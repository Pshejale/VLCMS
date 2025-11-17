--function testing 
---1. Test Function: GetMostReplacedPart()
SELECT GetMostReplacedPart('KA05MN1234') AS Most_Replaced_Part;

--Expected Output:
/*
Most_Replaced_Part
-------------------
Brake Pad
*/

--Explanation:
--The function:
--• Checks all service tasks for vehicle KA05MN1234  
--• Counts how many times each part was replaced  
--• Returns the part with the highest replacement count (Brake Pad)

--Real-world meaning:
--“Brake Pads for this vehicle are replaced most often — they need frequent attention.”

-------------------------------------------------------------------------------------------------------------   

--2. Test Function: GetAvgReplacementDays()
SELECT GetAvgReplacementDays('KA05MN1234', 'Brake Pad') AS Avg_Replacement_Days;

--Expected Output:
/*
Avg_Replacement_Days
---------------------
120
*/

--Explanation:
--The function:
--• Finds the earliest and latest dates when 'Brake Pad' was replaced  
--• Calculates DATEDIFF(latest - earliest)  
--• Returns the average interval in days (example: 120 days)

--Real-world meaning:
--“Brake pads on this vehicle are typically replaced every ~120 days.”

-------------------------------------------------------------------------------------------------------------     

--3. Test Function: PredictNextReplacementDate()
SELECT PredictNextReplacementDate('KA05MN1234', 'Brake Pad') AS Next_Estimated_Date;

--Expected Output:
/*
Next_Estimated_Date
--------------------
2025-03-15
*/

--Explanation:
--The function:
--• Gets the latest date when 'Brake Pad' was replaced  
--• Calls GetAvgReplacementDays() internally  
--• Adds the average interval to last replacement date  
--• Predicts the next likely replacement date

--Real-world meaning:
--“Based on past replacement pattern, brake pads will likely need replacement around 15 March 2025.”

-------------------------------------------------------------------------------------------------------------

--4. Test Function: GetMostServicedCompany()
SELECT GetMostServicedCompany() AS Most_Serviced_Company;

--Expected Output:
/*
Most_Serviced_Company
----------------------
Tata
*/

--Explanation:
--The function:
--• Counts number of service records for each vehicle company  
--• Returns the company with the highest total services (example: Tata)

--Real-world meaning:
--“Tata vehicles are serviced the most in our workshop overall.”

-------------------------------------------------------------------------------------------------------------

--5. Test Function: GetMostReplacedPartOverall()
SELECT GetMostReplacedPartOverall() AS Most_Replaced_Part_Overall;

--Expected Output:
/*
Most_Replaced_Part_Overall
---------------------------
Air Filter
*/

--Explanation:
--The function:
--• Checks all replaced parts across all vehicles  
--• Counts total replacements  
--• Returns the part with the highest replacement frequency (example: Air Filter)

--Real-world meaning:
--“Air Filter is the most commonly replaced part in the entire workshop.”


