SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_INV_ITEM_XREF_PKG AUTHID CURRENT_USER

-- +======================================================================+
-- |                  Office Depot - Project Simplify                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization          |
-- +======================================================================+
-- | Name        :  XX_INV_ITEM_XREF_PKG.pks                              |
-- | Description :  To create/update/delete Item/product/Wholesaler cross |
-- |                reference values in EBS                               |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date        Author           Remarks                        |
-- |=======   ==========  =============    ===============================|
-- |Draft 1a  11-Apr-2007 Madhukar Salunke Initial draft version          |
-- |Draft 1b  18-May-2007 Madhukar Salunke Incorporated as per latest MD70|
-- |Draft 1c  11-Jun-2007 Madhukar Salunke Incorporated peer review comments|
-- |Draft 1d  12-JUN-2007 Jayshree kale    Reviewed and Updated           | 
-- |Draft 1e  14-JUN-2007 Jayshree kale    Updated as per onsite comments | 
-- |Draft 1f  16-JUN-2007 Madhukar Salunke Updated as per onsite comments | 
-- |Draft 1g  20-JUN-2007 Madhukar Salunke Updated as per onsite comments | 
-- |Draft 1h  09-JUL-2007 Madhukar Salunke Added Global variables         | 
-- |1.0       10-JUL-2007 Madhukar Salunke Baseline                       | 
-- +======================================================================+
IS

--+=======================================================================+
--| PROCEDURE  : Process_item_xref                                        |
--| p_xref_object          IN    VARCHAR2                                 |
--| p_item                 IN    VARCHAR2                                 |
--| p_action               IN    VARCHAR2                                 |
--| p_xref_item            IN    VARCHAR2                                 |
--| p_xref_type            IN    VARCHAR2                                 |
--| p_prodmultiplier       IN    NUMBER                                   |
--| p_prodmultdivcd        IN    VARCHAR2                                 |
--| p_prdxrefdesc          IN    VARCHAR2                                 |
--| p_whslrsupplier        IN    NUMBER                                   |
--| p_whslrmultiplier      IN    NUMBER                                   |
--| p_whslrmultdivcd       IN    VARCHAR2                                 |
--| p_whslrretailprice     IN    NUMBER                                   |
--| p_whslruomcd           IN    VARCHAR2                                 |
--| p_whslrprodcategory    IN    VARCHAR2                                 |
--| p_whslrgencatpgnbr     IN    NUMBER                                   |
--| p_whslrfurcatpgnbr     IN    NUMBER                                   |
--| p_whslrnnpgnbr         IN    NUMBER                                   |
--| p_whslrprgeligflg      IN    VARCHAR2                                 |
--| p_whslrbranchflg       IN    VARCHAR2                                 |
--| x_message_code         OUT   NUMBER                                   |
--| x_message_data         OUT   VARCHAR2                                 |
--+=======================================================================+

PROCEDURE Process_item_xref  (
            p_xref_object          IN    VARCHAR2,
            p_item                 IN    VARCHAR2,
            p_action               IN    VARCHAR2,
            p_xref_item            IN    VARCHAR2,
            p_xref_type            IN    VARCHAR2,
            p_prodmultiplier       IN    NUMBER,
            p_prodmultdivcd        IN    VARCHAR2,
            p_prdxrefdesc          IN    VARCHAR2,
            p_whslrsupplier        IN    NUMBER,
            p_whslrmultiplier      IN    NUMBER,
            p_whslrmultdivcd       IN    VARCHAR2,
            p_whslrretailprice     IN    NUMBER,
            p_whslruomcd           IN    VARCHAR2,
            p_whslrprodcategory    IN    VARCHAR2,
            p_whslrgencatpgnbr     IN    NUMBER,
            p_whslrfurcatpgnbr     IN    NUMBER,
            p_whslrnnpgnbr         IN    NUMBER,
            p_whslrprgeligflg      IN    VARCHAR2,
            p_whslrbranchflg       IN    VARCHAR2,
            x_message_code         OUT   NUMBER,
            x_message_data         OUT   VARCHAR2
            );

-- ----------------------------------------
-- Global constants used for error handling
-- ----------------------------------------
G_PROG_NAME              CONSTANT VARCHAR2(50)  := 'XX_INV_ITEM_XREF_PKG.PROCESS_ITEM_XREF';
G_MODULE_NAME            CONSTANT VARCHAR2(50)  := 'INV';
G_PROG_TYPE              CONSTANT VARCHAR2(50)  := 'CUSTOM API';
G_NOTIFY                 CONSTANT VARCHAR2(1)   := 'Y';
G_MAJOR                  CONSTANT VARCHAR2(15)  := 'MAJOR';
G_MINOR                  CONSTANT VARCHAR2(15)  := 'MINOR';
            

END xx_inv_item_xref_pkg;
/
SHOW ERRORS;
EXIT;
-- --------------------------------------------------------------------------------
-- +==============================================================================+
-- |                         End of Script                                        |
-- +==============================================================================+
-- --------------------------------------------------------------------------------


