import mysql.connector

def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",  # change if using a different username
        password="339018",  # use your real password here
        database="flight_tracking"  # or whatever you called your DB
    )
