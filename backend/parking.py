import requests
import logging

from pymongo import UpdateOne
from pymongo.errors import PyMongoError

# Utilise le même logger que le bulk import.
# Sa configuration console/fichier est faite dans functions.py.
log = logging.getLogger(
    "Trouves ta place - Bulk Import"
)

DATASET_ID = "stationnement-en-ouvrage"

API_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    f"{DATASET_ID}/records"
)

TIMEOUT = (10, 60)


def recuperer_parkings():
    """
    Récupère tous les parkings depuis Paris Open Data.

    Le dataset étant petit, on peut utiliser directement
    l'endpoint /records.
    """

    parkings = []
    limit = 100
    offset = 0

    while True:

        params = {
            "limit": limit,
            "offset": offset
        }

        response = requests.get(
            API_URL,
            params=params,
            timeout=TIMEOUT
        )

        response.raise_for_status()

        data = response.json()

        resultats = data.get("results", [])

        if not resultats:
            break

        parkings.extend(resultats)

        # Si moins de 100 résultats sont retournés,
        # nous avons atteint la dernière page.
        if len(resultats) < limit:
            break

        offset += limit

    log.info(
        f"{len(parkings)} parking(s) récupéré(s)."
    )

    return parkings


def normaliser_parking(parking):
    """
    Prépare uniquement les informations nécessaires
    pour la phase 1 : identification et position.
    """

    return {
        "type_donnee": "parking",

        "parking_id": parking.get("id"),
        "nom": parking.get("nom"),
        "adresse": parking.get("adresse"),
        "arrondissement": parking.get("insee"),

        "nb_places": parking.get("nb_places"),

        "geo_shape": parking.get("geo_shape"),
        "geo_point_2d": parking.get("geo_point_2d")
    }


def import_parkings(collection):
    """
    Ajoute ou met à jour les parkings dans la même collection MongoDB.

    L'upsert évite de créer des doublons si cette fonction
    est relancée ultérieurement.

    Une erreur liée à Paris Open Data ou MongoDB est enregistrée
    dans les logs sans interrompre le reste du bulk import.
    """

    # ------------------------------------------------------------
    # RÉCUPÉRATION DES PARKINGS
    # ------------------------------------------------------------

    try:
        parkings = recuperer_parkings()

    except requests.exceptions.RequestException as erreur:
        log.error(
            f"Erreur lors de la récupération des parkings "
            f"depuis Paris Open Data : {erreur}"
        )
        return False

    except Exception as erreur:
        log.error(
            f"Erreur inattendue lors de la récupération "
            f"des parkings : {erreur}"
        )
        return False

    # ------------------------------------------------------------
    # PRÉPARATION DES OPÉRATIONS MONGODB
    # ------------------------------------------------------------

    operations = []

    for parking in parkings:

        parking_normalise = normaliser_parking(
            parking
        )

        parking_id = parking_normalise.get(
            "parking_id"
        )

        # Un parking sans identifiant fiable n'est pas importé.
        if not parking_id:
            continue

        operations.append(
            UpdateOne(
                {
                    "type_donnee": "parking",
                    "parking_id": parking_id
                },
                {
                    "$set": parking_normalise
                },
                upsert=True
            )
        )

    if not operations:
        log.info(
            "Aucun parking à importer."
        )
        return True

    # ------------------------------------------------------------
    # ÉCRITURE MONGODB
    # ------------------------------------------------------------

    try:
        resultat = collection.bulk_write(
            operations,
            ordered=False
        )

    except PyMongoError as erreur:
        log.error(
            f"Erreur MongoDB pendant l'import des parkings : "
            f"{erreur}"
        )
        return False

    except Exception as erreur:
        log.error(
            f"Erreur inattendue pendant l'import "
            f"des parkings : {erreur}"
        )
        return False

    # ------------------------------------------------------------
    # RAPPORT
    # ------------------------------------------------------------

    log.info(
        f"{len(operations)} parking(s) traité(s)."
    )

    log.info(
        f"{resultat.upserted_count} parking(s) ajouté(s)."
    )

    log.info(
        f"{resultat.modified_count} parking(s) mis à jour."
    )

    return True
