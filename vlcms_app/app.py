from flask import Flask, render_template, request, redirect, url_for, session, flash
from db_config import get_connection
from roles_config import ROLE_PERMISSIONS
import re
import mysql.connector
from mysql.connector import Error as MySQLError

app = Flask(__name__)
app.secret_key = "vlcms_flask_secret"

# -------------------------------
# LOGIN ROUTE
# -------------------------------
@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"].strip()
        password = request.form["password"].strip()

        try:
            db = get_connection(username, password)
            db.close()
            session["user"] = username
            session["password"] = password
            session["role"] = ROLE_PERMISSIONS.get(username, {})
            flash("Login successful!", "success")
            return redirect(url_for("dashboard"))
        except Exception as e:
            flash("Invalid credentials or access denied.", "danger")
            return render_template("login.html")
    return render_template("login.html")


# -------------------------------
# DASHBOARD
# -------------------------------
@app.route("/dashboard")
def dashboard():
    if "user" not in session:
        return redirect(url_for("login"))
    role = ROLE_PERMISSIONS.get(session["user"], {})
    return render_template("dashboard.html", user=session["user"], role=role)


# -------------------------------
# TABLE LIST PAGE
# -------------------------------
@app.route("/tables")
def tables():
    if "user" not in session:
        return redirect(url_for("login"))

    db = get_connection(session["user"], session["password"])
    cursor = db.cursor()
    cursor.execute("SHOW TABLES;")
    tables = [row[0] for row in cursor.fetchall()]
    db.close()

    role = ROLE_PERMISSIONS.get(session["user"], {})
    return render_template("tables.html", tables=tables, role=role, user=session["user"])


#-------------------------------
# TABLE VIEW PAGE   
#------------------------------
@app.route("/table/<name>")
def table_view(name):
    if "user" not in session:
        return redirect(url_for("login"))

    db = get_connection(session["user"], session["password"])
    cursor = db.cursor(dictionary=True)

    #  JOIN only for the vehicles table
    if name.lower() == "vehicles":
        query = """
            SELECT 
                v.Vehicle_Id,
                v.Reg_Num,
                v.Make,
                v.Model,
                v.Year,
                v.Milage,
                o.Name AS Owner_Name
            FROM vehicles v
            JOIN owner o ON v.Owner_Id = o.Owner_Id;
        """
    elif name.lower() == "vehicle_ownership_log":
        query = """
            SELECT 
                vol.Log_Id,
                vol.Reg_Num,
                o_old.Name AS Old_Owner_Name,
                o_new.Name AS New_Owner_Name,
                vol.Change_Date
            FROM 
                VEHICLE_OWNERSHIP_LOG vol
            LEFT JOIN OWNER o_old ON vol.Old_Owner_Id = o_old.Owner_Id
            LEFT JOIN OWNER o_new ON vol.New_Owner_Id = o_new.Owner_Id
            ORDER BY vol.Change_Date DESC;
        """
    # elif name.lower() == "service_record":
    else:
        query = f"SELECT * FROM {name}"

    try:
        cursor.execute(query)
        rows = cursor.fetchall()
        cols = [desc[0] for desc in cursor.description] if cursor.description else []
        db.close()

        role = ROLE_PERMISSIONS.get(session["user"], {})
        return render_template(
            "table_view.html",
            name=name,
            rows=rows,
            cols=cols,
            role=role,
            user=session["user"]
        )

    except Exception as e:
        print("❌ SQL ERROR:", e)   # Debug print in terminal
        if db: db.close()
        flash(f"MySQL Error: {str(e)}", "danger")
        return redirect(url_for("tables"))


# -------------------------------
# TRIGGERS, PROCEDURES, FUNCTIONS, QUERIES
# -------------------------------
#-------------------------------
# TRIGGERS PAGE
#------------------------------
@app.route("/triggers")
def triggers():
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    password = session["password"]

    db = None
    try:
        db = get_connection(user, password)
        cursor = db.cursor(dictionary=True)

        # ✅ Fetch triggers safely from information_schema
        cursor.execute("""
            SELECT TRIGGER_NAME, EVENT_MANIPULATION AS event_type,
                   EVENT_OBJECT_TABLE AS table_name, ACTION_TIMING AS timing
            FROM information_schema.TRIGGERS
            WHERE TRIGGER_SCHEMA = 'VLCMS';
        """)
        triggers = cursor.fetchall()
        db.close()

        return render_template("triggers.html", triggers=triggers, user=user)

    except Exception as e:
        flash(f"MySQL Error: {str(e)}", "danger")
        if db: db.close()
        return redirect(url_for("dashboard"))


