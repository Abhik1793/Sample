-- 1. Identify customers with low credit scores and high-risk loans
SELECT c.customer_id, c.name, c.credit_score, l.loan_id, l.default_risk
FROM customer_table c
JOIN loan_table l ON c.customer_id = l.customer_id
WHERE c.credit_score < 600 AND l.default_risk = 'High';

-- 2.Find the most popular loan purposes and their total loan amounts.
SELECT loan_purpose, COUNT(*) AS loan_count, SUM(loan_amount) AS total_amount
FROM loan_table
GROUP BY loan_purpose
ORDER BY loan_count DESC;

-- 3.Detect transactions that exceed 30% of the respective loan amounts.
SELECT t.transaction_id, t.loan_id, t.transaction_amount, l.loan_amount
FROM transaction_table t
JOIN loan_table l ON t.loan_id = l.loan_id
WHERE t.transaction_amount > (l.loan_amount * 0.3);

-- 4.Count the number of missed EMI transactions per loan.
SELECT loan_id, COUNT(*) AS missed_emi_count
FROM transaction_table
WHERE transaction_type = 'Missed EMI'
GROUP BY loan_id
ORDER BY missed_emi_count DESC;

-- 6.Analyze loan disbursement trends by customer location.
SELECT c.address, COUNT(l.loan_id) AS loan_count, SUM(l.loan_amount) AS total_loan
FROM customer_table c
JOIN loan_table l ON c.customer_id = l.customer_id
GROUP BY c.address
ORDER BY total_loan DESC;

-- 7.List customers who have been associated for over five years.
SELECT customer_id, name, customer_since
FROM customer_table
where (curdate() - customer_since) > 1825;
-- NOTE: using above code because Year(Curdate())-Year(customer_since) > 5; is resulting in blank table. Checked all the issues. Nothing found

-- 7.Find loans with excellent repayment history (no missed payments).
SELECT l.loan_id, 
       l.customer_id
FROM loan_table l
LEFT JOIN transaction_table t ON l.loan_id = t.loan_id
GROUP BY l.loan_id, l.customer_id
HAVING SUM(CASE WHEN t.transaction_type = 'Missed EMI' THEN 1 ELSE 0 END) = 0;

-- 8.Identify potential fraud based on mismatches between customer addresses and transaction locations.
SELECT c.customer_id, c.address, b.ip_address
FROM behavior_logs b
JOIN customer_table c ON c.customer_id = b.customer_id
WHERE c.address NOT LIKE CONCAT('%', b.ip_address, '%');
