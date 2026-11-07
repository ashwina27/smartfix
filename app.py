import os
from functools import wraps
import psycopg2, psycopg2.extras
from flask import Flask, render_template, request, redirect, url_for, session, flash
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = "smartfix-dev-secret"

DB = dict(dbname=os.getenv("DB_NAME", "smartfix"), user=os.getenv("DB_USER", "postgres"),
          password=os.getenv("DB_PASSWORD", "postgres"), host=os.getenv("DB_HOST", "localhost"),
          port=os.getenv("DB_PORT", "5432"))


def db(sql, args=(), fetch="all"):
    """Run one parameterized query. fetch: 'all' | 'one' | None"""
    conn = psycopg2.connect(**DB)
    try:
        with conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql, args)
            if fetch == "all":
                return cur.fetchall()
            if fetch == "one":
                return cur.fetchone()
    finally:
        conn.close()


def db_tx(steps):
    """Run several statements in ONE transaction."""
    conn = psycopg2.connect(**DB)
    try:
        with conn, conn.cursor() as cur:
            for sql, args in steps:
                cur.execute(sql, args)
    finally:
        conn.close()


def login_required(role):
    def deco(f):
        @wraps(f)
        def wrapper(*a, **k):
            if session.get("role") != role:
                flash("Please log in first.", "warning")
                return redirect(url_for("login"))
            return f(*a, **k)
        return wrapper
    return deco


# ---------------- Auth ----------------
TABLES = {"customer": ("customer", "customer_id"), "worker": ("worker", "worker_id"),
          "admin": ("admin", "admin_id")}


@app.route("/")
def index():
    return redirect(url_for({"customer": "home", "worker": "worker_dashboard",
                             "admin": "admin_dashboard"}.get(session.get("role"), "login")))


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        role = request.form.get("role")
        if role in TABLES:
            table, idcol = TABLES[role]  # whitelisted names, safe to format
            u = db(f"SELECT {idcol} AS id, name, password_hash FROM {table} WHERE email=%s",
                   (request.form["email"].strip(),), "one")
            if u and check_password_hash(u["password_hash"], request.form["password"]):
                session.clear()
                session.update(role=role, uid=u["id"], name=u["name"])
                return redirect(url_for("index"))
        flash("Invalid email, password or role.", "danger")
    return render_template("login.html")


@app.route("/register", methods=["GET", "POST"])
def register():
    services = db("SELECT * FROM service ORDER BY service_name")
    if request.method == "POST":
        f = request.form
        pw = generate_password_hash(f["password"])
        try:
            if f.get("role") == "worker":
                row = db("INSERT INTO worker(name,phone,email,experience_years,password_hash) "
                         "VALUES(%s,%s,%s,%s,%s) RETURNING worker_id",
                         (f["name"], f["phone"], f["email"], int(f.get("experience_years") or 0), pw), "one")
                for sid in f.getlist("services"):
                    db("INSERT INTO worker_service(worker_id,service_id) VALUES(%s,%s)",
                       (row["worker_id"], sid), None)
                flash("Registered. Your profile will be visible after admin verification.", "success")
            else:
                db("INSERT INTO customer(name,phone,email,address,password_hash) VALUES(%s,%s,%s,%s,%s)",
                   (f["name"], f["phone"], f["email"], f.get("address", ""), pw), None)
                flash("Registered successfully. Please log in.", "success")
            return redirect(url_for("login"))
        except psycopg2.errors.UniqueViolation:
            flash("That email or phone is already registered.", "danger")
    return render_template("register.html", services=services)


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


# ---------------- Customer ----------------
@app.route("/home")
@login_required("customer")
def home():
    services = db("SELECT * FROM service ORDER BY service_name")
    sel = request.args.get("service_id", type=int)
    workers, sel_name = [], None
    if sel:
        sel_name = (db("SELECT service_name FROM service WHERE service_id=%s", (sel,), "one") or {}).get("service_name")
        workers = db("""SELECT r.* FROM worker_reliability r
                        JOIN worker_service ws ON ws.worker_id = r.worker_id
                        WHERE ws.service_id=%s AND r.verification_status='Verified'
                        ORDER BY r.avg_rating DESC NULLS LAST, r.completed_jobs DESC""", (sel,))
    return render_template("home.html", services=services, sel=sel, sel_name=sel_name, workers=workers)


