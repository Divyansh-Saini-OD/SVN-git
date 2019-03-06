--  
--  Copyright (c) 2002 Oracle Corporation, Redwood Shores, CA, USA
--  All rights reserved.
--  
--  FILENAME
--  
--      OEBSVATB.pls
--  
--  DESCRIPTION
--  
--      Body of package OE_BULK_VALIDATE
--  
--  NOTES
--
--      This is the attribute validation API used for bulk
--      order import.
--
--
--  HISTORY
--  
--  30-Apr-02 Created        Nithya Lakshmanan
--  

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile:~PROD:~PATH:~FILE

CREATE OR REPLACE PACKAGE BODY OE_BULK_VALIDATE AS
/* $Header: OEBSVATB.pls 115.13.11510.12 2007/05/22 06:14:36 smmathew ship $ */


G_PKG_NAME         CONSTANT     VARCHAR2(30):='OE_BULK_VALIDATE';

---------------------------------------------------------------------
-- PROCEDURE Pre_Process
--
-- This API does all the order import pre-processing validations on
-- the interface tables for orders in this batch.
-- It will insert error messages for all validation failures.
---------------------------------------------------------------------

PROCEDURE Pre_Process(p_batch_id  IN NUMBER)
AS
l_msg_text                  VARCHAR2(2000);
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_BULK_REQD_HDR_ATTRIBUTES');
  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login 
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language 
     ,message_text, transaction_id
    )
  SELECT
     request_id ,'HEADER' ,NULL ,NULL ,NULL ,NULL 
     ,order_source_id ,orig_sys_document_ref
     ,NULL, NULL ,change_sequence
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate 
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL 
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text, OE_MSG_ID_S.NEXTVAL 
  FROM OE_HEADERS_IFACE_ALL
  WHERE batch_id = p_batch_id
    AND (order_source_id IS NULL OR orig_sys_document_ref IS NULL);

  IF g_error_count = 0 THEN
     IF SQL%ROWCOUNT > 0 THEN
        g_error_count := 1;
        IF l_debug_level  > 0 THEN
            oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
        END IF;
     END IF;
  END IF;

  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_OI_OPERATION_CODE');
  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login 
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language 
     ,message_text, transaction_id
    )
  SELECT
     request_id ,'HEADER' ,NULL ,NULL ,NULL ,NULL 
     ,order_source_id ,orig_sys_document_ref
     ,NULL, NULL ,change_sequence
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate 
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL 
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text, OE_MSG_ID_S.NEXTVAL 
  FROM OE_HEADERS_IFACE_ALL h
  WHERE batch_id = p_batch_id
    AND EXISTS (SELECT 'Y'
                FROM OE_ORDER_HEADERS oh
                WHERE oh.order_source_id       = h.order_source_id
                  AND oh.orig_sys_document_ref = h.orig_sys_document_ref
                );

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

-- comment out with config support change
/* 
  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_BULK_NOT_SUPP_HDR_ATTRIBS');
  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login 
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language 
     ,message_text, transaction_id
    )
  SELECT
     h.request_id ,'HEADER' ,NULL ,NULL ,NULL ,NULL 
     ,order_source_id ,orig_sys_document_ref
     ,NULL, NULL ,change_sequence
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate 
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL 
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text, OE_MSG_ID_S.NEXTVAL 
  FROM OE_HEADERS_IFACE_ALL h
  WHERE h.batch_id = p_batch_id
    AND ( h.payment_type_code = 'CREDIT_CARD'
         OR h.order_source_id = 10 -- 'Internal' Orders
         OR h.customer_preference_set_code IS NOT NULL  -- Value here requires lines to be in sets!
         OR h.return_reason_code IS NOT NULL -- for RETURN orders
         -- Bug 3355762
         -- Import of closed orders is not supported with HVOP
         OR h.closed_flag = 'Y'
         );

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
*/


  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_OI_ORIG_SYS_LINE_REF');
  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login 
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language 
     ,message_text, transaction_id
    )
  SELECT
     h.request_id ,'LINE' ,NULL ,NULL ,NULL ,NULL 
     ,l.order_source_id ,l.orig_sys_document_ref
     ,l.orig_sys_line_ref, l.orig_sys_shipment_ref, l.change_sequence
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate 
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL 
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text, OE_MSG_ID_S.NEXTVAL 
  FROM OE_HEADERS_IFACE_ALL h, OE_LINES_IFACE_ALL l
  WHERE h.batch_id = p_batch_id
    AND h.order_source_id = l.order_source_id
    AND h.orig_sys_document_ref = l.orig_sys_document_ref
    AND l.orig_sys_line_ref IS NULL 
    AND l.orig_sys_shipment_ref IS NULL;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

-- comment out with config support change
/*
  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_BULK_NOT_SUPP_LINE_ATTRIBS');
  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login 
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language 
     ,message_text, transaction_id
    )
  SELECT
     h.request_id ,'LINE' ,NULL ,NULL ,NULL ,NULL 
     ,l.order_source_id ,l.orig_sys_document_ref
     ,l.orig_sys_line_ref, l.orig_sys_shipment_ref, l.change_sequence
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate 
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL 
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text, OE_MSG_ID_S.NEXTVAL 
  FROM OE_HEADERS_IFACE_ALL h, OE_LINES_IFACE_ALL l
  WHERE h.batch_id = p_batch_id
    AND h.order_source_id = l.order_source_id
    AND h.orig_sys_document_ref = l.orig_sys_document_ref
    AND ( nvl(l.source_type_code,'INTERNAL') <> 'INTERNAL' -- Drop ships
         OR (l.arrival_set_name IS NOT NULL OR l.ship_set_name IS NOT NULL)
         OR l.commitment_id IS NOT NULL
         OR l.return_reason_code IS NOT NULL -- for RETURN lines 
         OR l.override_atp_date_code IS NOT NULL
         );

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
*/


  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_OI_ORIG_SYS_DISCOUNT_REF');
  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login 
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language 
     ,message_text, transaction_id
    )
  SELECT
     h.request_id ,decode(l.orig_sys_line_ref||l.orig_sys_shipment_ref,NULL,'HEADER_ADJ','LINE_ADJ')
     ,NULL ,NULL ,NULL ,NULL 
     ,l.order_source_id ,l.orig_sys_document_ref
     ,l.orig_sys_line_ref, l.orig_sys_shipment_ref, l.change_sequence
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate 
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL 
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text, OE_MSG_ID_S.NEXTVAL 
  FROM OE_HEADERS_IFACE_ALL h, OE_PRICE_ADJS_INTERFACE l
  WHERE h.batch_id = p_batch_id
    AND h.order_source_id = l.order_source_id
    AND h.orig_sys_document_ref = l.orig_sys_document_ref
    AND l.orig_sys_discount_ref IS NULL;
 
    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'EXIT PRE_PROCESS , G_ERROR_COUNT: '||G_ERROR_COUNT ) ;
  END IF;
