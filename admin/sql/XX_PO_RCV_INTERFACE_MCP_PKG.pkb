CREATE OR REPLACE PACKAGE Body XX_PO_RCV_INTERFACE_MCP_PKG AS

-- +===========================================================================+
-- |    Office Depot - Project Simplify                                        |
-- |     Office Depot                                                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_PO_RCV_INTERFACE_MCP_PKG
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
-- |DRAFT 1A   03-MAR-2016   Antonio Morales  Initial draft version  
-- |
-- |Objective: POM to PO Master Concurrent Program to submit Receipts conversion
-- |           based on parameter max threads
-- |
-- |Concurrent Program: OD: PO Receipts Conversion Master Program
-- |                    XXPORCVCNVMC
-- +===========================================================================+

    cn_commit       CONSTANT INTEGER := 50000;     --- Number of transactions per commit
	cc_module       CONSTANT VARCHAR2(100) := 'XX_PO_RCV_INTERFACE_MCP_PKG';
    cc_procedure    CONSTANT VARCHAR2(100) := 'MASTER_MAIN';
    cn_max_loop     CONSTANT INTEGER := 99999999;     --- Max. time in minutes to wait on an infinit loop

    ln_max_thread           INTEGER := 8;
    ln_request_id           INTEGER := fnd_global.conc_request_id();
    ln_debug_level          INTEGER := oe_debug_pub.g_debug_level;
    ln_hdr_recs             INTEGER := 0;
    ln_txs_recs             INTEGER := 0;
    ln_batch_launched       INTEGER := 0;


PROCEDURE master_main( x_retcode            OUT NOCOPY NUMBER
                      ,x_errbuf             OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag  IN        VARCHAR2  DEFAULT 'N' -- Y/N
                      ,p_reset_status_flag   IN        VARCHAR2  DEFAULT 'N' -- Y/N
                      ,p_max_thread          IN        INTEGER   DEFAULT NULL
                      ,p_debug_flag          IN        VARCHAR2  DEFAULT 'N'
                      ) IS

    lc_message              VARCHAR2(100);

    TYPE rbatch_job IS RECORD
         ( batch_id   INTEGER
          ,job_no     INTEGER
          ,job_status VARCHAR2(100)
         );

    TYPE tbatch_job IS TABLE OF rbatch_job;

    t_batch_job tbatch_job := tbatch_job();

PROCEDURE submit_po_cnv IS

  ln_jobs_sub    INTEGER := 0;
  ln_max_loop    INTEGER := 0;
  ln_active_jobs INTEGER := 0;

  lc_phase       VARCHAR2(100);
  lc_status      VARCHAR2(100);
  lc_dev_phase   VARCHAR2(100);
  lc_dev_status  VARCHAR2(100);
  lc_message     VARCHAR2(4000);

  lb_bool        BOOLEAN;

FUNCTION check_completed_jobs RETURN INTEGER IS

BEGIN

    ln_jobs_sub := 0;

    LOOP

       FOR i IN t_batch_job.FIRST .. t_batch_job.LAST
       LOOP

        IF NVL(t_batch_job(i).job_no,0) > 0 THEN
          IF NVL(t_batch_job(i).job_status,'X') <> 'COMPLETE' THEN
             lb_bool := fnd_concurrent.wait_for_request(request_id => t_batch_job(i).job_no 
                                                       ,interval   => 60
                                                       ,max_wait   => 60
                                                       ,phase      => lc_phase
                                                       ,status     => lc_status
                                                       ,dev_phase  => t_batch_job(i).job_status
                                                       ,dev_status => lc_dev_status
                                                       ,message    => lc_message
                                                       );
             IF t_batch_job(i).job_status = 'COMPLETE' THEN
                fnd_file.put_line(fnd_file.log,'Job '||t_batch_job(i).job_no||', completed.');
                ln_jobs_sub := ln_jobs_sub + 1;
                ln_batch_launched := ln_batch_launched + 1;
                IF ln_jobs_sub = t_batch_job.COUNT THEN
                   RETURN 0;
                END IF;
             END IF;
          ELSE
             ln_max_loop := ln_max_loop + 1;
             IF ln_max_loop > cn_max_loop THEN
                RETURN 1;
             END IF;

          END IF; 
        END IF;

       END LOOP;

    END LOOP;

    RETURN 1;

