# Référence des effets de cartes

Fichier source analysé : `ressources/cards_data_player.lua`

But : documenter toutes les clés d'effets observées dans le script, expliquer leur rôle, valeurs attendues, comportement multi-cible, et donner des exemples d'usage.

---

## Table des matières
- Résumé rapide
- Structure générale d'un `Effect`
- Liste complète des champs observés
- Multi-target (`multiTarget`) — fonctionnement et intégration
- `action` : fonction personnalisée
- Exemples extraits du projet
- Notes d'intégration (CardStandbyPlay, localisation, sauvegarde)
- 🔧 Fonctions à créer pour la partie `action` (liste et contrats)

---

## Résumé rapide
Chaque carte expose un champ `Effect` contenant typiquement deux sous-sections : `caster` (effets appliqués sur le lanceur) et `target` (effets appliqués sur la cible). Une entrée `action` (fonction) peut compléter la logique pour des effets personnalisés.

Les valeurs observées sont majoritairement numériques (montants, pourcentages) ou des tables pour effets temporels (ex: `bleeding`, `force_augmented`).

---

## Structure générale d'un `Effect`
Exemple minimal observé :

```lua
Effect = {
  caster = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
  target = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
  action = function() -- fonction optionnelle end
}
```

Remarques :
- `caster` et `target` sont des tables définissant des changements d'état immédiats ou à appliquer.
- `action` est une fonction Lua exécutée pour logique spécifique (recherche de jumelles, manipulations deck/graveyard, play automatique, etc.).

---

## Liste complète des champs observés et signification
Pour chaque champ : type attendu et comportement.

- heal (number)
  - Soigne la cible/lanceur de N points de vie.
  - Exemple : `caster.heal = 10` ajoute 10 pv au lanceur.

- shield (number)
  - Ajoute une réserve de bouclier absorbant des dégâts.
  - Exemple : `target.shield = 4` donne 4 bouclier à la cible.

- Epine (number)
  - Valeur d'épines (renvoie des dégâts quand la cible est touchée).
  - Observé en pourcentage ou valeur directe selon usage (ici valeur absolue : 50).

- attack (number)
  - Dégâts infligés à la cible (valeur immédiate soustraite aux PV.)
  - Exemple : `target.attack = 12`.

- AttackReduction (number)
  - Réduction du prochain dégât infligé par la cible (pourcentage ou valeur). Dans le code existant, valeurs comme `25` sont utilisées.

- shield_pass (number)
  - Mécanique spécifique : passer du bouclier vers une autre entité (implémentation projet spécifique).

- bleeding (table)
  - Forme : `{ value = number, number_turns = number }`
  - Applique des dégâts sur plusieurs tours.

- force_augmented (table)
  - Buff temporaire de force/puissance : `{ value = number, number_turns = number }`.

- chancePassedTour (number)
  - Pourcentage de faire rater un tour à la cible (exemple: 25 pour 25%).

- energyCostIncrease / energyCostDecrease (number)
  - Augmente ou diminue le coût énergétique de cartes/actions de la cible.

- Autres flags observés ou implicites
  - `Type` dans la carte (outside de Effect) : catégorise la carte (`"attaque"`, `"defense"`, `"soin"`, `"soutien"`, `"carte_jumelle"`, ...).
  - `PowerBlow`, `Rarete`, `ImgIlustration`, `Description` : métadonnées utilisées par HUD/renderer ou la recherche de carte.

---

## `action` : fonctions personnalisées
- Chaque carte peut définir `Effect.action = function() ... end`.
- Usage observé :
  - rechercher la présence d'une carte jumelle (`Card.func.find('Nom', Card.graveyard)`)
  - manipuler `Card.deck`, `Card.hand`, `Card.graveyard` (p.ex. `Card.func.moveTo`)
  - déclencher un `Card.func.playCardInTheHand(index, target)`
  - modifier directement l'état de l'acteur : `_user.actor.state.shield = ...`

Notes pratiques :
- Les `action` sont exécutées après la validation/applicaton des champs `caster`/`target` (implémentation standard attendue).
- Elles permettent des effets conditionnels qui ne sont pas décrits uniquement par des nombres (ex: pioche conditionnelle, free-play).

---

## Multi-target (`multiTarget`) — description et règles
Nous ajoutons ici la spécification du tag `multiTarget` (appelé "multisable" dans la discussion) :

- But : marquer une carte dont l'effet doit s'appliquer à **tous** les ennemis vivants automatiquement.
- Emplacement : propriété de la carte (générateur), p.ex. `card.multiTarget = true`.
- Valeur par défaut : `false` si absente.

