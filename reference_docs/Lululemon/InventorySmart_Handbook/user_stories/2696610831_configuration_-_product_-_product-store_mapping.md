# Configuration -> Product -> Product-Store Mapping

| Field | Value |
|---|---|
| Confluence page ID | `2696610831` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610831/Configuration+-+Product+-+Product-Store+Mapping |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:18.145Z |
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

## **Jira Summary: [Client Name] - Development of Configuration -> Product -> Product-Store Mapping**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

The user should possess the capability to modify the eligible stores for a product. The 'Products-Store' screen serves as a tool to view/add/modify eligibility. The mappings that are active in the table '**rule-store mapping** ' establish the foundation for Product-Store base eligibility.

### _Navigation:_

Left-hand panel -> Configuration -> Product -> Product Mapping -> Product-Store

###  _Landing Page:_

**The functionalities that should be applicable:**

  1. View Rule-Store Mapping: Apply a set of hierarchy filters and view the list of the rules in the hierarchy and the corresponding mapped stores.

  2. Create New Rule/Add Hierarchy: Create a New Rule (Style-Size combination as a Rule) or Edit an existing Rule (Adding Size as an additional hierarchy)

  3. Create New Store Eligibility: Map new stores to existing rules.

  4. Edit Eligibility: Edit existing eligibility between product-store combinations.

  5. Edit Mapping Period: Ability to add/modify start date and end date to the existing eligibility.




### _Filters:_

By clicking on '**Select Filters** ', the user can apply a set of hierarchy filters to get the list of the rules in the corresponding hierarchy. Refer to the table below for filter details. Only product-related filters are to be present on this screen.

**fc_name : ps mapping rules list**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Multi select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi select  
  
### ** _Flow:_**

#### **_View the Product Store Mapping:_**

The following is the expected flow of the Product Store Mapping Screen:

  1. By clicking on 'Select Filters', The user will apply a set of hierarchy filters to get the list of the products in the corresponding hierarchy.

  2. Once the filters are selected, the Product table is populated. The loaded table **Filtered Product** should have following columns:




**tc_name : ps_mapping_rules_list**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**|   
---|---|---|---|---|---|---|---|---  
Product| SKU ID| product_code| | varchar| No| Yes| Yes|   
Product| Description| product_description| global.product_attributes_filter| text| No| Yes| Yes|   
Product| Style-Color ID| article| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| Yes| Yes|   
Product| {Product Attributes}| {product_attribute}| global.product_attributes_filter| varchar / date| Yes| Yes| Yes|   
Custom| Mapped Stores| | | | | No| No| Clicking this should open the popup window with mapped stores details  
  
The landing screen shows the product hierarchies, and mapped stores. The Rule Creation Level for Map Products is defaulted to {**Style Color ID -**(can some some other hierarchy)**}**. Multiple Rules can be created within this Rule Creation Level, where {**Style Color ID}** is a mandatory hierarchy to be chosen. The rules are populated based on the filter selection.

The user can view the mapped stores by clicking on the hyperlink in the column - Mapped Stores. The **Edit Rules** and **Modify** options can be used to edit the rules/mapping.

#### **_Modify Mapping for Existing Rules:_ **

Step 1: The user should select the appropriate filter and see rules corresponding to the selected filters on the landing page. 

Step 2: The Mapped Stores column must be clickable, and on clicking it, the user should get a pop-up to see the stores mapped to the corresponding rule.

The columns in the view popup should be:

**tc_name : view_mapped_store_tier_ps_mapping**

**Section**| **Column Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Store| Store Number| store_code| | varchar| No| Yes| Yes  
Store| Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {Channel}| {channel}| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {S1 Name}| {s1_name}| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {Store Attribute}| {store_attribute}| global.store_attributes_filter| varchar / date| Yes| Yes| Yes  
Custom| Time Period -> From Date| | | | No| No| No  
Custom| Time Period -> To Date| | | | No| No| No  
  
