-- https://microsoft.github.io/sql-ml-tutorials/python/customerclustering/

-- Step 1.3 Enable external script execution
EXEC sp_configure 'external scripts enabled', 1;
RECONFIGURE WITH OVERRIDE

-- Step 2.1 Load the sample data
USE master;
GO
RESTORE DATABASE tpcxbb_1gb
   FROM DISK = 'c:\users\hfleitas\downloads\tpcxbb_1gb.bak'
   WITH
                MOVE 'tpcxbb_1gb' TO 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\tpcxbb_1gb.mdf'
                ,MOVE 'tpcxbb_1gb_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\tpcxbb_1gb.ldf';
GO

USE [master]
GO
ALTER DATABASE [tpcxbb_1gb] SET COMPATIBILITY_LEVEL = 140
GO
exec sp_updatestats 
go

USE tpcxbb_1gb;
SELECT TOP (100) * FROM [dbo].[store_sales];
SELECT TOP (100) * FROM [dbo].[store_returns];


SELECT
    ss_customer_sk AS customer,
    ROUND(COALESCE(returns_count / NULLIF(1.0*orders_count, 0), 0), 7) AS orderRatio,
    ROUND(COALESCE(returns_items / NULLIF(1.0*orders_items, 0), 0), 7) AS itemsRatio,
    ROUND(COALESCE(returns_money / NULLIF(1.0*orders_money, 0), 0), 7) AS monetaryRatio,
    COALESCE(returns_count, 0) AS frequency
    FROM
    (
      SELECT
        ss_customer_sk,
        -- return order ratio
        COUNT(distinct(ss_ticket_number)) AS orders_count,
        -- return ss_item_sk ratio
        COUNT(ss_item_sk) AS orders_items,
        -- return monetary amount ratio
        SUM( ss_net_paid ) AS orders_money
      FROM store_sales s
      GROUP BY ss_customer_sk
    ) orders
    LEFT OUTER JOIN
    (
      SELECT
        sr_customer_sk,
        -- return order ratio
        count(distinct(sr_ticket_number)) as returns_count,
        -- return ss_item_sk ratio
        COUNT(sr_item_sk) as returns_items,
        -- return monetary amount ratio
        SUM( sr_return_amt ) AS returns_money
    FROM store_returns
    GROUP BY sr_customer_sk ) returned ON ss_customer_sk=sr_customer_sk
