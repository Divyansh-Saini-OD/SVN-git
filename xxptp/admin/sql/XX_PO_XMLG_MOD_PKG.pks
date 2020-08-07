
SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_XMLG_MOD_PKG AUTHID CURRENT_USER
-- +===================================================================+                            
-- |                  Office Depot - Project Simplify                  |                            
-- |      Oracle NAIO/Office Depot/Consulting Organization             |                            
-- +===================================================================+                            
-- | Name       : XX_PO_XMLG_MOD_PKG.pks                               |                            
-- | Description: This package is used to select all the PO, which     |                            
-- |got revision less updation.This package also raises the poxml      |                            
-- |event for the corrosponding PO's using standard package proc.      |                            
-- |PO_XML_UTILS_GRP.REGENANDSEND and generates XML file for the same. |                            
-- |                                                                   |                            
-- |                                                                   |                            
-- |Change Record:                                                     |                            
-- |===============                                                    |                            
-- |Version   Date        Author           Remarks                     |                            
-- |=======   ==========  =============    ============================|                            
-- |DRAFT 1A 08-MAR-2007  Seemant Gour     Initial draft version       |
-- |DRAFT 1b 28-APR-2007  Vikas Raina      Updated after review        |
-- |1.0      03-MAY-2007  Seemant Gour     Baseline for Release        |
-- +===================================================================+                            
                                                                                                    
AS                                                                                                  
-- +====================================================================+                           
-- | Name         : GET_UPDATED_PO                                      |                           
-- | Description  : This procedure selects the headers and lines details|                           
-- | for all the inscope PO's which are revision less modified for all  |                           
-- | APPROVED purchase orders.                                          |                           
-- |                                                                    |                           
-- |                                                                    |                           
-- | Parameters   : x_err_buf    OUT  VARCHAR2  Error Message           |                           
-- |                x_retcode    OUT  NUMBER    Error Code              |                           
-- |                                                                    |                           
-- |                                                                    |                           
-- | Returns      : None                                                |                           
-- +====================================================================+                           
                                                                                                    
   PROCEDURE GET_UPDATED_PO(                                                                        
                            x_err_buf      OUT   VARCHAR2                                           
                          , x_retcode      OUT   NUMBER                                             
                           );                                                                       
                                                                                                    
-- +====================================================================+                           
-- | Name         : INVOKE_POXML_WF_PROCESS                             |                           
-- | Description  : This procedure calls to the standard package        |                           
-- | procedure to raise poxml event for the POXML workflow.             |                           
-- |                                                                    |                           
-- |                                                                    |                           
-- | Parameters   : p_po_header_id       IN NUMBER                      |                           
-- |                p_po_type            IN VARCHAR2                    |                           
-- |                p_po_revision        IN NUMBER                      |                           
-- |                p_user_id            IN NUMBER                      |                           
-- |                                                                    |                           
-- |                                                                    |                           
-- |                                                                    |                           
-- | Returns      :     None                                            |                           
-- +====================================================================+                           
                                                                                                    
   PROCEDURE INVOKE_POXML_WF_PROCESS (p_po_header_id       IN NUMBER                                
                                    , p_po_type            IN VARCHAR2                              
                                    , p_po_revision        IN NUMBER                                
                                    , p_user_id            IN NUMBER                                
                                    );                                                              
                                           
END XX_PO_XMLG_MOD_PKG;
/
SHOW ERRORS;

EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================

