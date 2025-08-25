-- globalFunction.lua (renamed from myFunction.lua)
-- Provides utility functions previously exported as myFunction.
local globalFunction = {}
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
globalFunction.lerp = function(a, b, t)
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

globalFunction.mouse = {}

--[[ Hover robuste: gère scale nil / partiel ]]
globalFunction.mouse.hover = function(x, y, width, height, scale)
    local sx, sy = 1, 1
    if type(scale) == "table" then
        sx = scale.x or scale[1] or 1
        sy = scale.y or scale[2] or 1
    end
    local function _getCursor()
        local okc, cursor = pcall(require, "my-librairie/cursor")
        if okc and cursor and cursor.get then return cursor.get() end
        return 0, 0
    end
    local mx, my = _getCursor()
    return (mx >= x and mx <= x + width * sx and my >= y and my <= y + height * sy)
end

--[[ Click «front edge» compatible avec l'existant ]]
globalFunction.mouse.click = function()
    local down = false
    local okInp, inp = pcall(require, "my-librairie/inputManager")
    if okInp and inp and inp.state then
        local s = inp.state(); down = (s == 'pressed' or s == 'held')
    else
        local okI, iface = pcall(require, "my-librairie/inputInterface")
        if okI and iface and iface.isActionDown then
            down = iface.isActionDown()
        else
            -- no provider available: default to false
            down = false
        end
    end
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
globalFunction.mouse.state = function()
    local down = false
    local okInp, inp = pcall(require, "my-librairie/inputManager")
    if okInp and inp and inp.state then
        local s = inp.state()
        if s == 'pressed' or s == 'held' then down = true end
    else
        local okI, iface = pcall(require, "my-librairie/inputInterface")
        if okI and iface and iface.isActionDown then
            down = iface.isActionDown()
        else
            down = false
        end
    end
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
globalFunction.mouse.justPressed = function()
    local s = globalFunction.mouse.state()
    return s == "pressed"
end

--[[
    Just released mouse button (front-edge)
    Renvoie true uniquement lors de la première relâche
]]
globalFunction.mouse.justReleased = function()
    local s = globalFunction.mouse.state()
    return s == "released"
end

--[[ End Turn hotkeys
    E ou Return ou Space pendant le tour joueur.
]]
globalFunction.endTurnHotkeys = function()
    if _G.Tour ~= 'player' then return end
    if love.keyboard.isDown('e') or love.keyboard.isDown('return') or love.keyboard.isDown('space') then
        if Transition and Transition.requestEndTurn then
            Transition.requestEndTurn()
        end
    end
end

--[[ Draw Life bar status ]]
function globalFunction.drawLifeBarStatus(p_actor, p_Colorbar)
    if type(p_actor) ~= 'table' or type(p_actor.state) ~= 'table' then return end
    local maxLife = tonumber(p_actor.state.maxLife) or 1
    if maxLife <= 0 then maxLife = 1 end
    local life     = math.max(0, math.min(tonumber(p_actor.state.life) or 0, maxLife))

    local color    = lifeBar.color_red
    local colorBar = 'red'
    if p_Colorbar == "bleu" then
        colorBar = p_Colorbar
        color = lifeBar.color_bleu
    end

    local vx = (p_actor.vector2 and p_actor.vector2.x) or 0
    local vy = (p_actor.vector2 and p_actor.vector2.y) or 0
    local w = p_actor.width or 0
    local h = p_actor.height or 0

    local position = {
        x = vx + ((w / 2) - (maxLife / 0.5)),
        y = vy + h - 88
    }

    love.graphics.setColor(color)
    love.graphics.rectangle('fill', position.x, position.y + 4, 336 * (life / maxLife), 10)
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(lifeBar[colorBar], position.x, position.y, 0, 1.5, 2)

    love.graphics.print(
        life .. '/' .. maxLife,
        vx + (w / 1.8),
        vy + (h - 8)
    )

    drawBonus(p_actor, color, position)
end

--[[ Draw bonus (shield, épine, bonus-attack) ]]
function drawBonus(p_actor, color, position)
    if not (p_actor and p_actor.state) then return end
    -- Shield icon
    if (p_actor.state.shield or 0) > 0 then
        love.graphics.draw(shield, position.x - 30, position.y - 20, 0, 1.5, 1.5)
        local oldFont = love.graphics.getFont()
        local f40 = love.graphics.newFont(40)
        love.graphics.setFont(f40)
        love.graphics.print(p_actor.state.shield, position.x - 12, position.y - 10)
        love.graphics.setFont(oldFont)
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
local function _table_clone(orig, seen)
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
        copy[_table_clone(k, seen)] = _table_clone(v, seen)
    end

    return setmetatable(copy, getmetatable(orig))
end

-- Expose clone via module
globalFunction.clone = _table_clone

-- Ensure legacy code using table.clone still works: provide a safe fallback
if type(table) == 'table' and type(table.clone) ~= 'function' then
    table.clone = _table_clone
end

-- Try to load centralized input manager and delegate mouse helpers to it.
local ok, input = pcall(require, "my-librairie/inputManager")
if ok and type(input) == 'table' then
    globalFunction.mouse = globalFunction.mouse or {}
    globalFunction.mouse.hover = input.hover
    globalFunction.mouse.click = input.click
    globalFunction.mouse.state = input.state
    globalFunction.mouse.justPressed = input.justPressed
    globalFunction.mouse.justReleased = input.justReleased
    globalFunction.endTurnHotkeys = input.endTurnHotkeys
end

-- Aliases globaux pour compat (certains scripts utilisent "myFonction")
rawset(_G, "globalFunction", globalFunction)
rawset(_G, "myFunction", globalFunction)
rawset(_G, "myFonction", globalFunction)

-- ============================
-- Centralized logging utility
-- ============================
globalFunction.log = {}

-- config
globalFunction.log.maxEntries = 200
globalFunction.log.show = false -- toggle on/off
globalFunction.log.entries = {} -- circular buffer

local LEVEL = { OK = 0, INFO = 1, WARN = 2, ERROR = 3 }
local LEVEL_NAME = { [0] = "OK", [1] = "INFO", [2] = "WARN", [3] = "ERROR" }
local LEVEL_COLOR = {
    [0] = { 1, 1, 1 },       -- OK = white
    [1] = { 0.6, 0.9, 0.6 }, -- INFO = greenish
    [2] = { 1, 0.65, 0 },    -- WARN = orange
    [3] = { 1, 0.2, 0.2 }    -- ERROR = red
}

local function _pushLog(level, text)
    local info = debug.getinfo(3, "nSl") or {}
    local src = tostring(info.short_src or info.source or "?")
    local func = tostring(info.name or "?")
    local entry = { t = os.time(), level = level, text = tostring(text), src = src, func = func }
    table.insert(globalFunction.log.entries, entry)
    -- trim
    if #globalFunction.log.entries > globalFunction.log.maxEntries then
        table.remove(globalFunction.log.entries, 1)
    end
    -- also print to console for convenience
    local prefix = string.format("[%s][%s:%s] ", LEVEL_NAME[level], src, func)
    if level == LEVEL.ERROR then
        print(prefix .. "ERROR: " .. tostring(text))
    else
        print(prefix .. tostring(text))
    end
end

function globalFunction.log.ok(text) _pushLog(LEVEL.OK, text) end

function globalFunction.log.info(text) _pushLog(LEVEL.INFO, text) end

function globalFunction.log.warn(text) _pushLog(LEVEL.WARN, text) end

function globalFunction.log.error(text) _pushLog(LEVEL.ERROR, text) end

function globalFunction.log.clear() globalFunction.log.entries = {} end

function globalFunction.log.toggle() globalFunction.log.show = not globalFunction.log.show end

-- Draw logs on screen (call from love.draw when desired)
function globalFunction.drawLogs(opts)
    opts = opts or {}
    if not globalFunction.log.show then return end

    -- prefer game-space resolution when available (makes the panel readable)
    local screen = rawget(_G, 'screen')
    local gw = (screen and screen.gameReso and screen.gameReso.width) or 800
    local gh = (screen and screen.gameReso and screen.gameReso.height) or 600

    local x = opts.x or 10
    local y = opts.y or 40
    local w = opts.w or (gw - 20)
    local h = opts.h or math.min(300, gh - y - 20)
    local bg = opts.bg or { 0, 0, 0, 0.6 }

    love.graphics.push()
    -- background
    love.graphics.setColor(bg)
    love.graphics.rectangle("fill", x - 6, y - 6, w + 12, h + 12)
    love.graphics.setColor(1, 1, 1)

    -- cached font for logs (avoid re-creating every frame)
    globalFunction._logFont = globalFunction._logFont or love.graphics.newFont(16)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(globalFunction._logFont)

    local lineH = opts.lineHeight or globalFunction._logFont:getHeight()
    local maxLines = math.floor(h / lineH)
    local start = math.max(1, #globalFunction.log.entries - maxLines + 1)
    local idx = 0
    for i = start, #globalFunction.log.entries do
        idx = idx + 1
        local e = globalFunction.log.entries[i]
        local col = LEVEL_COLOR[e.level] or { 1, 1, 1 }
        love.graphics.setColor(col)
        local timestr = os.date('%H:%M:%S', e.t)
        local text = string.format("%s [%s:%s] %s", timestr, e.src, e.func, e.text)
        love.graphics.print(text, x, y + (idx - 1) * lineH)
    end

    love.graphics.setFont(oldFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end

-- Export logs to a file (returns true on success)
function globalFunction.log.exportToFile(path)
    -- ensure target directory exists
    local dir = "gameLogs"
    pcall(function()
        if type(love) == 'table' and love.filesystem and type(love.filesystem.createDirectory) == 'function' then
            love.filesystem.createDirectory(dir)
        end
    end)

    path = path or (dir .. "/" .. "game_logs_" .. os.date("%Y%m%d_%H%M%S") .. ".log")

    -- try normal io.open first
    local ok, f = pcall(function() return io.open(path, "w") end)
    if not ok or not f then
        -- fallback to love.filesystem.write when available (useful in sandboxed runtimes)
        if type(love) == 'table' and love.filesystem and type(love.filesystem.write) == 'function' then
            local content = {}
            for i = 1, #globalFunction.log.entries do
                local e = globalFunction.log.entries[i]
                local timestr = os.date('%Y-%m-%d %H:%M:%S', e.t)
                local line = string.format("%s [%s] [%s:%s] %s\n", timestr, LEVEL_NAME[e.level], e.src, e.func, e.text)
                content[#content + 1] = line
            end
            local joined = table.concat(content)
            local succ, serr = pcall(function() love.filesystem.write(path, joined) end)
            if succ then
                print("[LOG] exported " .. tostring(#globalFunction.log.entries) .. " entries to " .. tostring(path))
                return true
            else
                print("[LOG] cannot write to file via love.filesystem: " .. tostring(serr))
                return false
            end
        end
        print("[LOG] cannot open file for writing: " .. tostring(path))
        return false
    end

    for i = 1, #globalFunction.log.entries do
        local e = globalFunction.log.entries[i]
        local timestr = os.date('%Y-%m-%d %H:%M:%S', e.t)
        local line = string.format("%s [%s] [%s:%s] %s\n", timestr, LEVEL_NAME[e.level], e.src, e.func, e.text)
        f:write(line)
    end
    f:close()
    print("[LOG] exported " .. tostring(#globalFunction.log.entries) .. " entries to " .. tostring(path))
    return true
end

-- auto init log entry
globalFunction.log.info("Logger initialized")

return globalFunction
