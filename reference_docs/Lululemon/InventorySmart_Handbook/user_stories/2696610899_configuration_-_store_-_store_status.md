# Configuration -> Store -> Store Status

| Field | Value |
|---|---|
| Confluence page ID | `2696610899` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610899/Configuration+-+Store+-+Store+Status |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:19.596Z |
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

  
02 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

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

## **Jira Summary: [Client Name] - Development of Configuration -> Store -> Store Status**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

As a user, I should be able to change the status of a store and control which stores are visible in the tool, their eligibility for allocation, and forecast. The Store Status screen is important for managing this.

The purpose of the status is to make sure that any inactive stores won't be part of Allocation flows. In General, the Store status screen has two components - the Status tag (Active/Inactive) and Validity (the period when the status is valid).

The store status screen follows the generic approach, having the status defined between from and to dates. The edit over the tool is the only source of truth for existing stores, new stores would be added to the Store Status table through ingestion, provided they are deemed allocation eligible.

### _Navigation:_

Left-hand panel -> Configuration -> Store -> Store Status

###  _Landing Page:_

As a user, I expect the following functionalities in the 'Store Status' screen:

  1. Use hierarchy filters to get a list of stores in the desired order.

  2. Use table functions like sorting based on a column, adjusting column width, etc.

  3. Change the status of specific stores one by one or all at once using 'Set All'




### _Filters:_

Only store-related filters are to be present on this screen.

**fc_name : Store Status**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Store| {S0 Name}| s0_name| global.store_attributes_filter| varchar| No| Yes| Single Select  
Store| {S1 Name}| s1_name| global.store_attributes_filter| varchar| No| No| Multi Select  
Store| {S2 Name}| s2_name| global.store_attributes_filter| varchar| No| No| Multi Select  
Store| {Store Attribute}| store_attribute| global.store_attributes_filter| varchar| No| No| Multi Select  
  
### ** _Flow:_**

#### **_Edit the status of individual Store:_**

As a user, I should be able to edit the status of a Store(s) in this section. The following is the expected flow:

  1. By clicking on 'Select Filters', I would apply a set of hierarchy filters to help me get the list of the stores in the corresponding hierarchy.

  2. Once I select the filters, I should get the Store Status table. The loaded table **Filtered Store** should have following columns:




**tc_name : store_status**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**|   
---|---|---|---|---|---|---|---|---  
Store| Store Number| store_code| global.store_time_attributes| varchar| No| Yes| Yes|   
Store| Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes|   
Store| {Channel}| {channel}| global.store_attributes_filter| varchar| No| Yes| Yes|   
Store| {S1 Name}| {s1_name}| global.store_attributes_filter| varchar| No| Yes| Yes|   
Store| {Store Attribute}| {store_attribute}| global.store_attributes_filter| varchar / date| Yes| Yes| Yes| Add proper datatype - required for validation  
Custom| Status| | global.store_time_attributes| varchar| No| No| No| In summary, comma separated value should show  
In expanded view, it should be dropdown and allow user to update the status  
Custom| From Date| | global.store_time_attributes| date| No| No| No| Shows the data at expanded level  
Custom| To Date| | global.store_time_attributes| date| No| No| No| Shows the data at expanded level  
Custom| Updated At| | global.store_time_attributes| date| Yes| No| No|    
Custom| Updated By| | global.store_time_attributes| varchar| Yes| No| No|    
Custom| Delete Status| | | | | No| No| Shows the data at expanded level  
User can delete a status  
  
I will edit the status of the relevant store(s) and click on 'Save' to save the changes

**Tables to be used to create the Store Status screen:**

  * **store_attributes_filter:** All the store hierarchy-related columns for the corresponding store, are to be fetched from this table

  * **store_time_attributes:**__ Status, updated by, updated at, validity




#### ** _Edit the Status of multiple Stores at once:_**

As a user, I want to edit the status of multiple stores at once rather than one. I would follow the same flow as above, till the store status table is populated.

  1. By clicking on 'Select Filters', I would apply a set of hierarchy filters to help me get the list of the stores in the hierarchy.

  2. Once I select the filters, I should get the Store Status table. If I select the required stores, I would click on 'Set All'. A pop-up should appear in which I should be able to edit the status.

  3. All the selected stores should have the status overwritten along with the time-frames, as per the given input.

![image-20250702-065850.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610899/image-20250702-065850.png?version=1&modificationDate=1779356659710&cacheVersion=1&api=v2&width=736&height=386)



**_Acceptance Criteria:_**

  1. The user should be able to access the Store Status screen from the 'Store' tab in the configuration module.

  2. The user should be able to apply hierarchy filters to get a list of stores in the desired order.

  3. The user should be able to use table functions like sorting based on a column and adjusting column width.

  4. The user should be able to change the status of specific stores one by one.

  5. The user should be able to save the changes after editing the status.

  6. The user should be able to change the status of multiple stores at once using the 'Set All' button.

  7. A pop-up should appear when the user clicks 'Set All', allowing them to edit the status for multiple stores.

  8. All selected stores should have their status overwritten along with the time-frames as per the given input.

  9. Screen load time for filters - within 1 sec, product loading after applying filters - within 3 sec, pop-up load times - within 2 sec.

  10. No duplicate stores should be present (the table should be at the store code level).

  11. If a store is made active, it should appear on other screens on the tool and vice versa.

  12. Store Status table should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc




