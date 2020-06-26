
local screen = require("my-librairie/responsive");
--LOAD IMG HUD
local hud={};
hud.object ={
	
	footerBar ={ 
		
		img =love.graphics.newImage("img/hud/footer-bare.jpg"),
		vector2 = { x = 0 , y = 1017 } ,
		
	},
	numberCard ={
		
		img =love.graphics.newImage("img/hud/nombre de carte.png"),
		vector2 = { x = 129 , y = 914 } ,
		
	},
	numberAtack ={
		
		img =love.graphics.newImage("img/hud/nombre de coup.png"),
		vector2 = { x = 129 , y = 790 } ,
		
	}
	
	
};

function hud.init()
	
	for key,value in pairs(hud.object) do
		
		width , height = value.img:getDimensions();
		
		value.width = width;
		value.height = height;
		
	end
end
function hud.hover()
	
	local objet={name ='',info='',validate=false};
	
		local x,y = love.mouse.getPosition() ;
		x=x/screen.ratioScreen.width;
		y=y/screen.ratioScreen.height;
	
	for key,value in pairs(hud.object) do
		

		
		if(x >= value.vector2.x and
			
			x <= value.vector2.x +	value.width 	and
			y >= value.vector2.y and
			y <= value.vector2.y +	value.height) then
			
			objet.name = key;
			objet.info = value;
			objet.validate=true;
		
			return objet;
			
		end
		
	end 
	return objet;
end
function hud.draw()

	love.graphics.draw(hud.object.footerBar.img,hud.object.footerBar.vector2.x , hud.object.footerBar.vector2.y );
	love.graphics.draw(hud.object.numberCard.img,hud.object.numberCard.vector2.x , hud.object.numberCard.vector2.y );
	love.graphics.draw(hud.object.numberAtack.img,hud.object.numberAtack.vector2.x , hud.object.numberAtack.vector2.y );
	
end
return hud ;