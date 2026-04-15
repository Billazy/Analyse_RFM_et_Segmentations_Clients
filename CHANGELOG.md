
---

## 📄 **CHANGELOG.md**

```markdown
# 📝 Changelog - RFM Segmentation Analysis

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-16

### ✨ Ajouté
- Script principal d'analyse RFM (`rfm_analysis.sql`)
- Segmentation en 7 catégories clients
- Projection financière par segment
- Matrice de segmentation Récence vs Fréquence
- Résumé exécutif automatisé
- Documentation complète du projet

### 🔧 Fonctionnalités
- Calcul automatique des scores RFM (quintiles)
- Recommandations marketing par segment
- Détection des clients à risque avec niveaux d'urgence
- Top 20 des clients Champions
- Analyse de la distribution des segments

### 📚 Documentation
- README.md avec guide d'installation
- Business questions détaillées
- Dictionnaire des segments
- Conseils de performance SQL

### 🎯 Métriques incluses
- Récence (jours depuis dernier achat)
- Fréquence (nombre de commandes)
- Montant (CA total)
- Scores RFM (1 à 5)
- Score RFM combiné (3 à 15)

## [À venir]

### 🚀 Roadmap
- [ ] Version avec coefficients ajustables dynamiquement
- [ ] Export automatique vers Excel/CSV
- [ ] Dashboard Power BI intégré
- [ ] Analyse prédictive du churn
- [ ] Calcul du LTV (Lifetime Value)
- [ ] Intégration avec des données CRM externes

### 🐛 Corrections prévues
- Gestion des valeurs NULL dans SalesAmount
- Support pour différentes devises
- Optimisation pour très gros volumes (> 1M clients)

---

## Notes de version

### [1.0.0] - 2026-04-16
**Première version stable**

✅ Tests validés sur SQL Server 2019  
✅ Performance optimisée pour 100K+ clients  
✅ Documentation complète  
✅ Prêt pour production

### Compatibilité
- SQL Server 2012 et supérieur
- Azure SQL Database
- Amazon RDS for SQL Server

---

**Maintenu par :** [Billazy]  
**Contact :** billazy30@hotmail.com
