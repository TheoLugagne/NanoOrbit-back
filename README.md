# NanoOrbit-back

API Flask JSON pour le projet NanoOrbit (Séance 1 — authentification MySQL Option A, routes métier).

## Prérequis

- Python 3.10+
- MySQL avec la base `nanoOrbit_db` créée et peuplée (Phases 1–4 du sujet)
- Comptes MySQL Phase 4 actifs : `operateur_sat`, `analyste_data`, `resp_mission`, `admin_nano`

## Installation

```bash
python -m venv .venv
```

**Windows (PowerShell) :**

```powershell
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

**Linux / macOS :**

```bash
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Éditez `.env` et définissez au minimum une clé secrète unique pour `FLASK_SECRET_KEY`. Les identifiants MySQL des utilisateurs ne figurent pas dans `.env` : ils sont saisis au login (Option A).

Variables disponibles (voir `.env.example`) :

| Variable | Description |
|----------|-------------|
| `FLASK_SECRET_KEY` | Clé pour signer les cookies de session |
| `FLASK_ENV` | `development` ou `production` |
| `MYSQL_HOST` | Hôte MySQL (défaut : `localhost`) |
| `MYSQL_PORT` | Port MySQL (défaut : `3306`) |
| `MYSQL_DATABASE` | Nom de la base (défaut : `nanoOrbit_db`) |

## Démarrage

```bash
python run.py
```

L’application écoute sur `http://0.0.0.0:5000`.

Alternative avec la CLI Flask :

```bash
flask --app run run
```

## Tests avec curl

Une fois les routes auth et métier en place :

```bash
# Connexion (remplacer le mot de passe)
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"analyste_data\",\"password\":\"VOTRE_MOT_DE_PASSE\"}" \
  -c cookies.txt

# Session courante
curl http://localhost:5000/api/auth/me -b cookies.txt

# Satellites opérationnels (nécessite une session)
curl http://localhost:5000/api/satellites -b cookies.txt

# Déconnexion
curl -X POST http://localhost:5000/api/auth/logout -b cookies.txt
```

## Structure du projet

```
app/
├── __init__.py    # Factory create_app()
├── config.py      # Configuration depuis .env
├── auth/          # Login, logout, détection des rôles
├── api/           # Routes front-office / back-office
├── db.py          # Connexion MySQL par utilisateur (session)
└── middleware/    # @login_required, @role_required
run.py             # Point d'entrée
```
