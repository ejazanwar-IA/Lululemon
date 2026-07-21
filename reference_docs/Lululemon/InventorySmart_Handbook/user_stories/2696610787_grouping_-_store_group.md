# Grouping -> Store Group

| Field | Value |
|---|---|
| Confluence page ID | `2696610787` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610787/Grouping+-+Store+Group |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:16.729Z |
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

## **Jira Summary: [Client Name] - Development of Grouping -> Store Group**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

### _Navigation:_

Left-hand panel -> Grouping -> Store Group

###  _Landing Page:_

In this module, users can create, edit, or delete Store Group(s). Groups can be used for Allocation, set Store Eligibility, Reporting, etc. All the Stores (New and Existing) are eligible for Store Grouping. Store grouping allows the user to allocate the SKU to a limited number of stores.

For example,**Product Groups can be used to configure Store Eligibility.**

**Applications/Features of Product Grouping:**

  * Defining Store Eligibility for SKUs during the Allocation process.

  * Users can also create their custom Store Groups.

  * A Store Group name cannot be edited. The user would need to delete and recreate. 

  * After a new Store Group is created, the user can use this in the Create New Allocation to create allocation for selected stores

  * All users can see and edit the store groups




###  _Filters:_

Applicable for the screens: Create a New Store Group/ Edit/Delete a Store Group. Only store filters are required in this case

**fc_name : inventory_smart_store_group**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Store| {S0 Name}| s0_name| global.store_attributes_filter| varchar| No| Yes| Single Select  
Store| {S1 Name}| s1_name| global.store_attributes_filter| varchar| No| No| Multi Select  
Store| {S2 Name}| s2_name| global.store_attributes_filter| varchar| No| No| Multi Select  
Store| {Store Attribute}| store_attribute| global.store_attributes_filter| varchar| No| No| Multi Select  
  
### ** _Default Store Group:_**

Default Store Group needs to be created based on either country, channel or sales organization. (The number of default store groups varies between different client. It depends of number of channel or number of regions/country)

All the active Stores having Store Opening Date as a historic date or the current date will be part of one of the default store group.

  1. {Default Store Group 1}

  2. {Default Store Group 1}




### **_Store Grouping_**

The user can create, edit, or delete Store Groups in this section. These groups are then linked to Style Color ID(s) for allocation and forecasting purposes.

#### **_Create a New Store Group_**

This feature allows users to create a user-defined store group. The steps involved are as defined below:

Step 1:  Click on the **' +' **sign button. The user is redirected to a new screen to create a new Store Group.  
Step 2: Select relevant **Filters**. The table **Filtered Store** should populate with following columns:

**tc_name : store_group_filter**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Store| Store Number| store_code| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {Channel}| {channel}| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {S1 Name}| {s1_name}| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {Store Attribute}| {store_attribute}| global.store_attributes_filter| varchar / date| Yes| Yes| Yes  
  
Step 3: Clicking on the **Include Store Groups** should populate another table just below the **Filtered Store** table named **Filtered Grouping** with following columns

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Custom| Store Group Name| | global.store_groups| varchar| No| Yes| Yes  
Custom| # Store| | global.store_groups_mapping| int| No| No| Yes  
Custom| Group Type| | global.store_groups| varchar| No| No| Yes  
Custom| Created At| | global.store_groups| date| Yes| No| Yes  
Custom| Updated At| | global.store_groups| date| Yes| No| Yes  
Custom| Created By| | global.store_groups| varchar| Yes| Yes| Yes  
Custom| Updated By|  | global.store_groups| varchar| Yes| Yes| Yes  
  
Step 4: Select the required **Stores** to be grouped**** from the table, click on**Save,** and enter the New Store Group name in the prompt screen. Then the user is redirected to the Store Group landing page, where the newly created group can be found.

#### **_Edit/Delete a Store Group:_ **

Store groups can be edited or deleted altogether. New stores can be added to existing store groups or stores can be removed if needed.

Step 1: In the Store Group landing page, select and apply the relevant filters. The table should load with below columns:

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Custom| Store Group Name| Created Store Group Name| global.store_groups| varchar| No| Yes| Yes  
Custom| # Store| Number of stores in the Store Group| global.store_groups_mapping| int| No| No| Yes  
Custom| Group Type| Tyle of the Group| global.store_groups| varchar| No| No| Yes  
Custom| Created At|  | global.store_groups| date| Yes| No| Yes  
Custom| Updated At|  | global.store_groups| date| Yes| No| Yes  
Custom| Created By|  | global.store_groups| varchar| Yes| Yes| Yes  
Custom| Updated By|  | global.store_groups| varchar| Yes| Yes| Yes  
Custom| Action| Actionable column with **Edit** and **Delete** Functionality| | | | No| No  
  
Step 2: In the Store Group landing page, find the '**Action '** column and select the action to be performed by clicking on the respective icon.  
Step 3: Click on **Modify** and make the required changes by selecting/deselecting the items in the **store number column** and clicking on **Update**. Click on **Save.**

#### **_Store Group Upload Functionality_** _:_

The user should be able to upload a store group using an **upload icon** placed beside the **' Create New Store Group'** button.

  * On clicking the icon, an upload modal should open allowing users to upload `.xlsx` or `.csv` files.

  * A **downloadable template** must be provided within this modal. This template should include:

    * The expected format/columns

    * Validations/rules for upload

  * The system should **validate the uploaded file** for:

    * Format issues

    * Missing or invalid data

    * Duplicate entries

  * If invalid data is found, an appropriate **error message should be displayed** , and invalid rows should not be uploaded.




### **_Acceptance Criteria:_**

  1. Once the Store Group is created, it has to be populated on the Store Groups -> Grouping -> landing page according to the selected filters.

  2. The default groups should be refreshed post-data refresh every day.

  3. The User-Created Store Groups should be available to be attached to the styles color IDs under Configuration -> DC Store Policy and CNA -> Details table -> Store Eligibility Groups column dropdown.

  4. By default, the default store groups should be mapped for allocation in the CNA screen.




**Invalid Use case:**

  1. If the group name already exists, a warning alert will be shown "Group name already exists".

  2. The Store Group Name cannot be edited. It has to be deleted and re-created.




**Performance Expectation:**

  1. The group creation should be instantaneous (<2 sec).

  2. All the tables should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  3. Only filtered stores should be visible on the screen.




