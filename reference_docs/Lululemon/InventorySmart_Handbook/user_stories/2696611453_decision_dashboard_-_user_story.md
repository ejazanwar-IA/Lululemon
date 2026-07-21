# Decision Dashboard - User Story

| Field | Value |
|---|---|
| Confluence page ID | `2696611453` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:30.901Z |
| Last mirrored | 2026-05-21 |

---

| **Update Date** | **Updated By** | **Description** |
| --- | --- | --- |
| <custom data-type="date" data-id="id-0">5/7/2026</custom> | <custom data-type="mention" data-id="id-1">@Navin Chandan</custom> | Updated the details table table view |
| <custom data-type="date" data-id="id-2">5/6/2026</custom> | <custom data-type="mention" data-id="id-3">@Navin Chandan</custom> | Removed mapping columns for the OOTB columns |
| <custom data-type="date" data-id="id-4">4/10/2026</custom> | <custom data-type="mention" data-id="id-5">@Navin Chandan</custom> | Added fc_name and tc_name |
| <custom data-type="date" data-id="id-6">3/27/2026</custom> | <custom data-type="mention" data-id="id-7">@Navin Chandan</custom> | Inventory Details side modal |
| <custom data-type="date" data-id="id-8">3/26/2026</custom> | <custom data-type="mention" data-id="id-9">@Navin Chandan</custom> | Added mapping table, datatype and Nullable column in filters and tables for validation Title case naming as per latest guideline |

# Table of Contents

# Guideline

* The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**
* Filters are configurable as per clients requirement.
* Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**
* Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**
* Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.
* Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field

# User Story **1 - Filters:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> Filters**

## **Jira Description:**

### **Demo link: {Add React Demo - If available}**

The Decision Dashboard has 2 Tabs: 

1. Store Inventory
2. Vendor-DC (DC Replenishment) - If Ordering is not there then this should be removed

This page details out all the components of **Store Inventory** Tab.

Decision Dashboard provides a comprehensive overview of Store Inventory, Draft and WIP Allocation Plans, recommended Alerts, and style-color level details. 

The Store Inventory Tab of Decision Dashboard has 5 parts:

1. **Date Ticker** - This shows the refresh date for the Inventory and transactions and MFP (if available)
2. **KPIs** - Users can see the overall performance metrics on a higher level. KPI serves that functionality. Upon logging into the tool, the user will be directed to the decision dashboard screen. When the relevant filters are applied, the KPI tiles will be created for the selected filters.
3. **View Allocation Plans** - The View Allocation Plans section takes the user to Allocation Plans that have been Created/Saved as drafts and not finalized during the current day. Users can click on individual allocation plans to review, edit, and finalize the allocation at any time during the day. Any saved plans that have not been finalized will be purged/deleted at the beginning of the next day.
4. **Alerts** - This section shows different alerts based on the store inventory, product lifecycle, source of inventory or forecast. Based on the requirement there can be 2 tabs here: Allocation and Forecast.
5. **Details** - The Details table provides key metrics at a Style Color level Sales Performance, Inventory, and Store counts. The style colors present in this table will be populated according to the filters selected. Users can use this section to select any Style Color to proceed with the allocation process.

### Navigation:

Left-hand panel → Decision Dashboard

This is the landing page for the Inventory Smart application.

### Landing Page:

After navigating to the Decision Dashboard user can apply the filters to populate the required information (KPIs, View Allocation Plans, Alerts, Details).

**NOTE:** Only those Style Color should show up here where there is DC available to allocate > 0 (In specific cases, this filter can be removed).

### Filters:

By clicking on ‘**Select Filters**’, the user can apply a set of hierarchy filters to get the list of the articles (Style Color IDs or Styles). Refer to the table below for filter details. Mainly product-related filters are to be present on this screen. Higher level store filter can be added maybe channel or country.

**fc_name : InventorySmartDashboard**

| **Section** | **Filter Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Mandatory** | **Selection Criteria** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Single select |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Multi select |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Store | {S0 Name} | s0_name | global.store_attributes_filter | varchar | No | No | Multi select |

# User Story **2 - Date Ticker and KPIs:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> Date Ticker and KPIs**

## **Jira Description:**

### Date Ticker:

Upon applying the Filters, the date ticker should show the refresh dates at the top of the screen. The following refresh dates should show up:

1. Inventory Refresh Date
2. Transaction Refresh Date
3. MFP Refresh Date (Optional - Required only if MFP data is coming from client)

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=9a16732c597a&id=ed30164b-440a-4a2d-be1e-0ef2eb3ee077&&collection=contentId-2696611453&height=136&occurrenceKey=null&width=1825&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)

‌

### KPIs:

Users can see the overall performance metrics on a higher level. KPI serves that functionality. Upon logging into the tool, the user will be directed to the decision dashboard screen. When the relevant filters are applied, the KPI tiles will be created for the selected filters.

The base table for fetching the KPIs should be article_inventory_dashbpard or/and dashboard_kpi_table. If the KPIs are simple and can be aggregated directly from the article_inventory_dashbpard table then that table should be used. If there are some KPIs that are complex, then that should be computed and stored in the dashboard_kpi_table. Forecast KPIs should be added in the dashboard_kpi_table.

Below is the list of the KPIs with the logic for aggregation:

| **KPI** | **KPI Description** | **KPI Logic (Aggregation)** | **Base Table** |
| --- | --- | --- | --- |
| DC OH | DC On-Hand Units | Sum of DC On Hand (oh) Units.  
To be aggregated at filtered level. | Article Inventory Dashboard |
| DC OO | DC On-Order Units | Sum of DC On Order (oo) Units.  
To be aggregated at filtered level. | Article Inventory Dashboard |
| Store OH Units | Store On-Hand Inventory | Sum of Store OH aggregated at selected filter level | Article Inventory Dashboard |
| Store OO + IT Units | Store On-Order + In-Transit Inventory | Sum of OO + IT aggregated at selected filter level | Article Inventory Dashboard |
| WOS (OH) | Forward-looking WOS (OH) of all Stores | Weighted Average of FWOS with respect to On Hand Inventory at selected filter level. Eg: sum(WOS \* oh) / sum(oh) | Article Inventory Dashboard |
| FWOS | Forward-looking WOS (OH+IT+OO) of all Stores | Weighted Average of FWOS with respect to OH +OO + IT Inventory at selected filter level. | Article Inventory Dashboard |
| Reserve | Reserve Quantity  | Sum of reserve quantity at selected filters | dc_reserve_quantity (quantity) |
| Sales Units (L 4 W) | Sum of sales units in last 4 week | sum of sales_1_ago + sales_2_ago + sales_3_ago + sales_4_ago | Article Inventory Dashboard |
| Size integrity (%) | Percentage of sizes having OH + OO + IT > 0 | Average of OH +OO + IT size integrity (si_oh_oo_it) at selected filter level | Article Inventory Dashboard (si_oh_oo_it) |

**NOTE:** Please adjust the above KPI table as per the requirement. Properly add the KPI Name, aggregation logic and the base table.

### **Acceptance Criteria:**

