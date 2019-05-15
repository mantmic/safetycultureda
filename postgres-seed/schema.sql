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
	signup_ts			timestamptz,
	active 			boolean,
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
	declare
			--variable to use for start and end effective dates
			v_now timestamptz := now() ;
	begin
		-- drive from the staging.sc_user_document table
		-- create temporary table with new or changed records
		drop table if exists sc_user_new ;
		create temporary table sc_user_new as
		select
			  n.user_id
			, n.user_email
			, n.on_trial
			, n.signup_ts
			, n.user_industry
			, n.user_region
			, n.user_company
			, n.active
			, case when sc.user_id is null then '1970-01-01'::timestamptz
				   else v_now
			  end as effective_from_ts
		from
			( select
				  ud.user_id
				, ud.user_email
				, ud.on_trial
				, ud.signup_ts
				, ud.active
				, coalesce ( c.user_industry, 'unknown' ) 	as user_industry
				, coalesce ( c.user_region, 'unknown' ) 	as user_region
				, coalesce ( c.user_company, 'unknown' ) 	as user_company
			from
				( select
					( ud.user_document ->> 'user_id' )::int 				as user_id,
					( ud.user_document ->> 'user_email' )::varchar(200) 	as user_email,
					( ud.user_document ->> 'on_trial' )::boolean 			as on_trial,
					( ud.user_document ->> 'signup_ts' )::timestamptz 		as signup_ts,
					( ud.user_document ->> 'active' )::boolean 	as active,
					--row number to cator for duplicate records
					row_number() over ( partition by ud.user_document ->> 'user_id' order by ud.created_on_ts desc ) as rn1
				from
					staging.sc_user_document ud
				) ud
				left outer join
				( select
					  c.customer_email 			as user_email
					, c.industry 				as user_industry
					, c.region 					as user_region
					, c.company_name 			as user_company
					, row_number() over ( partition by c.customer_email order by c.created_on_ts desc ) as rn2
				from
					staging.crm_customer c
				) c
					on ud.user_email = c.user_email
					and c.rn2 = 1
				where
					ud.rn1 = 1
			) n
			-- check if current record exists and is identical
			left outer join
			only sc.sc_user sc
				on n.user_id = sc.user_id
		where
			--new record
			sc.user_id is null
			--or record as changed
			or sc.user_email 	!= n.user_email
			or sc.on_trial 		!= n.on_trial
			or sc.user_industry != n.user_industry
			or sc.user_region 	!= n.user_region
			or sc.user_company 	!= n.user_company
			or sc.signup_ts 	!= n.signup_ts
			or sc.active != n.active
		;
		--move changed records to history
		insert into sc.sc_user_hist (
			  user_id
			, user_email
			, on_trial
			, user_industry
			, user_region
			, user_company
			, signup_ts
			, active
			, effective_from_ts
			, effective_to_ts
			, created_on_ts
		)
		select
			  c.user_id
			, c.user_email
			, c.on_trial
			, c.user_industry
			, c.user_region
			, c.user_company
			, c.signup_ts
			, c.active
			, c.effective_from_ts
			, v_now
			, c.created_on_ts
		from
			only sc.sc_user c
			join
			sc_user_new n
				on c.user_id = n.user_id
		;
	 	--remove current records to table
	 	delete from only sc.sc_user where user_id in ( select user_id from sc_user_new ) ;
		--add new records to table
		insert into sc.sc_user (
			  user_id
			, user_email
			, on_trial
			, user_industry
			, user_region
			, user_company
			, signup_ts
			, active
			, effective_from_ts
		)
		select
			  n.user_id
			, n.user_email
			, n.on_trial
			, n.user_industry
			, n.user_region
			, n.user_company
			, n.signup_ts
			, n.active
			, n.effective_from_ts
		from
			sc_user_new n
		;
		drop table if exists sc_user_new ;
	end ;
$$ language plpgsql ;
