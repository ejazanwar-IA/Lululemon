# DC-Store Policy Handbook

| Field | Value |
|---|---|
| Confluence page ID | `2696610609` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610609/DC-Store+Policy+Handbook |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:13.446Z |
| Last mirrored | 2026-05-21 |

---

## **Purpose**

This document focuses on the flow of DC Store Policy. This includes the initial creation and update of DC Store Strategy Rules, Auto Allocation Rules, Auto Allocation Scheduler and DC store Strategy. This screen is Rule based where a RCL and rule will be created and mapping would be done at rule level. Right now, this section consists of following four sub modules:

  1. **DC Store Strategy Rules** \- Multiple Strategy rules can be created for DC to Store Allocation

  2. **Auto Allocation Rules** \- Multiple allocation rules can be created for Auto Allocation

  3. **Auto Allocation Scheduler** \- Multiple Schedules can be created to control the time and frequency of Auto allocation generation 

  4. **DC Store Strategy** \- The above three rules and schedule along with product profile and store groups can be mapped to a RCL or Rule in this screen.




## **DC Store Strategy Rules**

In this sub module, user can create a strategy for DC to Store allocation. The strategy then can be attached to a Rule or RCL which will be used during the manual allocation in CNA flow or during a auto allocation generation. To create a DC Store Strategy Rules, a maximum of 3 rules (as per current architecture) can be used. Following 3 rules are supported as of now:

  1. **DC to Store Strategy** \- Here the user has the option to select what strategy to use for DC to store allocation.

     1. **Min First and then WOS** \- The optimizer will allocate Mins first across all stores. The remaining inventory will be considered to allocate the demand portion. This is **default rule**. If no strategy is selected then this strategy will be used.

     2. **Mins Only** \- The optimizer only allocates Mins, demand is not considered.

     3. **WOS Only** \- The entire inventory is considered to fulfill the demand, ignoring mins but respecting the max.

  2. **Prioritization Strategy** \- This dictates the store prioritization logic to be used in case in constrained inventory.

     1. **IA Priority** \- In this case, a store prioritization is decided based on the need of the store, propensity of store to sell (ROS or APS). The store having higher need and ROS (or APS) will be allocated first. There can be possibility that some of the stores will not get any units. This is the **default Priority**.

     2. **Fair Share** \- In this case, the optimizer will try to allocate to all the stores in the proportion of their need. There is no priority between the stores. There would be a chance for each store to get some units.

  3. **Demand Type** \- Here user can select which Demand Type to use for allocation. following are the options

     1. **IA Forecast** \- In this case IA forecast will be used to calculate the demand and do the allocation.

     2. **Fixed Inventory Push** \- In this case a fixed portion of the DC inventory will be allocated. In this case user is asked to specify the fixed inventory percentage during the rule creation. By default 10% of DC inventory will be used for allocation.

     3. **APS** \- Stands for ‘average per store’. When APS is selected as the Demand Type, user is asked to enter the planned APS number. The demand for each store will be calculated using the Planned APS value and the overall proportion flowing from the product profile. _**(Not included in OOTB)**_

  4. **DC Inventory Source** \- This rule gives an option to select the source of inventory for allocation. The available choices are

     1. **DC on hand** \- This is the default case. In this case, DC On Hand inventory will be used for allocation

     2. **DC in transit** \- In this case, DC In Transit inventory will be used for allocation




The user can add one or more than one rules to create the final rule definition which then can be used to map to any RCL in DC Store Strategy.

The default Rules and dropdown values/options for each of these can be found in the Postgres table: `inventory_smart.dc_store_policy_rule`. Apply a filter of `rule_type='dc-store-rule'` to fetch the rules for DC store. The schema for the table is as follows:

**Column Name**| **Type**| **Description**  
---|---|---  
rule_name| varchar(255)| Name  
rule_structure| json| Structure of Rule like label name, what value it can take  
default_value| json| Default Value for the rule  
rule_type| varchar(255)| Type of rule - auto-allocation or dc-store-rule  
is_mandatory| bool|   
rule_key| varchar| Unique identifier of the Rule  
  
The user created rules from the tool will be saved in this Postgres table: `inventory_smart.dc_store_policy_user_rule`. Apply a filter of `rule_type='dc-store-rule'` to fetch the rules for DC store.

