

--------------------------------------------------------------
-- First, create a database "stockmarket" under "Databases" --
--------------------------------------------------------------

-- Use pgAdmin's interface

------------------------------------------------------------------------------------
-- Let us now investigate the csv files, create a temporary table and import data --
------------------------------------------------------------------------------------

-- Use Microsoft Excel (OpenOffice or Google Spreasheets) to investigate small csv files
-- Make sure to check the lengths of the fields!

/*
This is only in case you are unable to create it manually
-- LIFELINE
-- DROP TABLE public._temp_company_list;
CREATE TABLE public._temp_company_list
(
    symbol character varying(255) COLLATE pg_catalog."default",
    name character varying(255) COLLATE pg_catalog."default",
    last_sale character varying(255) COLLATE pg_catalog."default",
    net_change character varying(255) COLLATE pg_catalog."default",
	pct_change character varying(255) COLLATE pg_catalog."default",
	market_cap character varying(255) COLLATE pg_catalog."default",
	country character varying(255) COLLATE pg_catalog."default",
    ipo_year character varying(255) COLLATE pg_catalog."default",
    volume character varying(255) COLLATE pg_catalog."default",
    sector character varying(255) COLLATE pg_catalog."default",
    industry character varying(255) COLLATE pg_catalog."default"
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public._temp_company_list
    OWNER to postgres;
*/

-------------------------------------------------
-- Import NASDAQ companies to the temporary table
-------------------------------------------------

/*
	Set the header ON, separator to a comma and text delimiter to double-quote
	
*/

----------------------------------------------
-- Check if we have data in the correct format
-----------------------------------------------
SELECT * FROM _temp_company_list LIMIT 10;
SELECT COUNT(*) from _temp_company_list;

--------------------------------------------------------------
-- Now, let us create the actual tables to transfer data there
--------------------------------------------------------------

-- table stock_mkt with just one column stock_mkt_name(16,PK)

/*
-- LIFELINE
-- DROP TABLE public.stock_mkt;
CREATE TABLE public.stock_mkt
(
    stock_mkt_name character varying(16) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT stock_mkt_pkey PRIMARY KEY (stock_mkt_name)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.stock_mkt
    OWNER to postgres;
*/

-- table company_list with stock_mkt_name(16,PK), symbol(16,PK), company_name(100), market_cap, sector(100), industry(100)

/*
-- LIFELINE

-- DROP TABLE public.company_list;
CREATE TABLE public.company_list
(
    symbol character varying(16) COLLATE pg_catalog."default" NOT NULL,
    stock_mkt_name character varying(16) COLLATE pg_catalog."default" NOT NULL,
    company_name character varying(255) COLLATE pg_catalog."default",
    market_cap double precision,
	country character varying(255) COLLATE pg_catalog."default",
	ipo_year integer,
	sector character varying(255) COLLATE pg_catalog."default",
    industry character varying(255) COLLATE pg_catalog."default",
    CONSTRAINT company_list_pkey PRIMARY KEY (symbol, stock_mkt_name)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.company_list
    OWNER to postgres;

*/

-- We have PK and other entity integrity constraints, now let us set the referential integrity (FK) constraints

/*
-- LIFELINE
ALTER TABLE public.company_list
    ADD CONSTRAINT company_list_fkey FOREIGN KEY (stock_mkt_name)
    REFERENCES public.stock_mkt (stock_mkt_name) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
    NOT VALID;
CREATE INDEX fki_company_list_fkey
    ON public.company_list(stock_mkt_name);
*/
-- Validate the FK (company_list->Constraints->right-click on the fkey->Validate)

----------------------------------------------
-- Populate the final tables with data
-----------------------------------------------

-- First, add the markets to the stock_mkt (otherwise you will get an integrity error)
TRUNCATE TABLE public.stock_mkt; -- Fast delete all content (no restoring) but will not work if we have referential integrity
DELETE FROM stock_mkt; -- The "normal" delete procedure
-- But we have nothing to delete - we need to add data
INSERT INTO stock_mkt (stock_mkt_name) VALUES ('NASDAQ');
-- Check!
SELECT * FROM stock_mkt;

