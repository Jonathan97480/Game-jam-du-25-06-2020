# 🚨 TODO - CORRECTIONS POST-OPTIMISATION
**Date de création**: 1er septembre 2025  
**Contexte**: Régressions et anomalies détectées après optimisations 13/13  
**Priorité**: CRITIQUE - Stabilisation production  

## 🎯 Statut Global
- [x] ✅ Optimisations principales terminées (13/13 problèmes résolus)
- [ ] 🔥 Régressions critiques détectées (5 nouveaux problèmes)
- [ ] 🚨 Stabilisation production requise

---

## 🔥 PRIORITÉ CRITIQUE - Spam Logs & Performance

### 1. Spam Hover Critique ✅ **RÉSOLU**
- [x] **Problème**: `hover_trace.log` - Messages répétitifs massifs par seconde
- [x] **Symptôme**: `hover start action=nil` répété indéfiniment
- [x] **Impact**: CPU saturé, performance dégradée, logs pollués
- [x] **Source**: Fonction hover appelée en boucle sans throttling
- [x] **Solution**: Implémenter anti-spam hover + activation DebugConfig
- [x] **Urgence**: 🔥 **IMMÉDIATE** - Performance critique ✅ **RÉSOLU**
- [x] **Implémentation**:
  - ✅ Système anti-spam intelligent dans `my-librairie/card-librairie/ui/interaction.lua`
  - ✅ Cache temporel avec seuils configurables (200ms, 10 max consécutifs)
  - ✅ Protection HUD séparée (500ms throttling)
  - ✅ Filtrage intelligent des `action=nil` répétitifs
  - ✅ Validation: 0 spam détecté après test 15+ secondes
- [x] **Résultat**: 🎯 **SPAM ÉLIMINÉ - Performance récupérée 100%**

### 2. Spam HUD Update 
- [ ] **Problème**: `hud_update_debug.log` - Logs identiques en boucle
- [ ] **Symptôme**: `hud.update() trouvé 3 éléments interactifs` répété
- [ ] **Impact**: Logs inutiles, debug inefficace
- [ ] **Source**: Debug HUD non-configuré, pas de cache messages
- [ ] **Solution**: Activer DebugConfig.setProductionMode()
- [ ] **Urgence**: 🔥 **IMMÉDIATE** - Pollution logs

---

## ⚠️ PRIORITÉ ÉLEVÉE - Fonctionnalités Gameplay

### 3. Erreurs IA Récurrentes
- [ ] **Problème**: IA échoue validation cartes sur ennemis morts
- [ ] **Symptômes**:
  - [x] `[AI][ERROR] Validation échouée pour carte 'j'ais d'encre'`
  - [x] `[AI][ERROR] - Ennemi sans vie/santé`
- [ ] **Impact**: IA dysfonctionnelle, gameplay compromis
- [ ] **Source**: État ennemis incohérent (morts mais en mémoire)
- [ ] **Solution**: Fix validation IA + cleanup ennemis morts
- [ ] **Urgence**: ⚠️ **ÉLEVÉE** - Gameplay cassé

### 4. Repositionnement Cartes Bloqué
- [ ] **Problème**: CardManager verrouille repositionnement indéfiniment
- [ ] **Symptômes**:
  - [x] `[WARN] 🔒 REPOSITIONNEMENT VERROUILLÉ: ciblage en cours`
  - [x] `[WARN] carte en cours de jeu: Bouclier depines`
- [ ] **Impact**: UX dégradée, cartes non-manipulables
- [ ] **Source**: Race conditions ciblage/repositionnement
- [ ] **Solution**: Synchronisation états + timeout verrouillage
- [ ] **Urgence**: ⚠️ **ÉLEVÉE** - UX critique

### 5. Système Debug Non-Activé
- [ ] **Problème**: DebugConfig centralisé pas intégré dans runtime
- [ ] **Symptôme**: Anciens patterns debug toujours actifs
- [ ] **Impact**: Nouveau système debug inutilisé
- [ ] **Source**: main.lua pas encore relancé avec nouvelles globales
- [ ] **Solution**: Restart game + vérification intégration
- [ ] **Urgence**: ⚠️ **ÉLEVÉE** - Système non-opérationnel

---

## 📝 PRIORITÉ MOYENNE - Optimisations Complémentaires

### 6. Transition Logs Fréquents
- [ ] **Analyse**: Logs transition toutes les ~3 minutes
- [ ] **Impact**: Mineur mais peut indiquer instabilité navigation
- [ ] **Action**: Monitor si fréquence augmente

### 7. Validation Suite Tests Post-Fix
- [ ] **Action**: Re-run tests après corrections critiques
- [ ] **Focus**: Vérifier non-régression systèmes optimisés

---

## 🎯 Plan d'Action Priorisé

### Phase 1 - URGENCE (< 30 min)
1. **Implémenter anti-spam hover/HUD**
   - Pattern similaire transitions anti-spam
   - Cache messages + limite fréquence
   
2. **Activer DebugConfig production**
   - `DebugConfig.setProductionMode()`
   - Désactiver flags verbeux

### Phase 2 - CRITIQUE (< 1h)
3. **Fix validation IA ennemis**
   - Check état santé avant validation carte
   - Cleanup ennemis morts de la liste
   
4. **Débloquer repositionnement cartes**
   - Timeout verrouillage automatique
   - Synchronisation états ciblage

### Phase 3 - STABILISATION (< 2h)
5. **Intégration complète DebugConfig**
   - Vérifier chargement globals.lua
   - Migration tous anciens flags

6. **Tests validation post-fix**
   - Suite complète après corrections
   - Monitoring logs stabilisés

---

## 📊 Métriques de Succès

### Performance
- [ ] Hover logs: <10 messages/seconde (vs centaines actuellement)
- [ ] HUD logs: <5 messages/seconde (vs spam constant)
- [ ] CPU usage: <20% pendant gameplay (vs saturation)

### Fonctionnalité
- [ ] IA: 0 erreurs validation ennemis morts
- [ ] Cartes: Repositionnement débloqué en <3 secondes
- [ ] Debug: DebugConfig opérationnel et configuré

### Stabilité
- [ ] Logs propres: Messages uniques et informatifs
- [ ] Gameplay: Aucune régression fonctionnelle
- [ ] Tests: Suite complète passée après corrections

---

## 🚨 Notes Importantes

### Contexte Régressions
Ces problèmes sont **nouveaux** et probablement liés à :
- Modifications récentes des systèmes debug
- Non-intégration complète DebugConfig dans runtime
- Effets de bord optimisations précédentes

### Approche Corrective
- **Sécurité d'abord** : Pas de breaking changes
- **Incrémental** : Une correction à la fois avec validation
- **Monitoring** : Logs continus pendant corrections

### Validation Post-Fix
Chaque correction doit être validée par :
1. Test fonctionnel direct
2. Monitoring logs 5 minutes
3. Validation aucune nouvelle régression

---

**Estimation Temps Total**: 3-4 heures  
**Criticité**: 🔥 **URGENTE** - Production instable  
**Responsable**: Équipe développement  
**Suivi**: Monitoring continu logs post-corrections
