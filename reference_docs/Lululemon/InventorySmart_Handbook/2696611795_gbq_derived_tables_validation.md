# GBQ Derived Tables Validation

| Field | Value |
|---|---|
| Confluence page ID | `2696611795` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611795/GBQ+Derived+Tables+Validation |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:36.986Z |
| Last mirrored | 2026-05-21 |

---

This section provides the validation of Derived tables to easily check if there is any table missing the Article, Store or DC, which shows that if there is some issue with some derived table update which could lead to allocations not happening correctly.  
Also other part provides the standard queries which compares the data from the corresponding master tables v the derived tables. Any major deviation can be checked using these queries for the derived tables.

This section is designed to validate the **Derived tables** and ensure data consistency across the allocation process.

  * **Data Consistency Check** : Provides a set of **standard queries** to compare the data in Derived tables against their corresponding **Master tables**. Any significant deviations flagged by these queries can highlight data integrity issues that need to be addressed.

  * **Missing Data Check** : Quickly identify if any Derived table is missing an **Article, Store, or DC**. Such gaps may indicate an issue in the update process, which could directly affect allocation accuracy.




By running these validations regularly, teams can proactively detect and resolve discrepancies, ensuring smooth and accurate allocations.

### **Data Consistency Check:** (Major Derived Tables)

