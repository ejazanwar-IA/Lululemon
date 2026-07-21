# Create New Allocation -> Recommendation Screen -> Store Capacity

| Field | Value |
|---|---|
| Confluence page ID | `2696611375` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611375/Create+New+Allocation+-+Recommendation+Screen+-+Store+Capacity |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:28.783Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
25 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table, datatype and Nullable column in filters and tables for validation
  2. Title case naming as per latest guideline

  
  
# Guideline

  * This is optional.

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field




# User Story

## **Jira Summary: [Client Name] - Create New Allocation -> Recommendation Screen -> Store Capacity**

## **Jira Description:**

After the allocation is created, the user is directed to the Recommendation Screen with Product View, Store View, and Store Capacity details.

The Store Capacity (Capacity Breach) tab informs users about capacity breaches related to the current allocation. This is currently a soft constraint and does not play any role in the recommendation algorithm. The user can take necessary actions if needed, such as editing the recommended allocation in the previous tabs (Product View, Store View) or in the same tab to handle the breach. If the user is not worried about the capacity breach, then the allocation can move the allocation by clicking on **Move to Order Batching** or **Finalized**.

The breach is set at store - {l1_name} level. Store capacity numbers are provided in the inventory_smart.store_unit_capacity table.

**The Store Capacity(Capacity Breach) tab should get populated with data only when there is a Store capacity breach (i.e. Net available capacity<0)**

### _Navigation:_

Create New Allocation -> Recommendation Screen -> Store Capacity

###  _Landing Page:_

Once the created allocation is loaded and user moves to the Store Capacity tab, the table should populate with all the stores where the capacity has breached.

### **_Flow:_**

The **Details** table should load with following columns:

**tc_name : inventorysmart_finalize_store_capacity**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Description**| **Editable(Yes/No)/[Single/Multi Select]**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---|---|---  
Store| Store Number| store_code| inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Store Code - Should be expandable with the arrow| No| Yes| Yes  
Store| Store Name| store_name| global.store_attributes_filter| varchar| No| Store Name| No| Yes| Yes  
Store| Store Grade| grade or store tier| inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Store garde at article level| No| Yes| Yes  
Product| {Article or Style/Style Color ID}| article| inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Product Hierarchy| No| Yes| Yes  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Product Hierarchy| No| Yes| Yes  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Product Hierarchy| No| Yes| Yes  
Custom| Capacity| unit_capacity| inventory_smart.store_unit_capacity| float4| No| Capacity at {l1 name} store level| No| Yes| Yes  
Custom| OH+OO+IT| OH + OO + IT| latest_inventory| int4| No| Sum of OH, OO and IT at store {l1 name} hierarchy level| No| Yes| Yes  
Custom| Allocated Reserve| | | | | Already allocated units as of Today| No| Yes| Yes  
Custom| DC Net Available| | | | | The remaining inventory at DC| No| Yes| Yes  
Custom| Current Allocation Recommendation| | | | | Allocated units as per current allocationUser can click on it to edit the allocated units at size and pack level| No (Hyperlink)| Yes| Yes  
Custom| Net Available Capacity| | | | | Net Available capacity at store considering the current allocation| No| Yes| Yes  
Custom| WOS| | | | | The target WOS used for the allocation| No| Yes| Yes  
  
The '**Current Allocation Recommendation** ' column is hyperlinked to a size-level table shown as a pop-up. The pop-up contains Size level DC distribution, Allocated Qty, total inventory, and Min and Max details.  
The Allocated Qty at size level is editable. The user can adjust the allocated qty and check for the Capacity Breach at a store level. 

The Popup table should have the following columns:

**tc_name : inventorysmart_finalize_store_product_size**

**Section**| **Column Name**| **Mapping Column**| **Description**| **Editable(Yes/No)/[Single/Multi Select]**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---  
Product| Sizes| size| Size or Pack| No| Yes| Yes  
Custom| DC Net Available| | The remaining inventory at DC| No| Yes| Yes  
Custom| Allocated Quantity| | Allocated units as per current allocationUser can adjust the allocated qty and check for the Capacity Breach at a store level. | Yes| Yes| Yes  
Custom| OH+OO+IT| OH + OO + IT| Sum of OH, OO and IT at store {l1 name} hierarchy level| No| Yes| Yes  
Custom| Min| | min_stock for the size store| No| Yes| Yes  
Custom| Max| | max_stock for the size store| No| Yes| Yes  
  
Make the required changes in the allocated quantity and click on Update to save the changes.

Click on **Move to Order Batching** or **Finalize**.

### **_Acceptance Criteria:_**

  1. The Capacity Breach tab should inform users about capacity breaches related to the current allocation.

  2. The table schema should include columns such as Store Code, Store Name, Store Grade, Style Color ID, Division, Department, Class, Subclass, Style, Pack ID, Pack Description, Capacity, OH+OO+IT, Allocated Reserve, DC Net Available, Current Allocation Recommendation, Net Available Capacity, FWOS.

  3. The 'Current Allocation Recommendation' column should be linked to a size-level table shown as a pop-up.

  4. The pop-up should contain Size level DC distribution, Allocated Qty, total inventory, and Min and Max details.

  5. Users should be able to adjust the allocated qty and check for the Capacity Breach at a store level.

  6. Users should be able to save changes by clicking on Update.

  7. Users should be able to click on Move to Order Batching or Finalize.




