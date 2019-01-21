create or replace
PACKAGE BODY XX_AR_CREATE_ACCT_MASTER_PKG
AS

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_CREATE_ACCT_MASTER_PKG                                 |
-- | RICE ID :  E0080                                                    |
-- | Description : The master will call the child (E0080B) based on the  |
-- |               batching logic and then submitting auto invoice master|
-- |               program and E0080A,E0081, XX_AR_EXCL_HED_INVOICES     |
-- |               and Prepayments Matching Program                      |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version    Date         Author         Remarks                       |
-- |=========  ===========  =============  ============================= |
-- | 11.4      17-AUG-2011  R.Aldridge     Defect 13212 - add hint       |
-- |                                                                     |
-- | 12.0      24-OCT-2012  R.Aldridge     Defect 20687 - Enable batch   |
-- |                                       group processing              |
-- | 12.1	     08-JUL-2013  Manasa			   E0080- R12 Upgrade Retrofit   |
-- |                                       changes                       |
-- | 12.2	     21-OCT-2015 Vasu Raparla		 Removed Schema References	   |
-- +=====================================================================+

-- +=====================================================================+
-- +=====================================================================+
-- | Name :  XX_AR_CREATE_ACCT_MASTER_PROC                               |
-- | Description : The procedure will call the child (E0080B) based on   |
-- |               the batching logic and then submitting auto invoice   |
-- |               master program and E0080A,E0081,                      |
-- |               XX_AR_EXCL_HED_INVOICES and                           |
-- |               Prepayments Matching Program                          |
-- | Parameters :p_batch_source,p_max_thread_count,p_batch_size,         |
-- |             p_display_log,p_error_message,p_number_of_instances,    |
-- |             ,p_rerun_flag,p_email_address,p_autoinvoice_batch_source|
-- |             ,p_sleep and p_wait_time                                |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

gn_msg_cnt                NUMBER := 1;
gn_ret_count              NUMBER := 0;

PROCEDURE XX_AR_CREATE_ACCT_MASTER_PROC(
                                        x_err_buff                  OUT VARCHAR2
                                       ,x_ret_code                  OUT NUMBER
                                       ,p_org_id                    IN  NUMBER
                                       ,p_batch_group               IN  VARCHAR2   -- Added for Defect 20687
                                       ,p_batch_source              IN  VARCHAR2 DEFAULT NULL
                                       ,p_max_thread_count          IN  NUMBER
                                       ,p_batch_size                IN  NUMBER
                                       ,p_display_log               IN  VARCHAR2 DEFAULT 'N'
                                       ,p_error_message             IN  VARCHAR2 DEFAULT 'N'
                                       ,p_number_of_instances       IN  NUMBER
                                       ,p_rerun_flag                IN  VARCHAR2
                                       ,p_email_address             IN  VARCHAR2 DEFAULT NULL
                                       ,p_autoinvoice_batch_source  IN  VARCHAR2
                                       ,p_check_record              IN  VARCHAR2 DEFAULT 'N'
                                       ,p_sleep_time                IN  NUMBER
                                       ,p_wave_number               IN  VARCHAR2
                                       )
