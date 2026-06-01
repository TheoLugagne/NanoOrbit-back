import os
import sys

# Répertoire du projet dans sys.path (important : le CWD n’est pas fiable sous uWSGI)

sys.path.insert(0, os.path.dirname(__file__))

from dotenv import load_dotenv

load_dotenv()

from app import create_app

application = create_app()