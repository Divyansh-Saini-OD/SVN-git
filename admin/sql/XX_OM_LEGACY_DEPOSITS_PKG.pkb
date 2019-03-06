CREATE OR REPLACE PACKAGE BODY xx_om_legacy_deposits_pkg
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_POS_RECEIPT_PKG                                                              |
-- |                                                                                            |
-- |  Description:  This package creates a report of transactions that are in error status in   |
-- |                XX_OM_LEGACY_DEPOSITS table                                                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         18-Mar-2016  Shubhashree Rajanna  Initial version                              |
-- +============================================================================================+
AS
   PROCEDURE  create_legacy_deposits_err_rpt (   x_retcode          OUT NOCOPY NUMBER,
                                                 x_errbuf           OUT NOCOPY VARCHAR2,
                                                 p_from_date        IN  VARCHAR2,
                                                 p_to_date          IN  VARCHAR2,
                                                 p_process_code     IN  VARCHAR2,
                                                 p_i1025_status     IN  VARCHAR2,
                                                 p_od_payment_type  IN  VARCHAR2,
                                                 p_single_pay_ind   IN  VARCHAR2,
                                                 p_i1025_message    IN  VARCHAR2)
    IS
       --variables and cursors
       --variables
       ld_from_date          DATE;
       ld_to_date            DATE;
       lc_process_code       VARCHAR2(10)   := null;
       CURSOR legacy_deposits_rpt (l_from_date  IN DATE, l_to_date   IN DATE, l_process_code  IN VARCHAR2, l_i1025_status  IN VARCHAR2,
                                   l_od_payment_type  IN  VARCHAR2, l_single_pay_ind   IN  VARCHAR2, l_i1025_message  IN VARCHAR2)
       IS
          SELECT   orig_sys_document_ref
                  --receipt number
                  ,receipt_date
                  ,payment_type_code
                  ,od_payment_type
                  ,prepaid_amount
                  ,avail_balance
                  ,creation_date
                  ,process_code
                  ,transaction_number
                  ,i1025_status
                  ,i1025_message
                  ,imp_file_name
                  ,single_pay_ind
                  ,error_flag
            FROM  XX_OM_LEGACY_DEPOSITS 
           WHERE  receipt_date  BETWEEN l_from_date and l_to_date
             AND  process_code = DECODE(l_process_code, 'All', process_code, 'P', l_process_code, 'C', l_process_code, process_code)
             AND  i1025_status = DECODE(l_i1025_status, 'All', i1025_status, null, i1025_status, l_i1025_status)
             AND  od_payment_type = DECODE(l_od_payment_type, 'All', od_payment_type, null, od_payment_type, l_od_payment_type)
             AND  single_pay_ind = DECODE(l_single_pay_ind, 'All', single_pay_ind, null, single_pay_ind, l_single_pay_ind)
             AND  NVL(i1025_message, 'A') = DECODE(l_i1025_message, 'All', NVL(i1025_message, 'A'), null, 'A', l_i1025_message)
             AND  error_flag = 'Y'
          ORDER BY receipt_date, od_payment_type;
       --
       TYPE t_error_records_tab IS TABLE OF legacy_deposits_rpt%ROWTYPE
       INDEX BY PLS_INTEGER;
       l_error_records            t_error_records_tab; 
    BEGIN
       --
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<?xml version = "1.0" encoding = "UTF-8"?>');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<MAIN_OUTPUT_TAG>');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<TODAYS_DATE>' ||TO_CHAR(sysdate,'DD-MON-YYYY HH24:MI:SS') || '</TODAYS_DATE>');
       FND_FILE.PUT_LINE(FND_FILE.LOG,'From Date: '||p_from_date||'  sTo Date: '||p_to_date||' Process Code: '||p_process_code);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'I1025 Status: '||p_i1025_status);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Od Payment Type: '||p_od_payment_type);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Single Pay Ind: '||p_single_pay_ind);
       FND_FILE.PUT_LINE(FND_FILE.LOG,'I1025 Message: '||p_i1025_message);
       ld_from_date := TRUNC(NVL(fnd_conc_date.string_to_date(p_from_date), SYSDATE) );
       ld_to_date   := TRUNC(NVL(fnd_conc_date.string_to_date(p_to_date), SYSDATE) );
       FND_FILE.PUT_LINE(FND_FILE.LOG,'After date conversion :'||ld_from_date||', '||ld_to_date);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<P_FROM_DATE>'||ld_from_date||'</P_FROM_DATE>');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<P_TO_DATE>'||ld_to_date||'</P_TO_DATE>');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<P_PROCESS_CODE>'||p_process_code||'</P_PROCESS_CODE>');    
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<P_I1025_STATUS>'||p_i1025_status||'</P_I1025_STATUS>');   
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<P_OD_PAYMENT_TYPE>'||p_i1025_status||'</P_OD_PAYMENT_TYPE>'); 
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<P_SINGLE_PAY_IND>'||p_i1025_status||'</P_SINGLE_PAY_IND>'); 
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<P_I1025_MESSAGE>'||p_i1025_message||'</P_I1025_MESSAGE>'); 
       --Open the cursor and fetch the data
       OPEN legacy_deposits_rpt (l_from_date  =>  ld_from_date, l_to_date  =>  ld_to_date, l_process_code  =>  p_process_code, l_i1025_status  => p_i1025_status,
                                 l_od_payment_type => p_od_payment_type, l_single_pay_ind => p_single_pay_ind, l_i1025_message => p_i1025_message);
       
       FETCH legacy_deposits_rpt
       BULK COLLECT INTO l_error_records;
        
       CLOSE legacy_deposits_rpt;
       
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Records fetched :'||l_error_records.COUNT);
       
       IF (l_error_records.COUNT > 0)
       THEN
          FOR i_index IN l_error_records.FIRST .. l_error_records.LAST
          LOOP
             --
              --FND_FILE.PUT_LINE(FND_FILE.LOG,'In for loop');
              --Get the orig_sys_document_ref into a variable.
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<ERROR_RECORD>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<ORIG_SYS_DOC_REF>'||l_error_records(i_index).orig_sys_document_ref||'</ORIG_SYS_DOC_REF>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<RECEIPT_NUMBER> </RECEIPT_NUMBER>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<RECEIPT_DATE>'||l_error_records(i_index).receipt_date||'</RECEIPT_DATE>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<PAYMENT_TYPE_CODE>'||l_error_records(i_index).payment_type_code||'</PAYMENT_TYPE_CODE>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<OD_PAYMENT_TYPE>'||l_error_records(i_index).od_payment_type||'</OD_PAYMENT_TYPE>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<PREPAID_AMOUNT>'||l_error_records(i_index).prepaid_amount||'</PREPAID_AMOUNT>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<AVAIL_BALANCE>'||l_error_records(i_index).avail_balance||'</AVAIL_BALANCE>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<CREATION_DATE>'||l_error_records(i_index).creation_date||'</CREATION_DATE>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<PROCESS_CODE>'||l_error_records(i_index).process_code||'</PROCESS_CODE>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<TRANSACTION_NUMBER>'||l_error_records(i_index).transaction_number||'</TRANSACTION_NUMBER>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<I1025_STATUS>'||l_error_records(i_index).i1025_status||'</I1025_STATUS>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<I1025_MESSAGE>'||l_error_records(i_index).i1025_message||'</I1025_MESSAGE>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<IMP_FILE_NAME>'||l_error_records(i_index).imp_file_name||'</IMP_FILE_NAME>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'<SINGLE_PAY_IND>'||l_error_records(i_index).single_pay_ind||'</SINGLE_PAY_IND>');
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'</ERROR_RECORD>');
          END LOOP;
       END IF;
       
       
       --write all the data
       --close the loop
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'</MAIN_OUTPUT_TAG>');
       x_retcode := 0;
    EXCEPTION
       WHEN OTHERS THEN
          --
          x_retcode := 2;
          x_errbuf := SQLERRM;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Encountered an exception '||x_errbuf);
    END create_legacy_deposits_err_rpt;
END xx_om_legacy_deposits_pkg;
/

SHOW ERRORS;
