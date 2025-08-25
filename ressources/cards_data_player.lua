local cards = {
    --[[ CARTE 1 - 🎮 Joueur ]]
    {
        name = 'A demain',
        ImgIlustration = 'img/cards/carte_001.png',
        Description =
        'Donne 25% de chance que lennemi passe son tour. Si sa jumelle est dans votre main, +25% et la jouer gratuitement.',
        PowerBlow = 2,
        Rarete = 'commun',
        Type = {},
        Effect = {
            Actor = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 25, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                -- Aucune action spécifiée
            end
        },
        TextFormatting = {
            card = {
                width = 280,  -- Largeur standard de carte Love2D
                height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                scale = 1.0   -- Facteur d'échelle
            },
            title = {
                x = 93,
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

    --[[ CARTE 2 - 🎮 Joueur ]]
    {
        name = 'Coup puissant',
        ImgIlustration = 'img/cards/carte_002.png',
        Description = 'Inflige 12 degats.',
        PowerBlow = 2,
        Rarete = 'commun',
        Type = { 'attaque' },
        Effect = {
            Actor = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 12, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                -- Aucune action spécifiée
            end
        },
        TextFormatting = {
            card = {
                width = 280,  -- Largeur standard de carte Love2D
                height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                scale = 1.0   -- Facteur d'échelle
            },
            title = {
                x = 74,
                y = 45,
                font = 'Cambria.ttc',
                size = 15,
                color = '#000000'
            },
            text = {
                x = 56,
                y = 315,
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

    --[[ CARTE 3 - 🎮 Joueur ]]
    {
        name = 'Aide moi mon ami',
        ImgIlustration = 'img/cards/carte_003.png',
        Description = 'Donne 4 de bouclier. Si sa jumelle est au cimetiere, donne 8 au total.',
        PowerBlow = 0,
        Rarete = 'commun',
        Type = { 'defense', 'carte_jumelle' },
        Effect = {
            Actor = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 4, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                local numberCard = Card.func.find('Aide mon ami', Card.graveyard)
                if numberCard ~= 0 and _user and _user.actor and _user.actor.state then
                    _user.actor.state.shield = (_user.actor.state.shield or 0) + 4
                end
            end
        },
        TextFormatting = {
            card = {
                width = 280,  -- Largeur standard de carte Love2D
                height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                scale = 1.0   -- Facteur d'échelle
            },
            title = {
                x = 76,
                y = 48,
                font = 'Cambria.ttc',
                size = 11,
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

    --[[ CARTE 4 - 🎮 Joueur ]]
    {
        name = 'Bouclier depines',
        ImgIlustration = 'img/cards/carte_004.png',
        Description = 'Si sa jumelle est au cimetierre, double l effet de la carte.',
        PowerBlow = 4,
        Rarete = 'commun',
        Type = { 'defense', 'carte_jumelle' },
        Effect = {
            Actor = { heal = 0, shield = 8, Epine = 50, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                local numberCard = Card.func.find('Bouclier depines', Card.graveyard)
                if numberCard ~= 0 and _user and _user.actor and _user.actor.state then
                    _user.actor.state.epine  = (_user.actor.state.epine or 0) + 50
                    _user.actor.state.shield = (_user.actor.state.shield or 0) + 8
                end
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
                size = 13,
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

    --[[ CARTE 5 - 🎮 Joueur ]]
    {
        name = 'Griffure',
        ImgIlustration = 'img/cards/carte_005.png',
        Description = 'Inflige 8 degats.',
        PowerBlow = 2,
        Rarete = 'commun',
        Type = { 'attaque' },
        Effect = {
            Actor = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 8, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                -- Aucune action spécifiée
            end
        },
        TextFormatting = {
            card = {
                width = 280,  -- Largeur standard de carte Love2D
                height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                scale = 1.0   -- Facteur d'échelle
            },
            title = {
                x = 103,
                y = 45,
                font = 'Cambria.ttc',
                size = 16,
                color = '#000000'
            },
            text = {
                x = 56,
                y = 316,
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

    --[[ CARTE 6 - 🎮 Joueur ]]
    {
        name = 'Ca va piquer',
        ImgIlustration = 'img/cards/carte_006.png',
        Description =
        'Si sa jumelle est au cimetiere, renvoyer toutes les cartes du cimetiere dans le deck puis mettre une carte A dans votre main.',
        PowerBlow = 6,
        Rarete = 'commun',
        Type = { 'soutien', 'carte_jumelle' },
        Effect = {
            Actor = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                if Card.func.find('Ca va piquer', Card.graveyard) ~= 0 then
                    Card.func.graveyardToMove('all', Card.deck)
                    local numberCard = Card.func.find('A', Card.deck)
                    if numberCard ~= 0 then
                        Card.func.moveTo(Card.deck, numberCard, Card.hand)
                        Card.positioneHand()
                    end
                end
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

    --[[ CARTE 7 - 🎮 Joueur ]]
    {
        name = 'Toi et moi',
        ImgIlustration = 'img/cards/carte_007.png',
        Description = 'Soigne 10 PV. Si sa jumelle est dans votre main, la jouer gratuitement.',
        PowerBlow = 4,
        Rarete = 'commun',
        Type = { 'soin', 'carte_jumelle' },
        Effect = {
            Actor = { heal = 10, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 0, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                local numberCard = Card.func.find('Toi et moi', Card.hand)
                if numberCard ~= 0 then
                    Card.func.playCardInTheHand(numberCard, 0)
                end
            end
        },
        TextFormatting = {
            card = {
                width = 280,  -- Largeur standard de carte Love2D
                height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                scale = 1.0   -- Facteur d'échelle
            },
            title = {
                x = 87,
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

    --[[ CARTE 8 - 🎮 Joueur ]]
    {
        name = 'Double frappe',
        ImgIlustration = 'img/cards/carte_008.png',
        Description =
        'Inflige 5 degats et reduit les degats de la prochaine attaque ennemie de 25%. Si sa jumelle est dans votre main,la jouer gratuitement.',
        PowerBlow = 3,
        Rarete = 'commun',
        Type = { 'attaque', 'carte_jumelle' },
        Effect = {
            Actor = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 5, AttackReduction = 25, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                local numberCard = Card.func.find('Double frappe', Card.hand)
                if numberCard ~= 0 then
                    Card.func.playCardInTheHand(numberCard, 0)
                end
            end
        },
        TextFormatting = {
            card = {
                width = 280,  -- Largeur standard de carte Love2D
                height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                scale = 1.0   -- Facteur d'échelle
            },
            title = {
                x = 71,
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

    --[[ CARTE 9 - 🎮 Joueur ]]
    {
        name = 'Deux soeurs',
        ImgIlustration = 'img/cards/carte_009.png',
        Description = 'Si vous avez un double de cette carte dans votre deck, piochez une carte aleatoire du deck.',
        PowerBlow = 0,
        Rarete = 'commun',
        Type = { 'carte_jumelle' },
        Effect = {
            Actor = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 2, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                -- y a-t-il AU MOINS une autre "Deux soeurs" dans le deck ?
                local hasTwinInDeck = false
                for i = 1, #Card.deck do
                    local c = Card.deck[i]
                    if c and c.name == 'Deux soeurs' then
                        hasTwinInDeck = true
                        break
                    end
                end
                if hasTwinInDeck and #Card.deck > 0 then
                    local idx = love.math.random(1, #Card.deck)
                    Card.func.moveTo(Card.deck, idx, Card.hand)
                    Card.positioneHand()
                end
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

    --[[ CARTE 10 - 🎮 Joueur ]]
    {
        name = 'A',
        ImgIlustration = 'img/cards/carte_010.png',
        Description = 'Inflige 10 degats. Si sa jumelle est dans votre deck, piochez-la et mettez-la dans votre main.',
        PowerBlow = 1,
        Rarete = 'commun',
        Type = { 'attaque', 'carte_jumelle' },
        Effect = {
            Actor = { heal = 0, shield = 0, Epine = 0, attack = 0, AttackReduction = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            Enemy = { heal = 0, attack = 10, AttackReduction = 0, Epine = 0, shield = 0, shield_pass = 0, bleeding = { value = 0, number_turns = 0 }, force_augmented = { value = 0, number_turns = 0 }, chancePassedTour = 0, energyCostIncrease = 0, energyCostDecrease = 0 },
            action = function()
                local idx = Card.func.find('A', Card.deck)
                if idx ~= 0 then
                    Card.func.moveTo(Card.deck, idx, Card.hand)
                    Card.positioneHand()
                end
            end
        },
        TextFormatting = {
            card = {
                width = 280,  -- Largeur standard de carte Love2D
                height = 392, -- Hauteur standard de carte Love2D (ratio 5:7)
                scale = 1.0   -- Facteur d'échelle
            },
            title = {
                x = 135,
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
    }
}

return cards
