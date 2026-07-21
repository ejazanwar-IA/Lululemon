# Reports - User Story

| Field | Value |
|---|---|
| Confluence page ID | `2696611595` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611595/Reports+-+User+Story |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:33.284Z |
| Last mirrored | 2026-05-21 |

---

| **Update Date** | **Updated By** | **Description** |
| --- | --- | --- |
| <custom data-type="date" data-id="id-0">5/6/2026</custom> | <custom data-type="mention" data-id="id-1">@Navin Chandan</custom> | Removed mapping columns for the OOTB columns |
| <custom data-type="date" data-id="id-2">4/10/2026</custom> | <custom data-type="mention" data-id="id-3">@Navin Chandan</custom> | Added fc_name and tc_name |
| <custom data-type="date" data-id="id-4">3/31/2026</custom> | <custom data-type="mention" data-id="id-5">@Navin Chandan</custom> | Added mapping table, datatype and nullable column for validation in filters and tables Title case naming as per latest guideline Store Stock Drilldown → Product View |

# Table of Contents

# Guideline

* The **text in blue color and in curly brackets are configurable or optional**. Based on the client requirement, make the required adjustment to the story. **Make sure you remove the curly bracket from the column naming**
* Filters are configurable as per clients requirement.
* Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**
* Please keep the **fc_name** and **tc_name** as it is. This is used for **Agentic Application Configurator**
* Please maintain the **Section** column for all the tables and filters. Any product and store hierarchy and attributes should be added as **Product** and **Store** respectively. Others should be added as **Custom**.
* Add the below **Jira Summary in the ticket Summary and the Jira Description in the description field of the ticket**. No need to mention the Jira Summary and Jira Description in the description field

# User Story 1 - Store Stock Drilldown

## **Jira Summary: \[Client Name\] - Development of Reports -> Store Stock Drilldown**

## **Jira Description:**

The Store Stock Drilldown report is a module providing essential insights into product performance across various stores and sales KPIs. This report streamlines inventory management and empowers decision-making for optimal allocation. The Store Stock Drilldown is a daily refresh table and is not editable by the user.

The Store Stock Drilldown report can be accessed through the ‘Store Stock Drill down' tab in the reports module. 

### Navigation:

Left-hand panel → Reports → Store Stock Drilldown

### Landing Page:

Once the filters are applied, the table should populate with all the product for the selected filters.

There should be 2 tabs:

1. Product View - The default view. This will show all the metrics aggregated at product (article) level
2. Product Store View - This will show the data at product-store combinations level.

### Filters:

By clicking on ‘**Select Filters**’, the user can apply a set of hierarchy filters to get the list of the product store in the corresponding hierarchy. Refer to the table below for filter details. Both Product and Store level filters can used.

**fc_name : inventorysmart_store_stock_drill_down**

| **Section** | **Filter Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Mandatory** | **Selection Criteria** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Single select |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Multi select |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Store | {S0 Name} | s0_name | global.store_attributes_filter | varchar | No | No | Multi Select |
| Store | {S1 Name} | s1_name | global.store_attributes_filter | varchar | No | No | Multi Select |

### **Flow:**

The following is the expected flow of the Store Stock Drilldown Screen:

1. By clicking on ‘Select Filters’, The user will apply a set of hierarchy filters to get the list of the products and stores in the corresponding hierarchy. 
2. Once the filters are selected, the Report has the appropriate product combinations populated in the Product View
3. User can click on Product Store View to see the data at product and store combinations.

The following is the schema of **Store Stock Drilldown - Table View** → Product View:

