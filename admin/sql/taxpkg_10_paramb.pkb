CREATE OR REPLACE PACKAGE BODY taxpkg_10_param
/* $Header: $Twev5ARParmbv2.2.4
   $Header: Version - 2.1 Modified for - Defect#1453 Modified by - Bhuvaneswary Sethuraman Date - 14-Sept-09*
   $Header: Version - 2.2 Modified for - Defect#2481 Modified by - Harini G  Date - 11-DEC-09
            Version - 2.3 Modified for - Defect#2481 Modified by - Aravind A Date - 24-MAR-10
                                         Removed insertion of ORDER STATUS in custom attributes*/
-- | Version 2.4 20-JUN-2013    -- RETORFITR12 Vasisht      Modified version 2.3 for R12                                   |
-- |                                                    Upgrade retrofit .Refer to the key word RETORFITR12         |
-- | Version 2.5 17-JAN-2014    -- Veronica Mairembam     Modified for defect 27364|
AS
   /* Govind: 6/13/2007: TWE Engine DB has attribute value length of 20 characters,
      so we need to truncate input Oracle attribute value to 20 before passing the
     string to TWE. See get_AR_customatts and get_OM_customatts functions for code */
   g_twe_custom_attr_len         NUMBER (15) := 20;
   p_name                        VARCHAR2 (10);

   --Added global variables below from twe_ar.taxpkg_10 for defect 27364
   g_jda_enabled_flag       VARCHAR2(1)     := 'N';   
   g_is_internal_order      BOOLEAN;  
   g_is_same_order          BOOLEAN ; 
   g_trx_source             varchar2(100);   
   g_ar_trx_type             varchar2(240);
   g_org_type                varchar2(240);

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
   Company Code -- Based on Ship to Location for Internal
                          Sales Orders -- Defect # 8085
   ********************************************************/
   FUNCTION get_company (
      p_line_id                  IN       NUMBER
   )
      RETURN VARCHAR2
   IS
      l_company_id                  VARCHAR2 (30);
   BEGIN
      SELECT attribute1
        INTO l_company_id
        FROM fnd_flex_values_vl fvv, fnd_flex_value_sets fv
       WHERE fv.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
         AND fvv.flex_value_set_id = fv.flex_value_set_id
         AND fvv.flex_value = (SELECT SUBSTR (ship_to
                                             ,1
                                             ,6
                                             )
                                 FROM oe_order_lines_v oev
                                WHERE line_id = p_line_id);

      RETURN l_company_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('Cant derive company code for ship to location :');
   END get_company;

   FUNCTION get_costcenter (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
   )
      RETURN VARCHAR2
   IS
      l_cost_center                 VARCHAR2 (30);
   BEGIN
      RETURN NULL;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_CostCenter:NO_DATA_FOUND');
         RETURN NULL;
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_CostCenter:'
                   || SQLERRM);
   END get_costcenter;

   FUNCTION get_organization (
      p_org_id                   IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_item_id                  IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
     ,p_other                    IN       VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_organization                VARCHAR2 (30);
      l_ccid                        NUMBER;
   BEGIN
      printout (   'TWE:AR:>org1:'
                || p_org_id
                || ':');

      IF p_other = 'OE_TAX_LINES_SUMMARY'
      THEN
         --(
         printout ('TWE:AR:>org:OM');

         SELECT hh.attribute15
           INTO l_organization
           FROM hr_organization_units_v hh
          WHERE hh.organization_id = p_org_id;

         BEGIN
            l_organization             := get_company (p_cus_trx_line_id);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               printout ('Cant derive company code for ship to location ');
         END;
      ELSE
         --)(
         BEGIN
            --{
            --Logic
            --first look to the Receivables account to get the LE segment
            --value to derive org, then if it does not find it, use
            --the first Revenue account
            SELECT code_combination_id
              INTO l_ccid
              FROM ra_cust_trx_line_gl_dist 
                        -- 4_1_08:perf: use this instead of _v view
              -- Commented for defect #9116
             --WHERE  account_class = 'REC'
             --Defect #9116 First look at Revenue account
            WHERE  account_class = 'REV'
               AND customer_trx_id = p_cus_trx_id
               AND ROWNUM = 1;

            printout (   'TWE:AR:> REV ccid=:'
                      || l_ccid
                      || ':');

            IF l_ccid IS NULL
            THEN
               --(
               printout ('TWE:AR:> REV not found, get REC Account');

               SELECT code_combination_id
                 INTO l_ccid
                 FROM ra_cust_trx_line_gl_dist 
                 -- 4_1_08:perf: use this instead of _v view
                 --Commented for defect # 9116
                --WHERE  account_class = 'REV'
                --Added Defect # 9116
               WHERE  account_class = 'REC'
                  AND customer_trx_id = p_cus_trx_id
                  AND ROWNUM = 1;

               printout (   'TWE:AR:> REC ccid=:'
                         || l_ccid
                         || ':');
            END IF;
         --)
         EXCEPTION
            WHEN OTHERS
            THEN
               printout ('TWE:AR:>org1.3a:AR GET ORG ERROR');
               printout ('TWE:AR:> REV not found, get REC Account');

               SELECT code_combination_id
                 INTO l_ccid
                 FROM ra_cust_trx_line_gl_dist 
                -- 4_1_08:perf: use this instead of _v view
               WHERE  account_class = 'REC'
                  AND customer_trx_id = p_cus_trx_id
                  AND ROWNUM = 1;

               printout (   'TWE:AR:> REC ccid=:'
                         || l_ccid
                         || ':');
         END;

         --}
         printout (   'TWE:AR:>org1.5:l_ccid:'
                   || l_ccid
                   || ':');
         printout (   'TWE:AR:>org1.6:CharofAcc:'
                --   || arp_tax.sysinfo.chart_of_accounts_id -- Commented RETORFITR12
               || ZX_PRODUCT_INTEGRATION_PKG.sysinfo.chart_of_accounts_id   -- Added RETORFITR12
                   || ':');

         IF NOT fnd_flex_keyval.validate_ccid
                                   ('SQLGL'
                                   ,'GL#'
                                 --  ,arp_tax.sysinfo.chart_of_accounts_id -- Commented RETORFITR12
                                    , ZX_PRODUCT_INTEGRATION_PKG.sysinfo.chart_of_accounts_id   -- Added RETORFITR12
                                   ,l_ccid
                                   )
         THEN
            printout ('TWE:AR:>org2: RETURN Organization Code NULL <--');
            RAISE NO_DATA_FOUND;
         END IF;

         l_organization             := fnd_flex_keyval.segment_value (1);
      END IF;

      --)
      printout (   'TWE:AR:>org_out:'
                || l_organization
                || ':');
      RETURN l_organization;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_Organization:NO_DATA_FOUND');
         RETURN NULL;
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_Organization:'
                   || SQLERRM);
         RETURN NULL;
   END get_organization;

   FUNCTION get_jobnumber (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
   )
      RETURN VARCHAR2
   IS
      l_jobnumber                   VARCHAR2 (30);
   BEGIN
      RETURN NULL;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_JobNumber:NO_DATA_FOUND');
         RETURN NULL;
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_JobNumber:'
                   || SQLERRM);
   END get_jobnumber;

   FUNCTION get_entityuse (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
     ,p_other                    IN       VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_entityuse                   VARCHAR2 (30);
   BEGIN
      RETURN NULL;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_EntityUse:NO_DATA_FOUND');
         RETURN NULL;
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_EntityUse:'
                   || SQLERRM);
   END get_entityuse;

   FUNCTION get_prodcode (
      p_item_id                  IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
     ,p_org_id                   IN       NUMBER
     ,p_other                    IN       VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_prodcode                    VARCHAR2 (150);

      /* Office Depot Custom: 2/10/2007: OD_TWE_AR_Design_V21.doc:
         Use item level dff attribute1 for product code */
      CURSOR csr_item_attr
      IS
         SELECT msi.attribute1 AS product_code              /* product code */
           FROM mtl_system_items msi
          WHERE msi.inventory_item_id = p_item_id
            AND msi.organization_id = p_org_id;

      CURSOR csr_item_catg
      IS
         SELECT category_id
           FROM mtl_item_categories
          WHERE inventory_item_id = p_item_id
            AND organization_id = p_org_id
            AND category_set_id = (SELECT category_set_id
                                     FROM mtl_category_sets
                                    WHERE category_set_name = 'PO CATEGORY')
            AND ROWNUM = 1;

      CURSOR csr_catg_segment (
         p_category_id                       NUMBER
      )
      IS
         SELECT segment1
           FROM mtl_categories
          WHERE category_id = p_category_id;

      l_category_id                 NUMBER (15);
   BEGIN
      printout (   'TWE:AR:-get_ProdCode:p_item_id:='
                || p_item_id
                || ':');
      printout (   'TWE:AR:-get_ProdCode:p_org_id:='
                || p_org_id
                || ':');
      printout (   'TWE:AR:-get_ProdCode:p_line_id:='
                || p_cus_trx_line_id
                || ':');

      IF --(taxpkg_10.g_is_internal_order = TRUE)
	  g_is_internal_order = TRUE --Commented/Added For defect 27364
      THEN
         printout
            ('TWE:AR:-get_ProdCode: INTERNAL ORDER. Fetching segment1 from categories, category_set = [PO CATEGORY]  ...');

         FOR crec IN csr_item_catg
         LOOP
            l_category_id              := crec.category_id;
            EXIT;
         END LOOP;

         FOR crec IN csr_catg_segment (l_category_id)
         LOOP
            l_prodcode                 := crec.segment1;
            EXIT;
         END LOOP;

         printout (   'TWE:AR:-get_ProdCode: segment1 = ['
                   || l_prodcode
                   || ']');
      ELSE
         FOR crec IN csr_item_attr
         LOOP
            l_prodcode                 := crec.product_code;
         END LOOP;
      END IF;

        /*
        SELECT ltrim(rtrim(attribute15))
          INTO l_ProdCode
          FROM ra_customer_trx_lines
         WHERE customer_trx_line_id = p_Cus_trx_line_id;
      */
      printout (   'TWE:AR:-get_ProdCode:'
                || l_prodcode
                || ':');
      RETURN l_prodcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_ProdCode:NO_DATA_FOUND');
         RETURN NULL;
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_ProdCode:'
                   || SQLERRM);
   END get_prodcode;

   PROCEDURE get_shipfrom (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_location_id              IN       NUMBER
     ,                                                          --warehouse_id
      p_org_id                   IN       NUMBER
     ,                                                                --org_id
      p_other                    IN       VARCHAR2
     ,                                                             --view_name
      o_country                  OUT NOCOPY VARCHAR2
     ,o_city                     OUT NOCOPY VARCHAR2
     ,o_cnty                     OUT NOCOPY VARCHAR2
     ,o_state                    OUT NOCOPY VARCHAR2
     ,o_zip                      OUT NOCOPY VARCHAR2
     ,o_code                     OUT NOCOPY VARCHAR2
   )
   IS
      /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
         For Ship From: Use the interface_line_attribute10 at the invoice line level
         to find the location value otherwise use the warehouse field from the AR
         transaction line. */
      CURSOR csr_get_trxline_attr
      IS
         SELECT lines.interface_line_attribute10
          -- FROM ra_customer_trx_lines lines
           FROM ra_customer_trx_lines_all lines
          WHERE lines.customer_trx_line_id = p_cus_trx_line_id;

      l_location_id                 VARCHAR2 (150) := NULL;
   BEGIN
      printout (   ':get_ShipFrom:p_org_id      :'
                || p_org_id
                || ':');
      printout (   ':get_ShipFrom:p_warehouse_id:'
                || p_location_id
                || ':');

      /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
       For Ship From: Use the interface_line_attribute10 at the invoice line level
       to find the location value otherwise use the warehouse field from the AR
       transaction line. */
      FOR crec IN csr_get_trxline_attr
      LOOP
         l_location_id              := crec.interface_line_attribute10;
      END LOOP;

      /* End : Office Depot custom */
      IF p_other = 'OE_TAX_LINES_SUMMARY'
      THEN
         --(
         printout (':get_ShipFrom:OM CALL:');

         --Added Substr (1,30) for defect #10915
         SELECT SUBSTR (hl.location_code
                       ,1
                       ,30
                       )
               ,SUBSTR (hl.postal_code
                       ,1
                       ,5
                       )
               ,hl.town_or_city
               ,DECODE (hl.country
                       ,'CA', NULL
                       ,hl.region_1
                       )
               ,
                --County
                DECODE (hl.country
                       ,'CA', hl.region_1
                       ,hl.region_2
                       )
               ,
                --State
                DECODE (hl.country
                       ,'CA', 'CANADA'
                       ,'US', 'UNITED STATES'
                       )                                             --Country
           INTO o_code
               ,o_zip
               ,o_city
               ,o_cnty
               ,o_state
               ,o_country
           FROM hr_organization_units_v hh, hr_locations_all hl
          WHERE hh.location_id = hl.location_id
            AND hh.organization_id = NVL (l_location_id, p_location_id);
      ELSE
         --)(
         IF (p_location_id IS NULL)
         THEN
            --(
            printout (':get_ShipFrom:Loc is NULL:');

            --Added Substr (1,30) for defect #10915
            SELECT SUBSTR (hl.location_code
                          ,1
                          ,30
                          )
                  ,SUBSTR (hl.postal_code
                          ,1
                          ,5
                          )
                  ,hl.town_or_city
                  ,DECODE (hl.country
                          ,'CA', NULL
                          ,hl.region_1
                          )
                  ,
                   --County
                   DECODE (hl.country
                          ,'CA', hl.region_1
                          ,hl.region_2
                          )
                  ,
                   --State
                   DECODE (hl.country
                          ,'CA', 'CANADA'
                          ,'US', 'UNITED STATES'
                          )                                          --Country
              INTO o_code
                  ,o_zip
                  ,o_city
                  ,o_cnty
                  ,o_state
                  ,o_country
              FROM                --hr_organization_information_v    hro,
                   hr_organization_units_v hh, hr_locations_all hl
             WHERE   --hro.org_information_context  = 'Accounting Information'
                   --AND hh.organization_id      = hro.organization_id
                   hh.location_id = hl.location_id
               AND hh.organization_id = p_org_id;
         ELSE
            --)(
            printout (':get_ShipFrom:Loc is NOT NULL:');

            --Added Substr (1,30) for defect #10915
            SELECT SUBSTR (hl.location_code
                          ,1
                          ,30
                          )
                  ,SUBSTR (hl.postal_code
                          ,1
                          ,5
                          )
                  ,hl.town_or_city
                  ,DECODE (hl.country
                          ,'CA', NULL
                          ,hl.region_1
                          )
                  ,
                   --County
                   DECODE (hl.country
                          ,'CA', hl.region_1
                          ,hl.region_2
                          )
                  ,
                   --State
                   DECODE (hl.country
                          ,'CA', 'CANADA'
                          ,'US', 'UNITED STATES'
                          )                                          --Country
              INTO o_code
                  ,o_zip
                  ,o_city
                  ,o_cnty
                  ,o_state
                  ,o_country
              FROM hr_organization_units_v hh, hr_locations_all hl
             WHERE hh.location_id = hl.location_id
               AND hh.organization_id = NVL (l_location_id, p_location_id);

            printout (':get_ShipFrom:GOT Loc:');
         END IF;
      --)
      END IF;

      --) p_other
     -- arp_tax.tax_info_rec.ship_from_code := o_zip; -- Commented RETORFITR12
     ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.ship_from_code := o_zip; -- Added RETORFITR12
      printout (':get_ShipFrom:END');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout (':(E)-get_ShipFrom:NO_DATA_FOUND');
        -- arp_tax.tax_info_rec.ship_from_code := 'XXXXXXXXXX'; -- Commented RETORFITR12
         ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.ship_from_code:= 'XXXXXXXXXX';   -- Added RETORFITR12
      -- Returning XXXXXXXX  will cause it to default to ship to
      WHEN OTHERS
      THEN
         printout (   ':(E)-get_ShipFrom:'
                   || SQLERRM);
         --arp_tax.tax_info_rec.ship_from_code := 'XXXXXXXXXX';-- Commented RETORFITR12
         ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.ship_from_code:= 'XXXXXXXXXX';   -- Added RETORFITR12
   END get_shipfrom;

   PROCEDURE get_shipto (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_location_id              IN       NUMBER
     ,p_org_id                   IN       NUMBER
     ,o_country                  OUT NOCOPY VARCHAR2
     ,o_city                     OUT NOCOPY VARCHAR2
     ,o_cnty                     OUT NOCOPY VARCHAR2
     ,o_state                    OUT NOCOPY VARCHAR2
     ,o_zip                      OUT NOCOPY VARCHAR2
     ,o_code                     OUT NOCOPY VARCHAR2
   )
   IS
      l_saleschannel                VARCHAR2 (200) := 'X';
      l_deliverycode                VARCHAR2 (25) := 'X';

          --lc_jda_enabled  VARCHAR2(10) := 'N';
        /*
       4_1_08: perf changes: using direct tables instead of view. see alternate cursor below


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
            FROM AR_ADDRESSES_V ardv, RA_SITE_USES rasu
           WHERE ardv.address_id = rasu.address_id
             AND rasu.site_use_id = c_site_use_id;

      CURSOR getaddressdata (c_site_use_id NUMBER)
      IS
         SELECT DECODE (loc.state,
                        'CA', 'CANADA',
                        UPPER (terr.territory_short_name)
                       ),

                --Country
                loc.city,
                         --City
                         DECODE (loc.state, 'CA', NULL, loc.county),

                --County
                NVL (loc.province,
                     DECODE (loc.state, 'CA', loc.county, loc.state)
                    ),

                --State
                SUBSTR (loc.postal_code, 1, 5)                          -- Zip
           FROM hz_cust_acct_sites cas,
                hz_cust_site_uses csu,
                hz_party_sites party_site,
                hz_locations loc,
                fnd_territories_vl terr
          WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
            AND csu.site_use_id = c_site_use_id
            AND cas.party_site_id = party_site.party_site_id
            AND loc.location_id = party_site.location_id
            AND loc.country = terr.territory_code(+);
      */
      CURSOR getaddressdata (
         c_site_use_id                       NUMBER
      )
      IS
         SELECT DECODE (loc.country
                       ,'CA', 'CANADA'
                       ,'US', 'UNITED STATES'
                       ,UPPER (terr.territory_short_name)
                       ) country
               ,loc.city city
               ,loc.county county
               ,loc.state state
               ,loc.province province
               ,SUBSTR (loc.postal_code
                       ,1
                       ,5
                       ) zip
               ,UPPER (terr.territory_short_name) territory_short_name
           FROM hz_cust_acct_sites cas
               ,hz_cust_site_uses csu
               ,hz_party_sites party_site
               ,hz_locations loc
               ,fnd_territories_vl terr
          WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
            AND csu.site_use_id = c_site_use_id
            AND cas.party_site_id = party_site.party_site_id
            AND loc.location_id = party_site.location_id
            AND loc.country = terr.territory_code(+);

      CURSOR getlegacyaddressdata
      IS
         SELECT DECODE (custom_ordhdr.ship_to_country
                       ,'CAN', 'CANADA'
                       ,'USA', 'UNITED STATES'
                       ,ship_to_country
                       ) AS country
               ,custom_ordhdr.ship_to_county AS county
               ,custom_ordhdr.ship_to_city AS city
               ,custom_ordhdr.ship_to_state AS state
               ,SUBSTR (custom_ordhdr.ship_to_zip
                       ,1
                       ,5
                       ) AS zip
           FROM xx_om_header_attributes_all custom_ordhdr
               ,ra_customer_trx trx
               ,oe_order_headers ordhdr
          WHERE trx.customer_trx_id = p_cus_trx_id
            --AND to_char(ordhdr.order_number) = trx.interface_header_attribute1
            AND ordhdr.order_number =
                     TO_NUMBER (trx.interface_header_attribute1)
                                                                -- defect 6549
            AND custom_ordhdr.header_id = ordhdr.header_id;

      CURSOR getordersource
      IS
         SELECT ordsrc.NAME NAME
           -- INTO lc_source
         FROM   oe_order_headers hdr
               ,oe_order_lines line
               ,oe_order_sources ordsrc
               ,ra_customer_trx trx
          WHERE line.header_id = hdr.header_id
            AND hdr.order_source_id = ordsrc.order_source_id
            --AND line.line_id = arp_tax.tax_info_rec.customer_trx_line_id;
                        --AND to_char(hdr.order_number) = trx.interface_header_attribute1
            AND hdr.order_number =
                     TO_NUMBER (trx.interface_header_attribute1)
                                                                -- defect 6549
            AND trx.customer_trx_id = p_cus_trx_id;

      CURSOR gethrcode
      IS
         SELECT hrloc.attribute15 attribute15
               ,hrloc.attribute14 jda_enabled
           --  INTO o_code
             --hrloc.country,hrloc.region_1,hrloc.region_2,hrloc.town_or_city,hrloc.postal_code
         FROM   hr_locations_all hrloc
               ,hr_all_organization_units hrorg
               ,oe_order_headers ordhdr
               ,ra_customer_trx trx
          WHERE hrloc.location_id = hrorg.location_id
            AND hrorg.organization_id = ordhdr.ship_from_org_id
            --AND to_char(ordhdr.order_number) = trx.interface_header_attribute1
            AND ordhdr.order_number =
                     TO_NUMBER (trx.interface_header_attribute1)
                                                                -- defect 6549
            AND trx.customer_trx_id = p_cus_trx_id;

      CURSOR getshiptocode
      IS
         SELECT hrloc.country country
               ,hrloc.town_or_city city
               ,hrloc.region_1 province
               ,hrloc.region_2 state
               ,hrloc.postal_code zip
           FROM hr_locations_all hrloc
               ,hr_all_organization_units hrorg
               ,oe_order_headers ordhdr
               ,ra_customer_trx_all trx
          WHERE hrloc.location_id = hrorg.location_id
            AND hrorg.organization_id = ordhdr.ship_from_org_id
            --  AND to_char(ordhdr.order_number) = trx.interface_header_attribute1
            AND ordhdr.order_number =
                     TO_NUMBER (trx.interface_header_attribute1)
                                                                -- defect 6549
            AND trx.customer_trx_id = p_cus_trx_id;

      CURSOR getsaleschannel
      IS
         SELECT flv.meaning saleschannel
           FROM oe_order_headers hdr
               ,fnd_lookup_values flv
               ,ra_customer_trx trx
               ,xx_om_header_attributes_all xoha
          WHERE flv.lookup_code = xoha.od_order_type
            AND flv.lookup_type = 'SALES_CHANNEL'
            AND trx.customer_trx_id = p_cus_trx_id
            AND hdr.order_number = TO_NUMBER (trx.interface_header_attribute1)
            AND hdr.header_id = xoha.header_id;

      CURSOR getdeliveryflag
      IS
         SELECT NVL (delivery_code, 'X') delivery_code
           FROM xx_om_header_attributes_all custom_ordhdr
               ,ra_customer_trx trx
               ,oe_order_headers ordhdr
          WHERE trx.customer_trx_id = p_cus_trx_id
            AND ordhdr.order_number =
                                   TO_NUMBER (trx.interface_header_attribute1)
            AND custom_ordhdr.header_id = ordhdr.header_id;

      CURSOR getpickuplocation
      IS
         SELECT hrloc.country country
               ,hrloc.town_or_city city
               ,DECODE (hrloc.country
                       ,'CA', hrloc.region_1
                       ,hrloc.region_2
                       ) state
               ,DECODE (hrloc.country
                       ,'US', hrloc.region_1
                       ,NULL
                       ) county
               ,                                                --Defect 10721
                hrloc.postal_code zip
           FROM
                --xx_om_header_attributes_all xoh, defect 11065
                hr_locations_all hrloc
               ,hr_all_organization_units hrorg
               ,oe_order_headers ordhdr
               ,ra_customer_trx_all trx
          WHERE hrloc.location_id = hrorg.location_id
            AND hrorg.organization_id = ordhdr.ship_from_org_id
                                  --decode(xoh.paid_at_store_id,null,ordhdr.ship_from_org_id,xoh.paid_at_store_id) for defect 11065
            -- AND ordhdr.header_id = xoh.header_id defect 11065
            AND ordhdr.order_number =
                                   TO_NUMBER (trx.interface_header_attribute1)
            AND trx.customer_trx_id = p_cus_trx_id;
   BEGIN
      printout (   'TWE:AR:get_ShipTo:p_org_id:'
                || p_org_id
                || ':');

      /*
      fnd_file.put_line (fnd_file.LOG,
                    'TWE:AR:get_ShipTo:p_org_id:' || p_org_id || ':'
                   );


      fnd_file.put_line (fnd_file.LOG,
          'Taxpkg10 Legacy order batch is:    ' || Taxpkg_10.g_is_legacy_order_batch);
      */
     -- IF (taxpkg_10.g_is_legacy_order_batch = TRUE)
	 IF (g_is_legacy_order_batch = TRUE)      --Added/Commented for defect 27364
      THEN
         FOR ordsrcrec IN getordersource
         LOOP
            lc_source                  := ordsrcrec.NAME;

            /*  fnd_file.put_line (fnd_file.LOG,
             'TWE:AR:get source name:  ' || lc_source
             || ':'
            );
            */
            IF getordersource%NOTFOUND
            THEN
               /*  fnd_file.put_line (fnd_file.LOG,
                     'TWE:AR:get source name:  ' || lc_source
                     || ':'
                    );
                    */
               RAISE NO_DATA_FOUND;
            END IF;

            EXIT;
         END LOOP;

         /*  POS Order             */
         IF lc_source = 'POE'      --OR lc_source = 'PRO' OR lc_source = 'SPC'
         -- Commented for Defect # 8827
         THEN
            --  USE following SQL TO get address FROM hr_locations
            FOR hrcoderec IN gethrcode
            LOOP
               o_code                     := hrcoderec.attribute15;

               --lc_jda_enabled := hrcoderec.attribute14;  --Defect 12623
               IF hrcoderec.jda_enabled = 'Y'
               THEN                                            --Defect 12623
                  --taxpkg_10.g_jda_enabled_flag := 'Y';         --Defect 12623
				   g_jda_enabled_flag := 'Y'; --Commented/Added for defect 27364
               ELSE
                 -- taxpkg_10.g_jda_enabled_flag := 'N';         --Defect 12623
				   g_jda_enabled_flag := 'N';  --Commented/Added for defect 27364
               END IF;

                /*     fnd_file.put_line
                          (fnd_file.LOG,'attribute 15 is null -- '||
                          '  '||'LC_SOURCE'||lc_source||'  '||
                          'ship to code'||o_code);
               */
               IF gethrcode%NOTFOUND
               THEN
                  /*fnd_file.put_line
                               (fnd_file.LOG,'attribute 15 is null  '||o_code);
                       */
                  RAISE NO_DATA_FOUND;
               END IF;
            END LOOP;

            /*IF lc_jda_enabled = 'Y' THEN --Defect 12623


                    taxpkg_10.g_jda_enabled_flag := 'Y';  --Defect 12623
            ELSE

                    taxpkg_10.g_jda_enabled_flag := 'N';  --Defect 12623

            END IF;*/
            /*  Getting OU Name */
            BEGIN
               SELECT NAME
                 INTO p_name
                 FROM hr_operating_units
                WHERE organization_id = p_org_id;
            END;

            --IF p_org_id = 403  THEN  Canadian Operating Unit
            IF p_name = 'OU_CA'
            THEN
               /*
                               fnd_file.put_line  (fnd_file.LOG,
                               ' BEFORE EXECUTING getshiptorec-- Data Found for Cusomer Trx Id  -'||p_org_id||'-geocode null--poe-spc-pro   '
                               || p_cus_trx_id
                               || ':'
                               );
                               */
               FOR getshiptorec IN getshiptocode
               LOOP
                  o_country                  := getshiptorec.country;
                  o_city                     := getshiptorec.city;
                  o_state                    := getshiptorec.province;
                  o_zip                      := getshiptorec.zip;

                  /*
                                      fnd_file.put_line
                                         (fnd_file.LOG,
                                                 ' Data Found for Cusomer Trx Id -403-geocode null--poe-spc-pro   '
                                              || p_cus_trx_id
                                              || ':'
                                         );
                                      */
                  IF getshiptocode%NOTFOUND
                  THEN
                     /*
                                       fnd_file.put_line
                        (fnd_file.LOG,
                                'No Data Found for Cusomer Trx Id    '
                             || p_cus_trx_id
                             || ':'
                        );
                     */
                     RAISE NO_DATA_FOUND;
                  END IF;
               END LOOP;
            --ELSIF p_org_id = 404   US operating Unit.
            ELSIF p_name = 'OU_US'
            THEN
               BEGIN
                  FOR getshiptorec IN getshiptocode
                  LOOP
                     o_country                  := getshiptorec.country;
                     o_city                     := getshiptorec.city;
                     o_state                    := getshiptorec.state;
                     o_cnty                     := getshiptorec.province;
                                                               --Defect 10721
                     o_zip                      := getshiptorec.zip;

                     /*
                     fnd_file.put_line
                     (fnd_file.LOG,
                     ' Data Found for Cusomer Trx Id  -- geocode null--poe-spc-pro  '
                     || p_cus_trx_id
                     || ':'
                     );
                     */
                     IF getshiptocode%NOTFOUND
                     THEN
                        /*
                                fnd_file.put_line
                                (fnd_file.LOG,
                                'No Data Found for Cusomer Trx Id    '
                                || p_cus_trx_id
                                || ':'
                                );
                        */
                        RAISE NO_DATA_FOUND;
                     END IF;
                  END LOOP;
               END;
            END IF;                                           ---OU Condition.
         ELSE                                                ----Non POS Order
           -- taxpkg_10.g_jda_enabled_flag := 'N';               --Defect 12623
		   g_jda_enabled_flag := 'N';   --Commented/Added for defect 27364

            FOR sales_rec IN
               getsaleschannel             ---Get Sales Channel for the Order
            LOOP
               l_saleschannel             := sales_rec.saleschannel;
            END LOOP;

            IF l_saleschannel = 'Export'          ----Non POS But Export Order
            THEN
               FOR irec IN getaddressdata (p_site_use_id)
               LOOP
                  o_country                  := irec.country;
                  o_city                     := irec.city;
                  o_cnty                     := irec.county;
                  o_state                    :=
                                              NVL (irec.state, irec.province);
                  o_zip                      := irec.zip;

                  IF getaddressdata%NOTFOUND
                  THEN
                     printout ('TWE:AR:(E) ShipTo    Error:NOTFOUND');
                     --fnd_file.put_line (fnd_file.LOG,
                                              --   'TWE:AR:(E) ShipTo        Error:NOTFOUND'
                                              --  );
                     RAISE NO_DATA_FOUND;
                  END IF;
               END LOOP;
            ELSE                                          ----NON-Export Order
               /* ----------------------Added for Defect#     9121-------------------------------------------------------*/
               FOR delcode IN getdeliveryflag        ---Get the Delivery code
               LOOP
                  l_deliverycode             := delcode.delivery_code;
               END LOOP;

               IF l_deliverycode = 'P'
               THEN                                       --Store Pickup Order
                  FOR locrec IN getpickuplocation
                  LOOP
                     o_country                  := locrec.country;
                     o_city                     := locrec.city;
                     o_state                    := locrec.state;
                     o_cnty                     := locrec.county;
                                                               --defect 10721
                     o_zip                      := locrec.zip;
                  END LOOP;
               ELSE                                           ----Normal Order
                  FOR addr_rec IN
                     getlegacyaddressdata
                                --also considers SPC, PRO orders Defect #8827
                  LOOP
                     o_country                  := addr_rec.country;
                     o_cnty                     := addr_rec.county;
                     o_city                     := addr_rec.city;
                     o_state                    := addr_rec.state;
                     o_zip                      := addr_rec.zip;
                     /*
                        fnd_file.put_line
                      (fnd_file.LOG,'get legacy address'||o_country||
                     '  '||o_city||'  '||o_state||'  '||o_zip);
                     */
                     EXIT;

                     IF getlegacyaddressdata%NOTFOUND
                     THEN
                        printout ('TWE:OM:(E) ShipTo  Error:NOTFOUND');
                        -- fnd_file.put_line (fnd_file.LOG,
                          --                       'TWE:OM:(E) ShipTo  Error:NOTFOUND'
                          --                      );
                        RAISE NO_DATA_FOUND;
                     END IF;
                  END LOOP;
               END IF;                                   --Pick Up Order Check
            END IF;                                      ---Export Order Check
         END IF;                          -- Order Type Check (POS Or Non-POS)
      ELSE                                                 ---Non Legacy Order
         FOR irec IN getaddressdata (p_site_use_id)
         LOOP
            o_country                  := irec.country;
            o_city                     := irec.city;
            o_cnty                     := irec.county;
            o_state                    := NVL (irec.state, irec.province);
            o_zip                      := irec.zip;

            IF getaddressdata%NOTFOUND
            THEN
               printout ('TWE:AR:(E) ShipTo    Error:NOTFOUND');
               --  fnd_file.put_line (fnd_file.LOG,
               --                          'TWE:AR:(E) ShipTo  Error:NOTFOUND'
               --                         );
               RAISE NO_DATA_FOUND;
            END IF;
         END LOOP;
      -- o_code := arp_tax.tax_info_rec.p_site_use_id;
      --CLOSE getaddressdata;
      END IF;                                           ----Legacy Order Check

      printout ('TWE:AR:get_get_ShipTo:END');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_ShipTo:NO_DATA_FOUND');
        -- arp_tax.tax_info_rec.ship_to_code := '!ERROR!'; -- -- RETORFITR12
        ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.ship_to_code:= '!ERROR!';  -- -- RETORFITR12
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_ShipTo:'
                   || SQLERRM);
        -- arp_tax.tax_info_rec.ship_to_code := '!ERROR!'; -- -- RETORFITR12
         ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.ship_to_code:= '!ERROR!';  -- -- RETORFITR12
   END get_shipto;

   PROCEDURE get_billto (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_location_id              IN       NUMBER
     ,p_org_id                   IN       NUMBER
     ,o_country                  OUT NOCOPY VARCHAR2
     ,o_city                     OUT NOCOPY VARCHAR2
     ,o_cnty                     OUT NOCOPY VARCHAR2
     ,o_state                    OUT NOCOPY VARCHAR2
     ,o_zip                      OUT NOCOPY VARCHAR2
     ,o_code                     OUT NOCOPY VARCHAR2
   )
   IS
       /* 4_1_08: perf changes: using direct tables instead of view. see alternate cursor below
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
           FROM AR_ADDRESSES_V ardv, RA_SITE_USES rasu
          WHERE ardv.address_id = rasu.address_id
            AND rasu.site_use_id = c_site_use_id;
      */
      CURSOR getaddressdata (
         c_site_use_id                       NUMBER
      )
      IS
         SELECT DECODE (loc.state
                       ,'CA', 'CANADA'
                       ,UPPER (terr.territory_short_name)
                       )
               ,
                --Country
                loc.city
               ,
                --City
                DECODE (loc.state
                       ,'CA', NULL
                       ,loc.county
                       )
               ,
                --County
                NVL (loc.province
                    ,DECODE (loc.state
                            ,'CA', loc.county
                            ,loc.state
                            ))
               ,
                --State
                SUBSTR (loc.postal_code
                       ,1
                       ,5
                       )                                                -- Zip
           FROM hz_cust_acct_sites cas
               ,hz_cust_site_uses csu
               ,hz_party_sites party_site
               ,hz_locations loc
               ,fnd_territories_vl terr
          WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
            AND csu.site_use_id = c_site_use_id
            AND cas.party_site_id = party_site.party_site_id
            AND loc.location_id = party_site.location_id
            AND loc.country = terr.territory_code(+);
   BEGIN
      printout (   'TWE:AR:get_BillTo:p_org_id:'
                || p_org_id
                || ':');
      -- fnd_file.put_line (fnd_file.LOG,'TWE:AR:get_BillTo:p_org_id:' || p_org_id || ':');
     -- arp_tax.tax_info_rec.bill_to_postal_code := ''; -- Commented RETORFITR12
     ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.bill_to_postal_code := '';  -- Added RETORFITR12
      printout ('TWE:AR:-Going for BillTo       Info');

     -- OPEN getaddressdata (arp_tax.tax_info_rec.bill_to_site_use_id);-- Commented RETORFITR12
      OPEN getaddressdata (ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.bill_to_site_use_id);   -- Added RETORFITR12
 
      FETCH getaddressdata
       INTO o_country
           ,o_city
           ,o_cnty
           ,o_state
           ,o_zip;

      IF getaddressdata%NOTFOUND
      THEN
         printout ('TWE:AR:(E) BillTo   Error:NOTFOUND');
         RAISE NO_DATA_FOUND;
      END IF;

      /*o_code                     :=
                                 arp_tax.tax_info_rec.bill_to_site_use_id;*/ -- Commented RETORFITR12
     o_code                     :=
                                 ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.bill_to_site_use_id;  -- Added RETORFITR12
      CLOSE getaddressdata;

     -- arp_tax.tax_info_rec.bill_to_postal_code := o_zip; -- Commented RETORFITR12
     ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.bill_to_postal_code := o_zip;  -- Added RETORFITR12
      printout ('TWE:AR:get_BillTo:END');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_BillTo:NO_DATA_FOUND');
        -- arp_tax.tax_info_rec.bill_to_postal_code := 'XXXXX'; -- Commented RETORFITR12
        ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.bill_to_postal_code := 'XXXXX';   -- Added RETORFITR12
      -- Returning XXXXXXXX  will cause it to default to ship to
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_BillTo:'
                   || SQLERRM);
       --  arp_tax.tax_info_rec.bill_to_postal_code := 'XXXXX'; -- Commented RETORFITR12
       ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.bill_to_postal_code := 'XXXXX';   -- Added RETORFITR12
   END get_billto;

   PROCEDURE get_poo (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_location_id              IN       NUMBER
     ,p_org_id                   IN       NUMBER
     ,o_country                  OUT NOCOPY VARCHAR2
     ,o_city                     OUT NOCOPY VARCHAR2
     ,o_cnty                     OUT NOCOPY VARCHAR2
     ,o_state                    OUT NOCOPY VARCHAR2
     ,o_zip                      OUT NOCOPY VARCHAR2
     ,o_code                     OUT NOCOPY VARCHAR2
   )
   IS
   BEGIN
      printout (   'TWE:AR:get_POO:p_org_id:'
                || p_org_id
                || ':');
   --   arp_tax.tax_info_rec.poo_code := 'XXXXXXXXXX';           -- Commented RETORFITR12
   ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.poo_code := 'XXXXXXXXXX';  -- Added RETORFITR12
      printout ('TWE:AR:get_POO:END');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_POO:NO_DATA_FOUND');
       --  arp_tax.tax_info_rec.poo_code := 'XXXXXXXXXX'; -- Commented RETORFITR12
       ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.poo_code := 'XXXXXXXXXX';  -- Added RETORFITR12
      -- Returning XXXXXXXX  will cause it to default to ship to
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_POO:'
                   || SQLERRM);  
      --   arp_tax.tax_info_rec.poo_code := 'XXXXXXXXXX';               -- Commented RETORFITR12
         ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.poo_code := 'XXXXXXXXXX';     -- Added RETORFITR12 
   END get_poo;

   PROCEDURE get_poa (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_location_id              IN       NUMBER
     ,p_org_id                   IN       NUMBER
     ,o_country                  OUT NOCOPY VARCHAR2
     ,o_city                     OUT NOCOPY VARCHAR2
     ,o_cnty                     OUT NOCOPY VARCHAR2
     ,o_state                    OUT NOCOPY VARCHAR2
     ,o_zip                      OUT NOCOPY VARCHAR2
     ,o_code                     OUT NOCOPY VARCHAR2
     ,p_order_date               IN       DATE
   )
   IS
      l_salesrepid                  VARCHAR2 (100) := NULL;
   BEGIN
    --  arp_tax.tax_info_rec.poa_code := '';             -- Commented RETORFITR12
    ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.poa_code := '';  -- Added RETORFITR12 
      printout (   'TWE:AR:get_POA:p_line_id:'
                || p_cus_trx_line_id
                || ':');
      printout (   'TWE:AR:get_POA:p_TRX_id:'
                || p_cus_trx_id
                || ':');

     -- fnd_file.put_line (fnd_file.LOG,
     --                            'TWE:AR:get_POA:p_line_id:'
     --                         || p_cus_trx_line_id
     --                         || ':'
     --                        );
