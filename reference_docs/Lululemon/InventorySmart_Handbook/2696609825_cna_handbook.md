# CNA Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696609825` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:01.871Z |
| Last mirrored | 2026-05-21 |

---

| **Update Date** | **Updated By** | **Description** |
| --- | --- | --- |
| <custom data-type="date" data-id="id-0">11/20/2025</custom> | <custom data-type="mention" data-id="id-1">@Navin Chandan</custom>  | Updated the screenshot Consistencies in choice / article naming Fixed Push update as per current logic |

## Table of Contents

## **Purpose**

This document encompasses information and details related to Create New Allocation (CNA). We will cover various parameters used in the CNA flow, and will also go into the math behind how certain metrics are calculated. This will serve as a ready reckoner for anyone getting started with CNA.

## **Overview**

The core value of InventorySmart is realized through automated DC-Store Inventory recommendations. The recommendations are based on the demand forecast from our in-house demand forecasting models - which leverage the pinnacle of artificial intelligence and machine learning. It will also factor in constraints such as min, max, etc. as well as different allocation strategies configured by the user.

## **Manual Allocation Flow- Configuring Inputs**

### **Details Table:**

Users can start the allocation process by applying filters. After selecting filters, the system shows **Eligible Style-Color** with **Current ATA > 0** in the Details Table, including key inventory metrics and some editable fields.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=fea6fa27-f82b-4d15-bbe0-b53337166d68&id=61f5d940-eb03-4041-bb98-3b7bd426b9fc&&collection=contentId-2696609825&height=785&occurrenceKey=null&width=1821&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
\*\* Added screenshots for Victoria’s Secret, where “Choice” corresponds to Style-Color. Throughout this document we have tried to use Style Color. In some places instead of Style-Color, we might be using Choice, Article or Styles. The backend column name is article.

#### **Behind the scenes - Eligibility Calculation**

This section explains how the eligibility for allocation is created from the input feeds:

The eligibility base is created using valid SKU-Store-DC combinations for each Style-Color in the Details Table. Metrics are calculated by considering and aggregating only the eligible SKU-Store-DC combinations for that Style-Color. 

For the products that the user has selected in the overhead filters - we join the following four tables to create the eligibility base:

1. **Product-Store Mapping:** Contains eligible SKU-Store combinations.

For Style-Color='**111734583MQ4**'

| **SKU** | **Size** | **Store Code** |
| --- | --- | --- |
| 26940340 | LARGE | 0001 |
| 26940479 | XL | 0001 |
| 26937767 | SMALL | 0001 |
| 26940340 | LARGE | 0005 |
| 26940479 | XL | 0005 |
| 26937767 | SMALL | 0005 |
| 26940340 | LARGE | 0006 |
| 26940479 | XL | 0006 |
| 26937767 | SMALL | 0006 |

2. **Store-DC Mapping:** Contains eligible Store-DC combinations.

| **Store Code** | **DC Code** |
| --- | --- |
| 0001 | S015 |
| 0005 | S015 |
| 0001 | S003 |

3. **Product-DC Mapping:** Contains eligible SKU-DC combinations.

| **SKU** | **Size** | **DC Code** |
| --- | --- | --- |
| 26940340 | LARGE | S003 |
| 26940340 | LARGE | S015 |
| 26940479 | XL | S015 |

4. **SKU-DC Inventory:** Contains DC inventory at the SKU-DC level.

| **SKU** | **Size** | **DC Code** | **DC OH** |
| --- | --- | --- | --- |
| 26940340 | LARGE | S015 | 50 |
| 26940479 | XL | S015 | 0 |
| 26937767 | SMALL | S015 | 60 |
| 26940340 | LARGE | S003 | 40 |

5. **Final Eligibility Base**

| **SKU** | **Size** | **Store Code** | **DC Code** |
| --- | --- | --- | --- |
| 26940340 | LARGE | 0001 | S015 |
| 26940340 | LARGE | 0005 | S015 |
| 26940340 | LARGE | 0001 | S003 |

Note: The final eligibility base will also be a function of the store group. In the case of the ‘Default’ store group, the final eligibility will be the same as in the table above. In case any other store group is selected in the Details table, the above eligibility table will be filtered to show the intersection.

**Explanation:**

The Product-Store, Store-DC, Product-DC, and SKU-DC Inventory tables were joined.

1. Only SKUs with DC OH > 0 were included.
2. **SKU** 26937767 (Size SMALL) was excluded because it is not in the Product-DC Mapping table.
3. **SKU** 26940479 (Size XL) was excluded because its DC OH is 0 in the SKU-DC Inventory table.
4. Store Code 0006 was excluded because it is not in the Store-DC Mapping table.

#### **Metrics and Calculation:**

1. **Last Allocated:** Shows the last allocation date for the Style-Color. For Style-Colors with no prior allocations, the value will be “-”
2. **Demand Type:** This is an editable field where users can choose from three demand type options:

    a. **IA Forecast -** Final Forecast flowing from ADA Visual. Can be Adjusted IA Forecast or MFP depending on user selection  
      
    b. **APS -** Stands for  ‘average per store’. When APS is selected as the Demand Type,  the planned APS number is to be entered by the user in the 'Planned APS' column. The demand for each store will be calculated using the Planned APS value and the overall proportion flowing from the product profile (user created or ia-recommended whichever is selected).  
      
    c. **Fixed -** Units or percentage of inventory to push out from the DC. If a user attempts to enter a unit or percentage value where the Fixed Quantity to Allocate (FQTA) exceeds the Current Available to Allocate (CATA), the system prevents the FQTA from surpassing the CATA. In such cases, the FQTA is automatically adjusted to match the CATA value.


3. In the CNA Details Table, the demand type is fetched from the **highest-priority rule i**n the DC-Store Policy for that particular Style-Color. Users can adjust the demand type in the CNA Details table if needed.

The **highest-priority rule** is the most granular rule defined for the product. For example a rule defined at the SKU level will be higher priority compared to rule defined at the subclass level. This will apply to all parameters that are

If no rule other than the default rule is present in DC-Store Strategy for the Style-Color, the demand type will depend upon the status tag of the Style Color from `article_status_tag`. If the Style-Color is in Clearance then the Demand type will default to Fixed else it will be fetched from the default rule set at the l0 or l1 level, where the demand type is set to **"IA Forecast"** by default.

4. **Product Profile:** A **Product Profile** in InventorySmart outlines the size-to-store contribution (summing to 100% per store) and the overall proportion (summing to 100% across all stores for a Style-Color).   
    
  The Product Profile is fetched from the highest-priority rule in the DC-Store Policy for that particular Style-Color. Users will see values in the product profile dropdown only if the user-created product profile was attached for that Style-Color (through a rule) in the DC-Store-Policy. Otherwise, only IA Recommended will be visible and considered for the manual allocation.

If no rule other than the default rule is created for a specific Style-Color, the product profile will be fetched from the default rule set at the l0 or l1 level, where the product profile is set to **"IA Recommended"** by default.

5. **Store Eligibility Groups:** This field is user-editable. Initially, the column is populated with the store group attached to the highest-priority rule in the DC Store Policy for the particular Style-Color.

    The user has the option to select other store groups from the list.



* If no rule other than the default rule has been created for a particular Style-Color, the store eligibility groups will be fetched from the default rule at the l0 or l1 level, where the **"Default"** store group will be considered. The default store groups will include all active stores in the given region or country or channel.
* Based on the selected store groups, the list of stores will be inner-joined with the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), and the number of eligible stores will be updated accordingly.

6. **Prioritization Strategy:** Determines how the demand is distributed. This is an editable field where users can select one of two prioritization strategies. This works in tandem with the allocation strategy to determine the overall allocation process:

**a. IA Priority  -** Stores are ordered based on higher Demand / ROS >  higher Tier >  lower Store OH, the top store is allocated the entire demand component first, then the second, and so on. In the case of a constrained situation, it is possible that stores in the bottom order do not receive any allocations.  
**b. Fair Share -** Demand component is used to calculate store level proportions. In case of a constrained inventory situation, all stores receive a share of the available inventory.

In the CNA Details Table, the prioritization strategy is pulled from the highest-priority rule in the DC-Store Policy for that specific Style-Color.

* If no rule other than the default rule has been created for a particular Style-Color, the Prioritization Strategy will be fetched from the default rule at the l0 or l1 level, where the Prioritization Strategy is set to **"IA Priority"**.

7. **Allocation Strategy:** This is an editable field where users can select one of three Allocation Strategies:

**a. Mins First and then WOS -** The optimizer will allocate Mins first across all stores. The remaining inventory will be considered to allocate the demand portion  
**b. Mins Only -** The optimizer only allocates Mins, demand is not considered. This is also a proxy for WOS = 0 allocations  
**c. WOS Only -** The entire inventory is considered to fulfill the demand, ignoring mins but respecting the max  
  
In the CNA Details Table, the Allocation Strategy is fetched from the highest-priority rule in the DC-Store Policy for that specific Style-Color.

If no rule other than the default rule has been created for a particular Style-Color, the Allocation Strategy will be fetched from the default rule at the l0 or l1 level, where the Allocation Strategy is set to **"Mins First and then WOS"**.

8. **Planned APS:** This is a user input field that becomes editable only when the demand type is set to **"APS."**  If any other demand type is selected, the field will be greyed out and will not accept any input, The planned APS number in tandem with the overall proportion will determine the demand for each store.
9. **Size Profile:** This column will display a list of all eligible sizes identified in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation). Considering the above example for the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), only "LARGE" will be displayed in this column, as it is the only size in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation).

The user can deselect sizes from the list of eligible sizes for allocation. When a size is deselected,  it will not get allocated. Other metrics, such as the DC inventory on hand, allocated quantity, reserve quantity at DC, and allocation reserve quantity, will be updated in real-time on the tool.

