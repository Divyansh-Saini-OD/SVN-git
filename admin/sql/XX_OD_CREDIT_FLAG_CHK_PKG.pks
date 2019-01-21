SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_UPDATE_CUST_PROFILE_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE  XX_OD_CREDIT_FLAG_CHK_PKG
 AS
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_CREDIT_FLAG_CHK_PKG                                   |
-- | Description :                                                             |
-- | This package helps us to check if AOPS A/R credit flag and attribute3 of  |
-- | hz_customer_profiles are in synch and outputs the mismatch records as     | 
-- | output flag and type.                                                     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 15-JUN-2010 Renupriya     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+
 

   PROCEDURE XX_OD_CREDIT_FLAG_CHK_MAIN (
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_CREDIT_FLAG_CHK_PROC                                  |
-- | Description :                                                             |
-- | This is the main procedure which calls 2 procedures: 1) Procedure to      |
-- | populate the custom table with AOPS data from csv file and 2)Procedure    |
-- | to check if AOPS credit flag and attribute3 in CDH are in synch.          |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-JUN-2010 Renupriya     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+
     
    p_errbuf      OUT   VARCHAR2
    ,p_retcode     OUT   NUMBER
    ,p_file_name   IN    VARCHAR2);

PROCEDURE XX_OD_CREDIT_FLAG_TEMP_LOAD(

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_CREDIT_FLAG_TEMP_LOAD                                 |
-- | Description :                                                             |
-- | This procedure is to load the AOPS csv data into the custom table         |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-JUN-2010 Renupriya     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+
    p_file_name   IN   VARCHAR2
   ,x_retcode     OUT  NUMBER
   ,x_retmsg      OUT  VARCHAR2); 
  
PROCEDURE XX_OD_CREDIT_FLAG_CHK_PROC(

-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_CREDIT_FLAG_CHK_PROC                                  |
-- | Description :                                                             |
-- | This procedure helps us to check if AOPS A/R credit flag and attribute3   |
-- | of hz_customer_profiles are in synch and outputs the mismatch records as  | 
-- | output flag and type.                                                     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-JUN-2010 Renupriya     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+

   x_retcode   OUT  NUMBER,
   x_retmsg    OUT  VARCHAR2); 

END XX_OD_CREDIT_FLAG_CHK_PKG;

/
SHOW ERROR;