1. The Decision Dashboard should provide an overview of Store Inventory, Draft and WIP Allocation Plans, recommended Alerts, and style-color level details.
2. The dashboard should be divided into 5 parts: Date Ticker, KPIs, View Allocation Plans, Alerts, and Details.
3. The Date Ticker should show the refresh date for the Inventory and transactions.
4. KPIs should display overall performance metrics at a higher level.
5. The View Allocation Plans section should allow users to review, edit, and finalize allocation plans.
6. The Details table should provide key metrics at a Style Color level for Sales Performance, Inventory, and Store counts.
7. KPI tiles should be created based on the selected filters.
8. The KPI tiles should display overall performance metrics at a higher level.
9. The KPI tiles should be updated in real-time based on the applied filters.
10. The KPI tiles should be prominently displayed on the Decision Dashboard screen.
11. The above mentioned KPIs should be available
12. The KPIs should be aggregated at the selected filter level.

# User Story **3 - View Allocation Plans:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> View Allocation Plans**

## **Jira Description:**

The View Allocation Plans section takes the user to Allocation Plans that have been Created/Saved as drafts or Moved to order Batching and is not finalized during the current day. Users can click on individual allocation plans to review, edit, and finalize the allocation at any time during the day. Any saved plans that have not been finalized will be purged/deleted at the beginning of the next day.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=5b10853eb853&id=fe0525ab-765d-4889-8454-39faaef3e744&&collection=contentId-2696611453&height=93&occurrenceKey=null&width=1830&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
In the Decision Dashboard → Allocation Plans section, 3 metrics should show:

1. Created - Count of created allocations
2. Draft - Count of Draft allocations
3. Moved to Order Batching - Count of Allocations moved to Order Batching

When all Created, Draft and moved to Order Batching count are 0, the the View Details should be disabled.

### **Flow:**

1. Click on the View Details to review the created or drafted plans.
2. A new screen will load with **Allocation Plans** table. The **Allocation Plans** table should have following columns:

**tc_name : inventorysmart_plans_table**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Description** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | Allocation Plan Name |  | inventory_smart.plan_master | varchar | No | Allocation Plan Name | Yes | Yes |
| Product | Style Color ID | article | inventory_smart.plan_attributes | varchar | No | article or Style Color ID or Styles or Choice | No | Yes |
| Custom | Inventory |  | inventory_smart.plan_attributes | varchar | No | Source of inventory for the allocation, DC or PO or ASN | No | Yes |
| Custom | Created By |  | global.user_master | varchar | No | User Name who has created the allocation | Yes | Yes |
| Custom | Created On |  | inventory_smart.plan_attributes | date | No | The date when the allocation is created | Yes | Yes |
| Custom | Status |  | inventory_smart.plan_attributes | varchar | No | The Status of the allocation, Draft or Created | Yes | Yes |
| Custom | # Allocated Style Colors |  | inventory_smart.plan_attributes | int4 | No | Number if Style Color which are present in the allocation | No | Yes |
| Custom | # Allocated Stores |  | inventory_smart.plan_attributes | int4 | No | Number of Stores which are allocated | No | Yes |

3.  Select an allocation plan and click on edit icon
4. For allocations with status **Created or Moved to Order Batching**, the user will be redirected to the **Create New Allocation → Recommendation** screen. Users can make any edits on top of the existing plan and move to order batching or finalize the allocation.
5. For allocations with status **Draft**, the user is redirected to **Create New Allocation → Allocation Plan Input** screen. Users can make any edits in the previous draft and create and finalize the allocation.
6. The User can also create a new allocation using the button **Create Allocation Plan**.
7. The User can also delete the selected plans using the delete option above the table.

If more than one plan is selected then only trashcan icon (delete) should show up. For edit flow only one allocation should be selected.

### **Acceptance Criteria:**

1. The View Allocation Plans section should display allocation plans created or saved as drafts.
2. Users should be able to click on individual allocation plans to review, edit, and finalize them.
3. Any saved plans that have not been finalized should be purged / deleted at the beginning of the next day.
4. The View Allocation Plans table should have columns as per the above table
5. Review the list of allocations based on the selected filters that are saved as Draft/Created but not finalized.
6. Click on the Edit column to edit the allocation plan. This should redirect to the ‘Recommendation’ screen of the Create New Allocation module if the allocation is created.
7. The screen should redirect to Create New Allocation -> Allocation Plan Input screen in case of Draft allocation.
8. Create a new allocation using the button → Create New Allocation Plan.
9. Delete selected plans using the delete option above the table or against individual plans.
10. Screen load time for cascaded filters - within 1-2 secs, product loading after applying filters - within 3 sec

# User Story **4 - Alerts:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> {} Alerts (This is for the us to know how the Alerts screen should look, no need to create ticket for this. Create tickets for specific alerts that is required)**

## **Jira Description:**

This section shows different alerts based on the store inventory, product lifecycle, source of inventory or forecast. This section can have 2 tabs depending upon the client requirement:

1. Forecast - This will be available only if there is forecast Alerts. Example - Recent Deviation, Sales vs Forecast Comparison
2. Allocation - This will be available if there are inventory or product cycle based alerts. Example - Clearance, Stockout, etc.

‌

Following alerts can be configured (The are some sample alerts. Based on client’s requirement, alerts can vary):

1. Clearance - Style Colors which are in Clearance (If Retirement then Retirement Alert)
2. Newly Launched - Style Colors which recently launched in last 1 month or going to launch (The launch date filter can vary)
3. Overstock - Style Colors having Overstock inventory in most of the stores based on the Forward weeks of supply **tc_name : overstock_alerts_table**
4. Shortfall - Style Colors having Shortfall inventory in most of the stores based on the Forward weeks of supply - **tc_name : shortfall_alerts_table**
5. Stockout - Style Colors having Stockout inventory in most of the stores based on the Forward weeks of supply - **tc_name : stockout_alerts_table**
6. Auto Allocation -  IA generated auto allocations pending for manual review and move to order batching or finalize.
7. PO To Allocate - Open purchase orders ready for manual pre-allocations either for new styles or older ones
8. ASN To Allocate - ASN which are ready for manual pre-allocations either for new styles or older ones
9. Recent Deviation - Choices where next 4 weeks IA forecast deviates by +/-50% from past 4 weeks actuals - **tc_name : recent_deviation_alert_table**

### **Infographic Chart:**

In the Alert section, at the top, for each tab, infographic chart should show up with following details:

* An **infographic-style summary chart** will be displayed at the **top of the Alerts section**.
* It will visually highlight the **real-time distribution of alerts** using summary blocks
* The chart will show:

    * **Overall** – Total number of articles. This is populated as a simple aggregation of the number of styles/articles from the Alerts main table
    * **Reviewed** – Total number of reviewed articles.
    * **Pending** – Calculated as _(Total Articles - Reviewed Articles)_.
    

**Note:** An article is marked as **Reviewed** when the user clicks on **"Review Recommendations"** and **views the details**.

* This gives users a **quick snapshot** of the alert distribution before they scroll down to view individual alert rows in detail.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=e85a57dc393b&id=37867fe0-6e60-45d8-8ebf-8561361172cb&&collection=contentId-2696611453&height=57&occurrenceKey=null&width=447&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
### **Example:**

| **Alert** | **KPI** | **Total** | **Reviewed** |
| --- | --- | --- | --- |
| Stockout and Shortfall | No. of Choices | 100 | 20 |
| New Store Reserve | No. of Stores | 35 | 0 |
| **Total** |   | **135** | **20** |

