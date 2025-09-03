Documentation des scripts du projet

Ce dossier contient la documentation des scripts Lua utilisés dans le projet. Il aide les développeurs à comprendre les responsabilités des modules, les API publiques et les contrats d'exécution.

Structure
- README.md (ce fichier)
- templates/
  - script_template.md  (modèle pour documenter un module Lua)
- modules/ (documentation par module)

Directives
- Rédigez des documents courts et précis en français.
- Pour chaque module, incluez : but, fonctions publiques, formes des données (inputs/outputs), effets secondaires et modes d'erreur courants.
- Gardez les exemples minimaux et exécutables si possible.
- Utilisez le modèle fourni pour documenter les nouveaux modules.

Contribuer
- Créez un fichier sous `modules/` en utilisant le chemin du module dans le nom, par exemple `my-librairie_sceneManager.md`.
- Suivez le modèle et reliez les modules connexes lorsque pertinent.
- Un module par fichier.

Commandes utiles (PowerShell)

# Ouvrir dans l'Explorateur
explorer .\my-librairie\documentation

# Ouvrir dans VS Code
code .\my-librairie\documentation