END check_completed_jobs;

BEGIN
       ---------------------------------------------------------
       -- Submit Concurrent Program for Conversion
       ---------------------------------------------------------
       -- THE XXPORCVCNVCH concurrent program for Receipts Conversion
       -- OD: PO Receipts Conversion Child Program

       fnd_file.put_line(fnd_file.log,'Submitting : '|| 'XXPORCVCNVCH');

       IF t_batch_job.COUNT = 0 THEN
          fnd_file.put_line(fnd_file.log,'Job batch count is 0');
		  RETURN;
       END IF;

       FOR bi IN t_batch_job.FIRST .. t_batch_job.LAST
	   LOOP

           t_batch_job(bi).job_no := fnd_request.submit_request(application => 'XXFIN'
                                                               ,program     => 'XX_CNV_PO_RECEIPT_PKG_CHILD'--'XXPORCVCNVCH'
	                                                           ,argument1   => p_validate_only_flag
			    								               ,argument2   => p_reset_status_flag
                                                               ,argument3   => t_batch_job(bi).batch_id
                                                               ,argument4   => p_debug_flag
                                                               );
           COMMIT;

           IF NVL(t_batch_job(bi).job_no,0) = 0 THEN
              fnd_file.put_line(fnd_file.log,'Error submitting batch='|| t_batch_job(bi).batch_id);
		      t_batch_job(bi).job_status := 'Error';
           ELSE
              ln_jobs_sub := ln_jobs_sub + 1;
              fnd_file.put_line(fnd_file.log,'Submitted batch_id='|| t_batch_job(bi).batch_id||
			                                 ', job_no='|| t_batch_job(bi).job_no);
           END IF;

       END LOOP;

       -- Wait for jobs to complete

       ln_max_loop := 0;
	   
       fnd_file.put_line(fnd_file.log,'Waiting for all the batch jobs to be completed');

       -- Check completed jobs

       IF check_completed_jobs = 1 THEN
          fnd_file.put_line(fnd_file.log,'Loop exceeded '||cn_max_loop||' iterations');
       ELSE
          fnd_file.put_line(fnd_file.log,'All jobs completed');
       END IF;

END submit_po_cnv;

PROCEDURE update_batch_id IS

    CURSOR c_batch IS
    SELECT /*+ parallel(6) */
           DISTINCT ap_po_number
          ,null batch_id
          ,round(count(*) over () / ln_max_thread)+1 numrecs
      FROM xx_po_rcpts_stg
     WHERE (process_flag < 6 AND p_reset_status_flag = 'Y')
        OR (process_flag = 1 AND p_reset_status_flag = 'N');

    TYPE tbatch IS TABLE OF c_batch%ROWTYPE;
	
    t_batch tbatch := tbatch();

    ln_batch_id INTEGER;
    ln_recs     INTEGER := 0;