AS

      XX_EXP_NO_BATCH_NAME      EXCEPTION;
      -- Local Variable declaration
      ln_autoinv_req_id         NUMBER(15);
      ln_count                  NUMBER;
      ln_index                  NUMBER;
      ln_del_flag               NUMBER := 0;
      ln_last_sales_order       ra_interface_lines_all.sales_order%TYPE;
      ln_master_req_id          NUMBER(15);
      ln_org_id                 NUMBER;
      ln_rowcount               NUMBER;
      ln_request_id             NUMBER(15);
      ln_thread_count           NUMBER;
      ln_upper                  NUMBER;
      lc_attribute_category     xx_fin_translatevalues.target_value1%TYPE;
      lc_country_value          xx_fin_translatevalues.source_value1%TYPE;
      lc_error_msg              VARCHAR2(4000);
      lc_error_loc              VARCHAR2(2000);
      lc_last_row_id            VARCHAR2(255);
      lc_ou_name                hr_operating_units.name%TYPE;

      lc_start_flag             VARCHAR2(100);
      lb_mode                   BOOLEAN;
      lb_print_option           BOOLEAN;
      ln_HVOP_count             NUMBER;

      ln_AI_count               NUMBER :=4;
      ln_AI_thread_count        NUMBER :=0;
      ln_number_of_instances    NUMBER :=0;
      lc_temp_batch_source      ra_interface_lines_all.batch_source_name%type;
      ln_batch_source_id        NUMBER;

      TYPE rail_rec IS RECORD(
                            sales_order ra_interface_lines_all.sales_order%TYPE
                           ,row_id      VARCHAR2(30)
                             );

      TYPE t_rail_so     IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
      TYPE t_rail_rowid  IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;

      r_rail      rail_rec;
      t_so        t_rail_so;
      t_rowid     t_rail_rowid;


      -- Cursor Declaration for ra_interface_lines_all Table
      CURSOR lcu_so (p_batch_source VARCHAR2)
      IS

         SELECT ril.sales_order                                                 --Added cursor 11.3 POS SDR
               ,ril.rowid ROW_ID
           FROM ra_interface_lines_all      ril
               ,xx_fin_translatedefinition td
               ,xx_fin_translatevalues     tv
          WHERE ril.request_id        = -1
            AND ril.batch_source_name = NVL(p_batch_source , ril.batch_source_name)
            AND ril.interface_line_attribute3 <> 'SUMMARY'                      -- Add 11.3  POS SDR exclude POS summary errors
            AND ril.org_id            = FND_PROFILE.VALUE('ORG_ID')
            AND ril.batch_source_name =  tv.target_value1
            AND tv.translate_id = td.translate_id                               -- add for defect
            AND td.translation_name   = 'OD_AR_INVOICING_DEFAULTS'
            AND td.enabled_flag       = 'Y'
            AND tv.enabled_flag       = 'Y'
            -- Added condition for Defect 20687
            AND tv.target_value6      = p_batch_group
            ORDER BY sales_order;


   BEGIN

   ln_org_id  := p_org_id;                                                -- Added 11.3 POS SDR

   ln_AI_count := NVL(FND_PROFILE.value('XX_AR_AI_THREAD_COUNT'),4);

   IF (NVL(FND_CONC_GLOBAL.request_data,'0') = '0')  THEN

      BEGIN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Wave Number : '||p_wave_number);
         FND_FILE.PUT_LINE(FND_FILE.LOG,'request_data='||FND_CONC_GLOBAL.request_data);


         --to update all auto invoice error records.
         UPDATE ra_interface_lines_all RIL
            SET RIL.request_id        = -1
          WHERE (RIL.request_id <> -1 OR RIL.request_id IS NULL)
            AND RIL.batch_source_name =  NVL(p_batch_source , RIL.batch_source_name)      -- Added 11.3 POS SDR
            AND RIL.interface_line_attribute3 <> 'SUMMARY'                            -- Add 11.3  POS SDR exclude POS summary errors
            AND RIL.org_id            =  ln_org_id
            -- Added condition for Defect 20687
            AND EXISTS (SELECT 1
                          FROM xx_fin_translatedefinition td
                              ,xx_fin_translatevalues     tv
                         WHERE td.translation_name = 'OD_AR_INVOICING_DEFAULTS'
                           AND tv.translate_id  = td.translate_id
                           AND td.enabled_flag  = 'Y'
                           AND tv.enabled_flag  = 'Y'
                           AND tv.target_value6 = p_batch_group
                           AND tv.target_value1 = ril.batch_source_name);

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Number of records updated for reprocessing:'
                           ||SQL%ROWCOUNT);


         --Below queries to fetch the operating_unit_name from translation

         SELECT name
         INTO   lc_ou_name
         FROM   hr_operating_units
         WHERE  organization_id = FND_PROFILE.VALUE('ORG_ID');

         SELECT VAL.source_value1
         INTO   lc_country_value
         FROM   xx_fin_translatedefinition DEF
               ,xx_fin_translatevalues     VAL
         WHERE  DEF.translate_id     = VAL.translate_id
         AND    DEF.translation_name = 'OD_COUNTRY_DEFAULTS'
         AND    VAL.target_value2    = lc_ou_name;

         BEGIN


             -- 0$ Tax Lines
             DELETE FROM ra_interface_lines_all RIL
                   WHERE RIL.org_id = ln_org_id
                     AND RIL.interface_line_context = 'ORDER ENTRY'
                     AND RIL.request_id = -1
                     AND RIL.batch_source_name = NVL(p_batch_source,RIL.batch_source_name) -- added 11.3 SDR
                     AND RIL.line_type = 'TAX'
                     -- Added condition for Defect 20687
                     AND EXISTS (SELECT 1
                                   FROM xx_fin_translatedefinition TD
                                       ,xx_fin_translatevalues     TV
                                  WHERE TD.translation_name = 'OD_AR_INVOICING_DEFAULTS'
                                    AND TV.translate_id  = td.translate_id
                                    AND TD.enabled_flag  = 'Y'
                                    AND TV.enabled_flag  = 'Y'
                                    AND TV.target_value6 = p_batch_group
                                    AND TV.target_value1 = RIL.batch_source_name);


             -- Added the below query to delete the records from
             -- RA_INTERFACE_DISTRIBUTIONS_ALL that were rejected by auto invoice
             DELETE FROM ra_interface_distributions_all RID
                   WHERE RID.org_id                 = ln_org_id
                     AND RID.interface_line_context = 'ORDER ENTRY'
                     AND RID.interface_line_id IN (SELECT RIL.interface_line_id
                                                     FROM ra_interface_lines_all RIL
                                                    WHERE RIL.request_id             = -1
                                                      AND RIL.batch_source_name = NVL(p_batch_source,RIL.batch_source_name) -- added 11.3 SDR
                                                      AND RIL.org_id                 = ln_org_id
                                                      AND RIL.interface_line_context = 'ORDER ENTRY'
                                                      -- Added condition for Defect 20687
                                                      AND EXISTS (SELECT 1
                                                                    FROM xx_fin_translatedefinition TD
                                                                        ,xx_fin_translatevalues     TV
                                                                   WHERE TD.translation_name = 'OD_AR_INVOICING_DEFAULTS'
                                                                     AND TV.translate_id  = td.translate_id
                                                                     AND TD.enabled_flag  = 'Y'
                                                                     AND TV.enabled_flag  = 'Y'
                                                                     AND TV.target_value6 = p_batch_group
                                                                     AND TV.target_value1 = RIL.batch_source_name));

             FND_FILE.PUT_LINE(FND_FILE.LOG,'Total records deleted from '
                                   ||'RA_INTERFACE_DISTRIBUTIONS_ALL '
                                   || 'that were rejected by Auto invoice:'
                                   ||SQL%ROWCOUNT);

         EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_del_flag := 1;
             WHEN OTHERS THEN
                ln_del_flag := 1;
        END;

        --Modified and tuned on 03-Apr-2008 to delete only records for 'ORDER ENTRY'
        --The below query will delete data from distributions based on interface line attributes.

        -- IF statement for deleting from distributions
        IF ((ln_del_flag = 0) OR (ln_del_flag = 1)) THEN

             BEGIN
                 -- Defect 12540 - removed delete and replaced with below
                 -- Defect 13212 - added hint due to resolve peformance issue
                 DELETE FROM ra_interface_distributions_all RIDA
                       WHERE RIDA.org_id                 = ln_org_id
                         AND RIDA.interface_line_context = 'ORDER ENTRY'
                         AND EXISTS (SELECT /*+ INDEX(RI XX_RA_INTERFACE_LINES_N1)*/ 1
                                       FROM ra_interface_lines_all RI
                                      WHERE RI.request_id             = - 1
                                        AND RI.batch_source_name      = NVL(p_batch_source, RI.batch_source_name)
                                        AND RI.org_id                 = RIDA.org_id
                                        AND RI.interface_line_context = RIDA.interface_line_context
                                        AND RI.sales_order            = RIDA.interface_line_attribute1
                                        -- Added condition for Defect 20687
                                        AND EXISTS (SELECT 1
                                                      FROM xx_fin_translatedefinition TD
                                                          ,xx_fin_translatevalues     TV
                                                     WHERE TD.translation_name = 'OD_AR_INVOICING_DEFAULTS'
                                                       AND TV.translate_id  = td.translate_id
                                                       AND TD.enabled_flag  = 'Y'
                                                       AND TV.enabled_flag  = 'Y'
                                                       AND TV.target_value6 = p_batch_group
                                                       AND TV.target_value1 = RI.batch_source_name));

                 FND_FILE.PUT_LINE(FND_FILE.LOG,
                          'Total number of records deleted'
                          || 'from RA_INTERFACE_DISTRIBUTIONS_ALL: '
                          ||SQL%ROWCOUNT);
                 COMMIT;

              EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                      FND_MESSAGE.SET_TOKEN('COL','DELETING FROM RA_INTERFACE_DISTRIBUTIONS_ALL');
                      lc_error_msg := FND_MESSAGE.GET;
                      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);

                       XX_COM_ERROR_LOG_PUB.LOG_ERROR
                             (
                              p_program_type            => 'CONCURRENT PROGRAM'
                             ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Master'
                             ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                             ,p_module_name             => 'AR'
                             ,p_error_location          => 'Oracle Error '||SQLERRM
                             ,p_error_message_count     => gn_msg_cnt
                             ,p_error_message_code      => 'E'
                             ,p_error_message           => lc_error_msg
                             ,p_error_message_severity  => 'Major'
                             ,p_notify_flag             => 'N'
                             ,p_object_type             => 'Splitting into Batches'
                             );

                 WHEN OTHERS THEN
                    FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                    FND_MESSAGE.SET_TOKEN('COL','DELETING FROM RA_INTERFACE_DISTRIBUTIONS_ALL');
                    lc_error_msg := FND_MESSAGE.GET || SQLERRM;
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
                    XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                           p_program_type            => 'CONCURRENT PROGRAM'
                          ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Master'
                          ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                          ,p_module_name             => 'AR'
                          ,p_error_location          => 'Oracle Error '||SQLERRM
                          ,p_error_message_count     => gn_msg_cnt + 1
                          ,p_error_message_code      => 'E'
                          ,p_error_message           => lc_error_msg
                          ,p_error_message_severity  => 'Major'
                          ,p_notify_flag             => 'N'
                         ,p_object_type             => 'Splitting into Batches'
                                    );
              END;

           END IF;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
             FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
             FND_MESSAGE.SET_TOKEN('COL','Attribute Category');
             lc_error_msg := FND_MESSAGE.GET;
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
             XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'CONCURRENT PROGRAM'
                                      ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Master'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'AR'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => gn_msg_cnt
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_error_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'Splitting into Batches'
                                      );
         WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
            FND_MESSAGE.SET_TOKEN('COL','Attribute Category');
            lc_error_msg := FND_MESSAGE.GET || SQLERRM;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);
            XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Master'
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Oracle Error '||SQLERRM
                                     ,p_error_message_count     => gn_msg_cnt + 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => lc_error_msg
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Splitting into Batches'
                                     );
      END;

   END IF;

   IF (TO_NUMBER(SUBSTR(FND_CONC_GLOBAL.request_data,-1),'9') = '3')  THEN

        -- added parameter for defect 20687
        XX_AR_POST_UPDATES_PROC(p_batch_group              => p_batch_group
                               ,p_batch_source             => p_batch_source
                               ,p_display_log              => p_display_log
                               ,p_error_message            => p_error_message
                               ,p_rerun_flag               => p_rerun_flag
                               ,p_email_address            => p_email_address
                               ,p_autoinvoice_batch_source => p_autoinvoice_batch_source
                               ,p_request_id                =>
                                        TO_NUMBER(SUBSTR(FND_CONC_GLOBAL.request_data,1,
                                                         INSTR(FND_CONC_GLOBAL.request_data,'~',1,1)-1
                                                        )
                                                 )
                               ,p_org_id                   =>  p_org_id
                               );

         IF (p_check_record ='Y') THEN
              -- Added parameter for Defect 20687
              XX_HVOP_RUNNING_CHECK_PROC( p_sleep_time   => p_sleep_time
                                         ,p_batch_source => p_batch_source
                                         ,p_batch_group  => p_batch_group
                                        );
         END IF;

         IF (gn_ret_count = 1) THEN
               GOTO MAIN_LOOP;
         END IF;

         x_err_buff := 'COMPLETED MASTER PROGRAM';
         x_ret_code := XX_AR_STATUS_FUNC();
         RETURN;

    END IF;

   IF (SUBSTR(FND_CONC_GLOBAL.request_data,-1) = '1'
              OR SUBSTR(FND_CONC_GLOBAL.request_data,-1) = '2')  THEN

           BEGIN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'request_data='
                                     ||FND_CONC_GLOBAL.request_data);

              --------------------------------------------------------
              -- select the batch_source_id for passing it as a
              -- parameter to the auto invoice master program.
              -- **************WARNING***************************************
              -- As part of release 11.3 SDR a join to the OD_AR_INVOICING_DEFAULTS
              -- was added to only import non POS_US data. If a new batch source name
              -- other then SALES_ACCT_US, SALES_ACCT_CA, POS_US or POS_CA is attempted
              -- this current logic will not work. If a new source is to be used
              --, looping logic in this program will need to be redesigned.
              -----------------------------------------------------------------
              SELECT DISTINCT RS.batch_source_id
                    ,TV.target_value1
                INTO ln_batch_source_id
                    ,lc_temp_batch_source                                 --added summary_flg 11.3 POS SDR
                FROM xx_fin_translatedefinition  TD
                    ,xx_fin_translatevalues      TV
                    ,ra_batch_sources_all        RS
               WHERE TD.translation_name = 'OD_AR_INVOICING_DEFAULTS'
                 AND RS.name          = TV.target_value1
                 AND TV.translate_id  = TD.translate_id
                 AND TV.source_value1 = (SELECT NAME
                                           FROM hr_all_organization_units
                                          WHERE organization_id  = p_org_id)
                 AND TV.target_value3  = 'N'
                 AND TD.enabled_flag   = 'Y'
                 AND TV.enabled_flag   = 'Y'
                 -- Added condition for Defect 20687
                 AND TV.target_value6  = p_batch_group;

                FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_temp_batch_source'||
                                    ' is ' ||lc_temp_batch_source);


                FND_FILE.PUT_LINE(FND_FILE.LOG,'Retrieving ln_batch_source_id'
                                      || 'from ra_batch_sources_all');

                SELECT batch_source_id
                  INTO ln_batch_source_id
                  FROM ra_batch_sources_all
                 WHERE name = NVL(p_batch_source,lc_temp_batch_source)
                   AND org_id = ln_org_id;


                FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_batch_source_id'||
                                        ' = ' ||ln_batch_source_id);

            EXCEPTION
                WHEN NO_DATA_FOUND THEN

                   FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0010_CREATE_ACT_NO_DATA');
                   FND_MESSAGE.SET_TOKEN('COL','BATCH SOURCE ID');
                   lc_error_msg := FND_MESSAGE.GET;
                   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,lc_error_msg);

                   XX_COM_ERROR_LOG_PUB.LOG_ERROR
                            (
                             p_program_type            => 'CONCURRENT PROGRAM'
                            ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Master'
                            ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                            ,p_module_name             => 'AR'
                            ,p_error_location          => 'Oracle Error '||SQLERRM
                            ,p_error_message_count     => gn_msg_cnt
                            ,p_error_message_code      => 'E'
                            ,p_error_message           => lc_error_msg
                            ,p_error_message_severity  => 'Major'
                            ,p_notify_flag             => 'N'
                            ,p_object_type             => 'Splitting into Batches'
                            );

                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'No Data Found Exception '
                                          ||'Looking up Batch name' ||SQLERRM);

                   RAISE XX_EXP_NO_BATCH_NAME;

                WHEN OTHERS THEN
                  FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
                  FND_MESSAGE.SET_TOKEN('COL','BATCH SOURCE ID');
                  lc_error_msg := FND_MESSAGE.GET || SQLERRM;

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR(
                           p_program_type            => 'CONCURRENT PROGRAM'
                          ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Master'
                          ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                          ,p_module_name             => 'AR'
                          ,p_error_location          => 'Oracle Error '||SQLERRM
                          ,p_error_message_count     => gn_msg_cnt + 1
                          ,p_error_message_code      => 'E'
                          ,p_error_message           => lc_error_msg
                          ,p_error_message_severity  => 'Major'
                          ,p_notify_flag             => 'N'
                          ,p_object_type             => 'Splitting into Batches'
                           );

                   FND_FILE.PUT_LINE(FND_FILE.LOG, 'When Others Exception '
                                          ||'Looking up Batch name' ||SQLERRM);

                   RAISE XX_EXP_NO_BATCH_NAME;


               END;


               IF (SUBSTR(FND_CONC_GLOBAL.request_data,-1) = '2')  THEN

                   FND_FILE.PUT_LINE(FND_FILE.LOG,'befor post updates--request_data='
                                      ||FND_CONC_GLOBAL.request_data);

                   -- added parameter for defect 20687
                   XX_AR_POST_UPDATES_PROC
                          (p_batch_group              => p_batch_group
                          ,p_batch_source             => p_batch_source
                          ,p_display_log              => p_display_log
                          ,p_error_message            => p_error_message
                          ,p_rerun_flag               => p_rerun_flag
                          ,p_email_address            => p_email_address
                          ,p_autoinvoice_batch_source => p_autoinvoice_batch_source
                          ,p_request_id               =>
                          TO_NUMBER(SUBSTR(FND_CONC_GLOBAL.request_data,1,
                                INSTR(FND_CONC_GLOBAL.request_data,'~',1,1)-1))
                          ,p_org_id                     => p_org_id
                          ); -- Added for defect #2472
              END IF;

              FND_FILE.PUT_LINE(FND_FILE.LOG,'before auto invoice request_data='
                                    ||FND_CONC_GLOBAL.request_data);

              -- Submitting Auto Invoice Master Program.
              lb_print_option := fnd_request.set_print_options(printer => NULL
                                                              ,copies  => 0
                                                              );

              IF (lb_print_option = TRUE) THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG,
                            'Return Value from Printer Options Set: '||'TRUE');
              ELSE
                  FND_FILE.PUT_LINE(FND_FILE.LOG,
                           'Return Value from Printer Options Set: '||'FALSE');
              END IF;

              ln_AI_thread_count := 0;

              ln_AI_thread_count :=
                      TO_NUMBER(SUBSTR(FND_CONC_GLOBAL.request_data,
                                          INSTR(FND_CONC_GLOBAL.request_data,'~',1,1) + 1,
                                             (INSTR(FND_CONC_GLOBAL.request_data,'~',1,2)
                                                   - INSTR(FND_CONC_GLOBAL.request_data,'~',1,1)
                                             )-1
                                      )
                                );

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Count of AutoInvoice '
                                     ||'threads submitted dynamically   : '
                                     ||ln_AI_thread_count);

      /*ln_autoinv_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                  application => 'AR'
                                 ,program     => 'RAXMTR'
                                 ,description => ''
                                 ,start_time  => ''
                                 ,sub_request => TRUE
                                 ,argument1   => ln_AI_thread_count
                                 ,argument2   => ln_batch_source_id
                                 ,argument3   => lc_temp_batch_source           -- p_batch_source
                                 ,argument4   => TO_CHAR(TRUNC(SYSDATE),'RRRR/MM/DD HH24:MI:SS')
                                 ,argument5   => ''
                                 ,argument6   => ''
                                 ,argument7   => ''
                                 ,argument8   => ''
                                 ,argument9   => ''
                                 ,argument10  => ''
                                 ,argument11  => ''
                                 ,argument12  => ''
                                 ,argument13  => ''
                                 ,argument14  => ''
                                 ,argument15  => ''
                                 ,argument16  => ''
                                 ,argument17  => ''
                                 ,argument18  => ''
                                 ,argument19  => ''
                                 ,argument20  => ''
                                 ,argument21  => ''
                                 ,argument22  => ''
                                 ,argument23  => ''
                                 ,argument24  => ''
                                 ,argument25  => 'Y'
                                 ,argument26  => ''
                                 ,argument27  => ln_org_id
                                 ,argument28  => CHR(0)
                                                     );*/
      --Changed for R12 Retrofit
		ln_autoinv_req_id := FND_REQUEST.SUBMIT_REQUEST(
                                  application => 'AR'
                                 ,program     => 'RAXMTR'
                                 ,description => ''
                                 ,start_time  => ''
                                 ,sub_request => TRUE
                                 ,argument1   => ln_AI_thread_count
                                 ,argument2   => ln_org_id
                                 ,argument3   => ln_batch_source_id
                                 ,argument4   => lc_temp_batch_source           -- p_batch_source
                                 ,argument5   => TO_CHAR(TRUNC(SYSDATE),'RRRR/MM/DD HH24:MI:SS')
                                 ,argument6   => ''
                                 ,argument7   => ''
                                 ,argument8   => ''
                                 ,argument9   => ''
                                 ,argument10  => ''
                                 ,argument11  => ''
                                 ,argument12  => ''
                                 ,argument13  => ''
                                 ,argument14  => ''
                                 ,argument15  => ''
                                 ,argument16  => ''
                                 ,argument17  => ''
                                 ,argument18  => ''
                                 ,argument19  => ''
                                 ,argument20  => ''
                                 ,argument21  => ''
                                 ,argument22  => ''
                                 ,argument23  => ''
                                 ,argument24  => ''
                                 ,argument25  => ''
                                 ,argument26  => 'Y'
                                 ,argument27  => ''
                                 ,argument28  => CHR(0)
                                                     );
          COMMIT;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'after auto invoice---request_data='
                             ||FND_CONC_GLOBAL.request_data);

          lc_start_flag := '2';
      END IF;


     <<MAIN_LOOP>>

         ln_thread_count := 0;
         ln_number_of_instances :=0;

     OPEN lcu_so(p_batch_source );

     <<THREAD_LOOP>>

      -- Loop for calling child prog based on the number of maximum thread count.
     WHILE ln_thread_count < p_max_thread_count
       LOOP
            BEGIN
                FETCH lcu_so BULK COLLECT INTO t_so,t_rowid LIMIT p_batch_size;

                 IF (NVL(t_rowid.FIRST,0) = 0 AND ln_thread_count <> 0
                                AND ln_thread_count < p_max_thread_count) THEN
                      EXIT THREAD_LOOP;
                 ELSIF (NVL(t_rowid.FIRST,0) = 0 AND ln_thread_count =0) THEN

                     --Make the master complete Normal when there are no records found during the very first run
                     IF (NVL(FND_CONC_GLOBAL.request_data,'0') = '0') THEN
                          IF (p_check_record ='Y') THEN
                                    -- Added parameter for Defect 20687
                                    XX_HVOP_RUNNING_CHECK_PROC (
                                                 p_sleep_time   => p_sleep_time
                                                ,p_batch_source => p_batch_source
                                                ,p_batch_group  => p_batch_group
                                                                );
                           END IF;
                                IF (gn_ret_count = 1) THEN
                                   IF lcu_so%ISOPEN THEN
                                           CLOSE lcu_so;
                                   END IF;

                                   GOTO MAIN_LOOP;

                                END IF;

                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'THERE WERE NO RECORDS FOR '||p_batch_source );
                        x_err_buff := 'COMPLETED MASTER PROGRAM SUCCESSFULLY-EXITING';
                        x_ret_code := 0;

                        RETURN;
                     END IF;

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'before last post update---request_data= '
                                                 ||FND_CONC_GLOBAL.request_data);

                     lc_start_flag := '3';

                     EXIT THREAD_LOOP;

                 ELSE
                     ln_upper            := t_so.last;
                     ln_last_sales_order := t_so(ln_upper);
                     ln_index            := ln_upper ;

                     <<BATCH_LOOP>>
                     -- Loop to check the remaining lines for a sales order number.
                     WHILE ln_last_sales_order = t_so(ln_index)
                      LOOP
                         ln_index            := ln_index + 1;
                          FETCH lcu_so  INTO r_rail;

                              IF lcu_so%NOTFOUND THEN
                                    EXIT BATCH_LOOP;
                              END IF;
                              t_rowid(ln_index)   := r_rail.ROW_ID; -- Add one record to t_rail table at the end.
                              t_so(ln_index)      := r_rail.sales_order;

                      END LOOP;         -- End of the batch_loop

                      ln_upper := ln_index-1;

                      lb_print_option := fnd_request.set_print_options(
                                                   printer           => NULL
                                                  ,copies            => 0 );

                      IF (lb_print_option = TRUE) THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG,
                                       'Return Value from Printer Options Set: '
                                       ||'TRUE');
                      ELSE
                         FND_FILE.PUT_LINE(FND_FILE.LOG,
                                       'Return Value from Printer Options Set: '
                                       ||'FALSE');
                      END IF;


                     -- Submit Create Accounting child processes (E0080B)
                     ln_request_id :=  FND_REQUEST.submit_request
                                           (
                                             'XXFIN'
                                            ,'XXARACCTC'
                                            ,NULL
                                            ,TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                            ,TRUE
                                            ,p_org_id
                                            ,'B'
                                            ,p_email_address
                                            ,NULL
                                            ,NULL
                                            ,p_display_log
                                            ,p_batch_group   -- added for defect 20687
                                            ,p_batch_source
                                            ,NULL
                                            ,p_error_message
                                            ,NULL
                                            );

                       IF NVL(ln_request_id,0) = 0 THEN
                        x_err_buff  := FND_MESSAGE.GET;
                        x_ret_code  := 2;
                        FND_FILE.PUT_LINE(FND_FILE.LOG,
                               'Child Request submission failed................'
                                          ||x_err_buff);
                        RETURN;

                     END IF;

                     --Update the request ids of the child requests in the
                     --request_id column of ra_interface_lines_all.
                     FORALL  ln_index IN 1..ln_upper
                     UPDATE  ra_interface_lines_all
                     SET     request_id = ln_request_id
                            ,trx_number = sales_order	-- Added this upfront in the master
			                      ,interface_status = NULL
                     WHERE   rowid      = t_rowid(ln_index);

                     COMMIT;

                     --Update the request_Id for the sales order that has been
                     --skipped in the previous fetch

                     UPDATE  ra_interface_lines_all
                     SET     request_id = ln_request_id
                            ,trx_number = sales_order
                     WHERE   rowid      = lc_last_row_id;
                     COMMIT;

                     lc_last_row_id  := r_rail.ROW_ID;
                     ln_thread_count := ln_thread_count + 1;
               END IF;
            EXCEPTION

            WHEN XX_EXP_NO_BATCH_NAME  THEN

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'WARNING******************** '
                                    ||'***********************************' );

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'If multi-rows are being '
                                    || 'returned confirm that  '
                                    || 'batch source names other then ');

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'SALES_ACCT_US, SALES_ACCT_CA,'
                                    ||'  POS_US or POS_CA do not exist on '
                                    ||' the ra_batch_sources_all') ;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Program current design will'
                                    ||'  only process SALES_ACCT_US, SALES_ACCT_CA'
                                    ||', POS_US or POS_CA') ;

                  FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************** '
                                    ||'***********************************' );
            WHEN OTHERS THEN
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_0011_CREATE_ACT_OTHERS');
            FND_MESSAGE.SET_TOKEN('COL','UPDATING REQUEST ID:'||ln_request_id
                                      ||'DUE TO MISMATCH OF ROW ID');
            lc_error_msg := FND_MESSAGE.GET;
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                          p_program_type            => 'CONCURRENT PROGRAM'
                         ,p_program_name            => 'OD: AR Create Autoinvoice Accounting Master'
                         ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                         ,p_module_name             => 'AR'
                         ,p_error_location          => 'Oracle Error '||SQLERRM
                         ,p_error_message_count     => gn_msg_cnt + 1
                         ,p_error_message_code      => 'E'
                         ,p_error_message           => lc_error_msg
                         ,p_error_message_severity  => 'Major'
                         ,p_notify_flag             => 'N'
                         ,p_object_type             => 'Splitting into Batches'
                                           );
            END;

       END LOOP;-- End of the thread count loop.


       ln_number_of_instances := ln_thread_count * ln_AI_count;

       IF lcu_so%ISOPEN THEN
              CLOSE lcu_so;
       END IF;




       IF lc_start_flag = '2' THEN
            lc_start_flag := ln_autoinv_req_id ||'~'||ln_number_of_instances||'~'||'2';
            FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>(lc_start_flag));
            COMMIT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING MASTER PROGRAM');
            x_err_buff := 'Restarted to submit post updates and auto invoice';
            x_ret_code := 0;
            RETURN;

       ELSIF   lc_start_flag = '3' THEN
            lc_start_flag := ln_autoinv_req_id ||'~'||ln_number_of_instances||'~'||'3';
            FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>(lc_start_flag));
            COMMIT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING MASTER PROGRAM');
            x_err_buff := 'Restarted to exit the master';
            x_ret_code := 0;
            RETURN;

      ELSE    lc_start_flag := '~'||ln_number_of_instances||'~'||'1';
            FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>(lc_start_flag));
            COMMIT;
            FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING MASTER PROGRAM');
            x_err_buff := 'Restarted to submit auto invoice';
            x_ret_code := 0;
            RETURN;

      END IF;


