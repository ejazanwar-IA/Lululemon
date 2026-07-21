# Order Batching Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696610522` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610522/Order+Batching+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:11.676Z |
| Last mirrored | 2026-05-21 |

---

Users can leverage this module to update/review the pre-existing allocation plans. This module has three components: **KPIs, Current Allocations Summary, and Current Allocations.**

_KPIs:_

**# Allocations** \- Number of distinct plans that are currently active in Order Batching, i.e plans not finalized or not purged.

**# Allocated Styles** \- Number of distinct styles that are in order batching across all the Order Batched plans.

**# Allocated units** \- Total allocated units that are in Order Batching.

**DC Net Available Inventory** \- The available to allocate inventory remaining across the styles post adjusting for the Order Batching allocations and the allocations finalized over the day. (Please note that it also considers Launch POs not arrived to DC yet, however the name suggest it as DC Available inventory)

**Reserve Quantity** \- The total units reserved by the user across each Product Code and DC for the replenishment flow.

**DC WOS** \- The future weeks of store forecast that the current DC inventory can fulfill. These forecasts are only for DC allocation eligibile styles (Non new skus or non new stores)

**Current WOS + Allocation** \- The future WOS considering the current store inventory(OH+OO+IT) and allocations finalized for the day or in Order Batching.  
Note that the delta WOS computation for allocation units considers average forecast per week and not the exact calculation.

**Current WOS** \- The future WOS considering the current store inventory(OH+OO+IT)

**Store In-Stock** \- Percentage of Stores with available stock across all SKUs (Style-Size)

**DC In-Stock** \- Proportion of sizes with available-to-allocate (ATA) inventory (DC stock) for allocated styles at relevant DCs.

_Current Allocations Summary:_

The Summary View displays allocation plans available in the Order Batching screen, aggregated at both Store and Style levels across all plans in the module.

Summary Store presents data at the Store ID level aggregated for all styles part of the Order Batching plan selection:  
**Allocated Quantity** : Total allocated units that are in Order Batching for the Store  
**#Styles** : Number of distinct styles that are in order batching across all the Order Batched plans for the store  
**#Allocations** : Number of distinct plans that are currently active in Order Batching for the store  
**Current Available to Allocate:** The aggregate available to allocate inventory for the styles in Order Batching for the store.  
**Store Capacity:** Original available capacity of the store  
**Store% to Capacity:** Its the proportion of utilised capacity for the store (This being greater than 100% denotes the store is breaching the available capacity)  
**Net Available Capacity:** Remaining store capacity after accounting for finalized plans for the day, plans in the Order Batching screen, and existing store inventory (OH + OO + IT)  
Please note that the OO component from Store inventory or Allocated/Order Batching is only considered if its expected to reach to Store within next 7 days. Also, this metric is independent of the uptop filter selection and is at a store level considering the entire product universe.

Summary Style presents data at the Style level aggregated for all styles part of the Order Batching plan selection:

**Allocated Quantity** : Total allocated units that are in Order Batching for the Style  
**#Stores** : Number of distinct stores that are in order batching across all the Order Batched plans for the style  
**#Allocations** : Number of distinct plans that are currently active in Order Batching for the style  
**Current Available to Allocate:** The available to allocate inventory for the style

 _Current Allocations:_

This View displays the allocations available in the Order Batching screen, at Style - Store - Release PO level.  
Through this table, the user can navigate to the recommendation screen from the Allocation Plan ID hyperlink and recommendation edits can be made and save. This will update all the relevant metrics in the OB views.  
The user can also edit Start Ship Date and Order Priority through this table.  
Key Metrics  
**Min Constraint:** Aggregated Min Constraint for all sizes  
**Min Allocation:** Aggregated Min driven allocated units for all sizes  
**Total Allocated Units:** Total Allocated units that are in Order Batching.  
**WOS Allocation:** Aggregated WOS driven allocated units for all sizes (excluding the min allocation)  
**Store Capacity:** Original available capacity of the store  
**Store% to Capacity:** Same as Summary Store  
**Net Available Capacity:** Same as Summary Store  
**StartShip Date:** DC out date as per the aligned logic for different PO types (Editable)  
**Order Priority:** Driven through feed and a default logic from Carters (Editable)

Finalize for Order generation:

This button finalizes all the allocation plans filtered through the top-level filters and triggers the downstream file generation.

Please note the following:

  * **All distinct allocation plans** listed in the _Current Allocations_ table will be finalized—**regardless of** any partial selection of Product or Store hierarchies in the filters above.

  * The row selection within the _Current Allocations_ table is only used for the **‘Set All’** action within the table—it does **not limit or affect** which plans are finalized through this button.




Order Batching Purging logic:

  * **B-type plans** are automatically purged overnight if no action is taken on them.

  * **L-type (PO) and S-type (New Store) plans** are purged **14 days** after their creation date if they remain unactioned.




Impact of Allocation Reserve for Order Batching Plans:

  * When a plan is active in **Order Batching (OB)** , the allocated units are **reserved** in the system, similar to how they are treated for finalized plans on the same day. This ensures the same units are **not available** for allocation in subsequent plans.

  * If **multiple plans** are created on the same day and the **combined allocation** exceeds the available ATA for a given Product-DC/PO combination, the system enforces a check:

    * The **second (or subsequent) plan** will **not be allowed** to move to OB if it breaches the ATA constraint.

  * In summary, the **total units** across **all active OB plans** and **finalized allocations** for the same day **must not exceed the available ATA** , ensuring allocation consistency and inventory accuracy.




