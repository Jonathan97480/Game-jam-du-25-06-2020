local menu={};
menu.illustration={};
	
menu.illustration.background={
	img = love.graphics.newImage('img/Menu/Titre.png'),
	vector2 = {x=screen.gameReso.width/2,y=screen.gameReso.height/2.8};
}
menu.illustration.title ={
	img = love.graphics.newImage('img/Menu/BackGround.jpg'),
	vector2={x=0,y=0}
}


--REQUIRE


--VARIABLE


--LOAD
function menu.load()
	
	
	
end


--UPDATE
function menu.update()




end



--DRAW
function menu.draw()

for key, value in pairs(menu.illustration) do
	love.graphics.draw(value.img,value.vector2.x,value.vector2.y); 
end


	

end
return menu;