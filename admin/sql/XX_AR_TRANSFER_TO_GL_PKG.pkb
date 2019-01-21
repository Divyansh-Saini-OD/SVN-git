SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_AR_TRANSFER_TO_GL_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle  Consulting Organization                    |
-- +===================================================================+
-- | Name        :  XX_AR_TRANSFER_TO_GL_PKG.pkb                       |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date         Author           Remarks                   |
-- |========   ===========  ===============  ==========================|
-- | 1.0       01-JUN-2008   P.Suresh        Defect 7011. Multithread  |
-- |                                         Import Journals program.  |
-- | 1.1       13-AUG-2008   P.Suresh        Defect 9690. Made the     |
-- |                                         journal import program as |
-- |                                         child program.            |
-- | 1.2       12-AUG-2008   R.Aldidge       Defect 11117 eliminate    |
-- |                                         perf issue with update    |
-- | 1.3        14-OCT-2008   Aravind A      Defect 12063.Changes for  |
-- |                                         output/log file           |
-- |                                                                   |
-- +===================================================================+
AS

PROCEDURE generate_group (
                          x_errbuf               OUT NOCOPY VARCHAR2
                          ,x_retcode             OUT NOCOPY VARCHAR2
                          ,p_batch_size          IN         NUMBER
                          ,p_req_id              IN         NUMBER
                          ,p_check_interval      IN         NUMBER
                          ,p_max_wait_time       IN         NUMBER
                          ,p_email_id            IN         VARCHAR2
                         )
IS
  --Cursor to get Set of Books Id and Category name for request id--
  CURSOR c_sob (p_request_id NUMBER) IS
  SELECT /*+ full(gi) parallel(gi,4) */ DISTINCT
         set_of_books_id
        ,user_je_category_name
    FROM gl_interface gi
   WHERE user_je_source_name = 'Receivables'
     AND status              = 'NEW'
     AND actual_flag         = 'A'
     AND request_id + 0      = p_request_id;
  --Table Type Definition based on c_sob cursor to collect cursor informations--
  TYPE sob_rec_tbl_type IS TABLE OF c_sob%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_sob_rec sob_rec_tbl_type;
  --Cursor to get Invoice informations--
  CURSOR c_invoice_num (p_sob NUMBER,p_caregory VARCHAR2,p_request_id NUMBER)
  IS
  SELECT reference24 invoice_num
        ,count(*) inv_cnt
    FROM gl_interface
   WHERE user_je_source_name   = 'Receivables'
     AND user_je_category_name =  p_caregory
     AND set_of_books_id       =  p_sob
     AND actual_flag           = 'A'
     AND status                = 'NEW'
     AND request_id            = p_request_id
  GROUP BY reference24;
  --Cursor to get Child request Informations--
  CURSOR  c_imp_jr_reqs
  IS
  SELECT FNDCR.request_id
         ,FNDCR.argument3
    FROM fnd_concurrent_requests FNDCR
   WHERE FNDCR.parent_request_id  = FND_GLOBAL.CONC_REQUEST_ID;
  --Table Type Definition based on c_invoice_num cursor to collect cursor records--
  TYPE inv_rec_tbl_type IS TABLE OF c_invoice_num%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_inv_rec inv_rec_tbl_type;
  --Table Type Definition for collecting invoice number--
  TYPE inv_tbl_type IS TABLE OF  gl_interface.reference24%TYPE
  INDEX BY BINARY_INTEGER;
  lt_inv_num inv_tbl_type;
  --Local Variables declarations--
  ln_parent_request_id      NUMBER :=0;
  ln_request_id             NUMBER :=0;
  ln_group_id               NUMBER :=0;
  ln_batch_count            NUMBER :=0;
  ln_group_start            NUMBER :=1;
  ln_sub_req_phase          VARCHAR2(1000);
  ln_sub_req_status         VARCHAR2(1000);
  ln_sub_dev_phase          VARCHAR2(1000);
  ln_sub_dev_status         VARCHAR2(1000);
  l_message                 VARCHAR2(240);
  ln_child_request_id       NUMBER;
  flg                       BOOLEAN := TRUE;
  l_complete                BOOLEAN ;
  ln_gc_request_id          NUMBER;
  lc_set_of_books_name      gl_sets_of_books.name%TYPE;
  lc_jrnl_import_name       fnd_concurrent_programs_tl.user_concurrent_program_name %TYPE;
  lc_status_code            fnd_lookups.meaning%TYPE;
  ln_req_id                 fnd_concurrent_requests.request_id%TYPE;
  lc_group_id               gl_je_batches.name%TYPE;
  ln_lin_count              NUMBER;
  ln_tot_dr_grp             NUMBER;
  ln_tot_cr_grp             NUMBER;
  ln_tot_dr                 NUMBER;
  ln_tot_cr                 NUMBER;
  ln_difference             NUMBER;
  ln_tot_diff               NUMBER;
  ln_tot_count              NUMBER;
  ln_req_group_id           fnd_concurrent_requests.argument3%TYPE;
  ln_jrnl_imp_ro_req_id     NUMBER;

