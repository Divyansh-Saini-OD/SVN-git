CREATE OR REPLACE
PACKAGE BODY APPS.POS_ASN_NOTIF AS
/* $Header: POSASNNB.pls 115.16 2004/02/11 03:06:47 mji ship $ */

TYPE AsnBuyerArray IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

asn_buyers             AsnBuyerArray;
asn_buyers_empty       AsnBuyerArray;
asn_buyer_num	       INTEGER := 0;

PROCEDURE GENERATE_NOTIF (
	p_shipment_num  	IN 	VARCHAR2,
	p_notif_type		IN	VARCHAR2,
	p_vendor_id		IN	NUMBER,
	p_vendor_site_id	IN	NUMBER,
        p_user_id       	IN      INTEGER)
IS

l_item_type     VARCHAR2(20) := 'POSASNND';
l_item_key      VARCHAR2(240) ;
l_seq_val    	NUMBER;
l_supp_username     VARCHAR2(100);
l_supplier_displayname VARCHAR2(100);

BEGIN

 SELECT po_wf_itemkey_s.nextval INTO l_seq_val FROM dual;
 l_item_key := 'POSASNND_' || p_shipment_num || '_' || to_char(l_seq_val);

   if (p_notif_type = 'CANCEL') then
      wf_engine.createProcess(	ItemType    => l_item_type,
                           	ItemKey     => l_item_key,
                           	Process     => 'BUYER_NOTIF_CANCEL'
                             );
   else
      wf_engine.createProcess(	ItemType    => l_item_type,
                           	ItemKey     => l_item_key,
                           	Process     => 'BUYER_NOTIFICATION'
                             );
   end if;

   -- Get the supplier user name
   WF_DIRECTORY.GetUserName(  'FND_USR',
                           p_user_id,
                           l_supp_username,
                           l_supplier_displayname);

   wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'SHIPMENT_NUM',
                            avalue      => p_shipment_num
                            );

   wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'SUPPLIER_USERNAME',
                            avalue      => l_supp_username
                            );

   wf_engine.SetItemAttrNumber
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'VENDOR_ID',
                            avalue      => p_vendor_id
                            );

   wf_engine.SetItemAttrNumber
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'VENDOR_SITE_ID',
                            avalue      => p_vendor_site_id
                            );
   --dbms_output.put_line('Item Key ' || l_item_key );
   wf_engine.StartProcess( ItemType => l_item_type,
                           ItemKey  => l_item_key );


END GENERATE_NOTIF;


-- This procedure sets the next Buyer to send notification
PROCEDURE SET_NEXT_BUYER(
			 l_item_type IN VARCHAR2,
			 l_item_key  IN VARCHAR2,
			 actid       IN NUMBER,
                         funcmode    IN  VARCHAR2,
                         result      OUT NOCOPY VARCHAR2
)
IS

x_buyer_user_name        VARCHAR2(40);
x_buyer_user_displayname VARCHAR2(40);
x_total_num_buyers       NUMBER;
x_curr_buyer             NUMBER;
x_shipment_num  VARCHAR2(80);
x_vendor_id     NUMBER;
x_vendor_site_id     NUMBER;

BEGIN
   --dbms_output.put_line('Calling Set Next Buyer');
x_total_num_buyers := wf_engine.GetItemAttrNumber ( itemtype => l_item_type,
                                                    itemkey  => l_item_key,
                                                    aname    => 'TOTAL_BUYER_NUM');

x_curr_buyer       := wf_engine.GetItemAttrNumber ( itemtype => l_item_type,
                                                    itemkey  => l_item_key,
                                                    aname    => 'CURR_BUYER_NUM');

x_shipment_num     := wf_engine.GetItemAttrText (   itemtype => l_item_type,
                                                    itemkey  => l_item_key,
                                                    aname    => 'SHIPMENT_NUM');

x_vendor_id        := wf_engine.GetItemAttrNumber ( itemtype => l_item_type,
                                                    itemkey  => l_item_key,
                                                    aname    => 'VENDOR_ID');

x_vendor_site_id   := wf_engine.GetItemAttrNumber ( itemtype => l_item_type,
                                                    itemkey  => l_item_key,
                                                    aname    => 'VENDOR_SITE_ID');

