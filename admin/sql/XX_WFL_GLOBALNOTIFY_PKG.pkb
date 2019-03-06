SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_wfl_globalnotify_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : xx_wfl_globalnotify_pkg                                     |
-- | Rice ID     : E0270_GlobalNotification                                    |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 10-Jul-2007  Pankaj Kapse           Initial draft version         |
-- |                                                                           |
-- +===========================================================================+

AS
    -- +===================================================================+
    -- | Name        : Write_Exception                                     |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :  Error_Code                                          |
    -- |               Error_Description                                   |
    -- |               Entity_Reference                                    |
    -- |               Entity_Reference_Id                                 |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE Write_Exception(
                               p_error_code        IN  VARCHAR2
                              ,p_error_description IN  VARCHAR2
                              ,p_entity_reference  IN  VARCHAR2
                              ,p_entity_ref_id     IN  VARCHAR2
                             )
    IS

     lc_errbuf    VARCHAR2(4000);
     lc_retcode   VARCHAR2(4000);

    BEGIN                               -- Procedure Block

     ge_exception.p_error_code        := p_error_code;
     ge_exception.p_error_description := p_error_description;
     ge_exception.p_entity_ref        := p_entity_reference;
     ge_exception.p_entity_ref_id     := p_entity_ref_id;

     xx_om_global_exception_pkg.Insert_Exception(
                                                  ge_exception
                                                 ,lc_errbuf
                                                 ,lc_retcode
                                                );

    END Write_Exception;    -- End Procedure Block

    -- +===================================================================+
    -- | Name        : get_schedule_arrival_date                           |
    -- | Description : Function to get the schedule arrival date           |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |               p_order_header_id                                   |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |               ld_arrival_date                                     |
    -- +===================================================================+

    FUNCTION get_schedule_arrival_date (
                                        p_order_header_id IN PLS_INTEGER
                                       )
    RETURN DATE
    AS

       ld_arrival_date    DATE;

       lc_errbuf          VARCHAR2(4000);
       lc_err_code        VARCHAR2(1000);

       CURSOR lcu_schedule_arrival_date (p_header_id IN PLS_INTEGER) IS
       SELECT TO_DATE(RCT.transaction_date,'DD/MM/RRRR') transaction_date
       FROM   oe_order_headers OHA
             ,oe_drop_ship_sources ODSS
             ,rcv_transactions     RCT
       WHERE OHA.header_id          = ODSS.header_id
       AND   ODSS.po_header_id      = RCT.po_header_id
       AND   RCT.transaction_type   = 'DELIVER'
       AND   OHA.header_id          = p_header_id
       GROUP BY TO_DATE(RCT.transaction_date,'DD/MM/RRRR');

    BEGIN

        FOR lr_schedule_arrival_date IN lcu_schedule_arrival_date(p_order_header_id)
        LOOP

           ld_arrival_date := lr_schedule_arrival_date.transaction_date;

        END LOOP;

        RETURN(ld_arrival_date);

    EXCEPTION
    WHEN OTHERS THEN

       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

       lc_errbuf   := FND_MESSAGE.GET;
       lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR1';

       -- -------------------------------------
       -- Call the Write_Exception procedure to
       -- insert into Global Exception Table
       -- -------------------------------------

       Write_Exception (
                         p_error_code        => lc_err_code
                        ,p_error_description => lc_errbuf
                        ,p_entity_reference  => 'Order Header Id'
                        ,p_entity_ref_id     => gn_header_id
                     );
    END get_schedule_arrival_date;

    -- +===================================================================+
    -- | Name        : get_customer_item                                   |
    -- | Description : Function to get customer's item number              |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |               p_order_item_id                                     |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |               lc_customer_item                                    |
    -- +===================================================================+

    FUNCTION get_customer_item(
                               p_order_item_id IN PLS_INTEGER
                              )
    RETURN VARCHAR2
    AS

       lc_customer_item    VARCHAR2(100);

       lc_errbuf          VARCHAR2(4000);
       lc_err_code        VARCHAR2(1000);

       CURSOR lcu_customer_item(p_item_id IN PLS_INTEGER) IS
       SELECT MCR.cross_reference item_number
       FROM   mtl_cross_references MCR
       WHERE inventory_item_id = P_item_id;

    BEGIN

       FOR lr_customer_item IN lcu_customer_item(p_order_item_id)
       LOOP

          lc_customer_item := lr_customer_item.item_number;

       END LOOP;

       RETURN(lc_customer_item);
    EXCEPTION
    WHEN OTHERS THEN

       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

       lc_errbuf   := FND_MESSAGE.GET;
       lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR2';

       -- -------------------------------------
       -- Call the Write_Exception procedure to
       -- insert into Global Exception Table
       -- -------------------------------------

       Write_Exception (
                         p_error_code        => lc_err_code
                        ,p_error_description => lc_errbuf
                        ,p_entity_reference  => 'Order Header Id'
                        ,p_entity_ref_id     => gn_header_id
                 );

    END get_customer_item;

    -- +===================================================================+
    -- | Name        : get_carrier_info                                    |
    -- | Description : Function to get carrier information                 |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |               p_order_header_id                                   |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |               lc_carrier_name                                     |
    -- +===================================================================+

    FUNCTION get_carrier_info(
                               p_order_header_id IN PLS_INTEGER
                              )
    RETURN VARCHAR2
    AS
       lc_carrier_name    VARCHAR2(1000);

       lc_errbuf          VARCHAR2(4000);
       lc_err_code        VARCHAR2(1000);

       CURSOR lc_carrier_info(p_header_id PLS_INTEGER)IS
       SELECT WC.carrier_name
       FROM  oe_order_headers OHA
            ,hz_cust_accounts     HCA
            ,wsh_carriers_v       WC
       WHERE OHA.sold_to_org_id = HCA.cust_account_id
       AND   HCA.party_id       = WC.carrier_id
       AND   OHA.header_id      = p_header_id;

    BEGIN
       FOR lr_carrier_info IN lc_carrier_info(p_order_header_id)
       LOOP

          lc_carrier_name := lr_carrier_info.carrier_name;

       END LOOP;

       RETURN(lc_carrier_name);

    EXCEPTION
    WHEN OTHERS THEN

       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

       lc_errbuf   := FND_MESSAGE.GET;
       lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR2';

       -- -------------------------------------
       -- Call the Write_Exception procedure to
       -- insert into Global Exception Table
       -- -------------------------------------

       Write_Exception (
                         p_error_code        => lc_err_code
                        ,p_error_description => lc_errbuf
                        ,p_entity_reference  => 'Order Header Id'
                        ,p_entity_ref_id     => gn_header_id
                 );

    END get_carrier_info;
    
    -- +===================================================================+
    -- | Name        : get_warehouse_info                                  |
    -- | Description : Function to get warehouse information               |
    -- |                                                                   |
    -- | Parameters :                                                      |
    -- |               p_header_id                                         |
    -- |                                                                   |
    -- | Returns :                                                         |
    -- |               lc_warehouse_address                                |
    -- +===================================================================+

    FUNCTION get_warehouse_info(
                                p_header_id IN PLS_INTEGER
                               )
    RETURN VARCHAR2
    AS
       lc_warehouse_address VARCHAR2(1000);

       lc_errbuf            VARCHAR2(4000);
       lc_err_code          VARCHAR2(1000);

       CURSOR lc_warehouse_info(p_order_id PLS_INTEGER)IS
       SELECT HLJ.address_line_1||' '||HLJ.address_line_1||' '||HLJ.town_or_city||' '||HLJ.country||' '||HLJ.postal_code Address
       FROM  oe_order_headers   OHA 
            ,hr_organization_units HOU
            ,hr_locations_no_join  HLJ
       WHERE OHA.ship_from_org_id = HOU.organization_id 
       AND   HOU.location_id      = HLJ.location_id
       AND   OHA.header_id        = p_order_id;

    BEGIN
       FOR lr_warehouse_info IN lc_warehouse_info(p_header_id)
       LOOP

          lc_warehouse_address := lr_warehouse_info.Address;

       END LOOP;

       RETURN(lc_warehouse_address);

    EXCEPTION
    WHEN OTHERS THEN

       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

       lc_errbuf   := FND_MESSAGE.GET;
       lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR2';

       -- -------------------------------------
       -- Call the Write_Exception procedure to
       -- insert into Global Exception Table
       -- -------------------------------------

       Write_Exception (
                         p_error_code        => lc_err_code
                        ,p_error_description => lc_errbuf
                        ,p_entity_reference  => 'Order Header Id'
                        ,p_entity_ref_id     => gn_header_id
                 );

    END get_warehouse_info;

    -- +===================================================================+
    -- | Name        : generate_message                                    |
    -- | Description : Procedure is used to generate the message           |
    -- |                                                                   |
    -- |                                                                   |
    -- | Parameters :  p_document_id                                       |
    -- |               p_display_type                                      |
    -- |               p_document                                          |
    -- |               p_document_type                                     |
    -- +===================================================================+

    PROCEDURE generate_message(
                               p_document_id   IN     VARCHAR2
                              ,p_display_type  IN     VARCHAR2
                              ,p_document      IN OUT CLOB
                              ,p_document_type IN OUT VARCHAR2
                              )
        IS

           ln_header_id         PLS_INTEGER;
           lc_cause             VARCHAR2(1000);

           --
           -- Order Header Attributes
           --

           ln_order_number      PLS_INTEGER;
           ld_arrival_date      DATE;
           lc_my_po             VARCHAR2(100);
           lc_loc               VARCHAR2(1000);
           lc_my_cc             VARCHAR2(100);
           lc_my_rel            VARCHAR2(100);
           lc_my_desk           VARCHAR2(100);
           lc_comments          VARCHAR2(1000);
           lc_flow_status_code  VARCHAR2(20);
           ld_ordered_date      DATE;
           lc_account_number    VARCHAR2(100);
           lc_customer_name     VARCHAR2(100);
           lc_created_by        VARCHAR2(20);
           lc_ship_to           VARCHAR2(1000);
           lc_contact           VARCHAR2(1000);
           lc_currency          VARCHAR2(10);
           lc_payment_type      VARCHAR2(100);
           ln_sub_total         PLS_INTEGER:=0;
           ln_taxes             PLS_INTEGER:=0;
           ln_charges           PLS_INTEGER:=0;
           ln_misc              PLS_INTEGER:=0;
           ln_discount          PLS_INTEGER:=0;
           ln_total_amount      PLS_INTEGER:=0;
           lc_document          VARCHAR2(100);
           lc_document1         CLOB:=NULL;
           lc_document2         CLOB:=NULL;
           lc_document3         CLOB:=NULL;
           lc_line_document     CLOB:=NULL;
           lc_line_header       CLOB:=NULL; 

           --
           -- Order Line Attributes
           --
           ln_line_number         PLS_INTEGER;
           lc_sku                 VARCHAR2(1000);
           lc_customer_item       VARCHAR2(1000);
           lc_Item_Description    VARCHAR2(1000);
           ln_ordered_qty         PLS_INTEGER;
           ln_shipped_qty         PLS_INTEGER;
           ln_backordered_qty     PLS_INTEGER;
           lc_uom                 VARCHAR2(20);
           ln_unit_price          PLS_INTEGER;
           ln_extended_price      PLS_INTEGER;
           lc_carrier_no          VARCHAR2(100);
           lc_carrier_name        VARCHAR2(1000);
           lc_mail_format         VARCHAR2(100);

           --
           -- Exception Variable
           --
           lc_errbuf          VARCHAR2(4000);
           lc_err_code        VARCHAR2(1000);

           --
           -- Order header - Cursor
           --
           CURSOR lcu_order_header_details (p_header_id PLS_INTEGER)IS
           SELECT order_number
                 ,schedule_arrival_date
                 ,my_po
                 ,loc
                 ,my_cc
                 ,my_rel
                 ,my_desk
                 ,comments
                 ,flow_status_code
                 ,ordered_date
                 ,account_number
                 ,customer_name
                 ,created_by
                 ,ship_to
                 ,Contact
                 ,currency
                 ,payment_type
                 ,misc
           FROM
              (
                SELECT  OHA.order_number                                                                 order_number
                       ,DECODE(OLA.SOURCE_TYPE_CODE,'EXTERNAL',get_schedule_arrival_date(OHA.header_id)
                                                              ,OLA.schedule_arrival_date)               schedule_arrival_date
                       ,OHA.cust_po_number                                                              my_po
                       ,get_warehouse_info(OHA.header_id)                                               loc
                       ,OHA.attribute2                                                                  my_cc
                       ,OHA.attribute1                                                                  my_rel
                       ,OHA.attribute3                                                                  my_desk
                       ,OHA.attribute10                                                                 comments
                       ,OHA.flow_status_code                                                            flow_status_code
                       ,OHA.ordered_date                                                                ordered_date
                       ,HCA.account_number                                                              account_number
                       ,HP.party_name                                                                   customer_name
                       ,FND.user_name                                                                   created_by
                       ,HL.address1||' '||HL.address2||' '||HL.address3||' '||HL.address4               ship_to
                       ,HP.person_first_name||' '||HP.person_last_name                                  Contact
                       ,FC.name                                                                         currency
                       ,OL.meaning                                                                      payment_type
                       ,0                                                                               misc
                 FROM  oe_order_headers        OHA
                      ,oe_order_lines          OLA
                      ,oe_transaction_types_tl OTL
                      ,hz_cust_accounts        HCA
                      ,hz_parties              HP
                      ,fnd_user                FND
                      ,hz_cust_acct_sites      HCAS
                      ,hz_cust_site_uses       HCSU
                      ,hz_locations            HL
                      ,hz_party_sites          HPS
                      ,fnd_currencies_vl       FC
                      ,oe_lookups              OL
                 WHERE OHA.header_id                   = OLA.header_id
                 AND   OHA.order_type_id               = OTL.transaction_type_id
                 AND   OTL.LANGUAGE                    = USERENV('LANG')
                 AND   OHA.sold_to_org_id              = HCA.cust_account_id
                 AND   HCA.cust_account_id             = HCAS.cust_account_id
                 AND   HCA.party_id                    = HP.party_id
                 AND   HCSU.site_use_code              = 'SHIP_TO'
                 AND   HCSU.primary_flag               = 'Y'
                 AND   HCAS.cust_acct_site_id          = HCSU.cust_acct_site_id
                 AND   HCAS.party_site_id              = HPS.party_site_id
                 AND   HPS.location_id                 = HL.location_id
                 AND   OHA.transactional_curr_code     = FC.currency_code
                 AND   FND.user_id                     = OHA.created_by
                 AND   OL.lookup_type                  = 'OE_PAYMENT_TYPE'
                 AND   OL.lookup_code                  = OHA.Payment_Type_Code
                 AND   OHA.header_id                   = p_header_id
              )
           GROUP BY schedule_arrival_date
                   ,order_number
                   ,my_po
                   ,loc
                   ,my_cc
                   ,my_rel
                   ,my_desk
                   ,comments
                   ,flow_status_code
                   ,ordered_date
                   ,account_number
                   ,customer_name
                   ,created_by
                   ,ship_to
                   ,Contact
                   ,currency
                   ,payment_type
                   ,misc;

           --
           -- Order Line - Cursor
           --
           CURSOR lcu_order_line_details (p_order_header_id PLS_INTEGER)IS
           SELECT OLA.line_number                                                        line_number
                 ,MSI.concatenated_segments                                              sku
                 ,DECODE(item_identifier_type,'CUST',get_customer_item(OLA.ordered_item)
                                             ,OLA.ordered_item)                          customer_item
                 ,NVL(OLA.User_item_description,MSI.DESCRIPTION)                         Item_Description
                 ,NVL(OLA.Ordered_quantity,0)                                            ordered_qty
                 ,NVL(OLA.shipped_quantity,0)                                            shipped_qty
                 ,(NVL(OLA.ordered_quantity,0) - NVL(OLA.shipped_quantity,0))            backordered_qty
                 ,OLA.Order_quantity_uom                                                 uom
                 ,OLA.Unit_selling_price                                                 unit_price
                 ,(OLA.Unit_selling_price * OLA.ordered_quantity)                        extended_price
                 ,NULL                                                                   carrier_no
                 ,get_carrier_info(OHA.header_id)                                        carrier_name
           FROM  oe_order_lines      OLA
                ,oe_order_headers    OHA
                ,oe_transaction_types_tl OTL
                ,mtl_system_items_b_kfv  MSI
           WHERE OHA.header_id                  = p_order_header_id
           AND   OHA.header_id                  = OLA.header_id
           AND   OHA.order_type_id              = OTL.Transaction_Type_Id
           AND   OTL.LANGUAGE                   = USERENV('LANG')
           AND   OLA.inventory_item_id          = MSI.inventory_item_id
           AND   OLA.ship_from_org_id           = MSI.organization_id
           AND   MSI.inventory_item_status_code = 'Active';

        BEGIN

           ln_header_id   := TO_NUMBER(SUBSTR(p_document_id,2,INSTR(p_document_id,'#')-INSTR(p_document_id,'@')-1));
           lc_cause       := SUBSTR(p_document_id,INSTR(p_document_id,'#')+1,(INSTR(p_document_id,'-')- 1)-INSTR(p_document_id,'#'));
           lc_mail_format := SUBSTR(p_document_id,INSTR(p_document_id,'-')+1,LENGTH(p_document_id));

            --
            --Cursor for Order Header Information
            --
            FOR lr_order_header_details IN lcu_order_header_details(ln_header_id)-- Order Header Loop Start
            LOOP

               ln_order_number      := lr_order_header_details.order_number;
               ld_arrival_date      := lr_order_header_details.schedule_arrival_date;
               lc_my_po             := lr_order_header_details.my_po;
               lc_loc               := lr_order_header_details.loc;
               lc_my_cc             := lr_order_header_details.my_cc;
               lc_my_rel            := lr_order_header_details.my_rel;
               lc_my_desk           := lr_order_header_details.my_desk;
               lc_comments          := lr_order_header_details.comments;
               lc_flow_status_code  := lr_order_header_details.flow_status_code;
               ld_ordered_date      := lr_order_header_details.ordered_date;
               lc_account_number    := lr_order_header_details.account_number;
               lc_customer_name     := lr_order_header_details.customer_name;
               lc_created_by        := lr_order_header_details.created_by;
               lc_ship_to           := lr_order_header_details.ship_to;
               lc_contact           := lr_order_header_details.Contact;
               lc_currency          := lr_order_header_details.currency;
               lc_payment_type      := lr_order_header_details.payment_type;
               ln_misc              := lr_order_header_details.misc;
               
               --
               -- Deriving order Information
               --
               oe_oe_totals_summary.order_totals(ln_header_id
                                                ,ln_sub_total
                                                ,ln_discount
                                                ,ln_charges
                                                ,ln_taxes
                                                );
                                                
               ln_total_amount      := ln_sub_total + ln_charges + ln_taxes;
 
               IF lc_mail_format = 'MAILHTML' THEN

                  lc_document1:= '<html>';
                  lc_document1:=lc_document1||'<head>';
                  lc_document1:=lc_document1||'<title></title>';
                  lc_document1:=lc_document1||'</head>';
                  lc_document1:=lc_document1||'<body>';
                  lc_document1:=lc_document1||'<table border="0"  width="100%" cellspacing="17">
                                                <tr width="100">
                                                   <td><div align="center"><B><font face="Verdana" Size ="2" color="#FF0000">'||lc_cause||'</font></B></DIV></td>
                                                </tr>
                                              </table>';
                  lc_document1:=lc_document1||'<table border="1"  width="100%" cellspacing="8" bgcolor="#0000FF">
                                                <tr width="100">
                                                   <td></td>
                                                </tr>
                                                </table>';


                  lc_document1:= lc_document1||'<table border="1"  width="100%" cellspacing="0"><!-- Header Level -->
                                                <tr width="100%">
                                                 <tr width="100%"><!-- Row 1 -->
                                                    <td width="20%"><B><font face="Verdana" Size ="2">Order #:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||ln_order_number||'</font></DIV></td>
                                                    <td width="20%"><B><font face="Verdana" Size ="2">User Name:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_created_by||'</font></DIV></td>
                                                  </tr>
                                                  <tr width="100%"><!-- Row 2 -->
                                                    <td width="20%"><B><font face="Verdana" Size ="2">Order Date:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||ld_ordered_date||'</font></DIV></td>
                                                    <td width="20%"><B><font face="Verdana" Size ="2">Customer #:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_account_number||'</font></DIV></td>
                                                  </tr>
                                                  <tr width="100%"><!-- Row 3 -->
                                                    <td width="20%"><B><font face="Verdana" Size ="2">Currency:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_currency||'</font></DIV></td>
                                                    <td width="20%"><B><font face="Verdana" Size ="2">My PO:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_my_po||'</font></DIV></td>
                                                  </tr>
                                                  <tr width="100%"><!-- Row 4 -->
                                                    <td width="20%"><B><font face="Verdana" Size ="2">LOC:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||NULL||'</font></DIV></td>
                                                    <td width="20%"><B><font face="Verdana" Size ="2">Contact:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_contact||'</font></DIV></td>
                                                  </tr>
                                                  <tr width="100%"><!-- Row 5 -->
                                                    <td width="20%"><B><font face="Verdana" Size ="2">Status:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_flow_status_code||'</font></DIV></td>
                                                    <td width="20%"><B><font face="Verdana" Size ="2">My CC:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_my_cc||'</font></DIV></td>
                                                  </tr>
                                                  <tr width="100%"><!-- Row 6 -->
                                                    <td width="20%"></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2"></font></DIV></td>
                                                    <td width="20%"><B><font face="Verdana" Size ="2">My DESK:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_my_desk||'</font></DIV></td>
                                                  </tr>
                                                  <tr width="100%"><!-- Row 7 -->
                                                    <td width="20%"><B><font face="Verdana" Size ="2">Shipment Date:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||ld_arrival_date||'</font></DIV></td>
                                                    <td width="20%"><B><font face="Verdana" Size ="2">My REL:</font></B></td>
                                                    <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_my_rel||'</font></DIV></td>
                                                  </tr>
                                                   <tr width="100%"><!-- Row 8 -->
                                                     <td width="20%"><B><font face="Verdana" Size ="2">Ship To</font></B></td>
                                                     <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_ship_to||'</font></DIV></td>
                                                     <td width="20%"><B><font face="Verdana" Size ="2">Comments:</font></B></td>
                                                     <td width="30%"><div align="center"><font face="Verdana" Size ="2">'||lc_comments||'</font></DIV></td>
                                                  </tr>
                                                  <tr width="100%"><!-- Row 8 -->
                                                     <td width="20%"><font face="Verdana" Size ="2">OFFICE DEPOT (DEFAULT) 2200 OLD GERMANTOWN RD
                                                                                                    DELRAY BEACH,FL 33445-8299</font></td>
                                                     <td width="30%"></td>
                                                     <td width="20%"></td>
                                                     <td width="30%"></td>
                                                  </tr>
                                                 </tr><!-- Row 1 -->
                                                </table><!-- Header Level -->
                                                <table border="1"  width="100%" cellspacing="8"><!-- Blank Line -->
                                                  <tr width="100">
                                                     <td></td>
                                                  </tr>
                                               </table>';
                                               
                  --                             
                  -- Line level headings
                  --
                  lc_line_header := '<table border="1"  width="100%" cellspacing="0"><!-- Line Level -->
                                      <tr width="100%">
                                        <tr width="100%" bgcolor="#CCCCCC"><!-- Line Heading -->
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Line#</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Sku</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Customer Item #</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Item Description</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Ord Qty</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Shipped Qty</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">B/O Qty</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">UM</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Unit Price</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Extended Price</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Carrier No.</font></B></DIV></td>
                                          <td width="8.3%"><div align="center"><B><font face="Verdana"Size ="2">Carrier Name</font></B></DIV></td>
                                        </tr>
                                      </tr></table>';                             
                   --
                   -- Cursor for Order Line Information
                   --
                  FOR lr_order_line_details IN lcu_order_line_details(ln_header_id)
                  LOOP
                      ln_line_number       :=lr_order_line_details.line_number;
                      lc_sku               :=lr_order_line_details.sku;
                      lc_customer_item     :=lr_order_line_details.customer_item;
                      lc_Item_Description  :=lr_order_line_details.Item_Description;
                      ln_ordered_qty       :=lr_order_line_details.ordered_qty;
                      ln_shipped_qty       :=lr_order_line_details.shipped_qty;
                      ln_backordered_qty   :=lr_order_line_details.backordered_qty;
                      lc_uom               :=lr_order_line_details.uom;
                      ln_unit_price        :=lr_order_line_details.unit_price;
                      ln_extended_price    :=lr_order_line_details.extended_price;
                      lc_carrier_no        :=lr_order_line_details.carrier_no;
                      lc_carrier_name      :=lr_order_line_details.carrier_name;

                      lc_line_document :=lc_line_document||'<table border="1"  width="100%" cellspacing="0"><!-- Line Level -->
                                                            <tr width="100%">
                                                            <tr width="100%"><!-- Line values -->
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||ln_line_number||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||lc_sku||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||lc_customer_item||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||lc_Item_Description||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||ln_ordered_qty||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||ln_shipped_qty||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||ln_backordered_qty||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||lc_uom||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||ln_unit_price||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||ln_extended_price||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||lc_carrier_no||'</font></td>
                                                              <td width="8.3%"><font face="Verdana" Size ="2">'||lc_carrier_name||'</font></td>
                                                            </tr>
                                                          </tr></table>';

                  END LOOP;

                  lc_document2 := '<table border="1"  width="100%" cellspacing="8"><!-- Blank Line -->
                                      <tr width="100">
                                         <td></td>
                                      </tr>
                                   </table>
                                   <table border="1"  width="100%" cellspacing="0" >
                                    <tr width="100%">
                                      <tr width="100%">
                                          <td width="20%" bgcolor="#CACBDD"><B><font face="Verdana" Size ="2">LEGEND</font></B></td>
                                       <td width="20%"></td>
                                       <td width="20%"></td>
                                       <td width="20%"><div align="right"><B><font face="Verdana" Size ="2" color="#0000A0">Subtotal:</font></B></DIV></td>
                                       <td width="20%"><div align="right"><font face="Verdana" Size ="2">'||ln_sub_total||'</font></DIV></td>
                                      </tr>
                                      <tr width="100%">
                                          <td width="20%"><B><font face="Verdana" Size ="2">Ord Qty:</font></B></td>
                                       <td width="20%"><font face="Verdana" Size ="2">Original Quantity Ordered</font></td>
                                        <td width="20%"></td>
                                       <td width="20%"><div align="right"><B><font face="Verdana" Size ="2">Tax:</font></B></DIV></td>
                                       <td width="20%"><div align="right"><font face="Verdana" Size ="2">'||ln_taxes||'</font></DIV></td>
                                      </tr>
                                      <tr width="100%">
                                          <td width="20%"><B><font face="Verdana" Size ="2">Shipped Qty:</font></B></td>
                                       <td width="20%"><font face="Verdana" Size ="2">Ordered Quantity - Backorder Quantity</font></td>
                                        <td width="20%"></td>
                                       <td width="20%"><div align="right"><B><font face="Verdana" Size ="2">Delivery Charge:</font></B></DIV></td>
                                       <td width="20%"><div align="right"><font face="Verdana" Size ="2">'||ln_charges||'</font></DIV></td>
                                      </tr>
                                      <tr width="100%">
                                          <td width="20%"><B><font face="Verdana" Size ="2">B/O Qty:</font></B></td>
                                       <td width="20%"><font face="Verdana" Size ="2">Backorder Quantity</font></td>
                                        <td width="20%"></td>
                                       <td width="20%"><div align="right"><B><font face="Verdana" Size ="2">Misc:</font></B></DIV></td>
                                       <td width="20%"><div align="right"><font face="Verdana" Size ="2">'||NULL||'</font></DIV></td>
                                      </tr>
                                      <tr width="100%">
                                          <td width="20%"><B><font face="Verdana" Size ="2">UM:</font></B></td>
                                       <td width="20%"><font face="Verdana" Size ="2">Unit of Measure</font></td>
                                       <td width="20%"></td>
                                       <td width="20%"></td>
                                       <td width="20%"><div align="right">_________</DIV></td>
                                      </tr>
                                      <tr width="100%">
                                          <td width="20%"><B><font face="Verdana" Size ="2">Unit Price:</font></B></td>
                                       <td width="20%"><font face="Verdana" Size ="2">Price per Individual Unit</font></td>
                                       <td width="20%"></td>
                                       <td width="20%"><div align="right"><B><font face="Verdana" Size ="2" color="#FF0000">Total:</font></B></DIV></td>
                                       <td width="20%"><div align="right"><font face="Verdana" Size ="2">'||ln_total_amount||'</font></DIV></td>
                                      </tr>
                                      <tr width="100%">
                                          <td width="20%"><B><font face="Verdana" Size ="2">Extended Price:</font></B></td>
                                       <td width="20%"><font face="Verdana" Size ="2">Ordered Quantity x Unit Price</font></td>
                                        <td width="20%"></td>
                                       <td width="20%"><div align="right"><B><font face="Verdana" Size ="2">Payment Type</font></B></DIV></td>
                                       <td width="20%"><div align="right"><font face="Verdana" Size ="2">'||lc_payment_type||'</font></DIV></td>
                                      </tr>
                                   </table>';

                   lc_document3:= '<table border="1"  width="100%" cellspacing="0">
                                   <tr width="100%">
                                    <td width="20%"><font face="Verdana" Size ="2">
                                        Thank you for ordering from Office Depot Business Services Division Online.
                                        Thank you for shopping at Office Depot Business Services Division Online.
                                        https://bsd.officedepot.com
                                        Technical Support Number (800) 269-6888.
                                    </td>
                                  </tr></table></body></html>';

                   p_document      := lc_document1||lc_line_header||lc_line_document||lc_document2||lc_document3;

                ELSIF lc_mail_format = 'MAILTEXT' OR lc_mail_format IS NULL THEN

                   lc_document  := lc_cause||CHR(13)||CHR(10);
                   
                   lc_document1 := lc_document1||'Order #   : '||ln_order_number     ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'Customer #: '||lc_account_number   ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'User Name : '||lc_created_by       ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'Order Date: '||ld_ordered_date     ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'LOC       : '||lc_loc              ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'My PO     : '||lc_my_po            ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'Contact   : '||lc_contact          ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'MY DESK   : '||lc_my_desk          ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'MY CC     : '||lc_my_cc            ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'MY REL    : '||lc_my_rel           ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'Status    : '||lc_flow_status_code ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'Comments  : '||lc_comments         ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'Ship To   : '||lc_ship_to          ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'--------'                             ||CHR(13)||CHR(10);

                   lc_document1 := lc_document1||'OFFICE DEPOT (DEFAULT)'     ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'2200 OLD GERMANTOWN RD'     ||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||'DELRAY BEACH, FL 33445-8299'||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||CHR(13)||CHR(10);
                   lc_document1 := lc_document1||CHR(13)||CHR(10);
                   
                   
                   --
                   -- Line level Heading's
                   --
                   lc_line_document  :=lc_line_document||RPAD('SKU',10,' ')    ||CHR(09);
                   lc_line_document  :=lc_line_document||RPAD('Cust #',10,' ') ||CHR(09);
                   lc_line_document  :=lc_line_document||RPAD('Shipped',10,' ')||CHR(09);
                   lc_line_document  :=lc_line_document||RPAD('B/O',5,' ')     ||CHR(09);
                   lc_line_document  :=lc_line_document||RPAD('UM',5,' ')      ||CHR(09);
                   lc_line_document  :=lc_line_document||RPAD('Price',10,' ')  ||CHR(09);
                   lc_line_document  :=lc_line_document||RPAD('Ext',10,' ')    ||CHR(13)||CHR(10);
                   lc_line_document  :=lc_line_document||'------------------------------------------------------------------'||CHR(13)||CHR(10);
                  
                   
                   FOR lr_order_line_details IN lcu_order_line_details(ln_header_id)
                   LOOP
                      ln_line_number       :=lr_order_line_details.line_number;
                      lc_sku               :=lr_order_line_details.sku;
                      lc_customer_item     :=lr_order_line_details.customer_item;
                      lc_Item_Description  :=lr_order_line_details.Item_Description;
                      ln_ordered_qty       :=lr_order_line_details.ordered_qty;
                      ln_shipped_qty       :=lr_order_line_details.shipped_qty;
                      ln_backordered_qty   :=lr_order_line_details.backordered_qty;
                      lc_uom               :=lr_order_line_details.uom;
                      ln_unit_price        :=lr_order_line_details.unit_price;
                      ln_extended_price    :=lr_order_line_details.extended_price;

                      lc_line_document  :=lc_line_document||RPAD(lc_sku,10,' ')            ||CHR(09);
                      lc_line_document  :=lc_line_document||RPAD(lc_customer_item,10,' ')  ||CHR(09);
                      lc_line_document  :=lc_line_document||RPAD(ln_shipped_qty,10,' ')    ||CHR(09);
                      lc_line_document  :=lc_line_document||RPAD(ln_backordered_qty,5,' ') ||CHR(09);
                      lc_line_document  :=lc_line_document||RPAD(lc_uom,5,' ')             ||CHR(09);
                      lc_line_document  :=lc_line_document||RPAD(ln_unit_price,10,' ')     ||CHR(09);
                      lc_line_document  :=lc_line_document||RPAD(ln_extended_price,10,' ') ||CHR(13)||CHR(10);
                      
                   END LOOP;

                   lc_document2 :=               'Sub Total       : '||ln_sub_total   ||CHR(13)||CHR(10);
                   lc_document2 := lc_document2||'Tax             : '||ln_taxes       ||CHR(13)||CHR(10);
                   lc_document2 := lc_document2||'Delivery Charges: '||ln_charges     ||CHR(13)||CHR(10);
                   lc_document2 := lc_document2||'Misc            : '||ln_misc        ||CHR(13)||CHR(10);
                   lc_document2 := lc_document2||'-----------------------------------'||CHR(13)||CHR(10);
                   lc_document2 := lc_document2||'Total           : '||ln_total_amount||CHR(13)||CHR(10);
                   lc_document2 :=lc_document2||CHR(13)||CHR(10);                   
                   lc_document2 := lc_document2||'Payment Type    : '||lc_payment_type||CHR(13)||CHR(10);

                   lc_document3 :='******************************************'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'Legend'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'------'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'Ord: Original Quantity Ordered'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'To Be Shipped: Ordered Quantity - Backorder Quantity'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'B/O: Backorder Quantity'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'UM: Unit of Measure'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'CC: Cost Center'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'Price: Price per Individual Unit'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'Ext: Return Quantity x Price'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||CHR(13)||CHR(10);                   
                   lc_document3 :=lc_document3||'Thank you for ordering from Office Depot Business Services Division Online.'||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'Thank you for shopping at Office Depot Business Services Division Online.'  ||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'https://bsd.officedepot.com'             ||CHR(13)||CHR(10);
                   lc_document3 :=lc_document3||'Technical Support Number (800) 269-6888.'||CHR(13)||CHR(10);

                   p_document   := lc_document ||CHR(13)||CHR(10)||lc_document1||lc_line_document||CHR(13)||CHR(10)||lc_document2||lc_document3;

                END IF;

             END LOOP; -- Order Header Loop End

          EXCEPTION
          WHEN OTHERS THEN
             WF_CORE.CONTEXT
                 ('xx_wfl_globalnotify_pkg','generate_message',1,2, 'Unknown Error: '||SQLERRM);

             FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

             FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
             FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

             lc_errbuf   := FND_MESSAGE.GET;
             lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR3';

             -- -------------------------------------
             -- Call the Write_Exception procedure to
             -- insert into Global Exception Table
             -- -------------------------------------

             Write_Exception (
                               p_error_code        => lc_err_code
                              ,p_error_description => lc_errbuf
                              ,p_entity_reference  => 'Order Header Id'
                              ,p_entity_ref_id     => gn_header_id
                           );

      END generate_message;

    -- +===================================================================+
    -- | Name        : set_notification_attribute                          |
    -- | Description : Procedure is used to generate the message           |
    -- |               to send to the customer.                            |
    -- |                                                                   |
    -- | Parameters :  p_mode                                              |
    -- |               p_cause                                             |
    -- |               p_order_header_id                                   |
    -- |                                                                   |
    -- +===================================================================+

    PROCEDURE set_notification_attribute(
                                         itemtype  IN            VARCHAR2
                                        ,itemkey   IN            VARCHAR2
                                        ,actid     IN            PLS_INTEGER
                                        ,funcmode  IN            VARCHAR2
                                        ,resultout IN OUT NOCOPY VARCHAR2
                                        )
    IS

       ln_header_id         PLS_INTEGER;
       lc_cause             VARCHAR2(1000);
       lc_email_format      VARCHAR2(1000);
       lc_email_address     VARCHAR2(1000);
       lc_role_name         VARCHAR2(1000);
       lc_role_display_name VARCHAR2(1000);

       lc_errbuf            VARCHAR2(4000);
       lc_err_code          VARCHAR2(1000);

       CURSOR lcu_customer_id (p_header_id PLS_INTEGER)IS
       SELECT HP.party_id
             ,HCP.email_format
             ,HCP.email_address
       FROM   hz_cust_accounts     HCA
             ,oe_order_headers OHA
             ,hz_parties           HP
             ,hz_contact_points    HCP
       WHERE HCA.cust_account_id       = OHA.sold_to_org_id
       AND   HCA.party_id              = HP.party_id
       AND   HCP.owner_table_id        = HP.party_id
       AND   HCP.CONTACT_POINT_TYPE(+) = 'EMAIL'
       AND   HCP.PRIMARY_FLAG(+)       = 'Y'
       AND   HCP.OWNER_TABLE_NAME(+)   = 'HZ_PARTIES'
       AND   OHA.header_id             = p_header_id;

     BEGIN

       IF (funcmode = 'RUN') THEN
          ln_header_id := Wf_Engine.GetItemAttrNumber(
                                                      itemtype => itemtype
                                                     ,itemkey  => itemkey
                                                     ,aname    => 'XX_OM_HEADER_ID'
                                                     );

          lc_cause     := Wf_Engine.GetItemAttrText(
                                                    itemtype => itemtype
                                                   ,itemkey  => itemkey
                                                   ,aname    => 'XX_OM_CAUSE'
                                                   );

          FOR lr_customer_id IN lcu_customer_id(ln_header_id)
          LOOP

            lc_email_format := lr_customer_id.email_format;
            lc_email_address:= lr_customer_id.email_address;

          END LOOP;


          --
          -- Adding Customer as Role
          --
          Wf_directory.createAdhocRole(
                                       role_name               =>lc_role_name
                                      ,role_display_name       =>lc_role_display_name
                                      ,email_address           =>lc_email_address
                                      ,notification_preference =>lc_email_format
                                     );

          --
          --Assign performer to notification
          --
          Wf_Engine.SetItemAttrText(
                                    itemtype => itemtype
                                   ,itemkey  => itemkey
                                   ,aname    => 'XX_OM_PERFORMER'
                                   ,avalue   => lc_role_name
                                   );

          --
          -- Generate message body and assign to attribute
          --
             Wf_Engine.SetItemAttrText(
                                        itemtype => itemtype
                                       ,itemkey  => itemkey
                                       ,aname    => 'XX_OM_ORDER_DETAILS'
                                       ,avalue   => 'plsqlclob:xx_wfl_globalnotify_pkg.generate_message/'||
                                                    '@'||ln_header_id||
                                                    '#'||lc_cause||
                                                    '-'||lc_email_format
                                      );
          resultout := ' ';
          RETURN ;
       ELSIF (funcmode = 'CANCEL') THEN
          resultout := ' ';
          RETURN;
       ELSE
          resultout := ' ';
          RETURN;
       END IF;

       EXCEPTION
       WHEN OTHERS THEN
          WF_CORE.CONTEXT
             ('xx_wfl_globalnotify_pkg','set_notification_attribute',itemtype,itemkey, 'Unknown Error: '||SQLERRM);

          FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

          FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
          FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

          lc_errbuf   := FND_MESSAGE.GET;
          lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR4';

          -- -------------------------------------
          -- Call the Write_Exception procedure to
          -- insert into Global Exception Table
          -- -------------------------------------

          Write_Exception (
                            p_error_code        => lc_err_code
                           ,p_error_description => lc_errbuf
                           ,p_entity_reference  => 'Order Header Id'
                           ,p_entity_ref_id     => gn_header_id
                        );

   END set_notification_attribute;

   -- +===================================================================+
   -- | Name        : Invoke_wf_process                                   |
   -- | Description : Function is used to start workflow in prefer mode.  |
   -- |                                                                   |
   -- | Parameters :  p_mode                                              |
   -- |               p_cause                                             |
   -- |               p_order_header_id                                   |
   -- |                                                                   |
   -- +===================================================================+

   FUNCTION Invoke_wf_process(
                              p_subscription_guid IN RAW
                             ,p_event             IN OUT NOCOPY wf_event_t  
                              )
   RETURN VARCHAR2                              
   AS
       --
       -- Business Event Parameter
       --
       lc_mode              VARCHAR2(20);
       lc_cause             VARCHAR2(1000);
       ln_header_id         PLS_INTEGER;
       ln_count             PLS_INTEGER := 0;
       lc_item_key          VARCHAR(1000):= NULL;
       lc_itemkey_prefix    VARCHAR2(50):= 'XX_OM_GLOBALNOTIFY-'; 
       lt_parameter_list    wf_parameter_list_t;

       lc_errbuf          VARCHAR2(4000);
       lc_err_code        VARCHAR2(1000);

       CURSOR lcu_deferred_order(p_header_id PLS_INTEGER) IS
       SELECT COUNT(*) order_count
       FROM   xx_om_globalnotify XDOT
       WHERE  XDOT.order_header_id               = p_header_id
       AND    TO_DATE(creation_date,'DD/MM/RRRR')= TO_DATE(SYSDATE,'MM/DD/RRRR');

   BEGIN

      --
      -- Get parameter values from business parameter list
      --
      lc_mode       :=  p_event.getvalueforparameter(
                                                     'Mode'                                                     
                                                    );

      lc_cause      := p_event.getValueForParameter(
                                                    'Cause'
                                                   );

      ln_header_id  := p_event.getValueForParameter(
                                                    'Order_header_id'
                                                   );
      --
      --Assign order header_id to global variable
      --
      gn_header_id := ln_header_id;
      
      --
      --Deriving Item Key from sequence
      --
      BEGIN
         SELECT xx_om_globalnotify_itemkey_s.NEXTVAL
         INTO   lc_item_key
         FROM   dual;            
      END;  

      IF UPPER(lc_mode) = 'IMMEDIATE' THEN

         Wf_engine.Createprocess(
                                 itemtype =>'XXOMGNTF'
                                ,itemkey => lc_itemkey_prefix||lc_item_key
                                ,process => 'XX_OM_SEND_NOTIFICATION'
                                );

         Wf_engine.SetItemAttrNumber(
                                     itemtype => 'XXOMGNTF'
                                    ,itemkey  => lc_itemkey_prefix||lc_item_key
                                    ,aname    => 'XX_OM_HEADER_ID'
                                    ,avalue   => ln_header_id
                                    );

         Wf_engine.SetItemAttrText(
                                   itemtype => 'XXOMGNTF'
                                  ,itemkey  => lc_itemkey_prefix||lc_item_key
                                  ,aname    => 'XX_OM_CAUSE'
                                  ,avalue   => lc_cause
                                  );

         Wf_engine.Startprocess(
                                ItemType =>'XXOMGNTF',
                                ItemKey => lc_itemkey_prefix||lc_item_key
                               );

      ELSIF UPPER(lc_mode) = 'DEFERRED' THEN

         --
         --Checking if order is already exist for Current Date
         --
         FOR lr_deferred_order IN lcu_deferred_order(ln_header_id)
         LOOP

            ln_count:= lr_deferred_order.order_count;

         END LOOP;

         --
         -- Inserting into the temparory table
         --
         IF ln_count = 0 THEN
            --
            -- Inserting orders which are in deffered mode
            --
            BEGIN

               INSERT INTO xx_om_globalnotify
                                             (
                                              order_header_id
                                             ,creation_date
                                             ,cause
                                             )
                                     VALUES
                                            (
                                             ln_header_id
                                            ,SYSDATE
                                            ,lc_cause
                                            );
               COMMIT;

            EXCEPTION
               WHEN OTHERS THEN

                  ROLLBACK;

                  FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

                  FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                  FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                  lc_errbuf   := FND_MESSAGE.GET;
                  lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR5';

                  -- -------------------------------------
                  -- Call the Write_Exception procedure to
                  -- insert into Global Exception Table
                  -- -------------------------------------

                  Write_Exception (
                                    p_error_code        => lc_err_code
                                   ,p_error_description => lc_errbuf
                                   ,p_entity_reference  => 'Order Header Id'
                                   ,p_entity_ref_id     => gn_header_id
                     );
            END;
         ELSE

            --
            -- Updating the existing order with cause
            --
            BEGIN

               UPDATE xx_om_globalnotify
               SET    cause           = lc_cause
                     ,creation_date   = SYSDATE
               WHERE  order_header_id = ln_header_id;

               COMMIT;

            EXCEPTION
            WHEN OTHERS THEN

               ROLLBACK;

               FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

               FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
               FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

               lc_errbuf   := FND_MESSAGE.GET;
               lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR6';

               -- -------------------------------------
               -- Call the Write_Exception procedure to
               -- insert into Global Exception Table
               -- -------------------------------------

               Write_Exception (
                                 p_error_code        => lc_err_code
                                ,p_error_description => lc_errbuf
                                ,p_entity_reference  => 'Order Header Id'
                                ,p_entity_ref_id     => gn_header_id
                              );
            END;

         END IF;

      END IF;
      
      RETURN 'SUCCESS';   
      
   EXCEPTION
   WHEN OTHERS THEN

      ROLLBACK;
      
      RETURN 'Error';   
      
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_65100_UNEXPECTED_ERROR7';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                        p_error_code        => lc_err_code
                       ,p_error_description => lc_errbuf
                       ,p_entity_reference  => 'Order Header Id'
                       ,p_entity_ref_id     => gn_header_id
                     );

   END Invoke_wf_process;

END xx_wfl_globalnotify_pkg;
/
SHOW ERRORS;

EXIT;