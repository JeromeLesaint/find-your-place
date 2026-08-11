import requests
import os
from dotenv import load_dotenv
from pathlib import Path
import logging
import sys
import json
from pymongo import MongoClient, GEOSPHERE
from pymongo.errors import ConnectionFailure, OperationFailure
import time
from functions import setup_logger

def create_mongodb_collection(db_name, collection_name,uri,jsonfile):
    """
    Connects to MongoDB and creates a collection if it doesn't exist.
    """
    try:
        # Connect to MongoDB server
        client = MongoClient(uri, serverSelectionTimeoutMS=5000)
        client.server_info()  # Force connection check

        # Access the database
        db = client[db_name]

        # Check if collection already exists
        if collection_name in db.list_collection_names():
            log.error(f"Collection '{collection_name}' already exists in database '{db_name}'.")
        else:
            # Explicitly create the collection
            db.create_collection(collection_name)
            
            log.info(f"Collection '{collection_name}' created successfully in database '{db_name}'.")
            
            collection = db[collection_name]
            
            # Import datas
                        
            # Open and read JSON file
            with open(jsonfile, 'r', encoding='utf-8') as file:
                data = json.load(file)

            # Insert data into MongoDB
            if isinstance(data, list): # For multiple records
                collection.insert_many(data)
            else: # For a single record
                collection.insert_one(data)
                 
            index_name = collection.create_index([("geo_shape.geometry", GEOSPHERE)])
            log.info(f"2dsphere index created: {index_name}")
            
            

    except errors.ServerSelectionTimeoutError:
        log.error("Error: Could not connect to MongoDB server. Check your URI and network.")
    except errors.CollectionInvalid:
        log.error(f"Error: Collection '{collection_name}' already exists.")
    except Exception as e:
        log.error(f"Unexpected error: {e}")
    finally:
        client.close()

def delete_collection(db_name, collection_name, uri):
    """
    Deletes a MongoDB collection safely.
    
    :param db_name: Name of the database
    :param collection_name: Name of the collection to delete
    :param uri: MongoDB connection URI (default: local instance)
    """
    try:
        # Connect to MongoDB
        client = MongoClient(uri, serverSelectionTimeoutMS=5000)
        client.admin.command('ping')  # Test connection

        db = client[db_name]

        # Check if collection exists before dropping
        if collection_name in db.list_collection_names():
            db[collection_name].drop()
            log.info(f"Collection '{collection_name}' deleted successfully from database '{db_name}'.")
        else:
            log.error(f"Collection '{collection_name}' does not exist in database '{db_name}'.")

    except ConnectionFailure:
        log.error("Error: Could not connect to MongoDB server.")
    except OperationFailure as e:
        log.error(f"MongoDB operation failed: {e}")
    except Exception as e:
        log.error(f"Unexpected error: {e}")
    finally:
        client.close()

def delete_file(file_path):
    """
    Deletes a file if it exists.
    :param file_path: Path to the file to delete
    """
    try:
        # Check if the path exists and is a file
        if not os.path.exists(file_path):
            log.error(f"Error: '{file_path}' does not exist.")
            return
        if not os.path.isfile(file_path):
            log.error(f"Error: '{file_path}' is not a file.")
            return
        
        os.remove(file_path)
        log.info(f"File '{file_path}' deleted successfully.")
    
    except PermissionError:
        log.error(f"Permission denied: Cannot delete '{file_path}'.")
    except OSError as e:
        log.error(f"Error deleting file '{file_path}': {e}")

def download_file(url, save_path, chunk_size=1024):
    """
    Downloads a file from the given URL and saves it to the specified path.

    Args:
        url (str): The URL of the file to download.
        save_path (str): The local file path where the file will be saved.
        chunk_size (int): Size of each chunk to read (default: 1024 bytes).
    """
    try:
        # Send HTTP GET request with stream=True for large files
        with requests.get(url, stream=True, timeout=15) as response:
            response.raise_for_status()  # Raise HTTPError for bad responses

            # Create directory if it doesn't exist
            os.makedirs(os.path.dirname(save_path), exist_ok=True)

            # Write file in chunks
            with open(save_path, 'wb') as file:
                for chunk in response.iter_content(chunk_size=chunk_size):
                    if chunk:  # Filter out keep-alive chunks
                        file.write(chunk)

        log.info(f"✅ File downloaded successfully: {save_path}")

    except requests.exceptions.MissingSchema:
        log.error("❌ Invalid URL format. Please include http:// or https://")
    except requests.exceptions.ConnectionError:
        log.error("❌ Network connection error.")
    except requests.exceptions.Timeout:
        log.error("❌ Request timed out.")
    except requests.exceptions.HTTPError as e:
        log.error(f"❌ HTTP error: {e}")
    except Exception as e:
        log.error(f"❌ An unexpected error occurred: {e}")


# Example usage
if __name__ == "__main__":
    # Load environment variables from the .env file (if present)
    load_dotenv()
    log = setup_logger()
    file_url = os.getenv('EMPLACEMENTS_URL')  # Replace with your file URL
    save_location = os.getenv('SAVE_LOCATION')       # Local path to save the file
    mongodb_uri = os.getenv('MONGODB_URI')

    start = time.time()

    download_file(file_url, save_location)

    # Access or create database and collection
    db = "emplacements"
    collection = "paris" 

    delete_collection(db,collection,mongodb_uri)
    create_mongodb_collection(db,collection,mongodb_uri,save_location)
    
    end = time.time()
    
    log.info(f'Elapsed: {end - start:.2f} seconds')
