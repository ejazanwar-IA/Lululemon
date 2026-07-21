# Allocation x Optimisation FAQs

| Field | Value |
|---|---|
| Confluence page ID | `2696610488` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610488/Allocation+x+Optimisation+FAQs |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:11.015Z |
| Last mirrored | 2026-05-21 |

---

**Objective:**  
This document aims to provide a comprehensive understanding of general allocation logic-related queries and tickets. It is designed to serve as a reference for users, helping them systematically approach and resolve new queries.

### **Demand Categories in Allocation:**

Allocation logic primarily considers two categories of demand:

  1. **IA Recommended Demand**

     * This is based on demand forecasts, taking into account various constraints such as Weeks of Supply (WOS) and others.

     * The allocation demand is dynamically calculated to ensure optimal inventory distribution while adhering to these constraints.

  2. **Fixed Inventory Push**

     * Here, the user specifies a fixed quantity of inventory to be allocated for an article.

     * The optimizer aims to match the user-defined quantity. However, deviations may occur, resulting in lower allocations. These deviations are typically caused by breaches of user-set constraints, such as maximum limits.




### **Types of Inventory:**

There are two primary types of inventory in the allocation system:

  1. **Eaches**

     * Inventory allocated at the product level, in single units or multiples of one.

  2. **Packs**

     * Packs consist of either:

       * Multiple products (e.g., various sizes) bundled together based on specific configurations.

       * A single product bundled in quantities greater than one.

     * When allocating packs, the optimization process incorporates additional parameters to ensure the allocation of the most suitable pack. This approach balances meeting demand and adhering to constraints while optimizing inventory utilization.




**General issues:**  
1) **Why is there** **no allocation or less allocation than the demand/ Higher allocation than the demand**?

Scenario 1:  
This can happen if the stores already have enough inventory (OH+OO+IT) which can meet the demand of the stores. The optimiser always allocates as per Demand - Current store inv, considering there is unconstrained inventory in DC

Scenario 2:  
If there is a max constraint which is less than the demand, then the optimiser always constraint the allocation until max.

Scenario 3:  
If there is a min constraint which is greater than the demand, then the optimiser always tries to fulfil the min irrespective of the demand.  
  
Lead time forecast(ltf) calculation: 

**Example of final need calculation:**(This calculation in the backend happens at Style-Size-Store level, although the frontend data is shown at Style-Store level)

Min = 2, Max = 20, Demand(WOS forecast) = 13, Store inv = 4, Current day alloc = 1,  
lead time forecast(ltf) = 1

Hence, updated inv = Store inv + Current day alloc - ltf , updated inv = 4 + 1 - 1 = 4

P1, greatest(Max - updated inv,0) = greatest(20 - 4,0) = 16

P2, greatest(WOS forecast - updated inv,0) = greatest(13 - 4,0) = 9

P3, greatest(Min - updated inv,0) = greatest(2 - 4,0) = 0

Final need = P2 if (P1 <= P2 <= P3),

Final need = P1 if (P2 > P1),

Final need = P3 if (P2 < P3)

So final need here = P2 = 9

Note: WOS forecast -> Demand forecast corresponding to the target Weeks of supply.

Lead time forecast -> Forecast from the day of allocation to the store receival date  
Current day alloc -> The allocation (either in OB or Finalized) made to the store during the day which didn't reflect in the start of day inv 

This calculation in the backend happens at Style-Size-Store level, although the frontend data is shown at Style-Store level. Hence, the allocation number validations can deviate slightly if done using the front-end.  


  2. **Why does 1 store get preference over the other store while allocating constrained inventory?**  
The stores with higher ROS, higher Store grade get preference over other stores in the case of constrained inventory.  
For the tie-breaker of allocation to multiple stores in case of constrained inventory, it considers a score basis the ROS and the Store grade ranking of the stores under consideration.  


  3. **Why does the fixed inventory push not be met while allocating?**  
The fixed inventory push is not met in certain cases because of the max constraints.  
There are 2 parts to it as per OOTB:  
i) When the max of all stores is reached, but the fixed push is not allocated among the stores. This is a valid scenario.  
ii) When the max of all stores is not reached, but still the fixed push inv is not allocated.




