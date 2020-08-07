 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Body XX_WSH_SHIPPING_LABEL_PKG 
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE
create or replace PACKAGE BODY XX_WSH_SHIPPING_LABEL_PKG AS
 -- +============================================================================================+
 -- |                  Office Depot - Project Simplify                                           |
 -- |                       WIPRO Technologies                                                   |
 -- +============================================================================================+
 -- | Name :        Shipping Label                                                               |
 -- | Rice ID:      E1292                                                                        |
 -- | Description : This package aids printing of Shipping Labels. It generates Shipping Label   |
 -- |               data in a format recognisable to Intermec Printer. The label data is         |
 -- |               generated for Internal Sales Orders. When a sales order is confirmed for     |
 -- |               shipment, the labels are printed. The output of this program is in IPL       |
 -- |               language which is sent to the Intermec Printer for printing. A concurrent    | 
 -- |               program with host execuatble is submitted from this package to direct the    |
 -- |               output to the printer.                                                       |
 -- |Change Record:                                                                              |
 -- |===============                                                                             |
 -- |Version  Date          Author              Remarks                                          |
 -- |=======  ==========   =============        =================================================|
 -- |1.0      25-SEP-2007  Hemalatha.S          Initial version                                  |
 -- |                      Wipro Technologies                                                    |
 -- |1.1      01-OCT-2007  Radhika Raman        Added Printer Logic                              |
 -- |1.2      18-OCT-2007  Radhika Raman        Defect 2453, Added logic to print blank box      |
 -- |                                           numbers when reprint                             |                     
 -- |1.3      22-OCT-2007  Radhika Raman        CR - 264. changed fetching of THRU location and  |
 -- |                                           lane info bolded.                                | 
 -- |1.4      02-APR-2007  Radhika Raman        Added org based condition to query as we         |
 -- |                                           associate one internal location to 2 sites for   | 
 -- |                                           inter-operating unit shipping - defect 5332      |
 -- |1.5      05-MAY-2008  Subbu Pillai         Added Org based Query for                        |
 -- |                                           po_location_associations_all table - defect 6701 |
 -- |1.6      12-MAY-2008  Radhika Raman        Changing for the scenario where X-DOC information|
 -- |                                           is not available. -- defect 6701                 |
 -- |1.7      19-MAY-2008  Radhika Raman        EXPENSE organizations do not have STORE or       |
 -- |                                           WAREHOUSE attributes, so KFF in a DFF does not   |
 -- |                                           have a record for this organziation.This scenario|
 -- |                                           is addressed in this defect - 7202               | 
 -- |1.8      15-SEP-2010 Bapuji Nanapaneni     Modifed code to print V27 INV ORG address instead|
 -- |                                           of xdoc and pass null value to shipment line     |
 -- |1.9      17-JUN-2013 Bapuji Nanapaneni     Added Rice ID                                    |
 -- |1.10     25-Feb-2016 Paddy Sanjeevi        Defect 36966                                     |
 -- |1.11     06-JAN-2017 Avinash Baddam        Changes for Defect 38317                         |
 -- |1.12     28-MAR-2017 Avinash Baddam        Changes for Defect 41357                         |
 -- |1.13     03-APR-2017 Suresh Ponnambalam    Changes for Defect 41357                         |
 -- |1.14     03-APR-2017 Avinash Baddam        Added del_detail_id to the tracking table        |
-- |1.15     01-OCT-2019 Venkateshwar Panduga  Added Walet location/Certification logic          |
 -- +============================================================================================+
 -- +===================================================================+
 -- | Name        : LABELS_DATA                                         |
 -- |                                                                   |
 -- | Description : This procedure will be the executable of Concurrent |
 -- |               Program " OD: WSH Shipping Label Data-Intermec "    |
 -- |                                                                   |
 -- | Parameters  :  x_error_buff, x_ret_code,p_trip_id                 |
 -- |               ,p_trip_stop_id,p_departure_date_low                |
 -- |               ,p_departure_date_high,p_freight_code               |
 -- |               ,p_delivery_id,p_container_id,p_organization_id,    |
 -- |                p_printer_name                                     |
 -- +===================================================================+
-- global variables declaration
g_def_debug    VARCHAR2(1)  :='N';
g_debug_lvl    VARCHAR2(1);

/* Below variable is added for V1.15 */
gc_package_name  VARCHAR2(30) := 'XX_WSH_SHIPPING_LABEL_PKG';

