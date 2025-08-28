-- scene/overlay_start.lua
local overlay           = { name = "overlay_start" }

-- Use modular HUD system
local hud_overlay_start = require("scene.overlay_start.HUD.hud_overlay_start")

function overlay.load()
    hud_overlay_start.load()
end

function overlay.update(dt)
    dt = _G.globalFunction.clampDt(dt)
    hud_overlay_start.update(dt)
end

function overlay.draw()
    hud_overlay_start.draw()
end

function overlay.leave()
    -- Appelé quand la scène est sur le point d'être retirée de la pile
    if hud_overlay_start.leave then
        hud_overlay_start.leave()
    end
end

function overlay.unload()
    hud_overlay_start.unload()
end

return overlay