--dbms_output.put_line('Buyer Num is ' || to_char(x_curr_buyer));


IF ( x_curr_buyer <= x_total_num_buyers ) THEN

 --  dbms_output.put_line('Buyer id is ' ||  to_char(asn_buyers(x_curr_buyer)) );
   wf_directory.getusername('PER',
			       asn_buyers(x_curr_buyer),
			       x_buyer_user_name,
			       x_buyer_user_displayname);

   wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'ASN_BUYER',
                            avalue      => x_buyer_user_name
                            );


   wf_engine.SetItemAttrText (
				itemtype       => l_item_type,
                                itemkey       => l_item_key,
                                aname         => 'ASN_INFO',
                                avalue        => 'PLSQLCLOB:POS_ASN_NOTIF.GENERATE_ASN_BODY/'
				|| x_shipment_num || '*%$*' || to_char(asn_buyers(x_curr_buyer))
				||'%'||to_char(x_vendor_id)||'#'||to_char(x_vendor_site_id)
				);

--   dbms_output.put_line('Buyer Name is ' || x_buyer_user_name );
   x_curr_buyer := x_curr_buyer + 1;

    wf_engine.SetItemAttrNumber
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'CURR_BUYER_NUM',
                            avalue      => x_curr_buyer
                            );


	result := 'COMPLETE:Y';
ELSE

	result := 'COMPLETE:N';
END IF;

END SET_NEXT_BUYER;


-----------------------------------------------------------------------
-- Procedure to retrieve Buyers for each ASN
-- and generates the headers

PROCEDURE GET_ASN_BUYERS(
			 l_item_type IN VARCHAR2,
			 l_item_key  IN VARCHAR2,
			 actid       IN NUMBER,
                         funcmode    IN  VARCHAR2,
                         result      OUT NOCOPY VARCHAR2
)
IS

l_buyer_id      number;
x_buyer_id      number;
x_shipment_num  VARCHAR2(80);
x_asn_type      VARCHAR2(20);
x_vendor_name   VARCHAR2(240);
x_shipped_date  DATE;
x_shipped_date_ts  varchar2(30);
x_expected_receipt_date date;
x_expected_receipt_ts varchar2(30);
x_invoice_num   VARCHAR2(50);
x_total_invoice_amount  NUMBER;
x_invoice_date  date;
x_tax_amount    NUMBER;
l_document1     VARCHAR2(32000) := '';
NL              VARCHAR2(1) := fnd_global.newline;
x_display_type  VARCHAR2(60);
x_buyer_user_name VARCHAR2(40);
x_buyer_user_displayname VARCHAR2(40);
l_nid 		NUMBER;
i		INTEGER;
x_vendor_id       NUMBER;
x_vendor_site_id  NUMBER;

CURSOR asn_buyer(v_shipment_num varchar2,v_vendor_id number,v_vendor_site_id number) is
SELECT distinct BUYER_ID
FROM   POS_LINES_V
WHERE  SHIPMENT_NUM=v_shipment_num
AND    vendor_id=v_vendor_id
AND    vendor_site_id=v_vendor_site_id;

BEGIN

asn_buyers :=  asn_buyers_empty;
--asn_buyer_num := 0;

x_shipment_num := wf_engine.GetItemAttrText  ( itemtype => l_item_type,
                                               itemkey  => l_item_key,
                                               aname    => 'SHIPMENT_NUM');

x_vendor_id := wf_engine.GetItemAttrNumber     ( itemtype => l_item_type,
                                                 itemkey  => l_item_key,
                                                 aname    => 'VENDOR_ID');

x_vendor_site_id := wf_engine.GetItemAttrNumber ( itemtype => l_item_type,
                                                  itemkey  => l_item_key,
                                                  aname    => 'VENDOR_SITE_ID');

--dbms_output.put_line('Shipment Num is ' || x_shipment_num);
i:= 1;
open asn_buyer(x_shipment_num,x_vendor_id,x_vendor_site_id);
--dbms_output.put_line('Before Open Buyer Cursor ');
-- Populate the global pl/sql table with buyer id's
LOOP
	FETCH asn_buyer INTO x_buyer_id;
	EXIT WHEN asn_buyer%NOTFOUND;
	asn_buyers(i) := x_buyer_id;
