CREATE OR REPLACE PACKAGE Body XX_PO_RCV_INTERFACE_STG_PKG AS

-- +===========================================================================+
-- |     Office Depot                                                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name        : XX_PO_RCV_INTERFACE_STG_PKG
-- | Description : Package Body
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version    Date          Author           Remarks
-- |=======    ==========    =============    =================================+
-- |DRAFT 1A   20-FEB-2016   Antonio Morales  Initial draft version  
-- |
-- |Objective: Read a sequential file from inbound directory to get the Receiving
-- |           records to be converted and insert them in the corresponding
-- |           table for receiving header and transactions staging tables
-- |
-- |Concurrent Program: OD: PO Receiving Conversion Staging Program
-- |                    XXPORCVCNVST

-- +===========================================================================+

    cc_col_sep   CONSTANT VARCHAR2(1) := '|';   --- Character to separate columns in text file
    cn_commit    CONSTANT INTEGER := 10000;     --- Number of transactions per commit
	cc_module    CONSTANT VARCHAR2(100) := 'XX_PO_RCV_INTERFACE_STG_PKG'; 

-- global variables

    g_error_count           NUMBER := 0;
    g_file_name             VARCHAR2(100);
    g_login_id              NUMBER;
    g_user_id               NUMBER;

    lc_input_file_handle    utl_file.file_type;
    ln_request_id           INTEGER := fnd_global.conc_request_id();
    lc_curr_line            VARCHAR2 (32000);
    ln_debug_level          INTEGER := oe_debug_pub.g_debug_level;
    lc_errbuf               VARCHAR2(4000);
    ln_retcode              INTEGER;
    ln_record_count_hdr     INTEGER := 0;
    ln_record_count_det     INTEGER := 0;
    ln_record_count_err     INTEGER := 0;
    ln_record_count_tot     INTEGER := 0;
    ln_record_count_qty     INTEGER := 0;
    ln_record_count_skp     INTEGER := 0;
    lb_has_records          BOOLEAN;
    lc_error_flag           VARCHAR2(1) := 'N';
    lc_message              VARCHAR2(100);
    ln_start                INTEGER;
	ln_end                  INTEGER;
	ln_instr                INTEGER;
	lc_buffer               VARCHAR2(32000);

    lc_prev_type            VARCHAR2(50) := NULL;
    lc_prev_key             VARCHAR2(50) := NULL;
    lc_prev_po              VARCHAR2(50) := NULL;

    ln_first                INTEGER := 0;

	ln_vendor_index         INTEGER;
	
    TYPE tarray IS TABLE OF VARCHAR2(4000);
	
    t_array tarray := tarray();

    lt_ap_location          xx_po_rcpts_stg.ap_location%TYPE;
    lt_ap_keyrec            xx_po_rcpts_stg.ap_keyrec%TYPE;
    lt_ap_po_number         xx_po_rcpts_stg.ap_po_number%TYPE;
    lt_ap_po_vendor         xx_po_rcpts_stg.ap_po_vendor%TYPE;
    lt_ap_rcvd_date         xx_po_rcpts_stg.ap_rcvd_date%TYPE;
    lt_ap_po_date           xx_po_rcpts_stg.ap_po_date%TYPE;
    lt_ap_ship_date         xx_po_rcpts_stg.ap_ship_date%TYPE;
    lt_ap_frt_bill_no       xx_po_rcpts_stg.ap_frt_bill_no%TYPE;
    lt_ap_buyer_code        xx_po_rcpts_stg.ap_buyer_code%TYPE;
    lt_ap_freight_terms     xx_po_rcpts_stg.ap_freight_terms%TYPE;
    lt_receipt_num          xx_po_rcpts_stg.receipt_num%TYPE;

    ln_header_s             INTEGER;
    ln_group_s              INTEGER;

PROCEDURE main(x_retcode  OUT NOCOPY NUMBER
              ,x_errbuf   OUT NOCOPY VARCHAR2
              ,p_filepath IN         VARCHAR2
              ,p_filename IN         VARCHAR2
              ) AS


PROCEDURE save_hdr IS

BEGIN

     lt_ap_location      := lpad(t_array(2),4,'0');
     lt_ap_keyrec        := t_array(3);
     lt_ap_po_number     := t_array(6)||'-'||lpad(substr(lt_ap_location,length(lt_ap_location)-3),4,'0');
     lt_ap_po_vendor     := t_array(7);
     lt_ap_rcvd_date     := trim(t_array(9));
     lt_ap_po_date       := t_array(10);
     lt_ap_ship_date     := t_array(11);
     lt_ap_frt_bill_no   := t_array(13);
     lt_ap_buyer_code    := t_array(15);
     lt_ap_freight_terms := t_array(16);
     lt_receipt_num      := t_array(30);

     SELECT rcv_headers_interface_s.NEXTVAL 
           ,rcv_interface_groups_s.NEXTVAL
       INTO ln_header_s
           ,ln_group_s
       FROM dual;

     ln_record_count_hdr := ln_record_count_hdr + 1;

