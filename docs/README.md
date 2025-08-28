README — Game Jam (fork)

Résumé rapide des changements récents

- Refactor : consolidation des effets dans `my-librairie/card-librairie/effects/cardEffect_shim.lua`.
- Compat : `my-librairie/card-librairie/core/common.lua` mis à jour pour charger le nouveau module d'effets, avec fallback vers l'ancien chemin si nécessaire.
- HUD : correction de l'initialisation du module HUD (`my-librairie/hud/hudManager.lua`) pour éviter une erreur "attempt to index global 'hud' (a nil value)".
- Divers : petites défenses ajoutées et logs de debug (option `HUD_DEBUG_ENERGY`) pour tracer les changements d'énergie.

Où regarder

- Code principal : `main.lua`, `scene/gameplay.lua`.
- Librairie de cartes : `my-librairie/card-librairie/` (core, play, effects, cardEffect).
- Gestion des acteurs : `my-librairie/actorManager.lua`.
- HUD : `my-librairie/hud/hudManager.lua`.

Comment tester localement

1. Lancer le jeu avec LÖVE (depuis le dossier racine du projet) :

```powershell
# si love est dans le PATH
love .
```

2. Activer le debug HUD (optionnel) :
   - Éditez `my-librairie/hud/hudManager.lua` et mettez `hud.HUD_DEBUG_ENERGY = true` ou exécutez `hud.HUD_DEBUG_ENERGY = true` depuis la console si disponible.

3. Jouer une carte et observer la console pour voir les logs d'énergie et vérifier que l'UI se met à jour.

Notes et recommandations

- J'ai évité de créer des fichiers nouveaux à la racine (convention du projet). Le README est placé dans `docs/README.md`. Si vous préférez le README à la racine, dites‑le et je le déplace.
- Si vous voulez que je corrige aussi les warnings du linter (table.pack/unpack, signatures LÖVE), je peux faire un patch dédié.

Contact

- Pour tout autre correctif ou nettoyage (supprimer anciens fichiers, standardiser tous les require sur le nouveau chemin), indiquez la démarche souhaitée et je m'en occupe.
