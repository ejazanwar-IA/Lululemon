# Product-Store Configuration Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696609990` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609990/Product-Store+Configuration+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:04.344Z |
| Last mirrored | 2026-05-21 |

---

### Product Status

### Workflow: 

  1. The data is set up for the first time through data ingestion. IA uses the default rule to set up the product status table in BQ. 

     1. Ingestion is directly run on the sku_status table in BQ. Refer to Table 1.1 for schema of sku_status

     2. The table sku_status table in BQ is inserted with new rows obtained and existing rows have their status updated (data is upserted)

     3. Insert rows: pick active products (where active=true) from the product master and map them as active from the current date to 2050-12-31. The date "2050-12-31" is the maximum date that can be used by the IS tool.

     4. Update: existing products in sku_status that are shared as inactive in the product master will have their status changed to inactive for all the timeframes present in the table.

  2. The delta rows are created by querying the rows where feed_updated=current date() in sku_status to create productseason_validated_table.

     1. The table in BQ: productseason_validated_table. Refer to Table 1.2 below

     2. Ingestion query name: productseason_validated_table

     3. This is a full replacement query

  3. The data ingested in BQ (delta rows only) productseason_validated_table will be pushed to Postgres public schema through ingestion.

     1. The table in PG public schema: public.productseason_validated_table. Please refer to table 1.3 for schema

     2. Data from public.productseason_validated_table gets upserted in global.product_time_attributes. Please refer to table 1.5 for global.productseason_validated_table schema

  4. An SP updates global.aggregation_time_attributes: rolling status values from sku to a style level

     1. Logic used: At least one sku is active for the article then the article is marked active

     2. This is used to show the active status for styles/ styles-color in the tool when the toggle is moved to a Style or Style-Color level (any level higher than sku)

     3. SP name: sync_aggregation_time_attributes

  5. The SKU status screen in the tool points to the PG tables:

     1. SKU Status: global.product_time_attributes

     2. Style Status: global.aggregation_time_attributes 

     3. Any edits made in the Style Status table will affect the SKU Status table on the fly

  6. Any edits made in the tool are directly updated in the Postgres table

  7. After a designated time when users are expected to be logged out of the tool (towards the end of the day, for example, 7 pm CST) and before periodic ingestion begins, the edits are to be back synced from PG to BQ. 

     1. Back syncs are set up in Data Flows

     2. Through the back sync process, we fully replace the table sku_status

  8. Back-syncing the table from PG to BQ ensures:

     1. The data in both platforms are in sync

     2. This information is used to modify the active status of the product in the next ingestion in the product_attributes_filter table to be used in CNA and Auto Allocation

  9. In Periodic ingestion that follows,uses the back synced sku_status and product_master to update its active flag

     1. It refers to edits from sku_status (after back sync- back syncs are to be completed before ingestion starts): Since the product_attribute_filter table is not time-phased, the status of the product where the current date is between start_time and end_time is considered.

     2. and product_master active= true/ false is used

     3. When there is a status conflict between the product master feed and sku_status user edits then the product master feed update takes the higher precedence

  10. Since sku_status is back synced to BQ with user edits towards the end of the client day and paf refers to this for updates in ingestion, there will be a day's lag in sku_status updates reflecting in product_attributes_filter and CNA.




Table 1.1: BQ table - sku_status

**Column names**|  product_code| attribute_name| attribute_value| start_time| end_time| feed_updated_date| product_time_attr_id| updated_at| updated_by  
---|---|---|---|---|---|---|---|---|---  
**Default Logic in Ingestion**|  product_codes from the product master feed shared by the client | status| active or inactive based on active flag shared in the feed | The date the product code is added to the table as active | Max date supported by the system 2050-12-31| the date the rows was last updated through ingestion| null| null| null  
  
Table 1.2: BQ: productseason_validated_table

**Column names**|  product_code| attribute_name| attribute_value| season_start_date| season_end_date| product_time_attributes_id| updated_at| updated_by| feed_updated_date|   
---|---|---|---|---|---|---|---|---|---|---  
**Column mapping:** productseason_validated_table| product_code| attribute_name| attribute_value| start_time| end_time| product_time_attr_id| updated_at| updated_by| feed_updated_date|   
  
Table 1.3: PG table- public.productseason_validated

**Column names**|  product_code| attribute_name| attribute_value| season_start_date| season_end_date| product_time_attributes_id| updated_at| updated_by| feed_updated_date|   
---|---|---|---|---|---|---|---|---|---|---  
  
