CREATE OR REPLACE PACKAGE BODY XX_OD_CREDIT_FLAG_CHK_PKG
AS
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_CREDIT_FLAG_CHK_PKG                                   |
-- | Description :                                                             |
-- | This package helps us to check if AOPS A/R credit flag and attribute3 of  |
-- | hz_customer_profiles are in synch and outputs the mismatch records        |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-JUN-2010 Renupriya     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+
   PROCEDURE XX_OD_CREDIT_FLAG_CHK_MAIN(
          p_errbuf        OUT    VARCHAR2
        , p_retcode       OUT    NUMBER
        , p_file_name     IN     VARCHAR2
        )
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_CREDIT_FLAG_CHK_PROC                                  |
-- | Description :                                                             |
-- | This is the main procedure which calls 2 procedures: 1) Procedure to      |
-- | populate the custom table with AOPS data from csv file and 2)Procedure    |
-- | to check if AOPS credit flag and attribute3 in CDH are in synch.          |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-JUN-2010 Renupriya     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+
   AS
       x_retcode NUMBER  :=0;
       x_retmsg  VARCHAR2(4000);
       ln_retcode NUMBER  :=0;
       lc_retmsg  VARCHAR2(4000);

       CURSOR   lcu_cust_details (lc_aops_account_number IN VARCHAR2)
       IS
       SELECT      HCP.profile_class_id
                 , HCP.attribute3
                 , HCP.standard_terms
                 , HCP.collector_id
                 , HCA.cust_account_id
                 , HCA.status
                 , HCA.account_name
                 , HCA.attribute18
                 , HCA.account_number
                 , HCPA.overall_credit_limit
                 , HCPA.currency_code
                 , HCPC.name  profile_class_name
                 , ARC.name   collector_name
                 , TERM.name  term_name
        FROM       hz_cust_accounts HCA
                  ,hz_customer_profiles HCP
                  ,hz_cust_profile_amts HCPA
                  ,hz_cust_profile_classes HCPC
                  ,ar_collectors ARC
                  ,ra_terms TERM
        WHERE   HCPA.cust_account_profile_id = HCP.cust_account_profile_id
        AND     HCPA.cust_account_id         = HCP.cust_account_id
        AND     HCP.cust_account_id          = HCA.cust_account_id
        AND     ARC.collector_id=HCP.collector_id
        AND     TERM.term_id=HCP.standard_terms
        AND     HCPC.profile_class_id=HCP.profile_class_id
        AND     HCP.site_use_id IS NULL
       --AND     SUBSTR(HCA.orig_system_reference,1,8)= lc_aops_account_number;
        AND     HCA.orig_system_reference = lc_aops_account_number||'-00001-A0'; --Changed on 14/07/10 


        lrec_cust_details           lcu_cust_details%rowtype;
        ln_credit_lt_cad            NUMBER:=0;
        ln_credit_lt_usd            NUMBER:=0;
        lc_customer_type            VARCHAR2(20);
        lc_file_name                VARCHAR2(120);
        lc_file_path                VARCHAR2(200):='$XXCRM_DATA/ftp/in/XX_AB_Flag/'; 
        lc_full_file_name           VARCHAR2(320);
        lc_source_file_name         VARCHAR2(320);
        lc_dest_file_name           VARCHAR2(320);
        ln_req_id                   NUMBER:=0;
        ln_conc_req_id              NUMBER:=0;
        ln_file_name_ext_ptr        NUMBER:=0;
        lc_profile_option_table1    VARCHAR2(100) ;
        lc_profile_option_table2    VARCHAR2(100) ;

        TYPE aops_data_record IS RECORD ( 
        lr_acc_num  varchar2(2000),
        lr_cust_type varchar2(2000),
        lr_cust_name  varchar2(2000),
        lr_cust_status varchar2(2000));

        TYPE aops_data_table IS TABLE OF aops_data_record
        INDEX BY BINARY_INTEGER;
        lt_aops_data_tab aops_data_table;
        lcu_aops_to_temp SYS_REFCURSOR;

   BEGIN

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,chr(10));
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Office Depot');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, SYSDATE);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OD: AR Credit Flag Report');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Legacy Customer Number'||','||
                                          'Legacy Status'||','||
                                          'Oracle Customer Number'||','||
                                          'Oracle Status'||','||
                                          'Customer Name'||','||
                                          'Profile Class'||','||
                                          'Credit Limit - USD'||','||
                                          'Credit Limit - CSD'||','||
                                          'AOPS AR Credit Flag'||','||
                                          'Oracle Attribute3'||','||
                                          'Collector Code'||','||
                                          'Payment Term'||','||
                                          'OD Customer Type');

