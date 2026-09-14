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
        type_vehicule
    ):
        """
        Recherche des emplacements proches en fonction
        des coordonnées GPS et du véhicule renseigné.
        """

        # 1. Uniformise le type reçu depuis le frontend.
        type_vehicule = type_vehicule.strip().lower()

        # 2. Vérifie que les dimensions sont valides.
        if hauteur <= 0 or largeur <= 0 or longueur <= 0:
            raise ValueError(
                "Les dimensions du véhicule doivent être positives."
            )

        # 3. Calcule la surface occupée au sol.
        surface_vehicule = longueur * largeur

        # 4. Vérifie que le type est autorisé.
        types_autorises = [
            "velo",
            "moto",
            "voiture",
            "suv"
        ]

        if type_vehicule not in types_autorises:
            raise ValueError(
                "Type de véhicule non reconnu."
            )

        # Filtre MongoDB correspondant au type de véhicule.
        filtres_par_type = {
            "velo": {
                "regpri": "2 ROUES",
                "regpar": {
                    "$in": [
                        "Vélos",
                        "Vélo-cargo"
                    ]
                }
            },

            "moto": {
                "regpri": "2 ROUES",
                "regpar": {
                    "$in": [
                        "Motos payant Mixte",
                        "Motos payant Rotatif"
                    ]
                }
            },

            "voiture": {
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
            },

            "suv": {
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
        }

        filtre_type = filtres_par_type[type_vehicule]

        # 5. Correspondance avec les tarifs MongoDB.
        tarifs_par_type = {
            "velo": None,
            "moto": "deux_roues_motorises",
            "voiture": "voiture",
            "suv": "suv"
        }

        # 6. Recherche MongoDB.
        requete = {
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
                        os.getenv("DISTANCE_MAXI")
                    )
                }
            },

            "surface_calculee": {
                "$gte": surface_vehicule
            },

            "interdit": {
                "$ne": True
            }
        }

        # Ajoute le filtre correspondant
        # au type de véhicule.
        requete.update(filtre_type)

        cursor = self.collection.find(
            requete
        )

        resultats = []

        cle_tarif = tarifs_par_type[type_vehicule]

        # 7. Prépare les résultats.
        for record in cursor:

            # Nombre de places présentes dans la zone.
            # PLAREL correspond au nombre de places réelles.
            # Si cette information manque, on utilise PLACAL
            # (nombre de places calculées) en secours.
            nombre_places = (
                record.get("plarel")
                or record.get("placal")
            )

            surface_totale = record.get(
                "surface_calculee"
            )

            # Impossible de déterminer correctement
            # la surface d'une place.
            if not nombre_places or not surface_totale:
                continue

            # Surface moyenne disponible pour une place.
            surface_par_place = (
                surface_totale
                / nombre_places
            )

            # Le véhicule est trop grand pour la place.
            if surface_par_place < surface_vehicule:
                continue

            tarifs = record.get(
                "tarifs",
                {}
            )

            if cle_tarif is not None:
                record["tarif_vehicule"] = tarifs.get(
                    cle_tarif
                )
            else:
                record["tarif_vehicule"] = None

            record["surface_par_place"] = surface_par_place

            resultats.append(record)

        # 8. Construit le JSON de réponse.
        reponse = {
            "vehicule": {
                "hauteur": hauteur,
                "largeur": largeur,
                "longueur": longueur,
                "surface_projetee": surface_vehicule,
                "type": type_vehicule
            },

            "coordonnees": {
                "longitude": lon,
                "latitude": lat
            },

            "nombre_resultats": len(resultats),

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
        cursor = self.collection.find({
           "geo_shape.geometry": {
              "$near": {
                 "$geometry": {
                    "type": "Point",
                    "coordinates": [lon, lat]
                 },
                 "$maxDistance": int(os.getenv('DISTANCE_MAXI'))
              }
           }
        })
        return json.dumps(list(cursor), default=json_util.default, ensure_ascii=False)

    def close(self):
        self.client.close()