--dbms_output.put_line('Buyer Id is  ' || to_char(x_buyer_id));
        i := i+1;

END LOOP;

CLOSE asn_buyer;
--dbms_output.put_line('First Buyer Id is ' || to_char(asn_buyers(1)));

     BEGIN

	SELECT distinct poh.shipment_num,pov.vendor_name,
                poh.shipped_date,
		to_char(poh.shipped_date,fnd_profile.value_wnps('ICX_DATE_FORMAT_MASK')||' HH24:MI:SS'),
		poh.expected_receipt_date,
		to_char(poh.expected_receipt_date,fnd_profile.value_wnps('ICX_DATE_FORMAT_MASK')||' HH24:MI:SS'),
       		poh.invoice_num,poh.total_invoice_amount,
       	        poh.invoice_date,
       	poh.tax_amount,poh.asn_type
	INTO   x_shipment_num,x_vendor_name,
		x_shipped_date,
		x_shipped_date_ts,
		x_expected_receipt_date,
		x_expected_receipt_ts,
       		x_invoice_num,x_total_invoice_amount,
       		x_invoice_date,x_tax_amount,x_asn_type
	FROM   POS_HEADERS_V poh,PO_VENDORS pov
	WHERE  poh.shipment_num   = x_shipment_num AND
               poh.vendor_id      = pov.vendor_id  AND
               poh.vendor_id      = x_vendor_id    AND
               poh.vendor_site_id = x_vendor_site_id ;
    EXCEPTION
        WHEN NO_DATA_FOUND then
        l_document1:= 'ASN has been cancelled';
        -- fnd_message.get_string('POS','POS_ASN_CANCELLED');
        wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'ASN_HEADERS',
                            avalue      => l_document1
                            );

        wf_directory.getusername('PER',
			       asn_buyers(1),
			       x_buyer_user_name,
			       x_buyer_user_displayname);

        wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'ASN_BUYER',
                            avalue      => x_buyer_user_name
                            );
        return;
        WHEN OTHERS then
        RAISE;
    END;

--dbms_output.put_line('Asn Type is ' || x_asn_type);
--dbms_output.put_line('Vendor Name is ' || x_vendor_name);
   wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'SUPPLIER',
                            avalue      => x_vendor_name
                            );

   wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'EXPECTED_RECEIPT_TS',
                            avalue      => x_expected_receipt_ts
                            );

   wf_engine.SetItemAttrDate
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'EXPECTED_RECEIPT_DATE',
                            avalue      => x_expected_receipt_date
                            );

   wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'ASN_TYPE',
                            avalue      => x_asn_type
                            );

--x_display_type := 'text/html';

l_document1 := '<font size=3 color=#336699 face=arial><b>' ||fnd_message.get_string('POS', 'POS_ASN_NOTIF_DETAILS') ||
                '</B></font><HR size=1 color=#cccc99>' ;

l_document1 := l_document1 || '<TABLE  cellpadding=2 cellspacing=1>';

l_document1 := l_document1 || '<TR>' ;

l_document1 := l_document1 || '<TD nowrap><font color=black><B>' ||
                     fnd_message.get_string('POS', 'POS_ASN_NOTIF_SUPP_NAME') || '</B></font></TD> ' ;
l_document1 := l_document1 || '<TD nowrap><font color=black>' ||
                      x_vendor_name || '</font></TD> ' ;
l_document1 := l_document1 || '</TR>' ;

l_document1 := l_document1 || '<TR>' ;
l_document1 := l_document1 || '<TD nowrap><font color=black><B>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_SHIPMENT_NUM') || '</B></font></TD> ' ;
l_document1 := l_document1 || '<TD nowrap><font color=black>' ||
                      x_shipment_num || '</font></TD> ' ;
l_document1 := l_document1 || '</TR>' ;

l_document1 := l_document1 || '<TR>' ;
l_document1 := l_document1 || '<TD nowrap><font color=black><B>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_SHIPMENT_DATE') || '</B></font></TD> ' ;
l_document1 := l_document1 || '<TD nowrap><font color=black>' ||
                      x_shipped_date_ts || '</font></TD> ' ;
