# NanoOrbit-back

API REST Flask pour le projet **NanoOrbit** (CubeSat Earth Observation System).

- **Auth** : connexion MySQL réelle (Option A) — les identifiants saisis au login sont réutilisés pour chaque requête SQL
- **Front associé** : [NanoOrbit-front](https://github.com/TheoLugagne/NanoOrbit-front) (React + Vite)
- **Documentation API** : `openapi.json`

## Prérequis

- Python **3.10+**
- MySQL **8+** ou MariaDB **10.6+**
- Base peuplée (scripts dans `database/`) :
  - Phase 2 : schéma + données (`Groupe14_Lugagne_Police_Boudeville_CubeSat_Phase2 (3).sql`)
  - Phase 3 : vues métier (`Groupe14_Lugagne_Police_Boudeville_CubeSat_Phase3 (1).sql`)
  - Phase 4 : droits utilisateurs (`phase 4 version server.sql` sur le serveur)
  - Optionnel : contrainte RG-I03 (`rg_i03_contrainte_instrument.sql`)

---

## Installation locale

```bash
git clone <url-du-repo>
cd NanoOrbit-back
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

Éditez `.env` (voir tableau ci-dessous). Générez une clé secrète unique pour `FLASK_SECRET_KEY`.

### Base de données locale

1. Importer le script Phase 2 dans MySQL (crée `nanoOrbit_db`).
2. Exécuter le script Phase 3 (vues).
3. Exécuter le script Phase 4 adapté à votre environnement local (utilisateurs `operateur_sat`, `analyste_data`, `resp_mission`, `admin_nano`).

### Lancer l'API en local

```bash
python run.py
```

L'application écoute sur **http://localhost:5000**.

Alternative :

```bash
flask --app run run
```

Une page de test statique est aussi disponible sur `http://localhost:5000/`.

---

## Déploiement serveur (AlwaysData)

### 1. Récupérer le code

```bash
ssh <user>@ssh-<user>.alwaysdata.net
cd ~/NanoOrbit-back
git pull
```

### 2. Environnement Python

- Créer un **environnement virtuel** AlwaysData pointant vers ce dépôt (ou réutiliser l'existant).
- Installer les dépendances : `pip install -r requirements.txt`

### 3. Fichier `.env` sur le serveur

Copier `.env.example` vers `.env` et adapter :

| Variable | Exemple serveur |
|----------|-----------------|
| `FLASK_SECRET_KEY` | Clé longue et aléatoire |
| `FLASK_ENV` | `production` |
| `MYSQL_HOST` | `mysql-<user>.alwaysdata.net` |
| `MYSQL_PORT` | `3306` |
| `MYSQL_DATABASE` | `tlugagne_tp` |
| `FRONTEND_ORIGIN` | `https://nano-orbite-prod.tlugagne.live` |
| `CORS_ORIGINS` | Origines du front + API, séparées par des virgules |
| `SESSION_COOKIE_SAMESITE` | `None` |
| `SESSION_COOKIE_SECURE` | `true` |

> Les mots de passe des comptes métier **ne sont pas** dans `.env` : ils sont saisis au login.

### 4. Base MySQL (serveur)

- Base : `tlugagne_tp`
- Droits Phase 4 : `database/phase 4 version server.sql`
- Comptes AlwaysData mappés dans `app/auth/services.py` :

| Login applicatif | Compte MySQL serveur |
|------------------|----------------------|
| `analyste_data` | `tlugagne_analyst` |
| `operateur_sat` | `tlugagne_operateur` |
| `resp_mission` | `tlugagne_responsable` |
| `admin_nano` | `tlugagne` |

### 5. Service uWSGI

Le point d'entrée WSGI est `wsgi.py` (variable `application`).

Dans le panneau AlwaysData :

1. **Sites** → site API (ex. `nano-orbite.tlugagne.live`)
2. Type : **Python** / uWSGI
3. Répertoire : `~/NanoOrbit-back`
4. Fichier WSGI : `wsgi.py`
5. Environnement virtuel : celui du projet

Après chaque `git pull`, **redémarrer le site** ou le service Python pour prendre en compte les changements.

---

## Variables d'environnement

| Variable | Obligatoire | Description | Défaut |
|----------|-------------|-------------|--------|
| `FLASK_SECRET_KEY` | Oui (prod) | Clé de signature des cookies de session | `change-me-in-production` |
| `FLASK_ENV` | Non | `development` ou `production` | `development` |
| `MYSQL_HOST` | Oui | Hôte MySQL | `localhost` |
| `MYSQL_PORT` | Non | Port MySQL | `3306` |
| `MYSQL_DATABASE` | Oui | Nom de la base | `nanoOrbit_db` |
| `MYSQL_USER` | Non | Compte technique (rarement utilisé par l'app) | `root` |
| `MYSQL_PASSWORD` | Non | Mot de passe du compte technique | *(vide)* |
| `FRONTEND_ORIGIN` | Recommandé (prod) | URL exacte du front déployé | — |
| `CORS_ORIGINS` | Recommandé (prod) | Liste d'origines autorisées, séparées par `,` | localhost + domaines du projet |
| `SESSION_COOKIE_SAMESITE` | Prod cross-origin | `None`, `Lax` ou `Strict` | `None` |
| `SESSION_COOKIE_SECURE` | Prod HTTPS | `true` ou `false` | `true` |

### Exemple `.env` — développement local (front Vite sur :5173)

```env
FLASK_SECRET_KEY=dev-secret-change-me
FLASK_ENV=development
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=nanoOrbit_db
CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
SESSION_COOKIE_SAMESITE=Lax
SESSION_COOKIE_SECURE=false
```

### Exemple `.env` — production (AlwaysData)

```env
FLASK_SECRET_KEY=<clé-aléatoire-longue>
FLASK_ENV=production
MYSQL_HOST=mysql-tlugagne.alwaysdata.net
MYSQL_PORT=3306
MYSQL_DATABASE=tlugagne_tp
FRONTEND_ORIGIN=https://nano-orbite-prod.tlugagne.live
CORS_ORIGINS=https://nano-orbite-prod.tlugagne.live,https://nano-orbite.tlugagne.live
SESSION_COOKIE_SAMESITE=None
SESSION_COOKIE_SECURE=true
```

---

## Profils et accès

| Login | Rôle app | Front-office | Back-office |
|-------|----------|--------------|-------------|
| `analyste_data` | `analyste` | Oui | Non |
| `operateur_sat` | `operateur` | Oui | Partiel (BO-01, BO-02, BO-05) |
| `resp_mission` | `responsable` | Oui | Partiel (BO-03) |
| `admin_nano` | `admin` | Oui | Complet |

La désorbitation d'un satellite est réservée à l'**admin**.

---

## Tests rapides (curl)

```bash
# Connexion
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

---

## Structure du projet

```
app/
├── __init__.py          # Factory Flask, CORS, blueprints
├── config.py            # Configuration depuis .env
├── db.py                # Connexion MySQL par utilisateur de session
├── auth/
│   ├── routes.py        # POST /login, /logout — GET /me
│   └── services.py      # Authentification, mapping rôles
├── api/
│   ├── front.py         # Routes front-office (lecture)
│   ├── back.py          # Routes back-office + actions d'écriture
│   └── helpers.py       # Helpers DB, gestion d'erreurs SQL
├── middleware/
│   └── auth.py          # @login_required, @role_required
└── static/
    └── index.html       # Page de test (navigateur)
database/                # Scripts SQL (phases 2–4, contraintes)
run.py                   # Démarrage local
wsgi.py                  # Point d'entrée production (uWSGI)
requirements.txt
.env.example
openapi.json
```

## Notes

- Les identifiants MySQL sont stockés en **session serveur** (choix pédagogique du sujet) et utilisés pour chaque requête.
- En cross-origin (front et API sur des domaines différents), `SESSION_COOKIE_SAMESITE=None` et `SESSION_COOKIE_SECURE=true` sont requis.
- Si les utilisateurs MySQL sont définis avec `@'%'` (serveur), la détection de rôle dans `services.py` gère ce format.
