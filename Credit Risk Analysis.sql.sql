--- Credist Risk Analysis Project
--- Checking if our data was correctly uploaded
SELECT*
FROM Person_Table_Credit_Risk;

SELECT*
FROM Loan_Table_Credit_Risk;

ALTER TABLE Loan_Table_Credit_Risk
ALTER COLUMN loan_status INT;

--- Count total rows in each table

SELECT COUNT(*) AS person_rows
FROM Person_Table_Credit_Risk;

SELECT COUNT(*) AS loan_rows
FROM Loan_Table_Credit_Risk;

--- Checking duplicates in Person Table

WITH duplicate_person AS
(
	SELECT*,
	ROW_NUMBER() 
	OVER(PARTITION BY person_id,person_age, person_income, person_home_ownership, person_emp_length, cb_person_default_on_file, cb_person_cred_hist_length ORDER BY person_id) AS row_num
	FROM Person_Table_Credit_Risk
)
SELECT*
FROM duplicate_person
WHERE row_num >1;

--- Checking duplicates in Loan Table

WITH duplicate_loan AS
(
SELECT*,
ROW_NUMBER() OVER(PARTITION BY person_id, loan_intent, loan_grade, loan_amnt, loan_int_rate, loan_status, loan_percent_income ORDER BY person_id) AS row_num
FROM Loan_Table_Credit_Risk
)
SELECT*
FROM duplicate_loan
WHERE row_num >1;

--- Handling missing values
--- Checking NULL/Blank values in Person Table

SELECT*
FROM Person_Table_Credit_Risk
	WHERE person_age IS NULL OR person_age ='' 
	OR person_income IS NULL OR person_income ='' 
	OR person_home_ownership IS NULL OR person_home_ownership ='' 
	OR person_emp_length IS NULL OR person_emp_length ='' 
	OR cb_person_default_on_file IS NULL OR cb_person_default_on_file =''
	OR cb_person_cred_hist_length IS NULL OR cb_person_cred_hist_length ='';

--- We have a total of 887 blank rows all coming from the person_emp_length column. We'll keep the rows and replace the blank rows with "Unkown" and flag

SELECT
	person_id,
	person_age,
	person_income,
	person_home_ownership,
	CASE
		WHEN person_emp_length IS NULL OR LTRIM(RTRIM(person_emp_length)) ='' THEN 'Unkown'
		ELSE person_emp_length
	END AS person_emp_length_clean,
	cb_person_default_on_file,
	cb_person_cred_hist_length,
	CASE
		WHEN person_emp_length IS NULL OR LTRIM(RTRIM(person_emp_length)) ='' THEN 1
		ELSE 0
	END AS is_emp_length_missing
INTO Person_Cleaned
FROM Person_Table_Credit_Risk;

--- Checking NULL/Blank values in Loan Table

SELECT*
FROM Loan_Table_Credit_Risk
	WHERE loan_intent IS NULL OR loan_intent ='' 
	OR loan_grade IS NULL OR loan_grade ='' 
	OR loan_int_rate IS NULL OR loan_int_rate ='' 
	OR loan_status IS NULL OR loan_status ='' 
	OR loan_percent_income IS NULL OR loan_percent_income ='';

--- We have 3,095 blank rows all from the loan_int_rate column. Since the cuase of the blanks are unkown, we'll keep these rows for other analysis and use median imputation by loan grade or loan intent and remove the rows for interest_rate based analysis
--- We'll use a CTE to create a 

--- Converting data types

ALTER TABLE Loan_Table_Credit_Risk
ALTER COLUMN person_id INT;

ALTER TABLE Loan_Table_Credit_Risk
ALTER COLUMN loan_amnt INT;

ALTER TABLE Loan_Table_Credit_Risk
ALTER COLUMN loan_int_rate FLOAT;

ALTER TABLE Loan_Table_Credit_Risk
ALTER COLUMN loan_status INT;

ALTER TABLE Loan_Table_Credit_Risk
ALTER COLUMN loan_grade VARCHAR(2);

ALTER TABLE Loan_Table_Credit_Risk
ALTER COLUMN loan_percent_income FLOAT;

WITH LoanGradeMedian AS 
(
	SELECT
		l.loan_grade,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY l.loan_int_rate)
		OVER (PARTITION BY l.loan_grade) AS median_loan_int_rate 
	FROM Loan_Table_Credit_Risk AS l
	WHERE L.loan_int_rate IS NOT NULL
),
MedianPerGrade AS (
	SELECT DISTINCT lgm.loan_grade, lgm.median_loan_int_rate
	FROM LoanGradeMedian AS lgm
)
	SELECT
		l.person_id,
		l.loan_intent,
		l.loan_grade,
		l.loan_amnt,
		 CASE
			WHEN  l.loan_int_rate IS NULL THEN  mpg.median_loan_int_rate
			ELSE l.loan_int_rate
		 END AS loan_int_rate_clean,
		 l.loan_status,
		 l.loan_percent_income,
		 CASE WHEN l.loan_int_rate IS NULL THEN 1 ELSE 0 END AS is_loan_int_rate_missing
INTO dbo.loan_cleaned
FROM Loan_Table_Credit_Risk AS l
LEFT JOIN MedianPerGrade AS mpg
	ON l.loan_grade = mpg.loan_grade;

--- Join Personal Table  and Loan Table into a new table for our analysis

