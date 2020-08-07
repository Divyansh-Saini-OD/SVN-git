/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  ADP Taxware                                       A#
 *#W  Address: 401 Edgewater Place, Suite 260                    X#
 *#A           Wakefield, MA 01880-6210                          W#
 *#R           www.taxware.com                                   A#
 *#E  Contact: Tel Main # 781-557-2600                           R#
 *#T                                                             E#
 *#A  THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED  T#
 *#X  WITHOUT WRITTEN PERMISSION FROM govONE Solutions, LP       A#
 *#W                                                             X#
 *#A       Copyright © 2007 ADP Taxware                          W#
 *#R   THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL          A#
 *#E                     ALL RIGHTS RESERVED                     R#
 *#T                                                             E#
 *#AXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE##
 *#################################################################
 *#     $Header: $Twev5ARParmbv2.0            March 30, 2007
 *#     Modification History 
 *#     5/30/2007    Govind      Added utility procedures for Office Depot 
 *#                              customization. Search for "Office Depot"  
 *###############################################################
 *	 Source	File		  :- taxpkg_10_paramb.sql
 *	 ---> Office Depot <---
 *###############################################################
 */

create or replace
PACKAGE BODY TAXPKG_10_PARAM /* $Header: $Twev5ARParmbv2.0 */
 AS

 /* Govind: 6/13/2007: TWE Engine DB has attribute value length of 20 characters,
     so we need to truncate input Oracle attribute value to 20 before passing the 
	 string to TWE. See get_AR_customatts and get_OM_customatts functions for code */
 g_TWE_CUSTOM_ATTR_LEN number(15) := 20;
 
  /* ********************************************************/
  /* Retrieve  all necessary elements from here.  It is more */
  /* convenient than to update the standard views.     */
  /* ********************************************************/
  /* GET ALL THE OTHERS HERE BASED ON  THE Customer_trx_id
  CostCenter  -- DFF Invoice Line Information.ATTRIBUTE11
  G/L Account -- DFF Invoice Line Information.ATTRIBUTE12
  Location    -- DFF Invoice Line Information.ATTRIBUTE13
  EntityUse   -- DFF Invoice Line Information.ATTRIBUTE14
  Job Number  -- DFF Invoice Line Information.ATTRIBUTE15
  ********************************************************/

  FUNCTION get_CostCenter(p_Cust_id         IN NUMBER,
                          p_Site_use_id     IN Number,
                          p_Cus_trx_id      IN Number,
                          p_Cus_trx_line_id IN NUMBER,
                          p_Trx_type_id     IN NUMBER) RETURN VARCHAR2 is
  
    l_cost_center VARCHAR2(30);
  BEGIN
    RETURN NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_CostCenter:NO_DATA_FOUND');
      return null;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_CostCenter:' || SQLERRM);
  END get_CostCenter;

  FUNCTION get_Organization(p_Org_id          IN NUMBER,
                            p_Site_use_id     IN Number,
                            p_Cus_trx_id      IN Number,
                            p_Cus_trx_line_id IN NUMBER,
                            p_item_id         IN NUMBER,
                            p_Trx_type_id     IN NUMBER,
                            p_other           IN VARCHAR2) RETURN VARCHAR2 is
  
    l_Organization VARCHAR2(30);
    l_ccid         NUMBER;
  
  BEGIN
    PrintOut('TWE:AR:>org1:' || p_org_id || ':');
  
    IF p_other = 'OE_TAX_LINES_SUMMARY' THEN
      --(
      PrintOut('TWE:AR:>org:OM');
      SELECT hh.attribute15
        INTO l_Organization
        FROM apps.hr_organization_units_v hh
       WHERE hh.organization_id = p_org_id;
    
    ELSE
      --)(
      BEGIN
        --{
        --Logic
        --first look to the Receivables account to get the LE segment
        --value to derive org, then if it does not find it, use
        --the first Revenue account
        SELECT DISTINCT code_combination_id
          INTO l_ccid
          FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
         WHERE account_class = 'REC'
           AND customer_trx_id = p_Cus_trx_id
           AND ROWNUM = 1;
        PrintOut('TWE:AR:> REC ccid=:' || l_ccid || ':');
      
        IF l_ccid IS NULL THEN
          --(
          PrintOut('TWE:AR:> REC not found, get REV Account');
          SELECT DISTINCT code_combination_id
            INTO l_ccid
            FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
           WHERE account_class = 'REV'
             AND customer_trx_id = p_Cus_trx_id
             AND ROWNUM = 1;
          PrintOut('TWE:AR:> REV ccid=:' || l_ccid || ':');
        END IF; --)
      
      EXCEPTION
        WHEN OTHERS THEN
          PrintOut('TWE:AR:>org1.3a:AR GET ORG ERROR');
          PrintOut('TWE:AR:> REC not found, get REV Account');
          SELECT DISTINCT code_combination_id
            INTO l_ccid
            FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
           WHERE account_class = 'REV'
             AND customer_trx_id = p_Cus_trx_id
             AND ROWNUM = 1;
          PrintOut('TWE:AR:> REV ccid=:' || l_ccid || ':');
        
      END; --}
      PrintOut('TWE:AR:>org1.5:l_ccid:' || l_ccid || ':');
      PrintOut('TWE:AR:>org1.6:CharofAcc:' ||
               APPS.ARP_TAX.SYSINFO.CHART_OF_ACCOUNTS_ID || ':');
      IF NOT APPS.FND_FLEX_KEYVAL.Validate_CCID('SQLGL',
                                                'GL#',
                                                APPS.ARP_TAX.SYSINFO.CHART_OF_ACCOUNTS_ID,
                                                l_ccid) THEN
        PrintOut('TWE:AR:>org2: RETURN Organization Code NULL <--');
        RAISE NO_DATA_FOUND;
      END IF;
    
      l_Organization := APPS.FND_FLEX_KEYVAL.Segment_Value(1);
    
    END IF; --)
  
    PrintOut('TWE:AR:>org_out:' || l_Organization || ':');
    RETURN l_Organization;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_Organization:NO_DATA_FOUND');
      RETURN NULL;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_Organization:' || SQLERRM);
      RETURN NULL;
  END get_Organization;

  FUNCTION get_JobNumber(p_Cust_id         IN NUMBER,
                         p_Site_use_id     IN NUMBER,
                         p_Cus_trx_id      IN NUMBER,
                         p_Cus_trx_line_id IN NUMBER,
                         p_Trx_type_id     IN NUMBER) RETURN VARCHAR2 IS
    l_JobNumber VARCHAR2(30);
  BEGIN
    RETURN NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_JobNumber:NO_DATA_FOUND');
      return null;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_JobNumber:' || SQLERRM);
  END get_JobNumber;

  FUNCTION get_EntityUse(p_Cust_id         IN NUMBER,
                         p_Site_use_id     IN Number,
                         p_Cus_trx_id      IN Number,
                         p_Cus_trx_line_id IN NUMBER,
                         p_Trx_type_id     IN NUMBER,
                         p_other           IN VARCHAR2) RETURN VARCHAR2 is
    l_EntityUse VARCHAR2(30);
  BEGIN
    RETURN NULL;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_EntityUse:NO_DATA_FOUND');
      RETURN null;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_EntityUse:' || SQLERRM);
  END get_EntityUse;

  FUNCTION get_ProdCode(p_item_id         IN NUMBER,
                        p_Cus_trx_id      IN NUMBER,
                        p_Cus_trx_line_id IN NUMBER,
                        p_Trx_type_id     IN NUMBER,
                        p_org_id          IN NUMBER,
                        p_other           IN VARCHAR2) RETURN VARCHAR2 is
    l_ProdCode VARCHAR2(150);
  
    /* Office Depot Custom: 2/10/2007: OD_TWE_AR_Design_V21.doc:
       Use item level dff attribute1 for product code */
    cursor csr_item_attr IS
      select msi.attribute1 as product_code /* product code */
        from apps.mtl_system_items msi
       where msi.inventory_item_id = p_item_id
         and msi.organization_id = p_org_id;
  
  BEGIN
  
    PrintOut('TWE:AR:-get_ProdCode:p_item_id:=' || p_item_id || ':');
    PrintOut('TWE:AR:-get_ProdCode:p_org_id:=' || p_org_id || ':');
    PrintOut('TWE:AR:-get_ProdCode:p_line_id:=' || p_Cus_trx_line_id || ':');
  
    for crec in csr_item_attr loop
      l_ProdCode := crec.product_code;
    end loop;
  
    /* 
      SELECT ltrim(rtrim(attribute15))
        INTO l_ProdCode
        FROM APPS.ra_customer_trx_lines
       WHERE customer_trx_line_id = p_Cus_trx_line_id;
    */
    PrintOut('TWE:AR:-get_ProdCode:' || l_ProdCode || ':');
  
    RETURN l_ProdCode;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_ProdCode:NO_DATA_FOUND');
      RETURN null;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_ProdCode:' || SQLERRM);
  END get_ProdCode;


  PROCEDURE get_ShipFrom(p_Cust_id         IN NUMBER,
                         p_Site_use_id     IN Number,
                         p_Cus_trx_id      IN Number,
                         p_Cus_trx_line_id IN NUMBER,
                         p_location_id     IN NUMBER, --warehouse_id
                         p_org_id          IN NUMBER, --org_id
                         p_other           IN VARCHAR2, --view_name
                         o_Country         OUT NOCOPY VARCHAR2,
                         o_City            OUT NOCOPY VARCHAR2,
                         o_Cnty            OUT NOCOPY VARCHAR2,
                         o_State           OUT NOCOPY VARCHAR2,
                         o_Zip             OUT NOCOPY VARCHAR2,
                         o_Code            OUT NOCOPY VARCHAR2) IS
    /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
       For Ship From: Use the interface_line_attribute10 at the invoice line level 
       to find the location value otherwise use the warehouse field from the AR 
       transaction line. */
    cursor csr_get_trxline_attr IS
      select lines.interface_line_attribute10
        from apps.ra_customer_trx_lines lines
       where lines.customer_trx_line_id = p_Cus_trx_line_id;
    l_location_id varchar2(150) := null;
  
  BEGIN
  
    PrintOut(':get_ShipFrom:p_org_id      :' || p_org_id || ':');
    PrintOut(':get_ShipFrom:p_warehouse_id:' || p_location_id || ':');
  
    /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
       For Ship From: Use the interface_line_attribute10 at the invoice line level 
       to find the location value otherwise use the warehouse field from the AR 
       transaction line. */  
    for crec in csr_get_trxline_attr loop
      l_location_id := crec.interface_line_attribute10;
    end loop;
	/* End : Office Depot custom */
  
    IF p_other = 'OE_TAX_LINES_SUMMARY' THEN
      --(
    
      PrintOut(':get_ShipFrom:OM CALL:');
      SELECT hl.location_code,
             substr(hl.postal_code, 1, 5),
             hl.town_or_city,
             DECODE(hl.country, 'CA', NULL, hl.region_1), --County
             DECODE(hl.country, 'CA', hl.region_1, hl.region_2), --State
             DECODE(hl.country, 'CA', 'CANADA', 'US', 'UNITED STATES') --Country
        INTO o_code, o_Zip, o_City, o_Cnty, o_State, o_Country
        FROM apps.hr_organization_units_v hh, apps.hr_locations_all hl
       WHERE hh.location_id = hl.location_id
         AND hh.organization_id = nvl(l_location_id, p_location_id);
    
    ELSE
      --)(
    
      IF (p_location_id IS NULL) THEN
        --(
      
        PrintOut(':get_ShipFrom:Loc is NULL:');
        SELECT hl.location_code,
               substr(hl.postal_code, 1, 5),
               hl.town_or_city,
               DECODE(hl.country, 'CA', NULL, hl.region_1), --County
               DECODE(hl.country, 'CA', hl.region_1, hl.region_2), --State
               DECODE(hl.country, 'CA', 'CANADA', 'US', 'UNITED STATES') --Country
          INTO o_code, o_Zip, o_City, o_Cnty, o_State, o_Country
          FROM --apps.hr_organization_information_v    hro,
               apps.hr_organization_units_v hh,
               apps.hr_locations_all        hl
         WHERE
        --hro.org_information_context  = 'Accounting Information'
        --AND hh.organization_id      = hro.organization_id
         hh.location_id = hl.location_id
         AND hh.organization_id = p_org_id;
      ELSE
        --)(
        PrintOut(':get_ShipFrom:Loc is NOT NULL:');
        SELECT hl.location_code,
               substr(hl.postal_code, 1, 5),
               hl.town_or_city,
               DECODE(hl.country, 'CA', NULL, hl.region_1), --County
               DECODE(hl.country, 'CA', hl.region_1, hl.region_2), --State
               DECODE(hl.country, 'CA', 'CANADA', 'US', 'UNITED STATES') --Country
          INTO o_code, o_Zip, o_City, o_Cnty, o_State, o_Country
          FROM apps.hr_organization_units_v hh, apps.hr_locations_all hl
         WHERE hh.location_id = hl.location_id
           AND hh.organization_id = nvl(l_location_id, p_location_id);
      
        PrintOut(':get_ShipFrom:GOT Loc:');
      END IF; --)
    
    END IF; --) p_other
    APPS.ARP_TAX.tax_info_rec.Ship_from_code := o_Zip;
  
    PrintOut(':get_ShipFrom:END');
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut(':(E)-get_ShipFrom:NO_DATA_FOUND');
      APPS.ARP_TAX.tax_info_rec.Ship_from_code := 'XXXXXXXXXX';
      -- Returning XXXXXXXX  will cause it to default to ship to
    WHEN OTHERS THEN
      PrintOut(':(E)-get_ShipFrom:' || SQLERRM);
      APPS.ARP_TAX.tax_info_rec.Ship_from_code := 'XXXXXXXXXX';
  END get_ShipFrom;

  PROCEDURE get_ShipTo(p_Cust_id         IN NUMBER,
                       p_Site_use_id     IN Number,
                       p_Cus_trx_id      IN Number,
                       p_Cus_trx_line_id IN NUMBER,
                       p_location_id     IN NUMBER,
                       p_org_id          IN NUMBER,
                       o_Country         OUT NOCOPY VARCHAR2,
                       o_City            OUT NOCOPY VARCHAR2,
                       o_Cnty            OUT NOCOPY VARCHAR2,
                       o_State           OUT NOCOPY VARCHAR2,
                       o_Zip             OUT NOCOPY VARCHAR2,
                       o_Code            OUT NOCOPY VARCHAR2) IS
  
    CURSOR getAddressData(c_site_use_id NUMBER) IS
      SELECT DECODE(ardv.state,
                    'CN',
                    'CANADA',
                    upper(ardv.territory_short_name)), --Country
             ardv.city, --City
             DECODE(ardv.state, 'CN', NULL, ardv.county), --County
             NVL(ardv.province,
                 decode(ardv.state, 'CN', ardv.county, ardv.state)), --State
             SUBSTR(ardv.postal_code, 1, 5) -- Zip
        FROM APPS.AR_ADDRESSES_V ardv, APPS.RA_SITE_USES rasu
       WHERE ardv.address_id = rasu.address_id
         AND rasu.site_use_id = c_site_use_id;
  
  BEGIN
  
    PrintOut('TWE:AR:get_ShipTo:p_org_id:' || p_org_id || ':');
    --
    OPEN getAddressData(p_Site_use_id);
    FETCH getAddressData
      INTO o_Country, o_City, o_Cnty, o_State, o_Zip;
    o_Code := APPS.ARP_TAX.tax_info_rec.Ship_to_site_use_id;
  
    IF getAddressData%NOTFOUND THEN
      PrintOut('TWE:AR:(E) ShipTo	Error:NOTFOUND');
      Raise NO_DATA_FOUND;
    END IF;
    CLOSE getAddressData;
    --
    APPS.ARP_TAX.tax_info_rec.Ship_to_code := o_zip;
    PrintOut('TWE:AR:get_get_ShipTo:END');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_ShipTo:NO_DATA_FOUND');
      APPS.ARP_TAX.tax_info_rec.Ship_to_code := '!ERROR!';
    
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_ShipTo:' || SQLERRM);
      APPS.ARP_TAX.tax_info_rec.Ship_to_code := '!ERROR!';
    
  END get_ShipTo;

  PROCEDURE get_BillTo(p_Cust_id         IN NUMBER,
                       p_Site_use_id     IN Number,
                       p_Cus_trx_id      IN Number,
                       p_Cus_trx_line_id IN NUMBER,
                       p_location_id     IN NUMBER,
                       p_org_id          IN NUMBER,
                       o_Country         OUT NOCOPY VARCHAR2,
                       o_City            OUT NOCOPY VARCHAR2,
                       o_Cnty            OUT NOCOPY VARCHAR2,
                       o_State           OUT NOCOPY VARCHAR2,
                       o_Zip             OUT NOCOPY VARCHAR2,
                       o_Code            OUT NOCOPY VARCHAR2) IS
  
    CURSOR getAddressData(c_site_use_id NUMBER) IS
      SELECT DECODE(ardv.state,
                    'CN',
                    'CANADA',
                    upper(ardv.territory_short_name)), --Country
             ardv.city, --City
             DECODE(ardv.state, 'CN', NULL, ardv.county), --County
             NVL(ardv.province,
                 decode(ardv.state, 'CN', ardv.county, ardv.state)), --State
             SUBSTR(ardv.postal_code, 1, 5) -- Zip
        FROM APPS.AR_ADDRESSES_V ardv, APPS.RA_SITE_USES rasu
       WHERE ardv.address_id = rasu.address_id
         AND rasu.site_use_id = c_site_use_id;
  
  BEGIN
  
    PrintOut('TWE:AR:get_BillTo:p_org_id:' || p_org_id || ':');
    APPS.ARP_TAX.tax_info_rec.bill_to_postal_code := '';
    PrintOut('TWE:AR:-Going for BillTo	Info');
    OPEN getAddressData(APPS.ARP_TAX.tax_info_rec.Bill_to_site_use_id);
    FETCH getAddressData
      INTO o_Country, o_City, o_Cnty, o_State, o_Zip;
  
    IF getAddressData%NOTFOUND THEN
      PrintOut('TWE:AR:(E) BillTo	Error:NOTFOUND');
      Raise NO_DATA_FOUND;
    END IF;
    o_Code := APPS.ARP_TAX.tax_info_rec.Bill_to_site_use_id;
    CLOSE getAddressData;
  
    APPS.ARP_TAX.tax_info_rec.bill_to_postal_code := o_zip;
    PrintOut('TWE:AR:get_BillTo:END');
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_BillTo:NO_DATA_FOUND');
      APPS.ARP_TAX.tax_info_rec.bill_to_postal_code := 'XXXXX';
      -- Returning XXXXXXXX  will cause it to default to ship to
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_BillTo:' || SQLERRM);
      APPS.ARP_TAX.tax_info_rec.bill_to_postal_code := 'XXXXX';
    
  END get_BillTo;

  PROCEDURE get_POO(p_Cust_id         IN NUMBER,
                    p_Site_use_id     IN Number,
                    p_Cus_trx_id      IN Number,
                    p_Cus_trx_line_id IN NUMBER,
                    p_location_id     IN NUMBER,
                    p_org_id          IN NUMBER,
                    o_Country         OUT NOCOPY VARCHAR2,
                    o_City            OUT NOCOPY VARCHAR2,
                    o_Cnty            OUT NOCOPY VARCHAR2,
                    o_State           OUT NOCOPY VARCHAR2,
                    o_Zip             OUT NOCOPY VARCHAR2,
                    o_Code            OUT NOCOPY VARCHAR2) IS
  
  BEGIN
  
    PrintOut('TWE:AR:get_POO:p_org_id:' || p_org_id || ':');
    APPS.ARP_TAX.tax_info_rec.poo_code := 'XXXXXXXXXX';
    PrintOut('TWE:AR:get_POO:END');
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_POO:NO_DATA_FOUND');
      APPS.ARP_TAX.tax_info_rec.poo_code := 'XXXXXXXXXX';
      -- Returning XXXXXXXX  will cause it to default to ship to
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_POO:' || SQLERRM);
      APPS.ARP_TAX.tax_info_rec.poo_code := 'XXXXXXXXXX';
    
  END get_POO;

  PROCEDURE get_POA(p_Cust_id         IN NUMBER,
                    p_Site_use_id     IN Number,
                    p_Cus_trx_id      IN Number,
                    p_Cus_trx_line_id IN NUMBER,
                    p_location_id     IN NUMBER,
                    p_org_id          IN NUMBER,
                    o_Country         OUT NOCOPY VARCHAR2,
                    o_City            OUT NOCOPY VARCHAR2,
                    o_Cnty            OUT NOCOPY VARCHAR2,
                    o_State           OUT NOCOPY VARCHAR2,
                    o_Zip             OUT NOCOPY VARCHAR2,
                    o_Code            OUT NOCOPY VARCHAR2) IS
  
  BEGIN
  
    PrintOut('TWE:AR:get_POA:p_line_id:' || p_Cus_trx_line_id || ':');
  
    SELECT rals.salesrep_id,
           SUBSTR(pera.postal_code, 1, 5),
           pera.town_or_city,
           DECODE(pera.country, 'CA', NULL, pera.region_1), --County
           DECODE(pera.country, 'CA', pera.region_1, pera.region_2), --State
           DECODE(pera.country, 'CA', 'CANADA', 'US', 'UNITED STATES') --Country
      INTO o_code, o_zip, o_city, o_cnty, o_state, o_country
      FROM APPS.ra_cust_trx_line_salesreps_v rals,
           APPS.per_addresses_v              pera,
           APPS.ra_salesreps                 rasr
     WHERE customer_trx_line_id = p_Cus_trx_line_id
       AND rals.salesrep_id = rasr.salesrep_id
       AND rasr.person_id = pera.person_id;
  
    PrintOut('TWE:AR:get_POA:END');
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_POA:NO_DATA_FOUND');
      APPS.ARP_TAX.tax_info_rec.poa_code := 'XXXXXXXXXX';
      -- Returning XXXXXXXX  will cause it to default to ship to
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_POA:' || SQLERRM);
      APPS.ARP_TAX.tax_info_rec.poa_code := 'XXXXXXXXXX';
    
  END get_POA;

  /* 5/11/07: Govind: Office Depot Custom: Requirements Doc: OD_TWE_AR_Design_v21.doc.
     This  get_CustomAtts function should return a value of the form */
     ---> name1:value1:name2:value2:name3:value3  <--- */ 

  FUNCTION get_AR_CustomAtts(p_Cust_id      IN NUMBER,
                          p_Site_use_id     IN NUMBER,
                          p_Cus_trx_id      IN NUMBER,
                          p_Cus_trx_line_id IN NUMBER,
                          p_Trx_type_id     IN NUMBER,
                          p_org_id          IN NUMBER) RETURN VARCHAR2 IS
  
    CURSOR c_ar_invoice_source IS
      select bs.name
        from apps.ra_customer_trx trx, apps.ra_batch_sources bs
       where bs.batch_source_id = trx.batch_source_id
         and trx.customer_trx_id = p_Cus_trx_id;
  
    CURSOR c_ar_trx_type IS
      select trxtypes.name
        from apps.ra_cust_trx_types trxtypes
       where trxtypes.cust_trx_type_id = p_Trx_type_id;
  
    /* Inventory Org */
    CURSOR c_org_type IS
      select hrorg.organization_type
        from APPS.hr_organization_units_v hrorg
       where hrorg.organization_id = to_number(APPS.arp_tax.tax_info_rec.Ship_From_Warehouse_id);
  
    l_ar_invoice_source varchar2(240);
    l_ar_trx_type       varchar2(240);
    l_org_type          varchar2(240);
    l_custom_attr_str   varchar2(2000) := null;
    l_GLAcct            VARCHAR2(240);
    l_Location          VARCHAR2(240);
  BEGIN
  
    PrintOut('TWE:AR: get_AR_CustomAtts + ');   
    /* 5/11/07: Govind: Office Depot Custom: Requirements Doc: OD_TWE_AR_Design_v21.doc.
    Description: Get AR Invoice Source for custom attribute OD Txn Source */
    FOR arbsrec in c_ar_invoice_source LOOP
      l_ar_invoice_source := arbsrec.name;
    END LOOP;
    
    if (l_ar_invoice_source is not null) then
      l_custom_attr_str := 'OD Txn Source:' || substr(replace(l_ar_invoice_source, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
    end if;
  
    /* Get AR Trx Type for custom attr OD Txn Type */
    FOR artyperec in c_ar_trx_type LOOP
      l_ar_trx_type := artyperec.name;
    END LOOP;
    if (l_ar_trx_type is not null) then
	  if (l_custom_attr_str is not null)
	  then
	  	  l_custom_attr_str := l_custom_attr_str || ':';
	  end if;
      l_custom_attr_str := l_custom_attr_str || 'OD Txn Type:' ||
                           substr(replace(l_ar_trx_type, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
    end if;
  
    /* Get HR Org Type for custom attr OD org Type */
    FOR orgrec in c_org_type LOOP
      l_org_type := orgrec.organization_type;
    END LOOP;
    if (l_org_type is not null) then
	  if (l_custom_attr_str is not null)
	  then
	  	  l_custom_attr_str := l_custom_attr_str || ':';
	  end if;	
      l_custom_attr_str := l_custom_attr_str || 'OD org type:' ||
                           substr(replace(l_org_type, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
    end if;
  
    l_GLAcct := get_GLAcct(NULL, --p_Cust_id
                            NULL, --p_Site_use_id,
                            p_Cus_trx_id, --p_Cus_trx_id
                            NULL,
                            NULL /*p_Trx_type_id*/);
							
    if (l_GLAcct is not null) then
	  if (l_custom_attr_str is not null)
	  then
	  	  l_custom_attr_str := l_custom_attr_str || ':';
	  end if;	
      l_custom_attr_str := l_custom_attr_str || 'OD GL account:' ||
                           substr(replace(l_GLAcct, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
    end if;  
  
    l_Location := get_Location(NULL, --p_Cust_id
                            NULL, --p_Site_use_id,
                            p_Cus_trx_id, --p_Cus_trx_id
                            NULL,
                            NULL /*p_Trx_type_id*/);
    if (l_Location is not null) then
	  if (l_custom_attr_str is not null)
	  then
	  	  l_custom_attr_str := l_custom_attr_str || ':';
	  end if;	
      l_custom_attr_str := l_custom_attr_str || 'OD location code:' ||
                           substr(replace(l_Location, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
    end if;    
  
    PrintOut('TWE:AR: get_AR_CustomAtts - ');  
    return l_custom_attr_str;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_AR_CustomAtts:NO_DATA_FOUND');
      return null;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_AR_CustomAtts:' || SQLERRM);
  END get_AR_CustomAtts;

  /* 5/11/07: Govind: Office Depot Custom: Requirements Doc: OD_TWE_AR_Design_v21.doc.
     This  get_CustomAtts function should return a value of the form */
     ---> name1:value1:name2:value2:name3:value3  <--- */ 
  FUNCTION get_OM_CustomAtts(p_Cust_id      IN NUMBER,
                          p_Site_use_id     IN NUMBER,
                          p_Cus_trx_id      IN NUMBER,
                          p_Cus_trx_line_id IN NUMBER,
                          p_Trx_type_id     IN NUMBER,
                          p_org_id          IN NUMBER) RETURN VARCHAR2 IS
  
    /* Get Order Type */
    CURSOR csr_om_order_type IS
      select ordtype.name 
      from  apps.oe_order_headers hdr, 
            apps.oe_order_lines line,  
            apps.oe_order_types_v ordtype
      where line.header_id = hdr.header_id
      and   hdr.order_type_id = ordtype.order_type_id
      and   line.line_id = p_Cus_trx_line_id;
  
    /* Get Order Source */
    CURSOR csr_om_order_src IS
      select ordsrc.name 
      from  apps.oe_order_headers hdr, 
            apps.oe_order_lines line,  
            apps.oe_order_sources ordsrc
      where line.header_id = hdr.header_id
      and   hdr.order_source_id = ordsrc.order_source_id
      and   line.line_id = p_Cus_trx_line_id;

    /* Inventory Org */
    CURSOR csr_ship_from_loc IS
      select hrorg.location_code
        from APPS.hr_organization_units_v hrorg
       where hrorg.organization_id = to_number(APPS.arp_tax.tax_info_rec.Ship_From_Warehouse_id);

    l_order_type    varchar2(240);
    l_order_source  varchar2(240);
    l_ship_from_loc varchar2(300);  -- name is 240, location_code is 60
    l_custom_attr_str   varchar2(2000) := null;
  BEGIN
  
    PrintOut('TWE:AR: get_OM_CustomAtts + ');   
    /* 5/11/07: Govind: Office Depot Custom: Requirements Doc: OD_TWE_AR_Design_v21.doc.
    Description: Get OM Order Source for custom attribute OD Txn Source */
    FOR ordsrcrec in csr_om_order_src 
    LOOP
      l_order_source := ordsrcrec.name;
    END LOOP;
    
    if (l_order_source is not null) then
      l_custom_attr_str := 'OD Txn Source:' || substr(replace(l_order_source, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
    end if;

    /* Get OM Order Type for custom attr OD Txn Type */
    FOR ordtyperec in csr_om_order_type 
    LOOP
      l_order_type := ordtyperec.name;
    END LOOP;
    if (l_order_type is not null) then
	  if (l_custom_attr_str is not null)
	  then
	  	  l_custom_attr_str := l_custom_attr_str || ':';
	  end if;
      l_custom_attr_str := l_custom_attr_str || 'OD Txn Type:' ||
                           substr(replace(l_order_type, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
    end if;
  
    /* Get HR Org Type for custom attr OD org Type */
    FOR locrec in csr_ship_from_loc LOOP
      l_ship_from_loc := locrec.location_code;
    END LOOP;
    if (l_ship_from_loc is not null) then
	  if (l_custom_attr_str is not null)
	  then
	  	  l_custom_attr_str := l_custom_attr_str || ':';
	  end if;	
      l_custom_attr_str := l_custom_attr_str || 'OD location code:' ||
                           substr(replace(l_ship_from_loc, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
    end if;
  
    PrintOut('TWE:AR: get_OM_CustomAtts - ');  
    return l_custom_attr_str;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_OM_CustomAtts:NO_DATA_FOUND');
      return null;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_OM_CustomAtts:' || SQLERRM);
  END get_OM_CustomAtts;


  FUNCTION get_CustomAtts(p_Cust_id         IN NUMBER,
                          p_Site_use_id     IN NUMBER,
                          p_Cus_trx_id      IN NUMBER,
                          p_Cus_trx_line_id IN NUMBER,
                          p_Trx_type_id     IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
  
    return NULL;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_CustomAtts:NO_DATA_FOUND');
      return null;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_CustomAtts:' || SQLERRM);
  END get_CustomAtts;

  PROCEDURE PrintOut(Message IN VARCHAR2) IS
  
  BEGIN
  
    IF GlobalPrintOption = 'Y' THEN
      --(
      APPS.ARP_UTIL_TAX.DEBUG('TWE_AR:(pv2.0):' || MESSAGE || ':');
    END IF; --)
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END PrintOut;

  /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
     Use Geocode before using ship-to address.
     We get the value of geocode here and pass back to TAXFN_TAX010 which passes
     the geocode and ship-to/bill-to addresses as separate parameters to the 
     TWE java engine */ 
  FUNCTION get_GeoCode(p_site_use_id IN NUMBER) RETURN VARCHAR2 IS
    l_GeoCode varchar2(150);
  
    CURSOR csr_GeoCode IS
      SELECT ardv.attribute14 as geocode
        FROM APPS.AR_ADDRESSES_V ardv, APPS.RA_SITE_USES rasu
       WHERE ardv.address_id = rasu.address_id
         AND rasu.site_use_id = p_site_use_id;
  
  BEGIN
    PrintOut('TWE:AR:-get_GeoCode:p_site_use_id:=' || p_site_use_id || ':');
  
    for crec in csr_GeoCode loop
      l_GeoCode := crec.geocode;
    end loop;
  
    PrintOut('TWE:AR:-get_GeoCode:' || l_GeoCode || ':');
    RETURN l_GeoCode;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PrintOut('TWE:AR:(E)-get_GeoCode:NO_DATA_FOUND');
      RETURN null;
    WHEN OTHERS THEN
      PrintOut('TWE:AR:(E)-get_GeoCode:' || SQLERRM);
  END get_GeoCode;

  /* Office Depot:  Custom Attributes */
  FUNCTION get_GLAcct(p_Cust_id         IN NUMBER,
                      p_Site_use_id     IN Number,
                      p_Cus_trx_id      IN Number,
                      p_Cus_trx_line_id IN NUMBER,
                      p_Trx_type_id     IN NUMBER) RETURN VARCHAR2 is
    l_GLAcct VARCHAR2(30);
    l_ccid         NUMBER;
  BEGIN
    BEGIN
      --{
      --Logic
      --first look to the Receivables account to get the LE segment
      --value to derive GL Account, then if it does not find it, use
      --the first Revenue account
      SELECT DISTINCT code_combination_id
        INTO l_ccid
        FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
       WHERE account_class = 'REC'
         AND customer_trx_id = p_Cus_trx_id
         AND ROWNUM = 1;
      PrintOut('TWE:AR:> REC ccid=:' || l_ccid || ':');
      
      IF l_ccid IS NULL THEN
      --(
        BEGIN 
          PrintOut('TWE:AR:> REC not found, get REV Account');
          SELECT DISTINCT code_combination_id
            INTO l_ccid
            FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
           WHERE account_class = 'REV'
             AND customer_trx_id = p_Cus_trx_id
             AND ROWNUM = 1;
          PrintOut('TWE:AR:> REV ccid=:' || l_ccid || ':');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
--            PrintOut('TWE:AR:(E)-get_GLAcct:NO_DATA_FOUND');
            PrintOut('TWE:AR:>1:RETURN GL Account NULL <--');
            RETURN NULL;
          WHEN OTHERS THEN
            PrintOut('TWE:AR:(E)-1:get_GLAcct:' || SQLERRM);
            RETURN NULL;
        END;
      END IF; --)

    EXCEPTION
      WHEN OTHERS THEN
        PrintOut('TWE:AR:> AR GET GL ERROR');
        PrintOut('TWE:AR:> REC not found, get REV Account');
        BEGIN 
          SELECT DISTINCT code_combination_id
            INTO l_ccid
            FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
           WHERE account_class = 'REV'
             AND customer_trx_id = p_Cus_trx_id
             AND ROWNUM = 1;
          PrintOut('TWE:AR:> REV ccid=:' || l_ccid || ':');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
 --           PrintOut('TWE:AR:(E)-get_GLAcct:NO_DATA_FOUND');
            PrintOut('TWE:AR:>2:RETURN GL Account NULL <--');
            RETURN NULL;
          WHEN OTHERS THEN
            PrintOut('TWE:AR:(E)-2:get_GLAcct:' || SQLERRM);
            RETURN NULL;
        END;
    END;

    PrintOut('TWE:AR:>l_ccid:' || l_ccid || ':');
    PrintOut('TWE:AR:>:CharofAcc:' || APPS.ARP_TAX.SYSINFO.CHART_OF_ACCOUNTS_ID || ':');
    IF NOT APPS.FND_FLEX_KEYVAL.Validate_CCID('SQLGL',
                                              'GL#',
                                              APPS.ARP_TAX.SYSINFO.CHART_OF_ACCOUNTS_ID,
                                              l_ccid) THEN
      PrintOut('TWE:AR:>3:RETURN GL Account NULL <--');
      RETURN NULL;
    END IF;
    
    l_GLAcct := APPS.FND_FLEX_KEYVAL.Segment_Value(3);

    RETURN l_GLAcct;
  END get_GLAcct;    

 /* Office Depot: Custom Attributes */
  FUNCTION get_Location(p_Cust_id         IN NUMBER,
               p_Site_use_id     IN Number,
               p_Cus_trx_id      IN Number,
               p_Cus_trx_line_id IN NUMBER,
               p_Trx_type_id     IN NUMBER) RETURN VARCHAR2 is
    l_Location VARCHAR2(30);
    l_ccid         NUMBER;
  BEGIN
    BEGIN
      --{
      --Logic
      --first look to the Receivables account to get the LE segment
      --value to derive Location, then if it does not find it, use
      --the first Revenue account
      SELECT DISTINCT code_combination_id
        INTO l_ccid
        FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
       WHERE account_class = 'REC'
         AND customer_trx_id = p_Cus_trx_id
         AND ROWNUM = 1;
      PrintOut('TWE:AR:> REC ccid=:' || l_ccid || ':');
      
      IF l_ccid IS NULL THEN
      --(
        BEGIN 
          PrintOut('TWE:AR:> REC not found, get REV Account');
          SELECT DISTINCT code_combination_id
            INTO l_ccid
            FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
           WHERE account_class = 'REV'
             AND customer_trx_id = p_Cus_trx_id
             AND ROWNUM = 1;
          PrintOut('TWE:AR:> REV ccid=:' || l_ccid || ':');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
--            PrintOut('TWE:AR:(E)-get_Location:NO_DATA_FOUND');
            PrintOut('TWE:AR:>1:RETURN Location NULL <--');
            RETURN NULL;
          WHEN OTHERS THEN
            PrintOut('TWE:AR:(E)-1:get_Location:' || SQLERRM);
            RETURN NULL;
        END;
      END IF; --)

    EXCEPTION
      WHEN OTHERS THEN
        PrintOut('TWE:AR:> AR GET Location ERROR');
        PrintOut('TWE:AR:> REC not found, get REV Account');
        BEGIN 
          SELECT DISTINCT code_combination_id
            INTO l_ccid
            FROM APPS.RA_CUST_TRX_LINE_GL_DIST_V
           WHERE account_class = 'REV'
             AND customer_trx_id = p_Cus_trx_id
             AND ROWNUM = 1;
          PrintOut('TWE:AR:> REV ccid=:' || l_ccid || ':');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
 --           PrintOut('TWE:AR:(E)-get_Location:NO_DATA_FOUND');
            PrintOut('TWE:AR:>2:RETURN Location NULL <--');
            RETURN NULL;
          WHEN OTHERS THEN
            PrintOut('TWE:AR:(E)-2:get_Location:' || SQLERRM);
            RETURN NULL;
        END;
    END;

    PrintOut('TWE:AR:>l_ccid:' || l_ccid || ':');
    PrintOut('TWE:AR:>:CharofAcc:' || APPS.ARP_TAX.SYSINFO.CHART_OF_ACCOUNTS_ID || ':');
    IF NOT APPS.FND_FLEX_KEYVAL.Validate_CCID('SQLGL',
                                              'GL#',
                                              APPS.ARP_TAX.SYSINFO.CHART_OF_ACCOUNTS_ID,
                                              l_ccid) THEN
      PrintOut('TWE:AR:>3:RETURN Location Segment NULL <--');
      RETURN NULL;
    END IF;
    
    l_Location := APPS.FND_FLEX_KEYVAL.Segment_Value(4);

    RETURN l_Location;
  END get_Location;    
  
END TAXPKG_10_PARAM;
/
