-- scene/hud_overlay.lua
local hud_overlay = { name = "hud_overlay" }

-- On réutilise ton module HUD existant (mêmes API : load/update/draw/hover/…)
local hud = rawget(_G, "hud") or require("ressources/hud")

function hud_overlay.load(self)
    if hud and hud.load then hud.load() end
end

function hud_overlay.enter(self) end

function hud_overlay.leave(self) end

function hud_overlay.unload(self) end

function hud_overlay.resume(self) end

function hud_overlay.pause(self) end

-- NOTE: on ne touche pas aux tours ici : le gameplay gère Tour.
function hud_overlay.update(self, dt)
    if hud and hud.update then hud.update(dt) end
end

function hud_overlay.draw(self)
    if hud and hud.draw then hud.draw() end
end

-- Si ton HUD gère des clics propres, on les relaie (facultatif)
function hud_overlay.mousepressed(x, y, button)
    if hud and hud.mousepressed then
        local consumed = hud.mousepressed(x, y, button)
        -- Si ta fonction renvoie true quand elle consomme, retourne true pour stopper (si emit modifié en “consommable”).
        return consumed
    end
end

function hud_overlay.mousereleased(x, y, button)
    if hud and hud.mousereleased then
        return hud.mousereleased(x, y, button)
    end
end

function hud_overlay.keypressed(key, scancode, isrepeat)
    if hud and hud.keypressed then
        return hud.keypressed(key, scancode, isrepeat)
    end
end

return hud_overlay