BEGIN

  fnd_file.put_line(fnd_file.log,'update_batch_id');

  IF t_batch_job.EXISTS(1) THEN
     t_batch_job.DELETE;
  END IF;

  OPEN c_batch;

  LOOP

    FETCH c_batch
	 BULK COLLECT
	 INTO t_batch LIMIT cn_commit;

    EXIT WHEN t_batch.COUNT = 0;

    fnd_file.put_line(fnd_file.log,'rows read='||t_batch.COUNT);

    ln_hdr_recs := ln_hdr_recs + t_batch.COUNT;

    FOR r IN t_batch.FIRST .. t_batch.LAST
	LOOP

       IF ln_recs >= t_batch(r).numrecs OR ln_recs = 0 THEN
          SELECT xx_po_poconv_batchid_s.nextval
            INTO ln_batch_id
            FROM dual;
	      ln_recs := 0;
          t_batch_job.EXTEND;
          t_batch_job(t_batch_job.LAST).batch_id := ln_batch_id;
	   END IF;

	   t_batch(r).batch_id := ln_batch_id;

       SELECT /*+ parallel(6) */
              COUNT(*) + ln_recs
         INTO ln_recs
         FROM xx_po_rcpts_stg
        WHERE ap_po_number = t_batch(r).ap_po_number;

    END LOOP;

    FORALL r IN t_batch.FIRST .. t_batch.LAST
           UPDATE xx_po_rcpts_stg
              SET batch_id = t_batch(r).batch_id
            WHERE ap_po_number = t_batch(r).ap_po_number
              AND NVL(batch_id,-1) <> t_batch(r).batch_id
              AND process_flag+0 < 9;

    FOR r IN t_batch.FIRST .. t_batch.LAST
    LOOP
        ln_txs_recs := ln_txs_recs + SQL%BULK_ROWCOUNT(r);
    END LOOP;

    COMMIT;

  END LOOP;

  CLOSE c_batch;


  fnd_file.put_line (fnd_file.log,'Batch ID Updated');

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		 IF c_batch%ISOPEN THEN
            CLOSE c_batch;
         END IF;
         RAISE;

END update_batch_id;

PROCEDURE reset_process_status_flag IS

    CURSOR c_hdrs IS
    SELECT rowid rid
      FROM xx_po_rcpts_stg stg
     WHERE process_flag < 6;

    TYPE thdrs IS TABLE OF c_hdrs%ROWTYPE;

    t_hdrs thdrs := thdrs();

    ln_count INTEGER := 0;

BEGIN

  fnd_file.put_line (fnd_file.LOG,'Start reset status flag = '||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));

  OPEN c_hdrs;

  LOOP
     FETCH c_hdrs
	  BULK COLLECT
	  INTO t_hdrs LIMIT cn_commit;

     EXIT WHEN t_hdrs.COUNT = 0;
  
     FORALL r_hdr IN t_hdrs.FIRST .. t_hdrs.LAST
            UPDATE xx_po_rcpts_stg
		       SET process_flag = 1
             WHERE rowid = t_hdrs(r_hdr).rid;

     COMMIT;
	 
     ln_count := ln_count + t_hdrs.COUNT;

  END LOOP;

  CLOSE c_hdrs;

  fnd_file.put_line (fnd_file.LOG,'End reset status flag   = '||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));


  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		 IF c_hdrs%ISOPEN THEN
            CLOSE c_hdrs;
         END IF;
         RAISE;

END reset_process_status_flag;

-------------- MAIN --------------

BEGIN

   x_retcode := 0;

   IF p_max_thread IS NULL THEN
      BEGIN

       SELECT NVL(p_max_thread,max_threads)
	     INTO ln_max_thread
         FROM xx_com_conversions_conv
        WHERE conversion_code = 'CXXXX_Receipts';

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           fnd_file.put_line (fnd_file.LOG, 'No data found for CXXXX_PurchaseOrders');
           RAISE;
      WHEN OTHERS THEN
           fnd_file.put_line (fnd_file.LOG, 'Error reading xx_com_conversions_conv, '||sqlerrm);
           RAISE;
      END;
   ELSE
      ln_max_thread := p_max_thread;
   END IF;

   fnd_file.put_line (fnd_file.LOG, 'Parameters ');
   fnd_file.put_line (fnd_file.LOG, ' p_validate_only_flag: ' || p_validate_only_flag);
   fnd_file.put_line (fnd_file.LOG, ' p_max_thread        : ' || ln_max_thread);
   fnd_file.put_line (fnd_file.LOG, ' p_reset_status_flag : ' || p_reset_status_flag);
   fnd_file.put_line (fnd_file.LOG, ' p_debug_flag        : ' || p_debug_flag);

   IF t_batch_job.EXISTS(1) THEN
      t_batch_job.DELETE;
   END IF;

   update_batch_id;

   IF p_reset_status_flag = 'Y' THEN
      reset_process_status_flag;
   END IF;

   submit_po_cnv;

   create_exception_report;

