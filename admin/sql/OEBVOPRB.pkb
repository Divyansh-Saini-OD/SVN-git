--  
--  Copyright (c) 1996 Oracle Corporation, Redwood Shores, CA, USA
--  All rights reserved.
--  
--  FILENAME
--  
--      OEBVOPRS.pls
--  
--  DESCRIPTION
--  
--      Spec Package OE_BULK_PRICEORDER_PVT
--  
--  NOTES
--  
--  HISTORY
--  
--  05-May-2002 Created BTEA
--  
SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile:~PROD:~PATH:~FILE
CREATE or REPLACE PACKAGE BODY OE_BULK_PRICEORDER_PVT AS
/* $Header: OEBVOPRB.pls 115.12 2004/07/01 07:29:13 jisingh ship $ */



G_PKG_NAME                    CONSTANT VARCHAR2(30) := 'OE_BULK_PRICEORDER_PVT';
G_CHARGES_FOR_INCLUDED_ITEM Varchar2(30)
      := nvl(fnd_profile.value('ONT_CHARGES_FOR_INCLUDED_ITEM'),'N');
G_FUNCTION_CURRENCY           VARCHAR2(30) default NULL;



Type Price_Flag_Type Is Record
( all_lines_y  OE_WSH_BULK_GRP.T_V1    := OE_WSH_BULK_GRP.T_V1(),
  all_lines_n   OE_WSH_BULK_GRP.T_V1    := OE_WSH_BULK_GRP.T_V1(),
  Mixed        OE_WSH_BULK_GRP.T_V1    := OE_WSH_BULK_GRP.T_V1()
); 

G_PRICE_FLAG  Price_Flag_Type;

Function get_version Return Varchar2 is
Begin
 Return('/* $Header: OEBVOPRB.pls 115.12 2004/07/01 07:29:13 jisingh ship $ */');
End;

Procedure set_price_flag(p_line_rec IN OUT NOCOPY OE_WSH_BULK_GRP.LINE_REC_TYPE,
                         p_index                  Number,
                         p_header_counter         Number
                         ) IS
  l_hdr_count number := OE_BULK_ORDER_PVT.G_HEADER_REC.HEADER_ID.count;
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  l_local_count BINARY_INTEGER;
Begin
  l_local_count := G_PRICE_FLAG.ALL_LINES_Y.COUNT;
  IF l_hdr_count > l_local_count THEN
     G_PRICE_FLAG.ALL_LINES_Y.extend(l_hdr_count - l_local_count);
     G_PRICE_FLAG.ALL_LINES_N.extend(l_hdr_count - l_local_count);
     G_PRICE_FLAG.MIXED.extend(l_hdr_count - l_local_count);
  END IF;
  If l_debug_level > 0 Then
     oe_debug_pub.add('inside set_price_flag');
     oe_debug_pub.add('p_header_counter : '||p_header_counter||'hdr count : '||oe_bulk_order_pvt.g_header_rec.header_id.count);
     oe_debug_pub.add('G_PRICE_FLAG count : '||G_PRICE_FLAG.ALL_LINES_Y.count);
  end if;

If G_PRICE_FLAG.ALL_LINES_Y(p_header_counter) is null or G_PRICE_FLAG.ALL_LINES_N(p_header_counter) is null or G_PRICE_FLAG.MIXED(p_header_counter) is null Then
If G_PRICE_FLAG.ALL_LINES_Y(p_header_counter) is null and G_PRICE_FLAG.ALL_LINES_N(p_header_counter) is null and G_PRICE_FLAG.MIXED(p_header_counter) is null then
     IF p_line_rec.calculate_price_flag(p_index) = 'Y' Then
           G_PRICE_FLAG.ALL_LINES_Y(p_header_counter) := 'Y';
           G_PRICE_FLAG.ALL_LINES_N(p_header_counter) := 'N';
     else
           G_PRICE_FLAG.ALL_LINES_Y(p_header_counter) := 'N';
           G_PRICE_FLAG.ALL_LINES_N(p_header_counter) := 'Y';
     end if;
else
     if  p_line_rec.calculate_price_flag(p_index) = 'Y' Then
         if G_PRICE_FLAG.ALL_LINES_Y(p_header_counter) = 'N' then
                G_PRICE_FLAG.MIXED(p_header_counter) := 'Y';
         end if;
     else
          if    G_PRICE_FLAG.ALL_LINES_N(p_header_counter) = 'N' Then
                 G_PRICE_FLAG.MIXED(p_header_counter) := 'Y';
          end if;
      end if;
end if;
end if;
end;



Procedure set_hdr_price_flag(p_header_rec IN OUT NOCOPY OE_BULK_ORDER_PVT.HEADER_REC_TYPE) IS

  l_hdr_ctr  Number := p_header_rec.header_id.count;
  i          Number;
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
Begin

   If l_debug_level > 0 Then
    oe_debug_pub.add('inside set_hdr_price_flag');
    oe_debug_pub.add('p_header_rec.header_id.count = '||l_hdr_ctr);
    oe_debug_pub.add('g_price_flag count all_lines_y= '|| G_PRICE_FLAG.ALL_LINES_Y.count);
    oe_debug_pub.add('g_price_flag count mixed= '|| G_PRICE_FLAG.MIXED.count);
   end if;

      p_header_rec.calculate_price_flag.extend(l_hdr_ctr);
   for i in 1..l_hdr_ctr LOOP
      IF G_PRICE_FLAG.MIXED(i) = 'Y' Then
         p_header_rec.calculate_price_flag(i) := 'P';
      elsif G_PRICE_FLAG.ALL_LINES_Y(i) = 'Y' Then
         p_header_rec.calculate_price_flag(i) := 'Y';
      else
         p_header_rec.calculate_price_flag(i) := 'N';
      end if;
      
      --Setting the flags back to null
      G_PRICE_FLAG.ALL_LINES_Y(i) := NULL;
      G_PRICE_FLAG.ALL_LINES_N(i) := NULL;
      G_PRICE_FLAG.MIXED(i) := NULL;
    end loop;
end;
  

/****************************************************************************************************
Procedure Unbook_included_item

*****************************************************************************************************/
Procedure Unbook_Included_Item(p_start_index In Number,p_count In Number) As
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
Begin

  If l_debug_level > 0 Then
   oe_debug_pub.add('Starting unbook included item lines');
   oe_debug_pub.add('p_start_index:'||p_start_index);
   oe_debug_pub.add('p_count:'||p_count);
  End If;

  For i in p_start_index..p_start_index + p_count - 1 Loop
    If OE_BULK_ORDER_PVT.G_Line_Rec.Booked_Flag.exists(i) Then
      OE_BULK_ORDER_PVT.G_Line_Rec.Booked_Flag(i):='N';
    Else
      If l_debug_level > 0 Then
        oe_debug_pub.add('Record index:'||i||' does not exists'); 
      End If;
    End If;
  End Loop;

  If l_debug_level > 0 Then
    oe_debug_pub.add('Leaving unbook included item lines');
  End If;
End;

/*************************************************************************************************
Procedure Insert_Adj
This procedure transfers valid adjustments from QP temp tables to oe_price_adjustments
**************************************************************************************************/
  --!!!warning, Insert_Adj look oe_order_pub.g_hdr.header_id will need to change for hvop
  --OE_ADV_PRICE_PVT.Insert_Adj;
  --The reason not to call adv_price_pvt.insert_adj is because this will introduce dependency on
  --qp data model.  That is header_id will need to be added to qp_preq_lines_tmp.  If we reference
  --qp_preq_lines_tmp.header_id, in Oe_adj_price_pvt.insert_adj then we will need to include odf that
  --will have the columns. Due to this reason, I have to copy the code over although it is 99% the same
  --code.