-- Next we will load the company_list with data stored in _temp_company_list
-- Prepare
SELECT symbol, 'NASDAQ' AS stock_mkt_name, name company_name, market_cap,country, ipo_year,sector, industry 
FROM _temp_company_list;

-- INSERT INTO will not work!
INSERT INTO company_list
SELECT symbol, 'NASDAQ' AS stock_mkt_name, name company_name, market_cap, country, ipo_year,sector,industry 
FROM _temp_company_list;

-- Insert with proper casting (type conversion)
INSERT INTO company_list
SELECT symbol, 'NASDAQ' AS stock_mkt_name, name company_name, market_cap::double precision ,country, ipo_year::integer, sector,industry 
FROM _temp_company_list;
-- Check
SELECT * FROM company_list LIMIT 10;
SELECT COUNT(*) FROM company_list;


-----------------------------------------------------------------
-- Dealing with unwanted values  and leading/trailing blanks ----
-----------------------------------------------------------------
SELECT * FROM company_list order by market_cap LIMIT 100;
UPDATE company_list SET market_cap=NULL WHERE market_cap=0;
SELECT * FROM company_list order by market_cap LIMIT 100;

UPDATE stock_mkt SET stock_mkt_name=TRIM(stock_mkt_name);

UPDATE company_list SET 
	stock_mkt_name=TRIM(stock_mkt_name)
	,company_name=TRIM(company_name)
	,country=TRIM(country)	
	,sector=TRIM(sector)
	,industry=TRIM(industry);

SELECT * FROM company_list LIMIT 10;


----------------------------------------------
----------------- Create a View --------------
----------------------------------------------

-- Let us create a view v_company_list using the select statement with numeric market cap

/*
-- LIFELINE

CREATE OR REPLACE VIEW public.v_company_list AS
 SELECT company_list.symbol,
    company_list.stock_mkt_name,
    company_list.company_name,
    company_list.market_cap,
    company_list.country,	
    company_list.sector,
    company_list.industry
   FROM company_list;

ALTER TABLE public.v_company_list
    OWNER TO postgres;

*/

-- Check!
SELECT * FROM v_company_list;


----------------------------------------------------------
----------------- Import EOD (End of Day) Quotes ---------
----------------------------------------------------------
-- Let's assume that this is curated data (so, no temporary table)
-- Use R's read.csv with a row limit to identify the number and types of columns
-- Create table eod_quotes
-- NOTE: ticker and date will be the PK; volume numeric, and other numbers real (4 bytes)
-- NOTE: double precision and bigint will result in an import error on Windows

/*
-- LIFELINE
-- DROP TABLE public.eod_quotes;

CREATE TABLE public.eod_quotes
(
    ticker character varying(16) COLLATE pg_catalog."default" NOT NULL,
    date date NOT NULL,
    adj_open real,
    adj_high real,
    adj_low real,
    adj_close real,
    adj_volume numeric,
    CONSTRAINT eod_quotes_pkey PRIMARY KEY (ticker, date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.eod_quotes
    OWNER to postgres;
*/

-- Import eod.csv to the table - it will take some time (approx. 17 million rows)

-- Check!
SELECT * FROM eod_quotes LIMIT 10;
SELECT COUNT(*) FROM eod_quotes; -- this will take some time the first time; should be 16,891,814

-- Now let's join the view with the table and extract the "NULL" sector in NASDAQ
SELECT ticker,date,company_name,market_cap,country,adj_open,adj_high,adj_low,adj_close,adj_volume
FROM v_company_list C INNER JOIN eod_quotes Q ON C.symbol=Q.ticker 
WHERE C.sector IS NULL AND C.stock_mkt_name='NASDAQ';

-- And let us store the results in a separate table
SELECT ticker,date,company_name,market_cap,country,adj_open,adj_high,adj_low,adj_close,adj_volume
INTO eod_quotes_nasdaq_null_sector
FROM v_company_list C INNER JOIN eod_quotes Q ON C.symbol=Q.ticker 
WHERE C.sector IS NULL AND C.stock_mkt_name='NASDAQ';