l_document1 := l_document1 || '</TR>' ;

l_document1 := l_document1 || '<TR>' ;
l_document1 := l_document1 || '<TD nowrap><font color=black><B>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_EXPT_RCPT_DATE') || '</B></font></TD> ';
l_document1 := l_document1 || '<TD nowrap><font color=black>' ||
                      x_expected_receipt_ts || '</font></TD> ' ;
l_document1 := l_document1 || '</TR>' ;

l_document1 := l_document1 || '</TABLE></P>' ;


IF (x_asn_type = 'ASBN') THEN

  wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'INVOICE_INFO',
                            avalue      => 'and Invoice'
                            );

  wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'INVOICE_NUM',
                            avalue      => x_invoice_num
                            );


l_document1 := l_document1 || '<font size=3 color=#336699 face=arial><b>'||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_BILL_INFO') ||'</B></font><HR size=1 color=#cccc99>' ;

l_document1 := l_document1 || '<TABLE  cellpadding=2 cellspacing=1>';

l_document1 := l_document1 || '<TR>' ;
l_document1 := l_document1 || '<TD nowrap><font color=black><B>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_INVOICE_NUMBER') || '</B></font></TD> ' ;
l_document1 := l_document1 || '<TD nowrap><font color=black>' ||
                      x_invoice_num || '</font></TD> ' ;
l_document1 := l_document1 || '</TR>' ;

l_document1 := l_document1 || '<TR>' ;
l_document1 := l_document1 || '<TD nowrap><font color=black><B>' ||
                       fnd_message.get_string('POS', 'POS_ASN_NOTIF_INVOICE_AMOUNT') || '</B></font></TD> ' ;
l_document1 := l_document1 || '<TD nowrap><font color=black>' ||
                      x_total_invoice_amount || '</font></TD> ' ;
l_document1 := l_document1 || '</TR>' ;

l_document1 := l_document1 || '<TR>' ;
l_document1 := l_document1 || '<TD nowrap><font color=black><B>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_INVOICE_DATE') || '</B></font></TD> ' ;
l_document1 := l_document1 || '<TD nowrap><font color=black>' ||
                      x_invoice_date || '</font></TD> ' ;
l_document1 := l_document1 || '</TR>' ;

l_document1 := l_document1 || '<TR>' ;
l_document1 := l_document1 || '<TD nowrap><font color=black><B>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_TAX_AMOUNT') || '</B></font></TD> ' ;
l_document1 := l_document1 || '<TD nowrap><font color=black>' ||
                      x_tax_amount || '</font></TD> ' ;
l_document1 := l_document1 || '</TR>' ;

l_document1 := l_document1 || '</TABLE></P>' ;


ELSE
 wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'INVOICE_INFO',
                            avalue      => ''
                            );

  wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'INVOICE_NUM',
                            avalue      => ''
                            );

END IF;

 -- This Attribute is not being set to l_document any more , moved to the body section as pl/sql clob

     wf_engine.SetItemAttrText
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'ASN_HEADERS',
                            avalue      => ''
                            );

-- Set the Buyer Count and Current Number in the Workflow
    wf_engine.SetItemAttrNumber
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'TOTAL_BUYER_NUM',
                            avalue      => asn_buyers.COUNT
                            );
    wf_engine.SetItemAttrNumber
                            (
                            ItemType    => l_item_type,
                            ItemKey     => l_item_key,
                            aname       => 'CURR_BUYER_NUM',
                            avalue      => 1
                            );

END GET_ASN_BUYERS;



PROCEDURE GENERATE_ASN_BODY(p_ship_num_buyer_id IN VARCHAR2,
			    display_type   in      Varchar2,
			    document in OUT NOCOPY clob,
			    document_type  in OUT NOCOPY  varchar2)
IS

