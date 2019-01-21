SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_TM_SETUP_RSC_ASSIGNMENT_PKG AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_TM_SETUP_RSC_ASSIGNMENT_PKG                                    |
-- |                                                                                |
-- | Description:  This procedure provides the statistics on Territory assignment . |
-- |               for the Setup Resource.
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 14-Jul-2009 Sarah Maria Justina        Initial draft version           |
-- +================================================================================+
    -- -------------------------------------
    -- Setup Assignments PL/SQL Record
    -- -------------------------------------

    TYPE xx_setup_asgn_rec IS RECORD   ( CUSTOMER_PROSPECT     VARCHAR2 (150) 
					,PARTY_SITE_ID         NUMBER (15) 
					,PARTY_SITE_NUMBER     VARCHAR2 (30) 
					,ORIG_SYSTEM_REFERENCE VARCHAR2 (240) 
					,PARTY_NAME            VARCHAR2 (360) 
					,ADDRESS               VARCHAR2 (30) 
					,START_DATE_ACTIVE     DATE 
					,END_DATE_ACTIVE       DATE 
					,RESOURCE_ID           NUMBER
					,RESOURCE_NAME         VARCHAR2 (360)
					,LEGACY_REP_ID         VARCHAR2 (150));
    -- -------------------------------------
    -- Setup Assignments PL/SQL Table Type
    -- -------------------------------------
					
   TYPE xx_setup_asgn_tbl IS TABLE OF xx_setup_asgn_rec
      INDEX BY BINARY_INTEGER;					
-- +===========================================================================================================+
-- | Name        :  MAIN
-- | Description:  This package provides the statistics on Territory assignment .   
-- |               for the Setup Resource.                                          
-- | Parameters  :  x_errbuf           OUT   VARCHAR2,
-- |                x_retcode          OUT   NUMBER,
-- |                p_start_datetime         VARCHAR2
-- |                p_end_datetime           VARCHAR2  
-- +===========================================================================================================+
   PROCEDURE MAIN (
      x_errbuf           OUT   VARCHAR2,
      x_retcode          OUT   NUMBER,
      p_start_datetime         VARCHAR2,
      p_end_datetime           VARCHAR2    
   );

END XX_TM_SETUP_RSC_ASSIGNMENT_PKG;
/

SHOW ERRORS
EXIT;