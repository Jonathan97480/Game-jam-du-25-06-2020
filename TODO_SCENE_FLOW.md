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
6. Créer `scene/hub/hub.lua` : interface planification/mission, bouton « Préparer » -> push `scene/gameplay/preparation.lua`.
7. Créer `scene/gameplay/preparation.lua` : sélection deck/mission -> push `scene/gameplay/gameplay.lua`.

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
