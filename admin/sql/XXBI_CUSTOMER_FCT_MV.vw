-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW APPS.XXBI_CUSTOMER_FCT_MV
  BUILD DEFERRED
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUSTOMER_FCT_MV.vw                            |
-- | Description :  Customers Fact MV                                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT 
        c.ACCESS_ID,
	c.PARTY_ID,
	c.PARTY_NUMBER,
	c.PARTY_NAME,
	c.PARTY_ORIG_SYSTEM_REFERENCE,
	c.PARTY_SITE_ID,
	c.PARTY_SITE_NUMBER,
	c.SITE_ORIG_SYSTEM_REFERENCE,
	c.CUST_CREATE_DATE,
	c.RESOURCE_ID,
	c.GROUP_ID,
	c.ROLE_ID,
	c.GRAND_PARENT_NAME,
	c.GRAND_PARENT_PARTY_ID,
	c.PARENT_NAME,
	c.PARENT_PARTY_ID,
	c.IDENTIFYING_ADDRESS_FLAG,
	c.ADDRESS1,
	c.ADDRESS2,
	NVL(c.CITY,'XX') CITY,
	NVL(c.STATE,'XX') STATE,
	NVL(c.PROVINCE,'XX') PROVINCE,
	NVL(c.POSTAL_CODE,'XX') POSTAL_CODE,
	c.COUNTRY,
	c.DUNS_NUMBER,
	NVL(c.SIC_CODE,'XX') SIC_CODE,
	c.WCW,
	c.OD_WCW,
	c.ACCT_FLAG,
	c.CHANNEL,
	c.SITE_USE,
       DECODE(P.Attribute_Category || '-' || P.ATTRIBUTE24,'-','XX',P.Attribute_Category || '-' || P.ATTRIBUTE24) REVENUE_BAND,   
       NVL(SUBSTR(site_orig_system_reference,0,8),'P'||p.party_number) AOPS_NUMBER,      
       DECODE(C.acct_flag,'Y',SUBSTR(site_orig_system_reference,0,8),NULL) LEGACY_ACCOUNT_NUM,
       DECODE(C.acct_flag,'Y',SUBSTR(site_orig_system_reference,10,5),NULL) LEGACY_SITE_SEQ,
       CASE WHEN c.country = 'US' THEN 
                          c.address1
                          || '.'
                          || c.address2
                          || '.'
                          || c.city
                          || '.'
                          || c.state
                          || '.'
                          || c.postal_code
       WHEN c.country = 'CA' THEN
                          c.address1
                          || '.'
                          || c.address2
                          || '.'
                          || c.city
                          || '.'
                          || c.province
                          || '.'
                          || c.postal_code
        END  formatted_address,
       NVL(DECODE(C.country,'CA',C.province,c.state),'XX') STATE_PROVINCE,
       DECODE(C.acct_flag,'Y','C',DECODE(C.PARTY_CODE,'CUSTOMER','I','P')) customer_type,
       DECODE(DECODE(C.acct_flag,'Y','C',DECODE(C.PARTY_CODE,'CUSTOMER','I','P')),'P',TRUNC(SYSDATE)-TRUNC(P.creation_date),TRUNC(SYSDATE)-TRUNC(c.cust_create_date)) age,
       lkup_age.lookup_code AGE_BUCKET,
       lkup_wcw.lookup_code WCW_RANGE, 
       DECODE(c.identifying_address_flag,'Y',1,0)  party_count_val
FROM XXTPS_CURRENT_ASSIGNMENTS_MV C, HZ_PARTIES P, FND_LOOKUP_VALUES lkup_age, FND_LOOKUP_VALUES lkup_wcw
WHERE C.PARTY_ID = P.PARTY_ID
AND lkup_age.lookup_type = 'XXBI_CUSTOMER_AGE_BUCKET'
AND lkup_wcw.lookup_type = 'XXBI_CUST_WCW_RANGE'
AND NVL(NVL(c.od_wcw,c.wcw),0) BETWEEN substr(lkup_wcw.tag,0,instr(lkup_wcw.tag,'-')-1) AND substr(lkup_wcw.tag,instr(lkup_wcw.tag,'-')+1,LENGTH(lkup_wcw.tag))
AND DECODE(DECODE(C.acct_flag,'Y','C',DECODE(C.PARTY_CODE,'CUSTOMER','I','P')),'P',TRUNC(SYSDATE)-TRUNC(P.creation_date),TRUNC(SYSDATE)-TRUNC(c.cust_create_date)) 
    BETWEEN substr(lkup_age.tag,0,instr(lkup_age.tag,'-')-1) AND substr(lkup_age.tag,instr(lkup_age.tag,'-')+1,LENGTH(lkup_age.tag));

----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON APPS.XXBI_CUSTOMER_FCT_MV TO XXCRM;

SHOW ERRORS;
EXIT;