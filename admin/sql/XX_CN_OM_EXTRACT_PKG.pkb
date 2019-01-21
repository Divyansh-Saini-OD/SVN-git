CREATE OR REPLACE PACKAGE BODY XX_CN_OM_EXTRACT_PKG AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                Oracle NAIO Consulting Organization                             |
-- +================================================================================+
-- | Name       : XX_CN_OM_EXTRACT_PKG                                              |
-- |                                                                                |
-- | Rice ID    : E1004B_CustomCollections_(OM_Extract)                             |
-- | Description: Package body to extract the closed sales order data               |
-- |              and insert it into XX_CN_NOT_TRX and XX_CN_OM_TRX tables          |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                 Remarks                           |
-- |========  ===========  =============          ===============================   |
-- |DRAFT 1A  03-OCT-2007  Hema Chikkanna         Initial draft version             |
-- |DRAFT 1B  10-OCT-2007  Hema Chikkanna         Incorporated changes after review |
-- |DRAFT 1C  16-OCT-2007  Hema Chikkanna         Incorporated changes after onsite |
-- |                                              review                            |
-- |1.0       15-OCT-2007  Hema Chikkanna         Incorporated changes after Testing|
-- |1.1       24-OCT-2007  Sarah Justina          Incorporated Onsite SQL Comments  |
-- |1.2       29-OCT-2007  Hema Chikkanna         Incorporated the changes for      |
-- |                                              Interface logic                   |
-- |1.3       02-NOV-2007  Hema Chikkanna         Incorporated code for Error       |
-- |                                              Reporting,Party site ID Derivation|
-- |                                              and log error procedure           |
-- |1.4       12-NOV-2007  Hema Chikkanna         Incorporated error reporting      |
-- |                                              changes.                          |
-- +================================================================================+



-- Global variables decalration

-- Global Constants
G_EVENT_ID              CONSTANT NUMBER             := CN_GLOBAL.ord_event_id;
G_SRC_DOC_TYPE          CONSTANT VARCHAR2(4)        := 'OM';
G_CHILD_PROG            CONSTANT VARCHAR2(100)      := 'OD: CN Custom Collections (OM Extract) Child Program';
G_PROG_TYPE             CONSTANT VARCHAR2(100)      := 'E1004B_CustomCollections_(OM_Extract)';


-- Global Variables
gn_batch_size           PLS_INTEGER      := FND_PROFILE.VALUE('XX_CN_OM_BATCH_SIZE');
gn_client_org_id        PLS_INTEGER      := FND_GLOBAL.ORG_ID;

-- +=============================================================+
-- | Name        : get_item_details                              |
-- | Description : Procedure to derive class,department,division |
-- |               for the given inventory item id               |
-- |                                                             |
-- |                                                             |
-- | Parameters  : x_err_msg                OUT   VARCHAR2       |
-- |               x_ret_code               OUT   PLS_INTEGER    |
-- |               x_class                  OUT   VARCHAR2       |
-- |               x_department             OUT   VARCHAR2       |
-- |               x_division               OUT   VARCHAR2       |
-- |               p_inventory_item_id      IN    NUMBER         |
-- |                                                             |
-- |                                                             |
-- +=============================================================+

PROCEDURE get_item_details (  p_inventory_item_id  IN  NUMBER
                             ,p_order_source       IN  VARCHAR2
                             ,p_private_brand_fg   IN  VARCHAR2
                             ,x_class              OUT NOCOPY VARCHAR2
                             ,x_department         OUT NOCOPY VARCHAR2
                             ,x_division           OUT NOCOPY VARCHAR2
                             ,x_rev_class          OUT NOCOPY NUMBER
                             ,x_err_msg            OUT NOCOPY VARCHAR2
                             ,x_ret_code           OUT NOCOPY PLS_INTEGER
                           ) IS


lc_category_set_name       MTL_CATEGORY_SETS.category_set_name%TYPE := 'Inventory';
ln_mas_org_id              HR_ALL_ORGANIZATION_UNITS.organization_id%TYPE;

EX_NO_MASTER_ORG           EXCEPTION;

CURSOR lcu_class_dep (p_mas_org_id IN PLS_INTEGER) IS
      SELECT  MC.segment3
             ,MC.segment4
      FROM    mtl_item_categories    MIC
             ,mtl_categories         MC
             ,mtl_category_sets      MCS
      WHERE   MIC.organization_id    = p_mas_org_id
      AND     MIC.inventory_item_id  = p_inventory_item_id
      AND     MIC.category_id        = MC.category_id
      AND     MCS.category_set_id    = MIC.category_set_id
      AND     MCS.category_set_name  = lc_category_set_name;


BEGIN

   BEGIN

     SELECT MP.organization_id
     INTO   ln_mas_org_id
     FROM   mtl_parameters MP
     WHERE  MP.organization_id = MP.master_organization_id;

   EXCEPTION
        WHEN OTHERS THEN
             RAISE EX_NO_MASTER_ORG;
   END;


   FOR lr_class_dep IN lcu_class_dep(p_mas_org_id => ln_mas_org_id)
   LOOP

      x_department := lr_class_dep.segment3;
      x_class      := lr_class_dep.segment4;

   END LOOP;

   IF (x_department IS NOT NULL AND x_class IS NOT NULL) THEN
         -- Use procedure xx_cn_util_pkg.xx_xx_cn_get_division
         -- To get the Division and Revenue class
         xx_cn_util_pkg.xx_cn_get_division (  p_dept_code      => x_department
                                             ,p_class_code     => x_class
                                             ,p_order_source   => p_order_source
                                             ,p_collect_source => NULL
                                             ,p_private_brand  => p_private_brand_fg
                                             ,x_division       => x_division
                                             ,x_rev_class_id   => x_rev_class
                                           );

         x_ret_code := 0;

    ELSE
         x_ret_code := 2;

         x_err_msg  := 'Class and Department value are NULL for Item'||p_inventory_item_id;

    END IF;


EXCEPTION

   WHEN EX_NO_MASTER_ORG THEN

      x_err_msg  := 'Unexpected Error while deriving the MASTER ORGANIZATION ID '||SQLERRM;
      x_ret_code := 2;

   WHEN OTHERS THEN

      x_err_msg  := 'Unexpected Error while deriving Class,Department,Division and Revenue Class for Item'||p_inventory_item_id||':'||SQLERRM;
      x_ret_code := 2;

END get_item_details;

-- +=============================================================+
-- | Name        : om_col_notify                                 |
-- | Description : Procedure to extract the sales                |
-- |               order data and insert it into                 |
-- |               xx_cn_not_trx table                           |
-- |                                                             |
-- | Parameters  : x_err_msg                OUT   VARCHAR2       |
-- |               x_ret_code               OUT   PLS_INTEGER    |
-- |               p_parent_proc_audit_id   IN    PLS_INTEGER    |
-- |               p_start_date             IN    DATE           |
-- |               p_end_date               IN    DATE           |
-- |                                                             |
-- +=============================================================+

PROCEDURE  om_col_notify ( p_start_date           IN  DATE
                          ,p_end_date             IN  DATE
                          ,p_parent_proc_audit_id IN  PLS_INTEGER
                          ,x_err_msg              OUT VARCHAR2
                          ,x_ret_code             OUT PLS_INTEGER
                         ) IS



ln_trx_count            NUMBER;
lc_error_message        VARCHAR2(4000);

lc_process_type         VARCHAR2(40);
ln_process_audit_id     NUMBER;
lc_descritpion          VARCHAR2(4000);

L_CONTRACT_CUST         CONSTANT VARCHAR2(10)         := 'CONTRACT';

