-- Solutions to Advanced SQL Puzzles by Scott Peters

/*
Solution Puzzle #1
Shopping Carts
*/
SELECT c1.Item, c2.Item
FROM Cart1 c1
LEFT JOIN Cart2 c2 USING (Item)
UNION
SELECT c1.Item, c2.Item
FROM Cart1 c1
RIGHT JOIN Cart2 c2 USING (Item);


/*
Solution to Puzzle #2
Managers and Employees
*/
WITH RECURSIVE emp_depth AS (
	SELECT EmployeeID, ManagerID, JobTitle, Salary, 0 depth
    FROM employees 
    WHERE ManagerID IS NULL
    UNION ALL
    SELECT e.EmployeeID, e.ManagerID, e.JobTitle, e.Salary, ed.depth+1 depth
    FROM employees e
    JOIN emp_depth ed ON e.ManagerID = ed.EmployeeID
)
SELECT * FROM emp_depth;


/*
Answer to Puzzle #3
Fiscal Year Table Constraints
*/
ALTER TABLE EmployeePayRecords
	MODIFY EmployeeID INT NOT NULL,
    MODIFY FiscalYear INT NOT NULL,
    MODIFY StartDate DATE NOT NULL,
    MODIFY EndDate DATE NOT NULL,
    MODIFY PayRate INT NOT NULL;

ALTER TABLE EmployeePayRecords
ADD PRIMARY KEY (EmployeeID, FiscalYear);

ALTER TABLE EmployeePayRecords
ADD CHECK (YEAR(StartDate)=FiscalYear AND MONTH(StartDate)=1 AND DATE(StartDate)=01);

ALTER TABLE EmployeePayRecords
ADD CHECK (YEAR(EndDate)=FiscalYear AND MONTH(EndDate)=12 AND DATE(EndDate)=31);

ALTER TABLE EmployeePayRecords
ADD CHECK (PayRate >= 0);
		

/*
Solution to Puzzle #4
Two Predicates
*/
SELECT * 
FROM orders o
WHERE DeliveryState = 'TX' AND
	EXISTS (
		SELECT 1 FROM Orders 
        WHERE CustomerID = o.CustomerID AND 
			DeliveryState = 'CA'
	);


/*
Solution to Puzzle #5
Phone Directory
*/
SELECT CustomerID, MAX(Cellular) Cellular, MAX(Work) Work, MAX(Home) Home 
FROM (
	SELECT 
		CustomerID,
		IF(type='Cellular', PhoneNumber, NULL) AS Cellular,
		IF(type='Home', PhoneNumber, NULL) AS Home,
		IF(type='Work', PhoneNumber, NULL) AS Work
	FROM phonedirectory
) AS tmp
GROUP BY CustomerID;


/*
Solution to Puzzle #6
Workflow Steps
*/
SELECT Workflow
FROM workflowsteps
GROUP BY Workflow
HAVING COUNT(CompletionDate) !=  MAX(StepNumber);


/*
Solution to Puzzle #7
Mission to Mars
*/
SELECT CandidateID
FROM Candidates c 
JOIN Requirements r ON c.Occupation = r.Requirement
GROUP BY CandidateID
HAVING COUNT(*) = 3;


/*
Solution to Puzzle #8
Workflow Cases
*/
SELECT Workflow, (Case1 + Case2 + Case3) AS Passed
FROM workflowcases;


/*
Solution to Puzzle #9
Matching Sets
*/
SELECT e1.EmployeeID, e2.EmployeeID EmployeeID2, COUNT(*) LicenseCountCombo 
FROM Employees e1
JOIN Employees e2 USING (License)
WHERE e1.EmployeeID != e2.EmployeeID
GROUP BY e1.EmployeeID, e2.EmployeeID
HAVING LicenseCountCombo = (
	SELECT COUNT(1) 
    FROM Employees 
    WHERE EmployeeID = e1.EmployeeID
);


