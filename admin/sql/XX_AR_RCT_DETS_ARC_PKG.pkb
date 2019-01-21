SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body xx_ar_rct_dets_arc_pkg
PROMPT Program exits if the creation is not successful

create or replace
PACKAGE BODY XX_AR_RCT_DETS_ARC_PKG AS
-- +===================================================================================+
-- |                    Oracle Consulting                                              |
-- +===================================================================================+
-- | Name       : XXARORDRCTDTLPKS.pls                                                 |
-- | Description: Order Receipt Details Archiving Program                              |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record                                                                      |
-- |==============                                                                     |
-- |Version   Date         Authors              Remarks                                |
-- |========  ===========  ===============      ============================           |
-- |Draft 1A  20-Apr-2011  Sreenivasa Tirumala  Intial Draft Version                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- +===================================================================================+

-- -------------------------------------------
-- Global Variables
-- ----------------------------------------------
   gn_error                   NUMBER         := 2;
   gn_warning                 NUMBER         := 1;
   gn_normal                  NUMBER         := 0;
   gd_start_date              DATE;
   gd_end_date                DATE;
   g_print_line               VARCHAR2 (125)
      := '------------------------------------------------------------------------------------------------------------------------';

PROCEDURE lp_print (lp_line IN VARCHAR2, lp_both IN VARCHAR2)
IS
BEGIN
    IF fnd_global.conc_request_id () > 0
    THEN
     CASE
        WHEN UPPER (lp_both) = 'BOTH'
        THEN
           fnd_file.put_line (fnd_file.LOG, lp_line);
           fnd_file.put_line (fnd_file.output, lp_line);
        WHEN UPPER (lp_both) = 'LOG'
        THEN
           fnd_file.put_line (fnd_file.LOG, lp_line);
        ELSE
           fnd_file.put_line (fnd_file.output, lp_line);
     END CASE;
    ELSE
     DBMS_OUTPUT.put_line (lp_line);
    END IF;
END;  

-- +=================================================================================+
-- | Name        : PRINT_MESSAGE_HEADER                                              |
-- | Description : This procedure will be used to print the                          |
-- |               record process details                                            |
-- |                                                                                 |
-- | Parameters  : None                                                              |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
   PROCEDURE print_message_header (
      x_errbuf    OUT NOCOPY   VARCHAR2
    , x_retcode   OUT NOCOPY   NUMBER
   )
   IS
   BEGIN
-- ------------------------------------------------
-- Set the Concurrent program Output header display
-- ------------------------------------------------
      lp_print(g_print_line,'BOTH');
      lp_print(LPAD (' ', 31, ' ')||'Archiving Cleared Transactions','BOTH');
      lp_print(g_print_line,'BOTH');
      
      -- Log Messages
      lp_print('Processing cleared transactions for Receipt Dates ('||NVL(gd_start_date,SYSDATE-720)||' through '||NVL(gd_end_date,SYSDATE)||') (Review Log for Error details)','LOG');
      lp_print(  RPAD ('Order Payment ID', 18, ' ')
              || ' '
              || RPAD ('Type', 10, ' ')
              || ' '
              || RPAD ('Customer Receipt Reference#', 30, ' ')
              || ' '
              || LPAD ('Trx Amt', 14, ' ')
              || ' '
              || RPAD ('Status', 20, ' '),'LOG');
      lp_print(  RPAD ('-', 18, '-')
              || ' '
              || RPAD ('-', 10, '-')
              || ' '
              || RPAD ('-', 30, '-')
              || ' '
              || LPAD ('-', 14, '-')
              || ' '
              || RPAD ('-', 20, '-'),'LOG');
      
      -- Output Messages
      
   EXCEPTION
      WHEN OTHERS
      THEN
         x_errbuf := SUBSTR(SQLERRM,1,250);
         x_retcode := gn_error;
         fnd_file.put_line (fnd_file.LOG, '==========================');
         fnd_file.put_line (fnd_file.LOG, x_errbuf);
   END print_message_header;

