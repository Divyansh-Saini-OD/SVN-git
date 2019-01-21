CREATE OR REPLACE PACKAGE Body XX_PO_POM_INTERFACE_MCP_PKG AS

-- +===========================================================================+
-- |    Office Depot - Project Simplify                                        |
-- |     Office Depot                                                          |
-- |                                                                           |
-- +===========================================================================+
-- | Name  : XX_PO_POM_INTERFACE_MCP_PKG
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
-- |1.1        02-AUG-2017   Vinay Singh     Added program to update PO lines data
-- |
-- |Objective: POM to PO Master Concurrent Program to submit PO conversion
-- |           based on parameters max batch size and threads
-- |
-- |Concurrent Program: OD: PO Purchase Order Conversion Master Program
-- |                    XXPOCNVMC
-- +===========================================================================+

    cn_commit       CONSTANT INTEGER := 70000;     --- Number of transactions per commit
	cc_module       CONSTANT VARCHAR2(100) := 'XX_PO_POM_INTERFACE_MCP_PKG';
    cc_procedure    CONSTANT VARCHAR2(100) := 'MASTER_MAIN';
    cn_max_loop     CONSTANT INTEGER := 999999999; --14400; --- Max. time in minutes to wait in a loop (4 hours)

    ln_batch_size           INTEGER := 0;
    ln_request_id           INTEGER := fnd_global.conc_request_id();
    ln_debug_level          INTEGER := oe_debug_pub.g_debug_level;
    ln_hdr_recs             INTEGER := 0;
    ln_batch_launched       INTEGER := 0;


PROCEDURE master_main( x_retcode            OUT NOCOPY NUMBER
                      ,x_errbuf             OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag  IN        VARCHAR2  DEFAULT 'N' -- Y/N
                      ,p_reset_status_flag   IN        VARCHAR2  DEFAULT 'N' -- Y/N
                      ,p_batch_size          IN        INTEGER   DEFAULT NULL
                      ,p_max_thread          IN        INTEGER   DEFAULT NULL
                      ,p_debug_flag          IN        VARCHAR2  DEFAULT 'N'
                      ,p_pdoi_batch_size     IN        INTEGER   DEFAULT 5000
                      ) IS

    ln_max_thread           INTEGER := p_max_thread;
    ld_end_dt               DATE := sysdate + cn_max_loop/(24*60*60);

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
  ln_pending     INTEGER := 0;

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

       EXIT WHEN ln_jobs_sub >= t_batch_job.COUNT OR ln_max_loop > cn_max_loop;

       FOR i IN t_batch_job.FIRST .. t_batch_job.LAST
       LOOP

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
                IF ln_jobs_sub >= t_batch_job.COUNT THEN
                   RETURN 0;
                END IF;
             END IF;
          ELSE
             IF sysdate > ld_end_dt THEN -- check if maxtime is exceeded THEN
                RETURN 1;
             END IF;

          END IF; 

       END LOOP;

       ln_jobs_sub := 0;
       
       FOR i IN t_batch_job.FIRST .. t_batch_job.LAST
       LOOP
          IF NVL(t_batch_job(i).job_status,'X') = 'COMPLETE' THEN
             ln_jobs_sub := ln_jobs_sub + 1;
          END IF;
       END LOOP;

       IF ln_jobs_sub >= t_batch_job.COUNT THEN
          ln_batch_launched := t_batch_job.COUNT;
          RETURN 0;
       END IF;

    END LOOP;

    RETURN 1;

END check_completed_jobs;

FUNCTION check_max_jobs RETURN INTEGER IS

BEGIN

     LOOP

       ln_pending := 0;

       FOR i IN t_batch_job.FIRST .. t_batch_job.LAST
       LOOP

          IF NVL(t_batch_job(i).job_no,0) <> 0 THEN
             IF NVL(t_batch_job(i).job_status,'X') <> 'COMPLETE' THEN
                lb_bool := fnd_concurrent.wait_for_request(request_id => t_batch_job(i).job_no 
                                                          ,interval   => 10
                                                          ,max_wait   => 1
                                                          ,phase      => lc_phase
                                                          ,status     => lc_status
                                                          ,dev_phase  => t_batch_job(i).job_status
                                                          ,dev_status => lc_dev_status
                                                          ,message    => lc_message
                                                          );
                IF t_batch_job(i).job_status <> 'COMPLETE' THEN
                   ln_pending := ln_pending + 1;
                END IF;
             END IF; 

          END IF;

       END LOOP;

       IF ln_pending < p_max_thread OR ln_pending = 0 THEN
          RETURN 0;
       END IF;

       IF sysdate > ld_end_dt THEN -- check if maxtime is exceeded
          RETURN 1;
       END IF;

     END LOOP;

