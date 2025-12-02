Drop table accounts cascade ;
DROP table products cascade ;
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00
 );
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
 );

 INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob', 500.00),
    ('Wally', 750.00);
 INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);

 --3.2 Task 1: Basic Transaction with COMMIT
 BEGIN;
 UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
 UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';
 COMMIT;

select * from accounts;
--  Questions:
--  • a) What are the balances of Alice and Bob after the transaction?
    --Alice- 900 , Bob-600

--  • b) Why is it important to group these two UPDATE statements in a single transaction?
    --grouping both updates in a single ensures atomicity- either both operations complete succesfully or neither does.

--  • c) What would happen if the system crashed between the two UPDATE statements without a
-- transaction?
    --Alice balance:900, Bob's balance:500. 100$ would be lost

-- 3.3 Task 2: Using ROLLBACK
 BEGIN;
 UPDATE accounts SET balance = balance - 500.00
    WHERE name = 'Alice';
 SELECT * FROM accounts WHERE name = 'Alice';-- Oops! Wrong amount, let's undo
 ROLLBACK;
 SELECT * FROM accounts WHERE name = 'Alice';

-- Questions:
--  • a) What was Alice's balance after the UPDATE but before ROLLBACK?
    --500
--  • b) What is Alice's balance after ROLLBACK?
    --900
--  • c) In what situations would you use ROLLBACK in a real application?
    --error handling when business logic fails, multi-step operations where intermediate steps might fail


--  3.4 Task 3: Working with SAVEPOINTs
 BEGIN;
 UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
 SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';-- Oops, should transfer to Wally instead
 ROLLBACK TO my_savepoint;
 UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Wally';
 COMMIT;

--  Questions:
--  • a) After COMMIT, what are the balances of Alice, Bob, and Wally?
    --Alice:800, Bob:600, Wally:850
--  • b) Was Bob's account ever credited? Why or why not in the final state?
    --Yes bob's account was credited during the transaction, but the rollback undone that specific update, restoring Bob's balance to what it was at the save point
--  • c) What is the advantage of using SAVEPOINT over starting a new transaction?
    --savepoint allows partial rollback within a transaction without losing all work done

--  3.5 Task 4: Isolation Level Demonstration
 --Scenario A: READ COMMITTED

 --Terminal 1:
 BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
 SELECT * FROM products WHERE shop = 'Joe''s Shop';-- Wait for Terminal 2 to make changes and COMMIT-- Then re-run:
 SELECT * FROM products WHERE shop = 'Joe''s Shop';
 COMMIT;

 --Terminal 2 (while Terminal 1 is still running):
 BEGIN;
 DELETE FROM products WHERE shop = 'Joe''s Shop';
 INSERT INTO products (shop, product, price)
    VALUES ('Joe''s Shop', 'Fanta', 3.50);
 COMMIT;

-- Scenario B: SERIALIZABLE
 --Repeat the above scenario but use:
-- BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
 BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
 SELECT * FROM products WHERE shop = 'Joe''s Shop';-- Wait for Terminal 2 to make changes and COMMIT-- Then re-run:
 SELECT * FROM products WHERE shop = 'Joe''s Shop';
 COMMIT;

 --Terminal 2 (while Terminal 1 is still running):
 BEGIN;
 DELETE FROM products WHERE shop = 'Joe''s Shop';
 INSERT INTO products (shop, product, price)
    VALUES ('Joe''s Shop', 'Fanta', 3.50);
 COMMIT;


--  Questions:
--  • a) In Scenario A, what data does Terminal 1 see before and after Terminal 2 commits?
    --before: coke:2.50, pepsi:3.00
    --after: fanta:3.50
--  • b) In Scenario B, what data does Terminal 1 see?
    --Terminal 1 sees the same data in both SELECT statements (original products).
    -- It won't see Terminal 2's changes because SERIALIZABLE provides snapshot isolation - it sees the database state as it was when the transaction began.
--  • c) Explain the difference in behavior between READ COMMITTED and SERIALIZABLE.
    --read committed: allows non-repeatable reads.Each query sees committed changes from other transactions that completed before the query execution
    --serializable: provides full isolation. transactions see a snapshot of the database as it was when the transaction started. Prevents dirty read, non-repeatable reads and phantom reads


--  3.6 Task 5: Phantom Read Demonstration
-- Objective: Understand phantom reads with REPEATABLE READ isolation level.
--  Terminal 1:
 BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
 SELECT MAX(price), MIN(price) FROM products
    WHERE shop = 'Joe''s Shop';-- Wait for Terminal 2
 SELECT MAX(price), MIN(price) FROM products
    WHERE shop = 'Joe''s Shop';
 COMMIT;
 --Terminal 2:
 BEGIN;
 INSERT INTO products (shop, product, price)
    VALUES ('Joe''s Shop', 'Sprite', 4.00);
 COMMIT;


--  Questions:
--  • a) Does Terminal 1 see the new product inserted by Terminal 2?
--  • b) What is a phantom read?
--  • c) Which isolation level prevents phantom reads?


