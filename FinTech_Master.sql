-- 1. OVERVIEW REPORT
	-- 1.1. HOW MANY CUSTOMERS ARE IN THE TABLE "CUSTOMERS?" ARE THESE CUSTOMERS ALL UNIQUE CUSTOMERS?
CREATE VIEW customer_overview AS
SELECT 
	-- NUMBER OF CUSTOMERS IN DATABASE
	COUNT(public.customers.customer_id) AS num_customers,
	-- UNIQUE NUMBER OF CUSTOMERS IN DATABASE 
	COUNT(DISTINCT public.customers.customer_id) AS uniq_num_customers
FROM public.customers;

SELECT *
FROM customer_overview;

	-- 1.2. HOW MANY LOANS ARE SIGNED PER CUSTOMER?
WITH number_loans_cte AS(
	SELECT
		customer_id,
		COUNT(loan_id) AS number_loans
	FROM sales
	GROUP BY customer_id)
	
SELECT 
	MIN(number_loans) AS min_number_loans,
	MAX(number_loans) AS max_number_loans,
	ROUND(AVG(number_loans),2) AS avg_number_loans
FROM number_loans_cte;

	-- 1.3. WHAT COUNTRIES ARE THE CUSTOMERS FROM AND WHAT IS THE MOST IMPORTANT MARKET?
CREATE VIEW geographical_sales_distribution AS
SELECT 
	public.currencies.country_name AS country_name,
	COUNT(public.sales.loan_id) AS num_loans,
	SUM(public.sales.loan_amount)::numeric(1000,2) AS signed_value,
	public.currencies.currency AS currency
FROM public.sales
	LEFT JOIN public.customers
		ON public.sales.customer_id = public.customers.customer_id
	LEFT JOIN public.currencies
		ON public.customers.country_id = public.currencies.country_id
GROUP BY country_name, currency
ORDER BY signed_value DESC;

SELECT 
	*,
	ROUND(signed_value / (SELECT SUM(signed_value) FROM geographical_sales_distribution),2) AS signed_value_share
FROM geographical_sales_distribution;


	-- 1.4. WHAT DIFERENT CURRENCIES ARE AMONG THE CUSTOMER DATA?
CREATE VIEW customers_geographics AS
SELECT 
	public.currencies.country_name AS country_name,
	public.currencies.currency AS currency,
	COUNT(public.customers.customer_id) AS num_customers
FROM public.customers
	LEFT JOIN public.currencies
	ON public.customers.country_id = public.currencies.country_id
GROUP BY public.currencies.country_name, public.currencies.currency
ORDER BY num_customers DESC;

SELECT *
FROM customers_geographics;

SELECT
	currency,
	SUM(num_customers) as num_customers,
	ROUND(SUM(num_customers) / (SELECT SUM(num_customers) FROM customers_geographics),2) as prct_customers
FROM customers_geographics
GROUP BY currency;


-- 2. DATA PREPARATION
	-- 2.1. STANDARDIZ TABLE "SALES" TO EUR.

CREATE VIEW sales_eur AS
SELECT
	s.loan_id,
	s.customer_id,
	s.loan_acquisition_date,
	s.loan_amount,
	s.interest_rate_pm,
	c.customer_acquisition_channel_id,
	fx.currency,
	fx.fx_to_eur,
	ROUND(s.loan_amount * fx.fx_to_eur,2) AS loan_amount_EUR
FROM sales AS s
	LEFT JOIN customers AS c
		ON s.customer_id = c.customer_id
	LEFT JOIN currencies AS fx
		ON c.country_id = fx.country_id;
	
SELECT *
FROM sales_eur;

	-- 2.2. 	STANDADIZE TABLE "TRANSACTIONS" TO EUR.
CREATE VIEW transactions_eur AS
SELECT
	t.date,
	t.amount,
	t.customer_id,
	t.transaction_type,
	t.transaction_id,
	t.loan_id,
	fx.currency,
	fx.fx_to_eur,
	ROUND(t.amount * fx.fx_to_eur,2) AS amount_EUR
