CREATE OR REPLACE PACKAGE xx_cs_tds_parts_jda_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : XX_CS_TDS_PARTS_JDA_PKG.pkb                                        |
-- | Description: Wrapper package to get the data from xx_cs_tds_parts table         |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |1.0       13-JUL-2011  Jagadeesh S        Creation                               |
-- |                                                                                 |
---+=================================================================================+
   g_user_name   CONSTANT VARCHAR2 (20) := 'CS_ADMIN';
   g_login_id             NUMBER        := fnd_global.login_id;

 /*  TYPE xx_cs_tds_order_items_rec IS RECORD (
      rms_sku            VARCHAR2 (25),
      item_description   VARCHAR2 (250),
      quantity           NUMBER,
      purchase_price     NUMBER,
      selling_price      NUMBER,
      uom                VARCHAR2 (5)
   );

   TYPE xx_cs_tds_parts_order_tbl IS TABLE OF xx_cs_tds_order_items_rec; */

   PROCEDURE main_proc (
      P_Sr_Number        In       Varchar2,
      p_parts_tbl        OUT       apps.xx_cs_tds_parts_order_tbl,
      x_return_status    OUT      VARCHAR2,
      x_return_message   OUT      VARCHAR2
   );
END xx_cs_tds_parts_jda_pkg;
/

SHOW ERRORS;