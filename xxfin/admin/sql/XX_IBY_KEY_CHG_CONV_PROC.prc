SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Procedure XX_IBY_KEY_CHG_CONV_PROC

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PROCEDURE XX_IBY_KEY_CHG_CONV_PROC(
                                                      x_err_buf            OUT    VARCHAR2
                                                     ,x_ret_code           OUT    NUMBER
                                                     ,p_limit_val          IN     NUMBER
                                                     ,p_batch_num_from     IN     VARCHAR2
                                                     ,p_batch_num_to       IN     VARCHAR2
                                                     ,p_generate_log_file  IN     VARCHAR2
                                                     )
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Key label changes conversion                        |
-- | RICE ID     : I0349   settlement                                  |
-- | Description : To populate the XX_IBY_BATCH_TRXNS_HISTORY          |
-- |               with appropriate key labels                         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- | V1.0    09-APR-2010    Aravind A.           Initial version       |
-- +===================================================================+
CURSOR c_101_hist(
                  p_batch_num_from  IN VARCHAR2
                 ,p_batch_num_to    IN VARCHAR2
                 )
IS
SELECT ixrecptnumber
       ,attribute8
       ,ixsettlementdate
       ,DECODE(ixregisternumber
               ,'54',ixaccount
               ,'55',ixaccount
               ,'56',ixaccount
               ,'99',ixaccount
               ,SUBSTR(ixswipe,1,INSTR(ixswipe,'=',-1)-1)) AS enc_cc_num
FROM   xx_iby_batch_trxns_history
WHERE  ixipaymentbatchnumber 
BETWEEN p_batch_num_from AND p_batch_num_to;
 
ln_key_num                    xx_iby_key_changes.key_num%TYPE      DEFAULT NULL;
lc_key_label                  xx_iby_key_changes.key_label%TYPE    DEFAULT NULL;
lc_decrypt_cc_data            VARCHAR2(1000)                       DEFAULT NULL;
lc_decrypt_error_msg          VARCHAR2(4000)                       DEFAULT NULL;
ln_success_count              NUMBER                               DEFAULT 0;
ln_first_fail_count           NUMBER                               DEFAULT 0;
ln_fail_count                 NUMBER                               DEFAULT 0;
lc_upd_rec                    VARCHAR2(1)                          DEFAULT 'N';
lf_suc_file                   UTL_FILE.file_type;
lf_err_file                   UTL_FILE.file_type;
lc_error_loc                  VARCHAR2(4000);
ln_request_id                 NUMBER DEFAULT 0;
lc_settlementdate             VARCHAR2(25);
ln_chunk_size                 BINARY_INTEGER := 32767; 

TYPE hist_rec_type IS RECORD(
                              ixrecptnumber      xx_iby_batch_trxns_history.ixrecptnumber%TYPE
                             ,attribute8         xx_iby_batch_trxns_history.attribute8%TYPE
                             ,ixsettlementdate   xx_iby_batch_trxns_history.ixsettlementdate%TYPE
                             ,enc_cc_num         xx_iby_batch_trxns_history.ixaccount%TYPE
                            );

TYPE xx_iby_batch_trxns_type IS TABLE OF hist_rec_type;
lt_xx_iby_batch_trxns  xx_iby_batch_trxns_type;

