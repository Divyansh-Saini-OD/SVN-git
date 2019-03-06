SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_WSH_OTM_SYNC_ITEM_PKG AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |                      Oracle NAIO Consulting Organization                                |
-- +=========================================================================================+
-- | Name   : XX_OM_WSH_OTM_SYNC_ITEM_PKG                                                    |
-- | RICE ID: E0271_EBSOTMDataMap                                                            |
-- | Description      : Package Body containing procedures for Item Information extraction   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   30-Jan-2007       Shashi Kumar     Initial Draft version                      |
-- |1.0        33-Jun-07         Shashi Kumar     Based lined after testing                  |
-- +=========================================================================================+

G_PKG_NAME CONSTANT VARCHAR2(50) := 'XX_OM_WSH_OTM_SYNC_ITEM_PKG';

-- Global Exception variables --

G_ENTITY_REF        VARCHAR2(1000);
G_ENTITY_REF_ID     NUMBER;
G_ERROR_DESCRIPTION VARCHAR2(4000);
G_ERROR_CODE        VARCHAR2(100);

-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Description: This procedure will be responsible to store all      | 
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  None                                                 |
-- |                                                                   |
-- | Returns :    None                                                 |
-- +===================================================================+

PROCEDURE log_exceptions
  
AS

--Variables holding the values from the global exception framework package
--------------------------------------------------------------------------
x_errbuf                    VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_error_code        := g_error_code;
   g_exception.p_error_description := g_error_description;
   g_exception.p_entity_ref        := g_entity_ref;
   g_exception.p_entity_ref_id     := g_entity_ref_id;

   BEGIN
       XX_OM_GLOBAL_EXCEPTION_PKG.insert_exception(g_exception
                                                  ,x_errbuf
                                                  ,x_retcode
                                                 );
   END;    
END log_exceptions;

-- +===================================================================+
-- | Name       :  get_EBS_item_info                                   |
-- | Description:  This Procedure will be used to import the           |
-- |               the deliveries to Roadnet                           |
-- | Parameters :  p_entity_in_rec is the input rec type.              |
-- | returns    :  XX_OM_WSH_OTM_GLOG_ITEM_TBL Extracted Item Info     |
-- +===================================================================+

FUNCTION get_EBS_item_info( p_entity_in_rec IN WSH_OTM_ENTITY_REC_TYPE,
                            x_transmission_id OUT NOCOPY NUMBER,
                            x_return_status OUT NOCOPY VARCHAR2
                          ) RETURN XX_OM_WSH_OTM_GLOG_ITEM_TBL IS


CURSOR  c_get_delivery_items(p_delivery_id NUMBER) IS
SELECT  MTLB.inventory_item_id,
        MTLK.concatenated_segments,
        MTLT.description,
        MTLB.last_update_date,
        MTLB.organization_id,
        (SELECT DECODE(un_number,NULL,NULL,'Hazmat') 
         FROM   PO_UN_NUMBERS_B PUNB, PO_UN_NUMBERS_TL PUNT
         WHERE  PUNB.UN_NUMBER_ID = PUNT.UN_NUMBER_ID
         AND PUNB.UN_NUMBER_ID    = MTLB.UN_NUMBER_ID
        ) hazmat_Attribute,
        MTLB.attribute1,
        MTLB.attribute2,
        MTLB.attribute3,
        MTLB.attribute4
FROM    wsh_delivery_assignments WDA,
        wsh_delivery_details WDD,
        mtl_system_items_b MTLB,
        mtl_system_items_tl MTLT,
        mtl_system_items_kfv MTLK
WHERE   WDA.delivery_id = p_delivery_id
AND     WDA.delivery_detail_id = WDD.delivery_detail_id
AND     WDD.inventory_item_id  = MTLB.inventory_item_id
AND     WDD.inventory_item_id  = MTLT.inventory_item_id
AND     WDD.inventory_item_id  = MTLK.inventory_item_id
AND     WDD.organization_id    = MTLB.organization_id
AND     WDD.organization_id    = MTLK.organization_id
AND     WDD.organization_id    = MTLT.organization_id
AND     MTLB.shippable_item_flag = 'Y'
AND     MTLK.shippable_item_flag = 'Y'
AND     MTLT.LANGUAGE = USERENV('LANG');

