# Configuration -> Store -> New Store Setup

| Field | Value |
|---|---|
| Confluence page ID | `2696610948` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610948/Configuration+-+Store+-+New+Store+Setup |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:20.669Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
13 May 2026| [Gowthami T](https://impactanalytics.atlassian.net/wiki/people/5f8956ac7d9637006f2b4591?ref=confluence)| 

  1. Data Type change for hyperlinks

Expected : If there is a Datatype present then Datatype / Link else Link  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
20 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table, datatype and Nullable column in filters and tables for validation
  2. Title case naming as per latest guideline

  
  
# Guideline

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field




# User Story

## **Demo link: { Add React Demo - If available}**

Figma links for reference below-

[Configurations(new store setup) - Levis specific - ADMIN FLOW](https://www.figma.com/proto/L457wzTY1xirsY7NoTYADl/InventorySmart-UI-v3?page-id=5878%3A119693&node-id=15952-159755&viewport=3058%2C-2892%2C0.11&t=C1zFKwJSajXcsoh7-8&scaling=scale-down-width&content-scaling=fixed&starting-point-node-id=15952%3A159755&hide-ui=1)  
[Configurations(new store setup) - Levis specific - USER FLOW](https://www.figma.com/proto/L457wzTY1xirsY7NoTYADl/InventorySmart-UI-v3?page-id=5878%3A119693&node-id=15952-159773&viewport=3058%2C-2892%2C0.11&t=C1zFKwJSajXcsoh7-8&scaling=scale-down-width&content-scaling=fixed&starting-point-node-id=15952%3A159773&hide-ui=1)

## **Details:**

This page contains all the sub features related to the development of the Updated New Store workflow along with any other new screens related (Eg- New Store Performance report, projection report, allocation for new stores).

# User Story 1 - New Store Setup Flow

## **Jira Summary: [Client Name] - Development of Configuration -> New Store**

## **Jira Description:**

This story covers the implementation of the New Store setup flow in the Store Management Tool, providing a streamlined process for configuring new stores in the IS system.

As an Admin/Superuser, I need to set up new stores in the IS system so that they can be properly configured before their opening date, with appropriate sister store mapping and store group settings. Post which, I would later use this to generate and recommend Allocations.

The New Store setup process consists of two main steps:

  1. Store details configuration

  2. Sister store mapping & Store group setting




Different user roles (Admin/Superuser and regular users) will have different permissions in this flow.

### _Navigation:_

Left-hand panel -> Configuration -> Store -> New Store Setup

###  _Landing Page:_

  * The landing page displays a table of all historically created/in-progress New Stores in the IS system

  * Table includes columns for store information, status, and action required


![image-20250512-193004.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610948/image-20250512-193004.png?version=1&modificationDate=1779356661313&cacheVersion=1&api=v2&width=624&height=215)

  * To add a new store, click on the `+` icon, a new page will load with 1st step of New Store addition.

  * User can select and apply filter to fetch the new stores.




### _Filters:_

Only store-related filters are to be present on this screen.

**fc_name : Inventorysmart Configurations New Store**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Store| {S0 Name}| s0_name| global.store_attributes_filter| varchar| No| Yes| Single Select  
Store| {S1 Name}| s1_name| global.store_attributes_filter| varchar| No| No| Multi Select  
  
###  _Step 1: Store Details_

  * Initiated when Admin/Superuser clicks the "Add" or `+` button (For other users, this button should not be clickable)

  * The system displays all future stores where setup has not been started/completed based on applied filters

  * Admin selects a store, and relevant details are pre-populated in the drop-downs (Store Attributes" section)

  * Only "Store opening date" field should be editable (but pre populated with backend data)

  * Admin can either:

    * Continue to Step 2 by clicking "Continue"

    * Save and return to the landing page by clicking "Save"


![image-20250512-193207.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610948/image-20250512-193207.png?version=1&modificationDate=1779356661123&cacheVersion=1&api=v2&width=624&height=339)

**_Store Attributes Configuration_** \- The loaded table should have following columns:

**tc_name : new_store_store_detail_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Comments**  
---|---|---|---|---|---|---  
Store| Store Code| store_code| inventory_smart.new_store_data| varchar / Link| No| Store Identifier  
Store| Store Name| store_name| inventory_smart.new_store_data| varchar| No| Store Identifier  
Store| Store Opening Date| opening_date| inventory_smart.new_store_attributes| varchar| No| Editable  
Store| {S0 Name}| s0_name| global.store_attributes_filter| varchar| No| Store Hierarchy  
Store| {S1 Name}| s1_name| global.store_attributes_filter| varchar| No| Store Hierarchy  
Store| {S2 Name}| s2_name| global.store_attributes_filter| varchar| No| Store Hierarchy  
Store| {Store Attribute}| store_attribute| global.store_attributes_filter| varchar| No| Store Attributes  
  
###  _Step 2: Sister Store Mapping & Store Group Setting_

  * Accessible directly from Step 1 (for Super users) or by clicking "Edit" (by Super user/ normal users) on a pending setup store

  * Post clicking on edit, the system displays recommendation message: "IA recommends xxxx Store as the sister store based on the store attributes of the New Store" (xxxx populated from backend analytics table)

  * Contains a details table for setting multipliers for relevant product categories

    * Only UAM relevant categories should be shown in drop downs (based on the user and their accesses to categories of products)

    * By default, all the columns need to have Select All done (as per the UAM)- Example, like below 

  * ![image-20250513-063528.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610948/image-20250513-063528.png?version=1&modificationDate=1779356661123&cacheVersion=1&api=v2&width=676&height=70)
  * Users can add new records or delete existing ones


![image-20250512-193420.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610948/image-20250512-193420.png?version=1&modificationDate=1779356661122&cacheVersion=1&api=v2&width=682&height=393)

** _Sister Store Dropdown Configuration_** \- The loaded table should have following columns:

**tc_name : new_store_select_sister**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| No| Yes| Dropdown  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| No| Yes| Dropdown  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Yes| Dropdown  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Yes| Dropdown  
Store| Sister Store| store_code| global.store_attributes_filter| varchar| No| No| Yes| Dropdown  
Custom| Multiplier| | | float8| No| No| Yes| Editable  
Custom| Created By| | | varchar| No| No| Yes|   
  
** _Sister Store Mapping Time Period_**

  * Options: Static/Dynamic (The options inside this are as per the previous version of the New Store Setup)

  * Below this is a table listing all store groups the sister store(s) are part of

  * Table includes:

    * Store group name

    * Number of stores in each group

    * Clickable row to expand details of stores in the group


![image-20250512-193549.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610948/image-20250512-193549.png?version=1&modificationDate=1779356660856&cacheVersion=1&api=v2&width=757&height=436)

** _Store Group Assignment_**

  * Users can set future store group mapping dates. As per the dates set, the New Store should automatically be a part of the corresponding store groups mentioned.

  * Tooltips should be provided for below columns as shown in Figma:

    * Store group mapping

    * Store group mapping date

    * Multiplier column




###  _Approval Flow_

  * Regular users:

    * Click "Request Superuser Approval"

    * Redirected to landing page

    * Status column shows "Pending Setup"

    * Action Required column (for superusers) shows "Complete Setup"

  * Superusers:

    * Can click on "Complete Setup" in the Action Required column

    * Navigated to Step 2 to review changes

    * Can click "Super User Approval" button

    * Popup displays all modifications and additions with user details. This popup should include ALL changes from the last superuser approval.

    * Can override changes if needed

    * Click "Confirm Approval" to complete the process

    * Status changes to "Setup Completed"

    * Action Required changes to "No Action"


![image-20250512-193938.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610948/image-20250512-193938.png?version=1&modificationDate=1779356660856&cacheVersion=1&api=v2&width=754&height=435)

### _Edit/Delete Flow_

  * **Edit/Delete Availability**

    * Once a new store is set up, users can **edit or delete it** until its **opening date**.

  * **Deletion Impact**

    * If deleted, the store should be **completely removed** from the InventorySmart tool.

  * **Edit Flow**

    * **3.1 User Edit Flow**

      * Clicking **Edit** navigates the user to **Step 2** of the setup.

      * The user can make changes and submit for **Super User approval**.

      * The store status changes from **" Setup Completed" -> "Approval Required"**.

      * The admin then reviews and approves the changes.

    * **3.2 Admin Edit Flow**

      * Admins are also taken to **Step 2** on clicking Edit, but they can **make and approve changes directly** --no further approval needed.




### _Data Table Requirements_

  * All tables throughout the New Store setup flow should have filterable and sortable columns, including:

    * The main New Store setup landing page table

    * The future stores selection table in Step 1

    * The sister store mapping details table in Step 2

    * The store groups table in Step 2

    * The expanded store list table when viewing store group details




###  _Acceptance Criteria_

  1. Admin/Superuser can initiate new store setup for future stores

  2. Store details are correctly prepopulated with only opening date editable

  3. Sister store recommendation is displayed based on backend data

  4. Users can set multipliers for their relevant product categories

  5. Users can select Static/Dynamic for sister store mapping time period

  6. Store groups are displayed with correct store counts and details

  7. Users can set future store group mapping dates

  8. Regular users can request superuser approval

  9. Superusers can review, override, and approve changes

  10. Status and Action Required columns update appropriately based on the workflow state

  11. Tooltips are displayed in the specified locations

  12. All tables have proper filtering, sorting, and pagination




### ** _Technical Notes_**

  * Ensure UAM controls are implemented to show only relevant product categories to users

  * Backend will need an integration with the analytics team's table for sister store recommendations

  * Implement proper state management for the multi-step process

  * Ensure proper validation for dates (must be in the future)




# User Story 2 - New Store Allocation Projections

## **Jira Summary: [Client Name] - Development of Configuration -> Store -> New Store Allocation Projections**

## **Jira Description:**

Figma link: [https://www.figma.com/proto/L457wzTY1xirsY7NoTYADl/InventorySmart-UI-v3?page-id=5878%3A119693&node-id=17007-161196&viewport=3058%2C-2892%2C0.11&t=C1zFKwJSajXcsoh7-8&scaling=scale-down&content-scaling=fixed&starting-point-node-id=15952%3A159773&hide-ui=1](https://www.figma.com/proto/L457wzTY1xirsY7NoTYADl/InventorySmart-UI-v3?page-id=5878%3A119693&node-id=17007-161196&viewport=3058%2C-2892%2C0.11&t=C1zFKwJSajXcsoh7-8&scaling=scale-down&content-scaling=fixed&starting-point-node-id=15952%3A159773&hide-ui=1)

As a user, I would like to view projected allocations and their associated dollar values after setting up a new store. This visibility enables accurate forecasting and financial planning based on the assigned sister store and defined multipliers.

### **_Navigation:_**

  * After a new store setup is completed, the store code on the landing page becomes a clickable hyperlink.

  * Clicking this hyperlink loads the "New Store Allocation Projections" table.




### **_Functionality:_**

This feature provides insights into the projected allocations (in units) and their corresponding dollar values, calculated using the sister store's forecast data and multipliers set by the user.

#### **_Table Configuration:_**

**tc_name : new_store_allocation_projections**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Store| Store Code| store_code| inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Store| Store Name| store_name| inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Product| {L0 Name}| l0_name| inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Product| {L1 Name}| l1_name| inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Product| {L4 Name}| l4_name| inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Product| {Product attributes}| {product_attribute}| inventory_smart.new_store_attributes| varchar / date| Yes| Yes| Yes  
Custom| Sister Store Details - Store ID| | inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Custom| Sister Store Details - Store Name| | inventory_smart.new_store_attributes| varchar| No| Yes| Yes  
Custom| Sister Store Details - Multiplier| | inventory_smart.new_store_attributes| numeric| No| Yes| Yes  
Custom| Projected Units| | inventory_smart.new_store_attributes| int4| No| Yes| Yes  
Custom| Projected Value (in $)| | inventory_smart.new_store_attributes| numeric| No| Yes| Yes  
  
![image-20250519-103541.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610948/image-20250519-103541.png?version=1&modificationDate=1779356660855&cacheVersion=1&api=v2&width=960&height=134)

The styling of the table should be similar to the Figma prototype

### **_Acceptance Criteria:_**

  * Store codes on the landing page become clickable hyperlinks once store setup is complete.

  * Hyperlink directs users to the "New Store Allocation Projections" view.

  * Data displayed accurately reflects allocations based on associated sister store and defined multipliers.

  * Multiplier defaults to 1 if not specifically set by the user.

  * All product and store hierarchy details are correctly displayed.

  * Projected units and values are clearly shown and accurately calculated.




# User Story 3 - New Store Allocation flow

## **Jira Summary: [Client Name] - Development of Configuration -> Store -> New Store Allocation flow**

## **Jira Description:**

**This workflow is only relevant for clients where this is a single pool of inventory for new and existing stores.**  
As a user, I want to allocate products to new stores even before their opening date. Once the new store is set up, the allocation process should mirror the process used for existing stores in the system.

### **_Allocation Inputs:_**

Input| Source  
---|---  
Store Group| If a store group mapping date is defined during setup, the new store is added automatically. Otherwise, users must manually add the store to a store group.  
Configuration (Product-Store eligibility)| Shared by the client via feeds  
Configuration (DC-Store Strategy)| Rule-based. New stores will automatically inherit a strategy (as per existing strategies).  
Constraints| Rule-based. New stores will automatically inherit constraints (as per existing constraint rules whichever they qualify under).  
Misc Inputs (Store Grade, Lead time, etc)| Shared by the client via feeds  
  
### ** _Allocation Creation Process:_**

Once the new store is included in the eligibility feed, users can proceed with both manual and auto allocations.

#### _Manual Allocation Creation:_

**Flow:**

  1. Select styles from the Dashboard or via the "Create New Allocation" screen.

  2. Confirm that the associated store group includes the new store.

  3. Review store-specific allocation details.

  4. Create the allocation, review the details, and send it to Order Batching.

  5. Superuser/Admin can review the allocation for the new store within the Order Batching screen and finalize it for order generation.




#### _Auto Allocation Creation:_

If the new store qualifies for a style and has a scheduler assigned, styles will be automatically allocated.

**Flow:**

  1. Auto-allocated plans will appear in either the Alerts section( or the Order Batching screen as per the Auto Approve option set), which contains Recommendations for Existing and New Stores.

  2. Clicking "Review" redirects the user to the "Review Recommendation" screen.

  3. The user can then:

     * Review the allocation.

     * Make necessary edits.

     * Move the plan to Order Batching.

  4. Superuser/Admin can finalize the allocation in the Order Batching screen for order generation.  





If the admin or allocator wants to discard allocations to the new store and re-allocate closer to its opening date, they can do so using the new **" Top-down Edits"** workflow in the Order Batching screen. They'll be able to set the allocated units for the new store to zero across all batched plans.

For clients where there are separate pools of inventory for new and existing stores, the allocation takes place using a new alert on the Dashboard screen.

### **_Acceptance Criteria:_**

  * Store group mapping logic is applied automatically if the setup includes a mapping date.

  * Eligibility configurations and strategies are correctly inherited by the new store.

  * Manual and auto allocation workflows accommodate new stores seamlessly.

  * Allocations made for new stores are visible and actionable in the Order Batching screen.

  * Superuser/Admin can review and finalize all new store allocations without errors or rework.




# User Story 4 - New Store Performance Tracking Report

## **Jira Summary: [Client Name] - Development of Reports -> New Store Performance Tracking Report**

## **Jira Description:**

As a user, I want to view a report that helps me track the performance of newly opening stores. This will enable better visibility and management of store performance metrics from launch through the early stages of operation.

Figma link for reference: [New store tracking](https://www.figma.com/proto/L457wzTY1xirsY7NoTYADl/InventorySmart-UI-v3?page-id=5878%3A119693&node-id=16142-155946&viewport=3522%2C-7961%2C0.28&t=8oSD2xlUWcbXYTv2-8&scaling=scale-down-width&content-scaling=fixed&starting-point-node-id=11624%3A512681&hide-ui=1)

### ** _Navigation_ :**

Left-hand panel -> Reports -> New Stores Tracking (New Tab)

### **_Filters_ :**

**fc_name : New Store Performance Tracking Report**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single Select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi Select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi Select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi Select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi Select  
Store| Store Code| store_code| global.store_attributes_filter| varchar| No| Yes| Single Select  
  
### ** _Functionality:_**

  * After clicking "Apply," users will first see KPI cards summarizing key performance metrics for the new stores.




KPI| Definition| Calculation  
---|---|---  
Sales Units| Total Units sold in the new store| Sum of units allocated  
Sister Store Sales Units| Total Units sold in the sister store| Sum of units sold  
Sister Store Multiplier| Multiplier used during setup of new store| Average of sister store multiplier  
Units Allocated| Units allocated to the store| sum of units allocated  
Sell-Through %| Proportion of allocated units sold| (Total Sales / Allocated Units) × 100  
FWOS| Forward looking WOS| Average of FWOS across products based on filter  
  
  * Following the KPI summary, users will see an interactive graph with two selectable views: "Performance Trend View" and "Inventory View."




### **_Graph Views_ :**

#### **_Performance Trend View_ :**

Users can compare allocated units, actual sales, sister store sales, and sister store sales × multiplier. Visual dotted lines indicate the week of the first sales and the sister store mapping date.

Axis| Label| Definition  
---|---|---  
X-axis| Week Number| Week 1 is the week of first allocation; data shown for 24 weeks [Number of weeks should be configurable by client]  
Y-axis| Units|    
  
#### **_Inventory View:_**

Users compare forward-looking Weeks of Supply (WOS) vs. Target WOS, alongside current store inventory levels.

Axis| Label| Definition  
---|---|---  
X-axis| Week Number| Week 1 is the week of first allocation; data shown for 12 weeks [Number of weeks should be configurable by client]  
Y-axis (Primary)| WOS| The primary axis will cater to the WOS trendlines.  
Y-axis (Secondary)| Store Inventory| The secondary axis will cater to the Store Inventory trendline.  
  
Other Graph design elements such as type of graph, legends, tooltip on hover etc should be similar to what is available in the Figma prototype

### ** _New Store Performance Breakdown (Table)_ :**

A detailed table providing insights into allocated units, sister store sales, and sell-through percentages compared to sister stores.

**tc_name : new_stores_performance_tracking_details_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Product| {Article or Style/Style Color ID}| article| new_store_performance_report| STRING| No| Yes| Yes  
Store| Store Code| store_code| new_store_performance_report| STRING| No| Yes| Yes  
Store| Store Name| store_name| new_store_performance_report| STRING| No| Yes| Yes  
Product| {L0 Name}| l0_name| new_store_performance_report| STRING| No| Yes| Yes  
Product| {L1 Name}| l1_name| new_store_performance_report| STRING| No| Yes| Yes  
Product| {L2 Name}| l2_name| new_store_performance_report| STRING| No| Yes| Yes  
Product| {L3 Name}| l3_name| new_store_performance_report| STRING| No| Yes| Yes  
Product| {L4 Name}| l4_name| new_store_performance_report| STRING| No| Yes| Yes  
Product| {Product attributes}| {product_attribute}| new_store_performance_report| STRING / DATE| Yes| Yes| Yes  
Custom| Sister Store Code| | new_store_performance_report| STRING| No| Yes| Yes  
Custom| Sister Store Name| | new_store_performance_report| STRING| No| Yes| Yes  
Custom| Opening Date| | new_store_performance_report| DATE| No| No| Yes  
Custom| Sister Store Sales Units| | new_store_performance_report| INTEGER| No| No| Yes  
Custom| Sales Units| | new_store_performance_report| INTEGER| No| No| Yes  
Custom| Sister Store Multiplier| | new_store_performance_report| FLOAT| No| No| Yes  
Custom| Allocated Units| | new_store_performance_report| INTEGER| No| No| Yes  
Custom| Sell Through %| | new_store_performance_report| FLOAT| No| No| Yes  
Custom| Sister Store Sell Through %| | new_store_performance_report| FLOAT| No| No| Yes  
  
An Excel export option must be provided for this table.

### **_Acceptance Criteria:_**

  * "New Stores Tracking" tab appears under Reports navigation.

  * Filters function correctly and apply data to the entire report.

  * KPI cards correctly summarize store performance.

  * The interactive graph with both "Performance Trend View" and "Inventory View" works as described.

  * Visual cues and designs match the Figma prototype.

  * "New Store Performance Breakdown" table displays accurate data and allows export to Excel.




