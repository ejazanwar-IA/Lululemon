# Create New Allocation - User Story

| Field | Value |
|---|---|
| Confluence page ID | `2696611283` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611283/Create+New+Allocation+-+User+Story |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:27.348Z |
| Last mirrored | 2026-05-21 |

---

| **Update Date** | **Updated By** | **Description** |
| --- | --- | --- |
| <custom data-type="date" data-id="id-0">5/18/2026</custom> | <custom data-type="mention" data-id="id-1">@Gowthami T</custom>  | Higher Level edit addition Created new user story for what if scenario Updated review recommendation user story to add new columns/ update the naming convention of existing ones (based on comparison with GA) Added Aggregation logic and specific custom dimension |
| <custom data-type="date" data-id="id-2">5/18/2026</custom> | <custom data-type="mention" data-id="id-3">@Gowthami T</custom>  | Removed Current Available to allocate Eaches and Packs as this is not relevant (Details Table) |
| <custom data-type="date" data-id="id-4">5/6/2026</custom> | <custom data-type="mention" data-id="id-5">@Navin Chandan</custom> | Removed mapping columns for the OOTB columns |
| <custom data-type="date" data-id="id-6">4/10/2026</custom> | <custom data-type="mention" data-id="id-7">@Navin Chandan</custom> | Added fc_name and tc_name |
| <custom data-type="date" data-id="id-8">3/24/2026</custom> | <custom data-type="mention" data-id="id-9">@Navin Chandan</custom> | Recommendation Screen KPIs enhancements |
| <custom data-type="date" data-id="id-10">3/20/2026</custom> | <custom data-type="mention" data-id="id-11">@Navin Chandan</custom> | Added mapping table, datatype and Nullable column in filters and tables for validation Title case naming as per latest guideline Review Forecast enhancements |

# Table of Contents

# Guideline

* The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**
* Filters are configurable as per clients requirement.
* Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**
* Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**
* Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.
* Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field

# Module Dependency/ Pre requisite

1. [Configuration -> Product -> Product Status](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610803)
2. [Configuration -> Store -> Store Status](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610899)
3. [Configuration -> DC -> DC Status](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611025)
4. [Configuration -> Product -> Product-Store Mapping](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610831)
5. [ADA Visual](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610753)
6. [Grouping -> Product Group](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610771)
7. [Grouping -> Store Group](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610787)
8. [Product Profile](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611244)
9. [Configuration -> Product -> Product-DC Mapping](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610859)
10. [Configuration -> Store -> Store-DC Mapping](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610922)
11. [Configuration -> DC-Store Policy -> DC Store Strategy Rules](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611046)
12. [Configuration -> DC-Store Policy -> Auto Allocation Rules](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611080)
13. [Configuration -> DC-Store Policy -> Auto Allocation Scheduler](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611113)
14. [Constraints -> Store Allocations](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611179)
15. [Constraints -> User Reserve](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611213)
16. [Configuration -> DC-Store Policy -> DC Store Strategy](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611146)

# User Story

## **Demo link: {Add React Demo - If available}**

## **Details:**

Users can leverage CNA to create Manual Allocations.

Users can also create a **New** **Allocation** from the **Decision Dashboard Module**.

This story mainly explains the allocation flow only through the **Create New Allocation** Module. The user can make temporary changes to the **constraints** and some **configuration** options on this screen. The SKU/sizes to be allocated for a style color (article or styles) can also be filtered.  
These changes will only be applicable for this active allocation and will revert once the allocation is finalized. Once an allocation has been finalized, the **Available to Allocate** in the DC and the store inventory will change to reflect the allocated quantity of the finalized allocation.

**General deviations when CNA is directed through the Dashboard → Alerts (Except Auto allocation, PO To Allocate, ASN To Allocate):**

* On Create New Allocation from **Dashboard → Any** **Alert except auto allocation, PO To Allocate and ASN To Allocate**, the user is redirected to the Create New Allocation screen in a separate window. The selected style colors (articles or styles) are filtered in the Create New Allocation screen.

**General deviations when CNA is directed through the Dashboard → PO To Allocate or ASN To Allocate:**

* On clicking the review allocation from **Dashboard → PO To Allocate or ASN To Allocate,** the user is redirected to the Create New Allocation screen in a separate window. PO or ASN inventory source is utilized for Allocation. Inv Source dropdown should be defaulted to **PO Inv** or **ASN Inv**.

**General deviations when CNA is directed through the Dashboard → Auto Allocation Alerts:**

* On clicking the review allocation from **Dashboard → Auto Allocation Alerts,** the user is redirected to the Create New Allocation -> Recommendation Screen in a separate window.

# **User Story 1 - Filters and Details Table:**

## **Jira Summary: \[Client Name\] - Create New Allocation -> Details Table**

## **Jira Description:**

### Navigation:

Left-hand panel → Create New Allocation

### Landing Page:

After navigating to the Create New Allocation, user will land on the 1st step of allocation creation → Allocation Plan Input. Here user can add the Allocation Plan Name or keep it blank. In case of blank the system should automatically create an unique allocation plan name.

**Generic Flow of Allocation Module:**

1. Enter **Allocation Plan Name**: The User can enter the Allocation Plan name if needed.
2. Select the relevant **Filters**.
3. Click on **Apply Filter**.
4. Review the table populated at the style color (article or style) level. The flow and columns information about the 'Details' table is added below. User can edit the allocation strategies and source of inventory.
5. Review The Style Color-Store (article-store or style-store) level properties from the Review Store and DC table and the edits can be made wherever necessary. 
6. Click on **Create Allocation**.
7. Click on **Notification(bell icon)** on the top right corner of the Inventory Smart product.
8. Select the Allocated Plan from **Notification.** Product View and Store View recommendations will open. If required user can make the edits in the allocated quantity.
9. Click on **Finalize (Release)** or **Move to Order Batching**

### Filters:

By clicking on ‘**Select Filters**’, the user can apply a set of hierarchy filters to get the list of the articles (Style Color IDs or Styles). Refer to the table below for filter details. Mainly product-related filters are to be present on this screen. Higher level store filter can be added maybe channel or country.

**fc_name : Allocation**

| **Section** | **Filter Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Mandatory** | **Selection Criteria** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Single select |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Multi select |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Store | {S0 Name} | s0_name | global.store_attributes_filter | varchar | No | No | Multi select |

### **Details Table:**

The Details table shows the Style Color (article or style) level information including Product Hierarchies, Demand Type, Product Profile, Size Profile, Store Eligibility Groups, Eligible Stores, and DC inventory. Only those Style Colors (articles or styles) should populate in the Details table which follows the following conditions:

1. Products should be active.
2. Should have active product store mapping
3. Should have active product DC mapping
4. Should have active store DC mapping
5. Should have the constraints data for the product store combinations
6. Should have the Available to Allocate (ATA) > 0

The below table explains the '**Details'** table schema along with the use case of each column.

