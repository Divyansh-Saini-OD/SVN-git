CREATE OR REPLACE PACKAGE BODY APPS.xx_ar_excl_hed_invoices_pkg IS
---+============================================================================================+        
---|                              Office Depot - Project Simplify                               |
---|                                   Providge Consulting                                      |
---+============================================================================================+
---|    Application     : AR                                                                    |
---|                                                                                            |
---|    Name            : xx_ar_excl_hed_invoices_pks.pks                                       |
---|                                                                                            |
---|    Description     : Exclude hedberg invoices from standard consolidated billing process.  |
---|                                                                                            |
---|                                                                                            |
---|                                                                                            |
---|    Change Record                                                                           |
---|    ---------------------------------                                                       |
---|    Version         DATE              AUTHOR             DESCRIPTION                        |
---|    ------------    ----------------- ---------------    ---------------------              |
---|    1.0             11-MAR-2008       Sairam Bala        Initial Version                    |
---|    1.1             09-JUL-2008       Sambasiva Reddy D  Defect # 8855                      |
---|                                                         To exclude NON SPC POS invoices    |
---|                                                         and paid transactions              |
---|    1.2             09-AUG-2008       Sambasiva Reddy D  Defect # 9451                      |
---|                                                         Removed logic to exclude NON SPC   |
---|                                                         POS invoices for thr defect #8855  |
---|    1.3             03-MAR-2008       Gokila Tamilselvam Defect # 13485 to exclude PRO card |
---|                                                         invoices.                          |
-- |    1.4             17-JUL-2009       Samabsiva Reddy D  Defect# 631 (CR# 662)              |
-- |                                                         -- Applied Credit Memos            |
-- |    1.5             18-APR-2018       Punit Gupta CG     Retrofit OD AR Reprint Summary/    |
-- |                                                         Consolidated Bills-                |
-- |                                                         Defect NAIT-31695                  |
---+============================================================================================+

    gs_module_name              VARCHAR2(50) := 'xx_ar_flag_hed_invoices_pkg.main()';

    PROCEDURE log_message (ps_message VARCHAR2) IS
    BEGIN

        fnd_file.put_line (fnd_file.log, substr(gs_module_name || ':' || ps_message, 1, 255) );
    END log_message;
    
    PROCEDURE main (ps_errbuf    OUT NOCOPY     VARCHAR2
                   ,pn_retcode   OUT NOCOPY     NUMBER
                   ,pn_request_id IN            NUMBER DEFAULT NULL
                   ) IS

        ln_curr_request_id          fnd_concurrent_requests.request_id%TYPE;
        ln_request_id               fnd_concurrent_requests.request_id%TYPE;
        ls_concurrent_program_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
        ld_actual_start_date        fnd_concurrent_requests.actual_start_date%TYPE;


    BEGIN

        log_message ( 'Start of module');

        ln_curr_request_id := fnd_global.conc_request_id;
--        ln_curr_request_id := fnd_profile.value (fnd_global.conc_request_id);
        log_message ( 'Request ID = ' || ln_curr_request_id );
        
        IF pn_request_id IS NULL THEN -- Calling from within Request Set 

            SELECT  
                     fndcr_aim.request_id
                    ,fndcp_aim.concurrent_program_name 
                    ,fndcr_aim.actual_start_date 
--                     fndcr_aii.request_id
--                    ,fndcp_aii.concurrent_program_name 
--                    ,fndcr_aii.actual_start_date 
            INTO    ln_request_id
                   ,ls_concurrent_program_name
                   ,ld_actual_start_date
            FROM    fnd_concurrent_requests fndcr_rs
                   ,fnd_concurrent_requests fndcr_rss
                   ,fnd_concurrent_requests fndcr_aim
                   ,fnd_concurrent_programs fndcp_aim
--                   ,fnd_concurrent_requests fndcr_aii
--                   ,fnd_concurrent_programs fndcp_aii
            WHERE  1 = 1
                    AND fndcr_rss.parent_request_id = fndcr_rs.request_id
                    AND fndcr_aim.parent_request_id = fndcr_rss.request_id
                    AND fndcr_aim.concurrent_program_id = fndcp_aim.concurrent_program_id
                    AND fndcp_aim.concurrent_program_name = 'RAXMTR'