**tc_name: report_store_stock_drilldown_product_view**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** | **Comments** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Product Code} | article or product_code | store_stock_drilldown | STRING | No | Yes | Yes |  |
| Product | {L0 Name} | l0_name | store_stock_drilldown | STRING | No | Yes | Yes | Product Hierarchy or Attributes |
| Product | {L1 Name} | l1_name | store_stock_drilldown | STRING | No | Yes | Yes |
| Product | {L2 Name} | l2_name | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | {L3 Name} | l3_name | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | {L4 Name} | l4_name | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | Style Color ID | article | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | Size | size | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Custom | # Stores | Calculated | store_stock_drilldown |  | No | Yes | Yes |  |
| Custom | Article Status | article_status | store_stock_drilldown | STRING | No | Yes | Yes |  |
| Custom | Product Type | article_status_tag | store_stock_drilldown | STRING | No | Yes | Yes |  |
| Custom | LW units | Calculated | store_stock_drilldown | INTEGER | Yes | Yes | Yes | sum(lw_qty) |
| Custom | Size Integrity | Calculated | store_stock_drilldown | FLOAT | Yes | Yes | Yes | sum(size_integrity \* oh) / sum(oh) |
| Custom | WOS (OH) | Calculated | store_stock_drilldown | FLOAT | Yes | Yes | Yes | sum(wos_oh \* (oh) ) / sum(oh) |
| Custom | WOS (OH + IT) | Calculated | store_stock_drilldown | FLOAT | Yes | Yes | Yes | sum(wos_oh_it \* (oh+it) ) / sum(oh+it) |
| Custom | WOS (OH + IT + OO) | Calculated | store_stock_drilldown | FLOAT | Yes | Yes | Yes | sum(wos_oh_it_oo \* (oh+it+oo) ) / sum(oh+it+oo) |
| Custom | On Hand | Calculated | store_stock_drilldown | INTEGER | Yes | Yes | Yes | sum(oh) |
| Custom | In Transit | Calculated | store_stock_drilldown | INTEGER | Yes | Yes | Yes | sum(it) |
| Custom | On Order | Calculated | store_stock_drilldown | INTEGER | Yes | Yes | Yes | sum(oo) |
| Custom | Total Inventory | Calculated | store_stock_drilldown | INTEGER | Yes | Yes | Yes | sum(total_inv) |
| Custom | DC Inventory | dc_total_inv | store_stock_drilldown | INTEGER | Yes | Yes | Yes |  |
| Custom | DC Available to Allocate | available_to_allocate | store_stock_drilldown | INTEGER | Yes | Yes | Yes |  |
| Custom | Store In-Stock | Calculated | store_stock_drilldown | varchar | Yes | Yes | Yes | avg(str_instock) |
| Custom | DC WOS (OH + IT + OO) | dc_wos_oh_oo_it | store_stock_drilldown | varchar | Yes | Yes | Yes |  |
| Custom | DC WOS (OH + IT) | dc_wos_oh_oo | store_stock_drilldown | varchar | Yes | Yes | Yes |  |
| Custom | DC WOS (OH) | dc_wos_oh | store_stock_drilldown | varchar | Yes | Yes | Yes |  |
| Custom | LW Sales $ | Calculated | store_stock_drilldown | varchar | Yes | Yes | Yes | sum(lw_revenue) |

‌

The following is the schema of **Store Stock Drilldown - Table View** → Product-Store View:

**tc_name: report_store_stock_drilldown_store**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** | **Comments** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Product Code} | article or product_code | store_stock_drilldown | STRING | No | Yes | Yes |  |
| Product | {L0 Name} | l0_name | store_stock_drilldown | STRING | No | Yes | Yes | Product Hierarchy or Attributes |
| Product | {L1 Name} | l1_name | store_stock_drilldown | STRING | No | Yes | Yes |
| Product | {L2 Name} | l2_name | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | {L3 Name} | l3_name | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | {L4 Name} | l4_name | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | Style Color ID | article | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Product | Size | size | store_stock_drilldown | STRING | Yes | Yes | Yes |
| Store | Store Number | store_code | store_stock_drilldown | STRING | No | Yes | Yes | Store Hierarchy or Attributes |
| Store | Store Name | store_name | store_stock_drilldown | STRING | No | Yes | Yes |
| Store | {S1 Name} | s1_name | store_stock_drilldown | STRING | No | Yes | Yes |
| Store | {S2 Name} | s2_name | store_stock_drilldown | STRING | No | Yes | Yes |
| Store | Store Grade / Tier | store_grade | store_stock_drilldown | STRING | No | Yes | Yes |
| Custom | Article Status | article_status | store_stock_drilldown | STRING | No | Yes | Yes |  |
| Custom | Store Status | store_status | store_stock_drilldown | STRING | No | Yes | Yes |  |
| Custom | Product Type | article_status_tag | store_stock_drilldown | STRING | No | Yes | Yes |  |
| Custom | LW units | lw_qty | store_stock_drilldown | INTEGER | Yes | Yes | Yes |  |
| Custom | Size Integrity | size_integrity | store_stock_drilldown | FLOAT | Yes | Yes | Yes |  |
| Custom | WOS (OH) | wos_oh | store_stock_drilldown | FLOAT | Yes | Yes | Yes |  |
| Custom | WOS (OH + IT) | wos_oh_it | store_stock_drilldown | FLOAT | Yes | Yes | Yes |  |
| Custom | WOS (OH + IT + OO) | wos_oh_it_oo | store_stock_drilldown | FLOAT | Yes | Yes | Yes |  |
| Custom | On Hand | oh | store_stock_drilldown | INTEGER | Yes | Yes | Yes |  |
| Custom | In Transit | it | store_stock_drilldown | INTEGER | Yes | Yes | Yes |
| Custom | On Order | oo | store_stock_drilldown | INTEGER | Yes | Yes | Yes |
| Custom | Total Inventory | total_inv | store_stock_drilldown | INTEGER | Yes | Yes | Yes |  |
| Custom | DC Inventory | dc_total_inv | store_stock_drilldown | INTEGER | Yes | Yes | Yes |  |
| Custom | DC Available to Allocate | available_to_allocate | store_stock_drilldown | INTEGER | Yes | Yes | Yes |  |
| Custom | Store In-Stock | str_instock | store_stock_drilldown | varchar | Yes | Yes | Yes |  |
| Custom | DC WOS (OH + IT + OO) | dc_wos_oh_oo_it | store_stock_drilldown | varchar | Yes | Yes | Yes |  |
| Custom | DC WOS (OH + IT) | dc_wos_oh_oo | store_stock_drilldown | varchar | Yes | Yes | Yes |  |
| Custom | DC WOS (OH) | dc_wos_oh | store_stock_drilldown | varchar | Yes | Yes | Yes |  |
| Custom | LW Sales $ | lw_revenue | store_stock_drilldown | varchar | Yes | Yes | Yes |  |

