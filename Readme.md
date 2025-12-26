# Online Course System Database Documentation

## 1. Overview

This database supports an online course platform similar to Udemy. It manages users, courses, topics, lessons, enrollments, quizzes, questions, and logging activity. The database enforces data integrity, manages user access, and provides analytics via views and stored procedures.

---

## 2. Tables

| Table                  | Description                                                         | Key Columns        | Relationships                                                       |
| ---------------------- | ------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------- |
| **users**              | Stores system users and roles (Admin, Manager, Student)             | user_id (PK)       | Linked to `enrollments`, `user_logins`, `course_access_logs`        |
| **courses**            | Contains course metadata                                            | course_id (PK)     | Linked to `lessons`, `enrollments`, `quizzes`, `course_access_logs` |
| **topics**             | Defines lesson topics                                               | topic_id (PK)      | Linked to `lessons`                                                 |
| **lessons**            | Contains course lessons with optional topic, text, video, and image | lesson_id (PK)     | Linked to `courses`, `topics`                                       |
| **enrollments**        | Tracks user enrollment in courses with start/end dates and grades   | enrollment_id (PK) | Linked to `users`, `courses`                                        |
| **quizzes**            | Contains quizzes for courses                                        | quiz_id (PK)       | Linked to `courses`, `questions`                                    |
| **questions**          | Multiple-choice questions for quizzes                               | question_id (PK)   | Linked to `quizzes`                                                 |
| **user_logins**        | Logs user login activity                                            | login_id (PK)      | Linked to `users`                                                   |
| **course_access_logs** | Logs course content access by users                                 | log_id (PK)        | Linked to `users`, `courses`                                        |

---

## 3. Views

| View                                               | Description                                                  |
| -------------------------------------------------- | ------------------------------------------------------------ |
| **view_courses_not_purchased_last_3_months**       | Lists courses not purchased by any user in the last 3 months |
| **view_courses_with_more_than_10_unique_students** | Lists courses purchased by more than 10 unique students      |
| **view_top_5_courses_by_average_grade**            | Lists the top 5 courses based on average student grade       |

---

## 4. Stored Procedures

| Procedure                                          | Description                                                        | Parameters  |
| -------------------------------------------------- | ------------------------------------------------------------------ | ----------- |
| **sp_list_student_enrollments**                    | Lists all enrollments of a student with start/end dates and grades | @user_id    |
| **sp_list_available_courses**                      | Lists courses available for enrollment for a specific student      | @user_id    |
| **sp_calculate_final_average_for_expired_courses** | Calculates average grade of expired courses for a student          | @user_id    |
| **sp_find_courses_by_topic**                       | Finds courses that contain lessons for a specific topic            | @topic_name |

---

## 5. Triggers

| Trigger                                          | Table       | Purpose                                                                          |
| ------------------------------------------------ | ----------- | -------------------------------------------------------------------------------- |
| **trigger_prevent_invalid_enrollment**           | enrollments | Prevents insertion if course is inactive or student is already actively enrolled |
| **trigger_prevent_grade_on_inactive_enrollment** | enrollments | Prevents grade insertion/update if the enrollment is not currently active        |

---

## 6. Business Rules

* Users can have only one active enrollment per course.
* Grades can only be assigned to active enrollments.
* Courses may be active or inactive; inactive courses cannot accept new enrollments.
* Logging tables track user logins and course access events for analytics and auditing.

---