/* Below Procedure is added for V1.15 */
 PROCEDURE get_translation_info(p_translation_name  IN            xx_fin_translatedefinition.translation_name%TYPE,
                                 px_translation_info IN OUT NOCOPY xx_fin_translatevalues%ROWTYPE)
  IS

    lc_procedure_name  CONSTANT VARCHAR2(61) := gc_package_name || '.' || 'get_translation_info';

    lr_translation_info xx_fin_translatevalues%ROWTYPE;

  BEGIN

    SELECT  vals.*
    INTO    lr_translation_info
    FROM    xx_fin_translatevalues vals,
            xx_fin_translatedefinition defn
    WHERE   defn.translate_id                        = vals.translate_id
    AND     defn.translation_name                    = p_translation_name
    AND     NVL(vals.source_value1, '-X')            = NVL(px_translation_info.source_value1, NVL(vals.source_value1, '-X'))
    AND     NVL(vals.source_value2, '-X')            = NVL(px_translation_info.source_value2, NVL(vals.source_value2, '-X'))
    AND     NVL(vals.source_value3, '-X')            = NVL(px_translation_info.source_value3, NVL(vals.source_value3, '-X'))
    AND     NVL(vals.source_value4, '-X')            = NVL(px_translation_info.source_value4, NVL(vals.source_value4, '-X'))
    AND     NVL(vals.source_value5, '-X')            = NVL(px_translation_info.source_value5, NVL(vals.source_value5, '-X'))
    AND     NVL(vals.source_value6, '-X')            = NVL(px_translation_info.source_value6, NVL(vals.source_value6, '-X'))
    AND     NVL(vals.source_value7, '-X')            = NVL(px_translation_info.source_value7, NVL(vals.source_value7, '-X'))
    AND     NVL(vals.source_value8, '-X')            = NVL(px_translation_info.source_value8, NVL(vals.source_value8, '-X'))
    AND     SYSDATE BETWEEN vals.start_date_active AND NVL(vals.end_date_active, SYSDATE + 1)
    AND     SYSDATE BETWEEN defn.start_date_active AND NVL(defn.end_date_active, SYSDATE + 1)
    AND     vals.enabled_flag                        = 'Y'
    AND     defn.enabled_flag                        = 'Y';

    px_translation_info := lr_translation_info;
    
      
     FND_FILE.PUT_LINE (FND_FILE.LOG,'RESULT target_value1: ' || px_translation_info.target_value1);

    EXCEPTION
    WHEN OTHERS
    THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception while getting WALLET_LOCATION -'|| substr(sqlerrm,1,250));
      RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END get_translation_info;
  
  ----- End for V1.15
   PROCEDURE LABEL_OUTLINE;

   PROCEDURE LABELS_DATA (
                           x_error_buff           OUT      VARCHAR2
                          ,x_ret_code             OUT      NUMBER
                          ,p_trip_id              IN       VARCHAR2
                          ,p_trip_stop_id         IN       VARCHAR2
                          ,p_departure_date_low   IN       DATE
                          ,p_departure_date_high  IN       DATE
                          ,p_freight_code         IN       VARCHAR2
                          ,p_organization_id      IN       VARCHAR2
                          ,p_delivery_id          IN       NUMBER
                          ,p_container_id         IN       VARCHAR2
                          ,p_reprint              IN       VARCHAR2
                         )
   AS

   lc_location_code           hr_locations.location_code%TYPE;
   lc_ship_to_address_1       VARCHAR(1000);
   lc_ship_to_address_2       VARCHAR(1000);
   ln_organization_id         po_location_associations_all.organization_id%TYPE;
   lc_thru_location_code      hr_locations.location_code%TYPE;
   lc_address_line_1          VARCHAR(1000);
   lc_address_line_2          VARCHAR(1000);
   lc_telephone_number_1      hr_locations.telephone_number_1%TYPE;
   lc_telephone_number_2      hr_locations.telephone_number_2%TYPE;
   ln_csr_count               NUMBER;
   lc_csr_count               VARCHAR2(10);
   ln_rec_count               NUMBER;
   lc_rec_count               VARCHAR2(10);
   lc_ship_from_location_code VARCHAR2(1000);
   lc_shipping_lane           VARCHAR2(1000);
   lc_container_name          VARCHAR2(1000);
   lc_ship_to_location_id     NUMBER;
   ln_customer_id             NUMBER;
   lc_query_val               VARCHAR2(2000);
   ld_departure_date          DATE;
   ln_conc_req_id             NUMBER;
   ln_req_id                  NUMBER;
   lc_error_loc               VARCHAR2(1000);
   lc_loc_err_msg             VARCHAR2(1000);
   ln_conc_pgm_id             NUMBER;
   ln_from_organization_id    NUMBER;
   ln_count                   NUMBER :=0;
   lc_subinventory            VARCHAR2(100);
   lc_printer_name            wsh_report_printers.printer_name%TYPE;
   NO_PRINTER                 EXCEPTION;
   lc_xdoc                    VARCHAR2(10);
   ln_kff_unique_id           NUMBER;
   lc_inv_org_code            mtl_parameters.organization_code%TYPE;   -- Added by NB
   
   --Defect#38317 
   ln_ship_from_location_id     NUMBER;
   lc_ship_date               VARCHAR2(20); 
   ln_source_header_id        NUMBER;       
   lc_requisition_number      VARCHAR2(20);
   ld_order_dt		      DATE;
   ln_internal_sales_order    NUMBER;        
   ln_login     	      NUMBER                :=  FND_GLOBAL.LOGIN_ID;
   ln_user_id   	      NUMBER                :=  FND_GLOBAL.USER_ID;
   lc_trackingexists_flag     VARCHAR2(1)           := 'N';
   ln_ship_lbl_nbr            NUMBER;
   ln_tracking_id             NUMBER;
   ln_delivery_detail_id      NUMBER;
   lb_result                  BOOLEAN;
   lc_phase                   VARCHAR2 (50);
   lc_status                  VARCHAR2 (50);
   lc_dev_phase               VARCHAR2 (50);
   lc_dev_status              VARCHAR2 (50);
   lc_message                 VARCHAR2 (1000);
   lc_soap_request            VARCHAR2 (32500);
   lc_soap_respond            VARCHAR2 (32500);
   lr_http_request            UTL_HTTP.req;
   lr_http_response           UTL_HTTP.resp;
   lc_hosturl                 VARCHAR2 (2000);
   lc_username	              VARCHAR2(25) := NULL;
   lc_password	              VARCHAR2(25) := NULL;
   ln_consumer_transaction_id VARCHAR2(250);
   resp                       XMLTYPE;
   lc_resp_statuscode         VARCHAR2(500)  := null;
   lc_resp_statusdesc         VARCHAR2(2000) := null;
   insert_exception	      EXCEPTION;
   Invoke_exception           EXCEPTION;
   ---- Added for V1.15
   lt_translation_info            xx_fin_translatevalues%ROWTYPE;  ---- Added for V1.15
   lc_wallet_location             xx_fin_translatevalues.target_value1%TYPE;
   lc_wallet_password             xx_fin_translatevalues.target_value1%TYPE;
  --- End V1.15 
   CURSOR order_cur(p_order_header_id NUMBER) IS
      SELECT orig_sys_document_ref
	    ,order_number
            ,ordered_date
        FROM oe_order_headers_all 
       WHERE header_id = p_order_header_id; 
       
   CURSOR get_trackingid_cur(p_delivery_detail_id NUMBER) IS
      SELECT tracking_id
        FROM xx_wsh_ship_lbl_tracking 
       WHERE delivery_id = p_delivery_id
         AND trip_id = p_trip_id
         AND delivery_detail_id = p_delivery_detail_id;
       
   CURSOR get_service_params_cur IS
       SELECT  XFTV.source_value1, XFTV.target_value1
	   FROM   xx_fin_translatedefinition XFTD
	         ,xx_fin_translatevalues XFTV
	  WHERE   XFTD.translate_id = XFTV.translate_id
	    AND   XFTD.translation_name = 'OD_SHIP_OUTBOUND_SERVICE'
	    AND   SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
	    AND   SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
	    AND   XFTV.enabled_flag = 'Y'
            AND   XFTD.enabled_flag = 'Y';       
 
   TYPE ship_details_csr_type IS REF CURSOR;
   lcu_ship_details ship_details_csr_type;

   BEGIN
      --Changes for defect#41357
      lc_query_val := 'SELECT  hl.location_code '||
                             ',wdd.container_name' ||
                             ',wdd.ship_to_location_id '||
                             ',wdd.customer_id ' ||
                             ',wdd.organization_id '||
                             ',wdd.subinventory ' ||
                             ',mp.organization_code '||                                      -- Added by NB
                             ',TO_CHAR(WND.initial_pickup_date,''DD-MON-YY'') '||	     --Defect#38317
                             ',DECODE(wdd.source_code,''WSH'',(SELECT max(wd.source_header_id)
                                                                 FROM wsh_deliverables_v wd 
                                                                WHERE wd.parent_container_instance_id = wdd.delivery_detail_id),
                                      wdd.source_header_id) source_header_id '||             --Defect#41357                       
                             ',wdd.ship_from_location_id '||
                             ',wdd.delivery_detail_id '||
                        'FROM  wsh_delivery_assignments        WDA '||
                             ',wsh_delivery_details            WDD '||
                             ',wsh_new_deliveries              WND '||
                             ',hr_locations                    HL  '||
                             ',mtl_parameters                  MP  '||                       -- Added by NB
                        'WHERE wnd.delivery_id              = wda.delivery_id '||
                          'AND wdd.delivery_detail_id       = wda.delivery_detail_id '||
                          'AND NVL(wnd.shipment_direction,''O'') IN (''O'',''IO'') '||
                          'AND hl.location_id               = wdd.ship_from_location_id '||
                          'AND wdd.organization_id          = mp.organization_id '||         -- Added by NB
                          'AND wda.delivery_id              ='|| p_delivery_id;


      IF p_container_id IS NOT NULL THEN
         lc_query_val := lc_query_val||' AND WDD.delivery_detail_id = '||p_container_id;
      ELSE
         lc_query_val := lc_query_val||' AND WDA.parent_delivery_detail_id IS NULL';
      END IF;

      IF p_freight_code IS NOT NULL THEN
         lc_query_val := lc_query_val ||' AND WND.ship_method_code = ' || p_freight_code;
      END IF;

      IF p_organization_id IS NOT NULL THEN
         lc_query_val := lc_query_val ||' AND WND.organization_id = '||p_organization_id;
      END IF;

      IF p_trip_stop_id IS NOT NULL THEN
         lc_query_val := lc_query_val ||' AND WND.delivery_id IN (SELECT DISTINCT delivery_id
                                                                  FROM   wsh_delivery_legs
                                                                  WHERE  (pick_up_stop_id     = '|| p_trip_stop_id ||
                                                                         ' OR drop_off_stop_id = '|| p_trip_stop_id ||
                                                                ' ))';
      END IF;

      IF p_trip_id IS NOT NULL THEN
         lc_query_val := lc_query_val ||' AND WND.delivery_id IN (SELECT DISTINCT delivery_id
                                                                  FROM   wsh_delivery_legs WDL
                                                                         ,wsh_trip_stops   WTS
                                                                  WHERE  WDL.pick_up_stop_id = WTS.stop_id
                                                                  AND    WTS.trip_id         = ' || p_trip_id ||
                                                                ' )';
      END IF;

      IF p_departure_date_high IS NOT NULL THEN
         ld_departure_date := p_departure_date_high + (86399/86400);
      END IF;

      IF (p_departure_date_low IS NOT NULL
          OR p_departure_date_high IS NOT NULL) THEN

             IF p_departure_date_low IS NULL THEN
                lc_query_val := lc_query_val || ' AND WND.delivery_id IN (SELECT DISTINCT delivery_id
                                                                          FROM   wsh_delivery_legs
                                                                          WHERE  pick_up_stop_id IN (SELECT stop_id
                                                                                                     FROM   wsh_trip_stops
                                                                                                     WHERE  planned_departure_date <= '|| p_departure_date_high ||
                                                                                                   ' ))';
             ELSIF p_departure_date_high IS NULL THEN
                lc_query_val := lc_query_val|| ' AND WND.delivery_id IN (SELECT DISTINCT delivery_id
                                                                         FROM   wsh_delivery_legs
                                                                         WHERE  pick_up_stop_id IN (SELECT stop_id
                                                                                                    FROM   wsh_trip_stops
                                                                                                    WHERE  planned_departure_date >= ' || P_DEPARTURE_DATE_LOW ||
                                                                                                  ' ))';
             ELSE
                lc_query_val := lc_query_val|| ' AND WND.delivery_id IN (SELECT DISTINCT delivery_id
                                                                         FROM   wsh_delivery_legs
                                                                         WHERE  pick_up_stop_id IN (SELECT stop_id
                                                                                                    FROM   wsh_trip_stops
                                                                                                    WHERE  planned_departure_date BETWEEN '||
                                                                                                    p_departure_date_low || ' AND '|| p_departure_date_high ||
                                                                                                 '  ))';
             END IF;

      END IF;
      
      --Defect 38317
      lc_query_val := lc_query_val||' ORDER BY wdd.source_header_id';

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Query:: '||lc_query_val);
      FND_FILE.PUT_LINE (FND_FILE.LOG,'Reprint::'||p_reprint);

      -- -------------------------------------------------------
      -- Get web service values --Defect 38317
      -- -------------------------------------------------------
      FOR get_service_params_rec IN get_service_params_cur 
      LOOP
         IF get_service_params_rec.source_value1 = 'URL' THEN
    	    lc_hosturl := get_service_params_rec.target_value1;
         ELSIF get_service_params_rec.source_value1 = 'USERNAME' THEN
	    lc_username := get_service_params_rec.target_value1;
         ELSIF get_service_params_rec.source_value1 = 'PASSWORD' THEN
	    lc_password := xx_encrypt_decryption_toolkit.decrypt(get_service_params_rec.target_value1);
         END IF;
      END LOOP;

      -- To fetch the CURSOR count
      OPEN lcu_ship_details FOR lc_query_val;
      ln_csr_count:=0;
      LOOP
      FETCH lcu_ship_details INTO   lc_ship_from_location_code
                                      ,lc_container_name
                                      ,lc_ship_to_location_id
                                      ,ln_customer_id
                                      ,ln_from_organization_id
                                      ,lc_subinventory
                                      ,lc_inv_org_code           -- Added by NB
                                      ,lc_ship_date              --Defect#38317
                                      ,ln_source_header_id       --Defect#38317 
                                      ,ln_ship_from_location_id  --Defect#38317 
                                      ,ln_delivery_detail_id;    --Defect#38317 
      EXIT WHEN lcu_ship_details%NOTFOUND;                               
      ln_csr_count := ln_csr_count + 1;                                      
      END LOOP;
      
      IF (p_reprint = 'Y') THEN
        lc_csr_count:=' ';
      ELSE
        lc_csr_count:=TO_CHAR(ln_csr_count);
      END IF;
      
      CLOSE lcu_ship_details;
      
      --  Open the cursor to display label
      OPEN lcu_ship_details FOR lc_query_val;
      
      ln_rec_count := 1;     

      LOOP
         FETCH lcu_ship_details INTO   lc_ship_from_location_code
                                      ,lc_container_name
                                      ,lc_ship_to_location_id
                                      ,ln_customer_id
                                      ,ln_from_organization_id
                                      ,lc_subinventory
                                      ,lc_inv_org_code           -- Added by NB
                                      ,lc_ship_date              --Defect#38317
                                      ,ln_source_header_id       --Defect#38317 
                                      ,ln_ship_from_location_id  --Defect#38317 
                                      ,ln_delivery_detail_id;    --Defect#38317

         EXIT WHEN lcu_ship_details%NOTFOUND;
         
         IF (p_reprint = 'Y') THEN
            lc_rec_count:=' ';
         ELSE
            lc_rec_count:=TO_CHAR(ln_rec_count);
         END IF;

         BEGIN
            lc_error_loc := 'Fetching To Organization Details';
            SELECT  HL.location_code
                    ,SUBSTR(HL.address_line_1||' '||HL.address_line_2||' '||HL.address_line_3,1,44)
                    ,SUBSTR(HL.town_or_city||','||decode(HL.region_2, NULL,HL.region_1,HL.region_2)||','||decode(HL.country,'CA','CANADA',HL.country)||','||HL.postal_code,1,44)
                    ,PLAA.organization_id
                    ,HL.attribute6
            INTO     lc_location_code
                    ,lc_ship_to_address_1
                    ,lc_ship_to_address_2
                    ,ln_organization_id
                    ,lc_shipping_lane
            FROM     hz_cust_accounts             HCA
                    ,hz_party_sites               HPS
                    ,hz_cust_acct_sites_all       HCASA
                    ,hz_cust_site_uses_all        HCSUA
                    ,po_location_associations_all PLAA
                    ,hr_locations                 HL
            WHERE   HPS.party_id                = HCA.party_id
            AND     HCASA.party_site_id         = HPS.party_site_id
            AND     HCSUA.cust_acct_site_id     = HCASA.cust_acct_site_id
            AND     PLAA.site_use_id            = HCSUA.site_use_id
            AND     HL.location_id              = PLAA.location_id
            AND     HCSUA.site_use_code         = 'SHIP_TO'
            AND     HCA.cust_account_id         = ln_customer_id
            AND     HPS.location_id             = lc_ship_to_location_id
            AND     HCASA.cust_account_id       = ln_customer_id       -- Defect 5332
	    AND     HCASA.org_id                = FND_PROFILE.VALUE('ORG_ID')  -- Defect 5332
            AND     PLAA.org_id			= FND_PROFILE.VALUE('ORG_ID'); --Defect 6701
            
            -- Added logic by NB to send Null value for shipping line if inv_org is V27.
	    IF lc_inv_org_code = 'V27' THEN
	        lc_shipping_lane := NULL;
            END IF;
         
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            lc_loc_err_msg :=  SQLERRM;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR  (p_program_type            => 'CONCURRENT PROGRAM'
                                            ,p_program_name            => 'OD: WSH Shipping Label Data-Intermec'
                                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                            ,p_module_name             => 'WSH'
                                            ,p_error_location          => lc_error_loc
                                            ,p_error_message           => 'NO DATA FOUND::'||lc_loc_err_msg
                                            ,p_error_message_severity  => 'Major'
                                            ,p_object_type             => 'Extension'
                                            ,p_object_id               => 'E1292'
                                           );
         WHEN OTHERS THEN
            lc_loc_err_msg :=  SQLERRM;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR  (p_program_type            => 'CONCURRENT PROGRAM'
                                            ,p_program_name            => 'OD: WSH Shipping Label Data-Intermec'
                                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                            ,p_module_name             => 'WSH'
                                            ,p_error_location          => lc_error_loc
                                            ,p_error_message           => 'ERROR::'||lc_loc_err_msg
                                            ,p_error_message_severity  => 'Major'
                                            ,p_object_type             => 'Extension'
                                            ,p_object_id               => 'E1292'
                                           );
         END;
         
         BEGIN
            lc_error_loc := 'Fetching Thru Organization Details';
            /* SELECT HL.location_code
                   ,SUBSTR(HL.address_line_1||' '||HL.address_line_2||' '||HL.address_line_3,1,44)
                   ,SUBSTR(HL.town_or_city||','||HL.region_2||','||HL.country||','||HL.postal_code,1,44)
                   ,HL.telephone_number_1
                   ,HL.telephone_number_2
            INTO   lc_thru_location_code
                   ,lc_address_line_1
                   ,lc_address_line_2
                   ,lc_telephone_number_1
                   ,lc_telephone_number_2
            FROM   mtl_parameters                MP
                   ,xx_inv_org_loc_rms_attribute IOLRA
                   ,hr_locations                 HL
            WHERE  IOLRA.combination_id        = TO_NUMBER(MP.attribute6)
            AND    HL.location_code LIKE LPAD(default_wh_sw,6,'0')||'%'
            AND    MP.organization_id          = ln_organization_id;  */ -- commented for defect 6701
            
            /*SELECT IOLRA.default_wh_sw
            INTO   lc_xdoc
            FROM   mtl_parameters                MP
                   ,xx_inv_org_loc_rms_attribute IOLRA
            WHERE  IOLRA.combination_id        = TO_NUMBER(MP.attribute6)
            AND    MP.organization_id          = ln_organization_id;*/ -- commented for defect 7202
            
            SELECT TO_NUMBER(MP.attribute6)
            INTO   ln_kff_unique_id
            FROM   mtl_parameters        MP
            WHERE  MP.organization_id     = ln_organization_id; -- defect 7202
            
            IF ln_kff_unique_id IS NOT NULL THEN -- defect 7202
               -- If organization does not have STORE or WAREHOUSE attributes
              SELECT IOLRA.default_wh_sw 
              INTO lc_xdoc
              FROM  XX_INV_ORG_LOC_RMS_ATTRIBUTE IOLRA
              WHERE IOLRA.combination_id = ln_kff_unique_id;
            
              IF lc_xdoc IS NOT NULL THEN  -- Defect 6701
                 -- added IF condn for the scenario --> X-DOC may not be available for all locations.
                 -- Only if X-DOC ia available we need to fetch the X-DOC details
                 -- Added By NB to print SHIP FROM ORG ADDRESS for INV ORG V27 and for remaning pringt xdoc.
                 IF lc_inv_org_code = 'V27' THEN
                     SELECT HL.location_code
		          , SUBSTR(HL.address_line_1||' '||HL.address_line_2||' '||HL.address_line_3,1,44)
		          , SUBSTR(HL.town_or_city||','||decode(HL.region_2, NULL,HL.region_1,HL.region_2)||','||decode(HL.country,'CA','CANADA',HL.country)||','||HL.postal_code,1,44)
		          , HL.telephone_number_1
		          , HL.telephone_number_2
		       INTO lc_thru_location_code
		          , lc_address_line_1
		          , lc_address_line_2
		          , lc_telephone_number_1
		          , lc_telephone_number_2
		       FROM hr_locations                 HL
		          , hr_all_organization_units    HO
		          , mtl_parameters               MP
		      WHERE mp.organization_code = lc_inv_org_code
		        AND mp.organization_id   = ho.organization_id
                        AND ho.location_id       = hl.location_id;
                 ELSE
                     SELECT HL.location_code
		          , SUBSTR(HL.address_line_1||' '||HL.address_line_2||' '||HL.address_line_3,1,44)
		          , SUBSTR(HL.town_or_city||','||decode(HL.region_2, NULL,HL.region_1,HL.region_2)||','||decode(HL.country,'CA','CANADA',HL.country)||','||HL.postal_code,1,44)
		          , HL.telephone_number_1
		          , HL.telephone_number_2
		       INTO lc_thru_location_code
		          , lc_address_line_1
		          , lc_address_line_2
		          , lc_telephone_number_1
		          , lc_telephone_number_2
		       FROM hr_locations                 HL
                      WHERE HL.location_code LIKE LPAD(lc_xdoc,6,'0')||'%'; 
                 
                 END IF;
              END IF; -- Defect 6701  
              
            END IF;  
            
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            lc_loc_err_msg :=  SQLERRM;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (p_program_type            => 'CONCURRENT PROGRAM'
                                            ,p_program_name            => 'OD: WSH Shipping Label Data-Intermec'
                                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                            ,p_module_name             => 'WSH'
                                            ,p_error_location          => lc_error_loc
                                            ,p_error_message_count     => 1
                                            ,p_error_message_code      => 'E'
                                            ,p_error_message           => 'NO DATA FOUND'||lc_loc_err_msg
                                            ,p_error_message_severity  => 'Major'
                                            ,p_notify_flag             => 'N'
                                            ,p_object_type             => 'XX_SHIPPING_LABEL_PKG'
                                           );
         WHEN OTHERS THEN
            lc_loc_err_msg :=  SQLERRM;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (p_program_type            => 'CONCURRENT PROGRAM'
                                            ,p_program_name            => 'OD: WSH Shipping Label Data-Intermec'
                                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                            ,p_module_name             => 'WSH'
                                            ,p_error_location          => lc_error_loc
                                            ,p_error_message_count     => 1
                                            ,p_error_message_code      => 'E'
                                            ,p_error_message           => 'ERRORED OUT'||lc_loc_err_msg
                                            ,p_error_message_severity  => 'Major'
                                            ,p_notify_flag             => 'N'
                                            ,p_object_type             => 'XX_SHIPPING_LABEL_PKG'
                                           );
         END;
         
         --Defect#38317
         IF ln_source_header_id IS NOT NULL THEN
            OPEN order_cur(ln_source_header_id);
            FETCH order_cur INTO lc_requisition_number
   	       		        ,ln_internal_sales_order
	                        ,ld_order_dt;
            CLOSE order_cur;
         END IF;            
         
         --check if TrackingId already exists
         ln_ship_lbl_nbr := NULL;
         lc_trackingexists_flag := 'N';
         OPEN get_trackingid_cur(ln_delivery_detail_id);    
         FETCH get_trackingid_cur INTO ln_ship_lbl_nbr;
         CLOSE get_trackingid_cur;
         IF ln_ship_lbl_nbr IS NULL THEN
            SELECT xx_wsh_ship_lbl_nbr_s.nextval
              INTO ln_ship_lbl_nbr 
              FROM dual;
         ELSE
            lc_trackingexists_flag := 'Y';
         END IF;
         
         -- Caling the procedure LABEL_OUTLINE
         LABEL_OUTLINE;
         
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H0;o141,38;f0;c19;h3;w3;d3,*** Office Depot Internal Supplies ***;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>D1;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H1;o22,89;f0;c25;h14;w15;d3,FROM:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H2;o19,133;f0;c25;h14;w15;d3,THRU:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H3;o128,88;f0;c25;h14;w15;d3,Inv Loc ID: ;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H4;o357,89;f0;c25;h14;w15;d3,'||lc_ship_from_location_code||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H5;o130,124;f0;c25;h14;w15;d3,Loc ID:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H6;o357,125;f0;c25;h14;w15;d3,'||lc_thru_location_code||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H7;o359,160;f0;c25;h14;w15;d3,'||lc_address_line_1||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H8;o359,195;f0;c25;h14;w15;d3,'||lc_address_line_2||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H9;o133,241;f0;c25;h14;w15;d3,Phone:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H10;o361,243;f0;c25;h14;w15;d3,'||lc_telephone_number_1||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H11;o134,279;f0;c25;h14;w15;d3,Fax:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H12;o360,277;f0;c25;h14;w15;d3,'||lc_telephone_number_2||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>W13;o119,86;h307;l1032;w1;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>W14;o123,436;h301;l1026;w1;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H15;o134,447;f0;c25;h14;w15;d3,Loc ID:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H16;o359,449;f0;c25;h14;w15;d3,'||lc_location_code||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H17;o356,481;f0;c25;h14;w15;d3,'||lc_ship_to_address_1||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H18;o361,513;f0;c25;h14;w15;d3,'||lc_ship_to_address_2||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H19;o22,444;f0;c25;h14;w15;d3,To: ;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H20;o925,264;f0;c33;h2;w2;d3,LANE;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H21;o890,320;f0;c33;h2;w2;d3,'||lc_shipping_lane||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H22;o142,590;f0;c19;h3;w3;d3,ContainerID:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H23;o449,590;f0;c19;h3;w3;d3,'||lc_container_name||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H24;o142,663;f0;c19;h3;w3;d3,BOX:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H25;o509,667;f0;c19;h3;w3;d3,OF;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H26;o369,665;f0;c19;h3;w3;d3,'||lc_rec_count||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H27;o672,665;f0;c19;h3;w3;d3,'||lc_csr_count||';<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>U28;o327,697;f0;c0;w1;h1;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>U29;o650,695;f0;c1;w1;h1;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H30;o131,162;f0;c25;h14;w15;d3,Address:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H31;o132,485;f0;c25;h14;w15;d3,Address:;<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>H32;o134,317;f0;c25;h14;w15;d3,Track ID:;<ETX>');         
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>B33;o360,317;f0;c6;h50;w1;i1;d0,30;<ETX>'); --Defect#38317
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>R<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><ESC>E*<CAN><ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><ESC>F33<LF>'||to_char(ln_ship_lbl_nbr)||'<ETX>');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><RS>1<US>1<ETB><ETX>');

	 ln_rec_count := ln_rec_count + 1; 
	 
	 IF lc_trackingexists_flag = 'N' THEN  --Check if tracking already exists
         -- -------------------------------------------------------
         -- Insert into stage table  --Defect 38317
         -- -------------------------------------------------------	 
         BEGIN
            BEGIN
               lc_error_loc := 'Insert into tracking table';
	       ln_tracking_id := ln_ship_lbl_nbr;
	       IF lc_container_name IS NULL THEN
	          lc_container_name := '-1';
	       END IF;
	       IF lc_ship_date IS NULL THEN
	          lc_ship_date := TO_CHAR(fnd_api.g_miss_date,'DD-MON-RR');
               END IF;	          
               
               INSERT INTO XX_WSH_SHIP_LBL_TRACKING(TRACKING_ID
          			         ,ORDER_NBR
          			         ,ORDER_DT
					 ,DELIVERY_ID
					 ,DELIVERY_DT
					 ,TRIP_ID
					 ,CONTAINER_ID
					 ,LANE_NBR
					 ,SRC_LOC_ID
					 ,LOC_ID
					 ,DELIVERY_DETAIL_ID
					 ,STATUSCODE
					 ,STATUSDESC
					 ,CREATED_BY
					 ,CREATION_DATE
					 ,LAST_UPDATED_BY
					 ,LAST_UPDATE_DATE
					 ,LAST_UPDATE_LOGIN)
				 VALUES (ln_tracking_id 
				 	 ,ln_internal_sales_order
				 	 ,ld_order_dt
				         ,p_delivery_id
				         ,TO_DATE(lc_ship_date,'DD-MON-YY')
				         ,p_trip_id
				         ,lc_container_name
				         ,lc_shipping_lane
				         ,ln_ship_from_location_id 
				         ,lc_ship_to_location_id
				         ,ln_delivery_detail_id
				         ,NULL
				         ,NULL
				         ,ln_user_id
				         ,sysdate
				         ,ln_user_id
				         ,sysdate
				         ,ln_login);
             EXCEPTION
             WHEN OTHERS THEN
                lc_loc_err_msg :=  SQLERRM;
                FND_FILE.PUT_LINE (FND_FILE.LOG,'Exception while insert-'|| substr(sqlerrm,1,250));
                RAISE insert_exception;
             END;	
          
             -- -------------------------------------------------------
             -- Invoke outbound web service --Defect 38317
             -- -------------------------------------------------------			         
   	     ln_consumer_transaction_id := 'EBIZ'||TO_CHAR(ln_tracking_id);
		    
             lc_soap_request :='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
		    xmlns:tran="http://www.officedepot.com/model/transaction" 
		    xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		    xmlns:ord="http://eai.officedepot.com/model/Order">
				 <soapenv:Header/>
				 <soapenv:Body>
				   <non:noneTradeShipmentTrackingRequest>
				   <tran:transactionHeader>
				       <tran:consumer>
					   <tran:consumerName>EBIZ</tran:consumerName>
					   <tran:consumerTransactionID>'||ln_consumer_transaction_id||'</tran:consumerTransactionID>
					</tran:consumer>
				    </tran:transactionHeader>
				   <non:trackingNumber>'||to_char(ln_tracking_id)||'</non:trackingNumber>
				   <non:locationId>'||SUBSTR(lc_location_code,1,6)||'</non:locationId>
				   <non:orderDate>'||TO_CHAR(ld_order_dt,'YYYY-MM-DD')||'</non:orderDate>
				   <non:orderHeader>
				       <ord:orderNumber>'||TO_CHAR(ln_internal_sales_order)||'</ord:orderNumber>
				    </non:orderHeader>
				    <non:deliveryDate>'||TO_CHAR(TO_DATE(lc_ship_date,'DD-MON-YY'),'RRRR-MM-DD')||'</non:deliveryDate>
				   <non:containerId>'||lc_container_name||'</non:containerId>
				   <non:laneNumber>'||lc_shipping_lane||'</non:laneNumber>
				   <non:deliveryId>'||TO_CHAR(p_delivery_id)||'</non:deliveryId>
				  </non:noneTradeShipmentTrackingRequest>
				 </soapenv:Body>
				</soapenv:Envelope>';
				
             FND_FILE.PUT_LINE (FND_FILE.LOG,'Request Message:'|| lc_soap_request);
-----/*   Below code is added for V1.15 
  /***********************
   * Get wallet information
   ***********************/
                 
           lt_translation_info := NULL;
         
           lt_translation_info.source_value1 := 'WALLET_LOCATION';
         
           get_translation_info(p_translation_name  => 'XX_FIN_IREC_TOKEN_PARAMS',
                                px_translation_info => lt_translation_info);
                                
           lc_wallet_location  := lt_translation_info.target_value1;
           lc_wallet_password  := lt_translation_info.target_value2;
            IF lc_wallet_location IS NOT NULL
            THEN

              UTL_HTTP.SET_WALLET(lc_wallet_location, lc_wallet_password);
			  
            END IF;
			
            UTL_HTTP.set_response_error_check(FALSE);
---- END V1.15             
	     lr_http_request :=  UTL_HTTP.begin_request (lc_hosturl, 'POST', 'HTTP/1.1');

	     
	     IF lc_username IS NOT NULL THEN
   	        UTL_HTTP.set_authentication(lr_http_request,lc_username,lc_password);
	     END IF;
	            
	     UTL_HTTP.set_header (lr_http_request, 'Content-Type', 'text/xml');
	            
	     -- since we are dealing with plain text in XML documents
	     UTL_HTTP.set_header(lr_http_request,'Content-Length',LENGTH (lc_soap_request));
	     UTL_HTTP.set_header(lr_http_request, 'SOAPAction', '');
	     -- required to specify this is a SOAP communication
	     UTL_HTTP.write_text(lr_http_request, lc_soap_request);
	     lr_http_response := UTL_HTTP.get_response (lr_http_request);
	     UTL_HTTP.read_text (lr_http_response, lc_soap_respond);
	            
	     FND_FILE.PUT_LINE (FND_FILE.LOG,'Response Message:'||lc_soap_respond);
	            
	     UTL_HTTP.end_response(lr_http_response);
	     resp := XMLTYPE.createxml (lc_soap_respond);

             lc_resp_statuscode := null;
             lc_resp_statusdesc := null;
             /* Check if invoke is success */
             IF (lr_http_response.status_code = 200)
	     THEN
		BEGIN
		   SELECT EXTRACTVALUE(resp,'/soapenv:Envelope/soapenv:Body/non:noneTradeShipmentTrackingResponse/non:status/odc:statusCode',
		         'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		          xmlns:odc="http://eai.officedepot.com/model/ODCommon"'),
		          SUBSTR(EXTRACTVALUE(resp,'/soapenv:Envelope/soapenv:Body/non:noneTradeShipmentTrackingResponse/non:status/odc:statusDescription',
		         'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		          xmlns:odc="http://eai.officedepot.com/model/ODCommon"'),1,2000)
		     INTO lc_resp_statuscode,lc_resp_statusdesc
		     FROM dual; 
		          
		     --check statuscode if response from service is fault message
		     IF lc_resp_statuscode IS NULL THEN
		        lc_resp_statuscode := '-2';
		        lc_resp_statusdesc := SUBSTR('statuscode not found(fault message)'||lc_soap_respond,1,2000);
                     END IF;
 	        EXCEPTION
		WHEN others THEN
		   lc_resp_statuscode := '-2';
		   lc_resp_statusdesc := SUBSTR('Error occured while deriving status code from response message'||SUBSTR(sqlerrm,1,250)||lc_soap_respond,1,2000);
		END;
		
		UPDATE xx_wsh_ship_lbl_tracking
		   SET statuscode = lc_resp_statuscode --need to confirm
		      ,statusdesc = lc_resp_statusdesc
		      ,last_updated_by = ln_user_id
		      ,last_update_date = sysdate                       
		 WHERE tracking_id = ln_tracking_id;
		 
             ELSE --If invoke is not success
	        lc_resp_statuscode := '-2';
	        lc_resp_statusdesc := SUBSTR('Message Code:'||to_char(lr_http_response.status_code)||' Reason Phrase:'||lr_http_response.reason_phrase,1,2000);
	        RAISE invoke_exception;
	     END IF;
	     
	     FND_FILE.PUT_LINE (FND_FILE.LOG,'respstatuscode:'|| lc_resp_statuscode);
	     FND_FILE.PUT_LINE (FND_FILE.LOG,'respstatusdesc:'|| lc_resp_statusdesc);
	     
          EXCEPTION
          WHEN insert_exception THEN
	     XX_COM_ERROR_LOG_PUB.LOG_ERROR (p_program_type            => 'CONCURRENT PROGRAM'
					 ,p_program_name            => 'OD: WSH Shipping Label Data-Intermec'
					 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
					 ,p_module_name             => 'WSH'
					 ,p_error_location          => lc_error_loc
					 ,p_error_message_count     => 1
					 ,p_error_message_code      => 'E'
					 ,p_error_message           => 'ERRORED OUT'||lc_loc_err_msg
					 ,p_error_message_severity  => 'Major'
					 ,p_notify_flag             => 'N'
					 ,p_object_type             => 'XX_SHIPPING_LABEL_PKG');
          WHEN invoke_exception THEN
             UPDATE xx_wsh_ship_lbl_tracking
	        SET statuscode = lc_resp_statuscode 
	           ,statusdesc = lc_resp_statusdesc
	           ,last_updated_by = ln_user_id
	           ,last_update_date = sysdate                       
	      WHERE tracking_id = ln_tracking_id; 
	  WHEN others THEN
	     lc_resp_statuscode := '-2'; 
	     lc_resp_statusdesc := SUBSTR('WHEN others'||sqlerrm,1,2000);
	     UPDATE xx_wsh_ship_lbl_tracking
	        SET statuscode = lc_resp_statuscode 
	 	   ,statusdesc = lc_resp_statusdesc
		   ,last_updated_by = ln_user_id
		   ,last_update_date = sysdate                       
	      WHERE tracking_id = ln_tracking_id; 
          END;     
          END IF; --End check if tracking already exists
      END LOOP;

      CLOSE lcu_ship_details;
      
      COMMIT;
      
      -- Get the Concurrent program ID
      ln_conc_pgm_id := FND_GLOBAL.CONC_PROGRAM_ID;

      -- Get the appropriate printer

      BEGIN
         lc_error_loc:= 'Get count of printers associated to user';
         SELECT COUNT(printer_name)
         INTO   ln_count
         FROM   wsh_report_printers     WRP
         WHERE  concurrent_program_id = ln_conc_pgm_id
         AND    default_printer_flag  = 'Y'
         AND    enabled_flag          = 'Y'
         AND    level_type_id         = 10004
         AND    level_value_id        = FND_GLOBAL.USER_ID;

         IF ln_count > 0 THEN
            lc_error_loc:= 'Get printer associated to user';
            SELECT printer_name
            INTO   lc_printer_name
            FROM   wsh_report_printers     WRP
            WHERE  concurrent_program_id = ln_conc_pgm_id
            AND    default_printer_flag  = 'Y'
            AND    enabled_flag          = 'Y'
            AND    level_type_id         = 10004
            AND    level_value_id        = FND_GLOBAL.USER_ID;
         ELSE
            lc_error_loc:= 'Get count of printers associated to subinventory';
            SELECT COUNT(printer_name)
            INTO   ln_count
            FROM   wsh_report_printers    WRP
            WHERE  concurrent_program_id = ln_conc_pgm_id
            AND    default_printer_flag  = 'Y'
            AND    enabled_flag          = 'Y'
            AND    level_type_id         = 10006
            AND    organization_id       = ln_from_organization_id
            AND    subinventory          = lc_subinventory;

            IF ln_count > 0 THEN
               lc_error_loc:= 'Get printer associated to subinventory';
               SELECT printer_name
               INTO   lc_printer_name
               FROM   wsh_report_printers     WRP
               WHERE  concurrent_program_id = ln_conc_pgm_id
               AND    default_printer_flag  = 'Y'
               AND    enabled_flag          = 'Y'
               AND    level_type_id         = 10006
               AND    organization_id       = ln_from_organization_id
               AND    subinventory          = lc_subinventory;
            ELSE
               lc_error_loc:= 'Get count of printers associated to organization';
               SELECT COUNT(printer_name)
               INTO   ln_count
               FROM   wsh_report_printers     WRP
               WHERE  concurrent_program_id = ln_conc_pgm_id
               AND    default_printer_flag  = 'Y'
               AND    enabled_flag          = 'Y'
               AND    level_type_id         = 10008
               AND    level_value_id        = ln_from_organization_id;

               IF ln_count > 0 THEN
                  lc_error_loc:= 'Get printer associated to organization';
                  SELECT printer_name
                  INTO   lc_printer_name
                  FROM   wsh_report_printers     WRP
                  WHERE  concurrent_program_id = ln_conc_pgm_id
                  AND    default_printer_flag  = 'Y'
                  AND    enabled_flag          = 'Y'
                  AND    level_type_id         = 10008
                  AND    level_value_id        = ln_from_organization_id;
               ELSE
                  lc_error_loc:= 'Get count of printers associated to responsibility';
                  SELECT COUNT(printer_name)
                  INTO   ln_count
                  FROM   wsh_report_printers     WRP
                  WHERE  concurrent_program_id = ln_conc_pgm_id
                  AND    default_printer_flag  = 'Y'
                  AND    enabled_flag          = 'Y'
                  AND    level_type_id         = 10003
                  AND    level_value_id        = FND_GLOBAL.RESP_ID;

                  IF ln_count > 0 THEN
                     lc_error_loc:= 'Get printer associated to responsibility';
                     SELECT printer_name
                     INTO   lc_printer_name
                     FROM   wsh_report_printers     WRP
                     WHERE  concurrent_program_id = ln_conc_pgm_id
                     AND    default_printer_flag  = 'Y'
                     AND    enabled_flag          = 'Y'
                     AND    level_type_id         = 10003
                     AND    level_value_id        = FND_GLOBAL.RESP_ID;
                  ELSE
                     lc_error_loc:= 'Get count of printers associated to Application';
                     SELECT COUNT(printer_name)
                     INTO   ln_count
                     FROM   wsh_report_printers     WRP
                     WHERE  concurrent_program_id = ln_conc_pgm_id
                     AND    default_printer_flag  = 'Y'
                     AND    enabled_flag          = 'Y'
                     AND    level_type_id         = 10002
                     AND    level_value_id        = FND_GLOBAL.RESP_APPL_ID;

                     IF ln_count > 0 THEN
                        lc_error_loc:= 'Get printer associated to APPLICATION';
                        SELECT printer_name
                        INTO   lc_printer_name
                        FROM   wsh_report_printers     WRP
                        WHERE  concurrent_program_id = ln_conc_pgm_id
                        AND    default_printer_flag  = 'Y'
                        AND    enabled_flag          = 'Y'
                        AND    level_type_id         = 10002
                        AND    level_value_id        = FND_GLOBAL.RESP_APPL_ID;
                     ELSE
                        lc_error_loc:= 'Get count of printers associated to Site';
                        SELECT COUNT(printer_name)
                        INTO   ln_count
                        FROM   wsh_report_printers     WRP
                        WHERE  concurrent_program_id = ln_conc_pgm_id
                        AND    default_printer_flag  = 'Y'
                        AND    enabled_flag          = 'Y'
                        AND    level_type_id         = 10001;

                        IF ln_count > 0 THEN
                           lc_error_loc:= 'Get printer associated at Site level';
                           SELECT printer_name
                           INTO   lc_printer_name
                           FROM   wsh_report_printers     WRP
                           WHERE  concurrent_program_id = ln_conc_pgm_id
                           AND    default_printer_flag  = 'Y'
                           AND    enabled_flag          = 'Y'
                           AND    level_type_id         = 10001;
                        ELSE
                           RAISE NO_PRINTER;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            END IF;
         END IF;
      EXCEPTION
      WHEN NO_PRINTER THEN
         FND_MESSAGE.SET_NAME('XXFIN','XX_PO_0077_NO_PRINTER');
         lc_loc_err_msg := FND_MESSAGE.GET;
         FND_FILE.PUT_LINE (FND_FILE.LOG,lc_loc_err_msg);
         x_ret_code:=2; 
      WHEN OTHERS THEN
         lc_loc_err_msg :=  SQLERRM;
         XX_COM_ERROR_LOG_PUB.LOG_ERROR (p_program_type            => 'CONCURRENT PROGRAM'
                                         ,p_program_name            => 'OD: WSH Shipping Label Data-Intermec'
                                         ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                         ,p_module_name             => 'WSH'
                                         ,p_error_location          => lc_error_loc
                                         ,p_error_message_count     => 1
                                         ,p_error_message_code      => 'E'
                                         ,p_error_message           => 'ERROR:: '||lc_loc_err_msg
                                         ,p_error_message_severity  => 'Major'
                                         ,p_notify_flag             => 'N'
                                         ,p_object_type             => 'XX_SHIPPING_LABEL_PKG'
                                        );
         x_ret_code:=2;
      END;

      --Get the current concurrent request id
      ln_conc_req_id := FND_GLOBAL.CONC_REQUEST_ID;

      FND_FILE.PUT_LINE (FND_FILE.LOG,'Printer::'||lc_printer_name);

      --Call host concurrent program to print file
      IF lc_printer_name IS NOT NULL THEN
         ln_req_id := FND_REQUEST.SUBMIT_REQUEST(APPLICATION => 'XXFIN'
                                                 ,PROGRAM    => 'XXPOINTERMEC'
                                                 ,ARGUMENT1  => ln_conc_req_id
                                                 ,ARGUMENT2  => lc_printer_name
                                                );
         COMMIT;
      END IF;   

   END LABELS_DATA;


 -- +===================================================================+
 -- | Name        : LABEL_OUTLINE                                       |
 -- |                                                                   |
 -- | Description : This procedure is to print the outline of           |
 -- |               the Shipping Label Report.                          |
 -- |                                                                   |
 -- +===================================================================+

   PROCEDURE LABEL_OUTLINE AS
   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><ESC>C0<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><ESC>k<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>L1360<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>S30<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>d0<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>h0,0;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>l8<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>I3<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>F20<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>D0<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>t0<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>W880<ETX>');
--    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>g1,567<ETX>'); -- Defect 36966
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><SI>g0,180<ETX>'); -- Added for Defect 36966
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><ESC>P<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>G0;x108;y36;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u0,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u1,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u2,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u3,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u4,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u5,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u6,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u7,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u8,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u9,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u10,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u11,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u12,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u13,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u14,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u15,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u16,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u17,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u18,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u19,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u20,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u21,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u22,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u23,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u24,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u25,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u26,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u27,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u28,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u29,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u30,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u31,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u32,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u33,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u34,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u35,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u36,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u37,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u38,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u39,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u40,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u41,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u42,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u43,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u44,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u45,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u46,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u47,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u48,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u49,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u50,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u51,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u52,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u53,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u54,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u55,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u56,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u57,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u58,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u59,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u60,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u61,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u62,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u63,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u64,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u65,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u66,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u67,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u68,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u69,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u70,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u71,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u72,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u73,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u74,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u75,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u76,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u77,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u78,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u79,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u80,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u81,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u82,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u83,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u84,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u85,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u86,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u87,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u88,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u89,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u90,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u91,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u92,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u93,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u94,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u95,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u96,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u97,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u98,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u99,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u100,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u101,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u102,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u103,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u104,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u105,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u106,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u107,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>R<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><ESC>P<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>G1;x120;y36;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u0,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u1,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u2,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u3,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u4,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u5,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u6,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u7,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u8,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u9,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u10,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u11,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u12,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u13,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u14,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u15,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u16,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u17,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u18,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u19,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u20,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u21,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u22,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u23,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u24,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u25,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u26,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u27,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u28,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u29,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u30,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u31,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u32,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u33,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u34,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u35,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u36,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u37,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u38,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u39,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u40,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u41,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u42,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u43,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u44,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u45,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u46,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u47,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u48,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u49,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u50,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u51,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u52,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u53,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u54,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u55,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u56,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u57,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u58,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u59,B@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u60,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u61,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u62,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u63,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u64,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u65,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u66,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u67,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u68,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u69,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u70,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u71,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u72,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u73,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u74,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u75,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u76,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u77,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u78,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u79,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u80,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u81,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u82,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u83,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u84,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u85,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u86,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u87,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u88,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u89,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u90,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u91,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u92,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u93,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u94,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u95,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u96,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u97,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u98,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u99,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u100,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u101,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u102,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u103,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u104,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u105,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u106,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u107,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u108,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u109,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u110,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u111,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u112,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u113,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u114,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u115,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u116,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u117,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u118,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>u119,A@@@@@;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>R<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX><ESC>P<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>E*;F*;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>L1;<ETX>');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<STX>D0;<ETX>');

   END LABEL_OUTLINE;

   --Defect 38317 Load Non-Trade Order Tracking Data
   PROCEDURE LOAD_TRACKING_DATA(
                         x_error_buff           OUT      VARCHAR2
                        ,x_ret_code             OUT      NUMBER
                        ,p_filename		IN	 VARCHAR2
                        )
   AS
      l_filehandle       UTL_FILE.FILE_TYPE;
      lc_filedir         VARCHAR2(30) := 'XXFIN_INBOUND_NONTRADE';
      lc_filename	 VARCHAR2(200);
      lb_file_exist 	 BOOLEAN;
      ln_size            NUMBER;
      ln_block_size      NUMBER;
      lc_dest_file_name  VARCHAR2(200);
      lc_newline         VARCHAR2(4000);  
      l_max_linesize     BINARY_INTEGER  := 32767;
      ln_user_id  	 NUMBER := fnd_global.user_id;
      ln_login_id 	 NUMBER := fnd_global.login_id;
      ln_request_id      NUMBER := fnd_global.conc_request_id;
      ln_rec_cnt         NUMBER := 0;
      ln_upd_cnt         NUMBER := 0;
      ln_err_cnt         NUMBER := 0;
      ln_conc_file_copy_request_id NUMBER;
      
      /*File columns*/   
      ln_tracking_id      NUMBER;
      lc_scan_in_tmstmp   VARCHAR2(50);
      lc_scan_out_tmstmp  VARCHAR2(50);
      lc_ilp	          VARCHAR2(250);
      l_nofile            EXCEPTION;
   
   BEGIN
      lc_filename := p_filename;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'File dir :'||lc_filedir);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'File Name:'||lc_filename);
      
      UTL_FILE.FGETATTR(lc_filedir,lc_filename,lb_file_exist,ln_size,ln_block_size);
      IF NOT lb_file_exist THEN
          raise l_nofile;
      END IF;
      
      l_filehandle := UTL_FILE.FOPEN(lc_filedir,lc_filename,'r',l_max_linesize);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'File open successfull');
      LOOP
         BEGIN
            UTL_FILE.GET_LINE(l_filehandle,lc_newline);
            IF lc_newline IS NULL THEN
   	    exit;
   	 END IF;
   	
   	 ln_tracking_id 	:= TRIM(SUBSTR(lc_newline,1,INSTR(lc_newline,'|',1,1)-1));
   	 lc_scan_in_tmstmp	:= TRIM(SUBSTR(lc_newline,INSTR(lc_newline,'|',1,1)+1,INSTR(lc_newline,'|',1,2)-INSTR(lc_newline,'|',1,1)-1));
   	 lc_scan_out_tmstmp	:= TRIM(SUBSTR(lc_newline,INSTR(lc_newline,'|',1,2)+1,INSTR(lc_newline,'|',1,3)-INSTR(lc_newline,'|',1,2)-1));
   	 lc_ilp			:= TRIM(SUBSTR(lc_newline,INSTR(lc_newline,'|',1,3)+1,INSTR(lc_newline,'|',1,4)-INSTR(lc_newline,'|',1,3)-1));
   	 
   	 --FND_FILE.PUT_LINE(FND_FILE.LOG,ln_tracking_id);
   	 --FND_FILE.PUT_LINE(FND_FILE.LOG,lc_scan_in_tmstmp);
   	 --FND_FILE.PUT_LINE(FND_FILE.LOG,lc_ilp);
   	  
   	 UPDATE xx_wsh_ship_lbl_tracking
   	    SET scan_in_tmstmp  = TO_TIMESTAMP (lc_scan_in_tmstmp,'YYYY-MM-DD-HH24.MI.SS.FF'),
   	        scan_out_tmstmp = TO_TIMESTAMP (lc_scan_out_tmstmp,'YYYY-MM-DD-HH24.MI.SS.FF'),
   	        ilp		= lc_ilp,
   	        statuscode      = '0',        --need to confirm
   	        statusdesc      = 'SUCCESS - Scan info updated',
   	        last_updated_by = ln_user_id,
   	        last_update_date = sysdate,
   	        last_update_login = ln_login_id
   	  WHERE tracking_id = ln_tracking_id;
            ln_upd_cnt := ln_upd_cnt + SQL%ROWCOUNT;
   
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            exit;
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR Processing Line '||lc_newline);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - '||substr(sqlerrm,1,250));
            ln_err_cnt := ln_err_cnt + 1;
         END;
         ln_rec_cnt := ln_rec_cnt + 1;
      END LOOP;
      UTL_FILE.FCLOSE(l_filehandle);

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,TO_CHAR(ln_rec_cnt)||' lines processed');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,TO_CHAR(ln_upd_cnt)||' lines updated');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,TO_CHAR(ln_err_cnt)||' lines completed in error');
      dbms_lock.sleep(5);
      
      
      
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling the Common File Copy to move the Inbound file to Archive folder');
      lc_dest_file_name := '$XXFIN_ARCHIVE/inbound/' || SUBSTR(lc_filename,1,LENGTH(lc_filename) - 4)
                                               || TO_CHAR(SYSDATE, 'DD-MON-YYYYHHMMSS') || '.txt';
      ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
      					                         'XXCOMFILCOPY',
      					   		         '',
      								 '',
      								 FALSE,
      								 '$XXFIN_DATA/ftp/in/nontrade/'||lc_filename,   --Source File Name
      								 lc_dest_file_name,   --Dest File Name
      								 '',
      								 '',
      								 'Y'   --Deleting the Source File
								 );
      
      COMMIT;
      
      IF ln_err_cnt > 0 THEN
         x_ret_code := 1;
      ELSE
         x_ret_code := 0;      
      END IF;
      
   EXCEPTION
   WHEN l_nofile THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Warning - File not exists');
       x_ret_code := 1;
   WHEN UTL_FILE.INVALID_OPERATION THEN
       UTL_FILE.FCLOSE(l_filehandle);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - Invalid Operation');
       x_ret_code:=2;
   WHEN UTL_FILE.INVALID_FILEHANDLE THEN
       UTL_FILE.FCLOSE(l_filehandle);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - Invalid File Handle');
       x_ret_code:=2;
   WHEN UTL_FILE.READ_ERROR THEN
       UTL_FILE.FCLOSE(l_filehandle);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - Read Error');
       x_ret_code:=2;
   WHEN UTL_FILE.INVALID_PATH THEN
       UTL_FILE.FCLOSE(l_filehandle);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - Invalid Path');
       x_ret_code:=2;
   WHEN UTL_FILE.INVALID_MODE THEN
       UTL_FILE.FCLOSE(l_filehandle);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - Invalid Mode');
       x_ret_code:=2;
   WHEN UTL_FILE.INTERNAL_ERROR THEN
       UTL_FILE.FCLOSE(l_filehandle);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - Internal Error');
       x_ret_code:=2;
   WHEN OTHERS THEN
       UTL_FILE.FCLOSE(l_filehandle);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR - '||substr(sqlerrm,1,250));
       x_ret_code:=2;
   END LOAD_TRACKING_DATA;
