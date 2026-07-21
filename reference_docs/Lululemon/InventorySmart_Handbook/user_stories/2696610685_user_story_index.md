# User Story Index

| Field | Value |
|---|---|
| Confluence page ID | `2696610685` |
| Source URL | https://impactanalytics.atlassian.net/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610685/User+Story+Index |
| Mirrored from | Impact Analytics Confluence (Inventory Smart- Handbook) |
| Created (Confluence) | 2026-05-21T09:44:14.980Z |
| Last mirrored | 2026-05-21 |

---

Inventory Smart - A&R consists of multiple modules. Some of these modules are independent of others. For some, there is no prerequisite other than data. Some of the modules are completely dependent on other modules. So the development for those cannot be stated before the prerequisites are met. Below is the recommended order for the user stories for development. For each module, dependent modules are added. Modules which does not have any dependencies can be picked up together in one sprint.

For the table or data dependency, go through this - [Required table list](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609807/Module+Level+Table+Mapping)

  1. [Configuration -> Product -> Product Status](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610803/Configuration+-+Product+-+Product+Status)

     * Module Dependency - None

  2. [Configuration -> Store -> Store Status](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610899/Configuration+-+Store+-+Store+Status)

     * Module Dependency - None

  3. [Configuration -> DC -> DC Status](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611025/Configuration+-+DC+-+DC+Status)

     * Module Dependency - None

  4. [Configuration -> Product -> Product-Store Mapping](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610831/Configuration+-+Product+-+Product-Store+Mapping)

     * Module Dependency - None

  5. [ADA Visual](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610753/ADA+Visual+-+User+Story)

     * Module Dependency - None (Though there is no direct product level dependency, it is recommended to have some basic status and eligibility modules so that eligibility to the forecasting team can flow from the system)

  6. [Grouping -> Product Group](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610771/Grouping+-+Product+Group)

     * Module Dependency - None

  7. [Grouping -> Store Group](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610787/Grouping+-+Store+Group)

     * Module Dependency - None

  8. [Product Profile](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611244/Product+Profile+-+User+Story)

     * Module Dependency - None

  9. [Configuration -> Product -> Product-DC Mapping](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610859/Configuration+-+Product+-+Product-DC+Mapping)

     * Module Dependency - None

  10. [Configuration -> Store -> Store-DC Mapping](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610922/Configuration+-+Store+-+Store-DC+Mapping)

     * Module Dependency - None

  11. [Configuration -> DC-Store Policy -> DC Store Strategy Rules](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611046/Configuration+-+DC+Store+Policy+-+DC+Store+Strategy+Rules)

  12. [Configuration -> DC-Store Policy -> Auto Allocation Rules](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611080/Configuration+-+DC+Store+Policy+-+Auto+Allocation+Rules)

  13. [Configuration -> DC-Store Policy -> Auto Allocation Scheduler](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611113/Configuration+-+DC+Store+Policy+-+Auto+Allocation+Scheduler)

  14. [Constraints -> Store Allocations](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611179/Constraints+-+Store+Allocations)

     * Module Dependency - None

  15. [Constraints -> User Reserve](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611213/Constraints+-+User+Reserve)

     * Module Dependency - 

       * Configuration -> Product -> Product-DC Mapping

  16. [Configuration -> DC-Store Policy -> DC Store Strategy](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611146/Configuration+-+DC+Store+Policy+-+DC+Store+Strategy)

     * Module Dependency - 

       * DC Store Strategy Rules

       * Auto Allocation Rules

       * Auto Allocation Scheduler

       * Store Group

       * Product Profile

  17. [Create New Allocation - Details Table](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611283/Create+New+Allocation+-+User+Story)

     * Module Dependency - 

       * All Above Modules and Screens

  18. [Configuration -> Product -> Product Supersession](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610885/Configuration+-+Product+-+Product+Supersession)

     * Module Dependency - 

       * Product Status

  19. [Decision Dashboard - Date ticker and KPIs](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story)

     * Module Dependency - None

  20. [Report -> Store Stock Drill Down](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611595/Reports+-+User+Story)

     * Data Dependency - [Required table list](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696609807/Module+Level+Table+Mapping)

     * Module Dependency - None

  21. [Report -> Excess Inventory](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611595/Reports+-+User+Story)

     * Module Dependency - None

  22. [Create New Allocation - Review Store and DC](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611283/Create+New+Allocation+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Details Table

  23. [Decision Dashboard -> Forecast Alerts](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story) (For each Alert, a separate story is required) - [Main Story](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story)

     * Module Dependency - 

       * ADA Visual

       * Decision Dashboard - Date ticker and KPIs

  24. [Report -> Lost Sales](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611595/Reports+-+User+Story)

     * Module Dependency - None

  25. [Create New Allocation - Pre and Post Processing](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611283/Create+New+Allocation+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Details Table

       * Create New Allocation - Review Store and DC

  26. [Decision Dashboard -> Allocation Alerts](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story) (This is excluding Auto Allocation and PO/ASN To Allocate) - For each Alert, a separate story is required - [Main Story](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Details Table

       * Decision Dashboard - Date ticker and KPIs

  27. [Create New Allocation - Recommendation Screen](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611283/Create+New+Allocation+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Details Table

       * Create New Allocation - Review Store and DC

       * Create New Allocation - Pre and Post Processing

  28. [Create New Allocation -> Recommendation Screen -> Store Capacity](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611375/Create+New+Allocation+-+Recommendation+Screen+-+Store+Capacity)

     * Module Dependency - 

       * Create New Allocation - Details Table

       * Create New Allocation - Review Store and DC

       * Create New Allocation - Pre and Post Processing

  29. [Order Batching](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611410/Order+Batching+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Recommendation Screen

  30. [View Past Allocation](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611422/View+Past+Allocation+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Recommendation Screen

       * Order Batching (Only if Order Batching is eligible for the client)

  31. [Decision Dashboard -> View Allocation Plans](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Recommendation Screen

  32. [Decision Dashboard -> Details](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Details Table

       * Decision Dashboard - Date ticker and KPIs

  33. [Decision Dashboard -> Alerts -> Auto Allocation](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Recommendation Screen

       * Decision Dashboard - Date ticker and KPIs

  34. [Decision Dashboard -> Alerts -> PO/ASN To Allocate](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611453/Decision+Dashboard+-+User+Story)

     * Module Dependency - 

       * Create New Allocation - Details Table

       * Decision Dashboard - Date ticker and KPIs

  35. [Configuration -> Store -> New Store Setup](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696610948/Configuration+-+Store+-+New+Store+Setup)

     * Module Dependency - None

  36. [Report -> Daily Allocation Summary](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611595/Reports+-+User+Story)

     * Module Dependency - None

  37. [Report -> Deep Dive Allocation](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611595/Reports+-+User+Story)

     * Module Dependency - None

  38. [Downstream File Generation and Integration](/wiki/spaces/~7120208879ed2e673641b6b354fc145398edd5/pages/2696611649/Downstream+File+Generation+and+Integration)

     * Module Dependency - None




