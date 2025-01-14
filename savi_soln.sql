--Library Management System
CREATE TABLE branch
(
	branch_id VARCHAR(10) PRIMARY KEY,
	manager_id VARCHAR(10),
	branch_address VARCHAR(20),
	contact_no VARCHAR(20)
);
SELECT * FROM branch

DROP TABLE employees
CREATE TABLE employees
(
	emp_id VARCHAR(10) PRIMARY KEY,
	emp_name VARCHAR(25),
	position VARCHAR(25),
	salary INT,
	branch_id VARCHAR(25) --FK
);
SELECT * FROM employees

DROP TABLE books
CREATE TABLE books
(
	isbn VARCHAR(30) PRIMARY KEY,
	book_title VARCHAR(75),
	category VARCHAR(20),
	rental_price FLOAT,
	status VARCHAR(20),
	author VARCHAR(35),
	publisher VARCHAR(55)
);
SELECT * FROM books

DROP TABLE members
CREATE TABLE members 
(
	member_id VARCHAR(35) PRIMARY KEY,
	member_name VARCHAR(35),
	member_address VARCHAR(75),
	reg_date DATE 
);
SELECT * FROM members

DROP TABLE issued_status
CREATE TABLE issued_status
(
	issued_id VARCHAR(30) PRIMARY KEY,
	issued_member_id VARCHAR(20), --FK
	issued_book_name VARCHAR(75),
	issued_date DATE,
	issued_book_isbn VARCHAR(25), --FK
	issued_emp_id VARCHAR(20) --FK
);
SELECT * FROM issued_status

DROP TABLE return_status
CREATE TABLE return_status
(
	return_id VARCHAR(20) PRIMARY KEY,
	issued_id VARCHAR(30),
	return_book_name VARCHAR(75),
	return_date DATE,
	return_book_isbn VARCHAR(20)

);
SELECT * FROM return_status

--FOREIGN KEY
ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employees
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);

--Project Task

--1. Create a New Book Record  "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes',
--'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books (isbn,book_title,category,rental_price,status,author,publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes','Harper Lee', 'J.B. Lippincott & Co.')
SELECT * FROM books

--2: Update an Existing Member's Address

UPDATE members
SET member_address='128 Elm St'
WHERE member_id='C102'
SELECT * FROM members

--3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS117' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id='IS121'
SELECT * FROM issued_status

--4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id= 'E101';

--5: List Members Who Have Issued More Than One Book 

SELECT issued_emp_id, 
COUNT(issued_id)
FROM issued_status
GROUP BY issued_EMP_id
HAVING COUNT(issued_id)>1;

--CTAS
--6: Create Summary Tables: 
--   Used CTAS to generate new tables based on query results - each book and total book_issued_cnt.

CREATE TABLE book_counts
AS
SELECT 
	b.isbn,
	b.book_title,
	COUNT(ist.issued_book_isbn)
FROM books as b
JOIN issued_status as ist
ON ist.issued_book_isbn=b.isbn
GROUP BY isbn

SELECT * FROM book_counts

--7. Retrieve All Books in a Specific Category.

SELECT * FROM books
WHERE category='Mystery';

--8: Find Total Rental Income by Category.

SELECT 
	b.category,
	SUM(b.rental_price)
FROM books as b
JOIN issued_status as ist
ON ist.issued_book_isbn=b.isbn 
GROUP BY category;

--9: List Members Who Registered in the Last 180 Days.

SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

INSERT INTO members(member_id,member_name,member_address,reg_date)
VALUES('C136','Savi','145 St','2024-11-01')

--10: List Employees with Their Branch Manager's Name and their branch details.
SELECT
	e.emp_id,
	e.emp_name,
	e1.emp_name AS manager,
	b.*
FROM employees AS e
JOIN branch as b
ON e.branch_id=b.branch_id
JOIN employees AS e1
ON e1.emp_id=b.manager_id;

--11: Create a Table of Books with Rental Price Above a Certain Threshold (7)

CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;
SELECT * FROM expensive_books

--12: Retrieve the List of Books Not Yet Returned

SELECT 
	i.* 
FROM issued_status AS i
LEFT JOIN return_status AS r
ON i.issued_id=r.issued_id
WHERE r.return_id IS NULL;

--13: Identify Members with Overdue Books
--Write a query to identify members who have overdue books (assume a 30-day return period).
--Display the member's_id, member's name, book title, issue date, and days overdue. 

