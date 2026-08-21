import json
import time
from pathlib import Path

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


# ============================================================
# CONFIGURATION API
# ============================================================

DATASET_ID = "stationnement-sur-voie-publique-stationnement-interdit"

API_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    f"{DATASET_ID}/records"
)

# On utilise JSONL plutôt que JSON.
# JSONL permet de lire le dataset ligne par ligne sans charger
# les ~975 000 enregistrements en mémoire.
API_EXPORT_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    f"{DATASET_ID}/exports/jsonl"
)

# 10 secondes pour établir la connexion.
# 180 secondes maximum sans recevoir de nouvelles données.
TIMEOUT = (10, 180)


# ============================================================
# CACHE LOCAL
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

CACHE_DIR = (
    BASE_DIR
    / "downloads"
    / "cache"
)

CACHE_FILE = (
    CACHE_DIR
    / "zones_interdites_v1.jsonl"
)

# Pendant 24 heures, on ne retélécharge pas le dataset.
CACHE_TTL_SECONDS = 24 * 60 * 60

# Si Paris Open Data est momentanément indisponible,
# on accepte temporairement un cache vieux de 7 jours maximum.
MAX_STALE_SECONDS = 7 * 24 * 60 * 60

# Nombre maximum de tentatives en cas de coupure réseau.
DOWNLOAD_ATTEMPTS = 3


# ============================================================
# CHAMPS À TÉLÉCHARGER
# ============================================================

# On ne récupère volontairement que les champs nécessaires
# au matching des interdictions.
#
# Cela réduit fortement le poids réseau par rapport
# au dataset complet.
EXPORT_SELECT = (
    "id,"
    "regpri,"
    "regpar,"
    "c_voie_vp,"
    "n_voieadd,"
    "n_voieadf,"
    "parite"
)


# ============================================================
# SESSION HTTP
# ============================================================

def creer_session_http():
    """
    Crée une session HTTP robuste.

    Les erreurs temporaires comme :
    - 429 Too Many Requests
    - 500
    - 502
    - 503
    - 504

    sont automatiquement retentées avec un délai progressif.
    """

    retry = Retry(
        total=4,
        connect=4,

        # Le téléchargement streaming est lui-même
        # retenté par telecharger_cache_interdictions().
        read=0,

        status=4,

        backoff_factor=1.5,

        status_forcelist=(
            429,
            500,
            502,
            503,
            504,
        ),

        allowed_methods=frozenset(
            {"GET"}
        ),

        respect_retry_after_header=True,

        raise_on_status=False,
    )

    adapter = HTTPAdapter(
        max_retries=retry
    )

    session = requests.Session()

    session.mount(
        "https://",
        adapter
    )

    session.mount(
        "http://",
        adapter
    )

    return session


# ============================================================
# GESTION DU CACHE
# ============================================================

def age_cache_secondes():
    """
    Retourne l'âge actuel du cache en secondes.

    Retourne None si le cache n'existe pas.
    """

    if not CACHE_FILE.exists():
        return None

    return (
        time.time()
        - CACHE_FILE.stat().st_mtime
    )


def cache_utilisable(age_maximum):
    """
    Vérifie que le cache :
    - existe ;
    - n'est pas vide ;
    - n'est pas plus ancien que la limite donnée.
    """

    age = age_cache_secondes()

    return (
        age is not None
        and age <= age_maximum
        and CACHE_FILE.stat().st_size > 0
    )


def valider_cache_jsonl(path):
    """
    Vérifie que le fichier téléchargé contient réellement
    des enregistrements JSONL exploitables.

    Un fichier invalide ou vide ne remplacera jamais
    le cache précédent.
    """

    if (
        not path.exists()
        or path.stat().st_size == 0
    ):
        raise ValueError(
            "Le cache téléchargé est vide."
        )

    with open(
        path,
        "r",
        encoding="utf-8-sig"
    ) as fichier:

        for ligne in fichier:

            ligne = ligne.strip()

            if not ligne:
                continue

            data = json.loads(ligne)

            if not isinstance(data, dict):
                raise ValueError(
                    "Format JSONL inattendu."
                )

            # Un enregistrement valide suffit ici
            # pour vérifier la structure du fichier.
            return

    raise ValueError(
        "Le cache ne contient aucun enregistrement."
    )