-- Check!
SELECT * FROM eod_quotes_nasdaq_null_sector;
-- Adjust the PK by adding a contraint - properties will not work!

/*
--LIFELINE
-- ALTER TABLE public.eod_quotes_nasdaq_null_sector DROP CONSTRAINT eod_quotes_nasdaq_null_sector_pkey;

ALTER TABLE public.eod_quotes_nasdaq_null_sector
    ADD CONSTRAINT eod_quotes_nasdaq_null_sector_pkey PRIMARY KEY (ticker, date);
*/


---------------------------------------------------
----------------- Anaylze the null sector ---------
---------------------------------------------------

-- How many distinct companies (list them)?
SELECT DISTINCT ticker 
FROM eod_quotes_nasdaq_null_sector;

-- But how many?
SELECT COUNT(*) FROM (SELECT DISTINCT ticker FROM eod_quotes_nasdaq_null_sector) A;

-- From how many different countries?
SELECT COUNT(*) FROM (SELECT DISTINCT country FROM eod_quotes_nasdaq_null_sector) A;

-- Date range for all companies
SELECT ticker, MIN(date) AS first_date, MAX(date) as last_date
FROM eod_quotes_nasdaq_null_sector
GROUP BY ticker
ORDER BY first_date;

-- Which company/companies (if any) was/were listed first?
SELECT DISTINCT ticker,date FROM eod_quotes_nasdaq_null_sector
WHERE date = (SELECT MIN(date) FROM eod_quotes_nasdaq_null_sector);

-- Which company/companies (if any) was/were listed last?
-- Not so simple...
SELECT ticker, MIN(date) AS first_date, MAX(date) as last_date
FROM eod_quotes_nasdaq_null_sector
GROUP BY ticker
HAVING MIN(date)= 
	(
	SELECT MAX(first_date) 
	FROM (SELECT ticker, MIN(date) AS first_date FROM eod_quotes_nasdaq_null_sector GROUP BY ticker) LFD
	);

-- Extract date parts
-- https://www.postgresql.org/docs/10/static/functions-datetime.html
SELECT *, date_part('year',date) AS Y,date_part('month',date) AS M,date_part('day',date) AS D 
FROM eod_quotes_nasdaq_null_sector;


--------------------------------------------
----------------- Review JOINS -------------
--------------------------------------------

-- We have reviewed the inner join, let's now look at outer joins
-- Which NASDAQ v_company_list companies are not present in the eod_quotes (large) table?
-- Method 1
SELECT DISTINCT symbol FROM v_company_list C LEFT JOIN eod_quotes Q ON C.symbol=Q.ticker
WHERE C.stock_mkt_name='NASDAQ' AND Q.ticker IS NULL;
-- Method 2
SELECT DISTINCT symbol
FROM v_company_list 
WHERE stock_mkt_name='NASDAQ' AND symbol NOT IN (SELECT DISTINCT ticker FROM eod_quotes);

-- Which eod_quotes (large) table companies are not present in the NASDAQ v_company_list view?
-- Method 1
SELECT DISTINCT ticker 
FROM (SELECT * FROM v_company_list WHERE stock_mkt_name='NASDAQ') C RIGHT JOIN eod_quotes Q ON C.symbol=Q.ticker
WHERE C.symbol IS NULL;
-- Method 2
SELECT DISTINCT ticker 
FROM eod_quotes 
WHERE ticker NOT IN (SELECT DISTINCT symbol FROM v_company_list WHERE stock_mkt_name='NASDAQ');

-- Provide the full list of unique tickers from the v_company_list and eod_quotes
-- Method 1 - takes too long!
SELECT DISTINCT CASE WHEN symbol IS NULL THEN ticker WHEN ticker IS NULL THEN symbol ELSE ticker END AS tck
FROM v_company_list C FULL OUTER JOIN eod_quotes Q ON C.symbol=Q.ticker;

-- Method 2 - much faster
SELECT DISTINCT symbol FROM v_company_list
UNION
SELECT DISTINCT ticker FROM eod_quotes;

--------------------------------------------
----------------- WILDCARDS -------------
--------------------------------------------

-- Which company names include 'Tech'?

