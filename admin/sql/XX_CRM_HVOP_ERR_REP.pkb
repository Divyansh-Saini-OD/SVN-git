SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON

PROMPT Creating PACKAGE XX_CRM_HVOP_ERR_REP

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE
 PACKAGE BODY apps.XX_CRM_HVOP_ERR_REP
 AS
    gc_error_location       VARCHAR2(2000);
    gc_debug                VARCHAR2(1000);
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_CRM_HVOP_ERR_REP                                                 |
-- | Description : This Package is used to check the status of the Customer information|
-- |               of the Errored HVOP data.                                           |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MASTER                                                              |
-- | Description : This procedure is used to trigger the output pgm and the mailer pgm.|
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE MASTER ( x_error_buff                 OUT VARCHAR2
                      ,x_ret_code                   OUT NUMBER
                      ,p_start_date                 IN  VARCHAR2
                      ,p_end_date                   IN  VARCHAR2
                      )
    IS

       lc_request_data          VARCHAR2(25);
       ln_ofile_size            FND_CONCURRENT_REQUESTS.ofile_size%type;
       ln_error                 NUMBER;
       ln_pgm_req_id            NUMBER;
       ln_mail_req_id           NUMBER;

    BEGIN

       lc_request_data        := FND_CONC_GLOBAL.REQUEST_DATA;

       IF lc_request_data IS NULL THEN

          gc_error_location := 'Submitting the HVOP Error Information Program to get the Details of the Record Errors.';

          ln_pgm_req_id := FND_REQUEST.SUBMIT_REQUEST ( application         => 'xxcrm'
                                                       ,program             => 'XX_CRM_HVOP_ERR_CUST_INFO'
                                                       ,description         => NULL
                                                       ,start_time          => NULL
                                                       ,sub_request         => TRUE
                                                       ,argument1           => p_start_date
                                                       ,argument2           => p_end_date
                                                       );

          FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => TO_CHAR(ln_pgm_req_id)||'-MASTER');

       ELSIF (SUBSTR(lc_request_data,INSTR(lc_request_data,'-')+1) = 'MASTER') THEN

          gc_error_location := 'Getting the size of the output program - '||lc_request_data;

          ln_pgm_req_id := SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1);

          SELECT ofile_size
          INTO   ln_ofile_size
          FROM   fnd_concurrent_requests
          WHERE  request_id = ln_pgm_req_id;

          IF NVL(ln_ofile_size,0) <> 0 THEN

             gc_error_location := 'Submit the Mailer Program.';

             ln_mail_req_id := FND_REQUEST.SUBMIT_REQUEST ( application         => 'xxfin'
                                                           ,program             => 'XXODROEMAILER'
                                                           ,description         => NULL
                                                           ,start_time          => NULL
                                                           ,sub_request         => TRUE
                                                           ,argument1           => NULL
                                                           ,argument2           => 'gokila.tamilselvam@officedepot.com'
                                                           ,argument3           => 'HVOP Error Report'
                                                           ,argument4           => NULL
                                                           ,argument5           => 'N'
                                                           ,argument6           => ln_pgm_req_id
                                                           ,argument7           => 'noreply@officedepot.com'
                                                           );

             FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => ln_mail_req_id);

          END IF;

       END IF;

       gc_error_location := 'Get the count of the error records for the parent request ID - ' || fnd_global.conc_request_id;

       SELECT COUNT(1)
       INTO   ln_error
       FROM   fnd_concurrent_requests
       WHERE  parent_request_id   = fnd_global.conc_request_id
       AND    phase_code          = 'C'
       AND    status_code         = 'E';

       IF ln_error > 0 THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Child Program Completes in Error. Check Child program Log for error.');
          x_ret_code := 2;
        END IF;

    EXCEPTION
    WHEN OTHERS THEN

       FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_location || CHR(13) || 'SQLERRM : ' || SQLERRM);

    END MASTER;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : CUST_INFO_STATUS                                                    |
