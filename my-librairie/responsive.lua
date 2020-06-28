local screenManager = {};

screenManager.gameReso = {
    width = 1920,
    height = 1080
};
screenManager.ratioScreen = {
    height = 1,
    width = 1
};
local curentDimensions = {};

screenManager.Syncro = true;
screenManager.FullScreen = false;
screenManager.resizable = true;

local isHover = false;


love.window.setMode(1280, 720, {
    fullscreen = screenManager.FullScreen,
    resizable = screenManager.resizable,
    vsync = screenManager.Syncro,
    minwidth = 1280,
    minheight = 720
});
--[[ MOUSE SCALE POSITION ]]
local x, y = love.mouse.getPosition();
screenManager.mouse={};
screenManager.mouse.X = x / screenManager.ratioScreen.width;
screenManager.mouse.Y = y / screenManager.ratioScreen.height;
function screenManager.UpdateRatio()

    curentDimensions.width, curentDimensions.height = love.graphics.getDimensions();
    screenManager.ratioScreen.height = curentDimensions.height / screenManager.gameReso.height;
	screenManager.ratioScreen.width = curentDimensions.width / screenManager.gameReso.width;

	x, y = love.mouse.getPosition();
    screenManager.mouse.X = x / screenManager.ratioScreen.width;
    screenManager.mouse.Y = y / screenManager.ratioScreen.height;

end

return screenManager;