**tc_name : inventorysmart_strategy_table**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Description** | **Editable(Yes/No)/\[Single/Multi   Select\]** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Style/Style Color ID} | article | inventory_smart.article_inventory_dashboard | varchar | No | Product Hierarchy | No | Yes | Yes |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Product Hierarchy | No | Yes | Yes |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Product Hierarchy | No | Yes | Yes |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | Product Hierarchy | No | Yes | Yes |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | Product Hierarchy | No | Yes | Yes |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | Product Hierarchy | No | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | global.product_attributes_filter | varchar / date | Yes | Product Attributes | No | Yes | Yes |
| Custom | Product Life Cycle | product_type or article_status_tag | inventory_smart.article_status_tag | varchar | No | Column related to lifecycle of the product | No | Yes | Yes |
| Custom | Last Allocated |  last_allocation_date | inventory_smart.last_allocation_date_table | date | Yes | The date on which the article was allocated   previously | No | No | No |
| Custom | Demand Type |   |  |  |  | Indicates whether allocation should be based on the IA forecast, or a Fixed percentage of net available inventory or APS(Average per Store). By default IA forecast should be selected. Possible values:  
1\. IA Forecast (Default)  
2\. Fixed  
3\. APS (Optional) | Single Select | No | No |
| Custom | Prioritization Strategy |  |  |  |  | Indicates the prioritization strategy. The default strategy will be IA Priority or will be picked from the DC Store Policy. Possible values:  
1\. IA Priority (Default)  
2\. Fair Share This is optional field  | Single Select | No | No |
| Custom | Allocation Strategy |  |  |  |  | Indicates the allocation strategy. The default strategy will be “Min First and then WOS” or will be picked from the DC Store Policy. Possible values:  
1\. Min First and then WOS (Default)  
2\. Min Only  
3\. WOS Only This is optional field  | Single Select from dropdown options: “Min Only”, “WOS Only”, “Min First and then WOS” | No | No |
| Custom | Target WOS |  |  |  |  | Panned target WOS | Yes | No | No |
| Custom | Product Profile |   |  |  |  | The   size curve values will be used during allocation to distribute demand   estimates across sizes and stores. Will indicate if this is “IA Recommended”   or “User Created”. Possible Values:  
1\. IA Recommended  
2\. {User Created Product Profile Name} - This will show only if the user created product profile is mapped in the DC Store Policy → DC Store Strategy If user created product profile is mapped then IA-recommended should show in dropdown | Single Select Dropdown - Default value will be   IA-Recommended or the user created product profile mapped in the DC to Store Policy. | No | No |
| Custom | Size Profile |   |  |  |  | The list of sizes for which the allocation will be carried out. Unselecting this checkbox should update the DC Available Units to Allocate corresponding columns. If the Product Status screen has a Style that has one SKU completely inactive and the Style is active, it should by default have a selection for only the sizes that are active and the size that is inactive should be shown in the dropdown but should not be selected. Ex: If a style has 5 sizes, and 2 of them are active, all the 5 can be shown in the dropdown but SKUs can be selected from only 2 active ones. The DC ATA should be aggregation only for the selected active sizes. | Multi Select Dropdown | No | No |
| Custom | Store Eligibility Groups |   |  |  |  | Group of eligible stores to which the Style needs to be allocated. Possible Values  
1\. Default Mapping  
2\. {User Created Store Group mapped in DC Store Policy} The User-Created Store Groups mapped in DC Store Policy → DC Store Strategy should be attached and available to be attached | Multi Select Dropdown - Default value is the default store for selected channel or country | No | No |
| Custom | No. Eligible Stores |   |  |  |  | Number of eligible stores for the article based on the store group selected | No | No | No |
| Custom | Inv. Source |   |  |  |  | Source from which inventory will be consumed for allocation. Possible Values:  
1\. DC Inv. On Hand - Default for DC based allocation  
2\.  PO Inv - Default for for PO based allocation.  
3\. DC Inv. In Transit - Available for selected if required by client | Single Select Dropdown | No | No |
| Custom | DC / ASN |  |  |  |  | DC from which the article should be allocated Default value will be taken from the DC Product Mapping. If no mapping is there then the style will not show up in the Details table. All the mapped DCs from product dc mapping should be selected | Multi Select Dropdown | No | No |
| Custom | DC Inv On Hand |  | inventory_smart.sku_dc_available_units | int4 | No | The total DC inventory at the beginning of the day. This will show the inventory for all the sizes whether the size is selected or not. If a size is unselected then the inventory will still remain the same | No | No | No |
| Custom | Beginning Available to Allocate (Eaches) |  | inventory_smart.dc_pack_inventory | int4 | No | The total DC inventory of eaches which is available to allocate at the beginning of the day. This will show only the inventory for the sizes which are selected in the Size Profile column. If a size is unselected then the inventory will adjust to remove the inventory of unselected size Optional. In case, the packs are not there then not required | No | No | No |
| Custom | Beginning Available to Allocate (Packs) |  | inventory_smart.dc_pack_inventory | int4 | No | The total DC inventory of packs which is available to allocate at the beginning of the day. This will show only the inventory for the sizes which are selected in the Size Profile column. If a size is unselected then the inventory will adjust to remove the inventory of unselected size Optional. In case, the packs are not there then not required | No | No | No |
| Custom | Beginning Available to Allocate |  | inventory_smart.dc_pack_inventory | int4 | No | The total DC inventory which is available to allocate at the beginning of the day. This will show only the inventory for the sizes which are selected in the Size Profile column. If a size is unselected then the inventory will adjust to remove the inventory of unselected size Optional. In case, columns Beginning Available to Allocate (Eaches) and Beginning Available to Allocate (Packs) are there then this is not required. Otherwise this is mandatory | No | No | No |
| Custom | Reserve Quantity at DC |  | inventory_smart.sku_dc_reserved_units | int4 | No | Units of inventory reserved for the article (Can be referred from the User Reserve section in the Constraints Module, Constraints -> User Reserve) | No | No | No |
| Custom | Allocation Reserve Quantity |  | inventory_smart.sku_dc_allocated_units | int4 | No | Total Allocated Quantity for each article from the earlier allocations created on the same day. | No | No | No |
| Custom | Current Available to Allocate |  |  |  |  | (Beginning Available to Allocate) - (User   Reserved + Allocated Units). This is the net inventory available for   allocation after deducting the reserved units. | No | No | No |
| Custom | User Defined Inv. in % |  |  |  |  | Units of Inventory in percentage are to be pushed to stores during allocation. This is relevant for scenarios where Demand-Type is chosen as Fixed. | Yes (Only if Demand-Type is Fixed) | No | No |
| Custom | Fixed Inv. Push |   |  |  |  | Units of Inventory are to be pushed to stores during allocation. This is relevant for scenarios where the Demand Type is chosen as Fixed. | Yes (Only if Demand-Type is Fixed) | No | No |
| Custom | Fixed Qty to   Allocate  |   |  |  |  | Fixed units of inventory for allocation | No | No | No    |
| Custom | Planned APS |  |  |  |  | Average per Store (APS) value for the article or style color ID that needs to be pushed Optional editable field. Required only in case the Demand Type is APS | Yes | No | No |
| Custom | {Metric 1} | metric_1 | inventory_smart.article_inventory_dashboard | int4 / float4 | No | Some metrics for the article or style color ID being allocated. The reference column should be present in the article_inventory_dashboard and the fwos_sku_store. The accepted metrics - LW sales unit, revenue, margin, discount percentage, AUR | No | No | No |
| Custom | {Metric 2} | metric_1 | inventory_smart.article_inventory_dashboard | int4 / float4 | No | Same as Metric 1 | No | No | No |
| Custom | {Metric 3} | metric_1 | inventory_smart.article_inventory_dashboard | int4 / float4 | No | Same as Metric 1 | No | No | No |

The user can select the required style colors (article or styles) and proceed.

**Set All** Option can be used to input the editable columns to multiple selected style color (article or styles) in bulk. **The following options should be available in Set All:**

* Target WOS
* Store Eligibility Groups
* DC / ASN
* Demand Type (Dropdown with values “Fixed”, “IA Forecast”, “APS”)
* User Defined Inventory % (input allowed only when Demand Type selection is “Fixed”; maximum allowed value is 100%)
* Planned APS (input allowed only when Demand Type selection is “APS”)

### **Review Forecast**

User can select one or more products and click on **Review Forecast** button to review the forecast.

**Flow:**

1. Select article → click **Review Forecast**
2. **Forecast side panel** opens

    * Shows **KPIs**, **Graph**, and **"Go to ADA Dashboard"** button
    
3. If the user clicks **“Go to ADA Dashboard”** → modal appears:
4. Click Yes → Redirect to **ADA Visual Module**

The ‘**Review Forecast’**  option leads the user to the **ADA Visual** module and facilitates the view/edit of the forecast. It opens up a new window to the **ADA Visual Module** → **Adjusted Forecast** section.

Clicking **"Review Forecast"** after selecting an article opens a **forecast side panel**. 

* The side panel includes:

    * **KPIs**:
    
        * IA Recommended Forecast
        * Adjusted Forecast
        
    * **Forecast Visualization Graph**:
    
        * X-axis: Weekly buckets (e.g., 202623 to 202630)
        * Y-axis: Sales Units
        * Three lines:
        
            * Final Forecast
            * Adjusted User Forecast
            * Plan Data (MFP Data)
            
        
    
* **Filter Controls** are available at the top of the side panel (as shown in the screenshot):

    * Users can select one or more **Style Color IDs**, **Store Names**, and **SKUs**
    * The KPIs and graph dynamically update based on the selected filters
    
* A **“Go to ADA Dashboard”** button is available at the bottom of the panel.
* Clicking that button shows a **confirmation modal** with the message:  
  _“Changes made will be discarded on redirecting to review the forecast. Are you sure you want to continue?”_
* If the user confirms, they are redirected to the **ADA Visual Module**, pre-filtered for the selected article.

### **Go to Review Store and DC:**

Clicking on **Go to Review Store and** **DC** will move the allocation flow to the 2nd step. A table at the Style Color-Store (article or styles-Store) level, containing store details and DC inventory details should load. The constraints are visible in this table and the user has an option to make temporary edits.

### **Acceptance Criteria:**