‌

If the report is at Style Color (Article or choice or Styles) level and not at product code level, then based on requirement, inventory and sales data can be made hyperlink to show the inventory and sales data at size level (product code level). This is valid for columns like On Hand, In Transit, On Order and LW Sales.

On clicking the hyperlink, a popup table should load with corresponding details at size level. Sample table schema  should be as per below:

**tc_name : report_ssd_article_size**

| **Section** | **Column Name** | **Mapping Column** | **Searchable** | **Sortable** |
| --- | --- | --- | --- | --- |
| Store | Store Number | store_code | Yes | Yes |
| Product | Sizes |  List of all sizes available with (OH / IT / OO or LW sales) | No | No |

The report should be downloadable. The download button should present at the top of the table.

### **Acceptance Criteria:**

1. The Store Stock Drilldown report should be accessible through the 'Store Stock Drilldown' tab in the reports module.
2. The report should provide essential insights into product performance across various stores and sales KPIs.
3. The report should be refreshed daily.
4. The report should not be editable by the user.
5. The report should populate the appropriate product and store combinations based on the selected filters.
6. The columns in the loaded table should be as per above.
7. If the hyperlink is there for On Hand, In Transit, On Order and LW Sales, then the hyperlink should load a new popup table.

# User Story 2 - Excess Inventory

## **Jira Summary: \[Client Name\] - Development of Reports -> Excess Inventory**

## **Jira Description:**

The Excess Inventory report offers a comprehensive overview of overstocking patterns observed across stores during the past 52 weeks. It is updated weekly to ensure that users have access to the most recent week information. Please note that the Excess Inventory report cannot be edited by users.

The Excess Inventory report can be accessed through the ‘Excess Inventory' tab in the reports module. The expected functionalities in the ‘Excess Inventory’ tab:

1. The report would show the appropriate Week, Style, and Store combinations as per the higher-level filters applied
2. Apply general table functionalities like sorting the table based on a column, Adjusting column width, etc.
3. Users can navigate through the Excess Inventory report and graph to review detailed information on Excess Inventory.
4. The Excess Inventory Graph is displayed from Fiscal Week 1 to the current Fiscal Week (FW), providing a chronological view of Excess Inventory opportunities.

**NOTE:** In the graph, only 10 weeks can show at a time. Even if the filters are applied to fetch 20 weeks of data. The Graph will show only 10 weeks.

### Navigation:

Left-hand panel → Reports → Excess Inventory

### Landing Page:

Once the filters are applied, the table should populate with all the product-store combinations for the selected filters.

### Filters:

By clicking on ‘**Select Filters**’, the user can apply a set of hierarchy filters to get the list of the product store in the corresponding hierarchy. Refer to the table below for filter details. Both Product and Store level filters can used.

**fc_name : Excess Inventory Reports Filters**

| **Section** | **Filter Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Mandatory** | **Selection Criteria** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | Date | From and To Date | global.fiscal_date_mapping | date | No | Yes | Date Picker |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Single select |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Multi select |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Store | {S0 Name} | s0_name | global.store_attributes_filter | varchar | No | No | Multi Select |
| Store | {S1 Name} | s1_name | global.store_attributes_filter | varchar | No | No | Multi Select |

### **Flow:**

The following is the expected flow of the Excess Inventory Screen:

1. By clicking on ‘Select Filters’, The user will apply a set of hierarchy filters to get the list of the products and stores in the corresponding hierarchy. 
2. Upon selecting the filters, the graph and report dynamically adjust to display the relevant week, SKU, and store.

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=a7f9fba93ba0&id=12cc6b29-85c3-444e-b168-831f98fb2c05&&collection=contentId-2696611595&height=306&occurrenceKey=null&width=1815&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
3. Along side the graph, on the left side, a summary Of Excess Inventory units and Excess Inventory cost should be shown. 
4. Below the graph and the summary, a table should load. At the top of the table, a dropdown will be displayed to select the fiscal week for which excess inventory reports need to be displayed in the table. 
5. The summary will correspond to the selected week. By default the latest fiscal week will be selected.

The following is the schema of Excess Inventory table:

**tc_name : inventorysmart_excess_inv_list**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** | **Comments** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Product Code} | article or product_code | excess_units | STRING | No | Yes | Yes |  |
| Product | {L0 Name} | l0_name | excess_units | STRING | No | Yes | Yes | Product Hierarchy or Attributes |
| Product | {L1 Name} | l1_name | excess_units | STRING | No | Yes | Yes |
| Product | {L2 Name} | l2_name | excess_units | STRING | Yes | Yes | Yes |
| Product | {L3 Name} | l3_name | excess_units | STRING | Yes | Yes | Yes |
| Product | {L4 Name} | l4_name | excess_units | STRING | Yes | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | excess_units | STRING | Yes | Yes | Yes |
| Product | Style Color ID | article | excess_units | STRING | Yes | Yes | Yes |
| Product | Size | size | excess_units | STRING | Yes | Yes | Yes |
| Store | Store Number | store_code | excess_units | STRING | No | Yes | Yes | Store Hierarchy or Attributes |
| Store | Store Name | store_name | excess_units | STRING | No | Yes | Yes |
| Store | {S1 Name} | s1_name | excess_units | STRING | No | Yes | Yes |
| Store | {S2 Name} | s2_name | excess_units | STRING | No | Yes | Yes |
| Store | Store Grade / Tier | store_grade | excess_units | STRING | No | Yes | Yes |
| Custom | Fiscal Year | fiscal_year | excess_units | INTEGER | No | No | No |  |
| Custom | Fiscal Week | fiscal_week | excess_units | INTEGER | No | No | No |  |
| Custom | Fiscal Year Week | fiscal_year_week | excess_units | INTEGER | No | No | No |  |
| Custom | OH | oh | excess_units | INTEGER | Yes | Yes | Yes |  |
| Custom | OO | oo | excess_units | INTEGER | Yes | Yes | Yes |  |
| Custom | IT | it | excess_units | INTEGER | Yes | Yes | Yes |  |
| Custom | Units Sold | units_sold | excess_units | INTEGER | Yes | Yes | Yes |  |
| Custom | WOS Threshold | wos_threshold | excess_units | FLOAT | Yes | Yes | Yes |  |
| Custom | Target WOS | target_wos | excess_units | FLOAT | Yes | Yes | Yes |  |
| Custom | Forward WOS | forward_wos | excess_units | FLOAT | Yes | Yes | Yes |  |
| Custom | Excess Inventory | excess_inv | excess_units | INTEGER | Yes | Yes | Yes |  |
| Custom | Excess Inventory ($) | excess_inv_cost | excess_units | FLOAT | Yes | Yes | Yes |  |
| Custom | Inventory Closing Balance | inventory_closing_balance | excess_units | INTEGER | Yes | Yes | Yes |  |

The report should be downloadable. The download button should present at the top of the table.

### **Acceptance Criteria:**

1. The Excess Inventory report should be accessible through the 'Excess Inventory' tab in the reports module.
2. The report should provide essential insights into excess inventory for the product store week combinations.
3. The report should be refreshed weekly.
4. The report should not be editable by the user.
5. The report should populate the appropriate product and store combinations based on the selected filters.
6. The columns in the loaded table should be as per above
7. The dropdown filter should have the latest fiscal week selected by default
8. The graph should show the max 10 weeks of excess units and cost data

# User Story 3 - Lost Sales

## **Jira Summary: \[Client Name\] - Development of Reports -> Lost Sales**

## **Jira Description:**

The Lost Sales report presents the sales lost, either in units or $, resulting from the unavailability or understocking of SKU in stores. It is updated weekly to ensure that users have access to the most updated information. Please note that the Lost Sales report cannot be edited by users.

The Lost Sales report can be accessed through the ‘Lost Sales' tab in the reports module. The expected functionalities in the ‘Lost Sales’ tab:

1. The report would show the appropriate Week, SKU, and Store combinations as per the higher-level filters applied.
2. Apply general table functionalities like sorting the table based on a column, Adjusting column width, etc.
3. Users can navigate through the Lost Sales report and Lost Sales Opportunity histogram graph to review detailed information on lost sales.
4. The Lost Sales Opportunity histogram is displayed from Fiscal Week 1 to the current Fiscal Week (FW), providing a chronological view of lost sales opportunities.

**NOTE:** In the graph, only 10 weeks can show at a time. Even if the filters are applied to fetch 20 weeks of data. The Graph will show only 10 weeks.

### Navigation:

Left-hand panel → Reports → Lost Sales

### Landing Page:

Once the filters are applied, the table should populate with all the product-store combinations for the selected filters.

### Filters:

By clicking on ‘**Select Filters**’, the user can apply a set of hierarchy filters to get the list of the product store in the corresponding hierarchy. Refer to the table below for filter details. Both Product and Store level filters can used.

**fc_name : Report Lost Sales Filters**

| **Section** | **Filter Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Mandatory** | **Selection Criteria** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | Date | From and To Date | global.fiscal_date_mapping | date | No | Yes | Date Picker |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Single select |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Multi select |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Store | {S0 Name} | s0_name | global.store_attributes_filter | varchar | No | No | Multi Select |
| Store | {S1 Name} | s1_name | global.store_attributes_filter | varchar | No | No | Multi Select |

### **Flow:**

The following is the expected flow of the Lost Sales screen:

1. By clicking on ‘Select Filters’, The user will apply a set of hierarchy filters to get the list of the products and stores in the corresponding hierarchy. 
2. Upon selecting the filters, the graph and report dynamically adjust to display the relevant week, SKU, and store.

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=7f1ada2f6304&id=2c07eead-3d4c-4845-807b-1dff329978c4&&collection=contentId-2696611595&height=328&occurrenceKey=null&width=1814&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
3. Along side the graph, on the left side, a summary Of Lost Sales units and Lost Sales Revenue should be shown. 
4. Below the graph and the summary, a table should load. At the top of the table, a dropdown will be displayed to select the fiscal week for which lost sales reports need to be displayed in the table. 
5. The summary will correspond to the selected week. By default the latest fiscal week will be selected.

The following is the schema of Lost Sales table:

**tc_name : report_lost_sales**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** | **Comments** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Product Code} | article or product_code | lost_sales | STRING | No | Yes | Yes |  |
| Product | {L0 Name} | l0_name | lost_sales | STRING | No | Yes | Yes | Product Hierarchy or Attributes |
| Product | {L1 Name} | l1_name | lost_sales | STRING | No | Yes | Yes |
| Product | {L2 Name} | l2_name | lost_sales | STRING | Yes | Yes | Yes |
| Product | {L3 Name} | l3_name | lost_sales | STRING | Yes | Yes | Yes |
| Product | {L4 Name} | l4_name | lost_sales | STRING | Yes | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | lost_sales | STRING | Yes | Yes | Yes |
| Product | Style Color ID | article | lost_sales | STRING | Yes | Yes | Yes |
| Product | Size | size | lost_sales | STRING | Yes | Yes | Yes |
| Store | Store Number | store_code | lost_sales | STRING | No | Yes | Yes | Store Hierarchy or Attributes |
| Store | Store Name | store_name | lost_sales | STRING | No | Yes | Yes |
| Store | {S1 Name} | s1_name | lost_sales | STRING | No | Yes | Yes |
| Store | {S2 Name} | s2_name | lost_sales | STRING | No | Yes | Yes |
| Store | Store Grade / Tier | store_grade | lost_sales | STRING | No | Yes | Yes |
| Custom | Fiscal Year | fiscal_year | lost_sales | INTEGER | No | No | No |  |
| Custom | Fiscal Week | fiscal_week | lost_sales | INTEGER | No | No | No |  |
| Custom | Fiscal Year Week | fiscal_year_week | lost_sales | INTEGER | No | No | No |  |
| Custom | Opening Inventory | opening_inventory | lost_sales | INTEGER | Yes | No | Yes |  |
| Custom | Units Sold | units | lost_sales | INTEGER | Yes | No | Yes |  |
| Custom | Cluster Avg Sales | cluster_avg_sales | lost_sales | FLOAT | Yes | No | Yes |  |
| Custom | Lost Opportunity (Units) | lost_units | lost_sales | FLOAT | Yes | No | Yes |  |
| Custom | Lost Opportunity (Revenue) $ | lost_sales | lost_sales | FLOAT | Yes | No | Yes |  |
| Custom | Selling Price | selling_price | lost_sales | FLOAT | Yes | No | Yes |  |
| Custom | In Stock with DC-ATA | available_to_allocate | lost_sales | INTEGER | Yes | No | Yes |  |