This****[**Notebook**](https://colab.research.google.com/drive/1d8O1rK3GNH4luBNK4eTO153kPAzpPUfW#scrollTo=a1d9057d) is created to validate the **universe of expected Product–Store–DC combinations** along with the **key metrics** for the major derived tables. It should be used as the base for all implementations.

### Key Notes

  * The queries are written to cover most **generic use cases**.

  * Users are expected to make environment-specific updates before execution.




### Required Updates

  1. **Project & Dataset**

     * Update the **Project ID** and **Dataset name** according to the respective implementation.

  2. **Filters**

     * Add any **mandatory filters** (e.g., date, product hierarchy, region) as required for the implementation.

  3. **Column Name Mismatches**

     * Validate schema alignment.

     * If column names differ across implementations, update the notebook queries accordingly.




### Implementation Steps

  1. Download the base notebook.

  2. Create a **new copy** dedicated to the respective implementation.

  3. Apply the required updates (Project/Dataset, filters, schema adjustments).

  4. Run validation against the derived tables.




### **Missing Data Check:**

Article: This validation ensures that all **active articles** are correctly mapped across the major derived tables.

  * **Scope of Validation** : Articles are checked against critical derived tables such as:

    * Product–Store Mapping

    * DC Inventory

    * Product Profile

    * Constraints

    * (and other key derived tables)

  * **Purpose** : If an article is missing from any of these derived tables, it may not appear in **allocations** or other downstream flows. This check helps quickly identify such discrepancies so corrective action can be taken.




By validating article presence across all derived tables, we can ensure no gaps exist that could impact allocation accuracy or reporting.
    
    
    SELECT
      sm.article AS Active_Article,
      CASE WHEN avp.article IS NOT NULL THEN 'Y' ELSE 'N' END AS ada_visual_pred,
      CASE WHEN pp.article IS NOT NULL THEN 'Y' ELSE 'N' END AS product_profile,
      CASE WHEN li.article IS NOT NULL THEN 'Y' ELSE 'N' END AS latest_inv,
      CASE WHEN psm.article IS NOT NULL THEN 'Y' ELSE 'N' END AS product_store_mapping,
      CASE WHEN sdm.article IS NOT NULL THEN 'Y' ELSE 'N' END AS product_dc_mapping,
      CASE WHEN tmm.article IS NOT NULL THEN 'Y' ELSE 'N' END AS transaction_master_month_wise,
      CASE WHEN tmw.article IS NOT NULL THEN 'Y' ELSE 'N' END AS transaction_master_week_wise,
      CASE WHEN ss.article IS NOT NULL THEN 'Y' ELSE 'N' END AS sku_status,
      CASE WHEN wcrt.article IS NOT NULL THEN 'Y' ELSE 'N' END AS whole_constraint_resolved_table,
      CASE WHEN fsdb.article IS NOT NULL THEN 'Y' ELSE 'N' END AS forecast_start_date_base,
      CASE WHEN ls.article IS NOT NULL THEN 'Y' ELSE 'N' END AS lost_sales,
      CASE WHEN eu.article IS NOT NULL THEN 'Y' ELSE 'N' END AS excess_units,
      CASE WHEN ssd.article IS NOT NULL THEN 'Y' ELSE 'N' END AS store_stock_drilldown,
      CASE WHEN aid.article IS NOT NULL THEN 'Y' ELSE 'N' END AS article_inventory_dashboard,
      CASE WHEN poi.article IS NOT NULL THEN 'Y' ELSE 'N' END AS po_inventory,
      CASE WHEN dpi.article IS NOT NULL THEN 'Y' ELSE 'N' END AS dc_pack_inventory,
      CASE WHEN nsis.article IS NOT NULL THEN 'Y' ELSE 'N' END AS new_store_inventory_source,
      CASE WHEN st.article IS NOT NULL THEN 'Y' ELSE 'N' END AS supersession_table,
      CASE WHEN ru.article IS NOT NULL THEN 'Y' ELSE 'N' END AS reserved_units,
      CASE WHEN ast.article IS NOT NULL THEN 'Y' ELSE 'N' END AS article_status_tag,
      CASE WHEN rsm.article IS NOT NULL THEN 'Y' ELSE 'N' END AS rule_store_mapping,
      CASE WHEN fst.article IS NOT NULL THEN 'Y' ELSE 'N' END AS fwos_sku_store_table,
      CASE WHEN dpc.article IS NOT NULL THEN 'Y' ELSE 'N' END AS dc_pack_configuration
    FROM
      `carters-070424.carters_ingestion_prod.product_master` sm
    -- ada visual predictions
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.ada_visual_predictions` avp
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
      WHERE fiscal_year_week > 202530
    ) avp ON sm.article = avp.article
    -- product profile
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.product_profile` pp
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) pp ON sm.article = pp.article
    -- latest inventory
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.latest_inventory` li
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) li ON sm.article = li.article
    -- product store mapping
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.product_store_mapping` psm
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) psm ON sm.article = psm.article
    -- product dc mapping
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.product_dc_mapping` sdm
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) sdm ON sm.article = sdm.article
    -- transaction master month wise
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.transaction_master_month_wise` tmm
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) tmm ON sm.article = tmm.article
    -- transaction master week wise
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.transaction_master_week_wise` tmw
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) tmw ON sm.article = tmw.article
    -- sku status
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.sku_status` ss
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) ss ON sm.article = ss.article
    -- whole constraint resolved table
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.whole_constraint_resolved_table` wcrt
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) wcrt ON sm.article = wcrt.article
    -- forecast start date base
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.forecast_start_date_base` fsdb
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (article, style, size)
    ) fsdb ON sm.article = fsdb.article
    -- lost sales
    LEFT JOIN (
      SELECT DISTINCT ls.article
      FROM `carters-070424.carters_ingestion_prod.lost_sales` ls
      -- JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) ls ON sm.article = ls.article
    -- excess units
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.excess_units` eu
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) eu ON sm.article = eu.article
    -- store stock drilldown
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.store_stock_drilldown` ssd
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) ssd ON sm.article = ssd.article
    -- article inventory dashboard
    LEFT JOIN (
      SELECT DISTINCT aid.article
      FROM `carters-070424.carters_ingestion_prod.article_inventory_dashboard` aid
      -- JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) aid ON sm.article = aid.article
    -- po inventory
    LEFT JOIN (
      SELECT DISTINCT poi.article
      FROM `carters-070424.carters_ingestion_prod.po_inventory` poi
      -- JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) poi ON sm.article = poi.article
    -- dc pack inventory
    LEFT JOIN (
      SELECT DISTINCT dpi.article
      FROM `carters-070424.carters_ingestion_prod.dc_pack_inventory` dpi
      -- JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) dpi ON sm.article = dpi.article
    -- new store inventory source
    LEFT JOIN (
      SELECT DISTINCT nsis.article
      FROM `carters-070424.carters_ingestion_prod.new_store_inventory_source` nsis
      -- JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) nsis ON sm.article = nsis.article
    -- supersession table
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.supersession_table` st
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) st ON sm.article = st.article
    -- reserved units
    LEFT JOIN (
      SELECT DISTINCT ru.article
      FROM `carters-070424.carters_ingestion_prod.reserved_units` ru
      -- JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) ru ON sm.article = ru.article
    -- article status tag
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.article_status_tag` ast
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) ast ON sm.article = ast.article
    -- rule store mapping
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.rule_store_mapping` rsm
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (article, size)
    ) rsm ON sm.article = rsm.article
    -- fwos sku store table
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.fwos_sku_store_table` fst
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) fst ON sm.article = fst.article
    -- dc pack configuration
    LEFT JOIN (
      SELECT DISTINCT pm.article
      FROM `carters-070424.carters_ingestion_prod.dc_pack_configuration` dpc
      JOIN `carters-070424.carters_ingestion_prod.product_master` pm USING (product_code)
    ) dpc ON sm.article = dpc.article
    WHERE
      sm.active = TRUE
      AND sm.article LIKE '%Brick%'
    ORDER BY
      sm.article;

Store: This validation ensures that all **active stores** are correctly mapped across the major derived tables.

  * **Scope of Validation** : Articles are checked against critical derived tables such as:

    * Product–Store Mapping

    * Store inventory

    * Forecast

    * Product Profile

    * Constraints

    * (and other key derived tables)

  * **Purpose** : If a store is missing from any of these derived tables, it may not appear in **allocations** or other downstream flows. This check helps quickly identify such discrepancies so corrective action can be taken.




