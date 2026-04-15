
---

## 📄 **docs/business_questions.md**

```markdown
# 📊 Questions Business - RFM Segmentation

## Table des matières
1. [Questions stratégiques](#stratégiques)
2. [Questions opérationnelles](#opérationnelles)
3. [Questions financières](#financières)
4. [KPI à suivre](#kpi)
5. [Cas d'usage concrets](#cas-usage)

## 🎯 Questions stratégiques {#stratégiques}

### 1. Qui sont nos meilleurs clients et comment les reconnaître ?

**Question SQL associée :**
```sql
-- Section 3 du script
SELECT TOP 20 CustomerKey, monetary, frequency
FROM #segments WHERE segment_client = 'Champions'
ORDER BY monetary DESC;
