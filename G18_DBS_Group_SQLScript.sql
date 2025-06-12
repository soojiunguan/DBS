----------------------------------------------------------------------------------------------------------------------
--+=============================================+
--|                 GROUP 18					|
--+=============================================+
--	ALL LOGIN PASSWORD AS "StrongPassword#00 '[your id]' "

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MedicalInfoSystem')
DROP DATABASE MedicalInfoSystem;
GO

-- Drop existing logon trigger if it exists
IF EXISTS (SELECT * FROM sys.server_triggers WHERE name = 'trg_LogonAudit_HospitalSystem')
    DROP TRIGGER trg_LogonAudit_HospitalSystem ON ALL SERVER;
GO

--	CREATE DATABASE
CREATE DATABASE MedicalInfoSystem;
GO

USE MedicalInfoSystem;
GO

USE MASTER;
GO

--	CREATE MASTER KEY
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Strong_Master_Key_Password123_!';
END
GO

--	CREATE CERTIFICATE
CREATE CERTIFICATE MedicalSystemTDECert
WITH SUBJECT = 'Certificate For MedicalInfoSystem Database TDE';
GO

---------------------------------------------------- SECTION BREAK ----------------------------------------------------

--+=============================================+
--|				     TABLE						|
--+=============================================+

--	STAFF TABLE
CREATE TABLE Staff (
    StaffID VARCHAR(6) PRIMARY KEY,
    SName VARCHAR(100) NOT NULL,
    SPassportNumber VARCHAR(50) NOT NULL,
    SPhone VARCHAR(20),
    Position VARCHAR(20)
);
GO

--	PATIENT TABLE
CREATE TABLE Patient (
    PID VARCHAR(6) PRIMARY KEY,
    PName VARCHAR(100) NOT NULL,
    PPassportNumber VARCHAR(50) NOT NULL,
    PPhone VARCHAR(20),
    PaymentCardNumber VARCHAR(20),
    PaymentCardPinCode VARCHAR(20)
);
GO

--	PRESCRIPTION TABLE
CREATE TABLE Prescription (
    PresID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID VARCHAR(6) REFERENCES Patient(PID),
    DoctorID VARCHAR(6) REFERENCES Staff(StaffID),
    PresDateTime DATETIME NOT NULL,
	Status VARCHAR(10),
		CONSTRAINT CHK_PresStatus CHECK (Status IN ('New', 'Dispensed', 'Cancelled'))
);
GO

--	MEDICINE TABLE
CREATE TABLE Medicine (
	MedID VARCHAR(10) PRIMARY KEY,
	MedName VARCHAR(100) NOT NULL
);
GO

--	PRESCRIPTION MEDICINE TABLE
CREATE TABLE PrescriptionMedicine (
	PresID INT REFERENCES Prescription(PresID),
	MedID VARCHAR(10) REFERENCES Medicine(MedID),
	PRIMARY KEY (PresID, MedID)
);
GO

--	APPOINTMENT TABLE
CREATE TABLE Appointment (
	AppointmentID INT IDENTITY(1,1) PRIMARY KEY,
	StaffID VARCHAR(6) REFERENCES Staff(StaffID),
	PID VARCHAR(6) REFERENCES Patient(PID),
	Date DATETIME,
	Status VARCHAR(10),
		CONSTRAINT CHK_AppointmentStatus CHECK (Status IN ('New', 'Done', 'Cancelled'))
);
GO

---------------------------------------------------- SECTION BREAK ----------------------------------------------------
--+=============================================+
--|				   ORIGINAL VALUE				|
--+=============================================+

INSERT INTO Staff (StaffID, SName, SPassportNumber, SPhone, Position) VALUES
    ('ST001', 'Jerremy Lim', 'G1234567A', '60123456789', 'Doctor'),
    ('ST002', 'Mandy Loh', 'G2345678B', '60198765432', 'Nurse'),
    ('ST003', 'Deric Wong', 'G3456789C', '60187654321', 'Pharmacist'),
    ('ST004', 'Monicca Ching', 'G4567890D', '60176543210', 'Doctor'),
    ('ST005', 'Vanessa Ho', 'G5678901E', '60165432109', 'Pharmacist'),
    ('ST006', 'David Tan', 'G6789012F', '60154321098', 'Nurse');
GO

INSERT INTO Patient (PID, PName, PPassportNumber, PPhone, PaymentCardNumber, PaymentCardPinCode) VALUES
    ('PT001', 'Alice Tan', 'P1234567X', '60123456788', '2736251728391029', '1344'),
    ('PT002', 'Bob Chan', 'P2345678Y', '60198765433', '1274625172839128', '3481'),
    ('PT003', 'Clara Ng', 'P3456789Z', '60187654322', '1226351728391023', '9012'),
    ('PT004', 'David Lim', 'P4567890W', '60176543211', '3627182910391827', '3317'),
    ('PT005', 'Emma Soh', 'P5678901V', '60165432100', '9203726152716273', '7890'),
    ('PT006', 'Frank Teo', 'P6789012U', '60154321099', '1472839172647182', '1447');
GO

INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, [Status]) VALUES
    ('PT001', 'ST001', '2025-04-01 10:00:00', 'New'),
    ('PT002', 'ST004', '2025-04-02 11:30:00', 'Dispensed'),
    ('PT003', 'ST001', '2025-04-03 09:15:00', 'Cancelled'),
    ('PT004', 'ST004', '2025-04-04 14:00:00', 'New'),
    ('PT005', 'ST001', '2025-04-05 16:45:00', 'Dispensed'),
    ('PT006', 'ST004', '2025-04-06 08:30:00', 'New');
GO

SELECT * FROM Prescription;

INSERT INTO Medicine (MedID, MedName) VALUES
    ('MED001', 'Paracetamol 500mg'),
    ('MED002', 'Amoxicillin 250mg'),
    ('MED003', 'Ibuprofen 400mg'),
    ('MED004', 'Cetirizine 10mg'),
    ('MED005', 'Metformin 500mg'),
    ('MED006', 'Aspirin 100mg');
GO

INSERT INTO PrescriptionMedicine (PresID, MedID) VALUES
    (1, 'MED001'),
    (5, 'MED003'),
    (2, 'MED002'),
    (3, 'MED004'),
    (4, 'MED005'),
    (5, 'MED006');
GO

INSERT INTO Appointment (StaffID, PID, Date, [Status]) VALUES
    ('ST001', 'PT001', '2025-04-01 09:00:00', 'Done'),
    ('ST004', 'PT002', '2025-04-02 10:30:00', 'New'),
    ('ST001', 'PT003', '2025-04-03 11:00:00', 'Cancelled'),
    ('ST004', 'PT004', '2025-04-04 13:00:00', 'New'),
    ('ST001', 'PT005', '2025-04-05 15:00:00', 'Done'),
    ('ST004', 'PT006', '2025-04-06 08:00:00', 'New');
GO

---------------------------------------------------- SECTION BREAK ----------------------------------------------------
--+=============================================+
--|				   CREATE ROLE					|
--+=============================================+

USE MedicalInfoSystem; -- Switch to your database
GO

-- Create Roles (skip if they exist)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Doctor' AND type = 'R')
    CREATE ROLE Doctor;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Nurse' AND type = 'R')
    CREATE ROLE Nurse;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Pharmacist' AND type = 'R')
    CREATE ROLE Pharmacist;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Patient' AND type = 'R')
    CREATE ROLE Patient;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Admin' AND type = 'R')
    CREATE ROLE Admin;
GO

-- Create Database Users (skip if they exist)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ST001')
    CREATE USER ST001 FOR LOGIN ST001;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ST002')
    CREATE USER ST002 FOR LOGIN ST002;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ST003')
    CREATE USER ST003 FOR LOGIN ST003;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ST004')
    CREATE USER ST004 FOR LOGIN ST004;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ST005')
    CREATE USER ST005 FOR LOGIN ST005;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ST006')
    CREATE USER ST006 FOR LOGIN ST006;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'PT001')
    CREATE USER PT001 FOR LOGIN PT001;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'PT002')
    CREATE USER PT002 FOR LOGIN PT002;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'PT003')
    CREATE USER PT003 FOR LOGIN PT003;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'PT004')
    CREATE USER PT004 FOR LOGIN PT004;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'PT005')
    CREATE USER PT005 FOR LOGIN PT005;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'PT006')
    CREATE USER PT006 FOR LOGIN PT006;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AD001')
    CREATE USER AD001 FOR LOGIN AD001;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AD002')
    CREATE USER AD002 FOR LOGIN AD002;
GO

--	Assign Role Memberships
--	DOCTOR
ALTER ROLE Doctor ADD MEMBER ST001;
ALTER ROLE Doctor ADD MEMBER ST004;
--	NURSE
ALTER ROLE Nurse ADD MEMBER ST002;
ALTER ROLE Nurse ADD MEMBER ST006;
--	PHARMACIST
ALTER ROLE Pharmacist ADD MEMBER ST003;
ALTER ROLE Pharmacist ADD MEMBER ST005;
--	ADMIN
ALTER ROLE Admin ADD MEMBER AD001;
ALTER ROLE Admin ADD MEMBER AD002;
--	PATIENT
ALTER ROLE Patient ADD MEMBER PT001;
ALTER ROLE Patient ADD MEMBER PT002;
ALTER ROLE Patient ADD MEMBER PT003;
ALTER ROLE Patient ADD MEMBER PT004;
ALTER ROLE Patient ADD MEMBER PT005;
ALTER ROLE Patient ADD MEMBER PT006;
GO

-- STAFF LOGIN
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ST001')
    CREATE LOGIN ST001 WITH PASSWORD = 'StrongPassword#ST001';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ST002')
    CREATE LOGIN ST002 WITH PASSWORD = 'StrongPassword#ST002';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ST003')
    CREATE LOGIN ST003 WITH PASSWORD = 'StrongPassword#ST003';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ST004')
    CREATE LOGIN ST004 WITH PASSWORD = 'StrongPassword#ST004';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ST005')
    CREATE LOGIN ST005 WITH PASSWORD = 'StrongPassword#ST005';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ST006')
    CREATE LOGIN ST006 WITH PASSWORD = 'StrongPassword#ST006';

-- PATIENT LOGIN
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'PT001')
    CREATE LOGIN PT001 WITH PASSWORD = 'StrongPassword#PT001';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'PT002')
    CREATE LOGIN PT002 WITH PASSWORD = 'StrongPassword#PT002';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'PT003')
    CREATE LOGIN PT003 WITH PASSWORD = 'StrongPassword#PT003';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'PT004')
    CREATE LOGIN PT004 WITH PASSWORD = 'StrongPassword#PT004';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'PT005')
    CREATE LOGIN PT005 WITH PASSWORD = 'StrongPassword#PT005';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'PT006')
    CREATE LOGIN PT006 WITH PASSWORD = 'StrongPassword#PT006';

-- ADMIN LOGIN
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'AD001')
    CREATE LOGIN AD001 WITH PASSWORD = 'StrongPassword#AD001';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'AD002')
    CREATE LOGIN AD002 WITH PASSWORD = 'StrongPassword#AD002';


