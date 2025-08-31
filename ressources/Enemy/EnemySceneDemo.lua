local Enemy = {
    --[[ ENEMY 1 ]]
    {
        name = 'pouplpie',
        type = 'monstre',
        animation = { idle = { 'img/Actor/Enemy/Enemy-1.png' } },
        description = 'Un ennemi qui attaque le joueur avec des projectiles.',
        health = 100,
        damage = 10,
        numberAttack = 1,
        deckName = "Deck de l'ennemi Pouplpie",
        cards = {
            {
                name = 'j\'ais d\'encre',
                ImgIlustration = 'img/cards/Enemy/MonsterAttack.png',
                Description = 'lance une boule d\'encre la ou il vise',
                PowerBlow = 0,
                Rarete = 'commun',
                Type = { 'capacity' },
                Effect = {
                    caster = { heal = 0, shield = 0, Epine = 0, attack = 5, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
                    target = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
                    action = function(target)

                    end
                },
                TextFormatting = {
                    card = {
                        width = 280,  -- Largeur standard de carte Love2D
                        height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                        scale = 1.0   -- Facteur d'échelle
                    },
                    title = {
                        x = 79,
                        y = 45,
                        font = 'Cambria.ttc',
                        size = 16,
                        color = '#000000'
                    },
                    text = {
                        x = 56,
                        y = 306,
                        width = 168,
                        height = 42,
                        font = 'Cambria.ttc',
                        size = 9,
                        color = '#000000',
                        align = 'center',
                        line_spacing = 1.2,
                        wrap = true
                    },
                    energy = {
                        x = 19,
                        y = 26,
                        font = 'Cambria.ttc',
                        size = 11,
                        color = '#FFFFFF'
                    }
                },
                Cards = {}
            },
        }
    },
    --[[ ENEMY 2 ]]
    {
        name = 'Assasin Crue',
        type = 'Humain',
        animation = { idle = { 'img/Actor/Enemy/Enemy-2.png' } },
        description = 'Un ennemi qui attaque le joueur avec des projectiles ou des bombes',
        health = 100,
        damage = 10,
        numberAttack = 1,
        deckName = "Deck de l'ennemi Assasin Crue",
        cards = {
            {
                name = 'j\'ais de couteau',
                ImgIlustration = 'img/cards/Enemy/AssasinAttack.png',
                Description = 'lance des couteaux sur l\'ennemi',
                PowerBlow = 0,
                Rarete = 'commun',
                Type = { 'capacity' },
                Effect = {
                    caster = { heal = 0, shield = 0, Epine = 0, attack = 5, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
                    target = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
                    action = function(target)

                    end
                },
                TextFormatting = {
                    card = {
                        width = 280,  -- Largeur standard de carte Love2D
                        height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                        scale = 1.0   -- Facteur d'échelle
                    },
                    title = {
                        x = 79,
                        y = 45,
                        font = 'Cambria.ttc',
                        size = 16,
                        color = '#000000'
                    },
                    text = {
                        x = 56,
                        y = 306,
                        width = 168,
                        height = 42,
                        font = 'Cambria.ttc',
                        size = 9,
                        color = '#000000',
                        align = 'center',
                        line_spacing = 1.2,
                        wrap = true
                    },
                    energy = {
                        x = 19,
                        y = 26,
                        font = 'Cambria.ttc',
                        size = 11,
                        color = '#FFFFFF'
                    }
                },
                Cards = {}
            },
        }
    },
    --[[ ENEMY 3 ]]
    {
        name = 'Spider',
        type = 'spider',
        animation = { idle = { 'img/Actor/Enemy/Enemy-3.png' } },
        description = 'Un ennemi qui attaque le joueur avec des toiles d\'araignée.',
        health = 100,
        damage = 10,
        numberAttack = 1,
        deckName = "Deck de l'ennemi Spider",
        cards = {
            {
                name = 'Fil d\'Ariane',
                ImgIlustration = 'img/cards/Enemy/spiderAttack.png',
                Description = 'lance une toile d\'araignée là où il vise',
                PowerBlow = 0,
                Rarete = 'commun',
                Type = { 'capacity' },
                Effect = {
                    caster = { heal = 0, shield = 0, Epine = 0, attack = 5, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
                    target = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
                    action = function(target)

                    end
                },
                TextFormatting = {
                    card = {
                        width = 280,  -- Largeur standard de carte Love2D
                        height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                        scale = 1.0   -- Facteur d'échelle
                    },
                    title = {
                        x = 79,
                        y = 45,
                        font = 'Cambria.ttc',
                        size = 16,
                        color = '#000000'
                    },
                    text = {
                        x = 56,
                        y = 306,
                        width = 168,
                        height = 42,
                        font = 'Cambria.ttc',
                        size = 9,
                        color = '#000000',
                        align = 'center',
                        line_spacing = 1.2,
                        wrap = true
                    },
                    energy = {
                        x = 19,
                        y = 26,
                        font = 'Cambria.ttc',
                        size = 11,
                        color = '#FFFFFF'
                    }
                },
                Cards = {}
            },
        }
    }
    ,
    --[[ ENEMY 4 ]]
    {
        name = 'chevalier noir',
        type = 'Humain',
        animation = { idle = { 'img/Actor/Enemy/Enemy-4.png' } },
        description = 'Un ennemi qui attaque le joueur avec une épée.',
        health = 100,
        damage = 10,
        numberAttack = 1,
        deckName = "Deck de l'ennemi Chevalier Noir",
        cards = {
            {
                name = 'Attaque Rapide',
                ImgIlustration = 'img/cards/Enemy/chevalierNoirAttack.png',
                Description = 'Inflige des dégâts rapides à l\'ennemi.',
                PowerBlow = 0,
                Rarete = 'commun',
                Type = { 'capacity' },
                Effect = {
                    caster = { heal = 0, shield = 0, Epine = 0, attack = 5, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
                    target = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
                    action = function(target)

                    end
                },
                TextFormatting = {
                    card = {
                        width = 280,  -- Largeur standard de carte Love2D
                        height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                        scale = 1.0   -- Facteur d'échelle
                    },
                    title = {
                        x = 79,
                        y = 45,
                        font = 'Cambria.ttc',
                        size = 16,
                        color = '#000000'
                    },
                    text = {
                        x = 56,
                        y = 306,
                        width = 168,
                        height = 42,
                        font = 'Cambria.ttc',
                        size = 9,
                        color = '#000000',
                        align = 'center',
                        line_spacing = 1.2,
                        wrap = true
                    },
                    energy = {
                        x = 19,
                        y = 26,
                        font = 'Cambria.ttc',
                        size = 11,
                        color = '#FFFFFF'
                    }
                },
                Cards = {}
            },
        }
    }
}

return Enemy
