from pymongo import MongoClient
import time
from dotenv import load_dotenv
import os

load_dotenv()

# Connect to local MongoDB server
client = MongoClient(os.getenv('MONGODB_URI'))

# Access or create database and collection
db = client["emplacements"]
collection = db["paris"]

start = time.time()

# Query documents
for record in collection.find({
   "geo_shape.geometry": {
      "$near": {
         "$geometry": {
            "type": "Point",
            "coordinates": [ 2.368791,48.853877 ]
         },
         "$maxDistance" : int(os.getenv('DISTANCE_MAXI'))
      }
   }
}):
    print(record)
    
end = time.time()
client.close()
print(f'Elapsed: {end - start:.2f} seconds')