eg. of Demand calculation incase of fixed inventory push:

**Style**| **Store**| **Size**| **Min**| **Max**| **Demand**| **Store inv**| **Final need**| **Allocated**  
(Default)| Allocated (fixed push Flag)  
---|---|---|---|---|---|---|---|---|---  
3S597910| 0419| XS| 1| 10| 16| 4| 6| 6| 6  
3S597910| 1370| XS| 1| 10| 3| 1| 2| 2| 8  
  
Here, the fixed push is 14  
Store split of store 0419 = 85.7% and for store 1370 = 14.3% (Basis product profile)

As per the store split, Store 0419 got a split of 12 and store 1370 got a split of 2  
Demand of store 0419 = 14*0.857 + Store inv (4) = 16  
Demand of store 1370 = 14*0.143 + Store inv (1) = 3

Since the max limit for Store 0419 is 10, it only received 6 units because it already had 4 units in stock. Similarly, Store 1370 received only 2 units based on the demand split, resulting in a total allocation of 8 units.

This behavior aligns with the default setting where fixed_inv_push_flag = False in the payload.

Handling Leftover Allocation  
To ensure any remaining units are allocated to stores that can still receive more without breaching their max limit, an additional iteration can be executed by setting fixed_inv_push_flag = True in the payload.

With this change: Store 1370, which has a max limit of 10, can still receive 6 more units from the fixed push of 14.  
The store receives an additional 6 units, ensuring that the total fixed push of 14 is fully allocated across stores.  
This approach guarantees that no max breaches occur while optimizing allocation.

  4. **Second allocation of an article not considering the updated inventory:**  
When an allocation is in either the "Order Batching" (OB) or "Finalized" state, the available DC inventory for the next allocation should be the original dc inventory minus the allocated quantity. 




For example, if there are 100 units available for a style and 30 units are allocated in "allocation_1" (and moved to OB or finalized), the next allocation should consider only 70 units (100 - 30)  


  5. **Bulk edit load time issue in recommendation screen:**  
This issue was caused by a resource-intensive operation that temporarily slowed down system performance and, in some cases, rendered the tool unusable. To address this, we have implemented two solutions: 



  * _**Immediate action:**_ involves increasing system capacity to better handle such operation. 

  * _**Long-term**_**:** Optimizing the bulk edit logging process to shorten the run time (WIP)  




  6. **Negative DC inventory in recommendation screen for multiple allocation flows:**  
This issue was caused due to following reasons:



  * Referencing the wrong DC inventory table for the specific allocation flow.

  * The allocated quantity in "Order Batching" or "Finalized" was not taken into account for the next allocation.  




  7. **The user was able to allocate a quantity greater than the available DC inventory:**  
The user edited the allocation quantity and, during the bulk edit of individual records, was able to save a higher allocation quantity, resulting in a total allocation exceeding the available DC inventory.  


  8. **CNA - > Review store and DC are displaying sizes that are not part of the Style Universe.**



  * **Size Display in UI** : The sizes displayed in the UI for a particular style are derived from the size universe in the product master, with these sizes being passed to IA through the product master and linked to the style via the existing Style x SKU/Size relationship. While active styles are considered, there is no specific filter for active sizes. In the absence of size-level eligibility, style-level eligibility is applied to all sizes in the product master.

  * **Assessment of Non-Selling Sizes** : Based on the observations, these sizes are not sold with this style, indicating they are likely obsolete or outdated data entries that the system is unintentionally pulling. It is unlikely that any inventory or ATA exists for these sizes.

  * **Forecasting Impact** : While still under review, it is believed that inactive sizes will rarely have corresponding forecasts - recheck this

  * **Allocation Relevance** : Even if there's a minimal forecast, as long as there is no associated ATA, there won't be any allocation generated for these sizes.  




  9. **Bulk edit is not saving the changes, even though there is available DC inventory:**  
This edge case occurs when the user tries to allocate units to stores, but the total allocation exceeds the available DC inventory.




For example, if there are 100 units in the DC and 150 eligible stores, and the user allocates 1 unit to each store via bulk edit, an error occurs because the total allocation (150 units) exceeds the DC inventory (100 units).  


  10. **DC ATA Incorrect in CNA Flow:**  
