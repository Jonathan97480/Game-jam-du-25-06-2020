local scene = {};

--REQUIRE
scene.start = require("scene/start");
scene.gameplay = require("scene/gameplay");
scene.option = require("scene/option");
scene.credit = require("scene/credit");
scene.menu = require("scene/menu");

scene.liste={
	
	startGame ={},
	menu ={},
	gmaePlay={},
	credit={},
	option={}
	
	};
scene.curent="gameplay";

function scene.load()
	
	if(scene.curent =="gameplay") then
		
		scene.gameplay.load();
		
		
	end
	
end


function scene.update()
		if(scene.curent =="gameplay") then
		
		scene.gameplay.update();
		
		
	end
end


function scene.draw()
	if(scene.curent =="gameplay") then
		
		scene.gameplay.draw();
		
		
	end
	
end
return scene