@app.route("/book/<int:worker_id>/<int:service_id>", methods=["GET", "POST"])
@login_required("customer")
def book(worker_id, service_id):
    w = db("""SELECT w.worker_id, w.name, s.service_id, s.service_name FROM worker w
              JOIN worker_service ws ON ws.worker_id=w.worker_id
              JOIN service s ON s.service_id=ws.service_id
              WHERE w.worker_id=%s AND s.service_id=%s AND w.verification_status='Verified'""",
           (worker_id, service_id), "one")
    if not w:
        flash("Worker not available for that service.", "danger")
        return redirect(url_for("home"))
    cust = db("SELECT address FROM customer WHERE customer_id=%s", (session["uid"],), "one")
    if request.method == "POST":
        f = request.form
        db("""INSERT INTO service_request(customer_id,worker_id,service_id,preferred_date,address,description)
              VALUES(%s,%s,%s,%s,%s,%s)""",
           (session["uid"], worker_id, service_id, f["preferred_date"], f["address"], f["description"]), None)
        flash("Request sent. The worker will accept or reject it.", "success")
        return redirect(url_for("my_requests"))
    return render_template("book.html", w=w, cust=cust)


@app.route("/my-requests")
@login_required("customer")
def my_requests():
    rows = db("""SELECT sr.*, s.service_name, w.name AS worker_name, j.job_id, j.actual_cost, rv.review_id
                 FROM service_request sr
                 JOIN service s ON s.service_id = sr.service_id
                 JOIN worker w ON w.worker_id = sr.worker_id
                 LEFT JOIN job j ON j.request_id = sr.request_id
                 LEFT JOIN review rv ON rv.job_id = j.job_id
                 WHERE sr.customer_id=%s ORDER BY sr.request_id DESC""", (session["uid"],))
    return render_template("my_requests.html", rows=rows)


@app.route("/cancel/<int:rid>", methods=["POST"])
@login_required("customer")
def cancel(rid):
    db("""UPDATE service_request SET status='Cancelled'
          WHERE request_id=%s AND customer_id=%s AND status IN ('Pending','Accepted')""",
       (rid, session["uid"]), None)
    flash("Request cancelled.", "info")
    return redirect(url_for("my_requests"))


def _own_completed_job(job_id):
    return db("""SELECT j.job_id, sr.worker_id, w.name AS worker_name,
                        (SELECT COUNT(*) FROM review WHERE job_id=j.job_id) AS reviewed
                 FROM job j JOIN service_request sr ON sr.request_id=j.request_id
                 JOIN worker w ON w.worker_id=sr.worker_id
                 WHERE j.job_id=%s AND sr.customer_id=%s AND j.job_status='Completed'""",
              (job_id, session["uid"]), "one")


@app.route("/review/<int:job_id>", methods=["GET", "POST"])
@login_required("customer")
def review_page(job_id):
    job = _own_completed_job(job_id)
    if not job:
        flash("Job not found.", "danger")
        return redirect(url_for("my_requests"))
    if request.method == "POST" and not job["reviewed"]:
        db("INSERT INTO review(job_id,customer_id,worker_id,rating,comment) VALUES(%s,%s,%s,%s,%s)",
           (job_id, session["uid"], job["worker_id"], int(request.form["rating"]), request.form["comment"]), None)
        flash("Thanks for your review!", "success")
        return redirect(url_for("my_requests"))
    return render_template("review.html", job=job)


@app.route("/complaint/<int:job_id>", methods=["POST"])
@login_required("customer")
def complaint(job_id):
    job = _own_completed_job(job_id)
    if job:
        db("INSERT INTO complaint(customer_id,worker_id,job_id,description) VALUES(%s,%s,%s,%s)",
           (session["uid"], job["worker_id"], job_id, request.form["description"]), None)
        flash("Complaint submitted to the admin.", "success")
    return redirect(url_for("my_requests"))


# ---------------- Worker ----------------
@app.route("/worker")
@login_required("worker")
def worker_dashboard():
    summary = db("SELECT * FROM worker_reliability WHERE worker_id=%s", (session["uid"],), "one")
    rows = db("""SELECT sr.*, s.service_name, c.name AS customer_name, c.phone AS customer_phone, j.job_id
                 FROM service_request sr
                 JOIN service s ON s.service_id = sr.service_id
                 JOIN customer c ON c.customer_id = sr.customer_id
                 LEFT JOIN job j ON j.request_id = sr.request_id
                 WHERE sr.worker_id=%s
                 ORDER BY CASE sr.status WHEN 'Pending' THEN 0 WHEN 'Accepted' THEN 1
                          WHEN 'In Progress' THEN 2 ELSE 3 END, sr.request_id DESC""", (session["uid"],))
    return render_template("worker.html", summary=summary, rows=rows)