TYPE asn_lines_record is record (
po_num          po_headers_all.segment1%TYPE,
po_rev_no       po_headers_all.revision_num%TYPE,
line_num        po_lines_all.line_num%TYPE,
ship_num        po_line_locations_all.shipment_num%TYPE,
item_num        varchar2(80),
item_desc       po_lines_all.item_description%TYPE,
uom             po_lines_all.unit_meas_lookup_code%TYPE,
order_qty       po_line_locations_all.quantity%TYPE,
ship_qty        rcv_transactions_interface.quantity%TYPE,
--rcvd_qty        po_line_locations_all.quantity_received%type,
rcvd_qty        NUMBER,
ship_to         rcv_transactions_interface.ship_to_location_code%type,
ship_to_org     org_organization_definitions.ORGANIZATION_CODE%type
);

NL              VARCHAR2(1) := fnd_global.newline;
l_document      VARCHAR2(32000) := '';
l_asn_lines     asn_lines_record;
x_shipment_num  pos_lines_v.shipment_num%TYPE;
x_buyer_id		NUMBER;
x_vendor_id		NUMBER;
x_vendor_site_id	NUMBER;
x_num_lines		NUMBER;
x_bvs_id		VARCHAR2(50);
x_vs_id			VARCHAR2(50);

h_shipment_num  pos_headers_v.shipment_num%TYPE;
h_asn_type      VARCHAR2(20);
h_vendor_name   VARCHAR2(240);
h_shipped_date  varchar2(2000);
h_expected_receipt_date varchar2(2000);
h_invoice_num   VARCHAR2(50);
h_total_invoice_amount  NUMBER;
h_invoice_date  DATE;
h_tax_amount    NUMBER;

l_remit_to_site_id	NUMBER;
l_remit_to_site_code	PO_VENDOR_SITES_ALL.vendor_site_code%TYPE;
l_remit_to_address1	PO_VENDOR_SITES_ALL.address_line1%TYPE;
l_remit_to_address2	PO_VENDOR_SITES_ALL.address_line2%TYPE;
l_remit_to_address3	PO_VENDOR_SITES_ALL.address_line3%TYPE;
l_remit_to_address4	PO_VENDOR_SITES_ALL.address_line4%TYPE;
l_remit_to_czinfo	VARCHAR2(200);
l_remit_to_country	PO_VENDOR_SITES_ALL.country%TYPE;

l_remit_exist_flag	VARCHAR2(1) := 'T';


CURSOR asn_lines(p_shipment_num varchar2,v_buyer_id number,p_vendor_id number,p_vendor_site_id number) IS
SELECT
      DECODE(PRL.PO_RELEASE_ID,NULL,PH.SEGMENT1,PH.SEGMENT1 || '-' || TO_CHAR(PRL.RELEASE_NUM)) PO_NUM,
      ph.revision_num REVISION_NUM,
      pola.line_num LINE_NUM,
      pll.shipment_num SHIPMENT_NUM,
      pos_get.get_item_number(rti.item_id,ood.organization_id) ITEM_NUM,
      pola.item_description ITEM_DESC,
      pola.unit_meas_lookup_code UOM,
      pll.quantity QUANTITY_ORDERED,
      rti.quantity QUANTITY_SHIPPED,
      pll.quantity_received QUANTITY_RECEIVED,
      NVL( HRL.LOCATION_CODE,
      SUBSTR(RTRIM(HZ.ADDRESS1)||'-'||RTRIM(HZ.CITY),1,20)) ship_to_location_code,
      ood.ORGANIZATION_CODE ORGANIZATION_CODE
FROM  rcv_transactions_interface rti, rcv_headers_interface rhi ,
      org_organization_definitions ood,po_releases_all prl,
      po_line_locations_all pll,po_lines_all pola,po_headers_all ph,
      hr_locations_all_tl hrl, hz_locations hz
WHERE rhi.header_interface_id=rti.header_interface_id and
      rhi.shipment_num= p_shipment_num and
      pola.po_line_id = rti.po_line_id and
      ph.agent_id=v_buyer_id and
      pll.po_release_id = prl.po_release_id(+) and
      pll.line_location_id=rti.po_line_location_id and
      ood.organization_id = pll.ship_to_organization_id  and
      ph.po_header_id = rti.po_header_id and
      rti.vendor_id   = p_vendor_id and
      rti.vendor_site_id = p_vendor_site_id and
      HRL.LOCATION_ID (+) = rti.SHIP_TO_LOCATION_ID AND
      HRL.LANGUAGE(+) = USERENV('LANG') AND
      HZ.LOCATION_ID(+) = rti.SHIP_TO_LOCATION_ID