/*
Solution to Puzzle #10
Mean, Median, Mode and Range
*/
SELECT AVG(IntegerValue) 
INTO @average
FROM SampleData;

SET @size = (SELECT COUNT(*) FROM SampleData);
SELECT AVG(IntegerValue)
INTO @median
FROM (
	SELECT IntegerValue, ROW_NUMBER() OVER (ORDER BY IntegerValue) AS row_num
	FROM SampleData
) AS t
WHERE CASE WHEN @size MOD 2 
	THEN row_num =  CEIL(@size/2)
    ELSE row_num = @size/2 OR row_num = @size/2+1
    END;

SELECT IntegerValue
INTO @mode
FROM SampleData
GROUP BY IntegerValue
ORDER BY COUNT(*) DESC
LIMIT 1;

SELECT MAX(IntegerValue) - MIN(IntegerValue) 
INTO @range
FROM SampleData;

SELECT ROUND(@average,2) average, ROUND(@median,2) median, @mode 'mode', @range 'range';


/*
Answer to Puzzle #11
Permutations 
*/
# To be completed


/*
Answer to Puzzle #12
Average Days
*/
SELECT WorkFlow, FLOOR(AVG(DaysToNextEntry)) AvgDays
FROM (
	SELECT *, DATEDIFF(LEAD(ExecutionDate) OVER (PARTITION BY WorkFlow), ExecutionDate) DaysToNextEntry
	FROM ProcessLog
) AS t
GROUP BY WorkFlow;


/*
Answer to Puzzle #13
Inventory Tracking
*/
SELECT *, SUM(QuantityAdjustment) OVER (ORDER BY InventoryDate) 
FROM inventory;


/*
Answer to Puzzle #14
Indeterminate Process Log
*/
SELECT Workflow, (
	CASE WHEN 'Complete' = ALL (SELECT Status FROM ProcessLog WHERE Workflow = pl.Workflow)
		THEN 'Complete' 
    WHEN 'Error' = ALL (SELECT Status FROM ProcessLog WHERE Workflow = pl.Workflow)
		THEN 'Error'
	WHEN 'Running' = ALL (SELECT Status FROM ProcessLog WHERE Workflow = pl.Workflow) OR 
		'Error' NOT IN (SELECT Status FROM ProcessLog WHERE Workflow = pl.Workflow)
		THEN 'Running'
    WHEN 'Running' NOT IN (SELECT Status FROM ProcessLog WHERE Workflow = pl.Workflow) OR
		'Complete' NOT IN (SELECT Status FROM ProcessLog WHERE Workflow = pl.Workflow)
		THEN 'Indeterminate'
	END
) as Status
FROM ProcessLog pl
GROUP BY Workflow;


/*
Answer to Puzzle #15
Group Concatenation
*/
SELECT GROUP_CONCAT(String SEPARATOR ' ')
FROM (
	SELECT	
		(
			CASE WHEN SequenceNumber IN (2, 3)
			THEN CONCAT(String, ',')
			ELSE String
			END
		) AS String
	FROM dmltable
) AS t;


/*
Answer to Puzzle #16
Reciprocals
*/
SELECT PlayerA, PlayerB, SUM(Score) AS Score
FROM (
	SELECT 
		(CASE WHEN PlayerA < PlayerB THEN PlayerA ELSE PlayerB END) AS PlayerA,
		(CASE WHEN PlayerA < PlayerB THEN PlayerB ELSE PlayerA END) AS PlayerB,
		Score
	FROM playerscores
) AS t
GROUP BY PlayerA, PlayerB;


/*
Answer to Puzzle #17
De-grouping
*/
# To be completed


/*
Answer to Puzzle #18
Seating Chart
*/
SET @start = 1;
SELECT gapStart 'Gap Start', gapEnd 'Gap End'
FROM (
	SELECT @start 'gapStart', SeatNumber-1 'gapEnd', @start:=SeatNumber+1 
	FROM SeatingChart
) AS t
WHERE gapStart < gapEnd;