Procedure Insert_Adj(p_hvop_mode In Boolean Default False) 
IS
l_booked_flag varchar2(1) := oe_order_cache.g_header_rec.booked_flag;
i  Number;
--
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
--
cursor test is
select pricing_status_code,LINE_DETAIL_INDEX,LINE_INDEX from QP_PREQ_LINE_ATTRS_TMP;
BEGIN
  IF l_debug_level  > 0 THEN
      oe_debug_pub.add(  'INSIDE OE_BULK_PRICEORDER_PVT.INSERT_ADJ' ) ;
  END IF;
 --bug 3544829
 -- added the condition for manual adjustments in the where clause
    INSERT INTO OE_PRICE_ADJUSTMENTS
    (       PRICE_ADJUSTMENT_ID
    ,       CREATION_DATE
    ,       CREATED_BY
    ,       LAST_UPDATE_DATE
    ,       LAST_UPDATED_BY
    ,       LAST_UPDATE_LOGIN
    ,       PROGRAM_APPLICATION_ID
    ,       PROGRAM_ID
    ,       PROGRAM_UPDATE_DATE
    ,       REQUEST_ID
    ,       HEADER_ID
    ,       DISCOUNT_ID
    ,       DISCOUNT_LINE_ID
    ,       AUTOMATIC_FLAG
    ,       PERCENT
    ,       LINE_ID
    ,       CONTEXT
    ,       ATTRIBUTE1
    ,       ATTRIBUTE2
    ,       ATTRIBUTE3
    ,       ATTRIBUTE4
    ,       ATTRIBUTE5
    ,       ATTRIBUTE6
    ,       ATTRIBUTE7
    ,       ATTRIBUTE8
    ,       ATTRIBUTE9
    ,       ATTRIBUTE10
    ,       ATTRIBUTE11
    ,       ATTRIBUTE12
    ,       ATTRIBUTE13
    ,       ATTRIBUTE14
    ,       ATTRIBUTE15
    ,       ORIG_SYS_DISCOUNT_REF
    ,	  LIST_HEADER_ID
    ,	  LIST_LINE_ID
    ,	  LIST_LINE_TYPE_CODE
    ,	  MODIFIER_MECHANISM_TYPE_CODE
    ,	  MODIFIED_FROM 
    ,	  MODIFIED_TO
    ,	  UPDATED_FLAG
    ,	  UPDATE_ALLOWED
    ,	  APPLIED_FLAG
    ,	  CHANGE_REASON_CODE
    ,	  CHANGE_REASON_TEXT
    ,	  operand				
    ,	  Arithmetic_operator
    ,	  COST_ID
    ,	  TAX_CODE
    ,	  TAX_EXEMPT_FLAG
    ,	  TAX_EXEMPT_NUMBER
    ,	  TAX_EXEMPT_REASON_CODE
    ,	  PARENT_ADJUSTMENT_ID
    ,	  INVOICED_FLAG
    ,	  ESTIMATED_FLAG
    ,	  INC_IN_SALES_PERFORMANCE
    ,	  SPLIT_ACTION_CODE
    ,	  ADJUSTED_AMOUNT
    ,	  PRICING_PHASE_ID
    ,	  CHARGE_TYPE_CODE
    ,	  CHARGE_SUBTYPE_CODE
    ,     list_line_no
    ,     source_system_code
    ,     benefit_qty
    ,     benefit_uom_code
    ,     print_on_invoice_flag
    ,     expiration_date
    ,     rebate_transaction_type_code
    ,     rebate_transaction_reference
    ,     rebate_payment_system_code
    ,     redeemed_date
    ,     redeemed_flag
    ,     accrual_flag
    ,     range_break_quantity         
    ,     accrual_conversion_rate     
    ,     pricing_group_sequence     
    ,     modifier_level_code       
    ,     price_break_type_code    
    ,     substitution_attribute  
    ,     proration_type_code    
    ,       CREDIT_OR_CHARGE_FLAG    
    ,       INCLUDE_ON_RETURNS_FLAG    
    ,       AC_CONTEXT
    ,       AC_ATTRIBUTE1
    ,       AC_ATTRIBUTE2
    ,       AC_ATTRIBUTE3
    ,       AC_ATTRIBUTE4
    ,       AC_ATTRIBUTE5
    ,       AC_ATTRIBUTE6
    ,       AC_ATTRIBUTE7
    ,       AC_ATTRIBUTE8
    ,       AC_ATTRIBUTE9
    ,       AC_ATTRIBUTE10
    ,       AC_ATTRIBUTE11
    ,       AC_ATTRIBUTE12
    ,       AC_ATTRIBUTE13
    ,       AC_ATTRIBUTE14
    ,       AC_ATTRIBUTE15
    ,       OPERAND_PER_PQTY
    ,       ADJUSTED_AMOUNT_PER_PQTY
    ,	  LOCK_CONTROL
    )
    ( SELECT     /*+ ORDERED USE_NL(ldets lines qh) */ 
            ldets.price_adjustment_id
    ,       sysdate --p_Line_Adj_rec.creation_date
    ,       fnd_global.user_id --p_Line_Adj_rec.created_by
    ,       sysdate --p_Line_Adj_rec.last_update_date
    ,       fnd_global.user_id --p_Line_Adj_rec.last_updated_by
    ,       fnd_global.login_id --p_Line_Adj_rec.last_update_login
    ,       NULL --p_Line_Adj_rec.program_application_id
    ,       NULL --p_Line_Adj_rec.program_id
    ,       NULL --p_Line_Adj_rec.program_update_date
    ,       NULL --p_Line_Adj_rec.request_id
    ,       lines.header_id
    ,       NULL --p_Line_Adj_rec.discount_id
    ,       NULL  --p_Line_Adj_rec.discount_line_id
    ,       ldets.automatic_flag
    ,       NULL --p_Line_Adj_rec.percent
    ,       decode(ldets.modifier_level_code,'ORDER',NULL,lines.line_id)
    ,       NULL --p_Line_Adj_rec.context
    ,       NULL --p_Line_Adj_rec.attribute1
    ,       NULL --p_Line_Adj_rec.attribute2
    ,       NULL --p_Line_Adj_rec.attribute3
    ,       NULL --p_Line_Adj_rec.attribute4
    ,       NULL --p_Line_Adj_rec.attribute5
    ,       NULL --p_Line_Adj_rec.attribute6
    ,       NULL --p_Line_Adj_rec.attribute7
    ,       NULL --p_Line_Adj_rec.attribute8
    ,       NULL --p_Line_Adj_rec.attribute9
    ,       NULL --p_Line_Adj_rec.attribute10
    ,       NULL --p_Line_Adj_rec.attribute11
    ,       NULL --p_Line_Adj_rec.attribute12
    ,       NULL --p_Line_Adj_rec.attribute13
    ,       NULL --p_Line_Adj_rec.attribute14
    ,       NULL --p_Line_Adj_rec.attribute15
    ,       NULL --p_Line_Adj_rec.orig_sys_discount_ref
    ,	  ldets.LIST_HEADER_ID
    ,	  ldets.LIST_LINE_ID
    ,	  ldets.LIST_LINE_TYPE_CODE
    ,	  NULL --p_Line_Adj_rec.MODIFIER_MECHANISM_TYPE_CODE
    ,	  decode(ldets.list_line_type_code, 'TSN', ldets.substitution_attribute, 'IUE', to_char(ldets.inventory_item_id), NULL)
    ,	  decode(ldets.list_line_type_code, 'TSN', ldets.substitution_value_to, 'IUE', to_char(ldets.related_item_id), NULL)
    ,	  'N' --p_Line_Adj_rec.UPDATED_FLAG
    ,	  ldets.override_flag
    ,	  ldets.APPLIED_FLAG
    ,	  NULL --p_Line_Adj_rec.CHANGE_REASON_CODE
    ,	  NULL --p_Line_Adj_rec.CHANGE_REASON_TEXT
    ,	  nvl(ldets.order_qty_operand, decode(ldets.operand_calculation_code, 
             '%', ldets.operand_value, 
             'LUMPSUM', ldets.operand_value,
             ldets.operand_value*lines.priced_quantity/nvl(lines.line_quantity,1)))
    ,	  ldets.operand_calculation_code --p_Line_Adj_rec.arithmetic_operator
    ,	  NULl --p_line_Adj_rec.COST_ID
    ,	  NULL --p_line_Adj_rec.TAX_CODE
    ,	  NULL --p_line_Adj_rec.TAX_EXEMPT_FLAG
    ,	  NULL --p_line_Adj_rec.TAX_EXEMPT_NUMBER
    ,	  NULL --p_line_Adj_rec.TAX_EXEMPT_REASON_CODE
    ,	  NULL --p_line_Adj_rec.PARENT_ADJUSTMENT_ID
    ,	  NULL --p_line_Adj_rec.INVOICED_FLAG
    ,	  NULL --p_line_Adj_rec.ESTIMATED_FLAG
    ,	  NULL --p_line_Adj_rec.INC_IN_SALES_PERFORMANCE
    ,	  NULL --p_line_Adj_rec.SPLIT_ACTION_CODE
    ,	  nvl(ldets.order_qty_adj_amt, ldets.adjustment_amount*nvl(lines.priced_quantity,1)/nvl(lines.line_quantity,1))
    ,	  ldets.pricing_phase_id --p_line_Adj_rec.PRICING_PHASE_ID
    ,	  ldets.CHARGE_TYPE_CODE
    ,	  ldets.CHARGE_SUBTYPE_CODE
    ,       ldets.list_line_no
    ,       qh.source_system_code
    ,       ldets.benefit_qty
    ,       ldets.benefit_uom_code
    ,       NULL --p_Line_Adj_rec.print_on_invoice_flag
    ,       ldets.expiration_date
    ,       ldets.rebate_transaction_type_code
    ,       NULL --p_Line_Adj_rec.rebate_transaction_reference
    ,       NULL --p_Line_Adj_rec.rebate_payment_system_code
    ,       NULL --p_Line_Adj_rec.redeemed_date
    ,       NULL --p_Line_Adj_rec.redeemed_flag
    ,       ldets.accrual_flag
    ,       ldets.line_quantity  --p_Line_Adj_rec.range_break_quantity
    ,       ldets.accrual_conversion_rate
    ,       ldets.pricing_group_sequence
    ,       ldets.modifier_level_code
    ,       ldets.price_break_type_code
    ,       ldets.substitution_attribute
    ,       ldets.proration_type_code
    ,       NULL --p_Line_Adj_rec.credit_or_charge_flag    
    ,       ldets.include_on_returns_flag
    ,       NULL -- p_Line_Adj_rec.ac_context
    ,       NULL -- p_Line_Adj_rec.ac_attribute1
    ,       NULL -- p_Line_Adj_rec.ac_attribute2
    ,       NULL -- p_Line_Adj_rec.ac_attribute3
    ,       NULL -- p_Line_Adj_rec.ac_attribute4
    ,       NULL -- p_Line_Adj_rec.ac_attribute5
    ,       NULL -- p_Line_Adj_rec.ac_attribute6
    ,       NULL -- p_Line_Adj_rec.ac_attribute7
    ,       NULL -- p_Line_Adj_rec.ac_attribute8
    ,       NULL -- p_Line_Adj_rec.ac_attribute9
    ,       NULL -- p_Line_Adj_rec.ac_attribute10
    ,       NULL -- p_Line_Adj_rec.ac_attribute11
    ,       NULL -- p_Line_Adj_rec.ac_attribute12
    ,       NULL -- p_Line_Adj_rec.ac_attribute13
    ,       NULL -- p_Line_Adj_rec.ac_attribute14
    ,       NULL -- p_Line_Adj_rec.ac_attribute15
    ,       ldets.OPERAND_value
    ,       ldets.adjustment_amount
    ,       1
    FROM 
         QP_LDETS_v ldets
    ,    QP_PREQ_LINES_TMP lines
    ,    QP_LIST_HEADERS_B QH
    WHERE 
         ldets.list_header_id=qh.list_header_id
    AND  ldets.process_code=QP_PREQ_GRP.G_STATUS_NEW
    AND  lines.pricing_status_code in (QP_PREQ_GRP.G_STATUS_NEW,QP_PREQ_GRP.G_STATUS_UPDATED,QP_PREQ_GRP.G_STATUS_GSA_VIOLATION)
    AND lines.process_status <> 'NOT_VALID'
    AND  ldets.line_index=lines.line_index 
    AND  ((nvl(ldets.automatic_flag,'N') = 'Y')
       OR (ldets.automatic_flag = 'N' AND ldets.applied_flag = 'Y' AND ldets.updated_flag = 'Y'))
    AND ldets.created_from_list_type_code not in ('PRL','AGR')
    AND  ldets.list_line_type_code<>'PLL'
    AND ldets.list_line_type_code<>'IUE'
);

    IF l_debug_level  > 0 THEN
        oe_debug_pub.add(  'INSERTED '||SQL%ROWCOUNT||' ADJUSTMENTS' ) ;
    END IF;

  --Insert associations

  INSERT INTO OE_PRICE_ADJ_ASSOCS
        (       PRICE_ADJUSTMENT_ID
                ,CREATION_DATE
                ,CREATED_BY
                ,LAST_UPDATE_DATE
                ,LAST_UPDATED_BY
                ,LAST_UPDATE_LOGIN
                ,PROGRAM_APPLICATION_ID
                ,PROGRAM_ID
                ,PROGRAM_UPDATE_DATE
                ,REQUEST_ID
                ,PRICE_ADJ_ASSOC_ID
                ,LINE_ID
                ,RLTD_PRICE_ADJ_ID
                ,LOCK_CONTROL
        )
        (SELECT  /*+ ORDERED USE_NL(QPL ADJ RADJ) */
                 LDET.price_adjustment_id
                ,sysdate  --p_Line_Adj_Assoc_Rec.creation_date
                ,fnd_global.user_id --p_Line_Adj_Assoc_Rec.CREATED_BY
                ,sysdate  --p_Line_Adj_Assoc_Rec.LAST_UPDATE_DATE
                ,fnd_global.user_id  --p_Line_Adj_Assoc_Rec.LAST_UPDATED_BY
                ,fnd_global.login_id  --p_Line_Adj_Assoc_Rec.LAST_UPDATE_LOGIN
                ,NULL  --p_Line_Adj_Assoc_Rec.PROGRAM_APPLICATION_ID
                ,NULL  --p_Line_Adj_Assoc_Rec.PROGRAM_ID
                ,NULL  --p_Line_Adj_Assoc_Rec.PROGRAM_UPDATE_DATE
                ,NULL  --p_Line_Adj_Assoc_Rec.REQUEST_ID
                ,OE_PRICE_ADJ_ASSOCS_S.nextval
                ,NULL
                ,RLDET.PRICE_ADJUSTMENT_ID
                ,1
        FROM
              QP_PREQ_RLTD_LINES_TMP RLTD,
              QP_PREQ_LDETS_TMP LDET,
              QP_PREQ_LDETS_TMP RLDET
        WHERE
             LDET.LINE_DETAIL_INDEX = RLTD.LINE_DETAIL_INDEX              AND
             RLDET.LINE_DETAIL_INDEX = RLTD.RELATED_LINE_DETAIL_INDEX     AND
             LDET.PRICING_STATUS_CODE = 'N' AND
             LDET.PROCESS_CODE  IN (QP_PREQ_PUB.G_STATUS_NEW,QP_PREQ_PUB.G_STATUS_UNCHANGED,QP_PREQ_PUB.G_STATUS_UPDATED)  AND
             nvl(LDET.AUTOMATIC_FLAG, 'N') = 'Y' AND
             lDET.CREATED_FROM_LIST_TYPE_CODE NOT IN ('PRL','AGR') AND
             lDET.PRICE_ADJUSTMENT_ID IS NOT NULL AND
             RLDET.PRICE_ADJUSTMENT_ID IS NOT NULL AND
             RLDET.PRICING_STATUS_CODE = 'N' AND
             RLDET.PROCESS_CODE = 'N' AND
             nvl(RLDET.AUTOMATIC_FLAG, 'N') = 'Y' AND
             -- not in might not be needed
              RLDET.PRICE_ADJUSTMENT_ID
                NOT IN (SELECT RLTD_PRICE_ADJ_ID
                       FROM   OE_PRICE_ADJ_ASSOCS
                       WHERE PRICE_ADJUSTMENT_ID = LDET.PRICE_ADJUSTMENT_ID ) AND
              RLTD.PRICING_STATUS_CODE = 'N');

      --Insert pricing attributes 
      If l_debug_level > 0 Then
         oe_debug_pub.add('after inserting assocs');
         oe_debug_pub.add('INSERTED '||SQL%ROWCOUNT||' ASSOCIATIONS');
         for i in test loop
           oe_debug_pub.add('pricing_status_code = '||i.pricing_status_code);
           oe_debug_pub.add('LINE_DETAIL_INDEX = '||i.LINE_DETAIL_INDEX);
           oe_debug_pub.add('LINE_INDEX = '||i.LINE_INDEX);
         end loop;
      end if;
      INSERT INTO OE_PRICE_ADJ_ATTRIBS
        (       PRICE_ADJUSTMENT_ID
                ,PRICING_CONTEXT
                ,PRICING_ATTRIBUTE
                ,CREATION_DATE
                ,CREATED_BY
                ,LAST_UPDATE_DATE
                ,LAST_UPDATED_BY
                ,LAST_UPDATE_LOGIN
                ,PROGRAM_APPLICATION_ID
                ,PROGRAM_ID
                ,PROGRAM_UPDATE_DATE
                ,REQUEST_ID
                ,PRICING_ATTR_VALUE_FROM
                ,PRICING_ATTR_VALUE_TO
                ,COMPARISON_OPERATOR
                ,FLEX_TITLE
                ,PRICE_ADJ_ATTRIB_ID
                ,LOCK_CONTROL
        )
        (SELECT  LDETS.PRICE_ADJUSTMENT_ID
                ,QPLAT.CONTEXT 
                ,QPLAT.ATTRIBUTE
                ,sysdate  
                ,fnd_global.user_id
                ,sysdate  
                ,fnd_global.user_id 
                ,fnd_global.login_id 
                ,NULL  
                ,NULL 
                ,NULL
                ,NULL
                ,QPLAT.SETUP_VALUE_FROM --VALUE_FROM
                ,QPLAT.SETUP_VALUE_TO   --VALUE_TO
                ,QPLAT.COMPARISON_OPERATOR_TYPE_CODE
                ,decode(QPLAT.ATTRIBUTE_TYPE, 
                        'QUALIFIER','QP_ATTR_DEFNS_QUALIFIER',
                        'QP_ATTR_DEFNS_PRICING')  
                ,OE_PRICE_ADJ_ATTRIBS_S.nextval
                ,1
          FROM QP_PREQ_LINE_ATTRS_TMP QPLAT
             , QP_LDETS_v LDETS
          WHERE QPLAT.pricing_status_code=QP_PREQ_PUB.G_STATUS_NEW
            AND QPLAT.LINE_DETAIL_INDEX = LDETS.LINE_DETAIL_INDEX
            AND QPLAT.LINE_INDEX = LDETS.LINE_INDEX
            AND LDETS.PROCESS_CODE=QP_PREQ_PUB.G_STATUS_NEW
            AND LDETS.AUTOMATIC_FLAG = 'Y'
            AND LDETS.CREATED_FROM_LIST_TYPE_CODE NOT IN ('PRL','AGR')
         );


   IF l_debug_level  > 0 THEN
       oe_debug_pub.add(  'INSERTED '||SQL%ROWCOUNT||' PRICE ADJ ATTRIBS' , 3 ) ;
   END IF;

