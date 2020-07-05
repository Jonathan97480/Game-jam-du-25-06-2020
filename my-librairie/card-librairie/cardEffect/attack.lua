local attack = {}

attack.applique = function(p_card, p_actorA, p_actorB, p_value)
    --[[ p_ActorA est ce lui qui attack et
        p_AttorB est xe lui la reçoit 
        p_value la valeur des degats aplliquer 
        p_card la carte utiliser  ]]
    local attackValue = p_value;

    --[[  Si l'armure de acteur qui reçoit les degats a une plus grnade
       valeur que les degats subis on deduit les degat de l'armus et mon mest les degat a zero ]]
    if p_actorB.state.shield >= attackValue then

        p_actorB.state.shield = p_actorB.state.shield - attackValue;

        attackValue = 0;
    else 
        --[[ si les degat sont superieure a l'armure on deduit de l'attack l'armure 
        est on mais l'armure a zero  ]]
        attackValue = attackValue - p_actorB.state.shield;
        p_actorB.state.shield = 0;
    end

    --[[ TODO:Play animation Attack  ]]
    p_actorA.animation.playAction('attack', attackValue,p_actorB);

end

return attack;
