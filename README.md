# NanoOrbit-back

API Flask JSON pour le projet NanoOrbit (Séance 1 — authentification MySQL Option A, routes métier).

**Niveau :** Autonome · **Auth :** Option A (connexion MySQL réelle) · **Interface :** API JSON

## Prérequis

- Python 3.10+
- MySQL avec la base `nanoOrbit_db` créée et peuplée (Phases 1–4 du sujet)
- Vue Phase 3 : `VUE_SATELLITES_OPERATIONNELS`
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

Éditez `.env` et définissez au minimum une clé secrète unique pour `FLASK_SECRET_KEY`.

Les identifiants MySQL des utilisateurs ne figurent **pas** dans `.env` : ils sont saisis au login (Option A). Le mot de passe est conservé en session serveur pour reconnecter à MySQL à chaque requête (choix pédagogique du sujet).

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

L'application écoute sur `http://0.0.0.0:5000`.

Une page de test statique est disponible sur `http://localhost:5000/` pour tester l'authentification dans le navigateur.

Alternative avec la CLI Flask :

```bash
flask --app run run
```

## Endpoints (Séance 1)

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `GET` | `/api/health` | Non | Santé de l'application |
| `GET` | `/api/health/db` | Oui | Test `SELECT 1` avec les creds de session |
| `POST` | `/api/auth/login` | Non | Connexion MySQL + création de session |
| `POST` | `/api/auth/logout` | Non | Destruction de session |
| `GET` | `/api/auth/me` | Session | Profil courant |
| `GET` | `/api/satellites` | Oui | Satellites opérationnels (`VUE_SATELLITES_OPERATIONNELS`) |

### Profils et accès

| Compte MySQL | Rôle app | Front-office | Back-office |
|--------------|----------|--------------|-------------|
| `analyste_data` | `analyste` | Oui | Non |
| `operateur_sat` | `operateur` | Oui | Partiel |
| `resp_mission` | `responsable` | Oui | Partiel |
| `admin_nano` | `admin` | Oui | Complet |

## Tests avec curl

```bash
# Santé
curl http://localhost:5000/api/health

# Connexion (remplacer le mot de passe)
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"analyste_data\",\"password\":\"VOTRE_MOT_DE_PASSE\"}" \
  -c cookies.txt

# Session courante
curl http://localhost:5000/api/auth/me -b cookies.txt

# Satellites opérationnels
curl http://localhost:5000/api/satellites -b cookies.txt

# Déconnexion
curl -X POST http://localhost:5000/api/auth/logout -b cookies.txt
```

Réponse login attendue :

```json
{
  "username": "analyste_data",
  "role": "analyste",
  "can_access_backoffice": false,
  "access": {
    "front_office": true,
    "back_office": false
  }
}
```

## Structure du projet

```
app/
├── __init__.py       # Factory create_app(), /api/health
├── config.py         # Configuration depuis .env
├── db.py             # Connexion MySQL par utilisateur (session)
├── auth/
│   ├── routes.py     # login, logout, me
│   └── services.py   # authenticate(), detect_role()
├── api/
│   └── front.py      # GET /api/satellites
├── middleware/
│   └── auth.py       # @login_required, @role_required
└── static/
    └── index.html    # Page de test auth (navigateur)
run.py                # Point d'entrée
requirements.txt
.env.example
```

## Notes

- Si vos utilisateurs MySQL Phase 4 sont définis avec `'user'@'%'` plutôt que `'user'@'localhost'`, la détection de rôle gère les deux formats.
- Pour un frontend sur un autre port (ex. `http://localhost:5173`), configurez les `origins` CORS dans `app/__init__.py` quand le client sera connu.