Exception
WHEN OTHERS THEN
  IF l_debug_level > 0 THEN
     oe_debug_pub.add('ERROR in inserting adjustments and associations'||sqlerrm);
  END IF;
  Raise FND_API.G_EXC_ERROR;
END Insert_Adj;





/**************************************************************************************************
Procedure Update_Global_Line
This procedure updates global line table based on lastest price info from qp table
**************************************************************************************************/

Procedure Update_Global_Line As
Cursor valid_lines Is
select 
      lines.order_uom_selling_price     UNIT_SELLING_PRICE
    , lines.line_unit_price             UNIT_LIST_PRICE
    , lines.ADJUSTED_UNIT_PRICE         UNIT_SELLING_PRICE_PER_PQTY
    , lines.UNIT_PRICE                  UNIT_LIST_PRICE_PER_PQTY
    , lines.priced_quantity             PRICING_QUANTITY
    , lines.priced_uom_code             PRICING_QUANTITY_UOM
    , lines.price_list_header_id        PRICE_LIST_ID
    , lines.price_request_code          PRICE_REQUEST_CODE
    , nvl(lines.percent_price, NULL)    UNIT_LIST_PERCENT
    , nvl(lines.parent_price, NULL)     UNIT_PERCENT_BASE_PRICE
    , decode(lines.parent_price, NULL, 0, 0, 0,
           lines.adjusted_unit_price/lines.parent_price)
                                        UNIT_SELLING_PERCENT
    , lines.line_index                  line_index
from qp_preq_lines_tmp lines
     where lines.line_type_code='LINE'
     and lines.pricing_status_code in (QP_PREQ_GRP.G_STATUS_UPDATED, QP_PREQ_GRP.G_STATUS_GSA_VIOLATION)
     and lines.process_status <> 'NOT_VALID';

