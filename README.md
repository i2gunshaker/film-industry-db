# 🎬 Film Industry Database Management System

A fully-functional, logically formulated Database Management System (DBMS) designed from scratch to manage movies, actors, studios, and financial records within the film industry. 

This project demonstrates a thorough understanding of advanced database concepts, normalized architecture, and complex PL/SQL programming.

## 📌 Project Overview
The film industry generates massive amounts of relational data, from cast and crew assignments to box office tracking and studio management. The objective of this project was to design a robust DBMS that handles this data effectively, ensuring data integrity, optimized querying, and automated business rules.



## 🗄️ System Architecture & Schema
The database schema adheres to strict normalization principles (up to 3NF) to accurately model real-world film industry entities and their complex many-to-many relationships. The architecture consists of 20 distinct tables:

### Core Entities
* **`Movie`**: Central entity storing titles, release dates, durations, and maturity ratings.
* **`Actor` & `Production_Staff`**: Separated entities for on-screen talent and behind-the-scenes crew.
* **`Character`**: Canonical fictional identities portrayed by actors.
* **`Studio`**: Production companies linked to founding years and headquarters.
* **`Review`**: User-generated ratings and textual reviews for movies.
* **`User`**: Registered users who submit reviews.

### Lookup & Reference Tables
* **`Role`, `Genre`, `Language`, `Country`, `Award`**: Standardized lookup tables to maintain data consistency and avoid anomalies.

### Associative (Bridge) Tables
To resolve many-to-many relationships, the following bridge tables were implemented with composite/foreign keys:
* **`Movie_Cast`**: Links Movies, Actors, and Characters.
* **`Movie_Crew`**: Links Movies, Staff, and Roles.
* **`Movie_Genre`**, **`Movie_Language`**, **`Movie_Country`**, **`Movie_Studio`**: Maps movies to their respective attributes.
* **`Movie_Awards`**: Tracks which movie, actor, or staff member won specific awards in a given year.

### System & Security
* **`Audit_Log`**: An automated table populated by triggers to track `INSERT`, `UPDATE`, and `DELETE` operations on critical tables, storing both old and new data payloads.

## 📈 Data Population & Volume
To simulate a realistic production environment and properly test the efficiency of our PL/SQL queries, the database was populated using **Mockaroo**. 

The dataset contains over **100,000 total records** distributed across the relational schema:

| Table | Row Count | Table | Row Count |
| :--- | :--- | :--- | :--- |
| **Review** | 29,109 | **Movie_Studio** | 2,000 |
| **Movie_Cast** | 18,000 | **Movie_Language** | 2,000 |
| **Character** | 18,000 | **Movie_Country** | 1,800 |
| **Movie_Crew** | 15,090 | **Movie_Awards** | 1,500 |
| **User** | 10,000 | **Movie** | 1,500 |
| **Actor** | 5,000 | **Award** | 198 |
| **Movie_Genre** | 2,700 | **Studio** | 150 |
| **Production_Staff** | 2,000 | **Role** | 50 |
| **Country** | 30 | **Genre** | 30 |
| **Language** | 12 | **Audit_Log** | *Dynamic (via Triggers)* |

## ⚙️ Advanced PL/SQL Implementation
To meet complex business requirements, the database relies on **28 advanced PL/SQL blocks**, each serving a specific real-world logical purpose:

* **Functions and Procedures (9):** Designed to handle recurring business operations, such as calculating the average rating for an actor's filmography or securely inserting a new movie while validating inputs.
* **Cursors and Records (7):** Utilized explicit cursors to iterate through complex result sets. Examples include generating formatted reports for top co-actors, yearly studio releases, and actor filmographies.
* **Packages and Exceptions (3):** Grouped related procedures into unified packages (`pkg_award_manager`, `pkg_search`, `pkg_movie_maint`) for modularity. Includes strict **Exception Handling** using `RAISE_APPLICATION_ERROR` to catch and resolve issues gracefully.
* **Collections (2):** Utilized `BULK COLLECT` and associative arrays to temporarily hold bulk lists of data (like fetching all "Drama" movies into memory) to optimize processing.
* **Triggers (7):** Automated business rules enforced at the database level. Includes validating that award years match movie release dates, preventing the deletion of active studios, and populating the `Audit_Log` table automatically.

## 🖥️ Application Interface

A user-friendly, unified **Admin CRUD** front-end interface was built using **Oracle APEX**. Instead of sprawling across dozens of pages, it utilizes a highly efficient single-page architecture to manage the entire database:
* **Dynamic Table Routing:** A main dropdown selector (`P2_TABLE`) dynamically toggles the active workspace, revealing specific UI regions, form fields, and reports for the chosen entity (e.g., *Production Staff*, *Movie Genres*, *Reviews*, *Languages*).
* **Popup LOV Searching:** Complex foreign key relationships (like assigning an Actor to a Movie) are handled safely via intuitive Popup List-of-Values (LOVs) with built-in search functionality.
* **Unified Processing:** Insert and Delete operations are managed by a consolidated PL/SQL process that reads the active table context and executes the appropriate DML statements safely in the background.

## 📂 Repository Structure
```text
film-industry-db/
├── docs/                               
│   ├── film_db_erd.png                        
├── sql/                                
│   ├── 01_ddl_schema.sql               
│   ├── 02_views.sql                    
│   ├── 03_dml_mockaroo_data.sql        
│   ├── 04_functions_procedures.sql     
│   ├── 05_cursors_records.sql          
│   ├── 06_packages_exceptions.sql      
│   ├── 07_collections.sql              
│   └── 08_triggers.sql                 
└── app_interface/                      
    └── f182083.sql
    └── app_builder_button_scripts.sql 
