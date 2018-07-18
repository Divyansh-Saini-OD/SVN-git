create or replace
PACKAGE body XX_MPS_ORDER_DW_OUT_PKG
AS
  -- +====================================================================================================+
  -- |                  Office Depot                                                                      |
  -- |                  Oracle Consulting                                                                 |
  -- +====================================================================================================+
  -- | Name  : XX_MPS_ORDER_DW_OUT_PKG                                                                    |
  -- | Description  : Defect# 20726                                                                       |
  -- |                                                                                                    |
  -- |Change Record:                                                                                      |
  -- +====================================================================================================+                                                                                   
  -- |Version    Date          Author              Remarks                                                |
  -- |=======    ==========    ==========          =======================================================|
  -- |1.0        18-Oct-2012   Deepti S            Initial version - Defect# 20726                        |
  -- |1.1        03-APR-2013   Ray Strauss         increased rounding procision                           |
  -- |1.2        20-AUG-2013   Raj Jagarlamudi     MPS COGs changes                                       |
  -- |1.3        19-FEB-2014   Arun Gannarapu      Made changes to add the distinct clause to             |
  -- |                                             c_order_lines cursor defect 28322                      |
  -- |1.4        26-FEB-2014   Arun Gannarapu      Made changes to fix the duplicate issue defect 28642   |
  -- |1.5        29-MAY-2014   Arun Gannarapu      Made chages to fix the Color issue defect 28863        |
  -- |1.6        29-MAY-2014   Arun Gannarapu      Added comments                                         |
  -- |1.7        04-JUN-2014   Arun Gannararpu     Added logic to include overage records                 |
  -- |1.8        07-JUL-2014   Arun Gannarapu      Made changes to get the cpc from MPS tables instead    |
  -- |                                             Order lines                                            |
  -- |1.9        03-NOV-2015   Havish Kasina       Removed the Schema references in the existing code as  |
  -- |                                             per R12.2 Retrofit Changes                             |
  -- +====================================================================================================+
PROCEDURE FTP_FILE( p_file_name IN  VARCHAR2
                  , x_retcode   OUT NUMBER
                  , x_errbuf    OUT VARCHAR2
                  );
                  
PROCEDURE MAIN(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT NUMBER ,
    p_days NUMBER)
