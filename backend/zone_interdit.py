import json
import time
from pathlib import Path

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from shapely.errors import GEOSException
from shapely.geometry import shape
from shapely import make_valid

from pyproj import Transformer
from pyproj.exceptions import ProjError
from shapely.ops import transform as shapely_transform

# ============================================================
# PROJECTION MÉTRIQUE ET TOLÉRANCE GÉOGRAPHIQUE
# ============================================================

# Les données Paris Open Data sont exprimées en longitude/latitude
# (EPSG:4326).
#
# Pour mesurer une distance réelle en mètres, on les projette
# en Lambert-93, système métrique adapté à la France.
TRANSFORMER_LAMBERT93 = Transformer.from_crs(
    "EPSG:4326",
    "EPSG:2154",
    always_xy=True
)

# Tolérance très faible retenue après audit des écarts géométriques.
# Elle sert uniquement à absorber les écarts de précision entre
# les géométries officielles lorsque l'intersection exacte échoue.
# 0.05 m = 5 cm.
TOLERANCE_GEOMETRIQUE_METRES = 0.10


def projeter_lambert93(geometrie):
    """
    Convertit une géométrie Shapely EPSG:4326
    vers Lambert-93 EPSG:2154.

    La géométrie retournée permet de calculer
    correctement des distances en mètres.
    """

    if geometrie is None:
        return None

    try:

        return shapely_transform(
            TRANSFORMER_LAMBERT93.transform,
            geometrie
        )

    except (
        GEOSException,
        ProjError,
        TypeError,
        ValueError
    ):
        return None


def auditer_distance_interdiction_geographique(
    place,
    index_verification,
    index_emprises
):
    """
    Mesure la distance minimale entre l'emprise réelle
    d'une place et les interdictions correspondant
    exactement à son tronçon.

    Cette fonction est uniquement destinée à l'audit.

    Elle ne décide jamais qu'une place est interdite
    et ne modifie aucune donnée MongoDB.

    Retour :
        {
            "auditable": True,
            "distance_m": 0.42,
            "source_id": "...",
            "emprise_id": "..."
        }
    """

    # --------------------------------------------------------
    # 1. Vérification stricte du tronçon
    # --------------------------------------------------------

    verification_troncon = verifier_place_interdite(
        place,
        index_verification
    )

    if not verification_troncon.get("confirmee"):

        return {
            "auditable": False,
            "motif": (
                verification_troncon.get(
                    "motif_verification"
                )
            ),
            "distance_m": None
        }

    n_sq_tv = place.get("n_sq_tv")
    c_voie_vp = place.get("c_voie_vp")
    parite = normaliser_texte(
        place.get("parite")
    )

    if (
        not n_sq_tv
        or not c_voie_vp
        or not parite
    ):

        return {
            "auditable": False,
            "motif": "cle_geographique_incomplete",
            "distance_m": None
        }

    cle = (
        str(n_sq_tv).strip(),
        str(c_voie_vp).strip(),
        parite
    )

    # --------------------------------------------------------
    # 2. Point de la place
    # --------------------------------------------------------

    point_place = convertir_geo_shape(
        place.get("geo_shape"),
        {"Point"}
    )

    if point_place is None:

        return {
            "auditable": False,
            "motif": "point_place_inexploitable",
            "distance_m": None
        }

    # --------------------------------------------------------
    # 3. Emprises correspondant au même tronçon
    # --------------------------------------------------------

    emprises_candidates = (
        index_emprises.get(cle)
    )

    if not emprises_candidates:

        return {
            "auditable": False,
            "motif": "aucune_emprise_sur_troncon",
            "distance_m": None
        }

    emprises_place = []

    for emprise in emprises_candidates:

        try:

            if emprise["geometry"].covers(
                point_place
            ):

                emprises_place.append(
                    emprise
                )

        except GEOSException:
            continue

    if not emprises_place:

        return {
            "auditable": False,
            "motif": (
                "aucune_emprise_contenant_la_place"
            ),
            "distance_m": None
        }

    # --------------------------------------------------------
    # 4. Recherche de la distance minimale
    # --------------------------------------------------------

    distance_minimale = None

    meilleure_source_id = None
    meilleure_emprise_id = None

    for preuve in verification_troncon.get(
        "preuves",
        []
    ):

        geometrie_interdiction = convertir_geo_shape(
            preuve.get("geo_shape"),
            {
                "LineString",
                "MultiLineString"
            }
        )

        if geometrie_interdiction is None:
            continue

        # Projection de l'interdiction en mètres.
        interdiction_l93 = preuve.get(
            "_geometry_l93"
        )

        if interdiction_l93 is None:

            interdiction_l93 = projeter_lambert93(
                geometrie_interdiction
            )

            # Petit cache en mémoire pour ne pas reprojeter
            # plusieurs fois la même interdiction.
            preuve["_geometry_l93"] = (
                interdiction_l93
            )

        if interdiction_l93 is None:
            continue

        for emprise in emprises_place:

            # Même principe pour l'emprise.
            emprise_l93 = emprise.get(
                "_geometry_l93"
            )

            if emprise_l93 is None:

                emprise_l93 = projeter_lambert93(
                    emprise.get("geometry")
                )

                emprise["_geometry_l93"] = (
                    emprise_l93
                )

            if emprise_l93 is None:
                continue

            try:

                distance = float(
                    emprise_l93.distance(
                        interdiction_l93
                    )
                )

            except GEOSException:
                continue

            if (
                distance_minimale is None
                or distance < distance_minimale
            ):

                distance_minimale = distance

                meilleure_source_id = (
                    preuve.get("source_id")
                )

                meilleure_emprise_id = (
                    emprise.get("id")
                )

    if distance_minimale is None:

        return {
            "auditable": False,
            "motif": (
                "distance_geographique_incalculable"
            ),
            "distance_m": None
        }

    return {
        "auditable": True,

        # On conserve la valeur brute.
        # L'arrondi sera uniquement fait à l'affichage.
        "distance_m": distance_minimale,

        "source_id": meilleure_source_id,
        "emprise_id": meilleure_emprise_id
    }


