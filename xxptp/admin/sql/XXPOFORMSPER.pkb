create or replace PACKAGE BODY XX_PO_FORMS_PERSN_PKG

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name             : XX_PO_FORMS_PERSN_PKG                                                |
-- | Description      : Package spec for E0416 PO FORMS PERSONALIZATION                      |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |1.0        07/01/2007        Paul DSouza                                                 |
-- |2.0        08/14/2007        Paul DSouza      Change for Expense Supplier Site Category  |
-- |3.0        08/20/2007        Paul DSouza      Change for "EX" Expense Supplier Site Cat  |
-- +=========================================================================================+

AS

-- **************************************************************
-- Procedure to update PO lines and shipments for PO type E0416B.
-- **************************************************************

PROCEDURE UpdatePOLines(p_po_header_id  IN NUMBER, p_po_type IN VARCHAR2, p_vendor_site_id IN NUMBER)
IS
lc_total_cost VARCHAR2(150);
BEGIN
	UPDATE po_lines_all pol
	SET    pol.attribute_category=p_po_type,
	       pol.attribute6=''
	WHERE  pol.po_header_id = p_po_header_id;

	UPDATE po_line_locations_all poll
	SET    poll.attribute_category=p_po_type
	WHERE  poll.po_header_id = p_po_header_id;

	/* IF p_po_type='Trade-Import' THEN  -- Commented for Release 1
	   UPDATE po_lines_all pol1
 	   SET    pol1.attribute6=
 	          (SELECT poll.attribute6
                   FROM   po_lines_all pol,
                          po_line_locations_all poll,
                          po_headers_all poh
                   WHERE  poh.type_lookup_code='QUOTATION'
                   AND    poh.status_lookup_code='A'
                   AND    trunc(sysdate) between trunc(nvl(poh.start_date_active,sysdate-1))
                          and trunc(nvl(poh.start_date_active,sysdate+1))
                   AND    pol.po_header_id=poh.po_header_id
                   AND    poll.po_line_id=pol.po_line_id
                   AND    trunc(sysdate) between trunc(nvl(poll.start_date,sysdate-1)) and trunc(nvl(poll.end_date,sysdate+1))
                   AND    pol.item_id=pol1.item_id
                   AND    poh.vendor_site_id=p_vendor_site_id
                   AND    1>= poll.quantity
                   AND    poll.attribute6 is not null
                   AND    rownum=1);
	END IF; */

	COMMIT;
EXCEPTION
WHEN OTHERS THEN
    NULL;
    COMMIT;
END UpdatePOLines;

-- **************************************************************
-- Procedure to update PO Number for GSS Order.
-- **************************************************************
PROCEDURE UpdatePONumber(p_po_header_id  IN NUMBER)
IS
BEGIN
	--insert into xxtb values (p_po_header_id,'Update PO Number-'||sysdate);
	--COMMIT;
	UPDATE po_headers_all poh
	SET    poh.attribute10=poh.segment1
	WHERE  poh.po_header_id = p_po_header_id;

	COMMIT;
EXCEPTION
WHEN OTHERS THEN
    --insert into xxtb values (p_po_header_id,'Error:Update PO Number-'||sysdate);
    NULL;
END UpdatePONumber;

-- **************************************************************
-- Fuction to default PO type.
-- **************************************************************
Function DefaultPOType(p_ship_to_location_id in number,p_vendor_id in number, p_vendor_site_id in number)
RETURN varchar2 IS
lc_po_type      varchar2(150):='';
lc_stcountry    varchar2(150):='';
lc_sfcountry    varchar2(150):='';
lc_vendor_type  varchar2(150):='';
ln_count        number;
ln_found        number;
BEGIN
   SELECT country
   INTO   lc_stcountry
   FROM   hr_locations_all
   WHERE  location_id=p_ship_to_location_id;

   SELECT  country,upper(attribute8)
   INTO    lc_sfcountry,lc_vendor_type
   FROM    po_vendor_sites_all
   WHERE   vendor_site_id=p_vendor_site_id;

   IF lc_vendor_type='EX' OR substr(lc_vendor_type,1,3)='EX-' THEN --4IF  -- Changed on 08/02/2007 after verifying with Payables BR-100.
                                            -- Changed again on 08/14/2007 after verifying with Elaine.
      lc_po_type:='Non-Trade';
   ELSE
      lc_po_type:='';