UNION ALL
SELECT
      DECODE(PRL.PO_RELEASE_ID,NULL,PH.SEGMENT1,PH.SEGMENT1 || '-' || TO_CHAR(PRL.RELEASE_NUM)) PO_NUM,
      ph.revision_num REVISION_NUM,
      pola.line_num LINE_NUM,
      pll.shipment_num SHIPMENT_NUM,
      pos_get.get_item_number(rsl.item_id,ood.organization_id) ITEM_NUM,
      pola.item_description ITEM_DESC,
      pola.unit_meas_lookup_code UOM,
      pll.quantity QUANTITY_ORDERED,
      rsl.quantity_shipped QUANTITY_SHIPPED,
      pll.quantity_received QUANTITY_RECEIVED,
      NVL( HRL.LOCATION_CODE,
      SUBSTR(RTRIM(HZ.ADDRESS1)||'-'||RTRIM(HZ.CITY),1,20)) ship_to_location_code,
      ood.ORGANIZATION_CODE ORGANIZATION_CODE
FROM  rcv_shipment_lines rsl, rcv_shipment_headers rsh ,
      org_organization_definitions ood,po_releases_all prl,
      po_line_locations_all pll,po_lines_all pola,po_headers_all ph,
      hr_locations_all_tl hrl,hz_locations hz
WHERE rsh.shipment_header_id=rsl.shipment_header_id and
      rsh.shipment_num= p_shipment_num and
      pola.po_line_id = rsl.po_line_id and
      ph.agent_id=v_buyer_id and
      pll.po_release_id = prl.po_release_id(+) and
      pll.line_location_id=rsl.po_line_location_id and
      ood.organization_id = pll.ship_to_organization_id  and
      ph.po_header_id = rsl.po_header_id and
      HRL.LOCATION_ID (+) = rsl.SHIP_TO_LOCATION_ID AND
      HRL.LANGUAGE(+) = USERENV('LANG') AND
      HZ.LOCATION_ID(+) = rsl.SHIP_TO_LOCATION_ID and
      rsh.vendor_id = p_vendor_id and
      rsh.vendor_site_id=p_vendor_site_id;


BEGIN

x_shipment_num   := substr(p_ship_num_buyer_id,1,instr(p_ship_num_buyer_id,'*%$*')-1);
x_bvs_id         := substr(p_ship_num_buyer_id,instr(p_ship_num_buyer_id,'*%$*')+ 4,length(p_ship_num_buyer_id)-2);
x_buyer_id       := substr(x_bvs_id,1,instr(x_bvs_id, '%')- 1);
x_vs_id          := substr(x_bvs_id,instr(x_bvs_id,'%')+1,length(x_bvs_id)-2);
x_vendor_id      := substr(x_vs_id,1,instr(x_vs_id,'#')-1);
x_vendor_site_id := substr(x_vs_id,instr(x_vs_id,'#')+ 1,length(x_vs_id)-2);

--Generate the Header

     BEGIN

	SELECT distinct poh.shipment_num,pov.vendor_name,
		to_char(poh.shipped_date,fnd_profile.value_wnps('ICX_DATE_FORMAT_MASK')||' HH24:MI:SS'),
		to_char(poh.expected_receipt_date,fnd_profile.value_wnps('ICX_DATE_FORMAT_MASK')||' HH24:MI:SS'),
       		poh.invoice_num,poh.total_invoice_amount,
       		poh.invoice_date,
       		poh.tax_amount,poh.asn_type,
                poh.remit_to_site_id
	INTO   h_shipment_num,h_vendor_name,
		h_shipped_date,
		h_expected_receipt_date,
       		h_invoice_num,h_total_invoice_amount,
       		h_invoice_date,
       		h_tax_amount,h_asn_type,
                l_remit_to_site_id
	FROM   POS_HEADERS_V poh,PO_VENDORS pov
	WHERE  poh.shipment_num   = x_shipment_num AND
               poh.vendor_id      = pov.vendor_id  AND
               poh.vendor_id      = to_number(x_vendor_id)   AND
               poh.vendor_site_id = to_number(x_vendor_site_id);
     EXCEPTION
        WHEN NO_DATA_FOUND then
        l_document := 'NO_DATA';
        WHEN OTHERS then
        RAISE;
     END;