FROM transactions AS t
	LEFT JOIN customers AS c
		ON t.customer_id = c.customer_id
	LEFT JOIN currencies AS fx
		ON c.country_id = fx.country_id;
	
SELECT *
FROM transactions_eur;


-- 3. DATA ANALYTICS
	-- 3.1 UNDERSTAND THE SALES PERFORMANCE BY LOOKING AT THE NUMBER OF SIGNED LOANS, SIGNED VALUE (EUR) PER MONTH. ALSO ANALYSE THE MONTH-OVER-MONTH (MOM) AND YEAR-OVER-YEAR (YOY) GROWTH.

CREATE VIEW monthly_sales_performance AS
(SELECT
	loan_id,
	loan_acquisition_date,
	loan_amount_eur,
	customer_acquisition_channel,
	DATE_TRUNC('MONTH',loan_acquisition_date)::DATE AS sales_month
FROM sales_eur AS s
 	LEFT JOIN customers AS c
 		ON s.customer_id = c.customer_id
	LEFT JOIN acquisition_channels AS ac
		ON c.customer_acquisition_channel_id = ac.customer_acquisition_channel_id)

SELECT
	sales_month,
	COUNT(DISTINCT loan_id) AS num_loans,
	SUM(loan_amount_eur) AS signed_value,
	ROUND((SUM(loan_amount_eur) / LAG(SUM(loan_amount_eur),1) OVER(ORDER BY sales_month)) -1,2) AS mom_value_growth,
	ROUND((SUM(loan_amount_eur) / LAG(SUM(loan_amount_eur),12) OVER(ORDER BY sales_month)) -1,2) AS yoy_value_growth,
	RANK() OVER(ORDER BY SUM(loan_amount_eur) DESC) AS ranking_best_month
FROM monthly_sales_performance
GROUP BY sales_month
ORDER BY sales_month ASC;

	-- 3.2. ANALYZE ACQUISITION PER CHANNEL.
SELECT
	customer_acquisition_channel,
	COUNT(DISTINCT loan_id) AS num_loans,
	SUM(loan_amount_eur) AS signed_value,
	ROUND(SUM(loan_amount_eur) / (SELECT SUM(loan_amount_eur) FROM monthly_sales_performance),2) AS share_total_sales
FROM monthly_sales_performance
GROUP BY customer_acquisition_channel
ORDER BY signed_value DESC;


	-- 3.3. UNDERSTAND THE BEST PERFORMING CUSTOMER ACQUISITION CHANNEL PER MONTH.
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * 
FROM CROSSTAB($$
	SELECT
		sales_month,
		customer_acquisition_channel,
		SUM(loan_amount_eur)::numeric AS signed_value
	FROM monthly_sales_performance
	GROUP BY sales_month, customer_acquisition_channel
	ORDER BY sales_month ASC, customer_acquisition_channel ASC
	$$) AS ct (
		sales_month DATE,
		"LinkedIn" NUMERIC,
		"Facebook" NUMERIC,
		"Referral" NUMERIC,
		"Cold Call" NUMERIC,
		"Google Ads" NUMERIC,
		"Affiliate Partner" NUMERIC,
		"Trade Show" NUMERIC,
		"Webinar" NUMERIC)
ORDER BY sales_month ASC;

	-- 3.4. GET AN OVERVIEW OF THE TOP 20 CUSTOMERS AND LOANS BY SIGNED VALUE.
		-- 3.4.1.  LARGEST CUSTOMER (TOP 20).
SELECT 	
	customer_id,
	SUM(loan_amount_eur) AS signed_value
FROM sales_eur
GROUP BY customer_id
ORDER BY signed_value DESC
LIMIT 20;

		-- 3.4.2.. LARGEST LOAN (TOP 20).
