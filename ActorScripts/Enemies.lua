local Enemies={};

--REQUIRE


--VARIABLE
Enemies.vector2 ={x = 1261 , y = 450};
Enemies.sfx={};
Enemies.sound ={};
Enemies.curentAnimation = 'idle';

Enemies.state = {
	life=100,
	degatBase ={0},
	bonus ={
		degat =0,
		life =0,
		armor =0,
		}
	};

Enemies.animation ={
	
	idle = {
		love.graphics.newImage("img/Actor/Enemy/enemy.png");
		};
	hit = {};
	attack = {};
	parade = {};
	heal = {};
	
};

--LOAD
function Enemies.load()
	
	
	
end


--UPDATE
function Enemies.update()




end



--DRAW
function Enemies.draw()
	
	local animation = Enemies.animation[Enemies.curentAnimation] ;
	
	for i=1 , #animation  do
	
		
		love.graphics.draw(animation[i],Enemies.vector2.x ,Enemies.vector2.y);
		
		
	end
			--BARE DE VIE 
		love.graphics.setColor(1,0,0);
		love.graphics.rectangle(
			'fill',
			Enemies.vector2.x+50,
			Enemies.vector2.y + 270 ,
			3*Enemies.state.life,	
			10
		);
		love.graphics.setColor(1,1,1);
	
	
	end
return Enemies;