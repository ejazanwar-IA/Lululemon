# Product Profile Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696611810` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611810/Product+Profile+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:37.207Z |
| Last mirrored | 2026-05-21 |

---

This section helps the user view and manipulate Product Profiles (store proportions and size curves at a store level). The Product Profile helps drive allocation recommendations to the SKU-Store level from the style-color level. The user can view IA's recommended Product Profile and create/ edit user-defined Product Profiles. By default, the IA Recommended Product Profile is tagged to all products, but users can change it if needed.

## **_User-Created Product Profiles_**

### ** _Creation Workflow_**

A user can create a new Product Profile from historical data. They can select a period and the products and stores that will take part in creating the Profile. The Below flowchart depicts the flow to create a new product profile:

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXdx3pOkSEhCr-RJc7WZsgFv-t7-sHsc80pJgHu6blR8k1f_NAIBDztdjXFhUhsZNcCPGxxaqvOfTwsFGUXcrjmGQ2LUYRnwU22aY1UXCs4Ng_h4tY9K5gMUQhvkZjjSpHkQOxUhOA?key=h1gME0B4n1Bi3hqe6PulW4v2)

### **_Components of Product Profile Creation screen_**

![image-20250304-061244.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611810/image-20250304-061244.png?version=1&modificationDate=1779356677868&cacheVersion=1&api=v2&width=760&height=77)

This section allows the user to provide a name and description to the user created product profile

![image-20250304-061621.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611810/image-20250304-061621.png?version=1&modificationDate=1779356677867&cacheVersion=1&api=v2&width=760&height=62)

This section allows the user to select the time period for the profile calculation. The user can select either a static time period or one out of the following dynamic time periods:

  1. Last 4 Weeks

  2. Last 12 Weeks

  3. Last 26 Weeks

  4. Last 52 Weeks


![image-20250304-062334.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611810/image-20250304-062334.png?version=1&modificationDate=1779356677866&cacheVersion=1&api=v2&width=760&height=173)

This section allows the user to filter the products the used for the profile creation based on hierarchies/attributes.

![image-20250304-063109.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611810/image-20250304-063109.png?version=1&modificationDate=1779356677689&cacheVersion=1&api=v2&width=760&height=115)

This section allows the user to filter transactions that are used for profile creation based on the following sales attributes:

  1. Min & Max Price

  2. Transaction Type: Regular/Promo/Clearance


![image-20250304-075407.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611810/image-20250304-075407.png?version=1&modificationDate=1779356677348&cacheVersion=1&api=v2&width=760&height=369)

This section allows the user to select products to create the product profile. _The filter highlighted in red allows the users to filter products whose cumulative sum of contribution, in descending order, is less than or equal to the value specified_.

_Calculation of Contribution table_

  * The contribution table is calculated from the `transaction_master_week_wise` table in BigQuery

  * `transaction_master_week_wise` is filtered based on the product and transaction filters and aggregated based on the query below



    
    
    with final_result as (
      select 
        tm.primary_sku, 
        tm.size, 
        tm.store_name, 
        tm.store_code, 
        tm.channel, 
        tm.l3_name, 
        tm.l4_name, 
        tm.store_code as store_grade, 
        sum(tm.day_count) day_count, 
        sum(tm.qty) as qty, 
        count(*) count 
      from 
        dollar - general - 395209.dg_ingestion_dev.transaction_master_month_wise tm 
      where 
        (
          tm.fiscal_year > 2023 
          OR (
            tm.fiscal_year = 2023 
            AND tm.fiscal_month >= 11
          )
        ) 
        AND (
          tm.fiscal_year < 2024 
          OR (
            tm.fiscal_year = 2024 
            AND tm.fiscal_month <= 2
          )
        ) 
        and tm.qty > 0 
        and price / count >= 1 
        and price / count <= 9999 
        AND tm.l1_name in ('400_TOYS') 
      group by 
        tm.primary_sku, 
        tm.size, 
        tm.store_name, 
        tm.store_code, 
        tm.channel, 
        tm.l3_name, 
        tm.l4_name, 
        tm.day_count, 
        tm.qty, 
        store_grade
    ) 
    select 
      primary_sku, 
      l3_name, 
      l4_name, 
      sum(qty) sales, 
      round(
        SUM(qty) / (
          SELECT 
            SUM(qty) 
          FROM 
            final_result
        ) * 100, 
        2
      ) as contribution 
    from 
      final_result 
    group by 
      primary_sku, 
      l3_name, 
      l4_name 
    order by 
      contribution desc