-- Standard who columns
ln_created_by           NUMBER         := FND_GLOBAL.user_id;
ld_creation_date        DATE           := SYSDATE;
ln_last_updated_by      NUMBER         := FND_GLOBAL.user_id;
ld_last_update_date     DATE           := SYSDATE;
ln_last_update_login    NUMBER         := FND_GLOBAL.login_id;
ln_request_id           NUMBER         := FND_GLOBAL.conc_request_id;
ln_prog_appl_id         NUMBER         := FND_GLOBAL.prog_appl_id;


BEGIN


   lc_process_type      := 'OM_NOTIFY';

   ln_process_audit_id  := NULL;  -- Will get value in the call below

   lc_descritpion       := 'OM Notification Process';


   xx_cn_util_pkg.begin_batch(
                                  p_parent_proc_audit_id  => p_parent_proc_audit_id
                                 ,x_process_audit_id      => ln_process_audit_id
                                 ,p_request_id            => fnd_global.conc_request_id
                                 ,p_process_type          => lc_process_type
                                 ,p_description           => lc_descritpion
                                );

   xx_cn_util_pkg.DEBUG('Begin OM Notification');
   
   xx_cn_util_pkg.DEBUG('Inserting into XX_CN_NOT_TRX table');
   -------------------------------------------
   -- Insert records into xx_cn_not_trx table
   -------------------------------------------
   INSERT INTO xx_cn_not_trx (
               not_trx_id
              ,row_id
              ,org_id
              ,notified_date
              ,process_audit_id
              ,batch_id
              ,last_extracted_date
              ,extracted_flag
              ,event_id
              ,source_doc_type
              ,source_trx_id
              ,source_trx_line_id
              ,source_trx_number
              ,processed_date
              ,request_id
              ,program_application_id
              ,created_by
              ,creation_date
              ,last_updated_by
              ,last_update_date
              ,last_update_login
              )
         SELECT
              xx_cn_not_trx_s.NEXTVAL
             ,OOH.ROWID
             ,OOH.org_id
             ,SYSDATE
             ,ln_process_audit_id
             ,FLOOR(xx_cn_not_trx_s.CURRVAL/gn_batch_size)
             ,SYSDATE
             ,'N'
             ,G_EVENT_ID
             ,G_SRC_DOC_TYPE
             ,OOH.header_id
             ,OOL.line_id
             ,OOH.order_number
             ,OOL.actual_shipment_date
             ,ln_request_id
             ,ln_prog_appl_id
             ,ln_created_by
             ,ld_creation_date
             ,ln_last_updated_by
             ,ld_last_update_date
             ,ln_last_update_login
         FROM
              oe_order_headers     OOH
             ,oe_order_lines       OOL
         WHERE  OOH.header_id||''                     = OOL.header_id
         AND    OOL.flow_status_code                  ='CLOSED'
         AND    OOL.actual_shipment_date  BETWEEN p_start_date AND p_end_date
         AND EXISTS (SELECT 1 
                       FROM  hz_cust_accounts  HCA 
                      WHERE  HCA.cust_account_id      = OOH.sold_to_org_id  
                        AND HCA.attribute18           = L_CONTRACT_CUST)
         AND EXISTS (SELECT 1 
                       FROM   mtl_system_items_b   MSIB 
                      WHERE   MSIB.organization_id    = OOL.ship_from_org_id
                        AND    MSIB.inventory_item_id = OOL.inventory_item_id 
                        AND    MSIB.invoiceable_item_flag    = 'Y')
         AND NOT EXISTS
                      (SELECT 1
                       FROM   xx_cn_not_trx XCNT
                       WHERE  XCNT.source_trx_id      = OOH.header_id
                       AND    XCNT.source_trx_line_id = OOL.line_id
                       AND    XCNT.event_id           = G_EVENT_ID);


   ln_trx_count := SQL%ROWCOUNT;

   xx_cn_util_pkg.display_out ( 'Number of Records Notified from OM Source  : ' || ln_trx_count);
   xx_cn_util_pkg.display_out (' ');
   xx_cn_util_pkg.DEBUG('Number of Records Notified from OM Source  : ' || ln_trx_count);
   xx_cn_util_pkg.DEBUG('End of OM Notification');

   -- Update the batch with number of transaction records extracted

   lc_error_message := 'Finished notification run: Notified ' || ln_trx_count || ' orders.';

   xx_cn_util_pkg.update_batch(
                                p_process_audit_id      => ln_process_audit_id
                               ,p_execution_code        => 0
                               ,p_error_message         => lc_error_message
                              );


   xx_cn_util_pkg.end_batch (ln_process_audit_id);

   COMMIT;

   x_ret_code := 0;

   EXCEPTION

         WHEN OTHERS THEN

             ROLLBACK;

             xx_cn_util_pkg.update_batch(
                                                p_process_audit_id      => ln_process_audit_id
                                               ,p_execution_code        => SQLCODE
                                               ,p_error_message         => SQLERRM
                                           );


             xx_cn_util_pkg.end_batch (ln_process_audit_id);

             x_err_msg := 'Unexpeted error while notifying the Orders: '||SQLERRM;

             x_ret_code := 2;


    END om_col_notify;


-- +=============================================================+
-- | Name        : om_extrcat_main                               |
-- | Description : MAIN Procedure to extract the sales           |
-- |               order data and insert it into                 |
-- |               xx_cn_not_trx table                           |
-- |                                                             |
-- | Parameters  : x_errbuf         OUT   VARCHAR2               |
-- |               x_retcode        OUT   NUMBER                 |
-- |               p_mode           IN    VARCHAR2               |
-- |               p_start_date     IN    VARCAHR2               |
-- |               p_end_date       IN    VARCAHR2               |
-- |                                                             |
-- +=============================================================+


PROCEDURE om_extract_main ( x_errbuf      OUT NOCOPY VARCHAR2
                           ,x_retcode     OUT NOCOPY NUMBER
                           ,p_mode        IN  VARCHAR2
                           ,p_start_date  IN  VARCHAR2
                           ,p_end_date    IN  VARCHAR2
                          ) IS


ld_start_date             DATE;
ld_end_date               DATE;
ln_ext_audit_id           PLS_INTEGER;
lc_err_msg                VARCHAR2(4000);
ln_ret_code               PLS_INTEGER;
ln_batch_id               NUMBER;
lc_error_message          VARCHAR2(4000);
lc_sd_exist               VARCHAR2(1);
lc_ed_exist               VARCHAR2(1);
ln_mas_org_id             NUMBER;
ln_extract_count          PLS_INTEGER;

lc_process_type           VARCHAR2(40);
ln_proc_ext_audit_id      NUMBER;
lc_descritpion            VARCHAR2(4000);

ln_code                   NUMBER;
lc_message                VARCHAR2(4000);
ln_count                  PLS_INTEGER;
ln_request_id             NUMBER      := FND_GLOBAL.conc_request_id;

-- Conc request variables
ln_conc_request_id        NUMBER;
lb_wait_req               BOOLEAN;
lc_phase                  VARCHAR2(25);
lc_status                 VARCHAR2(25);
lc_dev_phase              VARCHAR2(25);
lc_dev_status             VARCHAR2(25);
lc_con_message            VARCHAR2(2000);
ln_conc_req_idx           NUMBER := 0;

-- Exception Variable
EX_RUN_CONV_PROG_FIRST    EXCEPTION;
EX_UNEXP_ERR_NOTIFY_ORD   EXCEPTION;
EX_INVALID_CN_PERIOD_DATE EXCEPTION;
EX_INVALID_OM_BATCH_SIZE  EXCEPTION;
EX_NO_MASTER_ORG_SETUP    EXCEPTION;
EX_MANY_MASTER_ORGS_SETUP EXCEPTION;

