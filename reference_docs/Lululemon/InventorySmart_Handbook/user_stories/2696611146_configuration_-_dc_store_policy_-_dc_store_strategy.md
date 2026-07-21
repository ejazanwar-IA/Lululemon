# Configuration -> DC Store Policy -> DC Store Strategy

| Field | Value |
|---|---|
| Confluence page ID | `2696611146` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611146/Configuration+-+DC+Store+Policy+-+DC+Store+Strategy |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:24.296Z |
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




# Module Dependency/ Pre requisites

  * DC Store Strategy Rules

  * Auto Allocation Rules

  * Auto Allocation Scheduler

  * Store Group

  * Product Profile




# User Story

## **Jira Summary:[Client Name] \- Development of Configuration -> DC Store Policy -> DC Store Strategy**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

As an Allocator, I want to set the End-to-end process flow used for Allocation. The strategy outlines the execution approach for the recommendation and the methodology for calculating demand, attaching a Store Group and Product Profile, etc. As an Allocator, I am looking for the following functionalities on this screen:

  1. Apply a set of hierarchy filters that can help me get the list of the rules in the hierarchy.

  2. Create a New Rule using RCL.

  3. Attach a 'Product Profile' to the Rule: This can be either IA-recommended or user-created.

  4. Attach a 'Store Group' to the Rule: Choose between default eligibility or manually created groups.

  5. Attach a 'DC to Store Strategy Rule' to the Rule: Utilize predefined rules from the 'DC to Store Strategy Rules' screen.

  6. Set Auto Allocation Rule: Utilize predefined rules from the 'Auto Allocation Rules screen

  7. Set Auto Allocation Scheduler: Utilize the predefined rule set in the Auto Allocation Scheduler




###  _Navigation:_

Left-hand panel -> Configuration -> DC Store Policy -> DC Store Strategy

###  _Landing Page:_

Once the filters are applied, the default rules and the rules created by the user for the selected filters should load up. There should be option to go to the Manage RCL page to create or edits rules.

### _Filters:_

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters to get the list of the rules in the corresponding hierarchy. Refer to the table below for filter details. Only product-related filters are to be present on this screen.

**fc_name : DC-Store-Policy-Strategy Filters**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
  
### ** _Flow:_**

#### **_View the DC Store Strategy:_**

The following is the expected flow of the DC Store Strategy Screen:

  1. By clicking on 'Select Filters', The user will apply a set of hierarchy filters to get the list of the products in the corresponding hierarchy.

  2. Once the filters are selected, the strategy rules are populated. The loaded table should have following columns:




**tc_name : rcl_dc_store_policy**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**|   
---|---|---|---|---|---|---|---|---  
Custom| Rule ID| | inventory_smart.rcl_dc_store_policy_rule| int| No| Yes| No| Rule ID should has a arrow head to expand the row to show the store groups mapped, time periods, product profile, etc  
Custom| Rule Creation Level| | inventory_smart.rcl_dc_store_policy_rule| int| No| Yes| No|   
Custom| Rule Name| | inventory_smart.rcl_dc_store_policy_rule| varchar| Yes| Yes| No|   
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes| Only those columns are required which will be used for RCL/Rule creation  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| {Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes  
Product| Style-Color ID| article| global.product_attributes_filter| varchar| No| Yes| Yes  
Product| Size| size| global.product_attributes_filter| varchar| No| Yes| Yes  
Custom| Store/Store Groups Mapped| | | | Yes| No| No| Clicking on the values in this cell will open up the popup which shows the store groups mapped to this rule and the corresponding store codes  
Custom| From Date| | inventory_smart.rcl_dc_store_policy| date| No| Yes| Yes| Start date when this strategy will be active  
Custom| To Date| | inventory_smart.rcl_dc_store_policy| date| No| Yes| Yes| End date when this strategy will become inactive  
Custom| Product Profile| | | | Yes| No| No| Hyperlink to selection the product profile. By default ia-recommended should be there  
Custom| DC to Store Strategy Rules| | | | Yes| No| No| Hyperlink to set the rules.   
Custom| Auto Allocation Rules| | | | Yes| No| No| Hyperlink to set the auto allocation rules.   
Custom| Auto Allocation Scheduler| | | | Yes| No| No| Hyperlink to set the auto allocation scheduler  
  
At least one default rule should be created at the higher hierarchy level (l0_name, l1_name), which will have default values for Store Group, Auto Allocation Rules, Scheduler and DC-Store Strategy Rules. This default rule will not be editable from the tool. This acts as a backup when there are no rules created for any hierarchy.

Time based -> Strategies can be defined for each product hierarchy for different time ranges, with a From Date - To Date. The date ranges should be added in such a way that the end date for the final or last validity should be 31 Dec 2050 (a date in future, set as 31 Dec 2050).

  * Maximum Date - 31 Dec 2050

  * Minimum Date - Current date or a date in past when the rule was set.




#### **_Edit the DC Store Strategy:_**

DC Store Strategy can be edited inline or using the set All flow. 

  1. To edit one rule at a time expand the rule which needs to be edited. 

  2. Change the Store group, product profile, Auto Allocation Rules, Scheduler, DC-Store Strategy Rules and the to and from dates.

  3. To add a new time based strategy, click on + icon and set the rest of the values.

  4. Once done, click on save.




Multiple rules can be edited at once by using the Set All.

  1. Select the rules that needs to be edited.

  2. Click on Set All.

  3. In the popup, add the Store group, product profile, Auto Allocation Rules, Scheduler, DC-Store Strategy Rules and the to and from dates.

  4. Add more rows with different start and end dates.

  5. In the pop up there should be a flow for partial set All also.

  6. The partial Set All will have the same functionality except the Start and End date.

  7. Click on Apply to save changes




#### ** _Delete the DC Store Strategy Rules:_**

The user should have the flexibility to delete a rule completely or a selected time period.

To delete the particular time period, expand the rule and click the trashcan to delete the specific time period from the rule.

To delete a rule completely, select the rule(s) and click on the trashcan at the top the table. 

#### **_Manage RCL:_**

Clicking on the Manage RCL button from the landing page, user will be directed to the Manage RCL page. Users can create, edit or delete any RCL (Rule Creation Level) in this section.

#### **_Add RCL:_**

Following are the steps to create the RCL:

  1. Click on Add RCL button from the Manage RCL page

  2. The Add Rules page should load which has 3 steps of flow - Select Levels, Select Products and Set Strategy.

  3. In the Select Levels, user can select the product hierarchy or attributes at which Rules will be created. Below mentioned hierarchy and attributes should be present (The priority between hierarchy and attributes has to be aligned with the client. During the rule resolution this priority will be used. The column or rule with the lowest value of Priority will be used, 1 will be preffered instead of 2 or 3)




**Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Priority**| **Mandatory**  
---|---|---|---|---|---|---  
{L0 Name}| l0_name| global.product_attributes_filter| varchar| No| 6| Yes  
{L1 Name}| l1_name| global.product_attributes_filter| varchar| No| 5| Yes  
{L2 Name}| l2_name| global.product_attributes_filter| varchar| No| 4| No  
{L3 Name}| l3_name| global.product_attributes_filter| varchar| No| 3| No  
{L4 Name}| l4_name| global.product_attributes_filter| varchar| No| 2| No  
{Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| 1| No  
  
  4. Select the hierarchy or attribute at which user wants to create the rule and click on Next. User will be moved to Select Products section.

  5. Select the values for the hierarchy or attributes which was selected in the last section

  6. Click on Next. User will be moved to the Set Strategy section.

  7. The columns loaded in the Set Strategy screen will be same as the landing page table from the DC Store Strategy.

  8. Set the Store group, product profile, Auto Allocation Rules, Scheduler, DC-Store Strategy Rules and the to and from dates using either inline edits or Set All.




#### **_Delete RCL:_**

To delete a RCL, select the RCL from the Manage RCL page and click on the trashcan icon. A pop up will load asking for confirmation. 

![image-20250708-102849.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611146/image-20250708-102849.png?version=1&modificationDate=1779356664464&cacheVersion=1&api=v2&width=424&height=290)

Click on yes.

### **_Acceptance Criteria:_**

  1. Screen load time for filters - within 1 sec, product loading after applying filters - within 3 sec, pop-up load times - within 2 sec.

  2. Based on the rule creation level, the hierarchies must be filled. Rest all of them should be kept empty or '-'

  3. Should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  4. Rules must be attached for auto-allocation to function. Once the rules are attached, the styles corresponding to these rules will become part of auto-allocation the following day (There will be no impact of these rules in Manual Allocation)




**Invalid Use case**  
From Date should not be greater than End Date, front end check to be applied  
Any record with historic End Date to be deleted

**Performance Expectations**

  1. Attaching the rule(s) or Store group, etc to the hierarchy in DC-Store strategy section should not take longer than 4 seconds




