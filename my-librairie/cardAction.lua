local action = {};
local listeAction = {};
local ongoingAction = false;

function action.Apllique(p_card)
    --[[ POWER USE  ]]

    if hero.actor.state.power < p_card.PowerBlowCard then
        return false;
    end
    table.insert(listeAction, p_card);
    return true
end

function action.update()

    if ongoingAction == false and listeAction[1]~=nil and effect.efect.attack.isplay==false then

        ongoingAction = true;
        action.play(listeAction[1])

    end

end

function action.play(p_card)

    hero.actor.state.power = hero.actor.state.power - p_card.PowerBlowCard;
    --[[ HERO-HEAL ]]
    if (p_card.effect.Hero.heal ~= nil) then

        hero.actor.state.life = hero.actor.state.life + p_card.effect.Hero.heal;

        if hero.actor.state.life > hero.actor.state.maxLife then

            hero.actor.state.life = hero.actor.state.maxLife;

        end
    end
    --[[ HERO-ARMOR ]]
    if (p_card.effect.Hero.Deffence ~= nil) then

        hero.actor.state.armor = hero.actor.state.armor + p_card.effect.Hero.Deffence;

    end
    --[[ Henemy APlique Degat ]]
    if p_card.effect.Enemy.Degat ~= nil then

        local degat = p_card.effect.Enemy.Degat;

        if Enemies.curentEnemy.state.armor > degat then

            Enemies.curentEnemy.state.armor = Enemies.curentEnemy.state.armor - degat;
            degat = 0;
        else
            degat = degat - Enemies.curentEnemy.state.armor;
            Enemies.curentEnemy.state.armor = 0;
        end
        effect.efect.attack.vector2.x = Enemies.curentEnemy.vector2.x
        effect.efect.attack.vector2.y = Enemies.curentEnemy.vector2.y + (Enemies.curentEnemy.height / 2) - 40

        effect.efect.attack.speed = 0.1;
        effect.efect.attack.isplay = true
        Enemies.curentEnemy.state.life = Enemies.curentEnemy.state.life - degat;

        if Enemies.curentEnemy.state.life <= 0 then
            Enemies.curentEnemy.state.dead = true;
            Enemies.curentEnemy.state.life = 0;
        end

    end

    table.remove(listeAction, 1);
    ongoingAction = false;
end
return action;
