#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
LimeSurvey Lab - Application cross-platform (macOS / Windows)
Menubar sur macOS (rumps), System Tray sur Windows (pystray)
"""

import subprocess
import os
import sys
import webbrowser
import platform
import threading

# Detection de l'OS
IS_MACOS = platform.system() == "Darwin"
IS_WINDOWS = platform.system() == "Windows"

# Notifications cross-platform avec plyer
try:
    from plyer import notification as plyer_notification
    HAS_PLYER = True
except ImportError:
    HAS_PLYER = False

# Import conditionnel selon l'OS
if IS_MACOS:
    import rumps
elif IS_WINDOWS:
    import pystray
    from PIL import Image
    import tkinter as tk
    from tkinter import messagebox


def notify(title, message):
    """Notification cross-platform"""
    if HAS_PLYER:
        try:
            plyer_notification.notify(
                title=title,
                message=message,
                app_name="LimeSurvey Lab",
                timeout=5
            )
        except Exception:
            print(f"[{title}] {message}")
    else:
        print(f"[{title}] {message}")


def show_alert(title, message):
    """Boite de dialogue cross-platform"""
    if IS_MACOS:
        rumps.alert(title=title, message=message, ok="Fermer")
    elif IS_WINDOWS:
        # Utiliser tkinter pour les alertes Windows
        root = tk.Tk()
        root.withdraw()  # Cacher la fenetre principale
        messagebox.showinfo(title, message)
        root.destroy()
    else:
        print(f"[{title}]\n{message}")


def open_folder(path):
    """Ouvrir un dossier dans l'explorateur de fichiers"""
    if IS_MACOS:
        subprocess.run(["open", path])
    elif IS_WINDOWS:
        os.startfile(path)
    else:
        subprocess.run(["xdg-open", path])


class LimeSurveyAppBase:
    """Classe de base avec la logique metier commune"""
    
    def __init__(self):
        # Detecter si on est dans une app compilee ou en dev
        if getattr(sys, 'frozen', False):
            if IS_MACOS:
                # App compilee macOS: l'executable est dans LimeSurvey.app/Contents/MacOS/
                bundle_dir = os.path.dirname(sys.executable)
                contents_dir = os.path.dirname(bundle_dir)
                app_bundle = os.path.dirname(contents_dir)
                self.project_dir = os.path.dirname(app_bundle)
            else:
                # App compilee Windows: l'exe est a la racine ou dans un sous-dossier
                self.project_dir = os.path.dirname(sys.executable)
        else:
            # Developpement: script dans app/
            app_dir = os.path.dirname(os.path.abspath(__file__))
            self.project_dir = os.path.dirname(app_dir)
        
        self.scripts_dir = os.path.join(self.project_dir, "scripts")
    
    def get_script_name(self, base_name):
        """Retourne le nom du script selon l'OS (.sh ou .bat)"""
        if IS_WINDOWS:
            return base_name.replace(".sh", ".bat")
        return base_name
    
    def run_script(self, script_name):
        """Execute un script shell (.sh) ou batch (.bat) selon l'OS"""
        script_name = self.get_script_name(script_name)
        script_path = os.path.join(self.scripts_dir, script_name)
        
        try:
            if IS_WINDOWS:
                # Sur Windows, utiliser cmd.exe pour les fichiers .bat
                result = subprocess.run(
                    ["cmd", "/c", script_path],
                    cwd=self.project_dir,
                    capture_output=True,
                    text=True,
                    shell=False
                )
            else:
                result = subprocess.run(
                    [script_path],
                    cwd=self.project_dir,
                    capture_output=True,
                    text=True
                )
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)
    
    def do_start(self):
        """Demarrer LimeSurvey"""
        notify("LimeSurvey", "Demarrage en cours...")
        success, output = self.run_script("start-limesurvey.sh")
        if success:
            notify("LimeSurvey", "Serveur demarre!")
            webbrowser.open("http://localhost:8081/admin")
        else:
            notify("LimeSurvey", "Echec du demarrage")
    
    def do_stop(self):
        """Arreter LimeSurvey (avec sauvegarde auto)"""
        notify("LimeSurvey", "Sauvegarde + Export avant arret...")
        export_ok, _ = self.run_script("export-csv.sh")
        backup_ok, _ = self.run_script("backup-data.sh")
        stop_ok, _ = self.run_script("stop-limesurvey.sh")

        if export_ok and backup_ok and stop_ok:
            notify("LimeSurvey", "Serveur arrete (donnees sauvegardees)")
        else:
            errors = []
            if not export_ok:
                errors.append("Export CSV echoue")
            if not backup_ok:
                errors.append("Sauvegarde echouee")
            if not stop_ok:
                errors.append("Arret serveur echoue")
            notify("LimeSurvey", "Arret termine avec erreurs")
            show_alert("Arret LimeSurvey - erreurs", "\n".join(errors))
    
    def do_open_browser(self):
        """Ouvrir le navigateur"""
        webbrowser.open("http://localhost:8081")
    
    def do_export_csv(self):
        """Exporter les reponses en CSV"""
        notify("LimeSurvey", "Export en cours...")
        success, output = self.run_script("export-csv.sh")
        if success:
            notify("LimeSurvey", "Export termine!")
            exports_dir = os.path.join(self.project_dir, "exports")
            open_folder(exports_dir)
        else:
            notify("LimeSurvey", "Echec de l'export")
    
    def do_backup(self):
        """Sauvegarder les donnees"""
        notify("LimeSurvey", "Sauvegarde en cours...")
        success, output = self.run_script("backup-data.sh")
        if success:
            notify("LimeSurvey", "Sauvegarde terminee!")
        else:
            notify("LimeSurvey", "Echec de la sauvegarde")
    
    def do_diagnostics(self):
        """Afficher les diagnostics"""
        success, output = self.run_script("test-system.sh")
        # Tronquer si trop long
        display_output = output[:1500] if len(output) > 1500 else output
        show_alert("Diagnostics LimeSurvey", display_output)