---------------------------------------------------- SECTION BREAK ----------------------------------------------------

--+=============================================+
--|				     ISSUE						|
--+=============================================+

--	STUDENT 1 - MUHAMMAD NABIL HAKIM BIN YUSAIDI
--	ISSUE 1 ->	Doctors can create multiple same appointments (Appointment dupplication)
--	ISSUE 2	->	Appointment table allows invalid patient entries.
--	ISSUE 3	->	Data stored/transferred unencrypted.
--	ISSUE 4	->	All users share schema access without roles.
--	ISSUE 5	->	Admins delete patient or appointment without records.

--	STUDENT 2 - TAN SHI YING
--	ISSUE 1 ->	SQL Injection Threat
--	ISSUE 2	->	Sensitive Data Exposure
--	ISSUE 3	->	Patients are able to view all appointments in the system, including those of other patients 
--	ISSUE 4	->	Doctor can updates another doctor’s prescription
--	ISSUE 5	->	Staff Deleted Without Trace / Admins can delete staff or change structure without audit trail

--	STUDENT 3 -	SOO JIUN GUAN
--	ISSUE 1	->	Phone numbers of patients are directly exposed.
--	ISSUE 2	->	Non-admin users can modify their position field.
--	ISSUE 3	->	Critical tables like Patient and Staff are not monitored for changes.
--	ISSUE 4	->	Staff and patients can view each other’s full personal records without restriction.
--	ISSUE 5 ->	Pharmacist has unrestricted access to modify prescription data
--	ISSUE 6 ->	No login activity is being captured or tracked.

--	STUDENT 4 - TEH YUE FENG
--	ISSUE 1 ->	Backdated prescription entries are allowed.
--	ISSUE 2 ->	Plaintext Storage of Payment Information
--	ISSUE 3 ->	No Backup or Disaster Recovery Plan
--	ISSUE 4 ->	Improper Permission Control for Nurse
--	ISSUE 5 ->	Lack of Change History Tracking on Patient, Medicine, and Staff tables
--	ISSUE 6 ->	No Prescription / Appointment Audit

---------------------------------------------------- SECTION BREAK ----------------------------------------------------

--+=============================================+
--|				     PROOF						|
--+=============================================+

--	STUDENT 1:	MUHAMMAD NABIL HAKIM BIN YUSAIDI
--	ISSUE 1	->	Doctors can create multiple same appointments (Appointment dupplication)
INSERT INTO Appointment (StaffID, PID, Date, Status)
VALUES ('ST001', 'PT001', '2025-05-10 09:00:00', 'New');

SELECT *FROM Appointment;
----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 2	->	Appointment table allows invalid patient entries.
--	For example, this insert statement works even though patient 'PT999' doesn't exist:
--	drop constraints first
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Appointment_Patient')
    ALTER TABLE Appointment DROP CONSTRAINT FK_Appointment_Patient;
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Appointment__PID_52593CB8')
    ALTER TABLE Appointment DROP CONSTRAINT FK_Appointment__PID_52593CB8;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID('Appointment') AND referenced_object_id = OBJECT_ID('Patient'))
BEGIN
    DECLARE @constraintName nvarchar(128)
    SELECT @constraintName = name FROM sys.foreign_keys 
    WHERE parent_object_id = OBJECT_ID('Appointment') 
    AND referenced_object_id = OBJECT_ID('Patient')
    
    DECLARE @sql nvarchar(200) = N'ALTER TABLE Appointment DROP CONSTRAINT ' + @constraintName
    EXEC sp_executesql @sql
END

--	then try insert

INSERT INTO Appointment (StaffID, PID, Date, Status)
VALUES ('ST001', 'PT999', '2025-05-20 11:00:00', 'New');

--	delete afterwards
DELETE FROM Appointment
WHERE StaffID = 'ST001'
  AND PID = 'PT999'
  AND Date = '2025-05-20 11:00:00'
  AND Status = 'New';


--	orphaned appointments and data integrity issues
SELECT a.AppointmentID, a.PID, p.PName, a.Date, 
       CASE WHEN p.PID IS NULL THEN 'ORPHANED RECORD' 
            ELSE 'Valid Record' END AS RecordStatus
FROM Appointment a
LEFT JOIN Patient p ON a.PID = p.PID;

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 3	->	Data stored/transferred unencrypted.
SELECT * FROM Patient;

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 4 ->	All users share schema access without roles.
--	NURSE
SELECT * FROM Patient;
UPDATE Patient SET PPhone = '60123456789' WHERE PID = 'PT001';

--	PHARMACIST
SELECT * FROM Prescription;
UPDATE Prescription SET Status = 'Dispensed' WHERE PresID = 1;

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 5	->	Admins delete patient or appointment without records.
--	Currently, an admin can delete staff records without any tracking
DELETE FROM Staff WHERE StaffID = 'ST001';

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 2:	TAN SHI YING
--	ISSUE 1 ->	SQL Injection Threat
--  Dynamic SQL prone to injection ---> Returns all rows in the Staff table (SQL Injection successful)
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM Staff WHERE StaffID = ''' + 'ST001'' OR ''1''=''1' + '''';
EXEC(@sql);