The report should be downloadable. The download button should present at the top of the table.

### **Acceptance Criteria:**

1. The Lost Sales report should be accessible through the 'Lost Sales' tab in the reports module.
2. The report should provide essential insights into lost opportunity for the product store week combinations.
3. The report should be refreshed weekly.
4. The report should not be editable by the user.
5. The report should populate the appropriate product and store combinations based on the selected filters.
6. The columns in the loaded table should be as per above
7. The dropdown filter should have the latest fiscal week selected by default
8. The graph should show the max 10 weeks of lost sales data

# User Story 4 - Daily Allocation Summary

## **Jira Summary: \[Client Name\] - Development of Reports -> Daily Allocation Summary**

## **Jira Description:**

The Daily Allocation Summary Report Provides a detailed view of the allocation metrics like units allocated, units remaining to allocate, and the reserved units at an allocation plan level. These details can be viewed either at a store level or at a product level. It is updated daily to ensure that users have access to the most updated information. Please note that the Daily Allocation Summary report cannot be edited by users.

The Daily Allocation Summary report can be accessed through the ‘Daily Allocation Summary' tab in the reports module. The expected functionalities in the ‘Daily Allocation Summary’ tab:

1. The report would show the appropriate Style Color, or Store combinations with allocated, available quantity as per the higher-level filters applied.
2. Apply general table functionalities like sorting the table based on a column, Adjusting column width, etc.
3. Users can navigate through the store and product views, along with the summary metrics displayed above the Daily Allocation Summary Report, to review detailed information on daily allocations. 

### Navigation:

Left-hand panel → Reports → Daily Allocation Summary

### Landing Page:

Once the filters are applied, the table should populate with all the KPIs and the product details with allocated and available quantity. By default Product View should be selected. Store view should be available for selection.

### Filters:

By clicking on ‘**Select Filters**’, the user can apply a set of hierarchy filters to get the list of the product or store in the corresponding hierarchy. Refer to the table below for filter details. Both Product and Store level filters can used.

**fc_name : Inventorysmart Daily Allocation Reports**

| **Section** | **Filter Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Mandatory** | **Selection Criteria** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | Date | Select Single Date | global.fiscal_date_mapping | date | No | Yes | Date Picker |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Single select |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Multi select |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Store | {S0 Name} | s0_name | global.store_attributes_filter | varchar | No | No | Multi Select |
| Store | {S1 Name} | s1_name | global.store_attributes_filter | varchar | No | No | Multi Select |

### **Flow:**

The following is the expected flow of the Daily Allocation Summary:

1. By clicking on ‘Select Filters’, The user will apply a set of hierarchy filters to get the list of the products or stores in the corresponding hierarchy which had some allocation on the selected date.
2. Upon selecting the filters, users can see the summary metrics at the top.

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=8771e062c7ad&id=698e36f2-6737-4deb-9442-f6e197b6391d&&collection=contentId-2696611595&height=150&occurrenceKey=null&width=1781&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
3. Below the summary, users can choose between store or product view of the report. By default the product view will be displayed.

**KPIs List:**

| **KPI Name** | **Description** |
| --- | --- |
| # Allocations | Total number of allocation finalized for the selected filters |
| # Style Color Allocation | Total number of style colors allocated for the selected filters |
| # Units Allocated | Total units allocated for all the style colors for the selected filters |
| DC Net Available Inv | Net DC available post the allocation for the selected style color |

**Product View Table Schema:**

**tc_name : inventory_daily_allocation_article_list**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** | **Comments** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Product Code} | article or product_code | inventory_smart.create_allocation_result_flat_gurobi | varchar | No | Yes | Yes |  |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Yes | Product Hierarchy or Attributes |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | global.product_attributes_filter | varchar / date | Yes | Yes | Yes |
| Product | Style Color ID | article | inventory_smart.create_allocation_result_flat_gurobi | varchar | No | Yes | Yes |
| Custom | Total Units Allocated | allocated_total | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | Min Units Allocated | Calculated | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | WOS Units Allocated | Calculated | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | DC Available | pack_dc_allocation | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | Reserve Quantity | reserve_quantity | inventory_smart.dc_pack_reserve_quantity_derived_table | int4 | No | Yes | Yes |  |
| Custom | Store In-Stock | store_in_stock | inventory_smart.article_inventory_dashboard | float4 | Yes | Yes | Yes |  |
| Custom | In-Stock with DC ATA | store_in_stock_ata | inventory_smart.article_inventory_dashboard | float4 | Yes | Yes | Yes |  |
| Custom | Remaining Available to Allocate | remaining_available_to_allocate | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |

**Store View Table Schema:**

