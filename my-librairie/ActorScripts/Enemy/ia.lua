local ia = {};

function ia.playTour()

    --[[ On verifie si lenemy doit passer son tour   ]]
    if Enemies.curentEnemy.state.chancePassTour > 0 and Enemies.isAttack then
        if (math.random(20, 100) < Enemies.curentEnemy.state.chancePassTour) then

            Enemies.curentEnemy.state.chancePassTour = 0;
            Enemies.isAttack = false;
        end
    end

    --[[ On verifie si il va avoir de l'armure  ]]
    local shield = math.random(1, 10);

    if shield > 2 and shield <= 4 and Enemies.isAttack then

        --[[ TODO:ANIMATION GIVE SHIELD ]]
        Enemies.curentEnemy.state.shield = math.random(10, 30);
        Enemies.isAttack = false;

    end

    --[[ si il doit ataquer  ]]
    if Enemies.isAttack then

        --[[On fait un ramdom parapore a ces degats de base et ces degat maximum ]]
        local degat = love.math.random(20, 30);

        --[[ On verifie si le hero a de lépine  ]]
        if hero.actor.state.epine > 0 then

            --[[ On calcul le nombre de degat que l'enemy va se prendre et on applique les degats  ]]
            AppliqueDegatToEnemy(hero.actor.state.shield * (hero.actor.state.epine / 100));

            --[[ on verifie que l'enemie est mort  ]]
            if Enemies.curentEnemy.state.life <= 0 then
                --[[ On fixe la valeur de la vie de l'enemy ]]
                Enemies.curentEnemy.state.life = 0;
                --[[ On change son state dead sur true  ]]
                Enemies.curentEnemy.state.dead = true;
                -- TODO:Rajouter transition
                --[[ On change dénemy ]]

                --[[ rezet value epine hero ]]
                hero.actor.state.epine = 0;
                Tour = 'transition';
                card.clearHand();
                card.tirage(5);

                Enemies.next();

                return;

            end
            --[[ rezet value epine hero ]]
            hero.actor.state.epine = 0;

        end
        --[[ si le hero a une armure superieure ho degats qu'il vas resevoir ]]
        if hero.actor.state.shield >= degat then

            hero.actor.state.shield = hero.actor.state.shield - degat;
            degat = 0;
        else --[[ si les degat est superieure a sont armure  ]]
            degat = degat - hero.actor.state.shield;
            hero.actor.state.shield = 0;
        end
        --[[ On joue l'animation dattack ]]
        effect.play({
            name = 'attack',
            vector2 = {
                x = hero.actor.vector2.x,
                y = hero.actor.vector2.y + (hero.actor.height / 2) - 40
            }
        });
        --[[ On applique les degats ho hero ]]
        hero.actor.state.life = hero.actor.state.life - degat;
        --[[ On verifie si le hero est vivant ]]
        if hero.actor.state.life < 0 then

            hero.actor.state.life = 0;
            hero.actor.state.dead = true;

            Tour = 'GameOver'

        end

        Enemies.isAttack = false;
    end

    if Enemies.timerAttack <= 0 then

        Enemies.timerAttack = Enemies.timerDefautl;
        Enemies.isAttack = true;

        Tour = 'transition';
        card.clearHand();
        card.tirage(5);

        return;
    else
        Enemies.timerAttack = Enemies.timerAttack - delta;
    end

end

function AppliqueDegatToEnemy(p_valueDegats)

    --[[  Si l'armure de acteur qui reçoit les degats a une plus grande
       valeur que les degats subis on deduit les degat de l'armus et mon mest les degat a zero ]]
    if Enemies.curentEnemy.state.shield >= p_valueDegats then

        Enemies.curentEnemy.state.shield = Enemies.curentEnemy.state.shield - p_valueDegats;

        p_valueDegats = 0;
    else
        --[[ si les degat sont superieure a l'armure on deduit de l'attack l'armure 
        est on mais l'armure a zero  ]]
        p_valueDegats = p_valueDegats - Enemies.curentEnemy.state.shield;
        Enemies.curentEnemy.state.shield = 0;
    end
    --[[ On joue une animation dattaque pour signifier que l'enemie ces prie des degats ]]
    effect.play({
        name = 'attack',
        vector2 = {
            x = Enemies.curentEnemy.vector2.x,
            y = Enemies.curentEnemy.vector2.y + (Enemies.curentEnemy.height / 2) - 40
        }
    });
    --[[ on mais a jour les points de vie de l'enemy ]]
    Enemies.curentEnemy.state.life = Enemies.curentEnemy.state.life - p_valueDegats;
end

return ia;
