use RawData;

SELECT * 
FROM dbo.OnlineSaleDetail;

--------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER TABLE OnlineSaleDetail
ADD Frequency smallint;
-- Update value for TransactionFrequency
WITH Temp AS 
(
SELECT Customer_ID, COUNT(DISTINCT Invoice) AS Feq
FROM dbo.OnlineSaleDetail
GROUP BY Customer_ID
)
UPDATE OnlineSaleDetail
SET Frequency = Te.Feq
FROM dbo.OnlineSaleDetail AS Ro
INNER JOIN Temp AS Te
ON Ro.Customer_ID = Te.Customer_ID
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE Recent value For Customer
ALTER TABLE OnlineSaleDetail
ADD Recent int;

UPDATE OnlineSaleDetail
SET Recent = ABS(DATEDIFF(day, '2011-12-05',InvoiceDate));

WITH Temp
AS 
(
SELECT Customer_ID, Min(Recent) as LastestPur
FROM dbo.OnlineSaleDetail
GROUP BY Customer_ID
)
UPDATE OnlineSaleDetail
SET Recent = LastestPur
FROM dbo.OnlineSaleDetail as Onl
INNER JOIN Temp as Te
ON Onl.Customer_ID = Te.Customer_ID;

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- ADD Monetary rating
ALTER TABLE OnlineSaleDetail
ADD MonetaryRating smallint;

WITH SumOrder
AS 
(
SELECT Customer_ID, SUM(TotalPrice) as Num
FROM dbo.OnlineSaleDetail
GROUP BY Customer_ID
)
UPDATE OnlineSaleDetail
SET MonetaryRating = CASE
						WHEN Num > 50000 THEN 5
						WHEN Num > 25000 AND Num <=50000 THEN 4
						WHEN Num > 10000 AND Num <=25000 THEN 3
						WHEN Num > 1000 AND Num <=10000 THEN 2
						WHEN Num > 0 AND Num <=1000 THEN 1
					END
FROM dbo.OnlineSaleDetail AS Onl
INNER JOIN SumOrder AS Ra
ON Onl.Customer_ID = Ra.Customer_ID;

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- ADD Frequency rating
ALTER TABLE OnlineSaleDetail
ADD FrequencyRating smallint;

UPDATE OnlineSaleDetail
SET FrequencyRating = CASE
						WHEN Frequency > 300 THEN 5
						WHEN Frequency > 200 AND Frequency <= 300 THEN 4
						WHEN Frequency > 100 AND Frequency <= 200 THEN 3
						WHEN Frequency > 50 AND Frequency <= 100 THEN 2
						WHEN Frequency > 0 AND Frequency <= 50 THEN 1
					 END;
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- ADD Recentrating
ALTER TABLE OnlineSaleDetail
ADD RecentRating smallint;

UPDATE OnlineSaleDetail
SET RecentRating = CASE
						WHEN Recent < 30 THEN 5
						WHEN Recent >= 30 AND Recent < 100 THEN 4
						WHEN Recent >= 100 AND Recent < 300 THEN 3
						WHEN Recent >= 300 AND Recent <=  600 THEN 2
						WHEN Recent > 600 THEN 1
					 END;

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Add RFM_Score for customer
ALTER TABLE OnlineSaleDetail
ADD RFM_Score smallint;

UPDATE OnlineSaleDetail
SET RFM_Score = (RecentRating *100) + (FrequencyRating *10) + MonetaryRating
--------------------------------------------------------------------------------------------------------------------------------------------------------
--Customer Segmentation
ALTER TABLE OnlineSaleDetail
ADD CustSeg VARCHAR(30);

UPDATE OnlineSaleDetail
SET CustSeg = CASE  
				WHEN (RecentRating = 5 OR RecentRating = 4) AND (FrequencyRating = 5 OR FrequencyRating = 4) AND (MonetaryRating = 4 OR MonetaryRating = 5) THEN 'VIP'
				WHEN (RecentRating = 5 OR RecentRating = 4) AND (FrequencyRating = 4 OR FrequencyRating = 3) AND (MonetaryRating = 4 OR MonetaryRating = 3) THEN 'Loyal'
				WHEN (RecentRating = 5 OR RecentRating = 4) AND (FrequencyRating = 2 OR FrequencyRating = 3) AND (MonetaryRating = 4 OR MonetaryRating = 3)THEN 'Potential'
				WHEN RecentRating = 5  AND (FrequencyRating = 1 OR Frequency = 2) THEN 'Recent'
				WHEN (RecentRating = 5 OR RecentRating = 4) AND (MonetaryRating = 1 OR MonetaryRating = 2)THEN 'Promising'
				WHEN (RecentRating = 4 OR RecentRating = 3)  AND (FrequencyRating = 3 OR FrequencyRating = 4) AND ( MonetaryRating = 4 OR MonetaryRating = 3) THEN 'Need Attention'
				WHEN (RecentRating = 2 OR RecentRating = 3)  AND (FrequencyRating = 2 OR FrequencyRating = 3)  AND ( MonetaryRating = 2 OR MonetaryRating = 3) THEN 'Sleep'
				WHEN (RecentRating = 1 OR RecentRating = 2) AND (FrequencyRating = 4 OR FrequencyRating = 5) AND ( MonetaryRating = 4 OR MonetaryRating = 5) THEN 'At Risk'
				WHEN (RecentRating = 1 OR RecentRating = 2) AND FrequencyRating = 4 AND MonetaryRating = 5 THEN 'Can’t Lose'
				WHEN (RecentRating = 1 OR RecentRating = 2) AND (FrequencyRating = 2 OR FrequencyRating = 1) AND MonetaryRating = 2 THEN 'Hibernating'
				WHEN RecentRating = 1 AND FrequencyRating = 1 AND MonetaryRating = 1 THEN 'Lost'
				END;