-- ==========================================================================
-- Truncate previously processed records from temp table
-- ==========================================================================

        EXECUTE IMMEDIATE ('TRUNCATE TABLE xxcrm.XXCRM_CREDIT_FLAG_TEMP');

-- ==================================================================================
-- Call SQL Loader program to load the temp table if file name is given as parameter
-- ==================================================================================
        lc_full_file_name:=lc_file_path||p_file_name;
        IF p_file_name IS NOT NULL
        THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Temp table loading is done by SQL Loader');
          XX_OD_CREDIT_FLAG_TEMP_LOAD(lc_full_file_name,x_retcode,x_retmsg);
        ELSE
        BEGIN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Temp table loading is done by DB Link Approach');

-- ====================================================================================
--  Get DB Link name from profile option to load data from AOPS table to temp 
--  if file name is not given as parameter
-- ====================================================================================

          lc_profile_option_table1:=FND_PROFILE.VALUE('XX_CDH_AB_FLAG_DBLINK_NAME');
          FND_FILE.PUT_LINE (fnd_file.LOG,'AOPS table for AB Flag: '||lc_profile_option_table1);
          lc_profile_option_table2:=FND_PROFILE.VALUE('XX_CDH_AB_FLAG_DET_DBLINK_NAME');
          FND_FILE.PUT_LINE (fnd_file.LOG,'AOPS table for customer details: '||lc_profile_option_table2);