**Column Name**| **Type**| **Description**  
---|---|---  
rule_code| serial4| Primary Key  
rule_name| varchar| Name  
values| json| Structure of Rule like label name, what value it can take  
rule_type| varchar(255)| Type of rule - auto-allocation or dc-store-rule  
is_deleted| bool|   
created_by| int4|   
created_at| timestamptz|   
updated_by| int4|   
updated_at| timestamptz|   
is_deletable| bool| Default rule will not be deletable  
  
## **Auto Allocation Rules**

In this sub module, user can create a strategy for Auto Allocation. The strategy then can be attached to a Rule or RCL which will be used during the auto allocation generation along with the DC Store Strategy Rules. To create a Auto Allocation rule definitions, following rules can be used:

  1. **Set Minimum DC Inventory** \- Users can set a minimum inventory level for DCs which should be available for auto allocation to start.

  2. **Set CutOff WOS** \- Users can define an upper cutoff Weeks of Supply (e.g. cutoff WOS = 7, which implies whenever WOS is below cutoff WOS (7), this rule will be in consideration). User can enter an integer value only.

  3. **Set WOS Threshold** \- Here the users can establish a WOS threshold using the Target WOS. The rule can be defined as follows: (Current WOS, Conditions: ('>=”, ‘<'), Threshold(0 to 1): Target WOS). Here the user needs to choose the operator (’>', ‘=' or '<’) and enter enter a value of 0 to 1 in the text field.

  4. **Triggered if MinStock not satisfied** \- This is a toggle button to set it as **Yes** or **No**. If the value is Yes, then the Auto allocation will gets triggered when the min stock condition is not satisfied even for one single product-store combinations

  5. **Set Auto Release** \- This rule states if the Auto Allocation should be auto finalized or not. If this is set to Yes, the auto allocation will be auto finalized and sent to the downstream. If No, then the auto allocation will be only created and not finalized. If this rule is added for a client then it should be a mandatory one.

  6. **Set Auto Approve** \- Similar to **Set Auto Release** , this is a toggle button with values as **Yes** and **No**. This rule is only applicable of the tool has **Order Batching** module. If this rule is set to Yes, then the auto allocation will be moved Order Batching automatically post creation. If No, then the auto allocation will be created and available in the Auto Allocation Alert.




**NOTE:** _The rules**Set Auto Approve** and **Set Auto Release** can not be used together in one single rule._

The user can add one or more than one rules to create the final rule definition which then can be used to map to any RCL in DC Store Strategy.

The default Rules and dropdown values/options for each of these can be found in the Postgres table: `inventory_smart.dc_store_policy_rule`. Apply a filter of `rule_type='auto-allocation'` to fetch the rules for Auto Allocation.

The user created rules from the tool will be saved in this Postgres table: `inventory_smart.dc_store_policy_user_rule`. Apply a filter of `rule_type='auto-allocation'` to fetch the rules for Auto Allocation.

## **Auto Allocation Scheduler**

In this submodule, user can create a scheduler for the auto allocation. The scheduler then can be mapped to any rules or RCL in DC Store Strategy screen. To create the scheduler, user needs to select the Frequency for the auto allocation. Following options are available:

  1. **Daily** \- In case of Daily, the auto allocation will run on week days only

  2. **Weekly** \- In this case user can select the days of the week when the auto allocation should run

  3. **Monthly** \- Here, user has the option to choose date of the month or Day and week of the month to create the scheduler

  4. **Quarterly** \- Similar to Monthly, user has the option to choose month and date of the quarter or month, Day and week of the quarter to create the scheduler

  5. **Yearly** \- User can select the month, date or month, week and week days to create the scheduler




The user can create multiple schedulers and that can be used to map to any RCL in DC Store Strategy.

The created schedule is stored in the `inventory_smart.auto_allocation_scheduler`

**Column Name**| **Type**| **Description**  
---|---|---  
sh_code| serial4| Primary Key  
sh_name| varchar| Name  
sh_structure| json| Structure of the Scheduler. Stored in json format based on the input from frontend  
sh_frequency| varchar| Weekly, Monthly, etc  
is_deleted| bool|   
created_by| int4|   
created_at| timestamptz|   
updated_by| int4|   
updated_at| timestamptz|   
is_deletable| bool| Default rule will not be deletable  
  
## **DC Store Strategy**

This is the main module where different strategy, store groups and product profile can be mapped. The mapped strategy, store groups and product profile will be used for allocation in the CNA flow and in the auto allocation generation. At each rule level, user can add or update the below metrics:

  1. **Store/Store Groups Mapped** \- user can add or remove one or more than one store groups for each of the rules. Once updated the column will show the Number of mapped stores and number of store groups mapped. By default the Default store group for that channel or organization will be added.

  2. **Product Profile** \- User can attach a user created profile profile for the rule for certain period of time. If nothing is used then default product profile will be used.

  3. **DC to Store Strategy Rules** \- DC to Store Strategy created in above steps can be attached here to a rule. If nothing is attached then the default rule will be used.

  4. **Auto Allocation Rules** \- Auto Allocation Rules created in above steps can be attached here to a rule. If nothing is attached then the default rule will be used or No Rule.

  5. **Auto Allocation Scheduler** \- Auto Allocation Scheduler created in above steps can be attached here to a rule.

  6. **From Date** \- The validity start date for the using the mapped store group, product profile, DC to Store Strategy rules and auto allocations rules.

  7. **To Date** \- The validity end date for the using the mapped store group, product profile, DC to Store Strategy rules and auto allocations rules.




Multiple rows can be added for a rule based on the validity start and end dates. There cannot be any overlapping dates for the rule. The date ranges should be added in such a way that the end date for the final or last validity should be 31 Dec 2050 (a date in future, set as 31 Dec 2050).

  * Maximum Date - 31 Dec 2050

  * Minimum Date - Current date or a date in past when the rule was set.




There is no restrictions on the number of date ranges that can be added for one Rule. With more number of records for each rule, there would be some impact on the performance.

The mapping of store groups, product profile and strategies are captured in the `inventory_smart.rcl_dc_store_policy` table. The schema for that is as follows:

**Column Name**| **Type**| **Description**  
---|---|---  
rcl_dc_store_policy_code| serial4| Primary Key  
rcl_code| int4|   
rule_code| int4|   
default_store_groups| _int4| Array of Store Group codes  
default_product_profile| int4| Attached product profile code. Null in case nothing is attached  
dc_store_rule| int4| rule code from `inventory_smart.dc_store_policy_user_rule`  
auto_allocation_rule| int4| rule code from `inventory_smart.dc_store_policy_user_rule`  
auto_allocation_schedular| int4| rule code from `inventory_smart.auto_allocation_scheduler`  
validity| daterange|   
created_by| int4|   
created_at| timestamptz|   
updated_by| int4|   
updated_at| timestamptz|   
is_deleted| bool|   
  
### Manage RCL

User can create RCL and Rules to attach different strategies to different hierarchy. This way user can control what strategy should be used of each hierarchy and for what period of time. A hierarchy can be created at different product hierarchy or product attributes level. User first needs to select the hierarchy level (product hierarchy or attributes) at which the rules should be created. In the 2nd step, user can select the values for each of those hierarchy. In the 3rd step based on the hierarchy selected, rules will be created. Users can attach the above explained metrics for each rule. The created rules will be saved in `inventory_smart.rcl_dc_store_policy_rule` and strategies attached to each rule will be stored in `inventory_smart.rcl_dc_store_policy`. The schema for `inventory_smart.rcl_dc_store_policy_rule` is as below:

**Column Name**| **Type**| **Description**  
---|---|---  
rule_code| serial4| Primary Key  
rcl_code| int4| Foreign Key from RCL Master  
rcl_dimension| jsonb| Key value pair for the hierarchy selected  
rule_name| varchar| Name  
  
During the initial setup, default rules should be created and pushed to the Postgres table. The Default rules are created in the BigQuery at l0_name or l0_name, l1_name. This rule is then pushed to Postgres table and the SP `public.sync_rcl_dc_store()`updates the table `inventory_smart.rcl_dc_store_policy_rule` and `inventory_smart.rcl_dc_store_policy`. The detailed query and SP for default DC Store Policy can be found [Default DC to store policy](/wiki/spaces/IA/pages/1445134392/Default+DC+to+store+policy).

In case there are multiple rules created for the same product, the rule resolution will be done based on the priority defined. The resolution logic is similar to the logic added in [RCL-Dynamic Hierarchy](/wiki/spaces/IA/pages/1035796531/RCL+-+Dynamic+Hierarchy) or [Product Rule Store Mapping Handbook](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610534/Product+Rule+Store+Mapping+Handbook).