# CONFIGURATION API


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

# CACHE LOCAL
BASE_DIR = Path(__file__).resolve().parent

CACHE_DIR = (
    BASE_DIR
    / "downloads"
    / "cache"
)

CACHE_FILE = (
    CACHE_DIR
    / "zones_interdites.jsonl"
)

# Pendant 24 heures, on ne retélécharge pas le dataset.
CACHE_TTL_SECONDS = 24 * 60 * 60

# Si Paris Open Data est momentanément indisponible,
# on accepte temporairement un cache vieux de 7 jours maximum.
MAX_STALE_SECONDS = 7 * 24 * 60 * 60

# Nombre maximum de tentatives en cas de coupure réseau.
DOWNLOAD_ATTEMPTS = 3


# CHAMPS À TÉLÉCHARGER
EXPORT_SELECT = (
    "id,"
    "regpri,"
    "regpar,"
    "c_voie_vp,"
    "n_sq_tv,"
    "n_voieadd,"
    "n_voieadf,"
    "parite,"
    "geo_shape"
)


# CONFIGURATION API - EMPRISES DE STATIONNEMENT

EMPRISES_DATASET_ID = "stationnement-sur-voie-publique-emprises"

EMPRISES_API_EXPORT_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    f"{EMPRISES_DATASET_ID}/exports/jsonl"
)

EMPRISES_CACHE_FILE = (
    CACHE_DIR
    / "emprises_stationnement.jsonl"
)

# On ne récupère que les champs nécessaires au rapprochement
# entre les points MongoDB, les polygones d'emprise et les
# géométries de stationnement interdit.
EMPRISES_EXPORT_SELECT = (
    "id,"
    "c_voie_vp,"
    "n_sq_tv,"
    "n_voieadd,"
    "n_voieadf,"
    "parite,"
    "geo_shape"
)

# SESSION HTTP


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

# GESTION DU CACHE


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


# GESTION DU CACHE DES EMPRISES


def age_cache_emprises_secondes():
    """
    Retourne l'âge du cache des emprises en secondes.

    Retourne None si le cache n'existe pas.
    """

    if not EMPRISES_CACHE_FILE.exists():
        return None

    return (
        time.time()
        - EMPRISES_CACHE_FILE.stat().st_mtime
    )


