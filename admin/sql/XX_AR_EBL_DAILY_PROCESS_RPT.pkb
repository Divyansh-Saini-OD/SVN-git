CREATE OR REPLACE PACKAGE BODY xx_ar_ebl_daily_process_rpt
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_DAILY_PROCESS_RPT                                         |
-- | Description : This Package will be executable code for the Daily processing report|
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2010  Ranjith Thnangasamy     Initial draft version               |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : DATA_EXTRACT                                                        |
-- | Description : This Procedure is used to generate the daile processing report      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2010  Ranjith Thnangasamy     Initial draft version               |
-- |1.1       16-SEP-2010  Ranjith Thnangasamy     Changes for defect 7924             |
-- |2.0       25-JAN-2013  KirubhaSamuel           Changes were made for defect #21679 |
-- |                                                1.Procedure DATA_EXTRACT has been  |
-- |                                                 commented out                     |
-- |                                                2.Procedure DATA_REPORT has been,  |
-- |                                                 has been created                  |
-- |                                                3.P_AS_OF_DATE,P_STATUShas been    |
-- |                                                  declared as global variables     |
-- |                                                                                   |
-- |3.0       02-OCT-2013  Edson Morales            Retrofitted for R12                |
-- +===================================================================================+
    p_as_of_date  VARCHAR2(30) := NULL;
    p_status      VARCHAR2(30) := NULL;

    /* Procedure DATA_EXTRACT (P_AS_OF_DATE VARCHAR2,
                             P_STATUS VARCHAR2
                             p_file_path VARCHAR2,
                             p_file_name VARCHAR2,
                             p_delimiter VARCHAR2,
                    --         p_ftp        VARCHAR2,  commented for defect 7924
                             p_copy_files   VARCHAR2,  --added for defect 7924
                    --         p_processname VARCHAR2,   commented for defect 7924
                             p_dest_path     VARCHAR2, --added for defect 7924
                             p_dest_file_name VARCHAR2,
                             p_delete_source_file VARCHAR2*
                            )
     AS
          CURSOR file_error_details(p_cycle_date DATE)
           IS
           select  xaef.account_number
                  ,xaef.aops_customer_number
                  ,xaef.cust_doc_id
                  ,xaet.status trans_status
                  ,translate(SUBSTR(xaet.status_detail,1,1200),chr(13)||chr(10)||'|','   ') trans_status_Detail  -- added for defect 7924
                  ,xaef.status status
                  ,translate(SUBSTR(xaef.status_detail,1,1200),chr(13)||chr(10)||'|','   ') status_detail   -- added substring for defect 7924
                  ,xaef.billing_associate_name
                  ,xaef.file_name  file_name
           from xx_ar_ebl_transmission xaet
               ,xx_ar_ebl_file xaef
           WHERE xaet.transmission_id(+) = xaef.transmission_id
           AND  xaef.file_type IN ('PDF','XLS','TXT')
           AND (p_status = 'BOTH'
                 OR (p_status = 'SUCCESS' AND xaet.status IN ('SENT','ARCHIVED'))
                 OR (p_status = 'ERROR' AND NVL(xaet.status,'X') NOT IN ('SENT','ARCHIVED'))
               )
           AND xaef.billing_dt = p_cycle_date
           AND xaef.org_id = fnd_profile.VALUE('ORG_ID')
           AND xaef.file_name NOT LIKE '%REMIT%'
           UNION ALL
           select DISTINCT chdr.oracle_account_number oracle_customer_number
                  ,chdr.aops_account_number   aopscustomer_number
                  ,chdr.parent_cust_doc_id    cust_doc_id
                  ,NULL trans_Status
                  ,NULL trans_status_Detail  -- added for defect 7924
                  ,DECODE(chdr.status,'NEW','FILE NOT PROCESSED - CHECK CDH SETUP'
                                     ,chdr.status) status
                  ,NULL status_detail
                  ,NULL billing_associate_name
                  ,chdr.file_name file_name
           FROM xx_ar_ebl_cons_hdr_main CHDR
           WHERE p_status IN ('ERROR','BOTH')
           AND chdr.status = 'NEW'
           and chdr.org_id = fnd_profile.VALUE('ORG_ID')
           UNION ALL
           select DISTINCT IHDR.oracle_account_number oracle_customer_number
                  ,IHDR.aops_account_number   aopscustomer_number
                  ,IHDR.parent_cust_doc_id    cust_doc_id
                  ,NULL trans_Status
                  ,NULL trans_status_Detail   -- added for defect 7924
                  ,DECODE(IHDR.status,'NEW','FILE NOT PROCESSED - CHECK CDH SETUP'
                                                     ,IHDR.status) status
                  ,NULL status_detail
                  ,NULL billing_associate_name
                  ,ihdr.file_name file_name
           FROM xx_ar_ebl_ind_hdr_main IHDR
           WHERE p_status IN ('ERROR','BOTH')
           AND IHDR.status = 'NEW'
           AND IHDR.org_id = fnd_profile.VALUE('ORG_ID');

           CURSOR trx_error_details(p_cycle_date date)
           IS
           select  xaeb.oracle_customer_number
                  ,xaeb.aopscustomer_number
                  ,xaeb.cust_doc_id
                  ,xaeb.error_message
                  ,xaeb.cons_bill_number
                  ,xaeb.trx_number
                  ,DECODE(xaeb.document_type,'Y','Paydoc'
                                            ,'N','Infocopy') doc_type
           from XX_AR_EBL_ERROR_BILLS xaeb
           WHERE TRUNC(xaeb.as_of_date) = p_cycle_date
           AND xaeb.org_id = fnd_profile.VALUE('ORG_ID');


    ld_as_of_date DATE:= trunc (fnd_conc_date.string_to_date (p_as_of_date));
     /*lc_file_handle                UTL_FILE.file_type;
    lc_path  VARCHAR2(1000);
    --ln_request_id NUMBER;
    lc_phase     VARCHAR2(1000);
    lc_status    VARCHAR2(1000);
    lc_dev_phase  VARCHAR2(1000);
    lc_dev_status VARCHAR2(1000);
    lc_message    VARCHAR2(1000);
    lb_wait       BOOLEAN;
    lc_file_status    VARCHAR2(1000);
    lc_trans_status   VARCHAR2(1000);
    lc_error_location VARCHAR2(1000);


    BEGIN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'As of Date : '||ld_as_of_date);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Status : '||p_status);
       /*FND_FILE.PUT_LINE(FND_FILE.LOG,'File Path Directory: '|| p_file_path);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'File Name : '|| p_file_name);

      BEGIN
      SELECT directory_path
      INTO lc_path
      FROM dba_directories
      where directory_name = p_file_path;
      EXCEPTION
       WHEN OTHERS THEN
        lc_path:=NULL;
      END;


      FND_FILE.PUT_LINE(FND_FILE.LOG,'Writing to File : '||lc_path||'/'||p_file_name);
      lc_file_handle := UTL_FILE.fopen (p_file_path, p_file_name, 'W', 32767); */ -- Commented for defect 21679

    /*UTL_FILE.put_line(lc_file_handle, 'H'||p_delimiter
                                          ||'Oracle Account Number'||p_delimiter
                                          ||'AOPS Account NUMBER'||p_delimiter
                                          ||'Customer Document ID'||p_delimiter
                                          ||'File Status'||p_delimiter
                                          ||'Reason for Failure'||p_delimiter
                                          ||'Transmission Status'||p_delimiter
                                          ||'Transmission Status Detail'||p_delimiter  -- added for defect 7924
                                          ||'Billing Associate'||p_delimiter
                                          ||'File Name'||p_delimiter
                                          ||'File Location');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Writing Header Records');

       FOR file_rec IN file_error_details(ld_as_of_date)
         LOOP
          SELECT DECODE(file_rec.status,     'RENDER','FILE YET TO BE RENDERED'
                                            ,'MANIP_READY','eXLS FILE MANIPULATION PENDING'
                                            ,'RENDERED','FILE HAS BEEN RENDERED'
                                            ,'FILE INSERT FAILED','FILE INSERTION FAILED'
                                            ,'DATAEXTRACT_FAILED','DATA EXTRACT FAILED'
                                            ,'RENDER_ERROR','ERROR DURING RENDERING'
                                            ,'MANIP_ERROR','DATA MANIPULATION ERROR'
                                            ,file_rec.status
                               )
          INTO lc_file_status
          FROM DUAL;

          SELECT DECODE(file_rec.trans_status,'STAGED','FILE STAGED FOR TRANSMISSION'
                                              ,'SEND','FILE NOT YET TRANSMITTED'
                                              ,'ERROR','ERROR, NOT TRANSMITTED'
                                              ,'SENT','FILE TRANSMITTED SUCCESFULLY'
                                              ,'TOOBIG','FILE TOO BIG TO BE TRANSMITTED'
                                              ,'SENTBYCD','FILE SENT BY CD'
                                              ,file_rec.trans_status
                               )
          INTO lc_trans_status
          FROM DUAL;

           /*UTL_FILE.put_line(lc_file_handle,'H'||p_delimiter
                                             ||file_rec.account_number||p_delimiter
                                             ||file_rec.aops_customer_number||p_delimiter
                                             ||file_rec.cust_doc_id||p_delimiter
                                             ||lc_file_status||p_delimiter
                                             ||file_rec.status_detail||p_delimiter
                                             ||lc_trans_status||p_delimiter
                                             ||file_rec.trans_status_Detail||p_delimiter -- added for defect 7924
                                             ||file_rec.billing_associate_name||p_delimiter
                                             ||file_rec.file_name||p_delimiter
                                             );
    fnd_file.put_line(fnd_file.log,'inserting '||file_rec.account_number);
    Insert into xxfin.XX_EBILL_DAILY_REPORT_HEADER values(file_rec.account_number,file_rec.aops_customer_number,file_rec.cust_doc_id,
    lc_trans_status,file_rec.trans_status_Detail,lc_file_status,file_rec.status_detail,file_rec.billing_associate_name,file_rec.file_name,ld_as_of_date);
     END LOOP;
        IF (p_status <> 'SUCCESS') THEN
        /*UTL_FILE.put_line(lc_file_handle,'');
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Writing Detail Column Labels');
        UTL_FILE.put_line(lc_file_handle, 'D'||p_delimiter
                                          ||'Oracle Account Number'||p_delimiter
                                          ||'AOPS Account NUMBER'||p_delimiter
                                          ||'Customer Document ID'||p_delimiter
                                          ||'Transaction Number'||p_delimiter
                                          ||'Consolidated Number'||p_delimiter
                                          ||'Document Type'||p_delimiter
                                          ||'Status'||p_delimiter
                                          ||'Error Message'
                                          );



         FOR trx_rec IN trx_error_details(ld_as_of_date)
          LOOP
           /*UTL_FILE.put_line(lc_file_handle,'D'||p_delimiter
                                             ||trx_rec.oracle_customer_number||p_delimiter
                                             ||trx_rec.aopscustomer_number||p_delimiter
                                             ||trx_rec.cust_doc_id||p_delimiter
                                             ||trx_rec.trx_number||p_delimiter
                                             ||trx_rec.cons_bill_number||p_delimiter
                                             ||trx_rec.doc_type||p_delimiter
                                             ||'ERROR'||p_delimiter
                                             ||trx_rec.error_message
                                             );


    fnd_file.put_line(fnd_file.log,'error  '||trx_rec.oracle_customer_number);
          Insert into xxfin.XX_EBILL_DAILY_REPORT_DETAIL values(trx_rec.oracle_customer_number,trx_rec.aopscustomer_number,trx_rec.cust_doc_id,trx_rec.error_message,trx_rec.cons_bill_number,
      trx_rec.trx_number,trx_rec.doc_type,'ERROR',ld_as_of_date);

       END LOOP;
        END IF;
    --UTL_FILE.fclose (lc_file_handle);-- Commented for defect 21679
    --Commented for defect 7924
       /*IF (p_ftp = 'Y') THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling FTP program');
                     ln_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                                                 ,'XXCOMFTP'
                                                                 ,NULL
                                                                 ,NULL
                                                                 ,FALSE
                                                                 ,p_processname
                                                                 ,p_file_name
                                                                 ,p_dest_file_name
                                                                 ,p_delete_source_file
                                                                 );
                     COMMIT;
                               lb_wait := fnd_concurrent.wait_for_request ( ln_request_id
                                                                 ,10
                                                                 ,NULL
                                                                 ,lc_phase
                                                                 ,lc_status
                                                                 ,lc_dev_phase
                                                                 ,lc_dev_status
                                                                 ,lc_message
                                                                 );

       END IF;
    */
       /*IF (p_copy_files = 'Y') THEN  -- changes for defect 7924 starts
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling FTP program');
                     ln_request_id := FND_REQUEST.SUBMIT_REQUEST ('XXFIN'
                                                                 ,'XXCOMFILCOPY'
                                                                 ,NULL
                                                                 ,NULL
                                                                 ,FALSE
                                                                 ,lc_path||'/'||p_file_name
                                                                 ,p_dest_path||'/'||p_file_name
                                                                 );
                     COMMIT;
                               lb_wait := fnd_concurrent.wait_for_request ( ln_request_id
                                                                 ,10
                                                                 ,NULL
                                                                 ,lc_phase
                                                                 ,lc_status
                                                                 ,lc_dev_phase
                                                                 ,lc_dev_status
                                                                 ,lc_message
                                                                 );

       END IF;
    commit;


     END;-- changes for defect 7924 ends*/ --commenetd for defect#21679
    PROCEDURE data_report(
        x_errbuff     OUT  VARCHAR2,
        x_retcode     OUT  NUMBER,
        p_as_of_date       VARCHAR2,
        p_status           VARCHAR2)
    IS
        ln_request_id  NUMBER;
        lb_wait        BOOLEAN;
        lb_layout      BOOLEAN;
        lc_dev_phase   VARCHAR2(1000);
        lc_dev_status  VARCHAR2(1000);
        lc_message     VARCHAR2(1000);
        lc_status      VARCHAR2(1000);
        lb_printer     BOOLEAN;
        lc_phase       VARCHAR2(1000);
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          'Submitting the JAVA Concurrent program to create the Report');
        lb_printer := fnd_request.add_printer('XPTR',
                                              1);
        lb_layout := fnd_request.add_layout('XXFIN',
                                            'XX_AR_EBL_DAILY_PROCESS_RPT_T',
                                            'en',
                                            'US',
                                            'EXCEL');
        ln_request_id :=
            fnd_request.submit_request('XXFIN',
                                       'XX_AR_EBL_DAILY_PROCESS_RPT',
                                       NULL,
                                       NULL,
                                       FALSE,
                                       p_status,
                                       p_as_of_date);
        COMMIT;
        lb_wait :=
            fnd_concurrent.wait_for_request(ln_request_id,
                                            10,
                                            NULL,
                                            lc_phase,
                                            lc_status,
                                            lc_dev_phase,
                                            lc_dev_status,
                                            lc_message);

        IF lc_dev_status = 'WARNING' OR lc_dev_status = 'ERROR'
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Child program completed in Warning or error, Request ID:'
                              || ln_request_id);
            x_retcode := 2;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'Exception raised when Submitting the Report :'
                              || SQLERRM);
            RAISE;
    END;
END;
/