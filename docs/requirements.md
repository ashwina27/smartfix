# SmartFix – Requirements

**Project:** SmartFix — Smart Service Provider Management System
**Type:** College Database Systems (DBS) demonstration project
**Stack:** Python 3, Flask, psycopg2 (raw SQL), PostgreSQL, Jinja2, Bootstrap 5, plain CSS

---

## 1. Stakeholders and Roles

| Role | Description |
|------|-------------|
| **Customer** | Searches for services, books workers, tracks jobs, reviews completed work, files complaints |
| **Worker** | Receives booking requests, accepts/rejects, starts and completes jobs |
| **Admin** | Verifies workers, manages services, resolves complaints, views system reports |

---

## 2. Functional Requirements

### 2.1 Authentication and Registration (FR-AUTH)

| ID | Requirement |
|----|-------------|
| FR-AUTH-1 | Login page accepts email, password, and role (customer / worker / admin). |
| FR-AUTH-2 | Passwords are stored using Werkzeug `generate_password_hash` / `check_password_hash`. A code comment notes that plain storage must NOT be used in production. |
| FR-AUTH-3 | Session-based login: Flask session stores `role`, `uid`, `name`. `secret_key` must be set. |
| FR-AUTH-4 | Role-specific redirect after login: customer → `/home`, worker → `/worker`, admin → `/admin`. |
| FR-AUTH-5 | Customers register with: name, phone, email, password, address. |
| FR-AUTH-6 | Workers register with: name, phone, email, password, experience_years, services offered (checkboxes). New workers start as `verification_status = 'Pending'`. |
| FR-AUTH-7 | Duplicate email or phone returns a friendly flash message (catch `UniqueViolation`). |
| FR-AUTH-8 | `/logout` clears session and redirects to login. |
| FR-AUTH-9 | Route decorators (`login_required(role)`) protect all role-specific pages. |

### 2.2 Service Discovery — Customer (FR-DISC)

| ID | Requirement |
|----|-------------|
| FR-DISC-1 | Customer dashboard (`/home`) shows a greeting, 5 service category tiles, and a "My Requests" link. |
| FR-DISC-2 | Clicking a service tile queries `/workers?service_id=<id>` (or inline on the same page) and returns only `Verified` workers who offer that service via `JOIN worker, worker_service, service, worker_reliability`. |
| FR-DISC-3 | Each worker card shows: name, experience, completed jobs, cancelled jobs, avg rating (star display), on-time %, reliability badge. |
| FR-DISC-4 | Reliability formula (documented as a code comment): **High** = avg_rating ≥ 4.5 AND on_time_rate ≥ 80%; **Medium** = avg_rating ≥ 3.5 AND on_time_rate ≥ 60%; **Low** = otherwise; **New** = completed_jobs < 3. |
| FR-DISC-5 | The reliability criteria are shown as a footnote on the page (transparent, not a hidden score). |
| FR-DISC-6 | Optional sort by rating / experience / completed jobs. |

### 2.3 Service Booking — Customer (FR-BOOK)