--For defect 8511. Use ra_customer_trx_all instead of ra_cust_trx_line_salesreps_v
                        --Added Substr (1,30) for defect #10915
      SELECT SUBSTR (loc.location_code
                    ,1
                    ,30
                    )
            ,ract.primary_salesrep_id
            ,                                              --rals.salesrep_id,
             SUBSTR (loc.postal_code
                    ,1
                    ,5
                    )
            ,loc.town_or_city
            ,DECODE (loc.country
                    ,'CA', NULL
                    ,loc.region_1
                    )
            ,
             --County
             DECODE (loc.country
                    ,'CA', loc.region_1
                    ,loc.region_2
                    )
            ,
             --State
             DECODE (loc.country
                    ,'CA', 'CANADA'
                    ,'US', 'UNITED STATES'
                    )
        --Country
      INTO   o_code
            ,l_salesrepid
            ,o_zip
            ,o_city
            ,o_cnty
            ,o_state
            ,o_country
        FROM ra_customer_trx_all ract
            ,ra_salesreps rasr
            ,per_all_assignments_f asgn
            ,hr_locations_all loc
       WHERE ract.customer_trx_id = p_cus_trx_id
         AND rasr.salesrep_id = ract.primary_salesrep_id
         AND rasr.person_id = asgn.person_id
         AND TRUNC (p_order_date) BETWEEN TRUNC (effective_start_date)
                                      AND TRUNC (effective_end_date)
         AND loc.location_id = asgn.location_id;

      --  fnd_file.put_line (fnd_file.LOG, 'o_code '||o_code);
         --   fnd_file.put_line (fnd_file.LOG, 'o_city '||o_city);
         --   fnd_file.put_line (fnd_file.LOG, 'o_country '||o_country);
      printout ('TWE:AR:get_POA:END');
   --  fnd_file.put_line (fnd_file.LOG, 'TWE:AR:get_POA:END');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_POA:NO_DATA_FOUND');
      --   arp_tax.tax_info_rec.poa_code := 'XXXXXXXXXX'; -- Commented RETORFITR12
       ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.poa_code := 'XXXXXXXXXX'; -- Added RETORFITR12
       -- Returning XXXXXXXX  will cause it to default to ship to
      -- fnd_file.put_line (fnd_file.LOG,
       --                        'TWE:AR:(E)-get_POA:NO_DATA_FOUND'
        --                      );
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_POA:'
                   || SQLERRM);
         --   fnd_file.put_line (fnd_file.LOG,
         ---                              'TWE:AR:(E)-get_POA:NO_DATA_FOUND   '
          --                          || SQLERRM
          --                         );
       --  arp_tax.tax_info_rec.poa_code := 'XXXXXXXXXX';        -- Commented RETORFITR12
       ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.poa_code := 'XXXXXXXXXX'; -- Added RETORFITR12
   END get_poa;

   /* 5/11/07: Govind: Office Depot Custom: Requirements Doc: OD_TWE_AR_Design_v21.doc.
    This  get_CustomAtts function should return a value of the form */ ---> name1:value1:name2:value2:name3:value3  <--- */
   FUNCTION get_ar_customatts (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
     ,p_org_id                   IN       NUMBER
   )
      RETURN VARCHAR2
   IS
      CURSOR c_ar_invoice_source
      IS
         SELECT bs.NAME
           FROM ra_customer_trx trx, ra_batch_sources bs
          WHERE bs.batch_source_id = trx.batch_source_id
            AND trx.customer_trx_id = p_cus_trx_id;

      CURSOR c_ar_trx_type
      IS
         SELECT trxtypes.NAME
           FROM ra_cust_trx_types trxtypes
          WHERE trxtypes.cust_trx_type_id = p_trx_type_id;

      CURSOR c_ar_line_amount
      IS
         SELECT extended_amount
           FROM ra_customer_trx_lines
          WHERE customer_trx_line_id = p_cus_trx_line_id;

      --Above code can get the taxable amount Defect # 8243
      /* Inventory Org */

      /* 4_1_08: perf: Use table instead of view
      CURSOR c_org_type IS
        select hrorg.organization_type
          from hr_organization_units_v hrorg
         where hrorg.organization_id = to_number(arp_tax.tax_info_rec.Ship_From_Warehouse_id);
      */
      CURSOR c_org_type
      IS
         SELECT l.meaning AS organization_type
           FROM hr_organization_units o, hr_lookups l
          WHERE o.TYPE = l.lookup_code(+)
            AND l.lookup_type(+) = 'ORG_TYPE'
            AND o.organization_id =
                 --  TO_NUMBER (arp_tax.tax_info_rec.ship_from_warehouse_id);         -- Commented RETORFITR12
                 TO_NUMBER (ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.ship_from_warehouse_id); -- Added RETORFITR12

      l_ar_invoice_source           VARCHAR2 (240);
      l_ar_trx_type                 VARCHAR2 (240);
      l_org_type                    VARCHAR2 (240);
      l_custom_attr_str             VARCHAR2 (2000) := NULL;
      l_glacct                      VARCHAR2 (240);
      l_location                    VARCHAR2 (240);
      l_line_amount                 VARCHAR2 (240);
   BEGIN
      printout ('TWE:AR: get_AR_CustomAtts + ');
        /* 5/11/07: Govind: Office Depot Custom: Requirements Doc: OD_TWE_AR_Design_v21.doc.
      Description: Get AR Invoice Source for custom attribute OD Txn Source */

      /*
      FOR arbsrec in c_ar_invoice_source LOOP
        l_ar_invoice_source := arbsrec.name;
      END LOOP;

      if (l_ar_invoice_source is not null) then
        l_custom_attr_str := 'OD Txn Source:' || substr(replace(l_ar_invoice_source, ':', ' '),1,g_TWE_CUSTOM_ATTR_LEN);
      end if;
      */
      l_custom_attr_str          :=
            'OD Txn Source:'
         || SUBSTR (REPLACE (--taxpkg_10.g_trx_source
		                    g_trx_source   --Commented/Added for Defect 27364
                            ,':'
                            ,' '
                            )
                   ,1
                   ,g_twe_custom_attr_len
                   );

      /* Get AR Trx Type for custom attr OD Txn Type */
      --IF (taxpkg_10.g_is_same_order = FALSE)    
	  IF (g_is_same_order = FALSE)    --Commented/Added for Defect 27364
      THEN
         FOR artyperec IN c_ar_trx_type
         LOOP
            l_ar_trx_type              := artyperec.NAME;
         END LOOP;

         IF (l_ar_trx_type IS NOT NULL)
         THEN
            IF (l_custom_attr_str IS NOT NULL)
            THEN
               l_custom_attr_str          :=    l_custom_attr_str
                                             || ':';
            END IF;

            --taxpkg_10.g_ar_trx_type    := l_ar_trx_type;
			g_ar_trx_type    := l_ar_trx_type;      --Commented/Added for defect 27364
            l_custom_attr_str          :=
                  l_custom_attr_str
               || 'OD Txn Type:'
               || SUBSTR (REPLACE (l_ar_trx_type
                                  ,':'
                                  ,' '
                                  )
                         ,1
                         ,g_twe_custom_attr_len
                         );
         END IF;
      ELSE
         /* For the same order, pick up transaction type from global variable */
         IF (l_custom_attr_str IS NOT NULL)
         THEN
            l_custom_attr_str          :=    l_custom_attr_str
                                          || ':';
         END IF;

         l_custom_attr_str          :=
               l_custom_attr_str
            || 'OD Txn Type:'
            || SUBSTR (REPLACE (--taxpkg_10.g_ar_trx_type
			                    g_ar_trx_type    --Commented/Added for defect 27364
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      /* Get HR Org Type for custom attr OD org Type */
      --IF (taxpkg_10.g_is_same_order = FALSE)     
	  IF (g_is_same_order = FALSE)         --Commented/Added for Defect 27364
      THEN
         FOR orgrec IN c_org_type
         LOOP
            l_org_type                 := orgrec.organization_type;
         END LOOP;

         IF (l_org_type IS NOT NULL)
         THEN
            IF (l_custom_attr_str IS NOT NULL)
            THEN
               l_custom_attr_str          :=    l_custom_attr_str
                                             || ':';
            END IF;

            --taxpkg_10.g_org_type       := l_org_type;
			g_org_type       := l_org_type;         --Commented/Added for defect 27364
            l_custom_attr_str          :=
                  l_custom_attr_str
               || 'OD org type:'
               || SUBSTR (REPLACE (l_org_type
                                  ,':'
                                  ,' '
                                  )
                         ,1
                         ,g_twe_custom_attr_len
                         );
         END IF;
      ELSE
         /* For the same order, pick up org_type from global variable */
         IF (l_custom_attr_str IS NOT NULL)
         THEN
            l_custom_attr_str          :=    l_custom_attr_str
                                          || ':';
         END IF;

         l_custom_attr_str          :=
               l_custom_attr_str
            || 'OD Txn Type:'
            || SUBSTR (REPLACE (--taxpkg_10.g_org_type
			                   g_org_type --Commented/Added for defect 27364
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      l_glacct                   :=
         get_glacct (NULL
                    ,                                              --p_Cust_id
                     NULL
                    ,                                         --p_Site_use_id,
                     p_cus_trx_id
                    ,                                           --p_Cus_trx_id
                     NULL
                    ,NULL
                    /*p_Trx_type_id*/
                    );

      IF (l_glacct IS NOT NULL)
      THEN
         IF (l_custom_attr_str IS NOT NULL)
         THEN
            l_custom_attr_str          :=    l_custom_attr_str
                                          || ':';
         END IF;

         l_custom_attr_str          :=
               l_custom_attr_str
            || 'OD GL account:'
            || SUBSTR (REPLACE (l_glacct
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      l_location                 :=
         get_location (NULL
                      ,                                            --p_Cust_id
                       NULL
                      ,                                       --p_Site_use_id,
                       p_cus_trx_id
                      ,                                         --p_Cus_trx_id
                       NULL
                      ,NULL
                      /*p_Trx_type_id*/
                      );

      IF (l_location IS NOT NULL)
      THEN
         IF (l_custom_attr_str IS NOT NULL)
         THEN
            l_custom_attr_str          :=    l_custom_attr_str
                                          || ':';
         END IF;

         l_custom_attr_str          :=
               l_custom_attr_str
            || 'OD location code:'
            || SUBSTR (REPLACE (l_location
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      /* OD Custom: Per Sept 5 discussions with Noor and Siva, setting custom attribute
           to indicate source of the taxable transaction */
      l_custom_attr_str          :=
                            l_custom_attr_str
                         || ':'
                         || 'OD APPLICATION:'
                         || 'AR';
      /*
          FOR amtrec IN c_ar_line_amount
         LOOP
            l_line_amount := amtrec.extended_amount;
         END LOOP;

      fnd_file.put_line (fnd_file.LOG,'extened amount' || l_line_amount);

                     l_custom_attr_str :=
                         l_custom_attr_str || ':' || 'OD SALES AMOUNT:' || l_line_amount;
            */
      printout ('TWE:AR: get_AR_CustomAtts - ');
      RETURN l_custom_attr_str;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_AR_CustomAtts:NO_DATA_FOUND');
         RETURN NULL;
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_AR_CustomAtts:'
                   || SQLERRM);
   END get_ar_customatts;

   /* 5/11/07: Govind: Office Depot Custom: Requirements Doc: OD_TWE_AR_Design_v21.doc.
    This  get_CustomAtts function should return a value of the form */ ---> name1:value1:name2:value2:name3:value3  <--- */
   FUNCTION get_om_customatts (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
     ,p_org_id                   IN       NUMBER
   )
      RETURN VARCHAR2
   IS
      /* Get Order Type */
      CURSOR csr_om_order_type
      IS
         SELECT ordtype.NAME
           FROM oe_order_headers hdr
               ,oe_order_lines line
               ,oe_order_types_v ordtype
          WHERE line.header_id = hdr.header_id
            AND hdr.order_type_id = ordtype.order_type_id
            AND line.line_id = p_cus_trx_line_id;

      /* Get Order Source */
      CURSOR csr_om_order_src
      IS
         SELECT ordsrc.NAME
               ,line.line_id line                      --Added for Defect 2481
           -- ,line.flow_status_code STATUS  -- Added for Defect 2481-- Commented for Defect 2481 on 24-Mar-10
         FROM   oe_order_headers hdr
               ,oe_order_lines line
               ,oe_order_sources ordsrc
          WHERE line.header_id = hdr.header_id
            AND hdr.order_source_id = ordsrc.order_source_id
            AND line.line_id = p_cus_trx_line_id;

      /* Inventory Org */
      CURSOR csr_ship_from_loc
      IS
         SELECT hrorg.location_code
           FROM hr_organization_units_v hrorg
          WHERE hrorg.organization_id =
                 --  TO_NUMBER (arp_tax.tax_info_rec.ship_from_warehouse_id);        -- -- RETORFITR12
                    TO_NUMBER (ZX_PRODUCT_INTEGRATION_PKG.tax_info_rec.ship_from_warehouse_id);    -- -- RETORFITR12

      l_order_type                  VARCHAR2 (240);
      l_order_source                VARCHAR2 (240);
      l_ship_from_loc               VARCHAR2 (300);
      lc_ship_to_loc                hz_cust_site_uses.LOCATION%TYPE;
      ln_order_line_id              oe_order_lines.line_id%TYPE;
                                                       --Added for defect 2481
      --lc_order_status     VARCHAR2 (240); --Added for Defect 2481-- Commented for Defect 2481 on 24-Mar-10
      -- name is 240, location_code is 60
      l_custom_attr_str             VARCHAR2 (2000) := NULL;
   BEGIN
      printout ('TWE:AR: get_OM_CustomAtts + ');

        /* 5/11/07: Govind: Office Depot Custom: Requirements Doc: OD_TWE_AR_Design_v21.doc.
      Description: Get OM Order Source for custom attribute OD Txn Source */
      FOR ordsrcrec IN csr_om_order_src
      LOOP
         l_order_source             := ordsrcrec.NAME;
         ln_order_line_id           := ordsrcrec.line;
                                                      --Added for Defect 2481
      --lc_order_status := ordsrcrec.STATUS; --Added for Defect 2481-- Commented for Defect 2481 on 24-Mar-10
      END LOOP;

      IF (l_order_source IS NOT NULL)
      THEN
         l_custom_attr_str          :=
               'OD Txn Source:'
            || SUBSTR (REPLACE (l_order_source
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      /* -- Appending Order Status:
         IF (lc_order_status IS NOT NULL)
         THEN
              IF (l_custom_attr_str IS NOT NULL)
              THEN
                   l_custom_attr_str := l_custom_attr_str || ':';
              END IF;

              l_custom_attr_str := l_custom_attr_str
                                  || 'OD Order Status:'
                                  || SUBSTR (REPLACE (lc_order_status, ':', ' '),
                                     1,
                                     g_twe_custom_attr_len
                                    );
         END IF;*/ -- Commented for Defect 2481 on 24-Mar-10

      --Appending the order line ID also in the custom attributes for defect 2481 - Start
      -- Appending Line ID:
      IF (ln_order_line_id IS NOT NULL)
      THEN
         IF (l_custom_attr_str IS NOT NULL)
         THEN
            l_custom_attr_str          :=    l_custom_attr_str
                                          || ':';
         END IF;

         l_custom_attr_str          :=
               l_custom_attr_str
            || 'OD ORDER LINE ID:'                     --Changed to UPPER CASE
            || SUBSTR (REPLACE (ln_order_line_id
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      --Appending the order line ID also in the custom attributes for defect 2481 - End

      /* Get OM Order Type for custom attr OD Txn Type */
      FOR ordtyperec IN csr_om_order_type
      LOOP
         l_order_type               := ordtyperec.NAME;
      END LOOP;

      IF (l_order_type IS NOT NULL)
      THEN
         IF (l_custom_attr_str IS NOT NULL)
         THEN
            l_custom_attr_str          :=    l_custom_attr_str
                                          || ':';
         END IF;

         l_custom_attr_str          :=
               l_custom_attr_str
            || 'OD Txn Type:'
            || SUBSTR (REPLACE (l_order_type
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      /* Get HR Org Type for custom attr OD org Type */
      FOR locrec IN csr_ship_from_loc
      LOOP
         l_ship_from_loc            := locrec.location_code;
      END LOOP;

      IF (l_ship_from_loc IS NOT NULL)
      THEN
         IF (l_custom_attr_str IS NOT NULL)
         THEN
            l_custom_attr_str          :=    l_custom_attr_str
                                          || ':';
         END IF;

         l_custom_attr_str          :=
               l_custom_attr_str
            || 'OD location code:'
            || SUBSTR (REPLACE (l_ship_from_loc
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      --START --Added for defect #1453
      BEGIN
         SELECT hzsu.LOCATION
           INTO lc_ship_to_loc
           FROM hz_cust_site_uses hzsu, oe_order_lines ool
          WHERE hzsu.site_use_id = ool.ship_to_org_id
            AND ool.line_id = p_cus_trx_line_id
            AND site_use_code = 'SHIP_TO';
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_ship_to_loc             := NULL;
      END;

      IF (lc_ship_to_loc IS NOT NULL)
      THEN
         IF (l_custom_attr_str IS NOT NULL)
         THEN
            l_custom_attr_str          :=    l_custom_attr_str
                                          || ':';
         END IF;

         l_custom_attr_str          :=
               l_custom_attr_str
            || 'OD SHIP TO LOC:'
            || SUBSTR (REPLACE (lc_ship_to_loc
                               ,':'
                               ,' '
                               )
                      ,1
                      ,g_twe_custom_attr_len
                      );
      END IF;

      --END ----Added for defect #1453

      /* OD Custom: Per Sept 5 discussions with Noor and Siva, setting custom attribute
       to indicate source of the taxable transaction */
      l_custom_attr_str          :=
                            l_custom_attr_str
                         || ':'
                         || 'OD APPLICATION:'
                         || 'OM';
      printout ('TWE:AR: get_OM_CustomAtts - ');
      RETURN l_custom_attr_str;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_OM_CustomAtts:NO_DATA_FOUND');
         RETURN NULL;
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_OM_CustomAtts:'
                   || SQLERRM);
   END get_om_customatts;

   FUNCTION get_customatts (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
   )
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN NULL;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         printout ('TWE:AR:(E)-get_CustomAtts:NO_DATA_FOUND');
         RETURN NULL;
      WHEN OTHERS
      THEN
         printout (   'TWE:AR:(E)-get_CustomAtts:'
                   || SQLERRM);
   END get_customatts;

   PROCEDURE printout (
      MESSAGE                    IN       VARCHAR2
   )
   IS
   BEGIN
      --IF globalprintoption = 'Y'
      --THEN
         --(
      arp_util_tax.DEBUG (   'TWE_AR:(pv2.0):'
                               || MESSAGE
                               || ':');
      --END IF;
   --)
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END printout;
--ADDING the PROCEDURE printout from TWE_AR.taxpkg_10 and renamed to "printout_fromtaxpkg_10" as part of defect 27364  
   PROCEDURE printout_fromtaxpkg_10 (MESSAGE IN VARCHAR2)
   IS
   BEGIN
      IF (globalprintoption = 'Y')
      THEN
          arp_util_tax.DEBUG ('TWE_AR:' || MESSAGE || ':');

          fnd_file.put_line
              (fnd_file.LOG,
                  '*** AR ADAPTOR-TWE-AR :'||MESSAGE
              );
                /*
            insTrxAdt(arp_tax.tax_info_rec.Customer_trx_id,
                     arp_tax.tax_info_rec.Customer_trx_line_id,
                     NULL,--   L_TWE_DOC_ID
                     NULL,--   L_TWE_LINE_ID
                     'PrintOut', --   L_STATUS
                     NULL,--   L_RETURN_CODE
                     Message,
                     'TaxPkg_10');
      */
      ELSE
         NULL;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END printout_fromtaxpkg_10;
--END of defect 27364

    /* Office Depot Custom: 5/10/2007: : OD_TWE_AR_Design_V21.doc:
   Use Geocode before using ship-to address.
   We get the value of geocode here and pass back to TAXFN_TAX010 which passes
   the geocode and ship-to/bill-to addresses as separate parameters to the
   TWE java engine */
   FUNCTION get_geocode (
      p_cus_trx_id               IN       NUMBER
     ,p_site_use_id              IN       NUMBER
   )
      RETURN VARCHAR2
   IS
      l_geocode                     VARCHAR2 (150);

      CURSOR csr_geocode_hrloc
      IS
         --  use following sql to get address from hr_locations
         SELECT DISTINCT hrloc.attribute15 geocode
                    -- INTO lc_geocode
                     --hrloc.country,hrloc.region_1,hrloc.region_2,hrloc.town_or_city,hrloc.postal_code
         FROM            hr_locations_all hrloc
                        ,hr_all_organization_units hrorg
                        ,oe_order_headers ordhdr
                        ,ra_customer_trx_all trx
                   WHERE hrloc.location_id = hrorg.location_id
                     AND hrorg.organization_id = ordhdr.ship_from_org_id
                     AND ordhdr.order_number = trx.interface_header_attribute1
                     AND trx.customer_trx_id = p_cus_trx_id;

      CURSOR csr_geocode_billto
      IS
         SELECT cas.attribute14 geocode
           FROM hz_cust_acct_sites cas, hz_cust_site_uses csu
          WHERE cas.cust_acct_site_id = csu.cust_acct_site_id
            AND csu.site_use_id = p_site_use_id;

      CURSOR csr_geocode_xxom
      IS
         SELECT DISTINCT ship_to_geocode geocode
                    FROM xx_om_header_attributes_all custom_ordhdr
                        ,ra_customer_trx_all trx
                        ,oe_order_headers ordhdr
                   WHERE trx.customer_trx_id = p_cus_trx_id
                     -- AND to_char(ordhdr.order_number) = trx.interface_header_attribute1
                     AND ordhdr.order_number =
                            TO_NUMBER
                                (trx.interface_header_attribute1)
                                                                -- defect 6549
                     AND custom_ordhdr.header_id = ordhdr.header_id;
   BEGIN
      printout (   'TWE:AR:-get_GeoCode:p_cus_trx_id:='
                || p_cus_trx_id
                || ':');

           /* fnd_file.put_line (fnd_file.LOG,
                                       'TWE:AR:-get_GeoCode:p_cus_trx_id:='
                                    || p_cus_trx_id
                                    || ':'
                                   );
      */
      IF lc_source = 'POE'        -- OR lc_source = 'PRO' OR lc_source = 'SPC'
                                  -- commented for defect #8827
      THEN
         BEGIN
            FOR crec IN csr_geocode_hrloc
            LOOP
               l_geocode                  := crec.geocode;
            END LOOP;

            printout (   'TWE:AR:-get_GeoCode:'
                      || l_geocode
                      || ':');
            --   fnd_file.put_line (fnd_file.LOG,
             --                          'TWE:AR:-get_GeoCode-POS:' || l_geocode || ':'
             --                         );
            RETURN NULL;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               printout ('TWE:AR:(E)-get_GeoCode:NO_DATA_FOUND');
               -- fnd_file.put_line (fnd_file.LOG,
               ---                         'TWE:AR:(E)-get_GeoCode-POS:NO_DATA_FOUND'
                --                       );
               RETURN NULL;
            WHEN OTHERS
            THEN
               printout (   'TWE:AR:(E)-get_GeoCode:'
                         || SQLERRM);
          -- fnd_file.put_line (fnd_file.LOG,
         --                          'TWE:AR:(E)-get_GeoCode-POS:' || SQLERRM
         --                         );
         END;
      ELSE
         IF p_site_use_id IS NULL
         THEN
            BEGIN
               FOR crec IN csr_geocode_xxom
               LOOP
                  l_geocode                  := crec.geocode;
               END LOOP;

               printout (   'TWE:AR:-get_GeoCode:'
                         || l_geocode
                         || ':');
               -- fnd_file.put_line (fnd_file.LOG,
               --                         'TWE:AR:-get_GeoCode-AOPS:' || l_geocode || ':'
               --                        );
               RETURN NULL;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  printout ('TWE:AR:(E)-get_GeoCode:NO_DATA_FOUND');
                  -- fnd_file.put_line (fnd_file.LOG,
                   --                        'TWE:AR:(E)-get_GeoCode-AOPS:NO_DATA_FOUND'
                   --                       );
                  RETURN NULL;
               WHEN OTHERS
               THEN
                  printout (   'TWE:AR:(E)-get_GeoCode:'
                            || SQLERRM);
            -- fnd_file.put_line (fnd_file.LOG,
            ----                         'TWE:AR:(E)-get_GeoCode-AOPS:' || SQLERRM
             --                       );
            END;
         ELSE
            BEGIN
               FOR crec IN csr_geocode_billto
               LOOP
                  l_geocode                  := crec.geocode;
               END LOOP;

               printout (   'TWE:AR:-get_GeoCode:'
                         || l_geocode
                         || ':');
               --  fnd_file.put_line (fnd_file.LOG,
                --                         'TWE:AR:-get_GeoCode-BILLTO:' || l_geocode || ':'
                --                        );
               RETURN NULL;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  printout ('TWE:AR:(E)-get_GeoCode:NO_DATA_FOUND');
                  --fnd_file.put_line (fnd_file.LOG,
                   --                       'TWE:AR:(E)-get_GeoCode-BILLTO:NO_DATA_FOUND'
                   --                      );
                  RETURN NULL;
               WHEN OTHERS
               THEN
                  printout (   'TWE:AR:(E)-get_GeoCode:'
                            || SQLERRM);
            -- fnd_file.put_line (fnd_file.LOG,
            --                         'TWE:AR:(E)-get_GeoCode:' || SQLERRM
             ---                       );
            END;
         END IF;
      END IF;
   END get_geocode;

   /* Office Depot:  Custom Attributes */
   FUNCTION get_glacct (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
   )
      RETURN VARCHAR2
   IS
      l_glacct                      VARCHAR2 (30);
      l_ccid                        NUMBER;
   BEGIN
      BEGIN
         --{
         --Logic
         --first look to the Receivables account to get the LE segment
         --value to derive GL Account, then if it does not find it, use
         --the first Revenue account
         SELECT code_combination_id
           INTO l_ccid
           FROM ra_cust_trx_line_gl_dist
          -- 4_1_08:perf: use this instead of _v view
         WHERE  account_class = 'REC'
            AND customer_trx_id = p_cus_trx_id
            AND ROWNUM = 1;

         printout (   'TWE:AR:> REC ccid=:'
                   || l_ccid
                   || ':');

         IF l_ccid IS NULL
         THEN
            --(
            BEGIN
               printout ('TWE:AR:> REC not found, get REV Account');

               SELECT code_combination_id
                 INTO l_ccid
                 FROM ra_cust_trx_line_gl_dist
                -- 4_1_08:perf: use this instead of _v view
               WHERE  account_class = 'REV'
                  AND customer_trx_id = p_cus_trx_id
                  AND ROWNUM = 1;

               printout (   'TWE:AR:> REV ccid=:'
                         || l_ccid
                         || ':');
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  --            PrintOut('TWE:AR:(E)-get_GLAcct:NO_DATA_FOUND');
                  printout ('TWE:AR:>1:RETURN GL Account NULL <--');
                  RETURN NULL;
               WHEN OTHERS
               THEN
                  printout (   'TWE:AR:(E)-1:get_GLAcct:'
                            || SQLERRM);
                  RETURN NULL;
            END;
         END IF;
      --)
      EXCEPTION
         WHEN OTHERS
         THEN
            printout ('TWE:AR:> AR GET GL ERROR');
            printout ('TWE:AR:> REC not found, get REV Account');

            BEGIN
               SELECT code_combination_id
                 INTO l_ccid
                 FROM ra_cust_trx_line_gl_dist
                -- 4_1_08:perf: use this instead of _v view
               WHERE  account_class = 'REV'
                  AND customer_trx_id = p_cus_trx_id
                  AND ROWNUM = 1;

               printout (   'TWE:AR:> REV ccid=:'
                         || l_ccid
                         || ':');
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  --           PrintOut('TWE:AR:(E)-get_GLAcct:NO_DATA_FOUND');
                  printout ('TWE:AR:>2:RETURN GL Account NULL <--');
                  RETURN NULL;
               WHEN OTHERS
               THEN
                  printout (   'TWE:AR:(E)-2:get_GLAcct:'
                            || SQLERRM);
                  RETURN NULL;
            END;
      END;

      printout (   'TWE:AR:>l_ccid:'
                || l_ccid
                || ':');
      printout (   'TWE:AR:>:CharofAcc:'
               -- || arp_tax.sysinfo.chart_of_accounts_id                    -- Commented RETORFITR12
                  || ZX_PRODUCT_INTEGRATION_PKG.sysinfo.chart_of_accounts_id   -- Added RETORFITR12
                || ':');

      IF NOT fnd_flex_keyval.validate_ccid
                                   ('SQLGL'
                                   ,'GL#'
                                --   ,arp_tax.sysinfo.chart_of_accounts_id            -- Commented RETORFITR12
                                     , ZX_PRODUCT_INTEGRATION_PKG.sysinfo.chart_of_accounts_id -- Added RETORFITR12
                                   ,l_ccid
                                   )
      THEN
         printout ('TWE:AR:>3:RETURN GL Account NULL <--');
         RETURN NULL;
      END IF;

      l_glacct                   := fnd_flex_keyval.segment_value (3);
      RETURN l_glacct;
   END get_glacct;

   /* Office Depot: Custom Attributes */
   FUNCTION get_location (
      p_cust_id                  IN       NUMBER
     ,p_site_use_id              IN       NUMBER
     ,p_cus_trx_id               IN       NUMBER
     ,p_cus_trx_line_id          IN       NUMBER
     ,p_trx_type_id              IN       NUMBER
   )
      RETURN VARCHAR2
   IS
      l_location                    VARCHAR2 (30);
      l_ccid                        NUMBER;
   BEGIN
      BEGIN
              --{
              --Logic
              --first look to the Receivables account to get the LE segment
              --value to derive Location, then if it does not find it, use
              --the first Revenue account
         /*
             New Logic based on Defect #8590. First look at Revenue account and
             if code combination is Null then, look at receivables account
         */
         SELECT code_combination_id
           INTO l_ccid
           FROM ra_cust_trx_line_gl_dist
          -- 4_1_08:perf: use this instead of _v view
         WHERE  account_class = 'REV'
            AND customer_trx_id = p_cus_trx_id
            AND ROWNUM = 1;

         printout (   'TWE:AR:> REV ccid=:'
                   || l_ccid
                   || ':');

         IF l_ccid IS NULL
         THEN
            --(
            BEGIN
               printout ('TWE:AR:> REV not found, get Receivables Account');

               SELECT code_combination_id
                 INTO l_ccid
                 FROM ra_cust_trx_line_gl_dist
                -- 4_1_08:perf: use this instead of _v view
               WHERE  account_class = 'REC'
                  AND customer_trx_id = p_cus_trx_id
                  AND ROWNUM = 1;

               printout (   'TWE:AR:> REC ccid=:'
                         || l_ccid
                         || ':');
            /*  code moved above
                  SELECT code_combination_id
                 INTO l_ccid
                 FROM ra_cust_trx_line_gl_dist
                -- 4_1_08:perf: use this instead of _v view
               WHERE  account_class = 'REV'
                  AND customer_trx_id = p_cus_trx_id
                  AND ROWNUM = 1;
            */
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  --            PrintOut('TWE:AR:(E)-get_Location:NO_DATA_FOUND');
                  printout ('TWE:AR:>1:RETURN Location NULL <--');
                  RETURN NULL;
               WHEN OTHERS
               THEN
                  printout (   'TWE:AR:(E)-1:get_Location:'
                            || SQLERRM);
                  RETURN NULL;
            END;
         END IF;
      --)
      EXCEPTION
         WHEN OTHERS
         THEN
            printout ('TWE:AR:> AR GET Location ERROR');
            printout ('TWE:AR:> REV not found, get REC Account');

            BEGIN
               SELECT code_combination_id
                 INTO l_ccid
                 FROM ra_cust_trx_line_gl_dist
                -- 4_1_08:perf: use this instead of _v view
               WHERE  account_class = 'REC'
                  AND customer_trx_id = p_cus_trx_id
                  AND ROWNUM = 1;

               printout (   'TWE:AR:> REC ccid=:'
                         || l_ccid
                         || ':');
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  --           PrintOut('TWE:AR:(E)-get_Location:NO_DATA_FOUND');
                  printout ('TWE:AR:>2:RETURN Location NULL <--');
                  RETURN NULL;
               WHEN OTHERS
               THEN
                  printout (   'TWE:AR:(E)-2:get_Location:'
                            || SQLERRM);
                  RETURN NULL;
            END;
      END;

      printout (   'TWE:AR:>l_ccid:'
                || l_ccid
                || ':');
      printout (   'TWE:AR:>:CharofAcc:'
              --  || arp_tax.sysinfo.chart_of_accounts_id         -- Commented RETORFITR12
                   || ZX_PRODUCT_INTEGRATION_PKG.sysinfo.chart_of_accounts_id -- Added RETORFITR12
                || ':');

      IF NOT fnd_flex_keyval.validate_ccid
                                   ('SQLGL'
                                   ,'GL#'
                                   --,arp_tax.sysinfo.chart_of_accounts_id        -- Commented RETORFITR12
                                   , ZX_PRODUCT_INTEGRATION_PKG.sysinfo.chart_of_accounts_id -- Added RETORFITR12
                                   ,l_ccid
                                   )
      THEN
         printout ('TWE:AR:>3:RETURN Location Segment NULL <--');
         RETURN NULL;
      END IF;

      l_location                 := fnd_flex_keyval.segment_value (4);
      RETURN l_location;
   END get_location;
END taxpkg_10_param;
/