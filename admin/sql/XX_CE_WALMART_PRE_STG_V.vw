-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                 |
-- +==================================================================================+
-- | Name :APPS.XX_CE_WALMART_PRE_STAGE_V                                           |
-- | Description : Returns the data from XX_CE_MARKETPLACE_PRE_STG for RAKUTEN_MWS    |
-- |   RICE_Id:I3123                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date         Author               Remarks                               |
-- |=======   ==========   =============        ======================================|
-- | V1.0     28-Jun-2018  Digamber S           Initial version                       |
-- | V2.0     05-Nov-2020  Ankit Jaiswal		Added new columns to the view for the |
-- |											JIRA NAIT-154432					  |
-- +==================================================================================+

CREATE OR REPLACE FORCE EDITIONABLE VIEW "APPS"."XX_CE_WALMART_PRE_STG_V" ("REC_ID", "REPORT_DATE", "PROCESS_NAME", "FILENAME", "FILE_TYPE", "REQUEST_ID", "PROCESS_FLAG", "ERR_MSG", "SETTLEMENT_ID", "WALMART_ORDER", "WALMART_ORDER_LINE", "WALMART_PO", "WALMART_PO_LINE", "PARTNER_ORDER", "TRANSACTION_TYPE", "TRANSACTION_DATE_TIME", "SHIPPED_QTY", "PARTNER_ITEM_ID", "PARTNER_GTIN", "PARTNER_ITEM_NAME", "PRODUCT_TAX_CODE", "SHIPPING_TAX_CODE", "GIFT_WRAP_TAX_CODE", "SHIP_TO_STATE", "SHIP_TO_COUNTY", "COUNTY_CODE", "SHIP_TO_CITY", "ZIP_CODE", "SHIPPING_METHOD", "TOTAL_TENDER_CUSTOMER", "PAYABLE_TO_PARTNER", "COMMISSION_FROM_SALE", "COMMISSION_RATE", "GROSS_SALES_REVENUE", "REFUNDED_RETAIL_SALES", "SALES_REFUND_FOR_ESCALN", "GROSS_SHIPPING_REVENUE", "GROSS_SHIPPING_REFUNDED", "SHIPPING_REFUND_FOR_ESCLN", "NET_SHIPPING_REVENUE", "GROSS_FEE_REVENUE", "GROSS_FEE_REFUNDED", "FEE_REFUND_FOR_ESCALATION", "NET_FEE_REVENUE", "GIFT_WRAP_QUANTITY", "GROSS_GIFT_WRAP_REVENUE", "GROSS_GIFT_WRAP_REFUNDED", "GIFT_WRAP_REFUND_FOR_ESCLN", "NET_GIFT_WRAP_REVENUE", "TAX_ON_SALES_REVENUE", "TAX_ON_SHIPPING_REVENUE", "TAX_ON_GIFT_WRAP_REVENUE", "TAX_ON_FEE_REVENUE", "EFFECTIVE_TAX_RATE", "TAX_ON_REFUNDED_SALES", "TAX_ON_SHIPPING_REFUND", "TAX_ON_GIFT_WRAP_REFUND", "TAX_ON_FEE_REFUND", "TAX_ON_SALES_REFUND_FOR_ESCLN", "TAX_SHIPPING_REFUND_ESCLN", "TAX_GIFT_WRAP_REFUND_ESCLN", "TAX_FEE_REFUND_ESCLN", "TOTAL_NET_TAX_COLLECTED","TAX_WITHHELD", "ADJUSTMENT_DESCRIPTION", "ADJUSTMENT_CODE", "ORIGINAL_ITEM_PRICE", "ORIGINAL_COMMISSION_AMOUNT", "SPEC_CATEGORY", "CONTRACT_CATEGORY","PRODUCT_TYPE","FLEX_COMMISSION_RULE","RETURN_REASON_CODE","RETURN_REASON_DESCRIPTION","FEE_WITHHELD_FLAG","FULFILLMENT_TYPE") AS 
   SELECT REC_ID,
    REPORT_DATE,
    PROCESS_NAME,
    FILENAME,
    FILE_TYPE,
	REQUEST_ID,
    PROCESS_FLAG,
    ERR_MSG,
    SETTLEMENT_ID,
    ATTRIBUTE1 Walmart_Order,
    ATTRIBUTE2 Walmart_Order_Line,
    ATTRIBUTE3 Walmart_PO,
    ATTRIBUTE4 Walmart_PO_Line,
    ATTRIBUTE5 Partner_Order,
    ATTRIBUTE6 Transaction_Type,
    ATTRIBUTE7 Transaction_Date_Time,
    ATTRIBUTE8 Shipped_Qty,
    ATTRIBUTE9 Partner_Item_ID,
    ATTRIBUTE10 Partner_GTIN,
    ATTRIBUTE11 Partner_Item_name,
    ATTRIBUTE12 Product_tax_code,
    ATTRIBUTE13 Shipping_tax_code,
    ATTRIBUTE14 Gift_wrap_tax_code,
    ATTRIBUTE15 Ship_to_state,
    ATTRIBUTE16 Ship_to_county,
    ATTRIBUTE17 County_Code,
    ATTRIBUTE18 Ship_to_city,
    ATTRIBUTE19 Zip_code,
    ATTRIBUTE20 shipping_method,
    ATTRIBUTE21 Total_tender_Customer,
    ATTRIBUTE22 Payable_to_Partner,
    ATTRIBUTE23 Commission_from_Sale,
    ATTRIBUTE24 Commission_Rate,
    ATTRIBUTE25 Gross_Sales_Revenue,
    ATTRIBUTE26 Refunded_Retail_Sales,
    ATTRIBUTE27 Sales_refund_for_Escaln,
    ATTRIBUTE28 Gross_Shipping_Revenue,
    ATTRIBUTE29 Gross_Shipping_Refunded,
    ATTRIBUTE30 Shipping_refund_for_Escln,
    ATTRIBUTE31 Net_Shipping_Revenue,
    ATTRIBUTE32 Gross_Fee_Revenue,
    ATTRIBUTE33 Gross_Fee_Refunded,
    ATTRIBUTE34 Fee_refund_for_Escalation,
    ATTRIBUTE35 Net_Fee_Revenue,
    ATTRIBUTE36 Gift_Wrap_Quantity,
    ATTRIBUTE37 Gross_Gift_Wrap_Revenue,
    ATTRIBUTE38 Gross_Gift_Wrap_Refunded,
    ATTRIBUTE39 Gift_wrap_refund_for_Escln,
    ATTRIBUTE40 Net_Gift_Wrap_Revenue,
    ATTRIBUTE41 Tax_on_Sales_Revenue,
    ATTRIBUTE42 Tax_on_Shipping_Revenue,
    ATTRIBUTE43 Tax_on_Gift_Wrap_Revenue,
    ATTRIBUTE44 Tax_on_Fee_Revenue,
    ATTRIBUTE45 Effective_tax_rate,
    ATTRIBUTE46 Tax_on_Refunded_Sales,
    ATTRIBUTE47 Tax_on_Shipping_Refund,
    ATTRIBUTE48 Tax_on_Gift_Wrap_Refund,
    ATTRIBUTE49 Tax_on_Fee_Refund,
    ATTRIBUTE50 Tax_on_Sales_refund_for_Escln,
    ATTRIBUTE51 Tax_Shipping_Refund_Escln,
    ATTRIBUTE52 Tax_Gift_Wrap_Refund_escln,
    ATTRIBUTE53 Tax_Fee_Refund_escln,
    ATTRIBUTE54 Total_NET_Tax_Collected,
	--ATTRIBUTE55 Tax_Withheld,    --Added new columns to the view for the JIRA NAIT-154432
	--ATTRIBUTE56 Adjustment_Description,
	--ATTRIBUTE57 Adjustment_Code,
	--ATTRIBUTE58 Original_Item_price,
	--ATTRIBUTE59 Original_Commission_Amount,
	--ATTRIBUTE60 Spec_Category,
	--ATTRIBUTE61 Contract_Category,
	--ATTRIBUTE62 Product_Type,
	--ATTRIBUTE63 Flex_Commission_Rule,
	--ATTRIBUTE64 Return_Reason_Code,
	--ATTRIBUTE65 Return_Reason_Description,
	--ATTRIBUTE66 Fee_Withheld_Flag,
	--ATTRIBUTE67 Fulfillment_Type
	ATTRIBUTE55 Tax_Withheld,
	ATTRIBUTE56 Adjustment_Description,
	ATTRIBUTE57 Adjustment_Code,
	ATTRIBUTE58 Original_Item_price,
	ATTRIBUTE59 Original_Commission_Amount,
	ATTRIBUTE60 Spec_Category,
	ATTRIBUTE61 Contract_Category,
	ATTRIBUTE62 Product_Type,
	ATTRIBUTE63 Flex_Commission_Rule,
	ATTRIBUTE64 Return_Reason_Code,
	ATTRIBUTE65 Return_Reason_Description,
	ATTRIBUTE66 Fee_Withheld_Flag,
	ATTRIBUTE67 Fulfillment_Type
  FROM XX_CE_MARKETPLACE_PRE_STG
  WHERE PROCESS_NAME ='WALMART_MPL'
 AND FILE_TYPE='WAL';