# ============================================================
# Implementation macOS avec rumps
# ============================================================

if IS_MACOS:
    class LimeSurveyApp(rumps.App, LimeSurveyAppBase):
        def __init__(self):
            rumps.App.__init__(
                self,
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
            LimeSurveyAppBase.__init__(self)
        
        @rumps.clicked("Demarrer")
        def start(self, _):
            self.do_start()
        
        @rumps.clicked("Arreter")
        def stop(self, _):
            self.do_stop()
        
        @rumps.clicked("Ouvrir navigateur")
        def open_browser(self, _):
            self.do_open_browser()
        
        @rumps.clicked("Exporter CSV")
        def export_csv(self, _):
            self.do_export_csv()
        
        @rumps.clicked("Sauvegarder")
        def backup(self, _):
            self.do_backup()
        
        @rumps.clicked("Diagnostics")
        def diagnostics(self, _):
            self.do_diagnostics()


# ============================================================
# Implementation Windows avec pystray
# ============================================================

elif IS_WINDOWS:
    class LimeSurveyApp(LimeSurveyAppBase):
        def __init__(self):
            LimeSurveyAppBase.__init__(self)
            self.icon = None
        
        def create_icon(self):
            """Creer l'icone pour le system tray"""
            icon_path = os.path.join(os.path.dirname(__file__), "icon.ico")
            if os.path.exists(icon_path):
                return Image.open(icon_path)
            else:
                # Icone par defaut si icon.ico n'existe pas
                img = Image.new('RGB', (64, 64), color='green')
                return img
        
        def create_menu(self):
            """Creer le menu du system tray"""
            return pystray.Menu(
                pystray.MenuItem("Demarrer", self.on_start),
                pystray.MenuItem("Ouvrir navigateur", self.on_open_browser),
                pystray.Menu.SEPARATOR,
                pystray.MenuItem("Exporter CSV", self.on_export_csv),
                pystray.MenuItem("Sauvegarder", self.on_backup),
                pystray.Menu.SEPARATOR,
                pystray.MenuItem("Diagnostics", self.on_diagnostics),
                pystray.Menu.SEPARATOR,
                pystray.MenuItem("Arreter serveur", self.on_stop),
                pystray.MenuItem("Quitter", self.on_quit),
            )
        
        def on_start(self, icon, item):
            threading.Thread(target=self.do_start, daemon=True).start()
        
        def on_stop(self, icon, item):
            threading.Thread(target=self.do_stop, daemon=True).start()
        
        def on_open_browser(self, icon, item):
            self.do_open_browser()
        
        def on_export_csv(self, icon, item):
            threading.Thread(target=self.do_export_csv, daemon=True).start()
        
        def on_backup(self, icon, item):
            threading.Thread(target=self.do_backup, daemon=True).start()
        
        def on_diagnostics(self, icon, item):
            threading.Thread(target=self.do_diagnostics, daemon=True).start()
        
        def on_quit(self, icon, item):
            icon.stop()
        
        def run(self):
            """Lancer l'application system tray"""
            self.icon = pystray.Icon(
                name="LimeSurvey",
                icon=self.create_icon(),
                title="LimeSurvey Lab",
                menu=self.create_menu()
            )
            self.icon.run()


# ============================================================
# Point d'entree
# ============================================================

if __name__ == "__main__":
    app = LimeSurveyApp()
    app.run()
