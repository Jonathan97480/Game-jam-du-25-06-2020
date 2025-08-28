# Game Jam — Tactique Cards

Ce dépôt contient un prototype de jeu de cartes tactique développé avec LÖVE (Love2D) et Lua.

Résumé
- Projet initial: Game-jam du 25-06-2020 (fork/maintenance).
- Langage: Lua, moteur: LÖVE (Love2D).

Fichiers importants
- `main.lua` — point d'entrée (initialisation, boucle jeu).
- `scene/` — scènes (menu, gameplay, overlays).
- `my-librairie/` — librairies (hud, sceneManager, card-librairie, etc.).
- `ressources/` — données (cartes, effets).
- `img/`, `fonts/` — ressources médias.
- `gameLogs/` — dossier runtime (logs exportés) (ignoré par Git).

Lancer le jeu
1. Installer LÖVE (https://love2d.org).
2. Depuis la racine du dépôt :

```powershell
# si love est dans le PATH
love .
```

Logger & diagnostics
- Le projet fournit `globalFunction.log` (panneau affichable via F12 si activé).
- À la fermeture, le logger tente d'exporter les logs dans `gameLogs/`.

Développement
- Contribuez via fork → branche → PR.
- Respectez la structure du dépôt (ne pas créer de scripts sources à la racine).

Notes
- Un README détaillé existe déjà dans `docs/README.md` (mises à jour récentes). Si vous souhaitez une version plus complète ici, je peux la fusionner.

---

Si vous voulez que je commit ce fichier README.md maintenant, je peux le faire.