SELECT RFM_Score, CustSeg
FROM dbo.OnlineSaleDetail
WHERE CustSeg IS NULL
GROUP BY RFM_Score, CustSeg
ORDER BY RFM_Score DESC

SELECT COUNT(Customer_ID) AS NumCust, CustSeg
FROM dbo.OnlineSaleDetail
GROUP BY CustSeg
ORDER BY NumCust DESC

UPDATE OnlineSaleDetail
SET CustSeg = 'Hibernating'
WHERE RFM_Score IN (114,113)
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- ADD DAY OF WEEk
ALTER TABLE OnlineSaleDetail
ADD day_of_week varchar(50);


WITH GetDay
AS 
(
SELECT InvoiceDate, DATENAME(WEEKDAY,InvoiceDate) as DAYOFW
FROM dbo.OnlineSaleDetail
GROUP BY InvoiceDate
)
UPDATE OnlineSaleDetail
SET day_of_week = DAYOFW
FROM dbo.OnlineSaleDetail AS Onl
INNER JOIN GetDay AS Gd
ON Onl.InvoiceDate = Gd.InvoiceDate;

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Update TimeID
SELECT * FROM dbo.OnlineSaleDetail;

SELECT  InvoiceDate, DateID
FROM dbo.OnlineSaleDetail
GROUP BY DateID, InvoiceDate
ORDER BY DateID;

ALTER TABLE OnlineSaleDetail 
ADD DateID int;

With RowNum
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY InvoiceDate) as NumRow, InvoiceDate
FROM dbo.OnlineSaleDetail
GROUP BY InvoiceDate
)
UPDATE OnlineSaleDetail 
SET DateID = Ro.NumRow
FROM OnlineSaleDetail as Ba
INNER JOIN RowNum as Ro
ON Ba.InvoiceDate = Ro.InvoiceDate

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- ADD YearID
SELECT *
FROM dbo.OnlineSaleDetail

ALTER TABLE OnlineSaleDetail 
ADD YearID int;

With RowNum
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY year_of_transaction) as NumRow, year_of_transaction
FROM dbo.OnlineSaleDetail
GROUP BY year_of_transaction
)
UPDATE OnlineSaleDetail 
SET YearID = Ro.NumRow
FROM OnlineSaleDetail as Ba
INNER JOIN RowNum as Ro
ON Ba.year_of_transaction = Ro.year_of_transaction

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- ADD MonthID
SELECT *
FROM dbo.OnlineSaleDetail

ALTER TABLE OnlineSaleDetail 
ADD MonthID int;

With RowNum
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY month_of_transaction) as NumRow, month_of_transaction
FROM dbo.OnlineSaleDetail
GROUP BY month_of_transaction
)
UPDATE OnlineSaleDetail 
SET MonthID = Ro.NumRow
FROM OnlineSaleDetail as Ba
INNER JOIN RowNum as Ro
ON Ba.month_of_transaction = Ro.month_of_transaction

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- ADD DayID
SELECT *
FROM dbo.OnlineSaleDetail

ALTER TABLE OnlineSaleDetail 
ADD DayID int;

With RowNum
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY day_of_week) as NumRow, day_of_week
FROM dbo.OnlineSaleDetail
GROUP BY day_of_week
)
UPDATE OnlineSaleDetail 
SET DayID = Ro.NumRow
FROM OnlineSaleDetail as Ba
INNER JOIN RowNum as Ro
ON Ba.day_of_week = Ro.day_of_week

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- ADD CustSegID
SELECT *
FROM dbo.OnlineSaleDetail

ALTER TABLE OnlineSaleDetail 
ADD CustSegID int;

With RowNum
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY CustSeg) as NumRow, CustSeg
FROM dbo.OnlineSaleDetail
GROUP BY CustSeg
)
UPDATE OnlineSaleDetail 
SET CustSegID = Ro.NumRow
FROM OnlineSaleDetail as Ba
INNER JOIN RowNum as Ro
ON Ba.CustSeg = Ro.CustSeg

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Split DAY OF InvoiceDate
ALTER TABLE OnlineSaleDetail
ADD day_of_transaction smallint;