BEGIN

   lc_error_loc := 'Opening the UTL FILE : '  ;

   ln_request_id := FND_GLOBAL.CONC_REQUEST_ID;

   IF(p_generate_log_file ='Y') THEN
      lf_suc_file := UTL_FILE.FOPEN('XXFIN_OUTBOUND','XX_IBY_KEY_CHG_CONV_SUCCESS_'||ln_request_id||'.txt','w',ln_chunk_size);
      lf_err_file := UTL_FILE.FOPEN('XXFIN_OUTBOUND','XX_IBY_KEY_CHG_CONV_FALIED_' ||ln_request_id||'.txt','w',ln_chunk_size);
   END IF;

   IF (p_generate_log_file ='Y') THEN

      lc_error_loc :='Printing success records for Request ';

      UTL_FILE.PUT_LINE(lf_suc_file,lc_error_loc||'	'||ln_request_id); 
      UTL_FILE.PUT_LINE(lf_suc_file,'Key Label'||'		'||' Receipt Number '||'		'||'Settlement Date');

      lc_error_loc :='Printing Failure records for Request ';

      UTL_FILE.PUT_LINE(lf_err_file,lc_error_loc||'	'||ln_request_id); 
      UTL_FILE.PUT_LINE(lf_err_file,'Key Label'||'		'||' Receipt Number '||'		'||'Settlement Date');

   END IF;

   lc_error_loc := 'Opening the Cursor ';

   OPEN c_101_hist(p_batch_num_from,p_batch_num_to);
   LOOP

   lc_error_loc := 'Fetching the cursor value using BULK COLLECT ';

   FETCH c_101_hist BULK COLLECT INTO lt_xx_iby_batch_trxns LIMIT p_limit_val;

      FOR i IN lt_xx_iby_batch_trxns.FIRST..lt_xx_iby_batch_trxns.LAST
      LOOP

        lc_key_label         := NULL;
        ln_key_num           := NULL;
        lc_decrypt_cc_data   := NULL;
        lc_decrypt_error_msg := NULL;
        lc_upd_rec           := 'N';

         SELECT key_num
               ,key_label
         INTO   ln_key_num
               ,lc_key_label
         FROM   xx_iby_key_changes
         WHERE  key_rot_date = (SELECT MAX(key_rot_date)
                                FROM   xx_iby_key_changes
                                WHERE  key_rot_date <= lt_xx_iby_batch_trxns(i).ixsettlementdate);

         --Call the decrypt procedure to find if this is the correct label

         lc_error_loc := 'Call the decrypt procedure to find if this is the correct label ';

         XX_OD_SECURITY_KEY_PKG.DECRYPT (
                                          X_DECRYPTED_VAL => lc_decrypt_cc_data
                                         ,X_ERROR_MESSAGE => lc_decrypt_error_msg
                                         ,P_MODULE        => 'AJB'
                                         ,P_KEY_LABEL     => lc_key_label
                                         ,P_ALGORITHM     => '3DES'
                                         ,P_ENCRYPTED_VAL => lt_xx_iby_batch_trxns(i).enc_cc_num
                                         ,P_FORMAT        => 'BASE64'
                                        );

         IF ( (lc_decrypt_error_msg IS NOT NULL) OR (lc_decrypt_cc_data IS NULL)) THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message 1: '||lc_decrypt_error_msg);

         END IF;

         BEGIN

            lc_decrypt_cc_data := TO_NUMBER (lc_decrypt_cc_data);
            lc_upd_rec := 'Y';

         EXCEPTION WHEN VALUE_ERROR THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message VALUE_ERROR:' ||lc_decrypt_error_msg||' - '||SQLERRM);

            ln_key_num := ln_key_num - 1;

            SELECT  key_label
            INTO    lc_key_label
            FROM    xx_iby_key_changes
            WHERE   key_num = ln_key_num;

            XX_OD_SECURITY_KEY_PKG.DECRYPT (
                                             X_DECRYPTED_VAL => lc_decrypt_cc_data
                                            ,X_ERROR_MESSAGE => lc_decrypt_error_msg
                                            ,P_MODULE        => 'ORC'
                                            ,P_KEY_LABEL     => lc_key_label
                                            ,P_ALGORITHM     => '3DES'
                                            ,P_ENCRYPTED_VAL => lt_xx_iby_batch_trxns(i).enc_cc_num
                                            ,P_FORMAT        => 'BASE64'
                                            );

            IF ( (lc_decrypt_error_msg IS NOT NULL) OR (lc_decrypt_cc_data IS NULL)) THEN 

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Message 2 : '||lc_decrypt_error_msg);
               RAISE; 

            END IF;

            BEGIN

               lc_decrypt_cc_data := TO_NUMBER (lc_decrypt_cc_data);
               lc_upd_rec := 'Y';

            EXCEPTION WHEN VALUE_ERROR THEN

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Key Label Could not be received');

              IF (p_generate_log_file ='Y') THEN
                 UTL_FILE.PUT_LINE(lf_err_file,lt_xx_iby_batch_trxns(i).ixrecptnumber);
                 lc_upd_rec := 'N';
              END IF;

            END;

         END;

         IF (lc_upd_rec = 'Y') THEN

            UPDATE xx_iby_batch_trxns_history
            SET    attribute8 = lc_key_label
            WHERE ixrecptnumber = lt_xx_iby_batch_trxns(i).ixrecptnumber;

            ln_success_count :=ln_success_count+1;

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Successful Key Updation for Receipt : '||lt_xx_iby_batch_trxns(i).ixrecptnumber);

            IF(p_generate_log_file ='Y') THEN
               lc_error_loc :='Printing the success Request for';
               UTL_FILE.PUT_LINE(lf_suc_file, lc_key_label||'			'||lt_xx_iby_batch_trxns(i).ixrecptnumber||'			'||lt_xx_iby_batch_trxns(i).ixsettlementdate);
            END IF;

         ELSE 

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Failed Key Updation : '||lt_xx_iby_batch_trxns(i).ixrecptnumber);

            IF(p_generate_log_file ='Y') THEN
               lc_error_loc :='Printing the failure Request for';
               UTL_FILE.PUT_LINE(lf_err_file, lc_key_label||'			'||lt_xx_iby_batch_trxns(i).ixrecptnumber||'			'||lt_xx_iby_batch_trxns(i).ixsettlementdate);
            END IF;

           ln_fail_count:=ln_fail_count+1;

         END IF;

      END LOOP;

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Successful count '||ln_success_count);
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Failed Count '||ln_fail_count);

      COMMIT;

   EXIT WHEN c_101_hist%NOTFOUND;

   END LOOP;

   IF(p_generate_log_file ='Y') THEN

      lc_error_loc :='Close UTL FILE ';
      UTL_FILE.FCLOSE(lf_suc_file);
      UTL_FILE.FCLOSE(lf_err_file);

   END IF;

EXCEPTION
   WHEN OTHERS THEN
   x_ret_code := 2;
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Other Exception at : '||lc_error_loc||' - '||SQLERRM);

END XX_IBY_KEY_CHG_CONV_PROC;

/
SHOW ERROR