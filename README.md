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

**Appendix:**

**Table: Loan States** ("Loan State":"Defintion")

No Payout Yet: Payout date in the future
Current: Payout date before reporting date. Open notional and maturity date after reporting date.
Repaid: Payout date before reporting date, and (a) maturity date before reporting date and 0 open notional at maturity date, or (b) maturity date after reporting date and 0 open notional.
Repaid (Overpaid - Rounding): Payout date before reporting date, and (a) maturity date before reporting date and >0 open notional at maturity date, or (b) maturity date after reporting date and >0 open notional.
Recovered: Payout date and maturity date before reporting date, open notional at maturity date but repaid before reporting date.
Default: Payout date and maturity date before reporting date, open notional at maturity date and still open at reporting date


**ERD:**

Please refer to the entity-relationship diagram for an overview of tables, realtions and data types.
![FinTech_ERD pgerd](https://github.com/Dominik-Schwoerer/FinTech/assets/156693461/d2b70816-8af1-479e-ad11-0f1d99714950)

