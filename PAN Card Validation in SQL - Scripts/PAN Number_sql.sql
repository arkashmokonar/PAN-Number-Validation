
create table stg_pan_numbers_dataset
(
   	pan_number text
);

select * from stg_pan_numbers_dataset;

---Identify and handle missing data:

select * from stg_pan_numbers_dataset where pan_number is null

---Check for duplicates

select pan_number,count(1)
from stg_pan_numbers_dataset
group by  pan_number
having count(1)>1;

---Handle leading/traning space

select * 
from stg_pan_numbers_dataset 
where pan_number <> trim(pan_number);

---Correct lettercase

select * 
from stg_pan_numbers_dataset 
where pan_number <> upper(pan_number);

---Cleaned Pan Number:
select distinct  upper(trim(pan_number)) as pan_number 
from stg_pan_numbers_dataset 
where pan_number is not null
and trim(pan_number) <> '';

	---Function to check if adjacent characters are the same--ZWOVO3987M ==> ZWOVO

create or replace function fun_check_adjacent_characters(p_str text)
returns boolean
language plpgsql
as $$
begin 
for i in 1.. length (p_str)
loop
if substring(p_str,i,1)= substring(p_str,i+1,1)
then
return true; --- The characters are adjacent
end if;
end loop;
return false; --- non of the characters are adjacent to each other were the same
end;
$$
select fun_check_adjacent_characters('ZZOVO')

---Function to check if sequencial characters are used
create or replace function fun_check_sequencial_characters(p_str text)---ABCDE, AXDGE
returns boolean
language plpgsql
as $$
begin
    for i in 1..length(p_str) - 1
    loop
        if ascii(substring(p_str, i+1, 1)) - ascii(substring(p_str, i, 1)) = 1
        then
            return true;--- The string is forming a sequence
        end if;
    end loop;
    return false;--- The string does not form the sequence
end;
$$;
select ascii('X')
select fun_check_sequencial_characters('ABXDE')

---Regular expression to validate the patterns or structure of PAN Numbers ---AAAAA1234A

select * 
from stg_pan_numbers_dataset 
where pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z}$'

---Valid and Invalid PAN categorization
create or replace view vw_valid_invalid_pans
as
with cte_cleaned_pan as (
    select distinct upper(trim(pan_number)) as pan_number 
    from stg_pan_numbers_dataset 
    where pan_number is not null
      and trim(pan_number) <> ''
),
cte_valid_pan as (
    select *
    from cte_cleaned_pan
    where fun_check_adjacent_characters(pan_number) = false
      and fun_check_sequential_characters(substring(pan_number,1,5)) = false
      and fun_check_sequential_characters(substring(pan_number,6,4)) = false
      and pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
)
select cln.pan_number,
    case when vld.pan_number is not null 
         then 'Valid PAN'
         else 'Invalid PAN'
    end as status
from cte_cleaned_pan cln
left join cte_valid_pan vld on vld.pan_number = cln.pan_number;

select * from vw_valid_invalid_pans
-- Summary report
with cte as (
    select
        (select count(*) from stg_pan_numbers_dataset) as total_processed_records,
        count(*) filter (where status = 'Valid PAN') as total_valid_pans,
        count(*) filter (where status = 'Invalid PAN') as total_invalid_pans
    from vw_valid_invalid_pans
)
select 
    total_processed_records, 
    total_valid_pans, 
    total_invalid_pans,
    (total_processed_records) - (total_valid_pans + total_invalid_pans) as total_missing_pans
from cte;


