CREATE OR REPLACE PACKAGE BODY "APPS"."XX_PO_WMS_SUPERTRANS_OB_PKG" 
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_WMS_SUPERTRANS_OB_PKG                                                     |
-- |  RICE ID 	 :  E3522 Trade Match SuperTrans outbound to WMS    	                        |
-- |  Description:         								        								|
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         09-Oct-17    Madhu Bolli      Initial version                                  |
-- | 1.1         16-Aug-18    Antonio Morales  NAIT-56488 Change PO Number in outbound file     |
-- |                                           to 9 digits                                      |
-- | 1.2         27-AUG-18    Jitendra A        NAIT-49192 added INSERT STATEMEMT to create new  |
-- |                                           record for cancelled invoices to negate quantity |
-- |                                           feed for WMS   									|
-- | 1.3         7-Mar-2019   Raj Jose         NAIT-87118 Performance Supertrans Outbound Program |
-- +============================================================================================+

gc_debug 	VARCHAR2(2) := 'N';
gn_request_id   fnd_concurrent_requests.request_id%TYPE;
gn_user_id      fnd_concurrent_requests.requested_by%TYPE;
gn_login_id    	NUMBER;



/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE print_debug_msg (p_message   IN VARCHAR2,
                           p_force     IN BOOLEAN DEFAULT FALSE)
IS
   lc_message   VARCHAR2 (4000) := NULL;
BEGIN
   IF (gc_debug = 'Y' OR p_force)
   THEN
       lc_Message := P_Message;
       fnd_file.put_line (fnd_file.log, lc_Message);

       IF (   fnd_global.conc_request_id = 0
           OR fnd_global.conc_request_id = -1)
       THEN
          dbms_output.put_line (lc_message);
       END IF;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
       NULL;
END print_debug_msg;

/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg (p_message IN VARCHAR2)
IS
   lc_message   VARCHAR2 (4000) := NULL;
BEGIN
   lc_message := p_message;
   fnd_file.put_line (fnd_file.output, lc_message);

   IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
   THEN
      dbms_output.put_line (lc_message);
   END IF;
EXCEPTION
WHEN OTHERS
THEN
   NULL;
END print_out_msg;

 -- +============================================================================================+
 -- |  Name	  : populate_supertrans_file                                                         |
 -- |  Description: This procedure retrieves data from table an d writes data to the outbound file|
 -- =============================================================================================|
PROCEDURE populate_supertrans_file(p_errbuf     OUT  VARCHAR2
                         ,p_retcode      OUT  NUMBER
                         ,p_batch_id     IN   NUMBER
                      	 ,p_debug        IN   VARCHAR2)
IS

	CURSOR c_get_st_data(c_batch_id NUMBER)
	IS
	SELECT lpad(substr(RECEIPT_NUM,5,length(RECEIPT_NUM)-2),8,'0') RECEIPT_NUM   -- KEYREC is extracting
		  ,ITEM_NAME
		  ,RECEIPT_LINE_QTY
		  ,INV_LINE_QTY
		  ,PO_LINE_COST
		  ,INV_LINE_COST
		  ,VENDOR_NUMBER
		  ,RECORD_TYPE
		  ,SHIP_LOCATION
		  ,PO_NUMBER
		  ,CURRENCY
		  ,COMPANY
		  ,PO_LINE_NUM
		  ,SEQ_NO
	FROM XX_PO_WMS_SUPERTRANS_OB
	WHERE batch_id = c_batch_id;

    TYPE LC_ST_DATA_TAB IS TABLE OF c_get_st_data%ROWTYPE
						INDEX BY PLS_INTEGER;
    LC_ST_DATA   LC_ST_DATA_TAB;

	lc_file_handle      UTL_FILE.file_type;
	lv_line_count	    NUMBER;
	l_file_path			VARCHAR(200);
	l_file_name			VARCHAR2(100);
    lv_col_title        VARCHAR2(1000);
    lc_errormsg         VARCHAR2(1000);
	ln_conc_file_copy_request_id	NUMBER;
	lc_dest_file_name   VARCHAR2(200);
	lc_source_file_name	VARCHAR2(200);

	BEGIN
    print_debug_msg('Begin - populate_supertrans_file', TRUE);
		gc_debug	  := p_debug;
		gn_request_id := fnd_global.conc_request_id;
		gn_user_id    := fnd_global.user_id;
		gn_login_id   := fnd_global.login_id;

		lv_line_count := 0;

        BEGIN
         SELECT directory_path
           INTO l_file_path
           FROM dba_directories
          WHERE directory_name = 'XXFIN_PO_OUTBOUND';
        EXCEPTION
         WHEN OTHERS
         THEN
            l_file_path := NULL;
        END;


		l_file_name :=
               'XX_PO_WMS_SUPERTRANS_'
            || TO_CHAR(SYSDATE, 'DDMONYYYYHH24MISS')
            ||'_'
            || gn_request_id
            || '.txt';


    lc_file_handle := UTL_FILE.fopen('XXFIN_PO_OUTBOUND', l_file_name, 'W', 32767);

    print_out_msg('Filename is :' || l_file_name);
	print_out_msg('Unix File Path is :' || l_file_path);

	print_debug_msg ('File Name : '||l_file_name, TRUE);
	print_debug_msg ('File Path : '||l_file_path, TRUE);


    lv_col_title :=
            'ST-KEYREC'
         || ','||
         'ST-SKU'
         || ','||
         'ST-ORIG-QTY'
         || ','||
         'ST-NEW-QTY'
         || ','||
         'ST-ORIG-COST'
         || ','||
         'ST-NEW-COST'
         || ','||
         'ST-VENDOR'
         || ','||
         'ST-REC-TYPE'
         || ','||
         'ST-LOCATION'
         || ','||
         'ST-PO-NUMBER'
         || ','||
         'ST-CURRENCY'
         || ','||
         'ST-COMPANY'
         || ','||
         'ST-PO-LINE'
         || ','||
         'ST-SEQ-NBR';

	  -- UTL_FILE.put_line(lc_file_handle,lv_col_title);

	  print_debug_msg (lv_col_title, TRUE);



      OPEN c_get_st_data(p_batch_id);
      FETCH c_get_st_data BULK COLLECT INTO LC_ST_DATA;
      CLOSE c_get_st_data;

	  IF LC_ST_DATA.COUNT > 0 THEN
		  FOR l_rec IN LC_ST_DATA.FIRST..LC_ST_DATA.LAST
		  LOOP
			 lv_line_count := lv_line_count + 1;
			  UTL_FILE.put_line(lc_file_handle,
												lpad(LC_ST_DATA(l_rec).RECEIPT_NUM,8,'0')||
												lpad(LC_ST_DATA(l_rec).ITEM_NAME,7,'0')||
												lpad(LC_ST_DATA(l_rec).RECEIPT_LINE_QTY,9,'0')||
												lpad(LC_ST_DATA(l_rec).INV_LINE_QTY,9,'0')||
												lpad(to_char(LC_ST_DATA(l_rec).PO_LINE_COST,'fm999999999.000'), 13, '0')||
												lpad(to_char(LC_ST_DATA(l_rec).INV_LINE_COST,'fm999999999.000'), 13, '0')||
												lpad(LC_ST_DATA(l_rec).VENDOR_NUMBER,9,'0')||
												LC_ST_DATA(l_rec).RECORD_TYPE||
												lpad(LC_ST_DATA(l_rec).SHIP_LOCATION,5,'0')||
												lpad(substr(LC_ST_DATA(l_rec).PO_NUMBER,1,instr(LC_ST_DATA(l_rec).PO_NUMBER,'-')-1),9,'0')|| -- Version 1.1 NAIT-56488
												lpad(LC_ST_DATA(l_rec).CURRENCY,2,'0')||
												lpad(LC_ST_DATA(l_rec).COMPANY,4,'0')||
												lpad(LC_ST_DATA(l_rec).PO_LINE_NUM,3,'0')||
												lpad(LC_ST_DATA(l_rec).SEQ_NO,2,'0')
											);

			print_debug_msg (LC_ST_DATA(l_rec).RECEIPT_NUM|| ','||
												LC_ST_DATA(l_rec).ITEM_NAME|| ','||
												LC_ST_DATA(l_rec).RECEIPT_LINE_QTY|| ','||
												LC_ST_DATA(l_rec).INV_LINE_QTY|| ','||
												LC_ST_DATA(l_rec).PO_LINE_COST|| ','||
												LC_ST_DATA(l_rec).INV_LINE_COST|| ','||
												LC_ST_DATA(l_rec).VENDOR_NUMBER|| ','||
												LC_ST_DATA(l_rec).RECORD_TYPE|| ','||
												LC_ST_DATA(l_rec).SHIP_LOCATION|| ','||
												LC_ST_DATA(l_rec).PO_NUMBER|| ','||
												LC_ST_DATA(l_rec).CURRENCY|| ','||
												LC_ST_DATA(l_rec).COMPANY|| ','||
												LC_ST_DATA(l_rec).PO_LINE_NUM|| ','||
												LC_ST_DATA(l_rec).SEQ_NO
											, TRUE);

		  END LOOP;
    END IF;

    UTL_FILE.fclose(lc_file_handle);

	-- Archive the file

	print_debug_msg('Calling the Common File Copy to archive this OutBound file to Archive folder',TRUE);

	lc_dest_file_name            := '$XXFIN_ARCHIVE/outbound/' ||l_file_name;
	lc_source_file_name			 := l_file_path||'/' ||l_file_name;

	ln_conc_file_copy_request_id := fnd_request.submit_request('XXFIN',
															 'XXCOMFILCOPY',
															 '',
															 '',
															 FALSE,
															 lc_source_file_name, 		   --Source File Name
															 lc_dest_file_name,            --Dest File Name
															 '', '', 'N'                   --Deleting the Source File
															);


	print_debug_msg('Request Id of Common Copy , to archive, is '||ln_conc_file_copy_request_id,TRUE);
	COMMIT;

    print_debug_msg('End - populate_supertrans_file', TRUE);
    EXCEPTION
      WHEN UTL_FILE.access_denied
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' access_denied :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
		 print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.delete_failed
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' delete_failed :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.file_open
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' file_open :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.internal_error
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' internal_error :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_filehandle
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' invalid_filehandle :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_filename
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' invalid_filename :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_maxlinesize
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' invalid_maxlinesize :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_mode
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' invalid_mode :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_offset
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' invalid_offset :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_operation
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' invalid_operation :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.invalid_path
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' invalid_path :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.read_error
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' read_error :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.rename_failed
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' rename_failed :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;

      WHEN UTL_FILE.write_error
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' write_error :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg (lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;
      WHEN OTHERS
      THEN
         lc_errormsg :=
            (   'Supertrans Outbound Report Generation Errored :- '
             || ' OTHERS :: '
             || SUBSTR (SQLERRM, 1, 3800)
             || SQLCODE
            );
         print_debug_msg ('End - populate_supertrans_file - '||lc_errormsg, TRUE);
         UTL_FILE.fclose_all;
         lc_file_handle := UTL_FILE.fopen (l_file_path, l_file_name, 'W', 32767);
         UTL_FILE.fclose(lc_file_handle);

         p_errbuf := SUBSTR (SQLERRM, 1, 150);
         p_retcode := 2;