/*
Answer to Puzzle #19
Back to the Future
*/
# To be completed


/*
Answer to Puzzle #20
Price Points
*/
SELECT t.ProductID, t.EffectiveDate, UnitPrice
FROM (
	SELECT ProductID, MAX(EffectiveDate) EffectiveDate
	FROM ValidPrices
	GROUP BY ProductID
) AS t
JOIN ValidPrices v
	ON v.ProductID = t.ProductID AND v.EffectiveDate = t.EffectiveDate;
    

/*
Answer to Puzzle #21
Average Monthly Sales
*/
WITH MonthlySales AS (
	SELECT State, CustomerID, EXTRACT(MONTH FROM OrderDate) OrderMonth, SUM(Amount) MonthlySales
	FROM Orders
	GROUP BY State, CustomerID, orderMonth
	ORDER BY CustomerID, OrderMonth
), AvgMonthlySales AS (
	SELECT State, CustomerID, AVG(MonthlySales) AvgMonthlySales
	FROM MonthlySales
	GROUP BY State, CustomerID
)
SELECT State
FROM AvgMonthlySales t
GROUP BY State
HAVING 100 < ALL(SELECT AvgMonthlySales FROM AvgMonthlySales WHERE State = t.State);


/*
Answer to Puzzle #22
Occurences
*/
SELECT Workflow, LogMessage 
FROM (
	SELECT LogMessage, Workflow, Occurrences, ROW_NUMBER() OVER (PARTITION BY LogMessage ORDER BY Occurrences DESC) row_num
	FROM ProcessLog
) AS t
WHERE row_num = 1;


/*
Answer to Puzzle #23
Divide in Half
*/
SELECT IF(
	COUNT(1) MOD 2, -- ODD
    FLOOR(COUNT(1)/2), 
    COUNT(1) / 2
    ) 
INTO @half
FROM PlayerScores;

SELECT PlayerID, Score, 
	CASE WHEN row_num <= @half THEN 1 ELSE 2 END 'Group'
FROM (
	SELECT *, ROW_NUMBER() OVER (ORDER BY Score DESC) row_num 
	FROM PlayerScores
) AS t;


/*
Answer to Puzzle #24
Page Views
*/
SELECT *
FROM SampleData
ORDER BY RowID
LIMIT 10, 10;


/*
Answer to Puzzle #25
Top Vendors
*/
SELECT CustomerID, Vendor
FROM Orders o
WHERE OrderCount = (SELECT MAX(OrderCount) FROM Orders WHERE CustomerID = o.CustomerID);


/*
Answer to Puzzle #26
Previous Year's Sales
*/
SELECT SUM(Year_2019) '2019', SUM(Year_2020) '2020', SUM(Year_2021) '2021', SUM(Year_2022) '2022'
FROM (
	SELECT 
		CASE WHEN Year = 2019 THEN Amount ELSE NULL END Year_2019,
		CASE WHEN Year = 2020 THEN Amount ELSE NULL END Year_2020,
		CASE WHEN Year = 2021 THEN Amount ELSE NULL END Year_2021,
		CASE WHEN Year = 2022 THEN Amount ELSE NULL END Year_2022
	FROM Sales
) AS t;

/*
Answer to Puzzle #27
Delete the duplicates
*/
# To be completed


/*
Answer to Puzzle #28
Fill the Gaps
*/
SELECT RowNumber, @currTestCase := (CASE WHEN TestCase IS NOT NULL THEN TestCase ELSE @currTestCase END) Workflow
FROM Gaps;


/*
Solution to Puzzle #29
Count the Groupings
*/
SET @lastStatus = NULL;
SET @n = 0;
SELECT
	MIN(StepNumber) 'Min Step Number', 
    MAX(StepNumber) 'Max Step Number', 
    Status, COUNT(1) 'Consecutive Count'
FROM (
	SELECT *, 
		@n:=(CASE WHEN Status = @lastStatus THEN @n ELSE @n+1 END) grup, 
		@lastStatus:=Status lastStatus
	FROM Groupings
) AS t
GROUP BY grup, Status;