END XX_AR_CREATE_ACCT_MASTER_PROC;

-- +=====================================================================+
-- | Name :  XX_AR_POST_UPDATES_PROC                                     |
-- | Description : The procedure will call the post update programs      |
-- |               E0080A,E0081,XX_AR_EXCL_HED_INVOICES and              |
-- |               Prepayments Matching Program                          |
-- | Parameters :p_batch_source,p_display_log,p_error_message,           |
-- |             ,p_rerun_flag,p_email_address,p_autoinvoice_batch_source|
-- |             ,p_request_id                                           |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_AR_POST_UPDATES_PROC(
                                  p_batch_group               IN  VARCHAR2
                                 ,p_batch_source              IN  VARCHAR2
                                 ,p_display_log               IN  VARCHAR2 DEFAULT 'N'
                                 ,p_error_message             IN  VARCHAR2 DEFAULT 'N'
                                 ,p_rerun_flag                IN  VARCHAR2
                                 ,p_email_address             IN  VARCHAR2 DEFAULT NULL
                                 ,p_autoinvoice_batch_source  IN  VARCHAR2  --Added prepayments matching program for defect#4609
                                 ,p_request_id                IN  NUMBER
                                 ,p_org_id                    IN  NUMBER)
AS
   --Local variable declaration
   ln_request_id          NUMBER(15);
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);
   lb_req_status        BOOLEAN;
   lb_print_option      BOOLEAN;
   lc_operating_unit         xx_fin_translatevalues.source_value1%TYPE;
   lc_batch_group            xx_fin_translatevalues.target_value6%TYPE;
   lc_batch_source           xx_fin_translatevalues.target_value1%TYPE;
   lc_submit_prepay          xx_fin_translatevalues.target_value7%TYPE;
   lc_submit_remit_to_addr   xx_fin_translatevalues.target_value8%TYPE;
   lc_submit_hed             xx_fin_translatevalues.target_value9%TYPE;

   CURSOR lcu_conc_req(p_request_id NUMBER)
   IS
   SELECT  parent_request_id
          ,request_id
          ,request_date
          ,requested_start_date
          ,actual_start_date
          ,actual_completion_date
          ,phase_code
          ,status_code
          ,responsibility_id
          ,controlling_manager
          ,concurrent_program_id
   FROM   fnd_concurrent_requests
   WHERE  parent_request_id = p_request_id;

   BEGIN

      ---------------------------------------------
      -- Select Post Processing Settings  (Added condition for Defect 20687)
      ---------------------------------------------
      SELECT tv.source_value1   OPERATING_UNIT
            ,tv.target_value6   BATCH_GROUP
            ,tv.target_value1   BATCH_SOURCE
            ,tv.target_value7   SUBMIT_PREPAY
            ,tv.target_value8   SUBMIT_REMIT_TO_ADDR
            ,tv.target_value9   SUBMIT_HED
        INTO lc_operating_unit
            ,lc_batch_group
            ,lc_batch_source
            ,lc_submit_prepay
            ,lc_submit_remit_to_addr
            ,lc_submit_hed
        FROM xx_fin_translatedefinition  TD
            ,xx_fin_translatevalues      TV
       WHERE TD.translation_name = 'OD_AR_INVOICING_DEFAULTS'
         AND TV.translate_id  = TD.translate_id
         AND TV.source_value1 = (SELECT NAME
                                   FROM hr_all_organization_units
                                  WHERE organization_id  = p_org_id)
         AND TV.target_value3  = 'N'
         AND TD.enabled_flag   = 'Y'
         AND TV.enabled_flag   = 'Y'
         AND TV.target_value6  = p_batch_group;

     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Values Retrieved from OD_AR_INVOICING_DEFAULTS translation for batch group: '||p_batch_group);
     FND_FILE.PUT_LINE(FND_FILE.LOG, '     Operating Unit          (source_value1) : '||lc_operating_unit);
     FND_FILE.PUT_LINE(FND_FILE.LOG, '     Batch Group             (target_value6) : '||lc_batch_group);
     FND_FILE.PUT_LINE(FND_FILE.LOG, '     Batch Source            (target_value1) : '||lc_batch_source);
     FND_FILE.PUT_LINE(FND_FILE.LOG, '     Submit Prepay Matchint  (target_value7) : '||lc_submit_prepay);
     FND_FILE.PUT_LINE(FND_FILE.LOG, '     Submit Remit to Address (target_value8) : '||lc_submit_remit_to_addr);
     FND_FILE.PUT_LINE(FND_FILE.LOG, '     Submit Exclude HED      (target_value9) : '||lc_submit_hed);
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

     ---------------------------------------------
     -- Set Wait Interval
     ---------------------------------------------
     lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                      request_id  => p_request_id
                                                     ,interval    => '2'
                                                     ,max_wait    => ''
                                                     ,phase       => lc_phase
                                                     ,status      => lc_status
                                                     ,dev_phase   => lc_devphase
                                                     ,dev_status  => lc_devstatus
                                                     ,message     => lc_message
                                                     );



     ---------------------------------------------
     -- Submit AFTER Processing for E80 Child  (this is always submitted
     ---------------------------------------------
     lb_print_option := fnd_request.set_print_options(
                                                      printer           => NULL
                                                     ,copies            => 0
                                                      );

      IF (lb_print_option = TRUE) THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'TRUE');
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'FALSE');
      END IF;

      ln_request_id:=FND_REQUEST.submit_request(
                                               'XXFIN'
                                              ,'XXARACCTC'
                                              ,NULL
                                              ,TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                              ,TRUE
                                              ,p_org_id
                                              ,'A'
                                              ,p_email_address
                                              ,NULL
                                              ,NULL
                                              ,p_display_log
                                              ,p_batch_group
                                              ,p_batch_source
                                              ,NULL
                                              ,p_error_message
                                              ,p_request_id
                                              );
         COMMIT;


        ---------------------------------------------
        -- Submit Remit To Address Update using request id from FND_CONC_GLOBAL.request_data.
        ---------------------------------------------
        BEGIN
           IF lc_submit_remit_to_addr = 'Y' THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submit Remit To Address Update is set to Y.');
              lb_print_option := fnd_request.set_print_options(
                                                              printer           => NULL
                                                             ,copies            => 0
                                                             );

              IF (lb_print_option = TRUE) THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'TRUE');
              ELSE
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'FALSE');
              END IF;

              ln_request_id:=FND_REQUEST.submit_request(
                                                     'XXFIN'
                                                    ,'XX_AR_REMITC'
                                                    ,NULL
                                                    ,TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                                    ,FALSE
                                                    ,p_rerun_flag
                                                    ,NULL
                                                    ,NULL
                                                    ,NULL
                                                    ,NULL
                                                    ,p_request_id
                                                    );
               COMMIT;

               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Remit To Address Update submitted.  RID: '||ln_request_id);
            ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submit Remit To Address Update is set to N. ');
            END IF;
         END;

        ---------------------------------------------
        --Submit Prepayments Matching Program for the defect#4609.
        ---------------------------------------------
        BEGIN
           IF lc_submit_prepay = 'Y' THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submit Prepayment Matching is set to Y.');

              FOR lcu_conc_req_rec IN lcu_conc_req(p_request_id)
                 LOOP
                    lb_print_option := fnd_request.set_print_options(
                                                           printer           => NULL
                                                          ,copies            => 0
                                                            );

                     IF (lb_print_option = TRUE) THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'TRUE');
                     ELSE
                         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'FALSE');
                     END IF;

                  ln_request_id:=FND_REQUEST.submit_request(
                                                'AR'
                                                ,'ARPREMAT'
                                                ,NULL
                                                ,TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                                ,FALSE
                                                ,p_autoinvoice_batch_source
                                                ,lcu_conc_req_rec.request_id
                                                   );
                     COMMIT;
                     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Prepayment Matching submitted.  RID: '||ln_request_id);
                END LOOP;
           ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submit Prepayment Matching is set to N.');
           END IF;
        END;

        ---------------------------------------------
        -- Submit OD: AR Exclude HED Invoices From Consolidated Billing for the defect#4076.
        ---------------------------------------------
        BEGIN
           IF lc_submit_hed = 'Y' THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submit Exclude HED Invoices is set to Y.');
              lb_print_option := fnd_request.set_print_options( printer   => NULL
                                                                ,copies   => 0
                                                              );

              IF (lb_print_option = TRUE) THEN
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'TRUE');
              ELSE
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Return Value from Printer Options Set: '||'FALSE');
              END IF;

              ln_request_id:=FND_REQUEST.submit_request(
                                                   'XXFIN'
                                                  ,'XX_AR_EXCL_HED_INVOICES'
                                                  ,NULL
                                                  ,TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                                  ,FALSE
                                                  ,p_request_id
                                                  );
               COMMIT;
               FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exlude HED Invoices submitted.  RID: '||ln_request_id);
           ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submit Exclude HED Invoices is set to N.');
           END IF;
        END;

   END XX_AR_POST_UPDATES_PROC;

