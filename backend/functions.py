from pathlib import Path
import logging
import sys
import hashlib
import hmac


def setup_logger(process_name):
    """
    Configure the logger with both console and file handlers.
    """
    logger = logging.getLogger(process_name)
    logger.setLevel(logging.DEBUG)  # Capture all levels

    # Prevent adding handlers multiple times if setup_logger is called again
    if logger.hasHandlers():
        logger.handlers.clear()

    # Formatter for logs
    formatter = logging.Formatter(
        fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )

    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)  # Show INFO and above in console
    console_handler.setFormatter(formatter)

    # File handler
    file_handler = logging.FileHandler("app.log", mode="a", encoding="utf-8")
    file_handler.setLevel(logging.DEBUG)  # Save all logs to file
    file_handler.setFormatter(formatter)

    # Add handlers to logger
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)

    return logger

def clean_response(response):
    return response.replace('\\','').replace('["{','[{').replace('}"]','}]').replace('}", "{','},{').encode('utf-8')
    
def generate_key(secret_phrase: str) -> str:
    """
    Generate a SHA-256 hash from the secret phrase.
    Returns the hexadecimal representation of the hash.
    """
    if not isinstance(secret_phrase, str) or not secret_phrase.strip():
        raise ValueError("Secret phrase must be a non-empty string.")
    
    # Encode to bytes and hash
    return hashlib.sha256(secret_phrase.encode('utf-8')).hexdigest()

def verify_key(secret_phrase: str, stored_hash: str) -> bool:
    """
    Verify if the SHA-256 hash of the provided phrase matches the stored hash.
    Uses constant-time comparison to prevent timing attacks.
    """
    if not isinstance(stored_hash, str) or len(stored_hash) != 64:
        raise ValueError("Stored hash must be a 64-character hexadecimal string.")
    
    # Generate hash from input phrase
    computed_hash = generate_key(secret_phrase)
    
    # Constant-time comparison
    return hmac.compare_digest(computed_hash, stored_hash)

    
    