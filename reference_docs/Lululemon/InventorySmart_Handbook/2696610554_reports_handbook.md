# Reports Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696610554` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610554/Reports+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:12.370Z |
| Last mirrored | 2026-05-21 |

---

Inventory Smart majorly has these reports on the tool.

  1. Lost Sales

  2. Excess Inventory

  3. Daily Allocation Report 

  4. Store Stock Drill Down

  5. Deep Dive Allocation




## **1\. Lost Sales:**

This report provides the sales lost in units or $ due to the unavailability / under-stocking of Primary SKUs in stores for the last 52 weeks.

Listed below are the key conditions to calculate the Lost Sales:

###### _**Key Conditions For Lost Sales**_

  1. Primary SKU should have had inventory recorded in the store.

  2. Average units sold within the cluster > Units sold in that particular store.

  3. Proportion of stores with inventory (Active Stores) across the store cluster > X%.

  4. Opening and Closing Inventory must be 0.




### _**Query and Table list required to get started:**_

### [_Query_](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/1386283823)

**Table Schema:**

**Sl no**| **Columns**| **Datatype**| **Formula/Definition**  
---|---|---|---  
**1**|  Primary SKU ID| text| Column related to product hierarchy order  
**2**|  Primary SKU Description| text| Column related to product hierarchy   
**3**|  Store Band|   text| Column related to store hierarchy  
**4**|  Fiscal Week| numeric | Fiscal week for which the lost sales is calculated  
**5**|  Fiscal Year| date|   Fiscal year for which the lost sales is calculated  
**6**|  Opening Inventory|   numeric | Inventory Available at beginning of the week at store band-Primary SKU level  
**7**|  Unit Sold| numeric | Units of Primary SKU sold in the store for the entire week   
**8**|  Cluster Average Sales| numeric  | Average of the units sold across stores in the same store band  
**9**|  Lost Opportunity (Units) | numeric  | Sales lost due to under stocking based on Quantity sold and cluster average sales  
**10**|  Lost Opportunity (Revenue) $| numeric | Lost units * average retail price  
  
## **2\. Excess Inventory Report**

This report provides a detailed view of the over-stocking patterns across stores over the next 52 weeks.  
Excess Inventory is calculated based on the Total Inventory, Forecasted Demand, and Target Weeks Of Supply (Target WOS). Listed below are the key conditions to calculate the excess inventory.

###### _**Key Conditions For Excess Inventory**_

  1. Primary SKU ID should have on-hand inventory or incoming inventory to the store.

  2. Primary SKU ID should have a past sales history in the store.

  3. Any inventory over and above the X% threshold of Target WOS is considered as excess inventory in the system.

  4. The report can be calculated at a weekly level based on the beginning of period inventory. 




  
**Calculations:**

WOS Threshold = Target WOS * (1+X%)

Current WOS = Weeks the current inventory will last as per the demand requirements

Excess Inventory = Current Inventory - Demand for WOS Threshold

###  _**Query and Table list required to get started:**_

### [Query](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/1386283764)

  
**Table Schema**

**Sl no**| **Columns**| **Datatype**| **Formula/Definition**  
---|---|---|---  
**1**|  Fiscal Week| Numeric | Fiscal week for which the excess sales is calculated  
**2**|  Fiscal Year| Date | Fiscal year for which the excess sales is calculated  
**3**|  Store Band| text| Column related to Store hierarchy order  
**4**|  Primary SKU ID| text| Column related to product hierarchy order  
**5**|  Primary SKU Description| text| Column related to product hierarchy order  
**6**|  OH| Numeric| On hand units at Stores aggregated for Store Band  
**7**|  IT| Numeric|   In-Transit units to Stores aggregated for Store Band  
**8**|  OO| Numeric|   On Order units to Stores aggregated for Store Band  
**9**|  Unit Sold | Numeric | Units of Primary SKUs sold in the store for the entire week   
**10**|  ROS| Numeric | Rate of sales per week based on IA forecast  
**11**|  WOS Threshold| Numeric| Target Weeks of Supply for the Store Band-Primary SKU combination  
**12**|  WOS | Numeric | Approximate weeks of supply  
**13**|  Excess Inventory | Numeric| Current Inventory - Demand for WOS Threshold  
**14**|  Excess Inventory ($)| Numeric| Excess Inventory * Unit Retail  
**15**|  Inventory Closing Balance| Numeric| Inventory Available at End of week at Primary SKU store band level  
  
## **3\. Daily Allocation Report**

It provides a detailed view of the allocation metrics like units allocated, units remaining to allocate, and reserved units at an allocation plan level. These details can be viewed either at a DC level or at a Primary SKU level.

  * _this query is written by the engineering team and based on the filters selected the results are fetched in real time_




**Table Schema - Product level**

