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
        cursor=self.collection.find({
           "geo_shape.geometry": {
              "$near": {
                 "$geometry": {
                    "type": "Point",
                    "coordinates": [ lon,lat ]
                 },
                 "$maxDistance" : int(os.getenv('DISTANCE_MAXI'))
              }
           },
           # Les parcs amodiés sont réservés à leurs titulaires : ils ne
           # doivent pas être proposés comme une solution de stationnement.
           "parc_amod": {"$nin": [True, 1, "1", "oui", "OUI"]},
        })
        return json.dumps(list(cursor), default=json_util.default, ensure_ascii=False)
    def close(self):
        self.client.close()