END save_hdr;

PROCEDURE insert_det_stg IS

BEGIN

                 -- Insert in staging table

                 INSERT
                   INTO xx_po_rcpts_stg
                      (control_id
                      ,process_flag
                      ,conv_action
                      ,source_system_code
                      ,source_system_ref
                      ,creation_date
                      ,last_update_date
                      ,ap_location
                      ,ap_keyrec
                      ,ap_po_number
                      ,ap_po_vendor
                      ,ap_rcvd_date -- expected rcvd date
                      ,ap_po_date
                      ,ap_ship_date
                      ,ap_frt_bill_no
                      ,ap_buyer_code
                      ,ap_freight_terms
                      ,ap_po_line_no    -- 6
                      ,ap_sku           -- 7 
                      ,ap_vendor_item   -- 8
                      ,ap_description   -- 9
                      ,ap_rcvd_quantity -- 17
                      ,ap_rcvd_cost     -- 11
                      ,ap_vendor_prodcd -- 12
                      ,ap_seq_no1       -- 14
                      ,receipt_num
                      ,header_interface_id
                      ,group_id
                      ,interface_transaction_id
                      ,quantity
                      ) 
                  VALUES
                      (xx_po_poconv_stg_s.NEXTVAL
                      ,DECODE(NVL(to_number(t_array(6)),0),0,9,1) -- process flag= (if line number = 0 then flag = 9 else flag = 1)
                                                                  -- Defect NAIT-12523 Skip PO Lines = 0
                      ,'CREATE'
                      ,'ODRCV'         -- source_system_code
					  ,lt_ap_po_number
                      ,systimestamp
                      ,systimestamp
                      ,lt_ap_location
                      ,lt_ap_keyrec
                      ,lt_ap_po_number
                      ,lt_ap_po_vendor
                      ,lt_ap_rcvd_date
                      ,lt_ap_po_date
                      ,lt_ap_ship_date
                      ,lt_ap_frt_bill_no
                      ,lt_ap_buyer_code
                      ,lt_ap_freight_terms
                      ,t_array(6)
                      ,t_array(7)
                      ,t_array(8)
                      ,t_array(9)
                      ,t_array(17) -- unbilled-qty
                      ,t_array(11)
                      ,t_array(12)
                      ,t_array(14)
                      ,lt_receipt_num
                      ,ln_header_s
                      ,ln_group_s
                      ,rcv_transactions_interface_s.NEXTVAL
                      ,t_array(10)  -- original rcvd qty
                      );
         IF NVL(to_number(t_array(6)),0) = 0 THEN
            ln_record_count_skp := ln_record_count_skp + 1;
         ELSE
            ln_record_count_det := ln_record_count_det + 1;
         END IF;


         IF mod(ln_record_count_det,cn_commit) = 0 THEN
            COMMIT;
         END IF;

EXCEPTION
  WHEN OTHERS THEN
       fnd_file.put_line(fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
       fnd_file.put_line(fnd_file.LOG,sqlerrm);
       fnd_file.put_line(fnd_file.LOG,'Unexpected error in Process:'||sqlerrm);
       lc_error_flag := 'Y';
       ROLLBACK;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END insert_det_stg;
-------- MAIN --------

 BEGIN

    BEGIN
        fnd_file.put_line (fnd_file.LOG, 'Parameters ');
        fnd_file.put_line (fnd_file.LOG, 'File Path : [' || p_filepath||']');
        fnd_file.put_line (fnd_file.LOG, 'File Name : [' || p_filename||']');

        lc_input_file_handle := UTL_FILE.fopen(p_filepath, p_filename, 'R');
        fnd_file.put_line (fnd_file.LOG, 'File opened Successful');

        fnd_file.put_line (fnd_file.OUTPUT, 'OD: PO Receiving Conversion Staging Program');
        fnd_file.put_line (fnd_file.OUTPUT, '=========================================== ');
        fnd_file.put_line (fnd_file.OUTPUT, ' ');
        fnd_file.put_line (fnd_file.OUTPUT, ' ');

    EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'Invalid Path: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_mode THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_filehandle THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'Invalid file handle: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_operation THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'Invalid operation: ' || SQLERRM ||' => '||p_filename );
         lc_errbuf := 'Can not find the Receiving file: '||p_filename||' in '||p_filepath;
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.read_error THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'Read Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.write_error THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'Write Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.internal_error THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'Internal Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN NO_DATA_FOUND THEN
         fnd_file.put_line (fnd_file.OUTPUT,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'No data found: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN VALUE_ERROR THEN
         fnd_file.put_line (fnd_file.OUTPUT,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG, 'Value Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         UTL_FILE.fclose (lc_input_file_handle);
         RAISE FND_API.G_EXC_ERROR;
    END;

    lb_has_records := TRUE;
    g_file_name := p_filename;

    BEGIN
      ln_record_count_hdr := 0;
      ln_record_count_det := 0;
      LOOP
        BEGIN
            lc_curr_line := NULL;
            /* UTL FILE READ START */
            UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            fnd_file.put_line (fnd_file.LOG, 'End of File');
            lb_has_records := FALSE;
        WHEN OTHERS THEN
          x_retcode := 2;
          fnd_file.put_line(FND_FILE.LOG,'Unexpected error '||substr(sqlerrm,1,200));
          x_errbuf := 'Please check the log file for error messages';
          lb_has_records := FALSE;
          RAISE FND_API.G_EXC_ERROR;
        END;

        IF NOT lb_has_records THEN
           IF ln_record_count_hdr = 0 THEN
		      fnd_file.put_line(fnd_file.LOG, 'Empty File');
		      fnd_file.put_line(fnd_file.OUTPUT, 'Empty File');
           ELSE 
              fnd_file.put_line (fnd_file.LOG, 'Records processed for headers = '||ln_record_count_hdr);
              fnd_file.put_line (fnd_file.LOG, 'Records processed for detail  = '||ln_record_count_det);
              fnd_file.put_line (fnd_file.LOG, 'Records skipped               = '||ln_record_count_skp);
              fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for headers = '||
                                 lpad(to_char(ln_record_count_hdr,'99,999,990'),12));
              fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for detail  = '||
                                 lpad(to_char(ln_record_count_det,'99,999,990'),12));
              fnd_file.put_line (fnd_file.OUTPUT, 'Records skipped               = '||
                                 lpad(to_char(ln_record_count_skp,'99,999,990'),12));
           END IF;
  
           UTL_FILE.fclose (lc_input_file_handle);
           EXIT;  -- exit infint loop
        END IF;