CURSOR lcu_batch_id IS
   SELECT DISTINCT xcnt.batch_id
   FROM   xx_cn_not_trx xcnt
   WHERE  xcnt.extracted_flag  = 'N'
   AND    xcnt.source_doc_type = G_SRC_DOC_TYPE
   AND    xcnt.event_id        = G_EVENT_ID;



BEGIN

    xx_cn_util_pkg.display_out ('******************** Custom Collections (OM Extract) ********************');
    xx_cn_util_pkg.display_out ('');
    xx_cn_util_pkg.display_out ('********************************* BEGIN *********************************');
    xx_cn_util_pkg.display_out ('');

    xx_cn_util_pkg.display_log ('******************** Custom Collections (OM Extract) ********************');
    xx_cn_util_pkg.display_log ('');
    xx_cn_util_pkg.display_log ('********************************* BEGIN *********************************');
    xx_cn_util_pkg.display_log ('');

    xx_cn_util_pkg.display_out ( 'Mode of Run: ' || p_mode);
    xx_cn_util_pkg.display_out ('');
    xx_cn_util_pkg.display_log ( 'Mode of Run: ' || p_mode);
    xx_cn_util_pkg.display_log ('');


    IF p_mode = 'INTERFACE' THEN

      BEGIN
          -------------------------------------------------------------------
          -- Commented as per change in logic for interface mode 
          -- Modified on 29/Oct/2007 
          -------------------------------------------------------------------
       /* SELECT MAX(XCNT.last_extracted_date)
          INTO   ld_start_date
          FROM   xx_cn_not_trx         XCNT
          WHERE  XCNT.source_doc_type  = G_SRC_DOC_TYPE
          AND    XCNT.event_id         = G_EVENT_ID;

          IF ld_start_date IS NULL THEN

             -- Raise Exception and Terminate the program
             RAISE EX_RUN_CONV_PROG_FIRST;


          END IF;*/
          
          ----------------------------------------------------------------
          -- Included as per change in logic for interface mode 
          -- Modified on 29/Oct/2007 
          ----------------------------------------------------------------
          
          SELECT COUNT (1)
          INTO ln_count
          FROM DUAL
          WHERE EXISTS (
                         SELECT XCNT.not_trx_id
                         FROM   xx_cn_not_trx XCNT
                         WHERE  XCNT.source_doc_type = G_SRC_DOC_TYPE
                         AND    XCNT.event_id        = G_EVENT_ID
                       );
                         
                         
                     
          SELECT MIN (CAPSV.start_date)
          INTO ld_start_date
          FROM cn_acc_period_statuses_v CAPSV
          WHERE (CAPSV.quarter_num, CAPSV.period_year) =
                      (SELECT CAPS.quarter_num
                             ,CAPS.period_year
                       FROM cn_acc_period_statuses_v CAPS
                       WHERE SYSDATE BETWEEN CAPS.start_date AND CAPS.end_date);
          
          
          
          IF (ln_count = 0) THEN
         
               RAISE EX_RUN_CONV_PROG_FIRST;
               
          END IF;
          
          -- End of changes on 29/Oct/2007 

          ld_end_date := SYSDATE;

       EXCEPTION

          WHEN OTHERS THEN

             RAISE;

       END;

    ELSIF p_mode ='CONVERSION' THEN

       ld_start_date := fnd_date.canonical_to_date(p_start_date);
       ld_end_date   := fnd_date.canonical_to_date(p_end_date);

       xx_cn_util_pkg.display_out ( 'Start Date: ' || ld_start_date);
       xx_cn_util_pkg.display_out ('');
       xx_cn_util_pkg.display_out ( 'End Date: '   || ld_end_date);
       xx_cn_util_pkg.display_out ('');

       xx_cn_util_pkg.display_log ( 'Start Date: ' || ld_start_date);
       xx_cn_util_pkg.display_log ('');
       xx_cn_util_pkg.display_log ( 'End Date: '   || ld_end_date);
       xx_cn_util_pkg.display_log ('');

    END IF; -- End of Mode branch

    ------------------------------------------------------
    -- Check if input dates belong to Open/Future periods
    ------------------------------------------------------

    xx_cn_util_pkg.display_log('Extract: Checking if start and end dates belong to Open/Future periods');
    xx_cn_util_pkg.display_log ('');


    -- Initialize the lc_exist flag
    lc_sd_exist := 'N';
    lc_ed_exist := 'N';

    BEGIN

         SELECT 'Y'
         INTO   lc_sd_exist
         FROM   cn_acc_period_statuses_v CAPSV
         WHERE  ld_start_date BETWEEN CAPSV.start_date AND CAPSV.end_date;

         IF (lc_sd_exist = 'N')
         THEN
             -- Raise exception and terminate the program
             RAISE EX_INVALID_CN_PERIOD_DATE;
         END IF;

         SELECT 'Y'
         INTO   lc_ed_exist
         FROM   cn_acc_period_statuses_v CAPSV
         WHERE  ld_end_date BETWEEN CAPSV.start_date AND CAPSV.end_date;

         IF (lc_ed_exist = 'N')
         THEN
             -- Raise exception and terminate the program
             RAISE EX_INVALID_CN_PERIOD_DATE;
         END IF;

    EXCEPTION
         WHEN NO_DATA_FOUND THEN

              RAISE EX_INVALID_CN_PERIOD_DATE;

         WHEN OTHERS THEN

            lc_sd_exist := 'N';
            lc_ed_exist := 'N';

            RAISE;
    END;
    xx_cn_util_pkg.display_log('Extract: End of start and end dates validation for Open/Future periods');
    xx_cn_util_pkg.display_log ('');


    -------------------------------
    -- Check for valid batch size
    -------------------------------

    xx_cn_util_pkg.display_log('Extract: Checking if Batch Size from OD: CN OM Process Batch Size is valid');
    xx_cn_util_pkg.display_log ('');

    IF (gn_batch_size IS NULL OR gn_batch_size <= 0)
    THEN
        -- raise exception and terminate the program
        RAISE EX_INVALID_OM_BATCH_SIZE;

    END IF;

    xx_cn_util_pkg.display_log('Extract: End of check for Batch Size from OD: CN OM Process Batch Size');
    xx_cn_util_pkg.display_log ('');



    --------------------------------
    -- Check for Master Organization
    --------------------------------

    xx_cn_util_pkg.display_log('Extract: Derivation of Master Organization');
    xx_cn_util_pkg.display_log ('');

    BEGIN

      SELECT MP.organization_id
      INTO   ln_mas_org_id
      FROM   mtl_parameters MP
      WHERE  MP.organization_id = MP.master_organization_id;

      IF ln_mas_org_id IS NULL THEN
         RAISE EX_NO_MASTER_ORG_SETUP;
      END IF;

    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
             RAISE EX_MANY_MASTER_ORGS_SETUP;

        WHEN OTHERS THEN
             RAISE;
    END;

    xx_cn_util_pkg.display_log('Extract: End of Master Organization Derivation');
    xx_cn_util_pkg.display_log ('');


    ---------------------------
    -- Main extraction process
    ---------------------------

    lc_process_type      := 'OM_MAIN';

    ln_proc_ext_audit_id := NULL;   -- Will get a value in the call below

    lc_descritpion       := 'OM: begin of the main extract process';

    xx_cn_util_pkg.begin_batch(
                                p_parent_proc_audit_id  => NULL
                               ,x_process_audit_id      => ln_proc_ext_audit_id
                               ,p_request_id            => fnd_global.conc_request_id
                               ,p_process_type          => lc_process_type
                               ,p_description           => lc_descritpion
                              );

    ln_ext_audit_id := ln_proc_ext_audit_id;

    xx_cn_util_pkg.DEBUG('Custom Collections>>');

    xx_cn_util_pkg.DEBUG('Extract: Call notify process begin.');

    lc_err_msg      := NULL;
    ln_ret_code     := NULL;

    xx_cn_util_pkg.DEBUG('Extract: entering notify.');

    -- Call the OM_COL_NOTIFY procedure to extract the eligible sales order data
    
    xx_cn_util_pkg.flush; -- Flush the messages to the stack
    
    om_col_notify ( p_start_date           => ld_start_date
                   ,p_end_date             => ld_end_date
                   ,p_parent_proc_audit_id => ln_proc_ext_audit_id
                   ,x_err_msg              => lc_err_msg
                   ,x_ret_code             => ln_ret_code
                  );
                  
    xx_cn_util_pkg.g_process_audit_id := ln_proc_ext_audit_id;
    
    IF ln_ret_code = 2 THEN

       -- Raise exception and terminate the program

       xx_cn_util_pkg.display_log (lc_err_msg);
       xx_cn_util_pkg.display_log ('');

       RAISE EX_UNEXP_ERR_NOTIFY_ORD;

    END IF;
     
    xx_cn_util_pkg.DEBUG('Extract: exit from notify and start collection run.');

    --------------------------------------------------------
    -- Insert records into xx_cn_om_trx table in batches
    --------------------------------------------------------

    xx_cn_util_pkg.DEBUG('Extract: start extraction process.');
    xx_cn_util_pkg.DEBUG('Extract: entering cursor Batches loop.');

    -- Delete the records from concurrent request pl/sql table type
    lt_conc_req_tbl.DELETE;

    FOR lr_batch_id IN lcu_batch_id
    LOOP

        ln_batch_id := lr_batch_id.batch_id;

        ---------------------------------------
        -- Submit the child concurrent program
        ---------------------------------------
        xx_cn_util_pkg.DEBUG('Extract: Submitting the child program for each batch.');
        xx_cn_util_pkg.flush;
        ln_conc_request_id := FND_REQUEST.SUBMIT_REQUEST ( application => 'xxcrm'
                                                          ,program     => 'XXCNOMCHILD'
                                                          ,sub_request => FALSE
                                                          ,argument1   => ln_batch_id
                                                          ,argument2   => ln_proc_ext_audit_id
                                                         );
        xx_cn_util_pkg.g_process_audit_id := ln_proc_ext_audit_id;
        COMMIT;

        lc_message  := NULL;
        ln_code     := NULL;

        IF ln_conc_request_id = 0 THEN

            ROLLBACK;

            ln_code := -1;

            FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0012_CONC_PRG_FAILED');
            FND_MESSAGE.set_token ('PRG_NAME','XXCNOMCHILD');
            FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
            FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);

            lc_message := FND_MESSAGE.get;

            xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                       ,p_prog_type      => G_PROG_TYPE
                                       ,p_prog_id        => ln_request_id
                                       ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                       ,p_message        => lc_message
                                       ,p_code           => ln_code
                                       ,p_err_code       => 'XX_OIC_0012_CONC_PRG_FAILED'
                                     );


             xx_cn_util_pkg.DEBUG (lc_message);

             xx_cn_util_pkg.display_log (lc_message);
             xx_cn_util_pkg.display_log ('');

             x_retcode := 1;

             x_errbuf := 'Procedure: OM_EXTRACT_MAIN: ' || lc_message;

        ELSE

             lt_conc_req_tbl (ln_conc_req_idx) := ln_conc_request_id;

             xx_cn_util_pkg.DEBUG ('Submitted: '|| G_CHILD_PROG);
             xx_cn_util_pkg.display_log ('Submitted: '|| G_CHILD_PROG);


             xx_cn_util_pkg.DEBUG ('Concurrent Request ID: '|| ln_conc_request_id);
             xx_cn_util_pkg.display_log ('Concurrent Request ID: '|| ln_conc_request_id);
             xx_cn_util_pkg.display_log ('');

        END IF;

        -- Increment the index number
        ln_conc_req_idx := ln_conc_req_idx + 1;

    END LOOP; -- End of loop on batches

    -------------------------------------------------
    -- Wait for all the child program to complete
    -- before the main program
    -------------------------------------------------
    IF (ln_conc_req_idx > 0) THEN

       FOR i IN 0 .. (ln_conc_req_idx - 1)
       LOOP

           ln_conc_request_id := lt_conc_req_tbl (i);

           lb_wait_req  :=   FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                              request_id => ln_conc_request_id,
                                                              INTERVAL   => 5,
                                                              phase      => lc_phase,
                                                              status     => lc_status,
                                                              dev_phase  => lc_dev_phase,
                                                              dev_status => lc_dev_status,
                                                              message    => lc_con_message
                                                            );

            IF (    lc_dev_status = 'ERROR'
                 OR lc_dev_status = 'TERMINATED'
                 OR lc_dev_status = 'CANCELLED')
            THEN
                    xx_cn_util_pkg.DEBUG (lc_con_message);

                    xx_cn_util_pkg.display_log (lc_con_message);

                    x_retcode := 1;

                    x_errbuf := 'Procedure: OM_EXTRACT_MAIN: ' || lc_con_message;

            END IF; -- End of branch on dev status check

        END LOOP;

    END IF; -- End of branch on concurrent request index check

    COMMIT;

    ln_proc_ext_audit_id := ln_ext_audit_id;

    -- To get the total count of records extracted into xx_cn_om_trx
    BEGIN

      ln_extract_count := 0;

      SELECT COUNT(*)
      INTO   ln_extract_count
      FROM   xx_cn_om_trx
      WHERE  process_audit_id = ln_proc_ext_audit_id;

    EXCEPTION
      WHEN OTHERS THEN
             RAISE;
    END;

    xx_cn_util_pkg.display_out ('Total number of records extracted from OM Source: '||ln_extract_count);

    xx_cn_util_pkg.DEBUG ('Total number of records extracted from OM Source: '||ln_extract_count);

    xx_cn_util_pkg.DEBUG('Custom Collections<<');

    xx_cn_util_pkg.end_batch (ln_proc_ext_audit_id);


    xx_cn_util_pkg.display_out ('********************************** END **********************************');


    xx_cn_util_pkg.display_log ('********************************** END **********************************');


    x_retcode := 0;


