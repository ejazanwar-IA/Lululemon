# Configuration -> Product -> Product Status

| Field | Value |
|---|---|
| Confluence page ID | `2696610803` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610803/Configuration+-+Product+-+Product+Status |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:17.269Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns.
  2. Added Style level view table

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
18 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added Nullable column for validation

  
02 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence) | 

  1. Added mapping table and datatype in filters and tables
  2. Title case naming as per latest guideline

  
21 Nov 2025| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Corrected the edit flow and added delete status.
  2. Sentence case naming for column and filter headers

  
  
# Guideline

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field




# User Story

## **Jira Summary: [Client Name] - Development of Configuration -> Product -> Product Status**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

Users should have the capability to modify the status of the {Style(s) - (optional, configurable at style or style color level)} & SKU(s) and the Product status screen is crucial for maintaining and controlling their eligibility for allocation, forecast, etc.

The purpose of the status is to ensure that any Style/SKU(s) tagged as inactive will not be displayed in allocation flows, or have a forecast in the ADA visual. In general, the Product status screen has two components - the status tag (Active/Inactive) and validity (the period during which the status remains valid).

The status updates are taken through user edits only. There are default start and end dates given for all the valid products(valid product logic is incorporated in product master), and then user edits if any, will capture the information including status (Active/Inactive), validity (period where status remains valid), Updated by, Last updated, for the valid products.

### _Navigation:_

Left-hand panel -> Configuration -> Product -> Product Status

###  _Landing Page:_

The expected functionalities in the 'Product Status' tab:

  1. Apply a set of hierarchy filters that can help get the list of the styles in the desired hierarchy.

  2. Apply general table functionalities like sorting the table based on a column, adjusting column width, etc..

  3. Ability to modify the status of the desired Style/SKU(s) individually or at once using 'Set All'.




**{There needs to be a toggle button to switch from Style to SKU view.}**

The most recent edit is considered when considering the Style/SKU view for the same product.

For example, If Style A is made Active from Style view, all the SKUs corresponding to the style turns Active. Later from SKU view, if SKU X(part of Style A) is made Inactive then all the other SKUs(except SKU X ) from Style A will be considered Active.

### _Filters:_

Only product-related filters are to be present on this screen. If the products are allocated separately in each channel, region or country then duplication of products are done during master table creation which will ensure each channel, country or region has unique product.

**fc_name: Product Status**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
  
### ** _Flow:_**

#### **_Edit the status of individual_ _Style_ _/SKU(s):_**

The following is the expected flow of the Product Status screen:

  1. By clicking on 'Select Filters', The user will apply a set of hierarchy filters to get the list of the products in the corresponding hierarchy.

  2. Once the filters are selected, the Product Status table is populated. The loaded table **Filtered Product** should have following columns:  
**The below table is for product view.(Keep it only if required)**