![image-20250304-083112.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611810/image-20250304-083112.png?version=1&modificationDate=1779356677348&cacheVersion=1&api=v2&width=760&height=347)

Once the user selects the products from the contribution table and clicks on the "Proceed" button, the store and size level contribution table is populated. The query used to populate the table is given below:
    
    
    with final_result as (
      select 
        primary_sku, 
        size, 
        l3_name, 
        l4_name, 
        store_name, 
        store_code, 
        channel, 
        tm.store_code as store_grade, 
        tm.day_count, 
        sum(tm.qty) as qty, 
        count(*) as count 
      from 
        dollar - general - 395209.dg_ingestion_test.transaction_master_month_wise tm 
      where 
        (
          tm.fiscal_year > 2023 
          OR (
            tm.fiscal_year = 2023 
            AND tm.fiscal_month >= 12
          )
        ) 
        AND (
          tm.fiscal_year < 2024 
          OR (
            tm.fiscal_year = 2024 
            AND tm.fiscal_month <= 3
          )
        ) 
        and tm.qty > 0 
        and price / count >= 1 
        and price / count <= 9999 
        AND tm.l1_name in (
          '102_BEAUTY CARE', '105_PET', '110_CANDY __ia_char_13 SNACKS', 
          '111_FOOD'
        ) 
        AND primary_sku in (
          '16787601', '16866602', '20368501', 
          '24015901', '24029601', '28824301', 
          '30702601', '34726601', '05869401', 
          '05869901'
        ) 
      group by 
        primary_sku, 
        size, 
        l3_name, 
        l4_name, 
        store_name, 
        store_code, 
        channel, 
        store_grade, 
        tm.day_count
    ), 
    agg_cte as (
      select 
        primary_sku, 
        store_name, 
        store_code, 
        channel, 
        store_grade, 
        size, 
        sum(qty) qty, 
        sum(day_count) day_count 
      from 
        final_result fr 
      group by 
        primary_sku, 
        store_name, 
        store_code, 
        channel, 
        store_grade, 
        size
    ) 
    SELECT 
      primary_sku, 
      store_name, 
      store_code, 
      channel, 
      store_grade, 
      size, 
      day_count, 
      qty / SUM(qty) OVER (PARTITION BY store_code) AS size_level_proportion, 
      qty / (
        SELECT 
          SUM(qty) 
        FROM 
          agg_cte
      ) AS overall_proportion 
    from 
      agg_cte 
    group by 
      primary_sku, 
      store_name, 
      store_code, 
      channel, 
      store_grade, 
      size, 
      day_count, 
      qty
    

### **_Attaching a user profile to a product_**

  * User profiles can be attached to a rule in Configurations > DC-Store Strategy

  * User profiles can be attached only if the rule relates to the hierarchy that is part of the user profile

  * A user profile can now be attached to any style-color within a hierarchy, even if the style-color was not initially used for creating the user profile

  * For example, a user profile can be created using style-colors C1 - C100 within a subclass 

    * Let's say there is a new choice C120 that is launched today, and falls within the same subclass

    * The profile can be applied on C120 for the overlapping sizes and stores for allocation

    * For any store / size that is missing in the profile, the contribution will be 0

    * Sizes and stores with a non-zero contribution will receive a non-zero allocation provided there is sufficient inventory in the DC




## ** _IA-Recommended Product Profiles_**

### ** _Creation Workflow_**

IA product profile are either calculated from the forecast or directly consumed from the forward looking product profile table shared by the ADA team. The approaches are as follows:

  1. **Approach 1**

     1. ADA team shares the forecast at a SKU-Store-Week level table.

     2. IA calculates both size and store proportions from the shared data.

     3. The data is then ingested into the BE product profile tables.

  2. **Approach 2**

     1. ADA team shares a week-wise product profile table ; 26 weeks into the future.

     2. The product profile for the current fiscal week is selected and ingested into the BE product profile tables. 




## **_Table Information_**

###   
** _Table Structure_**

| **DB**| **Table Name**  
---|---|---  
1| PG| inventory_smart.product_profile_master  
2| PG| inventory_smart.product_profile_mapping  
3| PG| inventory_smart.product_profile_attributes  
4| PG| inventory_smart.product_profile_user_mapping  
5| PG| inventory_smart.product_profile_attributes_list  
6| PG| inventory_smart.product_profile_attributes_filter  
  
