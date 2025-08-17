# 📊 Credit Risk Analysis Project

## 🔍 Project Overview

This project analyzes credit risk data to uncover insights into loan
performance, borrower characteristics, and potential risk factors.\
The analysis pipeline consists of **SQL (for data cleaning and
exploration)** and **Power BI (for visualization and dashboarding)**.

------------------------------------------------------------------------

## 🛠️ Tools & Technologies

-   **SQL Server Management Studio (SSMS):** Data cleaning,
    transformation, and feature engineering.\
-   **Power BI:** Interactive dashboards for visualization and
    storytelling.\
-   **GitHub:** Project documentation and portfolio presentation.

------------------------------------------------------------------------

## 📂 Dataset Description

The dataset contains loan applications with information about: -
Borrower demographics (age, employment length, income bracket, etc.) -
Loan details (amount, grade, status, intent, interest rate, etc.) -
Credit performance (default vs. non-default).

------------------------------------------------------------------------

## ⚙️ Data Cleaning Process (SQL)

The SQL script ([Credit Risk
Analysis.sql](./Credit%20Risk%20Analysis.sql.sql)) includes: 1. Handling
missing values (`person_emp_length`, `loan_int_rate`). 2. Creating
cleaned versions of the **Person** and **Loan** tables. 3. Joining
datasets into a unified `CleanedCreditData` table/view. 4. Adding
missingness flags for later analysis in Power BI. 5. Exploratory queries
to calculate default rates, distributions, and correlations.

------------------------------------------------------------------------

## ❓ Key Exploration Questions

-   What is the overall **default rate** in the dataset?
-   How does default rate vary by **loan grade**?
-   How does default rate vary by **income bracket**?
-   What is the impact of **employment length** on credit risk?
-   How do **age groups** influence loan defaults?
-   What proportion of records have missing **employment length** and
    **interest rate** values?

------------------------------------------------------------------------

## 📊 Dashboard

Below is the Power BI dashboard designed for this project:

![Credit Risk Dashboard](0FA5046F-A84F-4F28-B047-9682B0536691.jpeg)

**Dashboard Features:** - KPI cards: Total Loans, Total Defaults,
Default Rate (%), Avg Loan Amount.\
- Bar charts: Default rate by Loan Grade & Income Bracket.\
- Donut chart: Loan Intent distribution.\
- Missing Values analysis by Loan Grade.\
- Filters for Loan Grade, Loan Status, and Home Ownership.

------------------------------------------------------------------------

## 🚀 Insights

-   Overall default rate is around **21.9%**.\
-   Higher default rates are concentrated in **lower loan grades (E, F,
    G)**.\
-   Borrowers with **income \< \$25K** have the highest default risk.\
-   Loan intent categories such as **debt consolidation** dominate
    applications.\
-   Missing values exist primarily in **employment length** and
    **interest rate**, which could bias modeling.

------------------------------------------------------------------------

## 📌 Next Steps

-   Build predictive models (Logistic Regression, Decision Trees) using
    Python/SQL.\
-   Enhance dashboard with time-trend analysis.\
-   Deploy reports for stakeholders.

------------------------------------------------------------------------

## 🧑‍💻 Author

**Alexander Otto Bende**\
📍 Finance Professional turned Data Analyst\
🔗 [LinkedIn](https://www.linkedin.com/in/alexander-otto-bende/) • 💻
[GitHub](https://github.com/Ottobende)

------------------------------------------------------------------------
