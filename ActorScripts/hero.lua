local hero={};

--REQUIRE


--VARIABLE
hero.vector2 ={x = 466 , y = 523};
hero.sfx={};
hero.sound ={};

hero.state = {
	
	name ="",
	nameDeck ="",
	life=80,
	degatBase =0,
		bonus ={
		degat =0,
		life =0,
		armor =0,
		}
	
	};
hero.curentAnimation = 'idle';

hero.animation ={
	
	idle = {
		love.graphics.newImage("img/Actor/hero/Hero.png");
		};
	hit = {};
	attack = {};
	parade = {};
	heal = {};
	
};

--LOAD
function hero.load()
	
	
	
end


--UPDATE
function hero.update()




end



--DRAW
function hero.draw()
	
	local animation = hero.animation[hero.curentAnimation] ;
	
	for i=1 , #animation  do
	
		love.graphics.draw(animation[i],hero.vector2.x ,hero.vector2.y);
		
	end
		--BARE DE VIE 
		love.graphics.setColor(0,0,1);
		love.graphics.rectangle(
			'fill',
			hero.vector2.x+100,
			hero.vector2.y + 230 ,
			3*hero.state.life,	
			10
		);
		love.graphics.setColor(1,1,1);
	
	
	end
return hero;