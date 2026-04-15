/*
================================================================================
PROJET : ANALYSE RFM ET SEGMENTATION CLIENTS
AUTEUR : [Billazy]
DATE DE CRÉATION : 2026-04-16
VERSION : 1.0
BASE DE DONNÉES : [ContosoRetailDW]
TABLE PRINCIPALE : FactOnlineSales
================================================================================

OBJECTIF DU PROJET :
-------------------
Ce projet a pour objectif d'analyser le comportement d'achat des clients 
via une segmentation RFM (Récence, Fréquence, Montant) afin d'optimiser 
la stratégie marketing et la gestion de la relation client (CRM).

QUESTIONS BUSINESS RÉSOLUES :
----------------------------
1. Qui sont nos meilleurs clients ? (Champions)
2. Quels clients sont sur le point de partir ? (Clients à risque)
3. Qui sont nos nouveaux clients prometteurs ?
4. Quel est le potentiel de croissance par segment ?
5. Où investir notre budget marketing ?
6. Quel est l'impact financier de l'inaction ?

MÉTRIQUES PRINCIPALES :
----------------------
- Récence : Dernier achat (en jours)
- Fréquence : Nombre total de commandes
- Montant : Chiffre d'affaires total
- Score RFM : Quintiles (1 à 5) pour chaque dimension
- Segment : Catégorie business du client

================================================================================
*/

/*
================================================================================
SECTION 1 : CRÉATION DE LA TABLE DE SEGMENTATION
================================================================================
Objectif : Créer une table temporaire contenant tous les clients avec leurs
           métriques RFM, scores et segments associés.
*/

-- Nettoyage de la table temporaire si elle existe déjà
IF OBJECT_ID('tempdb..#segments') IS NOT NULL
    DROP TABLE #segments;

-- Calcul des métriques RFM et segmentation
WITH rfm_base AS (
    -- Étape 1 : Agrégation des données clients
    SELECT
        CustomerKey,
        MAX(DateKey) AS last_order_date,                    -- Date du dernier achat
        COUNT(DISTINCT OnlineSalesKey) AS frequency,        -- Nombre total de commandes
        SUM(SalesAmount) AS monetary                        -- Chiffre d'affaires total
    FROM FactOnlineSales
    GROUP BY CustomerKey
),
rfm_calc AS (
    -- Étape 2 : Calcul de la récence (nombre de jours depuis dernier achat)
    SELECT
        CustomerKey,
        DATEDIFF(day, last_order_date, GETDATE()) AS recency,  -- Jours d'inactivité
        frequency,
        monetary
    FROM rfm_base
),
rfm_scores AS (
    -- Étape 3 : Scoring RFM par quintiles (1 = meilleur, 5 = moins bon)
    SELECT
        CustomerKey,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency ASC) AS R_score,      -- Plus récent = meilleur score
        NTILE(5) OVER (ORDER BY frequency DESC) AS F_score,   -- Plus fréquent = meilleur score
        NTILE(5) OVER (ORDER BY monetary DESC) AS M_score     -- Plus dépensier = meilleur score
    FROM rfm_calc
)
-- Étape 4 : Création de la table finale avec segments et recommandations
SELECT
    CustomerKey,
    recency,
    frequency,
    monetary,
    R_score,
    F_score,
    M_score,
    CONCAT(R_score, F_score, M_score) AS rfm_score,          -- Score combiné (ex: 555)
    (R_score + F_score + M_score) AS rfm_total,              -- Score total (3 à 15)
    
    -- Segmentation business basée sur les scores RFM
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        WHEN R_score >= 4 AND F_score >= 3 AND M_score >= 3 THEN 'Clients fidèles'
        WHEN R_score >= 4 AND (F_score <= 2 OR M_score <= 2) THEN 'Nouveaux clients'
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN 'Clients à risque'
        WHEN R_score <= 2 AND F_score <= 2 AND M_score <= 2 THEN 'Clients perdus'
        WHEN R_score <= 2 AND (F_score >= 3 OR M_score >= 3) THEN 'Clients à réactiver'
        ELSE 'Clients standards'
    END AS segment_client,
    
    -- Actions marketing recommandées par segment
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Programme VIP + Parrainage'
        WHEN R_score >= 4 AND F_score >= 3 AND M_score >= 3 THEN 'Programme fidélité + Offres personnalisées'
        WHEN R_score >= 4 AND (F_score <= 2 OR M_score <= 2) THEN 'Offre 2ème achat + Cross-selling'
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN 'Email réactivation + Code promo urgent'
        WHEN R_score <= 2 AND F_score <= 2 AND M_score <= 2 THEN 'Campagne reconquête -50%'
        WHEN R_score <= 2 AND (F_score >= 3 OR M_score >= 3) THEN 'Campagne "We miss you" -20%'
        ELSE 'Newsletter + Enquête satisfaction'
    END AS recommandation,
    
    -- Niveau d'urgence pour la réactivation
    CASE
        WHEN recency > 365 THEN 'CRITIQUE'
        WHEN recency > 180 THEN 'ÉLEVÉ'
        WHEN recency > 90 THEN 'MOYEN'
        WHEN recency > 30 THEN 'FAIBLE'
        ELSE 'NORMAL'
    END AS urgence_reactivation
