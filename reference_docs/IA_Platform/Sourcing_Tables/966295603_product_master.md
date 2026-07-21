# Product Master

| Field | Value |
|---|---|
| Confluence page ID | `966295603` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/966295603/Product+Master |
| Mirrored from | Impact Analytics Confluence (IA space) |
| Created (Confluence) | 2023-08-31T09:41:31.951Z |
| Last mirrored | 2026-05-21 |

---

**SUMMARY:**

  * Contains details about all the products with respect to their attributes, launch date, hierarchy, etc. 




**EXPLANATION OF CODE:**

  * Level of Data → Article

  * Product_intermediate table is created from 3 datasets → product_master_v2, product_master_v3 and product_attribute_v2 (the tables product_attribute_v2 and product_master_v3 contains only product attributes)

  * All the ‘None’ and white spaces present in the data are converted to _null._

  * Additional size column is created with is concatenation of size1 and size2.

  * Additional choiceid_description column is created which is concatenation of style_description and color_description.




**PRODUCT MASTER SOURCING QUERY:**
    
    
    CREATE OR REPLACE TABLE
      `victorias-secret-393308.vs_sourcing_dev.product_intermediate` AS
    WITH
      BASE AS(
      SELECT
        STYLE,
        CASE
          WHEN UPPER(style_description) = 'NONE' OR TRIM(style_description)= '' THEN NULL
        ELSE
        TRIM(style_description)
      END
        AS style_description,
        ARTICLE,
        CASE
          WHEN UPPER(article_description) = 'NONE' OR TRIM(article_description)= '' THEN NULL
        ELSE
        TRIM(article_description)
      END
        AS article_description,
        PARSE_DATE('%Y%m%d',CAST(created_on AS string)) AS Created_On,
        CASE
          WHEN UPPER(GTIN) = 'NONE' OR TRIM(GTIN)= '' THEN NULL
        ELSE
        TRIM(GTIN)
      END
        AS GTIN,
        CASE
          WHEN UPPER(product_hierarchy) = 'NONE' OR TRIM(product_hierarchy)= '' THEN NULL
        ELSE
        TRIM(product_hierarchy)
      END
        AS product_hierarchy,
        CASE
          WHEN UPPER(Brand) = 'NONE' OR TRIM(Brand)= '' THEN NULL
        ELSE
        TRIM(Brand)
      END
        AS Brand,
        CASE
          WHEN UPPER(Channel) = 'NONE' OR TRIM(Channel)= '' THEN NULL
        ELSE
        TRIM(Channel)
      END
        AS Channel,
        CASE
          WHEN UPPER(article_status) = 'NONE' OR TRIM(article_status)= '' THEN NULL
        ELSE
        TRIM(article_status)
      END
        AS article_status,
        CASE
          WHEN UPPER(SIZE1) = 'NONE' OR TRIM(SIZE1)= '' THEN NULL
        ELSE
        TRIM(SIZE1)
      END
        AS SIZE1,
        CASE
          WHEN UPPER(SIZE2) = 'NONE' OR TRIM(SIZE2)= '' THEN NULL
        ELSE
        TRIM(SIZE2)
      END
        AS SIZE2,
        CASE
          WHEN UPPER(color_id) = 'NONE' OR TRIM(color_id)= '' THEN NULL
        ELSE
        TRIM(color_id)
      END
        AS color_id,
        CASE
          WHEN UPPER(Color_Description) = 'NONE' OR TRIM(Color_Description)= '' THEN NULL
        ELSE
        TRIM(Color_Description)
      END
        AS Color_Description,
        Subbrand_code,
        CASE
          WHEN UPPER(Subbrand_Description) = 'NONE' OR TRIM(Subbrand_Description)= '' THEN NULL
        ELSE
        TRIM(Subbrand_Description)
      END
        AS Subbrand_Description,
        Subclass_code_Level_1,
        CASE
          WHEN UPPER(Subclass_Description_Level1) = 'NONE' OR TRIM(Subclass_Description_Level1)= '' THEN NULL
        ELSE
        TRIM(Subclass_Description_Level1)
      END
        AS Subclass_Description_Level1,
        Merchandise_category_Level_3,
        CASE
          WHEN UPPER(Merchandise_category_Level_3_Desc) = 'NONE' OR TRIM(Merchandise_category_Level_3_Desc)= '' THEN NULL
        ELSE
        TRIM(Merchandise_category_Level_3_Desc)
      END
        AS Merchandise_category_Level_3_Desc,
        Category_Level_2,
        CASE
          WHEN UPPER(Category_Level_2_description) = 'NONE' OR TRIM(Category_Level_2_description)= '' THEN NULL
        ELSE
        TRIM(Category_Level_2_description)
      END
        AS Category_Level_2_description,
        Sector_Level1,
        CASE
          WHEN UPPER(Sector_Level1__Description) = 'NONE' OR TRIM(Sector_Level1__Description)= '' THEN NULL
        ELSE
        TRIM(Sector_Level1__Description)
      END
        AS Sector_Level1__Description,
        CASE
          WHEN UPPER(Collection) = 'NONE' OR TRIM(Collection)= '' THEN NULL
        ELSE
        TRIM(Collection)
      END
        AS Collection,
        CASE
          WHEN UPPER(Color_Family) = 'NONE' OR TRIM(Color_Family)= '' THEN NULL
        ELSE
        TRIM(Color_Family)
      END
        AS Color_Family,
        CASE
          WHEN UPPER(Color_Marketing_Name) = 'NONE' OR TRIM(Color_Marketing_Name)= '' THEN NULL
        ELSE
        TRIM(Color_Marketing_Name)
      END
        AS Color_Marketing_Name,
        CASE
          WHEN UPPER(Product_Lifecycle) = 'NONE' OR TRIM(Product_Lifecycle)= '' THEN NULL
        ELSE
        TRIM(Product_Lifecycle)
      END
        AS Product_Lifecycle,
        CASE
          WHEN UPPER(Fabric_Family) = 'NONE' OR TRIM(Fabric_Family)= '' THEN NULL
        ELSE
        TRIM(Fabric_Family)
      END
        AS Fabric_Family,
        CASE
          WHEN UPPER(Choice_Family) = 'NONE' OR TRIM(Choice_Family)= '' THEN NULL
        ELSE
        TRIM(Choice_Family)
      END
        AS Choice_Family,
        CASE
          WHEN UPPER(Gender) = 'NONE' OR TRIM(Gender)= '' THEN NULL
        ELSE
        TRIM(Gender)
      END
        AS Gender,
        CASE
          WHEN UPPER(Emotional_Space) = 'NONE' OR TRIM(Emotional_Space)= '' THEN NULL
        ELSE
        TRIM(Emotional_Space)
      END
        AS Emotional_Space,
        CASE
          WHEN UPPER(CHOICEID) = 'NONE' OR TRIM(CHOICEID)= '' THEN NULL
        ELSE
        TRIM(CHOICEID)
      END
        AS CHOICEID,
        CASE
          WHEN UPPER(ARTICLE_TYPE) = 'NONE' OR TRIM(ARTICLE_TYPE)= '' THEN NULL
        ELSE
        TRIM(ARTICLE_TYPE)
      END
        AS ARTICLE_TYPE,
        CASE
          WHEN UPPER(BASE_UNIT) = 'NONE' OR TRIM(BASE_UNIT)= '' THEN NULL
        ELSE
        TRIM(BASE_UNIT)
      END
        AS BASE_UNIT,
        CASE
          WHEN UPPER(CLEARANCE_INDICATOR) = 'NONE' OR TRIM(CLEARANCE_INDICATOR)= '' THEN NULL
        ELSE
        TRIM(CLEARANCE_INDICATOR)
      END
        AS CLEARANCE_INDICATOR,
        EMOTIONAL_SPACE_CD AS EMOTIONAL_SPACE_CODE,
        CASE
          WHEN UPPER(EMOTIONAL_SPACE_DESCR) = 'NONE' OR TRIM(EMOTIONAL_SPACE_DESCR)= '' THEN NULL
        ELSE
        TRIM(EMOTIONAL_SPACE_DESCR)
      END
        AS EMOTIONAL_SPACE_DESCR_NEW,
        CASE
          WHEN UPPER(MASTERSTYLE) = 'NONE' OR TRIM(MASTERSTYLE)= '' THEN NULL
        ELSE
        TRIM(MASTERSTYLE)
      END
        AS MASTERSTYLE,
        CASE
          WHEN UPPER(MASTERSTYLE_DESCR) = 'NONE' OR TRIM(MASTERSTYLE_DESCR)= '' THEN NULL
        ELSE
        TRIM(MASTERSTYLE_DESCR)
      END
        AS MASTERSTYLE_DESCR,
        CASE
          WHEN UPPER(SUB_COLLECTION) = 'NONE' OR TRIM(SUB_COLLECTION)= '' THEN NULL
        ELSE
        TRIM(SUB_COLLECTION)
      END
        AS SUB_COLLECTION,
        CASE
          WHEN UPPER(PRICING_VALUE) = 'NONE' OR TRIM(PRICING_VALUE)= '' THEN NULL
        ELSE
        TRIM(PRICING_VALUE)
      END
        AS PRICING_VALUE,
        CASE
          WHEN UPPER(RISE_VALUE) = 'NONE' OR TRIM(RISE_VALUE)= '' THEN NULL
        ELSE
        TRIM(RISE_VALUE)
      END
        AS RISE_VALUE,
        CASE
          WHEN UPPER(SLEEVE_LENGTH_VALUE) = 'NONE' OR TRIM(SLEEVE_LENGTH_VALUE)= '' THEN NULL
        ELSE
        TRIM(SLEEVE_LENGTH_VALUE)
      END
        AS SLEEVE_LENGTH_VALUE,
        CASE
          WHEN UPPER(LENGTH_VALUE) = 'NONE' OR TRIM(LENGTH_VALUE)= '' THEN NULL
        ELSE
        TRIM(LENGTH_VALUE)
      END
        AS LENGTH_VALUE,
        CASE
          WHEN UPPER(INNER_BRA_VALUE) = 'NONE' OR TRIM(INNER_BRA_VALUE)= '' THEN NULL
        ELSE
        TRIM(INNER_BRA_VALUE)
      END
        AS INNER_BRA_VALUE,
        CASE
          WHEN UPPER(NECKLINE_VALUE) = 'NONE' OR TRIM(NECKLINE_VALUE)= '' THEN NULL
        ELSE
        TRIM(NECKLINE_VALUE)
      END
        AS NECKLINE_VALUE,
        CASE
          WHEN UPPER(CLOSURE_VALUE) = 'NONE' OR TRIM(CLOSURE_VALUE)= '' THEN NULL
        ELSE
        TRIM(CLOSURE_VALUE)
      END
        AS CLOSURE_VALUE,
        CASE
          WHEN UPPER(WAIST_VALUE) = 'NONE' OR TRIM(WAIST_VALUE)= '' THEN NULL
        ELSE
        TRIM(WAIST_VALUE)
      END
        AS WAIST_VALUE,
        CASE
          WHEN UPPER(HOODIE_VALUE) = 'NONE' OR TRIM(HOODIE_VALUE)= '' THEN NULL
        ELSE
        TRIM(HOODIE_VALUE)
      END
        AS HOODIE_VALUE,
        CASE
          WHEN UPPER(CUFF_HEM_VALUE) = 'NONE' OR TRIM(CUFF_HEM_VALUE)= '' THEN NULL
        ELSE
        TRIM(CUFF_HEM_VALUE)
      END
        AS CUFF_HEM_VALUE,
        CASE
          WHEN UPPER(BACK_TYPE_VALUE) = 'NONE' OR TRIM(BACK_TYPE_VALUE)= '' THEN NULL
        ELSE
        TRIM(BACK_TYPE_VALUE)
      END
        AS BACK_TYPE_VALUE,
        CASE
          WHEN UPPER(PACKAGED_VALUE) = 'NONE' OR TRIM(PACKAGED_VALUE)= '' THEN NULL
        ELSE
        TRIM(PACKAGED_VALUE)
      END
        AS PACKAGED_VALUE,
        CASE
          WHEN UPPER(PJ_TYPE_VALUE) = 'NONE' OR TRIM(PJ_TYPE_VALUE)= '' THEN NULL
        ELSE
        TRIM(PJ_TYPE_VALUE)
      END
        AS PJ_TYPE_VALUE,
        CASE
          WHEN UPPER(STYLE_LIFECYCLE_VALUE) = 'NONE' OR TRIM(STYLE_LIFECYCLE_VALUE)= '' THEN NULL
        ELSE
        TRIM(STYLE_LIFECYCLE_VALUE)
      END
        AS STYLE_LIFECYCLE_VALUE,
        CASE
          WHEN UPPER(LINING_LEVEL_VALUE) = 'NONE' OR TRIM(LINING_LEVEL_VALUE)= '' THEN NULL
        ELSE
        TRIM(LINING_LEVEL_VALUE)
      END
        AS LINING_LEVEL_VALUE,
        CASE
          WHEN UPPER(STRUCTURE_CH_VALUE) = 'NONE' OR TRIM(STRUCTURE_CH_VALUE)= '' THEN NULL
        ELSE
        TRIM(STRUCTURE_CH_VALUE)
      END
        AS STRUCTURE_CH_VALUE,
        CASE
          WHEN UPPER(SUPPORT_VALUE) = 'NONE' OR TRIM(SUPPORT_VALUE)= '' THEN NULL
        ELSE
        TRIM(SUPPORT_VALUE)
      END
        AS SUPPORT_VALUE,
        CASE
          WHEN UPPER(COVERAGE_CH_VALUE) = 'NONE' OR TRIM(COVERAGE_CH_VALUE)= '' THEN NULL
        ELSE
        TRIM(COVERAGE_CH_VALUE)
      END
        AS COVERAGE_CH_VALUE,
        CASE
          WHEN UPPER(TREND_CH_VALUE) = 'NONE' OR TRIM(TREND_CH_VALUE)= '' THEN NULL
        ELSE
        TRIM(TREND_CH_VALUE)
      END
        AS TREND_CH_VALUE,
        CASE
          WHEN UPPER(PLANNING_SILHOUETTE_VALUE) = 'NONE' OR TRIM(PLANNING_SILHOUETTE_VALUE)= '' THEN NULL
        ELSE
        TRIM(PLANNING_SILHOUETTE_VALUE)
      END
        AS PLANNING_SILHOUETTE_VALUE,
        CASE
          WHEN UPPER(PRICE_POINT_VALUE) = 'NONE' OR TRIM(PRICE_POINT_VALUE)= '' THEN NULL
        ELSE
        TRIM(PRICE_POINT_VALUE)
      END
        AS PRICE_POINT_VALUE,
        CASE
          WHEN UPPER(DEVELOPMENT_SEASON_VALUE) = 'NONE' OR TRIM(DEVELOPMENT_SEASON_VALUE)= '' THEN NULL
        ELSE
        TRIM(DEVELOPMENT_SEASON_VALUE)
      END
        AS DEVELOPMENT_SEASON_VALUE,
        CASE
          WHEN UPPER(GRAPHIC_CH_VALUE) = 'NONE' OR TRIM(GRAPHIC_CH_VALUE)= '' THEN NULL
        ELSE
        TRIM(GRAPHIC_CH_VALUE)
      END
        AS GRAPHIC_CH_VALUE,
        CASE
          WHEN UPPER(PCB_SUB_COLLECTION_VALUE) = 'NONE' OR TRIM(PCB_SUB_COLLECTION_VALUE)= '' THEN NULL
        ELSE
        TRIM(PCB_SUB_COLLECTION_VALUE)
      END
        AS PCB_SUB_COLLECTION_VALUE,
        CASE
          WHEN UPPER(TREATMENT_VALUE) = 'NONE' OR TRIM(TREATMENT_VALUE)= '' THEN NULL
        ELSE
        TRIM(TREATMENT_VALUE)
      END
        AS TREATMENT_VALUE,
        CASE
          WHEN UPPER(PILLARS_VALUE) = 'NONE' OR TRIM(PILLARS_VALUE)= '' THEN NULL
        ELSE
        TRIM(PILLARS_VALUE)
      END
        AS PILLARS_VALUE,
        CASE
          WHEN UPPER(CHOICE_TREND_VALUE) = 'NONE' OR TRIM(CHOICE_TREND_VALUE)= '' THEN NULL
        ELSE
        TRIM(CHOICE_TREND_VALUE)
      END
        AS CHOICE_TREND_VALUE,
        (
        SELECT
          CAST(FORMAT_DATETIME('%Y-%m-%d %H:%M:%S',CURRENT_DATETIME()) AS DATETIME)) AS SYNCSTARTDATETIME
      FROM
        victorias-secret-393308.vs_sourcing_dev.vs_product_master_v2 prod
      LEFT JOIN
        victorias-secret-393308.vs_sourcing_dev.vs_product_attribute_v2 attr1
      ON
        prod.article=attr1.matnr
      LEFT JOIN
        victorias-secret-393308.vs_sourcing_dev.vs_product_master_v3 attr2
      ON
        prod.article=attr2.product)
    SELECT
      STYLE,
      style_description,
      ARTICLE,
      article_description,
      Created_On,
      GTIN,
      product_hierarchy,
      CASE
      WHEN BRAND = 'Victoria Secret' THEN 'VSL'
      WHEN BRAND = 'VS-Beauty' THEN 'VSB'
      WHEN BRAND = 'PINK' THEN 'PINK'
      ELSE NULL
      END AS Brand_code,
      Brand,
      Brand AS Brand_name,
      Channel,
      article_status,
      SIZE1,
      SIZE2,
      CASE
        WHEN SIZE1 IS NOT NULL AND SIZE2 IS NULL THEN SIZE1
        WHEN SIZE1 IS NULL
      AND SIZE2 IS NOT NULL THEN SIZE2
      ELSE
      CONCAT(SIZE1,'_',SIZE2)
    END
      AS SIZE,
      color_id,
      Color_Description,
      Subbrand_code,
      Subbrand_Description,
      Subclass_code_Level_1,
      Subclass_Description_Level1,
      Merchandise_category_Level_3,
      Merchandise_category_Level_3_Desc,
      Category_Level_2,
      Category_Level_2_description,
      Sector_Level1,
      Sector_Level1__Description,
      Collection,
      Color_Family,
      Color_Marketing_Name,
      Product_Lifecycle,
      Fabric_Family,
      Choice_Family,
      Gender,
      Emotional_Space,
      CHOICEID,
      CASE
        WHEN style_description IS NOT NULL AND color_description IS NULL THEN style_description
        WHEN style_description IS NULL AND color_description IS NOT NULL THEN color_description
      ELSE
      CONCAT(style_description,'-',color_description)
    END
      AS choiceid_description,
      ARTICLE_TYPE,
      BASE_UNIT,
      CASE
        WHEN CLEARANCE_INDICATOR = 'X' THEN TRUE
      ELSE
      FALSE
    END
      AS CLEARANCE_INDICATOR,
      EMOTIONAL_SPACE_CODE,
      EMOTIONAL_SPACE_DESCR_NEW,
      MASTERSTYLE,
      MASTERSTYLE_DESCR,
      SUB_COLLECTION,
      PRICING_VALUE,
      RISE_VALUE,
      SLEEVE_LENGTH_VALUE,
      LENGTH_VALUE,
      INNER_BRA_VALUE,
      NECKLINE_VALUE,
      CLOSURE_VALUE,
      WAIST_VALUE,
      HOODIE_VALUE,
      CUFF_HEM_VALUE,
      BACK_TYPE_VALUE,
      PACKAGED_VALUE,
      PJ_TYPE_VALUE,
      STYLE_LIFECYCLE_VALUE,
      LINING_LEVEL_VALUE,
      STRUCTURE_CH_VALUE,
      SUPPORT_VALUE,
      COVERAGE_CH_VALUE,
      TREND_CH_VALUE,
      PLANNING_SILHOUETTE_VALUE,
      PRICE_POINT_VALUE,
      DEVELOPMENT_SEASON_VALUE,
      GRAPHIC_CH_VALUE,
      PCB_SUB_COLLECTION_VALUE,
      TREATMENT_VALUE,
      PILLARS_VALUE,
      CHOICE_TREND_VALUE,
      TRUE AS ACTIVE,
      SYNCSTARTDATETIME
    FROM
      BASE
