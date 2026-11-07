# SmartFix - Smart Service Provider Management System
Flask + PostgreSQL

## Run
1. Install PostgreSQL and create an empty database:  createdb -U postgres smartfix   (or create "smartfix" in pgAdmin)
2. pip install -r requirements.txt
3. Set your DB password (default user postgres):
   Windows CMD:  set DB_PASSWORD=yourpassword
   Linux/Mac:    export DB_PASSWORD=yourpassword
4. python init_db.py     (creates tables, sample data, demo passwords)
5. python app.py         -> open http://127.0.0.1:5000

## Demo logins (password for all: password123)
- Customer: priya@example.com
- Worker:   arun@example.com   (Worker 'Dinesh', dinesh@example.com, is Pending for admin verification demo)
- Admin:    admin@smartfix.com