SELECT DISTINCT company_name
FROM v_company_list 
WHERE company_name LIKE '%Tech%'



----------------------------------------------
----------------- End of Part  ---------------
----------------------------------------------

-- What is the date range?
SELECT min(date),max(date) FROM eod_quotes;

-- Really? How many companies have full data in each year?
SELECT date_part('year',date), COUNT(*)/252 FROM eod_quotes GROUP BY date_part('year',date);

-- Let's decide on some practical time range (e.g. 2015-2020)
SELECT ticker, date, adj_close FROM eod_quotes WHERE date BETWEEN '2015-01-01' AND '2020-12-31';

-- And create a (simple version of) view v_eod_quotes_2015_2020
/*
-- LIFELINE
-- DROP VIEW public.v_eod_quotes_2015_2020;

CREATE OR REPLACE VIEW public.v_eod_quotes_2015_2020 AS
 SELECT eod_quotes.ticker,
    eod_quotes.date,
    eod_quotes.adj_close
   FROM eod_quotes
  WHERE eod_quotes.date >= '2015-01-01'::date AND eod_quotes.date <= '2020-12-31'::date;

ALTER TABLE public.v_eod_quotes_2015_2020
    OWNER TO postgres;

*/

-- Check
SELECT min(date),max(date) FROM v_eod_quotes_2015_2020;

-------------------------------------------------------------
-- Next, let's us explore the required packages in R --------
-------------------------------------------------------------

-- Install PerformanceAnalytics and PortfolioAnalytics using RStudio


-------------------------------------------------------------------------
-- We have stock quotes but we could also use daily index data ----------
-------------------------------------------------------------------------

-- Let's download 2015-2020 of SP500TR from Yahoo https://finance.yahoo.com/quote/%5ESP500TR/history?p=^SP500TR

-- An analysis of the CSV indicated that to make it compatible with eod
-- - all unusual formatting has to be removed
-- - a "ticker" column with the value SP500TR need to be added 
-- - the volume column has to be updated (zeros are fine)

-- Import the (modified) CSV to a (new) data table eod_indices which reflects the original file's structure

/*

LIFELINE:

-- DROP TABLE public.eod_indices;

CREATE TABLE public.eod_indices
(
    symbol character varying(16) COLLATE pg_catalog."default" NOT NULL,
    date date NOT NULL,
    open real,
    high real,
    low real,
    close real,
    adj_close real,
    volume double precision,
    CONSTRAINT eod_indices_pkey PRIMARY KEY (symbol, date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.eod_indices
    OWNER to postgres;

*/

-- Check
SELECT * FROM eod_indices LIMIT 10;

-- Create a view analogous to our quotes view: v_eod_indices_2015_2020

/*
--LIFELINE
-- DROP VIEW public.v_eod_indices_2015_2020;

CREATE OR REPLACE VIEW public.v_eod_indices_2015_2020 AS
 SELECT eod_indices.symbol,
    eod_indices.date,
    eod_indices.adj_close
   FROM eod_indices
   WHERE eod_indices.date >= '2015-01-01'::date AND eod_indices.date <= '2020-12-31'::date;

   
ALTER TABLE public.v_eod_indices_2015_2020
    OWNER TO postgres;
*/

-- CHECK
SELECT MIN(date),MAX(date) FROM v_eod_indices_2015_2020;

-- We can combine the two views using UNION which help us later (this will take a while)
SELECT * FROM v_eod_quotes_2015_2020 
UNION 
SELECT * FROM v_eod_indices_2015_2020;

-------------------------------------------------------------------------
-- Next, let's prepare a custom calendar (using a spreadsheet) --------
-------------------------------------------------------------------------

-- We need a stock market calendar to check our data for completeness
-- https://www.nyse.com/markets/hours-calendars

-- Because it is faster, we will use Excel (we need market holidays to do that)

-- We will use NETWORKDAYS.INTL function

-- date, y,m,d,dow,trading (format date and dow!)

-- Save as custom_calendar.csv and import to a new table

