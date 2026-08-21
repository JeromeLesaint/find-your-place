import requests

# Identifiant officiel du dataset Paris Open Data
DATASET_ID = "stationnement-sur-voie-publique-zones-tarifaires"
API_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    f"{DATASET_ID}/records"
)

# Endpoint d'export JSON complet.
API_EXPORT_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    f"{DATASET_ID}/exports/json"
)

# Temps maximum accordé à une requête HTTP.
TIMEOUT = 30


def recuperer_zones_tarifaires():
    """
    Récupère l'ensemble des zones tarifaires depuis Paris Open Data.
    """

    # Appel de l'export JSON complet.
    response = requests.get(
        API_EXPORT_URL,
        timeout=TIMEOUT
    )

    # Déclenche une exception si l'API retourne une erreur HTTP
    # comme 404, 500, etc.
    response.raise_for_status()

    # Conversion de la réponse JSON en objet Python.
    data = response.json()

    # Selon le format renvoyé par Opendatasoft,
    # l'export peut être directement une liste de zones.
    if isinstance(data, list):
        return data

    # Certains formats peuvent encapsuler les enregistrements
    # dans un dictionnaire.
    if isinstance(data, dict):
        if isinstance(data.get("results"), list):
            return data["results"]

        if isinstance(data.get("records"), list):
            return data["records"]

    # Si la structure reçue n'est pas reconnue,
    # on préfère arrêter clairement plutôt
    raise ValueError("Format JSON inattendu pour les zones tarifaires.")


def normaliser_zone_tarifaire(zone):
    """
    Prépare une zone tarifaire dans une structure simple à exploiter.
    """

    # On récupère automatiquement tous les champs tarifaires.
    # Exemple :
    # vis_vl_h1_lv
    # vis_vl_h2_lv
    # vis_2rm_h1_lv
    # vis_suv_h1
    # etc.

    tarifs = {
        cle: valeur
        for cle, valeur in zone.items()
        if cle.startswith("vis_")
    }

    return {
        # Numéro / identifiant de la zone tarifaire.
        "zone": zone.get("zone"),

        # Grille tarifaire complète conservée telle qu'elle est publiée.
        "tarifs": tarifs,

        # Géométrie complète de la zone tarifaire.
        "geo_shape": zone.get("geo_shape"),

        # Point représentatif de la zone.
        "geo_point_2d": zone.get("geo_point_2d"),
    }


def build_index_tarifaires():
    """
    Récupère puis normalise toutes les zones tarifaires.
    """

    # Récupération des données brutes depuis l'API.
    zones = recuperer_zones_tarifaires()

    # Transformation de chaque zone dans notre format simplifié.
    return [
        normaliser_zone_tarifaire(zone)
        for zone in zones
    ]


def recuperer_exemple(limit=1):
    """
    Récupère quelques zones directement depuis l'endpoint /records.
    """

    # L'API Opendatasoft limite le nombre de résultats
    # retournés par page.
    if not 1 <= limit <= 100:
        raise ValueError("limit doit être compris entre 1 et 100.")

    params = {
        "limit": limit
    }

    # Appel de l'endpoint paginé.
    response = requests.get(
        API_URL,
        params=params,
        timeout=TIMEOUT
    )

    # Arrêt immédiat en cas d'erreur HTTP.
    response.raise_for_status()

    return response.json()


if __name__ == "__main__":
    print("========================================")
    print("TEST ZONE TARIFAIRE")
    print("========================================")
    print("Fichier exécuté :", __file__)
    print("API :", API_URL)
    print()

    try:
        print("Envoi de la requête API...")

        exemple = recuperer_exemple(limit=1)

        print("Réponse API reçue.")
        print()
        print("Nombre total :", exemple.get("total_count"))
        print("Exemple :", exemple.get("results", []))

    except requests.exceptions.Timeout as e:
        print("ERREUR : délai d'attente dépassé.")
        print(e)

    except requests.exceptions.HTTPError as e:
        print("ERREUR HTTP :")
        print(e)

    except requests.exceptions.RequestException as e:
        print("ERREUR lors de la requête :")
        print(e)

    except Exception as e:
        print("ERREUR inattendue :")
        print(type(e).__name__, "-", e)
