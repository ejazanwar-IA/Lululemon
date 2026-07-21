# Decision Dashboard Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696610422` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610422/Decision+Dashboard+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:09.846Z |
| Last mirrored | 2026-05-21 |

---

**Objective:** This document aims to provide a comprehensive understanding of the general flow and logic-related queries for Decision Dashboard and its tickets. It will help user to under the Dashboard module flow systematically and resolve new queries.

**Workflow:**

After applying the mandatory filters and the user will see the 4 main sections of the dashboard screen.

  1. **KPI Cards:** Here, the user will see different KPI cards which tells the current inventory position of Store and DC, Weeks of Coverage, Sell Through rate etc. Below is the detailed list of KPIs. 

![image-20250123-172736.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610422/image-20250123-172736.png?version=1&modificationDate=1779356650540&cacheVersion=1&api=v2&width=736&height=92)
     1. **Store OH Units -** This represents the total Beginning of Period On Hand inventory present for all the Master Styles in the attached stores for the selected filters. 

     2. **Store OH + IT Units -** This represents the total Beginning of Period On Hand and In Transit inventory present for all the Master Styles in the attached stores for the selected filters.

     3. **Store OH + IT + OO Units -** This represents the total Beginning of Period On Hand, In Transit and On Order inventory present for all the Master Styles in the attached stores for the selected filters.

     4. **Sell Through % -** The sell-through rate (STR) is a metric that helps you measure how quickly products are sold through in a given period. It is calculated based on L6M Sales/(L6M Sales + Total Inventory) at an Article-Store level.

     5. **Last 6 Months Sell Through % -** Based on the last 6 month’s sales, how quickly the products are likely to be sold. This KPI is calculated using the weighted average of store total inventory. 

        * _sum(sell_through_perc * tot_inv) / sum(tot_inv)_

     6. **Store WOS (OH) -** It represents the number of weeks the On Hand Store inventory of the selected Master Styles can cover the forecasted demand across all the associated stores. 

     7. **Store WOS (OH + IT) -** It represents the number of weeks the combined Store On Hand and In Transit inventory can fulfil the forecasted demand of all the attached stores for the filtered Master Styles.

     8. **Store WOS (OH + IT + OO) -** It represents the number of weeks the combined Store On Hand, In Transit and On Order inventory can fulfil the forecasted demand of all the attached stores for the filtered Master Styles.

     9. **Store In-Stock % -** It represents the percentage of sizes available in stores where on-hand inventory is greater than 0, calculated as the ratio of "In Stock Count" to "In Stock Total" for each store.

        * _This KPI is calculated by taking the average of the in-stock % for the given filters._

     10. **In-Stock with DC ATA % -** It represents the percentage of sizes available in the DC where ATA inventory is greater than 0, calculated as the ratio of "In Stock Count" to "In Stock Total".

     11. **DC In-Stock % -** This represents the percentage of sizes available in the DC where on-hand inventory is greater than 0, calculated as the ratio of "In Stock Count" to "In Stock Total" for each DC.

     12. **DC ATA (OH) -** This is the total Master SKUs DC inventory available to allocate aggregated for the selected product filters. 

     13. **DC WOS (OH) -** It represents the number of weeks the combined DC On Hand, In Transit and On Order inventory can fulfil the forecasted demand of all the attached Stores for the filtered Master Styles.




