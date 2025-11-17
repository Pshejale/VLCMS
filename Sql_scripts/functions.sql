USE VLCMS;

--Functions creation 
--Function: GetMostReplacedPart()---this is for the particular vehicle 
--Finds which part has been replaced most often for a specific vehicle.
--This is your “prediction” of which part will likely need replacement again soon.
DELIMITER $$

CREATE FUNCTION GetMostReplacedPart(p_reg_num VARCHAR(14))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE most_replaced_part VARCHAR(100);

    -- Trim spaces and find most replaced part
    SELECT p.Name
    INTO most_replaced_part
    FROM PART p
    JOIN SERVICE_TASK st ON p.Service_Task_Id = st.Service_Task_Id
    JOIN SERVICE_RECORD sr ON st.Service_Id = sr.Service_Id
    JOIN PART_REPLACEMENT pr ON st.Service_Task_Id = pr.Service_Task_Id
    WHERE TRIM(sr.Reg_Num) = TRIM(p_reg_num)
    GROUP BY p.Name
    ORDER BY COUNT(pr.Replacement_Id) DESC
    LIMIT 1;

    RETURN most_replaced_part;
END$$

DELIMITER ;


--2.Function: GetAvgReplacementDays()
--Calculates how frequently (in days) a particular part is replaced on a specific vehicle.
--This helps predict how soon it will need replacing again.
DELIMITER $$

CREATE FUNCTION GetAvgReplacementDays(p_reg_num VARCHAR(14), p_part_name VARCHAR(100))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE avg_days INT DEFAULT 0;
    DECLARE min_date DATE;
    DECLARE max_date DATE;

    -- Get earliest and latest replacement (service) dates
    SELECT MIN(sr.Service_Date), MAX(sr.Service_Date)
    INTO min_date, max_date
    FROM SERVICE_RECORD sr
    JOIN SERVICE_TASK st ON sr.Service_Id = st.Service_Id
    JOIN PART p ON p.Service_Task_Id = st.Service_Task_Id
    WHERE TRIM(sr.Reg_Num) = TRIM(p_reg_num)
      AND p.Name = p_part_name;

    -- Calculate date difference
    IF min_date IS NOT NULL AND max_date IS NOT NULL THEN
        SET avg_days = DATEDIFF(max_date, min_date);
    END IF;

    RETURN avg_days;
END$$

DELIMITER ;



--3. Function: PredictNextReplacementDate()
--Uses the average replacement interval (from the previous function) to predict when the next replacement will likely occur.
DELIMITER $$

CREATE FUNCTION PredictNextReplacementDate(p_reg_num VARCHAR(14), p_part_name VARCHAR(100))
RETURNS DATE
DETERMINISTIC
BEGIN
    DECLARE last_date DATE;
    DECLARE avg_days INT DEFAULT 0;

    -- Get last replacement/service date
    SELECT MAX(sr.Service_Date)
    INTO last_date
    FROM SERVICE_RECORD sr
    JOIN SERVICE_TASK st ON sr.Service_Id = st.Service_Id
    JOIN PART p ON p.Service_Task_Id = st.Service_Task_Id
    WHERE TRIM(sr.Reg_Num) = TRIM(p_reg_num)
      AND p.Name = p_part_name;

    -- Get average days using previous function
    SET avg_days = GetAvgReplacementDays(p_reg_num, p_part_name);

    -- Return next likely replacement date
    IF last_date IS NOT NULL THEN
        RETURN DATE_ADD(last_date, INTERVAL avg_days DAY);
    ELSE
        RETURN NULL;
    END IF;
END$$

DELIMITER ;


--4. Function: GetMostServicedCompany()

--GetMostServicedCompany()
/*
Find which vehicle company (Make) has had the most services overall across all records — for example, “Tata” vehicles are serviced the most.
*/
DELIMITER $$

CREATE FUNCTION GetMostServicedCompany()
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE most_serviced_company VARCHAR(50);

    SELECT v.Make
    INTO most_serviced_company
    FROM VEHICLES v
    JOIN SERVICE_RECORD sr ON v.Reg_Num = sr.Reg_Num
    GROUP BY v.Make
    ORDER BY COUNT(sr.Service_Id) DESC
    LIMIT 1;

    RETURN most_serviced_company;
END$$

DELIMITER ;

-------------------------------------------------------------------------------------------------------------

--GetMostReplacedPartOverall()
-- Find the most commonly replaced part across all vehicles and services — for example, “Brake Pad” is replaced most often.

DELIMITER $$

CREATE FUNCTION GetMostReplacedPartOverall()
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE common_part VARCHAR(100);

    SELECT p.Name
    INTO common_part
    FROM PART p
    JOIN SERVICE_TASK st ON p.Service_Task_Id = st.Service_Task_Id
    JOIN PART_REPLACEMENT pr ON st.Service_Task_Id = pr.Service_Task_Id
    GROUP BY p.Name
    ORDER BY COUNT(pr.Replacement_Id) DESC
    LIMIT 1;

    RETURN common_part;
END$$

DELIMITER ;