IS
  lc_filehandle UTL_FILE.file_type;
  LC_TIMESTAMP       VARCHAR2 (100)  := TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISS');
  lc_dirpath         VARCHAR2 (2000) := 'XXOM_OUTBOUND';
  lc_order_file_name VARCHAR2 (100)  :='MPS_ORDERS';
  lc_message         VARCHAR2 (4000);
  lc_mode            VARCHAR2 (1) := 'W';
  ln_HEADER_ID OE_ORDER_HEADERS_ALL.HEADER_ID%TYPE;
  ln_line_id OE_ORDER_LINES_ALL.LINE_ID%TYPE;
  l_line_count   NUMBER :=0;
  l_header_count NUMBER :=0;
  lc_serial_no   VARCHAR2(25);
  lc_label       VARCHAR2(25);
  ln_count       NUMBER;
  ln_cost        NUMBER;
  lc_serialNo    VARCHAR2(50);
  ln_return_id   NUMBER;
  ln_party_id    NUMBER;

 
  -- Extract the Usage Orders created in last updated in p_days. 
  
  CURSOR c_orders
  IS
    SELECT '"H"|"'
      ||ooh.HEADER_ID
      ||'"|"'
      || OoH.ORDER_NUMBER
      ||'"|"'
      || TO_CHAR(OoH.LAST_UPDATE_DATE, 'YYYY/MM/DD')
      ||'"|"'
      || OoH.SHIP_FROM_ORG_ID
      ||'"|"'
      || trim(xoha.CREATED_BY_ID)
      ||'"|"'
      || TO_CHAR(xoha.ORDER_END_TIME, 'YYYY/MM/DD HH:MI:SS')
      ||'"|"'
      ||
      (SELECT lookup_code
      FROM FND_LOOKUP_VALUES
      WHERE lookup_type='OD_ORDER_SOURCE'
      AND meaning      = 'ODS'
      )
    ||'"|"'
    ||
    (SELECT ATTRIBUTE1
    FROM HR_ALL_ORGANIZATION_UNITS
    WHERE organization_id =OoH.SHIP_FROM_ORG_ID
    )
    ||'"' msg,
    ooh.header_id
  FROM OE_ORDER_HEADERS_ALL ooh ,
    XX_OM_HEADER_ATTRIBUTES_ALL xoha ,
    OE_TRANSACTION_TYPES_TL ott ,
    oe_order_sources oos
  WHERE ooh.HEADER_ID            = xoha.HEADER_ID
  AND ooh.flow_status_code       = 'CLOSED'
  AND ott.transaction_type_id    = ooh.order_type_id
  AND ott.name                   ='MPS US Standard'
  AND oos.order_source_id        = ooh.order_source_id
  AND oos.name                   ='ODS'
  AND OOH.LAST_UPDATE_DATE       > SYSDATE-P_DAYS
  AND NVL(xoha.mps_ext_flag,'N') = 'N';
  

  -- Get all the Line details for given header id 

  CURSOR c_order_lines(p_header_id NUMBER)
  IS
    SELECT DISTINCT 
    * 
    FROM 
    ( SELECT '"I"|"'
      || ool.header_id
      ||'"|"'
      || ool.ORDER_NUMBER
      ||'"|"'
      || xmd.serial_no
      ||'"|"'
      || OoL.LINE_NUMBER
      ||'"|"'
      || decode(jtb.attribute1, 'Black', xmd.black_count, 'Color', xmd.color_count,'Over Usage',xmd.over_usage ,'Color Over Usage',color_over_usage) 
      ||'"|"'
      || (decode(jtb.attribute1, 'Black', xmd.black_count, 'Color', xmd.color_count,'Over Usage',xmd.over_usage ,'Color Over Usage',color_over_usage) * NVL(OOL.PO_COST,0))
      ||'"|"'
    --  || ROUND(NVL(OoL.UNIT_SELLING_PRICE,0),4)
      || (decode(jtb.attribute1, 'Black', xmd.black_count, 'Color', xmd.color_count,'Over Usage',xmd.over_usage ,'Color Over Usage',color_over_usage) * 
         (decode(jtb.attribute1, 'Black', NVL(xmb.black_cpc,0), 'Color', NVL(xmb.color_cpc,0),NVL(xmb.overage_cost,0))))
      ||'"|"'
      || ROUND(NVL(OoL.TAX_VALUE,0),3)
      ||'"|"'
      || NVL(OoL.SHIP_FROM_ORG_ID,0)
      ||'"|"'
      || NVL(OoL.INVENTORY_ITEM_ID, 0)
      ||'"|"'
      || NVL(OOL.ITEM_SOURCE, '')
      ||'"|"'
      || NVL(OOL.taxable_flag,'')
      ||'"|"'
      || NVL(OOL.SEGMENT1,'')
      ||'"|"'
      ||'A'
      || '"' msg,
      ool.line_id
 FROM XX_CS_MPS_DEVICE_DETAILS XMD,
      XX_CS_MPS_DEVICE_B XMB,
      CS_INCIDENTS_ALL_B CCB,
      JTF_TASKS_B JTB,
      (SELECT OOH.HEADER_ID, OOH.ORDER_NUMBER,
         OOL.LINE_NUMBER, OOL.SHIP_FROM_ORG_ID,ool.orig_sys_line_ref,
         OOH.ORIG_SYS_DOCUMENT_REF, HRA.ATTRIBUTE1,XOLA.PO_COST,
         MSI.SEGMENT1, OOL.TAX_VALUE, OOL.INVENTORY_ITEM_ID,
         XOLA.ITEM_SOURCE, XOLA.TAXABLE_FLAG, OOL.LINE_ID,
         OoL.UNIT_SELLING_PRICE
         FROM OE_ORDER_LINES_ALL ooL ,
              OE_ORDER_HEADERS_ALL ooh ,
              XX_OM_LINE_ATTRIBUTES_ALL xOLA ,
              MTL_SYSTEM_ITEMS_B MSI,
              HR_ALL_ORGANIZATION_UNITS hra
         WHERE HRA.ORGANIZATION_ID = OoL.SHIP_FROM_ORG_ID
            AND OoL.HEADER_ID       = ooH.HEADER_ID
            AND xola.LINE_ID          = OoL.LINE_ID
            AND MSI.INVENTORY_ITEM_ID = OoL.INVENTORY_ITEM_ID
            AND MSI.ORGANIZATION_ID   = OoL.SHIP_FROM_ORG_ID
           AND OOH.HEADER_ID         =  P_HEADER_ID) OOL
      WHERE OOL.ORIG_SYS_DOCUMENT_REF = CCB.INCIDENT_NUMBER
      AND   JTB.SOURCE_OBJECT_ID = CCB.INCIDENT_ID
      AND   JTB.SOURCE_OBJECT_TYPE_CODE = 'SR'
      AND   XMD.SERIAL_NO = XMB.SERIAL_NO
      AND   XMB.PARTY_ID = CCB.CUSTOMER_ID
      AND   CCB.INCIDENT_NUMBER = XMD.REQUEST_NUMBER
      AND   JTB.ATTRIBUTE8 = OOL.SHIP_FROM_ORG_ID
      AND   NVL(XMD.ATTRIBUTE3,1165) = OOL.ATTRIBUTE1
      AND   DECODE(JTB.ATTRIBUTE1, 'Black', XMD.BLACK_COUNT, 'Color', XMD.COLOR_COUNT,'Over Usage',xmd.over_usage ,'Color Over Usage',color_over_usage) > 0
      AND   JTB.ATTRIBUTE5 = OOL.SEGMENT1
      AND   XMD.SUPPLIES_LABEL = 'USAGE'
      AND   jtb.task_id        = ool.orig_sys_line_ref  -- added to fix the dup issue
      ---AND   xmd.attribute1     = jtb.task_id            -- added to fix the dup issue 
      AND   DECODE(JTB.ATTRIBUTE1, 'Black',      XMD.attribute1, 
                                   'Color',      xmd.color_task_id, 
                                   'Over Usage', xmd.overage_task_id,
                                   'Color Over Usage' , xmd.color_overage_task_id)  = jtb.task_id -- added to fix the dup/color issue 28863
      ORDER BY OOL.LINE_NUMBER );

  -- Get the header for Reversal Entries .. 
  -- 
   
   CURSOR MPS_CUR IS
   SELECT '"H"|"'
      ||ooh.HEADER_ID
      ||'"|"'
      || OoH.ORDER_NUMBER
      ||'"|"'
      || TO_CHAR(OoH.LAST_UPDATE_DATE, 'YYYY/MM/DD')
      ||'"|"'
      || OoH.SHIP_FROM_ORG_ID
      ||'"|"'
      || trim(xoha.CREATED_BY_ID)
      ||'"|"'
      || TO_CHAR(xoha.ORDER_END_TIME, 'YYYY/MM/DD HH:MI:SS')
      ||'"|"'
      ||
      (SELECT lookup_code
      FROM FND_LOOKUP_VALUES
      WHERE lookup_type='OD_ORDER_SOURCE'
      AND meaning      = 'ODS'
      )
    ||'"|"'
    ||
    (SELECT ATTRIBUTE1
    FROM HR_ALL_ORGANIZATION_UNITS
    WHERE organization_id =OoH.SHIP_FROM_ORG_ID
    )
    ||'"' msg,
    ooh.header_id
  FROM OE_ORDER_HEADERS_ALL ooh ,
    XX_OM_HEADER_ATTRIBUTES_ALL xoha ,
    OE_TRANSACTION_TYPES_TL ott ,
    oe_order_sources oos
  WHERE ooh.HEADER_ID            = xoha.HEADER_ID
  AND ooh.flow_status_code       = 'CLOSED'
  AND ott.transaction_type_id    = ooh.order_type_id
  AND ott.name                   ='MPS US Standard'
  AND oos.order_source_id        = ooh.order_source_id
  AND oos.name                   ='ODS'
  AND OOH.LAST_UPDATE_DATE       > SYSDATE-P_DAYS
  AND NVL(xoha.mps_ext_flag,'N') = 'P';

 
  /* SELECT DISTINCT '"H"|"'
           ||ooh.HEADER_ID
          ||'"|"'
          || OoH.ORDER_NUMBER
          ||'"|"'
          || TO_CHAR(OoH.LAST_UPDATE_DATE, 'YYYY/MM/DD')
          ||'"|"'
          || OoH.SHIP_FROM_ORG_ID
          ||'"|"'
          || trim(xoha.CREATED_BY_ID)
          ||'"|"'
          || TO_CHAR(xoha.ORDER_END_TIME, 'YYYY/MM/DD HH:MI:SS')
          ||'"|"'
          ||
          (SELECT lookup_code
          FROM FND_LOOKUP_VALUES
          WHERE lookup_type='OD_ORDER_SOURCE'
          AND meaning      = 'ODS'
          )
        ||'"|"'
        ||
        (SELECT ATTRIBUTE1
        FROM HR_ALL_ORGANIZATION_UNITS
        WHERE organization_id =OoH.SHIP_FROM_ORG_ID
        )
        ||'"' msg,
        ooh.header_id
      FROM OE_ORDER_HEADERS_ALL ooh ,
        XX_OM_HEADER_ATTRIBUTES_ALL xoha ,
        OE_TRANSACTION_TYPES_TL ott ,
        oe_order_sources oos,
        XX_CS_MPS_DEVICE_DETAILS xmd ,
        (select distinct md.serial_no
      from xx_cs_mps_device_details md,
           xx_cs_mps_device_b mb
      where md.serial_no = mb.serial_no
      and supplies_label <> 'USAGE'
      and nvl(usage_billed,'N') = 'N'
      and md.toner_order_date > sysdate - p_days)  xmdd 
      WHERE ooh.HEADER_ID            = xoha.HEADER_ID
      AND ooh.flow_status_code       = 'CLOSED'
      AND ott.transaction_type_id    = ooh.order_type_id
      AND ott.name                   ='MPS US Standard'
      AND oos.order_source_id        = ooh.order_source_id
      AND oos.name                   ='ODS'
      AND xmd.request_number         = ooh.orig_sys_document_ref  
      AND xmd.serial_no              = xmdd.serial_no
      AND xmd.supplies_label         = 'USAGE'; */
      

    -- Reversal Entries for Toner Transactions ..

    CURSOR MPS_PRE_ORDERS (p_header_id NUMBER) IS
         SELECT '"I"|"'
      || ooh.header_id
      ||'"|"'
      || ooh.ORDER_NUMBER
      ||'"|"'
      || XMDD.SERIAL_NO
      ||'"|"'
      || 1
      ||'"|"'
      || 0 --xmdd.current_count
      ||'"|"'
      || (((NVL(mssi.attribute14,0)-xmdd.service_cost)*xmdd.total_retail_count)*-1)
      ||'"|"'
      || (((nvl(xmdd.toner_cost,0)*xmdd.total_retail_count)*-1))
      ||'"|"'
      || ROUND(NVL(null,0),3)
      ||'"|"'
      || NVL(xmdd.org_id,0)
      ||'"|"'
      || NVL(msi.INVENTORY_ITEM_ID, 0)
      ||'"|"'
      || NVL(null, '')
      ||'"|"'
      || NVL(null,'')
      ||'"|"'
      || NVL(MSI.SEGMENT1,'')
      ||'"|"'
      ||'R'
      || '"' msg,
     xmdd.serial_no,
     xmdd.supplies_label,
     xmb.party_id
    FROM xx_cs_mps_device_b xmb,
         xx_cs_mps_device_details xmd,
         oe_order_headers_all ooh,
        cs_lookups cl,
        mtl_system_items_b msi,
        mtl_system_items_b mssi,
        (select md.serial_no, md.supplies_label, md.total_retail_count, nvl(mb.service_cost,0) service_cost,
      decode(md.supplies_label, 'TONERLEVEL_BLACK', mb.black_cpc, mb.color_cpc) - nvl(mb.service_cost,0) toner_cost,
      decode(md.supplies_label, 'TONERLEVEL_BLACK', 'BLACK', 'COLOR') label,
      hr.organization_id org_id
      from xx_cs_mps_device_details md,
           xx_cs_mps_device_b mb,
           hr_all_organization_units hr
      where to_number(hr.attribute1) = md.attribute3
      and md.serial_no = mb.serial_no
      and mb.program_type in (select meaning
                            from cs_lookups
                            where lookup_type = 'XX_MPS_PROGRAM_TYPES'
                            and tag in ('BOTH', 'USAGE')
                            and end_date_active is null)
      and supplies_label <> 'USAGE'
      and nvl(usage_billed,'N') = 'N'
      --and md.toner_order_date > sysdate - p_days
      and md.total_retail_count > 0 ) XMDD                
    where xmb.serial_no = xmd.serial_no                   
    and ooh.orig_sys_document_ref = xmd.request_number    
    and msi.organization_id = xmdd.org_id                 
    and msi.segment1 = cl.meaning
    and msi.segment1 = mssi.segment1
    and msi.inventory_item_id = mssi.inventory_item_id
    and mssi.organization_id = 441
    and cl.lookup_type ='XX_CS_MPS_USAGE_SKUS'
    and cl.lookup_code = xmdd.label
    and  xmd.serial_no = xmdd.serial_no 
    and ooh.header_id = p_header_id
    and xmd.supplies_label = 'USAGE';

