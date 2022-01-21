SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_GI_CONSIGN_CONV_CAP_PKG
-- +=================================================================================+
-- |                  Office Depot - Project Simplify                                |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
-- +=================================================================================+
-- |Name        : XX_GI_CONSIGN_CONV_CAP_PKG                                         |
-- |                                                                                 |
-- |Description : The procedures in this package read rows from the                  |
-- |              XX_GI_CONSIGN_CHANGES table and inserts them into                  |
-- |              MTL_TRANSACTIONS_INTERFACE table.                                  |
-- |Change Record:                                                                   |
-- |===============                                                                  |
-- |Version   Date        Author           Remarks                                   |
-- |=======   ==========  =============    ==========================================|
-- |Draft 1a  24-SEP-2007 Siddharth Singh  Initial draft version                     |
-- |Draft 1b  08-OCT-2007 Siddharth Singh  Incorporated Peer review comments.        |
-- |Draft 1c  18-OCT-2007 Siddharth Singh  Modified to perform Item based processing.|
-- |Draft 1d  26-Oct-2007 Siddharth Singh  Added query to fetch material account to  |
-- |                                       INSERT_MTI_ROW procedure.                 |
-- +=================================================================================+
AS


EX_END_PROC EXCEPTION;

TYPE failed_rec_type IS RECORD
    ( row_id                   ROWID
     ,change_id                XX_GI_CONSIGN_CHANGES.change_id%TYPE
     ,change_type              XX_GI_CONSIGN_CHANGES.change_type%TYPE
     ,effective_date           XX_GI_CONSIGN_CHANGES.effective_date%TYPE
     ,inventory_item_id        XX_GI_CONSIGN_CHANGES.inventory_item_id%TYPE
     ,organization_id          XX_GI_CONSIGN_CHANGES.organization_id%TYPE
     ,vendor_id                XX_GI_CONSIGN_CHANGES.vendor_id%TYPE
     ,consigned                PO_VENDORS.segment1%TYPE
     ,buyback                  PO_VENDORS.segment1%TYPE
     ,vendor_site_id           XX_GI_CONSIGN_CHANGES.vendor_site_id%TYPE
     ,buy_back_vendor_id       XX_GI_CONSIGN_CHANGES.buy_back_vendor_id%TYPE
     ,buy_back_vendor_site_id  XX_GI_CONSIGN_CHANGES.buy_back_vendor_site_id%TYPE
     ,old_po_cost              XX_GI_CONSIGN_CHANGES.old_po_cost%TYPE
     ,new_po_cost              XX_GI_CONSIGN_CHANGES.new_po_cost%TYPE
     ,processed_flag           XX_GI_CONSIGN_CHANGES.processed_flag%TYPE
     ,uom                      MTL_SYSTEM_ITEMS_B.primary_uom_code%TYPE
     ,segment1                 MTL_SYSTEM_ITEMS_B.segment1%TYPE
     ,creation_date            XX_GI_CONSIGN_CHANGES.creation_date%TYPE
     ,created_by               XX_GI_CONSIGN_CHANGES.created_by%TYPE
     ,process_date             XX_GI_CONSIGN_CHANGES.process_date%TYPE
     ,error_code               XX_GI_CONSIGN_CHANGES.error_code%TYPE
     ,error_explanation        XX_GI_CONSIGN_CHANGES.error_message%TYPE
    );

TYPE failed_rec_tbl_type IS TABLE OF failed_rec_type INDEX BY BINARY_INTEGER;
gt_failed_rec_table      failed_rec_tbl_type;  --Table to hold failed record details

gr_xgcc_rec            failed_rec_type := NULL;

TYPE success_rec_type IS RECORD
    ( success_rec  failed_rec_type
     ,print_flag   VARCHAR2(1)
    );

TYPE success_rec_tbl_type IS TABLE OF success_rec_type INDEX BY BINARY_INTEGER;
gt_succ_rec_table  success_rec_tbl_type;          --Table to hold successfuly processed records

EX_ITEM_ERROR  EXCEPTION;

gc_change_type          VARCHAR2(30)  := NULL;
gc_error_msg            VARCHAR2(240) := NULL;

gn_transaction_type_id  PLS_INTEGER := NULL;
gn_global_user_id       PLS_INTEGER := FND_GLOBAL.USER_ID;
gn_unprocessed_records  PLS_INTEGER := NULL;
gn_consign_items_limit  PLS_INTEGER := NULL;
gn_rec_inserted         PLS_INTEGER := NULL;
gn_rec_bypassed         PLS_INTEGER := NULL;
gn_rec_failed           PLS_INTEGER := NULL;
gn_qoh                  PLS_INTEGER := NULL;

PROCEDURE PRINT_LOG_OUTPUT_FOOTER
-- +===============================================================================+
-- |                                                                               |
-- | Name             : PRINT_LOG_OUTPUT_FOOTER                                    |
-- |                                                                               |
-- | Description      : This procedure prints the record statistics,column headers |
-- |                    ,failed records, and records inserted successfuly into     |
-- |                    MTI_TRANSACTIONS_INTERFACE table in the program Output and |
-- |                  : Log Footer Section.                                        |
-- |                                                                               |
-- +===============================================================================+
IS

lc_output_record VARCHAR2(3000);
lc_log_record    VARCHAR2(3000);
lc_column_header VARCHAR2(3000);
lc_separator     VARCHAR2(3000);

