local screen = require("my-librairie/responsive");

-- LOAD IMG HUD
local hud = {};
hud.object = {

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
		action= function()
			cardeGenerator.clearHand();
			cardeGenerator.tirage(5);
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

		}
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

		}
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
		action= function()
			cardeGenerator.clearHand();
			cardeGenerator.tirage(5);
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

        }

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

        }

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

        }
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

        }
    },

    Attack = {

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

        }
    },
    Deffence = {

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

        }
    },
    prisme = {

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

        }
    }

};

function hud.init()

    for key, value in pairs(hud.object) do

        width, height = value.img:getDimensions();

        value.width = width;
        value.height = height;

    end
end
function hud.hover(action)

    local objet = {
        name = '',
        info = '',
        validate = false
    };

    local x, y = love.mouse.getPosition();
    x = x / screen.ratioScreen.width;
    y = y / screen.ratioScreen.height;

    for key, value in pairs(hud.object) do

        if (x >= value.vector2.x and x <= value.vector2.x + value.width and y >= value.vector2.y and y <=
			value.vector2.y + value.height) then
				
			if (action == nil) then
				
                objet.name = key;
                objet.info = value;
                objet.validate = true;

				return objet;
			else

				hud.action(value,action,key);
			--	return true;
            end
        end

    end
    if (action == nil) then
		return objet;
	else
		return false;	
    end

end

function hud.action(p_hudElement,action,nameElement)
	print(nameElement)
	if(p_hudElement.action==nil)then return false end
	
	p_hudElement.action();



end


function hud.draw()

    for key, value in pairs(hud.object) do

        love.graphics.draw(value.img, value.vector2.x, value.vector2.y);
        love.graphics.setNewFont(20);

        for i, info in pairs(value.value) do

            if info ~= nil and info.text ~= '' then

                love.graphics.print(info.text, info.vector2.x, info.vector2.y);

            end
        end

    end

end
return hud;