-- | Description : This procedure is used to check the status of the customer info.    |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE CUST_INFO_STATUS ( x_error_buff                 OUT VARCHAR2
                                ,x_ret_code                   OUT NUMBER
                                ,p_start_date                 IN  VARCHAR2
                                ,p_end_date                   IN  VARCHAR2
                                )
    IS

       -- Cursor to fetch all the Errored records
       CURSOR ERROR_REC ( p_start_date      DATE
                         ,p_end_date        DATE
                         )
       IS
       SELECT DISTINCT  OHIA.request_id
                       ,OPMV.original_sys_document_ref             original_sys_document_ref
                       ,OPMV.header_id
                       ,'HVOP Order'                               import_Type
                       ,SUBSTR(OPMV.message_text,   1,  8)         message_code
                       ,OPMV.message_text
                       ,NVL(OHIA.sold_to_org, (SELECT orig_system_reference FROM hz_cust_accounts WHERE cust_account_id = OHIA.sold_to_org_id))  sold_to_org
                       ,NVL(OHIA.ship_to_org, (SELECT orig_system_reference FROM hz_cust_site_uses_all WHERE site_use_id = OHIA.ship_to_org_id)) ship_to_org
                       ,NVL(DECODE(SUBSTR(SUBSTR(OPMV.message_text,(INSTR(OPMV.message_text,':',1,2)+1)),1,INSTR(SUBSTR(OPMV.message_text ,(INSTR(OPMV.message_text,':',1,2)+1) ),'-A0',1)+2)
                                   ,'Va',''
                                   ,' C',''
                                   ,SUBSTR(SUBSTR(OPMV.message_text,(INSTR(OPMV.message_text,':',1,2)+1)),1,INSTR(SUBSTR(OPMV.message_text ,(INSTR(OPMV.message_text,':',1,2)+1) ),'-A0',1)+2)
                                   )
                             ,(SELECT orig_system_reference FROM hz_cust_site_uses_all WHERE site_use_id = OHIA.invoice_to_org_id)
                            )                                      bill_to
                       ,OHIA.sold_to_contact_id
                       ,XOHAIA.order_start_time
                       ,XOHAIA.creation_date
       FROM xx_om_sacct_file_history      XOSFH
           ,xx_om_headers_attr_iface_all  XOHAIA
           ,oe_processing_msgs_vl         OPMV
           ,oe_headers_iface_all          OHIA
       WHERE XOSFH.process_date             BETWEEN NVL(p_start_date,XOSFH.process_date) AND NVL(p_end_date,XOSFH.process_date)
       AND   XOHAIA.imp_file_name           = XOSFH.file_name
       AND   XOHAIA.orig_sys_document_ref   = OHIA.orig_sys_document_ref
       AND   XOHAIA.order_source_id         = OHIA.order_source_id
       AND   NVL(OHIA.error_flag,'N')       = 'Y'
       AND   OHIA.orig_sys_document_ref     = OPMV.original_sys_document_ref
       AND   OHIA.order_source_id           = OPMV.order_source_id
       AND   SUBSTR(OPMV.message_text,1,8)  NOT IN ('This Cus')
       AND   XOSFH.org_id                   = fnd_profile.value('ORG_ID')
       AND   XOSFH.file_type               != 'DEPOSIT'
       AND    (CASE WHEN SUBSTR(message_text,   1,  8) = 'Validati'
                       AND message_text = 'Validation failed for the field -Customer' THEN '10000010'
                    WHEN SUBSTR(message_text,   1,  8) = 'Validati'
                       AND message_text = 'Validation failed for the field - Ship To' THEN '10000016'
                    WHEN SUBSTR(message_text,   1,  8) = 'Validati'
                       AND message_text = 'Validation failed for the field - Bill To' THEN '10000021'
                    WHEN SUBSTR(message_text,   1,  8) = 'Validati'
                       AND message_text = 'Validation failed for the field - Contact' THEN '10000010'
                    ELSE SUBSTR(message_text,   1,  8)
                    END) IN                (SELECT FFVNH.child_flex_value_low
                                            FROM   fnd_flex_value_norm_hierarchy FFVNH
                                                  ,fnd_flex_value_sets           FFVS
                                            WHERE  FFVNH.flex_value_set_id = FFVS.flex_value_set_id
                                            AND    UPPER(FFVNH.parent_flex_value) = 'CUSTOMER'
                                            )
       UNION ALL
       SELECT DISTINCT XOLD.request_id
                       ,XOLD.orig_sys_document_ref                                   original_sys_document_ref
                       ,OPMV.header_id
                       ,'HVOP Deposit'                                               import_type
                       ,SUBSTR(OPMV.message_text,   1,  8)                           message_code
                       ,OPMV.message_text
                       ,SUBSTR(OPMV.message_text,(INSTR(OPMV.message_text,'-',1)+1)) sold_to_org
                       ,NULL                                                         ship_to_org
                       ,NULL                                                         bill_to
                       ,NULL                                                         sold_to_contact_id
                       ,NULL                                                         order_start_time
                       ,XOSFH.creation_date
       FROM xx_om_legacy_deposits    XOLD
           ,oe_processing_msgs_vl    OPMV
           ,xx_om_sacct_file_history XOSFH
       WHERE XOSFH.process_date      BETWEEN NVL(p_start_date,XOSFH.process_date) AND NVL(p_end_date,XOSFH.process_date)
       AND   XOSFH.file_type         = 'DEPOSIT'
       AND   XOSFH.org_id            = fnd_profile.value('ORG_ID')
       AND   XOSFH.file_name         = XOLD.imp_file_name
       AND   XOLD.transaction_number = OPMV.original_sys_document_ref
       AND   XOLD.order_source_id    = OPMV.order_source_id
       AND   XOLD.error_flag         = 'Y'
       AND   XOLD.sold_to_org_id     IS NULL
       AND   SUBSTR(OPMV.message_text,1, 8)
                                     IN (SELECT FFVNH.child_flex_value_low
                                          FROM fnd_flex_value_norm_hierarchy FFVNH
                                              ,fnd_flex_value_sets           FFVS
                                         WHERE FFVNH.flex_value_set_id          = FFVS.flex_value_set_id
                                         AND   UPPER(FFVNH.parent_flex_value)   = 'CUSTOMER'
                                         )
       ORDER BY  import_type
                ,request_id
                ,message_code;

       TYPE error_rec_tab IS TABLE OF error_rec%ROWTYPE INDEX BY BINARY_INTEGER;
       lcu_error_rec            error_rec_tab;
       ld_start_date            DATE;
       ld_end_date              DATE;
       lc_err_level             VARCHAR2(20);
       lc_status                VARCHAR2(5);
       lc_use_code              hz_cust_site_uses_all.site_use_code%type;
       lc_orig_sys_ref          hz_cust_site_uses_all.orig_system_reference%type;
       lc_spc_flag              VARCHAR2(1);
       ln_exception_cnt         NUMBER   := 0;

    BEGIN

       ld_start_date        := fnd_conc_date.string_to_date(p_start_date);
       ld_end_date          := fnd_conc_date.string_to_date(p_end_date);

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Start Date : '||ld_start_date);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'End Date : '||ld_end_date);

       gc_error_location  := 'Opening the cursor error_rec';
       OPEN error_rec ( ld_start_date
                       ,ld_end_date
                       );
       gc_error_location  := 'Fetching the cursor error_rec into lcu_error_rec';
       FETCH error_rec BULK COLLECT INTO lcu_error_rec;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Number of Errored records to be processed for the given date '||lcu_error_rec.COUNT);
          IF (lcu_error_rec.COUNT > 0) THEN

             PRINT_OUTPUT('Hi,
             ');

          ELSE

             PRINT_OUTPUT('Hi,

No Error Record for the Date passed as parameter.

Thanks'
                          );

          END IF;

       gc_error_location := 'closing the Cursor error_rec';
       CLOSE error_rec;

       FOR i IN 1 .. lcu_error_rec.COUNT
       LOOP

          BEGIN
             gc_error_location := 'Calling REC_STATUS procedure to get the status of the record.';
             gc_debug          := 'Orig System Reference of Customer : '||lcu_error_rec(i).sold_to_org ||CHR(13) ||
                                  'Orig System Reference of Bill To  : '||lcu_error_rec(i).bill_to ||CHR(13) ||
                                  'Orig System Reference of Ship To  : '||lcu_error_rec(i).ship_to_org ||CHR(13) ||
                                  'Message Text : '|| lcu_error_rec(i).message_text;

             -- Get the status of the records fetched.
             REC_STATUS( lcu_error_rec(i).message_code
                        ,lcu_error_rec(i).message_text
                        ,lcu_error_rec(i).sold_to_org
                        ,lcu_error_rec(i).bill_to
                        ,lcu_error_rec(i).ship_to_org
                        ,lcu_error_rec(i).original_sys_document_ref
                        ,lc_err_level
                        ,lc_status
                        ,lc_use_code
                        ,lc_spc_flag
                        );

             -- Decide the orig_system_reference based on the error level.
             IF lc_err_level = 'Customer' THEN

                lc_orig_sys_ref := lcu_error_rec(i).sold_to_org;

             ELSIF lc_use_code = 'Bill_TO' THEN

                lc_orig_sys_ref := lcu_error_rec(i).bill_to;

             ELSIF lc_use_code = 'SHIP_TO' THEN

                lc_orig_sys_ref := lcu_error_rec(i).ship_to_org;

             END IF;

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Orig System Reference :'||lc_orig_sys_ref);

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling REC_ERR_DETAILS procedure');

             gc_error_location := 'Calling REC_ERR_DETAILS procedure';
             gc_debug          := 'For Orig System Reference : '|| lc_orig_sys_ref || CHR(13) ||
                                  'Error Level at            : '|| lc_err_level || CHR(13) ||
                                  'Error Status              : '|| lc_status || CHR(13) ||
                                  'Use Code                  : '|| lc_use_code || CHR(13) ||
                                  'SPC Flag                  : '|| lc_spc_flag;
             -- Validate and print the details in Output File.
             REC_ERR_DETAILS( lc_err_level
                             ,lc_status
                             ,lc_use_code
                             ,lc_orig_sys_ref
                             ,lc_spc_flag
                             );

             EXCEPTION
             WHEN OTHERS THEN

                ln_exception_cnt := ln_exception_cnt + 1;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location : '||gc_error_location);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Debug          :' || CHR(13) ||gc_debug);

             END;

             IF i = lcu_error_rec.LAST THEN

                PRINT_OUTPUT('
Thanks');

             END IF;

       END LOOP;

       IF ln_exception_cnt > 1 THEN

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Some of the Records raised exception');
          x_ret_code := 1;

       END IF;

    EXCEPTION
    WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Location : '||gc_error_location);
       x_ret_code := 2;
    END CUST_INFO_STATUS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : REC_STATUS                                                          |
-- | Description : This procedure is used to check the status of the customer.         |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE REC_STATUS ( p_message_code            IN   VARCHAR2
                          ,p_message_text            IN   VARCHAR2
                          ,p_cust_orig_sys_ref       IN   VARCHAR2
                          ,p_bill_to_orig_sys_ref    IN   VARCHAR2
                          ,p_ship_to_orig_sys_ref    IN   VARCHAR2
                          ,p_doc_orig_sys_ref        IN   VARCHAR2
                          ,x_err_level               OUT  VARCHAR2
                          ,x_status                  OUT  VARCHAR2
                          ,x_use_code                OUT  VARCHAR2
                          ,x_spc_flag                OUT  VARCHAR2
                          )
    IS
       lc_use_code       hz_cust_site_uses_all.site_use_code%type;
       lc_orig_sys_ref   hz_cust_site_uses_all.orig_system_reference%type;
       lc_err_level      VARCHAR2(20);
       lc_status         VARCHAR2(5);
       lc_spc_flag       VARCHAR2(1)  := 'N';

    BEGIN

       lc_use_code   := NULL;
       lc_err_level  := NULL;
       lc_status     := NULL;

       -- Check for SPC Card
       IF LENGTH(p_doc_orig_sys_ref) = 20 THEN

          lc_spc_flag := 'Y';

       END IF;

       -- Check for WWW error
       IF (p_cust_orig_sys_ref LIKE '%--%') OR (p_ship_to_orig_sys_ref LIKE '%--%') OR (p_bill_to_orig_sys_ref LIKE '%--%') THEN

          lc_err_level  := 'WWW';

       -- Check for Customer level error
       ELSIF (p_message_code = 'Validati' AND p_message_text = 'Validation failed for the field -Customer') OR (p_message_code IN ('10000010','10000004')) THEN

          lc_err_level  := 'Customer';

          SELECT status
          INTO   lc_status
          FROM   hz_cust_accounts
          WHERE  orig_system_reference = p_cust_orig_sys_ref;

       -- Check for use code Ship to
       ELSIF (p_message_code = 'Validati' AND p_message_text = 'Validation failed for the field - Ship To') OR (p_message_code = '10000016') THEN

          lc_use_code      := 'SHIP_TO';
          lc_orig_sys_ref  := REPLACE(p_ship_to_orig_sys_ref,'-'||lc_use_code,NULL);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Ship To level');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Orig System Reference :' ||lc_orig_sys_ref);

       -- Check for use code bill to
       ELSIF (p_message_code = 'Validati' AND p_message_text = 'Validation failed for the field - Bill To') OR (p_message_code = '10000021') THEN

          lc_use_code      := 'BILL_TO';
          lc_orig_sys_ref  := REPLACE(p_bill_to_orig_sys_ref,'-'||lc_use_code,NULL);

       END IF;

       -- Validate for the use code Bill To and Ship To
       IF lc_use_code IN ('SHIP_TO','BILL_TO') THEN

          BEGIN

             lc_err_level  := 'Site';
             -- Fetch status at site level.
             SELECT  status
             INTO    lc_status
             FROM    hz_cust_acct_sites_all
             WHERE   orig_system_reference   = lc_orig_sys_ref;

             FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_status :' ||lc_status);

             -- Fetch status at site use level if site level status is active.
             IF lc_status = 'A' THEN

                lc_err_level  := 'Site Uses';
                lc_orig_sys_ref := lc_orig_sys_ref||'-'||lc_use_code;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_orig_sys_ref :' ||lc_orig_sys_ref);

                SELECT  status
                INTO    lc_status
                FROM    hz_cust_site_uses_all
                WHERE   orig_system_reference   = lc_orig_sys_ref;

                FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_status :' ||lc_status);

             END IF;

          EXCEPTION
          WHEN NO_DATA_FOUND THEN

             FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found');

             lc_status     := NULL;

          END;

       END IF;

       x_err_level    := lc_err_level;
       x_status       := lc_status;
       x_use_code     := lc_use_code;
       x_spc_flag     := lc_spc_flag;

    END REC_STATUS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : REC_ERR_DETAILS                                                     |
