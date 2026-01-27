#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
LimeSurvey Lab - Application menubar macOS
"""

import rumps
import subprocess
import os
import webbrowser

class LimeSurveyApp(rumps.App):
    def __init__(self):
        super().__init__(
            name="LimeSurvey",
            title="LS",
            menu=[
                "Demarrer",
                "Ouvrir navigateur",
                None,
                "Exporter CSV",
                "Sauvegarder",
                None,
                "Diagnostics",
                None,
                "Arreter",
            ]
        )
        # Detecter si on est dans une app compilee ou en dev
        import sys
        if getattr(sys, 'frozen', False):
            # App compilee: l'executable est dans LimeSurvey.app/Contents/MacOS/
            # L'app doit etre dans le meme dossier que le projet
            bundle_dir = os.path.dirname(sys.executable)  # Contents/MacOS
            contents_dir = os.path.dirname(bundle_dir)     # Contents
            app_bundle = os.path.dirname(contents_dir)     # LimeSurvey.app
            self.project_dir = os.path.dirname(app_bundle) # dossier du projet
        else:
            # Developpement: script dans app/
            self.app_dir = os.path.dirname(os.path.abspath(__file__))
            self.project_dir = os.path.dirname(self.app_dir)
        self.scripts_dir = os.path.join(self.project_dir, "scripts")
    
    def run_script(self, script_name):
        script_path = os.path.join(self.scripts_dir, script_name)
        try:
            result = subprocess.run(
                [script_path],
                cwd=self.project_dir,
                capture_output=True,
                text=True
            )
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)
    
    @rumps.clicked("Demarrer")
    def start(self, _):
        rumps.notification("LimeSurvey", "", "Demarrage en cours...")
        success, output = self.run_script("start-limesurvey.sh")
        if success:
            rumps.notification("LimeSurvey", "", "Serveur demarre!")
            webbrowser.open("http://localhost:8081/admin")
        else:
            rumps.notification("LimeSurvey", "Erreur", "Echec du demarrage")
    
    @rumps.clicked("Arreter")
    def stop(self, _):
        # Sauvegarde automatique avant arret
        rumps.notification("LimeSurvey", "", "Sauvegarde + Export avant arret...")
        self.run_script("export-csv.sh")
        self.run_script("backup-data.sh")
        # Arret
        success, output = self.run_script("stop-limesurvey.sh")
        rumps.notification("LimeSurvey", "", "Serveur arrete (donnees sauvegardees)")
    
    @rumps.clicked("Ouvrir navigateur")
    def open_browser(self, _):
        webbrowser.open("http://localhost:8081")
    
    @rumps.clicked("Exporter CSV")
    def export_csv(self, _):
        rumps.notification("LimeSurvey", "", "Export en cours...")
        success, output = self.run_script("export-csv.sh")
        if success:
            rumps.notification("LimeSurvey", "", "Export termine!")
            exports_dir = os.path.join(self.project_dir, "exports")
            subprocess.run(["open", exports_dir])
        else:
            rumps.notification("LimeSurvey", "Erreur", "Echec de l'export")
    
    @rumps.clicked("Sauvegarder")
    def backup(self, _):
        rumps.notification("LimeSurvey", "", "Sauvegarde en cours...")
        success, output = self.run_script("backup-data.sh")
        if success:
            rumps.notification("LimeSurvey", "", "Sauvegarde terminee!")
        else:
            rumps.notification("LimeSurvey", "Erreur", "Echec de la sauvegarde")
    
    @rumps.clicked("Diagnostics")
    def diagnostics(self, _):
        success, output = self.run_script("test-system.sh")
        rumps.alert(
            title="Diagnostics LimeSurvey",
            message=output[:500] if len(output) > 500 else output,
            ok="Fermer"
        )

if __name__ == "__main__":
    LimeSurveyApp().run()
