local gameplay={};

--REQUIRE
local cardeGenerator = require("my-librairie/cardeGenerator");
local hud = require("my-librairie/hud");
local hero = require("ActorScripts/hero");
local Enemies = require("ActorScripts/Enemies");
--VARIABLE
	local myDeck={};

--LOAD
function gameplay.load()
	
	hud.init();
	
	for  i=0 , 9 do
		card = cardeGenerator.create(
			
			'img/card/tourbillion/card.jpg' ,
			'img/card/tourbillion/decoration.png' ,
			'img/card/tourbillion/ilustration.png',
			'Ma Premiere card'
		);
		
		
		card.vector2.x = card.vector2.x + ((card.width/2) * (i+1));
		card.oldVector2.x = card.vector2.x;
		
		table.insert(myDeck,card);
		
	end	
	
end


--UPDATE
function gameplay.update()

cardeGenerator.hover();


end



--DRAW
function gameplay.draw()
	
	--DRAW ACTOR 
	hero.draw();
	Enemies.draw();
	--DRAW CARD
	for key,value in pairs(myDeck) do
	
		love.graphics.draw(
			
			value.canvas ,
			value.vector2.x ,
			value.vector2.y ,
			0 ,
			value.scale.x ,
			value.scale.y 
		);
		

	end
	
	--DRAW HUD
	hud.draw();
	
	end
return gameplay;