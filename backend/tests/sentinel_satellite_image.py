"""
Récupération d'une image satellite/aérienne précise, à partir d'une adresse
ou de coordonnées GPS, avec cadrage serré et netteté optimisée.

Trois sources possibles (--source) :
  1. sentinel2 (défaut, GRATUIT) : Sentinel-2 L2A via Sentinel Hub,
     résolution native 10 m/pixel, avec rééchantillonnage bicubique +
     unsharp mask pour un rendu plus net (aucun détail réel ajouté).
  2. byoc (PAYANT) : collection tierce haute résolution (Planet SkySat
     ~0.5 m, Airbus Pléiades ~0.5-0.8 m, Maxar ~0.3 m) importée dans ton
     compte Sentinel Hub via "Data Import"/BYOC. Nécessite un abonnement
     séparé chez le fournisseur + un collection-id Sentinel Hub.
  3. ign (GRATUIT, France uniquement) : orthophotos aériennes de l'IGN
     (Géoplateforme), résolution ~0.15-0.20 m/pixel selon les zones —
     bien plus net que Sentinel-2, aucune clé API nécessaire.

Prérequis :
    pip install sentinelhub geopy pillow numpy requests

Compte Sentinel Hub (nécessaire seulement pour --source sentinel2 ou byoc) :
    - https://www.sentinel-hub.com/ > Account Settings > OAuth clients
      pour obtenir Client ID / Client Secret.

Exemples :
    # IGN, France, très haute résolution, gratuit, sans clé
    python sentinel_satellite_image.py --address "Tour Eiffel, Paris" \\
        --source ign --size-m 200 --sharpen

    # Sentinel-2 gratuit, cadrage serré, netteté renforcée
    python sentinel_satellite_image.py --address "Tour Eiffel, Paris" \\
        --size-m 500 --sharpen --client-id XXX --client-secret YYY

    # Haute résolution payante (collection BYOC déjà importée)
    python sentinel_satellite_image.py --lat 48.8584 --lon 2.2945 \\
        --source byoc --collection-id <ID_BYOC> --size-m 300 \\
        --client-id XXX --client-secret YYY
"""

import argparse
import io
import math
import os
import sys
from datetime import date, timedelta

import requests
from sentinelhub import (
    SHConfig,
    CRS,
    BBox,
    bbox_to_dimensions,
    SentinelHubRequest,
    DataCollection,
    MimeType,
    ResamplingType,
)
from geopy.geocoders import Nominatim


# ---------------------------------------------------------------------------
# 1. Géocodage : adresse -> coordonnées GPS
# ---------------------------------------------------------------------------
def address_to_coordinates(address: str) -> tuple[float, float]:
    """Convertit une adresse en (latitude, longitude) via Nominatim (OpenStreetMap)."""
    geolocator = Nominatim(user_agent="sentinel_satellite_image_script")
    location = geolocator.geocode(address)
    if location is None:
        raise ValueError(f"Adresse introuvable : {address}")
    return location.latitude, location.longitude


# ---------------------------------------------------------------------------
# 2. Configuration Sentinel Hub
# ---------------------------------------------------------------------------
def build_config(client_id: str, client_secret: str) -> SHConfig:
    config = SHConfig()
    config.sh_client_id = client_id
    config.sh_client_secret = client_secret
    if not config.sh_client_id or not config.sh_client_secret:
        raise ValueError(
            "Client ID / Client Secret Sentinel Hub manquants. "
            "Passez --client-id/--client-secret ou définissez "
            "SH_CLIENT_ID / SH_CLIENT_SECRET."
        )
    return config


# ---------------------------------------------------------------------------
# 3. Evalscripts
# ---------------------------------------------------------------------------
# Sentinel-2 : couleurs naturelles, léger renforcement du contraste
EVALSCRIPT_SENTINEL2 = """
//VERSION=3
function setup() {
    return {
        input: ["B02", "B03", "B04"],
        output: { bands: 3 }
    };
}
function evaluatePixel(sample) {
    return [2.5 * sample.B04, 2.5 * sample.B03, 2.5 * sample.B02];
}
"""

# Collections tierces (BYOC) : la plupart exposent des bandes Red/Green/Blue.
# À adapter selon le fournisseur si les noms de bandes diffèrent (vérifier
# dans le Configuration Utility de Sentinel Hub, onglet de la collection).
EVALSCRIPT_BYOC_RGB = """
//VERSION=3
function setup() {
    return {
        input: ["Red", "Green", "Blue"],
        output: { bands: 3 }
    };
}
function evaluatePixel(sample) {
    return [2.5 * sample.Red / 255, 2.5 * sample.Green / 255, 2.5 * sample.Blue / 255];
}
"""

MAX_PIXELS = 2500  # limite du Process API par requête (côté largeur/hauteur)


