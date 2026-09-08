import math
from typing import Tuple

# ---------- 1. Euclidean Distance ----------
def euclidean_distance(p1: Tuple[float, float], p2: Tuple[float, float]) -> float:
    """Calculate Euclidean distance between two points in 2D or 3D."""
    if len(p1) != len(p2):
        raise ValueError("Points must have the same dimensions.")
    return math.dist(p1, p2)  # Python 3.8+ built-in

# ---------- 2. Manhattan Distance ----------
def manhattan_distance(p1: Tuple[float, float], p2: Tuple[float, float]) -> float:
    """Calculate Manhattan (L1) distance."""
    if len(p1) != len(p2):
        raise ValueError("Points must have the same dimensions.")
    return sum(abs(a - b) for a, b in zip(p1, p2))

# ---------- 3. Haversine Distance (Geographic) ----------
def haversine_distance(coord1: Tuple[float, float], coord2: Tuple[float, float]) -> float:
    """
    Calculate the great-circle distance between two points on Earth.
    Coordinates are given as (latitude, longitude) in decimal degrees.
    Returns distance in kilometers.
    """
    lat1, lon1 = coord1
    lat2, lon2 = coord2

    # Convert degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])

    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat / 2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2)**2
    c = 2 * math.asin(math.sqrt(a))
    R = 6371.0  # Earth's radius in kilometers
    return R * c

# ---------- Example Usage ----------
if __name__ == "__main__":
    # Cartesian points
    p1 = (3, 4)
    p2 = (7, 1)

    print("Euclidean distance:", euclidean_distance(p1, p2))
    print("Manhattan distance:", manhattan_distance(p1, p2))

    # Geographic coordinates (Paris, London)
    paris = (48.8566, 2.3522)
    london = (51.5074, -0.1278)
    print("Haversine distance (km):", haversine_distance(paris, london))
