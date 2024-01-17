# FinTech Project: Hypothetical Case Study (PostgreSQL)
This FinTech project models the reporting structure for a hypothetical lending company that provides 12-month loans with flexible repayment terms. Inspired by real-life work experiences and reporting obligations to external stakeholders, the project includes the following reports:
1. Monthly Sales Performance: How many loans have been signed and in which market?
2. Customer Acquisition Metrics: How many loans have been signed and through which channel?
3. Portfolio Performance: How has the portfolio performed month on month (measured by portfolio size: loan disbursements - loan repayments = notional outstanding)?
4. **Loan Book Report (Main Objective)**: Prepare a recurring reporting template based on the funding agreements that (i) outlines the portfolio status as per reporting data and (ii) details on non-performing loans.

The SQL code is available in the file FinTech_Master.


# **Data Set**

As no comparable dataset was available online, the project is based on randomised data. The datasets are available as .csv files.
The following characteristics were taken into account when creating the database
1. To simplify the modelling, there are a total of 1,000 unique customers with one loan each.
2. Customers are located in EUR and GBP countries to add an exchange rate layer to the report. (Typical market expansions for German fintechs is England [and the United States]).
3. Customers are acquired through a number of different channels, ranging from inbound to outbound.
4. All loans have a maturity of 12 months.
5. The data is set so that a certain percentage of customers repay the loan within the contractual loan period. Some customers repay the loan after the maturity date, while others do not repay the loan at all. Depending on the reporting date/observation date of the portfolio, customers have an open loan within maturity. The table _"Loan States"_ in the appendix shows the different loan states and definitions.

# **Overall Project Steps:**
# 1. Overview Report
- **Objective:** Understand the data set and the number of customers, number of loans and geographical characteristics. How many loans of what value have been signed in each currency zone?
- Q1: How many customers are in the table "customers"? Are they all unique customers?
- Q2: How many loans have been signed per customer?
- Q3: Which countries are the customers from and which is the most important market?
- Q4: What are the different currencies in the customer data?
- **Results:**
- for Q1: There are a total of 1.000 unique customers in the dataset. See results in _Table 1: Customer Results_
- for Q2: Each customer signed a single loan. See results in _Table 2: Customer Rebookings_
- for Q3: Customers come from a total of 8 countries. Most customers are from  Germany (494) with a total signed value share of 48%. See results in _Table 3: Geographic Results_
- for Q4: There are a total of two currencies: EUR (85% of loan value) and GBP (15% of loan value) present in the data set. See results in _Table 4: Currency Results_
- **Next steps:** Standardize the datasets to adjust for currency zones to show all values in EUR for all further analysis.

Table 1: Customer Results

![Customer_stats](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/ea0311ec-8756-4fd4-a196-9a106d5db5d3)

Table 2: Customer Rebookings

![Customer_rebookings](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/0e34867a-25c4-45aa-8b13-fcda48f6a43a)

Table 3: Geographic Results

![Geographic_stats](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/04b6a2d3-e2af-429c-a463-a9d468fcb00a)


Table 4: Currency Results

![Currency_stats](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/39397af4-196b-43eb-b27b-c46c567fd1af)

# 2. Data Preparation
- **Objective:** Standardize tables (i) Sales and (ii) Transactions into EUR.
- **Results:** Views "sales_eur" and "transactions_eur" are ready for further analysis. These views are not shown here, please refer to the SQL code.


# 3. Data Analysis
- **Objective:** Perform further analysis for sales and marketing performance.
- Q1: Understand the sales performance by looking at the number of signed loans, signed value (EUR) per month. Also analyse the month-over-month (mom) and year-over-year (yoy) growth.
- Q2: Understand the best performing customer acquisition channel.
- Q3: Understand the best performing customer acquisition channel per month. See results in 
- Q4: Get an overview of the top 20 customers and loans by signed value.
- **Results:**
- for Q1: See an extract of the results in _Table 5: Sales Performance by Month (Extract)_
- for Q2: "Cold Call" is the top performing channel generating 46% of total sales, followed by LinkedIn generating 16% of total sales. See results in _Table 6: Customer Acquisition Channel Ranked_
- for Q3: See an extract of the results in Table _7: Customer Acquisition Channel Pivot_
- for Q4: See results in _Table 8: Top 20 Customers_ and _Table 9: Top 20 Loans_