EXCEPTION

      WHEN EX_RUN_CONV_PROG_FIRST THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0013_RUN_CONV_FIRST');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                    ,p_prog_type      => G_PROG_TYPE
                                    ,p_prog_id        => ln_request_id
                                    ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                    ,p_message        => lc_message
                                    ,p_code           => ln_code
                                    ,p_err_code       => 'XX_OIC_0013_RUN_CONV_FIRST'
                                   );

         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** END OF PROCESS ******************************');

         xx_cn_util_pkg.display_out ('*************************** END OF PROCESS ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: OM_EXTRACT_MAIN: ' || lc_message;

      WHEN EX_INVALID_CN_PERIOD_DATE THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0014_INVALID_CN_DATE');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                   ,p_prog_type      => G_PROG_TYPE
                                   ,p_prog_id        => ln_request_id
                                   ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                   ,p_message        => lc_message
                                   ,p_code           => ln_code
                                   ,p_err_code       => 'XX_OIC_0014_INVALID_CN_DATE'
                                  );

         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** END OF PROCESS ******************************');

         xx_cn_util_pkg.display_out ('*************************** END OF PROCESS ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: OM_EXTRACT_MAIN: ' || lc_message;

      WHEN EX_INVALID_OM_BATCH_SIZE THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0021_INVALID_OM_SIZE');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                    ,p_prog_type      => G_PROG_TYPE
                                    ,p_prog_id        => ln_request_id
                                    ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                    ,p_message        => lc_message
                                    ,p_code           => ln_code
                                    ,p_err_code       => 'XX_OIC_0021_INVALID_OM_SIZE'
                                  );


         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** END OF PROCESS ******************************');

         xx_cn_util_pkg.display_out ('*************************** END OF PROCESS ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: EXTRACT_MAIN: ' || lc_message;


      WHEN EX_NO_MASTER_ORG_SETUP  THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0022_NO_MASTER_ORG');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error(  p_prog_name => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                   ,p_prog_type => G_PROG_TYPE
                                   ,p_prog_id   => ln_request_id 
                                   ,p_exception => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                   ,p_message   => lc_message
                                   ,p_code      => ln_code
                                   ,p_err_code  => 'XX_OIC_0022_NO_MASTER_ORG'
                                  );


         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** END OF PROCESS ******************************');

         xx_cn_util_pkg.display_out ('*************************** END OF PROCESS ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: OM_EXTRACT_MAIN: ' || lc_message;

      WHEN EX_MANY_MASTER_ORGS_SETUP THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0023_MANY_MASTER_ORG');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error ( p_prog_name => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                   ,p_prog_type => G_PROG_TYPE
                                   ,p_prog_id   => ln_request_id 
                                   ,p_exception => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                   ,p_message   => lc_message
                                   ,p_code      => ln_code
                                   ,p_err_code  => 'XX_OIC_0023_MANY_MASTER_ORG'
                                  );

         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.display_log ('*************************** END OF PROCESS ******************************');

         xx_cn_util_pkg.display_out ('*************************** END OF PROCESS ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: OM_EXTRACT_MAIN: ' || lc_message;



      WHEN EX_UNEXP_ERR_NOTIFY_ORD THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0019_NOTIFY_ERROR');

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                    ,p_prog_type      => G_PROG_TYPE
                                    ,p_prog_id        => ln_request_id
                                    ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                    ,p_message        => lc_message
                                    ,p_code           => ln_code
                                    ,p_err_code       => 'XX_OIC_0019_NOTIFY_ERROR'
                                  );

         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.update_batch(
                                      p_process_audit_id      => ln_proc_ext_audit_id
                                     ,p_execution_code        => SQLCODE
                                     ,p_error_message         => SQLERRM
                                    );


         xx_cn_util_pkg.end_batch (ln_proc_ext_audit_id);


         xx_cn_util_pkg.display_log ('*************************** END OF PROCESS ******************************');

         xx_cn_util_pkg.display_out ('*************************** END OF PROCESS ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: OM_EXTRACT_MAIN: ' || lc_message;

     WHEN OTHERS THEN

         ROLLBACK;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
         FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);

         lc_message := fnd_message.get;

         xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                   ,p_prog_type      => G_PROG_TYPE
                                   ,p_prog_id        => ln_request_id
                                   ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_MAIN'
                                   ,p_message        => lc_message
                                   ,p_code           => ln_code
                                   ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                  );


         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.update_batch(
                                      p_process_audit_id      => ln_proc_ext_audit_id
                                     ,p_execution_code        => SQLCODE
                                     ,p_error_message         => lc_message
                                    );


         xx_cn_util_pkg.end_batch (ln_proc_ext_audit_id);

         xx_cn_util_pkg.display_log ('*************************** END OF PROCESS ******************************');

         xx_cn_util_pkg.display_out ('*************************** END OF PROCESS ******************************');

         x_retcode := 2;

         x_errbuf := 'Procedure: OM_EXTRACT_MAIN: ' || lc_message;

