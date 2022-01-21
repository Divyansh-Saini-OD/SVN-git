CREATE OR REPLACE PACKAGE Body APPS.XX_PO_POM_INTERFACE_STG_PKG AS

-- +===========================================================================+
-- |    Office Depot - Project Simplify                                        |
-- |     Office Depot                                                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_PO_POM_INTERFACE_PKG
-- | Description      : Package Body
-- |
-- |
-- |
-- |Change Record:
-- |
-- |===============
-- |
-- |Version    Date          Author           Remarks
-- |=======    ==========    =============    =================================+
-- |DRAFT 1A   12-DEC-2016   Antonio Morales  Initial draft version  
-- |
-- |Objective: Read a sequential file from inbound directory to get the POM
-- |           records to be converted and insert them in the corresponding
-- |           table for header and lines stagging tables
-- |
-- |Concurrent Program: OD: PO Purchase Order Conversion Staging Program
-- |                    XXPOCNVST

-- +===========================================================================+

    cc_col_sep     CONSTANT VARCHAR2(1) := '|';   --- Character to separate columns in text file
    cn_commit      CONSTANT INTEGER := 50000;     --- Number of transactions per commit
	cc_module      CONSTANT VARCHAR2(100) := 'XX_PO_POM_INTERFACE_STG_PKG'; 

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
    ln_record_count_lin     INTEGER := 0;
    ln_record_count_err     INTEGER := 0;
    ln_record_count_tot     INTEGER := 0;
    ln_record_count_qty     INTEGER := 0;
    lb_has_records          BOOLEAN;
    lc_error_flag           VARCHAR2(1) := 'N';
    lc_message              VARCHAR2(100);
    ln_start                INTEGER;
	ln_end                  INTEGER;
	ln_instr                INTEGER;
	lc_buffer               VARCHAR2(32000);

	ln_vendor_index         INTEGER;
	
    TYPE tarray IS TABLE OF VARCHAR2(4000);
	
    t_array tarray := tarray();

PROCEDURE set_process_status_flag IS

    CURSOR c_set_flag_hdr IS
    SELECT hdr.rowid rid
      FROM apps.xx_po_hdrs_conv_stg  hdr
     WHERE hdr.request_id = ln_request_id;

    CURSOR c_set_flag_lin IS
    SELECT lin.rowid rid
          ,hdr.interface_header_id
      FROM apps.xx_po_lines_conv_stg lin
          ,apps.xx_po_hdrs_conv_stg  hdr
     WHERE lin.request_id = ln_request_id
       AND hdr.source_system_ref = lin.source_system_ref;
	
    TYPE tset_flag IS TABLE OF c_set_flag_hdr%ROWTYPE;
	
    t_set_flag tset_flag := tset_flag();

    TYPE tset_lin IS TABLE OF c_set_flag_lin%ROWTYPE;
	
    t_set_lin tset_lin := tset_lin();

    ln_count_hdr INTEGER := 0;
    ln_count_lin INTEGER := 0;

BEGIN

  fnd_file.put_line (fnd_file.LOG,'Updating header and lines status to 1');

  OPEN c_set_flag_hdr;

  LOOP
     FETCH c_set_flag_hdr
	  BULK COLLECT
	  INTO t_set_flag LIMIT cn_commit;

     EXIT WHEN t_set_flag.COUNT = 0;
  
     FORALL r IN t_set_flag.FIRST .. t_set_flag.LAST
            UPDATE apps.xx_po_hdrs_conv_stg
		       SET process_flag = 1
             WHERE rowid = t_set_flag(r).rid;

     ln_count_hdr := ln_count_hdr + SQL%ROWCOUNT;

     COMMIT;

  END LOOP;

  CLOSE c_set_flag_hdr;

  OPEN c_set_flag_lin;

  LOOP
     FETCH c_set_flag_lin
	  BULK COLLECT
	  INTO t_set_lin LIMIT cn_commit;

     EXIT WHEN t_set_lin.COUNT = 0;
  

     FORALL r IN t_set_lin.FIRST .. t_set_lin.LAST
            UPDATE apps.xx_po_lines_conv_stg
		       SET process_flag = 1
                  ,interface_header_id = t_set_lin(r).interface_header_id
             WHERE rowid = t_set_lin(r).rid;

     ln_count_lin := ln_count_lin + SQL%ROWCOUNT;
	 
     COMMIT;


  END LOOP;
  
  CLOSE c_set_flag_lin;

  fnd_file.put_line (fnd_file.LOG,'Updated headers status to 1 = '||lpad(to_char(ln_count_hdr,'99,999,990'),12));
  fnd_file.put_line (fnd_file.LOG,'Updated lines status to 1   = '||lpad(to_char(ln_count_lin,'99,999,990'),12));

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         fnd_file.put_line (fnd_file.LOG,sqlerrm);
         RAISE;

