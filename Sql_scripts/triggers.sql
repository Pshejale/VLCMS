--triggers
--------------1----------------
--table for the vehicles owneship changes
CREATE TABLE VEHICLE_OWNERSHIP_LOG (
    Log_Id INT PRIMARY KEY AUTO_INCREMENT,
    Reg_Num VARCHAR(14),
    Old_Owner_Id INT,
    New_Owner_Id INT,
    Change_Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Reg_Num) REFERENCES VEHICLES(Reg_Num)
);

 
 --trigger to log ownership changes
 DELIMITER $$

CREATE TRIGGER after_vehicle_owner_update
AFTER UPDATE ON VEHICLES
FOR EACH ROW
BEGIN
    IF OLD.Owner_Id <> NEW.Owner_Id THEN
        INSERT INTO VEHICLE_OWNERSHIP_LOG (Reg_Num, Old_Owner_Id, New_Owner_Id)
        VALUES (NEW.Reg_Num, OLD.Owner_Id, NEW.Owner_Id);
    END IF;
END$$

DELIMITER ;

--------------2----------------
--Auto-Update Vehicle Mileage After Service
DELIMITER $$

CREATE TRIGGER update_vehicle_mileage_after_service
AFTER INSERT ON SERVICE_RECORD
FOR EACH ROW
BEGIN
    UPDATE VEHICLES
    SET Milage = NEW.Odometer_Readings
    WHERE Reg_Num = NEW.Reg_Num;
END$$

DELIMITER ;


--------------3----------------
--Track Warranty Claim Creation After Part Replacement
DELIMITER $$

CREATE TRIGGER create_warranty_claim_after_replacement
AFTER INSERT ON PART_REPLACEMENT
FOR EACH ROW
BEGIN
    IF NEW.Warranty_Period > 0 THEN
        INSERT INTO WARRANTY_CLAIM (Claim_Id, Status, Date, Replacement_Id)
        VALUES (NEW.Replacement_Id, 'Pending', CURDATE(), NEW.Replacement_Id);
    END IF;
END$$

DELIMITER ;


--------------4----------------
--Prevent Invalid Service Date
DELIMITER $$

CREATE TRIGGER check_service_date_before_insert
BEFORE INSERT ON SERVICE_RECORD
FOR EACH ROW
BEGIN
    DECLARE last_date DATE;

    SELECT MAX(Service_Date)
    INTO last_date
    FROM SERVICE_RECORD
    WHERE Reg_Num = NEW.Reg_Num;

    IF last_date IS NOT NULL AND NEW.Service_Date < last_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Service date cannot be earlier than last recorded service date.';
    END IF;
END$$

DELIMITER ;



--------------5----------------
--phone number validation trigger
DELIMITER $$

CREATE TRIGGER before_insert_owner
BEFORE INSERT ON OWNER
FOR EACH ROW
BEGIN
    IF NOT NEW.Phone_No REGEXP '^[0-9]{10}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phone number must be exactly 10 digits.';
    END IF;
END $$

DELIMITER ;

--------------6----------------
--phone number validation trigger for workshop table

DELIMITER $$

CREATE TRIGGER before_insert_workshop
BEFORE INSERT ON WORKSHOP
FOR EACH ROW
BEGIN
    IF NOT NEW.Phone_No REGEXP '^[0-9]{10}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phone number must be exactly 10 digits.';
    END IF;
END $$

DELIMITER ;

--------------7----------------
---to check the expiry date of the insurance
DELIMITER $$

CREATE TRIGGER before_insurance_insert
BEFORE INSERT ON INSURANCE
FOR EACH ROW
BEGIN
    IF NEW.Expiry_Date < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot add insurance with expired date.';
    END IF;
END$$

DELIMITER ;