UPDATE OnlineSaleDetail
SET day_of_transaction = DAY(InvoiceDate)
FROM dbo.OnlineSaleDetail


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Split Month OF InvoiceDate
ALTER TABLE OnlineSaleDetail
ADD month_of_transaction smallint;


UPDATE OnlineSaleDetail
SET month_of_transaction = MONTH(InvoiceDate)
FROM dbo.OnlineSaleDetail

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Split year OF InvoiceDate
ALTER TABLE OnlineSaleDetail
ADD year_of_transaction smallint;


UPDATE OnlineSaleDetail
SET year_of_transaction = YEAR(InvoiceDate)
FROM dbo.OnlineSaleDetail
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Update locationID
SELECT * FROM dbo.OnlineSaleDetail;

SELECT  Country, LocationID
FROM dbo.OnlineSaleDetail
GROUP BY Country, LocationID
ORDER BY LocationID DESC;

ALTER TABLE OnlineSaleDetail 
ADD LocationID int;

With RowNum
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY Country) as NumRow, Country
FROM dbo.OnlineSaleDetail
GROUP BY Country
)
UPDATE OnlineSaleDetail 
SET LocationID = Ro.NumRow
FROM OnlineSaleDetail as Ba
INNER JOIN RowNum as Ro
ON Ba.Country = Ro.Country
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Standardize ProductID

With RowNum
AS
(
SELECT ROW_NUMBER() OVER (ORDER BY Description) as NumRow, Description
FROM dbo.OnlineSaleDetail
GROUP BY Description
)
UPDATE OnlineSaleDetail 
SET StockCode = Ro.NumRow
FROM OnlineSaleDetail as Ba
INNER JOIN RowNum as Ro
ON Ba.Description = Ro.Description

--------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'OnlineSaleDetail'

SELECT DATEPART(second, TransactionTime)
FROM dbo.BankTransaction
WHERE TransactionID = 'T1'

--------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT Customer_ID, *
FROM dbo.OnlineSaleDetail
WHERE Frequency > 2
ORDER BY InvoiceDate DESC;

SELECT Customer_ID, Recent
FROM dbo.OnlineSaleDetail
ORDER BY Customer_ID

SELECT MAX(Recent), MIN(Recent)
FROM dbo.OnlineSaleDetail;

SELECT Customer_ID, SUM(TotalPrice) as Num, MonetaryRating
FROM dbo.OnlineSaleDetail
GROUP BY Customer_ID,MonetaryRating
ORDER BY Num DESC

SELECT RecentRating, COUNT(RecentRating)
FROM dbo.OnlineSaleDetail
GROUP BY RecentRating;


WITH SumOrder
AS 
(
SELECT Customer_ID, SUM(TotalPrice) as Num, MonetaryRating
FROM dbo.OnlineSaleDetail
GROUP BY Customer_ID, MonetaryRating
)
SELECT MIN(Num)
FROM SumOrder
WHERE MonetaryRating = 5;

SELECT *
FROM dbo.OnlineSaleDetail
WHERE Customer_ID = '17998';

-- Fact Transaction
	SELECT Customer_ID, DateID, LocationID,StockCode AS ProductID, Invoice, Quantity, TotalPrice 
	FROM dbo.OnlineSaleDetail
	ORDER BY Customer_ID;

-- Dim Location
	SELECT  LocationID, Country
	FROM dbo.OnlineSaleDetail
	GROUP BY LocationID,Country
	ORDER BY LocationID

-- DimCustomer
	SELECT  DISTINCT Customer_ID, LocationID, CustSegID
	FROM dbo.OnlineSaleDetail
	

-- Dim CustomerSeg
	SELECT  DISTINCT CustSegID, CustSeg
	FROM dbo.OnlineSaleDetail

-- Dim Date
	SELECT DateID, InvoiceDate, DayID, MonthID, YearID
	FROM dbo.OnlineSaleDetail
	GROUP BY DateID, InvoiceDate, DayID, MonthID, YearID
	ORDER BY DateID

-- Dim Product
	SELECT StockCode as ProductID, Description
	FROM dbo.OnlineSaleDetail
	GROUP BY StockCode,Description
	ORDER BY ProductID ASC

-- Dim Year
	SELECT DISTINCT YearID, year_of_transaction
	From dbo.OnlineSaleDetail

-- Dim Month
	SELECT DISTINCT MonthID, month_of_transaction
	From dbo.OnlineSaleDetail

-- Dim Day of week
	SELECT DISTINCT DayID, day_of_week
	From dbo.OnlineSaleDetail

	SELECT COUNT(DISTINCT Customer_ID) as Num, CustSeg
	FROM dbo.OnlineSaleDetail
	GROUP BY CustSeg
	ORDER BY Num DESC

	SELECT MAX(Frequency), MIN(Frequency)
	FROM dbo.OnlineSaleDetail