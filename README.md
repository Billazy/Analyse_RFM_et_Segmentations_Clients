# RFM Segmentation Analysis

## Description
Analyse RFM (Récence, Fréquence, Montant) pour la segmentation client et l'optimisation CRM.

## Installation
1. Exécuter `rfm_analysis.sql` sur SQL Server 2012+
2. Vérifier l'existence de la table `FactOnlineSales`

## Utilisation
Le script génère automatiquement :
- Segmentation client en 7 catégories
- Projections financières
- Recommandations marketing
- Priorisation des actions

## Résultats attendus
- Table temporaire `#segments` avec tous les clients segmentés
- 9 analyses prêtes à l'emploi

## Auteur
[Billazy] - [2026-04-16]

## Version
1.0
