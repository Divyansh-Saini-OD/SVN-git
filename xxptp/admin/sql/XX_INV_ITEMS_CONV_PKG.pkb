SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_ITEMS_CONV_PKG
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- |                Oracle NAIO Consulting Organization                                 |
-- +====================================================================================+
-- | Name        :  XX_INV_ITEMS_CONV_PKG.pkb                                           |
-- | Description :  INV Item Cross Reference Master Package Spec                        |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===================================        |
-- |DRAFT 1a  16-May-2007 Fajna K.P          Initial draft version                      |
-- |DRAFT 1b  29-May-2007 Parvez Siddiqui    TL Reviewed                                |
-- |DRAFT 1c  30-May-2007 Fajna K.P          Incorporated TL Review                     |
-- |                                         Comments                                   |
-- |DRAFT 1d  05-Jun-2007 Fajna K.P          Incorporated Onsite Review                 |
-- |                                         Comments                                   |
-- |DRAFT 1e  07-Jun-2007 Susheel Raina      TL Reviewed                                |
-- |DRAFT 1f  08-Jun-2007 Fajna K.P          Incorporated Onsite Review                 |
-- |                                         Comments                                   |
-- |DRAFT 1g  12-Jun-2007 Fajna K.P          Incorporated TL Review                     |
-- |                                         Comments                                   |
-- |DRAFT 1h  19-Jun-2007 Fajna K.P          Incorporated Onsite Review                 |
-- |                                         Comments                                   |
-- |                                         Applied Merchendising Template             |
-- |                                         for Child Orgs except DropShip Orgs        |
-- |DRAFT 1i  19-Jun-2007 Susheel Raina      TL Reviewed                                |
-- |DRAFT 1j  20-Jun-2007 Parvez Siddiqui    TL Reviewed                                |
-- |DRAFT 1k  22-Jun-2007 Fajna K.P          Modified table names to xx_item_master_stg |
-- |                                         and xx_item_loc_stg                        |
-- |DRAFT 1l  25-Jun-2007 Fajna K.P          Modified segment2 of PO CATEGORY from      |
-- |                                         'Trade' to 'TRADE'                         |
-- |DRAFT 1m  25-Jun-2007 Fajna K.P          Removed join for HR_LOOKUPS from           |
-- |                                         lcu_location_type  and lcu_val_orgs        |
-- |                                         to improve performance                     |
-- |DRAFT 1n  25-Jun-2007 Parvez Siddiqui    TL Reviewed                                |
-- |DRAFT 1o  26-Jun-2007 Fajna K.P          Modified code to update item_process_flag  |
-- |                                         and location_process_flag of failure items |
-- |                                         followed by updating the process flags for | 
-- |                                         success items                              |
-- |DRAFT 1p  26-Jun-2007 Parvez Siddiqui    TL Reviewed                                |
-- |DRAFT 1q  28-Jun-2007 Fajna K.P          Modified code to pick Master and child     |
-- |                                         records based on process flag rather than  |
-- |                                         other four custom process flags            |
-- |                                         Modified code to validate and create ODPB  |
-- |                                         category assignment only if the            |
-- |                                         OD_PRIVATE_BRAND_FLG is "Y"                |
-- |DRAFT 1r  28-Jun-2007 Parvez Siddiqui    TL Reviewed                                |
-- |DRAFT 1s  04-Jul-2007 Fajna K.P          Modified code to incorporate ATP CATEGORY  |
-- |                                         and Non-Code Item                          |
-- |DRAFT 1t  05-Jul-2007 Parvez Siddiqui    TL Reviewed                                |
-- |DRAFT 1u  10-Jul-2007 Fajna K.P          Modified code to pass the item status as   |
-- |                                         coming from Staging tables(A,D,I)          |
-- |DRAFT 1v  10-Jul-2007 Parvez Siddiqui    TL Reviewed                                |
-- |1.0       13-Jul-2007 Arun Andavar       Modified reprocessing logic and modified   |
-- |                                          category queries to pick the active record|
-- |1.1       13-Jul-2007 Susheel Raina      TL Reviewed                                |
-- +====================================================================================+
AS
----------------------------
--Declaring Global Constants
----------------------------
G_TRANSACTION_TYPE          CONSTANT mtl_system_items_interface.transaction_type%TYPE           :=  'CREATE';
G_PROCESS_FLAG              CONSTANT mtl_system_items_interface.process_flag%TYPE               :=   1;
G_USER_ID                   CONSTANT mtl_system_items_interface.created_by%TYPE                 :=   FND_GLOBAL.user_id;
G_DATE                      CONSTANT mtl_system_items_interface.last_update_date%TYPE           :=   SYSDATE;
G_MER_TEMPLATE              CONSTANT mtl_item_templates.template_name%TYPE                      :=  'OD Merchandising Item';
G_DS_TEMPLATE               CONSTANT mtl_item_templates.template_name%TYPE                      :=  'OD Drop Ship Item';
G_INV_STRUCTURE_CODE        CONSTANT fnd_id_flex_structures_vl.id_flex_structure_code%TYPE      :=  'ITEM_CATEGORIES';
G_ODPB_STRUCTURE_CODE       CONSTANT fnd_id_flex_structures_vl.id_flex_structure_code%TYPE      :=  'OD_ITM_BRAND_CATEGORY';
G_PO_STRUCTURE_CODE         CONSTANT fnd_id_flex_structures_vl.id_flex_structure_code%TYPE      :=  'PO_ITEM_CATEGORY';
G_ATP_STRUCTURE_CODE        CONSTANT fnd_id_flex_structures_vl.id_flex_structure_code%TYPE      :=  'OD_ATP_PLANNING_CATEGORY';
G_ID_FLEX_CODE              CONSTANT fnd_id_flex_structures_vl.id_flex_code%TYPE                :=  'MCAT';
G_APPLICATION_ID            CONSTANT fnd_id_flex_structures_vl.application_id%TYPE              :=   401;
G_INV_CATEGORY_SET          CONSTANT mtl_category_sets.category_set_name%TYPE                   :=  'Inventory';
G_ODPB_CATEGORY_SET         CONSTANT mtl_category_sets.category_set_name%TYPE                   :=  'Office Depot Private Brand';
G_PO_CATEGORY_SET           CONSTANT mtl_category_sets.category_set_name%TYPE                   :=  'PO CATEGORY';
G_ATP_CATEGORY_SET          CONSTANT mtl_category_sets.category_set_name%TYPE                   :=  'ATP_CATEGORY';
G_CONVERSION_CODE           CONSTANT xx_com_conversions_conv.conversion_code%TYPE               :=  'C0258_Items';
G_PACKAGE_NAME              CONSTANT VARCHAR2(30)                                               :=  'XX_INV_ITEMS_CONV_PKG';
G_APPLICATION               CONSTANT VARCHAR2(10)                                               :=  'INV';
G_CHILD_PROGRAM             CONSTANT VARCHAR2(50)                                               :=  'XX_INV_IT_CONV_PKG_CHILD_MAIN';
G_COMM_APPLICATION          CONSTANT VARCHAR2(10)                                               :=  'XXCOMN';
G_SUMM_PROGRAM              CONSTANT VARCHAR2(50)                                               :=  'XXCOMCONVSUMMREP';
G_EXCEP_PROGRAM             CONSTANT VARCHAR2(50)                                               :=  'XXCOMCONVEXPREP';
G_SLEEP                     CONSTANT PLS_INTEGER                                                :=   60;
G_MAX_WAIT_TIME             CONSTANT PLS_INTEGER                                                :=   300;
G_LIMIT_SIZE                CONSTANT PLS_INTEGER                                                :=   10000;

----------------------------
--Declaring Global Variables
----------------------------
gc_master_setup_status      VARCHAR2(1);
gc_valorg_setup_status      VARCHAR2(1);
gc_sqlerrm                  VARCHAR2(5000);
gc_sqlcode                  VARCHAR2(20);
gn_conversion_id            xx_com_exceptions_log_conv.converion_id%TYPE;
gn_master_org_id            mtl_parameters.organization_id%TYPE;
gn_mer_template_id          mtl_item_templates.template_id%TYPE;
gn_ds_template_id           mtl_item_templates.template_id%TYPE;
gn_inv_category_set_id      mtl_category_sets.category_set_id%TYPE;
gn_odpb_category_set_id     mtl_category_sets.category_set_id%TYPE;
gn_po_category_set_id       mtl_category_sets.category_set_id%TYPE;
gn_atp_category_set_id      mtl_category_sets.category_set_id%TYPE;
gn_inv_structure_id         mtl_categories_b.structure_id%TYPE;
gn_odpb_structure_id        mtl_categories_b.structure_id%TYPE;
gn_po_structure_id          mtl_categories_b.structure_id%TYPE;
gn_atp_structure_id         mtl_categories_b.structure_id%TYPE;
gn_request_id               PLS_INTEGER;
gn_batch_size               PLS_INTEGER;
gn_max_child_req            PLS_INTEGER;
gn_batch_count              PLS_INTEGER := 0;
gn_record_count             PLS_INTEGER := 0;
gn_index_request_id         PLS_INTEGER := 0;

----------------------------------------------------
--Declaring record variables for logging bulk errors 
----------------------------------------------------
gr_item_err_rec         xx_com_exceptions_log_conv%ROWTYPE;
gr_item_err_empty_rec   xx_com_exceptions_log_conv%ROWTYPE;

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE val_org_tbl_type IS TABLE OF hr_organization_units.organization_id%TYPE
INDEX BY BINARY_INTEGER;
gt_val_orgs  val_org_tbl_type;

TYPE req_id_tbl_type IS TABLE OF fnd_concurrent_requests.request_id%TYPE
INDEX BY BINARY_INTEGER;
gt_req_id req_id_tbl_type;

-- +====================================================================+
-- | Name        :  display_log                                         |
-- | Description :  This procedure is invoked to print in the log file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
PROCEDURE display_log(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);
END;

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the out file  |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )
IS
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END;

-- +====================================================================+
-- | Name        :  bulk_log_error                                      |
-- | Description :  This procedure is invoked to insert errors into     |
-- |                xx_com_exceptions_log_conv                          |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+
PROCEDURE bulk_log_error(
                          p_error_msg           IN VARCHAR2
                         ,p_error_code          IN VARCHAR2
                         ,p_control_id          IN VARCHAR2
                         ,p_request_id          IN VARCHAR2
                         ,p_converion_id        IN VARCHAR2
                         ,p_package_name        IN VARCHAR2
                         ,p_procedure_name      IN VARCHAR2
                         ,p_staging_table_name  IN VARCHAR2
                         ,p_batch_id            IN VARCHAR2
                       )
               
IS
BEGIN
    ------------------------------------
    --Initializing the error record type
    ------------------------------------
    gr_item_err_rec                     :=  gr_item_err_empty_rec;
    ------------------------------------------------------
    --Assigning values to the columns of error record type
    ------------------------------------------------------
    gr_item_err_rec.oracle_error_msg    :=  p_error_msg;
    gr_item_err_rec.oracle_error_code   :=  p_error_code;
    gr_item_err_rec.record_control_id   :=  p_control_id;
    gr_item_err_rec.request_id          :=  p_request_id;
    gr_item_err_rec.converion_id        :=  p_converion_id;
    gr_item_err_rec.package_name        :=  p_package_name;
    gr_item_err_rec.procedure_name      :=  p_procedure_name;
    gr_item_err_rec.staging_table_name  :=  p_staging_table_name;
    gr_item_err_rec.batch_id            :=  p_batch_id;

    XX_COM_CONV_ELEMENTS_PKG.bulk_add_message(gr_item_err_rec);
END bulk_log_error;

-- +======================================================================+
-- | Name        :  bat_child                                             |
-- | Description :  This procedure is invoked from the submit_sub_requests|
-- |                procedure. This would submit child requests based     |
-- |                on batch_size.                                        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_request_id                                          |
-- |                p_validate_only_flag                                  |
-- |                p_reset_status_flag                                   |
-- |                p_delete_flag                                         |
-- |                                                                      |
-- | Returns     :  x_time                                                |
-- |                x_errbuf                                              |
-- |                x_retcode                                             |
-- +======================================================================+
PROCEDURE bat_child(
                     p_request_id          IN  NUMBER
                    ,p_validate_only_flag  IN  VARCHAR2
                    ,p_reset_status_flag   IN  VARCHAR2
                    ,p_delete_flag         IN  VARCHAR2
                    ,x_time                OUT NOCOPY DATE
                    ,x_errbuf              OUT NOCOPY VARCHAR2
                    ,x_retcode             OUT NOCOPY VARCHAR2
                   )

IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_SUBMIT_CHILD     EXCEPTION;

ln_batch_size_count PLS_INTEGER;
ln_seq              PLS_INTEGER;
ln_req_count        PLS_INTEGER;
ln_master_count     PLS_INTEGER;
lt_conc_request_id  FND_CONCURRENT_REQUESTS.request_id%TYPE;

