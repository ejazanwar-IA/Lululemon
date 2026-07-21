# DC to DC Transfer Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696610653` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610653/DC+to+DC+Transfer+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:14.143Z |
| Last mirrored | 2026-05-21 |

---

## **DC to DC Transfer**

The **DC-DC Transfer** feature enables users to execute inventory transfers between eligible distribution centers (DCs) for a given product choice. Currently, the system supports transfers across channels, meaning that each choice will have two designated DCs available for transfer.

  * For **VSL and Pink** , transfers can occur between **S015** and **S073**.

  * For **Beauty** , transfers can occur between **S003** and **S073**.




This functionality is supported by **three screens** :

  1. **DC Transfer Constraints** – Used to set up the **minimum transfer quantity** required for a DC-DC transfer.

  2. **DC Service Levels** – Defines the **service level for each eligible DC** based on the product.

  3. **DC to DC Transfer** – The main screen where users **initiate and process** DC transfers




Lets dive into the configurations first…

### DC Transfer Constraints

This screen is located under the **Constraints module** , within the **DC-DC Transfer tab**.

The **DC Transfer Constraints** screen allows users to configure the **minimum transfer quantity** required for inventory movement between eligible distribution centers (DCs). This table is at a SKU - Source DC - Destination DC level. Thus, users can set different minimums for different routes for the same SKU.

  * The screen displays a table with product choices, sizes, source DCs, and destination DCs.

  * The **" Min Transfer Qty"** column, highlighted in the image, lets users define the minimum number of units that must be transferred 

  * Users can apply filters (e.g., by **brand** and **category**) to refine the selection of products.

  * The **" Set All"** button likely allows bulk updates for the minimum transfer quantity.




Consider SKU **112501254A2 (Size 30_C)** , which is eligible for transfers between S015 and S073:

  * Route 1: Source DC: S015 → Destination DC: S073, Min Transfer Qty: 10

  * Route 2: Source DC: S073 → Destination DC: S015, Min Transfer Qty: 20




![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXegfpkTh01mZ2jBIpz_bgC0PI8zkX3ECQu0FQ6fQ3LxKS5kjs5pS3A3MW-jxYqZ3bK9u3r-MFlduXjnxiQjlk-iWoH5U06OFu5Ay6QONMpg_A9b0M8Owt0oEqQGAfMxsroGSnKq?key=5V2TMS3BHRbeSg-6LFzEDIYP)

**Column Description:**

**Sl No**| **Columns**| **Datatype**| **Definition / Formula**  
---|---|---|---  
**1**|  Choice| text| Choice ID  
**2**|  Choice Info| text| Product hierarchy and attributes  
**3**|  Size| numeric| Size  
**4**|  Source DC| text| DC ID of the source DC  
**5**|  Destination DC| text| DC ID of the destination DC  
**6**|  Min Transfer Qty| numeric| Minimum number of units that must be transferred from the source to destination  
**7**|  Updated By| text| Username of the user who updated the value most recently  
**8**|  Updated At| date| Date at which this value was modified most recently  
  
### DC Service Levels

Here users can setup the **operating parameters** for the DC at a SKU level. Users can configure parameters such as Min Stock, Target WOS and Safety Stock levels in this screen. The parameters set into this screen will be used to calculate whether a DC is in an **Excess or a Deficit Inventory State** (this will be explained further in the DC to DC Transfer Section)

**Note** : These parameters will only be considered for the DC to DC Transfer module and its calculations and will not impact the recommendations on OMS and vice versa.

**Key Functions of this Screen:**

  * It allows users to define service level-related settings for each SKU at a specific **DC**.

  * The table displays key attributes such as:

    * **Choice Info & Size** – Product attributes and hierarchies

    * **DC** – Specifies the distribution center where the parameters apply.

    * **Target WOS (Weeks of Supply)** – Determines the ideal inventory coverage period.

    * **Min Stock** – Defines the minimum stock level required at the DC.

    * **Safety Stock Method** – Allows selection of a method (e.g., Service Level) to calculate safety stock.

    * **Service Level %** – Specifies the desired service level percentage for inventory planning.  
**Safety Stock WOS / Units** – Represents safety stock expressed in weeks of supply or absolute units.

  * The **" Set All"** button enables bulk updates for multiple SKU-DC combinations.




