USE blinkit;

select  * from `blinkit grocery data`;

#Update Item_Fat_Content in the blinkit grocery data table 
update `blinkit`.`blinkit grocery data`
SET  Item_Fat_Content =
CASE
   when Item_Fat_Content IN ( 'LF' , 'low fat') THEN 'Low Fat'
   when Item_Fat_Content  = 'reg' THEN 'Regular'
   ELSE Item_Fat_Content
END

-- 1. Joins:
-- Assume we split this dataset into two tables: items and outlets.
-- This query joins the items and outlets tables on Outlet Identifier, retrieving item and outlet details along with total sales.

-- Join items and outlets tables to combine item and outlet information
SELECT 
    i.[Item Identifier],  -- Unique identifier for the item
    i.[Item Type],        -- Category or type of the item
    o.[Outlet Identifier],-- Unique identifier for the outlet
    o.[Outlet Type],      -- Type of outlet (e.g., supermarket, convenience store)
    i.[Total Sales]       -- Total sales amount for the item
FROM items i
JOIN outlets o 
    ON i.[Outlet Identifier] = o.[Outlet Identifier]; -- Match records based on Outlet Identifier

-- 2. CTE (Common Table Expression):
-- Calculate average sales per item type.
-- Calculate average sales per item type and sort by descending order
WITH avg_sales AS (
    SELECT 
        `Item Type`,                     -- Column for item category
        AVG(`Total Sales`) AS avg_item_sales -- Compute average sales for each item type
    FROM `blinkit grocery data`                  -- Source table
    GROUP BY `Item Type`                 -- Group by item type
)
SELECT * 
FROM avg_sales 
ORDER BY avg_item_sales DESC;            -- Sort by average sales in descending order

-- 3. Temp Table:
-- Create a temp table for outlets with high average ratings.

CREATE TEMPORARY TABLE high_rating_outlets AS
SELECT 
    `Outlet Identifier`,
    AVG(Rating) AS avg_rating
FROM `blinkit grocery data`
GROUP BY `Outlet Identifier`
HAVING AVG(Rating) > 3.5;

SELECT * FROM high_rating_outlets;

-- 4. Window Function:
-- Rank items by total sales within each outlet.
SELECT 
    `Outlet Identifier`,
    `Item Identifier`,
    `Total Sales`,
    RANK() OVER (PARTITION BY `Outlet Identifier` ORDER BY `Total Sales` DESC) AS rank_in_outlet
FROM `blinkit grocery data`;

-- 5. Aggregate Functions:
-- Get total sales, average rating, and average item weight per item type.
SELECT 
    `Item Type`,
    SUM(`Total Sales`) AS total_sales,
    AVG(`Rating`) AS avg_rating,
    AVG(`Item Weight`) AS avg_weight
FROM `blinkit grocery data`
GROUP BY `Item Type`;

-- 6. Create a View:
-- View for outlet performance summary.
CREATE VIEW outlet_performance_summary AS
SELECT 
    `Outlet Identifier`,
    `Outlet Type`,
    COUNT(DISTINCT `Item Identifier`) AS total_items_sold,
    SUM(`Total Sales`) AS total_sales,
    AVG(`Rating`) AS avg_rating
FROM `blinkit grocery data`
GROUP BY `Outlet Identifier`, `Outlet Type`;

select * from outlet_performance_summary;

--  for final profit analysis, we usually need:
-- Revenue (Total Sales)
-- Cost (either per item or estimated)
-- Profit = Revenue - Cost
-- Optional: group by outlet, item type, category, or time period
-- Since the dataset has Total Sales, but no explicit cost, we can simulate cost by:
-- Assuming a uniform cost rate (e.g., 70% of sales as cost), or
-- Assuming cost = Item Weight × estimated price per kg/unit

-- Let’s go with a simple assumption for now:
-- Cost = 70% of Total Sales
-- Profit = Total Sales - Cost = 30% of Total Sales

--  Final Profit Analysis Queries:
--  Overall Profit Summary
SELECT 
    cast(SUM(`Total Sales`) as decimal(10,2)) AS 	Total_revenue,
    cast(SUM(`Total Sales`) * 0.7 as decimal(10,2)) AS Estimated_cost,
    cast(SUM(`Total Sales`) * 0.3 as decimal(10,2))AS Estimated_profit
