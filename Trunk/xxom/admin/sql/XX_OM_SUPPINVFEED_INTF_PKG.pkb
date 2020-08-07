SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_SUPPINVFEED_INTF_PKG
-- +===================================================================+
-- | Name  :    XX_OM_SUPPINVFEED_INTF_PKG                             |
-- | RICE ID :  I1186                                                  |
-- | Description      : This package contains the following            |
-- |                    procedures                                     |
-- |                    1)  PROCESS_FEED_MASTER                        |
-- |                        Read feed from work table and notifies     |
-- |                        supply management team about the suppliers |
-- |                        who did not send feed and checks if the    |
-- |                        supplier is active and then spawns the     |
-- |                        child concurrent program for those active  |
-- |                        suppliers                                  |
-- |                                                                   |
-- |                    2)  PROCESS_FEED_CHILD                         |
-- |                        Perform ITEM,UOM,VPC validatiions,         |
-- |                        decrement quantity,calculate available to  |
-- |                        resreve and update/insert data into the    |
-- |                        production table                           |
-- |                                                                   |
-- |                    3)  PURGE_WORKTABLE_SKUS                       |
-- |                        Purges successfully processed records from |
-- |                        work table and error records if they have  |
-- |                        threshold days                             |
-- |                                                                   |
-- |                    4)  PURGE_INACTIVE_PROD_SKUS                   |
-- |                        Purges inactive SKUs from production table |
-- |                        based on the threshold days                |
-- |                                                                   |
-- |                    5)  SYNC_ONHOLD_QTY                            |
-- |                        Synchronizes on hold quantity in production|
-- |                        table and sales order tables               |
-- |                                                                   |
-- |                    6)  WRITE_LOG                                  |
-- |                        This procedure is used to write into       |
-- |                        the log file                               |
-- |                                                                   |
-- |                    7)  STRIP_CHAR                                 |
-- |                        Strips non alpha numeric characters from   |
-- |                        the given string                           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       06-July-07  Aravind A.       Initial Version             |
-- +===================================================================+
AS
-- +===================================================================+
-- | Following are the Global parameters that are used                 |
-- | across this package                                               |
-- +===================================================================+

gc_exp_header       xx_om_global_exceptions.exception_header%TYPE  DEFAULT  'OTHERS';
gc_track_code       xx_om_global_exceptions.track_code%TYPE        DEFAULT  'OTC';
gc_sol_domain       xx_om_global_exceptions.solution_domain%TYPE   DEFAULT  'Sourcing';
gc_function         xx_om_global_exceptions.function_name%TYPE     DEFAULT  'I1186_SupplierInventoryFeed';
gc_sup_mgmt_team    fnd_flex_value_sets.flex_value_set_name%TYPE   DEFAULT  'XX_OM_SUPP_MGMT_TEAM';
gc_purge_profile    fnd_profile_options.profile_option_name%TYPE   DEFAULT  'XX_OM_SUPP_INV_PURGE';
gc_hold_lookup      fnd_lookup_values.lookup_type%TYPE             DEFAULT  'XX_OM_SUPP_INV_HOLDS';
gc_debug_flag       VARCHAR2(1)                                    DEFAULT  'Y';
gc_master_org       mtl_parameters.organization_id%TYPE            DEFAULT  oe_sys_parameters.VALUE('MASTER_ORGANIZATION_ID');

-- +===================================================================+
-- | Name  : PROCESS_FEED_MASTER                                       |
-- | Description   : Read feed from work table and notifies            |
-- |                 supply management team about the suppliers        |
-- |                 who did not send feed and checks if the           |
-- |                 supplier is active and then spawns the            |
-- |                 child concurrent program for those active         |
-- |                 suppliers                                         |
-- |                                                                   |
-- | Parameters :      NONE                                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_FEED_MASTER(
                              x_errbuff                OUT NOCOPY VARCHAR2
                              ,x_retcode               OUT NOCOPY VARCHAR2
                              ,p_debug_flag            IN           VARCHAR2      DEFAULT 'N'
                             )
IS

   err_report_type           xx_om_report_exception_t;

   lc_valid_supplier         VARCHAR2(1);
   lc_err_code               xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc               xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref             xx_om_global_exceptions.entity_ref%TYPE;
   lc_err_buf                VARCHAR2(240);
   lc_ret_code               VARCHAR2(30);
   lc_notif_flag             VARCHAR2(1) DEFAULT 'N';
   lc_sup_mgmt_notif         VARCHAR2(4000);
   lc_hdr_valid              VARCHAR2(1);
   lc_notif_sub              VARCHAR2(1000);
   lc_notif_body             VARCHAR2(1000);
   lc_msg_type               fnd_new_messages.type%TYPE;
   lc_alert_category         fnd_new_messages.category%TYPE;
   lc_alert_severity         fnd_new_messages.severity%TYPE;

   ln_request_id             NUMBER;
   ln_nid                    NUMBER;
   ln_supplier_id            xx_om_supplier_invfeed_hdr_int.supplier_id%TYPE;
   ln_sup_count              NUMBER         DEFAULT 0;
   ln_msg_num                fnd_new_messages.message_number%TYPE;
   ln_log_severity           fnd_new_messages.fnd_log_severity%TYPE;

   TYPE supplier_name_type   IS TABLE OF po_vendors.vendor_name%TYPE;
   TYPE supplier_num_type    IS TABLE OF xx_om_supplier_invfeed_hdr_int.supplier_number%TYPE;
   TYPE vendor_num_type      IS TABLE OF xx_om_supplier_invfeed_hdr_int.vendor_number%TYPE;
   TYPE vendor_site_type     IS TABLE OF xx_om_supplier_invfeed_hdr_int.vendor_site_id%TYPE;

   TYPE item_num_type        IS TABLE OF xx_om_supplier_invfeed_txn_int.item_number%TYPE;
   TYPE vpc_code_type        IS TABLE OF xx_om_supplier_invfeed_txn_int.vpc_code%TYPE;

   lt_supplier_name          supplier_name_type;
   lt_supplier_num           supplier_num_type;
   lt_vendor_num             vendor_num_type;
   lt_vendor_site_id         vendor_site_type;
   lt_item_num               item_num_type;
   lt_vpc_code               vpc_code_type;

   -- get suppliers that have uploaded a file
   CURSOR lcu_sup_exist
   IS
      SELECT XOSIP.supplier_name
             ,XOSIHI.supplier_id
             ,XOSIHI.ROWID
             ,XOSIHI.supplier_number
             ,XOSIHI.vendor_number
      FROM xx_om_supplier_invfeed_hdr_int XOSIHI
           ,xx_om_supplier_invfeed_percent XOSIP
      WHERE XOSIHI.vendor_number = XOSIP.supplier_number(+)
      AND XOSIHI.status IS NULL
      ORDER BY XOSIHI.last_update_date;             --Order by last update date to ensure processing of old feed first

   -- get suppliers that have sent files previously but did not for this load
   CURSOR lcu_sup_not_exist
   IS
      SELECT XOSIP.supplier_name
             ,XOSIP.supplier_id
      FROM xx_om_supplier_invfeed_percent XOSIP
      WHERE XOSIP.supplier_number NOT IN (
                                         SELECT XOSIHI.vendor_number
                                         FROM xx_om_supplier_invfeed_hdr_int XOSIHI
                                         WHERE XOSIHI.status IS NULL
                                         );

   -- retrieve members of supplier team to be sent a message 
   CURSOR lcu_sup_mgmt_team
   IS
      SELECT FFV.flex_value
      FROM fnd_flex_values FFV
           ,fnd_flex_value_sets FFVS
      WHERE  FFV.flex_value_set_id = FFVS.flex_value_set_id
      AND FFV.enabled_flag = 'Y'
      AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(FFV.start_date_active,SYSDATE)) AND TRUNC(NVL(FFV.end_date_active,SYSDATE))
      AND FFVS.flex_value_set_name = gc_sup_mgmt_team;