PROCEDURE write_debug(p_msg IN VARCHAR2)   -- Procedure added for the defect#43375
IS
BEGIN
     IF g_debug_lvl <> g_def_debug
	 THEN
     fnd_file.put_line(fnd_file.LOG,p_msg);
	 END IF;
END;
PROCEDURE write_log(p_mode IN VARCHAR2   -- Procedure added for the defect#43375
                   ,p_msg IN VARCHAR2)
IS
BEGIN
   IF p_mode ='L'
   THEN 
      fnd_file.put_line(fnd_file.LOG,p_msg);
   ELSE 	  
     fnd_file.put_line(fnd_file.OUTPUT,p_msg);
   END IF;	 
END;
FUNCTION get_loc(p_loc_id IN NUMBER,p_order_num IN NUMBER)   -- Procedure added for the defect#43375
RETURN VARCHAR2
IS
lc_loc_code VARCHAR2(100); 
BEGIN
SELECT  SUBSTR(HL.location_code,1,6)
  INTO     lc_loc_code
  FROM     hz_cust_accounts             HCA
          ,hz_party_sites               HPS
          ,hz_cust_acct_sites_all       HCASA
          ,hz_cust_site_uses_all        HCSUA
          ,po_location_associations_all PLAA
          ,hr_locations                 HL
		  ,oe_order_headers_all         OOH
  WHERE   HPS.party_id                = HCA.party_id
  AND     HCASA.party_site_id         = HPS.party_site_id
  AND     HCSUA.cust_acct_site_id     = HCASA.cust_acct_site_id
  AND     PLAA.site_use_id            = HCSUA.site_use_id
  AND     HL.location_id              = PLAA.location_id
  AND     HCSUA.site_use_code         = 'SHIP_TO'
  AND     HCA.cust_account_id         = ooh.sold_to_org_id
  AND     HPS.location_id             = p_loc_id
  AND     HCASA.cust_account_id       = ooh.sold_to_org_id           
  AND     HCASA.org_id                = FND_PROFILE.VALUE('ORG_ID')  
  AND     PLAA.org_id			      = FND_PROFILE.VALUE('ORG_ID')
  AND     ooh.order_number            = p_order_num; 
