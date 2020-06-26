local card={};
card.objet ={}
local screen = require("my-librairie/responsive");
local hud = require("my-librairie/hud");

function card.create(p_card,p_decoration,p_ilustration,p_description)
	--
	local cart ={
		
		vector2 = { x = 60 , y = 900 } ,
		scale={ x = 0.5 , y = 0.5 },
		card = love.graphics.newImage( p_card ),
		decoration = love.graphics.newImage ( p_decoration ) ,
		ilustration = love.graphics.newImage ( p_ilustration ) ,
		description = p_description ,
		oldVector2 = { x = 60 , y = 900 } 
	}
	
	local Width , Height = cart.card:getDimensions() ; 
	cart.height = Height;
	cart.width = Width ;
	--generate canvas card
	cart.canvas =  card.generate(cart)
	
	table.insert(card.objet,cart);
	
	return cart
end


--HOVER MOUSE DETECTION 
	function card.hover()
	
		local isHover = false;
		
		local x,y = love.mouse.getPosition() ;
		
		x=x/screen.ratioScreen.width;
		y=y/screen.ratioScreen.height;
		
		for i= #card.objet ,1,-1 do
			
			value = card.objet[i];
			
			
			if(x >= value.vector2.x and
				x <= value.vector2.x +	(value.width*value.scale.x) 	and
				y >= value.vector2.y and
				y <= value.vector2.y +	(value.height*value.scale.y) and isHover == false) then
				
				local objet = hud.hover();
				
				if(objet.validate==false )then
					value.scale.x = 1 ;
					value.scale.y = 1 ;
					
					card.dragAndDrop(x,y,value);
					
					--DEBUG
					love.graphics.setColor(1,0,0);
					love.graphics.rectangle(
						'line',
						value.vector2.x,
						value.vector2.y,
						value.width*value.scale.x,
						value.height*value.scale.y
						
					);
					love.graphics.setColor(1,1,1);
					
				end	
				
				isHover = true;
				
			else
				
				value.vector2.y = value.oldVector2.y ;
				value.vector2.x = value.oldVector2.x;
				
				
				value.scale.x = 0.5 ;
				value.scale.y = 0.5 ;
			end
			
		end
	end	
	
	--DRAG CART MOUSE
	function card.dragAndDrop(p_x,p_y,cart)
		
		--STATE CLICK LEFT MOUSE
		local down = love.mouse.isDown(1);
		--check is down
		if( down) then
			

			
			cart.vector2.y = p_y-(cart.height/2);
			cart.vector2.x = p_x-(cart.width/2);
		
			print(cart.vector2.y);
			--cart.vector2.x = (cart.vector2.x+cart.width) - p_x;
	
			
		else
			
			--Reset Position Cart
				cart.vector2.y = 600;
			
		end
		
		
		
	end
--Return canvas 
function card.generate(p_cart)
	
	 -- create canvas
    local graphicsCard = love.graphics.newCanvas(338,462)
		
		love.graphics.clear()
 
    -- direct drawing operations to the canvas
    love.graphics.setCanvas(graphicsCard)
		love.graphics.rectangle('fill',0,0,338,462)
		love.graphics.draw( p_cart.card , 0 , 0 )
		
		love.graphics.draw( p_cart.decoration , 15 , 41 )
		
		love.graphics.draw( p_cart.ilustration , 55 , 74 )
		
		love.graphics.print ( p_cart.description , 66 , 271 )

    -- re-enable drawing to the main screen
    love.graphics.setCanvas()
	
	return graphicsCard
	
end

return card;