FROM `blinkit grocery data`;

--  Profit by Item Type
SELECT 
    `Item Type`,
    cast(SUM(`Total Sales`) as decimal(10,2)) AS total_revenue,
    cast(SUM(`Total Sales`) * 0.7 as decimal(10,2)) AS estimated_cost,
    cast(SUM(`Total Sales`) * 0.3 as decimal(10,2)) AS estimated_profit
FROM `blinkit grocery data`
GROUP BY `Item Type`
ORDER BY estimated_profit DESC;

-- Profit by Outlet
SELECT 
    `Outlet Identifier`,
    `Outlet Type`,
    cast(SUM(`Total Sales`) as decimal(10,2)) AS total_revenue,
    cast(SUM(`Total Sales`) * 0.7 as decimal(10,2)) AS estimated_cost,
    cast(SUM(`Total Sales`) * 0.3 as decimal(10,2)) AS estimated_profit
FROM `blinkit grocery data`
GROUP BY `Outlet Identifier`, `Outlet Type`
ORDER BY estimated_profit DESC;

-- Profit by Fat Content (Interesting consumer insight) 
SELECT 
    `Item_Fat_Content`,
    cast(SUM(`Total Sales`) as decimal(10,2)) AS total_revenue,
    cast(SUM(`Total Sales`) * 0.3 as decimal(10,2)) AS estimated_profit
FROM `blinkit grocery data`
GROUP BY `Item_Fat_Content`;

-- actual profit percentage assuming 70% cost price and 30% profit 
SELECT 
    cast(SUM(`Total Sales`) as decimal(10,2)) AS Total_revenue,
    cast(SUM(`Total Sales`) * 0.3 as decimal(10,2)) AS Total_profit,
    (SUM(`Total Sales`) * 0.3) / SUM(`Total Sales`) * 100  AS profit_percentage
FROM `blinkit grocery data`;

-- To improve profit by 34%,focus on either increasing revenue, reducing cost,or both. 
-- Since profit = revenue - cost:

-- 📈 GOAL: Increase Profit by 34%
-- Let’s assume current profit is P. To get 1.34 × P

-- Strategy	                            How to Achieve it (with your data)
-- Increase revenue                  	Boost total sales via marketing, product focus, or pricing
-- Reduce cost	                        Cut supply, logistics, or packaging cost
-- Optimize high-profit areas	        Double down on top-performing items/outlets
-- Phase out low performers	Identify    low-profit items/outlets and reduce focus

-- Action	                                    Impact on Profit
-- Reduce cost from 70% to 65%	                       +18.3%
-- Focus sales effort on top 5 profitable items	       +10%
-- Minor price increase for low-margin items	       +6%
-- Total Impact (estimated)	                         +34.3% 


WITH item_summary AS (  #Makes it easier to reuse the item_summary CTE for other metrics (e.g., average rating)
    SELECT 
        `Item Type`,
        SUM(`Total Sales`) AS total_sales
    FROM `blinkit grocery data`
    GROUP BY `Item Type`
)
SELECT 
    `Item Type`,
    total_sales AS total_revenue,
    ROUND(total_sales * 0.7, 2) AS estimated_cost,
    ROUND(total_sales * 0.3, 2) AS estimated_profit
FROM item_summary
ORDER BY estimated_profit DESC;

--  similar logic for:
-- Outlet-level profit analysis
-- Fat content group profit
-- Monthly or yearly profit trends (if dates are available)

-- Optimized Profit by Outlet

WITH outlet_sales AS (
    SELECT 
        `Outlet Identifier`,
        `Outlet Type`,
        SUM(`Total Sales`) AS total_sales
    FROM `blinkit grocery data`
    GROUP BY `Outlet Identifier`, `Outlet Type`
)
SELECT 
    `Outlet Identifier`,
    `Outlet Type`,
    cast(total_sales as decimal(10,2)) AS total_revenue,
    cast(total_sales * 0.7 as decimal(10,2)) AS estimated_cost,
    cast(total_sales * 0.3 as decimal(10,2)) AS estimated_profit
FROM outlet_sales
ORDER BY estimated_profit DESC;