### ** _Table Schema and Definitions_**

  * inventory_smart.product_profile_master




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pp_code| serial4| Unique ID for the product profile  
2| name| varchar| The value will be the Style-Color ID for IA-Recommended profiles, while for User-Defined product profiles, it will be the user-defined title.  
3| special_classification| varchar| The two possible values are:

  1. ia-recommended
  2. user-defined

  
4| is_deleted| bool| Flag to indicate whether the product profile is deleted or not  
5| created_at| timestamptz| Creation Info  
6| updated_at| timestamptz| Creation Info  
7| created_by| int4| This column will indicate the user_id of the user who created the profile  
8| updated_by| int4| This column will indicate the user_id of the user who updated the profile  
9| ph_code| int4| foreign key that connects to the `global.product_hierarchies_filter` table  
10| description| text| The value will be **NULL** for IA-recommended profiles, while for User-Defined product profiles, it will be the same as the value in the `name` column  
  
  * inventory_smart.product_profile_mapping  
 _This table is only relevant for IA-Recommended product profiles._




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pp_code| int4| Foreign Key that refers to `inventory_smart.product_profile_master`  
2| mapping_code| int4| Foreign Key that refers to `global.product_mapping_product_store`  
3| l0_name| varchar| Refers to the first level of product hierarchy  
4| size_level_proportion| float4| size profile   
5| overall_proportion| float4| store profile  
6| product_code| varchar|   
7| store_code| varchar|   
  
  * inventory_smart.product_profile_user_mapping  
 _This table is only relevant for user-defined product profiles. This table saves the size and store proportions for user-defined product profiles._




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pp_code| int4| Foreign Key that refers to `inventory_smart.product_profile_master`  
2| mapping_code| int4| Foreign Key that refers to `global.product_mapping_product_store`  
3| l0_name| varchar| Refers to the first level of product hierarchy  
4| size_level_proportion| float4| size profile   
5| overall_proportion| float4| store profile  
6| product_code| varchar|   
7| store_code| varchar|   
  
  * inventory_smart.product_profile_attributes  
 _This table is only relevant for user-defined product profiles._




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pp_code| int4| Foreign Key that refers to `inventory_smart.product_profile_master`  
2| attribute_name| varchar| Attributes that were used as filters while creating the user-defined product profile (Example: `product_hierarchy_filters`, `max_price`, `min_price,` etc)  
3| attribute_value| varchar| Attribute values that were used as filters while creating the user-defined product profile  
  
  * inventory_smart.product_profile_attributes_list  
 _This table lists down the product/store attributes used as filters in the user-defined product profile creation. These attributes are then used as columns in_`inventory_smart.product_profile_attributes_filter`




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| attribute_name| varchar|   
2| is_hierarchy| bool| `True` if the `attribute_name` is a product/store hierarchy  
3| is_attribute| bool| `True` if the `attribute_name` is a product/store attribute   
4| is_main_col| bool| -  
5| hierarchy_level| text| `store` or `product`  
6| datatype| text|   
  
  * inventory_smart.product_profile_attributes_filter  
 _This table is only relevant for user-defined product profiles._  
_Attributes might change across clients (Populated based on Carters data)_




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pp_code| int4| Foreign Key that refers to `inventory_smart.product_profile_master`  
2| article| _text| selected style-color IDs in text array format  
3| l1_name| _text| second product hierarchy level in text array format  
4| l2_name| _text| third product hierarchy level in text array format  
5| l3_name| _text| fourth product hierarchy level in text array format  
6| l4_name| _text| fifth product hierarchy level in text array format  
7| l0_name| _text| first product hierarchy level in text array format  
8| l5_name| _text| sixth product hierarchy level in text array format  
9| season| _text| selected `season` in text array format  
10| class| _text| selected `class` in text array format  
11| subclass| _text| selected `subclass` in text array format  
12| collection| _text| selected `collection` in text array format  
13| style| _text| selected `style` in text array format  
14| item_group_desc| _text| selected `item_group_desc` in text array format   
15| sty_primary_occsn_end_use_dsc| _text| selected `sty_primary_occsn_end_use_dsc` in text array format  
16| gender| _text| selected `gender` in text array format  
17| size| _text| selected `size` in text array format  
18| product_life_cycle| _text| selected `product_life_cycle` in text array format  
19| channel| _text| selected `channel` in text array format  
  
### ** _Dynamic Product Profile Refresh_**

