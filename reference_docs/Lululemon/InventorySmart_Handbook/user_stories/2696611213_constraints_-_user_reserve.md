# Constraints -> User Reserve

| Field | Value |
|---|---|
| Confluence page ID | `2696611213` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611213/Constraints+-+User+Reserve |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:25.701Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
18 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added Nullable column for validation

  
06 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table and datatype in filters and tables
  2. Title case naming as per latest guideline

  
  
# Guideline

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field




# Module Dependency/ Pre requisites

  * DC Mapping -> DC-Product




# User Story

## **Jira Summary:[Client Name] \- Development of Constraints -> User Reserve**

## **Jira Description:**

In this module, users can reserve DC inventory. The table provided will be at the SKU(Pack ID)-DC (Channel) level. Users can set the reserve quantity in terms of the number of units or as a percentage of Inventory available in the DC.  Users can set a **' Reservation Till Date'** after which the reserved quantity will be released to DC On-Hand and become **Available to Allocate**. The table provides information regarding the On-Hand DC as well as the Incoming PO inventory.

**NOTE:** Eaches and Packs both can be reserved at the same time but separately. Eaches inventory will be reserved for eaches and packs inventory will be reserved for Packs. Example - 

**Pack ID**| **Size**| **Units in Pack**  
---|---|---  
Pack-123| S| 1  
Pack-123| M| 2  
Pack-123| L| 1  
  
**Pack ID / SKU**| **Inventory**| **Reserved Qty**  
---|---|---  
Pack-123| 20| 10  
S| 30| 5  
M| 10| 5  
L| 20| 10  
  
**SKU**| **Total Eaches Inventory**| **Total Eaches Reserved**  
---|---|---  
S| 50| 15  
M| 50| 25  
L| 40| 10  
  
####  _**_Data Requirement:_**_

Based on the DC-Product mapping, a table with DC Code (Channel), Product level will be created. This table should have the available inventory details at DC level and the incoming PO. This table should be pushed to PG where upsert logic should be used to update the inventory and PO details in the existing table. 

### _Navigation:_

Left-hand panel -> Constraints -> User Reserve

###  _Landing Page:_

Once the filters are applied, the table should populate with all the DC-Product combinations for the selected filters.

### _Filters:_

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters to get the list of the rules in the corresponding hierarchy. Refer to the table below for filter details. Mainly product-related filters are to be present on this screen. Higher level store filter can be added maybe channel or DC

**fc_name : Inventorysmart Constraints User Reserve**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
  
### ** _Flow:_**

  1. Select relevant filters to reserve the inventory at a SKU level

  2. To edit the reserved quantity and reservation date for SKUs in bulk, select rows from the **User reserve and Instock list** table and click on '**Set All ' **option.

  3. The user can edit the User reserve(Eaches or Packs), User reserve %(Eaches or Packs) and Reservation till date for all the rows.

  4. The user can directly edit User reserve(Eaches or Packs), User reserve %(Eaches or Packs) and Reservation till date in the table row-wise




Below is the table format for the User Reserve. The User can look at the Incoming Inv, On-Hand Inv, etc, and enter the User_Reserve units along with the Reservation_Till_Date.

**tc_name : user_reserve_and_instock_list**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Product| {Article or Product Code}| article or product_code| inventory_smart.dc_reserve_quantity| varchar| No| Yes| Yes|   
Product| {L0 Name}| l0_name| inventory_smart.dc_reserve_quantity| varchar| No| Yes| Yes| Product Hierarchy or Attributes  
Product| {L1 Name}| l1_name| inventory_smart.dc_reserve_quantity| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| inventory_smart.dc_reserve_quantity| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| inventory_smart.dc_reserve_quantity| varchar| No| Yes| Yes  
Product| {L4 Name}| l4_name| inventory_smart.dc_reserve_quantity| varchar| No| Yes| Yes  
Product| {Product Attributes}| {product_attribute}| inventory_smart.dc_reserve_quantity| varchar / date| Yes| Yes| Yes  
Product| Style Color ID| article| inventory_smart.dc_reserve_quantity| varchar| No| Yes| Yes  
Product| Size| size| inventory_smart.dc_reserve_quantity| varchar| No| Yes| Yes  
Custom| DC OH| | inventory_smart.latest_inventory| int| No| No| Yes|   
Custom| DC IT| | inventory_smart.latest_inventory| int| No| No| Yes|   
Custom| DC OO| | inventory_smart.latest_inventory| int| No| No| Yes|   
Custom| Net Available| | | int| No| No| Yes|   
Custom| Incoming PO 30| | inventory_smart.dc_reserve_quantity| int| No| No| Yes| If PO data is not there, these can be removed.  
Custom| Incoming PO 60| | inventory_smart.dc_reserve_quantity| int| No| No| Yes  
Custom| Incoming PO 90| | inventory_smart.dc_reserve_quantity| int| No| No| Yes  
Custom| User Reserve| | inventory_smart.dc_reserve_quantity| int| No| No| No| Units reserved (User Input)  
Custom| User Reserve % (eaches)| | inventory_smart.dc_reserve_quantity| float| Yes| No| No| Percentage of units reserved  (User Input)  
Custom| Total Units Reserved| | inventory_smart.dc_reserve_quantity| int| No| No| No|   
Custom| Reservation Till Date| | inventory_smart.dc_reserve_quantity| date| Yes| | | User Input  
Custom| Last Updated By| | inventory_smart.dc_reserve_quantity| varchar| Yes| Yes| Yes|   
Custom| Comment| | inventory_smart.dc_reserve_quantity| varchar| Yes| | | User Input  
  
###  **_Acceptance Criteria:_**

  1. Users should be able to reserve DC inventory at the SKU(Pack)-Channel(DC) level.

  2. Users should be able to set reserve quantities in terms of units or percentages.

  3. Users should be able to set a 'Reservation Till Date' after which the reserved quantity will be released to DC On-Hand and become Available to Allocate.

  4. The system should display information regarding On-Hand DC and Incoming PO inventory.

  5. Users should be able to view and edit the User Reserve, User Reserve % and Reservation Till Date for multiple rows using **Set All**

  6. Users should be able to directly edit User Reserve, User Reserve % and Reservation Till Date in the table row-wise.

  7. The system should allow reservations for Eaches and Packs separately.

  8. The system should prevent reservation units from being greater than Available Units in DC.

  9. Select All checkbox for Current Page selection and All records selection should work

  10. The system should validate that reservation units are not greater than available units in DC.

  11. The system should display an error message if the reservation units exceed the available units in DC.

  12. Once a non-zero user reserve is set against a SKU, it should reflect in the ATA for subsequent allocations.




**Invalid Use case**  
Reservation units cannot be greater than Available Units in DC, front end check to be applied