SELECT 
	i.issued_member_id,
	m.member_name,
	b.book_title,
	i.issued_date,
	CURRENT_DATE - i.issued_date AS overdue_days
FROM issued_status AS i
JOIN members AS m
ON i.issued_member_id=m.member_id
JOIN books AS b
ON b.isbn=i.issued_book_isbn
LEFT JOIN return_status AS r
ON i.issued_id=r.issued_id
	WHERE r.return_id IS NULL
	AND CURRENT_DATE - i.issued_date > 30;

--14: Update Book Status on Return: Write a query to update the status of books in the books table to "Yes" 
--when they are returned (based on entries in the return_status table).

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(20),p_issued_id VARCHAR(30))
LANGUAGE plpgsql
AS $$
DECLARE
	v_isbn VARCHAR(30);
	v_book_name VARCHAR(75);
BEGIN
	--Inserting into the returns table
	INSERT INTO return_status (return_id,issued_id,return_date)
	VALUES(p_return_id,p_issued_id,CURRENT_DATE);

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO 
		v_isbn,
		v_book_name
	FROM issued_status
	WHERE issued_id=p_issued_id;

	UPDATE books
	SET status='yes'
	WHERE isbn=v_isbn;

	RAISE NOTICE 'Happy Reading!Thank you for returning %', v_book_name;
END;
$$

CALL add_return_records('RS138','IS135');

/*15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued,
the number of books returned, and the total revenue generated from book rentals. */

CREATE TABLE branch_report
AS
SELECT 
	e.branch_id,
	COUNT(i.issued_emp_id) AS issued_quantity,
	COUNT(r.return_id) AS return_quantity,
	SUM(b.rental_price) AS revenue,
	br.manager_id
FROM employees AS e
JOIN issued_status AS i
ON e.emp_id=i.issued_emp_id
LEFT JOIN return_status as r
ON r.issued_id=i.issued_id
JOIN books AS b
ON b.isbn=i.issued_book_isbn
JOIN branch AS br
ON e.branch_id=br.branch_id
GROUP BY e.branch_id, br.manager_id
ORDER BY e.branch_id

SELECT * FROM branch_report

/*16: Create a table of Active Members containing members who have issued at least 1 book in the last 2 months.*/

DROP TABLE active_members
CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN
	(SELECT 
		DISTINCT issued_member_id
		FROM issued_status
		WHERE
			issued_date >= CURRENT_DATE - INTERVAL '360 days')

SELECT * FROM active_members



SELECT 
	DISTINCT issued_member_id,
	m.*
FROM issued_status AS i
JOIN members AS m
ON m.member_id=i.issued_member_id
WHERE
	issued_date >= CURRENT_DATE - INTERVAL '360 days'

/*17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.*/

SELECT 
	e.emp_name,
	e.branch_id,
	COUNT(i.issued_id) AS quantity_issued
FROM employees AS e
JOIN issued_status AS i
ON e.emp_id=i.issued_emp_id
GROUP BY e.emp_id
ORDER BY COUNT(i.issued_id) DESC
LIMIT 3

/*18: Stored Procedure Objective: Write a stored procedure that updates the status of a book in the library 
based on its issuance.The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter.
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that 
the book is currently not available.*/

CREATE OR REPLACE PROCEDURE 
issue_book(p_issued_id VARCHAR(10),p_issued_member_id VARCHAR(10),p_issued_book_isbn VARCHAR(30),
p_issued_emp_id VARCHAR(30))
LANGUAGE plpgsql
AS $$
DECLARE 
v_status VARCHAR(10);
v_isbn VARCHAR(30);
BEGIN
--Check if book is available 'yes'
	SELECT status 
	INTO v_status
	FROM books
	WHERE isbn=p_issued_book_isbn;

	IF v_status='yes' THEN
		INSERT INTO issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id)
		VALUES(p_issued_id,p_issued_member_id,CURRENT_DATE,p_issued_book_isbn,p_issued_emp_id);

		UPDATE books
		SET status='no'
		WHERE isbn=v_isbn;

		RAISE NOTICE 'Book record added successfully for book_isbn: %',p_issued_book_isbn;
	
	ELSE
		RAISE NOTICE 'Sorry, the requested book is unavailable.';
	
	END IF;


END;
$$

CALL issue_book('IS155','C108','978-0-330-25864-8','E104')