-- +=====================================================================+
-- | Name :  XX_AR_STATUS_FUNC                                           |
-- | Description : This function will derive and return the final status |
-- |              of the Master Program based on its child program status|
-- | Returns :  x_ret_code                                               |
-- +=====================================================================+
   FUNCTION XX_AR_STATUS_FUNC
   RETURN   NUMBER
   IS

        x_ret_code  NUMBER;
        ln_cnt_err  NUMBER := 0;
        ln_cnt_warn NUMBER := 0;

        CURSOR lcu_status
        IS
        SELECT FCR.request_id
              ,FCP.user_concurrent_program_name
              ,FCR.status_code
              ,FLP.meaning
        FROM   fnd_concurrent_requests    FCR
              ,fnd_concurrent_programs_vl FCP
              ,fnd_lookups                FLP
        WHERE  FCP.concurrent_program_id   = FCR.concurrent_program_id
        AND    FCR.program_application_id  = FCP.application_id
        AND    FLP.lookup_code             = FCR.status_code
        AND    FLP.lookup_type             = 'CP_STATUS_CODE'
        AND    FCP.concurrent_program_name IN ('XXARACCTC','RAXMTR','RAXTRX')
        AND    FCR.ARGUMENT1               <>'A'
        AND    FCR.priority_request_id     = FND_GLOBAL.CONC_REQUEST_ID
        ORDER BY FCR.request_id;

   BEGIN

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------CHILD PROGRAMS SUBMITTED-----------------------------------------------------------');

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('REQUEST ID',30,' ')
                                      ||RPAD('PROGRAM NAME',60,' ')
                                      ||RPAD('STATUS ',20,' '));

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-----------',30,' ')
                                      ||RPAD('------------------',60,' ')
                                      ||RPAD('----------------',20,' '));

     FOR lcu_status_req IN lcu_status
     LOOP

       IF lcu_status_req.status_code ='E' THEN

         ln_cnt_err := ln_cnt_err + 1;

       ELSIF lcu_status_req.status_code = 'G' THEN

         ln_cnt_warn := ln_cnt_warn + 1;

       END IF;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcu_status_req.request_id,30,' ')
                                      ||RPAD(lcu_status_req.user_concurrent_program_name,60,' ')
                                      ||RPAD(lcu_status_req.meaning,20,' '));

     END LOOP;

     IF ln_cnt_err > 0 THEN

        x_ret_code := 2;

        RETURN x_ret_code;

     ELSIF ln_cnt_warn > 0 AND ln_cnt_err = 0 THEN

        x_ret_code := 1;

        RETURN x_ret_code;

     ELSIF ln_cnt_warn = 0 AND ln_cnt_err = 0 THEN

        x_ret_code := 0;

        RETURN x_ret_code;

     END IF;

   END XX_AR_STATUS_FUNC;


