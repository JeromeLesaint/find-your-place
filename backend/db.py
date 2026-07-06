from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure
from bson import json_util
from bson.errors import InvalidId
import os
import json

class db:
    def connection(self):
        """
        Connects to MongoDB and creates a collection if it doesn't exist.
        """
        try:
            # Connect to MongoDB server
            self.client = MongoClient(os.getenv('MONGODB_URI'), serverSelectionTimeoutMS=5000)
            self.client.server_info()  # Force connection check

            # Access the database
            self.db = self.client["emplacements"]
            self.collection = self.db["paris"]
            
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
           }
        })        
        return json.dumps(list(cursor), default=json_util.default, ensure_ascii=False)    
    def close(self):
        self.client.close()
            