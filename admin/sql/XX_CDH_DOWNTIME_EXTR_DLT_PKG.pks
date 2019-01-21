SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_DOWNTIME_EXTR_DLT_PKG
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_DOWNTIME_EXTR_DLT_PKG                                              |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   27-May-2013     Sreedhar Mohan       Initial draft version                    |
-- |1.1        05-Jan-2016     Manikant Kasu        Removed schema alias as part of GSCC     | 
-- |                                                R12.2.2 Retrofit                         |
-- +=========================================================================================+

AS
 --Procedure for extracting TDS Customer in the source system                                                                                                                                                                                                                                                                                                                                                                                                                                                     
  --into a staging table                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
 PROCEDURE EXTRACT_TDS_CUSTOMER(errbuf  OUT NOCOPY VARCHAR2                                                                                                                                                                                                                                                                                                                                                                                                                                                         
                              , retcode OUT NOCOPY VARCHAR2);  
  --Procedure for extracting Org_Cust_BO in the source system
  --into a staging table
 PROCEDURE EXTRACTCUSTOMERBO(errbuf  OUT NOCOPY VARCHAR2
                           , retcode OUT NOCOPY VARCHAR2);

  --Procedure for extracting Customer Data in the source system
  --into existing CDH staging tables
 PROCEDURE extractCustomer  (errbuf  OUT NOCOPY VARCHAR2
                           , retcode OUT NOCOPY VARCHAR2);

 PROCEDURE CLEANUP_STAGING(errbuf  OUT NOCOPY VARCHAR2
                         , retcode OUT NOCOPY VARCHAR2
                         , p_time  IN         VARCHAR2);

END XX_CDH_DOWNTIME_EXTR_DLT_PKG;
/

