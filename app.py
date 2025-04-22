from flask import Flask, render_template, request
from db_config import get_connection

app = Flask(__name__)

@app.route('/')
def home():
    return render_template("index.html")

# --- Procedures ---
@app.route('/add_airplane', methods=['GET', 'POST'])
def add_airplane():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('add_airplane', [
                request.form['airline_id'],
                request.form['tail_num'],
                int(request.form['seat_capacity']),
                int(request.form['speed']),
                request.form['location_id'],
                request.form['plane_type'],
                request.form['maintenanced'].lower() == 'true',
                int(request.form['model']) if request.form['model'] else None,
                int(request.form['neo']) if request.form['neo'] else None
            ])
            conn.commit()
            return "Airplane added successfully"
        except Exception as e:
            return str(e)
    return render_template("add_airplane.html")

@app.route('/add_airport', methods=['GET', 'POST'])
def add_airport():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('add_airport', [
                request.form['airport_id'],
                request.form['airport_name'],
                request.form['city'],
                request.form['state'],
                request.form['country'],
                request.form['location_id']
            ])
            conn.commit()
            return "Airport added successfully"
        except Exception as e:
            return str(e)
    return render_template("add_airport.html")

@app.route('/add_person', methods=['GET', 'POST'])
def add_person():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('add_person', [
                request.form['person_id'],
                request.form['first_name'],
                request.form['last_name'] if request.form['last_name'] else None,
                request.form['location_id'],
                request.form['tax_id'] if request.form['tax_id'] else None,
                int(request.form['experience']) if request.form['experience'] else None,
                int(request.form['miles']) if request.form['miles'] else None,
                int(request.form['funds']) if request.form['funds'] else None
            ])
            conn.commit()
            return "Person added successfully"
        except Exception as e:
            return str(e)
    return render_template("add_person.html")

@app.route('/grant_or_revoke_pilot_license', methods=['GET', 'POST'])
def grant_or_revoke_pilot_license():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('grant_or_revoke_pilot_license', [
                request.form['person_id'],
                request.form['license']
            ])
            conn.commit()
            return "Pilot license updated"
        except Exception as e:
            return str(e)
    return render_template("grant_or_revoke_pilot_license.html")

@app.route('/offer_flight', methods=['GET', 'POST'])
def offer_flight():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('offer_flight', [
                request.form['flight_id'],
                request.form['route_id'],
                request.form['support_airline'],
                request.form['support_tail'],
                int(request.form['progress']),
                request.form['next_time'],
                int(request.form['cost'])
            ])
            conn.commit()
            return "Flight offered successfully"
        except Exception as e:
            return str(e)
    return render_template("offer_flight.html")

@app.route('/flight_landing', methods=['GET', 'POST'])
def flight_landing():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('flight_landing', [request.form['flight_id']])
            conn.commit()
            return "Flight landed"
        except Exception as e:
            return str(e)
    return render_template("flight_landing.html")

@app.route('/flight_takeoff', methods=['GET', 'POST'])
def flight_takeoff():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('flight_takeoff', [request.form['flight_id']])
            conn.commit()
            return "Flight took off"
        except Exception as e:
            return str(e)
    return render_template("flight_takeoff.html")

@app.route('/passengers_board', methods=['GET', 'POST'])
def passengers_board():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('passengers_board', [request.form['flight_id']])
            conn.commit()
            return "Passengers boarded"
        except Exception as e:
            return str(e)
    return render_template("passengers_board.html")

@app.route('/passengers_disembark', methods=['GET', 'POST'])
def passengers_disembark():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('passengers_disembark', [request.form['flight_id']])
            conn.commit()
            return "Passengers disembarked"
        except Exception as e:
            return str(e)
    return render_template("passengers_disembark.html")

@app.route('/assign_pilot', methods=['GET', 'POST'])
def assign_pilot():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('assign_pilot', [
                request.form['flight_id'],
                request.form['person_id']
            ])
            conn.commit()
            return "Pilot assigned"
        except Exception as e:
            return str(e)
    return render_template("assign_pilot.html")

@app.route('/recycle_crew', methods=['GET', 'POST'])
def recycle_crew():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('recycle_crew', [request.form['flight_id']])
            conn.commit()
            return "Crew recycled"
        except Exception as e:
            return str(e)
    return render_template("recycle_crew.html")

@app.route('/retire_flight', methods=['GET', 'POST'])
def retire_flight():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('retire_flight', [request.form['flight_id']])
            conn.commit()
            return "Flight retired"
        except Exception as e:
            return str(e)
    return render_template("retire_flight.html")

@app.route('/simulation_cycle', methods=['GET', 'POST'])
def simulation_cycle():
    if request.method == 'POST':
        try:
            conn = get_connection()
            cursor = conn.cursor()
            cursor.callproc('simulation_cycle')
            conn.commit()
            return "Simulation step advanced"
        except Exception as e:
            return str(e)
    return render_template("simulation_cycle.html")

# --- Views ---
@app.route('/flights_in_air')
def flights_in_air():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM flights_in_the_air")
        results = cursor.fetchall()
        return render_template("flights_in_air.html", results=results)
    except Exception as e:
        return str(e)

@app.route('/flights_on_ground')
def flights_on_ground():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM flights_on_the_ground")
        results = cursor.fetchall()
        return render_template("flights_on_ground.html", results=results)
    except Exception as e:
        return str(e)

@app.route('/people_in_air')
def people_in_air():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM people_in_the_air")
        results = cursor.fetchall()
        return render_template("people_in_air.html", results=results)
    except Exception as e:
        return str(e)

@app.route('/people_on_ground')
def people_on_ground():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM people_on_the_ground")
        results = cursor.fetchall()
        return render_template("people_on_ground.html", results=results)
    except Exception as e:
        return str(e)

@app.route('/route_summary')
def route_summary():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM route_summary")
        results = cursor.fetchall()
        return render_template("route_summary.html", results=results)
    except Exception as e:
        return str(e)

@app.route('/alternative_airports')
def alternative_airports():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM alternative_airports")
        results = cursor.fetchall()
        return render_template("alternative_airports.html", results=results)
    except Exception as e:
        return str(e)

# ======================= show tables ===========================
@app.route('/table/flight')
def show_flight_table():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM flight")
        rows = cursor.fetchall()
        conn.close()
        return render_template("table_view.html", table='Flight', rows=rows)
    except Exception as e:
        return str(e)

@app.route('/table/airplane')
def show_airplane_table():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM airplane")
        rows = cursor.fetchall()
        conn.close()
        return render_template("table_view.html", table='airplane', rows=rows)
    except Exception as e:
        return str(e)

@app.route('/table/airport')
def show_airport_table():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM airport")
        rows = cursor.fetchall()
        conn.close()
        return render_template("table_view.html", table='airport', rows=rows)
    except Exception as e:
        return str(e)

@app.route('/table/person')
def show_person_table():
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM person")
        rows = cursor.fetchall()
        conn.close()
        return render_template("table_view.html", table='person', rows=rows)
    except Exception as e:
        return str(e)

if __name__ == '__main__':
    app.run(debug=True)