/*
LIFELINE:
-- DROP TABLE public.custom_calendar;

CREATE TABLE public.custom_calendar
(
    date date NOT NULL,
    y integer,
    m integer,
    d integer,
    dow character varying(3) COLLATE pg_catalog."default",
    trading smallint,
    CONSTRAINT custom_calendar_pkey PRIMARY KEY (date)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.custom_calendar
    OWNER to postgres;

*/

-- CHECK:
SELECT * FROM custom_calendar LIMIT 10;

-- Let's add some columns to be used later: eom (end-of-month) and prev_trading_day

/*
-- LIFELINE
ALTER TABLE public.custom_calendar
    ADD COLUMN eom smallint;

ALTER TABLE public.custom_calendar
    ADD COLUMN prev_trading_day date;
*/

-- CHECK:
SELECT * FROM custom_calendar LIMIT 10;

-- Now let's populate these columns

-- Identify trading days
SELECT * FROM custom_calendar WHERE trading=1;
-- Identify previous trading days via a nested query
SELECT date, (SELECT MAX(CC.date) FROM custom_calendar CC 
			  WHERE CC.trading=1 AND CC.date<custom_calendar.date) ptd 
			  FROM custom_calendar;
-- Update the table with new data 
UPDATE custom_calendar
SET prev_trading_day = PTD.ptd
FROM (SELECT date, (SELECT MAX(CC.date) FROM custom_calendar CC WHERE CC.trading=1 AND CC.date<custom_calendar.date) ptd FROM custom_calendar) PTD
WHERE custom_calendar.date = PTD.date;
-- CHECK
SELECT * FROM custom_calendar ORDER BY date;
-- We could really use the last trading day of 2014 (as the end of the month)
INSERT INTO custom_calendar VALUES('2014-12-31',2014,12,31,'Wed',1,1,NULL);
-- Re-run the update
-- CHECK again
SELECT * FROM custom_calendar ORDER BY date;

-- Identify the end of the month
SELECT CC.date,CASE WHEN EOM.y IS NULL THEN 0 ELSE 1 END endofm FROM custom_calendar CC LEFT JOIN
(SELECT y,m,MAX(d) lastd FROM custom_calendar WHERE trading=1 GROUP by y,m) EOM
ON CC.y=EOM.y AND CC.m=EOM.m AND CC.d=EOM.lastd;
-- Update the table with new data
UPDATE custom_calendar
SET eom = EOMI.endofm
FROM (SELECT CC.date,CASE WHEN EOM.y IS NULL THEN 0 ELSE 1 END endofm FROM custom_calendar CC LEFT JOIN
(SELECT y,m,MAX(d) lastd FROM custom_calendar WHERE trading=1 GROUP by y,m) EOM
ON CC.y=EOM.y AND CC.m=EOM.m AND CC.d=EOM.lastd) EOMI
WHERE custom_calendar.date = EOMI.date;
-- CHECK
SELECT * FROM custom_calendar ORDER BY date;
SELECT * FROM custom_calendar WHERE eom=1 ORDER BY date;

------------------------------------------------------------------
-- We can now use the calendar to query prices and indexes -------
------------------------------------------------------------------

-- Calculate stock price (or index value) statistics

-- min, average, max and volatility (st.dev) of prices/index values for each month
SELECT symbol, y,m,min(adj_close) as min_adj_close,avg(adj_close) as avg_adj_close, max(adj_close) as max_adj_close,stddev_samp(adj_close) as std_adj_close 
FROM custom_calendar CC INNER JOIN v_eod_indices_2015_2020 II ON CC.date=II.date
GROUP BY symbol,y,m
ORDER BY symbol,y,m;

-- Identify end-of-month prices/values for stock or index
SELECT II.*
FROM custom_calendar CC INNER JOIN v_eod_indices_2015_2020 II ON CC.date=II.date
WHERE CC.eom=1
ORDER BY II.date;

------------------------------------------------------------------
-- Determine the completeness of price or index data -------------
------------------------------------------------------------------

-- Incompleteness may be due to when the stock was listed/delisted or due to errors

-- First, let's see how many trading days were there between 2015 and 2020
SELECT COUNT(*) 
FROM custom_calendar 
WHERE trading=1 AND date BETWEEN '2015-01-01' AND '2020-12-31';

