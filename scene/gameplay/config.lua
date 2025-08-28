-- Configuration de la scène gameplay
-- Ce fichier permet d'ajuster le comportement des ennemis et quelques paramètres de jeu
-- Modifiez ces valeurs à runtime si vous voulez des réglages dynamiques.
local enemy = require("ressources.Enemy.EnemySceneDemo")
return {
    enemies = {
        -- Nombre d'ennemis à placer par vague (fallback si spawns non fournis)
        count = 3,

        -- Pool d'identifiants/types d'ennemis (doit correspondre aux ressources / identifiants utilisés)
        -- Ex : noms d'assets ou clés de génération
        pool = { "Enemy-1", "Enemy-2", "Enemy-3", "Enemy-4" },

        -- Positions de spawn (optionnel). Si fourni, la table est itérée et utilisée comme positions fixes.
        -- Format : { {x = 100, y = 120}, {x = 300, y = 120}, ... }
        -- Si nil, la scène peut calculer automatiquement des positions en fonction de l'écran.
        spawns = {
            { x = 1500, y = 600, type = 'monstre' },
            { x = 1420, y = 450, type = 'Humain' },
            { x = 1200, y = 550, type = 'spider' },

        },
        poolEnemies = {
            { id = "Enemy-1", data = enemy[1] },
            { id = "Enemy-2", data = enemy[2] },
            { id = "Enemy-3", data = enemy[3] },
            { id = "Enemy-4", data = enemy[4] },
        },

        -- Options additionnelles pour la génération (facultatif)
        options = {
            allowDuplicates = true, -- autoriser plusieurs ennemis du même type
            shufflePool = true,     -- mélanger la pool avant sélection
        },
    }
}