CURSOR  c_get_trip_items(p_trip_id NUMBER) IS
SELECT  MTLB.inventory_item_id,
        MTLK.concatenated_segments,
        MTLT.description,
        MTLB.last_update_date,
        MTLB.organization_id,
        MTLB.un_number_id,
        MTLB.Attribute1,
        MTLB.Attribute2,
        MTLB.Attribute3, 
        MTLB.Attribute4
FROM    wsh_delivery_assignments WDA,
        wsh_delivery_details WDD,
        wsh_delivery_legs WDL,
        wsh_trip_stops WTS,
        mtl_system_items_b MTLB,
        mtl_system_items_tl MTLT,
        mtl_system_items_kfv MTLK
WHERE   WTS.trip_id = p_trip_id
AND     WTS.stop_id = WDL.pick_up_stop_id
AND     WDA.delivery_id = WDL.delivery_id
AND     WDA.delivery_detail_id = WDD.delivery_detail_id
AND     WDD.inventory_item_id = MTLB.inventory_item_id
AND     WDD.inventory_item_id = MTLT.inventory_item_id
AND     WDD.inventory_item_id = MTLK.inventory_item_id
AND     WDD.organization_id = MTLB.organization_id
AND     WDD.organization_id = MTLK.organization_id
AND     WDD.organization_id = MTLT.organization_id
AND     MTLB.shippable_item_flag = 'Y'
AND     MTLK.shippable_item_flag = 'Y'
AND     MTLT.LANGUAGE = USERENV('LANG');

--Cursor to get the new transmission Id
CURSOR  c_get_transmission_id IS
SELECT  wsh_otm_sync_ref_data_log_s.NEXTVAL
FROM    dual;

--Declare are local variables of GLOG record and table types
l_tbl_send_item_info XX_OM_WSH_OTM_GLOG_ITEM_TBL;
l_rec_itemmaster XX_OM_WSH_OTM_ITEMMASTER;

l_rec_item item_info;
l_tbl_item item_info_tbl;

l_delivery_id NUMBER;
l_trip_id NUMBER;

l_item_id NUMBER;
l_item_name VARCHAR2(40);
l_item_description VARCHAR2(240);
l_last_update_date DATE;
l_org_id NUMBER;

l_domain_name VARCHAR2(50);
l_xid VARCHAR2(50);

l_substitute_entity VARCHAR2(50);
l_transmission_id NUMBER;
l_send_allowed BOOLEAN;
l_send_count NUMBER := 0;

e_null_id_error EXCEPTION;
e_entity_type_error EXCEPTION;

l_return_status VARCHAR2(1);
l_debug_on BOOLEAN ;
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_EBS_ITEM_INFO';
-- added by shashi 
l_attribute1  mtl_system_items_b.attribute1%TYPE;
l_attribute2  mtl_system_items_b.attribute2%TYPE;           
l_attribute3  mtl_system_items_b.attribute3%TYPE;
l_attribute4  mtl_system_items_b.attribute4%TYPE;
l_hazmat      mtl_system_items_b.un_number_id%TYPE;

ln_delivery_id NUMBER;
ln_trip_id     NUMBER;


BEGIN

-- Debug Statements
--
l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
--
IF l_debug_on IS NULL THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
END IF;

IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
    WSH_DEBUG_SV.LOG(l_module_name,' p_entity_in_rec.ENTITY_TYPE ', p_entity_in_rec.ENTITY_TYPE);
END IF;

x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

--Check for number of ids in the input table and if 0 then raise error.
IF p_entity_in_rec.entity_id_tbl.COUNT = 0 THEN
    RAISE e_null_id_error;
END IF;

l_tbl_send_item_info := XX_OM_WSH_OTM_GLOG_ITEM_TBL();
--l_my_table := glog_item_tbl();

--Get the new transmission Id
OPEN c_get_transmission_id;
FETCH c_get_transmission_id INTO l_transmission_id;
CLOSE c_get_transmission_id;

--Get the domain name from the profile value
FND_PROFILE.Get('WSH_OTM_DOMAIN_NAME',l_domain_name);
IF (l_domain_name IS NULL) THEN
--{
     FND_MESSAGE.SET_NAME('WSH','WSH_PROFILE_NOT_SET_ERR');
     FND_MESSAGE.SET_TOKEN('PRF_NAME','WSH_OTM_DOMAIN_NAME');
     x_return_status := wsh_util_core.G_RET_STS_UNEXP_ERROR;
     wsh_util_core.add_message(x_return_status, l_module_name);
     IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Error: The profile WSH_OTM_DOMAIN_NAME is set to NULL.  Please correct the profile value');
     END IF;
     RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
--}
END IF;

