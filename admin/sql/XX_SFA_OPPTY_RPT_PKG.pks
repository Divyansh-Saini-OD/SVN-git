SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_SFA_OPPTY_RPT_PKG AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_SFA_OPPTY_RPT_PKG                                              |
-- |                                                                                |
-- | Description:  This procedure prints all the Opportunities in the system.       |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A  09-FEB-2010 Sarah Maria Justina        Initial draft version          |
-- |DRAFT 1   19-APR-2010 Nabarun                    Added IMU%                     |
-- |DRAFT 1.1 28-APR-2010 Nabarun                    Modified the approach to derive| 
-- |                                                 the DSM/RSD/VP name            |
-- |DRAFT 2   11-NOV-2010 Devi Viswanathan           Fix for defect 8062.           | 
-- |DRAFT 3   24-JAN-2011 Parameswarn S N            Fix for defect 9794            |
-- +================================================================================+
       TYPE xx_sfa_oppty_type IS RECORD
       (    
         CREATED_BY_ID       NUMBER
        ,LEAD_ID             NUMBER
        ,EMPLOYEE_ID         VARCHAR2 (4000) -- Defect 8062 Changed data type from NUMBER to VARCHAR2(4000)
	,CREATED_BY          VARCHAR2 (360) 
	,CREATION_DATE       DATE 
	,OPP_NUMBER          VARCHAR2 (30) 
	,OPP_NAME            VARCHAR2 (240) 
	,CUSTOMER_ID         NUMBER
	,PARTY_NAME          VARCHAR2 (360) 
	,PARTY_NUMBER        NUMBER --Added for defect# 9794
	,PARTY_SITE_NUMBER   NUMBER --Added for defect# 9794
	,PROSPECT_CUSTOMER   VARCHAR2 (150) 
	,ADDRESS_ID          NUMBER
	,ADDRESS             VARCHAR2 (4000) 
	,SOURCE_PROMOTION_ID NUMBER
	,SOURCE              VARCHAR2 (240) 
	,TOTAL_AMOUNT        NUMBER
	 --Defect-4999 , Added IMU_PERCENTAGE by Nabarun, 19-Apr-2010 
	,IMU_PERCENTAGE      VARCHAR2 (4000) -- Defect 8062 Changed data type from NUMBER to VARCHAR2(4000) 
	,WIN_PROBABILITY     NUMBER
	,LAST_UPDATE_DATE    DATE 
	,CLOSE_DATE          DATE 
	,STATUS              VARCHAR2 (30) 
	,CLOSE_REASON        VARCHAR2 (30) 
	,OPP_PRIMARY_CONTACT VARCHAR2 (360) 
	,PRODUCT_CATEGORY    VARCHAR2 (240) 
	,COMPETITOR_NAME     VARCHAR2 (360) 
        ,STATUS_CATEGORY     VARCHAR2 (8)
	,SALESPERSONEMPID    NUMBER
	,SALESPERSON         VARCHAR2 (360) 
	,SALESREP_ROLE       VARCHAR2 (60) 
	,SALESREP_GROUP      VARCHAR2 (60) 
	,SOURCE_ID           NUMBER
	,DSM_NAME            VARCHAR2 (360) 
	,RSD_NAME            VARCHAR2 (360) 
	,VP_NAME             VARCHAR2 (360) 
       );
       
   TYPE xx_sfa_oppty_tbl_type IS TABLE OF xx_sfa_oppty_type
      INDEX BY BINARY_INTEGER;
      
  TYPE xx_sfa_oppty_details IS RECORD
       (    
         lead_id             NUMBER
        ,lead_number         VARCHAR2 (240) 
       );
       
   TYPE xx_sfa_oppty_details_t IS TABLE OF xx_sfa_oppty_details
      INDEX BY BINARY_INTEGER;    
      

FUNCTION Get_DSM_RSD_VP ( 
                          p_group_id IN NUMBER
                         ,p_name     IN VARCHAR2
                         ,p_asgn_source_id IN NUMBER
                        )
RETURN VARCHAR2;

   PROCEDURE report_main (
      x_errbuf       OUT   VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_close_date         VARCHAR2 DEFAULT NULL,
      p_create_date        VARCHAR2 DEFAULT NULL,      
      p_status             VARCHAR2 DEFAULT NULL,
      p_status_cat         VARCHAR2 DEFAULT NULL
   );
END XX_SFA_OPPTY_RPT_PKG;
/
SHOW ERRORS;