l_ordered_quantity Number;
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

Begin
 If l_debug_level > 0 Then
    oe_debug_pub.add('inside update_global_line'); 
 end if;
 For valid in valid_lines Loop

   l_ordered_quantity:=OE_BULK_ORDER_PVT.G_Line_Rec.Ordered_Quantity(valid.line_index);

   OE_BULK_ORDER_PVT.G_Line_Rec.Unit_Selling_Price(valid.line_index):=
    nvl(valid.unit_selling_price, valid.unit_selling_price_per_pqty*nvl(valid.pricing_quantity,l_ordered_quantity)/l_ordered_quantity);

   OE_BULK_ORDER_PVT.G_Line_Rec.Unit_List_Price(valid.line_index):=
   nvl(valid.UNIT_LIST_PRICE, valid.unit_list_price_per_pqty*nvl(valid.pricing_quantity,l_ordered_quantity)/l_ordered_quantity);

  OE_BULK_ORDER_PVT.G_Line_Rec.Unit_Selling_Price_Per_Pqty(valid.line_index):= valid.Unit_Selling_Price_Per_PQTY;

  OE_BULK_ORDER_PVT.G_Line_Rec.Unit_List_Price_Per_Pqty(valid.line_index):=valid.Unit_List_Price_Per_Pqty;

  If valid.pricing_quantity <> -99999 Then
    OE_BULK_ORDER_PVT.G_Line_Rec.Pricing_Quantity(valid.line_index):=valid.pricing_quantity;
    OE_BULK_ORDER_PVT.G_Line_Rec.Pricing_QUantity_Uom(Valid.line_index):=valid.pricing_quantity_uom;
  Else   ---99999 no conversion, set pricing and order uom to same 
    OE_BULK_ORDER_PVT.G_Line_Rec.Pricing_Quantity(valid.line_index):=l_ordered_quantity;
    OE_BULK_ORDER_PVT.G_Line_Rec.Pricing_QUantity_Uom(Valid.line_index):=OE_BULK_ORDER_PVT.G_Line_Rec.Order_Quantity_Uom(Valid.line_index);
  End If;

  If valid.price_list_id <> -9999 Then
    OE_BULK_ORDER_PVT.G_Line_Rec.Price_List_Id(Valid.line_index):=Valid.Price_List_Id;
  Else
    OE_BULK_ORDER_PVT.G_Line_Rec.Price_List_Id(Valid.line_index):=NULL;
  End If;

 -- OE_BULK_ORDER_PVT.G_Line_Rec.Price_Request_Code(Valid.line_index):=Valid.Price_Request_Code;
  OE_BULK_ORDER_PVT.G_Line_Rec.Unit_List_Percent(Valid.line_index):=Valid.Unit_List_Percent;
  OE_BULK_ORDER_PVT.G_Line_Rec.Unit_Percent_Base_Price(Valid.line_index):=Valid.Unit_Percent_Base_Price;
  OE_BULK_ORDER_PVT.G_Line_Rec.Unit_Selling_Percent(Valid.line_index):=Valid.Unit_Selling_Percent;

 End Loop;
End;

PROCEDURE Booking_Failed(p_index        IN            NUMBER,
                         p_header_rec   IN OUT NOCOPY OE_BULK_ORDER_PVT.HEADER_REC_TYPE)
IS
l_start_index  BINARY_INTEGER;
BEGIN
    -- Update DB values
    UPDATE OE_ORDER_LINES
    SET booked_flag = 'N' 
    ,flow_status_code = 'ENTERED'
    WHERE header_id = p_header_rec.header_id(p_index);

    UPDATE OE_ORDER_HEADERS 
    SET booked_flag = 'N' 
       ,booked_date = NULL
       ,flow_status_code = 'ENTERED'
    WHERE header_id = p_header_rec.header_id(p_index);

    -- Also, delete from DBI tables if booking fails
    IF OE_BULK_ORDER_PVT.G_DBI_INSTALLED = 'Y' THEN
       DELETE FROM ONT_DBI_CHANGE_LOG
       WHERE header_id = p_header_rec.header_id(p_index);
    END IF;

    -- Un-set booking fields on global records
    p_header_rec.booked_flag(p_index) := 'N';
    l_start_index := 1;

    /*FOR l_index IN l_start_index..OE_Bulk_Order_PVT.G_LINE_REC.HEADER_ID.COUNT LOOP
        IF OE_Bulk_Order_PVT.G_LINE_REC.header_id(l_index) = p_header_rec.header_id(p_index)
        THEN
            OE_Bulk_Order_PVT.G_LINE_REC.booked_flag(l_index) := 'N';
        ELSIF OE_Bulk_Order_PVT.G_LINE_REC.header_id(l_index) > 
               p_header_rec.header_id(p_index) 
        THEN
            l_start_index := l_index;
            EXIT;
        END IF;
    END LOOP;*/

END Booking_Failed;


/**************************************************************************************************
PROCEDURE Credit_Check
1.  OE_BULK_HEADER_UTIL.Insert_Headers will always insert booked_flag = 'N' for the header.
2.  The g_header_rec memory always contains the correct booked_flag.
3.  Before process acknowledgment, we call credit_check
4.  Credit_Check will  one by one loop through the G_HEADER_REC updates the db header book_flag as 'BOOKED' and then perform the credit check for each order
****************************************************************************************************/
PROCEDURE Credit_Check (p_header_rec IN OUT NOCOPY OE_BULK_ORDER_PVT.HEADER_REC_TYPE) As
 l_msg_count Number;
 l_msg_data Varchar2(2000);
 l_return_status Varchar2(30);
 l_header_id     number;
 l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

Begin
 l_return_status:= FND_API.G_RET_STS_SUCCESS;

  If l_debug_level > 0 Then
    oe_debug_pub.add('Entering OE_BULK_PRICEORDER_PVT.credit_check');
  End If;
  
 For i IN 1..p_header_rec.header_id.count Loop

  l_header_id := p_header_rec.header_id(i);
  If p_header_rec.booked_flag(i) = 'Y' Then
   Begin

      -- Update the booked flag only if real Time CC is required
      -- else the booked_flag is already set on the record
      IF OE_BULK_ORDER_PVT.G_REALTIME_CC_REQUIRED = 'Y' THEN
       update oe_order_headers_all set booked_flag = 'Y'
       where  header_id = p_header_rec.header_id(i);
      END IF;

        IF OE_BULK_CACHE.IS_CC_REQUIRED(p_header_rec.order_type_id(i))
            THEN
	      If l_debug_level > 0 Then
                oe_debug_pub.add(' Calling OE_Verify_Payment_PUB.Verify_Payment');
              End If;
	      
              OE_Verify_Payment_PUB.Verify_Payment
                            ( p_header_id      => l_header_id
                             , p_calling_action => 'UPDATE'
                             , p_delayed_request=> FND_API.G_TRUE
                             , p_msg_count      => l_msg_count
                             , p_msg_data       => l_msg_data
                             , p_return_status  => l_return_status);
	      
	       If l_return_status <>  FND_API.G_RET_STS_SUCCESS Then
                 oe_debug_pub.add('Verify payment returns status errors:'||l_msg_data);
                 l_return_status := FND_API.G_RET_STS_SUCCESS;
                 Booking_Failed(i,p_header_rec);
               End If;
        End IF;
   
   Exception
     When no_data_found Then
       oe_debug_pub.add('Header Id:'|| p_header_rec.header_id(i) || 'not exists in DB');
     When others Then
       oe_debug_pub.add('Errors occured when restoring the book flag:'||SQLERRM);
   End;
 
  End If;
 End Loop;
 
     If l_debug_level > 0 Then
       oe_debug_pub.add('Leaving OE_BULK_PRICEORDER_PVT.credit_checking');
     End If;
End;


Procedure set_calc_flag_incl_item(p_line_rec            IN OUT NOCOPY OE_WSH_BULK_GRP.LINE_REC_TYPE
,                                               p_index    Number) Is

   l_calculate_flag varchar2(1);
Begin

    IF p_line_rec.calculate_price_flag(p_index) in ( 'Y', 'P' )
    Then
        If ( G_CHARGES_FOR_INCLUDED_ITEM = 'N')
        Then
            l_calculate_flag := 'N';
        Else
            l_calculate_flag := 'P';
        End If;
    Else
        l_calculate_flag := 'N';
    End IF;
    p_line_rec.calculate_price_flag(p_index) := l_calculate_flag;
End;



