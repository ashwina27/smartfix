-- 1. SELECT + WHERE + ORDER BY: verified AC repair workers
SELECT w.name, w.experience_years FROM worker w
JOIN worker_service ws ON ws.worker_id=w.worker_id
JOIN service s ON s.service_id=ws.service_id
WHERE s.service_name='AC Repair' AND w.verification_status='Verified'
ORDER BY w.experience_years DESC;

-- 2. Aggregates: job cost summary
SELECT COUNT(*) AS jobs, SUM(actual_cost) AS total, AVG(actual_cost) AS average,
       MIN(actual_cost) AS lowest, MAX(actual_cost) AS highest
FROM job WHERE job_status='Completed';

-- 3. GROUP BY + HAVING: workers with more than 2 completed jobs
SELECT w.name, COUNT(*) AS completed_jobs
FROM service_request sr JOIN worker w ON w.worker_id=sr.worker_id
WHERE sr.status='Completed' GROUP BY w.name HAVING COUNT(*) > 2 ORDER BY completed_jobs DESC;

-- 4. JOIN (5 tables): full job details
SELECT j.job_id, c.name AS customer, w.name AS worker, s.service_name, j.actual_cost, r.rating
FROM job j JOIN service_request sr ON sr.request_id=j.request_id
JOIN customer c ON c.customer_id=sr.customer_id
JOIN worker w ON w.worker_id=sr.worker_id
JOIN service s ON s.service_id=sr.service_id
LEFT JOIN review r ON r.job_id=j.job_id;

-- 5. Subquery: workers rated above the overall average
SELECT name, avg_rating FROM worker_summary
WHERE avg_rating > (SELECT AVG(rating) FROM review);

-- 6. Most requested services
SELECT s.service_name, COUNT(sr.request_id) AS requests
FROM service s LEFT JOIN service_request sr ON sr.service_id=s.service_id
GROUP BY s.service_name ORDER BY requests DESC;

-- 7. VIEW usage
SELECT name, completed_jobs, cancelled_jobs, avg_rating, on_time_rate, reliability
FROM worker_reliability ORDER BY completed_jobs DESC;

-- 8. INSERT / UPDATE / DELETE
INSERT INTO service_request(customer_id,worker_id,service_id,preferred_date,address,description)
VALUES (1,1,1,'2026-11-20','12 Gandhi Nagar, Coimbatore','Test request');
UPDATE service_request SET status='Accepted' WHERE description='Test request';
DELETE FROM service_request WHERE description='Test request';