SELECT 	
	loan_id,
	SUM(loan_amount_eur) AS signed_value
FROM sales_eur
GROUP BY loan_id
ORDER BY signed_value DESC
LIMIT 20;

-- 4. LOAN PORTFOLIO DEVELOPMENT

CREATE VIEW monthly_open_notional_report AS
-- CREATE CTE FOR MONTHLY BINS
WITH 
	bins AS (	
	SELECT 
		d::date AS beginning_of_month,
		(d + '1 month'::interval - '1 day'::interval )::date AS end_of_month
	FROM GENERATE_SERIES(
						'2018-07-01'::date, 
						'2022-06-30'::date, 
						'1 month'::interval) d)

-- CREATE MONTHLY OPEN NOTIONAL REPORT
SELECT 
	beginning_of_month,
	end_of_month,
	-- SUM UP PAYOUTS TO CUSTOMER, DEFINED IN COLUMN TRANSACTION-TYPE AS "PAYOUT"
	SUM(CASE WHEN transaction_type = 'Payout' THEN amount_eur ELSE 0 END) AS payouts,
	-- SUM UP REPAYMENTS FROM CUSTOMER, DEFINED IN COLUMN TRANSACTION-TYPE AS "REPAYMENTS"
	SUM(CASE WHEN transaction_type = 'Repayment' THEN amount_eur ELSE 0 END) AS repayments,
	-- SUM UP ALL HISTORIC PAYOUTS AND REPAYMENTS UNTIL MONTH END AS OPEN NOTIONAL, THAT IS MONEY OUTSTANDING OVER ALL CUSTOMERS
	SUM(SUM(CASE WHEN transaction_type = 'Payout' THEN amount_eur ELSE 0 END) + SUM(CASE WHEN transaction_type = 'Repayment' THEN amount_eur ELSE 0 END)) OVER(ORDER BY beginning_of_month)::numeric(1000,2) AS open_notional
FROM bins
	LEFT JOIN transactions_eur AS trx
		ON trx.date >= beginning_of_month
		AND trx.date <= end_of_month
GROUP BY beginning_of_month, end_of_month
ORDER BY beginning_of_month;

SELECT *
FROM monthly_open_notional_report;

-- 5. LOAN BOOK REPORT
	-- 5.1. CREATE A LOAN BOOK REPORT FOR 2021-07-31 FOLLOWING THE REPORTING OBLIGATIONS AS PER TABLE HEADERS IN THE REPORT.