/****************************************************************************************************
PROCEDURE Unbook_Order
This procedure will mark (in memory) order and all the lines including included items underneath the lines as UNBOOKED. If the order_header is already unbook, it will return immediately. Otherwise 
It will iterate up and down from the current line_index position and mark the line as unbooked until
the header_index changes. While iterating, if it is a 'KIT' line then we will need to mark included item lines as unbook also. To do that, we should start from global_line_rec.ii_start_index and iterate until ii_start_index + ii_count - 1
******************************************************************************************************/
Procedure Unbook_Order(p_header_index IN Number,
                       p_line_index   IN Number) As
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
l_index                number;
Begin
  If l_debug_level > 0 Then
   oe_debug_pub.add('inside Unbook_Order');
   oe_debug_pub.add('p_header_index = '||p_header_index);
   oe_debug_pub.add('p_line_index = '||p_line_index);
  End if;

 If p_header_index Is Null Then
  If l_debug_level > 0 Then
     oe_debug_pub.add('Header index is null, unable to proceed. Returning');
  end if;
  Return;
 End If;

 If l_debug_level > 0 Then
  oe_debug_pub.add('before checking Booked_Flag');
  oe_debug_pub.add('Booked_Flag = '||OE_Bulk_Order_Pvt.G_Header_Rec.Booked_Flag(p_header_index));
  oe_debug_pub.add('after printing Booked_Flag');
 end if;
 If OE_Bulk_Order_Pvt.G_Header_Rec.Booked_Flag(p_header_index) = 'N' Then
   If l_debug_level > 0 Then
     Oe_Debug_Pub.add('Order has been unbooked, no further unbook action is needed');
   End If;
   RETURN;
 End If;

 If OE_Bulk_Order_Pvt.G_Header_Rec.Booked_Flag(p_header_index) = 'Y' Then
   OE_Bulk_Order_Pvt.G_Header_Rec.Booked_Flag(p_header_index):='N';
   If p_line_index Is Not NULL Then
     --First unbook the line, then move the pointer up and unbook the line until header_index changes.
     --Then move the pointer down from the p_line_index and unblook the line until header_index changes
     OE_BULK_ORDER_PVT.G_Line_Rec.Booked_Flag(p_line_index):='N';
      
     l_index := p_line_index;

     While l_index > 0 Loop

       If l_debug_level > 0 Then
          oe_debug_pub.add('in the while loop');
       end if;
       OE_BULK_ORDER_PVT.G_Line_Rec.Booked_Flag(l_index) := 'N';

       If  OE_BULK_ORDER_PVT.G_Line_Rec.item_type_code(l_index) = 'KIT' Then
         Unbook_Included_Item(p_start_index=> OE_BULK_ORDER_PVT.G_Line_Rec.ii_start_index(l_index),
                              p_count => OE_BULK_ORDER_PVT.G_Line_Rec.ii_count(l_index));
       End If;
       If l_debug_level > 0 Then
          oe_debug_pub.add('after checking item_type_code');
       end if;
       If l_index <> 1 Then
          If  OE_BULK_ORDER_PVT.G_Line_Rec.Header_Index(l_index) <>
              OE_BULK_ORDER_PVT.G_Line_Rec.Header_Index(l_index-1) 
          Then
              Exit;
          End If;
       End If;

       l_index := l_index - 1;
     End Loop;

     l_index := p_line_index;

     While l_index <= OE_BULK_ORDER_PVT.G_Line_Rec.Line_Id.Count Loop

       OE_BULK_ORDER_PVT.G_Line_Rec.Booked_Flag(l_index) := 'N';
       
       If  OE_BULK_ORDER_PVT.G_Line_Rec.item_type_code(l_index) = 'KIT' Then
         Unbook_Included_Item(p_start_index=> OE_BULK_ORDER_PVT.G_Line_Rec.ii_start_index(l_index),
                              p_count => OE_BULK_ORDER_PVT.G_Line_Rec.ii_count(l_index));
       End If;
 

       IF l_index <> OE_BULK_ORDER_PVT.G_Line_Rec.Line_Id.Count Then
          If  OE_BULK_ORDER_PVT.G_Line_Rec.Header_Index(l_index) <>
              OE_BULK_ORDER_PVT.G_Line_Rec.Header_Index(l_index+1) Then 
             Exit;
          End If;
       End If;

       l_index := l_index + 1;
     End Loop;
   Else
    If l_debug_level > 0 Then
       oe_debug_pub.add('Line index is null, unable to unbook line');
    End If;
   End If;

 End If;

End;


--This procedure need to insert adj from interface table and put it into
--QP_TEMP_TABLE. Now qp is providing an api for that
Procedure Insert_Adjs_From_Iface
(p_batch_id      IN  NUMBER, 
 x_return_status OUT NOCOPY VARCHAR2) AS
BEGIN
 null;
END;



Function Get_List_Lines (p_line_id Number) Return Varchar2 As
 Cursor list_lines_no is
 Select c.name,
        a.list_line_no
 From   qp_preq_ldets_tmp a,
        qp_preq_lines_tmp b,
        qp_list_headers_vl c
 Where  b.line_id = p_line_id
 And    b.line_index = a.line_index
 And    a.created_from_list_header_id = c.list_header_id
 And    a.automatic_flag = 'Y'
 And    a.pricing_status_code = 'N'
 And    b.process_status <> 'NOT_VALID'
 And    a.created_from_list_line_type <> 'PLL';

 l_list_line_nos Varchar2(2000):=' ';
 l_separator Varchar2(1):='';
 --
 l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
 --
Begin
 For i in List_Lines_no Loop
   l_list_line_nos := i.name||':'||i.list_line_no||l_separator||l_list_line_nos;
   l_separator := ',';
 End Loop;
 Return l_list_line_nos;
End Get_List_Lines;




/*********************************************************************
Procedure: Check_Errors.
Purpose : Check for errors return by pricing. Post it messaging table.
          Hold the line if it violates GSA rule. Unbooked all the lines, and included items
          underneath the KIT if errors.
OUTPUT:  
***********************************************************************/

Procedure Check_Errors As
l_allow_negative_price		Varchar2(30) := nvl(fnd_profile.value('ONT_NEGATIVE_PRICING'),'N');
l_has_errors Boolean := False;
--l_GSA_Enabled_Flag 	Varchar2(30) := FND_PROFILE.VALUE('QP_VERIFY_GSA');
--l_gsa_violation_action Varchar2(30) := nvl(fnd_profile.value('ONT_GSA_VIOLATION_ACTION'), 'WARNING');
l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
l_invalid_line      varchar2(1);
l_request_id        number;
l_price_list                            Varchar2(240);
l_msg_text                              Varchar2(200);

cursor wrong_lines is
  select   qp.line_id
         , qp.line_index
         , qp.line_type_code
         , qp.processed_code
         , qp.pricing_status_code
         , qp.PRICING_STATUS_TEXT STATUS_TEXT
         , qp.unit_price
         , qp.adjusted_unit_price
         , qp.priced_quantity
         , qp.line_quantity
         , qp.priced_uom_code
   from qp_preq_lines_tmp qp
   where process_status <> 'NOT_VALID' and
     (pricing_status_code not in 
     (QP_PREQ_GRP.G_STATUS_UNCHANGED,
      QP_PREQ_GRP.G_STATUS_UPDATED, 
      QP_PREQ_GRP.G_STATUS_GSA_VIOLATION,  --uncommented for bug 3716296
      'NOT_VALID') 
  OR (l_allow_negative_price = 'N' AND (unit_price<0 OR adjusted_unit_price<0)));
 -- and l.line_id = qp.line_id;

    l_header_id                NUMBER;
    l_order_source_id          Number;
    l_orig_sys_document_ref    Varchar2(50);
    l_orig_sys_line_ref        Varchar2(50);
    l_orig_sys_shipment_ref    Varchar2(50);
    l_change_sequence          Varchar2(50);
    l_source_document_type_id  Number;
    l_source_document_id       Number;
    l_source_document_line_id  Number;
    l_booked_flag              Varchar2(1);
    l_item_type_code           Varchar2(30);
    l_line_category_code       Varchar2(30);
    l_calculate_price_flag     Varchar2(1);
    l_top_model_line_id        Number;   
    l_ordered_item             Varchar2(2000);
    l_order_quantity_uom       Varchar2(3);
    l_price_list_id            Number;
    l_inventory_item_id        Number;
    l_line_count               Number := OE_BULK_ORDER_PVT.G_LINE_REC.line_id.count;
     