END om_extract_main; -- End of Main Extract Program



-- +=============================================================+
-- | Name        : om_extrcat_child                              |
-- | Description : Procedure to extract the uncollected data from|
-- |               xx_cn_not_trx table and insert it into        |
-- |               xx_cn_om_trx table batch wise                 |
-- |                                                             |
-- | Parameters  : x_errbuf             OUT   VARCHAR2           |
-- |               x_retcode            OUT   NUMBER             |
-- |               p_batch_id           IN    VARCHAR2           |
-- |               p_process_audit_id   IN    VARCAHR2           |
-- |                                                             |
-- +=============================================================+


PROCEDURE om_extract_child ( x_errbuf            OUT VARCHAR2
                            ,x_retcode           OUT NUMBER
                            ,p_batch_id          IN  NUMBER
                            ,p_process_audit_id  IN  NUMBER
                          ) IS

ln_om_trx_count         PLS_INTEGER := 0;
L_LIMIT_SIZE            CONSTANT PLS_INTEGER    := 1000;

lc_err_msg              VARCHAR2(4000);
ln_ret_code             PLS_INTEGER;

ln_code                 NUMBER;
lc_message              VARCHAR2(4000);

ln_proc_col_audit_id    NUMBER;
lc_error_message        VARCHAR2(4000);
lc_process_type         VARCHAR2(40);
lc_descritpion          VARCHAR2(4000);
lb_val_rec              BOOLEAN;

ln_null_rev_class       PLS_INTEGER;
ln_null_div             PLS_INTEGER;
ln_null_priv_band       PLS_INTEGER;
ln_null_po_cost         PLS_INTEGER;
ln_null_rollup_date     PLS_INTEGER;

-- Standard who columns
ln_created_by           NUMBER      := FND_GLOBAL.user_id;
ld_creation_date        DATE        := SYSDATE;
ln_last_updated_by      NUMBER      := FND_GLOBAL.user_id;
ld_last_update_date     DATE        := SYSDATE;
ln_last_update_login    NUMBER      := FND_GLOBAL.login_id;
ln_request_id           NUMBER      := FND_GLOBAL.conc_request_id;
ln_prog_appl_id         NUMBER      := FND_GLOBAL.prog_appl_id;
  

-- Cursor for selecting all the notified slaes orders to
-- insert into xx_cn_om_trx table.