BEGIN
   gc_debug_flag := p_debug_flag;

   FND_MESSAGE.SET_NAME('XXOM','XX_OM_SUPINV_0015_NOTIF_BOD');
   FND_MESSAGE.GET_MESSAGE_INTERNAL(
                                    appin             =>   'XXOM'
                                    ,namein           =>   'XX_OM_SUPINV_0015_NOTIF_BOD'
                                    ,langin           =>   USERENV('LANG')
                                    ,auto_log         =>   'Y'
                                    ,msg              =>   lc_notif_body
                                    ,msg_number       =>   ln_msg_num
                                    ,msg_type         =>   lc_msg_type
                                    ,fnd_log_severity =>   ln_log_severity
                                    ,alert_category   =>   lc_alert_category
                                    ,alert_severity   =>   lc_alert_severity
                                   );

   lc_sup_mgmt_notif := CHR(10)||CHR(10)||lc_notif_body||'  '||TO_CHAR(SYSDATE,'DD-MON-YYYY , hh:mi:ss')||CHR(10)||CHR(10)||'Supplier Names'||CHR(10)||CHR(10);

   BEGIN
   
      --locate suppliers who have not been loaded but a file exists

      SELECT 
            PV.segment1
            ,XOSIHI.supplier_number
            ,s.vendor_site_id
      BULK COLLECT INTO lt_vendor_num
                        ,lt_supplier_num
                        ,lt_vendor_site_id
      FROM 
            po_vendors PV
           ,po_vendor_sites_all s
           ,xx_om_supplier_invfeed_hdr_int XOSIHI
      WHERE 
            TO_NUMBER(XOSIHI.supplier_number) = s.vendor_site_id
        AND s.purchasing_site_flag = 'Y'
        AND pv.vendor_id = s.vendor_id
        AND XOSIHI.status IS NULL;

      -- update the interface hdr table with the supplier name if null
      FORALL i IN lt_supplier_num.FIRST..lt_supplier_num.LAST
         UPDATE 
            xx_om_supplier_invfeed_hdr_int
         SET 
            vendor_number = lt_vendor_num(i) 
            ,vendor_site_id = lt_vendor_site_id(i)
            ,created_by = FND_GLOBAL.USER_ID
            ,creation_date = SYSDATE
            ,last_updated_by = FND_GLOBAL.USER_ID
            ,last_update_date = SYSDATE
            ,last_update_login = FND_GLOBAL.LOGIN_ID
         WHERE supplier_number = lt_supplier_num(i)
         AND vendor_number IS NULL
         AND status IS NULL;

   END;

   WRITE_LOG('Processing non existent suppliers',gc_debug_flag);

   -- loop through the suppliers that have not sent a new file to be loaded
   -- load all of these into local vars
   FOR sup_not_exist_rec IN lcu_sup_not_exist
   LOOP
      ln_supplier_id := sup_not_exist_rec.supplier_id;
      lc_notif_flag := 'Y';
      ln_sup_count := ln_sup_count + 1;
      lc_sup_mgmt_notif := lc_sup_mgmt_notif||' '||ln_sup_count||'. '||sup_not_exist_rec.supplier_name||CHR(10)||CHR(13);
   END LOOP;

   WRITE_LOG('End of processing non existent suppliers',gc_debug_flag);

   -- send a workflow message to supplier team members. The message contains all suppliers
   IF (lc_notif_flag = 'Y') THEN

      WRITE_LOG('Sending notification to Supplier Management Team',gc_debug_flag);

      FOR sup_mgmt_team_rec IN lcu_sup_mgmt_team
      LOOP
         ln_nid := WF_NOTIFICATION.SEND(
                                         role => sup_mgmt_team_rec.flex_value
                                         , msg_type => 'WFMAIL'
                                         , msg_name => 'O_OPEN_MAIL_FYI'
                                        );
         
         FND_MESSAGE.SET_NAME('XXOM','XX_OM_SUPINV_0014_NOTIF_SUB');
         FND_MESSAGE.GET_MESSAGE_INTERNAL(
                                          appin             =>   'XXOM'
                                          ,namein           =>   'XX_OM_SUPINV_0014_NOTIF_SUB'
                                          ,langin           =>   USERENV('LANG')
                                          ,auto_log         =>   'Y'
                                          ,msg              =>   lc_notif_sub
                                          ,msg_number       =>   ln_msg_num
                                          ,msg_type         =>   lc_msg_type
                                          ,fnd_log_severity =>   ln_log_severity
                                          ,alert_category   =>   lc_alert_category
                                          ,alert_severity   =>   lc_alert_severity
                                         );

         WF_NOTIFICATION.SETATTRTEXT(
                                      ln_nid
                                      , 'SUBJECT'
                                      , lc_notif_sub||TO_CHAR(SYSDATE,'DD-MON-YYYY , hh:mi:ss')
                                     );
         WF_NOTIFICATION.SETATTRTEXT(
                                      ln_nid
                                      , 'SENDER'
                                      , 'Supplier Inventory Feed'
                                      );
         WF_NOTIFICATION.SETATTRTEXT(
                                    ln_nid
                                    ,'BODY'
                                    ,lc_sup_mgmt_notif
                                    );
         WF_NOTIFICATION.DENORMALIZE_NOTIFICATION(
                                                  ln_nid
                                                  );
      END LOOP;

      WRITE_LOG('Notification sent to Supplier Management Team',gc_debug_flag);
   END IF;

   WRITE_LOG('Processing existent suppliers',gc_debug_flag);

   -- start to loop through suppliers that have sent a file to be loaded
   FOR sup_exist_rec IN lcu_sup_exist
   LOOP
      WRITE_LOG('Processing supplier  '||sup_exist_rec.supplier_name,gc_debug_flag);
      
      ln_supplier_id := sup_exist_rec.supplier_id;
      BEGIN
      
         -- validate the supplier is currently enabled and active
         SELECT 'Y'
         INTO lc_valid_supplier
         FROM po_vendors PV
         WHERE PV.segment1 = sup_exist_rec.vendor_number
         AND PV.enabled_flag = 'Y'
         AND TRUNC(SYSDATE) BETWEEN 
            TRUNC(NVL(PV.start_date_active,SYSDATE)) AND TRUNC(NVL(PV.end_date_active,SYSDATE));

         -- update the header interface table that the load will be run
         UPDATE xx_om_supplier_invfeed_hdr_int
         SET status = 'S'
             ,error_message = NULL
             ,last_updated_by = FND_GLOBAL.USER_ID
             ,last_update_date = SYSDATE
             ,last_update_login = FND_GLOBAL.LOGIN_ID
         WHERE ROWID = sup_exist_rec.ROWID;

      -- submit the child process to load the details for each supplier
      ln_request_id   :=   FND_REQUEST.SUBMIT_REQUEST(
                                                      application   =>   'xxom'
                                                      ,program      =>   'XXOMSUPINVFEEDCHILD'
                                                      ,argument1    =>   sup_exist_rec.vendor_number
                                                      ,argument2    =>   sup_exist_rec.supplier_id
                                                      ,argument3    =>   p_debug_flag
                                                     );
        IF (ln_request_id <= 0) THEN

            lc_err_code := 'XX_OM_SUPINV_0013_CONC_FAIL';
            FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0013_CONC_FAIL');
            FND_MESSAGE.SET_TOKEN('PROG_NAME','OD: OM Supplier Inventory Feed Child');
            lc_err_desc := FND_MESSAGE.GET;
            lc_entity_ref := 'Supplier ID';

            -- update the status with an error
            UPDATE 
                xx_om_supplier_invfeed_hdr_int
            SET 
                status = 'E'
                ,error_message = lc_err_desc
                ,last_updated_by = FND_GLOBAL.USER_ID
                ,last_update_date = SYSDATE
                ,last_update_login = FND_GLOBAL.LOGIN_ID
            WHERE 
                supplier_id = sup_exist_rec.supplier_id;

            err_report_type := xx_om_report_exception_t (
                                                   gc_exp_header
                                                   ,gc_track_code
                                                   ,gc_sol_domain
                                                   ,gc_function
                                                   ,lc_err_code
                                                   ,SUBSTR(lc_err_desc,1,1000)
                                                   ,lc_entity_ref
                                                   ,NVL(sup_exist_rec.supplier_id,0)
                                                  );
            XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                      err_report_type
                                                      ,lc_err_buf
                                                      ,lc_ret_code
                                                     );


        END IF;


      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            -- if the supplier was not active or the update failed throw the error
            -- attempt to update the header record and create a global exception
            lc_err_code := 'XX_OM_SUPINV_0006_SUP_INACTIVE';
            FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0006_SUP_INACTIVE');
            lc_err_desc := FND_MESSAGE.GET;
            lc_entity_ref := 'Supplier ID';

            -- update header with error status
            UPDATE xx_om_supplier_invfeed_hdr_int
            SET status = 'E'
                ,error_message = lc_err_desc
                ,last_updated_by = FND_GLOBAL.USER_ID
                ,last_update_date = SYSDATE
                ,last_update_login = FND_GLOBAL.LOGIN_ID
            WHERE ROWID = sup_exist_rec.ROWID;

            err_report_type :=
                            xx_om_report_exception_t (
                                                      gc_exp_header
                                                      ,gc_track_code
                                                      ,gc_sol_domain
                                                      ,gc_function
                                                      ,lc_err_code
                                                      ,SUBSTR(lc_err_desc,1,1000)
                                                      ,lc_entity_ref
                                                      ,NVL(sup_exist_rec.supplier_id,0)
                                                     );
            XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                         err_report_type
                                                         ,lc_err_buf
                                                         ,lc_ret_code
                                                        );
         WHEN TOO_MANY_ROWS THEN

            -- supplier has more than one record in the vedor table
            lc_err_code := 'XX_OM_SUPINV_0006_SUP_INACTIVE';
            FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0006_SUP_INACTIVE');
            lc_err_desc := FND_MESSAGE.GET;
            lc_entity_ref := 'Supplier ID';

            -- update the header with and error status
            UPDATE xx_om_supplier_invfeed_hdr_int
            SET status = 'E'
                ,error_message = lc_err_desc
                ,last_updated_by = FND_GLOBAL.USER_ID
                ,last_update_date = SYSDATE
                ,last_update_login = FND_GLOBAL.LOGIN_ID
            WHERE ROWID = sup_exist_rec.ROWID;

            err_report_type :=
                            xx_om_report_exception_t (
                                                      gc_exp_header
                                                      ,gc_track_code
                                                      ,gc_sol_domain
                                                      ,gc_function
                                                      ,lc_err_code
                                                      ,SUBSTR(lc_err_desc,1,1000)
                                                      ,lc_entity_ref
                                                      ,NVL(sup_exist_rec.supplier_id,0)
                                                     );
            XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                         err_report_type
                                                         ,lc_err_buf
                                                         ,lc_ret_code
                                                        );

      END;

   END LOOP;
   ---End of Supplier Loop

   COMMIT;  

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_err_desc   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_SUPINV_UNEXPECTED_ERROR1';
      lc_entity_ref := 'Supplier ID';

      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,NVL(ln_supplier_id,0)
                                               );
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );

END PROCESS_FEED_MASTER;

-- +===================================================================+
-- | Name  : PROCESS_FEED_CHILD                                        |
-- | Description   : Perform ITEM,UOM,VPC validatiions,                |
-- |                 decrement quantity,calculate available to         |
-- |                 resreve and update/insert data into the           |
-- |                 production table                                  |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :      p_supplier_name                                 |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PROCESS_FEED_CHILD(
                             x_errbuff                 OUT NOCOPY VARCHAR2
                             ,x_retcode                OUT NOCOPY VARCHAR2
                             ,p_supplier_number        IN           VARCHAR2
                             ,p_supplier_id            IN           NUMBER
                             ,p_debug_flag             IN           VARCHAR2    DEFAULT 'N'
                             )
IS
   EX_TXN_INVALID              EXCEPTION;

   err_report_type             xx_om_report_exception_t;

   lc_err_code                 xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc                 xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref               xx_om_global_exceptions.entity_ref%TYPE;
   lc_err_buf                  VARCHAR2(240);
   lc_ret_code                 VARCHAR2(30);
   lc_txn_valid                VARCHAR2(1)    DEFAULT 'N';
   lc_stripped_vpc             xx_om_supplier_invfeed_txn_int.vpc_code%TYPE;
   lc_txn_exists               VARCHAR2(1)    DEFAULT 'N';

   ln_on_hand_qty              xx_om_supplier_invfeed_txn_all.on_hand_qty%TYPE;
   ln_avb_reserve              xx_om_supplier_invfeed_txn_all.avb_reserve_qty%TYPE;
   ln_avb_res_qty              xx_om_supplier_invfeed_txn_all.avb_reserve_qty%TYPE;
   ln_on_hold_qty              xx_om_supplier_invfeed_txn_all.on_hold_qty%TYPE;
   ln_item_id                  mtl_system_items_b.inventory_item_id%TYPE;
   ln_request_id               NUMBER;
   ln_supplier_id              xx_om_supplier_invfeed_hdr_all.supplier_id%TYPE;

   lc_uom_code          mtl_system_items_b.primary_uom_code%TYPE;
   lc_item_number       mtl_system_items_b.segment1%TYPE;
   ln_count             NUMBER := 0;
   lc_all_item          mtl_system_items_b.segment1%TYPE;
   ln_all_hold_qty       xx_om_supplier_invfeed_txn_all.on_hold_qty%TYPE;
   
   NULL_PARAMETERS      EXCEPTION;

   -- cursor to select all of the items from the suppliers that have not been loaded 
   -- and supplier has been sent in to be processed
   CURSOR lcu_sup_txn_info (p_supp_id NUMBER
       --, p_all_supp_id NUMBER
       )
   IS
      SELECT ti.supplier_id
             ,hi.supplier_number
             ,hi.vendor_number
             ,hi.vendor_site_id
             ,ti.vpc_code
             ,ti.on_hand_qty
             ,ti.avb_reserve_qty
             ,ti.interface_status
             ,ti.error_message
             ,ip.avb_per_qty
             ,ti.ROWID
      FROM xx_om_supplier_invfeed_txn_int ti
           ,xx_om_supplier_invfeed_percent ip
           ,xx_om_supplier_invfeed_hdr_int hi
      WHERE 
            hi.supplier_id = ti.supplier_id
        AND hi.supplier_id = p_supp_id
        AND hi.status = 'S'
        AND hi.vendor_number = ip.supplier_number 
        AND ti.interface_status IS NULL;

   -- cursor to validate the item and get the existing txn row if it exists      
   CURSOR lcu_asl_item (p_vendor_site_id po_vendor_sites_all.vendor_site_id%TYPE
                       ,p_vpc_code xx_om_supplier_invfeed_txn_int.vpc_code%TYPE
                       ,p_supp_id xx_om_supplier_invfeed_hdr_all.supplier_id%TYPE)
   IS
      SELECT 
          MSIB.segment1
          ,msib.primary_uom_code
          ,pasl.item_id
          ,ta.item_number
          ,ta.on_hold_qty
      FROM 
          po_vendor_sites_all vs
          ,mtl_system_items_b MSIB
          ,po_approved_supplier_list PASL
          ,xx_om_supplier_invfeed_txn_all ta
      WHERE 
              MSIB.organization_id = gc_master_org
          AND PASL.using_organization_id = MSIB.organization_id
          AND vs.vendor_site_id = p_vendor_site_id
          AND vs.vendor_id = pasl.vendor_id
          AND pasl.vendor_site_id = vs.vendor_site_id
          AND pasl.item_id = MSIB.inventory_item_id
          AND pasl.primary_vendor_item = p_vpc_code
          AND NVL(PASL.disable_flag,'N') = 'N'
          AND NVL(PASL.asl_status_id,2) = 2
          AND MSIB.enabled_flag = 'Y'
          AND MSIB.inventory_item_status_code IN('A','Active')
          AND TRUNC(SYSDATE) BETWEEN 
                 TRUNC(NVL(MSIB.start_date_active,SYSDATE)) 
                 AND TRUNC(NVL(MSIB.end_date_active,SYSDATE))
          AND p_supp_id = TA.supplier_id(+)
          AND msib.segment1 = TA.item_number(+);

