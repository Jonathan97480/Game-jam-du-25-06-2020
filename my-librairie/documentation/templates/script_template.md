# Modèle de documentation de module

Module : <chemin du module, ex. my-librairie/sceneManager.lua>

Courte description
- Une phrase sur le rôle du module.

API publique
- fonctionNom(args) -> return : brève description
- AutreFonction(args) -> return : brève description

Formes de données / types
- Décrire les tables/objets importants et leurs champs.

Effets secondaires
- Fichiers écrits, variables globales modifiées, état externe touché.

Exemple d'utilisation
```lua
local mod = require('<chemin module>')
mod.someFunction({ param = 1 })
```

Notes / pièges
- Mentionner les requires circulaires, globals inattendus, ordre de chargement.

Modules liés
- Liste des modules utilisés ou à utiliser ensemble

Changelog
- YYYY-MM-DD - note
