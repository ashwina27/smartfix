INSERT INTO admin(name,email) VALUES ('SmartFix Admin','admin@smartfix.com');

INSERT INTO service(service_name,description) VALUES
 ('AC Repair','AC servicing, gas refill, installation'),
 ('Electrical Work','Wiring, fans, switches, inverter issues'),
 ('Plumbing','Leaks, pipe fitting, bathroom fixtures'),
 ('Carpentry','Furniture repair, doors, wardrobes'),
 ('Appliance Repair','Washing machine, fridge, microwave repair');

INSERT INTO customer(name,phone,email,address) VALUES
 ('Priya Raman','9840011101','priya@example.com','12 Gandhi Nagar, Coimbatore'),
 ('Anand Kumar','9840011102','anand@example.com','45 Nehru Street, Singanallur, Coimbatore'),
 ('Meena Sundaram','9840011103','meena@example.com','7 Lake View Road, Peelamedu, Coimbatore'),
 ('Vikram Narayan','9840011104','vikram@example.com','90 RS Puram Main Road, Coimbatore'),
 ('Lakshmi Devi','9840011105','lakshmi@example.com','23 Race Course Road, Coimbatore');

INSERT INTO worker(name,phone,email,experience_years,verification_status) VALUES
 ('Arun AC Services','9790022201','arun@example.com',8,'Verified'),
 ('Ravi Electricals','9790022202','ravi@example.com',6,'Verified'),
 ('Suresh Plumbing Works','9790022203','suresh@example.com',10,'Verified'),
 ('Murugan Carpentry','9790022204','murugan@example.com',12,'Verified'),
 ('Karthik Appliance Care','9790022205','karthik@example.com',5,'Verified'),
 ('Dinesh Electric and Plumbing','9790022206','dinesh@example.com',3,'Pending'),
 ('Selvam Cooling Solutions','9790022207','selvam@example.com',4,'Verified');

INSERT INTO worker_service(worker_id,service_id) VALUES
 (1,1),(2,2),(3,3),(4,4),(5,5),(5,1),(6,2),(6,3),(7,1);

INSERT INTO service_request(customer_id,worker_id,service_id,request_date,preferred_date,address,description,status) VALUES
 (1,1,1,'2026-09-02','2026-09-05','12 Gandhi Nagar, Coimbatore','AC not cooling','Completed'),
 (2,1,1,'2026-09-06','2026-09-09','45 Nehru Street, Singanallur, Coimbatore','Gas refill','Completed'),
 (3,1,1,'2026-09-12','2026-09-15','7 Lake View Road, Peelamedu, Coimbatore','AC making noise','Completed'),
 (4,1,1,'2026-09-18','2026-09-20','90 RS Puram Main Road, Coimbatore','Annual servicing','Completed'),
 (5,1,1,'2026-09-25','2026-09-28','23 Race Course Road, Coimbatore','Install split AC','Completed'),
 (1,1,1,'2026-10-03','2026-10-06','12 Gandhi Nagar, Coimbatore','Water leaking from AC','Cancelled'),
 (2,2,2,'2026-09-04','2026-09-07','45 Nehru Street, Singanallur, Coimbatore','Fan not working','Completed'),
 (3,2,2,'2026-09-14','2026-09-16','7 Lake View Road, Peelamedu, Coimbatore','Rewire kitchen switchboard','Completed'),
 (4,2,2,'2026-10-02','2026-10-05','90 RS Puram Main Road, Coimbatore','Inverter fault','Completed'),
 (5,3,3,'2026-09-08','2026-09-10','23 Race Course Road, Coimbatore','Bathroom tap leak','Completed'),
 (1,3,3,'2026-09-20','2026-09-22','12 Gandhi Nagar, Coimbatore','Blocked kitchen sink','Completed'),
 (2,3,3,'2026-10-10','2026-10-12','45 Nehru Street, Singanallur, Coimbatore','Overhead tank pipe repair','Completed'),
 (3,4,4,'2026-09-10','2026-09-14','7 Lake View Road, Peelamedu, Coimbatore','Wardrobe door repair','Completed'),
 (4,5,5,'2026-10-05','2026-10-08','90 RS Puram Main Road, Coimbatore','Washing machine not spinning','Completed'),
 (5,5,1,'2026-10-15','2026-10-18','23 Race Course Road, Coimbatore','AC power issue','In Progress'),
 (1,7,1,'2026-11-01','2026-11-08','12 Gandhi Nagar, Coimbatore','AC servicing','Pending'),
 (2,2,2,'2026-11-03','2026-11-09','45 Nehru Street, Singanallur, Coimbatore','Install ceiling fan','Accepted'),
 (3,4,4,'2026-10-20','2026-10-24','7 Lake View Road, Peelamedu, Coimbatore','Bed repair','Rejected');

-- jobs for requests 1-5, 7-15
INSERT INTO job(request_id,start_time,completion_time,actual_cost,job_status) VALUES
 (1,'2026-09-05 10:00','2026-09-05 12:30',1800,'Completed'),
 (2,'2026-09-09 11:00','2026-09-09 13:00',2200,'Completed'),
 (3,'2026-09-15 10:00','2026-09-15 14:00',2500,'Completed'),
 (4,'2026-09-20 09:30','2026-09-20 11:30',1500,'Completed'),
 (5,'2026-09-28 15:00','2026-09-28 17:00',3200,'Completed'),
 (7,'2026-09-07 10:00','2026-09-07 11:00',900,'Completed'),
 (8,'2026-09-16 10:00','2026-09-16 13:00',1200,'Completed'),
 (9,'2026-10-06 10:00','2026-10-06 12:00',1500,'Completed'),
 (10,'2026-09-10 09:00','2026-09-10 10:00',700,'Completed'),
 (11,'2026-09-22 09:00','2026-09-22 10:30',850,'Completed'),
 (12,'2026-10-12 11:00','2026-10-12 13:00',1100,'Completed'),
 (13,'2026-09-14 10:00','2026-09-14 16:00',4500,'Completed'),
 (14,'2026-10-08 10:00','2026-10-08 12:00',1300,'Completed'),
 (15,'2026-10-16 10:00',NULL,NULL,'In Progress');

INSERT INTO review(job_id,customer_id,worker_id,rating,comment,review_date) VALUES
 (1,1,1,5,'Quick and professional','2026-09-06'),
 (2,2,1,5,'Cooling is perfect now','2026-09-10'),
 (3,3,1,4,'Good work','2026-09-16'),
 (4,4,1,5,'Very neat servicing','2026-09-21'),
 (5,5,1,5,'Installed with care','2026-09-29'),
 (6,2,2,4,'Fixed the same day','2026-09-08'),
 (7,3,2,5,'Clean wiring work','2026-09-17'),
 (8,4,2,3,'Work was fine but came late','2026-10-07'),
 (9,5,3,5,'Leak fixed perfectly','2026-09-11'),
 (10,1,3,4,'Good job','2026-09-23'),
 (11,2,3,5,'Highly recommended','2026-10-13'),
 (12,3,4,4,'Solid carpentry work','2026-09-15'),
 (13,4,5,4,'Machine works well now','2026-10-09');

INSERT INTO complaint(customer_id,worker_id,job_id,description,status,created_date) VALUES
 (4,2,8,'Arrived late and left wires exposed','Open','2026-10-07'),
 (3,1,3,'Technician took longer than promised','Resolved','2026-09-17');