def telecharger_cache_interdictions():
    """
    Télécharge le dataset dans un fichier temporaire.

    Le cache existant n'est remplacé qu'une fois :
    - le téléchargement terminé ;
    - le fichier non vide ;
    - le JSONL validé.

    Une coupure réseau ne peut donc pas corrompre
    un ancien cache fonctionnel.
    """

    CACHE_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    fichier_temporaire = (
        CACHE_FILE.with_suffix(
            ".jsonl.tmp"
        )
    )

    derniere_erreur = None

    params = {
        "select": EXPORT_SELECT
    }

    for tentative in range(
        1,
        DOWNLOAD_ATTEMPTS + 1
    ):

        if fichier_temporaire.exists():
            fichier_temporaire.unlink()

        session = creer_session_http()

        try:

            print(
                "Téléchargement du cache "
                "des interdictions "
                f"({tentative}/{DOWNLOAD_ATTEMPTS})..."
            )

            with session.get(
                API_EXPORT_URL,
                params=params,
                timeout=TIMEOUT,
                stream=True
            ) as response:

                response.raise_for_status()

                with open(
                    fichier_temporaire,
                    "wb"
                ) as fichier:

                    # Lecture par blocs de 1 Mo.
                    # On ne charge jamais tout le dataset en RAM.
                    for bloc in response.iter_content(
                        chunk_size=1024 * 1024
                    ):

                        if bloc:
                            fichier.write(bloc)

            # Vérifie que le fichier téléchargé
            # est réellement utilisable.
            valider_cache_jsonl(
                fichier_temporaire
            )

            # Remplacement atomique.
            # L'ancien cache reste disponible jusqu'ici.
            fichier_temporaire.replace(
                CACHE_FILE
            )

            print(
                "Cache des zones interdites prêt :",
                CACHE_FILE
            )

            return

        except (
            requests.RequestException,
            OSError,
            ValueError
        ) as erreur:

            derniere_erreur = erreur

            if fichier_temporaire.exists():
                fichier_temporaire.unlink()

            if tentative < DOWNLOAD_ATTEMPTS:

                # 1 seconde, puis 2 secondes...
                attente = 2 ** (
                    tentative - 1
                )

                print(
                    "Échec du téléchargement. "
                    f"Nouvelle tentative dans {attente}s..."
                )

                time.sleep(attente)

        finally:

            session.close()

    raise RuntimeError(
        "Impossible de télécharger le cache "
        "des zones interdites."
    ) from derniere_erreur


def assurer_cache_interdictions():
    """
    Garantit qu'un cache exploitable est disponible.

    Fonctionnement :
    - cache < 24 h : utilisation immédiate ;
    - cache absent/périmé : téléchargement ;
    - API temporairement indisponible :
      ancien cache accepté jusqu'à 7 jours ;
    - au-delà : erreur.
    """

    if cache_utilisable(
        CACHE_TTL_SECONDS
    ):

        print(
            "Cache des zones interdites "
            "déjà disponible."
        )

        return

    try:

        telecharger_cache_interdictions()

    except RuntimeError:

        if cache_utilisable(
            MAX_STALE_SECONDS
        ):

            print(
                "⚠️ Paris Open Data indisponible : "
                "utilisation temporaire du "
                "dernier cache disponible."
            )

            return

        raise


def iterer_zones_interdites_cache():
    """
    Lit les interdictions une par une depuis le cache.

    Le fichier peut contenir près d'un million de lignes :
    aucune grosse liste n'est créée ici.
    """

    assurer_cache_interdictions()

    with open(
        CACHE_FILE,
        "r",
        encoding="utf-8-sig"
    ) as fichier:

        for numero_ligne, ligne in enumerate(
            fichier,
            start=1
        ):

            ligne = ligne.strip()

            if not ligne:
                continue

            try:

                zone = json.loads(ligne)

            except json.JSONDecodeError as erreur:

                raise ValueError(
                    "Cache JSONL invalide "
                    f"à la ligne {numero_ligne}."
                ) from erreur

            if isinstance(zone, dict):
                yield zone


def recuperer_zones_interdites():
    """
    Retourne l'intégralité du dataset depuis le cache.

    Cette fonction reste présente pour compatibilité.

    Le bulk_import ne doit cependant pas l'utiliser directement,
    car cela chargerait tout le dataset en mémoire.
    """

    return list(
        iterer_zones_interdites_cache()
    )


# ============================================================
# OUTILS DE MATCHING
# ============================================================

def normaliser_borne(valeur):
    """
    Convertit une borne de numéro de voie en entier.

    Retourne None lorsque la valeur est inexploitable.
    """

    if valeur is None:
        return None

    try:
        return int(valeur)

    except (
        TypeError,
        ValueError
    ):
        return None