END populate_supertrans_file;

 -- +============================================================================================+
 -- |  Name	  : adj_cost_generate                                                         		 |
 -- |  Description: This procedure generates data for Adjust Cost and writes to a staging table  |
 -- =============================================================================================|
PROCEDURE adj_cost_generate(p_errbuf      OUT  VARCHAR2
                         ,p_retcode       OUT  NUMBER
                         ,p_batch_id      IN   NUMBER
                         ,p_acct_run_date IN   DATE
                      	 ,p_debug         IN   VARCHAR2)
 IS
	CURSOR c_list_po_adj_price_var(c_account_date DATE)
	IS
		WITH accounted_invoices_a AS
		(
			SELECT /*+ index(XAH XX_XLA_AE_HEADERS_N11) use_nl(XAH XTE) */ 
				   AIA1.INVOICE_ID ,
				   AIA1.INVOICE_NUM ,
				   AIA1.INVOICE_CURRENCY_CODE ,
				   AIA1.VENDOR_ID ,
				   AIA1.VENDOR_SITE_ID
			FROM xla_ae_headers XAH, 
				 --xla_Events xev,  /*raj NAIT-87118 commented redundant */
				  xla_transaction_entities XTE
				 ,AP_INVOICES_ALL AIA1
			WHERE   xah.application_id = 200
				--and trunc(xah.gl_transfer_date) = trunc(c_account_date)
				AND xah.gl_transfer_date >= trunc(c_account_date) AND xah.gl_transfer_date < ( trunc(c_account_date) + 1 ) /*Raj NAIT-87118 to utilize the new XX_XLA_AE_HEADERS_N11 index */ 
				AND XAH.EVENT_TYPE_CODE         = 'INVOICE VALIDATED' /*raj added */ 
				AND XAH.gl_transfer_Status_code = 'Y' -- Raj NAIT-87118 to consider only gl_transferred records
				 --AND XEV.APPLICATION_ID          = 200
				 --AND XEV.EVENT_TYPE_CODE         = 'INVOICE VALIDATED'
				  --AND XEV.PROCESS_STATUS_CODE     = 'P'
				AND XAH.LEDGER_ID               = XTE.LEDGER_ID
				AND XAH.entity_id               = xte.entity_id 
				--AND XAH.EVENT_ID              = XEV.EVENT_ID
				AND XTE.ENTITY_CODE             = 'AP_INVOICES'
				--AND XEV.ENTITY_ID             = XTE.ENTITY_ID
				AND XTE.APPLICATION_ID          = 200
				AND XTE.ENTITY_CODE             = 'AP_INVOICES'
				AND AIA1.INVOICE_ID             = XTE.SOURCE_ID_INT_1
				AND AIA1.CANCELLED_DATE        IS NULL
				AND EXISTS
				(
					SELECT 'x'
					FROM XX_FIN_TRANSLATEVALUES TV ,
					  XX_FIN_TRANSLATEDEFINITION TD
					WHERE TD.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
					AND TV.TRANSLATE_ID       = TD.TRANSLATE_ID
					AND TV.ENABLED_FLAG       ='Y'
					AND SYSDATE BETWEEN TV.START_DATE_ACTIVE AND NVL(TV.END_DATE_ACTIVE,SYSDATE)
					AND TV.TARGET_VALUE1=AIA1.SOURCE
				)
				AND NOT EXISTS
				(
					SELECT 'x'
					FROM XX_PO_WMS_SUPERTRANS_OB XPWS
					WHERE XPWS.INVOICE_ID = AIA1.INVOICE_ID
					AND XPWS.RECORD_TYPE  = 'A'
				)
		)
	SELECT 
		   PHA.PO_HEADER_ID ,
		   PHA.SEGMENT1 PO_NUMBER ,
		   PLA.PO_LINE_ID ,
		  (SELECT MSI.SEGMENT1 
		   FROM  MTL_SYSTEM_ITEMS_B MSI
		   WHERE MSI.INVENTORY_ITEM_ID      = AILA.INVENTORY_ITEM_ID
		   AND   MSI.ORGANIZATION_ID         =441 )   ITEM_SKU,
		   PLA.UNIT_PRICE PO_UNIT_PRICE ,
		   LPAD(LTRIM(ASSA.VENDOR_SITE_CODE_ALT, '0'), 9, '0') SUPPLIER_SITE_CODE ,
		   LPAD(LTRIM(HRL.ATTRIBUTE1,'0'), 4, '0') SHIP_TO_LOCATION_CODE ,
		   PLA.LINE_NUM ,
		   SUM(1) OVER (PARTITION BY AILA.INVOICE_ID, AILA.LINE_NUMBER, RSL.PO_LINE_ID) RECEIPT_LINES_FOR_PO ,
		   SUM(1) OVER (PARTITION BY PLA.PO_LINE_ID, RSL.SHIPMENT_HEADER_ID, RSL.SHIPMENT_LINE_ID) INV_LINES_FOR_PO ,
		   AILA.QUANTITY_INVOICED ,
		   AILA.UNIT_PRICE INVOICE_UNIT_PRICE ,
		   AILA.LINE_NUMBER AS INV_LINE_NUM ,
		   AIA.INVOICE_ID ,
		   AIA.INVOICE_CURRENCY_CODE ,
		   AIA.INVOICE_NUM ,
		   NULL ORIG_QUANTITY ,
		   NULL NEW_QUANTITY ,
		   NULL RECEIPT_NUM ,
		   NULL SHIPMENT_LINE_ID ,
		   'N' MATCHED_LINE
	FROM AP_INVOICE_LINES_ALL AILA ,
		 ACCOUNTED_INVOICES_A AIA,
		 PO_LINES_ALL PLA,
		 PO_HEADERS_ALL PHA,
		 AP_SUPPLIER_SITES_ALL ASSA,
		 RCV_TRANSACTIONS RT ,
		 RCV_SHIPMENT_LINES RSL,
		 HR_LOCATIONS_ALL HRL
		 --MTL_SYSTEM_ITEMS_B MSI  /*Raj NAIT-87118 moved to select as its impacting the execution plan */
		 --RCV_SHIPMENT_HEADERS RSH /*Raj NAIT-87118  table not required redundant */
	WHERE 1                        =1
	AND AILA.INVOICE_ID            = AIA.INVOICE_ID
	AND AILA.LINE_TYPE_LOOKUP_CODE = 'ITEM'
	AND AILA.DISCARDED_FLAG        = 'N'
	AND (AILA.CANCELLED_FLAG      IS NULL
	OR AILA.CANCELLED_FLAG         = 'N')
	AND PLA.PO_LINE_ID             = AILA.PO_LINE_ID
	AND (PLA.UNIT_PRICE    -AILA.UNIT_PRICE)<>0
	AND PLA.PO_HEADER_ID           = PHA.PO_HEADER_ID
	AND ASSA.VENDOR_SITE_ID        = PHA.VENDOR_SITE_ID
	AND ASSA.ATTRIBUTE8 LIKE 'TR%'
	AND RT.PO_LINE_ID              = PLA.PO_LINE_ID
	AND RT.SHIPMENT_LINE_ID        = RSL.SHIPMENT_LINE_ID
	AND RT.TRANSACTION_TYPE        = 'RECEIVE'
	--AND RSL.SHIPMENT_HEADER_ID     = RSH.SHIPMENT_HEADER_ID
	AND HRL.LOCATION_ID            = PHA.SHIP_TO_LOCATION_ID
	--AND MSI.INVENTORY_ITEM_ID      = AILA.INVENTORY_ITEM_ID /*moved to select as its impacting the execution plan */
	--AND MSI.ORGANIZATION_ID         =441 /*moved to select as its impacting the execution plan */
	AND NOT EXISTS
	  (
	   SELECT /*+ index(AIA2 AP_INVOICES_N6) */  '1'
	   FROM AP_INVOICES_ALL AIA2,
			AP_INVOICE_LINES_ALL AILA2
	   WHERE AILA2.INVOICE_ID = AIA2.INVOICE_ID
	   AND AIA2.INVOICE_NUM   = AIA.INVOICE_NUM||'DM'
	   AND AIA2.INVOICE_TYPE_LOOKUP_CODE                             ='DEBIT'
	   AND AIA2.VENDOR_ID                                            = AIA.VENDOR_ID     
	   AND AIA2.VENDOR_SITE_ID                                       = AIA.VENDOR_SITE_ID
	   AND AILA2.ATTRIBUTE5                                          = AILA.LINE_NUMBER
	   AND ((PLA.UNIT_PRICE-AILA.UNIT_PRICE)*AILA.QUANTITY_INVOICED) = AILA2.AMOUNT
	  )
	AND 1=1
	ORDER BY PLA.PO_LINE_ID,
	  AIA.INVOICE_NUM,
	  AILA.LINE_NUMBER;

	/** RE-VERIFY this query to add more criteria
		Like cancel lines etc..,
	**/
	CURSOR c_po_recpt_det(c_po_line_id NUMBER)
	IS
	(SELECT
		 'U' line_status
		,xpst.po_line_id
		,xpst.shipment_header_id
		,xpst.receipt_num
		,xpst.shipment_line_id
		,xpst.quantity_received as quantity_received
		,xpst.unmatched_qty as unmatch_qty_rcv
		,null transaction_date
	FROM XX_PO_SUPERTRANS_USED_RCPTS xpst
	WHERE supertrans_type = 'A'
	  AND po_line_id = c_po_line_id
	  AND unmatched_qty > 0
	)


	UNION ALL

	(SELECT
		'I' line_status
		,rsl.po_line_id
		,rsh.shipment_header_id
		,rsh.receipt_num
		,rsl.shipment_line_id
		,rsl.quantity_received
		,rsl.quantity_received as unmatch_qty_rcv
    ,rt.transaction_date
	FROM rcv_transactions rt
		,rcv_shipment_lines rsl
	    ,rcv_shipment_headers rsh
	WHERE rt.po_line_id = c_po_line_id
      AND rt.shipment_header_id = rsh.shipment_header_id
      AND rt.shipment_line_id = rsl.shipment_line_id
      AND rsh.shipment_header_id = rsl.shipment_header_id
	  AND rsl.po_line_id = c_po_line_id
	  AND rt.destination_type_code = 'RECEIVING'
	  AND NOT EXISTS (
				SELECT
					 rsh.receipt_num
					,rsl.shipment_line_id
					,rsl.quantity_received
					,rsl.quantity_received as unmatch_qty_rcv
				FROM XX_PO_SUPERTRANS_USED_RCPTS xpst
				WHERE xpst.po_line_id = c_po_line_id
				  AND xpst.shipment_header_id = rsl.shipment_header_id
				  AND xpst.shipment_line_id = rsl.shipment_line_id
				  AND xpst.supertrans_type = 'A'
	  )

   )
   ORDER BY line_status desc, transaction_date, shipment_header_id, shipment_line_id asc
   ;

	-- Above if same transaction_date then secondary order by shipment_line_id

    TYPE l_po_inv_list_tab IS TABLE OF c_list_po_adj_price_var%ROWTYPE
						INDEX BY PLS_INTEGER;
	l_po_inv_list   	l_po_inv_list_tab;
	l_po_inv_list_new 	l_po_inv_list_tab;

	TYPE l_po_line_rcpt_list_tab IS TABLE OF c_po_recpt_det%ROWTYPE
						INDEX BY PLS_INTEGER;
	l_po_rcpt_list   l_po_line_rcpt_list_tab;
	l_ins_po_rcpt_list   l_po_line_rcpt_list_tab;
	l_upd_po_rcpt_list   l_po_line_rcpt_list_tab;

	l_prev_po_line_id	NUMBER;
	l_unmatch_inv_qty	NUMBER;
	ln_rec				    NUMBER := 0;
	l_orig_quant      NUMBER :=0;
	l_new_quant       NUMBER :=0;
	ln_rec_cnt        NUMBER := 0;

	ln_err_count      NUMBER := 0;
	ln_error_idx      NUMBER := 0;
	lc_error_msg      VARCHAR2(4000);
	ln_temp			NUMBER := 0;
	data_exception     EXCEPTION;
	l_prev_inv_line_no	NUMBER;
	l_prev_inv_no		VARCHAR2(50);
	ln_po_inv_cnt	  NUMBER;
	l_invoice_line_count NUMBER;

	l_po_line_cnt		NUMBER;
	l_po_line_total_cnt	NUMBER;
	l_is_last_line_of_po	VARCHAR2(1);
	ln_cur_rcpt_cnt     NUMBER;

	ln_ins_rcpt_cnt 	NUMBER;
	ln_upd_rcpt_cnt 	NUMBER;

  l_is_match_for_inv_line VARCHAR2(1);

 BEGIN

   xla_security_pkg.set_security_context(602);----Added for defect NAIT #49192
	print_debug_msg('Begin - adj_cost_generate', TRUE);

	gc_debug	  := p_debug;
	gn_request_id := fnd_global.conc_request_id;
	gn_user_id    := fnd_global.user_id;
	gn_login_id   := fnd_global.login_id;


	OPEN c_list_po_adj_price_var(p_acct_run_date);
	FETCH c_list_po_adj_price_var BULK COLLECT INTO l_po_inv_list;

	BEGIN

		ln_po_inv_cnt := l_po_inv_list.count;
		print_debug_msg('Count of Adjust Price records, before matching, is '||ln_po_inv_cnt, TRUE);

		ln_ins_rcpt_cnt := 0;
		ln_upd_rcpt_cnt := 0;

		FOR i in 1..ln_po_inv_cnt
		LOOP

			BEGIN

				-- If the Sum of Inv Quantity is greater than Sum of Received Quantity for a PO
				-- then don't extract it
				/**  No need of this validation
				IF l_po_inv_list(i).invoice_line_quantity > l_po_inv_list(i).receipt_line_quantity THEN
					CONTINUE;  -- Skip this line
				END IF;
				**/


				-- If different Invoice for the same PO (Cursor is - order by po, invoice and Multiple invoices exist for one PO).
				-- So, if the same Invoice then we should use the same Receipt data so that we can use the updated "unmatch_qty_rcv"
				-- value, by the previous invoice, to skip those already matched invoices.

				IF l_prev_po_line_id = l_po_inv_list(i).po_line_id THEN
					-- Use the old Rcpt List so that we can match unMatchedRcptQuant
					IF ((l_prev_inv_no <> l_po_inv_list(i).invoice_num)
					   or (l_prev_inv_line_no <> l_po_inv_list(i).inv_line_num)) THEN

						l_prev_inv_no := l_po_inv_list(i).invoice_num;
						l_unmatch_inv_qty := l_po_inv_list(i).quantity_invoiced;
						l_prev_inv_line_no := l_po_inv_list(i).inv_line_num;
						l_invoice_line_count := l_invoice_line_count + 1;
						l_is_match_for_inv_line := 'N';
					END IF;

					l_is_last_line_of_po := 'N';
					l_po_line_cnt := l_po_line_cnt + 1;
					IF l_po_line_cnt = l_po_line_total_cnt THEN
						l_is_last_line_of_po := 'Y';
					END IF;

				ELSE
					-- If new po Line,
					print_debug_msg('Generate receipts for new po_Line_id : '||l_po_inv_list(i).po_line_id, FALSE);
					l_prev_po_line_id  :=  l_po_inv_list(i).po_line_id;
					l_prev_inv_no := l_po_inv_list(i).invoice_num;
					l_prev_inv_line_no := l_po_inv_list(i).inv_line_num;
					l_unmatch_inv_qty  := l_po_inv_list(i).quantity_invoiced;


					l_invoice_line_count := 1;
					l_po_line_cnt := 1;
					l_po_line_total_cnt := l_po_inv_list(i).inv_lines_for_po * l_po_inv_list(i).receipt_lines_for_po;

					l_is_match_for_inv_line := 'N';

					l_is_last_line_of_po := 'N';
					IF l_po_line_cnt = l_po_line_total_cnt THEN
						l_is_last_line_of_po := 'Y';
					END IF;

					OPEN c_po_recpt_det(l_po_inv_list(i).po_line_id);
					FETCH c_po_recpt_det BULK COLLECT INTO l_po_rcpt_list;
					CLOSE c_po_recpt_det;

				END IF;


				ln_cur_rcpt_cnt := l_po_rcpt_list.count;
				print_debug_msg('Count of Recipts for the po_line_id '||l_po_inv_list(i).po_line_id||' is '||ln_cur_rcpt_cnt, FALSE);

				IF ln_cur_rcpt_cnt <= 0 THEN
					lc_error_msg := 'adj_cost_generate() - No Receipts exist or already matched for po_line_id '||l_po_inv_list(i).po_line_id||' and invoice num '||l_po_inv_list(i).invoice_num||' and '||l_po_inv_list(i).inv_line_num;
					raise data_exception;
				END IF;

				FOR r in 1..ln_cur_rcpt_cnt
				LOOP

					BEGIN
						-- This receipt is matched already, so skip this receipt.
						IF l_po_rcpt_list(r).unmatch_qty_rcv <= 0 THEN
							CONTINUE;
						END IF;

						-- if the receipts apply then unmatch_qty_rcvv become zero
						IF l_unmatch_inv_qty <=0 THEN
							EXIT;   -- Exit from this Receipt Loop
						END IF;

						l_orig_quant := l_po_rcpt_list(r).quantity_received;

						IF l_po_rcpt_list(r).unmatch_qty_rcv <= l_unmatch_inv_qty THEN
							l_new_quant  := l_po_rcpt_list(r).unmatch_qty_rcv;
							l_unmatch_inv_qty := l_unmatch_inv_qty - l_new_quant;

							l_po_rcpt_list(r).unmatch_qty_rcv := 0;
							l_po_inv_list(i).matched_Line := 'Y';
						ELSE
							l_new_quant  := l_unmatch_inv_qty;
							l_unmatch_inv_qty := 0;
							l_po_rcpt_list(r).unmatch_qty_rcv := l_po_rcpt_list(r).unmatch_qty_rcv - l_new_quant;
							l_po_inv_list(i).matched_Line := 'Y';
						END IF;

						ln_rec := ln_rec + 1;
						l_po_inv_list_new(ln_rec) := l_po_inv_list(i);
						l_po_inv_list_new(ln_rec).receipt_num   := l_po_rcpt_list(r).receipt_num;
						l_po_inv_list_new(ln_rec).shipment_line_id   := l_po_rcpt_list(r).shipment_line_id;
						l_po_inv_list_new(ln_rec).orig_quantity := l_orig_quant;
						l_po_inv_list_new(ln_rec).new_quantity  := l_new_quant;
						l_is_match_for_inv_line := 'Y';

					EXCEPTION
					WHEN OTHERS THEN
						lc_error_msg := 'adj_cost_generate() - Error when matching with receipt for po line:'||l_po_inv_list(i).po_line_id||' with invoice quantity as '||l_po_inv_list(i).quantity_invoiced||' and receipt quantity as '||l_po_rcpt_list(r).quantity_received||' with error as: '||substr(SQLERRM,1,500);
						raise data_exception;
					END;

				END LOOP; -- End of PO Receipt List Loop

				/**
				IF l_is_match_for_inv_line = 'N' THEN
					lc_error_msg := 'adj_cost_generate() - Invoice line '||l_po_inv_list(i).inv_line_num||' doesnt match with receipt for po line:'||l_po_inv_list(i).po_line_id||' with invoice quantity as '||l_po_inv_list(i).quantity_invoiced;
					raise data_exception;
				END IF;
				**/

				IF l_is_last_line_of_po = 'Y'  THEN


					IF l_unmatch_inv_qty > 0 THEN
						l_po_inv_list_new(ln_rec).new_quantity  := l_po_inv_list_new(ln_rec).new_quantity +   l_unmatch_inv_qty;
					END IF;

					ln_cur_rcpt_cnt := l_po_rcpt_list.count;
					FOR k in 1..ln_cur_rcpt_cnt
					LOOP
					    IF l_po_rcpt_list(k).line_status = 'I' THEN
							-- if the origianl quantity doesn't matched then no need to insert
							IF (l_po_rcpt_list(k).quantity_received <> l_po_rcpt_list(k).unmatch_qty_rcv and l_po_rcpt_list(k).unmatch_qty_rcv > 0) THEN
								ln_ins_rcpt_cnt := ln_ins_rcpt_cnt + 1;
								l_ins_po_rcpt_list(ln_ins_rcpt_cnt) := l_po_rcpt_list(k);
							END IF;
						ELSE
							ln_upd_rcpt_cnt := ln_upd_rcpt_cnt + 1;
							l_upd_po_rcpt_list(ln_upd_rcpt_cnt) := l_po_rcpt_list(k);
						END IF;
					END LOOP;
					print_debug_msg('New inserted receipts cumulative count for the po_line_id - '||l_po_inv_list_new(ln_rec).po_line_id||' is '||ln_ins_rcpt_cnt, FALSE);
					print_debug_msg('Updated matched receipts cumulative count for the po_line_id - '||l_po_inv_list_new(ln_rec).po_line_id||' is '||ln_upd_rcpt_cnt, FALSE);

				END IF;
			EXCEPTION
				WHEN data_exception THEN
					raise data_exception;
				WHEN OTHERS THEN
					print_debug_msg('adj_cost_generate() - Error when doing matching for PO lineId '||l_po_inv_list(i).po_line_id||' is '||substr(SQLERRM,1,500),TRUE);
					lc_error_msg  := 'adj_cost_generate() - Exception when doing matching as '||substr(SQLERRM,1,500);
					raise data_exception;
			END;

		END LOOP;  -- End of PO Invoice List Loop

	EXCEPTION
		WHEN data_exception THEN
			raise data_exception;
		WHEN OTHERS THEN
			print_debug_msg('adj_cost_generate() - Error when doing matching - '||substr(SQLERRM,1,500),TRUE);
			lc_error_msg  := 'adj_cost_generate() - Exception when doing matching as '||substr(SQLERRM,1,500);
			raise data_exception;
	END;

	CLOSE c_list_po_adj_price_var;
	ln_rec_cnt := l_po_inv_list_new.count;

	print_debug_msg('Count of Adjust Price records, after matching, is '||ln_rec_cnt, TRUE);

	BEGIN
		FORALL n in 1..ln_rec_cnt
			SAVE EXCEPTIONS
			INSERT INTO XX_PO_WMS_SUPERTRANS_OB(BATCH_id
											  ,RECEIPT_NUM
											  ,ITEM_NAME
											  ,RECEIPT_LINE_QTY
											  ,INV_LINE_QTY
											  ,PO_LINE_COST
											  ,INV_LINE_COST
											  ,VENDOR_NUMBER
											  ,RECORD_TYPE
											  ,SHIP_LOCATION
											  ,PO_NUMBER
											  ,CURRENCY
											  ,COMPANY
											  ,PO_LINE_NUM
											  ,SEQ_NO
											  ,PO_LINE_ID
											  ,INVOICE_ID
											  ,INV_LINE_NUM
											  ,SHIPMENT_LINE_ID
											  ,RECORD_STATUS
											  ,COMMENTS
											  ,REQUEST_ID
											  ,CREATED_BY
											  ,CREATION_DATE
											  ,LAST_UPDATED_BY
											  ,LAST_UPDATE_DATE
											  ,LAST_UPDATE_LOGIN
											 )
								VALUES (p_batch_id
									,l_po_inv_list_new(n).receipt_num
									,l_po_inv_list_new(n).item_sku
									,l_po_inv_list_new(n).orig_quantity
									,l_po_inv_list_new(n).new_quantity
									,l_po_inv_list_new(n).po_unit_price
									,l_po_inv_list_new(n).invoice_unit_price
									,l_po_inv_list_new(n).supplier_site_code
									,'A'  -- record_type
									,l_po_inv_list_new(n).ship_to_location_code
									,l_po_inv_list_new(n).po_number
									,decode(l_po_inv_list_new(n).invoice_currency_code, 'USD', 'US', 'CAD', 'CA')
									,'USTR'  -- Company hardcoded
									,l_po_inv_list_new(n).line_num
									,0    -- seq_nmbr  constant here
									,l_po_inv_list_new(n).po_line_id
									,l_po_inv_list_new(n).invoice_id
									,l_po_inv_list_new(n).inv_line_num
									,l_po_inv_list_new(n).shipment_line_id
									,NULL
									,NULL
									,gn_request_id
									,gn_user_id
									,sysdate
									,gn_user_id
									,sysdate
									,gn_login_id
									);
		--	COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
		   print_debug_msg('adj_cost_generate() - Bulk Exception raised while inserting into XX_PO_WMS_SUPERTRANS_OB',TRUE);
		   ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		   FOR i IN 1..ln_err_count
		   LOOP
			  ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			  lc_error_msg := SUBSTR('Bulk Exception - Failed to Insert value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			  print_debug_msg('Record_Line_id=['||to_char(l_po_inv_list_new(ln_error_idx).po_number)||'-'||to_char(l_po_inv_list_new(ln_error_idx).line_num)||'-'||to_char(l_po_inv_list_new(ln_error_idx).receipt_num)||'], Error msg=['||lc_error_msg||']'
			   ,TRUE);
		   END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'adj_cost_generate() - Bulk Exception raised while inserting. Pls. check the debug log.';
			raise data_exception;
	END;


	BEGIN
		FORALL i in 1..ln_upd_rcpt_cnt SAVE EXCEPTIONS
		UPDATE XX_PO_SUPERTRANS_USED_RCPTS xpst
		SET xpst.unmatched_qty = l_upd_po_rcpt_list(i).unmatch_qty_rcv
		    ,last_updated_by = gn_user_id
			,last_update_date = sysdate
			,last_update_login = gn_login_id
		WHERE xpst.supertrans_type = 'A'
		  AND l_upd_po_rcpt_list(i).line_status = 'U'
		  AND xpst.shipment_header_id = l_upd_po_rcpt_list(i).shipment_header_id
		  AND xpst.shipment_line_id = l_upd_po_rcpt_list(i).shipment_line_id
		  AND l_upd_po_rcpt_list(i).unmatch_qty_rcv > 0;

		print_debug_msg('adj_cost_generate() - updated existed matched receipts', TRUE);

	EXCEPTION
	WHEN OTHERS THEN
			print_debug_msg('adj_cost_generate() - Bulk Exception raised when update to table XX_PO_SUPERTRANS_USED_RCPTS',TRUE);

		    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		    FOR i IN 1..ln_err_count
		    LOOP
			    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			    lc_error_msg := SUBSTR('Bulk Exception - Failed to update value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			    print_debug_msg('po_line_id-receipt_num-shipment_line_id=['||to_char(l_upd_po_rcpt_list(ln_error_idx).po_line_id)||'-'||to_char(l_upd_po_rcpt_list(ln_error_idx).receipt_num)||'-'||to_char(l_upd_po_rcpt_list(ln_error_idx).shipment_line_id)||'], Error msg=['||lc_error_msg||']'
			     ,TRUE);
		    END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'adj_cost_generate() - Bulk Exception raised while updating into table XX_PO_SUPERTRANS_USED_RCPTS. Pls. check the debug log.';
			raise data_exception;
	END;


	BEGIN
		FORALL i in 1..ln_upd_rcpt_cnt SAVE EXCEPTIONS
		DELETE FROM XX_PO_SUPERTRANS_USED_RCPTS xpst
		WHERE xpst.supertrans_type = 'A'
		  AND l_upd_po_rcpt_list(i).line_status = 'U'
		  AND xpst.shipment_header_id = l_upd_po_rcpt_list(i).shipment_header_id
		  AND xpst.shipment_line_id = l_upd_po_rcpt_list(i).shipment_line_id
		  AND l_upd_po_rcpt_list(i).unmatch_qty_rcv = 0;

		print_debug_msg('adj_cost_generate() - Delete existed matched receipts, if value is 0.', TRUE);

	EXCEPTION
	WHEN OTHERS THEN
			print_debug_msg('adj_cost_generate() - Bulk Exception raised when delete from table XX_PO_SUPERTRANS_USED_RCPTS',TRUE);

		    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		    FOR i IN 1..ln_err_count
		    LOOP
			    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			    lc_error_msg := SUBSTR('Bulk Exception - Failed to update value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			    print_debug_msg('po_line_id-receipt_num-shipment_line_id=['||to_char(l_upd_po_rcpt_list(ln_error_idx).po_line_id)||'-'||to_char(l_upd_po_rcpt_list(ln_error_idx).receipt_num)||'-'||to_char(l_upd_po_rcpt_list(ln_error_idx).shipment_line_id)||'], Error msg=['||lc_error_msg||']'
			     ,TRUE);
		    END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'adj_cost_generate() - Bulk Exception raised while deleting from table XX_PO_SUPERTRANS_USED_RCPTS. Pls. check the debug log.';
			raise data_exception;
	END;

	BEGIN
		FORALL i in 1..ln_ins_rcpt_cnt SAVE EXCEPTIONS
		INSERT INTO XX_PO_SUPERTRANS_USED_RCPTS
						(
						 po_line_id
						,receipt_num
						,shipment_header_id
						,shipment_line_id
						,quantity_received
						,unmatched_qty
						,supertrans_type
						,created_by
						,creation_date
						,last_updated_by
						,last_update_date
						,last_update_login
						)
					VALUES(
						 l_ins_po_rcpt_list(i).po_line_id
						,l_ins_po_rcpt_list(i).receipt_num
						,l_ins_po_rcpt_list(i).shipment_header_id
						,l_ins_po_rcpt_list(i).shipment_line_id
						,l_ins_po_rcpt_list(i).quantity_received
						,l_ins_po_rcpt_list(i).unmatch_qty_rcv
						,'A'
						,gn_user_id
						,sysdate
						,gn_user_id
						,sysdate
						,gn_login_id
					);
		print_debug_msg('adj_cost_generate() - inserted new matched receipts count is '||ln_ins_rcpt_cnt, TRUE);
	EXCEPTION
		WHEN OTHERS THEN
			print_debug_msg('adj_cost_generate() - Bulk Exception raised when inserting into table XX_PO_SUPERTRANS_USED_RCPTS',TRUE);

		    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		    FOR i IN 1..ln_err_count
		    LOOP
			    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			    lc_error_msg := SUBSTR('Bulk Exception - Failed to insert to table XX_PO_SUPERTRANS_USED_RCPTS and error value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			    print_debug_msg('po_line_id-receipt_num-shipment_line_id=['||to_char(l_ins_po_rcpt_list(ln_error_idx).po_line_id)||'-'||to_char(l_ins_po_rcpt_list(ln_error_idx).receipt_num)||'-'||to_char(l_ins_po_rcpt_list(ln_error_idx).shipment_line_id)||'], Error msg=['||lc_error_msg||']'
			     ,TRUE);
		    END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'adj_cost_generate() - Bulk Exception raised while inserting into table XX_PO_SUPERTRANS_USED_RCPTS. Pls. check the debug log.';
			raise data_exception;
	END;
	  -- NAIT-49192 added INSERT STATEMEMT to create new record for cancelled invoices to negate quantity feed for WMS
  BEGIN
   INSERT
    INTO XX_PO_WMS_SUPERTRANS_OB
      (
        BATCH_id ,
        RECEIPT_NUM ,
        ITEM_NAME ,
        RECEIPT_LINE_QTY ,
        INV_LINE_QTY ,
        PO_LINE_COST ,
        INV_LINE_COST ,
        VENDOR_NUMBER ,
        RECORD_TYPE ,
        SHIP_LOCATION ,
        PO_NUMBER ,
        CURRENCY ,
        COMPANY ,
        PO_LINE_NUM ,
        SEQ_NO ,
        PO_LINE_ID ,
        INVOICE_ID ,
        INV_LINE_NUM ,
        SHIPMENT_LINE_ID ,
        RECORD_STATUS ,
        COMMENTS ,
        REQUEST_ID ,
        CREATED_BY ,
        CREATION_DATE ,
        LAST_UPDATED_BY ,
        LAST_UPDATE_DATE ,
        LAST_UPDATE_LOGIN
      )
    SELECT p_batch_id ,
      RECEIPT_NUM ,
      ITEM_NAME ,
      INV_LINE_QTY ,
      RECEIPT_LINE_QTY ,
      INV_LINE_COST ,
      PO_LINE_COST ,
      VENDOR_NUMBER ,
      RECORD_TYPE ,
      SHIP_LOCATION ,
      PO_NUMBER ,
      CURRENCY ,
      COMPANY ,
      PO_LINE_NUM ,
      SEQ_NO ,
      PO_LINE_ID ,
      INVOICE_ID ,
      INV_LINE_NUM ,
      SHIPMENT_LINE_ID ,
      NULL ,
      'CANCEL_INVOICE_TRX', ---COMMENTS ,
      gn_request_id ,
      gn_user_id ,
      SYSDATE ,
      gn_user_id ,
      SYSDATE ,
      gn_login_id
    FROM XX_PO_WMS_SUPERTRANS_OB ST
    WHERE ST.RECORD_TYPE ='A'
   AND EXISTS
      (SELECT /*+ index(xah XX_XLA_AE_HEADERS_N11) */ 
	         1  --NAIT-87118 drive the SQL only via the records for that gl transfer run date from index XX_XLA_AE_HEADERS_N11
      FROM XLA_TRANSACTION_ENTITIES XTE ,
           --XLA_EVENTS XEV , --NAIT-87118 commented redundant
           xla_ae_headers xah
      WHERE 1                =1
      AND xah.application_id = 200
      --AND xev.event_id       = xah.event_id
      --AND xev.entity_id      =xah.entity_id
      --AND XEV.APPLICATION_ID = XAH.APPLICATION_ID
      --AND XEV.EVENT_TYPE_CODE='INVOICE CANCELLED'
      --AND XEV.PROCESS_STATUS_CODE = 'P'
      --AND xev.event_status_code   ='P'
      --AND XTE.ENTITY_ID           = XEV.ENTITY_ID
	  AND xah.EVENT_TYPE_CODE     = 'INVOICE CANCELLED' --NAIT-87118
	  AND XTE.application_id      = 200            --NAIT-87118
	  AND XTE.ENTITY_ID           = XAH.ENTITY_ID  --NAIT-87118
      AND xte.entity_code         = 'AP_INVOICES'
      --AND xte.application_id      = xev.application_id --NAIT-87118
	  AND xte.application_id      = xah.application_id --NAIT-87118
      AND XTE.LEDGER_ID           = XAH.LEDGER_ID
      AND ST.INVOICE_ID           = XTE.SOURCE_ID_INT_1
	  AND XAH.GL_TRANSFER_DATE >= TRUNC(p_acct_run_date) AND xah.gl_transfer_date < ( trunc(p_acct_run_date) + 1 ) --NAIT-87118
	  AND XAH.GL_TRANSFER_STATUS_CODE = 'Y' --NAIT-87118 consider only gl transferred records as the filter is on gl_transfer_date
      --AND TRUNC(XAH.GL_TRANSFER_DATE)     =TRUNC(p_acct_run_date)
      )
 AND NOT  EXISTS
    (SELECT 'x'
    FROM XX_PO_WMS_SUPERTRANS_OB XPWS
    WHERE xpws.invoice_id = ST.invoice_id
    AND XPWS.RECORD_TYPE  = 'A'
   AND NVL(XPWS.COMMENTS,'X') = 'CANCEL_INVOICE_TRX'
    );
    --COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg('adj_cost_generate() - Bulk Exception raised while inserting into XX_PO_WMS_SUPERTRANS_OB',TRUE);
    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
    FOR i IN 1..ln_err_count
    LOOP
      ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
      lc_error_msg := SUBSTR('Bulk Exception - Failed to Insert value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
      print_debug_msg('Record_Line_id=['||TO_CHAR(l_po_inv_list_new(ln_error_idx).po_number)||'-'||TO_CHAR(l_po_inv_list_new(ln_error_idx).line_num)||'-'||TO_CHAR(l_po_inv_list_new(ln_error_idx).receipt_num)||'], Error msg=['||lc_error_msg||']' ,TRUE);
    END LOOP; -- bulk_err_loop FOR Insert
    ROLLBACK;
    lc_error_msg := 'adj_cost_generate() - Bulk Exception raised while inserting cancelled invoices data. Pls. check the debug log.';
    raise data_exception;
  END;

	p_retcode := 0;
	p_errbuf  := NULL;

	print_debug_msg('End - adj_cost_generate', TRUE);

	EXCEPTION
	WHEN data_exception THEN
		p_retcode := 2;
		p_errbuf  := lc_error_msg;
	WHEN OTHERS THEN
		lc_error_msg := 'adj_cost_generate() - '||substr(sqlerrm,1,250);
		print_debug_msg ('ERROR process_supertrans_ob - '||lc_error_msg, TRUE);
		p_retcode := 2;
		p_errbuf  := lc_error_msg;
 END  adj_cost_generate;

 -- +============================================================================================+
 -- |  Name	  : match_recpt_generate                                                         	 |
 -- |  Description: This procedure generates data for Matching receipts and writes to a staging table  |
 -- |                and marks those receipt as matched so that it won't pickup again.			 |
 -- =============================================================================================|
PROCEDURE match_recpt_generate(p_errbuf      OUT  VARCHAR2
                         ,p_retcode       OUT  NUMBER
                         ,p_batch_id      IN   NUMBER
                         ,p_acct_run_date IN   DATE
                      	 ,p_debug         IN   VARCHAR2)
 IS
	CURSOR c_list_po_recpt_inv_match(c_account_date DATE)
	IS
		WITH accounted_invoices_m AS
		(
			SELECT   /*+ index(xah XX_XLA_AE_HEADERS_N11) use_nl(xah xte ) */ 
				  aia1.invoice_id
				, aia1.invoice_num
				, aia1.invoice_currency_code
			FROM ap_invoices_all aia1
				,xla_transaction_entities xte
				--,xla_events xev
				,xla_ae_headers xah
			WHERE 1=1
			  and xah.application_id = 200
			  --and trunc(xah.gl_transfer_date) = trunc(c_account_date)
			  AND xah.gl_transfer_date >= trunc(c_account_date) AND xah.gl_transfer_date < ( trunc(c_account_date) + 1 ) /*Raj NAIT-87118 to utilize the new XX_XLA_AE_HEADERS_N11 index */
              AND xah.gl_transfer_status_code = 'Y' 			  
			  AND XAH.EVENT_TYPE_CODE         = 'INVOICE VALIDATED' /*raj NAIT-87118 added */ 
			  AND XAH.entity_id               = xte.entity_id  /*raj NAIT-87118 added */
			  and xah.ledger_id = xte.ledger_id
			  and xte.application_id = 200
			  and xte.entity_code = 'AP_INVOICES'
			  and aia1.invoice_id = xte.source_id_int_1
			  and aia1.cancelled_date IS NULL
			  --and xev.application_id = 200
			  --and xev.entity_id= xte.entity_id
			  --and xev.event_type_code = 'INVOICE VALIDATED'
			  --and xev.process_status_code = 'P'
			  --and xah.event_id = xev.event_id
			  and EXISTS (SELECT 'x'
						 FROM  xx_fin_translatevalues tv
							  ,xx_fin_translatedefinition td
						WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
						  AND tv.TRANSLATE_ID  = td.TRANSLATE_ID
						  AND tv.enabled_flag='Y'
						  AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)
						  AND tv.target_value1=aia1.source
					  )
			 and NOT EXISTS (
						SELECT 'x'
						FROM XX_PO_WMS_SUPERTRANS_OB xpws
						WHERE xpws.invoice_id = aia1.invoice_id
						  AND xpws.record_type = 'M'
			 )
		)
		SELECT
			pha.po_header_id
		  , pha.segment1 po_number
		  , pla.po_line_id
		  , lpad(ltrim(assa.vendor_site_code_alt, '0'), 9, '0') supplier_site_code
		  , lpad(ltrim(hrl.attribute1,'0'), 4, '0') ship_to_location_code
		  , pla.line_num as po_line_num
		  , SUM(1) OVER (PARTITION BY aila.invoice_id, aila.line_number, rsl.po_line_id) receipt_lines_for_po
		--  , SUM(rsl.quantity_received) OVER (PARTITION BY aila.invoice_id, aila.line_number, rsl.po_line_id) receipt_line_quantity --orig_sum_rcv_quant_of_po_line
		  , SUM(1) OVER (PARTITION BY pla.po_line_id, rsl.shipment_header_id, rsl.shipment_line_id) inv_lines_for_po
		--  , SUM(aila.quantity_invoiced)  OVER  (PARTITION BY pla.po_line_id, rsl.shipment_header_id, rsl.shipment_line_id) invoice_line_quantity --new_sum_inv_quant_of_po_line
		  , aila.quantity_invoiced
		  , aila.line_number as inv_line_num
		  , aia.invoice_id
		  , aia.invoice_currency_code
		  , aia.invoice_num
		  , NULL receipt_num
		  , NULL shipment_header_id
		FROM ap_invoice_lines_all aila
			,accounted_invoices_m aia
			,po_lines_all pla
			,po_headers_all pha
			,rcv_shipment_lines rsl
			,ap_supplier_sites_all assa
			,hr_locations_all hrl
		WHERE 1=1
		  AND aila.invoice_id = aia.invoice_id
		  AND aila.line_type_lookup_code = 'ITEM'
		  AND aila.discarded_flag = 'N'
		  AND (aila.CANCELLED_FLAG IS NULL OR aila.CANCELLED_FLAG = 'N') --??
		  AND pla.po_line_id = aila.po_line_id
		  AND pla.po_header_id = pha.po_header_id
		  AND rsl.po_line_id = pla.po_line_id
		  AND assa.vendor_site_id = pha.vendor_site_id
		  AND assa.attribute8 like 'TR%'
		  AND hrl.location_id = pha.ship_to_location_id
		  ORDER BY pla.po_line_id, aia.invoice_num, aila.line_number;


	--- Sum up the receipt line amount for each receipt
	CURSOR c_po_recpt_det(c_po_line_id NUMBER)
	IS
	(SELECT
		 'U' line_status
		,xpst.po_line_id
		,xpst.shipment_header_id
		,xpst.receipt_num
		,xpst.shipment_line_id
		,xpst.quantity_received as quantity_received
		,xpst.unmatched_qty as unmatch_qty_rcv
    ,null transaction_date
	FROM XX_PO_SUPERTRANS_USED_RCPTS xpst
	WHERE supertrans_type = 'M'
	  AND po_line_id = c_po_line_id
	  AND unmatched_qty > 0
	)


	UNION ALL

	(SELECT
		'I' line_status
		,rsl.po_line_id
		,rsh.shipment_header_id
		,rsh.receipt_num
		,rsl.shipment_line_id
		,rsl.quantity_received
		,rsl.quantity_received as unmatch_qty_rcv
    ,rt.transaction_date
	FROM rcv_transactions rt
		,rcv_shipment_lines rsl
	    ,rcv_shipment_headers rsh
	WHERE rt.po_line_id = c_po_line_id
      AND rt.shipment_header_id = rsh.shipment_header_id
      AND rt.shipment_line_id = rsl.shipment_line_id
      AND rsh.shipment_header_id = rsl.shipment_header_id
	  AND rsl.po_line_id = c_po_line_id
	  AND rt.destination_type_code = 'RECEIVING'
	  AND NOT EXISTS (
				SELECT
					 rsh.receipt_num
					,rsl.shipment_line_id
					,rsl.quantity_received
					,rsl.quantity_received as unmatch_qty_rcv
				FROM XX_PO_SUPERTRANS_USED_RCPTS xpst
				WHERE xpst.po_line_id = c_po_line_id
				  AND xpst.shipment_header_id = rsl.shipment_header_id
				  AND xpst.shipment_line_id = rsl.shipment_line_id
				  AND xpst.supertrans_type = 'M'
	  )

   )
   ORDER BY line_status desc, transaction_date, shipment_header_id, shipment_line_id asc
   ;
	-- Above if same transaction_date then secondary order by shipment_line_id

    TYPE l_po_inv_list_tab IS TABLE OF c_list_po_recpt_inv_match%ROWTYPE
						INDEX BY PLS_INTEGER;
	l_po_inv_list   	l_po_inv_list_tab;
	l_po_inv_list_new 	l_po_inv_list_tab;

	TYPE l_po_line_rcpt_list_tab IS TABLE OF c_po_recpt_det%ROWTYPE
						INDEX BY PLS_INTEGER;
	l_po_rcpt_list   l_po_line_rcpt_list_tab;

  l_ins_po_rcpt_list  l_po_line_rcpt_list_tab;
  l_upd_po_rcpt_list   l_po_line_rcpt_list_tab;

	TYPE l_rcpt_match_tab IS TABLE OF VARCHAR2(1) INDEX BY PLS_INTEGER;
	l_rcpt_match_list   l_rcpt_match_tab;


	l_prev_po_line_id	NUMBER;
	l_unmatch_inv_qty	NUMBER;
	ln_rec				    NUMBER := 0;
	l_orig_quant      NUMBER :=0;
	l_new_quant       NUMBER :=0;
	ln_rec_cnt        NUMBER := 0;

	ln_err_count      NUMBER := 0;
	ln_error_idx      NUMBER := 0;
	lc_error_msg      VARCHAR2(4000);
	ln_temp			  NUMBER := 0;
	data_exception    EXCEPTION;
	l_prev_inv_line_no	NUMBER;
	l_prev_po_hdr_id  NUMBER;
	l_prev_inv_no	  VARCHAR2(50);
	l_rcpt_cnt		  NUMBER;
	lc_new_receipt_num	VARCHAR2(1);
	ln_po_inv_cnt	  NUMBER;

	l_invoice_line_count NUMBER;

	l_po_line_cnt		NUMBER;
	l_po_line_total_cnt	NUMBER;
	l_is_last_line_of_po	VARCHAR2(1);
	ln_cur_rcpt_cnt     NUMBER;

	ln_ins_rcpt_cnt 	NUMBER;
	ln_upd_rcpt_cnt 	NUMBER;

 BEGIN
	print_debug_msg('Begin - match_recpt_generate', TRUE);

	gc_debug	  := p_debug;
	gn_request_id := fnd_global.conc_request_id;
	gn_user_id    := fnd_global.user_id;
	gn_login_id   := fnd_global.login_id;



	OPEN c_list_po_recpt_inv_match(p_acct_run_date);
	FETCH c_list_po_recpt_inv_match BULK COLLECT INTO l_po_inv_list;

	BEGIN
		ln_po_inv_cnt := l_po_inv_list.count;
		print_debug_msg('Count of Supertrans Matched records, before matching, is '||ln_po_inv_cnt, TRUE);

		ln_ins_rcpt_cnt := 0;
		ln_upd_rcpt_cnt := 0;

		FOR i in 1..ln_po_inv_cnt
		LOOP

			BEGIN
				-- If the Sum of Inv Quantity is greater than Sum of Received Quantity for a PO
				-- then don't extract it
				/** No need of this vaildation now
				IF l_po_inv_list(i).invoice_line_quantity > l_po_inv_list(i).receipt_line_quantity THEN
					CONTINUE;  -- Skip this line
				END IF;
				**/

				IF l_prev_po_hdr_id <> l_po_inv_list(i).po_header_id  THEN
					l_prev_po_hdr_id := l_po_inv_list(i).po_header_id;
					-- For new PO, get corresonding receipts eliminating old receipts which doesn't require.
					l_rcpt_match_list.DELETE;
				END IF;

				-- If different Invoice for the same PO (Cursor is - order by po, invoice and Multiple invoices exist for one PO).
				-- So, if the same Invoice then we should use the same Receipt data so that we can use the updated "unmatch_qty_rcv"
				-- value, by the previous invoice, to skip those already matched invoices.

				IF l_prev_po_line_id = l_po_inv_list(i).po_line_id THEN
					-- Use the old Rcpt List so that we can match unMatchedRcptQuant

					-- If same inv line then the value of l_unmatch_inv_qty is carried over.
					-- If different inv line then new value for l_unmatch_inv_qty
					IF ((l_prev_inv_no <> l_po_inv_list(i).invoice_num)
					   or (l_prev_inv_line_no <> l_po_inv_list(i).inv_line_num)) THEN

						l_prev_inv_no := l_po_inv_list(i).invoice_num;
						l_unmatch_inv_qty := l_po_inv_list(i).quantity_invoiced;
						l_prev_inv_line_no := l_po_inv_list(i).inv_line_num;
						l_invoice_line_count := l_invoice_line_count + 1;
					END IF;

					l_is_last_line_of_po := 'N';
					l_po_line_cnt := l_po_line_cnt + 1;
					IF l_po_line_cnt = l_po_line_total_cnt THEN
						l_is_last_line_of_po := 'Y';
					END IF;

				ELSE
					-- If new po Line,
					l_prev_po_line_id  :=  l_po_inv_list(i).po_line_id;
					l_prev_inv_no := l_po_inv_list(i).invoice_num;
					l_prev_inv_line_no := l_po_inv_list(i).inv_line_num;
					l_unmatch_inv_qty  := l_po_inv_list(i).quantity_invoiced;

					l_invoice_line_count := 1;
					l_po_line_cnt := 1;
					l_po_line_total_cnt := l_po_inv_list(i).inv_lines_for_po * l_po_inv_list(i).receipt_lines_for_po;

					l_is_last_line_of_po := 'N';
					IF l_po_line_cnt = l_po_line_total_cnt THEN
						l_is_last_line_of_po := 'Y';
					END IF;


					OPEN c_po_recpt_det(l_po_inv_list(i).po_line_id);
					FETCH c_po_recpt_det BULK COLLECT INTO l_po_rcpt_list;
					CLOSE c_po_recpt_det;
				END IF;


				l_rcpt_cnt := l_po_rcpt_list.count;

				IF ln_cur_rcpt_cnt <= 0 THEN
					lc_error_msg := 'match_recpt_generate() - No Receipts exists or already matched for po_line_id '||l_po_inv_list(i).po_line_id;
					raise data_exception;
				END IF;

				FOR r in 1..l_rcpt_cnt
				LOOP
					BEGIN
						-- This receipt is matched already, so skip this receipt.
						IF l_po_rcpt_list(r).unmatch_qty_rcv <= 0 Then
							CONTINUE;
						END IF;

						-- if the receipts apply to the previous invoices fully then l_unmatch_inv_qty become zero
						-- and we can exit this receipt loop(ignoring other receipts in this loop)
						-- and come with other invoice of same/new po_line
						IF l_unmatch_inv_qty <=0 THEN
							EXIT;   -- Exit from this Receipt Loop
						END IF;

						IF l_po_rcpt_list(r).unmatch_qty_rcv <= l_unmatch_inv_qty THEN
							-- For last Invoice Line, if unmatch invoice quantity is more then use
							-- the remaining amount as new quantity.
									--IF l_invoice_line_count = l_po_inv_list(i).inv_lines_for_po THEN
							/**
							IF l_is_last_line_of_po = 'Y' THEN
								l_new_quant  := l_unmatch_inv_qty;
								l_unmatch_inv_qty := 0;
							ELSE
								l_new_quant  := l_po_rcpt_list(r).unmatch_qty_rcv;
								l_unmatch_inv_qty := l_unmatch_inv_qty - l_new_quant;
							END IF;
							**/

							l_new_quant  := l_po_rcpt_list(r).unmatch_qty_rcv;
							l_unmatch_inv_qty := l_unmatch_inv_qty - l_new_quant;

							l_po_rcpt_list(r).unmatch_qty_rcv := 0;

						ELSE
							l_new_quant  := l_unmatch_inv_qty;
							l_unmatch_inv_qty := 0;
							l_po_rcpt_list(r).unmatch_qty_rcv := l_po_rcpt_list(r).unmatch_qty_rcv - l_new_quant;
						END IF;

						-- To prevent duplicate Receipt Number lines to extract, use l_rcpt_match_list.EXISTS
						-- And if the line_status = 'U' means it is already matched for old invoice date of supertrans and receipt sent already and no need to send the same
						-- receipt again.
						IF ((NOT l_rcpt_match_list.EXISTS(l_po_rcpt_list(r).shipment_header_id)) and (l_po_rcpt_list(r).line_status = 'I')) THEN
							l_rcpt_match_list(l_po_rcpt_list(r).shipment_header_id) := 'Y';
							ln_rec := ln_rec + 1;
							l_po_inv_list_new(ln_rec) := l_po_inv_list(i);
							l_po_inv_list_new(ln_rec).receipt_num   := l_po_rcpt_list(r).receipt_num;
							l_po_inv_list_new(ln_rec).shipment_header_id := l_po_rcpt_list(r).shipment_header_id;
						END IF;

					EXCEPTION
					WHEN OTHERS THEN
						lc_error_msg := 'match_recpt_generate() - Error when matching with receipt for po line:'||l_po_inv_list(i).po_line_id||' with invoice quantity as '||l_po_inv_list(i).quantity_invoiced||' and receipt quantity as '||l_po_rcpt_list(r).quantity_received||' with error as: '||substr(SQLERRM,1,500);
						raise data_exception;
					END;

				END LOOP; -- End of PO Receipt List Loop

				-- If it is last line of the po_line then update the receipts to another total receipts plsql table so that
				-- we can update all receipts at a time.
				IF l_is_last_line_of_po = 'Y' THEN

					ln_cur_rcpt_cnt := l_po_rcpt_list.count;
					FOR k in 1..ln_cur_rcpt_cnt
					LOOP
					    IF l_po_rcpt_list(k).line_status = 'I' THEN
							-- if the origianl quantity doesn't matched then no need to insert
							IF (l_po_rcpt_list(k).quantity_received <> l_po_rcpt_list(k).unmatch_qty_rcv and l_po_rcpt_list(k).unmatch_qty_rcv > 0) THEN
								ln_ins_rcpt_cnt := ln_ins_rcpt_cnt + 1;
								l_ins_po_rcpt_list(ln_ins_rcpt_cnt) := l_po_rcpt_list(k);
							END IF;
						ELSE
							ln_upd_rcpt_cnt := ln_upd_rcpt_cnt + 1;
							l_upd_po_rcpt_list(ln_upd_rcpt_cnt) := l_po_rcpt_list(k);
				END IF;
					END LOOP;
					print_debug_msg('New inserted receipts cumulative count for the po_line_id - '||l_po_inv_list(i).po_line_id||' is '||ln_ins_rcpt_cnt, FALSE);
					print_debug_msg('Updated matched receipts cumulative count for the po_line_id - '||l_po_inv_list(i).po_line_id||' is '||ln_upd_rcpt_cnt, FALSE);
				END IF;

			EXCEPTION
				WHEN data_exception THEN
					raise data_exception;
				WHEN OTHERS THEN
					print_debug_msg('match_recpt_generate() - Error when doing matching for PO lineId '||l_po_inv_list(i).po_line_id||' is '||substr(SQLERRM,1,500),TRUE);
					lc_error_msg  := 'match_recpt_generate() - Exception when doing matching as '||substr(SQLERRM,1,500);
					raise data_exception;
			END;
		END LOOP;  -- End of PO Invoice List Loop
	EXCEPTION
		WHEN data_exception THEN
			raise data_exception;
		WHEN OTHERS THEN
			print_debug_msg('match_recpt_generate() - Error when doing matching - '||substr(SQLERRM,1,500),TRUE);
			lc_error_msg  := 'match_recpt_generate() - Exception when doing matching as '||substr(SQLERRM,1,500);
			raise data_exception;
	END;

	CLOSE c_list_po_recpt_inv_match;
	ln_rec_cnt := l_po_inv_list_new.count;

	print_debug_msg('Count of Supertrans Matched records, after matching, is '||ln_rec_cnt, TRUE);

	BEGIN
		FORALL n in 1..ln_rec_cnt
			SAVE EXCEPTIONS
			INSERT INTO XX_PO_WMS_SUPERTRANS_OB(BATCH_id
											  ,RECEIPT_NUM
											  ,ITEM_NAME
											  ,RECEIPT_LINE_QTY
											  ,INV_LINE_QTY
											  ,PO_LINE_COST
											  ,INV_LINE_COST
											  ,VENDOR_NUMBER
											  ,RECORD_TYPE
											  ,SHIP_LOCATION
											  ,PO_NUMBER
											  ,CURRENCY
											  ,COMPANY
											  ,PO_LINE_NUM
											  ,SEQ_NO
											  ,PO_LINE_ID
											  ,INVOICE_ID
											  ,INV_LINE_NUM
											  ,RECORD_STATUS
											  ,COMMENTS
											  ,REQUEST_ID
											  ,CREATED_BY
											  ,CREATION_DATE
											  ,LAST_UPDATED_BY
											  ,LAST_UPDATE_DATE
											  ,LAST_UPDATE_LOGIN
											 )
								VALUES (p_batch_id
									,l_po_inv_list_new(n).receipt_num
									,'0'
									,0
									,0
									,0
									,0
									,l_po_inv_list_new(n).supplier_site_code
									,'M'  -- record_type
									,l_po_inv_list_new(n).ship_to_location_code
									,l_po_inv_list_new(n).po_number
									,decode(l_po_inv_list_new(n).invoice_currency_code, 'USD', 'US', 'CAD', 'CA')
									,'USTR'  -- Company value is hardcoded
									,0  -- po_line_num
									,0    -- seq_nmbr  constant here
									,l_po_inv_list_new(n).po_line_id
									,l_po_inv_list_new(n).invoice_id
									,l_po_inv_list_new(n).inv_line_num
									,NULL
									,NULL
									,gn_request_id
									,gn_user_id
									,sysdate
									,gn_user_id
									,sysdate
									,gn_login_id
									);
		--COMMIT;
	EXCEPTION
		WHEN OTHERS THEN
		   print_debug_msg('match_recpt_generate() - Bulk Exception raised when inserting',TRUE);
		   ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		   FOR i IN 1..ln_err_count
		   LOOP
			  ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			  lc_error_msg := SUBSTR('Bulk Exception - Failed to Insert value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			  print_debug_msg('Record_Line_id=['||to_char(l_po_inv_list_new(ln_error_idx).po_number)||'-'||to_char(l_po_inv_list_new(ln_error_idx).po_line_num)||'-'||to_char(l_po_inv_list_new(ln_error_idx).receipt_num)||'], Error msg=['||lc_error_msg||']'
			   ,TRUE);
		   END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'match_recpt_generate() - Bulk Exception raised while inserting. Pls. check the debug log.';
			raise data_exception;
	END;


	/**
	BEGIN
		FORALL i in 1..ln_rec_cnt
			SAVE EXCEPTIONS
			UPDATE rcv_shipment_headers rsh
			SET attribute5 = 'Y'
			WHERE rsh.shipment_header_id = l_po_inv_list_new(i).shipment_header_id;


	EXCEPTION
		WHEN data_exception THEN
			raise data_exception;
		WHEN OTHERS THEN
			print_debug_msg('match_recpt_generate() - Error when marking receipts as matched - '||substr(SQLERRM,1,500),TRUE);
			lc_error_msg  := 'match_recpt_generate() - Exception when marking receipts as matched - '||substr(SQLERRM,1,500);
			raise data_exception;

		   ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		   FOR i IN 1..ln_err_count
		   LOOP
			  ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			  lc_error_msg := SUBSTR('Bulk Exception - Failed to Update Receipt Mark - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			  print_debug_msg('Record_Line_id=['||to_char(l_po_inv_list_new(ln_error_idx).po_number)||'-'||to_char(l_po_inv_list_new(ln_error_idx).po_line_num)||'-'||to_char(l_po_inv_list_new(ln_error_idx).receipt_num)||'], Error msg=['||lc_error_msg||']'
			   ,TRUE);
		   END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'match_recpt_generate() - Bulk Exception raised while updating receipt mark. Pls. check the debug log.';

	END;

	**/

	BEGIN
		FORALL i in 1..ln_upd_rcpt_cnt SAVE EXCEPTIONS
		UPDATE XX_PO_SUPERTRANS_USED_RCPTS xpst
		SET xpst.unmatched_qty = l_upd_po_rcpt_list(i).unmatch_qty_rcv
		    ,last_updated_by = gn_user_id
			,last_update_date = sysdate
			,last_update_login = gn_login_id
		WHERE supertrans_type = 'M'
		  AND l_upd_po_rcpt_list(i).line_status = 'U'
		  AND xpst.shipment_header_id = l_upd_po_rcpt_list(i).shipment_header_id
		  AND xpst.shipment_line_id = l_upd_po_rcpt_list(i).shipment_line_id
		  AND l_upd_po_rcpt_list(i).unmatch_qty_rcv > 0;

		print_debug_msg('match_recpt_generate() - updated existed matched receipts', TRUE);

	EXCEPTION
	WHEN OTHERS THEN
			print_debug_msg('match_recpt_generate() - Bulk Exception raised when update to table XX_PO_SUPERTRANS_USED_RCPTS',TRUE);

		    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		    FOR i IN 1..ln_err_count
		    LOOP
			    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			    lc_error_msg := SUBSTR('Bulk Exception - Failed to update value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			    print_debug_msg('po_line_id-receipt_num-shipment_line_id=['||to_char(l_upd_po_rcpt_list(ln_error_idx).po_line_id)||'-'||to_char(l_upd_po_rcpt_list(ln_error_idx).receipt_num)||'-'||to_char(l_upd_po_rcpt_list(ln_error_idx).shipment_line_id)||'], Error msg=['||lc_error_msg||']'
			     ,TRUE);
		    END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'match_recpt_generate() - Bulk Exception raised while updating into table XX_PO_SUPERTRANS_USED_RCPTS. Pls. check the debug log.';
			raise data_exception;
	END;

	BEGIN
		FORALL i in 1..ln_upd_rcpt_cnt SAVE EXCEPTIONS
		DELETE FROM XX_PO_SUPERTRANS_USED_RCPTS xpst
		WHERE xpst.supertrans_type = 'M'
		  AND l_upd_po_rcpt_list(i).line_status = 'U'
		  AND xpst.shipment_header_id = l_upd_po_rcpt_list(i).shipment_header_id
		  AND xpst.shipment_line_id = l_upd_po_rcpt_list(i).shipment_line_id
		  AND l_upd_po_rcpt_list(i).unmatch_qty_rcv = 0;

		print_debug_msg('match_recpt_generate() - Delete existed matched receipts, if value is 0', TRUE);

	EXCEPTION
	WHEN OTHERS THEN
			print_debug_msg('match_recpt_generate() - Bulk Exception raised when delete from table XX_PO_SUPERTRANS_USED_RCPTS',TRUE);

		    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		    FOR i IN 1..ln_err_count
		    LOOP
			    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			    lc_error_msg := SUBSTR('Bulk Exception - Failed to update value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			    print_debug_msg('po_line_id-receipt_num-shipment_line_id=['||to_char(l_upd_po_rcpt_list(ln_error_idx).po_line_id)||'-'||to_char(l_upd_po_rcpt_list(ln_error_idx).receipt_num)||'-'||to_char(l_upd_po_rcpt_list(ln_error_idx).shipment_line_id)||'], Error msg=['||lc_error_msg||']'
			     ,TRUE);
		    END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'match_recpt_generate() - Bulk Exception raised while deleting from table XX_PO_SUPERTRANS_USED_RCPTS. Pls. check the debug log.';
			raise data_exception;
	END;

	BEGIN
		FORALL i in 1..ln_ins_rcpt_cnt SAVE EXCEPTIONS
		INSERT INTO XX_PO_SUPERTRANS_USED_RCPTS
						(
						 po_line_id
						,receipt_num
						,shipment_header_id
						,shipment_line_id
						,quantity_received
						,unmatched_qty
						,supertrans_type
						,created_by
						,creation_date
						,last_updated_by
						,last_update_date
						,last_update_login
						)
					VALUES(
						 l_ins_po_rcpt_list(i).po_line_id
						,l_ins_po_rcpt_list(i).receipt_num
						,l_ins_po_rcpt_list(i).shipment_header_id
						,l_ins_po_rcpt_list(i).shipment_line_id
						,l_ins_po_rcpt_list(i).quantity_received
						,l_ins_po_rcpt_list(i).unmatch_qty_rcv
						,'M'
						,gn_user_id
						,sysdate
						,gn_user_id
						,sysdate
						,gn_login_id
					);
		print_debug_msg('adj_cost_generate() - inserted new matched receipts count is '||ln_ins_rcpt_cnt, TRUE);
	EXCEPTION
		WHEN OTHERS THEN
			print_debug_msg('adj_cost_generate() - Bulk Exception raised while inserting into table XX_PO_SUPERTRANS_USED_RCPTS',TRUE);

		    ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		    FOR i IN 1..ln_err_count
		    LOOP
			    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			    lc_error_msg := SUBSTR('Bulk Exception - Failed to update to table XX_PO_SUPERTRANS_USED_RCPTS and error value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			    print_debug_msg('po_line_id-receipt_num-shipment_line_id=['||to_char(l_ins_po_rcpt_list(ln_error_idx).po_line_id)||'-'||to_char(l_ins_po_rcpt_list(ln_error_idx).receipt_num)||'-'||to_char(l_ins_po_rcpt_list(ln_error_idx).shipment_line_id)||'], Error msg=['||lc_error_msg||']'
			     ,TRUE);
		    END LOOP; -- bulk_err_loop FOR Insert

			ROLLBACK;
			lc_error_msg  := 'adj_cost_generate() - Bulk Exception raised while inserting into table XX_PO_SUPERTRANS_USED_RCPTS. Pls. check the debug log.';
			raise data_exception;
	END;

	--COMMIT;
	p_retcode := 0;
	p_errbuf  := NULL;

	print_debug_msg('End - match_recpt_generate', TRUE);

	EXCEPTION
	WHEN data_exception THEN
		p_retcode := 2;
		p_errbuf  := lc_error_msg;
	WHEN OTHERS THEN
		lc_error_msg := 'match_recpt_generate() - '||substr(sqlerrm,1,250);
		print_debug_msg ('ERROR process_supertrans_ob - '||lc_error_msg, TRUE);
		p_retcode := 2;
		p_errbuf  := lc_error_msg;
 END  match_recpt_generate;

 -- +============================================================================================+
 -- |  Name	  : process_supertrans_ob                                                             	 |
 -- |  Description: This procedure reads data from the PO, INV and Receipts table and prepares   |
 -- |               outbound file for supertrans.												 |
 -- |               Inovkes from "OD: PO Super Trans Outbound"			                         |
 -- =============================================================================================|
