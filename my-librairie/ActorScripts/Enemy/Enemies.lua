-- my-librairie/ActorScripts/Enemy/Enemies.lua
local Enemies    = {
    curentEnemy  = nil,
    listeEnemies = {}
}

local actor      = require("my-librairie/actorManager")
local myFonction = rawget(_G, "myFonction") or require("my-librairie/myFunction")


-- Sécurise l'état d'un ennemi (toujours un state table numérisé)
local function ensureEnemyState(e)
    if type(e) ~= "table" then return nil end
    e.state   = (type(e.state) == "table") and e.state or {}

    local s   = e.state
    s.life    = tonumber(s.life) or math.random(50, 81)
    s.maxLife = tonumber(s.maxLife) or s.life
    s.maxLife = 8
    if s.maxLife <= 0 then s.maxLife = 1 end
    s.life     = math.max(0, math.min(s.life, s.maxLife))

    s.shield   = tonumber(s.shield) or 0
    s.epine    = tonumber(s.epine) or 0
    s.degat    = tonumber(s.degat) or 0
    s.powerMax = tonumber(s.powerMax) or 8
    s.power    = tonumber(s.power) or s.powerMax
    s.dead     = (s.dead == true)

    -- positions/tailles minimales (au cas où l’actor ne les a pas)
    e.vector2  = e.vector2 or { x = 1261, y = 400 }
    e.width    = e.width or 337
    e.height   = e.height or 462

    return e
end

-- LOAD : crée 4 ennemis, prend 1 au hasard comme courant
function Enemies.load()
    Enemies.listeEnemies = {}
    Enemies.curentEnemy  = nil

    for i = 1, 4 do
        local E = actor.create('Enemy-' .. i, {
            idle = { 'img/Actor/Enemy/Enemy-' .. i .. '.png' }
        }, { x = 1261, y = 400 })

        ensureEnemyState(E)
        table.insert(Enemies.listeEnemies, E)
    end

    local idx = math.random(1, #Enemies.listeEnemies)
    Enemies.curentEnemy = Enemies.listeEnemies[idx]
    table.remove(Enemies.listeEnemies, idx)
    ensureEnemyState(Enemies.curentEnemy)
end

-- NEXT : passe à l’ennemi suivant (le Transition Manager gère le flow global)
function Enemies.next()
    Enemies.curentEnemy = nil
    if #Enemies.listeEnemies > 0 then
        local idx = #Enemies.listeEnemies
        Enemies.curentEnemy = Enemies.listeEnemies[idx]
        table.remove(Enemies.listeEnemies, idx)
        ensureEnemyState(Enemies.curentEnemy)
    else
        -- Plus d’ennemis : laisse le Transition Manager enclencher la suite (récompense / fin)
        -- (Ne change pas Tour ici, ne pioche pas)
    end
end

-- UPDATE : l’IA est gérée par my-librairie/ai/controller.lua
function Enemies.update(dt)
    -- éventuellement : animations propres aux ennemis si besoin
end

-- DRAW : dessine l’ennemi courant + sa barre de vie
function Enemies.draw()
    local e = ensureEnemyState(Enemies.curentEnemy)
    if not e then return end

    -- animation (idle par défaut)
    local animName = e.curentAnimation or "idle"
    if e.animation and e.animation[animName] then
        local animation = e.animation[animName]
        for i = 1, #animation do
            love.graphics.draw(animation[i], e.vector2.x, e.vector2.y)
        end
    end

    if myFonction and myFonction.drawLifeBarStatus then
        myFonction.drawLifeBarStatus(e, 'red')
    end
end

return Enemies