BEGIN
  IF p_req_id IS NULL THEN
    /* Get the request id of Journal Ledger Transfer Program.
       This is to process only records imported by
       current run of ARGLTP
    */
    BEGIN
      SELECT request_id
        INTO ln_parent_request_id
        FROM fnd_concurrent_requests FCR
            ,fnd_concurrent_programs FCP
       WHERE FCR.CONCURRENT_PROGRAM_ID   = FCP.CONCURRENT_PROGRAM_ID
         AND FCP.CONCURRENT_PROGRAM_NAME = 'ARGLTP'
         AND FCR.PRIORITY_REQUEST_ID     = FND_GLOBAL.conc_priority_request;
    EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, ' Could not find the parent program ');
        x_retcode             := 2;
    END;
  ELSE
    ln_parent_request_id     := p_req_id;
  END IF;
  --Writing into Log file--
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parameters');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '----------');
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Batch Size                     :  ' ||p_batch_size);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Parent Request ID              :  ' ||ln_parent_request_id);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Journal Import Wait Interval   :  ' ||p_check_interval);
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Journal Import Max Wait Time   :  ' ||p_max_wait_time);
  /* Get distinct SOB and Category into PL/SQL table type*/
  OPEN  c_sob (ln_parent_request_id);
  FETCH c_sob BULK COLLECT INTO lt_sob_rec;
  CLOSE c_sob;
  --Get Sequence Next Value--
  SELECT GL_INTERFACE_CONTROL_S.NEXTVAL
    INTO ln_group_id
    FROM DUAL;
  FND_FILE.PUT_LINE(FND_FILE.LOG, CHR(10)||'Grouping Information');
  FND_FILE.PUT_LINE(FND_FILE.LOG, '--------------------');
  IF lt_sob_rec.COUNT <> 0 THEN
    --If PL/SQL table has Value, loop thru it for processing--
    FOR i IN 1..lt_sob_rec.COUNT
    LOOP
      --Writing into Log File--
      FND_FILE.PUT_LINE(FND_FILE.LOG, CHR(10)||'Processing ....'||CHR(10)||
                        'Set of Books      :'||lt_sob_rec(i).set_of_books_id
                        ||CHR(10)||
                        'Category          :'|| lt_sob_rec(i).user_je_category_name);
                        
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, CHR(10)||'Processing ....'||CHR(10)||
                        'Set of Books      :'||lt_sob_rec(i).set_of_books_id
                        ||CHR(10)||
                        'Category          :'|| lt_sob_rec(i).user_je_category_name);
      --If the batch has been processed already, remove the batch id--
      IF ln_batch_count <> 0 THEN -- Not First Time
        ln_batch_count := 0;
        ln_group_id := ln_group_id + 1;
      END IF;
      /* Get Invoice Details into PL/SQL table*/
       OPEN  c_invoice_num (
                            lt_sob_rec(i).set_of_books_id
                           ,lt_sob_rec(i).user_je_category_name
                           ,ln_parent_request_id
                           );
      FETCH c_invoice_num BULK COLLECT INTO lt_inv_rec;
      CLOSE c_invoice_num ;
      ----If PL/SQL table has Value, loop thru it for processing--
      IF lt_inv_rec.COUNT <> 0 THEN
        FOR j IN 1..lt_inv_rec.COUNT
        LOOP
          --Collect Invoice Number into PL/SQL table--
          lt_inv_num(j) :=  lt_inv_rec(j).invoice_num;
          --Check if the Invoice count exceeds the batch size and log the message and make the status of the program to error--
          IF lt_inv_rec(j).inv_cnt  > p_batch_size THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Could not group all the accounting lines of category '
                              || lt_sob_rec(i).user_je_category_name || '  transaction '
                              || lt_inv_rec(j).invoice_num
                              || '  in one batch. Please increase the batch size');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Could not group all the accounting lines of category '
                              || lt_sob_rec(i).user_je_category_name || '  transaction '
                              || lt_inv_rec(j).invoice_num
                              || '  in one batch. Please increase the batch size');
            x_retcode := 2;
            RETURN;
          ELSIF (ln_batch_count + lt_inv_rec(j).inv_cnt) <= p_batch_size
          --Check if the Invoice count is less than batch size when added to batch count, then increment the batch count with invoice count--
          --Records will be collected and processed outside the loop--<<ref1>>
          THEN
            ln_batch_count := ln_batch_count + lt_inv_rec(j).inv_cnt;
          ELSE
            --Update the gl_interface Table with group id for current invoice num--
            --Defect 11117 : Changed the condition request_id + 0 to request_id as recommended by Enliu
            FORALL k IN ln_group_start..j-1
            UPDATE  /*+ index(gl_interface xx_gl_interface_n1) */ gl_interface
               SET  group_id             = ln_group_id
             WHERE  set_of_books_id       = lt_sob_rec(i).set_of_books_id
               AND  user_je_source_name   = 'Receivables'
               AND  user_je_category_name = lt_sob_rec(i).user_je_category_name
               AND  reference24           = lt_inv_num(k)
               AND  actual_flag           = 'A'
               AND  status                = 'NEW'
               AND  request_id            = ln_parent_request_id;
            COMMIT;
            --Submit Journal Import Program--
            ln_request_id :=
            FND_REQUEST.SUBMIT_REQUEST
            (
             application => 'SQLGL'
            ,program     => 'GLLEZLSRS'
            ,description => NULL
            ,start_time  => NULL
            ,sub_request => FALSE
            ,argument1   => lt_sob_rec(i).set_of_books_id
            ,argument2   => 'Receivables'
            ,argument3   => ln_group_id
            ,argument4   => 'N'
            ,argument5   => 'Y'
            ,argument6   => 'Y'
            );
            COMMIT;
            --Log Message into program Log--
            /*FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' Successfully submitted Import Journal Program '
                              || ln_request_id
                              || '  for group '
                              || ln_group_id);*/
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Successfully submitted Import Journal Program '|| ln_request_id
                                              || '  for group '|| ln_group_id);
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Successfully submitted Import Journal Program '|| ln_request_id
                                              || '  for group '|| ln_group_id);
            --Get Next group id for next batch--
            SELECT GL_INTERFACE_CONTROL_S.NEXTVAL
              INTO ln_group_id
              FROM DUAL;
            --get current invoice records number in PL/SQL table--
            ln_group_start := j;
            --Log Message into Program Log--
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Group             : '|| ln_group_id|| ' has been created.'||CHR(10)
                              ||'Total no of accounting lines included in this group : '|| ln_batch_count );
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Group             : '|| ln_group_id|| ' has been created.'||CHR(10)
                              ||'Total no of accounting lines included in this group : '|| ln_batch_count );
          
            ln_batch_count := lt_inv_rec(j).inv_cnt;
            ln_group_id    := ln_group_id +1;
          END IF;
        END LOOP;
        --Update all Invoice Records with Group Id, which falls within batch size--
        ----<<ref1>>--
        --Defect 11117 : Changed the condition request_id + 0 to request_id as recommended by Enliu
        FORALL l IN ln_group_start..lt_inv_rec.COUNT
        UPDATE  /*+ index(gl_interface xx_gl_interface_n1) */ gl_interface
           SET  group_id             = ln_group_id
         WHERE  set_of_books_id       = lt_sob_rec(i).set_of_books_id
           AND  user_je_source_name   = 'Receivables'
           AND  user_je_category_name = lt_sob_rec(i).user_je_category_name
           AND  reference24           = lt_inv_num(l)
           AND  actual_flag           = 'A'
           AND  status                = 'NEW'
           AND  request_id            = ln_parent_request_id;
        --Log message into Program Log--
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Group             : ' || ln_group_id || ' has been created.'||CHR(10)
                                         ||'Total no of accounting lines included in this group : ' || ln_batch_count );
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Group             : ' || ln_group_id || ' has been created.'||CHR(10)
                                         ||'Total no of accounting lines included in this group : ' || ln_batch_count );
        ln_group_start :=1;
        COMMIT;
        --Submit Journal Import program--
        ln_request_id :=
                         FND_REQUEST.SUBMIT_REQUEST
                         (
                          application => 'SQLGL'
                         ,program     => 'GLLEZLSRS'
                         ,description => NULL
                         ,start_time  => NULL
                         ,sub_request => FALSE
                         ,argument1   => lt_sob_rec(i).set_of_books_id
                         ,argument2   => 'Receivables'
                         ,argument3   => ln_group_id
                         ,argument4   => 'N'
                         ,argument5   => 'Y'
                         ,argument6   => 'Y'
                         );
        COMMIT;
        --Log Message into Program Log--
        /*FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' Successfully submitted Import Journal Program '
                          || ln_request_id
                          || '  for Batch  '
                          || ln_group_id);*/
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Successfully submitted Import Journal Program '|| ln_request_id
                                        || '  for Batch  '|| ln_group_id);
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Successfully submitted Import Journal Program '|| ln_request_id
                                        || '  for Batch  '|| ln_group_id);
      
        --Get Next Group Id for next batch--
        SELECT GL_INTERFACE_CONTROL_S.NEXTVAL
          INTO ln_group_id
          FROM DUAL;
      END IF;
    END LOOP;
  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG, ' No Accounting Lines to Process ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' No Accounting Lines to Process ');
    x_retcode := 1;
    RETURN;
  END IF;
  --Since we DO NOT want all the child programs(Journal Import) to wait till--
  --the parent program(OD: GL Multi Threading) completes processing all the records--
  --we are not submitting the Journal import program as the child program.--
     --Commented for fix of defect 12063
     /*FND_FILE.PUT_LINE(FND_FILE.OUTPUT, chr(10) || '*******************************************************************************************************' || chr(10));
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            '***************************** Journal Import Request Exception Report *********************************');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, chr(10) || '*******************************************************************************************************' || chr(10));*/
     --Added for 12063
    -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT, chr(10) || '****************************************************************************************************************************' || chr(10));
   --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            '****************************************** OD Multithread Import Execution Report ******************************************');
   --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            '*  OFFICE DEPOT INC                                                                        Report Date: '||TO_CHAR(SYSDATE,'DD-MON-YYYY HH:MI')||'  *'||CHR(10));
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            'Multithread Request ID                      : '||FND_GLOBAL.CONC_REQUEST_ID||CHR(10));
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            'General Ledger Transfer Program Request ID  : '||p_req_id||CHR(10));

     SELECT name
     INTO   lc_set_of_books_name
     FROM   gl_sets_of_books
     WHERE  set_of_books_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');

     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            'Operating Unit                              : '||lc_set_of_books_name);
     --FND_FILE.PUT_LINE(FND_FILE.OUTPUT, chr(10) || '****************************************************************************************************************************' || chr(10));
    -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            'PROGRAM NAME      GROUP ID      REQUEST ID      REQUEST STATUS      Count      Total Debit      Total Credit      Difference');
    -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            '------------      --------      -----------     --------------      -----      -----------      ------------      ----------');
     FND_FILE.PUT_LINE(FND_FILE.LOG, chr(10) || '*******************************************************************************************************' || chr(10));
     FND_FILE.PUT_LINE(FND_FILE.LOG,            '********************************* Journal Imports Submitted *******************************************');
     FND_FILE.PUT_LINE(FND_FILE.LOG, chr(10) || '*******************************************************************************************************' || chr(10));

     ln_tot_dr    := 0;
     ln_tot_cr    := 0;
     ln_tot_diff  := 0;
     ln_tot_count := 0;

    OPEN c_imp_jr_reqs;----------Child Requests
    LOOP
    FETCH c_imp_jr_reqs INTO ln_child_request_id,ln_req_group_id;
    EXIT WHEN c_imp_jr_reqs%NOTFOUND;
    --Wait for child request to Complete--
    l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST
                   (
                     request_id => ln_child_request_id
                    ,interval   => p_check_interval
                    ,max_wait   => p_max_wait_time
                    ,phase      => ln_sub_req_phase
                    ,status     => ln_sub_req_status
                    ,dev_phase  => ln_sub_dev_phase
                    ,dev_status => ln_sub_dev_status
                    ,message    => l_message
                   );
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Group ID '||ln_req_group_id||' :');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Group ID '||ln_req_group_id||' :');
    IF ln_sub_dev_phase <> 'COMPLETE' THEN
      --If not completed, still child requests are running or in pending--
      x_retcode := 1;
      --FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' The Program - Import Journals, request id ' || ln_child_request_id || ' is running for more than ' || p_max_wait_time || ' seconds. Please increase the Journal Import maximum wait parameter value.' || chr(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG, '   The Program - Import Journals, request id ' || ln_child_request_id || ' is running for more than ' || p_max_wait_time || ' seconds. Please increase the Journal Import maximum wait parameter value.');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   The Program - Import Journals, request id ' || ln_child_request_id || ' is running for more than ' || p_max_wait_time || ' seconds. Please increase the Journal Import maximum wait parameter value.');
    ELSIF ln_sub_dev_status = 'WARNING' THEN
      --If child request completes with warning make parent status to warning--
      IF NVL(x_retcode, 1) <> 2 THEN
        x_retcode := 1;
        --FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' The Program - Import Journals, request id ' || ln_child_request_id  || ' completed in warning. ' || chr(10));
        FND_FILE.PUT_LINE(FND_FILE.LOG, '   The Program - Import Journals, request id ' || ln_child_request_id  || ' completed in warning. ');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   The Program - Import Journals, request id ' || ln_child_request_id  || ' completed in warning. ');
      END IF;
    ELSIF ln_sub_dev_status <> 'NORMAL' THEN
      --If child requests get completed with error, error out parent program--
      -- ERROR
      x_retcode := 2;
      --FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' The Program - Import Journals, request id ' || ln_child_request_id || ' does not complete Normal,  - ' ||ln_sub_req_status || chr(10));
      FND_FILE.PUT_LINE(FND_FILE.LOG, '   The Program - Import Journals, request id ' || ln_child_request_id || ' does not complete Normal,  - ' ||ln_sub_req_status);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   The Program - Import Journals, request id ' || ln_child_request_id || ' does not complete Normal,  - ' ||ln_sub_req_status);
    ELSE
      --Request Completed Normal--
      FND_FILE.PUT_LINE(FND_FILE.LOG, '   The Program - Import Journals, request id ' || ln_child_request_id || ' completed Normal.');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   The Program - Import Journals, request id ' || ln_child_request_id || ' completed Normal.');
    END IF;
    flg := TRUE;
    --Make parent to wait for grand child requests--
    IF ln_sub_dev_status = 'NORMAL' THEN
      WHILE (flg)
      LOOP
        BEGIN
          --Get Grand Child request--
          SELECT FNDCR.request_id
            INTO ln_gc_request_id
            FROM fnd_concurrent_requests FNDCR
           WHERE FNDCR.parent_request_id  = ln_child_request_id
             AND ROWNUM =1;
          flg := FALSE;
          l_complete := FND_CONCURRENT.WAIT_FOR_REQUEST
                       (
                         request_id => ln_gc_request_id
                        ,interval   => p_check_interval
                        ,max_wait   => p_max_wait_time
                        ,phase      => ln_sub_req_phase
                        ,status     => ln_sub_req_status
                        ,dev_phase  => ln_sub_dev_phase
                        ,dev_status => ln_sub_dev_status
                        ,message    => l_message
                        );
          IF ln_sub_dev_phase <> 'COMPLETE' THEN
            --If not completed, still Grand child requests are running or in pending--
            x_retcode := 1;
            --FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' The Journal Import request ' || ln_gc_request_id|| ' is running for more than ' || p_max_wait_time || ' seconds. Please increase the Journal Import maximum wait parameter value.' || chr(10));
            FND_FILE.PUT_LINE(FND_FILE.LOG, '   The Journal Import request ' || ln_gc_request_id|| ' is running for more than ' || p_max_wait_time || ' seconds. Please increase the Journal Import maximum wait parameter value.');
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   The Journal Import request ' || ln_gc_request_id|| ' is running for more than ' || p_max_wait_time || ' seconds. Please increase the Journal Import maximum wait parameter value.');
          ELSIF  ln_sub_dev_status = 'WARNING' THEN
            --If child request completes with warning make parent status to warning--
            --FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' The Journal Import concurrent program, request id ' || ln_gc_request_id|| ' completed in Warning. '|| chr(10));
            FND_FILE.PUT_LINE(FND_FILE.LOG, '   The Journal Import concurrent program, request id ' || ln_gc_request_id|| ' completed in Warning. ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   The Journal Import concurrent program, request id ' || ln_gc_request_id|| ' completed in Warning. ');
            --Check if the status is  not set as error--
            --Check if the status is not set ann set to warning--
            IF NVL(x_retcode, 1) <> 2 THEN
              x_retcode := 1;
            END IF;
          ELSIF  ln_sub_dev_status <> 'NORMAL' THEN
            --If child requests get completed with error, error out parent program--
            x_retcode := 2;
            --FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ' The Journal Import concurrent program, request id ' || ln_gc_request_id|| '  -  ' ||ln_sub_req_status || chr(10));
            FND_FILE.PUT_LINE(FND_FILE.LOG, '   The Journal Import concurrent program, request id ' || ln_gc_request_id|| ' does not complete Normal, Completed with status - ' ||ln_sub_req_status);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   The Journal Import concurrent program, request id ' || ln_gc_request_id|| ' does not complete Normal, Completed with status - ' ||ln_sub_req_status);
          ELSE
            --Grand Child request Completed Normal--
            FND_FILE.PUT_LINE(FND_FILE.LOG, '   The Journal Import concurrent program, request id ' || ln_gc_request_id|| ' completed Normal.');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '   The Journal Import concurrent program, request id ' || ln_gc_request_id|| ' completed Normal.');
            ln_jrnl_imp_ro_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                                                'XXFIN'
                                                                ,'XXODROEMAILER'
                                                                ,NULL
                                                                ,NULL
                                                                ,FALSE
                                                                ,'GLLEZL'
                                                                ,p_email_id
                                                                ,'Journal Import Program Output'
                                                                ,'Please find attached the Journal Import Program Output'
                                                                ,'Y'
                                                                ,ln_gc_request_id
                                                               );
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --When Grand Child has not been submitted--
            --Set it as true--
            --till it is setting this flag to false, loop will execute--
            flg := TRUE;
          WHEN OTHERS THEN
            raise;
        END;
      END LOOP; /* While */

    /*  --Added for defect 12063
      BEGIN
         lc_jrnl_import_name := NULL;
         ln_req_id           := 0;
         lc_group_id         := NULL;
         lc_status_code      := NULL;
         ln_tot_dr_grp       := 0;
         ln_tot_cr_grp       := 0;
         ln_difference       := 0;
         ln_lin_count        := 0;

         SELECT fcpt.user_concurrent_program_name
                ,fcr.request_id
                ,SUBSTR(gjb.name,INSTR(gjb.name,' ',1,5)) group_id
                ,fl.meaning
                ,gjb.running_total_dr
                ,gjb.running_total_cr
                ,(gjb.running_total_dr - gjb.running_total_cr) difference
                ,COUNT(gjl.je_line_num)
         INTO   lc_jrnl_import_name
                ,ln_req_id
                ,lc_group_id
                ,lc_status_code
                ,ln_tot_dr_grp
                ,ln_tot_cr_grp
                ,ln_difference
                ,ln_lin_count
         FROM   fnd_concurrent_requests fcr
                ,fnd_concurrent_programs_tl fcpt
                ,fnd_lookups   fl
                ,gl_je_batches gjb
                ,gl_je_headers gjh
                ,gl_je_lines   gjl
         WHERE  fcr.request_id = ln_gc_request_id
         AND    fcr.concurrent_program_id = fcpt.concurrent_program_id
         AND    fl.lookup_type = 'CP_STATUS_CODE'
         AND    fcr.status_code = fl.lookup_code
         AND    fcr.request_id = SUBSTR(gjb.name,INSTR(gjb.name,' ',1,3),(INSTR(gjb.name,' ',1,4)-INSTR(gjb.name,' ',1,3)-1))
         AND    gjb.je_batch_id  = gjh.je_batch_id
         AND    gjh.je_header_id = gjl.je_header_id
         AND    gjb.name LIKE 'AR%'
         GROUP BY fcpt.user_concurrent_program_name
                  ,fcr.request_id
                  ,SUBSTR(gjb.name,INSTR(gjb.name,' ',1,5))
                  ,fl.meaning
                  ,gjb.running_total_dr
                  ,gjb.running_total_cr
                  ,(gjb.running_total_dr - gjb.running_total_cr);

         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            RPAD(lc_jrnl_import_name,17,' ')||RPAD(lc_group_id,15,' ')||RPAD(ln_req_id,16,' ')||RPAD(lc_status_code,18,' ')||LPAD(ln_lin_count,7,' ')||LPAD(ln_tot_dr_grp,17,' ')||LPAD(ln_tot_cr_grp,18,' ')||LPAD(ln_difference,16,' '));
         ln_tot_dr := ln_tot_dr + ln_tot_dr_grp;
         ln_tot_cr := ln_tot_cr + ln_tot_cr_grp;
         ln_tot_diff := ln_tot_diff + ln_difference;
         ln_tot_count := ln_tot_count + ln_lin_count;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Journal Import Details for Request ID '||ln_gc_request_id||' could not be found');
         WHEN TOO_MANY_ROWS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Multiple Journal Groups were created for Request ID '||ln_gc_request_id);
      END;*/


    END IF;
  END LOOP; /* Cursor */
  CLOSE c_imp_jr_reqs;
 -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            '                                                                 __________    ___________      _____________     __________');
--  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            '                                                      Total       '||LPAD(ln_tot_count,7,' ')||LPAD(ln_tot_dr,17,' ')||LPAD(ln_tot_cr,18,' ')||LPAD(ln_tot_diff,16,' '));
 -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            '                                                                 __________    ___________      _____________     __________');
 -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,            CHR(10)||'*******************************************************End of Report *******************************************************');
EXCEPTION
  WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unexpected Error ....' || SQLERRM);
    x_retcode             := 2;
END generate_group;
END XX_AR_TRANSFER_TO_GL_PKG;
/
SHOW ERR