/*      SELECT count(*) -- Commented for Release 1
      INTO   ln_count
      FROM   fnd_descr_flex_contexts
      WHERE  descriptive_flexfield_name = 'PO_HEADERS'
      AND    enabled_flag='Y';

      IF ln_count > 1 THEN  --5IF
         SELECT distinct 1
         INTO   ln_found
         FROM   fnd_descr_flex_contexts
         WHERE  descriptive_flexfield_name = 'PO_HEADERS'
         AND    enabled_flag='Y'
         AND    upper(descriptive_flex_context_code) in ('TRADE','TRADE-IMPORT');

         IF ln_found = 1 THEN  --6IF
            BEGIN
               SELECT global_indicator_name
               INTO   lc_po_type
               FROM   xx_po_global_indicator
               WHERE  source_territory_code=lc_sfcountry
               AND    destination_territory_code=lc_stcountry
               AND    trunc(sysdate) between trunc(start_date) and trunc(end_date);
             EXCEPTION
             WHEN OTHERS THEN
               SELECT DECODE(SUBSTR(UPPER(lc_vendor_type),1,9),'TR-IMP','Trade-Import','Trade') -- Changed on 08/02/2007 after verifying with Payables BR-100.
               INTO   lc_po_type
               FROM   dual;
             END;
         ELSE
             SELECT descriptive_flex_context_code
             INTO   lc_po_type
      	     FROM   fnd_descr_flex_contexts
 	     WHERE  descriptive_flexfield_name = 'PO_HEADERS'
             AND    enabled_flag='Y'
             AND    rownum=1;
         END IF;               --6IF
      ELSE
               SELECT descriptive_flex_context_code
               INTO   lc_po_type
   	       FROM   fnd_descr_flex_contexts
 	       WHERE  descriptive_flexfield_name = 'PO_HEADERS'
               AND    enabled_flag='Y';
      END IF; --5IF
*/
   END IF; --4IF
RETURN lc_po_type;
EXCEPTION
WHEN OTHERS THEN
   RETURN lc_po_type;
END;

-- **************************************************************
-- Fuction to default PO type.
-- **************************************************************
Function DefaultPOSource(p_po_header_id in number)
RETURN varchar2 IS
lc_po_source    varchar2(150):='';
lc_stcountry    varchar2(150):='';
lc_sfcountry    varchar2(150):='';
lc_vendor_type  varchar2(150):='';
ln_count        number;
ln_fLAG         number;
BEGIN
   ln_flag:=0;
   BEGIN
      SELECT 1
      INTO   ln_Flag
      FROM   PO_HEADERS_ALL POH
      WHERE  POH.PO_HEADER_ID=p_po_header_id
      AND     EXISTS
             (SELECT 1
              FROM   PO_LINE_LOCATIONS_ALL POLL, PO_REQUISITION_LINES_ALL PORL,PO_REQUISITION_HEADERS_ALL PORH
              WHERE  POLL.PO_HEADER_ID=POH.PO_HEADER_ID
              AND    PORL.LINE_LOCATION_ID=POLL.LINE_LOCATION_ID
              AND    PORH.REQUISITION_HEADER_ID=PORL.REQUISITION_HEADER_ID
              AND    PORH.APPS_SOURCE_CODE='POR');
   EXCEPTION
   WHEN OTHERS THEN
      ln_Flag:=0;
   END;
   --IF ln_Flag=1 THEN
   --   lc_po_source:='NA-IPREQ';
  -- ELSE
  --    lc_po_source:='MANUAL';
  -- END IF;
    lc_po_source:='MANUAL';
RETURN lc_po_source;
EXCEPTION
WHEN OTHERS THEN
   lc_po_source:='MANUAL';
   RETURN lc_po_source;
END;

-- **************************************************************
-- Fuction to default GSS Values on the PO Header.
-- **************************************************************
Function GetGSSValues(p_po_header_id in number,p_vendor_site_id in number,p_gss_attribute in varchar2)
RETURN varchar2 IS
ln_kff_id         number;
ln_buying_agent   number:='';
ln_manufacturer   number:='';
ln_fforwarder     number:='';
ln_ship_from_port number:='';
BEGIN
/*   SELECT  attribute15
   INTO    ln_kff_id
   FROM    po_vendor_sites_all
   WHERE   vendor_site_id=p_vendor_site_id;

   SELECT xpvs.segment91,
          xpvs.segment90,
          xpvs.segment92,
          xpvs.segment93
   INTO   ln_buying_agent,
          ln_manufacturer,
          ln_fforwarder  ,
          ln_ship_from_port
   FROM   xx_po_vendor_sites_kff xpvs
   WHERE  vs_kff_id=ln_kff_id; */

   IF p_gss_attribute='ATTR6' THEN
      RETURN ln_buying_agent;
   ELSIF p_gss_attribute='ATTR7' THEN
      RETURN ln_manufacturer;
   ELSIF p_gss_attribute='ATTR8' THEN
      RETURN ln_fforwarder;
   ELSIF p_gss_attribute='ATTR9' THEN
      RETURN ln_ship_from_port;
   END IF;
EXCEPTION
WHEN OTHERS THEN
   RETURN NULL;
END;

END XX_PO_FORMS_PERSN_PKG  ;
/