Comportement attendu :
1. Lors de la phase de jeu, avant le ciblage, détecter `card.multiTarget == true`.
2. Si true : bypass du sélecteur de cible (pas d'interaction de sélection individuelle).
3. Application : appliquer les effets définis dans `Effect.target` à chaque ennemi vivant (itérer la liste ennemis et appliquer `attack`, `bleeding`, etc.).
4. Animation : déclencher animations AOE (cercles, chain lightning) et synchroniser application des dégâts.
5. `action` peut compléter la logique multi-cible (par ex. effets additionnels conditionnels sur chaque cible).

Exemple de structure de carte multi-target :
```lua
{
  id = "carte_fireball",
  name_key = "cards.names.carte_fireball",
  multiTarget = true,
  Effect = {
    caster = { /*...*/ },
    target = { attack = 25, bleeding = { value=5, number_turns=2 } },
    action = function() end
  }
}
```

---

## Exemples extraits du projet (cartes observées)

- `Coup puissant` : `target.attack = 12` → simple attaque single-target.
- `Aide moi mon ami` : action cherche "Aide mon ami" dans `Card.graveyard` et applique shield au lanceur.
- `Bouclier depines` : applique `caster.shield = 8` et `caster.Epine = 50` si la jumelle est au cimetière.
- `Double frappe` : `target.attack = 5` + `target.AttackReduction = 25`.
- `Deux soeurs` : si double présent dans le deck, pioche une carte aléatoire.

Ces exemples montrent l'utilisation conjointe de champs numériques et d'`action` pour logique conditionnelle.

---

## Intégration avec CardStandbyPlay / Auto-play
- Pour cartes `multiTarget`, `CardStandbyPlay` doit exécuter un flux différent :
  - Détecter `multiTarget` à la mise en standby.
  - Ne pas créer de copie targetable unique ; appeler `Card.Play.applyEffectToAllTargets(card)`.
  - Mettre à jour logs/animations pour montrer AOE.

- Si on désire un comportement automatique pour l'IA, l'IA doit aussi respecter `multiTarget` et appeler la même API d'application d'effets.

---

## Localisation et champs textuels
- Les textes (nom, description) peuvent être externalisés via clé de localisation (ex: `cards.names.carte_fireball`) pour supporter FR/EN.
- Les descriptions doivent supporter variables `{damage}`, `{target}` utilisées par `textFormatter.lua`.

---

## Recommandations d'implémentation
- Centraliser l'application d'effets dans un module `card_effects` :
  - `card_effects.applyToTarget(card, target)`
  - `card_effects.applyToAllTargets(card, enemies)` pour `multiTarget`
  - `card_effects.applyCasterEffects(card, caster)`
  - Cette centralisation évite les divergences et facilite debug/logs.

- Valider les `action` avec `pcall` pour éviter crash si erreur de script.
- Ajouter tests unitaires pour :
  - application single-target (attack/shield/heal)
  - application bleeding/force_augmented sur plusieurs tours
  - fonctionnement `multiTarget` (applique à tous ennemis vivants)
  - cas `carte_jumelle` (interaction avec deck/graveyard)

---

## Checklist (pour développement)
- [ ] Implémenter `card_effects` centralisé
- [ ] Ajouter support `multiTarget` dans `CardStandbyPlay` et IA
- [ ] Écrire tests unitaires pour effets de base et multiTarget
- [ ] Localiser tous les textes de cartes (FR/EN)
- [ ] Générateur de cartes : ajouter `multiTarget` flag par défaut `false`
- [ ] Créer assets visuels pour effets AOE / single-target

---

## 🔧 Fonctions à créer pour la partie `action` (liste et contrats)

Cette section décrit des fonctions utilitaires à implémenter dans `my-librairie/card-librairie/core/` (ou `my-librairie/tools/`) pour être réutilisées par les `Effect.action` des cartes.

Pour chaque fonction ci-dessous : signature, but, entrées/sorties, erreurs possibles et cas limites.

### 1) drawFromDeck(deck, n, toHand)
- But : piocher `n` cartes depuis `deck` vers `hand`.
- Entrées : `deck` (table), `n` (number), `toHand` (table destination, ex: `Card.hand`).
- Sorties : table des cartes piochées.
- Erreurs : si `n <= 0` retourne `{}` ; si deck vide retourne `{}`.
- Cas limites : si `n > #deck` piocher tout le deck.
- Exemple : `local drawn = CardActions.drawFromDeck(Card.deck, 1, Card.hand)`

### 2) moveFromGraveyard(filter, dest, count)
- But : déplacer `count` cartes depuis `Card.graveyard` vers `dest` en fonction d'un `filter` (string name | function predicate).
- Entrées : `filter` (string ou function), `dest` (table), `count` (number)
- Sortie : liste des cartes déplacées
- Comportement : si `filter` string => recherche par nom, si function => test predicate(card) => true
- Exemple : `CardActions.moveFromGraveyard('A', Card.deck, 1)`

### 3) findCardByName(name, zone)
- But : retourner l'index et la référence de la première carte portant `name` dans `zone` (deck/hand/graveyard).
- Entrées : `name` (string), `zone` (table)
- Sortie : `index` (number) ou 0 si non trouvé, `card` (table) ou nil
- Exemple : `local idx, c = CardActions.findCardByName('Aide mon ami', Card.graveyard)`

### 4) findCardsByType(typeName, zone)
- But : retourner une table d'indices/cartes correspondant au `typeName`.
- Entrées : `typeName` (string), `zone` (table)
- Sortie : liste `{ {index=..., card=...}, ... }`
- Exemple : `local list = CardActions.findCardsByType('carte_jumelle', Card.deck)`

### 5) findCardsByRarity(rarity, zone)
- But : filtrer par rareté (`'commun'|'rare'|...`).
- Sortie : table cartes matching.

### 6) setTargetStone(targetActor, durationTurns)
- But : mettre `targetActor` en état "stone" (skip turn) pour `durationTurns` tours.
- Entrées : `targetActor` (actor object), `durationTurns` (number)
- Effet attendu : `targetActor.state.stoned = durationTurns` et hook dans le système de tours pour décrémenter et empêcher action.
- Cas limites : si duration <= 0 => no-op.
- Exemple : `CardActions.setTargetStone(enemyActor, 1)`

### 7) addEffectToActor(actor, effectTable)
- But : ajouter dynamiquement un effet sur `actor` (shield, bleed, buff, debuff).
- Entrées : `actor`, `effectTable` (forme identique aux `caster`/`target`).
- Comportement : fusionner/chainer les effets ; respecter `number_turns` pour effets temporels.
- Exemple : `CardActions.addEffectToActor(enemy, { bleeding = {value=3, number_turns=2} })`

### 8) spawnProjectileEffect(opts)
- But : créer un `actor` projectile visuel/logique qui se déplace vers une cible et déclenche `onHit`.
- `opts` fields (proposé) :
  - `caster` (actor), `target` (actor) ou `targetPos` ({x,y}),
  - `sprite` (string), `startPos` ({x,y}), `speed` (number), `size`,
  - `onHit` (function(target, projectile)),
  - `hitAnim` (string), `explodeAnim` (string), `aoeRadius` (number, optionnel),
  - `travelBehavior` ("linear"|"parabola"|function),
  - `lifetime` (seconds) fallback.
- Retour : référence du projectile actor.
- Comportement : spawn -> move -> collision detection -> call `onHit` -> play hit/explosion -> destroy
- Exemple :
```lua
CardActions.spawnProjectileEffect({ caster=player, target=enemy, sprite='img/effect/fireball.png', speed=600, onHit=function(t,p) card_effects.applyToTarget(card, t) end, explodeAnim='explode_big' })
```
- Notes : le projectile est un acteur léger géré par `actorManager` pour bénéficier des systèmes d'animation et update/draw.

### 9) playAOEEffect(centerPos, radius, effectTable)
- But : appliquer `effectTable` à tous les acteurs dans `radius` autour de `centerPos`.
- Exemple : invocation par `spawnProjectileEffect` avec `aoeRadius`.

### 10) applyEffectToTarget(card, targetActor)
- But : appliquer la logique `Effect.caster` et `Effect.target` de `card` sur `caster` et `targetActor`.
- Entrées : `card`, `targetActor`, `caster` (optionnel)
- Comportement : appeler `addEffectToActor` pour buffs/dots, appliquer dégâts directs, appeler `action` en sécurité (pcall).

### 11) applyEffectToAllTargets(card, enemies)
- But : itérer `enemies` et appeler `applyEffectToTarget` par cible (utilisé pour `multiTarget=true`).

### 12) safeCall(fn, ...)
- But : wrapper `pcall` pour exécuter les `action` des cartes sans casser le runtime.
- Retour : boolean success, result or error
- Utiliser pour exécuter `card.Effect.action`

### 13) scheduleDelayed(func, delaySeconds)
- But : exécuter `func` après `delaySeconds` (utile pour séquencer animation -> application d'effet).
- Implémentation : scheduler global update -> countdown -> call.

---

## Contrat rapide recommandé pour `Effect.action`
- Entrées : contexte implicite accessible via variables globales/documentées (ex : `_user`, `_target`, `Card`, `actorManager`).
- Retour : optionnel ; l'`action` doit utiliser `CardActions` et `card_effects` plutôt que manipuler directement les tables internes quand possible.
- Exécution : appeler via `safeCall(card.Effect.action, context)` pour éviter crash.

---

## Exemple d'utilisation combinée
- Carte AOE boules de feu :
  - `Effect.target = { attack = 12 }`, `multiTarget = true`
  - `Effect.action = function() CardActions.spawnProjectileEffect({ caster=_user, targets=_enemies, sprite='img/effect/fireball.png', speed=600, onHit=function(t,p) card_effects.applyToTarget(card, t) end, explodeAnim='boom' }) end`

- Carte qui met en stone :
  - `Effect.target = { }`, `Effect.action = function() CardActions.setTargetStone(_target, 1) end`

---

## Emplacement recommandé
- `my-librairie/card-librairie/core/card_actions.lua` (implémentation des fonctions ci-dessus)
- `my-librairie/card-librairie/core/card_effects.lua` (logique d'application des effets)
- `my-librairie/actorManager.lua` (gestion projectiles/acteurs si absent)

---