Begin

   If l_debug_level > 0 Then
     oe_debug_pub.add('inside check_errors');
   end if;
   OE_BULK_ORDER_PVT.G_Line_Rec.source_document_type_id.extend(l_line_count);
   OE_BULK_ORDER_PVT.G_Line_Rec.source_document_line_id.extend(l_line_count);

   For wrong_line in wrong_lines loop 
    if l_debug_level > 0 Then
      oe_debug_pub.add('inside wrong_line loop');
      oe_debug_pub.add('line_index = '||wrong_line.line_index);	
    end if;

    l_header_id := OE_BULK_ORDER_PVT.G_Line_Rec.header_id(wrong_line.line_index);
     l_order_source_id := OE_BULK_ORDER_PVT.G_Line_Rec.order_source_id(wrong_line.line_index);
     l_orig_sys_document_ref := OE_BULK_ORDER_PVT.G_Line_Rec.orig_sys_document_ref(wrong_line.line_index);
     l_orig_sys_line_ref := OE_BULK_ORDER_PVT.G_Line_Rec.orig_sys_line_ref(wrong_line.line_index);
     l_orig_sys_shipment_ref := OE_BULK_ORDER_PVT.G_Line_Rec.orig_sys_shipment_ref(wrong_line.line_index);
     l_change_sequence := OE_BULK_ORDER_PVT.G_Line_Rec.change_sequence(wrong_line.line_index);
     l_source_document_type_id := OE_BULK_ORDER_PVT.G_Line_Rec.source_document_type_id(wrong_line.line_index);
     l_source_document_id := OE_BULK_ORDER_PVT.G_Line_Rec.source_document_id(wrong_line.line_index);
     l_source_document_line_id := OE_BULK_ORDER_PVT.G_Line_Rec.source_document_line_id(wrong_line.line_index);
     l_booked_flag := OE_BULK_ORDER_PVT.G_Line_Rec.booked_flag(wrong_line.line_index);
     l_item_type_code := OE_BULK_ORDER_PVT.G_Line_Rec.item_type_code(wrong_line.line_index);
     l_line_category_code := OE_BULK_ORDER_PVT.G_Line_Rec.line_category_code(wrong_line.line_index);
     l_calculate_price_flag := OE_BULK_ORDER_PVT.G_Line_Rec.calculate_price_flag(wrong_line.line_index);
     l_top_model_line_id := OE_BULK_ORDER_PVT.G_Line_Rec.top_model_line_id(wrong_line.line_index);
     l_order_quantity_uom := OE_BULK_ORDER_PVT.G_Line_Rec.order_quantity_uom(wrong_line.line_index);
     l_price_list_id := OE_BULK_ORDER_PVT.G_Line_Rec.price_list_id(wrong_line.line_index);
     l_inventory_item_id := OE_BULK_ORDER_PVT.G_Line_Rec.inventory_item_id(wrong_line.line_index);


     If l_debug_level > 0 Then oe_debug_pub.add('before set_msg_context'); end if;
     
     OE_BULK_MSG_PUB.set_msg_context
      			( p_entity_code                => 'LINE'
         		,p_entity_id                   => wrong_line.line_id 
         		,p_header_id                   => l_header_id 
         		,p_line_id                     => wrong_line.line_id
                ,p_order_source_id             => l_order_source_id
                ,p_orig_sys_document_ref       => l_orig_sys_document_ref
                ,p_orig_sys_document_line_ref  => l_orig_sys_line_ref
                ,p_orig_sys_shipment_ref       => l_orig_sys_shipment_ref
                ,p_change_sequence             => l_change_sequence
                ,p_source_document_type_id     => l_source_document_type_id
                ,p_source_document_id          => l_source_document_id
                ,p_source_document_line_id     => l_source_document_line_id
         		);		

	IF l_debug_level  > 0 THEN
	    oe_debug_pub.add(  'THE STATUS'||WRONG_LINE.PRICING_STATUS_CODE||':'||WRONG_LINE.PROCESSED_CODE||':'||WRONG_LINE.STATUS_TEXT ) ;
	END IF;

        l_invalid_line := 'N';
     -- add message when the price list is found to be inactive
	IF wrong_line.line_Type_code ='LINE' and 
	   wrong_line.processed_code = QP_PREQ_GRP.G_STS_LHS_NOT_FOUND 
        Then

   	    IF l_debug_level  > 0 THEN oe_debug_pub.add(  'PRICE LIST NOT FOUND1' ) ; END IF;

  	  FND_MESSAGE.SET_NAME('ONT','ONT_NO_PRICE_LIST_FOUND');
	  FND_MESSAGE.SET_TOKEN('ITEM',nvl(l_Ordered_Item,l_inventory_item_id));
	  FND_MESSAGE.SET_TOKEN('UOM',l_Order_Quantity_uom);
          OE_BULK_MSG_PUB.Add; 
          l_invalid_line := 'Y';
        END IF;

	If wrong_line.line_Type_code ='LINE' and 
  	  wrong_line.pricing_status_code in ( QP_PREQ_GRP.G_STATUS_INVALID_PRICE_LIST,
				QP_PREQ_GRP.G_STS_LHS_NOT_FOUND,
				QP_PREQ_GRP.G_STATUS_FORMULA_ERROR,
				QP_PREQ_GRP.G_STATUS_OTHER_ERRORS,
				FND_API.G_RET_STS_UNEXP_ERROR,
				FND_API.G_RET_STS_ERROR,
				QP_PREQ_GRP.G_STATUS_CALC_ERROR,
				QP_PREQ_GRP.G_STATUS_UOM_FAILURE,
				QP_PREQ_GRP.G_STATUS_INVALID_UOM,
				QP_PREQ_GRP.G_STATUS_DUP_PRICE_LIST,
				QP_PREQ_GRP.G_STATUS_INVALID_UOM_CONV,
				QP_PREQ_GRP.G_STATUS_INVALID_INCOMP,
				QP_PREQ_GRP.G_STATUS_BEST_PRICE_EVAL_ERROR)
                                --bug 3716296QP_PREQ_GRP.G_STATUS_GSA_VIOLATION)
	Then

                 l_invalid_line := 'Y';
		 Begin 
			Select name into l_price_list 
			from qp_list_headers_vl where
			list_header_id = l_price_list_id;
			Exception When No_data_found then
			l_price_list := l_price_list_id;
		 End;

		 If wrong_line.pricing_status_code  = QP_PREQ_GRP.G_STATUS_INVALID_PRICE_LIST then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'INVALID ITEM/PRICE LIST COMBINATION'||l_ORDERED_ITEM||l_ORDER_QUANTITY_UOM||L_PRICE_LIST ) ;
                         null;
		 	END IF;

		 	FND_MESSAGE.SET_NAME('ONT','OE_PRC_NO_LIST_PRICE');
		 	FND_MESSAGE.SET_TOKEN('ITEM',nvl(l_Ordered_Item,l_inventory_item_id));
		 	FND_MESSAGE.SET_TOKEN('UNIT',l_Order_Quantity_uom);
		 	FND_MESSAGE.SET_TOKEN('PRICE_LIST',l_Price_List);

                        OE_BULK_MSG_PUB.ADD;
      

		Elsif wrong_line.pricing_status_code = QP_PREQ_GRP.G_STS_LHS_NOT_FOUND Then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'PRICE LIST NOT FOUND' ) ;
		 	END IF;
		 	FND_MESSAGE.SET_NAME('ONT','ONT_NO_PRICE_LIST_FOUND');
		 	FND_MESSAGE.SET_TOKEN('ITEM',nvl(l_Ordered_Item,l_inventory_item_id));
		 	FND_MESSAGE.SET_TOKEN('UOM',l_Order_Quantity_uom);
		  	OE_BULK_MSG_PUB.Add;

		Elsif wrong_line.pricing_status_code = QP_PREQ_GRP.G_STATUS_FORMULA_ERROR then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'ERROR IN FORMULA PROCESSING' ) ;
		 	END IF;
		 	FND_MESSAGE.SET_NAME('ONT','ONT_PRC_ERROR_IN_FORMULA');
		 	FND_MESSAGE.SET_TOKEN('ERR_TEXT',wrong_line.status_text);
   	                OE_BULK_MSG_PUB.Add;
  
		Elsif wrong_line.pricing_status_code in 
				( QP_PREQ_GRP.G_STATUS_OTHER_ERRORS , FND_API.G_RET_STS_UNEXP_ERROR,
						FND_API.G_RET_STS_ERROR)
		then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'OTHER ERRORS PROCESSING' ) ;
		 	END IF;
		 	FND_MESSAGE.SET_NAME('ONT','ONT_PRICING_ERROR');
		 	FND_MESSAGE.SET_TOKEN('ERR_TEXT',wrong_line.status_text);
		  	OE_BULK_MSG_PUB.Add;

		Elsif wrong_line.pricing_status_code = QP_PREQ_GRP.G_STATUS_INVALID_UOM then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'INVALID UOM' ) ;
		 	END IF;
		 	FND_MESSAGE.SET_NAME('ONT','ONT_PRC_INVALID_UOM');
			FND_MESSAGE.SET_TOKEN('ITEM',nvl(l_Ordered_Item,l_inventory_item_id));
		 	FND_MESSAGE.SET_TOKEN('UOM',l_Order_Quantity_uom);
		  	OE_BULK_MSG_PUB.Add;
		Elsif wrong_line.pricing_status_code = QP_PREQ_GRP.G_STATUS_DUP_PRICE_LIST then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'DUPLICATE PRICE LIST' ) ;
		 	END IF;
		 	FND_MESSAGE.SET_NAME('ONT','ONT_PRC_DUPLICATE_PRICE_LIST');

		 	Begin 
				Select name into l_price_list 
				from qp_list_headers_vl a,qp_list_lines b where
				b.list_line_id =  to_number(substr(wrong_line.status_text,1,
									instr(wrong_line.status_text,',')-1))
				and a.list_header_id=b.list_header_id 
				;
				Exception When No_data_found then
				l_price_list := to_number(substr(wrong_line.status_text,1,
								instr(wrong_line.status_text,',')-1));
				When invalid_number then
				l_price_list := substr(wrong_line.status_text,1,
								instr(wrong_line.status_text,',')-1);
					
		 	End;

		 	FND_MESSAGE.SET_TOKEN('PRICE_LIST1',
                      '( '||l_Ordered_Item||' ) '||l_price_list);
                 



		 	Begin 
				Select name into l_price_list 
				from qp_list_headers_vl a,qp_list_lines b where
				b.list_line_id =  
                     to_number(substr(wrong_line.status_text,
                         instr(wrong_line.status_text,',')+1))
				and a.list_header_id=b.list_header_id	;
				Exception When No_data_found then
				l_price_list := to_number(substr(wrong_line.status_text,
						instr(wrong_line.status_text,',')+1));
				When invalid_number then
				l_price_list := substr(wrong_line.status_text,
								instr(wrong_line.status_text,',')+1);
		 	End;

		 	FND_MESSAGE.SET_TOKEN('PRICE_LIST2',l_price_list);
 	  	        OE_BULK_MSG_PUB.Add;

		Elsif wrong_line.pricing_status_code = QP_PREQ_GRP.G_STATUS_INVALID_UOM_CONV then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'INVALID UOM CONVERSION' ) ;
		 	END IF;
		 	FND_MESSAGE.SET_NAME('ONT','ONT_PRC_INVALID_UOM_CONVERSION');
			FND_MESSAGE.SET_TOKEN('UOM_TEXT','( '||l_Ordered_Item||' ) '||
													wrong_line.status_text); 
		  	OE_BULK_MSG_PUB.Add;


		Elsif wrong_line.pricing_status_code = QP_PREQ_GRP.G_STATUS_INVALID_INCOMP then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'UNABLE TO RESOLVE INCOMPATIBILITY' ) ;
		 	END IF;
		 	FND_MESSAGE.SET_NAME('ONT','ONT_PRC_INVALID_INCOMP');
		 	FND_MESSAGE.SET_TOKEN('ERR_TEXT','( '||
                        l_Ordered_Item||' ) '||wrong_line.status_text);
                 
		  	OE_BULK_MSG_PUB.Add;

		Elsif wrong_line.pricing_status_code = QP_PREQ_GRP.G_STATUS_BEST_PRICE_EVAL_ERROR then
		 	IF l_debug_level  > 0 THEN
		 	    oe_debug_pub.add(  'ERROR WHILE EVALUATING THE BEST PRICE' ) ;
		 	END IF;
		 	FND_MESSAGE.SET_NAME('ONT','ONT_PRC_BEST_PRICE_ERROR');
		        FND_MESSAGE.SET_TOKEN('ITEM',nvl(l_Ordered_Item,l_inventory_item_id));
		 	FND_MESSAGE.SET_TOKEN('ERR_TEXT',wrong_line.status_text);
  
		  	OE_BULK_MSG_PUB.Add;
                  --bug 3716296
              /*  Elsif wrong_line.pricing_status_code = QP_PREQ_GRP.G_STATUS_GSA_VIOLATION THEN
                       IF  (l_GSA_Enabled_Flag = 'Y') THEN
                         IF l_gsa_violation_action = 'WARNING' THEN
                           FND_MESSAGE.SET_NAME('ONT','OE_GSA_VIOLATION');
	                   l_msg_text := wrong_line.status_text||' ( '||nvl(l_ordered_item,l_inventory_item_id)||' )';
	                   FND_MESSAGE.SET_TOKEN('GSA_PRICE',l_msg_text);
	                   OE_BULK_MSG_PUB.Add;
			   
                           IF l_debug_level  > 0 THEN
                            oe_debug_pub.add(' GSA warning occured on line_id:'||wrong_line.line_id);
                           END IF;
                         ELSE  --violation action is error
                           FND_MESSAGE.SET_NAME('ONT','OE_GSA_HOLD_APPLIED');
	                   OE_BULK_MSG_PUB.Add;
                           -- Apply GSA Hold
                           OE_Bulk_Holds_Pvt.Apply_GSA_Hold
                             (p_header_id         => l_header_id,
                              p_line_id           => wrong_line.line_id,
                              p_line_number       => NULL,
                              p_hold_id           => G_SEED_GSA_HOLD_ID,
                              p_ship_set_name     => NULL,
                              p_arrival_set_name  => NULL,
                              p_activity_name     => NULL,
                              p_attribute         => NULL,
                              p_top_model_line_id => l_top_model_line_id );
                           IF l_debug_level  > 0 THEN
                            oe_debug_pub.add(' GSA Hold applied on line_id:'||wrong_line.line_id);
                           END IF;
                         END IF;                 
                       ELSE
                         IF l_debug_level  > 0 THEN oe_debug_pub.add(' GSA check is disabled'); END If;
                       END IF;
          --bug 3716296    */
	      END IF;
        End if;



	 --Pricing does not return error status but returns negative price.
        IF wrong_line.line_type_code='LINE' and
        (wrong_line.unit_price <0 or wrong_line.adjusted_unit_price<0) 
        Then

		 FND_MESSAGE.SET_NAME('ONT','ONT_NEGATIVE_PRICE');
		 FND_MESSAGE.SET_TOKEN('ITEM',nvl(l_Ordered_Item,l_inventory_item_id));
		 FND_MESSAGE.SET_TOKEN('LIST_PRICE',wrong_line.unit_price);
		 FND_MESSAGE.SET_TOKEN('SELLING_PRICE',wrong_line.Adjusted_unit_price);
		  OE_BULK_MSG_PUB.Add;

                 FND_MESSAGE.SET_NAME('ONT','ONT_NEGATIVE_MODIFIERS');
                 FND_MESSAGE.SET_TOKEN('LIST_LINE_NO',get_list_lines(wrong_line.line_id));
                 OE_BULK_MSG_PUB.Add;

                  IF l_debug_level  > 0 THEN
                       oe_debug_pub.add(  'NEGATIVE LIST PRICE '||WRONG_LINE.UNIT_PRICE ||'OR SELLING PRICE '||WRONG_LINE.ADJUSTED_UNIT_PRICE ) ;
                       oe_debug_pub.add(  'MODIFIERS:'||GET_LIST_LINES ( WRONG_LINE.LINE_ID ) ) ;
                   END IF;
               
		 RAISE FND_API.G_EXC_ERROR;
         END IF;
	 
		 
        IF l_debug_level  > 0 THEN oe_debug_pub.add('before checking l_invalid_line'); END IF;
     
     If l_invalid_line = 'Y' Then
        --we need to unbook the order and all the lines and included under this order
        --first check if the header is already has been unbooked, if yes, we would
        --assume all the lines have already been unbooked. If 'NO', unbook the header
        --and all the lines including included under this order.
        --we can use header_index.  
        Unbook_Order(OE_BULK_ORDER_PVT.G_Line_Rec.Header_Index(wrong_line.line_index),wrong_line.line_index);
	
        If l_debug_level > 0 Then oe_debug_pub.add('after call to Unbook_Order'); END IF;
     Else
        l_invalid_line:='N';
     End If;

  END loop;  /* wrong_lines cursor */



