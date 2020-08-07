CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_ZERO_TAX_ROWS_DELETE_PKG IS
---+============================================================================================+        
---|                              Office Depot - Project Simplify                               |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : XX_AR_ZERO_TAX_ROWS_DELETE_PKG.pkb                                    |
---|                                                                                            |
---|    Description     : Delete 0 tax rows from RA_CUSTOMER_TRX_LINES_ALL and                  |
---|                      RA_CUST_TRX_LINE_GL_DIST_ALL                                          |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             29-SEP-2009       Prakash Sankaran   Initial Version                    |
---+============================================================================================+

    gs_module_name              VARCHAR2(50) := 'XX_AR_ZERO_TAX_ROWS_DELETE_PKG.MAIN()';

    PROCEDURE log_message (ps_message VARCHAR2) IS
    BEGIN

        fnd_file.put_line (fnd_file.log, substr(gs_module_name || ':' || ps_message, 1, 255) );
    END log_message;
    
    PROCEDURE main (ps_errbuf    OUT NOCOPY     VARCHAR2
                   ,pn_retcode   OUT NOCOPY     NUMBER
                   ,pn_request_id IN            NUMBER DEFAULT NULL
                   ) IS

        ln_curr_request_id          fnd_concurrent_requests.request_id%TYPE;
        lc_AI_master_phase          fnd_concurrent_requests.phase_code%TYPE;
        lc_AI_master_status         fnd_concurrent_requests.status_code%TYPE;
        AI_master_incomplete			  exception;
        delete_count_mismatch			  exception;
        ln_rows_trx_lines						number(15);
        ln_rows_dist_lines					number(15);

    BEGIN

        log_message ( 'Start of module');
        
        ARP_GLOBAL.G_ALLOW_DATAFIX:=TRUE; 

        ln_curr_request_id := fnd_global.conc_request_id;
        log_message ( 'Request ID = ' || ln_curr_request_id );
        log_message ( 'Auto Invoice Master Program Request ID = ' || pn_request_id );        
        
        SELECT   req.phase_code,
                 req.status_code
        INTO     lc_AI_master_phase,
                 lc_AI_master_status
        FROM     fnd_concurrent_requests req,
                 fnd_concurrent_programs conc
        WHERE    req.request_id = pn_request_id
        AND      conc.concurrent_program_id = req.concurrent_program_id
        AND      req.program_application_id = conc.application_id
        AND      conc.concurrent_program_name = 'RAXMTR';
        
        IF lc_AI_master_phase <> 'C' THEN
           RAISE AI_master_incomplete;
        END IF;

				DELETE FROM ra_customer_trx_lines_all lines
				WHERE EXISTS
				     (SELECT ai.request_id
				      FROM   fnd_concurrent_requests aim,
				             fnd_concurrent_requests ai
				      WHERE  aim.request_id = pn_request_id
				      AND    ai.parent_request_id = aim.request_id
				      AND    lines.request_id = ai.request_id)
        AND lines.line_type = 'TAX'
        AND lines.extended_amount = 0
        AND EXISTS
              (SELECT 'x'
               FROM  ra_cust_trx_line_gl_dist_all dist
               WHERE dist.customer_trx_line_id = lines.customer_trx_line_id
               AND   dist.account_class = 'TAX'
               AND   dist.posting_control_id = -3
               AND   (dist.acctd_amount = 0 and dist.amount = 0));
         				    
        log_message ('Total 0 TAX Rows Deleted from RA_CUSTOMER_TRX_LINES_ALL: ' || SQL%ROWCOUNT);
        ln_rows_trx_lines := SQL%ROWCOUNT;

				DELETE FROM ra_cust_trx_line_gl_dist_all  dist
				WHERE EXISTS
				     (SELECT ai.request_id
				      FROM   fnd_concurrent_requests aim,
				             fnd_concurrent_requests ai
				      WHERE  aim.request_id = pn_request_id
				      AND    ai.parent_request_id = aim.request_id
				      AND    dist.request_id = ai.request_id)
        AND dist.account_class = 'TAX'
        AND dist.posting_control_id = -3
        AND (dist.acctd_amount = 0 OR dist.amount = 0);

        log_message ('Total 0 TAX Rows Deleted from RA_CUST_TRX_LINE_GL_DIST_ALL: ' || SQL%ROWCOUNT);
        ln_rows_dist_lines := SQL%ROWCOUNT;      
        
        IF ln_rows_trx_lines != ln_rows_dist_lines THEN
           ROLLBACK;
           log_message ('ERROR:  Deletes Rolled back due to count mismatch between TRX and DIST');
           RAISE delete_count_mismatch;
        END IF;
        
        log_message ( 'End of module');
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ps_errbuf  := 'ERROR: Auto Invoice Master did not run for this request ID';
            pn_retcode := 0;
        WHEN AI_master_incomplete THEN
            ps_errbuf  := 'ERROR: Auto Invoice Master did not complete for this request ID';
            pn_retcode := 0;
        WHEN delete_count_mismatch THEN
            ps_errbuf  := 'ERROR:  Deletes Rolled back due to count mismatch between TRX and DIST';
            pn_retcode := 0;
    END main;
        
END XX_AR_ZERO_TAX_ROWS_DELETE_PKG;
/