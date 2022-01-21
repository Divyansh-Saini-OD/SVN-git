CREATE OR REPLACE FORCE VIEW "APPS"."AR_PAYING_RELATIONSHIPS_V" ("PARTY_ID", "RELATED_PARTY_ID", "RELATED_CUST_ACCOUNT_ID", "RELATIONSHIP_TYPE", "RELATIONSHIP_TYPE_GROUP_NAME", "EFFECTIVE_START_DATE", "EFFECTIVE_END_DATE")
AS
  SELECT
  DISTINCT gettop.child_id party_id ,
    relacc.party_id related_party_id ,
    relacc.cust_account_id related_cust_account_id ,
    hn.hierarchy_type ,
    'PARTY_REL_GRP_AR_PAY_ANY' relationship_type_group_name ,
    trunc(GREATEST(hn.effective_start_date, top.effective_start_date, gettop.effective_start_date)) effective_start_date ,
    trunc(LEAST(hn.effective_end_date, top.effective_end_date, gettop.effective_end_date, hn.effective_end_date)) effective_end_date
  FROM xx_hz_hierarchy_nodes_interim gettop ,
    xx_hz_hierarchy_nodes_interim top ,
    xx_hz_hierarchy_nodes_interim hn ,
    hz_cust_accounts relacc
  WHERE /** Get the Top parent/s for the given party for PayAny Hierarchies **/
      top.hierarchy_type          = gettop.hierarchy_type
  AND top.parent_id             = gettop.parent_id
  AND gettop.parent_table_name  = 'HZ_PARTIES'
  AND gettop.parent_object_type = 'ORGANIZATION'
  AND top.parent_table_name     = 'HZ_PARTIES'
  AND top.parent_object_type    = 'ORGANIZATION'
  AND top.top_parent_flag       = 'Y'
    /** Get all children for given account using Hierarchy Nodes **/
  AND hn.hierarchy_type     = top.hierarchy_type
  AND hn.parent_id          = top.parent_id
  AND hn.parent_table_name  = 'HZ_PARTIES'
  AND hn.parent_object_type = 'ORGANIZATION'
    /** Get Accounts for all children ***/
  AND hn.child_id          = relacc.party_id
  AND hn.child_table_name  = 'HZ_PARTIES'
  and HN.CHILD_OBJECT_TYPE = 'ORGANIZATION'
  AND hn.hierarchy_type = 'OD_FIN_PAY_WITHIN';