**Column Description:**

Sl No| Columns| Datatype| Definition / Formula  
---|---|---|---  
1| Choice| text| Choice ID (SKU)  
2| Size| text| Size of the SKU  
3| DC| text| Distribution Center ID where the SKU is located  
4| Target WOS| numeric| Target weeks of supply for the SKU at the DC  
5| Min Stock| numeric| Minimum stock required at the DC  
6| Safety Stock Method| text| Method used to calculate safety stock (e.g., Service Level)  
7| Safety Stock Units| numeric| Number of units allocated as safety stock  
8| Service Level %| numeric| Service level percentage used to determine safety stock  
9| Safety Stock WOS| numeric| Safety stock expressed in weeks of supply  
  
**Issue Management for DC Transfer Constraints and Service Levels**

**Issue Priority**| **Issue Priority Description**| **Examples of Potential Issues**  
---|---|---  
P0(Emergency)| Any emergency condition that makes use of key parts of the system impossible or is significantly impaired. It requires immediate attention.| The page does not load  
P1(Urgent)| Any condition (excluding P0 issues) that makes use of any parts of the system difficult that the user cannot reasonably circumvent.| Filters are not sticking  
P2(Normal)| Any condition (excluding P0 & P1 issues) that leads to parts of the system not working as expected but doesn’t impair regular processes for the users.| Increased screen loading timeColumn freezing is not working  
P3(Low)| Any condition (excluding P0, P1, and P2 issues) that causes minor inconvenience in using the system but does not impair regular processes.| Incorrect placement of a buttonIncorrect column header name  
  
### DC to DC Transfer (Main Page)

The **DC to DC Transfer** screen is the primary interface where users can review the inventory situation across Distribution Centers (DCs) and plan or execute inter-DC transfers. This screen provides a consolidated view at the **Choice (Style-Color) - DC** level, with a drill down at the size level. The module contains metrics to help users make informed transfer decisions.

#### Landing table (Choice-DC Level)

This screen provides a consolidated view at the **Choice - DC** level. Users can select choice(s) from this screen and directly approve the transfer or review/edit the transfer recommendation at the granular level in the next table. There is also a toggle to show only recommended choices v/s all choices eligible for a transfer.

Below are the key metrics shown in this table:

**Total DC OH (On Hand)**

  * Current available inventory in the DC for the Choice.

  * Reflects what is physically present and ready to be used or transferred.




**Demand Projection**

  * Agg. projected store allocations for the Choice at the DC constrained by the store OH

**Upcoming PO Units**



  * Quantity of the SKU expected to arrive at the DC via confirmed purchase orders

  * Gives visibility into incoming supply.




**Upcoming PO Date**

  * Estimated delivery date for the incoming PO units.

  * Assists in planning transfers around supply timelines.




**DC TWOS (Target Weeks of Supply)**

  * Desired number of weeks the DC should be stocked for 

  * Flowing in from the DC Service Levels module




**Sales Forecast**

  * Projected store allocations over the store TWOS period accounting for store demand, Min, Max and projected Store OH

  * Demand is first calculated for each store over its TWOS and then aggregated up.




**DC CWOS (Current Weeks of Supply)**

  * Indicates how long the current inventory will last, based on projected demand.

  * Helps spot excess (high CWOS) or shortage (low CWOS) situations.




**DC Min**

  * Indicates the min qty that should be present in the DC for the choice

  * Flowing in from the DC Service Levels module




**Safety Stock**

  * The safety stock units that should be present in the DC to achieve the desired service level

  * Flowing in from the DC Service Levels module




**Walkthrough:**

Step1: Select the products from the overhead filters

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXdPE-X7OtvLJj7sfpHT93uNbxk-afLkS2T8F1JwsZGvIgftIPF-uDqy9_fujSQuVV8kOxgbKndZUcfGcnkeiEr5aK79FiKCAjNkXb0AXV07017sLNP4VS-K1hTKomv4JWmPI8hjaQ?key=5V2TMS3BHRbeSg-6LFzEDIYP)

Step2: Set the Recommendation Toggle

