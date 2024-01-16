# FinTech Project: Hypothetical Case Study (PostgreSQL)
This FinTech project models the reporting structure for a hypothetical lending company granting 12-months loans with flexible repayment terms. Inspired by real-life job experience and reporting obligations to outside stakeholders, the project covers th following reports:
1. Monthly Sales Performance: How many loans were signed and in which market?
2. Customer Acquisition Metrics: How many loans were signed over which channel?
3. Portolio Performance: How did the portfolio develop month over month? (Measured by portfolio size: loan payouts - loan repayments = outstanding notional)
4. Debt Funding Reporting: Prepare a recurring reporting template based on funding agreement that (i) outlines the portfolio status as per reporting data as well as (ii) details on problematic loans.

**Data Set**

Since no comparable dataset was available online, the project is based on ramdomized data. The data sets are available as .csv.
During the creation of the database, the following characteristics were considered:
1. For the sake of simplicity in modeling, there are a total of 1.000 unique customers with one loan each.
2. Customers are based in EUR and GBP countries in order to add a exchange rate layer to the report. (Typical market expansions for German fintechs is England [and the United States].)
3. Customers are acquired over a range of different channels, ranging from Cold Call to LinkedIn.
4. All loans have maturity of 12 months.
5. The data is set up, so that a certain percentage of customers repays the loan within the contractual loan duration. Some customers repay the loan after the maturity date while others do not repay the loan at all. Depending on the reporting date/ observation date of the portfolio, customers have an open loan within maturity. The table "Loan States" in the appendix outlines the different loan states and definitions.

**Project Steps**
1. Overview Report
- Goal: Understand data set and number of customers, number of loans and geographic characteristics. How many loans with hat value were signed in the respective currency zones?
- Result: There are a total of 1.000 customers with one loan signed each. Loans are signed in two currency zones: EUR and GBP and the loan amount is shown in the local currency.
The German market is the strongest, making up 48% of total signed value
- Next steps: Standardize the data sets to adjust for currency zones -> show all values in EUR.

3. Data Preparation
- Goal: Standardize tables (i) Sales and (ii) Transactions into EUR.
- Result: Views "sales_eur" and "transactions_eur" ready for further analysis.

4. Data Analysis
- Goal 1: Understand the sales performance by looking at the signed value (EUR) per month.
- Goal 2: Understand the best performing customer acquisition channel.
- Goal 3: Add the customer acquisition channel to understand the sales per month per channel.
- Goal 4: Get an overview of the top 20 customers and loans by signed value.
- Results:
- for Goal 1: See table for results.
- for Goal 2: "Cold Call" is the best performing channel generating 46% of total sales, followed by LinkedIn generating 16% of total sales.
- for Goal 3: See table for results.
- for Goal 3: See table for results.

5. Loan Portfolio Development
- Goal: Get an overview of the loan portfolio month-over-month considering new loan payouts and loan repayments until end of month.
- Results: Monthly overview with open notional and month-over-month (mom) and year-over-year (yoy) growth.

6. Loan Book Report
- Goal 1: Create a template used to report the loan book to external stakeholders. The report can be created for a specific reporting date using a date input in the reporting mask. The report gives a loan-level overview with the key loan characteristics, exposure at the reporting date and a loan state. See the table of loan states in the appendix (Table: Loan States).
- Goal 2: Create a default report focusing on the distressed loans focusing on (i) recovered loans and (ii) defaulted loans.
- Results:
- Goal 1. and 2.: See table for results.

Overall Results Summary:
The overall goal of the FinTech project is to combine the technical PostgreSQL skills with the business need for risk management and reporting obligations in a lending company.
Despite the uniqueness of the data set for a specific loan model, the approach and reports can be adjusted for other loan models. Hence, the skills showcased during the project are transferable not only for other lending models, but any business model with reports on customer acquisition and/ or sales performance.

Futher Analysis:
1. Adjust reporting periodes for sales and portfolio reports: weekly, bi-weekly quaterly, annual
2. Add further loan data for existing customers (returning customers):
3.   Add cohort-analysis for different monthly cohorts and/ or channel
4.   Add sales reports for time between loan maturity and second loan payout
5.   Understand repayment behavior of customers (potentilly add cohorts)


**Appendix:**

**Table: Loan States** ("Loan State":"Defintion")

- No Payout Yet: Payout date in the future
- Current: Payout date before reporting date. Open notional and maturity date after reporting date.
- Repaid: Payout date before reporting date, and (a) maturity date before reporting date and 0 open notional at maturity date, or (b) maturity date after reporting date and 0 open notional.
- Repaid (Overpaid - Rounding): Payout date before reporting date, and (a) maturity date before reporting date and >0 open notional at maturity date, or (b) maturity date after reporting date and >0 open notional.
- Recovered: Payout date and maturity date before reporting date, open notional at maturity date but repaid before reporting date.
- Default: Payout date and maturity date before reporting date, open notional at maturity date and still open at reporting date


**ERD:**

Please refer to the entity-relationship diagram for an overview of tables, relations and data types.
![FinTech_ERD pgerd](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/1967a3dd-727d-45c9-a185-b79c2043c247)

