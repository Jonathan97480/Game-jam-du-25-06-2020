# TODO - Refactor Flow des Scènes (Intro → VillageHub → Hub → Préparation → Combat)

Date: 03 septembre 2025
Auteur: généré automatiquement

## Objectif
Refondre le chargement des scènes pour remplacer le lancement direct du combat par un flow clair :
Intro → VillageHub → Hub → Préparation → Combat. Ajouter aussi les overlays (gameover, reward, start, initiative) et garantir des transitions propres (HUD, audio, sauvegarde).

---

## Checklist (exigences)
- [ ] Remplacer le lancement direct du combat par un router d'entrée.
- [ ] Implémenter flow premier lancement : `intro` → `villageHub` → `hub`.
- [ ] Permettre navigation `villageHub` → `hub` → `preparation` → `gameplay` (combat).
- [ ] Ajouter overlays : `overlay_gameover`, `overlay_reward`, `overlay_start`, `overlay_initiative`.
- [ ] Conserver stack-based `SceneManager` (push/pop) et lifecycles (`load/enter/update/draw/pause/resume/leave/unload`).
- [ ] Préserver sauvegarde / détection premier lancement (`saveManager` / `settings.json`).
- [ ] Écrire tests d'intégration/smoke pour le nouveau flow.
- [ ] Travailler en branche feature et ne pas modifier la `beta` sans PR.

---

## Tâches priorisées (actionnable)

### Phase 0 — Préparation
1. Créer une branche feature: `feature/scene-flow-refactor`.
2. Audit rapide (lecture seule) des modules clés : `my-librairie/sceneManager.lua`, `main.lua`, `scene/menu/menu.lua`, `my-librairie/core/globals.lua`, `saveManager.lua`.
   - Livrable : notes de compatibilité API push/pop et lifecycle.

### Phase 1 — Router d'entrée (essentiel)
3. Implémenter `GameStartRouter.lua` (nouveau) :
   - décide si push `intro` / `villageHub` / `hub` selon `saveManager`/settings.
   - expose `startNewGame()` et `continueGame()`.
   - Remplacer callback Play dans `scene/menu/HUD/mainMenu.lua` pour appeler le router.

### Phase 2 — Scènes de flow
4. Créer `scene/intro/intro.lua` : timeline, skip, à la fin mark `firstRunCompleted` et push `scene.villageHub`.
5. Créer `scene/villageHub/villageHub.lua` : hub monde, push `scene.hub` ou overlays.
6. Créer `scene/hub/hub.lua` : interface planification/mission, sélection deck & étage
   - Permettre la sélection des cartes qui composeront le deck pour l'exploration.
   - Permettre la sélection d'un étage du château à explorer (liste des étages disponibles).
   - Bouton « Explorer / Préparer » qui ouvre la scène de carte d'étage (floor map) décrite en 7.