**tc_name : product_status**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Product| SKU ID| product_code| global.product_time_attributes| varchar| No| Yes| Yes|   
Product| Description| product_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| Style-Color ID| article| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L0 name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L1 name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L2 name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L3 name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L4 name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {Product attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes| Add proper datatype - required for validation  
Custom| Status| | global.product_time_attributes| varchar| No| No| No| In summary, comma separated value should show  
In expanded view, it should be dropdown and allow user to update the status  
Custom| Status From Date| | global.product_time_attributes| date| No| No| No| Shows the data at expanded level  
Custom| Status To Date| | global.product_time_attributes| date| No| No| No| Shows the data at expanded level  
Custom| Last Updated| | global.product_time_attributes| date| Yes| No| No|    
Custom| Updated By| | global.product_time_attributes| varchar| Yes| No| No|    
Custom| Delete| | | | | No| No| Shows the data at expanded level  
User can delete a status  
  
  3. Clicking the toggle (if applicable for client) should change the status view to Style View. The column for style view tables should be as below:  
**The below table is for style view.(Keep it only if required)**  
**tc_name : product_status_style**




**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Product| Style-Color ID| article| global.product_attributes_filter| varchar| No| Yes| Yes| Can be at higher level also. the corresponding aggregation_time_attributes should be at created at that level  
Product| {L0 name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L1 name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L2 name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L3 name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L4 name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {Product attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes| Add proper datatype - required for validation  
Custom| Status| | global.product_time_attributes| varchar| No| No| No| In summary, comma separated value should show  
In expanded view, it should be dropdown and allow user to update the status  
Custom| Status From Date| | global.product_time_attributes| date| No| No| No| Shows the data at expanded level  
Custom| Status To Date| | global.product_time_attributes| date| No| No| No| Shows the data at expanded level  
Custom| Last Updated| | global.product_time_attributes| date| Yes| No| No|    
Custom| Updated By| | global.product_time_attributes| varchar| Yes| No| No|    
Custom| Delete| | | | | No| No| Shows the data at expanded level  
User can delete a status  
  
Users can edit the status of the relevant style(s)/SKU(s) and click on 'Save' to save the changes

  * Tables to be used to create the Product Status screen:

    * **product_attributes_filter:** All the product hierarchy-related columns for the corresponding product, are to be fetched from this table

    * **product_time_attributes:**__ Status, updated by, updated at, validity

    * **{aggregation_time_attributes** : Required for higher level status like at Style level or Style color level}




**Set All - Edit the Status of multiple Products at once:**

If the user wants to edit the status of multiple Styles/SKUs at once rather than one.

  1. By clicking on 'Select Filters', a set of hierarchy filters can be applied to get the list of the Styles in the hierarchy.

  2. Once the filters are selected, the Product status table is populated. The required products can be selected, and click on '**Set All** '. A pop-up should appear which should be able to edit the status of all the selected Styles/SKUs.

![image-20251121-024338.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610803/image-20251121-024338.png?version=1&modificationDate=1779356657498&cacheVersion=1&api=v2&width=736&height=304)
  3. All the selected products should have the status overwritten, as per the given input.




**Delete Flow**

User can delete a status of product by clicking on the **Trash** icon in the **Delete** column.

**NOTE:** The delete would work only if there are multiple statuses for the product. If there is only one status for a product then the delete will not work and the user needs to change the status from Active or Inactive.

**Example:**

**Case 1** \- In the below example there is only one status for the product. The delete would not work on this as there should be at least one status present for each product in the tool.

**Product**| **Status**| **Status from date**| **Status to date**  
---|---|---|---  
8000760| Active| 2025-01-12| 2050-12-31  
  
**Case 2** \- in the below example there are 3 different set status with start and end date. If we delete the 2nd status then the product will become **active** from initial start date to final end date

**Product**| **Status**| **Status from date**| **Status to date**  
---|---|---|---  
8000760| Active| 2025-01-12| 2025-08-31  
8000760| Inactive| 2025-09-01| 2026-09-30  
8000760| Active| 2026-10-01| 2050-12-31  
  
After 2nd row deletion:

**Product**| **Status**| **Status from date**| **Status to date**  
---|---|---|---  
8000760| Active| 2025-01-12| 2050-12-31  
  
If row 3 is deleted then the Inactive status will extent to the final end date.

**Product**| **Status**| **Status from date**| **Status to date**  
---|---|---|---  
8000760| Active| 2025-01-12| 2025-08-31  
8000760| Inactive| 2025-09-01| 2050-12-31  
  
 _At any case, the final status end date will always be 2050-12-31. If any status is deleted or edited it will extend the last range of status to 2050-12-31._

### **_Acceptance Criteria:_**

  1. Users should be able to access the Product status screen through the 'Product' tab in the configuration module.

  2. Users should be able to modify the status of Style(s) & SKU(s) individually or at once using 'Set All'.

  3. The status updates should include Status (Active/Inactive), Validity (period where status remains valid).

  4. The most recent edit should be considered when viewing the Style/SKU for the same product.

  5. A toggle button should be available to switch from Style to SKU view.

  6. If a Style is made Active from Style view, all corresponding SKUs should turn Active. If a SKU is made Inactive from SKU view, only that SKU should be Inactive while others remain Active.

  7. Once the filters are selected, the Product Status table should be populated with the relevant products.

  8. No duplicate styles should be present in the table (the table should be at the style level).

  9. If a style/SKU is made inactive, it should not appear in the allocation flow screen

  10. Using Set All to update the status should open a popup window to adjust the validity start and end time.

  11. After applying the changes in the Set All pop-up window, all selected products should have their status overwritten as per the given input.

  12. Screen load time for filters - within 1 sec, style loading after applying filters - within 3 sec, pop-up load times - within 2 sec.

  13. Should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.




