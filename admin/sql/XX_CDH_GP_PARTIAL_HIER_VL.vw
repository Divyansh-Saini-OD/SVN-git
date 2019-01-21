  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CDH_GP_PARTIAL_HIER_VL" ("RELATIONSHIP_ID", "GP_ID", "GP_NAME", "GP_PARTY_ID", "RESOURCE_ID", "ROLE_ID", "GROUP_ID", "OWNER", "SEGMENT", "REVENUE_BAND", "ATTRIBUTE1", "PARENT_ID", "PARENT_NAME", "PARENT_PARTY_ID", "CUSTOMER_ID", "CUSTOMER_NAME", "CUSTOMER_PARTY_ID") AS 
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
    SUBSTR(prnt.orig_system_reference,0,8) parent_id,
    prnt.account_name parent_name,
    prnt.party_id parent_party_id,
    NULL customer_id,
    NULL customer_name,
    NULL customer_party_id
   FROM HZ_RELATIONSHIPS G,
        xx_cdh_gp_master gp,
        hz_cust_accounts prnt
  WHERE G.SUBJECT_ID(+)      = gp.party_id
  AND g.object_id         = prnt.party_id(+)
  AND G.RELATIONSHIP_TYPE(+) = 'OD_CUST_HIER'
  AND G.RELATIONSHIP_CODE(+) = 'GRANDPARENT'
  AND (SYSDATE BETWEEN nvl(g.START_DATE,sysdate) AND NVL(g.END_DATE,SYSDATE)
  OR g.START_DATE > SYSDATE)
  AND G.DIRECTION_CODE(+)   = 'P'
  AND g.status(+)           = 'A'
  AND EXISTS
    (SELECT 'Y'
    FROM  hz_relationships
    WHERE subject_id      = g.object_id
    AND RELATIONSHIP_TYPE = 'OD_CUST_HIER'
    AND RELATIONSHIP_CODE = 'PARENT_COMPANY'
    AND (SYSDATE BETWEEN START_DATE AND NVL(END_DATE,SYSDATE)
    OR START_DATE > SYSDATE)
    AND DIRECTION_CODE   = 'P'
    AND status           = 'A'
    )
  UNION ALL
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
    NULL parent_id,
    NULL parent_name,
    NULL parent_party_id,
    SUBSTR(prnt.orig_system_reference,0,8) customer_id,
    prnt.account_name customer_name,
    prnt.party_id customer_party_id
  FROM HZ_RELATIONSHIPS G,
       xx_cdh_gp_master gp,
       hz_cust_accounts prnt
  WHERE G.SUBJECT_ID(+)      = gp.party_id
  AND g.object_id         = prnt.party_id(+)
  AND G.RELATIONSHIP_TYPE(+) = 'OD_CUST_HIER'
  AND G.RELATIONSHIP_CODE(+) = 'GRANDPARENT'
  AND (SYSDATE BETWEEN nvl(g.START_DATE,SYSDATE) AND NVL(g.END_DATE,SYSDATE)
  OR g.START_DATE > SYSDATE)
  AND G.DIRECTION_CODE(+)   = 'P'
  AND g.status(+)           = 'A'
  AND NOT EXISTS
    (SELECT 'Y'
    FROM hz_relationships
    WHERE subject_id      = g.object_id
    AND RELATIONSHIP_TYPE = 'OD_CUST_HIER'
    AND RELATIONSHIP_CODE = 'PARENT_COMPANY'
    AND (SYSDATE BETWEEN START_DATE AND NVL(END_DATE,SYSDATE)
    OR START_DATE > SYSDATE)
    AND DIRECTION_CODE   = 'P'
    AND status           = 'A'
    );
 
