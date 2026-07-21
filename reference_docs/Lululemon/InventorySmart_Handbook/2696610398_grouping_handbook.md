# Grouping Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696610398` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610398/Grouping+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:09.069Z |
| Last mirrored | 2026-05-21 |

---

Users can create, import, edit, or delete Store and Product Group(s) in this module. Groups can be used for Allocation, setting Store Eligibility, Reporting, forecasting, etc. 

## _Store Group_

In this section, users can create, edit, or delete store groups. These groups are then associated with style colors for allocation. If a store group is linked to a style color in the DC-store policy, only the stores common to both the default eligibility and the store group will be considered for allocation.

Additionally, store groups serve as filters in various modules, allowing users to view a specific subset of stores using a single filter.

### Creation Workflow

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXeBM88Z0EeW2NsQL1dInH2Dnrt8mFU4ernWg_1T-AWNS2HKaVZHCqkumW_2Am-R0BKiFtgWbi4bkw0r-Fo98wB931poRb6GU4MX3CotzchDVfjUKUVqyLtHIB-8rA-X9JlCk4Dh?key=h1gME0B4n1Bi3hqe6PulW4v2)

### Table Structure

| **DB**| **Table Name**  
---|---|---  
1| BQ| store_group  
2| PG| global.store_groups  
3| PG| global.store_groups_mapping  
  
### Table Schema and Definitions

  * store_group  
 _This is a back-synced table that is created by combining_ `global.store_groups` and `global.store_groups_mapping`. _This table is used in conjunction with the eligibility table to get the eligible SKU-store combinations that would be used to generate DD KPIs and Reports._




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| store_code| STRING|   
2| store_group| STRING| store_group name  
3| ref_sg_code| INETGER|   
4| special_classification| STRING|   
5| application_code| INTEGER|   
6| sg_code| INTEGER| unique store group code  
  
  * global.store_groups




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| sg_code| serial4|   
2| name| varchar|   
3| special_classification| varchar|   
4| is_deleted| bool|   
5| created_at| timestamptz|   
6| updated_at| timestamptz|   
7| created_by| int4|   
8| updated_by| int4|   
9| channel| varchar|   
10| application_code| int4|   
11| extra| jsonb|   
12| is_default| bool|   
  
  * global.store_groups_mapping




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| sg_code| int4|   
2| store_code| varchar|   
3| ref_sg_code| int4|   
  
##  _Product Group_

Users can create Product Groups based on various hierarchies or attribute filters, streamlining workflows and enabling efficient management of product-related configurations. This functionality allows users to set default values for a group of products collectively, enhancing operational convenience.

#### **Use Cases for Product Groups**

  * **Configuring Store Eligibility:** Product Groups can be used to define store eligibility for allocations.

  * **Screen Filters:** Product Groups can be applied as filters across reports, enabling focused analysis of specific product subsets.




#### **Types of Product Groups**

Product Groups in the system are categorized into two types:

  1. **Manual Group Type:**

     * Created by manually selecting specific products to include in the group.

     * Ideal for scenarios where product grouping remains static over time.

  2. **Dynamic Group Type:**

     * Created using Grouping Definitions that automatically update Product Groups based on predefined rules.

     * Once defined, the system runs these rules daily to update the Product Group. This ensures that the grouping reflects the latest product changes without manual intervention.

     * Best suited for situations where groups are expected to be dynamic, with SKUs being added or removed automatically based on criteria.




### Creation Workflow

#### Static Group Creation Workflow

![image-20250121-053859.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610398/image-20250121-053859.png?version=1&modificationDate=1779356649370&cacheVersion=1&api=v2&width=794&height=364)

#### Dynamic Group Creation Workflow

![image-20250121-053953.png](https://impactanalytics.atlassian.net/wiki/download/thumbnails/2696610398/image-20250121-053953.png?version=1&modificationDate=1779356649369&cacheVersion=1&api=v2&width=722&height=537)

### Table Structure

| **DB**| **Table Name**  
---|---|---  
1| PG| global.product_groups  
2| PG| global.product_groups_mapping  
  
### Table Schema and Definitions

  * global.product_groups




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pg_code| serial4|   
2| name| varchar|   
3| special_classification| varchar|   
4| is_deleted| bool|   
5| created_at| timestamptz|   
6| updated_at| timestamptz|   
7| created_by| int4|   
8| updated_by| int4|   
9| selection_metadata| json|   
10| extra| jsonb|   
  
  * global.product_groups_mapping




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pg_code| int4|   
2| product_code| varchar|   
3| ref_pg_code| int4|   
4| avg_st_perc| float4|   
5| rev_con_perc| float4|   
  
  * global.product_group_definitions  
This table records the rule definition used to create the product group




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pgd_code| serial4|   
2| name| varchar|   
3| pseudo_code| text|   
4| is_deleted| bool|   
5| created_at| timestamptz|   
6| updated_at| timestamptz|   
7| created_by| int4|   
8| updated_by| int4|   
  
  * global.product_group_definitions_rules_mapping  
This table records the relationship between the product group definition and the product group rules.




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pg_code| int4|   
2| pgd_code| int4|   
3| pgr_code| int4|   
  
  * global.product_group_rules  
This table records the attribute and the value used to create the sub rule. If a product group definition has multiple subrules, each `pgr_code` will have multiple rows in this table.




| **Column Name**| **Column Type**| **Definition**  
---|---|---|---  
1| pgr_code| serial4|   
2| name| varchar|   
3| attribute_name| varchar|   
4| attribute_values| _varchar|   
5| is_deleted| bool|   
6| created_at| timestamptz|   
7| updated_at| timestamptz|   
8| created_by| int4|   
9| updated_by| int4|   
  
##  _Frequently Asked Questions_

  * What happens when a user modifies a dynamic product group?

    * When a user modifies a dynamic product group, it no longer follows the user-defined rule definition. As a result, the system treats it as a static product group, requiring manual maintenance. It will no longer be dynamically updated based on predefined rules.

  * What is the limit of style-color/SKUs possible in a product group?

    * The user should limit the product groups to a maximum of 2,000 entities (SKU/Style-Color) to ensure the filters function correctly.