def cache_emprises_utilisable(age_maximum):
    """
    Vérifie que le cache des emprises :
    - existe ;
    - n'est pas vide ;
    - n'est pas plus ancien que la limite donnée.
    """

    age = age_cache_emprises_secondes()

    return (
        age is not None
        and age <= age_maximum
        and EMPRISES_CACHE_FILE.stat().st_size > 0
    )


def telecharger_cache_emprises():
    """
    Télécharge le dataset des emprises dans un cache JSONL local.

    Le fichier existant n'est remplacé qu'une fois le téléchargement
    terminé et le JSONL validé, afin de ne jamais laisser un cache
    partiellement téléchargé.
    """

    CACHE_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    fichier_temporaire = (
        EMPRISES_CACHE_FILE.with_suffix(
            ".jsonl.tmp"
        )
    )

    derniere_erreur = None

    params = {
        "select": EMPRISES_EXPORT_SELECT
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
                "Téléchargement du cache des emprises "
                f"({tentative}/{DOWNLOAD_ATTEMPTS})..."
            )

            with session.get(
                EMPRISES_API_EXPORT_URL,
                params=params,
                timeout=TIMEOUT,
                stream=True
            ) as response:

                response.raise_for_status()

                with open(
                    fichier_temporaire,
                    "wb"
                ) as fichier:

                    # Lecture par blocs afin de ne jamais charger
                    # l'export complet en mémoire.
                    for bloc in response.iter_content(
                        chunk_size=1024 * 1024
                    ):

                        if bloc:
                            fichier.write(bloc)

            valider_cache_jsonl(
                fichier_temporaire
            )

            # Remplacement atomique du cache précédent.
            fichier_temporaire.replace(
                EMPRISES_CACHE_FILE
            )

            print(
                "Cache des emprises prêt :",
                EMPRISES_CACHE_FILE
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

                attente = 2 ** (
                    tentative - 1
                )

                print(
                    "Échec du téléchargement des emprises. "
                    f"Nouvelle tentative dans {attente}s..."
                )

                time.sleep(attente)

        finally:
            session.close()

    raise RuntimeError(
        "Impossible de télécharger le cache "
        "des emprises de stationnement."
    ) from derniere_erreur


def assurer_cache_emprises():
    """
    Garantit qu'un cache d'emprises exploitable est disponible.

    Même politique que pour les interdictions :
    - cache < 24 h : utilisation immédiate ;
    - sinon téléchargement ;
    - si l'API est temporairement indisponible, un cache de moins
      de 7 jours peut être utilisé ;
    - au-delà, l'erreur est propagée.
    """

    if cache_emprises_utilisable(
        CACHE_TTL_SECONDS
    ):

        print(
            "Cache des emprises déjà disponible."
        )

        return

    try:
        telecharger_cache_emprises()

    except RuntimeError:

        if cache_emprises_utilisable(
            MAX_STALE_SECONDS
        ):

            print(
                "⚠️ Paris Open Data indisponible : "
                "utilisation temporaire du dernier "
                "cache des emprises."
            )

            return

        raise


def iterer_emprises_cache():
    """
    Lit les emprises une par une depuis le cache JSONL.

    Le dataset n'est jamais chargé entièrement en mémoire.
    """

    assurer_cache_emprises()

    with open(
        EMPRISES_CACHE_FILE,
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
                emprise = json.loads(ligne)

            except json.JSONDecodeError as erreur:

                raise ValueError(
                    "Cache des emprises JSONL invalide "
                    f"à la ligne {numero_ligne}."
                ) from erreur

            if isinstance(emprise, dict):
                yield emprise


def recuperer_zones_interdites():
    """
    Retourne l'intégralité du dataset depuis le cache.
    Cette fonction reste présente pour compatibilité.
    """

    return list(
        iterer_zones_interdites_cache()
    )

# OUTILS DE MATCHING


def convertir_geo_shape(geo_shape, types_attendus=None):
    """
    Convertit un geo_shape Paris Open Data
    en géométrie Shapely exploitable.

    La géométrie est également réparée lorsqu'elle
    est topologiquement invalide.

    Retourne None si la géométrie reste inexploitable.
    """

    if not isinstance(geo_shape, dict):
        return None

    geojson = geo_shape

    # Paris Open Data utilise souvent une Feature GeoJSON.
    # Shapely doit recevoir uniquement sa géométrie.
    if geojson.get("type") == "Feature":
        geojson = geojson.get("geometry")

    if not isinstance(geojson, dict):
        return None

    try:

        geometrie = shape(
            geojson
        )

    except (
        GEOSException,
        TypeError,
        ValueError,
        KeyError
    ):
        return None

    if geometrie.is_empty:
        return None

    # --------------------------------------------------------
    # RÉPARATION TOPOLOGIQUE
    # --------------------------------------------------------

    # Certaines géométries Open Data peuvent être valides
    # visuellement mais incorrectes d'un point de vue
    # topologique.
    #
    # Cela peut notamment produire des résultats incohérents
    # entre distance() et intersects().
    if not geometrie.is_valid:

        try:

            geometrie = make_valid(
                geometrie
            )

        except (
            GEOSException,
            ValueError
        ):
            return None

    if geometrie.is_empty:
        return None

    # --------------------------------------------------------
    # CONTRÔLE DU TYPE
    # --------------------------------------------------------

    if types_attendus:

        # Cas normal :
        # Point, Polygon, MultiPolygon,
        # LineString ou MultiLineString.
        if geometrie.geom_type in types_attendus:
            return geometrie

        # make_valid() peut transformer une géométrie
        # invalide en GeometryCollection.
        #
        # On récupère alors uniquement les morceaux
        # correspondant au type attendu.
        if geometrie.geom_type == "GeometryCollection":

            geometries_valides = [
                element
                for element in geometrie.geoms
                if element.geom_type in types_attendus
                and not element.is_empty
            ]

            if not geometries_valides:
                return None

            # Une seule géométrie exploitable.
            if len(geometries_valides) == 1:
                return geometries_valides[0]

            # Plusieurs éléments :
            # on les regroupe proprement.
            try:

                from shapely.ops import unary_union

                geometrie = unary_union(
                    geometries_valides
                )

            except GEOSException:
                return None

            if geometrie.is_empty:
                return None

            return geometrie

        return None

    return geometrie


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


# RÉCUPÉRATION FILTRÉE


def recuperer_zones_interdites_filtrees(places_voies):
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
        "n_sq_tv": zone.get("n_sq_tv"),
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


def construire_cles_verification(places):
    """
    Construit les clés exactes de tronçon à vérifier.

    Une clé contient :
        (n_sq_tv, c_voie_vp, parite)

    Cette étape évite de construire un second index sur les
    ~975 000 interdictions : seules les clés présentes parmi les
    places à auditer sont conservées.
    """
    cles = set()

    for place in places:
        n_sq_tv = place.get("n_sq_tv")
        c_voie_vp = place.get("c_voie_vp")
        parite = normaliser_texte(place.get("parite"))

        if not n_sq_tv or not c_voie_vp or not parite:
            continue

        cles.add(
            (
                str(n_sq_tv).strip(),
                str(c_voie_vp).strip(),
                parite,
            )
        )

    return cles


def build_index_interdit_verification(cles_places):
    """
    Construit un index strict destiné à vérifier les interdictions.

    Contrairement à l'index compact principal, cet index exige :
    - le même n_sq_tv ;
    - le même c_voie_vp ;
    - la même parité.

    Seules les clés correspondant aux places réellement auditées
    sont conservées, afin de limiter fortement l'utilisation mémoire.

    L'index conserve également l'identifiant et le motif de la source
    Paris Open Data afin de pouvoir justifier chaque confirmation.
    """
    if not cles_places:
        return {}

    cles_places = set(cles_places)
    index = {}

    zones_lues = 0
    zones_retenues = 0

    for zone in iterer_zones_interdites_cache():
        zones_lues += 1

        n_sq_tv = zone.get("n_sq_tv")
        c_voie_vp = zone.get("c_voie_vp")
        parite = normaliser_texte(zone.get("parite"))

        if not n_sq_tv or not c_voie_vp or not parite:
            continue

        cle = (
            str(n_sq_tv).strip(),
            str(c_voie_vp).strip(),
            parite,
        )

        # On ne garde que les tronçons présents parmi les places
        # que le bulk souhaite réellement auditer.
        if cle not in cles_places:
            continue

        debut = normaliser_borne(zone.get("n_voieadd"))
        fin = normaliser_borne(zone.get("n_voieadf"))

        # Une interdiction sans aucune borne ne constitue pas
        # une preuve assez précise pour cette vérification stricte.
        if debut is None and fin is None:
            continue

        if debut is None:
            debut = fin

        if fin is None:
            fin = debut

        if debut > fin:
            debut, fin = fin, debut

        index.setdefault(cle, []).append(
            {
                "debut": debut,
                "fin": fin,
                "source_id": zone.get("id"),
                "regpri": zone.get("regpri"),
                "regpar": zone.get("regpar"),
                "geo_shape": zone.get("geo_shape"),
            }
        )

        zones_retenues += 1

    # Le tri permet d'arrêter rapidement les comparaisons lorsque
    # les intervalles suivants commencent après la place auditée.
    for preuves in index.values():
        preuves.sort(
            key=lambda preuve: (
                preuve["debut"],
                preuve["fin"],
            )
        )

    print(
        f"{zones_lues} zone(s) interdite(s) lue(s) "
        f"pour la vérification stricte."
    )
    print(
        f"{zones_retenues} zone(s) source retenue(s) "
        f"pour les tronçons à auditer."
    )
    print(
        f"{len(index)} clé(s) tronçon/voie/parité "
        f"dans l'index de vérification."
    )

    return index


def verifier_place_interdite(place, index_verification):
    """
    Vérifie strictement une place actuellement candidate à l'interdiction.

    Une interdiction n'est confirmée que si :
    1. n_sq_tv est identique ;
    2. c_voie_vp est identique ;
    3. la parité est identique ;
    4. les plages de numéros se croisent.

    La fonction retourne un résultat détaillé afin de pouvoir expliquer
    pourquoi une place a été confirmée ou non.
    """
    n_sq_tv = place.get("n_sq_tv")
    c_voie_vp = place.get("c_voie_vp")
    parite = normaliser_texte(place.get("parite"))

    if not n_sq_tv:
        return {
            "confirmee": False,
            "motif_verification": "n_sq_tv_absent_place",
            "preuves": [],
        }

    if not c_voie_vp:
        return {
            "confirmee": False,
            "motif_verification": "c_voie_vp_absent_place",
            "preuves": [],
        }

    if not parite:
        return {
            "confirmee": False,
            "motif_verification": "parite_absente_place",
            "preuves": [],
        }

    cle = (
        str(n_sq_tv).strip(),
        str(c_voie_vp).strip(),
        parite,
    )

    preuves_candidates = index_verification.get(cle)

    if not preuves_candidates:
        return {
            "confirmee": False,
            "motif_verification": "aucune_interdiction_sur_troncon_exact",
            "preuves": [],
        }

    debut_place = normaliser_borne(place.get("n_voieadd"))
    fin_place = normaliser_borne(place.get("n_voieadf"))
    numvoie = normaliser_borne(place.get("numvoie"))

    # numvoie reste uniquement un secours lorsque l'une des bornes
    # de tronçon manque dans la place MongoDB.
    if debut_place is None:
        debut_place = numvoie

    if fin_place is None:
        fin_place = numvoie

    if debut_place is None or fin_place is None:
        return {
            "confirmee": False,
            "motif_verification": "plage_place_inexploitable",
            "preuves": [],
        }

    if debut_place > fin_place:
        debut_place, fin_place = fin_place, debut_place

    preuves_confirmees = []

    for preuve in preuves_candidates:
        debut_interdit = preuve["debut"]
        fin_interdit = preuve["fin"]

        if fin_interdit < debut_place:
            continue

        if debut_interdit > fin_place:
            break

        # Les deux intervalles se croisent sur le même tronçon exact.
        preuves_confirmees.append(
            {
                "source_id": preuve.get("source_id"),
                "regpri": preuve.get("regpri"),
                "regpar": preuve.get("regpar"),
                "n_sq_tv": str(n_sq_tv).strip(),
                "c_voie_vp": str(c_voie_vp).strip(),
                "parite": parite,
                "n_voieadd": debut_interdit,
                "n_voieadf": fin_interdit,
                "geo_shape": preuve.get("geo_shape"),
            }
        )

    if preuves_confirmees:
        return {
            "confirmee": True,
            "motif_verification": "troncon_voie_parite_plage_confirmes",
            "preuves": preuves_confirmees,
        }

    return {
        "confirmee": False,
        "motif_verification": "plages_sans_intersection_sur_troncon_exact",
        "preuves": [],
    }


def build_index_emprises(cles_places):
    """
    Construit un index des emprises de stationnement pour les seuls
    tronçons réellement présents parmi les places candidates.

    Clé de l'index :
        (n_sq_tv, c_voie_vp, parite)

    Les polygones sont convertis une seule fois en objets Shapely.
    """

    if not cles_places:
        return {}

    cles_places = set(cles_places)
    index = {}

    emprises_lues = 0
    emprises_retenues = 0
    geometries_invalides = 0

    for emprise in iterer_emprises_cache():

        emprises_lues += 1

        n_sq_tv = emprise.get("n_sq_tv")
        c_voie_vp = emprise.get("c_voie_vp")
        parite = normaliser_texte(
            emprise.get("parite")
        )

        if (
            not n_sq_tv
            or not c_voie_vp
            or not parite
        ):
            continue

        cle = (
            str(n_sq_tv).strip(),
            str(c_voie_vp).strip(),
            parite,
        )

        if cle not in cles_places:
            continue

        geometrie = convertir_geo_shape(
            emprise.get("geo_shape"),
            {
                "Polygon",
                "MultiPolygon",
            }
        )

        if geometrie is None:
            geometries_invalides += 1
            continue

        index.setdefault(
            cle,
            []
        ).append(
            {
                "id": emprise.get("id"),
                "n_voieadd": normaliser_borne(
                    emprise.get("n_voieadd")
                ),
                "n_voieadf": normaliser_borne(
                    emprise.get("n_voieadf")
                ),
                "geometry": geometrie,
            }
        )

        emprises_retenues += 1

    print()
    print("========== INDEX EMPRISES ==========")
    print(
        f"{emprises_lues} emprise(s) lue(s)."
    )
    print(
        f"{emprises_retenues} emprise(s) "
        f"retenue(s) pour l'audit."
    )
    print(
        f"{len(index)} clé(s) "
        f"tronçon/voie/parité."
    )

    if geometries_invalides:
        print(
            f"{geometries_invalides} géométrie(s) "
            f"d'emprise invalide(s) ignorée(s)."
        )

    print("====================================")

    return index


def verifier_interdiction_geographique(
    place,
    verification_troncon,
    index_emprises
):
    """
    Effectue la preuve géographique finale d'une interdiction.

    Une place n'est confirmée que si :
    1. la vérification n_sq_tv / voie / parité / plage a réussi ;
    2. le Point MongoDB est couvert par une emprise Polygon ;
    3. cette même emprise :
       - intersecte exactement une géométrie d'interdiction ;
       - ou se trouve à 10 cm maximum de cette géométrie.

    La tolérance de 10 cm est volontairement très faible et provient
    de l'audit des écarts géométriques. Elle n'est pas utilisée comme
    remplacement d'une vraie correspondance de tronçon.
    """

    if not verification_troncon.get("confirmee"):
        return verification_troncon

    n_sq_tv = place.get("n_sq_tv")
    c_voie_vp = place.get("c_voie_vp")
    parite = normaliser_texte(
        place.get("parite")
    )

    if (
        not n_sq_tv
        or not c_voie_vp
        or not parite
    ):
        return {
            "confirmee": False,
            "motif_verification": "cle_geographique_incomplete",
            "preuves": [],
        }

    cle = (
        str(n_sq_tv).strip(),
        str(c_voie_vp).strip(),
        parite,
    )

    # Le dataset MongoDB représente les emplacements par des Points.
    point_place = convertir_geo_shape(
        place.get("geo_shape"),
        {"Point"}
    )

    if point_place is None:
        return {
            "confirmee": False,
            "motif_verification": "point_place_inexploitable",
            "preuves": [],
        }

    emprises_candidates = index_emprises.get(cle)

    if not emprises_candidates:
        return {
            "confirmee": False,
            "motif_verification": "aucune_emprise_sur_troncon",
            "preuves": [],
        }

    # On ne retient que les polygones couvrant réellement le Point.
    # covers() accepte aussi un Point exactement placé sur la bordure.
    emprises_place = []

    for emprise in emprises_candidates:
        try:
            if emprise["geometry"].covers(
                point_place
            ):
                emprises_place.append(emprise)
        except GEOSException:
            continue

    if not emprises_place:
        return {
            "confirmee": False,
            "motif_verification": "aucune_emprise_contenant_la_place",
            "preuves": [],
        }

    preuves_geographiques = []

    for preuve in verification_troncon.get(
        "preuves",
        []
    ):
        geometrie_interdiction = convertir_geo_shape(
            preuve.get("geo_shape"),
            {
                "LineString",
                "MultiLineString",
            }
        )

        if geometrie_interdiction is None:
            continue

        for emprise in emprises_place:
            try:
                intersection = emprise["geometry"].intersects(
                    geometrie_interdiction
                )
            except GEOSException:
                continue

            # Une intersection exacte constitue la meilleure preuve.
            if intersection:
                distance_m = 0.0
                methode_geographique = "intersection"

            else:
                # Si l'intersection exacte échoue, on mesure l'écart
                # réel en mètres dans Lambert-93.
                emprise_l93 = emprise.get("_geometry_l93")

                if emprise_l93 is None:
                    emprise_l93 = projeter_lambert93(
                        emprise.get("geometry")
                    )
                    emprise["_geometry_l93"] = emprise_l93

                interdiction_l93 = preuve.get("_geometry_l93")

                if interdiction_l93 is None:
                    interdiction_l93 = projeter_lambert93(
                        geometrie_interdiction
                    )
                    preuve["_geometry_l93"] = interdiction_l93

                if (
                    emprise_l93 is None
                    or interdiction_l93 is None
                ):
                    continue

                try:
                    distance_m = float(
                        emprise_l93.distance(
                            interdiction_l93
                        )
                    )
                except GEOSException:
                    continue

                # Au-delà de 10 cm, la géométrie n'est pas confirmée.
                if distance_m > TOLERANCE_GEOMETRIQUE_METRES:
                    continue

                methode_geographique = "tolerance_10cm"

            preuves_geographiques.append(
                {
                    "source_id": preuve.get("source_id"),
                    "emprise_id": emprise.get("id"),
                    "regpri": preuve.get("regpri"),
                    "regpar": preuve.get("regpar"),
                    "n_sq_tv": str(n_sq_tv).strip(),
                    "c_voie_vp": str(c_voie_vp).strip(),
                    "parite": parite,
                    "n_voieadd": preuve.get("n_voieadd"),
                    "n_voieadf": preuve.get("n_voieadf"),
                    "methode_geographique": methode_geographique,
                    "distance_m": distance_m,
                }
            )

    if preuves_geographiques:
        return {
            "confirmee": True,
            "motif_verification": "geometrie_confirmee",
            "preuves": preuves_geographiques,
        }

    return {
        "confirmee": False,
        "motif_verification": (
            "aucune_intersection_ou_proximite_geographique"
        ),
        "preuves": [],
    }


def verifier_place_interdite_complete(
    place,
    index_verification,
    index_emprises
):
    """
    Exécute les deux niveaux de preuve d'une interdiction :

    1. vérification stricte du tronçon ;
    2. vérification géographique Point -> emprise -> interdiction.
    """

    verification_troncon = verifier_place_interdite(
        place,
        index_verification
    )

    if not verification_troncon.get("confirmee"):
        return verification_troncon

    return verifier_interdiction_geographique(
        place,
        verification_troncon,
        index_emprises
    )


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

    # FUSION DES INTERVALLES

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