--  Test Case 2: Patient Login--
--	Directly vulnerable to injection --> Logs in without correct passport (SQL Injection successful)
DECLARE @sql NVARCHAR(MAX) = 
  'SELECT PID, PName FROM Patient WHERE PID = ''' + 'PT001'' OR ''1''=''1' + ''' AND PPassportNumber = ''' + 'any' + '''';
EXEC(@sql);

--  Test Case 3: Doctor Prescription Lookup--
--	Assumes vulnerable dynamic SQL --> Returns all prescriptions regardless of doctor (unauthorized access)
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM Prescription WHERE DoctorID = ''' + 'ST001'' OR ''1''=''1' + '''';
EXEC(@sql);

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 2	->	Sensitive data (PASSPORT) is visible in plain text
SELECT PID, PName, PPassportNumber FROM Patient;
SELECT StaffID, SName, SPassportNumber FROM Staff;

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 3	->	Patients are able to view all appointments in the system, including those of other patients 
--	Patient (or even unauthorized user) views all appointments:
SELECT * FROM Appointment;

--	Update appointment status without permission:
UPDATE Appointment
SET Status = 'Done'
WHERE StaffID = 'ST001' AND PID = 'PT001' AND Date = '2025-05-04 09:00:00';

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 4	->	Unauthorized Prescription Modification by Doctors
--	View and modify all prescriptions regardless of ownership
SELECT * FROM Prescription;

--	Modify a prescription that belongs to another doctor
UPDATE Prescription
SET Status = 'Cancelled'
WHERE PresID = 2;  -- belongs to another doctor

--	Insert prescriptions for patients under other doctors
INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, Status)
VALUES ('PT004', 'ST001', GETDATE(), 'New');  -- even if PT004 belongs to ST004

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 5	->	Staff Deleted Without Trace / Admins can delete staff or change structure without audit trail
ALTER TABLE Staff ADD DummyBeforeAudit INT;
SELECT * FROM sys.fn_get_audit_file('D:\Temp\AuditLogs\*', DEFAULT, DEFAULT);

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 3:	SOO JIUN GUAN
--	ISSUE 1	->	Phone numbers of patients are directly exposed.

ALTER TABLE Patient ALTER COLUMN PPhone VARCHAR(20);
GO

SELECT 
    PID,
    PPhone
FROM Patient;

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 2	->	Non-admin users (e.g., nurses) can modify their position field
UPDATE Staff
SET Position = 'Doctor'
OUTPUT 
    deleted.StaffID,
    deleted.Position AS OriginalPosition,
    inserted.Position AS NewPosition
WHERE StaffID = 'ST002';

-- Change back to original position
UPDATE Staff
SET Position = 'Nurse'
WHERE StaffID = 'ST002';

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 3	->	Critical tables like Patient and Staff are not monitored for changes
-- Check if CDC is enabled on database
SELECT is_cdc_enabled AS DB_CDC_Enabled
FROM sys.databases 
WHERE name = 'MedicalInfoSystem';

-- Check if tables are tracked
SELECT name, is_tracked_by_cdc 
FROM sys.tables 
WHERE name IN ('Patient', 'Staff');

-- Check if CDC tables exist
IF OBJECT_ID('cdc.dbo_Patient_CT') IS NULL
    PRINT 'Patient CDC table does NOT exist.';
ELSE
    SELECT TOP 5 * FROM cdc.dbo_Patient_CT;

IF OBJECT_ID('cdc.dbo_Staff_CT') IS NULL
    PRINT 'Staff CDC table does NOT exist.';
ELSE
    SELECT TOP 5 * FROM cdc.dbo_Staff_CT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 4	->	Staff and patients can view each other’s full personal records without restriction
SELECT * FROM Staff;

SELECT * FROM Patient;

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 5	->	Pharmacist has unrestricted access to modify prescription data
DROP PROCEDURE IF EXISTS usp_UpdatePrescriptionStatus;
GO

UPDATE Prescription
SET DoctorID = 'ST004'
WHERE PresID = 3;

SELECT *
FROM Prescription
WHERE PresID = 3;

-- change back to original data
UPDATE Prescription
SET DoctorID = 'ST002'
WHERE PresID = 3;

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 6	->	No login activity is being captured or tracked
IF EXISTS (SELECT * FROM sys.server_triggers WHERE name = 'trg_LogonAudit_HospitalSystem')
    DROP TRIGGER trg_LogonAudit_HospitalSystem ON ALL SERVER;
GO

IF OBJECT_ID('dbo.LogonAudit', 'U') IS NULL
    PRINT 'LogonAudit table does not exist.';
ELSE
BEGIN
    PRINT 'LogonAudit table exists.';
    SELECT TOP 5 * FROM dbo.LogonAudit ORDER BY LoginTime DESC;
END
GO

-- Try simulating a login context switch (no audit will happen)
EXECUTE AS LOGIN = 'ST006';
SELECT SYSTEM_USER AS CurrentLogin;
REVERT;
GO

-- Check again (no log entries expected)
IF OBJECT_ID('dbo.LogonAudit', 'U') IS NOT NULL
BEGIN
    PRINT 'Re-checking LogonAudit contents...';
    SELECT TOP 5 * FROM dbo.LogonAudit ORDER BY LoginTime DESC;
END
GO

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 4:	TEH YUE FENG
--	ISSUE 1	->	Backdated prescription entries are allowed

DROP TRIGGER IF EXISTS trg_BlockBackdatedPrescription;
GO

INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, Status)
VALUES ('PT001', 'ST001', '1999-01-01 10:00:00', 'New');
SELECT TOP 5 * FROM Prescription ORDER BY PresID DESC;
GO

--	Remove test data with old date
DELETE FROM Prescription
WHERE PresDateTime = '1999-01-01 10:00:00';
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 2	->	CAN VIEW PATIENT SENSITIVE DATA
SELECT PaymentCardNumber, PaymentCardPinCode 
FROM Patient;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 3	->	SYSTEM MISSING BACKUP PLAN
SELECT
    bs.database_name,
    bs.backup_start_date,
    bs.type AS backup_type,
    bmf.physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MedicalInfoSystem';

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 4	->	NURSE HAVE OVER ACCESS ON PATIENT INFORMATION
EXECUTE AS USER = 'ST002';
SELECT USER_NAME()
SELECT * FROM Patient; -- Should succeed, displaying all columns, including sensitive columns
REVERT;
GO

EXECUTE AS USER = 'ST006';
SELECT * FROM Patient; -- Should succeed, displaying all columns, including sensitive columns
REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 5	->	LACK OF TEMPORAL TABLE TO TRACK CHANGES
BEGIN TRY
    SELECT PID, PName, PPhone, ValidFrom, ValidTo
    FROM Patient
    FOR SYSTEM_TIME AS OF '2025-05-01 12:00:00';
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO	
--	Expected Result: Error indicating that Patient is not a system-versioned table.

--	Perform a change to show no history is tracked
UPDATE Patient SET PPhone = '60143247821' WHERE PID = 'PT005';
SELECT PID, PName, PPhone FROM Patient WHERE PID = 'PT005';
GO
--	Expected Result: PPhone is updated, but no history of the previous value is available.

----------------------------------------------------	NEXT	----------------------------------------------------

--	ISSUE 6	->
IF OBJECT_ID('dbo.AuditLog') IS NULL
	SELECT 'No audit table exists' AS AuditStatus;
ELSE
	SELECT * FROM AuditLog WHERE TableName IN ('Prescription', 'Appointment');
GO
--	Expected Result: Either 'No audit table exists' or empty result, indicating no audit logs.

--	Perform changes to show no audit
INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, [Status])
VALUES ('PT006', 'ST004', '2025-05-01 21:45:00', 'Cancelled');
UPDATE Prescription SET PresDateTime = '2025-05-04 12:00:00' WHERE PresID = 6;

BEGIN TRANSACTION;
DELETE FROM PrescriptionMedicine WHERE PresID = 1;
DELETE FROM Prescription WHERE PresID = 1;
COMMIT;

SELECT *FROM PRESCRIPTION;

---------------------------------------------------- SECTION BREAK ----------------------------------------------------
--+=============================================+	--	RUN SOLUTION 4.2
--|		        INSERT NEW VALUE			    |	--	EXCEPT PATIENT
--+=============================================+
INSERT INTO Medicine (MedID, MedName) VALUES
    ('MED001', 'Paracetamol 500mg'),
    ('MED002', 'Amoxicillin 250mg'),
    ('MED003', 'Ibuprofen 400mg'),
    ('MED004', 'Cetirizine 10mg'),
    ('MED005', 'Metformin 500mg'),
    ('MED006', 'Aspirin 100mg');
GO

INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, Status) VALUES
    ('PT001', 'ST001', '2025-04-01 10:00:00', 'New'),
    ('PT002', 'ST004', '2025-04-02 11:30:00', 'Dispensed'),
    ('PT003', 'ST001', '2025-04-03 09:15:00', 'Cancelled'),
    ('PT004', 'ST004', '2025-04-04 14:00:00', 'New'),
    ('PT005', 'ST001', '2025-04-05 16:45:00', 'Dispensed'),
    ('PT006', 'ST004', '2025-04-06 08:30:00', 'New');
GO

SELECT *FROM Prescription;	--	TO CONFIRM PRES ID INSERTING BY SYSTEM

INSERT INTO PrescriptionMedicine (PresID, MedID) VALUES
    (9, 'MED001'),
    (10, 'MED003'),
    (11, 'MED002'),
    (12, 'MED004'),
    (13, 'MED005'),
    (14, 'MED006');
GO

INSERT INTO Appointment (StaffID, PID, Date, [Status]) VALUES
    ('ST001', 'PT001', '2025-04-01 09:00:00', 'Done'),
    ('ST004', 'PT002', '2025-04-02 10:30:00', 'New'),
    ('ST001', 'PT003', '2025-04-03 11:00:00', 'Cancelled'),
    ('ST004', 'PT004', '2025-04-04 13:00:00', 'New'),
    ('ST001', 'PT005', '2025-04-05 15:00:00', 'Done'),
    ('ST004', 'PT006', '2025-04-06 08:00:00', 'New');
GO

---------------------------------------------------- SECTION BREAK ----------------------------------------------------
--+=============================================+
--|				    SOLUTION					|
--+=============================================+

--	STUDENT 1:	MUHAMMAD NABIL HAKIM BIN YUSAIDI
--	SOLUTION 1 ->	Implement a DML trigger to prevent duplicate appointments

CREATE TRIGGER TR_Prevent_Duplicate_Appointments
ON Appointment
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    --	Create a table variable (not a permanent table) to track which rows can be inserted
    DECLARE @ValidInserts TABLE (
        RowID INT IDENTITY(1,1),
        StaffID VARCHAR(6),
        PID VARCHAR(6),
        Date DATETIME,
        Status VARCHAR(10)
    );
    
    --	Identify valid (non-duplicate) inserts
    INSERT INTO @ValidInserts (StaffID, PID, Date, Status)
    SELECT i.StaffID, i.PID, i.Date, i.Status
    FROM inserted i
    WHERE NOT EXISTS (
        SELECT 1 
        FROM Appointment a
        WHERE a.PID = i.PID -- Same patient
        AND a.Status <> 'Cancelled' -- Only consider non-cancelled appointments
        AND (
            -- Check for overlapping time (within 30 minutes)
            (i.Date BETWEEN DATEADD(MINUTE, -30, a.Date) AND DATEADD(MINUTE, 30, a.Date))
        )
    );
    
    --	Insert only the valid (non-duplicate) records
    INSERT INTO Appointment (StaffID, PID, Date, Status)
    SELECT StaffID, PID, Date, Status FROM @ValidInserts;
    
    --	Log rejection information to SQL Server error log instead of a custom table
    IF @@ROWCOUNT < (SELECT COUNT(*) FROM inserted)
    BEGIN
        DECLARE @ErrorMsg NVARCHAR(MAX) = '';
        
        SELECT @ErrorMsg = @ErrorMsg + 
            'Duplicate appointment rejected: Patient ' + i.PID + 
            ' already has an appointment within 30 minutes of ' + 
            CONVERT(VARCHAR, i.Date, 120) + '. Attempted by StaffID: ' + i.StaffID + CHAR(13) + CHAR(10)
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM @ValidInserts v 
            WHERE v.StaffID = i.StaffID AND v.PID = i.PID AND v.Date = i.Date
        );
        
        --	Use RAISERROR with severity 10 (information only) to log to SQL Server error log
        RAISERROR(@ErrorMsg, 10, 1) WITH LOG;
        
        --	Return a result set with error information
        SELECT 
            i.StaffID, 
            i.PID, 
            i.Date,
            'Rejected - Duplicate Appointment' AS Status,
            'Patient already has an appointment within 30 minutes' AS Reason
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM @ValidInserts v 
            WHERE v.StaffID = i.StaffID AND v.PID = i.PID AND v.Date = i.Date
        );
    END
END;
GO

--	Create a stored procedure for scheduling appointments with validation
CREATE PROCEDURE usp_ScheduleAppointment
    @StaffID VARCHAR(6),
    @PID VARCHAR(6),
    @AppointmentDate DATETIME,
    @Status VARCHAR(10) = 'New'
AS
BEGIN
    SET NOCOUNT ON;
    
    --	Check for conflicts directly
    IF EXISTS (
        SELECT 1 
        FROM Appointment
        WHERE PID = @PID
        AND Status <> 'Cancelled'
        AND (@AppointmentDate BETWEEN DATEADD(MINUTE, -30, Date) AND DATEADD(MINUTE, 30, Date))
    )
    BEGIN
        --	Return error message
        SELECT 'ERROR: Cannot schedule appointment. Patient already has an appointment within 30 minutes of this time.' AS Message;
        RETURN -1;
    END
    ELSE
    BEGIN
        --	Schedule the appointment
        INSERT INTO Appointment (StaffID, PID, Date, Status)
        VALUES (@StaffID, @PID, @AppointmentDate, @Status);
        
        SELECT 'SUCCESS: Appointment scheduled successfully.' AS Message;
        RETURN 0;
    END
END;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 2 ->	Currently the Appointment table has no referential integrity constraints. The table structure allows appointments to be created with invalid patient IDs
--	Add a foreign key constraint to ensure appointments only reference valid patients
SELECT a.AppointmentID, a.PID 
FROM Appointment a
LEFT JOIN Patient p ON a.PID = p.PID
WHERE p.PID IS NULL;

--	Now add the foreign key constraint
ALTER TABLE Appointment
ADD CONSTRAINT FK_Appointment_Patient
FOREIGN KEY (PID) REFERENCES Patient(PID);

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 3 ->	Enable TDE / SSL / TLS on the MedicalInfoSystem database
USE MedicalInfoSystem;
GO

--	Create database encryption key
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE MedicalSystemTDECert;
GO

--	Turn on encryption for the database
ALTER DATABASE MedicalInfoSystem
SET ENCRYPTION ON;
GO

--	Configure SQL Server to use SSL/TLS for encrypted communications
USE master;
GO

--EXEC sp_configure 'show advanced options', 1;
--RECONFIGURE;
--EXEC sp_configure 'force encryption', 1;
--RECONFIGURE;
--GO

--	Backup the certificate and private key for disaster recovery
BACKUP CERTIFICATE MedicalSystemTDECert
TO FILE = 'D:\Certificates\MedicalSystemTDECert.cer'
WITH PRIVATE KEY (
    FILE = 'D:\Certificates\MedicalSystemTDECert.pvk',
    ENCRYPTION BY PASSWORD = 'StrongPrivateKeyPassword123!'
);
GO

--	Verify encryption status
SELECT DB_NAME(database_id) AS DatabaseName, 
       encryption_state, 
       CASE encryption_state
           WHEN 0 THEN 'No database encryption key present, no encryption'
           WHEN 1 THEN 'Unencrypted'
           WHEN 2 THEN 'Encryption in progress'
           WHEN 3 THEN 'Encrypted'
           WHEN 4 THEN 'Key change in progress'
           WHEN 5 THEN 'Decryption in progress'
           WHEN 6 THEN 'Protection change in progress'
           ELSE 'Unknown'
       END AS EncryptionState
FROM sys.dm_database_encryption_keys
WHERE DB_NAME(database_id) = 'MedicalInfoSystem';
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 4 ->	RBAC
--	Doctors: Update own details, manage prescriptions for their patients, check appointments
GRANT SELECT ON Patient TO Doctor;
GRANT SELECT, INSERT, UPDATE ON Prescription TO Doctor;
GRANT SELECT, INSERT ON PrescriptionMedicine TO Doctor;
GRANT SELECT ON Medicine TO Doctor;
GRANT SELECT ON Appointment TO Doctor;
GRANT SELECT, UPDATE ON Staff TO Doctor;

--	Pharmacists: Update own details, manage medicines, update prescription status
GRANT SELECT ON Patient TO Pharmacist;
GRANT SELECT, UPDATE ON Prescription TO Pharmacist;
GRANT SELECT, INSERT, UPDATE, DELETE ON Medicine TO Pharmacist;
GRANT SELECT, INSERT, UPDATE ON PrescriptionMedicine TO Pharmacist;
GRANT SELECT, UPDATE ON Staff TO Pharmacist;

--	Nurses: Update own details, manage appointments
GRANT SELECT ON Patient TO Nurse;
GRANT SELECT, INSERT, UPDATE ON Appointment TO Nurse;
GRANT SELECT, UPDATE ON Staff TO Nurse;

--	Patients: Update own details, manage appointments
GRANT SELECT ON Prescription TO Patient;
GRANT SELECT ON Appointment TO Patient;
GRANT SELECT, UPDATE ON Patient TO Patient;

--	System Admin: Full access to manage staff and patient records
GRANT CONTROL ON DATABASE::MedicalInfoSystem TO Admin;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 5 ->	Create a Server Audit to capture database activities
USE master;
GO

CREATE SERVER AUDIT MedicalSystemAudit
TO FILE 
(
    FILEPATH = 'D:\AuditLogs',
    MAXSIZE = 100MB,
    MAX_ROLLOVER_FILES = 10
)
WITH
(
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);
GO

--	Enable the server audit
ALTER SERVER AUDIT MedicalSystemAudit
WITH (STATE = ON);
GO

--	Create a Database Audit Specification to track DML operations on the Staff table
USE MedicalInfoSystem;
GO

CREATE DATABASE AUDIT SPECIFICATION StaffTableAudit
FOR SERVER AUDIT MedicalSystemAudit
ADD (DELETE ON Staff BY dbo),
ADD (UPDATE ON Staff BY dbo),
ADD (INSERT ON Staff BY dbo)
WITH (STATE = ON);
GO

--	Create a trigger to capture the details of the deleted data
CREATE PROCEDURE usp_DeleteStaff
    @StaffID VARCHAR(6)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variables to track dependencies
    DECLARE @HasPrescriptions INT = 0;
    DECLARE @HasAppointments INT = 0;
    DECLARE @DeletedBy VARCHAR(100) = SYSTEM_USER;
    DECLARE @DeletedDate DATETIME = GETDATE();
    
    -- Check for dependencies
    SELECT @HasPrescriptions = COUNT(*) FROM Prescription WHERE DoctorID = @StaffID;
    SELECT @HasAppointments = COUNT(*) FROM Appointment WHERE StaffID = @StaffID;
    
    -- If no dependencies, perform actual delete
    IF @HasPrescriptions = 0 AND @HasAppointments = 0
    BEGIN
        BEGIN TRY
            -- Log the data being deleted first (for audit trail)
            SELECT 
                'DELETED: StaffID=' + StaffID + 
                ', Name=' + SName + 
                ', Position=' + ISNULL(Position, 'NULL') + 
                ', Deleted By=' + @DeletedBy + 
                ', Deleted At=' + CONVERT(VARCHAR, @DeletedDate, 120) AS DeletedRecord
            FROM Staff 
            WHERE StaffID = @StaffID;
            
            -- Perform the actual delete
            DELETE FROM Staff WHERE StaffID = @StaffID;
            
            PRINT 'Staff record successfully deleted and logged.';
        END TRY
        BEGIN CATCH
            PRINT 'Error deleting staff record: ' + ERROR_MESSAGE();
        END CATCH
    END
    ELSE
    BEGIN
        --	Log the attempted deletion with dependency information
        SELECT 
            'DELETION BLOCKED: StaffID=' + @StaffID + 
            ', Attempted By=' + @DeletedBy + 
            ', Attempted At=' + CONVERT(VARCHAR, @DeletedDate, 120) + 
            ', Has Prescriptions=' + CONVERT(VARCHAR, @HasPrescriptions) + 
            ', Has Appointments=' + CONVERT(VARCHAR, @HasAppointments) AS BlockedDeletion;
            
        PRINT 'Cannot delete Staff record due to existing references.';
        PRINT 'Prescriptions: ' + CAST(@HasPrescriptions AS VARCHAR);
        PRINT 'Appointments: ' + CAST(@HasAppointments AS VARCHAR);
    END
END;
GO

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 2:	TAN SHI YING
--	SOLUTION 1 ->	Use Parameterized Queries
Create PROCEDURE GetStaffDetails
    @StaffID VARCHAR(6),
    @SName VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    --	Secure Query Using Parameters
    SELECT * FROM Staff WHERE StaffID = @StaffID AND SName = @SName;
END;
GO

--	Secure Patient Login Procedure
CREATE PROCEDURE ValidatePatientLogin
    @PID VARCHAR(6),
    @PPassportNumber VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

--	Prevent direct string execution
    SELECT PID, PName FROM Patient WHERE PID = @PID AND PPassportNumber = @PPassportNumber;
END;
GO

--	Secure Prescription Lookup for Doctors
CREATE PROCEDURE GetDoctorPrescriptions
    @DoctorID VARCHAR(6)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT PresID, PatientID, PresDateTime, Status
    FROM Prescription
    WHERE DoctorID = @DoctorID;
END;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 2 ->	
ALTER TABLE Patient ADD Encrypted_PPassportNumber VARBINARY(MAX);
ALTER TABLE Staff ADD Encrypted_SPassportNumber VARBINARY(MAX);

--	Create asymmetric key for passport number encryption
CREATE ASYMMETRIC KEY PassportAsymKey WITH ALGORITHM = RSA_2048;

--	Encrypt patient passport numbers
UPDATE Patient
SET Encrypted_PPassportNumber = ENCRYPTBYASYMKEY(
    ASYMKEY_ID('PassportAsymKey'),
    CONVERT(VARBINARY(256), PPassportNumber)
)
WHERE PPassportNumber IS NOT NULL;

-- Encrypt staff passport numbers
UPDATE Staff
SET Encrypted_SPassportNumber = ENCRYPTBYASYMKEY(
    ASYMKEY_ID('PassportAsymKey'),
    CONVERT(VARBINARY(256), SPassportNumber)
)
WHERE SPassportNumber IS NOT NULL;

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 3 ->	Restrict PROCESS to current_user_pid.
CREATE PROCEDURE ManageAppointment
    @UserID VARCHAR(6),         -- User attempting the action
    @ActionType VARCHAR(20),    -- 'View', 'Add', 'UpdateStatus'
    @DoctorID VARCHAR(6) = NULL,  -- Doctor assigned to the appointment
    @PID VARCHAR(6) = NULL,     -- Patient assigned to the appointment
    @AppointmentDate DATETIME = NULL, -- Appointment date
    @NewStatus VARCHAR(10) = NULL  -- Status update ('Done' or 'Cancelled')
AS
BEGIN
    SET NOCOUNT ON;

    -- Determine User Role
    DECLARE @UserRole VARCHAR(20);
    SELECT @UserRole = Position FROM Staff WHERE StaffID = @UserID;

    -- Validate ActionType
    IF @ActionType NOT IN ('View', 'Add', 'UpdateStatus')
    BEGIN
        RAISERROR ('Invalid ActionType. Use View, Add, or UpdateStatus.', 16, 1);
        RETURN;
    END

    -- VIEW Appointments
    IF @ActionType = 'View'
    BEGIN
        IF @UserRole = 'Doctor'
        BEGIN
            -- Doctors can view only their own appointments
            IF NOT EXISTS (SELECT 1 FROM Appointment WHERE StaffID = @UserID)
            BEGIN
                RAISERROR ('No appointments found for this doctor.', 16, 1);
                RETURN;
            END
            SELECT * FROM Appointment WHERE StaffID = @UserID;
        END
        ELSE IF @UserID IN (SELECT PID FROM Patient)
        BEGIN
            -- Patients can view only their own appointments
            IF NOT EXISTS (SELECT 1 FROM Appointment WHERE PID = @UserID)
            BEGIN
                RAISERROR ('No appointments found for this patient.', 16, 1);
                RETURN;
            END
            SELECT * FROM Appointment WHERE PID = @UserID;
        END
        ELSE IF @UserRole = 'Nurse'
        BEGIN
            -- Nurses can view all appointments
            IF NOT EXISTS (SELECT 1 FROM Appointment)
            BEGIN
                RAISERROR ('No appointments found.', 16, 1);
                RETURN;
            END
            SELECT * FROM Appointment;
        END
        ELSE
        BEGIN
            RAISERROR ('Access Denied: Only Doctors, Patients, or Nurses can view appointments.', 16, 1);
            RETURN;
        END
    END

    -- ADD New Appointment (Only Nurses)
    IF @ActionType = 'Add'
    BEGIN
        -- Ensure user is a Nurse
        IF @UserRole <> 'Nurse'
        BEGIN
            RAISERROR ('Access Denied: Only Nurses can add new appointments.', 16, 1);
            RETURN;
        END

        -- Ensure Doctor and Patient exist
        IF NOT EXISTS (SELECT 1 FROM Staff WHERE StaffID = @DoctorID AND Position = 'Doctor')
        BEGIN
            RAISERROR ('Error: Assigned Doctor does not exist.', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Patient WHERE PID = @PID)
        BEGIN
            RAISERROR ('Error: Assigned Patient does not exist.', 16, 1);
            RETURN;
        END

		-- Insert New Appointment
        INSERT INTO Appointment (StaffID, PID, Date, Status)
        VALUES (@DoctorID, @PID, @AppointmentDate, 'New');

        PRINT 'New appointment added successfully';
        RETURN;
    END

    -- UPDATE Appointment Status (Only Nurses, from 'New' to 'Done' or 'Cancelled')
    IF @ActionType = 'UpdateStatus'
    BEGIN
        -- Ensure user is a Nurse
        IF @UserRole <> 'Nurse'
        BEGIN
            RAISERROR ('Access Denied: Only Nurses can update appointment status.', 16, 1);
            RETURN;
        END

        -- Ensure Status is either 'Done' or 'Cancelled'
        IF @NewStatus NOT IN ('Done', 'Cancelled')
        BEGIN
            RAISERROR ('Error: Status can only be updated to Done or Cancelled.', 16, 1);
            RETURN;
        END

        -- Ensure Appointment Exists and is in 'New' Status
        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE StaffID = @DoctorID AND PID = @PID AND Date = @AppointmentDate)
        BEGIN
            RAISERROR ('Error: No matching appointment found.', 16, 1);
            RETURN;
        END

        -- Ensure Appointment is in 'New' status before updating
        IF NOT EXISTS (SELECT 1 FROM Appointment WHERE StaffID = @DoctorID AND PID = @PID AND Date = @AppointmentDate AND Status = 'New')
        BEGIN
            RAISERROR ('Error: Only appointments with "New" status can be updated.', 16, 1);
            RETURN;
        END

        -- Update Appointment Status
        UPDATE Appointment 
        SET Status = @NewStatus 
        WHERE StaffID = @DoctorID AND PID = @PID AND Date = @AppointmentDate;

        PRINT 'Appointment status updated successfully';
    END
END;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 4 ->	Use triggers to restrict edits.
CREATE PROCEDURE ManagePrescription
    @ActionType VARCHAR(20),  -- 'AddPrescription', 'UpdateStatus'
    @DoctorID VARCHAR(6),
    @PatientID VARCHAR(6) = NULL,
    @PresID INT = NULL,
    @NewStatus VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Ensure a valid action type is provided
    IF @ActionType NOT IN ('AddPrescription', 'UpdateStatus')
    BEGIN
        RAISERROR ('Invalid ActionType. Choose AddPrescription or UpdateStatus.', 16, 1);
        RETURN;
    END

    -- Check if the user is a doctor before proceeding
    IF NOT EXISTS (
        SELECT 1 FROM Staff WHERE StaffID = @DoctorID AND Position = 'Doctor'
    )
    BEGIN
        RAISERROR ('Access Denied: Only doctors can add or update prescriptions.', 16, 1);
        RETURN;
    END

    -- Action: Add a New Prescription
    IF @ActionType = 'AddPrescription'
    BEGIN
        -- Validate Patient
        IF NOT EXISTS (SELECT 1 FROM Patient WHERE PID = @PatientID)
        BEGIN
            RAISERROR ('Error: Patient does not exist', 16, 1);
            RETURN;
        END

        -- Check if another doctor has an active prescription for this patient
        IF EXISTS (
            SELECT 1 FROM Prescription 
            WHERE PatientID = @PatientID AND DoctorID <> @DoctorID AND Status = 'New'
        )
        BEGIN
            RAISERROR ('Access Denied: You can only prescribe for your own patients.', 16, 1);
            RETURN;
        END

        -- Insert new prescription
        INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, Status)
        VALUES (@PatientID, @DoctorID, GETDATE(), 'New');

        PRINT 'Prescription added successfully';
        RETURN;
    END

    -- Action: Update Prescription Status (Only to 'New' or 'Cancelled')
    IF @ActionType = 'UpdateStatus'
    BEGIN
        -- Validate Prescription Ownership
        IF NOT EXISTS (
            SELECT 1 FROM Prescription 
            WHERE PresID = @PresID AND DoctorID = @DoctorID
        )
        BEGIN
            RAISERROR ('Access Denied: You can only modify your own prescriptions.', 16, 1);
            RETURN;
        END

        -- Ensure Status is valid
        IF @NewStatus NOT IN ('New', 'Cancelled')
        BEGIN
            RAISERROR ('Error: Doctors can only update status to New or Cancelled.', 16, 1);
            RETURN;
        END

        -- Update the prescription status
        UPDATE Prescription 
        SET Status = @NewStatus 
        WHERE PresID = @PresID;

        PRINT 'Prescription status updated successfully';
        RETURN;
    END
END;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 5 ->	
USE master;
GO

CREATE SERVER AUDIT Audit_DDL_Changes
TO FILE (
    FILEPATH = 'D:\Temp\AuditLogs\',
    MAXSIZE = 10 MB
);
GO

ALTER SERVER AUDIT Audit_DDL_Changes WITH (STATE = ON);
GO

--	Create the Database-Level Audit Spec
USE MedicalInfoSystem;
GO

CREATE DATABASE AUDIT SPECIFICATION AuditDDLChanges
FOR SERVER AUDIT Audit_DDL_Changes
ADD (SCHEMA_OBJECT_CHANGE_GROUP);  -- This tracks CREATE, ALTER, DROP etc.
GO

ALTER DATABASE AUDIT SPECIFICATION AuditDDLChanges WITH (STATE = ON);
GO

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 3:	SOO JIUN GUAN
--	SOLUTION 1 ->	Apply dynamic data masking to patient phone numbers with role-based unmasking
ALTER TABLE Patient ALTER COLUMN PPhone VARCHAR(20);
GO
-- Add dynamic masking to original phone number columns

ALTER TABLE Patient
ALTER COLUMN PPhone ADD MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX",2)');
GO

-- Grant UNMASK to trusted roles (optional)
GRANT UNMASK TO Patient, Nurse;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 2 ->	Block staff from changing their job position unless they are in the Admin role
DROP TRIGGER IF EXISTS trg_PreventStaffChangePosition;
GO

CREATE TRIGGER trg_PreventStaffChangePosition
ON Staff
INSTEAD OF UPDATE
AS
BEGIN
    -- Block position change if not done by user in Admin role
    IF IS_MEMBER('Admin') <> 1 
       AND EXISTS (
            SELECT 1
            FROM inserted i
            JOIN deleted d ON i.StaffID = d.StaffID
            WHERE i.Position <> d.Position
       )
    BEGIN
        RAISERROR('Only admin is allowed to change staff position.', 16, 1);
        ROLLBACK;
        RETURN;
    END

    -- Allow updates to other fields
    UPDATE Staff
    SET
        SName = i.SName,
        SPhone = i.SPhone,
        SPassportNumber = i.SPassportNumber,
        Position = i.Position  -- Only allowed if user is in Admin role
    FROM inserted i
    WHERE Staff.StaffID = i.StaffID;
END;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 3 ->	Enable CDC (Change Data Capture) for auditing updates to Patient and Staff tables
USE MedicalInfoSystem;
GO

-- Disable CDC on the tables if enabled
IF EXISTS (
    SELECT 1 FROM cdc.change_tables 
    WHERE source_object_id = OBJECT_ID('dbo.Patient')
)
BEGIN
    EXEC sys.sp_cdc_disable_table 
        @source_schema = N'dbo', 
        @source_name = N'Patient', 
        @capture_instance = N'dbo_Patient';
END

IF EXISTS (
    SELECT 1 FROM cdc.change_tables 
    WHERE source_object_id = OBJECT_ID('dbo.Staff')
)
BEGIN
    EXEC sys.sp_cdc_disable_table 
        @source_schema = N'dbo', 
        @source_name = N'Staff', 
        @capture_instance = N'dbo_Staff';
END

-- Step 2: Disable CDC at database level if no other tables use it
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'MedicalInfoSystem' AND is_cdc_enabled = 1)
BEGIN
    EXEC sys.sp_cdc_disable_db;
END
GO

-- Enable CDC at the database level
EXEC sys.sp_cdc_enable_db;
GO

EXEC sys.sp_cdc_enable_table   
@source_schema = N'dbo', -- The schema where the table exists
@source_name   = N'Patient', -- The name of the table you want to track
@role_name     = N'Admin'; -- Role allowed to access the CDC data 

EXEC sys.sp_cdc_enable_table   
@source_schema = N'dbo',   
@source_name   = N'Staff',   
@role_name     = N'Admin';
GO

CREATE VIEW vw_Patient_Changes AS
SELECT 
    __$start_lsn       AS ChangeLSN,
    __$seqval          AS SequenceValue,
    __$operation       AS OperationType,
    __$update_mask     AS UpdateMask,
    PID,
    PName,
    PPassportNumber,
    PPhone,
    PaymentCardNumber,
    PaymentCardPinCode,
    __$command_id      AS CommandID
FROM cdc.dbo_Patient_CT;

CREATE VIEW vw_Staff_Changes AS
SELECT 
    __$start_lsn       AS ChangeLSN,
    __$seqval          AS SequenceValue,
    __$operation       AS OperationType,
    __$update_mask     AS UpdateMask,
    StaffID,
    SName,
    SPassportNumber,
    SPhone,
    Position,
    __$command_id      AS CommandID
FROM cdc.dbo_Staff_CT;
GO

-- Restrict access to Admin only
REVOKE SELECT ON vw_Staff_Changes FROM PUBLIC;
GRANT SELECT ON vw_Staff_Changes TO Admin;
REVOKE SELECT ON vw_Patient_Changes FROM PUBLIC;
GRANT SELECT ON vw_Patient_Changes TO Admin;
REVOKE SELECT ON cdc.dbo_Patient_CT FROM PUBLIC;
REVOKE SELECT ON cdc.dbo_Staff_CT FROM PUBLIC;
GRANT SELECT ON cdc.dbo_Patient_CT TO Admin;
GRANT SELECT ON cdc.dbo_Staff_CT TO Admin;

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 4 ->	 Enforce row-level security to restrict staff and patient access to their own records
-- Disable and drop existing security policies if they exist
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'StaffRowFilter')
BEGIN
    ALTER SECURITY POLICY StaffRowFilter WITH (STATE = OFF);
    DROP SECURITY POLICY StaffRowFilter;
END
GO

IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'PatientRowFilter')
BEGIN
    ALTER SECURITY POLICY PatientRowFilter WITH (STATE = OFF);
    DROP SECURITY POLICY PatientRowFilter;
END
GO

-- Drop the filter functions if they exist
IF OBJECT_ID('dbo.fn_RLS_StaffOwnRecord', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_RLS_StaffOwnRecord;
GO

IF OBJECT_ID('dbo.fn_RLS_PatientOwnRecord', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_RLS_PatientOwnRecord;
GO

-- Create function to allow staff themselves
CREATE FUNCTION dbo.fn_RLS_StaffOwnRecord (@StaffID AS VARCHAR(6))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN 
	SELECT 1 AS result
	WHERE USER_NAME() = @StaffID
	OR IS_MEMBER('Admin') = 1;
GO

-- Create the security policy to enforce filtering and blocking
CREATE SECURITY POLICY StaffRowFilter
ADD FILTER PREDICATE dbo.fn_RLS_StaffOwnRecord(StaffID) ON dbo.Staff,
ADD BLOCK PREDICATE dbo.fn_RLS_StaffOwnRecord(StaffID) ON dbo.Staff
WITH (STATE = ON);
GO

-- Create function to allow patient themselves and nurse role
CREATE FUNCTION dbo.fn_RLS_PatientOwnRecord (@PID AS VARCHAR(6))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN 
    SELECT 1 AS result
    WHERE USER_NAME() = @PID  -- patient sees own record
       OR IS_MEMBER('Nurse') = 1  -- nurse sees all
	   OR IS_MEMBER('Admin') = 1;
GO

CREATE SECURITY POLICY PatientRowFilter
ADD FILTER PREDICATE dbo.fn_RLS_PatientOwnRecord(PID) ON dbo.Patient,
ADD BLOCK PREDICATE dbo.fn_RLS_PatientOwnRecord(PID) ON dbo.Patient
WITH (STATE = ON);
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 5 ->	Restrict prescription status modification via stored procedure for pharmacists
DROP PROCEDURE IF EXISTS usp_UpdatePrescriptionStatus;
GO

REVOKE UPDATE ON Prescription TO Pharmacist;
GO

CREATE PROCEDURE usp_UpdatePrescriptionStatus
    @PresID INT,
    @NewStatus VARCHAR(10),
    @UserID VARCHAR(6)
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the user is a pharmacist
    IF NOT EXISTS (
        SELECT 1 FROM Staff 
        WHERE StaffID = @UserID AND Position = 'Pharmacist'
    )
    BEGIN
        RAISERROR('Access Denied: Only pharmacists can update prescription status.', 16, 1);
        RETURN;
    END

    -- Validate that the prescription exists
    IF NOT EXISTS (
        SELECT 1 FROM Prescription WHERE PresID = @PresID
    )
    BEGIN
        RAISERROR('Error: Prescription ID does not exist.', 16, 1);
        RETURN;
    END

    -- Allow update of Status only
    UPDATE Prescription
    SET Status = @NewStatus
    WHERE PresID = @PresID;

    PRINT 'Prescription status updated successfully.';
END;
GO

GRANT EXECUTE ON usp_UpdatePrescriptionStatus TO Pharmacist;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 6 ->	 Implement server-level logon auditing with a trigger and store logs in a custom table.
-- Create audit table in MedicalInfoSystem
USE MedicalInfoSystem;
GO

DROP TABLE IF EXISTS dbo.LogonAudit;
GO

CREATE TABLE LogonAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    LoginName NVARCHAR(100),
    HostName NVARCHAR(100),
    AppName NVARCHAR(100),
    LoginTime DATETIME DEFAULT GETDATE()
);
GO

-- Switch to master to create server-level trigger
USE master;
GO

-- Drop existing trigger if it exists
IF EXISTS (SELECT * FROM sys.server_triggers WHERE name = 'trg_LogonAudit_HospitalSystem')
    DROP TRIGGER trg_LogonAudit_HospitalSystem ON ALL SERVER;
GO

-- Create a server-level logon trigger that only logs logins into MedicalInfoSystem
CREATE TRIGGER trg_LogonAudit_HospitalSystem
ON ALL SERVER
WITH EXECUTE AS SELF
FOR LOGON
AS
BEGIN
    BEGIN TRY
        DECLARE @dbname NVARCHAR(128);
        IF ORIGINAL_LOGIN() <> 'sa' 
        BEGIN
            -- Prevent duplicates within short period
            IF NOT EXISTS (
                SELECT 1 FROM MedicalInfoSystem.dbo.LogonAudit
                WHERE LoginName = ORIGINAL_LOGIN()
                  AND DATEDIFF(SECOND, LoginTime, GETDATE()) <= 3
            )
            BEGIN
                INSERT INTO MedicalInfoSystem.dbo.LogonAudit (
                    LoginName,
                    HostName,
                    AppName
                )
                VALUES (
                    ORIGINAL_LOGIN(),
                    HOST_NAME(),
                    APP_NAME()
                );
            END
        END
    END TRY
    BEGIN CATCH
        -- Avoid blocking logins on failure
    END CATCH
END;
GO

-- Revoke access from PUBLIC
USE MedicalInfoSystem;
GO
REVOKE SELECT ON dbo.LogonAudit FROM PUBLIC;
GO

-- Allow only Admin role to view logon logs
GRANT SELECT ON dbo.LogonAudit TO Admin;
GO

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 4:	TEH YUE FENG
--	SOLUTION 1 ->	Prevent insertion of backdated prescriptions using a trigger
DROP TRIGGER IF EXISTS trg_BlockBackdatedPrescription;
GO

CREATE TRIGGER trg_BlockBackdatedPrescription
ON Prescription
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE PresDateTime < GETDATE())
    BEGIN
        RAISERROR('Backdated prescriptions are not allowed.', 16, 1);
        ROLLBACK;
        RETURN;
    END

    INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, Status)
    SELECT PatientID, DoctorID, PresDateTime, Status
    FROM inserted;
END;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 2 ->	DATA HASHING ON PATIENT SENSITIVE DATA
ALTER TABLE Patient 
    DROP COLUMN PaymentCardNumber;
ALTER TABLE Patient 
    ADD PaymentCardNumber VARBINARY(MAX);
GO

ALTER TABLE Patient 
    DROP COLUMN PaymentCardPinCode;
ALTER TABLE Patient 
    ADD PaymentCardPinCode VARBINARY(MAX);
GO

DELETE FROM PrescriptionMedicine;
DELETE FROM Appointment;
DELETE FROM Prescription;
DELETE FROM Patient;
DELETE FROM Medicine;
GO

INSERT INTO Patient (PID, PName, PPassportNumber, PPhone, PaymentCardNumber, PaymentCardPinCode) VALUES
    ('PT001', 'Alice Tan', 'P1234567X', '60123456788', HASHBYTES('SHA2_256', '2736251728391029'), HASHBYTES('SHA2_256', '1344')),
    ('PT002', 'Bob Chan', 'P2345678Y', '60198765433', HASHBYTES('SHA2_256', '1274625172839128'), HASHBYTES('SHA2_256', '3481')),
    ('PT003', 'Clara Ng', 'P3456789Z', '60187654322', HASHBYTES('SHA2_256', '1226351728391023'), HASHBYTES('SHA2_256', '9012')),
    ('PT004', 'David Lim', 'P4567890W', '60176543211', HASHBYTES('SHA2_256', '3627182910391827'), HASHBYTES('SHA2_256', '3317')),
    ('PT005', 'Emma Soh', 'P5678901V', '60165432100', HASHBYTES('SHA2_256', '9203726152716273'), HASHBYTES('SHA2_256', '7890')),
    ('PT006', 'Frank Teo', 'P6789012U', '60154321099', HASHBYTES('SHA2_256', '1472839172647182'), HASHBYTES('SHA2_256', '1447'));
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 3 ->	
--	EXECUTE A NORMAL BACKUP DATABASE
BACKUP DATABASE MedicalInfoSystem
TO DISK = 'D:\Backup\Full\MedicalInfoSystem_FULL_20250501.bak'
WITH INIT, STATS = 10;
GO

--	CONFIRM DATABASE IS IN FULL RECOVERY
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'MedicalInfoSystem';

--
EXEC master.dbo.xp_create_subdir 'D:\Backup\Full';
EXEC master.dbo.xp_create_subdir 'D:\Backup\Differential';
EXEC master.dbo.xp_create_subdir 'C:\Backup\Log';
GO

USE msdb;
GO
--	Create or Update Full Backup Job
IF EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name = N'AutoFullBackupJob')
    EXEC msdb.dbo.sp_delete_job @job_name = N'AutoFullBackupJob';
EXEC sp_add_job @job_name = N'AutoFullBackupJob';

--	Add Job Step
EXEC sp_add_jobstep 
    @job_name = N'AutoFullBackupJob',
    @step_name = N'FullBackupStep',
    @subsystem = N'TSQL',
    @command = N'
    DECLARE @File NVARCHAR(200);
    SET @File = ''D:\Backup\Full\FullBackup_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + ''.bak'';
    BACKUP DATABASE MedicalInfoSystem TO DISK = @File WITH INIT, STATS = 10;
    ',
    @database_name = N'master';

--	Create Schedule (Every 12 hours at 02:00 and 14:00)
IF EXISTS (SELECT name FROM msdb.dbo.sysschedules WHERE name = N'FullBackup_Every12Hours')
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'FullBackup_Every12Hours';
EXEC sp_add_schedule 
    @schedule_name = N'FullBackup_Every12Hours',
    @enabled = 1,
    @freq_type = 4, -- Daily
    @freq_interval = 1, -- Every day
    @freq_subday_type = 8, -- Every X hours
    @freq_subday_interval = 12, -- Every 12 hours
    @active_start_time = 20000; -- Start at 02:00

--	Attach Schedule to Job
EXEC sp_attach_schedule 
    @job_name = N'AutoFullBackupJob',
    @schedule_name = N'FullBackup_Every12Hours';

--	Register Job
EXEC sp_add_jobserver @job_name = N'AutoFullBackupJob';
GO


--	Create or Update Differential Backup Job
IF EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name = N'AutoDiffBackupJob')
    EXEC msdb.dbo.sp_delete_job @job_name = N'AutoDiffBackupJob';
EXEC sp_add_job @job_name = N'AutoDiffBackupJob';

--	Add Job Step
EXEC sp_add_jobstep 
    @job_name = N'AutoDiffBackupJob',
    @step_name = N'DiffBackupStep',
    @subsystem = N'TSQL',
    @command = N'
    DECLARE @File NVARCHAR(200);
    SET @File = ''D:\Backup\Differential\DiffBackup_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + ''.bak'';
    BACKUP DATABASE MedicalInfoSystem TO DISK = @File WITH DIFFERENTIAL, INIT, STATS = 10;
    ',
    @database_name = N'master';

--	Create Schedule (Every 6 hours at 00:00, 06:00, 12:00, 18:00)
IF EXISTS (SELECT name FROM msdb.dbo.sysschedules WHERE name = N'DiffBackup_Every6Hours')
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'DiffBackup_Every6Hours';
EXEC sp_add_schedule 
    @schedule_name = N'DiffBackup_Every6Hours',
    @enabled = 1,
    @freq_type = 4, -- Daily
    @freq_interval = 1, -- Every day
    @freq_subday_type = 8, -- Every X hours
    @freq_subday_interval = 6, -- Every 6 hours
    @active_start_time = 000000; -- Start at 00:00

--	Attach Schedule to Job
EXEC sp_attach_schedule 
    @job_name = N'AutoDiffBackupJob',
    @schedule_name = N'DiffBackup_Every6Hours';

--	Register Job
EXEC sp_add_jobserver @job_name = N'AutoDiffBackupJob';
GO


--	Create or Update Transaction Log Backup Job
IF EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name = N'AutoLogBackupJob')
    EXEC msdb.dbo.sp_delete_job @job_name = N'AutoLogBackupJob';
EXEC msdb.dbo.sp_add_job 
    @job_name = N'AutoLogBackupJob',
    @enabled = 1,
    @description = N'Automatically backs up transaction log every 3 hours.';

--	Add Job Step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'AutoLogBackupJob',
    @step_name = N'LogBackupStep',
    @subsystem = N'TSQL',
    @command = N'
    DECLARE @File NVARCHAR(255);
    SET @File = ''D:\Backup\TransactionLog\LogBackup_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + ''.trn'';
    BACKUP LOG MedicalInfoSystem TO DISK = @File WITH INIT, STATS = 10;
    ',
    @database_name = N'master';

--	Create Schedule (Every 3 hours at 00:00, 03:00, 06:00, 09:00, 12:00, 15:00, 18:00, 21:00)
IF EXISTS (SELECT name FROM msdb.dbo.sysschedules WHERE name = N'LogBackup_Every3Hours')
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'LogBackup_Every3Hours';
EXEC msdb.dbo.sp_add_schedule 
    @schedule_name = N'LogBackup_Every3Hours',
    @enabled = 1,
    @freq_type = 4, -- Daily
    @freq_interval = 1, -- Every day
    @freq_subday_type = 8, -- Every X hours
    @freq_subday_interval = 3, -- Every 3 hours
    @active_start_time = 000000; -- Start at 00:00

--	Attach Schedule to Job
EXEC msdb.dbo.sp_attach_schedule 
    @job_name = N'AutoLogBackupJob',
    @schedule_name = N'LogBackup_Every3Hours';

--	Register Job
EXEC msdb.dbo.sp_add_jobserver @job_name = N'AutoLogBackupJob';
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 4 ->	DENYING NURSE TO VIEW SENSITIVE DATA COLUMN OF PATIENT
USE MedicalInfoSystem;
GO

IF OBJECT_ID('dbo.PatientNonSensitiveView') IS NOT NULL
    DROP VIEW dbo.PatientNonSensitiveView;
GO

CREATE VIEW dbo.PatientNonSensitiveView
WITH SCHEMABINDING
AS
SELECT PID, PName, PPassportNumber, PPhone
FROM dbo.Patient;
GO

--	Grant view permissions and deny access to sensitive columns and updates
GRANT SELECT ON dbo.PatientNonSensitiveView TO Nurse;
DENY SELECT ON Patient(PaymentCardNumber, PaymentCardPinCode) TO Nurse;
DENY UPDATE ON Patient TO Nurse;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 5 ->	
--	ADD TEMPORAL COLUMN
ALTER TABLE Patient
ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL
	DEFAULT '2025-01-01 00:00:00',
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL
	DEFAULT '9999-12-31 23:59:59.9999999',
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO

ALTER TABLE Medicine
ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL
	DEFAULT '2025-01-01 00:00:00',
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL
	DEFAULT '9999-12-31 23:59:59.9999999',
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO

ALTER TABLE Staff
ADD ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL
	DEFAULT '2025-01-01 00:00:00',
	ValidTo DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL
	DEFAULT '9999-12-31 23:59:59.9999999',
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO

--	ENABLE SYSTEM VERSIONING FOR PATIENT, STAFF, AND MEDICINE
ALTER TABLE Patient
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.PatientHistory));
GO
ALTER TABLE Staff
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.StaffHistory));
GO
ALTER TABLE Medicine
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.MedicineHistory));
GO
--	Expected Result: Temporal tables enabled for Patient, Medicine, and Staff, 
--	with history tables PatientHistory, MedicineHistory, and StaffHistory created.

----------------------------------------------------	NEXT	----------------------------------------------------

--	SOLUTION 6 ->	
IF OBJECT_ID('dbo.AuditLog') IS NOT NULL
    DROP TABLE dbo.AuditLog;
GO

CREATE TABLE AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName VARCHAR(50),
    Operation VARCHAR(10),
    RecordID VARCHAR(10),
    ChangedColumns NVARCHAR(MAX), -- JSON to store old and new values
    ChangedBy VARCHAR(128),
    ChangedAt DATETIME
);
GO

REVOKE SELECT ON dbo.AuditLog FROM PUBLIC;
GO
--	Grant SELECT only to Admin Role
GRANT SELECT ON dbo.AuditLog TO Admin;
GO

--	Create trigger for Prescription
IF OBJECT_ID('trg_Prescription_Audit') IS NOT NULL
    DROP TRIGGER trg_Prescription_Audit;
GO

CREATE TRIGGER trg_Prescription_Audit
ON Prescription
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operation VARCHAR(10);
    DECLARE @ChangedColumns NVARCHAR(MAX);

    -- Determine operation
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Operation = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Operation = 'INSERT';
    ELSE
        SET @Operation = 'DELETE';

    -- For INSERT and UPDATE, capture new values; for DELETE, capture old values
    IF @Operation IN ('INSERT', 'UPDATE')
        SELECT @ChangedColumns = (
            SELECT 
                PresID, 
                PatientID, 
				DoctorID,
                PresDateTime,
				[Status]
            FROM inserted
            FOR JSON PATH
        );
    ELSE
        SELECT @ChangedColumns = (
            SELECT 
                PresID, 
                PatientID, 
				DoctorID,
                PresDateTime,
				[Status]
            FROM deleted
            FOR JSON PATH
        );

    -- Insert audit log
    INSERT INTO AuditLog (TableName, Operation, RecordID, ChangedColumns, ChangedBy, ChangedAt)
    SELECT 
        'Prescription',
        @Operation,
        COALESCE(i.PresID, d.PresID),
        @ChangedColumns,
        SUSER_SNAME(),
        GETDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.PresID = d.PresID;
END;
GO

--	Create trigger for Appointment
IF OBJECT_ID('trg_Appointment_Audit') IS NOT NULL
    DROP TRIGGER trg_Appointment_Audit;
GO

CREATE TRIGGER trg_Appointment_Audit
ON Appointment
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operation VARCHAR(10);
    DECLARE @ChangedColumns NVARCHAR(MAX);

    -- Determine operation
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @Operation = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @Operation = 'INSERT';
    ELSE
        SET @Operation = 'DELETE';

    -- For INSERT and UPDATE, capture new values; for DELETE, capture old values
    IF @Operation IN ('INSERT', 'UPDATE')
        SELECT @ChangedColumns = (
            SELECT 
                StaffID, 
                PID, 
                Date, 
                [Status]
            FROM inserted
            FOR JSON PATH
        );
    ELSE
        SELECT @ChangedColumns = (
            SELECT 
                StaffID, 
                PID, 
                Date, 
                [Status]
            FROM deleted
            FOR JSON PATH
        );

    -- Insert audit log
    INSERT INTO AuditLog (TableName, Operation, RecordID, ChangedColumns, ChangedBy, ChangedAt)
    SELECT 
        'Appointment',
        @Operation,
        COALESCE(i.StaffID, d.StaffID),
        @ChangedColumns,
        SUSER_SNAME(),
        GETDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.StaffID = d.StaffID;
END;
GO

---------------------------------------------------- SECTION BREAK ----------------------------------------------------

--+=============================================+
--|				 PROOF SOLUTION					|
--+=============================================+

--	STUDENT 1:	MUHAMMAD NABIL HAKIM BIN YUSAIDI
--	TESTING 1 ->	Doctor attempts to create a duplicate appointment

--	Attempt 1: First appointment (succeeds)
EXEC usp_ScheduleAppointment 'ST001', 'PT001', '2025-05-10 09:00:00', 'New';
-- Result: "SUCCESS: Appointment scheduled successfully."

--	Attempt 2: Duplicate appointment (fails)
EXEC usp_ScheduleAppointment 'ST004', 'PT001', '2025-05-10 09:00:00', 'New';
-- Result: "ERROR: Cannot schedule appointment. Patient already has an appointment within 30 minutes of this time."

--	Attempt 3: Same patient, different time (succeeds)
EXEC usp_ScheduleAppointment 'ST004', 'PT001', '2025-05-10 14:00:00', 'New';
-- Result: "SUCCESS: Appointment scheduled successfully."

--	If someone tries to insert directly (bypassing the procedure):
INSERT INTO Appointment (StaffID, PID, Date, Status)
VALUES ('ST001', 'PT001', '2025-05-10 09:15:00', 'New');

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 2 ->	After adding the constraint, any attempt to add an appointment with invalid PID will fail:

--	This will succeed (valid patient):
INSERT INTO Appointment (StaffID, PID, Date, Status)
VALUES ('ST001', 'PT001', '2025-05-20 10:00:00', 'New');

--	This will fail (invalid patient):
INSERT INTO Appointment (StaffID, PID, Date, Status)
VALUES ('ST001', 'PT999', '2025-05-20 11:00:00', 'New');

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 3 ->	After implementing TDE and SSL/TLS:
-- 1. All data stored on disk is now encrypted
-- The database files (.mdf, .ldf) are encrypted on disk

-- 2. All data transmitted over the network is encrypted
-- Client-server communications are protected by SSL/TLS

-- 3. All database backups are encrypted automatically
-- If a backup file is stolen, the data remains protected

-- 4. When querying the database, authorized users still see the data normally:
SELECT * FROM Patient;
-- Results appear as normal to authorized users, but the underlying
-- storage is encrypted

-- 5. Encryption status check shows the database is fully encrypted:
-- DatabaseName       EncryptionState
-- MedicalInfoSystem  Encrypted

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 4 ->	EACH ROLE HAVE EACH ACCESS AND EACH RESTRICT
EXECUTE AS USER = 'ST001'
--	Doctor (ST001) logs in:
--	Can view patient information
SELECT * FROM Patient; -- Succeeds
--	Can create and update prescriptions
INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, Status)
VALUES ('PT001', 'ST001', GETDATE(), 'New'); -- Succeeds
--	Cannot modify medicine inventory
UPDATE Medicine SET MedName = 'New Name' WHERE MedID = 'MED001'; -- Fails with permission error
REVERT;
GO

EXECUTE AS USER = 'ST003'
--	Pharmacist (ST003) logs in:
--	Can update prescription status
UPDATE Prescription SET Status = 'Dispensed' WHERE PresID = 1; -- Succeeds
--	Can manage medicines
INSERT INTO Medicine VALUES ('MED007', 'New Medication'); -- Succeeds
--	Cannot create new prescriptions
INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, Status)
VALUES ('PT001', 'ST001', GETDATE(), 'New'); -- Fails with permission error
REVERT;
GO

EXECUTE AS USER = 'ST002'
--	Nurse (ST002) logs in:
--	Can manage appointments
INSERT INTO Appointment (StaffID, PID, Date, Status)
VALUES ('ST001', 'PT001', GETDATE(), 'New'); -- Succeeds
--	Cannot modify prescriptions
UPDATE Prescription SET Status = 'Dispensed' WHERE PresID = 1;
REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 5 ->	Now when an admin tries to delete a staff record;
EXEC usp_DeleteStaff 'ST001';

--	The procedure will:
--	1. First check if deletion is possible
--	2. If possible, log the data and then delete it
--	3. If not possible, log the attempted deletion with reason
--	4. The SQL Server Audit will capture all these activities

--	To view all audit records:
 SELECT * FROM sys.fn_get_audit_file ('D:\AuditLogs', DEFAULT, DEFAULT);

-- To specifically see staff deletion attempts (successful or not):
 SELECT event_time, server_principal_name, statement 
 FROM sys.fn_get_audit_file ('D:\AuditLogs', DEFAULT, DEFAULT)
 WHERE action_id IN ('EX', 'DL') AND 
       (object_name = 'Staff' OR object_name = 'usp_DeleteStaff');

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 2:	TAN SHI YING
--	TESTING 1 ->	Staff Details Lookup
--	Secure version using parameterized query
EXEC GetStaffDetails @StaffID = 'ST001'' OR ''1''=''1', @SName = '';
EXEC GetStaffDetails @StaffID = 'ST001', @SName = 'Jerremy Lim';

--	Test Case 2: Patient Login--
--	Secure call using parameters
EXEC ValidatePatientLogin @PID = 'PT001'' OR ''1''=''1', @PPassportNumber = 'any';
EXEC ValidatePatientLogin @PID = 'PT001' , @PPassportNumber = 'P1234567X';

--	Test Case 3: Doctor Prescription Lookup--
 EXEC GetDoctorPrescriptions @DoctorID = 'ST001'' OR ''1''=''1';
 EXEC GetDoctorPrescriptions @DoctorID = 'ST001';

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 2 ->	 VIEW ENCRYPTED VALUES
--	View encrypted values in Patient table
SELECT 
    PID, 
    Encrypted_PPassportNumber 
FROM Patient;

--	View encrypted values in Staff table
SELECT 
    StaffID, 
    Encrypted_SPassportNumber 
FROM Staff;

--	View decrypted patient passport
SELECT 
    PID,
    CONVERT(VARCHAR(50), DECRYPTBYASYMKEY(
        ASYMKEY_ID('PassportAsymKey'), Encrypted_PPassportNumber)) AS DecryptedPassport
FROM Patient;

--	View decrypted staff passports
SELECT 
    StaffID,
    CONVERT(VARCHAR(50), DECRYPTBYASYMKEY(
        ASYMKEY_ID('PassportAsymKey'), Encrypted_SPassportNumber)) AS DecryptedPassport
FROM Staff;

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 3 ->	
--	1.	Patient can only view their own appointments
EXEC ManageAppointment 
    @UserID = 'PT001', 
    @ActionType = 'View';

--	2.	Nurse adds a new appointment
EXEC ManageAppointment 
    @UserID = 'ST006', 
    @ActionType = 'Add',
    @DoctorID = 'ST001',
    @PID = 'PT001',
    @AppointmentDate = '2025-05-06 10:00:00';

--	3.	Nurse tries to insert a duplicate appointment
EXEC ManageAppointment 
    @UserID = 'ST006', 
    @ActionType = 'Add',
    @DoctorID = 'ST001',
    @PID = 'PT001',
    @AppointmentDate = '2025-05-06 10:00:00';

--	4.	Doctor tries to update appointment status (not allowed)
EXEC ManageAppointment 
    @UserID = 'ST001', 
    @ActionType = 'UpdateStatus',
    @DoctorID = 'ST001',
    @PID = 'PT001',
    @AppointmentDate = '2025-05-06 10:00:00',
    @NewStatus = 'Done';

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 4 ->	ACCESS ON PRESCRIPTION TABLE FROM PHARMACIST AND DOCTOR
--	TEST 1	->	Pharmacist cannot add prescription 
EXEC ManagePrescription 
    @ActionType = 'AddPrescription',
    @DoctorID = 'ST003',  -- Pharmacist
    @PatientID = 'PT003';

--	TEST 2	->	Doctor can only add prescription for his own patient
EXEC ManagePrescription 
    @ActionType = 'AddPrescription',
    @DoctorID = 'ST001',  -- Doctor
    @PatientID = 'PT004';

--	TEST 3	->	Doctor cancels prescription
EXEC ManagePrescription 
    @ActionType = 'UpdateStatus',
    @DoctorID = 'ST001',
    @PresID = 1,
    @NewStatus = 'Cancelled';

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 5 ->	
--	Run any DDL action to test
ALTER TABLE Staff ADD TestAuditColumn INT;
GO

--	View the Audit Logs
SELECT *
FROM sys.fn_get_audit_file('D:\Temp\AuditLogs\*', DEFAULT, DEFAULT);

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 3:	SOO JIUN GUAN
--	TESTING 1 ->	Patients and nurses can view unmasked phone number 
-- Test as Nurse: should see all patients
EXECUTE AS USER = 'ST002';
SELECT PID, PPhone FROM Patient;
REVERT;
GO

-- Test as Patient: should see own record only
EXECUTE AS USER = 'PT003';
SELECT PID, PPhone FROM Patient;
REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 2 ->	Staff attempts to change their own position
EXECUTE AS USER = 'ST006';
BEGIN TRY
    UPDATE Staff SET Position = 'Doctor' WHERE StaffID = 'ST006'; -- ST006 is nurse
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); -- Expect: Only admin is allowed to change staff position.
END CATCH;
REVERT;
GO

EXECUTE AS USER = 'AD001';  -- ST006 is a nurse, not admin
BEGIN TRY
    UPDATE Staff SET Position = 'Nurse' WHERE StaffID = 'ST006';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();  -- Expect: Only admin is allowed to change staff position.
END CATCH;
REVERT;
GO

-- View the current position after the update
EXECUTE AS USER = 'ST006';
SELECT StaffID, Position AS CurrentPosition 
FROM Staff 
REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 3 ->	Admin views CDC log for patient changes
EXECUTE AS USER = 'PT002';
GO
-- Update the patient's phone number
UPDATE Patient 
SET PPhone = '+60110909310' 
WHERE PID = 'PT002';
REVERT;
GO

EXECUTE AS USER = 'AD001';
-- View captured CDC changes
SELECT TOP 5 * 
FROM vw_Patient_Changes
ORDER BY ChangeLSN DESC;
REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 4 ->	Patients and Staffs view their own personal information only
EXECUTE AS USER = 'ST003';
SELECT * FROM Staff;
REVERT;
GO

EXECUTE AS USER = 'PT002';
SELECT * FROM Patient;
REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 5 ->	Pharmacist restricted to updating prescription status only
EXECUTE AS USER = 'ST003'; -- pharmacists
EXEC usp_UpdatePrescriptionStatus
    @PresID = 3,
    @NewStatus = 'Dispensed',
    @UserID = 'ST003';
	REVERT;
GO

EXECUTE AS USER = 'ST003';
BEGIN TRY
    -- Attempt to update the DoctorID directly (this should fail)
    UPDATE Prescription
    SET DoctorID = 'ST004'
    WHERE PresID = 3;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();  -- Expect: The UPDATE permission was denied
END CATCH;
REVERT;
GO

EXECUTE AS USER = 'ST003';
SELECT * FROM Prescription
WHERE PresID = 3;
REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 6 ->	Admin views the logon audit table
USE MedicalInfoSystem;
GO

EXECUTE AS USER = 'AD001';
SELECT TOP 20 *
FROM dbo.LogonAudit
ORDER BY LoginTime DESC;
REVERT;
GO

---------------------------------------------------- NEXT STUDENT ----------------------------------------------------

--	STUDENT 4:	TEH YUE FENG

--	TESTING 1 ->	Insert a backdated prescription

EXECUTE AS USER = 'ST001';  -- doctor
BEGIN TRY
    INSERT INTO Prescription (PatientID, DoctorID, PresDateTime, Status)
    VALUES ('PT001', 'ST001', '1999-01-01 10:00:00', 'New');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); -- Expect: Backdated prescriptions are not allowed.
END CATCH;
REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 2 ->	SELECT PATIENT COLUMN DATA
SELECT 
    PID, 
    PName, 
    PPhone,
    PaymentCardNumber, 
    PaymentCardPinCode
FROM Patient;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 3 ->	CHECK BACKUP HISTORY
SELECT 
	database_name,
	backup_start_date,
	backup_finish_date,
	type AS backup_type,
	CASE type 
		WHEN 'D' THEN 'Full'
		WHEN 'I' THEN 'Differential'
		WHEN 'L' THEN 'Transaction Log'
		ELSE 'Other'
	END AS backup_type_desc,
	physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf
	ON bs.media_set_id = bmf.media_set_id
WHERE database_name = 'MedicalInfoSystem'
ORDER BY backup_finish_date DESC;

SELECT 
	h.run_date,
	h.run_time,
	h.step_id,
	h.step_name,
	h.sql_message_id,
	h.message,
	h.run_status,  -- 1 = Success, 0 = Failed
	h.run_duration,
	j.name AS job_name
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j
	ON h.job_id = j.job_id
WHERE j.name IN ('AutoFullBackupJob', 'AutoDiffBackupJob', 'AutoLogBackupJob')
ORDER BY h.run_date DESC, h.run_time DESC;
GO

--	CHECK THE BACKUP INFORMATION
SELECT 
	j.name AS JobName,
	s.name AS ScheduleName,
	s.enabled,
	s.freq_type,
	s.freq_interval,
	s.freq_subday_type,
	s.freq_subday_interval,
	s.active_start_time
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE j.name IN ('AutoFullBackupJob', 'AutoDiffBackupJob', 'AutoLogBackupJob');

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 4 ->	LOGIN AS NURSE AND CHECK THE ACCESS
--	1.	NURSE 1
EXECUTE AS USER = 'ST002';
SELECT * FROM PatientNonSensitiveView; -- Should succeed, displaying only non-sensitive columns

SELECT * FROM Patient; -- Should fail, Msg 229

SELECT PaymentCardNumber, PaymentCardPinCode FROM Patient; -- Should fail

UPDATE Patient SET PPhone = '0126109237' WHERE PID = 'PT005'; -- Should fail

REVERT;
GO

--	2.	NURSE 2
EXECUTE AS USER = 'ST006';
SELECT * FROM PatientNonSensitiveView; -- Should succeed, displaying only non-sensitive columns

SELECT * FROM Patient; -- Should fail, Msg 229

SELECT PaymentCardNumber, PaymentCardPinCode FROM Patient; -- Should fail

UPDATE Patient SET PPhone = '0126109237' WHERE PID = 'PT005'; -- Should fail

REVERT;
GO

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 5 ->	
--	Query current and historical data
SELECT PID, PName, PPhone, ValidFrom, ValidTo
FROM Patient
WHERE PID = 'PT007';
GO
--	Expected Result: Empty, as PT007 was deleted.

SELECT PID, PName, PPhone, ValidFrom, ValidTo
FROM PatientHistory
WHERE PID = 'PT006'
ORDER BY ValidFrom;
GO
--	Expected Result: Two records showing PT006's history:
--	1. Initial insert with PPhone = '+60187654321'.
--	2. Update with PPhone = '+60187654322'.

--	Query historical data as of a specific time
SELECT PID, PName, PPhone, ValidFrom, ValidTo
FROM Patient
FOR SYSTEM_TIME AS OF '2025-05-01 12:00:00'
WHERE PID = 'PT006';
GO
--	Expected Result: Shows PT006's state at the specified time

----------------------------------------------------	NEXT	----------------------------------------------------

--	TESTING 6 ->	
EXECUTE AS USER = 'AD001';

--	QUERY AUDIT LOGS
SELECT 
	AuditID,
	TableName,
	Operation,
	RecordID,
	ChangedColumns,
	ChangedBy,
	ChangedAt
FROM AuditLog
WHERE TableName IN ('Prescription', 'Appointment')
ORDER BY ChangedAt;
GO

---------------------------------------------------- SECTION BREAK ----------------------------------------------------
--+=============================================+
--|				  EXTRA QUERY					|
--+=============================================+
--	CHECK SERVICE NAME
SELECT servicename, service_account
FROM sys.dm_server_services
WHERE servicename LIKE '%SQL Server%';

--	RESTORING BACKUP IN OTHER SERVER (NEED RUN IN OTHER SCRIPT)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
EXEC xp_cmdshell 'dir D:\Backup';

RESTORE FILELISTONLY 
FROM DISK = 'D:\Backup\Full\.bak';

RESTORE DATABASE MedicalInfoSystem
FROM DISK = 'D:\Backup\Full\MedicalInfoSystem_FULL_20250501.bak'
WITH MOVE 'MedicalInfoSystem' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER02\MSSQL\DATA\MedicalInfoSystem.mdf',
     MOVE 'MedicalInfoSystem_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER02\MSSQL\DATA\MedicalInfoSystem_log.ldf',
     REPLACE,
     STATS = 10;

--	CHECK EVERY CHARACTER ROLE
SELECT 
    r.name AS RoleName,
    m.name AS MemberName,
    m.type_desc AS MemberType
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.name IN ('Doctor', 'Nurse', 'Pharmacist', 'Patient', 'Admin');

--	DELETE ALL DATABASE BACKUP HISTORY
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = 'MedicalInfoSystem';

--+=================================================================================================================+
--|															END														|
--+=================================================================================================================+