RETURN  lc_loc_code;
EXCEPTION 
WHEN OTHERS
THEN 
    lc_loc_code := NULL;
    RETURN  lc_loc_code;	
END;	 
PROCEDURE REPROCESS_LABELS_DATA(x_error_buff  OUT  VARCHAR2     -- Procedure added for the defect#43375
                               ,x_ret_code    OUT  VARCHAR2
                               ,p_order_nbr    IN  VARCHAR2
                               ,p_tracking_id  IN  NUMBER
							   ,p_days         IN  NUMBER 
                               ,p_debug_lvl    IN  VARCHAR2 DEFAULT 'N'			   
                               )	
IS                      
-- Variable Declarations
lc_hosturl                     VARCHAR2(2000);
lc_username                    VARCHAR2(30):=NULL;
lc_password                    VARCHAR2(30):=NULL;
ln_consumer_transaction_id     VARCHAR2(250);
lc_soap_request                VARCHAR2 (32500);
lc_soap_respond                VARCHAR2 (32500);
lr_http_request                UTL_HTTP.req;
lr_http_response               UTL_HTTP.resp; 
resp                           XMLTYPE;
lc_resp_statuscode             VARCHAR2(500)  := null;
lc_resp_statusdesc             VARCHAR2(2000) := null;
lc_location_code               VARCHAR2(20);     					  
Invoke_exception               EXCEPTION;  
ln_user_id   	               NUMBER :=  FND_GLOBAL.USER_ID;
---- Added for V1.15
lt_translation_info            xx_fin_translatevalues%ROWTYPE;  ---- Added for V1.15
lc_wallet_location             xx_fin_translatevalues.target_value1%TYPE;
lc_wallet_password             xx_fin_translatevalues.target_value1%TYPE;
--- End V1.15
CURSOR tracking_cur                                                                                                         
    IS                                                                                 
    SELECT xt.tracking_id                                   
          ,xt.order_nbr
          ,xt.order_dt
          ,xt.delivery_dt
          ,xt.delivery_id
          ,xt.trip_id
          ,xt.container_id
          ,xt.lane_nbr
          ,xt.src_loc_id
          ,xt.loc_id
          ,xt.statuscode
          ,xt.statusdesc
  FROM xx_wsh_ship_lbl_tracking xt 
 WHERE NVL(xt.statuscode,-2) <>'0'
   AND UPPER(xt.statusdesc) NOT LIKE 'DUPLICATE%CONTAINER%'                     
   AND xt.tracking_id  = NVL(p_tracking_id,xt.tracking_id) 
   AND xt.order_nbr    = NVL(p_order_nbr,xt.order_nbr)     
   AND xt.creation_date > SYSDATE-NVL(p_days,365);
   CURSOR get_service_params_cur 
    IS
      SELECT  xftv.source_value1
	         ,xftv.target_value1
        FROM  xx_fin_translatedefinition xftd
	         ,xx_fin_translatevalues xftv
	   WHERE  xftd.translate_id = XFTV.translate_id
	     AND  xftd.translation_name = 'OD_SHIP_OUTBOUND_SERVICE'
	     AND  SYSDATE BETWEEN XFTV.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
	     AND  SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
	     AND  xftv.enabled_flag = 'Y'
         AND  xftd.enabled_flag = 'Y';    
