--triggers demo 
--1. Vehicle Ownership Change Trigger
UPDATE VEHICLES
SET Owner_Id = 3
WHERE Reg_Num = 'KA01AB1234';

SELECT * FROM VEHICLE_OWNERSHIP_LOG;
 
--result sampleLog_Id | Reg_Num     | Old_Owner_Id | New_Owner_Id | Change_Date
--1      | KA01AB1234  | 1            | 3             | (timestamp)


--2. Auto-Update Vehicle Mileage Trigger

INSERT INTO SERVICE_RECORD (Service_Cost, Service_type, Service_Date, Odometer_Readings, Remark, WorkShop_Id, Reg_Num)
VALUES (1500, 'General Service', '2025-10-31', 50000, 'Routine maintenance', 1, 'KA01AB1234');

SELECT Milage FROM VEHICLES WHERE Reg_Num = 'KA01AB1234';

--result sample
--it should show the updated mileage for the respective vehicle, e.g., 50000

--3. Warranty Claim Creation Trigger
INSERT INTO PART_REPLACEMENT (Part_Cost, Replacement_Date, Warranty_Period, Service_Task_Id)
VALUES (1200, '2025-11-01', 12, 1);

--check for the created warranty claim
SELECT * FROM WARRANTY_CLAIM;

--4. Prevent Invalid Service Date Trigger
INSERT INTO SERVICE_RECORD (Service_Cost, Service_type, Service_Date, Odometer_Readings, WorkShop_Id, Reg_Num)
VALUES (900, 'Quick Check', '2025-01-01', 42000, 1, 'KA01AB1234');

--epected result: Error indicating that the service date cannot be earlier than the last service date.

--5. Phone Number Validation Triggers
INSERT INTO OWNER (Name, Phone_No, Email_Id, Address, Gender)
VALUES ('Test User', '12345', 'test@gmail.com', 'Test City', 'Male');

--expected result: Phone number must be exactly 10 digits.

--valid insert
INSERT INTO OWNER (Name, Phone_No, Email_Id, Address, Gender)
VALUES ('Valid User', '9876504321', 'valid@gmail.com', 'Delhi', 'Male');

-------------------------------------------------------------------------------------------------------------
/*

--6. same phone number validation trigger for workshop table

--7. check the expiry date of the insurance trigger
    for this it check the curdate with the expiry date of the insurance
    it should be greater than curdate else it should give an error
*/