/* CREATE A VIEW FOLLOWING THE NAMING CONVENTION "loan_book_YYYY_MM_DD" BASED ON THE DATE DEFINED IN FIRST CTE "reporting_date_cte".
THIS DATE DETERMINES THE REPORTING DATE FOR THE LOAN BOOK, I.E. UP TO WHICH DATE SHOULD PAYOUTS AND REPAYMENTS BE CONSIDERED? */
CREATE VIEW loan_book_2021_07_31 AS
WITH 
	-- CREATE CTE THAT REQUIRES ONLY A SINGLE DATE INPUT FOR THE LOAN BOOK REPORT. CHANGE DATE HERE.
	reporting_date_cte AS (
	SELECT '2021-07-31'),

	-- CREATE CTE WITH THE PAYOUT DATE AND MATURITY DATE FOR EACH LOAN. DOES NOT RETURN A MATURITY DATE FOR LOANS THAT HAVE NOT BEEN PAID OUT YET.
	loan_dates AS(
	SELECT
		t.loan_id,
		CASE WHEN MIN(date) > (SELECT * FROM reporting_date_cte)::date THEN NULL ELSE MIN(date) END AS payout_date,
		-- CALCULATE THE MATURITY DATE: TAKE MIN(DATE) FROM TRANSACTIONS (=PAYOUT DATE) AND ADD LOAN DURATION IN MONTHS. NO DATE FOR LOANS WITHOUT A PAYOUT DATE.
		CASE WHEN (CASE WHEN MIN(date) > (SELECT * FROM reporting_date_cte)::date THEN NULL ELSE MIN(date) END) IS NOT NULL THEN (CASE WHEN MIN(date) > (SELECT * FROM reporting_date_cte)::date THEN NULL ELSE MIN(date) END + interval '1 months' * s.loan_duration)::date ELSE NULL END AS maturity_date
	FROM transactions_eur as t
		LEFT JOIN sales AS s
			ON t.loan_id = s.loan_id
	GROUP BY t.loan_id, s.loan_duration
	),

	-- CALCULATE THE OPEN NOTIONAL PER LOAN AT THE (I) REPORTING DATE AND (II) MATURITY DATE OF EACH LOAN. (NOTE: IF MATURITY DATE AFTER REPORTING DATE, CALCULATE UNTIL REPORTING DATE)
	open_notional_cte AS(
	SELECT
		t.customer_id,
		t.loan_id,
		ld.payout_date,
		ld.maturity_date,
		-- SUM OF PAYOUTS IN EUR
		SUM(CASE WHEN transaction_type = 'Payout' AND date <= (SELECT * FROM reporting_date_cte)::date THEN amount_eur ELSE 0 END) AS payout_amount_eur,
		-- SUM OF REPAYMENTS IN EUR
		SUM(CASE WHEN transaction_type = 'Repayment' AND date <= (SELECT * FROM reporting_date_cte)::date THEN amount_eur ELSE 0 END) AS repayment_amount_eur,
		-- (PAYOUTS - REPAYMENTS) UNTIL REPORTING DATE (SPECIFIED IN CTE)
		SUM(CASE WHEN transaction_type = 'Payout' AND date <= (SELECT * FROM reporting_date_cte)::date THEN amount_eur ELSE 0 END) + SUM(CASE WHEN transaction_type = 'Repayment' AND date <= (SELECT * FROM reporting_date_cte)::date THEN amount_eur ELSE 0 END) AS open_notional_eur_reporting_date,
		-- (PAYOUTS  REPAYMENTS) UNTIL LEAST(REPORTING DATE,MATURITY DATE)
		SUM(CASE WHEN transaction_type = 'Payout' AND date <= LEAST(ld.maturity_date,(SELECT * FROM reporting_date_cte)::date) THEN amount_eur ELSE 0 END) + SUM(CASE WHEN transaction_type = 'Repayment' AND date <= LEAST(ld.maturity_date,(SELECT * FROM reporting_date_cte)::date) THEN amount_eur ELSE 0 END) AS open_notional_eur_maturity_date
	FROM transactions_eur as t
		LEFT JOIN sales AS s
			ON t.loan_id = s.loan_id
		LEFT JOIN loan_dates AS ld
			ON ld.loan_id = t.loan_id
	GROUP BY t.customer_id, t.loan_id, ld.payout_date,ld.maturity_date
)


