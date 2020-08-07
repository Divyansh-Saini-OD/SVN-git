-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- |                       WIPRO Technologies                                           |
-- +====================================================================================+
-- +====================================================================================+
-- | Description : AR Conversion LOB Updation                                           |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date          Author              Remarks                                 |
-- |=======   ==========   =============        ========================================|
-- |1.0       05-MAY-2009  Shobana S             Initial version                        |
-- |====================================================================================+

 -- +===================================================================+
-- | Name : XX_LOB_UPDATE                                              |
-- | Description : Update the Segment6 field of                        |
-- | RA_INTERFACE_DISTRIBUTIONS_ALL with the new LOB(Line Of Business) |
-- | value from the translation AR_LOB_UPDATE                          |
-- |                                                                   |
-- | program :                                                         |
-- | Parameters : x_error_buff, x_ret_code                             |
-- |                                                                   |
-- | Returns : Returns Code                                            |
-- |           Error Message                                           |
-- +===================================================================+
 CREATE OR REPLACE PROCEDURE XX_LOB_UPDATE
                      AS
   CURSOR lcu_trx_details
   IS
      (SELECT     RID.rowid
                 ,RID.interface_line_attribute2
                 ,XFTV.target_value1
                 ,RID.segment1||'.'||RID.segment2||'.'||RID.segment3||'.'||RID.segment4||'.'||
                  RID.segment5||'.'||RID.segment6||'.'||RID.segment7
                 ,RID.segment6
                 ,RID.account_class
       FROM    ra_interface_distributions_all   RID
              ,xx_fin_translatedefinition       XFTD
              ,xx_fin_translatevalues           XFTV
       WHERE  XFTV.translate_id          =   XFTD.translate_id
       AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
       AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
       AND XFTD.translation_name         = 'AR_LOB_UPDATE'
       AND RID.segment4                  = XFTV.source_value1
       AND XFTV.enabled_flag             = 'Y'
       AND XFTD.enabled_flag             = 'Y'
       AND RID.interface_line_context    = 'CONVERSION');

       TYPE trx_line_rowid_tbl_type  IS TABLE OF ROWID INDEX BY PLS_INTEGER;
       TYPE lob_value_tbl_type       IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
       TYPE trx_num_tbl_type         IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
       TYPE trx_segment_value        IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
       TYPE trx_lob_value            IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
       TYPE trx_acct_class           IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
       ln_count                    NUMBER;
       lt_trx_line_rowid           trx_line_rowid_tbl_type;
       lt_lob_value                lob_value_tbl_type;
       lt_trx_num                  trx_num_tbl_type;
       lt_trx_segment_value        trx_segment_value;
       lt_trx_lob_value            trx_lob_value;
       lt_trx_acct_class           trx_acct_class;
       lc_file_handle              UTL_FILE.file_type;
       lc_file_name                VARCHAR2(100);
      


   BEGIN
      lc_file_name   := 'XX_AR_INV_CCID_DETAILS_'
                        || TO_CHAR (SYSDATE, 'DDMONYYYYHH24MISS')
                        ||'.txt';

       DBMS_OUTPUT.PUT_LINE('Process Start.......');

      OPEN lcu_trx_details;
         lc_file_handle := UTL_FILE.fopen ('XXFIN_OUTBOUND', lc_file_name, 'A', 32767);

         UTL_FILE.put_line(lc_file_handle,RPAD('Trx Number ',25,' ')||
                                          RPAD('Concatenated Segment ',55,' ')||
                                          RPAD('Account Class ',20,' ')||
                                          RPAD('Old LOB Value  ',20,' ')||
                                          RPAD('New LOB Value  ',20,' '));

         UTL_FILE.put_line(lc_file_handle,RPAD('---------- ',25,' ')||
                                          RPAD('-------------------- ',55,' ')||
                                          RPAD('------------- ',20,' ')||
                                          RPAD('-------------  ',20,' ')||
                                          RPAD('-------------  ',20,' '));

         UTL_FILE.fclose (lc_file_handle);

         LOOP
            lc_file_handle := UTL_FILE.fopen ('XXFIN_OUTBOUND', lc_file_name, 'A', 32767);

            FETCH lcu_trx_details BULK COLLECT INTO lt_trx_line_rowid
                                                    ,lt_trx_num
                                                    ,lt_lob_value
                                                    ,lt_trx_segment_value 
                                                    ,lt_trx_lob_value       
                                                    ,lt_trx_acct_class         LIMIT 10000;

               IF lt_trx_line_rowid.COUNT = 0 THEN
                 RAISE NO_DATA_FOUND;
               END IF;

               FORALL ln_count IN lt_trx_line_rowid.FIRST..lt_trx_line_rowid.LAST
               UPDATE ra_interface_distributions_all RID
               SET   RID.segment6   = lt_lob_value(ln_count)
               WHERE RID.ROWID      = lt_trx_line_rowid(ln_count);

                  COMMIT;

               FOR i IN lt_trx_line_rowid.FIRST..lt_trx_line_rowid.LAST
               LOOP
                  UTL_FILE.put_line
                                  (lc_file_handle,RPAD (NVL(lt_trx_num(i),' '),25, ' ')||
                                   RPAD (NVL(lt_trx_segment_value(i),' '),55, ' ')||
                                   RPAD (NVL(lt_trx_acct_class(i),' '),20, ' ')||
                                   RPAD (NVL(lt_trx_lob_value(i),' '),20, ' ')||
                                   RPAD (NVL(lt_lob_value(i),' '),20, ' '));
               END LOOP;

             UTL_FILE.fclose (lc_file_handle);

          END LOOP;

      CLOSE lcu_trx_details;
       DBMS_OUTPUT.PUT_LINE('Process End.......');

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
       DBMS_OUTPUT.PUT_LINE('No Updatable records in Interface');
 
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in XX_LOB_UPDATE ');

END XX_LOB_UPDATE;
/