PROCEDURE process_supertrans_ob(p_errbuf  OUT  VARCHAR2
                         ,p_retcode       OUT  NUMBER
                         ,p_acct_run_date IN   VARCHAR2
                      	 ,p_debug         IN   VARCHAR2)
 AS
    lc_error_msg       		VARCHAR2(1000) := NULL;
    lc_error_loc       		VARCHAR2(100) := 'XX_PO_WMS_SUPERTRANS_OB_PKG.process_supertrans_ob';
    ln_retry_hdr_count 		NUMBER;
    ln_retry_lin_count 		NUMBER;
    lc_retcode	       		VARCHAR2(3)    := NULL;
    ln_iretcode	       		NUMBER;
    lc_uretcode	       		VARCHAR2(3)    := NULL;
    lc_req_data        		VARCHAR2(30);
    ln_child_request_status     VARCHAR2(1) := NULL;

    lc_continue				VARCHAR2(1)    := 'Y';
    ld_acct_run_date  DATE;
	  ln_batch_id				NUMBER;
    data_exception    EXCEPTION;

 BEGIN
    gc_debug	  := p_debug;
    gn_request_id := fnd_global.conc_request_id;
    gn_user_id    := fnd_global.user_id;
    gn_login_id   := fnd_global.login_id;

    print_debug_msg('Check Retry Errors', TRUE);
	print_out_msg('p_acct_run_date is '||p_acct_run_date);
	print_out_msg('Concurrent Request is '||gn_request_id);

	IF p_acct_run_date IS NULL THEN
		  print_debug_msg('Accounting Date is Mandatory', TRUE);
			lc_error_msg  := 'Accounting Date is Mandatory';
			raise data_exception;
	END IF;


	/** -- Planning to do archive the data instead of delete
	-- 0. Delete the records age older than an year
	--
	BEGIN
		DELETE FROM xx_po_wms_supertrans_ob WHERE creation_date <= sysdate-365;
		print_debug_msg('Deleted age old records of sysdate-365', TRUE);
		commit;
	EXCEPTION
		WHEN OTHERS THEN
			print_debug_msg('Exception when deleting age old records '||SUBSTR(SQLERRM, 1, 3800), TRUE);
			lc_error_msg  := 'Exception when deleting age old records as: '||SUBSTR(SQLERRM, 1, 500);
			raise data_exception;
	END;

	**/

	ld_acct_run_date := fnd_date.canonical_to_date(p_acct_run_date);

	SELECT xx_po_wms_supertrans_ob_s.NEXTVAL
		INTO ln_batch_id
	FROM dual;

    print_debug_msg('batch_id is '||ln_batch_id, TRUE);

		lc_continue := 'Y';
	-- 1. Invoke adj_cost_generate

			adj_cost_generate(p_errbuf     => lc_error_msg
                         ,p_retcode        => ln_iretcode
                         ,p_batch_id       => ln_batch_id
                         ,p_acct_run_date  => ld_acct_run_date
                      	 ,p_debug          => p_debug);

	   IF ln_iretcode <> 0 THEN
			lc_continue := 'N';
	   END IF;

	-- 2. Invoke match_receipt_generate

		IF lc_continue = 'Y' THEN

			match_recpt_generate(p_errbuf  => lc_error_msg
                         ,p_retcode        => ln_iretcode
                         ,p_batch_id       => ln_batch_id
                         ,p_acct_run_date  => ld_acct_run_date
                      	 ,p_debug          => p_debug);

		   IF ln_iretcode <> 0 THEN
				lc_continue := 'N';
		   END IF;
		END IF;

	-- 3. populate_supertrans_file

		IF lc_continue = 'Y' THEN

			populate_supertrans_file(p_errbuf   => lc_error_msg
                         ,p_retcode        => ln_iretcode
                         ,p_batch_id       => ln_batch_id
                      	 ,p_debug          => p_debug);

		   IF ln_iretcode <> 0 THEN
				lc_continue := 'N';
		   END IF;
		END IF;

        IF ln_iretcode = 0 THEN
		   COMMIT;  -- Only if both Adjust Cost and Match completes successfully then commit else fail all.
           print_debug_msg('Completed PO Supertrans Outbound Interface......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'), TRUE);
        ELSIF ln_iretcode = 1 THEN
           p_retcode := 1;
           p_errbuf  := lc_error_msg;
           print_debug_msg('In Warning, PO Supertrans Outbound Interface......:: '||lc_error_msg, TRUE);
        ELSIF ln_iretcode = 2 THEN
           p_retcode := 2;
           p_errbuf  := lc_error_msg;
           print_debug_msg('In Error, PO Supertrans Outbound Interface......:: '||lc_error_msg, TRUE);
        END IF;

 EXCEPTION
 WHEN data_exception THEN
    p_retcode := 2;
    p_errbuf  := lc_error_msg;
 WHEN others THEN
    lc_error_msg := substr(sqlerrm,1,250);
    print_debug_msg ('ERROR process_supertrans_ob - '||lc_error_msg, TRUE);
    p_retcode := 2;
    p_errbuf  := lc_error_msg;
 END process_supertrans_ob;

END XX_PO_WMS_SUPERTRANS_OB_PKG;
/