# ---------------------------------------------------------------------------
# 4. Construction de la requête + téléchargement
# ---------------------------------------------------------------------------
def get_satellite_image(
    lat: float,
    lon: float,
    config: SHConfig,
    size_m: float = 500.0,
    resolution: float | None = None,
    days_back: int = 90,
    collection_id: str | None = None,
    resampling: str = "BICUBIC",
    sharpen: bool = False,
    output_path: str = "satellite_image.png",
):
    """
    Télécharge une image satellite centrée précisément sur (lat, lon).

    size_m       : largeur/hauteur de la zone couverte, en MÈTRES (cadrage serré).
    resolution   : résolution en m/pixel. Si None : résolution native
                   (10 m pour Sentinel-2, sinon calculée pour rester sous
                   MAX_PIXELS avec la collection tierce).
    days_back    : fenêtre de recherche (jours) pour l'image la moins nuageuse.
    collection_id: identifiant Sentinel Hub d'une collection tierce (BYOC)
                   pour la haute résolution payante. Si None -> Sentinel-2 L2A.
    resampling   : "BICUBIC", "BILINEAR" ou "NEAREST" — méthode utilisée par
                   Sentinel Hub pour le sur/sous-échantillonnage côté serveur.
    sharpen      : applique un unsharp mask en post-traitement (plus net à
                   l'affichage, mais n'ajoute aucun détail réel).
    """
    # Conversion précise mètres -> degrés autour du point demandé
    delta_lat_deg = (size_m / 2) / 111_320.0
    delta_lon_deg = (size_m / 2) / (111_320.0 * math.cos(math.radians(lat)))

    bbox = BBox(
        bbox=[
            lon - delta_lon_deg,
            lat - delta_lat_deg,
            lon + delta_lon_deg,
            lat + delta_lat_deg,
        ],
        crs=CRS.WGS84,
    )

    if collection_id:
        data_collection = DataCollection.define_byoc(collection_id)
        evalscript = EVALSCRIPT_BYOC_RGB
        native_resolution = resolution or 0.5  # ordre de grandeur typique très haute résolution
    else:
        data_collection = DataCollection.SENTINEL2_L2A
        evalscript = EVALSCRIPT_SENTINEL2
        native_resolution = resolution or 10.0

    size = bbox_to_dimensions(bbox, resolution=native_resolution)

    # On respecte la limite de pixels du Process API en resserrant la résolution
    # si besoin, plutôt que de couper l'image.
    if max(size) > MAX_PIXELS:
        scale = max(size) / MAX_PIXELS
        native_resolution *= scale
        size = bbox_to_dimensions(bbox, resolution=native_resolution)

    resampling_map = {
        "BICUBIC": ResamplingType.BICUBIC,
        "BILINEAR": ResamplingType.BILINEAR,
        "NEAREST": ResamplingType.NEAREST,
    }
    resampling_type = resampling_map.get(resampling.upper(), ResamplingType.BICUBIC)

    time_interval = (
        (date.today() - timedelta(days=days_back)).isoformat(),
        date.today().isoformat(),
    )

    request = SentinelHubRequest(
        evalscript=evalscript,
        input_data=[
            SentinelHubRequest.input_data(
                data_collection=data_collection,
                time_interval=time_interval,
                mosaicking_order="leastCC",
                upsampling=resampling_type,
                downsampling=resampling_type,
            )
        ],
        responses=[SentinelHubRequest.output_response("default", MimeType.PNG)],
        bbox=bbox,
        size=size,
        config=config,
    )

    images = request.get_data()
    image = images[0]

    from PIL import Image, ImageFilter
    import numpy as np

    pil_image = Image.fromarray(np.array(image))

    if sharpen:
        pil_image = pil_image.filter(
            ImageFilter.UnsharpMask(radius=2, percent=150, threshold=2)
        )

    pil_image.save(output_path)
    print(f"Image enregistrée : {output_path}  ({size[0]}x{size[1]} px, "
          f"~{native_resolution:.2f} m/pixel)")
    return output_path


# ---------------------------------------------------------------------------
# 4bis. Source IGN (orthophotos aériennes françaises, gratuit, sans clé)
# ---------------------------------------------------------------------------
IGN_WMS_URL = "https://data.geopf.fr/wms-r/wms"
IGN_LAYER = "ORTHOIMAGERY.ORTHOPHOTOS"  # mosaïque orthophoto la plus récente


