-- my-librairie/ActorScripts/Enemy/Enemies.lua
local Enemies = {
    curentEnemy  = nil,
    listeEnemies = {}
}
local actor   = actor or require("my-librairie.managers.actorManager")

-- Backwards-compatible Enemy factory registry (singleton)
local Enemy   = rawget(_G, "__ENEMY_SINGLETON__") or {}
local IA      = nil
local function getIA()
    if IA then return IA end
    pcall(function() IA = require("my-librairie/ActorScripts/Enemy/ia") end)
    return IA
end


-- Création d'un ennemi avec configuration explicite
function Enemies.create(_spawnData)
    -- Données de l'ennemi à partir des paramètres de spawn
    local enemyData = _spawnData.enemyData or {}

    -- Position de spawn de l'ennemi
    local enemySpawnPosition = {
        x = _spawnData.x or 0,
        y = _spawnData.y or 0
    }

    -- Création de l'entité ennemi avec les paramètres fournis
    local enemyEntity = actor.create(
        enemyData.name or "",
        enemyData.animation,
        {
            x = enemySpawnPosition.x or 0,
            y = enemySpawnPosition.y or 0
        }
    )

    -- Configuration de la barre de vie de l'ennemi
    enemyEntity.lifeBarConfig = {
        x = (enemyEntity.vector2 and enemyEntity.vector2.x) or 0,
        y = (enemyEntity.vector2 and enemyEntity.vector2.y) - 50 or 0,
        w = 150,
        h = 25,
        position = {
            x = ((enemyEntity.vector2 and enemyEntity.vector2.x) + (enemyEntity.width / 2)) - (150 / 2) or 0,
            y = (enemyEntity.vector2 and enemyEntity.vector2.y) - 50 or 0
        },
        size = {
            w = 150,
            h = 25
        }
    }

    -- Attributs supplémentaires de l'ennemi
    enemyEntity.cards = enemyData.cards or {}
    enemyEntity.nameDeck = enemyData.deckName or "Deck de l'ennemi inconnu"
    enemyEntity.deck = Card and Card.createDeck(enemyEntity.nameDeck) or {}
    Card.loadCards(enemyEntity.cards, enemyEntity.name, enemyEntity.nameDeck)

    enemyEntity.type = enemyData.type or "Type inconnu"

    -- Initialisation de l'état de vie de l'ennemi
    enemyEntity.state = enemyEntity.state or {
        life = 12,
        maxLife = 12
    }

    -- Initialisation du système d'IA de l'ennemi
    local iaSystem = getIA()
    enemyEntity.ai = iaSystem and iaSystem.new and iaSystem.new(enemyEntity) or nil

    return enemyEntity
end

rawset(_G, "__ENEMY_SINGLETON__", Enemies)

-- actorManager is resolved lazily inside load() to avoid circular require
local actor = nil

local globalFunction = nil
local function getGlobalFunction()
    if globalFunction then return globalFunction end
    pcall(function() globalFunction = require('my-librairie.globalFunction') end)
    return globalFunction
end


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

-- LOAD
function Enemies.load()

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
    for i = #Enemies.listeEnemies, 1, -1 do
        local e = Enemies.listeEnemies[i]
        if not e then return end

        -- Vérifier si cet ennemi est survolé pendant la sélection de cible
        local isHovered = false
        local CardTargetSelection = rawget(_G, "CardTargetSelection")
        if CardTargetSelection and CardTargetSelection.isSelectingTarget and CardTargetSelection.hoveredEnemy == e then
            isHovered = true
        end

        -- Dessiner effet de survol (contour vert)
        if isHovered then
            love.graphics.setColor(0, 1, 0, 0.8) -- Vert semi-transparent
            love.graphics.setLineWidth(4)
            love.graphics.rectangle("line", e.vector2.x - 5, e.vector2.y - 5, e.width + 10, e.height + 10)
            love.graphics.setColor(1, 1, 1, 1) -- Restaurer couleur blanche
            love.graphics.setLineWidth(1)
        end

        -- animation (idle par défaut)
        local animName = e.curentAnimation or "idle"
        if e.animation and e.animation[animName] then
            local animation = e.animation[animName]
            for i = 1, #animation do
                love.graphics.draw(animation[i], e.vector2.x, e.vector2.y)
            end
        end

        -- Dessiner un overlay de selection si ennemi survolé
        if isHovered then
            love.graphics.setColor(0, 1, 0, 0.2) -- Overlay vert très transparent
            love.graphics.rectangle("fill", e.vector2.x, e.vector2.y, e.width, e.height)
            love.graphics.setColor(1, 1, 1, 1)   -- Restaurer couleur
        end

        local gf = getGlobalFunction()
        if type(gf) == "table" and type(gf.drawLifeBarStatus) == "function" then
            pcall(function()
                gf.drawLifeBarStatus(e, 'red')
            end)
        end
    end
end

return Enemies