BEGIN

         fnd_file.put_line (fnd_file.output,'No. of records processed:                                                         '              || gn_unprocessed_records);
         fnd_file.put_line (fnd_file.output,'No. of records processed successfuly - ' || RPAD(gc_change_type,23,' ') || '                    '|| gn_rec_inserted);
         fnd_file.put_line (fnd_file.output,'No. of records failed:                                                            '              || gn_rec_failed);

         IF (gc_change_type = G_CHANGE_TYPE_CR OR gc_change_type = G_CHANGE_TYPE_RC) THEN
             fnd_file.put_line (fnd_file.output,'No. of records bypassed because: ' || gc_change_type || ' Items > '                              || RPAD(NVL(gn_consign_items_limit,0),10,' ') ||'            ' ||gn_rec_bypassed);
         ELSIF (gc_change_type = G_CHANGE_TYPE_PO) THEN
             fnd_file.put_line (fnd_file.output,'No. of records bypassed because: ' || gc_change_type || ' Items > '                              || RPAD(NVL(gn_consign_items_limit,0),10,' ') ||'        ' ||gn_rec_bypassed);
         END IF;

         fnd_file.put_line (fnd_file.output,'');
         fnd_file.put_line (fnd_file.output,'');

         --Printing successful records
         fnd_file.put_line (fnd_file.output,'');
         fnd_file.put_line (fnd_file.output,'                                                  ------------------------------');
         fnd_file.put_line (fnd_file.output,'                                                  RECORDS PROCESSED SUCCESSFULLY');
         fnd_file.put_line (fnd_file.output,'                                                  ------------------------------');
         fnd_file.put_line (fnd_file.output,'');


         lc_column_header := NULL;
         lc_column_header := lc_column_header || RPAD('CHANGE_TYPE',30,' ')            ||CHR(09);
         lc_column_header := lc_column_header || RPAD('SKU',10,' ')                    ||CHR(09);
         lc_column_header := lc_column_header || RPAD('CONSIGN SUPPLIER',22,' ')       ||CHR(09);
         lc_column_header := lc_column_header || RPAD('BUYBACK SUPPLIER',23,' ')       ||CHR(09);
         lc_column_header := lc_column_header || RPAD('OLD_PO_COST',12,' ')            ||CHR(09);
         lc_column_header := lc_column_header || RPAD('NEW_PO_COST',12,' ')            ||CHR(09);
         lc_column_header := lc_column_header || RPAD('EFFECTIVE_DATE',15,' ')         ||CHR(09);

         lc_separator     := NULL;
         lc_separator     := lc_separator || RPAD('-----------------------------',30,' ')            ||CHR(09);
         lc_separator     := lc_separator || RPAD('----',10,' ')                                     ||CHR(09);
         lc_separator     := lc_separator || RPAD('---------------------',22,' ')                    ||CHR(09);
         lc_separator     := lc_separator || RPAD('----------------------',23,' ')                   ||CHR(09);
         lc_separator     := lc_separator || RPAD('-----------',12,' ')                              ||CHR(09);
         lc_separator     := lc_separator || RPAD('-----------',12,' ')                              ||CHR(09);
         lc_separator     := lc_separator || RPAD('--------------',15,' ')                           ||CHR(09);

         fnd_file.put_line (fnd_file.output,lc_column_header);
         fnd_file.put_line (fnd_file.output,lc_separator);

         IF (gt_succ_rec_table.COUNT > 0 AND gn_rec_inserted > 0) THEN

             FOR  ln_log_counter IN gt_succ_rec_table.FIRST .. gt_succ_rec_table.LAST
             LOOP

                 IF (gt_succ_rec_table(ln_log_counter).print_flag = 'Y') THEN

                     lc_log_record := NULL;
                     lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_log_counter).success_rec.change_type),' '),30,' ' )             ||CHR(09);
                     lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_log_counter).success_rec.segment1),' '),10,' ' )                ||CHR(09);

                     lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_log_counter).success_rec.consigned),' '),22,' ' )        ||CHR(09);
                     lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_log_counter).success_rec.buyback),' '),23, ' ')        ||CHR(09);
                     lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_log_counter).success_rec.old_po_cost),' '),12,' ')              ||CHR(09);
                     lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_log_counter).success_rec.new_po_cost),' '),12,' ')              ||CHR(09);

                     lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_log_counter).success_rec.effective_date),' '),15,' ')           ||CHR(09);

                     fnd_file.put_line (fnd_file.output,lc_log_record);

                 END IF;

             END LOOP;

         END IF;

         lc_column_header := NULL;
         lc_column_header := lc_column_header || RPAD('CHANGE_ID',10,' ')              ||CHR(09);
         lc_column_header := lc_column_header || RPAD('CHANGE_TYPE',30,' ')            ||CHR(09);
         lc_column_header := lc_column_header || RPAD('EFFECTIVE_DATE',15,' ')         ||CHR(09);
         lc_column_header := lc_column_header || RPAD('CREATION_DATE',14,' ')          ||CHR(09);
         lc_column_header := lc_column_header || RPAD('CREATED_BY',11,' ')             ||CHR(09);
         lc_column_header := lc_column_header || RPAD('INVENTORY_ITEM_ID',18,' ')      ||CHR(09);
         lc_column_header := lc_column_header || RPAD('ORGANIZATION_ID',16,' ')        ||CHR(09);
         lc_column_header := lc_column_header || RPAD('PRIMARY_SUPPLIER_SITE',22,' ')  ||CHR(09);
         lc_column_header := lc_column_header || RPAD('BUY_BACK_SUPPLIER_SITE',23,' ') ||CHR(09);
         lc_column_header := lc_column_header || RPAD('OLD_PO_COST',12,' ')            ||CHR(09);
         lc_column_header := lc_column_header || RPAD('NEW_PO_COST',12,' ')            ||CHR(09);
         lc_column_header := lc_column_header || RPAD('PROCESSED_FLAG',15,' ')         ||CHR(09);
         lc_column_header := lc_column_header || RPAD('PROCESS_DATE',13,' ')           ||CHR(09);
         lc_column_header := lc_column_header || RPAD('ERROR_CODE',20,' ')             ||CHR(09);
         lc_column_header := lc_column_header || RPAD('ERROR_MESSAGE',240,' ')         ||CHR(09);

         lc_separator     := NULL;
         lc_separator     := lc_separator || RPAD('---------',10,' ')                      ||CHR(09);
         lc_separator     := lc_separator || RPAD('-----------------------------',30,' ')  ||CHR(09);
         lc_separator     := lc_separator || RPAD('--------------',15,' ')                 ||CHR(09);
         lc_separator     := lc_separator || RPAD('-------------',14,' ')                  ||CHR(09);
         lc_separator     := lc_separator || RPAD('----------',11,' ')                     ||CHR(09);
         lc_separator     := lc_separator || RPAD('-----------------',18,' ')              ||CHR(09);
         lc_separator     := lc_separator || RPAD('---------------',16,' ')                ||CHR(09);
         lc_separator     := lc_separator || RPAD('---------------------',22,' ')          ||CHR(09);
         lc_separator     := lc_separator || RPAD('----------------------',23,' ')         ||CHR(09);
         lc_separator     := lc_separator || RPAD('-----------',12,' ')                    ||CHR(09);
         lc_separator     := lc_separator || RPAD('-----------',12,' ')                    ||CHR(09);
         lc_separator     := lc_separator || RPAD('--------------',15,' ')                 ||CHR(09);
         lc_separator     := lc_separator || RPAD('------------',13,' ')                   ||CHR(09);
         lc_separator     := lc_separator || RPAD('----------',20,' ')                     ||CHR(09);
         lc_separator     := lc_separator || RPAD('-----------------',240,' ')             ||CHR(09);
         
         
         fnd_file.put_line (fnd_file.output,'');
         fnd_file.put_line (fnd_file.output,'                                                  ---------------------');
         fnd_file.put_line (fnd_file.output,'                                                  FAILED RECORD DETAILS');
         fnd_file.put_line (fnd_file.output,'                                                  ---------------------');
         fnd_file.put_line (fnd_file.output,'');

         fnd_file.put_line (fnd_file.output,lc_column_header);
         fnd_file.put_line (fnd_file.output,lc_separator);

         IF (gt_failed_rec_table.COUNT > 0) THEN
         
         fnd_file.put_line (fnd_file.log,'No of records in failed table = ' || gt_failed_rec_table.COUNT);

             --Print records from the failed table 
             FOR  ln_counter IN gt_failed_rec_table.FIRST .. gt_failed_rec_table.LAST
             LOOP

                 lc_output_record := NULL;
                 lc_output_record := RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).change_id),' '),10,' ')                                   ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).change_type),' '),30,' ' )            ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).effective_date),' '),15,' ')          ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).creation_date),' '),14,' ')           ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).created_by),' '),11,' ')              ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).inventory_item_id),' '),18,' ')                ||CHR(09);

                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).organization_id),' '),16,' ')         ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).vendor_site_id),' '),22,' ')          ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).buy_back_vendor_site_id),' '),23,' ') ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).old_po_cost),' '),12,' ')             ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).new_po_cost),' '),12,' ')             ||CHR(09);

                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).processed_flag),' '),15,' ')          ||CHR(09);

                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).process_date),' '),13,' ')            ||CHR(09);

                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).error_code),' '),20,' ')              ||CHR(09);
                 lc_output_record := lc_output_record || RPAD(NVL(TO_CHAR(gt_failed_rec_table(ln_counter).error_explanation),' '),240,' ')      ||CHR(09);

                 fnd_file.put_line (fnd_file.output,lc_output_record);

                 IF (gt_succ_rec_table.COUNT > 0) THEN

                     fnd_file.put_line (fnd_file.log,'No of records in successful table = ' || gt_succ_rec_table.COUNT);

                     --To print those records records which are in successful table but were rolled back later.
                     FOR ln_scounter IN gt_succ_rec_table.FIRST .. gt_succ_rec_table.LAST
                     LOOP
                     

                         IF (gt_failed_rec_table(ln_counter).inventory_item_id = gt_succ_rec_table(ln_scounter).success_rec.inventory_item_id
                             AND gt_succ_rec_table(ln_scounter).print_flag = 'N') 
                         THEN

                             fnd_file.put_line (fnd_file.log,'Printing rolled back records from success table');
                             lc_log_record := NULL;
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.change_id),' '),10,' ')               ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.change_type),' '),30,' ' )            ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.effective_date),' '),15,' ')          ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.creation_date),' '),14,' ')           ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.created_by),' '),11,' ')              ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.inventory_item_id),' '),18,' ')       ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.organization_id),' '),16,' ')         ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.vendor_site_id),' '),22,' ')          ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.buy_back_vendor_site_id),' '),23,' ') ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.old_po_cost),' '),12,' ')             ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.new_po_cost),' '),12,' ')             ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.processed_flag),' '),15,' ')          ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.process_date),' '),13,' ')            ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.error_code),' '),20,' ')              ||CHR(09);
                             lc_log_record := lc_log_record || RPAD(NVL(TO_CHAR(gt_succ_rec_table(ln_scounter).success_rec.error_explanation),' '),240,' ')      ||CHR(09);

                             fnd_file.put_line (fnd_file.output,lc_log_record);
                             fnd_file.put_line (fnd_file.log,'Change Id: ' || gt_succ_rec_table(ln_scounter).success_rec.change_id);
                             
                             --Mark this record as already printed 
                             gt_succ_rec_table(ln_scounter).print_flag := 'X';

                             fnd_file.put_line (fnd_file.log,'Updating print flag to X');

                         END IF;

                     END LOOP;
                     --Loop to print rolled back records from successful table ends.
                 END IF;
                 --IF (gt_succ_rec_table.COUNT > 0) Ends

             END LOOP;
             --Loop to Print records from the failed table Ends

         END IF;

         fnd_file.put_line (fnd_file.output,'');
         fnd_file.put_line (fnd_file.output,'');
         fnd_file.put_line (fnd_file.output,'============================================================================================================================');
         fnd_file.put_line (fnd_file.output,'                                *** End of Report - Consignment Change Load Statistics ***                             ');

         fnd_file.put_line (fnd_file.output,'');
         fnd_file.put_line (fnd_file.output,'Program End Time: ' || TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS AM'));

         fnd_file.put_line (fnd_file.log,' ');
         fnd_file.put_line (fnd_file.log,'============================================================================================================================');
         fnd_file.put_line (fnd_file.log,'                                 *** End of Report - Consignment Change Load Summary ***                              ');

END PRINT_LOG_OUTPUT_FOOTER;


PROCEDURE PRINT_LOG_OUTPUT_HEADER
-- +===============================================================================+
-- |                                                                               |
-- | Name             : PRINT_LOG_OUTPUT_HEADER                                    |
-- |                                                                               |
-- | Description      : This procedure prints Header Sections for the program      |
-- |                    Output and Log.                                            |
-- |                                                                               |
-- | Parameters       :                                                            |
-- |                                                                               |
-- +===============================================================================+

IS

lc_column_header  VARCHAR2(3000);
lc_separator      VARCHAR2(3000);

BEGIN

                  fnd_file.put_line (fnd_file.output,'============================================================================================================================');
                  fnd_file.put_line (fnd_file.output,'Office Depot '||LPAD('Date:',90,' ')||TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS AM'));
                  fnd_file.put_line (fnd_file.output,'                                             Consignment Change Load Statistics                                             ');
                  fnd_file.put_line (fnd_file.output,'                                                  ' || gc_change_type ||'                                               ');
                  fnd_file.put_line (fnd_file.output,'============================================================================================================================');
                  fnd_file.put_line (fnd_file.output,'                                                                                                                            ');
                  fnd_file.put_line (fnd_file.output,'                                                                                                                            ');
                  fnd_file.put_line (fnd_file.output,'Program Start Time: ' || TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS AM'));
                  fnd_file.put_line (fnd_file.output,' ');

                  fnd_file.put_line (fnd_file.log,'============================================================================================================================');
                  fnd_file.put_line (fnd_file.log,'Office Depot '||LPAD('Date:',85,' ')||TO_CHAR(SYSDATE,'DD-MON-YY HH24:MI:SS AM'));
                  fnd_file.put_line (fnd_file.log,'                                              Consignment Change Load Summary                                              ');
                  fnd_file.put_line (fnd_file.log,'============================================================================================================================');
                  fnd_file.put_line (fnd_file.log,'                                                                                                                            ');
                  fnd_file.put_line (fnd_file.log,'                                                                                                                            ');
                  

END PRINT_LOG_OUTPUT_HEADER;


PROCEDURE UPDATE_XGCC_ROW (p_row_id         IN  ROWID   DEFAULT NULL
                          ,p_processed_flag    IN  VARCHAR2
                          ,p_process_date      IN  DATE     DEFAULT SYSDATE
                          ,p_error_code        IN  VARCHAR2 DEFAULT NULL
                          ,p_error_explanation IN  VARCHAR2 DEFAULT NULL
                           )
-- +===============================================================================+
-- |                                                                               |
-- | Name             : UPDATE_XGCC_ROW                                            |
-- |                                                                               |
-- | Description      : This procedure updates a row in the XX_GI_CONSIGN_CHANGES  |
-- |                    table.        .                                            |
-- |                                                                               |
-- | Parameters       :                                                            |
-- |                                                                               |
-- +===============================================================================+

IS

BEGIN

         IF (p_row_id IS NULL) THEN

             --When Count of rows is greater than Consign Max Item Limit DFF
             UPDATE XX_GI_CONSIGN_CHANGES
             SET    processed_flag    = p_processed_flag
                   ,process_date      = p_process_date
                   ,error_code        = p_error_code
                   ,error_message     = p_error_explanation
             WHERE  processed_flag    = 'N' 
             AND    change_type       = gc_change_type;

         ELSE

             UPDATE XX_GI_CONSIGN_CHANGES XGCC
             SET    processed_flag    = p_processed_flag
                   ,process_date      = p_process_date
                   ,error_code        = p_error_code
                   ,error_message     = p_error_explanation
             WHERE  XGCC.rowid        = p_row_id
             AND    processed_flag    = 'N';

         END IF;

EXCEPTION
    WHEN OTHERS THEN
    gc_error_msg := 'When Others Exception in Procedure UPDATE_XGCC_ROW';
    RAISE EX_ITEM_ERROR;

END UPDATE_XGCC_ROW;


PROCEDURE QUERY_QUANTITIES(p_organization_id   IN  NUMBER
                          ,p_inventory_item_id IN  NUMBER
                          ,p_row_id         IN  ROWID
                          ,x_ret_status        OUT VARCHAR2
                          )
-- +===============================================================================+
-- |                                                                               |
-- | Name             : QUERY_QUANTITIES                                           |
-- |                                                                               |
-- | Description      : This procedure internally calls the standard API           |
-- |                    INV_QUANTITY_TREE_PUB.query_quantities                     |
-- |                                                                               |
-- | Parameters       :                                                            |
-- |                                                                               |
-- +===============================================================================+
IS

EX_API_ERROR         EXCEPTION;

L_API_VERSION_NO     CONSTANT PLS_INTEGER    := 1.1;
L_ONHAND_SOURCE      CONSTANT PLS_INTEGER    := 3;

lc_api_return_status VARCHAR2(1)       := NULL;
lc_msg_data          VARCHAR2(240)     := NULL;

ln_msg_index_out     PLS_INTEGER   := NULL;
ln_msg_count         PLS_INTEGER   := NULL;
ln_rqoh              PLS_INTEGER   := NULL;
ln_qty_res           PLS_INTEGER   := NULL;
ln_qty_sug           PLS_INTEGER   := NULL;
ln_qty_att           PLS_INTEGER   := NULL;
ln_qty_atr           PLS_INTEGER   := NULL;


BEGIN

         gn_qoh := NULL;

         INV_QUANTITY_TREE_PUB.query_quantities(p_api_version_number  => L_API_VERSION_NO
                                               ,p_init_msg_lst        => FND_API.G_TRUE
                                               ,x_return_status       => lc_api_return_status
                                               ,x_msg_count           => ln_msg_count
                                               ,x_msg_data            => lc_msg_data
                                               ,p_organization_id     => p_organization_id
                                               ,p_inventory_item_id   => p_inventory_item_id
                                               ,p_tree_mode           => INV_QUANTITY_TREE_PUB.g_transaction_mode
                                               ,p_onhand_source       => L_ONHAND_SOURCE
                                               ,p_is_revision_control => FALSE
                                               ,p_is_lot_control      => FALSE
                                               ,p_is_serial_control   => FALSE
                                               ,p_revision            => NULL
                                               ,p_lot_number          => NULL
                                               ,p_subinventory_code   => NULL
                                               ,p_locator_id          => NULL
                                               ,x_qoh                 => gn_qoh      --Quantity on hand
                                               ,x_rqoh                => ln_rqoh     --reservable quantity on hand
                                               ,x_qr                  => ln_qty_res  --quantity reserved
                                               ,x_qs                  => ln_qty_sug  --quantity suggested
                                               ,x_att                 => ln_qty_att  --available to transact
                                               ,x_atr                 => ln_qty_atr  --available to reserve
                                               );

         x_ret_status := lc_api_return_status;

         IF (lc_api_return_status <> 'S') THEN

             IF (ln_msg_count > 1) THEN

                 FOR ln_index IN 1.. ln_msg_count 
                 LOOP
                     FND_MSG_PUB.GET(p_encoded       => FND_API.G_FALSE
                                    ,p_data          => lc_msg_data
                                    ,p_msg_index_out => ln_msg_index_out
                                    );

                     gc_error_msg := gc_error_msg || lc_msg_data;

                 END LOOP;

                 RAISE EX_API_ERROR;

             --If ln_msg_count =1
             ELSE

                 FND_MSG_PUB.GET(p_msg_index     => FND_MSG_PUB.G_FIRST
                                ,p_encoded       => FND_API.G_FALSE
                                ,p_data          => lc_msg_data
                                ,p_msg_index_out => ln_msg_index_out
                                );

                 gc_error_msg := lc_msg_data;
                 RAISE EX_API_ERROR;

             END IF;
             --If ln_msg_count > 1 ENDS
         END IF;
         --IF (lc_api_return_status <> 'S') ENDS

EXCEPTION
   WHEN EX_API_ERROR THEN 
   UPDATE_XGCC_ROW (p_row_id            => p_row_id
                   ,p_processed_flag    => 'E'
                   ,p_error_code        => 'STD API ERROR'
                   ,p_error_explanation => gc_error_msg
                   );

   WHEN OTHERS THEN
   UPDATE_XGCC_ROW(p_row_id             => p_row_id
                   ,p_processed_flag    => 'E'
                   ,p_error_code        => SQLCODE
                   ,p_error_explanation => SQLERRM
                   );

END QUERY_QUANTITIES;

PROCEDURE INSERT_MTI_ROW (p_xgcc_rec IN failed_rec_type)
-- +=====================================================================================+
-- |                                                                                     |
-- | Name             : INSERT_MTI_ROW                                                   |
-- |                                                                                     |
-- | Description      : This procedure inserts a row into the MTL_TRANSACTIONS_INTERFACE |
-- |                    table         .                                                  |
-- |                                                                                     |
-- | Parameters       :                                                                  |
-- |                                                                                     |
-- +=====================================================================================+
IS

L_SOURCE_CODE          CONSTANT mtl_transactions_interface.source_code%TYPE           := 'CONSIGN CHANGE LOAD';
L_PROCESS_FLAG         CONSTANT mtl_transactions_interface.process_flag%TYPE          :=1;  --READY
L_TRANSACTION_MODE     CONSTANT mtl_transactions_interface.transaction_mode%TYPE      :=3;  --Background Processing Mode
L_TRANSACTION_QUANTITY CONSTANT mtl_transactions_interface.transaction_quantity%TYPE  :=0;  --Zero for Average Cost Updates

LC_CONSIGNMENT_FLAG    CONSTANT VARCHAR2(1)  := 'Y';
ln_new_avg_cost        PLS_INTEGER  := NULL;
ln_value_change        mtl_transactions_interface.value_change%TYPE  := NULL;
ln_material_account    PLS_INTEGER := NULL;

BEGIN

         BEGIN

             SELECT MP.material_account
             INTO   ln_material_account
             FROM   mtl_parameters MP
             WHERE  MP.organization_id   = p_xgcc_rec.organization_id;

         EXCEPTION
             WHEN OTHERS THEN
             gc_error_msg := NULL;
             gc_error_msg := SQLERRM || ' Error in getting Material Account.';
             RAISE;
         END;

         IF ((p_xgcc_rec.change_type = G_CHANGE_TYPE_RC) OR (p_xgcc_rec.change_type = G_CHANGE_TYPE_CR)) THEN
             ln_new_avg_cost := p_xgcc_rec.new_po_cost;
             ln_value_change := NULL;
         ELSE
             ln_new_avg_cost := NULL;
             ln_value_change := (p_xgcc_rec.new_po_cost - NVL(p_xgcc_rec.old_po_cost,0)) * (gn_qoh);
         END IF;

         INSERT INTO MTL_TRANSACTIONS_INTERFACE
             (SOURCE_CODE
             ,SOURCE_LINE_ID
             ,SOURCE_HEADER_ID
             ,PROCESS_FLAG
             ,TRANSACTION_MODE
             ,LAST_UPDATE_DATE
             ,LAST_UPDATED_BY
             ,CREATION_DATE
             ,CREATED_BY
             ,TRANSACTION_DATE
             ,INVENTORY_ITEM_ID
             ,ORGANIZATION_ID
             ,TRANSACTION_TYPE_ID
             ,TRANSACTION_QUANTITY
             ,TRANSACTION_UOM
             ,NEW_AVERAGE_COST
             ,VALUE_CHANGE
             ,ATTRIBUTE14
             ,ATTRIBUTE15
             ,MATERIAL_ACCOUNT
             )
         VALUES
             (L_SOURCE_CODE                        --SOURCE_CODE
             ,p_xgcc_rec.change_id                 --SOURCE_LINE_ID
             ,p_xgcc_rec.change_id                 --SOURCE_HEADER_ID
             ,L_PROCESS_FLAG                       --PROCESS_FLAG
             ,L_TRANSACTION_MODE                   --TRANSACTION_MODE
             ,SYSDATE                              --LAST_UPDATE_DATE
             ,gn_global_user_id                    --LAST_UPDATED_BY
             ,SYSDATE                              --CREATION_DATE
             ,gn_global_user_id                    --CREATED_BY
             ,SYSDATE                              --TRANSACTION_DATE
             ,p_xgcc_rec.inventory_item_id         --INVENTORY_ITEM_ID
             ,p_xgcc_rec.organization_id           --ORGANIZATION_ID
             ,gn_transaction_type_id               --TRANSACTION_TYPE_ID
             ,L_TRANSACTION_QUANTITY               --TRANSACTION_QUANTITY
             ,p_xgcc_rec.uom                       --TRANSACTION_UOM
             ,ln_new_avg_cost                      --NEW_AVERAGE_COST
             ,ln_value_change                      --VALUE_CHANGE
             ,p_xgcc_rec.buy_back_vendor_site_id   --ATTRIBUTE14
             ,LC_CONSIGNMENT_FLAG                  --ATTRIBUTE15 (consignment_flag)
             ,ln_material_account
         );

EXCEPTION
    WHEN OTHERS THEN
    gc_error_msg := 'WHEN OTHERS EXCEPTION in Procedure INSERT_MTI_ROW.Error: ' || gc_error_msg;
    RAISE EX_ITEM_ERROR;
END INSERT_MTI_ROW;


PROCEDURE PROCESS_UPDATE_WAC ( x_errbuf      OUT VARCHAR2
                              ,x_retcode     OUT NUMBER
                              ,p_change_type IN  VARCHAR2
                              )
-- +===============================================================================+
-- |                                                                               |
-- | Name             : PROCESS_UPDATE_WAC                                         |
-- |                                                                               |
-- | Description      : This procedure is called from the concurrent program       |
-- |                    OD: GI Consignment Conversion Deconversion Load.           |
-- |                                                                               |
-- | Parameters       :                                                            |
-- |                                                                               |
-- +===============================================================================+
IS


EX_MAX_LIMIT   EXCEPTION;

lc_return_status     VARCHAR2(1);
lc_exception_raised  VARCHAR2(1) := 'N';

ln_index       PLS_INTEGER := NULL;
ln_log_index   PLS_INTEGER := NULL;
ln_temp_inv_id XX_GI_CONSIGN_CHANGES.inventory_item_id%TYPE := -999;


CURSOR lcu_get_unprocessed_ctype
IS
SELECT  XGCC.ROWID
       ,XGCC.CHANGE_ID
       ,XGCC.CHANGE_TYPE
       ,XGCC.EFFECTIVE_DATE
       ,XGCC.INVENTORY_ITEM_ID
       ,XGCC.ORGANIZATION_ID
       ,XGCC.VENDOR_ID
       , (SELECT segment1 
          FROM   PO_VENDORS
          WHERE  vendor_id = XGCC.VENDOR_ID) CONSIGNED
       , (SELECT segment1 
          FROM   PO_VENDORS
          WHERE  vendor_id = XGCC.BUY_BACK_VENDOR_ID) BUYBACK
       ,XGCC.VENDOR_SITE_ID
       ,XGCC.BUY_BACK_VENDOR_ID
       ,XGCC.BUY_BACK_VENDOR_SITE_ID
       ,XGCC.OLD_PO_COST
       ,XGCC.NEW_PO_COST
       ,XGCC.PROCESSED_FLAG
       , (SELECT primary_uom_code 
          FROM   MTL_SYSTEM_ITEMS_B MSI 
          WHERE  MSI.inventory_item_id = XGCC.inventory_item_id  
          AND    MSI.organization_id   = XGCC.organization_id) UOM
       , (SELECT segment1 
          FROM   MTL_SYSTEM_ITEMS_B MSI 
          WHERE  MSI.inventory_item_id = XGCC.inventory_item_id
          AND    MSI.organization_id   = XGCC.organization_id) SEGMENT1
       ,XGCC.CREATION_DATE
       ,XGCC.CREATED_BY   
       ,XGCC.PROCESS_DATE
       ,XGCC.ERROR_CODE
       ,XGCC.ERROR_MESSAGE
FROM    xx_gi_consign_changes XGCC
WHERE   XGCC.processed_flag = 'N'
AND     XGCC.change_type    = p_change_type
ORDER BY inventory_item_id,change_id ASC;

BEGIN

         gc_change_type := p_change_type;

         PRINT_LOG_OUTPUT_HEADER();

         fnd_file.put_line (fnd_file.log,'Change Type is: ' || gc_change_type);
         fnd_file.put_line (fnd_file.log,'Getting Count of unprocessed records');
         --Get count of unprocessed records
         BEGIN

             SELECT   count(*) 
             INTO     gn_unprocessed_records
             FROM     xx_gi_consign_changes
             WHERE    processed_flag = 'N'
             AND      change_type    = p_change_type;

             IF (gn_unprocessed_records = 0) THEN
                 gc_error_msg := 'There are no records of type ' || p_change_type || ' to process.';
                 RAISE EX_END_PROC;
             END IF;

         EXCEPTION
             WHEN OTHERS THEN
             gc_error_msg := gc_error_msg || SQLERRM;
             RAISE;
         END;

         fnd_file.put_line (fnd_file.log,'Getting values for transaction type id and Consign Max Item Limit DFF');
         --Get values for transaction type id and Consign Max Item Limit DFF 
         BEGIN

             SELECT transaction_type_id,TO_NUMBER(attribute10)
             INTO   gn_transaction_type_id,gn_consign_items_limit
             FROM   mtl_transaction_types MTT
             WHERE  MTT.transaction_type_name = DECODE(p_change_type,G_CHANGE_TYPE_CR,G_TRANS_TYPE_CR
                                                                    ,G_CHANGE_TYPE_RC,G_TRANS_TYPE_RC
                                                                    ,G_CHANGE_TYPE_PO,G_TRANS_TYPE_PO
                                                      );

             IF (gn_consign_items_limit = 0 OR gn_consign_items_limit IS NULL) THEN
                 gc_error_msg := 'Value of MAX ITEMS LIMIT DFF is Not Set.';
                 RAISE EX_END_PROC;
             END IF;

         EXCEPTION
             WHEN OTHERS THEN
             gc_error_msg := gc_error_msg || SQLERRM;
             RAISE;
         END;

         --If Count of rows is greater than Consign Max Item Limit DFF for that Change Type then terminate program
         IF (gn_unprocessed_records > gn_consign_items_limit) THEN

             fnd_file.put_line (fnd_file.log,'Count of rows, ' || gn_unprocessed_records ||' is greater than Consign Max Item Limit DFF: ' || gn_consign_items_limit);
             gn_rec_inserted := 0;
             gn_rec_bypassed := gn_unprocessed_records;
             gn_rec_failed   := 0;
             gt_failed_rec_table.DELETE;
             ln_index := 1;

             FOR lcu_get_unprocessed_ctype_rec IN lcu_get_unprocessed_ctype
             LOOP

                 gr_xgcc_rec                                     := lcu_get_unprocessed_ctype_rec;
                 gt_failed_rec_table(ln_index)                   := lcu_get_unprocessed_ctype_rec;
                 --over write processed_flag,error_code and error_explanation
                 gt_failed_rec_table(ln_index).processed_flag    := 'E';
                 gt_failed_rec_table(ln_index).error_code        := 'MAX LIMIT EXCEEDED';
                 gt_failed_rec_table(ln_index).process_date      :=  SYSDATE;
                 gt_failed_rec_table(ln_index).error_explanation := 'Number of Rows of change type:' || p_change_type || ' is greater than the limit:' || TO_CHAR(gn_consign_items_limit);

                 ln_index      := ln_index + 1;

             END LOOP;

             UPDATE_XGCC_ROW(p_processed_flag     => 'E'
                            ,p_error_code         => 'MAX LIMIT EXCEEDED'
                            ,p_error_explanation  => 'Number of Rows of change type:' || p_change_type || ' is greater than the limit:' || TO_CHAR(gn_consign_items_limit)
                            );

             RAISE EX_MAX_LIMIT;

         --If count of rows is less than Consign Max Item Limit DFF value for the given Transaction Type
         ELSE

             fnd_file.put_line (fnd_file.log,'Count of rows is: ' || gn_unprocessed_records || ' ,Consign Max Item Limit DFF is: ' || gn_consign_items_limit);
             gt_failed_rec_table.DELETE;
             ln_index := 1;

             gt_succ_rec_table.DELETE;
             ln_log_index := 1;

             gn_rec_failed   := 0;
             gn_rec_inserted := 0;
             gn_rec_bypassed := 0;

             --Fetch all unprocessed rows of the given change_type
             FOR lcu_get_unprocessed_ctype_rec IN lcu_get_unprocessed_ctype
             LOOP

                 --Anonymous Block
                 BEGIN

                     --For every new item create a SAVEPOINT
                     IF (ln_temp_inv_id <> lcu_get_unprocessed_ctype_rec.inventory_item_id) THEN
                         fnd_file.put_line (fnd_file.log,'Creating Savepoint for ' || lcu_get_unprocessed_ctype_rec.change_id);
                         lc_exception_raised := 'N';
                         SAVEPOINT NEW_ITEM;

                     --If the current item is same as the previous item and exception was raised for the previous run
                     --No need to process this record.
                     ELSIF (lc_exception_raised = 'Y' AND ln_temp_inv_id = lcu_get_unprocessed_ctype_rec.inventory_item_id) THEN
                         
                         gc_error_msg := 'Exception was raised for this Item Previously';
                         RAISE EX_ITEM_ERROR;
                     END IF;

                     ln_temp_inv_id := lcu_get_unprocessed_ctype_rec.inventory_item_id;

                     --If it is a PO COST CHANGE
                     IF (lcu_get_unprocessed_ctype_rec.change_type = G_CHANGE_TYPE_PO) THEN

                         --Get total quantity onhand and in-transit
                         QUERY_QUANTITIES (p_organization_id   => lcu_get_unprocessed_ctype_rec.organization_id
                                          ,p_inventory_item_id => lcu_get_unprocessed_ctype_rec.inventory_item_id
                                          ,p_row_id            => lcu_get_unprocessed_ctype_rec.rowid
                                          ,x_ret_status        => lc_return_status
                                          );

                         --If API error display in program output and terminate the program.
                         IF (lc_return_status <> 'S') THEN

                             fnd_file.put_line (fnd_file.log,'QUERY_QUANTITIES API ERROR: Return Status = ' || lc_return_status);
                             gc_error_msg := 'STANDARD API ERROR' || gc_error_msg;
                             RAISE EX_ITEM_ERROR;

                         --If no API error
                         ELSE 

                             gr_xgcc_rec  := lcu_get_unprocessed_ctype_rec;

                             IF (lcu_get_unprocessed_ctype_rec.segment1 IS NULL) THEN
                                 gc_error_msg := 'For Change Id: ' || lcu_get_unprocessed_ctype_rec.change_id || ' Item is Invalid or is not assigned to Inventory Organization: ' || lcu_get_unprocessed_ctype_rec.organization_id;
                                 RAISE EX_ITEM_ERROR;
                             ELSIF (lcu_get_unprocessed_ctype_rec.consigned IS NULL) THEN
                                 gc_error_msg := 'For Change Id: ' || lcu_get_unprocessed_ctype_rec.change_id || ' The Consigned Supplier: ' || lcu_get_unprocessed_ctype_rec.vendor_id||' is Invalid.';
                                 RAISE EX_ITEM_ERROR;
                             ELSIF (lcu_get_unprocessed_ctype_rec.buyback IS NULL) THEN
                                 gc_error_msg := 'For Change Id: ' || lcu_get_unprocessed_ctype_rec.change_id || ' The Buy Back Supplier: '  || lcu_get_unprocessed_ctype_rec.buy_back_vendor_id || ' is Invalid.';
                                 RAISE EX_ITEM_ERROR;
                             END IF;

                             INSERT_MTI_ROW(p_xgcc_rec => lcu_get_unprocessed_ctype_rec);

                             --It is a successful record
                             gt_succ_rec_table(ln_log_index).success_rec  := lcu_get_unprocessed_ctype_rec;
                             gt_succ_rec_table(ln_log_index).print_flag   := 'Y';

                             ln_log_index := ln_log_index + 1;

                             UPDATE_XGCC_ROW(p_row_id      => lcu_get_unprocessed_ctype_rec.rowid 
                                            ,p_processed_flag => 'Y'
                                            );

                             gn_rec_inserted := gn_rec_inserted + 1 ;
                             fnd_file.put_line (fnd_file.log,'---------------------------------------------------------');

                         END IF;

                     --If change_type is other than PO Cost Change
                     ELSE

                         --ln_change_id := lcu_get_unprocessed_ctype_rec.change_id;
                         gr_xgcc_rec  := lcu_get_unprocessed_ctype_rec;
                         
                         IF (lcu_get_unprocessed_ctype_rec.segment1 IS NULL) THEN
                             gc_error_msg := 'For Change Id: ' || lcu_get_unprocessed_ctype_rec.change_id || ' Item is Invalid or is not assigned to Inventory Organization: ' || lcu_get_unprocessed_ctype_rec.organization_id;
                             RAISE EX_ITEM_ERROR;
                         ELSIF (lcu_get_unprocessed_ctype_rec.consigned IS NULL) THEN
                             gc_error_msg := 'For Change Id: ' || lcu_get_unprocessed_ctype_rec.change_id || ' The Consigned Supplier: ' || lcu_get_unprocessed_ctype_rec.vendor_id||' is Invalid.';
                             RAISE EX_ITEM_ERROR;
                         ELSIF (lcu_get_unprocessed_ctype_rec.buyback IS NULL) THEN
                             gc_error_msg := 'For Change Id: ' || lcu_get_unprocessed_ctype_rec.change_id || ' The Buy Back Supplier: '  || lcu_get_unprocessed_ctype_rec.buy_back_vendor_id || ' is Invalid.';
                             RAISE EX_ITEM_ERROR;
                         END IF;

                         INSERT_MTI_ROW(p_xgcc_rec => lcu_get_unprocessed_ctype_rec);

                         --It is a successful record
                         gt_succ_rec_table(ln_log_index).success_rec  := lcu_get_unprocessed_ctype_rec;
                         gt_succ_rec_table(ln_log_index).print_flag   := 'Y';

                         ln_log_index := ln_log_index + 1;

                         UPDATE_XGCC_ROW(p_row_id         => lcu_get_unprocessed_ctype_rec.rowid 
                                        ,p_processed_flag => 'Y'
                                        );

                         gn_rec_inserted := gn_rec_inserted + 1 ;
                         fnd_file.put_line (fnd_file.log,'---------------------------------------------------------');

                     END IF;
                     --If change_type is PO Cost Change, ENDS

                 EXCEPTION
                     WHEN EX_ITEM_ERROR THEN
                     ROLLBACK TO NEW_ITEM;
                     fnd_file.put_line (fnd_file.log,gc_error_msg);
                     fnd_file.put_line (fnd_file.log,'EXCEPTION EX_ITEM_ERROR for Change Id' || lcu_get_unprocessed_ctype_rec.change_id);
                     fnd_file.put_line (fnd_file.log,'---------------------------------------------------------');
                     lc_exception_raised := 'Y';

                     gt_failed_rec_table(ln_index)                   := lcu_get_unprocessed_ctype_rec;
                     gt_failed_rec_table(ln_index).processed_flag    := 'E';
                     gt_failed_rec_table(ln_index).process_date      := SYSDATE;

                     IF (lcu_get_unprocessed_ctype_rec.consigned IS NULL OR lcu_get_unprocessed_ctype_rec.buyback IS NULL) THEN
                         gt_failed_rec_table(ln_index).error_code        := 'Invalid Supplier';
                     ELSE
                         gt_failed_rec_table(ln_index).error_code        := 'API ERROR';
                     END IF;

                     gt_failed_rec_table(ln_index).error_explanation := gc_error_msg;

                     ln_index      := ln_index + 1 ;
                     gn_rec_failed := gn_rec_failed + 1;

                 END;
                 --Anonymous Block Ends

             END LOOP;
             --Fetch all unprocessed rows of the given change_type, Loop ENDS

         END IF;
         --If Count of rows is greater than Consign Max Item Limit DFF, ENDS

         --If there are Failed Records,Mark all rolled back records as errored
         IF (gt_failed_rec_table.COUNT > 0 ) THEN
             FOR ln_counter IN gt_failed_rec_table.FIRST .. gt_failed_rec_table.LAST
             LOOP

                 fnd_file.put_line(fnd_file.log,'Updating Consign Changes record from failed table ' || gt_failed_rec_table(ln_counter).change_id|| ' as Errored');

                 UPDATE_XGCC_ROW(p_row_id            => gt_failed_rec_table(ln_counter).row_id 
                                ,p_processed_flag    => 'E'
                                ,p_error_code        => gt_failed_rec_table(ln_counter).error_code
                                ,p_error_explanation => gt_failed_rec_table(ln_counter).error_explanation
                                );

                FOR  ln_log_counter IN gt_succ_rec_table.FIRST .. gt_succ_rec_table.LAST
                LOOP

                    IF (gt_succ_rec_table(ln_log_counter).success_rec.inventory_item_id  = gt_failed_rec_table(ln_counter).inventory_item_id
                        AND gt_succ_rec_table(ln_log_counter).success_rec.processed_flag <> 'E') 
                    THEN

                        fnd_file.put_line(fnd_file.log,'Updating Consign Changes record from success table ' || gt_succ_rec_table(ln_log_counter).success_rec.change_id|| ' as Errored');

                        gt_succ_rec_table(ln_log_counter).print_flag        := 'N';
                        gt_succ_rec_table(ln_log_counter).success_rec.processed_flag    := 'E';
                        gt_succ_rec_table(ln_log_counter).success_rec.error_code        := gt_failed_rec_table(ln_counter).error_code;
                        gt_succ_rec_table(ln_log_counter).success_rec.error_explanation := 'Exception was raised for this Item Previously.';
                        gt_succ_rec_table(ln_log_counter).success_rec.process_date      := SYSDATE;

                        UPDATE_XGCC_ROW(p_row_id            => gt_succ_rec_table(ln_log_counter).success_rec.row_id 
                                       ,p_processed_flag    => 'E'
                                       ,p_error_code        => gt_failed_rec_table(ln_counter).error_code
                                       ,p_error_explanation => 'Exception was raised for this Item Previously.'
                                        );

                        gn_rec_failed   := gn_rec_failed + 1;
                        gn_rec_inserted := gn_rec_inserted - 1;

                    END IF;
                 END LOOP;
                 --gt_succ_rec_table Loop Ends

             END LOOP;
             --gt_failed_rec_table Loop Ends

         END IF;
         --if there are Failed Records Ends

         PRINT_LOG_OUTPUT_FOOTER;

COMMIT;

EXCEPTION
    WHEN EX_MAX_LIMIT THEN
    fnd_file.put_line (fnd_file.log,'EXCEPTION EX_MAX_LIMIT in Procedure PROCESS_UPDATE_WAC.');
    COMMIT;
    PRINT_LOG_OUTPUT_FOOTER;

    WHEN EX_END_PROC THEN
    fnd_file.put_line (fnd_file.log,'EXCEPTION EX_END_PROC in Procedure PROCESS_UPDATE_WAC.');
    fnd_file.put_line (fnd_file.log,gc_error_msg);
    gn_rec_inserted := 0;
    gn_rec_bypassed := 0;
    gn_rec_failed   := 0;
    PRINT_LOG_OUTPUT_FOOTER;

    WHEN OTHERS THEN
    fnd_file.put_line (fnd_file.log,'EXCEPTION WHEN OTHERS in Procedure PROCESS_UPDATE_WAC.');
    fnd_file.put_line (fnd_file.log,gc_error_msg);
    gn_rec_inserted := 0;
    ROLLBACK;
    UPDATE_XGCC_ROW(p_row_id            => gr_xgcc_rec.row_id
                   ,p_processed_flag    => 'E'
                   ,p_error_code        => SQLCODE
                   ,p_error_explanation => 'Exception When Others in PROCESS_UPDATE_WAC.' || gc_error_msg
                   );
    PRINT_LOG_OUTPUT_FOOTER;
    COMMIT;



END PROCESS_UPDATE_WAC;

END  XX_GI_CONSIGN_CONV_CAP_PKG;
/
SHOW ERRORS;

EXIT;
