local ia ={};

function ia.playTour()

    if (math.random(20, 50) < Enemies.curentEnemy.state.chancePassTour) then

        Tour = 'transition';

        card.clearHand();
        card.tirage(5);

        print('Enemy a passer son tour ')

        Enemies.curentEnemy.state.chancePassTour = 0;

        return;

    elseif Enemies.isAttack then

        local shield = math.random(1, 10);
        
        if shield > 2 and shield <= 4 then
            --[[ TODO:ANIMATION GIVE SHIELD ]]
            Enemies.curentEnemy.state.shield = math.random(10, 30);
            Enemies.isAttack = false;
        else
            --[[ Ramdon degat Enemy select ]]
            local degat = love.math.random(20, 30);
            --[[ check is hero have Epine ]]
            if hero.actor.state.epine > 0 then

                local division = (hero.actor.state.epine / 100)
                print('DIVISION: '..division..' \nEPINE:'..hero.actor.state.epine );
                local renvoi = hero.actor.state.shield * division;

                effect.play({
                    name = 'attack',
                    vector2 = {
                        x = Enemies.curentEnemy.vector2.x,
                        y = Enemies.curentEnemy.vector2.y + (Enemies.curentEnemy.height / 2) - 40
                    }
                });
                Enemies.curentEnemy.state.life = Enemies.curentEnemy.state.life - renvoi;
                if Enemies.curentEnemy.state.life <= 0 then
                    Enemies.curentEnemy.state.life = 0;
                    Enemies.curentEnemy.state.dead = true;
                    print(Enemies.curentEnemy.name..' est mort suite a des degat Epine de '..renvoi);
                    Enemies.next();
                    print('On change denemie');
                end
                --[[ rezet value epine hero ]]
                hero.actor.state.epine = 0;
                print(Enemies.curentEnemy.name..' a reçu des degat de Epine dune valeur de '..renvoi);
            end
            if hero.actor.state.shield >= degat then

                hero.actor.state.shield = hero.actor.state.shield - degat;
                degat = 0;
            else
                degat = degat - hero.actor.state.shield;
                hero.actor.state.shield = 0;
            end

            --[[ TODO:ANIMATION DE LATTACK ]]
            effect.play({
                name = 'attack',
                vector2 = {
                    x = hero.actor.vector2.x,
                    y = hero.actor.vector2.y + (hero.actor.height / 2) - 40
                }
            });
            hero.actor.state.life = hero.actor.state.life - degat;
            print(hero.actor.name..' a reçu '..degat..' venent de '..Enemies.curentEnemy.name);
            if hero.actor.state.life < 0 then

                hero.actor.state.life = 0;
                hero.actor.state.dead = true;
                print(hero.actor.name..' est mort');
            end

            Enemies.isAttack = false;
        end
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


return ia;