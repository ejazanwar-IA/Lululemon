# Product (Rule) Store Mapping Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696610534` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610534/Product+Rule+Store+Mapping+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:12.013Z |
| Last mirrored | 2026-05-21 |

---

## **Purpose**

This document focuses on the flow of Product/Rule Store Mapping. This includes the initial creation of tables/rules, views, updates and back sync of the tables. This document also covers the initial setup of RCL master and priority mapping for different modules.

## **RCL Priority Mapping**

For Product Store Mapping, DC Store Strategy and Constraints, Rule based approach is used. Here a RCL is created at any hierarchy (or product attribute) level. In each RCL there can be multiple Rules, each corresponding to different values for the selected hierarchy or attribute level. More detail on RCL can be found [here](/wiki/spaces/IA/pages/1035796531/RCL+-+Dynamic+Hierarchy). To resolve the RCL, there is a priority set for each product hierarchy or attributes (The priority can be set based on the hierarchy order or based on the discussion with the client).

The RCL Priority Mapping is a one time table created to add the priority for different hierarchies and attributes. For different module, different priority can be there so the priority is created at module level. For example, Constraints is defined at l1_name, l2_name, l3_name and so on but product store mapping is defined at style and style-size level.

The schema for `rcl_priority_mapping` in BigQuery is as below:

**Column Name**| **Type**| **Description**  
---|---|---  
level| STRING| Product Hierarch/Attribute Combinations  
priority_rank| INTEGER| Rank  
rcl_code| INTEGER|   
module_code| INTEGER| Constraint/Store DC policy (code)  
  
The module codes are as follows:

  1. **170** \- Rules Constraints

  2. **10003** \- DC Store Policy

  3. **101** \- Product Mapping

  4. **7001** \- Oms Rules Constraints




The detailed schema and query for generating the `rcl_priority_mapping` is added [here](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/1386283616).

The `rcl_priority_mapping` is then pushed to Postgres table using the SP `public.sync_rcl_priority_mapping()`. The schema for the Postgres tables is as below:

**Column Name**| **Type**| **Description**  
---|---|---  
level| _varchar| ARRAY[]::character varying[]  
priority_rank| int4|   
module_code| int4|   
  
## **Product Store Mapping (Rule Store Mapping)**

This defines the eligibility of product to store for allocation and forecasting. Product store combinations will be eligible for allocation only for the given period of time for which the eligibility is marked as active. This can be a feed from client without any edits on the tool or can be a one time feed and then subsequent changes can be done in the tool. For the initial feed we can get the mapping at any hierarchy level with exception list if client has some. For example - All store except 102 is mapped to Accessories.

### Eligibility Master

Based on the initial shared feed, eligibility master is created. The Schema for eligibility master in BigQuery is as follows:

**Column Name**| **Type**| **Description**  
---|---|---  
lx_name| STRING| The hierarchy at which rule is set. This can be Style or Size  
store_code| STRING|   
size| STRING|   
eligibility_start_date| DATE| Start date of the eligibility  
eligibility_end_date| DATE| End date of the eligibility  
eligibility_flag| INTEGER| If the mapping is active or not  
syncstartdatetime| DATETIME| Required in case the eligibility data is a daily feed  
  
In case of daily feed, eligibility master schema is aligned with client and will be used as a base to populate the `rule_store_mapping`. In case the eligibility is a one time feed. The initial eligibility master is created at either style level or size level based on the feed from client.

### Product Store Attributes Filter Store Code

This is an intermediate table for product hierarchy and store level attribute. This table is used for the creation and update of Rule Store mapping in Big Query and Postgres. The Schema for the table is as follows: 

**Column Name**| **Type**| **Description**  
---|---|---  
lx_name| STRING| Fetched from Product Master. Usually l0_name  
.psa_code| STRING| unique code at lx_name and store_code. Usually concat(lx_name, store_code)  
psa_name| STRING| Store Hierarchy, usually store_code  
store_code| STRING| Fetched from Store Master  
  
This table is moved to Postgres using the SP `public.sync_product_store_attributes_filter_store_code()`. This schema for the table `"global".product_store_attributes_filter_store_code` in Potgres is same as that of BigQuery. The detailed logic is added in this [page](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/1386283505).

### Rule Store Mapping

Using the eligibility master and product_store_attributes_filter_store_code, rule store mapping is created. This essentially takes all the feed from eligibility master which are active and are eligible for dates greater than Today and add any new hierarchy or SKUs (in case of one time feed only) and then adds the rule level and priority. The Schema for Rule Store Mapping in Big Query is as below:

**Column Name**| **Type**| **Description**  
---|---|---  
rcl_code| INTEGER| Rule creation code  
rcl_dimension| STRING| Rule creation Dimension  
psa_code| STRING| Product store attribute code  
lx_name| STRING| Product Hierarchy, usually l0_name  
psa_name| STRING| Store code  
start_date| DATE| Mapping Start Date  
end_date| DATE| Mapping End Date  
mapping_type| STRING| rule-store  
  
More details on schema and generation of Rule Store mapping can be found [here](https://impactanalytics.atlassian.net/wiki/spaces/IA/pages/1386283549). 

Since the rule store mapping can be at some product hierarchy level (usually at style or style-size level), this has to be resolved to get the final eligibility at product store level. The requirement to get the eligibility at product store level is required for the Allocation flow as the allocation can be done at product store level. To get the final eligibility at product store level, all the products belonging to a rule will be assigned the same eligibility start and end date. In case a product belongs to multiple rules, then the priority of rule will be used to decide which eligibility dates should be used. 

For example -

**Rule level ID**| **Selected Level**| **Lowest level**| **Priority**  
---|---|---|---  
RCL 1| Department-category-class| Class| 2  
RCL 2| Department-category-class-subclass| Subclass| 1  
  
In the above example, 2 rules are created. In this case, first the eligibility will be decided based on the RCL 2, as it has the priority 1. If the product does not fits in RCL 2 then RCL 1 will be used to define the eligibility.

The `rule_store_mapping` is pushed to Postgres table where it will be split into 2 separate table using the SP `public.sync_rcl_psm`. The schema for these tables are as below:

`”global”.rcl_product_mapping_product_store_rule`

**Column Name**| **Type**| **Description**  
---|---|---  
rule_code| int4| Rule Code (primary key)  
rcl_code| int4| Rule Creation Level Code  
rcl_dimension| jsonb| Key value pair of product hierarchy  
  
`”global”.rcl_product_mapping_product_store`

**Column Name**| **Type**| **Description**  
---|---|---  
rule_code| int4| Rule Code  
rcl_code| int4| Rule Creation Level Code  
psa_code| varchar| psa code from product_store_attributes_filter_store_code  
psa_name| varchar| psa name from product_store_attributes_filter_store_code  
validity| datemultirange| To and from dates  
  
From the tool when a new rule is created, the rule dimension will be updated in the `”global”.rcl_product_mapping_product_store_rule` table and the validity added will be added in `”global”.rcl_product_mapping_product_store`. These 2 tables are back synced to GBQ to create the updated eligibility master (in case of feed based, back sync is not needed and the eligibility master will be shared by client feed).

In addition to this there is a exception table also which would capture any exception cases where a store (or set of stores) to be exempted from a rule. The exception table is `”global”.rcl_product_mapping_product_store_exceptions`

### Product Store Mapping

Based on the `rule_store_mapping`, `product_store_mapping` table is created in GBQ by resolving the rules. This table is required to filter out the non eligible product store combinations in subsequent tables (like article inventory dashboard).