SELECT
	s.customer_id,
	s.loan_id,
	fx.country_name,
	fx.currency,
	s.interest_rate_pm,
	s.loan_amount::numeric(1000,2),
	-- REPORT THE LOAN AMOUNT IN EUR
	ROUND(s.loan_amount * fx.fx_to_eur,2) AS loan_amount_eur,
	on_cte.payout_date AS payout_date,
	on_cte.maturity_date AS maturity_date,
	on_cte.open_notional_eur_maturity_date,
	on_cte.open_notional_eur_reporting_date,
	-- DETERMINE A LOAN STATE. SEE LOAN STATE DOCUMENTATION FOR DETAILS AND CALCULATIONS
	CASE WHEN on_cte.payout_date IS NULL THEN 'No Payout Yet'
		WHEN on_cte.maturity_date > (SELECT * FROM reporting_date_cte)::date AND on_cte.open_notional_eur_reporting_date < 0 THEN 'Current'
		WHEN (on_cte.maturity_date < (SELECT * FROM reporting_date_cte)::date AND on_cte.open_notional_eur_maturity_date = 0) OR (on_cte.maturity_date > (SELECT * FROM reporting_date_cte)::date AND on_cte.open_notional_eur_reporting_date = 0) THEN 'Repaid'
		WHEN on_cte.maturity_date < (SELECT * FROM reporting_date_cte)::date AND on_cte.open_notional_eur_reporting_date < 0 THEN 'Default'
		WHEN on_cte.maturity_date < (SELECT * FROM reporting_date_cte)::date AND on_cte.open_notional_eur_reporting_date = 0 AND open_notional_eur_maturity_date < 0 THEN 'Recovered'
		WHEN on_cte.open_notional_eur_reporting_date > 0 THEN 'Repaid (Overpaid - Rounding)'
		-- ELSE OPERATOR TO RETURN AN ERROR MESSAGE IN CASE OF ANY POTENTIAL ABNORMALITY THAT IS NOT COVERED BY THE ABOVE LOGIC.
		ELSE 'ERROR' END AS loan_status
FROM sales AS s
	LEFT JOIN customers AS c
		ON s.customer_id = c.customer_id
	LEFT JOIN currencies AS fx
		ON c.country_id = fx.country_id
	LEFT JOIN open_notional_cte AS on_cte
		ON on_cte.customer_id = s.customer_id
GROUP BY s.customer_id, s.loan_id, fx.currency, s.interest_rate_pm, fx.country_name, s.loan_amount, loan_amount_eur, payout_date, maturity_date, on_cte.open_notional_eur_maturity_date,on_cte.open_notional_eur_reporting_date,loan_status
ORDER BY s.customer_id ASC, s.loan_id ASC;

SELECT *
FROM loan_book_2021_07_31;


	-- 5.2. CREATE A LOAN STATE REPORT FOR LOAN BOOK 2021-07-31 LISTING ALL PRESENT LOAN STATES WITH NUMBER OF LOANS AND EXPOSURE PER STATE.
SELECT
	loan_status,
	COUNT(loan_id),
	SUM(loan_amount_eur) AS signed_value,
	SUM(open_notional_eur_reporting_date) AS open_notional_eur_reporting_date
FROM loan_book_2021_07_31
GROUP BY ROLLUP(loan_status)
-- CUSTOMER ORDER OF LOAN STATES ACCORDING TO BUSINESS LOGIC.
ORDER BY position(loan_status::text in '"Current", "Repaid", "Repaid (Overpaid - Rounding)", "Recovered", "Default","No Payout Yet"');


	-- 5.3. CREATE A DEFAULT REPORT FOCUSING ON THE DISTRESSED LOANS FOCUSING ON (I) RECOVERED LOANS AND (II) DEFAULTED LOANS. CREATE BINS FOR EACH STATE SORTING THESE LOANS ACCORDING TO THE DAYS FROM MATURITY DATE TO FINAL REPAYMENT DATE FOR RECOVERED LOANS AND DAYS FROM MATURITY DATE TO REPORTING DATE FOR DEFAULT LOANS.

-- CREATE CTE THAT REQUIRES ONLY A SINGLE DATE INPUT FOR THE LOAN STATE REPORT. CHANGE DATE HERE.
WITH 
	reporting_date_cte AS (
		SELECT '2021-07-31'),