The sub-style inventory will be consolidated under the main-style and made available in the tool. When the DIMs match, the sub-style inventory will be aggregated with the main-style. If the DIM is only present in sub-style, the will appear as the main-style on the recommendation screen. However, the outbound file will break down the allocated inventory by the corresponding sub-styleID DIM combination.  


  11. **Allocation happening even when the min and demand are zero:**  
In these cases, while the aggregated demand shows as 0, it is effectively 1. This happens when the size-level demand for a style-store combination is less than 0.5, causing the demand to round to 0 in the front-end table. However, the allocation process uses different logic, where decimal forecasts are redistributed to achieve an integer value.




Thus, the Aggregated Demand displayed in the UI, calculated as round(0.304) + round(0.247) + round(0.185) + round(0.177) + round(0.085) + round(0.061) = 0, differs from the actual demand passed to the optimizer, which sums up to approximately 1 (0.304 + 0.247 + 0.185 + 0.177 + 0.085 + 0.061). This demand is then distributed as integer values using a prioritization logic.  


  12. **Allocated quantity exceeding demand or max:**  
The allocation appears to exceed demand in scenarios where packs are being allocated. Even when the system attempts to meet the min or demand for specific sizes within the pack, the lack of units in eaches for those sizes causes the entire pack to be allocated. As a result, other sizes within the pack--those that have already met their demand--also receive inventory, leading to an overall higher allocated quantity/max breach. 




article| size| store inv| min| max| demand| units in pack| allocated total  
---|---|---|---|---|---|---|---  
123| S| 0| 2| 5| 1| 1| 2  
123| M| 1| 2| 5| 2| 3| 6  
  
  13. **Constraints edit in review store and DC not reflecting in allocation:**  
When multiple styles are present in the CNA Review Store & DC, and the constraints for each style are changed individually, only the most recently edited style's updated constraints are considered during allocations. The updated constraints for the other styles were being reverted.  


  14. **Demand incorrect in recommendation screen:**  
In the recommendation screen, the "Aggregated Demand (for Target WOS)" for the 'IA Recommended' demand type is based solely on forecast data. However, for the 'Fixed' demand type, it includes both the fixed inventory push and the store's total inventory (there might be slight deviations due to rounding at the style-size-store level). In the case of fixed demand, the allocation of fixed inventory (based on overall proportions) is independent of the store's current inventory position.




Forecast Demand using Fixed Push Example:

  * Store 1 Inventory = 200, Store 2 Inventory = 150

  * Fixed Push = 1500

  * Initial forecast for Store 1 = 300, Store 2 = 200 based on real demand

  * Proportion of stores: Store 1: Store 2 = 3:2

  * Therefore, for Store 1: f=1500×3/5=900, and for Store 2: f =1500×2/5 = 600

  * Thus, the Aggregated Demand would be 900+200 = 1100 for Store 1, and 600+150 = 750 for Store 2.




For 'IA Recommended' demand type, the Aggregated Demand is simply the raw forecast (300 for Store 1 and 200 for Store 2 in this case).  


  15. **Style missing from CNA details:**



  * The style is not included in the Details table in CNA when there are no eligible stores in the product-store eligibility mapping.  

  * Availability DC inventory is zero

  * Product dc mapping missing/invalid

  * Store dc mapping missing/invalid

  * Rules resolution is not giving output

  * Mapped DC(s)/Store(s) inactive

  * Mapped stores not part of store group  




  16. **Constraints in review store and dc are incorrect:**  
Currently, the validity of child RCLs in the RCL Constraint Master is being used as the validity for the main RCL in the RCL Master. This causes issues when a new hierarchy is added, with the end date of the new hierarchy exceeding the end date of the RCL Master record. To resolve this, the main RCL in the RCL Master should either have the maximum end date of the child RCL records or the end date should be set to 2050.  


  17. **Inactive stores/products are getting allocated:**  
