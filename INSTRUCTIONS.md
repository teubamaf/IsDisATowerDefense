# Instructions de Test et Développement

## Lancer le Jeu

1. Ouvrez **Godot 4.5**
2. Cliquez sur "Importer" et sélectionnez le fichier `project.godot` dans ce dossier
3. Une fois le projet ouvert, appuyez sur **F5** pour lancer le jeu

## Tests à Effectuer

### Test 1: Collecte de Ressources
✅ Des ressources (cercles colorés) apparaissent autour du château
✅ Cliquer sur une ressource l'ajoute à vos réserves
✅ Les ressources disparaissent après 10 secondes
✅ Les compteurs de ressources en haut s'actualisent

### Test 2: Timer de Vagues
✅ Le timer en haut compte à rebours depuis 3:00
✅ À 0:00, des ennemis apparaissent
✅ Le message "Vague X commence !" s'affiche

### Test 3: Combat
✅ Les ennemis se déplacent vers le château
✅ Le château tire automatiquement sur les ennemis à portée
✅ Les ennemis attaquent le château quand ils sont proches
✅ La barre de vie du château diminue
✅ Quand un ennemi meurt, il donne de l'or

### Test 4: UI
✅ Les compteurs de ressources s'affichent correctement
✅ La barre de vie du château change de couleur (vert > jaune > rouge)
✅ Les messages d'information apparaissent en bas

## Problèmes Connus et Solutions

### Si les ennemis n'apparaissent pas:
- Vérifiez que le WaveManager a bien la référence à Enemy.tscn
- Ouvrez Game.tscn dans l'éditeur et vérifiez la propriété enemy_scene

### Si les ressources ne spawent pas:
- Vérifiez que ResourceSpawner a bien la référence à CollectableResource.tscn
- Ouvrez Game.tscn et vérifiez la propriété resource_scene

### Si le château ne tire pas:
- Vérifiez les groupes : le château doit être dans le groupe "castle"
- Les ennemis doivent être dans le groupe "enemies"

## Prochaines Fonctionnalités à Implémenter

### Priorité Haute
1. **Placement de bâtiments**
   - Système de drag & drop depuis le panneau
   - Zones de placement valides
   - Coût en ressources

2. **Amélioration du château**
   - Boutons pour augmenter PV, Dégâts, Portée
   - Coûts progressifs

3. **Système de races**
   - Écran de sélection au démarrage
   - Application des bonus raciaux

### Priorité Moyenne
4. **Héros et Taverne**
   - Construction de la Taverne
   - Recrutement de héros
   - Sorts actifs avec cooldowns

5. **Système de grille (Chunks)**
   - Déblocage de nouveaux terrains
   - Slots de construction par chunk

6. **Prestige / Skill Tree**
   - Écran de Game Over avec calcul d'Âmes
   - Arbre de compétences permanent
   - Bonus progressifs

### Priorité Basse
7. **Améliorations visuelles**
   - Sprites et animations
   - Effets de particules
   - Sons et musique

8. **Sauvegarde**
   - Système de save/load
   - Progression persistante

## Architecture du Code

### Singleton Global
- **GameManager.gd** : Gère les ressources, vagues, stats du château

### Scènes Principales
- **Game.tscn** : Scène principale, assemble tous les éléments
- **Castle.tscn** : Le château défensif
- **Enemy.tscn** : Ennemis de base
- **CollectableResource.tscn** : Ressources cliquables
- **Building.tscn** : Bâtiments de production
- **GameUI.tscn** : Interface utilisateur

### Scripts Utilitaires
- **WaveManager.gd** : Gère le spawn des vagues
- **ResourceSpawner.gd** : Gère l'apparition des ressources
- **ChunkGrid.gd** : Système de grille (non utilisé pour l'instant)

## Conseils de Développement

### Ajouter un Nouveau Type de Bâtiment
1. Modifier l'enum `BuildingType` dans Building.gd
2. Ajouter le cas dans la fonction `produce()`
3. Créer un bouton dans GameUI.tscn
4. Implémenter le système de placement

### Ajouter un Nouveau Type d'Ennemi
1. Créer une nouvelle scène héritant de Enemy.tscn
2. Modifier les propriétés exportées
3. Ajouter la logique spécifique dans le script
4. Référencer dans WaveManager

### Modifier l'Équilibrage
Ouvrez **GameManager.gd** et modifiez:
- Ressources de départ
- PV du château
- Dégâts du château
- Durée entre les vagues (time_until_next_wave)

Ouvrez **Enemy.tscn** et modifiez les exports:
- max_hp
- speed
- damage
- gold_reward

## Debug et Console

Utilisez `print()` pour déboguer. Exemples déjà présents:
- GameManager affiche les vagues
- WaveManager affiche le spawn
- Building affiche les améliorations

Pour activer les logs Godot:
- Menu Débogage > Déployer avec Console de Débogage Distante