Table 1.4: global.aggregation_time_attributes

**Column names**|  aggregation_code| attribute_name| attribute_value| start_time| end_time| aggregation_attr_id| updated_by| updated_at|   
---|---|---|---|---|---|---|---|---|---  
**Default Logic**|  style from product_attributes_filter where is_active=true| status| active or inactive based on logic| timeframe| timeframe| unique ID generated at an article level| null | null|   
  
Table 1.5 global.product_time_attributes

**Column names**|  product_code| attribute_name| attribute_value| start_time| end_time| product_time_attr_id| updated_by| l0_name| updated_at  
---|---|---|---|---|---|---|---|---|---  
**Description**|  All active product_codes from the product master feed shared by the client |  status| active by default.   
  
Users can change the status of the product for the relevant timeframes (start_time and end_time | By default, the date will the date pushed from BQ. Users can update this date to a values of their choice based on business use case| Max date supported by the system 2050-12-31Users can update this date to a values of their choice based on business use case| This is the unique id provided in the table at product_code, attibute_name, attribute_value, start_time and end_time level| By default null.   
  
This will save the id of the user who updated configurations for the row| Product Hierarchy | By default null. This will save the timestamp at which the user updated the row  
  
### Store Status

#### Workflow: 

  1. The data is set up for the first time through data ingestion. IA uses the default rule to set up the store status table in BQ. 

     1. Ingestion is directly run on the store_status table in BQ. Refer to Table 1.1 for schema of sku_status

     2. The table store_status table in BQ is inserted with new rows obtained and existing rows have their status updated (data is upserted)

     3. Insert rows: pick active stores (where active=true) from the store master and map them as active from the current date to 2050-12-31. The date "2050-12-31" is the maximum date that can be used by the IS tool.

     4. Update: existing products in store_status that are shared as inactive in the store master will have their status changed to inactive for all the timeframes present in the table.

  2. The delta rows are created by querying the rows where feed_updated=current date() in store_status to create storeseason_validated_table.

     1. The table in BQ: storeseason_validated_table. Refer to Table 1.2 below

     2. Ingestion query name: storeseason_validated_table

     3. This is a full replacement query

  3. The data ingested in BQ (delta rows only) storeseason_validated_table will be pushed to Postgres public schema through ingestion.

     1. The table in PG public schema: public.storeseason_validated_table. Please refer to table 1.3 for schema

     2. Data from public.storeseason_validated_table gets upserted in global.store_time_attributes. Please refer to table 1.5 for global.storeseason_validated_table schema

  4. Any edits made in the tool are directly updated in the Postgres table global.store_time_attributes

  5. After a designated time when users are expected to be logged out of the tool (towards the end of the day, for example, 7 pm CST) and before periodic ingestion begins, the edits are to be back synced from PG to BQ. 

     1. Back syncs are set up in Data Flows

     2. Through the back sync process, we fully replace the table store_status

  6. Back-syncing the table from PG to BQ ensures:

     1. The data in both platforms are in sync

     2. This information is used to modify the active status of the store in the next ingestion in the store_attributes_filter table to be used in CNA and Auto Allocation

  7. In Periodic ingestion that follows,uses the back synced store_status and store_master to update its active flag

     1. It refers to edits from store_status (after back sync- back syncs are to be completed before ingestion starts): Since the store_attribute_filter table is not time-phased, the status of the product where the current date is between start_time and end_time is considered.

     2. and store_master active= true/ false is used

     3. When there is a status conflict between the product master feed and store_status user edits then the store master feed update takes the higher precedence

  8. Since store_status is back synced to BQ with user edits towards the end of the client day and paf refers to this for updates in ingestion, there will be a day's lag in store_status updates reflecting in store_attributes_filter and CNA.




Table 1.1: BQ table - store_status

**Column names**|  store_code| attribute_name| attribute_value| start_time| end_time| feed_updated_date| store_time_attr_id| updated_at| updated_by  
---|---|---|---|---|---|---|---|---|---  
**Default Logic in Ingestion**|  product_codes from the product master feed shared by the client | status| active or inactive based on active flag shared in the feed | The date the product code is added to the table as active | Max date supported by the system 2050-12-31| the date the rows was last updated through ingestion| null| null| null  
  
Table 1.2: BQ: productseason_validated_table

**Column names**|  store_code| attribute_name| attribute_value| season_start_date| season_end_date| store_time_attr_id| updated_at| updated_by| feed_updated_date|   
---|---|---|---|---|---|---|---|---|---|---  
**Column mapping:** productseason_validated_table| store_code| attribute_name| attribute_value| start_time| end_time| store_time_attr_id| updated_at| updated_by| feed_updated_date|   
  
Table 1.3: PG table- public.productseason_validated

**Column names**|  store_code| attribute_name| attribute_value| season_start_date| season_end_date| store_time_attr_id| updated_at| updated_by| feed_updated_date|   
---|---|---|---|---|---|---|---|---|---|---  
  
Table 1.5 global.store_time_attributes

**Column names**|  store_code| attribute_name| attribute_value| start_time| end_time| store_time_attr_id| updated_by| l0_name| updated_at  
---|---|---|---|---|---|---|---|---|---  
**Description**|  All active store_codes from the store master feed shared by the client |  status| active by default. Users can change the status of the store for the relevant timeframes (start_time and end_time | By default, the date will the date pushed from BQ. Users can update this date to a values of their choice based on business use case| Max date supported by the system 2050-12-31Users can update this date to a values of their choice based on business use case| This is the unique id provided in the table at product_code, attibute_name, attribute_value, start_time and end_time level| By default null. This will save the id of the user who updated configurations for the row| Product Hierarchy | By default null. This will save the timestamp at which the user updated the row  
  
Store-DC Mapping

Workflow:

  1. The data is set up for the first time through data ingestion. IA uses the default rule to set up the store-DC mapping table in BQ.

     1. Ingestion is directly run on the store_dc_mapping table in BQ. Refer to Table 3.1 for schema of store_dc_mapping 

     2. Insert rows: pick active stores (from the store_status table for the current_date) and map it to all DCs

        1. Active stores in store_status : store_codes where current date() between start_time and end_time and attibute_value='active'

        2. Stores and DCs that are active for the current date as per store/DC status

     3. Update: The is_active column is updated accordingly for existing store-dc combinations

     4. The feed_updated=current_date() for rows that were newly inserted or updated

  2. The delta rows are created by querying the rows where feed_updated=current date() in store_dc_mapping to create store_dc_mapping_delta.

     1. The table in BQ: store_dc_mapping_delta. Refer to Table 3.2 below

     2. Ingestion query name: store_dc_mapping_delta

     3. This is a full replacement query

  3. The data ingested in BQ (delta rows only) store_dc_mapping_delta will be pushed to Postgres public schema through ingestion.

     1. The table in PG public schema: public.store_dc_mapping_delta. Please refer to Table 3.3 for the schema

     2. The public.store_dc_mapping_delta is a fully replaced table in PG

  4. The public.store_dc_mapping_delta gets upserted into product_mapping_store_dc in global through an SP sync_store_dc_mapping

  5. product_mapping_store_dc in global is not a table. it is one of the partitions of the product_mapping table. Refer to Image 3.1

  6. Refer to Table 3.4 for the schema of product_mapping_store_dc

  7. The Store-DC Mapping screen in the tool points to the PG tables:




Table 3.1: BQ- store_dc_mapping

**Column names**|  mapping_type| store_code| dc_code| is_active| feed_updated_date| updated_at| updated_by  
---|---|---|---|---|---|---|---  
**Default Logic in Ingestion**|  store-dc| active stores from store_status| active Dcs| active or inactive status of the store-dc| the date the rows was last updated through ingestion| null| null  
  
Table 3.2: BQ- store_dc_mapping_delta

**Column names**|  mapping_type| store_code| dc_code| is_active| feed_updated_date| updated_at| updated_by  
---|---|---|---|---|---|---|---  
**Default Logic in Ingestion**|  store-dc| active stores from store_status| active Dcs| active or inactive status of the store-dc| the date the rows was last updated through ingestion| null| null  
  
Table 3.3: PG- public.store_dc_mapping_delta

**Column names**|  mapping_type| store_code| dc_code| is_active| feed_updated_date| updated_at| updated_by  
---|---|---|---|---|---|---|---  
**Default Logic in Ingestion**|  store-dc| active stores from store_status| active Dcs| active or inactive status of the store-dc| the date the rows was last updated through ingestion| null| null  
  
Image 3.1 

![](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696609990/Screenshot%202025-01-24%20at%2012.47.31%E2%80%AFPM.png?version=1&modificationDate=1779356644499&cacheVersion=1&api=v2&width=527&height=462)

Table 3.4: PG- product_mapping_store_dc partition of global.product_mapping

**Column names**|  mapping_code| mapping_type| product_code| store_code| dc_code| fc_code| is_active| validity_start_date| validity_end_date| created_at| created_by| updated_at| updated_by| vendor  
---|---|---|---|---|---|---|---|---|---|---|---|---|---|---  
**Default Value**|  unique mapping_code at store-dc| store-dc| null| active stores from store_status (linked to store_code of store_master)| active Dcs(linked to distribution centre - dc code)| null| active or inactive status of the store-dc| null| null| the timestamp of when the entry was added| nulll | null| null| null  
  
Product-DC Mapping

Workflow:

  1. The data is set up for the first time through data ingestion. IA uses the default rule to set up the product-DC mapping table in BQ.

     1. Ingestion is directly run on the product_store_mapping table in BQ. Refer to Table 4.1 for schema of product_store_mapping 

     2. Insert rows: obtain new product-dc mapping table using product_store_mapping and store_dc_mapping 

        1. Join product_store_mapping and store_dc_mapping using store_code and obtain the combinations

     3. Update: The is_active column is updated accordingly for existing store-dc combinations based on current active eligibility (same logic as b.i)

     4. The feed_updated=current_date() for rows that were newly inserted or updated

  2. The delta rows are created by querying the rows where feed_updated=current date() in product_dc_mapping to create product_dc_mapping_delta.

     1. The table in BQ: product_dc_mapping_delta. Refer to Table 4.2 below

     2. Ingestion query name: product_dc_mapping_delta

     3. This is a full replacement query

  3. The data ingested in BQ (delta rows only) product_dc_mapping_delta will be pushed to Postgres public schema through ingestion.

     1. The table in PG public schema: public.product_dc_mapping_delta. Please refer to Table 4.3 for the schema

     2. The public.product_dc_mapping_delta is a fully replaced table in PG

  4. The public.product_dc_mapping_delta gets upserted into product_mapping_product_dc in global through an SP sync_product_dc_mapping

  5. product_mapping_product_dc in global is not a table. it is one of the partitions of the product_mapping table. Refer to Image 4.1

  6. Refer to Table 4.4 for the schema of product_mapping_product_dc

  7. The Product-DC Mapping screen in the tool points to the PG tables:




Table 4.1: BQ- product_dc_mapping

**Column names**|  mapping_type| product_code| dc_code| is_active| feed_updated_date| updated_at| updated_by  
---|---|---|---|---|---|---|---  
**Default Logic in Ingestion**|  product-dc| product obtained by joining product_store_mapping and store_dc_mapping. products that have active dc mapped to it| product obtained by joining product_store_mapping and store_dc_mapping. dcs that have active mapping to products| active or inactive status of the product-dc| the date the rows was last updated through ingestion| null| null  
  
Table 4.2: BQ- product_dc_mapping_delta

**Column names**|  mapping_type| product_code| dc_code| is_active| feed_updated_date| updated_at| updated_by  
---|---|---|---|---|---|---|---  
**Default Logic in Ingestion**|  product-dc| product obtained by joining product_store_mapping and store_dc_mapping. products that have active dc mapped to it| product obtained by joining product_store_mapping and store_dc_mapping. dcs that have active mapping to products| active or inactive status of the product-dc| the date the rows was last updated through ingestion| null| null  
  
Table 4.3: PG- public.store_dc_mapping_delta

**Column names**|  mapping_type| product_code| dc_code| is_active| feed_updated_date| updated_at| updated_by  
---|---|---|---|---|---|---|---  
**Default Logic in Ingestion**|  product-dc| product obtained by joining product_store_mapping and store_dc_mapping. products that have active dc mapped to it| product obtained by joining product_store_mapping and store_dc_mapping. dcs that have active mapping to products| active or inactive status of the product-dc| the date the rows was last updated through ingestion| null| null  
  
Image 4.1 

![](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696609990/Screenshot%202025-01-24%20at%202.25.09%E2%80%AFPM.png?version=1&modificationDate=1779356644498&cacheVersion=1&api=v2&width=501&height=457)

Table 4.4: PG- product_mapping_store_dc partition of global.product_mapping

**Column names**|  mapping_code| mapping_type| product_code| store_code| dc_code| fc_code| is_active| validity_start_date| validity_end_date| created_at| created_by| updated_at| updated_by| vendor  
---|---|---|---|---|---|---|---|---|---|---|---|---|---|---  
**Default Value**|  unique mapping_code at product-dc| product-dc| linked to product_master- product_code| null| linked to distribution centre - dc_code| null| active or inactive status of the store-dc| null| null| the timestamp of when the entry was added| nulll | null| null| null

