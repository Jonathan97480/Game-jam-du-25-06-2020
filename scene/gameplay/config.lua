-- Configuration de la scène gameplay
-- Ce fichier permet d'ajuster le comportement des ennemis et quelques paramètres de jeu
-- Modifiez ces valeurs à runtime si vous voulez des réglages dynamiques.

return {
    enemies = {
        -- Nombre d'ennemis à placer par vague (fallback si spawns non fournis)
        count = 2,

        -- Pool d'identifiants/types d'ennemis (doit correspondre aux ressources / identifiants utilisés)
        -- Ex : noms d'assets ou clés de génération
        pool = { "Enemy-1", "Enemy-2", "Enemy-3", "Enemy-4" },

        -- Positions de spawn (optionnel). Si fourni, la table est itérée et utilisée comme positions fixes.
        -- Format : { {x = 100, y = 120}, {x = 300, y = 120}, ... }
        -- Si nil, la scène peut calculer automatiquement des positions en fonction de l'écran.
        spawns = {
            { x = 1500, y = 600, type = "orc" },
            { x = 1420, y = 450, type = "slime" },
            { x = 1200, y = 550, type = "knightDeath" },
        },

        -- Options additionnelles pour la génération (facultatif)
        options = {
            allowDuplicates = true, -- autoriser plusieurs ennemis du même type
            shufflePool = true,     -- mélanger la pool avant sélection
        },
    },

    -- Paramètres généraux de la scène (exemples)
    gameplay = {
        difficulty = "normal", -- "easy" | "normal" | "hard"
        maxTurns = 50,
    },
}