BEGIN
     write_log('L','Order Number     :'||p_order_nbr);
     write_log('L','Tracking Id      :'||p_tracking_id);
	 write_log('L','Number of Days   :'||p_days);
	 write_log('L','Debug Level      :'||p_debug_lvl);
                                                                                                           
	  g_debug_lvl := p_debug_lvl;
     -- -------------------------------------------------------
     -- Get web service values 
     -- -------------------------------------------------------
     FOR get_service_params_rec IN get_service_params_cur 
     LOOP
        IF get_service_params_rec.source_value1 = 'URL' THEN
           lc_hosturl := get_service_params_rec.target_value1;
        ELSIF get_service_params_rec.source_value1 = 'USERNAME' THEN
	       lc_username := get_service_params_rec.target_value1;
        ELSIF get_service_params_rec.source_value1 = 'PASSWORD' THEN
	       lc_password := xx_encrypt_decryption_toolkit.decrypt(get_service_params_rec.target_value1);
        END IF;
     END LOOP;                                                                                                                         
            
     FOR track IN  tracking_cur
     LOOP
     BEGIN  	 
        write_log('L','Procesing tracking_id -'||track.tracking_id);                                                                                                                                                                                               
        ln_consumer_transaction_id := 'EBIZ'||TO_CHAR(track.tracking_id);
		lc_location_code  := get_loc(track.loc_id,track.order_nbr);
        IF lc_location_code IS NULL
        THEN
            lc_resp_statusdesc := 'Unable to derive the location for location_id '|| track.src_loc_id;
            RAISE invoke_exception;
        END IF; 			
             lc_soap_request :='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
		    xmlns:tran="http://www.officedepot.com/model/transaction" 
		    xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		    xmlns:ord="http://eai.officedepot.com/model/Order">
				 <soapenv:Header/>
				 <soapenv:Body>
				   <non:noneTradeShipmentTrackingRequest>
				   <tran:transactionHeader>
				       <tran:consumer>
					   <tran:consumerName>EBIZ</tran:consumerName>
					   <tran:consumerTransactionID>'||ln_consumer_transaction_id||'</tran:consumerTransactionID>
					</tran:consumer>
				    </tran:transactionHeader>
				   <non:trackingNumber>'||to_char(track.tracking_id)||'</non:trackingNumber>
				   <non:locationId>'||lc_location_code||'</non:locationId>
				   <non:orderDate>'||TO_CHAR(track.order_dt,'YYYY-MM-DD')||'</non:orderDate>
				   <non:orderHeader>
				       <ord:orderNumber>'||TO_CHAR(track.order_nbr)||'</ord:orderNumber>
				    </non:orderHeader>
				    <non:deliveryDate>'||TO_CHAR(TO_DATE(track.delivery_dt,'DD-MON-YY'),'RRRR-MM-DD')||'</non:deliveryDate>
				   <non:containerId>'||track.container_id||'</non:containerId>
				   <non:laneNumber>'||track.lane_nbr||'</non:laneNumber>
				   <non:deliveryId>'||TO_CHAR(track.delivery_id)||'</non:deliveryId>
				  </non:noneTradeShipmentTrackingRequest>
				 </soapenv:Body>
				</soapenv:Envelope>';
			write_debug('SOAP Request :');	
            write_debug(lc_soap_request);
			write_log('L','Before SOAP request call' );
      
      -----/*   Below code is added for V1.15 
  /***********************
   * Get wallet information
   ***********************/
                 
           lt_translation_info := NULL;
         
           lt_translation_info.source_value1 := 'WALLET_LOCATION';
         
           get_translation_info(p_translation_name  => 'XX_FIN_IREC_TOKEN_PARAMS',
                                px_translation_info => lt_translation_info);
                                
           lc_wallet_location  := lt_translation_info.target_value1;
           lc_wallet_password  := lt_translation_info.target_value2;
            IF lc_wallet_location IS NOT NULL
            THEN

              UTL_HTTP.SET_WALLET(lc_wallet_location, lc_wallet_password);
			  
            END IF;
			
            UTL_HTTP.set_response_error_check(FALSE);
