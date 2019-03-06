SET SHOW          OFF; 
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_PIP_ERROR_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name  : XX_OM_PIP_ERROR_PKG.pks                                   |
-- | Rice ID      :E1259_PIPCampaignDefinition                         |
-- | Description      : This pacakge will be used in the PIP Campaign  |
-- |                    forms. This is the package specification       |
-- |                    containing the procedures to insert the error  |
-- |                    in Global exception handling Table.            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   11-Mar-2007   Neeraj R.        Initial draft version    |
-- |1.0        17-MAR-2007   Hema Chikkanna   Baselined after testing  |
-- |1.1        27-APR-2007   Hema Chikkanna   Updated the Comments     |
-- |                                          Section as per onsite    |
-- |                                          requirement              |
-- |1.2        14-JUN-2007   Hema Chikkanna   Incorporated the file    |
-- |                                          name change as per onsite|
-- |                                          requirement              |
-- +===================================================================+

AS

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------

 ge_exception  xx_om_report_exception_t := xx_om_report_exception_t(
                                                                     'OTHERS'
                                                                     ,'OTC'
                                                                     ,'Order Management'
                                                                     ,'PIP Campaign Definition'
                                                                     ,NULL
                                                                     ,NULL
                                                                     ,NULL
                                                                     ,NULL
                                                                   );
                                                              
 
-- +===================================================================+
-- | Name  : Write_Exception                                           |
-- | Description : Procedure to log exceptions from the PIP forms using|
-- |               the Common Exception Handling Framework             |
-- |                                                                   |
-- | Parameters :    p_error_code                                      |
-- |                 p_error_description                               |
-- |                 p_entity_reference                                |
-- |                 p_entity_ref_id                                   |
-- | Returns    :                                                      |
-- |                                                                   |
-- +===================================================================+

 PROCEDURE write_exception ( 
                             p_error_code            IN VARCHAR2,
                             p_error_description     IN VARCHAR2,                          
                             p_entity_reference      IN VARCHAR2,
                             p_entity_ref_id         IN NUMBER
                           );  
END XX_OM_PIP_ERROR_PKG;

/

SHOW ERRORS

EXIT;