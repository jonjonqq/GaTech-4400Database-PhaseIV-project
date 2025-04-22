# Simple Airline Management System (SAMS)

This is the Phase IV implementation of the CS4400 Project. It is a full-stack Flask web application connected to a MySQL database, allowing users to manage airline operations including flights, passengers, pilots, airports, and simulations.

---

## ✅ Prerequisites

- Python 3.9+
- MySQL Server (locally installed and running)
- MySQL Workbench (optional for DB inspection)
- VS Code (or any Python-compatible IDE)

---

## 🗂 Folder Structure

```
4400PhaseIV/
├── app.py                 # Main Flask app with all routes and views
├── db_config.py           # MySQL connection configuration
├── requirements.txt       # Python dependencies
├── templates/             # HTML files for each view and form
│   └── *.html
├── venv/                  # Virtual environment (not included in source control)
├── cs4400_sams_phase3_database_v0.sql
└── cs4400_sams_phase3_mechanics_TEMPLATE_fix.sql
```

---

## ⚙️ Setup Instructions

### 1. Clone or Move Project Folder
Make sure `4400PhaseIV` is on your local machine.

### 2. Open VS Code Terminal & Set Up Virtual Environment
```bash
cd path\to\4400PhaseIV
python -m venv venv
.\venv\Scripts\activate
```

### 3. Install Required Packages
```bash
pip install -r requirements.txt
```

### 4. Set Up MySQL Database
- Open MySQL Workbench
- Create database:
- Run `...database_v0.sql` script to create database "flight_tracking"
- Run the full `...TEMPLATE_fix.sql` script to populate tables, procedures, and views.

### 5. Configure `db_config.py`
Edit your MySQL username and password:
```python
mysql.connector.connect(
    host="localhost",
    user="root",
    password="your_password",
    database="flight_tracking"
)
```

---

## 🚀 Running the Application

### In VS Code terminal (with venv activated):
```bash
python app.py
```
Visit `http://127.0.0.1:5000` in your browser.

---

## 💻 Functionality Checklist

| Feature                            | Status |
|-----------------------------------|--------|
| All 13 stored procedures callable | ✅      |
| All 6 global views display data   | ✅      |
| Manual table viewing (e.g. flight)| ✅      |
| Full navigation from homepage     | ✅      |

---

## 👥 Team Info

- By my self
- Jonathan Perng
- GTID 904026858
- Phase IV Group 43

---

## 💬 Contact
For issues or setup questions, contact jonjon1129xx@gmail.com
