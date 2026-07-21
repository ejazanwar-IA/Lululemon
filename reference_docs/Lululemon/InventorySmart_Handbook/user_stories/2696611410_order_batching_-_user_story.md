# Order Batching - User Story

| Field | Value |
|---|---|
| Confluence page ID | `2696611410` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611410/Order+Batching+-+User+Story |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:29.617Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
12 May 2026| [Gowthami T](https://impactanalytics.atlassian.net/wiki/people/5f8956ac7d9637006f2b4591?ref=confluence) | Reverted the splitting of stories as this is not required  
11 May 2026| [Gowthami T](https://impactanalytics.atlassian.net/wiki/people/5f8956ac7d9637006f2b4591?ref=confluence) | 

  1. Split OB story into 2 parts to resolve Jira Character Limit Issues

  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
26 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table, datatype and Nullable column in filters and tables for validation
  2. Title case naming as per latest guideline

  
  
# Guideline

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * The Order Batching module is required only if the user intends to batch the created allocations before releasing them. If the user prefers to directly send allocations from the Recommendation screen or via the auto-release process, then this module is not necessary.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field

  * **Please copy the tables to a notepad and then paste it to the Jira story if you get Jira Character Limit Issue**




# User Story 

## **Jira Summary: [Client Name] - Development of Order Batching Screen **

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

Users can leverage this module to update/review the pre-existing allocation plans.

### _Filters:_

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters along with the Allocation/PO type filter to get the list of the allocations that are in order batching state.

**fc_name : inventorysmart_order_batching**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Custom| Inventory type| inventory_source (required only if client is having different inventory source)| inventory_smart.create_allocation_result_flat_gurobi| varchar| No| No| Multi Select  
Custom| Allocation type| type| inventory_smart.plan_master| int4| No| No| Multi Select  
Custom| Allocation Plan Name| name|  inventory_smart.plan_master| varchar| No| No| Multi Select  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
Store| {S0 Name}| s0_name| global.store_attributes_filter| varchar| No| No| Multi select  
  
This module should have three components:

  1. KPIs (View Only)

  2. Current Allocations Summary (View Only)

  3. Current Allocations (Editable)




### _KPIs:_

**KPI Name**| **Mapping Column**| **Description**  
---|---|---  
# Allocation Plans| plan_master - plan_code| Number of distinct plans that are currently active in Order Batching, i.e plans not finalized or not purged.  
# Allocated Style-Colors| create_allocation_result_flat_gurobi - article| Number of distinct style color IDs that are in order batching across all the Order Batched plans.  
# Allocated Quantity| create_allocation_result_flat_gurobi - allocated_total| Total allocated units that are in Order Batching.  
Remaining Available To Allocate| Calculated| The available to allocate inventory remaining across the style color IDs post adjusting for the Order Batching allocations and the allocations finalized over the day. (Please note that it also considers Launch POs not arrived to DC yet, however the name suggest it as DC Available inventory)  
Reserve Quantity| Views| The total units reserved by the user across each Product Code and DC for the replenishment flow.  
DC WOS(OH)| article_inventory_dashboard| The future weeks of store forecast that the current DC inventory can fulfill.  
Store WOS(OH+OO+IT+Allocation)| Calculated| The future WOS considering the current store inventory(OH+OO+IT) and allocations finalized for the day or in Order Batching.  
Store WOS(OH+OO+IT)| article_inventory_dashboard| The future WOS considering the current store inventory(OH+OO+IT)  
Store In-Stock%| article_inventory_dashboard| Percentage of Stores with available stock across all SKUs (Style-Size)  
DC In-Stock%| article_inventory_dashboard| Proportion of sizes with available-to-allocate (ATA) inventory (DC stock) for allocated styles at relevant DCs.  
  
The KPIs can be customized based on specific business needs. However, it is recommended to keep the number of distinct KPIs limited to a maximum of 12 for optimal usability and performance.

### _Current Allocations Summary:_

The Summary View displays allocation plans available in the Order Batching screen, aggregated at both Store and Style levels across all plans in the module.

  1. **Store:**




The Store View summary presents data at the Store ID level aggregated for all styles part of the Order Batching plan selection:

**tc_name : inventorysmart_order_triaging_summary_store**

**Section**| **Parent Column**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---|---  
Store|  | Store Code| store|  inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Yes| Yes  
Store|  | Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes  
Custom| Allocated Quantity| Eaches|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Packs|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Total|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom|  | # Allocated Style-Color|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| Yes| Yes  
Custom|  | # Allocation Plans|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| Yes| Yes  
Custom| Remaining ATA| Eaches|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Packs|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Total|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom|  | Store Capacity|  | inventory_smart.store_unit_capacity| int4| No| Yes| Yes  
Custom|  | Store% to Capacity|  |  | float4| No| Yes| Yes  
Custom|  | Net Available Capacity|  |  | int4| No| Yes| Yes  
  
**Store% to Capacity : **Its the proportion of utilised capacity for the store (This being greater than 100% denotes the store is breaching the available capacity)  
**Net Available Capacity :** Remaining store capacity after accounting for finalized plans for the day, plans in the Order Batching screen, and existing store inventory (OH + OO + IT)  
Please note that the OO component from Store inventory or Allocated/Order Batching is only considered if its expected to reach to Store within next 7 days. Also, this metric is independent of the up top filter selection and is at a store level considering the entire product universe.

  2. **Style-Color:**




Summary Style-Color presents data at the Style level aggregated for all styles part of the Order Batching plan selection:

**tc_name : inventorysmart_order_triaging_summary_style**

**Section**| **Parent Column**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---|---  
Product|  | Style-Color ID| article|  inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Yes| Yes  
Product|  | {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product|  | {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product|  | {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product|  | {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product|  | {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Custom| Allocated Quantity| Eaches|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Packs|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Total|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom|  | # Store Count|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| Yes| Yes  
Custom|  | # Allocation Plans|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| Yes| Yes  
Custom| Remaining ATA| Eaches|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Packs|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Total|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
  
###  _Current Allocations:_

This View displays the allocations available in the Order Batching screen, at Style Color - Store - Release PO/Allocation Code level.  
Through this table, the user should be able to navigate to the recommendation screen from the Allocation Plan ID hyperlink and recommendation edits can be made and save. This will update all the relevant metrics in the OB views.  
The user can also edit Start Ship Date and Order Priority (if applicable) through this table.  
Key Metrics  
**Min Constraint: **Aggregated Min Constraint for all sizes  
**Min Allocation: **Aggregated Min driven allocated units for all sizes  
**Total Allocated Units: **Total Allocated units that are in Order Batching.  
**WOS Allocation: **Aggregated WOS driven allocated units for all sizes (excluding the min allocation)  
**Store Capacity:** Original available capacity of the store  
**Store% to Capacity:** Same as Summary Store  
**Net Available Capacity:** Same as Summary Store  
**StartShip Date:** DC out date as per the aligned logic for different PO types (Editable)

Note: Additional metrics can be added in all the views based on business needs. However, please ensure that redundant or duplicate columns are excluded to avoid any negative impact on load time and performance.

**tc_name : inventorysmart_order_batching**

**Section**| **Parent Column**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---|---  
Product|  | Style-Color ID| article|  inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Yes| Yes  
Product|  | {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product|  | {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product|  | {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product|  | {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product|  | {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Store|  | Store Code| store|  inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Yes| Yes  
Store|  | Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes  
Store|  | Store Grade| store_grade| global.store_attributes_filter| varchar| No| Yes| Yes  
Custom|  | DC Code|  | global.distribution_centres| varchar| No| Yes| Yes  
Custom| Allocated Quantity| Eaches|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Packs|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Total|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Remaining ATA| Eaches|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Packs|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom| Total|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| No| Yes  
Custom|  | Aggregated Min|  |  inventory_smart.create_allocation_result_flat_gurobi| int4| No| Yes| Yes  
Custom|  | Allocation Plan ID|  |  inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Yes| Yes  
Custom|  | Store Capacity|  | inventory_smart.store_unit_capacity| int4| No| Yes| Yes  
Custom|  | Store% to Capacity|  |  | float4| No| Yes| Yes  
Custom|  | Net Available Capacity|  |  | int4| No| Yes| Yes  
Custom|  | Created By|  |  inventory_smart.create_allocation_result_flat_gurobi| varchar| No| Yes| Yes  
Custom|  | Created At|  |  inventory_smart.create_allocation_result_flat_gurobi| date| No| No| Yes  
  
There should be a **Finalize for Order generation** button in the bottom left of the screen:

This button finalizes all the allocation plans filtered through the top-level filters and triggers the downstream file generation.

**Acceptance Criteria:**

  1. Screen load time for filters - within 1 sec, style loading after applying filters - within 3 sec, pop-up load times - within 2 sec.

  2. No duplicate rows should be present

  3. Should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  4. Pagination & Scroll Behavior

     * The tables should be paginated with 100 records per page.

     * Within each page, only 10 records should be visible at a time in the scrollable view.

  5. Layout

     * All relevant views (tables, filters, summaries, etc.) should be accommodated within a single page--no separate navigation tabs or pages.

  6. Action Button Placement

     * The "Finalize for Order Generation" button should be persistently visible at the bottom-left corner of the screen.

     * This button should remain fixed in position and not require any scrolling to be accessed.

  7. The allocations to be sent downstream using Finalize functionality or purged as per the defined frequency

  8. All distinct allocation plans listed in the _Current Allocations_ table should be finalized--regardless of any partial selection of Product or Store hierarchies in the filters above.

  9. The row selection within the _Current Allocations_ table should only be used for the 'Set All' action within the table--it should not limit or affect which plans are finalized through this button.




