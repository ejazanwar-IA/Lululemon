# Configuration -> DC Store Policy -> Auto Allocation Scheduler

| Field | Value |
|---|---|
| Confluence page ID | `2696611113` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611113/Configuration+-+DC+Store+Policy+-+Auto+Allocation+Scheduler |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:23.675Z |
| Last mirrored | 2026-05-21 |

---

# Guideline

  * The text in blue color are configurable or optional. Based on the client requirement, make the required adjustment to the story

  * Filters are configurable as per clients requirement.




# User Story

## **Jira Summary: [Client Name] - Development of Configuration -> DC Store Policy -> Auto Allocation Scheduler**

## **Jira Description:**

### **Demo link: { Add React Demo - If available}**

As an allocator, I want have full control on the schedule of Auto allocations. I want my auto-allocation frequency to be externalized so that I can manipulate it as per business need. Auto allocation cadence might vary for different product and store combinations. In order to handle these use cases, I would be able to set different auto allocations schedule and tag that to required product hierarchies.

### _Navigation:_

Left-hand panel -> Configuration -> DC Store Policy -> Auto Allocation Scheduler

###  _Landing Page:_

As a user, I would expect the following functionalities on the landing page:

  1. View the existing schedulers

  2. Have the ability to Modify or Delete existing schedulers

  3. View details of the creator/ editor and the date when the last modification was made for the existing schedulers (will be the creation date if not modified).




#### **_Create a new Scheduler:_**

  1. I'll initialize the Scheduler creation by clicking on the "Create Scheduler" on the landing page.

  2. Choose the required Auto Allocation frequency and click on "Save"




User can choose required frequency from the frequency dropdown. In each of the 5 frequencies - user can select the actual calendar date or days to run auto allocations. User need to put scheduler name as it is mandatory.

#### **_Edit an existing Scheduler:_**

Any existing scheduler might require modifications. As a user, I expect the following flow and functionalities in this section.

  1. I will navigate to any existing scheduler and click on the "Edit" icon on the landing page.

  2. After clicking on edit, the following page needs to be displayed.

  3. I should see the existing scheduler that I want to edit.

  4. After the required modifications I would click on 'Save Rule' to save the changes




#### ** _Delete an existing Scheduler_**

  1. I can delete any existing Auto Allocation Scheduler by clicking on the delete icon in the corresponding scheduler.

  2. On deleting any rule the following warning should pop up.


![image-20250704-074554.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696611113/image-20250704-074554.png?version=1&modificationDate=1779356663807&cacheVersion=1&api=v2&width=443&height=283)

### **_Acceptance Criteria:_**

  1. Users must be able to create, view, edit, and delete frequencies in the 'Auto-allocation scheduler' tab.

  2. The scheduler must offer frequency options such as daily (all days, weekdays), weekly (specific days), and monthly (specific days of the week or month), quarterly and yearly.

  3. Users must be able to select time slots from a predefined list, which can vary from client to client.

  4. The scheduler must allow users to set a start date and choose an end date in three ways: specific end date, never-ending, or a number of occurrences.

  5. The system must automatically calculate and display the end date when the number of occurrences is selected.

  6. Each rule must be uniquely named by the user, and duplication of rule names is prohibited.

  7. The system must update the 'Modified by' and 'Modified at' fields properly once any changes are made in the scheduler.

  8. The default rule present in the landing screen of the Auto Allocation scheduler must be editable but not removable, and it should act as the default rule for all new or existing Product Hierarchy Rules without attached rules.




**Non-functional requirement**

  * Keep Scheduler as an individual entity and it's design should be scalable enough that it can be attached to any other processes other than auto allocations such as "downstream reports generation" in future.

  * During auto allocation time, at a run time, we must be able to identify the scheduler/s which are eligible at that time along with for each product-store combinations attached to it.

  * Data integrity should be maintained, with mechanisms in place to prevent data loss or corruption.



  1. Users must be able to create, view, edit, and delete frequencies in the 'Auto-allocation scheduler' tab.

  2. The scheduler must offer frequency options such as daily (all days, weekdays), weekly (specific days), and monthly (specific days of the week or month), quarterly and yearly.

  3. Users must be able to select time slots from a predefined list, which can vary from client to client.

  4. The scheduler must allow users to set a start date and choose an end date in three ways: specific end date, never-ending, or a number of occurrences.

  5. The system must automatically calculate and display the end date when the number of occurrences is selected.

  6. Each rule must be uniquely named by the user, and duplication of rule names is prohibited.

  7. The system must update the 'Modified by' and 'Modified at' fields properly once any changes are made in the scheduler.

  8. The default rule present in the landing screen of the Auto Allocation scheduler must be editable but not removable, and it should act as the default rule for all new or existing Product Hierarchy Rules without attached rules.




**Non-functional requirement**

  * Keep Scheduler as an individual entity and it's design should be scalable enough that it can be attached to any other processes other than auto allocations such as "downstream reports generation" in future.

  * During auto allocation time, at a run time, we must be able to identify the scheduler/s which are eligible at that time along with for each product-store combinations attached to it.

  * Data integrity should be maintained, with mechanisms in place to prevent data loss or corruption.