7. Créer `scene/gameplay/preparation.lua` : carte d'étage (floor map) et sélection de zone
   - Cette scène affiche la carte de l'étage sélectionné (réutilisable pour tous les étages).
   - L'utilisateur clique sur une zone de la carte :
       - Si zone == combat : push `scene/gameplay/gameplay.lua` (combat) ET transmettre en paramètres : background à utiliser, liste de monstres à charger, dialogues/événements associés.
     - Si zone == repos : ouvrir une **scène réutilisable de repos** (ex: `scene/gameplay/rest.lua`) utilisée par toutes les zones de repos du jeu.
        - `rest.lua` doit être paramétrable : recevoir le `background` de la zone, le type de repos, et les données événementielles.
        - Fonctionnalités attendues dans la scène de repos :
           - Récupération PV/ressources (heal/energy) configurable.
           - Possibilité d'améliorer des cartes via des items trouvés pendant l'exploration (upgrade slot, ajouter effets, augmenter valeurs).
           - Option de fusionner des cartes (combiner 2 cartes pour créer une nouvelle variante) avec règles/ressources définies.
           - Récupération de lore / dialogues liés à l'étage (événements narratifs) — stockage dans le profil joueur.
           - Bouton retour à la carte d'étage (`preparation.lua`) ou retour au hub selon le flow.
        - La scène de repos doit exposer une API simple pour passer des callbacks et récupérer l'état final (items gagnés, cartes modifiées, choix du joueur).
      - Si zone == marchand : ouvrir une **scène marchand réutilisable** (ou overlay) paramétrable :
         - API / paramètres attendus : `background`, `merchantData` (id, sprite, animations, dialogues), `inventory` (cartes, items, reliques), `pricingRules`, `persistState` (bool) et `onComplete` (callback).
         - Comportement attendu :
            - Afficher le background et l'apparence/animations du marchand, lancer les dialogues/événements liés à la zone.
            - Afficher l'inventaire du marchand (catalogue) avec filtres (cartes, reliques, consommables) et prévisualisation/compare pour les cartes.
            - Permettre les actions : acheter (coût en monnaie), vendre (cards/reliques → monnaie), et échanger/convertir reliques contre cartes selon des règles (barter).
            - Gestion de confirmation : preview → confirmer → transaction atomique (mise à jour profil, monnaie et inventory).
            - Supporter l'échange de cartes contre cartes (swap) si défini par `pricingRules` ou par une logique de fusion/upgrade.
         - API de sortie : invoquer `onComplete(result)` à la fermeture, où `result` contient `{ transactions = {...}, itemsGained = {...}, currencyDelta = n, modifiedCards = {...} }`.
         - Retour au flow : après fermeture, revenir à `preparation.lua` (carte) en appliquant les changements au profil via `saveManager` ou via le callback `onComplete`.
         - Notes d'implémentation : la scène doit être réutilisable pour boutiques fixes et commerçants aléatoires ; autoriser la personnalisation des dialogues/animations par zone ; persister l'état du marchand si `persistState=true`.
   - `preparation.lua` reçoit les métadonnées de l'étage (layout, zones, paramètres) depuis le `hub` ou `saveManager` et doit être paramétrable.
    - Après validation d'une zone combat, lancer la transition vers `scene/gameplay/gameplay.lua` en lui passant les paramètres nécessaires (background, monsters, dialogues, musique d'ambiance).
       - À la fin du combat, le jeu doit revenir automatiquement à la carte d'étage (`scene/gameplay/preparation.lua`) pour que le joueur puisse sélectionner la prochaine zone ou se déplacer.
       - Le `gameplay.lua` doit rendre un résultat de combat structuré (ex: `{ rewards = {...}, losses = {...}, stateChanges = {...}, events = {...} }`) et appeler un callback `onComplete(result)` fourni par `preparation.lua` ou persister via `saveManager`.
       - Prévoir les cas : victoire → affichage `overlay_reward` puis retour à la carte ; défaite → `overlay_gameover` ou retour au hub selon règles ; arrêt/interruption → revenir proprement à la carte et restaurer l'état.
       - Implémentation recommandée : `preparation.lua` appelle `sceneManager:push('scene/gameplay/gameplay.lua', params, onComplete)` ou transmet un `onComplete` dans `params`; le gameplay pousse ses overlays internes puis, à la fin, appelle `onComplete(result)` et effectue `sceneManager:pop()` pour retirer la scène de combat, laissant `preparation.lua` afficher la carte et traiter le résultat.

      - Taille / estimation (approx) :
         - `GameStartRouter` : 0.5 - 1 jour (design + tests minimal)
         - `scene/intro/intro.lua` : 0.5 jour (squeleton + skip)
         - `scene/villageHub/villageHub.lua` : 0.5 - 1 jour (UI navigation)
         - `scene/hub/hub.lua` : 1 jour (sélection deck + étages)
         - `scene/gameplay/preparation.lua` (floor map) : 1 jour (sélection zones + callbacks)
         - `scene/gameplay/gameplay.lua` (combat stub -> voir renommage) : 1 - 2 jours (système de phases de combat minimal)
         - `rest.lua` (scène de repos réutilisable) : 0.5 - 1 jour (API + options)
         - `merchant` scene/overlay : 0.5 - 1 jour (catalogue + transactions)
         - Overlays (gameover/reward/initiative) : 0.5 jour total (squeletons + intégration)

      - Travail sans tous les assets : objectif → système fonctionnel avant beauté.
         - Implémenter des placeholders (backgrounds simples, sprites carrés, fontes par défaut) et des données mock (monstres/items) pour valider le flow.
         - Les assets graphiques/sons peuvent être branchés ensuite sans modifier la logique.

      - Renommage recommandé : `scene/gameplay/gameplay.lua` → `scene/gameplay/combat.lua` (ou `combat_manager.lua`) :
         - Raison : clarifier la responsabilité (gestion complète des phases de combat).
         - Actions à faire :
            - Créer `scene/gameplay/combat.lua` (copier/adapter `gameplay.lua` existant si présent) et implémenter l'API `onComplete(result)`.
            - Mettre à jour tous les `require` et les appels (`sceneManager:push(...)`, `preparation.lua`, tests, docs) pour pointer vers le nouveau nom.
            - Taille estimée du refactor + tests : 0.5 jour.
         - Bénéfice : permet d'isoler et tester le combat sans toucher le reste du flow.

      - Note technique : pour éviter les erreurs de require lors des tests hors LÖVE, ajouter un petit bootstrap de test qui expose les globals nécessaires (`_G.screen`, `_G.hud`, `_G.saveManager`, `_G.json`, etc.) ou prévoir `pcall(require, ...)` dans les modules non critiques.

### Phase 3 — Overlays
8. Créer overlays stackables :
   - `scene/overlay/overlay_gameover.lua`
   - `scene/overlay/overlay_reward.lua`
   - `scene/overlay/overlay_start.lua` (optionnel)
   - `scene/overlay/overlay_initiative.lua`
   - Intégrer `sceneManager:push("overlay_*")` depuis `gameplay.lua` aux points appropriés.

### Phase 4 — Intégration HUD / Audio
9. Assurer clearing / changement de contexte HUD via `_G.hud` lors de transitions majeures.
10. Gérer transitions audio (stop/transition des ambiances) via un audio manager central.

### Phase 5 — Tests & QA
11. Tests d'intégration :
    - Scénarios : Play -> router -> Intro -> VillageHub -> Hub -> Préparation -> Gameplay.
    - Continue game (save) -> skip Intro.
    - Edge cases : save corrompu, double push, skip intro, overlays stacking.

### Phase 6 — Déploiement
12. Merge en PR, exécution CI, monitoring logs (`gameLogs/`), rollback plan (restaurer callback Play direct si besoin).

---

## Fichiers ciblés
- Nouveaux fichiers recommandés :
  - `scene/gameflow/GameStartRouter.lua` (ou `scene/gameplay/GameStartRouter.lua`)
  - `scene/intro/intro.lua`
  - `scene/villageHub/villageHub.lua`
  - `scene/hub/hub.lua`
  - `scene/gameplay/preparation.lua`
  - `scene/overlay/overlay_gameover.lua`, `overlay_reward.lua`, `overlay_start.lua`, `overlay_initiative.lua`

- Modifications minimales :
  - `scene/menu/HUD/mainMenu.lua` (callback Play -> router)
  - `main.lua` (vérifier ordering HUD draw / scene startup)
  - `scene/gameplay/gameplay.lua` (push overlay)

---

## Estimation globale
- Effort total ≈ 5–7 jours (1 dev) selon disponibilité assets et validations.
- Priorité immédiate : `GameStartRouter` + remplacement callback Play + skeleton `intro`/`villageHub`.

---

## Notes & recommandations
- Utiliser `SceneManager:push()` pour overlays afin de conserver pile et revenir proprement.
- Prévoir un petit bootstrap de tests unitaires (init globals minima) pour exécuter modules hors LÖVE.
- Travailler en branche feature et ouvrir PR avec captures d'écran + logs de transitions pour revue.

---

Fin du TODO.