@app.route("/worker/action/<int:rid>/<action>", methods=["POST"])
@login_required("worker")
def worker_action(rid, action):
    wid = session["uid"]
    if action in ("accept", "reject"):
        new = "Accepted" if action == "accept" else "Rejected"
        db("UPDATE service_request SET status=%s WHERE request_id=%s AND worker_id=%s AND status='Pending'",
           (new, rid, wid), None)
    elif action == "start":
        db_tx([
            ("UPDATE service_request SET status='In Progress' "
             "WHERE request_id=%s AND worker_id=%s AND status='Accepted'", (rid, wid)),
            ("""INSERT INTO job(request_id,start_time,job_status)
                SELECT request_id, NOW(), 'In Progress' FROM service_request
                WHERE request_id=%s AND worker_id=%s AND status='In Progress'
                  AND NOT EXISTS (SELECT 1 FROM job WHERE request_id=%s)""", (rid, wid, rid)),
        ])
    elif action == "complete":
        cost = float(request.form.get("cost") or 0)
        db_tx([
            ("""UPDATE job SET job_status='Completed', completion_time=NOW(), actual_cost=%s
                WHERE request_id=%s AND job_status='In Progress'
                  AND request_id IN (SELECT request_id FROM service_request WHERE worker_id=%s)""",
             (cost, rid, wid)),
            ("UPDATE service_request SET status='Completed' "
             "WHERE request_id=%s AND worker_id=%s AND status='In Progress'", (rid, wid)),
        ])
    flash("Status updated.", "success")
    return redirect(url_for("worker_dashboard"))


# ---------------- Admin ----------------
@app.route("/admin")
@login_required("admin")
def admin_dashboard():
    data = dict(
        pending=db("SELECT * FROM worker WHERE verification_status='Pending' ORDER BY worker_id"),
        status_counts=db("SELECT status, COUNT(*) AS n FROM service_request GROUP BY status ORDER BY n DESC"),
        demand=db("""SELECT s.service_name, COUNT(sr.request_id) AS n FROM service s
                     LEFT JOIN service_request sr ON sr.service_id=s.service_id
                     GROUP BY s.service_name ORDER BY n DESC"""),
        workers=db("SELECT * FROM worker_reliability ORDER BY completed_jobs DESC, name"),
        top=db("SELECT name, avg_rating FROM worker_summary "
               "WHERE avg_rating > (SELECT AVG(rating) FROM review) ORDER BY avg_rating DESC"),
        by_service=db("""SELECT s.service_name, COUNT(*) AS n FROM worker_service ws
                         JOIN service s ON s.service_id=ws.service_id
                         JOIN worker w ON w.worker_id=ws.worker_id
                         WHERE w.verification_status='Verified' GROUP BY s.service_name ORDER BY s.service_name"""),
        complaints=db("""SELECT c.*, cu.name AS customer, w.name AS worker FROM complaint c
                         JOIN customer cu ON cu.customer_id=c.customer_id
                         JOIN worker w ON w.worker_id=c.worker_id ORDER BY c.status DESC, c.complaint_id DESC"""),
    )
    return render_template("admin.html", **data)


@app.route("/admin/verify/<int:wid>/<decision>", methods=["POST"])
@login_required("admin")
def admin_verify(wid, decision):
    if decision in ("Verified", "Rejected"):
        db("UPDATE worker SET verification_status=%s WHERE worker_id=%s", (decision, wid), None)
        flash(f"Worker {decision.lower()}.", "success")
    return redirect(url_for("admin_dashboard"))


@app.route("/admin/complaint/<int:cid>/resolve", methods=["POST"])
@login_required("admin")
def admin_resolve(cid):
    db("UPDATE complaint SET status='Resolved' WHERE complaint_id=%s", (cid,), None)
    flash("Complaint marked resolved.", "success")
    return redirect(url_for("admin_dashboard"))


@app.route("/admin/service", methods=["POST"])
@login_required("admin")
def admin_add_service():
    try:
        db("INSERT INTO service(service_name,description) VALUES(%s,%s)",
           (request.form["service_name"].strip(), request.form.get("description", "")), None)
        flash("Service category added.", "success")
    except psycopg2.errors.UniqueViolation:
        flash("That service already exists.", "danger")
    return redirect(url_for("admin_dashboard"))


if __name__ == "__main__":
    app.run(debug=True)