-- Now, let us check how many price items we have for each stock in the same date range
SELECT ticker,min(date) as min_date, max(date) as max_date, count(*) as price_count
FROM v_eod_quotes_2015_2020
GROUP BY ticker
ORDER BY price_count DESC;

-- Let's calculate the percentage of complete trading day prices for each stock and identify 99%+ complete
SELECT ticker
, count(*)::real/(SELECT COUNT(*) FROM custom_calendar WHERE trading=1 AND date BETWEEN '2015-01-01' AND '2020-12-31')::real as complete
FROM v_eod_quotes_2015_2020
GROUP BY ticker
HAVING count(*)::real/(SELECT COUNT(*) FROM custom_calendar WHERE trading=1 AND date BETWEEN '2015-01-01' AND '2020-12-31')::real>=0.99
ORDER BY complete DESC;


-- Let's store the excluded tickers (less than 99% complete in a table)
SELECT ticker, 'More than 1% missing' as reason
INTO exclusions_2015_2020
FROM v_eod_quotes_2015_2020
GROUP BY ticker
HAVING count(*)::real/(SELECT COUNT(*) FROM custom_calendar WHERE trading=1 AND date BETWEEN '2015-01-01' AND '2020-12-31')::real<0.99;

-- Also define the PK constraint for exclusions_2015_2020
/*
-- LIFELINE:
ALTER TABLE public.exclusions_2015_2020
    ADD CONSTRAINT exclusions_2015_2020_pkey PRIMARY KEY (ticker);
*/


-- CHECK
SELECT * FROM exclusions_2015_2020;

-- We will be adding rows to exclusions_2015_2020 table (for other reasons) later

-- Let combine everything we have (it will take some time to execute)
SELECT * FROM v_eod_indices_2015_2020 WHERE symbol NOT IN  (SELECT DISTINCT ticker FROM exclusions_2015_2020)
UNION
SELECT * FROM v_eod_quotes_2015_2020 WHERE ticker NOT IN  (SELECT DISTINCT ticker FROM exclusions_2015_2020);

-- And let's store it as a new view v_eod_2015_2020

/*
-- LIFELINE:
-- DROP VIEW public.v_eod_2015_2020;

CREATE OR REPLACE VIEW public.v_eod_2015_2020 AS
 SELECT v_eod_indices_2015_2020.symbol,
    v_eod_indices_2015_2020.date,
    v_eod_indices_2015_2020.adj_close
   FROM v_eod_indices_2015_2020
  WHERE NOT (v_eod_indices_2015_2020.symbol::text IN ( SELECT DISTINCT exclusions_2015_2020.ticker
           FROM exclusions_2015_2020))
UNION
 SELECT v_eod_quotes_2015_2020.ticker AS symbol,
    v_eod_quotes_2015_2020.date,
    v_eod_quotes_2015_2020.adj_close
   FROM v_eod_quotes_2015_2020
  WHERE NOT (v_eod_quotes_2015_2020.ticker::text IN ( SELECT DISTINCT exclusions_2015_2020.ticker
           FROM exclusions_2015_2020));

ALTER TABLE public.v_eod_2015_2020
    OWNER TO postgres;

*/

-- CHECK:
SELECT * FROM v_eod_2015_2020; -- slow
SELECT DISTINCT symbol FROM v_eod_2015_2020;

-- Let's create a materialized view mv_eod_2015_2020

/*
--LIFELINE

-- DROP MATERIALIZED VIEW public.mv_eod_2015_2020;

CREATE MATERIALIZED VIEW public.mv_eod_2015_2020
TABLESPACE pg_default
AS
 SELECT v_eod_indices_2015_2020.symbol,
    v_eod_indices_2015_2020.date,
    v_eod_indices_2015_2020.adj_close
   FROM v_eod_indices_2015_2020
  WHERE NOT (v_eod_indices_2015_2020.symbol::text IN ( SELECT DISTINCT exclusions_2015_2020.ticker
           FROM exclusions_2015_2020))
UNION
 SELECT v_eod_quotes_2015_2020.ticker AS symbol,
    v_eod_quotes_2015_2020.date,
    v_eod_quotes_2015_2020.adj_close
   FROM v_eod_quotes_2015_2020
  WHERE NOT (v_eod_quotes_2015_2020.ticker::text IN ( SELECT DISTINCT exclusions_2015_2020.ticker
           FROM exclusions_2015_2020))
WITH NO DATA;

ALTER TABLE public.mv_eod_2015_2020
    OWNER TO postgres;
*/