EXCEPTION
    WHEN OTHERS THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OTHERS ERROR , PRE_PROCESS' ) ;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
    END IF;
    OE_BULK_MSG_PUB.ADD_Exc_Msg
      (   G_PKG_NAME
      ,   'Pre_Process'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Pre_Process;


---------------------------------------------------------------------
-- PROCEDURE Attributes
--
-- This API does all attribute validations on interface tables for
-- orders in this batch.
-- It will insert error messages for all validation failures.
---------------------------------------------------------------------

PROCEDURE Attributes
           (p_batch_id            IN NUMBER 
           ,p_adjustments_exist   IN VARCHAR2 DEFAULT 'N')
IS
l_msg_text      VARCHAR2(2000);
l_msg_data      VARCHAR2(2000);
l_count NUMBER;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN

   -- Also, include calculate price attribute validation

   -- Validations for following fields NOT NEEDED!
   -- 
   -- 1.These will be covered in Entity Validations:
   -- Agreement, Ship From, Ship To Org, Invoice To Org, Deliver To Org
   -- Sold To Contact, Ship To Contact, Invoice To Contact, Deliver To Contact
   -- Order Type, Line Type, Tax Exempt Reason, Tax Exempt Number
   -- Project
   -- 
   -- 2. These are internal fields and cannot be passed by the user:
   -- Open Flag, Booked Flag, Cancelled Flag,Fulfilled Flag, Flow Status
   -- Shipping Interfaced Flag, Shippable Flag, Item Type Code
   --
   -- 3. Values in following fields not supported in BULK mode:
   -- Source Type: can only be 'INTERNAL'
   -- Return Reason Code, Return Desc Flex: RETURNS not supported
   -- Tax Point: unused
   -- Commitment: not supported
   -- Credit Card Code: IPayment not supported
   -- Source Document Type: orders entered only via order import,
   -- cannot have a source document type.
   --


   l_msg_data := FND_MESSAGE.GET_STRING('ONT','OE_BULK_INVALID_ATTRIBUTE');

   -------------------------------------------------------------------
   -- Attribute Validations for Headers and Lines
   -------------------------------------------------------------------

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('ACCOUNTING_RULE_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'ACCOUNTING_RULE_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.accounting_rule_id IS NOT NULL and
    NOT EXISTS (SELECT RULE_ID
    FROM    OE_RA_RULES_V
    WHERE   RULE_ID = b.accounting_rule_id
    AND     STATUS = 'A'
    AND     TYPE in ('A', 'ACC_DUR','PP_DR_ALL','PP_DR_PP'))--bug6004166
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'ACCOUNTING_RULE_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.accounting_rule_id IS NOT NULL and
    NOT EXISTS (SELECT RULE_ID
    FROM    OE_RA_RULES_V
    WHERE   RULE_ID = b.accounting_rule_id
    AND     STATUS = 'A'
    AND     TYPE in ('A', 'ACC_DUR','PP_DR_ALL','PP_DR_PP'));--bug6004166

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('CONVERSION_TYPE_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id , 'HEADER' ,NULL ,NULL ,NULL ,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL ,NULL
     ,change_sequence ,NULL ,NULL ,NULL ,'CONVERSION_TYPE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.CONVERSION_TYPE_CODE IS NOT NULL and
    NOT EXISTS (SELECT CONVERSION_TYPE
           FROM OE_GL_DAILY_CONVERSION_TYPES_V a
           WHERE CONVERSION_TYPE = b.CONVERSION_TYPE_CODE);

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('DEMAND_CLASS_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'DEMAND_CLASS_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.demand_class_code IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
            FROM    OE_FND_COMMON_LOOKUPS_V a
    WHERE   LOOKUP_CODE = b.demand_class_code
    AND     LOOKUP_TYPE = 'DEMAND_CLASS'
    AND     APPLICATION_ID = 700
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'DEMAND_CLASS_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.demand_class_code IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
            FROM    OE_FND_COMMON_LOOKUPS_V a
    WHERE   LOOKUP_CODE = b.demand_class_code
    AND     LOOKUP_TYPE = 'DEMAND_CLASS'
    AND     APPLICATION_ID = 700
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('FOB_POINT_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'FOB_POINT'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.fob_point_code IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
    FROM    OE_AR_LOOKUPS_V
    WHERE   LOOKUP_CODE = b.fob_point_code
    AND     LOOKUP_TYPE = 'FOB'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    

   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'FOB_POINT_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.fob_point_code IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
    FROM    OE_AR_LOOKUPS_V
    WHERE   LOOKUP_CODE = b.fob_point_code
    AND     LOOKUP_TYPE = 'FOB'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('FREIGHT_TERMS_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'FREIGHT_TERMS_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.freight_terms_code IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
    FROM    OE_LOOKUPS
    WHERE   LOOKUP_CODE = b.freight_terms_code
    AND     LOOKUP_TYPE = 'FREIGHT_TERMS'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'FREIGHT_TERMS_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.freight_terms_code IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
    FROM    OE_LOOKUPS
    WHERE   LOOKUP_CODE = b.freight_terms_code
    AND     LOOKUP_TYPE = 'FREIGHT_TERMS'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('INVOICING_RULE_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'INVOICING_RULE_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.invoicing_rule_id IS NOT NULL and
    NOT EXISTS (SELECT RULE_ID
    FROM    OE_RA_RULES_V
    WHERE   RULE_ID = b.invoicing_rule_id
    AND     STATUS = 'A'
    AND     TYPE = 'I')
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'INVOICING_RULE_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.invoicing_rule_id IS NOT NULL and
    NOT EXISTS (SELECT RULE_ID
    FROM    OE_RA_RULES_V
    WHERE   RULE_ID = b.invoicing_rule_id
    AND     STATUS = 'A'
    AND     TYPE = 'I');

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('ORDER_DATE_TYPE_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id , 'HEADER' ,NULL ,NULL ,NULL ,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL ,NULL
     ,change_sequence ,NULL ,NULL ,NULL ,'ORDER_DATE_TYPE_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id
      AND b.order_date_type_code IS NOT NULL
      AND NOT EXISTS (SELECT LOOKUP_CODE
           FROM OE_LOOKUPS a
           WHERE LOOKUP_TYPE = 'REQUEST_DATE_TYPE'
             AND LOOKUP_CODE = b.order_date_type_code
             AND ENABLED_FLAG = 'Y'
             AND SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('PAYMENT_TERM_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'PAYMENT_TERM_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.payment_term_id IS NOT NULL and
    NOT EXISTS (select a.TERM_ID 
    FROM    OE_RA_TERMS_V a
    WHERE   TERM_ID = b.payment_term_id
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'PAYMENT_TERM_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.payment_term_id IS NOT NULL and
    NOT EXISTS (select a.TERM_ID 
    FROM    OE_RA_TERMS_V a
    WHERE   TERM_ID = b.payment_term_id
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('PRICE_LIST_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'PRICE_LIST_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.price_list_id IS NOT NULL and
    NOT EXISTS (select list_header_id 
    FROM    qp_list_headers_vl
    WHERE   list_header_id = b.price_list_id
    and list_type_code in ('PRL', 'AGR') and
    nvl(active_flag,'Y') ='Y')
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'PRICE_LIST_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.price_list_id IS NOT NULL and
    NOT EXISTS (select list_header_id 
    FROM    qp_list_headers_vl
    WHERE   list_header_id = b.price_list_id
    and list_type_code in ('PRL', 'AGR') and
    nvl(active_flag,'Y') ='Y');

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('SHIPMENT_PRIORITY_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'SHIPMENT_PRIORITY_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.shipment_priority_code IS NOT NULL and
    NOT EXISTS (select LOOKUP_CODE
    FROM    OE_LOOKUPS
    WHERE   LOOKUP_CODE = b.shipment_priority_code
    AND     LOOKUP_TYPE = 'SHIPMENT_PRIORITY'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'SHIPMENT_PRIORITY_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.shipment_priority_code IS NOT NULL and
    NOT EXISTS (select LOOKUP_CODE
    FROM    OE_LOOKUPS
    WHERE   LOOKUP_CODE = b.shipment_priority_code
    AND     LOOKUP_TYPE = 'SHIPMENT_PRIORITY'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE)); 
    
    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('SHIPPING_METHOD_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'SHIPPING_METHOD'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.shipping_method_code IS NOT NULL and
    NOT EXISTS (select LOOKUP_CODE
    FROM    OE_SHIP_METHODS_V
    WHERE   lookup_code = b.shipping_method_code
    AND     SYSDATE <= NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'SHIPPING_METHOD_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.shipping_method_code IS NOT NULL and
    NOT EXISTS (select LOOKUP_CODE
    FROM    OE_SHIP_METHODS_V
    WHERE   lookup_code = b.shipping_method_code
    AND     SYSDATE <= NVL(END_DATE_ACTIVE, SYSDATE)) ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('SOLD_TO_ORG_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'SOLD_TO_ORG'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.sold_to_org_id IS NOT NULL and
    NOT EXISTS (select ORGANIZATION_ID
    FROM    OE_SOLD_TO_ORGS_V
    WHERE   ORGANIZATION_ID = b.sold_to_org_id
    AND     STATUS = 'A'
    AND     SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                    AND     NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'SOLD_TO_ORG_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.sold_to_org_id IS NOT NULL and
    NOT EXISTS (select ORGANIZATION_ID
    FROM    OE_SOLD_TO_ORGS_V
    WHERE   ORGANIZATION_ID = b.sold_to_org_id
    AND     STATUS = 'A'
    AND     SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                    AND     NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('TAX_EXEMPT_FLAG');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'TAX_EXEMPT_FLAG'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.tax_exempt_flag IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
    FROM    OE_AR_LOOKUPS_V
    WHERE   LOOKUP_CODE = b.tax_exempt_flag
    AND     LOOKUP_TYPE = 'TAX_CONTROL_FLAG'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'TAX_EXEMPT_FLAG'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.tax_exempt_flag IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
    FROM    OE_AR_LOOKUPS_V
    WHERE   LOOKUP_CODE = b.tax_exempt_flag
    AND     LOOKUP_TYPE = 'TAX_CONTROL_FLAG'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('TRANSACTIONAL_CURR_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
      request_id , 'HEADER' ,NULL ,NULL ,NULL ,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL ,NULL
     ,change_sequence ,NULL ,NULL ,NULL ,'TRANSACTIONAL_CURR_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.transactional_curr_code IS NOT NULL and
    NOT EXISTS (SELECT CURRENCY_CODE
    FROM    OE_FND_CURRENCIES_V
    WHERE   CURRENCY_CODE = b.transactional_curr_code
    AND     CURRENCY_FLAG = 'Y'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('PAYMENT_TYPE_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id , 'HEADER' ,NULL ,NULL ,NULL ,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL ,NULL
     ,change_sequence ,NULL ,NULL ,NULL ,'PAYMENT_TYPE_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.payment_type_code IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
    FROM    OE_LOOKUPS
    WHERE   LOOKUP_CODE = b.payment_type_code
    AND     LOOKUP_TYPE = 'PAYMENT TYPE'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('SALESREP_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'SALESREP_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id
    AND b.salesrep_id IS NOT NULL
    AND NOT EXISTS (SELECT a.salesrep_id
    from ra_salesreps_all a
       where salesrep_id =b.salesrep_id
      and sysdate between NVL(start_date_active,sysdate)
                       and NVL(end_date_active,sysdate))
    AND NOT EXISTS (SELECT jrs.salesrep_id
       from jtf_rs_salesreps jrs,
            jtf_rs_resource_extns jre 
       where jrs.salesrep_id = b.salesrep_id
       and jrs.resource_id = jre.resource_id
       and jre.category in ('EMPLOYEE','OTHER','PARTY','PARTNER','SUPPLIER_CONTACT')
       and nvl(jrs.ORG_ID,nvl(to_number(decode(substrb(userenv('CLIENT_INFO'),1,1),' ',
               null,substrb(userenv('CLIENT_INFO'),1,10))),-99)) =
               nvl(to_number(decode(substrb(USERENV('CLIENT_INFO'),1,1),' ',null,
               substrb(userenv('CLIENT_INFO'),1,10))),-99)
       and sysdate between nvl(jrs.start_date_active,sysdate)
                   and nvl(jrs.end_date_active,sysdate))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'SALESREP_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.salesrep_id IS NOT NULL
    AND NOT EXISTS (SELECT a.salesrep_id
       from ra_salesreps_all a
       where salesrep_id =b.salesrep_id
       and sysdate between NVL(start_date_active,sysdate)
                       and NVL(end_date_active,sysdate))
    AND NOT EXISTS (SELECT jrs.salesrep_id
       from jtf_rs_salesreps jrs,
            jtf_rs_resource_extns jre 
       where jrs.salesrep_id = b.salesrep_id
       and jrs.resource_id = jre.resource_id
       and jre.category in ('EMPLOYEE','OTHER','PARTY','PARTNER','SUPPLIER_CONTACT')
       and nvl(jrs.ORG_ID,nvl(to_number(decode(substrb(userenv('CLIENT_INFO'),1,1),' ',
               null,substrb(userenv('CLIENT_INFO'),1,10))),-99)) =
               nvl(to_number(decode(substrb(USERENV('CLIENT_INFO'),1,1),' ',null,
               substrb(userenv('CLIENT_INFO'),1,10))),-99)
       and sysdate between nvl(jrs.start_date_active,sysdate)
                   and nvl(jrs.end_date_active,sysdate))
       ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('SALES_CHANNEL_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id , 'HEADER' ,NULL ,NULL ,NULL ,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL ,NULL
     ,change_sequence ,NULL ,NULL ,NULL ,'SALES_CHANNEL_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.sales_channel_code IS NOT NULL and
    NOT EXISTS (SELECT LOOKUP_CODE
    FROM    OE_LOOKUPS
    WHERE   LOOKUP_CODE = b.sales_channel_code
    AND     LOOKUP_TYPE = 'SALES_CHANNEL'
    AND     ENABLED_FLAG = 'Y'
    AND     SYSDATE     BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                        AND NVL(END_DATE_ACTIVE, SYSDATE));

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('END_ITEM_UNIT_NUMBER');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'END_ITEM_UNIT_NUMBER'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.end_item_unit_number IS NOT NULL and
    NOT EXISTS (SELECT unit_number
    FROM     pjm_unit_numbers_lov_v
    WHERE    unit_number = b.end_item_unit_number);

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('CALCULATE_PRICE_FLAG');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'END_ITEM_UNIT_NUMBER'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND NVL(b.calculate_price_flag,'Y') NOT IN ('Y','P','N');

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

-- OPM HVOP pre_process validation from order import for UOM2 for OPM - 
-- same as in OEXVIMSB.pls

IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN
 IF OE_Bulk_Order_PVT.G_PROCESS_INSTALLED_FLAG = 'Y' THEN

-- 	validation is ordered_quantity_uom2;  
--	1. if line is process and type 0 (zero) then do not supply UOM2 OR secondary quantity 

 l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('ORDERED_QUANTITY_UOM2');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'ORDERED_QUANTITY_UOM2'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND ( b.ordered_quantity_uom2 IS NOT NULL
       OR b.ordered_quantity2 IS NOT NULL )
    AND
        EXISTS (SELECT w.whse_code
	     , s.co_code
     	     , s.orgn_code
        FROM   mtl_parameters p
    	       , ic_whse_mst w
     	       , sy_orgn_mst s
	WHERE w.mtl_organization_id   = p.organization_id
	AND   s.orgn_code             = w.orgn_code
	AND   s.orgn_code             = p.process_orgn_code
	AND   p.process_enabled_flag  ='Y'
	AND   s.delete_mark           = 0
	AND   w.delete_mark           = 0
	AND   p.ORGANIZATION_ID       = b.ship_from_org_id )
    AND EXISTS (SELECT       dualum_ind
        FROM  ic_item_mst
        WHERE delete_mark = 0
        and dualum_ind = 0
        AND   item_no in (SELECT segment1 
         	 FROM mtl_system_items
     	        WHERE organization_id   = b.ship_from_org_id
                  AND inventory_item_id = b.inventory_item_id) ) ;
   
    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'OPM 1 THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

-- OPM HVOP 2. if secondary UOM is entered,then item must be process and type 1 2 or 3 
-- AND secondary UOM must be same as on ic_item_mst.


l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('ORDERED_QUANTITY_UOM2');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'ORDERED_QUANTITY_UOM2'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND ( b.ordered_quantity_uom2 IS NOT NULL )
    AND 
        EXISTS (SELECT w.whse_code
	     , s.co_code
     	     , s.orgn_code
        FROM   mtl_parameters p
    	       , ic_whse_mst w
     	       , sy_orgn_mst s
	WHERE w.mtl_organization_id   = p.organization_id
	AND   s.orgn_code             = w.orgn_code
	AND   s.orgn_code             = p.process_orgn_code
	AND   p.process_enabled_flag  ='Y'
	AND   s.delete_mark           = 0
	AND   w.delete_mark           = 0
	AND   p.ORGANIZATION_ID       = b.ship_from_org_id )
    AND NOT EXISTS (SELECT ic.dualum_ind,
                       sy.um_code -- opm_um                 
        FROM  ic_item_mst ic, 
              mtl_units_of_measure mtl,
    	      sy_uoms_mst sy
        WHERE ic.delete_mark = 0
        AND ic.dualum_ind in (1,2,3) 
        AND sy.unit_of_measure = mtl.unit_of_measure
	AND mtl.uom_code = b.ordered_quantity_uom2
	AND ic.item_um2 = sy.um_code
        AND ic.item_no in (SELECT segment1 
         	 FROM mtl_system_items
     	        WHERE organization_id   = b.ship_from_org_id 
     	          AND inventory_item_id = b.inventory_item_id ) );
          
    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'OPM 2 THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


-- OPM HVOP need to insert here the pre_process validation from order import for grade for OPM - 
-- same as in OEXVIMSB.pls
-- validation is preferred_grade;   1 if entered,item must be process and grade controlled;
--				    2.if entered grade must exist in grad_mst table 

    l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('PREFERRED_GRADE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'PREFERRED_GRADE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.preferred_grade IS NOT NULL
    AND b.ship_from_org_id IS NOT NULL
    AND b.inventory_item_id IS NOT NULL     
    AND 
        EXISTS (SELECT w.whse_code
	     , s.co_code
     	     , s.orgn_code
        FROM   mtl_parameters p
    	       , ic_whse_mst w
     	       , sy_orgn_mst s
	WHERE w.mtl_organization_id   = p.organization_id
	AND   s.orgn_code             = w.orgn_code
	AND   s.orgn_code             = p.process_orgn_code
	AND   p.process_enabled_flag  ='Y'
	AND   s.delete_mark           = 0
	AND   w.delete_mark           = 0
	AND   p.ORGANIZATION_ID       = b.ship_from_org_id )
    AND ( NOT EXISTS (SELECT ic.grade_ctl
        FROM  ic_item_mst ic
        WHERE ic.delete_mark = 0
        AND   ic.grade_ctl = 1 
        AND   ic.item_no in (SELECT segment1 
        	 	 FROM mtl_system_items
     	        	 WHERE organization_id   = b.ship_from_org_id 
     	          	 AND inventory_item_id   = b.inventory_item_id ) )
    OR NOT EXISTS (SELECT preferred_grade
    FROM     qc_grad_mst
    WHERE    qc_grade = b.preferred_grade
             and delete_mark <> 1) ); 	      	          	 
     	 
    
    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'OPM 3 THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


    
 END IF; -- IF OE_Bulk_Order_PVT.G_PROCESS_INSTALLED_FLAG = 'Y' THEN

 -- QUOTING changes - validate trxn phase and version number if >= Pack J
   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('TRANSACTION_PHASE_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'TRANSACTION_PHASE_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.transaction_phase_code IS NOT NULL
    -- Only fulfillment orders are supported for HVOP
    AND nvl(b.transaction_phase_code,'F') <> 'F'
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('VERSION_NUMBER');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'VERSION_NUMBER'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.version_number IS NOT NULL
    -- Version number cannot be negative or in decimals
    AND (b.version_number < 0 
         OR mod(b.version_number,1) <> 0
         )
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
END IF; --  IF OE_CODE_CONTROL.CODE_RELEASE_LEVEL >= '110510' THEN

   -------------------------------------------------------------------
   -- Attribute Validations for Price Adjustments
   -------------------------------------------------------------------

   -- Validations for following adjustment columns in Value to ID:
   -- List Header ID, List Line ID, List Line Type Code

   IF p_adjustments_exist = 'N' THEN
      RETURN;
   END IF;

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('APPLIED_FLAG');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     h.request_id,decode(orig_sys_line_ref,NULL,'HEADER_ADJ','LINE_ADJ'),NULL ,NULL ,NULL
     ,NULL, a.order_source_id ,a.orig_sys_document_ref, a.orig_sys_line_ref ,NULL
     ,a.change_sequence ,NULL ,NULL ,NULL ,'APPLIED_FLAG'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_PRICE_ADJS_INTERFACE a, OE_HEADERS_IFACE_ALL h 
    WHERE h.batch_id = p_batch_id
      AND a.order_source_id = h.order_source_id
      AND a.orig_sys_document_ref = h.orig_sys_document_ref
      AND a.APPLIED_FLAG IS NOT NULL
      AND a.applied_flag NOT IN ('Y','N');

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('INCLUDE_ON_RETURNS_FLAG');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     h.request_id,decode(orig_sys_line_ref,NULL,'HEADER_ADJ','LINE_ADJ'),NULL ,NULL ,NULL
     ,NULL, a.order_source_id ,a.orig_sys_document_ref, a.orig_sys_line_ref ,NULL
     ,a.change_sequence ,NULL ,NULL ,NULL ,'INCLUDE_ON_RETURNS_FLAG'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_PRICE_ADJS_INTERFACE a, OE_HEADERS_IFACE_ALL h 
    WHERE h.batch_id = p_batch_id
      AND a.order_source_id = h.order_source_id
      AND a.orig_sys_document_ref = h.orig_sys_document_ref
      AND a.INCLUDE_ON_RETURNS_FLAG IS NOT NULL
      AND a.include_on_returns_flag NOT IN ('Y','N');

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('CREDIT_OR_CHARGE_FLAG');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     h.request_id,decode(orig_sys_line_ref,NULL,'HEADER_ADJ','LINE_ADJ'),NULL ,NULL ,NULL
     ,NULL, a.order_source_id ,a.orig_sys_document_ref, a.orig_sys_line_ref ,NULL
     ,a.change_sequence ,NULL ,NULL ,NULL ,'CREDIT_OR_CHARGE_FLAG'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_PRICE_ADJS_INTERFACE a, OE_HEADERS_IFACE_ALL h 
    WHERE h.batch_id = p_batch_id
      AND a.order_source_id = h.order_source_id
      AND a.orig_sys_document_ref = h.orig_sys_document_ref
      AND a.CREDIT_OR_CHARGE_FLAG IS NOT NULL
      AND NOT EXISTS (SELECT 'Y'
                      FROM OE_LOOKUPS l
                      WHERE LOOKUP_TYPE = 'CREDIT_OR_CHARGE_FLAG'
                        AND LOOKUP_CODE = a.credit_or_charge_flag);

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('CHARGE_TYPE_CODE');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     h.request_id,decode(orig_sys_line_ref,NULL,'HEADER_ADJ','LINE_ADJ'),NULL ,NULL ,NULL
     ,NULL, a.order_source_id ,a.orig_sys_document_ref, a.orig_sys_line_ref ,NULL
     ,a.change_sequence ,NULL ,NULL ,NULL ,'CHARGE_TYPE_CODE'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_PRICE_ADJS_INTERFACE a, OE_HEADERS_IFACE_ALL h 
    WHERE h.batch_id = p_batch_id
      AND a.order_source_id = h.order_source_id
      AND a.orig_sys_document_ref = h.orig_sys_document_ref
      AND a.CHARGE_TYPE_CODE IS NOT NULL
      AND NOT EXISTS (SELECT 'Y'
                      FROM QP_CHARGE_LOOKUP
                      WHERE LOOKUP_CODE = a.charge_type_code);

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('LIST_HEADER_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     h.request_id,decode(orig_sys_line_ref,NULL,'HEADER_ADJ','LINE_ADJ'),NULL ,NULL ,NULL
     ,NULL, a.order_source_id ,a.orig_sys_document_ref, a.orig_sys_line_ref ,NULL
     ,a.change_sequence ,NULL ,NULL ,NULL ,'LIST_HEADER_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_PRICE_ADJS_INTERFACE a, OE_HEADERS_IFACE_ALL h 
    WHERE h.batch_id = p_batch_id
      AND a.order_source_id = h.order_source_id
      AND a.orig_sys_document_ref = h.orig_sys_document_ref
      AND a.list_header_id IS NOT NULL
      AND NOT EXISTS (SELECT 'Y'
                      FROM QP_LIST_HEADERS
                      WHERE LIST_HEADER_ID = a.list_header_id
                      );

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

   l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('LIST_LINE_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
     h.request_id,decode(orig_sys_line_ref,NULL,'HEADER_ADJ','LINE_ADJ'),NULL ,NULL ,NULL
     ,NULL, a.order_source_id ,a.orig_sys_document_ref, a.orig_sys_line_ref ,NULL
     ,a.change_sequence ,NULL ,NULL ,NULL ,'LIST_LINE_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660 ,NULL ,NULL ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_PRICE_ADJS_INTERFACE a, OE_HEADERS_IFACE_ALL h 
    WHERE h.batch_id = p_batch_id
      AND a.order_source_id = h.order_source_id
      AND a.orig_sys_document_ref = h.orig_sys_document_ref
      AND a.list_line_id IS NOT NULL
      AND NOT EXISTS (SELECT 'Y'
                      FROM QP_LIST_LINES
                      WHERE LIST_LINE_ID = a.list_line_id
                        AND LIST_HEADER_ID = a.list_header_id
                      );
 IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;

 -- End Customer Change
l_msg_text := l_msg_data||
                 OE_ORDER_UTIL.Get_Attribute_Name('END_CUSTOMER_ID');
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id , 'HEADER',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,NULL
     ,NULL ,change_sequence,NULL,NULL,NULL,'END_CUSTOMER'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_HEADERS_IFACE_ALL b
    WHERE batch_id = p_batch_id and
    b.sold_to_org_id IS NOT NULL and
    NOT EXISTS (select ORGANIZATION_ID
    FROM    OE_SOLD_TO_ORGS_V
    WHERE   ORGANIZATION_ID = b.sold_to_org_id
    AND     STATUS = 'A'
    AND     SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                    AND     NVL(END_DATE_ACTIVE, SYSDATE))
    ;

    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;
    
   INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id
     ,line_id ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,source_document_type_id ,source_document_id ,source_document_line_id
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login ,program_application_id ,program_id
     ,program_update_date ,process_activity ,notification_flag ,type
     ,message_source_code ,language ,message_text, transaction_id
    )
    SELECT
    request_id ,'LINE',NULL,NULL,NULL,NULL
     ,order_source_id ,orig_sys_document_ref ,ORIG_SYS_LINE_REF
     ,orig_sys_shipment_ref ,change_sequence,NULL,NULL,NULL,'END_CUSTOMER_ID'
     ,sysdate ,FND_GLOBAL.USER_ID ,sysdate ,FND_GLOBAL.USER_ID
     ,FND_GLOBAL.CONC_LOGIN_ID ,660,NULL,NULL,NULL,NULL,NULL
     ,'C' ,USERENV('LANG') ,l_msg_text, OE_MSG_ID_S.NEXTVAL
    FROM OE_LINES_IFACE_ALL b
    WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT order_source_id, orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL
                     WHERE batch_id = p_batch_id)
    AND b.sold_to_org_id IS NOT NULL and
    NOT EXISTS (select ORGANIZATION_ID
    FROM    OE_SOLD_TO_ORGS_V
    WHERE   ORGANIZATION_ID = b.sold_to_org_id
    AND     STATUS = 'A'
    AND     SYSDATE BETWEEN NVL(START_DATE_ACTIVE, SYSDATE)
                    AND     NVL(END_DATE_ACTIVE, SYSDATE));



    IF g_error_count = 0 THEN
       IF SQL%ROWCOUNT > 0 THEN
          g_error_count := 1;
          IF l_debug_level  > 0 THEN
              oe_debug_pub.add(  'THE ERROR COUNT IS SET' ) ;
          END IF;
       END IF;
    END IF;


    
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'EXIT ATTRIBUTES , G_ERROR_COUNT: '||G_ERROR_COUNT ) ;
  END IF;
EXCEPTION
    WHEN OTHERS THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OTHERS ERROR , VALIDATE.ATTRIBUTES' ) ;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
    END IF;
    OE_BULK_MSG_PUB.ADD_Exc_Msg
      (   G_PKG_NAME
      ,   'Attributes'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END Attributes;


---------------------------------------------------------------------
--
-- PROCEDURE Validate_BOM
--
---------------------------------------------------------------------

PROCEDURE Validate_BOM

IS
  l_msg_text                  VARCHAR2(2000); 

  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

BEGIN
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add( 'ENTERING OE_BULK_VALIDATE.Validate_BOM ') ;
  END IF;


  -- Check if parent exists  

  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_BULK_CONFIG_MISS_PARENT');

  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language
     ,message_text, transaction_id
    )
  SELECT
     OE_BULK_ORDER_PVT.G_REQUEST_ID,'LINE' ,NULL,NULL ,NULL ,l.line_id
     ,l.order_source_id ,l.orig_sys_document_ref
     ,l.orig_sys_line_ref, l.orig_sys_shipment_ref, NULL
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text || ' '|| l.ordered_item, 
     OE_MSG_ID_S.NEXTVAL
  FROM oe_config_details_tmp L
  WHERE NVL(L.item_type_code, 'XXX') <> 'MODEL'
  AND NOT EXISTS (select L2.line_id
                  From oe_config_details_tmp L2
                  WHERE L2.component_code = 
		      substr(L.component_code,1,instr(L.component_code,'-',-1,1)-1)
                  AND L2.top_model_line_id = L.top_model_line_id); 


  IF OE_BULK_VALIDATE.g_error_count = 0 THEN
     IF SQL%ROWCOUNT > 0 THEN
        OE_BULK_VALIDATE.g_error_count := 1;
     END IF;
  END IF;



  -- Check for min max quantities 

  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_BULK_CONFIG_QTY_RANGE');

  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language
     ,message_text, transaction_id
    )
  SELECT
     OE_BULK_ORDER_PVT.G_REQUEST_ID ,'LINE' ,NULL,NULL ,NULL ,l.line_id
     ,l.order_source_id ,l.orig_sys_document_ref
     ,l.orig_sys_line_ref, l.orig_sys_shipment_ref, NULL
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text ||' '||l.ordered_item || '( '|| l.low_quantity*L2.ordered_quantity 
		|| ' -> '|| l.high_quantity *L2.ordered_quantity || ')', 
     OE_MSG_ID_S.NEXTVAL
  FROM oe_config_details_tmp L,
       oe_config_details_tmp L2
  WHERE L2.item_type_code = 'MODEL'
  AND L.top_model_line_id = L2.line_id
  AND L.ordered_quantity > 0
  AND L2.ordered_quantity > 0
  AND ( TRUNC(L.ordered_quantity/L2.ordered_quantity) < L.low_quantity OR
        TRUNC(L.ordered_quantity/L2.ordered_quantity) > L.high_quantity );

  IF OE_BULK_VALIDATE.g_error_count = 0 THEN
     IF SQL%ROWCOUNT > 0 THEN
        OE_BULK_VALIDATE.g_error_count := 1;
     END IF;
  END IF;



  -- Check for class has options 
  l_msg_text := FND_MESSAGE.GET_STRING('ONT','OE_BULK_CONFIG_CLS_NO_OPTION');

  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language
     ,message_text, transaction_id
    )
  SELECT
     OE_BULK_ORDER_PVT.G_REQUEST_ID, 'LINE' ,NULL,NULL ,NULL ,l.line_id
     ,l.order_source_id ,l.orig_sys_document_ref
     ,l.orig_sys_line_ref, l.orig_sys_shipment_ref, NULL
     ,NULL, sysdate, FND_GLOBAL.USER_ID ,sysdate
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text || ' '||l.ordered_item 
     ,OE_MSG_ID_S.NEXTVAL
  FROM oe_config_details_tmp L
  WHERE L.BOM_ITEM_TYPE = 2
  AND L.ordered_quantity > 0 
  AND NOT EXISTS ( 	-- fix bug 5687771
	select 1
	from oe_config_details_tmp L2
	where L2.top_model_line_id = L.top_model_line_id
	and substr(L2.component_code, 1, instr(l2.component_code,'-',-1)-1) = L.component_code );

/* 
  AND L.component_code NOT IN (
	select substr(L2.component_code, 1, instr(l2.component_code,'-',-1)-1)
        From oe_config_details_tmp L2
        --BUG 4586356  Where L2.item_type_code = 'OPTION'
        --BUG 4586356 And L2.top_model_line_id = L.top_model_line_id);
	where L2.top_model_line_id = L.top_model_line_id);
*/

  IF OE_BULK_VALIDATE.g_error_count = 0 THEN
     IF SQL%ROWCOUNT > 0 THEN
        OE_BULK_VALIDATE.g_error_count := 1;
     END IF;
  END IF;

  -- Check for mutually exclusive options 

  -- existing message can used without specifying the token.
  l_msg_text := FND_MESSAGE.GET_STRING('ONT', 'OE_BULK_CONFIG_EXCLUSIVE_CLS'); 

  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language
     ,message_text, transaction_id
    )
  SELECT
     OE_BULK_ORDER_PVT.G_REQUEST_ID,'LINE' ,NULL,NULL ,NULL ,l.line_id
     ,l.order_source_id ,l.orig_sys_document_ref
     ,l.orig_sys_line_ref, l.orig_sys_shipment_ref, NULL
     ,NULL, sysdate, FND_GLOBAL.USER_ID , sysdate
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text || ' '||l.ordered_item
     ,OE_MSG_ID_S.NEXTVAL
  FROM oe_config_details_tmp L
  WHERE L.ITEM_TYPE_CODE in ('CLASS','MODEL')
  AND L.mutually_exclusive_options = 1
  AND 2 <= ( select count(line_id) 
	     From oe_config_details_tmp L2
             where   --BUG 4586356 L2.item_type_code = 'OPTION'
             L.component_code = substr(L2.component_code, 1, instr(l2.component_code,'-',-1)-1)
             and L2.top_model_line_id = L.top_model_line_id);

  IF OE_BULK_VALIDATE.g_error_count = 0 THEN
     IF SQL%ROWCOUNT > 0 THEN
        OE_BULK_VALIDATE.g_error_count := 1;
     END IF;
  END IF;

  -- Check for mandatory classes 

  l_msg_text := FND_MESSAGE.GET_STRING('ONT', 'OE_BULK_CONFIG_MANDATORY_CLS'); 

  INSERT INTO OE_PROCESSING_MSGS
   ( request_id ,entity_code ,entity_ref ,entity_id ,header_id, line_id
     ,order_source_id ,original_sys_document_ref
     ,original_sys_document_line_ref ,orig_sys_shipment_ref ,change_sequence
     ,attribute_code ,creation_date ,created_by ,last_update_date
     ,last_updated_by ,last_update_login
     ,program_application_id ,program_id,program_update_date
     ,process_activity ,notification_flag ,type
     ,message_source_code ,language
     ,message_text, transaction_id
    )
  SELECT
     OE_BULK_ORDER_PVT.G_REQUEST_ID,'LINE' ,NULL,NULL ,NULL ,l.line_id
     ,l.order_source_id ,l.orig_sys_document_ref
     ,l.orig_sys_line_ref, l.orig_sys_shipment_ref, NULL
     ,NULL, sysdate, FND_GLOBAL.USER_ID , sysdate
     ,FND_GLOBAL.USER_ID ,FND_GLOBAL.CONC_LOGIN_ID
     ,660 ,NULL ,NULL
     ,NULL ,NULL ,NULL
     ,'C' ,USERENV('LANG')
     ,l_msg_text || ' '||l.ordered_item
     , OE_MSG_ID_S.NEXTVAL
  FROM oe_config_details_tmp L
  WHERE L.ITEM_TYPE_CODE = 'MODEL'
  AND EXISTS  (select b2.component_code 
               From  bom_explosions b2
               Where b2.explosion_type = 'OPTIONAL'
               AND   b2.top_bill_sequence_id = L.top_bill_sequence_id
               AND   b2.plan_level >= 0
               AND   b2.effectivity_date <= sysdate
               AND   b2.disable_date > sysdate
               AND   b2.bom_item_type IN ( 1, 2 )  -- Model, Class
               AND   b2.optional = 2
               AND   b2.component_code NOT IN (
				select component_code
                                From oe_config_details_tmp L2
                                Where L.top_model_line_id = L2.top_model_line_id)
	       AND   SUBSTR(B2.COMPONENT_CODE,1,INSTR(B2.COMPONENT_CODE,'-',-1,1)-1) 
		     IN (	select component_code
                                From oe_config_details_tmp L3
                                Where L.top_model_line_id = L3.top_model_line_id)		           );

  IF OE_BULK_VALIDATE.g_error_count = 0 THEN
     IF SQL%ROWCOUNT > 0 THEN
        OE_BULK_VALIDATE.g_error_count := 1;
     END IF;
  END IF;

              
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add('LEAVING OE_BULK_VALIDATE.Validate_BOM' , 1);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    oe_debug_pub.add('Others Error, Validate_BOM');
    oe_debug_pub.add(substr(sqlerrm,1,240));
    OE_BULK_MSG_PUB.Add_Exc_Msg
      (   G_PKG_NAME,
          'Validate_BOM'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END Validate_BOM;


---------------------------------------------------------------------
-- PROCEDURE Mark_Interface_Error
--
-- This procedure sets error_flag on order header interface table
-- if any entity of this order (header, line, adjustments etc.)
-- fail pre-processing checks or attribute validation.
---------------------------------------------------------------------

PROCEDURE MARK_INTERFACE_ERROR(p_batch_id NUMBER)
IS
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
BEGIN
      
     -- set the error flag for the configuration pre_process failure
     BEGIN
     UPDATE OE_HEADERS_IFACE_ALL h
     SET ERROR_FLAG = 'Y'
          ,ATTRIBUTE_STATUS = NULL
     WHERE batch_id = p_batch_id
     AND nvl(ERROR_FLAG, 'N') = 'N'
     AND EXISTS
          (SELECT 'Y'
           FROM OE_CONFIG_DETAILS_TMP t
           WHERE t.orig_sys_document_ref = h.ORIG_SYS_DOCUMENT_REF
           AND t.order_source_id = h.order_source_id
           AND nvl(t.lock_control, 0) = -99);
     EXCEPTION
         WHEN NO_DATA_FOUND THEN
             NULL;
     END;

     OE_BULK_ORDER_IMPORT_PVT.G_ERROR_ORDERS := 
         	OE_BULK_ORDER_IMPORT_PVT.G_ERROR_ORDERS + SQL%ROWCOUNT;

    IF g_error_count >= 1 THEN

       UPDATE OE_HEADERS_IFACE_ALL a
       SET ERROR_FLAG = 'Y'
          ,ATTRIBUTE_STATUS = NULL
       WHERE batch_id = p_batch_id
       AND nvl(ERROR_FLAG, 'N') = 'N'
       AND EXISTS
          (SELECT original_sys_document_line_ref
           FROM OE_PROCESSING_MSGS b
           WHERE b.original_sys_document_ref = a.ORIG_SYS_DOCUMENT_REF
           AND b.order_source_id = a.order_source_id
           AND b.request_id = a.request_id);


       OE_BULK_ORDER_IMPORT_PVT.G_ERROR_ORDERS := 
         	OE_BULK_ORDER_IMPORT_PVT.G_ERROR_ORDERS + SQL%ROWCOUNT;


       BEGIN

       UPDATE OE_LINES_IFACE_ALL c
       SET ATTRIBUTE_STATUS = NULL
       WHERE (order_source_id, orig_sys_document_ref) IN
                   ( SELECT a.order_source_id, a.orig_sys_document_ref
                     FROM OE_HEADERS_IFACE_ALL a, OE_PROCESSING_MSGS b
                     WHERE a.batch_id = p_batch_id
                     AND b.original_sys_document_ref = a.ORIG_SYS_DOCUMENT_REF
                     AND b.order_source_id = a.order_source_id);
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
             NULL;
       END;

       ----------------------------------------
       --ADDED BY UMA ON 7/18/02
       ----------------------------------------

	--OE_BULK_ORDER_IMPORT_PVT.G_ERROR_ORDERS := 
         --   OE_BULK_ORDER_IMPORT_PVT.G_ERROR_ORDERS + SQL%ROWCOUNT;

    END IF;

EXCEPTION
    WHEN OTHERS THEN
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'OTHERS ERROR , MARK_INTERFACE_ERROR' ) ;
    END IF;
    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  SUBSTR ( SQLERRM , 1 , 240 ) ) ;
    END IF;
    OE_BULK_MSG_PUB.ADD_Exc_Msg
      (   G_PKG_NAME
      ,   'MARK_INTERFACE_ERROR'
       );
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
END MARK_INTERFACE_ERROR;

END OE_BULK_VALIDATE;
/
-- SHOW ERRORS;
commit;
exit;