---- END V1.15  

			lr_http_request :=  UTL_HTTP.begin_request (lc_hosturl, 'POST', 'HTTP/1.1');
			write_debug(' After lr_http_request: ');
            IF lc_username IS NOT NULL THEN
               UTL_HTTP.set_authentication(lr_http_request,lc_username,lc_password);
            END IF;                                                                                                                                                                                           
            UTL_HTTP.set_header (lr_http_request, 'Content-Type', 'text/xml');
			write_debug(' After UTL_HTTP.set_header step-1');
            -- since we are dealing with plain text in XML documents
            UTL_HTTP.set_header(lr_http_request,'Content-Length',LENGTH (lc_soap_request));
			write_debug(' After UTL_HTTP.set_header step-2');
            UTL_HTTP.set_header(lr_http_request, 'SOAPAction', '');
			write_debug(' After UTL_HTTP.set_header step-3');
            -- required to specify this is a SOAP communication
            UTL_HTTP.write_text(lr_http_request, lc_soap_request);
			write_debug(' After UTL_HTTP.write_text step-4');
            lr_http_response := UTL_HTTP.get_response (lr_http_request);
			write_debug(' After UTL_HTTP.get_response step-5');
            UTL_HTTP.read_text (lr_http_response, lc_soap_respond);
            write_debug('Response Message:'||lc_soap_respond);
            UTL_HTTP.end_response(lr_http_response);
			write_debug('UTL_HTTP.end_response Step-6');
            resp := XMLTYPE.createxml (lc_soap_respond);
            lc_resp_statuscode := null;
            lc_resp_statusdesc := null;
             /* Check if invoke is success */
			write_debug('Response code  : '||lr_http_response.status_code ); 
			write_log('L','Response code  : '||lr_http_response.status_code ); 
        IF (lr_http_response.status_code = 200)
	     THEN
		   BEGIN
		    SELECT EXTRACTVALUE(resp,'/soapenv:Envelope/soapenv:Body/non:noneTradeShipmentTrackingResponse/non:status/odc:statusCode',
		          'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		           xmlns:odc="http://eai.officedepot.com/model/ODCommon"'),
		           SUBSTR(EXTRACTVALUE(resp,'/soapenv:Envelope/soapenv:Body/non:noneTradeShipmentTrackingResponse/non:status/odc:statusDescription',
		          'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:non="http://eai.officedepot.com/service/NoneTradeShipmentTrackingService" 
		           xmlns:odc="http://eai.officedepot.com/model/ODCommon"'),1,2000)
		     INTO lc_resp_statuscode,lc_resp_statusdesc
		     FROM dual; 
		     --check statuscode if response from service is fault message
		     IF lc_resp_statuscode IS NULL THEN
		        lc_resp_statuscode := '-2';
		        lc_resp_statusdesc := SUBSTR('statuscode not found(fault message)'||lc_soap_respond,1,2000);
				write_log('L','Tracking ID: '||track.tracking_id ||' '||lc_resp_statusdesc ); 
             END IF;
 	        EXCEPTION
		    WHEN others THEN
		        lc_resp_statuscode := '-2';
		        lc_resp_statusdesc := SUBSTR('Error occured while deriving status code from response message'||SUBSTR(sqlerrm,1,250)||lc_soap_respond,1,2000);
				write_debug(lc_resp_statusdesc);
		    END;
		
		  UPDATE xx_wsh_ship_lbl_tracking
		   SET statuscode = lc_resp_statuscode --need to confirm
		      ,statusdesc = lc_resp_statusdesc
		      ,last_updated_by = ln_user_id
		      ,last_update_date = sysdate                       
		   WHERE tracking_id = track.tracking_id;
		    write_debug('Tracking Number is Sent Successfully for :'||track.tracking_id);
        ELSE --If invoke is not success
	        lc_resp_statuscode := '-2';
	        lc_resp_statusdesc := SUBSTR('Message Code:'||to_char(lr_http_response.status_code)||' Reason Phrase:'||lr_http_response.reason_phrase,1,2000);
	        write_log('L',lc_resp_statusdesc); 
			RAISE invoke_exception;
	     END IF;
	       
	     write_log('L','Response Code :'||lc_resp_statuscode);
	     write_log('L','respstatusdesc:'|| lc_resp_statusdesc);
	     
   EXCEPTION
      WHEN invoke_exception THEN
             UPDATE xx_wsh_ship_lbl_tracking
	        SET statuscode = lc_resp_statuscode 
	           ,statusdesc = lc_resp_statusdesc
	           ,last_updated_by = ln_user_id
	           ,last_update_date = sysdate                       
	      WHERE tracking_id = track.tracking_id; 
	  WHEN others THEN
	     lc_resp_statuscode := '-2'; 
	     lc_resp_statusdesc := SUBSTR('WHEN others'||sqlerrm,1,2000);
		   write_log('L',lc_resp_statusdesc); 
	     UPDATE xx_wsh_ship_lbl_tracking
	        SET statuscode = lc_resp_statuscode 
	 	   ,statusdesc = lc_resp_statusdesc
		   ,last_updated_by = ln_user_id
		   ,last_update_date = sysdate                       
	      WHERE tracking_id = track.tracking_id;
          write_debug('Update the staging table with error code and message'); 		  
          END;     
      END LOOP; 
	  COMMIT;
EXCEPTION
WHEN OTHERS
THEN
	write_log('L','Exception in process data Procedure :'||SQLERRM);  
END;
END XX_WSH_SHIPPING_LABEL_PKG;
/