EXCEPTION
    WHEN OTHERS THEN
	    fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        fnd_file.put_line(FND_FILE.LOG,'Unexpected error in '||cc_module||' :'||SQLERRM);
        ROLLBACK;
        x_retcode := 2;
        x_errbuf := SQLERRM;
        raise FND_API.G_EXC_ERROR;

END master_main;

PROCEDURE create_exception_report IS

 CURSOR c_exc IS
 SELECT exe.source_system_ref PO
       ,exe.staging_column_name Error_Field
       ,exe.staging_column_value Error_Value
       ,exe.exception_log Error_Message
       ,DECODE(NVL(oracle_error_code,0),0,NULL,exe.oracle_error_msg) Oracle_Error_Message
   FROM xx_com_exceptions_log_conv exe
  WHERE exe.request_id IN (SELECT DISTINCT request_id
                             FROM xx_po_rcpts_stg
                           WHERE process_flag = 3)
    AND exe.package_name = 'XX_PO_RCV_CONV_PKG'

 ORDER BY 2,1;

 TYPE texc IS TABLE OF c_exc%ROWTYPE;

 t_exc texc;

 CURSOR c_ie IS
 WITH rcp AS
 (
  SELECT DISTINCT 
         ap_po_number
        ,rvctp_request_id
    FROM xx_po_rcpts_stg
 )
 SELECT ie.column_name
       ,ie.error_message
       ,ie.error_message_name
       ,ie.table_name
       ,ie.interface_header_id
       ,ie.column_value
       ,po.ap_po_number po
   FROM po_interface_errors ie
       ,rcp po
  WHERE 1=1
    AND ie.request_id = po.rvctp_request_id
  ORDER BY ie.column_name
          ,po.ap_po_number;

 TYPE tie IS TABLE OF c_ie%ROWTYPE;

 t_ie tie;

 CURSOR c_shdr IS
 SELECT a.*
       ,SUM(pcount) OVER () tcount
   FROM (SELECT count(*) pcount
               ,process_flag
               ,CASE process_flag
                     WHEN 3 THEN 'Validation Error'
                     WHEN 6 THEN 'Interface Error'
                     WHEN 7 THEN 'Successfully Processed'
                  ELSE 'Unknown'
                END status
           FROM xx_po_rcpts_stg a
          WHERE 1=1
          GROUP BY process_flag) a
  ORDER BY process_flag;

 TYPE tshdr IS TABLE OF c_shdr%ROWTYPE;

 t_shdr tshdr;

 CURSOR c_hdrc IS
 SELECT a.*
       ,SUM(pcount) OVER () tcount
   FROM (SELECT count(*) pcount
               ,process_flag
               ,CASE process_flag
                     WHEN 3 THEN 'Validation Error'
                     WHEN 5 THEN 'Validated Only'
                     WHEN 7 THEN 'Successfully Processed'
                     WHEN 9 THEN  'Skipped Cancelled Line'
                  ELSE 'Unknown'
                END status
           FROM (SELECT distinct header_interface_id, process_flag
                   FROM xx_po_rcpts_stg a)
          WHERE 1=1
          GROUP BY  process_flag) a
  ORDER BY process_flag;

 TYPE thdrc IS TABLE OF c_hdrc%ROWTYPE;

 t_hdrc thdrc;

 lc_prec         VARCHAR2(200) := 'XYZ';
 ln_flag         INTEGER := 0;
 ln_error_hdr    INTEGER := 0;
 ln_error_int    INTEGER := 0;
 ln_int_prc      INTEGER := 0;
 ln_skipped      INTEGER := 0;

 ln_error_hdrc   INTEGER := 0;
 ln_error_intc   INTEGER := 0;
 ln_int_prcc     INTEGER := 0;
 ln_valid_onc    INTEGER := 0;