We perform a weekly refresh of user created product profiles with a dynamic data range. It is done in 4 steps (_Signet Specific_) :

  * Run Backsync and get all relevant user-created dynamic product profile details to BigQuery

    * Backsync Query
          
          WITH
            pp_dynamic AS(
            SELECT
              *
            FROM
              crosstab ( 'SELECT pp_code, attribute_name, attribute_value FROM inventory_smart.product_profile_attributes ppa WHERE attribute_name IN (''date_type'', ''date_value'')        ORDER BY pp_code, attribute_name' ) AS pivot_ppa(pp_code int,
                date_type varchar,
                date_value varchar))
          SELECT
            a.pp_code,
            name,
            product_code,
            store_code,
            date_value,
            SUM(overall_proportion) AS overall_proportion
          FROM
            inventory_smart.product_profile_mapping a
          LEFT JOIN
            inventory_smart.product_profile_master ppm
          USING
            (pp_code)
          LEFT JOIN
            pp_dynamic
          USING
            (pp_code)
          WHERE
            ppm.special_classification = 'user-defined'AND date_type = 'dynamic'
          GROUP BY
            1,
            2,
            3,
            4,
            5

    * The table has the following fields

      * pp_code: Product Profile Code

      * name: Product Profile Name

      * product_code

      * store_code

      * date_value: 'Last 4 weeks' OR 'Last 12 weeks' OR 'Last 26 weeks' OR 'Last 52 weeks'

      * overall_proportion: Store level proportions

      * size_level_proportions: Store level proportion at a pp_code, style-color and store level  


  * Using the newly created BigQuery table, update the store and size proportions based on the dynamic timeperiod selected by the user during created.

    * SP for updating the proportions
          
          CREATE OR REPLACE PROCEDURE `impactsmart-prod.signet_ingestion_prod.user_defined_product_profile_refresh`()
          BEGIN 
          DECLARE present_date DATE; 
          DECLARE last_4_weeks_date DATE;
          DECLARE last_12_weeks_date DATE;
          DECLARE last_26_weeks_date DATE;
          DECLARE last_52_weeks_date DATE; 
          SET present_date = (select date from `impactsmart-prod.signet_ingestion_prod.fiscal_date_mapping` where date = current_date);
          SET last_4_weeks_date = (select date from `impactsmart-prod.signet_ingestion_prod.fiscal_date_mapping` where date = current_date - 4*7); 
          SET last_12_weeks_date = (select date from `impactsmart-prod.signet_ingestion_prod.fiscal_date_mapping` where date = current_date - 12*7); 
          SET last_26_weeks_date = (select date from `impactsmart-prod.signet_ingestion_prod.fiscal_date_mapping` where date = current_date - 26*7); 
          SET last_52_weeks_date = (select date from `impactsmart-prod.signet_ingestion_prod.fiscal_date_mapping` where date = current_date - 52*7);  
          create or replace table `impactsmart-prod.signet_ingestion_prod.dynamic_product_profile` as 
                      with base as ( 
                      with product_master as ( 
                     select article,size,planning_ownership,merchandise_category,product_description,merchandise_brand,product_type,sku_grade,product_code from `impactsmart-prod.signet_ingestion_prod.product_master` 
                     where article in (select distinct product_code from  `impactsmart-prod.signet_ingestion_prod.dynamic_product_profile`) 
                     
                 ) 
                  ,store_master as (
                        select channel,store_code,store_name from `impactsmart-prod.signet_ingestion_prod.store_master`   
                       where store_code in (select distinct store_code from  `impactsmart-prod.signet_ingestion_prod.dynamic_product_profile` )
                       
                  )
                 ,skus_per_pp_code as (
                    SELECT pp_code,COUNT(DISTINCT product_code) AS product_count FROM `impactsmart-prod.signet_ingestion_prod.dynamic_product_profile` GROUP BY 1 
                 )
                 ,final_result as (select product_code, store_code, store_name, store_grade, article,size,planning_ownership,merchandise_category,product_description,merchandise_brand,product_type,sku_grade, day_count, x.qty from 
                     (select tm.product_code, tm.store_code,
                     case when cluster is null then tm.store_code else cluster end as store_grade,
                      psf.article,psf.size,psf.planning_ownership,psf.merchandise_category,psf.product_description,psf.merchandise_brand,psf.product_type,psf.sku_grade , sm.store_name,
                       count(distinct tm.date) as day_count, sum(tm.qty) as qty, sum(tm.price) as price, count(*) as count  
                        from (select
                       tm.product_code, 
                     CASE
                          WHEN tm.store_code IN ('D.2','D.6') AND po.product_channel_name = 'ZALES' THEN 'ER.1'
                         WHEN tm.store_code IN ('D.2','D.6') AND po.product_channel_name = 'ZALES OUTLET' THEN 'EO.1'
                           WHEN tm.store_code IN ('D.5998') AND po.product_channel_name = 'PEOPLES' THEN 'EPR.1'
                           WHEN tm.store_code in ('D.10') AND po.product_channel_name='BANTER' THEN 'EBR.1'
                           WHEN tm.store_code in ('A.2000','A.2033')  AND po.product_channel_name="KAY"  THEN 'EKR.1'
                        WHEN tm.store_code in ('A.2001')  AND po.product_channel_name="JARED" THEN  'EJR.1'
                         WHEN tm.store_code in ('A.2032') AND po.product_channel_name="KAY OUTLET" THEN 'EKO.1'
                        ELSE tm.store_code
                        END as store_code,
                      tm.qty,
                     tm.price,
                       tm.date
                       from
                       `impactsmart-prod.signet_ingestion_prod.transaction_master` tm
                       left join (select po.product_code, po.product_channel_name from `impactsmart-prod.signet_ingestion_prod.product_master` po) po on po.product_code = tm.product_code
                       left join `impactsmart-prod.signet_ingestion_prod.dynamic_product_profile` u 
                       on tm.product_code = u.product_code and tm.store_code = u.store_code
                        where tm.qty > 0 AND (
              (u.date_value IN ('Last 30 days', 'Last 4 weeks') AND tm.date >= last_4_weeks_date AND tm.date <= present_date)
              OR (u.date_value IN ('Last 90 days', 'Last 12 weeks') AND tm.date >= last_12_weeks_date AND tm.date <= present_date)
              OR (u.date_value IN ('Last 180 days', 'Last 26 weeks') AND tm.date >= last_26_weeks_date AND tm.date <= present_date)
              OR (u.date_value IN ('Last 365 days', 'Last 52 weeks') AND tm.date >= last_52_weeks_date AND tm.date <= present_date)
          )
                        ) tm 
                        join product_master psf using (product_code) 
                        join store_master sm using (store_code)
                        left join `impactsmart-prod.signet_ingestion_prod.product_master` po on po.product_code = tm.product_code
                        left join
                                (
                                        select
                                        store_code, cluster, l0_name
                                        from
                                        (SELECT
                        store_code, cluster,
                        replace(JSON_EXTRACT(cluster_hierarchy, '$.l0_name'), '"', '') as l0_name 
                        FROM `impactsmart-prod.signet_ingestion_prod.store_clusters`) 
                                ) as cdg
                                on po.l0_name = cdg.l0_name
                                and tm.store_code = cdg.store_code
                        group by tm.product_code, tm.store_code, store_grade, psf.article,psf.size,psf.planning_ownership,psf.merchandise_category,psf.product_description,psf.merchandise_brand,psf.product_type,psf.sku_grade, sm.store_name ) x
                        where x.price/x.count >= 1 and x.price/x.count <= 999999)     
           ,agg_cte_base as (
                            select sm.*,pp_code,product_code,store_grade, size, sum(qty) qty, sum(day_count) day_count 
                            from `impactsmart-prod.signet_ingestion_prod.dynamic_product_profile` 
                            left join final_result fr using(product_code,store_code) 
                            join store_master sm using (store_code) 
                            group by channel,store_code,store_name, store_grade, size ,pp_code,product_code 
                            ),
           agg_cte as (
                            select sm.*,pp_code,store_grade, size, sum(qty) qty, sum(day_count) day_count 
                            from `impactsmart-prod.signet_ingestion_prod.dynamic_product_profile`  
                            left join final_result fr using(product_code,store_code) 
                            join store_master sm using (store_code) 
                            group by channel,store_code,store_name, store_grade, size ,pp_code 
                            ), 
           end_result AS (
          SELECT  pp_code
                 ,y.channel
                 ,y.product_code
                 ,y.store_code
                 ,y.store_name
                 ,y.store_grade
                 ,y.size
                 ,y.day_count
                 ,IFNULL(y.qty / SUM(y.qty) OVER (PARTITION BY pp_code,product_code,store_code),0) AS size_level_proportion
                 ,IFNULL((CAST(SUM(y.qty) OVER (PARTITION BY pp_code,store_code) AS FLOAT64) / CAST(SUM(y.qty) OVER (PARTITION BY pp_code) AS FLOAT64)) / CAST(k.product_count AS FLOAT64),0) AS overall_proportion 
          FROM agg_cte_base y
          JOIN skus_per_pp_code k using
          (pp_code
          )
          LEFT JOIN agg_cte g using
          (pp_code, store_code 
          )
          GROUP BY  pp_code
                   ,channel
                   ,product_code
                   ,store_code
                   ,store_name
                   ,store_grade
                   ,size
                   ,day_count
                   ,y.qty
                   ,product_code
                   ,k.product_count)
          SELECT *
          FROM end_result ) 
                   select z.pp_code,z.name,z.product_code,z.store_code,z.date_value,coalesce(k.overall_proportion,0)  as overall_proportion from `impactsmart-prod.signet_ingestion_prod.dynamic_product_profile` z left join base k using(pp_code,store_code,product_code) 
            ; end;