By validating store presence across all derived tables, we can ensure no gaps exist that could impact allocation accuracy or reporting.
    
    
    SELECT
      sm.store_code AS Active_Store,
      CASE WHEN avp.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS ada_visual_pred,
      CASE WHEN pp.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS product_profile,
      CASE WHEN li.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS latest_inv,
      CASE WHEN sg.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS store_group,
      CASE WHEN psm.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS product_store_mapping,
      CASE WHEN sdm.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS store_dc_mapping,
      CASE WHEN ls.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS lost_sales,
      CASE WHEN ss.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS store_status,
      CASE WHEN fsd.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS forecast_start_date_base,
      CASE WHEN wcr.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS whole_constraint_resolved_table,
      CASE WHEN eu.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS excess_units,
      CASE WHEN ssd.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS store_stock_drilldown,
      CASE WHEN aid.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS article_inventory_dashboard,
      CASE WHEN psaf.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS product_store_attributes_filter,
      CASE WHEN psafsc.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS product_store_attributes_filter_store_code,
      CASE WHEN sc.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS store_clusters,
      CASE WHEN nst.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS new_store_table,
      CASE WHEN dtt.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS dc_transit_time,
      CASE WHEN rsm.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS rule_store_mapping,
      CASE WHEN fss.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS fwos_sku_store_table,
      CASE WHEN sci.store_code IS NOT NULL THEN 'Y' ELSE 'N' END AS store_current_inventory
    FROM
      `carters-070424.carters_ingestion_prod.store_master` sm
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.ada_visual_predictions` 
      WHERE fiscal_year_week > 202530
    ) avp ON sm.store_code = avp.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.product_profile`
    ) pp ON sm.store_code = pp.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.latest_inventory`
    ) li ON sm.store_code = li.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.store_group`
    ) sg ON sm.store_code = sg.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.product_store_mapping`
    ) psm ON sm.store_code = psm.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.store_dc_mapping`
    ) sdm ON sm.store_code = sdm.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.lost_sales`
    ) ls ON sm.store_code = ls.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.store_status`
    ) ss ON sm.store_code = ss.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.forecast_start_date_base`
    ) fsd ON sm.store_code = fsd.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.whole_constraint_resolved_table`
    ) wcr ON sm.store_code = wcr.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.excess_units`
    ) eu ON sm.store_code = eu.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.store_stock_drilldown`
    ) ssd ON sm.store_code = ssd.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.article_inventory_dashboard`
    ) aid ON sm.store_code = aid.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.product_store_attributes_filter`
    ) psaf ON sm.store_code = psaf.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.product_store_attributes_filter_store_code`
    ) psafsc ON sm.store_code = psafsc.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.store_clusters`
    ) sc ON sm.store_code = sc.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.new_store_table`
    ) nst ON sm.store_code = nst.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.dc_transit_time`
    ) dtt ON sm.store_code = dtt.store_code
    LEFT JOIN (
      SELECT DISTINCT psa_name store_code 
      FROM `carters-070424.carters_ingestion_prod.rule_store_mapping`
    ) rsm ON sm.store_code = rsm.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.fwos_sku_store_table`
    ) fss ON sm.store_code = fss.store_code
    LEFT JOIN (
      SELECT DISTINCT store_code 
      FROM `carters-070424.carters_ingestion_prod.store_current_inventory`
    ) sci ON sm.store_code = sci.store_code
    WHERE
      sm.active = TRUE
      AND sm.store_code NOT LIKE '%_dc'
    ORDER BY
      sm.store_code;

DC: This validation ensures that all **active DCs** are correctly mapped across the major derived tables.

  * **Scope of Validation** : Articles are checked against critical derived tables such as:

    * Product–DC Mapping

    * Store-DC Mapping

    * DC inventory

  * **Purpose** : If a DC is missing from any of these derived tables.
        
        SELECT DISTINCT dc_code,
               CASE WHEN t1.dc_code IS NOT NULL THEN 'Y' ELSE 'N' END AS in_dc_country_channel,
               CASE WHEN t2.dc_code IS NOT NULL THEN 'Y' ELSE 'N' END AS in_dc_status
        FROM ( 
        select country, dc_code from (
        select country, 
        CONCAT(LPAD(omnia_dc,4,'0'),'_dc') AS dc_code, sum(qu_alloc_qty) ata  from `carters-070424.carters_ingestion_prod.omnia_master`
        where channel like '%Brick%' and bulk_po in ('B', 'E')
        group by 1,2
        ) where ata > 0
        )
        AS om
        LEFT JOIN (
            SELECT DISTINCT dc_code FROM `carters-070424.carters_ingestion_prod.dc_country_channel`
        ) AS t1 USING (dc_code)
        LEFT JOIN (
            SELECT DISTINCT dc_code FROM `carters-070424.carters_ingestion_prod.dc_status`
        ) AS t2 USING (dc_code)