**Sl no**| **Columns**| **Datatype**| **Formula/Definition**  
---|---|---|---  
**1**|  Primary SKU ID| Text| Column related to product hierarchy order  
**2**|  Plan ID| Text | Column related to product hierarchy order  
**3**|  Primary SKU Description | Text| Column related to product hierarchy order  
**4**|  Total Units Allocated | Numeric | Total allocated units at the Primary SKU ID level for the selected day  
**5**|  Min Units Allocated| Numeric| Min Units allocated at the Primary SKU ID level for the selected day  
**6**|  WOS Units Allocated| Numeric| WOS Units allocated at the Primary SKU ID level for the selected day  
**7**|  DC Available | Numeric| Units available in DC after the allocation was release  
**8**|  Reserve Quantity | Numeric| Units Reserved by the user for the corresponding Primary SKU  
  
  
**Table Schema - DC level**

**Sl no**| **Columns**| **Datatype**| **Formula/Definition**  
---|---|---|---  
**1**|  DC Code| Text | Column related to store hierarchy  
**2**|  Unit Allocated | Numeric | Total units allocated from the DC level for the selected day  
**3**|  Min Units Allocated| Numeric| Units allocated for min constraint from the DC for the selected day  
**4**|  WOS Units Allocated| Numeric| Units allocated for WOS demand from the DC for the selected day  
**5**|  IT| Numeric| In-Transit units  
**6**|  OH| Numeric| On hand units  
**7**|  OO| Numeric|   On order units  
  
## **4\. Store Stock Drill Down Report**

Provides a detailed view of important metrics like available DC inventory, Store inventory levels & Sales at a Store level. The table also allows the user to see the Product Status that is Shortfall, Normal, Excess and Out of Stock.

**Table Schema:**

**Sl no**| **Columns**| **Datatype**| **Formula/Definition**  
---|---|---|---  
**1**|  Primary SKU ID| text| Column related to product hierarchy order  
**2**|  Primary SKU Description| text| Column related to product hierarchy order  
**3**|  Plan| text| Column related to product hierarchy order  
**4**|  Department| text| Column related to product hierarchy order  
**5**|  Class| text| Column related to product hierarchy order  
**6**|  Store Cluster| text| Store Band  
**7**|  Target ST %| %| Targeted Sell Through Percentage  
**8**|  STD ST %| %| Season Till Date Sell Through Percentage  
**9**|  STD Receipt Units| Numeric| Season Till Date Receipt Units  
**10**|  STD Receipt $| Numeric| Season Till Date Receipt in Dollars  
**11**|  STD Sales $| Numeric| Season Till Date Sales in Dollars  
**12**|  STD Sales Units| Numeric| Season Till Date Sales Units  
**13**|  LW ST%| %| Last Week Sell Through Percentage  
**14**|  LW Receipt Units| Numeric| Last Week Receipt Units  
**15**|  LW Receipt $| Numeric| Last Week Receipt in Dollars  
**16**|  LW Sales $| Numeric| Last Week Sales in Dollars  
**17**|  LW Sales Units| Numeric| Last Week Sales Units  
**18**|  On Hand| Numeric| On hand units at Store Band  
**19**|  In Transit| Numeric|   In-Transit units to Store Band   
**20**|  On Order| Numeric|   On Order units to Store Band  
**21**|  Total Inventory| Numeric|   Total Inventory at Store Band  
**22**|  DC OH| Numeric| On hand units at Distribution Centers  
**23**|  DC IT| Numeric| In-Transit units to Distribution Centers  
**24**|  DC OO| Numeric| On Order units to Distribution Centers  
**25**|  Total DC Inventory| Numeric| Total Inventory at Distribution Centers  
**26**|  Primary SKU Status| text| Inventory status of the product  
  
###  _**Query and Table list required to get started:**_

### [Query](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/1386283936)

## **5\. Deep Dive Allocation** **Report:**

This report provides a detailed view of the important allocation metrics like the number of allocations released, the number of units allocated, quantity match %, and size match %  at a store-style level for the selected period.

**Table Schema:   **

**Sl no**| **Columns**| **Datatype**| **Formula/Definition**  
---|---|---|---  
**1**|  # Allocations| Numeric| Number of allocations released based on the filters applied  
**2**|  # of units of Allocation| Numeric| Number of units allocated based on the filters applied  
**3**|  Qty Match % (Plan vs Actual) | Numeric | Aggregated ratio of Actual Allocation vs Planned   Allocation expressed in terms of %.  
**4**|  Qty Match % (Actual vs Sales) | Numeric |   Aggregated % match of allocated units in comparison to ideal allocation units.  
**5**|  Size Match % (Plan vs Actual)| Numeric |  Aggregated ratio of actual allocation vs planned allocation at size level expressed in terms of %.  
**6**|  Size Match % (Actual vs Sale)| Numeric | Aggregated % alignment of allocated units in comparison to sales pattern vs ideal allocation pattern at size level.  
  
Explanation and example for the above KPI wrt Deep Dive Report:  
  
_**  Quantity Match %**_

  1. Planned Allocation: Units recommended to be allocated from the tool

  2. Actual Allocation: Units allocated to store as per store receipt estimates

  3. Qty Match % (Plan vs Actual):  Ratio of Actual Allocation vs Planned Allocation expressed in terms of %.

  4. Qty Match %(Actual vs Sales): % Match of allocated units in comparison to ideal allocation units.




