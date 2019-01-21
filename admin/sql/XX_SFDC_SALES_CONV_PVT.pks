-- $Id: XX_SFDC_SALES_CONV_PVT.pks 90515 2010-01-12 18:03:44Z Prasad Devar $
-- $Rev: 90515 $
-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XX_SFDC_SALES_CONV_PVT.pks $
-- $Author: Prasad Devar $
-- $Date: 2010-01-12 13:03:44 -0500 (Tue, 12 Jan 2010) $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
package XX_SFDC_SALES_CONV_PVT AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_SFDC_SALES_CONV_PVT                                                       |
-- | Description : Custom package for data migration.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        08-Apr-2009     Prasad Devar               Initial version                          |
-- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
-- +=========================================================================================+

 date_format      VARCHAR2(50) := 'MM/dd/yyyy HH:mm:ss';

  /*PROCEDURE insert_XX_CRM_EXP_LEAD (
    BATCH_ID                  NUMBER,
	ORACLE_ENTITY_ID          VARCHAR2,
	ENTITY_HDR_ID             VARCHAR2,
	NAME                      VARCHAR2,
	SOURCE_VALUE              VARCHAR2,
	STAGE                     VARCHAR2,
	PROBABILITY               VARCHAR2,
	CLOSEDATE                 VARCHAR2,
	CLOSE_REASON              VARCHAR2,
	CREATEDDATE               VARCHAR2,
	CREATEDBYID               VARCHAR2,
	LASTMODIFIEDDATE          VARCHAR2,
	LASTMODIFIEDBYID          VARCHAR2,
	STATUS                    VARCHAR2,
	SITE                      VARCHAR2,
	ACCOUNTID                 VARCHAR2,
	OWNERID                   VARCHAR2,
	OD_STORE_NUMBER           VARCHAR2,
	AMOUNT                    VARCHAR2,
	PRODUCT_CATEGORY          VARCHAR2,
	IMU                       VARCHAR2,
	SOURCE                    VARCHAR2,
	ORACLE_OPPORTUNITY_NUMBER VARCHAR2,
	PRIMARY_COMPETITOR        VARCHAR2,
	SECONDARY_COMPETITOR      VARCHAR2,
    x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );


  PROCEDURE insert_XX_CRM_EXP_OPPORTUNITY (
   BATCH_ID                  NUMBER,
	ORACLE_ENTITY_ID          VARCHAR2,
	ENTITY_HDR_ID              VARCHAR2,
	NAME                      VARCHAR2,
	SOURCE_VALUE              VARCHAR2,
	STAGE                     VARCHAR2,
	PROBABILITY               VARCHAR2,
	CLOSEDATE                 VARCHAR2,
	CLOSE_REASON              VARCHAR2,
	CREATEDDATE               VARCHAR2,
	CREATEDBYID               VARCHAR2,
	LASTMODIFIEDDATE          VARCHAR2,
	LASTMODIFIEDBYID          VARCHAR2,
	STATUS                    VARCHAR2,
	SITE                      VARCHAR2,
	ACCOUNTID                 VARCHAR2,
	OWNERID                   VARCHAR2,
	OD_STORE_NUMBER           VARCHAR2,
	AMOUNT                    VARCHAR2,
	PRODUCT_CATEGORY          VARCHAR2,
	IMU                       VARCHAR2,
	SOURCE                    VARCHAR2,
	ORACLE_OPPORTUNITY_NUMBER VARCHAR2,
	PRIMARY_COMPETITOR        VARCHAR2,
	SECONDARY_COMPETITOR      VARCHAR2,
   x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );

 PROCEDURE insert_XX_CRM_EXP_OPP_CONTACT (
  BATCH_ID                  NUMBER,
	ORACLE_ENTITY_ID          VARCHAR2,
	PRIMARY                   VARCHAR2,
	ROLE                      VARCHAR2,
	ORACLE_CONTACT_ID         VARCHAR2,
    x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );*/