-- | Description : This procedure is used to display the details of the HVOP error     |
-- |               record.                                                             |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 28-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE REC_ERR_DETAILS ( p_err_level            IN VARCHAR2
                               ,p_status               IN VARCHAR2
                               ,p_use_code             IN VARCHAR2
                               ,p_cust_orig_sys_ref    IN VARCHAR2
                               ,p_spc_flag             IN VARCHAR2
                               )
    IS
       lc_orig_sys_ref   hz_cust_site_uses_all.orig_system_reference%type;
       lc_use_code       hz_cust_site_uses_all.site_use_code%type;
       lc_message        VARCHAR2(2000);

    BEGIN

       -- Check the Customer Satus is inactive and print the output.
       IF p_err_level = 'Customer' AND p_status = 'I' THEN

          lc_message := 'The status of the customer '||p_cust_orig_sys_ref|| ' is Inactive.';

       -- Check the Customer Site or Site Uses Satus is inactive and print the output.
       ELSIF (p_err_level = 'Site' OR p_err_level = 'Site Uses') THEN

          IF p_use_code IS NOT NULL THEN
             lc_use_code := ' ' || p_use_code;
          END IF;

          lc_orig_sys_ref := REPLACE(p_cust_orig_sys_ref,'-'||lc_use_code,NULL);

          IF p_status = 'I' THEN

             lc_message := 'The status of the customer '||p_err_level || ' ' || lc_orig_sys_ref || lc_use_code ||' is Inactive.';

          ELSIF p_status IS NULL THEN

             lc_message := 'Orig System Reference '|| lc_orig_sys_ref || lc_use_code || ' is not found in EBS System.';

          END IF;

       -- Print the output for WWW Error
       ELSIF p_err_level = 'WWW' THEN

          lc_message := 'Time Issue.';

       END IF;

       IF p_spc_flag = 'Y' THEN

          lc_message := lc_message || ' This also has a SPC Card Issue.';

       END IF;

       PRINT_OUTPUT(lc_message);

    END REC_ERR_DETAILS;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : PRINT_OUTPUT                                                        |
-- | Description : This procedure is used to print the output.                         |
-- |                                                                                   |
-- | Parameters  :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 28-SEP-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE PRINT_OUTPUT ( p_message   IN VARCHAR2)
    IS
    BEGIN

       -- Check the program is executed from the concurrent program and print the output in output file else print in DBMS_OUTPUT
       IF FND_GLOBAL.CONC_REQUEST_ID > 0 THEN

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

       ELSE

          DBMS_OUTPUT.PUT_LINE(p_message);

       END IF;

    END PRINT_OUTPUT;

END XX_CRM_HVOP_ERR_REP;

/
SHO ERROR