Table 5: Sales Performance by Month (Extract)

![Sales Performance by Month (Extract)](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/f1fecbd8-4a7d-4559-9201-ed20482cb6fe)

Table 6: Customer Acquisition Channel Ranked

![Customer_acquisition_channel_ranked](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/1d725b31-126c-4df4-8b9e-ec78730aedb2)

Table 7: Customer Acquisition Channel Pivot

![Acquisition_pivot](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/30fb1976-7a0f-4262-9a96-4efce4cd7317)

Table 8: Top 20 Customers

![Top_20_customers](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/546c0f49-617a-45e6-b250-62db8728294d)

Table 9: Top 20 Loans

![Top_20_loans](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/8fbf5e9c-9e73-4257-a6c1-841b473fd1f7)


# 4. Loan Portfolio Development
- **Objective:** Get an overview of the loan portfolio month-over-month considering new loan payouts and loan repayments until end of month.
- **Results:** Monthly overview with open notional and month-over-month (mom) and year-over-year (yoy) growth. See an extract of the results in _Table 10: Open Notional Reporting (Extract)_

Table 10: Open Notional Reporting (Extract)

![Open_notional_report](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/23ddbf70-2a4c-4c63-9c9d-f3dfce0ce555)


# 5. Loan Book Report (Main Objective)
- **Objective:** Create a template used to report the loan book to external stakeholders. The report can be generated for a specific reporting date using a date input in the reporting mask. The report provides a loan level overview with the key loan characteristics, exposure at the reporting date and a loan state.
- Q1: Generate a loan book report for 2021-07-31 according to the contractual reporting requirements (table structure [headers] of the report was provided).
- Q2: Generate a loan state report for loan book 2021-07-31 listing all live loan states with number of loans and exposure per status.
- Q3: Generate a default report with a focus on (i) recovered loans and (ii) defaulted loans. Create bins for each state sorting loans according to the (i) days from maturity date to reporting date for default loans and (ii) days from maturity date to final repayment date for recovered loans.
- **Results:**
- for Q1.: See an extract of the results in _Table 11: Loan Book as per 2021-07-31 (Extract)_. Since this is the main goal of the project, the report is attached as file in this project (see **20210731_loan_book**).
- for Q2: See results in _Table 12: Loan State Report as of 2021-07-31_
- for Q3: See results for default loans in _Table 13: Distressed Loan Overview as of 2021-07-31: Default_ and results for recovered loans in _Table 14: Distressed Loan Overview as of 2021-07-31: Recovered_

Table 11: Loan Book as of 2021-07-31 (Extract)

![Loan_book_2021ß731](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/91ad1489-ffbf-40c1-94af-c87336358e67)

Table 12: Loan State Report as of 2021-07-31

![20210731_loan_state_report](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/307b3ea6-fa6e-46ed-ab43-a81bc8984c93)

Table 13: Distressed Loan Overview as of 2021-07-31: Default

![Default_bins](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/c7791656-4c3d-4f8b-9fef-650898e2eda7)

Table 14: Distressed Loan Overview as of 2021-07-31: Recovered

![Recovered_bins](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/23c14a45-dead-439f-bcb9-223a00398f3c)


# **Overall Results Summary:**

The overall goal of the FinTech project is to combine the technical PostgreSQL skills with the business needs for risk management and reporting obligations in a hypothetical lending company.
Despite the uniqueness of the dataset for a specific lending model, the approach and reports can be adapted for other loan models. Therefore, the skills demonstrated during the project are transferable not only for other lending models, but to any business model that reports on customer acquisition and/ or sales performance.

# **Futher Analysis:**

1. Adjust reporting periodes for sales and portfolio reports: weekly, bi-weekly quaterly, annual
2. Add historic exchange rates.
3. Add further loan data for existing customers (returning customers):
4. (3.1.) Add cohort-analysis for different monthly cohorts and/ or channel
5. (3.2.) Add sales reports for time between loan maturity and second loan payout
6. (3.3.) Understand repayment behavior of customers (potentilly add cohorts)
7. Add interest payments to the transactions table. (Not added due to increased complexity in creating the dataset.)


# **Appendix:**

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

