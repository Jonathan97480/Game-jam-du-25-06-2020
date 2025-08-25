-- my-librairie/card-librairie/card.lua
-- Façade : regroupe les sous-modules et expose une API compatible.

local Common                      = require("my-librairie/card-librairie/common")
local Generator                   = require("my-librairie/card-librairie/generator")
local Player                      = require("my-librairie/card-librairie/player_ops")

local Card                        = {}
-- Assure l’existence d’une main IA
Card.handAi                       = Card.handAi or {}

-- Etats exposés (références directes)
Card.deck                         = Common.deck
Card.deckAi                       = Common.deckAi
Card.globalDeck                   = Common.globalDeck
Card.hand                         = Common.hand
Card.graveyard                    = Common.graveyard

-- Constantes/params
Card.DEFAULT_COPIES               = Common.DEFAULT_COPIES

-- ----- API génération / chargement -----
Card.loadCards                    = Generator.loadCards

-- ----- Tirage / decks -----
Card.shuffle                      = Common.shuffle
Card.shuffleDeck                  = Common.shuffleDeck
Card.MoveCardNumberCardDeckToDeck = Common.MoveCardNumberCardDeckToDeck
Card.createDeck                   = Common.createDeck
Card.getDeckByName                = Common.getDeckByName
Card.tirage                       = Common.tirage

-- >>> Expose clearHand
Card.clearHand                    = Player.clearHand
Card.clearHandPlayer              = Player.clearHandPlayer
Card.clearHandEnemy               = Player.clearHandEnemy

-- ----- Deck Global -----
Card.globalDeckList               = Common.globalDeckList
Card.addToGlobal                  = Common.addToGlobal
Card.copyToGlobal                 = Common.copyToGlobal
Card.addFromGlobalToDeck          = Common.addFromGlobalToDeck

-- ----- Affichages / accès -----
Card.draw                         = Player.drawHand
Card.drawHand                     = Player.drawHand
Card.hover                        = Player.hover
Card.displayDeck                  = Common.displayDeck
Card.deckList                     = Common.deckList
Card.handList                     = Common.handList
Card.graveyardList                = Common.graveyardList

-- ----- Actions / update -----
Card.action                       = Player.action
Card.update                       = Player.action.update

-- ----- Helpers layout (si utilisés autre part) -----
Card._computeSlot                 = Common._computeSlot
Card._updateHandTargets           = Common._updateHandTargets

-- ----- Compat helpers (Card.func.*) -----
Card.func                         = Player.func
Card.onTurnChanged                = Player.onTurnChanged
Card.resetInteractions            = Player.resetInteractions
Card.positionHand                 = Player.positioneHand
Card.positioneHand                = Player.positioneHand
Card.cardToGraveyard              = Player.cardToGraveyard
Card.graveyardToDeckPlayer        = Common.graveyardToDeckPlayer

-- Expose globalement
rawset(_G, "card", Card)
rawset(_G, "Card", Card)

return Card