-- +=================================================================================+
-- | Name        : ARCHIVING_PROC                                                    |
-- | Description : This procedure will be used to Archive the Order Receipt Details  |
-- |               records based on the Start and End date provided                  |
-- |                                                                                 |
-- | Parameters  : p_date_from                                                       |
-- |               p_date_to                                                         |
-- |                                                                                 |
-- | Returns     : x_errbuf                                                          |
-- |               x_retcode                                                         |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE archiving_proc ( x_errbuf    OUT NOCOPY   VARCHAR2
                         , x_retcode   OUT NOCOPY   NUMBER
                         , p_date_from        VARCHAR2
                         , p_date_to          VARCHAR2
                         , p_no_of_days       NUMBER DEFAULT 720) IS

-- Cursor Which gets all those records which fall in between from and to date and 
-- checks if the records are already cleared in 996 and 998 tables.
CURSOR lcu_archive_ord_dtls(lp_from_date     DATE
                           ,lp_to_date       DATE)
IS
SELECT xao.*
FROM   xx_ar_order_receipt_dtl xao
WHERE xao.receipt_status = 'CLEARED'
AND   xao.receipt_date BETWEEN NVL(lp_from_date,SYSDATE-p_no_of_days) AND NVL(lp_to_date,SYSDATE)
ORDER BY xao.receipt_date;


CURSOR lcu_998_check(p_order_payment_id NUMBER)
IS
SELECT NVL(status_1295,'N')
FROM   xx_ce_ajb998 x998
WHERE x998.order_payment_id = p_order_payment_id;

CURSOR lcu_996_check(p_order_payment_id NUMBER)
IS
SELECT attribute2
FROM   xx_ce_ajb996 x996
WHERE x996.order_payment_id = p_order_payment_id;

lc_errmsg       VARCHAR2(500);
ln_retcode      NUMBER;
ln_rows         NUMBER              := 2000;
lc_purge_status   VARCHAR2(500);
lc_insert_status  VARCHAR2(500);
ld_from_date      DATE;
ld_to_date        DATE;
lc_error_flag     CHAR(1);       
lc_998_status     CHAR(1);
lc_996_status     CHAR(1);
lc_error_msg1     VARCHAR2(100):= NULL;
lc_error_msg2     VARCHAR2(100):= NULL;
ln_succ_rec_count NUMBER := 0;
ln_succ_amount    NUMBER := 0;  
ln_err_rec_count  NUMBER := 0;
ln_err_amount     NUMBER := 0;
lc_rct_rec_cnt          NUMBER := 0;  
lc_rct_rec_amount       NUMBER := 0;
lc_rct_rec_cnt_err      NUMBER := 0;
lc_rct_rec_amount_err   NUMBER := 0;
ld_receipt_date         DATE   := NULL;

BEGIN
    IF p_date_from IS NOT NULL
    THEN
        gd_start_date := TRUNC (fnd_conc_date.string_to_date (p_date_from));
    END IF;
    
    IF p_date_to IS NOT NULL
    THEN
        gd_end_date := TRUNC (fnd_conc_date.string_to_date (p_date_to));
    END IF;
    -- Printing the header part
    --Looping of the Cursor
    
    print_message_header (x_errbuf => lc_errmsg, x_retcode => ln_retcode);

    FOR rec_archive_ord_dtls IN lcu_archive_ord_dtls(gd_start_date,gd_end_date)
    LOOP
        lc_error_flag := 'N';
        lc_998_status := NULL;
        lc_996_status := NULL;
        lc_error_msg1 := NULL;
        lc_error_msg2 := NULL;
        
        IF (rec_archive_ord_dtls.payment_type_code in ('DEBIT_CARD','TELECHECK','CREDIT_CARD')) THEN
            -- Validate the Records for the 998 Table Status
            OPEN lcu_998_check(rec_archive_ord_dtls.order_payment_id);
            FETCH lcu_998_check INTO lc_998_status;
                IF (lcu_998_check%FOUND) THEN
                    IF lc_998_status = 'N' THEN
                        lc_error_flag := 'Y';
                        x_retcode := gn_warning;
                        lc_error_msg1 := 'Record Found and not Cleared in 998 Table/';
                    END IF;
                END IF;
            CLOSE lcu_998_check;    

            -- Validate the Records for the 996 Table Status
            OPEN lcu_996_check(rec_archive_ord_dtls.order_payment_id);
            FETCH lcu_996_check INTO lc_996_status;
                IF (lcu_996_check%FOUND) THEN
                    IF lc_996_status <> 'CB_YES' THEN
                        lc_error_flag := 'Y';
                        x_retcode := gn_warning;
                        lc_error_msg2 := 'Record Found and not Cleared in 996 Table/';
                    END IF;
                END IF;
            CLOSE lcu_996_check;              

        END IF;
        -- Based on the Status decide on the Insertion and Deletion of record into 
        -- xx_ar_order_receipt_dtl_arc and xx_ar_order_receipt_dtl respectively.
        IF lc_error_flag = 'N' THEN
            BEGIN    
                INSERT INTO xx_ar_order_receipt_dtl_arc
                    SELECT * FROM xx_ar_order_receipt_dtl 
                    WHERE order_payment_id = rec_archive_ord_dtls.order_payment_id;
                lc_insert_status := 'Archived';   
            EXCEPTION
                WHEN OTHERS THEN
                    lp_print ('Exception Raised while Inserting the Record with Order payment Id:'
                              ||rec_archive_ord_dtls.order_payment_id, 'LOG');
                    lc_insert_status := 'Error-Not Archived'||sqlerrm;     
                    lc_error_flag := 'Y';
                    x_retcode := gn_warning;
                    --test_debug_insert(8,'iN eXCEPTION');
            END;

            BEGIN
                DELETE FROM xx_ar_order_receipt_dtl 
                WHERE  order_payment_id = rec_archive_ord_dtls.order_payment_id;
                lc_purge_status := 'Purged';
            EXCEPTION
                WHEN OTHERS THEN
                    lp_print ('Exception Raised while Purging the Record with Order payment Id:'
                              ||rec_archive_ord_dtls.order_payment_id, 'LOG');
                    lc_purge_status := 'Error-Not Purged:'||sqlerrm;  
                    lc_error_flag := 'Y';
                    x_retcode := gn_warning;
            END;            
        END IF;

        -- Record Count Logic/Amount 
            -- If Successfully Archived then Success Count/Amount
        IF lc_error_flag = 'N' THEN
            ln_succ_rec_count := ln_succ_rec_count+1;
            ln_succ_amount    := ln_succ_amount + NVL(rec_archive_ord_dtls.payment_amount,0);
        ELSE-- Else Error Count/Error Amount
            ln_err_rec_count := ln_err_rec_count+1;
            ln_err_amount    := ln_err_amount + NVL(rec_archive_ord_dtls.payment_amount,0);
        END IF;

        -- For Display of Output, Date Wise Record Count/Amount should be calculated and displayed          
            -- Check for the Date
                -- If New date assign it to the Variable
                    -- Check if the new date is same as variable
                        -- IF Same
                            -- Calculate the Amount/Record Count based on the Success/Error
                        -- IF it is Different
                            -- Assign variable with this new date
                            -- Display the previous Record Count/Amount to the Output.
                            -- assign the Record Count/Amount with the new data received.

        IF ld_receipt_date IS NULL
        THEN
            ld_receipt_date := rec_archive_ord_dtls.receipt_date;
            IF lc_error_flag = 'N' THEN
                lc_rct_rec_cnt := 1;
                lc_rct_rec_amount := NVL(rec_archive_ord_dtls.payment_amount,0);
            ELSE
                lc_rct_rec_cnt_err := 1;
                lc_rct_rec_amount_err := NVL(rec_archive_ord_dtls.payment_amount,0);
            END IF;
        ELSIF ld_receipt_date = rec_archive_ord_dtls.receipt_date
        THEN
            IF lc_error_flag = 'N' THEN
                lc_rct_rec_cnt := lc_rct_rec_cnt+1;
                lc_rct_rec_amount := lc_rct_rec_amount+NVL(rec_archive_ord_dtls.payment_amount,0);
            ELSE
                lc_rct_rec_cnt_err := lc_rct_rec_cnt_err+1;
                lc_rct_rec_amount_err := lc_rct_rec_amount_err+NVL(rec_archive_ord_dtls.payment_amount,0);
            END IF;            
        ELSE
            lp_print('Receipt Date: '||TO_CHAR(rec_archive_ord_dtls.receipt_date,'DD-MON-YY'),'OUTPUT');
            lp_print(LPAD('Count',45,' ')
                    ||' '
                    ||LPAD('AR Amount',24,' '),'OUTPUT');
            lp_print( LPAD(' ',30,' ')
                    ||LPAD('-',15,'-')
                    ||'          '
                    ||LPAD('-',15,'-'),'OUTPUT');            
            lp_print( LPAD('Successfully Processed:',30,' ')
                    ||LPAD(lc_rct_rec_cnt,15,' ')
                    ||'          '
                    ||LPAD(lc_rct_rec_amount,15,' '),'OUTPUT');  
            lp_print( LPAD('Error Processing::',30,' ')
                    ||LPAD(lc_rct_rec_cnt_err,15,' ')
                    ||'          '
                    ||LPAD(lc_rct_rec_amount_err,15,' '),'OUTPUT');             
            --lp_print(g_print_line,'OUTPUT');            
            ld_receipt_date := rec_archive_ord_dtls.receipt_date;
            IF lc_error_flag = 'N' THEN
                lc_rct_rec_cnt := 1;
                lc_rct_rec_amount := NVL(rec_archive_ord_dtls.payment_amount,0);
            ELSE
                lc_rct_rec_cnt_err := 1;
                lc_rct_rec_amount_err := NVL(rec_archive_ord_dtls.payment_amount,0);
            END IF;
        END IF;

        -- After successful completion of the above operations, decide on the status and display the records 
        lp_print(  RPAD (rec_archive_ord_dtls.order_payment_id, 18, ' ')
              || ' '
              || RPAD (rec_archive_ord_dtls.payment_type_code, 10, ' ')
              || ' '
              || RPAD (rec_archive_ord_dtls.customer_receipt_reference, 30, ' ')
              || ' '
              || LPAD (NVL(rec_archive_ord_dtls.payment_amount,0), 14, ' ')
              || ' '
              || RPAD (rec_archive_ord_dtls.receipt_status, 18, ' '),'LOG');   
    END LOOP;
    COMMIT;
    lp_print(' ','BOTH');
    lp_print(g_print_line,'BOTH');
    
    -- Display in the log for the statistics on Records processed successfully
    lp_print(LPAD('Count',45,' ')
            ||' '
            ||LPAD('AR Amount',24,' '),'LOG');
    lp_print( LPAD(' ',30,' ')
            ||LPAD('-',15,'-')
            ||'          '
            ||LPAD('-',15,'-'),'LOG');            
    lp_print( LPAD('Successfully Processed:',30,' ')
            ||LPAD(ln_succ_rec_count,15,' ')
            ||'          '
            ||LPAD(ln_succ_amount,15,' '),'LOG');  
    lp_print( LPAD('Error Processing::',30,' ')
            ||LPAD(ln_err_rec_count,15,' ')
            ||'          '
            ||LPAD(ln_err_amount,15,' '),'LOG');             
    lp_print(g_print_line,'LOG');
    
EXCEPTION
    WHEN OTHERS THEN
        x_retcode := gn_error;
        x_errbuf  := SQLERRM;
        lp_print(g_print_line,'LOG');
        lp_print('In Exception'||x_errbuf,'LOG');

END archiving_proc;
END XX_AR_RCT_DETS_ARC_PKG;
/
show errors;

exit;