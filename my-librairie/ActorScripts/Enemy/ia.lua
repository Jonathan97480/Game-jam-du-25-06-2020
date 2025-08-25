-- my-librairie/ActorScripts/Enemy/ia.lua
local ia = {}

-- Helpers sûrs
local function num(x, d) return tonumber(x) or d end
local function rndi(a, b)
    if love and love.math and love.math.random then return love.math.random(a, b) end
    return math.random(a, b)
end
local function rnd01()
    if love and love.math and love.math.random then return love.math.random() end
    return math.random()
end

-- Overlay / états qui bloquent l'IA
local function overlayBloque()
    if not rawget(_G, "Transition") then return false end
    local S = Transition.state
    return S == "victory_check"
        or S == "reward_choice"
        or S == "advance_enemy"
        or S == "game_over"
        or S == "deal_start_hand"
        or S == "initiative_flip"
        or S == "announce_initiative"
end

-- Applique des dégâts à l'ennemi (valeurs sûres + FX optionnel)
local function appliqueDegatToEnemy(val)
    local e = Enemies and Enemies.curentEnemy
    if not (e and e.state) then return end
    local dmg = num(val, 0)

    local shield = num(e.state.shield, 0)
    if shield >= dmg then
        e.state.shield = shield - dmg
        dmg = 0
    else
        dmg = dmg - shield
        e.state.shield = 0
    end

    -- petit FX facultatif
    if effect and effect.play then
        pcall(effect.play, {
            name = 'attack',
            vector2 = {
                x = e.vector2 and e.vector2.x or 0,
                y = (e.vector2 and e.vector2.y or 0) + (num(e.height, 0) / 2) - 40
            }
        })
    end

    e.state.life    = num(e.state.life, 0) - dmg
    e.state.maxLife = num(e.state.maxLife, math.max(1, num(e.state.life, 0)))
    if e.state.life <= 0 then
        e.state.life = 0
        e.state.dead = true
    end
end

-- Fin de tour IA propre
local function finDeTourIA()
    if rawget(_G, "Transition") and Transition.requestEndTurn then
        Transition.requestEndTurn()
    else
        -- fallback ultra simple si pas de Transition
        _G.Tour = 'player'
    end
end

-- ====== TOUR IA ======
function ia.playTour(dt)
    -- Normalisation dt
    local Delta = num(dt, num(rawget(_G, "Delta"), 0.016))

    -- Conditions minimales pour jouer
    if overlayBloque() then return end
    if _G.Tour ~= 'Enemy' then return end
    if not rawget(_G, "Transition") or Transition.state ~= "enemy_turn" then return end

    local e = Enemies and Enemies.curentEnemy
    local h = Hero and Hero.actor
    if not (e and e.state and h and h.state) then return end

    -- Securiser états chiffrés
    e.state.life    = num(e.state.life, 0)
    e.state.maxLife = num(e.state.maxLife, math.max(1, e.state.life))
    e.state.shield  = num(e.state.shield, 0)
    e.state.dead    = not not e.state.dead

    h.state.life    = num(h.state.life, 0)
    h.state.maxLife = num(h.state.maxLife, math.max(1, h.state.life))
    h.state.shield  = num(h.state.shield, 0)
    h.state.epine   = num(h.state.epine, 0)

    -- Si l'ennemi est mort, laisser Transition gérer (on sort)
    if e.state.dead or e.state.life <= 0 then return end

    -- Timers IA (défauts)
    Enemies.timerDefautl = num(Enemies.timerDefautl, 1.25) -- intervalle entre deux actions
    Enemies.timerAttack  = num(Enemies.timerAttack, Enemies.timerDefautl)
    if type(Enemies.isAttack) ~= "boolean" then Enemies.isAttack = false end

    -- 1) Si on est en mode "préparation d'attaque", exécuter l'action
    if Enemies.isAttack then
        -- a) Chance de passer le tour
        local passChance = num(e.state.chancePassTour, 0)
        if passChance > 0 then
            local roll = rndi(20, 100)
            if roll < passChance then
                e.state.chancePassTour = 0
                Enemies.isAttack = false
                return finDeTourIA()
            end
        end

        -- b) Chance de se donner du shield
        local shieldRoll = rndi(1, 10)
        if shieldRoll > 2 and shieldRoll <= 4 then
            e.state.shield = num(e.state.shield, 0) + rndi(10, 30)
            Enemies.isAttack = false
            return finDeTourIA()
        end

        -- c) Attaque
        local degat = rndi(20, 30)

        -- Réaction épines du héros
        if h.state.epine > 0 then
            local ret = num(h.state.shield, 0) * (h.state.epine / 100)
            appliqueDegatToEnemy(ret)

            -- Mort de l'ennemi sur épines → reward
            if e.state.life <= 0 or e.state.dead then
                h.state.epine = 0
                if Transition and Transition.onEnemyDied then
                    Transition.onEnemyDied()
                end
                Enemies.isAttack = false
                return
            end
            -- reset épines après riposte
            h.state.epine = 0
        end

        -- Absorption par le bouclier du héros
        if h.state.shield >= degat then
            h.state.shield = h.state.shield - degat
            degat = 0
        else
            degat = degat - h.state.shield
            h.state.shield = 0
        end

        -- FX d'attaque (optionnel)
        if effect and effect.play then
            pcall(effect.play, {
                name = 'attack',
                vector2 = {
                    x = h.vector2 and h.vector2.x or 0,
                    y = (h.vector2 and h.vector2.y or 0) + (num(h.height, 0) / 2) - 40
                }
            })
        end

        -- Appliquer dégâts au héros
        h.state.life = h.state.life - degat
        if h.state.life <= 0 then
            h.state.life = 0
            h.state.dead = true
            -- Laisser la Transition afficher le Game Over
            if Transition and Transition.onHeroDied then
                Transition.onHeroDied()
            else
                _G.Tour = 'transition'
            end
            Enemies.isAttack = false
            return
        end

        -- Fin d'action : fin de tour IA
        Enemies.isAttack = false
        return finDeTourIA()
    end

    -- 2) Sinon, on décompte le timer avant la prochaine action
    if Enemies.timerAttack <= 0 then
        Enemies.timerAttack = Enemies.timerDefautl
        Enemies.isAttack    = true
        -- On prépare l'action, elle sera exécutée à la prochaine frame
        return
    else
        Enemies.timerAttack = Enemies.timerAttack - Delta
    end
end

return ia
