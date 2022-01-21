SET VERIFY OFF;
SET SHOW OFF;
SET TAB OFF;
SET ECHO OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :            XX_OM_DPSCANCEL_V.vw                           |
-- | Rice ID : I1151  DPS cancel order                                 |
-- | Description      : This scipt creeated VIEW XX_OM_DPSCANCEL_V     |
-- |                    for DPS Cancel Interface. This view extracts   |
-- |                    Sales Order Bundle details                     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   25-APR-2007 Rizwan A         Initial Version             |
-- |V1.1      30-JUL-2007 Rizwan A         Incorporated KFF changes    |
-- |                                                                   |
-- +===================================================================+

CREATE OR REPLACE VIEW xx_om_dpscancel_v
AS
      SELECT TO_CHAR (SYSDATE, 'YYYY.MM.DD HH:MM:SS.SSSS') datetimestamp
         ,XOLAA.vendor_site_id globalbusinessid_recv
         , 'OD to ' || TO_CHAR(XOLAA.vendor_site_id) || ' transact' freeformtext_recv
         ,XOLAA.vendor_site_id globalbusinesssvccode_to
         ,ooha.order_number ordernumber
         ,XOLAA.ext_top_model_line_id orderidentifier
         ,NULL cancelcode
         ,NULL codemessage
         ,OOLA.line_id ordersubnumber
         ,OOLA.ordered_item itemid
         ,XODS.event_key session_id
     FROM oe_order_headers_all OOHA
         ,oe_order_lines_all OOLA
         ,xx_om_line_attributes_all XOLAA
         ,xx_om_dpsparent_stg XODS
    WHERE OOHA.header_id = OOLA.header_id
      AND OOLA.Line_id = XOLAA.line_id
      AND XOLAA.ext_top_model_line_id = XODS.parent_line_id
/
SHOW ERROR