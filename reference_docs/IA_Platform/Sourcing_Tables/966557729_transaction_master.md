# Transaction Master

| Field | Value |
|---|---|
| Confluence page ID | `966557729` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966557729/Transaction+Master |
| Mirrored from | Impact Analytics Confluence (IA space) |
| Created (Confluence) | 2023-08-31T09:37:39.441Z |
| Last mirrored | 2026-05-21 |

---

**SUMMARY:**

  * This intermediate table contains details of all the transactions that have occurred, through a period of Jan - 2020 to July - 2023 through Domestic Retail, Domestic EComm, International Retail and International EComm channels.




**EXPLANATION OF CODE:**

  * Level of Data → transaction_code, transaction_date, line_id, product_code, store_code, transaction_type. 

  * Union of three Datasets - Ecomm Transactions (International and Domestic), Partner transactions (Retail International transactions) and Retail Domestic transactions (Partner Transaction). 

  * Ecomm transactions are derived from table : ecomm_master_v2, and has been divided into 2 parts → ecomm_sales and ecomm_returns so that we could make it into a generic table structure

  * Retail Domestic transactions are derived from table : transaction_master_final_v1

  * Partner transactions are derived from table : international_transaction_master_full_v1, and has been labelled as int_txn → int_txn1 → int_txn2 and then divided into 2 parts → int_txn_sale and int_txn_return.

  * All the tables are inner joined with the product_intermediate (on sku_id) and store_intermediate (on store_code) table as we were told to use these mapping tables and filter out all other Products/ Stores that are not present in these tables

  * Discount is a calculated field in Ecomm transactions , whereas other datasets came with a   
predefined discount column.

  * Bifurcation based on transaction_type : ‘INTERNATIONAL_ECOMM’, ‘DOMESTIC_ECOMM’, ‘PARTNER_TRANSACTION’, ‘DOMESTIC_TRANSACTION’.

  * Additional columns were created so that other teams could identify various work streams.