CURSOR MPS_RET_ORDERS IS
 SELECT DISTINCT '"H"|"'
          ||ooh.HEADER_ID
          ||'"|"'
          || OoH.ORDER_NUMBER
          ||'"|"'
          || TO_CHAR(OoH.LAST_UPDATE_DATE, 'YYYY/MM/DD')
          ||'"|"'
          || OoH.SHIP_FROM_ORG_ID
          ||'"|"'
          || trim(xoha.CREATED_BY_ID)
          ||'"|"'
          || TO_CHAR(xoha.ORDER_END_TIME, 'YYYY/MM/DD HH:MI:SS')
          ||'"|"'
          ||
          (SELECT lookup_code
          FROM FND_LOOKUP_VALUES
          WHERE lookup_type='OD_ORDER_SOURCE'
          AND meaning      = 'ODS'
          )
        ||'"|"'
        ||
        (SELECT ATTRIBUTE1
        FROM HR_ALL_ORGANIZATION_UNITS
        WHERE organization_id =OoH.SHIP_FROM_ORG_ID
        )
        ||'"' msg,
        ooh.header_id
 FROM OE_ORDER_HEADERS_ALL ooh ,
        XX_OM_HEADER_ATTRIBUTES_ALL xoha ,
        OE_TRANSACTION_TYPES_TL ott ,
        oe_order_sources oos,
    (SELECT  xoha.header_id return_header, xmt.usage_request_number
          from xx_om_header_attributes_all xoha,
               oe_order_headers_all ooh,
               oe_order_lines_all ool,
               xx_om_line_attributes_all xola,
               xx_cs_mps_toner_details xmt
          where ooh.cust_po_number = xmt.serial_no
          and xola.ret_orig_order_num = xmt.toner_order_number||'001'
          and  xola.line_id = ool.line_id
          and ool.header_id = ooh.header_id
          and ooh.header_id = xoha.header_id
          and  ooh.order_source_id = 1041
          and  ooh.order_type_id = 1024
          and nvl(xoha.atr_order_flag,'N') = 'MPS'
          and nvl(xoha.mps_ext_flag,'N') = 'N'
          and ooh.creation_date > sysdate - p_days
          and exists (select 'x' from xx_cs_mps_device_b 
                      where serial_no = ooh.cust_po_number
                      and program_type = 'MPS')) xmd
