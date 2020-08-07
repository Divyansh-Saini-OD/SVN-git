SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_CE_TMS_JE_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE  XX_CE_TMS_JE_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name :  XX_CE_TMS_JE_PKG                                                 |
-- | Description :  This package is used to create Journal entry              |
-- |                with the help of translation codes and                    |
-- |                CE headers and lines data                                 |
-- | RICEID      :  I2197 TR Automated Journal Entries                        |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |1.0       31-Mar-2017    praveen vanga       Initial version              |
-- |                                                                          |
-- +==========================================================================+


-- Global Variables
G_Batch_Name     Varchar2(50):='OD CM Treasury 2';
G_Journal_Name   Varchar2(50):='OD CM Treasury 2';
G_Category_Name  Varchar2(50):='ODP Treasury';
G_Je_Source_Name VARCHAR2(50):='OD CM Treasury 2';
 

PROCEDURE MAIN(X_ERRBUF          OUT NOCOPY      VARCHAR2
              ,X_RETCODE         OUT NOCOPY      NUMBER
      		  ,P_REPROCESS      VARCHAR2
              ,P_REPROCESS_DATE VARCHAR2);

			  
END XX_CE_TMS_JE_PKG;
/
show error