@app.route("/procedures")
def procedures():
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    if user not in ["vlcms_user", "service_staff"]:
        flash("❌ You do not have permission to view procedures.", "danger")
        return redirect(url_for("dashboard"))

    password = session["password"]

    db = None
    try:
        db = get_connection(user, password)
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT ROUTINE_NAME, CREATED, LAST_ALTERED
            FROM information_schema.ROUTINES
            WHERE ROUTINE_SCHEMA = 'VLCMS' AND ROUTINE_TYPE = 'PROCEDURE';
        """)
        procedures = cursor.fetchall()
        db.close()

        return render_template("procedures.html", procedures=procedures, user=user)
    except Exception as e:
        flash(f"MySQL Error: {str(e)}", "danger")
        if db:
            db.close()
        return redirect(url_for("dashboard"))


@app.route("/run_procedure/<proc_name>", methods=["GET", "POST"])
def run_procedure(proc_name):
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    if user not in ["vlcms_user", "service_staff"]:
        flash("❌ You do not have permission to execute procedures.", "danger")
        return redirect(url_for("dashboard"))

    password = session["password"]
    db = get_connection(user, password)
    cursor = db.cursor(dictionary=True)

    try:
        # ✅ Get parameter list for this procedure
        cursor.execute("""
            SELECT PARAMETER_NAME, DATA_TYPE
            FROM information_schema.PARAMETERS
            WHERE SPECIFIC_SCHEMA='VLCMS' AND SPECIFIC_NAME=%s
            ORDER BY ORDINAL_POSITION;
        """, (proc_name,))
        params = cursor.fetchall()

        if request.method == "POST":
            # Collect all parameter values
            values = [request.form.get(p["PARAMETER_NAME"]) for p in params]

            try:
                cursor.callproc(proc_name, values)
                db.commit()

                # If the procedure returns result sets
                result_data = []
                for result in cursor.stored_results():
                    result_data.extend(result.fetchall())

                if result_data:
                    return render_template(
                        "procedure_result.html",
                        data=result_data,
                        proc_name=proc_name
                    )

                flash(f"✅ Procedure '{proc_name}' executed successfully!", "success")
                return redirect(url_for("procedures"))

            except Exception as e:
                db.rollback()
                flash(f"MySQL Error while executing procedure '{proc_name}': {str(e)}", "danger")
                return redirect(url_for("procedures"))

        # GET: show the input form dynamically
        return render_template("procedure_form.html", proc_name=proc_name, params=params)

    finally:
        db.close()



@app.route("/functions")
def functions():
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    if user not in ["vlcms_user","service_viewer","service_staff"]:
        flash("❌ You do not have permission to view functions.", "danger")
        return redirect(url_for("dashboard"))

    password = session["password"]
    db = None

    try:
        db = get_connection(user, password)
        cursor = db.cursor(dictionary=True)

        # ✅ Fetch list of all stored FUNCTIONS in VLCMS schema
        cursor.execute("""
            SELECT ROUTINE_NAME, DTD_IDENTIFIER AS return_type, CREATED, LAST_ALTERED
            FROM information_schema.ROUTINES
            WHERE ROUTINE_SCHEMA = 'VLCMS' AND ROUTINE_TYPE = 'FUNCTION';
        """)
        functions = cursor.fetchall()
        db.close()

        return render_template("functions.html", functions=functions, user=user)
    except Exception as e:
        flash(f"MySQL Error: {str(e)}", "danger")
        if db:
            db.close()
        return redirect(url_for("dashboard"))

@app.route("/run_function/<func_name>", methods=["GET", "POST"])
def run_function(func_name):
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    if user not in ["vlcms_user", "service_staff"]:
        flash("❌ You do not have permission to execute functions.", "danger")
        return redirect(url_for("dashboard"))

    password = session["password"]
    db = get_connection(user, password)
    cursor = db.cursor(dictionary=True)

    try:
        # ✅ Fetch input parameters for the function
        cursor.execute("""
            SELECT PARAMETER_NAME, DATA_TYPE
            FROM information_schema.PARAMETERS
            WHERE SPECIFIC_SCHEMA = 'VLCMS'
            AND SPECIFIC_NAME = %s
            AND PARAMETER_NAME IS NOT NULL  -- ✅ ignore return value row
            ORDER BY ORDINAL_POSITION;
        """, (func_name,))
        params = cursor.fetchall()


        if request.method == "POST":
            # Collect all parameter values from the form
            values = [request.form.get(p["PARAMETER_NAME"]) for p in params]
            placeholders = ", ".join(["%s"] * len(values))
            query = f"SELECT {func_name}({placeholders}) AS result;"

            try:
                cursor.execute(query, values)
                result = cursor.fetchone()
                db.close()
                return render_template(
                    "function_result.html",
                    func_name=func_name,
                    result=result["result"],
                    params=params,
                    values=values
                )
            except Exception as e:
                flash(f"MySQL Error while executing function '{func_name}': {str(e)}", "danger")
                db.close()
                return redirect(url_for("functions"))

        # GET request — show dynamic input form
        return render_template("function_form.html", func_name=func_name, params=params)

    finally:
        db.close()



@app.route("/queries")
def queries():
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    queries_list = [
        {"id": "nested", "name": "Vehicles with Above-Average Mileage"},
        {"id": "join", "name": "Latest Service Information"},
        {"id": "aggregate", "name": "Service Summary per Vehicle"}
    ]

    return render_template("queries.html", queries_list=queries_list, user=user)


@app.route("/run_query/<query_id>")
def run_query(query_id):
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    password = session["password"]
    db = None

    try:
        db = get_connection(user, password)
        cursor = db.cursor(dictionary=True)

        # Pick query dynamically based on ID
        if query_id == "nested":
            title = "Vehicles with Above-Average Mileage"
            query = """
                SELECT Reg_Num, Make, Model, Milage
                FROM VEHICLES
                WHERE Milage > (SELECT AVG(Milage) FROM VEHICLES);
            """

        elif query_id == "join":
            title = "Latest Service Information"
            query = """
                SELECT v.Reg_Num, o.Name AS Owner, w.Name AS Workshop,
                       MAX(sr.Service_Date) AS Last_Service
                FROM VEHICLES v
                JOIN OWNER o ON v.Owner_Id = o.Owner_Id
                JOIN SERVICE_RECORD sr ON v.Reg_Num = sr.Reg_Num
                JOIN WORKSHOP w ON sr.WorkShop_Id = w.WorkShop_Id
                GROUP BY v.Reg_Num, o.Name, w.Name;
            """

        elif query_id == "aggregate":
            title = "Service Summary per Vehicle"
            query = """
                SELECT Reg_Num,
                       COUNT(Service_Id) AS Total_Services,
                       SUM(Service_Cost) AS Total_Service_Cost
                FROM SERVICE_RECORD
                GROUP BY Reg_Num;
            """

        else:
            flash("❌ Unknown query selected.", "danger")
            return redirect(url_for("queries"))

        # Execute chosen query
        cursor.execute(query)
        data = cursor.fetchall()
        db.close()

        return render_template("query_result.html",
                               title=title,
                               data=data,
                               query_id=query_id)

    except Exception as e:
        if db:
            db.close()
        flash(f"MySQL Error while executing query: {str(e)}", "danger")
        return redirect(url_for("queries"))



# -------------------------------
# INSERT route with MySQL error handling
# -------------------------------
@app.route("/insert/<table>", methods=["GET", "POST"])
def insert_record(table):
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    password = session["password"]
    db = None

    try:
        db = get_connection(user, password)
        cursor = db.cursor(dictionary=True)
        cursor.execute(f"DESCRIBE {table}")
        columns = cursor.fetchall()

        if request.method == "POST":
            fields, values = [], []

            for col in columns:
                col_name = col["Field"]
                if col["Extra"] == "auto_increment":
                    continue
                fields.append(col_name)
                values.append(request.form.get(col_name))

            placeholders = ", ".join(["%s"] * len(fields))
            query = f"INSERT INTO {table} ({', '.join(fields)}) VALUES ({placeholders})"

            try:
                cursor.execute(query, values)
                db.commit()
                flash(f"✅ Record added successfully to {table}", "success")
                return redirect(url_for("tables"))
            except MySQLError as err:
                db.rollback()
                # show MySQL error directly
                flash(f"MySQL Error: {str(err)}", "danger")
                return redirect(url_for("insert_record", table=table))

        return render_template("insert.html", table=table, columns=columns)

    except MySQLError as err:
        flash(f"MySQL Connection Error: {str(err)}", "danger")
        return redirect(url_for("tables"))
    finally:
        if db:
            db.close()


# -------------------------------
# UPDATE route with MySQL error handling
# -------------------------------
@app.route("/update/<table>", methods=["GET", "POST"])
def update_record(table):
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    password = session["password"]
    db = None

    try:
        db = get_connection(user, password)
        cursor = db.cursor(dictionary=True)

        # describe table & get PK
        cursor.execute(f"DESCRIBE {table}")
        columns = cursor.fetchall()
        primary_key = columns[0]["Field"]

        selected_record = None
        if "record_id" in request.args:
            record_id = request.args["record_id"]
            cursor.execute(f"SELECT * FROM {table} WHERE {primary_key}=%s", (record_id,))
            selected_record = cursor.fetchone()

        if request.method == "POST":
            record_id = request.form.get("record_id")
            updates, values = [], []

            for col in columns[1:]:
                col_name = col["Field"]
                val = request.form.get(col_name)
                updates.append(f"{col_name}=%s")
                values.append(val)

            values.append(record_id)
            query = f"UPDATE {table} SET {', '.join(updates)} WHERE {primary_key}=%s"

            try:
                cursor.execute(query, values)
                db.commit()
                flash(f"✅ Record updated successfully in {table}", "success")
                return redirect(url_for("tables"))
            except MySQLError as err:
                db.rollback()
                flash(f"MySQL Error: {str(err)}", "danger")
                return redirect(url_for("update_record", table=table, record_id=record_id))

        # Fetch records for dropdown
        cursor.execute(f"SELECT * FROM {table}")
        rows = cursor.fetchall()
        db.close()

        return render_template(
            "update.html",
            table=table,
            columns=columns,
            rows=rows,
            selected_record=selected_record,
            primary_key=primary_key
        )

    except MySQLError as err:
        flash(f"MySQL Connection Error: {str(err)}", "danger")
        return redirect(url_for("tables"))
    finally:
        if db:
            db.close()


# -------------------------------
# DELETE route with MySQL error handling
# -------------------------------
@app.route("/delete/<table>", methods=["GET", "POST"])
def delete_record(table):
    if "user" not in session:
        return redirect(url_for("login"))

    user = session["user"]
    password = session["password"]
    db = None

    try:
        db = get_connection(user, password)
        cursor = db.cursor(dictionary=True)

        cursor.execute(f"DESCRIBE {table}")
        columns = cursor.fetchall()
        primary_key = columns[0]["Field"]

        cursor.execute(f"SELECT * FROM {table}")
        rows = cursor.fetchall()

        if request.method == "POST":
            record_id = request.form.get("record_id")

            try:
                cursor.execute(f"DELETE FROM {table} WHERE {primary_key}=%s", (record_id,))
                db.commit()
                flash(f"🗑️ Record deleted successfully from {table}", "success")
                return redirect(url_for("tables"))
            except MySQLError as err:
                db.rollback()
                flash(f"MySQL Error: {str(err)}", "danger")
                return redirect(url_for("delete_record", table=table))

        return render_template("delete.html", table=table, columns=columns, rows=rows)

    except MySQLError as err:
        flash(f"MySQL Connection Error: {str(err)}", "danger")
        return redirect(url_for("tables"))
    finally:
        if db:
            db.close()

# -------------------------------
# LOGOUT
# -------------------------------
@app.route("/logout")
def logout():
    session.clear()
    flash("Logged out successfully.", "info")
    return redirect(url_for("login"))


if __name__ == "__main__":
    app.run(debug=True)