BEGIN

   --Processing the Transactions of the supplier
   gc_debug_flag := p_debug_flag;

   WRITE_LOG('         Validating Transactions         ',gc_debug_flag);
   
   IF p_supplier_number IS NULL OR
      p_supplier_id IS NULL THEN
      
      RAISE NULL_PARAMETERS;
      
   END IF;
   
 
   -- select the interface row if the prod one exists update it otherwise insert a new row
   MERGE INTO xx_om_supplier_invfeed_hdr_all XOSIHA
   USING (
       SELECT 
           pv.vendor_name supplier_name
           ,pv.vendor_id
           ,hi.vendor_number
           ,vs.org_id
           ,hi.vendor_site_id
       FROM 
           xx_om_supplier_invfeed_hdr_int hi
           ,po_vendor_sites_all vs
           ,po_vendors pv
       WHERE 
               hi.supplier_id = p_supplier_id
           AND hi.vendor_site_id = vs.vendor_site_id
           AND pv.vendor_id = vs.vendor_id
           AND status = 'S'
       ) XOSIHI
   ON (XOSIHA.vendor_site_id = XOSIHI.vendor_site_id)
   WHEN MATCHED THEN
       UPDATE 
       SET 
           supplier_name = XOSIHI.supplier_name
           ,last_updated_by = FND_GLOBAL.USER_ID
           ,last_update_date = SYSDATE
           ,last_update_login = FND_GLOBAL.LOGIN_ID
   WHEN NOT MATCHED THEN
       INSERT (
           XOSIHA.supplier_id, XOSIHA.supplier_name, XOSIHA.supplier_number,
           XOSIHA.org_id, XOSIHA.vendor_id, XOSIHA.vendor_site_id,XOSIHA.created_by, XOSIHA.creation_date, 
           XOSIHA.last_updated_by, XOSIHA.last_update_date, XOSIHA.last_update_login)
       VALUES (
           xx_om_supp_inv_hdr_all_s.NEXTVAL
           ,XOSIHI.supplier_name
           ,XOSIHI.vendor_number
           ,XOSIHI.org_id
           ,XOSIHI.vendor_id
           ,XOSIHI.vendor_site_id
           ,FND_GLOBAL.USER_ID
           ,SYSDATE
           ,FND_GLOBAL.USER_ID
           ,SYSDATE
           ,FND_GLOBAL.LOGIN_ID
       );

   WRITE_LOG('         Collecting Supplier ID value',gc_debug_flag);
            
   -- get the supplier_id to use for txn row write
   SELECT 
       ha.supplier_id
   INTO 
       ln_supplier_id
   FROM 
       xx_om_supplier_invfeed_hdr_all ha
       ,xx_om_supplier_invfeed_hdr_int hi
   WHERE 
       ha.vendor_site_id = hi.vendor_site_id
       AND hi.supplier_id = p_supplier_id;

   WRITE_LOG('         Supplier ID value collected '||ln_supplier_id,gc_debug_flag);

   FOR sup_txn_info_rec IN lcu_sup_txn_info(p_supplier_id)
   LOOP
      BEGIN

         --Stripping non alpha numeric characters from VPC codes
         lc_stripped_vpc := STRIP_CHAR(sup_txn_info_rec.vpc_code);

         WRITE_LOG('         Validating VPC/Item',gc_debug_flag);

         lc_all_item := NULL;
         ln_all_hold_qty := 0;
         
         -- Validate the item, ASL existence and the outer join to txn all
         OPEN lcu_asl_item (sup_txn_info_rec.vendor_site_id, lc_stripped_vpc, ln_supplier_id);
         FETCH lcu_asl_item 
         INTO lc_item_number, lc_uom_code, ln_item_id, lc_all_item, ln_all_hold_qty ;

         IF lcu_asl_item%NOTFOUND THEN
            lc_err_code := 'XX_OM_SUPINV_0002_INVALID_ITEM';
            FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0002_INVALID_ITEM');
            lc_err_desc := FND_MESSAGE.GET;
            WRITE_LOG('         '||lc_err_desc,gc_debug_flag);
            lc_entity_ref := 'Supplier ID';
            
            CLOSE lcu_asl_item;
            RAISE EX_TXN_INVALID;
         END IF;

         CLOSE lcu_asl_item;


         WRITE_LOG('         VPC/Item validation completed',gc_debug_flag);

         -- set the on hold qty
         ln_on_hold_qty := NVL(ln_all_hold_qty,0);
         
         --Calculating the new on_hand_qty and avb_reserve_qty
         ln_on_hand_qty := sup_txn_info_rec.on_hand_qty * (sup_txn_info_rec.avb_per_qty / 100);

         ln_avb_reserve := ln_on_hand_qty - ln_on_hold_qty;

         IF (ln_avb_reserve < 0) THEN
            ln_avb_reserve := 0;
         END IF;

         -- Only update/insert the header once and retrieve the supplier_id to write txn rows

         -- If the row does not exist in the prod table then insert a new row otherwise
         -- update the existing row
         IF lc_all_item IS NULL THEN
 
            INSERT INTO xx_om_supplier_invfeed_txn_all (
                supplier_id
                ,supplier_number
                ,item_number
                ,inventory_item_id 
                ,uom 
                ,vpc_code 
                ,on_hand_qty
                ,avb_reserve_qty 
                ,on_hold_qty 
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_update_date 
                ,last_update_login)        
                
            VALUES (
                ln_supplier_id
                ,sup_txn_info_rec.vendor_number
                ,lc_item_number
                ,ln_item_id
                ,lc_uom_code
                ,lc_stripped_vpc        
                ,ln_on_hand_qty
                ,ln_avb_reserve
                ,0                     --Hold_Qty
                ,FND_GLOBAL.USER_ID
                ,SYSDATE
                ,FND_GLOBAL.USER_ID
                ,SYSDATE
                ,FND_GLOBAL.LOGIN_ID);
                
             WRITE_LOG('Record has been Inserted',gc_debug_flag);
         ELSE

             UPDATE xx_om_supplier_invfeed_txn_all
             SET 
                on_hand_qty = ln_on_hand_qty
                ,avb_reserve_qty = ln_avb_reserve
                ,last_updated_by = FND_GLOBAL.USER_ID
                ,last_update_date = SYSDATE
                ,last_update_login = FND_GLOBAL.LOGIN_ID
             WHERE 
                    supplier_id = ln_supplier_id
                AND item_number = lc_item_number;

             WRITE_LOG('Record has been Updated',gc_debug_flag);

         END IF;

         -- update the interface row as being processed
         UPDATE 
            xx_om_supplier_invfeed_txn_int
         SET 
            interface_status = 'S'
            ,error_message = NULL
            ,last_updated_by = FND_GLOBAL.USER_ID
            ,last_update_date = SYSDATE
            ,last_update_login = FND_GLOBAL.LOGIN_ID
         WHERE 
            ROWID = sup_txn_info_rec.ROWID;
         
         -- count number of txn rows that were sucessful
         ln_count := ln_count + 1;

      EXCEPTION
         WHEN EX_TXN_INVALID THEN

            --set the row to have an error status
            UPDATE xx_om_supplier_invfeed_txn_int
            SET interface_status = 'E'
                ,error_message = lc_err_desc
                ,last_updated_by = FND_GLOBAL.USER_ID
                ,last_update_date = SYSDATE
                ,last_update_login = FND_GLOBAL.LOGIN_ID
            WHERE ROWID = sup_txn_info_rec.ROWID;

            lc_err_code := 'XX_OM_SUPINV_0003_INVALID_VPC';
            FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0003_INVALID_VPC');
            FND_MESSAGE.SET_TOKEN('PROG_NAME','OD: OM Supplier Inventory Feed Child');
            lc_err_desc := FND_MESSAGE.GET;
            lc_entity_ref := 'Supplier ID';


            err_report_type :=
                xx_om_report_exception_t (
                                          gc_exp_header
                                          ,gc_track_code
                                          ,gc_sol_domain
                                          ,gc_function
                                          ,lc_err_code
                                          ,SUBSTR(lc_err_desc,1,1000)
                                          ,lc_entity_ref
                                          ,NVL(sup_txn_info_rec.supplier_id,0)
                                         );
            XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                         err_report_type
                                                         ,lc_err_buf
                                                         ,lc_ret_code
                                                        );

      END;
   END LOOP;

   IF ln_count = 0 THEN

      UPDATE xx_om_supplier_invfeed_hdr_int
      SET status='E'
          ,error_message='No Transactions were loaded for the given supplier'
      WHERE supplier_id = p_supplier_id;

   END IF;
   COMMIT;
   
   ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                               application => 'xxom'
                                               ,program    => 'XXOMSUPINVWRKSKUPRG'
                                               ,argument1  => p_supplier_number
                                               ,argument2  => p_supplier_id
                                               ,argument3  => p_debug_flag
                                               );
   IF (ln_request_id <= 0) THEN

         lc_err_code := 'XX_OM_SUPINV_0013_CONC_FAIL';
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0013_CONC_FAIL');
         FND_MESSAGE.SET_TOKEN('PROG_NAME','OD: OM Purge Worktable SKUs');
         lc_err_desc := FND_MESSAGE.GET;
         lc_entity_ref := 'Supplier ID';

         err_report_type :=
                         xx_om_report_exception_t (
                                                   gc_exp_header
                                                   ,gc_track_code
                                                   ,gc_sol_domain
                                                   ,gc_function
                                                   ,lc_err_code
                                                   ,SUBSTR(lc_err_desc,1,1000)
                                                   ,lc_entity_ref
                                                   ,NVL(ln_supplier_id,0)
                                                  );
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                      err_report_type
                                                      ,lc_err_buf
                                                      ,lc_ret_code
                                                     );


   END IF;