1. Users should be able to access the Manual Allocations feature from the CNA.
2. Users should be able to create new allocations manually.
3. The system should allow users to make temporary changes to constraints and configuration options.
4. The changes should only be applicable for the active allocation and should revert once the allocation is finalized.
5. The SKU/sizes to be allocated for a style color should be filterable.
6. Once an allocation is finalized, the Available to Allocate in the DC and the store inventory should update to reflect the allocated quantity.
7. The Global filters should work as per the added table
8. Users should be able to enter the Allocation Plan Name.
9. Users should be able to apply the selected filters.
10. Users should be able to review the table populated.
11. The Details table should show Style Color level information including Product Hierarchies, Demand Type, Product Profile, Size Profile, Store Eligibility Groups, Eligible Stores, and DC inventory.
12. Only Active Styles (Allocation Eligible) should be shown in the Details table.
13. The table schema should include columns as per the above table
14. Each column should have appropriate editability, searchability, and sort ability attributes.
15. Beginning Available to Allocate, Allocated Quantity and Current Available to Allocate should change based on size selection and Supplying DC selection.
16. Filter to load - 1-2s, Screen to load after applying the filters - 3-5s, Set All for small volume - 3-5s and for large volume - 10-15s.

# **User Story 2 - Review Store and DC:**

## **Jira Summary: \[Client Name\] - Create New Allocation -> Review Store and DC**

## **Jira Description:**

This story explains the details of the Review Store and DC. After selecting the Style Color IDs (articles or styles), user can click on Review Store and DC, this will move to 2nd step of the allocation flow. The screen should load 2 tabs - 

1. **Store Details** - This contains the inventory, min, max, WOS, size and contributions, aggregated demand at store level
2. **Inv. Source** - This contains the available, allocated and reserved units at DC or PO level

**Note:** The Style-Store and SKU-Store eligibility, is layered on top of the selections (Size Profile, Store Eligibility Groups) along with the DC Product, DC Status, etc modules in Details table when the user clicks on the "Review Store and DC" button in the Front end. If in case only a few SKUs are active in a Style, the data shown in the Review Store and DC should only consider the active SKUs.

The Review Store and DC is a Style Color (article or style) - Store level table. The user can select the required style color (article or style) from the dropdown and review the Store level properties and Inv Source details populated in the table below. 

### Store Details:

The Store Details table should load with the following columns:

**tc_name : inventorysmart_review_store**

| **Section** | **Column Name** | **Mapping column** | **Mapping Table** | **Data Type** | **Nullable** | **Description** | **Editable(Yes/No)/\[Single/Multi Select\]** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Store | Store Number | store_code | inventory_smart.article_inventory_dashboard | varchar | No | Store Hierarchy | No | Yes | Yes |
| Store | Store Name | store_name | global.store_attributes_filter | varchar | No | Store Hierarchy | No | Yes | Yes |
| Store | {Store Grade or Tier} | grade | inventory_smart.article_inventory_dashboard | varchar | No | Store grade for given article-Store combination. | No | Yes | Yes |
| Custom | Overall Proportion (%) |  | inventory_smart.product_profile_mapping | float4 | No | % contribution of the store to the overall sales of the Style. The overall proportion should be reflecting according to the active styles selected in the details table. | No | No | Yes |
| Custom | Size to overall store contribution% |  | inventory_smart.product_profile_mapping | float4 | No | % contribution of a size to the article-Store based on sales $ (forecasts). The size to overall store contribution should be reflected according to the active styles selected in the details table. | No | No | Yes |
| Custom | Like Store |  | global.store_attributes_filter | varchar | No | Similar Store. The constraints and product profile details can be borrowed from a similar store temporarily for the allocation. Default (Mapped to Self). The dropdown should show all the eligible stores | Single Select Dropdown | No | No |
| Custom | Min |  | inventory_smart.rcl_constraint_master | int4 | No | Min Constraint is the average of Mins of all the sizes present in the article at store level | Yes | No | Yes |
| Custom | Max |  | inventory_smart.rcl_constraint_master | int4 | No | Min Constraint is the average of Max of all the sizes present in the article at store level | Yes | No | Yes |
| Custom | Aggregated Min |  | Calculated |  |  | Sum of mins constraint of all the sizes present in the article at store level | No | No | Yes |
| Custom | Aggregated Max |  | Calculated |  |  | Sum of max constraint of all the sizes present in the article at store level | No | No | Yes |
| Custom | ROS |  |  |  |  | Performance metrics are used to measure the rate of sales at the store and style level (Based on forecast) | Yes | Yes | Yes |
| Custom | WOS |  | inventory_smart.rcl_constraint_master | int4 | No | Forward Weeks Of Supply. | Yes | Yes | Yes |
| Custom | Estimated Demand |  |  |  |  | IA weekly forecast units aggregated based on the WOS defined. (See the Demand Calculation section) | No | Yes | Yes |
| Custom | Transit Time |  | inventory_smart.dc_transit_time_mapping | int4 | No | The estimated time taken (in days) for units to reach from DC to the store. If multiple DCs are chosen with different transit times for each DC, the max transit time will be displayed. | No | No | Yes |
| Custom | Store On Hand |  | inventory_smart.latest_inventory | int4 | No | On-hand units at Stores (aggregated across stores). | No | No | Yes |
| Custom | Store On Order |  | inventory_smart.latest_inventory | int4 | No | On-order units to Stores (aggregated across stores). | No | No | Yes |
| Custom | Store In Transit |  | inventory_smart.latest_inventory | int4 | No | In-transit units to Stores (aggregated across stores). | No | No | Yes |
| Custom | Oh + IT + OO |  | inventory_smart.latest_inventory | int4 | No | Sum of On hand, In transit and On order | No | No | Yes |

At the top of the table, Allocation Plan Name will show. if nothing is added in the previous step then it will show **N/A.**

Below there, **Total Estimated Demand: XXX** and **#stores eligible for allocation: N** should show up. With the selection or deselection of stores, this N and XXX value should change. By default all the stores of selected store group should be selected and the count.

Users can edit the Min, Max, WOS and Like store using the inline for the stores for the selected style colors. To edit for multiple stores, users can use the **Set All** options.

Users can save the draft of the allocation details using the option ‘**Save as Draft**’.  It can be accessed by the user from the **Dashboard -> View Allocation Plans section** module later.

Newly added

Sizes are displayed in a standardized order. If pack information is available, items are first grouped by pack, and then by eaches. In the absence of pack information, only the standardized sizing order is applied (Derived table should be available to enable this where size order is maintained)

### Inv. Source:

Users can View in the Inv Source section, which provides details about the DC Available Inv, DC Reserved Units, and Allocated Units. The table will show source inventory for one style-color ID at a time. The selection at the top of the table can be used to select another style-color ID.

The Inv. Source table should have the following Columns:

**tc_name : inventorysmart_dc_level_metrics**

| **Section** | **Column Name** | **Mapping column** | **Description** | **Editable(Yes/No)/\[Single/Multi Select\]** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- |
| Store | DC Code | dc_code | DC Code | No | No | No |
| Store | DC Name | name | Name from distribution_centres | No | No | No |
| Custom | Available Inventory |  | Available inventory at size level. There should be one column for each size | No | No | No |
| Custom | Quantity Reserved |  | Reserved inventory at size level. There should be one column for each size | No | No | No |
| Custom | Allocated Units |  | allocated inventory on the same day at size level. There should be one column for each size | No | No | No |

Lastly, the user can select the required stores and proceed with the allocation using the option → **Create Allocation.**  
When clicked on the Create Allocation button in the backend, the payload should also consider DC-Store mapping, DC-Product mapping, Product-Store mapping, Product Status, DC Status and Store Status for the final eligibility.

Newly added

Sizes are displayed in a standardized order. If pack information is available, items are first grouped by pack, and then by eaches. In the absence of pack information, only the standardized sizing order is applied (Derived table should be available to enable this where size order is maintained)

### **Acceptance Criteria:**

1. The Overall Proportion/Size-level Proportion values should be adjusted according to the size profile selected in the CNA details table.
2. Users should be able to select the required style Color and proceed.
3. Users should be able to use the 'Set All' option to input editable columns to multiple selected style color in bulk.
4. Users should be able to review the Store level properties and Inv Source details populated in the table.
5. The table schema should include columns as per above table
6. Users should be able to bulk edit values for multiple stores and save the draft of the allocation details.
7. Users should be able to view details about the DC Available Inv, DC Reserved Units, and Allocated Units in the Inv Source section.
8. Users should be able to proceed with the allocation using the 'Create Allocation' option.

**Performance Expectations:**

1. Should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.
2. Only filtered products and stores should be visible on the screen
3. Filters to load - 1-2s, Screen to load after applying filters - 3-5s, Navigating from one screen to another - 2-3s, Row update and save changes - 2-3s, and Bulk Updates or Set All - Small volume: within 3-5s Large volume: within 10-15s

# **User Story 3 - CNA Pre and Post Processing:**

## **Jira Summary: \[Client Name\] - Create New Allocation → Pre and Post Processing**

## **Jira Description:**

This story is more from a backend point of view. Post clicking on the Review Store and DC, a payload is created (Pre Processing) based on the inputs and edits made on the tool. The payload is then sent to the optimizer. The optimizer process the data and generates the allocation output. The optimizer output is then processed (Post Processing) and the results will be shown on the tool.