WHERE ooh.HEADER_ID            = xoha.HEADER_ID
      AND ooh.flow_status_code       = 'CLOSED'
      AND ott.transaction_type_id    = ooh.order_type_id
      AND ott.name                   ='MPS US Standard'
      AND oos.order_source_id        = ooh.order_source_id
      AND oos.name                   ='ODS'
      AND ooh.orig_sys_document_ref  = xmd.usage_request_number;
            
CURSOR MPS_RET_LINES (p_header_id NUMBER) IS
SELECT '"I"|"'
      || ooh.header_id
      ||'"|"'
      || ooh.ORDER_NUMBER
      ||'"|"'
      || XMDD.SERIAL_NO
      ||'"|"'
      || 1
      ||'"|"'
      || 0 
      ||'"|"'
      || (((NVL(mssi.attribute14,0)-xmdd.service_cost)*xmdd.current_count))
      ||'"|"'
      || xmdd.toner_order_total
      ||'"|"'
      || ROUND(NVL(null,0),3)
      ||'"|"'
      || ooh.ship_from_org_id 
      ||'"|"'
      || NVL(msi.INVENTORY_ITEM_ID, 0)
      ||'"|"'
      || NVL(null, '')
      ||'"|"'
      || NVL(null,'')
      ||'"|"'
      || NVL(MSI.SEGMENT1,'')
      ||'"|"'
      ||'R'
      || '"' msg,
     xmdd.serial_no,
     xmdd.supplies_label,xmdd.header_id
    FROM oe_order_headers_all ooh,
        cs_lookups cl,
        mtl_system_items_b msi,
        mtl_system_items_b mssi,
        (SELECT  xoha.header_id,xmt.usage_request_number, xmt.serial_no,xmt.toner_order_total,xmt.current_count,xmb.service_cost,
        decode(xmt.supplies_label, 'TONERLEVEL_BLACK', xmb.black_cpc, xmb.color_cpc) - nvl(xmb.service_cost,0) toner_cost,
        decode(xmt.supplies_label, 'TONERLEVEL_BLACK', 'BLACK', 'COLOR') label,
        xmt.supplies_label
          from xx_om_header_attributes_all xoha,
               oe_order_headers_all ooh,
               oe_order_lines_all ool,
               xx_om_line_attributes_all xola,
               xx_cs_mps_toner_details xmt,
               xx_cs_mps_device_b xmb
          where xmb.serial_no = xmt.serial_no
          and ooh.cust_po_number = xmt.serial_no
          and xola.ret_orig_order_num = xmt.toner_order_number||'001'
          and  xola.line_id = ool.line_id
          and ool.header_id = ooh.header_id
          and ooh.header_id = xoha.header_id
          and  ooh.order_source_id = 1041
          and  ooh.order_type_id = 1024
          and nvl(xoha.atr_order_flag,'N') = 'MPS'
          and nvl(xoha.mps_ext_flag,'N') = 'N'
          and ooh.creation_date > sysdate - p_days
          and exists (select 'x' from xx_cs_mps_device_b 
                      where serial_no = ooh.cust_po_number
                      and program_type = 'MPS')) XMDD
    where  ooh.orig_sys_document_ref = xmdd.usage_request_number--xmd.request_number
    and msi.organization_id = ooh.ship_from_org_id --xmdd.org_id 
    and msi.segment1 = cl.meaning
    and msi.segment1 = mssi.segment1
    and msi.inventory_item_id = mssi.inventory_item_id
    and mssi.organization_id = 441
    and cl.lookup_type ='XX_CS_MPS_USAGE_SKUS'
    and cl.lookup_code = xmdd.label
    and ooh.header_id = p_header_id;
    