-- We must refresh it (it will take time but it is one-time or infrequent)
REFRESH MATERIALIZED VIEW mv_eod_2015_2020 WITH DATA;

-- CHECK
SELECT * FROM mv_eod_2015_2020; -- faster
SELECT DISTINCT symbol FROM mv_eod_2015_2020; -- fast
SELECT * FROM mv_eod_2015_2020 WHERE symbol='AAPL' ORDER BY date;
SELECT * FROM mv_eod_2015_2020 WHERE symbol='SP500TR' ORDER BY date;

-- We can even add a couple of indexes to our materialized view if we want to speed up access some more

--------------------------------------------------------
-- Calculate daily returns or changes ------------------
--------------------------------------------------------

-- We will assume the following definition R_1=(P_1-P_0)/P_0=P_1/P_0-1.0 (P:price, i.e., adj_close)

-- First let us join the calendar with the prices (and indices)

SELECT EOD.*, CC.* 
FROM mv_eod_2015_2020 EOD INNER JOIN custom_calendar CC ON EOD.date=CC.date;

-- Next, let us use the prev_trading_day in a join to determine prev_adj_close (this will take some time)
SELECT EOD.symbol,EOD.date,EOD.adj_close,PREV_EOD.date AS prev_date,PREV_EOD.adj_close AS prev_adj_close
FROM mv_eod_2015_2020 EOD INNER JOIN custom_calendar CC ON EOD.date=CC.date
INNER JOIN mv_eod_2015_2020 PREV_EOD ON PREV_EOD.symbol=EOD.symbol AND PREV_EOD.date=CC.prev_trading_day;

-- Change the columns in the select clause to return (ret) and create another materialized view mv_ret_2015_2020
SELECT EOD.symbol,EOD.date,EOD.adj_close/PREV_EOD.adj_close-1.0 AS ret
FROM mv_eod_2015_2020 EOD INNER JOIN custom_calendar CC ON EOD.date=CC.date
INNER JOIN mv_eod_2015_2020 PREV_EOD ON PREV_EOD.symbol=EOD.symbol AND PREV_EOD.date=CC.prev_trading_day;

-- Let's make another materialized view - this time with the returns

/*
-- LIFELINE:

-- DROP MATERIALIZED VIEW public.mv_ret_2015_2020;

CREATE MATERIALIZED VIEW public.mv_ret_2015_2020
TABLESPACE pg_default
AS
 SELECT eod.symbol,
    eod.date,
    eod.adj_close / prev_eod.adj_close - 1.0::double precision AS ret
   FROM mv_eod_2015_2020 eod
     JOIN custom_calendar cc ON eod.date = cc.date
     JOIN mv_eod_2015_2020 prev_eod ON prev_eod.symbol::text = eod.symbol::text AND prev_eod.date = cc.prev_trading_day
WITH NO DATA;

ALTER TABLE public.mv_ret_2015_2020
    OWNER TO postgres;
*/

-- We must refresh it (it will take time but it is one-time or infrequent)
REFRESH MATERIALIZED VIEW mv_ret_2015_2020 WITH DATA;

-- CHECK
SELECT * FROM mv_ret_2015_2020;
SELECT * FROM mv_ret_2015_2020 WHERE symbol='AAPL' ORDER BY date;
SELECT * FROM mv_ret_2015_2020 WHERE symbol='SP500TR' ORDER BY date;

------------------------------------------------------------------
-- Identify potential errors and expand the exlusions list --------
------------------------------------------------------------------

-- Let's explore first
SELECT min(ret),avg(ret),max(ret) from mv_ret_2015_2020;
SELECT * FROM mv_ret_2015_2020 ORDER BY ret DESC;