Here, **Overall** = 135  
          **Reviewed** = 20  
          **Pending** = 115

‌

The process flow to Review Recommendations for each of the these Allocation alerts are as follows:

* Go to the Decision Dashboard. Click on “Select Filters”
* Apply specific filters based on your preferences and proceed by clicking on “Apply Filter”.
* Navigate to the “Alerts” section. All the Allocation alerts are listed here.
* Click on “Review Recommendation” corresponding to the alert of interest.
* Select the relevant style/s and click on “Create New Allocation” to proceed with the Allocation.

### **Alert Layout - Card Based:**

Below the infographic chart, each alert should show in a separate card, with dynamic columns based on alert type. For each alerts what column or metrics, we need to show can be configured.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=a9188cafb641&id=5ba11f9d-e049-4149-b2c7-877191dc1901&&collection=contentId-2696611453&height=324&occurrenceKey=null&width=1606&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
**Alert Description Tooltip:** Hovering over the description of the alert should display the full description in a tooltip.

**Embedded Recommendation Sub-Table**

* Clicking on **Review Recommendation** of a specific alert row will expand a **view**.

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=2e79dc48c291&id=0bfef719-3ac3-4034-ab68-2f637d0ff5b6&&collection=contentId-2696611453&height=482&occurrenceKey=null&width=1789&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
* This will display a **Review** **Recommendation table** within the same screen, without navigating the user away.
* In case of **Allocation Alerts** like Shortfall, Overstock, Stockout, Clearance, Newly launched (markdown, retirement), etc, users can click select the articles (style colors or styles or choices) and click on Create Allocation to move to the CNA screen. In CNA screen user can create the allocation and move to order batching or finalize it
* In case of **Allocation Alerts** like **PO To Allocate and ASN To Allocate**:

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=7141fe768203&id=c555d117-94a5-4d1e-ba47-0c51563fa36b&&collection=contentId-2696611453&height=423&occurrenceKey=null&width=1791&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)

    * User can click on **Review** button for any one row which will open another table in the same screen
    * User can select the articles (style colors or styles or choices) and click on Create Allocation to move to the CNA screen. In CNA screen user can create the allocation and move to order batching or finalize it
    
* In case of **Allocation Alerts → Auto Allocation**, User can click on **Review** button for any one row which will open another table in the same screen. In the 2nd table users can select one or more article and then click on Review to Review the already created allocation. User can then move the allocation to Order Batching or Finalize.
* In case of **Forecast Alerts**, Users can select the articles (style colors or styles) and click on the **Go To ADA Visual Dashboard**. Users should be redirected to the ADA Visual → Adjusted Forecast tab where the forecast data should populate only for the selected articles (style colors or styles)

**Highlighting of Reviewed Items**

* Alert recommendation rows already reviewed by the user will be **visually highlighted**.
* This acts as a soft indicator — the user can still interact with or re-review the same rows.

### **Acceptance Criteria:**

1. Two tabs should show at the top of the Alert Section - Allocation and Forecast. If the requirement is there for only one Alerts section then the tab is not required.
2. The infographics should at the top for each tab. Resolved and Pending count should update based on the Reviewed items in real time.
3. All alerts are listed in card format with flexible columns for alert-specific parameters.
4. Hovering over the description of the alert should display the full description in a tooltip.
5. Alert rows can be expanded to show a recommendation sub-table inline.
6.  For the **Auto Allocation** and **PO To Allocate or ASN To Allocate**, or any other alerts that involve **an additional intermediate step**, an additional 2nd layer table should load.
7. Reviewed recommendation rows are clearly highlighted.
8. Previously reviewed rows remain fully interactive.
9. For allocation alerts, the redirection should properly work to land the users in Create New Allocation screen (Recommendation Screen for Auto allocation)
10. For Forecast alerts, the redirection should properly load the ADA Visual → Adjusted Forecast tab for the selected articles (style colors or styles) 

# User Story **5 - Stockout Alert:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> Stockout Alerts**

## **Jira Description:**