**tc_name : inventory_daily_allocation_store_list**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** | **Comments** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Store | Store Number | store_code | inventory_smart.create_allocation_result_flat_gurobi | varchar | No | Yes | Yes | Store Hierarchy or Attributes |
| Store | Store Name | store_name | global.store_attributes_filter | varchar | No | Yes | Yes |
| Store | {S1 Name} | s1_name | global.store_attributes_filter | varchar | No | Yes | Yes |
| Store | {S2 Name} | s2_name | global.store_attributes_filter | varchar | No | Yes | Yes |
| Store | Store Grade / Tier | store_grade | inventory_smart.create_allocation_result_flat_gurobi | varchar | No | Yes | Yes |
| Custom | OH | oh | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | OO | oo | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | IT | it | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | Total Units Allocated | allocated_total | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | Min Units Allocated | Calculated | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | WOS Units Allocated | Calculated | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |
| Custom | Total Inventory | total_inventory | inventory_smart.create_allocation_result_flat_gurobi | int4 | No | Yes | Yes |  |

The report should be downloadable. The download button should present at the top of the table for both the view.

### **Acceptance Criteria:**

1. The Daily Allocation Summary report should be accessible through the 'Daily Allocation Summary' tab in the reports module.
2. The report should provide essential insights into daily allocations at product and store view.
3. The report should be refreshed daily.
4. The report should not be editable by the user.
5. The report should populate the appropriate product and store combinations based on the selected filters.
6. The columns in the loaded table should be as per above
7. The KPI should show the summary at selected filter level

# User Story 5 - Deep Dive

## **Jira Summary: \[Client Name\] - Development of Reports -> Deep Dive Allocation**

## **Jira Description:**

The Deep Dive Allocation Report provides a detailed view of the important allocation metrics like the number of allocations released, the number of units allocated, quantity match %, and size match %  at a store-product level for the selected period. It is updated daily to ensure that users have access to the most updated information. Please note that the Deep Dive Allocation report cannot be edited by users.

The Deep Dive Allocation report can be accessed through the ‘Deep Dive' tab in the reports module. The expected functionalities in the ‘Deep Dive’ tab:

1. The report would show the appropriate product, and Store combinations as per the higher-level filters applied.
2. Apply general table functionalities like sorting the table based on a column, Adjusting column width, etc.   

### Navigation:

Left-hand panel → Reports → Deep Dive

### Landing Page:

Once the filters are applied, the table should populate with all the KPIs and the product and store details with allocated quantity and match percentage with respect to sales and actual allocation.

### Filters:

By clicking on ‘**Select Filters**’, the user can apply a set of hierarchy filters to get the list of the product  store in the corresponding hierarchy. Refer to the table below for filter details. Both Product and Store level filters can used.

**fc_name : inventorysmart_reportings**

| **Section** | **Filter Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Mandatory** | **Selection Criteria** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Custom | Date | From and To Date | global.fiscal_date_mapping | date | No | Yes | Date Picker |
| Product | {L0 Name} | l0_name | global.product_attributes_filter | varchar | No | Yes | Single select |
| Product | {L1 Name} | l1_name | global.product_attributes_filter | varchar | No | Yes | Multi select |
| Product | {L2 Name} | l2_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L3 Name} | l3_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Product | {L4 Name} | l4_name | global.product_attributes_filter | varchar | No | No | Multi select |
| Store | {S0 Name} | s0_name | global.store_attributes_filter | varchar | No | No | Multi Select |
| Store | {S1 Name} | s1_name | global.store_attributes_filter | varchar | No | No | Multi Select |

### **Flow:**

The following is the expected flow of the Daily Allocation Summary:

1. By clicking on ‘Select Filters’, The user will apply a set of hierarchy filters to get the list of the products or stores in the corresponding hierarchy which had some allocation on the selected date.
2. Upon selecting the filters, users can see the summary metrics / KPIs at the top.

    ![](blob:https://media.staging.atl-paas.net/?type=file&localId=1cb92b8da525&id=6848e1c7-1d15-4de7-a1cc-4e9eed75060a&&collection=contentId-2696611595&height=168&occurrenceKey=null&width=1815&__contextId=null&__displayType=null&__external=false&__fileMimeType=null&__fileName=null&__fileSize=null&__mediaTraceId=null&url=null)
3. Below the summary, users can see the details view or product store allocation over the selected period of time.

**KPIs List:**

| **KPI Name** | **Description** |
| --- | --- |
| # Allocations | Total number of allocation finalized for the selected filters |
| # Units Allocated | Total units allocated for all the style colors for the selected filters |
| Qty Match % (Plan vs Actual) | Overall Qty match % for planned allocation vs actual allocation |
| Size Match % (Plan vs Actual) | Overall size level qty match % for planned allocation vs actual allocation |
| Qty Match % (Actual vs Sales) | Overall Qty match % for actual allocation vs sales |
| Size Match % (Actual vs Sales) | Overall size level qty match % for actual allocation vs sales |

**Table Schema:**

**tc_name : inventorysmart_allocation_deep_dive**

| **Section** | **Column Name** | **Mapping Column** | **Mapping Table** | **Data Type** | **Nullable** | **Searchable** | **Sortable** | **Comments** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product | {Article or Product Code} | article or product_code | deep_dive_allocation | STRING | No | Yes | Yes |  |
| Product | {L0 Name} | l0_name | deep_dive_allocation | STRING | No | Yes | Yes | Product Hierarchy or Attributes |
| Product | {L1 Name} | l1_name | deep_dive_allocation | STRING | No | Yes | Yes |
| Product | {L2 Name} | l2_name | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Product | {L3 Name} | l3_name | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Product | {L4 Name} | l4_name | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Product | {Product Attributes} | {product_attribute} | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Product | Style Color ID | article | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Product | Size | size | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Store | Store Number | store_code | deep_dive_allocation | STRING | No | Yes | Yes | Store Hierarchy or Attributes |
| Store | Store Name | store_name | deep_dive_allocation | STRING | No | Yes | Yes |
| Store | {S1 Name} | s1_name | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Store | {S2 Name} | s2_name | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Store | Store Grade / Tier | store_grade | deep_dive_allocation | STRING | Yes | Yes | Yes |
| Custom | Total Allocated | total_allocated | deep_dive_allocation | INTEGER | Yes | No | No |  |
| Custom | Qty Match % (Actual vs Sales) | Calculated | deep_dive_allocation | FLOAT | Yes | No | No | Based on these columns,  
actual_allocation_article_size,  
units_sold_article_size,  
actual_allocation_article |
| Custom | Size Match % (Actual vs Sales) | Calculated | deep_dive_allocation | FLOAT | Yes | No | No | Based on these columns,  
actual_allocation_article_size,  
units_sold_article_size,  
actual_allocation_article |
| Custom | Qty Match % (Plan vs Actual) | Calculated | deep_dive_allocation | FLOAT | Yes | No | No | Based on these columns,  
actual_allocation_article,  
total_allocated |
| Custom | Size Match % (Plan vs Actual) | Calculated | deep_dive_allocation | FLOAT | Yes | No | No | Based on these columns,  
planned_allocation_article_size,  
actual_allocation_article_size |
| Custom | Demand Forecast | demand_forecast | deep_dive_allocation | FLOAT | Yes | No | No |  |
| Custom | MIN | min | deep_dive_allocation | INTEGER | Yes | No | No |  |
| Custom | MAX | max | deep_dive_allocation | INTEGER | Yes | No | No |  |
| Custom | Target WOS | wos | deep_dive_allocation | INTEGER | Yes | No | No |  |
| Custom | WOS (OH+OO+IT)+allocated | wos_oh_oo_it_allocated | deep_dive_allocation | FLOAT | Yes | No | No |  |
| Custom | WOS (OH+OO+IT) | wos_oh_oo_it | deep_dive_allocation | FLOAT | Yes | No | No |  |
| Custom | WOS (OH+IT) | wos_oh_oo | deep_dive_allocation | FLOAT | Yes | No | No |  |
| Custom | WOS (OH) | wos_oh | deep_dive_allocation | FLOAT | Yes | No | No |  |
| Custom | Store In-Stock | in_stock_perc | deep_dive_allocation | FLOAT | Yes | No | No |  |
| Custom | On Hand | oh | deep_dive_allocation | INTEGER | Yes | No | No |  |
| Custom | In Transit | it | deep_dive_allocation | INTEGER | Yes | No | No |  |
| Custom | On Order | oo | deep_dive_allocation | INTEGER | Yes | No | No |  |
| Custom | Total Inventory | total_inv | deep_dive_allocation | INTEGER | Yes | No | No |  |
| Custom | Remaining Available To Allocate | remaining_available_to_allocate | deep_dive_allocation | INTEGER | Yes | No | No |  |

The report should be downloadable. The download button should present at the top of the table.

### **Acceptance Criteria:**

1. The Deep Dive Allocation report should be accessible through the 'Deep Dive Allocation' tab in the reports module.
2. The report should be refreshed daily.
3. The report should not be editable by the user.
4. The report should populate the appropriate product and store combinations based on the selected filters.
5. The columns in the loaded table should be as per above
6. The KPI should show the summary at selected filter level


