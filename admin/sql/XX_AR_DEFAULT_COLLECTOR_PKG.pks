SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_AR_DEFAULT_COLLECTOR_PKG
PROMPT Program exits IF the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_AR_DEFAULT_COLLECTOR_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_DEFAULT_COLLECTOR_PKG                                  |
-- | RICE ID :  R0528                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: AR Default Collector  |
-- |              report with the desirable format of the user, and the  |
-- |              default format is EXCEL                                |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  02-JAN-09      Jennifer Jegam         Initial version      |
-- |Draft 1B  10-FEB-09      Kantharaja    Fixed for defect 11568(added  | 
-- |                                       level number condition)       |                                                                    |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_AR_DEFAULT_COLLECTOR_PROC                                |
-- | Description : The procedure will submit the OD: AR Default Collector|
-- |               report in the specified format                        |
-- | Parameters : p_collectorid, p_termid                                |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_AR_DEFAULT_COLLECTOR_PROC(
                                          x_err_buff       OUT VARCHAR2
                                         ,x_ret_code       OUT NUMBER
				                 ,p_collectorid    IN NUMBER
				                 ,p_termid         IN NUMBER
                                          );


 -- +=====================================================================+
-- | Name :  XX_AR_DEFAULT_COLLECTOR_PROC                                |
-- | Description : The procedure will do the necessary validations and   |
-- |               and processings needed for the report OD: AR          |
-- |		   Default Collector                                         |
-- |                                                                     |
-- | Parameters :  p_collectorid, p_termid                               |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_AR_DEF_COL_INSERT_PROCEDURE(
                                          p_collectorid     IN NUMBER
				                 ,p_termid          IN NUMBER
				          );

END XX_AR_DEFAULT_COLLECTOR_PKG;
/
 SHO ERR;