**NOTE**: This is covering the Stockout Alert but similar format can be used for Shortfall Alert (`shrtfl_flg=1`, Overstock Alert (`excs_flg=1`), New Launched Alert (`newly_launched_alert_flag=1`, Clearance Alert (`clearance_alert_flag=1`, Retirement Alert, etc. For each of these case the flag in the backend table, `inventory_smart.alerts_product_level` or `inventory_smart.alerts_product_store_level` will change. 

The style colors (articles or styles) belonging to these alerts at channel (store attribute) or l0_name (product attribute) are exclusive of one another. So, if a style color (articles or styles) is a part of Clearance then it can not be part of any other Allocation alerts, except Auto allocation and PO/ASN To Allocate.

The data for this alerts can be picked up from `inventory_smart.alerts_product_level` or `inventory_smart.alerts_product_store_level` table. Stockout Alerts can be identified by applying the filter of `stckout_flg=1`

In the Alerts Section of the Decision Dashboard the row for stockout should be :

| Stockout | Style Colors having Stockout inventory in most of the stores | #Style Colors 135 | Review Recommendation |
| --- | --- | --- | --- |

**Flow:**

The process flow to Review Recommendations for each of the these Allocation alerts are as follows:

* Go to the Decision Dashboard. Click on “Select Filters”
* Apply specific filters based on your preferences and proceed by clicking on “Apply Filter”.
* Navigate to the “Alerts” section. All the Allocation alerts are listed here.
* Click on “Review Recommendation” corresponding to the alert of interest.
* Select the relevant style/s and click on “Create New Allocation” to proceed with the Allocation.

On clicking the Review Recommendation button, a table will load just the below the Alert row. The table should load with following columns:

**tc_name : stockout_alerts_table** (For each alerts refer to the correct tc_name from the <custom data-type="smartlink" data-id="id-10">https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story#User-Story-4---Alerts%3A</custom> section.

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Style/Style Color ID} | article | inventory_smart.alerts_product_level | varchar | No | Yes | Yes |
| Product | {L0 Name} | l0_name | inventory_smart.alerts_product_level | varchar | No | Yes | Yes |
| Product | {L1 Name} | l1_name | inventory_smart.alerts_product_level | varchar | Yes | Yes | Yes |
| Product | {L2 Name} | l2_name | inventory_smart.alerts_product_level | varchar | Yes | Yes | Yes |
| Product | {L3 Name} | l3_name | inventory_smart.alerts_product_level | varchar | Yes | Yes | Yes |
| Product | {L4 Name} | l4_name | inventory_smart.alerts_product_level | varchar | Yes | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | inventory_smart.alerts_product_level | varchar | Yes | Yes | Yes |
| Custom | LW Units | sales_1_ago | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | LW Revenue $ | lw_revenue | inventory_smart.alerts_product_level | float4 | Yes | No | Yes |
| Custom | LW Margin $ | lw_margin | inventory_smart.alerts_product_level | float4 | Yes | No | Yes |
| Custom | Promo % | promo_percentage | inventory_smart.alerts_product_level | float4 | Yes | No | Yes |
| Custom | AUR | aur | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | Store On Hand | oh | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | Store On Order | oo | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | In Transit to Store | it | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | OH +OO + IT | tot_inv | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | WOS (OH) | wos_oh | inventory_smart.alerts_product_level | float4 | Yes | No | Yes |
| Custom | WOS (OH + IT) | wos_oh_it | inventory_smart.alerts_product_level | float4 | Yes | No | Yes |
| Custom | WOS (OH + OO + IT) | wos | inventory_smart.alerts_product_level | float4 | Yes | No | Yes |
| Custom | Bulk Remaining / Available to Allocate | ata | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | Stockout | stockout | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | Shortfall | shortfall | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | Normal | normal | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |
| Custom | Overstock | excess | inventory_smart.alerts_product_level | int4 | Yes | No | Yes |

### **Acceptance Criteria:**

1. The Alerts section should have all the above mentioned Alerts.
2. Clicking on the Review Recommendation screen should open a popup window which should have details for the Style Colors which are part of that alert. The schema of table should be as per above.
3. The style colors present in the table should be populated according to the selected filters.
4. Users should be able to select any Style Color in the Alerts popup table to proceed with the allocation process.
5. The Create Allocation button in the popup window should direct the user to the Create New Allocation screen module.

| **Table Name** | **Flag** | **Values** | **Comments** |
| --- | --- | --- | --- |
| Alerts_product_level | stckout_flg | 1/0 |  |
| Alerts_product_level | stckout_flg_is_resolved | 1/0 | By Default 0 |
| Alerts_product_store_level | stckout_flg | 1/0 |  |
| Alerts_product_store_level | stckout_flg_is_resolved | 1/0 | By Default 0 |

# User Story **6 - PO To Allocate Alert:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> PO To Allocate Alerts**

## **Jira Description:**

**NOTE**: This is covering the PO To Allocate Alert but similar format can be used for ASN To Allocate Alert also. Backend table to be used for each of these cases:

1. PO To Allocate - `inventory_smart.po_master`
2. ASN To Allocate - `inventory_smart.asn_to_allocate` 

The style colors (articles or styles) belonging to these alerts at channel (store attribute) or l0_name (product attribute) should have some PO (ASN) available to allocate and the delivery date for that PO or ASN should be in future. The delivery date filter can be applied to show only limited PO (ASN). Usually PO (ASN) with expected delivery date in coming 4 or weeks are shown on tool

In the Alerts Section of the Decision Dashboard the row for PO To Allocate should be :

| PO To Allocate | Open Purchase Order Ready for Manual Allocation | #Style Colors 135 | Review Recommendation |
| --- | --- | --- | --- |

**Flow:**

The process flow to Review Recommendations for each of the these Allocation alerts are as follows:

* Go to the Decision Dashboard. Click on “Select Filters”
* Apply specific filters based on your preferences and proceed by clicking on “Apply Filter”.
* Navigate to the “Alerts” section. All the Allocation alerts are listed here.
* Click on “Review Recommendation” corresponding to the PO To Allocate Alert
* On clicking the Review Recommendation button, a table will load just the below the Alert row. The table should load with following columns:

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | PO Number | po_code | inventory_smart.po_master | varchar | No | Yes | Yes |
| Custom | # Style Color {Article or Style/Style Color ID} |  | inventory_smart.po_master | varchar | No | Yes | Yes |
| Custom | Style Color {Article or Style/Style Color ID} |  | inventory_smart.po_master | varchar | No | Yes | Yes |
| Custom | Style Description | Calculated | inventory_smart.po_master | varchar | No | Yes | Yes |
| Custom | Delivery Date | requirement_date | inventory_smart.po_master | date | No | Yes | Yes |
| Custom | Available To Allocate | available_qty | inventory_smart.po_master | int4 | Yes | Yes | Yes |
| Custom | Action |  |  |  |  | No | No |

* Choose a PO Number and click on Review to review the Style Colors {Article or Style/Style Color ID} which are to be allocated. Clicking on Review will open another table in the same screen at Style Color {Article or Style/Style Color ID} level (Style colors which are part of that PO)
* The loaded table should have the following columns:

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | PO Number | po_code | inventory_smart.po_master | varchar | No | Yes | Yes |
| Product | {Article or Style/Style Color ID} | article | inventory_smart.po_master | varchar | No | Yes | Yes |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | global.product_attributes_filter | varchar / date | Yes | Yes | Yes |
| Custom | Available to Allocate | available_qty | inventory_smart.po_master | int4 | No | Yes | Yes |

* Select the Style Colors {Article or Style/Style Color ID} that user wants to allocate and click on **Create New Allocation**. This would direct user to Create New Allocation screen in new tab. In the Create New Allocation screen, the Inv Source should be PO Inv (ASN Inv).

On Create Allocation from Dashboard → PO (ASN) to Allocate Alert, the user is redirected to the Create New Allocation screen in a separate window. PO (ASN) Inventory source is utilized for Allocation (data at PO (ASN) ID - Style level in the Dashboard screen). Inv Source dropdown should be defaulted to PO (ASN) Inv.

### **Acceptance Criteria:**

1. The Alerts section should have all the above required Alerts.
2. Clicking on the Review Recommendation screen should open a table just below the alert line.
3. The loaded table should have details for the PO (ASN) Number and count of Style Colors which are part of that PO (ASN).
4. The schema of table should be as per above.
5. The PO (ASN) and style colors present in the table should be populated according to the selected filters.
6. Clicking on the review from the opened table should load another table. The loaded table should be at Style Color {Article or Style/Style Color ID} level.
7. The Schema of the 2nd table should be as per above.
8. Users should be able to select any Style Color from the 2nd table to proceed with the allocation process.
9. The Create Allocation button in the popup window should direct the user to the Create New Allocation screen module.
10. In the Create New Allocation screen, the inventory source should PO Inv (ASN Inv)
11. Once the allocation is created using this flow, a notification should come.
12. From the notification, user can view and then finalize the allocation. The finalized allocation should show up in the View Past Allocation

# User Story **7 - Auto Allocation Alert:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> Auto Allocation Alerts**

## **Jira Description:**

In the Auto Allocation alert, users can view system-recommended auto allocations. Navigate to the **'Auto Allocation**' Alert from the **‘Alerts**’ section on the decision dashboard module by applying relevant filters.

In the Alerts section, the row for auto allocation should be:

| Auto Allocation | System generated auto allocations pending review and finalization | #Style Colors 135 | Review Recommendation |
| --- | --- | --- | --- |

**Flow:**

The process flow to the Auto Allocation alert is as follows:

* Go to the Decision Dashboard. Click on “Select Filters”
* Apply specific filters based on your preferences and proceed by clicking on “Apply Filter”.
* Navigate to the “Alerts” section. Locate Auto Allocation Alert.
* Click on the ‘Review Recommendation’ button corresponding to the “Auto Allocation” alert.
* A detail table containing the Plan code info, Allocated units, Available Inventory, etc., is displayed below the Auto Allocation Alert row

The required column names in the table are as follows:

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | Allocation Name |  | inventory_smart.plan_master | varchar | No | Yes | Yes |
| Product | {L0 Name} | l0_name | inventory_smart.plan_attributes | varchar | No | Yes | Yes |
| Product | {L1 Name} | l1_name | inventory_smart.plan_attributes | varchar | No | Yes | Yes |
| Custom | Creation Date |  | inventory_smart.plan_master | date | No | Yes | Yes |
| Custom | Bulk Remaining |  |  |  |  | No | Yes |
| Custom | Allocated Qty |  | inventory_smart.plan_attributes | int4 | No | No | Yes |
| Custom | Action |  |  |  |  | No | No |

* Scroll horizontally and click on “Review” to see the allocation details, from where the plan can be finalized. Clicking on Review will open another table in the same screen which shows the details at style color {Article or Style/Style Color ID} level for all the style colors {Article or Style/Style Color ID} which are present in that allocation. Following columns will be present

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | Allocation Name | plan_name | inventory_smart.plan_master | varchar | No | No | Yes |
| Product | {Article or Style/Style Color ID} | article | inventory_smart.plan_attributes | varchar | No | Yes | Yes |
| Product | {L0 Name} | l0_name | inventory_smart.plan_attributes | varchar | No | Yes | Yes |
| Product | {L1 Name} | l1_name | inventory_smart.plan_attributes | varchar | No | Yes | Yes |
| Product | {L2 Name} | l2_name | inventory_smart.plan_attributes | varchar | No | Yes | Yes |
| Product | {L3 Name} | l3_name | inventory_smart.plan_attributes | varchar | No | Yes | Yes |
| Product | {L4 Name} | l4_name | inventory_smart.plan_attributes | varchar | No | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | inventory_smart.plan_attributes | varchar / date | Yes | Yes | Yes |
| Custom | Bulk Remaining |  |  |  |  | No | Yes |
| Custom | Allocated Qty |  | inventory_smart.plan_attributes | int4 | No | No | Yes |

* At the bottom of the 2nd table, the **Review** button will be available. This will redirect to the recommendation screen of the ‘**Create New Allocation**’ module, where the user can review, edit and finalize the allocation plan
* Once the allocation is finalized, the allocation should be shown in the View Past Allocation screen.
* Once the allocation is finalized, the allocation should not be shown in the Auto Allocation Alert.

### **Acceptance Criteria:**

1. The Auto Allocations should be available in the Alerts, post the ingestion and Auto Allocations completion
2. Post Action on Auto allocation finalization to downstream, it should no longer be visible in the Auto Allocation Alert
3. Also post Action on Auto allocation finalization to downstream, it should work similar to a normal manual allocation finalization (Deduction in ATA, updated allocation reserve column, etc)
4. The user should be able to navigate to the 'Alerts' section and locate the 'Auto Allocation' Alert.
5. The user should be able to click on the 'Review Recommendation' button corresponding to the 'Auto Allocation' alert. This will open a table just below the Alert line.
6. The loaded table should be at allocation name level. The schema of the table should be as per above. 
7. Clicking on the review from the opened table should load another table. The loaded table should be at Style Color {Article or Style/Style Color ID} level.
8. The Schema of the 2nd table should be as per above.
9. Users should be able to select any Style Color {Article or Style/Style Color ID} and click on the 'Review' button in the second screen to be redirected to the recommendation screen of the 'Create New Allocation' module.
10. User can review, edit and then finalize the allocation. The finalized allocation should show up in the View Past Allocation module.

# User Story **8 - Forecast Alert (Recent Deviation Alerts):**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> Recent Deviation Alerts**

## **Jira Description:**

**NOTE**: This is covering the Recent Deviation Alert but similar format can be used for other forecasting alerts. For each forecast alert there should be a corresponding flag in the backend table, `inventory_smart.forecast_alerts`. 

This Alert (any similar forecast alert) should show up in the **Forecast** tab of Alert section.

### **Alert Description:**

Within this alert, the user can view all the Style Color {Article or Style/Style Color ID} where the upcoming 4 weeks' forecast has a deviation of +/- 50% w.r.t the previous 4 weeks' actuals. Any modifications made to the ADA visual screen will be reflected in the following week as the alerts are pre-calculated and refreshed every week.

For populating this alert, use **“recent_deviation_flag” = 1** in `inventory_smart.forecast_alerts` table

In the Alerts table the row for recent deviation should be :In the Alerts section, the row for auto allocation should be:

| Recent Deviation | Choices where next 4 weeks IA forecast has significant deviation from past 4 weeks actuals | #Style Colors 135 | Review Recommendation |
| --- | --- | --- | --- |

**Flow:**

The process flow to Review Recommendations for this alert is as follows:

* Go to the Decision Dashboard. Click on “Select Filters”
* Apply specific filters based on your preferences and proceed by clicking on “Apply Filter”.
* Navigate to the “Alerts” section. All the Forecast alerts should be listed here.
* Click on “Review Recommendation” corresponding to the alert of interest.
* Select the relevant Style Color {Article or Style/Style Color ID} and click on “Go to ADA Dashboard” to edit forecasts.

‌

On clicking the Review Recommendation button, a table will load just the below the Alert row. The table should load with following columns:

**tc_name : recent_deviation_alert_table** (For each alerts refer to the correct tc_name from the <custom data-type="smartlink" data-id="id-11">https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story#User-Story-4---Alerts%3A</custom> section.

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Style/Style Color ID} | article | inventory_smart.forecast_alerts | varchar | No | Yes | Yes |
| Product | {L0 Name} | l0_name | inventory_smart.forecast_alerts | varchar | No | Yes | Yes |
| Product | {L1 Name} | l1_name | inventory_smart.forecast_alerts | varchar | Yes | Yes | Yes |
| Product | {L2 Name} | l2_name | inventory_smart.forecast_alerts | varchar | Yes | Yes | Yes |
| Product | {L3 Name} | l3_name | inventory_smart.forecast_alerts | varchar | Yes | Yes | Yes |
| Product | {L4 Name} | l4_name | inventory_smart.forecast_alerts | varchar | Yes | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | inventory_smart.forecast_alerts | varchar | Yes | Yes | Yes |
| Custom | Store On Hand | oh | inventory_smart.forecast_alerts | int4 | Yes | Yes | Yes |
| Custom | Store On Order | oo | inventory_smart.forecast_alerts | int4 | Yes | Yes | Yes |
| Custom | In Transit to Store | it | inventory_smart.forecast_alerts | int4 | Yes | Yes | Yes |
| Custom | Bulk Remaining / Available to Allocate | ata | inventory_smart.forecast_alerts | int4 | Yes | Yes | Yes |
| Custom | LW Units | lw_qty | inventory_smart.forecast_alerts | float4 | Yes |  |  |
| Custom | LW Revenue $ | lw_revenue | inventory_smart.forecast_alerts | float4 | Yes |  |  |
| Custom | LW Margin $ | lw_margin | inventory_smart.forecast_alerts | float4 | Yes |  |  |
| Custom | Promo % | promo_percentage | inventory_smart.forecast_alerts | float4 | Yes |  |  |
| Custom | Past 4 Weeks Actual | past_4_weeks_actual | inventory_smart.forecast_alerts | float4 | Yes |  |  |
| Custom | Past 4 Weeks Forecast | past_4_weeks_forecast | inventory_smart.forecast_alerts | float4 | Yes | Yes | Yes |
| Custom | Forecast Deviation % | forecast_deviation | inventory_smart.forecast_alerts | float4 | Yes | Yes | Yes |
| Custom | SKU Count Deviation | sku_count_deviation | inventory_smart.forecast_alerts | float4 | Yes | Yes | Yes |
| Custom | Store Penetration Deviation | store_penetration_deviation | inventory_smart.forecast_alerts | float4 | Yes | Yes | Yes |
| Custom | Discount% Deviation | discount_deviation | inventory_smart.forecast_alerts | float4 | Yes | Yes | Yes |
| Custom | MSRP Deviation | msrp_deviation | inventory_smart.forecast_alerts | float4 | Yes | Yes | Yes |
| Custom | Inventory Deviation | inventory_deviation | inventory_smart.forecast_alerts | float4 | Yes | Yes | Yes |

### **Acceptance Criteria:**

1. The Alerts section should have all the required Alerts.
2. Clicking on the Review Recommendation screen should open a table below the alert line showing the Style Color {Article or Style/Style Color ID} which are part of that alert. The schema of table should be as per above.
3. The Style Color {Article or Style/Style Color ID} present in the table should be populated according to the selected filters.
4. Users should be able to select any Style Color {Article or Style/Style Color ID} in the table and click on the **Go To ADA Dashboard**.
5. The Go to ADA Dashboard button in the popup window should direct the user to the ADA Visual screen module, with selected Style Color {Article or Style/Style Color ID} filtered.
6. Screen load time for cascaded filters - within 1 sec, product loading after applying filters - within 3 sec, Product loading to Populate Alert table - within 1 sec

# User Story **9 - Details:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> Details**

## **Jira Description:**

The Details table provides key metrics at a Style Color {Article or Style/Style Color ID} level Sales Performance, Inventory, and Store counts. The style colors {Article or Style/Style Color ID} present in this table will be populated according to the filters selected. Other column KPIs will also be updated based on filters selected. Users can use this section to select any Style Color {Article or Style/Style Color ID} to proceed with the allocation process.

### **Flow:**

1. Upon logging into the tool, the user will be directed to the decision dashboard screen. After selecting the relevant filters, the user will be able to see the details table (along with KPIs, View Allocation Plans, Alerts) populated.
2. The `article_inventory_dashboard` backend table is set up to provide a comprehensive overview of inventory metrics at Style Color {Article or Style/Style Color ID} and store levels, serving as the source for aggregating all necessary metrics required for the view at a style color {Article or Style/Style Color ID} level.
3. When the user clicks on the number of stores under the store count section hyperlink (stockout, shortfall, normal, excess), a pop-up having all the inventory and sales metrics at the style {Article or Style/Style Color ID}-store level will appear.

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=0e0ce21120a9&id=c357e7da-2f62-4f85-a070-902db6e7c8b9&&collection=contentId-2696611453&height=356&occurrenceKey=null&width=815&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=20d84de38089&id=346141b0-28b0-4205-bdb2-3eb3b3435685&&collection=contentId-2696611453&height=568&occurrenceKey=null&width=1705&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
4. User can select one and more Style Colors {Article or Style/Style Color ID} using the check box in the left top corner of the tool. Two actionable button should show up:

    1. **Create Allocation:** Clicking on this link will redirect the user to Create New Allocation module with the selected Style Colors {Article or Style/Style Color ID} where user can create the allocation for the selected Style Colors {Article or Style/Style Color ID}
    2. **Inventory Details:** Clicking on this button will open a side modal where user can view the key metrics for the selected Style Colors {Article or Style/Style Color ID}
    

‌

The columns in the **Details** table should be as follows:

**tc_name : inventorysmart_details_table**

| **Section** | **Parent Column** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** | **Aggregation Logic** | **Specific Custom Dimension** | **Comments** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | Product Information | {Article or Style/Style Color ID} | article | inventory_smart.article_inventory_dashboard | varchar | No | Yes | Yes |  |  |  |
| Product |  | {L0 Name} | l0_name | inventory_smart.article_inventory_dashboard | varchar | No | Yes | Yes |  |  |  |
| Product |  | {L1 Name} | l1_name | inventory_smart.article_inventory_dashboard | varchar | Yes | Yes | Yes |  |  |  |
| Product |  | {L2 Name} | l2_name | inventory_smart.article_inventory_dashboard | varchar | Yes | Yes | Yes |  |  |  |
| Product |  | {L3 Name} | l3_name | inventory_smart.article_inventory_dashboard | varchar | Yes | Yes | Yes |  |  |  |
| Product |  | {L4 Name} | l4_name | inventory_smart.article_inventory_dashboard | varchar | Yes | Yes | Yes |  |  |  |
| Product |  | {Product Attributes} | {product_attribute} | inventory_smart.article_inventory_dashboard | varchar | Yes | Yes | Yes |  |  |  |
| Custom |  | Product Tag | style_color_status | inventory_smart.article_inventory_dashboard | varchar | Yes | Yes | Yes |  |  |  |
| Custom | Sales Performance | LW Units |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.lw_units, 0))::NUMERIC, 0) | AID Store |  |
| Custom |  | LW Revenue $ |  | inventory_smart.article_inventory_dashboard | float | Yes | No | Yes | ROUND(SUM(COALESCE(aid.lw_revenue, 0))::NUMERIC, 0) | AID Store |  |
| Custom |  | LW Margin $ |  | inventory_smart.article_inventory_dashboard | float | Yes | No | Yes | ROUND(SUM(COALESCE(aid.lw_margin, 0))::NUMERIC, 0) | AID Store |  |
| Custom |  | Sales Last 8 Weeks |  | inventory_smart.article_inventory_dashboard | table-chart | Yes | No | No | (COALESCE(SUM(aid.sales_1_ago), 0) + COALESCE(SUM(aid.sales_2_ago), 0) + COALESCE(SUM(aid.sales_3_ago), 0) + COALESCE(SUM(aid.sales_4_ago), 0) + COALESCE(SUM(aid.sales_5_ago), 0) + COALESCE(SUM(aid.sales_6_ago), 0) + COALESCE(SUM(aid.sales_7_ago), 0) + COALESCE(SUM(aid.sales_8_ago), 0))::TEXT \|\| '\|' \|\| COALESCE(SUM(aid.sales_8_ago), 0)::TEXT \|\| ',' \|\| COALESCE(SUM(aid.sales_7_ago), 0)::TEXT \|\| ',' \|\| COALESCE(SUM(aid.sales_6_ago), 0)::TEXT \|\| ',' \|\| COALESCE(SUM(aid.sales_5_ago), 0)::TEXT \|\| ',' \|\| COALESCE(SUM(aid.sales_4_ago), 0)::TEXT \|\| ',' \|\| COALESCE(SUM(aid.sales_3_ago), 0)::TEXT \|\| ',' \|\| COALESCE(SUM(aid.sales_2_ago), 0)::TEXT \|\| ',' \|\| COALESCE(SUM(aid.sales_1_ago), 0)::TEXT | AID Store |  |
| Custom |  | Sales This v/s Last Week |  | inventory_smart.article_inventory_dashboard | table-chart | Yes | No | No | COALESCE(CAST(ROUND(SUM(COALESCE(aid.week_to_date_sales, 0))) AS INTEGER), 0)::TEXT \|\| '\|' \|\| COALESCE(CAST(ROUND(SUM(COALESCE(aid.lw_units, 0))) AS INTEGER), 0)::TEXT \|\| ',' \|\| COALESCE(CAST(ROUND(SUM(COALESCE(aid.week_to_date_sales, 0))) AS INTEGER), 0)::TEXT | AID Store |  |
| Custom |  | Promo % |  | inventory_smart.article_inventory_dashboard | progress-bar | Yes | No | No | ROUND(AVG(COALESCE(aid.promo_percentage, 0))::NUMERIC, 2) | AID Store |  |
| Custom | Inventory | Store On Hand |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.oh, 0))::NUMERIC, 0) | AID Store |  |
| Custom |  | Store On Order |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.oo, 0))::NUMERIC, 0) | AID Store |  |
| Custom |  | In Transit to Store |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE([aid.it](http://aid.it), 0))::NUMERIC, 0) | AID Store |  |
| Custom |  | OH +OO + IT |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.tot_inv, 0))::NUMERIC, 0) | AID Store |  |
| Custom |  | WOS (OH) |  | inventory_smart.article_inventory_dashboard | float | Yes | No | Yes | COALESCE(CAST(ROUND(SUM(aid.wos_oh \* aid.oh) / NULLIF(SUM(aid.oh), 0)) AS INTEGER), 0) | AID Store |  |
| Custom |  | WOS (OH + IT) |  | inventory_smart.article_inventory_dashboard | float | Yes | No | Yes | COALESCE(CAST(ROUND(SUM(aid.wos_oh_it \* (aid.oh + [aid.it](http://aid.it))) / NULLIF(SUM(aid.oh + [aid.it](http://aid.it)), 0)) AS INTEGER), 0) | AID Store |  |
| Custom |  | WOS (OH + OO + IT) |  | inventory_smart.article_inventory_dashboard | float | Yes | No | Yes | COALESCE(CAST(ROUND(SUM(aid.wos \* aid.tot_inv) / NULLIF(SUM(aid.tot_inv), 0)) AS INTEGER), 0) | AID Store |  |
| Custom | DC Inventory | Bulk Remaining / Available to Allocate |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.ata, 0))::NUMERIC, 0) | AID DC |  |
| Custom |  | DC OH |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.oh_dc, 0))::NUMERIC, 0) | AID DC |  |
| Custom |  | DC OO |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.oo_dc, 0))::NUMERIC, 0) | AID DC |  |
| Custom |  | DC IT |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.it_dc, 0))::NUMERIC, 0) | AID DC |  |
| Custom |  | DC(OH+OO+IT) |  | inventory_smart.article_inventory_dashboard | int | Yes | No | Yes | ROUND(SUM(COALESCE(aid.oh_dc, 0) + COALESCE(aid.oo_dc, 0) + COALESCE(aid.it_dc, 0))) | AID DC |  |
| Custom | Store Count | Stockout |  | inventory_smart.article_inventory_dashboard | link - editable | Yes | No | Yes | ROUND(SUM(COALESCE(aid.stockout, 0))::NUMERIC, 0) | AID Store | The values should be hyperlink clicking which it should show inventory, wos, sales at store level |
| Custom |  | Shortfall |  | inventory_smart.article_inventory_dashboard | link - editable | Yes | No | Yes | ROUND(SUM(COALESCE(aid.shortfall, 0))::NUMERIC, 0) | AID Store | The values should be hyperlink clicking which it should show inventory, wos, sales at store level |
| Custom |  | Normal |  | inventory_smart.article_inventory_dashboard | link - editable | Yes | No | Yes | ROUND(SUM(COALESCE(aid.normal, 0))::NUMERIC, 0) | AID Store | The values should be hyperlink clicking which it should show inventory, wos, sales at store level |
| Custom |  | Overstock |  | inventory_smart.article_inventory_dashboard | link - editable | Yes | No | Yes | ROUND(SUM(COALESCE(aid.excess, 0))::NUMERIC, 0) | AID Store | The values should be hyperlink clicking which it should show inventory, wos, sales at store level |
| Custom |  | Current WOS (OH) |  | inventory_smart.article_inventory_dashboard | cell-tag | Yes | No | No | COALESCE(CAST(ROUND(SUM(aid.wos \* aid.tot_inv) / NULLIF(SUM(aid.tot_inv), 0)) AS INTEGER), 0)::TEXT \|\| ',' \|\| COALESCE(CAST(ROUND(SUM(aid.twos \* aid.tot_inv) / NULLIF(SUM(aid.tot_inv), 0)) AS INTEGER), 0)::TEXT | AID Store | Data showing the Target WOS and WOS OH |
| Custom |  | Store Inv. Snapshot |  | inventory_smart.article_inventory_dashboard | box-plot | Yes | No | No | ARRAY\[ COALESCE(MIN(aid.tot_inv), 0), COALESCE(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY aid.tot_inv), 0), COALESCE(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY aid.tot_inv), 0), COALESCE(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY aid.tot_inv), 0), COALESCE(MAX(aid.tot_inv), 0) \] | AID Store | The box plot for inventory |
| Custom |  | Size Integrity (OH) % |  | inventory_smart.article_inventory_dashboard | progress-bar | Yes | No | No | ROUND(AVG(COALESCE(aid.si, 0))::NUMERIC, 2) | AID Store |  |

