# Guide de Développement de Cartes

## 🎯 Système opérationnel - Prêt pour de nouvelles cartes !

Le système `card_effects` est maintenant **validé en production**. Vous pouvez créer de nouvelles cartes facilement !

## 🃏 Exemples de cartes à implémenter

### 1. Cartes d'attaque avancées
```lua
{
    name = "Frappe Foudroyante",
    Effect = {
        target = {
            attack = 8,
            AttackReduction = 2  -- Réduit l'attaque de l'ennemi
        },
        caster = {
            heal = 2  -- Le lanceur récupère de la vie
        }
    },
    multiTarget = false,
    onPlay = function()
        -- Effet visuel éclair
        spawnProjectileEffect("lightning", _target.x, _target.y)
    end
}
```

### 2. Cartes AOE (multiTarget)
```lua
{
    name = "Tempête de Glace",
    Effect = {
        target = {
            attack = 5,
            chancePassedTour = 30  -- 30% chance de stun
        }
    },
    multiTarget = true,  -- ⭐ Applique à tous les ennemis !
    onPlay = function()
        playAOEEffect("frost_storm", {x = 400, y = 300}, 150)
    end
}
```

### 3. Cartes de manipulation de deck
```lua
{
    name = "Recyclage Magique",
    Effect = {
        caster = {
            heal = 3
        }
    },
    onPlay = function()
        -- Récupère 2 cartes du cimetière
        moveFromGraveyard(function(card) return true end, "hand", 2)
        drawFromDeck(1, "hand")
    end
}
```

## 🛠️ Workflow de création

1. **Ajouter la carte** dans `ressources/cards_data_player.lua`
2. **Tester immédiatement** - le système gère automatiquement :
   - Application des effets `target` et `caster`
   - Détection AOE via `multiTarget`
   - Exécution sécurisée des `onPlay`
   - Logs détaillés pour debug

3. **Assets visuels** : Utiliser les placeholders dans `effect_assets.json`

## 🎨 Assets disponibles pour effets visuels
- `img/effect/Attaque-base/` - Attaques physiques
- `img/effect/heal/` - Soins
- `img/effect/shield/` - Boucliers
- `img/effect/epine/` - Épines/contre-attaques
- `img/effect/degat/` - Dégâts génériques

## 🔧 Fonctions utilitaires disponibles
```lua
-- Dans card.onPlay, vous avez accès à :
drawFromDeck(n, "hand")
moveFromGraveyard(filter, "hand", count)
spawnProjectileEffect("fire", x, y)
playAOEEffect("explosion", {x, y}, radius)
setTargetStone(target, 3)  -- Pierre de ciblage 3 tours
```