if (l_document = 'NO_DATA') then
        -- if you didnt find any data in the headers do not draw the header section at all
        l_document := '';
else


  if (l_remit_to_site_id is not null) then
    BEGIN

      SELECT pvs.VENDOR_SITE_CODE,
             pvs.address_line1,
             pvs.address_line2,
             pvs.address_line3,
             pvs.address_line4,
             pvs.city || ', ' || pvs.state || ' ' || pvs.zip,
	     pvs.country
      INTO   l_remit_to_site_code,
	     l_remit_to_address1,
	     l_remit_to_address2,
	     l_remit_to_address3,
	     l_remit_to_address4,
	     l_remit_to_czinfo,
             l_remit_to_country
      FROM   PO_VENDOR_SITES_ALL pvs
      WHERE  pvs.vendor_site_id = l_remit_to_site_id;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_remit_exist_flag := 'F';

      WHEN OTHERS then
        RAISE;
    END;

  end if;

l_document :=  l_document || NL || NL || '<font size=3 color=#336699 face=arial><b>' ||fnd_message.get_string('POS', 'POS_ASN_NOTIF_DETAILS') || '</B></font><HR size=1 color=#cccc99>' ;

l_document := l_document || '<TABLE cellpadding=2 cellspacing=1>';

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                     fnd_message.get_string('POS', 'POS_ASN_NOTIF_SUPP_NAME') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || h_vendor_name || '</B></TD> ' ;
l_document := l_document || '</TR>' ;

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_SHIPMENT_NUM') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || h_shipment_num || '</B></TD> ' ;
l_document := l_document || '</TR>' ;

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_SHIPMENT_DATE') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || h_shipped_date || '</B></TD> ' ;
l_document := l_document || '</TR>' ;

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_EXPT_RCPT_DATE') || '</TD> ';
l_document := l_document || '<TD nowrap><B>' || h_expected_receipt_date || '</B></TD> ' ;
l_document := l_document || '</TR>' ;

l_document := l_document || '</TABLE></P>' ;


IF (h_asn_type = 'ASBN') THEN

l_document := l_document || '<font size=3 color=#336699 face=arial><b>'||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_BILL_INFO') ||'</B></font><HR size=1 color=#cccc99>' ;

l_document := l_document || '<TABLE  cellpadding=2 cellspacing=1>' ;

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_INVOICE_NUMBER') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' ||
                      h_invoice_num || '</B></TD> ' ;
l_document := l_document || '</TR>' ;

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                       fnd_message.get_string('POS', 'POS_ASN_NOTIF_INVOICE_AMOUNT') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' ||
                      h_total_invoice_amount || '</B></TD> ' ;
l_document := l_document || '</TR>' ;

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_INVOICE_DATE') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || h_invoice_date || '</B></TD></TR>' ;

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_TAX_AMOUNT') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || h_tax_amount || '</B></TD> ' ;
l_document := l_document || '</TR>' ;

--mji Remit-to Info
IF (l_remit_exist_flag = 'T') THEN

l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_REMIT_NAME') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || l_remit_to_site_code || '</B></TD></TR>' ;


l_document := l_document || '<TR>' ;
l_document := l_document || '<TD nowrap>' ||
                      fnd_message.get_string('POS', 'POS_ASN_NOTIF_REMIT_ADDR') || '</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || l_remit_to_address1 || '</B></TD></TR>' ;


if (l_remit_to_address2 is not null) then
  l_document := l_document || '<TR>' ;
  l_document := l_document || '<TD>&nbsp</TD> ' ;
  l_document := l_document || '<TD nowrap><B>' || l_remit_to_address2 || '</B></TD> ' ;
  l_document := l_document || '</TR>' ;
end if;


if (l_remit_to_address3 is not null) then
  l_document := l_document || '<TR>' ;
  l_document := l_document || '<TD>&nbsp</TD> ' ;
  l_document := l_document || '<TD nowrap><B>' || l_remit_to_address3 || '</B></TD> ' ;
  l_document := l_document || '</TR>' ;
