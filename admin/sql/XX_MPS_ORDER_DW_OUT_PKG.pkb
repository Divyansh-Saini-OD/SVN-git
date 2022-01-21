create or replace
PACKAGE body XX_MPS_ORDER_DW_OUT_PKG
AS
  -- +====================================================================+
  -- |                  Office Depot                                      |
  -- |                  Oracle Consulting                                 |
  -- +====================================================================+
  -- | Name  : XX_MPS_ORDER_DW_OUT_PKG                                    |
  -- | Description  : Defect# 20726                                       |
  -- |                                                                    |
  -- |Change Record:                                                      |
  -- |===============                                                     |
  -- |Version    Date          Author      Remarks                        |
  -- |=======    ==========    ==========  ==========================     |
  -- |1.0        18-Oct-2012   Deepti S    Initial version - Defect# 20726|
  -- |1.1        03-APR-2013   Ray Strauss increased rounding procision   |
  -- +====================================================================+
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
  CURSOR c_order_lines(p_header_id NUMBER)
  IS
    SELECT '"I"|"'
      || ooh.header_id
      ||'"|"'
      || ooh.ORDER_NUMBER
      ||'"|"'
      || ool.LINE_ID
      ||'"|"'
      || OoL.LINE_NUMBER
      ||'"|"'
      || NVL(OoL.SHIPPED_QUANTITY,0)
      ||'"|"'
      || ROUND(NVL(xola.PO_COST,0),4)
      ||'"|"'
      || ROUND(NVL(OoL.UNIT_SELLING_PRICE,0),4)
      ||'"|"'
      || ROUND(NVL(OoL.TAX_VALUE,0),3)
      ||'"|"'
      || NVL(OoL.SHIP_FROM_ORG_ID,0)
      ||'"|"'
      || NVL(OoL.INVENTORY_ITEM_ID, 0)
      ||'"|"'
      || NVL(xola.ITEM_SOURCE, '')
      ||'"|"'
      || NVL(xola.taxable_flag,'')
      ||'"|"'
      || NVL(MSI.SEGMENT1,'')
      || '"' msg,
      ool.line_id
    FROM OE_ORDER_LINES_ALL ooL ,
      oe_order_headers_all ooh ,
      XX_OM_LINE_ATTRIBUTES_ALL xOLA ,
      MTL_SYSTEM_ITEMS_B MSI
    WHERE OoL.HEADER_ID       = ooH.HEADER_ID
    AND xola.LINE_ID          = OoL.LINE_ID
    AND MSI.INVENTORY_ITEM_ID = OoL.INVENTORY_ITEM_ID
    AND MSI.ORGANIZATION_ID   = OoL.SHIP_FROM_ORG_ID
    AND OOH.HEADER_ID         = P_HEADER_ID;
  --    AND NVL(xola.MPS_EXT_FLAG,'N') = 'N';
BEGIN
  --alter table xxom.XX_OM_HEADER_ATTRIBUTES_ALL add (mps_ext_flag CHAR(3), mps_ext_date DATE);
  --alter table xxom.XX_OM_LINE_ATTRIBUTES_ALL add (mps_ext_flag CHAR(3), mps_ext_date DATE);
  lc_message         := NULL;
  LC_ORDER_FILE_NAME := LC_ORDER_FILE_NAME || '_' || LC_TIMESTAMP ||'.dat';
  LC_FILEHANDLE      := UTL_FILE.FOPEN (LC_DIRPATH, LC_ORDER_FILE_NAME, LC_MODE);
  OPEN c_orders;
  IF c_orders%NOTFOUND THEN
    UTL_FILE.put_line (lc_filehandle, lc_message);
  ELSE
    fnd_file.put_line (fnd_file.LOG,'Starting to write order details in the file '|| LC_ORDER_FILE_NAME);
    LOOP
      FETCH c_orders INTO lc_message, ln_header_id;
      EXIT
    WHEN c_orders%NOTFOUND;
      UTL_FILE.put_line (lc_filehandle, lc_message);
      l_header_count := l_header_count+1;
      OPEN C_ORDER_LINES(LN_HEADER_ID);
      lc_message := NULL;
      IF C_ORDER_LINES%NOTFOUND THEN
        UTL_FILE.put_line (lc_filehandle, lc_message);
      ELSE
        LOOP
          FETCH c_order_lines INTO lc_message, ln_line_id;
          EXIT
        WHEN c_order_lines%NOTFOUND;
          UTL_FILE.put_line (lc_filehandle, lc_message);
          l_line_count := l_line_count+1;
          /* UPDATE XX_OM_LINE_ATTRIBUTES_ALL
          SET MPS_EXT_FLAG = 'Y'
          ,MPS_EXT_DATE = sysdate
          WHERE LINE_ID = ln_line_id ;  */
        END LOOP;
      END IF;
      CLOSE c_order_lines;
      UPDATE XX_OM_HEADER_ATTRIBUTES_ALL
      SET MPS_EXT_FLAG = 'Y' ,
        MPS_EXT_DATE   = sysdate
      WHERE HEADER_ID  =ln_HEADER_ID ;
    END LOOP;
  END IF;
  CLOSE c_orders;
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
IF 	v_request_id = 0 THEN
  x_retcode := 2;
  x_errbuf  := 'Request not submitted check file_name';
END IF;
							   
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  x_errbuf  := 'When Others Raised while submitting XXCOMFTP ' ||SQLERRM;
  fnd_file.put_line (fnd_file.LOG,'When Others Raised while submitting XXCOMFTP ' ||SQLERRM);
  
END	FTP_FILE;

END XX_MPS_ORDER_DW_OUT_PKG;
/
SHOW ERRORS PACKAGE BODY XX_MPS_ORDER_DW_OUT_PKG;