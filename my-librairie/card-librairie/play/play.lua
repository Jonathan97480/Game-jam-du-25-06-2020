-- my-librairie/card-librairie/play/play.lua
local Common      = require("my-librairie/card-librairie/core/common")
local Layout      = require("my-librairie/card-librairie/ui/layout")
local Anim        = require("my-librairie/card-librairie/play/anim")

-- Import du nouveau CardManager
local CardManager = require("my-librairie/card-librairie/card_manager")

-- Fonction de log pour le système
local function _log(message)
    local gf = rawget(_G, "globalFunction")
    if gf and gf.log and gf.log.info then
        gf.log.info("[play.lua] " .. tostring(message))
    else
        print("[play.lua] " .. tostring(message))
    end
end

local function getHud() return rawget(_G, "hud") end
local function getHero() return rawget(_G, "Hero") end
local function getEnemies() return rawget(_G, "Enemies") end
local function getTour() return rawget(_G, "Tour") end

local M = {}

function M.cardToGraveyard(c)
    local cardRemoved = false


    -- PRIORITÉ 2: Si pas en standby, chercher dans la main
    if not cardRemoved then
        for i = #Common.hand.cards, 1, -1 do
            if Common.hand.cards[i] == c then
                table.remove(Common.hand.cards, i)
                _log("📍 Carte retirée de la MAIN (index " .. i .. ")")
                cardRemoved = true
                break
            end
        end
    end

    if not cardRemoved then
        _log("⚠️ ATTENTION: Carte '" .. (c.name or "?") .. "' non trouvée ni en standby ni en main !")
    end

    -- Ajouter au cimetière
    if Common.graveyard.cards and Common.graveyard.addCard then
        Common.graveyard:addCard(c)
        _log("💀 Carte ajoutée au cimetière: " .. (c.name or "?"))
    end

    -- NOUVEAU : Utiliser CardManager pour gestion sécurisée
    CardManager.onCardMoveToGrave(c, "cardToGraveyard - play.lua")
end

local function _tryPlay(_card, free)
    -- ===== LOGS DÉTAILLÉS DES CONDITIONS =====
    _log("🎮 [ANALYSE CONDITIONS CARTE] Début vérification pour: " .. (_card.name or "carte sans nom"))

    local tour = getTour()
    _log("📊 Condition TOUR - Actuel: " .. tostring(tour) .. " / Requis pour carte: " .. tostring(_card.actorTag))

    -- Condition 1: Tour valide
    if _card.actorTag == 'Hero' and tour ~= 'player' then
        _log("❌ ÉCHEC CONDITION 1: Tour Hero mais tour actuel n'est pas 'player'")
        return false
    end
    if _card.actorTag ~= 'Hero' and tour ~= 'Enemy' then
        _log("❌ ÉCHEC CONDITION 1: Tour Ennemi mais tour actuel n'est pas 'Enemy'")
        return false
    end
    _log("✅ CONDITION 1 OK: Tour valide")

    local HeroG    = getHero()
    local EnemiesG = getEnemies()
    local source   = (_card.actorTag == 'Hero') and (HeroG and HeroG.actor) or
        (EnemiesG and EnemiesG.curentEnemy)

    -- Condition 2: Source valide
    _log("📊 Condition SOURCE - Trouvée: " .. (source and (source.name or "source sans nom") or "AUCUNE"))
    if not source then
        _log("❌ ÉCHEC CONDITION 2: Source manquante")
        return false
    end
    _log("✅ CONDITION 2 OK: Source valide")

    -- ===== NOUVEAU SYSTÈME DE CIBLAGE MANUEL =====
    local target              = nil

    -- Vérifier si le système de ciblage manuel est actif
    local CardTargetSelection = rawget(_G, "CardTargetSelection")
    if _card.actorTag == 'Hero' and CardTargetSelection and CardTargetSelection.selectedTarget then
        -- Utiliser la cible sélectionnée manuellement
        target = CardTargetSelection.selectedTarget
        _log("🎯 [CIBLAGE MANUEL] Cible trouvée: " .. (target.name or "Ennemi"))
    elseif _card.actorTag == 'Hero' and CardTargetSelection and _card.selectedTarget then
        -- Vérifier si la carte a une cible assignée directement
        target = _card.selectedTarget
        _log("🎯 [CIBLAGE DIRECT] Cible trouvée sur carte: " .. (target.name or "Ennemi"))
    else
        -- Fallback sur l'ancien système automatique
        target = (_card.actorTag == 'Hero') and (EnemiesG and EnemiesG.curentEnemy) or (HeroG and HeroG.actor)
        if _card.actorTag == 'Hero' then
            _log("🎯 [CIBLAGE AUTO] Cible automatique: " .. (target and target.name or "AUCUNE"))
        end
    end
    -- ===== FIN NOUVEAU SYSTÈME DE CIBLAGE =====

    -- Condition 3: État de résolution
    _log("📊 Condition RESOLVING - État _resolving: " .. tostring(_card._resolving))
    if _card._resolving then
        _log("❌ ÉCHEC CONDITION 3: Carte déjà en cours de résolution")
        return false
    end
    _log("✅ CONDITION 3 OK: Carte pas en résolution")

    _card._resolving = true
    local prevCurrent = M._currentPlaying
    M._currentPlaying = _card

    local cost = tonumber(_card.PowerBlow or 0) or 0
    _log("📊 Condition COÛT - Coût carte: " .. tostring(cost) .. " / Gratuit: " .. tostring(free))

    if (source.tag == 'Hero') then
        if source.state and source.state.power then
            _log("📊 Énergie source - Disponible: " .. tostring(source.state.power) .. " / Requis: " .. tostring(cost))
        end

        -- Condition 4: Coût suffisant
        if not free and source.state and source.state.power and source.state.power < cost then
            _log("❌ ÉCHEC CONDITION 4: Énergie insuffisante (" ..
                tostring(source.state.power) .. " < " .. tostring(cost) .. ")")
            _card._resolving = false; M._currentPlaying = prevCurrent; return false
        end
        _log("✅ CONDITION 4 OK: Coût validé")

        -- Déduction du coût
        if not free and source.state and source.state.power then
            source.state.power = source.state.power - cost
            _log("💰 Coût déduit - Nouvelle énergie: " .. tostring(source.state.power))
            local hud = getHud()
            if hud and type(hud.updateLabel) == "function" then
                hud.updateLabel('energy_text', tostring(source.state.power))
            elseif hud and hud.object and hud.object.energie and hud.object.energie.value then
                hud.object.energie.value.text = tostring(source.state.power)
            end
        end
    end

    _log("🎯 CIBLE FINALE - " .. (target and target.name or "AUCUNE CIBLE"))
    _log("🚀 TOUTES CONDITIONS REMPLIES - Exécution effet carte...")

    if _card.Effect then
        Common.playCard(_card, source, target)
    end

    if type(_card.onPlay) == "function" and not _card._suppressOnPlay then
        local user = (_card.actorTag == 'Hero') and getHero() or getEnemies()
        local prev_card = rawget(_G, "card")
        local prev_Card = rawget(_G, "Card")
        rawset(_G, "card", _G.Card or {})
        rawset(_G, "Card", _G.Card or {})
        pcall(_card.onPlay, user)
        rawset(_G, "card", prev_card)
        rawset(_G, "Card", prev_Card)
    end

    _card._suppressOnPlay = nil

    -- NOUVEAU : Notification CardManager du début de jeu
    CardManager.onCardPlayStart(_card, "_tryPlay - play.lua")

    _card._playing = true
    _card._anim = { kind = "jump", t = 0, d = 0.35, startX = _card.vector2.x, startY = _card.vector2.y }
    _card._safetyTimer = 0.6

    _card._resolving = false
    M._currentPlaying = prevCurrent

    _log("🎉 [SUCCÈS CONDITIONS] Carte jouée avec succès: " .. (_card.name or "carte sans nom"))
    _log("===============================================")

    return true
end
M._tryPlay = _tryPlay
M.tryPlay = _tryPlay

M.action = { queue = {}, current = nil, busy = false }
function M.action.add(_card) if _card then table.insert(M.action.queue, _card) end end

M.action.addAction = M.action.add
function M.action.setCurrent() if not M.action.current then M.action.current = table.remove(M.action.queue, 1) end end

M.action.setCurrentAction = M.action.setCurrent
function M.action._applyEffect(_card) return _tryPlay(_card, false) end

function M.action.play()
    if not M.action.current then M.action.setCurrent() end
    if not M.action.current then return end
    _tryPlay(M.action.current, false)
    M.action.current = nil
end

function M.action.update(dt)
    local dt = globalFunction.clampDt(dt)
    if Anim and type(Anim.update) == "function" then return Anim.update(dt) end
end

function M.action.draw()
    if Anim and type(Anim.draw) == "function" then return Anim.draw() end
end

function M.drawHand()
    if Anim and type(Anim.drawHand) == "function" then return Anim.drawHand() end
end

M.func = {}
local function _normName(s)
    if type(s) ~= "string" then return "" end
    s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    return string.lower(s)
end

function M.func.find(name, list)
    if type(list) ~= "table" then return 0 end
    local target = _normName(name)
    for i = 1, #list do
        local it = list[i]
        if it and _normName(it.name) == target and it ~= M._currentPlaying and not it._resolving and not it._playing then
            return i
        end
    end
    return 0
end

function M.func.moveTo(fromList, index, toList)
    if type(fromList) ~= "table" or type(toList) ~= "table" then return end
    local it = fromList[index]; if not it then return end
    table.remove(fromList, index); table.insert(toList, it)
end

function M.func.playCardInTheHand(index, costOverride)
    local _card = Common.hand.cards[index]; if not _card then return end
    if M._currentPlaying and M._currentPlaying ~= _card then _card._suppressOnPlay = true end
    return _tryPlay(_card, (tonumber(costOverride) or 0) == 0)
end

function M.func.graveyardToMove(mode, dest)
    if mode == 'all' and type(dest) == "table" then
        for i = #Common.graveyard.cards, 1, -1 do
            table.insert(dest, Common.graveyard.cards[i])
            table.remove(Common.graveyard.cards, i)
        end
    end
end

function M.clearHand(opts)
    opts        = opts or {}
    local owner = (opts.owner == "Enemy") and "Enemy" or "Hero"
    local dest  = opts.dest or "graveyard"
    if owner == "Enemy" then return 0 else return Layout.moveAll(Common.hand.cards, dest) end
end

function M.clearHandPlayer(opts)
    opts = opts or {}; opts.owner = "Hero"; return M.clearHand(opts)
end

function M.clearHandEnemy(opts)
    opts = opts or {}; opts.owner = "Enemy"; return M.clearHand(opts)
end

return M