PROCEDURE  insert_xx_crm_exp_assignment(
     BATCH_ID                  NUMBER,
	ORACLE_ENTITY_ID          VARCHAR2,
      ACCOUNT_TYPE               VARCHAR2,
	ACCOUNT_ID               VARCHAR2,
	PRIMARY_EMP_ID               VARCHAR2,
	PRIMARY_SPID               VARCHAR2,
	PRIMARY_RRLID              VARCHAR2,
	OVRLY_EMP_ID1               VARCHAR2,
	OVRLY_SPID1               VARCHAR2,
      OVRLY_EMP_ID2               VARCHAR2,
	OVRLY_SPID2               VARCHAR2,
      OVRLY_EMP_ID3               VARCHAR2,
	OVRLY_SPID3               VARCHAR2,
      OVRLY_EMP_ID4               VARCHAR2,
	OVRLY_SPID4               VARCHAR2,
      OVRLY_EMP_ID5               VARCHAR2,
	OVRLY_SPID5               VARCHAR2,
      OVRLY_EMP_ID6               VARCHAR2,
	OVRLY_SPID6               VARCHAR2,
      OVRLY_EMP_ID7               VARCHAR2,
	OVRLY_SPID7               VARCHAR2,
      OVRLY_EMP_ID8               VARCHAR2,
	OVRLY_SPID8               VARCHAR2,
      OVRLY_EMP_ID9               VARCHAR2,
	OVRLY_SPID9               VARCHAR2,
      OVRLY_EMP_ID10               VARCHAR2,
	OVRLY_SPID10               VARCHAR2,
      OSR                        VARCHAR2,
      ENTITY_TYPE              VARCHAR2,          
      OVRLY_EMP_ID11               VARCHAR2,
      OVRLY_SPID11               VARCHAR2, 
      OVRLY_EMP_ID12               VARCHAR2, 
      OVRLY_SPID12               VARCHAR2,
	OVRLY_EMP_ID13               VARCHAR2,
      OVRLY_SPID13               VARCHAR2,
	OVRLY_EMP_ID14               VARCHAR2,
      OVRLY_SPID14                VARCHAR2,
	OVRLY_EMP_ID15                VARCHAR2,
      OVRLY_SPID15                VARCHAR2,
OVRLY_EMP_ID21               VARCHAR2,
	OVRLY_SPID21               VARCHAR2,
      OVRLY_EMP_ID22               VARCHAR2,
	OVRLY_SPID22               VARCHAR2,
      OVRLY_EMP_ID23               VARCHAR2,
	OVRLY_SPID23               VARCHAR2,
      OVRLY_EMP_ID24               VARCHAR2,
	OVRLY_SPID24               VARCHAR2,
      OVRLY_EMP_ID25               VARCHAR2,
	OVRLY_SPID25               VARCHAR2,
      OVRLY_EMP_ID26               VARCHAR2,
	OVRLY_SPID26               VARCHAR2,
      OVRLY_EMP_ID27               VARCHAR2,
	OVRLY_SPID27               VARCHAR2,
      OVRLY_EMP_ID28               VARCHAR2,
	OVRLY_SPID28               VARCHAR2,
      OVRLY_EMP_ID29               VARCHAR2,
	OVRLY_SPID29               VARCHAR2,
      OVRLY_EMP_ID30               VARCHAR2,
	OVRLY_SPID30               VARCHAR2, 
OVRLY_EMP_ID16               VARCHAR2,
	OVRLY_SPID16               VARCHAR2,
      OVRLY_EMP_ID17               VARCHAR2,
	OVRLY_SPID17               VARCHAR2,
      OVRLY_EMP_ID18               VARCHAR2,
	OVRLY_SPID18              VARCHAR2,
      OVRLY_EMP_ID19               VARCHAR2,
	OVRLY_SPID19               VARCHAR2,
      OVRLY_EMP_ID20               VARCHAR2,
	OVRLY_SPID20            VARCHAR2,	
x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  )  ;

 /* PROCEDURE INSERT_XX_CRM_EXP_USER
  (
    p_user_record          IN    XXCRM.XX_CRM_EXP_USER%ROWTYPE,
    x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );

  PROCEDURE INSERT_XX_CRM_EXP_SPID
  (
    p_sp_record            IN    XXCRM.XX_CRM_EXP_SPID%ROWTYPE,
    x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );
PROCEDURE update_XX_CRM_EXP_LEAD (
      L_RECORD_ID                  NUMBER,
	L_OWNERID                   VARCHAR2,
	 x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );
 

PROCEDURE update_XX_CRM_EXP_OPPORTUNITY (
      L_RECORD_ID                  NUMBER,
	L_OWNERID                   VARCHAR2,
	 x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );
 -- Procedure for Store data Conversion
  PROCEDURE insert_xx_crm_exp_store
  (
    p_st_record            IN    xxcrm.xx_crm_exp_store%ROWTYPE,
    x_ret_status           OUT   VARCHAR2,
    x_ret_msg              OUT   VARCHAR2
  );*/

END XX_SFDC_SALES_CONV_PVT;
/

SHOW ERRORS;