Note: The overall proportion is distributed equally among the number of products within the product profile code. This ensures that when displayed on the front end, the proportions can be aggregated, regardless of the specific products used to create the profile.

  * The output of the above code is ingested into a PostgreSQL table called `user_defined_product_profile_refresh` with the following schema:




| **Column Name**| **Data Type**| **Definition**  
---|---|---|---  
1| pp_code| STRING| Product Profile Code  
2| name| STRING| Product Profile Title  
3| product_code| STRING| Product Identifier  
4| store_code| STRING| Store Identifier  
5| date_value| STRING| Can have one of four values:

  * Last 4 weeks
  * Last 12 weeks
  * Last 26 weeks
  * Last 52 weeks

  
6| overall_proportion| FLOAT| Store level proportions  
  
  * We will then run the following SP to update the store and size proportions in the final table



    
    
    --liquibase formatted sql
    --changeset liquibase:user_defined_product_profile_refresh runOnChange:true stripComments:false splitStatements:false context:Release_1_0 labels:udpp
    --comment:  sync_user_defined_product_profile_refresh
    --rollback: SELECT 1
    DROP PROCEDURE IF EXISTS public.sync_user_defined_product_profile_refresh();
    CREATE OR REPLACE PROCEDURE public.sync_user_defined_product_profile_refresh()
     LANGUAGE plpgsql
     SECURITY DEFINER
    AS $procedure$
        begin   
            update inventory_smart.product_profile_mapping ppm
            set overall_proportion = x.overall_proportion
            from public.user_defined_product_profile_refresh x 
            where ppm.product_code = x.product_code and ppm.store_code = x.store_code and ppm.pp_code = x.pp_code; 
        end
    $procedure$;

