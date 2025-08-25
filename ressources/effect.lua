-- my-librairie/effect/effects.lua
local res = require("res")


local effects  = {}

-- Definitions (frames & vitesse par défaut) et instances actives
effects.defs   = {}
effects.active = {}

-- Charge une séquence d’images 1..count à partir d’un préfixe
--[[
Fonction : addFrames
Rôle : Fonction « Add frames » liée à la logique du jeu.
Paramètres :
  - basePrefix : paramètre détecté automatiquement.
  - count : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
local function addFrames(basePrefix, count)
    local t = {}
    for i = 1, count do
        -- love.graphics.newImage peut échouer, on gère l’erreur
        local img = res.image(basePrefix .. i .. ".png")
        if img then
            t[i] = img
        else
            local gf = rawget(_G, 'globalFunction')
            local msg = "Erreur lors du chargement de l'image : " .. tostring(basePrefix .. i .. ".png")
            if gf and gf.log and gf.log.warn then gf.log.warn(msg) else print(msg) end
        end
    end
    return t
end

--[[

Fonction : effects.load

Rôle : Initialise les ressources et l'état.

Paramètres :

  - (aucun)

Retour : valeur calculée.

]]

function effects.load()
    if next(effects.defs) then return end -- déjà chargé

    effects.defs.attack = {
        frames = addFrames("img/effect/Attaque-base/frame-", 5),
        speed  = 0.10
    }
    effects.defs.heal = {
        frames = addFrames("img/effect/heal/bonuss-heal-", 4),
        speed  = 0.20
    }
    effects.defs.epine = {
        frames = addFrames("img/effect/epine/bonuss-epine-", 5),
        speed  = 0.10
    }
    effects.defs.bonusAttack = {
        frames = addFrames("img/effect/degat/bonuss-degat-", 5),
        speed  = 0.10
    }
end

-- Crée une instance d’effet à partir d’une déf.
--[[
Fonction : newInstance
Rôle : Fonction « New instance » liée à la logique du jeu.
Paramètres :
  - def : paramètre détecté automatiquement.
  - x : paramètre détecté automatiquement.
  - y : paramètre détecté automatiquement.
  - opts : paramètre détecté automatiquement.
Retour : valeur calculée.
]]
local function newInstance(def, x, y, opts)
    opts = opts or {}
    return {
        def   = def,
        frame = 1,
        time  = 0,
        speed = tonumber(opts.speed) or def.speed or 0.1,
        x     = tonumber(x) or 0,
        y     = tonumber(y) or 0,
        sx    = tonumber(opts.sx) or 1,
        sy    = tonumber(opts.sy) or 1,
        rot   = tonumber(opts.rot) or 0,
    }
end

-- Lance un effet :
--   effects.play("heal", x, y, {speed=0.2, sx=1.2, sy=1.2})
--   effects.play({ name="heal", vector2={x=..., y=...} })
--[[
Fonction : effects.play
Rôle : Fonction « Play » liée à la logique du jeu.
Paramètres :
  - arg : paramètre détecté automatiquement.
  - x : paramètre détecté automatiquement.
  - y : paramètre détecté automatiquement.
  - opts : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function effects.play(arg, x, y, opts)
    local name, px, py, o = nil, nil, nil, nil
    if type(arg) == "table" then
        name = arg.name
        if arg.vector2 then px, py = arg.vector2.x, arg.vector2.y end
        o = arg.opts or {}
    else
        name, px, py, o = arg, x, y, opts
    end
    if not name then return end
    local def = effects.defs[name]
    if not def then
        -- nom inconnu → on ignore proprement
        return
    end
    table.insert(effects.active, newInstance(def, px or 0, py or 0, o))
end

-- Mise à jour (dt obligatoire)
--[[
Fonction : effects.update
Rôle : Met à jour la logique à chaque frame.
Paramètres :
  - dt : paramètre détecté automatiquement.
Retour : valeur calculée.
]]
function effects.update(dt)
    if not dt then return end
    for i = #effects.active, 1, -1 do
        local e = effects.active[i]
        e.time = e.time + dt
        if e.time >= e.speed then
            e.time = e.time - e.speed
            e.frame = e.frame + 1
            if e.frame > #e.def.frames then
                -- fin → on retire l’instance
                table.remove(effects.active, i)
            end
        end
    end
end

--[[

Fonction : effects.draw

Rôle : Affiche le rendu à l'écran.

Paramètres :

  - (aucun)

Retour : aucune valeur (nil).

]]

function effects.draw()
    for _, e in ipairs(effects.active) do
        love.graphics.draw(e.def.frames[e.frame], e.x, e.y, e.rot, e.sx, e.sy)
    end
end

return effects
