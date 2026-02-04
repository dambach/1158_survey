# LimeSurvey Lab

Questionnaires sur tablettes en laboratoire avec hebergement local.

**Compatible macOS et Windows**

## TODO
- [ ] screenshots

---

## Installation macOS

### 1. Prerequis
- macOS 10.14+
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Python 3 (inclus sur macOS)

### 2. Cloner et compiler
```bash
git clone https://github.com/dambach/1158_survey.git
cd 1158_survey/app
pip3 install -r requirements.txt
chmod +x build-app.sh
./build-app.sh
```

### 3. Lancer
Double-cliquez sur `LimeSurvey.app` (a la racine du projet).

---

## Installation Windows

### 1. Prerequis
- Windows 10/11
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (activer WSL2 lors de l'installation)
- [Python 3.10+](https://www.python.org/downloads/) (**Cocher "Add Python to PATH"** lors de l'installation)

### 2. Cloner et compiler
```cmd
git clone https://github.com/dambach/1158_survey.git
cd 1158_survey\app
pip install -r requirements.txt
build-app.bat
```

### 3. Lancer
Double-cliquez sur `LimeSurvey.exe` (a la racine du projet).

---

## Variables d'environnement (optionnel)

Par defaut, l'application utilise des identifiants internes simples. Vous pouvez les surcharger via des variables d'environnement **avant** de lancer l'app ou les scripts.

Variables supportees:
- `LISTEN_PORT` (defaut: `8080`) - port interne du conteneur LimeSurvey
- `MYSQL_ROOT_PASSWORD` (defaut: `rootpass`)
- `MYSQL_DATABASE` (defaut: `limesurvey`)
- `MYSQL_USER` (defaut: `limesurvey`)
- `MYSQL_PASSWORD` (defaut: `limepass`)
- `ADMIN_USER` (defaut: `admin`)
- `ADMIN_PASSWORD` (defaut: `admin123`)
- `ADMIN_NAME` (defaut: `Admin`)
- `ADMIN_EMAIL` (defaut: `admin@lab.local`)

Exemples:

macOS:
```bash
export ADMIN_PASSWORD="mon-mot-de-passe"
export MYSQL_PASSWORD="mon-mysql-pass"
./scripts/start-limesurvey.sh
```

Windows (cmd):
```cmd
set ADMIN_PASSWORD=mon-mot-de-passe
set MYSQL_PASSWORD=mon-mysql-pass
scripts\start-limesurvey.bat
```

> **Note:** L'acces externe reste sur `http://localhost:8081` (ou l'IP du PC/Mac), meme si `LISTEN_PORT` change.

---

## Workflow complet

### Etape 1: Lancer l'application

1. **Ouvrir Docker Desktop** (icone baleine)
2. **Double-cliquer sur l'application:**
   - **macOS:** `LimeSurvey.app`
   - **Windows:** `LimeSurvey.exe`
3. L'icone **LS** apparait:
   - **macOS:** dans la barre de menu (en haut a droite)
   - **Windows:** dans la zone de notification (en bas a droite)

### Etape 2: Demarrer le serveur

1. Cliquer sur l'icone **LS** (barre de menu macOS / zone de notification Windows)
2. Cliquer sur **Demarrer**
3. Attendre la notification "Serveur demarre!"
4. Le navigateur s'ouvre automatiquement sur l'admin

### Etape 3: Creer un questionnaire

1. **Se connecter** a l'admin:
   - Utilisateur: `admin`
   - Mot de passe: `admin123`

2. **Creer un questionnaire:**
   - Cliquer sur "+ Creer un questionnaire"
   - Remplir le titre et la description
   - Cliquer sur "Enregistrer"

3. **Ajouter des questions:**
   - Cliquer sur "Ajouter un groupe de questions"
   - Cliquer sur "Ajouter une question"
   - Choisir le type (choix multiple, texte, echelle, etc.)

4. **Activer le questionnaire:**
   - Cliquer sur "Activer ce questionnaire"
   - Choisir "Reponses anonymes" si souhaite
   - Confirmer l'activation

### Etape 4: Recuperer l'URL pour les tablettes

1. Dans l'admin, aller dans **Parametres** > **Vue d'ensemble**
2. Copier l'**URL du questionnaire** (ex: `http://localhost:8081/index.php/123456?lang=fr`)
3. **Remplacer `localhost` par l'IP de l'ordinateur** pour les tablettes:
   - Trouver l'IP: **LS** > **Diagnostics**
   - Ou manuellement:
     - **macOS:** `ipconfig getifaddr en0`
     - **Windows:** `ipconfig` (chercher "Adresse IPv4")
   - URL tablettes: `http://192.168.1.XX:8081/index.php/123456?lang=fr`

4. **Desactiver le pare-feu** (une seule fois):
   - **macOS:**
     ```bash
     sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
     ```
   - **Windows** (en tant qu'administrateur):
     ```cmd
     netsh advfirewall set allprofiles state off
     ```
     Ou via: Panneau de configuration > Pare-feu Windows Defender > Desactiver

### Etape 5: Pendant la session

- Les participants remplissent le questionnaire sur tablettes
- **Les reponses sont sauvegardees automatiquement** dans LimeSurvey
- Verifier les reponses: Admin > Reponses > Reponses et statistiques

### Etape 6: Apres la session

| Action | Comment |
|--------|---------|
| **Exporter les reponses** | **LS** > **Exporter CSV** |
| **Sauvegarder tout** | **LS** > **Sauvegarder** |
| **Arreter** | **LS** > **Arreter** (sauvegarde auto incluse) |

Les fichiers sont dans:
- `./exports/` - Fichiers CSV des reponses
- `./backups/` - Sauvegardes completes

---

## Menus de l'application

| Menu | Action |
|------|--------|
| Demarrer | Lance le serveur + ouvre l'admin |
| Ouvrir navigateur | Acces a LimeSurvey |
| Exporter CSV | Exporte les reponses -> ./exports/ |
| Sauvegarder | Backup complet -> ./backups/ |
| Diagnostics | Verifie le systeme + affiche l'IP |
| Arreter | **Sauvegarde auto** + arrete le serveur |

> **Note:** "Arreter" effectue automatiquement une sauvegarde et un export CSV.

---

## Acces

| Type | URL |
|------|-----|
| Admin (local) | http://localhost:8081/admin |
| Questionnaire (local) | http://localhost:8081/index.php/[ID]?lang=fr |
| Questionnaire (tablettes) | http://[IP_ORDINATEUR]:8081/index.php/[ID]?lang=fr |
| Login admin | `admin` / `admin123` |

---

## Alternative: Scripts Terminal

### macOS
```bash
./scripts/start-limesurvey.sh
./scripts/export-csv.sh
./scripts/backup-data.sh
./scripts/stop-limesurvey.sh
```

### Windows
```cmd
scripts\start-limesurvey.bat
scripts\export-csv.bat
scripts\backup-data.bat
scripts\stop-limesurvey.bat
```

| Script | Description |
|--------|-------------|
| `start-limesurvey` | Demarre LimeSurvey |
| `start-limesurvey --fresh` | Reinitialise tout (⚠️ efface les donnees) |
| `stop-limesurvey` | Arrete les services |
| `backup-data` | Sauvegarde -> ./backups/ |
| `export-csv` | Export CSV -> ./exports/ |
| `restore-data <fichier>` | Restaure une sauvegarde |
| `test-system` | Diagnostic complet |

---

## Depannage

| Probleme | Solution |
|----------|----------|
| Tablettes n'accedent pas | Desactiver pare-feu (macOS ou Windows) |
| Serveur inaccessible | `docker restart limesurvey` |
| Docker ne demarre pas | Ouvrir Docker Desktop manuellement |
| Reset complet | `start-limesurvey --fresh` (⚠️ efface tout) |

## Persistance des donnees

Les donnees sont stockees dans des volumes Docker et **survivent aux redemarrages**:
- `limesurvey-mysql-data` - Base de donnees (reponses, questionnaires)
- `limesurvey-upload-data` - Fichiers uploades

**Recommandation:** Faire un backup regulier via **LS** > **Sauvegarder**.

## Structure du projet

```
LimeSurvey.app          # Application macOS (generee par build-app.sh)
LimeSurvey.exe          # Application Windows (generee par build-app.bat)
app/
  limesurvey_app.py     # Code source cross-platform (macOS/Windows)
  build-app.sh          # Script de compilation macOS
  build-app.bat         # Script de compilation Windows
  icon.icns             # Icone macOS
  icon.ico              # Icone Windows
  requirements.txt      # Dependances Python
scripts/                # Scripts shell (.sh) et batch (.bat)
backups/                # Sauvegardes (gitignore)
exports/                # Exports CSV (gitignore)
```

## Ressources

- [Documentation LimeSurvey](https://manual.limesurvey.org/)
- [LimeSurvey Docker](https://hub.docker.com/r/martialblog/limesurvey)

---
v1.3 - Cross-platform macOS/Windows