def get_ign_orthophoto(
    lat: float,
    lon: float,
    size_m: float = 200.0,
    resolution: float = 0.2,
    sharpen: bool = False,
    output_path: str = "satellite_image.png",
):
    """
    Télécharge une orthophoto aérienne IGN (France uniquement) centrée
    précisément sur (lat, lon), via le service WMS public de la
    Géoplateforme (aucune clé API nécessaire).

    size_m     : largeur/hauteur de la zone couverte, en mètres.
    resolution : résolution cible en m/pixel (la donnée source est
                 généralement ~0.15-0.20 m/pixel selon les départements ;
                 demander plus fin ne fait qu'interpoler).
    sharpen    : applique un unsharp mask en post-traitement.
    """
    delta_lat_deg = (size_m / 2) / 111_320.0
    delta_lon_deg = (size_m / 2) / (111_320.0 * math.cos(math.radians(lat)))

    min_lon, max_lon = lon - delta_lon_deg, lon + delta_lon_deg
    min_lat, max_lat = lat - delta_lat_deg, lat + delta_lat_deg

    width = int(size_m / resolution)
    height = int(size_m / resolution)
    if max(width, height) > MAX_PIXELS:
        scale = max(width, height) / MAX_PIXELS
        width = int(width / scale)
        height = int(height / scale)

    params = {
        "SERVICE": "WMS",
        "VERSION": "1.3.0",
        "REQUEST": "GetMap",
        "LAYERS": IGN_LAYER,
        "STYLES": "",
        "CRS": "CRS:84",  # axes en ordre lon,lat (plus simple que EPSG:4326 en WMS 1.3)
        "BBOX": f"{min_lon},{min_lat},{max_lon},{max_lat}",
        "WIDTH": width,
        "HEIGHT": height,
        "FORMAT": "image/jpeg",
    }

    response = requests.get(IGN_WMS_URL, params=params, timeout=30)
    response.raise_for_status()
    if "image" not in response.headers.get("Content-Type", ""):
        raise RuntimeError(
            f"Réponse inattendue du service IGN (pas de zone couverte à cet "
            f"endroit, ou erreur) : {response.text[:300]}"
        )

    from PIL import Image, ImageFilter

    pil_image = Image.open(io.BytesIO(response.content)).convert("RGB")

    if sharpen:
        pil_image = pil_image.filter(
            ImageFilter.UnsharpMask(radius=2, percent=150, threshold=2)
        )

    pil_image.save(output_path)
    print(f"Image enregistrée : {output_path}  ({width}x{height} px, "
          f"~{resolution:.2f} m/pixel, source IGN)")
    return output_path


# ---------------------------------------------------------------------------
# 5. Point d'entrée en ligne de commande
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Télécharge une image satellite précise via Sentinel Hub."
    )
    parser.add_argument("--address", type=str, help="Adresse à géocoder")
    parser.add_argument("--lat", type=float, help="Latitude (si pas d'adresse)")
    parser.add_argument("--lon", type=float, help="Longitude (si pas d'adresse)")
    parser.add_argument(
        "--size-m", type=float, default=500.0,
        help="Taille du cadrage en MÈTRES autour du point (défaut: 500)"
    )
    parser.add_argument(
        "--resolution", type=float, default=None,
        help="Résolution en m/pixel. Par défaut : native (10 m Sentinel-2, "
             "0.5 m indicatif pour collection tierce)."
    )
    parser.add_argument("--days-back", type=int, default=90, help="Fenêtre de recherche en jours")
    parser.add_argument(
        "--source", type=str, default="sentinel2",
        choices=["sentinel2", "byoc", "ign"],
        help="sentinel2 (défaut, gratuit, 10 m/pixel) | byoc (payant, très haute "
             "résolution, nécessite --collection-id) | ign (gratuit, France "
             "uniquement, ~0.2 m/pixel, aucune clé requise)"
    )
    parser.add_argument(
        "--collection-id", type=str, default=None,
        help="ID Sentinel Hub d'une collection tierce (requis si --source byoc)."
    )
    parser.add_argument(
        "--resampling", type=str, default="BICUBIC",
        choices=["BICUBIC", "BILINEAR", "NEAREST"],
        help="Méthode de rééchantillonnage côté serveur (défaut: BICUBIC)"
    )
    parser.add_argument(
        "--sharpen", action="store_true",
        help="Applique un renforcement de netteté (unsharp mask) en post-traitement"
    )
    parser.add_argument("--output", type=str, default="satellite_image.png")
    parser.add_argument("--client-id", type=str, default=os.environ.get("SH_CLIENT_ID"))
    parser.add_argument("--client-secret", type=str, default=os.environ.get("SH_CLIENT_SECRET"))

    args = parser.parse_args()

    if args.address:
        lat, lon = address_to_coordinates(args.address)
        print(f"Adresse '{args.address}' -> lat={lat:.6f}, lon={lon:.6f}")
    elif args.lat is not None and args.lon is not None:
        lat, lon = args.lat, args.lon
    else:
        print("Erreur : fournissez soit --address, soit --lat et --lon.", file=sys.stderr)
        sys.exit(1)

    if args.source == "ign":
        get_ign_orthophoto(
            lat=lat,
            lon=lon,
            size_m=args.size_m,
            resolution=args.resolution or 0.2,
            sharpen=args.sharpen,
            output_path=args.output,
        )
        return

    if args.source == "byoc" and not args.collection_id:
        print("Erreur : --source byoc nécessite --collection-id.", file=sys.stderr)
        sys.exit(1)

    config = build_config(args.client_id, args.client_secret)

    get_satellite_image(
        lat=lat,
        lon=lon,
        config=config,
        size_m=args.size_m,
        resolution=args.resolution,
        days_back=args.days_back,
        collection_id=args.collection_id if args.source == "byoc" else None,
        resampling=args.resampling,
        sharpen=args.sharpen,
        output_path=args.output,
    )


if __name__ == "__main__":
    main()
