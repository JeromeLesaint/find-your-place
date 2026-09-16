from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
from bson import json_util
from bson.errors import InvalidId
import os
import json
from dotenv import load_dotenv


class db:
    def findbyvehicle(
        self,
        lon,
        lat,
        hauteur,
        largeur,
        longueur,
        type_vehicule,
        is_suv=False
    ):
        """
        Recherche les emplacements compatibles avec un véhicule.

        La recherche est effectuée :
        - dans les emplacements de rue ;
        - dans les parkings en ouvrage.

        Les dimensions sont exprimées en mètres.
        """

        # VALIDATION DU TYPE DE VÉHICULE

        type_vehicule = (
            type_vehicule
            .strip()
            .lower()
        )

        types_autorises = [
            "voiture",
            "moto",
            "velo",
            "utilitaire"
        ]

        if type_vehicule not in types_autorises:
            raise ValueError(
                "Type de véhicule non reconnu."
            )

        # DIMENSIONS DU VÉHICULE

        surface_vehicule = None

        dimensions = [
            hauteur,
            largeur,
            longueur
        ]

        dimensions_presentes = [
            dimension
            for dimension in dimensions
            if dimension is not None
        ]

        # Voiture et utilitaire :
        # les dimensions sont obligatoires.
        if type_vehicule in [
            "voiture",
            "utilitaire"
        ]:

            if len(dimensions_presentes) != 3:
                raise ValueError(
                    "Les dimensions sont obligatoires "
                    "pour une voiture ou un utilitaire."
                )

        # Si une dimension est renseignée,
        # les trois doivent l'être.
        if dimensions_presentes:

            if len(dimensions_presentes) != 3:
                raise ValueError(
                    "Les dimensions du véhicule "
                    "sont incomplètes."
                )

            if (
                hauteur <= 0
                or largeur <= 0
                or longueur <= 0
            ):
                raise ValueError(
                    "Les dimensions du véhicule "
                    "doivent être positives."
                )

            # Surface au sol du véhicule.
            surface_vehicule = (
                longueur
                * largeur
            )

        # FILTRE DES EMPLACEMENTS DE RUE

        if type_vehicule == "velo":

            filtre_rue = {
                "regpri": "2 ROUES",
                "regpar": {
                    "$in": [
                        "Vélos",
                        "Vélo-cargo"
                    ]
                }
            }

            cle_tarif = None

        elif type_vehicule == "moto":

            filtre_rue = {
                "regpri": "2 ROUES",
                "regpar": {
                    "$in": [
                        "Motos payant Mixte",
                        "Motos payant Rotatif"
                    ]
                }
            }

            cle_tarif = "deux_roues_motorises"

        elif type_vehicule == "voiture":

            # Une voiture peut recevoir :
            # - les places classiques ;
            # - les emplacements électriques ;
            # - les emplacements livraison.
            #
            # Le frontend affichera les avertissements
            # nécessaires pour ELECTRIQUE et LIVRAISON.
            filtre_rue = {
                "$or": [
                    {
                        "regpri": "PAYANT MIXTE",
                        "regpar": "Mixte"
                    },
                    {
                        "regpri": "PAYANT ROTATIF",
                        "regpar": "Rotatif"
                    },
                    {
                        "regpri": "GRATUIT",
                        "regpar": "Gratuit"
                    },
                    {
                        "regpri": "ELECTRIQUE"
                    },
                    {
                        "regpri": "LIVRAISON"
                    }
                ]
            }

            # Le SUV reste une voiture.
            # Seule sa grille tarifaire change.
            if is_suv:
                cle_tarif = "suv"
            else:
                cle_tarif = "voiture"

        else:
            # Utilitaire :
            # utilisation provisoire des emplacements
            # voiture classiques uniquement.
            filtre_rue = {
                "$or": [
                    {
                        "regpri": "PAYANT MIXTE",
                        "regpar": "Mixte"
                    },
                    {
                        "regpri": "PAYANT ROTATIF",
                        "regpar": "Rotatif"
                    },
                    {
                        "regpri": "GRATUIT",
                        "regpar": "Gratuit"
                    }
                ]
            }

            # En attendant une tarification spécifique,
            # l'utilitaire utilise la grille voiture.
            cle_tarif = "voiture"

        # RECHERCHE DES PLACES DE RUE

        requete_rues = {
            "geo_shape.geometry": {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [
                            lon,
                            lat
                        ]
                    },
                    "$maxDistance": int(
                        os.getenv(
                            "DISTANCE_MAXI"
                        )
                    )
                }
            },

            # Une place confirmée comme interdite
            # n'est jamais retournée.
            "interdit": {
                "$ne": True
            }
        }

        requete_rues.update(
            filtre_rue
        )

        cursor_rues = self.collection.find(
            requete_rues
        )

        resultats_rues = []

        for record in cursor_rues:

            # FILTRAGE PAR SURFACE

            # Pour l'utilitaire, les dimensions sont conservées dans la réponse,
            # mais elles ne servent pas encore à filtrer les places de rue.
            # Il utilise provisoirement les emplacements voiture classiques.
            if (
                surface_vehicule is not None
                and type_vehicule != "utilitaire"
            ):

                nombre_places = (
                    record.get("plarel")
                    or record.get("placal")
                )

                surface_totale = record.get(
                    "surface_calculee"
                )

                # Impossible de vérifier correctement
                # la taille de cette place.
                if (
                    not nombre_places
                    or not surface_totale
                ):
                    continue

                try:
                    surface_par_place = (
                        float(surface_totale)
                        / float(nombre_places)
                    )

                except (
                    ValueError,
                    TypeError,
                    ZeroDivisionError
                ):
                    continue

                # Le véhicule est trop grand.
                if (
                    surface_par_place
                    < surface_vehicule
                ):
                    continue

                record[
                    "surface_par_place"
                ] = surface_par_place

            else:
                record[
                    "surface_par_place"
                ] = None

            # TARIF CORRESPONDANT AU VÉHICULE

            tarifs = (
                record.get("tarifs")
                or {}
            )

            if cle_tarif is not None:
                record[
                    "tarif_vehicule"
                ] = tarifs.get(
                    cle_tarif
                )
            else:
                record[
                    "tarif_vehicule"
                ] = None

            # Permet au frontend de distinguer
            # une place de rue d'un parking.
            record[
                "type_resultat"
            ] = "rue"

            resultats_rues.append(
                record
            )

        # RECHERCHE DES PARKINGS

        # Chaque véhicule utilise une capacité différente.
        if type_vehicule in [
            "voiture",
            "utilitaire"
        ]:
            champ_capacite = (
                "capacites.voitures"
            )

        elif type_vehicule == "moto":
            champ_capacite = (
                "capacites."
                "deux_roues_motorises"
            )

        else:
            champ_capacite = (
                "capacites.velos"
            )

        requete_parkings = {
            "type_donnee": "parking",

            champ_capacite: {
                "$gt": 0
            },

            "geolocalisation."
            "forme_geographique.geometry": {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [
                            lon,
                            lat
                        ]
                    },
                    "$maxDistance": int(
                        os.getenv(
                            "DISTANCE_MAXI"
                        )
                    )
                }
            }
        }

        cursor_parkings = (
            self.collection.find(
                requete_parkings
            )
        )

        resultats_parkings = []

        for parking in cursor_parkings:

            informations = (
                parking.get(
                    "informations_generales"
                )
                or {}
            )

            hauteur_max_brute = (
                informations.get(
                    "hauteur_maximale"
                )
            )

            hauteur_max_metres = None

            # HAUTEUR MAXIMALE DU PARKING

            if hauteur_max_brute not in [
                None,
                ""
            ]:

                try:
                    texte_hauteur = (
                        str(
                            hauteur_max_brute
                        )
                        .strip()
                        .lower()
                        .replace(",", ".")
                    )

                    # Valeur explicitement donnée en centimètres.
                    # Exemple : "190 cm" -> 1.90 m.
                    if texte_hauteur.endswith("cm"):

                        hauteur_max_metres = (
                            float(
                                texte_hauteur[
                                    :-2
                                ].strip()
                            )
                            / 100
                        )

                    # Valeur explicitement donnée en mètres.
                    # Exemple : "1.90 m" -> 1.90 m.
                    elif texte_hauteur.endswith("m"):

                        hauteur_max_metres = float(
                            texte_hauteur[
                                :-1
                            ].strip()
                        )

                    else:
                        valeur_hauteur = float(
                            texte_hauteur
                        )

                        # Le dataset Paris stocke actuellement
                        # des valeurs comme 180, 185, 190 ou 195.
                        # Elles correspondent à des centimètres.
                        if valeur_hauteur > 10:
                            hauteur_max_metres = (
                                valeur_hauteur
                                / 100
                            )

                        # Une petite valeur comme 1.90
                        # est considérée comme déjà exprimée
                        # en mètres.
                        else:
                            hauteur_max_metres = (
                                valeur_hauteur
                            )

                    # Une valeur impossible n'est pas utilisée
                    # pour exclure un parking.
                    if (
                        hauteur_max_metres <= 0
                        or hauteur_max_metres > 10
                    ):
                        hauteur_max_metres = None

                except (
                    ValueError,
                    TypeError
                ):
                    hauteur_max_metres = None

            # Si la hauteur maximale est connue,
            # le véhicule doit pouvoir passer.
            #
            # Si elle est absente ou inexploitable,
            # le parking est conservé conformément
            # à la demande de Manuel.
            if (
                hauteur is not None
                and hauteur_max_metres is not None
                and hauteur > hauteur_max_metres
            ):
                continue

            parking[
                "hauteur_maximale_m"
            ] = hauteur_max_metres

            # TARIF DU PARKING

            tarifs_parking = (
                parking.get("tarifs")
                or {}
            )

            if type_vehicule in [
                "voiture",
                "utilitaire"
            ]:
                parking[
                    "tarif_vehicule"
                ] = tarifs_parking.get(
                    "voitures"
                )

            elif type_vehicule == "moto":
                parking[
                    "tarif_vehicule"
                ] = tarifs_parking.get(
                    "motos"
                )

            else:
                parking[
                    "tarif_vehicule"
                ] = tarifs_parking.get(
                    "velos"
                )

            parking[
                "type_resultat"
            ] = "parking"

            resultats_parkings.append(
                parking
            )

        # RÉPONSE FINALE

        resultats = (
            resultats_rues
            + resultats_parkings
        )

        reponse = {
            "vehicule": {
                "type": type_vehicule,
                "is_suv": is_suv,
                "hauteur": hauteur,
                "largeur": largeur,
                "longueur": longueur,
                "surface_projetee": surface_vehicule
            },

            "coordonnees": {
                "longitude": lon,
                "latitude": lat
            },

            "nombre_resultats": len(
                resultats
            ),

            "resultats": resultats
        }

        return json.dumps(
            reponse,
            default=json_util.default,
            ensure_ascii=False
        )

    def connection(self):
        """
        Connects to MongoDB and creates a collection if it doesn't exist.
        """
        load_dotenv()
        try:
            # Connect to MongoDB server
            self.client = MongoClient(os.getenv('MONGODB_URI'), serverSelectionTimeoutMS=5000)
            self.client.server_info()  # Force connection check

            # Access the database
            self.db = self.client[os.getenv('DATABASE_NAME')]
            self.collection = self.db[os.getenv('COLLECTION_NAME')]

        except errors.ServerSelectionTimeoutError:
            log.error("Error: Could not connect to MongoDB server. Check your URI and network.")
        except errors.CollectionInvalid:
            log.error(f"Error: Collection '{collection_name}' already exists.")
        except Exception as e:
            log.error(f"Unexpected error: {e}")

    def findbydistance(self,lon, lat):
        requete_places_de_rue = {
            "geo_shape.geometry": {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [lon, lat]
                    },
                    "$maxDistance": int(os.getenv('DISTANCE_MAXI'))
                }
            }
        }
        requete_parkings = {
            "geolocalisation.forme_geographique.geometry": {
                "$near": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [lon, lat]
                    },
                    "$maxDistance": int(os.getenv('DISTANCE_MAXI'))
                }
            },
            "type_donnee": "parking"
        }
        places_de_rue = list(self.collection.find(requete_places_de_rue))
        parkings = list(self.collection.find(requete_parkings))
        return json.dumps(places_de_rue + parkings, default=json_util.default, ensure_ascii=False)

    def close(self):
        self.client.close()