#### The below flow is applicable only if client is using the tool to update the product store mapping. If client is sending the feed then modify and edits are not required in tool

If the user wants to edit the stores mapped to Rule. The following is the expected flow in this screen.  
Step 3: The user can modify the Mapped Stores by clicking on the MODIFY button on the dialogue box, or by directly clicking on the MODIFY button on the landing screen.

Step 4: Clicking on the MODIFY button should redirect the user to another screen where they can turn off any existing mapping / change the date range. The user can modify the mapping for multiple stores using Set All. 

The Filters in the Modify screen should be as below:

**fc_name : ps mapping modify rules**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---  
Store| {S0 Name}| s0_name| global.store_attributes_filter| Yes| Single Select  
Store| {S1 Name}| s1_name| global.store_attributes_filter| No| Multi Select  
Store| {S2 Name}| s2_name| global.store_attributes_filter| No| Multi Select  
Store| {Store Attribute}| store_attribute| global.store_attributes_filter| No| Multi Select  
  
The columns in the table:

**tc_name : ps_mapping_modify_rules_map**

**Section**| **Column**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Searchable**| **Sortable**  
---|---|---|---|---|---|---|---  
Store| Store Number| store_code| | varchar| No| Yes| Yes  
Store| Store Name| store_name| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {Channel}| {channel}| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {S1 Name}| {s1_name}| global.store_attributes_filter| varchar| No| Yes| Yes  
Store| {Store Attribute}| {store_attribute}| global.store_attributes_filter| varchar / date| Yes| Yes| Yes  
Custom| Action|  | | | | No| No  
  
Users can change the mapping time period for each row using the Action column. Click on **Modify Time Period** -> In the Popup screen, add the Start Date and End Date and click on Apply.

**Unmap Set All** \- This can be used to unmap multiple stores and SKUs combinations at once.

**Set All** \- Mapping for multiple stores and SKUs can be adjusted with different time period and status by using the Set All. Select some stores and click on Set All, a pop up screen will appear.

![image-20250703-114749.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610831/image-20250703-114749.png?version=1&modificationDate=1779356658283&cacheVersion=1&api=v2&width=760&height=318)

Set different start and end dates for mapping.

#### **_Add Rules:_ **

The User can edit the Rules by either clicking on the '**ADD RULES** ' button on top of the landing page table.

On clicking the, the user is redirected to a screen, where the user can edit the existing rules / add new rules. 

  1. Two rule levels are available: {Style Color Level, and Style Color Size level}.

  2. The user can click on '**Add Rules** ' to add a new rule.

  3. The user is prompted to select date range, product selection and store selection.




Product Selection Filters:

**fc_name : New Rule Product Filters**

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---  
Product| {L0 Name}| l0_name| global.product_attributes_filter| Yes| Single Select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| Yes| Multi Select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| No| Multi Select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| No| Multi Select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| No| Multi Select  
Store| {S0 Name}| s0_name| global.store_attributes_filter| Yes| Single Select  
Store| {S1 Name}| s1_name| global.store_attributes_filter| No| Multi Select  
Store| {S2 Name}| s2_name| global.store_attributes_filter| No| Multi Select  
Store| {Store Attribute}| store_attribute| global.store_attributes_filter| No| Multi Select  
  
### ** _Acceptance Criteria:_**

  1. No duplicate Rules should be present.

  2. If a product store is made active/inactive for a rule, it should reflect in the allocation flow on the tool.

  3. The table in the landing screen should be populated based on the filters selected.

  4. By default, for a Style-Store level mapping, all the Active Sizes within the Style should be mapped to the stores. If there exists a rule corresponding to Style-Store mapping, and a Style-Size-Store Mapping is added newly, then the Style-Size-Store Mapping only should be retained.




**Performance Expectations**

  1. Should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  2. Screen load time for filters - within 1 sec, style loading after applying filters - within 3 sec, pop-up load times - within 2 sec.




