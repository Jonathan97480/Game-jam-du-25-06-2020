local Common         = require("my-librairie/card-librairie/core/common")
local UX             = require("my-librairie/card-librairie/ui/ux")
local screen         = _G.screen or require("my-librairie/utils/responsive")
local Layout         = require("my-librairie/card-librairie/ui/layout")

-- Import du nouveau CardManager
local CardManager    = require("my-librairie/card-librairie/card_manager")

local okInput, input = pcall(require, "my-librairie/inputManager")
if not okInput then input = nil end
local okI, inputI = pcall(require, "my-librairie/inputInterface")
if not okI then inputI = nil end

-- Import du module de sélection manuelle des cibles
local okCTS, CardTargetSelection = pcall(require, "my-librairie/card-librairie/ui/card_target_selection")
if not okCTS then CardTargetSelection = nil end

local M                         = {}

local mouseWasDown              = false
local draggedCard, draggedIndex = nil, nil
local DEBUG                     = rawget(_G, "DEBUG_CARD_INTERACTION") or false

local function _lerpTable(vec2, target, speed)
    local dt = (love and love.timer and love.timer.getDelta and love.timer.getDelta()) or 0.016
    local a = math.min(1, dt * (speed or 10))
    vec2.x = vec2.x + (target.x - vec2.x) * a
    vec2.y = vec2.y + (target.y - vec2.y) * a
end

local function _getCursor()
    local ok, inputIface = pcall(require, "my-librairie/inputInterface")
    if ok and type(inputIface) == "table" and type(inputIface.getCursor) == "function" then
        local c = inputIface.getCursor()
        return c.x or 0, c.y or 0
    end
    local gcur = rawget(_G, "cursor")
    if type(gcur) == "table" and type(gcur.get) == "function" then
        local cx, cy = gcur.get()
        return cx or 0, cy or 0
    end
    return 0, 0
end

-- logging helper
local function _logf(fmt, ...)
    local gf = rawget(_G, 'globalFunction')
    local text = string.format(fmt, ...)
    if gf and gf.log and gf.log.info then gf.log.info(text) else print(text) end
end

M._getDragState = function()
    return draggedCard, draggedIndex
end
M._setDragState = function(card, idx)
    draggedCard, draggedIndex = card, idx
end

function M.resetInteractions(hard)
    -- ===== FONCTION DE RESET DES INTERACTIONS =====
    -- Cette fonction remet toutes les cartes à leur position de base
    -- NOUVEAU : Utilise CardManager pour contrôle centralisé

    _logf("[Card.Interaction] ⚠️  APPEL resetInteractions - hard=%s", tostring(hard))

    -- NOUVEAU : Utiliser CardManager pour vérification
    if not CardManager.onResetInteractions(hard, "interaction.lua") then
        _logf("[Card.Interaction] 🛡️  RESET BLOQUÉ par CardManager")
        return
    end

    _logf("[Card.Interaction] 🔄 RESET EN COURS - Remise des cartes en position de base")

    draggedCard, draggedIndex = nil, nil
    Common.__dragLock = false
    mouseWasDown = false
    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]
        -- Protection : utiliser CardManager pour vérifier les cartes protégées
        if CardManager.isCardPlaying(_card) then
            _logf("[Card.Interaction] 🛡️  Protection CardManager: %s (ignore repositionnement)", _card.name or "carte")
            goto continue
        end

        _logf("[Card.Interaction] 📍 Repositionnement carte %d: %s", i, _card.name or "sans nom")

        local bx = (_card.oldVector2 and _card.oldVector2.x) or (_card.target and _card.target.x) or _card.vector2.x
        local by = (_card.oldVector2 and _card.oldVector2.y) or (_card.target and _card.target.y) or _card.vector2.y
        _card._targetPos = _card._targetPos or { x = bx, y = by }
        _card._targetScale = _card._targetScale or { x = Common.SCALE_BASE, y = Common.SCALE_BASE }
        _card._targetPos.x, _card._targetPos.y = bx, by
        _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
        if hard then
            _logf("[Card.Interaction] 💥 HARD RESET carte %s: position (%d, %d)", _card.name or "carte", bx, by)
            _card.vector2.x, _card.vector2.y = bx, by
            _card.scale.x, _card.scale.y = Common.SCALE_BASE, Common.SCALE_BASE
        end
        ::continue::
    end
