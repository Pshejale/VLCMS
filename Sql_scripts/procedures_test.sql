--procedures check up

--1. Test: AddNewVehicleWithOwner
CALL AddNewVehicleWithOwner(
    'Ravi Kumar', '9876543210', 'ravi@gmail.com', 'Bangalore', 'Male',
    'KA05MN1234', 'Hyundai', 'i20', 2022, 12000
);

--verify insertion
SELECT * FROM OWNER;
SELECT * FROM VEHICLES;


--2. Test: AddServiceRecord
CALL AddServiceRecord(
    1500, 'Full Service', '2025-10-30', 54000, 'Routine checkup', 1, 'KA05MN1234'
);
--verify insertion
SELECT * FROM SERVICE_RECORD WHERE Reg_Num = 'KA05MN1234';
SELECT Milage FROM VEHICLES WHERE Reg_Num = 'KA05MN1234';

--3. Test: ReplacePart
-- Before replacement
INSERT INTO SERVICE_TASK (Description, Cost, Service_Id)
VALUES ('Oil Filter Replacement', 400, 1);

--
CALL ReplacePart('BRK001', 'OEM45', 'Brake Pad', 12, 2, 2500, '2025-11-01');

--Verify
SELECT * FROM PART WHERE Part_Id = 'BRK001';
SELECT * FROM PART_REPLACEMENT;
SELECT * FROM WARRANTY_CLAIM;

--4.GetVehicleServiceSummary
CALL GetVehicleServiceSummary('KA05MN1234');
--Verify output
--Reg_Num     | Total_Services | Total_Service_Cost | Last_Service_Date
--KA05MN1234  |        1        |        1500.00     | 2025-10-30


---------------------------------------------------------------------------------------------
/*
“A stored procedure is a reusable SQL block that automates multi-step operations.
In my VLCMS project:

One procedure registers an owner and vehicle together,

Another records service details,

A third logs part replacements and warranty claims,

And the last provides vehicle service summaries.”

Then run the AddNewVehicleWithOwner and GetVehicleServiceSummary live — they show both data creation and reporting functionality.
*/---------------------------------------------------------------------------------------------

