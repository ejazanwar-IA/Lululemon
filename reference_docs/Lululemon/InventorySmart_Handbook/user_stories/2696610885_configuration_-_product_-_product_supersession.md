# Configuration -> Product -> Product Supersession

| Field | Value |
|---|---|
| Confluence page ID | `2696610885` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610885/Configuration+-+Product+-+Product+Supersession |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:19.264Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
20 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table, datatype and Nullable column in filters and tables for validation
  2. Title case naming as per latest guideline

  
  
# Guideline

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field




# Module Dependency/ Pre requisites

  * [ _Configuration - > Product -> Product Status_](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610803/Configuration+-+Product+-+Product+Status)




# User Story

## **Jira Summary: [Client Name] - Development of Configuration -> Product -> Product Supersession**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

Users should have the capability to map one item (sub style-color ID) to another item (main style-color ID) in a way where the history of the former item gets added to the history of the latter item. The Product Supersession screen is crucial for managing product transitions and ensuring accurate allocation.

The purpose of supersession is to allow mapping of old products to new and collectively allocate preceded styles with superseded ones, done at a weekly level. For example, if sub style-color ID A supersedes main style-color ID B, then the history of B is added to the history of A. The sub style-color ID A now ceases to exist in the current universe. In essence, A now becomes part of B.

### _Filters:_

By clicking on '**Select Filters** ', the user can apply a set of product hierarchy filters to get the list of products having supersession mapping.

**fc_name : inventorysmart_product_supersession_listing**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {Style-Color ID}| article| inventory_smart.product_supersession_mapping| varchar| No| No| Multi select  
Product| {Sub Style-Color ID}| sub_article| inventory_smart.product_supersession_mapping| varchar| No| No| Multi select  
  
The supersession mappings will be taken through the tool and back synced into the system on a scheduled basis. Users can create and edit supersession mappings directly on the tool, seamlessly superseding an item with the history of preceded items.

**tc_name : product-supersession-summary**

**Section**| **Parent Column**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---|---  
Product| Old Article| Style-Color ID| old_article| inventory_smart.product_supersession_mapping| varchar| No| Yes| Yes  
Product| Old Article| {L0 name}| old_l0_name| inventory_smart.product_supersession_attribute| varchar| No| Yes| Yes  
Product| Old Article| {L1 name}| old_l1_name| inventory_smart.product_supersession_attribute| varchar| No| Yes| Yes  
Product| Old Article| {L2 name}| old_l2_name| inventory_smart.product_supersession_attribute| varchar| No| Yes| Yes  
Product| Old Article| {L3 name}| old_l3_name| inventory_smart.product_supersession_attribute| varchar| No| Yes| Yes  
Product| Old Article| {L4 name}| old_l4_name| inventory_smart.product_supersession_attribute| varchar| No| Yes| Yes  
Product| Old Article| {Product attributes}| {old_product_attribute}| inventory_smart.product_supersession_attribute| varchar / date| Yes| Yes| Yes  
Product| New Article| Style-Color ID| article | inventory_smart.product_supersession_mapping| STRING| Yes| Yes| Yes  
Product| New Article| {L0 name}| new_l0_name| inventory_smart.product_supersession_attribute| STRING| Yes| Yes| Yes  
Product| New Article| {L1 name}| new_l1_name| inventory_smart.product_supersession_attribute| STRING| Yes| Yes| Yes  
Product| New Article| {L2 name}| new_l2_name| inventory_smart.product_supersession_attribute| STRING| Yes| Yes| Yes  
Product| New Article| {L3 name}| new_l3_name| inventory_smart.product_supersession_attribute| STRING| Yes| Yes| Yes  
Product| New Article| {L4 name}| new_l4_name| inventory_smart.product_supersession_attribute| STRING| Yes| Yes| Yes  
Product| New Article| {Product attributes}| {new_product_attribute}| inventory_smart.product_supersession_attribute| STRING| Yes| Yes| Yes  
Custom|  | Priority| | inventory_smart.product_supersession_mapping| Actionable| Yes| Yes| Yes  
Custom|  | Mapped Sizes| | inventory_smart.product_supersession_mapping| STRING| Yes| Yes| Yes  
Custom|  | Start Date| | inventory_smart.product_supersession_mapping| DATE| Yes| Yes| Yes  
Custom|  | End Date| | inventory_smart.product_supersession_mapping| DATE| Yes| Yes| Yes  
Custom|  | Mapped On| | inventory_smart.product_supersession_mapping| DATE| Yes| Yes| Yes  
Custom|  | Mapped By| | inventory_smart.product_supersession_mapping| STRING| Yes| Yes| Yes  
  
