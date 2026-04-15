# 🔧 Prérequis techniques - RFM Segmentation

## Configuration minimale requise

### Base de données
| Composant | Version requise | Recommandée |
|-----------|----------------|-------------|
| SQL Server | 2012+ | 2019+ |
| Azure SQL Database | Toutes versions | Standard tier |
| Compatibilité niveau | 110+ | 130+ |

### Structure de données requise

#### Table principale : FactOnlineSales
```sql
-- Colonnes obligatoires
CREATE TABLE FactOnlineSales (
    CustomerKey    INT          NOT NULL,  -- Identifiant client
    DateKey        DATE         NOT NULL,  -- Date de commande
    OnlineSalesKey INT          NOT NULL,  -- Identifiant vente
    SalesAmount    DECIMAL(18,2) NOT NULL  -- Montant de la vente
);