When ON (blue), the table shows **only recommended Choices** that the system suggests for transfer (choices with transfers exceeding the Min Transfer Qty)  
To view all Choices (even those without recommendations), simply flip the toggle OFF

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXc-UJnZyV10XxoFdqFiYAGpVYH4dopI3eO_JBCZGKlqahop7ip6USry-9mpmvRmHIdg7IhK0_GuhwlE1UWsHqs-lkWkSsOFM5ZFDo0rP4WYhspCyvmT1pbmm19NgJyfF-R_7sR7?key=5V2TMS3BHRbeSg-6LFzEDIYP)

Step3: Select and Take Action on Choices

From the main table, **select one or more Choices** using the checkboxes.  
**a) Approve Transfer Directly**

  * Click on the **“Approve Transfer”** button to execute the transfer based on system recommendations.

  * Best for straightforward transfers without the need for deep analysis.




**b) Review Recommendation and Sizes**

  * Click on **“Review Recommendation and Sizes”** to dive deeper into inventory breakdowns and size-level details.

  * Ideal for validating the system’s suggestions or making manual adjustments


![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXfZPikbaF4mrCuW-BxmP_J6LIIA9fhvi17uDvGptr163mRbpvnv5R-jjD0L5bhtQIgvoy05I7ZHXaBWHYc7CC5kBlyOYO5_H7m8CNpljZqIwL7o1pf2Mk3ZUp1jNvkDM6do-V1y?key=5V2TMS3BHRbeSg-6LFzEDIYP)

#### Review Sizes

The **Review Sizes** tab provides a detailed, view-only breakdown of inventory status at the **Size-DC level** for a selected Style Color (Choice). This view complements the main Choice-DC level table by offering greater granularity. It helps users understand which specific size-DC combinations are in **excess or deficit** , supporting more informed and accurate DC-to-DC transfer decisions.

This tab is especially useful when reviewing the health of inventory across multiple sizes before approving or editing recommended transfers.

The metrics shown here are the same as the ones in the Choice-DC table except that here users can also see the excess/deficit status.

#### Excess/Deficit Tagging 

  * A **label tagged ‘Excess’ or ‘Deficit’** appears next to each DC:

    * **Excess** : The DC has more inventory than required and is a potential sender.

    * **Deficit** : The DC has less inventory than required and is a potential receiver.

  * This tag is determined based on current inventory, demand projections, and inventory policies (e.g., safety stock, minimum weeks of supply).




**Excess/Deficit Units**

  * Indicates how many units the DC has in excess or shortfall **for the specific size**

  * Positive values indicate **excess** , while negative values indicate **deficit**




Users will also see a toggle here to ‘Hide Non-Recommended Sizes’, users can see details for non-recommended sizes if they wish by flipping the toggle. 

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXfOs5lddfWtbAYXAcFFhmhqENB_oe4X7AfLqMW6UpXh-0QKrFGGG66GLyuW0G27Ywoe0iP5jSq82qaXvj3EGybMFsWzd6Lc3Fw9Poi8VaGCRI1-zpjIWYKVw7QjLrorExXGFreKyw?key=5V2TMS3BHRbeSg-6LFzEDIYP)

#### Review Recommendation

The **Review Recommendations** tab is the central workspace where users can review and act on system-generated transfer suggestions between eligible DCs. These recommendations are made at the **SKU (Size) - DC** level and aim to balance inventory by moving stock from surplus DCs to deficit DCs.

This screen is highly interactive and allows both **reviewing** and **manual editing** of transfer quantities, giving planners full control over the movement decisions.

#### UI/UX Functionality

Below is a detailed breakdown of the workflow and capabilities available on this screen:

  1. **Total Deficit and Excess Visibility**

     * At the top, users can view the **aggregate excess and deficit quantities** for the selected choice.

     * This data is broken down **further by individual sizes** , helping users identify where imbalances exist




![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXcWRnamNdvpPiVsUKmKw5AIdoyu7niJ23z6A7YVC0gcOxPLuYcsMpOlSvcJGLgcvVXfFcDP2kXAT_h_N_zFo9042jbLwSEtPEHk7teBZxc5YORp9dh7jhlLXTalKMnqP-1rZLFSzw?key=5V2TMS3BHRbeSg-6LFzEDIYP)

  2. **Editable Transfer Quantity**

     * The **'Transfer Units/Packs'** column is **editable** , allowing users to override the system-recommended transfer quantity. By default, it will be equal to the IA Recommended Transfer


