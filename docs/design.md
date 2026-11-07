# SmartFix – Design Document

---

## 1. Architecture Overview

```
Browser
  │  HTTP (HTML forms, links)
  ▼
Flask app (app.py)
  │  psycopg2 (raw SQL, parameterized)
  ▼
PostgreSQL – database "smartfix"
```

No ORM. No JavaScript framework. No build step. One Python file (`app.py`) contains all routes. Templates are Jinja2 HTML files. CSS is in `static/style.css`. Minimal vanilla JS is used only for the star-rating widget and the complete-job cost modal.

---

## 2. Database Design

### 2.1 Entity-Relationship Summary

```
CUSTOMER  1 ──< SERVICE_REQUEST >── 1  WORKER
                      │
                      1
                      │
                     JOB  1 ──── 0..1  REVIEW
                      │
                      1
                      │
                   COMPLAINT (many per job, FK to customer + worker)

WORKER  >──── WORKER_SERVICE ────<  SERVICE
              (composite PK)
```

### 2.2 Tables

| Table | Key Columns | Notes |
|-------|-------------|-------|
| `customer` | `customer_id (PK)`, name, phone (UQ), email (UQ), address, password_hash | |
| `worker` | `worker_id (PK)`, name, phone (UQ), email (UQ), experience_years, verification_status, password_hash | verification_status DEFAULT 'Pending' |
| `admin` | `admin_id (PK)`, name, email (UQ), password_hash | |
| `service` | `service_id (PK)`, service_name (UQ), description | |
| `worker_service` | `(worker_id, service_id) PK`, FK to worker + service | Many-to-many bridge |
| `service_request` | `request_id (PK)`, customer_id (FK), worker_id (FK), service_id (FK), request_date, preferred_date, address, description, status | status CHECK |
| `job` | `job_id (PK)`, request_id (FK UNIQUE), start_time, completion_time, actual_cost, job_status | completion_time ≥ start_time CHECK |
| `review` | `review_id (PK)`, job_id (FK UNIQUE), customer_id (FK), worker_id (FK), rating (1-5), comment, review_date | UNIQUE(job_id) enforces one review per job |
| `complaint` | `complaint_id (PK)`, customer_id (FK), worker_id (FK), job_id (FK), description, status, created_date | status CHECK |

### 2.3 Views

**`worker_summary`** — Aggregates per worker: `completed_jobs`, `cancelled_jobs`, `avg_rating`, `on_time_rate` (% of completed jobs finished on or before `preferred_date`). Uses correlated subqueries.

**`worker_reliability`** — Extends `worker_summary` with a CASE-derived `reliability` column:
- `New` → completed_jobs < 3
- `High` → avg_rating ≥ 4.5 AND on_time_rate ≥ 80
- `Medium` → avg_rating ≥ 3.5 AND on_time_rate ≥ 60
- `Low` → otherwise

---

## 3. Application Structure

```
smartfix/
├── app.py                  # All Flask routes
├── db.py                   # (to create) DB connection + helper
├── init_db.py              # DB setup script
├── schema.sql              # Table and view definitions
├── sample_data.sql         # Seed data with hashed passwords
├── requirements.txt
├── README.md
├── static/
│   ├── style.css           # All custom styles
│   └── app.js              # Star-rating widget, cost modal
└── templates/
    ├── base.html           # Navbar, flash messages, layout shell
    ├── login.html
    ├── register.html
    ├── home.html           # Customer dashboard + worker search
    ├── my_requests.html    # Customer request list
    ├── book.html           # Booking form
    ├── worker.html         # Worker dashboard
    ├── admin.html          # Admin dashboard
    └── admin_reports.html  # Admin reports with charts
```

Missing templates to create:
- `request_status.html` — Job tracking stepper
- `worker_profile.html` — Public worker profile

---

## 4. Route Map

### Auth
| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET/POST | `/login` | `login()` | Login form |
| GET/POST | `/register` | `register()` | Registration form |
| GET | `/logout` | `logout()` | Clear session |
| GET | `/` | `index()` | Role-aware redirect |

### Customer
| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET | `/home` | `home()` | Dashboard + service tile + worker search |
| GET | `/my-requests` | `my_requests()` | All customer requests |
| GET/POST | `/book/<worker_id>/<service_id>` | `book()` | Booking form |
| POST | `/cancel/<rid>` | `cancel()` | Cancel a Pending/Accepted request |
| GET/POST | `/review/<job_id>` | `review_page()` | Leave review and/or complaint |
| POST | `/complaint/<job_id>` | `complaint()` | Submit complaint |
| GET | `/request/<id>` | `request_status()` | Job tracking stepper *(to add)* |