Schema for the hyperlink in screen tables:

**tc_name : inventorysmart_details_store_table**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Store | Store Number | store_code | inventory_smart.article_inventory_dashboard | varchar | No | Yes | Yes |
| Store | Store Name | store_name | inventory_smart.article_inventory_dashboard | varchar | Yes | Yes | Yes |
| Custom | Store On Hand | oh | inventory_smart.article_inventory_dashboard | int4 | Yes | Yes | Yes |
| Custom | Store On Order | it | inventory_smart.article_inventory_dashboard | int4 | Yes | Yes | Yes |
| Custom | In Transit To Store | oo | inventory_smart.article_inventory_dashboard | int4 | Yes | Yes | Yes |
| Custom | WOS | wos | inventory_smart.article_inventory_dashboard | float4 | Yes | No | Yes |
| Custom | Size Integrity | size_integrity_oh_oo_it | inventory_smart.article_inventory_dashboard | float4 | Yes | No | Yes |
| Custom | LW Units | sales_1_ago | inventory_smart.article_inventory_dashboard | int4 | Yes | Yes | Yes |
| Custom | LW Revenue | lw_revenue | inventory_smart.article_inventory_dashboard | float4 | Yes | Yes | Yes |
| Custom | LW Margin | lw_margin | inventory_smart.article_inventory_dashboard | float4 | Yes | Yes | Yes |

