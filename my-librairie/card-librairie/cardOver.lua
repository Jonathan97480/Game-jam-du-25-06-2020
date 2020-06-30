local cardsHover={}

function cardsHover.hover(dt)

    local isDown = love.mouse.isDown(1);

    local action = nil;

    if myFonction.mouse.click() then

        action = "click";

    end
    if #card.hand > 0 then
        for i = #card.hand, 1, -1 do

            value = card.hand[i];

            if (hud.hover(action) == false) then

                --[[ SI ma sourie ne se trouve pas sur un element du Hud ]]

                if myFonction.mouse.hover(value.vector2.x, value.vector2.y, value.width, value.height, value.scale) and
                    Tour ~= "transition" then

                    --[[ Je redonne a la carte sa taille normale  ]]
                    value.scale.x = 1;
                    value.scale.y = 1;

                    if (isDown) then
                        -- DRAG CART MOUSE POSITION
                        value.vector2.y = screen.mouse.Y - (value.height / 2);
                        value.vector2.x = screen.mouse.X - (value.width / 2);
                        break
                    elseif isDown == false and value.vector2.y <= 400 then
                        --[[ Applique car si elle est deplaser go  moin a 300pixel de haut  ]]
                        if hero.actor.state.power >= 0 then

                            if CardAction.Apllique(value) then
                            
                                --[[ On enleve la carde de la main du jouer et on la met dans le simetiere  ]]
                                table.insert(card.Graveyard, card.hand[i]);
                                table.remove(card.hand, i);
                                --[[ est on reposition les carte restant dans la main du jouer  ]]
                                card.positioneHand();
                                break
                            end
                            break
                        end
                    elseif value.vector2.y > 580 and isDown == false then

                        myFonction.lerp(value.vector2, {
                            x = value.vector2.x,
                            y = 600
                        }, 4);

                    end

                else

                    local Arrival = myFonction.lerp(value.vector2, value.oldVector2, 4);

                    value.scale.x = 0.5;
                    value.scale.y = 0.5;

                end
            else
                myFonction.lerp(value.vector2, value.oldVector2, 4);
                value.scale.x = 0.5;
                value.scale.y = 0.5;

            end

        end
    else
        hud.hover(action)
    end
end
return cardsHover;