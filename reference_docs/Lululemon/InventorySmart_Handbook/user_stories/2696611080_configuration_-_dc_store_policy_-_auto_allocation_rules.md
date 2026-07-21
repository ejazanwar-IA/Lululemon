# Configuration -> DC Store Policy -> Auto Allocation Rules

| Field | Value |
|---|---|
| Confluence page ID | `2696611080` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611080/Configuration+-+DC+Store+Policy+-+Auto+Allocation+Rules |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:23.066Z |
| Last mirrored | 2026-05-21 |

---

# Guideline

  * The text in blue color are configurable or optional. Based on the client requirement, make the required adjustment to the story

  * Filters are configurable as per clients requirement.

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**




# User Story

## **Jira Summary: [Client Name] - Development of Configuration -> DC Store Policy -> Auto Allocation Rules**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

This section allows users to edit/delete/create new auto-allocation rules. Auto allocation is the automated trigger of allocating inventory to stores, based on predefined constraints and strategies.

These rules can be mapped to the hierarchies present in the DC Store Strategy section -> Auto Allocation Rules column.

As an Allocator, my goal is to establish Auto Allocations, to increase efficiency and reduce manual efforts.

Auto allocation is the automated trigger of allocating inventory to Stores, based on predefined constraints and strategies. The 'Auto Allocation Rules' Screen allows me to create rules that drive the Auto Allocation triggering process.

### _Navigation:_

Left-hand panel -> Configuration -> DC Store Policy -> Auto Allocation Rules

###  _Landing Page:_

All the existing created Rules are visible with an ability to Edit/Delete existing rules and option to create New Rules.

As an Allocator, I am looking for the following functionalities in the 'Auto Allocation Rule' screen:

  1. Create a new auto-allocation rule.

  2. Edit any existing Auto Allocation rule.

  3. Delete an existing Auto Allocation Rule.

  4. View details of the Modifications to the Rule.




As an Allocator, I am expecting the following components in my rule definition to create an Auto Allocation rule:

  1. **Set Auto Approve (Yes/No toggle):** Users can determine whether the Auto-Allocation requires User Approval or not. If this is set to True then the Auto Allocation will be moved to Order Batching. **{NOTE: This is required only if the Order Batching module is there}**

  2. **Set Auto Release (Yes/No toggle): **Users can determine whether the Auto-Allocation requires User Release or not. If this is set to True then the Auto Allocation will be finalized and downstream file is created and set to the client. **{NOTE: This is required only in case Order Batching module is not there}**

  3. **Set Cut-Off WOS** \- This involves setting a cut-off Weeks of Supply (WOS). The cut-off WOS is then compared with WOS based on current DC ATA, triggering Auto-Allocation if it is less ((e.g. cutoff WOS = 7, which implies whenever WOS is below cutoff WOS (7), this rule will be in consideration).

  4. **Triggered if MinStock not Satisfied** \- If the current DC ATA is less than the specified Minimum Constraint, Auto-Allocation is triggered. (Yes/No)

  5. **Set Minimum DC Inventory** -**** Set Minimum DC Inventory (Available to Allocate). Users can set a minimum inventory level for DCs.

  6. **Set WOS Threshold** \- Here, I can establish a threshold percentage and a condition. The rule compares WOS based on the current ATA with TWOS (Target Weeks of Supply) multiplied by the Threshold %. Auto Allocation is triggered based on the given condition (e.g. Current WOS <= 0.7 * Target WOS).




Using the above components I would formulate a rule definition and add a rule name to it. This rule will be linked to RCLs in the 'DC to Store Strategy' Screen.

Users should be able to choose the AND/OR operator when defining rules. They should also be able to edit the rule logic, including adjusting brackets to control the order of execution.

**Default/Mandatory/Enable-Disable conditions for above Rules:**

**Rule**| **Mandatory (Y/N)**| **Default Selection**| **Rule Enable-Disable toggle**| **Additional comments**| **Operator**  
---|---|---|---|---|---  
Set Auto Approve| Y| **No**(selection in the toggle)| Yes| Selection can be turned to Yes from No| AND  
Triggered if MinStock not Satisfied| N| **No**(selection in the toggle)| Yes| Selection can be turned to Yes from No| AND/OR  
Set Minimum DC Inventory| N| None| No| The rule either needs to get some valid user input or rule needs to be disabled incase of no input| AND/OR  
Set WOS Threshold| N| None| No| The rule either needs to get some valid user input or rule needs to be disabled incase of no input| AND/OR  
Set CutOff WOS| N| None| No| The rule either needs to get some valid user input or rule needs to be disabled incase of no input| AND/OR  
  
#### ** _Create a new Auto Allocation Rule:_**

  1. I'll initialize the Auto Allocation Rule creation by clicking on the "Create Rule" on the landing page.

  2. The following is the illustration of the "Create Rule" page. By default, Set Auto Approve (or Set Auto Release) will be shown and the user can toggle to set it on or off.

  3. Then the User can click on Add Rules and Add the rest of the Rules as per their requirement

  4. With these rules/components, a rule definition will be created automatically. This will be a logical expression of the above-mentioned rules/components. 

  5. After creating the rule definition, I would add a rule name to it and click on 'Save Rule' to save the rule. Rule Name: Rule 1 AND RULE 2 AND RULE 3 AND RULE 4 AND RULE 5. 

  6. Note on (5): User input for Rule Name is optional. If provided, duplicate Rule Names need to be checked. In cases where the user leaves it blank, the default naming logic should be implemented.




#### **_Edit an existing Auto Allocation Rule_**

Any existing rule might require modifications. As a user, I expect the following flow and functionalities in this section. 

  1. I will navigate to any existing rule and click on the "Edit" icon on the landing page.

  2. After clicking on edit, the user should be able to view and edit the existing rules.

  3. I should see the existing rule definition and the existing rules/components of the corresponding Auto-allocation rule that I want to edit. 

  4. After the required modifications I would click on 'Save Rule' to save the changes.




#### **_Delete an existing Auto Allocation Rule_**

  1. I can delete any existing Auto Allocation rule, by clicking on the delete icon in the corresponding rule.

  2. On deleting any rule the following warning should pop up.


![image-20250704-074554.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611080/image-20250704-074554.png?version=1&modificationDate=1779356663199&cacheVersion=1&api=v2&width=443&height=283)

### **_Acceptance Criteria:_**

  1. Screen load time - within 1 sec, Screen loading after clicking on edit/create rule - within 1 sec, Screen refresh time after deleting any rule - within 1 sec. Attaching the rule to the hierarchy in DC-Store strategy section should not take longer than 4 seconds

  2. No two rule names are to be kept identical.

  3. Should have all the general table functionalities like sorting based on a column, auto-fit column width, adjusting font size, etc.

  4. The user should be able to create Auto Allocation rules and be able to tag them in the DC-Store Strategy module in the DC-Store policy section at a Rule level.

  5. Once Auto Allocation rules are tagged to a particular RCL, the RCL elements that qualify for these Auto Allocation conditions should be considered while generating Auto Allocations for the entered time period