Download functionality should be available for the Details table.

### **Acceptance Criteria:**

1. The Details table should provide key metrics at a Style Color {Article or Style/Style Color ID} level for Sales Performance, Inventory, and Store counts.
2. The style colors {Article or Style/Style Color ID} present in the table should be populated according to the selected filters.
3. Users should be able to select any Style Color {Article or Style/Style Color ID} to proceed with the allocation process.
4. The Create Allocation button should direct the user to the Create New Allocation screen module. The screen should have selected style color IDs {Article or Style/Style Color ID} populated.
5. The details table should have column as per the above table.
6. Should be able to download the populated table and should have only filtered Products and Stores in the table.
7. The hyperlink for the Stock Count columns should load with new table.
8. The table should have the columns as per the above.
9. The values of store count in stockout, shortfall, normal and excess should sum up to total eligible stores for that style colors {Article or Style/Style Color ID}.
10. The allocation once created and finalized from the Details table redirection should show up in the View Past Allocation.
11. Screen load time for filters - within 1 sec, product loading after applying filters - within 1-3 sec, pop-up load times - within 2 sec.

# User Story **10 - Inventory Details:**

## **Jira Summary: \[Client Name\] - Development of Decision Dashboard -> Inventory Details**

## **Jira Description:**

Add a right-side visualisation panel in the Decision Dashboard to enable detailed exploration of selected products through interactive and configurable charts. user can select as many product as they want but can only see visualisation for one product at a time in right right panel. From the dropdown at the top of right panel, user can switch the views/visualization by any clicking on any selected product from details table.