INTO #segments
FROM rfm_scores;

-- Création d'un index clusterisé pour optimiser les performances des requêtes suivantes
CREATE CLUSTERED INDEX idx_segment ON #segments(segment_client, monetary DESC);

-- Affichage du nombre de clients segmentés
SELECT COUNT(*) AS total_clients_segmentes FROM #segments;


/*
================================================================================
SECTION 2 : ANALYSE DE LA DISTRIBUTION DES SEGMENTS
================================================================================
Objectif : Comprendre la répartition des clients et du chiffre d'affaires
           par segment.
Questions business :
- Quel segment domine ma base client ?
- Quel segment génère le plus de revenus ?
- Où dois-je concentrer mes efforts ?
*/

SELECT 
    segment_client,
    COUNT(*) AS nb_clients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pourcentage_clients,
    ROUND(AVG(monetary), 2) AS panier_moyen,
    ROUND(AVG(frequency), 2) AS frequence_moyenne,
    ROUND(AVG(recency), 0) AS recence_moyenne_jours,
    ROUND(SUM(monetary), 2) AS CA_total,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER(), 2) AS part_ca_pct
FROM #segments
GROUP BY segment_client
ORDER BY CA_total DESC;


/*
================================================================================
SECTION 3 : TOP 20 DES CLIENTS CHAMPIONS (PROGRAMME VIP)
================================================================================
Objectif : Identifier les meilleurs clients pour un programme de fidélisation VIP.
Questions business :
- Qui sont mes 20 meilleurs clients ?
- Quel est leur panier moyen ?
- Depuis combien de temps n'ont-ils pas acheté ?
*/

SELECT TOP 20
    CustomerKey,
    frequency AS nb_commandes,
    monetary AS CA_total,
    recency AS jours_inactivite,
    rfm_score,
    recommandation
FROM #segments
WHERE segment_client = 'Champions'
ORDER BY monetary DESC;


/*
================================================================================
SECTION 4 : CLIENTS À RISQUE - PRIORISATION CRM
================================================================================
Objectif : Identifier les clients à risque de départ pour action immédiate.
Questions business :
- Quels clients sont sur le point de partir ?
- Quel est l'impact financier potentiel de leur perte ?
- Quel est le niveau d'urgence ?
*/

SELECT TOP 50
    CustomerKey,
    frequency AS nb_commandes,
    monetary AS CA_total,
    recency AS jours_inactivite,
    urgence_reactivation,
    recommandation,
    ROUND(monetary * 0.7, 2) AS perte_potentielle      -- Perte estimée si inaction
FROM #segments
WHERE segment_client = 'Clients à risque'
ORDER BY 
    CASE urgence_reactivation
        WHEN 'CRITIQUE' THEN 1
        WHEN 'ÉLEVÉ' THEN 2
        WHEN 'MOYEN' THEN 3
        ELSE 4
    END,
    monetary DESC;


/*
================================================================================
SECTION 5 : PROJECTION FINANCIÈRE PAR SEGMENT
================================================================================
Objectif : Estimer le potentiel de croissance ou la perte évitable par segment.
Questions business :
- Quel est le ROI potentiel par segment ?
- Où investir mon budget marketing ?
- Quel est le coût de l'inaction ?
*/

SELECT 
    segment_client,
    ROUND(SUM(monetary), 2) AS CA_actuel,
    
    -- Projection du CA avec actions marketing adaptées
    ROUND(CASE 
        WHEN segment_client = 'Champions' THEN SUM(monetary) * 1.15
        WHEN segment_client = 'Clients fidèles' THEN SUM(monetary) * 1.20
        WHEN segment_client = 'Nouveaux clients' THEN SUM(monetary) * 1.30
        WHEN segment_client = 'Clients à risque' THEN SUM(monetary) * 0.70
        WHEN segment_client = 'Clients à réactiver' THEN SUM(monetary) * 0.50
        ELSE SUM(monetary) * 0.90
    END, 2) AS CA_potentiel,
    
    -- Variation en pourcentage
    ROUND(CASE 
        WHEN segment_client = 'Champions' THEN 15.0
        WHEN segment_client = 'Clients fidèles' THEN 20.0
        WHEN segment_client = 'Nouveaux clients' THEN 30.0
        WHEN segment_client = 'Clients à risque' THEN -30.0
        WHEN segment_client = 'Clients à réactiver' THEN -50.0
        ELSE -10.0
    END, 2) AS variation_pct,
    
    -- Impact financier absolu
    ROUND(CASE 
        WHEN segment_client = 'Champions' THEN SUM(monetary) * 0.15
        WHEN segment_client = 'Clients fidèles' THEN SUM(monetary) * 0.20
        WHEN segment_client = 'Nouveaux clients' THEN SUM(monetary) * 0.30
        WHEN segment_client = 'Clients à risque' THEN SUM(monetary) * -0.30
        WHEN segment_client = 'Clients à réactiver' THEN SUM(monetary) * -0.50
        ELSE SUM(monetary) * -0.10
    END, 2) AS impact_potentiel
FROM #segments
GROUP BY segment_client
ORDER BY CA_actuel DESC;


/*
================================================================================
SECTION 6 : MATRICE DE SEGMENTATION (RÉCENCE VS FRÉQUENCE)
================================================================================
Objectif : Visualiser la répartition des clients selon deux dimensions clés.
Questions business :
- Où se situent la majorité de mes clients ?
- Quels sont les axes d'amélioration prioritaires ?
*/

SELECT 
    CASE 
        WHEN R_score >= 4 THEN 'Récent'
        WHEN R_score >= 2 THEN 'Moyen'
        ELSE 'Ancien'
    END AS niveau_recence,
    CASE 
        WHEN F_score >= 4 THEN 'Très fréquent'
        WHEN F_score >= 2 THEN 'Moyennement fréquent'
        ELSE 'Peu fréquent'
    END AS niveau_frequence,
    COUNT(*) AS nb_clients,
    ROUND(AVG(monetary), 2) AS panier_moyen,
    ROUND(SUM(monetary), 2) AS CA_total,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER(), 2) AS part_ca_pct
FROM #segments
GROUP BY 
    CASE 
        WHEN R_score >= 4 THEN 'Récent'
        WHEN R_score >= 2 THEN 'Moyen'
        ELSE 'Ancien'
    END,
    CASE 
        WHEN F_score >= 4 THEN 'Très fréquent'
        WHEN F_score >= 2 THEN 'Moyennement fréquent'
        ELSE 'Peu fréquent'
    END
ORDER BY MAX(R_score) DESC, MAX(F_score) DESC;


/*
================================================================================
SECTION 7 : RÉSUMÉ EXÉCUTIF
================================================================================
Objectif : Fournir une vue d'ensemble de la santé de la clientèle.
Questions business :
- Quelle est la valeur moyenne d'un client ?
- Combien de commandes en moyenne ?
- Depuis combien de temps mes clients n'ont-ils pas acheté ?
*/

SELECT 
    'RÉSUMÉ EXÉCUTIF' AS titre,
    COUNT(DISTINCT CustomerKey) AS total_clients,
    ROUND(SUM(monetary), 2) AS ca_total,
    ROUND(AVG(monetary), 2) AS panier_moyen,
    ROUND(AVG(frequency), 2) AS commandes_moyennes,
    ROUND(AVG(recency), 0) AS inactivite_moyenne_jours,
    ROUND(SUM(monetary) / COUNT(DISTINCT CustomerKey), 2) AS valeur_moyenne_par_client
FROM #segments;


/*
================================================================================
SECTION 8 : ANALYSES COMPLÉMENTAIRES (OPTIONNELLES)
================================================================================
Objectif : Fournir des analyses supplémentaires pour des besoins spécifiques.
*/

-- 8.1 : Clients éligibles à l'upsell (bonne fréquence, faible montant)
SELECT TOP 20
    CustomerKey,
    frequency,
    monetary,
    ROUND(monetary / NULLIF(frequency, 0), 2) AS panier_moyen,
    'Éligible upselling' AS opportunite
FROM #segments
WHERE F_score >= 4 AND M_score <= 2
ORDER BY monetary DESC;

-- 8.2 : Distribution des scores RFM
SELECT 
    rfm_total,
    COUNT(*) AS nb_clients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pourcentage
FROM #segments
GROUP BY rfm_total
ORDER BY rfm_total DESC;

-- 8.3 : Clients inactifs depuis plus d'un an (à reconquérir)
SELECT 
    COUNT(*) AS clients_perdus,
    ROUND(SUM(monetary), 2) AS CA_perdu
FROM #segments
WHERE recency > 365;


/*
================================================================================
SECTION 9 : NETTOYAGE FINAL
================================================================================
Objectif : Supprimer les objets temporaires (optionnel - décommenter si besoin)
*/

-- DROP TABLE #segments;


/*
================================================================================
FIN DU DOCUMENT
================================================================================
*/
