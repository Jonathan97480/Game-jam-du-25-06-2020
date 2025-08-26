if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

-- ***********Config Window Game*************
love.window.setTitle("Tactique Cards")


-- REQUIRE System
json = require("my-librairie/json");
hud = require("my-librairie/hud/hud");
Card = require("my-librairie/card-librairie/card");
screen = require("my-librairie/responsive");
scene = require("my-librairie/sceneManager");
effect = require("ressources/effect");

-- input manager (unified mouse/gamepad helpers)
local okInput, inputManager = pcall(require, "my-librairie/inputManager")
if not okInput then inputManager = nil end

-- Robust loader for legacy myFunction/globalFunction utilities.
local function safeRequireAny(list)
  for _, name in ipairs(list) do
    local ok, mod = pcall(require, name)
    if ok and mod then return mod end
  end
  return nil
end

myFonction = rawget(_G, "myFonction")
    or rawget(_G, "myFunction")
    or
    safeRequireAny({ "my-librairie/myFunction", "my-librairie.myFunction", "my-librairie/globalFunction",
      "my-librairie.globalFunction" })
    or {}
local menu = require("scene.menu.menu")
local Transition = require("my-librairie.transitionManager")

-- Returns the distance between two points.
--[[
Fonction : math.dist
Rôle : Fonction « Dist » liée à la logique du jeu.
Paramètres :
  - x1 : paramètre détecté automatiquement.
  - y1 : paramètre détecté automatiquement.
  - x2 : paramètre détecté automatiquement.
  - y2 : paramètre détecté automatiquement.
Retour : valeur calculée.
]]
function math.dist(x1, y1, x2, y2)
  return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

-- VARIABLES
--[[ global ]]

DefaultColor = love.graphics.getColor();
--[[ Local ]]

-- INIT
--[[
Fonction : love.load
Rôle : Initialise les ressources et l'état.
Paramètres :
  - (aucun)
Retour : aucune valeur (nil).
]]
function love.load()
  -- ensure a folder for runtime logs exists so our debug writes won't fail silently
  pcall(function()
    local lfs = pcall(require, 'lfs') -- prefer lfs if available
    -- try basic Lua I/O fallback to create directory on Windows
    local ok, _ = pcall(function()
      -- On Windows, mkdir via os.execute may be available; try a portable approach
      if package.config:sub(1, 1) == '\\' then
        os.execute('if not exist "gameLogs" mkdir "gameLogs"')
      else
        os.execute('mkdir -p gameLogs')
      end
    end)
  end)

  scene:add(menu) -- ← deux-points
  scene:load()    -- pas besoin de dt ici
end

-- UPDATE
--[[
Fonction : love.update
Rôle : Met à jour la logique à chaque frame.
Paramètres :
  - dt : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function love.update(dt)
  _G.deltaTime = dt
  screen.UpdateRatio(dt)
  if inputManager and inputManager.update then inputManager.update(dt) end
  if not Transition.maskInput() then scene:update(dt) else --[[scene:update(dt)]] end
  Transition.update(dt)
  effect.update(dt)
  --[[  if love.keyboard.isDown('p') then
    Card.positioneHand(dt)
  end ]]
end

-- DRAW
--[[
Fonction : love.draw
Rôle : Affiche le rendu à l'écran.
Paramètres :
  - (aucun)
Retour : aucune valeur (nil).
]]
function love.draw()
  love.graphics.push()
  love.graphics.scale(screen.ratioScreen.width, screen.ratioScreen.height)
  scene:draw()
  Transition.draw()
  -- draw global logs panel if enabled (globalFunction may be set by module)
  local gf = rawget(_G, "globalFunction") or rawget(_G, "myFunction") or rawget(_G, "myFonction")
  if type(gf) == 'table' and type(gf.drawLogs) == 'function' then
    gf.drawLogs()
  end
  effect.draw()
  love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)
  love.graphics.pop()
end

-- (facultatif) Propager les événements si ton HUD a du clic/boutons
function love.mousepressed(x, y, button)
  pcall(function()
    local f = io.open("gameLogs/hud_clicks.log", "a")
    if f then
      f:write(os.date("%Y-%m-%d %H:%M:%S") ..
        " - love.mousepressed -> window_coords=" ..
        tostring(x) .. "," .. tostring(y) .. " button=" .. tostring(button) .. "\n")
      f:close()
    end
  end)
  scene:emit("mousepressed", x, y, button)
end

function love.mousereleased(x, y, button)
  scene:emit("mousereleased", x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
  -- toggle global logs with F12 if available
  if key == "f12" then
    local gf = rawget(_G, "globalFunction") or rawget(_G, "myFunction") or rawget(_G, "myFonction")
    if type(gf) == 'table' and type(gf.log) == 'table' and type(gf.log.toggle) == 'function' then gf.log.toggle() end
  end
  if Transition.maskInput() then return end
  scene:emit("keypressed", key, scancode, isrepeat)
end

function love.quit()
  local gf = rawget(_G, "globalFunction") or rawget(_G, "myFunction") or rawget(_G, "myFonction")
  if type(gf) == 'table' and type(gf.log) == 'table' and type(gf.log.exportToFile) == 'function' then
    pcall(function() gf.log.exportToFile() end)
  end
end
