--procedures 
--Procedure: Add a New Vehicle with Owner
--Automate the process of registering a new vehicle and its owner at once — instead of inserting into two tables manually.
DELIMITER $$

CREATE PROCEDURE AddNewVehicleWithOwner(
    IN p_owner_name VARCHAR(100),
    IN p_phone VARCHAR(10),
    IN p_email VARCHAR(50),
    IN p_address VARCHAR(255),
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_reg_num VARCHAR(14),
    IN p_make VARCHAR(50),
    IN p_model VARCHAR(50),
    IN p_year INT,
    IN p_milage INT
)
BEGIN
    DECLARE new_owner_id INT;

    -- Insert into OWNER table
    INSERT INTO OWNER (Name, Phone_No, Email_Id, Address, Gender)
    VALUES (p_owner_name, p_phone, p_email, p_address, p_gender);

    SET new_owner_id = LAST_INSERT_ID();

    -- Insert into VEHICLES table
    INSERT INTO VEHICLES (Reg_Num, Make, Model, Year, Milage, Owner_Id)
    VALUES (p_reg_num, p_make, p_model, p_year, p_milage, new_owner_id);
END$$

DELIMITER ;


--2.Procedure: Record a Vehicle Service
--Insert a complete service record for a vehicle in one step.
DELIMITER $$

CREATE PROCEDURE AddServiceRecord(
    IN p_service_cost DECIMAL(10,2),
    IN p_service_type VARCHAR(100),
    IN p_service_date DATE,
    IN p_odometer INT,
    IN p_remark TEXT,
    IN p_workshop_id INT,
    IN p_reg_num VARCHAR(14)
)
BEGIN
    INSERT INTO SERVICE_RECORD (Service_Cost, Service_type, Service_Date, Odometer_Readings, Remark, WorkShop_Id, Reg_Num)
    VALUES (p_service_cost, p_service_type, p_service_date, p_odometer, p_remark, p_workshop_id, p_reg_num);
END$$

DELIMITER ;



--3. Procedure: Replace a Part for a Service Task
--Record a part replacement easily, and automatically create warranty claim
DELIMITER $$

CREATE PROCEDURE ReplacePart(
    IN p_part_id VARCHAR(30),
    IN p_part_no VARCHAR(50),
    IN p_part_name VARCHAR(100),
    IN p_warranty_period INT,
    IN p_service_task_id INT,
    IN p_part_cost DECIMAL(10,2),
    IN p_replacement_date DATE
)
BEGIN
    -- Insert into PART table
    INSERT INTO PART (Part_Id, Part_No, Name, Warranty_Period, Service_Task_Id)
    VALUES (p_part_id, p_part_no, p_part_name, p_warranty_period, p_service_task_id);

    -- Insert into PART_REPLACEMENT table
    INSERT INTO PART_REPLACEMENT (Part_Cost, Replacement_Date, Warranty_Period, Service_Task_Id)
    VALUES (p_part_cost, p_replacement_date, p_warranty_period, p_service_task_id);
END$$

DELIMITER ;


--4. Procedure: Get Service Summary of a Vehicle
--Fetch all service details for a vehicle — total cost, number of services, and last service date.
DELIMITER $$

CREATE PROCEDURE GetVehicleServiceSummary(
    IN p_reg_num VARCHAR(14)
)
BEGIN
    SELECT 
        v.Reg_Num,
        COUNT(sr.Service_Id) AS Total_Services,
        SUM(sr.Service_Cost) AS Total_Service_Cost,
        MAX(sr.Service_Date) AS Last_Service_Date
    FROM VEHICLES v
    JOIN SERVICE_RECORD sr ON v.Reg_Num = sr.Reg_Num
    WHERE v.Reg_Num = p_reg_num
    GROUP BY v.Reg_Num;
END$$

DELIMITER ;


