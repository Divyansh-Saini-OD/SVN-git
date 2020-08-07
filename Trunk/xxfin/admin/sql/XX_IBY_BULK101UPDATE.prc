SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PROCEDURE XX_AR_TRX_POST_CONV_UPDATE

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

   CREATE OR REPLACE PROCEDURE XX_BULK101UPDATE
   AS

-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | RICE ID     :  I0349                                                               |
-- | Name        :  Settlement and Payment Processing                                   |
-- |                                                                                    |
-- | SQL Script to update attribute7 in the the following object                        |
-- |             Table       : XX_IBY_BATCH_TRXNS_HISTORY                               |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date          Author              Remarks                                 |
-- |=======   ==========   =============        ========================================|
-- |1.0       23-FEB-2009  Anitha Devarajulu    Initial Version for Defect 11482        |
-- +====================================================================================+

      CURSOR c_data_from_201
      IS
      (
       SELECT ixreceiptnumber
              ,attribute7
              ,process_indicator
       FROM   xx_iby_batch_trxns_201_history
       GROUP BY ixreceiptnumber,attribute7,process_indicator
      );

      CURSOR c_attr_from_101
      IS
      (
       SELECT attribute28
              ,attribute29
              ,attribute30
              ,ixreceiptnumber
       FROM   xx_iby_batch_trxns_history
      );

      TYPE rcp_number_tbl_type IS TABLE OF xx_iby_batch_trxns_201_history.ixreceiptnumber%TYPE;
      TYPE attr7_tbl_type IS TABLE OF xx_iby_batch_trxns_201_history.attribute7%TYPE;
      TYPE proc_ind_tbl_type IS TABLE OF xx_iby_batch_trxns_201_history.process_indicator%TYPE;
      TYPE attr28_tbl_type IS TABLE OF xx_iby_batch_trxns_history.attribute28%TYPE;
      TYPE attr29_tbl_type IS TABLE OF xx_iby_batch_trxns_history.attribute29%TYPE;
      TYPE attr30_tbl_type IS TABLE OF xx_iby_batch_trxns_history.attribute30%TYPE;
      TYPE rcp_numb_tbl_type IS TABLE OF xx_iby_batch_trxns_history.ixreceiptnumber%TYPE;

      lt_rcp_number_tbl_type   rcp_number_tbl_type;
      lt_attr7_tbl_type        attr7_tbl_type;
      lt_proc_ind_tbl_type     proc_ind_tbl_type;
      lt_attr28_tbl_type       attr28_tbl_type;
      lt_attr29_tbl_type       attr29_tbl_type;
      lt_attr30_tbl_type       attr30_tbl_type;
      lt_rcp_numb_tbl_type     rcp_numb_tbl_type;

   BEGIN

      OPEN c_data_from_201;
      LOOP

            FETCH c_data_from_201 BULK COLLECT INTO lt_rcp_number_tbl_type,lt_attr7_tbl_type,lt_proc_ind_tbl_type;
            FORALL i IN lt_rcp_number_tbl_type.FIRST..lt_rcp_number_tbl_type.LAST

               UPDATE xx_iby_batch_trxns_history XIBT
               SET    XIBT.attribute7          = lt_attr7_tbl_type(i)
                      ,XIBT.process_indicator  = lt_proc_ind_tbl_type(i)
               WHERE  XIBT.ixreceiptnumber     = lt_rcp_number_tbl_type(i);

               EXIT WHEN c_data_from_201%NOTFOUND;

      END LOOP;
      CLOSE c_data_from_201;

      OPEN c_attr_from_101;
      LOOP

            FETCH c_attr_from_101 BULK COLLECT INTO lt_attr28_tbl_type,lt_attr29_tbl_type,lt_attr30_tbl_type,lt_rcp_numb_tbl_type;
            FORALL i IN lt_rcp_numb_tbl_type.FIRST..lt_rcp_numb_tbl_type.LAST

               UPDATE xx_iby_batch_trxns_history XIBT
               SET    XIBT.is_deposit        = lt_attr28_tbl_type(i)
                      ,XIBT.is_custom_refund = lt_attr29_tbl_type(i)
                      ,XIBT.is_amex          = lt_attr30_tbl_type(i)
                      ,XIBT.attribute28      = NULL
                      ,XIBT.attribute29      = NULL
                      ,XIBT.attribute30      = NULL
               WHERE  XIBT.ixreceiptnumber   = lt_rcp_numb_tbl_type(i);

               EXIT WHEN c_attr_from_101%NOTFOUND;

      END LOOP;
      CLOSE c_attr_from_101;

      COMMIT;

      EXCEPTION

         WHEN NO_DATA_FOUND THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,'No Updatable record in Interface');
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Problem in Updating Transaction Text'|| sqlerrm);

   END XX_BULK101UPDATE;
/
show err