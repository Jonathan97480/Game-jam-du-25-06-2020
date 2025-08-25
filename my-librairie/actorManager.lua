-- my-librairie/actorManager.lua

-- Module + alias public (compat)
local actor = {}
local actorManager = actor -- alias retourné par require
-- Alias global de compat au cas où certains scripts utilisent _G.actorManager directement
rawset(_G, "actorManager", actor)

----------------------------------------------------------------------
-- Crée un acteur
----------------------------------------------------------------------
function actor.create(p_name, p_animation, p_vector2)
    local newActor           = {}

    newActor.name            = p_name or ""
    newActor.nameDeck        = ""
    newActor.vector2         = { x = (p_vector2 and p_vector2.x) or 0, y = (p_vector2 and p_vector2.y) or 0 }

    newActor.animation       = { isPlay = false }
    newActor.curentAnimation = 'idle'

    newActor.width           = 0
    newActor.height          = 0

    newActor.state           = {
        life           = 80,
        maxLife        = 80,
        power          = 8,
        powerMax       = 8,
        degat          = 0,
        shield         = 0,
        dead           = false,
        epine          = 0,
        chancePassTour = 0,
    }

    newActor.sound           = { sfx = {}, music = {} }

    actor.addAnimation(newActor.animation, p_animation or {})
    actor.get.size(newActor)
    actor.ensureStateDefaults(newActor) -- normalise les nombres

    return newActor
end

actor.get, actor.set = {}, {}

----------------------------------------------------------------------
-- Taille depuis la première frame dispo
----------------------------------------------------------------------
function actor.get.size(p_actor)
    if not p_actor or not p_actor.animation then return end
    for _, frames in pairs(p_actor.animation) do
        if type(frames) == "table" and frames[1] and frames[1].getDimensions then
            p_actor.width, p_actor.height = frames[1]:getDimensions()
            return
        end
    end
end

----------------------------------------------------------------------
-- Ajout d’animations depuis des chemins
----------------------------------------------------------------------
function actor.addAnimation(p_animTable, p_animation)
    if type(p_animTable) ~= "table" or type(p_animation) ~= "table" then return end
    for state, paths in pairs(p_animation) do
        p_animTable[state] = {}
        for _, path in ipairs(paths) do
            local ok, img = pcall(love.graphics.newImage, path)
            if ok and img then table.insert(p_animTable[state], img) end
        end
    end
end

----------------------------------------------------------------------
-- Suppression d’animations
----------------------------------------------------------------------
function actor.removeAnimation(p_animTable, p_animation)
    if type(p_animTable) ~= "table" or type(p_animation) ~= "table" then return end
    for state, flag in pairs(p_animation) do
        if flag and p_animTable[state] then p_animTable[state] = nil end
    end
end

----------------------------------------------------------------------
-- Bascule d’animation
----------------------------------------------------------------------
function actor.playAnimation(p_actor, p_animation)
    if not p_actor or not p_actor.animation then return end
    if p_actor.animation[p_animation] then
        p_actor.animation.isPlay = true
        p_actor.curentAnimation  = p_animation
    end
end

----------------------------------------------------------------------
-- Outils d’état (normalisation + power)
----------------------------------------------------------------------
function actor.ensureStateDefaults(p_actor)
    if not p_actor or not p_actor.state then return end
    local st   = p_actor.state
    st.life    = tonumber(st.life) or 0
    st.maxLife = tonumber(st.maxLife) or st.life or 0
    if st.maxLife <= 0 then st.maxLife = 1 end
    st.life     = math.max(0, math.min(st.life, st.maxLife))
    st.power    = tonumber(st.power) or 0
    st.powerMax = tonumber(st.powerMax) or st.power or 0
    if st.powerMax < 0 then st.powerMax = 0 end
    st.power          = math.max(0, math.min(st.power, st.powerMax))
    st.degat          = tonumber(st.degat) or 0
    st.shield         = tonumber(st.shield) or 0
    st.epine          = tonumber(st.epine) or 0
    st.chancePassTour = tonumber(st.chancePassTour) or 0
    st.dead           = not not st.dead
end

function actor.canAfford(p_actor, cost)
    if not p_actor or not p_actor.state then return false end
    local c = math.max(0, tonumber(cost) or 0)
    return (p_actor.state.power or 0) >= c
end

function actor.consumePower(p_actor, cost)
    if not p_actor or not p_actor.state then return 0 end
    local c = math.max(0, tonumber(cost) or 0)
    local p = tonumber(p_actor.state.power) or 0
    local used = math.min(p, c)
    p_actor.state.power = p - used
    return used
end

----------------------------------------------------------------------
-- Effets simples
-- kind: "damage" | "heal" | "shield" | "epine" | "thorns" | "skip"
----------------------------------------------------------------------
function actor.applyEffect(target, kind, value, opts)
    if not target or type(target) ~= "table" or not target.state then return end
    kind = tostring(kind or ""):lower()
    local v = tonumber(value or 0) or 0
    local st = target.state

    -- S’assure que l’état est sain
    actor.ensureStateDefaults(target)

    if kind == "damage" then
        local remain = math.max(0, v)
        local shield = st.shield or 0
        if shield > 0 and remain > 0 then
            local absorb = math.min(shield, remain)
            st.shield = shield - absorb
            remain = remain - absorb
        end
        if remain > 0 then
            st.life = math.max(0, (st.life or 0) - remain)
            if st.life <= 0 then st.dead = true end
        end
    elseif kind == "heal" then
        local maxLife = st.maxLife or st.life or 0
        if maxLife < 0 then maxLife = 0 end
        st.life = math.min(maxLife, (st.life or 0) + math.abs(v))
    elseif kind == "shield" then
        st.shield = (st.shield or 0) + math.abs(v)
    elseif kind == "epine" or kind == "thorns" then
        st.epine = (st.epine or 0) + math.abs(v)
    elseif kind == "skip" then
        local nv = math.max(0, math.min(100, math.abs(v)))
        st.chancePassTour = math.max(0, math.min(100, (st.chancePassTour or 0) + nv))
    end
end

return actor
