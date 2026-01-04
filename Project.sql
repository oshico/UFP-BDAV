-- =============================================
-- 1. SCHEMA: users, courses, topics, lessons, enrollments, quizzes, questions
-- =============================================

CREATE TABLE users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(50) NOT NULL UNIQUE,
    password_hash NVARCHAR(256) NOT NULL,
    full_name NVARCHAR(100),
    email_address NVARCHAR(100) UNIQUE,
    user_role NVARCHAR(20) CHECK (user_role IN ('Admin', 'Manager', 'Student')),
    account_created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE courses (
    course_id INT IDENTITY(1,1) PRIMARY KEY,
    course_title NVARCHAR(200) NOT NULL,
    course_description NVARCHAR(MAX),
    course_duration_hours INT,
    course_price DECIMAL(10,2),
    course_status NVARCHAR(20) CHECK (course_status IN ('Active', 'Inactive')),
    course_created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE topics (
    topic_id INT IDENTITY(1,1) PRIMARY KEY,
    topic_name NVARCHAR(100) NOT NULL UNIQUE,
    topic_description NVARCHAR(MAX)
);

CREATE TABLE lessons (
    lesson_id INT IDENTITY(1,1) PRIMARY KEY,
    course_id INT NOT NULL,
    topic_id INT,
    lesson_title NVARCHAR(200) NOT NULL,
    lesson_text_content NVARCHAR(MAX),
    lesson_video_path NVARCHAR(500),
    lesson_image_path NVARCHAR(500),
    lesson_created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (topic_id) REFERENCES topics(topic_id)
);

CREATE TABLE enrollments (
    enrollment_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    enrollment_start_date DATE NOT NULL,
    enrollment_end_date DATE NOT NULL,
    enrollment_grade DECIMAL(5,2),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE TABLE quizzes (
    quiz_id INT IDENTITY(1,1) PRIMARY KEY,
    course_id INT NOT NULL,
    quiz_title NVARCHAR(200) NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE TABLE questions (
    question_id INT IDENTITY(1,1) PRIMARY KEY,
    quiz_id INT NOT NULL,
    question_text NVARCHAR(MAX),
    question_option_a NVARCHAR(200),
    question_option_b NVARCHAR(200),
    question_option_c NVARCHAR(200),
    question_option_d NVARCHAR(200),
    correct_option CHAR(1) CHECK (correct_option IN ('A','B','C','D')),
    FOREIGN KEY (quiz_id) REFERENCES quizzes(quiz_id)
);

-- =============================================
-- 2. LOGGING: user_logins, course_access_logs
-- =============================================

CREATE TABLE user_logins (
    login_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    login_timestamp DATETIME DEFAULT GETDATE(),
    login_ip_address NVARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE course_access_logs (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    access_timestamp DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

-- =============================================
-- 3. VIEWS
-- =============================================

CREATE VIEW view_courses_not_purchased_last_3_months AS
SELECT *
FROM courses c
WHERE NOT EXISTS (
    SELECT 1
    FROM enrollments e
    WHERE e.course_id = c.course_id
      AND e.enrollment_start_date >= DATEADD(MONTH, -3, GETDATE())
);

CREATE VIEW view_courses_with_more_than_10_unique_students AS
SELECT c.course_id, c.course_title, COUNT(DISTINCT e.user_id) AS student_count
FROM courses c
JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_title
HAVING COUNT(DISTINCT e.user_id) > 10;

CREATE VIEW view_top_5_courses_by_average_grade AS
SELECT TOP 5 c.course_id, c.course_title, AVG(e.enrollment_grade) AS average_grade
FROM courses c
JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_title
ORDER BY average_grade DESC;

-- =============================================
-- 4. STORED PROCEDURES
-- =============================================

CREATE PROCEDURE sp_list_student_enrollments
    @user_id INT
AS
BEGIN
    SELECT e.enrollment_id, c.course_title, e.enrollment_start_date, e.enrollment_end_date, e.enrollment_grade
    FROM enrollments e
    JOIN courses c ON e.course_id = c.course_id
    WHERE e.user_id = @user_id;
END;

CREATE PROCEDURE sp_list_available_courses
    @user_id INT
AS
BEGIN
    SELECT c.course_id, c.course_title, c.course_description, c.course_price
    FROM courses c
    WHERE c.course_status = 'Active'
      AND NOT EXISTS (
          SELECT 1 FROM enrollments e
          WHERE e.course_id = c.course_id
            AND e.user_id = @user_id
            AND e.enrollment_end_date >= GETDATE()
      );
END;

CREATE PROCEDURE sp_calculate_final_average_for_expired_courses
    @user_id INT
AS
BEGIN
    SELECT AVG(e.enrollment_grade) AS final_average
    FROM enrollments e
    WHERE e.user_id = @user_id
      AND e.enrollment_end_date < GETDATE();
END;

CREATE PROCEDURE sp_find_courses_by_topic
    @topic_name NVARCHAR(100)
AS
BEGIN
    SELECT DISTINCT c.course_id, c.course_title
    FROM courses c
    JOIN lessons l ON c.course_id = l.course_id
    JOIN topics t ON l.topic_id = t.topic_id
    WHERE t.topic_name = @topic_name;
END;

-- =============================================
-- 5. TRIGGERS
-- =============================================

CREATE TRIGGER trigger_prevent_invalid_enrollment
ON enrollments
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN courses c ON i.course_id = c.course_id
        WHERE c.course_status = 'Inactive'
           OR EXISTS (
               SELECT 1
               FROM enrollments e
               WHERE e.user_id = i.user_id
                 AND e.course_id = i.course_id
                 AND e.enrollment_end_date >= GETDATE()
           )
    )
    BEGIN
        RAISERROR('Cannot enroll: course inactive or already enrolled', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO enrollments(user_id, course_id, enrollment_start_date, enrollment_end_date, enrollment_grade)
    SELECT user_id, course_id, enrollment_start_date, enrollment_end_date, enrollment_grade
    FROM inserted;
END;

CREATE TRIGGER trigger_prevent_grade_on_inactive_enrollment
ON enrollments
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.enrollment_grade IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM enrollments e
              WHERE e.enrollment_id = i.enrollment_id
                AND e.enrollment_start_date <= GETDATE()
                AND e.enrollment_end_date >= GETDATE()
          )
    )
    BEGIN
        RAISERROR('Cannot assign grade: enrollment not active', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- =============================================
-- 6. Backup
-- =============================================

BACKUP DATABASE master
TO DISK = '/var/opt/mssql/backup/master.bak'
WITH
    FORMAT,
    INIT,
    COMPRESSION,
    STATS = 10;


RESTORE DATABASE master
FROM DISK = '/var/opt/mssql/backup/master.bak'
WITH
    REPLACE,
    STATS = 10;