-- CREATE A CTE CALCULATING THE DAYS DELAYED UNTIL LOAN REPAYMENT FOR 'RECOVERED' AND THE DAYS-OVERDUE FOR 'DEFAULT' LOANS FOR FURTHER ANALYSIS.
	overdue_report_helper AS (
			SELECT 
				loan_book_2021_07_31.*, 
				credit_score,
				-- CALCULATE THE DAYS BETWEEN MATURITY DATE AND REPORTING_DATE
				CASE WHEN loan_status = 'Default' THEN (SELECT * FROM reporting_date_cte)::date - maturity_date ELSE NULL END AS default_days_overdue,
				-- CALCULATE THE DAYS BETWEEN LOAN REPAYMENT DATE (= MAX REPAYMENT DATE FROM TRANSACTIONS TABLE) AND MATURITY DATE
				CASE WHEN loan_status = 'Recovered' THEN max_repayment_date - maturity_date ELSE NULL END AS recovered_delayed_days
			FROM loan_book_2021_07_31
				LEFT JOIN customers AS c
					ON loan_book_2021_07_31.customer_id = c.customer_id
				LEFT JOIN (SELECT loan_id, MAX(date) AS max_repayment_date FROM transactions_eur WHERE transaction_type = 'Repayment' GROUP BY loan_id) AS t
					ON loan_book_2021_07_31.loan_id = t.loan_id
			WHERE loan_status IN('Default','Recovered')),
	
-- ADD BINS FOR RECOVERED AND DEFAULT LOANS FPR FURTHER REPORTING
	overdue_report AS (	
		SELECT 
			overdue_report_helper.*,
			CASE WHEN default_days_overdue IS NULL THEN NULL
				WHEN default_days_overdue >= 1 AND  default_days_overdue <= 90 THEN '1 - 90'
				WHEN default_days_overdue > 90 AND  default_days_overdue <= 180 THEN '91 - 180'
				WHEN default_days_overdue > 180 AND  default_days_overdue <= 360 THEN '181 - 360'
				WHEN default_days_overdue > 360 THEN '360+' ELSE NULL END AS default_bin,
			CASE WHEN recovered_delayed_days IS NULL THEN NULL
				WHEN recovered_delayed_days >= 1 AND  recovered_delayed_days <= 30 THEN '1 - 30'
				WHEN recovered_delayed_days > 30 AND  recovered_delayed_days <= 60 THEN '31 - 60'
				WHEN recovered_delayed_days > 60 AND  recovered_delayed_days <= 90 THEN '61 - 90'
				WHEN recovered_delayed_days > 90 THEN '90+' ELSE NULL END AS recovered_bin
		FROM overdue_report_helper)
	
	
-- CREATE AN OVERVIEW OF DEFAULT LOANS CLUSTERING IN DAYS SINCE MATURITY DATE BINS (1-90, 91-180, 181-360, 361+)
SELECT 
	default_bin,
	COUNT(loan_id) AS num_loans,
	SUM(open_notional_eur_reporting_date) AS open_notional_eur_reporting_date,
	-- CALCULATE SHARE OF OPEN NOTIONAL AT REPORTING DATE ACROSS THE BINS
	ROUND(SUM(open_notional_eur_reporting_date) / (SELECT SUM(open_notional_eur_reporting_date) FROM overdue_report WHERE loan_status = 'Default'),2) AS open_notional_share
FROM overdue_report
WHERE loan_status = 'Default'
GROUP BY default_bin
ORDER BY position(default_bin::text in '"1 - 90", "91 - 180", "181 - 360", "360+"');

-- CREATE AN OVERVIEW OF RECOVERED LOANS CLUSTERING IN DAYS NEEDED FOR RECOVER BINS (1-90, 91-180, 181-360, 361+)
SELECT 
	recovered_bin,
	COUNT(loan_id) AS num_loans,
	SUM(open_notional_eur_maturity_date) AS open_notional_eur_maturity_date,
	-- CALCULATE SHARE OF OPEN NOTIONAL AT MATURITY DATE ACROSS THE BINS
	ROUND(SUM(open_notional_eur_maturity_date) / (SELECT SUM(open_notional_eur_maturity_date) FROM overdue_report WHERE loan_status = 'Recovered'),2) AS open_notional_share
FROM overdue_report
WHERE loan_status = 'Recovered'
GROUP BY recovered_bin
ORDER BY position(recovered_bin::text in '"1 - 30", "31 - 60", "61 - 90", "90+"'); 