END set_process_status_flag;

PROCEDURE main(x_retcode  OUT NOCOPY NUMBER
              ,x_errbuf   OUT NOCOPY VARCHAR2
              ,p_filepath IN         VARCHAR2
              ,p_filename IN         VARCHAR2
              ) AS

 lc_rec_type         VARCHAR2(1);
 lc_rec_status       VARCHAR2(1);

PROCEDURE insert_headers IS

  ln_rec_id   INTEGER;

BEGIN

   SELECT xx_po_poconv_stg_s.NEXTVAL
     INTO ln_rec_id
	 FROM dual;

-- Insert in headers stagging table
                 INSERT
                   INTO xx_po_hdrs_conv_stg
                      (control_id           
                      ,conv_action            
                      ,source_system_code   --1
                      ,source_system_ref    
                      ,audit_id             
                      ,record_id            
					  ,interface_header_id  
                      ,document_num         --1 || 4
                      ,currency_code        --2
                      ,vendor_site_code     --3
                      ,ship_to_location     --4
                      ,fob                  --5
                      ,freight_terms        --6
                      ,note_to_vendor       --7
                      ,note_to_receiver     --8
                      ,approval_status      
                      ,closed_code          --9
                      ,vendor_doc_num       --1
                      ,attribute10          --10
                      ,creation_date        --11
                      ,last_update_date     --12
                      ,reference_num        
                      ,vendor_num           --3 
                      ,rate_type            --13
                      ,agent_id             
					  ,request_id           
                      ,distribution_code    --16
                      ,po_type              --17
                      ,num_lines            --18
                      ,cost                 --19
                      ,ord_rec_shpd         --20
                      ,lb                   --21
                      ,net_po_total_cost    --22
                      ,drop_ship_flag       --23
                      ,ship_via             --25
                      ,back_orders          --26
                      ,order_dt             --27
                      ,ship_dt              --28
                      ,arrival_dt           --29
                      ,cancel_dt            --30
                      ,release_date         --31
                      ,revision_flag        --32
                      ,last_ship_dt         --33
                      ,last_receipt_dt      --34
                      ,terms_disc_pct       --35
                      ,terms_disc_days      --36
                      ,terms_net_days       --37
                      ,allowance_basis_code --38
                      ,allowance_dollars    --39
                      ,allowance_percent    --40
                      ,pom_created_by       --41
                      ,pgm_entered_by       --43
                      ,pom_changed_by       --44
                      ,pgm_changed_by       --46
                      ,cust_order_sub_nbr   --47
                      ,cust_order_nbr       --48
                      ,attribute15          --1 legacy po number
                      ) 
                  VALUES
                      (ln_rec_id
					  ,'CREATE' -- conv_action
                      ,'ODPO'   -- source_system_code
					  ,t_array(1)  --poh.Po_Nbr  => system_ref
                      ,ln_rec_id   -- audit_id
                      ,ln_rec_id   -- record_id
                      ,po_headers_interface_s.NEXTVAL -- interface_header_id 
                      ,t_array(1)||'-'||ltrim(t_array(4),'0')  --poh.Po_Nbr + poh.loc_id -- document_number
                      ,t_array(2)  --poh.Currency_Cd  -- POPR01
                      ,t_array(3)  --poh.Vendor_Id  -- PODR01
                      ,t_array(4)  --poh.Loc_Id
                      ,t_array(5)  --poh.Fob_Cd
                      ,t_array(6)  --poh.Freight_Cd --CC DF PP
					  ,t_array(7)  --note_to_vendor
					  ,t_array(8)  --note_to_receiver
                      ,NULL        -- approval_status
                      ,t_array(9)  --poh.Status_Cd   -- POPR05  -- closed_code
                      ,t_array(1)  --poh.Po_Nbr 
                      ,t_array(10) --gsp.Import_Manual_Po
                      ,CASE WHEN t_array(11) IS NULL THEN NULL
                            ELSE to_date(t_array(11)||nvl(t_array(42),'00.00.00'),'mm/dd/yyyyhh24.mi.ss') --poh.Dt_Ent -- creation_date
                       END
                      ,CASE WHEN t_array(12) IS NULL THEN NULL
                            ELSE to_date(t_array(12)||nvl(t_array(45),'00.00.00'),'mm/dd/yyyyhh24.mi.ss') --poh.Dt_chg -- last_update_date
                       END
                      ,po_headers_interface_s.NEXTVAL  --interface_header_id
                      ,t_array(3)  --poh.Vendor_Id  -- PODR01
                      ,t_array(13) --poh.rate_type
                      ,15335       --agent_id defaulted to AGENT_NAME: Interface Buyer
					  ,ln_request_id
                      ,t_array(16) --Distribution_cd
                      ,t_array(17) --po_type (Type_cd)
                      ,t_array(18) --#Lines
                      ,t_array(19) --Cost
                      ,t_array(20) --Units- ord_rec_shpd
                      ,t_array(21) --LBs (Weight or rec/shp)
                      ,t_array(22) --Net_po_total_cost
                      ,t_array(23) --Drop Ship Flag
                      ,t_array(25) --Ship via
                      ,t_array(26) --Back Orders
                      ,DECODE(t_array(27),NULL,NULL,to_date(t_array(28),'mm/dd/yyyy')) --order_dt
                      ,DECODE(t_array(28),NULL,NULL,to_date(t_array(28),'mm/dd/yyyy')) --Ship_dt
                      ,DECODE(t_array(29),NULL,NULL,to_date(t_array(29),'mm/dd/yyyy')) --Arrival_dt
                      ,DECODE(t_array(30),NULL,NULL,to_date(t_array(30),'mm/dd/yyyy')) --Cancel_dt
                      ,DECODE(t_array(31),NULL,NULL,to_date(t_array(31),'mm/dd/yyyy')) --Release_dt
                      ,t_array(32) --Revision_flag
                      ,DECODE(t_array(33),NULL,NULL,to_date(t_array(33),'mm/dd/yyyy')) --Last Ship_DT
                      ,DECODE(t_array(34),NULL,NULL,to_date(t_array(34),'mm/dd/yyyy')) --Last Receipt_DT
                      ,t_array(35) --Disc %
                      ,t_array(36) --Disc Days
                      ,t_array(37) --Net Days
                      ,t_array(38) --Allowance Basis
                      ,t_array(39) --Allowance Dollars
                      ,t_array(40) --Allowance Percent
                      ,t_array(41) --POM Created By            --
                      ,t_array(43) --Program entered By
                      ,t_array(44) --POM Changed By
                      ,t_array(46) --Program Changed By
                      ,t_array(47) --Non-Codes/Special Orders: Customer #
                      ,t_array(48) --Customer Order #
                      ,t_array(1)  --poh.Po_Nbr -- attribute15
                      );

           ln_record_count_hdr := ln_record_count_hdr + 1;

           IF mod(ln_record_count_hdr,cn_commit) = 0 THEN
              COMMIT;
           END IF;