BEGIN
    
    ------------------------------------------------------------
    --Updating Master table with load batch id and process flags
    ------------------------------------------------------------
    SELECT XX_INV_ITEM_STG_BAT_S.NEXTVAL
    INTO   ln_seq
    FROM   DUAL;
    ------------------------------------------------------------
    --Updating Master table with load batch id and process flags
    ------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM
    SET    XSIM.load_batch_id               = ln_seq
          ,XSIM.item_process_flag           = (CASE WHEN item_process_flag          IS NULL  OR item_process_flag         =1   THEN 2 ELSE item_process_flag           END)
          ,XSIM.inv_category_process_flag   = (CASE WHEN inv_category_process_flag  IS NULL  OR inv_category_process_flag =1   THEN 2 ELSE inv_category_process_flag   END)
          ,XSIM.odpb_category_process_flag  = (CASE WHEN odpb_category_process_flag IS NULL  OR odpb_category_process_flag=1   THEN 2 ELSE odpb_category_process_flag  END)
          ,XSIM.po_category_process_flag    = (CASE WHEN po_category_process_flag   IS NULL  OR po_category_process_flag  =1   THEN 2 ELSE po_category_process_flag    END)
          ,XSIM.atp_category_process_flag   = (CASE WHEN atp_category_process_flag  IS NULL  OR atp_category_process_flag =1   THEN 2 ELSE atp_category_process_flag   END)
    WHERE  XSIM.load_batch_id               IS NULL 
    AND    XSIM.process_flag                = 1
    AND   ROWNUM<=gn_batch_size;   
    
    --Fetching Count of Eligible Records in the Master Table
    ln_master_count := SQL%ROWCOUNT;
    
    COMMIT;
    
    ---------------------------------------------------------------------------------------------
    --Initializing the batch size count ,record count variables and taking next value of sequence
    ---------------------------------------------------------------------------------------------
    ln_batch_size_count := ln_master_count;
    gn_record_count     := gn_record_count + ln_batch_size_count;
    
    ----------------------------------------------------------
    --Updating Child table with load batch id and process flag
    ----------------------------------------------------------
    UPDATE  xx_item_loc_stg XSIL 
    SET     XSIL.load_batch_id          = ln_seq
           ,XSIL.location_process_flag  = (CASE WHEN location_process_flag      IS NULL  OR location_process_flag = 1 THEN 2 ELSE location_process_flag     END)
    WHERE   XSIL.item IN  (SELECT item 
                           FROM   xx_item_master_stg XSIM
                           WHERE  XSIM.load_batch_id  =  ln_seq
                           AND    XSIM.process_flag   =  1
                          )
    AND     XSIL.load_batch_id          IS NULL  
    AND     XSIL.process_flag           = 1;
   
    COMMIT;
    -----------------------------------------
    --Submitting Child Program for each batch
    -----------------------------------------
    LOOP
        SELECT COUNT(1)
        INTO   ln_req_count
        FROM   fnd_concurrent_requests FCR
        WHERE  FCR.parent_request_id  = gn_request_id
        AND    FCR.phase_code IN ('P','R');
        
        IF  ln_req_count < gn_max_child_req THEN
            lt_conc_request_id := FND_REQUEST.submit_request(
                                                              application =>  G_APPLICATION
                                                             ,program     =>  G_CHILD_PROGRAM
                                                             ,sub_request =>  FALSE
                                                             ,argument1   =>  p_validate_only_flag
                                                             ,argument2   =>  p_reset_status_flag
                                                             ,argument3   =>  p_delete_flag
                                                             ,argument4   =>  ln_seq
                                                            );
            IF lt_conc_request_id = 0 THEN
                x_errbuf  := FND_MESSAGE.GET;
                RAISE EX_SUBMIT_CHILD;
            ELSE
                COMMIT;
                gn_index_request_id             := gn_index_request_id + 1;
                gn_batch_count                  := gn_batch_count + 1;
                gt_req_id(gn_index_request_id)  := lt_conc_request_id;
                x_time := SYSDATE;
                ------------------------------------
                --Log Conversion Control Information
                ------------------------------------
                XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                                p_conversion_id           => gn_conversion_id
                                                               ,p_batch_id                => ln_seq
                                                               ,p_num_bus_objs_processed  => ln_batch_size_count
                                                              );
                EXIT;
            END IF;
        ELSE
            DBMS_LOCK.SLEEP(G_SLEEP);
        END IF;
    END LOOP;

EXCEPTION
  WHEN EX_SUBMIT_CHILD THEN
       x_retcode := 2;
       x_errbuf  := 'Error in submitting child requests: ' || x_errbuf;
END bat_child;

-- +====================================================================+
-- | Name        :  get_conversion_id                                   |
-- | Description :  This procedure is invoked to get the conversion_id  |
-- |                ,batch_size and max_threads                         |
-- |                                                                    |
-- | Parameters  :                                                      |
-- |                                                                    |
-- | Returns     :  x_conversion_id                                     |
-- |                x_batch_size                                        |
-- |                x_max_threads                                       |
-- |                x_return_status                                     |
-- +====================================================================+
PROCEDURE get_conversion_id(
                             x_conversion_id  OUT NOCOPY  NUMBER
                            ,x_batch_size     OUT NOCOPY  NUMBER
                            ,x_max_threads    OUT NOCOPY  NUMBER
                            ,x_return_status  OUT NOCOPY  VARCHAR2
                           )
IS
ln_conversion_id PLS_INTEGER;
ln_batch_size    PLS_INTEGER;
ln_max_threads   PLS_INTEGER;

BEGIN
     SELECT  XCCC.conversion_id
            ,XCCC.batch_size
            ,XCCC.max_threads
     INTO    ln_conversion_id
            ,ln_batch_size
            ,ln_max_threads
     FROM    xx_com_conversions_conv XCCC
     WHERE   XCCC.conversion_code = G_CONVERSION_CODE;
     x_conversion_id := ln_conversion_id;
     x_batch_size    := ln_batch_size;
     x_max_threads   := ln_max_threads;
     x_return_status := 'S';
EXCEPTION
WHEN NO_DATA_FOUND THEN
    x_return_status := 'E';
WHEN OTHERS THEN
    display_log('Error while deriving conversion_id - '||SQLERRM);
END get_conversion_id;

-- +====================================================================+
-- | Name        :  update_batch_id                                     |
-- | Description :  This procedure is invoked to reset Batch Id to Null |
-- |                for Previously Errored Out Records                  |
-- |                                                                    |
-- | Parameters  :                                                      |
-- +====================================================================+
PROCEDURE update_batch_id( x_errbuf   OUT NOCOPY VARCHAR2
                          ,x_retcode  OUT NOCOPY VARCHAR2
                         )
IS

BEGIN
    ------------------------------------------------
    --Updating Master Process Flags for Reprocessing
    ------------------------------------------------
    --Added by Arun Andavar in ver 1.0 -START
    -- This prepares for reprocessing the master records those are either in error by itself
    --   or
    -- having some or all the location records in error for reprocessing
    --Added by Arun Andavar in ver 1.0 -END

    UPDATE xx_item_master_stg XSIM
    SET    XSIM.load_batch_id = NULL
          ,XSIM.item_process_flag           = (CASE WHEN item_process_flag          <>7    THEN 1 ELSE item_process_flag            END)
          ,XSIM.inv_category_process_flag   = (CASE WHEN inv_category_process_flag  <>7    THEN 1 ELSE inv_category_process_flag    END)
          ,XSIM.odpb_category_process_flag  = (CASE WHEN odpb_category_process_flag <>7    THEN 1 ELSE odpb_category_process_flag   END)
          ,XSIM.po_category_process_flag    = (CASE WHEN po_category_process_flag   <>7    THEN 1 ELSE po_category_process_flag     END)
          ,XSIM.atp_category_process_flag   = (CASE WHEN atp_category_process_flag  <>7    THEN 1 ELSE atp_category_process_flag    END)
    WHERE  XSIM.process_flag                = 1 
      AND (
               (   XSIM.item_process_flag           IN (2,3,4,6) 
               OR  XSIM.inv_category_process_flag   IN (2,3,4,6) 
               OR  XSIM.odpb_category_process_flag  IN (2,3,4,6) 
               OR  XSIM.po_category_process_flag    IN (2,3,4,6)
               OR  XSIM.atp_category_process_flag   IN (2,3,4,6)
               )
    --Added by Arun Andavar in ver 1.0 -START
               OR
               (    XSIM.item_process_flag           IN (7) 
               AND  XSIM.inv_category_process_flag   IN (7)
               AND  XSIM.odpb_category_process_flag  IN (7)
               AND  XSIM.po_category_process_flag    IN (7)
               AND  XSIM.atp_category_process_flag   IN (7)
               AND  EXISTS ( SELECT 1 
                             FROM   xx_item_loc_stg XSIL
                             WHERE  XSIL.location_process_flag   IN (2,3,4,6)
                             AND    XSIL.load_batch_id  IS NOT NULL
                             AND    XSIL.process_flag=1
                             AND    item = XSIM.item
                           )  
               )
    --Added by Arun Andavar in ver 1.0 -END
           );

    -----------------------------------------------
    --Updating Child Process Flags for Reprocessing
    -----------------------------------------------
    UPDATE xx_item_loc_stg XSIL
    SET    XSIL.load_batch_id           = NULL
          ,XSIL.location_process_flag   = 1
    WHERE  XSIL.process_flag            = 1
    AND    XSIL.item IN  (SELECT item 
                          FROM   xx_item_master_stg XSIM
                          WHERE  XSIM.load_batch_id  IS NULL
                          AND    XSIM.process_flag   = 1 
                         )
    AND    XSIL.location_process_flag   IN (2,3,4,6);
    
   
EXCEPTION
WHEN OTHERS THEN
    x_errbuf  := 'Unexpected error in update_batch_id - '||SQLERRM;
    x_retcode := 2;
END update_batch_id;

-- +====================================================================+
-- | Name        :  launch_summary_report                               |
-- | Description :  This procedure is invoked to Launch Conversion      |
-- |                Processing Summary Report for that run              |
-- |                                                                    |
-- | Returns  :     x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE launch_summary_report( x_errbuf   OUT NOCOPY VARCHAR2
                                ,x_retcode  OUT NOCOPY VARCHAR2
                               )
IS
EX_REP_SUMM             EXCEPTION;

lc_phase                VARCHAR2(03);
ln_summ_request_id      PLS_INTEGER;

BEGIN
    FOR i IN gt_req_id.FIRST .. gt_req_id.LAST
    LOOP
        LOOP
            SELECT FCR.phase_code
            INTO   lc_phase
            FROM   fnd_concurrent_requests FCR
            WHERE  FCR.request_id = gt_req_id(i);

            IF  lc_phase = 'C' THEN
              EXIT;
            ELSE
              DBMS_LOCK.SLEEP(G_SLEEP);
            END IF;
        END LOOP;
    END LOOP;

    ln_summ_request_id := FND_REQUEST.submit_request(
                                                      application => G_COMM_APPLICATION
                                                     ,program     => G_SUMM_PROGRAM
                                                     ,sub_request => FALSE               -- TRUE means is a sub request
                                                     ,argument1   => G_CONVERSION_CODE   -- CONVERSION_CODE
                                                     ,argument2   => gn_request_id       -- MASTER REQUEST ID
                                                     ,argument3   => NULL                -- REQUEST ID
                                                     ,argument4   => NULL                -- BATCH ID
                                                    );
    IF  ln_summ_request_id = 0 THEN
        x_errbuf  := FND_MESSAGE.GET;
        RAISE EX_REP_SUMM;
    ELSE
        COMMIT;
    END IF;
EXCEPTION
  WHEN EX_REP_SUMM THEN
       x_retcode := 2;
       x_errbuf  := 'Processing Summary Report for the batch could not be submitted: '|| x_errbuf;
END launch_summary_report;

-- +===================================================================+
-- | Name        :  submit_sub_requests                                |
-- | Description :  This procedure is invoked from the master_main     |
-- |                procedure. This would submit child requests based  |
-- |                on batch_size.                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_validate_omly_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_delete_flag                                      |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE submit_sub_requests(
                               p_validate_only_flag  IN  VARCHAR2
                              ,p_reset_status_flag   IN  VARCHAR2
                              ,p_delete_flag         IN  VARCHAR2
                              ,x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY VARCHAR2
                             )
IS
EX_NO_ENTRY          EXCEPTION;

ld_check_time        DATE;
ld_current_time      DATE;
ln_rem_time          NUMBER;
ln_current_count     PLS_INTEGER;
ln_last_count        PLS_INTEGER;
ln_last_loc_count    PLS_INTEGER;
ln_current_loc_count PLS_INTEGER;
lc_return_status     VARCHAR2(03);
lc_launch            VARCHAR2(02) := 'N';

BEGIN
    ---------------------------
    --Getting the Conversion id
    ---------------------------
    get_conversion_id(
                        x_conversion_id  => gn_conversion_id
                       ,x_batch_size     => gn_batch_size
                       ,x_max_threads    => gn_max_child_req
                       ,x_return_status  => lc_return_status
                     );
    -------------------------------------------
    --Update Batch Id if p_reset_status_flag='Y'
    -------------------------------------------
    IF lc_return_status = 'S' THEN
        IF  NVL(p_reset_status_flag,'N') = 'Y' THEN
            update_batch_id ( x_errbuf
                             ,x_retcode
                            );
        END IF;
        
        ld_check_time := SYSDATE;
        ln_current_count := 0;
        
        ---------------------------------------------------------------------------------------------------------------------------------------------------------
        --Getting the Count of Eligible records and call batch child if count>=batch size, else wait for the wait time specified and recheck for eligible records
        ---------------------------------------------------------------------------------------------------------------------------------------------------------
        LOOP
            ln_last_count     := ln_current_count;         

            SELECT COUNT(1)
            INTO   ln_current_count
            FROM   xx_item_master_stg XSIM
            WHERE  XSIM.load_batch_id               IS NULL
            AND    XSIM.process_flag                = 1;
                    
            IF (ln_current_count >= gn_batch_size ) THEN
                bat_child(
                          p_request_id          => gn_request_id
                         ,p_validate_only_flag  => p_validate_only_flag
                         ,p_reset_status_flag   => p_reset_status_flag
                         ,p_delete_flag         => p_delete_flag            
                         ,x_time                => ld_check_time
                         ,x_errbuf              => x_errbuf
                         ,x_retcode             => x_retcode
                         );
               lc_launch := 'Y';
            ELSE
                IF ln_last_count = ln_current_count   THEN
                   ld_current_time := SYSDATE;
                   ln_rem_time := (ld_current_time - ld_check_time)*86400;
                   
                   IF  ln_rem_time > G_MAX_WAIT_TIME THEN
                       EXIT;
                   ELSE
                       DBMS_LOCK.SLEEP(G_SLEEP);
                   END IF; -- ln_rem_time > G_MAX_WAIT_TIME
                   
                ELSE
                    DBMS_LOCK.SLEEP(G_SLEEP);
                END IF; -- ln_last_count = ln_current_count
            END IF; --  ln_current_count >= gn_batch_size
        END LOOP;

        IF (ln_current_count <> 0  )THEN
           bat_child(
                      p_request_id          => gn_request_id
                     ,p_validate_only_flag  => p_validate_only_flag
                     ,p_reset_status_flag   => p_reset_status_flag
                     ,p_delete_flag         => p_delete_flag
                     ,x_time                => ld_check_time
                     ,x_errbuf              => x_errbuf
                     ,x_retcode             => x_retcode
                    );
           lc_launch := 'Y';
        END IF;

        IF  lc_launch = 'N' THEN
            display_log('No Data Found in the Table XX_ITEM_MASTER_STG');
            x_retcode := 1;
        ELSE
            launch_summary_report(
                                   x_errbuf
                                  ,x_retcode
                                 );
        END IF;
        --------------------------------------------------------------------------------
        --Displaying the Batch and Item Information in the output file of Matser Program
        --------------------------------------------------------------------------------
        display_out(RPAD('=',38,'='));
        display_out(RPAD('Batch Size                 : ',29,' ')||RPAD(gn_batch_size,9,' '));
        display_out(RPAD('Number of Batches Launched : ',29,' ')||RPAD(gn_batch_count,9,' '));
        display_out(RPAD('Number of Records          : ',29,' ')||RPAD(gn_record_count,9,' '));
        display_out(RPAD('=',38,'='));
    ELSE
        RAISE EX_NO_ENTRY;
    END IF; -- lc_return_status
EXCEPTION
WHEN EX_NO_ENTRY THEN
    x_retcode := 2;
    display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE);
END submit_sub_requests;

-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description :  This procedure is invoked to Launch Exception       |
-- |                Report for that batch                               |
-- |                                                                    |
-- | Parameters  :  p_batch_id                                          |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+

PROCEDURE launch_exception_report(
                                   p_batch_id IN NUMBER
                                  ,x_errbuf   OUT NOCOPY VARCHAR2 
                                  ,x_retcode  OUT NOCOPY VARCHAR2 
                                 )
IS
EX_REP_EXC              EXCEPTION;
ln_excep_request_id     PLS_INTEGER;

BEGIN
    ------------------------------------------------
    --Submitting the Exception Report for each batch
    ------------------------------------------------
    ln_excep_request_id := FND_REQUEST.submit_request(
                                                         application =>  G_COMM_APPLICATION
                                                        ,program     =>  G_EXCEP_PROGRAM
                                                        ,sub_request =>  FALSE                         -- TRUE means is a sub request
                                                        ,argument1   =>  G_CONVERSION_CODE             -- conversion_code
                                                        ,argument2   =>  NULL                          -- MASTER REQUEST ID
                                                        ,argument3   =>  fnd_global.conc_request_id    -- REQUEST ID
                                                        ,argument4   =>  p_batch_id                    -- BATCH ID
                                                     );
    IF  ln_excep_request_id = 0 THEN
        x_errbuf  := FND_MESSAGE.GET;
        RAISE EX_REP_EXC;
    ELSE
        COMMIT;
    END IF;

EXCEPTION
WHEN EX_REP_EXC THEN
    x_retcode := 2;
    x_errbuf  := 'Exception Summary Report for the batch '||p_batch_id||' could not be submitted: ' || x_errbuf;
    bulk_log_error( p_error_msg          =>  'Exception Summary Report for the batch '||p_batch_id||' could not be submitted: ' || x_errbuf
                   ,p_error_code         =>  NULL
                   ,p_control_id         =>  NULL
                   ,p_request_id         =>  fnd_global.conc_request_id
                   ,p_converion_id       =>  gn_conversion_id   
                   ,p_package_name       =>  G_PACKAGE_NAME
                   ,p_procedure_name     =>  'launch_exception_report'
                   ,p_staging_table_name =>  NULL
                   ,p_batch_id           =>  p_batch_id
                  );
    XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
END launch_exception_report;

-- +====================================================================+
-- | Name        :  get_master_request_id                               |
-- | Description :  This procedure is invoked to get the                |
-- |                master_request_Id                                   |izat
-- |                                                                    |
-- | Parameters  :  p_conversion_id                                     |
-- |                p_batch_id                                          |
-- |                                                                    |
-- | Returns     :  Master_Request_Id                                   |
-- |                                                                    |
-- +====================================================================+

PROCEDURE get_master_request_id(
                                 p_conversion_id      IN  NUMBER
                                ,p_batch_id           IN  NUMBER
                                ,x_master_request_id  OUT NOCOPY NUMBER
                               )
IS

BEGIN
    -------------------------------
    --Getting the master Request Id
    -------------------------------
    SELECT XCCIC.master_request_id
    INTO   x_master_request_id
    FROM   xx_com_control_info_conv XCCIC
    WHERE  XCCIC.conversion_id = p_conversion_id
    AND    XCCIC.batch_id      = p_batch_id;
 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        x_master_request_id := NULL;
    WHEN OTHERS THEN
        display_log('Error while deriving master_request_id - '||SQLERRM);
END get_master_request_id;

-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the OD: INV Items    |
-- |                Conversion Master Concurrent Request.This would     |
-- |                submit child programs based on batch_size           |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_validate_omly_flag                                |
-- |                p_reset_status_flag                                 |
-- |                p_delete_flag                                       |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+

PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
                     ,p_validate_only_flag  IN  VARCHAR2
                     ,p_reset_status_flag   IN  VARCHAR2
                     ,p_delete_flag         IN  VARCHAR2
                     )
IS

EX_SUB_REQ       EXCEPTION;
lc_request_data  VARCHAR2(1000);
lc_error_message VARCHAR2(4000);
ln_return_status PLS_INTEGER;

BEGIN
    -------------------------------------------------------------
    --Submitting Sub Requests corresponding to the Child Programs
    -------------------------------------------------------------
    gn_request_id   := FND_GLOBAL.CONC_REQUEST_ID;
    
    submit_sub_requests(
                         p_validate_only_flag
                        ,p_reset_status_flag
                        ,p_delete_flag
                        ,lc_error_message
                        ,ln_return_status
                       );

    IF ln_return_status <> 0 THEN
       x_errbuf := lc_error_message;
       RAISE EX_SUB_REQ;
    END IF;


EXCEPTION
WHEN EX_SUB_REQ THEN
   x_retcode := 2;   
WHEN NO_DATA_FOUND THEN
    x_retcode := 2;
    display_log('No Data Found');
WHEN OTHERS THEN
   x_retcode := 2;
   x_errbuf  := 'Unexpected error in master_main procedure - '||SQLERRM;
END master_main;

-- +===================================================================+
-- | Name        :  validate_setups                                    |
-- | Description :  This procedure is invoked from validate_item_data  |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :   p_batch_id                                        |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE validate_setups(p_batch_id     IN  NUMBER
                         )
IS

---------------------------
--Declaring Local Variables
---------------------------
lc_masterorg_status         VARCHAR2(1):='Y';
lc_mer_template_status      VARCHAR2(1):='Y';

---------------------------------------
--Cursor to get the Master Organization
---------------------------------------
CURSOR lcu_master_org
IS
SELECT MP.organization_id
FROM   mtl_parameters MP
WHERE  MP.organization_id=MP.master_organization_id
AND    ROWNUM=1;

-------------------------------------------------------------
--Cursor to get the Template Ids for the three Templates used
-------------------------------------------------------------
CURSOR lcu_templates
IS
SELECT MIN(CASE WHEN template_name = G_MER_TEMPLATE     THEN    template_id END) I,
       MIN(CASE WHEN template_name = G_DS_TEMPLATE      THEN    template_id END) K
FROM   mtl_item_templates MIT
WHERE  UPPER(MIT.template_name)IN (UPPER(G_MER_TEMPLATE),UPPER(G_DS_TEMPLATE)); 

---------------------------------------------------------------------
--Cursor to get the Category Set Ids  for the four Category sets used
---------------------------------------------------------------------
CURSOR lcu_category_sets
IS
SELECT MIN(CASE WHEN category_set_name = G_INV_CATEGORY_SET     THEN    category_set_id END) I,
       MIN(CASE WHEN category_set_name = G_ODPB_CATEGORY_SET    THEN    category_set_id END) J,
       MIN(CASE WHEN category_set_name = G_PO_CATEGORY_SET      THEN    category_set_id END) K,
       MIN(CASE WHEN category_set_name = G_ATP_CATEGORY_SET     THEN    category_set_id END) L
FROM   mtl_category_sets MCS
WHERE  UPPER(MCS.category_set_name)IN (UPPER(G_INV_CATEGORY_SET),UPPER(G_ODPB_CATEGORY_SET),UPPER(G_PO_CATEGORY_SET),UPPER(G_ATP_CATEGORY_SET)); 

----------------------------------------------------------
--Cursor to get Structure Ids for the four Structure Codes
----------------------------------------------------------
CURSOR lcu_structure_id
IS
SELECT MIN(CASE WHEN id_flex_structure_code = G_INV_STRUCTURE_CODE     THEN    id_flex_num END) I,
       MIN(CASE WHEN id_flex_structure_code = G_ODPB_STRUCTURE_CODE    THEN    id_flex_num END) J,
       MIN(CASE WHEN id_flex_structure_code = G_PO_STRUCTURE_CODE      THEN    id_flex_num END) K,
       MIN(CASE WHEN id_flex_structure_code = G_ATP_STRUCTURE_CODE     THEN    id_flex_num END) L
FROM   fnd_id_flex_structures_vl FIFS
WHERE  UPPER(FIFS.id_flex_structure_code)IN (UPPER(G_INV_STRUCTURE_CODE ),UPPER(G_ODPB_STRUCTURE_CODE ),UPPER(G_PO_STRUCTURE_CODE ),UPPER(G_ATP_STRUCTURE_CODE ))
AND    FIFS.application_id = G_APPLICATION_ID; 

--------------------------------------------
--Cursor to get the Validation Organizations
--------------------------------------------
CURSOR lcu_val_orgs
IS
SELECT HOU.organization_id
FROM   hr_organization_units HOU
WHERE  HOU.type='VAL'
AND    SYSDATE BETWEEN NVL(HOU.date_from,SYSDATE) AND NVL(HOU.date_to,SYSDATE+1);

BEGIN
    --------------------------------
    --Master Organization Validation
    --------------------------------
    OPEN lcu_master_org;
    FETCH lcu_master_org INTO gn_master_org_id;
    IF  lcu_master_org%NOTFOUND THEN
        display_log('Master Organizations are not defined in the System');
        lc_masterorg_status:='N';
        bulk_log_error( p_error_msg          =>  'Master Organizations are not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    CLOSE lcu_master_org;
    ---------------------
    --Template Validation 
    ---------------------
    OPEN lcu_templates;
    FETCH lcu_templates INTO gn_mer_template_id,gn_ds_template_id;
    IF  gn_mer_template_id IS NULL  THEN
        display_log('OD Merchandising Item Template not defined in the System');
        lc_mer_template_status:='N';
        bulk_log_error( p_error_msg          =>  'OD Merchandising Item Template is not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    IF  gn_ds_template_id IS NULL THEN
        display_log('OD Drop Ship Item Template not defined in the System');
        bulk_log_error( p_error_msg          =>  'OD Drop Ship Item Template is not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                     ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    CLOSE lcu_templates;   

    IF (lc_masterorg_status='N' OR lc_mer_template_status='N') THEN
        gc_master_setup_status:='N';
        display_log('Master Seups are not defined in the System');
    ELSE
        gc_master_setup_status:='Y';
        display_log('Master Seups are defined in the System');
    END IF;    
    -------------------------
    --Category Set Validation
    -------------------------
    OPEN lcu_category_sets;
    FETCH lcu_category_sets INTO gn_inv_category_set_id,gn_odpb_category_set_id,gn_po_category_set_id,gn_atp_category_set_id;
    IF  gn_inv_category_set_id IS NULL THEN
        display_log('Inventory Category Set not defined in the System');
        bulk_log_error( p_error_msg          =>  'Inventory Category Set is not defined in the System'
                       ,p_error_code         =>  NULL        
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    IF  gn_odpb_category_set_id IS NULL THEN
        display_log('Office Depot Private Brand Category Set not defined in the System');
        bulk_log_error( p_error_msg          =>  'Office Depot Private Brand Category Set is not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    IF  gn_po_category_set_id IS NULL THEN
        display_log('PO CATEGORY Category Set not defined in the System');
        bulk_log_error( p_error_msg          =>  'PO CATEGORY Category Set is not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    IF  gn_atp_category_set_id IS NULL THEN
        display_log('ATP_CATEGORY Category Set not defined in the System');
        bulk_log_error( p_error_msg          =>  'ATP_CATEGORY Category Set is not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;    
    CLOSE lcu_category_sets;     
    ---------------------------
    --Structure Code Validation
    ---------------------------    
    OPEN lcu_structure_id;
    FETCH lcu_structure_id INTO gn_inv_structure_id,gn_odpb_structure_id,gn_po_structure_id,gn_atp_structure_id;
    IF  gn_inv_structure_id IS NULL THEN
        display_log('Structure Code ITEM_CATEGORIES not defined in the System');
        bulk_log_error( p_error_msg          =>  'Structure Code ITEM_CATEGORIES not defined in the System'
                       ,p_error_code         =>  NULL        
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    IF  gn_odpb_structure_id IS NULL THEN
        display_log('Structure Code OD_ITM_BRAND_CATEGORY not defined in the System');
        bulk_log_error( p_error_msg          =>  'Structure Code OD_ITM_BRAND_CATEGORY not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    IF  gn_po_structure_id IS NULL THEN
        display_log('Structure Code PO_ITEM_CATEGORY not defined in the System');
        bulk_log_error( p_error_msg          =>  'Structure Code PO_ITEM_CATEGORY not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;
    IF  gn_atp_structure_id IS NULL THEN
        display_log('Structure Code OD_ATP_PLANNING_CATEGORY not defined in the System');
        bulk_log_error( p_error_msg          =>  'Structure Code OD_ATP_PLANNING_CATEGORY not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      );
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END IF;    
    CLOSE lcu_structure_id; 
    -------------------------------------
    --Validation Organizations Validation  
    -------------------------------------
    OPEN lcu_val_orgs;
    FETCH lcu_val_orgs BULK COLLECT INTO gt_val_orgs;
    IF  gt_val_orgs.COUNT=0 THEN
        gc_valorg_setup_status:='N';
        display_log('Validation Organizations are not defined in the System');
        bulk_log_error( p_error_msg          =>  'Validation Organizations are not defined in the System'
                       ,p_error_code         =>  NULL
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'validate_setups'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    ELSE
        gc_valorg_setup_status:='Y';
    END IF;
    CLOSE lcu_val_orgs;   
EXCEPTION
WHEN OTHERS THEN
    display_log('Unexpected error in validate_setups - '||gc_sqlerrm);
    gc_sqlerrm := SQLERRM; 
    gc_sqlcode := SQLCODE; 
    bulk_log_error( p_error_msg          =>  gc_sqlerrm
                   ,p_error_code         =>  gc_sqlcode  
                   ,p_control_id         =>  NULL
                   ,p_request_id         =>  fnd_global.conc_request_id
                   ,p_converion_id       =>  gn_conversion_id   
                   ,p_package_name       =>  G_PACKAGE_NAME
                   ,p_procedure_name     =>  'validate_setups'
                   ,p_staging_table_name =>  NULL
                   ,p_batch_id           =>  p_batch_id
                 );
    XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
END validate_setups;

-- +===================================================================+
-- | Name        :  validate_item_data                                 |
-- | Description :  This procedure is invoked from the OD: INV Items   |
-- |                Conversion Child  Concurrent Request.This would    |
-- |                submit conversion programs based on input          |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE validate_item_data(
                             x_errbuf      OUT NOCOPY VARCHAR2 
                            ,x_retcode     OUT NOCOPY VARCHAR2 
                            ,p_batch_id    IN  NUMBER
                            )
IS

------------------------------------------  
--Declaring Exceptions and local variables
------------------------------------------
EX_MASTER_NO_DATA           EXCEPTION;
EX_LOCATION_NO_DATA         EXCEPTION;
EX_ENTRY_EXCEP              EXCEPTION;

ln_batch_size               PLS_INTEGER;
ln_max_child_req            PLS_INTEGER;
lc_return_status            VARCHAR2(1);
lc_location_type            hr_organization_units.type%TYPE;
ln_inv_category_id          mtl_category_sets.category_set_id%TYPE;
ln_odbrand_category_id      mtl_category_sets.category_set_id%TYPE;
ln_po_category_id           mtl_category_sets.category_set_id%TYPE;
ln_atp_category_id          mtl_category_sets.category_set_id%TYPE;
ln_organization_id          mtl_parameters.organization_id%TYPE;

---------------------------------------
--Cursor to get the Master Item Details
---------------------------------------
CURSOR lcu_item_and_category(p_batch_id IN NUMBER)
IS
SELECT XSIM.ROWID
      ,XSIM.control_id
      ,XSIM.dept
      ,XSIM.class
      ,XSIM.subclass
      ,XSIM.od_private_brand_label
      ,XSIM.od_private_brand_flg
      ,XSIM.od_prod_protect_cd
      ,XSIM.od_ovrsize_delvry_flg
      ,XSIM.item_number_type
      ,XSIM.od_sku_type_cd
FROM   xx_item_master_stg XSIM
WHERE  XSIM.load_batch_id = p_batch_id
AND    (XSIM.item_process_flag IN (1,2,3) 
        OR XSIM.inv_category_process_flag  IN (1,2,3) 
        OR XSIM.odpb_category_process_flag IN (1,2,3)
        OR XSIM.po_category_process_flag   IN (1,2,3)
        OR XSIM.atp_category_process_flag  IN (1,2,3)
       )
ORDER BY XSIM.control_id;

---------------------------------------------
--Cursor to get the Organization Item Details
---------------------------------------------
CURSOR lcu_location(p_batch_id IN NUMBER)
IS
SELECT XSIL.ROWID
      ,XSIL.control_id
      ,XSIL.loc
FROM   xx_item_loc_stg XSIL
WHERE  XSIL.load_batch_id = p_batch_id
AND    XSIL.location_process_flag IN (1,2,3)
ORDER BY XSIL.control_id;

----------------------------------------------------------------
--Cursor to get the Category Id for the Inventory Structure Code 
----------------------------------------------------------------
CURSOR lcu_inv_category(p_invstructure_id IN NUMBER,p_item_dept IN VARCHAR2,p_item_class IN VARCHAR2,p_item_subclass IN VARCHAR2)
IS
SELECT MC.category_id
FROM   mtl_categories_b MC 
WHERE  MC.structure_id  =  p_invstructure_id
AND    MC.segment1 IN (SELECT FFV.attribute1
                       FROM   fnd_flex_values FFV
                             ,fnd_flex_value_sets FFVS
                       WHERE  FFVS.flex_value_set_id      =  FFV.flex_value_set_id    
                       AND    FFVS.flex_value_set_name    = 'XX_GI_GROUP_VS'                         
                       AND    FFV.flex_value              =  MC.segment2
                      )                                 
AND   MC.segment2 IN (SELECT FFV.attribute1
                      FROM fnd_flex_values FFV
                          ,fnd_flex_value_sets FFVS
                      WHERE FFVS.flex_value_set_id        =  FFV.flex_value_set_id
                      AND   FFVS.flex_value_set_name      =  'XX_GI_DEPARTMENT_VS'
                      AND   FFV.flex_value                =  MC.segment3
                     )                 
AND   MC.segment3 = p_item_dept
AND   MC.segment4 = p_item_class
AND   MC.segment5 = p_item_subclass
--Added by Arun Andavar in ver 1.0 -START
AND   MC.enabled_flag = 'Y'
AND   (      SYSDATE BETWEEN NVL(MC.start_date_active,SYSDATE - 1)
       AND   NVL(MC.end_date_active,SYSDATE + 1) 
      )
AND   (      SYSDATE <= NVL(MC.disable_date, SYSDATE + 1)
      )
--Added by Arun Andavar in ver 1.0 -END
;

-----------------------------------------------------------
--Cursor to get the Category Id for the ODPB Structure Code 
-----------------------------------------------------------
CURSOR lcu_odpb_category (p_odpbstructure_id IN NUMBER,p_private_brand_label IN VARCHAR2) 
IS
SELECT MC.category_id
FROM   mtl_categories_b MC 
WHERE  MC.structure_id  =  p_odpbstructure_id
AND    MC.segment1      =  p_private_brand_label
--Added by Arun Andavar in ver 1.0 -START
AND   MC.enabled_flag = 'Y'
AND   (      SYSDATE BETWEEN NVL(MC.start_date_active,SYSDATE - 1)
       AND   NVL(MC.end_date_active,SYSDATE + 1) 
      )
AND   (      SYSDATE <= NVL(MC.disable_date, SYSDATE + 1)
      )
--Added by Arun Andavar in ver 1.0 -END
;

------------------------------------------------------------------
--Cursor to get the Category Id for the PO CATEGORY Structure Code 
------------------------------------------------------------------
CURSOR lcu_po_category(p_postructure_id IN NUMBER,p_item_dept IN VARCHAR2,p_item_class IN VARCHAR2,p_item_subclass IN VARCHAR2)
IS
SELECT MC.category_id
FROM   mtl_categories_b MC 
WHERE  MC.structure_id  =  p_postructure_id
AND    MC.segment1      =  'NA'
AND    MC.segment2      =  'TRADE'
AND    MC.segment3      =  p_item_dept
AND    MC.segment4      =  p_item_class
AND    MC.segment5      =  p_item_subclass
--Added by Arun Andavar in ver 1.0 -START
AND   MC.enabled_flag = 'Y'
AND   (      SYSDATE BETWEEN NVL(MC.start_date_active,SYSDATE - 1)
       AND   NVL(MC.end_date_active,SYSDATE + 1) 
      )
AND   (      SYSDATE <= NVL(MC.disable_date, SYSDATE + 1)
      )
--Added by Arun Andavar in ver 1.0 -END
;

-------------------------------------------------------------------
--Cursor to get the Category Id for the ATP CATEGORY Structure Code 
-------------------------------------------------------------------
CURSOR lcu_atp_category(p_atpstructure_id IN NUMBER,p_ovrsize_delvry_flag  IN VARCHAR2)
IS
SELECT MC.category_id
FROM   mtl_categories_b MC 
WHERE  MC.structure_id  =  p_atpstructure_id
AND    MC.segment1      =  p_ovrsize_delvry_flag
--Added by Arun Andavar in ver 1.0 -START
AND   MC.enabled_flag = 'Y'
AND   (      SYSDATE BETWEEN NVL(MC.start_date_active,SYSDATE - 1)
       AND   NVL(MC.end_date_active,SYSDATE + 1) 
      )
AND   (      SYSDATE <= NVL(MC.disable_date, SYSDATE + 1)
      )
--Added by Arun Andavar in ver 1.0 -END
;

---------------------------------------
--Cursor to determine the Location Type 
---------------------------------------
CURSOR lcu_location_type (p_location VARCHAR2)
IS
SELECT HOU.organization_id
      ,HOU.type
FROM   hr_organization_units HOU
WHERE  HOU.attribute1   =  p_location
AND    SYSDATE BETWEEN NVL(HOU.date_from,SYSDATE) AND 
       NVL(HOU.date_to,SYSDATE+1);
       
--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE itemmaster_tbl_type IS TABLE OF lcu_item_and_category%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_itemmaster itemmaster_tbl_type;

TYPE mst_rowid_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_master_row_id mst_rowid_tbl_type;

TYPE loc_rowid_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_location_row_id loc_rowid_tbl_type;

TYPE master_control_id_tbl_type IS TABLE OF xx_item_master_stg.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_master_control_id master_control_id_tbl_type;

TYPE inv_category_pf_tbl_type IS TABLE OF xx_item_master_stg.inv_category_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_inv_categorypf inv_category_pf_tbl_type;

TYPE inv_categoryid_pf_tbl_type IS TABLE OF xx_item_master_stg.inv_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_inv_categoryid inv_categoryid_pf_tbl_type;

TYPE odpb_category_pf_tbl_type IS TABLE OF xx_item_master_stg.odpb_category_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_odpb_categorypf odpb_category_pf_tbl_type;

TYPE odpb_categoryid_pf_tbl_type IS TABLE OF xx_item_master_stg.odpb_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_odpb_categoryid odpb_categoryid_pf_tbl_type;

TYPE po_category_pf_tbl_type IS TABLE OF xx_item_master_stg.po_category_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_po_categorypf po_category_pf_tbl_type;

TYPE po_categoryid_tbl_type IS TABLE OF xx_item_master_stg.po_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_po_categoryid po_categoryid_tbl_type;

TYPE atp_category_pf_tbl_type IS TABLE OF xx_item_master_stg.atp_category_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_atp_categorypf atp_category_pf_tbl_type;

TYPE atp_categoryid_tbl_type IS TABLE OF xx_item_master_stg.atp_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_atp_categoryid atp_categoryid_tbl_type;

TYPE shippable_tbl_type IS TABLE OF xx_item_master_stg.shippable_item_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_shippable_item_flag shippable_tbl_type;

TYPE od_sku_type_cd_tbl_type IS TABLE OF xx_item_master_stg.od_sku_type_cd%TYPE
INDEX BY BINARY_INTEGER;
lt_od_sku_type_cd od_sku_type_cd_tbl_type;

TYPE itemloc_tbl_type IS TABLE OF lcu_location%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_itemlocation itemloc_tbl_type;

TYPE location_control_id_tbl_type IS TABLE OF xx_item_loc_stg.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_location_control_id location_control_id_tbl_type;

TYPE location_pf_tbl_type IS TABLE OF xx_item_loc_stg.location_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_location_pf location_pf_tbl_type;

TYPE loc_organization_id_tbl_type IS TABLE OF xx_item_loc_stg.organization_id%TYPE
INDEX BY BINARY_INTEGER;
lt_org_id loc_organization_id_tbl_type;

TYPE loc_template_id_tbl_type IS TABLE OF xx_item_loc_stg.template_id%TYPE
INDEX BY BINARY_INTEGER;
lt_template_id loc_template_id_tbl_type;

BEGIN
    ---------------------------
    --Getting the Conversion Id
    ---------------------------
    get_conversion_id(
                       x_conversion_id  => gn_conversion_id
                      ,x_batch_size     => ln_batch_size
                      ,x_max_threads    => ln_max_child_req
                      ,x_return_status  => lc_return_status
                     );

    --Calling validate_setups to validate all the required setups.                    
    IF lc_return_status = 'S' THEN          
        validate_setups(p_batch_id                =>    p_batch_id
                       ); 
        -----------------------------------------
        --Feching and Validating Master Item Data
        --
        --LIMIT clause not used here because batch 
        --size will be used to limit the fetch 
        -----------------------------------------
        BEGIN

           OPEN  lcu_item_and_category(p_batch_id);
           FETCH lcu_item_and_category BULK COLLECT INTO lt_itemmaster;
           CLOSE lcu_item_and_category;

           IF lt_itemmaster.COUNT <> 0 THEN
              XX_COM_CONV_ELEMENTS_PKG.bulk_table_initialize;

              FOR i IN 1..lt_itemmaster.COUNT
              LOOP               
                  lt_master_row_id(i)         :=  lt_itemmaster(i).ROWID;
                  ln_inv_category_id          :=  NULL;
                  ln_odbrand_category_id      :=  NULL;
                  ln_po_category_id           :=  NULL;
                  ln_atp_category_id          :=  NULL;

                  --Validating Category Id for Inventory Category Set
                  IF gn_inv_structure_id IS NOT NULL THEN
                      OPEN lcu_inv_category(gn_inv_structure_id,lt_itemmaster(i).dept,lt_itemmaster(i).class,lt_itemmaster(i).subclass);
                      FETCH lcu_inv_category INTO ln_inv_category_id;
                          IF  lcu_inv_category%NOTFOUND THEN
                              lt_inv_categorypf(i):= 3;
                              lt_inv_categoryid(i):= 0;
                              --Adding error message to stack
                              bulk_log_error( p_error_msg          =>  'Category Id for the Inventory Category Set cannot be found for the segments'
                                             ,p_error_code         =>  NULL
                                             ,p_control_id         =>  lt_itemmaster(i).control_id
                                             ,p_request_id         =>  fnd_global.conc_request_id
                                             ,p_converion_id       =>  gn_conversion_id   
                                             ,p_package_name       =>  G_PACKAGE_NAME
                                             ,p_procedure_name     =>  'validate_item_data'
                                             ,p_staging_table_name =>  'XX_ITEM_MASTER_STG'
                                             ,p_batch_id           =>  p_batch_id
                                            ); 
                          ELSE
                              lt_inv_categoryid(i):= ln_inv_category_id;
                              lt_inv_categorypf(i):= 4;
                          END IF;
                      CLOSE lcu_inv_category;
                  END IF;--gn_inv_structure_id IS NOT NULL
                  
                  --Validating Category Id for Office Depot Private Brand Category Set
                  IF gn_odpb_structure_id IS NOT NULL THEN                    
                      IF lt_itemmaster(i).od_private_brand_flg = 'Y' THEN
                          IF lt_itemmaster(i).od_private_brand_label IS NULL THEN
                              bulk_log_error( p_error_msg          =>  'OD_PRIVATE_BRAND_LABEL is mandatory when OD_PRIVATE_BRAND_FLAG is Y'
                                             ,p_error_code         =>  NULL
                                             ,p_control_id         =>  lt_itemmaster(i).control_id
                                             ,p_request_id         =>  fnd_global.conc_request_id
                                             ,p_converion_id       =>  gn_conversion_id   
                                             ,p_package_name       =>  G_PACKAGE_NAME
                                             ,p_procedure_name     =>  'validate_item_data'
                                             ,p_staging_table_name =>  'XX_ITEM_MASTER_STG'
                                             ,p_batch_id           =>  p_batch_id
                                           ); 
                          ELSE 
                              OPEN lcu_odpb_category(gn_odpb_structure_id,lt_itemmaster(i).od_private_brand_label);
                              FETCH lcu_odpb_category INTO ln_odbrand_category_id;   
                                  IF  lcu_odpb_category%NOTFOUND THEN
                                      lt_odpb_categorypf(i):= 3;
                                      lt_odpb_categoryid(i):= 0;
                                      --Adding error message to stack
                                      bulk_log_error( p_error_msg          =>  'Category Id for the Office Depot Private Brand Category Set cannot be found for the segments'
                                                     ,p_error_code         =>  NULL
                                                     ,p_control_id         =>  lt_itemmaster(i).control_id
                                                     ,p_request_id         =>  fnd_global.conc_request_id
                                                     ,p_converion_id       =>  gn_conversion_id   
                                                     ,p_package_name       =>  G_PACKAGE_NAME
                                                     ,p_procedure_name     =>  'validate_item_data'
                                                     ,p_staging_table_name =>  'XX_ITEM_MASTER_STG'
                                                     ,p_batch_id           =>  p_batch_id
                                                    ); 
                                  ELSE
                                      lt_odpb_categoryid(i):= ln_odbrand_category_id;
                                      lt_odpb_categorypf(i):= 4;            
                                  END IF;
                              CLOSE lcu_odpb_category;
                          END IF; -- lt_itemmaster(i).od_private_brand_flg='Y'
                      ELSE
                          lt_odpb_categoryid(i):= 0;
                          lt_odpb_categorypf(i):= 7;
                      END IF; --lt_itemmaster(i).od_private_brand_label IS NULL 
                  END IF;--gn_odpb_structure_id IS NOT NULL
                  
                  --Validating Category Id for PO Category Category Set
                  IF gn_po_structure_id IS NOT NULL THEN 
                      OPEN lcu_po_category(gn_po_structure_id,lt_itemmaster(i).dept,lt_itemmaster(i).class,lt_itemmaster(i).subclass);
                      FETCH lcu_po_category INTO ln_po_category_id;
                          IF  lcu_po_category%NOTFOUND THEN
                              lt_po_categorypf(i)     :=  3;
                              lt_po_categoryid(i)     :=  0;
                              --Adding error message to stack
                              bulk_log_error( p_error_msg          =>  'Category Id for the PO CATEGORY Category Set cannot be found for the segments'
                                             ,p_error_code         =>  NULL
                                             ,p_control_id         =>  lt_itemmaster(i).control_id
                                             ,p_request_id         =>  fnd_global.conc_request_id
                                             ,p_converion_id       =>  gn_conversion_id   
                                             ,p_package_name       =>  G_PACKAGE_NAME
                                             ,p_procedure_name     =>  'validate_item_data'
                                             ,p_staging_table_name =>  'XX_ITEM_MASTER_STG'
                                             ,p_batch_id           =>  p_batch_id
                                            ); 
                          ELSE
                              lt_po_categoryid(i):= ln_po_category_id;
                              lt_po_categorypf(i):= 4;
                          END IF;
                      CLOSE lcu_po_category;
                  END IF;--gn_po_structure_id IS NOT NULL 
                  
                  --Validating Category Id for ATP_CATEGORY Category Set    
                  IF gn_atp_structure_id IS NOT NULL THEN
                      IF lt_itemmaster(i).od_ovrsize_delvry_flg IS NOT NULL THEN
                          OPEN lcu_atp_category(gn_atp_structure_id,lt_itemmaster(i).od_ovrsize_delvry_flg);
                          FETCH lcu_atp_category INTO ln_atp_category_id;
                              IF  lcu_atp_category%NOTFOUND THEN
                                  lt_atp_categorypf(i)     :=  3;
                                  lt_atp_categoryid(i)     :=  0;
                                  --Adding error message to stack
                                  bulk_log_error( p_error_msg          =>  'Category Id for the ATP CATEGORY Category Set cannot be found for the segments'
                                                 ,p_error_code         =>  NULL
                                                 ,p_control_id         =>  lt_itemmaster(i).control_id
                                                 ,p_request_id         =>  fnd_global.conc_request_id
                                                 ,p_converion_id       =>  gn_conversion_id   
                                                 ,p_package_name       =>  G_PACKAGE_NAME
                                                 ,p_procedure_name     =>  'validate_item_data'
                                                 ,p_staging_table_name =>  'XX_ITEM_MASTER_STG'
                                                 ,p_batch_id           =>  p_batch_id
                                                ); 
                              ELSE
                                  lt_atp_categoryid(i):= ln_atp_category_id;
                                  lt_atp_categorypf(i):= 4;
                              END IF;
                          CLOSE lcu_atp_category;        
                      ELSE
                          lt_atp_categoryid(i):= 0;
                          lt_atp_categorypf(i):= 7;                       
                      END IF;
                  END IF;--gn_atp_structure_id IS NOT NULL

                  --Assigning 'Non-Code Item' Item type if item_number_type is ITEM7                             
                  IF lt_itemmaster(i).item_number_type  =  'ITEM7' THEN
                     lt_od_sku_type_cd(i)   :=  '08';
                  ELSE
                     lt_od_sku_type_cd(i)   :=   lt_itemmaster(i).od_sku_type_cd;
                  END IF;
                  
                  --Disabling the Shippable item flag for Warranty Item
                  IF  lt_itemmaster(i).od_prod_protect_cd='P' THEN
                      lt_shippable_item_flag(i):= 'N';
                  ELSE
                      lt_shippable_item_flag(i):= 'Y';
                  END IF;  
                                                  
              END LOOP; --End of Master Items Loop
                              

              -------------------------------------------------------------------------
              --Invoke Common Conversion API to Bulk Insert the Master Item Data Errors
              -------------------------------------------------------------------------
              XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
              
              ------------------------------------------------------------
              -- Bulk Update xx_item_master_stg with Process flags and Ids
              ------------------------------------------------------------
              FORALL i IN 1 .. lt_itemmaster.LAST 
              UPDATE xx_item_master_stg XSIM
              SET    XSIM.inv_category_process_flag  =  lt_inv_categorypf(i)
                    ,XSIM.odpb_category_process_flag =  lt_odpb_categorypf(i)
                    ,XSIM.po_category_process_flag   =  lt_po_categorypf(i)
                    ,XSIM.atp_category_process_flag  =  lt_atp_categorypf(i)
                    --Modified by Arun Andavar in version 1.0 --START
                    ,XSIM.item_process_flag          =  (CASE WHEN XSIM.item_process_flag < 4 THEN 4 ELSE XSIM.item_process_flag END)
                    --Modified by Arun Andavar in version 1.0 --END
                    ,XSIM.load_batch_id              =  p_batch_id
                    ,XSIM.inv_category_id            =  lt_inv_categoryid(i)
                    ,XSIM.odpb_category_id           =  lt_odpb_categoryid(i)
                    ,XSIM.po_category_id             =  lt_po_categoryid(i)
                    ,XSIM.atp_category_id            =  lt_atp_categoryid(i)
                    ,XSIM.od_sku_type_cd             =  lt_od_sku_type_cd(i)
                    ,XSIM.organization_id            =  gn_master_org_id
                    ,XSIM.template_id                =  gn_mer_template_id
                    ,XSIM.shippable_item_flag        =  lt_shippable_item_flag(i)
              WHERE  XSIM.ROWID                      =  lt_master_row_id(i);  
              COMMIT;
           ELSE
               RAISE EX_MASTER_NO_DATA;
           END IF; --lt_itemmaster.count <> 0
        EXCEPTION
           WHEN EX_MASTER_NO_DATA THEN
              x_retcode := 1;
              x_errbuf  := 'No data found in the staging table xx_item_master_stg with batch_id - '||p_batch_id;
              bulk_log_error( p_error_msg          =>  'No data found in the staging table xx_item_master_stg with batch_id '
                             ,p_error_code         =>  NULL
                             ,p_control_id         =>  NULL
                             ,p_request_id         =>  fnd_global.conc_request_id
                             ,p_converion_id       =>  gn_conversion_id   
                             ,p_package_name       =>  G_PACKAGE_NAME
                             ,p_procedure_name     =>  'validate_item_data'
                             ,p_staging_table_name =>  'XX_ITEM_MASTER_STG'
                             ,p_batch_id           =>  p_batch_id
                            );
              XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
        END;

        --------------------------------------
        --Feching and Validating Location Data
        --------------------------------------
        OPEN lcu_location(p_batch_id);
        LOOP
           FETCH lcu_location BULK COLLECT INTO lt_itemlocation LIMIT G_LIMIT_SIZE;
           IF lt_itemlocation.COUNT <> 0 THEN
               XX_COM_CONV_ELEMENTS_PKG.bulk_table_initialize;
               FOR i IN 1 .. lt_itemlocation.COUNT
               LOOP
                   lt_location_row_id(i)       :=   lt_itemlocation(i).ROWID;
                   ln_organization_id          :=   NULL;
                   lc_location_type            :=   NULL;
                   
                   OPEN lcu_location_type(lt_itemlocation(i).loc);
                   LOOP                    
                       FETCH lcu_location_type INTO ln_organization_id,lc_location_type;
                       IF  ln_organization_id IS NULL AND lc_location_type IS NULL THEN
                           lt_location_pf(i)   :=  3;
                           lt_org_id(i)        :=  0;
                           lt_template_id(i)   :=  0;
                           --Adding error message to stack
                           bulk_log_error( p_error_msg         =>  'Organization not defined'
                                          ,p_error_code        =>  NULL
                                          ,p_control_id        =>  lt_itemlocation(i).control_id
                                          ,p_request_id        =>  fnd_global.conc_request_id
                                          ,p_converion_id      =>  gn_conversion_id   
                                          ,p_package_name      =>  G_PACKAGE_NAME
                                          ,p_procedure_name    =>  'validate_item_data'
                                          ,p_staging_table_name=>  'XX_ITEM_LOC_STG'
                                          ,p_batch_id          =>  p_batch_id
                                         ); 
                       ELSE
                           lt_location_pf(i):= 4;
                           lt_org_id(i)     := ln_organization_id;

                           --Assigning Drop Ship Item template for Drop Ship Locations and Merchendising Item Template for Other Locations
                           IF  lc_location_type='DS' THEN
                               lt_template_id(i):=gn_ds_template_id;
                           ELSE
                               lt_template_id(i):=gn_mer_template_id;
                           END IF;

                       END IF;  --lcu_location_type%NOTFOUND
                       EXIT WHEN lcu_location_type%NOTFOUND;
                   END LOOP;--End of lcu_location_type
                   CLOSE lcu_location_type;
               END LOOP;--End of lt_itemlocation.COUNT loop
                                               
               ---------------------------------------------------------------------------
               --Invoke Common Conversion API to Bulk Insert the Location Item Data Errors
               ---------------------------------------------------------------------------
               XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
               --------------------------------------------------------
               -- Bulk Update xx_item_loc_stg with Process flag and Ids
               --------------------------------------------------------
               FORALL i IN 1..lt_itemlocation.LAST    
                   UPDATE xx_item_loc_stg XSIL
                   SET    XSIL.location_process_flag   =   lt_location_pf(i)
                         ,XSIL.load_batch_id           =   p_batch_id
                         ,XSIL.template_id             =   lt_template_id(i)
                         ,XSIL.organization_id         =   lt_org_id(i)
                   WHERE  XSIL.ROWID                   =   lt_location_row_id(i);
               COMMIT;
           END IF;--lt_itemlocation.count =<> 0
           EXIT WHEN lcu_location%NOTFOUND;

        END LOOP;--End of lcu_location
        CLOSE lcu_location; 
     ELSE
        RAISE EX_ENTRY_EXCEP;
     END IF;-- If lc_return_status ='S' 
EXCEPTION
WHEN EX_MASTER_NO_DATA THEN
    x_retcode := 1;
    x_errbuf  := 'No data found in the staging table xx_item_master_stg with batch_id - '||p_batch_id;
    bulk_log_error( p_error_msg          =>  'No data found in the staging table xx_item_master_stg with batch_id '
                   ,p_error_code         =>  NULL
                   ,p_control_id         =>  NULL
                   ,p_request_id         =>  fnd_global.conc_request_id
                   ,p_converion_id       =>  gn_conversion_id   
                   ,p_package_name       =>  G_PACKAGE_NAME
                   ,p_procedure_name     =>  'validate_item_data'
                   ,p_staging_table_name =>  'XX_ITEM_MASTER_STG'
                   ,p_batch_id           =>  p_batch_id
                 );
    XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;                 
WHEN EX_LOCATION_NO_DATA THEN
    x_retcode := 1;
    x_errbuf  := 'No data found in the staging table xx_item_loc_stg with batch_id - '||p_batch_id;
    bulk_log_error( p_error_msg          =>  'No data found in the staging table xx_item_loc_stg with batch_id '
                   ,p_error_code         =>  NULL
                   ,p_control_id         =>  NULL
                   ,p_request_id         =>  fnd_global.conc_request_id
                   ,p_converion_id       =>  gn_conversion_id   
                   ,p_package_name       =>  G_PACKAGE_NAME
                   ,p_procedure_name     =>  'validate_item_data'
                   ,p_staging_table_name =>  'XX_ITEM_LOC_STG'
                   ,p_batch_id           =>  p_batch_id
                 );
    XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;                   
WHEN EX_ENTRY_EXCEP THEN
    gc_sqlerrm:= 'There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE;
    gc_sqlcode:= SQLCODE;
    x_errbuf  := 'There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||G_CONVERSION_CODE;
    x_retcode := 2;
    bulk_log_error( p_error_msg          =>  gc_sqlerrm
                   ,p_error_code         =>  gc_sqlcode
                   ,p_control_id         =>  NULL
                   ,p_request_id         =>  fnd_global.conc_request_id
                   ,p_converion_id       =>  gn_conversion_id   
                   ,p_package_name       =>  G_PACKAGE_NAME
                   ,p_procedure_name     =>  'validate_item_data'
                   ,p_staging_table_name =>  NULL
                   ,p_batch_id           =>  p_batch_id
                );
    XX_COM_CONV_ELEMENTS_PKG.bulk_log_message; 
WHEN OTHERS THEN
    IF lcu_location%ISOPEN THEN
        CLOSE lcu_location;
    END IF;
    gc_sqlerrm := SQLERRM; 
    gc_sqlcode := SQLCODE; 
    x_errbuf  := 'Unexpected error in validate_item_data - '||gc_sqlerrm;
    x_retcode := 2;
    bulk_log_error( p_error_msg          =>  gc_sqlerrm
                   ,p_error_code         =>  gc_sqlcode    
                   ,p_control_id         =>  NULL
                   ,p_request_id         =>  fnd_global.conc_request_id
                   ,p_converion_id       =>  gn_conversion_id   
                   ,p_package_name       =>  G_PACKAGE_NAME
                   ,p_procedure_name     =>  'validate_item_data'
                   ,p_staging_table_name =>  NULL
                   ,p_batch_id           =>  p_batch_id
                );
    XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;                  
END validate_item_data;

-- +===================================================================+
-- | Name        :  insert_item_attributes                             |
-- | Description :  This procedure is invoked from the OD: INV Items   |
-- |                Conversion Child  Concurrent Request.This would    |
-- |                submit conversion programs based on input          |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE insert_item_attributes(x_errbuf    OUT NOCOPY VARCHAR2
                                ,x_retcode   OUT NOCOPY VARCHAR2
                                ,p_batch_id  IN  NUMBER)
IS

BEGIN
    -------------------------------
    --Bulk Insert Master Attributes
    -------------------------------
    BEGIN
    INSERT INTO XX_INV_ITEM_MASTER_ATTRIBUTES
                                              ( inventory_item_id
                                               ,organization_id      
                                               ,order_as_type
                                               ,pack_ind
                                               ,pack_type
                                               ,package_size
                                               ,ship_alone_ind
                                               ,handling_sensitivity 
                                               ,od_meta_cd
                                               ,od_ovrsize_delvry_flg        
                                               ,od_prod_protect_cd
                                               ,od_gift_certif_flg
                                               ,od_imprinted_item_flg        
                                               ,od_recycle_flg
                                               ,od_ready_to_assemble_flg
                                               ,od_private_brand_flg       
                                               ,od_gsa_flg
                                               ,od_hub_flag
                                               ,od_call_for_price_cd 
                                               ,od_cost_up_flg
                                               ,master_item 
                                               ,subsell_master_qty
                                               ,simple_pack_ind
                                               ,od_sell_restrict_cd          
                                               ,od_list_off_flg
                                               ,od_assortment_cd
                                               ,od_off_cat_flg
                                               ,od_retail_pricing_flg
                                               ,od_coupon_disc_flg
                                               ,od_sku_type_cd
                                               ,item_number_type
                                               ,short_desc
                                               ,source_system_code
                                               ,source_system_ref
                                               ,store_ord_mult                                                          
                                               ,last_update_date  
                                               ,last_update_login 
                                               ,last_updated_by   
                                               ,creation_date     
                                               ,created_by
                                              )
                                        SELECT   XSIM.inventory_item_id
                                                ,XSIM.organization_id
                                                ,XSIM.order_as_type
                                                ,XSIM.pack_ind
                                                ,XSIM.pack_type
                                                ,XSIM.package_size
                                                ,XSIM.ship_alone_ind
                                                ,XSIM.handling_sensitivity 
                                                ,XSIM.od_meta_cd
                                                ,XSIM.od_ovrsize_delvry_flg        
                                                ,XSIM.od_prod_protect_cd
                                                ,XSIM.od_gift_certif_flg
                                                ,XSIM.od_imprinted_item_flg        
                                                ,XSIM.od_recycle_flg
                                                ,XSIM.od_ready_to_assemble_flg
                                                ,XSIM.od_private_brand_flg       
                                                ,XSIM.od_gsa_flg
                                                ,XSIM.od_hub_flag
                                                ,XSIM.od_call_for_price_cd 
                                                ,XSIM.od_cost_up_flg
                                                ,XSIM.item 
                                                ,XSIM.subsell_master_qty
                                                ,XSIM.simple_pack_ind
                                                ,XSIM.od_sell_restrict_cd
                                                ,XSIM.od_list_off_flg
                                                ,XSIM.od_assortment_cd
                                                ,XSIM.od_off_cat_flg
                                                ,XSIM.od_retail_pricing_flg
                                                ,XSIM.od_coupon_disc_flg
                                                ,XSIM.od_sku_type_cd
                                                ,XSIM.item_number_type
                                                ,XSIM.short_desc
                                                ,XSIM.source_system_code
                                                ,XSIM.source_system_ref
                                                ,XSIM.store_ord_mult
                                                ,SYSDATE
                                                ,g_user_id
                                                ,g_user_id
                                                ,SYSDATE
                                                ,g_user_id
                                        FROM     xx_item_master_stg XSIM
                                        WHERE    XSIM.item_process_flag=7
                                        AND      XSIM.load_batch_id=p_batch_id;
    COMMIT;
    
    EXCEPTION
        -------------------------------------------------------------------
        --Invoke Common Conversion API to Bulk Insert the Unexpected Errors
        -------------------------------------------------------------------
        WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM; 
        gc_sqlcode := SQLCODE; 
        x_errbuf  := 'Unexpected error in insert_item_attributes - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg             =>  gc_sqlerrm
                       ,p_error_code            =>  gc_sqlcode
                       ,p_control_id            =>  NULL
                       ,p_request_id            =>  fnd_global.conc_request_id
                       ,p_converion_id          =>  gn_conversion_id   
                       ,p_package_name          =>  G_PACKAGE_NAME
                       ,p_procedure_name        =>  'insert_item_attributes'
                       ,p_staging_table_name    =>  'XX_ITEM_MASTER_STG'
                       ,p_batch_id              =>   p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END;--End of Bulk Insert Master Attributes

    ---------------------------------
    --Bulk Insert Location Attributes
    ---------------------------------
    BEGIN
    INSERT INTO XX_INV_ITEM_ORG_ATTRIBUTES
                                         ( inventory_item_id
                                          ,organization_id
                                          ,od_dist_target
                                          ,od_ebw_qty
                                          ,od_infinite_qty_cd
                                          ,od_lock_up_item_flg
                                          ,od_proprietary_type_cd
                                          ,od_replen_sub_type_cd
                                          ,od_replen_type_cd 
                                          ,od_whse_item_cd
                                          ,od_abc_class
                                          ,local_item_desc
                                          ,local_short_desc
                                          ,primary_supp
                                          ,od_channel_block
                                          ,source_system_code
                                          ,source_system_ref
                                          ,last_update_date  
                                          ,last_update_login 
                                          ,last_updated_by   
                                          ,creation_date     
                                          ,created_by
                                         )
                                   SELECT   XSIL.inventory_item_id
                                           ,XSIL.organization_id
                                           ,XSIL.od_dist_target
                                           ,XSIL.od_ebw_qty
                                           ,XSIL.od_infinite_qty_cd
                                           ,XSIL.od_lock_up_item_flg
                                           ,XSIL.od_proprietary_type_cd 
                                           ,XSIL.od_replen_sub_type_cd
                                           ,XSIL.od_replen_type_cd 
                                           ,XSIL.od_whse_item_cd
                                           ,XSIL.od_abc_class
                                           ,XSIL.local_item_desc
                                           ,XSIL.local_short_desc
                                           ,XSIL.primary_supp
                                           ,XSIL.od_channel_block
                                           ,XSIL.source_system_code
                                           ,XSIL.source_system_ref
                                           ,SYSDATE
                                           ,g_user_id
                                           ,g_user_id
                                           ,SYSDATE
                                           ,g_user_id
                                   FROM     xx_item_loc_stg XSIL
                                   WHERE    XSIL.location_process_flag=7
                                   AND      XSIL.load_batch_id=p_batch_id;
    COMMIT; 
    EXCEPTION
    -------------------------------------------------------------------
    --Invoke Common Conversion API to Bulk Insert the Unexpected Errors
    -------------------------------------------------------------------
    WHEN OTHERS THEN
        gc_sqlerrm := SQLERRM; 
        gc_sqlcode := SQLCODE; 
        x_errbuf  := 'Unexpected error in insert_item_attributes - '||gc_sqlerrm;
        x_retcode := 2;
        bulk_log_error( p_error_msg             =>  gc_sqlerrm
                       ,p_error_code            =>  gc_sqlcode     
                       ,p_control_id            =>  NULL
                       ,p_request_id            =>  fnd_global.conc_request_id
                       ,p_converion_id          =>  gn_conversion_id   
                       ,p_package_name          =>  G_PACKAGE_NAME
                       ,p_procedure_name        =>  'insert_item_attributes'
                       ,p_staging_table_name    =>  'XX_ITEM_LOC_STG'
                       ,p_batch_id              =>   p_batch_id
                     ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
    END;--End of Bulk Insert Location Attributes
EXCEPTION
WHEN OTHERS THEN
    gc_sqlerrm := SQLERRM; 
    gc_sqlcode := SQLCODE; 
    x_errbuf  := 'Unexpected error in insert_item_attributes - '||gc_sqlerrm;
    x_retcode := 2;
    bulk_log_error( p_error_msg          =>  gc_sqlerrm
                   ,p_error_code         =>  gc_sqlcode
                   ,p_control_id         =>  NULL
                   ,p_request_id         =>  fnd_global.conc_request_id
                   ,p_converion_id       =>  gn_conversion_id   
                   ,p_package_name       =>  G_PACKAGE_NAME
                   ,p_procedure_name     =>  'insert_item_attributes'
                   ,p_staging_table_name =>  NULL
                   ,p_batch_id           =>  p_batch_id
                 );
   XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;    
END insert_item_attributes;

-- +===================================================================+
-- | Name        :  process_item_data                                  |
-- | Description :  This procedure is invoked from the OD: INV Items   |
-- |                Conversion Child  Concurrent Request.This would    |
-- |                submit conversion programs based on input          |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- +===================================================================+
PROCEDURE process_item_data(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
                            ,p_batch_id    IN  NUMBER
                            ,p_delete_flag IN  VARCHAR2
                           )
IS
---------------------------
--Declaring Local Variables
---------------------------
lc_err_text          VARCHAR2(5000);
ln_return_code       PLS_INTEGER;
ln_del_rec_flag      PLS_INTEGER:=0;

-------------------------------------------------------------
--Cursor to fetch Inventory Item ids for success item records
-------------------------------------------------------------
CURSOR lcu_success_item_ids(p_batch_id IN NUMBER) 
IS 
SELECT MSIB.inventory_item_id
      ,XSIM.ROWID
FROM   xx_item_master_stg XSIM
      ,mtl_system_items_b  MSIB
WHERE  MSIB.segment1            =   XSIM.item
AND    MSIB.organization_id     =   XSIM.organization_id
AND    XSIM.item_process_flag   =   4
AND    XSIM.load_batch_id       =   p_batch_id;

-----------------------------------------------------------------
--Cursor to fetch Inventory Item ids for success location records
-----------------------------------------------------------------
CURSOR lcu_success_locations_itemids(p_batch_id IN NUMBER) 
IS
SELECT MSIB.inventory_item_id
      ,XSIL.ROWID
FROM   mtl_system_items_b MSIB
      ,xx_item_loc_stg XSIL
WHERE  MSIB.segment1                =   XSIL.item
AND    MSIB.organization_id         =   XSIL.organization_id
AND    XSIL.load_batch_id           =   p_batch_id
AND    XSIL.location_process_flag   =   4;

--------------------------------------------------
--Cursor to fetch Item and Category Error messages
--------------------------------------------------
CURSOR lcu_item_cat_error(p_batch_id IN NUMBER)
IS
SELECT 'MSII:'||MIE.error_message
      ,XSIM.control_id
      ,XSIM.ROWID
FROM   mtl_system_items_interface MSII
      ,mtl_interface_errors MIE
      ,xx_item_master_stg XSIM
WHERE  MSII.transaction_id    =   MIE.transaction_id
AND    MSII.set_process_id    =   p_batch_id
AND    XSIM.organization_id   =   MSII.organization_id
AND    XSIM.item              =   MSII.segment1
AND    XSIM.load_batch_id     =   p_batch_id
UNION ALL
SELECT 'MICI:'||MIE.error_message
      ,XSIM.control_id
      ,XSIM.ROWID
FROM   mtl_item_categories_interface MICI
      ,mtl_interface_errors MIE
      ,xx_item_master_stg XSIM
WHERE  MICI.transaction_id    =   MIE.transaction_id
AND    MICI.set_process_id    =   p_batch_id
AND    XSIM.item              =   MICI.item_number
AND    MICI.organization_id   =   XSIM.organization_id
AND    XSIM.load_batch_id     =   p_batch_id
UNION ALL
SELECT 'MIRI:'||MIE.error_message
      ,XSIM.control_id 
      ,XSIM.ROWID
FROM   mtl_interface_errors MIE
      ,xx_item_master_stg XSIM
      ,mtl_system_items_interface MSII 
      ,mtl_item_revisions_interface MIRI
WHERE  MIRI.set_process_id    =   p_batch_id
AND    MSII.set_process_id    =   MIRI.set_process_id
AND    MSII.organization_id   =   MIRI.organization_id
AND    MSII.inventory_item_id =   MIRI.inventory_item_id
AND    XSIM.load_batch_id     =   MSII.set_process_id
AND    XSIM.organization_id   =   MSII.organization_id
AND    XSIM.item              =   MSII.segment1
AND    MIE.transaction_id     =   MIRI.transaction_id;


-----------------------------------------
--Cursor to fetch Location Error messages
-----------------------------------------
CURSOR lcu_loc_error(p_batch_id IN NUMBER)
IS
SELECT 'MSII:'||MIE.error_message
      ,XSIL.control_id
      ,XSIL.ROWID
FROM   mtl_system_items_interface MSII
      ,mtl_interface_errors MIE
      ,xx_item_loc_stg XSIL
WHERE  MSII.transaction_id    =   MIE.transaction_id
AND    MSII.set_process_id    =   p_batch_id
AND    XSIL.organization_id   =   MSII.organization_id
AND    XSIL.item              =   MSII.segment1
AND    XSIL.load_batch_id     =   p_batch_id
UNION ALL
SELECT 'MICI:'||MIE.error_message
      ,XSIL.control_id
      ,XSIL.ROWID
FROM   mtl_item_categories_interface MICI
      ,mtl_interface_errors MIE
      ,xx_item_loc_stg XSIL
WHERE  MICI.transaction_id    =   MIE.transaction_id
AND    MICI.set_process_id    =   p_batch_id
AND    XSIL.item              =   MICI.item_number
AND    MICI.organization_id   =   XSIL.organization_id
AND    XSIL.load_batch_id     =   p_batch_id
UNION ALL
SELECT 'MIRI:'||MIE.error_message
      ,XSIL.control_id 
      ,XSIL.ROWID
FROM   mtl_interface_errors MIE
      ,xx_item_loc_stg XSIL
      ,mtl_system_items_interface MSII 
      ,mtl_item_revisions_interface MIRI
WHERE  MIRI.set_process_id    =   p_batch_id
AND    MSII.set_process_id    =   MIRI.set_process_id
AND    MSII.organization_id   =   MIRI.organization_id
AND    MSII.inventory_item_id =   MIRI.inventory_item_id
AND    XSIL.load_batch_id     =   MSII.set_process_id
AND    XSIL.organization_id   =   MSII.organization_id
AND    XSIL.item              =   MSII.segment1
AND    MIE.transaction_id     =   MIRI.transaction_id;

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE itemid_success_tbl_type IS TABLE OF mtl_system_items_b.inventory_item_id%TYPE
INDEX BY BINARY_INTEGER;
lt_itemid_success itemid_success_tbl_type;

TYPE rowid_item_success_tbl_type IS TABLE OF ROWID;
lt_rowid_success rowid_item_success_tbl_type;

TYPE rowid_item_failure_tbl_type IS TABLE OF ROWID;
lt_rowid_failure rowid_item_failure_tbl_type;

TYPE item_cat_error_type IS TABLE OF mtl_interface_errors.error_message%TYPE
INDEX BY BINARY_INTEGER;
lt_item_cat_error item_cat_error_type;

TYPE item_cat_errorid_type IS TABLE OF xx_item_master_stg.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_item_cat_errorid item_cat_errorid_type;

TYPE loc_itemid_success_tbl_type IS TABLE OF mtl_system_items_b.inventory_item_id%TYPE
INDEX BY BINARY_INTEGER;
lt_locationid_success loc_itemid_success_tbl_type;

TYPE loc_rowid_success_tbl_type IS TABLE OF ROWID;
lt_locationrowid_success loc_rowid_success_tbl_type;

TYPE loc_rowid_failure_tbl_type IS TABLE OF ROWID;
lt_locationrowid_failure loc_rowid_failure_tbl_type;

TYPE loc_error_type IS TABLE OF mtl_interface_errors.error_message%TYPE
INDEX BY BINARY_INTEGER;
lt_loc_error loc_error_type;

TYPE loc_errorid_type IS TABLE OF xx_item_loc_stg.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_loc_errorid loc_errorid_type;

BEGIN

---------------------------------------------------------------------------------
--Inserting Success items into MTL_SYSTEM_ITEMS_INTERFACE for Master Organization
---------------------------------------------------------------------------------
IF  gc_master_setup_status='Y' THEN
    INSERT 
    INTO   MTL_SYSTEM_ITEMS_INTERFACE
         (
          segment1
         ,description
         ,organization_id
         ,template_id
         ,inventory_item_status_code
         ,item_type
         ,process_flag
         ,purchasing_item_flag
         ,customer_order_flag
         ,shippable_item_flag
         ,primary_uom_code
         ,set_process_id
         ,transaction_type
         ,summary_flag
         ,attribute1
         ,last_update_date
         ,last_updated_by
         ,creation_date
         ,created_by
         ,last_update_login
         )
    SELECT XSIM.item
          ,XSIM.item_desc
          ,XSIM.organization_id
          ,XSIM.template_id
          ,XSIM.status
          ,XSIM.od_sku_type_cd
          ,G_PROCESS_FLAG
          ,XSIM.orderable_ind
          ,XSIM.sellable_ind
          ,XSIM.shippable_item_flag
          ,XSIM.package_uom 
          ,p_batch_id
          ,G_TRANSACTION_TYPE
          ,'Y'
          ,XSIM.od_tax_category
          ,G_DATE
          ,G_USER_ID
          ,G_DATE
          ,G_USER_ID
          ,G_USER_ID      
    FROM   xx_item_master_stg XSIM
    WHERE  XSIM.load_batch_id=p_batch_id
    AND    XSIM.item_process_flag IN (4,5,6);

    --------------------------------------------------------------------------------------
    --Inserting Success items into MTL_SYSTEM_ITEMS_INTERFACE for Validation Organizations
    --------------------------------------------------------------------------------------
    IF  gc_valorg_setup_status='Y' THEN
        FOR i IN 1..gt_val_orgs.LAST
        LOOP
            INSERT 
            INTO   MTL_SYSTEM_ITEMS_INTERFACE
                   (
                    segment1
                   ,description
                   ,organization_id
                   ,template_id
                   ,inventory_item_status_code
                   ,item_type
                   ,process_flag
                   ,purchasing_item_flag
                   ,customer_order_flag
                   ,primary_uom_code
                   ,set_process_id
                   ,transaction_type
                   ,summary_flag
                   ,attribute1
                   ,last_update_date
                   ,last_updated_by
                   ,creation_date
                   ,created_by
                   ,last_update_login
                   )
            SELECT  XSIM.item
                   ,XSIM.item_desc
                   ,gt_val_orgs(i)
                   ,XSIM.template_id
                   ,XSIM.status
                   ,XSIM.od_sku_type_cd
                   ,G_PROCESS_FLAG
                   ,XSIM.orderable_ind
                   ,XSIM.sellable_ind
                   ,XSIM.package_uom 
                   ,p_batch_id
                   ,G_TRANSACTION_TYPE
                   ,'Y'
                   ,XSIM.od_tax_category
                   ,G_DATE
                   ,G_USER_ID
                   ,G_DATE
                   ,G_USER_ID
                   ,G_USER_ID
            FROM    xx_item_master_stg XSIM
            WHERE   XSIM.load_batch_id=p_batch_id
            AND     XSIM.item_process_flag IN (4,5,6);
        END LOOP;-- End loop for p_val_orgs(i)
    END IF;
   ------------------------------------------------------------
   --Inserting Success items into MTL_ITEM_CATEGORIES_INTERFACE 
   ------------------------------------------------------------
    INSERT 
    INTO MTL_ITEM_CATEGORIES_INTERFACE
          (
           item_number
          ,organization_id
          ,category_set_id
          ,category_id
          ,transaction_type
          ,process_flag
          ,set_process_id
          ,last_update_date
          ,last_updated_by
          ,creation_date
          ,created_by
          ,last_update_login
         )
    SELECT XSIM.item
          ,XSIM.organization_id
          ,gn_inv_category_set_id
          ,XSIM.inv_category_id
          ,G_TRANSACTION_TYPE
          ,G_PROCESS_FLAG
          ,p_batch_id
          ,G_DATE
          ,G_USER_ID
          ,G_DATE
          ,G_USER_ID
          ,G_USER_ID
    FROM   xx_item_master_stg XSIM
    WHERE  XSIM.load_batch_id=p_batch_id
    AND    XSIM.inv_category_process_flag IN (4,5,6)
    UNION ALL
    SELECT XSIM.item
          ,XSIM.organization_id
          ,gn_odpb_category_set_id
          ,XSIM.odpb_category_id
          ,G_TRANSACTION_TYPE
          ,G_PROCESS_FLAG
          ,p_batch_id
          ,G_DATE
          ,G_USER_ID
          ,G_DATE
          ,G_USER_ID
          ,G_USER_ID
    FROM   xx_item_master_stg XSIM
    WHERE  XSIM.load_batch_id=p_batch_id
    AND    XSIM.odpb_category_process_flag IN (4,5,6)
    UNION ALL
    SELECT XSIM.item
          ,XSIM.organization_id
          ,gn_po_category_set_id
          ,XSIM.po_category_id
          ,G_TRANSACTION_TYPE
          ,G_PROCESS_FLAG
          ,p_batch_id
          ,G_DATE
          ,G_USER_ID
          ,G_DATE
          ,G_USER_ID
          ,G_USER_ID
    FROM   xx_item_master_stg XSIM   
    WHERE  XSIM.load_batch_id=p_batch_id
    AND    XSIM.po_category_process_flag  IN (4,5,6)
    UNION ALL
    SELECT XSIM.item
          ,XSIM.organization_id
          ,gn_atp_category_set_id
          ,XSIM.atp_category_id
          ,G_TRANSACTION_TYPE
          ,G_PROCESS_FLAG
          ,p_batch_id
          ,G_DATE
          ,G_USER_ID
          ,G_DATE
          ,G_USER_ID
          ,G_USER_ID
    FROM   xx_item_master_stg XSIM   
    WHERE  XSIM.load_batch_id=p_batch_id
    AND    XSIM.atp_category_process_flag  IN (4,5,6);   

   --------------------------------------------------------------------------------------   
   --Inserting Success items into MTL_SYSTEM_ITEMS_INTERFACE for Organization Assignments 
   --------------------------------------------------------------------------------------   
   INSERT INTO MTL_SYSTEM_ITEMS_INTERFACE
            (
             segment1
            ,description
            ,primary_uom_code
            ,organization_id
            ,template_id
            ,inventory_item_status_code
            ,process_flag
            ,set_process_id
            ,transaction_type
            ,summary_flag
            ,last_update_date
            ,last_updated_by
            ,creation_date
            ,created_by
            ,last_update_login
           )
   SELECT   XSIL.item
           ,XSIM.item_desc
           ,XSIM.package_uom
           ,XSIL.organization_id
           ,XSIL.template_id
           ,XSIL.status
           ,G_PROCESS_FLAG
           ,p_batch_id
           ,G_TRANSACTION_TYPE
           ,'Y'
           ,G_DATE
           ,G_USER_ID
           ,G_DATE
           ,G_USER_ID
           ,G_USER_ID
   FROM     xx_item_loc_stg XSIL
           ,xx_item_master_stg XSIM
   WHERE    XSIL.item=XSIM.item
   AND      XSIL.load_batch_id=p_batch_id
   AND      XSIL.location_process_flag  IN (4,5,6);

    COMMIT;

    --Setting the delete flag depending uopn the incoming parameter.
    IF  p_delete_flag='Y' THEN
        ln_del_rec_flag:=1;
    ELSE
        ln_del_rec_flag:=2;
    END IF;

    ----------------------------------------------------------------------------------------------------------------
    --Call the inopinp_open_interface_process API to process items,Organization Assignments and Category Assignments
    ----------------------------------------------------------------------------------------------------------------
    ln_return_code := INVPOPIF.inopinp_open_interface_process 
                                                              ( org_id         =>  gn_master_org_id 
                                                               ,all_org        =>  1  
                                                               ,val_item_flag  =>  1  
                                                               ,pro_item_flag  =>  1  
                                                               ,del_rec_flag   =>  ln_del_rec_flag  
                                                               ,prog_appid     =>  -1
                                                               ,prog_id        =>  -1
                                                               ,request_id     =>  -1
                                                               ,user_id        =>  G_USER_ID 
                                                               ,login_id       =>  G_USER_ID
                                                               ,err_text       =>  lc_err_text 
                                                               ,xset_id        =>  p_batch_id  
                                                               ,commit_flag    =>  1
                                                               ,run_mode       =>  1  
                                                              );
    COMMIT;
    
    ---------------------------------------------------------------------
    --Logging error details for failed Items Corresponding to Master Orgs
    ---------------------------------------------------------------------
    OPEN lcu_item_cat_error(p_batch_id);
    LOOP
        FETCH lcu_item_cat_error BULK COLLECT INTO lt_item_cat_error,lt_item_cat_errorid,lt_rowid_failure LIMIT G_LIMIT_SIZE;
        IF lt_item_cat_errorid.COUNT>0 THEN
            FOR i IN 1.. lt_item_cat_errorid.COUNT 
            LOOP   
                bulk_log_error(  p_error_msg            =>  lt_item_cat_error(i)
                                ,p_error_code           =>  NULL
                                ,p_control_id           =>  lt_item_cat_errorid(i)
                                ,p_request_id           =>  fnd_global.conc_request_id
                                ,p_converion_id         =>  gn_conversion_id   
                                ,p_package_name         =>  G_PACKAGE_NAME
                                ,p_procedure_name       =>  'process_item_data'
                                ,p_staging_table_name   =>  'XX_ITEM_MASTER_STG'
                                ,p_batch_id             =>  p_batch_id
                              ); 
                
            END LOOP;
            XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
            ----------------------------------------------
            --Updating Item Process Flags for Failed Items
            ----------------------------------------------
            FORALL i IN 1 .. lt_item_cat_errorid.LAST 
            UPDATE xx_item_master_stg XSIM
            SET    XSIM.item_process_flag = 6
            WHERE  XSIM.ROWID        = lt_rowid_failure(i);
        END IF;
        EXIT WHEN lcu_item_cat_error%NOTFOUND;
    END LOOP;
    CLOSE lcu_item_cat_error;
    COMMIT;
    
    ----------------------------------------------------------------------
    --Updating Item Process Flags and Inventory Item Ids for Success Items
    ----------------------------------------------------------------------
    OPEN  lcu_success_item_ids(p_batch_id);
    FETCH lcu_success_item_ids BULK COLLECT INTO lt_itemid_success,lt_rowid_success;
    CLOSE lcu_success_item_ids;

    IF lt_itemid_success.COUNT>0 THEN
       FORALL i IN 1 .. lt_itemid_success.LAST 
       UPDATE xx_item_master_stg XSIM
       SET    XSIM.item_process_flag = 7
             ,XSIM.inventory_item_id = lt_itemid_success(i)
       WHERE  XSIM.ROWID             = lt_rowid_success(i);
    END IF;
    COMMIT;
    ------------------------------------------------------------------------
    --Updating Inventory Category Process Flags for Success Category records
    ------------------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM1
    SET    XSIM1.inv_category_process_flag=7
    WHERE  XSIM1.ROWID IN (
                                SELECT XSIM.ROWID
                                FROM   mtl_item_categories MIC  
                                      ,xx_item_master_stg XSIM
                                      ,mtl_system_items_b MSIB
                                WHERE  MSIB.inventory_item_id           =   MIC.inventory_item_id
                                AND    MSIB.organization_id             =   MIC.organization_id
                                AND    MSIB.segment1                    =   XSIM.item
                                AND    MIC.organization_id              =   XSIM.organization_id
                                AND    XSIM.inv_category_id             =   MIC.category_id
                                AND    XSIM.inv_category_process_flag   IN  (4,5,6)
                                AND    MIC.category_set_id              =   gn_inv_category_set_id
                                AND    XSIM.load_batch_id               =   p_batch_id
                              )
    AND    XSIM1.item_process_flag=7;
    COMMIT;
    -------------------------------------------------------------------                           
    --Updating ODPB Category Process Flags for Success Category records
    -------------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM1
    SET    XSIM1.odpb_category_process_flag=7
    WHERE  XSIM1.ROWID IN (
                                SELECT XSIM.ROWID
                                FROM   mtl_item_categories MIC  
                                      ,xx_item_master_stg XSIM,
                                       mtl_system_items_b MSIB
                                WHERE  MSIB.inventory_item_id           =   MIC.inventory_item_id
                                AND    MSIB.organization_id             =   MIC.organization_id
                                AND    MSIB.segment1                    =   XSIM.item
                                AND    MIC.organization_id              =   XSIM.organization_id
                                AND    XSIM.odpb_category_id            =   MIC.category_id
                                AND    XSIM.odpb_category_process_flag  IN  (4,5,6)
                                AND    MIC.category_set_id              =   gn_odpb_category_set_id
                                AND    XSIM.load_batch_id               =   p_batch_id
                              )
    AND    XSIM1.item_process_flag=7;
    COMMIT;
    -----------------------------------------------------------------
    --Updating PO Category Process Flags for Success Category records
    -----------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM1
    SET    XSIM1.po_category_process_flag=7
    WHERE  XSIM1.ROWID IN (
                                SELECT XSIM.ROWID
                                FROM   mtl_item_categories MIC  
                                      ,xx_item_master_stg XSIM,
                                       mtl_system_items_b MSIB
                                WHERE  MSIB.inventory_item_id           =   MIC.inventory_item_id
                                AND    MSIB.organization_id             =   MIC.organization_id
                                AND    MSIB.segment1                    =   XSIM.item
                                AND    MIC.organization_id              =   XSIM.organization_id
                                AND    XSIM.po_category_id              =   MIC.category_id
                                AND    XSIM.po_category_process_flag    IN  (4,5,6)
                                AND    MIC.category_set_id              =   gn_po_category_set_id
                                AND    XSIM.load_batch_id               =   p_batch_id
                              )
    AND    XSIM1.item_process_flag=7;
    COMMIT;
    
    ------------------------------------------------------------------
    --Updating ATP Category Process Flags for Success Category records
    ------------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM1
    SET    XSIM1.atp_category_process_flag=7
    WHERE  XSIM1.ROWID IN (
                                SELECT XSIM.ROWID
                                FROM   mtl_item_categories MIC  
                                      ,xx_item_master_stg XSIM,
                                       mtl_system_items_b MSIB
                                WHERE  MSIB.inventory_item_id           =   MIC.inventory_item_id
                                AND    MSIB.organization_id             =   MIC.organization_id
                                AND    MSIB.segment1                    =   XSIM.item
                                AND    MIC.organization_id              =   XSIM.organization_id
                                AND    XSIM.atp_category_id             =   MIC.category_id
                                AND    XSIM.atp_category_process_flag   IN  (4,5,6)
                                AND    MIC.category_set_id              =   gn_atp_category_set_id
                                AND    XSIM.load_batch_id               =   p_batch_id
                              )
    AND    XSIM1.item_process_flag=7;
    COMMIT;
    
    ------------------------------------------------------------------------
    --Updating Inventory Category Process Flags for Failure Category records
    ------------------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM
    SET    XSIM.inv_category_process_flag   =   6
    WHERE  XSIM.inv_category_process_flag   IN (4,5)
    AND    XSIM.load_batch_id               =   p_batch_id;
    COMMIT;
    -------------------------------------------------------------------   
    --Updating ODPB Category Process Flags for Failure Category records
    -------------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM
    SET    XSIM.odpb_category_process_flag  =  6
    WHERE  XSIM.odpb_category_process_flag  IN (4,5)
    AND    XSIM.load_batch_id               =  p_batch_id;
    COMMIT;
    -----------------------------------------------------------------
    --Updating PO Category Process Flags for Failure Category records
    -----------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM
    SET    XSIM.po_category_process_flag    =  6
    WHERE  XSIM.po_category_process_flag    IN (4,5)
    AND    XSIM.load_batch_id               =  p_batch_id;
    COMMIT;
    ------------------------------------------------------------------
    --Updating ATP Category Process Flags for Failure Category records
    ------------------------------------------------------------------
    UPDATE xx_item_master_stg XSIM
    SET    XSIM.atp_category_process_flag    =  6
    WHERE  XSIM.atp_category_process_flag    IN (4,5)
    AND    XSIM.load_batch_id               =  p_batch_id;
    COMMIT;
    
    --------------------------------------------
    --Logging error details for failed locations
    --------------------------------------------
    OPEN lcu_loc_error(p_batch_id);
    LOOP
        FETCH lcu_loc_error BULK COLLECT INTO lt_loc_error,lt_loc_errorid,lt_locationrowid_failure LIMIT G_LIMIT_SIZE;
        IF  lt_loc_errorid.COUNT>0 THEN
            XX_COM_CONV_ELEMENTS_PKG.bulk_table_initialize;
            FOR i IN 1.. lt_loc_errorid.COUNT
            LOOP
                bulk_log_error( p_error_msg         =>  lt_loc_error(i)
                               ,p_error_code        =>  NULL
                               ,p_control_id        =>  lt_loc_errorid(i)
                               ,p_request_id        =>  fnd_global.conc_request_id
                               ,p_converion_id      =>  gn_conversion_id   
                               ,p_package_name      =>  G_PACKAGE_NAME
                               ,p_procedure_name    =>  'process_item_data'
                               ,p_staging_table_name=>  'XX_ITEM_LOC_STG'
                               ,p_batch_id          =>  p_batch_id
                              ); 
            END LOOP;
            XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
            -----------------------------------------------------
            --Updating Location Process Flag for Failed Locations
            -----------------------------------------------------
           FORALL i IN 1 .. lt_loc_errorid.LAST 
           UPDATE xx_item_loc_stg XSIL
           SET    XSIL.location_process_flag= 6
           WHERE  XSIL.ROWID           = lt_locationrowid_failure(i);
        END IF;
        EXIT WHEN lcu_loc_error%NOTFOUND;
    END LOOP;
    CLOSE lcu_loc_error;
    COMMIT;
    -------------------------------------------------------
    --Updating Location Process Flags for Success Locations
    -------------------------------------------------------
    OPEN lcu_success_locations_itemids(p_batch_id);
    LOOP
        FETCH lcu_success_locations_itemids BULK COLLECT INTO lt_locationid_success,lt_locationrowid_success LIMIT G_LIMIT_SIZE;
        IF lt_locationid_success.COUNT>0 THEN
           FORALL i IN 1 .. lt_locationid_success.LAST 
           UPDATE xx_item_loc_stg XSIL
           SET    XSIL.location_process_flag= 7
                 ,XSIL.inventory_item_id    = lt_locationid_success(i)
           WHERE  XSIL.ROWID                = lt_locationrowid_success(i);
        END IF;
        COMMIT;
        EXIT WHEN lcu_success_locations_itemids%NOTFOUND;
    END LOOP;
    CLOSE lcu_success_locations_itemids;
    COMMIT;
    
END IF;--gc_master_setup_status='Y'

EXCEPTION
WHEN OTHERS THEN
    IF lcu_item_cat_error%ISOPEN THEN
        CLOSE lcu_item_cat_error;
    END IF;
    IF lcu_loc_error%ISOPEN THEN
        CLOSE lcu_loc_error;
    END IF;
    gc_sqlerrm := SQLERRM; 
    gc_sqlcode := SQLCODE; 
    x_errbuf  := 'Unexpected error in process_item_data - '||gc_sqlerrm;
    x_retcode := 2;
    bulk_log_error( p_error_msg          =>  gc_sqlerrm
                   ,p_error_code         =>  gc_sqlcode
                   ,p_control_id         =>  NULL
                   ,p_request_id         =>  fnd_global.conc_request_id
                   ,p_converion_id       =>  gn_conversion_id   
                   ,p_package_name       =>  G_PACKAGE_NAME
                   ,p_procedure_name     =>  'process_item_data'
                   ,p_staging_table_name =>  NULL
                   ,p_batch_id           =>  p_batch_id
                 ); 
    XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;
END process_item_data;
 
-- +===================================================================+
-- | Name        :  child_main                                         |
-- | Description :  This procedure is invoked from the OD: INV Items   |
-- |                Conversion Child  Concurrent Request.This would    |
-- |                submit conversion programs based on input    .     |
-- |                parameters                                         |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                p_delete_flag                                      |
-- |                p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE child_main(
                       x_errbuf             OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                      ,p_validate_only_flag IN  VARCHAR2
                      ,p_reset_status_flag  IN  VARCHAR2
                      ,p_delete_flag        IN  VARCHAR2
                      ,p_batch_id           IN  NUMBER
                    )
IS
---------------------------
--Declaring local variables
---------------------------

lx_errbuf                   VARCHAR2(5000);
lx_retcode                  VARCHAR2(20);
lx_process_errbuf           VARCHAR2(5000);
lx_process_retcode          VARCHAR2(20);
lx_attr_errbuf              VARCHAR2(5000);
lx_attr_retcode             VARCHAR2(20);
ln_items_processed          PLS_INTEGER;
ln_items_failed             PLS_INTEGER;
ln_locations_processed      PLS_INTEGER;
ln_locations_failed         PLS_INTEGER;
ln_items_invalid            PLS_INTEGER;
ln_locations_invalid        PLS_INTEGER;
ln_request_id               PLS_INTEGER;
ln_item_total               PLS_INTEGER;
ln_location_total           PLS_INTEGER;
-------------------------------------------------
--Cursor to get the Control Information for Items
-------------------------------------------------
CURSOR lcu_master_info (p_batch_id IN NUMBER)
IS
SELECT COUNT (CASE WHEN item_process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN item_process_flag ='6' THEN 1 END),
       COUNT (CASE WHEN item_process_flag ='7' THEN 1 END)
FROM   xx_item_master_stg XSIM
WHERE  XSIM.load_batch_id=p_batch_id;
-----------------------------------------------------
--Cursor to get the Control Information for Locations
-----------------------------------------------------           
CURSOR lcu_location_info (p_batch_id IN NUMBER)
IS
SELECT COUNT (CASE WHEN location_process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN location_process_flag ='6' THEN 1 END),
       COUNT (CASE WHEN location_process_flag ='7' THEN 1 END)
FROM   xx_item_loc_stg XSIL
WHERE  XSIL.load_batch_id=p_batch_id;

BEGIN
    BEGIN    
        display_log('*Batch_id* '||p_batch_id);

        ------------------------------
        --Initializing local variables
        ------------------------------
        ln_item_total           :=  0;
        ln_location_total       :=  0;
        ln_items_processed      :=  0;
        ln_locations_processed  :=  0;
        ln_items_failed         :=  0;
        ln_locations_failed     :=  0;
        ln_items_invalid        :=  0;
        ln_locations_invalid    :=  0;

        -----------------------------------------------------------
        --Calling validate_item_data for SetUp and Data Validations 
        -----------------------------------------------------------
        validate_item_data( x_errbuf                  =>lx_errbuf
                           ,x_retcode                 =>lx_retcode
                           ,p_batch_id                =>p_batch_id
                          );
        IF lx_retcode <> 0 THEN
            x_retcode := lx_retcode;
            CASE WHEN x_errbuf IS NULL 
                 THEN x_errbuf  := lx_errbuf;
                 ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
            END CASE;
        END IF;    
        
        ---------------------------------------------
        --Processing data if p_validate_only_flag='N'
        ---------------------------------------------
        IF  p_validate_only_flag = 'N' THEN

            lx_errbuf     := NULL;
            lx_retcode    := NULL;
            process_item_data(
                               x_errbuf     =>lx_errbuf
                              ,x_retcode    =>lx_retcode
                              ,p_batch_id   =>p_batch_id
                              ,p_delete_flag=>p_delete_flag
                             );

            IF lx_retcode <> 0 THEN
                x_retcode := lx_retcode;
                CASE WHEN x_errbuf IS NULL
                     THEN x_errbuf  := lx_errbuf;
                     ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
                END CASE;
            END IF;    
        
            lx_errbuf     := NULL;
            lx_retcode    := NULL;
            insert_item_attributes( 
                                    x_errbuf     =>lx_errbuf
                                   ,x_retcode    =>lx_retcode
                                   ,p_batch_id   =>p_batch_id
                                  );
                                  
            IF lx_retcode <> 0 THEN
                x_retcode := lx_retcode;
                CASE WHEN x_errbuf IS NULL 
                     THEN x_errbuf  := lx_errbuf;
                     ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
                END CASE;
            END IF;    
            
        END IF;
    EXCEPTION
    WHEN OTHERS THEN
        x_retcode := lx_retcode;
        CASE WHEN x_errbuf IS NULL 
             THEN x_errbuf  := gc_sqlerrm;
             ELSE x_errbuf  := x_errbuf||'/'||gc_sqlerrm;
        END CASE;
        x_retcode := 2;
        bulk_log_error( p_error_msg          =>  SQLERRM
                       ,p_error_code         =>  SQLCODE
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'child_main'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      );     
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;                        
    
    END;
    -------------------------------------------------------------
    --Getting the Master Request Id to update Control Information 
    -------------------------------------------------------------
    get_master_request_id(
                           p_conversion_id     => gn_conversion_id
                          ,p_batch_id          => p_batch_id
                          ,x_master_request_id => ln_request_id
                         );
                         
    IF ln_request_id IS NOT NULL THEN
        --Fetching Number of  Invalid,Processing Failed and Processed Master Items
        OPEN lcu_master_info(p_batch_id);
        FETCH lcu_master_info INTO ln_items_invalid,ln_items_failed,ln_items_processed;
        CLOSE lcu_master_info;
        ----------------------------------
        --Updating the Control Information
        ----------------------------------
        XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc(
                                                          p_conc_mst_req_id             => ln_request_id --APPS.FND_GLOBAL.CONC_REQUEST_ID
                                                         ,p_batch_id                    => p_batch_id
                                                         ,p_conversion_id               => gn_conversion_id
                                                         ,p_num_bus_objs_failed_valid   => ln_items_invalid
                                                         ,p_num_bus_objs_failed_process => ln_items_failed
                                                         ,p_num_bus_objs_succ_process   => ln_items_processed
                                                     );
        --Fetching Number of Invalid,Processing Failed and Processed Location Items
        OPEN lcu_location_info(p_batch_id);
        FETCH lcu_location_info INTO ln_locations_invalid,ln_locations_failed,ln_locations_processed;
        CLOSE lcu_location_info;    
    END IF; 

    --------------------------------------------------------------------------------------------
    -- Launch the Exception Log Report for this batch
    --------------------------------------------------------------------------------------------
    lx_errbuf     := NULL;
    lx_retcode    := NULL;
    launch_exception_report(
                             p_batch_id => p_batch_id 
                            ,x_errbuf   => lx_errbuf
                            ,x_retcode  => lx_retcode
                           );
    IF lx_retcode <> 0 THEN
        x_retcode := lx_retcode;
        CASE WHEN x_errbuf IS NULL 
             THEN x_errbuf  := lx_errbuf;
             ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
        END CASE;
    END IF;   
    
    --------------------------------------------------                       
    --Displaying the Items Information in the Out file
    --------------------------------------------------
    ln_item_total := ln_items_invalid+ ln_items_failed + ln_items_processed;
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of Item Records      : ',49,' ')||RPAD(ln_item_total,9,' '));
    display_out(RPAD('No. Of Item Records Processed  : ',49,' ')||RPAD(ln_items_processed,9,' '));
    display_out(RPAD('No. Of Item Records Errored    : ',49,' ')||RPAD(ln_items_failed,9,' '));
    display_out(RPAD('=',58,'='));
    ------------------------------------------------------
    --Displaying the Locations Information in the Out file
    ------------------------------------------------------
    ln_location_total := ln_locations_invalid+ ln_locations_failed + ln_locations_processed;
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of Location Records      : ',49,' ')||RPAD(ln_location_total,9,' '));
    display_out(RPAD('No. Of Location Records Processed  : ',49,' ')||RPAD(ln_locations_processed,9,' '));
    display_out(RPAD('No. Of Location Records Errored    : ',49,' ')||RPAD(ln_locations_failed,9,' '));
    display_out(RPAD('=',58,'='));

    EXCEPTION
    WHEN OTHERS THEN
        x_errbuf  := 'Unexpected error in child_main - '||SQLERRM;
        x_retcode := 2;
        bulk_log_error( p_error_msg          =>  SQLERRM
                       ,p_error_code         =>  SQLCODE
                       ,p_control_id         =>  NULL
                       ,p_request_id         =>  fnd_global.conc_request_id
                       ,p_converion_id       =>  gn_conversion_id   
                       ,p_package_name       =>  G_PACKAGE_NAME
                       ,p_procedure_name     =>  'child_main'
                       ,p_staging_table_name =>  NULL
                       ,p_batch_id           =>  p_batch_id
                      ); 
        XX_COM_CONV_ELEMENTS_PKG.bulk_log_message;                      
END child_main;

END XX_INV_ITEMS_CONV_PKG;
/
SHOW ERRORS
EXIT;
