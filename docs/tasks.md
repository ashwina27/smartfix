# SmartFix – Implementation Tasks

---

## PHASE 1 – UI Redesign (templates + style.css only)

**Rules:**
- Edit ONLY `templates/*.html` and `static/style.css`
- Do NOT touch `app.py`, `schema.sql`, `sample_data.sql`, `init_db.py`, `requirements.txt`
- Keep every route name, `url_for()` target, form field name, and Jinja2 variable exactly as-is

### Task 1.1 – base.html + style.css
- [ ] Full design-system CSS (colors, typography, spacing, cards, badges, navbar, buttons)
- [ ] Navbar: logo, role-specific links, user name + role badge, logout button
- [ ] Flash message styling (success / danger / warning / info)
- [ ] Status badge classes for every status value

### Task 1.2 – login.html
- [ ] Two-column split: left = brand hero panel, right = login card
- [ ] Role dropdown, email, password fields
- [ ] Link to register

### Task 1.3 – register.html
- [ ] Role toggle shows customer fields (address) or worker fields (experience, services checkboxes)
- [ ] Clean card layout

### Task 1.4 – home.html (customer dashboard)
- [ ] 5 service category tiles with icons, active highlight
- [ ] Worker cards with avatar, reliability badge, 4 stat cells, "Book now" button
- [ ] Reliability criteria footnote

### Task 1.5 – book.html
- [ ] Worker summary header
- [ ] Form: preferred date, address, description
- [ ] Date min = today (client-side)

### Task 1.6 – my_requests.html
- [ ] Table with colored status badges
- [ ] Action buttons: Cancel, Review/Report, Track

### Task 1.7 – worker.html (worker dashboard)
- [ ] Stat cards row (completed, cancelled, avg rating, on-time, reliability)
- [ ] Verification banner for non-Verified workers
- [ ] Request table with Accept/Reject, Start Job, Complete (with cost input)

### Task 1.8 – review.html
- [ ] Star rating widget (visual clickable stars via JS in static/app.js)
- [ ] Comment textarea
- [ ] "Already reviewed" read-only state
- [ ] Complaint form below

### Task 1.9 – admin.html (admin dashboard)
- [ ] Stat cards: total customers, workers, requests, open complaints
- [ ] Worker verification table (Approve / Reject)
- [ ] Services table with Add form and Delete button
- [ ] Complaints table with Resolve button
- [ ] Worker performance summary table

---

## PHASE 2 – Two new app.py features (after Phase 1 confirmed)

### Task 2.1 – Worker profile page
- [ ] Route `GET /worker/<int:wid>` — query `worker_reliability`, services, last 5 reviews
- [ ] Template `templates/worker_profile.html`
- [ ] Add "View Profile" link on worker cards in `home.html`

### Task 2.2 – Admin delete service
- [ ] Route `POST /admin/service/<int:sid>/delete`
- [ ] Catch `ForeignKeyViolation` → friendly flash message
- [ ] Delete button already added in Phase 1 (Task 1.9), wire it up here

---

## PHASE 3 – Documentation (docs/)

### Task 3.1 – docs/ER_diagram.md
- [ ] Mermaid `erDiagram` block using real table/column names from schema.sql

### Task 3.2 – docs/relational_schema.md
- [ ] Every table: columns, types, PK, FK, CHECK constraints

### Task 3.3 – docs/normalization.md
- [ ] 1NF, 2NF, 3NF reasoning per table
- [ ] Note why `review` does not redundantly store worker_id/customer_id

### Task 3.4 – docs/sql_queries.md
- [ ] 15+ queries with purpose, SQL text, concept label

### Task 3.5 – docs/how_app_uses_database.md
- [ ] Route → SQL concept → tables touched, per module

### Task 3.6 – docs/demo_script.md
- [ ] Full live demo walkthrough: register → search → book → accept → start → complete → review → admin reports