BEGIN
  lc_message         := NULL;
  LC_ORDER_FILE_NAME := LC_ORDER_FILE_NAME || '_' || LC_TIMESTAMP ||'.dat';
  LC_FILEHANDLE      := UTL_FILE.FOPEN (LC_DIRPATH, LC_ORDER_FILE_NAME, LC_MODE);

  dbms_output.put_line('start..');

  OPEN c_orders;
  IF c_orders%NOTFOUND THEN
    UTL_FILE.put_line (lc_filehandle, lc_message);
    dbms_output.put_line(lc_message);
  ELSE
    fnd_file.put_line (fnd_file.LOG,'Starting to write order details in the file '|| LC_ORDER_FILE_NAME);
    dbms_output.put_line('Starting to write order details in the file '|| LC_ORDER_FILE_NAME);

    LOOP
      FETCH c_orders INTO lc_message, ln_header_id;
      EXIT WHEN c_orders%NOTFOUND;

      dbms_output.put_line('Header ID:'|| ln_header_id);

      UTL_FILE.put_line (lc_filehandle, lc_message);
      dbms_output.put_line(lc_message);

      l_header_count := l_header_count+1;

      OPEN C_ORDER_LINES(LN_HEADER_ID);
      lc_message := NULL;
      IF C_ORDER_LINES%NOTFOUND THEN
        UTL_FILE.put_line (lc_filehandle, lc_message);
        dbms_output.put_line(lc_message);
      ELSE
        LOOP
          FETCH c_order_lines INTO lc_message, ln_line_id;
          EXIT
        WHEN c_order_lines%NOTFOUND;
          UTL_FILE.put_line (lc_filehandle, lc_message);
          dbms_output.put_line(lc_message);
          l_line_count := l_line_count+1;
        END LOOP;
      END IF;
      CLOSE c_order_lines;

      UPDATE XX_OM_HEADER_ATTRIBUTES_ALL
      SET MPS_EXT_FLAG = 'P' ,
        MPS_EXT_DATE   = sysdate
      WHERE HEADER_ID  =ln_HEADER_ID ;
    END LOOP;
  END IF;
  CLOSE c_orders;


  -- Toner Order transactions Reversal Entries

  OPEN MPS_CUR;
  IF MPS_CUR%NOTFOUND THEN
        UTL_FILE.put_line (lc_filehandle, lc_message);
        dbms_output.put_line(lc_message);
   ELSE
    fnd_file.put_line (fnd_file.LOG,'Starting to write reversal transactions in the file '|| LC_ORDER_FILE_NAME);
   LOOP
   FETCH mps_cur INTO lc_message, ln_header_id;
   EXIT WHEN mps_cur%NOTFOUND;
      UTL_FILE.put_line (lc_filehandle, lc_message);
    dbms_output.put_line(lc_message);
      l_header_count := l_header_count+1;
 
      ln_party_id := NULL;
      
     OPEN MPS_PRE_ORDERS(ln_header_id);     
     IF MPS_PRE_ORDERS%NOTFOUND THEN
        UTL_FILE.put_line (lc_filehandle, lc_message);
        dbms_output.put_line(lc_message);
      ELSE
        fnd_file.put_line (fnd_file.LOG,'Starting to write reversal lines in the file '|| LC_ORDER_FILE_NAME);
        LOOP
          FETCH MPS_PRE_ORDERS INTO lc_message, lc_serialNo,lc_label,ln_party_id;
          EXIT WHEN MPS_PRE_ORDERS%NOTFOUND;
          UTL_FILE.put_line (lc_filehandle, lc_message);
          dbms_output.put_line(lc_message);
          l_line_count := l_line_count+1;
         
         BEGIN 
          update xx_cs_mps_device_details 
          set usage_billed = 'Y'
          where serial_no = lc_serialNo
          and supplies_label = lc_label;

         
          COMMIT;
         EXCEPTION 
           WHEN OTHERS THEN 
              fnd_file.put_line (fnd_file.LOG,'Error while updating MPS Details table' ||SQLERRM);
         END;
          
        END LOOP;
      END IF;
      CLOSE MPS_PRE_ORDERS;

      UPDATE XX_OM_HEADER_ATTRIBUTES_ALL
      SET MPS_EXT_FLAG = 'Y' ,
          MPS_EXT_DATE   = sysdate
      WHERE HEADER_ID  =ln_HEADER_ID ;

      -- reset the total_retail_count 

     UPDATE xx_cs_mps_device_details
      SET pre_total_ret_count = total_retail_count,
          total_retail_count = 0
      WHERE total_retail_count >0
      AND device_id IN ( SELECT DEVICE_ID
                         FROM xx_cs_mps_device_b
                         WHERE Party_id = ln_party_id);

      COMMIT;

    END LOOP;
   END IF;
  CLOSE MPS_CUR;



  -- MPS Return Orders reversals
  OPEN MPS_RET_ORDERS;
  IF MPS_RET_ORDERS%NOTFOUND THEN
    UTL_FILE.put_line (lc_filehandle, lc_message);
  ELSE
    fnd_file.put_line (fnd_file.LOG,'Starting to write Return order details in the file '|| LC_ORDER_FILE_NAME);
    LOOP
      FETCH MPS_RET_ORDERS INTO lc_message, ln_header_id;
      EXIT
    WHEN MPS_RET_ORDERS%NOTFOUND;
      UTL_FILE.put_line (lc_filehandle, lc_message);
      l_header_count := l_header_count+1;
      OPEN MPS_RET_LINES(LN_HEADER_ID);
      lc_message := NULL;
      IF MPS_RET_LINES%NOTFOUND THEN
        UTL_FILE.put_line (lc_filehandle, lc_message);
      ELSE
        LOOP
          FETCH MPS_RET_LINES INTO lc_message, lc_serialNo,lc_label,ln_return_id;
          EXIT
        WHEN MPS_RET_LINES%NOTFOUND;
          UTL_FILE.put_line (lc_filehandle, lc_message);
          l_line_count := l_line_count+1;
          
           UPDATE XX_OM_HEADER_ATTRIBUTES_ALL
            SET MPS_EXT_FLAG = 'Y' ,
              MPS_EXT_DATE   = sysdate
            WHERE HEADER_ID  =ln_return_id ;
      
        END LOOP;
      END IF;
      CLOSE MPS_RET_LINES;
    END LOOP;
  END IF;
  CLOSE MPS_RET_ORDERS;
  ------------------------------------
  UTL_FILE.FCLOSE(LC_FILEHANDLE);
  fnd_file.put_line (fnd_file.LOG,'File generated for ' || p_days || ' days');
  fnd_file.put_line (fnd_file.LOG,'Total Header records extracted '|| l_header_count);
  fnd_file.put_line (fnd_file.LOG,'Total Line records extracted '|| l_line_count);
  
  /* submit ftp concurrent program to ftp the file to DW server */
  FTP_FILE( p_file_name => lc_order_file_name
          , x_retcode   => p_retcode
          , x_errbuf    => p_errbuf
          );
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  UTL_FILE.FCLOSE(LC_FILEHANDLE);
  fnd_file.put_line (fnd_file.LOG,'Error in Order and Detail file generation' ||SQLERRM);
  p_retcode := 2;
END MAIN;

PROCEDURE FTP_FILE( p_file_name IN  VARCHAR2
                  , x_retcode   OUT NUMBER
                  , x_errbuf    OUT VARCHAR2
                  ) IS    

v_request_id NUMBER;

BEGIN

  v_request_id:= fnd_request.submit_request( application   => 'xxfin'
                                           , program       => 'XXCOMFTP'
                                           , description   => 'OD: Common Put Program'
                                           , start_time    => NULL
                                           , sub_request   => FALSE
                                           , argument1     => 'XX_MPS_ORD_DW_OUT'
                                           , argument2     => p_file_name
                                           , argument3     => NULL
                                           , argument4     => NULL
                                           , argument5     => NULL
                                           );
IF     v_request_id = 0 THEN
  x_retcode := 2;
  x_errbuf  := 'Request not submitted check file_name';
END IF;
                               
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  x_errbuf  := 'When Others Raised while submitting XXCOMFTP ' ||SQLERRM;
  fnd_file.put_line (fnd_file.LOG,'When Others Raised while submitting XXCOMFTP ' ||SQLERRM);
  
END    FTP_FILE;

END XX_MPS_ORDER_DW_OUT_PKG;
/************************************************************************************/
/
show errors;
exit;