The stores marked as inactive in the store status should be reflected in both the store master and the store attributes filter. The ingestion process needs to execute the load time attributes stored procedure (SP) to update these tables for stores. Similarly, for products, the product master and product attributes filter should also be updated with the status. These updates will be available for allocation after the next successful ingestion.  


  18. **Stores missing from Review Store and DC:**  
The store record missing from the store cluster and dc transit time mapping can cause this issue.  


  19. **Store grade values are blank/zero:**  
The store data should have details in the article store grade table to ensure it is reflected in the review store and the DC.  


  20. **User Created Product profile is not available in CNA details:**  
The product profile created by the user will become the default for allocation once it is tagged to the style corresponding higher priority hierarchy in the DC-Store Policy tab.  


  21. **Partial sizes of the pack are getting allocated:**  
The issue with partial size allocation is due to the following reasons:



  * The size was not selected from the size profile in the CNA details.

  * The size has been marked as inactive in product status.  




  22. **Product Profile(PP) numbers in Review Store and DC not matching with PP table:**  
The overall proportion of the product profile in the review store and DC for IA demand allocation is calculated using the forecast for the WOS constraint weeks. However, the PP table (Carters) contains the overall proportion values for the entire forecast period.  


  23. **Incorrect default store group in CNA details:**  
The default store group should be determined by the type of allocation flow. For Carters, in normal allocation flow, the default store group is _**existing_USA/existing_CAN**_ ; for PO allocation, it is _**overall_USA/overall_CAN**_ ; and for new store allocation, it is _**new_USA/new_CAN.**_  


  24. **Store Minimum Requirement Not Being Met (Eaches Allocation):**  
The minimum constraint for a store is satisfied in the IA Demand - Min_Forecast allocation strategy when the DC has sufficient inventory. However, in cases of constrained inventory (i.e., when the DC does not have enough inventory to fulfill the minimum requirement for all stores), some stores may not meet their minimum thresholds.

Additionally, minimum consideration during allocation happens after subtracting updated inventory (as explained in Issue 1).

Validation of Current Day Allocation Calculation: The calculation should only consider allocations made during the current day.

There are two common issues observed:

Timezone Difference:

The allocation plans should follow the client's timezone (e.g., EST for USA).  
However, in certain cases, the system incorrectly considers IST or another timezone, leading to incorrect metric calculations.  
Refresh Date Handling:

The allocated units should be based on post-refresh data.  
The system must ensure that the current day allocation correctly accounts for the latest refresh date to avoid discrepancies.  


  25. **Packs are not prioritised over eaches in allocation:**  
The packs are prioritised over eaches in allocation when the NON_PACK_PENALTY=TRUE flag is passed as a parameter in allocation payload  


  26. **User reserve is not getting considered in the currently available DC inventory:**  
The currently available DC inventory should be as follows:  
_**currently available DC inventory = Beginning available inventory - Allocated qty - User reserve qty**_




### **Packs Allocation:**

Pack allocation differs from eaches in that it must account for pack configurations, which can impact minimum breaches, maximum breaches, and over/under allocation.

This is due to cost optimization, where the system balances over/under allocation to meet the optimized need based on available pack configurations. As a result, pack allocation introduces additional complexities compared to scenarios where inventory is available in eaches.

#### **Cost Optimization Logic in Pack Allocation**

In the allocation process, cost optimization plays a crucial role in determining pack allocation.

For example, consider Style -> 2R061610 and Store -> 3021\. There are four sizes with a pack configuration that deviates from the final need pattern. This means the pack configuration and final need are not in the same ratio, requiring optimization to balance over/under allocation across sizes. The goal is to allocate in a way that minimizes cost while ensuring an optimal distribution.

###### **Size**

| 

###### **Pack Config**

| 

###### **Min**

| 

###### **Max**

| 

###### **Demand**

| 

###### **Store inv**

| 

###### **Ltf**

| 

###### **Final need**

| 

###### **ROS**

| 

###### **1 pk delta**

| 

###### 2 pk delta  
  
