# Downstream File Generation and Integration

| Field | Value |
|---|---|
| Confluence page ID | `2696611649` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611649/Downstream+File+Generation+and+Integration |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:34.660Z |
| Last mirrored | 2026-05-21 |

---

# Guideline

  * This is a fully customizable story




# User Story

## **Details:**

Once the allocations are finalized either manually or auto released, allocation output file(s) is/are generated and sent to the client via SFTP or GCS bucket. The client can then use this file for their downstream processes.

**File Format acceptable:**

  1. Tab delimited text file (.txt)

  2. Comma separated values (.csv)




**Acceptable Destinations:**

  1. SFTP

  2. GCS Bucket

  3. Azure (WIP)




Multiple files can be generated for a single allocation depending upon the client's requirement, mostly based on the DCs.

**Frequency:**

  1. Real time - When the allocations are finalized

  2. Batch Processing - File generation can be scheduled to run at fixed interval (1 hour, 2 hour,…)

  3. One Time - At the end of the day, allocation files will be generated and sent




**File Requirement:**

Basic and necessary columns required for the downstream file is as below:

**Column Name**| **Mapping Column**| **Comments**  
---|---|---  
Allocation ID| allocation_code| The unique identifier for each allocation  
Product Code| product_code|   
Store Code| store_code|   
DC Name| dc_code|   
Allocated Units| allocated_total| The allocated quantity for each product, store, dc and allocation code combinations  
Delivery Date| | The expected delivery date  
  
In addition to this any product hierarchy, store hierarchy or static column (with fixed value) can be added.

For PO/ASN allocations, PO ID or ASN ID can be added as an additional column.

**NOTE:** For pack allocations, pack id will be added in the Product Code.

**Folder and File Naming:**

For each day, a date level folder would be created where all the allocation files for that day would be stored.

If there is a requirement to have a different folder structure, then that will be evaluated and based on the effort level can be treated as a CR.

Default file naming - results_YYYYMMDDHHMMSS (considering only one file generated for an allocation)

File name can be customized (avoid too complex logic)

**_Acceptance Criteria:_**

  1. The allocated quantity for a product, store, dc and allocation code level in the file should match with the frontend data.

  2. There should be no duplicates at product, store, dc and allocation code level.

  3. Only rows with allocated quantity > 0 should show up.

  4. Allocated quantity should not exceed the DC total available units.

  5. The folder structure should be created as per the requirement

  6. The generated files should be placed in correct folder (date level or any customized one)

  7. The generated files should be sent to the required destination.

  8. The files should be generated as per the frequency stated.




