# ADA Visual - User Story

| Field | Value |
|---|---|
| Confluence page ID | `2696610753` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610753/ADA+Visual+-+User+Story |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:15.564Z |
| Last mirrored | 2026-05-21 |

---

**Update Date**| **Updated By**| **Description**  
---|---|---  
20 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added Nullable column for validation

  
05 Mar 2026| [Navin Chandan](https://impactanalytics.atlassian.net/wiki/people/640ed35f57f0c028e2f3e2fe?ref=confluence)| 

  1. Added mapping table in filters
  2. Title case naming as per latest guideline
  3. MFP filters and side by side table graph

  
  
# Guideline

  * The text in blue color are configurable or optional. Based on the client requirement, make the required adjustment to the story

  * Prepare a Product Store eligibility count sheet at different hierarchy level. This will help developer to optimize the global filtering

  * Please stick to sentence case for column header or filter naming except for the abbreviation. Example - **Style-Color ID, Net DC Available, Last Week Sales**




# User Story

## **Demo link: { Add React Demo - If available}**

## **Details:**

As a user, I want to have following requirements and functionality in the ADA Visual Module:

  1. **Demand Selection {Optional - Required only if client is sharing their forecast, MFP or Plan data}** \- 

     1. 2 tabs should load below the filters.

        1. **Demand Selection** \- Default selection. User can change which demand (Client forecast or Adjusted User forecast) to be used for allocation.

        2. **Manage Forecast** \- User can edit and save the forecast based on Discount value and/or multiplier.

     2. **Forecast Overview** \- This section should view all the key metrics and multipliers that I have adjusted or edited in the "Manage Forecast" tab along with the client / MFP forecast and final selected forecast, so that I can easily track and review the changes I made. This should contain 2 sub sections: Forecast Visualization and Forecast Summary Table showing side by side (default behavior). There should be option to view individual section. 

        1. **Forecast Summary Table:**

           * Displays the following columns: Original IA Forecast, Adjusted IA Forecast, Multiplier, Adjusted User Forecast, MFP, Final Forecast, Actuals, and Last Year or Last to Last Year Actuals (as per filter selection of Compare With), for up to 8 weeks of future data.

           * This table should be a view-only screen, where no edits can be made, and any changes in the "**Manage Forecast** " section should reflect here quickly.

        2. **Forecast Visualization:**

           * Displays all the above metrics (as displayed in the Forecast Summary Table) in graphical form.

     3. **Demand Selection - Details Table:**

        * As a user, I want to select between MFP and Adjusted User Forecast at the {Style Color ID} level for the selected Store and Product filters, so that I can tailor the forecast to my preferences.

        * I also want the ability to approve the final forecast by clicking "Approve Final Forecast."

Additionally, I want the option to apply MFP or Adjusted User Forecast to all filtered {Style Color ID} at once using "Set All MFP" or "Set All Adjusted User Forecast"

  2. **Adjusted Forecast** \- {As a user, I should be able to click on the "**Manage** **Forecast** " tab, which redirects me to the Adjusted Forecast page while retaining the filter selections from the landing page.} - (Applicable for clients where MFP is shared)  
{On applying the filter, Three tabs to be visible: IA Forecast, Adjusted Forecast, and Comparison. Adjusted Forecast should be loaded by default} - (Applicable for clients where client forecast or MFP is not shared)

     1. **Drivers of Forecast:** Needs to show discount value % (editable) and effective discount % along with Actuals Discount % and Last year Discount %.

     2. **Forecast Adjustment:**

        1. **Forecast Summary** \- Overview should show Original IA Forecast, Adjusted IA Forecast, Multiplier (editable), Adjusted User Forecast (editable), {MFP}, Actuals, and Last Year or Last to Last Year Actuals (as per filter selection of Compare With), for up to 8 weeks of future data.

        2. **Forecast Visualization** \- The deep-dive graph should visualize key metrics such as Original IA Forecast, Adjusted IA Forecast, Adjusted User Forecast, {MFP}, Actuals, and Last Year Actuals.  
Discount %, Actual discount % and comparison discount % in secondary y axis

     3. **View/edit Hierarchy Forecast:** In this section, user can see the forecast at more granular level (l3_name or l4_name level). The user can drill down to a max of 3 levels to see forecasts at lower level

        * Deep dive levels - {Class -> Style-Color ID -> Store} (The hierarchy level changes from client to client)

        * Users can lock / unlock for editing in View/Edit Hierarchy Forecasts screen.

  3. **IA Forecast** \- The IA Forecast module should have the same features as the Adjusted Forecast tab, but edit functionality should not be available.

  4. **Scenario** \- Same features as Adjusted Forecast tab. Add and Delete Scenario functionality should be there. Scenario data should update dynamically when the multiplier or manually entered values change.

  5. **Comparison** \- 

     1. **Scenario Comparison Forecast:** Need to show Original IA Forecast, Adjusted IA Forecast, Adjusted User Forecast, Scenario IA Forecast, Scenario User Forecast, Actuals, and Last Year or Last to Last Year Actuals (as per filter selection of Compare With).

     2. **Scenario Comparison** : Need to show Original IA Forecast, Adjusted IA Forecast, Adjusted User Forecast, scenario IA forecast, Scenario User forecast in tabular form.

  6. **Historic Week View** \- 

     1. **Historic forecast points:** Provide the last 8 weeks of forecast data for selected Product and Store filters.

     2. **LY comparison:** The LY forecast metrics corresponding to the selected Product & Store filters are shown.

  7. **Variable Contribution or Driver Significance (Glass box Visibility)** \- As a user, I want to review the various drivers which are significantly influencing my forecast beyond just discount percentage/ promotions. This will allow me to gain deeper insights into the essential factors contributing to my forecast and understand their respective weightage. By having a clear view of these drivers, I can make more informed business decisions and improve my forecasting accuracy.

     1. The system should display all relevant influencing drivers in a read-only format, ensuring that users can review them but not modify them. Also, these drivers about to load only on demand and not to be present in landing page. It has two parts

        1. **Drivers rank and average weightage** -based on filter selected, this should show a list of drivers in a descending order along with their average weightage among all selected product-store combination from filter. 

        2. **Week wise view of drivers** \- Need to show the same information of drivers weightage for upcoming each week.

     2. Graphical representation should be available for each of the above 2 parts:

        1. **Drivers rank and average weightage** \- Contribution should be shown on a Pie Chart 

        2. **Week wise view of drivers** \- Contribution for each week should be shown in a stacked bar chart.  
The drivers should be presented in a structured manner, allowing users to analyze their impact on forecasted values effectively.




## **Flow Details:**

### _Navigation:_

Left-hand panel -> ADA Visual

The user will be landed on the {MFP Dashboard or Adjusted Forecast} screen. User can click on **Add Filter** to apply the filters and load the data.

### _Filters:_

The product and store filters are dependent on the clients requirement. The Mandatory and Selection Criteria needs to be checked and evaluated based on the product store eligibility count. As a general guideline l0_name, l1_name and s0_name needs to be mandatory.

**Section**| **Filter Name**| **Mapping Column**| **Mapping Table**| **Data Type**| **Nullable**| **Mandatory**| **Selection Criteria**  
---|---|---|---|---|---|---|---  
Date Range and Aggregation Level| Date Range| | | date| No| Yes| From and to dates  
Date Range and Aggregation Level| Aggregation Level| | | varchar| No| Yes| Single Select  
Product| {L0 Name}| l0_name| global.product_attributes_filter| varchar| No| Yes| Single Select  
Product| {L1 Name}| l1_name| global.product_attributes_filter| varchar| No| Yes| Single Select  
Product| {L2 Name}| l2_name| global.product_attributes_filter| varchar| No| Yes / No| Multi Select  
Product| {L3 Name}| l3_name| global.product_attributes_filter| varchar| No| No| Multi Select  
Product| {L4 Name}| l4_name| global.product_attributes_filter| varchar| No| No| Multi Select  
Store| {S0 Name}| s0_name| global.store_attributes_filter| varchar| No| Yes| Single Select  
Store| {S1 Name}| s1_name| global.store_attributes_filter| varchar| No| No| Multi Select  
Store| {S2 Name}| s2_name| global.store_attributes_filter| varchar| No| No| Multi Select  
Compare With| Historic Actuals| | | | | Yes| Default Last Year  
  
### ** _Other Details:_**

  * **Forecast Horizon:** Future forecast for 26**** weeks to be provided in the ADA forecast table. However, the ADA Visual module in tool will have only future 8 weeks of data

  * **Discount percentage** \- 20 discount percentages from 0 to 100 at an interval of 5

  * **Forecast Week** \- 26 Weeks forward

  * **Product Store Count** \- Share a sheet with the eligible product store count at different hierarchy levels (l0_name->s1_name, l0_name->l1_name->s1_name). [Sample File](https://docs.google.com/spreadsheets/d/1NUoBVCwnH-bOMt1zKH4FYPBODtktr6yzIxi6Tup-dbE/edit?gid=639271364#gid=639271364)




### ** _Acceptance Criteria:_**

  1. The {**ADA Dashboard** or **Adjusted Forecast**} screen should be the default landing page.

  2. The Forecast Overview should showcase the following metrics:

     * Original IA Forecast, Adjusted IA Forecast, Multiplier , Adjusted User Forecast , MFP, Actuals, and Last Year Actuals or Last to Last year actuals (as per filter selection of Compare With).

  3. Forecast Overview should be a view only screen.

  4. The Multiplier field should be non editable, and any changes made in "Forecast Management" should update the Adjusted User Forecast in real-time.

  5. The graph should visually represent Original IA Forecast, Adjusted IA Forecast, Multiplier, Adjusted User Forecast, MFP, Actuals, and Last Year Actuals or Last to Last Year Actuals (as per filter selection of Compare With).

  6. The module should display discount %, effective discount %, actual discount %, and comparison discount %.

  7. The discount % should be editable.

  8. The module should update the forecast in real-time based on the edited discount %.

  9. The Deep-dive overview should display Original IA Forecast, Multiplier, Adjusted User Forecast, Actuals, Last year's actuals, and Comparison Actuals.

  10. The **Multiplier** should be **editable**.

  11. The **Adjusted User forecast** should update in real-time based on changes to the Multiplier.

  12. The Deep Dive hierarchy should consist of three levels:  
{Class -> Style Color ID -> Store}.

     * Each level should display relevant forecast data.

     * Clicking on a level should provide a breakdown of data at the next lower level.

  13. Edits made in the deep dive should update other data points according to the split ratio, and the lock/unlock functionality for editing should work seamlessly.

  14. The graph should visually represent Original IA Forecast, Adjusted IA Forecast, Multiplier, Adjusted User Forecast, MFP, Actuals, and Last Year Actuals or Last to Last Year Actuals.

  15. The Scenario Module should include all metrics available in the Adjusted Forecast tab, while allowing users to:

     * Add new scenarios.

     * Delete existing scenarios.

     * Have scenario forecasts update dynamically based on changes to the multiplier or manually entered values.

  16. Historical Data:

     * The module should display the last 8 weeks of forecast data, filtered by the selected weeks.

     * It should also include Last Year (LY) metrics based on the selected Product and Store filters.

  17. The ADA Visual module should display future data for only 8 weeks or up to a maximum of 26 weeks.

  18. There should be a toggle/switch labeled "Eligible SKUs / All SKUs" on the UI. The default toggle position should be configurable at the client level.

  19. The user should be able to view a breakdown of other influencing drivers affecting their forecast beyond discount % and promotions.

  20. The information should be available **week-wise** for **product-channel combination**.

  21. The weightage of each driver should be displayed clearly, ensuring users can analyze its relative importance.

  22. The data should be presented in a **read-only format** , meaning users cannot edit or modify the values.

  23. The view should be **intuitive and well-organized** , making it easy to interpret the impact of various drivers on the forecast.