![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXdac-e6AqUyMgKbLKIk9wFbpEyZvXiEmksEWXOtSvci_1cC6qs1Msmbg0Ri4CtPqA2HxIBADaXhLT7qAxZ6GHmn8VlFkzx_bpmTdGjVlksjwcW1C3rE_cjfyRNAvh9gz2bIZmePMg?key=5V2TMS3BHRbeSg-6LFzEDIYP)

  3. **Initial View: Recommended Sizes Only**

     * Upon opening, the screen displays **only those sizes** for which a transfer recommendation has been made by the system.

     * This helps focus user attention on the most critical stock movements.

  4. **Create Transfers for Non-Recommended Sizes**

     * Users can create transfers for other sizes (those without system recommendations) by clicking the **‘+’ button** at the top-right of the table.

     * A new row is added where users can define the transfer manually.




![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXcBRAqapPffi0qc88ZJ_fVQBBJWd5gxTBsXUSi32SikjzEhC4ln8Rp8Rj1h9TzV8WnXPmyWZOZdutlNkE7lo7mAYvRFTUjI37QNDyWjRarqShQX7U9Rg8nF0qkOV8TQZmiqq9qQ?key=5V2TMS3BHRbeSg-6LFzEDIYP)

  5. **Delete Manually Created Transfers**

     * Transfers created manually for non-recommended sizes can be **removed** by clicking the **bin icon** next to the row

     * Deletion will work only if the user has not **Saved** the transfer for the non-recommended sizes




![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXdmm-a4z7f1EKDi87HUlSLpS7x5AQiSBT42SVaN6DbJnWBgoxhlZhytWPT7M-mCDXKIDQjP0a8_qfY1JP7wC7_cfqIvu4v0EYN8qjdvlH97hm5cVefCaSErNEncIDiNPsY6kRh1xg?key=5V2TMS3BHRbeSg-6LFzEDIYP)

  6. **Manual Configuration of Source and Destination DCs**

     * For manually created transfers, users can **select the source and destination DCs** from a dropdown.

     * Upon selection, the relevant metrics for those DCs — including available quantity, service level, and forecast — will populate for reference.

     * Users can enter the desired transfer quantity and approve the transfer




  7. **Save to Apply Changes**

     * Once edits are made, clicking **‘Save’** will:

       * Lock in the modified or new transfer quantity.

       * Trigger recalculation of the **'After' metrics** (e.g., post-transfer units, WOS).

       * Saved transfers for Non-recommended sizes will be added to the list of recommended transfers

  8. **Approve Final Transfers**

     * After reviewing and validating all desired changes, users can finalize the transfer for all choices by clicking **‘Approve’**.

     * Note that clicking on Approve will release the transfer for all selected choices to the downstream and not just for the choice selected in the dropdown above




**Column Description (Landing Page):**

Sl No| Columns| Datatype| Definition / Formula  
---|---|---|---  
1| Choice| text| Choice ID (SKU)  
2| Choice Attributes| text| Product attributes and hierarchies for the choice  
3| DC| text| Distribution Center ID  
4| Total DC OH| numeric| Total DC OH across all the sizes having inventory for the choice-DC combination  
5| Demand Projection| numeric| This is the demand for the DC based on projected store allocations over the DC TWOS window  
6| Upcoming PO Units| numeric| # of OO units arriving to the DC from the closest arriving PO  
7| Upcoming PO Date| date| Delivery date of closest arriving PO  
8| DC TWOS| numeric| Target inventory coverage period for the choice - DC combination (average across sizes)  
9| Sales Forecast| numeric| Safety stock expressed in weeks of supply  
10| DC CWOS| numeric| Indicates how long current DC Inventory will last based on projected demand  
11| DC Min| numeric| Min Stock that should be present in the DC for that choice (agg. across sizes)  
12| Safety Stock| numeric| Safety Stock units that should be present in the DC to meet desired service levels  
  
**Column Description (Review Sizes):**