###### _**Key Terms**_

  1. Units Sold: Units sold during the selected period.

  2. Sales %: Sales Contribution of each store

  3. Ideal Units: Units that would be allocated had we known the exact sales contribution of that store

  4. Abs. Variance Units: Absolute unit variation of allocated units from ideal unit




###  _**Sample Calculations For   Given Period**_

  1. **Quantity Match (Plan vs Actual):**




Planned Quantity Match % = (Actual Allocation/Planned Allocation)*100

![](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610554/AD_4nXc4Ml3glF44tEYa6caxPdvpKRX9NVqSJB9merIjRlBHfzFZ_RH1QVS8j-rD9ynmfPjc-0Gg21LL5ZVXihgJqAO2x3G6AA-qyJV_pFgFx4QoypAgNKnrBFdgppq_aDCnJ5_JV_wuO251VRnUWerwsTPd6rKKjdtdTtYkFjk73iItAP5e-jN0yJk%3Fkey=Op3NfWy3k96Te6wk03UXRA?version=1&modificationDate=1779356653047&cacheVersion=1&api=v2&width=760&height=175)

  2. **Quantity Match (Actual vs Sales):**




Ideal units = (Sum of Actual Allocation at Style level)*Sales %

Allocation Qty Match % = (Actual Allocation/Ideal Units)*100

![](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610554/AD_4nXdwcL5_LpuWnELZep6T4dmEFsHNSI6_7_SVjSjjkigo5CJ2p8M5DyCMNsBjdBa7oDRNdyxrV_GvRaIGa9jLyt7BDU2wpyxukesUCvHp7wCplrXXXBUSC4TB0pk7mA9f9q2reYmZapqvTOnuM72Lmon5e-tZe0zxKMtwwI6f25ATg-MHCoPr-Nw%3Fkey=Op3NfWy3k96Te6wk03UXRA?version=1&modificationDate=1779356652774&cacheVersion=1&api=v2&width=766&height=207)

######  _**Size Match %**_

  1. Planned Allocation: Units allocated from the Inventory Smart tool.

  2. Actual Allocation: Units allocated to the store as per store receipt estimates.

  3. Size Match % (Plan vs Actual):  Ratio of actual allocation vs planned allocation at size level expressed in terms of %.

  4. Size Match %( Actual vs Sales):  % Alignment of allocated units in comparison to sales pattern vs ideal allocation pattern at size level.




###### _**Key Terms**_

  1. Units Sold - Units sold during the selected period.

  2. Sales % - Sales Contribution of each size in the store.

  3. Ideal Units - Units that should have been allocated had we known the exact sales contribution of that store (assuming total allocation quantity remains the same).

  4. Abs. Variance Units - Absolute unit variation of allocated units from ideal units.




###### _**Sample Calculations For Given Period**_

  1. **Size Match (Plan vs Actual):**




Planned Size Match % = (Actual Allocation/Planned Allocation)*100

![](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610554/AD_4nXdZMKTNglz40Q6R0Fri01wjBhODGUaqu74WN7ejpyRYyENTge1UxzAanBwadBNQGcAPCm-5uDJRM6tIoHw-t-DqnK_UOdnnwAovZgcA3H9_ZqUwINu-jzMAwv5xVLoN62NEBaReBac6WDK5w1vNxZu0HsQ-TgMI-7Zw3dW0a8RqSQSCndRkYrk%3Fkey=Op3NfWy3k96Te6wk03UXRA?version=1&modificationDate=1779356652773&cacheVersion=1&api=v2&width=760&height=148)

  2. **Size Match (Actual vs Sales):**




Ideal units = (Sum of Actual Allocation at Style level)*Sales %

Allocation Qty Match % = (Actual Allocation/Ideal Units)*100

![](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610554/AD_4nXfDOELmBcMbFLcZthXG4g3g9qf7P1SdXNaPVBt-NzpY9saFFRZowfxK6OMtUU_vHU6sI82Bd7Q4CUFVgSfSVn5yROtx4BiyW0M-X4YOygJmjcOSZQaexzcvrMEtYx4egC7Qu-UWbRnFJo-8F4JPEliBGbhkisXCJYX6RNK0zXZTuibd31MO4ys%3Fkey=Op3NfWy3k96Te6wk03UXRA?version=1&modificationDate=1779356652773&cacheVersion=1&api=v2&width=770&height=198)

**Note:   the above example is taken from Carter's OOTB document (**Adv Derived Tables Queries does not have deep dive report, once we have it, will link it)  
  
  
**FAQ:**

  1. **Will all clients have the same number of reports?** No, based on client requirement and sign off the reports will be finalized

  2. **Does the schema remain the same for all clients?** There may be some customization required to tweak it according to client requirements and data 

  3. **How to start off with the reports?** a- understand the data b- based on the above mentioned schema make a rough schema structure c- connect with DB and Dev team for alignment and then start writing the queries   
  





