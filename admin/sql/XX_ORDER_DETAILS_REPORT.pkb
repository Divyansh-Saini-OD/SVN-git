CREATE OR REPLACE PACKAGE BODY "XX_ORDER_DETAILS_REPORT"
IS
  /*=============================================================================+
  |                Office Depot Inc. | Compucom CSI                              |
  |                                                                              |
  +============================================================================= +
  | FILENAME     :  XX_ORDER_DETAILS_REPORT.pkb                                |
  | DESCRIPTION  :  Order Details (Entered,Pending and Missing)                  |
  | Author       :  Anmol Patil                                                  |
  |                                                                              |
  | HISTORY                                                                      |
  | Version   Date        Author           Remarks                               |
  | ====   ==========  =============    =========================================|
  | 1.0    05-MAY-2021  Anmol Patil     Created New                              |
  | 1.1    17-JAN-2022  Vivek Kumar     Added Store number in Pending Report     |
  |                                      Added Report For Order's lines stuck in |
  |                                      the lines Interface                     |
  ==============================================================================*/
  isData      BOOLEAN := FALSE;
  V_STARTDATE DATE;
  V_ENDDATE   DATE;
  
  /*********************************************************************
  * Procedure used to out the text to the concurrent program.          *
  * Will log to dbms_output if request id is not set,                  *
  * else will log to concurrent program output file.                   *
  *********************************************************************/
  
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line (lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_out_msg;

/*********************************************************************
* Procedure To Fetch Order Details                                   *
**********************************************************************/

PROCEDURE Order_Details(
    ERR_BUFF OUT NOCOPY VARCHAR2 ,
    ERR_NUM OUT NOCOPY  NUMBER ,
    P_ORDER_EXTRACT IN VARCHAR2 ,
    P_START_DATE    IN VARCHAR2 ,
    P_END_DATE      IN VARCHAR2)
IS
  CURSOR C_Order_Pending(START_DATE DATE, END_DATE DATE)
  IS
    SELECT q1.org ORG_ID,
      q1.orig_sys# ORIG_SYS_REFERENCE,
      (SELECT f1.imp_file_name
        || ' '
        || f1.creation_date
      FROM xx_om_headers_attr_iface_all f1
      WHERE f1.orig_sys_document_ref = q1.orig_sys#
      AND ROWNUM                     = 1
      ) FILE_NAME_DATECREATED,
    q1.ORDER_TOTAL,
    q1.COGS_AMOUNT,
    q1.SALE_TAX_TOTAL,
    q1.ORDER_TOTAL_WITHOUT_TAX,
    q1.LOB,
    q1.ORDERED_DATE,
    q1.PROCESS_DATE
  FROM
    ( SELECT DISTINCT h.org_id org,
      h.orig_sys_document_ref orig_sys#,
      ROUND(f.order_total, 2) order_total,--, --al.ordered_quantity, l.average_cost--,
      NVL(SUM(al.shipped_quantity * l.average_cost),0) cogs_amount,--, sum(l.average_cost)
      NVL(SUM(al.tax_value), 0) "SALE_TAX_TOTAL",
      ( f.order_total - NVL(SUM(al.tax_value), 0) ) order_total_without_tax,
      DECODE(paid_at_store_id, NULL, DECODE(h.payment_term_id, 1111, 'DIRECT', 5, 'DIRECT', NULL, 'DIRECT', 'CONTRACT'), 'POS' ) lob,
      h.ordered_date,
      fh.process_date
    FROM oe_headers_iface_all h,
         oe_lines_iface_all al,
         xx_om_headers_attr_iface_all f,
         xx_om_lines_attr_iface_all l,
         xx_om_sacct_file_history fh
    WHERE 1                      = 1
    AND f.order_source_id        = h.order_source_id
    AND h.orig_sys_document_ref  = al.orig_sys_document_ref
    AND f.orig_sys_document_ref  = h.orig_sys_document_ref
    AND f.orig_sys_document_ref  = l.orig_sys_document_ref
    AND al.orig_sys_document_ref = l.orig_sys_document_ref
    AND al.orig_sys_line_ref     = l.orig_sys_line_ref
    AND fh.file_name             = f.imp_file_name
  --AND ( fh.process_date        >= NVL(START_DATE,fh.process_date) -- Removed as part of 1.1 Change 
  --AND fh.process_date          <= NVL(END_DATE,SYSDATE) ) -- Removed as part of 1.1 Change 
  --AND h.creation_date          < TRUNC(SYSDATE) -- Removed as part of 1.1 Change 
    AND LENGTH(h.orig_sys_document_ref) = 12
    AND NOT EXISTS
    (SELECT 1
      FROM oe_order_headers_all ooh
      WHERE ooh.orig_sys_document_ref = h.orig_sys_document_ref
      )
        GROUP BY h.org_id,
        h.orig_sys_document_ref,
        h.creation_date,
        f.imp_file_name,
        f.order_total,
        h.payment_term_id,
        paid_at_store_id,
        h.ordered_date,
        fh.process_date  
    UNION
    SELECT DISTINCT h.org_id org,
      h.orig_sys_document_ref orig_sys#,
      ROUND(f.order_total, 2),--, --al.ordered_quantity, l.average_cost--,
      NVL(SUM(al.shipped_quantity * l.average_cost), 0) "COGS_AMOUNT", --, sum(l.average_cost)
      NVL(SUM(al.tax_value), 0) "SALE_TAX_TOTAL",
      ( f.order_total - NVL(SUM(al.tax_value), 0) ) order_total_without_tax,
      'POS' lob,
      h.ordered_date,
      fh.process_date
    FROM oe_headers_iface_all h,
         oe_lines_iface_all al,
         xx_om_headers_attr_iface_all f,
         xx_om_lines_attr_iface_all l,
         xx_om_sacct_file_history fh
    WHERE 1                      = 1
    AND f.order_source_id        = h.order_source_id
    AND h.orig_sys_document_ref  = al.orig_sys_document_ref
    AND f.orig_sys_document_ref  = h.orig_sys_document_ref
    AND f.orig_sys_document_ref  = l.orig_sys_document_ref
    AND al.orig_sys_document_ref = l.orig_sys_document_ref
    AND al.orig_sys_line_ref     = l.orig_sys_line_ref
    AND fh.file_name             = f.imp_file_name
  --AND ( fh.process_date        >= NVL(START_DATE,fh.process_date) -- Removed as part of 1.1 Change 
  --AND fh.process_date          <= NVL(END_DATE,SYSDATE) ) -- Removed as part of 1.1 Change 
  --AND h.creation_date          < TRUNC(SYSDATE) -- Removed as part of 1.1 Change 
    AND LENGTH(h.orig_sys_document_ref) <> 12
    AND NOT EXISTS
      (SELECT 1
      FROM oe_order_headers_all ooh
      WHERE ooh.orig_sys_document_ref = h.orig_sys_document_ref
      )
    GROUP BY h.org_id,
      h.orig_sys_document_ref,
      h.creation_date,
      f.imp_file_name,
      f.order_total,
      h.payment_term_id,
      paid_at_store_id,
      h.ordered_date,
      fh.process_date
    ) q1 ORDER BY 10;
	
  --**************************CURSOR ENTERED ORDER*********************
  CURSOR C_Order_Entered(START_DATE DATE, END_DATE DATE)
  IS
    SELECT ORDER_NUMBER,
      PROCESS_DATE,
      ORDERED_DATE,
      ORDER_TOTAL,
      COGS_AMOUNT,
      SALE_TAX_TOTAL,
      ORDER_TOTAL_WITHOUT_TAX,
      LOB,
      FLOW_STATUS_CODE,
	  STORE_NUMBER  
    FROM
      (SELECT h.order_number,--'OM Holds'
        f.process_date,
        h.ordered_date,
        xh.order_total,
        NVL(SUM(al.shipped_quantity * l.average_cost), 0) "COGS_AMOUNT",
        NVL(SUM(al.tax_value), 0) sale_tax_total,
        ( xh.order_total - NVL(SUM(al.tax_value), 0)) order_total_without_tax,
        DECODE(xh.paid_at_store_id, NULL,DECODE(h.payment_term_id, 1111, 'DIRECT', 5,'DIRECT', NULL, 'DIRECT', 'CONTRACT'), 'POS') lob,
        h.flow_status_code,
		ordt.store_number
      FROM oe_order_headers_all h,
        xx_om_header_attributes_all xh,
        oe_order_lines_all al,
        xx_om_sacct_file_history f,
        xx_om_line_attributes_all l,
		xx_ar_order_receipt_dtl ordt  -- Added as part of 1.1 Change to add store Number
      WHERE h.header_id                   = xh.header_id
      AND al.line_id                      = l.line_id
      AND h.header_id                     = al.header_id
      AND h.flow_status_code              = 'ENTERED'-- IN('CLOSED',   'INVOICED')
      AND xh.imp_file_name                = f.file_name
      AND LENGTH(h.orig_sys_document_ref) = 12
	  AND h.orig_sys_document_ref = ordt.orig_sys_document_ref
      AND ( f.process_date                >= NVL(START_DATE,f.process_date)
      AND f.process_date                  <= NVL(END_DATE,SYSDATE))
        GROUP BY h.order_number,
        f.process_date,
        h.ordered_date,
        xh.order_total,
        h.payment_term_id,
        xh.paid_at_store_id,
        h.flow_status_code,
		ordt.store_number
    UNION
    SELECT
      /*+ parallel(4) */
      h.order_number,--'OM Holds'
      f.process_date,
      h.ordered_date,
      xh.order_total,
      NVL(SUM(al.shipped_quantity * l.average_cost), 0) "COGS_AMOUNT",
      NVL(SUM(al.tax_value), 0) sale_tax_total,
      ( xh.order_total - NVL(SUM(al.tax_value), 0) ) order_total_without_tax,
      'POS' lob,
      h.flow_status_code,
	  ordt.store_number
    FROM oe_order_headers_all h,
      xx_om_header_attributes_all xh,
      oe_order_lines_all al,
      xx_om_sacct_file_history f,
      xx_om_line_attributes_all l,
	  xx_ar_order_receipt_dtl ordt
    WHERE h.header_id                   = xh.header_id
    AND h.header_id                     = al.header_id
    AND al.line_id                      = l.line_id
    AND h.flow_status_code              = 'ENTERED'-- IN('CLOSED',   'INVOICED')
    AND xh.imp_file_name                = f.file_name
	AND h.orig_sys_document_ref = ordt.orig_sys_document_ref
    AND LENGTH(h.orig_sys_document_ref) = 20 -- <> 12
    AND ( f.process_date                >= NVL(START_DATE,f.process_date)
    AND f.process_date                  <= NVL(END_DATE,SYSDATE) )
    GROUP BY h.order_number,
      f.process_date,
      h.ordered_date,
      xh.order_total,
      h.payment_term_id,
      xh.paid_at_store_id,
      h.flow_status_code,
	  ordt.store_number
      ) q1
    ORDER BY 2,
      3;
    --**************************CURSOR MISSING POS*********************
    CURSOR C_Missing_POS(START_DATE DATE, END_DATE DATE)
    IS
      SELECT h.ORDER_NUMBER,--'OM Holds'
        f.PROCESS_DATE,
        h.ORDERED_DATE,
        xh.ORDER_TOTAL,
        NVL(SUM(al.shipped_quantity * l.average_cost), 0) "COGS_AMOUNT",
        NVL(SUM(al.tax_value),0) SALE_TAX_TOTAL,
        ( xh.order_total - NVL(SUM(al.tax_value), 0) ) ORDER_TOTAL_WITHOUT_TAX,
        'POS' LOB,
        h.FLOW_STATUS_CODE
      FROM oe_order_headers_all h,
           xx_om_header_attributes_all xh,
           oe_order_lines_all al,
           xx_om_sacct_file_history f,
           xx_om_line_attributes_all l
      WHERE h.header_id       = xh.header_id
      AND h.header_id         = al.header_id
      AND al.line_id          = l.line_id
      AND h.flow_status_code != 'ENTERED'-- IN('CLOSED',   'INVOICED')
      AND xh.imp_file_name    = f.file_name
    --AND LENGTH(h.orig_sys_document_ref) =20 -- <> 12
      AND LENGTH(order_number) = 12
      AND ( h.ordered_date >= NVL(START_DATE,h.ordered_date)
      AND h.ordered_date   <= NVL(END_DATE,SYSDATE) )
      AND EXISTS
        (SELECT 1
        FROM xx_ra_int_lines_all a
        WHERE a.interface_line_attribute1 = h.order_number
        )
        GROUP BY h.order_number,
        f.process_date,
        h.ordered_date,
        xh.order_total,
        h.payment_term_id,
        xh.paid_at_store_id,
        h.flow_status_code
    UNION
	  (SELECT h.ORDER_NUMBER,--'OM Holds'
        f.PROCESS_DATE,
        h.ORDERED_DATE,
        xh.ORDER_TOTAL,
        NVL(SUM(al.shipped_quantity * l.average_cost), 0) "COGS_AMOUNT",
        NVL(SUM(al.tax_value),0) SALE_TAX_TOTAL,
        ( xh.order_total - NVL(SUM(al.tax_value), 0) ) ORDER_TOTAL_WITHOUT_TAX,
        'POS' LOB,
        h.FLOW_STATUS_CODE
      FROM oe_order_headers_all h,
           xx_om_header_attributes_all xh,
           oe_order_lines_all al,
           xx_om_sacct_file_history f,
           xx_om_line_attributes_all l
      WHERE h.header_id       = xh.header_id
      AND h.header_id         = al.header_id
      AND al.line_id          = l.line_id
      AND h.flow_status_code != 'ENTERED'-- IN('CLOSED',   'INVOICED')
      AND xh.imp_file_name    = f.file_name
    --AND LENGTH(h.orig_sys_document_ref) =20 -- <> 12
      AND LENGTH(order_number) = 20 
      AND ( h.ordered_date >= NVL(START_DATE,h.ordered_date)
      AND h.ordered_date   <= NVL(END_DATE,SYSDATE) )
      AND EXISTS
        (SELECT 1
        FROM xx_ra_int_lines_all a
        WHERE a.interface_line_attribute1 = h.order_number
        )
    GROUP BY h.order_number,
      f.process_date,
      h.ordered_date,
      xh.order_total,
      h.payment_term_id,
      xh.paid_at_store_id,
      h.flow_status_code);
	  
	--**************************CURSOR Orders Without Lines*********************  
      --Added as part of 1.1 Change
	CURSOR C_Order_Without_lines(START_DATE DATE, END_DATE DATE)
    IS 
	 SELECT distinct 
       ooha.order_number
      ,f.process_date
      ,ooha.ordered_date
      ,ooha.creation_date
      ,xxohaa.order_total
      ,SUM(oli.shipped_quantity) shipped_quantity
      ,NVL(SUM(oli.tax_value), 0) sale_tax_total
      ,xxohaa.order_total - NVL(SUM(oli.tax_value), 0) order_total_without_tax
      ,DECODE(xxohaa.paid_at_store_id,NULL,DECODE(ooha.payment_term_id,1111, 'DIRECT',5,'DIRECT',NULL, 'DIRECT', 'CONTRACT'),'POS') lob
        ,ooha.flow_status_code
     FROM xx_om_header_attributes_all xxohaa,
          oe_order_headers_all ooha,
          oe_lines_iface_all oli,
          xx_om_sacct_file_history f
     WHERE 1=1
     AND ooha.header_id = xxohaa.header_id
     AND ooha.orig_sys_document_ref = oli.orig_sys_document_ref
     AND f.file_name = xxohaa.imp_file_name
  -- AND ooha.creation_date>=sysdate-30
     AND ( ooha.creation_date>= NVL(START_DATE,f.process_date)
     AND ooha.creation_date<= NVL(END_DATE,SYSDATE))
     AND ooha.orig_sys_document_ref IN (SELECT DISTINCT olia.orig_sys_document_ref
                                    FROM OE_LINES_IFACE_ALL olia
                                    WHERE 1=1
                                    AND NOT EXISTS (SELECT ohia.orig_sys_document_ref    
                                                     FROM OE_HEADERS_IFACE_ALL ohia
                                                     WHERE 1=1
                                                     AND ohia.orig_sys_document_ref = olia.orig_sys_document_ref
                                                    )
                                    )
    GROUP BY ooha.order_number
	    ,f.process_date
		,ooha.ordered_date
        ,ooha.creation_date
		,xxohaa.order_total
		,ooha.payment_term_id
		,xxohaa.paid_at_store_id
        ,ooha.flow_status_code
		,oli.shipped_quantity
        Order by ooha.creation_date asc
;

    --********************************************************
  BEGIN
    V_STARTDATE := fnd_date.canonical_to_date (P_START_DATE);
    V_ENDDATE   := fnd_date.canonical_to_date (P_END_DATE);
    --FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '<ROWSET>');
    print_out_msg('OD Order Details Report');
    print_out_msg('=======================');
    print_out_msg('                       ');
    BEGIN
      IF(P_ORDER_EXTRACT = 'ORDERPENDING') THEN
	    print_out_msg('Orders Pending Report');
		print_out_msg('=====================');
        print_out_msg(RPAD('Org Id',10)||' '||RPAD('Orig_System_Reference',21)||' '||RPAD('SAS File Name                  Creation Date',50)||' '||RPAD('Order Total',15)||' '||RPAD('COGS Amount',15)||' '||RPAD('Sales Tax Total',16)||' '||RPAD('Order Total Without Tax',25)||' '||RPAD('LOB',8)||' '||RPAD('Ordered Date',15)||' '||RPAD('Process Date',15));
        print_out_msg(RPAD('=',10,'=')||' '||RPAD('=',21,'=')||' '||RPAD('=',50,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',16,'=')||' '||RPAD('=',25,'=')||' '||RPAD('=',8,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'='));
        FOR c_var IN C_Order_Pending(V_STARTDATE, V_ENDDATE)
        LOOP
          BEGIN
            isData := true;
            print_out_msg(RPAD(c_var.ORG_ID,10)||' '|| RPAD(c_var.ORIG_SYS_REFERENCE,21)||' '|| RPAD(c_var.FILE_NAME_DATECREATED,50)||' '|| RPAD(c_var.ORDER_TOTAL,15)||' '|| RPAD(c_var.COGS_AMOUNT,15)||' '|| RPAD(c_var.SALE_TAX_TOTAL,16)||' '|| RPAD(c_var.ORDER_TOTAL_WITHOUT_TAX,25)||' '|| RPAD(c_var.LOB,8)||' '|| RPAD(c_var.ORDERED_DATE,15)||' '|| RPAD(c_var.PROCESS_DATE,15));
          END;
        END LOOP;
        IF(isData = false) THEN
          BEGIN
		    print_out_msg('                                                 ');
		    print_out_msg('=================================================');
            print_out_msg('No Pending Orders listed for the given date range');
			print_out_msg('=================================================');
          END;
        END IF;
      END IF;
    END;
    BEGIN
      IF(P_ORDER_EXTRACT = 'ORDERENTERED') THEN
	    print_out_msg('Orders Entered Report');
		print_out_msg('=====================');
        print_out_msg(RPAD('Order Number',15)||' '||RPAD('Process Date',15)||' '||RPAD('Ordered date',15)||' '||RPAD('Order Total',15)||' '||RPAD('COGS Amount',15)||' '||RPAD('Sales Tax Total',16)||' '||RPAD('Order Total Without Tax',25)||' '||RPAD('LOB',8)||' '||RPAD('Flow Status Code',20)||' '||RPAD('Store Number',25));
        print_out_msg(RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',16,'=')||' '||RPAD('=',25,'=')||' '||RPAD('=',8,'=')||' '||RPAD('=',20,'=')||' '||RPAD('=',15,'='));
		FOR c_var IN C_Order_Entered(V_STARTDATE, V_ENDDATE)
        LOOP
          BEGIN
            isData := true;
            print_out_msg(RPAD(c_var.ORDER_NUMBER,15)||' '||RPAD(c_var.PROCESS_DATE,15)||' '|| RPAD(c_var.ORDERED_DATE,15)||' '|| RPAD(c_var.ORDER_TOTAL,15)||' '|| RPAD(c_var.COGS_AMOUNT,15)||' '|| RPAD(c_var.SALE_TAX_TOTAL,16)||' '|| RPAD(c_var.ORDER_TOTAL_WITHOUT_TAX,25)||' '|| RPAD(c_var.LOB,8)||' '|| RPAD(c_var.FLOW_STATUS_CODE,20)||' '||RPAD(c_var.Store_Number,20));
          END;
        END LOOP;
        IF(isData = false) THEN
          BEGIN
		    print_out_msg('                                                       ');
		    print_out_msg('=======================================================');
            print_out_msg('No Orders are in Entered State for the given date range');
			print_out_msg('=======================================================');
          END;
        END IF;
      END IF;
    END;
    BEGIN
      IF(P_ORDER_EXTRACT = 'MISSINGPOS') THEN
	    print_out_msg('Missing POS Report');
		print_out_msg('==================');
        print_out_msg(RPAD('Order Number',15)||' '||RPAD('Process Date',15)||' '||RPAD('Ordered date',15)||' '||RPAD('Order Total',15)||' '||RPAD('COGS Amount',15)||' '||RPAD('Sales Tax Total',16)||' '||RPAD('Order Total Without Tax',25)||' '||RPAD('LOB',8)||' '||RPAD('Flow Status Code',20));
        print_out_msg(RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',16,'=')||' '||RPAD('=',25,'=')||' '||RPAD('=',8,'=')||' '||RPAD('=',20,'='));
        FOR c_var IN C_Missing_POS(V_STARTDATE, V_ENDDATE)
        LOOP
          BEGIN
            isData := true;
            print_out_msg(RPAD(c_var.ORDER_NUMBER,15)||' '|| RPAD(c_var.PROCESS_DATE,15)||' '|| RPAD(c_var.ORDERED_DATE,15)||' '|| RPAD(c_var.ORDER_TOTAL,15)||' '|| RPAD(c_var.COGS_AMOUNT,15)||' '|| RPAD(c_var.SALE_TAX_TOTAL,16)||' '|| RPAD(c_var.ORDER_TOTAL_WITHOUT_TAX,25)||' '|| RPAD(c_var.LOB,8)||' '|| RPAD(c_var.FLOW_STATUS_CODE,15));
          END;
        END LOOP;
        IF(isData = false) THEN
          BEGIN
		    print_out_msg('                                              ');
		    print_out_msg('==============================================');
            print_out_msg('No Missing POS Orders for the given date range');
			print_out_msg('==============================================');
          END;
        END IF;
      END IF;
    END;
	BEGIN
       IF(P_ORDER_EXTRACT = 'ORDER WITHOUT LINES') THEN
	     print_out_msg('Orders Created with Headers and Lines stuck in Interface');
		print_out_msg('==================');
        print_out_msg(RPAD('Order Number',15)||' '||RPAD('Process Date',15)||' '||RPAD('Ordered date',15)||' '||RPAD('Creation Date',15)||' '||RPAD('Order Total',15)||' '||RPAD('shipped Quantity',15)||' '||RPAD('Sales Tax Total',16)||' '||RPAD('Order Total Without Tax',25)||' '||RPAD('LOB',8)||' '||RPAD('Flow Status Code',20));
        print_out_msg(RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',15,'=')||' '||RPAD('=',16,'=')||' '||RPAD('=',25,'=')||' '||RPAD('=',8,'=')||' '||RPAD('=',20,'='));
        FOR c_var IN C_Order_Without_lines(V_STARTDATE, V_ENDDATE)
        LOOP
          BEGIN
            isData := true;
            print_out_msg(RPAD(c_var.ORDER_NUMBER,15)||' '||RPAD(c_var.PROCESS_DATE,15)||' '|| RPAD(c_var.ORDERED_DATE,15)||' '||RPAD(c_var.Creation_Date,15)||' '||RPAD(c_var.ORDER_TOTAL,15)||' '||RPAD(c_var.shipped_Quantity,15)||' '||RPAD(c_var.SALE_TAX_TOTAL,16)||' '||RPAD(c_var.ORDER_TOTAL_WITHOUT_TAX,25)||' '||RPAD(c_var.LOB,8)||' '|| RPAD(c_var.FLOW_STATUS_CODE,20));
          END;
        END LOOP;
        IF(isData = false) THEN
          BEGIN
		    print_out_msg('                                              ');
		    print_out_msg('==============================================');
            print_out_msg('No Orders Created with Headers and Lines stuck in Interface given date range');
			print_out_msg('==============================================');
          END;
        END IF;
      END IF;
    END;
    COMMIT;
  END;
END XX_ORDER_DETAILS_REPORT;
/