end if;


if (l_remit_to_address4 is not null) then
  l_document := l_document || '<TR>' ;
  l_document := l_document || '<TD>&nbsp</TD> ' ;
  l_document := l_document || '<TD nowrap><B>' || l_remit_to_address4 || '</B></TD> ' ;
  l_document := l_document || '</TR>' ;
end if;


l_document := l_document || '<TR>' ;
l_document := l_document || '<TD>&nbsp</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || l_remit_to_czinfo || '</B></TD> ' ;
l_document := l_document || '</TR>' ;


l_document := l_document || '<TR>' ;
l_document := l_document || '<TD>&nbsp</TD> ' ;
l_document := l_document || '<TD nowrap><B>' || l_remit_to_country || '</B></TD> ' ;
l_document := l_document || '</TR>' ;

END IF;

l_document := l_document || '</TABLE></P>' ;

END IF;
end if ; -- end of if no data
-- End of Header Info


-- check if notification was cancelled then do not generate the table
select count(*) into x_num_lines from pos_headers_v
where shipment_num=x_shipment_num and
vendor_id  = x_vendor_id and
vendor_site_id = x_vendor_site_id;

if (x_num_lines < 1) then
	l_document := '';
	l_document := fnd_message.get_string('POS', 'POS_ASN_NOTIF_CANCELLED');

 	WF_NOTIFICATION.WriteToClob(document, l_document);

else
OPEN asn_lines(x_shipment_num,x_buyer_id,x_vendor_id,x_vendor_site_id);


--Generate HTML TABLE HEADER
l_document := l_document || NL || NL ||'<font size=3 color=#336699 face=arial><b>'||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_ASN_DTLS') ||'</B></font><HR size=1 color=#cccc99>'|| NL ;

l_document := l_document || '<TABLE WIDTH=100% cellpadding=2 cellspacing=1>';
l_document := l_document || '<TR bgcolor=#cccc99>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_ORDER_NUMBER') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_REVISION_NUMBER') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_LINE_NUM') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_SHIP_NUM') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_ITEM') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_ITEM_DESC') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_UOM') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS','POS_ASN_NOTIF_QUANTITY_ORD') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS','POS_ASN_NOTIF_QUANTITY_SHIP') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS','POS_ASN_NOTIF_QUANTITY_RCVD') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left nowrap><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_SHIP_TO') || '</font></TH>' || NL;

l_document := l_document || '<TH align=left><font color=#336699 >' ||
                fnd_message.get_string('POS', 'POS_ASN_NOTIF_SHIP_TO_ORG') || '</font></TH>' || NL;

l_document := l_document || '</TR>' || NL;

l_document := l_document || '</B>';

     LOOP

        FETCH asn_lines INTO l_asn_lines;
        EXIT WHEN asn_lines%NOTFOUND;

        l_document := l_document || '<TR bgcolor=#f7f7e7>' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(l_asn_lines.po_num, '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(to_char(l_asn_lines.po_rev_no), '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(to_char(l_asn_lines.line_num), '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(to_char(l_asn_lines.ship_num), '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(l_asn_lines.item_num, '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(l_asn_lines.item_desc, '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(l_asn_lines.uom, '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(to_char(l_asn_lines.order_qty), '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(to_char(l_asn_lines.ship_qty), '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(to_char(l_asn_lines.rcvd_qty), '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD nowrap><font color=black>' ||
                      nvl(l_asn_lines.ship_to, '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '<TD><font color=black>' ||
                      nvl(l_asn_lines.ship_to_org, '&nbsp') || '</font></TD> ' || NL;

        l_document := l_document || '</TR>' || NL;

 	WF_NOTIFICATION.WriteToClob(document, l_document);
	l_document := null;
     END LOOP;

     CLOSE asn_lines;

	l_document := l_document || '</TABLE></P>' || NL;

 	WF_NOTIFICATION.WriteToClob(document, l_document);
end if;

EXCEPTION
WHEN OTHERS THEN
    RAISE;
END GENERATE_ASN_BODY;

END POS_ASN_NOTIF;
/