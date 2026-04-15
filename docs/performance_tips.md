# ⚡ Optimisation des performances - RFM Segmentation

## Table des matières
1. [Diagnostic rapide](#diagnostic)
2. [Optimisations immédiates](#immediates)
3. [Optimisations avancées](#avancees)
4. [Monitoring et tuning](#monitoring)
5. [Gestion des volumes](#volumes)
6. [Bonnes pratiques SQL](#pratiques)
7. [Dépannage](#depannage)

---

## 📊 Diagnostic rapide {#diagnostic}

### Évaluer la performance actuelle

Exécutez ce script pour diagnostiquer les performances de votre environnement :

```sql
-- 1. Vérifier la volumétrie
SELECT 
    COUNT(*) AS nb_lignes_total,
    COUNT(DISTINCT CustomerKey) AS nb_clients_uniques,
    MIN(DateKey) AS premiere_vente,
    MAX(DateKey) AS derniere_vente,
    DATEDIFF(day, MIN(DateKey), MAX(DateKey)) AS jours_historique
FROM FactOnlineSales;

-- 2. Vérifier l'existence des index
SELECT 
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) = 'FactOnlineSales';

-- 3. Vérifier la fragmentation
SELECT 
    OBJECT_NAME(ips.object_id) AS table_name,
    ips.index_id,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats(
    DB_ID(), OBJECT_ID('FactOnlineSales'), NULL, NULL, 'LIMITED'
) ips;

-- 4. Estimer le temps d'exécution (test sur échantillon)
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

WITH test_rfm AS (
    SELECT TOP 10000 CustomerKey,
        MAX(DateKey) AS last_order_date,
        COUNT(DISTINCT OnlineSalesKey) AS frequency,
        SUM(SalesAmount) AS monetary
    FROM FactOnlineSales
    GROUP BY CustomerKey
)
SELECT COUNT(*) FROM test_rfm;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
