-- Noor Al-Iman: MySQL 8 schema
-- Run with: mysql -u root -p < schema.sql
-- Requires MySQL 8.0.16 or newer.

CREATE DATABASE IF NOT EXISTS noor_al_iman
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE noor_al_iman;

SET FOREIGN_KEY_CHECKS = 0;
DROP VIEW IF EXISTS view_student_attendance;
DROP TABLE IF EXISTS TakenGift, GiveGift, Gift, GiftType, Memorization_Record,
  Attendance_Record, EnrollsIn, Classroom, Curriculum, Student, Teacher,
  Supervisor, Admin, Person, ZipCodes;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE ZipCodes (
  ZipCode VARCHAR(10)  PRIMARY KEY,
  City    VARCHAR(50)  NOT NULL,
  State   VARCHAR(50)  NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Person (
  PersonID     INT AUTO_INCREMENT PRIMARY KEY,
  FName        VARCHAR(50)  NOT NULL,
  LName        VARCHAR(50)  NOT NULL,
  BOD          DATE NULL,
  Gender       ENUM('Male','Female') NULL,
  Street       VARCHAR(100) NULL,
  ZipCode      VARCHAR(10)  NULL,
  PhoneNumber  VARCHAR(20)  NULL,
  Email        VARCHAR(100) NULL UNIQUE,
  PasswordHash VARCHAR(255) NULL, -- bcrypt hash from PHP password_hash(), staff only
  CONSTRAINT fk_person_zip FOREIGN KEY (ZipCode) REFERENCES ZipCodes(ZipCode)
) ENGINE=InnoDB;

-- Disjoint subtypes of Person: a user's role is the subtype table that holds their PersonID
CREATE TABLE Admin (
  PersonID INT PRIMARY KEY,
  CONSTRAINT fk_admin_person FOREIGN KEY (PersonID) REFERENCES Person(PersonID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Supervisor (
  PersonID INT PRIMARY KEY,
  CONSTRAINT fk_super_person FOREIGN KEY (PersonID) REFERENCES Person(PersonID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Teacher (
  PersonID INT PRIMARY KEY,
  CONSTRAINT fk_teacher_person FOREIGN KEY (PersonID) REFERENCES Person(PersonID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Student (
  PersonID INT PRIMARY KEY,
  IsActive TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_student_person FOREIGN KEY (PersonID) REFERENCES Person(PersonID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Curriculum (
  Curriculum_ID  INT AUTO_INCREMENT PRIMARY KEY,
  CurriculumName VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Classroom (
  Classroom_ID INT AUTO_INCREMENT PRIMARY KEY,
  Name         VARCHAR(20) NOT NULL UNIQUE,
  MaxSize      INT NOT NULL,
  Super_ID     INT NOT NULL,
  T_ID         INT NOT NULL,
  Curr_ID      INT NOT NULL,
  CONSTRAINT chk_maxsize CHECK (MaxSize > 0),
  CONSTRAINT fk_class_super FOREIGN KEY (Super_ID) REFERENCES Supervisor(PersonID),
  CONSTRAINT fk_class_teacher FOREIGN KEY (T_ID) REFERENCES Teacher(PersonID),
  CONSTRAINT fk_class_curr FOREIGN KEY (Curr_ID) REFERENCES Curriculum(Curriculum_ID)
) ENGINE=InnoDB;

CREATE TABLE EnrollsIn (
  Classroom_ID INT NOT NULL,
  S_ID         INT NOT NULL,
  PRIMARY KEY (Classroom_ID, S_ID),
  UNIQUE KEY ux_enrolls_student (S_ID), -- every student belongs to exactly one classroom
  CONSTRAINT fk_enroll_class FOREIGN KEY (Classroom_ID) REFERENCES Classroom(Classroom_ID) ON DELETE CASCADE,
  CONSTRAINT fk_enroll_student FOREIGN KEY (S_ID) REFERENCES Student(PersonID)
) ENGINE=InnoDB;

CREATE TABLE Attendance_Record (
  A_ID   INT AUTO_INCREMENT PRIMARY KEY,
  Status ENUM('Present','Absent','Late') NOT NULL,
  Notes  VARCHAR(255) NULL,
  Date   DATE NOT NULL,
  T_ID   INT NOT NULL,
  S_ID   INT NOT NULL,
  UNIQUE KEY ux_attendance_day (S_ID, Date), -- one record per student per day
  CONSTRAINT fk_att_teacher FOREIGN KEY (T_ID) REFERENCES Teacher(PersonID),
  CONSTRAINT fk_att_student FOREIGN KEY (S_ID) REFERENCES Student(PersonID)
) ENGINE=InnoDB;

-- Weak entity of Student: composite key (M_ID, S_ID). The API sets M_ID = MAX(M_ID) + 1 per student.
CREATE TABLE Memorization_Record (
  M_ID       INT NOT NULL,
  S_ID       INT NOT NULL,
  SurahName  VARCHAR(50) NOT NULL,
  FromVerse  INT NOT NULL,
  ToVerse    INT NOT NULL,
  Evaluation ENUM('Weak','Good','Very good','Excellent') NULL,
  Notes      VARCHAR(255) NULL,
  Date       DATE NOT NULL,
  PRIMARY KEY (M_ID, S_ID),
  CONSTRAINT chk_verses CHECK (FromVerse >= 1 AND ToVerse >= FromVerse),
  CONSTRAINT fk_mem_student FOREIGN KEY (S_ID) REFERENCES Student(PersonID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Catalog of gift kinds (Mushaf, Certificate, ...)
CREATE TABLE GiftType (
  TypeName VARCHAR(50) PRIMARY KEY
) ENGINE=InnoDB;

-- One Gift row = one physical gift handed out.
-- Giving a gift inserts Gift, then GiveGift (teacher) and TakenGift (student) in one transaction.
CREATE TABLE Gift (
  G_ID INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(50) NOT NULL,
  CONSTRAINT fk_gift_type FOREIGN KEY (Name) REFERENCES GiftType(TypeName) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE GiveGift (
  G_ID INT PRIMARY KEY,
  T_ID INT NOT NULL,
  Date DATE NOT NULL,
  CONSTRAINT fk_give_gift FOREIGN KEY (G_ID) REFERENCES Gift(G_ID) ON DELETE CASCADE,
  CONSTRAINT fk_give_teacher FOREIGN KEY (T_ID) REFERENCES Teacher(PersonID)
) ENGINE=InnoDB;

CREATE TABLE TakenGift (
  G_ID INT NOT NULL,
  S_ID INT NOT NULL,
  Date DATE NOT NULL,
  PRIMARY KEY (G_ID, S_ID),
  CONSTRAINT fk_taken_gift FOREIGN KEY (G_ID) REFERENCES Gift(G_ID) ON DELETE CASCADE,
  CONSTRAINT fk_taken_student FOREIGN KEY (S_ID) REFERENCES Student(PersonID)
) ENGINE=InnoDB;

-- Business rules enforced by the database itself (the API also checks them first)
DELIMITER $$

CREATE TRIGGER prevent_student_delete
BEFORE DELETE ON Student
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM Attendance_Record WHERE S_ID = OLD.PersonID) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Cannot delete student with attendance records';
  END IF;
END$$

CREATE TRIGGER check_classroom_capacity
BEFORE INSERT ON EnrollsIn
FOR EACH ROW
BEGIN
  IF (SELECT COUNT(*) FROM EnrollsIn WHERE Classroom_ID = NEW.Classroom_ID)
     >= (SELECT MaxSize FROM Classroom WHERE Classroom_ID = NEW.Classroom_ID) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Classroom is full';
  END IF;
END$$

DELIMITER ;

CREATE VIEW view_student_attendance AS
SELECT p.PersonID, p.FName, p.LName,
       COUNT(a.A_ID) AS Total_Attendance_Records,
       SUM(a.Status = 'Present') AS Present_Count,
       SUM(a.Status = 'Absent')  AS Absent_Count,
       SUM(a.Status = 'Late')    AS Late_Count
FROM Attendance_Record a
JOIN Person p ON a.S_ID = p.PersonID
GROUP BY p.PersonID, p.FName, p.LName;

-- Dedicated MySQL user for the PHP API (change the password!!!).
-- MySQL stays bound to 127.0.0.1, so only the API on the same VPS can connect.
-- CREATE USER 'noor_api'@'localhost' IDENTIFIED BY 'CHANGE_ME_TO_STRONG_PASSWORD';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON noor_al_iman.* TO 'noor_api'@'localhost';
-- FLUSH PRIVILEGES;
