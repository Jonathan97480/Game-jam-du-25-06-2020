local screenManager ={};

local gameReso ={ width = 1920 , height = 1080 };
 screenManager.ratioScreen={height = 1 ,width = 1};
local curentDimensions={};

screenManager.Syncro = true;
screenManager.FullScreen = false;
screenManager.resizable = true;

love.window.setMode(
	1280,
	720,
	{
		fullscreen = screenManager.FullScreen,
		resizable=screenManager.resizable, 
		vsync=screenManager.Syncro,
		minwidth=1280, 
		minheight=720
	}
);

function screenManager.UpdateRatio()

	curentDimensions.width , curentDimensions.height = love.graphics.getDimensions();
	screenManager.ratioScreen.height =  curentDimensions.height  / gameReso.height;
	screenManager.ratioScreen.width =  curentDimensions.width  / gameReso.width;

	

end

return screenManager ;