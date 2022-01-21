--  Copyright (c) 1997 Oracle Corporation, Redwood Shores, CA, USA
--  All rights reserved.
--
--  FILENAME
--
--      OEXPINVB.pls
--
--  DESCRIPTION
--
--      Body of package OE_Invoice_PUB
--
--  NOTES
--  This is the OE_Invoice_PUB package API.
--
--  HISTORY
--  27-AUG-97 Created by Satyajit Ranganathan
--  03-DEC-97 Modified by Satyajit Ranganathan
--  26-MAR-99 Modified by Samuel Wong for R11.8
--            architecture and workflow
--  16-AUG-01 Debug statements and exception handlers added.
--  26-OCT-01 #fix bug 2072121
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile:~PROD:~PATH:~FILE

CREATE or REPLACE PACKAGE BODY OE_Invoice_PUB AS
/*  $Header: OEXPINVB.pls 115.221.11510.37 2007/08/27 20:12:56 lagrawal ship $ */
/*  Modifed for CUSTOMFIX  */

--  Global constant holding the package name

G_PKG_NAME     CONSTANT VARCHAR2(30) := 'OE_Invoice_PUB';
G_ITEMTYPE     VARCHAR2(8);
G_PROCESSING_LINE_ID  NUMBER;
G_USER_ID      NUMBER;
G_RESP_ID      NUMBER;
G_RESP_APPL_ID NUMBER;
inv_num       VARCHAR2(40);
-- 3757279
TYPE Prf_Rec_Type IS RECORD
(   concat_segment        varchar2(240)   := NULL
  , prf_value         varchar2(240)   := NULL
);

TYPE  Prf_Tbl_Type IS TABLE OF Prf_Rec_Type
    INDEX BY BINARY_INTEGER;

Prf_Tbl                 Prf_Tbl_Type;

TABLE_SIZE    binary_integer := 2147483646; /*Size of the above Table*/

FUNCTION find(p_concat_segment IN VARCHAR2)
RETURN binary_integer
IS
   l_tab_index  BINARY_INTEGER;
   l_found      BOOLEAN;
   l_hash_value NUMBER;

BEGIN
   l_tab_index := dbms_utility.get_hash_value(p_concat_segment,1,TABLE_SIZE);
   oe_debug_pub.add('Find: hash_value:'||l_tab_index,1);
   IF Prf_Tbl.EXISTS(l_tab_index) THEN
      IF Prf_Tbl(l_tab_index).concat_segment = p_concat_segment THEN
         RETURN l_tab_index;
      ELSE
         l_hash_value := l_tab_index;
          l_found := FALSE;
          WHILE (l_tab_index < TABLE_SIZE)
            AND NOT l_found  LOOP
             IF Prf_Tbl.EXISTS(l_tab_index) THEN
                IF Prf_Tbl(l_tab_index).concat_segment = p_concat_segment THEN
                   l_found := TRUE;
                ELSE
                   l_tab_index := l_tab_index + 1;
                END IF;
             ELSE
                RETURN (TABLE_SIZE+1);
             END IF;
          END LOOP;
          IF NOT l_found THEN
             l_tab_index := 1;
             WHILE (l_tab_index < l_hash_value)
               AND NOT l_found  LOOP
                IF Prf_Tbl.EXISTS(l_tab_index) THEN
                   IF Prf_Tbl(l_tab_index).concat_segment = p_concat_segment THEN
                       l_found := TRUE;
                   ELSE
                       l_tab_index := l_tab_index + 1;
                   END IF;
                ELSE
                   RETURN (TABLE_SIZE+1);
                END IF;
             END LOOP;
           END IF;
           IF NOT l_found THEN
              RETURN (TABLE_SIZE+1);
           END IF;
      END IF;
   ELSE
      RETURN (TABLE_SIZE+1);
   END IF;
   RETURN l_tab_index;
EXCEPTION
   WHEN OTHERS THEN
      RETURN TABLE_SIZE+1;
END find;

PROCEDURE put(p_concat_segment IN VARCHAR2,
              p_user_id        IN NUMBER,
              p_resp_id        IN NUMBER,
              p_appl_id        IN NUMBER,
              x_prof_value OUT NOCOPY VARCHAR2)
IS
   l_tab_index BINARY_INTEGER;
   l_stored BOOLEAN :=FALSE;
   l_prof_value VARCHAR2(240);
   l_hash_value  NUMBER;
BEGIN
   l_tab_index := dbms_utility.get_hash_value(p_concat_segment,1,TABLE_SIZE);
   l_prof_value := FND_PROFILE.VALUE_SPECIFIC('AR_ALLOW_TAX_CODE_OVERRIDE',p_user_id,p_resp_id,p_appl_id);
   oe_debug_pub.add('Put:hash_value:'||l_tab_index,1);
   IF  Prf_Tbl.EXISTS(l_tab_index) THEN
       IF Prf_Tbl(l_tab_index).concat_segment =  p_concat_segment THEN
          Prf_Tbl(l_tab_index).prf_value := l_prof_value;
          l_stored := TRUE;
       ELSE
         l_hash_value := l_tab_index;
         WHILE l_tab_index < TABLE_SIZE
           AND NOT l_stored LOOP
            IF  Prf_Tbl.EXISTS(l_tab_index) THEN
                IF  Prf_Tbl(l_tab_index).concat_segment =  p_concat_segment THEN
                    Prf_Tbl(l_tab_index).prf_value := l_prof_value;
                    l_stored := TRUE;
                 ELSE
                  l_tab_index := l_tab_index +1;
               END IF;
            ELSE
               Prf_Tbl(l_tab_index).prf_value := l_prof_value;
               Prf_Tbl(l_tab_index).concat_segment := p_concat_segment;
               l_stored := TRUE;
            END IF;
         END LOOP;
         IF NOT l_stored THEN
            l_tab_index := 1;
            WHILE l_tab_index < l_hash_value
              AND NOT l_stored LOOP
               IF Prf_Tbl.EXISTS(l_tab_index) THEN
                  IF Prf_Tbl(l_tab_index).concat_segment =  p_concat_segment THEN
                      Prf_Tbl(l_tab_index).prf_value := l_prof_value;
                      l_stored := TRUE;
                  ELSE
                     l_tab_index := l_tab_index +1;
                  END IF;
               ELSE
                  Prf_Tbl(l_tab_index).prf_value := l_prof_value;
                  Prf_Tbl(l_tab_index).concat_segment := p_concat_segment;
                  l_stored := TRUE;
               END IF;
            END LOOP;
         END IF;
      END IF;
   ELSE
      Prf_Tbl(l_tab_index).prf_value := l_prof_value;
      Prf_Tbl(l_tab_index).concat_segment := p_concat_segment;
      l_stored := TRUE;
   END IF;
   x_prof_value := l_prof_value;
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END put;
-- 3757279

-- 4872894, 4389040
PROCEDURE Get_Createdby_Context(p_line_id        IN  NUMBER,
                                x_user_id       OUT  NUMBER,
                                x_resp_id       OUT  NUMBER,
                                x_resp_appl_id  OUT  NUMBER)
IS
      l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
BEGIN
   IF l_debug_level  > 0 THEN
      oe_debug_pub.add('Entering Get_Createdby_Context, p_line_id:'||p_line_id||':G_Processing_Line_Id:'||G_Processing_Line_Id);
   END IF;
   IF G_Processing_Line_Id = p_line_id THEN
      x_user_id := G_user_id;
      x_resp_id := G_resp_id;
      x_resp_appl_id := G_resp_appl_id;
      IF l_debug_level  > 0 THEN
         oe_debug_pub.add('Returning Createdby_Context from cache:'||G_user_id||':'||G_resp_id||':'||G_resp_appl_id , 1 ) ;
      END IF;
   ELSE
      x_user_id := wf_engine.GetItemAttrNumber( OE_GLOBALS.G_WFI_LIN , to_char(p_line_id) , 'USER_ID');
      x_resp_id := wf_engine.GetItemAttrNumber( OE_GLOBALS.G_WFI_LIN , to_char(p_line_id) , 'RESPONSIBILITY_ID');
      x_resp_appl_id := wf_engine.GetItemAttrNumber( OE_GLOBALS.G_WFI_LIN , to_char(p_line_id) , 'APPLICATION_ID');

      G_Processing_Line_Id := p_line_id;
      G_user_id := x_user_id;
      G_resp_id := x_resp_id;
      G_resp_appl_id := x_resp_appl_id;
      IF l_debug_level  > 0 THEN
         oe_debug_pub.add('Returning Createdby_Context after deriving:'||G_user_id||':'||G_resp_id||':'||G_resp_appl_id , 1 ) ;
      END IF;     
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      x_user_id := NULL;
      x_resp_id := NULL;
      x_resp_appl_id := NULL;

      G_user_id := x_user_id;
      G_resp_id := x_resp_id;
      G_resp_appl_id := x_resp_appl_id;
      IF l_debug_level  > 0 THEN
         oe_debug_pub.add('Createdby_Context Exception:'||G_user_id||':'||G_resp_id||':'||G_resp_appl_id , 1 ) ;
      END IF;

END Get_Createdby_Context;

FUNCTION Invoice_Balance(
P_CUSTOMER_TRX_ID  IN NUMBER )
RETURN NUMBER
IS
   v_balance NUMBER := NULL ;
BEGIN
   IF ( P_CUSTOMER_TRX_ID IS NOT NULL )
   THEN
        SELECT NVL(SUM(AMOUNT_DUE_REMAINING),0)
        INTO v_balance
        FROM AR_PAYMENT_SCHEDULES
        WHERE CUSTOMER_TRX_ID = P_CUSTOMER_TRX_ID;
   END IF;
   RETURN(v_balance);
 EXCEPTION
   WHEN NO_DATA_FOUND THEN
        return(NULL);
END;  -- INVOICE_BALANCE

FUNCTION Return_Line
(p_line_rec IN OE_Order_Pub.Line_Rec_Type
)
RETURN BOOLEAN
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
l_header_id NUMBER;
l_line_id NUMBER;

BEGIN
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'ENTER RETURN_LINE ' , 1 ) ;
     END IF;
     IF p_line_rec.line_category_code = 'RETURN' THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXIT , THIS IS A RETURN LINE' , 1 ) ;
        END IF;
        RETURN TRUE;
     ELSE
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXIT , THIS IS A REGULAR LINE' , 1 ) ;
        END IF;
        RETURN FALSE;
     END IF;
EXCEPTION
     WHEN OTHERS THEN
        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'RETURN_LINE: WHEN OTHERS EXCEPTION ' , 1 ) ;
            END IF;
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Return_Line'
            );
        END IF;
END Return_Line;

Procedure Update_line_flow_status
(  p_line_id IN NUMBER
 , p_flow_status_code IN VARCHAR2
) IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
Begin
   IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'Inside Update Line Flow Status');
   END IF; 
	Update oe_order_lines_all
	Set flow_status_code = p_flow_status_code
	Where line_id = p_line_id;
End Update_line_flow_status;

Procedure Update_header_flow_status
(  p_header_id IN NUMBER
 , p_flow_status_code IN VARCHAR2
) IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
Begin
   IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'Inside Update Header Flow Status');
   END IF;
	Update oe_order_headers_all
	Set flow_status_code = p_flow_status_code
	Where header_id = p_header_id;
End Update_header_flow_status;


FUNCTION Shipping_info_Available
(  p_line_rec   IN   OE_Order_Pub.Line_Rec_Type
)
RETURN BOOLEAN
IS
l_count NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'ENTER SHIPPING_INFO_AVAILABLE ' , 1 ) ;
     END IF;
     -- Fix for bug 2196494
     IF (p_line_rec.shippable_flag = 'Y' OR p_line_rec.item_type_code in ('MODEL','CLASS','KIT')) 
        AND p_line_rec.line_category_code <> 'RETURN'
        AND p_line_rec.source_type_code <> 'EXTERNAL' THEN

        /* Modified the condition clause for bug 4003539 */
        IF (nvl(p_line_rec.shipped_quantity,0) = 0 AND
            p_line_rec.model_remnant_flag = 'Y'    AND
            p_line_rec.item_type_code in ('MODEL','CLASS','KIT')) THEN
             IF l_debug_level  > 0 THEN
                oe_debug_pub.add('Exit Shipping_info_Available (4) Remnant Model',1);
             END IF;
             RETURN TRUE;
        -- If line is shipped, shipped quantity will be filled in otherwise it will be null
        ELSIF p_line_rec.shipped_quantity IS NULL THEN   -- Changed IF to ELSIF
           IF l_debug_level  > 0 THEN
              oe_debug_pub.add('Exit Shipping_info_Available (1) non shippable', 1);
           END IF;
           RETURN FALSE;
        ELSE
           IF l_debug_level  > 0 THEN
              oe_debug_pub.add('Exit Shipping_info_Available (2)-shippable', 1); 
           END IF;
           RETURN TRUE;
        END IF;
     ELSE
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXIT SHIPPING_INFO_AVAILABLE ( 3 ) ' , 1 ) ;
        END IF;
        RETURN FALSE;
     END IF;
EXCEPTION
     WHEN OTHERS THEN
        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'SHIPPPING_INFO_AVAILABLE: WHEN OTHERS EXCEPTION ' , 1 ) ;
            END IF;
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Shippping_info_Available'
            );
        END IF;
END Shipping_info_Available;

FUNCTION Line_Invoiceable
(  p_line_rec   IN   OE_Order_Pub.Line_Rec_Type
)
RETURN BOOLEAN
IS
l_invoiceable_item_flag      VARCHAR2(1);
l_invoice_enabled_flag       VARCHAR2(1);
l_serviceable_product_flag   VARCHAR2(1);
l_order_line_id              NUMBER;
l_return_status              VARCHAR2(1);
l_service_reference_line_id  NUMBER;
l_cancelled_delivery_detail  NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'ENTERING LINE_INVOICEABLE' , 1 ) ;
     END IF;
     /* For internal orders source_document_type_id is 10 */
     IF p_line_rec.source_document_type_id = 10 THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'INTERNAL ORDER , NOT INVOICEABLE' , 1 ) ;
        END IF;
        RETURN FALSE;
     END IF;

     -- Begin 4172494
     IF p_line_rec.shippable_flag = 'Y' AND nvl(p_line_rec.shipped_quantity,0) = 0 THEN
        BEGIN

            SELECT COUNT(*)
            INTO   l_cancelled_delivery_detail
            FROM   WSH_DELIVERY_DETAILS
            WHERE  SOURCE_LINE_ID = p_line_rec.line_id
            AND    SOURCE_CODE='OE'
            AND    RELEASED_STATUS = 'D';
            IF NVL(l_cancelled_delivery_detail,0) > 0 THEN
               IF l_debug_level  > 0 THEN
                  oe_debug_pub.add('This line not eligible for invoice since shipping within tolerance'||p_line_rec.line_id,1);
               END IF;
               RETURN FALSE;
            END IF;
            EXCEPTION WHEN OTHERS THEN
               IF l_debug_level  > 0 THEN
                  oe_debug_pub.add('In Others',1);
               END IF;
               NULL;
        END;
     END IF;
     -- End 4172494

     BEGIN
        SELECT INVOICEABLE_ITEM_FLAG, INVOICE_ENABLED_FLAG
        INTO   l_invoiceable_item_flag, l_invoice_enabled_flag
        FROM   mtl_system_items
        WHERE  inventory_item_id = p_line_rec.inventory_item_id
        AND    organization_id = nvl(p_line_rec.ship_from_org_id, oe_sys_parameters.value('MASTER_ORGANIZATION_ID', p_line_rec.org_id));

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'ITEM DEFINITION DOES NOT EXISTS IN THE SHIP FROM ORG' ); 
           END IF;
           RAISE NO_DATA_FOUND;
     END;
     /* If the service reference context is ORDER, then the service_reference
        line_id is the line_id of the parent. However, if the service ref
        context is Customer Product then we need to first retrieve the
        original order line id */

     IF p_line_rec.item_type_code = 'SERVICE' AND
        p_line_rec.service_reference_type_code='CUSTOMER_PRODUCT' AND
        p_line_rec.service_reference_line_id IS NOT NULL THEN
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'LINE IS A CUSTOMER PRODUCT' ) ;
           END IF;
          /* Commenting for bug 5083469
           OE_SERVICE_UTIL.Get_Cust_Product_Line_Id
           ( x_return_status    => l_return_status
           , p_reference_line_id => p_line_rec.service_reference_line_id
           , p_customer_id       => p_line_rec.sold_to_org_id
           , x_cust_product_line_id => l_order_line_id
           );
           IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
		      IF l_debug_level  > 0 THEN
		          oe_debug_pub.add(  'SERVICE LINE ID IS ' || L_ORDER_LINE_ID ) ;
		      END IF;
              l_service_reference_line_id := l_order_line_id;
           ELSE
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'NOT ABLE TO RETRIEVE CUST PRODUCT LINE ID' ) ;
              END IF;
	              FND_MESSAGE.SET_NAME('ONT','ONT_NO_CUST_PROD_LINE');
                      OE_MSG_PUB.ADD;
		      RAISE NO_DATA_FOUND;
           END IF;
	   end commenting for bug 5083469*/
	   l_service_reference_line_id := NULL;
     ELSE
        l_service_reference_line_id := p_line_rec.service_reference_line_id;
     END IF;
     
     IF p_line_rec.item_type_code = 'SERVICE' AND l_service_reference_line_id IS NOT NULL THEN
        BEGIN
          /*Bug3261460*/
          SELECT msi.SERVICEABLE_PRODUCT_FLAG
          INTO l_serviceable_product_flag
          FROM oe_order_lines_all ol, mtl_system_items msi
          WHERE ol.line_id = l_service_reference_line_id
          AND ol.inventory_item_id = msi.inventory_item_id
          AND msi.organization_id = nvl(ol.ship_from_org_id, oe_sys_parameters.value('MASTER_ORGANIZATION_ID', ol.org_id));
        EXCEPTION
	   WHEN NO_DATA_FOUND THEN
              IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'IN NO DATA FOUND WHEN TRYING TO GET SERVICEABLE PRODUCT FLAG' ,5);
              END IF;
              l_serviceable_product_flag := 'Y';
	   WHEN OTHERS THEN
                  IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  'UNABLE TO DEFINE SERVICEABLE PRODUCT '||SQLERRM , 1 ) ;
                  END IF;
                  RAISE NO_DATA_FOUND;
        END;
     ELSE
          l_serviceable_product_flag := 'Y';
     END IF;

     IF (l_invoiceable_item_flag = 'N') OR
        (l_invoice_enabled_flag = 'N') OR
        (p_line_rec.item_type_code = 'SERVICE' AND l_serviceable_product_flag = 'N') THEN
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'ITEM NOT INVOICEABLE ( 2 ) ' , 1 ) ;
           END IF;
           RETURN FALSE;
     END IF;

     IF p_line_rec.item_type_code = 'INCLUDED' THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'INCLUDED ITEM , NOT INVOICEABLE ( 3 ) ' , 1 ) ;
        END IF;
        RETURN FALSE;
     END IF;

     IF Return_Line(p_line_rec) THEN
        IF OE_LINE_UTIL.Get_Return_Item_Type_Code(p_line_rec) = 'CONFIG' OR
           OE_LINE_UTIL.Get_Return_Item_Type_Code(p_line_rec) = 'INCLUDED' THEN
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'ITEM NOT INVOICEABLE ( 4 ) ' , 1 ) ;
           END IF;
           RETURN FALSE;
        END IF;
     END IF;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'THIS LINE IS INVOICEABLE ( 5 ) ' , 5 ) ;
     END IF;
     RETURN TRUE;

EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
	--RAISE FND_API.G_EXC_ERROR;
     WHEN OTHERS THEN
        IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'LINE_INVOICEABLE: WHEN OTHERS EXCEPTION '||SQLERRM , 1 ) ;
            END IF;
            OE_MSG_PUB.Add_Exc_Msg ( G_PKG_NAME ,'Line_Invoiceable');
        END IF;
END Line_Invoiceable;

PROCEDURE Check_Invoicing_Holds
(  p_line_rec       IN   OE_Order_Pub.Line_Rec_Type
,  p_itemtype       IN   VARCHAR2
,  x_return_status  OUT NOCOPY VARCHAR2
)
IS
l_hold_result_out     VARCHAR2(30);
l_hold_return_status  VARCHAR2(30);
l_hold_msg_count      NUMBER;
l_hold_msg_data       VARCHAR2(240);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

     -- We should honor invoice specific and generic holds
     -- call to check_hold api to check for holds
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'ENTER CHECK_INVOICING_HOLDS ' , 5 ) ;
     END IF;
     -- Check for Generic and invoice activity specific holds
--   IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
        OE_HOLDS_PUB.CHECK_HOLDS(p_api_version => 1.0,
                     p_line_id => p_line_rec.line_id,
                     p_wf_item => OE_GLOBALS.G_WFI_LIN,
                     p_wf_activity => 'INVOICE_INTERFACE',
                     x_result_out => l_hold_result_out,
                     x_return_status => l_hold_return_status,
                     x_msg_count => l_hold_msg_count,
                     x_msg_data => l_hold_msg_data);
        IF ( l_hold_return_status = FND_API.G_RET_STS_SUCCESS AND
             l_hold_result_out = FND_API.G_TRUE )
        THEN
           FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_HOLD');
           OE_MSG_PUB.ADD;
           x_return_status := FND_API.G_RET_STS_ERROR;
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'A Line level Invoicing hold or generic hold found ( 1 ) , Return status : '||X_RETURN_STATUS , 1 ) ;
           END IF;
           RETURN;
        ELSE
		x_return_status := FND_API.G_RET_STS_SUCCESS;
        END IF;
--   ELSIF p_itemtype = 'OEOH' THEN
        OE_HOLDS_PUB.CHECK_HOLDS(p_api_version => 1.0,
                     p_line_id => p_line_rec.line_id,
                     p_wf_item => OE_GLOBALS.G_WFI_HDR,
                     p_wf_activity => 'HEADER_INVOICE_INTERFACE',
                     x_result_out => l_hold_result_out,
                     x_return_status => l_hold_return_status,
                     x_msg_count => l_hold_msg_count,
                     x_msg_data => l_hold_msg_data);

        IF ( l_hold_return_status = FND_API.G_RET_STS_SUCCESS AND
             l_hold_result_out = FND_API.G_TRUE )
        THEN
          FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_HOLD');
          OE_MSG_PUB.ADD;
          x_return_status := FND_API.G_RET_STS_ERROR;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'A Header level Invoicing hold or generic hold found ( 2 ) , Return status '||X_RETURN_STATUS , 1 ) ;
          END IF;
          RETURN;
        ELSE
		x_return_status := FND_API.G_RET_STS_SUCCESS;
        END IF;
--   END IF;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'NO HOLDS FOUND FOR THIS LINE ( 3 ) , RETURN STATUS '||X_RETURN_STATUS , 1 ) ;
     END IF;
EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        IF  FND_MSG_PUB.Check_Msg_Level
            (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'Check_Invoicing_Holds: WHEN OTHERS EXCEPTION '||SQLERRM , 1 ) ;
            END IF;
            OE_MSG_PUB.Add_Exc_Msg ( G_PKG_NAME ,'Check_Invoicing_Holds');
        END IF;
END Check_Invoicing_Holds;

FUNCTION Show_Detail_Discounts
(  p_line_rec    IN OE_Order_Pub.Line_Rec_Type
) RETURN BOOLEAN IS
l_price_adj_tbl   OE_Header_Adj_Util.Line_Adjustments_Tab_Type;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
l_header_id NUMBER;
l_line_id NUMBER;
l_user_id          NUMBER;
l_resp_id          NUMBER;
l_appl_id          NUMBER;
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER SHOW_DETAIL_DISCOUNTS ( ) ' , 5 ) ;
    END IF;
    -- We should not depend on list price, selling price to determine if
    -- there are any discounts. There is bug in pricing now.
    -- Eventhough the discounts are not actually inserted into oe_price_adj table,
    -- Selling price is adjusted to discounted price)
    -- To avoid this look at adj table to see if there are any adjustments
    --  IF p_line_rec.unit_list_price <> p_line_rec.unit_selling_price AND
   Get_Createdby_Context(p_line_id => p_line_rec.line_id,
                         x_user_id      => l_user_id,
                         x_resp_id      => l_resp_id,
                         x_resp_appl_id => l_appl_id);
   IF (fnd_profile.VALUE_SPECIFIC('OE_DISCOUNT_DETAILS_ON_INVOICE', l_user_id,l_resp_id,l_appl_id) = 'Y') THEN
      -- 3661895 The IF will be true only for return retrobilled RMA, all others will go through else
      -- RT{ 
      IF (p_line_rec.line_category_code = 'RETURN'
         and p_line_rec.reference_line_id IS NOT NULL
         and p_line_rec.retrobill_request_id IS NOT NULL) THEN
 
         OE_RETROBILL_PVT.Get_Line_Adjustments
                                  (p_line_rec          =>  p_line_rec 
                                  ,x_line_adjustments  =>  l_price_adj_tbl);
       ELSE

         OE_Header_Adj_Util.Get_Line_Adjustments
	               (p_header_id         =>   p_line_rec.header_id
		       ,p_line_id           =>   p_line_rec.line_id
		       ,x_line_adjustments  =>   l_price_adj_tbl);
       END IF;
       -- RT}
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'HEADER_ID : '||P_LINE_REC.HEADER_ID , 5 ) ;
            oe_debug_pub.add(  'LINE_ID : '||P_LINE_REC.LINE_ID , 5 ) ;
            oe_debug_pub.add(  'COUNT IS : '||L_PRICE_ADJ_TBL.COUNT , 5 ) ;
        END IF;
        IF l_price_adj_tbl.COUNT <> 0 THEN
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'SHOW DETAIL DISCOUNTS IS ON' , 1 ) ;
           END IF;
           RETURN TRUE;
        ELSE
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'SHOW DETAIL DISCOUNTS IS OFF ( 1 ) ' , 1 ) ;
           END IF;
           RETURN FALSE;
        END IF;
    ELSE
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'SHOW DETAIL DISCOUNTS IS OFF ( 2 ) ' , 1 ) ;
       END IF;
       RETURN FALSE;
    END IF;
END Show_Detail_Discounts;

PROCEDURE Rounded_Amount
(  p_currency_code      IN   VARCHAR2
,  p_unrounded_amount   IN   NUMBER
,  x_rounded_amount     OUT NOCOPY NUMBER
)
IS
l_precision         NUMBER;
l_ext_precision     NUMBER;
l_min_acct_unit     NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'ENTERING ROUNDED_AMOUNT ( ) ' , 5 ) ;
     END IF;
     FND_CURRENCY.GET_INFO(Currency_Code => p_currency_code,
                           precision     => l_precision,
                           ext_precision => l_ext_precision,
                           min_acct_unit => l_min_acct_unit);

     IF (l_min_acct_unit = 0 OR l_min_acct_unit IS NULL) THEN
          x_rounded_amount := ROUND(p_unrounded_amount, l_precision);
     ELSE
          x_rounded_amount := ROUND(p_unrounded_amount/l_min_acct_unit)*l_min_acct_unit;
     END IF;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'EXITING ROUNDED AMOUNT ( ) WITH AMOUNT : '||X_ROUNDED_AMOUNT , 5 ) ;
     END IF;
END Rounded_Amount;

PROCEDURE Return_Credit_Info
(  p_line_rec   IN   OE_Order_Pub.Line_Rec_Type
,  x_credit_memo_type_id   OUT NOCOPY  NUMBER
,  x_credit_creation_sign  OUT NOCOPY  VARCHAR2
)
IS
l_inv_cust_trx_type_id NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  ' ENTER RETURN CREDIT INFO ( ) ' , 5 ) ;
    END IF;
          --Hierarchy of retrieval: 
          --1)Get cust_trx_type_id from referenced line.
          --2)Get cust_trx_type_id from referenced order.
          --3)Get cust_trx_type_id from that line.
          --4)Get cust_trx_type_id from that order.
          --5)Get cust_trx_type_id from PROFILE OPTION.
    IF p_line_rec.return_context = 'INVOICE' THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  ' RETURN TYPE IS INVOICE ' , 5 ) ;
       END IF;
       OE_DEBUG_PUB.DUMPDEBUG;
       -- Introducing this pl/sql block #3349781
    BEGIN
       SELECT nvl(ctt.credit_memo_type_id, 0),
              ctt_credit.creation_sign
       INTO x_credit_memo_type_id, x_credit_creation_sign
       FROM ra_customer_trx_lines_all ctl,
            ra_customer_trx_all ct,
            ra_cust_trx_types_all ctt,
            ra_cust_trx_types_all ctt_credit
       WHERE ctl.customer_trx_line_id = p_line_rec.reference_customer_trx_line_id
       AND   ct.customer_trx_id = ctl.customer_trx_id
       AND   ctt.cust_trx_type_id = ct.cust_trx_type_id
       AND   ctt_credit.cust_trx_type_id = ctt.credit_memo_type_id
       AND   NVL(ctt.org_id, -3114) = NVL(ctl.org_id, -3114)
                       /*   DECODE(ctt.cust_trx_type_id,
                            1, -3113,
                            2, -3113,
                            7, -3113,
                            8, -3113, 
                            NVL(ctl.org_id, -3114))                 Commented for the bug 3027150 */
       AND   NVL(ctt_credit.org_id, -3114) =  NVL(ctl.org_id, -3114);
                       /*   DECODE(ctt_credit.cust_trx_type_id,
                            1, -3113,
                            2, -3113,
                            7, -3113,
                            8, -3113,
                            NVL(ctl.org_id, -3114));                Commented for the bug 3027150 */
       -- cust_trx_type_id 1,2,7,8 (for Invoice, Credit Memo, PA Invoice, PA Credit memo) are seeded with org_id -3113
    EXCEPTION WHEN NO_DATA_FOUND THEN
       OE_DEBUG_PUB.add('Unable to derive credit memo type id from referenced order line, verify setup',1);
       x_credit_memo_type_id:= 0;
       x_credit_creation_sign := NULL;
       NULL;
    END;

       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'CREDIT_MEMO_TYPE_ID FROM INVOICE : '||X_CREDIT_MEMO_TYPE_ID , 5 ) ;
       END IF;
    ELSIF p_line_rec.return_context in ('PO', 'ORDER', 'SERIAL') THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  ' RETURN TYPE IS PO/ORDER/SERIAL' , 5 ) ;
          END IF;
          OE_DEBUG_PUB.DUMPDEBUG;
          -- Get cust_trx_type_id from line type
          --Bug2293944 Get information from the reference line or reference order.
          SELECT NVL(lt.cust_trx_type_id, 0)
          INTO   l_inv_cust_trx_type_id
          FROM   oe_line_types_v lt
          WHERE  lt.line_type_id = (SELECT line_type_id 
                                    FROM   oe_order_lines
                                    WHERE  line_id = p_line_rec.reference_line_id);
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM REFERENCE LINE TYPE : '||L_INV_CUST_TRX_TYPE_ID , 5 ) ;
          END IF;
          IF l_inv_cust_trx_type_id = 0 THEN
             SELECT NVL(ot.cust_trx_type_id,0)
             INTO   l_inv_cust_trx_type_id
             FROM   oe_order_types_v ot,
                    oe_order_headers oh
            WHERE   ot.order_type_id = oh.order_type_id
            AND     oh.header_id = (SELECT header_id 
                                    FROM   oe_order_lines
                                    WHERE  line_id = p_line_rec.reference_line_id);
          END IF;  
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM REFERENCE ORDER TYPE : '||L_INV_CUST_TRX_TYPE_ID , 5 ) ;
          END IF;
    ELSE
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'RETURN TYPE : '||P_LINE_REC.RETURN_CONTEXT , 5 ) ;
          END IF;
          x_credit_memo_type_id:= 0;
          x_credit_creation_sign := NULL;
    END IF;    
    IF (l_inv_cust_trx_type_id = 0 or x_credit_memo_type_id = 0)THEN 

     --use cache instead of SQL for bug 3975739
      IF ( p_line_rec.line_type_id is not null  
		 AND p_line_rec.line_type_id <> FND_API.G_MISS_NUM ) THEN 
           if (OE_Order_Cache.g_line_type_rec.line_type_id <> p_line_rec.Line_Type_id) THEN 
		  OE_Order_Cache.Load_Line_type(p_line_rec.Line_Type_id) ;
           end if  ; 
           if (OE_Order_Cache.g_line_type_rec.line_type_id =  p_line_rec.Line_Type_id ) 
 	   then 
		l_inv_cust_trx_type_id := nvl(OE_Order_Cache.g_line_type_rec.cust_trx_type_id,0);
	   else 
	        l_inv_cust_trx_type_id := 0 ;
           end if ;
      ELSE 
		l_inv_cust_trx_type_id := 0 ;
      END IF ;	
       /*SELECT NVL(lt.cust_trx_type_id,0)
       INTO   l_inv_cust_trx_type_id
	      FROM   oe_line_types_v lt
	      WHERE  lt.line_type_id = p_line_rec.line_type_id; */
	-- end bug 3975739
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM LINE TYPE : '||L_INV_CUST_TRX_TYPE_ID , 5 ) ;
       END IF;
       IF l_inv_cust_trx_type_id = 0 THEN
           -- Get cust_trx_type_id from order type
           SELECT  NVL(ot.cust_trx_type_id, 0)
           INTO   l_inv_cust_trx_type_id
           FROM   oe_order_types_v ot,
                  oe_order_headers oh
           WHERE  ot.order_type_id = oh.order_type_id
           AND    oh.header_id = p_line_rec.header_id;
       END IF;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM ORDER TYPE : '||L_INV_CUST_TRX_TYPE_ID , 5 ) ;
       END IF;
    END IF;
    IF l_inv_cust_trx_type_id <> 0 THEN -- cust_trx_type_id exists at line/order type
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'CUST_TRX_TYPE_ID FROM LINE/ORDER TYPE: '||L_INV_CUST_TRX_TYPE_ID , 5 ) ;
       END IF;
       -- Introducing this pl/sql block #3349781
       BEGIN
          SELECT NVL(ctt.credit_memo_type_id, 0),
                 ctt_credit.creation_sign
          INTO x_credit_memo_type_id, x_credit_creation_sign
          FROM ra_cust_trx_types_all ctt,
               ra_cust_trx_types_all ctt_credit
          WHERE ctt.cust_trx_type_id = l_inv_cust_trx_type_id
          AND   ctt_credit.cust_trx_type_id = ctt.credit_memo_type_id
          AND   NVL(ctt.org_id, -3114) =  NVL(p_line_rec.org_id, -3114)
                   /*      DECODE(ctt.cust_trx_type_id,
                            1, -3113,
                            2, -3113,
                            7, -3113,
                            8, -3113,
                            NVL(p_line_rec.org_id, -3114))                Commented for the bug 3027150 */
           AND   NVL(ctt_credit.org_id, -3114) = NVL(p_line_rec.org_id, -3114);
                 /*        DECODE(ctt_credit.cust_trx_type_id,
                            1, -3113,
                            2, -3113,
                            7, -3113,
                            8, -3113,
                            NVL(p_line_rec.org_id, -3114));                Commented for the bug 3027150 */
       EXCEPTION WHEN NO_DATA_FOUND THEN
         OE_DEBUG_PUB.add('Unable to derive credit memo type id from order line, verify setup',1);
         x_credit_memo_type_id:= 0;
         x_credit_creation_sign := NULL;
         NULL;
       END;

           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'CREDIT MEMO TYPE : '||X_CREDIT_MEMO_TYPE_ID , 5 ) ;
           END IF;
           -- cust_trx_type_id 1,2,7,8 (for Invoice, Credit Memo, PA Invoice, PA Credit memo) are seeded with org_id -3113
    END IF;
    IF l_inv_cust_trx_type_id = 0 OR x_credit_memo_type_id = 0 THEN 
       -- no cust_trx_type_id at line/order type
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'NO CUST TRX TYPE AT ORDER OR LINE TYPE LEVEL' , 5 ) ;
       END IF;
       x_credit_memo_type_id := 0;
       x_credit_creation_sign := NULL;
    END IF; 
 
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'CREDIT MEMO TYPE ID : '||X_CREDIT_MEMO_TYPE_ID , 5 ) ;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'CREATION_SIGN : '||X_CREDIT_CREATION_SIGN , 5 ) ;
        oe_debug_pub.add(  ' EXITING RETURN_CREDIT_INFO ( ) ' , 1 ) ;
    END IF;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXCEPTION. EXITING RETURN_CREDIT_INFO ( 1 ) '||SQLERRM , 1 ) ;
        END IF;
        x_credit_memo_type_id := 0;
        x_credit_creation_sign := NULL;
   WHEN TOO_MANY_ROWS THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXCEPTION. EXITING RETURN_CREDIT_INFO ( 2 ) '||SQLERRM , 1 ) ;
        END IF;
        x_credit_memo_type_id := 0;
        x_credit_creation_sign := NULL;
   WHEN OTHERS THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXCEPTION. EXITING RETURN_CREDIT_INFO ( 3 ) '||SQLERRM , 1 ) ;
        END IF;
        x_credit_memo_type_id := 0;
        x_credit_creation_sign := NULL;
END Return_Credit_Info;

FUNCTION Get_Credit_Creation_Sign
(  p_line_rec    IN   OE_Order_Pub.Line_Rec_Type
,  p_cust_trx_type_id   IN  NUMBER)
RETURN VARCHAR2 IS
l_creation_sign      VARCHAR2(30):= NULL;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'ENTERING GET_CREDIT_CREATION_SIGN' , 5 ) ;
   END IF;
   IF p_cust_trx_type_id IS NOT NULL AND p_cust_trx_type_id <> 0 THEN
	 SELECT creation_sign
	 INTO l_creation_sign
	 FROM ra_cust_trx_types
	 WHERE cust_trx_type_id = p_Cust_Trx_Type_Id;
   END IF;
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'CREATION_SIGN: '||L_CREATION_SIGN ) ;
       oe_debug_pub.add(  'EXITING GET_CREDIT_CREATION_SIGN ( 1 ) '||' SIGN= '||L_CREATION_SIGN , 1 ) ;
   END IF;
   RETURN(l_creation_sign);

EXCEPTION
   WHEN OTHERS THEN
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'EXCEPTION. EXITING GET_CREDIT_CREATION_SIGN ( 1 ) '||SQLERRM , 1 ) ;
      END IF;
      RETURN(NULL);
END Get_Credit_Creation_Sign;

PROCEDURE Get_Commitment_Info
(  p_line_rec    IN   OE_Order_Pub.Line_Rec_Type
,  x_commitment_applied     OUT NOCOPY NUMBER
,  x_commitment_interfaced  OUT NOCOPY NUMBER)
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'ENTERING GET_COMMITMENT_INFO' , 5 ) ;
   END IF;
   IF p_line_rec.commitment_id IS NOT NULL THEN
--serla begin
    IF OE_PrePayment_UTIL.IS_MULTIPLE_PAYMENTS_ENABLED THEN
      SELECT nvl(commitment_applied_amount, 0)
            ,nvl(commitment_interfaced_amount, 0)
      INTO  x_commitment_applied
            ,x_commitment_interfaced
      FROM oe_payments
      WHERE payment_trx_id = p_line_rec.commitment_id
      AND   payment_type_code = 'COMMITMENT'
      AND   line_id = p_line_rec.line_id;
    ELSE
--serla end
      SELECT nvl(commitment_applied_amount, 0)
            ,nvl(commitment_interfaced_amount, 0)
      INTO  x_commitment_applied
            ,x_commitment_interfaced
      FROM oe_payments
      WHERE payment_trx_id = p_line_rec.commitment_id
      AND   line_id = p_line_rec.line_id;
--serla begin
    END IF;
--serla end
   END IF;
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  ' COMMITMENT APPLIED : '||X_COMMITMENT_APPLIED , 1 ) ;
       oe_debug_pub.add(  ' COMMITMENT INTERFACED :'||X_COMMITMENT_INTERFACED , 1 ) ;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXCEPTION. EXITING GET_COMMITMENT_INFO ( 1 ) '||SQLERRM , 1 ) ;
        END IF;
        x_commitment_applied := NULL;
        x_commitment_interfaced := NULL;
END Get_Commitment_Info;

PROCEDURE Get_Item_Description
(  p_line_rec           IN   OE_Order_Pub.Line_Rec_Type
,  x_item_description   OUT NOCOPY VARCHAR2
) IS
l_organization_id NUMBER := oe_sys_parameters.value('MASTER_ORGANIZATION_ID', p_line_rec.org_id);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
l_item_description   VARCHAR2(240) := null ;
BEGIN
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  ' ENTERING GET_ITEM_DESCRIPTION ( ) ' , 5 ) ;
       oe_debug_pub.add(  ' Item Identifier Type :'||p_line_rec.item_identifier_type);
       oe_debug_pub.add('Inventory Item ID '||p_line_rec.inventory_item_id,5);
       oe_debug_pub.add('Organization ID '||l_organization_ID,5);
       oe_debug_pub.add('Ordered Item ID '||p_line_rec.ordered_item_id);
       oe_debug_pub.add('Sold to Org  ID '||p_line_rec.sold_to_org_id,5);
   END IF;
   IF    nvl(p_line_rec.item_identifier_type,'INT') = 'INT' THEN   -- Bug #3684306
         SELECT description
         INTO  x_item_description
         FROM  mtl_system_items_vl
         WHERE inventory_item_id =p_line_rec.inventory_item_id
         AND organization_id = l_organization_id;
   ELSIF nvl(p_line_rec.item_identifier_type,'INT') = 'CUST' THEN   -- Bug #3684306
		-- changes for bug 4237119
      /*   SELECT nvl(citems.customer_item_desc, sitems.description)
         INTO  x_item_description
         FROM  mtl_customer_items citems
              ,mtl_customer_item_xrefs cxref
              ,mtl_system_items_vl sitems
         WHERE citems.customer_item_id = cxref.customer_item_id
           AND cxref.inventory_item_id = sitems.inventory_item_id
           AND sitems.inventory_item_id = p_line_rec.inventory_item_id
           AND sitems.organization_id = l_organization_id
           AND citems.customer_item_id = p_line_rec.ordered_item_id
           AND citems.customer_id = p_line_rec.sold_to_org_id; */

	SELECT citems.customer_item_desc INTO l_item_description
	FROM mtl_customer_items citems
	WHERE citems.customer_item_id = p_line_rec.ordered_item_id
           AND citems.customer_id = p_line_rec.sold_to_org_id;
	if l_item_description is null then 
	      SELECT sitems.description INTO l_item_description 
	      FROM mtl_system_items_vl sitems
	      WHERE sitems.inventory_item_id = p_line_rec.inventory_item_id 
  	        and sitems.organization_id = l_organization_id ; 
	end if ;
	x_item_description := l_item_description ; 
   ELSE
         SELECT nvl(items.description, sitems.description)
         INTO x_item_description
         FROM  mtl_cross_reference_types types
             , mtl_cross_references items
             , mtl_system_items_vl sitems
         WHERE types.cross_reference_type = items.cross_reference_type
           AND items.inventory_item_id = sitems.inventory_item_id
           AND sitems.organization_id = l_organization_id
           AND sitems.inventory_item_id = p_line_rec.inventory_item_id
           AND items.cross_reference_type = p_line_rec.item_identifier_type
           AND items.cross_reference = p_line_rec.ordered_item
           AND ROWNUM = 1; -- Bug3333235
   END IF;
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'ITEM_DESCRIPTION : '||X_ITEM_DESCRIPTION ) ;
       oe_debug_pub.add(  ' EXITING GET_ITEM_DESCRIPTION: '||X_ITEM_DESCRIPTION , 1 ) ;
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND THEN --added for bug 4191624
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add('When no data found then get desc from system items '||SQLERRM,1);
         END IF;
	SELECT sitems.description 
        INTO x_item_description
	FROM mtl_system_items_vl sitems
	WHERE sitems.inventory_item_id = p_line_rec.inventory_item_id 
	  and sitems.organization_id = l_organization_id ;
   WHEN OTHERS THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXCEPTION. GET ITEM DESCRIPTION '||SQLERRM , 1 ) ;
         END IF;
         NULL;
END Get_Item_Description;

PROCEDURE Get_Service_Item_Description
(  p_line_rec           IN   OE_Order_Pub.Line_Rec_Type
,  x_item_description   OUT NOCOPY VARCHAR2
) IS
l_line_rec OE_Order_Pub.Line_Rec_Type;
l_order_line_id              NUMBER;
l_return_status              VARCHAR2(1);
l_service_reference_line_id  NUMBER;
l_service_item_desc          VARCHAR2(240);
l_item_serviced_desc         VARCHAR2(240) := null;

/*Bug3261460-start*/
l_inventory_item_id          NUMBER;
l_ordered_item_id            NUMBER;
l_sold_to_org_id             NUMBER;
l_item_identifier_type       VARCHAR2(30);
l_ordered_item               VARCHAR2(2000);
l_org_id                     NUMBER;
/*Bug3261460-end*/

l_organization_id NUMBER := oe_sys_parameters.value('MASTER_ORGANIZATION_ID', p_line_rec.org_id);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  ' ENTERING GET SERVICE ITEM DESCRIPTION ( ) ' , 5 ) ;
   END IF;
   IF p_line_rec.item_type_code = 'SERVICE' AND
      p_line_rec.service_reference_type_code='CUSTOMER_PRODUCT' AND
      p_line_rec.service_reference_line_id IS NOT NULL THEN
	       IF l_debug_level  > 0 THEN
	           oe_debug_pub.add(  'REFERENCED BY CUSTOMER PRODUCT' , 5 ) ;
	       END IF;
	  /* Commenting for bug 5083469
           OE_SERVICE_UTIL.Get_Cust_Product_Line_Id
           ( x_return_status    => l_return_status
           , p_reference_line_id => p_line_rec.service_reference_line_id
           , p_customer_id       => p_line_rec.sold_to_org_id
           , x_cust_product_line_id => l_order_line_id
           );
           IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
		      IF l_debug_level  > 0 THEN
		          oe_debug_pub.add(  'SERVICE LINE ID IS : ' || L_ORDER_LINE_ID , 5 ) ;
		      END IF;
              l_service_reference_line_id := l_order_line_id;
           ELSE
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'NOT ABLE TO RETRIEVE CUST PRODUCT LINE ID '||SQLERRM , 1 ) ;
              END IF;
		      RAISE NO_DATA_FOUND;
           END IF;
	   end commenting for bug 5083469 */
           l_service_reference_line_id := NULL;
   ELSE
        l_service_reference_line_id := p_line_rec.service_reference_line_id;
   END IF;
   Get_Item_Description(p_line_rec, l_service_item_desc);

   IF l_service_reference_line_id IS NOT NULL
   THEN
   /*Bug3261460-Changes made to get the serviced item description*/
     -- l_line_rec := OE_LINE_UTIL.Query_Row(l_service_reference_line_id);
     -- Get_Item_Description(l_line_rec, l_item_serviced_desc);
      BEGIN
          select inventory_item_id,ordered_item_id,sold_to_org_id,item_identifier_type,ordered_item,org_id
          into l_inventory_item_id,l_ordered_item_id,l_sold_to_org_id,l_item_identifier_type,l_ordered_item,l_org_id
          from OE_ORDER_LINES_ALL
          where line_id = l_service_reference_line_id;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            IF l_debug_level  > 0 THEN
               oe_debug_pub.add( 'NOT ABLE TO GET SERVICE LINE DETAILS', 1);
            END IF;
            l_item_identifier_type := NULL;
            l_inventory_item_id    := NULL;
            l_organization_id      := NULL;
      END;
          l_organization_id  :=  oe_sys_parameters.value('MASTER_ORGANIZATION_ID', l_org_id);
          oe_debug_pub.add('Executed  the first sql',1);

      BEGIN  --added for bug 4237119
          IF    nvl(l_item_identifier_type,'INT') = 'INT' THEN  -- Bug #3684306
                oe_debug_pub.add('Item identifier type is INT',1);
             BEGIN  
                SELECT description
                INTO l_item_serviced_desc
                FROM  mtl_system_items_vl
                WHERE inventory_item_id =l_inventory_item_id
                AND organization_id = l_organization_id;
	     EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    IF l_debug_level  > 0 THEN
                       oe_debug_pub.add( 'NO DATA FOUND IN SERVICE ITEM DESCRIPTION');
                    END IF;
                    l_item_serviced_desc := NULL;
               END;	
          ELSIF nvl(l_item_identifier_type,'INT') = 'CUST' THEN  -- Bug #3684306
                oe_debug_pub.add('Item Identifier typs is CUST',1);
		-- changes for bug 4237119
                /*SELECT nvl(citems.customer_item_desc, sitems.description)
                INTO l_item_serviced_desc
                FROM  mtl_customer_items citems
                ,mtl_customer_item_xrefs cxref
                ,mtl_system_items_vl sitems
                WHERE citems.customer_item_id = cxref.customer_item_id
                AND cxref.inventory_item_id = sitems.inventory_item_id
                AND sitems.inventory_item_id = l_inventory_item_id
                AND sitems.organization_id = l_organization_id
                AND citems.customer_item_id = l_ordered_item_id
                AND citems.customer_id = l_sold_to_org_id; */

		SELECT citems.customer_item_desc INTO l_item_serviced_desc
		FROM mtl_customer_items citems
		WHERE citems.customer_item_id = l_ordered_item_id
        	   AND citems.customer_id = l_sold_to_org_id;
		if l_item_serviced_desc is null then 
	      		SELECT sitems.description INTO l_item_serviced_desc
	      		FROM mtl_system_items_vl sitems
	     	 	WHERE sitems.inventory_item_id = l_inventory_item_id 
  	       		 and sitems.organization_id = l_organization_id ; 
		end if ;
          ELSE
                oe_debug_pub.add('In else part of item identifier type',1);
                SELECT nvl(items.description, sitems.description)
                INTO l_item_serviced_desc
                FROM  mtl_cross_reference_types types
                , mtl_cross_references items
                , mtl_system_items_vl sitems
                WHERE types.cross_reference_type = items.cross_reference_type
                AND items.inventory_item_id = sitems.inventory_item_id
                AND sitems.organization_id = l_organization_id
                AND sitems.inventory_item_id = l_inventory_item_id
                AND items.cross_reference_type = l_item_identifier_type
                AND items.cross_reference = l_ordered_item;
          END IF;
	EXCEPTION --added for bug 4237119
	    WHEN NO_DATA_FOUND THEN 
	        IF l_debug_level  > 0 THEN
	             oe_debug_pub.add('When no data found then get desc from system items '||SQLERRM,1);
                END IF;
		SELECT sitems.description 
        	INTO l_item_serviced_desc
		FROM mtl_system_items_vl sitems
		WHERE sitems.inventory_item_id = l_inventory_item_id 
		  and sitems.organization_id = l_organization_id ;
	END ;
          OE_DEBUG_PUB.ADD('Item_Description of serviced item: '||l_item_serviced_desc);
   
   END IF;
   x_item_description := substr(l_service_item_desc,1,90)||' - '||
           p_line_rec.ordered_quantity
           ||' '||substr(l_item_serviced_desc,1,90)||': '
           ||p_line_rec.service_start_date||' - '||p_line_rec.service_end_date ;

   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'SERVICE ITEM_DESCRIPTION: '||X_ITEM_DESCRIPTION ) ;
       oe_debug_pub.add(  ' EXITING GET_SERVICE_ITEM_DESCRIPTION: '||X_ITEM_DESCRIPTION , 1 ) ;
   END IF;
EXCEPTION
     WHEN OTHERS THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'EXCEPTION. GET SERVICE ITEM DESCRIPTION ( ) '||SQLERRM , 1 ) ;
          END IF;
          NULL;
END Get_Service_Item_Description;

FUNCTION Get_Overship_Invoice_Basis
(p_line_rec IN OE_Order_Pub.Line_Rec_Type)
RETURN VARCHAR2
IS
l_overship_invoice_basis  VARCHAR2(30):= NULL;
l_user_id          NUMBER;
l_resp_id          NUMBER;
l_appl_id          NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
/*
    Get l_overship_invoice_basis from control set
     1. Item
     2. Ship_to_site
     3. Customer
     4.Profile
*/
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  ' ENTERING GET_OVERSHIP_INVOICE_BASIS' , 5 ) ;
     END IF;
     IF p_line_rec.ship_to_org_id IS NOT NULL THEN
        SELECT invoice_quantity_rule
        INTO l_overship_invoice_basis
        FROM hz_cust_site_uses
        WHERE site_use_id = p_line_rec.ship_to_org_id
        AND site_use_code = 'SHIP_TO';
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OVERSHIP_INVOICE_BASIS ( 2 ) : '||L_OVERSHIP_INVOICE_BASIS , 5 ) ;
        END IF;
     END IF;
     IF l_overship_invoice_basis IS NULL THEN
        IF p_line_rec.sold_to_org_id IS NOT NULL THEN
	       SELECT invoice_quantity_rule
	       INTO l_overship_invoice_basis
  	       FROM hz_cust_accounts
	       WHERE cust_account_id = p_line_rec.sold_to_org_id;
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'OVERSHIP_INVOICE_BASIS ( 1 ) : '||L_OVERSHIP_INVOICE_BASIS , 5 ) ;
           END IF;
        END IF;
     END IF;
     IF l_overship_invoice_basis IS NULL THEN
        Get_Createdby_Context(p_line_id => p_line_rec.line_id,
                         x_user_id      => l_user_id,
                         x_resp_id      => l_resp_id,
                         x_resp_appl_id => l_appl_id);
        l_overship_invoice_basis := FND_PROFILE.VALUE_SPECIFIC('OE_OVERSHIP_INVOICE_BASIS', l_user_id,l_resp_id,l_appl_id);
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'OVERSHIP_INVOICE_BASIS ( 3 ) : '||L_OVERSHIP_INVOICE_BASIS , 5 ) ;
        END IF;
     END IF;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OVERSHIP_INVOICE_BASIS: '||L_OVERSHIP_INVOICE_BASIS , 5 ) ;
         oe_debug_pub.add(  ' EXITING GET_OVERSHIP_INVOICE_BASIS: '||L_OVERSHIP_INVOICE_BASIS , 5 ) ;
     END IF;
     RETURN l_overship_invoice_basis;

END Get_Overship_Invoice_Basis;

FUNCTION Get_Invoice_Source
(  p_line_rec IN OE_Order_Pub.Line_Rec_Type
,  p_interface_line_rec  IN  RA_Interface_Lines_Rec_Type
)
RETURN VARCHAR2
IS
l_invoice_source_id    NUMBER := NULL;
l_invoice_source       VARCHAR2(50):= NULL;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  ' ENTERING GET_INVOICE_SOURCE' , 5 ) ;
     END IF;
     IF FND_PROFILE.VALUE('WSH_INVOICE_NUMBERING_METHOD')=  'D' AND
        (Return_Line(p_line_rec) OR NOT Shipping_Info_Available(p_line_rec) OR
       (p_interface_line_rec.interface_line_attribute3 = '0')) THEN
           SELECT NVL(lt.non_delivery_invoice_source_id,
                  ot.non_delivery_invoice_source_id)
           INTO l_invoice_source_id
           FROM oe_line_types_v lt,
            oe_order_types_v ot,
            oe_order_headers oh
           WHERE lt.line_type_id = p_line_rec.line_type_id
       AND   ot.order_type_id = oh.order_type_id
       AND   oh.header_id = p_line_rec.header_id;
       IF   l_invoice_source_id IS NOT NULL THEN
            SELECT name
            INTO l_invoice_source
            FROM ra_batch_sources
            WHERE batch_source_id = l_invoice_source_id;
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'INVOICE_SOURCE IS ( 1 ) : '||L_INVOICE_SOURCE , 5 ) ;
            END IF;
            RETURN  l_invoice_source;
       ELSE
            l_invoice_source := FND_PROFILE.VALUE('OE_NON_DELIVERY_INVOICE_SOURCE');
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'INVOICE_SOURCE IS ( 2 ) : '||L_INVOICE_SOURCE , 5 ) ;
            END IF;
            RETURN l_invoice_source;
       END IF;
     ELSE  -- Invoice numbering method is 'Automatic' OR 'delivery' with shipping information available
        SELECT NVL(lt.invoice_source_id,
                   ot.invoice_source_id)
	INTO l_invoice_source_id
	FROM oe_line_types_v lt,
             oe_order_types_v ot,
             oe_order_headers oh
	    WHERE lt.line_type_id = p_line_rec.line_type_id
        AND   ot.order_type_id = oh.order_type_id
        AND   oh.header_id = p_line_rec.header_id;
        IF l_invoice_source_id IS NOT NULL THEN
           SELECT name
           INTO l_invoice_source
           FROM ra_batch_sources
           WHERE batch_source_id = l_invoice_source_id;
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'INVOICE SOURCE IS ( 3 ) : '||L_INVOICE_SOURCE , 5 ) ;
           END IF;
           RETURN  l_invoice_source;
        ELSE
           l_invoice_source := FND_PROFILE.VALUE('OE_INVOICE_SOURCE');
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'INVOICE_SOURCE IS ( 4 ) : '||L_INVOICE_SOURCE , 5 ) ;
           END IF;
           RETURN l_invoice_source;
        END IF;
     END IF;
    EXCEPTION
      WHEN OTHERS THEN
         IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'In Others of Function Get_Invoice_Source', 5);
         END IF;
         RETURN l_invoice_source;
END Get_Invoice_Source;

FUNCTION Get_Customer_Transaction_Type
(  p_record IN OE_AK_ORDER_LINES_V%ROWTYPE
) RETURN NUMBER IS
l_inv_cust_trx_type_id NUMBER;
l_cust_trx_type_id NUMBER;
l_creation_sign  VARCHAR2(30);
l_line_rec OE_Order_Pub.Line_Rec_Type;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  ' ENTER GET_CUSTOMER_TRANSACTION_TYPE' , 5 ) ;
  END IF;
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'Before the call to Rowtype_Rec_To_API_Rec ', 1);
  END IF;
      OE_Line_Util_Ext.Rowtype_Rec_To_API_Rec(p_record,l_line_rec);
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'After the call to Rowtype_Rec_To_API_Rec ', 1);
  END IF;
 
  l_cust_trx_type_id := Get_Customer_Transaction_Type(l_line_rec);
  RETURN(l_cust_trx_type_id);

EXCEPTION
   WHEN OTHERS THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXCEPTION. EXITING GET_CUSTOMER_TRANSACTION_TYPE ( ) , '||SQLERRM , 1 ) ;
        END IF;
        return(0);
END Get_Customer_Transaction_Type;

FUNCTION Get_Customer_Transaction_Type
(  p_line_rec IN OE_Order_Pub.Line_Rec_Type
) RETURN NUMBER IS
l_inv_cust_trx_type_id NUMBER;
l_cust_trx_type_id NUMBER;
l_creation_sign  VARCHAR2(30);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  ' ENTER GET_CUSTOMER_TRANSACTION_TYPE' , 5 ) ;
  END IF;

      --use cache instead of SQL for bug 3975739
  IF ( p_line_rec.line_type_id is not null  
	    AND p_line_rec.line_type_id <> FND_API.G_MISS_NUM 
               AND OE_Order_Cache.g_line_type_rec.line_type_id <> p_line_rec.Line_Type_id) THEN 
	  OE_Order_Cache.Load_Line_type(p_line_rec.Line_Type_id) ;
  END IF  ;   -- end 

  IF NOT Return_Line(p_line_rec) THEN  -- Standard Order Line
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'THIS IA A STANDARD ORDER LINE' , 5 ) ;
     END IF;
    --use cache instead of SQL for bug 3975739
	if (OE_Order_Cache.g_line_type_rec.line_type_id =  p_line_rec.Line_Type_id ) then	
      	     l_cust_trx_type_id := nvl(OE_Order_Cache.g_line_type_rec.cust_trx_type_id,0) ; 
	else 
	     l_cust_trx_type_id := 0 ;
	end if ; 
      /*  SELECT NVL(lt.cust_trx_type_id, 0)
     INTO   l_cust_trx_type_id
     FROM   oe_line_types_v lt
     WHERE  lt.line_type_id = p_line_rec.line_type_id; */
	-- end bug 3975739
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM LINE TYPE : '||L_CUST_TRX_TYPE_ID , 5 ) ;
     END IF;
     IF l_cust_trx_type_id = 0 THEN
        SELECT NVL(ot.cust_trx_type_id, 0)
        INTO   l_cust_trx_type_id
        FROM   oe_order_types_v ot,
               oe_order_headers oh
        WHERE  ot.order_type_id = oh.order_type_id
        AND    oh.header_id = p_line_rec.header_id;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM ORDER TYPE : '||L_CUST_TRX_TYPE_ID , 5 ) ;
        END IF;
        IF l_cust_trx_type_id = 0 THEN
          SELECT NVL(FND_PROFILE.VALUE('OE_INVOICE_TRANSACTION_TYPE_ID'), 0)
          INTO l_cust_trx_type_id
          FROM DUAL;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM PROFILE : '||L_CUST_TRX_TYPE_ID , 5 ) ;
          END IF;
        END IF;
     END IF;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'GET CUSTOMER TRANSACTION TYPE ( 1 ) : '||L_CUST_TRX_TYPE_ID , 5 ) ;
     END IF;
     RETURN(l_cust_trx_type_id);
  ELSIF p_line_rec.reference_line_id IS NOT NULL THEN -- Referenced Return Line
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'THIS IA A REFERENCED RETURN LINE' , 5 ) ;
        END IF;
        -- Get from reference line (Ignore l_creation_sign value here)
        Return_Credit_Info(p_line_rec, l_cust_trx_type_id, l_creation_sign);
        IF l_cust_trx_type_id = 0 THEN -- no cust_trx_type_id at line/order type
           SELECT FND_PROFILE.VALUE('OE_CREDIT_TRANSACTION_TYPE_ID')
           INTO l_cust_trx_type_id
           FROM DUAL;
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  ' CUSTOMER TRANSACTION TYPE ID FROM PROFILE ' , 5 ) ;
           END IF;
        END IF;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID ( 2 ) : '||L_CUST_TRX_TYPE_ID , 5 ) ;
        END IF;
        RETURN(l_cust_trx_type_id);
  ELSE -- Non Referenced Return Line
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'THIS IS A NON-REFERENCED RETURN LINE ' , 5 ) ;
       END IF;
     --use cache instead of SQL for bug 3975739
	 if (OE_Order_Cache.g_line_type_rec.line_type_id =  p_line_rec.Line_Type_id ) then
             l_inv_cust_trx_type_id := nvl(OE_ORDER_CACHE.g_line_type_rec.cust_trx_type_id,0);
	 else 
	     l_inv_cust_trx_type_id := 0 ;
	 end if ;
      /* SELECT NVL(lt.cust_trx_type_id, 0)
       INTO   l_inv_cust_trx_type_id
       FROM   oe_line_types_v lt
       WHERE  lt.line_type_id = p_line_rec.line_type_id; */
	-- end bug 3975739
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM LINE TYPE : '||L_INV_CUST_TRX_TYPE_ID , 5 ) ;
       END IF;
   --Bug2293944 Removed the decode statement. 
       IF l_inv_cust_trx_type_id = 0 THEN
          SELECT NVL(ot.cust_trx_type_id,0)
          INTO   l_inv_cust_trx_type_id
          FROM   oe_order_types_v ot,
                 oe_order_headers oh
          WHERE  ot.order_type_id = oh.order_type_id
          AND    oh.header_id = p_line_rec.header_id;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM ORDER TYPE: '||L_INV_CUST_TRX_TYPE_ID , 5 ) ;
          END IF;
       END IF;
       IF l_inv_cust_trx_type_id <> 0 THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'GET CREDIT MEMO TYPE ' , 5 ) ;
          END IF;
          SELECT nvl(ctt.credit_memo_type_id, 0)
          INTO l_cust_trx_type_id
          FROM ra_cust_trx_types_all ctt
          WHERE ctt.cust_trx_type_id = l_inv_cust_trx_type_id
          AND NVL(ctt.org_id, -3114) =  NVL(p_line_rec.org_id, -3114);
                       /*      DECODE(ctt.cust_trx_type_id,
                                       1, -3113,
                                       2, -3113,
                                       7, -3113,
                                       8, -3113,
                                       NVL(p_line_rec.org_id, -3114)); Commented for the bug 3027150 */
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'CREDIT MEMO TYPE FROM LINE TYPE/ORDER TYPE OF CURRENT LINE'||L_CUST_TRX_TYPE_ID , 5 ) ;
          END IF;
       END IF;
       IF l_inv_cust_trx_type_id = 0 OR l_cust_trx_type_id = 0 THEN
          SELECT NVL(FND_PROFILE.VALUE('OE_CREDIT_TRANSACTION_TYPE_ID'), 0)
          INTO l_cust_trx_type_id
          FROM DUAL;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID FROM PROFILE' , 5 ) ;
          END IF;
       END IF;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'CUSTOMER TRANSACTION TYPE ID ( 3 ) : '||L_CUST_TRX_TYPE_ID , 5 ) ;
       END IF;
       RETURN(l_cust_trx_type_id);
  END IF;
EXCEPTION
   WHEN OTHERS THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'EXCEPTION. EXITING GET_CUSTOMER_TRANSACTION_TYPE ( ) , '||SQLERRM , 1 ) ;
        END IF;
        return(0);
END Get_Customer_Transaction_Type;

PROCEDURE Get_Credit_Method_Code
(  p_line_rec IN OE_Order_Pub.Line_Rec_Type
,  x_accting_credit_method_code OUT NOCOPY VARCHAR2
,  x_invcing_credit_method_code OUT NOCOPY VARCHAR2
) IS
l_accting_credit_method_code   VARCHAR2(30):= NULL;
l_invcing_credit_method_code   VARCHAR2(30):= NULL;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'ENTERING GET_CREDIT_METHOD_CODE ( ) ' , 5 ) ;
        END IF;
        SELECT NVL(lt.accounting_credit_method_code,ot.accounting_credit_method_code),--Bug 5572355
               NVL(lt.invoicing_credit_method_code,ot.invoicing_credit_method_code)--Bug 5572355
        INTO   l_accting_credit_method_code,
               l_invcing_credit_method_code
        FROM   oe_line_types_v lt,
               oe_order_types_v ot,
               oe_order_headers oh
        WHERE  lt.line_type_id = p_line_rec.line_type_id
        AND    ot.order_type_id = oh.order_type_id
        AND    oh.header_id = p_line_rec.header_id;
        x_accting_credit_method_code := l_accting_credit_method_code;
        x_invcing_credit_method_code := l_invcing_credit_method_code;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'ACCOUNTING CREDIT METHOD CODE : '||X_ACCTING_CREDIT_METHOD_CODE , 5 ) ;
            oe_debug_pub.add(  'INVOICING CREDIT METHOD CODE : '||X_INVCING_CREDIT_METHOD_CODE , 5 ) ;
            oe_debug_pub.add(  'EXITING GET_CREDIT_METHOD_CODE ' , 5 ) ;
        END IF;
EXCEPTION
   WHEN OTHERS THEN
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'EXCEPTION. EXITING GET_CREDIT_METHOD_CODE ( ) '||SQLERRM , 1 ) ;
      END IF;
      x_accting_credit_method_code := 'LIFO';
      x_invcing_credit_method_code := 'LIFO';
END Get_Credit_Method_Code;

-- PTO RFR handling starts here
FUNCTION Is_PTO
(p_line_rec    IN OE_Order_Pub.Line_Rec_Type)
RETURN BOOLEAN
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   IF p_line_rec.model_remnant_flag = 'Y' AND
      p_line_rec.item_type_code in ('MODEL', 'CLASS', 'OPTION', 'KIT', 'INCLUDED')
   THEN
      IF (p_line_rec.item_type_code = 'OPTION' AND
          p_line_rec.ato_line_id = p_line_rec.line_id ) OR
          p_line_rec.ato_line_id is NULL
      THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THIS IS A REMNANT PTO ' , 5 ) ;
          END IF;
          RETURN TRUE;
      ELSE
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THIS IS NOT A REMNANT PTO ' , 5 ) ;
          END IF;
          RETURN FALSE;
      END IF;
   ELSE
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'THIS IS NOT REMNANT PTO ' , 5 ) ;
      END IF;
      RETURN FALSE;
   END IF;
END Is_PTO;

FUNCTION Is_Class
(p_line_id IN NUMBER)
RETURN BOOLEAN
IS
l_item_type_code VARCHAR2(30);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    SELECT item_type_code
    INTO   l_item_type_code
    FROM   OE_ORDER_LINES
    WHERE  line_id = p_line_id;
    IF  l_item_type_code = 'CLASS' THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'ITEM TYPE OF THIS LINE IS CLASS' , 5 ) ;
        END IF;
        RETURN TRUE;
    ELSE
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  ' ITEM TYPE IS NOT CLASS' , 5 ) ;
        END IF;
        RETURN FALSE;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         RETURN FALSE;
END Is_Class;

PROCEDURE RFR_Children
(p_line_id    IN NUMBER,
 x_return_code OUT NOCOPY VARCHAR2,
 x_RFR_children_tbl OUT NOCOPY Id_Tbl_Type)
IS
Cursor rfr_child is
SELECT line_id
FROM   oe_order_lines Line,
       bom_inventory_components bic
WHERE  Line.link_to_line_id = p_line_id
AND    Line.open_flag || '' = 'Y'
AND    bic.component_sequence_id = Line.component_sequence_id
AND    bic.component_item_id = Line.inventory_item_id
AND    bic.required_for_revenue = 1
ORDER BY Line.inventory_item_id;
/* the order by clause is important, do not remove!!! */
I NUMBER := 1;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   Open rfr_child;
   LOOP
     Fetch rfr_child into x_RFR_children_tbl(I);
     Exit WHEN rfr_child%NOTFOUND;
     I := I + 1;
   END LOOP;
   IF  x_RFR_children_tbl.count <> 0 THEN
       x_return_code := 'Y';
   ELSE
       x_return_code := 'N';
   END IF;
   Close rfr_child;
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'RFR CHILDREN , RETURN CODE IS '|| X_RETURN_CODE , 5 ) ;
   END IF;
END RFR_Children;

PROCEDURE RFR_Sibling
(p_link_to_line_id IN NUMBER,
 p_line_inventory_item_id IN NUMBER,
 x_return_code OUT NOCOPY VARCHAR2,
 x_RFR_sibling_tbl OUT NOCOPY Id_Tbl_Type)
IS

-- we use inventory_item_id to select
-- siblings, to prevent selecting splitted
-- lines
Cursor rfr_sibling is
SELECT line_id
FROM   oe_order_lines Line,
       bom_inventory_components bic
WHERE  Line.link_to_line_id = p_link_to_line_id
AND    Line.inventory_item_id <> p_line_inventory_item_id
AND    Line.open_flag || '' = 'Y'
AND    bic.component_sequence_id = Line.component_sequence_id
AND    bic.component_item_id = Line.inventory_item_id
AND    bic.required_for_revenue = 1
order by Line.inventory_item_id;
/* the order by clause is important, do not remove!!! */
I NUMBER := 1;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   Open rfr_sibling;
   LOOP
     Fetch rfr_sibling into x_RFR_sibling_tbl(I);
     Exit WHEN rfr_sibling%NOTFOUND;
     I := I + 1;
   END LOOP;

   IF x_RFR_sibling_tbl.count <> 0 THEN
      x_return_code := 'Y';
   ELSE
      x_return_code := 'N';
   END IF;
   Close rfr_sibling;
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'RFR SIBLING , RETURN CODE IS '|| X_RETURN_CODE , 1 ) ;
   END IF;
END RFR_Sibling;

FUNCTION Is_RFR
(p_line_id IN NUMBER)
RETURN BOOLEAN
IS
l_rfr VARCHAR2(1) := 'N';
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   SELECT 'Y'
   INTO l_rfr
   FROM oe_order_lines Line,
        bom_inventory_components bic
   WHERE Line.line_id = p_line_id
   AND Line.open_flag || '' = 'Y'
   AND bic.component_sequence_id = Line.component_sequence_id
   AND bic.component_item_id = Line.inventory_item_id
   AND bic.required_for_revenue = 1;
   IF l_rfr = 'Y' THEN
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'RFR RETURNING TRUE' , 5 ) ;
     END IF;
     RETURN TRUE;
   ELSE
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'RFR: RETURNING FALSE' , 5 ) ;
     END IF;
     RETURN FALSE;
   END IF;
EXCEPTION
    WHEN OTHERS THEN
         RETURN FALSE;
END Is_RFR;

FUNCTION Something_To_Invoice
(p_line_rec   IN OE_Order_Pub.Line_Rec_Type)
RETURN BOOLEAN IS
l_rfr_child_flag              VARCHAR2(1);
l_rfr_sibling_flag            VARCHAR2(1);
l_rfr_children_tbl            Id_Tbl_Type;
l_rfr_sibling_tbl             Id_Tbl_Type;
l_child_rec                   OE_Order_Pub.Line_Rec_type;
l_sibling_rec                 OE_Order_Pub.Line_Rec_type;
l_ratio                       NUMBER;
max_to_invoice                NUMBER;
qty_to_invoice                NUMBER;
x_qty_to_invoice              NUMBER;
i                             NUMBER;
l_child_inventory_item_id     NUMBER := 0;
l_child_total_ordered_qty     NUMBER;
l_child_total_fulfilled_qty   NUMBER;
l_sibling_inventory_item_id   NUMBER := 0;
l_sibling_total_ordered_qty   NUMBER;
l_sibling_total_fulfilled_qty NUMBER;
l_total_ordered_qty           NUMBER;
l_total_invoiced_qty          NUMBER;
l_overship_invoice_basis      VARCHAR2(30);
x_result_code                 VARCHAR2(240);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'RFR: IN SOMETHING_TO_INVOICE' , 5 ) ;
         END IF;
         IF (nvl(p_line_rec.ordered_quantity, 0) > nvl(p_line_rec.fulfilled_quantity, 0)) THEN
            qty_to_invoice := nvl(p_line_rec.ordered_quantity,0);
            x_qty_to_invoice := nvl(p_line_rec.ordered_quantity,0);
         ELSE -- initialize for overshipment cases
	        qty_to_invoice := nvl(p_line_rec.fulfilled_quantity,0);
            x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0);
         END IF;
         RFR_Children(p_line_rec.line_id, l_rfr_child_flag, l_rfr_children_tbl);
         IF (l_rfr_child_flag = 'Y') THEN
            FOR i IN 1..l_rfr_children_tbl.count LOOP
                OE_Line_Util.Query_Row(p_line_id => l_rfr_children_tbl(i), x_line_rec => l_child_rec);
                IF l_child_rec.inventory_item_id <> l_child_inventory_item_id then
                   l_child_inventory_item_id := l_child_rec.inventory_item_id;
                   select nvl(sum(ordered_quantity), 0), nvl(sum(fulfilled_quantity), 0)
                   into   l_child_total_ordered_qty, l_child_total_fulfilled_qty
                   from   oe_order_lines
                   where  link_to_line_id = p_line_rec.line_id
                   and    inventory_item_id = l_child_inventory_item_id;
                   l_ratio := nvl(p_line_rec.ordered_quantity,0) / l_child_total_ordered_qty;
                   -- ordered_quantity must be according to ratio
                   Select Floor(nvl(l_child_total_fulfilled_qty, 0) * nvl(p_line_rec.ordered_quantity,0) / l_child_total_ordered_qty)
                   Into   max_to_invoice
                   From   dual;
                   IF max_to_invoice < qty_to_invoice THEN
                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  'RFR: MAX_TO_INVOICE < QTY_TO_INVOICE' , 5 ) ;
                      END IF;
                      qty_to_invoice := max_to_invoice;
                   END IF;
                  END IF; --if this is a new inventory_item_id
               END LOOP;
               IF nvl(p_line_rec.fulfilled_quantity,0) <= qty_to_invoice THEN
                  x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0);
               ELSIF nvl(p_line_rec.fulfilled_quantity, 0) > qty_to_invoice
                     AND qty_to_invoice < p_line_rec.ordered_quantity THEN
                     x_qty_to_invoice := qty_to_invoice - nvl(p_line_rec.invoiced_quantity, 0);
               ELSE -- full or overshipment
                  l_overship_invoice_basis := Get_Overship_Invoice_Basis(p_line_rec);
                  IF l_overship_invoice_basis = 'ORDERED' THEN
                     x_qty_to_invoice := qty_to_invoice - nvl(p_line_rec.invoiced_quantity, 0);
                  ELSE
                     x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0);
                  END IF;
               END IF;
          END IF;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'RFR: FINISH CHECK CHILDREN' , 5 ) ;
          END IF;
          IF IS_CLASS(p_line_rec.link_to_line_id) THEN
               RFR_Sibling(p_line_rec.link_to_line_id,
                           p_line_rec.inventory_item_id,
                           l_rfr_sibling_flag, l_rfr_sibling_tbl);
               IF (l_rfr_sibling_flag = 'Y') THEN
                   FOR i IN 1..l_rfr_sibling_tbl.count LOOP
                      OE_Line_Util.Query_Row(p_line_id => l_rfr_sibling_tbl(i), x_line_rec =>l_sibling_rec );
                      IF l_sibling_rec.inventory_item_id <> l_sibling_inventory_item_id THEN
                         l_sibling_inventory_item_id := l_sibling_rec.inventory_item_id;
                         select nvl(sum(ordered_quantity), 0), nvl(sum(fulfilled_quantity), 0)
                         into   l_sibling_total_ordered_qty, l_sibling_total_fulfilled_qty
                         from   oe_order_lines
                         where  link_to_line_id = p_line_rec.link_to_line_id
                         and    inventory_item_id = l_sibling_inventory_item_id;
                         -- current line may be splitted from the original line
                         -- just like the sibling line may be splitted
                         select nvl(sum(ordered_quantity), 0), nvl(sum(invoiced_quantity), 0)
                         into   l_total_ordered_qty, l_total_invoiced_qty
                         from   oe_order_lines
                         where  link_to_line_id = p_line_rec.link_to_line_id
                         and    inventory_item_id = p_line_rec.inventory_item_id;
                         l_ratio := l_total_ordered_qty / l_sibling_total_ordered_qty;
                         -- ordered_quantity must be according to ratio
                         Select Floor(nvl(l_sibling_total_fulfilled_qty, 0) * l_total_ordered_qty / l_sibling_total_ordered_qty)
                         Into   max_to_invoice
                         From   dual;
                         IF max_to_invoice < qty_to_invoice THEN
                            qty_to_invoice := max_to_invoice;
                         END IF;
                      END IF; -- new inventory_item_id
                   END LOOP;
                   IF l_total_invoiced_qty < qty_to_invoice THEN
                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  'RFR: FULFILL < QTY_TO_INVOICE' , 4 ) ;
                      END IF;
                      IF (nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0)) <= (qty_to_invoice - l_total_invoiced_qty)
                         AND (nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0) < x_qty_to_invoice)  THEN
                            x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0);
                      ELSIF (nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0)) > (qty_to_invoice - l_total_invoiced_qty)
                      AND (qty_to_invoice - l_total_invoiced_qty < x_qty_to_invoice)
                      AND qty_to_invoice < l_total_ordered_qty THEN
                          x_qty_to_invoice := qty_to_invoice - l_total_invoiced_qty;
                          x_result_code := 'RFR-PENDING';
                      ELSIF (nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0)) > (qty_to_invoice - l_total_invoiced_qty)
                      AND (qty_to_invoice - l_total_invoiced_qty < x_qty_to_invoice)
                      AND qty_to_invoice >= l_total_ordered_qty THEN -- overshipment
                          l_overship_invoice_basis := Get_Overship_Invoice_Basis(p_line_rec);
                          IF l_overship_invoice_basis = 'ORDERED' THEN
                             x_qty_to_invoice := qty_to_invoice - l_total_invoiced_qty;
                          ELSE
                            x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0);
                          END IF;
                      END IF;
                  END IF;
               END IF;
          END IF;
          IF    nvl(p_line_rec.fulfilled_quantity, 0) <= qty_to_invoice THEN
                x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0);
          ELSIF nvl(p_line_rec.fulfilled_quantity, 0) > qty_to_invoice
                AND qty_to_invoice < nvl(p_line_rec.ordered_quantity, 0) THEN
                x_qty_to_invoice := qty_to_invoice - nvl(p_line_rec.invoiced_quantity, 0);
          ELSE -- full or overshipment
                l_overship_invoice_basis := Get_Overship_Invoice_Basis(p_line_rec);
                IF l_overship_invoice_basis = 'ORDERED' THEN
                   x_qty_to_invoice := qty_to_invoice - nvl(p_line_rec.invoiced_quantity, 0);
                ELSE
                   x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0);
                END IF;
          END IF;
          IF x_qty_to_invoice > 0 THEN
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  ' SOMETHING_TO_INVOICE: RETURNING TRUE' , 5 ) ;
              END IF;
              RETURN TRUE;
          ELSE
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  ' SOMETHING_TO_INVOICE: RETURNING FALSE' , 5 ) ;
              END IF;
              RETURN FALSE;
          END IF;
END Something_To_Invoice;

PROCEDURE Get_Regular_Qty_To_Invoice
(  p_line_rec    IN OE_Order_Pub.Line_Rec_Type
,  x_regular_qty_to_invoice   OUT NOCOPY NUMBER
)
IS
l_overship_invoice_basis  VARCHAR2(30);
l_fulfilled_qty  NUMBER;

-- changes for bug 3728587 start
l_unsplit_ordered_qty NUMBER;
l_unsplit_fulfilled_qty NUMBER;
l_unsplit_invoiced_qty NUMBER;
l_temp NUMBER;
l_set_type      VARCHAR2(30);
-- changes for bug 3728587 end

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    -- This may subject to change based on fulfillment design
    -- This may subject to change for required for revenue cases as there are
    -- chances for partial invoicing (should be looking at invoiced_quantity)
    
     -- changes for bug 3728587 start
        --check if line is splitted or not
        if(p_line_rec.line_set_id is not null) then
                select set_type into l_set_type from oe_sets where set_id = p_line_rec.line_set_id;
        end if;
        oe_debug_pub.add('l_set_type = '||l_set_type, 5 ) ;

        if(l_set_type = 'SPLIT') then
                -- line is splitted
                -- get the total amounts
                select sum(nvl(ordered_quantity,0)), sum(nvl(fulfilled_quantity,nvl(shipped_quantity,0))), sum(nvl(invoiced_quantity,0))
                into l_unsplit_ordered_qty ,  l_unsplit_fulfilled_qty, l_unsplit_invoiced_qty
                from oe_order_lines_all where header_id = p_line_rec.header_id and line_set_id = p_line_rec.line_set_id;
        else
                l_unsplit_ordered_qty := nvl(p_line_rec.ordered_quantity,0);
                l_unsplit_fulfilled_qty := nvl(p_line_rec.fulfilled_quantity,nvl(p_line_rec.shipped_quantity,0));
                l_unsplit_invoiced_qty := nvl(p_line_rec.invoiced_quantity,0);
        end if;
     -- changes for bug 3728587 end;
 
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER TO GET REGULAR QUANTITY TO INVOICE ' , 5 ) ;
        oe_debug_pub.add(  'FULFILLED QUANTITY = '|| TO_CHAR ( P_LINE_REC.FULFILLED_QUANTITY ) , 5 ) ;
        oe_debug_pub.add(  'SHIPPED QUANTITY = '|| TO_CHAR ( P_LINE_REC.SHIPPED_QUANTITY ) , 5 ) ;
        oe_debug_pub.add(  'ORDERED QUANTITY = '|| TO_CHAR ( P_LINE_REC.ORDERED_QUANTITY ) , 5 ) ;
                 -- changes for bug 3728587 end;
        oe_debug_pub.add(  'UNSPLIT ORDERED QUANTITY = '|| TO_CHAR ( l_unsplit_ordered_qty ) , 5 ) ;
        oe_debug_pub.add(  'UNSPLIT FULFILLED QUANTITY = '|| TO_CHAR ( l_unsplit_fulfilled_qty ) , 5 ) ;
        oe_debug_pub.add(  'UNSPLIT INVOICED QUANTITY = '|| TO_CHAR ( l_unsplit_invoiced_qty ) , 5 ) ;
                -- changes for bug 3728587 end; 
   END IF;

    IF p_line_rec.shipped_quantity IS NOT NULL THEN
      -- calculate quantity to invoice based on ship tolerances
      -- If we ship less than ship tolerance below, then the line will be split.
      l_fulfilled_qty := NVL(p_line_rec.fulfilled_quantity, NVL(p_line_rec.shipped_quantity, 0));
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'L_FULFILLED_QUANTITY = '|| L_FULFILLED_QTY , 5 ) ;
      END IF;
          -- changes for bug 3728587 start 
      -- IF (l_fulfilled_qty <= nvl(p_line_rec.ordered_quantity, 0)) then
      IF (l_unsplit_fulfilled_qty <= nvl(l_unsplit_ordered_qty, 0)) then
          -- changes for bug 3728587 end 
          x_regular_qty_to_invoice := l_fulfilled_qty - NVL(p_line_rec.invoiced_quantity, 0);
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'EXIT CALCUALTE_QTY_TO_INVOICE ( 1 ) : '||X_REGULAR_QTY_TO_INVOICE , 5 ) ;
          END IF;
          RETURN;
          -- changes for bug 3728587 start 
      -- ELSIF ( l_fulfilled_qty > NVL(p_line_rec.ordered_quantity, 0)
      --		    AND (l_fulfilled_qty < (NVL(p_line_rec.ordered_quantity, 0) + (NVL(p_line_rec.ordered_quantity, 0) * NVL(p_line_rec.ship_tolerance_above, 0)))) ) THEN
      ELSIF ( l_unsplit_fulfilled_qty > NVL(l_unsplit_ordered_qty, 0)
                 AND (l_unsplit_fulfilled_qty <= (NVL(l_unsplit_ordered_qty, 0) + ((NVL(l_unsplit_ordered_qty, 0) * NVL(p_line_rec.ship_tolerance_above, 0))/100))) ) THEN
          -- changes for bug 3728587 end 
               l_overship_invoice_basis := Get_Overship_Invoice_Basis(p_line_rec);
          IF l_overship_invoice_basis = 'ORDERED' THEN
             x_regular_qty_to_invoice := NVL(p_line_rec.ordered_quantity, 0) - NVL(p_line_rec.invoiced_quantity, 0);
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'EXIT CALCUALTE_QTY_TO_INVOICE ( 2 ) : '||X_REGULAR_QTY_TO_INVOICE , 1 ) ;
             END IF;
             RETURN;
          ELSE   -- 'SHIPPED'
             x_regular_qty_to_invoice := l_fulfilled_qty - NVL(p_line_rec.invoiced_quantity, 0);
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'EXIT CALCUALTE_QTY_TO_INVOICE ( 3 ) : '||X_REGULAR_QTY_TO_INVOICE , 5 ) ;
             END IF;
             RETURN;
          END IF;
       ELSE  -- overshipped (> ordered +tolerance), we only invoice up to the ordered + tolerance. user should manually handle the outstanding qtys
             -- changes for bug 3728587 start
             -- x_regular_qty_to_invoice := NVL(p_line_rec.ordered_quantity, 0) + (NVL(p_line_rec.ordered_quantity, 0) * NVL(p_line_rec.ship_tolerance_above, 0)) - NVL(p_line_rec.invoiced_quantity, 0);
            
             l_temp := NVL(l_unsplit_ordered_qty, 0) + ((NVL(l_unsplit_ordered_qty, 0) * NVL(p_line_rec.ship_tolerance_above, 0))/100) - NVL(l_unsplit_invoiced_qty, 0);
                         -- select min of l_temp and l_fulfilled_qty
                         if(l_temp<l_fulfilled_qty) then
                                x_regular_qty_to_invoice := l_temp;
                         else
                                x_regular_qty_to_invoice := l_fulfilled_qty;
                         end if;
             -- changes for bug 3728587 end 
             -- Issue Message here. (overshipment above tolerance should be invoiced manually)
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'QUANTITY TO INVOICE AT ( 4 ) = ' || TO_CHAR ( X_REGULAR_QTY_TO_INVOICE ) , 5 ) ;
             END IF;
             FND_MESSAGE.SET_NAME('ONT','OE_MANUAL_INVOICE_OVERSHIP_QTY');
             OE_MSG_PUB.ADD;
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'EXIT CALCUALTE_QTY_TO_INVOICE ( 4 ) : '||X_REGULAR_QTY_TO_INVOICE , 5 ) ;
             END IF;
             RETURN;
       END IF;
    ELSE  -- no ship cycle
       l_fulfilled_qty := NVL(p_line_rec.fulfilled_quantity, NVL(p_line_rec.shipped_quantity, NVL(p_line_rec.ordered_quantity, 0)));
       x_regular_qty_to_invoice := l_fulfilled_qty - NVL(p_line_rec.invoiced_quantity, 0);
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'EXIT CALCUALTE_QTY_TO_INVOICE ( 5 ) : '||X_REGULAR_QTY_TO_INVOICE , 5 ) ;
       END IF;
       RETURN;
    END IF;
END Get_Regular_Qty_To_Invoice;
-- new OUT parameter x_return_code
PROCEDURE Get_Qty_To_Invoice
(p_line_rec    IN OE_Order_Pub.Line_Rec_Type
,  x_qty_to_invoice   OUT NOCOPY NUMBER
,  x_result_code OUT NOCOPY VARCHAR2
)
IS
l_rfr_child_flag              VARCHAR2(1);
l_rfr_sibling_flag            VARCHAR2(1);
l_rfr_children_tbl            Id_Tbl_Type;
l_rfr_sibling_tbl             Id_Tbl_Type;
l_line_rec                    OE_Order_Pub.Line_Rec_Type;
l_child_rec                   OE_Order_Pub.Line_Rec_Type;
l_sibling_rec                 OE_Order_Pub.Line_Rec_Type;
l_ratio                       NUMBER;
max_to_invoice                NUMBER := 0;
qty_to_invoice                NUMBER := 0;
l_child_inventory_item_id     NUMBER := 0;
l_child_total_ordered_qty     NUMBER := 0;
l_child_total_fulfilled_qty   NUMBER := 0;
l_sibling_inventory_item_id   NUMBER := 0;
l_sibling_total_ordered_qty   NUMBER := 0;
l_sibling_total_fulfilled_qty NUMBER := 0;
l_total_ordered_qty           NUMBER := 0;
l_total_invoiced_qty          NUMBER := 0;
l_total_fulfilled_qty         NUMBER := 0;
l_overship_invoice_basis      VARCHAR2(30);
i                             NUMBER;
l_fulfilled_qty               NUMBER;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER TO GET QUANTITY TO INVOICE ( ) ' , 5 ) ;
    END IF;
    x_result_code := 'NORMAL';
    l_fulfilled_qty := NVL(p_line_rec.fulfilled_quantity, NVL(p_line_rec.shipped_quantity, NVL(p_line_rec.ordered_quantity, 0)));
    IF Is_PTO(p_line_rec) THEN
         IF (nvl(p_line_Rec.ordered_quantity, 0) > l_fulfilled_qty) THEN
             qty_to_invoice := nvl(p_line_rec.ordered_quantity, 0);
             x_qty_to_invoice := nvl(p_line_rec.ordered_quantity, 0);
         ELSE -- initialize for overshipment cases
	         qty_to_invoice := l_fulfilled_qty;
             x_qty_to_invoice := l_fulfilled_qty;
         END IF;
         RFR_Children(p_line_rec.line_id, l_rfr_child_flag, l_rfr_children_tbl);
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'RFR: QTY_TO_INVOICE: '||QTY_TO_INVOICE ||' L_RFR_CHILD_FLAG: '|| L_RFR_CHILD_FLAG , 5 ) ;
         END IF;
           IF (l_rfr_child_flag = 'Y') THEN
               FOR i IN 1..l_rfr_children_tbl.count LOOP
                   -- l_rfr_children_tbl is ordered by inventory_item_id
                   -- so same inventory_item_id will come next to each other
                   OE_Line_Util.Query_Row(p_line_id => l_rfr_children_tbl(i), x_line_rec => l_child_rec);
                   IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'RFR: L_CHILD_REC.LINE_ID: '||L_CHILD_REC.LINE_ID ||' L_CHILD_REC.INVENTORY_ITEM_ID: '|| L_CHILD_REC.INVENTORY_ITEM_ID , 5 ) ;
                   END IF;
                   IF l_child_rec.inventory_item_id <> l_child_inventory_item_id then
                      l_child_inventory_item_id := l_child_rec.inventory_item_id;
                      select nvl(sum(ordered_quantity), 0), nvl(sum(fulfilled_quantity), 0)
                      into   l_child_total_ordered_qty, l_child_total_fulfilled_qty
                      from   oe_order_lines
                      where  link_to_line_id = p_line_rec.line_id
                      and    inventory_item_id = l_child_inventory_item_id;
                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  'RFR: L_CHILD_TOTAL_ORDERED_QTY: '||L_CHILD_TOTAL_ORDERED_QTY||' L_CHILD_TOTAL_FULFILLED_QTY:'||L_CHILD_TOTAL_FULFILLED_QTY , 5 ) ;
                      END IF;
                      l_ratio := nvl(p_line_rec.ordered_quantity, 0) / l_child_total_ordered_qty;
                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  'RFR:L_RATIO :'||L_RATIO , 5 ) ;
                      END IF;
                      -- ordered_quantity must be according to ratio
                      Select Floor(nvl(l_child_total_fulfilled_qty, 0) * nvl(p_line_rec.ordered_quantity, 0) / l_child_total_ordered_qty)
                      Into   max_to_invoice
                      From   dual;
                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  'RFR:MAX_TO_INVOICE: '||MAX_TO_INVOICE , 5 ) ;
                      END IF;
                      IF max_to_invoice < qty_to_invoice THEN
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'RFR: MAX_TO_INVOICE < QTY_TO_INVOICE' , 5 ) ;
                         END IF;
                         qty_to_invoice := max_to_invoice;
                      END IF;
                   END IF; -- if this is a new inventory_item_id
               END LOOP;
               IF l_debug_level  > 0 THEN
                   oe_debug_pub.add(  'RFR:FULFILLED_QUANTITY: '||P_LINE_REC.FULFILLED_QUANTITY||' QTY_TO_INVOICE:'||QTY_TO_INVOICE , 4 ) ;
               END IF;
               IF nvl(p_line_rec.fulfilled_quantity, 0) <= qty_to_invoice THEN
                  x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0);
                  IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  ' ( 1 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
                  END IF;
                  IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  ' NOT SETTING TO RFR-PENDING' , 5 ) ;
                  END IF;
               ELSIF nvl(p_line_rec.fulfilled_quantity, 0) > qty_to_invoice
                     AND qty_to_invoice < nvl(p_line_rec.ordered_quantity, 0) THEN
                  x_qty_to_invoice := qty_to_invoice - nvl(p_line_rec.invoiced_quantity, 0);
                  IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  ' ( 2 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
                      oe_debug_pub.add(  'SET X_RESULT_CODE -> RFR-PENDING' , 5 ) ;
                  END IF;
                  x_result_code := 'RFR-PENDING';
               ELSE -- full or overshipment
                  l_overship_invoice_basis := Get_Overship_Invoice_Basis(p_line_rec);
                  IF l_overship_invoice_basis = 'ORDERED' THEN
                     x_qty_to_invoice := qty_to_invoice - nvl(p_line_rec.invoiced_quantity, 0);
                     IF l_debug_level  > 0 THEN
                         oe_debug_pub.add(  ' ( 3 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
                     END IF;
                  ELSE
                     x_qty_to_invoice := nvl(p_line_rec.fulfilled_quantity, 0) - nvl(p_line_rec.invoiced_quantity, 0);
                     IF l_debug_level  > 0 THEN
                         oe_debug_pub.add(  ' ( 4 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
                     END IF;
                  END IF;
               END IF;
          ELSE -- no rfr children
               Get_Regular_Qty_To_Invoice(p_line_rec, x_qty_to_invoice);
               IF l_debug_level  > 0 THEN
                   oe_debug_pub.add(  ' ( 5 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
               END IF;
          END IF;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'RFR: FINISH CHECK CHILDREN' , 5 ) ;
          END IF;

          -- fix for bug 2516823
          IF IS_CLASS(p_line_rec.link_to_line_id) THEN
             RFR_Sibling(p_line_rec.link_to_line_id
                        ,p_line_rec.inventory_item_id
                        ,l_rfr_sibling_flag
                        ,l_rfr_sibling_tbl);
             IF l_rfr_sibling_flag = 'Y' THEN
                FOR i IN 1..l_rfr_sibling_tbl.count LOOP
                    OE_Line_Util.Query_Row(p_line_id => l_rfr_sibling_tbl(i)
                                          ,x_line_rec => l_sibling_rec);
                       IF l_debug_level  > 0 THEN
                           oe_debug_pub.add(  'RFR:L_SIBLING_REC.LINE_ID: ' ||L_SIBLING_REC.LINE_ID ||' L_SIBLING_REC.INVENTORY_ITEM_ID:' ||L_SIBLING_REC.INVENTORY_ITEM_ID , 3 ) ;
                       END IF;
                    IF l_sibling_rec.inventory_item_id <> l_sibling_inventory_item_id THEN
                       l_sibling_inventory_item_id := l_sibling_rec.inventory_item_id;
                       SELECT NVL(SUM(ordered_quantity),0)
                             ,NVL(SUM(fulfilled_quantity),0)
                       INTO   l_sibling_total_ordered_qty
                             ,l_sibling_total_fulfilled_qty
                       FROM  oe_order_lines
                       WHERE link_to_line_id = p_line_rec.link_to_line_id
                       AND   inventory_item_id = l_sibling_inventory_item_id;
                       
                       -- current line may be splitted from the original line
                       -- just like the sibling line may be splitted
                  
                       SELECT NVL(SUM(ordered_quantity),0)
                             ,NVL(SUM(invoiced_quantity),0)
                             ,NVL(SUM(fulfilled_quantity),0)
                       INTO  l_total_ordered_qty
                            ,l_total_invoiced_qty
                            ,l_total_fulfilled_qty
                       FROM  oe_order_lines
                       WHERE link_to_line_id = p_line_rec.link_to_line_id
                       AND   inventory_item_id = p_line_rec.inventory_item_id;

                       l_ratio := l_total_ordered_qty/l_sibling_total_ordered_qty;
                        -- ordered_quantity must be according to ratio
                       max_to_invoice := FLOOR(nvl(l_sibling_total_fulfilled_qty,0) *l_total_ordered_qty / l_sibling_total_ordered_qty);
                       IF l_debug_level  > 0 THEN
                           oe_debug_pub.add(  'MAX_TO_INVOICE:'||MAX_TO_INVOICE||':QTY_TO_INVOICE:'||QTY_TO_INVOICE ) ;
                       END IF;
                       IF max_to_invoice < qty_to_invoice THEN
                          qty_to_invoice := max_to_invoice;
                       END IF;
                     END IF; -- new inventory_item_id
                   END LOOP;

                   IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'L_TOTAL_INVOICED_QTY:'||L_TOTAL_INVOICED_QTY , 5 ) ;
                       oe_debug_pub.add(  'L_TOTAL_FULFILLED_QTY:'||L_TOTAL_FULFILLED_QTY , 5 ) ;
                       oe_debug_pub.add(  'QTY_TO_INVOICE:'||QTY_TO_INVOICE , 5 ) ;
                   END IF;
 
                   IF l_total_fulfilled_qty <= qty_to_invoice THEN
                      x_qty_to_invoice := l_total_fulfilled_qty
                                          - l_total_invoiced_qty;
                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  ' ( 5 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
                      END IF;
                   ELSIF l_total_fulfilled_qty - l_total_invoiced_qty 
                         > qty_to_invoice 
                     AND qty_to_invoice <l_total_ordered_qty THEN
                         x_qty_to_invoice 
                           := qty_to_invoice - l_total_invoiced_qty;
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  ' ( 6 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
                         END IF;
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'SET X_RESULT_CODE -> RFR-PENDING' , 5 ) ;
                         END IF;
                         x_result_code := 'RFR-PENDING';
                   ELSE
                       l_overship_invoice_basis := Get_Overship_Invoice_Basis(p_line_rec);
                       IF l_overship_invoice_basis = 'ORDERED' THEN
                         x_qty_to_invoice := qty_to_invoice - l_total_invoiced_qty;
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  ' ( 7 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
                         END IF;
                       ELSE
                         x_qty_to_invoice := l_total_fulfilled_qty - l_total_invoiced_qty;
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  ' ( 8 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
                         END IF;
                       END IF;
                    END IF;
           --  ELSE -- no siblings
           --    Get_Regular_Qty_To_Invoice(p_line_rec, x_qty_to_invoice);
             END IF;
          END IF;
    ELSE -- not pto
       Get_Regular_Qty_To_Invoice(p_line_rec, x_qty_to_invoice);
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  ' ( 9 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
       END IF;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  ' ( 10 ) QUANTITY TO INVOICE : '||X_QTY_TO_INVOICE , 5 ) ;
    END IF;
END Get_Qty_To_Invoice;

FUNCTION Validate_Required_Attributes
(  p_line_rec             IN   OE_Order_Pub.Line_Rec_Type
,  p_interface_line_rec   IN   RA_Interface_Lines_Rec_Type
)
RETURN BOOLEAN
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'VALIDATING REQUIRED ATTRIBUTES' , 5 ) ;
   END IF;
   -- Check For all Required Attributes
   IF    p_interface_line_rec.Batch_Source_Name IS NULL THEN
         FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_ATTR_REQUIRED');
	     FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Batch_Source_Name');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE BATCH SOURCE NAME IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_interface_line_rec.Set_Of_Books_Id IS NULL THEN
	     FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_ATTR_REQUIRED');
	     FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Set_Of_Books_Id');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE SET OF BOOKS ID IS MISSING ' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_interface_line_rec.Line_Type IS NULL THEN
	     FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_ATTR_REQUIRED');
	     FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Line_Type');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE LINE TYPE IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_interface_line_rec.Description IS NULL THEN
	     FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_ATTR_REQUIRED');
	     FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Description');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE DESCRIPTION IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_interface_line_rec.Currency_Code IS NULL THEN
	     FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_ATTR_REQUIRED');
	     FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Currency_Code');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE CURRENCY CODE IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_interface_line_rec.Conversion_Type IS NULL THEN
	     FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_ATTR_REQUIRED');
	     FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Conversion_Type');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE CONVERSION TYPE IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_line_rec.commitment_id IS NULL AND
	    (p_interface_line_rec.Cust_Trx_Type_Id IS NULL OR
         p_interface_line_rec.Cust_Trx_Type_Id = 0) THEN
         FND_MESSAGE.SET_NAME('ONT','OE_INVOICING_ATTR_REQUIRED');
         FND_MESSAGE.SET_TOKEN('ATTRIBUTE','Cust_Trx_Type_Id');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE CUSTOMER TRX TYPE ID IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_interface_line_rec.ACCOUNTING_RULE_DURATION = -1 THEN
         -- Appropriate message was already posted for bug#3965665
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE ACCOUNTING RULE DURATION IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_interface_line_rec.customer_bank_account_id = -1 THEN
         FND_MESSAGE.SET_NAME('ONT','OE_VPM_CC_ACCT_NOT_SET');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE CUSTOMER CREDIT CARD BANK ACCOUNT IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;
   ELSIF p_interface_line_rec.customer_bank_account_id > 0
         AND p_interface_line_rec.receipt_method_id IS NULL THEN
	     FND_MESSAGE.SET_NAME('ONT','OE_VPM_NO_PAY_METHOD');
         OE_MSG_PUB.ADD;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'REQUIRED ATTRIBUTE PAYMENT METHOD IS MISSING' , 1 ) ;
         END IF;
         RETURN FALSE;

         /* ELSIF  -- will be updated with list of mandatory and conditionally required attributes
           Mandatory Columns:
           Batch_Source_Name
           Set_Of_Books_Id
           Line_Type
           Description
           Currency_Code
           Conversion_Type

           Optional columns:
           Term_Id is required for non credit transactions
           IF any thing is missing THEN
              -- Issue error message here
              RETURN FALSE;*/
   ELSE
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'EXIT VALIDATE REQUIRED ATTRIBUTES ( ) ' , 1 ) ;
          END IF;
          RETURN TRUE;
   END IF;
END Validate_Required_Attributes;

PROCEDURE Header_Invoicing_Validation
(p_header_id  IN NUMBER)
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   /*
   -- Following may be a result of wrong workflow setup
   if atleast one line is not ready for Invoicing then
      issue error message
   elsif atleast one line is already invoiced then
      issue error message
   Add any other validation here
   */
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'ENTERING HEADER_INVOICING_VALIDATION' ) ;
   END IF;
   NULL;
END Header_Invoicing_Validation;

PROCEDURE Query_Line_Scredits
( p_line_id          IN NUMBER
, p_quota_flag       IN VARCHAR2
, x_line_scredit_tbl IN OUT NOCOPY OE_Order_Pub.Line_Scredit_Tbl_Type
, x_total_percent OUT NOCOPY NUMBER --FP bug 3872157
) IS
l_Line_Scredit_rec OE_Order_PUB.Line_Scredit_Rec_Type;
CURSOR l_Line_Scredit_csr IS
    SELECT  SC.ATTRIBUTE1
    ,       SC.ATTRIBUTE10
    ,       SC.ATTRIBUTE11
    ,       SC.ATTRIBUTE12
    ,       SC.ATTRIBUTE13
    ,       SC.ATTRIBUTE14
    ,       SC.ATTRIBUTE15
    ,       SC.ATTRIBUTE2
    ,       SC.ATTRIBUTE3
    ,       SC.ATTRIBUTE4
    ,       SC.ATTRIBUTE5
    ,       SC.ATTRIBUTE6
    ,       SC.ATTRIBUTE7
    ,       SC.ATTRIBUTE8
    ,       SC.ATTRIBUTE9
    ,       SC.CONTEXT
    ,       SC.CREATED_BY
    ,       SC.CREATION_DATE
    ,       SC.DW_UPDATE_ADVICE_FLAG
    ,       SC.HEADER_ID
    ,       SC.LAST_UPDATED_BY
    ,       SC.LAST_UPDATE_DATE
    ,       SC.LAST_UPDATE_LOGIN
    ,       SC.LINE_ID
    ,       SC.PERCENT
    ,       SC.SALESREP_ID
    ,       SC.sales_credit_type_id
    ,       SC.SALES_CREDIT_ID
    ,       SC.WH_UPDATE_DATE
--SG{
    ,       SC.SALES_GROUP_ID
--SG}
    ,       SC.LOCK_CONTROL
    FROM    OE_SALES_CREDITS SC
    ,       OE_SALES_CREDIT_TYPES SCT
    WHERE   SC.sales_credit_type_id = sct.sales_credit_type_id
    AND     SCT.quota_flag = p_quota_flag
    AND     SC.line_id = p_line_id;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTERING QUERY_LINE_SCREDITS' , 5 ) ;
    END IF;
    -- Initialize table so that it clears previous records
    x_line_scredit_tbl.DELETE;

    --FP bug 3872157
    x_total_percent := 0;
    
    --  Loop over fetched records
    FOR l_implicit_rec IN l_Line_Scredit_csr LOOP
        l_Line_Scredit_rec.attribute1  := l_implicit_rec.ATTRIBUTE1;
        l_Line_Scredit_rec.attribute10 := l_implicit_rec.ATTRIBUTE10;
        l_Line_Scredit_rec.attribute11 := l_implicit_rec.ATTRIBUTE11;
        l_Line_Scredit_rec.attribute12 := l_implicit_rec.ATTRIBUTE12;
        l_Line_Scredit_rec.attribute13 := l_implicit_rec.ATTRIBUTE13;
        l_Line_Scredit_rec.attribute14 := l_implicit_rec.ATTRIBUTE14;
        l_Line_Scredit_rec.attribute15 := l_implicit_rec.ATTRIBUTE15;
        l_Line_Scredit_rec.attribute2  := l_implicit_rec.ATTRIBUTE2;
        l_Line_Scredit_rec.attribute3  := l_implicit_rec.ATTRIBUTE3;
        l_Line_Scredit_rec.attribute4  := l_implicit_rec.ATTRIBUTE4;
        l_Line_Scredit_rec.attribute5  := l_implicit_rec.ATTRIBUTE5;
        l_Line_Scredit_rec.attribute6  := l_implicit_rec.ATTRIBUTE6;
        l_Line_Scredit_rec.attribute7  := l_implicit_rec.ATTRIBUTE7;
        l_Line_Scredit_rec.attribute8  := l_implicit_rec.ATTRIBUTE8;
        l_Line_Scredit_rec.attribute9  := l_implicit_rec.ATTRIBUTE9;
        l_Line_Scredit_rec.context     := l_implicit_rec.CONTEXT;
        l_Line_Scredit_rec.created_by  := l_implicit_rec.CREATED_BY;
        l_Line_Scredit_rec.creation_date := l_implicit_rec.CREATION_DATE;
        l_Line_Scredit_rec.dw_update_advice_flag := l_implicit_rec.DW_UPDATE_ADVICE_FLAG;
        l_Line_Scredit_rec.header_id   := l_implicit_rec.HEADER_ID;
        l_Line_Scredit_rec.last_updated_by := l_implicit_rec.LAST_UPDATED_BY;
        l_Line_Scredit_rec.last_update_date := l_implicit_rec.LAST_UPDATE_DATE;
        l_Line_Scredit_rec.last_update_login := l_implicit_rec.LAST_UPDATE_LOGIN;
        l_Line_Scredit_rec.line_id     := l_implicit_rec.LINE_ID;
        l_Line_Scredit_rec.percent     := l_implicit_rec.PERCENT;
        l_Line_Scredit_rec.salesrep_id := l_implicit_rec.SALESREP_ID;
        l_Line_Scredit_rec.sales_credit_type_id := l_implicit_rec.sales_credit_type_id;
        l_Line_Scredit_rec.sales_credit_id := l_implicit_rec.SALES_CREDIT_ID;
        l_Line_Scredit_rec.wh_update_date := l_implicit_rec.WH_UPDATE_DATE;
        --SG{
        l_Line_Scredit_rec.sales_group_id:=l_implicit_rec.sales_group_id;
        --SG}
        l_Line_Scredit_rec.lock_control := l_implicit_rec.LOCK_CONTROL;
        x_Line_Scredit_tbl(x_Line_Scredit_tbl.COUNT + 1) := l_Line_Scredit_rec;
	--FP bug 3872157 
	x_total_percent := x_total_percent + l_implicit_rec.PERCENT;	
    END LOOP;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXITING QUERY_LINE_SCREDITS' , 5 ) ;
    END IF;
EXCEPTION
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    WHEN OTHERS THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXCEPTION , QUERY LINE SALES CREDITS '||SQLERRM , 1 ) ;
         END IF;
         IF oe_msg_pub.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
         THEN
            oe_msg_pub.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Query_Line_Scredits'
            );
         END IF;
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Query_Line_Scredits;

PROCEDURE Query_Header_Scredits
( p_header_id IN NUMBER
, p_quota_flag  IN VARCHAR2
, x_header_scredit_tbl IN OUT NOCOPY OE_Order_Pub.Header_Scredit_Tbl_Type
) IS
l_Header_Scredit_rec            OE_Order_PUB.Header_Scredit_Rec_Type;
CURSOR l_Header_Scredit_csr IS
    SELECT  SC.ATTRIBUTE1
    ,       SC.ATTRIBUTE10
    ,       SC.ATTRIBUTE11
    ,       SC.ATTRIBUTE12
    ,       SC.ATTRIBUTE13
    ,       SC.ATTRIBUTE14
    ,       SC.ATTRIBUTE15
    ,       SC.ATTRIBUTE2
    ,       SC.ATTRIBUTE3
    ,       SC.ATTRIBUTE4
    ,       SC.ATTRIBUTE5
    ,       SC.ATTRIBUTE6
    ,       SC.ATTRIBUTE7
    ,       SC.ATTRIBUTE8
    ,       SC.ATTRIBUTE9
    ,       SC.CONTEXT
    ,       SC.CREATED_BY
    ,       SC.CREATION_DATE
    ,       SC.DW_UPDATE_ADVICE_FLAG
    ,       SC.HEADER_ID
    ,       SC.LAST_UPDATED_BY
    ,       SC.LAST_UPDATE_DATE
    ,       SC.LAST_UPDATE_LOGIN
    ,       SC.LINE_ID
    ,       SC.PERCENT
    ,       SC.SALESREP_ID
    ,       SC.sales_credit_type_id
    ,       SC.SALES_CREDIT_ID
    ,       SC.WH_UPDATE_DATE
    --SG
    ,       SC.Sales_Group_Id
    --SG
    ,       SC.LOCK_CONTROL
    FROM    OE_SALES_CREDITS SC
    ,       OE_SALES_CREDIT_TYPES SCT
    WHERE   SC.sales_credit_type_id = sct.sales_credit_type_id
    AND     SCT.quota_flag = p_quota_flag
    AND     SC.header_id = p_header_id
    AND     SC.line_id IS NULL;
    --
    l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
    --
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTERING QUERY_HEADER_SCREDITS' , 5 ) ;
        oe_debug_pub.add(  'P_QUOTA_FLAG: '||P_QUOTA_FLAG , 5 ) ;
    END IF;
    -- Initialize table so that it clears previous records
    x_header_scredit_tbl.DELETE;
    --  Loop over fetched records
    FOR l_implicit_rec IN l_Header_Scredit_csr LOOP
        l_Header_Scredit_rec.attribute1  := l_implicit_rec.ATTRIBUTE1;
        l_Header_Scredit_rec.attribute10 := l_implicit_rec.ATTRIBUTE10;
        l_Header_Scredit_rec.attribute11 := l_implicit_rec.ATTRIBUTE11;
        l_Header_Scredit_rec.attribute12 := l_implicit_rec.ATTRIBUTE12;
        l_Header_Scredit_rec.attribute13 := l_implicit_rec.ATTRIBUTE13;
        l_Header_Scredit_rec.attribute14 := l_implicit_rec.ATTRIBUTE14;
        l_Header_Scredit_rec.attribute15 := l_implicit_rec.ATTRIBUTE15;
        l_Header_Scredit_rec.attribute2  := l_implicit_rec.ATTRIBUTE2;
        l_Header_Scredit_rec.attribute3  := l_implicit_rec.ATTRIBUTE3;
        l_Header_Scredit_rec.attribute4  := l_implicit_rec.ATTRIBUTE4;
        l_Header_Scredit_rec.attribute5  := l_implicit_rec.ATTRIBUTE5;
        l_Header_Scredit_rec.attribute6  := l_implicit_rec.ATTRIBUTE6;
        l_Header_Scredit_rec.attribute7  := l_implicit_rec.ATTRIBUTE7;
        l_Header_Scredit_rec.attribute8  := l_implicit_rec.ATTRIBUTE8;
        l_Header_Scredit_rec.attribute9  := l_implicit_rec.ATTRIBUTE9;
        l_Header_Scredit_rec.context     := l_implicit_rec.CONTEXT;
        l_Header_Scredit_rec.created_by  := l_implicit_rec.CREATED_BY;
        l_Header_Scredit_rec.creation_date := l_implicit_rec.CREATION_DATE;
        l_Header_Scredit_rec.dw_update_advice_flag := l_implicit_rec.DW_UPDATE_ADVICE_FLAG;
        l_Header_Scredit_rec.header_id   := l_implicit_rec.HEADER_ID;
        l_Header_Scredit_rec.last_updated_by := l_implicit_rec.LAST_UPDATED_BY;
        l_Header_Scredit_rec.last_update_date := l_implicit_rec.LAST_UPDATE_DATE;
        l_Header_Scredit_rec.last_update_login := l_implicit_rec.LAST_UPDATE_LOGIN;
        l_Header_Scredit_rec.line_id     := l_implicit_rec.LINE_ID;
        l_Header_Scredit_rec.percent     := l_implicit_rec.PERCENT;
        l_Header_Scredit_rec.salesrep_id := l_implicit_rec.SALESREP_ID;
        l_Header_Scredit_rec.sales_credit_type_id := l_implicit_rec.sales_credit_type_id;
        l_Header_Scredit_rec.sales_credit_id := l_implicit_rec.SALES_CREDIT_ID;
        l_Header_Scredit_rec.wh_update_date := l_implicit_rec.WH_UPDATE_DATE;
        --sg
        l_Header_Scredit_rec.sales_group_id := l_implicit_rec.sales_group_id;
        --sg
        l_Header_Scredit_rec.lock_control := l_implicit_rec.LOCK_CONTROL;
        x_Header_Scredit_tbl(x_Header_Scredit_tbl.COUNT + 1) := l_Header_Scredit_rec;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'SALESREP_ID: '||L_HEADER_SCREDIT_REC.SALESREP_ID ) ;
            oe_debug_pub.add(  'SALES_CREDIT_TYPE_ID: '||L_HEADER_SCREDIT_REC.SALES_CREDIT_TYPE_ID ) ;
            oe_debug_pub.add(  'PERCENT: '||L_HEADER_SCREDIT_REC.PERCENT ) ;
        END IF;
    END LOOP;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXITING QUERY_HEADER_SCREDITS ( ) ' , 5 ) ;
    END IF;
EXCEPTION
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    WHEN OTHERS THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXCEPTION , QUERY HEADER SALES CREDITS ( ) ' , 5 ) ;
         END IF;
         IF oe_msg_pub.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
         THEN
            oe_msg_pub.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Query_Header_Scredits'
            );
         END IF;
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Query_Header_Scredits;

PROCEDURE Insert_Line
(  p_interface_line_rec   IN  RA_interface_Lines_Rec_Type
,  x_return_status        OUT NOCOPY VARCHAR2
) IS
update_sql_stmt VARCHAR2(32767);
/* START PREPAYMENT */
update_sql_stmt1 VARCHAR2(32767);
/* END PREPAYMENT */
err_msg  VARCHAR2(5000);
l_rowid UROWID;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'ENTERING INSERT_LINE ( ) PROCEDURE' , 1 ) ;
   END IF;
   INSERT INTO RA_INTERFACE_LINES_ALL
                    (CREATED_BY
                     ,CREATION_DATE
                     ,LAST_UPDATED_BY
                     ,LAST_UPDATE_DATE
                     ,INTERFACE_LINE_ATTRIBUTE1
                     ,INTERFACE_LINE_ATTRIBUTE2
                     ,INTERFACE_LINE_ATTRIBUTE3
                     ,INTERFACE_LINE_ATTRIBUTE4
                     ,INTERFACE_LINE_ATTRIBUTE5
                     ,INTERFACE_LINE_ATTRIBUTE6
                     ,INTERFACE_LINE_ATTRIBUTE7
                     ,INTERFACE_LINE_ATTRIBUTE8
                     ,INTERFACE_LINE_ATTRIBUTE9
                     ,INTERFACE_LINE_ATTRIBUTE10
                     ,INTERFACE_LINE_ATTRIBUTE11
                     ,INTERFACE_LINE_ATTRIBUTE12
                     ,INTERFACE_LINE_ATTRIBUTE13
                     ,INTERFACE_LINE_ATTRIBUTE14
                     ,INTERFACE_LINE_ATTRIBUTE15
                     ,INTERFACE_LINE_ID
                     ,INTERFACE_LINE_CONTEXT
                     ,WAREHOUSE_ID
                     ,BATCH_SOURCE_NAME
                     ,SET_OF_BOOKS_ID
                     ,LINE_TYPE
                     ,DESCRIPTION
                     ,CURRENCY_CODE
                     ,AMOUNT
                     ,CONVERSION_TYPE
                     ,CONVERSION_DATE
                     ,CONVERSION_RATE
                     ,CUST_TRX_TYPE_NAME
                     ,CUST_TRX_TYPE_ID
                     ,TERM_NAME
                     ,TERM_ID
                     ,ORIG_SYSTEM_BILL_CUSTOMER_REF
                     ,ORIG_SYSTEM_BILL_CUSTOMER_ID
                     ,ORIG_SYSTEM_BILL_ADDRESS_REF
                     ,ORIG_SYSTEM_BILL_ADDRESS_ID
                     ,ORIG_SYSTEM_BILL_CONTACT_REF
                     ,ORIG_SYSTEM_BILL_CONTACT_ID
                     ,ORIG_SYSTEM_SHIP_CUSTOMER_REF
                     ,ORIG_SYSTEM_SHIP_CUSTOMER_ID
                     ,ORIG_SYSTEM_SHIP_ADDRESS_REF
                     ,ORIG_SYSTEM_SHIP_ADDRESS_ID
                     ,ORIG_SYSTEM_SHIP_CONTACT_REF
                     ,ORIG_SYSTEM_SHIP_CONTACT_ID
                     ,ORIG_SYSTEM_SOLD_CUSTOMER_REF
                     ,ORIG_SYSTEM_SOLD_CUSTOMER_ID
                     ,LINK_TO_LINE_ID
                     ,LINK_TO_LINE_CONTEXT
                     ,LINK_TO_LINE_ATTRIBUTE1
                     ,LINK_TO_LINE_ATTRIBUTE2
                     ,LINK_TO_LINE_ATTRIBUTE3
                     ,LINK_TO_LINE_ATTRIBUTE4
                     ,LINK_TO_LINE_ATTRIBUTE5
                     ,LINK_TO_LINE_ATTRIBUTE6
                     ,LINK_TO_LINE_ATTRIBUTE7
                     ,LINK_TO_LINE_ATTRIBUTE8
                     ,LINK_TO_LINE_ATTRIBUTE9
                     ,LINK_TO_LINE_ATTRIBUTE10
                     ,LINK_TO_LINE_ATTRIBUTE11
                     ,LINK_TO_LINE_ATTRIBUTE12
                     ,LINK_TO_LINE_ATTRIBUTE13
                     ,LINK_TO_LINE_ATTRIBUTE14
                     ,LINK_TO_LINE_ATTRIBUTE15
                     ,RECEIPT_METHOD_NAME
                     ,RECEIPT_METHOD_ID
                     ,CUSTOMER_BANK_ACCOUNT_ID
                     ,CUSTOMER_BANK_ACCOUNT_NAME
                     ,PAYMENT_SERVER_ORDER_NUM
                     ,APPROVAL_CODE
                     ,CUSTOMER_TRX_ID
                     ,TRX_DATE
                     ,GL_DATE
                     ,DOCUMENT_NUMBER
                     ,DOCUMENT_NUMBER_SEQUENCE_ID
                     ,TRX_NUMBER
                     ,QUANTITY
                     ,QUANTITY_ORDERED
                     ,UNIT_SELLING_PRICE
                     ,UNIT_STANDARD_PRICE
                     ,UOM_CODE
                     ,UOM_NAME
                     ,PRINTING_OPTION
                     ,INTERFACE_STATUS
                     ,REQUEST_ID
                     ,RELATED_BATCH_SOURCE_NAME
                     ,RELATED_TRX_NUMBER
                     ,RELATED_CUSTOMER_TRX_ID
                     ,PREVIOUS_CUSTOMER_TRX_ID
                     ,INITIAL_CUSTOMER_TRX_ID
                     ,CREDIT_METHOD_FOR_ACCT_RULE
                     ,CREDIT_METHOD_FOR_INSTALLMENTS
                     ,REASON_CODE_MEANING
                     ,REASON_CODE
                     ,TAX_RATE
                     ,TAX_CODE
                     ,TAX_PRECEDENCE
                     ,TAX_EXEMPT_FLAG
                     ,TAX_EXEMPT_NUMBER
                     ,TAX_EXEMPT_REASON_CODE
                     ,EXCEPTION_ID
                     ,EXEMPTION_ID
                     ,SHIP_DATE_ACTUAL
                     ,FOB_POINT
                     ,SHIP_VIA
                     ,WAYBILL_NUMBER
                     ,INVOICING_RULE_NAME
                     ,INVOICING_RULE_ID
                     ,ACCOUNTING_RULE_NAME
                     ,ACCOUNTING_RULE_ID
                     ,ACCOUNTING_RULE_DURATION
                     ,RULE_START_DATE
                     ,RULE_END_DATE --bug6004166    
                     ,PRIMARY_SALESREP_NUMBER
                     ,PRIMARY_SALESREP_ID
                     ,SALES_ORDER
                     ,SALES_ORDER_LINE
                     ,SALES_ORDER_DATE
                     ,SALES_ORDER_SOURCE
                     ,SALES_ORDER_REVISION
                     ,PURCHASE_ORDER
                     ,PURCHASE_ORDER_REVISION
                     ,PURCHASE_ORDER_DATE
                     ,AGREEMENT_NAME
                     ,AGREEMENT_ID
                     ,MEMO_LINE_NAME
                     ,MEMO_LINE_ID
                     ,INVENTORY_ITEM_ID
                     ,MTL_SYSTEM_ITEMS_SEG1
                     ,MTL_SYSTEM_ITEMS_SEG2
                     ,MTL_SYSTEM_ITEMS_SEG3
                     ,MTL_SYSTEM_ITEMS_SEG4
                     ,MTL_SYSTEM_ITEMS_SEG5
                     ,MTL_SYSTEM_ITEMS_SEG6
                     ,MTL_SYSTEM_ITEMS_SEG7
                     ,MTL_SYSTEM_ITEMS_SEG8
                     ,MTL_SYSTEM_ITEMS_SEG9
                     ,MTL_SYSTEM_ITEMS_SEG10
                     ,MTL_SYSTEM_ITEMS_SEG11
                     ,MTL_SYSTEM_ITEMS_SEG12
                     ,MTL_SYSTEM_ITEMS_SEG13
                     ,MTL_SYSTEM_ITEMS_SEG14
                     ,MTL_SYSTEM_ITEMS_SEG15
                     ,MTL_SYSTEM_ITEMS_SEG16
                     ,MTL_SYSTEM_ITEMS_SEG17
                     ,MTL_SYSTEM_ITEMS_SEG18
                     ,MTL_SYSTEM_ITEMS_SEG19
                     ,MTL_SYSTEM_ITEMS_SEG20
                     ,REFERENCE_LINE_ID
                     ,REFERENCE_LINE_CONTEXT
                     ,REFERENCE_LINE_ATTRIBUTE1
                     ,REFERENCE_LINE_ATTRIBUTE2
                     ,REFERENCE_LINE_ATTRIBUTE3
                     ,REFERENCE_LINE_ATTRIBUTE4
                     ,REFERENCE_LINE_ATTRIBUTE5
                     ,REFERENCE_LINE_ATTRIBUTE6
                     ,REFERENCE_LINE_ATTRIBUTE7
                     ,REFERENCE_LINE_ATTRIBUTE8
                     ,REFERENCE_LINE_ATTRIBUTE9
                     ,REFERENCE_LINE_ATTRIBUTE10
                     ,REFERENCE_LINE_ATTRIBUTE11
                     ,REFERENCE_LINE_ATTRIBUTE12
                     ,REFERENCE_LINE_ATTRIBUTE13
                     ,REFERENCE_LINE_ATTRIBUTE14
                     ,REFERENCE_LINE_ATTRIBUTE15
                     ,TERRITORY_ID
                     ,TERRITORY_SEGMENT1
                     ,TERRITORY_SEGMENT2
                     ,TERRITORY_SEGMENT3
                     ,TERRITORY_SEGMENT4
                     ,TERRITORY_SEGMENT5
                     ,TERRITORY_SEGMENT6
                     ,TERRITORY_SEGMENT7
                     ,TERRITORY_SEGMENT8
                     ,TERRITORY_SEGMENT9
                     ,TERRITORY_SEGMENT10
                     ,TERRITORY_SEGMENT11
                     ,TERRITORY_SEGMENT12
                     ,TERRITORY_SEGMENT13
                     ,TERRITORY_SEGMENT14
                     ,TERRITORY_SEGMENT15
                     ,TERRITORY_SEGMENT16
                     ,TERRITORY_SEGMENT17
                     ,TERRITORY_SEGMENT18
                     ,TERRITORY_SEGMENT19
                     ,TERRITORY_SEGMENT20
                     ,ATTRIBUTE_CATEGORY
                     ,ATTRIBUTE1
                     ,ATTRIBUTE2
                     ,ATTRIBUTE3
                     ,ATTRIBUTE4
                     ,ATTRIBUTE5
                     ,ATTRIBUTE6
                     ,ATTRIBUTE7
                     ,ATTRIBUTE8
                     ,ATTRIBUTE9
                     ,ATTRIBUTE10
                     ,ATTRIBUTE11
                     ,ATTRIBUTE12
                     ,ATTRIBUTE13
                     ,ATTRIBUTE14
                     ,ATTRIBUTE15
                     ,HEADER_ATTRIBUTE_CATEGORY
                     ,HEADER_ATTRIBUTE1
                     ,HEADER_ATTRIBUTE2
                     ,HEADER_ATTRIBUTE3
                     ,HEADER_ATTRIBUTE4
                     ,HEADER_ATTRIBUTE5
                     ,HEADER_ATTRIBUTE6
                     ,HEADER_ATTRIBUTE7
                     ,HEADER_ATTRIBUTE8
                     ,HEADER_ATTRIBUTE9
                     ,HEADER_ATTRIBUTE10
                     ,HEADER_ATTRIBUTE11
                     ,HEADER_ATTRIBUTE12
                     ,HEADER_ATTRIBUTE13
                     ,HEADER_ATTRIBUTE14
                     ,HEADER_ATTRIBUTE15
                     ,COMMENTS
                     ,INTERNAL_NOTES
                     ,MOVEMENT_ID
                     ,ORG_ID
                     ,HEADER_GDF_ATTR_CATEGORY
                     ,HEADER_GDF_ATTRIBUTE1
                     ,HEADER_GDF_ATTRIBUTE2
                     ,HEADER_GDF_ATTRIBUTE3
                     ,HEADER_GDF_ATTRIBUTE4
                     ,HEADER_GDF_ATTRIBUTE5
                     ,HEADER_GDF_ATTRIBUTE6
                     ,HEADER_GDF_ATTRIBUTE7
                     ,HEADER_GDF_ATTRIBUTE8
                     ,HEADER_GDF_ATTRIBUTE9
                     ,HEADER_GDF_ATTRIBUTE10
                     ,HEADER_GDF_ATTRIBUTE11
                     ,HEADER_GDF_ATTRIBUTE12
                     ,HEADER_GDF_ATTRIBUTE13
                     ,HEADER_GDF_ATTRIBUTE14
                     ,HEADER_GDF_ATTRIBUTE15
                     ,HEADER_GDF_ATTRIBUTE16
                     ,HEADER_GDF_ATTRIBUTE17
                     ,HEADER_GDF_ATTRIBUTE18
                     ,HEADER_GDF_ATTRIBUTE19
                     ,HEADER_GDF_ATTRIBUTE20
                     ,HEADER_GDF_ATTRIBUTE21
                     ,HEADER_GDF_ATTRIBUTE22
                     ,HEADER_GDF_ATTRIBUTE23
                     ,HEADER_GDF_ATTRIBUTE24
                     ,HEADER_GDF_ATTRIBUTE25
                     ,HEADER_GDF_ATTRIBUTE26
                     ,HEADER_GDF_ATTRIBUTE27
                     ,HEADER_GDF_ATTRIBUTE28
                     ,HEADER_GDF_ATTRIBUTE29
                     ,HEADER_GDF_ATTRIBUTE30
                     ,LINE_GDF_ATTR_CATEGORY
                     ,LINE_GDF_ATTRIBUTE1
                     ,LINE_GDF_ATTRIBUTE2
                     ,LINE_GDF_ATTRIBUTE3
                     ,LINE_GDF_ATTRIBUTE4
                     ,LINE_GDF_ATTRIBUTE5
                     ,LINE_GDF_ATTRIBUTE6
                     ,LINE_GDF_ATTRIBUTE7
                     ,LINE_GDF_ATTRIBUTE8
                     ,LINE_GDF_ATTRIBUTE9
                     ,LINE_GDF_ATTRIBUTE10
                     ,LINE_GDF_ATTRIBUTE11
                     ,LINE_GDF_ATTRIBUTE12
                     ,LINE_GDF_ATTRIBUTE13
                     ,LINE_GDF_ATTRIBUTE14
                     ,LINE_GDF_ATTRIBUTE15
                     ,LINE_GDF_ATTRIBUTE16
                     ,LINE_GDF_ATTRIBUTE17
                     ,LINE_GDF_ATTRIBUTE18
                     ,LINE_GDF_ATTRIBUTE19
                     ,LINE_GDF_ATTRIBUTE20
                     ,TRANSLATED_DESCRIPTION
                     ,PAYMENT_SET_ID)
              VALUES (
                      p_interface_line_rec.CREATED_BY
                     ,p_interface_line_rec.CREATION_DATE
                     ,p_interface_line_rec.LAST_UPDATED_BY
                     ,p_interface_line_rec.LAST_UPDATE_DATE
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE1
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE2
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE5
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE6
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE9
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE10
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE11
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE12
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE13
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE14
                     ,p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE15
                     ,p_interface_line_rec.INTERFACE_LINE_ID
                     ,p_interface_line_rec.INTERFACE_LINE_CONTEXT
                     ,p_interface_line_rec.WAREHOUSE_ID
                     ,p_interface_line_rec.BATCH_SOURCE_NAME
                     ,p_interface_line_rec.SET_OF_BOOKS_ID
                     ,p_interface_line_rec.LINE_TYPE
                     ,p_interface_line_rec.DESCRIPTION
                     ,p_interface_line_rec.CURRENCY_CODE
                     ,p_interface_line_rec.AMOUNT
                     ,p_interface_line_rec.CONVERSION_TYPE
                     ,p_interface_line_rec.CONVERSION_DATE
                     ,p_interface_line_rec.CONVERSION_RATE
                     ,p_interface_line_rec.CUST_TRX_TYPE_NAME
                     ,p_interface_line_rec.CUST_TRX_TYPE_ID
                     ,p_interface_line_rec.TERM_NAME
                     ,p_interface_line_rec.TERM_ID
                     ,p_interface_line_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF
                     ,p_interface_line_rec.ORIG_SYSTEM_BILL_CUSTOMER_ID
                     ,p_interface_line_rec.ORIG_SYSTEM_BILL_ADDRESS_REF
                     ,p_interface_line_rec.ORIG_SYSTEM_BILL_ADDRESS_ID
                     ,p_interface_line_rec.ORIG_SYSTEM_BILL_CONTACT_REF
                     ,p_interface_line_rec.ORIG_SYSTEM_BILL_CONTACT_ID
                     ,p_interface_line_rec.ORIG_SYSTEM_SHIP_CUSTOMER_REF
                     ,p_interface_line_rec.ORIG_SYSTEM_SHIP_CUSTOMER_ID
                     ,p_interface_line_rec.ORIG_SYSTEM_SHIP_ADDRESS_REF
                     ,p_interface_line_rec.ORIG_SYSTEM_SHIP_ADDRESS_ID
                     ,p_interface_line_rec.ORIG_SYSTEM_SHIP_CONTACT_REF
                     ,p_interface_line_rec.ORIG_SYSTEM_SHIP_CONTACT_ID
                     ,p_interface_line_rec.ORIG_SYSTEM_SOLD_CUSTOMER_REF
                     ,p_interface_line_rec.ORIG_SYSTEM_SOLD_CUSTOMER_ID
                     ,p_interface_line_rec.LINK_TO_LINE_ID
                     ,p_interface_line_rec.LINK_TO_LINE_CONTEXT
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE1
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE2
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE3
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE4
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE5
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE6
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE7
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE8
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE9
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE10
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE11
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE12
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE13
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE14
                     ,p_interface_line_rec.LINK_TO_LINE_ATTRIBUTE15
                     ,p_interface_line_rec.RECEIPT_METHOD_NAME
                     ,p_interface_line_rec.RECEIPT_METHOD_ID
                     ,p_interface_line_rec.CUSTOMER_BANK_ACCOUNT_ID
                     ,p_interface_line_rec.CUSTOMER_BANK_ACCOUNT_NAME
                     ,p_interface_line_rec.PAYMENT_SERVER_ORDER_NUM
                     ,p_interface_line_rec.APPROVAL_CODE
                     ,p_interface_line_rec.CUSTOMER_TRX_ID
                     ,p_interface_line_rec.TRX_DATE
                     ,p_interface_line_rec.GL_DATE
                     ,p_interface_line_rec.DOCUMENT_NUMBER
                     ,p_interface_line_rec.DOCUMENT_NUMBER_SEQUENCE_ID
                     ,p_interface_line_rec.TRX_NUMBER
                     ,p_interface_line_rec.QUANTITY
                     ,p_interface_line_rec.QUANTITY_ORDERED
                     ,p_interface_line_rec.UNIT_SELLING_PRICE
                     ,p_interface_line_rec.UNIT_STANDARD_PRICE
                     ,p_interface_line_rec.UOM_CODE
                     ,p_interface_line_rec.UOM_NAME
                     ,p_interface_line_rec.PRINTING_OPTION
                     ,p_interface_line_rec.INTERFACE_STATUS
                     ,p_interface_line_rec.REQUEST_ID
                     ,p_interface_line_rec.RELATED_BATCH_SOURCE_NAME
                     ,p_interface_line_rec.RELATED_TRX_NUMBER
                     ,p_interface_line_rec.RELATED_CUSTOMER_TRX_ID
                     ,p_interface_line_rec.PREVIOUS_CUSTOMER_TRX_ID
                     ,p_interface_line_rec.INITIAL_CUSTOMER_TRX_ID
                     ,p_interface_line_rec.CREDIT_METHOD_FOR_ACCT_RULE
                     ,p_interface_line_rec.CREDIT_METHOD_FOR_INSTALLMENTS
                     ,p_interface_line_rec.REASON_CODE_MEANING
                     ,p_interface_line_rec.REASON_CODE
                     ,p_interface_line_rec.TAX_RATE
                     ,p_interface_line_rec.TAX_CODE
                     ,p_interface_line_rec.TAX_PRECEDENCE
                     ,p_interface_line_rec.TAX_EXEMPT_FLAG
                     ,p_interface_line_rec.TAX_EXEMPT_NUMBER
                     ,p_interface_line_rec.TAX_EXEMPT_REASON_CODE
                     ,p_interface_line_rec.EXCEPTION_ID
                     ,p_interface_line_rec.EXEMPTION_ID
                     ,p_interface_line_rec.SHIP_DATE_ACTUAL
                     ,p_interface_line_rec.FOB_POINT
                     ,p_interface_line_rec.SHIP_VIA
                     ,p_interface_line_rec.WAYBILL_NUMBER
                     ,p_interface_line_rec.INVOICING_RULE_NAME
                     ,p_interface_line_rec.INVOICING_RULE_ID
                     ,p_interface_line_rec.ACCOUNTING_RULE_NAME
                     ,p_interface_line_rec.ACCOUNTING_RULE_ID
                     ,p_interface_line_rec.ACCOUNTING_RULE_DURATION
                     ,p_interface_line_rec.RULE_START_DATE
                     ,p_interface_line_rec.RULE_END_DATE --bug6004166
                     ,p_interface_line_rec.PRIMARY_SALESREP_NUMBER
                     ,p_interface_line_rec.PRIMARY_SALESREP_ID
                     ,p_interface_line_rec.SALES_ORDER
                     ,p_interface_line_rec.SALES_ORDER_LINE
                     ,p_interface_line_rec.SALES_ORDER_DATE
                     ,p_interface_line_rec.SALES_ORDER_SOURCE
                     ,p_interface_line_rec.SALES_ORDER_REVISION
                     ,p_interface_line_rec.PURCHASE_ORDER
                     ,p_interface_line_rec.PURCHASE_ORDER_REVISION
                     ,p_interface_line_rec.PURCHASE_ORDER_DATE
                     ,p_interface_line_rec.AGREEMENT_NAME
                     ,p_interface_line_rec.AGREEMENT_ID
                     ,p_interface_line_rec.MEMO_LINE_NAME
                     ,p_interface_line_rec.MEMO_LINE_ID
                     ,p_interface_line_rec.INVENTORY_ITEM_ID
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG1
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG2
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG3
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG4
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG5
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG6
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG7
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG8
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG9
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG10
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG11
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG12
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG13
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG14
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG15
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG16
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG17
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG18
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG19
                     ,p_interface_line_rec.MTL_SYSTEM_ITEMS_SEG20
                     ,p_interface_line_rec.REFERENCE_LINE_ID
                     ,p_interface_line_rec.REFERENCE_LINE_CONTEXT
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE1
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE2
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE3
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE4
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE5
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE6
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE7
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE8
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE9
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE10
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE11
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE12
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE13
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE14
                     ,p_interface_line_rec.REFERENCE_LINE_ATTRIBUTE15
                     ,p_interface_line_rec.TERRITORY_ID
                     ,p_interface_line_rec.TERRITORY_SEGMENT1
                     ,p_interface_line_rec.TERRITORY_SEGMENT2
                     ,p_interface_line_rec.TERRITORY_SEGMENT3
                     ,p_interface_line_rec.TERRITORY_SEGMENT4
                     ,p_interface_line_rec.TERRITORY_SEGMENT5
                     ,p_interface_line_rec.TERRITORY_SEGMENT6
                     ,p_interface_line_rec.TERRITORY_SEGMENT7
                     ,p_interface_line_rec.TERRITORY_SEGMENT8
                     ,p_interface_line_rec.TERRITORY_SEGMENT9
                     ,p_interface_line_rec.TERRITORY_SEGMENT10
                     ,p_interface_line_rec.TERRITORY_SEGMENT11
                     ,p_interface_line_rec.TERRITORY_SEGMENT12
                     ,p_interface_line_rec.TERRITORY_SEGMENT13
                     ,p_interface_line_rec.TERRITORY_SEGMENT14
                     ,p_interface_line_rec.TERRITORY_SEGMENT15
                     ,p_interface_line_rec.TERRITORY_SEGMENT16
                     ,p_interface_line_rec.TERRITORY_SEGMENT17
                     ,p_interface_line_rec.TERRITORY_SEGMENT18
                     ,p_interface_line_rec.TERRITORY_SEGMENT19
                     ,p_interface_line_rec.TERRITORY_SEGMENT20
                     ,p_interface_line_rec.ATTRIBUTE_CATEGORY
                     ,p_interface_line_rec.ATTRIBUTE1
                     ,p_interface_line_rec.ATTRIBUTE2
                     ,p_interface_line_rec.ATTRIBUTE3
                     ,p_interface_line_rec.ATTRIBUTE4
                     ,p_interface_line_rec.ATTRIBUTE5
                     ,p_interface_line_rec.ATTRIBUTE6
                     ,p_interface_line_rec.ATTRIBUTE7
                     ,p_interface_line_rec.ATTRIBUTE8
                     ,p_interface_line_rec.ATTRIBUTE9
                     ,p_interface_line_rec.ATTRIBUTE10
                     ,p_interface_line_rec.ATTRIBUTE11
                     ,p_interface_line_rec.ATTRIBUTE12
                     ,p_interface_line_rec.ATTRIBUTE13
                     ,p_interface_line_rec.ATTRIBUTE14
                     ,p_interface_line_rec.ATTRIBUTE15
                     ,p_interface_line_rec.HEADER_ATTRIBUTE_CATEGORY
                     ,p_interface_line_rec.HEADER_ATTRIBUTE1
                     ,p_interface_line_rec.HEADER_ATTRIBUTE2
                     ,p_interface_line_rec.HEADER_ATTRIBUTE3
                     ,p_interface_line_rec.HEADER_ATTRIBUTE4
                     ,p_interface_line_rec.HEADER_ATTRIBUTE5
                     ,p_interface_line_rec.HEADER_ATTRIBUTE6
                     ,p_interface_line_rec.HEADER_ATTRIBUTE7
                     ,p_interface_line_rec.HEADER_ATTRIBUTE8
                     ,p_interface_line_rec.HEADER_ATTRIBUTE9
                     ,p_interface_line_rec.HEADER_ATTRIBUTE10
                     ,p_interface_line_rec.HEADER_ATTRIBUTE11
                     ,p_interface_line_rec.HEADER_ATTRIBUTE12
                     ,p_interface_line_rec.HEADER_ATTRIBUTE13
                     ,p_interface_line_rec.HEADER_ATTRIBUTE14
                     ,p_interface_line_rec.HEADER_ATTRIBUTE15
                     ,p_interface_line_rec.COMMENTS
                     ,p_interface_line_rec.INTERNAL_NOTES
                     ,p_interface_line_rec.MOVEMENT_ID
                     ,p_interface_line_rec.ORG_ID
                     ,p_interface_line_rec.HEADER_GDF_ATTR_CATEGORY
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE1
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE2
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE3
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE4
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE5
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE6
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE7
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE8
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE9
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE10
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE11
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE12
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE13
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE14
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE15
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE16
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE17
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE18
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE19
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE20
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE21
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE22
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE23
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE24
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE25
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE26
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE27
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE28
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE29
                     ,p_interface_line_rec.HEADER_GDF_ATTRIBUTE30
                     ,p_interface_line_rec.LINE_GDF_ATTR_CATEGORY
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE1
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE2
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE3
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE4
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE5
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE6
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE7
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE8
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE9
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE10
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE11
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE12
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE13
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE14
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE15
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE16
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE17
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE18
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE19
                     ,p_interface_line_rec.LINE_GDF_ATTRIBUTE20
                     ,p_interface_line_rec.TRANSLATED_DESCRIPTION
                     ,p_interface_line_rec.PAYMENT_SET_ID   -- CUSTOMFIX
                     ) RETURNING rowid INTO l_rowid;
 
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'INSERT COMPLETED' , 1 ) ;
    END IF;
    IF OE_Commitment_Pvt.DO_Commitment_Sequencing 
       AND p_interface_line_rec.promised_commitment_amount IS NOT NULL THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'BUILD UPDATE STATEMENT WITH PROMISED COMMITMENT AMOUNT' , 1 ) ;
       END IF;
       update_sql_stmt := 'UPDATE RA_INTERFACE_LINES_ALL
                           SET PROMISED_COMMITMENT_AMOUNT = :1
                           WHERE ROWID = :r1';
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'EXECUTING UPDATE STMT FOR PROMISED_COMMITMENT_AMOUNT' , 1 ) ;
       END IF;
       EXECUTE IMMEDIATE update_sql_stmt USING
              p_interface_line_rec.promised_commitment_amount
             ,l_rowid;
    END IF;

/* START PREPAYMENT */
    /*
    IF p_interface_line_rec.payment_set_id IS NOT NULL THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'BUILD UPDATE STATEMENT WITH PAYMENT_SET_ID' , 1 ) ;
       END IF;
       update_sql_stmt1 := 'UPDATE RA_INTERFACE_LINES_ALL
                            SET PAYMENT_SET_ID = :2
                            WHERE ROWID = :r2';
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'EXECUTING UPDATE STMT FOR PAYMENT_SET_ID: '||P_INTERFACE_LINE_REC.PAYMENT_SET_ID , 1 ) ;
       END IF;
       EXECUTE IMMEDIATE update_sql_stmt1 USING
              p_interface_line_rec.PAYMENT_SET_ID
             ,l_rowid;
    END IF;
    */
/* END PREPAYMENT */ 
    -- Fix for the bug 2187074
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXIT INSERT_LINE ( ) PROCEDURE' , 1 ) ;
    END IF;
    EXCEPTION
       WHEN OTHERS THEN
            err_msg := 'Error while inserting to RA_INTERFACE_LINES_ALL :\n '|| SQLERRM;
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  ERR_MSG || ' SQLCODE: '||TO_CHAR ( SQLCODE ) , 1 ) ;
            END IF;
            IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
               OE_MSG_PUB.Add_Exc_Msg
               (   G_PKG_NAME
               ,   'Insert_Line'
               );
            END IF;
            /* fix for 2140223, do not raise hard error, but capture error in debug log */
            -- raise_application_error(-20101, 'Failing while inserting into ra_interface_lines');
            -- Fix for the bug 2187074
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
END Insert_Line;

PROCEDURE Prepare_Salescredit_rec
(   p_line_scredit_rec       IN     OE_Order_Pub.Line_Scredit_Rec_Type
,   p_interface_line_rec     IN     RA_Interface_Lines_Rec_Type
,   x_interface_scredit_rec  OUT NOCOPY   RA_Interface_Scredits_Rec_Type
) IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER LINE PREPARE_SALESCREDIT_REC ( ) PROCEDURE' , 5 ) ;
    END IF;

    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
       x_interface_scredit_rec.CREATION_DATE           := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(sysdate,p_interface_line_rec.org_id);
       x_interface_scredit_rec.LAST_UPDATE_DATE        := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(sysdate,p_interface_line_rec.org_id);
    ELSE
       x_interface_scredit_rec.CREATION_DATE           := sysdate;
       x_interface_scredit_rec.LAST_UPDATE_DATE        := sysdate;
    END IF;

    x_interface_scredit_rec.CREATED_BY                 := NVL(oe_standard_wf.g_user_id, fnd_global.user_id); -- 3169637
    x_interface_scredit_rec.LAST_UPDATED_BY            := NVL(oe_standard_wf.g_user_id, fnd_global.user_id); -- 3169637
    x_interface_scredit_rec.INTERFACE_SALESCREDIT_ID   := NULL;
    x_interface_scredit_rec.INTERFACE_LINE_ID          := NULL;
    x_interface_scredit_rec.INTERFACE_LINE_CONTEXT     := p_interface_line_rec.INTERFACE_LINE_CONTEXT;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE1  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE1;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE2  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE2;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE3  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE4  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE5  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE5;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE6  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE6;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE7  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE8  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE9  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE9;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE10 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE10;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE11 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE11;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE12 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE12;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE13 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE13;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE14 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE14;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE15 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE15;
    x_interface_scredit_rec.SALESREP_NUMBER            := NULL;
    x_interface_scredit_rec.SALESREP_ID                := p_line_scredit_rec.salesrep_id;
    x_interface_scredit_rec.SALES_CREDIT_TYPE_ID       := p_line_scredit_rec.sales_credit_type_id;
    x_interface_scredit_rec.SALES_CREDIT_PERCENT_SPLIT := p_line_scredit_rec.percent;
    x_interface_scredit_rec.ATTRIBUTE_CATEGORY         := p_line_scredit_rec.context;
    --SG
    x_interface_scredit_rec.SALES_GROUP_ID             := p_line_scredit_rec.sales_group_id;
    --SG

    --oe_debug_pub.add(x_interface_scredit_rec.SALES_GROUP_ID);

    --oe_debug_pub.add(
    x_interface_scredit_rec.ATTRIBUTE1                 := substrb(p_line_scredit_rec.attribute1, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE2                 := substrb(p_line_scredit_rec.attribute2, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE3                 := substrb(p_line_scredit_rec.attribute3, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE4                 := substrb(p_line_scredit_rec.attribute4, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE5                 := substrb(p_line_scredit_rec.attribute5, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE6                 := substrb(p_line_scredit_rec.attribute6, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE7                 := substrb(p_line_scredit_rec.attribute7, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE8                 := substrb(p_line_scredit_rec.attribute8, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE9                 := substrb(p_line_scredit_rec.attribute9, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE10                := substrb(p_line_scredit_rec.attribute10, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE11                := substrb(p_line_scredit_rec.attribute11, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE12                := substrb(p_line_scredit_rec.attribute12, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE13                := substrb(p_line_scredit_rec.attribute13, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE14                := substrb(p_line_scredit_rec.attribute14, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE15                := substrb(p_line_scredit_rec.attribute15, 1, 150);
    x_interface_scredit_rec.ORG_ID                     := p_interface_line_rec.org_id;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add ( 'value of sysdate '||sysdate);
        oe_debug_pub.add ( 'value of CREATION_DATE '||x_interface_scredit_rec.CREATION_DATE||
                           '  value of LAST_UPDATE_DATE '|| x_interface_scredit_rec.LAST_UPDATE_DATE);
    END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXITING LINE PREPARE_SALESCREDIT_REC' , 5 ) ;
    END IF;
END Prepare_Salescredit_rec;

PROCEDURE Prepare_Salescredit_rec
(   p_header_scredit_rec     IN     OE_Order_Pub.Header_Scredit_Rec_Type
,   p_interface_line_rec     IN     RA_Interface_Lines_Rec_Type
,   x_interface_scredit_rec  OUT NOCOPY   RA_Interface_Scredits_Rec_Type
) IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER HEADER PREPARE_SALESCREDIT_REC ( ) PROCEDURE ' , 5 ) ;
    END IF;

    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
       x_interface_scredit_rec.CREATION_DATE           := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(sysdate,p_interface_line_rec.org_id);
       x_interface_scredit_rec.LAST_UPDATE_DATE        := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(sysdate,p_interface_line_rec.org_id);
    ELSE
       x_interface_scredit_rec.CREATION_DATE           := sysdate;
       x_interface_scredit_rec.LAST_UPDATE_DATE        := sysdate;
    END IF;

    x_interface_scredit_rec.CREATED_BY                 := NVL(oe_standard_wf.g_user_id, fnd_global.user_id); -- 3169637
    x_interface_scredit_rec.LAST_UPDATED_BY            := NVL(oe_standard_wf.g_user_id, fnd_global.user_id); -- 3169637
    x_interface_scredit_rec.INTERFACE_SALESCREDIT_ID   := NULL;
    x_interface_scredit_rec.INTERFACE_LINE_ID          := NULL;
    x_interface_scredit_rec.INTERFACE_LINE_CONTEXT     := p_interface_line_rec.INTERFACE_LINE_CONTEXT;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE1  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE1;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE2  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE2;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE3  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE4  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE5  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE5;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE6  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE6;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE7  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE8  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE9  := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE9;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE10 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE10;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE11 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE11;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE12 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE12;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE13 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE13;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE14 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE14;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE15 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE15;
    x_interface_scredit_rec.SALESREP_NUMBER            := NULL;
    x_interface_scredit_rec.SALESREP_ID                := p_header_scredit_rec.salesrep_id;
    x_interface_scredit_rec.SALES_CREDIT_TYPE_ID       := p_header_scredit_rec.sales_credit_type_id;
    x_interface_scredit_rec.SALES_CREDIT_PERCENT_SPLIT := p_header_scredit_rec.percent;
    x_interface_scredit_rec.ATTRIBUTE_CATEGORY         := p_header_scredit_rec.context;
--SG{
    x_interface_scredit_rec.SALES_GROUP_ID             := p_header_scredit_rec.sales_group_id;
--SG}
    x_interface_scredit_rec.ATTRIBUTE1                 := substrb(p_header_scredit_rec.attribute1, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE2                 := substrb(p_header_scredit_rec.attribute2, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE3                 := substrb(p_header_scredit_rec.attribute3, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE4                 := substrb(p_header_scredit_rec.attribute4, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE5                 := substrb(p_header_scredit_rec.attribute5, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE6                 := substrb(p_header_scredit_rec.attribute6, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE7                 := substrb(p_header_scredit_rec.attribute7, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE8                 := substrb(p_header_scredit_rec.attribute8, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE9                 := substrb(p_header_scredit_rec.attribute9, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE10                := substrb(p_header_scredit_rec.attribute10, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE11                := substrb(p_header_scredit_rec.attribute11, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE12                := substrb(p_header_scredit_rec.attribute12, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE13                := substrb(p_header_scredit_rec.attribute13, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE14                := substrb(p_header_scredit_rec.attribute14, 1, 150);
    x_interface_scredit_rec.ATTRIBUTE15                := substrb(p_header_scredit_rec.attribute15, 1, 150);
    -- Fix for bug2185729
    x_interface_scredit_rec.ORG_ID                     := p_interface_line_rec.org_id;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add ( 'value of sysdate '||sysdate);
        oe_debug_pub.add ( 'value of CREATION_DATE '||x_interface_scredit_rec.CREATION_DATE||
                           '  value of LAST_UPDATE_DATE '|| x_interface_scredit_rec.LAST_UPDATE_DATE);
    END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXIT HEADER PREPARE_SALESCREDIT_REC ( ) PROCEDURE ' , 5 ) ;
    END IF;
END Prepare_Salescredit_rec;

PROCEDURE Prepare_Salescredit_rec
(   p_interface_line_rec     IN     RA_Interface_Lines_Rec_Type
,   x_interface_scredit_rec  OUT NOCOPY   RA_Interface_Scredits_Rec_Type
) IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER PREPARE_SALESCREDIT_REC ( ) PROCEDURE' , 1 ) ;
    END IF;
    --Fix for bug 2192220.
    Select SALES_CREDIT_TYPE_ID
    into x_interface_scredit_rec.SALES_CREDIT_TYPE_ID
    from ra_salesreps where salesrep_id=-3;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'SALES_CREDIT_TYPE_ID'||X_INTERFACE_SCREDIT_REC.SALES_CREDIT_TYPE_ID ) ;
    END IF;

    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
       x_interface_scredit_rec.CREATION_DATE           := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(sysdate,p_interface_line_rec.org_id);
       x_interface_scredit_rec.LAST_UPDATE_DATE        := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(sysdate,p_interface_line_rec.org_id);
    ELSE
       x_interface_scredit_rec.CREATION_DATE           := sysdate;
       x_interface_scredit_rec.LAST_UPDATE_DATE        := sysdate;
    END IF;

    x_interface_scredit_rec.CREATED_BY := NVL(oe_standard_wf.g_user_id, fnd_global.user_id); -- 3169637
    x_interface_scredit_rec.LAST_UPDATED_BY := NVL(oe_standard_wf.g_user_id, fnd_global.user_id); -- 3169637
    x_interface_scredit_rec.INTERFACE_SALESCREDIT_ID := NULL;
    x_interface_scredit_rec.INTERFACE_LINE_ID := NULL;
    x_interface_scredit_rec.INTERFACE_LINE_CONTEXT := p_interface_line_rec.INTERFACE_LINE_CONTEXT;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE1 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE1;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE2 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE2;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE3 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE4 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE5 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE5;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE6 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE6;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE7 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE8 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE9 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE9;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE10 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE10;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE11 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE11;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE12 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE12;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE13 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE13;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE14 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE14;
    x_interface_scredit_rec.INTERFACE_LINE_ATTRIBUTE15 := p_interface_line_rec.INTERFACE_LINE_ATTRIBUTE15;
    x_interface_scredit_rec.SALESREP_NUMBER := NULL;
    x_interface_scredit_rec.SALESREP_ID := -3;
    --x_interface_scredit_rec.SALES_CREDIT_TYPE_ID := 1; Commented off as part of fix for bug 2192220
    x_interface_scredit_rec.SALES_CREDIT_PERCENT_SPLIT := 100;
    x_interface_scredit_rec.ATTRIBUTE_CATEGORY := NULL;
    x_interface_scredit_rec.ATTRIBUTE1 := NULL;
    x_interface_scredit_rec.ATTRIBUTE2 := NULL;
    x_interface_scredit_rec.ATTRIBUTE3 := NULL;
    x_interface_scredit_rec.ATTRIBUTE4 := NULL;
    x_interface_scredit_rec.ATTRIBUTE5 := NULL;
    x_interface_scredit_rec.ATTRIBUTE6 := NULL;
    x_interface_scredit_rec.ATTRIBUTE7 := NULL;
    x_interface_scredit_rec.ATTRIBUTE8 := NULL;
    x_interface_scredit_rec.ATTRIBUTE9 := NULL;
    x_interface_scredit_rec.ATTRIBUTE10 := NULL;
    x_interface_scredit_rec.ATTRIBUTE11 := NULL;
    x_interface_scredit_rec.ATTRIBUTE12 := NULL;
    x_interface_scredit_rec.ATTRIBUTE13 := NULL;
    x_interface_scredit_rec.ATTRIBUTE14 := NULL;
    x_interface_scredit_rec.ATTRIBUTE15 := NULL;
    -- Fix for bug2185729
    x_interface_scredit_rec.ORG_ID := p_interface_line_rec.org_id;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add ( 'value of sysdate '||sysdate);
        oe_debug_pub.add ( ' value of CREATION_DATE '||x_interface_scredit_rec.CREATION_DATE||
                           '  value of LAST_UPDATE_DATE '|| x_interface_scredit_rec.LAST_UPDATE_DATE);
    END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXIT PREPARE_SALESCREDIT_REC ( ) PROCEDURE ' , 1 ) ;
    END IF;
END Prepare_Salescredit_rec;

procedure convert_to_ar(p_oe_salescredit_rec IN Ra_Interface_Scredits_Rec_Type,
                        x_ar_salescredit_rec OUT NOCOPY  AR_InterfaceSalesCredits_GRP.salescredit_rec_type) IS
Begin
  x_ar_salescredit_rec.INTERFACE_SALESCREDIT_ID         :=p_oe_salescredit_rec.INTERFACE_SALESCREDIT_ID ;
  x_ar_salescredit_rec.INTERFACE_LINE_ID	        :=p_oe_salescredit_rec.INTERFACE_LINE_ID	;
  x_ar_salescredit_rec.INTERFACE_LINE_CONTEXT		:=p_oe_salescredit_rec.INTERFACE_LINE_CONTEXT	;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE1	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE1;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE2	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE2;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE3	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE3;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE4	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE4;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE5	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE5;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE6	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE6;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE7	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE7;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE8	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE8;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE9	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE9;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE10	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE10;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE11	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE11;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE12	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE12;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE13	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE13;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE14	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE14;
  x_ar_salescredit_rec.INTERFACE_LINE_ATTRIBUTE15	:=p_oe_salescredit_rec.INTERFACE_LINE_ATTRIBUTE15;
  x_ar_salescredit_rec.SALESREP_NUMBER			:=p_oe_salescredit_rec.SALESREP_NUMBER		;
  x_ar_salescredit_rec.SALESREP_ID			:=p_oe_salescredit_rec.SALESREP_ID		;
  x_ar_salescredit_rec.SALESGROUP_ID			:=p_oe_salescredit_rec.SALES_GROUP_ID		;
  x_ar_salescredit_rec.SALES_CREDIT_TYPE_NAME		:=p_oe_salescredit_rec.SALES_CREDIT_TYPE_NAME	;
  x_ar_salescredit_rec.SALES_CREDIT_TYPE_ID		:=p_oe_salescredit_rec.SALES_CREDIT_TYPE_ID	;
  x_ar_salescredit_rec.SALES_CREDIT_AMOUNT_SPLIT	:=p_oe_salescredit_rec.SALES_CREDIT_AMOUNT_SPLIT;
  x_ar_salescredit_rec.SALES_CREDIT_PERCENT_SPLIT	:=p_oe_salescredit_rec.SALES_CREDIT_PERCENT_SPLIT;
  x_ar_salescredit_rec.INTERFACE_STATUS		        :=p_oe_salescredit_rec.INTERFACE_STATUS		;
  x_ar_salescredit_rec.REQUEST_ID			:=p_oe_salescredit_rec.REQUEST_ID		;
  x_ar_salescredit_rec.ATTRIBUTE_CATEGORY		:=p_oe_salescredit_rec.ATTRIBUTE_CATEGORY	;
  x_ar_salescredit_rec.ATTRIBUTE1			:=p_oe_salescredit_rec.ATTRIBUTE1		;
  x_ar_salescredit_rec.ATTRIBUTE2			:=p_oe_salescredit_rec.ATTRIBUTE2		;
  x_ar_salescredit_rec.ATTRIBUTE3			:=p_oe_salescredit_rec.ATTRIBUTE3		;
  x_ar_salescredit_rec.ATTRIBUTE4			:=p_oe_salescredit_rec.ATTRIBUTE4		;
  x_ar_salescredit_rec.ATTRIBUTE5			:=p_oe_salescredit_rec.ATTRIBUTE5		;
  x_ar_salescredit_rec.ATTRIBUTE6			:=p_oe_salescredit_rec.ATTRIBUTE6		;
  x_ar_salescredit_rec.ATTRIBUTE7			:=p_oe_salescredit_rec.ATTRIBUTE7		;
  x_ar_salescredit_rec.ATTRIBUTE8			:=p_oe_salescredit_rec.ATTRIBUTE8		;
  x_ar_salescredit_rec.ATTRIBUTE9			:=p_oe_salescredit_rec.ATTRIBUTE9		;
  x_ar_salescredit_rec.ATTRIBUTE10			:=p_oe_salescredit_rec.ATTRIBUTE10		;
  x_ar_salescredit_rec.ATTRIBUTE11			:=p_oe_salescredit_rec.ATTRIBUTE11		;
  x_ar_salescredit_rec.ATTRIBUTE12			:=p_oe_salescredit_rec.ATTRIBUTE12		;
  x_ar_salescredit_rec.ATTRIBUTE13			:=p_oe_salescredit_rec.ATTRIBUTE13		;
  x_ar_salescredit_rec.ATTRIBUTE14			:=p_oe_salescredit_rec.ATTRIBUTE14		;
  x_ar_salescredit_rec.ATTRIBUTE15			:=p_oe_salescredit_rec.ATTRIBUTE15		;
  x_ar_salescredit_rec.CREATED_BY			:=p_oe_salescredit_rec.CREATED_BY		;
  x_ar_salescredit_rec.CREATION_DATE			:=p_oe_salescredit_rec.CREATION_DATE		;
  x_ar_salescredit_rec.LAST_UPDATED_BY			:=p_oe_salescredit_rec.LAST_UPDATED_BY		;
  x_ar_salescredit_rec.LAST_UPDATE_DATE		        :=p_oe_salescredit_rec.LAST_UPDATE_DATE		;
  --x_ar_salescredit_rec.LAST_UPDATE_LOGIN		:=p_oe_salescredit_rec.LAST_UPDATE_LOGIN	;
  x_ar_salescredit_rec.ORG_ID				:=p_oe_salescredit_rec.ORG_ID			;

End;


PROCEDURE Insert_Salescredit
(   p_salescredit_rec  IN Ra_Interface_Scredits_Rec_Type
) IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
l_msg_count NUMBER;
l_msg_data VARCHAR2(2000);
l_return_status VARCHAR2(15);
l_ar_salescredit_rec AR_InterfaceSalesCredits_GRP.salescredit_rec_type;
BEGIN
  

   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'INSERTING SALES CREDIT RECORDS ' , 5 ) ;
   END IF;

   IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
      --OE_Invoice_Ext_Pvt.Insert_Salescredit(p_salescredit_rec);
      convert_to_ar(p_oe_salescredit_rec=>p_salescredit_rec,
                    x_ar_salescredit_rec=>l_ar_salescredit_rec);

      AR_InterfaceSalesCredits_GRP.Insert_Salescredit(
                              p_salescredit_rec=>l_ar_salescredit_rec,
                              x_return_status  =>l_return_status,
                              x_msg_count      =>l_msg_count,
                              x_msg_data       =>l_msg_data); 
   ELSE   --old behavior
     INSERT INTO RA_INTERFACE_SALESCREDITS_ALL
                 (CREATED_BY
                  ,CREATION_DATE
                  ,LAST_UPDATED_BY
                  ,LAST_UPDATE_DATE
                  ,INTERFACE_SALESCREDIT_ID
                  ,INTERFACE_LINE_ID
                  ,INTERFACE_LINE_CONTEXT
                  ,INTERFACE_LINE_ATTRIBUTE1
                  ,INTERFACE_LINE_ATTRIBUTE2
                  ,INTERFACE_LINE_ATTRIBUTE3
                  ,INTERFACE_LINE_ATTRIBUTE4
                  ,INTERFACE_LINE_ATTRIBUTE5
                  ,INTERFACE_LINE_ATTRIBUTE6
                  ,INTERFACE_LINE_ATTRIBUTE7
                  ,INTERFACE_LINE_ATTRIBUTE8
                  ,INTERFACE_LINE_ATTRIBUTE9
                  ,INTERFACE_LINE_ATTRIBUTE10
                  ,INTERFACE_LINE_ATTRIBUTE11
                  ,INTERFACE_LINE_ATTRIBUTE12
                  ,INTERFACE_LINE_ATTRIBUTE13
                  ,INTERFACE_LINE_ATTRIBUTE14
                  ,INTERFACE_LINE_ATTRIBUTE15
                  ,SALESREP_NUMBER
                  ,SALESREP_ID
                  ,SALES_CREDIT_TYPE_NAME
                  ,SALES_CREDIT_TYPE_ID
                  ,SALES_CREDIT_AMOUNT_SPLIT
                  ,SALES_CREDIT_PERCENT_SPLIT
                  ,INTERFACE_STATUS
                  ,REQUEST_ID
                  ,ATTRIBUTE_CATEGORY
                  ,ATTRIBUTE1
                  ,ATTRIBUTE2
                  ,ATTRIBUTE3
                  ,ATTRIBUTE4
                  ,ATTRIBUTE5
                  ,ATTRIBUTE6
                  ,ATTRIBUTE7
                  ,ATTRIBUTE8
                  ,ATTRIBUTE9
                  ,ATTRIBUTE10
                  ,ATTRIBUTE11
                  ,ATTRIBUTE12
                  ,ATTRIBUTE13
                  ,ATTRIBUTE14
                  ,ATTRIBUTE15
                  ,ORG_ID)
            VALUES
                  (p_salescredit_rec.CREATED_BY
                  ,p_salescredit_rec.CREATION_DATE
                  ,p_salescredit_rec.LAST_UPDATED_BY
                  ,p_salescredit_rec.LAST_UPDATE_DATE
                  ,p_salescredit_rec.INTERFACE_SALESCREDIT_ID
                  ,p_salescredit_rec.INTERFACE_LINE_ID
                  ,p_salescredit_rec.INTERFACE_LINE_CONTEXT
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE1
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE2
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE3
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE4
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE5
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE6
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE7
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE8
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE9
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE10
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE11
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE12
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE13
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE14
                  ,p_salescredit_rec.INTERFACE_LINE_ATTRIBUTE15
                  ,p_salescredit_rec.SALESREP_NUMBER
                  ,p_salescredit_rec.SALESREP_ID
                  ,p_salescredit_rec.SALES_CREDIT_TYPE_NAME
                  ,p_salescredit_rec.SALES_CREDIT_TYPE_ID
                  ,p_salescredit_rec.SALES_CREDIT_AMOUNT_SPLIT
                  ,p_salescredit_rec.SALES_CREDIT_PERCENT_SPLIT
                  ,p_salescredit_rec.INTERFACE_STATUS
                  ,p_salescredit_rec.REQUEST_ID
                  ,p_salescredit_rec.ATTRIBUTE_CATEGORY
                  ,p_salescredit_rec.ATTRIBUTE1
                  ,p_salescredit_rec.ATTRIBUTE2
                  ,p_salescredit_rec.ATTRIBUTE3
                  ,p_salescredit_rec.ATTRIBUTE4
                  ,p_salescredit_rec.ATTRIBUTE5
                  ,p_salescredit_rec.ATTRIBUTE6
                  ,p_salescredit_rec.ATTRIBUTE7
                  ,p_salescredit_rec.ATTRIBUTE8
                  ,p_salescredit_rec.ATTRIBUTE9
                  ,p_salescredit_rec.ATTRIBUTE10
                  ,p_salescredit_rec.ATTRIBUTE11
                  ,p_salescredit_rec.ATTRIBUTE12
                  ,p_salescredit_rec.ATTRIBUTE13
                  ,p_salescredit_rec.ATTRIBUTE14
                  ,p_salescredit_rec.ATTRIBUTE15
                  ,p_salescredit_rec.ORG_ID);
          END IF;

          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'SUCCESSFULLY INSERTED SALES CREDIT RECORDS' , 5 ) ;
          END IF;
EXCEPTION WHEN OTHERS THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'UNABLE TO INSERT SALES CREDIT RECORDS -> '||SQLERRM , 1 ) ;
          END IF;
          IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
               OE_MSG_PUB.Add_Exc_Msg
               (   G_PKG_NAME
               ,   'Insert_Salescredit'
               );
          END IF;
END Insert_Salescredit;

PROCEDURE Interface_SalesCredits
(   p_line_rec   IN   OE_Order_Pub.Line_Rec_Type
,   p_interface_line_rec        IN  RA_Interface_Lines_Rec_Type
,   x_return_status  OUT NOCOPY VARCHAR2
)
IS
l_interface_scredit_rec     RA_Interface_Scredits_Rec_Type;
l_line_scredit_tbl          OE_Order_Pub.Line_Scredit_Tbl_Type;
l_header_scredit_tbl        OE_Order_Pub.Header_Scredit_Tbl_Type;
l_line_scredit_rec          OE_Order_Pub.Line_Scredit_Rec_Type;
l_header_scredit_rec        OE_Order_Pub.Header_Scredit_Rec_Type;
l_line_credits              NUMBER := 0 ;
l_header_credits            NUMBER := 0 ;
Insert_Header_Scredits_flag VARCHAR2(1);
service_grand_parent_id     NUMBER := 0;
i                           NUMBER;
l_quota_flag                VARCHAR2(1);
l_order_line_id             NUMBER;
l_return_status             VARCHAR2(1);
l_service_reference_line_id NUMBER;

--FP bug 3872157 
l_total_percent NUMBER;

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
 IF l_debug_level  > 0 THEN
     oe_debug_pub.add(  'ENTER INTERFACE_SALES_CREDITS ( ) PROCEDURE ' , 5 ) ;
 END IF;
 FOR i IN 1..2 LOOP
     IF    i=1 THEN
           l_quota_flag := 'Y';
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'INSERTING QUOTA SALES CREDITS..' , 5 ) ;
           END IF;
     ELSIF i = 2 THEN
           l_quota_flag := 'N';
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'INSERTING NON-QUOTA SALES CREDITS..' , 5 ) ;
           END IF;
     END IF;
     Query_Line_Scredits(p_line_id          => p_line_rec.line_id
                        ,p_quota_flag       => l_quota_flag
                        ,x_line_scredit_tbl => l_line_scredit_tbl
			 --FP bug 3872157
			,x_total_percent    => l_total_percent );
     -- Prepare and insert line sales credits
     IF l_line_scredit_tbl.COUNT <> 0  AND
        (l_quota_flag = 'N' OR (l_quota_flag = 'Y' AND l_total_percent <> 0)) THEN --FP bug 3872157
        FOR I IN 1..l_line_scredit_tbl.COUNT LOOP
            l_line_scredit_rec := l_line_scredit_tbl(I);
	        Prepare_Salescredit_rec
                (p_line_scredit_rec        => l_line_scredit_rec
                ,p_interface_line_rec      => p_interface_line_rec
                ,x_interface_scredit_rec   => l_interface_scredit_rec);
            Insert_Salescredit(l_interface_scredit_rec);
      END LOOP;
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'INSERTED LINE SALESCREDITS' , 1 ) ;
      END IF;
      Insert_Header_Scredits_Flag := 'N';
   ELSE  -- Line has no sales credits
      IF p_line_rec.item_type_code = 'SERVICE' AND p_line_rec.service_reference_line_id IS NOT NULL THEN -- line is service and has parent
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'RETRIEVING CUSTOMER PRODUCT LINE ID' ) ;
         END IF;
         IF p_line_rec.service_reference_type_code = 'CUSTOMER_PRODUCT' THEN
	    /* Commenting for bug 5083469
            OE_SERVICE_UTIL.Get_Cust_Product_Line_Id
            (x_return_status     => l_return_status
            ,p_reference_line_id => p_line_rec.service_reference_line_id
            ,p_customer_id       => p_line_rec.sold_to_org_id
            ,x_cust_product_line_id=> l_order_line_id
            );
           IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
	          IF l_debug_level  > 0 THEN
	              oe_debug_pub.add(  'CUSTOMER PRODUCT LINE ID -> ' || L_ORDER_LINE_ID , 5 ) ;
	          END IF;
              l_service_reference_line_id := l_order_line_id;
           ELSE
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'UNABLE TO RETRIEVE CUSTOMER PRODUCT LINE ID' , 1 ) ;
              END IF;
		      RAISE NO_DATA_FOUND;
           END IF;
	   end commenting for bug 5083469 */
           l_service_reference_line_id := NULL;
         ELSE
           l_service_reference_line_id := p_line_rec.service_reference_line_id;
         END IF;
      END IF;
      IF l_service_reference_line_id is NOT NULL then  -- service line has a parent
         -- Get sales credits for service parent
         Query_Line_Scredits(p_line_id          => l_service_reference_line_id
                           , p_quota_flag       => l_quota_flag
                           , x_line_scredit_tbl => l_line_scredit_tbl
			     -- FP bug 3872157
			   , x_total_percent    => l_total_percent);
         IF l_line_scredit_tbl.COUNT <> 0 AND
	    (l_quota_flag = 'N' OR (l_quota_flag = 'Y' AND l_total_percent <> 0)) THEN -- FP bug 3872157
            FOR I IN 1..l_line_scredit_tbl.COUNT LOOP
                l_line_scredit_rec := l_line_scredit_tbl(I);
	            Prepare_Salescredit_rec
                       (p_line_scredit_rec        => l_line_scredit_rec
                       ,p_interface_line_rec      => p_interface_line_rec
                       ,x_interface_scredit_rec   => l_interface_scredit_rec);
                Insert_Salescredit(l_interface_scredit_rec);
            END LOOP;
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'INSERTED SERVICE PARENT LINE SALESCREDITS' , 1 ) ;
            END IF;
            Insert_Header_Scredits_Flag := 'N';
         ELSE  -- Service parent has no sales credits
            -- Check if service parent has parent (In case if service parent is an option, class, kit etc)
            BEGIN
               SELECT top_model_line_id
               INTO   service_grand_parent_id
               FROM   oe_order_lines_all /*Bug3261460*/
               WHERE  line_id = l_service_reference_line_id;
	    EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   IF l_debug_level  > 0 THEN
                    oe_debug_pub.add(  'UNABLE TO GET SERVICE GRAND PARENT ITEM' , 1);
                   END IF;
                   service_grand_parent_id := NULL;
            END;
            IF (nvl(service_grand_parent_id,0) <> 0 AND service_grand_parent_id <> l_service_reference_line_id) THEN
               -- Get sales credits for service grand parent
               Query_Line_Scredits(p_line_id          =>  service_grand_parent_id
                                 , p_quota_flag       => l_quota_flag
                                 , x_line_scredit_tbl => l_line_scredit_tbl
				   --FP bug 3872157
				 , x_total_percent    => l_total_percent);
               IF l_line_scredit_tbl.COUNT <> 0 AND
		  (l_quota_flag = 'N' OR (l_quota_flag = 'Y' AND l_total_percent <> 0)) THEN -- FP bug 3872157
                  FOR I IN 1..l_line_scredit_tbl.COUNT LOOP
                     l_line_scredit_rec := l_line_scredit_tbl(I);
                     Prepare_Salescredit_rec
                          (p_line_scredit_rec        => l_line_scredit_rec
                          ,p_interface_line_rec      => p_interface_line_rec
                          ,x_interface_scredit_rec   => l_interface_scredit_rec);
                     Insert_Salescredit(l_interface_scredit_rec);
                  END LOOP;
                  IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  'INSERTED SERVICE GRAND PARENT LINE SALESCREDITS' , 1 ) ;
                  END IF;
                  Insert_Header_Scredits_Flag := 'N';
               ELSE -- Service grand parent has no sales credits
                 --Get header sales credits
                 Insert_Header_Scredits_Flag := 'Y';
               END IF; -- end of service grand parent salescredits
            ELSE  -- Service has no grand parent
               --Get header sales credits
               Insert_Header_Scredits_Flag := 'Y';
            END IF; -- end of service grand parent
         END IF;  -- end of service parent
      -- Check if line is option, class or kit
      ELSIF (p_line_rec.top_model_line_id IS NOT NULL AND
             p_line_rec.top_model_line_id <> p_line_rec.line_id) THEN
          -- Get sales credits for parent line
          Query_Line_Scredits(p_line_id          =>  p_line_rec.top_model_line_id
                            , p_quota_flag       => l_quota_flag
                            , x_line_scredit_tbl => l_line_scredit_tbl
			      -- FP bug 3872157
                            , x_total_percent    => l_total_percent);
          IF l_line_scredit_tbl.COUNT <> 0 AND
	     (l_quota_flag = 'N' OR (l_quota_flag = 'Y' AND l_total_percent <> 0)) THEN --FP bug 3872157
             FOR I IN 1..l_line_scredit_tbl.COUNT LOOP
                l_line_scredit_rec := l_line_scredit_tbl(I);
       	        Prepare_Salescredit_rec
                        (p_line_scredit_rec        => l_line_scredit_rec
                        ,p_interface_line_rec      => p_interface_line_rec
                        ,x_interface_scredit_rec   => l_interface_scredit_rec);
                Insert_Salescredit(l_interface_scredit_rec);
             END LOOP;
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'INSERTED PARENT LINE SALESCREDITS' , 1 ) ;
             END IF;
             Insert_Header_Scredits_Flag := 'N';
          ELSE  -- parent has no sales credits
             -- Prepare and insert header sales credits
             Insert_Header_Scredits_flag := 'Y';
          END IF; -- end of model line
      ELSE -- line has no parent
          Insert_Header_Scredits_flag := 'Y';
      END IF;
   END IF;
   IF Insert_Header_Scredits_flag = 'Y' THEN
     -- Prepare and insert header sales credits
     Query_Header_Scredits(p_header_id => p_line_rec.header_id
                         , p_quota_flag => l_quota_flag
                         , x_header_scredit_tbl => l_header_scredit_tbl);
     IF l_header_scredit_tbl.COUNT <> 0 THEN
        FOR I IN 1..l_header_scredit_tbl.COUNT LOOP
           l_header_scredit_rec := l_header_scredit_tbl(I);
           Prepare_Salescredit_rec
                  (p_header_scredit_rec      => l_header_scredit_rec
                  ,p_interface_line_rec      => p_interface_line_rec
                  ,x_interface_scredit_rec   => l_interface_scredit_rec);
           Insert_Salescredit(l_interface_scredit_rec);
        END LOOP;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'INSERTED HEADER SALESCREDITS' , 1 ) ;
        END IF;
        Insert_Header_Scredits_Flag := 'N';
     END IF;
   END IF;
END LOOP;
x_return_status := FND_API.G_RET_STS_SUCCESS;
IF l_debug_level  > 0 THEN
    oe_debug_pub.add(  'INTERFACE_SALES_CREDITS ( ) PROCDURE SUCCESS : '||X_RETURN_STATUS , 1 ) ;
END IF;
EXCEPTION
     WHEN OTHERS THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'EXCEPTION INTERFACE_SALES_CREDITS ( ) '||SQLERRM , 1 ) ;
          END IF;
          x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
          IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
          THEN
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Interface_SalesCredits');
          END IF;
END Interface_SalesCredits;

PROCEDURE Interface_scredits_for_freight
( p_line_rec           IN OE_Order_PUB.Line_Rec_Type
, p_interface_line_rec IN RA_Interface_Lines_Rec_Type
, p_line_level_charge  IN VARCHAR2
) IS
l_header_scredit_tbl     OE_Order_PUB.Header_Scredit_Tbl_Type;
l_header_scredit_rec     OE_Order_PUB.Header_Scredit_Rec_Type;
l_interface_scredit_rec  RA_Interface_Scredits_Rec_Type;
l_cr_srep_for_freight    VARCHAR2(30) := NVL(FND_PROFILE.VALUE('WSH_CR_SREP_FOR_FREIGHT'), 'N');
l_return_status          VARCHAR2(30);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'INTERFACING SALES CREDITS FOR FREIGHT' , 5 ) ;
   END IF;
   -- If the profile option 'OM: Credit Salesperson for Freight on Sales'
   -- is set to 'Yes' then interface header/line sales credits otherwise
   -- insert dummy sales credits.
   IF l_cr_srep_for_freight = 'Y' THEN
      IF p_line_level_charge = 'Y' THEN
         -- interface line sales credits if there are any otherwise get from its parent
         Interface_Salescredits(p_line_rec
                               ,p_interface_line_rec
                               ,l_return_status);
      ELSE
        --Interface quota, non-quota Header Sales Credits
        OE_Header_Scredit_Util.Query_Rows(p_header_id => p_line_rec.header_id, x_header_scredit_tbl=>l_header_scredit_tbl);
        IF l_header_scredit_tbl.COUNT <> 0 THEN
           FOR I IN 1..l_header_scredit_tbl.COUNT LOOP
              l_header_scredit_rec := l_header_scredit_tbl(I);
              Prepare_Salescredit_rec
                  (p_header_scredit_rec      => l_header_scredit_rec
                  ,p_interface_line_rec      => p_interface_line_rec
                  ,x_interface_scredit_rec   => l_interface_scredit_rec);
              Insert_Salescredit(l_interface_scredit_rec);
            END LOOP;
        END IF;
      END IF;
   ELSE
      -- Interface dummy quota freight sales credits
      Prepare_Salescredit_rec
              (p_interface_line_rec      => p_interface_line_rec
              ,x_interface_scredit_rec   => l_interface_scredit_rec);
      Insert_Salescredit(l_interface_scredit_rec);
   END IF;
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'INTERFACE SALES CREDITS FOR FREIGHT SUCCESSFULLY ' , 5 ) ;
   END IF;
EXCEPTION
     WHEN OTHERS THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'EXCEPTION , INTERFACE SALES CREDITS FOR FREIGHT '||SQLERRM , 1 ) ;
          END IF;
          IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
          THEN
            OE_MSG_PUB.Add_Exc_Msg
            (   G_PKG_NAME
            ,   'Interface_scredits_for_freight'
            );
          END IF;
END Interface_scredits_for_freight;

-- 3685479 Changed the signature of the procedure with extra parameter p_adjustments_tbl
PROCEDURE Get_Rounding_Diff
(  p_line_rec              IN   OE_Order_Pub.Line_Rec_Type
,  p_interface_line_rec    IN   RA_Interface_Lines_Rec_Type
,  p_adjustments_tbl       IN   OE_Header_Adj_Util.Line_Adjustments_Tab_Type 
,  x_rounding_diff         OUT NOCOPY NUMBER
) IS
l_adjustments_tbl    OE_Header_Adj_Util.Line_Adjustments_Tab_Type;
l_adjustments_rec    OE_Header_Adj_Util.Line_Adjustments_Rec_Type;
l_line_adj_rec       OE_Order_PUB.Line_Adj_Rec_Type;
l_line_tot_amount    NUMBER;
l_ind_line_tot       NUMBER;
l_ind_disc_tot       NUMBER;
l_comb_ind_line_tots NUMBER;
l_user_id          NUMBER;
l_resp_id          NUMBER;
l_appl_id          NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
l_header_id NUMBER;
l_line_id   NUMBER;
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER GET_ROUNDING_DIFF ( ) PROCEDURE' , 5 ) ;
    END IF;
    
     -- Removed the previous call to get_line_adjustments as adjustment table is passed now

     IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'p_adjustments_tbl.COUNT:'||p_adjustments_tbl.COUNT);
     END IF;

     -- 3685479 Replaced call to show_detail_discounts by the foll IF
     Get_Createdby_Context(p_line_id => p_line_rec.line_id,
                         x_user_id      => l_user_id,
                         x_resp_id      => l_resp_id,
                         x_resp_appl_id => l_appl_id);
     IF (fnd_profile.value_specific('OE_DISCOUNT_DETAILS_ON_INVOICE', l_user_id,l_resp_id,l_appl_id) = 'Y' AND p_adjustments_tbl.COUNT > 0) THEN
        -- get line total when the profile is off
        Rounded_Amount(p_currency_code => p_interface_line_rec.currency_code
                      ,p_unrounded_amount => (p_line_rec.unit_selling_price * p_interface_line_rec.quantity)
                      ,x_rounded_amount => l_line_tot_amount);
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'LINE TOTAL WHEN SHOW DISCOUNTS PROFILE IS OFF: '||L_LINE_TOT_AMOUNT , 5 ) ;
        END IF;
        -- get line total when the profile is on
        Rounded_Amount(p_currency_code => p_interface_line_rec.currency_code
                      ,p_unrounded_amount => (p_line_rec.unit_list_price * p_interface_line_rec.quantity)
                      ,x_rounded_amount => l_ind_line_tot);
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'LINE TOTAL WHEN SHOW DISCOUNTS PROFILE IS ON: '||L_IND_LINE_TOT , 5 ) ;
        END IF;
        IF p_adjustments_tbl.COUNT <> 0 THEN
           FOR I IN 1..p_adjustments_tbl.COUNT LOOP
               l_adjustments_rec := p_adjustments_tbl(I);
               Rounded_Amount(p_currency_code => p_interface_line_rec.currency_code
                             ,p_unrounded_amount => (l_adjustments_rec.unit_discount_amount * p_interface_line_rec.quantity * -1)
                             ,x_rounded_amount => l_ind_disc_tot);
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'PROCESSING RECORD# '||I|| ': '||'DISCOUNT LINE TOTAL FOR ADJ_ID= '||L_ADJUSTMENTS_REC.PRICE_ADJUSTMENT_ID||': ' ||L_IND_DISC_TOT , 5 ) ;
              END IF;
              l_ind_line_tot := l_ind_line_tot + l_ind_disc_tot;
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'INTERMEDIATE TOTAL: '||L_IND_LINE_TOT , 5 ) ;
              END IF;
           END LOOP;
           Rounded_Amount(p_currency_code => p_interface_line_rec.currency_code
                         ,p_unrounded_amount => l_ind_line_tot
                         ,x_rounded_amount => l_comb_ind_line_tots);
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'ROUNDED TOTAL FOR THE LINE WHEN SHOW DISCOUNTS IS ON => '||L_COMB_IND_LINE_TOTS , 5 ) ;
           END IF;
        END IF;
        IF l_line_tot_amount = l_comb_ind_line_tots THEN
           x_rounding_diff := NULL;
        ELSE
        -- This difference should go with the first discount line
           x_rounding_diff := l_line_tot_amount - l_comb_ind_line_tots;
        END IF;
     END IF;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'EXIT GET_ROUNDING_DIFF ( ) WITH ROUNDING DIFFERENCE : '||X_ROUNDING_DIFF , 5 ) ;
     END IF;
EXCEPTION
     WHEN OTHERS THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'EXCEPTION , ROUNDING DIFFERENCE '||SQLERRM , 1 ) ;
          END IF;
          IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
          THEN
             OE_MSG_PUB.Add_Exc_Msg( G_PKG_NAME,'Get_Rounding_Diff');
          END IF;
END Get_Rounding_Diff;

PROCEDURE Interface_Detail_Discounts
(  p_line_rec              IN   OE_Order_Pub.Line_Rec_Type
,  p_interface_line_rec    IN   RA_Interface_Lines_Rec_Type
,  x_return_status         OUT NOCOPY  VARCHAR2
) IS
l_discounts_rec      RA_Interface_Lines_Rec_Type;
l_adjustments_tbl    OE_Header_Adj_Util.Line_Adjustments_Tab_Type;
l_adjustments_rec    OE_Header_Adj_Util.Line_Adjustments_Rec_Type;
l_line_adj_rec       OE_Order_PUB.Line_Adj_Rec_Type;
l_header_adj_rec     OE_Order_PUB.Header_Adj_Rec_Type;
l_return_status      VARCHAR2(30);
l_rounding_diff      NUMBER;
l_rounding_diff_applied VARCHAR2(1) :='N';
l_reference_line_id  NUMBER;

l_ref_header_id      NUMBER;
l_ref_line_id        NUMBER;
l_rounded_amount     NUMBER;

cursor order_info(c_line_id number)
is
select header_id, line_id
from   oe_order_lines_all
where  line_id = c_line_id;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
l_header_id NUMBER;
l_line_id NUMBER;
BEGIN
IF l_debug_level  > 0 THEN
    oe_debug_pub.add(  'ENTERING INTERFACE_DETAIL_DISCOUNTS ( ) PROCEDURE ' , 5 ) ;
END IF;
    -- 3661895 The IF will be true only for return retrobilled RMA, all others will go through else
    -- RT{  
    IF (p_line_rec.line_category_code = 'RETURN'
      and p_line_rec.reference_line_id IS NOT NULL
      and p_line_rec.retrobill_request_id IS NOT NULL) THEN
   
     OE_RETROBILL_PVT.Get_Line_Adjustments
                                  (p_line_rec          =>  p_line_rec 
                                  ,x_line_adjustments  =>  l_adjustments_tbl);
    ELSE

     OE_Header_Adj_Util.Get_Line_Adjustments
	               (p_header_id         =>   p_line_rec.header_id
		       ,p_line_id           =>   p_line_rec.line_id
		       ,x_line_adjustments  =>   l_adjustments_tbl);
    END IF;
    -- RT}
   
    -- Prepare l_discounts_rec from l_adjustments_tbl and p_interface_line_rec
    -- keep all other info same as line
IF l_adjustments_tbl.COUNT <> 0 THEN
   FOR I IN 1..l_adjustments_tbl.COUNT LOOP
       l_adjustments_rec := l_adjustments_tbl(I);
       l_discounts_rec   := p_interface_line_rec;
       OE_Line_Adj_Util.Query_Row(p_price_adjustment_id=>l_adjustments_rec.price_adjustment_id,x_line_adj_rec=>l_line_adj_rec);
           -- Do not set mandatory grouping columns to different value than order line.
           -- This can cause discount lines to group into different invoice (if values
           -- are different from sales order line)
           -- l_discounts_rec.INTERFACE_LINE_ATTRIBUTE3 := '0';
       -- l_discounts_rec.INTERFACE_LINE_ATTRIBUTE4 := '0'; -- for bug# 5751089
       l_discounts_rec.INTERFACE_LINE_ATTRIBUTE7 := '0';
       /* 1847224  l_discounts_rec.INTERFACE_LINE_ATTRIBUTE8 := '0'; */
       l_discounts_rec.INTERFACE_LINE_ATTRIBUTE11 := l_adjustments_rec.price_adjustment_id;
       /* 1789057, populate list_line_no in addition to adjustment name */
       if l_adjustments_rec.list_line_no is NULL then
	      l_discounts_rec.Description := l_adjustments_rec.adjustment_name;
       else
          l_discounts_rec.Description := substr(l_adjustments_rec.adjustment_name,1,119)||'.'||substr(l_adjustments_rec.list_line_no,1,120);
       end if;

       -- bug 2509121.
       -- translated description is only needed for sales order line.
       IF l_discounts_rec.translated_description is not null THEN
         l_discounts_rec.translated_description := null;
       END IF;

       -- Quantity comes with the correct creation sign from the interface_line record. No need to adjust here
       l_discounts_rec.Unit_Selling_Price := l_adjustments_rec.unit_discount_amount * -1;
       l_discounts_rec.Unit_Standard_Price := l_adjustments_rec.unit_discount_amount * -1;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'ORIGINAL UNIT DISCOUNT AMOUNT : '||L_ADJUSTMENTS_REC.UNIT_DISCOUNT_AMOUNT , 5 ) ;
       END IF;
       Rounded_Amount(p_currency_code => l_discounts_rec.currency_code
                      ,p_unrounded_amount => (l_discounts_rec.unit_selling_price * l_discounts_rec.quantity)
                      ,x_rounded_amount => l_discounts_rec.amount);
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'DISCOUNT UNIT_SELLING_PRICE: '||L_DISCOUNTS_REC.UNIT_SELLING_PRICE , 5 ) ;
           oe_debug_pub.add(  'DISCOUNT UNIT_STANDARD_PRICE: '||L_DISCOUNTS_REC.UNIT_STANDARD_PRICE , 5 ) ;
           oe_debug_pub.add(  'DISCOUNT AMOUNT: '||L_DISCOUNTS_REC.AMOUNT , 5 ) ;
       END IF;
       IF l_rounding_diff_applied = 'N' THEN
          IF (l_discounts_rec.quantity = 0 OR l_discounts_rec.amount = 0) THEN
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'NOT APPLYING ROUNDING DIFF TO THIS DISCOUNT' ) ;
             END IF;
          ELSE
             -- 3685479 Changed signature to pass adjustments table 
             Get_Rounding_Diff(p_line_rec => p_line_rec
                              ,p_interface_line_rec => p_interface_line_rec
                              ,p_adjustments_tbl => l_adjustments_tbl
                              , x_rounding_diff => l_rounding_diff);
             IF (l_rounding_diff IS NOT NULL AND l_rounding_diff <> 0) THEN
                l_discounts_rec.amount := l_discounts_rec.amount + l_rounding_diff;
                IF l_debug_level  > 0 THEN
                    oe_debug_pub.add(  'DISCOUNT TOTAL AFTER ADDING ROUNDING DIFF: '||L_DISCOUNTS_REC.AMOUNT , 5 ) ;
                END IF;

                Rounded_Amount(p_currency_code  => l_discounts_rec.currency_code
                               ,p_unrounded_amount => l_discounts_rec.amount
                               ,x_rounded_amount   => l_rounded_amount);

                l_discounts_rec.amount := l_rounded_amount;

                IF l_debug_level  > 0 THEN
                    oe_debug_pub.add(  'DISCOUNT TOTAL AFTER ADDING ROUNDING DIFF AND ROUNDING: '||L_DISCOUNTS_REC.AMOUNT , 5 ) ;
                END IF;
                l_discounts_rec.unit_selling_price := l_discounts_rec.amount /l_discounts_rec.quantity;
                IF l_debug_level  > 0 THEN
                    oe_debug_pub.add(  'DISCOUNT UNIT_SELLING_PRICE AFTER ADDING ROUNDING DIFF: '||L_DISCOUNTS_REC.UNIT_SELLING_PRICE , 5 ) ;
                END IF;
             END IF;
             l_rounding_diff_applied := 'Y';
          END IF;
       END IF;
       l_discounts_rec.Fob_Point      := NULL;
   --    l_discounts_rec.Ship_Via       := NULL; -- for bug# 5024576
      -- l_discounts_rec.Waybill_Number := NULL; -- for bug# 5751089
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'REFERENCE LINE_ID '||L_DISCOUNTS_REC.REFERENCE_LINE_ID , 5 ) ;
           oe_debug_pub.add(  'LINE CATEGORY CODE '||P_LINE_REC.LINE_CATEGORY_CODE , 5 ) ;
       END IF;
       IF p_line_rec.line_category_code = 'RETURN' AND l_discounts_rec.reference_line_id IS NOT NULL THEN
          -- 3645784 
          -- RT{Retrobill Lines with line type return will not have reference information populated
          -- So setting the reference info with original order Header_id and Line_id
          IF ( p_line_rec.order_source_id = 27) THEN
             l_ref_header_id := to_number(p_line_rec.orig_sys_document_ref);
             l_ref_line_id   := to_number(p_line_rec.orig_sys_line_ref);
             oe_debug_pub.add('Retro:After setting reference line id');
          ELSE
             FOR order_info_rec in order_info(p_line_rec.reference_line_id) loop
                 l_ref_header_id := order_info_rec.header_id;
                 l_ref_line_id   := order_info_rec.line_id;  
             END LOOP;
          END IF;
             oe_debug_pub.add('l_ref_header_id'||l_ref_header_id);
             oe_debug_pub.add('l_ref_line_id'||l_ref_line_id); 
           BEGIN
             SELECT dis.customer_trx_line_id
             INTO   l_reference_line_id
             FROM   RA_CUSTOMER_TRX_LINES_ALL DIS,
                    RA_CUSTOMER_TRX_LINES_ALL PAR
             WHERE  PAR.CUSTOMER_TRX_LINE_ID       = L_DISCOUNTS_REC.REFERENCE_LINE_ID
             AND    PAR.CUSTOMER_TRX_ID            = DIS.CUSTOMER_TRX_ID
             AND    DIS.INTERFACE_LINE_ATTRIBUTE6  = NVL(l_ref_line_id,DIS.INTERFACE_LINE_ATTRIBUTE6) --Bug2966839
             AND    DIS.INTERFACE_LINE_ATTRIBUTE11 = 
                   (SELECT D.PRICE_ADJUSTMENT_ID
                    FROM   OE_PRICE_ADJUSTMENTS D
                    WHERE  D.HEADER_ID                   = l_ref_header_id
                    AND    NVL(D.LINE_ID, l_ref_line_id) = l_ref_line_id
                    AND    D.APPLIED_FLAG = 'Y'          -- 3630426 Added for Retrobilling 
                    AND    D.LIST_LINE_ID                =
                          (SELECT D2.LIST_LINE_ID
                           FROM   OE_PRICE_ADJUSTMENTS D2
                           WHERE  D2.PRICE_ADJUSTMENT_ID = L_DISCOUNTS_REC.INTERFACE_LINE_ATTRIBUTE11));

             EXCEPTION
                       WHEN OTHERS THEN
                       -- 3661895 l_reference_line_id must be cleared when the sql fails 
                       l_reference_line_id := NULL; 
                       IF l_debug_level  > 0 THEN
                           oe_debug_pub.add(  'FAILED TO INSERT DISCOUNT RECORDS FOR THE RETURN LINES '||SQLERRM , 1 ) ;
                       END IF;
		       -- Added for the FP bug #3802957
		       l_reference_line_id := l_discounts_rec.Reference_Line_Id;
                       NULL;
             END;
             l_discounts_rec.Reference_Line_Id := l_reference_line_id;
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'REFERENCE LINE_ID FOR DISCOUNT LINE : '||L_DISCOUNTS_REC.REFERENCE_LINE_ID , 5 ) ;
             END IF;
          END IF;
          --  l_discounts_rec.Reference_Line_Id := NULL;
       l_discounts_rec.PROMISED_COMMITMENT_AMOUNT := NULL;
       l_discounts_rec.Attribute_Category := l_line_adj_rec.Context;
       l_discounts_rec.Attribute1 := substrb(l_line_adj_rec.Attribute1, 1, 150);
       l_discounts_rec.Attribute2 := substrb(l_line_adj_rec.Attribute2, 1, 150);
       l_discounts_rec.Attribute3 := substrb(l_line_adj_rec.Attribute3, 1, 150);
       l_discounts_rec.Attribute4 := substrb(l_line_adj_rec.Attribute4, 1, 150);
       l_discounts_rec.Attribute5 := substrb(l_line_adj_rec.Attribute5, 1, 150);
       l_discounts_rec.Attribute6 := substrb(l_line_adj_rec.Attribute6, 1, 150);
       l_discounts_rec.Attribute7 := substrb(l_line_adj_rec.Attribute7, 1, 150);
       l_discounts_rec.Attribute8 := substrb(l_line_adj_rec.Attribute8, 1, 150);
       l_discounts_rec.Attribute9 := substrb(l_line_adj_rec.Attribute9, 1, 150);
       l_discounts_rec.Attribute10 := substrb(l_line_adj_rec.Attribute10, 1, 150);
       l_discounts_rec.Attribute11 := substrb(l_line_adj_rec.Attribute11, 1, 150);
       l_discounts_rec.Attribute12 := substrb(l_line_adj_rec.Attribute12, 1, 150);
       l_discounts_rec.Attribute13 := substrb(l_line_adj_rec.Attribute13, 1, 150);
       l_discounts_rec.Attribute14 := substrb(l_line_adj_rec.Attribute14, 1, 150);
       l_discounts_rec.Attribute15 := substrb(l_line_adj_rec.Attribute15, 1, 150);

       Insert_Line(l_discounts_rec
                   ,x_return_status=>l_return_status);
       -- Fix for the bug 2187074
       IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       END IF;

       -- Populate salescredits for discount lines
       Interface_Salescredits(p_line_rec
                              ,l_discounts_rec
                              ,l_return_status);

    END LOOP;
END IF;
-- Fix for the bug 2187074
x_return_status := FND_API.G_RET_STS_SUCCESS;
IF l_debug_level  > 0 THEN
    oe_debug_pub.add(  'EXITING INTERFACE_DETAIL_DISCOUNTS ( ) PROCEDURE ' , 5 ) ;
END IF;

EXCEPTION
     WHEN OTHERS THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'EXCEPTION IN INTERFACE_DETAIL_DISCOUNTS '||SQLERRM , 1 ) ;
          END IF;
          -- Fix for the bug 2187074
          x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
          IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
             OE_MSG_PUB.Add_Exc_Msg (G_PKG_NAME , 'Interface_Detail_Discounts');
          END IF;

END Interface_Detail_Discounts;

PROCEDURE Update_Invoiced_Flag
(   p_price_adjustment_id  IN  NUMBER
,   p_adjusted_amount   IN NUMBER
,   p_invoiced_amount  IN NUMBER
,   x_return_status    OUT NOCOPY VARCHAR2
) IS
l_Header_Adj_tbl              OE_Order_PUB.Header_Adj_Tbl_Type;
l_Old_Header_Adj_tbl          OE_Order_PUB.Header_Adj_Tbl_Type;
l_return_status               VARCHAR2(30);
l_notify_index			NUMBER;  -- jolin

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTERING UPDATE_INVOICED_FLAG' , 1 ) ;
    END IF;
    OE_Header_Adj_Util.Lock_Rows
    	(P_PRICE_ADJUSTMENT_ID=>p_price_adjustment_id,
         X_HEADER_ADJ_TBL=>l_old_header_adj_tbl,
	     X_RETURN_STATUS => l_return_status);
    IF    l_return_status = FND_API.G_RET_STS_ERROR THEN
	      RAISE FND_API.G_EXC_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
	      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
    l_Header_Adj_tbl := l_old_Header_Adj_Tbl;
   
    oe_debug_pub.add('Charges Amount '||p_adjusted_amount);
    oe_debug_pub.add('Invoiced Amount'||p_invoiced_amount);
 
    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
       UPDATE OE_PRICE_ADJUSTMENTS
       SET    INVOICED_FLAG = 'Y'
              , INVOICED_AMOUNT = nvl(invoiced_amount,0) + p_invoiced_amount -- p_adjusted_amount Bug 5254866
              , LOCK_CONTROL = LOCK_CONTROL + 1
       WHERE  PRICE_ADJUSTMENT_ID = p_price_adjustment_id;
       
       --bug 4577365
       /*UPDATE OE_PRICE_ADJUSTMENTS
       SET  UPDATED_FLAG = 'Y'
       WHERE PRICE_ADJUSTMENT_ID = p_price_adjustment_id
	     AND line_id IS NOT NULL; */
     
       l_Header_Adj_tbl(1).Invoiced_Amount := l_Header_Adj_tbl(1).Invoiced_Amount+p_invoiced_amount;
    Else
       UPDATE OE_PRICE_ADJUSTMENTS
       SET    INVOICED_FLAG = 'Y'
              , UPDATED_FLAG = 'Y'
	      , LOCK_CONTROL = LOCK_CONTROL + 1
       WHERE  PRICE_ADJUSTMENT_ID = p_price_adjustment_id;
    End If;
    
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    l_Header_Adj_tbl(1).Invoiced_Flag := 'Y';
    l_Header_Adj_tbl(1).lock_control := l_Header_Adj_tbl(1).lock_control + 1;

  -- jolin start
  IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110508' THEN
  
  -- call notification framework to get header adj index position
    OE_ORDER_UTIL.Update_Global_Picture
	(p_Upd_New_Rec_If_Exists =>FALSE
	, p_hdr_adj_rec		=> l_Header_Adj_tbl(1)
	, p_old_hdr_adj_rec	=> l_Old_Header_Adj_tbl(1)
        , p_hdr_adj_id 		=> l_Header_Adj_tbl(1).price_adjustment_id
        , x_index 		=> l_notify_index
        , x_return_status 	=> l_return_status);
   
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'UPDATE_GLOBAL RETURN STATUS FOR HDR ADJ IS: ' || L_RETURN_STATUS ) ;
        oe_debug_pub.add(  'HDR ADJ INDEX IS: ' || L_NOTIFY_INDEX , 1 ) ;
    END IF;

   IF l_notify_index is not null then
     -- modify Global Picture
    OE_ORDER_UTIL.g_old_header_adj_tbl(l_notify_index) := l_old_header_adj_tbl(1);
    OE_ORDER_UTIL.g_header_adj_tbl(l_notify_index) := OE_ORDER_UTIL.g_old_header_adj_tbl(l_notify_index);
    OE_ORDER_UTIL.g_header_adj_tbl(l_notify_index).invoiced_amount:=
                        l_Header_Adj_tbl(1).invoiced_amount;
    OE_ORDER_UTIL.g_header_adj_tbl(l_notify_index).invoiced_flag:= 
			l_Header_Adj_tbl(1).invoiced_flag;
    OE_ORDER_UTIL.g_header_adj_tbl(l_notify_index).lock_control:= 
			l_header_adj_tbl(1).lock_control;
    OE_ORDER_UTIL.g_header_adj_tbl(l_notify_index).last_update_date:= 
			l_header_adj_tbl(1).last_update_date;
    OE_ORDER_UTIL.g_header_adj_tbl(l_notify_index).header_id:= 
			l_header_adj_tbl(1).header_id;
    OE_ORDER_UTIL.g_header_adj_tbl(l_notify_index).line_id:= 
			l_header_adj_tbl(1).line_id;

			IF l_debug_level  > 0 THEN
			    oe_debug_pub.add(  'GLOBAL HDR ADJ INVOICED_FLAG IS: ' || OE_ORDER_UTIL.G_HEADER_ADJ_TBL ( L_NOTIFY_INDEX ) .INVOICED_FLAG , 1 ) ;
			    oe_debug_pub.add(  'GLOBAL HDR ADJ LOCK_CONTROL IS: ' || OE_ORDER_UTIL.G_HEADER_ADJ_TBL ( L_NOTIFY_INDEX ) .LOCK_CONTROL , 1 ) ;

			 END IF;

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

-- Process requests is TRUE so still need to call it, but don't need to notify
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXPINVB: HDRADJ BEFORE CALLING PROCESS_REQUESTS_AND_NOTIFY' ) ;
  END IF;
    OE_Order_PVT.PROCESS_REQUESTS_AND_NOTIFY(
				P_HEADER_ADJ_TBL 	=>l_Header_Adj_tbl, 
                                P_OLD_HEADER_ADJ_TBL 	=>l_Old_Header_Adj_tbl, 
                                P_PROCESS_REQUESTS 	=> TRUE,
                                P_NOTIFY 		=> FALSE,
                                X_RETURN_STATUS 	=> l_return_status);  

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

   END IF ; /* global entity index null check */

  ELSE /* pre-pack H */

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'OEXPINVB: HDRADJ BEFORE CALLING PROCESS_REQUESTS_AND_NOTIFY' ) ;
  END IF;
    OE_Order_PVT.PROCESS_REQUESTS_AND_NOTIFY(
				P_HEADER_ADJ_TBL 	=>l_Header_Adj_tbl, 
                                P_OLD_HEADER_ADJ_TBL 	=>l_Old_Header_Adj_tbl, 
                                P_PROCESS_REQUESTS 	=> TRUE,
                                P_NOTIFY 		=> TRUE,
                                X_RETURN_STATUS 	=> l_return_status);  

    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    END IF; /* code set is pack H or higher */
    /* jolin end*/

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXIT UPDATE_INVOICED_FLAG ( ) PROCEDURE' , 1 ) ;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        IF      FND_MSG_PUB.Check_Msg_Level(FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
        THEN
                OE_MSG_PUB.Add_Exc_Msg
                        (   G_PKG_NAME
                        ,   'Update_Invoiced_flag'
                        );
        END IF;
END Update_Invoiced_Flag;

PROCEDURE Prepare_Freight_Charges_Rec
(  p_line_rec       IN OE_Order_Pub.Line_Rec_Type
,  p_x_charges_rec  IN  OUT NOCOPY RA_Interface_Lines_Rec_Type
) IS
-- l_vat_flag         VARCHAR2(1);
l_freight_as_line  VARCHAR2(1);
l_freight_item     NUMBER;
l_reference_line_id NUMBER;

l_ref_header_id    NUMBER;
l_ref_line_id      NUMBER;
l_ref_order_number VARCHAR2(30);
l_ref_order_type   VARCHAR2(30);
l_rounded_amount   NUMBER;
l_user_id          NUMBER;
l_resp_id          NUMBER;
l_appl_id          NUMBER;

CURSOR ORDER_INFO(c_line_id NUMBER) IS
SELECT ooh.header_id
     , ool.line_id
     , ooh.order_number
     , ott.name order_type
FROM   oe_order_lines ool,
       oe_order_headers ooh,
       oe_transaction_types_tl ott
WHERE  ool.line_id             = c_line_id
AND    ooh.header_id           = ool.header_id
AND    ott.transaction_type_id = ooh.order_type_id
AND    ott.language            =
      (select language_code
       from   fnd_languages
       where  installed_flag = 'B');
       --
       l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
       --
BEGIN
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'ENTER PREPARE_FREIGHT_CHARGES_REC ( ) PROCEDURE ' , 5 ) ;
       oe_debug_pub.add(  'PREPARING FOR CHARGE ID : '|| P_X_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 ) ;
   END IF;

   -- Do not set mandatory grouping columns to different value than order line.
   -- This can cause freight charges to group into different invoice (if values
   -- are different from sales order line)
   p_x_charges_rec.INTERFACE_LINE_ATTRIBUTE5  := 1;
   p_x_charges_rec.INTERFACE_LINE_ATTRIBUTE7  := '0'; --picking line id
   p_x_charges_rec.INTERFACE_LINE_ATTRIBUTE8  := '0'; -- bill_of_lading;
   p_x_charges_rec.INTERFACE_LINE_ATTRIBUTE9  := '0'; -- customer item number
   p_x_charges_rec.INTERFACE_LINE_ATTRIBUTE12 := lpad('0', 30); -- shipment number
   p_x_charges_rec.INTERFACE_LINE_ATTRIBUTE13 := lpad('0', 30); -- option number
   p_x_charges_rec.INTERFACE_LINE_ATTRIBUTE14 := lpad('0', 30); -- service number
   -- l_vat_flag := NVL(FND_PROFILE.VALUE('AR_ALLOW_TAX_CODE_OVERRIDE'), 'N');
   Get_Createdby_Context(p_line_id => p_line_rec.line_id,
                         x_user_id      => l_user_id,
                         x_resp_id      => l_resp_id,
                         x_resp_appl_id => l_appl_id);
   l_freight_as_line := NVL(FND_PROFILE.VALUE_SPECIFIC('OE_INVOICE_FREIGHT_AS_LINE', l_user_id,l_resp_id,l_appl_id), 'N');
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'INVOICE FREIGHT AS REVENUE '||L_FREIGHT_AS_LINE ) ;
   END IF;
   l_freight_item := FND_PROFILE.VALUE_SPECIFIC('OE_INVENTORY_ITEM_FOR_FREIGHT', l_user_id,l_resp_id,l_appl_id);
   /* VAT on freight
        if vat_flag = 'Y'
           if freight_as_line = 'Y'
             if freight_item is NULL
               o inventory_item_id = NULL
               o description = lookup meaning for FREIGHT
               o line_type = 'LINE'
             else
               o inventory_item_id = freight_item
               o description = freight item's description
               o line_type = 'LINE'
           else
               o inventory_item_id = NULL
               o description = lookup meaning for FREIGHT
               o line_type = 'FREIGHT'
       if vat = 'Y' and freight_as_line = 'Y' and freight_item not null
          get description from mtl_system_items
       else
          get description from ar_lookups */

   -- per bug 2382340, take out the dependency on AR_ALLOW_TAX_CODE_OVERRIDE.
   -- IF l_vat_flag = 'Y' AND l_freight_as_line = 'Y'AND l_freight_item IS NOT NULL THEN
   BEGIN
   IF l_freight_as_line = 'Y'AND l_freight_item IS NOT NULL THEN
     SELECT description
            ,primary_uom_code
     INTO   p_x_charges_rec.Description
            ,p_x_charges_rec.Uom_Code
     FROM   mtl_system_items
     WHERE  inventory_item_id = l_freight_item
     AND    organization_id =  oe_sys_parameters.value('MASTER_ORGANIZATION_ID', p_line_rec.org_id);
   ELSE
     SELECT meaning
            ,NULL
     INTO   p_x_charges_rec.Description
            ,p_x_charges_rec.Uom_Code
     FROM   ar_lookups
     WHERE  lookup_type = 'STD_LINE_TYPE'
     AND    lookup_code = 'FREIGHT';
   END IF;
    
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
          FND_MESSAGE.SET_NAME('ONT','ONT_FREIGHT_ITEM_REQUIRED');
          OE_MSG_PUB.ADD;
         END IF;

         RAISE FND_API.G_EXC_ERROR;
   END;

   IF l_freight_as_line = 'Y' THEN
      IF l_freight_item IS NULL THEN
         p_x_charges_rec.Inventory_Item_Id := NULL;
         p_x_charges_rec.Line_Type := 'LINE';
      ELSE
         p_x_charges_rec.Inventory_Item_Id := l_freight_item;
         p_x_charges_rec.Line_Type := 'LINE';
      END IF;
   ELSE
     p_x_charges_rec.Inventory_Item_Id := NULL;
     p_x_charges_rec.Line_Type := 'FREIGHT';
     p_x_charges_rec.Tax_Exempt_Flag := NULL;
     p_x_charges_rec.Tax_Exempt_Number := NULL;
     p_x_charges_rec.Tax_Exempt_Reason_Code :=  NULL;
   END IF;

   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'LINE TYPE IS SET AS ' ||P_X_CHARGES_REC.LINE_TYPE , 1 ) ;
   END IF;

     p_x_charges_rec.Quantity := NULL;
     p_x_charges_rec.Quantity_Ordered := NULL;
     p_x_charges_rec.Unit_Selling_Price := NULL;
     p_x_charges_rec.Unit_Standard_Price := NULL;

     Rounded_Amount(p_currency_code => p_x_charges_rec.currency_code
                   ,p_unrounded_amount => p_x_charges_rec.amount
                   ,x_rounded_amount => l_rounded_amount );

     p_x_charges_rec.amount := l_rounded_amount;

     p_x_charges_rec.Sales_Order_Line := NULL;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'LINE CATEGORY CODE : '||P_LINE_REC.LINE_CATEGORY_CODE , 5 ) ;
     END IF;
     -- Change made for the FP bug #3802957
     IF p_line_rec.line_category_code = 'RETURN' then
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'REFERENCE LINE_ID FOR FREIGHT RECORD BEFORE : '||P_X_CHARGES_REC.REFERENCE_LINE_ID , 5 ) ;
            oe_debug_pub.add(  'P_LINE_REC.REFERENCE_LINE_ID : '||P_LINE_REC.REFERENCE_LINE_ID , 5 ) ;
            oe_debug_pub.add(  'INTERFACE_LINE_ATTRIBUTE6 : '||P_X_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 , 5 ) ;
        END IF;
       
        -- 3645784
          -- RT{Retrobill lines will not have freight charges applied
          -- so for retrobill lines shouldnt come to this part at all
          -- But still coded it so that it doesnt fail 
          IF ( p_line_rec.order_source_id = 27) THEN
             l_ref_header_id    := to_number(p_line_rec.orig_sys_document_ref);
             l_ref_line_id      := to_number(p_line_rec.orig_sys_line_ref);
          ELSE
             FOR order_info_rec in ORDER_INFO(p_line_rec.reference_line_id) LOOP
             l_ref_header_id    := order_info_rec.header_id;
             l_ref_line_id      := order_info_rec.line_id;
             l_ref_order_number := to_char(order_info_rec.order_number);
             l_ref_order_type   := order_info_rec.order_type;
             END LOOP;
          END IF;

        BEGIN

          SELECT FRE.customer_trx_line_id
          INTO   l_reference_line_id
          FROM   RA_CUSTOMER_TRX_LINES_ALL FRE
          WHERE  FRE.LINE_TYPE IN ('LINE', 'FREIGHT')
          AND    FRE.INTERFACE_LINE_CONTEXT    = 'ORDER ENTRY'
          AND    FRE.INTERFACE_LINE_ATTRIBUTE1 = l_ref_order_number
          AND    FRE.INTERFACE_LINE_ATTRIBUTE2 = l_ref_order_type
          AND    FRE.INTERFACE_LINE_ATTRIBUTE6 = 
                (SELECT TO_CHAR(D.PRICE_ADJUSTMENT_ID)
                 FROM   OE_PRICE_ADJUSTMENTS D
                 WHERE  D.HEADER_ID                   = l_ref_header_id
                 AND    NVL(D.LINE_ID, l_ref_line_id) = l_ref_line_id
                 AND    D.LIST_LINE_ID                = 
                       (SELECT D2.LIST_LINE_ID
                        FROM   OE_PRICE_ADJUSTMENTS D2
                        WHERE  D2.PRICE_ADJUSTMENT_ID=p_x_charges_rec.INTERFACE_LINE_ATTRIBUTE6));

          EXCEPTION
             WHEN OTHERS THEN
                  IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  'UNABLE TO FIND REFERENCE LINE ID : '||SQLERRM , 1 ) ;
                  END IF;
                  NULL;
        END;
        IF l_reference_line_id IS NULL THEN
           BEGIN
               SELECT ra1.customer_trx_line_id 
               INTO   l_reference_line_id
               from   ra_customer_trx_lines ra1, 
                      ra_customer_trx_lines ra2 
               where  ra2.customer_trx_line_id = p_x_charges_rec.reference_line_id 
               and    ra1.customer_trx_id = ra2.customer_trx_id 
               and    ra1.line_type = 'FREIGHT' 
               and    ra1.request_id is not null; 
           EXCEPTION
               WHEN OTHERS THEN
                    IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'UNABLE TO FIND REFERENCE LINE ID - 2 : '||SQLERRM , 1 ) ;
                    END IF;
                    NULL;
           END;
        END IF;
        p_x_charges_rec.Reference_Line_Id := l_reference_line_id;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'REFERENCE LINE_ID FOR FREIGHT LINE AFTER : '||P_X_CHARGES_REC.REFERENCE_LINE_ID , 5 ) ;
        END IF;
     end if;
     --  IF p_line_rec.commitment_id is not null then
     --     re populate cust_trx_type_id which was nulled out for interface line
     --     p_x_charges_rec.Cust_Trx_Type_Id := Get_Customer_Transaction_Type(p_line_rec);
     --  END IF;
     p_x_charges_rec.PROMISED_COMMITMENT_AMOUNT := NULL;
     -- Adding for bug# 4071442
      IF p_x_charges_rec.LINE_TYPE = 'FREIGHT' OR
         nvl(FND_PROFILE.VALUE('ONT_TAX_CODE_FOR_FREIGHT'), 'N') = 'N'  THEN
         p_x_charges_rec.Tax_Code := NULL;
         IF l_debug_level  > 0 THEN
            oe_debug_pub.add('tax_code for freight is set as ' ||p_x_charges_rec.tax_code , 5 ) ;
         END IF;
      END IF;

     -- bug 2509121.
     -- translated description is only needed for sales order line.
     IF p_x_charges_rec.translated_description is not null THEN
        p_x_charges_rec.translated_description := null;
     END IF;

     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'EXIT PREPARE_FREIGHT_CHARGES_REC ( ) PROCEDURE' , 5 ) ;
     END IF;
END Prepare_Freight_Charges_Rec;

PROCEDURE Interface_Freight_Charges
(  p_line_rec  IN OE_Order_Pub.Line_Rec_Type
,  p_interface_line_rec  IN  RA_Interface_Lines_Rec_Type
,  x_return_status   OUT NOCOPY VARCHAR2
) IS
l_charges_rec      RA_Interface_Lines_Rec_Type;
l_return_status    VARCHAR2(30);
l_line_rec         OE_Order_Pub.Line_Rec_Type;
config_line_id     NUMBER;
l_invoiced_amount  NUMBER;
l_charge_amount    NUMBER;
l_count1           NUMBER := 0;
l_count2           NUMBER := 0 ;
v_record_locked    VARCHAR2(30);
CURSOR Line_Charges_Cursor(p_header_id IN NUMBER, p_line_id IN NUMBER) IS
   SELECT CHARGE_ID
         ,CHARGE_NAME
         ,CHARGE_AMOUNT
	 ,nvl(INVOICED_AMOUNT,CHARGE_AMOUNT)
         ,CURRENCY_CODE
         ,CONTEXT
         ,substrb(ATTRIBUTE1, 1, 150)
         ,substrb(ATTRIBUTE2, 1, 150)
         ,substrb(ATTRIBUTE3, 1, 150)
         ,substrb(ATTRIBUTE4, 1, 150)
         ,substrb(ATTRIBUTE5, 1, 150)
         ,substrb(ATTRIBUTE6, 1, 150)
         ,substrb(ATTRIBUTE7, 1, 150)
         ,substrb(ATTRIBUTE8, 1, 150)
         ,substrb(ATTRIBUTE9, 1, 150)
         ,substrb(ATTRIBUTE10, 1, 150)
         ,substrb(ATTRIBUTE11, 1, 150)
         ,substrb(ATTRIBUTE12, 1, 150)
         ,substrb(ATTRIBUTE13, 1, 150)
         ,substrb(ATTRIBUTE14, 1, 150)
         ,substrb(ATTRIBUTE15, 1, 150)
   FROM   oe_charge_lines_v
   WHERE  header_id = p_header_id
   AND    line_id = p_line_id
   AND    nvl(invoiced_flag, 'N') = 'N';

CURSOR Header_Charges_Cursor(p_header_id IN NUMBER, p_line_id IN NUMBER) IS
   SELECT CHARGE_ID
         ,CHARGE_NAME
         ,CHARGE_AMOUNT
	 ,nvl(INVOICED_AMOUNT,CHARGE_AMOUNT)
         ,CURRENCY_CODE
         ,CONTEXT
         ,substrb(ATTRIBUTE1, 1, 150)
         ,substrb(ATTRIBUTE2, 1, 150)
         ,substrb(ATTRIBUTE3, 1, 150)
         ,substrb(ATTRIBUTE4, 1, 150)
         ,substrb(ATTRIBUTE5, 1, 150)
         ,substrb(ATTRIBUTE6, 1, 150)
         ,substrb(ATTRIBUTE7, 1, 150)
         ,substrb(ATTRIBUTE8, 1, 150)
         ,substrb(ATTRIBUTE9, 1, 150)
         ,substrb(ATTRIBUTE10, 1, 150)
         ,substrb(ATTRIBUTE11, 1, 150)
         ,substrb(ATTRIBUTE12, 1, 150)
         ,substrb(ATTRIBUTE13, 1, 150)
         ,substrb(ATTRIBUTE14, 1, 150)
         ,substrb(ATTRIBUTE15, 1, 150)
   FROM   oe_charge_lines_v
   WHERE  header_id = p_line_rec.header_id
   AND    line_id IS NULL
   AND    nvl(invoiced_flag, 'N') = 'N';

   -- removed update nowait clause to fix #5590839
   -- for update nowait;   -- Bug #3686558

CURSOR Modified_Header_Charges_Cursor(p_header_id IN NUMBER, p_line_id IN NUMBER) IS
   SELECT CHARGE_ID
         ,CHARGE_NAME
         ,(CHARGE_AMOUNT -  INVOICED_AMOUNT)
         ,CHARGE_AMOUNT
         --,INVOICED_AMOUNT
         ,(CHARGE_AMOUNT -  INVOICED_AMOUNT) -- should be diff amount which is not rounded, for bug 5254866
         ,CURRENCY_CODE
         ,CONTEXT
         ,substrb(ATTRIBUTE1, 1, 150)
         ,substrb(ATTRIBUTE2, 1, 150)
         ,substrb(ATTRIBUTE3, 1, 150)
         ,substrb(ATTRIBUTE4, 1, 150)
         ,substrb(ATTRIBUTE5, 1, 150)
         ,substrb(ATTRIBUTE6, 1, 150)
         ,substrb(ATTRIBUTE7, 1, 150)
         ,substrb(ATTRIBUTE8, 1, 150)
         ,substrb(ATTRIBUTE9, 1, 150)
         ,substrb(ATTRIBUTE10, 1, 150)
         ,substrb(ATTRIBUTE11, 1, 150)
         ,substrb(ATTRIBUTE12, 1, 150)
         ,substrb(ATTRIBUTE13, 1, 150)
         ,substrb(ATTRIBUTE14, 1, 150)
         ,substrb(ATTRIBUTE15, 1, 150)
   FROM   oe_charge_lines_v
   WHERE  header_id = p_header_id
   AND    line_id IS NULL
   AND    nvl(invoiced_flag, 'N') = 'Y'
   AND    invoiced_amount IS NOT NULL
   AND    invoiced_amount <> charge_amount;

   -- removed update nowait clause to fix #5590839
   -- for update nowait;   -- Bug #3686558

CURSOR    config_for_model (l_line_id NUMBER) IS
   SELECT LINE_ID 
   FROM   OE_ORDER_LINES
   WHERE  LINK_TO_LINE_ID = l_line_id
   AND    ITEM_TYPE_CODE = 'CONFIG';

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'ENTER INTERFACE_FREIGHT_CHARGES ( ) PROCEDURE' , 5 ) ;
     END IF;
     l_charges_rec := p_interface_line_rec;
     OPEN Line_Charges_Cursor(p_line_rec.header_id, p_line_rec.line_id);
     LOOP
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'IN THE LOOP: L_CHARGES_REC.CHARGE_ID: '|| L_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 , 5 ) ;
        END IF;
        FETCH  Line_Charges_Cursor INTO
        l_charges_rec.INTERFACE_LINE_ATTRIBUTE6 -- charge_id
       ,l_charges_rec.description
       ,l_charges_rec.amount
       ,l_invoiced_amount 
       ,l_charges_rec.currency_code
       ,l_charges_rec.attribute_category
       ,l_charges_rec.attribute1
       ,l_charges_rec.attribute2
       ,l_charges_rec.attribute3
       ,l_charges_rec.attribute4
       ,l_charges_rec.attribute5
       ,l_charges_rec.attribute6
       ,l_charges_rec.attribute7
       ,l_charges_rec.attribute8
       ,l_charges_rec.attribute9
       ,l_charges_rec.attribute10
       ,l_charges_rec.attribute11
       ,l_charges_rec.attribute12
       ,l_charges_rec.attribute13
       ,l_charges_rec.attribute14
       ,l_charges_rec.attribute15;
        EXIT WHEN Line_Charges_Cursor%NOTFOUND;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'IN THE LOOP 1: L_CHARGES_REC.CHARGE_ID: '|| L_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 , 5 ) ;
   	    oe_debug_pub.add(  'INVOICE SOURCE BEFORE CALLING PREPARE_FREIGHT_CHARGES_REC '|| L_CHARGES_REC.BATCH_SOURCE_NAME , 5 ) ;
        END IF;
        --prepare l_charges_rec
        Prepare_Freight_Charges_Rec(p_line_rec    => p_line_rec
                                    ,p_x_charges_rec => l_charges_rec);
        IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'INVOICE SOURCE AFTER : '|| L_CHARGES_REC.BATCH_SOURCE_NAME , 5 ) ;
           oe_debug_pub.add(  'FREIGHT LINE TYPE : '||L_CHARGES_REC.LINE_TYPE , 5 ) ;
        END IF;
        IF l_charges_rec.Amount = 0 THEN
           -- Issue Message (Zero Amount Freight Charge not interfaced)
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'ZERO AMOUNT FREIGHT NOT INTERFACED' , 5 ) ;
           END IF;
        ELSE
           Insert_Line(l_charges_rec
                       ,x_return_status=>l_return_status);
           -- Fix for the bug 2187074
           IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;

           IF l_charges_rec.line_type = 'LINE' THEN
              Interface_scredits_for_freight
                                 (p_line_rec => p_line_rec
                                , p_interface_line_rec => l_charges_rec
                                , p_line_level_charge => 'Y');
           END IF;
           --Set oe_price_adjustment.Invoiced_flag for the interfaced charge line
           Update_Invoiced_Flag(to_number(l_charges_rec.INTERFACE_LINE_ATTRIBUTE6)
				,l_charges_rec.amount
				,l_invoiced_amount
                                ,l_return_status);
        END IF;
     END LOOP;
     CLOSE Line_Charges_Cursor;
     --Bug2465201
     IF p_line_rec.item_type_code IN ( 'MODEL','CLASS') THEN
        OPEN CONFIG_FOR_MODEL (p_line_rec.line_id);
        FETCH CONFIG_FOR_MODEL INTO config_line_id;
        CLOSE CONFIG_FOR_MODEL;

        IF config_line_id IS NOT NULL THEN
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'FOUND CONFIG LINE : '||CONFIG_LINE_ID , 1 ) ;
           END IF;
           -- Initialize API return status to success
           x_return_status := FND_API.G_RET_STS_SUCCESS;
           OE_Line_Util.Lock_Row(p_line_id=>config_line_id
           		, p_x_line_rec => l_line_rec
            		, x_return_status => l_return_status
              	    	);
           IF    l_return_status = FND_API.G_RET_STS_ERROR THEN
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'UNABLE TO LOCK LINE ID '||CONFIG_LINE_ID||' '||SQLERRM , 1 ) ;
              END IF;
       	      RAISE FND_API.G_EXC_ERROR;
           ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'UNABLE TO LOCK LINE ID '||CONFIG_LINE_ID||' '||SQLERRM , 1 ) ;
              END IF;
       	      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'INTERFACING OTHER CHARGES ASSOCIATED WITH THIS MODEL..' , 1 ) ;
           END IF;
           OPEN Line_Charges_Cursor(p_line_rec.header_id, config_line_id);
           LOOP
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'IN THE LOOP: L_CHARGES_REC.CHARGE_ID: '|| L_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 , 5 ) ;
              END IF;
              FETCH  Line_Charges_Cursor INTO
              l_charges_rec.INTERFACE_LINE_ATTRIBUTE6 -- charge_id
             ,l_charges_rec.description
             ,l_charges_rec.amount
             ,l_invoiced_amount 
             ,l_charges_rec.currency_code
             ,l_charges_rec.attribute_category
             ,l_charges_rec.attribute1
             ,l_charges_rec.attribute2
             ,l_charges_rec.attribute3
             ,l_charges_rec.attribute4
             ,l_charges_rec.attribute5
             ,l_charges_rec.attribute6
             ,l_charges_rec.attribute7
             ,l_charges_rec.attribute8
             ,l_charges_rec.attribute9
             ,l_charges_rec.attribute10
             ,l_charges_rec.attribute11
             ,l_charges_rec.attribute12
             ,l_charges_rec.attribute13
             ,l_charges_rec.attribute14
             ,l_charges_rec.attribute15;
              EXIT WHEN Line_Charges_Cursor%NOTFOUND;
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'IN THE LOOP 1: L_CHARGES_REC.CHARGE_ID: '|| L_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 , 5 ) ;
                  oe_debug_pub.add(  'INVOICE SOURCE BEFORE CALLING PREPARE_FREIGHT_CHARGES_REC '|| L_CHARGES_REC.BATCH_SOURCE_NAME , 5 ) ;
              END IF;
              --prepare l_charges_rec
              Prepare_Freight_Charges_Rec(p_line_rec    => p_line_rec
                                          ,p_x_charges_rec => l_charges_rec);
      	      IF l_debug_level  > 0 THEN
      	          oe_debug_pub.add(  'INVOICE SOURCE AFTER : '|| L_CHARGES_REC.BATCH_SOURCE_NAME , 5 ) ;
                  oe_debug_pub.add(  'FREIGHT LINE TYPE : '||L_CHARGES_REC.LINE_TYPE , 5 ) ;
              END IF;
              IF l_charges_rec.Amount = 0 THEN
                 -- Issue Message (Zero Amount Freight Charge not interfaced)
                 IF l_debug_level  > 0 THEN
                     oe_debug_pub.add(  'ZERO AMOUNT FREIGHT NOT INTERFACED' , 5 ) ;
                 END IF;
              ELSE
                 Insert_Line(l_charges_rec
                             ,x_return_status=>l_return_status);
                 -- Fix for the bug 2187074
                 IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                 END IF;
        
    /*   Added for the bug 3019754   */ 
                 IF l_charges_rec.line_type = 'LINE' THEN
              Interface_scredits_for_freight
                                 (p_line_rec => p_line_rec
                                , p_interface_line_rec => l_charges_rec
                                , p_line_level_charge => 'Y');
                 END IF;

                 --Set oe_price_adjustment.Invoiced_flag for the interfaced charge line
                 Update_Invoiced_Flag(to_number(l_charges_rec.INTERFACE_LINE_ATTRIBUTE6)
				      ,l_charges_rec.amount
         			      ,l_invoiced_amount
				      ,l_return_status);
              END IF;
           END LOOP;
           CLOSE Line_Charges_Cursor;
        END IF;
     END IF;      
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add('#5590839, lock the header charge record before interfacing header charges',1);
     END IF;

     l_charges_rec := p_interface_line_rec;

     BEGIN

     SELECT 'Lock this Header'
     INTO   v_record_locked
     FROM   OE_PRICE_ADJUSTMENTS 
     WHERE  HEADER_ID = p_line_rec.header_id
     AND    LINE_ID IS NULL
     FOR    UPDATE NOWAIT;

     EXCEPTION WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN
                    RAISE;
               WHEN OTHERS THEN
                    NULL;
     END;

     OPEN Header_Charges_Cursor(p_line_rec.header_id, p_line_rec.line_id);
     LOOP
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'IN THE LOOP: L_CHARGES_REC.CHARGE_ID: '|| L_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 ) ;
        END IF;
        FETCH  Header_Charges_Cursor INTO
        l_charges_rec.INTERFACE_LINE_ATTRIBUTE6 -- charge_id
       ,l_charges_rec.description
       ,l_charges_rec.amount
       ,l_invoiced_amount 
       ,l_charges_rec.currency_code
       ,l_charges_rec.attribute_category
       ,l_charges_rec.attribute1
       ,l_charges_rec.attribute2
       ,l_charges_rec.attribute3
       ,l_charges_rec.attribute4
       ,l_charges_rec.attribute5
       ,l_charges_rec.attribute6
       ,l_charges_rec.attribute7
       ,l_charges_rec.attribute8
       ,l_charges_rec.attribute9
       ,l_charges_rec.attribute10
       ,l_charges_rec.attribute11
       ,l_charges_rec.attribute12
       ,l_charges_rec.attribute13
       ,l_charges_rec.attribute14
       ,l_charges_rec.attribute15;

        EXIT WHEN Header_Charges_Cursor%NOTFOUND;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'IN THE LOOP 1: L_CHARGES_REC.CHARGE_ID: '|| L_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 ) ;
   	    oe_debug_pub.add(  'INVOICE SOURCE BEFORE CALLING PREPARE_FREIGHT_CHARGES_REC '|| L_CHARGES_REC.BATCH_SOURCE_NAME ) ;
   	END IF;
        --prepare l_charges_rec
        Prepare_Freight_Charges_Rec(p_line_rec    => p_line_rec
                                   ,p_x_charges_rec => l_charges_rec);
	IF l_debug_level  > 0 THEN
	   oe_debug_pub.add(  'INVOICE SOURE AFTER CALLING PREPARE_FREIGHT_CHARGES_REC '|| L_CHARGES_REC.BATCH_SOURCE_NAME ) ;
           oe_debug_pub.add(  'FREIGHT LINE TYPE: '||L_CHARGES_REC.LINE_TYPE ) ;
        END IF;
        IF l_charges_rec.Amount = 0 THEN
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  ' ZERO AMOUNT FREIGHT NOT INTERFACED' , 5 ) ;
           END IF;
        ELSE
           Insert_Line(l_charges_rec
                       ,x_return_status=>l_return_status);
           -- Fix for the bug 2187074
           IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;

           IF l_charges_rec.line_type = 'LINE' THEN
              Interface_scredits_for_freight
                                 (p_line_rec => p_line_rec
                                , p_interface_line_rec => l_charges_rec
                                , p_line_level_charge => 'N');
           END IF;
           --Set oe_price_adjustment.Invoiced_flag for the interfaced charge line
           Update_Invoiced_Flag(to_number(l_charges_rec.INTERFACE_LINE_ATTRIBUTE6)
                                ,l_charges_rec.amount
         			,l_invoiced_amount
				,l_return_status);
        END IF;
     END LOOP;
     CLOSE Header_Charges_Cursor;
     x_return_status := FND_API.G_RET_STS_SUCCESS;
     
     IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
        IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'INTERFACING Modified HEADER CHARGES...' , 1 ) ;
        END IF;
        l_charges_rec := p_interface_line_rec;
        OPEN Modified_Header_Charges_Cursor(p_line_rec.header_id, p_line_rec.line_id);
        LOOP
         IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'IN THE LOOP: L_CHARGES_REC.CHARGE_ID: '|| L_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 ) ;
         END IF;
        FETCH  Modified_Header_Charges_Cursor INTO
           l_charges_rec.INTERFACE_LINE_ATTRIBUTE6 -- charge_id
          ,l_charges_rec.description
          ,l_charges_rec.amount
          ,l_charge_amount
          ,l_invoiced_amount
          ,l_charges_rec.currency_code
          ,l_charges_rec.attribute_category
          ,l_charges_rec.attribute1
          ,l_charges_rec.attribute2
          ,l_charges_rec.attribute3
          ,l_charges_rec.attribute4
          ,l_charges_rec.attribute5
          ,l_charges_rec.attribute6
          ,l_charges_rec.attribute7
          ,l_charges_rec.attribute8
          ,l_charges_rec.attribute9
          ,l_charges_rec.attribute10
          ,l_charges_rec.attribute11
          ,l_charges_rec.attribute12
          ,l_charges_rec.attribute13
          ,l_charges_rec.attribute14
          ,l_charges_rec.attribute15;
        EXIT WHEN Modified_Header_Charges_Cursor%NOTFOUND;
        IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'IN THE LOOP 1: L_CHARGES_REC.CHARGE_ID: '|| L_CHARGES_REC.INTERFACE_LINE_ATTRIBUTE6 ) ;
           oe_debug_pub.add(  'Charge_Amount:'||l_charge_amount ||':Invoiced_Amount:'||l_invoiced_amount) ;
        END IF;

        --prepare l_charges_rec
        Prepare_Freight_Charges_Rec(p_line_rec    => p_line_rec
                                   ,p_x_charges_rec => l_charges_rec);

       SELECT nvl(max(interface_line_attribute5),0)  --Bug 3338492
       INTO   l_count1
       FROM   ra_interface_lines_all
       WHERE  interface_line_context = 'ORDER ENTRY'
       AND    interface_line_attribute1 = l_charges_rec.INTERFACE_LINE_ATTRIBUTE1
       AND    interface_line_attribute2 = l_charges_rec.INTERFACE_LINE_ATTRIBUTE2
       AND    interface_line_attribute6 = l_charges_rec.INTERFACE_LINE_ATTRIBUTE6
       AND    interface_line_attribute11 = '0'
       AND    NVL(interface_status, '~') <> 'P';
       SELECT nvl(max(interface_line_attribute5),0)
       INTO   l_count2
       FROM   ra_customer_trx_lines_all
       WHERE  interface_line_context = 'ORDER ENTRY'
       AND    interface_line_attribute1 = l_charges_rec.INTERFACE_LINE_ATTRIBUTE1
       AND    interface_line_attribute2 = l_charges_rec.INTERFACE_LINE_ATTRIBUTE2
       AND    interface_line_attribute6 = l_charges_rec.INTERFACE_LINE_ATTRIBUTE6
       AND    interface_line_attribute11 = '0';

       IF l_count1 > l_count2 THEN
          l_charges_rec.INTERFACE_LINE_ATTRIBUTE5 := l_count1 + 1 ;
       ELSE
          l_charges_rec.INTERFACE_LINE_ATTRIBUTE5 := l_count2 + 1 ;
       END IF;

       IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'INTERFACE_LINE_ATTRIBUTE5: '|| l_charges_rec.INTERFACE_LINE_ATTRIBUTE5 , 5 ) ;
          oe_debug_pub.add(  'INVOICE SOURE AFTER CALLING PREPARE_FREIGHT_CHARGES_REC '|| L_CHARGES_REC.BATCH_SOURCE_NAME ) ;
          oe_debug_pub.add(  'FREIGHT LINE TYPE: '||L_CHARGES_REC.LINE_TYPE ) ;
       END IF;

       IF l_charges_rec.Amount = 0 THEN
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  ' ZERO AMOUNT FREIGHT NOT INTERFACED' , 5 ) ;
        END IF;
       ELSE
           Insert_Line(l_charges_rec
                       ,x_return_status=>l_return_status);
           -- Fix for the bug 2187074
           IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;

           IF l_charges_rec.line_type = 'LINE' THEN
              Interface_scredits_for_freight
                                 (p_line_rec => p_line_rec
                                , p_interface_line_rec => l_charges_rec
                                , p_line_level_charge => 'N');
           END IF;
           --Set oe_price_adjustment.Invoiced_flag for the interfaced charge line
           Update_Invoiced_Flag(to_number(l_charges_rec.INTERFACE_LINE_ATTRIBUTE6)
                                , l_charges_rec.amount
                                 ,l_invoiced_amount
                                 ,l_return_status);
       END IF;
     END LOOP;
     CLOSE Modified_Header_Charges_Cursor;
     x_return_status := FND_API.G_RET_STS_SUCCESS;
     END IF;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'EXITING INTERFACE_FREIGHT_CHARGES' , 5 ) ;
     END IF;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXPECTED ERROR. EXITING INTERFACE_FREIGHT_CHARGES : '||SQLERRM , 1 ) ;
         END IF;
         x_return_status := FND_API.G_RET_STS_ERROR;
    WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN   -- Bug #3686558
         IF l_debug_level > 0 THEN
            OE_DEBUG_PUB.Add('Unable to lock the line',3);
         END IF;
         x_return_status := FND_API.G_RET_STS_SUCCESS;
    WHEN OTHERS THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXCEPTION , INTERFACE_FREIGHT_CHARGES ( ) '||SQLERRM , 1 ) ;
         END IF;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         IF      FND_MSG_PUB.Check_Msg_Level
                (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
         THEN
                OE_MSG_PUB.Add_Exc_Msg
                        (   G_PKG_NAME
                        ,   'Interface_Freight_Charges'
                        );
         END IF;
         IF (Line_Charges_Cursor%ISOPEN) THEN
            CLOSE Line_Charges_Cursor;
         END IF;
         IF (Header_Charges_Cursor%ISOPEN) THEN
            CLOSE Header_Charges_Cursor;
         END IF;
END Interface_Freight_Charges;

PROCEDURE Prepare_Interface_Line_Rec
(   p_line_rec              IN OE_Order_Pub.Line_Rec_Type
,   p_header_rec            IN OE_Order_Pub.Header_Rec_Type
,   p_x_interface_line_rec  IN OUT NOCOPY RA_Interface_Lines_Rec_Type
,   x_result_code           OUT NOCOPY VARCHAR2
) IS
l_creation_sign                VARCHAR2(30);
l_territory_code               VARCHAR2(30);
l_delivery_line_id             NUMBER;
l_bank_acct_id                 NUMBER;
l_bank_acct_uses_id            NUMBER;
l_pay_method_id                NUMBER;
l_pay_method_name              VARCHAR2(50);
l_merchant_id                  NUMBER;
l_trxn_id                      NUMBER;
l_tangible_id                  VARCHAR2(80);
l_hdr_inv_to_cust_id           NUMBER;
l_gdf_rec                      OE_GDF_Rec_Type;
l_jg_return_code               NUMBER;
l_jg_error_buffer              VARCHAR2(240);
l_rma_date                     DATE;
l_rma_result                   VARCHAR2(1);
l_count1                       NUMBER := 0 ;
l_count2                       NUMBER := 0 ;
l_item_description             VARCHAR2(2000);
l_course_end_date              DATE;
l_ship_method_code             VARCHAR2(30);
l_return_status                VARCHAR2(1);
l_accounting_rule_type         VARCHAR2(10);
l_acct_rule_duration           NUMBER;
l_orig_sys_ship_addr_id        NUMBER;
l_commitment_applied           NUMBER;
l_commitment_interfaced        NUMBER;
l_partial_line_amount          NUMBER := 0;
l_partial_line_tax_amount      NUMBER := 0;
l_partial_line_freight_amount  NUMBER := 0;
l_partial_line_promised_amount NUMBER := 0;
l_fulfilled_qty                NUMBER;
l_set_of_books_rec             OE_Order_Cache.Set_Of_Books_Rec_Type;
l_user_id                      NUMBER;
l_resp_id                      NUMBER;
l_appl_id                      NUMBER;
/*Added for FP bug # 3647389*/
l_cur_user_id                  NUMBER;
l_cur_resp_id                  NUMBER;
l_cur_appl_id                  NUMBER;
l_AR_Sys_Param_Rec             AR_SYSTEM_PARAMETERS_ALL%ROWTYPE;
--serla begin
l_payment_type_code VARCHAR2(30);
l_payment_trx_id NUMBER;
l_receipt_method_id NUMBER;
l_credit_card_holder_name  	VARCHAR2(80);
l_credit_card_approval_code 	VARCHAR2(80);
--serla end
l_trx_date			DATE;
l_max_actual_shipment_date	DATE;
l_fulfillment_set_flag		VARCHAR2(1) := FND_API.G_FALSE;
-- 3757279
l_concat_segment VARCHAR2(240) := NULL;
l_prof_value     VARCHAR2(240) := NULL;
l_table_index  BINARY_INTEGER;
-- 3757279
--Adding for bug#3965665
l_return_code                  VARCHAR2(30);
l_unmapped_date                DATE;
l_frequency                    VARCHAR2(15);
l_calendar_name                VARCHAR2(15);
l_interface_line_rec           RA_Interface_Lines_Rec_Type; --bug 4738942
--bug5603774
l_cust_pay_method_id           NUMBER;
L_ACCOUNTING_RULE_ID 	       NUMBER;
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
l_set_of_books_id NUMBER;
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER PREPARE_INTERFACE_LINE_REC ( ) PROCEDURE ' , 5 ) ;
    END IF;
	l_interface_line_rec.request_id := p_x_interface_line_rec.request_id; --bug 5120077
	p_x_interface_line_rec := l_interface_line_rec; --bug 4738942
    l_delivery_line_id := Null;
    IF Shipping_info_Available(p_line_rec) THEN
       -- Fix for bug 2196494
       IF p_line_rec.item_type_code NOT In ('MODEL','CLASS','KIT') THEN
       BEGIN
    --Bug2181628 TO retrieve the minimum delivery_id of a line,if it is present
    --in more than one delivery.Hence used "MIN"instead of "ROWNUM".Hence split the SQL Query.    
     SELECT min(dl.delivery_id)
         INTO   l_delivery_line_id
         FROM   wsh_new_deliveries dl,
                wsh_delivery_assignments da,
                wsh_delivery_details dd
         WHERE  dd.delivery_detail_id  = da.delivery_detail_id
         AND    da.delivery_id  = dl.delivery_id
         AND    dd.source_code = 'OE'
         AND    dd.source_line_id = p_line_rec.line_id;
--	     AND    rownum = 1;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
	          IF l_debug_level  > 0 THEN
	              oe_debug_pub.add(  'REACHING NO DATA FOUND. DELIVERY DETAILS NOT FOUND FOR THIS LINE..' , 1 ) ;
	          END IF;
              p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3 := '0';
              p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4 := '0';
              p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7 := '0';
       END;
       /*  Populate bill of lading  */
       IF l_delivery_line_id Is Not Null Then
          BEGIN
             SELECT NVL(SUBSTR(dl.name, 1, 30), '0')
                   ,NVL(SUBSTR(dl.waybill, 1, 30), '0')
                   ,dl.ship_method_code
                   ,dl.initial_pickup_date
             INTO  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3
                   ,p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4
                   ,l_ship_method_code
                   ,p_x_interface_line_rec.SHIP_DATE_ACTUAL
             FROM   wsh_new_deliveries dl
             WHERE  dl.delivery_id = l_delivery_line_id;
 
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'POPULATING BILL OF LADING NUMBER ..' , 5 ) ;
             END IF;
             SELECT wdi.sequence_number
             INTO   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8
             FROM   wsh_delivery_legs wdl,
                    wsh_document_instances wdi
             where wdi.entity_name = 'WSH_DELIVERY_LEGS'
             and wdi.entity_id = wdl.delivery_leg_id
             and wdl.delivery_id =l_delivery_line_id
             and wdi.status <> 'CANCELLED'
             and rownum=1;
 IF l_debug_level  > 0 THEN
     oe_debug_pub.add(  'BILL OF LADING NUMBER IS POPULATED AS ..'||P_X_INTERFACE_LINE_REC.INTERFACE_LINE_ATTRIBUTE8 , 5 ) ;
 END IF;
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'NO DETAILS FOR BILL OF LADING NUMBER FOUND ...' , 5 ) ;
                   END IF;
                   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8 := '0';
          END;
        END IF;
--Fix for bug 3661402 
  IF l_ship_method_code IS NOT NULL THEN
     GOTO get_ship_via;
  END IF;
--End of Fix for bug 3661402

-- commented for bug 3661402
/*      BEGIN
           IF l_debug_level  > 0 THEN
 oe_debug_pub.add(  'GETTING SHIP_VIA FROM SHIP_METHOD_CODE: '||L_SHIP_METHOD_CODE|| ' AND ORGANIZATION_ID: '||P_LINE_REC.SHIP_FROM_ORG_ID , 5 ) ;
           END IF;
-- fix bug# 1382196
           IF l_ship_method_code IS NOT NULL THEN
               IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110509' THEN

                  SELECT   substr(freight_code,1,25)
                    INTO   p_x_interface_line_rec.SHIP_VIA
                    FROM   wsh_carriers wsh_ca,wsh_carrier_services wsh,
                           wsh_org_carrier_services wsh_org
                    WHERE  wsh_org.organization_id   = p_line_rec.ship_from_org_id
                      AND  wsh.carrier_service_id    = wsh_org.carrier_service_id
                      AND  wsh_ca.carrier_id         = wsh.carrier_id
                      AND  wsh.ship_method_code      = l_ship_method_code
                      AND  wsh_org.enabled_flag      = 'Y';
               ELSE
                    SELECT  substr(freight_code,1,25)
                      INTO  p_x_interface_line_rec.SHIP_VIA
                      FROM  wsh_carrier_ship_methods
                     WHERE  ship_method_code = l_ship_method_code
                       AND  organization_id = p_line_rec.ship_from_org_id;
               END IF;
           END IF;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
		        p_x_interface_line_rec.SHIP_VIA := NULL;
        END;    */
    ELSE   --non ship line
       If p_line_rec.item_type_code In ('MODEL','CLASS','KIT') Then
          BEGIN
   --Bug2181628 TO retrieve the minimum delivery_id of a line,if it is present
   --in more than one delivery.Hence used "MIN"instead of "ROWNUM".Hence Split the Query.    
   SELECT min(dl.delivery_id)
             INTO   l_delivery_line_id
             FROM wsh_new_deliveries dl,
                  wsh_delivery_assignments da,
                  wsh_delivery_details dd
             WHERE   dd.delivery_detail_id  = da.delivery_detail_id
             AND     da.delivery_id  = dl.delivery_id
             AND     dd.source_code = 'OE'
             AND     dd.top_model_line_id = p_line_rec.line_id;
--	         AND   rownum = 1;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
	              IF l_debug_level  > 0 THEN
	                  oe_debug_pub.add(  'REACHING NO DATA FOUND. DELIVERY DETAILS NOT FOUND FOR THIS LINE..' , 1 ) ;
	              END IF;
                  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3 := '0';
                  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4 := '0';
                  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7 := '0';
          END;
          IF l_delivery_line_id Is Not Null Then
             BEGIN
               SELECT  NVL(SUBSTR(dl.name, 1, 30), '0')
                      ,NVL(SUBSTR(dl.waybill, 1, 30), '0')
                      ,dl.ship_method_code
                      ,dl.initial_pickup_date
               INTO    p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3
                      ,p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4
                      ,l_ship_method_code
                      ,p_x_interface_line_rec.SHIP_DATE_ACTUAL
               FROM   wsh_new_deliveries dl
               WHERE dl.delivery_id = l_delivery_line_id;
   
 
               IF l_debug_level  > 0 THEN
                   oe_debug_pub.add(  'POPULATING BILL OF LADING NUMBER ..' , 5 ) ;
               END IF;
               SELECT substr(wdi.sequence_number,1,30)
               INTO   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8
               FROM   wsh_delivery_legs wdl,
                      wsh_document_instances wdi
               where  wdi.entity_name = 'WSH_DELIVERY_LEGS'
               and    wdi.entity_id = wdl.delivery_leg_id
               and    wdl.delivery_id =l_delivery_line_id
               and    wdi.status <> 'CANCELLED'
               and    rownum=1;
               IF l_debug_level  > 0 THEN
                   oe_debug_pub.add(  'BILL OF LADING NUMBER IS POPULATED AS ..'||P_X_INTERFACE_LINE_REC.INTERFACE_LINE_ATTRIBUTE8 , 5 ) ;
               END IF;
             EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  'NO DETAILS FOR BILL OF LADING NUMBER FOUND ...' , 5 ) ;
                      END IF;
                      p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8 := '0';
             END;

--Fix for bug 3661402
  IF l_ship_method_code IS NOT NULL THEN
     GOTO get_ship_via;
  END IF;
--End of Fix for bug 3661402

--Commented for bug 3661402
/* Added for the bug number 2988432 */

/*        BEGIN
           IF l_debug_level  > 0 THEN
  oe_debug_pub.add(  'GETTING SHIP_VIA FROM SHIP_METHOD_CODE: '||L_SHIP_METHOD_CODE|| ' AND ORGANIZATION_ID: '||P_LINE_REC.SHIP_FROM_ORG_ID , 5 ) ;
           END IF;
           -- fix bug# 1382196
           IF l_ship_method_code IS NOT NULL THEN
               IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110509' THEN

                  SELECT   substr(freight_code,1,25)
                    INTO   p_x_interface_line_rec.SHIP_VIA
                    FROM   wsh_carriers wsh_ca,wsh_carrier_services wsh,
                           wsh_org_carrier_services wsh_org
                    WHERE  wsh_org.organization_id   = p_line_rec.ship_from_org_id
                      AND  wsh.carrier_service_id    = wsh_org.carrier_service_id
                      AND  wsh_ca.carrier_id         = wsh.carrier_id
                      AND  wsh.ship_method_code      = l_ship_method_code
                      AND  wsh_org.enabled_flag      = 'Y';
               ELSE
                    SELECT  substr(freight_code,1,25)
                      INTO  p_x_interface_line_rec.SHIP_VIA
                      FROM  wsh_carrier_ship_methods
                     WHERE  ship_method_code = l_ship_method_code
                       AND  organization_id = p_line_rec.ship_from_org_id;
               END IF;
           END IF;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
                        p_x_interface_line_rec.SHIP_VIA := NULL;
        END; */                                                         
/* Added for the bug number 2988432  */
          
          END IF;
      END IF;
      END IF;
  END IF;

--Fix for bug 3661402
 
 if l_ship_method_code is null then
   if p_line_rec.ship_from_org_id is not null then
      l_ship_method_code := p_line_rec.shipping_method_code;
   end if;
 end if;

 <<get_ship_via>>

       BEGIN
           IF l_debug_level  > 0 THEN
  oe_debug_pub.add(  'GETTING SHIP_VIA FROM SHIP_METHOD_CODE: '||L_SHIP_METHOD_CODE|| ' AND ORGANIZATION_ID: '||P_LINE_REC.SHIP_FROM_ORG_ID ,5 ) ;
           END IF;
           IF l_ship_method_code IS NOT NULL THEN
               IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110509' THEN

                  SELECT   substr(freight_code,1,25)
                    INTO   p_x_interface_line_rec.SHIP_VIA
                    FROM   wsh_carriers wsh_ca,wsh_carrier_services wsh,
                           wsh_org_carrier_services wsh_org
                    WHERE  wsh_org.organization_id   =
p_line_rec.ship_from_org_id
                      AND  wsh.carrier_service_id    =
wsh_org.carrier_service_id
                      AND  wsh_ca.carrier_id         = wsh.carrier_id
                      AND  wsh.ship_method_code      = l_ship_method_code
                      AND  wsh_org.enabled_flag      = 'Y';
               ELSE
                    SELECT  substr(freight_code,1,25)
                      INTO  p_x_interface_line_rec.SHIP_VIA
                      FROM  wsh_carrier_ship_methods
                     WHERE  ship_method_code = l_ship_method_code
                       AND  organization_id = p_line_rec.ship_from_org_id;
               END IF;
           END IF;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
                        p_x_interface_line_rec.SHIP_VIA := NULL;
        END;

--End of fix for bug 3661402

    /* 1847224 */
  IF l_delivery_line_id IS NULL THEN  -- for Returns and non shippable lines
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'NON SHIPPABLE OR RETURN LINE ' , 5 ) ;
       END IF;
       if p_line_rec.line_category_code <> 'RETURN' THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THIS IS A NON-SHIPPABLE LINE..' , 5 ) ;
          END IF;

          -- fixed bug 3435298 
          -- for non-shippable line in a fulfillment set
          l_fulfillment_set_flag 
                       := OE_Line_Fullfill.Is_Part_Of_Fulfillment_Set
                          (p_line_rec.line_id);
          IF l_fulfillment_set_flag = FND_API.G_TRUE THEN
             IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'SETTING TRANSACTION DATE AS THE ACTUAL_SHIPMENT_DATE OF THE LAST SHIPPED ITEM IN THE SET. ' , 5 ) ;
             END IF;

             BEGIN
             SELECT max(actual_shipment_date)
             INTO   l_max_actual_shipment_date
             FROM   oe_order_lines_all 	ool,
                    oe_line_sets	ols
             WHERE  ool.shippable_flag = 'Y'
             AND    ool.line_id = ols.line_id
             AND    ols.set_id IN (SELECT os.set_id
                                  FROM   oe_line_sets ls,
                                         oe_sets os
                                  WHERE  ls.line_id = p_line_rec.line_id
                                  AND    ls.set_id = os.set_id
                                  AND    os.set_type='FULFILLMENT_SET');
             EXCEPTION WHEN NO_DATA_FOUND THEN
               null;
             END;

             --4428930
             IF l_max_actual_shipment_date IS NULL THEN
                IF (fnd_profile.value('OE_RECEIVABLES_DATE_FOR_NONSHIP_LINES') = 'Y') THEN
                   l_max_actual_shipment_date := SYSDATE;
                ELSE
                   --Should we let the date be null?
                   Null;
                END IF;
             END IF;
	     --4428930

             p_x_interface_line_rec.SHIP_DATE_ACTUAL := l_max_actual_shipment_date;
	     
          -- for non-shippable line not in a fulfillment set
          ELSIF (fnd_profile.value('OE_RECEIVABLES_DATE_FOR_NONSHIP_LINES') = 'Y') THEN
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'SETTING TRANSACTION DATE AS CURRENT DATE FOR THIS NONSHIP LINE ' , 5 ) ;
              END IF;
              p_x_interface_line_rec.SHIP_DATE_ACTUAL := SYSDATE;

          END IF;
       end if;
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3 := '0';
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4 := '0';
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7 := '0';
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8 := '0';
  END IF;
  -- for bug# 1468820
  IF p_line_rec.source_type_code = 'EXTERNAL' THEN
     BEGIN
        --following line added for bug 3712551
        IF(p_line_rec.actual_shipment_date is null) THEN 
           SELECT nvl ( max ( transaction_date ) , sysdate )
           INTO   p_x_interface_line_rec.ship_date_actual
           FROM   rcv_transactions   t , oe_drop_ship_sources s
           WHERE  t.po_header_id  =  s.po_header_id
           AND    t.po_line_location_id =  s.line_location_id
           AND    transaction_type = 'RECEIVE'
           AND    s.line_id = p_line_rec.line_id;
        ELSE
          --following line added for bug 3712551
          p_x_interface_line_rec.ship_date_actual := p_line_rec.actual_shipment_date;
       END IF;

     EXCEPTION
         WHEN OTHERS THEN
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'SETTING SHIP_DATE_ACTUAL FOR DROPSHIP LINE TO SYSDATE' , 5 ) ;
              END IF;
              p_x_interface_line_rec.ship_date_actual := sysdate;
     END;
     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'SHIP_DATE_ACTUAL FOR DROPSHIP LINE: '|| TO_CHAR ( P_X_INTERFACE_LINE_REC.SHIP_DATE_ACTUAL , 'DD-MON-YYYY HH24:MI:SS' ) , 5 ) ;
     END IF;
  END IF;

  -- Get information into p_x_interface_line_rec
  p_x_interface_line_rec.CREATED_BY                := NVL(oe_standard_wf.g_user_id, fnd_global.user_id); -- 3169637
  p_x_interface_line_rec.CREATION_DATE             := sysdate;
  p_x_interface_line_rec.LAST_UPDATED_BY           := NVL(oe_standard_wf.g_user_id, fnd_global.user_id); -- 3169637
  p_x_interface_line_rec.LAST_UPDATE_DATE          := sysdate;
  p_x_interface_line_rec.INTERFACE_LINE_CONTEXT    := FND_PROFILE.VALUE('ONT_SOURCE_CODE');
  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE1 := to_char(p_header_rec.order_number);

  SELECT tt.name
  INTO   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE2
  FROM   oe_transaction_types_tl tt,
         oe_order_headers oh
  WHERE  tt.language = ( select language_code
                         from   fnd_languages
                         where  installed_flag = 'B')
  AND    tt.transaction_type_id = oh.order_type_id
  AND    oh.header_id = p_line_rec.header_id;
  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE6 := to_char(p_line_rec.line_id);
  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7 := '0'; -- picking_line_id
  --rt{ Retrobilling change 
  /*IF (p_line_rec.line_category_code = 'RETURN' 
     and p_line_rec.reference_line_id is not null
     and p_line_rec.retrobill_request_id is not null) THEN
    p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE5 := p_line_rec.retrobill_request_id;
  END IF;*/
  --rt} End Retrobilling change


  IF   p_line_rec.invoiced_quantity IS NOT NULL THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'THIS LINE WAS INTERFACED ATLEAST ONCE BEFORE' , 5 ) ;
       END IF;
       SELECT count(*)
       INTO   l_count1
       FROM   ra_interface_lines_all
       WHERE  interface_line_context = 'ORDER ENTRY'
       AND    interface_line_attribute1 = p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE1
       AND    interface_line_attribute2 = p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE2
       AND    interface_line_attribute6= to_char(p_line_rec.line_id)
       AND    interface_line_attribute11 = '0'
       AND    NVL(interface_status, '~') <> 'P';
       SELECT count(*)
       INTO   l_count2
       FROM   ra_customer_trx_lines_all
       WHERE  interface_line_context = 'ORDER ENTRY'
       AND    interface_line_attribute1 = p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE1
       AND    interface_line_attribute2 = p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE2
       AND    interface_line_attribute6= to_char(p_line_rec.line_id)
       AND    interface_line_attribute11 = '0'
       AND    sales_order =  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE1;
   END IF;
   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE5 := l_count1 + l_count2 ; -- no of times this line is interfaced to AR
   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'INTERFACE_LINE_ATTRIBUTE5: '|| P_X_INTERFACE_LINE_REC.INTERFACE_LINE_ATTRIBUTE5 , 5 ) ;
   END IF;

   --rt{ Retrobilling change
     IF (p_line_rec.line_category_code = 'RETURN'
         and p_line_rec.reference_line_id is not null
         and p_line_rec.retrobill_request_id is not null) THEN
             p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE5 := p_line_rec.retrobill_request_id;
    END IF;
  --rt} End Retrobilling change

   IF NVL(p_line_rec.item_identifier_type, 'INT') = 'CUST' THEN
       BEGIN
         SELECT customer_item_number
         INTO  p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE9
         FROM  mtl_customer_items citems
         WHERE customer_item_id = p_line_rec.ordered_item_id;
       EXCEPTION
            WHEN OTHERS THEN
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'EXCEPTION , POPULATING ATTRIBUTE9 AS 0 =>'||SQLERRM , 1 ) ;
            END IF;
            p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE9 := '0';
       END;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'GETTING CUSTOMER ITEM NUMBER: '|| P_X_INTERFACE_LINE_REC.INTERFACE_LINE_ATTRIBUTE9 ) ;
       END IF;
   ELSE
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE9 := '0';
   END IF;
   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE10 := nvl(to_char(p_line_rec.ship_from_org_id), '0');
   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE11 := '0';
   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE12 := lpad(to_char(nvl(p_line_rec.Shipment_Number,0)),30);
   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE13 := lpad(to_char(nvl(p_line_rec.Option_Number,0)),30);
   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE14 := lpad(to_char(nvl(p_line_rec.Service_Number,0)),30);
   p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE15 := NULL;
   p_x_interface_line_rec.SET_OF_BOOKS_ID := oe_sys_parameters.value('SET_OF_BOOKS_ID', p_line_rec.org_id);
   p_x_interface_line_rec.LINE_TYPE := 'LINE';
   p_x_interface_line_rec.WAREHOUSE_ID := p_line_rec.ship_from_org_id;

   /* If the Line is of OTA type, then we need to call an OTA API to get the */
   /* concaternated string for item description */

   IF p_line_rec.order_quantity_uom in ('EVT','ENR') THEN
	  IF l_debug_level  > 0 THEN
	      oe_debug_pub.add(  'GETTING THE OTA DESCRIPTION' , 5 ) ;
	  END IF;

          IF p_line_rec.line_category_code = 'RETURN' and 
             p_line_rec.reference_line_id is not null then

	    IF l_debug_level  > 0 THEN
	        oe_debug_pub.add(  'GETTING THE OTA DESCRIPTION FOR RETURN' , 5 ) ;
	    END IF;

	    OE_OTA_UTIL.Get_OTA_Description
			    (p_line_id         => p_line_rec.reference_line_id
			    ,p_uom             => p_line_rec.order_quantity_uom
                            ,x_description     => l_item_description
			    ,x_course_end_date => l_course_end_date
			    ,x_return_status   => l_return_status
			    );
            p_x_interface_line_rec.DESCRIPTION := l_item_description;
	    IF l_debug_level  > 0 THEN
	        oe_debug_pub.add(  'OTA DESCRIPTION' || L_ITEM_DESCRIPTION , 5 ) ;
	    END IF;
	    p_x_interface_line_rec.GL_DATE     := l_course_end_date;

          ELSE

	    OE_OTA_UTIL.Get_OTA_Description
			    (p_line_id         => p_line_rec.line_id
			    ,p_uom             => p_line_rec.order_quantity_uom
                            ,x_description     => l_item_description
			    ,x_course_end_date => l_course_end_date
			    ,x_return_status   => l_return_status
			    );
            p_x_interface_line_rec.DESCRIPTION := l_item_description;
	    IF l_debug_level  > 0 THEN
	        oe_debug_pub.add(  'OTA DESCRIPTION' || L_ITEM_DESCRIPTION , 5 ) ;
	    END IF;
	    p_x_interface_line_rec.GL_DATE     := l_course_end_date;

          END IF;
    ELSE
       IF p_line_rec.item_type_code = 'SERVICE' THEN
          Get_Service_Item_Description(p_line_rec, p_x_interface_line_rec.DESCRIPTION);
       ELSE
          Get_Item_Description(p_line_rec, p_x_interface_line_rec.DESCRIPTION);
       END IF;

    END IF;

    -- bug 2509121.
    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110509' 
       AND p_line_rec.user_item_description IS NOT NULL 
       AND p_line_rec.user_item_description <> FND_API.G_MISS_CHAR THEN 
         p_x_interface_line_rec.translated_description := p_line_rec.user_item_description; 
    END IF; 

    -- Commenting if condition for bug# 4063914
    --IF p_x_interface_line_rec.CURRENCY_CODE IS NULL THEN
       p_x_interface_line_rec.CURRENCY_CODE := p_header_rec.transactional_curr_code;
    --END IF;
    IF p_line_rec.Commitment_Id IS NOT NULL THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'GETTING CUST_TRX_TYPE_ID FROM COMMITMENT: '||P_LINE_REC.COMMITMENT_ID , 5 ) ;
       END IF;
       SELECT NVL(cust_type.subsequent_trx_type_id,cust_type.cust_trx_type_id)
       INTO p_x_interface_line_rec.Cust_Trx_Type_Id
       FROM ra_cust_trx_types cust_type,ra_customer_trx cust_trx
       WHERE cust_type.cust_trx_type_id = cust_trx.cust_trx_type_id
       AND cust_trx.customer_trx_id = p_line_rec.Commitment_Id;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'CUST_TRX_TYPE_ID FROM COMMITMENT IS '||P_X_INTERFACE_LINE_REC.CUST_TRX_TYPE_ID ) ;
       END IF;
    ELSE
       p_x_interface_line_rec.Cust_Trx_Type_Id := Get_Customer_Transaction_Type(p_line_rec);
    END IF;
/* START PREPAYMENT */
    IF NOT Return_Line(p_line_rec) THEN
       IF OE_PrePayment_Util.Is_Prepaid_Order(p_header_rec) = 'Y' THEN
          p_x_interface_line_rec.Term_Id := p_header_rec.payment_term_id;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'GETTING PAYMENT_SET_ID FROM OE_PAYMENTS' ) ;
          END IF;
          BEGIN
--serla begin
            IF OE_PrePayment_UTIL.IS_MULTIPLE_PAYMENTS_ENABLED THEN
               SELECT payment_set_id
               INTO p_x_interface_line_rec.Payment_Set_ID
               FROM oe_payments
               WHERE header_id = p_line_rec.header_id
               AND   payment_set_id IS NOT NULL
               AND   rownum=1;
            ELSE
--serla end
               SELECT payment_set_id
               INTO p_x_interface_line_rec.Payment_Set_ID
               FROM oe_payments
               WHERE header_id = p_line_rec.header_id
               AND   line_id is null
               AND   payment_type_code = 'CREDIT_CARD';
--serla begin
            END IF;
--serla end
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
               p_x_interface_line_rec.Payment_Set_ID := NULL;
             WHEN TOO_MANY_ROWS THEN
               p_x_interface_line_rec.Payment_Set_ID := NULL;
          END;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'AFTER GETTING PAYMENT_SET_ID: '||P_X_INTERFACE_LINE_REC.PAYMENT_SET_ID ) ;
          END IF;
          p_x_interface_line_rec.approval_code := NULL;
       ELSE
          p_x_interface_line_rec.Term_Id := p_line_rec.payment_term_id;
       END IF;
    END IF;
/* END PREPAYMENT */
    Get_Qty_To_Invoice(p_line_rec, p_x_interface_line_rec.QUANTITY, x_result_code);
    IF OE_Commitment_Pvt.DO_Commitment_Sequencing THEN-- commitment sequencing functionality ON
      IF p_line_rec.commitment_id IS NOT NULL THEN
         Get_Commitment_Info(p_line_rec
                            ,l_commitment_applied
                            ,l_commitment_interfaced);
         IF x_result_code = 'RFR-PENDING' THEN
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'GET PARTIAL PROMISED AMOUNT FOR PARTIALLY INVOICED LINE' , 5 ) ;
            END IF;
            Rounded_Amount(p_currency_code => p_x_interface_line_rec.currency_code
                          ,p_unrounded_amount => (p_line_rec.unit_selling_price * p_x_interface_line_rec.quantity)
                          ,x_rounded_amount => l_partial_line_amount);
            IF OE_COMMITMENT_PVT.Get_Allocate_Tax_Freight(p_line_rec) = 'Y' THEN
               l_fulfilled_qty := NVL(p_line_rec.fulfilled_quantity, NVL(p_line_rec.shipped_quantity, NVL(p_line_rec.ordered_quantity, 0)));
               l_partial_line_tax_amount := nvl(p_line_rec.tax_value * (p_x_interface_line_rec.QUANTITY/l_fulfilled_qty), 0);
               SELECT nvl(sum(charge_amount), 0)
               INTO   l_partial_line_freight_amount
               FROM   oe_charge_lines_v
               WHERE  header_id = p_line_rec.header_id
               AND    line_id = p_line_rec.line_id
               AND    nvl(invoiced_flag, 'N') = 'N';
            END IF;

            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'PARTIAL LINE AMOUNT '||L_PARTIAL_LINE_AMOUNT||' - PARTIAL TAX AMOUNT '||L_PARTIAL_LINE_TAX_AMOUNT||' - PARTIAL LINE FREIGHT AMOUNT '||L_PARTIAL_LINE_FREIGHT_AMOUNT , 5 ) ;
            END IF;
            l_partial_line_promised_amount := l_partial_line_amount + l_partial_line_tax_amount + l_partial_line_freight_amount;
            IF (l_commitment_applied-l_commitment_interfaced) >= l_partial_line_promised_amount THEN
               p_x_interface_line_rec.promised_commitment_amount := l_partial_line_promised_amount;
               IF l_debug_level  > 0 THEN
                   oe_debug_pub.add(  'RFR- PASS FULL AMOUNT FOR THIS INTERFACE: '|| P_X_INTERFACE_LINE_REC.PROMISED_COMMITMENT_AMOUNT , 3 ) ;
               END IF;
            ELSE
               p_x_interface_line_rec.promised_commitment_amount := l_commitment_applied-l_commitment_interfaced;
               IF l_debug_level  > 0 THEN
                   oe_debug_pub.add(  'PASS PARTIAL AMOUNT FOR THIS INTERFACE: ' ||P_X_INTERFACE_LINE_REC.PROMISED_COMMITMENT_AMOUNT , 3 ) ;
               END IF;
            END IF;
         ELSE
            p_x_interface_line_rec.PROMISED_COMMITMENT_AMOUNT := l_commitment_applied-l_commitment_interfaced;
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'NOT RFR- PROMISED_COMMITMENT_AMOUNT: '|| P_X_INTERFACE_LINE_REC.PROMISED_COMMITMENT_AMOUNT ) ;
            END IF;
         END IF;
      END IF;
    END IF; -- end of commitment sequencing functionality ON
    p_x_interface_line_rec.Unit_Standard_Price := p_line_rec.Unit_List_Price;
    IF Show_Detail_Discounts(p_line_rec) THEN
	  -- If we show detail discounts, original line selling and extended amounts should not include discount amount.
       p_x_interface_line_rec.Unit_Selling_Price := p_line_rec.Unit_List_Price;
       Rounded_Amount(p_currency_code => p_x_interface_line_rec.currency_code
                     ,p_unrounded_amount => (p_line_rec.unit_list_price * p_x_interface_line_rec.quantity)
                     ,x_rounded_amount => p_x_interface_line_rec.amount);
    ELSE
       p_x_interface_line_rec.Unit_Selling_Price := p_line_rec.Unit_Selling_Price;
       Rounded_Amount(p_currency_code => p_x_interface_line_rec.currency_code
                     ,p_unrounded_amount => (p_line_rec.unit_selling_price * p_x_interface_line_rec.quantity)
                     ,x_rounded_amount => p_x_interface_line_rec.amount);
    END IF;
    p_x_interface_line_rec.Quantity_Ordered := p_line_rec.Ordered_Quantity;
    -- Get Creation_sign
    l_creation_sign := Get_Credit_Creation_Sign(p_line_rec, p_x_interface_line_rec.cust_trx_type_id);
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  ' CREATION SIGN IS '|| L_CREATION_SIGN , 5 ) ;
    END IF;

    IF l_creation_sign = 'A' THEN
       IF Return_Line(p_line_rec) THEN
	     IF l_debug_level  > 0 THEN
	         oe_debug_pub.add(  'SETTING -VE SIGN FOR RETURN LINE' , 5 ) ;
	     END IF;
          p_x_interface_line_rec.Amount := p_x_interface_line_rec.amount * -1;
          p_x_interface_line_rec.Quantity := p_x_interface_line_rec.Quantity * -1;
          p_x_interface_line_rec.Quantity_Ordered := p_line_rec.Ordered_Quantity * -1;
       END IF;
    ELSIF l_creation_sign = 'P' THEN
       NULL;
    ELSIF l_creation_sign = 'N' THEN
       p_x_interface_line_rec.Amount := p_x_interface_line_rec.amount * -1;
       p_x_interface_line_rec.Quantity := p_x_interface_line_rec.Quantity * -1;
       p_x_interface_line_rec.Quantity_Ordered := p_line_rec.Ordered_Quantity * -1;
    END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'LINE UNIT SELLING PRICE: '||P_X_INTERFACE_LINE_REC.UNIT_SELLING_PRICE , 5 ) ;
        oe_debug_pub.add(  'LINE UNIT STANDARD PRICE: '||P_X_INTERFACE_LINE_REC.UNIT_STANDARD_PRICE , 5 ) ;
        oe_debug_pub.add(  'LINE AMOUNT: '||P_X_INTERFACE_LINE_REC.AMOUNT ) ;
    END IF;

    -- invoice_to_org_id is required at booking
    IF p_line_rec.invoice_to_org_id IS NOT NULL THEN
	  IF l_debug_level  > 0 THEN
	      oe_debug_pub.add(  'GETTING ORIG_SYSTEM_BILL_CUSTOMER_ID , ORIG_SYSTEM_BILL_ADDRESS_ID INFO' , 5 ) ;
	  END IF;
       BEGIN
       /* Commented for bug #3519137 added new select statement */
       /*SELECT bill_to_org.customer_id
               ,bill_to_org.address_id
         INTO   p_x_interface_line_rec.ORIG_SYSTEM_BILL_CUSTOMER_ID
               ,p_x_interface_line_rec.ORIG_SYSTEM_BILL_ADDRESS_ID
         FROM   oe_invoice_to_orgs_v bill_to_org
         WHERE  bill_to_org.organization_id = p_line_rec.invoice_to_org_id;*/

         SELECT acct_site.cust_account_id, site.cust_acct_site_id
         INTO p_x_interface_line_rec.ORIG_SYSTEM_BILL_CUSTOMER_ID
             ,p_x_interface_line_rec.ORIG_SYSTEM_BILL_ADDRESS_ID
         FROM hz_cust_acct_sites_all acct_site, hz_cust_site_uses_all site
         WHERE SITE.SITE_USE_CODE = 'BILL_TO'
         AND SITE.CUST_ACCT_SITE_ID = ACCT_SITE.CUST_ACCT_SITE_ID
         AND SITE.SITE_USE_ID  = p_line_rec.invoice_to_org_id;

       EXCEPTION
           WHEN OTHERS THEN
	            IF l_debug_level  > 0 THEN
	                oe_debug_pub.add(  'EXCEPTION , '||SQLERRM , 1 ) ;
	            END IF;
                p_x_interface_line_rec.ORIG_SYSTEM_BILL_CUSTOMER_ID := NULL;
                p_x_interface_line_rec.ORIG_SYSTEM_BILL_ADDRESS_ID := NULL;
       END;
    END IF;
    -- ship_to_org_id is not required at booking for return lines
    IF p_line_rec.ship_to_org_id IS NOT NULL THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'GETTING ORIG_SYSTEM_SHIP_CUSTOMER_ID , ORIG_SYSTEM_SHIP_ADDRESS_ID INFO' ) ;
       END IF;
       BEGIN
       /* Commented for bug #3519137 added new select statement */
       /*SELECT ship_to_org.customer_id
               ,ship_to_org.address_id
         INTO   p_x_interface_line_rec.ORIG_SYSTEM_SHIP_CUSTOMER_ID
               ,l_orig_sys_ship_addr_id
         FROM   oe_ship_to_orgs_v ship_to_org
         WHERE  ship_to_org.organization_id = p_line_rec.ship_to_org_id;*/

         SELECT acct_site.cust_account_id, site.cust_acct_site_id
         INTO   p_x_interface_line_rec.ORIG_SYSTEM_SHIP_CUSTOMER_ID
               ,l_orig_sys_ship_addr_id
         FROM hz_cust_acct_sites_all acct_site, hz_cust_site_uses_all site
         WHERE SITE.SITE_USE_CODE = 'SHIP_TO'
         AND SITE.CUST_ACCT_SITE_ID = ACCT_SITE.CUST_ACCT_SITE_ID
         AND SITE.SITE_USE_ID = p_line_rec.ship_to_org_id;

       EXCEPTION
           WHEN OTHERS THEN
	            IF l_debug_level  > 0 THEN
	                oe_debug_pub.add(  'EXCEPTION , '||SQLERRM , 1 ) ;
	            END IF;
                p_x_interface_line_rec.ORIG_SYSTEM_SHIP_CUSTOMER_ID := NULL;
                l_orig_sys_ship_addr_id := NULL;
       END;
    END IF;
    p_x_interface_line_rec.orig_system_ship_address_id  := nvl(p_x_interface_line_rec.orig_system_ship_address_id, l_orig_sys_ship_addr_id);
    p_x_interface_line_rec.orig_system_bill_contact_id  := p_line_rec.invoice_to_contact_id;
    p_x_interface_line_rec.orig_system_ship_contact_id  := p_line_rec.ship_to_contact_id;
    p_x_interface_line_rec.orig_system_sold_customer_id := p_line_rec.sold_to_org_id;
    p_x_interface_line_rec.conversion_type              := NVL(p_header_rec.conversion_type_code, 'User');
    p_x_interface_line_rec.conversion_date              := p_header_rec.conversion_rate_date;
    p_x_interface_line_rec.conversion_rate              := p_header_rec.conversion_rate;
    IF p_x_interface_line_rec.conversion_rate IS NULL THEN
       IF p_x_interface_line_rec.conversion_type = 'User' THEN
          p_x_interface_line_rec.conversion_rate := 1;
       END IF;
    END IF;

    OE_DEBUG_PUB.add('calling set of books for org id '||p_line_rec.org_id,1);

    IF p_header_rec.conversion_type_code IS NOT NULL THEN

       l_set_of_books_rec := OE_Order_Cache.Load_Set_Of_Books(p_line_rec.org_id);

       IF l_debug_level  > 0 THEN
          oe_debug_pub.add('SOB CURRENCY: '||L_SET_OF_BOOKS_REC.CURRENCY_CODE||' TRANSACTIONAL CURRENCY: '||P_HEADER_REC.TRANSACTIONAL_CURR_CODE ) ;
       END IF;

       IF p_header_rec.transactional_curr_code = l_set_of_books_rec.currency_code THEN
          p_x_interface_line_rec.conversion_type :=  'User';
          p_x_interface_line_rec.conversion_rate := 1;
       END IF;
    END IF;
 
    p_x_interface_line_rec.Primary_salesrep_Id := NVL(p_line_rec.Salesrep_Id, p_header_rec.Salesrep_Id);
    p_x_interface_line_rec.Sales_Order         := to_char(p_header_rec.Order_Number);
    p_x_interface_line_rec.Sales_Order_Line    := to_char(p_line_rec.Line_Number);
    p_x_interface_line_rec.Sales_Order_Date    := p_header_rec.Ordered_Date;
    p_x_interface_line_rec.Sales_Order_Source  := FND_PROFILE.VALUE('ONT_SOURCE_CODE');
    p_x_interface_line_rec.Agreement_Id        := p_line_rec.Agreement_Id;
    p_x_interface_line_rec.Purchase_Order      := p_line_rec.Cust_PO_Number;
    p_x_interface_line_rec.Inventory_Item_Id   := p_line_rec.Inventory_Item_Id;

    -- Changes for #3144768 begin

   /* BEGIN
         SELECT NUMBER_VALUE     
         INTO   l_user_id
         FROM   WF_ITEM_ATTRIBUTE_VALUES
         WHERE  ITEM_KEY = to_char(p_line_rec.line_id)
         AND    ITEM_TYPE = 'OEOL'
         AND    NAME = 'USER_ID';

         SELECT NUMBER_VALUE     
         INTO   l_resp_id
         FROM   WF_ITEM_ATTRIBUTE_VALUES
         WHERE  ITEM_KEY = to_char(p_line_rec.line_id)
         AND    ITEM_TYPE = 'OEOL'
         AND    NAME = 'RESPONSIBILITY_ID';

         SELECT NUMBER_VALUE     
         INTO   l_appl_id
         FROM   WF_ITEM_ATTRIBUTE_VALUES
         WHERE  ITEM_KEY = to_char(p_line_rec.line_id)
         AND    ITEM_TYPE = 'OEOL'
         AND    NAME = 'APPLICATION_ID';

    EXCEPTION WHEN OTHERS THEN
         l_user_id := NULL;
         l_resp_id := NULL;
         l_appl_id := NULL;
         OE_DEBUG_PUB.add('Unable to find item attributes while searching for Tax Code profile value : '||sqlerrm,1);
         NULL;
    END;
*/
    Get_Createdby_Context(p_line_id => p_line_rec.line_id,
                         x_user_id      => l_user_id,
                         x_resp_id      => l_resp_id,
                         x_resp_appl_id => l_appl_id);
    OE_DEBUG_PUB.add('Tax code value on the Order Line '||p_line_rec.tax_code,5);
    OE_DEBUG_PUB.add('ID => User,Resp,Appl : '||l_user_id||','||l_resp_id||','||l_appl_id,5);
   
    -- 3757279
       l_concat_segment := 'u'||l_user_id||'r'||l_resp_id||'a'||l_appl_id;
       oe_debug_pub.add('l_concat_segment'||l_concat_segment,1); 
       l_table_index := FIND(l_concat_segment);
       IF l_table_index < TABLE_SIZE THEN
           IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'cached FND PROFILE AR_ALLOW_TAX_CODE_OVERRIDE: '||Prf_Tbl(l_table_index).prf_value,1);
           END IF;
            l_prof_value := Prf_Tbl(l_table_index).prf_value;
       ELSE
           put(l_concat_segment,l_user_id,l_resp_id,l_appl_id,l_prof_value);
           IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  ' Uncached first time FND PROFILE AR_ALLOW_TAX_CODE_OVERRIDE: '||l_prof_value,1);
           END IF;
       END IF;
    -- 3757279
 
    IF NVL(l_prof_value,'N') = 'Y' THEN
       p_x_interface_line_rec.Tax_code := p_line_rec.Tax_code;
    END IF;
    OE_DEBUG_PUB.add('Tax Code interfaced to AR is : '||p_line_rec.Tax_Code,1);

    -- Changes for 3144768 End
    IF Return_Line(p_line_rec) THEN
	   IF l_debug_level  > 0 THEN
	       oe_debug_pub.add(  'SETTING INFORMATION FOR RETURN LINE' , 5 ) ;
	   END IF;
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3 := '0';
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE4 := '0';
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE7 := '0';
       p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE8 := '0';
       p_x_interface_line_rec.Reason_Code := p_line_rec.Return_Reason_Code;
--Bug2302812.Commented the procedure "Get_Received_Status" and in turn we get the
--Receipt date from "RCV_TRANSACTIONS".
  /*     OE_LINE_STATUS_PUB.Get_Received_Status(p_line_id => p_line_rec.line_id, x_result=>l_rma_result, x_result_date=>l_rma_date);*/
         --Bug2758528-Added a check for 'RECEIVE' Transaction type.

       -- With the new fix we are populating the actual_shipment_date for RMAs.
       -- But for old RMAs it may be still NULL, hence adding this logic
       -- to avoid the data upgrade impact for open RMA lines.

      IF p_line_rec.actual_shipment_date IS NULL THEN
         SELECT max ( transaction_date )   -- Bug#3343004 
         INTO   l_rma_date 
         FROM   rcv_transactions    
         WHERE  transaction_type IN ('RECEIVE','UNORDERED')
         AND    oe_order_line_id = p_line_rec.line_id;
     
         p_x_interface_line_rec.Ship_Date_Actual := l_rma_date;

      ELSE
         p_x_interface_line_rec.Ship_Date_Actual :=
                                      p_line_rec.actual_shipment_date;
      END IF;

      IF  p_x_interface_line_rec.Ship_Date_Actual is NULL THEN
          IF (fnd_profile.value('OE_RECEIVABLES_DATE_FOR_NONSHIP_LINES') = 'Y')
          THEN
              p_x_interface_line_rec.Ship_Date_Actual := SYSDATE;
          END IF;
      END IF;

       --p_x_interface_line_rec.Ship_Date_Actual := l_rma_date; 
       p_x_interface_line_rec.Fob_Point := NULL;
       p_x_interface_line_rec.Ship_Via := NULL;
       p_x_interface_line_rec.Waybill_Number := NULL;
       p_x_interface_line_rec.Reference_Line_Id := p_line_rec.Credit_Invoice_Line_Id;
       p_x_interface_line_rec.Accounting_Rule_Id := NULL;
       p_x_interface_line_rec.Invoicing_Rule_Id := NULL;
       p_x_interface_line_rec.Term_Id := NULL;
      --bug 6346111, populate credit method only if referenced invoice has accounting rule
       IF p_x_interface_line_rec.Reference_Line_Id is NOT NULL THEN
         select ACCOUNTING_RULE_ID INTO L_ACCOUNTING_RULE_ID from RA_CUSTOMER_TRX_LINES_all 
		where CUSTOMER_TRX_LINE_ID= p_x_interface_line_rec.Reference_Line_Id;
  	 IF L_ACCOUNTING_RULE_ID is NOT NULL THEN
           Get_Credit_Method_Code(p_line_rec
                          ,p_x_interface_line_rec.Credit_Method_For_Acct_Rule
                          ,p_x_interface_line_rec.Credit_Method_For_Installments);
         END IF;
       END IF;
    ELSE
       p_x_interface_line_rec.Reason_Code := NULL;
       p_x_interface_line_rec.Ship_Date_Actual := NVL(p_x_interface_line_rec.Ship_Date_Actual, p_line_rec.actual_shipment_date);
       p_x_interface_line_rec.Fob_Point := p_line_rec.fob_point_code;
       p_x_interface_line_rec.Waybill_Number := p_x_interface_line_rec.Interface_line_Attribute4;
--     p_x_interface_line_rec.Ship_Via := NVL(p_x_interface_line_rec.Ship_Via, p_line_rec.freight_carrier_code);  -- Should it be shipping_method_code???
       IF p_line_rec.Commitment_Id IS NOT NULL THEN
    	  IF l_debug_level  > 0 THEN
    	      oe_debug_pub.add(  'REFERENCE_LINE_ID FROM COMMITMENT ID IS '||P_LINE_REC.COMMITMENT_ID ) ;
    	  END IF;
          SELECT customer_trx_line_id
          INTO   p_x_interface_line_rec.Reference_Line_Id
          FROM   ra_customer_trx_lines_all
          WHERE  customer_trx_id = p_line_rec.Commitment_Id;
         -- p_x_interface_line_rec.Cust_Trx_Type_Id := NULL; --bug 4702837
       END IF;
       IF /*p_line_rec.accounting_rule_id = 1 or*/ p_line_rec.accounting_rule_id is NULL THEN--Commented for Bug 5725539
          p_x_interface_line_rec.accounting_rule_id := NULL;
          p_x_interface_line_rec.invoicing_rule_id := NULL;
       ELSE
          p_x_interface_line_rec.accounting_rule_id := p_line_rec.accounting_rule_id;
          p_x_interface_line_rec.invoicing_rule_id := p_line_rec.invoicing_rule_id;
       END IF;
    END IF;
    -- This may be a temporary fix for bug# 1386715.
    -- need to understand if we need to convert duration into different unit
    -- Right now, it is in units of Months.
    -- But, Autoinvoice uses accounting rule's period.
    IF NOT Return_Line(p_line_rec) AND p_x_interface_line_rec.accounting_rule_id IS NOT NULL THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'GET ACCOUNTING RULE TYPE ' , 5 ) ;
       END IF;
       --Modified for bug#3965665
       SELECT type,frequency
       INTO l_accounting_rule_type, l_frequency
       FROM ra_rules
       WHERE rule_id = p_x_interface_line_rec.accounting_rule_id;
       IF l_accounting_rule_type = 'ACC_DUR' THEN
          -- accounting rule duration is required for regular (non service) lines at booking
          IF OE_CODE_CONTROL.Get_Code_Release_Level >= '110509' THEN
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'INTERFACING ACCOUNTING_RULE_DURATION FOR REGULAR LINES:'|| P_LINE_REC.ACCOUNTING_RULE_DURATION ) ;
             END IF;
             p_x_interface_line_rec.ACCOUNTING_RULE_DURATION := p_line_rec.accounting_rule_duration;
          ELSE
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'BELOW PACK I , DO NOT INTERFACE DURATION' ) ;
             END IF;
             p_x_interface_line_rec.ACCOUNTING_RULE_DURATION := NULL;
          END IF;
          IF p_line_rec.item_type_code = 'SERVICE' THEN
             p_x_interface_line_rec.rule_start_date := p_line_rec.service_start_date; -- 1833680
             IF p_x_interface_line_rec.accounting_rule_duration IS NULL THEN
                IF p_line_rec.service_start_date IS NULL OR p_line_rec.service_end_date IS NULL THEN
                   -- bug# 3965665 post message and complete with status INCOMPLETE
                   FND_MESSAGE.SET_NAME('ONT','OE_INVALID_ACCT_RULE_DURATION');
                   OE_MSG_PUB.ADD;
                   IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'SERVICE START DATE OR SERVICE END DATE IS NULL' , 3 ) ;
                   END IF;
                   p_x_interface_line_rec.ACCOUNTING_RULE_DURATION := -1;
                ELSE
                   BEGIN
--Modified for bug#3965665
/*
                      l_acct_rule_duration :=  ceil(OKS_TIME_MEASURES_PUB.GET_QUANTITY(
                                                                 p_start_date  => p_line_rec.service_start_date
                                                                ,p_end_date    => p_line_rec.service_end_date));
*/

                      SELECT period_set_name 
                      INTO l_calendar_name
                      FROM gl_sets_of_books 
                      WHERE set_of_books_id = p_x_interface_line_rec.SET_OF_BOOKS_ID;

                      GL_CALENDAR_PKG.get_num_periods_in_date_range(
                         calendar_name => l_calendar_name,
                         period_type   => l_frequency,
                         start_date    => p_line_rec.service_start_date,
                         end_date      => p_line_rec.service_end_date,
                         check_missing => TRUE,
                         num_periods   => l_acct_rule_duration,
                         return_code   => l_return_code,
                         unmapped_date => l_unmapped_date);

                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add('l_acct_rule_duration:'||l_acct_rule_duration);
                          oe_debug_pub.add('l_return_code:'||l_return_code);
                          oe_debug_pub.add('l_unmapped_date:'||l_unmapped_date);
                      END IF;
                      IF l_return_code = 'SUCCESS' THEN
                         p_x_interface_line_rec.ACCOUNTING_RULE_DURATION := l_acct_rule_duration;
                      ELSE
                         p_x_interface_line_rec.ACCOUNTING_RULE_DURATION := -1;
                        -- post message
                        FND_MESSAGE.SET_NAME('ONT','ONT_GL_UNMAPPED_DATES');
                        FND_MESSAGE.SET_TOKEN('START_DATE', p_line_rec.service_start_date);
                        FND_MESSAGE.SET_TOKEN('END_DATE', p_line_rec.service_end_date);
                        FND_MESSAGE.SET_TOKEN('CALENDAR_NAME', l_calendar_name);
                        OE_MSG_PUB.ADD;
                         IF l_debug_level  > 0 THEN
                            oe_debug_pub.add('Atleast one or more dates ('||l_unmapped_date||') within the date range that are not associated with any adjustment period.');
                         END IF;
                      END IF;
                   EXCEPTION
                      WHEN OTHERS THEN
                         p_x_interface_line_rec.ACCOUNTING_RULE_DURATION := -1;
                         -- Modified for bug# 3965665
                         FND_MESSAGE.SET_NAME('ONT','ONT_GL_UNMAPPED_DATES');
                         FND_MESSAGE.SET_TOKEN('START_DATE', p_line_rec.service_start_date);
                         FND_MESSAGE.SET_TOKEN('END_DATE', p_line_rec.service_end_date);
                         FND_MESSAGE.SET_TOKEN('CALENDAR_NAME', l_calendar_name);
                         OE_MSG_PUB.ADD;
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'ERROR IN GL_CALENDAR_PKG.Get_Num_Periods_In_Date_Range ; ERROR => '||SQLERRM , 1 ) ;
                         END IF;
                   END;
                END IF; -- end of service service start/end dates
             END IF; -- null accounting_rule_duaration
          END IF; --service line
       ELSE -- fixed accounting rule
        -- Pass rule_start_date for service lines for fixed rules also (as it was before change for variable accounting rules)
          IF p_line_rec.item_type_code = 'SERVICE' THEN
             p_x_interface_line_rec.rule_start_date := p_line_rec.service_start_date; -- 1833680
            --bug6004166
            IF ((l_accounting_rule_type = 'PP_DR_ALL') OR (l_accounting_rule_type = 'PP_DR_PP')) THEN
                p_x_interface_line_rec.rule_end_date := p_line_rec.service_end_date;
             END IF;

          END IF;
       END IF; -- variable/fixed accounting rule
    END IF; 

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'GET ATTRIBUTE VALUES' , 5 ) ;
    END IF;
    p_x_interface_line_rec.Attribute_Category := p_line_rec.Context;
    p_x_interface_line_rec.Attribute1 := substrb(p_line_rec.Attribute1, 1, 150);
    p_x_interface_line_rec.Attribute2 := substrb(p_line_rec.Attribute2, 1, 150);
    p_x_interface_line_rec.Attribute3 := substrb(p_line_rec.Attribute3, 1, 150);
    p_x_interface_line_rec.Attribute4 := substrb(p_line_rec.Attribute4, 1, 150);
    p_x_interface_line_rec.Attribute5 := substrb(p_line_rec.Attribute5, 1, 150);
    p_x_interface_line_rec.Attribute6 := substrb(p_line_rec.Attribute6, 1, 150);
    p_x_interface_line_rec.Attribute7 := substrb(p_line_rec.Attribute7, 1, 150);
    p_x_interface_line_rec.Attribute8 := substrb(p_line_rec.Attribute8, 1, 150);
    p_x_interface_line_rec.Attribute9 := substrb(p_line_rec.Attribute9, 1, 150);
    p_x_interface_line_rec.Attribute10 := substrb(p_line_rec.Attribute10, 1, 150);
    p_x_interface_line_rec.Attribute11 := substrb(p_line_rec.Attribute11, 1, 150);
    p_x_interface_line_rec.Attribute12 := substrb(p_line_rec.Attribute12, 1, 150);
    p_x_interface_line_rec.Attribute13 := substrb(p_line_rec.Attribute13, 1, 150);
    p_x_interface_line_rec.Attribute14 := substrb(p_line_rec.Attribute14, 1, 150);
    p_x_interface_line_rec.Attribute15 := substrb(p_line_rec.Attribute15, 1, 150);

    p_x_interface_line_rec.Header_Attribute_Category := p_header_rec.Context;
    p_x_interface_line_rec.Header_Attribute1 := substrb(p_header_rec.Attribute1, 1, 150);
    p_x_interface_line_rec.Header_Attribute2 := substrb(p_header_rec.Attribute2, 1, 150);
    p_x_interface_line_rec.Header_Attribute3 := substrb(p_header_rec.Attribute3, 1, 150);
    p_x_interface_line_rec.Header_Attribute4 := substrb(p_header_rec.Attribute4, 1, 150);
    p_x_interface_line_rec.Header_Attribute5 := substrb(p_header_rec.Attribute5, 1, 150);
    p_x_interface_line_rec.Header_Attribute6 := substrb(p_header_rec.Attribute6, 1, 150);
    p_x_interface_line_rec.Header_Attribute7 := substrb(p_header_rec.Attribute7, 1, 150);
    p_x_interface_line_rec.Header_Attribute8 := substrb(p_header_rec.Attribute8, 1, 150);
    p_x_interface_line_rec.Header_Attribute9 := substrb(p_header_rec.Attribute9, 1, 150);
    p_x_interface_line_rec.Header_Attribute10 := substrb(p_header_rec.Attribute10, 1, 150);
    p_x_interface_line_rec.Header_Attribute11 := substrb(p_header_rec.Attribute11, 1, 150);
    p_x_interface_line_rec.Header_Attribute12 := substrb(p_header_rec.Attribute12, 1, 150);
    p_x_interface_line_rec.Header_Attribute13 := substrb(p_header_rec.Attribute13, 1, 150);
    p_x_interface_line_rec.Header_Attribute14 := substrb(p_header_rec.Attribute14, 1, 150);
    p_x_interface_line_rec.Header_Attribute15 := substrb(p_header_rec.Attribute15, 1, 150);

    p_x_interface_line_rec.UOM_Code := p_line_rec.Order_Quantity_UOM;
    p_x_interface_line_rec.Tax_Exempt_Flag := nvl(p_line_rec.Tax_Exempt_Flag, 'S');
    p_x_interface_line_rec.Tax_Exempt_Number := p_line_rec.Tax_Exempt_Number;
    p_x_interface_line_rec.Tax_Exempt_Reason_Code := p_line_rec.Tax_Exempt_Reason_Code;
    p_x_interface_line_rec.Org_id := p_line_rec.Org_id;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'GET DEFAULT TERRITORY' , 5 ) ;
    END IF;

    IF oe_code_control.code_release_level < '110510' THEN
       SELECT asp.default_territory
       INTO   l_territory_code
       FROM   ar_system_parameters asp
       WHERE  nvl(asp.org_id, -3114) = nvl(p_line_rec.org_id, -3114);
    ELSE
       l_AR_Sys_Param_Rec := OE_Sys_Parameters_Pvt.Get_AR_Sys_Params(p_line_rec.org_id);
       l_territory_code   := l_AR_Sys_Param_Rec.default_territory;
    END IF;

    -- Get territory information into p_x_interface_line_rec
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'PREPARE TERRITORY INFORMATION. l_territory_code: ' ||l_territory_code, 5 ) ;
    END IF;
    OE_DEBUG_PUB.DUMPDEBUG;

    p_x_interface_line_rec.territory_id := 0;

    IF    (l_territory_code = 'SALES') THEN
          SELECT max(nvl(rst.territory_id, 0))
          INTO   p_x_interface_line_rec.territory_id
          FROM   ra_salesrep_territories rst
          WHERE  rst.salesrep_id = nvl(p_line_rec.salesrep_id, p_header_rec.salesrep_id)
          AND  sysdate between nvl(start_date_active, sysdate)
          AND  nvl(end_date_active, sysdate);
    ELSIF (l_territory_code = 'BILL' AND p_line_rec.invoice_to_org_id IS NOT NULL) THEN
          SELECT nvl(sub.territory_id,0)
          INTO  p_x_interface_line_rec.territory_id
          FROM hz_cust_site_uses sub
          WHERE sub.site_use_id = p_line_rec.invoice_to_org_id;
    ELSIF (l_territory_code = 'SHIP' AND p_line_rec.ship_to_org_id IS NOT NULL) THEN
          SELECT nvl(sus.territory_id,0)
          INTO  p_x_interface_line_rec.territory_id
          FROM hz_cust_site_uses sus
          WHERE sus.site_use_id = p_line_rec.ship_to_org_id;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'territory_id:'|| p_x_interface_line_rec.territory_id , 5 ) ;
    END IF;
    IF (p_x_interface_line_rec.territory_id > 0) THEN
          SELECT     terr.segment1
                    ,terr.segment2
                    ,terr.segment3
                    ,terr.segment4
                    ,terr.segment5
                    ,terr.segment6
                    ,terr.segment7
                    ,terr.segment8
                    ,terr.segment9
                    ,terr.segment10
                    ,terr.segment11
                    ,terr.segment12
                    ,terr.segment13
                    ,terr.segment14
                    ,terr.segment15
                    ,terr.segment16
                    ,terr.segment17
                    ,terr.segment18
                    ,terr.segment19
                    ,terr.segment20
          INTO       p_x_interface_line_rec.TERRITORY_SEGMENT1
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT2
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT3
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT4
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT5
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT6
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT7
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT8
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT9
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT10
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT11
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT12
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT13
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT14
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT15
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT16
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT17
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT18
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT19
                    ,p_x_interface_line_rec.TERRITORY_SEGMENT20
           FROM     ra_territories terr
           WHERE    terr.territory_id = p_x_interface_line_rec.territory_id;
    END IF;
    IF p_x_interface_line_rec.territory_id = 0 THEN
       p_x_interface_line_rec.territory_id := NULL;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'FINISH TERRITORY' , 5 ) ;
    END IF;
    p_x_interface_line_rec.Batch_Source_Name := Get_Invoice_source(p_line_rec, p_x_interface_line_rec);
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'BATCH SOURCE NAME : '||P_X_INTERFACE_LINE_REC.BATCH_SOURCE_NAME ) ;
    END IF;
    IF p_x_interface_line_rec.INTERFACE_LINE_ATTRIBUTE3 = '0' THEN
       IF p_x_interface_line_rec.REQUEST_ID IS NOT NULL THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'SET REQUEST_ID TO NULL FOR NON DELIVERY LINES' , 5 ) ;
          END IF;
          p_x_interface_line_rec.REQUEST_ID := NULL;
       END IF;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'START CREDIT CARD PROCESSING' , 5 ) ;
    END IF;
--serla begin
    IF NOT OE_PREPAYMENT_UTIL.IS_MULTIPLE_PAYMENTS_ENABLED THEN
--serla end
       -- Check if the Line has an associated Credit Card Payment
       IF p_header_rec.credit_card_number is NOT NULL AND
          NOT Return_Line(p_line_rec) THEN   /* Bug #3463843 */
         IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'CREDIT CARD INFO EXISTS' , 5 ) ;
         -- Fix for Bug # 1586750.
         -- Get the Customer Id for Invoice To Org at the Header Level.
            oe_debug_pub.add(  'GET CUSTOMER ID FOR INVOICE TO ORG AT HEADER' , 5 ) ;
         END IF;

         BEGIN
         /* Commented for bug #3519137 added new select statement */
         /* SELECT customer_id
           INTO   l_hdr_inv_to_cust_id
           FROM   oe_invoice_to_orgs_v
           WHERE  organization_id = p_header_rec.invoice_to_org_id;*/

           SELECT acct_site.cust_account_id
           INTO   l_hdr_inv_to_cust_id
           FROM hz_cust_acct_sites_all acct_site, hz_cust_site_uses_all site
           WHERE SITE.SITE_USE_CODE = 'BILL_TO'
           AND SITE.CUST_ACCT_SITE_ID = ACCT_SITE.CUST_ACCT_SITE_ID
           AND SITE.SITE_USE_ID  = p_header_rec.invoice_to_org_id;

           EXCEPTION
               WHEN OTHERS THEN
                    IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'INVOICE TO CUSTOMER ID : '||L_HDR_INV_TO_CUST_ID , 1 ) ;
                        oe_debug_pub.add(  'ORGANIZATION ID : '||P_HEADER_REC.INVOICE_TO_ORG_ID , 1 ) ;
                        oe_debug_pub.add(  'IN OTHERS EXCEPTION ( OE_INVOICE_TO_ORGS_V ) '||SQLERRM , 1 ) ;
                    END IF;
         END;
         -- Calling Process Customer Bank Account
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'BEFORE CALLING AR PACKAGE PROCESS_CUST_BANK_ACCOUNT ( ) ' , 5 ) ;
         END IF;
         --
         l_trx_date := nvl(p_header_rec.ordered_date, sysdate)
                    - nvl( to_number(fnd_profile.value('ONT_DAYS_TO_BACKDATE_BANK_ACCT')), 0);
   	  BEGIN
               /*
               ** Fix Bug # 2438201
               ** p_trx_date to be passed as order creation date so that autoinvoice succceds
               */
	       arp_bank_pkg.process_cust_bank_account
		( p_trx_date             => l_trx_date
		, p_currency_code        => p_header_rec.transactional_curr_code
		, p_cust_id              => l_hdr_inv_to_cust_id
		, p_site_use_id          => p_header_rec.invoice_to_org_id
		, p_credit_card_num      => p_header_rec.credit_card_number
		, p_acct_name            => p_header_rec.credit_card_holder_name
		, p_exp_date             => p_header_rec.credit_card_expiration_date
		, p_bank_account_id      => l_bank_acct_id
		, p_bank_account_uses_id => l_bank_acct_uses_id
		) ;
           EXCEPTION
   	        WHEN OTHERS THEN
                    l_bank_acct_id := -1;
                    p_x_interface_line_rec.customer_bank_account_id := -1;
                    IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'AR PACKAGE ARP_BANK_PKG.PROCESS_CUST_BANK_ACCOUNT ( ) RETURNED ERROR : '||SQLERRM , 1 ) ;
                    END IF;
         END;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'AFTER CALLING PROCESS_CUST_BANK_ACCOUNT ( ) PROCEDURE ' , 5 ) ;
         END IF;
         -- Check if a Valid Bank Account Id returned
   	  IF NVL(l_bank_acct_id, 0) > 0 THEN
            -- Setup the Bank Account Information
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'BANK ACCOUNT ID : '||L_BANK_ACCT_ID ) ;
            END IF;
	        p_x_interface_line_rec.customer_bank_account_id := l_bank_acct_id;
	        p_x_interface_line_rec.customer_bank_account_name
							  := p_header_rec.credit_card_holder_name;
            /* Fix FP Bug # 3647389: Get the Current Context Values */
            l_cur_user_id := fnd_global.user_id;
            fnd_profile.get('RESP_ID',l_cur_resp_id);
            fnd_profile.get('RESP_APPL_ID',l_cur_appl_id);

            /* Fix FP Bug # 3647389: Set the Context using Original Values */
            fnd_global.apps_initialize(l_user_id, l_resp_id, l_appl_id);
           
             -- Call Get Primary Pay Method to get the method id
             IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'GETTING PRIMAY PAYMENT METHOD' , 5 ) ;
            END IF;
 
            l_pay_method_id := OE_Verify_Payment_PUB.Get_Primary_Pay_Method
                             ( p_header_rec      => p_header_rec ) ;
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'AFTER GETTING PRIMARY PAYMENT METHOD' , 5 ) ;
            END IF;
    
            /* Fix FP Bug # 3647389: Reset the Context using Current Values */
            fnd_global.apps_initialize(l_cur_user_id, l_cur_resp_id, l_cur_appl_id);

      	     -- Check if a Valid Pay Method Id returned
            IF NVL(l_pay_method_id, 0) > 0 THEN
               IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'PAYMENT METHOD IS VALID' ) ;
               -- Call Get Pay Method Info to get the method name
                  oe_debug_pub.add(  'GET PAYMENT METHOD INFORMATION ' , 5 ) ;
               END IF;
               OE_Verify_Payment_PUB.Get_Pay_Method_Info
               ( p_pay_method_id   => l_pay_method_id
               , p_pay_method_name => l_pay_method_name
               , p_merchant_id     => l_merchant_id
               ) ;
               IF l_debug_level  > 0 THEN
                   oe_debug_pub.add(  'AFTER GETTING PAYMENT METHOD INFORMATION' , 5 ) ;
          	    -- Setup the Payment Method Information
                   oe_debug_pub.add(  'PAYMENT METHOD ID IS : '||L_PAY_METHOD_ID , 5 ) ;
               END IF;
	        p_x_interface_line_rec.receipt_method_id := l_pay_method_id;
	        p_x_interface_line_rec.receipt_method_name := l_pay_method_name;
               -- Check if Credit Card Approval Code exists
	        IF p_header_rec.credit_card_approval_code is NOT NULL THEN
                  IF l_debug_level  > 0 THEN
                     oe_debug_pub.add(  'CREDIT CARD APPROVAL CODE EXISTS' , 5 ) ;
     	          -- Call Fetch Current Auth to get the tangible id
                     oe_debug_pub.add(  'FETCH CURRENT AUTHORIZATION CODE , IF ANY' , 5 ) ;
                  END IF;
                  OE_Verify_Payment_PUB.Fetch_Current_Auth
                  ( p_header_rec  => p_header_rec
                   , p_trxn_id     => l_trxn_id
		    , p_tangible_id => l_tangible_id
                  ) ;
                  IF l_debug_level  > 0 THEN
                      oe_debug_pub.add(  ' AFTER CALLING FETCH_CURRENT_AUTH' ) ;
        	      -- Setup the CC Approval Info
                      oe_debug_pub.add(  'TANGIBLE ID IS : '||L_TANGIBLE_ID , 5 ) ;
                  END IF;
   	           p_x_interface_line_rec.approval_code := p_header_rec.credit_card_approval_code;
    	          p_x_interface_line_rec.payment_server_order_num := l_tangible_id;
               END IF; -- IF Approval Code Exists
            END IF; -- IF Pay Method ID is VALID
         END IF; -- IF Bank Account ID is VALID
       END IF; -- IF Credit Card Payment Exists
--serla begin
    ELSE  -- multiple payments enabled
       IF l_debug_level  > 0 THEN
          oe_debug_pub.add('multiple payment enabled. getting payments data from line payments');
       END IF;
       BEGIN
          SELECT payment_type_code
               , payment_trx_id
               , receipt_method_id
               , tangible_id
               , credit_card_holder_name
               , credit_card_approval_code
          INTO   l_payment_type_code
               , l_payment_trx_id
               , l_receipt_method_id
               , l_tangible_id
               , l_credit_card_holder_name
               , l_credit_card_approval_code
          FROM   oe_payments
          WHERE  line_id = p_line_rec.line_id
          AND    payment_type_code <> 'COMMITMENT'
          AND    payment_collection_event = 'INVOICE';
          IF l_debug_level  > 0 THEN
             oe_debug_pub.add('l_payment_type_code:'||l_payment_type_code||'l_payment_trx_id:'||l_payment_trx_id||':l_receipt_method_id:'||l_receipt_method_id);
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
           IF l_debug_level  > 0 THEN
              oe_debug_pub.add('No invoice payments at line level');
           END IF;
           l_payment_type_code := NULL;
           l_payment_trx_id := NULL;
           l_receipt_method_id := NULL;
           l_tangible_id := NULL;
           l_credit_card_holder_name := NULL;
           l_credit_card_approval_code := NULL;
       END;

       IF l_payment_type_code IS NULL THEN
          oe_debug_pub.add('Getting payments data from header payments');
          BEGIN
             SELECT payment_type_code
                  , payment_trx_id
                  , receipt_method_id
                  , tangible_id
                  , credit_card_holder_name
                  , credit_card_approval_code
             INTO   l_payment_type_code
                  , l_payment_trx_id
                  , l_receipt_method_id
                  , l_tangible_id
                  , l_credit_card_holder_name
                  , l_credit_card_approval_code
             FROM   oe_payments
             WHERE  header_id = p_line_rec.header_id
             AND    line_id is NULL
             AND    payment_collection_event = 'INVOICE';
             IF l_debug_level  > 0 THEN
                oe_debug_pub.add('l_payment_type_code:'||l_payment_type_code||'l_payment_trx_id:'||l_payment_trx_id||':l_receipt_method_id:'||l_receipt_method_id);
             END IF;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
              l_payment_type_code := NULL;
              l_payment_trx_id := NULL;
              l_receipt_method_id := NULL;
              l_tangible_id := NULL;
              l_credit_card_holder_name := NULL;
              l_credit_card_approval_code := NULL;
          END;
       END IF;

       IF l_payment_type_code = 'CREDIT_CARD' OR
          l_payment_type_code = 'ACH' OR
          l_payment_type_code = 'DIRECT_DEBIT' OR /* Bug #3510892 */
          l_payment_type_code = 'CASH' OR 
          l_payment_type_code = 'CHECK' THEN  /* Bug #3742304 */
             p_x_interface_line_rec.receipt_method_id := l_receipt_method_id;
             p_x_interface_line_rec.customer_bank_account_id := l_payment_trx_id;
             p_x_interface_line_rec.customer_bank_account_name := l_credit_card_holder_name;
             IF  l_receipt_method_id IS NOT NULL THEN
               BEGIN
                 SELECT NAME
                 INTO p_x_interface_line_rec.receipt_method_name
                 FROM  AR_RECEIPT_METHODS
                 WHERE RECEIPT_METHOD_ID = l_receipt_method_id;
                 /* AND   SYSDATE >= NVL(START_DATE, SYSDATE)
                   AND   SYSDATE <= NVL(END_DATE, SYSDATE); */
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   p_x_interface_line_rec.receipt_method_name := NULL;
                 WHEN OTHERS THEN
                   p_x_interface_line_rec.receipt_method_name := NULL;
               END;
             END IF;

	     --bug5603774
             --Creating a receipt method assignment at the site level if it does not exist so that Autoinvoice goes through
             IF l_receipt_method_id IS NOT NULL THEN
		IF l_debug_level > 0 THEN
		   oe_debug_pub.add('Before creating receipt method assignment at site level if it does not exist');
		END IF;
		l_trx_date := nvl(p_header_rec.ordered_date, sysdate)
                    - nvl( to_number(fnd_profile.value('ONT_DAYS_TO_BACKDATE_BANK_ACCT')), 0);		
		l_cust_pay_method_id := arp_bank_pkg.process_cust_pay_method
                                               ( p_pay_method_id => l_receipt_method_id
                                               , p_customer_id   => p_header_rec.sold_to_org_id
                                               , p_site_use_id   => p_header_rec.invoice_to_org_id
                                               , p_as_of_date    => l_trx_date 
				                           );
		IF l_debug_level > 0 THEN
		   oe_debug_pub.add('l_cust_pay_method_id returned for Receipt Method  ' || p_x_interface_line_rec.receipt_method_name|| 'is ' ||l_cust_pay_method_id);
		END IF;
		                     
             END IF;
	     
             IF l_credit_card_approval_code IS NOT NULL THEN
                p_x_interface_line_rec.approval_code := l_credit_card_approval_code;
		--bug3589581 getting the tangible_id from oe_verify_payment_pub.fetch_current_auth if it is null
		IF l_tangible_id IS NULL THEN
		  
		   OE_Verify_Payment_PUB.Fetch_Current_Auth
                  ( p_header_rec  => p_header_rec
                   , p_trxn_id     => l_trxn_id
		    , p_tangible_id => l_tangible_id
                  ) ;

		  IF l_debug_level  > 0 THEN
		      oe_debug_pub.add(  ' AFTER CALLING FETCH_CURRENT_AUTH' ) ;
        	      -- Setup the CC Approval Info
                      oe_debug_pub.add(  'TANGIBLE ID IS : '||L_TANGIBLE_ID , 5 ) ;
                  END IF;
		  
		END IF;
		 p_x_interface_line_rec.payment_server_order_num := l_tangible_id;
             END IF;
             oe_debug_pub.add('l_receipt_method_id:'||l_receipt_method_id||'Name:'||p_x_interface_line_rec.receipt_method_name);
       END IF;
    END IF;

--serla end

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'FINISH CREDIT CARD PROCESSING' , 5 ) ;
        oe_debug_pub.add(  'START GLOBALIZATION' , 5 ) ;
    END IF;
    l_gdf_rec.interface_line_attribute3 := p_x_interface_line_rec.interface_line_attribute3;
    l_gdf_rec.interface_line_attribute6 := p_x_interface_line_rec.interface_line_attribute6;
    l_gdf_rec.line_type := p_x_interface_line_rec.line_type;
    l_gdf_rec.inventory_item_id := p_line_rec.inventory_item_id;
    l_gdf_rec.line_gdf_attr_category := p_line_rec.global_attribute_category;
    l_gdf_rec.line_gdf_attribute1 := substrb(p_line_rec.global_attribute1, 1, 150);
    l_gdf_rec.line_gdf_attribute2 := substrb(p_line_rec.global_attribute2, 1, 150);
    l_gdf_rec.line_gdf_attribute3 := substrb(p_line_rec.global_attribute3, 1, 150);
    l_gdf_rec.line_gdf_attribute4 := substrb(p_line_rec.global_attribute4, 1, 150);
    l_gdf_rec.line_gdf_attribute5 := substrb(p_line_rec.global_attribute5, 1, 150);
    l_gdf_rec.line_gdf_attribute6 := substrb(p_line_rec.global_attribute6, 1, 150);
    l_gdf_rec.line_gdf_attribute7 := substrb(p_line_rec.global_attribute7, 1, 150);
    l_gdf_rec.line_gdf_attribute8 := substrb(p_line_rec.global_attribute8, 1, 150);
    l_gdf_rec.line_gdf_attribute9 := substrb(p_line_rec.global_attribute9, 1, 150);
    l_gdf_rec.line_gdf_attribute10 := substrb(p_line_rec.global_attribute10, 1, 150);
    l_gdf_rec.line_gdf_attribute11 := substrb(p_line_rec.global_attribute11, 1, 150);
    l_gdf_rec.line_gdf_attribute12 := substrb(p_line_rec.global_attribute12, 1, 150);
    l_gdf_rec.line_gdf_attribute13 := substrb(p_line_rec.global_attribute13, 1, 150);
    l_gdf_rec.line_gdf_attribute14 := substrb(p_line_rec.global_attribute14, 1, 150);
    l_gdf_rec.line_gdf_attribute15 := substrb(p_line_rec.global_attribute15, 1, 150);
    l_gdf_rec.line_gdf_attribute16 := substrb(p_line_rec.global_attribute16, 1, 150);
    l_gdf_rec.line_gdf_attribute17 := substrb(p_line_rec.global_attribute17, 1, 150);
    l_gdf_rec.line_gdf_attribute18 := substrb(p_line_rec.global_attribute18, 1, 150);
    l_gdf_rec.line_gdf_attribute19 := substrb(p_line_rec.global_attribute19, 1, 150);
    l_gdf_rec.line_gdf_attribute20 := substrb(p_line_rec.global_attribute20, 1, 150);
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'CALLING THE GLOBALIZATION PACKAGE' , 5 ) ;
    END IF;
    JG_ZZ_OM_COMMON_PKG.copy_gdff(p_interface_line_rec => l_gdf_rec,
                           x_interface_line_rec => l_gdf_rec,
                           x_return_code => l_jg_return_code,
                           x_error_buffer => l_jg_error_buffer);
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'AFTER CALLING GLOBALIZATION PACKAGE' , 5 ) ;
    END IF;
    p_x_interface_line_rec.line_gdf_attr_category := l_gdf_rec.line_gdf_attr_category;
    p_x_interface_line_rec.line_gdf_attribute1  := l_gdf_rec.line_gdf_attribute1;
    p_x_interface_line_rec.line_gdf_attribute2  := l_gdf_rec.line_gdf_attribute2;
    p_x_interface_line_rec.line_gdf_attribute3  := l_gdf_rec.line_gdf_attribute3;
    p_x_interface_line_rec.line_gdf_attribute4  := l_gdf_rec.line_gdf_attribute4;
    p_x_interface_line_rec.line_gdf_attribute5  := l_gdf_rec.line_gdf_attribute5;
    p_x_interface_line_rec.line_gdf_attribute6  := l_gdf_rec.line_gdf_attribute6;
    p_x_interface_line_rec.line_gdf_attribute7  := l_gdf_rec.line_gdf_attribute7;
    p_x_interface_line_rec.line_gdf_attribute8  := l_gdf_rec.line_gdf_attribute8;
    p_x_interface_line_rec.line_gdf_attribute9  := l_gdf_rec.line_gdf_attribute9;
    p_x_interface_line_rec.line_gdf_attribute10 := l_gdf_rec.line_gdf_attribute10;
    p_x_interface_line_rec.line_gdf_attribute11 := l_gdf_rec.line_gdf_attribute11;
    p_x_interface_line_rec.line_gdf_attribute12 := l_gdf_rec.line_gdf_attribute12;
    p_x_interface_line_rec.line_gdf_attribute13 := l_gdf_rec.line_gdf_attribute13;
    p_x_interface_line_rec.line_gdf_attribute14 := l_gdf_rec.line_gdf_attribute14;
    p_x_interface_line_rec.line_gdf_attribute15 := l_gdf_rec.line_gdf_attribute15;
    p_x_interface_line_rec.line_gdf_attribute16 := l_gdf_rec.line_gdf_attribute16;
    p_x_interface_line_rec.line_gdf_attribute17 := l_gdf_rec.line_gdf_attribute17;
    p_x_interface_line_rec.line_gdf_attribute18 := l_gdf_rec.line_gdf_attribute18;
    p_x_interface_line_rec.line_gdf_attribute19 := l_gdf_rec.line_gdf_attribute19;
    p_x_interface_line_rec.line_gdf_attribute20 := l_gdf_rec.line_gdf_attribute20;
    p_x_interface_line_rec.header_gdf_attr_category := l_gdf_rec.header_gdf_attr_category;
    p_x_interface_line_rec.header_gdf_attribute1  := l_gdf_rec.header_gdf_attribute1;
    p_x_interface_line_rec.header_gdf_attribute2  := l_gdf_rec.header_gdf_attribute2;
    p_x_interface_line_rec.header_gdf_attribute3  := l_gdf_rec.header_gdf_attribute3;
    p_x_interface_line_rec.header_gdf_attribute4  := l_gdf_rec.header_gdf_attribute4;
    p_x_interface_line_rec.header_gdf_attribute5  := l_gdf_rec.header_gdf_attribute5;
    p_x_interface_line_rec.header_gdf_attribute6  := l_gdf_rec.header_gdf_attribute6;
    p_x_interface_line_rec.header_gdf_attribute7  := l_gdf_rec.header_gdf_attribute7;
    p_x_interface_line_rec.header_gdf_attribute8  := l_gdf_rec.header_gdf_attribute8;
    p_x_interface_line_rec.header_gdf_attribute9  := l_gdf_rec.header_gdf_attribute9;
    p_x_interface_line_rec.header_gdf_attribute10 := l_gdf_rec.header_gdf_attribute10;
    p_x_interface_line_rec.header_gdf_attribute11 := l_gdf_rec.header_gdf_attribute11;
    p_x_interface_line_rec.header_gdf_attribute12 := l_gdf_rec.header_gdf_attribute12;
    p_x_interface_line_rec.header_gdf_attribute13 := l_gdf_rec.header_gdf_attribute13;
    p_x_interface_line_rec.header_gdf_attribute14 := l_gdf_rec.header_gdf_attribute14;
    p_x_interface_line_rec.header_gdf_attribute15 := l_gdf_rec.header_gdf_attribute15;
    p_x_interface_line_rec.header_gdf_attribute16 := l_gdf_rec.header_gdf_attribute16;
    p_x_interface_line_rec.header_gdf_attribute17 := l_gdf_rec.header_gdf_attribute17;
    p_x_interface_line_rec.header_gdf_attribute18 := l_gdf_rec.header_gdf_attribute18;
    p_x_interface_line_rec.header_gdf_attribute19 := l_gdf_rec.header_gdf_attribute19;
    p_x_interface_line_rec.header_gdf_attribute20 := l_gdf_rec.header_gdf_attribute20;
    p_x_interface_line_rec.header_gdf_attribute21 := l_gdf_rec.header_gdf_attribute21;
    p_x_interface_line_rec.header_gdf_attribute22 := l_gdf_rec.header_gdf_attribute22;
    p_x_interface_line_rec.header_gdf_attribute23 := l_gdf_rec.header_gdf_attribute23;
    p_x_interface_line_rec.header_gdf_attribute24 := l_gdf_rec.header_gdf_attribute24;
    p_x_interface_line_rec.header_gdf_attribute25 := l_gdf_rec.header_gdf_attribute25;
    p_x_interface_line_rec.header_gdf_attribute26 := l_gdf_rec.header_gdf_attribute26;
    p_x_interface_line_rec.header_gdf_attribute27 := l_gdf_rec.header_gdf_attribute27;
    p_x_interface_line_rec.header_gdf_attribute28 := l_gdf_rec.header_gdf_attribute28;
    p_x_interface_line_rec.header_gdf_attribute29 := l_gdf_rec.header_gdf_attribute29;
    p_x_interface_line_rec.header_gdf_attribute30 := l_gdf_rec.header_gdf_attribute30;

    IF l_debug_level  > 0 THEN
       oe_debug_pub.add('Before calling Legal Entity Time Zone ');
       oe_debug_pub.add('Value of ship_date_actual '||p_x_interface_line_rec.ship_date_actual||
                          ' Value of creation_date '|| p_x_interface_line_rec.creation_date);
       oe_debug_pub.add('Value of last_update_date '||p_x_interface_line_rec.last_update_date||
                         ' Value of sales_order_date '||p_x_interface_line_rec.sales_order_date);
    END IF;

    IF oe_code_control.code_release_level >= '110510' THEN
     IF p_line_rec.org_id IS NOT NULL THEN
       IF p_x_interface_line_rec.ship_date_actual IS NOT NULL THEN
          p_x_interface_line_rec.ship_date_actual := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(p_x_interface_line_rec.ship_date_actual,p_line_rec.org_id);
       END IF;
       IF p_x_interface_line_rec.creation_date IS NOT NULL THEN
          p_x_interface_line_rec.creation_date    := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(p_x_interface_line_rec.creation_date,p_line_rec.org_id);
       END IF;
       IF p_x_interface_line_rec.last_update_date IS NOT NULL THEN
          p_x_interface_line_rec.last_update_date := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(p_x_interface_line_rec.last_update_date,p_line_rec.org_id);
       END IF;
       IF p_x_interface_line_rec.GL_Date IS NOT NULL THEN
          p_x_interface_line_rec.GL_Date          := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(p_x_interface_line_rec.GL_Date,p_line_rec.org_id);
       END IF;
       IF p_x_interface_line_rec.conversion_date IS NOT NULL THEN
          p_x_interface_line_rec.conversion_date  := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(p_x_interface_line_rec.conversion_date,p_line_rec.org_id);
       END IF;
       IF p_x_interface_line_rec.sales_order_date IS NOT NULL THEN
          p_x_interface_line_rec.sales_order_date := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(p_x_interface_line_rec.sales_order_date,p_line_rec.org_id);
       END IF;
       IF p_x_interface_line_rec.rule_start_date IS NOT NULL THEN
          p_x_interface_line_rec.rule_start_date  := INV_LE_TIMEZONE_PUB.Get_Le_Day_Time_For_Ou(p_x_interface_line_rec.rule_start_date,p_line_rec.org_id);
       END IF;
      END IF;
    END IF;

    IF l_debug_level  > 0 THEN
       oe_debug_pub.add('After calling Legal Entity Time Zone ');
       oe_debug_pub.add('Value of ship_date_actual '||p_x_interface_line_rec.ship_date_actual||
                          ' Value of creation_date '|| p_x_interface_line_rec.creation_date);
       oe_debug_pub.add('Value of last_update_date '||p_x_interface_line_rec.last_update_date||
                         ' Value of sales_order_date '||p_x_interface_line_rec.sales_order_date);
    END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'END GLOBALIZATION' , 5 ) ;
    END IF;
    OE_DEBUG_PUB.dumpdebug;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXITING PREPARE_INTERFACE_LINE_REC ( ) PROCEDURE' , 5 ) ;
    END IF;
END Prepare_Interface_Line_Rec;

PROCEDURE Update_Invoice_Attributes
(   p_line_rec             IN  OE_Order_Pub.Line_Rec_Type
,   p_interface_line_rec   IN  RA_interface_Lines_Rec_Type
,   p_invoice_interface_status       IN VARCHAR2
,   x_return_status    OUT NOCOPY VARCHAR2
) IS
l_invoiced_quantity NUMBER;
l_Line_tbl              OE_Order_PUB.Line_Tbl_Type;
l_Old_Line_tbl          OE_Order_PUB.Line_Tbl_Type;
l_return_status         VARCHAR2(30);
l_flow_status_code      VARCHAR2(30);
err_msg 		VARCHAR2(240);
l_notify_index		NUMBER;  -- jolin

--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'UPDATING INVOICE ATTRIBUTES' , 5 ) ;
    END IF;
    IF OE_GLOBALS.G_ASO_INSTALLED IS NULL THEN
       OE_GLOBALS.G_ASO_INSTALLED := OE_GLOBALS.CHECK_PRODUCT_INSTALLED(697);
    END IF;
    l_invoiced_quantity := nvl(p_line_rec.invoiced_quantity, 0) + nvl(p_interface_line_rec.quantity, 0);
    --Bug2361642.Added a check for lines in "MANUAL-PENDING" status too.
 IF (p_invoice_interface_status = 'RFR-PENDING' OR
        p_invoice_interface_status= 'NOT_ELIGIBLE' OR
        p_invoice_interface_status = 'MANUAL-PENDING') AND
        nvl(l_invoiced_quantity, 0) = 0 THEN -- changed for bug# 4091846
       l_invoiced_quantity := null;
    END IF;
    --Bug2361642 Added an ELSE condition to retain the flow_status_code otherwise.   
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'INVOICED QUANTITY IS '|| TO_CHAR ( L_INVOICED_QUANTITY ) , 5 ) ;
    END IF;
    
    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL < '110510' THEN
           IF p_invoice_interface_status = 'YES' THEN
              l_flow_status_code := 'INVOICED';
           ELSIF p_invoice_interface_status = 'RFR-PENDING' THEN
              l_flow_status_code := 'INVOICED_PARTIAL';
           ELSE l_flow_status_code := p_line_rec.flow_status_code;
           END IF;
    ELSE
           IF p_invoice_interface_status = 'YES' THEN
              l_flow_status_code := 'INVOICED';
           ELSIF p_invoice_interface_status = 'MANUAL-PENDING' THEN
              l_flow_status_code := 'INVOICE_DELIVERY';
           ELSIF p_invoice_interface_status = 'RFR-PENDING' THEN
              IF nvl(l_invoiced_quantity, 0) =  0 THEN -- changed for bug# 4091846
                 l_flow_status_code := 'INVOICE_RFR';
              ELSE
	         l_flow_status_code := 'PARTIAL_INVOICE_RFR';
              END IF;
           ELSIF p_invoice_interface_status = 'NOT_ELIGIBLE' THEN
              l_flow_status_code := 'INVOICE_NOT_APPLICABLE'; 
           ELSE l_flow_status_code := p_line_rec.flow_status_code;
           END IF;
    END IF;
    
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'UPDATING FLOW STATUS CODE AS '||L_FLOW_STATUS_CODE , 5 ) ;
    END IF;
    UPDATE OE_ORDER_LINES_ALL
    SET INVOICE_INTERFACE_STATUS_CODE = p_invoice_interface_status,
        INVOICED_QUANTITY = l_invoiced_quantity,
        FLOW_STATUS_CODE = l_flow_status_code,
        CALCULATE_PRICE_FLAG = 'N',
	    LOCK_CONTROL = LOCK_CONTROL + 1
    WHERE LINE_ID = p_line_rec.line_id;
    IF ( (OE_GLOBALS.G_ASO_INSTALLED = 'Y') OR
          (NVL(FND_PROFILE.VALUE('ONT_DBI_INSTALLED'),'N') = 'Y')  ) THEN

        l_Line_tbl(1) := p_line_rec;
        l_Old_Line_tbl(1) := p_line_rec;
        l_Line_tbl(1).calculate_price_flag := 'N';
        l_Line_tbl(1).invoice_interface_status_code := p_invoice_interface_status;
        l_Line_tbl(1).invoiced_quantity := l_invoiced_quantity;
        l_line_tbl(1).lock_control := l_line_tbl(1).lock_control + 1;

-- jolin start
IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110508' THEN

    -- call notification framework to get this line's index position
    OE_ORDER_UTIL.Update_Global_Picture
	(p_Upd_New_Rec_If_Exists =>FALSE
	, p_line_rec		=> l_line_tbl(1)
	, p_old_line_rec	=> l_old_line_tbl(1)
        , p_line_id 		=> l_line_tbl(1).line_id
        , x_index 		=> l_notify_index
        , x_return_status 	=> l_return_status);
   
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'UPDATE_GLOBAL RET_STATUS FOR LINE_ID '||L_LINE_TBL ( 1 ) .LINE_ID ||' IS: ' || L_RETURN_STATUS , 1 ) ;
        oe_debug_pub.add(  'UPDATE_GLOBAL INDEX FOR LINE_ID '||L_LINE_TBL ( 1 ) .LINE_ID ||' IS: ' || L_NOTIFY_INDEX , 1 ) ;
    END IF;

        IF l_return_status = FND_API.G_RET_STS_ERROR THEN
           RAISE FND_API.G_EXC_ERROR;
        ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
	   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

   IF l_notify_index is not null then
     -- modify Global Picture
    OE_ORDER_UTIL.g_old_line_tbl(l_notify_index) := l_old_line_tbl(1);
    OE_ORDER_UTIL.g_line_tbl(l_notify_index) := OE_ORDER_UTIL.g_old_line_tbl(l_notify_index);
    OE_ORDER_UTIL.g_line_tbl(l_notify_index).invoice_interface_status_code:=
			l_line_tbl(1).invoice_interface_status_code;
    OE_ORDER_UTIL.g_line_tbl(l_notify_index).invoiced_quantity:=
			l_line_tbl(1).invoiced_quantity;
    OE_ORDER_UTIL.g_line_tbl(l_notify_index).flow_status_code:=	
			l_line_tbl(1).flow_status_code;
    OE_ORDER_UTIL.g_line_tbl(l_notify_index).calculate_price_flag:=
			l_line_tbl(1).calculate_price_flag;
    OE_ORDER_UTIL.g_line_tbl(l_notify_index).lock_control:=	
			l_line_tbl(1).lock_control;
    OE_ORDER_UTIL.g_line_tbl(l_notify_index).last_update_date:=	
			l_line_tbl(1).last_update_date;
    OE_ORDER_UTIL.g_line_tbl(l_notify_index).line_id:=	
			l_line_tbl(1).line_id;
    OE_ORDER_UTIL.g_line_tbl(l_notify_index).header_id:=	
			l_line_tbl(1).header_id;
         
    IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'GLOBAL LINE INVOICED_QUANTITY IS: ' || OE_ORDER_UTIL.G_LINE_TBL ( L_NOTIFY_INDEX ) .INVOICED_QUANTITY , 1 ) ;
       oe_debug_pub.add(  'GLOBAL LINE CALCULATE_PRICE_FLAG IS: ' || OE_ORDER_UTIL.G_LINE_TBL ( L_NOTIFY_INDEX ) .CALCULATE_PRICE_FLAG , 1 ) ;
       oe_debug_pub.add(  'GLOBAL LINE INVOICE_INTERFACE_STATUS_CODE IS: ' || OE_ORDER_UTIL.G_LINE_TBL ( L_NOTIFY_INDEX ) .INVOICE_INTERFACE_STATUS_CODE , 1 ) ;
      oe_debug_pub.add(  'GLOBAL LINE FLOW_STATUS_CODE IS: ' || OE_ORDER_UTIL.G_LINE_TBL ( L_NOTIFY_INDEX ) .FLOW_STATUS_CODE , 1 ) ;
    END IF;

    -- Process requests is TRUE so still need to call it, but don't need to notify
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OEXPINVB: BEFORE CALLING LINE PROCESS_REQUESTS_AND_NOTIFY' ) ;
    END IF;
        OE_Order_PVT.PROCESS_REQUESTS_AND_NOTIFY(
				P_LINE_TBL 	=>l_Line_tbl,
                                P_OLD_LINE_TBL 	=>l_Old_Line_tbl,
                                P_PROCESS_REQUESTS => TRUE,
                                P_NOTIFY 	=> FALSE,
                                P_PROCESS_ACK 	=> FALSE,
                                X_RETURN_STATUS => l_return_status);  

        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

   END IF ; /* global entity index null check */

  ELSE  /* pre-pack H */

     IF l_debug_level  > 0 THEN
         oe_debug_pub.add(  'OEXPINVB: BEFORE CALLING LINE PROCESS_REQUESTS_AND_NOTIFY' ) ;
     END IF;
        OE_Order_PVT.PROCESS_REQUESTS_AND_NOTIFY(
				P_LINE_TBL 	=>l_Line_tbl,
                                P_OLD_LINE_TBL 	=>l_Old_Line_tbl,
                                P_PROCESS_REQUESTS => TRUE,
                                P_NOTIFY 	=> TRUE,
                                P_PROCESS_ACK 	=> FALSE,
                                X_RETURN_STATUS => l_return_status);  

        IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

    END IF; /* code set is pack H or higher */
    /* jolin end*/

    END IF;

    x_return_status := FND_API.G_RET_STS_SUCCESS;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'RETURN STATUS : ' ||X_RETURN_STATUS ) ;
    END IF;

    IF OE_Commitment_Pvt.DO_Commitment_Sequencing THEN --commitment sequencing ON
       IF p_line_rec.commitment_id IS NOT NULL AND
          p_interface_line_rec.promised_commitment_amount IS NOT NULL THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'UPDATING OE_PAYMENTS' , 3 ) ;
          END IF;
          UPDATE oe_payments
          SET commitment_interfaced_amount = nvl(commitment_interfaced_amount, 0) + nvl(p_interface_line_rec.promised_commitment_amount, 0)
          WHERE LINE_ID = p_line_rec.line_id
          AND PAYMENT_TRX_ID = p_line_rec.commitment_id;
       END IF;
    END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'DONE UPDATING INVOICE ATTRIBUTES' , 1 ) ;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXCEPTION WHILE UPDATING INVOICE ATTRIBUTES : '||SQLERRM , 1 ) ;
         END IF;
         err_msg := 'Error in Update_Invoice_Attributes:\n '||SQLERRM;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  ERR_MSG ) ;
         END IF;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         IF FND_MSG_PUB.Check_Msg_Level
            (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
         THEN
            OE_MSG_PUB.Add_Exc_Msg
                        (   G_PKG_NAME
                        ,   'Update_Invoice_Attributes'
                        );
         END IF;
END Update_Invoice_Attributes;
FUNCTION Header_Activity
(p_line_id IN NUMBER
) RETURN BOOLEAN IS
l_header_id NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER HEADER_ACTIVITY ( ) PROCEDURE ' , 5 ) ;
    END IF;
    SELECT header_id
    INTO   l_header_id
    FROM   oe_order_lines
    WHERE  line_id = p_line_id;
    RETURN( WF_ENGINE.Activity_Exist_In_Process(
                      p_item_type => OE_GLOBALS.G_WFI_HDR
                     ,p_item_key  => to_char(l_header_id)
                     ,p_activity_name => 'HEADER_INVOICE_INTERFACE'));
END Header_Activity;

FUNCTION Line_Activity
(p_line_id IN NUMBER
) RETURN BOOLEAN IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER LINE_ACTIVITY ( ) PROCEDURE ' , 5 ) ;
    END IF;
    -- This function is provided by WF for our use with bug# 1040262.
    -- WF team removed this function at one stage and now provided the same
    -- for backward compatibility purpose with bug# 1869241.
    -- Issue with invoice interface due the the missing wf function is reported in bug# 1868026.
    RETURN( WF_ENGINE.Activity_Exist_In_Process(
                      p_item_type => OE_GLOBALS.G_WFI_LIN
                     ,p_item_key  => to_char(p_line_id)
                     ,p_activity_name => 'INVOICE_INTERFACE'));
END Line_Activity;

FUNCTION Update_Invoice_Numbers
( p_del_id   IN NUMBER
, p_del_name IN VARCHAR2
)RETURN NUMBER IS
inv_num_index NUMBER;
inv_num_base  VARCHAR2(40);
err_msg       VARCHAR2(240);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER UPDATE_INVOICE_NUMBERS ( ) PROCEDURE ' , 5 ) ;
        oe_debug_pub.add(  'UPDATE INVOICE NUMBERS: DEL_ID ' || TO_CHAR ( P_DEL_ID ) ||' DEL NAME: ' || P_DEL_NAME , 5 ) ;
    END IF;
    inv_num_base := p_del_name;
    SELECT nvl((max(index_number)+1), 0)
    INTO   inv_num_index
    FROM   oe_invoice_numbers
    WHERE  delivery_id = p_del_id;
    IF ( SQL%NOTFOUND ) THEN
        inv_num_index := 1;
    END IF;
    IF ( inv_num_index = 0 ) THEN
        inv_num := inv_num_base;
    ELSE
        inv_num := inv_num_base || '-' || to_char(inv_num_index);
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'GLOBAL USER ' || NVL(oe_standard_wf.g_user_id, fnd_global.user_id)); -- 3169637
        oe_debug_pub.add(  'INV NUM INDEX ' || TO_CHAR ( INV_NUM_INDEX ) ) ;
    END IF;
    INSERT INTO OE_INVOICE_NUMBERS(
                 INVOICE_NUMBER_ID
               , DELIVERY_ID
               , INDEX_NUMBER
               , LAST_UPDATE_DATE
               , LAST_UPDATED_BY
               , CREATION_DATE
               , CREATED_BY)
    VALUES
              ( oe_invoice_numbers_s.nextval
              , p_del_id
              , inv_num_index
              , SYSDATE
              , NVL(oe_standard_wf.g_user_id, fnd_global.user_id) -- 3169637 
              , SYSDATE
              , NVL(oe_standard_wf.g_user_id, fnd_global.user_id)); -- 3169637

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'DONE UPDATE_INVOICE_NUMBERS W/SUCCESS' , 5 ) ;
    END IF;
    RETURN 0;
  EXCEPTION
      WHEN OTHERS THEN
           err_msg := 'Error in update_invoice_numbers:\n '||SQLERRM;
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  ERR_MSG ) ;
               oe_debug_pub.add(  'WHEN OTHERS :EXITING UPDATE_INVOICE_NUMBERS' , 1 ) ;
           END IF;
           RETURN -1;
END Update_Invoice_Numbers;

PROCEDURE Update_Numbers
( p_id       IN  NUMBER
, x_return_status OUT NOCOPY VARCHAR2
) IS
l_count NUMBER := 0;
group_col_clause varchar2(10000) := '';
select_col       varchar2(10000) := '';
col_name         varchar2(100) ;
grp_stmt         varchar2(20000);
col_length       NUMBER;
group_cursor     INTEGER;
rows_processed   INTEGER;

last_concat_cols varchar2(5000) := '';
this_concat_cols varchar2(5000) := '';

last_del_name varchar2(30) := '';
this_del_name varchar2(30) := '';
this_del_id   Number;
this_rowid    Varchar2(20);
err_msg       VARCHAR2(240);

Type DelCurType IS REF CURSOR;
del_cursor   DelCurType;
CURSOR cur_get_cols IS
  SELECT upper(c.from_column_name), c.from_column_length
  FROM ra_group_by_columns c
  WHERE c.column_type = 'M';

CURSOR cur_get_del_id (p_del_name IN VARCHAR2) IS
  SELECT delivery_id
  FROM wsh_new_deliveries
  WHERE name = p_del_name;
  --
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  --
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER UPDATE_NUMBERS ( ) PROCEDURE' , 5 ) ;
    END IF;
    SELECT count(*)
    INTO   l_count
    FROM   ra_interface_lines_all
    WHERE  request_id = -1 * p_id;

    IF l_count = 0 THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'NO LINES NEED MANUAL NUMBERING' , 5 ) ;
       END IF;
       x_return_status := FND_API.G_RET_STS_SUCCESS;
       RETURN;
    END IF;
    -- Get all the group by columns from ra_group_by_columns table
    -- and build up the select and group by column clauses.
    OPEN cur_get_cols;
    LOOP
      FETCH cur_get_cols Into col_name, col_length;
      EXIT WHEN cur_get_cols%NOTFOUND;
      IF ( group_col_clause is NULL ) THEN
          group_col_clause := col_name;
          select_col := col_name;
          select_col := col_name;
      ELSE
          group_col_clause := group_col_clause || ', ' || col_name;
          select_col := select_col || '||' || '''~'''|| '||'|| col_name;
      END IF;
    END LOOP;
    CLOSE cur_get_cols;
    IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'POSITION 2' ) ;
    -- Build the full select statement and using dbms_sql execute
    -- the statement
       oe_debug_pub.add(  'POSITION 2-1' ) ;
    END IF;
    grp_stmt := 'Select ' || select_col || ' group_cols,'    ||
          ' l.interface_line_attribute3, ROWID '       ||
          ' From RA_INTERFACE_LINES_ALL L'             ||
          ' Where trx_number is NULL'                  ||
          ' And request_id = :p' ||
          ' Order by ' || group_col_clause             ||
          ' , l.interface_line_attribute3, l.org_id' ;
    OPEN del_cursor FOR grp_stmt USING (-1 * p_id);
    LOOP
      FETCH del_cursor INTO this_concat_cols, this_del_name, this_rowid;
      EXIT WHEN del_cursor%NOTFOUND;
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'DELIVERY NAME: ' || THIS_DEL_NAME , 5 ) ;
          oe_debug_pub.add(  'CONCAT COLS: ' || THIS_CONCAT_COLS , 5 ) ;
      END IF;
      IF ( last_del_name is NULL OR
           last_del_name <> this_del_name ) THEN
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'POSITION 5' ) ;
          END IF;
          OPEN cur_get_del_id(this_del_name);
          FETCH cur_get_del_id Into this_del_id;
          IF (cur_get_del_id%NOTFOUND ) THEN
             fnd_message.set_token('DELIVERY_NAME', this_del_name);
             fnd_message.set_name('OE', 'WSH_AR_INVALID_DEL_NAME');
             err_msg := fnd_message.get;
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  ERR_MSG ) ;
             END IF;
             CLOSE cur_get_del_id;
             --return;
          END IF;
          IF ( cur_get_del_id%ISOPEN ) THEN
             Close cur_get_del_id;
          END IF;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'DELIVERY ID: ' || TO_CHAR ( THIS_DEL_ID ) , 5 ) ;
          END IF;
      END IF;
      IF ( last_concat_cols is NULL OR
           last_concat_cols <> this_concat_cols ) THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'CONCAT COLS CHANGED , CALLING UPDATE_INVOICE' ) ;
         END IF;
         IF ( Update_Invoice_Numbers ( this_del_id, this_del_name) < 0 ) THEN
            x_return_status := FND_API.G_RET_STS_SUCCESS;
            RETURN;
         END IF;
         last_del_name := this_del_name;
         last_concat_cols := this_concat_cols;
      ELSE
         IF ( last_del_name <> this_del_name ) THEN
            IF l_debug_level  > 0 THEN
                oe_debug_pub.add(  'DEL NAME CHANGED , CALLING UPDATE_INVOICE' ) ;
            END IF;
            IF ( update_invoice_numbers ( this_del_id, this_del_name) < 0 ) THEN
               x_return_status := FND_API.G_RET_STS_SUCCESS;
               RETURN;
            END IF;
            last_del_name := this_del_name;
         END IF;
      END IF;
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'TRANSACTION NUMBER IS : '|| INV_NUM , 5 ) ;
      END IF;
      Update RA_INTERFACE_LINES_ALL
      set trx_number = inv_num
      where rowid = chartorowid(this_rowid);
    END LOOP;
    CLOSE del_cursor;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'SETTING REQUEST ID TO NULL' , 5 ) ;
    END IF;
    update ra_interface_lines_all
    set request_id=null
    where request_id = -1 * p_id;
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXITING UPDATE_NUMBERS ( ) PROCEDURE' , 5 ) ;
    END IF;
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'ORACLE ERROR: ' || SQLERRM , 1 ) ;
      END IF;
      err_msg := 'Error in update_numbers:\n '|| SQLERRM;
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  ERR_MSG ) ;
      END IF;
      x_return_status := FND_API.G_RET_STS_ERROR;
      IF (cur_get_cols%ISOPEN) THEN
        CLOSE cur_get_cols;
      END IF;
      IF (cur_get_del_id%ISOPEN) THEN
        CLOSE cur_get_del_id;
      END IF;
      IF l_debug_level  > 0 THEN
          oe_debug_pub.add(  'EXITING UPDATE_NUMBERS' , 1 ) ;
      END IF;
      RETURN;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXITING UPDATE_NUMBERS' , 1 ) ;
    END IF;
END Update_Numbers;

PROCEDURE Interface_Single_Line
(  p_line_rec    IN    OE_Order_PUB.Line_Rec_Type
,  p_header_rec  IN    OE_Order_PUB.Header_Rec_Type
,  p_x_interface_line_rec   IN OUT NOCOPY  RA_Interface_Lines_Rec_Type
,  x_return_status     OUT NOCOPY VARCHAR2
,  x_result_out        OUT NOCOPY  VARCHAR2
) IS
--gaynagar
l_freight_count NUMBER;
l_user_id          NUMBER;
l_resp_id          NUMBER;
l_appl_id          NUMBER;

CURSOR Pending_Lines IS
SELECT Line.line_id
FROM   oe_order_lines Line
WHERE (Line.link_to_line_id = p_line_rec.link_to_line_id
       OR Line.line_id = p_line_rec.link_to_line_id)
       AND invoice_interface_status_code = 'RFR-PENDING';

l_pending_line_id           NUMBER;
l_pending_line_rec          OE_Order_Pub.Line_Rec_Type;

l_result_code VARCHAR2(240);
l_return_status VARCHAR2(30);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTERING INTERFACE_SINGLE_LINE ( ) PROCEDURE' , 5 ) ;
        oe_debug_pub.add(  'INTERFACING LINE ID '||TO_CHAR ( P_LINE_REC.LINE_ID ) , 1 ) ;
    END IF;
    x_return_status := FND_API.G_RET_STS_SUCCESS;

--gaynagar added code for handling non-invoiceable lines
    IF NOT Line_Invoiceable(p_line_rec) THEN
         oe_debug_pub.add('Line is non invoiceable',1);
       /* Bug#2666125 start-check freight records and holds for non invoiceable items*/
     /*    BEGIN
	 IF oe_code_control.code_release_level < '110510' then
          SELECT count(*)
          INTO l_freight_count
          FROM oe_price_adjustments p
          WHERE p.header_id = p_line_rec.header_id
          AND (p.line_id IS NULL OR p.line_id = p_line_rec.line_id)
          AND p.list_line_type_code = 'FREIGHT_CHARGE'
          AND p.applied_flag = 'Y'
          AND NVL(p.invoiced_flag, 'N') = 'N';
         ELSE
          SELECT count(*)
          INTO l_freight_count
          FROM oe_price_adjustments p
          WHERE p.header_id = p_line_rec.header_id
          AND p.line_id IS NULL
          AND p.list_line_type_code = 'FREIGHT_CHARGE'
          AND p.applied_flag = 'Y'
          AND (NVL(p.invoiced_flag, 'N') = 'N' OR (NVL(p.invoiced_flag, 'N') = 'Y' AND p.adjusted_amount <> nvl(p.invoiced_amount, p.adjusted_amount)));
            IF l_freight_count = 0 then
               SELECT count(*)
               INTO l_freight_count
               FROM oe_price_adjustments p
               WHERE p.header_id = p_line_rec.header_id
                AND p.line_id = p_line_rec.line_id
                AND p.list_line_type_code = 'FREIGHT_CHARGE'
                AND p.applied_flag = 'Y'
                AND NVL(p.invoiced_flag, 'N') = 'N';
            END IF;
        END IF;       

        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           IF l_debug_level  > 0 THEN 
             oe_debug_pub.add('Non-invoiceable lines-In when no data found of freight');
           END IF;
           l_freight_count := 0;
        END;
        IF l_debug_level  > 0 THEN
        oe_debug_pub.add('l_freight_count: '||l_freight_count);
        END IF;
        IF l_freight_count >0 then
           Check_Invoicing_Holds(p_line_rec, g_itemtype, x_return_status);
             IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                   x_result_out := OE_GLOBALS.G_WFR_ON_HOLD;
                   RAISE FND_API.G_EXC_ERROR;
             ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                   x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
             END IF;
        END IF; */
       /* Bug#2666125 end-check freight records and holds for non invoiceable items*/
    
       Update_Invoice_Attributes(p_line_rec
                                ,p_x_interface_line_rec
                                ,'NOT_ELIGIBLE'
                                ,x_return_status);
       IF x_return_status = FND_API.G_RET_STS_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          RAISE FND_API.G_EXC_ERROR;
       ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       END IF;
       --- Eventhough line is not eligible for invoicing, there might be some other
       --- lines that are waiting for this line to trigger their invoicing activity.
       --- Ex: Included Items are not invoiceable but due to RFR, there might be
       --- some lines in RFR-PENDING block. We should invoice them.
       IF Is_PTO(p_line_rec) THEN
          IF Is_RFR(p_line_rec.line_id) THEN
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'RFR: THIS LINE IS RFR BUT NOT ELIGIBLE FOR INVOICING- CHECKING FOR PENDING LINES' , 5 ) ;
             END IF;
             Open Pending_Lines;
             LOOP
                 Fetch Pending_Lines Into l_pending_line_id;
                 EXIT WHEN Pending_Lines%NOTFOUND;
                 OE_Line_Util.Query_Row(p_line_id=>l_pending_line_id,x_line_rec=>l_pending_line_rec);
                 IF l_debug_level  > 0 THEN
                     oe_debug_pub.add(  'RFR: PENDING LINE ID : ' || TO_CHAR ( L_PENDING_LINE_ID ) , 5 ) ;
                 END IF;
                 IF Something_To_Invoice(l_pending_line_rec) THEN -- the pending line now has something to
                                                             -- invoice because current line has been shipped
                   IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'RFR: INTERFACING PENDING LINE ID :'||L_PENDING_LINE_ID , 5 ) ;
                   END IF;
                   Interface_Single_line(p_line_rec              => l_pending_line_rec
                                        ,p_header_rec            => p_header_rec
                                        ,p_x_interface_line_rec  => p_x_interface_line_rec
                                        ,x_return_status         => x_return_status
                                        ,x_result_out            => x_result_out);
                   IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'INTERFACING PENDING LINE ID ' || L_PENDING_LINE_REC.LINE_ID , 5 ) ;
                   END IF;
                   IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                         x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                         RAISE FND_API.G_EXC_ERROR;
                   ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                         x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                   ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                      IF x_result_out = OE_GLOBALS.G_WFR_PRTL_COMPLETE THEN
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'RFR PENDING LINE PARTIALLY INTERFACED' , 5 ) ;
                         END IF;
                      ELSE --x_result_out = OE_GLOBALS.G_WFR_COMPLETE THEN
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'RFR-PENDING LINE INTERFACED SUCCESSFULLY' , 5 ) ;
                         END IF;
                         WF_ENGINE.CompleteActivityInternalName(OE_GLOBALS.G_WFI_LIN, l_pending_line_rec.line_id, 'INVOICING_WAIT_FOR_RFR', 'COMPLETE');
                      END IF;
                   END IF;
                 END IF;
             END LOOP;
             close Pending_Lines;
         END IF; -- itself is a RFR line
       END IF; -- PTO line
       --freight line rec info comes from interface line rec. so prepare interface line rec
/* START Enhancement Request# 1915736 */
       -- Prepare interface line rec only if there are any freight charges to interface (Enhancement Request# 1915736)
       BEGIN

	 IF oe_code_control.code_release_level < '110510' then
          SELECT count(*)
          INTO l_freight_count
          FROM oe_price_adjustments p
          WHERE p.header_id = p_line_rec.header_id
          AND (p.line_id IS NULL OR p.line_id = p_line_rec.line_id)
          AND p.list_line_type_code = 'FREIGHT_CHARGE'
          AND p.applied_flag = 'Y'
          AND NVL(p.invoiced_flag, 'N') = 'N';
         ELSE
          SELECT count(*)
          INTO l_freight_count
          FROM oe_price_adjustments p
          WHERE p.header_id = p_line_rec.header_id
          AND p.line_id IS NULL
          AND p.list_line_type_code = 'FREIGHT_CHARGE'
          AND p.applied_flag = 'Y'
          AND (NVL(p.invoiced_flag, 'N') = 'N' OR (NVL(p.invoiced_flag, 'N') = 'Y' AND p.adjusted_amount <> nvl(p.invoiced_amount, p.adjusted_amount)));
            IF l_freight_count = 0 then
               SELECT count(*)
               INTO l_freight_count
               FROM oe_price_adjustments p
               WHERE p.header_id = p_line_rec.header_id
                AND p.line_id = p_line_rec.line_id
                AND p.list_line_type_code = 'FREIGHT_CHARGE'
                AND p.applied_flag = 'Y'
                AND NVL(p.invoiced_flag, 'N') = 'N';
            END IF;
        END IF;       

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'IN WHEN NO DATA FOUND OF FREIGHT' ) ;
           END IF;
           l_freight_count := 0;
       END;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'L_FREIGHT_COUNT: '||L_FREIGHT_COUNT ) ;
       END IF;
       IF l_freight_count > 0 THEN
/* END Enhancement Request# 1915736 */
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'PREPARING INTERFACE LINE RECORD' , 5 ) ;
          END IF;

          Prepare_Interface_Line_Rec(p_line_rec            =>   p_line_rec
                                    ,p_header_rec          =>   p_header_rec
                                    ,p_x_interface_line_rec  =>   p_x_interface_line_rec
                                    ,x_result_code         =>   l_result_code);
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'VALIDATING REQUIRED ATTRIBUTES' , 5 ) ;
          END IF;
          IF NOT Validate_Required_Attributes(p_line_rec, p_x_interface_line_rec) THEN
             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
             RAISE FND_API.G_EXC_ERROR;
          END IF;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'INTERFACING FREIGHT CHARGES' , 5 ) ;
          END IF;
          Interface_Freight_Charges(p_line_rec
                                  , p_x_interface_line_rec
                                  , x_return_status);
/* START Enhancement Request# 1915736 */
       END IF; -- for freight
/* END Enhancement Request# 1915736 */
       IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
             RAISE FND_API.G_EXC_ERROR;
       ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             x_result_out := OE_GLOBALS.G_WFR_NOT_ELIGIBLE;
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'RETURN AFTER INVOICEABLE ELIGIBLE CHECK' , 1 ) ;
             END IF;
             RETURN;
       END IF;
    END IF;
--gaynagar end
    
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'PREPARING INTERFACE LINE RECORD' , 5 ) ;
    END IF;
    Prepare_Interface_Line_Rec(p_line_rec            =>   p_line_rec
                              ,p_header_rec          =>   p_header_rec
                              ,p_x_interface_line_rec  =>   p_x_interface_line_rec
                              ,x_result_code         =>   l_result_code);
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'REQUEST_ID: '||P_X_INTERFACE_LINE_REC.REQUEST_ID || ' RESULT_CODE: '||L_RESULT_CODE , 5 ) ;
    END IF;
    IF ((p_x_interface_line_rec.QUANTITY = 0 OR p_x_interface_line_rec.QUANTITY IS NULL) AND l_result_code = 'RFR-PENDING') THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'ZERO QUANTITY LINE - NOT INTERFACED' , 5 ) ;
           oe_debug_pub.add(  'UPDATING INVOICE FLAG AND QUANTITY' , 5 ) ;
       END IF;
       IF l_result_code = 'RFR-PENDING' THEN
           Update_Invoice_Attributes(p_line_rec
                                     ,p_x_interface_line_rec
                                     ,'RFR-PENDING'
                                     ,x_return_status);
       IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN	   
          FND_MESSAGE.SET_NAME('ONT','OE_INVOICE_WAIT_FOR_RFR');
          OE_MSG_PUB.ADD;
       END IF;	  
       END IF;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'REQUEST_ID AFTER INSERTING '||P_X_INTERFACE_LINE_REC.REQUEST_ID , 5 ) ;
       END IF;
       IF x_return_status = FND_API.G_RET_STS_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          RAISE FND_API.G_EXC_ERROR;
       ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
          IF l_result_code = 'RFR-PENDING' THEN
             x_result_out := OE_GLOBALS.G_WFR_PRTL_COMPLETE;
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'LINE ID '||TO_CHAR ( P_LINE_REC.LINE_ID ) ||' PARTIALLY INTERFACED SUCCESSFULLY ' || 'X_RESULT_OUT: '||X_RESULT_OUT ||' L_RESULT_CODE '||L_RESULT_CODE ) ;
             END IF;
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'EXITING INTERFACE_SINGLE_LINE' , 5 ) ;
             END IF;
             RETURN; --Do not need to interface this line
          END IF;
       END IF;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'EXIT INTERFACE_SINGLE_LINE ( ) PROCEDURE ( 1 ) ' , 1 ) ;
       END IF;
       RETURN; --Do not need to interface this line
    END IF; -- Zero invoice quantity RFR
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'VALIDATE REQUIRED ATTRIBUTES' , 5 ) ;
    END IF;
    IF NOT Validate_Required_Attributes(p_line_rec, p_x_interface_line_rec) THEN
       x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
       RAISE FND_API.G_EXC_ERROR;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'INSERTING LINE INTO RA_INTERFACE_LINES' , 5 ) ;
    END IF;
    Insert_Line(p_x_interface_line_rec
                ,x_return_status=>l_return_status);
    -- Fix for the bug 2187074
    IF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
   
    -- 3685479 Replacing show detail dis by the following IF
    -- Adjustments need not be queried here as it is anyway going to be queried in interface_detail_discounts 
    Get_Createdby_Context(p_line_id => p_line_rec.line_id,
                         x_user_id      => l_user_id,
                         x_resp_id      => l_resp_id,
                         x_resp_appl_id => l_appl_id);
    IF (fnd_profile.value_specific('OE_DISCOUNT_DETAILS_ON_INVOICE', l_user_id,l_resp_id,l_appl_id) = 'Y') THEN
  	   IF l_debug_level  > 0 THEN
  	       oe_debug_pub.add(  'INSERTING DISCOUNT DETAILS' , 5 ) ;
  	   END IF;
        Interface_Detail_Discounts(p_line_rec, p_x_interface_line_rec
                                   ,x_return_status);
        -- Fix for the bug 2187074
        IF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
           x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
           RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'INTERFACING FREIGHT CHARGES' , 5 ) ;
    END IF;
    Interface_Freight_Charges(p_line_rec
                            , p_x_interface_line_rec
                            , x_return_status);
    IF x_return_status = FND_API.G_RET_STS_ERROR THEN
       x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
       RAISE FND_API.G_EXC_ERROR;
    ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'INTERFACING SALES CREDITS' , 5 ) ;
    END IF;
    Interface_Salescredits(p_line_rec
                          ,p_x_interface_line_rec
                          ,x_return_status);
    IF x_return_status = FND_API.G_RET_STS_ERROR THEN
       x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
       RAISE FND_API.G_EXC_ERROR;
    ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'UPDATING INVOICE FLAG AND QUANTITY' , 5 ) ;
    END IF;
    IF l_result_code = 'RFR-PENDING' THEN
        Update_Invoice_Attributes(p_line_rec
                             ,p_x_interface_line_rec
                             ,'RFR-PENDING'
                             ,x_return_status);
    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
       FND_MESSAGE.SET_NAME('ONT','OE_INVOICE_WAIT_FOR_RFR');
       OE_MSG_PUB.ADD;
    END IF;
    ELSE
        Update_Invoice_Attributes(p_line_rec
                             ,p_x_interface_line_rec
                             ,'YES'
                             ,x_return_status);
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'REQUEST_ID AFTER INSERTING '||P_X_INTERFACE_LINE_REC.REQUEST_ID ) ;
    END IF;
    IF x_return_status = FND_API.G_RET_STS_ERROR THEN
       x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
       RAISE FND_API.G_EXC_ERROR;
    ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
       x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
       IF l_result_code = 'RFR-PENDING' THEN
          x_result_out := OE_GLOBALS.G_WFR_PRTL_COMPLETE;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'LINE ID '||TO_CHAR ( P_LINE_REC.LINE_ID ) ||' PARTIALLY INTERFACED SUCCESSFULLY' , 1 ) ;
          END IF;
       ELSE
          x_result_out := OE_GLOBALS.G_WFR_COMPLETE;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'LINE ID '||TO_CHAR ( P_LINE_REC.LINE_ID ) ||' INTERFACED SUCCESSFULLY' , 1 ) ;
          END IF;
       END IF;
    END IF;

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXIT INTERFACE_SINGLE_LINE ( ) PROCEDURE SUCCESSFULLY' , 1 ) ;
    END IF;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXPECTED ERROR. EXITING INTERFACE_SINGLE_LINE : '||SQLERRM , 1 ) ;
         END IF;
         x_return_status := FND_API.G_RET_STS_ERROR;
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'RETURN STATUS :'||X_RETURN_STATUS||' OUT RESULT : '||X_RESULT_OUT , 5 ) ;
         END IF;
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'UNEXPECTED ERROR. EXITING INTERFACE_SINGLE_LINE '||SQLERRM , 1 ) ;
             oe_debug_pub.add(  'RETURN STATUS :'||X_RETURN_STATUS||' OUT RESULT : '||X_RESULT_OUT , 5 ) ;
         END IF;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    WHEN OTHERS THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'OTHER EXCEPTION. EXITING INTERFACE_SINGLE_LINE : '||SQLERRM , 1 ) ;
             oe_debug_pub.add(  'RETURN STATUS :'||X_RETURN_STATUS||' OUT RESULT : '||X_RESULT_OUT , 5 ) ;
         END IF;
         IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
               OE_MSG_PUB.Add_Exc_Msg
               (   G_PKG_NAME
               ,   'Interface_Single_line'
               );
         END IF;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
END Interface_Single_line;

PROCEDURE Interface_Line
(   p_line_id       IN   NUMBER
,   p_itemtype      IN   VARCHAR2
,   x_result_out    OUT  NOCOPY VARCHAR2
,   x_return_status OUT  NOCOPY VARCHAR2
) IS
l_interface_line_rec        RA_Interface_Lines_Rec_Type;
l_line_rec                  OE_Order_Pub.Line_Rec_Type;
l_header_rec                OE_Order_Pub.Header_Rec_Type;
l_dummy                     VARCHAR2(240);
l_delivery_line_id          NUMBER := NULL;
l_line_delivery_id  NUMBER := NULL;
l_line_id                   NUMBER;
l_interface_status_code     VARCHAR2(30);
l_old_interface_status_code VARCHAR2(30);
l_pending_line_id           NUMBER;
l_pending_line_rec          OE_Order_Pub.Line_Rec_Type;
del_line_ready_flag         VARCHAR2(1) := NULL;
interface_this_line         VARCHAR2(1) := 'Y';
l_result_code               VARCHAR2(240);
generate_invoice_number     VARCHAR2(1) := 'N';
x_msg_count                 NUMBER;
x_msg_data                  VARCHAR2(240);
p_header_id                 NUMBER := NULL;
l_return_status		        VARCHAR2(30);
l_open_flag                 VARCHAR2(1);
l_flow_status_code      VARCHAR2(30);
/* START Enhancement Request# 1915736 */
l_freight_count             NUMBER;
/* END Enhancement Request# 1915736 */
-- Fix for bug 2224248
l_invoice_rec                  OE_Order_Pub.Line_Rec_Type;
-- Fix for the bug 2196494
CURSOR delivery_lines_cursor(p_delivery_id  IN NUMBER) IS
SELECT  distinct dd.source_line_id
FROM    wsh_new_deliveries dl,
        wsh_delivery_assignments da,
        wsh_delivery_details dd
WHERE   dd.delivery_detail_id  = da.delivery_detail_id
AND     da.delivery_id  = dl.delivery_id
AND     dd.source_code = 'OE'
AND     dl.delivery_id = p_delivery_id
AND     dd.source_line_id is not null
UNION ALL
SELECT  distinct dd.top_model_line_id
FROM    wsh_new_deliveries dl,
        wsh_delivery_assignments da,
        wsh_delivery_details dd
WHERE   dd.delivery_detail_id  = da.delivery_detail_id
AND     da.delivery_id  = dl.delivery_id
AND     dd.source_code = 'OE'
AND     dl.delivery_id = p_delivery_id
AND     dd.top_model_line_id is not null;

CURSOR cur1(p_delivery_id  IN NUMBER) IS -- added for 4056636
SELECT  'x'
FROM    wsh_new_deliveries dl,
        wsh_delivery_assignments da,
        wsh_delivery_details dd
WHERE   dd.delivery_detail_id  = da.delivery_detail_id
AND     da.delivery_id  = dl.delivery_id
AND     dd.source_code = 'OE'
AND     dl.delivery_id = p_delivery_id
AND     (dd.source_line_id is not null OR
         dd.top_model_line_id is not null)
for update of dd.source_line_id nowait;

CURSOR Pending_Lines IS
SELECT Line.line_id
FROM   oe_order_lines Line
WHERE (Line.link_to_line_id = l_line_rec.link_to_line_id
       OR Line.line_id = l_line_rec.link_to_line_id)
       AND invoice_interface_status_code = 'RFR-PENDING';
       --
       l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
       --
l_delivery_name VARCHAR2(30);
--bug# 4090604
delivery_line_processed VARCHAR2(1):='N';
current_line_return_status VARCHAR2(30);
current_line_result_out VARCHAR2(30);
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTERING INTERFACE_LINE ( ) PROCEDURE' , 1 ) ;
        oe_debug_pub.add(  'LINE ID : '|| P_LINE_ID , 5 ) ;
        oe_debug_pub.add(  'ITEM TYPE : '||P_ITEMTYPE , 5 ) ;
    END IF;
    IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
       SAVEPOINT INVOICE_INTERFACE;
    END IF;

    --Exception management begin
    OE_MSG_PUB.set_msg_context(
           p_entity_code           => 'LINE'
          ,p_entity_id                  => p_line_id
          ,p_line_id                    => p_line_id );
    --Exception management end

    -- Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    G_ITEMTYPE := p_itemtype;
    OE_Line_Util.Lock_Row(p_line_id=>p_line_id
    		, p_x_line_rec => l_line_rec
     		, x_return_status => l_return_status
	    	);
    IF    l_return_status = FND_API.G_RET_STS_ERROR THEN
	      RAISE FND_API.G_EXC_ERROR;
    ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
	      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
    OE_Header_Util.Query_row(p_header_id=>l_line_rec.header_id,x_header_rec=>l_header_rec);
    IF p_itemtype = OE_GLOBALS.G_WFI_HDR THEN
       p_header_id := l_line_rec.header_id;
    END IF;
    -- Set message context
    OE_MSG_PUB.set_msg_context(
           p_entity_code           => 'LINE'
          ,p_entity_id                  => l_line_rec.line_id
          ,p_header_id                  => l_line_rec.header_id
          ,p_line_id                    => l_line_rec.line_id
          ,p_order_source_id            => l_line_rec.order_source_id
          ,p_orig_sys_document_ref      => l_line_rec.orig_sys_document_ref
          ,p_orig_sys_document_line_ref => l_line_rec.orig_sys_line_ref
          ,p_orig_sys_shipment_ref      => l_line_rec.orig_sys_shipment_ref
          ,p_change_sequence            => l_line_rec.change_sequence
          ,p_source_document_type_id    => l_line_rec.source_document_type_id
          ,p_source_document_id         => l_line_rec.source_document_id
          ,p_source_document_line_id    => l_line_rec.source_document_line_id );

-- gaynagar controlled code for non-invoiceable lines based on invoice numbering method
    IF NOT Line_Invoiceable(l_line_rec) THEN
       /* Bug#2666125 start-check freight records and holds for non invoiceable items*/
         BEGIN
	 IF oe_code_control.code_release_level < '110510' then
          SELECT count(*)
          INTO l_freight_count
          FROM oe_price_adjustments p
          WHERE p.header_id = l_line_rec.header_id
          AND (p.line_id IS NULL OR p.line_id = l_line_rec.line_id)
          AND p.list_line_type_code = 'FREIGHT_CHARGE'
          AND p.applied_flag = 'Y'
          AND NVL(p.invoiced_flag, 'N') = 'N';
         ELSE
          SELECT count(*)
          INTO l_freight_count
          FROM oe_price_adjustments p
          WHERE p.header_id = l_line_rec.header_id
          AND p.line_id IS NULL
          AND p.list_line_type_code = 'FREIGHT_CHARGE'
          AND p.applied_flag = 'Y'
          AND (NVL(p.invoiced_flag, 'N') = 'N' OR (NVL(p.invoiced_flag, 'N') = 'Y' AND p.adjusted_amount <> nvl(p.invoiced_amount, p.adjusted_amount)));
            IF l_freight_count = 0 then
               SELECT count(*)
               INTO l_freight_count
               FROM oe_price_adjustments p
               WHERE p.header_id = l_line_rec.header_id
                AND p.line_id = l_line_rec.line_id
                AND p.list_line_type_code = 'FREIGHT_CHARGE'
                AND p.applied_flag = 'Y'
                AND NVL(p.invoiced_flag, 'N') = 'N';
            END IF;
        END IF;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           IF l_debug_level  > 0 THEN 
             oe_debug_pub.add('Non-invoiceable lines-In when no data found of freight');
           END IF;
           l_freight_count := 0;
        END;
        IF l_debug_level  > 0 THEN
        oe_debug_pub.add('l_freight_count: '||l_freight_count);
        END IF;
        IF l_freight_count >0 then
           Check_Invoicing_Holds(l_line_rec, p_itemtype, x_return_status);
             IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                   x_result_out := OE_GLOBALS.G_WFR_ON_HOLD;
                   RAISE FND_API.G_EXC_ERROR;
             ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                   x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
             END IF;
        END IF;
       /* Bug#2666125 end-check freight records and holds for non invoiceable items*/
     IF 
      -- l_freight_count = 0 OR 
         FND_PROFILE.VALUE('WSH_INVOICE_NUMBERING_METHOD') = 'A' THEN
       oe_debug_pub.add('Handling non-invoiceable lines with no freight or automatic numbering',1);
       Update_Invoice_Attributes(l_line_rec
                                ,l_interface_line_rec
                                ,'NOT_ELIGIBLE'
                                ,x_return_status);
       IF x_return_status = FND_API.G_RET_STS_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          RAISE FND_API.G_EXC_ERROR;
       ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       END IF;
       --- Eventhough line is not eligible for invoicing, there might be some other
       --- lines that are waiting for this line to trigger their invoicing activity.
       --- Ex: Included Items are not invoiceable but due to RFR, there might be
       --- some lines in RFR-PENDING block. We should invoice them.
       IF Is_PTO(l_line_rec) THEN
          IF Is_RFR(l_line_rec.line_id) THEN
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'RFR: THIS LINE IS RFR BUT NOT ELIGIBLE FOR INVOICING- CHECKING FOR PENDING LINES' , 5 ) ;
             END IF;
             Open Pending_Lines;
             LOOP
                 Fetch Pending_Lines Into l_pending_line_id;
                 EXIT WHEN Pending_Lines%NOTFOUND;
                 OE_Line_Util.Query_Row(p_line_id=>l_pending_line_id,x_line_rec=>l_pending_line_rec);
                 IF l_debug_level  > 0 THEN
                     oe_debug_pub.add(  'RFR: PENDING LINE ID : ' || TO_CHAR ( L_PENDING_LINE_ID ) , 5 ) ;
                 END IF;
                 IF Something_To_Invoice(l_pending_line_rec) THEN -- the pending line now has something to
                                                             -- invoice because current line has been shipped
                   IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'RFR: INTERFACING PENDING LINE ID :'||L_PENDING_LINE_ID , 5 ) ;
                   END IF;
                   Interface_Single_line(p_line_rec              => l_pending_line_rec
                                        ,p_header_rec            => l_header_rec
                                        ,p_x_interface_line_rec  => l_interface_line_rec
                                        ,x_return_status         => x_return_status
                                        ,x_result_out            => x_result_out);
                   IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'INTERFACING PENDING LINE ID ' || L_PENDING_LINE_REC.LINE_ID , 5 ) ;
                   END IF;
                   IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                         x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                         RAISE FND_API.G_EXC_ERROR;
                   ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                         x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                   ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                      IF x_result_out = OE_GLOBALS.G_WFR_PRTL_COMPLETE THEN
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'RFR PENDING LINE PARTIALLY INTERFACED' , 5 ) ;
                         END IF;
                      ELSE --x_result_out = OE_GLOBALS.G_WFR_COMPLETE THEN
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'RFR-PENDING LINE INTERFACED SUCCESSFULLY' , 5 ) ;
                         END IF;
                         WF_ENGINE.CompleteActivityInternalName(OE_GLOBALS.G_WFI_LIN, l_pending_line_rec.line_id, 'INVOICING_WAIT_FOR_RFR', 'COMPLETE');
                      END IF;
                   END IF;
                 END IF;
             END LOOP;
             close Pending_Lines;
         END IF; -- itself is a RFR line
       END IF; -- PTO line
       --freight line rec info comes from interface line rec. so prepare interface line rec
/* START Enhancement Request# 1915736 */
       -- Prepare interface line rec only if there are any freight charges to interface (Enhancement Request# 1915736)
       BEGIN
	IF oe_code_control.code_release_level < '110510' then
          SELECT count(*)
          INTO l_freight_count
          FROM oe_price_adjustments p
          WHERE p.header_id = l_line_rec.header_id
          AND (p.line_id IS NULL OR p.line_id = l_line_rec.line_id)
          AND p.list_line_type_code = 'FREIGHT_CHARGE'
          AND p.applied_flag = 'Y'
          AND NVL(p.invoiced_flag, 'N') = 'N';
	ELSE
          SELECT count(*)
          INTO l_freight_count
          FROM oe_price_adjustments p
          WHERE p.header_id = l_line_rec.header_id
          AND p.line_id IS NULL
          AND p.list_line_type_code = 'FREIGHT_CHARGE'
          AND p.applied_flag = 'Y'
          AND (NVL(p.invoiced_flag, 'N') = 'N' OR (NVL(p.invoiced_flag, 'N') = 'Y' AND p.adjusted_amount <> nvl(p.invoiced_amount, p.adjusted_amount)));
           IF l_freight_count = 0 then
               SELECT count(*)
               INTO l_freight_count
               FROM oe_price_adjustments p
               WHERE p.header_id = l_line_rec.header_id
                AND p.line_id = l_line_rec.line_id
                AND p.list_line_type_code = 'FREIGHT_CHARGE'
                AND p.applied_flag = 'Y'
                AND NVL(p.invoiced_flag, 'N') = 'N';
            END IF;
      END IF;
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'IN WHEN NO DATA FOUND OF FREIGHT' ) ;
           END IF;
           l_freight_count := 0;
       END;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'L_FREIGHT_COUNT: '||L_FREIGHT_COUNT ) ;
       END IF;
       IF l_freight_count > 0 THEN
/* END Enhancement Request# 1915736 */
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'PREPARING INTERFACE LINE RECORD' , 5 ) ;
          END IF;
          Prepare_Interface_Line_Rec(p_line_rec            =>   l_line_rec
                                    ,p_header_rec          =>   l_header_rec
                                    ,p_x_interface_line_rec  =>   l_interface_line_rec
                                    ,x_result_code         =>   l_result_code);
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'VALIDATING REQUIRED ATTRIBUTES' , 5 ) ;
          END IF;
          IF NOT Validate_Required_Attributes(l_line_rec, l_interface_line_rec) THEN
             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
             RAISE FND_API.G_EXC_ERROR;
          END IF;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'INTERFACING FREIGHT CHARGES' , 5 ) ;
          END IF;
          Interface_Freight_Charges(l_line_rec
                                  , l_interface_line_rec
                                  , x_return_status);
/* START Enhancement Request# 1915736 */
       END IF; -- for freight
/* END Enhancement Request# 1915736 */
       IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
             RAISE FND_API.G_EXC_ERROR;
       ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             x_result_out := OE_GLOBALS.G_WFR_NOT_ELIGIBLE;
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'RETURN AFTER INVOICEABLE ELIGIBLE CHECK' , 1 ) ;
             END IF;
             RETURN;
       END IF;
    END IF; --freight_count zero or automatic numbering
   END IF; -- non-invoiceable lines check

    Check_Invoicing_Holds(l_line_rec, p_itemtype, x_return_status);
    IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_ON_HOLD;
          RAISE FND_API.G_EXC_ERROR;
    ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;
    IF FND_PROFILE.VALUE('WSH_INVOICE_NUMBERING_METHOD') = 'D' THEN
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'INVOICE NUMBERING SET TO MANUAL' , 5 ) ;
       END IF;
       IF Shipping_Info_Available(l_line_rec) AND NOT Return_Line(l_line_rec) THEN
          -- Fix for bug 2196494
          IF (l_line_rec.item_type_code NOT IN ('MODEL','CLASS','KIT')) THEN
      	  IF l_debug_level  > 0 THEN
      	      oe_debug_pub.add(  'SHIPPING INFORMATION IS AVAILABLE' ) ;
      	  END IF;
   --Bug2181628 TO retrieve the minimum delivery_id of a line,if it is present
   --in more than one delivery.Hence used "MIN"instead of "ROWNUM".    
        SELECT min(dl.delivery_id)
          INTO   l_delivery_line_id
          FROM   wsh_new_deliveries dl,
                 wsh_delivery_assignments da,
                 wsh_delivery_details dd
          WHERE  dd.delivery_detail_id  = da.delivery_detail_id
          AND    da.delivery_id  = dl.delivery_id
          AND    dd.source_code = 'OE'
          AND    dd.source_line_id = l_line_rec.line_id;
        --  AND    rownum = 1;
          -- Fix for bug 2196494
          ELSE
          SELECT min(dl.delivery_id)
          INTO   l_delivery_line_id
          FROM   wsh_new_deliveries dl,
                 wsh_delivery_assignments da,
                 wsh_delivery_details dd
          WHERE  dd.delivery_detail_id  = da.delivery_detail_id
          AND    da.delivery_id  = dl.delivery_id
          AND    dd.source_code = 'OE'
          AND    dd.top_model_line_id = l_line_rec.line_id;
      --    AND    rownum = 1;
          END IF;

          -- fix: temporary
          IF l_delivery_line_id IS NOT NULL THEN
	         IF l_debug_level  > 0 THEN
	             oe_debug_pub.add(  'DELIVERY ID : '||L_DELIVERY_LINE_ID , 5 ) ;
	         END IF;
             /* added for bug fix 4056636 */
             BEGIN
               IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'locking '||to_char(sysdate,'HH24:MI:SS') ,5 ) ;
               END IF;
               open cur1(l_delivery_line_id);
               close cur1;
               IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'locking: locked' , 5 ) ;
               END IF;
             EXCEPTION
               when app_exceptions.RECORD_LOCK_EXCEPTION then
                IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'locking: cannot lock' , 5 ) ;
                END IF;
                x_return_status := 'DEFERRED';
                RETURN;
               when others then
                IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'locking: exception:'||sqlerrm , 5 ) ;
                END IF;
             END; -- end of bug fix 4056636

             OPEN delivery_lines_cursor(l_delivery_line_id);
             LOOP
                  FETCH  delivery_lines_cursor  INTO l_line_id;
                  EXIT WHEN delivery_lines_cursor%NOTFOUND;
                  SELECT invoice_interface_status_code, open_flag
                  INTO   l_interface_status_code, l_open_flag
                  FROM   oe_order_lines
                  WHERE  line_id = l_line_id;
            	  IF l_debug_level  > 0 THEN
            	      oe_debug_pub.add(  'LINE ID : '||L_LINE_ID , 5 ) ;
            	  END IF;
                  IF  l_interface_status_code = 'YES' OR
			          l_interface_status_code = 'NOT_ELIGIBLE' OR
                      l_interface_status_code = 'MANUAL-PENDING' OR
                      l_interface_status_code = 'RFR-PENDING' OR
                      l_open_flag = 'N' OR
                      l_line_id = p_line_id THEN --this line is ready to invoice
                      del_line_ready_flag := 'Y';
                  ELSE
                      --If there is no INVOICE_INTERFACE activity in the flow then do not wait for the line
	              IF NOT Line_Activity(l_line_id) then
                          del_line_ready_flag := 'Y';
                          -- Fix for bug 2164555
                          -- Fix for bug 2224248. Changed the variable l_line_rec to l_invoice_rec.
                      ELSE
                              l_invoice_rec :=OE_Line_Util.Query_Row(p_line_id=>l_line_id);
--Bug2181628 Check if the current line's delivery_id is the same as the delivery_id
--being processed.If it is the same then wait for this line,else do not wait indefinetely.
--Bug3071154 Check the shippable flag also 
                                 IF Shipping_Info_Available(l_invoice_rec) 
                                  AND (l_invoice_rec.shippable_flag = 'Y')  THEN
				    l_line_delivery_id := NULL;
                                    SELECT min(dl.delivery_id)
                                    INTO l_line_delivery_id
                                    FROM wsh_new_deliveries dl,
                                         wsh_delivery_assignments da,
                                         wsh_delivery_details dd
                                    WHERE dd.delivery_detail_id  = da.delivery_detail_id   
                                    AND   da.delivery_id  = dl.delivery_id
                                    AND   dd.source_code = 'OE'
                                    AND   dd.source_line_id = l_line_id;

                                      IF l_line_delivery_id IS NULL AND l_invoice_rec.item_type_code in ('MODEL', 'CLASS', 'KIT') THEN
                                      SELECT min(dl.delivery_id)
                                      INTO l_line_delivery_id
                                      FROM wsh_new_deliveries dl,
                                           wsh_delivery_assignments da,
                                           wsh_delivery_details dd
                                      WHERE dd.delivery_detail_id  = da.delivery_detail_id
                                      AND   da.delivery_id  = dl.delivery_id
                                      AND   dd.source_code = 'OE'
                                      AND   dd.top_model_line_id = l_line_id;
                                    END IF;
                                 ELSE
                                   IF l_invoice_rec.item_type_code in ('MODEL', 'CLASS', 'KIT') THEN
                                      l_line_delivery_id := NULL;
                                      SELECT min(dl.delivery_id)
                                      INTO l_line_delivery_id
                                      FROM wsh_new_deliveries dl,
                                           wsh_delivery_assignments da,
                                           wsh_delivery_details dd
                                      WHERE dd.delivery_detail_id  = da.delivery_detail_id   
                                      AND   da.delivery_id  = dl.delivery_id
                                      AND   dd.source_code = 'OE'
                                      AND   dd.top_model_line_id = l_line_id;
                                   END IF;
                                 END IF;
                                 IF  (l_line_delivery_id <> l_delivery_line_id) THEN
                                    del_line_ready_flag := 'Y';
                                 ELSE   
                                    del_line_ready_flag := 'N';
                                 END IF;
                              END IF;
                      END IF;
                  EXIT WHEN del_line_ready_flag = 'N';
              END LOOP;
              CLOSE delivery_lines_cursor;
       	      IF l_debug_level  > 0 THEN
       	          oe_debug_pub.add(  'DELIVERY LINE READY FLAG : '||DEL_LINE_READY_FLAG , 5 ) ;
       	      END IF;
              IF del_line_ready_flag = 'N' THEN -- atleast one line in delivery is not ready to interface
	             IF l_debug_level  > 0 THEN
	                 oe_debug_pub.add(  'SOME OF THE LINES IN THE DELIVERY ARE NOT READY' , 5 ) ;
	             END IF;
                 IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
	                IF l_debug_level  > 0 THEN
	                    oe_debug_pub.add(  'LINE LEVEL INVOICING-SET STATUS TO PENDING' , 5 ) ;
	                END IF;
                    Update_Invoice_Attributes(l_line_rec
                                       ,l_interface_line_rec
                                       ,'MANUAL-PENDING'
                                       ,x_return_status);
		    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
                       IF l_delivery_line_id Is Not Null Then
                          SELECT NVL(SUBSTR(dl.name, 1, 30), '0')
                          INTO l_delivery_name 
                          FROM   wsh_new_deliveries dl
                          WHERE  dl.delivery_id = l_delivery_line_id;
                       END IF;
		       FND_MESSAGE.SET_NAME('ONT','OE_INVOICE_WAIT_FOR_DELIVERY');
                       FND_MESSAGE.SET_TOKEN('DELIVERY_NAME',l_delivery_name);
                       OE_MSG_PUB.ADD;
		    END IF;
                    IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'INTERFACE STATUS : '||L_LINE_REC.INVOICE_INTERFACE_STATUS_CODE , 5 ) ;
                       oe_debug_pub.add(  'X_RETURN_STATUS : '||X_RETURN_STATUS , 5 ) ;
                    END IF;
                    IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                          RAISE FND_API.G_EXC_ERROR;
                    ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                    ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                          x_result_out := OE_GLOBALS.G_WFR_PRTL_COMPLETE; -- this actually is pending, we call it partial for WF
                          RETURN;
                    END IF;
                 ELSE -- header level invoice, all delivery lines are not ready to invoice. do not honor delivery.
                    IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'HDR INVOICING- PROCEED W/INVOICING' , 5 ) ;
                    END IF;
                    generate_invoice_number := 'Y';
                    interface_this_line := 'Y';
                 END IF;
              ELSIF del_line_ready_flag = 'Y' THEN --invoice all lines in delivery
                 IF l_debug_level  > 0 THEN
                     oe_debug_pub.add(  'ALL LINES IN DELIVERY ARE READY' , 5 ) ;
                 END IF;
                 --except we need to check for any line in the delivery actually is not invoiciable
                 --due to RFR
                 OPEN delivery_lines_cursor(l_delivery_line_id);
                 LOOP
                      FETCH  delivery_lines_cursor  INTO l_line_id;
                      EXIT WHEN delivery_lines_cursor%NOTFOUND;
                      OE_Line_Util.Query_Row(p_line_id=>l_line_id, x_line_rec=>l_line_rec);
                      OE_Header_Util.Query_row(p_header_id=>l_line_rec.header_id,x_header_rec=>l_header_rec);
	                  IF l_debug_level  > 0 THEN
	                      oe_debug_pub.add(  'LINE ID : '||L_LINE_REC.LINE_ID , 5 ) ;
	                  END IF;
--gaynagar processing non-invoiceable lines with delivery lines
                      IF l_line_rec.open_flag='Y' AND
                         NVL(l_line_rec.invoice_interface_status_code, 'NO') <> 'YES' AND
                         NVL(l_line_rec.invoice_interface_status_code, 'NO') <> 'NOT_ELIGIBLE' THEN 
                         -- Fix for bug 2224248
                         --Line_Invoiceable(l_line_rec) THEN
                         IF (l_line_id <> p_line_id AND Line_Activity(l_line_rec.line_id) OR (l_line_id = p_line_id))THEN
                             -- in devliery and pto, and has something/full qty to invoice - invoice whatever possible,
                             -- update to RFR-PENDING if necessarily
                             -- in delivery and pto, nothing to invoice - update status to RFR-PENDING
                             -- in delivery and not in pto - invoice
                             -- it is possible for lines in differnt orders in the same delivery
                             -- so ready in a delivery doesn't mean line has something to interface
                             --Bug2181628 Check if the current line's delivery_id is the same as the delivery_id
                             --being processed.If it is the same then wait for this line,else do not wait indefinetely.
                             --Bug 3071154 Check the shippable flag also.
                           IF (l_line_id <> p_line_id) THEN  
                               IF Shipping_Info_Available(l_line_rec)
                                AND (l_line_rec.shippable_flag = 'Y') THEN
                                   l_line_delivery_id := NULL;
                                   SELECT min(dl.delivery_id)
                                   INTO l_line_delivery_id
                                   FROM wsh_new_deliveries dl,
                                        wsh_delivery_assignments da,
                                        wsh_delivery_details dd
                                   WHERE dd.delivery_detail_id  = da.delivery_detail_id
                                   AND   da.delivery_id  = dl.delivery_id
                                   AND   dd.source_code = 'OE'
                                   AND   dd.source_line_id = l_line_id;

                                    IF l_line_delivery_id IS NULL AND l_line_rec.item_type_code in ('MODEL', 'CLASS', 'KIT') THEN
                                     SELECT min(dl.delivery_id)
                                     INTO l_line_delivery_id
                                     FROM wsh_new_deliveries dl,
                                          wsh_delivery_assignments da,
                                          wsh_delivery_details dd
                                      WHERE dd.delivery_detail_id  = da.delivery_detail_id
                                      AND   da.delivery_id  = dl.delivery_id
                                      AND   dd.source_code = 'OE'
                                      AND   dd.top_model_line_id = l_line_id;
                                   END IF;

                                   IF l_debug_level  > 0 THEN
                                       oe_debug_pub.add(  'CURRENT LINES DELIVERY ID = '||L_LINE_DELIVERY_ID , 5 ) ;
                                   END IF;
                                ELSE
                                  IF l_line_rec.item_type_code in ('MODEL', 'CLASS', 'KIT') THEN
                                     SELECT min(dl.delivery_id)
                                     INTO l_line_delivery_id
                                     FROM wsh_new_deliveries dl,
                                          wsh_delivery_assignments da,
                                          wsh_delivery_details dd
                                      WHERE dd.delivery_detail_id  = da.delivery_detail_id
                                      AND   da.delivery_id  = dl.delivery_id
                                      AND   dd.source_code = 'OE'
                                      AND   dd.top_model_line_id = l_line_id;
                                 IF l_debug_level  > 0 THEN
                                     oe_debug_pub.add(  'CURRENT LINES DELIVERY ID MODEL , CLASS , KIT = '||L_LINE_DELIVERY_ID , 5 ) ;
                                 END IF;
                                  END IF;
                                END IF;
                           END IF;    
                      -- Bug2181628 Only now Process the line.             
                         IF  ((l_line_id = p_line_id) OR (l_line_delivery_id = l_delivery_line_id)) THEN
                             IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
                                l_interface_line_rec.request_id := -1 * p_line_id;
                             ELSE
                                l_interface_line_rec.request_id := -1 * p_header_id;
                             END IF;
                             generate_invoice_number := 'Y';
                             l_old_interface_status_code := l_line_rec.invoice_interface_status_code;
                             IF Is_PTO(l_line_rec) THEN
                                IF l_debug_level  > 0 THEN
                                    oe_debug_pub.add(  'RFR: PTO IS TRUE - IN DELIVERY HANDLING' , 5 ) ;
                                END IF;
                                IF Something_To_Invoice(l_line_rec) THEN
                                   IF l_debug_level  > 0 THEN
                                       oe_debug_pub.add(  'RFR: SOMETHING_TO_INVOICE IS TRUE , GO AHEAD INTERFACE - IN DELIVERY HANDLING' , 5 ) ;
                                   END IF;
                                   Interface_Single_line(p_line_rec            => l_line_rec
                                         ,p_header_rec          => l_header_rec
                                         ,p_x_interface_line_rec  => l_interface_line_rec
                                         ,x_return_status       => x_return_status
                                         ,x_result_out          => x_result_out);
                                   IF l_debug_level  > 0 THEN
                                      oe_debug_pub.add(  'INTERFACED W/REQUEST_ID : '||L_INTERFACE_LINE_REC.REQUEST_ID , 5 ) ;
                                   -- if this line can only invoice partial, it will become RFR-PENDING while interfacing whatever it can
                                   -- x_result_out should have set appropriately
                                      oe_debug_pub.add(  'AFTER INTERFACE SINGLE LINE , RESULT_OUT IS ' || X_RESULT_OUT ||': And x_return_status:'||x_return_status, 5 ) ;
                                   END IF;
                                   IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                                         RAISE FND_API.G_EXC_ERROR;
                                   ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                                         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                                   ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                                         -- bug# 4090604, if RFR line is fully is fully invoiced or not eligible
                                         IF (x_result_out = OE_GLOBALS.G_WFR_COMPLETE OR x_result_out=OE_GLOBALS.G_WFR_NOT_ELIGIBLE) THEN
                                            IF l_old_interface_status_code = 'MANUAL-PENDING' OR l_old_interface_status_code = 'RFR-PENDING' THEN
                                               IF l_debug_level  > 0 THEN
                                                   oe_debug_pub.add(  'RFR: MANUAL-PENDING + RFR LINE HAS BEEN FULLY INVOICED' , 5 ) ;
                                                   oe_debug_pub.add(  'NOW COMPLETING THE WF BLOCK ACTIVITY' , 5 ) ;
                                               END IF;
                                               WF_ENGINE.CompleteActivityInternalName(OE_GLOBALS.G_WFI_LIN, l_line_rec.line_id, 'INVOICING_WAIT_FOR_RFR', 'COMPLETE');
                                            END IF;
                                         END IF;
                                         IF x_result_out = OE_GLOBALS.G_WFR_PRTL_COMPLETE THEN -- RFR line is partially invoiced
                                            IF l_debug_level  > 0 THEN
                                                oe_debug_pub.add(  'RFR: THIS LINE IS PARTIALLY INVOICED' , 5 ) ;
                                            END IF;
                                         END IF;
                                         -- real invoice_interface_status_code should have updated to right value
                                         -- from interface_single_line already
                                   END IF;
                                ELSE -- PTO in a delivery, but nothing available to invoice, update to RFR-PENDING
                                   IF l_debug_level  > 0 THEN
                                       oe_debug_pub.add(  'RFR: NOTHING AVAILABLE FOR PTO TO INVOICE , UDPATE RFR-PENDING' , 5 ) ;
                                       oe_debug_pub.add(  'l_interface_line_rec.quantity:'|| l_interface_line_rec.quantity||':l_line_rec.invoiced_quantity:'||l_line_rec.invoiced_quantity,5 ) ;
                                   END IF;
                                   l_interface_line_rec.quantity := 0; -- for bug# 4114961, setting the quantity to zero as nothing to invoice
                                   IF l_debug_level  > 0 THEN
                                       oe_debug_pub.add(  'l_interface_line_rec.quantity after resetting:'|| l_interface_line_rec.quantity,5 ) ;
                                   END IF;
                                   Update_Invoice_Attributes(l_line_rec
                                                 ,l_interface_line_rec
                                                 ,'RFR-PENDING'
                                                 ,x_return_status);
				   IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
				      FND_MESSAGE.SET_NAME('ONT','OE_INVOICE_WAIT_FOR_RFR');
                                      OE_MSG_PUB.ADD;
				   END IF;   
                                   IF l_debug_level  > 0 THEN
                                       oe_debug_pub.add(  'RFR: L_LINE_REC.INTERFACE_STATUS '||L_LINE_REC.INVOICE_INTERFACE_STATUS_CODE , 5 ) ;
                                       oe_debug_pub.add(  'RFR: X_RETURN_STATUS :'||X_RETURN_STATUS , 5 ) ;
                                   END IF;
                                   IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                                         x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                                         RAISE FND_API.G_EXC_ERROR;
                                   ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                                         x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                                         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                                   --bug# 4090604
                                   ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                                         x_result_out := OE_GLOBALS.G_WFR_PRTL_COMPLETE;
                                         IF l_debug_level  > 0 THEN
                                            oe_debug_pub.add(  'RFR: LINE ID '||TO_CHAR ( L_LINE_REC.LINE_ID ) ||' PARTIALLY INTERFACED SUCCESSFULLY ' || 'X_RESULT_OUT: '||X_RESULT_OUT) ;
                                         END IF;
                                   END IF; -- check for update_invoice_attribute results
                                END IF; -- check for anything to invoice for this PTO
                             ELSE -- not in a PTO
                                Interface_Single_line(p_line_rec              => l_line_rec
                                                     ,p_header_rec            => l_header_rec
                                                     ,p_x_interface_line_rec  => l_interface_line_rec
                                                     ,x_return_status         => x_return_status
                                                     ,x_result_out            => x_result_out);
                                IF l_debug_level  > 0 THEN
                                    oe_debug_pub.add(  'INTERFACED W/REQUEST_ID : '||L_INTERFACE_LINE_REC.REQUEST_ID , 5 ) ;
                                END IF;
                                IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                                      RAISE FND_API.G_EXC_ERROR;
                                ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                                      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                                ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                                      IF l_debug_level  > 0 THEN
                                          oe_debug_pub.add(  'L_LINE_ID: '||L_LINE_ID||' P_LINE_ID: '||P_LINE_ID|| ' INVOICE_INTERFACE_STATUS_CODE: '||L_LINE_REC.INVOICE_INTERFACE_STATUS_CODE , 5 ) ;
                                      END IF;
                                      IF l_old_interface_status_code = 'MANUAL-PENDING' THEN
                                         IF l_debug_level  > 0 THEN
                                             oe_debug_pub.add(  'MANUAL-PENDING LINE HAS BEEN INVOICED' , 5 ) ;
                                             oe_debug_pub.add(  'NOW COMPLETING THE WF BLOCK ACTIVITY' , 5 ) ;
                                         END IF;
                                         WF_ENGINE.CompleteActivityInternalName(OE_GLOBALS.G_WFI_LIN, l_line_rec.line_id, 'INVOICING_WAIT_FOR_RFR', 'COMPLETE');
                                      END IF;
                                END IF; -- check for interface_single_line result
                             END IF; -- check for PTO
                         END IF; -- Bug2181628.Process the line.
                        END IF;
                       END IF; -- line has not been interface yet
                       --bug# 4090604
                       IF  l_line_id = p_line_id THEN
                           delivery_line_processed := 'Y';
                           current_line_return_status := x_return_status;
                           current_line_result_out := x_result_out;
                           IF l_debug_level  > 0 THEN
                              oe_debug_pub.add(  'Current line status:'||current_line_return_status||': Current line result_out:'||current_line_result_out);
                           END IF;
                       END IF;
                    END LOOP;
                    CLOSE delivery_lines_cursor;
                    -- Setting the current line status correctly. This is 
                    -- required if the current line is not processed at the end
                    --bug# 4090604
                    IF delivery_line_processed = 'Y' THEN
                       IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  'Setting the current line status correctly.'||current_line_return_status||':'||current_line_result_out);
                       END IF;
                       x_return_status := current_line_return_status;
                       x_result_out := current_line_result_out;
                    END IF;
                    interface_this_line := 'N';
              END IF; -- are delivery lines ready?
          ELSE -- delivery_id is null
                 interface_this_line := 'Y';
                 generate_invoice_number := 'N';
                 IF l_debug_level  > 0 THEN
                     oe_debug_pub.add(  'DELIVERY ID IS NULL' , 5 ) ;
                 END IF;
          END IF; -- delivery id
        END IF;  --shipping info avaialable
     ELSE  -- automatic invoice numbering
        interface_this_line := 'Y';
        generate_invoice_number := 'N';
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'AUTOMATIC INVOICE NUMBERING' , 5 ) ;
        END IF;
     END IF;
     IF interface_this_line = 'Y' THEN -- for automatic invoice numbering
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'INTERFACING LINE ID : '||L_LINE_REC.LINE_ID , 5 ) ;
        END IF;
        IF generate_invoice_number = 'Y' THEN
           IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
              l_interface_line_rec.request_id := -1 * p_line_id;
           ELSE
              l_interface_line_rec.request_id := -1 * p_header_id;
           END IF;
           IF l_debug_level  > 0 THEN
               oe_debug_pub.add(  'SETTING REQUEST_ID' || L_INTERFACE_LINE_REC.REQUEST_ID , 5 ) ;
           END IF;
        END IF;
        -- Retrobilling:          
        -- For RMAs that reference a retrobilled order line
        -- We might need to create multiple credit memos
        IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510'
           and Oe_Retrobill_Pvt.retrobill_enabled
           and Return_Line(l_line_rec)
           and l_line_rec.reference_line_id IS NOT NULL
        THEN
          --dbms_output.put_line('inside retrobill rma');
          Oe_Retrobill_Pvt.Interface_Retrobilled_RMA(p_line_rec          => l_line_rec
                                                    ,p_header_rec        => l_header_rec
                                                    ,x_Return_status     => x_return_status
                                                    , x_result_out       => x_result_out);
        ELSE
        Interface_Single_line(p_line_rec              => l_line_rec
                             ,p_header_rec            => l_header_rec
                             ,p_x_interface_line_rec  => l_interface_line_rec
                             ,x_return_status         => x_return_status
                             ,x_result_out            => x_result_out);
        END IF;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'INTERFACED W/REQUEST_ID : '||L_INTERFACE_LINE_REC.REQUEST_ID || ' X_RETURN_STATUS: '|| X_RETURN_STATUS , 5 ) ;
        END IF;
        IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
              RAISE FND_API.G_EXC_ERROR;
        ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
        -- if this line is RFR and there are lines waiting for it, interface those lines
        IF Is_PTO(l_line_rec) THEN
           IF Is_RFR(l_line_rec.line_id) THEN
              IF l_debug_level  > 0 THEN
                  oe_debug_pub.add(  'RFR: THIS LINE ITSELF IS RFR' , 5 ) ;
              END IF;
              Open Pending_Lines;
              LOOP
                    Fetch Pending_Lines Into l_pending_line_id;
                    IF l_debug_level  > 0 THEN
                        oe_debug_pub.add(  'RFR: PENDING LINE ID ' || TO_CHAR ( L_PENDING_LINE_ID ) , 5 ) ;
                    END IF;
                    EXIT WHEN Pending_Lines%NOTFOUND;
                    OE_Line_Util.Query_Row(p_line_id=>l_pending_line_id, x_line_rec=>l_pending_line_rec);
                    IF Something_To_Invoice(l_pending_line_rec) THEN -- the pending line now has something to
                                                                     -- invoice because current line has been shipped
                       -- check for delivery and invoice delivery if necessarily
                       IF l_debug_level  > 0 THEN
                           oe_debug_pub.add(  'RFR: LINE IS RFR AND DELIVERY INVOICING' , 5 ) ;
                       END IF;
                       Interface_Single_line(p_line_rec            => l_pending_line_rec
                                         ,p_header_rec          => l_header_rec
                                         ,p_x_interface_line_rec  => l_interface_line_rec
                                         ,x_return_status       => x_return_status
                                         ,x_result_out          => x_result_out);
                       IF l_debug_level  > 0 THEN
                           oe_debug_pub.add(  'RFR: INTERFACE RFR-PENDING LINE , ID: ' || L_PENDING_LINE_REC.LINE_ID , 5 ) ;
                       END IF;
                       IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                             RAISE FND_API.G_EXC_ERROR;
                       ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                       ELSIF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                             IF x_result_out = OE_GLOBALS.G_WFR_PRTL_COMPLETE THEN
                                IF l_debug_level  > 0 THEN
                                    oe_debug_pub.add(  'RFR: RFR-PENDING LINE PARTIALLY INTERFACED' , 5 ) ;
                                END IF;
                             ELSE --x_result_out = OE_GLOBALS.G_WFR_COMPLETE THEN
                                IF l_debug_level  > 0 THEN
                                    oe_debug_pub.add(  'RFR: RFR-PENDING LINE INTERFACED SUCCESSFULLY , COMPLETING BLOCK' , 5 ) ;
                                END IF;
                                WF_ENGINE.CompleteActivityInternalName(OE_GLOBALS.G_WFI_LIN, l_pending_line_rec.line_id, 'INVOICING_WAIT_FOR_RFR', 'COMPLETE');
                          END IF;
                       END IF;
                    END IF;
                END LOOP;
                -- run for the pending lines just interfaced
                IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                   IF x_result_out = OE_GLOBALS.G_WFR_COMPLETE  OR x_result_out = OE_GLOBALS.G_WFR_NOT_ELIGIBLE THEN
                      IF generate_invoice_number  = 'Y' THEN
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'RFR:LINE ID '||TO_CHAR ( L_LINE_REC.LINE_ID ) ||' INTERFACED SUCCESSFULLY' , 5 ) ;
                             oe_debug_pub.add(  'RFR: CALLING UPDATE_NUMBERS' , 5 ) ;
                         END IF;
                         IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
                            Update_Numbers(p_line_id, x_return_status);
                         ELSE
                            Update_Numbers(p_header_id, x_return_status);
                         END IF;
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'RFR: RETURN STATUS : '||X_RETURN_STATUS , 5 ) ;
                         END IF;
                         IF x_return_status = FND_API.G_RET_STS_ERROR THEN
                               x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                               RAISE FND_API.G_EXC_ERROR;
                         ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                               x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                               RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                         ELSE
                               x_result_out := OE_GLOBALS.G_WFR_COMPLETE;
                               IF l_debug_level  > 0 THEN
                                   oe_debug_pub.add(  'RFR: UPDATE NUMBER DONE FOR RFR-PENDING LINE ( CURRENT LINE IS RFR ) ' , 5 ) ;
                               END IF;
                         END IF;
                      ELSE
                         IF l_debug_level  > 0 THEN
                             oe_debug_pub.add(  'RFR:LINE ID '||TO_CHAR ( L_LINE_REC.LINE_ID ) ||' INTERFACED SUCCESSFULLY' , 5 ) ;
                             oe_debug_pub.add(  'RFR:W/AUTOMATIC NUMBERING' , 5 ) ;
                         END IF;
                      END IF;
                   END IF;
                END IF;
                close Pending_Lines;
         END IF; -- itself is a RFR line
      END IF; -- PTO line
    END IF; -- if interface_this_line is Y
    IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
       IF x_result_out = OE_GLOBALS.G_WFR_COMPLETE  OR x_result_out = OE_GLOBALS.G_WFR_NOT_ELIGIBLE THEN
          IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
             IF generate_invoice_number  = 'Y' THEN
                IF l_debug_level  > 0 THEN
                    oe_debug_pub.add(  'LINE ID '||TO_CHAR ( L_LINE_REC.LINE_ID ) ||' INTERFACED SUCCESSFULLY' , 2 ) ;
                    oe_debug_pub.add(  'CALLING UPDATE_NUMBERS' ) ;
                END IF;
                IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
                   Update_Numbers(p_line_id, x_return_status);
                ELSE
                   Update_Numbers(p_header_id, x_return_status);
                END IF;
                IF l_debug_level  > 0 THEN
                    oe_debug_pub.add(  'RETURN STATUS : '||X_RETURN_STATUS , 5 ) ;
                END IF;
                IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
                      x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                      RAISE FND_API.G_EXC_ERROR;
                ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
                      x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
                      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
                ELSE
                      x_result_out := OE_GLOBALS.G_WFR_COMPLETE;
                      IF l_debug_level  > 0 THEN
                          oe_debug_pub.add(  'EXITING INTERFACE_LINE' , 5 ) ;
                      END IF;
                      RETURN;
             END IF;
           ELSE
             IF l_debug_level  > 0 THEN
                 oe_debug_pub.add(  'LINE ID '||TO_CHAR ( L_LINE_REC.LINE_ID ) ||' INTERFACED SUCCESSFULLY' , 5 ) ;
                 oe_debug_pub.add(  'W/AUTOMATIC NUMBERING' , 2 ) ;
             END IF;
             RETURN;
           END IF;
         END IF;
      END IF;
    END IF;
EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXPECTED ERROR. EXIT LINE INVOICING : '||SQLERRM , 1 ) ;
         END IF;
         IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
           ROLLBACK TO INVOICE_INTERFACE;
         END IF;
	 
	 IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
  	    IF x_result_out = OE_GLOBALS.G_WFR_ON_HOLD Then
	       l_flow_status_code := 'INVOICE_HOLD';
	    ELSIF x_result_out = OE_GLOBALS.G_WFR_INCOMPLETE THEN
	       l_flow_status_code := 'INVOICE_INCOMPLETE';
	    END IF;
	    Update_line_flow_status(l_line_rec.line_id,l_flow_status_code);
         END IF;
	 
         OE_MSG_PUB.Count_And_Get
                (   p_count     =>      x_msg_count
                ,   p_data      =>      x_msg_data
                );
         x_return_status := FND_API.G_RET_STS_ERROR;
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'UNEXPECTED ERROR. EXITING FROM LINE INVOICING : '||SQLERRM , 1 ) ;
         END IF;
         IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
           ROLLBACK TO INVOICE_INTERFACE;
         END IF;
         OE_MSG_PUB.Count_And_Get
                (   p_count     =>      x_msg_count
                ,   p_data      =>      x_msg_data
                );
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    WHEN OTHERS THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXCEPTION , OTHERS. EXITING FROM LINE INVOICING : '||SQLERRM , 1 ) ;
         END IF;
         IF (delivery_lines_cursor%ISOPEN) THEN
            CLOSE delivery_lines_cursor;
         END IF;
         IF (Pending_Lines%ISOPEN) THEN
            CLOSE Pending_Lines;
         END IF;
         IF p_itemtype = OE_GLOBALS.G_WFI_LIN THEN
           ROLLBACK TO INVOICE_INTERFACE;
         END IF;
         IF      FND_MSG_PUB.Check_Msg_Level
                (FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
         THEN
                OE_MSG_PUB.Add_Exc_Msg
                        (   G_PKG_NAME
                        ,   'Interface_Line'
                        );
         END IF;
         OE_MSG_PUB.Count_And_Get
                (   p_count     =>      x_msg_count
                ,   p_data      =>      x_msg_data
         );
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
END Interface_Line;

PROCEDURE Interface_Header
(   p_header_id     IN   NUMBER
,   p_itemtype      IN   VARCHAR2
,   x_result_out    OUT  NOCOPY VARCHAR2
,   x_return_status OUT  NOCOPY VARCHAR2
) IS
x_msg_count             NUMBER;
x_msg_data              VARCHAR2(240);
l_return_status         VARCHAR2(30);
l_result_out            VARCHAR2(30);
l_flow_status_code      VARCHAR2(30);
CURSOR order_line_cursor IS
     SELECT ol.line_id
     FROM   oe_order_lines ol
     WHERE  ol.header_id = p_header_id
     AND    ol.open_flag = 'Y';
l_line_id   NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'ENTER INTERFACE_HEADER ( ) PROCEDURE' , 5 ) ;
    END IF;
    SAVEPOINT HEADER_INVOICE_INTERFACE;
    -- Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

 -- Header_Invoicing_Validation
    OPEN order_line_cursor;
    LOOP
       FETCH order_line_cursor INTO l_line_id;
       EXIT WHEN order_line_cursor%NOTFOUND;
       IF l_debug_level  > 0 THEN
           oe_debug_pub.add(  'PROCESSING LINE_ID: '||L_LINE_ID , 5 ) ;
       END IF;
       Interface_Line(l_line_id, p_itemtype, l_result_out, l_return_status);
       IF l_return_status = FND_API.G_RET_STS_ERROR THEN
          IF l_result_out =  OE_GLOBALS.G_WFR_ON_HOLD THEN
             x_result_out := OE_GLOBALS.G_WFR_ON_HOLD;
          ELSIF l_result_out = OE_GLOBALS.G_WFR_INCOMPLETE THEN
             x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          END IF;
          RAISE FND_API.G_EXC_ERROR;
       ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
       ELSE
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'CONTINUE WITH NEXT LINE IF THIS IS NOT LAST ONE' , 5 ) ;
          END IF;
       END IF;
    END LOOP;
    CLOSE order_line_cursor;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'CALL UPDATE_NUMBERS FOR HEADER LEVEL INVOICING' , 5 ) ;
    END IF;
    Update_Numbers(p_header_id, x_return_status);
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'RETURN STATUS : '||X_RETURN_STATUS , 5 ) ;
    END IF;
    IF    x_return_status = FND_API.G_RET_STS_ERROR THEN
          x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
          RAISE FND_API.G_EXC_ERROR;
    ELSIF x_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    ELSE
          x_return_status := FND_API.G_RET_STS_SUCCESS;
          x_result_out := OE_GLOBALS.G_WFR_COMPLETE;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'EXIT INTERFACE_LINE ( ) PROCEDURE' , 5 ) ;
          END IF;
    END IF;
    
    IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
       l_flow_status_code := 'INVOICED';
       Update_header_flow_status(p_header_id,l_flow_status_code);
    END IF;
    
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'EXITING INTERFACE_HEADER ( ) PROCEDURE' , 5 ) ;
    END IF;

EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
         IF l_debug_level  > 0 THEN
             oe_debug_pub.add(  'EXPECTED ERROR. EXIT FROM HEADER INVOICING' , 5 ) ;
         END IF;
         IF (order_line_cursor%ISOPEN) THEN
            CLOSE order_line_cursor;
         END IF;
         ROLLBACK TO HEADER_INVOICE_INTERFACE;
	 
	 IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
	    IF x_result_out = OE_GLOBALS.G_WFR_ON_HOLD Then
	       l_flow_status_code := 'INVOICE_HOLD';
	    ELSIF x_result_out = OE_GLOBALS.G_WFR_INCOMPLETE THEN
	       l_flow_status_code := 'INVOICE_INCOMPLETE';
	    END IF; 
	    Update_header_flow_status(p_header_id,l_flow_status_code);
         END IF;
	 
         OE_MSG_PUB.Count_And_Get
                (   p_count     =>      x_msg_count
                ,   p_data      =>      x_msg_data
                );
         x_return_status := FND_API.G_RET_STS_ERROR;
    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
     	 IF l_debug_level  > 0 THEN
     	     oe_debug_pub.add(  'UNEXPECTED ERROR. EXITING FROM HEADER INVOICING' , 5 ) ;
     	 END IF;
         IF (order_line_cursor%ISOPEN) THEN
               CLOSE order_line_cursor;
         END IF;
         ROLLBACK TO HEADER_INVOICE_INTERFACE;
         OE_MSG_PUB.Count_And_Get
                (   p_count     =>      x_msg_count
                ,   p_data      =>      x_msg_data
                );
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;
    WHEN OTHERS THEN
     	 IF l_debug_level  > 0 THEN
     	     oe_debug_pub.add(  'EXCEPTION OTHERS. EXIT FROM HEADER INVOICING' , 5 ) ;
     	 END IF;
         IF (order_line_cursor%ISOPEN) THEN
            CLOSE order_line_cursor;
         END IF;
         ROLLBACK TO HEADER_INVOICE_INTERFACE;
         IF OE_MSG_PUB.Check_Msg_Level
                  (OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR)
         THEN
             OE_MSG_PUB.Add_Exc_Msg
                    ( G_PKG_NAME
                    , 'Interface_Header'
                    );
         END IF;
         OE_MSG_PUB.Count_And_Get
                (   p_count     =>      x_msg_count
                ,   p_data      =>      x_msg_data
                );
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         x_result_out := OE_GLOBALS.G_WFR_INCOMPLETE;

END Interface_Header;
Procedure Any_Line_ARInterfaced( p_application_id               IN NUMBER,
                                 p_entity_short_name            in VARCHAR2,
                                 p_validation_entity_short_name in VARCHAR2,
                                 p_validation_tmplt_short_name  in VARCHAR2,
                                 p_record_set_tmplt_short_name  in VARCHAR2,
                                 p_scope                        in VARCHAR2,
                                 p_result                       OUT NOCOPY NUMBER ) IS

l_header_id NUMBER ;
any_line_interfaced NUMBER := 0;
-- 3740077
line_payment_not_exists NUMBER :=0;
-- 3740077

BEGIN

   IF    p_validation_entity_short_name = 'HEADER_SCREDIT' THEN
         l_header_id := oe_header_scredit_security.g_record.header_id;
   ELSIF p_validation_entity_short_name = 'HEADER_ADJ' THEN
      l_header_id := oe_header_adj_security.g_record.header_id;
   ELSIF p_validation_entity_short_name = 'HEADER_PAYMENT' THEN
      l_header_id := oe_header_payment_security.g_record.header_id;
  END IF;
   
   IF l_header_id IS NULL OR
      l_header_id = FND_API.G_MISS_NUM
   THEN
      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);
      p_result := 0;
   END IF;

-- 3740077 Added the If
IF  p_validation_entity_short_name = 'HEADER_PAYMENT' THEN
  IF (nvl(oe_header_payment_security.g_record.payment_collection_event,'PREPAY')='INVOICE' and
     oe_header_payment_security.g_record.line_id is NULL) THEN

    BEGIN
     SELECT 1
     INTO  line_payment_not_exists  
     FROM  OE_ORDER_LINES L
     WHERE HEADER_ID = l_header_id
     AND   invoice_interface_status_code = 'YES'
     AND   NOT EXISTS
     (select 'x' from oe_payments
       WHERE header_id = l_header_id
       AND   line_id = L.line_id 
       AND   payment_type_code <> 'COMMITMENT'
     )
    AND ROWNUM=1;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_result := 0;
   END;
   
   IF line_payment_not_exists = 1 THEN
      p_result := 1;
      oe_debug_pub.add('skubendr going in');
   ELSE
      p_result := 0;
   END IF; 
 ELSE
   -- this is a prepayment.
   p_result := 0;
 END IF;
ELSE
   BEGIN
     SELECT 1
     INTO  any_line_interfaced
     FROM  OE_ORDER_LINES
     WHERE HEADER_ID = l_header_id
     AND   invoice_interface_status_code = 'YES'
     AND   ROWNUM = 1;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
           any_line_interfaced := 0;
   END;
   IF any_line_interfaced = 1 THEN
      p_result := 1;
   ELSE
      p_result := 0;
   END IF;
END IF;
END Any_Line_ARInterfaced;

Procedure All_Lines_ARInterfaced( p_application_id               IN NUMBER,
                                  p_entity_short_name            in VARCHAR2,
                                  p_validation_entity_short_name in VARCHAR2,
                                  p_validation_tmplt_short_name  in VARCHAR2,
                                  p_record_set_tmplt_short_name  in VARCHAR2,
                                  p_scope                        in VARCHAR2,
                                  p_result                       OUT NOCOPY NUMBER ) IS

l_header_id             NUMBER ;
any_line_not_interfaced NUMBER := 0;
l_lines_exist           NUMBER := 0;
BEGIN
   IF    p_validation_entity_short_name = 'HEADER_SCREDIT' THEN
         l_header_id := oe_header_scredit_security.g_record.header_id;
   ELSIF p_validation_entity_short_name = 'HEADER_ADJ' THEN
         l_header_id := oe_header_adj_security.g_record.header_id;
   -- 3740077
   ELSIF p_validation_entity_short_name = 'HEADER_PAYMENT' THEN
         l_header_id := oe_header_payment_security.g_record.header_id; 
   ELSIF p_validation_entity_short_name = 'LINE_PAYMENT' THEN
         l_header_id := oe_line_payment_security.g_record.header_id;
   -- 3740077 
   END IF;

   IF l_header_id IS NULL OR
      l_header_id = FND_API.G_MISS_NUM
   THEN
      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);
      p_result := 0;
   END IF;

   IF l_header_id is not null and
      l_header_id <> FND_API.G_MISS_NUM THEN

      BEGIN
         select 1 into l_lines_exist
         from oe_order_lines
         where header_id = l_header_id
         and rownum = 1;
 
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           l_lines_exist := 0;
           p_result := 0;
           any_line_not_interfaced := 1;
      END;

   END IF;

   IF l_lines_exist = 1 THEN

      BEGIN
        SELECT 1
        INTO   any_line_not_interfaced
        FROM   OE_ORDER_LINES
        WHERE  HEADER_ID = l_header_id
        AND    NVL(invoice_interface_status_code, 'NO') in ('NO', 'MANUAL-PENDING', 'RFR-PENDING')
        AND    open_flag = 'Y'
        AND    ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           any_line_not_interfaced := 0;
      END;

   END IF; -- if l_lines_exist = 1

   IF any_line_not_interfaced = 1 THEN
      p_result := 0;
   ELSE
      p_result := 1;
   END IF;

END All_Lines_ARInterfaced;


Procedure This_Line_ARInterfaced( p_application_id               IN NUMBER,
                                 p_entity_short_name            in VARCHAR2,
                                 p_validation_entity_short_name in VARCHAR2,
                                 p_validation_tmplt_short_name  in VARCHAR2,
                                 p_record_set_tmplt_short_name  in VARCHAR2,
                                 p_scope                        in VARCHAR2,
                                 p_result                       OUT NOCOPY NUMBER ) IS

l_line_id NUMBER ;
this_line_interfaced NUMBER := 0;
BEGIN

   oe_debug_pub.add(' Entering This_Line_ARInterfaced');
   l_line_id := OE_LINE_SECURITY.g_record.line_id;

   IF p_validation_entity_short_name = 'LINE_PAYMENT' THEN
      l_line_id := oe_line_payment_security.g_record.line_id;
   END IF;

     oe_debug_pub.add(' Line Id :'||l_line_id);

   IF l_line_id IS NULL OR
      l_line_id = FND_API.G_MISS_NUM
   THEN
      OE_MSG_PUB.Update_Msg_Context(p_attribute_code => null);
      p_result := 0;
   END IF;

   BEGIN
     SELECT 1
     INTO  this_line_interfaced
     FROM  OE_ORDER_LINES
     WHERE LINE_ID = l_line_id
     AND   invoice_interface_status_code = 'YES';

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
           this_line_interfaced := 0;
   END;
   IF this_line_interfaced = 1 THEN
      p_result := 1;
   ELSE
      p_result := 0;
   END IF;
END This_Line_ARInterfaced;



END OE_Invoice_PUB;
/

--SHOW ERRORS PACKAGE BODY OE_Invoice_PUB;
COMMIT;
EXIT;
