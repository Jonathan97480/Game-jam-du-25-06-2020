-- ressources/cardsIA.lua
local CardsIA = {
    -- 1) ATTAQUE légère
    {
        name = 'Entaille',
        ImgIlustration = 'img/cards/CardTheme/decoration.png',
        Description = 'Inflige 8 points de dégâts au héros.',
        PowerBlow = 1,
        Effect = {
            hero   = { attack = 8 },
            enemy  = {},
            action = function() end
        },
        Cards = {}
    },

    -- 2) ATTAQUE lourde
    {
        name = 'Écrasément',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = 'Inflige 12 points de dégâts au héros.',
        PowerBlow = 2,
        Effect = {
            hero   = { attack = 12 },
            enemy  = {},
            action = function() end
        },
        Cards = {}
    },

    -- 3) Soin pur
    {
        name = 'Récupération',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = "Soigne l'ennemi de 10 points de vie.",
        PowerBlow = 2,
        Effect = {
            hero   = {},
            enemy  = { heal = 10 },
            action = function() end
        },
        Cards = {}
    },

    -- 4) Bouclier pur
    {
        name = 'Parade renforcée',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = 'Octroie 6 points de bouclier à l’ennemi.',
        PowerBlow = 1,
        Effect = {
            hero   = {},
            enemy  = { shield = 6 },
            action = function() end
        },
        Cards = {}
    },

    -- 5) Mix : Soin + Bouclier
    {
        name = 'Second souffle',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = 'Soigne 6 PV et octroie 4 de bouclier à l’ennemi.',
        PowerBlow = 2,
        Effect = {
            hero   = {},
            enemy  = { heal = 6, shield = 4 },
            action = function() end
        },
        Cards = {}
    },

    -- 6) Mix : Épines + Bouclier
    {
        name = 'Peau épineuse',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = 'Octroie 5 de bouclier et 30 épines à l’ennemi.',
        PowerBlow = 2,
        Effect = {
            hero   = {},
            enemy  = { shield = 5, Epine = 30 }, -- note: clé normalisée plus bas -> epine
            action = function() end
        },
        Cards = {}
    },

    -- 7) ATTAQUE + réduction des dégâts du héros
    {
        name = 'Coup de jarret',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = "Inflige 5 dégâts et réduit la prochaine attaque du héros de 25%.",
        PowerBlow = 2,
        Effect = {
            hero   = { attack = 5, AttackReduction = 25 }, -- si ton moteur ne gère pas AttackReduction, garde tel quel
            enemy  = {},
            action = function() end
        },
        Cards = {}
    },

    -- 8) Vol de vie (ATK + Soin ennemi)
    {
        name = 'Frappe siphon',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = "Inflige 6 dégâts au héros et soigne l’ennemi de 6.",
        PowerBlow = 2,
        Effect = {
            hero   = { attack = 6 },
            enemy  = { heal = 6 },
            action = function() end
        },
        Cards = {}
    },

    -- 9) Bouclier fort
    {
        name = 'Rempart',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = "Octroie 10 points de bouclier à l’ennemi.",
        PowerBlow = 2,
        Effect = {
            hero   = {},
            enemy  = { shield = 10 },
            action = function() end
        },
        Cards = {}
    },

    -- 10) Mix : Petit bouclier + petite attaque
    {
        name = 'Coup de bouclier',
        ImgIlustration = 'img/card/CardTheme/decoration.png',
        Description = "Inflige 4 dégâts et octroie 3 de bouclier à l’ennemi.",
        PowerBlow = 1,
        Effect = {
            hero   = { attack = 4 },
            enemy  = { shield = 3 },
            action = function() end
        },
        Cards = {}
    },
}

--------------------------------------------------------------------
-- Normalisation pour l’IA :
--  - c.cost        = alias de PowerBlow (nombre)
--  - c.actorTag    = "Enemy" (utile si le moteur l’utilise)
--  - c.effects     = alias normalisé de Effect/effect
--  - Garantit c.effects.hero / c.effects.enemy comme tables
--  - Normalise 'Epine' -> 'epine'
--  - (alias) c.onPlay depuis Effect.action si présent
--  - (alias) c.description / c.illustration
--------------------------------------------------------------------
--[[ for _, c in ipairs(CardsIA) do
    -- coût
    c.cost     = tonumber(c.cost or c.PowerBlow) or 0

    -- tag de l'acteur (pratique si lu par le moteur)
    c.actorTag = c.actorTag or "Enemy"

    -- structure d'effets (le moteur attend souvent 'effects')
    local eff  = c.effects or c.effect or c.Effect or {}
    eff.hero   = eff.hero or eff.Hero or {}
    eff.enemy  = eff.enemy or eff.Enemy or {}

    -- normalisation 'Epine' -> 'epine'
    if eff.enemy.Epine and eff.enemy.epine == nil then
        eff.enemy.epine = eff.enemy.Epine
        eff.enemy.Epine = nil
    end
    if eff.hero.Epine and eff.hero.epine == nil then
        eff.hero.epine = eff.hero.Epine
        eff.hero.Epine = nil
    end

    -- écrire dans le champ pluriel lu par l'IA
    c.effects      = eff
    -- garder aussi l'alias singulier si d'autres morceaux du code y accèdent
    c.effect       = eff

    -- alias d'illustration/description
    c.description  = c.description or c.Description
    c.illustration = c.illustration or c.ImgIlustration or c.ImgIllustration

    -- alias d'onPlay depuis Effect.action (si ton moteur l'utilise)
    if not c.onPlay and c.Effect and type(c.Effect.action) == "function" then
        c.onPlay = c.Effect.action
    end
end ]]

return CardsIA
