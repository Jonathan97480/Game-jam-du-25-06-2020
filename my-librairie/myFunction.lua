-- myFunction.lua
local myFunction = {}
local lockClick = false

--[[ Icon Bare status load  ]]
local shield = love.graphics.newImage('img/Actor/Enemy/Hub-Shield2.png')
local epineIcon = love.graphics.newImage('img/icon/bonus-epine-icon.png')
local bonussAttackIcon = love.graphics.newImage('img/icon/bonuss-attack-icon.png')

local lifeBar = {
    red = love.graphics.newImage('img/Actor/Enemy/HudLifeEnemy.png'),
    bleu = love.graphics.newImage('img/Actor/hero/HudLifeHero.png'),
    color_red = { 1, 0, 0 },
    color_bleu = { 0, 0, 1 }
}

----------------------------------------------------------------
-- LERP STABLE (corrige les tremblements / oscillations)
-- a, b: tables {x, y}
-- t: «vitesse» (ex: 10). On le multiplie par Delta (dt global) si dispo
----------------------------------------------------------------
myFunction.lerp = function(a, b, t)
    -- sécurité des tables
    a.x      = a.x or 0; a.y = a.y or 0
    b.x      = b.x or 0; b.y = b.y or 0

    local dt = (rawget(_G, "Delta") or 0.016)
    local k  = (t or 10) * dt
    if k > 1 then k = 1 end

    -- epsilon pour arrêter proprement sans jitter
    local EPS = 0.5
    local moved = false

    -- axe X
    local dx = b.x - a.x
    if math.abs(dx) <= EPS then
        if a.x ~= b.x then
            a.x = b.x; moved = true
        end
    else
        a.x = a.x + dx * k
        moved = true
    end

    -- axe Y
    local dy = b.y - a.y
    if math.abs(dy) <= EPS then
        if a.y ~= b.y then
            a.y = b.y; moved = true
        end
    else
        a.y = a.y + dy * k
        moved = true
    end

    return moved
end

myFunction.mouse = {}

--[[ Hover robuste: gère scale nil / partiel ]]
myFunction.mouse.hover = function(x, y, width, height, scale)
    local sx, sy = 1, 1
    if type(scale) == "table" then
        sx = scale.x or scale[1] or 1
        sy = scale.y or scale[2] or 1
    end
    local mx, my = screen.mouse.X, screen.mouse.Y
    return (mx >= x and mx <= x + width * sx and my >= y and my <= y + height * sy)
end

--[[ Click «front edge» compatible avec l'existant ]]
myFunction.mouse.click = function()
    local down = love.mouse.isDown(1)
    if down and lockClick == false then
        lockClick = true
        return true -- front-edge (press)
    elseif (not down) and lockClick == true then
        -- fin du clic : on relâche le verrou mais on ne renvoie RIEN
        lockClick = false
        return nil -- (évite de renvoyer false)
    end
    return nil
end

-- (Optionnel) États de clic si besoin plus tard (pressed/held/released/idle)
myFunction.mouse.state = function()
    local down = love.mouse.isDown(1)
    if down and not lockClick then
        lockClick = true
        return "pressed"
    elseif down and lockClick then
        return "held"
    elseif (not down) and lockClick then
        lockClick = false
        return "released"
    else
        return "idle"
    end
end
--[[
    Just pressed mouse button (front-edge)
    Renvoie true uniquement lors de la première pression
]]
myFunction.mouse.justPressed = function()
    local s = myFunction.mouse.state()
    return s == "pressed"
end

--[[
    Just released mouse button (front-edge)
    Renvoie true uniquement lors de la première relâche
]]
myFunction.mouse.justReleased = function()
    local s = myFunction.mouse.state()
    return s == "released"
end

--[[ End Turn hotkeys
    E ou Return ou Space pendant le tour joueur.
]]
myFunction.endTurnHotkeys = function()
    -- petits helpers clavier: on teste "front-edge" en se basant sur love.keyboard.isDown,
    -- ou, si tu as déjà love.keypressed ailleurs, tu peux appeler Transition.requestEndTurn() là-bas.
    -- Ici version simple: E ou Return ou Space pendant le tour joueur.
    if _G.Tour ~= 'player' then return end
    if love.keyboard.isDown('e') or love.keyboard.isDown('return') or love.keyboard.isDown('space') then
        if Transition and Transition.requestEndTurn then
            Transition.requestEndTurn()
        end
    end
end

--[[ Draw Life bar status ]]
function myFunction.drawLifeBarStatus(p_actor, p_Colorbar)
    local maxLife = tonumber(p_actor.state.maxLife) or 1
    if maxLife <= 0 then maxLife = 1 end
    local life     = math.max(0, math.min(tonumber(p_actor.state.life) or 0, maxLife))

    local color    = lifeBar.color_red
    local colorBar = 'red'
    if p_Colorbar == "bleu" then
        colorBar = p_Colorbar
        color = lifeBar.color_bleu
    end

    local position = {
        x = p_actor.vector2.x + ((p_actor.width / 2) - (maxLife / 0.5)),
        y = p_actor.vector2.y + p_actor.height - 88
    }

    love.graphics.setColor(color)
    love.graphics.rectangle('fill', position.x, position.y + 4, 336 * (life / maxLife), 10)
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(lifeBar[colorBar], position.x, position.y, 0, 1.5, 2)

    love.graphics.print(
        life .. '/' .. maxLife,
        p_actor.vector2.x + (p_actor.width / 1.8),
        p_actor.vector2.y + (p_actor.height - 8)
    )

    drawBonus(p_actor, color, position)
end

--[[ Draw bonus (shield, épine, bonus-attack) ]]
function drawBonus(p_actor, color, position)
    -- Shield icon
    if (p_actor.state.shield or 0) > 0 then
        love.graphics.draw(shield, position.x - 30, position.y - 20, 0, 1.5, 1.5)
        love.graphics.setNewFont(40)
        love.graphics.print(p_actor.state.shield, position.x - 12, position.y - 10)
        love.graphics.setNewFont(20)
    end
    -- Epine icon
    if (p_actor.state.epine or 0) > 0 then
        love.graphics.draw(epineIcon, position.x + 30, position.y + 20, 0, 1.5, 1.5)
    end
    -- Bonus attack icon
    if (p_actor.state.degat or 0) > 0 then
        love.graphics.draw(bonussAttackIcon, position.x + 80, position.y + 20, 0, 1.5, 1.5)
    end
end

--[[ Deep copy table (clone) ]
    Renvoie une copie profonde d'une table
    @param orig La table d'origine à copier
    @param seen Une table pour suivre les références circulaires (optionnelle)
    @return Une nouvelle table clonée
]]
table.clone = function(orig, seen)
    if type(orig) ~= "table" then
        return orig
    end
    if seen and seen[orig] then
        return seen[orig]
    end

    local copy = {}
    seen = seen or {}
    seen[orig] = copy

    for k, v in pairs(orig) do
        copy[table.clone(k, seen)] = table.clone(v, seen)
    end

    return setmetatable(copy, getmetatable(orig))
end

-- Aliases globaux pour compat (certains scripts utilisent "myFonction")
rawset(_G, "myFunction", myFunction)
rawset(_G, "myFonction", myFunction)

return myFunction
