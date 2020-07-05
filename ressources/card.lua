local Cards = {
    --[[ CARTE 1 ]]
    {
        name = 'Prayer of the two sisters',
        ImgIlustration = 'img/card/ilustration/Prayer of the two sisters.png',
        Description = 'If you have double\nthis card in your deck\nyoudraw a random\ncard inside',
        PowerBlow = 0,
        Effect = {
            Hero = {},
            Enemy = {
                attack = 2
            },
            Deck = {
                CheckCard = 'Prayer of the two sisters',
                GiveRandomCard = true

            },
            Graveyard = {},
            Hand = {}

        },
        Cards = {}
    },
    --[[ CARTE 2 ]]
    {
        name = 'Double flick',
        ImgIlustration = 'img/card/ilustration/Double flick.png',
        Description = 'This card does 5\ndamage and reduces\nthe damage of the next\nattack enemy by 25%\n if its twin is present\nin your hand.',
        PowerBlow = 3,
        Effect = {
            Hero = {},
            Enemy = {
                attack = 5,
                AttackReduction = 25
            },
            Deck = {},
            Graveyard = {},
            Hand = {
                playCard = 'Double flick'
            }

        },
        Cards = {}
    },
    --[[ CARTE 3 ]]
    {
        name = 'You plus me',
        ImgIlustration = 'img/card/ilustration/You plus me.png',
        Description = 'If his twin is in your\nhand, play it for free',
        PowerBlow = 4,
        Effect = {
            Hero = {
                heal = 10
            },
            Enemy = {},
            Deck = {},
            Graveyard = {},
            Hand = {
                playCard = 'You plus me'
            }

        },
        Cards = {}
    },
    --[[ CARTE 4 ]]
    {
        name = 'Thorn shield',
        ImgIlustration = 'img/card/ilustration/Thorn shield.png',
        Description = 'If his twin sister is\nin the cemetery double\neffect of the card',
        PowerBlow = 3,
        Effect = {
            Hero = {
                Epine = 50,
                shield = 8
            },
            Enemy = {},
            Deck = {},
            Graveyard = {
                CheckCard = 'Thorn shield'
            },
            Hand = {}

        },
        Cards = {}
    },
    --[[ CARTE 5 ]]
    {
        name = 'See you tomorrow',
        ImgIlustration = 'img/card/ilustration/See you tomorrow.png',
        Description = 'gives you a 25% chance\nthat the enemy will pass\nand if his twin sister is in\nyour hand gives you 50%\nand plays it for free',
        PowerBlow = 2,
        Effect = {
            Hero = {},
            Enemy = {
                chancePassedTour = 25
            },
            Deck = {},
            Graveyard = {},
            Hand = {
                playCard = 'See you tomorrow'
            }

        },
        Cards = {}
    },
    --[[ CARTE 6 ]]
    {
        name = 'A',
        ImgIlustration = 'img/card/ilustration/A.png',
        Description = 'Deals 10 damage and\n if his twinsister is in\n your deck draw it\nand put it in your hand',
        PowerBlow = 1,
        Effect = {
            Hero = {},
            Enemy = {
                attack = 10
            },
            Deck = {

                GiveCard = 'A'
            },
            Graveyard = {},
            Hand = {},
            Cards = {}

        },

    },
    --[[ CARTE 7 ]]
    {
        name = 'It will sting',
        ImgIlustration = 'img/card/ilustration/It will sting.png',
        Description = 'If his twin sister is in\nthe graveyard transfer all\nthe cards to your deck then\nplace card A in your hand',
        PowerBlow = 3,
        Effect = {
            Hero = {},
            Enemy = {},
            Deck = {
                GiveCard = 'A'
            },
            Graveyard = {
                GiveCard = 'A',
                CheckCard = 'It will sting',
                tranfertAlllToDeck = true
            },
            Hand = {},
            Cards = {}

        },

        Cards = {
            
        }
    },
    --[[ CARTE 8 ]]
    {
        name = 'Help my friend',
        ImgIlustration = 'img/card/ilustration/Help my friend.png',
        Description = 'Gives you 4 armor but\nif his twin sister is in\nyour graveyard will\ngive you 8',
        PowerBlow = 2,
        Effect = {
            Hero = {
                shield = 4
            },
            Enemy = {
                
            },
            Deck = {},
            Graveyard = {
                CheckCard = 'Help my friend'
            },
            Hand = {
               
            },
            Cards = {
                DoublePower = true
            }

        },

    }

}

return Cards

--[[ 
Hero={
    Attack =0,
    shield =0,
    power =0,
    heal =0,
    PowerReductionBlow = 0,
    Epine = false,
    CardPowerUp =0,

},
Enemy={
    reductattackEnemy =0,
    EnemyPassTour= false
},
Deck={
    GiveRandomCard = false,
    GiveCard =''

},
Graveyard={

    tranfertAlllToDeck = false,
    GiveRandomCard = false,
    GiveCard =''

},
Hand={
    playcard ='',
    reduceCardBlow =0

} ]]
