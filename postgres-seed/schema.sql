-- Create schemas
drop schema if exists staging cascade ;
drop schema if exists sc cascade ;
create schema staging ;
create schema sc ;

-- Staging tables 
drop table if exists staging.sc_user_document ;
create table staging.sc_user_document ( 
	user_document json, 
	created_on_ts timestamptz default current_timestamp 
)
;

drop table if exists staging.crm_customer ;
create table staging.crm_customer ( 
	customer_email 	varchar(200),
	industry 		varchar(200),
	region 			varchar(200),
	company_name 	varchar(200),
	created_on_ts 	timestamptz default current_timestamp 
)
;



-- Dimension table
drop table if exists sc.sc_user cascade ;
drop table if exists sc.sc_user_hist ;

create table sc.sc_user ( 
	user_id 			int, 
	user_email 			varchar(200),
	on_trial 			boolean,
	user_industry 		varchar(200),
	user_region 		varchar(200),
	user_company 		varchar(200),
	effective_from_ts 	timestamptz default '1970-01-01',
	effective_to_ts 	timestamptz default '2199-12-31',
	created_on_ts		timestamptz default current_timestamp,
	constraint sc_user_pk primary key ( user_id ) 
)
;

create table sc.sc_user_hist () inherits ( sc.sc_user );

alter table sc.sc_user_hist add constraint sc_user_hist_pk primary key ( user_id, effective_from_ts ) ;

-- user event data 
drop table if exists sc.sc_user_event ; 

create table sc.sc_user_event ( 
	user_event_id 	serial primary key, 
	user_id 		int, 
	platform 		varchar(200),
	event_ts 		timestamptz, 
	event_type 		varchar(50),
	first_event 	boolean,
	created_on_ts 	timestamptz default current_timestamp
)
;

--procedure to populate sc.sc_user table 

create or replace function sc.load_sc_user () returns void as 
$$
	begin 
		--structure data to match table 
		
		--insert into sc.sc_user table 
		--on conflict check if any fields have changed
		--if fields have changed, insert data into history
		--update previous record's effective_to_ts value 
	end ;
$$ language plpgsql ;
