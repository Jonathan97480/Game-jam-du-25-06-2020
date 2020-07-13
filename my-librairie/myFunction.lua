local myFunction = {}
local lockClick = false;

--[[ Icon Bare status load  ]]
local shield = love.graphics.newImage('img/Actor/Enemy/Hub-Shield2.png');
local epineIcon = love.graphics.newImage('img/icon/bonus-epine-icon.png');
local bonussAttackIcon = love.graphics.newImage('img/icon/bonuss-attack-icon.png');

local lifeBar = {
    red = love.graphics.newImage('img/Actor/Enemy/HudLifeEnemy.png'),
    bleu = love.graphics.newImage('img/Actor/hero/HudLifeHero.png'),
    color_red = {
        1,
        0,
        0
    },
    color_bleu = {
        0,
        0,
        1
    }
};
myFunction.lerp = function(a, b, t)
    local complete = false;
    local d = a.x - b.x;
    if a.x > b.x then

        if (d <= 1) then
            a.x = b.x
            return false
        end
        a.x = a.x - d * (t * delta);

    elseif a.x < b.x then
        d = d * -1;
        if (d >= 1) then
            a.x = b.x
            return false
        end
        a.x = a.x + d * (t * delta);

    end

    local dY = a.y - b.y;

    if a.y > b.y then

        if (dY <= 1) then

            a.y = b.y
            return false
        end

        a.y = a.y - dY * (t * delta);

    elseif a.y < b.y then

        dY = dY * -1;

        if (dY <= 1) then
            a.y = b.y

            return false

        end

        a.y = a.y + dY * (t * delta);

    end
    return true;
end
myFunction.mouse = {}
--[[ Prend une postion x ,y et un width et height scale sur volée  ]]
myFunction.mouse.hover = function(x, y, width, height, scale)

    if screen.mouse.X >= x and screen.mouse.X <= x + (width * scale.x) and screen.mouse.Y >= y and screen.mouse.Y <= y +
        (height * scale.y) then
        return true;
    end
    return false;
end

myFunction.mouse.click = function()

    if love.mouse.isDown(1) and lockClick == false then

        lockClick = true;
        return true

    elseif love.mouse.isDown(1) == false and lockClick == true then

        lockClick = false;
        return false

    end

end

function myFunction.drawLifeBarStatus(p_actor, p_Colorbar)

    --[[ Define color bar  ]]
    local color = lifeBar.color_red;
    local colorBar = 'red';
    if p_Colorbar == "bleu" then
        colorBar = p_Colorbar;
        color = lifeBar.color_bleu
    end

    --[[ Define postion bar  ]]
    local position = {
        x = p_actor.vector2.x + ((p_actor.width /2) - (p_actor.state.maxLife / 0.5)),
        y = p_actor.vector2.y + p_actor.height-88
    }
    --[[ Draw Life bar ]]
    love.graphics.setColor(color);
    love.graphics.rectangle('fill', position.x, position.y + 4, 336 *(p_actor.state.life/p_actor.state.maxLife) , 10);
    love.graphics.setColor(1, 1, 1);
    --[[ Draw Border Life Bar ]]
    love.graphics.draw(lifeBar[colorBar], position.x, position.y, 0, 1.5, 2);
    --[[ Print Value Life Curent Actor and Life max ]]
    love.graphics.print(p_actor.state.life .. '/' .. p_actor.state.maxLife, p_actor.vector2.x + (p_actor.width / 1.8),
                        p_actor.vector2.y + (p_actor.height - 8));

    --[[ Draw icon Bonus  ]]
    drawBonus(p_actor, color, position);

end

function drawBonus(p_actor, color, position)

    --[[ Draw Shield incon  ]]
    if p_actor.state.shield > 0 then

        love.graphics.draw(shield, position.x - 30, position.y - 20, 0, 1.5, 1.5);
        love.graphics.setNewFont(40);
        love.graphics.print(p_actor.state.shield, position.x - 12, position.y - 10);
        love.graphics.setNewFont(20);

    end
    --[[ Draw Epine incon  ]]
    if p_actor.state.epine > 0 then
        love.graphics.draw(epineIcon, position.x + 30, position.y + 20, 0, 1.5, 1.5);
    end
    --[[ Draw Bonuss-Attack incon  ]]
    if p_actor.state.degat > 0 then
        love.graphics.draw(bonussAttackIcon, position.x + 80, position.y + 20, 0, 1.5, 1.5);
    end
end
return myFunction;