**SOURCING QUERY:**
    
    
    CREATE OR REPLACE TABLE
      `victorias-secret-393308.vs_sourcing_dev.transaction_intermediate` AS
    WITH
      txn AS (
      SELECT
        c.BRAND,
        a.CHANNEL_ID,
        a.CHNL_DESC,
        CAST(transaction_id AS string) AS TRANSACTION_ID,
        TRANSACTION_DATE,
        CAST (line_id AS string) AS LINE_ID,
        SKU_ID,
        STORE_CODE,
        QUANTITY_SOLD,
        ABS(launch_price)*CRCY_EXCH_RT AS LAUNCH_PRICE,
        ABS(RETAIL_UNIT_PRICE)*CRCY_EXCH_RT AS RETAIL_UNIT_PRICE,
        CASE
          WHEN DISCOUNT_AMOUNT LIKE '%N' THEN CAST('0' AS float64)
        ELSE
        ABS(CAST(DISCOUNT_AMOUNT AS float64))*CRCY_EXCH_RT
      END
        AS DISCOUNT_AMOUNT,
        CASE
          WHEN quantity_sold>=0 THEN NET_SELLING_PRICE*CRCY_EXCH_RT
        ELSE
        ABS(NET_SELLING_PRICE)*CRCY_EXCH_RT*-1
      END
        AS NET_SELLING_PRICE,
        NULL AS NET_SELLING_PRICE_BEFORE_TAX,
        ABS(COST_PRICE)*CRCY_EXCH_RT AS COST_PRICE,
        a.CLEARANCE_INDICATOR,
        CRCY_EXCH_RT,
        ORDER_TYPE,
        CASE
          WHEN quantity_sold>=0 THEN 'SALE'
        ELSE
        'RETURN'
      END
        AS INVOICE_TYPE,
        'DOMESTIC_TRANSACTION' AS TRANSACTION_TYPE,
        '' AS FULLFULMENT_LOCATION_CUSTOMER,
        '' AS SHIP_TO_COUNTRY,
        0 AS FREIGHT_COST,
          b.geography,
      FROM
        `victorias-secret-393308.vs_sourcing_dev.vs_transaction_master_final_v1` a
      INNER JOIN
        victorias-secret-393308.vs_sourcing_dev.store_intermediate b
      ON
        a.store_code = b.store_id
      INNER JOIN
        victorias-secret-393308.vs_sourcing_dev.product_intermediate c
      ON
        a.sku_id = c.article
      WHERE
        country IN ('United States',
          'Canada') ),
      int_txn AS (
      SELECT
        a.brand,
        a.channel_id,
        CHNL_DESC,
        TRANSACTION_DATE,
        sku_id,
        store_code,
        CASE
          WHEN SLS_UNT_EXCL_VOID_XRNG_QTY LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(SLS_UNT_EXCL_VOID_XRNG_QTY AS float64)
      END
        AS SLS_UNT_EXCL_VOID_XRNG_QTY,
        CASE
          WHEN RTN_UNT_EXCL_VOID_XRNG_QTY LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(RTN_UNT_EXCL_VOID_XRNG_QTY AS float64)
      END
        AS RTN_UNT_EXCL_VOID_XRNG_QTY,
        CASE
          WHEN QUANTITY_SOLD LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(QUANTITY_SOLD AS float64)
      END
        AS QUANTITY_SOLD,
        CASE
          WHEN RETAIL_UNIT_PRICE LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(RETAIL_UNIT_PRICE AS float64)
      END
        AS RETAIL_UNIT_PRICE,
        CASE
          WHEN DISCOUNT_AMOUNT LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(DISCOUNT_AMOUNT AS float64)
      END
        AS DISCOUNT_AMOUNT,
        CASE
          WHEN SLS_UNT_EXCL_VOID_XRNG_AMT LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(SLS_UNT_EXCL_VOID_XRNG_AMT AS float64)
      END
        AS SLS_UNT_EXCL_VOID_XRNG_AMT,
        CASE
          WHEN RTN_UNT_EXCL_VOID_XRNG_AMT LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(RTN_UNT_EXCL_VOID_XRNG_AMT AS float64)
      END
        AS RTN_UNT_EXCL_VOID_XRNG_AMT,
        CASE
          WHEN ASSC_DISC_AMT LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(ASSC_DISC_AMT AS float64)
      END
        AS ASSC_DISC_AMT,
        CASE
          WHEN NET_SELLING_PRICE LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(NET_SELLING_PRICE AS float64)
      END
        AS NET_SELLING_PRICE,
        CASE
          WHEN COST_PRICE LIKE '%N' THEN CAST(0 AS float64)
        ELSE
        CAST(COST_PRICE AS float64)
      END
        AS COST_PRICE,
        CRCY_EXCH_RT,
        CASE
          WHEN ITM_CLR_STAT_STRT_DT LIKE '%N' THEN NULL
        ELSE
        CAST(ITM_CLR_STAT_STRT_DT AS DATE)
      END
        AS ITM_CLR_STAT_STRT_DT,
        CASE
          WHEN ITM_CLR_STAT_END_DT LIKE '%N' THEN NULL
        ELSE
        CAST(ITM_CLR_STAT_END_DT AS DATE)
      END
        AS ITM_CLR_STAT_END_DT,
        a.CLEARANCE_INDICATOR,
        RETURN_ITEM,
        ORDER_TYPE,
        b.geography
      FROM
        `victorias-secret-393308.vs_sourcing_dev.vs_international_transaction_master_full_v1` a
      INNER JOIN
        victorias-secret-393308.vs_sourcing_dev.store_intermediate b
      ON
        a.store_code = b.store_id
      INNER JOIN
        victorias-secret-393308.vs_sourcing_dev.product_intermediate c
      ON
        a.sku_id = c.article),
      int_txn1 AS(
      SELECT
        *,
        'SALE' AS invoice_type
      FROM
        int_txn
      WHERE
        SLS_UNT_EXCL_VOID_XRNG_QTY > 0
      UNION ALL
      SELECT
        *,
        'RETURN' AS invoice_type
      FROM
        int_txn
      WHERE
        RTN_UNT_EXCL_VOID_XRNG_QTY >0 ),
      int_txn2 AS (
      SELECT
        brand,
        channel_id,
        chnl_desc,
        transaction_date,
        sku_id,
        store_code,
        invoice_type,
        clearance_indicator,
        return_item,
        order_type,
        geography,
        SUM(SLS_UNT_EXCL_VOID_XRNG_QTY) AS SLS_UNT_EXCL_VOID_XRNG_QTY,
        SUM(RTN_UNT_EXCL_VOID_XRNG_QTY) AS RTN_UNT_EXCL_VOID_XRNG_QTY,
        SUM(QUANTITY_SOLD) AS QUANTITY_SOLD,
        MAX(RETAIL_UNIT_PRICE) AS RETAIL_UNIT_PRICE,
        SUM(DISCOUNT_AMOUNT) AS DISCOUNT_AMOUNT,
        SUM(SLS_UNT_EXCL_VOID_XRNG_AMT) AS SLS_UNT_EXCL_VOID_XRNG_AMT,
        SUM(RTN_UNT_EXCL_VOID_XRNG_AMT) AS RTN_UNT_EXCL_VOID_XRNG_AMT,
        SUM(ASSC_DISC_AMT) AS ASSC_DISC_AMT,
        SUM(NET_SELLING_PRICE) AS NET_SELLING_PRICE,
        MAX(COST_PRICE) AS COST_PRICE,
        MAX(CRCY_EXCH_RT) AS CRCY_EXCH_RT
      FROM
        int_txn1
      GROUP BY
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,11 ),
      int_txn_sale AS (
      SELECT
        b.brand,
        channel_id,
        chnl_desc,
        '' AS transaction_id,
        transaction_date,
        '' AS line_id,
        a.sku_id,
        store_code,
        SLS_UNT_EXCL_VOID_XRNG_QTY AS quantity_sold,
        NULL AS launch_price,
        ABS(retail_unit_price)*CRCY_EXCH_RT AS retail_unit_price,
        ABS(discount_amount)*CRCY_EXCH_RT AS discount_amount,
        SLS_UNT_EXCL_VOID_XRNG_AMT*CRCY_EXCH_RT AS net_selling_price,
        NULL AS NET_SELLING_PRICE_BEFORE_TAX,
        ABS(cost_price)*CRCY_EXCH_RT AS cost_price,
        CLEARANCE_INDICATOR,
        CRCY_EXCH_RT,
        ORDER_TYPE,
        INVOICE_TYPE,
        'PARTNER_TRANSACTION' AS TRANSACTION_TYPE,
        '' AS FULLFULMENT_LOCATION_CUSTOMER,
        '' AS SHIP_TO_COUNTRY,
        0 AS FREIGHT_COST,
        geography
      FROM
        int_txn2 a
      LEFT JOIN (
        SELECT
          article AS sku_id,
          brand
        FROM
          victorias-secret-393308.vs_sourcing_dev.product_intermediate) AS b
      ON
        a.sku_id = b.sku_id
      WHERE
        INVOICE_TYPE = 'SALE' ),
      int_txn_return AS (
      SELECT
        b.brand,
        channel_id,
        chnl_desc,
        '' AS transaction_id,
        transaction_date,
        '' AS line_id,
        a.sku_id,
        store_code,
        ABS(RTN_UNT_EXCL_VOID_XRNG_QTY)*-1 AS quantity_sold,
        NULL AS launch_price,
        ABS(retail_unit_price)*CRCY_EXCH_RT AS retail_unit_price,
        ABS(discount_amount)*CRCY_EXCH_RT AS discount_amount,
        ABS(RTN_UNT_EXCL_VOID_XRNG_AMT)*CRCY_EXCH_RT*-1 AS net_selling_price,
        NULL AS NET_SELLING_PRICE_BEFORE_TAX,
        ABS(cost_price)*CRCY_EXCH_RT AS cost_price,
        CLEARANCE_INDICATOR,
        CRCY_EXCH_RT,
        ORDER_TYPE,
        INVOICE_TYPE,
        'PARTNER_TRANSACTION' AS TRANSACTION_TYPE,
        '' AS FULLFULMENT_LOCATION_CUSTOMER,
        '' AS SHIP_TO_COUNTRY,
        0 AS FREIGHT_COST,
        geography
      FROM
        int_txn2 a
      LEFT JOIN (
        SELECT
          article AS sku_id,
          brand
        FROM
          victorias-secret-393308.vs_sourcing_dev.product_intermediate) AS b
      ON
        a.sku_id = b.sku_id
      WHERE
        INVOICE_TYPE = 'RETURN'),
      raw_ecomm AS (
      SELECT
        * except (country_code),
        LPAD(REPLACE(LTRIM(REPLACE(FULFILLER_LOCATION_VENDOR,'0',' ')),' ','0'),4,'0') AS loc_num
      FROM
        victorias-secret-393308.vs_sourcing_dev.vs_ecomm_master_v2 p
        left join (select country_code,geography from victorias-secret-393308.vs_sourcing_dev.vs_countrymapping) as q
         on p.ship_to_country = q.country_code),
      ecomm_sales AS (
      SELECT
        T3.BRAND,
        NULL AS CHANNEL_ID,
        CASE
          WHEN (STORE_TYPE = 'PKMS DC' OR STORE_TYPE = 'Non-PKMS DC') THEN 'Digital'
        ELSE
        'Retail'
      END
        AS CHNL_DESC,
        CONCAT(ORDER_NUMBER,'-',INVOICE_NUMBER) AS TRANSACTION_ID,
        DATE AS TRANSACTION_DATE,
        CONCAT(INVOICE_LINE_NUMBER,'-',ORDER_LINE_NUMBER) AS LINE_ID,
        SKU_ID,
        STORE_ID AS STORE_CODE,
        ABS(INVOICED_UNITS) AS QUANTITY_SOLD,
        ABS(LAUNCH_PRICE),
        ABS(INVOICED_SALES_UNIT_RETAIL_PRICE) AS RETAIL_UNIT_PRICE,
        (ABS(INVOICED_SALES_UNIT_RETAIL_PRICE)*ABS(INVOICED_UNITS) - ABS(INVOICED_SALES_AMOUNT)) AS DISCOUNT_AMOUNT,
        TOTAL_INVOICED_AMOUNT AS NET_SELLING_PRICE,
        INVOICED_SALES_AMOUNT AS NET_SELLING_PRICE_BEFORE_TAX,
        ABS(SKU_COST) AS COST_PRICE,
        T1.CLEARANCE_INDICATOR,
        1 AS CRCY_EXCH_RT,
        order_channel AS order_type,
        'SALE' AS INVOICE_TYPE,
        CASE
          WHEN SHIP_TO_COUNTRY IN ('US', 'CA') THEN 'DOMESTIC_ECOMM'
        ELSE
        'INTERNATIONAL_ECOMM'
      END
        AS TRANSACTION_TYPE,
        FULLFULMENT_LOCATION_CUSTOMER,
        SHIP_TO_COUNTRY,
        FREIGHT_COST,
        T1.geography
      FROM
        raw_ecomm AS T1
      INNER JOIN
        victorias-secret-393308.vs_sourcing_dev.store_intermediate AS T2
      ON
        T1.loc_num = T2.LOC_NUM
      INNER JOIN
        victorias-secret-393308.vs_sourcing_dev.product_intermediate AS T3
      ON
        T1.SKU_ID = T3.ARTICLE
      WHERE
        INVOICED_UNITS > 0),
      ecomm_return AS (
      SELECT
        T3.BRAND,
        NULL AS channel_id,
        '' AS CHNL_DESC,
        CONCAT(ORDER_NUMBER,'-',INVOICE_NUMBER) AS TRANSACTION_ID,
        DATE AS TRANSACTION_DATE,
        CONCAT(INVOICE_LINE_NUMBER,'-',ORDER_LINE_NUMBER) AS LINE_ID,
        SKU_ID,
        0 AS STORE_CODE,
        ABS(INVOICED_RETURN_UNITS)*-1 AS QUANTITY_SOLD,
        ABS(LAUNCH_PRICE),
        ABS(RETURN_UNIT_RETAIL_PRICE) AS RETAIL_UNIT_PRICE,
        (ABS(RETURN_UNIT_RETAIL_PRICE)*ABS(INVOICED_RETURN_UNITS) - ABS(RETURN_AMOUNT)) AS DISCOUNT_AMOUNT,
        TOTAL_RETURN_AMOUNT AS NET_SELLING_PRICE,
        RETURN_AMOUNT AS NET_SELLING_PRICE_BEFORE_TAX,
        ABS(RETURN_SKU_COST) AS COST_PRICE,
        T1.CLEARANCE_INDICATOR,
        1 AS CRCY_EXCH_RT,
        order_channel AS order_type,
        'RETURN' AS INVOICE_TYPE,
        CASE
          WHEN SHIP_TO_COUNTRY IN ('US', 'CA') THEN 'DOMESTIC_ECOMM'
        ELSE
        'INTERNATIONAL_ECOMM'
      END
        AS TRANSACTION_TYPE,
        FULLFULMENT_LOCATION_CUSTOMER,
        SHIP_TO_COUNTRY,
        RETURN_FREIGHT_COST AS FREIGHT_COST,
        T1.geography
      FROM
        raw_ecomm AS T1
      INNER JOIN
        victorias-secret-393308.vs_sourcing_dev.product_intermediate AS T3
      ON
        T1.SKU_ID = T3.ARTICLE
      WHERE
        INVOICED_RETURN_UNITS > 0),
    
      base AS (
      SELECT *,"BNM" as WS_CHANNEL FROM txn
      UNION ALL
      SELECT  *,"BNM" as WS_CHANNEL FROM int_txn_sale
      UNION ALL
      SELECT *,"BNM" as WS_CHANNEL FROM int_txn_return
      UNION ALL
      SELECT * except (STORE_ID,STORE_CATEGORY),
              CASE when store_category = 'STORE' then "BNM" else "ECOMM" end as WS_CHANNEL
               FROM ecomm_sales w
               left join (select store_id ,store_category from victorias-secret-393308.vs_sourcing_dev.store_intermediate) as x
               on w.store_code = x.store_id
      UNION ALL
      SELECT * except (STORE_ID,STORE_CATEGORY),
              CASE when store_category = 'STORE' then "BNM" else "ECOMM" end as WS_CHANNEL
               FROM ecomm_return y
               left join (select store_id ,store_category from victorias-secret-393308.vs_sourcing_dev.store_intermediate) as z
               on y.store_code = z.store_id)
    SELECT
      *,
      (
      SELECT
        CAST(MAX(TRANSACTION_DATE) AS DATETIME)
      FROM
        base) AS SYNCSTARTDATETIME
    FROM
      base
