-- =============================
-- 1. INSERT USERS
-- =============================

INSERT INTO users (username, password_hash, full_name, email_address, user_role)
VALUES
('admin1', 'hash123', 'System Admin', 'admin@email.com', 'Admin'),
('manager1', 'hash456', 'Course Manager', 'manager@email.com', 'Manager'),
('student1', 'hash789', 'John Student', 'john@email.com', 'Student'),
('student2', 'hash999', 'Jane Student', 'jane@email.com', 'Student'),
('student3', 'hash888', 'Mike Student', 'mike@email.com', 'Student'),
('student4', 'hash777', 'Anna Student', 'anna@email.com', 'Student'),
('student5', 'hash666', 'Sara Student', 'sara@email.com', 'Student'),
('student6', 'hash555', 'Tom Student', 'tom@email.com', 'Student'),
('student7', 'hash444', 'Emma Student', 'emma@email.com', 'Student'),
('student8', 'hash333', 'Alex Student', 'alex@email.com', 'Student'),
('student9', 'hash222', 'Leo Student', 'leo@email.com', 'Student'),
('student10','hash111', 'Nina Student', 'nina@email.com', 'Student');
i
SELECT * FROM users;

-- =============================
-- 2. INSERT COURSES
-- =============================

INSERT INTO courses (course_title, course_description, course_duration_hours, course_price, course_status)
VALUES
('SQL Fundamentals', 'Learn SQL from scratch', 30, 99.99, 'Active'),
('Advanced Databases', 'Deep dive into DB design', 40, 149.99, 'Active'),
('Legacy Systems', 'Old technologies overview', 20, 59.99, 'Inactive');

SELECT * FROM courses;

-- =============================
-- 3. INSERT TOPICS
-- =============================

INSERT INTO topics (topic_name, topic_description)
VALUES
('SQL Basics', 'Introduction to SQL'),
('Joins', 'Working with joins'),
('Indexes', 'Database indexing');

SELECT * FROM topics;

-- =============================
-- 4. INSERT LESSONS
-- =============================

INSERT INTO lessons (course_id, topic_id, lesson_title, lesson_text_content)
VALUES
(1, 1, 'Intro to SQL', 'Basic SQL syntax'),
(1, 2, 'SQL Joins', 'INNER and OUTER joins'),
(2, 3, 'Indexes Explained', 'Index performance');

SELECT * FROM lessons;

-- =============================
-- 5. INSERT QUIZZES & QUESTIONS
-- =============================

INSERT INTO quizzes (course_id, quiz_title)
VALUES (1, 'SQL Basics Quiz');

INSERT INTO questions
(quiz_id, question_text, question_option_a, question_option_b, question_option_c, question_option_d, correct_option)
VALUES
(1, 'What does SQL stand for?',
 'Structured Query Language',
 'Simple Query Language',
 'Sequential Query Language',
 'Standard Query List',
 'A');

SELECT * FROM quizzes;
SELECT * FROM questions;

-- =============================
-- 6. VALID ENROLLMENTS (TRIGGER OK)
-- =============================

INSERT INTO enrollments (user_id, course_id, enrollment_start_date, enrollment_end_date)
VALUES
(3, 1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(4, 1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(5, 1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(6, 1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(7, 1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(8, 1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(9, 1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(10,1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(11,1, GETDATE(), DATEADD(MONTH, 2, GETDATE())),
(12,1, GETDATE(), DATEADD(MONTH, 2, GETDATE()));

SELECT * FROM enrollments;

-- =============================
-- 7. INVALID ENROLLMENT (TRIGGER ERROR)
-- =============================

INSERT INTO enrollments (user_id, course_id, enrollment_start_date, enrollment_end_date)
VALUES
(3, 3, GETDATE(), DATEADD(MONTH, 1, GETDATE()));

-- =============================
-- 8. STORED PROCEDURES TEST
-- =============================

EXEC sp_list_student_enrollments @user_id = 3;

EXEC sp_list_available_courses @user_id = 3;

EXEC sp_calculate_final_average_for_expired_courses @user_id = 3;

EXEC sp_find_courses_by_topic @topic_name = 'SQL Basics';

-- =============================
-- 9. UPDATE GRADE (ACTIVE)
-- =============================

UPDATE enrollments
SET enrollment_grade = 90
WHERE enrollment_id = 1;

SELECT * FROM enrollments;

-- =============================
-- 10. TEST VIEWS
-- =============================

SELECT * FROM view_courses_not_purchased_last_3_months;

SELECT * FROM view_courses_with_more_than_10_unique_students;

SELECT * FROM view_top_5_courses_by_average_grade;

-- =============================
-- 11. TEST BACKUP
-- =============================

RESTORE VERIFYONLY
FROM DISK = '/var/opt/mssql/backup/master.bak';