The mapping is done at a Style-Color ID level. Start and end dates are defined for the supersession mapping validity, and user edits capture changes in this validity or removal of the supersession mapping if required. "Mapped By" and "Mapped On" outline the creation details of the supersession in the landing table.

The Product Supersession screen can be accessed through the 'Product' tab in the configuration module.   
The expected functionalities in the 'Product Supersession' tab:

  1. Apply a set of hierarchy filters to get the list of the styles in the desired hierarchy.

  2. Apply general table functionalities like sorting the table based on a column, adjusting column width, etc.

  3. Ability to create and modify supersession mappings, including validity dates and priority.

  4. Ability to set priority of allocation of attached styles and main styles for all the store groups in bulk using 'Set All' option.




**User flow to Edit dates & priority**

  1. The user should be able to filter the product to get the product from the desired hierarchy using the 'Select Filters' button.

  2. User should be able to edit the validity dates and priority of allocation of preceded styles and superseded style of supersession mapping. 

  3. User can click on 'Edit dates & priority' to open a popup for the supersession mapping.

  4. Integer values can be input to define the priority of the different Style Color ID(s)

  5. Further, the user can change the start date and end date for the mapping.




**User flow to Create New Mapping**

  1. The user should be able to filter the product to get the product from the desired hierarchy using the 'Select Filters' button.

  2. The user should be able to select the required sub-styles to be mapped.

  3. User can then map all the previous sub-styles to a main style using 'Map Main Style' button.

  4. Clicking on 'Map Main Style' should open a popup with all eligible Style IDs.

  5. User can select the main style id from this list and click on 'Save' to reflect the mapping created in the supersession table.

  6. Eligible main styles will be all the styles except the selected ones within the same sub-class.




**User flow to View Existing Mappings** :

  1. Click on **Select Filters** and the above filters will be displayed.

  2. The details table will be displayed which is at the Main Style and Sub Style level. 

  3. By selecting "View" in the priority column hyperlink, users can access the priority order for the styles. The subsequent pop-up will then appear.

  4. **** Once the user clicks on view priority hyperlink, the below pop-up appears

  5. The user can click on size mapping from Step 2 to view the size mapping between styles. The table pops up with the following columns.  
The backend tables used for the Supersession Module are: supersession_master, product_attributes_filter




**Checks to be done:**

  1. Ensure that the product hierarchies belong to the Main Choice

  2. The SKU level table Should contain distinct Main Product Code, Sub Product Code, and Size level and no duplicates in any table




**Key Acceptance Criteria:**

  1. User should be able to create, edit, or delete supersession mapping

  2. The supersession table should not have one-many mapping.

  3. In case of an overlap between two date ranges for multiple instances of an old style mapping, the newer one will be considered as final

  4. The user should be able to access the Product Supersession screen from the Product tab in the configuration module.

  5. The user should be able to apply hierarchy filters to get a list of products in the desired order.

  6. The user should be able to use table functions like sorting based on a column and adjusting column width.

  7. Screen load time for filters - within 1 sec, product loading after applying filters - within 3 sec, pop-up load times - within 2 sec.

  8. Landing table should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc




