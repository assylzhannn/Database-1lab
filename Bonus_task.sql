--Database Schema
DROP TABLE customers cascade ;
create table customers
(
    customer_id serial primary key,
    iin varchar(12) unique not null check ( length(iin) = 12 ),
    full_name varchar(50),
    phone varchar(20),
    email varchar(30),
    status varchar(20) check ( status in ('active', 'blocked', 'frozen') ),
    created_at timestamp default current_timestamp,
    daily_limit_kzt decimal(10, 2)
);

drop table accounts cascade ;
create table accounts(
    account_id serial primary key ,
    customer_id integer not null references customers(customer_id) ,
    account_number varchar(34) unique not null ,--IBAN format
    currency varchar(3) check ( currency in ('KZT','USD','EUR','RUB') ),
    balance decimal(10,2),
    is_active boolean,
    opened_at timestamp default current_timestamp,
    closed_at timestamp
);

drop table transactions cascade ;
create table transactions (
    transaction_id serial primary key,
    from_account_id integer references accounts(account_id),
    to_account_id integer references accounts(account_id),
    amount decimal(10,2) check (amount > 0) ,
    currency varchar(3) ,
    exchange_rate decimal(10,6) ,
    amount_kzt decimal(10,2) not null,
    type varchar(20) check (type in ('transfer', 'deposit', 'withdrawal')),
    status varchar(20) check (status in ('pending', 'completed', 'failed', 'reversed')),
    created_at timestamp default current_timestamp,
    completed_at timestamp,
    description text
);

create table exchange_rates (
    rate_id serial primary key,
    from_currency varchar(3) ,
    to_currency varchar(3),
    rate decimal(10,5) ,
    valid_from timestamp default current_timestamp,
    valid_to timestamp
);

drop table audit_log cascade ;
create table audit_log (
    log_id serial primary key,
    table_name varchar(20) ,
    record_id integer ,
    action varchar(10) check (action in ('INSERT', 'UPDATE', 'DELETE')),
    old_values jsonb,
    new_values jsonb,
    changed_by varchar(50),
    changed_at timestamp ,
    ip_address inet
);

--populate each table with 10 meaningful records for testing
insert into customers (iin, full_name, phone, email, status, daily_limit_kzt) values
('000000000001', 'Assylzhan Kuntubay', '+77474744613', 'asylkuntubay@gmail.com', 'active', 5000000.00),
('000000000010', 'Assel Zhumadylda', '+77066744613', 'assel@gmail.com', 'active', 3000000.00),
('000000000011', 'Ayagoz Zhuman', '77011111111', 'ayagoz@gmail.com', 'active', 1000000.00),
('000000000100', 'Inkar Auyes', '+77012222222', 'ina@gmail.com', 'frozen', 200000.00),
('000000000101', 'Kazyna Kunesbay', '+7701333333', 'kazyna@gmail.com', 'blocked', 1000000.00),
('000000000110', 'Alina Mukhametsadyk', '+77014444444', 'alina@gmail.com', 'active', 800000.00),
('000000000111', 'Bekarys Toktar', '+77015555555', 'bekarys@gmail.com', 'active', 1000000.00),
('000000001000', 'Aruzhan Kuntubay', '+77016666666', 'aruzhan@gmail.com', 'active', 6000000.00),
('000000001001', 'Uldana Kuntubay', '+77017777777', 'uldana@gmail.com', 'active', 3000000.00),
('000000001010', 'Serikbolsyn Kuntubay', '+7701888888', 'seke@gmail.com', 'active', 9000000.00);

insert into accounts (customer_id, account_number, currency, balance, is_active) values
(1, 'kz111111111111111111', 'KZT', 10000.00, true),
(1, 'kz222222222222222222', 'USD', 50000.00, true),
(2, 'kz333333333333333333', 'KZT', 800000.00, true),
(2, 'kz444444444444444444', 'EUR', 30000.00, true),
(3, 'kz555555555555555555', 'KZT', 5000000.00, true),
(3, 'kz666666666666666666', 'RUB', 400000.00, true),
(4, 'kz777777777777777777', 'KZT', 100000.00, false),
(5, 'kz888888888888888888', 'KZT', 50000.00, true),
(6, 'kz999999999999999999', 'USD', 20000.00, true),
(7, 'kz000000000000000000', 'KZT', 100000.00, true),
(8, 'kz111111111000000000', 'EUR', 15000.00, true),
(9, 'kz000000000111111111', 'KZT', 30000.00, true),
(10, 'kz22222222000000000', 'USD', 75000.00, true);


insert into exchange_rates (from_currency, to_currency, rate) values
('USD', 'KZT', 450.00),
('EUR', 'KZT', 500.00),
('RUB', 'KZT', 5.00),
('KZT', 'USD', 0.002222),
('KZT', 'EUR', 0.002000),
('KZT', 'RUB', 0.20),
('USD', 'EUR', 0.90),
('EUR', 'USD', 1.11);


insert into transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, description) values
(1, 3, 50000.00, 'KZT', 1.0, 50000.00, 'transfer', 'completed', 'payment'),
(2, 4, 1000.00, 'USD', 450.0, 450000.00, 'transfer', 'completed', 'international translation'),
(5, 6, 200000.00, 'KZT', 1.0, 200000.00, 'transfer', 'completed', 'tax'),
(null, 7, 500000.00, 'KZT', 1.0, 500000.00, 'deposit', 'completed', 'payment'),
(8, null, 20000.00, 'KZT', 1.0, 20000.00, 'withdrawal', 'completed', 'сash withdrawal');

create or replace function audit_trigger1()
returns trigger as $$
begin
    if tg_op = 'insert' then
        insert into audit_log (table_name, record_id, action, old_values, new_values, changed_by)
        values (tg_table_name, new.account_id, 'insert', null, row_to_json(new), current_user);
    elsif tg_op = 'update' then
        insert into audit_log (table_name, record_id, action, old_values, new_values, changed_by)
        values (tg_table_name, new.account_id, 'update', row_to_json(old), row_to_json(new), current_user);
    elsif tg_op = 'delete' then
        insert into audit_log (table_name, record_id, action, old_values, new_values, changed_by)
        values (tg_table_name, old.account_id, 'delete', row_to_json(old), null, current_user);
    end if;
    return null;
end;
$$ language plpgsql;

create trigger accounts_audit_trigger
after insert or update or delete on accounts
for each row execute function audit_trigger1();

--TASK1
create or replace procedure process_transfer(
    p_from_account_number varchar,
    p_to_account_number varchar,
    p_amount decimal,
    p_currency varchar,
    p_description text default null
)
language plpgsql
as $$
declare
    v_from_account accounts%rowtype;
    v_to_account accounts%rowtype;
    v_customer customers%rowtype;
    v_exchange_rate decimal(10,6);
    v_amount_kzt decimal(15,2);
    v_daily_spent decimal(15,2);
    v_transaction_id integer;
    v_error_message text;
begin
    begin
        select * into v_from_account
        from accounts
        where account_number = p_from_account_number and is_active = true
        for update;

        select * into v_to_account
        from accounts
        where account_number = p_to_account_number and is_active = true
        for update;

        -- validate sender account exists
        if v_from_account.account_id is null then
            raise exception 'error1: sender account not found';
        end if;

        -- validate receiver account exists
        if v_to_account.account_id is null then
            raise exception 'error2: receiver account not found';
        end if;

        select * into v_customer from customers
        where customer_id = v_from_account.customer_id and status = 'active';

        if v_customer.customer_id is null then
            raise exception 'error3: sender customer is blocked';
        end if;

        if v_from_account.balance < p_amount then
            v_error_message := 'error4: insufficient funds in sender account. ' ||
                              'balance: ' || v_from_account.balance || ', ' ||
                              'required: ' || p_amount;
            raise exception '%', v_error_message;
        end if;

        if v_from_account.currency = p_currency then
            v_exchange_rate := 1.0;
        else
            select rate into v_exchange_rate
            from exchange_rates
            where from_currency = p_currency
              and to_currency = 'KZT'
              and valid_from <= current_timestamp
              and valid_to >= current_timestamp
            order by valid_from desc limit 1;

            if v_exchange_rate is null then
                raise exception 'error5: exchange rate for % not found', p_currency;
            end if;
        end if;

        v_amount_kzt := p_amount * v_exchange_rate;

        select coalesce(sum(amount_kzt), 0) into v_daily_spent
        from transactions t
        join accounts a on t.from_account_id = a.account_id
        where a.customer_id = v_customer.customer_id
          and date(t.created_at) = current_date
          and t.status = 'completed';

        if v_daily_spent + v_amount_kzt > v_customer.daily_limit_kzt then
            v_error_message := 'error6: daily transaction limit exceeded. ' ||
                              'used: ' || v_daily_spent || ', ' ||
                              'limit: ' || v_customer.daily_limit_kzt || ', ' ||
                              'attempt: ' || v_amount_kzt;
            raise exception '%', v_error_message;
        end if;

        savepoint before_transfer;

        insert into transactions (
            from_account_id, to_account_id, amount, currency,
            exchange_rate, amount_kzt, type, status, description
        ) values (
            v_from_account.account_id, v_to_account.account_id,
            p_amount, p_currency, v_exchange_rate, v_amount_kzt,
            'transfer', 'pending', p_description
        ) returning transaction_id into v_transaction_id;

        update accounts
        set balance = balance - p_amount
        where account_id = v_from_account.account_id;

        update accounts
        set balance = balance + p_amount
        where account_id = v_to_account.account_id;

        update transactions
        set status = 'completed', completed_at = current_timestamp
        where transaction_id = v_transaction_id;

        commit;

        raise notice 'transaction % completed successfully', v_transaction_id;

    exception
        when others then
            rollback to savepoint before_transfer;

            if v_transaction_id is not null then
                update transactions
                set status = 'failed', completed_at = current_timestamp
                where transaction_id = v_transaction_id;
            end if;

            insert into audit_log (table_name, record_id, action, new_values, changed_by)
            values ('transactions', coalesce(v_transaction_id, 0), 'insert',
                   jsonb_build_object('error', sqlerrm),
                   current_user);

            raise;
    end;
end;
$$;
-- view 1: customer_balance_summary
create or replace view customer_balance_summary as
with customer_balances as (
    select
        cus.customer_id,
        cus.full_name,
        cus.iin,
        cus.status as customer_status,
        cus.daily_limit_kzt,
        a.account_number,
        a.currency,
        a.balance,
        coalesce(
            case
                when a.currency = 'USD' then a.balance * er.rate
                when a.currency = 'EUR' then a.balance * er.rate
                when a.currency = 'RUB' then a.balance * er.rate
                else a.balance
            end,
            a.balance
        ) as balance_kzt
    from customers cus
    join accounts a on cus.customer_id = a.customer_id
    left join exchange_rates er on
        a.currency = er.from_currency
        and er.to_currency = 'KZT'
        and current_timestamp between er.valid_from and er.valid_to
    where a.is_active = true
),
aggregated as (
    select
        customer_id,
        full_name,
        iin,
        customer_status,
        daily_limit_kzt,
        count(*) as account_count,
        sum(balance_kzt) as total_balance_kzt,
        string_agg(account_number || ' (' || currency || ': ' || balance || ')', ', ') as account_details
    from customer_balances
    group by customer_id, full_name, iin, customer_status, daily_limit_kzt
)
select
    customer_id,
    full_name,
    iin,
    customer_status,
    account_count,
    account_details,
    total_balance_kzt,
    daily_limit_kzt,
    round((coalesce((
        select sum(amount_kzt)
        from transactions t
        join accounts a on t.from_account_id = a.account_id
        where a.customer_id = aggregated.customer_id
        and date(t.created_at) = current_date
        and t.status = 'completed'
    ), 0) / daily_limit_kzt * 100), 2) as limit_utilization_percent,
    rank() over (order by total_balance_kzt desc) as balance_rank
from aggregated
order by balance_rank;

-- view 2: daily_transaction_report
create or replace view daily_transaction_report as
with daily_stats as (
    select
        date(created_at) as transaction_date,
        type,
        status,
        count(*) as transaction_count,
        sum(amount_kzt) as total_volume_kzt,
        avg(amount_kzt) as avg_amount_kzt
    from transactions
    where status = 'completed'
    group by date(created_at), type, status
)
select
    transaction_date,
    type,
    status,
    transaction_count,
    total_volume_kzt,
    avg_amount_kzt,
    sum(total_volume_kzt) over (partition by type order by transaction_date) as running_total_kzt,
    lag(total_volume_kzt) over (partition by type order by transaction_date) as previous_day_volume,
    case
        when lag(total_volume_kzt) over (partition by type order by transaction_date) > 0
        then round(((total_volume_kzt - lag(total_volume_kzt) over (partition by type order by transaction_date))
              / lag(total_volume_kzt) over (partition by type order by transaction_date) * 100), 2)

    end as day_over_day_growth_percent
from daily_stats
order by transaction_date desc, type;

-- view 3: suspicious_activity_view (WITH SECURITY BARRIER)
create or replace view suspicious_activity_view with (security_barrier = true) as
with large_transactions as (
    select
        t.transaction_id,
        t.created_at,
        t.amount_kzt,
        t.from_account_id,
        t.to_account_id,
        'large transaction (>5m KZT)' as reason
    from transactions t
    where t.amount_kzt > 5000000
    and t.status = 'completed'
),
frequent_transactions as (
    select
        a.customer_id,
        date_trunc('hour', t.created_at) as hour_start,
        count(*) as transaction_count,
        'high frequency (>10/hour)' as reason
    from transactions t
    join accounts a on t.from_account_id = a.account_id
    where t.status = 'completed'
    group by a.customer_id, date_trunc('hour', t.created_at)
    having count(*) > 10
),
rapid_sequence as (
    select
        t1.transaction_id,
        t1.from_account_id,
        t1.created_at,
        'rapid sequential transfer (<1 min)' as reason
    from transactions t1
    join transactions t2 on t1.from_account_id = t2.from_account_id
    where t1.status = 'completed'
    and t2.status = 'completed'
    and t1.transaction_id < t2.transaction_id
    and extract(epoch from (t2.created_at - t1.created_at)) < 60
    and t2.created_at > t1.created_at
)
select
    'large' as activity_type,
    transaction_id,
    created_at,
    amount_kzt,
    reason,
    from_account_id,
    to_account_id
from large_transactions
union all
select
    'frequent' as activity_type,
    null as transaction_id,
    hour_start as created_at,
    null as amount_kzt,
    reason,
    null as from_account_id,
    null as to_account_id
from frequent_transactions
union all
select
    'rapid' as activity_type,
    transaction_id,
    created_at,
    null as amount_kzt,
    reason,
    from_account_id,
    null as to_account_id
from rapid_sequence;

--  task 3: Performance Optimization with Indexes
-- 1. b-tree index
create index idx_accounts_account_number on accounts(account_number);
explain analyze select * from accounts where account_number = 'kz11111111111111';

-- 2. composite index
create index ind_trans_date_status on transactions(created_at, status);
explain analyze select * from transactions where created_at >= '2024-01-01' and status = 'completed';

-- 3. partial index
create index ind_accounts_active on accounts(customer_id) where is_active = true;
explain analyze select * from accounts where is_active = true and customer_id = 1;

-- 4. expression index
create index ind_customers_email_lower on customers(lower(email));
explain analyze select * from customers where lower(email) = lower('assel@gmail.com');

-- 5. gin index
create index ind_audit_log_jsonb on audit_log using gin(new_values);
explain analyze select * from audit_log where new_values @> '{"status": "failed"}';

-- 6. hash index
create index idx_customers_tin_hash on customers using hash(iin);
explain analyze select * from customers where iin = '111111111111';

-- 7. covering index
create index ind_transactions_covering on transactions(created_at, type, status) include (amount_kzt, from_account_id, to_account_id);
explain analyze select created_at, type, amount_kzt from transactions where created_at >= '2024-01-01' and type = 'transfer';


-- Task 4: Advanced Procedure - Batch Processing
 create or replace procedure process_salary_batch(
    p_company_account_number varchar,
    p_payments jsonb,
    out p_successful_count integer,
    out p_failed_count integer,
    out p_failed_details jsonb
)
language plpgsql
as $$
declare
    v_company_account accounts%rowtype;
    v_total_amount decimal(15,2) := 0;
    v_payment jsonb;
    v_iin varchar;
    v_amount decimal;
    v_description text;
    v_employee_account accounts%rowtype;
    v_error text;
    v_failed_items jsonb := '[]'::jsonb;
    v_successful integer := 0;
    v_failed integer := 0;
    v_lock_id integer;
    v_error_message text;
begin
    v_lock_id := abs(hashtext(p_company_account_number));

    if not pg_try_advisory_lock(v_lock_id) then
        raise exception 'error6: batch processing already in progress';
    end if;

    begin
        select * into v_company_account
        from accounts
        where account_number = p_company_account_number
        for update;

        if v_company_account.account_id is null then
            raise exception 'error7: company account not found';
        end if;

        select sum((value ->>'amount' )::decimal)into v_total_amount
        from jsonb_array_elements(p_payments);

        if v_company_account.balance < v_total_amount then
            v_error_message := 'err103: insufficient funds in company account. ' ||
                              'required: ' || v_total_amount || ', ' ||
                              'available: ' || v_company_account.balance;
            raise exception '%', v_error_message;
        end if;

        begin
            for v_payment in select * from jsonb_array_elements(p_payments)
            loop
                begin
                    v_iin := v_payment->>'iin';
                    v_amount := (v_payment->>'amount')::decimal;
                    v_description := v_payment->>'description';

                    select a.* into v_employee_account
                    from accounts a
                    join customers c on a.customer_id = c.customer_id
                    where c.iin = v_iin
                      and a.is_active = true
                      and a.currency = v_company_account.currency;

                    if v_employee_account.account_id is null then
                        raise exception 'error8: employee account with iin % not found', v_iin;
                    end if;

                    savepoint salary_payment;

                    insert into transactions (
                        from_account_id, to_account_id, amount, currency,
                        exchange_rate, amount_kzt, type, status, description
                    ) values (
                        v_company_account.account_id,
                        v_employee_account.account_id,
                        v_amount,
                        v_company_account.currency,
                        1.0,
                        v_amount,
                        'transfer',
                        'pending',
                        coalesce(v_description, 'salary payment')
                    );

                    with updates as (
                        update accounts
                        set balance = balance - v_amount
                        where account_id = v_company_account.account_id
                        returning account_id
                    )
                    update accounts
                    set balance = balance + v_amount
                    where account_id = v_employee_account.account_id;

                    update transactions
                    set status = 'completed', completed_at = current_timestamp
                    where from_account_id = v_company_account.account_id
                      and to_account_id = v_employee_account.account_id
                      and status = 'pending'
                      and amount = v_amount;

                    v_successful := v_successful + 1;

                exception
                    when others then
                        rollback to savepoint salary_payment;
                        v_failed := v_failed + 1;
                        v_error := sqlerrm;

                        v_failed_items := v_failed_items ||
                            jsonb_build_object(
                                'iin', v_iin,
                                'amount', v_amount,
                                'error', v_error
                            );

                        continue;
                end;
            end loop;

            commit;

        exception
            when others then
                rollback;
                raise;
        end;

    exception
        when others then
            perform pg_advisory_unlock(v_lock_id);
            raise;
    end;

    perform pg_advisory_unlock(v_lock_id);

    p_successful_count := v_successful;
    p_failed_count := v_failed;
    p_failed_details := v_failed_items;

    drop materialized view if exists salary_batch_summary;
    create materialized view salary_batch_summary as
    select
        current_date as batch_date,
        p_company_account_number as company_account,
        (select count(*) from jsonb_array_elements(p_payments)) as total_payments,
        v_successful as successful_payments,
        v_failed as failed_payments,
        v_total_amount as total_amount,
        v_failed_items as failed_details;

    raise notice 'batch processing completed. successful: %, failed: %',
    v_successful, v_failed;
end;
$$;

--Test cases demonstrating each scenario (successful and failed operations)
call process_transfer(
    'kz111111111111111111',
    'kz222222222222222222',
    100000.00,
    'KZT',
    'payment'
);

-- test 2 failed operation
-- call process_transfer(
--     'kz111111111111111111',
--     'kz222222222222222222',
--     2000000.00,
--     'KZT',
--     'not enough'
-- );

--test 3
do $$
declare
    v_success integer;
    v_failed integer;
    v_details jsonb;
begin
    call process_transfer(
        'kz111111111111111111',
        '[
            {"iin": "000000000001", "amount": 150000, "description": "salary"},
            {"iin": "000000000010", "amount": 200000, "description": "salary"},
            {"iin": "000000000011", "amount": 180000, "description": "salary"}
        ]'::jsonb,
        v_success,
        v_failed,
        v_details
    );
    raise notice ':processing successful %, not successful %, details %',
    v_success, v_failed, v_details;
end $$;


select * from customer_balance_summary
where balance_rank <= 5;
explain (analyze, buffers)
select * from daily_transaction_report
where transaction_date >= current_date - 30;

-- concurrency test
-- first:
-- begin;
-- select * from accounts where account_number = 'kz111111111111111111' for update;

-- second should wait:
-- begin;
-- select * from accounts where account_number = 'kz111111111111111111' for update;
-- commit;
/*Brief documentation explaining design decisions
1.Savepoints for Partial Rollbacks:if something goes wrong mid-transfer, I can roll back only the problematic part, not the entire transaction.
2.Select for update: if two people trying to transfer money from the same account simultaneously. Without locks, money could disappear.
With locks the second transfer waits for the first to complete.
3.Error logging: error gets a unique code so users see spesific reasons
4.multi-currency support:can easily add new currencies without changing transfer structure
  5.atomic balance updates:both operations execute as one unit. both succeed or cancelled
  */

-- create performance report
create table performance_report as
select
    indexname,
    indexdef,
    tablename
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;
-- export results
copy performance_report to '/tmp/performance_report.csv' with csv header;

--test 1 successful transfer
call process_transfer(
    'kz444444444444444444',
    'kz333333333333333333',
    100000.00,
    'KZT',
    ''
);
--expected result: transaction completed successfully, balances updated.

--test 2: error - insufficient funds
call process_transfer(
    'kz111111111111111111',
    'kz333333333333333333',
    2000000.00,
    'KZT',
    'not enough'
);
-- result: error error4:  balance is not enough.

--test 3: batch salary processing
do $$
declare
    v_success integer;
    v_failed integer;
    v_details jsonb;
begin
    call process_transfer(
        'kz111111111111111111',
        '[
            {"iin": "000000000010", "amount": 150000, "description": "salary"},
            {"iin": "000000000011", "amount": 200000, "description": "salary"}
        ]'::jsonb,
        v_success,
        v_failed,
        v_details
    );
end $$;