--For each delivery and trip get the item info and put it into the local table l_tbl_item
IF p_entity_in_rec.ENTITY_TYPE = 'DELIVERY' THEN
    FOR l_loop_count IN p_entity_in_rec.entity_id_tbl.FIRST .. p_entity_in_rec.entity_id_tbl.LAST
    LOOP
    
        ln_delivery_id := p_entity_in_rec.entity_id_tbl(l_loop_count);
        g_entity_ref        := 'DELIVERY_ID';
        g_entity_ref_id     := ln_delivery_id;

        OPEN c_get_delivery_items(p_entity_in_rec.entity_id_tbl(l_loop_count));
        LOOP
            FETCH c_get_delivery_items INTO l_rec_item;
            EXIT WHEN c_get_delivery_items%NOTFOUND;
            l_tbl_item(l_tbl_item.COUNT+1) := l_rec_item;
        END LOOP;
        CLOSE c_get_delivery_items;
    END LOOP;
ELSIF p_entity_in_rec.ENTITY_TYPE = 'TRIP' THEN
    FOR l_loop_count IN p_entity_in_rec.entity_id_tbl.FIRST .. p_entity_in_rec.entity_id_tbl.LAST
    LOOP
    
        ln_trip_id          := p_entity_in_rec.entity_id_tbl(l_loop_count);
        g_entity_ref        := 'DELIVERY_ID';
        g_entity_ref_id     := ln_delivery_id;
    
        OPEN c_get_trip_items(p_entity_in_rec.entity_id_tbl(l_loop_count));
        LOOP
            FETCH c_get_trip_items INTO l_rec_item;
            EXIT WHEN c_get_trip_items%NOTFOUND;
            l_tbl_item(l_tbl_item.COUNT+1) := l_rec_item;
        END LOOP;
        CLOSE c_get_trip_items;
    END LOOP;
ELSE
    RAISE e_entity_type_error;
END IF;

--Search the table l_tbl_item for duplicates and if found then remove them.
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_OTM_SYNC_ITEM_PKG.REMOVE_DUPLICATE_ITEMS', WSH_DEBUG_SV.C_PROC_LEVEL);
END IF;

IF l_tbl_item.COUNT <> 0 THEN
    remove_duplicate_items(p_item_tbl => l_tbl_item,
                   x_return_status => l_return_status);
END IF;

IF l_tbl_item.COUNT <> 0 THEN
    FOR l_loop_index IN l_tbl_item.FIRST .. l_tbl_item.LAST
    LOOP
        l_item_id := l_tbl_item(l_loop_index).item_id;
        l_last_update_date := l_tbl_item(l_loop_index).last_update_date;
        l_item_name := l_tbl_item(l_loop_index).item_name;
        l_item_description := l_tbl_item(l_loop_index).item_description;
        l_org_id := l_tbl_item(l_loop_index).org_id;
        -- Added the attributes by shashi
        l_hazmat     := l_tbl_item(l_loop_index).hazmat_Attribute;        
        l_attribute1 := l_tbl_item(l_loop_index).attribute1;
        l_attribute2 := l_tbl_item(l_loop_index).attribute2;
        l_attribute3 := l_tbl_item(l_loop_index).attribute3;        
        l_attribute4 := l_tbl_item(l_loop_index).attribute4;
        
        --For each item find whether it has to be sent to GLOG
        IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit WSH_OTM_SYNC_REF_DATA_PKG.IS_REF_DATA_SEND_REQD', WSH_DEBUG_SV.C_PROC_LEVEL);
        END IF;

        WSH_OTM_SYNC_REF_DATA_PKG.IS_REF_DATA_SEND_REQD(P_ENTITY_ID => l_item_id,
                                P_PARENT_ENTITY_ID => l_org_id,
                                P_ENTITY_TYPE => 'ITEM',
                                P_ENTITY_UPDATED_DATE => l_last_update_date,
                                X_SUBSTITUTE_ENTITY => l_substitute_entity,
                                P_TRANSMISSION_ID => l_transmission_id ,
                                X_SEND_ALLOWED => l_send_allowed,
                                X_RETURN_STATUS => l_return_status
                                 );
        --If l_send_allowed is TRUE then populate l_tbl_send_item_info with that item info
        IF l_send_allowed THEN
            --Construct the XID
            l_xid := TO_CHAR(l_org_id) || '-' || TO_CHAR(l_item_id);
            --Extend the collection.
            l_tbl_send_item_info.EXTEND;
            l_send_count := l_send_count + 1;
        -- using the custom table types by shashi
            l_tbl_send_item_info(l_send_count) := XX_OM_WSH_OTM_ITEMMASTER(
                                        XX_OM_WSH_OTM_ITEM_TYPE('IU',
                                                WSH_OTM_GID_TYPE(WSH_OTM_GID_T(l_domain_name,l_xid)),
                                                l_item_name,
                                                l_item_description,
                                                l_hazmat,
                                                l_attribute1,
                                                l_attribute2,
                                                l_attribute3,
                                                l_attribute4),
                                        WSH_OTM_PACKAGING_TYPE(WSH_OTM_GID_TYPE(WSH_OTM_GID_T(l_domain_name,l_xid)),
                                                    l_item_description));
        END IF;
    END LOOP;