SELECT 
	p.person_id,
	p.person_age,
	p.person_income,
	p.person_home_ownership,
	p.person_emp_length_clean,
	p.is_emp_length_missing,
	p.cb_person_default_on_file,
	p.cb_person_cred_hist_length,

	l.loan_intent,
	l.loan_grade,
	l.loan_amnt,
	l.loan_int_rate_clean,
	l.is_loan_int_rate_missing,
	l.loan_status,
	l.loan_percent_income
INTO Credit_Risk_Joined
FROM Person_Cleaned AS p
FULL OUTER JOIN dbo.loan_cleaned AS l
	ON p.person_id = l.person_id;


SELECT*
FROM Credit_Risk_Joined;

--- Data Exploration
--- Questions
--- Q1. What is the overall default rate?

SELECT
	COUNT(*) AS total_loans,
	SUM(CASE WHEN loan_status = 1 THEN 1  ELSE 0 END) AS total_defaults,
	CAST(SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS default_rate
FROM Credit_Risk_Joined;

--- We had an overall default rate of 0.21% and a total of 7089 total defaults

---Q2. How does default rate vary across different age groups

WITH AgeBuckets AS (
	SELECT 
		person_id,
		CASE	
			WHEN person_age <29 THEN 'Young'
			WHEN person_age BETWEEN 30 AND 59 THEN 'Adult'
			ELSE 'Senior'
		END AS age_group,
		loan_status
	FROM Credit_Risk_Joined
)
SELECT
	age_group,
	COUNT(*) AS total_loans,
	SUM(CASE WHEN loan_status = 1 THEN 1  ELSE 0 END) AS total_defaults,
	CAST(SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS default_rate
FROM AgeBuckets
GROUP BY age_group
ORDER BY age_group DESC;

--- From our analysis, the Young and Senior have a higher default rate compared to the Adults

--- Q3. How does fedault rate vary by loan grade?

SELECT
	loan_grade,
	COUNT(*) AS total_loans,
	SUM(CASE WHEN loan_status = 1 THEN 1  ELSE 0 END) AS total_defaults,
	CAST(SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS default_rate
FROM Credit_Risk_Joined
GROUP BY loan_grade
ORDER BY default_rate DESC ;

---From our results, loan grade "G","F" and "E" have higher default rate compared to "A" AND "B"

---Q4. Which loan intents are associated with the highest default rates?

SELECT
	loan_intent,
	COUNT(*) AS total_loans,
	SUM(CASE WHEN loan_status = 1 THEN 1  ELSE 0 END) AS total_defaults,
	CAST(SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS default_rate
FROM Credit_Risk_Joined
GROUP BY loan_intent
ORDER BY default_rate DESC ;

--- Debt Consolidation, Medical and Home Improvement have a higher defualt rate compared to Venture and Education

---Q5.Does the borrower's income bracket affect the likelihood of defaults?
--- We'll create income bracket for easier segmentation 
ALTER TABLE Credit_Risk_Joined ADD income_bracket VARCHAR(20);

UPDATE Credit_Risk_Joined
SET income_bracket = CASE
	WHEN person_income < 25000 THEN '<25K'
	WHEN person_income BETWEEN 25000 AND 49999 THEN '25K-50K'
	WHEN person_income BETWEEN 50000 AND 74999 THEN '50K-75K'
	WHEN person_income BETWEEN 75000 AND 99999 THEN '75K-100K'
	WHEN person_income >= 100000 THEN '100+'
	ELSE 'Unkown'
END;
--- now we can answer our question
SELECT
	income_bracket,
	COUNT(*) AS total_loans,
	SUM(CASE WHEN loan_status = 1 THEN 1  ELSE 0 END) AS total_defaults,
	CAST(SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS default_rate
FROM Credit_Risk_Joined
GROUP BY income_bracket
ORDER BY default_rate DESC;

---From our result,the lesser the income the higher the default rate as those with income <25k have a higher default rate compared to thos with 100k+

---Q6. What is the average loan amount and interest rate for Defaulted vs Non-Defaulted loans?

SELECT
	loan_status,
	AVG(loan_amnt) AS Avg_loan_amount,
	AVG(loan_int_rate_clean) AS Avg_loan_int_rate
FROM Credit_Risk_Joined
GROUP BY loan_status;

--- The average loan amount and average loan interest rate for non-default loans is lesser than that of default loans.

--- Q7. How does loan percent of income relate to default?

SELECT 
	CASE	
		WHEN loan_percent_income  < 0.1 THEN '<10%'
		WHEN loan_percent_income  BETWEEN 0.1 AND 0.2 THEN '10%-20%'
		WHEN loan_percent_income  BETWEEN 0.2 AND 0.3 THEN '20%-30%'
		ELSE '>30%'
	END AS loan_percent_income_bracket,
	COUNT(*) AS total_loans,
	SUM(CASE WHEN loan_status = 1 THEN 1  ELSE 0 END) AS total_defaults,
	CAST(SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) AS default_rate
FROM Credit_Risk_Joined
GROUP BY 
	CASE	
		WHEN loan_percent_income  < 0.1 THEN '<10%'
		WHEN loan_percent_income  BETWEEN 0.1 AND 0.2 THEN '10%-20%'
		WHEN loan_percent_income  BETWEEN 0.2 AND 0.3 THEN '20%-30%'
		ELSE '>30%'
	END
ORDER BY default_rate DESC;

---From our analysis, the higher the loan percent income bracket, the higher bthe default rate and vice versa.

--- END OF QUERY