End;


--bug 3716296
PROCEDURE Check_Gsa
IS

  l_GSA_Enabled_Flag     Varchar2(30) := FND_PROFILE.VALUE('QP_VERIFY_GSA');
  l_gsa_violation_action Varchar2(30) := nvl(fnd_profile.value('ONT_GSA_VIOLATION_ACTION'), 'WARNING');
  l_ordered_item         Varchar2(2000);
  l_inventory_item_id    Number;
  l_msg_text             Varchar2(200);
  l_top_model_line_id    Number;
  l_header_id            Number;
  l_order_source_id      Number;
  l_orig_sys_document_ref Varchar2(50);
  l_orig_sys_line_ref     Varchar2(50);
  l_orig_sys_shipment_ref Varchar2(50);
  l_change_sequence       Varchar2(50);
  l_source_document_type_id  Number;
  l_source_document_id    Number;
  l_source_document_line_id  Number;
  l_return_status         Varchar2(1);
  l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;

  CURSOR gsa_violators IS
  SELECT line_id, PRICING_STATUS_TEXT status_text, line_index
  FROM QP_PREQ_LINES_TMP
  WHERE LINE_TYPE_CODE='LINE'
    AND PROCESS_STATUS <> 'NOT_VALID'
    AND PRICING_STATUS_CODE = QP_PREQ_GRP.G_STATUS_GSA_VIOLATION;
BEGIN
  IF l_debug_level  > 0 THEN
    oe_debug_pub.add('inside check gsa');
  END IF;
  for i in gsa_violators loop
    l_inventory_item_id := OE_BULK_ORDER_PVT.G_Line_Rec.inventory_item_id(i.line_index);
    l_header_id := OE_BULK_ORDER_PVT.G_Line_Rec.header_id(i.line_index);
    l_top_model_line_id := OE_BULK_ORDER_PVT.G_Line_Rec.top_model_line_id(i.line_index);
    If l_debug_level > 0 Then
      oe_debug_pub.add('before set_msg_context');
    end if;

    l_order_source_id := OE_BULK_ORDER_PVT.G_Line_Rec.order_source_id(i.line_index);
    l_orig_sys_document_ref := OE_BULK_ORDER_PVT.G_Line_Rec.orig_sys_document_ref(i.line_index);
    l_orig_sys_line_ref := OE_BULK_ORDER_PVT.G_Line_Rec.orig_sys_line_ref(i.line_index);
    l_orig_sys_shipment_ref := OE_BULK_ORDER_PVT.G_Line_Rec.orig_sys_shipment_ref(i.line_index);
    l_change_sequence := OE_BULK_ORDER_PVT.G_Line_Rec.change_sequence(i.line_index);
    l_source_document_type_id := OE_BULK_ORDER_PVT.G_Line_Rec.source_document_type_id(i.line_index);
    l_source_document_id := OE_BULK_ORDER_PVT.G_Line_Rec.source_document_id(i.line_index);
    l_source_document_line_id := OE_BULK_ORDER_PVT.G_Line_Rec.source_document_line_id(i.line_index);
    OE_BULK_MSG_PUB.set_msg_context
      ( p_entity_code                => 'LINE'
       ,p_entity_id                   => i.line_id
       ,p_header_id                   => l_header_id
       ,p_line_id                     => i.line_id
       ,p_order_source_id             => l_order_source_id
       ,p_orig_sys_document_ref       => l_orig_sys_document_ref
       ,p_orig_sys_document_line_ref  => l_orig_sys_line_ref
       ,p_orig_sys_shipment_ref       => l_orig_sys_shipment_ref
       ,p_change_sequence             => l_change_sequence
       ,p_source_document_type_id     => l_source_document_type_id
       ,p_source_document_id          => l_source_document_id
       ,p_source_document_line_id     => l_source_document_line_id
      );

    IF (l_GSA_Enabled_Flag = 'Y') THEN
      IF l_gsa_violation_action = 'WARNING' THEN
        FND_MESSAGE.SET_NAME('ONT','OE_GSA_VIOLATION');
        l_msg_text := i.status_text||' ( '||nvl(l_ordered_item,l_inventory_item_id)||' )';
        FND_MESSAGE.SET_TOKEN('GSA_PRICE',l_msg_text);
        OE_BULK_MSG_PUB.Add;

        IF l_debug_level  > 0 THEN
          oe_debug_pub.add(' GSA warning occured on line_id:'||i.line_id);
        END IF;
      ELSE  --violation action is error
        /* bug 3735141
        FND_MESSAGE.SET_NAME('ONT','OE_GSA_HOLD_APPLIED');
        OE_BULK_MSG_PUB.Add;
        */
        -- Apply GSA Hold
        OE_Bulk_Holds_Pvt.Apply_GSA_Hold
        (p_header_id         => l_header_id,
         p_line_id           => i.line_id,
         p_line_number       => NULL,
         p_hold_id           => G_SEED_GSA_HOLD_ID,
         p_ship_set_name     => NULL,
         p_arrival_set_name  => NULL,
         p_activity_name     => NULL,
         p_attribute         => NULL,
         p_top_model_line_id => l_top_model_line_id,
         x_return_status     => l_return_status);
        --bug 3735141
        IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
          IF l_debug_level  > 0 THEN
            oe_debug_pub.add(' GSA Hold applied on line_id:'||i.line_id);
          END IF;
        ELSIF l_return_status = FND_API.G_RET_STS_UNEXP_ERROR THEN
          IF l_debug_level  > 0 THEN
            oe_debug_pub.add('Unexpected error in applying GSA hold');
          END IF;
          RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
        --bug 3735141
      END IF;
    ELSE
      IF l_debug_level  > 0 THEN
        oe_debug_pub.add(' GSA check is disabled');
      END If;
    END IF;
  END LOOP;
