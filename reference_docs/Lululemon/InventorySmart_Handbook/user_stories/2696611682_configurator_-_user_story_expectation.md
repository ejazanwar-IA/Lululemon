# Configurator - User Story Expectation

| Field | Value |
|---|---|
| Confluence page ID | `2696611682` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611682/Configurator+-+User+Story+Expectation |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:35.333Z |
| Last mirrored | 2026-05-21 |

---

## **Guidelines for Module Configurator Usage**

### **Purpose & Objective**

The **Module Configurator** is designed to empower the Delivery Team to configure Out-of-the-Box (OOTB) requirements independently. This reduces dependency on the Engineering Team and speeds up the delivery lifecycle.

* * *

### **Phase 1: Pre-Sprint Tasks (Preparation & Alignment)**

_These steps are essential for a seamless configuration process. To avoid mid-sprint delays, please ensure all tasks are completed._

  * **Feature Validation:** Verify if the required configurations are available in the Configurator.

    * **Action:** If a requirement is **not** OOTB, schedule a call before the sprint prioritization to discuss the same with Engineering team. These stories must be handled by Engineering and require bandwidth allocation during sprint prioritization.

    * If delivery team is not sure if a feature is OOTB or not - Reach out to [Raj Mohan B](https://impactanalytics.atlassian.net/wiki/people/5c7392fa84926c623fb1dccf?ref=confluence) / [Md Faraz Ashraf](https://impactanalytics.atlassian.net/wiki/people/61d691d6567cb70070ea3282?ref=confluence) / [Gowthami T](https://impactanalytics.atlassian.net/wiki/people/5f8956ac7d9637006f2b4591?ref=confluence) for the confirmation

    * Module Configurator Scope - <https://impactanalytics.atlassian.net/wiki/x/G4DTng>_(Please note this is still WIP)_

  * **Data Readiness:**

    * All data updates must be finalized before Day 1 of the sprint.

    * **Schema:** The Delivery Team must follow the exact schema aligned with the DSLs ([Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence) )

  * **Data Quality Control (QC):**

    * Run the **Data QC Script** and resolve all flagged issues.

    * **Mandatory:** Configuration cannot begin until the data preparation is clean and validated.

  * **Jira Hygiene & Documentation:**

    * Create user stories using the approved template ([Gowthami T](https://impactanalytics.atlassian.net/wiki/people/5f8956ac7d9637006f2b4591?ref=confluence) can provide the same)

    * **Freezing:** Stories must be finalized and "frozen" before the sprint starts—no scope changes mid-sprint.

    * **Requirements:** Each story must detail Filters, Table Columns, Module-specific configs, and correct Mapping Columns.

    * **Confirmation:** Add a comment to the Jira story once Data QC is completed to signal readiness.




* * *

### **Phase 2: Post-Sprint Start (Execution & Validation)**

_Once the sprint is live, follow the Agentic Configurator workflow._

  * **Trigger Automation:** Request the Agentic Configurator team to run the script to populate your configurations. 

    * Reach out to @Srikanth Katkuri to run the script

    * This script should ideally run only once for the set up. 

      * Additional runs can be accomodated only for certain genuine exceptions. Ideally if the data qc is valid and stories are in right format this should not be a issue.

  * **Initial Verification:** Audit the populated configs against the Jira ticket (General, Filter, and Table configs).

    * **Discrepancies:** If the output deviates from the Jira story, immediately highlight the issue to the **Agentic Team** (@Srikanth Katkuri).

  * **Manual Refinement:**

    * Validate the populated values within the Configurator UI and make manual edits if necessary.

    * **If at all these configs are not part of your Jira story - These changes should be reflected in the Jira Story mandatorily for QA team to validate**

  * **Product Testing:**

    * Perform a final test of the product after saving configurations.

    * **Support:** If technical issues persist, reach out to the Engineering Team.

    * _Note: Engineering support is for system issues; please ensure no data-related errors remain at this stage._

    * If there are data related issues which are already part of the data qc and still persists - then this will be flagged by Engg team as they would be spending time to debug this issue. This inturn will affect the aligned effort estimate.

    * Any data-related issues identified during configuration that were not part of the initial Data QC must be documented and integrated into the script logic immediately to prevent future recurrence. This has to be reported to [Aman Lakkoju](https://impactanalytics.atlassian.net/wiki/people/641c025e5534b0bf7441e5cc?ref=confluence) to add these new checks as part of the QC scripts




**Order of Operation**

|   
---|---  
Tuesday (Before Sprint Start)| 

  * Jira Stories to be created in correct template aligned
  * Required data to be populated with correct schema
  * Run both Jira validation script and Data QC script
  * Fix issues if there are any

  
Wednesday (Sprint Start Date)| 

  * Request the Agentic team to run the script and confirm successful execution.

  
Thursday| Validate whatever has been populated by the agent

  * If you see some bugs with what is populated - highlight that to Agentic team (to improve their agents)
  * Go ahead and make changes manually if you see any discrepency anyway

  
Thursday - Friday| 

  * Perform end-to-end product testing for the respective modules and validate if the configurations are reflecting and highlight any bugs to the Engg team
  * Rerun QC scripts if any data changes occurred before escalating to Engineering. 

  
  
### **Guidelines**

  * Jira stories and Configurator settings must remain identical. Since the Configurator is currently limited to the Dev environment, the QA team relies solely on the Jira story to test higher environments.

  * **Responsibility:** The Agentic Configurator is a tool to accelerate your work; configuration remains the responsibility of the story owner.




* * *

### **Non OOTB/ Custom Changes**

Any deviations from **Out-of-the-Box (OOTB)** requirements must be identified and aligned with the Engineering team before the sprint begins. Once aligned, follow the standard OOTB workflow, ensuring all non-standard changes are explicitly highlighted.

**Key Requirements for Non-OOTB Tasks:**

  * **Mandatory Mapping:** Custom columns must include a defined Mapping Column within the ticket.

  * **Validation:** Complete all standard Jira and Data QC validations. Run the Agentic config script and verify OOTB configurations on the product.

  * **Backend Implementation:** While the Agentic configurator may reflect changes on the frontend, Engineering must manually implement backend support.

  * **Handoff:** Once your validations are complete, tag the Engineering team in a ticket comment to initiate the backend development for the custom changes




* * *

## **Technical Jira Story/Data Guidelines**

### **1\. Hierarchies:**

Always use `l0_name`; do **not** use `l0_ID`.

### **2\. Dimension Attribute Mapping (FCM/TCM)**

Every product and store dimension attribute must be defined with both a **valid mapping column** and a **valid label**.

  * **Requirement:** Ensure the backend database column matches the UI label intent.

  * **Warning:** Providing a label without a mapping column (or vice versa) for standard dimensions will result in a configuration failure.

  * Duplicates should not be there for mapping columns




The sample below is incorrect.

![](https://mail.google.com/mail/u/0?ui=2&ik=9de900c3bc&attid=0.1&permmsgid=msg-f:1864177555298540551&th=19dee39c15d35c07&view=fimg&fur=ip&permmsgid=msg-f:1864177555298540551&sz=s0-l75-ft&attbid=ANGjdJ-vgpd_AkhGc3xk_qTxibt6pCUj5D9ljJXZysUkZeueKn6HVzLD7ej9IZEP2UjJBCvgH5fpbNli8x1EAYq3vfAnq_U03Fs5W0sgSTOsrlsnHpjcjT4r5mQLxiM&disp=emb&realattid=ii_mopre7tu0&zw)

### **3\. Data Type Accuracy (TCM)**

TCM requires explicit data types to render information correctly. All entries must be assigned one of the following valid types:

  * `string`

  * `float`

  * `int`

  * Ones with hyperlink to be mentioned as `/link`

  * **Validation:** Entries with missing or non-standard data types are considered incorrect and will be rejected.




The samples below are incorrect.

![](https://mail.google.com/mail/u/0?ui=2&ik=9de900c3bc&attid=0.2&permmsgid=msg-f:1864177555298540551&th=19dee39c15d35c07&view=fimg&fur=ip&permmsgid=msg-f:1864177555298540551&sz=s0-l75-ft&attbid=ANGjdJ9Gjd_MwPvfn504xXOI8JDgqgNS2do1mOdcprWlRsAPnbSy1xdOJ3wcVNIW69ec5fqbwv4pgDyd_5MmO3YAMeu0Gwi7KMrJ9IBFnS1g76ABlFyGFBC-wu6Nzxo&disp=emb&realattid=ii_moprmc011&zw)![](https://mail.google.com/mail/u/0?ui=2&ik=9de900c3bc&attid=0.3&permmsgid=msg-f:1864177555298540551&th=19dee39c15d35c07&view=fimg&fur=ip&permmsgid=msg-f:1864177555298540551&sz=s0-l75-ft&attbid=ANGjdJ8ssseoL_TQ1sfV0FgyEX5AsLZ8tG5h3X52DUvCr3am0UFC-EyOZMiBrhIVdaU0gpOqe-9qHwOXZgY21eNihTxTNtUtLGESKIoSRxz5nyUl4qDNDI4b2xgdo34&disp=emb&realattid=ii_moprmc0e2&zw)

### **4\. Mapping Logic for Custom Columns**

The logic for Mapping Columns depends on whether the column is **Out-of-the-Box (OOTB)** or a **New Custom Requirement** :

  * **OOTB Custom Columns:**

    * Leave the **Mapping Column empty**.

      * **Reason:** These are already "solved" in the backend. Entering a mapping column here may create an override that breaks the existing UI table logic.

      * _Example Case:_ If using `oh` aliased as `dc_oh`, **do not** override `dc_oh` with `oh` in the TCM. Doing so will cause the column to disappear from the UI.

      * **Reference:** [MTP-138529](https://impactanalytics.atlassian.net/browse/MTP-138529)

    * Labels for the **OOTB Custom Columns** should not change client wise. Generic user story should be updated for the same ([Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence) to update this)


![](https://mail.google.com/mail/u/0?ui=2&ik=9de900c3bc&attid=0.4&permmsgid=msg-f:1864177555298540551&th=19dee39c15d35c07&view=fimg&fur=ip&permmsgid=msg-f:1864177555298540551&sz=s0-l75-ft&attbid=ANGjdJ8lFucXJfB9Skw-gDy5Y6N-ypQMOtfe1U8BobqF0ETkuptjgwR93JgdzwnF7107tRs75nqWe7nzhaX24tg-0hpOGECSrbustXBcRj8LEZo32WhajtHok-u2JcQ&disp=emb&realattid=ii_mops3udn3&zw)

  * **Non-OOTB Custom Columns:**

    * A **Mapping Column is mandatory**.

    * **Alignment:** These specific use cases must be aligned with the Engineering/DSLs **before the sprint starts** to ensure the backend supports the new mapping.




### **5\. Header for the Jira tickets should remain consistent**

**Product Profile**

  * Development of Product Profile Module




**Product Grouping**

  * Development of Grouping → Product Group




**Store Grouping**

  * Development of Grouping → Store Group




**Configuration**

  * Development of Configuration → Product → Product Status

  * Development of Configuration → Store → Store Status

  * Development of Configuration → Product → Product-Store Mapping

  * Development of Configuration → DC → DC Status

  * Development of Configuration -> Product -> Product-DC Mapping

  * Development of Configuration -> Store -> Store-DC Mapping

  * Development of Configuration → Product → Product Supersession

  * Development of Configuration → DC-Store Policy → DC Store Strategy

  * Development of Configuration → New Store




**Decision Dashboard**

  * Development of Decision Dashboard → Details Table

  * Development of Decision Dashboard → Shortfall Alerts

  * Development of Decision Dashboard → Stockout Alerts

  * Development of Decision Dashboard → Overstock Alerts

  * Development of Decision Dashboard → Auto Allocation Alert

  * Development of Decision Dashboard → Recent Deviation Alerts

  * Development of Decision Dashboard → MFP Deviation

  * Development of Decision Dashboard → View Allocation Plan




**Allocation**

  * Development of Order Batching Screen

  * Development of View Past Allocation




**Constraints**

  * Development of Constraints → Store Allocations

  * Development of Constraints → User Reserve




**Reports**

  * Development of Reports → Store Stock Drilldown

  * Development of Reports → Daily Allocation Summary

  * Development of Reports → Excess Inventory

  * Development of Reports → Lost Sales

  * Development of Reports → Deep Dive Allocation

  * Development of Reports → New Store Performance Tracking Report




**CNA (Create New Allocation)**

  * Create New Allocation → Details Table

  * Create New Allocation → Review Store and DC

  * Create New Allocation → Recommendation Screen

  * Create New Allocation → Recommendation Screen → Store Capacity




### **6\. Addition of TC names and FC names**

  * tc names and fc names to be present  
  





* * *

### **Modules inscope for Configurator**

  * Product Status, Product - Store Mapping, Product - DC Mapping

  * Store Status, Store - DC mapping

  * DC Status

  * Product Group

  * Store Group

  * Constraints




