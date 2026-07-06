from pymongo import MongoClient
import time

# Connect to local MongoDB server
client = MongoClient("mongodb://localhost:27017/")

# Access or create database and collection
db = client["emplacements"]
collection = db["paris"]

start = time.time()

# Query documents
for record in collection.find({"typsta":"Epi"}):
    print(record)
    
end = time.time()
client.close()
print(f'Elapsed: {end - start:.2f} seconds')