PROCEDURE rpt(text IN VARCHAR2) IS

BEGIN

  fnd_file.put_line (fnd_file.OUTPUT,text);

END rpt;


BEGIN

   OPEN c_shdr;

   FETCH c_shdr
   BULK COLLECT
   INTO t_shdr;

   CLOSE c_shdr;

   OPEN c_hdrc;

   FETCH c_hdrc
   BULK COLLECT
   INTO t_hdrc;

   CLOSE c_hdrc;

   FOR i IN t_shdr.FIRST .. t_shdr.LAST
   LOOP

     IF t_shdr(i).process_flag = 3 THEN
        ln_error_hdr := t_shdr(i).pcount;
     ELSIF t_shdr(i).process_flag = 6 THEN
           ln_error_int := t_shdr(i).pcount;
     ELSIF t_shdr(i).process_flag = 7 THEN
           ln_int_prc := t_shdr(i).pcount;
     ELSIF t_shdr(i).process_flag = 9 THEN
           ln_skipped := t_shdr(i).pcount;
     END IF;

   END LOOP;

   FOR i IN t_hdrc.FIRST .. t_hdrc.LAST
   LOOP

     IF t_hdrc(i).process_flag = 3 THEN
        ln_error_hdrc := t_hdrc(i).pcount;
     ELSIF t_hdrc(i).process_flag = 5 THEN
           ln_valid_onc := t_hdrc(i).pcount;
     ELSIF t_hdrc(i).process_flag = 6 THEN
           ln_error_intc := t_hdrc(i).pcount;
     ELSIF t_hdrc(i).process_flag = 7 THEN
           ln_int_prcc := t_hdrc(i).pcount;
     END IF;

   END LOOP;

   rpt(' ');
   rpt(' ');
   rpt(lpad(' ',30)||'OD: Receipts Conversion Master Program Summary: '||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));
   rpt(lpad(' ',30)||'________________________________________________'||lpad('_',17,'_'));
   rpt(' ');
   rpt(' ');
   rpt('Number of Threads                  - '||lpad(to_char(ln_max_thread,'99,999,990'),12));
   rpt('No. of Batches Launched            - '||lpad(to_char(ln_batch_launched,'99,999,990'),12));

   rpt(' ');
   rpt('Total Line Receipts                - '||lpad(to_char(t_shdr(1).tcount,'99,999,990'),12));
   rpt('No. of Lines Receipts Erroed       - '||lpad(to_char(ln_error_hdr,'99,999,990'),12));
   rpt(' ');
   rpt(' ');
   rpt('No. Headers                        - '||lpad(to_char(t_hdrc(1).tcount,'99,999,990'),12));
   rpt('No. Headers Erroed                 - '||lpad(to_char(ln_error_hdrc,'99,999,990'),12));
   rpt('No. Headers Validated Only         - '||lpad(to_char(ln_valid_onc,'99,999,990'),12));
   rpt(' ');
   rpt(' ');
   rpt('No. Receipts Interface Erroed      - '||lpad(to_char(ln_error_int,'99,999,990'),12));
   rpt('No. Receipts Interface Processed   - '||lpad(to_char(ln_int_prc,'99,999,990'),12));
   rpt(' ');
   rpt(' ');
   rpt('No. Skipped Receipts (Line Num.= 0)- '||lpad(to_char(ln_skipped,'99,999,990'),12));
   rpt(' ');
   rpt(' ');



   fnd_file.put_line (fnd_file.LOG, 'Start Validation Report: '||to_char(sysdate,'hh24:mi:ss'));

   OPEN c_exc;

   rpt(lpad(' ',30)||'Receipts Conversion Exception Report Date: '||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));
   rpt(lpad(' ',30)||'___________________________________________'||lpad('_',17,'_'));
   rpt(' ');


   LOOP

     FETCH c_exc
      BULK COLLECT
      INTO t_exc LIMIT cn_commit;

     EXIT WHEN t_exc.COUNT = 0;

     FOR i IN t_exc.FIRST .. t_exc.LAST
     LOOP

       IF lc_prec <> t_exc(i).Error_Field THEN
          lc_prec := t_exc(i).Error_Field;
          rpt(' ');
          rpt('Error Field '||t_exc(i).Error_Field);
          rpt(' ');
          rpt(rpad('PO',19)||rpad('Error Value',34)||rpad('Error Message',64)||rpad('Oracle Error Message',60));
          rpt(lpad('_',15,'_')||lpad(' ',4)||lpad('_',30,'_')||lpad(' ',4)||lpad('_',60,'_')||lpad(' ',4)||lpad('_',60,'_'));
          rpt(' ');
       END IF;

       rpt(rpad(NVL(t_exc(i).po,'0'),15)||lpad(' ',4)||
           rpad(NVL(t_exc(i).Error_Value,' '),30)||lpad(' ',4)||
           rpad(NVL(t_exc(i).Error_Message,' '),60)||lpad(' ',4)||
           rpad(NVL(t_exc(i).Oracle_Error_Message,' '),60)
          );

       ln_flag := 1;

     END LOOP;

   END LOOP;

   CLOSE c_exc;

   IF ln_flag = 0 THEN
      rpt(' ');
      rpt('------------------------------------------------------- No validation errors found. -------------------------------------------------------');
      rpt(' ');
   END IF;

   IF t_exc.EXISTS(1) THEN
      t_exc.DELETE;
   END IF;

   fnd_file.put_line (fnd_file.LOG, 'End Validation Report: '||to_char(sysdate,'hh24:mi:ss'));

   fnd_file.put_line (fnd_file.LOG, 'Start Interface Error Report: '||to_char(sysdate,'hh24:mi:ss'));

   OPEN c_ie;

   ln_flag := 0;

   rpt(' ');
   rpt(' ');
   rpt(lpad(' ',30)||'Receipts Interface Error Report Date: '||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));
   rpt(lpad(' ',30)||'______________________________________'||lpad('_',17,'_'));
   rpt(' ');

   LOOP

     FETCH c_ie
      BULK COLLECT
      INTO t_ie LIMIT cn_commit;

     EXIT WHEN t_ie.COUNT = 0;

     FOR i IN t_ie.FIRST .. t_ie.LAST
     LOOP

       IF lc_prec <> t_ie(i).column_name THEN
          lc_prec := t_ie(i).column_name;
          rpt(' ');
          rpt('Error Field '||t_ie(i).column_name);
          rpt(' ');
          rpt(rpad('PO',17)||rpad('Error Message',62)||rpad('Table Name',42)||rpad('Interface Header Id',20));
          rpt(lpad('_',15,'_')||lpad(' ',2)||lpad('_',60,'_')||lpad(' ',2)||lpad('_',40,'_')||lpad(' ',2)||lpad('_',20,'_'));
          rpt(' ');
       END IF;

       rpt(rpad(NVL(t_ie(i).po,'0'),15)||lpad(' ',2)||
           rpad(NVL(t_ie(i).Error_Message,' '),60)||lpad(' ',2)||
           rpad(NVL(t_ie(i).table_name,' '),40)||lpad(' ',2)||
           rpad(NVL(t_ie(i).interface_header_id,0),20)
          );

       ln_flag := 1;

     END LOOP;

   END LOOP;

   CLOSE c_ie;

   IF ln_flag = 0 THEN
      rpt(' ');
      rpt('------------------------------------------------------- No interface errors found. --------------------------------------------------------');
      rpt(' ');
   END IF;

   fnd_file.put_line (fnd_file.LOG, 'End Interface Error Report: '||to_char(sysdate,'hh24:mi:ss'));


END create_exception_report;

END xx_po_rcv_interface_mcp_pkg;
/