10. **Target WOS:** 

    1. **User Sets Constraints at Rule and Tier Level**: The user sets constraints at the Product Rule and defined Store Attribute level in the constraints screen.  
    
        ![](blob:https://media.staging.atl-paas.net/?type=file&localId=95b12722-105a-43f1-88d0-28ea34a01a81&id=5b8eabd6-f22a-4af9-8457-de116da3e103&&collection=contentId-2696609825&height=774&occurrenceKey=null&width=1814&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
    
        

    
    2. **Resolving Constraints at SKU-Store Level (Real Time)**: For each SKU-Store combination, the system checks all rule and tier combinations and selects the highest-priority rule to fetch the constraints (WOS) from that rule and tier.
    3. **Fetching Constraints from Resolved Constraints Table (Real Time)**: For the eligible SKU-Store combinations associated with a particular Style-Color, the system fetches the constraints (WOS) from the resolved constraints table at the SKU-store level.
    4. **Aggregating Constraints at Style-Color Level**: Once the constraints are retrieved, they are aggregated by calculating the average WOS at the Style-Color level.
    

    **Example:**

For the eligible SKU-Store combinations in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), let's consider the following example of WOS for each combination:

| **Style-Color** | **SKU** | **Size** | **Store Code** | **WOS** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | 0001 | 6 |
| 111734583MQ4 | 26940340 | LARGE | 0005 | 8 |

So the **Target WOS** will be calculated as:

(6+8) / 2 = **7**

This aggregated WOS value would then be displayed in the CNA Details Strategy screen against the Style-Color='111734583MQ4'. 

Note: This average WOS number is only for representation purposes. The actual metric used during the allocation workflow, will be at the size-store level.

11. **Beginning Available to Allocate:**  
  This metric represents the available DC On-Hand (DC OH) inventory for a particular Style-Color at the beginning of the day and remains constant throughout the day.  
  The value is fetched from the inventory table at the Size-DC level.  
  **To calculate this metric:**

    1. Only eligible SKU-DC combinations from the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation) are considered.
    2. The DC OH values for these eligible SKU-DC combinations are aggregated to determine the total DC OH for the Style-Color.
    

This aggregated value is displayed as the **Beginning Available to Allocate** metric in the CNA Details Table.

**Example:**  
For the eligible SKU-DC combinations in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), consider the following values of DC OH available at the beginning of the day for each combination:

| **Style-Color** | **SKU** | **Size** | **DC Code** | **DC OH** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | S015 | 50 |
| 111734583MQ4 | 26940340 | LARGE | S003 | 40 |

So the Beginning Available to Allocate is calculated as:

(50+40) =**90**

This aggregated **Beginning Available to Allocate** value would then be displayed in the CNA Details Strategy screen against the Style-Color='111734583MQ4'.

‌

12. **DC:** This column will display a list of all eligible DCs identified in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation). Considering the above example for the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), **S015** and **S003** will be displayed in this column.

The user can deselect DCs from this list. When a DC is deselected, other metrics, such as the DC inventory on hand, allocated quantity, reserve quantity at DC, and allocation reserve quantity, will be updated in real time on the tool. The number of eligible stores will be updated based on the updated DC list, may not update in this table in real time, but the allocations will be based on the updated store list.

13. **No. Eligible Stores:** This column displays the number of eligible stores identified in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation). Based on the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation) example we created, there are two eligible stores, so the value "2" will be displayed in this column.

The number of eligible stores is influenced by the selected Store Eligibility Groups. Also to note, If a size or DC is deselected, the number of eligible stores will be updated in the allocation recommendation, but will not reflect in the metric in the table here real time.

14. **DC Inv On Hand:** This metric represents the available DC On-Hand (DC OH) inventory for a specific Style-Color at a given time. If there is a delta feed or cyclic feed setup, then it will update with that frequency. The value is fetched from the SKU-DC Available Inventory table at the SKU-DC level.  
  **Calculation Process:**

    1. Only eligible SKU-DC combinations from the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation) are considered.
    2. The DC OH values for these eligible SKU-DC combinations are aggregated to determine the total DC OH for the Style-Color.
    

The aggregated value is displayed as the **DC Inv On Hand** metric in the CNA Details Table.

**Example:**  
For the eligible SKU-DC combinations in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), consider the following values of DC OH available.

| **Style-Color** | **SKU** | **Size** | **DC Code** | **DC OH** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | S015 | 30 |
| 111734583MQ4 | 26940340 | LARGE | S003 | 20 |

So the DC Inv On Hand is calculated as:

(30+20) =**50**

This aggregated **DC Inv On Hand** value would then be displayed in the CNA Details Strategy screen for the Style-Color='111734583MQ4'.

15. **Allocated Qty:** 

    1. Allocated Qty is calculated at Style-Color-SKU-Store Level for the eligible combinations.
    2. It is then aggregated at the Style-Color level and displayed in the **CNA Details Table.**
    3. If units have been previously allocated for a specific Style-Color on a particular day, the corresponding values are updated in this column for that day. At the beginning of the next day, the allocated quantity is purged, meaning it is cleared and reset to 0.
    

**Example**: For the eligible SKU-Store combinations in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), consider the following values of allocated qty.

| **Style-Color** | **SKU** | **Size** | **Store Code** | **Allocated Qty** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | 0001 | 5 |
| 111734583MQ4 | 26940340 | LARGE | 0005 | 3 |

So Allocated Qty is calculated as (5+3)=**8**  
  
This aggregated **Allocated Qty** value would then be displayed in the CNA Details Strategy screen for the Style-Color='111734583MQ4'.

16. **Reserve Qty At DC:** 

    1. Users can set the **Reserved Qty** at the **SKU/Pack-DC** level in the **DC Reserve Screen** within the **Constraints Module.**  
    
        ![](blob:https://media.staging.atl-paas.net/?type=file&localId=ba3364d8-e45a-4bf5-9e46-f07f36681b4e&id=36a262f9-6687-4e70-a008-57b27358bea3&&collection=contentId-2696609825&height=722&occurrenceKey=null&width=1820&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
    
        

    
    2. For eligible **SKU/Pack-DC** combinations, the system aggregates the reserved quantities at the Style-Color level.
    3. This aggregated value is then displayed in the **CNA Details Table.**
    

**Example:** 

For the eligible SKU/Pack-DC combinations in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), consider the following values of Reserve Qty.

| **Style-Color** | **SKU** | **Size** | **DC Code** | **Reserve Qty** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | S015 | 2 |
| 111734583MQ4 | 26940340 | LARGE | S003 | 3 |

So the **Reserve Qty At DC** is calculated as:

(3+2) =**5**

This aggregated **Reserve Qty At DC** value would then be displayed in the CNA Details Strategy screen for the Style-Color='111734583MQ4'.  
  
Note: For Pack Inventory, the DC reserve should also be maintained at Pack level.

17. **Allocation Reserve Quantity:**

    1. This Allocation Reserve Quantity is stored in a table at the SKU/Pack-DC level for the current date.
    2. For eligible **SKU/Pack-DC** combinations, the system aggregates the Allocation Reserve Quantity at the Style-Color level.
    3. This aggregated value is then displayed in the **CNA Details Table.**
    

**Example:**  
For the eligible SKU/Pack-DC combinations in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), consider the following values of Allocation Reserve Qty.

| **Style-Color** | **SKU** | **Size** | **DC Code** | **Allocation Reserve Qty** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | S015 | 4 |
| 111734583MQ4 | 26940340 | LARGE | S003 | 4 |

So the **Allocation Reserve Qty** is calculated as:

(4+4) =**8**

This aggregated **Allocation Reserve Qty** value would then be displayed in the CNA Details Strategy screen for the Style-Color='111734583MQ4'.

18. **Current Available to Allocate:**

    1. The **Current Available to Allocate** metric is calculated by subtracting **Reserve Qty at DC** and **Allocation Reserve** from **DC Inv On Hand** at the **SKU-DC level**.   
      **Current Available to Allocate** = **DC Inv On Hand** - **Reserve Qty at DC** - **Allocation Reserve** **Quantity - New Store Reserve.**
    2. It is then aggregated at the Style-Color **level**. 
    3. This aggregated value is displayed in the **CNA Details Table**. 
    

**Example:** For the eligible SKU-DC combinations in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation), consider the following values of the metrics.

| **Style-Color** | **SKU** | **Size** | **DC Code** | **DC Inv On Hand** | **Reserve Qty** | **Allocation Reserve Qty** |
| --- | --- | --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | S015 | 30 | 2 | 4 |
| 111734583MQ4 | 26940340 | LARGE | S003 | 20 | 3 | 4 |

So the **Current Available to Allocate** is calculated as:

{(30-2-4)+(20-3-4)} =**24+13=37.**  
This aggregated **Current Available to Allocate** value would then be displayed in the CNA Details Strategy screen for the Style-Color='111734583MQ4'.

19. **LW SLS U, L4W AVG SLS U, Discount Percentage, AUR (Optional):**  
  These metrics are available at the Style-Color level in the Details Table of the Decision Dashboard and are fetched directly from there.

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=84ba9234-8208-448d-b4b8-65ed3aa2522e&id=61cf2075-fab3-4ac3-8f3a-8b02f8e58c7f&&collection=contentId-2696609825&height=543&occurrenceKey=null&width=1829&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)

    The above screenshots show the metrics mentioned earlier in the Decision Dashboard >> Details Table.


20. **User Defined Inv. in %, Fix Inv Push, Fixed Qty to Allocate:**  
  These metrics are populated when the user selects "Fixed" as the demand type. For other demand types, the fields will be grayed out.

    1. **User Defined Inv. in %**: This is a user-editable field where the user can input the percentage of the current available-to-allocate inventory they want to allocate.
    2. **Fix Inv Push**: In this field, the user can specify the amount of inventory they wish to allocate.
    3. **Fixed Qty to Allocate**: This value is calculated based on the user's input. If "User Defined Inv. in %" is used, the Fixed Qty to Allocate is calculated as `User Defined Inv. in % * Current Available to Allocate`. If "Fix Inv Push" is used, the Fixed Qty to Allocate will be updated with the exact value entered by the user.
    
