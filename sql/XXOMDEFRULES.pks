SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_DEFRULE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name  : XX_OM_DEFRULE_PKG                                         |
-- | RICE ID : E0205_DefaultingRule                                    |
-- | Description      : Package Specification containing for deriving  | 
-- |                    the values for the order header and line level |
-- |                    which will be used in the defautlting rules    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  | 
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   30-Mar-2007   Shashi Kumar.    Initial Draft version    |
-- |DRAFT 1B   10-May-2007   Shashi Kumar.    Changed the code to      |
-- |                                          modify the sales rep     |
-- |                                          to 'No Sales Credit      |
-- |1.0        16-May-2007   Shashi Kumar.    After internal review    |
-- +===================================================================+
AS

g_exception xxod_report_exception:= xxod_report_exception(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

-- +===================================================================+
-- | Name  : log_exceptions                                            |
-- | Description: This procedure s used to log the exceptions          |
-- |                                                                   |
-- | Parameters:                                                       |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_exceptions;

-- +===================================================================+
-- | Name  : get_price_list                                            |
-- | Description: This function is used to get the price list          |
-- |              currency.                                            |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns : price list id                                           |
-- |                                                                   |
-- +===================================================================+

FUNCTION get_price_list(
                        p_database_object_name  IN  VARCHAR2,
                        p_attribute_code        IN  VARCHAR2
                       ) RETURN NUMBER;

-- +===================================================================+
-- | Name  : get_warehouse                                             |
-- | Description: This function is used to get the warehouse ID        |
-- |              				                       |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns :    warehouse id                                         |
-- |                                                                   |
-- +===================================================================+

FUNCTION get_warehouse(
                       p_database_object_name  IN  VARCHAR2,
                       p_attribute_code        IN  VARCHAR2
                      ) RETURN NUMBER;

-- +===================================================================+
-- | Name  : get_shipmethod                                            |
-- | Description: This function is used to get the ship method         |
-- |              currency.                                            |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns : ship method id                                          |
-- |                                                                   |
-- +===================================================================+

FUNCTION get_shipmethod(
                        p_database_object_name  IN  VARCHAR2,
                        p_attribute_code        IN  VARCHAR2
                       ) RETURN VARCHAR2;   

-- +===================================================================+
-- | Name  : get_salesrep                                              |
-- | Description: This function is used to get the sales rep           |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns :    sales rep id                                         | 
-- |                                                                   |
-- +===================================================================+      

FUNCTION get_salesrep(
                      p_database_object_name  IN  VARCHAR2,
                      p_attribute_code        IN  VARCHAR2
                     ) RETURN NUMBER;                            

END XX_OM_DEFRULE_PKG;
/
SHOW ERRORS;