Since Signet does not have sizing, this code will not include the update of size level proportions. Please update the code according to your client's business needs.

The tables used are Signet specific, the final table updated will change in newer implementations. Please verify before implementing.

### **_Frequently Asked Questions_**

  1. How does IA calculate size curves?

     1. The size curve calculation is done by the ADA team. Please refer to the documentations below:

        1. [Size Curve Split](/wiki/spaces/ACD/pages/1125515297/Size+Curve+Split)

        2. [New Store Split- Seasonality Inclusion](/wiki/spaces/ACD/pages/1082196014/New+Store+Split-+Seasonality+Inclusion)

  2. How are sizes properly ordered and rendered in the product profile screen?

     1. Create a size ordering table that arranges distinct sizes from the product master or within a specific hierarchy. The second approach is particularly useful in cases where the same size appears across multiple hierarchies and needs to be ordered differently.  
**For reference** :

![size_order_master.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611810/size_order_master.png?version=1&modificationDate=1779356678043&cacheVersion=1&api=v2&width=581&height=538)
     2. Using this ordering table, a json column `product_code_size_map` is created in the `ph_master` materialized view at a style-color level.

     3. This column will be then used to properly order sizes in all screens in InventorySmart
            
            Example:
            {"size": "MED", "order": 196, "new_size": "MED", "product_code": "24639006"}

  3. How does the edit of store and size proportions of user-created profiles work?

     1. How to edit

        1. On clicking the product profile name hyperlink the store and size contributions table is loaded.

        2. All proportions will be editable and the user can edit as required

        3. Once edited, the remaining non-edited values are rescaled back to 1

     2. Working of the rescaling logic

![image-20250225-111034.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611810/image-20250225-111034.png?version=1&modificationDate=1779356678214&cacheVersion=1&api=v2&width=712&height=241)



