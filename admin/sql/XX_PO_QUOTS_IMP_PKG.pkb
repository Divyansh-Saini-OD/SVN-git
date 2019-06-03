SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT  Creating XX_PO_QUOTS_IMP_PKG package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_PO_QUOTS_IMP_PKG
 -- +====================================================================================+
 -- |                  Office Depot - Project Simplify                                   |
 -- |                 Oracle NAIO/WIPRO/Office Depot/Consulting Organization             |
 -- +====================================================================================+
 -- | Name             :  XX_PO_QUOTS_IMP_PKG.pkb                                        |
 -- | Description      :  This package body is used in PO Quotation Conversion.          |
 -- |                                                                                    |
 -- | Change Record:                                                                     |
 -- |===============                                                                     |
 -- |Version   Date        Author           Remarks                                      |
 -- |=======   ==========  =============    =============================================|
 -- |Draft 1a  16-MAY-2007 Chandan U H      Initial draft version with Master Conversion |
 -- |                                       Program Logic.                               |
 -- |Draft 1b  23-MAY-2007 Chandan U H      Incorporated Review Comments.                |
 -- | 1.0      25-MAY-2007 Chandan U H      Baselined.                                   |   
 -- +====================================================================================+ 
AS

-- ---------------------------
-- Global Variable Declaration
-- ---------------------------

gt_request_id       FND_CONCURRENT_REQUESTS.request_id%TYPE ;
gn_batch_size       NUMBER;
gn_conversion_id    NUMBER;
gn_batch_count      NUMBER := 0;
gn_record_count     NUMBER := 0;
gn_sleep            NUMBER := 60;
gn_max_wait_time    NUMBER := 300;
gn_max_child_req    NUMBER ;
gn_req_id           NUMBER := 0;
gc_conversion_code  VARCHAR2(80):='C0301_PurchasePriceFromRMS';

-- -------------------------------
-- Type declaration for request_id
-- -------------------------------

TYPE req_id_tbl_type IS TABLE OF FND_CONCURRENT_REQUESTS.request_id%TYPE
INDEX BY BINARY_INTEGER;

TYPE xx_qty_price_rec IS RECORD (
                                   quantity NUMBER
                                  ,price    NUMBER
                                  );
-- ----------------------------------
-- Variable for request_id table type
-- ----------------------------------
lt_req_id req_id_tbl_type;

-- -----------------------------------------
-- Table type for holding staging table data
-- -----------------------------------------
                                              
TYPE stg_tbl_type              IS  TABLE  OF  xx_od_po_quotation_stg%ROWTYPE                 INDEX BY BINARY_INTEGER;
TYPE ctrl_id_tbl_type          IS  TABLE  OF  xx_od_po_quotation_stg.control_id%TYPE         INDEX BY BINARY_INTEGER;
TYPE pro_flg_tbl_type          IS  TABLE  OF  xx_od_po_quotation_stg.process_flag%TYPE       INDEX BY BINARY_INTEGER;
TYPE err_msg_tbl_type          IS  TABLE  OF  xx_od_po_quotation_stg.error_message%TYPE      INDEX BY BINARY_INTEGER;
TYPE qty_price_tbl_type        IS  TABLE  OF  xx_qty_price_rec                               INDEX BY BINARY_INTEGER;      
TYPE success_po_hdr_tbl_type   IS  TABLE  OF  xx_od_po_quotation_stg.control_id%TYPE         INDEX BY BINARY_INTEGER;
TYPE unsuccess_po_hdr_tbl_type IS  TABLE  OF  xx_od_po_quotation_stg.control_id%TYPE         INDEX BY BINARY_INTEGER;
TYPE lt_bat_cntrl_id_tbl_type  IS  TABLE  OF  xx_od_po_quotation_stg.control_id%TYPE         INDEX BY BINARY_INTEGER;
TYPE g_ready_for_proc_tbl_type IS  TABLE  OF  xx_od_po_quotation_stg%ROWTYPE                 INDEX BY BINARY_INTEGER;
TYPE inv_itm_id_tbl_type       IS  TABLE  OF  xx_od_po_quotation_stg.inventory_item_id%TYPE  INDEX BY BINARY_INTEGER;                  
TYPE ven_site_id_tbl_type      IS  TABLE  OF  xx_od_po_quotation_stg.vendor_site_id%TYPE     INDEX BY BINARY_INTEGER; 
TYPE org_id_tbl_type           IS  TABLE  OF  xx_od_po_quotation_stg.org_id%TYPE             INDEX BY BINARY_INTEGER;             
TYPE agent_id_tbl_type         IS  TABLE  OF  xx_od_po_quotation_stg.agent_id%TYPE           INDEX BY BINARY_INTEGER;
                                              
     


-- ----------------------------------------
-- Variable declaration of type -table type
-- ----------------------------------------
g_stg_tbl                stg_tbl_type;
g_org_id_tbl             org_id_tbl_type;   
g_ctrl_id_tbl            ctrl_id_tbl_type;
g_pro_flg_tbl            pro_flg_tbl_type;
g_err_msg_tbl            err_msg_tbl_type;
g_agent_id_tbl           agent_id_tbl_type; 
qty_price_tbl            qty_price_tbl_type;
g_inv_itm_id_tbl         inv_itm_id_tbl_type;
g_ven_site_id_tbl        ven_site_id_tbl_type;
g_success_po_hdr_tbl     success_po_hdr_tbl_type;
g_bat_control_id_tbl     lt_bat_cntrl_id_tbl_type;
g_ready_for_proc_tbl     g_ready_for_proc_tbl_type;
g_unsuccess_po_hdr_tbl   unsuccess_po_hdr_tbl_type;   
                        
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

END display_log;        

-- +====================================================================+
-- | Name        :  display_out                                         |
-- | Description :  This procedure is invoked to print in the output    |
-- |                file                                                |
-- |                                                                    |
-- | Parameters  :  Log Message                                         |
-- +====================================================================+

PROCEDURE display_out(
                      p_message IN VARCHAR2
                     )

IS

BEGIN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);
END display_out;

-- +====================================================================+
-- | Name        :  update_batch_id                                     |
-- | Description :  This procedure is invoked to reset Batch Id to Null |
-- |                for Previously Errored Out Records                  |
-- |                                                                    |
-- | Parameters  :  None                                                |
-- +====================================================================+

PROCEDURE update_batch_id

IS

-- ------------------------------------------------------------
-- Cursor declaration to get the previously errored out records
-- ------------------------------------------------------------

CURSOR   lcu_upd_batch
IS
SELECT   XOPQS.control_id
FROM     xx_od_po_quotation_stg XOPQS
WHERE    XOPQS.process_flag IN (3,6)
ORDER BY XOPQS.control_id;

BEGIN

   -- -------------------------
   -- Clear the table type data
   -- -------------------------
   g_ctrl_id_tbl.DELETE ;

   -- ---------------------------------------
   -- Collect the records into the table type
   -- ---------------------------------------
   OPEN  lcu_upd_batch;
   FETCH lcu_upd_batch BULK COLLECT INTO g_ctrl_id_tbl;
   CLOSE lcu_upd_batch;

   IF g_ctrl_id_tbl.COUNT <> 0 THEN

      FORALL i IN 1 .. g_ctrl_id_tbl.COUNT
      UPDATE  xx_od_po_quotation_stg XOPQS
      SET     XOPQS.load_batch_id  = NULL
             ,XOPQS.process_flag   = 1
      WHERE   XOPQS.control_id = g_ctrl_id_tbl(i);
      COMMIT;

   END IF;

END update_batch_id;

-- +====================================================================+
-- | Name        :  launch_summary_report                               |
-- | Description :  This procedure is invoked to Launch Conversion      |
-- |                Processing Summary Report for that run of Master    |
-- |                Program                                             |
-- |                                                                    |
-- | Out Parameters :x_errbuf                                           |
-- |                 x_retcode                                          |
-- +====================================================================+

PROCEDURE launch_summary_report(
                                x_errbuf   OUT VARCHAR2
                               ,x_retcode OUT VARCHAR2
                               )

IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------
lt_conc_summ_request_id FND_CONCURRENT_REQUESTS.request_id%TYPE; 
ln_master_req_id        NUMBER;
ln_request_id           NUMBER;
ln_batch_id             NUMBER;
lc_status               VARCHAR2(3);
EX_REP_SUMM             EXCEPTION;


BEGIN

   FOR i IN lt_req_id.FIRST .. lt_req_id.LAST
   LOOP
      LOOP
         -- ----------------------------------------
         -- Get the status of the concurrent request
         -- ----------------------------------------

         SELECT FCR.phase_code
         INTO   lc_status
         FROM   FND_CONCURRENT_REQUESTS FCR
         WHERE  FCR.request_id = lt_req_id(i);

         --- ------------------------------------------------
         --  If the concurrent requests completed sucessfully
         -- -------------------------------------------------

         IF  lc_status = 'C' THEN
             EXIT;
         ELSE
             DBMS_LOCK.sleep(gn_sleep);
         END IF;

       END LOOP;

   END LOOP;

   ln_master_req_id := NULL;
   ln_request_id    := NULL;
   ln_batch_id      := NULL;

   -- ---------------------------------------------
   -- Call the child program for parallel execution
   -- ---------------------------------------------

   lt_conc_summ_request_id := FND_REQUEST.submit_request(
                                                         application  =>'XXCOMN'
                                                        ,program     => 'XXCOMCONVSUMMREP'
                                                        ,sub_request => FALSE            -- FALSE means not a sub request
                                                        ,argument1   => gc_conversion_code -- conversion_code
                                                        ,argument2   => ln_master_req_id -- MASTER REQUEST ID
                                                        ,argument3   => ln_request_id    -- REQUEST ID
                                                        ,argument4   => ln_batch_id      -- BATCH ID
                                                       );

   IF  lt_conc_summ_request_id = 0 THEN

       x_errbuf := FND_MESSAGE.GET;
       RAISE EX_REP_SUMM;

   ELSE

       COMMIT;

   END IF;

EXCEPTION

   WHEN EX_REP_SUMM THEN

      x_retcode := 2;
      x_errbuf  := 'Processing Summary Report for the batch could not be submitted: '|| x_errbuf;
END launch_summary_report;

-- +====================================================================+
-- | Name        :  launch_exception_report                             |
-- | Description : This procedure is invoked to Launch Exception Report |
-- |               for every batch launched by the Master Program.      |
-- |                                                                    |
-- | In Parameters : p_batch_id                                         |
-- | Out Parameters: x_errbuf                                           |
-- |                 x_retcode                                          |
-- +====================================================================+

PROCEDURE launch_exception_report(
                                   p_batch_id  IN  NUMBER
                                  ,x_errbuf    OUT VARCHAR2
                                  ,x_retcode   OUT VARCHAR2
                                 )
IS

-- --------------------------
-- Local Variable declaration
-- --------------------------

lt_conc_excep_request_id FND_CONCURRENT_REQUESTS.request_id%TYPE; 
ln_request_id            NUMBER;
EX_REP_EXC               EXCEPTION;

BEGIN

   gt_request_id := NULL;
   ln_request_id := NULL;

   lt_conc_excep_request_id := FND_REQUEST.submit_request(
                                                           application => 'XXCOMN'
                                                          ,program     => 'XXCOMCONVEXPREP'
                                                          ,sub_request => FALSE            -- TRUE means is a sub request
                                                          ,argument1   => gc_conversion_code -- conversion_code
                                                          ,argument2   => gt_request_id    -- MASTER REQUEST ID
                                                          ,argument3   => ln_request_id    -- REQUEST ID
                                                          ,argument4   => p_batch_id       -- BATCH ID
                                                         );

   IF  lt_conc_excep_request_id = 0 THEN

      x_errbuf := FND_MESSAGE.GET;
      RAISE EX_REP_EXC;

   ELSE

        COMMIT;

   END IF;

EXCEPTION

   WHEN EX_REP_EXC THEN
      x_retcode := 2;
      x_errbuf  := 'Exception Summary Report for the batch '||p_batch_id||' could not be submitted: ' || x_errbuf;

END launch_exception_report;

-- +====================================================================+
-- | Name        :  get_conversion_id                                   |
-- | Description :  This procedure is invoked to get the conversion_id  |
-- |               ,batch_size and max_threads.                         |
-- |                                                                    |
-- |Out Parameters: x_conversion_id                                     |
-- |                x_batch_size                                        |
-- |                x_max_threads                                       |
-- |                x_return_status                                     |  
-- +====================================================================+

PROCEDURE get_conversion_id(
                            x_conversion_id  OUT  NUMBER
                           ,x_batch_size     OUT  NUMBER
                           ,x_max_threads    OUT  NUMBER
                           ,x_return_status  OUT  VARCHAR2
                           )
IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------
ln_conversion_id NUMBER ;
ln_batch_size    NUMBER ;
ln_max_threads   NUMBER ;

BEGIN

     SELECT  XCCC.conversion_id
            ,XCCC.batch_size
            ,XCCC.max_threads
     INTO    ln_conversion_id
            ,ln_batch_size
            ,ln_max_threads
     FROM    XX_COM_CONVERSIONS_CONV XCCC
     WHERE   XCCC.conversion_code = gc_conversion_code;--'C0301_PurchasePriceFromRMS';

     -- ------------------------------------------------
     -- Get the conversion details into the out variable
     -- ------------------------------------------------
     x_conversion_id := ln_conversion_id;
     x_batch_size    := ln_batch_size;
     x_max_threads   := ln_max_threads;
     x_return_status := 'S';

EXCEPTION

   WHEN NO_DATA_FOUND THEN

     x_return_status := 'E';
     display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code  '|| gc_conversion_code);

   WHEN OTHERS THEN
     x_return_status := 'E';
     display_log('Error while deriving conversion_id - '||SQLERRM);

END get_conversion_id;

-- +======================================================================+
-- | Name        :  bat_child                                             |
-- | Description :  This procedure is invoked from the submit_sub_requests|
-- |                procedure. This would submit child requests based     |
-- |                on batch_size.                                        | 
-- |                                                                      |
-- | In Parameters :p_request_id                                          |
-- |                p_validate_only_flag                                  |
-- |                p_reset_status_flag                                   |
-- |                                                                      |
-- | Out Parameters: x_time                                               |
-- |                 x_errbuf                                             |
-- |                 x_retcode                                            |
-- +======================================================================+

PROCEDURE bat_child(
                     p_request_id         IN  NUMBER
                   , p_validate_only_flag IN  VARCHAR2
                   , p_reset_status_flag  IN  VARCHAR2                   
                   , x_time               OUT DATE
                   , x_errbuf             OUT VARCHAR2
                   , x_retcode            OUT VARCHAR2
                   )

IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------

lt_conc_request_id  FND_CONCURRENT_REQUESTS.request_id%TYPE;
ln_batch_size_count    NUMBER;
ln_seq                 NUMBER;
ln_req_count           NUMBER;
EX_SUBMIT_CHILD_FAILED EXCEPTION;

-- -----------------------------------------------------------
-- Declare cursor to get eligible records for batch assignment
-- -----------------------------------------------------------

CURSOR lcu_elig_rec
IS
SELECT control_id
FROM   xx_od_po_quotation_stg XOPQS
WHERE  XOPQS.load_batch_id IS NULL
AND    XOPQS.process_flag = 1
AND    rownum <= gn_batch_size
ORDER BY XOPQS.control_id;


BEGIN

   -- -------------------------
   -- Clear the table type data
   -- -------------------------
   g_ctrl_id_tbl.DELETE ;

   -- -----------------------------------
   -- Get the records into the table type
   -- -----------------------------------
   OPEN  lcu_elig_rec;
   FETCH lcu_elig_rec BULK COLLECT INTO g_ctrl_id_tbl;
   CLOSE lcu_elig_rec;

   ln_batch_size_count := g_ctrl_id_tbl.COUNT;
   gn_record_count := gn_record_count + ln_batch_size_count;

   -- ----------------------------------
   -- Get the batch_id from the sequence
   -- ----------------------------------
   SELECT xx_od_po_quotation_stg_bat_s.NEXTVAL
   INTO   ln_seq
   FROM   DUAL;

   -- -----------------------------
   -- Assign batches to the records
   -- -----------------------------

   FORALL i IN 1 .. g_ctrl_id_tbl.COUNT
   UPDATE xx_od_po_quotation_stg  XOPQS
   SET    XOPQS.load_batch_id = ln_seq,
          XOPQS.process_flag  = 2
   WHERE  XOPQS.control_id = g_ctrl_id_tbl(i);
   COMMIT;

   LOOP
       -- --------------------------------------------
       -- Get the count of running concurrent requests
       -- --------------------------------------------
       SELECT COUNT(1)
       INTO   ln_req_count
       FROM   FND_CONCURRENT_REQUESTS
       WHERE  parent_request_id  = gt_request_id
       AND    status_code = 'R';

       IF ln_req_count < gn_max_child_req THEN

          -- ---------------------------------------------------------
          -- Call the custom concurrent program for parallel execution
          -- ---------------------------------------------------------

          lt_conc_request_id := Fnd_Request.Submit_Request
                                               (
                                                 application => 'PO' --g_custom_appl_name
                                               , program     => 'XX_PO_QUOTS_IMP_PKG_MAIN'--g_custom_pgm_name
                                               , description => 'PO Quotation Conversion Child Program'
                                               , start_time  => NULL
                                               , sub_request => FALSE                                              
                                               , argument1   => p_validate_only_flag
                                               , argument2   => p_reset_status_flag
                                               , argument3   => ln_seq
                                               );                                         
                     
           

           IF lt_conc_request_id = 0 THEN

              x_errbuf := FND_MESSAGE.GET;
              RAISE EX_SUBMIT_CHILD_FAILED;

           ELSE

              COMMIT;

              gn_req_id := gn_req_id + 1;
              lt_req_id(gn_req_id) := lt_conc_request_id;
              gn_batch_count  := gn_batch_count + 1;
              x_time := sysdate;

              ---------------------------------------------------
              -- Procedure to Log Conversion Control Informations.
              ---------------------------------------------------

              XX_COM_CONV_ELEMENTS_PKG.log_control_info_proc(
                                                             p_conversion_id          => gn_conversion_id
                                                            ,p_batch_id               => ln_seq
                                                            ,p_num_bus_objs_processed => ln_batch_size_count
                                                            );
              EXIT;

           END IF;

       ELSE
           dbms_lock.sleep(gn_sleep);
       END IF;

   END LOOP;

EXCEPTION
   WHEN EX_SUBMIT_CHILD_FAILED THEN
      x_retcode := 2;
END bat_child;

-- +===========================================================================+
-- | Name             : GET_MASTER_REQUEST_ID                                  |
-- | Description      : This Procedure is called to get master_request_id      |
-- |                                                                           |
-- | Parameters         p_conversion_id                                        |
-- |                    p_batch_id                                             |
-- |                    x_master_request_id                                    |
-- |                                                                           |
-- +===========================================================================+

PROCEDURE GET_MASTER_REQUEST_ID (
                                 p_conversion_id        IN     NUMBER
                                ,p_batch_id             IN     NUMBER
                                ,x_master_request_id    OUT    NUMBER
                                 )
IS

BEGIN

   SELECT  master_request_id
   INTO    x_master_request_id
   FROM    xx_com_control_info_conv XCCIC
   WHERE   XCCIC.conversion_id = p_conversion_id
   AND     XCCIC.batch_id      = p_batch_id;

EXCEPTION

   WHEN NO_DATA_FOUND THEN
      display_log('Master Request Id for the above batch not found');

   WHEN OTHERS THEN
      display_log('Unexpected Errors occured when fetching x_master_request_id');

END GET_MASTER_REQUEST_ID;

-- +===================================================================+
-- | Name        :  submit_sub_requests                                |
-- | Description :  This procedure is invoked from the batch_main      |
-- |                procedure. This would submit child requests based  |
-- |                on batch_size.                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_validate_only_flag                               |
-- |                p_reset_status_flag                                |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE submit_sub_requests(
                               p_validate_only_flag  IN  VARCHAR2
                              ,p_reset_status_flag   IN  VARCHAR2                             
                              ,x_errbuf              OUT VARCHAR2
                              ,x_retcode             OUT VARCHAR2
                             )

IS

-- --------------------------
-- Local Variable declaration
-- --------------------------

ld_check_time     DATE;
ld_current_time   DATE;
ln_rem_time       NUMBER;
ln_time           VARCHAR2(10);
ln_current_count  NUMBER;
ln_last_count     NUMBER;
lc_return_status  VARCHAR2(3);
lc_launch         VARCHAR2(2):='N';
EX_NO_ENTRY       EXCEPTION;

BEGIN

    get_conversion_id(
                      x_conversion_id  => gn_conversion_id
                     ,x_batch_size     => gn_batch_size
                     ,x_max_threads    => gn_max_child_req
                     ,x_return_status  => lc_return_status
                     );

    IF lc_return_status = 'S' THEN

       IF NVL(p_reset_status_flag,'N') = 'Y' THEN

          -- --------------------------------------------------------
          -- Call update_batch_id to change status of errored records
          -- --------------------------------------------------------
          update_batch_id;

       END IF;

       ld_check_time := sysdate;

       ln_current_count := 0;

       LOOP

          ln_last_count := ln_current_count;

          -- -----------------------------------------
          -- Get the current count of eligible records
          -- -----------------------------------------

          SELECT COUNT(1)
          INTO   ln_current_count
          FROM   xx_od_po_quotation_stg  XOPQS
          WHERE  XOPQS.load_batch_id IS NULL
          AND    XOPQS.process_flag = 1;

          IF (ln_current_count >= gn_batch_size) THEN

             -- -------------------------------------------
             -- Call bat_child to launch the child requests
             -- -------------------------------------------

             bat_child(
                        p_request_id         => gt_request_id
                       ,p_validate_only_flag => p_validate_only_flag
                       ,p_reset_status_flag  => p_reset_status_flag                      
                       ,x_time               => ld_check_time
                       ,x_errbuf             => x_errbuf
                       ,x_retcode            => x_retcode
                       );

              lc_launch := 'Y';

          ELSE

              IF ln_last_count = ln_current_count THEN

                 ld_current_time := sysdate;

                 ln_rem_time := (ld_current_time - ld_check_time)*86400;

                 IF  ln_rem_time > gn_max_wait_time THEN
                     EXIT;
                 ELSE
                     DBMS_LOCK.sleep(gn_sleep);
                 END IF; -- ln_rem_time > gn_max_wait_time

              ELSE

                  DBMS_LOCK.sleep(gn_sleep);

              END IF; -- ln_last_count = ln_current_count

          END IF; --  ln_current_count >= gn_batch_size

       END LOOP;

       IF ln_current_count <> 0 THEN

          bat_child(
                     p_request_id         => gt_request_id
                    ,p_validate_only_flag => p_validate_only_flag
                    ,p_reset_status_flag  => p_reset_status_flag                    
                    ,x_time               => ld_check_time
                    ,x_errbuf             => x_errbuf
                    ,x_retcode            => x_retcode
                   );

          lc_launch := 'Y';

       END IF;

       IF  lc_launch = 'N' THEN

           display_log('No Data Found in Staging Table to Proceed');
           display_log('ln_current_count '||ln_current_count);
           x_retcode := 2;

       ELSE

           -- --------------------------
           -- Lauunch the summary report
           -- --------------------------

           launch_summary_report(
                                 x_errbuf
                                ,x_retcode
                                );

       END IF;

       display_out(RPAD('=',38,'='));
       display_out(RPAD('Batch Size                 : ',29,' ')||RPAD(gn_batch_size,9,' '));
       display_out(RPAD('Number of Records          : ',29,' ')||RPAD(gn_record_count,9,' '));
       display_out(RPAD('Number of Batches Launched : ',29,' ')||RPAD(gn_batch_count,9,' '));       
       display_out(RPAD('=',38,'='));

    ELSE

       RAISE EX_NO_ENTRY;

    END IF; -- lc_return_status

EXCEPTION

   WHEN EX_NO_ENTRY THEN
      x_retcode := 2;
      display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code C0301_PurchasePriceFromRMS');

END;

-- +===================================================================+
-- | Name       :    VALIDATE_PROCESS_RECORDS                          |
-- |                                                                   |
-- | Description:    This procedure performs the validations before    |
-- |                 calling the  custom API for further processing.   |
-- |                                                                   |
-- | In Parameters :  p_batch_id                                       |
-- |                  p_validate_only_flag                             |
-- |                                                                   |
-- | Out Parameters : x_return_status                                  |
-- |                  x_return_msg                                     |
-- +===================================================================+

PROCEDURE VALIDATE_PROCESS_RECORDS
                                (
                                  x_return_status             OUT   VARCHAR2
                                , x_return_msg                OUT   VARCHAR2
                                , p_batch_id                  IN    NUMBER
                                , p_validate_only_flag        IN    VARCHAR2
                                )
IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------  

ln_vendor_id                 po_vendor_sites_all.vendor_id%TYPE;
ln_inventory_item_id         mtl_system_items_b.inventory_item_id%TYPE;
lc_prim_unit_of_measure      mtl_system_items_b.primary_unit_of_measure%TYPE;
ln_organization_id           hr_all_organization_units.organization_id%TYPE;
lc_return_status             VARCHAR2(1);
lc_error_flag                VARCHAR2(1);
lc_org_id_exists             VARCHAR2(1);
lc_inv_item_exists           VARCHAR2(1);
lc_vendor_id_exists          VARCHAR2(1);
lc_agent_id_exists           VARCHAR2(1);
lc_return_msg                VARCHAR2(1000);
lc_error_message             VARCHAR2(1000);
lc_staging_column_name       VARCHAR2(32);
lc_staging_column_value      VARCHAR2(500);
ln_sucess_count              NUMBER;
ln_agent_id                  NUMBER;
ln_vendor_site_id            NUMBER;
EX_VAL_FAIL                  EXCEPTION;

-- ------------------------------------------------------------------
-- Declare cursor to fetch the records in vaidation in progress state
-- ------------------------------------------------------------------

CURSOR lcu_ready_rec
IS
SELECT *
FROM   xx_od_po_quotation_stg XOPQS
WHERE  XOPQS.process_flag  <> 7--IN (2,6)
AND    XOPQS.load_batch_id = p_batch_id ;

BEGIN

   x_return_status :='E';
   -- -------------------------
   -- Clear the table type data
   -- -------------------------

   g_stg_tbl.DELETE;
   g_ctrl_id_tbl.DELETE;
   g_pro_flg_tbl.DELETE;
   g_err_msg_tbl.DELETE;

   -- ------------------------------------
   -- Collect the data into the table type
   -- ------------------------------------
   OPEN  lcu_ready_rec;
   FETCH lcu_ready_rec BULK COLLECT INTO g_stg_tbl;
   CLOSE lcu_ready_rec;

   -- -------------------------------
   -- Validate the records one by one
   -- -------------------------------

   FOR i IN g_stg_tbl.FIRST..g_stg_tbl.LAST
   LOOP
   
   BEGIN
   
          ln_vendor_id            := NULL;
          ln_inventory_item_id    := NULL;
          ln_agent_id             := NULL;
          lc_prim_unit_of_measure := NULL;         
          ln_organization_id      := NULL;
          ln_vendor_site_id       := NULL;


           -- Check Organization Definition in EBS  
                      
          IF g_stg_tbl(i).operating_unit IS NOT NULL THEN
          
            BEGIN
               SELECT HAOU.organization_id
               INTO   ln_organization_id
               FROM   hr_all_organization_units HAOU
               WHERE  HAOU.name = g_stg_tbl(i).operating_unit;
               
               lc_org_id_exists := 'Y';
               x_return_status :='S';
               g_stg_tbl(i).org_id := ln_organization_id;
               
            EXCEPTION
               WHEN OTHERS THEN 
                  x_return_status :='E';
                  g_stg_tbl(i).error_message:= 'Organization is not defined in EBS';--||' for record# '|| g_stg_tbl(i).control_id;
                  lc_staging_column_name  := 'OPERATING_UNIT';
                  lc_staging_column_value := g_stg_tbl(i).operating_unit;
                  RAISE EX_VAL_FAIL;
             END;
          END IF;
    
          -- Check Vendor Site Id Definition in EBS ie.,Supplier

          IF g_stg_tbl(i).vendor_id IS NOT NULL THEN
          
           BEGIN 
              SELECT PVSA.vendor_site_id
              INTO   ln_vendor_site_id
              FROM   po_vendor_sites_all PVSA
              WHERE  PVSA.attribute9 = TO_CHAR(g_stg_tbl(i).vendor_id)
              AND    PVSA.purchasing_site_flag = 'Y'
              AND    SYSDATE < NVL(inactive_date, SYSDATE + 1);
              
              lc_vendor_id_exists := 'Y';
              x_return_status :='S';             
              g_stg_tbl(i).vendor_site_id := ln_vendor_site_id;
              
           EXCEPTION 
              WHEN OTHERS THEN            
                 x_return_status :='E';           
                 g_stg_tbl(i).error_message:='Supplier is not defined in EBS';--|| 'for record# '|| g_stg_tbl(i).control_id;
                 lc_staging_column_name  := 'VENDOR_ID';
                 lc_staging_column_value := g_stg_tbl(i).vendor_id;
                 RAISE EX_VAL_FAIL;
           END;    
           
          END IF;   
          
          IF g_stg_tbl(i).sku IS NOT NULL THEN          
             BEGIN 
                SELECT inventory_item_id
                INTO   ln_inventory_item_id
                FROM   mtl_system_items_b MSIB
                WHERE  MSIB.segment1  = g_stg_tbl(i).sku
                AND    rownum = 1;            
                
                lc_inv_item_exists := 'Y';
                x_return_status :='S'; 
                g_stg_tbl(i).inventory_item_id := ln_inventory_item_id;
                
             EXCEPTION     
                WHEN OTHERS THEN
                   x_return_status :='E';                      
                   g_stg_tbl(i).error_message := 'Item is not defined in EBS'; --||' for record# '|| g_stg_tbl(i).control_id;
                   lc_staging_column_name  := 'SKU';
                   lc_staging_column_value := g_stg_tbl(i).sku;
                   RAISE EX_VAL_FAIL;               
             END;
          END IF;             
 
            
           -- Check Agent ID  Definition in EBS

           IF g_stg_tbl(i).vendor_id IS NOT NULL THEN
              BEGIN
                  SELECT PA.agent_id
                  INTO   ln_agent_id
                  FROM   po_agents PA
                        ,per_all_people_f PAPF
                  WHERE  PA.agent_id = PAPF.person_id
                  AND    PAPF.first_name = 'Veronica'--'Interface'
                  AND    PAPF.last_name  = 'Smith';--'Buyer';                 
                  lc_agent_id_exists := 'Y';
                  x_return_status :='S';
                  g_stg_tbl(i).agent_id := ln_agent_id;
              EXCEPTION     
                 WHEN OTHERS THEN
                     x_return_status :='E';                      
                     g_stg_tbl(i).error_message:= 'Agent Id is not defined in EBS'; --|| 'for record# '|| g_stg_tbl(i).control_id;
                     lc_staging_column_name  := '';--'VENDOR_ID';
                     lc_staging_column_value := 'first_name = Veronica and last_name = Smith';
                     RAISE EX_VAL_FAIL;
              END;

           END IF;          
       
     EXCEPTION
     WHEN EX_VAL_FAIL THEN
        NULL;
     END;
     
      IF x_return_status ='S' THEN
     -- -------------------------------------------------------------
     -- Set the process_flag to '4' for sucessfully validated records
     -- -------------------------------------------------------------
          g_stg_tbl(i).process_flag := 4;      
                 
                 
      ELSE
          -- ---------------------------------------------------------
          -- Set the process_flag to '3' for validation failed records
          -- ---------------------------------------------------------
         
          
           g_stg_tbl(i).process_flag := 3;      
                                                                      
          ----------------------------------------------------------------------------
          -- Call XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
          -- to log the exceptions while records are in validation in processing state
          ----------------------------------------------------------------------------

          XX_COM_CONV_ELEMENTS_PKG.log_exceptions_proc
                                                    (
                                                      p_conversion_id        => gn_conversion_id
                                                    , p_record_control_id    => g_stg_tbl(i).control_id
                                                    , p_source_system_code   => g_stg_tbl(i).source_system_code
                                                    , p_package_name         => 'XX_PO_QUOTS_IMP_PKG'
                                                    , p_procedure_name       => 'main'
                                                    , p_staging_table_name   => 'XX_OD_PO_QUOTATION_STG'
                                                    , p_staging_column_name  => lc_staging_column_name  
                                                    , p_staging_column_value => lc_staging_column_value 
                                                    , p_source_system_ref    => g_stg_tbl(i).source_system_ref
                                                    , p_batch_id             => p_batch_id
                                                    , p_exception_log        => NULL
                                                    , p_oracle_error_code    => NULL
                                                    , p_oracle_error_msg     => g_stg_tbl(i).error_message
                                                    );

         END IF;--If Return Status is 'S' 

       -- -----------------------------------------------
       -- Get the records in their respective table types
       -- -----------------------------------------------


          g_ctrl_id_tbl(i)          :=  g_stg_tbl(i).control_id;

          g_pro_flg_tbl(i)          :=  g_stg_tbl(i).process_flag;

          g_err_msg_tbl(i)          :=  g_stg_tbl(i).error_message;

          g_inv_itm_id_tbl(i)       :=  g_stg_tbl(i).inventory_item_id;

          g_ven_site_id_tbl(i)      :=  g_stg_tbl(i).vendor_site_id;

          g_org_id_tbl(i)           :=  g_stg_tbl(i).org_id;

          g_agent_id_tbl(i)         :=  g_stg_tbl(i).agent_id;




   END LOOP;

       -- ------------------------------------------------
       -- Bulk Update the table with the validated results
       -- ------------------------------------------------

       FORALL i IN g_stg_tbl.FIRST..g_stg_tbl.LAST

          UPDATE xx_od_po_quotation_stg

          SET  process_flag      =  g_pro_flg_tbl(i)

              ,error_message     =  g_err_msg_tbl(i)

              ,inventory_item_id =  g_inv_itm_id_tbl(i)

              ,vendor_site_id    =  g_ven_site_id_tbl(i)

              ,org_id            =  g_org_id_tbl(i)

              ,agent_id          =  g_agent_id_tbl(i)

          WHERE  control_id      =  g_ctrl_id_tbl(i);

EXCEPTION

   WHEN OTHERS THEN

      x_return_status :='E';

      x_return_msg    :='When Others Exception in  Validate_records SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM;

      display_log(x_return_msg);   

END VALIDATE_PROCESS_RECORDS;

-- +====================================================================+
-- | Name        : process_po                                           |
-- | Description : This procedure is invoked from the main procedure.   |
-- |               This procedure will submit the standard 'Import Price|
-- |               Catalog' concurrent to populate the EBS base tables. |
-- |                                                                    |
-- | In Parameters  :    p_batch_id                                     |
-- | Out Parameters :    x_errbuf                                       |
-- |                     x_retcode                                      |
-- |                                                                    |
-- +====================================================================+
PROCEDURE  process_po(
                      x_errbuf         OUT    VARCHAR2
                    , x_retcode        OUT    NUMBER
                    , p_batch_id       IN     NUMBER
                     )
IS
--
--  Local Variable Declaration
--
lt_conc_request_id  FND_CONCURRENT_REQUESTS.request_id%TYPE;
lb_wait                     BOOLEAN;
EX_SUBMIT_FAIL              EXCEPTION;
EX_NORMAL_COMPLETION_FAIL   EXCEPTION;
lv_phase                    VARCHAR2(50);
lv_status                   VARCHAR2(50);
lv_dev_phase                VARCHAR2(50); 
lv_dev_status               VARCHAR2(50); 
lv_message                  VARCHAR2(1000);

BEGIN
   --
   -- Submitting Standard Purchase Order Import concurrent program
   --
   display_log('p_batch_id in req'||p_batch_id);
   lt_conc_request_id := FND_REQUEST.submit_request(
                                                   application   => 'PO'
                                                  ,program       => 'POXPDOI'
                                                  ,description   => 'Importing Price Catalogs (Blanket and Quotation) Program'
                                                  ,start_time    => NULL
                                                  ,sub_request   => FALSE -- FALSE means is not a sub request
                                                  ,argument1     => NULL --Default Buyer
                                                  ,argument2     => 'Quotation'-- Document Type
                                                  ,argument3     => 'Catalog'-- Document  SubType
                                                  ,argument4     => 'N'--Create or Update  Items
                                                  ,argument5     => 'N' -- Create Sourcing Rules
                                                  ,argument6     => 'Approved'--Approval Status
                                                  ,argument7     => NULL--Release Generation Method
                                                  ,argument8     => p_batch_id
                                                  ,argument9     => NULL
                                                  ,argument10    => NULL 
                                                  --,argument8     => p_batch_id--Batch Id
                                                  --,argument9     => Operating_Unit
                                                  --,argument10    => NULL --Global Agreement
                                                   );

     IF lt_conc_request_id = 0 THEN                                                                               
       x_errbuf  := FND_MESSAGE.GET;                                                                             
       display_log('Standard Import Price Catalog program failed to submit: ' || x_errbuf);                      
       RAISE EX_SUBMIT_FAIL;                                                                                    
    ELSE                                                                                                         
       COMMIT;                                                                                                   
       display_log('Submitted Standard Import Price Catalog program Successfully : '|| lt_conc_request_id );     
       
    END IF;                                                                                                      

                  
                  
                  
    lb_wait := fnd_concurrent.wait_for_request(   request_id  => lt_conc_request_id
                                                 ,interval    => 20
                                                 ,phase       => lv_phase
                                                 ,status      => lv_status
                                                 ,dev_phase   => lv_dev_phase
                                                 ,dev_status  => lv_dev_status
                                                 ,message     => lv_message
                                               );

               IF ((lv_dev_phase = 'COMPLETE') AND (lv_dev_status = 'NORMAL')) THEN
                  
                  display_log('Submitted Standard Import Price Catalog program Successfully Completed: '||lt_conc_request_id||'completed with normal status');  

               ELSE
                  
                   display_log('Standard Import Price Catalog program with request id:'||lt_conc_request_id||'did not complete with normal status');
                   RAISE EX_NORMAL_COMPLETION_FAIL;

               END IF;
                     
  
  
  

EXCEPTION
    WHEN EX_SUBMIT_FAIL THEN
       x_retcode := 2;
       x_errbuf  := 'Standard Import Price Catalog program failed to submit: ' || x_errbuf;
    WHEN EX_NORMAL_COMPLETION_FAIL THEN
       x_retcode := 2;                                                                         
       x_errbuf  := 'Standard Import Price Catalog program failed to Complete Normally' || x_errbuf;    

    WHEN OTHERS THEN
       x_errbuf  := 'Unexpected Exception is raised in Procedure PROCESS_PO '||substr(SQLERRM,1,200);
       x_retcode := 2;
END process_po;           

-- +===================================================================+
-- | Name       :  main                                                |
-- |                                                                   |
-- | Description:  This Procedure picks the records from the staging   |
-- |               table for belonging to that batch,validates them and| 
-- |               processes them  by calling custom API to import the |
-- |               the records to EBS tables.                          |
-- |                                                                   |
-- | In Parameters : p_validate_only_flag                              | 
-- |                 p_reset_status_flag                               | 
-- |                 p_batch_id                                        |
-- |                                                                   |
-- | Out Parameters :x_errbuf                                          |
-- |                 x_retcode                                         |
-- +===================================================================+

PROCEDURE main
             (
               x_errbuf              OUT VARCHAR2
             , x_retcode             OUT NUMBER            
             , p_validate_only_flag  IN VARCHAR2
             , p_reset_status_flag   IN VARCHAR2
             , p_batch_id            IN NUMBER
             )
IS

-- --------------------------
-- Local Variable Declaration
-- -------------------------- 

ln_excpn_request_id            NUMBER;
lv_retcode                     NUMBER;
ln_request_id                  NUMBER;
ln_val_failed                  NUMBER;
ln_proc_success                NUMBER;
ln_proc_failed                 NUMBER;
ln_new_rec_cnt                 NUMBER;
ln_master_request_id           NUMBER;
lc_return_msg                  VARCHAR2(1000);
lv_errbuf                      VARCHAR2(1000);
lc_return_status               VARCHAR2(1);
x_return_status                VARCHAR2(1);
EX_ENTRY_EXCEP                 EXCEPTION;
EX_PROCESS_PO_ERROR            EXCEPTION;


CURSOR lcu_bat_control_id
IS
SELECT control_id
FROM   xx_od_po_quotation_stg XOPQS
WHERE  XOPQS.load_batch_id = p_batch_id
AND    XOPQS.process_flag = 4;

CURSOR lcu_ready_for_proc_rec                     
IS                                       
SELECT *                                 
FROM   xx_od_po_quotation_stg XOPQS      
WHERE  XOPQS.process_flag = 5
AND    XOPQS.load_batch_id = p_batch_id ;


--
-- Cursor to fetch the Header records for a PO's which got successfully created in EBS tables.
--
CURSOR lcu_success_hdr_data
IS
SELECT SUBSTR(interface_source_code,7)
FROM   po_headers_interface POI
WHERE  POI.process_code = 'ACCEPTED'
AND    POI.interface_source_code LIKE 'C0301%'
AND    POI.batch_id = p_batch_id;
                                                          
--
-- Cursor to fetch the Header records for a PO's which got rejected .
--
CURSOR lcu_unsuccess_hdr_data
IS      
SELECT SUBSTR(interface_source_code,7)
FROM   po_headers_interface POI
WHERE  POI.process_code = 'REJECTED'
AND    POI.interface_source_code LIKE 'C0301%'
AND    POI.batch_id = p_batch_id;
 

BEGIN

   -- ------------------------------------
   -- Get the conversion_id and batch size
   -- ------------------------------------

   get_conversion_id
                   (
                    x_conversion_id => gn_conversion_id
                   ,x_batch_size    => gn_batch_size
                   ,x_max_threads   => gn_max_child_req
                   ,x_return_status => lc_return_status
                   );

   IF lc_return_status = 'S' THEN

      -- --------------------------------------------------
      -- Get the count of new records based on the batch_id
      -- --------------------------------------------------
      
      SELECT  COUNT(1)
      INTO    ln_new_rec_cnt
      FROM    xx_od_po_quotation_stg XOPQS
      WHERE   XOPQS.process_flag <> 7
      AND     XOPQS.load_batch_id = p_batch_id;
      
      IF ln_new_rec_cnt > 0 THEN
      
       -- ------------------------------------------------------------------
       -- Perform the validations by calling  the VALIDATE_RECORDS procedure
       -- ------------------------------------------------------------------
      
          VALIDATE_PROCESS_RECORDS
                                (
                                  x_return_status
                                , lc_return_msg
                                , p_batch_id
                                , p_validate_only_flag
                                );                                                                        
           
                      
           IF NVL(p_validate_only_flag,'N') ='N'  THEN
                  
             OPEN  lcu_bat_control_id;
             FETCH lcu_bat_control_id BULK COLLECT INTO g_bat_control_id_tbl;
             CLOSE lcu_bat_control_id;
              
             FORALL i IN 1 .. g_bat_control_id_tbl.LAST
             UPDATE xx_od_po_quotation_stg XOPQS
             SET    XOPQS.process_flag = 5
             WHERE  XOPQS.control_id = g_bat_control_id_tbl(i);
             COMMIT;
          
             OPEN  lcu_ready_for_proc_rec;                                            
             FETCH lcu_ready_for_proc_rec BULK COLLECT INTO g_ready_for_proc_tbl;        
             CLOSE lcu_ready_for_proc_rec;                                            
                                                                  
             IF g_ready_for_proc_tbl.COUNT > 0 THEN 
                
                FOR i IN g_ready_for_proc_tbl.FIRST .. g_ready_for_proc_tbl.LAST    
                LOOP  
                
                BEGIN                      
                                                    
                qty_price_tbl.DELETE;

                qty_price_tbl(1).quantity:= g_ready_for_proc_tbl(i).Tier1_qty;
                qty_price_tbl(1).price:= g_ready_for_proc_tbl(i).Tier1_cost;
                qty_price_tbl(2).quantity:= g_ready_for_proc_tbl(i).Tier2_qty;
                qty_price_tbl(2).price:= g_ready_for_proc_tbl(i).Tier2_cost;
                qty_price_tbl(3).quantity:= g_ready_for_proc_tbl(i).Tier3_qty;
                qty_price_tbl(3).price:= g_ready_for_proc_tbl(i).Tier3_cost;
                qty_price_tbl(4).quantity:=g_ready_for_proc_tbl(i).Tier4_qty;
                qty_price_tbl(4).price:= g_ready_for_proc_tbl(i).Tier4_cost;
                qty_price_tbl(5).quantity:= g_ready_for_proc_tbl(i).Tier5_qty;
                qty_price_tbl(5).price:= g_ready_for_proc_tbl(i).Tier5_cost;
                qty_price_tbl(6).quantity:= g_ready_for_proc_tbl(i).Tier6_qty;
                qty_price_tbl(6).price:= g_ready_for_proc_tbl(i).Tier6_cost;
                
             --
             -- Insert all the eligibile records which are having process_flag = 5 ("Processing In Progress") into PO Headers interface table
             --
                                    
                INSERT INTO po_headers_interface(
                                                 INTERFACE_HEADER_ID --Unique ID   
                                                ,INTERFACE_SOURCE_CODE
                                                ,PROCESS_CODE
                                                ,BATCH_ID
                                                ,ACTION 
                                                ,DOCUMENT_TYPE_CODE
                                                ,DOCUMENT_SUBTYPE
                                                ,CURRENCY_CODE
                                                ,AGENT_ID
                                                ,VENDOR_ID
                                                ,VENDOR_SITE_ID
                                                ,ORG_ID
                                                ,QUOTE_WARNING_DELAY                                                 
                                                ,ATTRIBUTE1
                                                ,APPROVED_DATE
                                                ,EFFECTIVE_DATE
                                                ,CREATION_DATE
                                                ,CREATED_BY
                                                ,LAST_UPDATE_DATE
                                                ,LAST_UPDATED_BY 
                                                ,LAST_UPDATE_LOGIN

                                                 )
                                     VALUES(
                                                 PO_HEADERS_INTERFACE_S.nextval 
                                                 ,'C0301-'||g_ready_for_proc_tbl(i).control_id--'C0301_PurchasePriceFromRMS'
                                                 ,'PENDING'
                                                 ,p_batch_id
                                                 ,'ORIGINAL'
                                                 ,'QUOTATION'
                                                 ,'CATALOG'
                                                 ,g_ready_for_proc_tbl(i).currency_cd
                                                 ,g_ready_for_proc_tbl(i).agent_id
                                                 ,g_ready_for_proc_tbl(i).vendor_id
                                                 ,g_ready_for_proc_tbl(i).vendor_site_id
                                                 ,g_ready_for_proc_tbl(i).org_id
                                                 ,0                                            
                                                 ,g_ready_for_proc_tbl(i).price_protect_flg 
                                                 ,g_ready_for_proc_tbl(i).active_date
                                                 ,g_ready_for_proc_tbl(i).real_eff_date
                                                 ,g_ready_for_proc_tbl(i).creation_date
                                                 ,g_ready_for_proc_tbl(i).created_by
                                                 ,g_ready_for_proc_tbl(i).last_update_date
                                                 ,g_ready_for_proc_tbl(i).last_updated_by 
                                                 ,g_ready_for_proc_tbl(i).last_update_login
                                                  );
                                           
             EXCEPTION
             WHEN OTHERS THEN
               display_log('When OTHERS error while inserting data into PO Headers interface table');
               x_retcode := 2;
             END;

             --
             -- Insert all the eligibile records which are having process_flag = 5 ("Processing In Progress") into PO Lines interface table
             --
             
             FOR no_of_price_breaks IN 1..6
             LOOP
                BEGIN 
                 IF qty_price_tbl(no_of_price_breaks).quantity IS NOT NULL
                   AND qty_price_tbl(no_of_price_breaks).price IS NOT NULL  THEN
                                     

                    INSERT INTO po_lines_interface(
                                              INTERFACE_LINE_ID     --*
                                            , INTERFACE_HEADER_ID   --*
                                            , ACTION
                                            , LINE_NUM                                      
                                            , SHIPMENT_NUM --Starts with 1,increments for each price break by 1. 
                                            , LINE_TYPE
                                            , ITEM
                                            , ITEM_ID                                                                                                                           
                                            , QUANTITY
                                            , UNIT_PRICE
                                            , SHIPMENT_TYPE
                                            , LINE_ATTRIBUTE1 
                                            , CREATION_DATE
                                            , CREATED_BY
                                            , LAST_UPDATE_DATE
                                            , LAST_UPDATED_BY 
                                            , LAST_UPDATE_LOGIN                                                               
                                            )
                                    VALUES(
                                              PO_LINES_INTERFACE_S.nextval
                                            , PO_HEADERS_INTERFACE_S.currval
                                            , 'ORIGINAL'
                                            , 1
                                            , no_of_price_breaks--Starts with 1,increments for each price break by 1.                                           
                                            , 'Goods'
                                            , g_ready_for_proc_tbl(i).sku
                                            , g_ready_for_proc_tbl(i).inventory_item_id   
                                            , qty_price_tbl(no_of_price_breaks).quantity
                                            , qty_price_tbl(no_of_price_breaks).price
                                            , 'QUOTATION'
                                            , g_ready_for_proc_tbl(i).total_cost                                              
                                            , g_ready_for_proc_tbl(i).creation_date  
                                            , g_ready_for_proc_tbl(i).created_by  
                                            , g_ready_for_proc_tbl(i).last_update_date  
                                            , g_ready_for_proc_tbl(i).last_updated_by   
                                            , g_ready_for_proc_tbl(i).last_update_login  
                                             );

                 END IF;
           EXCEPTION
         WHEN OTHERS THEN
           display_log('When OTHERS error while inserting data into PO lines interface table');
           x_retcode := 2;           
         END;

         END LOOP;          
        
         COMMIT;

         END LOOP;--header loop
         COMMIT;
         
        END IF; --g_ready_for_proc_tbl.COUNT > 0  
        
        
        END IF; --NVL(p_validate_only_flag,'N') ='N'
     
           --
           -- Calling Process_po procedure to insert data in interface table and to submit Standard Import Price Catalog concurrent program.
           --
           process_po(
                       x_errbuf    => lv_errbuf
                      ,x_retcode   => lv_retcode
                      ,p_batch_id  => p_batch_id
                      );
          
           IF lv_retcode <> 0 THEN
              x_errbuf := lv_errbuf;
              display_log('Error in Calling Process_PO procedure :- ');
              RAISE EX_PROCESS_PO_ERROR;
           END IF;
           
           --
           -- Header level cursor for the successful PO Quotation staging table
           --
           OPEN  lcu_success_hdr_data;
           FETCH lcu_success_hdr_data BULK COLLECT INTO g_success_po_hdr_tbl;
           CLOSE lcu_success_hdr_data;
                    
           --
           -- Updating Header Staging table with Process_flag to 7 for all those Quotations which got ACCEPTED in EBS.
           --
           FORALL i IN g_success_po_hdr_tbl.FIRST..g_success_po_hdr_tbl.LAST
           UPDATE  xx_od_po_quotation_stg 
           SET     process_flag    = 7
           WHERE   control_id = g_success_po_hdr_tbl(i);          
           COMMIT; 
                     
           --
           -- Header level cursor for the unsuccessful PO Quotation staging table  
           --
           OPEN  lcu_unsuccess_hdr_data;
           FETCH lcu_unsuccess_hdr_data BULK COLLECT INTO g_unsuccess_po_hdr_tbl;
           CLOSE lcu_unsuccess_hdr_data;         
          
           --
           -- Updating Header Staging table with Process_flag to 6 for all those PO's which got REJECTED in EBS.
           --
           FORALL i IN g_unsuccess_po_hdr_tbl.FIRST..g_unsuccess_po_hdr_tbl.LAST          
           UPDATE  xx_od_po_quotation_stg XOPQS
           SET     XOPQS.process_flag  = 6
           WHERE   XOPQS.control_id = g_unsuccess_po_hdr_tbl(i);       
         
           COMMIT;
                    
        
           -- ----------------------------------
          -- Get the validation failed records
          -- ----------------------------------
          
          SELECT COUNT(1)
          INTO   ln_val_failed
          FROM   xx_od_po_quotation_stg
          WHERE  load_batch_id = p_batch_id
          AND    process_flag = 3;
          
          -- --------------------------------------
          -- Get the successfully processed records
          -- --------------------------------------
          
          SELECT COUNT(1)
          INTO   ln_proc_success
          FROM   xx_od_po_quotation_stg
          WHERE  load_batch_id = p_batch_id
          AND    process_flag  = 7;
          
          -- ---------------------------------
          -- Get the processing failed records
          -- ---------------------------------
          
          SELECT COUNT(1)
          INTO   ln_proc_failed
          FROM   xx_od_po_quotation_stg
          WHERE  load_batch_id = p_batch_id
          AND    process_flag = 6;
          
          -- ------------------------------------------------------------------------------------------------
          -- Gets the master request Id which needs to be passed while updating Control Information Log Table
          -- ------------------------------------------------------------------------------------------------
          
          get_master_request_id
                               (
                                p_conversion_id     => gn_conversion_id
                               ,p_batch_id          => p_batch_id
                               ,x_master_request_id => ln_master_request_id
                               );
          
          ---------------------------------------------------------------------------------------------
          -- XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc is called over
          -- to log the exception of the record while processing
          ---------------------------------------------------------------------------------------------
          
          XX_COM_CONV_ELEMENTS_PKG.upd_control_info_proc
                                                       (
                                                         p_conc_mst_req_id             => ln_master_request_id
                                                       , p_batch_id                    => p_batch_id
                                                       , p_conversion_id               => gn_conversion_id
                                                       , p_num_bus_objs_failed_valid   => ln_val_failed
                                                       , p_num_bus_objs_failed_process => ln_proc_failed
                                                       , p_num_bus_objs_succ_process   => ln_proc_success
                                                       );
          
              --------------------------------------------------------------------------------------------
              -- To launch the Exception Log Report for this batch
              --------------------------------------------------------------------------------------------
          
                  launch_exception_report(
                                          p_batch_id
                                         ,x_errbuf
                                         ,x_retcode
                                         );
                    
          display_out('====================================================================================');
          display_out(RPAD('Total no Of Puchase Price Header Records                     :',70)||ln_new_rec_cnt);
          display_out(RPAD('Total no Of Puchase Price Header Records failed in validation:',70)||ln_val_failed);
          display_out(RPAD('Total no Of Puchase Price Header Records Processed           :',70)||ln_proc_success);
          display_out(RPAD('Total no Of Puchase Price Header Records Errored             :',70)||ln_proc_failed);
          display_out('====================================================================================');
          
       ELSE

         display_log('No records in staging with status as Validation in progress');

      END IF;--If ln_new_rec_cnt > 0 

   ELSE

       RAISE EX_ENTRY_EXCEP;

   END IF;--If lc_return_status ='S'

EXCEPTION

   WHEN EX_PROCESS_PO_ERROR THEN
    x_errbuf  := 'Unexpected Exception is raised while calling Procedure PROCESS_PO ';
    x_retcode := 2;  

WHEN EX_ENTRY_EXCEP THEN

     x_retcode := 2;

     display_log('There is no entry in the table XX_COM_CONVERSIONS_CONV for the conversion_code '||gc_conversion_code);

WHEN NO_DATA_FOUND THEN

     x_retcode := 2;

     x_errbuf  := ('When No_data_Found  Exception in  Main SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);

     display_log(x_errbuf);

WHEN OTHERS THEN
     x_retcode := 2;

     x_errbuf  := ('When Others Exception in  Main SQLCODE  : ' || SQLCODE || ' SQLERRM  : ' || SQLERRM);

     display_log(x_errbuf);

END main;


-- +====================================================================+
-- | Name        :  batch_main                                          |
-- | Description :  This procedure is invoked from the OD: PO Quotations|
-- |                Conversion Master Concurrent Request.This would     |
-- |                submit child programs based on batch_size           |
-- |                                                                    |
-- | Parameters  :  p_validate_only_flag                                |
-- |                p_reset_status_flag                                 |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- +====================================================================+

PROCEDURE batch_main(
                     x_errbuf             OUT VARCHAR2
                    ,x_retcode            OUT NUMBER                   
                    ,p_validate_only_flag IN  VARCHAR2
                    ,p_reset_status_flag  IN  VARCHAR2
                    )
IS

-- --------------------------
-- Local Variable Declaration
-- --------------------------

lc_request_data    VARCHAR2(1000);
lc_error_message   VARCHAR2(4000);
ln_return_status   NUMBER;
EX_SUB_REQ_ERROR   EXCEPTION;

BEGIN

   lc_request_data := FND_CONC_GLOBAL.request_data;

   gt_request_id := FND_GLOBAL.CONC_REQUEST_ID;

   IF lc_request_data IS NULL THEN

      submit_sub_requests
                        (
                         p_validate_only_flag
                        ,p_reset_status_flag
                        ,lc_error_message
                        ,ln_return_status
                         );

      IF ln_return_status <> 0 THEN

         x_errbuf := lc_error_message;
         display_log('Error in submit_sub_requests :- ');
         display_log(lc_error_message );
         RAISE EX_SUB_REQ_ERROR;

      END IF;

   END IF;

EXCEPTION

  WHEN EX_SUB_REQ_ERROR THEN
       x_retcode := 2;

  WHEN NO_DATA_FOUND THEN
       x_retcode := 2;
       display_log('No Data Found to continue');

  WHEN OTHERS THEN
       x_retcode := 2;
       x_errbuf  := 'Unexpected error in main procedure - '||SQLERRM;
       display_log('Unexpected error in main procedure - '||SUBSTR(SQLERRM,1,150));
END batch_main;

END XX_PO_QUOTS_IMP_PKG;
/  
SHOW ERRORS;
EXIT;