CURSOR lcu_om_trx IS
     SELECT   xx_cn_om_trx_s.NEXTVAL                              -- OM Trx ID
             ,OOH.booked_date                                     -- Booked Date
             ,OOH.ordered_date                                    -- Order Date
             ,NULL                                                -- Salesrep ID
             ,OOH.sold_to_org_id                                  -- Customer ID
             ,OOL.inventory_item_id                               -- Inventory Item ID
             ,OOH.order_number                                    -- Order Number
             ,OOL.line_number                                     -- Line Number
             ,OOL.actual_shipment_date                            -- Processed Date 
             ,cn_api.get_acc_period_id(OOL.actual_shipment_date)  -- Account Period ID
             ,OOH.org_id                                          -- Operating Unit ID
             ,G_EVENT_ID                                          -- Event ID -1003
             ,'NON-REVENUE'                                       -- Revenue Type
             ,cn_api.get_site_address_id(OOL.ship_to_org_id)      -- Site Address ID
             ,HCAS.party_site_id                                  -- Party Site ID
             ,OOL.actual_shipment_date                            -- Rollup Date
             ,G_SRC_DOC_TYPE                                      -- Source Doc Type OM
             ,OOH.header_id                                       -- Source TRX ID
             ,OOL.line_id                                         -- Source TRX line ID
             ,OOH.order_number                                    -- Source TRX Number 
             ,NVL(OOL.ordered_quantity, 0)                        -- Qunatity
             ,NVL(OOL.ordered_quantity, 0) * NVL(OOL.unit_selling_price, 0) * DECODE(OOL.line_category_code, 'RETURN', -1, 1) -- Transaction Amount
             ,OOH.transactional_curr_code                         -- Transactional Currency Code
             ,OOL.line_category_code                              -- Trx Type
             ,NULL                                                -- Class code
             ,NULL                                                -- Department code
             ,XIIMA.od_private_brand_flg                          -- Private Brand Flag
             ,XOLAL.po_cost                                       -- PO Cost
             ,NULL                                                -- Division
             ,NULL                                                -- Revenue_class_id
             ,DECODE(OOL.source_type_code,'EXTERNAL','Y','N')     -- Drop Ship Flag
             ,NULL                                                -- Margin Amount
             ,0                                                   -- Discount Percentage
             ,NULL                                                -- Exchange Rate
             ,OOL.return_reason_code                              -- Return Reason Code
             ,OOS.name                                            -- Transaction Type
             ,'N'                                                 -- Summarized Flag
             ,'N'                                                 -- Salesrep Assign Flag
             ,p_batch_id                                          -- Batch ID
             ,NULL                                                -- Transfer Batch ID
             ,NULL                                                -- Summ Batch ID 
             ,p_process_audit_id                                  -- Process Audit ID
             ,ln_request_id                                       -- Con Request ID
             ,ln_prog_appl_id                                     -- Con Program Application ID
             ,ln_created_by                                       -- Standard WHO Coloumn
             ,ld_creation_date                                    -- Standard WHO Coloumn
             ,ln_last_updated_by                                  -- Standard WHO Coloumn
             ,ld_last_update_date                                 -- Standard WHO Coloumn
             ,ln_last_update_login                                -- Standard WHO Coloumn
     FROM     xx_cn_not_trx                  XCNT
             ,oe_order_headers               OOH
             ,oe_order_lines                 OOL
             ,oe_order_sources               OOS
             ,xx_inv_item_master_attributes  XIIMA
             ,xx_om_line_attributes_all      XOLAL
             ,hz_cust_acct_sites             HCAS
             ,hz_cust_site_uses              HCSU  
     WHERE    OOL.header_id                  = XCNT.source_trx_id
     AND      OOL.line_id                    = XCNT.source_trx_line_id
     AND      OOH.header_id                  = XCNT.source_trx_id
     AND      OOH.order_source_id            = OOS.order_source_id
     AND      OOL.inventory_item_id          = XIIMA.inventory_item_id(+)
     AND      OOL.line_id                    = XOLAL.line_id(+)
     AND      XCNT.event_id                  = G_EVENT_ID
     AND      XCNT.extracted_flag            = 'N'
     AND      XCNT.batch_id                  = p_batch_id
     AND      HCAS.cust_acct_site_id         = HCSU.cust_acct_site_id --| Included as per onsite requirement
     AND      HCSU.site_use_id               = OOL.ship_to_org_id;    --| to dervie the party site id


CURSOR lcu_actual_ship_date ( p_line_id   IN NUMBER
                             ,p_header_id IN NUMBER
                             ,p_org_id    IN NUMBER ) IS
   SELECT OOL.actual_shipment_date
   FROM   oe_order_lines OOL
   WHERE  (OOL.header_id,OOL.line_id) =
                 (SELECT  OOLB.return_attribute1
                         ,OOLB.return_attribute2
                  FROM    oe_order_lines OOLB
                  WHERE   OOLB.return_context ='ORDER'
                  AND     OOLB.line_id        = p_line_id
                  AND     OOLB.header_id      = p_header_id
                  AND     OOLB.org_id         = p_org_id);

