local action = {};

function action.Apllique(p_card)
    --[[ POWER USE  ]]
    if hero.state.power < p_card.PowerBlowCard then
        return false;
    end
    hero.state.power = hero.state.power - p_card.PowerBlowCard;
    --[[ HERO-HEAL ]]
    if (p_card.effect.Hero.heal ~= nil) then

        hero.state.life = hero.state.life + p_card.effect.Hero.heal;

        if hero.state.life > hero.state.maxLife then

            hero.state.life = hero.state.maxLife;

        end
    end
    --[[ HERO-ARMOR ]]
    if (p_card.effect.Hero.Deffence ~= nil) then

        hero.state.armor = hero.state.armor + p_card.effect.Hero.Deffence;

    end
    --[[ Henemy APlique Degat ]]
    if (p_card.effect.Enemy.Degat ~= nil) then
        
        if(Enemies.state.life >0)then
           
            Enemies.state.life = Enemies.state.life - p_card.effect.Enemy.Degat;
        else
            Enemies.state.Dead = true ;
        end
    end

    return true
end

return action;
