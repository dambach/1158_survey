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

## Utilisation (Application menubar)

L'icone **LS** apparait dans la barre de menu (en haut a droite).

| Menu | Action |
|------|--------|
| Demarrer | Lance le serveur + ouvre l'admin |
| Ouvrir navigateur | Acces a LimeSurvey |
| Exporter CSV | Exporte les reponses |
| Sauvegarder | Backup complet |
| Diagnostics | Verifie le systeme |
| Arreter | **Sauvegarde auto** + arrete le serveur |

> **Note:** "Arreter" effectue automatiquement une sauvegarde et un export CSV.

## Alternative: Scripts Terminal

```bash
./scripts/start-limesurvey.sh
```

**Acces:**
- Local: http://localhost:8081
- Admin: http://localhost:8081/index.php/admin
- Login: `admin` / `admin123`

## Acces tablettes

1. Desactiver le pare-feu macOS:
   ```bash
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
   ```

2. Trouver l'IP du Mac:
   ```bash
   ipconfig getifaddr en0
   ```

3. URL (telephones, tablettes): `http://[IP]:8081/index.php/[ID]?lang=fr`
(Adresse disponible dans l'admin LimeSurvey)

## Scripts (Terminal)

| Script | Description |
|--------|-------------|
| `start-limesurvey.sh` | Demarre LimeSurvey |
| `start-limesurvey.sh --fresh` | Reinitialise tout |
| `stop-limesurvey.sh` | Arrete les services |
| `backup-data.sh` | Sauvegarde -> ./backups/ |
| `export-csv.sh` | Export CSV -> ./exports/ |
| `restore-data.sh <fichier>` | Restaure une sauvegarde |
| `test-system.sh` | Diagnostic complet |
| `test-questionnaire.sh <ID>` | Teste un questionnaire |
| `install-desktop.sh` | Installe raccourcis Bureau |

## Workflow

```bash
# Avant session
./scripts/start-limesurvey.sh

# Apres session
./scripts/export-csv.sh
./scripts/backup-data.sh
./scripts/stop-limesurvey.sh
```

## Creer un questionnaire

1. Aller dans l'admin: http://localhost:8081/index.php/admin
2. Creer un questionnaire
3. Configurer les questions
4. Activer le questionnaire (mode "Anyone with link")
5. Noter l'URL: `http://localhost:8081/index.php/[ID]?lang=fr`

## Depannage

| Probleme | Solution |
|----------|----------|
| Tablettes n'accedent pas | Desactiver pare-feu macOS |
| Serveur inaccessible | `docker restart limesurvey` |
| Reset complet | `./scripts/start-limesurvey.sh --fresh` |

## Persistance

Les donnees sont stockees dans des volumes Docker:
- `limesurvey-mysql-data` (base de donnees)
- `limesurvey-upload-data` (fichiers)

Elles survivent aux redemarrages.

## Structure

```
app/
  limesurvey_app.py     # Application menubar
  build-app.sh          # Script de compilation
scripts/
  start-limesurvey.sh   # Demarrage
  stop-limesurvey.sh    # Arret
  backup-data.sh        # Sauvegarde
  restore-data.sh       # Restauration
  export-csv.sh         # Export reponses
  test-system.sh        # Diagnostic
Limesurvey_logo.svg     # Logo
README.md
```

## Ressources

- [LimeSurvey Docker](https://hub.docker.com/r/martialblog/limesurvey)
- [Documentation LimeSurvey](https://manual.limesurvey.org/)

---
v1.1
