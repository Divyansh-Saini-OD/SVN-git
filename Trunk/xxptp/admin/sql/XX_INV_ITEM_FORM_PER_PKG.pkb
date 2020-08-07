SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_ITEM_FORM_PER_PKG
AS 
-- +==============================================================================+
-- |                  Office Depot - Project Simplify                             |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                  |
-- +==============================================================================+
-- | Name       : XX_INV_ITEM_FORM_PER_PKG                                        |
-- | Description: This package checks if the given item displayed in the Master   |
-- |              Item or the Organization Item Forms has Item Type as 'TRADE' Or |
-- |              'COMMON' corresponds to segment2 of category set ‘PO_CATEGORY’. |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version   Date         Author           Remarks                               |
-- |=======   ==========   ===============  ======================================|
-- |DRAFT 1A  16-MAY-2007  Siddharth Singh  Initial version                       |
-- |DRAFT 1B  14-JUN-2007  Sriramdas S      Incorporated Peer review Comments     |
-- |DRAFT 1C  14-JUN-2007  Jayshree Kale    Reviewed and updated                  |    
-- |DRAFT 1D  25-JUN-2007  Sriramdas S      Modified to identify Trade/Common item|
-- |                                        based on the PO Item category as      | 
-- |                                        'TRADE'/‘COMMON’                      |
-- |DRAFT 1E  25-JUN-2007  Jayshree Kale    Reviewed and updated                  |
-- |1.0       19-JUL-2007  Jayshree Kale    Baselined.                            |
-- +==============================================================================+

FUNCTION IS_TRADE_ITEM (p_inv_item_id IN NUMBER, p_org_id IN NUMBER)
RETURN VARCHAR2
-- +==================================================================================================================+
-- |                                                                                                                  |
-- | Name             : IS_TRADE_ITEM                                                                                 |
-- |                                                                                                                  |
-- | Description      : This functon checks if the given item displayed in the Master Item or the Organization Item   |
-- |                    Forms has Item Type as 'TRADE'/'COMMON'.                                                               |
-- |                    If the item type is 'TRADE'/'COMMON' it returns 'Y' else it returns 'N'.                               |
-- |                                                                                                                  |
-- | Parameters       : p_inv_item_id     IN  Inventory Item Id of the given item on the Master Item or the           |
-- |                                          Organization Item  form                                                 |
-- |                    p_org_id          IN  Organization Id of the given item on the Master Item or the             |
-- |                                          Organization Item  form                                                 |
-- +==================================================================================================================+

IS 

ln_count NUMBER := 0;

BEGIN

     SELECT  COUNT(1)
      INTO    ln_count
      FROM    MTL_ITEM_CATEGORIES        MIC
             ,MTL_CATEGORIES_B           MCB
             ,MTL_CATEGORY_SETS          MCS
      WHERE   MIC.inventory_item_id       = p_inv_item_id
      AND     MIC.organization_id         = p_org_id
      AND     MCB.segment2                in ('TRADE','COMMON')
      AND     MCS.category_set_name       = 'PO CATEGORY'
      AND     MIC.category_set_id         = MCS.category_set_id
      AND     MCB.category_id             = MIC.category_id;

   IF ln_count <> 0 THEN
      RETURN 'Y';
   ELSE
      RETURN 'N';
   END IF;

EXCEPTION

WHEN OTHERS THEN

XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                 P_PROGRAM_TYPE            => 'CUSTOM API'
                                ,P_PROGRAM_NAME            => 'XX_INV_ITEM_FORM_PER_PKG.IS_TRADE_ITEM'
                                ,P_PROGRAM_ID              => NULL
                                ,P_MODULE_NAME             => 'INV'
                                ,P_ERROR_LOCATION          => 'WHEN OTHERS EXCEPTION'
                                ,P_ERROR_MESSAGE_COUNT     => NULL
                                ,P_ERROR_MESSAGE_CODE      => SQLCODE
                                ,P_ERROR_MESSAGE           => SQLERRM
                                ,P_ERROR_MESSAGE_SEVERITY  => 'MAJOR'
                                ,P_NOTIFY_FLAG             => 'Y'
                                ,P_OBJECT_TYPE             => 'Master Items / Organization Item Form'
                                ,P_OBJECT_ID               => 'Inventory Item Id: ' || TO_CHAR(p_inv_item_id)
                                ,P_ATTRIBUTE1              => 'Organization Id: '   || TO_CHAR(p_org_id)
                                ,P_ATTRIBUTE2              => 'ITEM FORM PERSONALIZATION'
                                ,P_RETURN_CODE             => NULL
                                ,P_MSG_COUNT               => NULL
                                );
RETURN 'Y';

END IS_TRADE_ITEM;

END XX_INV_ITEM_FORM_PER_PKG;
/

SHOW ERRORS;

EXIT;