end

function M.onTurnChanged(newTour)
    if newTour ~= 'player' then
        M.resetInteractions(true)
    end
end

function M.hover(dt)
    local tour = rawget(_G, "Tour")
    local isDown = false
    if input and input.state then
        local s = input.state()
        isDown = (s == 'pressed' or s == 'held')
    else
        local okI, iface = pcall(require, "my-librairie/inputInterface")
        if okI and iface and iface.isActionDown then
            isDown = iface.isActionDown()
        else
            -- fallback to robust globalFunction.mouse.state if available
            local okG, gf = pcall(require, "my-librairie/globalFunction")
            if okG and gf and gf.mouse and gf.mouse.state then
                local st = gf.mouse.state()
                isDown = (st == 'pressed' or st == 'held')
            else
                local okG, gf = pcall(require, "my-librairie/globalFunction")
                if okG and gf and gf.mouse and gf.mouse.state then
                    local st = gf.mouse.state()
                    isDown = (st == 'pressed' or st == 'held')
                else
                    local okI2, iface2 = pcall(require, "my-librairie/inputInterface")
                    if okI2 and iface2 and iface2.isActionDown then
                        isDown = iface2.isActionDown()
                    else
                        isDown = false
                    end
                end
            end
        end
    end
    local action = UX.UX_click(isDown, mouseWasDown) and "click" or nil
    pcall(function()
        local f = io.open("gameLogs/hover_trace.log", "a")
        if f then
            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hover start action=" .. tostring(action) .. "\n"); f:close()
        end
    end)
    if DEBUG then
        _logf("[Card.Interaction] isDown=%s mouseWasDown=%s action=%s", tostring(isDown),
            tostring(mouseWasDown), tostring(action))
    end

    if tour ~= 'player' then
        -- Protection : ne pas reset si système de ciblage actif
        local CardTargetSelection = rawget(_G, "CardTargetSelection")
        local CardStandbyPlay = rawget(_G, "CardStandbyPlay")
        local isTargetingActive = (CardTargetSelection and CardTargetSelection.isSelectingTarget) or
            (CardStandbyPlay and CardStandbyPlay.hasCardInStandby and CardStandbyPlay.hasCardInStandby())

        if (draggedCard or Common.__dragLock) and not isTargetingActive then
            M.resetInteractions(true)
            _logf("[Card.Interaction] RESET INTERACTIONS - tour=%s, draggedCard=%s, dragLock=%s",
                tostring(tour), draggedCard and draggedCard.name or "nil", tostring(Common.__dragLock))
        elseif isTargetingActive then
            _logf("[Card.Interaction] PROTECTION CIBLAGE ACTIF - pas de reset, tour=%s", tostring(tour))
        end
        for i = 1, #Common.hand.cards do
            local _card = Common.hand.cards[i]
            local bx = (_card.oldVector2 and _card.oldVector2.x) or (_card.target and _card.target.x) or _card.vector2.x
            local by = (_card.oldVector2 and _card.oldVector2.y) or (_card.target and _card.target.y) or _card.vector2.y
            _card._targetPos = _card._targetPos or { x = bx, y = by }
            _card._targetScale = _card._targetScale or { x = Common.SCALE_BASE, y = Common.SCALE_BASE }
            _card._targetPos.x, _card._targetPos.y = bx, by
            _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
            _lerpTable(_card.vector2, _card._targetPos, 10)
            _lerpTable(_card.scale, _card._targetScale, 12)
        end
        mouseWasDown = isDown
        return
    end

    local hud = rawget(_G, "hud")
    local overHUD = UX.isMouseOverHUD()
    local hudHover = false
    if hud and hud.hover and overHUD and not draggedCard then
        pcall(function()
            local f = io.open("gameLogs/hover_trace.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - calling hud.hover\n"); f:close()
            end
        end)
        local ok, res = pcall(hud.hover, action)
        if ok then hudHover = res or false else hudHover = false end
        pcall(function()
            local f = io.open("gameLogs/hover_trace.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud.hover returned=" .. tostring(hudHover) .. "\n"); f:close()
            end
        end)
    end
    if hudHover then
        mouseWasDown = isDown; return
    end

    local topOverI = nil
    if not draggedCard and #Common.hand.cards > 0 then
        for i = #Common.hand.cards, 1, -1 do
            local _card = Common.hand.cards[i]
            if not _card._playing and not _card.locked then
                if UX.UX_hover(_card.vector2.x, _card.vector2.y, _card.width, _card.height, _card.scale) then
                    topOverI = i; if DEBUG then
                        _logf("[Card.Interaction] topOverI %s %s", tostring(topOverI),
                            tostring(_card.name))
                    end; break
                end
            end
        end
    end
    local hoveredCard = (topOverI and Common.hand.cards[topOverI]) or nil
    local active = draggedCard or hoveredCard
    if DEBUG then
        local dcName = draggedCard and draggedCard.name or nil
        _logf("[Card.Interaction] active index=%s dragged=%s", tostring(topOverI), tostring(dcName))
    end

    for i = 1, #Common.hand.cards do
        local _card = Common.hand.cards[i]
        -- ===== BOUCLE PRINCIPALE DE GESTION DES CARTES =====
        -- Cette boucle détermine la position et échelle cible de chaque carte
        -- ATTENTION: Peut causer le retour des cartes en main si mal géré

        local bx = (_card.oldVector2 and _card.oldVector2.x) or (_card.target and _card.target.x) or _card.vector2.x
        local by = (_card.oldVector2 and _card.oldVector2.y) or (_card.target and _card.target.y) or _card.vector2.y
        _card._targetPos = _card._targetPos or { x = bx, y = by }
        _card._targetScale = _card._targetScale or { x = Common.SCALE_BASE, y = Common.SCALE_BASE }

        -- Vérifier si la carte est en standby (protection contre retour automatique en main)
        local CardStandbyPlay = rawget(_G, "CardStandbyPlay")
        local isCardInStandby = CardStandbyPlay and CardStandbyPlay.hasCardInStandby() and
            CardStandbyPlay.standbyCard == _card

        if _card._playing or _card.locked or _card.anim then
            -- 🔒 CARTES PROTÉGÉES (en cours de jeu, verrouillées ou en animation)
            -- Ces cartes gardent leur position actuelle
            _card._targetPos.x, _card._targetPos.y = _card.vector2.x, _card.vector2.y
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y
            if _card._playing then
                _logf("[Card.Interaction] 🔒 Carte protégée (en jeu): %s", _card.name or "carte")
            end
        elseif isCardInStandby then
            -- 🎯 CARTE EN STANDBY - NE PAS BOUGER (pas de log pour éviter spam)
            _card._targetPos.x, _card._targetPos.y = _card.vector2.x, _card.vector2.y
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y
        elseif _card == draggedCard then
            -- 🎯 CARTE EN COURS DE DRAG
            _logf("[Card.Interaction] 🎯 Carte draggée: %s", _card.name or "carte")
            _card.scale.x, _card.scale.y = 1.05, 1.05
            local ex, ey = _getCursor()
            ex = ex - (_card._grabDX or _card.width / 2)
            ey = ey - (_card._grabDY or _card.height / 2)
            _card.vector2.x, _card.vector2.y = ex, ey
            _card._targetPos.x, _card._targetPos.y = ex, ey
            _card._targetScale.x, _card._targetScale.y = _card.scale.x, _card.scale.y

            if not isDown then
                -- ⚠️  SECTION CRITIQUE: CARTE RELÂCHÉE ⚠️
                -- C'est ici que se décide si la carte est jouée ou remise en main
                _logf("[Card.Interaction] ⚠️  CARTE RELÂCHÉE: %s", _card.name or "carte")

                draggedCard, draggedIndex = nil, nil
                Common.__dragLock = false
                local mx, my = _getCursor()
                local dropY = my
                local playLine = rawget(_G, "CARD_PLAY_LINE_Y") or 400
                local inZone = (dropY <= playLine)

                _logf("[Card.Interaction] 🎯 ZONE DE JEU: dropY=%d, playLine=%d, inZone=%s",
                    dropY, playLine, tostring(inZone))

                if DEBUG then
                    _logf("[Card.Interaction] dropY=%s playLine=%s inZone=%s", tostring(dropY),
                        tostring(playLine), tostring(inZone))
                end
                if inZone then
                    -- ===== NOUVEAU SYSTÈME DE CIBLAGE MANUEL =====
                    -- Si la carte est dans la zone de jeu, on tente de l'activer
                    _logf("[Card.Interaction] ✅ CARTE EN ZONE DE JEU - Tentative d'activation")

                    local CardTargetSelection = rawget(_G, "CardTargetSelection")

                    -- Récupération des ennemis (plusieurs patterns possibles)
                    local EnemiesG = _G.Enemies or require("my-librairie.entities.Enemy.Enemies")
                    local enemyList = {}

                    if EnemiesG and EnemiesG.listeEnemies then
                        enemyList = EnemiesG.listeEnemies
                    end

                    -- DEBUG: Logs détaillés pour diagnostiquer
                    _logf("[DEBUG interaction.lua] === ANALYSE CIBLAGE ===")
                    _logf("[DEBUG] Carte actorTag: %s", tostring(_card.actorTag))
                    _logf("[DEBUG] CardTargetSelection existe: %s", tostring(CardTargetSelection ~= nil))
                    _logf("[DEBUG] EnemiesG existe: %s", tostring(EnemiesG ~= nil))
                    _logf("[DEBUG] EnemiesG.listeEnemies: %s", EnemiesG and type(EnemiesG.listeEnemies) or "nil")
                    _logf("[DEBUG] Nombre d'ennemis: %d", #enemyList)

                    if EnemiesG and EnemiesG.listeEnemies then
                        for i, enemy in ipairs(EnemiesG.listeEnemies) do
                            local isDead = enemy.state and
                                (enemy.state.dead or (enemy.state.life and enemy.state.life <= 0))
                            _logf("[DEBUG] Ennemi %d: %s dead: %s life: %s", i, enemy.name or "sans nom",
                                tostring(isDead),
                                tostring(enemy.state and enemy.state.life))
                        end
                    end

                    -- Vérifier si il y a plusieurs ennemis VIVANTS pour décider du mode de ciblage
                    local aliveEnemies = 0
                    for _, enemy in ipairs(enemyList) do
                        if enemy.state and not enemy.state.dead and (not enemy.state.life or enemy.state.life > 0) then
                            aliveEnemies = aliveEnemies + 1
                        end
                    end

                    _logf("[DEBUG] Ennemis vivants: %d", aliveEnemies)

                    if _card.actorTag == 'Hero' and CardTargetSelection and aliveEnemies > 1 then
                        -- Vérifier si le système est déjà actif pour cette carte
                        if CardTargetSelection.isSelectingTarget and
                            CardTargetSelection.cardBeingPlayed and
                            CardTargetSelection.cardBeingPlayed.name == _card.name then
                            _logf("[DEBUG] Système de ciblage déjà actif pour: %s", _card.name or "carte")
                            return -- Sortir early, système déjà en cours
                        end

                        -- Mode ciblage manuel : démarrer la sélection de cible
                        _logf(
                            "[interaction.lua] ✅ CONDITIONS REMPLIES - Démarrage sélection cible pour: %s - Ennemis vivants: %d",
                            _card.name or "carte", aliveEnemies)

                        -- NOUVEAU : Mettre la carte en standby AVANT la sélection
                        local CardStandbyPlay = _G.CardStandbyPlay
                        if CardStandbyPlay then
                            -- Trouver l'index de la carte dans la main
                            local cardIndex = 1
                            for i, handCard in ipairs(Common.hand.cards) do
                                if handCard == _card then
                                    cardIndex = i
                                    break
                                end
                            end

                            local standbySuccess = CardStandbyPlay.putCardInStandby(_card, cardIndex)
                            _logf("[DEBUG] Carte mise en standby: %s", tostring(standbySuccess))
                        end

                        local success = CardTargetSelection.startTargetSelection(_card)
                        _logf("[DEBUG] startTargetSelection retourné: %s", tostring(success))
                        if success then
                            -- La carte est maintenant en standby et le ciblage est actif
                            print("[DEBUG] ✅ CIBLAGE ACTIVÉ - carte en standby")
                            return -- Sortir early, carte gérée par le système standby
                        else
                            print("[interaction.lua] ❌ Échec démarrage sélection cible")
                            -- En cas d'échec, remettre la carte en main si elle était en standby
                            if CardStandbyPlay and CardStandbyPlay.hasCardInStandby() then
                                CardStandbyPlay.returnCardToHand()
                            end
                            -- Fallback sur ancien système en cas d'échec
                            local Card = rawget(_G, "Card")
                            local ok = Card and Card.Play and Card.Play.tryPlay and Card.Play.tryPlay(_card, false)
                            if not ok then
                                _card._targetPos.x, _card._targetPos.y = bx, by
                                _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
                            end
                        end
                    else
                        -- Mode traditionnel : jeu direct (1 seul ennemi ou pas de système de ciblage)
                        print("[interaction.lua] ❌ CONDITIONS NON REMPLIES - Jeu direct de carte (", aliveEnemies,
                            "ennemis vivants )")
                        print("[DEBUG] Raison: actorTag=", _card.actorTag, "CardTargetSelection=",
                            CardTargetSelection ~= nil, "aliveEnemies=", aliveEnemies)
                        local Card = rawget(_G, "Card")
                        local ok = Card and Card.Play and Card.Play.tryPlay and Card.Play.tryPlay(_card, false)
                        if not ok then
                            _card._targetPos.x, _card._targetPos.y = bx, by
                            _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
                        end
                    end
                    -- ===== FIN NOUVEAU SYSTÈME DE CIBLAGE =====
                else
                    -- ❌ CARTE HORS ZONE DE JEU - RETOUR EN MAIN
                    _logf("[Card.Interaction] ❌ CARTE HORS ZONE - Retour en main: %s", _card.name or "carte")
                    _card._targetPos.x, _card._targetPos.y = bx, by
                    _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
                end
            end
        else
            -- 🏠 CARTES NORMALES (ni draggées, ni actives)
            if active and _card == active then
                -- 👆 CARTE SURVOLÉE (hover effect)
                _card._targetPos.x = bx
                _card._targetPos.y = by - 100
                _card._targetScale.x, _card._targetScale.y = 0.95, 0.95
                if isDown and not mouseWasDown and not draggedCard then
                    -- 🎯 DÉBUT DU DRAG
                    _logf("[Card.Interaction] 🎯 DÉBUT DRAG carte: %s", _card.name or "carte")
                    draggedCard, draggedIndex = _card, i
                    Common.__dragLock = true
                    local gx, gy = _getCursor()
                    _card._grabDX = gx - _card.vector2.x
                    _card._grabDY = gy - _card.vector2.y
                    if i ~= #Common.hand.cards then Layout.bringToFront(i) end
                    if DEBUG then
                        _logf("[Card.Interaction] start drag %s %s grabDX=%s grabDY=%s", tostring(i),
                            tostring(_card.name), tostring(_card._grabDX), tostring(_card._grabDY))
                    end
                end
            else
                -- 🏠 CARTE EN POSITION DE BASE
                _card._targetPos.x, _card._targetPos.y = bx, by
                _card._targetScale.x, _card._targetScale.y = Common.SCALE_BASE, Common.SCALE_BASE
            end
        end

        -- ⚠️  ANIMATION LERP - PEUT CAUSER LE RETOUR DES CARTES ⚠️
        -- Cette section anime les cartes vers leur position cible
        -- Vérification supplémentaire pour cartes en standby
        local CardStandbyPlay = rawget(_G, "CardStandbyPlay")
        local isCardInStandbyForLerp = CardStandbyPlay and CardStandbyPlay.hasCardInStandby() and
            CardStandbyPlay.standbyCard == _card

        if _card ~= draggedCard and not _card._playing and not _card.locked and not _card.anim and not isCardInStandbyForLerp then
            if _card._playing then
                _logf("[Card.Interaction] 🚫 LERP BLOQUÉ pour carte en jeu: %s", _card.name or "carte")
            else
                -- Animation normale vers position cible
                _lerpTable(_card.vector2, _card._targetPos, 10)
                _lerpTable(_card.scale, _card._targetScale, 12)
            end
        elseif isCardInStandbyForLerp then
            -- LERP bloqué pour carte en standby (pas de log pour éviter spam)
        end
    end

    mouseWasDown = isDown
    if DEBUG and not isDown and draggedCard == nil then
        _logf("[Card.Interaction] 🔄 CYCLE TERMINÉ - mouse up, no draggedCard")
    end
end

M.disableDrag = function()
    -- TODO NOT IMPLEMENTED
    globalFunction.log.warn("[Card.Interaction] ⚠️  disableDrag() NOT IMPLEMENTED")
end
M.enableDrag = function(card, index)
    -- TODO NOT IMPLEMENTED
    globalFunction.log.warn("[Card.Interaction] ⚠️  enableDrag() NOT IMPLEMENTED")
end

return M
