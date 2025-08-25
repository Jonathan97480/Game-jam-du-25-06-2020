# Copilot Instructions – Positionnement des fichiers

## Règle principale
Toujours créer les nouveaux fichiers dans le dossier approprié selon leur usage, et **jamais à la racine du projet**.

## Directives de positionnement
- **Scripts de logique de jeu** :
  - Placer dans `my-librairie/` ou un de ses sous-dossiers (ex : `card-librairie/`, `ai/`, `hud/`, `transition/`).
- **Scripts de scènes** :
  - Placer dans `scene/`.
- **Ressources de données (cartes, effets, etc.)** :
  - Placer dans `ressources/`.
- **Images, polices, sons** :
  - Placer dans `img/`, `fonts/`, ou un sous-dossier pertinent.
- **Tests unitaires** :
  - Placer tous les tests unitaires dans le dossier `test/` à la racine du projet (ex : `test/mon_module_test.lua`).
- **Fichiers utilitaires ou librairies** :
  - Placer dans `my-librairie/`.

## Exemples
- Un nouveau script pour gérer un effet de carte → `my-librairie/card-librairie/cardEffect/`
- Un nouveau menu → `scene/menu.lua`
- Un nouveau jeu de données de cartes → `ressources/cards_data_nouveau.lua`

## À éviter
- Ne jamais créer de fichier source, script ou ressource directement à la racine du projet.
- Toujours vérifier la structure existante pour placer le fichier au bon endroit.

## Bonnes pratiques
- Respecter la logique de séparation par fonctionnalité déjà présente dans le projet.
- Si un nouveau type de fichier ou de fonctionnalité apparaît, créer un sous-dossier dédié dans la structure existante.

---

**Résumé :**
> Pour toute création de fichier, identifier le dossier thématique adapté et y placer le fichier, jamais à la racine.