/*
Solution to Puzzle #32
First and Last
*/
WITH PersonnelWithExtremes AS (
	SELECT *, 
		MAX(MissionCount) OVER (PARTITION BY JobDescription) HighestCount, 
		Min(MissionCount) OVER (PARTITION BY JobDescription) LowestCount
	FROM Personnel
)
SELECT JobDescription, MAX(MostExp) 'Most Experienced', MAX(LeastExp) 'Least Experienced'
FROM (
	SELECT JobDescription,
		(CASE WHEN MissionCount = HighestCount THEN SpacemanID ELSE NULL END) MostExp,
		(CASE WHEN MissionCount = LowestCount THEN SpacemanID ELSE NULL END) LeastExp
	FROM PersonnelWithExtremes
) as t
GROUP BY JobDescription;

# Alternative/cleaner solution (using FIRST_VALUE)
SELECT DISTINCT 
	JobDescription, 
	FIRST_VALUE(SpacemanID) OVER (PARTITION BY JobDescription ORDER BY MissionCount DESC) 'Most Experienced', 
    FIRST_VALUE(SpacemanID) OVER (PARTITION BY JobDescription ORDER BY MissionCount) 'Least Experienced'
FROM Personnel;


/*
Solution to Puzzle #34
Specific Exclusion
*/
SELECT *
FROM Orders
WHERE CustomerID != 1001 OR Amount != 50;


/*
Solution to Puzzle #35
International vs Domestic Sales
*/
WITH SalesRepRecord AS (
	SELECT SalesRepID, 
		MAX(SalesType) = 'International' HasInterSales,
        MIN(SalesType) = 'Domestic' HasDomSales
    FROM Orders o 
    GROUP BY SalesRepID
)
SELECT SalesRepID
FROM SalesRepRecord
WHERE HasInterSales + HasDomSales = 1;


/*
Solution to Puzzle #37
Group Criteria Keys
*/
SET @n = 0;
SET @lastCombo = '';
SELECT CriteriaID, OrderID, Distributor, Facility, Zone, Amount
FROM (
	SELECT *, 
		@n:=(CASE WHEN CONCAT(Distributor, Facility, Zone) != @lastCombo THEN @n+1 ELSE @n END) CriteriaID, 
		@lastCombo:=CONCAT(Distributor, Facility, Zone) LastCombo
	FROM GroupCriteria
	ORDER BY Distributor, Facility, Zone
) AS t;


/*
Solution to Puzzle #38
Reporting Elements
*/
WITH Regions AS (
	SELECT 'North' Region UNION SELECT 'South' UNION SELECT 'East' UNION SELECT 'West'
), Distributors AS (
	SELECT DISTINCT Distributor FROM RegionSales
)
SELECT t.Region, t.Distributor, IFNULL(Sales, 0) 
FROM (
	SELECT * FROM Regions, Distributors
) AS t
LEFT JOIN RegionSales rs 
	ON t.Region = rs.Region AND t.Distributor = rs.Distributor;
    

/*
Solution to Puzzle #39
Prime Numbers
*/
SELECT *
FROM SampleData t1
WHERE 1 = (
	SELECT COUNT(1) 
    FROM SampleData 
    WHERE IntegerValue < t1.IntegerValue AND 
		t1.IntegerValue MOD IntegerValue = 0
);


/*
Solution to Puzzle #40
Sort Order
*/
SELECT City
FROM SortOrder
ORDER BY (ROW_NUMBER() OVER () MOD 2) = 1;