For Create New Allocation, following process should be considered in pre and post processing:

* **Demand Type** - The possible options for the demand type are IA Forecast, Fixed and APS (optional). By default, IA Forecast should be used.
* **Allocation for PO or ASN** - This would be valid only in case the user is redirected from the PO to Allocate or ASN to Allocate Alerts. The **Inv. Source** column in this case should be **PO or ASN** by default.
* **Reserve Quantity at DC column in CNA -> Details** - In case of PO or DC allocation if there is some reservation done in Constraints screen, that should show up in the **Reserve Quantity at DC** column
* **Size Profile** - By default all the eligible Size should be selected in the Size profile. Selecting and deselecting the sizes should adjust the Available to allocate inventory
* **DC Selection** - By default all the eligible DCs should be selected in the DC. Selecting and removing the DC should adjust the Available to allocate inventory. DC prioritization should be handled from backend either by using the Rank or transit time.  
  **NOTE:** If DC rank is there the rank api of gurobi will be used. If there is no ranking then the non rank api will be used.
* **Default Store Groups** - {Add the logic for default store group. If allocations are happening at channel level or country level or region level separately then separate store groups should be there for each channel or country or region. If the allocation is happening for all channels or stores at once then only one default store group is needed.}:

    The User-Created Store Groups should be available to be attached to the article in the Allocation flow: CNA → Details table → Store Eligibility Groups  
    The User-Created Store Groups should be available to be attached to the rules in the DC- Store Policy → DC - Store Strategy table → Store/Store Groups Mapped column hyperlink. By default, the rule should have the default auto-allocations and eligible store groups mapped


* **Product Profile** - By default the **IA Recommended** product profile should be selected. The User Created Product Profile should be available to be mapped in the Details Screen → Product Profile as well as the DC - Store Strategy table → Product Profile column.
* **Prioritization Strategy** - If the column is there in the Details table of CNA and some edits are made then that Prioritization Strategy should be used for allocation else the Prioritization Strategy from the DC Store Policy → DC Store Strategy should be used. If both are not there then the default strategy of **IA Priority** should be used.
* **Allocation Strategy** - If the column is there in the Details table of CNA and some edits are made then that Allocation Strategy should be used for allocation else the Allocation Strategy from the DC Store Policy → DC Store Strategy should be used. If both are not there then the default strategy of **Min First and then WOS** should be used.
* **Cost of overallocation and under allocation** - By default the cost of overallocation and under allocation is same. Based on the client requirement the penalty can adjusted.
* **UOM (Units of Measurement) or Case Pack (Same size pack) rounding** - In case, if there is case pack and the allocated quantity needs to be rounded to the nearest case pack quantity based on a threshold value (X %). By default, the  threshold value is 50%.

### Sample Allocation Payload

As per clients use case, connect with the developer and get the below payload filled:

```
{  
    "folder_path": "gs://lovisa-inventorysmart-test/lovisa-inventorysmart-gurobi-files/6_1_0_NONESPECIFIED_20250326T124644",
    "project": "lovisa-09012025",
    "NO_PACKS_FLAG": To be created based on input data,
    "multiple_article_pack": false,
    "fo_min": 0,
    "fu_min": 1,
    "fo_demand": 1,
    "fu_demand": 1,
    "store_pack_filter": false,
    "article_newness_flag": false,
    "platform": "server",
    "tool_mode": "web",
    "model_name": "mod_x_two_step_model",
    "uuid_str": "6_1_0_NONESPECIFIED_20250326T124644",
    "only_solve_min_req": false,
    "mipgap": 5e-05,
    "use_weekly_optimization": false,
    "remove_store_cap_in_week_calc": false,
    "set_lb_after_week_calc": false,
    "callbackURL": "https://lovisa.test.impactsmartsuite.com/api/v3/inventory-smart/simulation/create-allocation",
    "callback_token": "AIzaSyCBhCMZqJIr6eW1oPfrZ289iwUVMeB92g4",
    "hard_max_for_min": false,
    "hard_max_for_demand": false,
    "fixed_inv_push_flag": true,
    "min_priority_for_fixed_inv": false,
    "allocate_after_cutoff_wos": true,
    "reshuffle_allocation": true,
    "store_grade_flag": true
}
```

Most of the parameters will remain. There will be some changes based on dc ranking or cost of over allocation and under allocation

# **User Story 4 - Recommendation Screen:**

## **Jira Summary: \[Client Name\] - Create New Allocation → Recommendation Screen**

## **Jira Description:**

Once the allocation is created, the user will receive a notification. Clicking on the allocation notification from the bell icon, user will land on the Create New Allocation → Recommendation screen, the 3rd step of allocation flow. The user can view/edit the allocation that has been created in the ‘**Recommendation’** screens.

The user can navigate to this screen from the Decision Dashboard → View Allocation Plan also. User can select any created allocation and click on edit icon to move to the Recommendation screen.

The Recommendation Screen contains three tabs namely - **Product View, Store View, and Store Capacity**. (**Store Capacity is optional and is covered in another page)**

### Product View:

The Product View tab should be the default landing page. There should be 2 sections here:

1. **Summary** - This section should show the KPIs for the current allocation.
2. **Product Details** - This will show the allocated quantity and the metrics at Style color (article or style) level. Upon clicking the hyperlinks in this table, **Net DC available** KPI and **Product-Store Details** table should populate:

    1. **Net DC Available | {Style Color ID}** - This should show the KPI card for DCs that could be expanded, which shows list of sizes available in the DC.
    2. **Product-Store Details | {Style Color ID}** - This will contains the allocated quantity and metrics at store level for the selected Style color (article or style).
    

**Summary -** Following KPIs should be present in the **Summary**:

| **KPI Name** | **Mapping Column** | **Icon** | **Description** | **Aggregation Logic** | **Specific Custom Dimension** |
| --- | --- | --- | --- | --- | --- |
| # Style Color ID | create_allocation_result_flat_gurobi - article | AP1 | Count of total style color for which allocation plan is created |  |  |
| #  Allocated Stores | create_allocation_result_flat_gurobi - store | S01 | Count of stores where at least one unit is allocated |  |  |
| # Eligible Stores | create_allocation_result_flat_gurobi - store | S02 | Count of Stores which are eligible for the current plan allocation |  |  |
| Allocated Stores per Style Color | Calculated | S02 | Stores allocated per style color |  |  |
| DC Allocated Quantity (By Size) | Views | WH1 | The KPI tile should show Allocated units for each DC with expandable option to size allocated quantity at size level Size DC level quantity allocated. For example, if a style color has 3 sizes, and is allocated from two DCs, then 2 DCs should show |  |  |
| Total Allocated Qty | Views | ST3 | Total allocated quantity in the current plan |  |  |
| Remaining DC Available | Views | WH4 | The KPI tile should show remaining DC available units for each DC after allocation DC remaining available to allocate inventory post allocation  |  |  |
| LW Sales Units | article_inventory_dashboard - sales_1_ago | PC1 | Total net sale units in last fiscal week | sum(sales_1_ago) | AID |
| LW Margin | article_inventory_dashboard - lw_margin | PT1 | Total sales margin in last fiscal week | sum(lw_margin) | AID |