def fusionner_plages(plages):
    """
    Fusionne les plages qui se chevauchent.

    Cela réduit fortement le nombre de comparaisons
    à effectuer pour une même voie/parité.
    """

    if not plages:
        return []

    plages = sorted(plages)

    fusionnees = [
        [
            plages[0][0],
            plages[0][1]
        ]
    ]

    for debut, fin in plages[1:]:

        derniere = fusionnees[-1]

        # Les groupes possèdent déjà la même parité.
        #
        # Exemple côté impair :
        # 9, 11, 13...
        #
        # Un écart de 2 peut donc rester continu.
        if debut <= derniere[1] + 2:

            derniere[1] = max(
                derniere[1],
                fin
            )

        else:

            fusionnees.append(
                [
                    debut,
                    fin
                ]
            )

    return [
        (
            debut,
            fin
        )
        for debut, fin in fusionnees
    ]


def construire_groupes_places(
    places_voies
):
    """
    Construit un index des places MongoDB.

    Format attendu pour chaque tuple :

        (
            c_voie_vp,
            parite,
            n_voieadd,
            n_voieadf,
            numvoie
        )

    Exemple :

        (
            "9205",
            "Impair",
            9,
            21,
            9
        )

    Résultat :

        (
            "9205",
            "IMPAIR"
        )
            ->
        [
            (9, 21),
            ...
        ]
    """

    groupes = {}

    for (
        code_voie,
        parite,
        debut_place,
        fin_place,
        numvoie
    ) in places_voies:

        if not code_voie:
            continue

        code_voie = str(
            code_voie
        ).strip()

        parite = normaliser_texte(
            parite
        )

        debut_place = normaliser_borne(
            debut_place
        )

        fin_place = normaliser_borne(
            fin_place
        )

        numvoie = normaliser_borne(
            numvoie
        )

        # numvoie sert de fallback uniquement lorsque
        # n_voieadd ou n_voieadf est absent.
        if debut_place is None:
            debut_place = numvoie

        if fin_place is None:
            fin_place = numvoie

        if (
            debut_place is None
            or fin_place is None
        ):
            continue

        # Protection contre une éventuelle plage inversée.
        if debut_place > fin_place:

            (
                debut_place,
                fin_place
            ) = (
                fin_place,
                debut_place
            )

        cle = (
            code_voie,
            parite
        )

        groupes.setdefault(
            cle,
            []
        ).append(
            (
                debut_place,
                fin_place
            )
        )

    # Réduction des plages avant le matching.
    for cle, plages in groupes.items():

        groupes[cle] = fusionner_plages(
            plages
        )

    return groupes


def zone_croise_plages(
    zone,
    plages_places
):
    """
    Vérifie si une zone interdite croise au moins
    une plage correspondant aux places MongoDB.

    Une zone sans aucune borne numérique est ignorée :
    on évite ainsi de déclarer une place interdite
    sans preuve suffisamment précise.
    """

    debut_zone = normaliser_borne(
        zone.get("n_voieadd")
    )

    fin_zone = normaliser_borne(
        zone.get("n_voieadf")
    )

    # Pas de plage exploitable.
    if (
        debut_zone is None
        and fin_zone is None
    ):
        return False

    # Une seule borne connue :
    # elle est traitée comme un point.
    if debut_zone is None:
        debut_zone = fin_zone

    if fin_zone is None:
        fin_zone = debut_zone

    if debut_zone > fin_zone:

        (
            debut_zone,
            fin_zone
        ) = (
            fin_zone,
            debut_zone
        )

    # Les plages MongoDB sont déjà triées.
    for (
        debut_place,
        fin_place
    ) in plages_places:

        # Plus aucune plage suivante ne pourra croiser.
        if debut_place > fin_zone:
            break

        # Intersection :
        #
        # place    [---------]
        # interdit      [---------]
        if fin_place >= debut_zone:
            return True

    return False


# ============================================================
# RÉCUPÉRATION FILTRÉE
# ============================================================

