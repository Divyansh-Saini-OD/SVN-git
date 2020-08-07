-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name  :      XX_PO_INBLOGISTIC_V.vw                               |
-- | Description: xx_po_inblogistic_v is a view that stores information|
-- | regarding shipment status of purchase orders.                     |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-Mar-2007  Seemant Gour     Initial draft version       |
-- |1.0      22-Jun-2007  Seemant Gour     Baseline for Release        |
-- +===================================================================+

SET VERIFY      ON
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF
WHENEVER SQLERROR CONTINUE



WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating/Replacing the Custom View XX_PO_INBLOGISTIC_V
PROMPT

CREATE OR REPLACE VIEW XX_PO_INBLOGISTIC_V
                 (ROW_ID
                , SEGMENT1
                , SHIPMENT_NUM
                , SHIPPED_DATE
                , EXPECTED_RECEIPT_DATE
                , PO_HEADER_ID
                , SHIPMENT_HEADER_ID
                , ORG_ID
                , ORGANIZATION_ID
                , LAST_UPDATE_DATE  
                , LAST_UPDATED_BY   
                , CREATION_DATE     
                , CREATED_BY        
                , LAST_UPDATE_LOGIN 
                )
AS SELECT  PHA.ROWID
         , PHA.SEGMENT1
         , RSH.shipment_num
         , RSH.shipped_date
         , RSH.expected_receipt_date
         , PHA.po_header_id
         , RSH.shipment_header_id
         , PHA.org_id
         , RSL.to_organization_id 
         , RSH.last_update_date 
         , RSH.last_updated_by  
         , RSH.creation_date    
         , RSH.created_by       
         , RSH.last_update_login
FROM po_headers_all PHA,
     po_lines_all PHL,
     rcv_shipment_lines RSL,
     rcv_shipment_headers RSH,
     mtl_parameters MP
WHERE PHA.po_header_id       = PHL.po_header_id
AND   PHA.po_header_id       = RSL.po_header_id
AND   PHL.po_line_id         = RSL.po_line_id
AND   PHA.vendor_id          = RSH.vendor_id
AND   PHA.vendor_site_id(+)  = RSH.vendor_site_id
AND   RSH.shipment_header_id = RSL.shipment_header_id
AND   MP.organization_id     = RSL.to_organization_id
AND   NVL(PHA.org_id,NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1), ' ', NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)) = NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1), ' ', NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)
WITH READ ONLY;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM*****************************************************************
REM                        End Of Script                           * 
REM*****************************************************************