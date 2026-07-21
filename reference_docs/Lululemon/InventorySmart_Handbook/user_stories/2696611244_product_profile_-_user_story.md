# Product Profile - User Story

| Field | Value |
|---|---|
| Confluence page ID | `2696611244` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611244/Product+Profile+-+User+Story |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:26.388Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
13 May 2026| [Gowthami T](https://impactanalytics.atlassian.net/wiki/people/5f8956ac7d9637006f2b4591?ref=confluence) | 

  1. Datatype update for hyperlink for the cases where dimension/section is either Product/Store

Expected : Datatype / Link  
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

## **Jira Summary:[Client Name] \- Development of Product Profile Module**

## **Jira Description:**

Product Profile helps drive allocation recommendations at the **SKU-Store** level. The user can view IA's recommended Product Profile as well as create/edit user-defined Product Profiles.

### _Navigation:_

Left-hand panel -> Product Profile

###  _Landing Page:_

Two tabs should be available: **IA Recommended** and **User Created**. Each tab has it's own filter and separate table structure.

### _IA Recommended:_

This section contains the Product Profile created from IA's forecast. The Overall Proportion % (store contribution) is the proportion of total forecast at a Store. The Product Profile Penetration% is determined by taking the forecast of a particular size for a specific store and dividing it by the total forecast for that store.

#### **_Filters for IA Recommended:_**

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters to get the list of the articles (Style Color IDs or Styles). Refer to the table below for filter details. Mainly product-related filters are to be present on this screen. Higher level store filter can be added maybe channel or country.

**fc_name : Product Profile Filters**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
Store| {S0 Name}| s0_name| global.store_attributes_filter| varchar| No| No| Multi Select  
  
#### ** _Flow:_**

  1. Select IA Recommended Tab.

  2. Apply relevant filters. The table should load with below columns:




**tc_name : product_profile_ia_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Product| {Article or Style/Style-Color ID}| article| inventory_smart.product_profile_master| varchar / Link| No| Yes| Yes| Hyperlink. Clicking on it should open the contribution at store and size level  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes| Product Hierarchy or Attributes  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes  
  
  3. Click on **{Article or Style/Style Color ID}** to view its Store, Overall Proportion(Store Contribution) %, and Size level Proportion for each store %.

  4. The **Store and size contributions** will load with below columns:




**tc_name : product_profile_store_size_ia_contribution_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Store| Store Number| store_code| inventory_smart.product_profile_mapping| varchar| No| Yes| Yes|   
Store| Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes|   
Store| {Channel}| {channel}| global.store_attributes_filter| varchar| No| Yes| Yes|   
Custom| Overall Proportion %| | inventory_smart.product_profile_mapping| float| No| No| Yes|   
Custom| Product Profile Pen %| | inventory_smart.product_profile_mapping| float| No| No| Yes| Size level columns. For each size, one column should be there.  
  
### _User Created:_

In this section, user can view or edit an existing user created product profile or can create a new Product Profile from historical data. They can select a time period and the products and store that will take part in creating the Profile.

#### **_Filters for User Created:_**

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters to get the list of the user created product profiles. Refer to the table below for filter details. Both product and store level filters can be added here

**fc_name : Create Product Profile**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| Yes| Single Select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| Yes| Multi Select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| No| Multi Select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| No| Multi Select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| No| Multi Select  
Store| {S0 Name}| s0_name| global.store_attributes_filter| No| Multi Select  
Store| {S1 Name}| s1_name| global.store_attributes_filter| No| Multi Select  
  
#### ** _Create Product Profile:_**

The flow for creating a product profile should be as below:

  1. Click on **Create** **Product Profile**.

  2. Enter Profile Name and Description (both are mandatory)

  3. Select time period. Static filters allow users to filter the transaction data based on a date range. Dynamic filter allows users to select for the Last 4 Weeks, Last 12 Weeks, Last 26 Weeks or Last 52 Weeks. {This can be based on days also like Last 30 days, Last 60 days, Last 90 days, Last 180 days and Last 360 days}

  4. Select relevant filter to get the transaction data for the product store combinations which will be used for profile creation.

  5. Select the Sales Attributes. Like if only Regular product should be included or only clearance products or both. By default both are selected.

  6. Enter Min and Max Price values. Default values are 1 and 9999.  
_(Note: Any transaction beyond these price points will not be considered for Profile creation)_

  7. The table should load with below columns:




**tc_name : create_product_profile_style_color_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Product| {Article or Style/Style-Color ID}| article| transaction_master_week_wise| varchar| No| Yes| Yes|   
Product| {L0 Name}| l0_name| transaction_master_week_wise| varchar| No| Yes| Yes| Product Hierarchy or Attributes  
Product| {L1 Name}| l1_name| transaction_master_week_wise| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| transaction_master_week_wise| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| transaction_master_week_wise| varchar| No| Yes| Yes  
Product| {Product Attributes}| {product_attribute}| transaction_master_week_wise| varchar / date| Yes| Yes| Yes  
Custom| Contribution %| | transaction_master_week_wise| float| No| No| Yes|   
Custom| Sales Qty| | transaction_master_week_wise| int| No| No| Yes|   
  
  8. User can change the value of the percentage at the top of the table to consider only top x% for profile creation. By default this will be 100.

![image-20250709-120030.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611244/image-20250709-120030.png?version=1&modificationDate=1779356666583&cacheVersion=1&api=v2&width=736&height=50)
  9. Select the {Article or Style/Style Color ID} which should be considered for product profile creation. Click on '**Proceed** '.   
The table Store and size contributions should load with following columns:




**tc_name: create_product_profile_store_size_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Store| Store Number| store_code| transaction_master_week_wise| varchar| No| Yes| Yes|   
Store| Store Name| store_name| transaction_master_week_wise| varchar| No| Yes| Yes|   
Store| {Channel}| {channel}| transaction_master_week_wise| varchar| No| Yes| Yes|   
Custom| Overall Proportion %| | transaction_master_week_wise| float| No| No| Yes|   
Custom| Product Profile Pen %| | transaction_master_week_wise| float| No| No| Yes| Size level columns. For each size, one column should be there.  
  
  10. Click on **Create Product Profile**.




#### **_View User Created Product Profile:_**

In this section the user can view existing **User Created** Product Profiles.

The User Created Product Profile should get updated every week based on the period selected

  1. Select **User Created** tab.

  2. Apply relevant filters. The table should load with below columns:




**tc_name: product_profile_user_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Custom| Product Profile| name| inventory_smart.product_profile_master| varchar| No| Yes| Yes|   
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes| Product Hierarchy or Attributes  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Custom| Time Attribute| | | | Yes| No| Yes| The time values selected during the creation of product profile  
Custom| Sales Attribute| | | | Yes| No| Yes| The sales attribute values selected during the creation of product profile  
Custom| Created At| | | | No| Yes| Yes|   
Custom| Created By| | | | No| Yes| Yes|   
Custom| Edit| | | | | | | Edit icon to edit the product profile  
Custom| Delete| | | | | | | Trashcan icon to delete the product profile  
  
  3. To view the overall proportion and product profile penetrations of a product profile, user should click on the corresponding product profile. Two tabs will be populated.

  4. The "Product Description" tab will help me view Style Color ID (article or styles) descriptions and their sales contributions. The loaded table **Store and size contributions:** should have the following columns:




**tc_name : product_profile_style_color_table**

**Section**| **Column Name**| **Mapping Column**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---  
Product| {Article or Style/Style-Color ID}| article| Yes| Yes|   
Product| Description| style_name| Yes| Yes|   
Custom| Contribution %| | No| Yes| Sales Contribution % in creating the product profile  
  
  5. The "Penetration" tab will help me view the Overall Proportion (Store Contribution) % and Product Profile Penetration % for a Style Color ID (article or Styles). The loaded table **Store and size contributions:** should have the following columns:




**tc_name : product_profile_store_size_contribution_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Store| Store Number| store_code| inventory_smart.product_profile_user_mapping| varchar| No| Yes| Yes|   
Store| Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes|   
Store| {Channel}| {channel}| global.store_attributes_filter| varchar| No| Yes| Yes|   
Custom| Overall Proportion %| | inventory_smart.product_profile_user_mapping| float| No| No| Yes|   
Custom| Product Profile Pen %| | inventory_smart.product_profile_user_mapping| float| No| No| Yes| Size level columns. For each size, one column should be there.  
  
  6. Click on **Edit** if any changes are needed to the contributions over what is shown in the table.




#### **_Edit User Created Product Profile:_**

As a user, I might want to edit the existing user-created product profile. To accomplish that I should have an "Edit" option for every user-created product profile. I am looking for the following functionalities while editing a product profile:

  * Should be able to adjust the Overall Proportion % (store contribution) at the store level.

  * Should be able to adjust the Product Profile Pen % (size proportion) at the SKU level.

  * The saved edits should recalculate the contributions to maintain a total of 100%.




_Any modifications made to a user-created product profile render the profile static, meaning that over time and with consecutive data refreshes, the product and store contributions won't be updated._

Two types of edits can be done:

  1. **Editing or adjusting only contributions for stores and sizes** \- The flow for this will be same as **View User Created Product Profile**. In the last step contributions will be editable. User can make changes to those cells. Rest of the cells will auto adjust to get the total contributions to 100%.

  2. **Editing or changing the sales contribution for product profile** \- This flow will be similar to the **Create Product Profile**. The detail flow is as below:

     1. I will navigate to the "User Created" tab and click on "Select Filters" to apply a set of hierarchy filters to help me get the list of the desired products and stores.

     2. I scroll right and click on the 'Edit' icon for the respective product profile. This will redirect me to a new screen.

     3. Apply filters and click on 'Proceed'.

     4. I select the relevant Style Color ID (article, styles). I should be able to remove older added Style Color ID (article, styles) or add Style Color ID (article, styles) styles. I click on 'Proceed'.

     5. The **Store and size contributions** table will load with updated contributions % based on the newly selected Style Color ID (article, styles).

     6. Click on Create Product Profile.




### **_Acceptance Criteria:_**

  1. Filters - within 1-2 sec, screen loading after applying filters - within 3-5 sec, Navigating from one screen to another 2-3 sec, update and save changes - 2-3 sec, Sell All - 3-5sec,

  2. All the tables in different screens should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  3. Only filtered products and stores should be visible on the screen

  4. Should be able to download the populated table and should have only filtered Products and Stores in the table

  5. The user should be able to click on 'Create Product Profile'.

  6. The user should be able to select a time period with options for static filters (date range) and dynamic filters (last 30, 90, 180, or 365 days).

  7. The user should be able to enter Min and Max Price values, with transactions beyond these points excluded from Profile creation.

  8. The user should be able to click on 'Save' to save the new Product Profile.

  9. The user should be able to click on Style ID to view its Store, Overall Proportion (Store Contribution) %, and Size level Proportion for each store % in both IA recommended and User Created

  10. In the User Created product profile, the user should be able to click on 'Edit' if any changes are needed to the contributions shown in the table.

  11. The user should be able to edit proportions at various parameters at store and size level.

  12. The user should be able to edit size proportion and overall proportion in the created product profile. Click on save to update the previous created product profile

  13. Any modifications made to a user-created product profile should render the profile static, meaning it won't be updated with consecutive data refreshes.




