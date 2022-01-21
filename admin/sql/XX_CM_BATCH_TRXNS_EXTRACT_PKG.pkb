SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET DEFINE OFF

PROMPT Creating Package Body XX_CM_BATCH_TRXNS_EXTRACT_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_CM_BATCH_TRXNS_EXTRACT_PKG
AS

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_BATCH_TRXNS_EXTRACT_PKG                               |
-- | RICE ID : R1053                                                     |
-- | Description : This package is to extract the Credit Card settlement |
-- |               transactions as a text file from the batch            |
-- |               transactions history table.                           |
-- |                                                                     |
-- |                                                                     |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A 12-JUL-2008      Aravind A.          Initial version        |
-- |                                              (Created as part of fix|
-- |                                              for defect 8403)       |
-- |                                                                     |
-- +=====================================================================+

gc_rpad_len       NUMBER  DEFAULT 50;

FUNCTION REPEAT_CHAR(
                      p_char  IN VARCHAR2
                      ,p_num  IN NUMBER
                      )
RETURN VARCHAR2
AS
lc_ret_var     VARCHAR2(1000)   DEFAULT NULL;
BEGIN
   FOR i IN 1..p_num
   LOOP
      lc_ret_var := lc_ret_var || p_char;
   END LOOP;
   RETURN lc_ret_var;
EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in REPEAT_CHAR procedure.');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is '||SQLERRM||' and error code is '||SQLCODE);
      RETURN NULL;
END REPEAT_CHAR;

-- +===================================================================+
-- | Name : XX_GET_BATCH_TRXNS_DETAILS                                 |
-- | Description: Extracts the details from batch transactions history |
-- |              table and writes to a flat file.                     |
-- +===================================================================+

PROCEDURE XX_GET_BATCH_TRXNS_DETAILS(
                                     x_err_buff            OUT VARCHAR2
                                    ,x_ret_code            OUT NUMBER
                                    ,p_payment_bat_num     IN  VARCHAR2
                                    )
AS

   CURSOR c_bat_det(
                    p_payment_bat_num  IN VARCHAR2
                    )
   IS
      SELECT ixsettlementdate
            ,ixstorenumber
            ,DECODE(
                    ixregisternumber
                    ,'54'
                    ,'Manual Refunds'
                    ,'55'
                    ,'iRec'
                    ,'99'
                    ,'AOPS'
                    ,'POS'
                    )
            ,ixregisternumber
            ,DECODE(
                    ixregisternumber
                    ,'54'            
                    ,ixinvoice
                    ,'55'            
                    ,ixinvoice          
                    ,'99'            
                    ,ixinvoice          
                    ,ixtransnumber
                    )
            ,ixipaymentbatchnumber
            ,ixamount/100
            ,ixtransactiontype
            ,ixrecptnumber
       FROM  xx_iby_batch_trxns_history
       WHERE ixrecordtype = '101'
        AND  ixipaymentbatchnumber = p_payment_bat_num;

   TYPE bat_det_rec_type IS RECORD(
                                    date_val              xx_iby_batch_trxns_history.ixsettlementdate%TYPE
                                   ,store_num             xx_iby_batch_trxns_history.ixstorenumber%TYPE
                                   ,ord_type              xx_iby_batch_trxns_history.ixregisternumber%TYPE
                                   ,reg_num               xx_iby_batch_trxns_history.ixinvoice%TYPE
                                   ,trx_num               xx_iby_batch_trxns_history.ixinvoice%TYPE
                                   ,batch_num             xx_iby_batch_trxns_history.ixipaymentbatchnumber%TYPE
                                   ,dollar_amt            xx_iby_batch_trxns_history.ixamount%TYPE
                                   ,trx_type              xx_iby_batch_trxns_history.ixtransactiontype%TYPE
                                   ,recpt_num             xx_iby_batch_trxns_history.ixrecptnumber%TYPE
                                  );

   TYPE bat_det_tbl_type IS TABLE OF bat_det_rec_type;

   lt_bat_det_tbl   bat_det_tbl_type;
   lc_file_hdr_ast  VARCHAR2(142);
   lc_file_hdr_nam  VARCHAR2(200);
   lc_file_ftr_nam  VARCHAR2(200);
   lc_file_ftr_ast  VARCHAR2(175);
   lc_col_hdr_ast   VARCHAR2(366);

   BEGIN
      lc_file_hdr_ast := REPEAT_CHAR('*',142);
      lc_col_hdr_ast  := REPEAT_CHAR('*',366);
      lc_file_hdr_nam := 'Credit Card Settlement Transactions Extract for the Payment Batch - '||RPAD(p_payment_bat_num,12,' ');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Started Extract with parameter payment batch number - '||p_payment_bat_num||'.');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_file_hdr_ast||' '||lc_file_hdr_nam||' '||lc_file_hdr_ast);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Settlement Date',gc_rpad_len)||RPAD('Store Number',gc_rpad_len)||RPAD('Order Type',gc_rpad_len)||RPAD('Register Number',gc_rpad_len)||
                        RPAD('Transaction Number',gc_rpad_len)||RPAD('Dollar Amount',gc_rpad_len)||RPAD('Transaction Type',gc_rpad_len)||RPAD('Receipt Number',gc_rpad_len));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_col_hdr_ast);
      
      OPEN c_bat_det(p_payment_bat_num);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Cursor Opened.');
      LOOP
         FETCH c_bat_det 
         BULK COLLECT INTO 
         lt_bat_det_tbl LIMIT 50000;
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Bulk collected into table.');
         
         EXIT WHEN (c_bat_det%ROWCOUNT = 0);
         
         FOR i IN lt_bat_det_tbl.FIRST..lt_bat_det_tbl.LAST
         LOOP
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lt_bat_det_tbl(i).date_val,gc_rpad_len)||RPAD(lt_bat_det_tbl(i).store_num,gc_rpad_len)||RPAD(lt_bat_det_tbl(i).ord_type,gc_rpad_len)||RPAD(lt_bat_det_tbl(i).reg_num,gc_rpad_len)||
                        RPAD(lt_bat_det_tbl(i).trx_num,gc_rpad_len)||RPAD(lt_bat_det_tbl(i).dollar_amt,gc_rpad_len)||RPAD(lt_bat_det_tbl(i).trx_type,gc_rpad_len)||RPAD(lt_bat_det_tbl(i).recpt_num,gc_rpad_len));
      
         END LOOP;
         
         EXIT WHEN c_bat_det%NOTFOUND;
      END LOOP;
      IF ((c_bat_det%ROWCOUNT = 0) AND c_bat_det%NOTFOUND) THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----NO DATA FOUND-----');
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Output File has been created.');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of lines written - '||c_bat_det%ROWCOUNT);
      CLOSE c_bat_det;

      lc_file_ftr_ast := REPEAT_CHAR('*',175);
      lc_file_ftr_nam := 'End of Extract';
      FND_FILE.PUT_LINE(FND_FILE.LOG,'End of Extract.');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_file_ftr_ast||' '||lc_file_ftr_nam||' '||lc_file_ftr_ast);
   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in Extract');
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error is '||SQLERRM||' and error code is '||SQLCODE);
   END XX_GET_BATCH_TRXNS_DETAILS;

END XX_CM_BATCH_TRXNS_EXTRACT_PKG;

/

SHOW ERROR