21. **Inner Pack Units (Case Pack or UOM):**  
  This is a product attribute that is populated from the product_master. The allocation recommendation will be in multiples of the inner pack units. More details are mentioned in the '[Case Pack Rounding](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Case-Pack-Rounding%3A)' section.  

---

### **Review Store and DC:**

After selecting a Style-Color or list of Style-Colors from the Details Table, the user can click on **Review Store and DC** to access the **Store Details** and **Inv. Source** tables for the selected Style-Colors.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=45327859-418a-43c5-9761-25466314aa69&id=ee528efb-7f3a-4bb5-a9bd-5da2b635e37d&&collection=contentId-2696609825&height=896&occurrenceKey=null&width=1824&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
#### **Tabs in Review Store and DC Screen:**

#### **a. Store Details:** 

The **Store Details** tab displays key metrics for each eligible store. Users can adjust allocation constraints through editable fields like **Min**, **Max**, and **WOS**. Only eligible stores identified from the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation) are displayed in this tab.

**Metrics and Calculations:**

1. **Size to Overall Store Contribution %:** This metric represents the size contributions for a particular store, expressed as a percentage. The total size contribution for a store will always add up to 100% across all eligible sizes. These contributions are derived from the product profile associated with that Style-Color in the details table.
2. **Overall Proportion(%):** This metric represents the store contribution for a particular Style-Color, expressed as a percentage. The total store contribution for the selected Style-Color will always sum to 100% across all eligible stores. These contributions are derived from the product profile linked to the Style-Color in the details table.
3. **APS/User-Defined ROS:**  
  **a.** **For APS Demand Type(APS):** This metric is calculated based on the APS value selected at the Style-Color level in the details table. The Style-Color level APS value is distributed across all eligible stores so that the average APS across these stores matches the value selected in the details table. The distribution follows the overall proportion (%) displayed in the Review Store and DC tab.  
  _Reminder: APS stands for Average-Per-Store, understood as the average # of units to push for each store, in that allocation._  
  **Example:**   
  Assume the user has set an APS value of **5** in the Details Table for **Style-Color='111734583MQ4'**. Assume, in the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation) there are two eligible stores. The Total APS value will be distributed across these stores based on their overall proportion (%).  
  The calculation is as follows:  
  _Total APS Value = APS Value x No. of Eligible Stores_  
  Here, _Total APS Value = 5\*2 =**10**_  
  _Store APS=Overall Proportion×Total APS Value_

| **Store Code** | **Overall Proportion(%)** | **APS**  |
| --- | --- | --- |
| 0001 | 0.3 | 0.3 X 10 = 3 |
| 0005 | 0.7 | 0.7 X 10 = 7 |

Thus, **Store 0001** gets an APS of **3**, and **Store 0005** gets an APS of **7**. This ensures that the average APS across the two stores is **5**, maintaining the value entered in the Details Table.

Although the APS is represented at the store level here, In the allocation workflow, the APS value is considered at the SKU-Store level. It is broken down to SKU level using the proportions from the attached product profile.

  
**b.** **For Fixed and IA Forecast Demand Type(User-Defined ROS):** This metric is the average forecast per week.  
_ROS=Demand Over WOS / WOS _  
This section outlines how Demand Over WOS is calculated:

**Demand Over WOS Calculation:**

**i. Date Calculation**:

**a. Start Ship Date**: (DC to Store Ship Date)

The Start Ship Date is set as _Current Date + 1_.

If _Current Date + 1_ falls on a Saturday or Sunday, the Start Ship Date is adjusted to the following Monday.  
This logic applies only to **DC allocations**. For **PO allocations**, the Start Ship Date depends on the PO receival date.  
The logic can also be customized based on specific business requirements.

**b. Start Date of Demand Period**: Start Ship Date + Lead/Transit Time + 1

**c. Start Week of Demand Period**: 

The week corresponding to the Start Date of the Demand Period.

If the Start Date falls in the first half of the week, the same week is considered.  
If the Start Date falls in the second half of the week, the following week is selected.

**d. End Date of Demand Period**: Start Date of Demand Period + (WOS × 7 days) - 1

**e. End Week of Demand Period**: Start Week of Demand Period + WOS - 1

**ii. Demand Calculation**:

The system aggregates the demand from the Start Date/Week to the End Date/Week to determine Demand Over WOS.

**Example:**  
Consider the following eligibility scenario.  
**SKU-Store Level Forecast:**

| **Style-Color** | **SKU** | **Size** | **Store Code** | **Demand Over WOS** | **WOS** |
| --- | --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | 0001 | 30 | 5 |
| 111734583MQ4 | 26940340 | LARGE | 0005 | 45 | 5 |
| 111734583MQ4 | 26937767 | SMALL | 0001 | 20 | 5 |
| 111734583MQ4 | 26937767 | SMALL | 0005 | 15 | 5 |

**Aggregated Data (Style-Color-Store Level):**

| **Style-Color** | **Store Code** | **Demand Over WOS** | **WOS** | **ROS** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 0001 | 50 | 5 | 50/5 = 10 |
| 111734583MQ4 | 0005 | 60 | 5 | 60/5 = 12 |

Thus, the ROS values for stores **0001** and **0005** are **10** and **12**, respectively.

4. **Min, Max, and WOS:** These constraints are displayed at the store level for a particular Style-Color. Constraints are first calculated at the SKU-Store level and then aggregated(average) at the Style-Color-Store level to be shown in the "Review Store and DC" screen.

    The calculation of constraints follows the same approach as explained in the calculation of Target WOS in the Details Table.   
    **Example:**  
    Below is a detailed example to illustrate the process. The calculation for Min, Max, and WOS is done by averaging the values from the SKU-Store level to the Style-Color-Store level.



     **SKU-Store Level Constraints:**

| **Style-Color** | **SKU** | **Size** | **Store Code** | **Min** | **Max** | **WOS** |
| --- | --- | --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | 0001 | 4 | 500 | 5 |
| 111734583MQ4 | 26937767 | SMALL | 0001 | 2 | 300 | 7 |
| 111734583MQ4 | 26937767 | SMALL | 0005 | 3 | 400 | 8 |
| 111734583MQ4 | 26940340 | LARGE | 0005 | 1 | 600 | 6 |

    **Aggregated Data (Style-Color-Store Level):**

| **Style-Color** | **Store Code** | **Min** | **Max** | **WOS** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 0001 | (4+2)/2 = **3** | (500+300)/2 = **400** | (5+7)/2 = **6** |
| 111734583MQ4 | 0005 | (3+1)/2 = **2** | (400+600)/2 = **500** | (8+6)/2 = **7** |

If a user edits the constraints (min, max, WOS) at the Style-Color-Store level in the Review Store and DC section, the updated values will apply to all eligible sizes for that Style-Color in that store.

For example, if a Style-Color has three sizes: XS, SMALL, and MEDIUM, and the user sets **min = 5** for store **0001**, the same **min = 5** will be applied to all three sizes in that store.

5. **Transit Time:** Transit Time is provided in the data feed at the Store and DC levels. If a store is mapped to multiple DCs in the eligibility data, the transit time displayed for that store is the maximum transit time among the mapped DCs.  
  **Example:**  
  Consider the following data where a store is mapped to two different DCs:

| **Store Code** | **DC Code** | **Transit Time (Days)** |
| --- | --- | --- |
| 0001 | S015 | 9 |
| 0001 | S003 | 11 |

In this case, the transit time shown for Store `0001` in the "Review Store and DC" screen will be **11**, with the maximum value between **9** and **11**.

6. **Store On Hand, Store In Transit, Store On Order, Store OH+OO+IT:** These metrics are derived from the inventory feed of the latest date, where inventory details are provided at the **SKU-Store** level. In the Review Store and DC screen, these metrics are aggregated and displayed at the **Style-Color-Store** level based on eligible SKU-Store combinations from the eligibility file.  
  **Example:**  
  Consider the following eligible SKU-Store combinations from the eligibility file, along with their corresponding inventory metrics:  
    
  **SKU-Store Level Inventory Metrics:**

| **Style-Color** | **SKU** | **Size** | **Store Code** | **Store OH** |  **Store OO** | **Store IT** | **Store OH+OO+IT** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | 0001 | 5 | 2 | 0 | 7 |
| 111734583MQ4 | 26937767 | SMALL | 0001 | 8 | 2 | 1 | 11 |
| 111734583MQ4 | 26937767 | SMALL | 0005 | 7 | 1 | 1 | 9 |
| 111734583MQ4 | 26940340 | LARGE | 0005 | 3 | 1 | 0 | 4 |

     **Aggregated Data (Style-Color-Store Level):**

| **Style-Color** | **Store Code** | **Store OH** | **Store OO** | **Store IT** | **Store OH+OO+IT** |
| --- | --- | --- | --- | --- | --- |
| 111734583MQ4 | 0001 | 13 | 4 | 1 | 18 |
| 111734583MQ4 | 0005 | 10 | 2 | 1 | 13 |

In the Review Store and DC screen, the aggregated inventory metrics for stores **0001** and **0005** will be displayed as shown in the table above.

7. **Estimated Demand:** This metric is first calculated at the **SKU-Store** level and then aggregated to the **Style-Color-Store** level. The calculation of **Demand Over WOS** follows the same logic as explained in the APS/User-Defined ROS calculation.  
  _Estimated Demand=max(min(max(Demand Over WOS,Min_stock),Max_stock)−(Store OH+OO+IT),0)_  
  **Example:**  
  Consider the following eligible SKU-Store combinations from the eligibility file, along with their corresponding metrics:

    **SKU-Store Level :**



