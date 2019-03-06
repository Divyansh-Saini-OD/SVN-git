SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE TRIGGER XX_PO_CANCEL_AUR1
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        :  XX_PO_CANCEL_AUR1                                  |
-- | Rice ID     :  E0274                                              |
-- | Description : This trigger fires when a shipment line is          |
-- |               cancelled in po_line_locations_all table.           |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  24-Jul-07   Christina S        Initial draft version     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AFTER UPDATE OF CANCEL_FLAG ON PO_LINE_LOCATIONS_ALL
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
WHEN (NEW.CANCEL_FLAG = 'Y')

DECLARE
    lc_event_key               VARCHAR2(200);
    lc_event_name              VARCHAR2(200) := 'xx.po.accept.reject';
    lc_order_type              PO_HEADERS_ALL.attribute_category%TYPE;

BEGIN

    SELECT NVL(PH.attribute_category, 'X')
    INTO   lc_order_type
    FROM   po_headers_all PH
          ,fnd_descr_flex_contexts FL
    WHERE PH.po_header_id = :OLD.po_header_id
    AND   PH.attribute_category = FL.descriptive_flex_context_code
    AND   FL.descriptive_flexfield_name = 'PO_HEADERS'
    AND   FL.enabled_flag = 'Y';

    IF lc_order_type IS NOT NULL THEN

        lc_event_key := 'PO'||'-'||:NEW.po_line_id;

        WF_EVENT.RAISE( p_event_name => lc_event_name
                       ,p_event_key  => lc_event_key 
		       );

    END IF;
END;
/
SHOW ERR