For icon selection, please refer to this Figma: [Link](https://www.figma.com/design/ezAXlChtdLssXuiW5tB2PT/InventorySmart_3d-Icon-Set?node-id=2157-84&t=y8gARSrmX3qSctAJ-0)

**Product Details -** The table should populate with following columns:

**tc_name  : inventorysmart_finalize_product_details**

| **Section** | **Column Name** | **Mapping Column** | **Description** | **Editable(Yes/No)/\[Single/Multi   Select\]** | **Searchable** | **Sortable** | **Aggregation Logic** | **Specific Custom Dimension** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Style/Style Color ID} | article | Product Hierarchy. Hyperlink which will open a table at store level | No | Yes | Yes |  |  |
| Product | {L0 Name} | l0_name | Product Hierarchy | No | Yes | Yes |  |  |
| Product | {L1 Name} | l1_name | Product Hierarchy | No | Yes | Yes |  |  |
| Product | {L2 Name} | l2_name | Product Hierarchy | No | Yes | Yes |  |  |
| Product | {L3 Name} | l3_name | Product Hierarchy | No | Yes | Yes |  |  |
| Product | {L4 Name} | l4_name | Product Hierarchy | No | Yes | Yes |  |  |
| Product | {Product Attributes} | {product_attribute} | Product Attributes | No | Yes | Yes |  |  |
| Custom | Demand Type |  | The demand type selected for allocation | No | Yes | Yes |  | carfg |
| Custom | # Eligible Stores |  | Number of stores eligible for allocation for the style color | No | Yes | Yes |  |  |
| Custom | # Allocated Stores |  | Number of stores allocated for the style color | No | Yes | Yes |  |  |
| Custom | Aggregated Min |  | Aggregated Min quantity for the style color | No | Yes | Yes |  | carfg |
| Custom | Aggregated Max |  | Aggregated Max quantity for the style color | No | Yes | Yes |  | carfg |
| Custom | Aggregated Demand (For the Target WOS) |  | The demand calculated based on the min, max and forecast | No | Yes | Yes |  | carfg |
| Custom | Target WOS |  | The target forward WOS | No | Yes | Yes |  | carfg |
| Custom | Store OH |  | Store onhand inventory | No | Yes | Yes |  | carfg |
| Custom | Store IT |  | Store intransit inventory | No | Yes | Yes |  | carfg |
| Custom | Store OO |  | Store onorder inventory | No | Yes | Yes |  | carfg |
| Custom | Store OH + OO + IT |  | Total store inventory | No | Yes | Yes |  | carfg |
| Custom | Total Allocated Quantity |  | Total allocated quantity for the style color | No | Yes | Yes |  | carfg |
| Custom | LW Sales Units | sales_1_ago | Total net sale units in last fiscal week | No | No | Yes | sum(sales_1_ago) | AID |
| Custom | LW Margin | lw_margin | Total sales margin in last fiscal week | No | No | Yes | sum(lw_margin) | AID |
| Custom | Remaining DC Available to Allocate |  | Remaining available to allocate at Style Color across DCs | No | Yes | Yes |  |  |
| Custom | Allocation Retail Value ($) |  | Allocated Quantity \* Cost To be enabled only if Cost is available in Product Master | No | Yes | Yes |  |  |
| Custom | Allocated Quantity (by Size) |  | Separate column for each DC - size combination Size level allocated quantity for the style color at size DC level. For example, if a style color has 3 sizes, and is allocated from two DCs, then there will be a total of 6 columns | No | Yes | Yes |  |  |
| Custom | Allocation % (By Size) |  | Allocation units in percentage at size level | No | Yes | Yes |  |  |
| Custom | Remaining DC Available to Allocate |  | Separate column for each DC - Eaches/Packs Remaining available to allocate at Style Color | No | Yes | Yes |  |  |
| Custom | Allocation Pack Quantity |  | Separate column for each DC - Eaches/Packs Allocated Quantity at Style Color | Yes (in edit mode) | Yes | Yes |  |  |

Users can click on relevant hyperlinks in the Style Color ID column. A new table will appear showing the DC and store distribution for the respective Style-Color.

New addition

**Users should be able to perform Higher-Level Edits in this table-**  Allocation Pack Quantity columns must be available at the DC / Packs and DC / Eaches level to display the total allocated quantity for a style-color.

* Users are only allowed to **decrease** the allocated quantity; they cannot increase it. If a user attempts to increase the allocation, a **warning message** should appear
* Edits are allowed only at the **total level**  at **Product details**, not at the **individual size level**. The individual size view is provided solely for **reviewing changes at the size level** without requiring users to scroll down.
* After making updates, users can **save their changes** by clicking the **Apply** button.
* These updates will be stored **temporarily**, and any changes made at the higher level will be **translated down to the lower level** (Style-Color → Store → Size → DC) for both **packs** and **eaches**.
* Users can review the updated numbers at the lower level by scrolling down the screen. Please ensure that when the **allocated quantity is decreased** for a given **style-color, pack/size, Store level**, the corresponding **DC numbers** are adjusted accordingly.
* When edits are in progress at the **higher level**, all **lower-level edits** must be **disabled** to avoid conflicts. Lower-level edits should only be enabled **after the higher-level changes are completed and applied locally**.
* Changes become **permanent** only after a **Global Save**, at which point they cannot be reverted. When performing a permanent save, users should be shown a **warning message** indicating that the change is final and cannot be undone.

‌

**Net DC Available | {Style Color ID} -** Along side this Style Color ID, the selected Style Color ID should show. Below this there should be KPI card for DC available inventory.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=e78133632ab0&id=0e7b761a-3537-46aa-87b3-11a79e2a4dff&&collection=contentId-2696611283&height=484&occurrenceKey=null&width=1103&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
For each DC, total remaining available inventory post allocation should show up. The expandable option should be there to show the DC inventory at size level.