| **Style-Color** | **Size** | **Store Code** | **Demand Over WOS** | **Min**  | **Max** | **Store OH+OO+IT** | **Estimated Demand** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 111734583MQ4 | LARGE | 0001 | 17 | 1 | 999 | 7 | 10 |
| 111734583MQ4 | SMALL | 0001 | 21 | 1 | 999 | 11 | 10 |
| 111734583MQ4 | SMALL | 0005 | 29 | 1 | 999 | 9 | 20 |
| 111734583MQ4 | LARGE | 0005 | 24 | 1 | 999 | 4 | 20 |

     **Aggregated Data (Style-Color-Store Level):**

| **Style-Color** | **Store Code** | **Estimated Demand** |
| --- | --- | --- |
| 111734583MQ4 | 0001 | 20 |
| 111734583MQ4 | 0005 | 40 |

In this example, the estimated demand for each store is calculated at the SKU-Store level and aggregated by summing values at the Style-Color-Store level, as shown above.

#### **b. Inv. Source:** 

The Inv Source tab provides a detailed view of key inventory metrics for each eligible DC. Users can monitor Available Inventory, Reserved Quantities, and Allocated Units for each eligible size.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=29cb581d-b6ba-4274-bfa7-aba457100126&id=1c599dbb-5529-4467-960c-63921b35d220&&collection=contentId-2696609825&height=581&occurrenceKey=null&width=1822&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
**Metrics and Calculations:**

1. **Available Inventory:** This metric indicates the available DC On-Hand (DC OH) inventory for a specific Size-DC combination before subtracting the reserves and allocated units. This metric gets updated with every cyclic feed (if applicable) we receive.  
  **Example:**  
  Consider the following eligible SKU-DC combinations from the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation). The corresponding DC OH values are displayed on the screen for DC S015 across sizes:

| **Style-Color** | **SKU** | **Size** | **DC Code** | **DC OH** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | S015 | 30 |
| 111734583MQ4 | 26937767 | SMALL | S015 | 20  
 |
| 111734583MQ4 | 26940479 | XL | S015 | 10 |

2. **Reserved Quantity:** The Reserved Quantity metric indicates the quantity reserved for a specific **Size-DC** combination. Users can set the reserved quantity at the **SKU-DC** level through the **DC Reserve Screen** within the **Constraints** Module. These reserved quantities are stored in the backend table at the SKU -DC level.  

    For eligible SKU-DC combinations under a specific Style-Color, the system displays the reserved quantity at the DC level across sizes.  
    **Example:**  
    Consider the following eligible SKU-DC combinations from the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation). The corresponding Reserved Quantity values are displayed on the screen for DC S015 across sizes:



| **Style-Color** | **SKU** | **Size** | **DC Code** | **Reserve Quantity** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | S015 | 1 |
| 111734583MQ4 | 26937767 | SMALL | S015 | 1 |
| 111734583MQ4 | 26940479 | XL | S015 | 1 |

3. **Allocated Units:** The **Allocated Units** metric represents the number of units previously allocated for a specific SKU-DC combination on the current day. For eligible SKU-DC combinations under a specific Style-Color, the system displays the allocated quantity at the DC level across sizes.  
  **Example:**  
  Consider the following eligible SKU-DC combinations from the [eligibility base](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Behind-the-scenes---Eligibility-Calculation) The corresponding Allocated Quantity values are displayed on the screen for DC S015 across sizes:

| **Style-Color** | **SKU** | **Size** | **DC Code** | **Allocated Units** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | 26940340 | LARGE | S015 | 7 |
| 111734583MQ4 | 26937767 | SMALL | S015 | 18 |
| 111734583MQ4 | 26940479 | XL | S015 | 34 |

---

## **Recommendation Screen:**

In the Recommendation screen of the CNA flow, users can view and edit the allocated quantity and finalize the allocation plan. The screen includes Product View and Store View, enabling users to review the allocated units and the remaining DC availability by size.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=7ef840d5-0343-4491-becb-d52c1e8e14af&id=0c4f7275-aa57-49b4-b5ca-075d4e632749&&collection=contentId-2696609825&height=652&occurrenceKey=null&width=1820&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
First, we explain how the allocated quantity is determined at the SKU-Store-DC level and then describe how this information populates the different views in the Recommendation screen.

For this explanation, we consider the following strategies (Defaults):

* **Prioritization Strategy:** IA Priority
* **Allocation Strategy:** Min First, then WOS
* **Demand Type:** IA Forecast

### **Allocated Quantity Determination at SKU-Store-DC Level**

#### **Step-by-Step Allocation Process:**