EXCEPTION
  WHEN OTHERS THEN
       fnd_file.put_line(fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
       fnd_file.put_line(fnd_file.LOG,'Unexpected error in Headers:'||sqlerrm);
       FOR i IN t_array.FIRST .. t_array.LAST
       LOOP
           fnd_file.put_line (fnd_file.LOG,'t_array('||i||')=['||t_array(i)||']');
       END LOOP;
       lc_error_flag := 'Y';
       ROLLBACK;
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

END insert_headers;

PROCEDURE insert_lines AS

BEGIN

                 -- Insert in lines staging table
                 INSERT
                   INTO xx_po_lines_conv_stg
                      (control_id
                      ,conv_action
                      ,source_system_code
                      ,request_id
                      ,source_system_ref
					  ,interface_line_id
                      ,interface_header_id
                      ,line_num
                      ,item
                      ,quantity
                      ,ship_to_location
					  ,need_by_date
				      ,promised_date
                      ,line_reference_num
                      ,uom_code
                      ,unit_price
                      ,line_attribute6
                      ,shipment_num
                      ,dept                 --12
                      ,class                --13
                      ,vendor_product_code  --14
                      ,extended_cost        --15
                      ,qty_shipped          --16
                      ,qty_received         --17
                      ,seasonal_large_order --18
                       ) 
                  VALUES
                      (xx_po_poconv_stg_s.NEXTVAL --control_id
					  ,'CREATE'  -- conv_action
                      ,'ODPO'    -- system_source_code
                      ,ln_request_id -- concurrent request_id
					  ,t_array(1)  -- Po_Nbr => system_source_ref
					  ,po_lines_interface_s.NEXTVAL -- interface_line_id
					  ,t_array(1)  -- Po_Nbr
                      ,t_array(2)  -- Line_num
                      ,t_array(3)  -- Item
                      ,t_array(4)  -- quantity
                      ,t_array(5)  -- ship_to_location
                      ,DECODE(t_array(6),NULL,NULL,to_date(t_array(6),'mm/dd/yyyy'))  -- arrival_date
                      ,DECODE(t_array(7),NULL,NULL,to_date(t_array(7),'mm/dd/yyyy'))  -- arrival_date
                      ,t_array(8)  -- line_reference_num
                      ,t_array(9)  -- uom_code
					  ,t_array(10) -- unit_price
					  ,t_array(11) -- line_attribute6
                      ,1           -- shipment num
                      ,t_array(12) --dept
                      ,t_array(13) --class
                      ,t_array(14) --vendor_product_code
                      ,t_array(15) --extended_cost
                      ,t_array(16) --qty_shipped
                      ,t_array(17) --qty_received
                      ,t_array(18) --seasonal_large_order
                      );

           ln_record_count_lin := ln_record_count_lin + 1;

           IF mod(ln_record_count_lin,cn_commit) = 0 THEN
              COMMIT;
           END IF;
	  
      COMMIT;
      
EXCEPTION
       WHEN OTHERS THEN
	        fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            fnd_file.put_line (fnd_file.LOG,sqlerrm);
            fnd_file.put_line(fnd_file.LOG,'Unexpected error in Process:'||sqlerrm);
            lc_error_flag := 'Y';
            ROLLBACK;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            UTL_FILE.fclose (lc_input_file_handle);

END insert_lines;

-------- MAIN --------
 
 BEGIN

    BEGIN
        fnd_file.put_line (fnd_file.LOG, 'Parameters ');
        fnd_file.put_line (fnd_file.LOG, 'File Path : ' || p_filepath);
        fnd_file.put_line (fnd_file.LOG, 'File Name : ' || p_filename);

        lc_input_file_handle := UTL_FILE.fopen(p_filepath, p_filename, 'R');
        fnd_file.put_line (fnd_file.LOG, 'File opened Successful');

        fnd_file.put_line (fnd_file.OUTPUT, 'OD: PO Purchase Order Conversion Staging Program');
        fnd_file.put_line (fnd_file.OUTPUT, '================================================ ');
        fnd_file.put_line (fnd_file.OUTPUT, ' ');
        fnd_file.put_line (fnd_file.OUTPUT, ' ');

    EXCEPTION
    WHEN UTL_FILE.invalid_path THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Path: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_mode THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid Mode: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_filehandle THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid file handle: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.invalid_operation THEN
         fnd_file.put_line (fnd_file.LOG, 'Invalid operation222: ' || SQLERRM ||'::::'||p_filename );
         lc_errbuf := 'Can not find the Shipping Lane file :'||p_filename||' in '||p_filepath;
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.read_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Read Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.write_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Write Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN UTL_FILE.internal_error THEN
         fnd_file.put_line (fnd_file.LOG, 'Internal Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN NO_DATA_FOUND THEN
         fnd_file.put_line (fnd_file.LOG, 'No data found: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN VALUE_ERROR THEN
         fnd_file.put_line (fnd_file.LOG, 'Value Error: ' || SQLERRM);
         RAISE FND_API.G_EXC_ERROR;
    WHEN OTHERS THEN
         UTL_FILE.fclose (lc_input_file_handle);
         RAISE FND_API.G_EXC_ERROR;
    END;

    lb_has_records := TRUE;
    g_file_name := p_filename;

    BEGIN
      ln_record_count_hdr := 0;
      ln_record_count_lin := 0;
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
              fnd_file.put_line (fnd_file.LOG, 'Records processed for lines   = '||ln_record_count_lin);
              fnd_file.put_line (fnd_file.LOG, 'Invalid Record type           = '||ln_record_count_err);
              fnd_file.put_line (fnd_file.LOG, 'Invalid Records (quantity=0)  = '||ln_record_count_qty);
              fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for headers = '||
                                 lpad(to_char(ln_record_count_hdr,'99,999,990'),12));
              fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for lines   = '||
                                 lpad(to_char(ln_record_count_lin,'99,999,990'),12));
              fnd_file.put_line (fnd_file.OUTPUT, 'Invalid record type           = '||
                                 lpad(to_char(ln_record_count_err,'99,999,990'),12));
              fnd_file.put_line (fnd_file.OUTPUT, 'Invalid records (quantity=0)  = '||
                                 lpad(to_char(ln_record_count_qty,'99,999,990'),12));
           END IF;
  
           UTL_FILE.fclose (lc_input_file_handle);
           EXIT;  -- exit infint loop
        END IF;

-- Parse line in columns separated by cc_col_sep previously defined

           ln_start := 1;
		   ln_end   := length(lc_curr_line);
		   lc_rec_type := substr(lc_curr_line,1,1);
		   lc_rec_status := substr(lc_curr_line,3,1);
           ln_record_count_tot := ln_record_count_tot + 1;
		   
           IF lc_rec_type NOT IN ('H','L') THEN
		      fnd_file.put_line (fnd_file.OUTPUT,'Invalid record type =['||lc_rec_type||'], rec#='||ln_record_count_tot);
		      fnd_file.put_line (fnd_file.LOG,'Invalid record type =['||lc_rec_type||'], rec#='||ln_record_count_tot);
              ln_record_count_err := ln_record_count_err + 1;
			  EXIT;  --- exit main loop
           END IF;

		   lc_buffer := substr(lc_curr_line,5);
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

--        fnd_file.put_line (fnd_file.LOG,'t_array.count='||t_array.COUNT||' type='||lc_rec_type);

--        FOR i IN t_array.FIRST .. t_array.LAST
--        LOOP
--            fnd_file.put_line (fnd_file.LOG,'t_array('||i||')=['||t_array(i)||']');
--        END LOOP;

        IF lc_rec_type = 'H' THEN
		   insert_headers;
		ELSE
           IF NVL(t_array(4),0) > 0 THEN
              insert_lines;
           ELSE
              fnd_file.put_line(fnd_file.log,'Error Quantity = 0 for PO='||t_array(1)||', line='||t_array(2));
              ln_record_count_qty := ln_record_count_qty + 1;
           END IF;
		END IF;

      END LOOP;
	  
    set_process_status_flag;

    EXCEPTION
        WHEN OTHERS THEN
	        fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            fnd_file.put_line(fnd_file.log,'Unexpected error in Process :'||sqlerrm);
            lc_error_flag := 'Y';
            ROLLBACK;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            UTL_FILE.fclose (lc_input_file_handle);
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
        fnd_file.put_line (fnd_file.LOG, 'Records processed for lines   = '||ln_record_count_lin);
        fnd_file.put_line (fnd_file.LOG, 'Invalid Record type           = '||ln_record_count_err);
        fnd_file.put_line (fnd_file.LOG, 'Invalid Records (quantity=0)  = '||ln_record_count_qty);
        fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for headers = '||
                           lpad(to_char(ln_record_count_hdr,'99,999,990'),12));
        fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for lines   = '||
                           lpad(to_char(ln_record_count_lin,'99,999,990'),12));
        fnd_file.put_line (fnd_file.OUTPUT, 'Invalid record type           = '||
                           lpad(to_char(ln_record_count_err,'99,999,990'),12));
        fnd_file.put_line (fnd_file.OUTPUT, 'Invalid records (quantity=0)  = '||
                           lpad(to_char(ln_record_count_qty,'99,999,990'),12));
        RAISE fnd_api.g_exc_error;
    WHEN OTHERS THEN
	    fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        fnd_file.put_line(FND_FILE.LOG,'Unexpected error in Process :'||SQLERRM);
        ROLLBACK;
        x_retcode := 2;
        x_errbuf := SQLERRM;
        fnd_file.put_line (fnd_file.LOG, 'Records processed for headers = '||ln_record_count_hdr);
        fnd_file.put_line (fnd_file.LOG, 'Records processed for lines   = '||ln_record_count_lin);
        fnd_file.put_line (fnd_file.LOG, 'Invalid Record type           = '||ln_record_count_err);
        fnd_file.put_line (fnd_file.LOG, 'Invalid Records (quantity=0)  = '||ln_record_count_qty);
        fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for headers = '||
                           lpad(to_char(ln_record_count_hdr,'99,999,990'),12));
        fnd_file.put_line (fnd_file.OUTPUT, 'Records processed for lines   = '||
                           lpad(to_char(ln_record_count_lin,'99,999,990'),12));
        fnd_file.put_line (fnd_file.OUTPUT, 'Invalid record type           = '||
                           lpad(to_char(ln_record_count_err,'99,999,990'),12));
        fnd_file.put_line (fnd_file.OUTPUT, 'Invalid records (quantity=0)  = '||
                           lpad(to_char(ln_record_count_qty,'99,999,990'),12));
        RAISE fnd_api.g_exc_error;

END main;

END xx_po_pom_interface_stg_pkg;
/