-- Make an arbitrary decision how much daily return is too much (e.g. 100%), identify such symbols
-- and add them to exclusions_2015_2020
INSERT INTO exclusions_2015_2020
SELECT DISTINCT symbol, 'Return higher than 100%' as reason FROM mv_ret_2015_2020 WHERE ret>1.0;

-- CHECK:
SELECT * FROM exclusions_2015_2020 WHERE reason LIKE 'Return%' ORDER BY ticker;
-- They should be excluded BUT THEY ARE NOT!
SELECT * FROM mv_eod_2015_2020 WHERE symbol='GWPH';
SELECT * FROM mv_ret_2015_2020 WHERE symbol='GWPH' ORDER BY ret DESC;
-- IMPORTANT: we have stored (materialized) views, we need to refresh them IN A SEQUENCE!
REFRESH MATERIALIZED VIEW mv_eod_2015_2020 WITH DATA;
-- CHECK:
SELECT * FROM mv_eod_2015_2020 WHERE symbol='GWPH'; -- excluded

REFRESH MATERIALIZED VIEW mv_ret_2015_2020 WITH DATA;
-- CHECK:
SELECT * FROM mv_ret_2015_2020 WHERE symbol='GWPH'; -- excluded
-- We can continue adding exclusions for various reasons - remember to refresh the stored views

---------------------------------------------------------------------------
-- Format price and return data for export to the analytical tool  --------
---------------------------------------------------------------------------

-- In order to export all data we will left-join custom_calendar with materialized views
-- This way we will not miss a trading day even if there is not a single record available
-- It is very important when data is updated daily

-- We may need to write data to (temporary) tables so that we can export them to CSV
-- Or we can select the query and use "Download as CSV (F8)" in PgAdmin

-- Daily prices export
SELECT PR.* 
INTO export_daily_prices_2015_2020
FROM custom_calendar CC LEFT JOIN mv_eod_2015_2020 PR ON CC.date=PR.date
WHERE CC.trading=1;

-- Monthly (eom) prices export
SELECT PR.* 
INTO export_monthly_prices_2015_2020
FROM custom_calendar CC LEFT JOIN mv_eod_2015_2020 PR ON CC.date=PR.date
WHERE CC.trading=1 AND CC.eom=1;

-- Daily returns export
SELECT PR.* 
INTO export_daily_returns_2015_2020
FROM custom_calendar CC LEFT JOIN mv_ret_2015_2020 PR ON CC.date=PR.date
WHERE CC.trading=1;

-- Remove temporary (export_) tables because they are not refreshed
DROP TABLE export_daily_prices_2015_2020;
DROP TABLE export_monthly_prices_2015_2020;
DROP TABLE export_daily_returns_2015_2020;


CREATE EXTENSION IF NOT EXISTS tablefunc;

-- crosstab is not going to work because crosstab requires pre-specyfying types for all columns
SELECT * 
FROM crosstab('SELECT date, symbol, adj_close from mv_eod_2015_2020 ORDER BY 1,2','SELECT DISTINCT symbol FROM mv_eod_2015_2020 ORDER BY 1') 
AS ct(dte date, A real);
-- Technically we could code a custom return type but it would be very tedious and one-time
-- The problem here is that we need to manually define return types for all 2000+ stock tickers
-- If you think you can work-around that with /crosstabview (PSQL) - you can't because of 1600 columns limit
-- So, we will deal with pivoting in R (Excel will not take 6M+ rows)

-------------------------------------------
-- Create a role for the database  --------
-------------------------------------------
-- rolename: stockmarketreader
-- password: read123

/*
-- LIFELINE:
-- REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM stockmarketreader;
-- DROP USER stockmarketreader;

CREATE USER stockmarketreader WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	CONNECTION LIMIT -1
	PASSWORD 'read123';
*/

-- Grant read rights (on existing tables and views)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO stockmarketreader;

-- Grant read rights (for future tables and views)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT ON TABLES TO stockmarketreader;
   

SELECT LEFT(symbol,1) letter,COUNT(*) as no_of_symbols
FROM
(SELECT DISTINCT symbol FROM mv_eod_2015_2020) S
GROUP BY LEFT(symbol,1)
ORDER BY letter;

