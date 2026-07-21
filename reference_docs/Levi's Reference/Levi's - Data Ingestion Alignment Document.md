# **LEVI’s**

# **Data Ingestion Alignment**

**Table of contents**

[**1\.  Workstreams for IA to handle/exclude	2**](#1.-workstreams-for-ia-to-handle/exclude)

[**2\.  List of Data Feeds Sharing/Parked/Dropped	3**](#2.-list-of-data-feeds-sharing/parked/dropped)

[**3\.  Plan/Expectations of Data Sharing for Historic, Weekly \- Catchups and Periodic Feeds	5**](#3.-plan/expectations-of-data-sharing-for-historic,-weekly---catchups-and-periodic-feeds)

[**4\. Entity Relationship Diagrams (ERDs) for each of the finalised Feeds.	6**](#4.-entity-relationship-diagrams-\(erds\)-for-each-of-the-finalised-feeds.)

[**5\. QC and data validations	7**](#5.-qc-and-data-validations)

[**6\. Catch up data feeds	8**](#6.-catch-up-data-feeds)

[**7\. Periodic data \- Alignment	9**](#7.-periodic-data---alignment)

[7.1 Supported data connectors:	9](#7.1-supported-data-connectors:)

[7.2. Key requirement for “file type” data transfer:	10](#7.2.-key-requirement-for-“file-type”-data-transfer:)

[7.3. Key requirement for “View type” data transfer:	11](#7.3.-key-requirement-for-“view-type”-data-transfer:)

[7.4. Table specific alignments	11](#7.4.-table-specific-alignments)

[7.5 Periodic data \- Cadence, File timings and Ingestion time window, Tool downtime \- **WIP**	11](#7.5-periodic-data---cadence,-file-timings-and-ingestion-time-window,-tool-downtime---wip)

[7.6 Periodic data \- Mandatory/Non-Mandatory and Triggers \- **WIP**	12](#7.6-periodic-data---mandatory/non-mandatory-and-triggers)

[7.7 Notifications and data related automated communication	13](#7.7-notifications-and-data-related-automated-communication)

[7.8 QC and data validations \- Periodic \- **WIP**	14](#7.8-qc-and-data-validations---periodic---wip)

[7.9 Periodic data \- Environments for data integration \- **WIP**	14](#7.9-periodic-data---environments-for-data-integration---wip)

[**8\. Data Schemas Aligned and Finalised	15**](#8.-data-schemas-aligned-and-finalised)

[**9\. Data Transformations and QC/Validations Checklist \- WIP	21**](#9.-data-transformations-and-qc/validations-checklist---wip)

[9.1 Data QC/Validations Checklist \- Historic	21](#9.1-data-qc/validations-checklist---historic)

[9.2 Data Transformations List \- Historic	24](#9.2-data-transformations-list---historic)

[**10\. Sample Emails:	26**](#10.-sample-emails:)

[10.1 Failure mail if we don't receive a trigger from the client.	26](#10.1-failure-mail-if-we-don't-receive-a-trigger-from-the-client.)

[10.2 Success mail for pulling the views	27](#10.2-success-mail-for-pulling-the-views)

[10.5 This is begin email for client when we receive triggers from clients to start the ingestion	28](#10.5-this-is-begin-email-for-client-when-we-receive-triggers-from-clients-to-start-the-ingestion)

[**11\. Outbound Files Alignment:	29**](#11.-outbound-files-alignment:)

[11.1 List of Outbound Feeds to be shared back with Levis	29](#11.1-list-of-outbound-feeds-to-be-shared-back-with-levis)

[11.2 Schema of the aligned Outbound Feed(s):	29](#11.2-schema-of-the-aligned-outbound-feed\(s\):)

[11.3 Additional Info on the aligned Outbound Feed(s):	30](#11.3-additional-info-on-the-aligned-outbound-feed\(s\):)

### 

### 1\.  Workstreams for IA to handle/exclude {#1.-workstreams-for-ia-to-handle/exclude}

The two tables below describes the workstreams/ business models of Levis that IA has to handle and the business models that are currently out of scope

Table 1.1: In Scope

| Workstreams in current scope |  |  |  |  |  |  |
| :---: | ----- | ----- | ----- | ----- | ----- | ----- |
| **Sl No.** | **Affiliate** | **Channel** | **Sub Channel** | **Business Model** | **Aligned understanding** | **Remarks** |
| 1 | CANADA | RETAIL | ECOMMERCE | COMPANY OPERATED | CA eCom |  |
| 2 | CANADA | RETAIL | MAINLINE | COMPANY OPERATED | CA Mainline |  |
| 3 | CANADA | RETAIL | OUTLET | COMPANY OPERATED | CA Outlet |  |
| 4 | MEXICO | RETAIL | ECOMMERCE | COMPANY OPERATED | MX eCom |  |
| 5 | MEXICO | RETAIL | MAINLINE | COMMISSIONAIRE | MX Mainline/Commissionaire | **PG Name:** MX Mainline Commissionaire |
| 6 | MEXICO | RETAIL | MAINLINE | FRANCHISE | MX Mainline \- FRANCHISE |  |
| 7 | MEXICO | RETAIL | MAINLINE | COMPANY OPERATED | \- | Included with Sl No. 5 |
| 8 | MEXICO | RETAIL | OUTLET | COMPANY OPERATED | MX Outlet |  |
| 9 | UNITED STATES | RETAIL | ECOMMERCE | COMPANY OPERATED | US eCom |  |
| 10 | UNITED STATES | RETAIL | MAINLINE | COMPANY OPERATED | US Mainline |  |
| 11 | UNITED STATES | RETAIL | OUTLET | COMPANY OPERATED | US Outlet |  |
| 12 | UNITED STATES | WHOLESALE | WHOLESALE | WHOLESALE | US VMI |  |

Table 1.2: Out of Scope

| Workstreams not in current scope |  |  |  |  |  |  |
| :---: | ----- | ----- | ----- | ----- | ----- | ----- |
| **Sl No.** | **Affiliate** | **Channel** | **Sub Channel** | **Business Model** | **Aligned understanding** | **Remarks** |
| 1 | CANADA | RETAIL | MAINLINE | FRANCHISE | Canada Mainline \- FRANCHISE | Out of scope |
| 2 | CANADA | RETAIL | OUTLET | FRANCHISE | Canada Outlet \- FRANCHISE | Out of scope |
| 3 | CANADA | WHOLESALE | WHOLESALE | WHOLESALE | Canada VMI | Out of scope |
| 4 | MEXICO | RETAIL | MAINLINE | CONCESSION | Mexico Mainline Concession | Not in current scope, Can get added in future |
| 5 | MEXICO | WHOLESALE | WHOLESALE | WHOLESALE | MEXICO VMI | Out of scope |

### 

### 2\.  List of Data Feeds Sharing/Parked/Dropped {#2.-list-of-data-feeds-sharing/parked/dropped}

**IA Recommendation**:  
IA recommended sharing the most granular data available. Going ahead, all the data feeds  that Levis shares with IA should be in line with the Schema and formats aligned below.

**Additional Comments:** The sheet attached has all the individual feeds discussed.  
**Resource**: [Levis\_Data\_Dictionary\_V1014.xlsx](https://docs.google.com/spreadsheets/d/1XYV8vSsFNikZkdxWfn_7W0w3D18MYqxv/edit?gid=1150724065#gid=1150724065)

Table 2.1: Data Feeds Aligned and Freezed/Parked:

| S.No. | Data | Workstreams Included | Workstreams Excluded | Schema Freeze Status |
| :---: | ----- | :---: | :---: | :---: |
|  |  |  |  |  |
| 1.1 | Inventory \- OnHand Data | Mainline, Outlet, VMI-wholesale, eCom locations and DCs | Franchise | Freezed |
| 1.2 | Inventory \- InTransit Data | O\&O, Outlet, VMI,  eCom locations | Franchise | Freezed |
| 1.3 | Inventory \- OnOrder Data | O\&O, Outlet, eCom locations | VMI, Franchise | Freezed |
| 2.1 | POS Data | O\&O, Outlet, Franchise, eCom locations |  | Freezed |
| 2.2 | eCom Demand | eCom Locations |  | Freezed |
| 2.3 | POS VMI | VMI locations |  | Freezed |
| 3.1 | Location Master | All Store Locations and DCs |  | Freezed |
| 4.1 | Product Master |  |  | Freezed |
| 4.2 | Product Price |  |  | Freezed |
| 4.3 | Product Cost |  |  | Freezed |
| 4.5 | Product attributes |  |  | Freezed |
| 4.6 | Product/Style images |  |  | Freezed |
| 5 | Fiscal Calendar |  |  | Freezed |
| 6 | Holidays and Store Closure |  |  | Freezed |
| 7 | Pack Configurations |  |  | Freezed |
| 8 | Due In |  |  | Freezed |
| 11 | Store SKU PG Eligibility |  |  | Freezed |
| 12 | DC-Store In transit data Lead Times |  |  | Freezed |
| 13 | DC-PC9 mapping |  |  | Freezed |
| 15 | Future Promotions Pricing | Schema Freeze to be done near Go-Live. Levis to confirm on pulling the data for IA |  |  |
| 16 | PDU |  |  | Freezed |
| 17 | Promotion Calendar |  |  | Freezed |
| 18 | VIR |  |  | Freezed |
| 19 | Currency Rates |  |  | Freezed |
| 24 | Delivered MTD |  |  | Freezed |

Table 2.2: Data Feeds Dropped:

| S.No. | Data | Workstreams Included | Workstreams Excluded | Schema Freeze Status |
| :---: | ----- | :---: | :---: | :---: |
|  |  |  |  |  |
| 4.4 | Product Lifecycle |  |  | Dropped |
| 9 | Web Traffic Data |  |  | Dropped |
| 10 | Planning Group-PC attributes |  |  | Dropped |
| 14 | Constraints Data |  |  | Dropped |
| 20 | Coupon Calendar |  |  | Dropped |
| 21 | COGs |  |  | Dropped |
| 22 | Country \- Instance mapping |  |  | Dropped |
| 23 | Supersession |  |  | Dropped |

### 

### 3\.  Plan/Expectations of Data Sharing for Historic, Weekly \- Catchups and Periodic Feeds {#3.-plan/expectations-of-data-sharing-for-historic,-weekly---catchups-and-periodic-feeds}

IA needs at least 2-3 years of data to build strong models. This historical data helps models to understand seasonality, trends, patterns, and other drivers of demand.  
Historic data required for product configurations have been aligned to be shared as a current snapshot of the respective feeds.  
Schema needs to be consistent between historic, weekly catchups, and periodic data.  
The below table explains the alignment with data sharing for Historic, weekly catchups and Daily Periodic Data.

Table 3.1: Data Sharing decision

| S.No. | Data | Historic Sharing (Yes/No) |  | Weekly Catchup Sharing (Yes/No) | Daily Periodic Sharing (Yes/No) |
| :---: | ----- | :---: | :---: | :---: | :---: |
|  |  | **Past Data** | **Current Snapshot** |  |  |
|  |  |  |  |  |  |
| 1.1 | Inventory \- OnHand Data | Yes |  | Yes | Yes |
| 1.2 | Inventory \- InTransit Data | Yes |  | Yes | Yes |
| 1.3 | Inventory \- OnOrder Data | Yes |  | Yes | Yes |
| 2.1 | POS Data | Yes |  | Yes | Yes |
| 2.2 | eCom Demand | Yes |  | Yes | Yes |
| 2.3 | POS VMI | Yes |  | Yes | Yes |
| 3.1 | Location Master | Yes |  | Yes | Yes |
| 4.1 | Product Master | Yes |  | Yes | Yes |
| 4.2 | Product Price | Dropped \- IA to pick from POS data |  |  | Yes |
| 4.3 | Product Cost | Not receiving for Historic and Catchups |  |  | Yes |
| 4.5 | Product attributes | Yes |  | Yes | Yes |
| 4.6 | Product/Style images | Yes |  | **Yes** | Yes |
| 5 | Fiscal Calendar | Yes |  | **Yes** | Yes |
| 6 | Holidays and Store Closure | Yes |  | **Yes** | Yes |
| 7 | Pack Configurations | Yes |  | Yes | Yes |
| 8 | Due In |  | Yes | Yes | Yes |
| 11 | Store SKU PG Eligibility |  | Yes | **Yes \- monthly maybe** | Yes |
| 12 | DC-Store In transit data Lead Times |  | Yes | **Yes** | Yes |
| 13 | DC-PC9 mapping |  | Yes | Yes | Yes |
| 15 | Future Promotions Pricing | Schema Freeze and Cadence to be confirmed by Levis. |  |  |  |
| 16 | PDU |  |  | Yes | Yes |
| 17 | Promotion Calendar |  |  |  | Yes |
| 18 | VIR |  | Yes | Yes | Yes |
| 19 | Currency Rates | Yes |  |  | Yes |
| 24 | Delivered MTD |  | Yes | Yes | Yes |

### 4\. Entity Relationship Diagrams (ERDs) for each of the finalised Feeds. {#4.-entity-relationship-diagrams-(erds)-for-each-of-the-finalised-feeds.}

| S.No. | Data | ERD Link |
| :---: | ----- | ----- |
|  |  |  |
| 1.1 | Inventory \- OnHand Data | [ERD \- Inventory \- OnHand Data](https://dbdiagram.io/d/Inventory-OnHand-Data-6798bc11263d6cf9a0475de4) |
| 1.2 | Inventory \- InTransit Data | [ERD \- Inventory \- InTransit Data](https://dbdiagram.io/d/Inventory-InTransit-Data-6798c135263d6cf9a047f24f) |
| 1.3 | Inventory \- OnOrder Data | [ERD \- Inventory \- OnOrder Data](https://dbdiagram.io/d/Inventory-OnOrder-Data-679876f0263d6cf9a03f93ba) |
| 2.1 | POS Data (Ecomm also) | [ERD \- POS Data (Ecomm also)](https://dbdiagram.io/d/POS-Data-Ecomm-also-6798809b263d6cf9a0407963) |
| 2.2 | eCom Demand | Will be created after the first data share for ecom demand. |
| 2.2 | POS VMI | [ERD \- POS VMI](https://dbdiagram.io/d/POS-VMI-67988f29263d6cf9a041eb30) |
| 3.1 | Location Master | [ERD \- Location Master](https://dbdiagram.io/d/Location-Master-67a99b3a263d6cf9a093f8a7) |
| 4.1 | Product Master | [ERD \- Product Master](https://dbdiagram.io/d/Product-Master-678e2e766b7fa355c36dbdd4) |
| 4.2 | Product Price | [ERD \- Product Price](https://dbdiagram.io/d/Product-Price-6799cde2263d6cf9a05dbe7d) |
| 4.3 | Product Cost | [ERD \- Product Cost](https://dbdiagram.io/d/Product-Cost-67a9cd68263d6cf9a09b547a) |
| 4.5 | Product attributes | [ERD \- Product attributes](https://dbdiagram.io/d/product-images-and-product-attributesand-currency-67a9c9da263d6cf9a09acbfe) |
| 4.6 | Product/Style images | [ERD \- Product/Style images](https://dbdiagram.io/d/product-images-and-product-attributesand-currency-67a9c9da263d6cf9a09acbfe) |
| 5 | Fiscal Calendar | [ERD \- Fiscal Calendar](https://dbdiagram.io/d/Fiscal-Calendar-679879b5263d6cf9a03fd758) |
| 6 | Holidays and Store Closure | [ERD \- Holidays and Store Closure](https://dbdiagram.io/d/Holidays-and-Store-Closure-67a301ea263d6cf9a012ff41) |
| 7 | Pack Configurations | [ERD \- Pack Configurations](https://dbdiagram.io/d/Pack-Configurations-67a9af32263d6cf9a096bb7d) |
| 8 | Due In | [ERD \- Due In](https://dbdiagram.io/d/Due-In-67a31d68263d6cf9a01687e3) |
| 11 | Store SKU PG Eligibility | [ERD \- Store SKU PG Eligibility](https://dbdiagram.io/d/Store-SKU-PG-Eligibility-67987407263d6cf9a03f4653) |
| 12 | DC-Store In transit data Lead Times | [ERD \- DC-Store In transit data Lead Times](https://dbdiagram.io/d/DC-Store-Transit-data-Lead_Time-67a325d7263d6cf9a017d417) |
| 13 | DC-PC9 mapping | [ERD \- DC-PC9 mapping](https://dbdiagram.io/d/DC-PC9-mapping-67a9b207263d6cf9a09725af) |
| 15 | Future Promotions Pricing | Can be created only post schema freeze |
| 16 | PDU | [ERD \- PDU](https://dbdiagram.io/d/PDU-67a32e8b263d6cf9a019463d) |
| 17 | Promotion Calendar | [ERD \- Promotion Calendar](https://dbdiagram.io/d/promotion-calender-67a33249263d6cf9a019d9d4) |
| 18 | VIR | [ERD \- VIR](https://dbdiagram.io/d/VIR-67a34e27263d6cf9a01dd15f) |
| 19 | Currency Rates | [ERD \- Currency Rates](https://dbdiagram.io/d/product-images-and-product-attributesand-currency-67a9c9da263d6cf9a09acbfe) |
| 24 | Delivered MTD | [ERD \- Delivered MTD](https://dbdiagram.io/d/Delivered-MTD-67b4323e263d6cf9a086c3da) |

### 

### 5\. QC and data validations {#5.-qc-and-data-validations}

Data Sanity checks will be done on all datasets before it is ingested into IA systems.  
A few simple examples of validations done are:  
1\. Level checks  
2\. Unique at a primary key level  
3\. Data consistency  
4\. Missing (or null values) hierarchies  
5\. Common columns to join across tables  
6\. Duplicate data check

**IA Recommendation**:   
We have put the suggested validation checklist for each table in the last section.  
Click [**here**](#heading=h.2jxsxqh) to see list of validations checklist.

**Alignment**: Once Historic Load is received by IA, we will start publishing the queries/data issues with the Levis IT Team to resolve them. Current Status: We have closed most of the blocker questions and few others which are open are getting looked into by the Levis IT Team.

**For the QC list that would run during the data absorption through the ingestion pipeline run \-**  
Once all the clean historical data is correctly received to IA, it will take some time to create the Ingestion Pipeline QC list on the historic data.

**Data Transformations:**  
IA has picked to do data transformations in the ingestion pipeline for the historic data feed and these will be already corrected and shared in the weekly catchups and daily periodic feeds.  
Click [**here**](#heading=h.h9lhe3w11vq3) for the Data Transformations list.

### 

### 6\. Catch up data feeds {#6.-catch-up-data-feeds}

Any missing data/report which can be informative and useful for ingestion, as any gap in historic data and periodic data needs to be “caught up” or transferred to or ingested in the IA system before periodic data can be consumed.

**IA Recommendation**:   
IA recommends to share catch up data in the same format as periodic.  
**Levis Alignment**:

| Sl No | Catchup Detail | Description | Share Start Date | Share End Date | Frequency |
| :---: | ----- | ----- | :---: | :---: | :---: |
| 1 | Catchup 1: February Load | Containing data from Dec 2024 to Jan 2025\. | 16 Feb 2025 | \- | Once |
| 2 | Catchup 2: March Load | Contains data for Feb 25 |  | \- | Once |
| 3 | Catchup 3,4,5, … | Weekly Catchup Data | 11 Mar 2025 |  | Weekly \- Tuesdays |

### 

### 7\. Periodic data \- Alignment {#7.-periodic-data---alignment}

#### **7.1 Supported data connectors:** {#7.1-supported-data-connectors:}

Below are the supported data connectors. IA recommended GCS.  
Other supported data connectors are: MSSQL, PostgreSQL, MySQL, Google Cloud Storage Folders, Snowflake, SFTP, BulkAPI, GCP PubSub

**IA Recommendation**: GCS folders but below alignment was selected based on Levis preference.  
**Levis Alignment:** Levis has agreed to share daily data feed through the connector mentioned below:

**Table 7.T1: Connector, Cadence, Timings**

| S.No. | Data | Periodic Sharing (Yes/No) | System/Manual Generated | Interface Share Approach |
| :---: | ----- | :---: | :---: | :---: |
| 1.1 | Inventory \- OnHand Data | Yes | System | Bulk API |
| 1.2 | Inventory \- InTransit Data | Yes | System | Bulk API |
| 1.3 | Inventory \- OnOrder Data | Yes | System | Bulk API |
| 2.1 | POS Data | Yes | System | Bulk API |
| 2.2 | eCom Demand | Yes | System | Bulk API |
| 2.3 | POS VMI | Yes | System | Bulk API |
| 3.1 | Location Master | Yes | System | GCP Pub-Sub |
| 4.1 | Product Master | Yes | System | GCP Pub-Sub |
| 4.2 | Product Price | Yes | System | GCP Pub-Sub |
| 4.3 | Product Cost | Yes | System | Bulk API |
| 4.5 | Product attributes | Yes | System | GCP Pub-Sub |
| 4.6 | Product/Style images | Yes | Manual | GCS Folders |
| 5 | Fiscal Calendar | Yes | Manual | GCS Folders |
| 6 | Holidays and Store Closure | Yes | Manual | GCS Folders |
| 7 | Pack Configurations | Yes | System | GCP Pub-Sub |
| 8 | Due In | Yes | System | Bulk API |
| 11 | Store SKU PG Eligibility | Yes | System | Bulk API |
| 12 | DC-Store In transit data Lead Times | Yes | Manual | GCS Folders |
| 13 | DC-PC9 mapping | Yes | System | Bulk API |
| 15 | Future Promotions Pricing | WIP |  |  |
| 16 | PDU | Yes | System | Bulk API |
| 17 | Promotion Calendar | Yes | Manual | GCS Folders |
| 18 | VIR | Yes | System | Bulk API |
| 19 | Currency Rates | Yes | System | Bulk API |
| 24 | Delivered MTD | Yes | System | Bulk API |

#### **7.2. Key requirement for “file type” data transfer:** {#7.2.-key-requirement-for-“file-type”-data-transfer:}

**Below** standard folder structure that helps in identifying the incremental data feed is recommended  
**Each** day a new folder is created and the incremental data is shared in that folder.  
For SFTP:

* Root directory  
  * YYYY-MM-DD  
    * \<file\_name\_pattern1\>.trg  
    * \<file\_name\_pattern1\>\_\<timestamp\>.\<file\_type\>  
    * \<file\_name\_pattern2\>\_\<timestamp\>.\<file\_type\>  
    * \<file\_name\_pattern2\>.trg

If GCS, below is the structure![][image1]  
If the data is supposed to be ingested on 6th Jan, 2025 then the folder name for those data files is expected to be 2025-01-06 and the data is expected to be of the date 2025-01-05.

**Levis Alignment:** IA will create the folders for multiple dates and Levis will be posting the manual feeds into the GCS folders at the aligned frequency for the feeds.

#### 

#### **7.3. Key requirement for “View type” data transfer:** {#7.3.-key-requirement-for-“view-type”-data-transfer:}

Record identifiers (**created\_timestamp** and **updated\_timestamp**) to track the row insertion timestamp. This helps in filtering the new records and boosts the query performance.

#### **7.4. Table specific alignments** {#7.4.-table-specific-alignments}

Below information needs to be aligned on each table shared:

* Full replace vs Incremental : The data is incremental data or full replace needs to aligned  
* File Type : Supported → (.csv, .txt, .parque, .dat), Recommended → .parque  
* Delimiter : Recommended → | (pipe)  
* Column Header and order of columns : Column headers should always be present and order of columns should remain consistent  
* Syncdatetime : table/row updated timestamp needs to be present 

#### **7.5 Periodic data \- Cadence, File timings and Ingestion time window, Tool downtime \- WIP** {#7.5-periodic-data---cadence,-file-timings-and-ingestion-time-window,-tool-downtime---wip}

* Triggers \- Single trigger vs table-specific trigger  
* Ingestion Time Window \- The ingestion time window needs to be aligned. Example: 4 AM EST to 7 AM EST  
* Tool downtime \- Expectations needs to be set up with clients on tool performance when data update is in progress

| S.No. | Data | Cadence | Feed Timing if system generated (PST) | Delta/Full Feed | Time Cutoff (PST) |
| :---: | ----- | :---: | ----- | :---: | :---: |
| 1.1 | Inventory \- OnHand Data | Daily | 12:30 AM | Delta | 1:30 AM |
| 1.2 | Inventory \- InTransit Data | Daily | 1:00 AM | Delta | 1:30 AM |
| 1.3 | Inventory \- OnOrder Data | Daily | 1:00 AM | Delta | 1:30 AM |
| 2.1 | POS Data | Daily | 12:30 AM | Delta | 1:30 AM |
| 2.2 | eCom Demand | Daily |  | Delta |  |
| 2.3 | POS VMI | Weekly \- Sundays | 8:30 PM | Delta | 1:30 AM |
| 3.1 | Location Master | Daily | 1:00 AM | Delta | 1:30 AM |
| 4.1 | Product Master | Daily | 1:00 AM | Delta | 1:30 AM |
| 4.2 | Product Price | Weekly | 1:00 AM | Delta | 1:30 AM |
| 4.3 | Product Cost | Daily | 1:00 AM | Delta | 1:30 AM |
| 4.5 | Product attributes | Daily | 1:00 AM | Delta |  |
| 4.6 | Product/Style images | Monthly | 8:00 PM | Full Feed | 11:59 PM |
| 5 | Fiscal Calendar | ad hoc | 8:00 PM | Full Feed | 11:59 PM |
| 6 | Holidays and Store Closure | ad hoc | 8:00 PM | Delta | 11:59 PM |
| 7 | Pack Configurations | Daily | 1:00 AM | Delta | 1:30 AM |
| 8 | Due In | Daily | 1:00 AM | Full Feed | 1:30 AM |
| 11 | Store SKU PG Eligibility | Daily | 1:00 AM | Full Feed, Delta | 1:30 AM |
| 12 | DC-Store In transit data Lead Times |  | 8:00 PM | Delta | 1:30 AM |
| 13 | DC-PC9 mapping | Daily | 1:00 AM | Delta | 1:30 AM |
| 15 | Future Promotions Pricing | WIP |  |  |  |
| 16 | PDU | Daily |  | Full Feed | 8:15 PM |
| 17 | Promotion Calendar | TBD \- Business |  | Full Feed | 11:59 PM |
| 18 | VIR | Daily |  | Full Feed | 2:15 AM |
| 19 | Currency Rates | daily |  | Delta | 1:30 AM |
| 24 | Delivered MTD | daily |  | Full Feed | 1:30 AM |

#### **7.6 Periodic data \- Mandatory/Non-Mandatory and Triggers** {#7.6-periodic-data---mandatory/non-mandatory-and-triggers}

Mandatory means IA will not initiate consuming the files and associated calculations if any mandatory files are missing.

| S.No. | Data | Mandatory/ Non-mandatory | Risk with Non-Mandatory |
| :---: | ----- | :---: | ----- |
| 1.1 | Inventory \- OnHand Data | Mandatory | Affects allocation since latest inv position unknown |
| 1.2 | Inventory \- InTransit Data | Mandatory | Affects allocation since latest inv position unknown |
| 1.3 | Inventory \- OnOrder Data | Mandatory | Affects allocation since latest inv position unknown |
| 2.1 | POS Data | Mandatory | Latest Sales Unknown for model to learn daily trends |
| 2.2 | eCom Demand | Mandatory | Latest Sales Unknown for model to learn daily trends |
| 2.3 | POS VMI | Mandatory | Latest Sales Unknown for model to learn weekly trends |
| 3.1 | Location Master | Mandatory | Cross validation dependency |
| 4.1 | Product Master | Mandatory | Cross validation dependency |
| 4.2 | Product Price | Non \- Mandatory |  |
| 4.3 | Product Cost | Non \- Mandatory |  |
| 4.5 | Product attributes | Non \- Mandatory |  |
| 4.6 | Product/Style images | Non \- Mandatory |  |
| 5 | Fiscal Calendar | Non \- Mandatory |  |
| 6 | Holidays and Store Closure | Non \- Mandatory |  |
| 7 | Pack Configurations | Non \- Mandatory |  |
| 8 | Due In | Mandatory | Updated Due In remaining calculation will not be accurate and latest which would hamper the pre-allocation |
| 11 | Store SKU PG Eligibility | Non \- Mandatory |  |
| 12 | DC-Store In transit data Lead Times | Non \- Mandatory |  |
| 13 | DC-PC9 mapping | Non \- Mandatory |  |
| 15 | Future Promotions Pricing | Non \- Mandatory |  |
| 16 | PDU | Mandatory | Mandatory to make sure we don't miss out on any month switch data. Can be made non mandatory if Levis is confident on being regular on this file |
| 17 | Promotion Calendar | Non \- Mandatory |  |
| 18 | VIR | Mandatory | Updated vir\_remaining and iob\_remaning will not be accurate and latest which would affect available dc oh for allocations |
| 19 | Currency Rates | Mandatory | Mandatory to absorb and keep updating the price values across multiple currencies on a daily baisis. |
| 24 | Delivered MTD | Mandatory | Updated pdu\_remaining calculation will not be accurate and latest which would affect available dc oh for allocations |

#### **7.7 Notifications and data related automated communication**  {#7.7-notifications-and-data-related-automated-communication}

IA usually sends two mails:

* Success/Failure mail on receiving data   
  * Sent to stakeholders once all the data is received on time and is in consumable form  
* Success/Failure in completion of data ingestion process  
  * Sent to all stakeholders once the whole data ingestion process is completed. Data validation summary reports are also sent  
    **Click [here](#10.-sample-emails:) to view sample email.**

#### 

#### **7.8 QC and data validations \- Periodic \- WIP** {#7.8-qc-and-data-validations---periodic---wip}

Any additional data validations needed apart from third module

**Alignment Deadline:** 

**Alignment**: 

#### **7.9 Periodic data \- Environments for data integration \- WIP** {#7.9-periodic-data---environments-for-data-integration---wip}

IA started receiving periodic files from \_\_\_\_\_. IA started receiving fully automated and stable periodic files from \_\_\_\_\_**.** Aligned with LEVI’s IT team on using periodic files from \_\_\_\_\_ for data ingestion.

**Levis Alignment**: 

| Item | Deadline Date for alignment | Alignment Date | Aligned data transfer deadline date | Status | Comments  |
| ----- | ----- | ----- | ----- | ----- | ----- |
| Table list identification |  |  |  |  |  |
| Historical Data |  |  |  |  |  |
| QC and Data validations |  |  |  |  |  |
| Periodic data |  |  |  |  |  |
| Mail communications |  |  |  |  |  |
| Catch up data |  |  |  |  |  |
| Unit Testing |  |  |  |  |  |
| Pipeline setup deadline-Dev |  |  |  |  |  |
| Pipeline setup deadline-Test |  |  |  |  |  |
| Pipeline setup deadline-UAT |  |  |  |  |  |
| Pipeline setup deadline-Prod |  |  |  |  |  |

### 8\. Data Schemas Aligned and Finalised {#8.-data-schemas-aligned-and-finalised}

Data Schemas and the level for each feed in the Sheet. [Levis\_Data\_Dictionary](https://docs.google.com/spreadsheets/d/1XYV8vSsFNikZkdxWfn_7W0w3D18MYqxv/edit?gid=1150724065#gid=1150724065).

All the schemas mentioned below will have 2 additional fields named: **created\_timestamp** and **updated\_timestamp**. These 2 fields will be used by IA to determine the entry record and update timings to fetch the latest detail of any of the conflicting entries in a feed

| S.No. | Data | Fields List | Level of the feed |
| :---: | ----- | ----- | ----- |
| 1.1 | Inventory \- OnHand Data | sku\_id pack\_id store\_id inventory\_date onhand\_qty | sku\_id pack\_id store\_id inventory\_date |
| 1.2 | Inventory \- InTransit Data | sku\_id pack\_id store\_id inventory\_date intransit\_qty | sku\_id pack\_id store\_id inventory\_date |
| 1.3 | Inventory \- OnOrder Data | sku\_id pack\_id store\_id inventory\_date onorder\_qty | sku\_id pack\_id store\_id inventory\_date |
| 2.1 | POS Data | transaction\_id transaction\_date line\_id sku\_id store\_id\_origin store\_id\_fulfilled transaction\_type workstation\_id unit\_retail\_price\_without\_taxes unit\_retail\_price\_with\_taxes quantity\_sold currency discount\_amount unit\_net\_selling\_price\_without\_taxes unit\_net\_selling\_price\_with\_taxes tax\_value price\_override\_flag | transaction\_id transaction\_date line\_id sku\_id store\_id\_origin store\_id\_fulfilled workstation\_id |
| 2.2 | eCom Demand | order\_id order\_date line\_id sku\_id store\_id\_origin store\_id\_fulfilled transaction\_type workstation\_id unit\_retail\_price\_without\_taxes unit\_retail\_price\_with\_taxes quantity\_sold currency discount\_amount unit\_net\_selling\_price\_without\_taxes unit\_net\_selling\_price\_with\_taxes tax\_value price\_override\_flag | order\_id order\_date line\_id sku\_id store\_id\_origin store\_id\_fulfilled workstation\_id |
| 2.3 | POS VMI | sku\_id store\_id\_origin fiscal\_year\_week transaction\_type unit\_net\_selling\_price\_without\_taxes unit\_net\_selling\_price\_with\_taxes quantity\_sold | sku\_id store\_id\_origin fiscal\_year\_week transaction\_type |
| 3.1 | Location Master | region channel\_id channel\_description store\_id store\_name store\_type country\_id state district city zipcode store\_status store\_open\_date store\_close\_date square\_footage planning\_group\_id planning\_group\_name affiliate\_id affiliate\_name subchannel businessmodel territory tourist\_local\_attribute climate markdown\_store account\_store\_number sls\_floor\_capacity store\_cluster store\_grade\_m ship\_to sold\_to store\_grade\_w | store\_id |
| 4.1 | Product Master | brand\_id brand\_name consumer\_id consumer\_desc sku\_desc category\_id category\_desc class\_id class\_desc subclass\_id subclass\_desc style\_id style\_description color\_id color\_description style\_color\_id country\_id country\_desc sku\_id season\_id season\_id\_descr size\_id size\_description channel\_specific product\_status | country\_id sku\_id season\_id |
| 4.2 | Product Price | style\_color\_id country\_id store\_id subchannel currency current\_price effective\_start\_date effective\_end\_date price\_status | style\_color\_id country\_id store\_id subchannel |
| 4.3 | Product Cost | sku\_id country\_id store\_id unit\_cost\_price currency | sku\_id country\_id store\_id |
| 4.5 | Product attributes | sku\_id country\_id attributes | sku\_id country\_id |
| 4.6 | Product/Style images | product\_id view asset\_url | product\_id view |
| 5 | Fiscal Calendar | cal\_date fiscal\_year\_num fiscal\_quarter\_num fiscal\_year\_qtr fiscal\_year\_month fiscal\_week\_num fiscal\_year\_week fiscal\_week\_day\_num fiscal\_day\_num season\_id season\_name | cal\_date |
| 6 | Holidays and Store Closure | store\_id store\_name state district district\_manager issue close\_date close\_time reopen\_date reopen\_time reason\_for\_closure estimated\_lost\_revenue fiscal\_wk\_1 fiscal\_wk\_2 fiscal\_wk\_3 fiscal\_wk\_4 fiscal\_wk\_5 number\_of\_full\_days\_closed | store\_id close\_date close\_time |
| 7 | Pack Configurations | brand channel\_id channel\_description pack\_id sku\_id pack\_desc pack\_type country\_id quantity season\_id prepack\_status | pack\_id sku\_id |
| 8 | Due In | dc\_id pack\_id sku\_id due\_in\_date due\_in\_unassigned | dc\_id pack\_id sku\_id due\_in\_date |
| 11 | Store SKU PG Eligibility | planning\_group\_id style\_color\_id store\_id sku\_id size\_percentage fiscal\_month start\_eligibility\_date end\_eligibility\_date carryover\_new\_ast wks\_of\_life volume\_rank pc9\_replacer on\_floor\_date end\_forecast\_date markdown\_date distributions lifecycle\_attribute store\_volume door\_count | planning\_group\_id store\_id sku\_id fiscal\_month |
| 12 | DC-Store In transit data Lead Times | store\_id dc\_id transit\_time | store\_id dc\_id |
| 13 | DC-PC9 mapping | style\_color\_id country\_id dc\_id start\_date end\_date allocation\_eligibility | style\_color\_id country\_id dc\_id start\_date end\_date |
| 15 | Future Promotions Pricing | Schema Freeze to be confirmed by Levis |  |
| 16 | PDU | region channel\_id style\_color\_id planning\_group\_id plan\_status fiscal\_week planned\_demand\_units sales\_plan | region channel\_id style\_color\_id planning\_group\_id plan\_status fiscal\_week |
| 17 | Promotion Calendar | planning\_group\_id store\_code starting\_date ending\_date brand\_name consumer\_id consumer\_desc category\_id category\_desc class\_id class\_desc subclass\_id subclass\_desc style-color\_id promo\_type discount\_percentage discount\_amount created\_timestamp updated\_timestamp | planning\_group\_id store\_code brand\_name consumer\_id consumer\_desc category\_id category\_desc class\_id class\_desc subclass\_id subclass\_desc style-color\_id promo\_type  |
| 18 | VIR | style\_color\_id planning\_group\_id fiscal\_month dc\_group vir\_reservation\_total vir\_reservation\_remaining iob\_reservation\_remaining | style\_color\_id planning\_group\_id fiscal\_month dc\_group |
| 19 | Currency Rates | date country currency conversion\_rate\_to\_usdollars | date country currency |
| 24 | Delivered MTD | style\_color\_id planning\_group\_id fiscal\_year\_month delivered\_mtd | style\_color\_id planning\_group\_id fiscal\_year\_month |

#### 

### 

### 9\. Data Transformations and QC/Validations Checklist \- WIP {#9.-data-transformations-and-qc/validations-checklist---wip}

#### 9.1 **Data QC/Validations Checklist \- Historic** {#9.1-data-qc/validations-checklist---historic}

| Check Sl No. | Feed Sl No. | Feed Name | Check | Description |
| :---: | :---: | ----- | ----- | ----- |
| 1 | 4.1 | Product Master | Null check in brand\_id | The brand\_id column in product should not have nulls and any such record found will be deleted. |
| 2 | 4.1 | Product Master | Null check in brand\_name | The brand\_name column in product should not have nulls and any such record found will be deleted. |
| 3 | 4.1 | Product Master | Null check in consumer\_id | The consumer\_id column in product should not have nulls and any such record found will be deleted. |
| 4 | 4.1 | Product Master | Null check in consumer\_desc | The consumer\_desc column in product should not have nulls and any such record found will be deleted. |
| 5 | 4.1 | Product Master | Null check in sku\_desc | The sku\_desc column in product should not have nulls and any such record found will be deleted. |
| 6 | 4.1 | Product Master | Null check in category\_id | The category\_id column in product should not have nulls and any such record found will be deleted. |
| 7 | 4.1 | Product Master | Null check in category\_desc | The category\_desc column in product should not have nulls and any such record found will be deleted. |
| 8 | 4.1 | Product Master | Null check in class\_id | The class\_id column in product should not have nulls and any such record found will be deleted. |
| 9 | 4.1 | Product Master | Null check in class\_desc | The class\_desc column in product should not have nulls and any such record found will be deleted. |
| 10 | 4.1 | Product Master | Null check in subclass\_id | The subclass\_id column in product should not have nulls and any such record found will be deleted. |
| 11 | 4.1 | Product Master | Null check in subclass\_desc | The subclass\_desc column in product should not have nulls and any such record found will be deleted. |
| 12 | 4.1 | Product Master | Null check in style\_id | The style\_id column in product should not have nulls and any such record found will be deleted. |
| 13 | 4.1 | Product Master | Null check in style\_description | The style\_description column in product should not have nulls and any such record found will be deleted. |
| 14 | 4.1 | Product Master | Null check in color\_id | The color\_id column in product should not have nulls and any such record found will be deleted. |
| 15 | 4.1 | Product Master | Null check in color\_description | The color\_description column in product should not have nulls and any such record found will be deleted. |
| 16 | 4.1 | Product Master | Null check in style\_color\_id | The style\_color\_id column in product should not have nulls and any such record found will be deleted. |
| 17 | 4.1 | Product Master | Null check in country\_id | The country\_id column in product should not have nulls and any such record found will be deleted. |
| 18 | 4.1 | Product Master | Null check in country\_desc | The country\_desc column in product should not have nulls and any such record found will be deleted. |
| 19 | 4.1 | Product Master | Null check in sku\_id | The sku\_id column in product should not have nulls and any such record found will be deleted. |
| 20 | 4.1 | Product Master | Null check in season\_id | The season\_id column in product should not have nulls and any such record found will be deleted. |
| 21 | 4.1 | Product Master | Null check in season\_id\_descr | The season\_id\_descr column in product should not have nulls and any such record found will be deleted. |
| 22 | 4.1 | Product Master | Null check in size\_id | The size\_id column in product should not have nulls and any such record found will be deleted. |
| 23 | 4.1 | Product Master | Null check in size\_description | The size\_description column in product should not have nulls and any such record found will be deleted. |
| 24 | 4.1 | Product Master | Null check in channel\_specific | The channel\_specific column in product should not have nulls and any such record found will be deleted. |
| 25 | 4.1 | Product Master | Null check in product\_status | The product\_status column in productshould not have nulls and any such record found will be deleted. |
| 26 | 2.1 | POS | Null check in transaction\_id | The transaction\_id column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 27 | 2.1 | POS | Null check in transaction\_date | The transaction\_date column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 28 | 2.1 | POS | Null check in line\_id | The line\_id column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 29 | 2.1 | POS | Null check in sku\_id | The sku\_id column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 30 | 2.1 | POS | Null check in store\_id\_origin | The store\_id\_origin column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 31 | 2.1 | POS | Null check in store\_id\_fulfilled | The store\_id\_fulfilled column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 32 | 2.1 | POS | Null check in workstation\_id | The workstation\_id column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 33 | 2.1 | POS | Null check in quantity\_sold | The quantity\_sold column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 34 | 2.1 | POS | Null check in currency | The currency column in POS Retail & Ecom should not have nulls and any such record found will be deleted. |
| 35 | 3.1 | Location Master | Null check in region | The region column in Location Master should not have nulls and any such record found will be deleted. |
| 36 | 3.1 | Location Master | Null check in channel\_id | The channel\_id column in Location Master should not have nulls and any such record found will be deleted. |
| 37 | 3.1 | Location Master | Null check in channel\_description | The channel\_description column in Location Master should not have nulls and any such record found will be deleted. |
| 38 | 3.1 | Location Master | Null check in store\_id | The store\_id column in Location Master should not have nulls and any such record found will be deleted. |
| 39 | 3.1 | Location Master | Null check in store\_name | The store\_name column in Location Master should not have nulls and any such record found will be deleted. |
| 40 | 3.1 | Location Master | Null check in store\_type | The store\_type column in Location Master should not have nulls and any such record found will be deleted. |
| 41 | 3.1 | Location Master | Null check in store\_status | The store\_status column in Location Master should not have nulls and any such record found will be deleted. |
| 42 | 3.1 | Location Master | Null check in planning\_group\_id | The planning\_group\_id column in Location Master should not have nulls and any such record found will be deleted. |
| 43 | 3.1 | Location Master | Null check in planning\_group\_name | The planning\_group\_name column in Location Master should not have nulls and any such record found will be deleted. |
| 44 | 3.1 | Location Master | Null check in affiliate\_id | The affiliate\_id column in Location Master should not have nulls and any such record found will be deleted. |
| 45 | 3.1 | Location Master | Null check in affiliate\_name | The affiliate\_name column in Location Master should not have nulls and any such record found will be deleted. |
| 46 | 3.1 | Location Master | Null check in subchannel | The subchannel column in Location Master should not have nulls and any such record found will be deleted. |
| 47 | 3.1 | Location Master | Null check in businessmodel | The businessmodel column in Location Master should not have nulls and any such record found will be deleted. |
| 48 | 1.1, 1.2, 1.3 | Inventory Master | Null check in sku\_id | The sku\_id column in Inventory Master should not have nulls and any such record found will be deleted. |
| 49 | 1.1, 1.2, 1.3 | Inventory Master | Null check in pack\_id | The pack\_id column in Inventory Master should not have nulls and any such record found will be deleted. |
| 50 | 1.1, 1.2, 1.3 | Inventory Master | Null check in store\_id | The store\_id column in Inventory Master should not have nulls and any such record found will be deleted. |
| 51 | 1.1, 1.2, 1.3 | Inventory Master | Null check in inventory\_date | The inventory\_date column in Inventory Master should not have nulls and any such record found will be deleted. |

#### 

#### 9.2 **Data Transformations List \- Historic** {#9.2-data-transformations-list---historic}

| Sl No. | Feed Sl No. | Feed Name | Check | Action |
| :---: | :---: | ----- | ----- | ----- |
| 1 | 4.1 | Product Master | Key Level duplicates | Pick the latest combination |
| 2 | 3.1 | Location Master | Key Level duplicates | Pick the latest combination |
| 3 | 3.1 | Location Master | Active/Inactive Stores | Anything except 'CL' will be active stores |
| 4 | 3.1 | Location Master | Store Open Data null | Wherever null: picking store\_open\_data as min   txn/inv date |
| 5 | 3.1 | Location Master | Acct Store \# | Change Store ID to account store number for VMI   Stores |
| 6 | 2.1 | POS | Row Level Duplicates | Remove the rows |
| 7 | 2.1 | POS | Key Level Duplicates for USA/CAD | Remove the rows |
| 8 | 2.1 | POS | Key Level Duplicates for Mexico | Pick the row as per the aligned logic |
| 9 | 2.1 | POS | Unit\_Retail\_Price | Ignore the rows with   unit\_retail\_price\_without\_taxes=0 for US/CAD |
| 10 | 2.1 | POS | Unit\_Retail\_Price | Ignore the rows with   unit\_retail\_price\_with\_taxes=0 for MXC |
| 11 | 2.1 | POS | Unit\_Retail\_Price | If Unit\_retail\_price is negative: convert it to   positive |
| 12 | 2.1 | POS | Unit\_Retail\_Price | For quantity\_sold\>1 , ignore the rows where   URP\>UNSP |
| 13 | 2.1 | POS | Unit\_Retail\_Price | For quantity\_sold=1 , ignore the rows where   URP\<UNSP |
| 14 | 2.1 | POS | Unit\_Net\_selling\_Price | Ignore negative UNSP for positive quantity\_sold |
| 15 | 2.1 | POS | Unit\_Net\_selling\_Price | Ignore positive UNSP for negative quantity\_sold |
| 16 | 2.1 | POS | Garbage values in store\_id\_fulfilled column | Ignore the rows with store\_id\_fulfilled='US' |
| 17 | 2.1 | POS | Transaction\_Type value | Ignore the rows with transaction\_type='Services' |
| 18 | 2.1 | POS | Discount Amount | Calculating this using URP and UNSP column |
| 19 | 2.1 | POS | Sku Check | Ignore the rows with skus not present in product   master |
| 20 | 2.1 | POS | Store Check | Ignore the rows with stores not present in   location master |
| 21 | 2.3 | POS VMI | Acct Store \# | Change Store ID to account store number  |
| 22 | 1.1, 1.2, 1.3 | Inventory Master | Key Level Duplicates | Sum up the Qty |
| 23 | 1.1, 1.2, 1.3 | Inventory Master | Negative OH,OO and IT values | Change negative values to 0 |
| 24 | 1.1, 1.2, 1.3 | Inventory Master | sku\_id format issue | Ignore these rows |
| 25 | 1.1, 1.2, 1.3 | Inventory Master | Store ID change | Changed store\_id 'C7559' to '7559' |
| 26 | 1.1, 1.2, 1.3 | Inventory Master | Old Store Mapping | Changed the PE2 stores to new stores using   Old\_Store to New\_Store Mapping |
| 27 | 1.1, 1.2, 1.3 | Inventory Master | Leading 0s | Removed leading 0s from all the store\_ids except   VMI Stores. |
| 28 | 1.1, 1.2, 1.3 | Inventory Master | Sku Check | Ignore the rows with skus not present in product   master |
| 29 | 1.1, 1.2, 1.3 | Inventory Master | Store Check | Ignore the rows with stores not present in   location master |
| 30 | 7 | Pack Configurations | Null values as string | Converting these to blanks. |
| 31 | 7 | Pack Configurations | Channel ID Column | Converting channel\_id to 10/20 from   Wholesale/RET |
| 32 | 7 | Pack Configurations | Sku Check | Ignore the rows with skus not present in product   master |
| 33 | 12 | DC-Store Transit Time | Row Level Duplicates | Picking any 1 row of the duplicated rows |
| 34 | 12 | DC-Store Transit Time | Transit\_time column | Rounding up values to the nearest whole number |
| 35 | 12 | DC-Store Transit Time | Store Check | Ignore the rows with stores not present in   location master |
| 36 | 16 | PDU | Sales\_plan column | Convert nulls and negative values to 0 |
| 37 | 16 | PDU | Decimal in Sales\_plan and pdu columns | Rounding up values to the nearest whole number |
| 38 | 16 | PDU | Sku Check | Ignore the rows with PC9s not present in product   master   |

#### 

### **10\. Sample Emails:** {#10.-sample-emails:}

#### 10.1 **Failure** mail if we don't receive a trigger from the client. {#10.1-failure-mail-if-we-don't-receive-a-trigger-from-the-client.}

#### 

#### 

#### 10.2 **Success** mail for pulling the views {#10.2-success-mail-for-pulling-the-views}

10.3 **Ingestion success** mail

10.4 **Validation fail** email, when we cross the data loss threshold

#### 10.5 This is begin email for client when we receive triggers from clients to **start the ingestion** {#10.5-this-is-begin-email-for-client-when-we-receive-triggers-from-clients-to-start-the-ingestion}

### **11\. Outbound Files Alignment:** {#11.-outbound-files-alignment:}

#### 11.1 List of Outbound Feeds to be shared back with Levis {#11.1-list-of-outbound-feeds-to-be-shared-back-with-levis}

| S.No. | Data | Schema Freeze Status |
| :---: | ----- | :---: |
|  |  |  |
| OB1 | **Allocation plan** | Freezed |

#### 11.2 Schema of the aligned Outbound Feed(s): {#11.2-schema-of-the-aligned-outbound-feed(s):}

| S.No. | Data | Fields List | Level of the feed |
| :---: | ----- | ----- | ----- |
| OB1 | Allocation Plan | ia\_allocation\_id from\_loc store sku\_id pack\_id order\_date ship\_to sold\_to mark\_for rdd\_date cancel\_date country\_id quantity allocation\_flag allocation\_type subchannel business\_model message\_type brand\_name consumer\_desc category\_desc class\_desc subclass\_desc planning\_group\_name upc\_ean | ia\_allocation\_id from\_loc store sku\_id pack\_id order\_date |

#### 

#### 11.3 Additional Info on the aligned Outbound Feed(s): {#11.3-additional-info-on-the-aligned-outbound-feed(s):}

11.3.1 How is an allocation-id generated: Refer to the tables below to understand how an allocation ID is to be read.

| Sample Allocation ID | A\_B\_C\_D |  |  |  |
| :---: | :---: | ----- | ----- | ----- |

| A | B | C | D |
| :---: | :---: | :---: | :---: |
| 6,9 | 118 3\_Auto\_Allocation | PG1 | Date Time stamp, Unique Identifier |
|  |  |  |  |
| 6 \- Manual Allocation | 118 \- Usercode | PG Number | Date Time stamp |
|  |  |  |  |
| 9 \- Auto Allocation | 3 \- Internal IA Allocation user ID |  |  |

| Type of Allocation | Sample Allocation ID |  |  |  |
| :---: | :---: | ----- | ----- | ----- |
| **Manual** | **6\_118\_PG1\_20241205T154806** |  |  |  |
| **Auto** | **9\_3\_Auto\_Allocation\_PG1\_097b7268-b2fc-11ef-a5d2-42010a0c010b** |  |  |  |

[image1]: <data:image/png;base64,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>