![](blob:https://media.staging.atl-paas.net/?type=file&localId=380f5d182e0d&id=5b877996-107f-407b-8e92-bc501b20f347&&collection=contentId-2696611283&height=475&occurrenceKey=null&width=1090&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
‌

**Product-Store Details | {Style Color ID} -** Along side this Style Color ID, the selected Style Color ID should show. Below this, the table at Style Color Store level should load with following columns:

**tc_name : inventorysmart_finalize_store_product**

| **Section** | **Column Name** | **Mapping column** | **Description** | **Editable(Yes/No)/\[Single/Multi Select\]** | **Searchable** | **Sortable** | **Aggregation Logic** | **Specific Custom Dimension** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Store | Store Number | store_code | Store Code | No | Yes | Yes |  |  |
| Store | Store Name | store_name | Store Name | No | Yes | Yes |  |  |
| Store | {Store Grade or Tier} | grade | Store grade for given article-Store combination. | No | Yes | Yes |  | carfg |
| Custom | Aggregated Demand (For the Target WOS) |  | The demand calculated based on the min, max and forecast at style color store level | No | Yes | Yes |  | carfg |
| Custom | Target WOS | wos | The target forward WOS | No | Yes | Yes |  | carfg |
| Custom | Forecasted WOS |  | Forecasted WOS based on the allocated qty | No | Yes | Yes |  |  |
| Custom | Store OH |  | Store onhand inventory | No | Yes | Yes |  | carfg |
| Custom | Store IT |  | Store intransit inventory | No | Yes | Yes |  | carfg |
| Custom | Store OO |  | Store onorder inventory | No | Yes | Yes |  | carfg |
| Custom | Store OH + OO + IT |  | Total store inventory | No | Yes | Yes |  | carfg |
| Custom | Allocated for Min |  | Quantity allocated to fulfill the Mins constraint | No | Yes | Yes |  | carfg |
| Custom | Allocated for Demand |  | Quantity allocated for the demand | No | Yes | Yes |  | carfg |
| Custom | Allocated Total Qty |  | Total quantity allocated | No | Yes | Yes |  |  |
| Custom | Total Allocated  Qty + OH |  | Total quantity allocated + Store OH | No | Yes | Yes |  |  |
| Custom | Aggregated Min |  | Min for the style color store | No | Yes | Yes |  | carfg |
| Custom | Aggregated Max |  | Max for the style color store | No | Yes | Yes |  | carfg |
| Custom | Delivery Date |  | The date when the allocated units are to be delivered to stores | Yes | No | No |  | carfg |
| Custom | Allocated Pack Quantity |  | Size level allocated quantity for the store at size DC level Separate column for each DC - size combination In the grid user can edit the quantity to be sent to the store | Yes | Yes | Yes |  |  |
| Custom | Allocated Quantity (By Pack-ID) |  | Size level allocated quantity for the store at Pack ID size level Separate column for each Pack ID - size combination | No | Yes | Yes |  |  |
| Custom | Available Pack Quantity |  | The net DC available inventory post allocation Separate column for each DC-Pack ID - size combination | No | Yes | Yes |  |  |

From the above table users can select the relevant stores to edit. Users can select a single store/multiple stores by clicking on the **‘Edit’** icon/ **Bulk Edit** to edit the editable metrics namely the Allocated quantity, and the Delivery Date, and click on **Save** to save the changes.

New changes

Sizes are displayed in a standardized order. If pack information is available, items are first grouped by pack, and then by eaches. In the absence of pack information, only the standardized sizing order is applied (Derived table should be available to enable this where size order is maintained)

‌

User can also do bulk edits of columns Allocated Size Quantity and Delivery Date, using **“Bulk Edit”.** Once all required updates are done, click on **Save** to save the edits. And Once done, click on **Move to Order Batching** or **Finalize**.

### Store View:

Click on the ‘**Store View**’ tab to view the **Allocation Summary** and **Store level distribution** at store level. There should be 2 sections here:

1. **Summary** - This section should show the KPIs for the current allocation.
2. **Store Details** - This will show the allocated quantity and the metrics at Store level. Upon clicking the store hyperlinks in this table 1 more table will populate:

    1. **Store-product details | Store Code:** {store_code} - This will be same as the Product View → Article Details except that it will have data only for the selected store. The rest of the flow will remain same. Clicking the hyperlinks in this table will load 2 more tables:
    
        1. **Net DC Available | {Style Color ID}** - This should show the KPI card for DCs that could be expanded, which shows list of sizes available in the DC.
        2. **Product-Store Details | {Style Color ID}** - This will contains the allocated quantity and metrics at store level for the selected Style color (article or style).
        
    

**Summary -** Following KPIs should be present in the **Summary**:

| **KPI Name** | **Mapping Column** | Icon | **Description** | **Aggregation Logic** | **Specific Custom Dimension** |
| --- | --- | --- | --- | --- | --- |
| # Allocated Style-Colors | create_allocation_result_flat_gurobi - article | AP1 | Count of total style color for which allocation plan is created |  |  |
| #  Allocated Stores | create_allocation_result_flat_gurobi - store | S01 | Count of stores where at least one unit is allocated |  |  |
| Style Color Depth per Store | create_allocation_result_flat_gurobi | ST2 | Average Style Color allocated per store |  |  |
| Average units per Store | create_allocation_result_flat_gurobi | PR1 | Average units allocated per store |  |  |
| Allocated Size Quantity | create_allocation_result_flat_gurobi | WH1 | Size DC level quantity allocated |  |  |
| Total Allocated Quantity | create_allocation_result_flat_gurobi | ST3 | Total quantity allocated for style color |  |  |
| Net DC Available |  | WH4 | DC remaining available to allocate inventory post allocation |  |  |
| Store Tier Allocated Qty | create_allocation_result_flat_gurobi | SG1 | Separate column for each store tier Store Grade level allocated Quantity |  |  |
| Store Tier Allocated Percentage | create_allocation_result_flat_gurobi | SG1 | Separate column for each store tier Store Grade level allocated Quantity in percentage |  |  |
| LW Sales Units | article_inventory_dashboard - sales_1_ago | PC1 | Total net sale units in last fiscal week | sum(sales_1_ago) | AID |
| LW Margin | article_inventory_dashboard - lw_margin | PT1 | Total sales margin in last fiscal week | sum(lw_margin) | AID |

For icon selection, please refer to this Figma: [Link](https://www.figma.com/design/ezAXlChtdLssXuiW5tB2PT/InventorySmart_3d-Icon-Set?node-id=2157-84&t=y8gARSrmX3qSctAJ-0)

**Store Details -** The table should populate with following columns:

**tc_name : inventorysmart_finalize_store_details**

| **Section** | **Column Name** | **Mapping column** | **Description** | **Editable(Yes/No)/\[Single/Multi Select\]** | **Searchable** | **Sortable** | **Aggregation Logic** | **Specific Custom Dimension** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Store | Store Number | store_code | Store Code | No | Yes | Yes |  |  |
| Store | Store Name | store_name | Store Name | No | Yes | Yes |  |  |
| Store | {Store Grade or Tier} | grade | Store grade for given article-Store combination. | No | Yes | Yes |  | carfg |
| Custom | # Allocated Style-Colors | article | Number of Style Color allocated to this store | No | Yes | Yes |  |  |
| Custom | Store On Hand | oh | Current Store on hand inventory | No | Yes | Yes |  | carfg |
| Custom | Store In Transit | it | Current Store in transit inventory | No | Yes | Yes |  | carfg |
| Custom | Store On Order | oo | Current Store on order inventory | No | Yes | Yes |  | carfg |
| Custom | Total Inventory (OH + IT + OO) |  | Sum of OH, IT and OO | No | Yes | Yes |  | carfg |
| Custom | LW Sales Units | sales_1_ago | Total net sale units in last fiscal week | No | No | Yes | sum(sales_1_ago) | AID |
| Custom | LW Margin | lw_margin | Total sales margin in last fiscal week | No | No | Yes | sum(lw_margin) | AID |
| Custom | Aggregated Min |  | Min for the style color store | No | Yes | Yes |  | carfg |
| Custom | Aggregated Max |  | Max for the style color store | No | Yes | Yes |  | carfg |
| Custom | Allocated for Min |  | Quantity allocated to fulfill the Mins constraint | No | Yes | Yes |  | carfg |
| Custom | Allocated for Demand |  | Quantity allocated for the demand | No | Yes | Yes |  | carfg |
| Custom | Aggregated Demand (For the Target WOS) |  | The demand calculated based on the min, max and forecast at style color store level | No | Yes | Yes |  |  |
| Custom | Allocated Total Qty |  | Total quantity allocated at store level across DC’s | No | Yes | Yes |  |  |
| Custom | Allocation Retail Value ($) |  | Allocated Quantity \* Cost To be enabled only if Cost is available in Product Master | No | Yes | Yes |  |  |
| Custom | Allocated Pack Quantity |  | Size level allocated quantity for the store at size DC level across all Stylecolors Separate column for each DC - size combination | Yes (Higher level edit) | Yes | Yes |  |  |

Users can click on the hyperlink present in the Store Number column. A new table will appear showing the Product distribution of the respective product. The format of the tables will be similar to the tables seen in the Product View.

Users can select the relevant stores to edit. Users can select a single store or multiple stores.

Users can click the ‘**Edit**’ icon, to edit the columns namely Allocated Quantity and the Delivery Date. and click on **Save** to save the changes. User can also do bulk edits of columns Allocated Size Quantity and Delivery Date.

Newly added

**Users should be able to perform Higher-Level Edits in this table-**  On the **Store View Screen**, the option to edit at the **higher level** is available for each **individual store**. - in Store Details Screen at individual Store level

* Allocation Pack Quantity should be displayed at the **DC Pack/Eaches level** for each store. Users can make changes at the **total packs** and **eaches level** for individual stores, and those changes should be reflected at the corresponding **style-color, size, and DC level** for that store in both **packs** and **eaches**.
* Users are only allowed to **decrease** the allocated quantity; they cannot increase it. If a user attempts to increase the allocation, a **warning message** should appear
* Edits are allowed only at the **total level**  at **Product details**, not at the **individual size level**. The individual size view is provided solely for **reviewing changes at the size level** without requiring users to scroll down.
* After making updates, users can **save their changes** by clicking the **Apply** button.
* These updates will be stored **temporarily**, and any changes made at the higher level will be **translated down to the lower level** (Style-Color → Store → Size → DC) for both **packs** and **eaches**.
* Users can review the updated numbers at the lower level by scrolling down the screen. Please ensure that when the **allocated quantity is decreased** for a given **style-color, pack/size, Store level**, the corresponding **DC numbers** are adjusted accordingly.
* When edits are in progress at the **higher level**, all **lower-level edits** must be **disabled** to avoid conflicts. Lower-level edits should only be enabled **after the higher-level changes are completed and applied locally**.
* Changes become **permanent** only after a **Global Save**, at which point they cannot be reverted. When performing a permanent save, users should be shown a **warning message** indicating that the change is final and cannot be undone.

Click on **Save** to save the edits. And Once done, click on **Move to Order Batching** or **Finalize**.

### **Acceptance Criteria:**

1. Users should be able to click on the 'Product View' tab to view the Allocation Summary and Product level distribution.
2. **Product View -** The Details Table (Products Summary) should include columns such as # Style, # Allocated Stores, # Eligible Stores, Allocated Stores per Style Color, Allocated Size Quantity, Total Allocated Qty, Net DC Available.
3. **Product View -** The Product Details table should include columns such as Style Color ID, Division, Department, Class, Subclass, Style, Product Life Cycle, Pack ID, Pack Description, Demand Type Used, # Stores, # Allocated Stores, Min Constraint, Max Constraint, Aggregated Demand (For the Target WOS), Target FWOS, Allocated Size Quantity, Remaining DC Available to allocate, Total Allocated Quantity.
4. **Product View -** Users should be able to click on relevant links in the Style Color ID column to view store distribution of the respective products.
5. **Product View -** Users should be able to select relevant stores to edit and save changes.
6. **Product View -** Users should be able to finalize the allocation by clicking on Finalize.
7. Users should be able to click on the 'Store View' tab to view the Allocation Summary and Store level distribution.
8. **Store View -** The Details Table (Stores Summary) should include columns such as # Style Color, # Allocated Stores, Style Color Depth per Store, Avg units per Store, Allocated Size Quantity, Net DC Available, Store Grade - Allocated Qty, Store Grade - Allocated Percentage.
9. **Store View -** The Store Details table should include columns such as Store Code, Store Name, Store Grade, # Style Color, Store On Hand, In transit to Store, Store On Order, OH + OO + IT, Aggre. Min, Aggre. Max, Total Allocated, Oh + OO + IT + Allocated, Allocated for Mins, Allocated for Demand, Target FWOS, Forecasted FWOS.
10. **Store View -** Users should be able to click on the links in the Store Number column to view product distribution of the respective product.
11. **Store View -** Users should be able to select relevant stores to edit and save changes.
12. **Store View -** Users should be able to finalize the allocation by clicking on Finalize.
13. **Higher level edit -** Given the Higher Level Edit feature is enabled, When users make edits at the higher level, Then the changes must cascade automatically down to the lower levels (Style-Color → Store → Size → DC).
14. **Higher level edit -** Given edits are in progress at the higher level, Then all lower-level edits should be disabled until the higher-level edits are applied locally.
15. **Higher level edit -** Given a user applies higher-level edits, Then the system must ensure that only **reductions** are allowed—any attempt to increase values should trigger a warning message and prevent the update.
16. **Higher level edit (Product View) -**In the Product Details screen,users should be able to edit allocations at the **style-color level** for **individual DCs**, with edits available separately for **packs** and **eaches**.
17. **Higher level edit (Store View) -**In the Product Details screen,users should be able to edit allocations at the **store level** for **individual DCs**, with edits available separately for **packs** and **eaches**.

‌

# **User Story 5 - What if Scenario:**

## **Jira Summary: \[Client Name\] - Create New Allocation → Recommendation Screen → What if Scenario**

## **Jira Description:**

As an allocator user, I want to easily create and modify **"What-if" scenarios** within the InventorySmart tool so that I can test different allocation strategies. Specifically, I need the ability to adjust several key parameters to simulate various real-world conditions and see their impact.

* I need to create a new scenario either manually using the 'Create New Allocation - Manual' option, or from  any existing system-generated 'Auto' allocation plan”.
* Once a new scenario is initiated, I want to be able to adjust input parameters such as:

    * **Product Profile** to focus on specific product categories. 
    * **Demand Type** to test how different types of demand affect allocation.
    * **Store Levels** including minimum (Min) stock levels, maximum (Max) stock levels, and weeks of supply (WOS). 
    * **Allocation Strategy** to evaluate different methods of distributing inventory1. (for generic IS, not to be included in carters)
    * **Prioritisation Strategy** to see how different prioritisation rules affect allocation. (for generic IS, not to be included in carters)
    * **Store Group Attached -** Read only. 
    

Additionally I want to see the store groups mapped to a particular product. (read-only). Put it in a comma separated format if more than one store groups are attached. 

**Workflow :**

**Key Functionality:**

1. **Scenario Creation:**

    1. Users can create new allocation scenarios manually or from auto-allocation plans.
    
2. **Adjustable Parameters:**

    1. Product Profile
    2. Demand Type
    3. Constraints at product store level(Min, Max, WOS)
    4. Allocation Strategy
    5. Prioritization Strategy
    
3. **Recommendation Screen:**

    1. A recommendation screen will be provided for users to review and make edits.
    
4. **Scenario Comparison:**

    1. Users can compare scenarios side-by-side, including against original numbers.
    2. A separate capacity breach tab will be available for each scenario.
    
5. **Finalizing Scenarios:**

    1. Finalizing will close the session, delete the scenario, and override original numbers.
    

**Step 1 :**

**Selected Style -** The table should populate with following columns:

**tc_name :** 

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Description** | **Editable(Yes/No)/\[Single/Multi   Select\]** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Style/Style Color ID} | article | inventory_smart.article_inventory_dashboard | varchar | Product Hierarchy | No | Yes | Yes |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | Product Hierarchy | No | Yes | Yes |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | Product Hierarchy | No | Yes | Yes |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | Product Hierarchy | No | Yes | Yes |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | Product Hierarchy | No | Yes | Yes |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | Product Hierarchy | No | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | global.product_attributes_filter | varchar / date | Product Attributes | No | Yes | Yes |
| Custom | Product Profile |   |  |  | The   size curve values will be used during allocation to distribute demand   estimates across sizes and stores. Will indicate if this is “IA Recommended”   or “User Created”. Possible Values: IA Recommended {User Created Product Profile Name} - This will show only if the user created product profile is mapped in the DC Store Policy → DC Store Strategy If user created product profile is mapped then IA-recommended should show in dropdown | Single Select Dropdown - Default value will be   IA-Recommended or the user created product profile mapped in the DC to Store Policy. | No | No |
| Custom | Store Eligibility Groups |   |  |  | String (comma separated values for >1 store groups) | No | No | No |
| Custom | Avg WOS |  |  |  | Input Number | Yes |  |  |
| Custom | Avg Min |  |  |  | Input Number | Yes |  |  |
| Custom | Avg Max |  |  |  | Input Number | Yes |  |  |
| Custom | Demand Type |   |  |  | Indicates whether allocation should be based on the IA forecast, or a Fixed percentage of net available inventory or APS(Average per Store). By default IA forecast should be selected. Possible values: IA Forecast (Default) Fixed APS (Optional) | Single Select | No | No |
| Custom | Fixed % |  |  |  | Units of Inventory in percentage are to be pushed to stores during allocation. This is relevant for scenarios where Demand-Type is chosen as Fixed. | Yes (Only if Demand-Type is Fixed) | No | No |
| Custom | Fixed Qty to Push |   |  |  | Units of Inventory are to be pushed to stores during allocation. This is relevant for scenarios where the Demand Type is chosen as Fixed. | Yes (Only if Demand-Type is Fixed) | No | No |
| Custom | Fixed Qty to   Allocate  |   |  |  | Fixed units of inventory for allocation | No | No | No    |
| Custom | Beginning Available to Allocate |  | inventory_smart.dc_pack_inventory | int4 | The total DC inventory which is available to allocate at the beginning of the day.  | No | No | No    |

### Eligible Stores:

The Store Details table should load with the following columns:

**tc_name :** 

| **Section** | **Column Name** | **Mapping column** | **Mapping Table** | **Data Type** | **Description** | **Editable(Yes/No)/\[Single/Multi Select\]** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Store | Store Number | store_code | inventory_smart.article_inventory_dashboard | varchar | Store Hierarchy | No | Yes | Yes |
| Store | Store Name | store_name | global.store_attributes_filter | varchar | Store Hierarchy | No | Yes | Yes |
| Store | {Store Grade or Tier} | grade | inventory_smart.article_inventory_dashboard | varchar | Store grade for given article-Store combination. | No | Yes | Yes |
| Custom | Store WOS |  | inventory_smart.rcl_constraint_master | int4 | Forward Weeks Of Supply. | Yes | No | Yes |
| Custom | Min |  |  | int4 | Min Constraint is the average of Mins of all the sizes present in the article at store level | Yes | No | Yes |
| Custom | Max |  |  | int4 | Min Constraint is the average of Max of all the sizes present in the article at store level | Yes | Yes | Yes |

**Acceptance Criteria:**

* Users can create scenarios with adjustable parameters.
* Users can compare scenarios and assess the impact of different strategies.
* Users can finalize scenarios while understanding their impact on original data.
* After initiating a new scenario, users must be able to adjust the mentioned input parameters at given levels/ (product, store, size)
* The system should validate inputs for each parameter to prevent unrealistic or conflicting configurations. e.g- 

    * Max stock level cannot be lower than Min stock level
    * Users must receive error messages or prompts when invalid data is entered.
    
* User must be able to unselect store for being allocated again in scenario in case they want. 

**Step 2 :**

As an allocator user, I want to be able to **review and modify the system's allocation recommendations** within the "What-if" scenario so that I can fine-tune the allocation based on my expertise and specific business needs.

* After creating a scenario with my desired inputs, I need to access a **recommendation screen** that displays the system’s proposed allocation based on the parameters I have set.
* The scenario recommendation screen should allow for the comparison of the scenario recommendations against the original allocation numbers.
* The scenario recommendation screen should present the data clearly to me, allowing me to quickly assess the impact of the simulated scenario and the adjustments I make.
* This recommendation screen will be a key area where I validate my hypotheses and explore the impact of my decisions.
* The feature will provide a way to compare different allocation strategies and confirm my intuitions.

This functionality will allow me to go beyond relying solely on system-generated recommendations and will empower me to use my expertise and business knowledge to make more informed allocation decisions and optimise inventory management.

Once scenario is created, user will see a high level summary and KPIs along with an option to see more details. KPIs include …

| **KPI Title** | **Logic** | **Sub Kpis** |
| --- | --- | --- |
| **Average Allocated Qty per Store** | Total quantity allocated / # Stores allocated | Original vs Scenario numbers |
| **#Allocated Stores** | #stores allocated | Original vs Scenario numbers |
| **Avg FWOS post allocation** | Sum (All sku-store's FWOS ) / #Allocated stores | Original vs Scenario numbers |
| **Average Store/SKU inventory post allocation** | All allocated sku-stores > Sum(OH+IT+OO+Allocated Qty) / allocated SKU-Store Count | Original vs Scenario numbers |
| **Avg store inventory post allocation** | All allocated stores > Sum(OH+IT+OO+Allocated Qty) / allocated Store Count | Original vs Scenario numbers |
| **In stock% post allocation** | Percentage of Sizes with positive inventory = (Numerator: number of eligible products having OH+IT+OO>0 at choice, store level  
Denominator: Total number of eligible products at choice, store level) | Original vs Scenario numbers |
| **Total Demand** | This will be original unconstrained demand : Sum(All sku-store's demand) | Original vs Scenario numbers |
|   **Target WOS Difference** | Target WOS (averaged across sku x store combinations) - Avg FWOS post allocation (this is an existing KPI) values should be displaye as +1, -1.3 etc | Original vs Scenario numbers |
| **Sell Through % - Forward Looking** | Forward looking demand for TWOS/(Forward looking demand for TWOS + Current Store OH+OO+IT) - Average across all sku stores combination | Original vs Scenario numbers |
| **Forward looking ROS** | Forward looking demand for TWOS / TWOS | Original vs Scenario numbers |

**Summary Table**

| **Column** | **Type of data in cells** |
| --- | --- |
| #Styles | Number |
| #Eligible Stores | Number |
| #Allocated Stores | Side by side comparison of Original vs Scenario |
| Avg. WOS | Side by side comparison of Original vs Scenario |
| Avg. Min | Side by side comparison of Original vs Scenario |
| Avg. Max | Side by side comparison of Original vs Scenario |
| Allocated quantity - each size | Side by side comparison of Original vs Scenario |
| Allocated quantity - Total | Side by side comparison of Original vs Scenario |
| Net Remaining Available (ATA available post allocations) | Side by side comparison of Original vs Scenario |
| Remaining DC Available- Size | Side by side comparison of Original vs Scenario |

**Scenario Details**

**Product Details -** The table should populate with following columns:

**tc_name  :** 

| **Section** | **Column Name** | **Mapping Column** | **Description** | **Editable(Yes/No)/\[Single/Multi   Select\]** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Style/Style Color ID} | article | Product Hierarchy. Hyperlink which will open a table at store level | No | Yes | Yes |
| Product | {L0 Name} | l0_name | Product Hierarchy | No | Yes | Yes |
| Product | {L1 Name} | l1_name | Product Hierarchy | No | Yes | Yes |
| Product | {L2 Name} | l2_name | Product Hierarchy | No | Yes | Yes |
| Product | {L3 Name} | l3_name | Product Hierarchy | No | Yes | Yes |
| Product | {L4 Name} | l4_name | Product Hierarchy | No | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | Product Attributes | No | Yes | Yes |
| Custom | Product Profile - Original |  |  | No | Yes | Yes |
| Custom | Product Profile - Scenario |  |  | No | Yes | Yes |
| Custom | Store Group |  |  | No | Yes | Yes |
| Custom | Aggregated Min |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Aggregated Max |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store WOS |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Allocation Delta |  |  | No | Yes | Yes |
| Custom | Absolute Deviation |  |  | No | Yes | Yes |
| Custom | Allocated Qty - Scenario |  | Total Allocated Quantity in Scenario | No | Yes | Yes |
| Custom | Allocated Qty - Original |  | Total Allocated Quantity in Scenario | No | Yes | Yes |
| Custom | Allocated Quantity |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store Info |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Allocated Pack Quantity  |  | Size level allocated quantity for the store at size/Pack DC level Separate column for each DC - size/Pack combination Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Remaining ATA |  | The net DC available inventory post allocation   
Side by side comparison of Original vs Scenario | No | Yes | Yes |

**Product-Store Details | {Style Color ID} -** Along side this Style Color ID, the selected Style Color ID should show. Below this, the table at Style Color Store level should load with following columns:

**tc_name :** 

| Store | Store Number | store_code | Store Code | No | Yes | Yes |
| --- | --- | --- | --- | --- | --- | --- |
| Store | Store Name | store_name | Store Name | No | Yes | Yes |
| Store | {Store Grade or Tier} | grade | Store grade for given article-Store combination. | No | Yes | Yes |
| Custom | Allocated Pack Quantity  |  | Size level allocated quantity for the store at size/Pack DC level Separate column for each DC - size/Pack combination Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Allocated Quantity |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Allocation Delta |  |  | No | Yes | Yes |
| Custom | Absolute Deviation |  |  | No | Yes | Yes |
| Custom | Allocated Qty - Scenario |  | Total Allocated Quantity in Scenario | No | Yes | Yes |
| Custom | Allocated Qty - Original |  | Total Allocated Quantity in Scenario | No | Yes | Yes |
| Custom | Store Inv - Store OH |  | Store Oh Hand Inventory | No | Yes | Yes |
| Custom | Store Inv -Store OO |  | Store Oh Order Inventory | No | Yes | Yes |
| Custom | Store Inv -Store IT |  | Store InTransit Inventory | No | Yes | Yes |
| Custom | Store Inv -Store OH+OO+IT |  | Total Store Inventory | No | Yes | Yes |
| Custom | Store WOS (OH+OO+IT) |  | Store WOS calculated Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store Constraints - Avg Min |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store Constraints - Avg Max |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store Constraints - Avg WOS |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store Constraints - Min  |  | Separate column for each size.Visible only when users expand Store Info   
Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store Constraints - Max  |  | Separate column for each size.Visible only when users expand Store Info  
  
Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store Constraints - WOS |  | Separate column for each size.Visible only when users expand Store Info  
Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Inv OH+IT+OO (By Size) |  | Total and size level split Separate column for each size | No | Yes | Yes |

‌

**Store View -** The table should populate with following columns:

**tc_name  :** 

| Store | Store Number | store_code | Store Code | No | Yes | Yes |
| --- | --- | --- | --- | --- | --- | --- |
| Store | Store Name | store_name | Store Name | No | Yes | Yes |
| Store | {Store Grade or Tier} | grade | Store grade for given article-Store combination. | No | Yes | Yes |
| Custom | Allocation Delta |  |  | No | Yes | Yes |
| Custom | Absolute Deviation |  |  | No | Yes | Yes |
| Custom | Allocated Qty - Scenario |  | Total Allocated Quantity in Scenario | No | Yes | Yes |
| Custom | Allocated Qty - Original |  | Total Allocated Quantity in Scenario | No | Yes | Yes |
| Custom | Allocated Quantity |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | # Allocated Styles |  | Side by side comparison of Original vs Scenario | No | Yes | Yes |
| Custom | Store OH+OO+IT |  | Total Store Inventory | No | Yes | Yes |

‌

**Acceptance criteria**

* After creating a scenario, the user can access a dedicated recommendation screen that displays the system’s proposed allocation based on the input parameters.
* UX - The recommendation screen displays both the system-generated allocation recommendations and the original allocation numbers side by side for easy comparison. Also, The system provides visual indicators (e.g., color coding) to show positive or negative impacts of adjustments made by the user.
* Users must be able to export or save their adjusted scenarios and recommendations for further analysis or reporting.
* The user must be able to finalise or delete a scenario, which locks in their adjustments and marks it as complete.
* Once a scenario is finalised, it must override the original plan numbers.

    * Original allocation plan id must remain same.
    
* Column names to be same as mentioned in confluence page attached.

‌

‌

# **User Story 6 - Allocation Upload Functionality (Add On):**

## **Jira Summary: \[Client Name\] - Create New Allocation → Allocation Upload Functionality**

## **Jira Description:**

As a planner or allocation user, I want to upload allocation units via a file so that I can bypass the standard allocation process and save time when specific manual allocations are needed.

### **Context & Scope:**

Currently, users need to go through the standard flow of creating allocations via the tool, which can be time-consuming for predefined or manually curated allocations. The new Allocation Upload feature allows users to directly upload allocation data from a file, bypassing typical validations like product-store or store-DC mappings.

### **Acceptance Criteria:**

1. **Upload Interface**:

    * An upload icon will be available in the _Create New Allocation_ module.
    * Upon clicking, users can download a structured **Upload Template** (.xlsx/.csv) and view **upload validations**.
    
2. **Upload Validations**:

    * Upload initiates a background job to validate schema and backend rules.
    * Generic success or failure notifications are shown.
    * Detailed validation messages shown in an _Upload Module_ screen.
    * Validation failures are color-coded (red = fail, blank = pass).
    * Upload schema must match exactly (case-sensitive, no extra/missing columns).
    
3. **Upload Module Features**:

    * View all validation rules per upload job.
    * Sort validations by success or failure.
    * Numerical indicators for count of failure per rule.
    * Option to download file with validation results.
    * Re-upload supported after correcting errors and removing validation columns.
    
4. **Allocation Processing**:

    * On successful upload, backdoor allocations are generated and released.
    * Allocations reflected in:
    
        * _View Past Allocations_ (marked as "Uploaded")
        * _Daily Allocation Summary_ (same day)
        * _Deep Dive Allocation_ (next refresh)
        
    
5. **Limitations**:

    * Max file size: **15 MB**
    * Max row count: **100,000**
    
6. **Edge Case Handling**:

    * If total allocated units > Net ATA at Style–Size level, a specific notification with impacted styles is triggered.
    

---

### **Notes**:

* Supports all BU–PO types.
* Works for both Packs and Eaches inventory types.
* Upload does not validate Active Status or Mappings.
* No need to use standard constraints or eligibility logic.
* Re-upload flow simplifies correction and improves user efficiency.