END check_max_jobs;

---------- Main submit PO ---------------

BEGIN
       ---------------------------------------------------------
       -- Submit Concurrent Program for Conversion
       ---------------------------------------------------------
       -- THE XXPOCNVCH concurrent program for PO Conversion
       
       fnd_file.put_line(fnd_file.log,'Submitting : '|| 'XXPOCNVCH');

       IF t_batch_job.COUNT = 0 THEN
          fnd_file.put_line(fnd_file.log,'Job batch count is 0');
		  RETURN;
       ELSE
          fnd_file.put_line(fnd_file.log,'Job batch count is='||t_batch_job.COUNT);
       END IF;

       FOR bi IN t_batch_job.FIRST .. t_batch_job.LAST
	   LOOP

           -- check max threads
           IF ln_jobs_sub = p_max_thread THEN

              fnd_file.put_line(fnd_file.log,'Waiting for a batch to be completed');

              ln_max_loop := 0;

           -- Loop until a job is finished		      

              IF check_max_jobs = 1 THEN
                 fnd_file.put_line(fnd_file.log,'Loop exceeded '||cn_max_loop||' seconds');
				 RETURN;
	          END IF;

              ln_jobs_sub := ln_pending;

           END IF;

           t_batch_job(bi).job_no := fnd_request.submit_request(application => 'XXFIN'
                                                               ,program     => 'XXPOCNVCH'
	                                                           ,argument1   => p_validate_only_flag
			    								               ,argument2   => p_reset_status_flag
                                                               ,argument3   => t_batch_job(bi).batch_id
                                                               ,argument4   => p_debug_flag
                                                               ,argument5   => p_pdoi_batch_size
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
          fnd_file.put_line(fnd_file.log,'Loop exceeded '||cn_max_loop||' minutes');
       ELSE
          fnd_file.put_line(fnd_file.log,'All jobs completed');
       END IF;

END submit_po_cnv;

PROCEDURE reset_status_flag IS

    CURSOR c_hdrs IS
    SELECT rowid rid
      FROM xx_po_hdrs_conv_stg stg
     WHERE process_flag < 6;

    CURSOR c_lins IS
    SELECT rowid rid
      FROM xx_po_lines_conv_stg stg
     WHERE process_flag < 6;

    TYPE trid IS TABLE OF c_lins%ROWTYPE;

    t_rid trid := trid();


BEGIN

  fnd_file.put_line (fnd_file.LOG,'Reset flag status='||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));

  OPEN c_hdrs;

  LOOP
     FETCH c_hdrs
      BULK COLLECT
      INTO t_rid LIMIT cn_commit;
     
     EXIT WHEN t_rid.COUNT = 0;
 
        FORALL r_lins IN t_rid.FIRST .. t_rid.LAST
               UPDATE xx_po_hdrs_conv_stg
                  SET process_flag = 1
                WHERE rowid = t_rid(r_lins).rid;

     COMMIT;

  END LOOP;

  CLOSE c_hdrs;

  OPEN c_lins;

  LOOP
     FETCH c_lins
      BULK COLLECT
      INTO t_rid LIMIT cn_commit;
     
     EXIT WHEN t_rid.COUNT = 0;
 
        FORALL r_lins IN t_rid.FIRST .. t_rid.LAST
               UPDATE xx_po_lines_conv_stg
                  SET process_flag = 1
                WHERE rowid = t_rid(r_lins).rid;

     COMMIT;

  END LOOP;

  CLOSE c_lins;

  fnd_file.put_line (fnd_file.LOG,'Reset flag status='||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         ROLLBACK;
         IF c_lins%ISOPEN THEN
            CLOSE c_lins;
         END IF;
         RAISE;

END reset_status_flag;

PROCEDURE od_po_update_lines_prc IS
  
  CURSOR c_hdrseq IS
    SELECT /*+ parallel(6) */
           hr.rowid rid
          ,source_system_ref||'-'||lpad(substr(ship_to_location,length(ship_to_location)-3),4,'0') po_num
     FROM xx_po_hdrs_conv_stg hr
    WHERE interface_header_id IS NULL;

  TYPE thdrseq IS TABLE OF c_hdrseq%ROWTYPE;

  t_hdrseq thdrseq;

  CURSOR c_linseq IS
    SELECT /*+ parallel(6) */
           li.rowid rid
          ,hr.interface_header_id
          ,hr.document_num
      FROM xx_po_lines_conv_stg li
          ,xx_po_hdrs_conv_stg hr
     WHERE li.source_system_ref||'-'||lpad(substr(li.ship_to_location,length(li.ship_to_location)-3),4,'0') = hr.document_num
       AND li.interface_header_id IS NULL;

   TYPE tlinseq IS TABLE OF c_linseq%ROWTYPE;

   t_linseq tlinseq;

   ln_agent_id INTEGER;

BEGIN

     fnd_file.put_line(fnd_file.log,'Starting PO Update Lines '||to_char(sysdate,'hh24:mi:ss'));

     fnd_file.put_line(fnd_file.log,'Get Agent_Id '||to_char(sysdate,'hh24:mi:ss'));

     BEGIN
       SELECT agent_id
         INTO ln_agent_id
         FROM po_agents_v
        WHERE agent_name = 'SVC_ESP_FIN, SVC_ESP_FIN';

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
             fnd_file.put_line(fnd_file.log,'Agent_ID not found for Buyer=SVC_ESP_FIN, SVC_ESP_FIN');
             RAISE;
     END;

     OPEN c_hdrseq;

     LOOP
         FETCH c_hdrseq
          BULK COLLECT
          INTO t_hdrseq LIMIT cn_commit;

         EXIT WHEN t_hdrseq.COUNT = 0;

         FORALL i IN t_hdrseq.FIRST .. t_hdrseq.LAST

            UPDATE xx_po_hdrs_conv_stg
                SET interface_header_id = po_headers_interface_s.NEXTVAL
                   ,control_id = xx_po_poconv_stg_s.NEXTVAL
                   ,document_num = t_hdrseq(i).po_num
                   ,source_system_ref = t_hdrseq(i).po_num
                   ,agent_id = ln_agent_id
            WHERE rowid = t_hdrseq(i).rid;

     COMMIT;

     END LOOP;

     OPEN c_linseq;

     LOOP

        FETCH c_linseq
         BULK COLLECT
         INTO t_linseq LIMIT cn_commit;

        EXIT WHEN t_linseq.COUNT = 0;

        FORALL l IN t_linseq.FIRST .. t_linseq.LAST
               UPDATE xx_po_lines_conv_stg
                  SET interface_header_id = t_linseq(l).interface_header_id
                     ,interface_line_id = po_lines_interface_s.NEXTVAL
                     ,control_id = xx_po_poconv_stg_s.NEXTVAL
                     ,source_system_ref = t_linseq(l).document_num
                WHERE rowid = t_linseq(l).rid;

        COMMIT;

     END LOOP;
  
     COMMIT;

     CLOSE c_hdrseq;  

     CLOSE c_linseq;

     fnd_file.put_line (fnd_file.LOG, 'End PO Update Lines '||to_char(sysdate,'hh24:mi:ss'));

END od_po_update_lines_prc;

PROCEDURE update_batch_id IS


    CURSOR c_batch IS
    SELECT /*+ parallel(4) */
           DISTINCT poh.rowid rid
          ,poh.interface_header_id
          ,null batch_id
          ,(count(lin.interface_header_id) OVER(PARTITION BY lin.interface_header_id)+1) rcount
      FROM xx_po_hdrs_conv_stg poh
           LEFT JOIN xx_po_lines_conv_stg lin
                  ON poh.interface_header_id = lin.interface_header_id
     WHERE 1=1
       AND (poh.process_flag < 6 AND p_reset_status_flag = 'Y')
            OR (poh.process_flag = 1 AND p_reset_status_flag = 'N')
      ORDER BY poh.interface_header_id;


    TYPE tbatch IS TABLE OF c_batch%ROWTYPE;
    
    t_batch tbatch := tbatch();

    ln_batch_id INTEGER := 0;
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

    ln_hdr_recs := ln_hdr_recs + t_batch.COUNT;

    FOR r IN t_batch.FIRST .. t_batch.LAST
    LOOP

       IF ln_recs >= ln_batch_size OR ln_recs = 0 THEN
          SELECT xx_po_poconv_batchid_s.nextval
            INTO ln_batch_id
            FROM dual;
          ln_recs := 0;
          t_batch_job.EXTEND;
          t_batch_job(t_batch_job.LAST).batch_id := ln_batch_id;
       END IF;

       t_batch(r).batch_id := ln_batch_id;

       ln_recs := ln_recs + t_batch(r).rcount;

    END LOOP;

    FORALL r IN t_batch.FIRST .. t_batch.LAST
           UPDATE xx_po_hdrs_conv_stg
              SET batch_id = t_batch(r).batch_id
            WHERE rowid = t_batch(r).rid;

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

PROCEDURE update_sequences IS

    CURSOR c_upd IS
    SELECT /*+ parallel(4) */
           DISTINCT
           lin.rowid lrid
          ,hdr.batch_id
          ,hdr.record_id
      FROM xx_po_hdrs_conv_stg  hdr
          ,xx_po_lines_conv_stg lin
     WHERE hdr.interface_header_id = lin.interface_header_id
       AND hdr.process_flag < 6;


    TYPE tupd IS TABLE OF c_upd%ROWTYPE;

    t_upd tupd := tupd();

    ln_count INTEGER := 0;

BEGIN


  OPEN c_upd;

  LOOP
     FETCH c_upd
      BULK COLLECT
      INTO t_upd LIMIT cn_commit;

     EXIT WHEN t_upd.COUNT = 0;
  
     FORALL r_upd IN t_upd.FIRST .. t_upd.LAST
            UPDATE xx_po_lines_conv_stg
               SET batch_id = t_upd(r_upd).batch_id
                  ,record_id = t_upd(r_upd).record_id
                  ,parent_record_id = t_upd(r_upd).record_id
             WHERE rowid = t_upd(r_upd).lrid;

     ln_count := ln_count + t_upd.COUNT;

     COMMIT;

  END LOOP;

  CLOSE c_upd;

  fnd_file.put_line (fnd_file.LOG,'Sequences updated='||ln_count);

  EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.LOG,DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
         IF c_upd%ISOPEN THEN
            CLOSE c_upd;
         END IF;
         RAISE;

END update_sequences;

---------------------------------------------------
-------------- MAIN --------------

BEGIN

   x_retcode := 0;
   ln_batch_size := p_batch_size;

   IF p_batch_size IS NULL OR p_max_thread IS NULL THEN
      BEGIN

       SELECT NVL(p_max_thread,max_threads)
	         ,NVL(p_batch_size,batch_size)
	     INTO ln_max_thread
		     ,ln_batch_size
         FROM xx_com_conversions_conv
        WHERE conversion_code = 'CXXXX_PurchaseOrders';
        
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           fnd_file.put_line (fnd_file.LOG, 'No data found for CXXXX_PurchaseOrders');
           RAISE;
      WHEN OTHERS THEN
           fnd_file.put_line (fnd_file.LOG, 'Error reading xx_com_conversions_conv, '||sqlerrm);
           RAISE;
      END;
   END IF;

   fnd_file.put_line (fnd_file.LOG, 'Parameters ');
   fnd_file.put_line (fnd_file.LOG, ' p_validate_only_flag: ' || p_validate_only_flag);
   fnd_file.put_line (fnd_file.LOG, ' p_batch_size        : ' || ln_batch_size);
   fnd_file.put_line (fnd_file.LOG, ' p_max_thread        : ' || ln_max_thread);
   fnd_file.put_line (fnd_file.LOG, ' p_reset_status_flag : ' || p_reset_status_flag);
   fnd_file.put_line (fnd_file.LOG, ' p_debug_flag        : ' || p_debug_flag);
   fnd_file.put_line (fnd_file.LOG, ' Max. End time       : ' || to_char(ld_end_dt,'mm/dd/yy hh24:mi:ss'));

   IF t_batch_job.EXISTS(1) THEN
      t_batch_job.DELETE;
   END IF;

   od_po_update_lines_prc;  

   update_batch_id;

   update_sequences;

   IF p_reset_status_flag = 'Y' THEN
      reset_status_flag;
   END IF;

   submit_po_cnv;

   -------------- Exception Report ------------
   
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
 WITH stg AS
 (
  SELECT /*+ materialize */
        DISTINCT request_id
   FROM xx_po_hdrs_conv_stg stg
  WHERE stg.process_flag = 3
 )
 SELECT *
  FROM (SELECT /*+ full(stg) full(exe) full(hdr) parallel(stg,8) parallel(hdr,8) parallel(exe,8) */
               exe.source_system_ref PO
              ,exe.staging_column_name Error_Field
              ,exe.staging_column_value Error_Value
              ,exe.exception_log Error_Message
              ,DECODE(NVL(oracle_error_code,0),0,NULL,exe.oracle_error_msg) Oracle_Error_Message
          FROM stg
               JOIN xx_po_hdrs_conv_stg hdr
                 ON hdr.request_id = stg.request_id
               JOIN xx_com_exceptions_log_conv exe
                 ON stg.request_id = exe.request_id
                AND exe.staging_table_name = 'XX_PO_HDRS_CONV_STG'
                AND exe.source_system_ref = hdr.source_system_ref
        UNION ALL
        SELECT /*+ full(stg) full(exe) full(hdr) parallel(stg,8) parallel(hdr,8) parallel(exe,8) */
               DISTINCT
               exe.source_system_ref po
              ,exe.staging_column_name Error_Field
              ,exe.staging_column_value Error_Value
              ,exe.exception_log Error_Message
              ,DECODE(NVL(oracle_error_code,0),0,NULL,exe.oracle_error_msg) Oracle_Error_Message
          FROM stg
               JOIN xx_po_lines_conv_stg hdr
                 ON hdr.request_id = stg.request_id
               JOIN xx_com_exceptions_log_conv exe
                 ON stg.request_id = exe.request_id
                AND exe.staging_table_name = 'XX_PO_LINES_CONV_STG'
                AND exe.source_system_ref = hdr.source_system_ref
        )
 ORDER BY 2,1;

 TYPE texc IS TABLE OF c_exc%ROWTYPE;

 t_exc texc;

 CURSOR c_ie IS
 WITH stg AS
 (
  SELECT /*+ materialize */
        DISTINCT interface_header_id
   FROM xx_po_hdrs_conv_stg stg
  WHERE stg.process_flag = 6
 )
 SELECT /*+ parallel(ie,4) */
       ie.column_name
      ,ie.error_message
      ,ie.error_message_name
      ,ie.table_name
      ,ie.interface_header_id
      ,ie.column_value
      ,ph.document_num po
  FROM po_interface_errors ie
      ,stg
      ,po_headers_interface ph
 WHERE 1=1
   AND stg.interface_header_id = ie.interface_header_id
   AND ph.interface_header_id = ie.interface_header_id;


 TYPE tie IS TABLE OF c_ie%ROWTYPE;

 t_ie tie;

 CURSOR c_shdr IS
 SELECT (SELECT count(*) FROM xx_po_hdrs_conv_stg) tcount
       ,count(*) pcount
       ,process_flag
       ,CASE process_flag
             WHEN 3 THEN 'Validation Error'
             WHEN 6 THEN 'Interface Error'
             WHEN 7 THEN 'Successfully Processed'
          ELSE 'Unknown'
        END status
   FROM xx_po_hdrs_conv_stg a
  WHERE 1=1
  GROUP BY process_flag
  ORDER BY process_flag;

 TYPE tshdr IS TABLE OF c_shdr%ROWTYPE;

 t_shdr tshdr;

 CURSOR c_slin IS
 SELECT (SELECT count(*) FROM xx_po_lines_conv_stg) tcount
       ,count(*) pcount
       ,process_flag
       ,CASE process_flag
             WHEN 3 THEN 'Validation Error'
             WHEN 6 THEN 'Interface Error'
             WHEN 7 THEN 'Successfully Processed'
          ELSE 'Unknown'
        END status
   FROM xx_po_lines_conv_stg a
  WHERE 1=1
  GROUP BY process_flag
  ORDER BY process_flag;

 TYPE tslin IS TABLE OF c_slin%ROWTYPE;

 t_slin tslin;

 lc_prec         VARCHAR2(200) := 'XYZ';
 ln_flag         INTEGER := 0;
 ln_error_hdr    INTEGER := 0;
 ln_error_int    INTEGER := 0;
 ln_int_prc      INTEGER := 0;
 ln_error_lin    INTEGER := 0;

 ln_errors       INTEGER := 0;


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

   OPEN c_slin;

   FETCH c_slin
   BULK COLLECT
   INTO t_slin;

   CLOSE c_slin;

   FOR i IN t_shdr.FIRST .. t_shdr.LAST
   LOOP

     IF t_shdr(i).process_flag = 3 THEN
        ln_error_hdr := t_shdr(i).pcount;
     ELSIF t_shdr(i).process_flag = 6 THEN
           ln_error_int := t_shdr(i).pcount;
     ELSIF t_shdr(i).process_flag = 7 THEN
           ln_int_prc := t_shdr(i).pcount;
     END IF;

   END LOOP;

   FOR i IN t_slin.FIRST .. t_slin.LAST
   LOOP

     IF t_slin(i).process_flag = 3 THEN
        ln_error_lin := t_slin(i).pcount;
     END IF;

   END LOOP;

   rpt(' ');
   rpt(' ');
   rpt(lpad(' ',30)||'OD: PO Purchase Order Conversion Master Program Summary: '||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));
   rpt(lpad(' ',30)||'___________________________________________________________________________');
   rpt(' ');
   rpt(' ');
   rpt('Batch Size                         - '||lpad(to_char(ln_batch_size,'99,999,990'),12));
   rpt('No. of Batches Launched            - '||lpad(to_char(ln_batch_launched,'99,999,990'),12));

   rpt(' ');
   rpt('Total no. of PO Header Records     - '||lpad(to_char(ln_hdr_recs,'99,999,990'),12));
   rpt('No. of PO Header Records Erroed    - '||lpad(to_char(ln_error_hdr,'99,999,990'),12));
   rpt(' ');
   rpt(' ');
   rpt('Total no. of PO Line Records       - '||lpad(to_char(t_slin(1).tcount,'99,999,990'),12));
   rpt('No. of PO Line Records Erroed      - '||lpad(to_char(ln_error_lin,'99,999,990'),12));
   rpt(' ');
   rpt(' ');
   rpt('No. of PO Interface Processed      - '||lpad(to_char(ln_int_prc,'99,999,990'),12));
   rpt('No. of PO Interface Erroed         - '||lpad(to_char(ln_error_int,'99,999,990'),12));
   rpt(' ');
   rpt(' ');


   fnd_file.put_line (fnd_file.LOG, 'Start Validation Report: '||to_char(sysdate,'hh24:mi:ss'));

   OPEN c_exc;

   rpt(lpad(' ',30)||'POM to PO Conversion Exception Report Date: '||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));
   rpt(lpad(' ',30)||'_____________________________________________________________');
   rpt(' ');


   LOOP

     FETCH c_exc
      BULK COLLECT
      INTO t_exc LIMIT cn_commit;

     EXIT WHEN t_exc.COUNT = 0;

     FOR i IN t_exc.FIRST .. t_exc.LAST
     LOOP

       IF lc_prec <> t_exc(i).Error_Field THEN
          IF i > 1 THEN
             rpt(' ');
             rpt(' ');
             rpt('Number of Errors for '||lc_prec||lpad(to_char(ln_errors,'99,999,990'),12));
             rpt(' ');
             ln_errors := 0;
          END IF;
          lc_prec := t_exc(i).Error_Field;
          rpt(' ');
          rpt('Error Field: '||t_exc(i).Error_Field);
          rpt(' ');
          rpt(rpad('PO Number',19)||rpad('Error Value',84)||rpad('Error Message',64)||rpad('Oracle Error Message',60));
          rpt(lpad('_',15,'_')||lpad(' ',4)||lpad('_',80,'_')||lpad(' ',4)||lpad('_',60,'_')||lpad(' ',4)||lpad('_',60,'_'));
          rpt(' ');
       END IF;

       rpt(rpad(NVL(t_exc(i).po,'0'),15)||lpad(' ',4)||
           rpad(NVL(t_exc(i).Error_Value,' '),80)||lpad(' ',4)||
           rpad(NVL(t_exc(i).Error_Message,' '),60)||lpad(' ',4)||
           rpad(NVL(t_exc(i).Oracle_Error_Message,' '),60)
          );

       ln_flag := 1;
       ln_errors := ln_errors + 1;

     END LOOP;

   END LOOP;

   CLOSE c_exc;

   IF ln_flag = 0 THEN
      rpt(' ');
      rpt('------------------------------------------------------- No validation errors found. -------------------------------------------------------');
      rpt(' ');
   ELSE
      rpt(' ');
      rpt(' ');
      rpt('Number of Errors for '||lc_prec||lpad(to_char(ln_errors,'99,999,990'),12));
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
   rpt(lpad(' ',30)||'POM to PO Interface Error Report Date: '||to_char(sysdate,'mm/dd/yy hh24:mi:ss'));
   rpt(lpad(' ',30)||'________________________________________________________');
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


END xx_po_pom_interface_mcp_pkg;
/