--                    AND fndcr_aim.request_id = fndcr_aii.parent_request_id
--                    AND fndcr_aii.concurrent_program_id = fndcp_aii.concurrent_program_id
--                    AND fndcp_aii.concurrent_program_name = 'RAXTRX'
                    AND fndcr_rs.request_id = (
                        SELECT  fndcr_rss.parent_request_id rs_request_id
                        FROM    fnd_concurrent_requests fndcr_cur
                               ,fnd_concurrent_requests fndcr_rss
                        WHERE   1 = 1
                                AND fndcr_cur.parent_request_id = fndcr_rss.request_id
                                AND fndcr_cur.request_id = ln_curr_request_id --4481298
                    );                


            log_message ( 'Auto Invoice Master Import Request ID = ' || ln_request_id );
        
--            UPDATE  ar_payment_schedules_all arps
--            SET     arps.exclude_from_cons_bill_flag = 'Y'
--            WHERE   1 = 1
--                    AND NVL(arps.exclude_from_cons_bill_flag, 'N') = 'N'
--                    AND arps.customer_trx_id in (
--                    SELECT  ract.customer_trx_id
--                    --ract.request_id, ract.interface_header_attribute1, oeoh.order_source_id, oeos.NAME
--                    FROM    ra_customer_trx_all ract
--                           ,oe_order_headers_all oeoh
--                           ,oe_order_sources oeos
--                    WHERE  1 = 1
--                            AND ract.interface_header_context = 'ORDER ENTRY'
--                            AND ract.interface_header_attribute1 = oeoh.order_number
--                            AND oeoh.order_source_id = oeos.order_source_id
--                            AND oeos.name = 'HED'
--                            AND ract.request_id = ln_request_id
--                    );
        
        ELSE
            ln_request_id := pn_request_id;
        END IF;
        
        UPDATE  ar_payment_schedules_all arps
        SET     arps.exclude_from_cons_bill_flag = 'Y'
        WHERE   1 = 1
                AND NVL(arps.exclude_from_cons_bill_flag, 'N') = 'N'
                AND arps.customer_trx_id in (
                SELECT  ract.customer_trx_id
                FROM    ra_customer_trx_all ract
                       --,oe_order_headers_all oeoh
					    ,xx_oe_order_headers_v oeoh -- Commented and Changed by Punit CG on 18-APR-2018 for Defect NAIT-31695
                       ,oe_order_sources oeos
                WHERE  1 = 1
                        AND ract.interface_header_context = 'ORDER ENTRY'
--                        AND ract.interface_header_attribute1 = oeoh.order_number    --Commented for performance
                        AND oeoh.header_id = ract.attribute14                         --Added for performance
                        AND oeos.order_source_id = oeoh.order_source_id
                        AND oeos.enabled_flag    = 'Y'
                        AND OEOS.name IN ('HED','PRO')     --Added PRO for Defect# 13485
                        --AND oeos.name = 'HED'                -- Commented for Defect # 8855 and again added for Defect # 9451
                                                               -- Commented for Defect# 13485
--                      AND oeos.name IN ('HED','POE')       -- Added for Defect # 8855 and again commented for Defect # 9451
                        AND ract.request_id IN (
                            SELECT  fndcr.request_id
                            FROM    fnd_concurrent_requests fndcr
                            WHERE   1 = 1
                                    AND fndcr.parent_request_id = ln_request_id
                            UNION
                            SELECT  ln_request_id
                            FROM    dual
                        )
         /* The following code has been added for the Defect # 8855 */
         -- Start for Defect # 631 (CR 662)
            /*    UNION
                SELECT  rct.customer_trx_id
                FROM    ra_customer_trx_all rct
                       ,ra_customer_trx_lines_all rctl
                WHERE   rct.customer_trx_id= rctl.customer_trx_id
                AND     rctl.payment_set_id > 0
                AND     rct.request_id IN (
                            SELECT  fndcr.request_id
                            FROM    fnd_concurrent_requests fndcr
                            WHERE   fndcr.parent_request_id = ln_request_id
                            UNION
                            SELECT  ln_request_id
                            FROM    dual
                        )*/
            -- End for Defect # 631 (CR 662) 
         /* The above code has been added for the Defect # 8855 */
                );
        log_message ( 'Updated ' || SQL%ROWCOUNT || ' lines in AR_PAYMENT_SCHEDULES_ALL');

        
        log_message ( 'End of module');
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ps_errbuf  := 'Auto Invoice Import did not run for this request set';
            pn_retcode := 0;
    END main;
        
END xx_ar_excl_hed_invoices_pkg;
/