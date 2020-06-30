
-- LOAD IMG HUD
local hudManager = {};
hudManager.object = {

    btnFinDeTour = {

        img = love.graphics.newImage("img/hud/Button-fin-de-tour.png"),
        vector2 = {
            x = 1283,
            y = 1019
        },
        value = {
            {
                vector2 = {
                    x = 1310,
                    y = 1035
                },
                text = 'End of Tours'

            }

        },
        width = 0,
        height = 0,

        action = function()
            if hero.actor.state.dead ~= true and Enemies.curentEnemy.state.dead ~= true then
                Tour = 'Enemy'
            end
        end
    },
    btnLife = {

        img = love.graphics.newImage("img/hud/Button-life.png"),
        vector2 = {
            x = 433,
            y = 1029
        },
        value = {
            {
                vector2 = {
                    x = 0,
                    y = 0
                },
                text = ''
            }

        },
        width = 0,
        height = 0
    },
    btnMenu = {

        img = love.graphics.newImage("img/hud/Button-Menu.png"),
        vector2 = {
            x = 1854,
            y = 1024
        },
        value = {
            {
                vector2 = {
                    x = 0,
                    y = 0
                },
                text = ''
            }

        },
        width = 0,
        height = 0
    },
    btnAllCard = {

        img = love.graphics.newImage("img/hud/Button-all-card.png"),
        vector2 = {
            x = 1778,
            y = 1023
        },
        value = {
            {
                vector2 = {
                    x = 0,
                    y = 0
                },
                text = ''
            }

        },
        width = 0,
        height = 0,
        action = function()
 
        end
    },
    footerBar = {

        img = love.graphics.newImage("img/hud/footer-bare.jpg"),
        vector2 = {
            x = 0,
            y = 1017
        },
        value = {
            {
                vector2 = {
                    x = 0,
                    y = 1017
                },
                text = ''
            }

        },
        width = 0,
        height = 0

    },
    cardDeck = {

        img = love.graphics.newImage("img/hud/nombre de carte.png"),
        vector2 = {
            x = 127,
            y = 827
        },
        value = {
            {
                vector2 = {
                    x = 130,
                    y = 830
                },
                text = 0
            }

        },
        width = 0,
        height = 0

    },
    cardGraveyard = {

        img = love.graphics.newImage("img/hud/Carte-simetiere.png"),
        vector2 = {
            x = 127,
            y = 916
        },
        value = {
            {
                vector2 = {
                    x = 180,
                    y = 975
                },
                text = 0
            }

        },
        width = 0,
        height = 0
    },
    energie = {

        img = love.graphics.newImage("img/hud/nombre de coup.png"),
        vector2 = {
            x = 127,
            y = 745
        },
        value = {
            {
                vector2 = {
                    x = 158,
                    y = 768
                },
                text = 0
            }

        },
        width = 0,
        height = 0
    },
    btnQuiter = {

        img = love.graphics.newImage("img/hud/Button-fin-de-tour.png"),
        vector2 = {
            x = 650,
            y = 300
        },
        value = {
            {
                vector2 = {
                    x = 680,
                    y = 315
                },
                text = 'Go To Menu'

            }

        },
        width = 0,
        height = 0,

        action = function()
            scene.curent = 'Menu'
        end
    },
    btnNewPartie = {

        img = love.graphics.newImage("img/hud/Button-fin-de-tour.png"),
        vector2 = {
            x = 1100,
            y = 300
        },
        value = {
            {
                vector2 = {
                    x = 1130,
                    y = 315
                },
                text = 'New Partie'

            }

        },
        width = 0,
        height = 0,

        action = function()

            scene.curent = 'gameplay';
            scene.gameplay.rezetGame();
        end
    }
    --[[  Attack = {

        img = love.graphics.newImage("img/hud/HubAttack.png"),
        vector2 = {
            x = 23,
            y = 767
        },
        value = {
            {
                vector2 = {
                    x = 60,
                    y = 800
                },
                text = 0
            }

        },
        width = 0,
        height = 0
    }, ]]
    --[[   Deffence = {

        img = love.graphics.newImage("img/hud/Hud-Defence.png"),
        vector2 = {
            x = 23,
            y = 854
        },
        value = {
            {
                vector2 = {
                    x = 60,
                    y = 900
                },
                text = 0
            }

        },
        width = 0,
        height = 0
    }, ]]
    --[[    prisme = {

        img = love.graphics.newImage("img/hud/power-magical.png"),
        vector2 = {
            x = 23,
            y = 935
        },
        value = {
            {
                vector2 = {
                    x = 60,
                    y = 980
                },
                text = 0
            }

        },
        width = 0,
        height = 0
    } ]]

};

function hudManager.load()

    for key, value in pairs(hudManager.object) do

        width, height = value.img:getDimensions();

        value.width = width;
        value.height = height;

    end
end
function hudManager.hover(action)



    for key, value in pairs(hudManager.object) do

        if ( screen.mouse.X >= value.vector2.x and screen.mouse.X <= value.vector2.x + value.width and screen.mouse.Y >= value.vector2.y and screen.mouse.Y <=
            value.vector2.y + value.height) then

            if (action == nil) then

            

                return true;
            else

                hudManager.action(value, action, key);
                --	return true;
            end
        end

    end
    if (action == nil) then
        return false;
    else
        return false;
    end

end

function hudManager.action(p_hudElement, action, nameElement)
    if (p_hudElement.action == nil) then
        return false
    end

    p_hudElement.action();

end

function hudManager.draw()

    for key, value in pairs(hudManager.object) do

        if key ~= 'btnNewPartie' and key ~= 'btnQuiter' then
            love.graphics.draw(value.img, value.vector2.x, value.vector2.y);
            love.graphics.setNewFont(20);

            for i = 1, #value.value do
                local info = value.value[i];
                love.graphics.print(info.text, info.vector2.x, info.vector2.y);
            end

        end
    end

end
return hudManager;