--Added procedure for Defect # 10864

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- | Name : XX_HVOP_RUNNING_CHECK_PROC                                   |
-- +=====================================================================+
-- | Description :   To check if HVOP process is running when  E0080     |
-- |                 program polls  records.                             |
-- |  Parameters :   p_sleep_time, p_batch_source                        |
-- +=====================================================================+
PROCEDURE   XX_HVOP_RUNNING_CHECK_PROC(
                                       p_sleep_time    IN  NUMBER
                                      ,p_batch_source  IN  VARCHAR2
                                      ,p_batch_group   IN  VARCHAR2
                                       )
AS
    ln_count                 NUMBER := 0;
    ln_HVOP_count            NUMBER :=0;

  BEGIN
         LOOP
              ln_count :=0;
              SELECT count(*)
              INTO   ln_count
              FROM   fnd_concurrent_requests FCR
                     ,fnd_concurrent_programs FCP
                     ,fnd_profile_options FPO
                     ,fnd_profile_option_values FPOV
              WHERE  FCR.concurrent_program_id   = FCP.concurrent_program_id
              AND    FCP.concurrent_program_name IN ('XXOMSASTRI','OEOIMP')--,'XXOMSASIMP') --Defect #10864
              AND    FPO.profile_option_name = 'ORG_ID'
              AND    FPO.profile_option_id= FPOV.profile_option_id
              AND    FPOV.level_value = FCR.responsibility_id
              AND    FPOV.profile_option_value = FND_PROFILE.VALUE('ORG_ID')
              AND    FCR.phase_code IN ('P','R');

              ln_HVOP_count :=0;
              gn_ret_count := 0;

              SELECT /*+ parallel(ra_interface_lines_all,8) */ COUNT(*)
                INTO ln_HVOP_count
                FROM ra_interface_lines_all RIL
               WHERE RIL.request_id        = -1
                 AND RIL.batch_source_name = NVL(p_batch_source, RIL.batch_source_name) -- added per 11.3  SDR
                 AND RIL.org_id = FND_PROFILE.VALUE('ORG_ID')
                 -- Added condition for Defect 20687
                 AND EXISTS (SELECT 1
                               FROM xx_fin_translatedefinition TD
                                   ,xx_fin_translatevalues     TV
                              WHERE TD.translation_name = 'OD_AR_INVOICING_DEFAULTS'
                                AND TV.translate_id  = TD.translate_id
                                AND TD.enabled_flag  = 'Y'
                                AND TV.enabled_flag  = 'Y'
                                AND TV.target_value6 = p_batch_group
                                AND TV.target_value1 = RIL.batch_source_name);

              --To check if records are inserted in Interface table when HVOP is NOT COMPLETED
              IF (ln_count > 0) THEN
                  IF (ln_HVOP_count >0) THEN
                     gn_ret_count := 1;
                     EXIT;
                  ELSE
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'E0080 is waiting for HVOP');
                     dbms_lock.sleep(p_sleep_time);
                  END IF;
              --To check if records are inserted in Interface table when HVOP is COMPLETED
              ELSE
                  IF (ln_HVOP_count >0) THEN
                     gn_ret_count := 1;
                     EXIT;
                  ELSE
                     EXIT;
                  END IF;
              END IF;
         END LOOP;


  END XX_HVOP_RUNNING_CHECK_PROC;

END XX_AR_CREATE_ACCT_MASTER_PKG;
/