--  3.7 Task 6: Dirty Read Demonstration
--  Objective: Understand dirty reads with READ UNCOMMITTED isolation level.
--  Terminal 1:
 BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 SELECT * FROM products WHERE shop = 'Joe''s Shop';-- Wait for Terminal 2 to UPDATE but NOT commit
 SELECT * FROM products WHERE shop = 'Joe''s Shop';-- Wait for Terminal 2 to ROLLBACK
 SELECT * FROM products WHERE shop = 'Joe''s Shop';
 COMMIT;

 --Terminal 2:
 BEGIN;
 UPDATE products SET price = 99.99
    WHERE product = 'Fanta';-- Wait here (don't commit yet)-- Then:
 ROLLBACK;


--  Questions:
--  • a) Did Terminal 1 see the price of 99.99? Why is this problematic?
    --Yes. with read committed, terminal 1 sees the uncommitted change from terminal2. This is problematic because terminal2 rolled back, so terminal1 saw data that never actually existed in the committed database state
--  • b) What is a dirty read?
    --A dirty read occurs when a transaction reads uncommitted data from another transaction that may be rolled back later.
--  • c) Why should READ UNCOMMITTED be avoided in most applications?
    --read uncommitted should be avoided because it can lead to incorrect data being used for decisions


-- 4. Independent Exercises
--  Exercise 1
--  Write a transaction that transfers $200 from Bob to Wally, but only if Bob has sufficient funds. Use
-- appropriate error handling.
BEGIN ;
update accounts
SET balance=balance-200.00
WHERE name ='Bob'
AND balance>= 200.00;

DO $$
BEGIN
   if not  FOUND Then
        Raise EXCEPTION 'Transfer failed';
   end if;
end$$;

update accounts
SET balance= balance+200.00
WHERE name='Wally';
COMMIT ;

--  Exercise 2
--  Create a transaction with multiple savepoints that:
    BEGIN ;
--  • Inserts a new product
    INSERT INTO products(shop, product, price) VALUES ('Zhazira','milk',1.25);
--  • Creates a savepoint
    SAVEPOINT sp1;
--  • Updates the price
    UPDATE products set price= 3.50
    WHERE product= 'milk' and shop='Zhazira';
--  • Creates another savepoint
    SAVEPOINT sp2;
--  • Deletes the product
    DELETE FROM products
    where products.product='milk' AND shop='Zhazira';
--  • Rolls back to the first savepoint
    ROLLBACK TO sp1;
--  • Commits
--  Document the final state of the products table.


--  Exercise 3
--  Design and implement a banking scenario where two users simultaneously try to withdraw money
-- from the same account. Demonstrate how different isolation levels handle this situation.
   --terminal 1
BEGIN transaction isolation level read committed ;
SELECT balance from accounts where name='Alice' FOR UPDATE ;
UPDATE accounts SET balance = balance - 50
WHERE name = 'Alice';

COMMIT;


   --terminal2
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT balance FROM accounts WHERE name = 'Alice' FOR UPDATE;
UPDATE accounts SET balance = balance - 50
WHERE name = 'Alice';

COMMIT;

--  Exercise 4
--  Given the Sells(shop, product, price) relation from the lecture, write queries to demonstrate the
-- problem where Sally sees MAX < MIN when she and Joe don't use transactions properly. Then
-- show how transactions fix this issue.
BEGIN ;
UPDATE products set price=price*0.9 where shop='Joe''s Shop';
UPDATE products set price=price*1.1 where shop='Joe''s Shop';
COMMIT ;

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
SELECT Max(products.price),min(products.price) from products where shop='Joe''s Shop';
COMMIT;

 --5. Questions for Self-Assessment
-- 1.Explain each ACID property with a practical example.
     --Atomicity; bank transfer -deducting from account A and crediting account b must both happen or neither happens
     --Consistency: after a transfer, the sum of all account balances remains the same
     --Isolation: While Alice is transferring money to Bob, Charlie querying balances should see either the pre-transfer or post-transfer state,not an intermediate stste
     --Durability: After confirming a payment, the transaction record survives a power outage or server crash

-- 2.What is the difference between COMMIT and ROLLBACK?
     --Commit: makes all changes visible to other transactions,cant be undone after commit
     --Rollback: discard al changes made in transaction,returns database to state before transaction began

--  3.When would you use a SAVEPOINT instead of a full ROLLBACK?
     --use savepoint when only some operations within a transaction need to be undone

--  4.Compare and contrast the four SQL isolation levels.
     --Serializable: highest isolation
     --Repeatable Read: Data read is guaranteed to be the same if read again
     --Read committed : only sees committed data
     --Read Uncommitted: can see uncommitted changes from other transactions

--  5.What is a dirty read and which isolation level allows it?
     --Dirty read reading uncommitted data from another transaction
     --read uncommitted isolation

--  6.What is a non-repeatable read? Give an example scenario.
     --NON-repeatable read when a transaction reads the same row twice and gets different results because another transaction modified it in between

--  7.What is a phantom read? Which isolation levels prevent it?
     --phantom read: when transaction executes the same query twice and gets different numbers of rows because another transaction insrted or deleted matching rows
     --prevented by repeatable read,read committed, read uncommitted

-- 8.Why might you choose READ COMMITTED over SERIALIZABLE in a high-traffic
-- application?
     --choose read committed when performance is critical and real-time data needed

-- 9. Explain how transactions help maintain database consistency during concurrent access.
     --Transactions maintain consistency through:locking, isolation level, serializable order

--  10. What happens to uncommitted changes if the database system crashes?
     --uncommitted changes are lost because; transaction log, recovery process