### Worker
| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET | `/worker` | `worker_dashboard()` | Worker dashboard |
| POST | `/worker/action/<rid>/<action>` | `worker_action()` | accept/reject/start/complete |

### Admin
| Method | Route | Handler | Description |
|--------|-------|---------|-------------|
| GET | `/admin` | `admin_dashboard()` | Admin dashboard |
| POST | `/admin/verify/<wid>/<decision>` | `admin_verify()` | Approve/Reject worker |
| POST | `/admin/complaint/<cid>/resolve` | `admin_resolve()` | Resolve complaint |
| POST | `/admin/service` | `admin_add_service()` | Add service category |
| POST | `/admin/service/<sid>/delete` | `admin_delete_service()` | Delete service *(to add)* |
| GET | `/admin/reports` | `admin_reports()` | Full reports page *(to add)* |
| POST | `/admin/delete-request/<rid>` | `admin_delete_request()` | Delete test request *(to add)* |

---

## 5. UI Design System

| Token | Value |
|-------|-------|
| Primary | `#4f46e5` (Indigo) |
| Secondary / sky | `#0ea5e9` |
| Star / accent | `#F59E0B` |
| Success | `#16A34A` |
| Danger | `#DC2626` |
| Background | `#f1f5f9` |
| Card radius | 16px |
| Card shadow | `0 4px 18px rgba(15,23,42,.06)` |
| Font | Inter (Google Fonts) — already loaded |

### Status Badge Colors
| Status | Color |
|--------|-------|
| Pending | Amber / warning |
| Accepted | Blue / info |
| In Progress | Purple |
| Completed | Green / success |
| Rejected | Red / danger |
| Cancelled | Red / danger |
| Verified | Green |
| Open | Amber |
| Resolved | Green |

### Components to build / improve
- **Stat cards** — white card with large number, label beneath, subtle icon (worker + admin dashboards)
- **Status stepper** — horizontal progress bar for job tracking
- **Star rating widget** — 5 clickable stars (vanilla JS, hidden `<input type="hidden">`)
- **Cost modal** — Bootstrap modal triggered by "Mark Completed" button
- **Collapsible SQL box** — `<details><summary>View SQL</summary><pre>…</pre></details>`
- **Charts** — Chart.js (CDN) bar chart and donut chart on admin reports page

---

## 6. Session and Auth Flow

```
POST /login
  → verify email+password against whitelisted table
  → session: { role, uid, name }
  → redirect based on role

login_required(role) decorator
  → checks session.role == expected role
  → if not: flash + redirect to /login
```

Whitelisted table names (`customer`, `worker`, `admin`) prevent SQL injection even in the one place where a table name is used in a format string.

---

## 7. Transaction Strategy

Two DB helpers in `app.py`:
- `db(sql, args, fetch)` — single statement, auto-commit via context manager
- `db_tx(steps)` — list of `(sql, args)` tuples run in one transaction

Multi-step state transitions (start job, complete job) use `db_tx` to prevent partial updates.

---

## 8. Error Handling Strategy

| Error | Handling |
|-------|----------|
| `psycopg2.errors.UniqueViolation` | Flash "already registered" or "already reviewed" |
| `psycopg2.errors.ForeignKeyViolation` | Flash "cannot delete, records exist" |
| `psycopg2.errors.CheckViolation` | Flash "invalid value" |
| `psycopg2.Error` (catch-all) | Flash generic error, log to console |
| Invalid state transition | Detected in Python before DB call; flash message |
| Unauthorized access | `login_required` decorator redirects to `/login` |

---

## 9. Missing Pieces (gap analysis vs spec)

The following are in the spec but not yet fully implemented:

| Gap | Where | Priority |
|-----|-------|----------|
| `db.py` helper module | Spec asks for `db.py` | Medium (currently inlined in `app.py`) |
| `/request/<id>` stepper page | `request_status.html` + route | High |
| `/worker/<id>` public profile page | `worker_profile.html` + route | High |
| `/admin/reports` full page | `admin_reports.html` + route | High |
| Admin stat cards (customer/worker/request/complaint counts) | `admin_dashboard()` query + template | High |
| Admin delete service route | `admin_delete_service()` | Medium |
| Admin delete test request route | `admin_delete_request()` | Low |
| Chart.js bar + donut on reports page | Template JS | High |
| Star rating widget (visual) | `app.js` + `review.html` | Medium |
| Cost modal (Bootstrap) | `app.js` + `worker.html` | Medium |
| Status badge color-coding (per design system) | `style.css` | Medium |
| Navbar role-specific links | `base.html` | Low |
| All 6 `docs/` documentation files | `/docs` | Medium |
| `requirements.txt` with pinned versions | Root | Low |
| `seed.sql` renamed from `sample_data.sql` (spec says seed.sql) | Root | Low |
