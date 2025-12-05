# Idle Kingdom Defense

Un jeu hybride **Idle / Tower Defense** basé sur le Game Design Document fourni.

## Concept

Défendez votre château, automatisez votre production de ressources, et étendez votre territoire pour survivre aux vagues d'ennemis !

**Hook:** "Défendez, Automatisez, Étendez-vous. Si vous tombez, relevez-vous plus fort."

## Comment Jouer

### Phase 1: Collecte & Gestion (Le Calme)
- **Cliquez sur les ressources** qui apparaissent autour du château (cercles dorés, bruns ou gris)
- **Collectez 3 types de ressources:**
  - Or (jaune/doré)
  - Bois (brun)
  - Pierre (gris)
- Les ressources disparaissent après 10 secondes si non collectées

### Phase 2: Construction
- Utilisez le **panneau de construction** (gauche de l'écran)
- **Bâtiments disponibles:**
  - **Mine:** Génère de l'or automatiquement
  - **Scierie:** Génère du bois automatiquement
  - **Marché:** Génère de l'or bonus

### Phase 3: Défense (La Tempête)
- Toutes les **3 minutes**, une vague d'ennemis attaque
- Le **château tire automatiquement** sur les ennemis à portée
- **Survivez** pour gagner des récompenses et continuer
- Si le château tombe à 0 PV, c'est le Game Over

### Phase 4: Expansion (À venir)
- Système de chunks de terrain pour s'étendre
- Achat de nouveaux territoires
- Découverte de points d'intérêt

## Interface

### En Haut
- **Barre de ressources:** Or, Bois, Pierre (avec génération passive)
- **Numéro de vague** et timer avant la prochaine
- **Barre de vie du château**

### À Gauche
- **Panneau de construction** avec les bâtiments disponibles

### En Bas
- **Messages d'information** (vagues, notifications)

## Mécaniques Implémentées

✅ Système de ressources (Or, Bois, Pierre)
✅ Ressources cliquables qui apparaissent aléatoirement
✅ Château défensif avec attaque automatique
✅ Système de vagues d'ennemis
✅ Ennemis avec pathfinding vers le château
✅ Bâtiments de production automatique
✅ UI dynamique avec affichage des ressources
✅ Game Manager global (autoload)

## À Implémenter (Prochaines Étapes)

⬜ Système de grille et expansion de territoire (chunks)
⬜ Système de races (Humains, Orcs, Elfes, Nains)
⬜ Héros avec compétences actives
⬜ Système de Prestige / Skill Tree
⬜ Tours défensives
⬜ Améliorations de bâtiments
⬜ Améliorations du château
⬜ Boss et piliers de l'ennemi
⬜ Système de sauvegarde

## Raccourcis Clavier (Futurs)

- **A, Z, E:** Sorts du héros (quand implémenté)
- **Espace:** Pause
- **Molette:** Zoom de la caméra

## Technologies

- **Moteur:** Godot 4.5
- **Langage:** GDScript
- **Plateforme:** PC / Mobile

## Comment Lancer

1. Ouvrez le projet dans **Godot 4.5**
2. Appuyez sur **F5** ou cliquez sur "Lancer le projet"
3. Cliquez sur les ressources pour commencer à collecter !

## Crédits

Basé sur le Game Design Document "Idle Kingdom Defense"
Développé avec Godot Engine