Sl No| Columns| Datatype| Definition / Formula  
---|---|---|---  
1| Size| text| Size Description  
2| Size Attributes| text| Product attributes: Product Code, Choice, Choice Description  
3| DC (tag)| text| Distribution Center ID with Excess/Deficit badging  
4| Excess/Deficit Units| numeric| Excess/Deficit units based on the DC tag. If the DC is excess then excess units will be displayed else deficit units are displayed here.   
5| Total DC OH| numeric| Total DC OH across all the sizes having inventory for the choice-DC combination  
6| Demand Projection| numeric| This is the projected store allocations constrained by the projected DC OH  
7| Upcoming PO Units| numeric| # of OO units arriving to the DC from the closest arriving PO  
8| Upcoming PO Date| date| Delivery date of closest arriving PO  
9| DC TWOS| numeric| Target inventory coverage period for the choice - DC combination (average across sizes)  
10| Sales Forecast| numeric| Projected store allocations over the store TWOS period accounting for Min and Max and projected Store OH  
11| DC CWOS| numeric| Indicates how long current DC Inventory will last based on projected demand  
12| DC Min| numeric| Min Stock that should be present in the DC for that choice (agg. across sizes)  
13| Safety Stock| numeric| Safety Stock units that should be present in the DC to meet desired service levels  
  
**Column Description (Review Recommendation):**

Sl No| Columns| Datatype| Definition / Formula  
---|---|---|---  
1| Choice| Text| Choice ID  
2| Size| Text| Size Description  
3| Total Deficit| Numeric| Deficit units agg across sizes  
4| Total Excess| Numeric| Excess units agg across sizes  
5| Source| Text| Source DC  
6| Destination| Text| Destincation DC  
7| Source DC Excess Units Total| Numeric| Excess units agg for the source DC  
8| Destination DC Deficit Units Total| Numeric| Deficit units agg for the destination DC  
9| IA Recommended Transfer| Numeric| IA Recommended Transfer  
10| Transfer Units/Packs| Numeric| User Editable Transfer Units  
11| Pending Deficit| Numeric| Remaining Deficit after transfer  
12| Remaining Excess| Numeric| Remaining Excess after transfer  
13| Before-Source OH| Numeric| Source DC OH before transfer  
14| Before - Destination OH| Numeric| Destincation DC OH before transfer  
15| Before-Source DC WOS| Numeric| Source DC WOS before transfer  
16| Before-Destination DC WOS| Numeric| Destination DC WOS before transfer  
17| After-Source OH| Numeric| Source DC OH after transfer  
18| After-Destination OH| Numeric| Destincation DC OH after transfer  
19| After-Source DC WOS| Numeric| Source DC WOS after transfer  
20| After-Destination DC WOS| Numeric| Destination DC WOS after transfer  
21| Source-Min| Numeric| Min Stock to be present in Source DC  
22| Source-Safety Stock| Numeric| Safety stock units to be maintained in Source DC  
23| Source-Demand Projection| Numeric| Demand projection of that size for the source DC  
24| Destination-Min| Numeric| Min Stock to be present in Destination DC  
25| Destination-Safety Stock| Numeric| Safety stock units to be maintained in Destination DC  
26| Destination-Demand Projection| Numeric| Demand projection of that size for the Destination DC  
27| Min Transfer Quantity| Numeric| Min Transfer units for IA to recommend a transfer in this direction  
28| Transfer Cost| Numeric| Transfer units * cost per unit  
  
**Issue Management for DC Transfer Constraints and Service Levels**

**Issue Priority**| **Issue Priority Description**| **Examples of Potential Issues**  
---|---|---  
P0(Emergency)| Any emergency condition that makes use of key parts of the system impossible or is significantly impaired. It requires immediate attention.| The page does not load, checkboxes dont work, ‘Review Recommendation and Sizes’ does not work  
P1(Urgent)| Any condition (excluding P0 issues) that makes use of any parts of the system difficult that the user cannot reasonably circumvent.| Filters are not sticking, cannot create transfers for non-recommended sizes. Toggle for hiding non-recommended sizes does not work  
P2(Normal)| Any condition (excluding P0 & P1 issues) that leads to parts of the system not working as expected but doesn’t impair regular processes for the users.| Increased screen loading time  
P3(Low)| Any condition (excluding P0, P1, and P2 issues) that causes minor inconvenience in using the system but does not impair regular processes.| Incorrect placement of a buttonIncorrect column header name