END IF;

--Delete the local table l_tbl_item.
l_tbl_item.DELETE;

IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;

--Check for the number of rows in the table.
IF l_send_count = 0 THEN
    -- This means that there are not items to be send and in this case pass the transmission_id = NULL
    x_transmission_id := NULL;
ELSE
    x_transmission_id := l_transmission_id;
END IF;

RETURN l_tbl_send_item_info;

EXCEPTION
WHEN e_null_id_error THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR ;
    IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'p_Ids cannot be null',WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:NULL_IDS');
        RAISE;
    END IF;
WHEN e_entity_type_error THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR ;
    IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'wrong entity type passed',WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:WRONG_ENTITY_TYPE');
        RAISE;
    END IF;
WHEN OTHERS THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE); 
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
    
    g_error_description:= FND_MESSAGE.GET;
    g_error_code       := FND_MESSAGE.get_number('XXOM','ODP_OM_UNEXPECTED_ERR');
    
    log_exceptions;     
    
    IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
        RAISE;
    END IF;

END get_EBS_item_info;

-- +===================================================================+
-- | Name       :  remove_duplicate_items                              |
-- | Description:  This Procedure will be used to remove duplicate item|
-- |                                                                   |
-- | Parameters :  p_item_tbl is the input item table type.            |
-- | returns    :  x_return_status rteurn status                       |
-- +===================================================================+

PROCEDURE remove_duplicate_items(p_item_tbl IN OUT NOCOPY item_info_tbl,
                                 x_return_status OUT NOCOPY VARCHAR2)IS

l_item_id NUMBER;
l_org_id NUMBER;
l_item_tbl item_info_tbl;
l_count NUMBER;

l_debug_on BOOLEAN ;
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'REMOVE_DUPLICATE_ITEMS';

BEGIN

-- Debug Statements
--
l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
--
IF l_debug_on IS NULL THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
END IF;

IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
    WSH_DEBUG_SV.LOG(l_module_name,'No of rows in item_info_tbl ',p_item_tbl.COUNT);
END IF;

l_count := p_item_tbl.COUNT;

x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

FOR l_loop_count IN p_item_tbl.FIRST .. p_item_tbl.LAST
LOOP
    l_item_id := p_item_tbl(l_loop_count).item_id;
    l_org_id := p_item_tbl(l_loop_count).org_id;
    IF l_item_id IS NOT NULL THEN
        l_item_tbl(l_item_tbl.COUNT+1) := p_item_tbl(l_loop_count);

        FOR l_inner_count IN l_loop_count .. p_item_tbl.LAST
        LOOP
            --Bug 5079207: Added condition to check for org_id also.
            IF p_item_tbl(l_inner_count).item_id = l_item_id AND p_item_tbl(l_inner_count).org_id = l_org_id THEN
                p_item_tbl(l_inner_count) := NULL;
            END IF;
        END LOOP;
    END IF;
END LOOP;

p_item_tbl := l_item_tbl;

EXCEPTION
WHEN OTHERS THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
    IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
        RAISE;
    END IF;
END remove_duplicate_items;

END XX_OM_WSH_OTM_SYNC_ITEM_PKG;
/

SHOW ERRORS;
EXIT;