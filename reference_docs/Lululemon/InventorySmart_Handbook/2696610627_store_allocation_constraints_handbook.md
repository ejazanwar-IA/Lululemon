# Store Allocation Constraints Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696610627` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610627/Store+Allocation+Constraints+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:13.789Z |
| Last mirrored | 2026-05-21 |

---

## **Purpose**

This document focuses on the flow of Store Allocations Constraints and User Reserve. This includes the initial creation of tables/rules, views, updates. This document also covers the initial setup of the Constraints.

## **Constraints - Store Allocations**

This defines the store constraints on Min, Max and WOS which will be used in the Allocation creation (Manual and Auto allocation). In the CNA flow, Min, Max and WOS along with forecast and store inventory are used to calculate the demand for the stores. For initial setup of constraints master and to update it in the tool, [RCL Priority Mapping](https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610534/Product+Rule+Store+Mapping+Handbook#RCL-Priority-Mapping) is required.

### Hierarchy Constraints

To setup the initial constraints on the tool, client can share the one time feed. Clients can choose to provide this constraints information (Min, Max and WOS) at any product hierarchy or product attribute, store grade level. In addition to this client can also share the default value for min, max and WOS which would be used as a default rule. The default rule is for the case when a product does not belong to any hierarchy shared. The client can share the info in following format: 

**Column Name**| **Type**| **Description**  
---|---|---  
l0_name| STRING| Can be at any other hierarchy also  
lx_name| STRING| The table can be shared at more hierarchy level, l0, l1, l2, etc  
attribute_1| STRING| Optional, valid only if client is sharing the constraints at attribute. Multiple attribute column can be there.  
Store Grade| STRING| Optional, In case store grade/tier is available and client maintain the constraints at grade level.  
Min| INT|   
Max| INT|   
WOS| INT|   
From Date| DATE| Optional. If not provided will set a date in past  
To Date| DATE| Optional. If not provided will set a date in future (2050)  
  
Simplified schema can be as below:

**Column Name**| **Type**| **Description**  
---|---|---  
rule_name| STRING| Unique value  
rule_dimension| JSON| Key value pair for product hierarchy or attribute  
Store Grade| STRING| Optional, In case store grade/tier is available and client maintain the constraints at grade level.  
Min| INT|   
Max| INT|   
WOS| INT|   
From Date| DATE| Optional. If not provided will set a date in past  
To Date| DATE| Optional. If not provided will set a date in future (2050)  
  
Based on the above shared information, a static table is created in BigQuery - `hierarchy_constraints_v2`. This table would have the min, max and wos values at all the eligible product hierarchy, attributes and store grade level. The details for generating the static table is explained in [Hierarchy Constraints](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/1386283586).

### Product Store Attributes Filter

This is an intermediate table for product hierarchy and store level attribute. This table is used for the creation and update of constraints rcl in Big Query and Postgres. The Schema for the table is as follows: 

**Column Name**| **Type**| **Description**  
---|---|---  
lx_name| STRING| Fetched from Product Master. Usually l0_name  
Sx_id| STRING| Store Hierarchy (Mainly Store Grade, if store grade is not provided we create store grade based on the sales data)  
.psa_code| STRING| unique code at lx_name and store_code. Usually concat(lx_name, store_code)  
psa_name| STRING| Store Hierarchy, usually store_code  
store_code| STRING| Fetched from Store Master  
  
This table is moved to Postgres using the SP `public.sync_product_store_attributes_filter()`. This schema for the table `"global".product_store_attributes_filter` in Potgres is same as that of BigQuery. The detailed logic is added in this [Product store attributes filter](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/1386283527).

### Constraint Priority Order

To resolve the constraints rule where a product can belong to more than one rule, a priority order is required for all the product hierarchy or attributes (which will be used to create the constraints rule). The hierarchy/attributes will be given priority rank from 1 to n. 1 is the highest priority. The schema for the priority is as follows:

**Column Name**| **Type**| **Description**  
---|---|---  
hierarchy/attribute| STRING| Product Hierarchy  
Priority| INTEGER| Rank  
  
### Constraint Master

Based on the client shared feed, the static table, rule store mapping and the product store attributes filter, constraints master table is created. This is a one time table required for initial setup. Post the initial setup, the tool can be used for edits and addition of any new rules. The initial table is created in BigQuery and then pushed to Postgres where the tables, `global.rcl_master`, `inventory_smart.rcl_constraint_master_rule` and `inventory_smart.rcl_constraint_master`are updated. The details of query and SP are explained in [Constraint Master](/wiki/spaces/IA/pages/1386283638/_Adv_28_ootb+adv+Constraint+Master). The Schema for all these tables are as follows:

**Constraints Master - BigQuery**

**Column Name**| **Type**| **Description**  
---|---|---  
rcl_code| INT| From rcl_priority_mapping  
rule_name| STRING| For Default rule it should be `Default Rule`  
rcl_dimension| STRING| Key value pair for product hierarchy or attribute  
module_code| INT| static value, 170 for constraints  
psa_name| STRING| Fetched from `product_store_attributes_filter`  
psa_code| STRING| Fetched from `product_store_attributes_filter`  
min| INT|   
max| INT|   
wos| INT|   
start_date| DATE| Optional. If not provided will set a date in past  
end_date| DATE| Optional. If not provided will set a date in future (2050)  
is_default| Bool| If this is set to true, the rule will not be edited or deleted from the toll  
  
**RCL Constraint Master Rule - Postgres**

**Column Name**| **Type**| **Description**  
---|---|---  
rule_code| int4| Rule Code (primary key)  
rcl_code| int4| Rule Creation Level Code  
rcl_dimension| jsonb| Key value pair of product hierarchy  
rule_name| varchar|   
  
**RCL Constraint Master - Postgres**

**Column Name**| **Type**| **Description**  
---|---|---  
rcl_constraint_code| int4| Primary Key  
rcl_code| int4| From rcl_priority_mapping  
rule_code| int4|   
psa_name| varchar| Fetched from `product_store_attributes_filter`  
psa_code| varchar| Fetched from `product_store_attributes_filter`  
validity| daterange| Start and End date for the constraints eligibility  
min_stock| float4|   
max_stock| float4|   
wos| float4|   
transit_time| float4|   
safety_stock| float4|   
aps| float4|   
ros| float4|   
st| float4|   
created_by| int4|   
created_at| timestamptz|   
updated_by| int4|   
updated_at| timestamptz|   
is_deleted| bool|   
  
There should be at least one default rule for constraints which will be used if a product does not belong to any of the created rules. Usually, default rule is set at channel/brand/sales org level. During the initial setup, default rules should be created and pushed to the Postgres table. The Default rules are created in the BigQuery at l0_name or l0_name, l1_name and/or store hierarchy level. This rule is then pushed to Postgres table and the SP `public.sync_rcl_constraint()`updates the table `inventory_smart.rcl_constraint_master` and `inventory_smart.rcl_constraint_master_rule`.

### Manage RCL

User can create RCL and Rules to attach different constraint values to different hierarchy. This way user can control what constraint values should be used of each hierarchy and for what period of time. A RCL can be created at different product hierarchy or product attributes level. User first needs to select the hierarchy level (product hierarchy or attributes) at which the rules should be created. In the 2nd step, user can select the values for each of those hierarchy. In the 3rd step based on the hierarchy selected, rules will be created. Users can add the required values for min, max, wos and the validity start and end dates for each rule. Multiple constraint values for min, max and wos can be added based on the validity start and end dates. The created rules will be saved in `inventory_smart.rcl_constraint_master_rule` and the constraints value attached to each rule will be stored in `inventory_smart.rcl_constraint_master`. 

In case there are multiple rules created for the same product, the rule resolution will be done based on the priority defined. The resolution logic is similar to the logic added in [RCL-Dynamic Hierarchy](/wiki/spaces/IA/pages/1035796531/RCL+-+Dynamic+Hierarchy) or [Product Rule Store Mapping Handbook](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610534/Product+Rule+Store+Mapping+Handbook).

### Manage Exceptions

The Manage Exceptions flow from the toll can be to set exceptions at store level in a rule. There can be cases where for certain set of stores there is need to maintain a different constraint values than for the rest of the product and store in that rule. To add an exception, select the required product hierarchy and apply filter in the 1st step of Add Exceptions. Select the rule and click on next for which exception is to be added. In the 2nd step, select the store hierarchy and apply filters. From the list populated, select the stores to add the exceptions. In the 3rd and final step, add the constraint values for min, max and wos for the selected rule store combinations. The added exceptions will be stored in the postgres table `inventory_smart.rcl_constraint_master_exceptions`. The schema for this is as below:

**Column Name**| **Type**| **Description**  
---|---|---  
rcl_code| int4| From rcl_priority_mapping  
rule_code| int4|   
psa_name| varchar| Fetched from `product_store_attributes_filter`  
psa_code| varchar| Fetched from `product_store_attributes_filter`  
validity| daterange| Start and End date for the constraints eligibility  
store_code| varchara|   
min_stock| float4|   
max_stock| float4|   
wos| float4|   
transit_time| float4|   
safety_stock| float4|   
aps| float4|   
ros| float4|   
st| float4|   
created_by| int4|   
created_at| timestamptz|   
updated_by| int4|   
updated_at| timestamptz|   
  
The added exception can be edited from the landing page of Manage Exceptions also.

## **Constraints - User Reserve**

In this module, user can reserve DC inventory at pack or each level. In the current version of OOTB, the reservation can be done at either pack or each level. Reservation at both level is not supported. User can specify a date also till when the units should be reserved. Client can share the reserved units as a feed or they can use the tool to reserve the quantity. To populate the DC-SKU(Pack) in the tool, a derived table is created in the BigQuery and then pushed to Postgres. If the reservation feed is coming from client then it is added and adjusted in the Bigquery table. The schema of the BigQuery table `dc_reserve_qty` is as follows: 

field name| type| description  
---|---|---  
product_code| STRING|   
dc_code| STRING|   
product hierarchy| STRING| Columns for product hierarchy  
channel| STRING|   
incoming_po_30| INTEGER|   
incoming_po_31_60| INTEGER|   
incoming_po_61_90| INTEGER|   
DC OH| INTEGER|   
DC OO| INTEGER|   
DC IT| INTEGER|   
new_store_reserve| INTEGER| Optional, In case reservation is from feed, this can be added  
user_reserve| INTEGER| Optional, In case reservation is from feed, this can be added  
reservation_till_date| DATE| Optional, In case reservation is from feed, this can be added  
  
Tot create the table, all the active mapping from `product_dc_mapping` taken and are filtered based on the available inventory and po inventory. The detailed logic for creation of the table is explained in [DC Reserve Qty](/wiki/spaces/IA/pages/1386284390/_Adv_61_dc_reserve_qty). 

The BigQuery table is pushed to Postgres and using the SP `public.sync_dc_reserve_qty()`, tables `inventory_smart.dc_reserve_quantity_archive` and `inventory_smart.dc_reserve_quantity` are populated. The `inventory_smart.dc_reserve_quantity_archive` table use to store the older reservation data where the reservation dates is less than the current date.

Any reservation done from the tool is updated in the `inventory_smart.dc_reserve_quantity`. Once the reservation is done, the reserved quantity can not be used for allocation, till the specified reservation date.

