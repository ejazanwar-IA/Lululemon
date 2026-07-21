# Configuration -> DC Store Policy -> DC Store Strategy Rules

| Field | Value |
|---|---|
| Confluence page ID | `2696611046` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611046/Configuration+-+DC+Store+Policy+-+DC+Store+Strategy+Rules |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:22.466Z |
| Last mirrored | 2026-05-21 |

---

# Guideline

  * The text in blue color are configurable or optional. Based on the client requirement, make the required adjustment to the story

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**




# User Story

## **Jira Summary: [Client Name] - Development of Configuration -> DC Store Policy -> DC Store Strategy Rules**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

This section allows users to edit/delete/create new DC to store strategy rules used for Auto allocation / Manual Allocation, which can later be mapped to the hierarchies present in the DC Store Strategy section.

### _Navigation:_

Left-hand panel -> Configuration -> DC Store Policy -> DC Store Strategy Rules

###  _Landing Page:_

All the existing created Rules are visible with an ability to Edit/Delete existing rules and option to create New Rules.

As an Allocator, I am looking for the following functionalities in the 'DC to Store Strategy Rules' screen:

  1. Create a new DC to Store Strategy rule.

  2. Edit any existing DC to Store Strategy rule.

  3. Delete an existing Rule.

  4. View details of the Modifications to the Rule.




As an Allocator, I am expecting the following components in my rule definition to create a DC to Store Strategy rule:

  1. **DC to Store Allocation Strategy:** This component drives how the system allocates units, depending on the selected strategy. There are three distinct allocation strategies to be shown in the dropdown (mentioned in blue):

     1. **Mins First then WOS** : As an allocator I want the system to prioritize meeting the Minimum OH requirement in the stores first. Subsequently, it should aggregate demand based on the Weeks of Supply (WOS) period. This is the most commonly preferred strategy.

     2. **Mins Only** : This strategy is helpful in cases when the available DC ATA is very constrained. As an Allocator, When my available source inventory is significantly lower than the demand, I want the system to solely focus on satisfying the Mins.

     3. **WOS only:** Under this strategy, the system allocates the entire demand based on WOS. As an Allocator, I would prefer this approach when source inventory is abundant.

  2. **Inventory Source:** In this component, the Inventory source that needs to be considered for allocation needs to be Specified. The following are the distinct Inventory sources

     1. **DC Available to Allocate:** As an allocator, I would prefer to consider only the available to allocate (ATA) Inventory as the Inventory Source.

     2. **DC In Transit:** As an allocator, I would want to include the In Transit Inventory along with my On Hand inventory as an Inventory Source.

  3. **Prioritization Strategy:** This component helps to determine the order of priority that should be considered while allocating. The following are the available Prioritization Strategies to be shown in the dropdown (mentioned in blue) :

     1. **IA Priority:** The System will consider default prioritization based on the demand.

     2. **Fair Share:** As an Allocator, in case of a constrained inventory situation, instead of fulfilling the demand for only some stores with limited DC ATA, I want to distribute the available DC ATA to all eligible stores based on its demand proportions. In case of the same demand. In case of the same demand, Store Tier can be used as a tie-breaker followed by Store OH, and finally a random factor.

  4. **Demand type:** Within this system, we have the flexibility to modify the demand type considered for Allocation. There are three distinct demand types to be mentioned in the dropdown (mentioned in blue):

     1. **IA Forecast:** The demand calculation is derived from the forecast provided by IA.

     2. **Fixed Inventory Push:** As an allocator, I would want to push a specific percentage of inventory from the source. The demand is then calculated based on the input percentage provided.

     3. **{APS:** As an allocator, I would like to allocate to the stores based on the APS value for a choice. APS value range is from 0 to 10000.}




### **_Flow:_**

The Below default Rule should be created which is not editable once the filters are selected

Default Rule:

  1. Allocation Strategy = Mins first and then WOS

  2. Inventory Source: DC Available to Allocate

  3. Prioritization Strategy = IA Priority

  4. Demand Type = IA Forecast




#### ** _Create a new DC Store Strategy Rule_**

  1. I'll initialize the DC to Store Strategy Rule creation by clicking on the "Create Rule" on the landing page.

  2. The following is the illustration of the "Create Rule" page.

     1. Click on Create Rules

     2. Click on Add Rules

     3. Select Rules dropdown should have DC to Store Strategy, Inventory Source, Prioritization Strategy, Demand Type

  3. Rule Definition will get updated automatically

  4. Note that for demand type "Fixed Inventory Push", an additional user input of % push will be required.

  5. The user should add a Rule Name and click on "Save Rule" to create the Rule. This will now reflect on the landing page.




#### **_Edit an existing DC to Store Strategy Rule_**

Any existing rule might require modifications. As a user, I expect the following flow and functionalities in this section.9

  1. I will navigate to any existing rule and click on the "Edit" icon on the landing page.

  2. After clicking on edit, the Create Rules page with rule details will be displayed

  3. I should see the existing combination of the corresponding DC to Store Strategy rule that I want to edit.

  4. After the required modifications I would click on 'Save Rule' to save the changes




#### ** _Delete an existing DC to Store Strategy Rule_**

  1. I can delete any existing DC to Store Strategy Rule by clicking on the delete icon in the corresponding rule

  2. On deleting any rule the following warning should pop up.

![image-20250704-074554.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611046/image-20250704-074554.png?version=1&modificationDate=1779356662598&cacheVersion=1&api=v2&width=443&height=283)



### **_Acceptance Criteria:_**

  1. Screen load time - within 1 sec, Screen loading after clicking on edit/create rule - within 1 sec, Screen refresh time after deleting any rule - within 1 sec. Attaching the rule to the hierarchy in DC-Store strategy section should not take longer than 4 seconds

  2. No two rule names are to be kept identical.

  3. It should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  4. The user should be able to create DC to Store strategy rules and be able to tag them in the DC-Store Strategy module in the DC-Store policy section at a Rule level

  5. Once DC to Store strategy rules are tagged to a particular RCL, the Styles would run as per the Strategy set wrt the rule they would classify for (both for Manual as well as Auto Allocation)




**Invalid use case:**  
No same rule should be duplicated and there needs to be a front end check for preventing the same

