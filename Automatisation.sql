# 🔄 Automatisation, Monitoring, Performance & Fiabilité - RFM Segmentation

## Table des matières
1. [Automatisation](#automatisation)
2. [Monitoring](#monitoring)
3. [Performance](#performance)
4. [Fiabilité](#fiabilite)
5. [Intégration continue](#ci-cd)
6. [Runbooks et procédures](#runbooks)

---

## 🤖 Automatisation {#automatisation}

### Architecture d'automatisation complète

### Script d'automatisation complet

```sql
-- =====================================================
-- PROCÉDURE STOCKÉE : Calcul automatique RFM
-- =====================================================

CREATE OR ALTER PROCEDURE dbo.sp_RFMAutomation
    @RunMode VARCHAR(20) = 'FULL',  -- 'FULL', 'INCREMENTAL', 'REFRESH'
    @DateReference DATE = NULL,      -- Date de référence pour le calcul
    @LogToTable BIT = 1              -- Logguer les résultats
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @Status VARCHAR(50) = 'STARTED';
    DECLARE @RowsAffected INT = 0;
    DECLARE @ErrorMessage NVARCHAR(4000) = NULL;
    
    BEGIN TRY
        
        -- 1. Validation des paramètres
        IF @DateReference IS NULL
            SET @DateReference = GETDATE();
        
        -- 2. Nettoyage des données temporaires
        IF OBJECT_ID('tempdb..#segments_new') IS NOT NULL
            DROP TABLE #segments_new;
        
        -- 3. Création de la table des résultats
        CREATE TABLE #segments_new (
            CustomerKey INT PRIMARY KEY,
            recency INT,
            frequency INT,
            monetary DECIMAL(18,2),
            R_score TINYINT,
            F_score TINYINT,
            M_score TINYINT,
            rfm_score VARCHAR(3),
            rfm_total TINYINT,
            segment_client VARCHAR(50),
            recommandation VARCHAR(200),
            urgence_reactivation VARCHAR(20),
            calculated_date DATE DEFAULT CAST(@DateReference AS DATE)
        );
        
        -- 4. Calcul RFM (version optimisée)
        INSERT INTO #segments_new (
            CustomerKey, recency, frequency, monetary,
            R_score, F_score, M_score, rfm_score, rfm_total,
            segment_client, recommandation, urgence_reactivation
        )
        WITH rfm_base AS (
            SELECT
                CustomerKey,
                MAX(DateKey) AS last_order_date,
                COUNT(DISTINCT OnlineSalesKey) AS frequency,
                SUM(SalesAmount) AS monetary
            FROM FactOnlineSales
            WHERE DateKey <= @DateReference
            GROUP BY CustomerKey
        ),
        rfm_calc AS (
            SELECT
                CustomerKey,
                DATEDIFF(day, last_order_date, @DateReference) AS recency,
                frequency,
                monetary
            FROM rfm_base
        ),
        rfm_scores AS (
            SELECT
                CustomerKey,
                recency,
                frequency,
                monetary,
                NTILE(5) OVER (ORDER BY recency ASC) AS R_score,
                NTILE(5) OVER (ORDER BY frequency DESC) AS F_score,
                NTILE(5) OVER (ORDER BY monetary DESC) AS M_score
            FROM rfm_calc
        )
        SELECT
            CustomerKey,
            recency,
            frequency,
            monetary,
            R_score,
            F_score,
            M_score,
            CONCAT(R_score, F_score, M_score) AS rfm_score,
            (R_score + F_score + M_score) AS rfm_total,
            CASE
                WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
                WHEN R_score >= 4 AND F_score >= 3 AND M_score >= 3 THEN 'Clients fidèles'
                WHEN R_score >= 4 AND (F_score <= 2 OR M_score <= 2) THEN 'Nouveaux clients'
                WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN 'Clients à risque'
                WHEN R_score <= 2 AND F_score <= 2 AND M_score <= 2 THEN 'Clients perdus'
                WHEN R_score <= 2 AND (F_score >= 3 OR M_score >= 3) THEN 'Clients à réactiver'
                ELSE 'Clients standards'
            END AS segment_client,
            CASE
                WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Programme VIP + Parrainage'
                WHEN R_score >= 4 AND F_score >= 3 AND M_score >= 3 THEN 'Programme fidélité + Offres personnalisées'
                WHEN R_score >= 4 AND (F_score <= 2 OR M_score <= 2) THEN 'Offre 2ème achat + Cross-selling'
                WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN 'Email réactivation + Code promo urgent'
                WHEN R_score <= 2 AND F_score <= 2 AND M_score <= 2 THEN 'Campagne reconquête -50%'
                WHEN R_score <= 2 AND (F_score >= 3 OR M_score >= 3) THEN 'Campagne "We miss you" -20%'
                ELSE 'Newsletter + Enquête satisfaction'
            END AS recommandation,
            CASE
                WHEN recency > 365 THEN 'CRITIQUE'
                WHEN recency > 180 THEN 'ÉLEVÉ'
                WHEN recency > 90 THEN 'MOYEN'
                WHEN recency > 30 THEN 'FAIBLE'
                ELSE 'NORMAL'
            END AS urgence_reactivation
        FROM rfm_scores;
        
        SET @RowsAffected = @@ROWCOUNT;
        
        -- 5. Mise à jour de la table historique
        IF @RunMode = 'FULL' OR @RunMode = 'REFRESH'
        BEGIN
            -- Supprimer les données de la même date
            DELETE FROM dbo.RFMSegmentationHistory
            WHERE calculated_date = CAST(@DateReference AS DATE);
            
            -- Insérer les nouvelles données
            INSERT INTO dbo.RFMSegmentationHistory
            SELECT * FROM #segments_new;
        END
        ELSE IF @RunMode = 'INCREMENTAL'
        BEGIN
            -- Insertion incrémentale (uniquement nouveaux clients)
            INSERT INTO dbo.RFMSegmentationHistory
            SELECT n.*
            FROM #segments_new n
            LEFT JOIN dbo.RFMSegmentationHistory h 
                ON n.CustomerKey = h.CustomerKey 
                AND h.calculated_date = DATEADD(day, -1, CAST(@DateReference AS DATE))
            WHERE h.CustomerKey IS NULL;
        END
        
        SET @Status = 'SUCCESS';
        
    END TRY
    BEGIN CATCH
        SET @Status = 'FAILED';
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Log de l'erreur
        IF @LogToTable = 1
        BEGIN
            INSERT INTO dbo.RFMAutomationLog (
                run_date, status, rows_affected, error_message, duration_ms
            )
            VALUES (
                @StartTime, @Status, @RowsAffected, @ErrorMessage,
                DATEDIFF(ms, @StartTime, GETDATE())
            );
        END
        
        -- Relancer l'erreur
        THROW;
    END CATCH
    
    -- 6. Logging de fin d'exécution
    IF @LogToTable = 1 AND @Status = 'SUCCESS'
    BEGIN
        INSERT INTO dbo.RFMAutomationLog (
            run_date, status, rows_affected, duration_ms
        )
        VALUES (
            @StartTime, @Status, @RowsAffected,
            DATEDIFF(ms, @StartTime, GETDATE())
        );
    END
    
    -- 7. Nettoyage
    DROP TABLE #segments_new;
    
    -- 8. Retourner le résumé
    SELECT 
        @Status AS execution_status,
        @RowsAffected AS customers_processed,
        DATEDIFF(ms, @StartTime, GETDATE()) AS duration_ms,
        @DateReference AS reference_date;
END;
