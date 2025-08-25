local screenManager = {};

screenManager.gameReso = {
    width = 1920,
    height = 1080
};
screenManager.ratioScreen = {
    height = 1,
    width = 1
};
local curentDimensions = {
    width = 1280,
    height = 720
};

screenManager.getRatio = function()
    return screenManager.ratioScreen.width, screenManager.ratioScreen.height
end

screenManager.Syncro = true;
screenManager.FullScreen = false;
screenManager.resizable = true;
screenManager.getWindow = {};
local isHover = false;


love.window.setMode(1280, 720, {
    fullscreen = screenManager.FullScreen,
    resizable = screenManager.resizable,
    vsync = screenManager.Syncro,
    minwidth = 1280,
    minheight = 720
});
--[[ MOUSE SCALE POSITION ]]
local function _getRawMouse()
    local ok, cur = pcall(require, "my-librairie/cursor")
    if ok and cur and cur.get then return cur.get() end
    return 0, 0
end

local x, y = _getRawMouse()
screenManager.mouse = {};
screenManager.mouse.X = x / screenManager.ratioScreen.width;
screenManager.mouse.Y = y / screenManager.ratioScreen.height;
--[[
Fonction : screenManager.UpdateRatio
Rôle : Fonction « Update ratio » liée à la logique du jeu.
Paramètres :
  - dt : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function screenManager.UpdateRatio(dt)
    curentDimensions.width, curentDimensions.height = love.graphics.getDimensions();
    screenManager.ratioScreen.height = curentDimensions.height / screenManager.gameReso.height;
    screenManager.ratioScreen.width = curentDimensions.width / screenManager.gameReso.width;
    screenManager.getWindow = curentDimensions;

    x, y = _getRawMouse();
    screenManager.mouse.X = x / screenManager.ratioScreen.width;
    screenManager.mouse.Y = y / screenManager.ratioScreen.height;
end

return screenManager;