def recuperer_zones_interdites_filtrees(
    places_voies
):
    """
    Sélectionne localement uniquement les interdictions
    pouvant correspondre aux places présentes dans MongoDB.

    Contrairement à l'ancienne version :
    - aucune requête par lot ;
    - aucun gigantesque WHERE ;
    - aucun OR généré dynamiquement ;
    - aucune centaine de requêtes HTTP.

    Un seul export est mis en cache puis parcouru localement.
    """

    groupes = construire_groupes_places(
        places_voies
    )

    print(
        f"{len(groupes)} combinaison(s) "
        f"voie/parité à rechercher "
        f"dans les interdictions."
    )

    zones_interdites = []

    for zone in iterer_zones_interdites_cache():

        code_zone = zone.get(
            "c_voie_vp"
        )

        if not code_zone:
            continue

        cle = (
            str(
                code_zone
            ).strip(),

            normaliser_texte(
                zone.get("parite")
            )
        )

        plages_places = groupes.get(
            cle
        )

        # Cette voie/parité n'existe pas dans MongoDB.
        if not plages_places:
            continue

        # Vérification précise des plages de numéros.
        if zone_croise_plages(
            zone,
            plages_places
        ):

            zones_interdites.append(
                zone
            )

    print(
        f"{len(zones_interdites)} "
        f"zone(s) interdite(s) pertinente(s) "
        f"conservée(s)."
    )

    return zones_interdites

def normaliser_zone_interdite(zone):
    """
    Prépare uniquement les informations utiles au futur enrichissement
    des documents de stationnement.

    La parité et les informations de voie sont conservées pour permettre
    un matching rapide avant les vérifications plus précises.
    """
    return {
        "interdit": True,
        "id": zone.get("id"),
        "id_old": zone.get("id_old"),
        "regpri": zone.get("regpri"),
        "regpar": zone.get("regpar"),
        "arrond": zone.get("arrond"),
        "zoneres": zone.get("zoneres"),
        "tar": zone.get("tar"),
        "c_voie_vp": zone.get("c_voie_vp"),
        "numvoie": zone.get("numvoie"),
        "n_voieadd": zone.get("n_voieadd"),
        "n_voieadf": zone.get("n_voieadf"),
        "typevoie": zone.get("typevoie"),
        "nomvoie": zone.get("nomvoie"),
        "parite": zone.get("parite"),
        "signhor": zone.get("signhor"),
        "signvert": zone.get("signvert"),
        "confsign": zone.get("confsign"),
        "geo_shape": zone.get("geo_shape"),
        "geo_point_2d": zone.get("geo_point_2d"),
    }


def iterer_zones_interdites_normalisees(zones=None):
    """
    Retourne les zones normalisées une par une.

    L'utilisation de yield évite de créer une seconde grosse liste
    contenant toutes les zones normalisées en mémoire.
    """
    if zones is None:
        zones = iterer_zones_interdites_cache()

    for zone in zones:
        yield normaliser_zone_interdite(zone)

def est_place_interdite(place, index_interdit):
    """
    Détermine si une place MongoDB croise une plage interdite.

    Le matching utilise :
    - c_voie_vp ;
    - parite ;
    - n_voieadd / n_voieadf ;
    - numvoie comme valeur de secours.
    """

    code_voie = place.get("c_voie_vp")

    if not code_voie:
        return False

    parite = normaliser_texte(
        place.get("parite")
    )

    cle = (
        str(code_voie).strip(),
        parite
    )

    plages_interdites = index_interdit[
        "par_code_voie"
    ].get(cle)

    # Aucune interdiction connue pour cette voie/parité.
    if not plages_interdites:
        return False

    debut_place = normaliser_borne(
        place.get("n_voieadd")
    )

    fin_place = normaliser_borne(
        place.get("n_voieadf")
    )

    numvoie = normaliser_borne(
        place.get("numvoie")
    )

    # numvoie sert de secours si une borne manque.
    if debut_place is None:
        debut_place = numvoie

    if fin_place is None:
        fin_place = numvoie

    # Impossible de positionner correctement la place.
    if debut_place is None or fin_place is None:
        return False

    # Protection contre une plage inversée.
    if debut_place > fin_place:
        debut_place, fin_place = (
            fin_place,
            debut_place
        )

    # Les intervalles interdits sont déjà triés et fusionnés.
    for debut_interdit, fin_interdit in plages_interdites:

        # L'interdiction est déjà complètement avant la place.
        if fin_interdit < debut_place:
            continue

        # Les intervalles suivants seront encore plus loin.
        if debut_interdit > fin_place:
            break

        # Les deux plages se croisent.
        return True

    return False

