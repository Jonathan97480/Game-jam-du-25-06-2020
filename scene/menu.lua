local menu = {};
menu.illustration = {};

menu.illustration.background = {
    img = love.graphics.newImage('img/Menu/Titre.png'),
    vector2 = {
        x = screen.gameReso.width / 2,
        y = screen.gameReso.height / 2.8
    }
}
menu.illustration.title = {
    img = love.graphics.newImage('img/Menu/BackGround.jpg'),
    vector2 = {
        x = 0,
        y = 0
    }
}

menu.button = {

    play = {
        texte = 'Play',
        width = 180,
        height = 60,
        vector2 = {
            x = 60,
            y = screen.gameReso.height / 2 + (1 * 80)
        },
        color = {
            curent = {
                1,
                1,
                1
            },
            hover = {
                0,
                1,
                0
            },
            normal = {
                1,
                1,
                1
            },
            click = {
                1,
                0,
                0
            }
        },
        action = function()
            scene.curent = 'gameplay';
            scene.gameplay.rezetGame();
        end
    },
    credit = {
        texte = 'Credit',
        width = 240,
        height = 60,
        vector2 = {
            x = 60,
            y = screen.gameReso.height / 2 + (2 * 80)
        },
        color = {
            curent = {
                1,
                1,
                1
            },
            hover = {
                0,
                1,
                0
            },
            normal = {
                1,
                1,
                1
            },
            click = {
                1,
                0,
                0
            }
        },
        action = function()
            scene.curent = 'credit';
        end
    },
    quit = {
        texte = 'Quit',
        width = 180,
        height = 60,
        vector2 = {
            x = 60,
            y = screen.gameReso.height / 2 + (3 * 80)
        },
        color = {
            curent = {
                1,
                1,
                1
            },
            hover = {
                0,
                1,
                0
            },
            normal = {
                1,
                1,
                1
            },
            click = {
                1,
                0,
                0
            }
        },
        action = function()
            love.window.close();
        end
    }

}
-- REQUIRE

-- VARIABLE
local isclick=false;
-- LOAD
function menu.load()
	
	scene.gameplay.load();
end

-- UPDATE
function menu.update()
    menu.hover();
end

-- DRAW
function menu.draw()

    for key, value in pairs(menu.illustration) do
        love.graphics.draw(value.img, value.vector2.x, value.vector2.y);
    end
    for key, value in pairs(menu.button) do
        love.graphics.setColor(value.color.curent);
        love.graphics.setNewFont(60);
        love.graphics.print(value.texte, value.vector2.x, value.vector2.y);

    end
    love.graphics.setColor(1, 1, 1);
end

function menu.hover()
    local x, y = love.mouse.getPosition();
    x = x / screen.ratioScreen.width;
    y = y / screen.ratioScreen.height;

    for key, value in pairs(menu.button) do

        if (x >= value.vector2.x and x <= value.vector2.x + value.width and y >= value.vector2.y and y <=
            value.vector2.y + value.height) then

			if love.mouse.isDown(1) and isclick == false then
				isclick = true;
				value.color.curent = value.color.click;
				cardeGenerator.tirage(5);
				value.action();
            else
				value.color.curent = value.color.hover;
				isclick = false;
            end
        else
			isclick = false;
            value.color.curent = value.color.normal;
        end
    end
end
return menu;
