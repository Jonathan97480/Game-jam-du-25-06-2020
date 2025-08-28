-- Test simple pour require overlay_initiative
print("Testing overlay_initiative require...")
local ok, overlay = pcall(require, "scene.overlay_initiative.overlay_initiative")
if ok then
    print("SUCCESS: overlay_initiative loaded successfully")
    print("overlay.name = " .. tostring(overlay.name))
else
    print("ERROR: " .. tostring(overlay))
end
