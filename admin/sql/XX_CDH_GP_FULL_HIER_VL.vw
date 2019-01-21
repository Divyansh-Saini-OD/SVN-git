
CREATE OR REPLACE FORCE VIEW "APPS"."XX_CDH_GP_FULL_HIER_VL" ("RELATIONSHIP_ID", "GP_ID", "GP_NAME", "GP_PARTY_ID", "RESOURCE_ID", "ROLE_ID", "GROUP_ID", "OWNER", "SEGMENT", "REVENUE_BAND", "ATTRIBUTE1", "PARENT_ID", "PARENT_NAME", "PARENT_PARTY_ID", "CUSTOMER_ID", "CUSTOMER_NAME", "CUSTOMER_PARTY_ID") AS 
  SELECT g.relationship_id,
    gp.gp_id,
    gp.gp_name,
    gp.party_id,
    gp.resource_id,
    gp.role_id,
    gp.group_id,
    gp.legacy_rep_id owner,
    gp.segment,
    gp.revenue_band,
    gp.attribute1,
    DECODE(cust.orig_system_reference,NULL,NULL,SUBSTR(prnt.orig_system_reference,0,8)) parent_id,
    DECODE(cust.orig_system_reference,NULL,NULL,prnt.account_name) parent_name,
    DECODE(cust.orig_system_reference,NULL,NULL,prnt.party_id) parent_party_id,
    DECODE(cust.orig_system_reference,NULL,SUBSTR(prnt.orig_system_reference,0,8),SUBSTR(cust.orig_system_reference,0,8)) customer_id,
    DECODE(cust.orig_system_reference,NULL,prnt.account_name,cust.account_name) customer_name,
    DECODE(cust.orig_system_reference,NULL,prnt.party_id,cust.party_id) customer_party_id
  FROM HZ_RELATIONSHIPS P,
       HZ_RELATIONSHIPS G,
       hz_cust_accounts prnt,
       hz_cust_accounts cust,
       xx_cdh_gp_master gp
  WHERE gp.party_id          = g.subject_id(+)
  AND prnt.party_id(+)       = g.object_id
  AND cust.party_id(+)       = p.object_id
  AND G.OBJECT_ID            = P.SUBJECT_ID(+)
  AND P.RELATIONSHIP_TYPE(+) = 'OD_CUST_HIER'
  AND P.RELATIONSHIP_CODE(+) = 'PARENT_COMPANY'
  AND P.DIRECTION_CODE(+)    = 'P'
  AND G.RELATIONSHIP_TYPE(+)    = 'OD_CUST_HIER'
  AND G.RELATIONSHIP_CODE(+)    = 'GRANDPARENT'
  AND (SYSDATE BETWEEN nvl(g.START_DATE,sysdate) AND NVL(g.END_DATE,SYSDATE)
  OR g.START_DATE > SYSDATE)
  AND g.status(+) = 'A'
  AND (SYSDATE BETWEEN NVL(p.start_date,SYSDATE) AND NVL(p.END_DATE,SYSDATE)
  OR NVL(p.START_DATE,SYSDATE+1) > SYSDATE)
  AND p.status(+) = 'A'
  AND G.DIRECTION_CODE(+)                  = 'P';
 
