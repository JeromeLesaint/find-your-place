from pathlib import Path
import logging
import sys
import os


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

    debug_mode = os.getenv("DEBUG", "false").strip().lower() == "true"

    # Le fichier garde toujours les logs ; la console les affiche seulement en debug.
    if debug_mode:
        logger.addHandler(console_handler)
    logger.addHandler(file_handler)

    return logger

def clean_response(response):
    return response.replace('\\','').replace('["{','[{').replace('}"]','}]').replace('}", "{','},{').encode('utf-8')
