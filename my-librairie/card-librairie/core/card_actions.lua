-- my-librairie/card-librairie/core/card_actions.lua
-- Module utilitaires pour les fonctions action des cartes
-- Complément du système card_effects pour les actions complexes

local card_actions = {}

-- Modules requis
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

local Card = _safeRequire("my-librairie/card-librairie/card")
local actorManager = _safeRequire("my-librairie/managers/actorManager")
local globalFunction = _G.globalFunction or _safeRequire("my-librairie/utils/globalFunction")

-- Logger local
local function _log(level, msg)
    if globalFunction and globalFunction.log then
        globalFunction.log[level]("[card_actions] " .. msg)
    else
        print("[card_actions] [" .. level .. "] " .. msg)
    end
end

---=============================================================================
--- MANIPULATION DECK/HAND/GRAVEYARD
---=============================================================================

-- Tire n cartes du deck vers la main
-- @param deckName string : Nom du deck source
-- @param n number : Nombre de cartes à tirer
-- @param toHand boolean : Si true, place en main, sinon retourne les cartes
-- @return table : Cartes tirées
function card_actions.drawFromDeck(deckName, n, toHand)
    if not Card or not Card.tirage then
        _log("warn", "drawFromDeck: Module Card non disponible")
        return {}
    end

    toHand = toHand == nil and true or toHand
    local drawnCards = {}

    pcall(function()
        if toHand then
            -- Utilise le système de tirage existant
            Card.tirage(n, deckName)
            _log("info", string.format("📥 Tiré %d cartes de %s vers main", n, deckName or "deck"))
        else
            -- Tire sans placer en main (pour actions spéciales)
            local deck = Card.deck[deckName]
            if deck and #deck > 0 then
                for i = 1, math.min(n, #deck) do
                    table.insert(drawnCards, table.remove(deck, 1))
                end
                _log("info", string.format("📤 Tiré %d cartes de %s (sans placer en main)", #drawnCards, deckName))
            end
        end
    end)

    return drawnCards
end

-- Déplace une carte du cimetière vers une destination
-- @param filter function : Fonction de filtrage (card) -> boolean
-- @param destZone string : Zone destination ("hand", "deck", "standby")
-- @param count number : Nombre maximum de cartes à déplacer
-- @return number : Nombre de cartes déplacées
function card_actions.moveFromGraveyard(filter, destZone, count)
    if not Card or not Card.graveyard then
        _log("warn", "moveFromGraveyard: Module Card non disponible")
        return 0
    end

    count = count or 1
    local moved = 0

    pcall(function()
        local graveyard = Card.graveyard
        local toMove = {}

        -- Trouve les cartes correspondant au filtre
        for i = #graveyard, 1, -1 do
            local card = graveyard[i]
            if not filter or filter(card) then
                table.insert(toMove, { card = card, index = i })
                if #toMove >= count then break end
            end
        end

        -- Déplace les cartes trouvées
        for _, item in ipairs(toMove) do
            local card = item.card
            table.remove(graveyard, item.index)

            if destZone == "hand" and Card.hand then
                table.insert(Card.hand, card)
                _log("info", string.format("♻️ Carte '%s' déplacée: cimetière → main", card.name or "?"))
            elseif destZone == "deck" and Card.deck then
                local playerDeck = Card.deck["HeroDeck"] or Card.deck["globalDeck"]
                if playerDeck then
                    table.insert(playerDeck, card)
                    _log("info", string.format("♻️ Carte '%s' déplacée: cimetière → deck", card.name or "?"))
                end
            end

            moved = moved + 1
        end
    end)

    return moved
end

-- Déplace une carte entre zones
-- @param sourceZone string : Zone source ("hand", "deck", "graveyard")
-- @param destZone string : Zone destination
-- @param cardIndex number : Index de la carte dans la zone source
-- @return boolean : Succès du déplacement
function card_actions.moveBetweenZones(sourceZone, destZone, cardIndex)
    if not Card then
        _log("warn", "moveBetweenZones: Module Card non disponible")
        return false
    end

    local success = false

    pcall(function()
        local sourceCards = Card[sourceZone]
        local destCards = Card[destZone]

        if sourceCards and destCards and sourceCards[cardIndex] then
            local card = table.remove(sourceCards, cardIndex)
            table.insert(destCards, card)
            _log("info", string.format("🔄 Carte '%s' déplacée: %s → %s", card.name or "?", sourceZone, destZone))
            success = true
        end
    end)

    return success
end

---=============================================================================
--- RECHERCHE DE CARTES
---=============================================================================

-- Trouve une carte par nom dans une zone
-- @param name string : Nom de la carte à chercher
-- @param zone string : Zone à examiner ("hand", "deck", "graveyard", "all")
-- @return table|nil : Carte trouvée ou nil
function card_actions.findCardByName(name, zone)
    if not Card or not name then return nil end

    zone = zone or "all"

    local function searchInZone(zoneName)
        local cards = Card[zoneName]
        if cards then
            for _, card in ipairs(cards) do
                if card.name == name then
                    return card
                end
            end
        end
        return nil
    end

    if zone == "all" then
        return searchInZone("hand") or searchInZone("deck") or searchInZone("graveyard")
    else
        return searchInZone(zone)
    end
end

-- Trouve des cartes par type dans une zone
-- @param typeName string : Type de carte à chercher
-- @param zone string : Zone à examiner
-- @return table : Liste des cartes trouvées
function card_actions.findCardsByType(typeName, zone)
    if not Card or not typeName then return {} end

    local found = {}
    zone = zone or "all"

    local function searchInZone(zoneName)
        local cards = Card[zoneName]
        if cards then
            for _, card in ipairs(cards) do
                if card.type == typeName or (card.tags and card.tags[typeName]) then
                    table.insert(found, card)
                end
            end
        end
    end

    if zone == "all" then
        searchInZone("hand")
        searchInZone("deck")
        searchInZone("graveyard")
    else
        searchInZone(zone)
    end

    return found
end

-- Trouve des cartes par rareté
-- @param rarity string : Rareté recherchée ("common", "rare", "epic", "legendary")
-- @param zone string : Zone à examiner
-- @return table : Liste des cartes trouvées
function card_actions.findCardsByRarity(rarity, zone)
    if not Card or not rarity then return {} end

    local found = {}
    zone = zone or "all"

    local function searchInZone(zoneName)
        local cards = Card[zoneName]
        if cards then
            for _, card in ipairs(cards) do
                if card.rarity == rarity then
                    table.insert(found, card)
                end
            end
        end
    end

    if zone == "all" then
        searchInZone("hand")
        searchInZone("deck")
        searchInZone("graveyard")
    else
        searchInZone(zone)
    end

    return found
end

---=============================================================================
--- EFFETS SPÉCIAUX
---=============================================================================

-- Applique l'effet "Statue de pierre" à une cible (immobilisation temporaire)
-- @param targetActor table : Acteur cible
-- @param durationTurns number : Durée en tours
-- @return boolean : Succès de l'application
function card_actions.setTargetStone(targetActor, durationTurns)
    if not targetActor or not targetActor.state then
        _log("warn", "setTargetStone: Acteur cible invalide")
        return false
    end

    durationTurns = durationTurns or 2

    local success = pcall(function()
        -- Ajoute l'effet "statue de pierre"
        targetActor.state.isStoned = true
        targetActor.state.stoneTurnsLeft = durationTurns

        -- Applique les effets visuels si disponibles
        if targetActor.visual then
            targetActor.visual.tint = { 0.7, 0.7, 0.7, 1.0 } -- Teinte grise
        end

        _log("info", string.format("🗿 Effet statue appliqué à %s (%d tours)", targetActor.name or "?", durationTurns))
    end)

    return success
end

-- Ajoute un effet temporaire à un acteur avec fusion intelligente
-- @param actor table : Acteur cible
-- @param effectTable table : Table d'effets à ajouter
-- @return boolean : Succès de l'application
function card_actions.addEffectToActor(actor, effectTable)
    if not actor or not actor.state or not effectTable then
        _log("warn", "addEffectToActor: Paramètres invalides")
        return false
    end

    local success = pcall(function()
        -- Initialise la table des effets temporaires si nécessaire
        actor.state.temporaryEffects = actor.state.temporaryEffects or {}

        -- Fusionne les effets avec les existants
        for effectName, value in pairs(effectTable) do
            if type(value) == "number" then
                -- Effets numériques : addition
                actor.state.temporaryEffects[effectName] = (actor.state.temporaryEffects[effectName] or 0) + value
            elseif type(value) == "boolean" then
                -- Effets booléens : OR logique
                actor.state.temporaryEffects[effectName] = actor.state.temporaryEffects[effectName] or value
            else
                -- Autres types : remplacement
                actor.state.temporaryEffects[effectName] = value
            end
        end

        _log("info", string.format("✨ Effets temporaires ajoutés à %s", actor.name or "?"))
    end)

    return success
end

-- Spawn un projectile avec effet visuel
-- @param sourceActor table : Acteur source
-- @param targetActor table : Acteur cible
-- @param projectileType string : Type de projectile ("ink", "knife", "web", "sword")
-- @param onImpact function : Callback d'impact (optionnel)
-- @return boolean : Succès du spawn
function card_actions.spawnProjectileEffect(sourceActor, targetActor, projectileType, onImpact)
    if not sourceActor or not targetActor then
        _log("warn", "spawnProjectileEffect: Acteurs source/cible manquants")
        return false
    end

    projectileType = projectileType or "default"

    local success = pcall(function()
        -- Crée le projectile (simulation basique)
        local projectile = {
            type = projectileType,
            source = sourceActor,
            target = targetActor,
            startPos = { x = sourceActor.vector2.x, y = sourceActor.vector2.y },
            endPos = { x = targetActor.vector2.x, y = targetActor.vector2.y },
            speed = 300, -- pixels/seconde
            progress = 0,
            onImpact = onImpact
        }

        -- Ajoute à la liste des projectiles actifs (si le système existe)
        if actorManager and actorManager.addProjectile then
            actorManager.addProjectile(projectile)
        else
            -- Simulation directe pour tests
            if onImpact then
                onImpact(projectile)
            end
        end

        _log("info",
            string.format("🎯 Projectile %s lancé: %s → %s", projectileType, sourceActor.name or "?",
                targetActor.name or "?"))
    end)

    return success
end

-- Joue un effet AOE dans une zone
-- @param centerPos table : Position centrale {x, y}
-- @param radius number : Rayon d'effet
-- @param effectType string : Type d'effet visuel
-- @param onAffected function : Callback pour chaque acteur affecté
-- @return number : Nombre d'acteurs affectés
function card_actions.playAOEEffect(centerPos, radius, effectType, onAffected)
    if not centerPos or not centerPos.x or not centerPos.y then
        _log("warn", "playAOEEffect: Position centrale invalide")
        return 0
    end

    radius = radius or 100
    effectType = effectType or "explosion"
    local affected = 0

    pcall(function()
        -- Trouve tous les acteurs dans la zone
        local actors = {}

        -- Ajoute les ennemis si actorManager disponible
        if actorManager and actorManager.getAllEnemies then
            local enemies = actorManager.getAllEnemies()
            for _, enemy in ipairs(enemies) do
                if enemy.vector2 then
                    local distance = math.sqrt((enemy.vector2.x - centerPos.x) ^ 2 + (enemy.vector2.y - centerPos.y) ^ 2)
                    if distance <= radius then
                        table.insert(actors, enemy)
                    end
                end
            end
        end

        -- Applique l'effet à chaque acteur affecté
        for _, actor in ipairs(actors) do
            if onAffected then
                onAffected(actor)
            end
            affected = affected + 1
        end

        _log("info", string.format("💥 Effet AOE %s: %d acteurs affectés (rayon: %d)", effectType, affected, radius))
    end)

    return affected
end

---=============================================================================
--- UTILITAIRES
---=============================================================================

-- Appel sécurisé avec gestion d'erreur
-- @param func function : Fonction à appeler
-- @param ... : Arguments de la fonction
-- @return boolean, any : Succès et résultat
function card_actions.safeCall(func, ...)
    if type(func) ~= "function" then
        _log("warn", "safeCall: Paramètre fourni n'est pas une fonction")
        return false, nil
    end

    local success, result = pcall(func, ...)
    if not success then
        _log("error", "safeCall: Erreur lors de l'exécution - " .. tostring(result))
    end

    return success, result
end

-- Programme une action avec délai (simulation pour LÖVE2D)
-- @param func function : Fonction à exécuter
-- @param delay number : Délai en secondes
-- @param ... : Arguments de la fonction
-- @return table : Handle de la tâche programmée
function card_actions.scheduleDelayed(func, delay, ...)
    if type(func) ~= "function" then
        _log("warn", "scheduleDelayed: Paramètre fourni n'est pas une fonction")
        return nil
    end

    delay = delay or 0
    local args = { ... }

    local task = {
        func = func,
        args = args,
        executeTime = (love and love.timer and love.timer.getTime() or os.time()) + delay,
        id = math.random(1000000)
    }

    -- Ajoute à la liste des tâches programmées (simulation)
    _G.scheduledTasks = _G.scheduledTasks or {}
    table.insert(_G.scheduledTasks, task)

    _log("info", string.format("⏰ Tâche programmée (délai: %.2fs, id: %d)", delay, task.id))

    return task
end

-- Validation et logs
function card_actions.validateContext()
    local warnings = {}

    if not Card then
        table.insert(warnings, "Module Card non disponible")
    end

    if not actorManager then
        table.insert(warnings, "Module actorManager non disponible")
    end

    if not globalFunction then
        table.insert(warnings, "Module globalFunction non disponible")
    end

    if #warnings > 0 then
        _log("warn", "validateContext: " .. table.concat(warnings, ", "))
        return false
    end

    return true
end

_log("info", "🔧 Module card_actions initialisé avec " ..
    "drawFromDeck, moveFromGraveyard, findCard*, setTargetStone, addEffectToActor, " ..
    "spawnProjectileEffect, playAOEEffect, safeCall, scheduleDelayed")

return card_actions
