import mysql.connector

def get_connection(user="vlcms_user", password="vlcms123"):
    return mysql.connector.connect(
        host="localhost",
        user=user,
        password=password,
        database="VLCMS"
    )
