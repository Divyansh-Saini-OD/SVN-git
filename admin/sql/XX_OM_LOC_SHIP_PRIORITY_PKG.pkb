SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_LOC_SHIP_PRIORITY_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  : XX_OM_DEFRULE_PKG                                         |
-- | Description : Package Body contains the function to default the   |
-- |               shipment priority for internal orders of non-trade  |
-- |               items                                               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version Date        Author             Remarks                     |
-- |======= =========== ================== =========================== |
-- |1.0     13-Mar-2008 Matthew Craig      Initial version             |
-- |1.1     26-Mar-2008 Matthew Craig      changed to use po table     |
-- |                                                                   |
-- +===================================================================+
AS

    NON_TRADE_ITEM_TYPE CONSTANT    VARCHAR2(2) := '99';

-- +===================================================================+
-- | Name : get_shipment_priority                                      |
-- |                                                                   |
-- | Description: This function is used to default the shipment        |
-- |              priority for an internal non-trade order line        |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns :    shipment_priority_code                               |
-- |                                                                   |
-- +===================================================================+

FUNCTION GET_SHIPMENT_PRIORITY (
    p_database_object_name  IN  VARCHAR2,
    p_attribute_code        IN  VARCHAR2
    ) RETURN VARCHAR2
IS

    x_msg                   VARCHAR2(4000);
    x_retcode               VARCHAR2(40);
    l_error_code            VARCHAR2(100);
    l_msg                   VARCHAR2(4000);
    l_item_id               mtl_system_items_b.inventory_item_id%TYPE;
    l_org_id                mtl_system_items_b.organization_id%TYPE;
    l_shipment_priority     oe_order_lines_all.shipment_priority_code%TYPE := NULL;
    l_exists                NUMBER := NULL;
    l_site_use_id           hz_cust_site_uses_all.site_use_id%TYPE;
    
    -- Cursor to get the shipment priority based on the ship to -- 
    CURSOR  lcu_shipment_priority(
        c_site_use_id   hz_cust_site_uses_all.site_use_id%TYPE )
    IS
        SELECT  
            v.attribute7 shipment_priority
        FROM    
             po_location_associations_all s
            ,hr_locations l
            ,fnd_lookup_values v
        WHERE   
                s.site_use_id = c_site_use_id
            AND s.location_id = l.location_id
            AND v.lookup_type = 'OD_LOC_SHIP_PRIORITY'
            AND v.enabled_flag = 'Y'
            AND l.location_id = TO_NUMBER(v.attribute6);
            
    CURSOR  lcu_default_priority
    IS
        SELECT  
            v.attribute7 shipment_priority
        FROM    
            fnd_lookup_values v
        WHERE   
                v.lookup_code = '0000'
            AND v.lookup_type = 'OD_LOC_SHIP_PRIORITY'
            AND v.enabled_flag = 'Y';

    CURSOR  lcu_item (
         c_item_id       mtl_system_items_b.inventory_item_id%TYPE
        ,c_org_id       mtl_system_items_b.organization_id%TYPE )
    IS
        SELECT  
            1
        FROM    
            mtl_system_items_b i
        WHERE   
                i.inventory_item_id = c_item_id
            AND i.organization_id = c_org_id
            AND i.item_type = NON_TRADE_ITEM_TYPE;

BEGIN

    l_item_id := ONT_LINE_DEF_HDLR.g_record.inventory_item_id;
    l_org_id := ONT_LINE_DEF_HDLR.g_record.ship_from_org_id;
    l_site_use_id := ONT_LINE_DEF_HDLR.g_record.ship_to_org_id;
    IF l_item_id IS NOT NULL  AND l_item_id <> FND_API.G_MISS_NUM THEN

        OPEN  lcu_item (l_item_id, l_org_id);
        FETCH lcu_item INTO l_exists;
        CLOSE lcu_item;
        
        IF l_exists IS NULL THEN
        
            RETURN NULL;
            
        END IF;
    END IF;

    IF l_site_use_id IS NULL OR l_site_use_id = FND_API.G_MISS_NUM THEN
        l_site_use_id := ONT_HEADER_DEF_HDLR.g_record.ship_to_org_id;
    END IF;
    
    IF l_site_use_id IS NULL OR 
       l_site_use_id = FND_API.G_MISS_NUM THEN
       
        RETURN NULL;
        
    END IF;

    OPEN  lcu_shipment_priority (l_site_use_id);
    FETCH lcu_shipment_priority INTO l_shipment_priority;
    CLOSE lcu_shipment_priority;
    
    IF l_shipment_priority IS NULL THEN
    
        OPEN  lcu_default_priority;
        FETCH lcu_default_priority INTO l_shipment_priority;
        CLOSE lcu_default_priority;
    
    END IF;

    RETURN l_shipment_priority;
    
EXCEPTION 
    WHEN OTHERS THEN

        IF OE_MSG_PUB.Check_Msg_Level (OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
        
            OE_MSG_PUB.Add_Exc_Msg (
                 'XX_OM_LOC_SHIP_PRIORITY_PKG'
                ,'get_shipment_priority' );
        END IF;

        RETURN NULL;

END GET_SHIPMENT_PRIORITY;


END XX_OM_LOC_SHIP_PRIORITY_PKG;
/
SHOW ERRORS PACKAGE BODY XX_OM_LOC_SHIP_PRIORITY_PKG;
EXIT;

