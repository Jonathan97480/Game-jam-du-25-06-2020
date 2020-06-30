local myFunction = {}
local lockClick = false;
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
return myFunction;