END;
--bug 3716296
  


PROCEDURE Price_Orders
        (p_header_rec          IN OUT NOCOPY OE_BULK_ORDER_PVT.HEADER_REC_TYPE
         , p_line_rec            IN OUT NOCOPY OE_WSH_BULK_GRP.LINE_REC_TYPE
         , p_adjustments_exist   IN VARCHAR2   --pibadj
         , x_return_status OUT NOCOPY VARCHAR2 
        )
IS
l_price_control_rec      QP_PREQ_GRP.control_record_type;
l_request_rec            oe_order_pub.request_rec_type;
l_line_tbl               oe_order_pub.line_tbl_type;
l_multiple_events        VARCHAR2(1);
l_book_failed            VARCHAR2(1);
l_header_id              NUMBER;
l_header_count           NUMBER := p_header_rec.HEADER_ID.COUNT;
I                        NUMBER;
l_ec_installed           VARCHAR2(1);
l_index                  NUMBER;
l_start_index            NUMBER := 1;
x_return_status_text     VARCHAR2(2000);
l_set_of_books           OE_Order_Cache.Set_Of_Books_Rec_Type;
l_line_count             NUMBER := p_line_rec.line_id.count;
l_count                  number;

CURSOR c_price_attributes(l_header_id NUMBER) IS
   SELECT line_id
          ,price_list_id
          ,unit_list_price
          ,unit_selling_price
   FROM OE_ORDER_LINES l
   WHERE l.header_id = l_header_id;

  l_start_time             NUMBER;
  l_end_time               NUMBER;


  cursor test is 
  select CURRENCY_CODE,LINE_INDEX,LINE_ID,LINE_TYPE_CODE from qp_preq_lines_tmp;

   --
   l_debug_level CONSTANT NUMBER := oe_debug_pub.g_debug_level;
   --
BEGIN

      x_return_status := FND_API.G_RET_STS_SUCCESS;
      -- invoke QP API to source and directly insert into temp table

      qp_price_request_context.set_request_id;

      IF l_debug_level > 0 Then
	   oe_debug_pub.add('Version:'||get_version);
        for l_index in 1..l_header_count loop
          oe_debug_pub.add('l_index : '||l_index||' header currency code : '||p_header_rec.transactional_curr_code(l_index));
          oe_debug_pub.add('price list id : '||p_header_rec.PRICE_LIST_ID(l_index)||' HEADER_ID : '||p_header_rec.HEADER_ID(l_index));
          oe_debug_pub.add('ordered date : '||p_header_rec.ORDERED_DATE(l_index)||' PRICING_DATE : '||p_header_rec.PRICING_DATE(l_index)||' header_index : '||p_header_rec.header_index(l_index));        
          oe_debug_pub.add('orig_sys_document_ref : '||p_header_rec.orig_sys_document_ref(l_index));
        end loop;
  /*
        for l_index in 1..l_line_count loop
          oe_debug_pub.add('l_index : '||l_index||' line currency code : '||p_line_rec.currency_code(l_index));
        end loop;
  */
      end if;
        SELECT hsecs INTO l_start_time from v$timer;
      If l_debug_level > 0 Then
         oe_debug_pub.add('before QP_BULK_PREQ_GRP.Bulk_insert_lines');
      end if;
      QP_BULK_PREQ_GRP.Bulk_insert_lines(p_header_rec
                                    , p_line_rec
                                    , x_return_status
                                    , x_return_status_text);
      If l_debug_level > 0 Then
         oe_debug_pub.add('return status after Bulk_insert_lines : '||x_return_status||' status text : '||x_return_status_text);
      End IF;
      IF (x_return_status = FND_API.G_RET_STS_UNEXP_ERROR
          OR x_return_status = FND_API.G_RET_STS_ERROR )
      THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

      If l_debug_level > 0 Then
         select count(*) into l_count from qp_preq_lines_tmp;
         oe_debug_pub.add('l_count : '||l_count);
         for i in test loop
           oe_debug_pub.add('curr code : '||i.CURRENCY_CODE||' LINE_INDEX : '||i.LINE_INDEX||' LINE_ID : '||i.LINE_ID||' LINE_TYPE_CODE : '||i.LINE_TYPE_CODE);
         end loop;
      end if;
        SELECT hsecs INTO l_end_time from v$timer;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in Bulk_insert_lines is (sec) '||((l_end_time-l_start_time)/100));

      If l_debug_level > 0 Then
         oe_debug_pub.add('before QP_BULK_PREQ_GRP.Bulk_insert_adj');
      end if;
      IF p_adjustments_exist = 'Y' THEN --pibadj
         QP_BULK_PREQ_GRP.Bulk_insert_adj(x_return_status,
                                       x_return_status_text);
         If l_debug_level > 0 Then
            oe_debug_pub.add('after Bulk_insert_adj return status : '||x_return_status||' status text : '||x_return_status_text);
         end if;
         IF (x_return_status = FND_API.G_RET_STS_UNEXP_ERROR
          OR x_return_status = FND_API.G_RET_STS_ERROR )
         THEN
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
         END IF;
      END IF; --pibadj

      IF p_header_rec.booked_flag(1) = 'Y' THEN
        l_price_control_rec.pricing_event := 'BATCH,BOOK';
      ELSE
        l_price_control_rec.pricing_event := 'BATCH';
      END IF;

      --???Control rec set to per call level might need to be changed to per order header level.... already changed for event code
      l_Price_Control_Rec.calculate_flag :=  QP_PREQ_GRP.G_SEARCH_N_CALCULATE;
      l_Price_Control_Rec.Simulation_Flag := 'N';
      l_Price_Control_rec.temp_table_insert_flag := 'N';

      --l_Price_Control_rec.check_cust_view_flag := 'N';
      --as per spgopal, we shoud set it to 'Y' to get price adjustment id.
      l_Price_Control_rec.check_cust_view_flag := 'Y';

      l_Price_Control_rec.request_type_code := 'ONT';
      l_Price_Control_rec.rounding_flag := 'Q';
      l_Price_Control_rec.use_multi_currency:='Y';
      l_Price_Control_rec.manual_adjustments_call_flag := 'N';
      
      IF G_FUNCTION_CURRENCY IS NULL Then
         l_set_of_books := Oe_Order_Cache.Load_Set_Of_Books;
         G_FUNCTION_CURRENCY := l_set_of_books.currency_code;
      END IF;
      l_Price_Control_rec.FUNCTION_CURRENCY   := G_FUNCTION_CURRENCY;



      SELECT hsecs INTO l_start_time from v$timer;

      If l_debug_level > 0 Then
         oe_debug_pub.add('before QP_PREQ_PUB.PRICE_REQUEST');
      end if;
      QP_PREQ_PUB.PRICE_REQUEST
                (p_control_rec           => l_Price_Control_rec
                ,x_return_status         =>x_return_status
                ,x_return_status_Text         =>x_return_status_Text
                );
      If l_debug_level > 0 Then
         oe_debug_pub.add('after PRICE_REQUEST return status : '||x_return_status||' status text : '||x_return_status_Text);
      end if;

       SELECT hsecs INTO l_end_time from v$timer;
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in PRICE_REQUEST is (sec) '||((l_end_time-l_start_time)/100));
      IF (x_return_status = FND_API.G_RET_STS_UNEXP_ERROR
          OR x_return_status = FND_API.G_RET_STS_ERROR )
      THEN
         RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

     -- error handling,if an error happens, the whole order in memory should be marked as unbooked
     -- check_errors will also post error message in message processing table.
     -- check_errors will also handle gsa violation.
      IF l_debug_level > 0 Then
         oe_debug_pub.add('before check_errors');
      end if;
      SELECT hsecs INTO l_start_time from v$timer;
      Check_Errors;
      SELECT hsecs INTO l_end_time from v$timer;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in Check_Errors is (sec) '||((l_end_time-l_start_time)/100));
          
     --Next Upadate memory with the lastest pricing info
     SELECT hsecs INTO l_start_time from v$timer;
      Update_Global_Line;
     SELECT hsecs INTO l_end_time from v$timer;
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in Update_Global_Line is (sec) '||((l_end_time-l_start_time)/100));
     check_gsa;


        SELECT hsecs INTO l_start_time from v$timer;
        Insert_Adj;
        SELECT hsecs INTO l_end_time from v$timer;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in Insert_Adj is (sec) '||((l_end_time-l_start_time)/100));      

     --Credit checking (will be called from OEBVORDB.pls) 

EXCEPTION
   WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      OE_GLOBALS.G_EC_INSTALLED := l_ec_installed;
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
   WHEN OTHERS THEN
      OE_GLOBALS.G_EC_INSTALLED := l_ec_installed;
      OE_BULK_MSG_PUB.Add_Exc_Msg
           (G_PKG_NAME
            ,'Price_Orders');
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
END Price_Orders;

End  OE_BULK_PRICEORDER_PVT;
/
--show errors package body OE_BULK_PRICEORDER_PVT;
COMMIT;
EXIT;








