# Grouping -> Product Group

| Field | Value |
|---|---|
| Confluence page ID | `2696610771` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610771/Grouping+-+Product+Group |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:16.160Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns.

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

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

## **Jira Summary: [Client Name] - Development of Grouping -> Product Group**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

### _Navigation:_

Left-hand panel -> Grouping -> Product Group

###  _Landing Page:_

In this module, users can create, edit, or delete Product Group(s). Users can create a Product Group based on various hierarchies or attribute filters. This helps the user in setting a default value for a group of products within/across hierarchies.

For example,**Product Groups can be used to configure Store Eligibility.**

**Applications/Features of Product Grouping:**

  * Users can also create their custom Product Groups.

  * A Product Group name cannot be edited. The user would need to delete and recreate. 

  * Product Groups can be used to set the eligibility for Stores in the Product store mapping

  * All users can see and edit the product groups (Depends on the user roles)




### _Filters:_

Applicable for the screens: Create New Product Group/ Edit/Delete Product Group. Only product filters are required in this case

**fc_name : Product Group**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
  
### ** _Product Grouping_**

Product Groups can be created by manually selecting a group of products (Manual Group Type) or by using a **Grouping Definition** that automatically updates the Product Groups based on certain rules (Dynamic Group Type).

#### **_Create a New Product Group_**

#### **  Manual Grouping**

Step 1: To create a Product Group manually, click on the  **' +'** sign button. It leads to a new screen to add a new product group based on user-selected filters and select filters.  
The loaded table **Filtered Product** should have following columns:

**tc_name : product_group_filter**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Product| SKU ID| product_code| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| Description| product_description| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes  
  
On clicking the Include Product Groups, table Filtered Grouping loads with below columns:

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Custom| Product Group Name| | global.product_groups| varchar| No| Yes| Yes  
Custom| # Products| | global.product_groups_mapping| int| No| No| Yes  
Custom| Definitions| | global.product_groups| varchar| Yes| No| Yes  
Custom| Group Type| | global.product_groups| varchar| No| No| Yes  
Custom| Created At| | global.product_groups| date| Yes| No| Yes  
Custom| Updated At| | global.product_groups| date| Yes| No| Yes  
Custom| Created By| | global.product_groups| varchar| Yes| Yes| Yes  
Custom| Updated By| | global.product_groups| varchar| Yes| Yes| Yes  
  
Step 2:  Select the required SKUs using single/multiple select or select current page records/all records based on the requirement, and click on **Save.**  Enter the name of the new product group and save. This leads to the landing screen of the Product Group tab.

#### **Grouping Definition**

Step 1: Click on '**Grouping Definitions** ' and then click on **' Create New Definition**' on the landing page.  
Once the user clicks on **Create New Definition** , users have the option to create a new definition by two methods:

  1. **Add Sub Rule:** Users have the option to add sub-rules, which are essentially conditions on certain product attributes or hierarchies. Each condition is called a Sub Rule and will be assigned a sub-rule name (for instance, Sub_Rule_1, Sub_Rule_2). These sub-rules come together to form a Grouping Definition.  
The sub rule should have the following dropdown values:




**Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**  
---|---|---|---  
{L0 Name}| l0_name| global.product_attributes_filter| varchar  
{L1 Name}| l1_name| global.product_attributes_filter| varchar  
{L2 Name}| l2_name| global.product_attributes_filter| varchar  
{L3 Name}| l3_name| global.product_attributes_filter| varchar  
{L4 Name}| l4_name| global.product_attributes_filter| varchar  
{Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date  
  
  2. **Add Definition as Sub Rule:** Users can utilize a pre-existing definition that includes established Sub Rules. Following each refresh, products falling within this definition will be automatically included in the Product Group.




Step 2:   When the **Add Sub Rule** is selected, and a user is presented with prompts to: Add a name for the sub-rule. and select the required attributes and/or hierarchy along with the corresponding values of the attribute selected from the two dropdowns respectively. Click Save.

Users can add definition as a sub-rule from the existing definitions using **Add Definition as Sub-Rule**

Step 1:  Click on "**Add Definition as Sub Rule** ".  
Step 2:  Select one or multiple existing Definitions and click on **Add.**  
Step 3: Users can also edit the sub-rules within the definition that is chosen and click on**Save.**

#### **_Edit/Delete Product Groups from the Landing Page_**

The landing page table should have the following columns:

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Custom| Product Group Name| Created Product Group Name| global.product_groups| varchar| No| Yes| Yes  
Custom| # Products| Number of products in the Product Group| global.product_groups_mapping| int| No| No| Yes  
Custom| Definitions| | global.product_groups| varchar| Yes| No| Yes  
Custom| Group Type| Type of the Group| global.product_groups| varchar| No| No| Yes  
Custom| Created At| | global.product_groups| date| Yes| No| Yes  
Custom| Updated At| | global.product_groups| date| Yes| No| Yes  
Custom| Created By| | global.product_groups| varchar| Yes| Yes| Yes  
Custom| Updated By| | global.product_groups| varchar| Yes| Yes| Yes  
Custom| Action| Actionable column with **Edit** and **Delete** Functionality| | | | No| No  
  
Step 1:  Select the relevant filters.  
Step 2: Users can edit/delete the existing Product Groups created manually/dynamically.  
Step 3:  Users can edit by selecting/deselecting the existing SKUs and clicking on '**Save** '.  
Step 4:  Users can click on '**Modify** ' to add more SKUs.  
Step 5: Once clicked on '**Modify** ', users can select the relevant filters add the desired SKUs, and click on '**Update** '.

#### **_Edit/Delete Grouping Definition  _**

Step 1:  Click on '**Grouping Definitions** '  to view the product groups created using the definitions and click on the '**Edit** ' icon to edit or the '**Delete** ' icon to directly delete.  
Step 2:  Perform the required edits and click on '**Save '**.

### **_Acceptance Criteria:_**

  1. Users should be able to click on the '+' sign button to create a new product group.

  2. Users should be able to select required SKUs using single/multiple select or select current page records/all records.

  3. Users should be able to enter the name of the new product group and save it.

  4. The new product group should be displayed on the landing screen of the Product Group tab.

  5. Users should be able to click on 'Grouping Definitions' and then 'Create New Definition'.

  6. Users should have the option to create a new definition by adding sub-rules or using an existing definition as a sub-rule.

  7. Users should be able to add a name for the sub-rule and select required attributes and/or hierarchy along with corresponding values.

  8. Users should be able to save the new definition.

  9. Users should be able to add an existing definition as a sub-rule and edit the sub-rules within the chosen definition.

  10. Users should be able to edit/delete existing product groups created manually or dynamically.

  11. Users should be able to click on 'Modify' to add more Style Color IDs.

  12. Users should be able to select relevant filters, add desired Style Color IDs, and click on 'Update' after clicking on 'Modify'.

  13. Users should be able to click on the 'Edit' icon to edit or the 'Delete' icon to delete a grouping definition.

  14. User-created product groups should be available in the Configuration -> Product mapping or store mapping screen.




**Invalid Use case:**

  1. If the group name already exists, a warning alert will be shown "Group name already exists".

  2. The Product Group Name cannot be edited. It has to be deleted and re-created.




**Performance Expectations:**

  1. The group creation should be instantaneous (<2 sec).

  2. All the tables should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  3. Only filtered products should be visible on the screen.




