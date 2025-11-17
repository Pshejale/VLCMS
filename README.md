# Vehicle Life Cycle Management System (VLCMS)

A full-stack database application for managing the entire lifecycle of vehicles — from ownership, servicing, part replacements, warranties, to insurance tracking.  

# Quick Start
1. Install Dependencies
```
pip install -r requirements.txt
```

2. Setup Database
```
# It creates the database with all tables
mysql -u root -p < Sql_scripts/Tables.sql
```
4. Load Functions
```
mysql -u root -p < Sql_scripts/functions.sql

```
5. Load Stored Procedures
```
mysql -u root -p < Sql_scripts/procedures.sql

```
6. Load Triggers
```
mysql -u root -p < Sql_scripts/triggers.sql

```
7. Load Sample Data
```
mysql -u root -p < Sql_scripts/sample_data.sql

```
8. Create Limited User + Privileges
```
mysql -u root -p < Sql_scripts/Create_user_previlages.sql

```
9. Configure

Edit ```db_config.py```:
- Chage user name to your user name 
- Chagne the password to yuor password 
- or you can use the previous username and password beacuse you are already creted those user .

10. Run the Application
A. Normal Run
```
python app.py

```
C. Optional Windows Launcher
Double-click:
```
start_interface.bat

```

# File Structure 
```
VLCMS/
│── README.md
│── requirements.txt
│
├── Sql_scripts/
│   ├── Create_user_previlages.sql
│   ├── functions.sql
│   ├── function_testing.sql
│   ├── procedures.sql
│   ├── procedures_test.sql
│   ├── Tables.sql
│   ├── triggers.sql
│   └── triggers_checkup.sql
│
└── vlcms_app/
    ├── app.py
    ├── db_config.py
    ├── roles_config.py
    ├── start_interface.bat
    │
    ├── static/
    │   └── style.css
    │
    └── templates/
        ├── base.html
        ├── dashboard.html
        ├── delete.html
        ├── functions.html
        ├── function_form.html
        ├── function_result.html
        ├── insert.html
        ├── login.html
        ├── procedures.html
        ├── procedure_form.html
        ├── procedure_result.html
        ├── queries.html
        ├── query_result.html
        ├── tables.html
        ├── table_view.html
        ├── triggers.html
        ├── update.html
        └── vehicles.html
```
