# View Past Allocation - User Story

| Field | Value |
|---|---|
| Confluence page ID | `2696611422` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611422/View+Past+Allocation+-+User+Story |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:30.139Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
06 May 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Removed mapping columns for the OOTB columns

  
10 Apr 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added fc_name and tc_name

  
26 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table, datatype and Nullable column in filters and tables for validation
  2. Title case naming as per latest guideline
  3. Table View and Card view

  
  
# Guideline

  * The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**

  * Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**

  * Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.

  * Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field




# User Story

## **Jira Summary: [Client Name] - Development of View Past Allocation**

## **Jira Description:**

This module allows a user to view any past allocations that were created and finalized through the Create New Allocation (Dashboard) or Order Batching module. The user can choose to look at allocations created within a specified time period as well as those pertaining to a certain area of business. The user will not be able to make any edits to any of these plans as they have already been finalized. 

### _Navigation:_

Left-hand panel -> View Past Allocation

###  _Landing Page:_

Once the filters are applied, the table should populate with all the past finalized allocations for the selected filters.

### _Filters:_

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters along with the date filter to get the list of the allocations that was finalized.

**fc_name : inventorysmart_view_past_allocations**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Custom| Date| date range| | date| No| Yes| Date selection  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
Store| {S0 Name}| s0_name| global.store_attributes_filter| varchar| No| No| Multi select  
  
### ** _Flow:_**

  1. Clicking on 'Select Filters' allows users to apply a set of hierarchy and date filters, enabling them to Review the list of past allocations based on the filters selected.

  2. This screen has 2 types of view

     1. Table View - In this view, a table will load with each rows for each allocation code

     2. Card View - The allocation code and corresponding metrics will be shown as a card.

  3. To explore additional details of an entry in the Past Allocation Table, click on the view Recommendation in the Card View or select the allocation code and click on Review Recommendation in the Table View.

  4. The user will be redirected to the **' Recommendation' ** screen of the **Create New Allocation** module. However, the user wouldn't be able to make any edits to the allocation, unlike the usual flow. The loaded screen will have only 2 tabs: Product View and Store View (Store Capacity will not be there)




The above global filters are only to pick the allocation codes in which these products and stores are part of. The populated allocation code can show other products and stores also which are not part of the selected filters but was in the created allocation.

Displayed below is the schema of the **Past Allocations** Table:

**tc_name : inventorysmart_past_plans_table**

**Section**| **Column Name**| **Description**| **Searchable**| **Sortable**  
---|---|---|---|---  
Custom| Plan Name| Allocation plan name which was created| Yes| Yes  
Custom| # Style Colors Allocated| Number of style colors for which allocated is created| No| Yes  
Custom| # Stores| Number of stores to which units are allocated| No| Yes  
Custom| Total Allocated| Total allocated units in the plan| No| Yes  
Custom| Created On| Date on which allocation plan is created| Yes| Yes  
Custom| Created By| User Name who created the allocation| Yes| Yes  
Custom| Released On| The date when allocation was finalized| Yes| Yes  
  
Each card should have the following information:

  1. Plan Name

  2. Created By

  3. Created On

  4. # Style Colors Allocated

  5. # Stores

  6. Released On

  7. View Recommendation - Hyperlink




### ** _Acceptance Criteria:_**

  1. The user should be able to view past allocations created and finalized through the Create New Allocation module.

  2. The user should be able to filter allocations by a specified time period.

  3. The user should be able to filter allocations by a certain area of business.

  4. The user should not be able to make any edits to the finalized allocations.

  5. The user should be able to navigate to the 'Action' column in the Past Allocation Table.

  6. The user should be able to click on the arrow head button within the 'Action' column.

  7. The user should be redirected to the 'Recommendation' screen of the Create New Allocation module.

  8. The user should not be able to make any edits to the allocation on the 'Recommendation' screen.

  9. The table should display the columns as per the above table