![](blob:https://media.staging.atl-paas.net/?type=file&localId=2cd6784b-e66b-4827-89d4-6357e97b724d&id=d70910bb-1bbc-47d1-8f57-0066bc6e525e&&collection=contentId-2696609825&height=525&occurrenceKey=null&width=1414&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
**Step 1: Updated Store Inventory Position Calculation:** The system updates the **starting store inventory position** by factoring in projected sales during the Lead Time Period and any allocated units on the current date(past allocated units). It subtracts the projected sales and then adds the past allocated units (from current date) to determine the **starting store inventory position**.

1. **Initial Store Inventory Position Calculation:**  
  The initial store inventory position is calculated as:  
  Updated Store OH+ IT+ OO = Store OH+ IT+ OO + past_allocated_units - lt_forecast
2. **Adjustment Based on Demand Type:**

    * If the demand_type is 'Fixed', there is no change, and the Updated Store OH+ OO+ IT remains the same.
    * For IA Recommend and APS, the Updated Store OH+ OO+ IT is adjusted using the formula:  
      Updated Store OH+ OO+ IT**= max(**Updated Store OH+ OO+ IT**-** lt_forecast**,** 0**)**
    

Note:

Updated Store OH + IT + OO indicates the estimated inventory position as of the store receival date for the allocation.  
past_allocated_units accounts for any new inventory allocated to the store after the data refresh through ingestion. This includes any finalized or Order Batching allocations made post the latest inventory position update.  
lt_forecast refers to the Lead Time Forecast - the projected demand from the date of allocation up to the store receival date. It helps adjust for the inventory currently available in stores that is expected to deplete before the new allocation arrives.

This approach ensures that previous allocations and anticipated demands are factored into the Store Inventory Position calculation.  
**Example:**   
Consider the following eligible SKU-Store combinations where the calculation is performed, with demand_type='IA'.

Style-Color = '111734583MQ4', Size = 'LARGE'  
The Updated Store OH+ IT+ OO is calculated using the formula:  
**Updated Store OH+ IT+ OO = Store OH + Store IT + Store OO + Past Allocated Units - Lead Time Forecast**  

| **Store Code** | **Store OH** | **Store IT** | **Store OO**  | **Past Allocated Units** | **Lead Time Forecast** | **Updated Store OH+ IT+ OO** |
| --- | --- | --- | --- | --- | --- | --- |
| 0001 | 20 | 5 | 0 | 10 | 4 | 31 |
| 0005 | 30 | 0 | 3 | 15 | 5 | 43 |
| 0009 | 5 | 2 | 2 | 0 | 6 | 3 |
| 0011 | 10 | 0 | 0 | 0 | 10 | 0 |

**Step 2: Store Prioritization: Calculation of Updated ROS:** The Updated ROS is used to prioritize stores in the allocation process.

1. **Calculate ROS (Rate of Sale):**

    1. **Formula**: ROS = Sum(Demand Over WOS at Size-Store level) / WOS
    

 **Example:** Consider the following eligible SKU-Store combinations 

 Style-Color = '111734583MQ4', Size = 'LARGE'

| **Store** | **Demand Over WOS** | **WOS** | **ROS** |
| --- | --- | --- | --- |
| 0001 | 15 | 5 | 3 |
| 0005 | 20 | 4 | 5 |
| 0009 | 10 | 5 | 2 |
| 0011 | 25 | 6 | 4.17 |

2. **Update ROS (Tie-breaking Adjustments):**

    1. **Round ROS to 3 Decimal Places**:  
      Each ROS value is rounded to 3 decimal places for consistency.
    2. **Add Scores for Prioritization**:
    
        * **Grade Score**: Higher grades (1AA>1A>1 > 2 > 3>4>5) get higher scores.
        * **On-Hand Score**: Lower on-hand inventory gets higher scores.
        * **Random Score**: A randomly generated value to differentiate ties.
        * **Updated ROS**=Rounded ROS+Grade Score+OH Score+Random Score  
          Below is the calculation of the Updated ROS:
        
    

Ros + 0.000x (Grade Score) +0.0000y (On-Hand Score) + 0.000000z (Random Score)

x is a single digit number signifying store grade (higher grade higher number)  
y is a two digit number signifying onhand qty.   
z is a single digit random number. 

The decimal places of the ros is manipulated as mentioned above.

Here, On-Hand Score is based on Updated Store OH+ OO+ IT(Store Inventory Position), which we calculated earlier.

| **Store** | **Rounded ROS** | **Grade Score** | **On-Hand Score** | **Random Score** | **Updated ROS** |
| --- | --- | --- | --- | --- | --- |
| 0001 | 3 | 0.0005 | 0.000011 | 0.000000234 | 3.000511 |
| 0005 | 5 | 0.0001 | 0.000055 | 0.000000112 | 5.000155 |
| 0009 | 2 | 0.0005 | 0.000015 | 0.000000098 | 2.000515 |
| 0011 | 4.312 | 0.0001 | 0.000011 | 0.000000157 | 4.312111 |

3. **Prioritize Stores:** The final prioritization is determined by sorting stores based on Updated ROS, in descending order.  
  **Example:**

| **Store** | **Priority** | **Updated ROS** |
| --- | --- | --- |
| 0005 | 1 | 5.000155 |
| 0011 | 2 | 4.312111 |
| 0001 | 3 | 3.000511 |
| 0009 | 4 | 2.000515 |

**Step 3: Min Requirement Calculation:** The allocation process begins by calculating the **Min Requirement** at the SKU-Store level. The Min Requirement is calculated at the SKU-Store level by considering the **Min** (min constraint) and the **Updated Store OH+ IT+ OO** (On-Hand + In-Transit + On-Order + Past Allocated Units - Lead Time Forecast).  
**Min Requirement =** IF **(Min- Updated Store OH+ IT+ OO) >= 0** THEN **(Min - Updated Store OH+ IT+ OO)**  
ELSE **0.**  
**Example:**   
Consider the following eligible SKU-Store combinations.  
Style-Color = '111734583MQ4', Size = 'LARGE'

| **Store Code** | **Min** | **Updated Store OH+OO+IT** | **Min Requirement** |
| --- | --- | --- | --- |
| 0001 | 5 | 31 | 0 |
| 0005 | 5 | 43 | 0 |
| 0009 | 5 | 3 | 2 |
| 0011 | 1 | 0 | 1 |

**Step 4: Min Allocated Quantity Calculation:** In the steps above, the Min Requirement at the SKU-Store level has been calculated. Next, we proceed with allocating the minimum requirement to stores based on DC inventory availability. Since the chosen allocation strategy is "Min First and then WOS," the process begins by fulfilling the Min Requirement for each store.  
  
_**Note:** In this example, only one DC is considered for fulfilling the allocation units for all stores._  
  
For Min Allocation, stores are first ranked based on the Updated ROS. The allocation process begins with the highest-priority stores and continues down the priority list, provided there is sufficient DC inventory to meet the minimum requirements. Any remaining DC inventory after fulfilling the min allocation will then be used for demand allocation.  
**Example:**   
Consider the following eligible SKU-Store combinations.  
Style-Color = '111734583MQ4', Size = 'LARGE’  
**SKU-DC Inventory:**

| **Style-Color** | **Size** | **DC** | **Current Available to Allocate** |
| --- | --- | --- | --- |
| 111734583MQ4 | LARGE | S015 | 500 |

**Min Allocated Quantity Table:**

| **Store Code** | **Store Priority** | **Min** | **Updated Store OH+ IT+ OO** | **Min Requirement** | **Current Available to Allocate** | **Min Allocated Quantity** |
| --- | --- | --- | --- | --- | --- | --- |
| 0005 | 1 | 5 | 43 | 0 | 500 | 0 |
| 0011 | 2 | 1 | 0 | 1 | 500 | 1 |
| 0001 | 3 | 5 | 31 | 0 | 500 | 0 |
| 0009 | 4 | 5 | 3 | 2 | 500 | 2 |

**Net DC Available After Min Allocation**= 500-(2+1)=**497**

**Step 5: Forecast Requirement Calculation:** After the min allocation is completed, the system calculates the Forecast Requirement at the SKU-Store level. The system calculates the Forecast Requirement by following the steps:

1. **Cut-Off Week Calculation:** In the optimizer, the forecast calculated for the WOS period is sent as input. If the DC inventory is not enough to meet the demand over WOS for all stores, the system finds a cutoff week based on the available inventory and only considers the forecast up to that week for all stores.    
  **Example:**  
  Assume we have forecasts for 5 weeks. If the available inventory is sufficient to meet only 2 weeks of Demand across all stores, the cutoff week will be 2.

    Thus, the forecast for only the first 2 weeks will be considered for all stores of this size, and the allocation requirement at the size level will be calculated accordingly.



| **Article** | **Size** | **Week** | **Available to Allocate** | **forecast** |
| --- | --- | --- | --- | --- |
| 111734583MQ4 | LARGE | 1 | 500 | 200 |
| 111734583MQ4 | LARGE | 2 | 500 | 280 |
| 111734583MQ4 | LARGE | 3 | 500 | 300 |
| 111734583MQ4 | LARGE | 4 | 500 | 300 |
| 111734583MQ4 | LARGE | 5 | 500 | 400 |

2. **Rounding Deficit in Case of Decimal Demands:**

    1. **Calculate Forecast Over Cutoff Weeks:**  
      Determine the forecast demand for each store based on the cutoff weeks.
    2. **Find the Floor Value:**  
      Take the integer part of the forecast value for each store.
    3. **Calculate the Deficit:**  
      Subtract the floor value from the forecast to find the deficit for each store.
    4. **Compute Total Deficit:**  
      Sum up the deficits across all stores to get the total deficit. If the Total Deficit is a decimal value, it will be rounded to the nearest whole number.
    5. **Rank the store based on the Deficit > Grade > Store On-Hand>Random Factor**
    
        1. **Deficit:** Higher deficit gets higher priority.
        2. **Grade:** Higher grades (e.g., 1AA >1A >1 > 2 > 3 > 4> 5) get higher priority.
        3. **Store On-Hand (OH):** Lower Store On-Hand gets higher priority.
        4. **Random Factor:** Used as a tie-breaker if all the above factors are equal.
        
    6. **Distribute the Deficit:**  
      Distribute the deficit starting from the highest-priority store until the total deficit is distributed.
    7. **Determine Final Rounded Forecast:**  
      Add the distributed deficit to the floor value for each store to get the final rounded forecast.   
      **Example:** 
    

| **Store Code** | **Store Priority** | **Forecast Over Cutoff Weeks** | **Floor Value** | **Deficit** | **Total Deficit** | **Deficit Distribution** | **Final Rounded Forecast** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0005 | 1 | 48.8 | 48 | 0.8 | 2 | 1 | 49 |
| 0011 | 2 | 30.7 | 30 | 0.7 | 2 | 1 | 31 |
| 0001 | 3 | 50.5 | 50 | 0.5 | 2 | 0 | 50 |
| 0009 | 4 | 55 | 55 | 0 | 2 | 0 | 55 |

3. **Forecast Requirement Formula:**  
  Forecast Requirement=max(min(max(Sales Forecast−(Store OH+ Store IT+ Store OO+ Min Allocated Qty), Min Stock − (Store OH+ Store IT+ Store OO+ Min Allocated Qty)), Max Stock−(Store OH+ Store IT+ Store OO+ Min Allocated Qty)), 0)

Where:

**Final Rounded Forecast:** Final Rounded Forecast aggregated over the cutoff weeks.

**Updated Store OH+ IT+ OO:** Updated Store OH+ IT +OO that we calculated above

**Min Allocated Qty:** Minimum allocated quantity at the SKU-Store level.

**Min Stock:** Min Constraints

**Max Stock:** Max Constraints

Note: If the allocation strategy is set to WOS only, then there is only one calculation to determine the allocation quantity rather than splitting it into min allocation and forecast allocation

**Example:** For Size ='LARGE'

| **Store Code** | **Updated Store OH+ IT+ OO** | **Min Allocated Qty** | **Final Rounded Forecast** | **Min Stock** | **Safety Stock** | **Max Stock** | **Forecast Requirement** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0001 | 31 | 0 | 50 | 5 | 0 | 999 | 19 |
| 0005 | 43 | 0 | 49 | 5 | 0 | 999 | 6 |
| 0009 | 3 | 2 | 55 | 5 | 0 | 999 | 50 |
| 0011 | 0 | 1 | 31 | 1 | 0 | 999 | 30 |

**Step 6: Forecast Allocated Quantity Calculation:** The optimizer calculates the Forecast Allocated Quantity by considering the Forecast Requirement and Available DC inventory.

For Forecast Allocation, stores are ranked based on their Updated ROS. Allocation starts with the highest-priority store and continues down the priority list, as long as there is enough DC inventory to fulfill the forecast requirements.  
**Example:**   
Consider the following eligible SKU-Store combinations.  
Style-Color = '111734583MQ4', Size = 'LARGE’  
**SKU-DC Inventory:**

| **Style-Color** | **Size** | **DC** | **Current Available to Allocate After Min Allocation** |
| --- | --- | --- | --- |
| 111734583MQ4 | LARGE | S015 | 497 |

**Forecast Allocated Quantity Table:**

| **Store Code** | **Store Priority** | **Forecast Requirement** | **Current Available to Allocate** | **Forecast Allocated Quantity** |
| --- | --- | --- | --- | --- |
| 0005 | 1 | 6 | 497 | 6 |
| 0011 | 2 | 30 | 497 | 30 |
| 0001 | 3 | 19 | 497 | 19 |
| 0009 | 4 | 50 | 497 | 50 |

**Total Forecast Allocated Quantity For Size 'LARGE' =** (6+30+19+50)**=105**  
 **Net DC Available After Forecast Allocation**= 497-(105)=**392**

In the above example, we have sufficient inventory of 497 units to fulfill the demand for all eligible stores. After allocating to all stores, 392 units will remain.

Now, let’s consider another example where the inventory is insufficient to meet the demand of all eligible stores. Assume we currently have 51 units available for allocation after the min allocation.

**SKU-DC Inventory (Constrained Inventory):**

| **Style-Color** | **Size** | **DC** | **Current Available to Allocate After Min Allocation** |
| --- | --- | --- | --- |
| 111734583MQ4 | LARGE | S015 | 51 |

**Forecast Allocated Quantity Table (Constrained Inventory):**

| **Store Code** | **Store Priority** | **Forecast Requirement** | **Current Available to Allocate** | **Forecast Allocated Quantity** |
| --- | --- | --- | --- | --- |
| 0005 | 1 | 6 | 51 | 6 |
| 0011 | 2 | 30 | 51 | 30 |
| 0001 | 3 | 19 | 51 | 15 |
| 0009 | 4 | 50 | 51 | 0 |

As shown in the table above, with only 51 units available for allocation, the distribution is done based on store priority.   
  
For stores "**0005**" and "**0011**," there is sufficient inventory to meet their forecast requirements. However, for store "**0001,**" only 15 units are available, so all 15 units are allocated instead of the 19 units required.   
  
For store "**0009**," no inventory remains, so it cannot be allocated any units.  

**Total Allocated Quantity** for Size 'LARGE' is (6+30+15+0) = **51**  
**Net DC Available After the Allocation** = 51-51 = **0**   

**Step 7: Total Allocated Quantity Calculation: Total Allocated Quantity** is calculated as the sum of **Min Allocated Quantity** and **Forecast Allocated Quantity** at the SKU-Store level.

**Example:**  
Consider the following eligible SKU-Store combinations for which the Min Allocated Quantity and Forecast Allocated Quantity have been calculated.

**Style-Color:** '111734583MQ4'  
**Size:** 'LARGE'

| **Store Code** | **Min Allocated Quantity** | **Forecast Allocated Quantity** | **Total Allocated Quantity** |
| --- | --- | --- | --- |
| 0005 | 0 | 6 | 6 |
| 0011 | 1 | 30 | 31 |
| 0001 | 0 | 19 | 19 |
| 0009 | 2 | 50 | 52 |

**Total Allocated Quantity** for Size 'LARGE' is (6+31+19+52)=**108**  
 **Net DC Available After the Allocation** = 500-108=**392**

A summary example has been created, including all the required metrics calculated to determine the "total allocated quantity" at the store-size level for a specific Style-Color. Refer to the linked sheet - <custom data-type="smartlink" data-id="id-2">https://docs.google.com/spreadsheets/d/1aHJkh02rslBeMnfRdguxKqFggPTwvXQE5-7-9-CJ0SM/edit?gid=1729665264#gid=1729665264</custom> 

### **Packs Allocation & ATA calculation:**

For styles that have **DC inventory available in packs**, the **size-level ATA (Available to Allocate)** computation requires a distinct calculation approach.

#### **ATA Calculation:**

Consider a style where a single size exists in both **packs** and **eaches**.

* **Pack 1 → DIM001**  
  Pack Configuration: Size M → 3 units, L → 2 units, XL → 1 unit  
  → **Total units in pack = 3 + 2 + 1 = 6**
* **Pack 2 → DIM002**  
  Pack Configuration: Size M → 2 units, L → 1 unit  
  → **Total units in pack = 2 + 1 = 3**

| **Pack/Size** | **Available** |
| --- | --- |
| DIM001 | 2 |
| DIM002 | 4 |
| L | 3 |
| XL | 2 |

Size level ATA:  
M → 2\*3 + 4\*2 = 14  
L → 2\*2 + 4\*1 + 3\*1 = 11  
XL → 2\*1 + 2\*1 = 4

Total ATA = 2\*6 + 4\*3 + 3\*1 + 2\*1 = 29

Pack allocation differs from eaches in that it must account for pack configurations, which can impact minimum breaches, maximum breaches, and over/under allocation.

This is due to cost optimization, where the system balances over/under allocation to meet the optimized need based on available pack configurations. As a result, pack allocation introduces additional complexities compared to scenarios where inventory is available in eaches.

#### **Cost Optimization Logic in Pack Allocation**

In the allocation process, cost optimization plays a crucial role in determining pack allocation.

For example, consider Style → 2R061610 and Store → 3021. There are four sizes with a pack configuration that deviates from the final need pattern. This means the pack configuration and final need are not in the same ratio, requiring optimization to balance over/under allocation across sizes. The goal is to allocate in a way that minimizes cost while ensuring an optimal distribution.

| Size | Pack Config | Min | Max | Demand | Store inv | Ltf | Final need | ROS | 1 pk delta | 2 pk delta |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2T | 3 | 3 | 7 | 5 | 1 | 1 | 5 | 1.1 | 5 - 3 = 2 | 5 - 6 = -1 |
| 3T | 4 | 3 | 7 | 7 | 1 | 0 | 6 | 1.6 | 6 - 4 = 2 | 6 - 8 = -2 |
| 4T | 3 | 3 | 7 | 5 | 1 | 0 | 4 | 1.3 | 4 - 3 = 1 | 4 - 6 = -2 |
| 5T | 2 | 5 | 7 | 5 | 2 | 0 | 3 | 0.9 | 3 - 2 = 1 | 3 - 4 = -1 |

The cost is determined using the formula:  
Cost = Σ |Δ \* ROS|

**Example Calculation:**

* **1 Pack Cost:**  
  2×1.1 + 2×1.6 + 1×1.3 + 1×0.9=7.6
* **2 Pack Cost:**  
  1×1.1 + 2×1.6 + 2×1.3 + 1×0.9 = 7.8

Since the cost for allocating 1 pack (7.6) is lower than 2 packs (7.8), the optimizer chooses to allocate only 1 pack in this case.

### **Case Pack Rounding:**

Products with Inner Pack Units greater than 1 are classified as case packs.

Initial allocations are made considering eaches, but after allocation, rounding logic is applied to ensure that the final allocation number is a multiple of the Inner Pack Units. 

**NOTE:** The rounding logic explained below applied at size level separately. Style Color level rounding across sizes is not possible. The input from clients can be shared at size level or at style color level. If style color level input is shared, the same value will be applied for each sizes.

The rounding logic can be implemented either in post processing logic or in Gurobi layer. If Min fulfilment is a must then rounding should be done in Gurobi layer with f0_min=0 and fu_min=1

**Rounding Logic for Allocated Units Based on Inner Pack Units:**

1. **Initial Allocation**  
  Start by considering the allocated units in eaches.
2. **Calculate the Half Factor**  
  The **Half Factor** is calculated as 50% of the Inner Pack Units.  
  **Half Factor = 50% of Inner Pack Units**
3. **Calculate Allocated Units % Inner Pack Units**  
  This is the remainder when the **Allocated Units** are divided by the **Inner Pack Units**:
4. **Determine Round Up or Round Down**  
  If the remainder is more than or equal to the Half Factor, we round up; if it’s less, we round down.
5. **Rounding Logic**

    * **Round-Up**: If the remainder is greater than or equal to Half Factor, round up to the nearest multiple of the Inner Pack Units.
    * **Round Down**: If the remainder is less than Half Factor, round down to the nearest multiple of the Inner Pack Units.
    
6. **Handling Insufficient DC Inventory**  
  If there is insufficient DC inventory to round up to the nearest multiple of the pack quantity, a round-down operation is performed. The system completes all round-down operations first before reassessing the available DC inventory for further allocations.

     **Example:**

| **Size** | **Store** | **Allocated Units** | **Inner Pack Units** | **Half Factor** | **Allocated Units % Inner Pack Units** | **Round UP/Down** | **Updated Allocated Value** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MEDIUM | 0001 | 43 | 12 | 6 | 7 | UP | 48 |
| LARGE | 0005 | 41 | 12 | 6 | 5 | DOWN | 36 |

**Case Pack Rounding Scenarios:**  
**Case 1: If the Initial Allocated Units at the Size-Store level are Less Than the Half Factor for all the Size Stores.**

In this scenario, if the allocated units are less than the half factor, the allocation is rounded down to the nearest multiple of the inner pack units, resulting in zero allocated units.  
**Example:**  
Consider a Style-Color with the following eligible Size and Stores:

| **Size** | **Store** | **Allocated Units** | **Inner Pack Units** | **Half Factor** | **Allocated Units % Inner Pack Units** | **Round UP/Down** | **Updated Allocated Value** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MEDIUM | 0001 | 2 | 6 | 3 | 2 | DOWN | 0 |
| LARGE | 0005 | 2 | 6 | 3 | 2 | DOWN | 0 |
| MEDIUM | 0006 | 2 | 6 | 3 | 2 | DOWN | 0 |
| LARGE | 0007 | 2 | 6 | 3 | 2 | DOWN | 0 |
| LARGE | 0008 | 2 | 6 | 3 | 2 | DOWN | 0 |

**Summary:**

* **Total Allocated Units before Case Pack Rounding:** 10
* **Updated Allocated Value after Case Pack Rounding:** 0

**Case 2: Allocation with Limited Available Units**

**Example:**  
Consider a Style-Color with the following eligible sizes and stores, where the **Current Available to Allocate = 24 units**.

| **Size** | **Store** | **Allocated Units** | **Inner Pack Units** | **Half Factor** | **Allocated Units % Inner Pack Units** | **Round UP/Down** | **Updated Allocated Value** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MEDIUM | 0001 | 13 | 8 | 4 | 5 | DOWN | 8 |
| MEDIUM | 0005 | 6 | 8  | 4 | 6 | UP | 8 |
| MEDIUM | 0007 | 5 | 8 | 4 | 5 | UP | 8 |

**Example Breakdown:**

* As per the scenario added in the above table, for all the stores, the remainder units is greater than half factor, so round UP should be the done.
* Round UP for all the 3 Stores would require **32 Units (16 + 8 + 8)**
* Since the total allocated units post round up is greater than available units (**32 > 24**), round DOWN will be done.
* After Round DOWN, the total allocated units - **8 Units (8 + 0 + 0)**
* Remaining Units - **24 - 8 = 16 Units**
* Now, from the remaining available units, round UP will be done store by store until all units are exhausted.

---

## **Implications of Cyclic Feeds in CNA:**

**DC OH Update with Cyclic Feed in CNA**  
DC OH is updated through the cyclic feed, accounting for the incoming inventory during the cycle. The system will not make adjustments in the DC OH for the allocations finalized on the same. The finalized allocated units will be reserved as Allocation Reserve for the full day. 

**Example:**

**Initial State (t=0, Beginning of the Cycle)**

| **Size** | **DC** | **DC OH** | **Allocation Reserve** |
| --- | --- | --- | --- |
| LARGE | S015 | 100 | 0 |

**During the Cycle (0≤t<2  hours)**  
If the update frequency is every 2 hours, and the user allocates 50 units during the cycle:

| **Size** | **DC** | **DC OH** | **Allocation Reserve** |
| --- | --- | --- | --- |
| LARGE | S015 | 100 | 50 |

 

**Beginning of the Next Cycle(t=2 hours)**  
**Case 1:** At the start of the next cycle, DC OH is updated to 120 units (20 units incoming)

| **Size** | **DC** | **DC OH** | **Allocation Reserve** |
| --- | --- | --- | --- |
| LARGE | S015 | 120 | 50 |

In this case, the remaining available to allocate for newer allocations would be **70 units (120 - 50)**

**Case 2:** At the start of the next cycle, DC OH is updated to 80 units (20 units outgoing)

| **Size** | **DC** | **DC OH** | **Allocation Reserve** |
| --- | --- | --- | --- |
| LARGE | S015 | 80 | 50 |

In this case, the remaining available to allocate for newer allocations would be **30 units (120 - 50)**

---

## **KPI Formula Sheet:**

Kindly refer to the "Create New Allocation" sheet in the spreadsheet below for the KPI formulas used in the CNA module.  
<custom data-type="smartlink" data-id="id-3">https://docs.google.com/spreadsheets/d/1ioIwS9PJBObMxNuoWJWeq7mqxCnFTfsjrJ8m6gVGsNo/edit?gid=554073445#gid=554073445</custom> 

‌

## Additional Allocation Workflows

### I. Fixed Inventory Push:

Fixed Inventory Push allows users to enter the number of units or a percentage of inventory to be pushed out from the DC. The entered units must be less than or equal to the Current Available to Allocate (CATA) units and a validation is in place in the UI.

**Manual Allocation Flow with Fixed as Demand Type:**

![](blob:https://media.staging.atl-paas.net/?type=file&localId=f28a8b82-7ae7-4bb3-9b7e-264456f1167e&id=aaea00c3-36cf-4058-bd6e-513799d9983c&&collection=contentId-2696609825&height=810&occurrenceKey=null&width=1815&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
Please refer to the [**Manual Allocation Flow - Configuring Inputs**](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Manual-Allocation-Flow--Configuring-Inputs) section to understand how the Details table is populated with eligible Style-Colors after the user selects filters in the filter section.

Once the Details table is populated, the following column needs to be updated by the user to enable Fixed Inventory Push:

* **Demand Type**: The user must select "**Fixed**" as the demand type to enable Fixed Inventory Push for allocation.

The user must then input one of the following to populate the **Fixed Qty to Allocate** column:

* **User Defined Inv. in %**
* **Fix Inv Push**

For more information, refer to the relevant sections under Details Table: [**User Defined Inv. in %, Fix Inv Push, Fixed Qty to Allocate**.](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Details-Table%3A)

Please note that any changes made to the **Prioritization Strategy** or **Allocation Strategy** when the **Demand Type** is set to "Fixed" will not affect the **Fixed Qty to Allocate** units.

**Mins Only** Allocation Strategy is not applicable when the **Demand Type** is “Fixed”.

Example:

| **Style-Color** | **Demand Type** | **Current Available to Allocate** | **User Defined Inv. in %** | **Fixed Inv Push** | **Fixed Qty to Allocate** |
| --- | --- | --- | --- | --- | --- |
| 111734586GVG | Fixed | 2178 | 10 | - | 218 |
| 1119497554A2 | Fixed | 10 | - | 5 | 5 |

#### **Review Store and DC:**

After selecting a Style-Color or list of Style-Colors having the demand type as “**Fixed**” from the Details Table, the user can click on **Review Store and DC** to access the **Store Details** and **Inv. Source** tables for the selected Style-Colors.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=50714e8c-825c-4267-80ba-e199df34604f&id=50f24e6d-6e61-435f-a26f-747414ad9542&&collection=contentId-2696609825&height=537&occurrenceKey=null&width=1832&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
Please refer to the **Metrics and Calculation** details in the following linked sections:

a. [**Store Details**](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#a.-Store-Details%3A)  
b. [**Inv. Source**](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#b.-Inv.-Source%3A)

---

#### **Recommendation Screen:**

The screen includes Product View and Store View, enabling users to review the Fixed allocated units and the remaining DC availability by size.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=f19f981d-9444-4df0-a4e3-6df66d236b68&id=e5ac13d3-7371-457d-b7b9-ea1ca15a63ab&&collection=contentId-2696609825&height=890&occurrenceKey=null&width=1823&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
First, we explain how the allocated quantity is determined at the SKU-Store-DC level and then describe how this information populates the different views in the Recommendation screen.

##### **Allocated Quantity Determination at SKU-Store-DC Level**

Total Allocated Quantity = 218

Below is the size-level quantity to allocate: It is 10% of the size level available DC OH

| **Size** | **Available DC OH** | **Reqd. Qty to Allocate (RQA)** |
| --- | --- | --- |
| XL | 4 | 0 |
| MED | 1073 | 107 |
| LARGE | 29 | 3 |
| SMALL | 1001 | 100 |
| XS | 82 | 8 |

Lets see how the fixed allocation push happens for the size = SMALL, which has a requirement of 100 units to allocate

**Step-by-Step Allocation Process:**

**Step 1:** Calculate the aggregated store inventory OH + IT + OO. The aggregated store inventory along with the Reqd. Qty to Allocate form the total inventory to be allocated to store.

The total store inventory as per below example = (10 + 20 + 60 + 50) = 140  
Reqd. Qty to Allocate (RQA) = 100  
Total Units = 140 + 100 = 240

| **store Code** | **Overall Proportion** | **OH + IT + OO** | **Ideal Distribution** | **Requirement** | **Mins** | **Max** |
| --- | --- | --- | --- | --- | --- | --- |
| 0005 | 40% | 10 | 96 | 70 | 15 | 80 |
| 0011 | 30% | 20 | 72 | 52 | 5 | 80 |
| 0001 | 20% | 60 | 48 | 0 | 5 | 70 |
| 0009 | 10% | 50 | 24 | 0 | 5 | 52 |

Total Units (store inventory and RQA) for size “SMALL” will be distributed to stores based on the rescaled overall proportion. This will be the **Ideal Distribution**.

For Store Codes, **0001** and **0009**, store inventory is already higher than the Ideal Distribution required. So, no units will be pushed to these stores unless the max for other stores are satisfied.

Requirement is calculated as:

**maximum( (minimum(MAX, Ideal Distribution) - (OH + IT + OO) ), 0)**

Based on the Requirement and RQA, the rescaled requirement is calculated.

Rescaled Req = **RQA / Sum(Requirement) \* Requirement**

| **store Code** | **Overall Proportion** | **OH + IT + OO** | **Ideal Distribution** | **Requirement** | **Mins** | **Max** | **Rescaled Req** | **Expected Push** | **Final Inv After Push** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0005 | 40% | 10 | 96 | 70 | 15 | 80 | 57 | 57 | 67 |
| 0011 | 30% | 20 | 72 | 52 | 5 | 80 | 43 | 43 | 63 |
| 0001 | 20% | 60 | 48 | 0 | 5 | 70 | 0 | 0 | 60 |
| 0009 | 10% | 50 | 24 | 0 | 5 | 52 | 0 | 0 | 50 |

The expected push is calculated as 

Expected Push = **IF( Rescaled Req > ( MAX - (OH + IT + OO) ), ( MAX - (OH + IT + OO) ), Rescaled Req)**

If for some stores, the max is breached in the calculation of the expected push, then the remaining units will be pushed to other stores where the max is not breached.

This **Final Inv After Push**, will be sent to Gurobi as Demand for Allocation optimization.

**Step 2:** Store Prioritization - Please refer to the **Store Prioritization** section in the manual allocation.

Example: 

Consider the following eligible SKU-Store combinations

Style-Color = '111734586GVG', Size = 'SMALL', Allocated Qty = 100

The final prioritization is determined by sorting stores based on Updated ROS, in descending order.  
**Example:**

| **Store** | **Priority** | **Updated ROS** |
| --- | --- | --- |
| 0005 | 1 | 6.612 |
| 0011 | 2 | 6.324 |
| 0001 | 3 | 4.734 |
| 0009 | 4 | 4.098 |

The Fixed Allocation using the 3 major steps which are explained in the below steps

**Step 3: Satisfying the Minimum Quantities:**

* Each store has a predefined **minimum quantity (Min)** requirement.
* The first step is to allocate units to ensure that every store’s **Min requirement** is fulfilled.
* If the total allocated quantity (100) is sufficient to meet all the minimum requirements, any remaining units proceed to the next step.
* If the total allocated quantity (100) is not sufficient to meet all the minimum requirements, then 2 condition are there:

    * **Case 1** - DC has enough inventory (more than the fixed inventory planned to push) to satisfy the Min requirement -   
      If the flag, **min_priority_for_fixed_inv,** is set to **True** then Min will be prioritized and the optimizer will try to satisfy the mins for all the stores  
      If the flag, **min_priority_for_fixed_inv,** is set to **False** then the set fixed quantity will be treated as hard constraints and no extra units will be allocated even if the DC has enough inventory to satisfy the mins
    

1. **Min Requirement Calculation:**

The allocation process begins by calculating the **Min Requirement** at the SKU-Store level. The Min Requirement is calculated at the SKU-Store level by considering the **Min** (min constraint) and the **Store OH+OO+IT and Past Allocated Units.**

**Updated Store OH** = Store OH + OO + IT + Past Allocated Units

**Min Requirement =** IF **(Min- Updated Store OH) >= 0** THEN **(Min - Updated Store OH)** ELSE **0.**  
**Example:**   
Consider the following eligible SKU-Store combinations.  
Style-Color = '111734586GVG', Size = 'SMALL', Allocated Qty = 100

| **Store Code** | **Min** | **Updated Store OH** | **Min Requirement** |
| --- | --- | --- | --- |
| 0005 | 15 | 10 | 5 |
| 0011 | 5 | 20 | 0 |
| 0001 | 5 | 60 | 0 |
| 0009 | 5 | 50 | 0 |

2. **Min Allocated Quantity Calculation:** In the steps above, the Min Requirement at the SKU-Store level has been calculated. Next, we proceed with allocating the minimum requirement to stores based on DC inventory availability.

_**Note:** In this example, only one DC is considered for fulfilling the allocation units for all stores._

For Min Allocation, stores are first ranked based on the Updated ROS. The allocation process begins with the highest-priority stores and continues down the priority list, provided there is final Remaining Quantity to Allocate (RQA). Any RQA after fulfilling the min allocation will then be used for demand allocation.  
**Example:**   
Consider the following eligible SKU-Store combinations.  
Style-Color = '111734586GVG', Size = 'SMALL’, Allocated Qty = 100

Now we will talk about how the DC Inventory is wrangled throughout this operation:

**SKU-DC Inventory:**

| **Style-Color** | **Size** | **DC** | **Remaining Quantity to Allocate (RQA)** |
| --- | --- | --- | --- |
| 111734586GVG | SMALL | S015 | 100 |

**Min Allocated Quantity Table:**

| **Store Code** | **Store Priority** | **Min** | **Store OH+OO+IT** | **Min Requirement** | **Remaining Quantity to Allocate** | **Min Allocated Quantity** |
| --- | --- | --- | --- | --- | --- | --- |
| 0005 | 1 | 15 | 10 | 5 | 100 | 5 |
| 0011 | 2 | 5 | 20 | 0 | 100 | 0 |
| 0001 | 3 | 5 | 60 | 0 | 100 | 0 |
| 0009 | 4 | 5 | 50 | 0 | 100 | 0 |

For size SMALL, since 5 unit is allocated for Mins, so the remaining units are reduced to 95.

**Net DC Available After Min Allocation for SMALL**= 1001-(5+0+0+0)=**996**

Fixed units to push after Min Allocation for SMALL (Need) = 100 -5 = 95

**Step 4: Demand based distribution of remaining units:**

* After meeting the minimum requirements, the remaining units are distributed to stores
* Store Need is calculated as: Need = Remaining Final RQA - Updated Store OH
* Stores are prioritized (ordered) by their need and allocated

1. **Remaining Final** **RQA**

This is the remaining units to push out per store, after Min Allocation. This can also be considered as the Store “Need” for the demand based allocation component.

In below example, 67 is the Final RQA and 15 is already in the store **0005**, so 52 (67-15) will be the need for the store

Where:

**Updated Store OH+OO+IT:** Store OH+OO+IT +Past Allocated Units that we calculated above

**Min Allocated Qty:** Minimum allocated quantity at the SKU-Store level.

**Min Stock:** Min Constraints

**Max Stock:** Max Constraints

**Example:** For Size ='SMALL'

| **Store Code** | **Updated Store OH+OO+IT** | **Min Allocated Qty** | **Final RQA** | **Min Stock** | **Max Stock** | **Need** |
| --- | --- | --- | --- | --- | --- | --- |
| 0005 | 10 | 5 | 67 | 15 | 80 | 52 |
| 0011 | 20 | 0 | 63 | 5 | 80 | 43 |
| 0001 | 60 | 0 | 60 | 5 | 70 | 0 |
| 0009 | 50 | 0 | 50 | 5 | 52 | 0 |

**Note:** If the Max constraint is lower than the Need, the push will be less than the fixed inventory units specified by the user at the time of allocation configuration.

If max is breached we will allocate the fixed units to other stores where max is not breached, we have explained that in detail in step5

2. **Fixed Allocated Need Quantity Calculation:**

The optimizer calculates the Allocated Quantity by considering the Need and Final RQA.

For Forecast Allocation, stores are ranked based on their Updated ROS. Allocation starts with the highest-priority store and continues down the priority list to fulfill the need.

| **Store Code** | **Store Priority** | **Need** | **RQA** | **Fixed Allocated Need Quantity** |
| --- | --- | --- | --- | --- |
| 0005 | 1 | 52 | 95 | 52 |
| 0011 | 2 | 43 | 95 | 43 |
| 0001 | 3 | 0 | 95 | 0 |
| 0009 | 4 | 0 | 95 | 0 |

**Allocated Need Quantity** for Size 'SMALL' is (52+43+0+0)=**7**

**Fixed units to push after the Min and Need Allocation** = 100-1 (Min Allocated)-95(Forecast Allocated Quantity)=0

**Step 5: Allocation of Remaining Fixed Allocated Quantity**

If there are still unallocated units after the above steps, the remaining quantity is distributed to the stores:

* Based on **priority**, which determines the order in which stores receive the leftover units. Stores with higher priority are allocated first.
* While distributing, the system considers the **maximum constraints (Max)** defined for each store, ensuring that no store receives more than its allowable maximum quantity.

In this case, after allocating the Min quantities and Fixed Forecast quantities, no units remain to be distributed.

If there are units remaining, then the remaining units will be distributed to stores which has not breached the MAX constraints. The logic of distribution is based on the rescaled overall proportion (fetched from product profile).

**Step 6: Total Allocated Quantity Calculation:**

**Total Allocated Quantity** is calculated as the sum of **Min Allocated Quantity**, **Need Allocated Quantity** and **Remaining Fixed Inv Push** at the SKU-Store level.

**Total Allocated Quantity** for Size 'SMALL' is (57+43+0+0)=**100**  
 **Net DC Available After the Allocation** = 1001-100=901

**More detailed work flow for Fixed Inventory push can be found in this sheet** - <custom data-type="smartlink" data-id="id-4">https://docs.google.com/spreadsheets/d/1PkERMhFxdNRIGJATmqcbNYqPVKb5COYxO6svxW__r2o/edit?gid=721676232#gid=721676232</custom> 

**Note:** The Fixed inventory push depends on Product Profile. By default the IA recommended Product profile will be used. If user has set user created product profile in the DC Store Policy then the User Created Product Profile will be used for allocation.

If User Created product profile is used then the allocation distribution will be based on the user created PP.

### II. Prioritization Strategy: Fair Share

The prioritization strategy defines how stores should be prioritized for allocation. When the demand type is set to 'IA Forecast' and the prioritization strategy is 'Fair Share,' the system allocates inventory based on demand proportions.

**Example Scenario:** Allocation Under Constrained Inventory

**Key Parameters:**

**Inventory is Constrained:** Insufficient inventory to meet total demand

**Allocation Strategy:** Mins First and then WOS

**Prioritization Strategy:** Fair Share

**Demand Type:** IA Forecast

#### **Allocation Process Flow:**

1. **Steps 1 to 4** follow the process outlined in the [**Allocated Quantity Determination at SKU-Store-DC Level**](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609825/CNA+Handbook#Allocated-Quantity-Determination-at-SKU-Store-DC-Level)

**Scenario:**

* Current available DC OH = 8
* Total forecast = 31
* **Net units to be pushed**: Need after considering store inventory.

| **Stores** | **Store Tier** | **Forecast** | **Min** | **Max** | **Updated Store OH** | **Net Units to be Pushed** |
| --- | --- | --- | --- | --- | --- | --- |
| 1001 | T1 | 10 | 1 | 30 | 0 | 10 |
| 1002 | T1 | 5 | 1 | 30 | 1 | 4 |
| 1003 | T2 | 3 | 1 | 30 | 0 | 3 |
| 1004 | T2 | 10 | 1 | 30 | 5 | 5 |
| 1005 | T3 | 3 | 1 | 30 | 0 | 3 |
|  | **Total** | 31 | 5 | 150 | 6 | 25 |

After following till step 4 from the section mentioned, below is the table after the **mins allocation**

| **Stores** | **Min** | **Max** | **Updated Store OH** | **Step 1:Fill to Mins** |
| --- | --- | --- | --- | --- |
| **Mins** | **Mins Need** | **Mins Allocation** |
| 1001 | 1 | 30 | 0 | 1 | 1 | 1 |
| 1002 | 1 | 30 | 1 | 1 | 0 | 0 |
| 1003 | 1 | 30 | 0 | 1 | 1 | 1 |
| 1004 | 1 | 30 | 5 | 1 | 0 | 0 |
| 1005 | 1 | 30 | 0 | 1 | 1 | 1 |
| **Total** | **5** | **150** | **6** | **5** | **3** | **3** |

Suppose we proceed with Steps 5 and 6 and allocate based on the "IA Forecast Priority." The resulting allocation is as follows:

| **Stores** | **Updated Store OH** | **Mins Allocation** | **Step 2: Fill to Forecast** |
| --- | --- | --- | --- |
| **Forecast** | **Need** | **IA Allocation** | **Net Allocation** |
| 1001 | 0 | 1 | 10 | 9 | 5 | 6 |
| 1002 | 1 | 0 | 5 | 4 | 0 | 0 |
| 1003 | 0 | 1 | 3 | 2 | 0 | 1 |
| 1004 | 5 | 0 | 10 | 5 | 0 | 0 |
| 1005 | 0 | 1 | 3 | 2 | 0 | 1 |
| **Total** | **6** | **3** | **31** | **22** | **5** | **8** |

#### Fair Share Prioritization Strategy:

If the prioritization strategy is Fair Share, the allocation is more equitable across stores:

**Need Ratio** = Store Need / Total Store Need.

**Allocation** = Need Ratio \* Available DC Qty.

**Forecast Allocation** = The final allocation considers fair share distribution

| Store | Store Tier | Need | Available DC Qty (DC OH-Mins Alloc) | Need Ratio | Allocation  
(X) | Rounded Down Alloc.  
(Y) | Deficit  
(X-Y) | Deficit Allocation   
(Z) | Forecast Allocation   
(Y+Z) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1001 | T1 | 9 | 5 | 41.00% | 2.05 | 2 | 0.05 | 0 | 2 |
| 1002 | T1 | 4 | 5 | 18.00% | 0.91 | 0 | 0.91 | 1 | 1 |
| 1003 | T2 | 2 | 5 | 9.00% | 0.45 | 0 | 0.45 | 1 | 1 |
| 1004 | T2 | 5 | 5 | 23.00% | 1.14 | 1 | 0.14 | 0 | 1 |
| 1005 | T3 | 2 | 5 | 0.09 | 0.45 | 0 | 0.45 | 0 | 0 |

Using Fair Share, the allocation ensures inventory is distributed to multiple stores based on their demand proportions, avoiding a scenario where only one store receives inventory, as seen with IA Forecast Priority.

‌

‌

‌
