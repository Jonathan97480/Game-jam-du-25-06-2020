-- my-librairie/card-librairie/card.lua
-- Façade : regroupe les sous-modules et expose une API compatible.

local Common                      = require("my-librairie/card-librairie/core/common")
local Generator                   = require("my-librairie/card-librairie/core/generator")
local UX                          = require("my-librairie/card-librairie/ui/ux")
local Interaction                 = require("my-librairie/card-librairie/ui/interaction")
local Play                        = require("my-librairie/card-librairie/play/play")
local Layout                      = require("my-librairie/card-librairie/ui/layout")
local Anim                        = require("my-librairie/card-librairie/play/anim")

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
Card.clearHand                    = Play.clearHand
Card.clearHandPlayer              = Play.clearHandPlayer
Card.clearHandEnemy               = Play.clearHandEnemy

-- ----- Deck Global -----
Card.globalDeckList               = Common.globalDeckList
Card.addToGlobal                  = Common.addToGlobal
Card.copyToGlobal                 = Common.copyToGlobal
Card.addFromGlobalToDeck          = Common.addFromGlobalToDeck

-- ----- Affichages / accès -----
Card.draw                         = Play.drawHand
Card.drawHand                     = Play.drawHand
Card.hover                        = Interaction.hover
Card.displayDeck                  = Common.displayDeck
Card.deckList                     = Common.deckList
Card.handList                     = Common.handList
Card.graveyardList                = Common.graveyardList

-- ----- Actions / update -----
Card.action                       = Play.action
Card.update                       = Play.action.update

-- ----- Helpers layout (si utilisés autre part) -----
Card._computeSlot                 = Common._computeSlot
Card._updateHandTargets           = Common._updateHandTargets

-- ----- Compat helpers (Card.func.*) -----
Card.func                         = Play.func
Card.onTurnChanged                = Interaction.onTurnChanged
Card.resetInteractions            = Interaction.resetInteractions
Card.positionHand                 = Layout.positionHand
Card.cardToGraveyard              = Play.cardToGraveyard
Card.graveyardToDeckPlayer        = Common.graveyardToDeckPlayer
-- compatibility: expose tryPlay
Card.tryPlay                      = Play.tryPlay

-- Expose sub-modules (refactor aide)
Card.UX                           = UX
Card.Interaction                  = Interaction
Card.Play                         = Play
Card.Layout                       = Layout
Card.Anim                         = Anim

-- Expose globalement
rawset(_G, "card", Card)
rawset(_G, "Card", Card)

return Card