EXCEPTION
   WHEN NULL_PARAMETERS THEN

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_err_desc   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_SUPINV_UNEXPECTED_ERROR3';
      lc_entity_ref := 'SQLERROR';

      err_report_type :=
          xx_om_report_exception_t (
                                    gc_exp_header
                                    ,gc_track_code
                                    ,gc_sol_domain
                                    ,gc_function
                                    ,lc_err_code
                                    ,SUBSTR(lc_err_desc,1,1000)
                                    ,lc_entity_ref
                                    ,SQLCODE
                                   );
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );
   
   WHEN OTHERS THEN

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_err_desc   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_SUPINV_UNEXPECTED_ERROR2';
      lc_entity_ref := 'SQLERROR';

      err_report_type :=
          xx_om_report_exception_t (
                                    gc_exp_header
                                    ,gc_track_code
                                    ,gc_sol_domain
                                    ,gc_function
                                    ,lc_err_code
                                    ,SUBSTR(lc_err_desc,1,1000)
                                    ,lc_entity_ref
                                    ,SQLCODE
                                   );
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );
END PROCESS_FEED_CHILD;

-- +===================================================================+
-- | Name  :   PURGE_WORKTABLE_SKUS                                    |
-- | Description   : Purges successfully processed records from        |
-- |                 work table and error records if they have         |
-- |                 threshold days                                    |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :      p_supplier_number                               |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PURGE_WORKTABLE_SKUS(
                                x_errbuff           OUT NOCOPY VARCHAR2
                                ,x_retcode          OUT NOCOPY VARCHAR2
                                ,p_supplier_number  IN  VARCHAR2   DEFAULT NULL
                                ,p_supplier_id      IN  NUMBER     DEFAULT NULL
                                ,p_debug_flag       IN  VARCHAR2   DEFAULT 'N'
                               )
AS

   err_report_type           xx_om_report_exception_t;

   lc_purge_threshold        fnd_profile_option_values.profile_option_value%TYPE := NULL;
   lc_err_code               xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc               xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref             xx_om_global_exceptions.entity_ref%TYPE;
   lc_err_buf                VARCHAR2(240);
   lc_ret_code               VARCHAR2(30);

   ln_supplier_id            xx_om_supplier_invfeed_hdr_int.supplier_id%TYPE DEFAULT 0;
   ln_chk_supplier           xx_om_supplier_invfeed_hdr_int.supplier_id%TYPE;
   ln_txn_count              NUMBER;

    CURSOR lcu_supplier_id (p_vendor_number VARCHAR2) IS
    SELECT
        supplier_id
    FROM
        xx_om_supplier_invfeed_hdr_int
    WHERE
        vendor_number = NVL(p_vendor_number,vendor_number);
        
    CURSOR lcu_txn_count (
            p_supplier_id NUMBER
            ,p_use_threshold NUMBER 
            ,p_threshold VARCHAR2) IS
    SELECT 
        COUNT(XOSITI.supplier_id)
    INTO 
        ln_txn_count
    FROM 
        xx_om_supplier_invfeed_txn_int XOSITI
    WHERE 
            supplier_id = p_supplier_id
       AND interface_status <> 'S'
       AND TRUNC(SYSDATE) > TRUNC(DECODE(p_use_threshold
                                    ,0,(SYSDATE - 1)
                                    ,(creation_date + TO_NUMBER(p_threshold))));
    
BEGIN

   gc_debug_flag := p_debug_flag;

   WRITE_LOG('         Purge of Work table begins...',gc_debug_flag);

      -- reterieve the profile value to purge rows X number of days out
   BEGIN
        
        lc_purge_threshold := -1;
        
        SELECT 
            NVL(FPOV.profile_option_value,0)
        INTO 
            lc_purge_threshold
        FROM 
            fnd_profile_option_values FPOV
            ,fnd_profile_options FPO
            ,fnd_profile_options_tl FPOT
        WHERE 
                FPOV.profile_option_id = FPO.profile_option_id
            AND FPOT.profile_option_name = FPO.profile_option_name
            AND FPOV.level_value = FND_PROFILE.VALUE('RESP_ID')
            AND FPO.profile_option_name = gc_purge_profile;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lc_err_code := 'XX_OM_SUPINV_0005_PROF_ERROR';
        FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0005_PROF_ERROR');
        lc_err_desc := FND_MESSAGE.GET;
        lc_entity_ref := 'Org ID';

        err_report_type :=
            xx_om_report_exception_t (
                                      gc_exp_header
                                      ,gc_track_code
                                      ,gc_sol_domain
                                      ,gc_function
                                      ,lc_err_code
                                      ,SUBSTR(lc_err_desc,1,1000)
                                      ,lc_entity_ref
                                      ,NVL(FND_PROFILE.VALUE('ORG_ID'),0)
                                     );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                     err_report_type
                                                     ,lc_err_buf
                                                     ,lc_ret_code
                                                    );
   END;

   IF lc_purge_threshold = -1 THEN
       lc_purge_threshold := NULL;
   END IF;
   WRITE_LOG('         Deleting records with success status ',gc_debug_flag);

   -- delete all of the succesfully loaded detail rows for the supplier
   IF p_supplier_id IS NOT NULL THEN

        SELECT 
            supplier_id 
        INTO
            ln_chk_supplier
        FROM
            xx_om_supplier_invfeed_hdr_int
        WHERE
            supplier_id = p_supplier_id;
            
        DELETE FROM 
            xx_om_supplier_invfeed_txn_int
        WHERE 
                supplier_id = p_supplier_id
            AND interface_status = 'S';
        
        -- count the number of rows not loaded
        ln_txn_count := 0;
        OPEN lcu_txn_count(p_supplier_id,0,0);
        FETCH lcu_txn_count INTO ln_txn_count;
        CLOSE lcu_txn_count;

        IF (ln_txn_count = 0) THEN

            DELETE FROM xx_om_supplier_invfeed_hdr_int
            WHERE 
                    supplier_id = p_supplier_id
                AND status = 'S';
        END IF;
        
        IF lc_purge_threshold IS NOT NULL THEN
            IF ln_txn_count > 0 THEN

                DELETE FROM xx_om_supplier_invfeed_txn_int
                WHERE 
                        supplier_id = p_supplier_id
                    AND interface_status <> 'S'
                    AND TRUNC(SYSDATE) > TRUNC(creation_date + TO_NUMBER(lc_purge_threshold))
                    ;
            
                ln_txn_count := 0;
                OPEN lcu_txn_count(p_supplier_id,1,lc_purge_threshold);
                FETCH lcu_txn_count INTO ln_txn_count;
                CLOSE lcu_txn_count;

                IF ln_txn_count = 0 THEN

                    DELETE FROM xx_om_supplier_invfeed_hdr_int
                    WHERE 
                        supplier_id = p_supplier_id;
                END IF;
            END IF;
        END IF;
        

   ELSE
        FOR supp_id_rec IN lcu_supplier_id(p_supplier_number) 
        LOOP
            DELETE FROM 
                xx_om_supplier_invfeed_txn_int
            WHERE 
                    supplier_id = supp_id_rec.supplier_id
                AND interface_status = 'S';
                
            -- count the number of rows not loaded
            ln_txn_count := 0;
            OPEN lcu_txn_count(supp_id_rec.supplier_id,0,0);
            FETCH lcu_txn_count INTO ln_txn_count; 
            CLOSE lcu_txn_count;

            IF (ln_txn_count = 0) THEN

                DELETE FROM xx_om_supplier_invfeed_hdr_int
                WHERE 
                        supplier_id = supp_id_rec.supplier_id
                    AND status = 'S';
            END IF;
            
            IF lc_purge_threshold IS NOT NULL THEN
                IF ln_txn_count > 0 THEN

                    DELETE FROM xx_om_supplier_invfeed_txn_int
                    WHERE 
                            supplier_id = supp_id_rec.supplier_id
                        AND interface_status <> 'S'
                        AND TRUNC(SYSDATE) > TRUNC(creation_date + TO_NUMBER(lc_purge_threshold))
                        ;
            
                    ln_txn_count := 0;
                    OPEN lcu_txn_count(supp_id_rec.supplier_id,1,lc_purge_threshold);
                    FETCH lcu_txn_count INTO ln_txn_count;
                    CLOSE lcu_txn_count;

                    IF ln_txn_count = 0 THEN
                        -- delete the header row where the creation date is X days in the past

                        DELETE FROM xx_om_supplier_invfeed_hdr_int
                        WHERE 
                            supplier_id = supp_id_rec.supplier_id;
                    END IF;
                END IF;
            END IF; 
        END LOOP;
   END IF;
   
   COMMIT;


EXCEPTION
   WHEN NO_DATA_FOUND THEN
      lc_err_code := 'XX_OM_SUPINV_0004_NO_SUPPLIER';
      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0004_NO_SUPPLIER');
      lc_err_desc := FND_MESSAGE.GET;
      lc_entity_ref := 'Org ID';

      err_report_type :=
          xx_om_report_exception_t (
                                    gc_exp_header
                                    ,gc_track_code
                                    ,gc_sol_domain
                                    ,gc_function
                                    ,lc_err_code
                                    ,SUBSTR(lc_err_desc,1,1000)
                                    ,lc_entity_ref
                                    ,NVL(FND_PROFILE.VALUE('ORG_ID'),0)
                                   );
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );

   WHEN OTHERS THEN
      ROLLBACK;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_err_desc   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_SUPINV_UNEXPECTED_ERROR3';
      lc_entity_ref := 'SQLERROR';

      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,SQLCODE
                                               );
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );

END;
-- +===================================================================+
-- | Name  :   PURGE_INACTIVE_PROD_SKUS                                |
-- | Description   : Purges inactive SKUs from production table        |
-- |                 based on the threshold days                       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :      p_supplier_name                                 |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PURGE_INACTIVE_PROD_SKUS(
                                   x_errbuff            OUT NOCOPY VARCHAR2
                                   ,x_retcode           OUT NOCOPY VARCHAR2
                                   ,p_supplier_number   IN  VARCHAR2   DEFAULT NULL
                                   ,p_all_rows          IN  VARCHAR2   DEFAULT 'N'
                                   ,p_debug_flag        IN  VARCHAR2   DEFAULT 'N'
                                  )
AS
   NULL_VALUES               EXCEPTION;
   INVALID_PURGE_ALL         EXCEPTION;

   err_report_type           xx_om_report_exception_t;

   lc_err_code               xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc               xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref             xx_om_global_exceptions.entity_ref%TYPE;
   lc_err_buf                VARCHAR2(240);
   lc_ret_code               VARCHAR2(30);

   ln_purge_sku_days         xx_om_supplier_invfeed_percent.inactive_skus_purge_days%TYPE;
   ln_supplier_id            xx_om_supplier_invfeed_percent.supplier_id%TYPE;
   ln_txn_count              NUMBER;

   -- select all the detail rows that are for the supplier or Null and have not been update
   CURSOR lcu_purge_prod (p_supplier_number xx_om_supplier_invfeed_hdr_all.supplier_number%TYPE)
   IS
      SELECT XOSIHA.supplier_id
             ,XOSITA.item_number
      FROM xx_om_supplier_invfeed_percent XOSIP
           ,xx_om_supplier_invfeed_hdr_all XOSIHA
           ,xx_om_supplier_invfeed_txn_all XOSITA
      WHERE 
          XOSIP.supplier_number = NVL(p_supplier_number,XOSIP.supplier_number)
      AND XOSIHA.supplier_id = XOSITA.supplier_id
      AND XOSIHA.supplier_number = XOSIP.supplier_number
      AND TRUNC(SYSDATE) > TRUNC(XOSITA.last_update_date) + XOSIP.inactive_skus_purge_days;

BEGIN
   gc_debug_flag := p_debug_flag;

   WRITE_LOG('         Purge of Production table begins...',gc_debug_flag);

   IF p_all_rows = 'Y' THEN
       IF p_supplier_number IS NULL THEN
           RAISE INVALID_PURGE_ALL;
       ELSE
           BEGIN
               SELECT
                   supplier_id
               INTO
                   ln_supplier_id
               FROM 
                   xx_om_supplier_invfeed_hdr_all
               WHERE
                   supplier_number = p_supplier_number;
               DELETE FROM 
                   xx_om_supplier_invfeed_txn_all
               WHERE 
                   supplier_id = ln_supplier_id;

               DELETE FROM 
                   xx_om_supplier_invfeed_hdr_all
               WHERE 
                   supplier_id = ln_supplier_id;
                   
           EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   WRITE_LOG('         Supplier does not exist in Production Tables',gc_debug_flag);
           END;
       END IF;
   ELSE        
   -- loop through seleted rows and delete the detail row
   FOR purge_prod_rec IN lcu_purge_prod(p_supplier_number)
   LOOP

      ln_supplier_id := purge_prod_rec.supplier_id;

      -- if for some unknown reason the the conditionals are null all data would ge deleted
      -- raise an exception to stop it 
      IF purge_prod_rec.supplier_id IS NULL or 
         purge_prod_rec.item_number IS NULL THEN
          RAISE NULL_VALUES;
      END IF;
      
      DELETE FROM 
        xx_om_supplier_invfeed_txn_all
      WHERE 
            supplier_id = purge_prod_rec.supplier_id
        AND item_number = purge_prod_rec.item_number;

   END LOOP;

   -- remove suppliers that have no transaction rows for the specified 
   -- supplier or all suppliers
   DELETE FROM xx_om_supplier_invfeed_hdr_all
   WHERE supplier_id NOT IN(
                              SELECT 
                                supplier_id
                              FROM
                                xx_om_supplier_invfeed_txn_all
                              )
         AND supplier_number = NVL(p_supplier_number,supplier_number);
   END IF;      
   WRITE_LOG('         Purge of Production table ends...',gc_debug_flag);

   COMMIT;
   
EXCEPTION
   WHEN NULL_VALUES THEN
      ROLLBACK;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_err_desc   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_SUPINV_UNEXPECTED_ERROR5';
      lc_entity_ref := 'Supplier ID';

      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,NVL(ln_supplier_id,0)
                                               );
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );
    WHEN INVALID_PURGE_ALL THEN
        ROLLBACK;

        lc_err_code := 'XX_OM_SUPINV_0016_PURGE_ALL';
        FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_SUPINV_0016_PURGE_ALL');
        lc_err_desc := FND_MESSAGE.GET;
        lc_entity_ref := 'Supplier ID';

        err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,-1
                                               );
        XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );
   WHEN OTHERS THEN
      ROLLBACK;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_err_desc   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_SUPINV_UNEXPECTED_ERROR4';
      lc_entity_ref := 'Supplier ID';

      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,NVL(ln_supplier_id,0)
                                               );
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );

END;
-- +===================================================================+
-- | Name  :   SYNC_ONHOLD_QTY                                         |
-- | Description   : Synchronizes on hold quantity in production       |
-- |                 table and sales order tables                      |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :      p_supplier_name                                 |
-- |                   p_item_number                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE SYNC_ONHOLD_QTY(
                          x_errbuff                 OUT NOCOPY VARCHAR2
                          ,x_retcode                OUT NOCOPY VARCHAR2
                          ,p_supplier_number        IN           VARCHAR2
                          ,p_item_number            IN           VARCHAR2   DEFAULT NULL
                          ,p_debug_flag             IN           VARCHAR2   DEFAULT 'N'
                         )
AS

   err_report_type           xx_om_report_exception_t;

   lc_err_code               xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc               xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref             xx_om_global_exceptions.entity_ref%TYPE;
   lc_err_buf                VARCHAR2(240);
   lc_ret_code               VARCHAR2(30);

   ln_on_hold_qty            NUMBER;
   ln_supplier_id            xx_om_supplier_invfeed_txn_all.supplier_id%TYPE;

   -- select all detail rows for the specified supplier and item. 
   CURSOR lcu_prod_update (
        p_supplier_number xx_om_supplier_invfeed_txn_all.supplier_number%TYPE
        )
   IS
      SELECT 
        XOSITA.*
      FROM 
        xx_om_supplier_invfeed_txn_all XOSITA
      WHERE 
            XOSITA.supplier_number = p_supplier_number
        AND XOSITA.item_number = NVL(p_item_number,XOSITA.item_number)
      FOR UPDATE OF on_hold_qty;
      
BEGIN
   gc_debug_flag := p_debug_flag;   

   WRITE_LOG('         Synchronizing on hold quantity in Production table...',gc_debug_flag);

   FOR prod_update_rec IN lcu_prod_update(p_supplier_number)
   LOOP

      ln_supplier_id := prod_update_rec.supplier_id;
       BEGIN
           SELECT SUM(qty)
           INTO ln_on_hold_qty
           FROM(
               SELECT SUM(DISTINCT OOLA.ordered_quantity) qty
               FROM oe_order_lines_all OOLA
                   ,oe_order_holds_all OOHA
                   ,oe_hold_sources_all OHSA
                   ,oe_hold_definitions OHD
                   ,xx_om_line_attributes_all XOLAA
                   ,xx_om_supplier_invfeed_hdr_all ha
                   ,po_vendor_sites_all vs
                   ,po_vendors v
               WHERE 
                        (OOLA.line_id = OOHA.line_id or
                            (oola.header_id = ooha.header_id and ooha.line_id IS NULL))
                    AND OOHA.released_flag = 'N'
                    AND OOLA.ordered_item = prod_update_rec.item_number
                    AND OOHA.hold_source_id = OHSA.hold_source_id
                    AND OHSA.hold_id = OHD.hold_id
                    AND OOLA.line_id = XOLAA.line_id
                    AND XOLAA.vendor_site_id = vs.vendor_site_id
                    AND v.vendor_id = vs.vendor_id
                    AND vs.org_id = ha.org_id
                    AND v.vendor_id = ha.vendor_id
                    AND ha.supplier_id = prod_update_rec.supplier_id
                    AND OHD.name NOT IN (
                            SELECT FLV.meaning
                            FROM fnd_lookup_values FLV
                            WHERE FLV.lookup_type = gc_hold_lookup
                                 AND FLV.enabled_flag = 'Y'
                                 AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(FLV.start_date_active,SYSDATE)) AND TRUNC(NVL(FLV.end_date_active,SYSDATE))
                            )
               GROUP BY OOLA.line_id
           );
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
               ln_on_hold_qty := 0;
           WHEN OTHERS THEN
               RAISE;
       END;
       
       IF ln_on_hold_qty IS NULL THEN
         ln_on_hold_qty := 0;
       END IF;
      UPDATE xx_om_supplier_invfeed_txn_all
      SET on_hold_qty = ln_on_hold_qty
          ,last_updated_by = FND_GLOBAL.USER_ID
          ,last_update_date = SYSDATE
          ,last_update_login = FND_GLOBAL.LOGIN_ID
      WHERE CURRENT OF lcu_prod_update;
      
   END LOOP;
   
   COMMIT;

   WRITE_LOG('         On hold quantity in Production table synchronized...',gc_debug_flag);

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_err_desc   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_SUPINV_UNEXPECTED_ERROR1';
      lc_entity_ref := 'Supplier ID';

      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,NVL(ln_supplier_id,0)
                                               );
      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                   err_report_type
                                                   ,lc_err_buf
                                                   ,lc_ret_code
                                                  );

END;

-- +===================================================================+
-- | Name  :   WRITE_LOG                                               |
-- | Description   : This procedure is used to write into the log file |
-- |                                                                   |
-- | Parameters :      p_log_msg                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE WRITE_LOG(
                    p_log_msg           IN           VARCHAR2
                    ,p_debug_flag       IN           VARCHAR2
                    )
AS
BEGIN
   IF (p_debug_flag = 'Y') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,p_log_msg);
   END IF;
END;


-- +===================================================================+
-- | Name  :   STRIP_CHAR                                              |
-- | Description   : This function is used to strip non alpha numeric  |
-- |                 characters from the input and returns the         |
-- |                 stripped string                                   |
-- |                                                                   |
-- | Parameters :      p_log_msg                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         x_errbuff                                       |
-- |                   x_retcode                                       |
-- |                                                                   |
-- +===================================================================+

FUNCTION STRIP_CHAR(
                    p_input             IN           VARCHAR2
                    )
RETURN VARCHAR2 IS

   lc_stripped_char          xx_om_supplier_invfeed_txn_int.vpc_code%TYPE;

   ln_length                 NUMBER;
   ln_count                  PLS_INTEGER;
   ln_ascii_val              NUMBER;
BEGIN

   ln_length := LENGTH(p_input);
   FOR ln_count IN 1..ln_length
   LOOP
      ln_ascii_val := ASCII(SUBSTR(p_input,ln_count,1));

      IF((ln_ascii_val>=48) AND (ln_ascii_val<=57)) THEN
         lc_stripped_char := lc_stripped_char||SUBSTR(p_input,ln_count,1);
      ELSIF ((ln_ascii_val>=65) AND (ln_ascii_val<=90)) THEN
         lc_stripped_char := lc_stripped_char||SUBSTR(p_input,ln_count,1);
      ELSIF ((ln_ascii_val>=97) AND (ln_ascii_val<=122)) THEN
         lc_stripped_char := lc_stripped_char||SUBSTR(p_input,ln_count,1);
      ELSIF (ln_ascii_val = 32) THEN
         lc_stripped_char := lc_stripped_char||SUBSTR(p_input,ln_count,1);
      END IF;

   END LOOP;
   RETURN lc_stripped_char;

END;

END XX_OM_SUPPINVFEED_INTF_PKG;
/
SHOW ERROR