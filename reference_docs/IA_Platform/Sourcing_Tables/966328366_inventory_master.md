# Inventory Master

| Field | Value |
|---|---|
| Confluence page ID | `966328366` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966328366/Inventory+Master |
| Mirrored from | Impact Analytics Confluence (IA space) |
| Created (Confluence) | 2023-08-31T09:40:22.261Z |
| Last mirrored | 2026-05-21 |

---

**SUMMARY:**

  * Contains Information about inventory at all stores and DCs from Jan -2020 to July - 2023, in terms of 

    * oh_quantity → on hand quantity, i.e. quantity present in store/DC, 

    * oo_quantity → on order quantity, i.e. quantity for which order has been placed by store/DC, 

    * it_quantity → in transit quantity, i.e. quantity which is inbound to store/DC.




**EXPLANATION OF CODE:**

  * Level of data → product_code, store_code, date.

  * Inventory_intermediate table is created from 2 datasets → inventory_data_ecomm_final_v1 & inventory_data_final_v1.

  * The above two tables are inner joined with product_intermediate and store_intermediate.

  * A flag has been created in the Inventory_intermediate which bifurcates Ecomm inventory and retail inventory.

  * The flag reads ‘RETAIL’ for all the entries from the table: inventory_data_final_v1, as all the records of this table correspond to retail inventory.

  * The flag reads ‘ECOMM’ for entries have have store code as 1020863,1022683,1022434 as these are EComm DCs ONLY, from the table: inventory_data_ecomm_final_v1

  * Finally the entire table is aggregated at a Store - SKU - Date level and OH, IT and OO is summed up together at this level




**INVENTORY SOURCING QUERY:**
    
    
    CREATE OR REPLACE TABLE
      `victorias-secret-393308.vs_sourcing_dev.inventory_intermediate` AS
    WITH
      invt_final AS (
      WITH
        raw_retail AS (
        SELECT
          *EXCEPT(ONORDERQTY),
          INTRANSITQTY AS it_quantity,
          ONHANDQTY AS oh_quantity,
          CASE
            WHEN ONORDERQTY LIKE '%N' THEN CAST('0' AS int64)
          ELSE
          CAST(ONORDERQTY AS int64)
          END
          AS oo_quantity
        FROM
          `victorias-secret-393308.vs_sourcing_dev.vs_inventory_data_final_v1` ),
        raw_ecomm AS (
        SELECT
          *EXCEPT(IN_TRANSIT_QTY,
            ON_ORDER_QTY),
          CASE
            WHEN IN_TRANSIT_QTY LIKE '%N' THEN CAST('0' AS int64)
          ELSE
          CAST(IN_TRANSIT_QTY AS int64)
          END
          AS it_quantity,
          ONHANDQTY AS oh_quantity,
          CASE
            WHEN ON_ORDER_QTY LIKE '%N' THEN CAST('0' AS int64)
          ELSE
          CAST(ON_ORDER_QTY AS int64)
          END
          AS oo_quantity
        FROM
          `victorias-secret-393308.vs_sourcing_dev.vs_inventory_data_ecomm_final_v1` ),
        retail_rolled_up AS (
        SELECT
          BRAND,
          SKU_NUM,
          STORE_CODE,
          INVENTORY_DATE,
          SUM(it_quantity) AS INTRANSITQTY,
          SUM(oh_quantity) AS ONHANDQTY,
          SUM(oo_quantity) AS ONORDERQTY
        FROM
          raw_retail
        GROUP BY
          1,
          2,
          3,
          4 ),
        ecomm_rolled_up AS (
        SELECT
          BRAND,
          SKU_NUM,
          LPAD(LOC_NUM,4,'0') AS LOC_NUM,
          INVENTORY_DATE,
          SUM(it_quantity) AS INTRANSITQTY,
          SUM(oh_quantity) AS ONHANDQTY,
          SUM(oo_quantity) AS ONORDERQTY
        FROM
          raw_ecomm
        GROUP BY
          1,
          2,
          3,
          4 ),
        retail_inv AS (
        SELECT
          t3.brand,
          sku_num AS sku_id,
          store_code,
          inventory_date,
          INTRANSITQTY AS it_quantity,
          ONHANDQTY AS oh_quantity,
          onorderqty AS oo_quantity,
          'RETAIL' AS inventory_type
        FROM
          retail_rolled_up AS t1
        INNER JOIN
          victorias-secret-393308.vs_sourcing_dev.store_intermediate AS t2
        ON
          t1.store_code = t2.store_id
        INNER JOIN
          victorias-secret-393308.vs_sourcing_dev.product_intermediate AS t3
        ON
          t1.sku_num = t3.article ),
        ecomm_inv AS (
        SELECT
          t3.brand,
          SKU_NUM AS sku_id,
          t2.store_id AS store_code,
          inventory_date,
          INTRANSITQTY AS it_quantity,
          ONHANDQTY AS oh_quantity,
          onorderqty AS oo_quantity,
          case when store_id in (1020863,1022683,1022434) then 'ECOMM'
          else 'RETAIL' end AS inventory_type
        FROM
          ecomm_rolled_up AS t1
        INNER JOIN
          victorias-secret-393308.vs_sourcing_dev.store_intermediate AS t2
        ON
          t1.loc_num = t2.loc_num
        INNER JOIN
          victorias-secret-393308.vs_sourcing_dev.product_intermediate AS t3
        ON
          t1.sku_num = t3.article)
      SELECT
        *
      FROM
        retail_inv
      UNION ALL
      SELECT
        *
      FROM
        ecomm_inv )
    SELECT
      *,
      (select CAST(max(INVENTORY_DATE) AS DATETIME) from invt_final) as SYNCSTARTDATETIME
    FROM
      invt_final