-- Parse line in columns separated by cc_col_sep previously defined

        ln_start := 1;
		ln_end   := length(lc_curr_line);
        ln_record_count_tot := ln_record_count_tot + 1;
		
		lc_buffer := lc_curr_line;
		ln_instr  := 1;

        IF t_array.EXISTS(1) THEN
		   t_array.DELETE;
		END IF;

        WHILE ln_instr < ln_end 
		LOOP

           t_array.EXTEND;
           ln_instr := instr(lc_buffer,cc_col_sep)-1;
           ln_instr := CASE WHEN ln_instr < 0 THEN ln_end ELSE ln_instr END;
           t_array(t_array.COUNT) := trim(substr(lc_buffer,1,ln_instr));
           lc_buffer := substr(lc_buffer, ln_instr + 2);

        END LOOP;

        IF NVL(lc_prev_key,'NN') <> t_array(3) THEN
           IF NVL(t_array(5),'N') <> 'A' THEN
              fnd_file.put_line(fnd_file.log,'File not in sequence, cannot process');
              RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
           END IF;
           lc_prev_key  := t_array(3);
           lc_prev_po   := t_array(6);
           lc_prev_type := t_array(5);
        END IF;

        IF t_array(5) IS NULL THEN
           insert_det_stg;
        ELSE
           save_hdr;
        END IF;

      END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
	        fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            fnd_file.put_line(fnd_file.log,'Unexpected error in Process :'||sqlerrm);
            lc_error_flag := 'Y';
            UTL_FILE.fclose (lc_input_file_handle);
            ROLLBACK;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END;

    x_retcode := 0;

EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
 	    fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        fnd_file.put_line (fnd_file.LOG,lc_errbuf);
        fnd_file.put_line(FND_FILE.LOG,'Error in reading the file :'||SQLERRM);
        ROLLBACK;
        x_retcode := 2;
        x_errbuf := SQLERRM;
        fnd_file.put_line (fnd_file.LOG, 'Records processed for headers = '||ln_record_count_hdr);
        fnd_file.put_line (fnd_file.LOG, 'Records processed for detail  = '||ln_record_count_det);
        fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for headers = '||
                           lpad(to_char(ln_record_count_hdr,'99,999,990'),12));
        fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for detail  = '||
                           lpad(to_char(ln_record_count_det,'99,999,990'),12));
        RAISE fnd_api.g_exc_error;
    WHEN OTHERS THEN
	    fnd_file.put_line(fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        fnd_file.put_line(FND_FILE.LOG,'Unexpected error in Process :'||SQLERRM);
        ROLLBACK;
        x_retcode := 2;
        x_errbuf := SQLERRM;
        fnd_file.put_line (fnd_file.LOG, 'Records processed for headers = '||ln_record_count_hdr);
        fnd_file.put_line (fnd_file.LOG, 'Records processed for detail  = '||ln_record_count_det);
        fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for headers = '||
                           lpad(to_char(ln_record_count_hdr,'99,999,990'),12));
        fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for lines   = '||
                           lpad(to_char(ln_record_count_det,'99,999,990'),12));
        RAISE fnd_api.g_exc_error;

END main;

END xx_po_rcv_interface_stg_pkg;
/