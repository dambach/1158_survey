# LimeSurvey Lab

Questionnaires sur tablettes en laboratoire avec hebergement local.

## Installation (nouveau Mac)

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

## Workflow complet

### Etape 1: Lancer l'application

1. **Ouvrir Docker Desktop** (icone baleine dans la barre de menu)
2. **Double-cliquer sur `LimeSurvey.app`** (a la racine du projet)
3. L'icone **LS** apparait dans la barre de menu (en haut a droite)

### Etape 2: Demarrer le serveur

1. Cliquer sur **LS** dans la barre de menu
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
3. **Remplacer `localhost` par l'IP du Mac** pour les tablettes:
   - Trouver l'IP: **LS** > **Diagnostics** (ou `ipconfig getifaddr en0`)
   - URL tablettes: `http://192.168.1.XX:8081/index.php/123456?lang=fr`

4. **Desactiver le pare-feu** (une seule fois):
   ```bash
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
   ```

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
| Admin (Mac) | http://localhost:8081/admin |
| Questionnaire (Mac) | http://localhost:8081/index.php/[ID]?lang=fr |
| Questionnaire (tablettes) | http://[IP_MAC]:8081/index.php/[ID]?lang=fr |
| Login admin | `admin` / `admin123` |

---

## Alternative: Scripts Terminal

```bash
./scripts/start-limesurvey.sh
./scripts/export-csv.sh
./scripts/backup-data.sh
./scripts/stop-limesurvey.sh
```

| Script | Description |
|--------|-------------|
| `start-limesurvey.sh` | Demarre LimeSurvey |
| `start-limesurvey.sh --fresh` | Reinitialise tout (⚠️ efface les donnees) |
| `stop-limesurvey.sh` | Arrete les services |
| `backup-data.sh` | Sauvegarde -> ./backups/ |
| `export-csv.sh` | Export CSV -> ./exports/ |
| `restore-data.sh <fichier>` | Restaure une sauvegarde |
| `test-system.sh` | Diagnostic complet |

---

## Depannage

| Probleme | Solution |
|----------|----------|
| Tablettes n'accedent pas | Desactiver pare-feu macOS (voir Etape 4) |
| Serveur inaccessible | `docker restart limesurvey` |
| Docker ne demarre pas | Ouvrir Docker Desktop manuellement |
| Reset complet | `./scripts/start-limesurvey.sh --fresh` (⚠️ efface tout) |

## Persistance des donnees

Les donnees sont stockees dans des volumes Docker et **survivent aux redemarrages**:
- `limesurvey-mysql-data` - Base de donnees (reponses, questionnaires)
- `limesurvey-upload-data` - Fichiers uploades

**Recommandation:** Faire un backup regulier via **LS** > **Sauvegarder**.

## Structure du projet

```
LimeSurvey.app          # Application (generee par build-app.sh)
app/
  limesurvey_app.py     # Code source de l'app
  build-app.sh          # Script de compilation
  icon.icns             # Icone
scripts/                # Scripts shell
backups/                # Sauvegardes (gitignore)
exports/                # Exports CSV (gitignore)
```

## Ressources

- [Documentation LimeSurvey](https://manual.limesurvey.org/)
- [LimeSurvey Docker](https://hub.docker.com/r/martialblog/limesurvey)

---
v1.2
