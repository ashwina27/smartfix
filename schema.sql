-- SmartFix schema (PostgreSQL)
DROP VIEW IF EXISTS worker_reliability, worker_summary;
DROP TABLE IF EXISTS complaint, review, job, service_request, worker_service, service, admin, worker, customer CASCADE;

CREATE TABLE customer (
  customer_id   SERIAL PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  phone         VARCHAR(15)  NOT NULL UNIQUE,
  email         VARCHAR(120) NOT NULL UNIQUE,
  address       TEXT,
  password_hash TEXT NOT NULL DEFAULT ''
);

CREATE TABLE worker (
  worker_id           SERIAL PRIMARY KEY,
  name                VARCHAR(100) NOT NULL,
  phone               VARCHAR(15)  NOT NULL UNIQUE,
  email               VARCHAR(120) NOT NULL UNIQUE,
  experience_years    INT NOT NULL DEFAULT 0 CHECK (experience_years >= 0),
  verification_status VARCHAR(10) NOT NULL DEFAULT 'Pending'
                      CHECK (verification_status IN ('Pending','Verified','Rejected')),
  password_hash       TEXT NOT NULL DEFAULT ''
);

CREATE TABLE admin (
  admin_id      SERIAL PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(120) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL DEFAULT ''
);

CREATE TABLE service (
  service_id   SERIAL PRIMARY KEY,
  service_name VARCHAR(60) NOT NULL UNIQUE,
  description  TEXT
);

CREATE TABLE worker_service (
  worker_id  INT NOT NULL REFERENCES worker(worker_id) ON DELETE CASCADE,
  service_id INT NOT NULL REFERENCES service(service_id) ON DELETE CASCADE,
  PRIMARY KEY (worker_id, service_id)
);

CREATE TABLE service_request (
  request_id     SERIAL PRIMARY KEY,
  customer_id    INT NOT NULL REFERENCES customer(customer_id),
  worker_id      INT NOT NULL REFERENCES worker(worker_id),
  service_id     INT NOT NULL REFERENCES service(service_id),
  request_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  preferred_date DATE NOT NULL,
  address        TEXT NOT NULL,
  description    TEXT,
  status         VARCHAR(12) NOT NULL DEFAULT 'Pending'
                 CHECK (status IN ('Pending','Accepted','Rejected','In Progress','Completed','Cancelled'))
);

CREATE TABLE job (
  job_id          SERIAL PRIMARY KEY,
  request_id      INT NOT NULL UNIQUE REFERENCES service_request(request_id),
  start_time      TIMESTAMP,
  completion_time TIMESTAMP,
  actual_cost     NUMERIC(10,2) CHECK (actual_cost >= 0),
  job_status      VARCHAR(12) NOT NULL DEFAULT 'In Progress'
                  CHECK (job_status IN ('In Progress','Completed')),
  CHECK (completion_time IS NULL OR completion_time >= start_time)
);

CREATE TABLE review (
  review_id   SERIAL PRIMARY KEY,
  job_id      INT NOT NULL UNIQUE REFERENCES job(job_id),
  customer_id INT NOT NULL REFERENCES customer(customer_id),
  worker_id   INT NOT NULL REFERENCES worker(worker_id),
  rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT,
  review_date DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE complaint (
  complaint_id SERIAL PRIMARY KEY,
  customer_id  INT NOT NULL REFERENCES customer(customer_id),
  worker_id    INT NOT NULL REFERENCES worker(worker_id),
  job_id       INT NOT NULL REFERENCES job(job_id),
  description  TEXT NOT NULL,
  status       VARCHAR(10) NOT NULL DEFAULT 'Open' CHECK (status IN ('Open','Resolved')),
  created_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Reliability: transparent summary from job, request and review records
CREATE VIEW worker_summary AS
SELECT w.worker_id, w.name, w.experience_years, w.verification_status,
  (SELECT COUNT(*) FROM service_request sr
     WHERE sr.worker_id = w.worker_id AND sr.status = 'Completed')  AS completed_jobs,
  (SELECT COUNT(*) FROM service_request sr
     WHERE sr.worker_id = w.worker_id AND sr.status = 'Cancelled')  AS cancelled_jobs,
  (SELECT ROUND(AVG(r.rating), 1) FROM review r
     WHERE r.worker_id = w.worker_id)                               AS avg_rating,
  (SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE j.completion_time::date <= sr.preferred_date)
                / NULLIF(COUNT(*), 0), 0)
     FROM job j JOIN service_request sr ON sr.request_id = j.request_id
     WHERE sr.worker_id = w.worker_id AND j.job_status = 'Completed') AS on_time_rate
FROM worker w;

-- Indicator rule: New (<3 completed) | High (avg>=4.5 and on-time>=80) | Medium (avg>=3.5 and on-time>=60) | Low
CREATE VIEW worker_reliability AS
SELECT *,
  CASE WHEN completed_jobs < 3 THEN 'New'
       WHEN COALESCE(avg_rating,0) >= 4.5 AND on_time_rate >= 80 THEN 'High'
       WHEN COALESCE(avg_rating,0) >= 3.5 AND on_time_rate >= 60 THEN 'Medium'
       ELSE 'Low' END AS reliability
FROM worker_summary;
