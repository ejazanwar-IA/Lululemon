# Configuration -> Product -> Product-DC Mapping

| Field | Value |
|---|---|
| Confluence page ID | `2696610859` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610859/Configuration+-+Product+-+Product-DC+Mapping |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:18.729Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns

  
16 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
18 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added Nullable column for validation

  
05 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table and datatype in filters and tables
  2. Title case naming as per latest guideline

  
  
# Guideline

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field




# User Story

## **Jira Summary: [Client Name] - Development of Configuration -> Product -> Product-DC Mapping**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

Product-DC Mapping will help the user to maintain the appropriate DC to Product mappings to fulfill the inventory allocations. The mappings in this screen are all-encompassing, meaning that any style whose allocation plan is created over the IA tool can be performed only on a subset of these mappings.

### _Navigation:_

Left-hand panel -> Configuration -> Product -> Product-DC Mapping

###  _Landing Page:_

In this screen the loaded table will be at product hierarchy. The DC can be mapped by selecting from the Dropdown.

### _Filters:_

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters to get the list of the product DC mapping. Only product-related filters are to be present on this screen.

**fc_name : asa**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
  
### ** _Flow:_**

#### **_Product -> Product-DC Mapping:_**

  1. By clicking on 'Select Filters', The user will apply a set of hierarchy filters to get the list of the products in the corresponding hierarchy.

  2. Once the filters are selected, the Product table is populated. The loaded table **Filtered Product** should have following columns:




**tc_name : product_dc**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**|   
---|---|---|---|---|---|---|---|---  
Product| SKU ID| product_code| global.product_mapping_product_dc| varchar| No| Yes| Yes|   
Product| Description| product_description| global.product_attributes_filter| text| No| Yes| Yes|   
Product| Style-Color ID| article| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes|   
Custom| DC Mapped|  | | | | No| No| Dropdown to select DC(s) to map to the product  
  
#### ** _Data population:_**

All the active Products(SKU) corresponding to the selected filters are mapped to all the DCs corresponding to those filters. The default mapping status is 'Active' with a user flexibility to modify it to Inactive/Active.

The default Product-DC mapping is to be synced daily based on the Product and DC master.

**Set All** : As a user, i should be able to select multiple Product-DC combinations and perform bulk mapping of DC

### ** _Acceptance Criteria:_**

  1. Screen load time for filters - within 1 sec, style loading after applying filters - within 3 sec, pop-up load times - within 2 sec.

  2. No duplicate rows should be present

  3. Should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  4. The CNA payload should consider these mapping along with Product-Store mapping, Product Status and Store Status for the final eligibility.




