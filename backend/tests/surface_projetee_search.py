from pymongo import MongoClient
import time

# Approximation de la surface projetée d'une voiture
def surface_projete(longueur_m, largeur_m):
    if longueur_m <= 0 or largeur_m <= 0:
        raise ValueError("Les dimensions doivent être positives.")
    return longueur_m * largeur_m

# Exemple : voiture de 4,5 m de long et 1,8 m de large
try:
    surface = surface_projete(4.5, 1.8)
    print(f"Surface projetée ≈ {surface:.2f} m²")
except ValueError as e:
    print("Erreur :", e)



# Connect to local MongoDB server
client = MongoClient("mongodb://localhost:27017/")

# Access or create database and collection
db = client["emplacements"]
collection = db["paris"]

start = time.time()
print(f'Start time: {start}')

# Query documents
for record in collection.find({'surface_calculee':{ '$lt': surface }}):
    print(record)
    
end = time.time()
print(f'Elapsed: {end - start:.2f} seconds')