---|---|---|---|---|---|---|---|---|---|---  
2T| 3| 3| 7| 5| 1| 1| 5| 1.1| 5 - 3 = 2| 5 - 6 = -1  
3T| 4| 3| 7| 7| 1| 0| 6| 1.6| 6 - 4 = 2| 6 - 8 = -2  
4T| 3| 3| 7| 5| 1| 0| 4| 1.3| 4 - 3 = 1| 4 - 6 = -2  
5T| 2| 5| 7| 5| 2| 0| 3| 0.9| 3 - 2 = 1| 3 - 4 = -1  
  
The cost is determined using the formula:  
Cost = Σ |Δ * ROS|

#### **Example Calculation:**

  * **1 Pack Cost:**  
2×1.1 + 2×1.6 + 1×1.3 + 1×0.9=7.6

  * **2 Pack Cost:**  
1×1.1 + 2×1.6 + 2×1.3 + 1×0.9 = 7.8




Since the cost for allocating 1 pack (7.6) is lower than 2 packs (7.8), the optimizer chooses to allocate only 1 pack in this case.

#### **Key Considerations:**

  * Allocating 1 pack leads to under-allocation for certain sizes:

    * 2T -> 2 units

    * 3T -> 2 units

    * 4T -> 1 unit

    * 5T -> 1 unit

  * **Min Breach:**

    * Size 5T has a minimum requirement of 5 units

    * Allocated: 2 units

    * Store Inventory: 2 units

    * Total after allocation: 2 + 2 = 4 (less than the required 5)




This results in a min breach for Size 5T.

  27. **Why does min breach happens for certain sizes during pack allocation?**  
This can occur due to cost optimization while considering pack configurations. As seen in the example above, Size 5T experiences a min breach.

To address this, configurable flags are introduced in the optimization process:

Default Setup: Allows allocation to continue despite min breaches.  
Strict Min Constraint: Ensures that min is always met during pack allocation.  
To enforce min as a hard constraint, the fo_min (Overallocation Factor for Min Model) should be set to 0 (default is 1).

Setting fo_min = 0 ensures that all individual sizes meet their minimum requirements.  
Key Consideration: This may lead to overallocation of certain sizes, potentially causing max breaches.

  28. **Why does max breach happens for certain sizes during pack allocation?**  
This can occur due to cost optimization while considering pack configurations. Similar to min breach, max breach can also happen.  
To address this, configurable flags are introduced in the optimization process:

Default Setup: Allows allocation to continue despite max breaches.  
Strict Max Constraint: Ensures that max is always considered during pack allocation.  
To enforce max as a hard constraint, the hard_max_for_demand should be set to True (default is False).

Setting hard_max_for_demand = True ensures that no individual sizes breach their max requirements.  
Key Consideration: This may lead to underallocation of certain sizes.

  29. **Why does fixed inventory allocation does not allocate as per user input incase of pack allocation?**  
Due to cost optimization based on the final need calculation, some packs remain unallocated, even though other stores still can accommodate more packs without breaching their max limit.

As explained in Issue 3, setting **fixed_inv_push_flag = True** ensures that the system attempts to allocate the fixed requirement until a max breach occurs.

  30. **Why is inventory left over even incase of constrained inventory allocation (IA Forecast Demand)?**  
There is a WOS adjustment that happens at size level incase of constrained DC inventory.  
This adjusted WOS is derived from DC availability and considers the current store's OH, OO, IT inventory along with the demand forecast. However, it does not factor in the ROS at the store level.

The rationale behind this approach is to distribute inventory across more stores, ensuring demand coverage for a specific number of weeks, rather than meeting the target WOS for some stores while leaving others unfulfilled.

For example:

     * If the demand per store per week is 1 unit, with 10 stores and a WOS of 10, the total demand would be 100 units.

     * If the DC inventory is only 60 units, the optimizer rescales the WOS to 6, enabling all 10 stores to receive inventory for 6 weeks. This is preferable to fulfilling the entire 10-week demand for 6 stores while leaving the remaining 4 stores without any inventory.

This rescaling logic operates at the size level and works effectively for inventory allocations in eaches. However, for pack allocations, due to cost optimization logic, some inventory may remain unallocated. This is as per the default flag, allocate_after_cutoff_wos - False  
By changing this flag, allocate_after_cutoff_wos - True, the further iteration rechecks the initial demand and allocate any remaining inventory, ensuring nothing is left unutilized.




