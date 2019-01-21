create materialized view log on ar.hz_parties
with rowid, primary key, sequence(party_type, status, last_update_date)
including new values;


create materialized view log on ar.hz_party_sites
with rowid, primary key, sequence(party_id, location_id, status, last_update_date)
including new values;


create materialized view log on ar.hz_locations with rowid, primary key, sequence(last_update_date)
including new values;


create materialized view log on ar.hz_party_sites_ext_b
with rowid, primary key, sequence(party_site_id, attr_group_id, n_ext_attr1, last_update_date)
including new values;


create materialized view log on ar.hz_cust_accounts
with rowid, primary key, sequence(party_id, status, attribute18, customer_type, last_update_date)
including new values;


create materialized view log on ar.hz_cust_acct_sites_all
with rowid, primary key, sequence(org_id, party_site_id, cust_account_id, status, last_update_date)
including new values;


create materialized view log on ar.hz_party_site_uses
with rowid, primary key, sequence(party_site_id, site_use_type, status, last_update_date)
including new values;


create materialized view log on ar.hz_hierarchy_nodes
with rowid, sequence(hierarchy_type,level_number,parent_id, child_id,
         parent_object_type,child_object_type,
         parent_table_name,child_table_name,effective_start_date,
         effective_end_date,status, last_update_date
        )
including new values;


create materialized view log on ar.ra_terms_b
with rowid, primary key, sequence(attribute1, attribute2, last_update_date)
including new values;


create materialized view log on ar.ra_terms_tl
with rowid, primary key, sequence(name, description, last_update_date)
including new values;


create materialized view log on ar.hz_customer_profiles
with rowid, primary key, sequence(cust_account_id, status, standard_terms, site_use_id, attribute3, 
                                  collector_id, account_status, last_update_date
                                 )
including new values;



CREATE MATERIALIZED VIEW LOG ON ar.hz_code_assignments
WITH rowid, primary key, 
     sequence(owner_table_name, owner_table_id, class_category, 
              class_code, start_date_active, end_date_active, last_update_date)
including new values;



CREATE MATERIALIZED VIEW LOG ON "AR"."HZ_RELATIONSHIPS"
  TABLESPACE "APPS_TS_TX_DATA" 
  WITH PRIMARY KEY, ROWID, SEQUENCE ( "END_DATE", "LAST_UPDATE_DATE", "STATUS", "SUBJECT_ID", "SUBJECT_TYPE" ,"OBJECT_ID", "OBJECT_TYPE", "PARTY_ID") 
including new values;

CREATE MATERIALIZED VIEW LOG ON "AR"."HZ_CUST_ACCOUNT_ROLES"
  TABLESPACE "APPS_TS_TX_DATA" 
  WITH PRIMARY KEY, ROWID, SEQUENCE ( "CURRENT_ROLE_STATE", "CUST_ACCOUNT_ID", "CUST_ACCT_SITE_ID", "END_DATE", "LAST_UPDATE_DATE", "ORIG_SYSTEM_REFERENCE", "PARTY_ID", "PRIMARY_FLAG", "ROLE_TYPE", "STATUS" )
including new values;

CREATE MATERIALIZED VIEW LOG ON "AR"."HZ_CONTACT_POINTS"
  TABLESPACE "APPS_TS_TX_DATA" 
  WITH PRIMARY KEY, ROWID, SEQUENCE ( "LAST_UPDATE_DATE", "OWNER_TABLE_ID", "OWNER_TABLE_NAME", "STATUS" ) 
including new values;

CREATE MATERIALIZED VIEW LOG ON "AR"."HZ_ORG_CONTACTS"
WITH PRIMARY KEY, ROWID, SEQUENCE ( "LAST_UPDATE_DATE", "PARTY_RELATIONSHIP_ID" ) INCLUDING NEW VALUES;



