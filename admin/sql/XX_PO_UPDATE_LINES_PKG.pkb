create or replace 
PACKAGE Body XX_PO_UPDATE_LINES_PKG AS


-- +============================================================================================+
-- |  Office Depot - Project Sprint                                                         |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_UPDATE_LINES_PKG                                                       |
-- |  RICE ID 	 :     			                        |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         07/28/2017   Vinay Singh      Initial version                                  |
-- +============================================================================================+



    g_error_count           NUMBER := 0;
    g_file_name             VARCHAR2(100);
    g_login_id              NUMBER;
    g_user_id               NUMBER;
    cn_commit      CONSTANT INTEGER := 50000;     --- Number of transactions per commit
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


PROCEDURE set_process_status_flag IS

    CURSOR c_set_flag_hdr IS
    SELECT hdr.rowid rid
      --FROM apps.xx_po_headers_conv_stg  hdr
	   FROM apps.xx_po_hdrs_conv_stg hdr
     WHERE hdr.process_flag is null;

    CURSOR c_set_flag_lin IS
    SELECT lin.rowid rid
          ,hdr.interface_header_id
      FROM apps.xx_po_lines_conv_stg lin
          ,apps.xx_po_hdrs_conv_stg  hdr
     WHERE hdr.source_system_ref = lin.source_system_ref
     and lin.process_flag is null;
	
    TYPE tset_flag IS TABLE OF c_set_flag_hdr%ROWTYPE;
	
    t_set_flag tset_flag := tset_flag();

    TYPE tset_lin IS TABLE OF c_set_flag_lin%ROWTYPE;
	
    t_set_lin tset_lin := tset_lin();

    ln_count_hdr INTEGER := 0;
    ln_count_lin INTEGER := 0;

BEGIN

  fnd_file.put_line (fnd_file.LOG,'Updating header and lines status to 1');
  
  fnd_file.put_line (fnd_file.LOG,'Request id :' || ln_request_id);

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
             -- ,interface_header_id = t_set_lin(r).interface_header_id
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




PROCEDURE od_po_update_lines_prc -- (--p_source_system_ref     IN VARCHAR2,
                                   --                  x_retcode            OUT  NUMBER,
                                     --                x_errbuf             OUT  VARCHAR2
                                       --               )

IS



  l_error_log            VARCHAR2(2):= 'N';

  l_error_msg            VARCHAR2(2000);

  l_success_req_cnt      NUMBER;
  
  cn_commit    CONSTANT INTEGER := 50000;  --- Number of transactions per commit and/or bulk limit


  --- Cursor to Fetch records with Success Status

 

  CURSOR cur_validate_req

    IS

		
	SELECT distinct hr.interface_header_id, hr.source_system_ref, li.rowid rid
    FROM xx_po_hdrs_conv_stg hr
        ,xx_po_lines_conv_stg li
    WHERE hr.source_system_ref =  li.source_system_ref;
	
   

   TYPE tsuccess IS TABLE OF cur_validate_req%ROWTYPE;
	  

    t_success tsuccess;

	
  BEGIN

  

      -- fetch all successful records from staging table
 
 

      FND_FILE.PUT_LINE(FND_FILE.LOG,' Starting The PO update Lines Prc ');

  
	 
    

	 OPEN cur_validate_req;

	 LOOP

		   FETCH cur_validate_req
		   BULK COLLECT
		   INTO t_success LIMIT cn_commit;

		   EXIT WHEN t_success.COUNT = 0;

		   FORALL i IN t_success.FIRST .. t_success.LAST
		   
				  UPDATE XX_PO_LINES_CONV_STG
				SET interface_header_id = t_success(i).interface_header_id   -- 15744784
				WHERE   
                  source_system_ref = t_success(i).source_system_ref
				  and rowid = t_success(i).rid;
					         
		
       	   
		   COMMIT;

     		 END LOOP;
			 
	      CLOSE cur_validate_req;  
			   
			    fnd_file.put_line (fnd_file.LOG, 'END PO Update lines PRC');
				
				
				------ Calling update process_flag Procedure---
        
        fnd_file.put_line (fnd_file.LOG, 'Calling update process_flag Procedure');
				
				set_process_status_flag;

           
END;

END XX_PO_UPDATE_LINES_PKG;