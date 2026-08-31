from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
from bson import json_util
from bson.errors import InvalidId
import os
import json
from dotenv import load_dotenv

class db:
    def connection(self):
        """
        Connects to MongoDB and creates a collection if it doesn't exist.
        """
        load_dotenv()
        try:
            # Connect to MongoDB server
            self.client = MongoClient(os.getenv('MONGODB_URI'), serverSelectionTimeoutMS=5000)
            self.client.server_info()  # Force connection check

            # Access the database
            self.db = self.client[os.getenv('DATABASE_NAME')]
            self.collection = self.db[os.getenv('COLLECTION_NAME') ]
            
        except errors.ServerSelectionTimeoutError:
            log.error("Error: Could not connect to MongoDB server. Check your URI and network.")
        except errors.CollectionInvalid:
            log.error(f"Error: Collection '{collection_name}' already exists.")
        except Exception as e:
            log.error(f"Unexpected error: {e}")
    def findbydistance(self,lon, lat):
        requete_places_de_rue = {
           "geo_shape.geometry": {
              "$near": {
                 "$geometry": {
                    "type": "Point",
                    "coordinates": [ lon,lat ]
                 },
                 "$maxDistance" : int(os.getenv('DISTANCE_MAXI'))
              }
           },
        }
        requete_parkings = {
           "geolocalisation.forme_geographique.geometry": {
              "$near": {
                 "$geometry": {
                    "type": "Point",
                    "coordinates": [ lon,lat ]
                 },
                 "$maxDistance" : int(os.getenv('DISTANCE_MAXI'))
              }
           },
           "type_donnee": "parking"
        }
        places_de_rue = list(self.collection.find(requete_places_de_rue))
        parkings = list(self.collection.find(requete_parkings))
        return json.dumps(places_de_rue + parkings, default=json_util.default, ensure_ascii=False)
    def close(self):
        self.client.close()
