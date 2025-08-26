-- scene/hud_overlay.lua
local hud_overlay = { name = "hud_overlay" }

local hud = require("my-librairie/hud/hud")



function hud_overlay.enter(self) end

function hud_overlay.leave(self) end

function hud_overlay.unload(self) end

function hud_overlay.resume(self) end

function hud_overlay.pause(self) end

-- NOTE: on ne touche pas aux tours ici : le gameplay gère Tour.


function hud_overlay.draw(self)
    -- Orchestration du rendu HUD (background, éléments, etc.)
    if hud.drawBackground then hud.drawBackground() end
    if hud.draw then hud.draw() end
end

function hud_overlay.hover(self, ...)
    if hud.hover then return hud.hover(...) end
end

function hud_overlay.mousepressed(self, mx, my, btn)
    -- convert window coords to game resolution coords (main.lua applies scale)
    local sx = (screen and screen.ratioScreen and screen.ratioScreen.width) or 1
    local sy = (screen and screen.ratioScreen and screen.ratioScreen.height) or 1
    local gx = mx / sx
    local gy = my / sy
    pcall(function()
        local f = io.open("gameLogs/hud_clicks.log", "a")
        if f then
            f:write(os.date("%Y-%m-%d %H:%M:%S") ..
                " - hud_overlay.mousepressed -> game_coords=" ..
                tostring(gx) .. "," .. tostring(gy) .. " button=" .. tostring(btn) .. "\n")
            f:close()
        end
    end)
    if hud and hud.hover then return hud.hover("click", gx, gy) end
    return false
end

return hud_overlay