-- =====================================================================================
-- Query to fetch AOPS records
-- =====================================================================================
          OPEN lcu_aops_to_temp FOR 
          'SELECT fcu.fcu000p_customer_id, fcu.fcu000p_cont_retail_code 
          ,fcu.fcu000p_business_name,fcu.fcu000p_delete_flag
           FROM '||lc_profile_option_table1||' '|| 'ccu,'||lc_profile_option_table2||' '||' fcu
           WHERE ccu.ccu007f_customer_id=fcu.fcu000p_customer_id
           AND ccu.ccu007f_ar_flag= ' || '''Y''';

          LOOP
             FETCH lcu_aops_to_temp 
             BULK COLLECT
             INTO lt_aops_data_tab LIMIT 10000;
             EXIT WHEN lt_aops_data_tab.COUNT=0;

             FOR i IN 1..lt_aops_data_tab.COUNT
             LOOP
                INSERT INTO xxcrm.XXCRM_CREDIT_FLAG_TEMP(aops_account_number,aops_cust_type,aops_cust_name,aops_cust_status) 
                                                 VALUES (lt_aops_data_tab(i).lr_acc_num,DECODE(lt_aops_data_tab(i).lr_cust_type,'C','CONTRACT','R','DIRECT','ERROR'),lt_aops_data_tab(i).lr_cust_name,lt_aops_data_tab(i).lr_cust_status);
             END LOOP;
             
          END LOOP;
          COMMIT;
          CLOSE lcu_aops_to_temp ;
        
          FND_FILE.put_line(FND_FILE.log,'Loading temp table completed');
          x_retcode:=0;
          x_retmsg:='Load program completed';
          
        EXCEPTION
        WHEN OTHERS THEN
          x_retmsg := 'Error - Unexpected Error in XX_OD_CREDIT_FLAG_CHK_PKG.XX_OD_CREDIT_FLAG_TEMP_LOAD'
               || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SQLERRM;
               
          FND_FILE.put_line(FND_FILE.log,x_retmsg);
          x_retcode:=2;
        END;
        END IF;

-- ==========================================================================
-- If Loading temp table fails, make program end in Error
-- ==========================================================================
        IF ( x_retcode = 2 )
        THEN
           FND_FILE.put_line(FND_FILE.log,' Loading  temp table failed ');
           ln_retcode:=2;
           p_errbuf:='Program Failed';
        
-- ==========================================================================
-- If Loading temp table is successful, call creditflag check procedure
-- ==========================================================================
        ELSE
        
            FND_FILE.put_line(FND_FILE.log,'Loading temp table is Successful');
            FND_FILE.put_line(FND_FILE.log,x_retmsg);
            BEGIN
            XX_OD_CREDIT_FLAG_CHK_PROC(ln_retcode,lc_retmsg);
            EXCEPTION
            WHEN OTHERS THEN
             FND_FILE.put_line(FND_FILE.log,'Error : '||SQLERRM);
            END;

-- ==========================================================================================================
--  Update process status of temp table when mismatch : AOPS Flag:'Y' and  Oracle Attr3: 'N'
--  and output in report
-- ============================================================================================================
            FOR lcu_mismatch_update IN (SELECT XCFT.aops_account_number,XCFT.aops_cust_status FROM xxcrm.XXCRM_CREDIT_FLAG_TEMP XCFT WHERE process_status IS NULL)
            LOOP
               ln_credit_lt_usd:=0;
               ln_credit_lt_cad:=0;
               lrec_cust_details:=NULL;
            OPEN lcu_cust_details(lcu_mismatch_update.aops_account_number);
            LOOP
               EXIT WHEN lcu_cust_details%NOTFOUND;
               FETCH lcu_cust_details INTO lrec_cust_details;
               IF lrec_cust_details.currency_code='CAD'
               THEN
                 ln_credit_lt_cad:=lrec_cust_details.overall_credit_limit;
               ELSE
                 ln_credit_lt_usd:=lrec_cust_details.overall_credit_limit;
               END IF;
            END LOOP;
            CLOSE lcu_cust_details;

            IF lrec_cust_details.account_number IS NULL
            THEN
            FND_FILE.put_line(FND_FILE.log,'AOPS Customer number: ' ||lcu_mismatch_update.aops_account_number ||' does not exist in CDH');
            END IF;
            FND_FILE.put_line(FND_FILE.OUTPUT,lcu_mismatch_update.aops_account_number||','||
                                           lcu_mismatch_update.aops_cust_status||','||
                                           lrec_cust_details.account_number||','||
                                           lrec_cust_details.status||','||
                                           '"'||lrec_cust_details.account_name||'"'||','||
                                           '"'||lrec_cust_details.profile_class_name||'"'||','||
                                           ln_credit_lt_usd||','||
                                           ln_credit_lt_cad||','||
                                           'Y'||','||
                                           NVL(lrec_cust_details.attribute3,'N')||','||
                                           '"'||lrec_cust_details.collector_name||'"'||','||
                                           '"'||lrec_cust_details.term_name||'"'||','||
                                           lrec_cust_details.attribute18);
            
            UPDATE xxcrm.XXCRM_CREDIT_FLAG_TEMP XCFT
            SET XCFT.process_status = 'E'
               ,XCFT.process_date=SYSDATE
               ,XCFT.attribute1='Mismatch Record:CDH-N,AOPS-Y'
            WHERE XCFT.aops_account_number=lcu_mismatch_update.aops_account_number;
            FND_FILE.put_line(FND_FILE.log,'Record '||lcu_mismatch_update.aops_account_number||' updated to Error');
            lc_retmsg := '';
            ln_retcode := 1;

            END LOOP;
            COMMIT;
            FND_FILE.put_line(FND_FILE.log,'ln_retcode : '||ln_retcode);
        END IF;
-- =================================================================
--  Update Errbuf and retcode
-- =================================================================
            IF ( ln_retcode = 2 )
            THEN
                p_retcode := 2;
                p_errbuf := 'Program Ended in Error';
                FND_FILE.put_line(FND_FILE.log,'Ended in Error');
            ELSIF ( ln_retcode = 1 )
            THEN
                p_retcode := 1;
                p_errbuf := 'Program Ended in Warning';
                FND_FILE.put_line(FND_FILE.log,'Ended in Warning');
            ELSIF ( ln_retcode = 0 )
            THEN
                p_retcode := 0;
                p_errbuf := 'Program Ended in Success';
                FND_FILE.put_line(FND_FILE.log,'Ended  Successfully');
            END IF;
-- ===================================================================================================
-- Store a copy of the AOPS csv file in a different name.
-- ===================================================================================================
            IF p_file_name is NOT NULL
            THEN
               IF ((ln_retcode=0) OR (ln_retcode=1))
               THEN
                  ln_conc_req_id:= FND_GLOBAL.CONC_REQUEST_ID;
                  ln_file_name_ext_ptr := INSTR(lc_full_file_name,'.',1);
                  lc_source_file_name  := SUBSTR(lc_full_file_name,1,ln_file_name_ext_ptr-1);
                  lc_dest_file_name:=lc_source_file_name||'_'||ln_conc_req_id||'.txt';
                  ln_req_id := FND_REQUEST.SUBMIT_REQUEST ('xxfin'
                                                          ,'XXCOMFILCOPY'
                                                          ,''
                                                          , SYSDATE
                                                          , FALSE
                                                          , lc_full_file_name
                                                          , lc_dest_file_name
                                                          , ''
                                                          , ''
                                                          ,'Y'
                                                          ,'$XXFIN_DATA/archive/inbound'
                                                         );
                 COMMIT;
                 FND_FILE.PUT_LINE (fnd_file.LOG,'XXCOMFILCOPY Submitted. Request_id = '||ln_req_id);
               END IF;
            END IF;

          
   EXCEPTION
   WHEN OTHERS THEN
    p_errbuf := 'Error - Unexpected Error in XX_OD_CREDIT_FLAG_CHK_PKG.XX_OD_CREDIT_FLAG_CHK_MAIN '
               || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SQLERRM;
               
    FND_FILE.put_line(FND_FILE.log,p_errbuf);
    p_retcode:=2;
   END XX_OD_CREDIT_FLAG_CHK_MAIN;


   PROCEDURE XX_OD_CREDIT_FLAG_TEMP_LOAD(
                                         p_file_name    IN      VARCHAR2,
                                         x_retcode      OUT     NUMBER,
                                         x_retmsg       OUT     VARCHAR2)
   IS
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_CREDIT_FLAG_TEMP_LOAD                                 |
-- | Description :                                                             |
-- | This procedure is to load the AOPS csv data into the custom table         |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-JUN-2010 Renupriya     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+
      ln_req_id              NUMBER:=0;
      lb_request_status      BOOLEAN;
      lc_phase               VARCHAR2(1000);
      lc_status              VARCHAR2(1000);
      lc_devphase            VARCHAR2(1000);
      lc_devstatus           VARCHAR2(1000);
      lc_message             VARCHAR2(4000);

    BEGIN
-- ====================================================================================
-- Submit SQL Loader Program
-- ====================================================================================
          ln_req_id := FND_REQUEST.SUBMIT_REQUEST ('xxcrm'
                                                  ,'XXODCREDITFLGLOAD'
                                                  ,''
                                                  , SYSDATE
                                                  , FALSE
                                                  , p_file_name
                                                  );
          COMMIT;
          FND_FILE.PUT_LINE (fnd_file.LOG,'XXODCREDITFLGLOAD Submitted. Request_id = '||ln_req_id);
-- =====================================================================================
-- Wait till Loader program complete
-- =====================================================================================
          lb_request_status :=
             FND_CONCURRENT.WAIT_FOR_REQUEST(request_id      => ln_req_id,
                                             interval        => 10,
                                             max_wait        => '',
                                             phase           => lc_phase,
                                             STATUS          => lc_status,
                                             dev_phase       => lc_devphase,
                                             dev_status      => lc_devstatus,
                                             MESSAGE         => lc_message
                                            );
          FND_FILE.PUT_LINE (fnd_file.LOG,lc_status ||','||lc_devphase||','||lc_devstatus||','||lc_message);
          
          IF ( ln_req_id = 0 )
          THEN
             FND_FILE.PUT_LINE (fnd_file.LOG,'Submission Failed');
             x_retcode:=2;
             x_retmsg:='SQL Loader Program not submitted';
          ELSE
            IF (lc_status = 'Error')
            THEN
              x_retcode:=2;
              x_retmsg:='SQL Loader Program completed with Error ';
              FND_FILE.PUT_LINE (fnd_file.LOG,'In retcode2: '||x_retcode);
            ELSE
              x_retcode:=0;
              x_retmsg:='SQL Loader Program Completed';
              FND_FILE.PUT_LINE (fnd_file.LOG,'In retcode0: '||x_retcode);
            END IF;
          END IF;
    EXCEPTION
    WHEN OTHERS THEN
    x_retmsg := 'Error - Unexpected Error in XX_OD_CREDIT_FLAG_CHK_PKG.XX_OD_CREDIT_FLAG_TEMP_LOAD '||Chr(10)||
                'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SQLERRM;
               
    FND_FILE.put_line(FND_FILE.log,x_retmsg);
    --lc_status := 'Error';
    x_retcode:=2;
    END XX_OD_CREDIT_FLAG_TEMP_LOAD;


    PROCEDURE XX_OD_CREDIT_FLAG_CHK_PROC (
                                          x_retcode   OUT NUMBER,
                                          x_retmsg    OUT VARCHAR2)
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- |                         WIPRO/Office Depot                                |
-- +===========================================================================+
-- | Name        : XX_OD_CREDIT_FLAG_CHK_PROC                                  |
-- | Description :                                                             |
-- | This procedure helps us to check if AOPS A/R credit flag and attribute3   |
-- | of hz_customer_profiles are in synch and outputs the mismatch records as  |
-- | output flag and type.                                                     |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 17-JUN-2010 Renupriya     Initial draft version                   |
-- |                                                                           |
-- +===========================================================================+
  AS
     CURSOR lcu_hz_cust_profile
     IS
        SELECT     HCP.cust_account_profile_id
                 , HCP.profile_class_id
                 , HCP.attribute3
                 , HCP.standard_terms
                 , HCP.collector_id
                 , HCA.cust_account_id
                 , HCA.status
                 , HCA.account_name
                 , HCA.attribute18
                 , HCA.account_number
                 , SUBSTR(HCA.orig_system_reference,1,8) aops_acct_number
        FROM    hz_customer_profiles HCP,
                hz_cust_accounts      HCA
        WHERE   hcp.cust_account_id =  HCA.cust_account_id
        AND     HCP.site_use_id IS NULL
        AND     HCP.attribute3='Y';


     CURSOR lcu_hz_cust_profile_amts(ln_cust_account_prof_id IN NUMBER)
     IS
        SELECT   HCPA.overall_credit_limit
                ,HCPA.currency_code
        FROM   hz_cust_profile_amts  HCPA
        WHERE  HCPA.cust_account_profile_id = ln_cust_account_prof_id;

     CURSOR lcu_payment_terms (ln_payment_term IN NUMBER)
     IS
        SELECT TERM.name  term_name
        FROM  ra_terms TERM
        WHERE TERM.term_id=ln_payment_term;

     CURSOR lcu_collector_name (ln_collector_id IN NUMBER)
     IS
        SELECT ARC.name   collector_name
        FROM  ar_collectors ARC
        WHERE ARC.collector_id=ln_collector_id;

     CURSOR lcu_profile_class_name (ln_profile_class_id IN NUMBER)
     IS
        SELECT HCPC.name  profile_class_name
        FROM  hz_cust_profile_classes HCPC
        WHERE HCPC.profile_class_id=ln_profile_class_id;
        
    TYPE cust_prof_table
    IS TABLE OF lcu_hz_cust_profile%ROWTYPE
    INDEX BY BINARY_INTEGER;

    lt_cust_prof_tab            cust_prof_table;
    ln_row_chk                  NUMBER:=0;
    ln_credit_lt_cad            NUMBER:=0;
    ln_credit_lt_usd            NUMBER:=0;
    ln_req_id                   NUMBER:=0;
    lc_legacy_credit_flag       VARCHAR2(10);
    lc_legacy_acc_number        xxcrm.XXCRM_CREDIT_FLAG_TEMP.aops_account_number%TYPE;
    lc_legacy_status            xxcrm.XXCRM_CREDIT_FLAG_TEMP.aops_cust_status%TYPE;
    lc_customer_type            VARCHAR2(10);
    lrec_hz_cust_profile_amts   lcu_hz_cust_profile_amts%ROWTYPE;
    lrec_payment_terms          lcu_payment_terms %ROWTYPE;
    lrec_collector_name         lcu_collector_name%ROWTYPE;
    lrec_profile_class_name     lcu_profile_class_name%ROWTYPE;

   BEGIN
   
     OPEN lcu_hz_cust_profile;
     LOOP
         FETCH lcu_hz_cust_profile
         BULK COLLECT
         INTO lt_cust_prof_tab LIMIT 10000;
         EXIT WHEN lt_cust_prof_tab.COUNT=0;

-- ==========================================================================================
-- Fetch profile details for Report such as account number,status,acc name, customer type,
-- credit limit in USD and CAD
-- ==========================================================================================
         FOR i IN lt_cust_prof_tab.FIRST..lt_cust_prof_tab.LAST 
         LOOP
         BEGIN
             --FND_FILE.put_line(FND_FILE.log,'in loop');
             
-- ===============================================================================================
-- Select query to find if any mismatch.Check if there is corresponding row in temp table for the
-- cust account
-- ===============================================================================================
             SELECT COUNT(1)
             INTO    ln_row_chk
             FROM    xxcrm.XXCRM_CREDIT_FLAG_TEMP XCFT
             WHERE   XCFT.aops_account_number = lt_cust_prof_tab(i).aops_acct_number;

-- ===============================================================================================
-- If a row is found, then no mismatch.Update process_status of temp table to 'S'
-- ===============================================================================================
             IF (ln_row_chk=1)
             THEN
                
                UPDATE xxcrm.XXCRM_CREDIT_FLAG_TEMP XCFT
                SET XCFT.process_status = 'S',
                PROCESS_DATE=trunc(SYSDATE)
                WHERE XCFT.AOPs_account_number = lt_cust_prof_tab(i).aops_acct_number;
                FND_FILE.put_line(FND_FILE.log,'Record '||lt_cust_prof_tab(i).aops_acct_number||' updated to Success');
-- ===============================================================================================
-- If no row is found, there is a mismatch.AOPS flag is 'N' and Oracle attr3 is 'Y'.
-- Update process_status of temp table to 'E'
-- ===============================================================================================
             ELSIF (ln_row_chk=0)
             THEN
             FND_FILE.put_line(FND_FILE.log,'Record '||lt_cust_prof_tab(i).aops_acct_number||' inserted in temp table with Error status ');
             x_retmsg := '';
             x_retcode := 1;
-- ===============================================================================================
-- Fetch overall_credit_limit
-- ===============================================================================================
             OPEN lcu_hz_cust_profile_amts(lt_cust_prof_tab(i).cust_account_profile_id);
             LOOP
                FETCH lcu_hz_cust_profile_amts INTO lrec_hz_cust_profile_amts;
                EXIT WHEN lcu_hz_cust_profile_amts%NOTFOUND;
                IF lrec_hz_cust_profile_amts.currency_code='CAD'
                THEN
                 ln_credit_lt_cad:=lrec_hz_cust_profile_amts.overall_credit_limit;
                ELSE
                 ln_credit_lt_usd:=lrec_hz_cust_profile_amts.overall_credit_limit;
                END IF;
             END LOOP;
             CLOSE lcu_hz_cust_profile_amts;
-- ===============================================================================================
-- Fetch payment_term
-- ===============================================================================================
             OPEN lcu_payment_terms(lt_cust_prof_tab(i).standard_terms);
                FETCH lcu_payment_terms INTO lrec_payment_terms;
             CLOSE lcu_payment_terms;
-- ===============================================================================================
-- Fetch collector_name
-- ===============================================================================================
             OPEN lcu_collector_name(lt_cust_prof_tab(i).collector_id);
               FETCH lcu_collector_name INTO lrec_collector_name;
             CLOSE lcu_collector_name;
-- ===============================================================================================
-- Fetch profile_class_name
-- ===============================================================================================
             OPEN lcu_profile_class_name (lt_cust_prof_tab(i).profile_class_id);
               FETCH lcu_profile_class_name INTO lrec_profile_class_name;
             CLOSE lcu_profile_class_name;
-- ===============================================================================================
-- Insert the record in temp table for which AOPS_credit_flag is 'No'
-- ===============================================================================================
             INSERT
             INTO
             xxcrm.XXCRM_CREDIT_FLAG_TEMP(aops_account_number,aops_cust_type,aops_cust_name,aops_cust_status,process_status,attribute1,process_date)
             VALUES (lt_cust_prof_tab(i).aops_acct_number,lt_cust_prof_tab(i).attribute18,lt_cust_prof_tab(i).account_name,lt_cust_prof_tab(i).status,'E','Mismatch Record:CDH-Y,AOPS-N',SYSDATE);
             FND_FILE.put_line(FND_FILE.OUTPUT,lt_cust_prof_tab(i).aops_acct_number||','||
                                               lt_cust_prof_tab(i).status||','||
                                               lt_cust_prof_tab(i).account_number||','||
                                               lt_cust_prof_tab(i).status||','||
                                               '"'||lt_cust_prof_tab(i).account_name||'"'||','||
                                               '"'||lrec_profile_class_name.profile_class_name||'"'||','||
                                               ln_credit_lt_usd||','||
                                               ln_credit_lt_cad||','||
                                               'N'||','||
                                               lt_cust_prof_tab(i).attribute3||','||
                                               '"'||lrec_collector_name.collector_name||'"'||','||
                                               '"'||lrec_payment_terms.term_name||'"'||','||
                                               lt_cust_prof_tab(i).attribute18);
             END IF;
         EXCEPTION
         WHEN OTHERS THEN
           x_retmsg:=('Error in processing the record for : 
                       Oracle Account Number: '||lt_cust_prof_tab(i).account_number||','||'AOPS Account Number: '||lt_cust_prof_tab(i).aops_acct_number||
                      'due to '||SQLCODE||'-'||SQLERRM);
           x_retcode := 1;
           FND_FILE.put_line(FND_FILE.log,x_retmsg);
         END;
         END LOOP; 
         COMMIT;
     END LOOP;
     CLOSE lcu_hz_cust_profile;
   EXCEPTION
   WHEN OTHERS THEN
   x_retmsg := 'Error - Unexpected Error in XX_OD_CREDIT_FLAG_CHK_PKG.XX_OD_CREDIT_FLAG_CHK_PROC '
               || 'SQLCODE - ' || SQLCODE || ' SQLERRM - ' || SQLERRM;
               
   FND_FILE.put_line(FND_FILE.log,x_retmsg);
   x_retcode := 1;
   END XX_OD_CREDIT_FLAG_CHK_PROC;
END XX_OD_CREDIT_FLAG_CHK_PKG;
/

