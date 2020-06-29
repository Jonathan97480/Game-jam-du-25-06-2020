local lerp = {}

lerp  = function(a, b, t)
    local complete = false;
    local d = a.x - b.x;
    if a.x > b.x then

        if (d <= 1) then
            a.x = b.x
            return false
        end
        a.x = a.x - d * (t * delta);

    elseif a.x < b.x then
        d = d *-1;
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

        dY = dY *-1;

        if (dY <= 1) then
            a.y = b.y

            return false

        end

        a.y = a.y + dY * (t * delta);

    end
    return true;
end

return lerp;