**Tables:**

  * **BQ -** [_**Article_inventory_dashboard**_](https://impactanalytics.atlassian.net/wiki/spaces/ISP/pages/1348797269)

  * **PG -**_Article_inventory_dashboard_




  2. **View Allocation Plan:** This section provides a summary of all allocations made throughout the day. Users can also create a new allocation plan by clicking the "Create New Allocation Plan" button, which will direct them to the Create New Allocation screen. 

![image-20250123-191247.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610422/image-20250123-191247.png?version=1&modificationDate=1779356650539&cacheVersion=1&api=v2&width=736&height=288)



  3. **Alerts:** Alerts section is categorized in the following 3 sub-sections.

![image-20250123-193550.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610422/image-20250123-193550.png?version=1&modificationDate=1779356650274&cacheVersion=1&api=v2&width=736&height=202)

     1. **Allocation -** This will have customized Allocation alerts based on the Store Inventory.

        1. **Overstock:** This alert displays a list of Master Style - Store combinations for which the majority of its Master Styles-Store combinations are tagged as Overstock, i.e., where the F.WOS falls below a specified threshold. For example, if the F.WOS is greater than or equal to 12 for any combination, it will be flagged as a overstock. User will be navigated to the “Create New Allocation” Screen from this alert. 

        2. **Understock:** This alert displays a list of Master Style - Store combinations for which the majority of its Master Styles-Store combinations are tagged as Understock, i.e., where the F.WOS falls below a specified threshold. For example, if the F.WOS is less than or equal to 2 for any combination, it will be flagged as a understock. User will be navigated to the “Create New Allocation” Screen from this alert. 

        3. **Stockout:** This alert displays a list of Master Style - Store combinations for which the majority of its Master Styles-Store combinations are tagged as Stockout, i.e., where the F.WOS falls below a specified threshold. For example, if the F.WOS is less than or equal to 2 for any combination, it will be flagged as a stockout. User will be navigated to the “Create New Allocation” Screen from this alert. 

        4. **Shortfall:** This alert displays a list of Master Style - Store combinations for which the majority of its Master Styles-Store combinations are tagged as Shortfall, i.e., where the F.WOS falls below a specified threshold. For example, if the F.WOS is less than or equal to 3 but greater than 2 for any combination, it will be flagged as a shortfall. User will be navigated to the “Create New Allocation” Screen from this alert. 

        5. **Auto Allocation:** This alert shows the list of plans that run through auto allocation, needing input from user to either create allocation/ move to allocation batching

        6. **PO to Allocate:** This alert can be leveraged to pre-allocate the Open POs for launch SKUs. Users will be navigated to the “Create New Allocation” Screen from this alert 

     2. **Forecast -** This will have the customized forecast related alerts

        1. Store Level Forecast Inaccurate

        2. Style Level Forecast Inaccurate

        3. Forecast is 0

     3. **OMS -** This will have the customized OMS alerts.




**Common Metrics in the Allocation Alerts:**

**Field Name**| **Description**  
---|---  
Master SKU ID/Choice/Article| Style - Color ID  
Master SKU Description| Master SKU/Choice/Article Description  
l0_name| Product Hierarchy - Group  
l1_name| Product Hierarchy - Division  
l2_name| Product Hierarchy - Buyer  
primary_trait_id| Product Hierarchy - Primary Trait ID  
primary_trait_desc| Product Hierarchy - Primary Trait Desc  
l3_name| Product Hierarchy - Department  
l4_name| Product Hierarchy - Class  
l5_name| Product Hierarchy - Sub Class  
LW_Units| Last Week Sales Units  
LW Revenue $| Last Week Sales Revenue  
LW Margin $| Last Week Sales Margin  
Store OH| Current Store On Hand Inventory  
Store OO| On Order Inventory In Store  
In Transit to Store| In Transit Inventory To Store  
OH + OO + IT| Sum of store OH, OO and IT inventory  
WOS (OH)| Future Weeks Of Supply Of Stores (OH)  
WOS (OH + IT)| Future Weeks Of Supply Of Stores (OH + IT)  
WOS (OH + OO + IT)| Future Weeks Of Supply Of Stores (OH + OO + IT)  
Store Count - Stockout| # of Stores in stockout status (WOS <=1) for the corresponding Article  
Store Count - Shortfall| # of Stores in shortfall status (2<=WOS <=3) for the corresponding Article  
Store Count - Overstock| # of Stores in overstock status (WOS >=12) for the corresponding Article  
Store Count - Normal| # of Stores in normal status (4<=WOS < 12) for the corresponding Article  
  
**Common Metrics in the Forecasting Alerts:**

**Field Name**| **Description**  
---|---  
Master SKU ID/Choice/Article| Style - Color ID  
Master SKU Description| Master SKU/Choice/Article Description  
l0_name| Product Hierarchy - Group  
l1_name| Product Hierarchy - Division  
l2_name| Product Hierarchy - Buyer  
primary_trait_id| Product Hierarchy - Primary Trait ID  
primary_trait_desc| Product Hierarchy - Primary Trait Desc  
l3_name| Product Hierarchy - Department  
l4_name| Product Hierarchy - Class  
l5_name| Product Hierarchy - Sub Class  
Store OH| Current Store On Hand Inventory  
Store OO| On Order Inventory In Store  
In Transit to Store| In Transit Inventory To Store  
OH + OO + IT| Sum of store OH, OO and IT inventory  
Past 4 Weeks Actuals| Actual Sales in the last 4 weeks  
Next 4 Weeks Forecast| Forecast for the next 4 weeks  
  
**Tables:**

  * **BQ -** Article_inventory_dashboard

  * **PG -** Article_inventory_dashboard, Alert_Product_level, Alert_product_store_level



  4. **Details:** Details table will provide a detailed view of all the available Styles for the selected filters. It shows the Sales Performance metrics, current store inventory position, current DC Inventory position, WOS for both Store and DC, DC Inventory (Available to Allocate) and Count of Store having inventory in excess, stockout, shortfall or normal (threshold can be customized as per the client). 

![image-20250123-221806.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610422/image-20250123-221806.png?version=1&modificationDate=1779356650273&cacheVersion=1&api=v2&width=736&height=308)



Users can select one or more than one Master Styles at a time and can check the inventory position, review stores where the flag is Shortfall/Stockout/Excess/Normal. Users can create a new allocation plan from the details table and upon clicking on the Create Allocation button, it will be directed to the “Create New Allocation” Screen.

![image-20250123-222019.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610422/image-20250123-222019.png?version=1&modificationDate=1779356650273&cacheVersion=1&api=v2&width=730&height=546)

**Tables:**

  * **BQ -** [**Article_inventory_dashboard**](https://impactanalytics.atlassian.net/wiki/spaces/ISP/pages/1348797269/40+article_inventory_dashboard?atlOrigin=eyJpIjoiMzFkY2RkMGM0MjhjNDdkZmFhZjVjMzFmOWZiNGFjZmIiLCJwIjoiYyJ9)

  * **PG -** Article_inventory_dashboard




**Table Schema:**_Article_Inventory_Dashboard_

**Field Names**| **Description**  
---|---  
article| Style-Color Id  
style| Style  
style_description| Style Description  
l0_name| Product Hierarchy - Group  
l1_name| Product Hierarchy - Division  
l2_name| Product Hierarchy - Buyer  
primary_trait_id| Product Hierarchy - Primary Trait Id  
primary_trait_desc| Product Hierarchy - Primary Trait Desc  
l3_name| Product Hierarchy - Department  
l4_name| Product Hierarchy - Class  
l5_name| Product Hierarchy - Sub Class  
product_type| Product Attribute - Product Type  
item_status| Product Attribute - Item Status  
launch_date| Product Attribute - Launch Date  
clearance| Product Attribute - Clearance Flag  
clearance_start_date| Product Attribute - Clearance Start Date  
store_code| Store Code  
store_name| Store Hierarchy - Store Name  
channel| Store Hierarchy - Channel  
store_tier| Store Attribute - Store Grade  
price| Product Attribute - Price  
msrp| Product Attribute - Msrp  
oh| On Hand Inventory Store  
it| In Transit Inventory To Store  
oo| On Order Inventory In Store  
total_inv| Total Store Inventory (OH+IT+OO)  
lw_units| Last Week Sales Units  
lw_margin| Last Week Sales Margin  
lw_revenue| Last Week Sales Revenue  
l4w_units| Last 4 Weeks Sales Units  
l4w_revenue| Last 4 Weeks Sales Revenue  
l8w_units| Last 8 Weeks Sales Units  
l6m_units| Last 6 Weeks Sales Units  
discount| DisCount offered  
promo_percentage| Promotion %  
wos_oh_oo_it| Future Weeks Of Supply Of Stores (OH+OO+IT)  
wos_oh_oo| Future Weeks Of Supply Of Stores (OH+OO)  
wos_oh_it| Future Weeks Of Supply Of Stores (OH+IT)  
wos_oh| Future Weeks Of Supply Of Stores (OH)  
dc_wos_oh_oo_it| Future Weeks Of Supply Of DC (OH+OO+IT)  
dc_wos_oh_oo| Future Weeks Of Supply Of DC (OH+OO)  
dc_wos_oh| Future Weeks Of Supply Of DC (OH)  
stockout| Stock Out Flag  
shortfall| Shortfall Flag  
excess| Excess Flag  
normal| Normal Flag  
sell_through_perc| Last 6 Months Sell Through %  
instock_perc| Percentage Of Inventroy In The Store  
dc_instock_perc| Ratio of Product-Store having OH > 0 to All the eligible Product-Stores  
ata_eaches| Available To Allocate Eaches  
ata_packs| Available To Allocate Of Packs After Configuration  
ata| Total Available To Allocate Inventory  
dc_instock| Total DC OH  
oo_dc| On Order Inventory In DC  
it_dc| In Transit Inventory In DC  
oh_dc| Present On Hand Inventory In DC  
in_stock| Flag Where OH > 0  
in_stock_count| Count of Products Having OH > 0 At Article Store Level  
total_count| Count of Baby SKUs (sizes) within Article  
dc_instock_count| Count of Products Having ATA > 0 At Article Store Level  
dc_instock_total_count| Count of Products In Article  
in_stock_dc_ata_count| Count of Products Having OH > 0 And ATA > 0  
in_stock_dc_ata_total_count| Count of Products Having ATA > 0  
in_stock_ata| Total Store Inv + Total DC OH  
allocated_units| Number of units allocated from DC to Store  
  
**Query:**[**Store_stock_drilldown**](https://impactanalytics.atlassian.net/wiki/spaces/ISP/pages/1348797245/39+store_stock_drilldown?atlOrigin=eyJpIjoiMmZjNzY4NjIwYTM4NDQ0YmE4ZjBiZWE4ZGIzMTQxZDAiLCJwIjoiYyJ9)**table is mainly used in**[**Article_inventory_dashboard**](https://impactanalytics.atlassian.net/wiki/spaces/ISP/pages/1348797269/40+article_inventory_dashboard?atlOrigin=eyJpIjoiMzMxMDc4MTIwNDY0NDg0ODlmMmIxNTE4OWIxMzUxYzEiLCJwIjoiYyJ9)**** ****

**Frequently Asked Questions (FAQs):**

  1. Why does the user not seeing anything in View Allocation Plan table?

     * User might not see any plan in the View Allocation Plan table because either the plan may have been moved to Order Batching or the plan may have been purged. Plan purge can be configured based on the client requirements. 




