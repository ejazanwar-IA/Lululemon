# Configuration -> DC -> DC Status

| Field | Value |
|---|---|
| Confluence page ID | `2696611025` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611025/Configuration+-+DC+-+DC+Status |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:21.926Z |
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

## **Jira Summary: [Client Name] - Development of Configuration -> DC -> DC Status**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

The user should be able to change the status of a DC and control which DC-stores are visible in the tool, their eligibility for allocation, and forecast. There can be a case where the user wants to make any DC active/inactive based on the season. The DC Status screen is important for managing this.

The purpose of the status is to make sure that any inactive DC won't be part of Allocation flows. Generally, the DC status screen has two components - the Status tag (Active/Inactive) and Validity (the period when the status is valid).

### _Navigation:_

Left-hand panel -> Configuration -> DC -> DC Status

###  _Landing Page:_

The following functionalities are given in the DC status tab:

  1. Use hierarchy filters to get a list of DCs in the desired order.

  2. Use table functions like sorting based on a column, adjusting column width, etc.

  3. Change the status of specific DCs one by one or all at once using 'Set All' (Edits for DCs are restricted. If there is only one DC or one DC per channel or region then that should be non editable)




### _Filters:_

Only store-related filters are to be present on this screen.

**fc_name : Dc Status new config**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Store| {Channel}| channel| global.store_attributes_filter| varchar| No| No| Multi Select  
Store| {DC Name}| dc_name| global.store_attributes_filter| varchar| Yes| No| Multi Select  
  
### ** _Flow:_**

#### **_Edit the status of individual DC:_**

The user should be able to edit the status of a DC(s) in this section. The following is the expected flow:

  1. By clicking on 'Select Filters', the user would apply a set of hierarchy filters to get the list of the DCs in the corresponding hierarchy.

  2. Once the filters are selected, the user should get the DC Status table. The loaded table **Filtered DC** should have following columns:




**tc_name : dc_status**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**|   
---|---|---|---|---|---|---|---|---  
Store| DC Number| dc_code| global.distribution_centres| varchar| No| Yes| Yes|   
Store| DC Name| name| global.distribution_centres| varchar| No| Yes| Yes|   
Store| {Channel}| {channel}| global.store_attributes_filter| varchar| No| Yes| Yes|   
Store| {S1 Name}| {s1_name}| global.store_attributes_filter| varchar| No| Yes| Yes|   
Store| {Store Attribute}| {store_attribute}| global.store_attributes_filter| varchar / date| Yes| Yes| Yes|   
Custom| Status| | global.store_time_attributes| varchar| No| No| No| In summary, comma separated value should show  
In expanded view, it should be dropdown and allow user to update the status  
Custom| From Date| | global.store_time_attributes| date| No| No| No| Shows the data at expanded level  
Custom| To Date| | global.store_time_attributes| date| No| No| No| Shows the data at expanded level  
Custom| Updated At| | global.store_time_attributes| date| Yes| No| No|    
Custom| Updated By| | global.store_time_attributes| varchar| Yes| No| No|    
Custom| Delete Status| | | | | No| No| Shows the data at expanded level  
User can delete a status  
  
Users can edit the status of the relevant DC(s) and click on 'Save' to save the changes

**Tables to be used to create the DC Status screen:**

  * **distribution_centres:** All the DC hierarchy-related columns for the corresponding DC, are to be fetched from this table(DCs will be present in this table) - 'linked_store_code' column to be referred.

  * **dc_status:**__ Status, updated by, updated at, validity




#### ** _Edit the Status of multiple DCs at once:_**

If the user wants to edit the status of multiple DCs at once rather than one. I would follow the same flow as above, till the DC status table is populated.

  1. By clicking on 'Select Filters', the user would apply a set of hierarchy filters to help them get the list of the DCs in the hierarchy.

  2. Once the filters are selected, the DC Status table is populated. The required DCs can be selected, and click on 'Set All'. A pop-up should appear in which the user should be able to edit the status.

  3. All the selected stores should have the status overwritten, as per the given input.




**_Acceptance Criteria:_**

  1. Screen load time for filters - within 1 sec, product loading after applying filters - within 3 sec, pop-up load times - within 2 sec.

  2. No duplicate DCs should be present (the table should be at the DC code level).

  3. If a DC is made active, it should be visible on other screens on the tool

  4. The DC status table should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.




