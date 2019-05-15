# wait for database to go online
sleep 5
# connect to database
PGPASSWORD=postgres psql -h postgres -U postgres postgres << EOF
\i schema.sql
\set content `cat /data/sc_data.json`
create temp table t ( j json );
insert into t values (:'content');
insert into staging.sc_user_document select value as user_document from json_array_elements((select j from t limit 1)) ;
drop table t ;
\copy staging.crm_customer(customer_email,industry,region,company_name) FROM '/data/crm_data.csv' DELIMITER ',' CSV HEADER;
select sc.load_sc_user () ;
EOF
