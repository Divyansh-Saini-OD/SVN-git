  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name          : XX_CE_VARIS_PRE_STG_V                                                     |
  -- |  Description   : Varis settlement view                                                     |
  -- |  Change Record :                                                                           |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         23-Dec-2021  Divyansh Saini   Initial version                                  |
  -- +============================================================================================+


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "APPS"."XX_CE_VARIS_PRE_STG_V" AS
  SELECT REC_ID,
        REPORT_DATE,
        PROCESS_NAME,
        FILENAME,
        FILE_TYPE,
        REQUEST_ID,
        PROCESS_FLAG,
        ERR_MSG,
        SETTLEMENT_ID,
        attribute1       order_no,
        attribute2       order_date,
        attribute3       po_number,
        attribute4       poc_number,
        attribute5       transaction_type,
        attribute6       customer,
        attribute7       order_qty,
        attribute8       requested_date,
        attribute9       poc_quantity,
        attribute10      invoice_no,
        attribute11      invoice_date,
        attribute12      asn_no,
        attribute13      ship_from,
        attribute14      ship_to,
        attribute15      tracking_number,
        attribute16      shipping_date,
        attribute17      shipping_rate,
        attribute18      shipping_charge,
        attribute19      shipping_sales_tax,
        attribute20      shipping_sales_tax_rate,
        attribute21      item_type,
        attribute22      sku,
        attribute23      sku_description,
        attribute24      shipped_qty,
        attribute25      uom,
        attribute26      unit_price,
        attribute27      line_amount,
        attribute28      commisison_rate,
        attribute29      commisison_amount,
        attribute30      item_sales_tax_rate,
        attribute31      item_sales_tax,
        attribute32      total_tax,
        attribute33      Fee_type_1,
        replace(replace(replace(attribute34,chr(9),''),chr(13),''),chr(10),'')      Fee_type_1_amt,
        attribute35      Fee_type_2,
        replace(replace(replace(attribute36,chr(9),''),chr(13),''),chr(10),'')     Fee_type_2_amt,
        attribute37      Fee_type_3,
        replace(replace(replace(attribute38,chr(9),''),chr(13),''),chr(10),'')      Fee_type_3_amt
    FROM XX_CE_MARKETPLACE_PRE_STG
   WHERE PROCESS_NAME ='VARIS_MPL';
