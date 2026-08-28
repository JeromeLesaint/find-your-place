import requests
from pymongo import UpdateOne


DATASET_ID = "stationnement-en-ouvrage"

API_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    f"{DATASET_ID}/records"
)

TIMEOUT = (10, 60)

# Ces données ne sont pas utiles à la recherche d'un parking et ne seront pas
# conservées dans MongoDB. Elles restent disponibles dans la source Open Data
# si le besoin revient plus tard.
CHAMPS_EXCLUS = {
    "asc_surf",  # présence d'un ascenseur débouchant en surface
}


def recuperer_parkings():
    """Récupère tous les parkings depuis Paris Open Data."""

    parkings = []
    limit = 100
    offset = 0

    while True:
        response = requests.get(
            API_URL,
            params={"limit": limit, "offset": offset},
            timeout=TIMEOUT,
        )
        response.raise_for_status()

        resultats = response.json().get("results", [])
        if not resultats:
            break

        parkings.extend(resultats)

        if len(resultats) < limit:
            break

        offset += limit

    print(f"{len(parkings)} parking(s) récupéré(s).")
    return parkings


def normaliser_parking(parking):
    """Conserve les données utiles Open Data et ajoute nos champs normalisés."""

    donnees_utiles = {
        champ: valeur
        for champ, valeur in parking.items()
        if champ not in CHAMPS_EXCLUS
    }

    return {
        **donnees_utiles,
        "type_donnee": "parking",
        "parking_id": parking.get("id"),
        "arrondissement": parking.get("insee"),
        "exploitant": parking.get("deleg"),
    }


def import_parkings(collection):
    """Ajoute ou met à jour les parkings sans créer de doublons."""

    operations = []

    for parking in recuperer_parkings():
        parking_normalise = normaliser_parking(parking)
        parking_id = parking_normalise.get("parking_id")

        if not parking_id:
            continue

        operations.append(
            UpdateOne(
                {"type_donnee": "parking", "parking_id": parking_id},
                {
                    "$set": parking_normalise,
                    # $set n'efface pas les champs déjà présents : on retire
                    # aussi l'ancienne valeur lors d'un réimport.
                    "$unset": {champ: "" for champ in CHAMPS_EXCLUS},
                },
                upsert=True,
            )
        )

    if not operations:
        print("Aucun parking à importer.")
        return

    resultat = collection.bulk_write(operations, ordered=False)
    print(f"{len(operations)} parking(s) traité(s).")
    print(f"{resultat.upserted_count} parking(s) ajouté(s).")
    print(f"{resultat.modified_count} parking(s) mis à jour.")