| ID | Requirement |
|----|-------------|
| FR-BOOK-1 | `/book/<worker_id>/<service_id>` shows a booking form with: service (locked to this worker's service), preferred date (must not be in the past), address (pre-filled from customer profile), description. |
| FR-BOOK-2 | Submitting the form does `INSERT INTO service_request` with status `'Pending'`. |
| FR-BOOK-3 | Customer can cancel a Pending (or Accepted) request from `/my-requests`; sets status `'Cancelled'`. |
| FR-BOOK-4 | `/my-requests` lists all of the customer's requests with: id, service, worker, preferred date, status badge, cost, and action buttons. |

### 2.4 Worker Module (FR-WORK)

| ID | Requirement |
|----|-------------|
| FR-WORK-1 | Worker dashboard (`/worker`) shows stat cards: pending requests, active jobs, completed jobs, avg rating. |
| FR-WORK-2 | Unverified (`Pending`/`Rejected`) workers see a verification banner and do not appear in customer search. |
| FR-WORK-3 | Worker can **Accept** a Pending request → sets `status = 'Accepted'`. |
| FR-WORK-4 | Worker can **Reject** a Pending request → sets `status = 'Rejected'`. |
| FR-WORK-5 | Worker can **Start Job** on an Accepted request → `INSERT INTO job` with `start_time = NOW()`, `job_status = 'In Progress'`; set `service_request.status = 'In Progress'`. These happen in one transaction. |
| FR-WORK-6 | Worker can **Mark Completed** on an In Progress job → a modal prompts for `actual_cost`; `UPDATE job` with `completion_time = NOW()`, `job_status = 'Completed'`, `actual_cost`; `UPDATE service_request.status = 'Completed'`. One transaction. |
| FR-WORK-7 | Invalid state transitions must be rejected with a flash message. |

### 2.5 Job Tracking (FR-TRACK)

| ID | Requirement |
|----|-------------|
| FR-TRACK-1 | `/request/<id>` shows a step progress bar: Pending → Accepted → In Progress → Completed with the current step highlighted. |
| FR-TRACK-2 | The page shows: worker, service, dates, address, description, start time, completion time, actual cost. |
| FR-TRACK-3 | "In Progress" is derived from the presence of a `job` row with `job_status = 'In Progress'`. |

### 2.6 Ratings and Reviews (FR-REVIEW)

| ID | Requirement |
|----|-------------|
| FR-REVIEW-1 | `/review/<job_id>` is only accessible by the customer who owns the job. |
| FR-REVIEW-2 | Reviews are only allowed on `Completed` jobs. |
| FR-REVIEW-3 | Each job can only be reviewed once (enforced by `UNIQUE(job_id)` in the `review` table and caught in code). |
| FR-REVIEW-4 | Review form: star rating 1–5 and text comment. `INSERT INTO review`. |
| FR-REVIEW-5 | Constraint violations (duplicate, out-of-range rating) return a friendly flash message. |

### 2.7 Complaint Management (FR-COMP)

| ID | Requirement |
|----|-------------|
| FR-COMP-1 | Customer can submit a complaint for a completed job from the review page. `INSERT INTO complaint`. |
| FR-COMP-2 | Admin views all complaints with customer, worker, description, date, status. |
| FR-COMP-3 | Admin can mark a complaint Resolved: `UPDATE complaint SET status='Resolved'`. |

### 2.8 Admin Module (FR-ADMIN)

| ID | Requirement |
|----|-------------|
| FR-ADMIN-1 | Dashboard (`/admin`) shows stat cards: total customers, workers, requests, open complaints using `COUNT`. |
| FR-ADMIN-2 | Worker verification table: list of `Pending` workers with Approve / Reject buttons → `UPDATE worker SET verification_status`. |
| FR-ADMIN-3 | Service management: list all services, add new service (`INSERT`), delete service (`DELETE` with FK-safe error). |
| FR-ADMIN-4 | Complaints tab with "Mark Resolved" action. |
| FR-ADMIN-5 | Worker performance summary table sourced from `worker_reliability` view. |

### 2.9 Admin Reports (FR-REPORT)

Ten named reports at `/admin/reports`. Each shows the raw SQL in a collapsible "View SQL" block labelled with the concept:

| # | Report | SQL Concept |
|---|--------|-------------|
| a | Verified workers by service category | JOIN |
| b | Completed jobs per worker | COUNT, GROUP BY |
| c | Average rating per worker, high to low | AVG, ORDER BY |
| d | Workers with > 1 completed job | GROUP BY + HAVING |
| e | Workers rated above the overall average | Subquery |
| f | Most requested service categories | COUNT, GROUP BY, ORDER BY + Bar chart (Chart.js) |
| g | Requests by status distribution | GROUP BY + Donut chart (Chart.js) |
| h | Worker cancellation and on-time summary | VIEW (`worker_reliability`) |
| i | Complaint status report | — |
| j | Revenue summary per service | SUM, MIN, MAX, AVG |

---

## 3. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-1 | All DB queries use parameterized statements (`%s`). No string interpolation in SQL. |
| NFR-2 | Every DB call wrapped in `try/except psycopg2.Error`; friendly flash messages, no raw exceptions shown to users. |
| NFR-3 | DB credentials in one place at the top of `db.py` (or `app.py`). Configurable via environment variables. |
| NFR-4 | Every SQL query has a comment naming the DBS concept it demonstrates. |
| NFR-5 | Pages are responsive (Bootstrap 5 grid). |
| NFR-6 | Flash messages use Bootstrap alert classes (`success`, `danger`, `warning`, `info`). |
| NFR-7 | Status badges are styled as pills with role-appropriate colors (per the design system). |
| NFR-8 | The app must start with `python app.py` and be demonstrable at `http://127.0.0.1:5000`. |
| NFR-9 | A `README.md` documents setup steps and all demo account credentials. |

---

## 4. Database Constraints (enforced in schema)

- `service_request.status` CHECK IN (`'Pending'`, `'Accepted'`, `'Rejected'`, `'In Progress'`, `'Completed'`, `'Cancelled'`)
- `job.job_status` CHECK IN (`'In Progress'`, `'Completed'`)
- `review.rating` CHECK BETWEEN 1 AND 5
- `job.completion_time >= start_time` (if both set)
- `worker.verification_status` CHECK IN (`'Pending'`, `'Verified'`, `'Rejected'`)
- `complaint.status` CHECK IN (`'Open'`, `'Resolved'`)

Valid state transitions enforced in application logic:
- `Pending` → `Accepted` | `Rejected` | `Cancelled`
- `Accepted` → (Start Job) `In Progress`
- `In Progress` → (Complete Job) `Completed`

---

## 5. Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Customer | priya@example.com | password123 |
| Customer | anand@example.com | password123 |
| Worker (Verified) | arun@example.com | password123 |
| Worker (Pending) | dinesh@example.com | password123 |
| Admin | admin@smartfix.com | password123 |

---

## 6. Documentation Deliverables (in `/docs`)

1. `ER_diagram.md` — Mermaid ER diagram
2. `relational_schema.md` — All tables with columns, PK, FK, constraints
3. `normalization.md` — 1NF, 2NF, 3NF reasoning
4. `sql_queries.md` — Key queries with purpose and concept
5. `how_app_uses_database.md` — Route-to-SQL mapping per module
6. `demo_script.md` — Step-by-step live demo walkthrough
