# Assets graphiques nécessaires

Ce fichier recense et organise les assets graphiques nécessaires pour le projet, extraits du TODO principal. Pour chaque asset je fournis : chemin recommandé, format/suggestion de résolution, et un nom d'exemple.

---

## Règles générales
- Format recommandé : PNG (RGBA) pour sprites et UI ; JPG pour fonds fixes si pas d'alpha.
- Résolution de référence jeu : 1920x1080 (gameResolution)
- Organisation des dossiers : `img/<catégorie>/...` (ex : `img/menu/`, `img/logoStudio/`)
- Prévoir variantes @2x si support de haute DPI requis
- Utiliser noms courts et descriptifs, éviter les espaces (utiliser underscore `_` ou tiret `-`).

---

## 1 — Branding / Logos
- `img/logoStudio/logo_studio_1920x1080.png` — Logo start_studio (PNG, 1920x1080)
- `img/logoStudio/logo_studio_small.png` — Version small (ex: 512x512) pour fallback
- `img/logoGame/logo_game_full.png` — Logo principal menu (PNG, vectorisé / 1024x512)

## 2 — Menu principal
- `img/menu/menu_bg_1920x1080.png` — Background principal menu (PNG/JPG, 1920x1080)
- `img/menu/menu_logo.png` — Logo jeu affiché dans le menu (PNG, 1024x256)
- `img/menu/button_play.png`, `img/menu/button_load.png`, `img/menu/button_options.png`, `img/menu/button_credits.png`, `img/menu/button_quit.png` — Boutons principaux (PNG, 9-slice recommandé, source ~400x100)
- `img/menu/button_hover.png` — Sprite pour état hover (PNG, même taille que boutons)
- `img/menu/button_disabled.png` — État disabled (PNG)
- `img/menu/menu_decor/*.png` — Éléments décoratifs (vignettes, vignette par section)

## 3 — HUD & UI global
- `img/hud/life_bar.png` — Barre de vie (PNG, 300x24 ou scalable 9-slice)
- `img/hud/energy_icon.png` — Icône énergie (PNG, 64x64)
- `img/hud/icon_shield.png`, `img/hud/icon_heal.png`, `img/hud/icon_attack.png` — Icônes d'état (PNG, 64x64)
- `img/hud/panel_large.png` — Panel (9-slice) pour menus et fenêtres (PNG)
- `img/hud/button_small.png` — Boutons HUD (PNG)

## 4 — Boutons & Icônes (multi usage)
- `img/ui/icons/*.png` collection d'icônes 32x32, 64x64 : save, load, settings, back, home, plus, minus
- `img/ui/icons/action_play.png`, `img/ui/icons/action_pause.png` etc.
- `img/ui/controls/gamepad_button_A.png` (64x64), `gamepad_button_B.png` pour HUD manette

## 5 — Scenes (village, castle, intro)
- `img/scene/intro/intro_01.png` ... `intro_08.png` — Images narration (1920x1080)
- `img/scene/village/village_bg_1920x1080.png` — Background village
- `img/scene/village/buildings/*.png` — Bâtiments (shop, house, castle_gate) - separate PNGs with alpha
- `img/scene/castle/castle_prep_bg_1920x1080.png` — Salle préparation château
- `img/scene/castle/tower_tile_*.png` — Tuiles ou éléments décoratifs

## 6 — Floor map / Plan d'étage
- `img/floormap/floor_map_base_1920x1080.png` — Fond carte étage
- `img/floormap/icons/combat.png`, `rest.png`, `treasure.png`, `event.png`, `boss.png` — Icônes zones (128x128 et 64x64)
- `img/floormap/overlay_path.png` — Chemin highlight (semi-transparent)
- `img/floormap/player_marker.png` — Indicateur position joueur (64x64)

## 7 — Combat / Acteurs
- `img/actors/hero/hero_idle_*.png` — Spritesheet héros (frame size ex: 256x256) ou atlas
- `img/actors/enemies/<enemy_name>_idle_*.png` — Sprites ennemis (256x256 ou 512x512 selon style)
- `img/actors/portraits/<enemy_name>_portrait.png` — Portraits UI (512x512)

## 8 — Cartes & thumbs
- `img/cards/card_base_1024x1536.png` — Template carte master (avec zone artwork)
- `img/cards/artwork/*.png` — Artwork de cartes (512x768 ou 1024x1536)
- `img/cards/icon_attack.png`, `img/cards/icon_shield.png` — Petits icônes d'effet (64x64)

## 9 — Effets visuels (VFX)
- `img/effects/slash_*.png` — Slash hits (spritesheets ou PNGs séquentiels)
- `img/effects/heal_glow.png` — Heal effect overlay (PNG, additive)
- `img/effects/shield_barrier.png` — Shield overlay (PNG)
- `img/effects/particles/*.png` — Particles (smoke, spark, spark_big) at 64x64/128x128
- `img/effects/aoe_circle.png` — AOE indicator (512x512 semi-transparent)

## 10 — UI Textures & Nine-slice
- `img/ui/9slice/panel.9.png` — Panel scalable (9-slice)
- `img/ui/9slice/button.9.png` — Bouton scalable (9-slice)

## 11 — Menu & Credits extras
- `img/menu/credits_bg_1920x1080.png` — Background crédits
- `img/menu/credits_portraits/*.png` — Portraits équipe (512x512)

## 12 — Thumbnails & small assets
- `img/thumbs/level_preview_*.png` — Miniatures pour niveaux/étages (320x180)
- `img/thumbs/card_preview_*.png` — Miniatures cartes (200x300)

## 13 — Misc / Overlays
- `img/overlays/fade_black.png` — Fullscreen fade texture (1x1 white PNG with alpha usage scaled)
- `img/overlays/vignette.png` — Vignette overlay (1920x1080)
- `img/overlays/blur_low.png` — Low blur overlay (for modal backgrounds)

---

## Suggestions pratiques
- Placer chaque catégorie dans un dossier dédié (ex : `img/menu/`, `img/hud/`, `img/effects/`).
- Fournir une source vectorielle (SVG or PSD) pour les éléments de branding / logo.
- Préparer versions @1x et @2x pour assets UI si support écrans haute dpi.
- Utiliser atlas (JSON+PNG) pour particles & spritesheets pour perf.

---

Si vous voulez, je peux :
- créer la structure de dossiers `img/` et ajouter des placeholders (PNG transparents) pour chaque asset listé ;
- ou générer un CSV / JSON listant les assets avec métadonnées (path, taille, format). 

Indiquez la ou les actions suivantes que vous préférez.
