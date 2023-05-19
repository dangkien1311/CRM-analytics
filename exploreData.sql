USE OnlineRetailDW;

-- Sale Product on november
SELECT description, COUNT(Fa.Invoice) as NumberOfInvoice
FROM dimension.dim_product as Pr
INNER JOIN fact.cust_transaction as Fa
ON Pr.ProductID = Fa.ProductID
INNER JOIN dimension.dim_date as Da
ON Fa.DateID = Da.DateID
WHERE Da.month_of_transaction = 11
GROUP BY description;

-- Country sale on November
SELECT country, COUNT(Fa.Invoice) as NumberOfInvoice
FROM dimension.dim_location as Lo
INNER JOIN fact.cust_transaction as Fa
ON Lo.LocationID = Fa.LocationID
INNER JOIN dimension.dim_date as Da
ON Fa.DateID = Da.DateID
WHERE Da.month_of_transaction = 11
GROUP BY country
HAVING  COUNT(Fa.Invoice)> 1;

-- Customer segment
SELECT CustSeg, Ct.TotalPrice AS CustSeg_Value
FROM dimension.dim_customer as Cu
INNER JOIN fact.cust_transaction as Ct
ON Cu.Customer_ID = Ct.Customer_ID;

-- Buying habit

WITH temp
AS
(
SELECT Cu.CustSeg,Pr.Description ,COUNT(description) as NUM, DENSE_RANK() OVER (PARTITION BY CustSeg ORDER BY COUNT(description) DESC) AS RANKCust
FROM dimension.dim_product as Pr
INNER JOIN fact.cust_transaction as Ct
ON Ct.ProductID = Pr.ProductID
INNER JOIN dimension.dim_customer as Cu
ON Cu.Customer_ID = Ct.Customer_ID
GROUP BY Cu.CustSeg,Pr.Description 
)
SELECT Distinct CustSeg, Description
From temp
WHERE RANKCust = 1
ORDER BY Description;


SELECT COUNT(Invoice)
FROM fact.cust_transaction;

SELECT Cu.CustSeg,Pr.Description ,COUNT(description) as NUM
FROM dimension.dim_product as Pr
INNER JOIN fact.cust_transaction as Ct
ON Ct.ProductID = Pr.ProductID
INNER JOIN dimension.dim_customer as Cu
ON Cu.Customer_ID = Ct.Customer_ID
WHERE Cu.CustSeg = 'Loyal'
GROUP BY Cu.CustSeg,Pr.Description 
ORDER BY NUM DESC;

CREATE VIEW dbo.CustSeg_By_Desc 
AS
SELECT Cu.CustSeg,Pr.Description ,COUNT(description) as NUM, DENSE_RANK() OVER (PARTITION BY CustSeg ORDER BY COUNT(description) DESC) AS RANKCust
FROM dimension.dim_product as Pr
INNER JOIN fact.cust_transaction as Ct
ON Ct.ProductID = Pr.ProductID
INNER JOIN dimension.dim_customer as Cu
ON Cu.Customer_ID = Ct.Customer_ID
GROUP BY Cu.CustSeg,Pr.Description;

SELECT Distinct CustSeg, Description
From dbo.CustSeg_By_Desc
WHERE RANKCust = 1;