def build_index_interdit(places_voies):
    """
    Construit directement un index compact des interdictions
    à partir des voies/plages présentes dans MongoDB.
    """

    groupes_places = construire_groupes_places(places_voies)

    print(
        f"{len(groupes_places)} combinaison(s) "
        f"voie/parité à analyser."
    )

    index_brut = {}

    zones_lues = 0
    zones_retenues = 0

    # Lecture du cache ligne par ligne pour ne pas charger
    # près d'un million d'enregistrements en mémoire.
    for zone in iterer_zones_interdites_cache():

        zones_lues += 1

        code_voie = zone.get("c_voie_vp")

        if not code_voie:
            continue

        cle = (
            str(code_voie).strip(),
            normaliser_texte(zone.get("parite"))
        )

        plages_places = groupes_places.get(cle)

        # Cette voie/parité n'existe pas dans MongoDB.
        if not plages_places:
            continue

        debut_zone = normaliser_borne(
            zone.get("n_voieadd")
        )

        fin_zone = normaliser_borne(
            zone.get("n_voieadf")
        )

        # Impossible de déterminer une plage précise.
        if debut_zone is None and fin_zone is None:
            continue

        # Si une seule borne existe, elle sert également
        # de deuxième borne.
        if debut_zone is None:
            debut_zone = fin_zone

        if fin_zone is None:
            fin_zone = debut_zone

        # Protection contre des bornes inversées.
        if debut_zone > fin_zone:
            debut_zone, fin_zone = fin_zone, debut_zone

        # Vérifie que le tronçon interdit croise réellement
        # au moins une plage présente dans MongoDB.
        correspondance = False

        for debut_place, fin_place in plages_places:

            # Les plages étant triées, inutile de continuer
            # si on a déjà dépassé l'interdiction.
            if debut_place > fin_zone:
                break

            if fin_place >= debut_zone:
                correspondance = True
                break

        if not correspondance:
            continue

        # On conserve uniquement deux nombres,
        # pas tout le dictionnaire de la zone.
        index_brut.setdefault(
            cle,
            []
        ).append(
            (
                debut_zone,
                fin_zone
            )
        )

        zones_retenues += 1

    # ============================================================
    # FUSION DES INTERVALLES
    # ============================================================

    index_compact = {}
    nombre_intervalles = 0

    for cle, plages in index_brut.items():

        plages_fusionnees = fusionner_plages(
            plages
        )

        index_compact[cle] = plages_fusionnees

        nombre_intervalles += len(
            plages_fusionnees
        )

    print(
        f"{zones_lues} zone(s) interdite(s) lue(s) "
        f"depuis le cache."
    )

    print(
        f"{zones_retenues} zone(s) brute(s) "
        f"correspondent aux emplacements."
    )

    print(
        f"{len(index_compact)} clé(s) voie/parité "
        f"dans l'index compact."
    )

    print(
        f"{nombre_intervalles} intervalle(s) "
        f"interdit(s) après fusion."
    )

    return {
        "par_code_voie": index_compact
    }

def trouver_candidats_interdiction(place, index):
    """
    Retourne uniquement les zones interdites susceptibles de correspondre
    à une place.

    Priorité :
    1. c_voie_vp + parité
    2. arrondissement + type de voie + nom de voie + parité

    Cette fonction ne décide PAS encore si la place est réellement interdite.
    Elle réduit seulement le nombre de candidats à comparer.
    """
    c_voie_vp = place.get("c_voie_vp")
    parite = place.get("parite")

    if c_voie_vp:
        cle_code_voie = (
            str(c_voie_vp).strip(),
            normaliser_texte(parite),
        )

        candidats = index["par_code_voie"].get(cle_code_voie)

        if candidats:
            return candidats

    nomvoie = place.get("nomvoie")

    if nomvoie:
        cle_adresse = (
            place.get("arrond"),
            normaliser_texte(place.get("typevoie")),
            normaliser_texte(nomvoie),
            normaliser_texte(parite),
        )

        candidats = index["par_adresse"].get(cle_adresse)

        if candidats:
            return candidats

    return []


def normaliser_texte(valeur):
    """
    Normalise une valeur texte utilisée dans les clés d'index.

    Exemple :
        " RUE DU " -> "RUE DU"
        "Pair"     -> "PAIR"
    """
    if valeur is None:
        return None

    return str(valeur).strip().upper()


def recuperer_exemple(limit=1):
    """
    Récupère quelques enregistrements depuis /records.
    Pratique pour vérifier rapidement la réponse réelle de l'API.
    """
    if not 1 <= limit <= 100:
        raise ValueError("limit doit être compris entre 1 et 100.")

    params = {
        "limit": limit
    }

    response = requests.get(
        API_URL,
        params=params,
        timeout=TIMEOUT
    )
    response.raise_for_status()

    return response.json()


if __name__ == "__main__":
    exemple = recuperer_exemple(limit=1)

    print("API :", API_URL)


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