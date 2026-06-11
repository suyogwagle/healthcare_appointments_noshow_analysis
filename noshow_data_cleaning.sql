select * from no_show_medical_appointment;

-- data cleaning
select count(*) from no_show_medical_appointment;
-- total 110527 records
-- standardize the column names
 alter table no_show_medical_appointment
    rename column PatientId to patient_id,
    rename column AppointmentID to appointment_id,
    rename column Gender to gender,
    rename column ScheduledDay to scheduled_date,
    rename column AppointmentDay to appointment_date,
    rename column Age to age,
    rename column Neighbourhood to neighbourhood,
    rename column Scholarship to scholarship,
    rename column Hipertension to hypertension,
    rename column Diabetes to diabetes,
    rename column Alcoholism to alcoholism,
    rename column Handcap to handicapped,
    rename column SMS_received to sms_received,
    rename column No_show to no_show;
    
-- check if duplicate records exist
select *, count(*) from no_show_medical_appointment
group by patient_id, appointment_id, gender, scheduled_date, appointment_date, age, neighbourhood, scholarship, hypertension, diabetes, alcoholism, handicapped, sms_received, no_show
having count(*) >1;
-- no duplicate records exist

-- check if the ages are valid
select count(*) from no_show_medical_appointment
where age < 0;

select distinct(age) from no_show_medical_appointment;
-- found 1 record with age = -1 and assumed - to be an error input becuase other values in the record (hypertension = 0, alcoholism = 0, diabetes = 0) indicate he/she could be a a child so updated the records to age = 1
-- also found records with age greater than 100 but it can be realistic so kept it as it is
update no_show_medical_appointment
set age = 1
WHERE age = -1;

-- binning ages into 4 categories to facilitate the analysis phase
alter table no_show_medical_appointment
add column age_category varchar(50);

update no_show_medical_appointment
set age_category = 
	case
		when age <= 12 then 'child'
        when age > 12 and age < 18 then 'teenager'
        when age >= 18 and age <= 59 then 'adult'
        when age >= 60 then 'elderly'
	end;

-- check if the binary values are valid
select *
from no_show_medical_appointment
where scholarship not in (0,1)
   or hypertension not in (0,1)
   or diabetes not in (0,1)
   or alcoholism not in (0,1)
   or handicapped not in (0,1)
   or sms_received not in (0,1);
   
-- initially i assumed handicapped was a binary value as well but found out is isnt, its value ranges from 0 to 4 where values represent the number of disabilities a person has

select count(*) from no_show_medical_appointment
where handicapped > 1;

-- the number of records with value greater than or equal to 2 are very less (199) compared to the records with values 0 and 1 (110527 - 199) 
-- so it will be easier to analyze the data by binning all the values into two categories as 0 and 1 where 0 means no disabilities and 1 means there are 1 or more diabilities 

update no_show_medical_appointment
set handicapped = 1
where handicapped >= 1;
-- now the Handicapped data values is also binary

-- check if null values exist
select * FROM no_show_medical_appointment
where patient_id is null or 
	  appointment_id is null or 
      gender is null or 
      scheduled_date is null or 
      appointment_date is null or 
      age is null or 
      neighbourhood is null or
      scholarship is null or
      hypertension is null or 
      diabetes is null or 
      alcoholism is null or 
      handicapped is null or
      sms_received is null or
      no_show is null;
-- there are no null values

-- waiting days calculation i.e waiting_days = appointment_day - scheduled_day
-- omitted the time data that was concatenated with date in scheduled_day and appointment_day columns since time is irrelevant for analysis
alter table no_show_medical_appointment
modify column scheduled_date date,
modify column appointment_date date;

alter table no_show_medical_appointment
add waiting_days int;

update no_show_medical_appointment
set waiting_days = datediff(appointment_date, scheduled_date); 

-- check if waiting days have negative values
select count(*) from no_show_medical_appointment
where waiting_days < 0;

-- there are 5 records with negative waiting days which seems like the mistakes made during data entry process 
-- so omitting those records for now for analysis purposes only

delete from no_show_medical_appointment
where waiting_days < 0;

-- check the scheduled and appoinment dates 
select distinct(scheduled_date) from no_show_medical_appointment;
select distinct(appointment_date) from no_show_medical_appointment;

alter table no_show_medical_appointment
add column scheduled_month varchar(20),
add column scheduled_day varchar(30),
add column appointment_month varchar(20),
add column appointment_day varchar(30);

update no_show_medical_appointment
set
    scheduled_month = MONTHNAME(scheduled_date),
    scheduled_day = DAYNAME(scheduled_date),
    appointment_month = MONTHNAME(appointment_date),
    appointment_day = DAYNAME(appointment_date);
    
-- binning waiting_days into 4 bins as same day, within a week, within a month, long wait and adding a column to indicate the bin record fall in
alter table no_show_medical_appointment
add column waiting_days_category varchar(50);

update no_show_medical_appointment
set waiting_days_category = 
	case 
		when waiting_days = 0 then 'same day'
        when waiting_days > 0 and waiting_days <= 7 then 'within a week'
        when waiting_days > 7 and waiting_days <= 30 then 'within a month'
        else 'long wait'
	end;

-- working with no_show column (target variable in analysis)
select distinct(no_show),count(no_show) from no_show_medical_appointment
group by no_show;

-- add a column with binary values for no_show Yes = 1 and No = 0 ( yes menas patient did not show up and no meand patient showed up)
alter table no_show_medical_appointment
add column no_show_binary tinyint;

-- check if there are any leading pr trailing spaces
select distinct concat('[', no_show, ']')
from no_show_medical_appointment;

-- trim the trailing spaces 
update no_show_medical_appointment
set no_show = trim(trailing '\r' from no_show);

-- populate new column with binary values
update no_show_medical_appointment
set no_show_binary =
    case
        when no_show = 'Yes' then 1
        when no_show = 'No' then 0
    end;

-- gender value validation
select distinct concat('[', gender, ']')
from no_show_medical_appointment;
-- there are only two categories as M and F with no heading and trailing spaces

select count(*) from no_show_medical_appointment;
-- 110527 records reduced to 110522 records 

-- Data cleaning is complete


-- Exporting the cleaned dataset
select *
into outfile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cleaned_dataset.csv'
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
from no_show_medical_appointment;