/*
Solution to Puzzle #43
Unbounded Preceding
*/
SELECT *, MIN(Quantity) OVER (PARTITION BY CustomerID ORDER BY OrderID RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 'Min Value'
FROM CustomerOrders;


/*
Solution to Puzzle #46
Positive Account Balances
*/
# 1
SELECT DISTINCT AccountID
FROM AccountBalances t
WHERE NOT EXISTS (SELECT Balance FROM AccountBalances WHERE AccountID = t.AccountID AND Balance > -1);

# 2
SELECT AccountID
FROM AccountBalances
GROUP BY AccountID
HAVING MAX(Balance) < 0;

# 3
SELECT DISTINCT AccountID
FROM AccountBalances
WHERE AccountID NOT IN (
	SELECT AccountID
    FROM AccountBalances 
    WHERE Balance > -1
);

# 4
SELECT AccountID
FROM AccountBalances t
GROUP BY AccountID
HAVING COUNT(Balance) = (SELECT COUNT(1) FROM AccountBalances WHERE AccountID = t.AccountID AND Balance < 0);

# 5
SELECT DISTINCT t1.AccountID 
FROM AccountBalances t1
LEFT OUTER JOIN AccountBalances t2 
	ON t1.AccountID = t2.AccountID AND t2.Balance > 0
WHERE t2.Balance IS NULL;


/*
Solution to Puzzle #48
Consecutive Sales
*/
SELECT DISTINCT SalesID
FROM Sales t
WHERE 3 = (
	SELECT COUNT(DISTINCT Year) 
    FROM Sales 
    WHERE SalesID = t.SalesID AND Year IN (2019, 2020, 2021)
);


/*
Solution to Puzzle #49
Sumo Wrestlers
*/
SELECT Name 
FROM (
	SELECT *, SUM(Weight) OVER (ORDER BY LineOrder RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) total
	FROM ElevatorOrder
) AS t
WHERE total <= 2000
ORDER BY LineOrder DESC
LIMIT 1;

# Alternative solution (significantly slower)
SELECT Name
FROM (
	SELECT *, 
		SUM(Weight) OVER (ORDER BY LineOrder RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) sum,
		LEAD(Weight) OVER () next
	FROM ElevatorOrder
) AS t
WHERE sum < 2000 AND sum + next > 2000;
 

/*
DDL for Puzzle #53
Spouse IDs
*/
SELECT DENSE_RANK() OVER (ORDER BY CoupleID) GroupID, PrimaryID, SpouseID
FROM (
	SELECT *,  
		CASE WHEN PrimaryID < SpouseID 
        THEN CONCAT(PrimaryID, '-', SpouseID) 
        ELSE CONCAT(SpouseID, '-', PrimaryID) 
        END CoupleID
	FROM Spouses
) AS t
ORDER BY CoupleID, PrimaryID;


/*
Solution to Puzzle #54
Winning Numbers
*/
WITH ticket_winnings AS (
	SELECT TicketID, CASE WHEN COUNT(1) = 3 THEN 100 ELSE 10 END winnings
	FROM LotteryTickets lt
	JOIN WinningNumbers wn
		USING (Number)
	GROUP BY TicketID
)
SELECT SUM(winnings) total_winnings FROM ticket_winnings;


/*
Solution to Puzzle #55
Table Audit
*/
WITH all_products AS (
	SELECT p1.ProductName table_a_product, p1.Quantity table_a_quantity, p2.ProductName table_b_product, p2.Quantity table_b_quantity
	FROM ProductsA p1
	LEFT OUTER JOIN ProductsB P2
		USING (ProductName)
	UNION 
	SELECT p1.ProductName, p1.Quantity, p2.ProductName, p2.Quantity
	FROM ProductsA p1
	RIGHT OUTER JOIN ProductsB p2 
		USING (ProductName)
)
SELECT
	CASE WHEN table_a_product IS NULL 
		THEN 'Product does not exist in table A' 
    WHEN table_b_product IS NULL
		THEN 'Product does not exist in table B'
	ELSE
		CASE WHEN table_a_quantity = table_b_quantity
			THEN 'Matches in both tables'
		ELSE 
			'Quantity in table A and table B do not match'
		END
    END Type,
    IFNULL(table_a_product, table_b_product) ProductName
FROM all_products;
