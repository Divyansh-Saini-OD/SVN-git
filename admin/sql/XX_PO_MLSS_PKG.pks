SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;      
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE; 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_MLSS_PKG                                                               
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_PO_MLSS_PKG                                      |
-- | Rice ID      :E1252_MultiLocationSupplierSourcing                 |
-- | Description  :This package specification is used to associate the |
-- |               MultiLocation Source name with the corresponding    |
-- |               Supplier Sourcing assignment record.                |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      17-MAR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      09-MAY-2007  Hema Chikkanna   Included the logic for      |
-- |                                       Insert/Updating the custom  |
-- |                                       od_mrp_supp_sr_assignment   |
-- |                                       Table                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

AS

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------

 ge_exception  xx_om_report_exception_t := xx_om_report_exception_t(
                                                                      'OTHERS'
                                                                     ,'OTC'
                                                                     ,'Pruchasing'
                                                                     ,'MLS Sourcing'
                                                                     ,NULL
                                                                     ,NULL
                                                                     ,NULL
                                                                     ,NULL
                                                                   );
                                                              
 
 
-- +===================================================================+
-- | Name  : Write_Exception                                           |
-- | Description : Procedure to log exceptions of MLSS objects using   |
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
                                  
                                  
                                  
-- +===================================================================+
-- | Name  : UPDATE_MLSS_MAIN                                          |
-- | Description:  This is the main procedure to update the custom ASL |
-- |               table with the MLSS Name                            |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_org_id                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE update_mlss_main(
                             x_errbuf    OUT VARCHAR2
                            ,x_retcode   OUT NUMBER
                            ,p_org_id    IN  NUMBER
                          );
       
END XX_PO_MLSS_PKG;
/

SHOW ERRORS

EXIT;