BEGIN

   xx_cn_util_pkg.display_out (' Office DEPOT');
   xx_cn_util_pkg.display_out (' ');
   xx_cn_util_pkg.display_out (RPAD (' ', 100, '_'));
   xx_cn_util_pkg.display_out ('');
      
   xx_cn_util_pkg.display_out (' OM Child Extract for Batch ID:  '||p_batch_id );
   xx_cn_util_pkg.display_out (' ');


   ------------------------------------
   -- Begin a new batch for Extraction
   ------------------------------------
   ln_proc_col_audit_id := NULL;   -- Will get a value in the call below

   lc_process_type      := 'OM_EXTRACT';

   lc_descritpion       := 'Extraction run for batch ' || p_batch_id;


   xx_cn_util_pkg.begin_batch(
                                 p_parent_proc_audit_id  => p_process_audit_id
                                ,x_process_audit_id      => ln_proc_col_audit_id
                                ,p_request_id            => fnd_global.conc_request_id
                                ,p_process_type          => lc_process_type
                                ,p_description           => lc_descritpion
                             );
   xx_cn_util_pkg.DEBUG('Extract: OM extract Child Program to insert records into XX_CN_OM_TRX table.');
   
   xx_cn_util_pkg.DEBUG('Extract: Running Child Program for Batch ID : ' ||p_batch_id);
   
   ln_null_rev_class   := 0;     
   ln_null_div         := 0;         
   ln_null_priv_band   := 0;     
   ln_null_po_cost     := 0;      
   ln_null_rollup_date := 0;                               

   
   OPEN lcu_om_trx;

   LOOP
   
      lt_omtrx.DELETE;
      lt_omtrx_suc.DELETE;
      lt_omtrx_fal.DELETE;
     

      ln_code             := NULL;
      lc_message          := NULL;
            
      
      

      FETCH lcu_om_trx BULK COLLECT INTO lt_omtrx LIMIT L_LIMIT_SIZE;
       
       -- Check if the table count is greater than zero
       
       IF(lt_omtrx.COUNT > 0) 
       THEN
       
         FOR idx IN lt_omtrx.FIRST .. lt_omtrx.LAST
         LOOP
          

             lb_val_rec := TRUE;
             
             --------------------------------
             -- Calculation of Margin Amount
             --------------------------------
             IF lt_omtrx(idx).cost IS NOT NULL THEN


                   IF lt_omtrx(idx).drop_ship_flag = 'N' THEN

                      lt_omtrx(idx).margin := lt_omtrx(idx).transaction_amount - (lt_omtrx(idx).quantity * lt_omtrx(idx).cost);

                   ELSE

                      lt_omtrx(idx).margin := (lt_omtrx(idx).transaction_amount * 1.1) - (lt_omtrx(idx).quantity * lt_omtrx(idx).cost);

                   END IF;
             ELSE

                 ln_code    := NULL;

                 lc_message := NULL;

                 lb_val_rec := FALSE;

                 ln_null_po_cost := ln_null_po_cost +1;

                 ln_code := -1;

                 FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0024_NO_PO_COST');
                 FND_MESSAGE.set_token ('ORDER_NO',lt_omtrx(idx).order_number);
                 FND_MESSAGE.set_token ('LINE_NO', lt_omtrx(idx).line_number);


                 lc_message := FND_MESSAGE.get;

                 xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                            ,p_prog_type      => G_PROG_TYPE
                                            ,p_prog_id        => ln_request_id 
                                            ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                            ,p_message        => lc_message
                                            ,p_code           => ln_code
                                            ,p_err_code       => 'XX_OIC_0024_NO_PO_COST'
                                          );


                  xx_cn_util_pkg.DEBUG (lc_message);

              END IF;
             
             ---------------------------------------------------------- 
             -- Calculation of Actual Shipment Date for a Return Order
             ----------------------------------------------------------

             IF lt_omtrx(idx).trx_type = 'RETURN' THEN

                FOR lr_actual_ship_date IN lcu_actual_ship_date ( p_line_id    => lt_omtrx(idx).source_trx_line_id
                                                                 ,p_header_id  => lt_omtrx(idx).source_trx_id
                                                                 ,p_org_id     => lt_omtrx(idx).org_id
                                                                )
                LOOP
                
                    IF lr_actual_ship_date.actual_shipment_date IS NOT NULL THEN

                        lt_omtrx(idx).processed_date      := lr_actual_ship_date.actual_shipment_date;

                        lt_omtrx(idx).processed_period_id := cn_api.get_acc_period_id(lr_actual_ship_date.actual_shipment_date);

                        lt_omtrx(idx).rollup_date         := lr_actual_ship_date.actual_shipment_date;
                        
                    ELSE
                    
                        ln_code    := NULL;
                    
                        lc_message := NULL;
                    
                        lb_val_rec := FALSE;
                    
                    
                        ln_code := -1;
                        
                        ln_null_rollup_date := ln_null_rollup_date +1;
                    
                        FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0050_NULL_ACT_SHIP_DATE');
                        FND_MESSAGE.set_token ('ORDER_NO',lt_omtrx(idx).order_number);
                        FND_MESSAGE.set_token ('LINE_NO', lt_omtrx(idx).line_number);
                    
                    
                        lc_message := FND_MESSAGE.get;
                    
                        xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                                   ,p_prog_type      => G_PROG_TYPE
                                                   ,p_prog_id        => ln_request_id 
                                                   ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                                   ,p_message        => lc_message
                                                   ,p_code           => ln_code
                                                   ,p_err_code       => 'XX_OIC_0050_NULL_ACT_SHIP_DATE'
                                                 );
                    
                    
                        xx_cn_util_pkg.DEBUG (lc_message);
                    
                        
                    END IF;
 
                END LOOP;

             END IF;


             --------------------------------------------------------------------
             -- Calcualtion of the Class, Department, Division and Revenue Class
             --------------------------------------------------------------------

             lc_err_msg  := NULL;
             ln_ret_code := NULL;


             IF lt_omtrx(idx).private_brand IS NOT NULL THEN


                  get_item_details (  p_inventory_item_id  =>  lt_omtrx(idx).inventory_item_id
                                     ,p_order_source       =>  lt_omtrx(idx).original_order_source
                                     ,p_private_brand_fg   =>  lt_omtrx(idx).private_brand
                                     ,x_class              =>  lt_omtrx(idx).class_code
                                     ,x_department         =>  lt_omtrx(idx).department_code
                                     ,x_division           =>  lt_omtrx(idx).division
                                     ,x_rev_class          =>  lt_omtrx(idx).revenue_class_id
                                     ,x_err_msg            =>  lc_err_msg
                                     ,x_ret_code           =>  ln_ret_code
                                   );
                  

                  IF ln_ret_code = 2 THEN

                      ln_code    := NULL;

                      lc_message := NULL;

                      lb_val_rec := FALSE;

                      ln_code := -1;


                      lc_message := lc_err_msg;

                      xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                                 ,p_prog_type      => G_PROG_TYPE
                                                 ,p_prog_id        => ln_request_id 
                                                 ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                                 ,p_message        => lc_message
                                                 ,p_code           => ln_code
                                                 ,p_err_code       => 'REVENUE_CLASS'
                                               );


                      xx_cn_util_pkg.DEBUG (lc_message);

                      xx_cn_util_pkg.display_log (lc_message);
                      
                  ELSIF ln_ret_code = 0 THEN
                      
                      ----------------------------------------------------
                      -- Check for Division
                      -- Included as per the error logging 02-Nov-2007
                      ----------------------------------------------------
                      IF lt_omtrx(idx).division IS NULL THEN
                  
                          
                          ln_code    := NULL;
                          
                          lc_message := NULL;
                          
                          lb_val_rec := FALSE;
                           
                          ln_code := -1;
                          
                          ln_null_div := ln_null_div +1;
                          
                          FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0051_NO_DIVISION');
                          FND_MESSAGE.set_token ('ORDER_NO',lt_omtrx(idx).order_number);
                          FND_MESSAGE.set_token ('LINE_NO', lt_omtrx(idx).line_number);
                                              
                          lc_message := FND_MESSAGE.get;
                     
                          xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                                     ,p_prog_type      => G_PROG_TYPE
                                                     ,p_prog_id        => ln_request_id 
                                                     ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                                     ,p_message        => lc_message
                                                     ,p_code           => ln_code
                                                     ,p_err_code       => 'XX_OIC_0051_NO_DIVISION'
                                                   );
                           
                           
                          xx_cn_util_pkg.DEBUG (lc_message);
                           
                                            
                      ---------------------------
                      -- Check for Revenue Class
                      ---------------------------
                      ELSIF lt_omtrx(idx).revenue_class_id IS NULL THEN
                      
                           
                          ln_code    := NULL;
                          
                          lc_message := NULL;
                          
                          lb_val_rec := FALSE;
                           
                          ln_code := -1;
                          
                          ln_null_rev_class := ln_null_rev_class +1;
                          
                          FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0032_NO_REV_CLASS_ID');
                          FND_MESSAGE.set_token ('ORDER_NO',lt_omtrx(idx).order_number);
                          FND_MESSAGE.set_token ('LINE_NO', lt_omtrx(idx).line_number);
                                              
                          lc_message := FND_MESSAGE.get;
                      
                          xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                                     ,p_prog_type      => G_PROG_TYPE
                                                     ,p_prog_id        => ln_request_id 
                                                     ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                                     ,p_message        => lc_message
                                                     ,p_code           => ln_code
                                                     ,p_err_code       => 'XX_OIC_0032_NO_REV_CLASS_ID'
                                                   );
                           
                           
                          xx_cn_util_pkg.DEBUG (lc_message);
                           
                                                
                      END IF; -- End of check on division and rev class
                      
                      --End of changes on 02-Nov-2007
                      
                  END IF; -- End of branch on ln_ret_code

             ELSE
             
                ln_code    := NULL;

                lc_message := NULL;

                lb_val_rec := FALSE;


                ln_code := -1;
                
                ln_null_priv_band := ln_null_priv_band +1;
                
                ln_null_rev_class := ln_null_rev_class +1;
                
                ln_null_div       := ln_null_div +1;

                FND_MESSAGE.set_name  ('XXCRM', 'XX_OIC_0025_NO_PRVT_FLAG');
                FND_MESSAGE.set_token ('INV_ID',lt_omtrx(idx).inventory_item_id);

                lc_message := FND_MESSAGE.get;

                xx_cn_util_pkg.log_error (  p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                           ,p_prog_type      => G_PROG_TYPE
                                           ,p_prog_id        => ln_request_id 
                                           ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                           ,p_message        => lc_message
                                           ,p_code           => ln_code
                                           ,p_err_code       => 'XX_OIC_0025_NO_PRVT_FLAG'
                                         );


                xx_cn_util_pkg.DEBUG (lc_message);

                
             END IF; -- End of branch on private brand flag check


             -- Assigning value to lt_omtrx_suc pl/sql table type

             IF lb_val_rec = TRUE THEN

                lt_omtrx_suc(lt_omtrx_suc.COUNT+1) := lt_omtrx(idx);
             
             ELSIF lb_val_rec = FALSE THEN   
                
                lt_omtrx_fal(lt_omtrx_fal.COUNT+1) := lt_omtrx(idx); 

             END IF;


      END LOOP; -- End of lt_omtrx loop
      
      END IF; -- End of main cursor count branch

      -- Bulk insert into XX_CN_OM_TRX table
      xx_cn_util_pkg.DEBUG('Extract: Inserting into XX_CN_OM_TRX.');

      FORALL i IN lt_omtrx_suc.FIRST .. lt_omtrx_suc.LAST

        INSERT INTO xx_cn_om_trx VALUES lt_omtrx_suc(i);


      ln_om_trx_count := ln_om_trx_count + lt_omtrx_suc.COUNT;


      ----------------------------------------------------------------------------
      --Report all errored records to the End User
      ----------------------------------------------------------------------------
      IF(lt_omtrx_fal.COUNT > 0) THEN
      
            xx_cn_util_pkg.display_log        (RPAD (' ', 230, '_'));
            xx_cn_util_pkg.display_log        ('');
      
            xx_cn_util_pkg.display_log        (' Records having NULL Revenue Class                 :              '||LPAD(ln_null_rev_class,15));
            xx_cn_util_pkg.display_log        ('');
            xx_cn_util_pkg.display_log        (' Records having NULL Division                      :              '||LPAD(ln_null_div,15));
            xx_cn_util_pkg.display_log        ('');
            xx_cn_util_pkg.display_log        (' Records having NULL Private Brand                 :              '||LPAD(ln_null_priv_band,15));
            xx_cn_util_pkg.display_log        ('');
            xx_cn_util_pkg.display_log        (' Records having NULL PO Cost                       :              '||LPAD(ln_null_po_cost,15));
            xx_cn_util_pkg.display_log        ('');
            xx_cn_util_pkg.display_log        (' Records having NULL Rollup Date                   :              '||LPAD(ln_null_rollup_date,15));
            xx_cn_util_pkg.display_log        ('');
            xx_cn_util_pkg.display_out        (' Number of Errored Sales Order Records             :              '||LPAD(lt_omtrx_fal.COUNT,15));
            xx_cn_util_pkg.display_out        ('');
            xx_cn_util_pkg.display_log        (' Number of Errored Sales Order Records             :              '||LPAD(lt_omtrx_fal.COUNT,15));
            xx_cn_util_pkg.display_log        ('');
            xx_cn_util_pkg.display_log        (' (The Errored Records have a NULL or INVALID value in Revenue Class ID, Division, Private Brand, PO Cost, Department Code, Class Code or Rollup Date.)');
            xx_cn_util_pkg.display_log        ('');
            xx_cn_util_pkg.display_log        (RPAD (' ', 230, '_'));
            xx_cn_util_pkg.display_log 
                                              (     RPAD (' CUSTOMER_ID', 15)
                                                 || CHR(9)
                                                 || RPAD ('INVENTORY_ITEM_ID', 20)
                                                 || CHR(9)
                                                 || RPAD ('ORDER_NUMBER', 20)
                                                 || CHR(9)
                                                 || RPAD ('ORDER_DATE', 15)
                                                 || CHR(9)
                                                 || RPAD ('LINE_ID', 15)
                                                 || CHR(9)
                                                 || RPAD ('LINE_NUMBER', 15)
                                                 || CHR(9)
                                                 || RPAD ('ROLLUP_DATE', 15)
                                                 || CHR(9)
                                                 || LPAD ('COST', 10)
                                                 || RPAD (' ', 5)
                                                 || CHR(9)
                                                 || RPAD ('PRIVATE_BRAND', 15)
                                                 || CHR(9)
                                                 || RPAD ('DIVISION', 15)
                                                 || CHR(9)
                                                 || RPAD ('REVENUE_CLASS', 15)
                                                 || CHR(9)
                                                 || RPAD ('DEPT_CODE', 15)
                                                 || CHR(9)
                                                 || RPAD ('CLASS_CODE', 15)
                                                 || CHR(9)
                                               );
            xx_cn_util_pkg.display_log        (RPAD (' ', 230, '_'));
            
            
            FOR i IN lt_omtrx_fal.FIRST .. lt_omtrx_fal.LAST
            LOOP
                 xx_cn_util_pkg.display_log 
                                              (     RPAD (' '||NVL(TO_CHAR(lt_omtrx_fal(i).customer_id),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).inventory_item_id),' '), 20)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).order_number),' '), 20)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).order_date),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).source_trx_line_id),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).line_number),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).rollup_date),' '), 15)
                                                 || CHR(9)
                                                 || LPAD (NVL(TRIM(TO_CHAR(ROUND(lt_omtrx_fal(i).cost,2),'9,999,999,999,999,999,999,999,999,999,999,999,999.99')),' '), 10)
                                                 || RPAD (' ', 5)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).private_brand),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).division),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).revenue_class_id),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).department_code),' '), 15)
                                                 || CHR(9)
                                                 || RPAD (NVL(TO_CHAR(lt_omtrx_fal(i).class_code),' '), 15)
                                                 || CHR(9)
                                               );
            END LOOP;

            xx_cn_util_pkg.display_log        (RPAD (' ', 230, '_'));
            xx_cn_util_pkg.display_log        ('');

            x_retcode                         := 1;

            x_errbuf                          := 'Procedure: OM_EXTRCAT_CHILD: This Batch has some errored Records';
            
      END IF; -- End of error reporting

      -- Update the xx_cn_not_trx table with extracted flag to Y
      xx_cn_util_pkg.DEBUG('Extract: Updating extracted_flag in XX_CN_NOT_TRX .');

      UPDATE xx_cn_not_trx XCNT
      SET    XCNT.extracted_flag    = 'Y'
            ,XCNT.last_updated_by   = ln_last_updated_by
            ,XCNT.last_update_date  = ld_last_update_date
            ,XCNT.last_update_login = ln_last_update_login
      WHERE (XCNT.batch_id,XCNT.source_trx_id,xcnt.source_trx_line_id)
                                    = (SELECT XCOT.batch_id
                                             ,XCNT.source_trx_id
                                             ,XCNT.source_trx_line_id
                                       FROM   xx_cn_om_trx XCOT
                                       WHERE  XCOT.source_trx_id      = XCNT.source_trx_id
                                       AND    XCOT.source_trx_line_id = XCNT.source_trx_line_id
                                       AND    XCOT.event_id           = G_EVENT_ID);


      xx_cn_util_pkg.DEBUG('Extract: Updated extracted_flag in XX_CN_NOT_TRX.');

      COMMIT;

      EXIT WHEN lcu_om_trx%NOTFOUND;
  
   END LOOP;

   CLOSE lcu_om_trx;
   

   xx_cn_util_pkg.DEBUG('Extract: Number of records inserted into XX_CN_OM_TRX table: '||ln_om_trx_count || '    for batch:  '||p_batch_id );

   xx_cn_util_pkg.display_out(' OM Extract: Number of records inserted into XX_CN_OM_TRX table: '||ln_om_trx_count );
   xx_cn_util_pkg.display_out(' ');
   
   xx_cn_util_pkg.display_out (RPAD (' ', 100, '_'));
   xx_cn_util_pkg.display_out ('');
    

   lc_error_message := 'Finished Inserting records into XX_CN_OM_TRX table for batch: '||p_batch_id;

   xx_cn_util_pkg.update_batch(
                                p_process_audit_id      => ln_proc_col_audit_id
                               ,p_execution_code        => 0
                               ,p_error_message         => lc_error_message
                              );


   xx_cn_util_pkg.end_batch (ln_proc_col_audit_id);


   IF lb_val_rec = FALSE THEN

        x_retcode := 1;
   ELSE

        x_retcode := 0;

   END IF;



 EXCEPTION

   WHEN OTHERS THEN

         ROLLBACK;

         CLOSE lcu_om_trx;

         ln_code := -1;

         FND_MESSAGE.set_name ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         FND_MESSAGE.set_token ('SQL_CODE', SQLCODE);
         FND_MESSAGE.set_token ('SQL_ERR', SQLERRM);

         lc_message := FND_MESSAGE.get;

         xx_cn_util_pkg.log_error ( p_prog_name      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                   ,p_prog_type      => G_PROG_TYPE
                                   ,p_prog_id        => ln_request_id 
                                   ,p_exception      => 'XX_CN_OM_EXTRACT_PKG.OM_EXTRACT_CHILD'
                                   ,p_message        => lc_message
                                   ,p_code           => ln_code
                                   ,p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                  );


         xx_cn_util_pkg.DEBUG (lc_message);

         xx_cn_util_pkg.display_log (lc_message);

         xx_cn_util_pkg.update_batch(
                                         p_process_audit_id      => ln_proc_col_audit_id
                                        ,p_execution_code        => SQLCODE
                                        ,p_error_message         => lc_message
                                       );


         xx_cn_util_pkg.end_batch (ln_proc_col_audit_id);

         x_retcode := 2;

         x_errbuf  := lc_message;

 END om_extract_child;

 END  XX_CN_OM_EXTRACT_PKG;
/

SHOW ERRORS

EXIT;