### **Flow:**

* The user selects one or more products in the Details Table.
* Clicking **"Inventory Details"** opens a right-side visualization pane.

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=94782e7239f1&id=778a7310-9d4c-421a-943d-a94bf05d92eb&&collection=contentId-2696611453&height=419&occurrenceKey=null&width=1599&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
* Visualization defaults to the first selected product with a dropdown to switch between others.

### **Feature Details:**

#### Panel Navigation

* One product/article shown at a time with a dropdown for switching.  

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=9fa81c4155ec&id=87e03aec-bf0f-48e3-8287-b25354422687&&collection=contentId-2696611453&height=185&occurrenceKey=null&width=773&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
* Pane is divided into **four sections**, each configurable per client.

#### Product Details

* Show Product Description and Product Tag - Displays static data already shown in the table.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=57b684364ce2&id=dd6cbe10-6576-4a8a-8f18-254c202368e5&&collection=contentId-2696611453&height=59&occurrenceKey=null&width=615&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
* Other than Product description and product tag, show four KPI like tiles - Total four values needs to be displayed. If the value is getting overlapped and space is not enough, show it in tooltip as well on hovering over.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=93bd17bcd8a7&id=ab5b3a0f-3c9a-4094-b4b9-7d58bde43be5&&collection=contentId-2696611453&height=69&occurrenceKey=null&width=700&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
* Here is the list of columns to be displayed in the **Product Details** section:

| **Item Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Comments** |
| --- | --- | --- | --- | --- | --- |
| **Product Description** | product_description / style_color_desc | inventory_smart.article_inventory_dashboard | varchar | Yes |  |
| **Product Type** | product_type | inventory_smart.article_inventory_dashboard | varchar | Yes |  |
| **Launch Date** | launch_date | inventory_smart.article_inventory_dashboard | date | Yes | If it is not there then this can be removed |
| **Price** | price | inventory_smart.article_inventory_dashboard | float4 | Yes |  |
| **Margin** | lw_margin | inventory_smart.article_inventory_dashboard | float4 | Yes |  |
| **Average Discount** | average_discount | inventory_smart.article_inventory_dashboard | float4 | Yes |  |

#### Overall Inventory Distribution

* Floating bar(waterfall) chart showing distribution across DCs and stores combined.
* Hover shows inventory units.  

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=cba9b4df2df7&id=17036b12-a420-4293-9d4f-1f63ae2b2f05&&collection=contentId-2696611453&height=391&occurrenceKey=null&width=742&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)

     


* Here is the list of columns displayed in the **Inventory Distribution – Units** chart from the screenshot:

    * **Total DC OH** - oh_dc
    * **Total DC IT** - it_dc
    * **Total DC OO** - oo_dc
    * **Total Store OH** - oh
    * **Total Store IT** - it
    * **Total Store OO** - oo
    * **Total System Inv**
    

#### Inventory and Sales Distribution by Various Parameters

* **Inventory(Store OH)** should be displayed as a **pie chart**.
* **Sales distribution(Week To Date Sales)** should be shown as a **bar chart**.
* Based on the **user’s selection** from the dropdown filter, both charts should update dynamically to reflect the data for the selected parameter.
* The following options should be available in the **dropdown filter** (client wise) for users to select.

    * Store Grade
    * Region
    * Channel - Remove if not needed
    * Country - Remove if not needed
    

![](blob:https://media.staging.atl-paas.net/?type=file&localId=eacfa189f916&id=c0bb8b08-456f-499e-a94f-da340afcaf2c&&collection=contentId-2696611453&height=276&occurrenceKey=null&width=705&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
#### Store Inventory Position:

This section allows users to **deep dive into store-wise inventory and sales performance** for the selected product.

* Displayed as an **accordion**, collapsed by default, and **loaded only on user interaction**.
* All stores are selected by default, with options to filter and view specific stores.
* Store Inventory Positions will be categorized into Stockout, Shortfall, Normal, and Excess tabs based on the selected stores, enabling users to analyze store-level performance by tag and visualize key metrics such as CWOS and last 8 weeks of sales.  

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=555196bc94b2&id=97595f33-8bc2-404a-b87e-651430e2085f&&collection=contentId-2696611453&height=393&occurrenceKey=null&width=756&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)

#### **Visual Components:**

1. **Weeks of Supply (CWOS)**

    * Displayed as a **circular gauge chart**.
    * Visually represents the CWOS value, overlaid with comparison markers (e.g., Target WOS).  
    
        ![](blob:https://media.staging.atl-paas.net/?type=file&localId=61865c1ecfaa&id=01134129-6156-4161-a6a6-bd07d0738206&&collection=contentId-2696611453&height=243&occurrenceKey=null&width=202&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
    
2. **Sales Last 8 Weeks**

    * Rendered as an **interactive line chart**.
    * X-axis: Week numbers
    * Y-axis: Sales values
    * Hovering over data points shows detailed weekly sales values.  
    
        ![](blob:https://media.staging.atl-paas.net/?type=file&localId=d53d613e5bb6&id=351b5be0-72bc-4814-a544-7525a736f085&&collection=contentId-2696611453&height=227&occurrenceKey=null&width=540&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
    

### **Acceptance Criteria:**

* The right-side visualisation panel should open when the user selects product(s) in the Details Table and clicks **“Inventory Details.”**
* If multiple products are selected, the first should be shown by default, with a **dropdown** to switch between them.
* The panel should include three **client-configurable sections**:

    * **Product Details**
    * **Overall Inventory Distribution**
    * **Inventory & Sales Distribution by Parameters**
    
* The **Product Details** section should display: Product Description, Product Type, Launch Date, Price, Margin, and Average Discount.
* The **Overall Inventory Distribution** section should use a floating bar chart to show Total DC OH/IT/OO, Store OH/IT/OO, and System Inventory, with **tooltips on hover**.
* The **Inventory & Sales by Parameters** section should show inventory as a **pie chart** and sales as a **bar chart**, updated based on selected filters: Region, Country, District, City, Channel.
* **Store Inventory Position** section should load on demand and display CWOS as a circular gauge chart and last X weeks of sales as an interactive line chart with store-level filtering
* All charts should be **interactive**, match Figma design, support **hover tooltips**, and scale responsively.
* A view should be concise enough to get an inventory overview at a first glance.


