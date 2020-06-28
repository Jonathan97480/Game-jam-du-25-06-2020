local lerp = {}
lerp.x = function(a, b, t)

    if a.x > b.x then


        a.x = a.x - (0.09 * t);
        return
    elseif a.x < b.x then

        a.x = a.x + (0.09* t);
        return
    end

end

return lerp;
