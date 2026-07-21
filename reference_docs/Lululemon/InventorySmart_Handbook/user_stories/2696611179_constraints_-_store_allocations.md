# Constraints -> Store Allocations

| Field | Value |
|---|---|
| Confluence page ID | `2696611179` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611179/Constraints+-+Store+Allocations |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:24.967Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
12 May 2026| [Gowthami T](https://impactanalytics.atlassian.net/wiki/people/5f8956ac7d9637006f2b4591?ref=confluence) | 

  1. Splitting of Constraints ticket into 2 parts to address Jira Character limit issue

  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
18 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added Nullable column for validation

  
06 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table and datatype in filters and tables
  2. Title case naming as per latest guideline
  3. Added Min Distribution by Size
  4. Added Partial Set All and Store hierarchy

  
  
**Table of Contents**

# Guideline

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field




# User Story 1 - RCL Flow

## **Jira Summary:[Client Name] \- Development of Constraints -> Store Allocations**

## **Jira Description:**

Users can view/edit Allocation Constraints in this section. These Constraints are used while optimizing inventory recommendations. Allocation Constraints such as Min, Max, and WOS.

An**** RCL (Rule Creation Level) is defined as a hierarchy combination that can be used to define Rules for a set of product hierarchy values in that hierarchy combination.   
A Rule is defined as a combination of product hierarchy values under an RCL. All the products under the specified hierarchy values are eligible for the constraints addition/modification under the defined Rule.   
In addition, there is a default rule defined by IA (whose constraint values can be modified by the user). This is just to ensure in case a product doesn't fall into any user-created rule, it follows the Default rule setup. IA can set up default values and client have the ability to edit them as needed.

The constraints setup can be done at the Rule or Rule-Store hierarchy (a max of 3 store hierarchy) level. It also facilitates overwriting constraints of required stores under the defined rule using Store Exceptions.

#### _**_Data Requirement:_**_

One-time ingestion of Constraints would be done using the feed received from clients   
Post the one-time ingestion, the constraints can only be updated through the UI (for both adding new combinations as well as edits on the existing combinations).

### _Navigation:_

Left-hand panel -> Constraints -> Store Allocations

###  _Landing Page:_

Once the filters are applied, the default rules and the rules created by the user for the selected filters should load up. There should be option to go to the Manage RCL page to create or edits rules.

### _Filters:_

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters to get the list of the rules in the corresponding hierarchy. Refer to the table below for filter details. Only product-related filters are to be present on this screen.

**fc_name: Rules Constraint Filters**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
  
### ** _Flow:_**

#### **_View the Store Allocations Constraints:_**

The following is the expected flow of the Store Allocation Constraints Screen:

  1. By clicking on 'Select Filters', The user will apply a set of hierarchy filters to get the list of the products in the corresponding hierarchy.

  2. Once the filters are selected, the strategy rules are populated. The loaded table should have following columns:




**tc_name : rules_constraint_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Custom| Rule ID| | inventory_smart.rcl_constraint_master_rule| int| No| Yes| No| Rule ID should has a arrow head to expand the row to show the store groups mapped, time periods, product profile, etc  
Custom| Rule Creation Level| | inventory_smart.rcl_constraint_master_rule| int| No| Yes| No|   
Custom| Rule Name| | inventory_smart.rcl_constraint_master_rule| varchar| Yes| Yes| No|   
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes| Only those columns are required which will be used for RCL/Rule creation  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes  
Product| Style Color ID| article| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| Size| size| global.product_attributes_filter| varchar| No| Yes| Yes  
Store| Store Hierarchy 1| store_h1 (or state)| global.store_attributes_filter| varchar| Yes| Yes| Yes| A max of 3 store hierarchies can be added. If rule is valid for all hierarchy then all will be populated in these column  
Store| Store Hierarchy 2| store_h2 (or grade)| global.store_attributes_filter| varchar| Yes| Yes| Yes  
Store| {Store Attributes}| {store_attribute}| global.store_attributes_filter| varchar| Yes| Yes| Yes  
Custom| Min Distribution By Size| | inventory_smart.rcl_constraint_master| varchar| No| No| No| Actionable only when article level rule is created  
Custom| Start Date| | inventory_smart.rcl_constraint_master| date| No| No| No| Start date when this constraints will be active  
Custom| End Date| | inventory_smart.rcl_constraint_master| date| No| No| No| End date when this constraints will become inactive  
Custom| Min| | inventory_smart.rcl_constraint_master| int| No| No| No| Editable - Show data only on expanded view  
Custom| Max| | inventory_smart.rcl_constraint_master| int| No| No| No| Editable - Show data only on expanded view  
Custom| WOS| | inventory_smart.rcl_constraint_master| int| No| No| No| Editable - Show data only on expanded view  
Custom| Action| | | | | No| No| Delete icon to delete the rule. + icon to add a new time period with different constraints  
Custom| Updated By| | | | Yes| No| No|   
Custom| Updated At| | | | Yes| No| No|   
  
At least one default rule should be created at the higher hierarchy level (l0_name, l1_name), which will have default values for Min, Max and WOS. This default rule will not be editable from the tool. This acts as a backup when there are no rules created for any hierarchy.

Time based -> Constraints can be defined for each product hierarchy -> Store hierarchy for different time ranges, with a From Date - To Date.

#### **_Edit the Store Allocations Constraints:_**

Store Allocations Constraints can be edited inline or using the set All flow. 

  1. To edit one rule at a time expand the rule which needs to be edited. 

  2. Change the Min, Max, WOS and the to and from dates.

  3. To add a new time based constraints, click on + icon and set the rest of the values.

  4. Once done, click on save.




Multiple rules can be edited at once by using the **Set All**.

  1. Select the rules that needs to be edited.

  2. Click on Set All.

  3. In the popup, add the Min, Max, WOS and the to and from dates.




**Field Name**| **Mandatory**| **Comment**  
---|---|---  
Rule Name| No|   
Min| Yes|   
Max| Yes|   
Target WOS| Yes|   
Start Date| Yes|   
End Date| Yes|   
Min Distribution By Size| Yes| Dropdown. Valid for article level rule only  
  
  4. Add more rows with different start and end dates.

  5. Click on Apply to save changes




**Partial Set All** should be there in the Set All popup to adjust the constraints without date entry and relative to actual constraints.

**Field Name**| **Mandatory**| **Comment**  
---|---|---  
Rule Name| No|   
Min| No|   
Max| No|   
Target WOS| No|   
Absolute / Relative| Yes| Toggle button to change the constraints in absolute or relative to older data  
  
#### ** _Delete the Store Allocations Constraints:_**

The user should have the flexibility to delete a rule completely or a selected time period.

To delete the particular time period, expand the rule and click the trashcan to delete the specific time period from the rule.

To delete a rule completely, select the rule(s) and click on the trashcan at the top the table. 

#### **_Manage RCL:_**

Clicking on the Manage RCL button from the landing page, user will be directed to the Manage RCL page. Users can create, edit or delete any RCL (Rule Creation Level) in this section.

#### **_Add RCL:_**

Following are the steps to create the RCL:

  1. Click on Add RCL button from the Manage RCL page

  2. The Add Rules page should load which has 3 steps of flow - Select Levels, Select Products and Set Constraints.

  3. In the Select Levels, user can select the product hierarchy or attributes at which Rules will be created. Below mentioned hierarchy and attributes should be present (The priority between hierarchy and attributes has to be aligned with the client. During the rule resolution this priority will be used. The column or rule with the lowest value of Priority will be used, 1 will be preffered instead of 2 or 3)




**Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Priority**| **Mandatory**  
---|---|---|---|---|---|---  
{L0 Name}| l0_name| global.product_attributes_filter| varchar| No| 6| Yes  
{L1 Name}| l1_name| global.product_attributes_filter| varchar| No| 5| Yes  
{L2 Name}| l2_name| global.product_attributes_filter| varchar| No| 4| No  
{L3 Name}| l3_name| global.product_attributes_filter| varchar| No| 3| No  
{L4 Name}| l4_name| global.product_attributes_filter| varchar| No| 2| No  
{Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| No| 1| No  
  
  4. Select the hierarchy or attribute at which user wants to create the rule and click on Next. User will be moved to Select Products section.

  5. Select the values for the hierarchy or attributes which was selected in the last section

  6. Below the product hierarchy selection their should be a toggle, asking for store hierarchy selection, by default it should be false, if a user changes it to be True, then below store hierarchy should show up.




**Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**  
---|---|---|---|---|---  
Store Hierarchy 1| store_h1 (or state)| global.store_attributes_filter| varchar| No| No  
Store Hierarchy 2| store_h2 (or grade)| global.store_attributes_filter| varchar| No| No  
{Store Attributes}| {store_attribute}| global.store_attributes_filter| varchar| No| No  
  
  7. Click on Next. User will be moved to the Set Constraints section.

  8. For each rule, multiple rows can be be there, depending upon the store hierarchy / attributes selection. 

  9. The columns loaded in the Set Constraints screen will be same as the landing page table from the Store Allocations Constraints.

  10. Set the Min, Max, WOS, Min Distribution By Size and the to and from dates using either inline edits or Set All.




#### **_Min Distribution By Size:_**

This feature is eligible for article level rules only. Using this user can set the min at article level and then use an strategy to distribute that minimum to size level. This column should present in both landing page and in Manage RCL flow. The following strategy should be present:

  1. **Same Minimum for All Sizes** \- The default behavior. Same minimum will be distributed to all the sizes

  2. **Equally Distribute Across Sizes** \- Equal distribution across all the sizes

  3. **Product Profile** \- Size will be distributed based on set product profile (user created or IA) contribution

  4. **Atleast X Units per Size** \- Selected sizes will be given set min. Remaining minimum units will be distributed based on set product profile (user created or IA) contribution




#### ** _Edit RCL:_**

A new hierarchy can be added in the existing RCL by clicking on the **Add Hierarchies** in the Action column. The rest of the flow will be same as the Add RCL.

#### **_Delete RCL:_**

To delete a RCL, select the RCL from the Manage RCL page and click on the trashcan icon. A pop up will load asking for confirmation. 

![image-20250708-102849.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611179/image-20250708-102849.png?version=1&modificationDate=1779356665160&cacheVersion=1&api=v2&width=424&height=290)

Click on yes.

### **_Acceptance Criteria:_**

  1. Once the rules are created and the constraints are setup, these needs to be disaggregated and utilized at a SKU-Store level for constraints in allocation flow.

  2. The screen load time should be <= 2 secs for a style view to come up.




**Invalid Use case**  
**Product Store:** No same Rule / RCL should be duplicated and there needs to be a front end check for preventing the same

# User Story 2 - Manage Exceptions

## **Jira Summary:[Client Name] \- Development of Constraints -> Manage Exception**

## **Jira Description:**

#### **_Manage Exceptions:_**

Certain sets of stores can be excluded from the set constraints for any product rule using this functionality. These exclusions take priority over the Rule-Store Tier level constraints.

The default table will contain all the Rule-Store ID combinations for which exceptions are defined basis the user-selected filters. The loaded table should have the following columns:

**tc_name: exception_stores_table**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**| **Comments**  
---|---|---|---|---|---|---|---|---  
Custom| Rule ID| | inventory_smart.rcl_constraint_master_exceptions| int| No| Yes| No| Rule ID should has a arrow head to expand the row to show the store groups mapped, time periods, product profile, etc  
Custom| Rule Creation Level| | inventory_smart.rcl_constraint_master_exceptions| int| No| Yes| No|   
Custom| Rule Name| | inventory_smart.rcl_constraint_master_exceptions| varchar| Yes| Yes| No|   
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes| Only those columns are required which will be used for RCL/Rule creation  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes  
Product| Style Color ID| article| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| Size| size| global.product_attributes_filter| varchar| No| Yes| Yes  
Store| Store Code| store_code| inventory_smart.rcl_constraint_master_exceptions| varchar| No| Yes| Yes|   
Custom| Start Date| | inventory_smart.rcl_constraint_master_exceptions| date| No| Yes| Yes| Start date when this constraints will be active  
Custom| End Date| | inventory_smart.rcl_constraint_master_exceptions| date| No| Yes| Yes| End date when this constraints will become inactive  
Custom| Min| | inventory_smart.rcl_constraint_master_exceptions| int| No| Yes| Yes| Editable - Show data only on expanded view  
Custom| Max| | inventory_smart.rcl_constraint_master_exceptions| int| No| Yes| Yes| Editable - Show data only on expanded view  
Custom| WOS| | inventory_smart.rcl_constraint_master_exceptions| int| No| No| No| Editable - Show data only on expanded view  
Custom| Action| | | | | No| No| Delete icon to delete the rule. + icon to add a new time period with different constraints  
Custom| Updated By| | | | Yes| No| No|   
Custom| Updated At| | | | Yes| No| No|   
  
The constraints can be modified here. Also, the rows can be deleted if they need to be excluded from the exception list.

#### **_Add Exceptions:_**

New exceptions can be added using the 'Add Exception' button.  
It's a 3-step process with Rule selection basis the product filters, Store selections basis the store filter and then Set constraints for the selected Rule-store combinations.

  1. Filter for the rules using the product filters. The product filters remain the same as defined above.

  2. Select the Rule(s) for which exception needs to be added.

  3. Click on Next. This will move to step 2, Select Store.

  4. Apply the Store Filters. Following Store Filters should be available:




**fc_name : Add Exception Store Filters**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---  
Store| {S0 Name}| s0_name| global.store_attributes_filter| Yes| Single Select  
Store| {S1 Name}| s1_name| global.store_attributes_filter| No| Multi Select  
Store| {S2 Name}| s2_name| global.store_attributes_filter| No| Multi Select  
Store| {Store Attribute}| store_attribute| global.store_attributes_filter| No| Multi Select  
  
  5. Store table will load with following columns:




**tc_name: exception_store_list_columns**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**|     
---|---|---|---|---|---|---|---|---  
Store| Store Number| store_code| global.store_time_attributes| varchar| No| Yes| Yes|    
Store| Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes|    
Store| {Channel}| {channel}| global.store_attributes_filter| varchar| No| Yes| Yes|    
Store| {S1 Name}| {s1_name}| global.store_attributes_filter| varchar| No| Yes| Yes|    
Store| {Store Attribute}| {store_attribute}| global.store_attributes_filter| varchar / date| Yes| Yes| Yes| Add proper datatype - required for validation  
  
  6. Select the stores for which the exception needs to be added. 

  7. Click on the Add button. This will move to step 3, Set Constraints.

  8. The loaded table should have columns same as the landing page table of Manage Exceptions.

  9. Set the Min, Max, WOS and the to and from dates using either inline edits or Set All.

  10. Click on Save to add the Exceptions.




#### **_Edit the Exceptions:_**

Store Exceptions can be edited inline or using the set All flow. 

  1. To edit one rule at a time expand the rule which needs to be edited. 

  2. Change the Min, Max, WOS and the to and from dates.

  3. To add a new time based constraints, click on + icon and set the rest of the values.

  4. Once done, click on save.




Multiple rules can be edited at once by using the Set All.

  1. Select the rules that needs to be edited.

  2. Click on Set All.

  3. In the popup, add the Min, Max, WOS and the to and from dates.

  4. Add more rows with different start and end dates.

  5. Click on Apply to save changes




#### ** _Delete the Exceptions:_**

The user should have the flexibility to delete a rule completely or a selected time period.

To delete the particular time period, expand the rule and click the trashcan to delete the specific time period from the rule.

To delete a rule completely, select the rule(s) and click on the trashcan at the top the table. 

### **_Acceptance Criteria:_**

  1. Once the rules are created and the constraints are setup, these needs to be disaggregated and utilized at a SKU-Store level for constraints in allocation flow.

  2. The screen load time should be <= 2 secs for a style view to come up.




**Invalid Use case**  
**Product Store:** No same Rule / RCL should be duplicated and there needs to be a front end check for preventing the same

