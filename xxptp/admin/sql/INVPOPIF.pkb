CREATE OR REPLACE PACKAGE BODY "INVPOPIF" AS
/* $Header: INVPOPIB.pls 115.44.115120.9 2007/05/24 13:30:52 arattan ship $ */

------------------------ inopinp_open_interface_process -----------------------
PROCEDURE UPDATE_SYNC_RECORDS(p_set_id  IN  NUMBER);

FUNCTION inopinp_open_interface_process (
    org_id          NUMBER,
    all_org         NUMBER      := 1,
    val_item_flag   NUMBER      := 1,
    pro_item_flag   NUMBER      := 1,
    del_rec_flag    NUMBER      := 1,
    prog_appid      NUMBER      := -1,
    prog_id         NUMBER      := -1,
    request_id      NUMBER      := -1,
    user_id         NUMBER      := -1,
    login_id        NUMBER      := -1,
    err_text    IN OUT NOCOPY VARCHAR2,
    xset_id     IN  NUMBER       DEFAULT -999,
    commit_flag IN  NUMBER       DEFAULT 1,
    run_mode    IN  NUMBER       DEFAULT 1)
RETURN INTEGER IS

   ret_code         NUMBER  := 0;
   ret_code_create  NUMBER  := 0;
   ret_code_update  NUMBER  := 0;
   p_flag           NUMBER  := 0;
   ret_code_grp     NUMBER  := 0;
   dumm_status      NUMBER;
   LOGGING_ERR      EXCEPTION;
   req_id           NUMBER  := request_id;
   mtl_count        NUMBER  := 0;
   mtli_count       NUMBER  := 0;

   CURSOR lock_rows IS
      select rowid
      from   mtl_system_items_interface
      where  set_process_id = xset_id
      for update;

   CURSOR lock_revs IS
      select rowid
      from   mtl_item_revisions_interface
      where set_process_id = xset_id
      for update;

   CURSOR update_org_id IS
      select rowid, transaction_id
      from mtl_system_items_interface
      where organization_id is NULL
      and set_process_id = xset_id
      and process_flag   = 1;

   CURSOR update_org_id_revs IS
      select rowid, transaction_id
      from mtl_item_revisions_interface
      where organization_id is NULL
      and set_process_id = xset_id
      and process_flag   = 1;

   CURSOR c_master_items(cp_transaction_type VARCHAR2) IS
      SELECT COUNT(*) FROM DUAL
      WHERE EXISTS (SELECT NULL
                    FROM  mtl_system_items_interface msii
                         ,mtl_parameters mp1
                    WHERE set_process_id   = xset_id
                    AND   transaction_type = cp_transaction_type
                    AND   process_flag in (1,4)
                    AND   mp1.master_organization_id = msii.organization_id);

   CURSOR c_master_revs(cp_transaction_type VARCHAR2) IS
      SELECT count(*) FROM DUAL
      WHERE EXISTS (SELECT NULL
                    FROM   mtl_item_revisions_interface msii
                          ,mtl_parameters mp1
                    WHERE  set_process_id   = xset_id
                    AND    transaction_type = cp_transaction_type
                    AND    process_flag in (1,4)
                    AND    mp1.master_organization_id = msii.organization_id);

   CURSOR c_interface_items(cp_transaction_type VARCHAR2) IS
      SELECT COUNT(*) FROM DUAL
      WHERE EXISTS (SELECT NULL
                    FROM  mtl_system_items_interface
                    WHERE set_process_id   = xset_id
                    AND   transaction_type = cp_transaction_type
                    AND   process_flag in (1,4));

   CURSOR c_interface_revs(cp_transaction_type VARCHAR2) IS
      SELECT count(*) FROM DUAL
      WHERE EXISTS (SELECT NULL
                    FROM   mtl_item_revisions_interface
                    WHERE  set_process_id   = xset_id
                    AND    transaction_type = cp_transaction_type
                    AND    process_flag in (1,4));

   l_processed_flag  BOOLEAN := FALSE;

   --2698140 : Gather stats before running the IOI
   l_schema          VARCHAR2(30);
   l_status          VARCHAR2(1);
   l_industry        VARCHAR2(1);
   l_records         NUMBER(10);
   err_msg           VARCHAR2(1000);

BEGIN

   INVPUTLI.info('INVPOPIF: *** Starting a new IOI process: run_mode='|| TO_CHAR(run_mode) ||' all_org='|| TO_CHAR(all_org));
   INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: org_id = '|| TO_CHAR(org_id));

   /*
   ** Make sure transaction type is in upper case
   */
   --Start 2698140 : Gather stats before running the IOI
   --When called through GRP pac, or through PLM prog_id will be -1.
   --IF fnd_global.conc_program_id <> -1 THEN  Bug:3547401

   IF NVL(prog_id,-1) <> -1 THEN

      INVPUTLI.info('INVPOPIF: Gathering interface table stats');
      --3515652: Collect stats only if no. records > 50
      SELECT count(*) INTO l_records
      FROM   mtl_system_items_interface
      WHERE  set_process_id = xset_id
      AND    process_flag = 1;

      /*IF (l_records > 50)
         AND FND_INSTALLATION.GET_APP_INFO('INV', l_status, l_industry, l_schema)
      THEN
         IF l_schema IS NOT NULL    THEN
            FND_STATS.GATHER_TABLE_STATS(l_schema, 'MTL_SYSTEM_ITEMS_INTERFACE');
            FND_STATS.GATHER_TABLE_STATS(l_schema, 'MTL_ITEM_REVISIONS_INTERFACE');
            FND_STATS.GATHER_TABLE_STATS(l_schema, 'MTL_DESC_ELEM_VAL_INTERFACE');
         END IF;
      END IF;*/
      INVPUTLI.info('INVPOPIF: Gathering interface table stats done');
   END IF;
   --End 2698140 : Gather stats before running the IOI

   UPDATE mtl_system_items_interface msii
   SET    transaction_type = UPPER(transaction_type)
   WHERE  set_process_id   = xset_id;

   UPDATE mtl_item_revisions_interface
   SET    transaction_type = UPPER(transaction_type)
   WHERE  set_process_id   = xset_id;

   -- Populate request_id to have a correct value in case
   -- validation fails while Creating or Updating an Item.

   -- Bug 3975408 :Changed the where clause to (1,4) of the following update.
   UPDATE mtl_system_items_interface
   SET request_id     = req_id
      ,transaction_id = NVL(transaction_id, MTL_SYSTEM_ITEMS_INTERFACE_S.NEXTVAL)
   WHERE   set_process_id = xset_id
   AND     process_flag IN (1,4);

   --SYNC: IOI to support SYNC operation.
   UPDATE mtl_system_items_interface msii
   SET  process_flag = -888
   WHERE ( transaction_type NOT IN ('CREATE', 'UPDATE','SYNC')
           OR transaction_type IS NULL OR set_process_id >= 900000000000)
   AND   set_process_id = xset_id;

   -- Rev UPDATE is not supported
   -- Start: 2808277 Supporting Item Revision Update
   -- SYNC: IOI to support SYNC operation.
   UPDATE mtl_item_revisions_interface
   SET  process_flag = -888
   WHERE (   transaction_type NOT IN ('CREATE', 'UPDATE','SYNC')
            OR transaction_type IS NULL OR set_process_id >= 900000000000)
   AND   set_process_id = xset_id;

   -- End: 2808277 Supporting Item Revision Update

   -- Assign missing organization_id from organization_code

   update MTL_SYSTEM_ITEMS_INTERFACE MSII
   set MSII.organization_id =
            ( select MP.organization_id
              from MTL_PARAMETERS MP
              where MP.organization_code = MSII.organization_code
            )
   where MSII.organization_id is NULL
   and MSII.set_process_id = xset_id
   and MSII.process_flag = 1;

   update MTL_ITEM_REVISIONS_INTERFACE MIRI
   set MIRI.organization_id =
            ( select MP.organization_id
              from MTL_PARAMETERS MP
              where MP.organization_code = MIRI.organization_code
            )
   where MIRI.organization_id is NULL
   and MIRI.set_process_id = xset_id
   and MIRI.process_flag = 1;

   -- When organization id is missing, update process_flag, and log an error
   FOR cr IN update_org_id LOOP
      dumm_status := INVPUOPI.mtl_log_interface_err(
                        -1,
                        user_id,
                        login_id,
                        prog_appid,
                        prog_id,
                        request_id,
                        cr.transaction_id,
                        'INVPOPIF: Invalid Organization ID',
                        'ORGANIZATION_ID',
                        'MTL_SYSTEM_ITEMS_INTERFACE',
                        'INV_IOI_ORG_NO_EXIST',
                        err_text);
      if dumm_status < 0 then
         raise LOGGING_ERR;
      end if;

      update mtl_system_items_interface
      set process_flag = 3
      where rowid  = cr.rowid ;

   END LOOP;

   FOR cr IN update_org_id_revs LOOP
      dumm_status := INVPUOPI.mtl_log_interface_err (
                        -1,
                        user_id,
                        login_id,
                        prog_appid,
                        prog_id,
                        request_id,
                        cr.transaction_id,
                        'INVPOPIF: Invalid Organization ID',
                        'ORGANIZATION_ID',
                        'MTL_ITEM_REVISIONS_INTERFACE',
                        'INV_IOI_ORG_NO_EXIST',
                        err_text);
      if dumm_status < 0 then
         raise LOGGING_ERR;
      end if;

      UPDATE mtl_item_revisions_interface
      SET process_flag = 3
      WHERE rowid = cr.rowid;

   END LOOP;


   /* Bug 5738958
   ** Update Item Status to pending for ITEM CREATE rows in a
   ** ICC with NIR enabled. This will prevent Active status
   ** to be defaulted and subsequently applied.
   */
   UPDATE mtl_system_items_interface msii
      SET msii.INVENTORY_ITEM_STATUS_CODE = 'Pending'
    WHERE (msii.organization_id = org_id OR all_Org = 1)
      AND msii.INVENTORY_ITEM_STATUS_CODE IS NULL
      AND msii.ITEM_CATALOG_GROUP_ID IS NOT NULL
      AND msii.process_flag = 1
      AND msii.set_process_id = xset_id
      AND msii.TRANSACTION_TYPE = 'CREATE'
      AND EXISTS
             (SELECT NULL
                FROM mtl_item_catalog_groups_b  micb
               WHERE micb.NEW_ITEM_REQUEST_REQD = 'Y'
             AND msii.ITEM_CATALOG_GROUP_ID =
                 micb.ITEM_CATALOG_GROUP_ID);

   --SYNC: IOI to support SYNC operation.
   IF run_mode = 3 THEN

      --3018673: Start of bug fix.
      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag + 20000
      WHERE transaction_type IN ('CREATE','UPDATE')
      AND process_flag < 20000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag + 20000
      WHERE transaction_type IN ('CREATE','UPDATE')
      AND process_flag < 20000
      AND set_process_id = xset_id;
      --3018673: End of bug fix.

      UPDATE_SYNC_RECORDS(p_set_id => xset_id);

   END IF;

   IF (run_mode IN (1,3)) THEN --{    /* transaction_type IN  'CREATE' 'SYNC' */

      l_processed_flag := TRUE;

      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag + 30000
      WHERE transaction_type IN ('UPDATE','SYNC') --3018673
      AND process_flag < 30000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag + 30000
      WHERE transaction_type IN ('UPDATE','SYNC') --3018673
      AND process_flag < 30000
      AND set_process_id = xset_id;

      IF (all_org = 1) THEN  --{

         OPEN  c_master_items(cp_transaction_type=>'CREATE');
         FETCH c_master_items INTO mtl_count;
         CLOSE c_master_items;

         OPEN  c_master_revs(cp_transaction_type=>'CREATE');
         FETCH c_master_revs INTO mtli_count;
         CLOSE c_master_revs;


         /*  Added the below If condition so that if no records are present in the
             interface table for creating master org Items then we can skip calling of
             inopinp_OI_process_create for the master org */

         IF (mtl_count <> 0 or mtli_count <> 0) THEN

            UPDATE mtl_system_items_interface msii
            SET process_flag = process_flag + 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag < 60000
            AND set_process_id = xset_id
            AND not exists (select mp1.organization_id
                            from mtl_parameters mp1
                            where msii.organization_id = mp1.master_organization_id);

            UPDATE mtl_item_revisions_interface miri
            SET process_flag = process_flag + 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag < 60000
            AND set_process_id = xset_id
            AND not exists (select mp1.organization_id
                            from mtl_parameters mp1
                            where miri.organization_id = mp1.master_organization_id);

            --Creating Master Items
            ret_code_create := INVPOPIF.inopinp_OI_process_create (
                                   NULL
                                  ,1
                                  ,val_item_flag
                                  ,pro_item_flag
                                  ,del_rec_flag
                                  ,prog_appid
                                  ,prog_id
                                  ,request_id
                                  ,user_id
                                  ,login_id
                                  ,err_text
                                  ,xset_id
                                  ,commit_flag);

            UPDATE mtl_system_items_interface msii
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag > 60000
            AND set_process_id = xset_id;

            UPDATE mtl_item_revisions_interface
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag > 60000
            AND set_process_id = xset_id;
         END IF;

         --Master item records are processed above, now time for childs
         --All master records will be having process flag as 3, 7.
         --We need to check only for REMAINING records with process flag in 1,4

         OPEN  c_interface_items(cp_transaction_type => 'CREATE');
         FETCH c_interface_items INTO mtl_count;
         CLOSE c_interface_items;

         OPEN  c_interface_revs(cp_transaction_type => 'CREATE');
         FETCH c_interface_revs INTO mtli_count;
         CLOSE c_interface_revs;

         /*  Added the below If condition so that if no records are present in the
             interface table for creating child org Items then we can skip calling of
             inopinp_OI_process_create for the child org */

         IF (mtl_count <> 0 or mtli_count <> 0) THEN
            --Creating Child Items
            ret_code_create := INVPOPIF.inopinp_OI_process_create (
                                  NULL,
                                  1,
                                  val_item_flag,
                                  pro_item_flag,
                                  del_rec_flag,
                                  prog_appid,
                                  prog_id,
                                  request_id,
                                  user_id,
                                  login_id,
                                  err_text,
                                  xset_id,
                                  commit_flag);
         END IF;

      ELSE  /* all_org <> 1 */

         --Creating Items under a specific org.
         OPEN  c_interface_items(cp_transaction_type => 'CREATE');
         FETCH c_interface_items INTO mtl_count;
         CLOSE c_interface_items;

         OPEN  c_interface_revs(cp_transaction_type => 'CREATE');
         FETCH c_interface_revs INTO mtli_count;
         CLOSE c_interface_revs;

         IF (mtl_count <> 0 or mtli_count <> 0) THEN
            ret_code_create := INVPOPIF.inopinp_OI_process_create (
                               org_id,
                               all_org,
                               val_item_flag,
                               pro_item_flag,
                               del_rec_flag,
                               prog_appid,
                               prog_id,
                               request_id,
                               user_id,
                               login_id,
                               err_text,
                               xset_id,
                               commit_flag);
         END IF;
      END IF;  --}

      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag - 30000
      WHERE transaction_type IN ('UPDATE','SYNC') --3018673
      AND process_flag > 30000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag - 30000
      WHERE transaction_type IN ('UPDATE','SYNC') --3018673
      AND process_flag > 30000
      AND set_process_id = xset_id;

   END IF;

   IF (run_mode IN (2,3)) THEN    /* transaction_type IN  'UPDATE' 'SYNC' */

      l_processed_flag := TRUE;

      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag + 30000
      WHERE transaction_type IN ('CREATE','SYNC') --3018673
      AND process_flag < 30000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag + 30000
      WHERE transaction_type IN ('CREATE','SYNC') --3018673
      AND process_flag < 30000
      AND set_process_id = xset_id;

      IF (all_org = 1) THEN  --{

         OPEN  c_master_items(cp_transaction_type=>'UPDATE');
         FETCH c_master_items INTO mtl_count;
         CLOSE c_master_items;

         OPEN  c_master_revs(cp_transaction_type=>'UPDATE');
         FETCH c_master_revs INTO mtli_count;
         CLOSE c_master_revs;

         IF (mtl_count <> 0 or mtli_count <> 0) THEN

            UPDATE mtl_system_items_interface msii
            SET process_flag = process_flag + 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag < 60000
            AND set_process_id = xset_id
            AND not exists (select mp1.organization_id
                            from mtl_parameters mp1
                            where msii.organization_id = mp1.master_organization_id);

            UPDATE mtl_item_revisions_interface miri
            SET process_flag = process_flag + 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag < 60000
            AND set_process_id = xset_id
            AND not exists (select mp1.organization_id
                            from mtl_parameters mp1
                            where miri.organization_id = mp1.master_organization_id);

            --Update master Items.
            ret_code_update := INVPOPIF.inopinp_OI_process_update (
                                  NULL,
                                  1,
                                  val_item_flag,
                                  pro_item_flag,
                                  del_rec_flag,
                                  prog_appid,
                                  prog_id,
                                  request_id,
                                  user_id,
                                  login_id,
                                  err_text,
                                  xset_id,
                                  commit_flag);

            UPDATE mtl_system_items_interface msii
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag > 60000
            AND set_process_id = xset_id;

            UPDATE mtl_item_revisions_interface
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag > 60000
            AND set_process_id = xset_id;

         END IF;

         --Master item records are processed above, now time for childs
         --All master records will have process flag as 3, 7.
         --We need to check only for REMAINING records with process flag in 1,4

         OPEN  c_interface_items(cp_transaction_type => 'UPDATE');
         FETCH c_interface_items INTO mtl_count;
         CLOSE c_interface_items;

         OPEN  c_interface_revs(cp_transaction_type => 'UPDATE');
         FETCH c_interface_revs INTO mtli_count;
         CLOSE c_interface_revs;

         IF (mtl_count <> 0 or mtli_count <> 0) THEN
            --Updating the child records.
            ret_code_update := INVPOPIF.inopinp_OI_process_update (
                                  NULL,
                                  1,
                                  val_item_flag,
                                  pro_item_flag,
                                  del_rec_flag,
                                  prog_appid,
                                  prog_id,
                                  request_id,
                                  user_id,
                                  login_id,
                                  err_text,
                                  xset_id,
                                  commit_flag);
         END IF;

      ELSE  -- all_org <> 1
         --Update only org specific items
         OPEN  c_interface_items(cp_transaction_type => 'UPDATE');
         FETCH c_interface_items INTO mtl_count;
         CLOSE c_interface_items;

         OPEN  c_interface_revs(cp_transaction_type => 'UPDATE');
         FETCH c_interface_revs INTO mtli_count;
         CLOSE c_interface_revs;

         IF (mtl_count <> 0 or mtli_count <> 0) THEN
            ret_code_update := INVPOPIF.inopinp_OI_process_update (
                        org_id,
                        all_org,
                        val_item_flag,
                        pro_item_flag,
                        del_rec_flag,
                        prog_appid,
                        prog_id,
                        request_id,
                        user_id,
                        login_id,
                        err_text,
                        xset_id,
                        commit_flag);
         END IF;

      END IF;  --}

      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag - 30000
      WHERE transaction_type IN ('CREATE','SYNC') --3018673
      AND process_flag > 30000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag - 30000
      WHERE transaction_type IN ('CREATE','SYNC') --3018673
      AND process_flag > 30000
      AND set_process_id = xset_id;

   END IF;  --}

   --3018673: Start of bug fix.
   IF run_mode = 3 THEN

      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag - 20000
      WHERE transaction_type IN ('CREATE','UPDATE')
      AND process_flag > 20000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag - 20000
      WHERE transaction_type  IN ('CREATE','UPDATE')
      AND process_flag > 20000
      AND set_process_id = xset_id;

   END IF;
   --3018673: End of bug fix.

   IF NOT l_processed_flag THEN
      ret_code := 1;
   END IF;

   --Start : Sync iM index changes
 --  IF commit_flag = 1 THEN
 --     INV_ITEM_PVT.SYNC_IM_INDEX;
 --  END IF;
   --End : Sync iM index changes

   --Raise events for EGO Bulk Load and Excel Import
   --Bug: 5350459 Added AND clause to prevent bulk load event from
   --             firing multiple times.
   IF (request_id <> -1
       AND ((INSTR(INV_EGO_REVISION_VALIDATE.Get_Process_Control,'EGO_BULK_LOAD') <> 0)
             OR (INV_EGO_REVISION_VALIDATE.Get_Process_Control IS NULL))) THEN
      -- Raise for IOI and EGO Bulkload both
      BEGIN
         INV_ITEM_EVENTS_PVT.Raise_Events(
                p_request_id    => request_id
               ,p_xset_id       => xset_id
               ,p_event_name    => 'EGO_WF_WRAPPER_PVT.G_ITEM_BULKLOAD_EVENT'
               ,p_dml_type      => 'BULK');
      EXCEPTION
         WHEN OTHERS THEN
            err_msg := SUBSTR('INVPOPIF: Error:' ||SQLERRM ||' while raising Item Change Event',1,240);
            INVPUTLI.info(err_msg);
      END;

      --Raise for revision bulkload also
      BEGIN
         INV_ITEM_EVENTS_PVT.Raise_Events(
             p_request_id    => request_id
            ,p_xset_id       => xset_id
            ,p_event_name    => 'EGO_WF_WRAPPER_PVT.G_REV_CHANGE_EVENT'
            ,p_dml_type      => 'BULK');

         INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Raised Revision Bulkload Event');

      EXCEPTION
         WHEN OTHERS THEN
            err_msg := SUBSTR('INVPOPIF: Error:' ||SQLERRM ||' while raising REV Change Event',1,240);
            INVPUTLI.info(err_msg);
      END;
   END IF; -- (request_id <> -1 )

   --Bug: 5219928 Delete records procedure call moved here as BEs are raised by checking status 7 records
   IF (del_rec_flag = 1) THEN
      INVPUTLI.info('INVPOPIF.inopinp_OI_process: calling INVPOPIF.indelitm_delete_item_oi');

      ret_code := INVPOPIF.indelitm_delete_item_oi (err_text => err_msg,
                                                    com_flag => commit_flag,
                                                    xset_id  => xset_id);

      INVPUTLI.info('INVPOPIF.inopinp_OI_process: done INVPOPIF.indelitm_delete_item_oi: ret_code=' || ret_code);
   END IF;


   --
   -- Process Item Category Open Interface records
   --

   INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: calling INV_ITEM_CATEGORY_OI.process_Item_Category_records');

   INV_ITEM_CATEGORY_OI.process_Item_Category_records
   (
      ERRBUF              =>  err_text
   ,  RETCODE             =>  ret_code
   ,  p_rec_set_id        =>  xset_id
   ,  p_upload_rec_flag   =>  pro_item_flag
   ,  p_delete_rec_flag   =>  del_rec_flag
   ,  p_commit_flag       =>  commit_flag
   ,  p_prog_appid        =>  prog_appid
   ,  p_prog_id           =>  prog_id
   ,  p_request_id        =>  request_id
   ,  p_user_id           =>  user_id
   ,  p_login_id          =>  login_id
   );

   INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: done INV_ITEM_CATEGORY_OI.process_Item_Category_records: ret_code=' || ret_code);

   /* SET return code to that of last error, IF any */

   IF (ret_code_create <> 0) THEN
      ret_code := ret_code_create;
   END IF;

   IF (ret_code_update <> 0) THEN
      ret_code := ret_code_update;
   END IF;

   --
   -- Process Item Catalog group element values open Interface records
   --

   INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: calling INV_ITEM_CATALOG_ELEM_PUB.process_Item_Catalog_grp_recs');

   INV_ITEM_CATALOG_ELEM_PUB.process_Item_Catalog_grp_recs
   (
      ERRBUF              =>  err_text
   ,  RETCODE             =>  ret_code_grp
   ,  p_rec_set_id        =>  xset_id
   ,  p_upload_rec_flag   =>  pro_item_flag
   ,  p_delete_rec_flag   =>  del_rec_flag
   ,  p_commit_flag       =>  commit_flag
   ,  p_prog_appid        =>  prog_appid
   ,  p_prog_id           =>  prog_id
   ,  p_request_id        =>  request_id
   ,  p_user_id           =>  user_id
   ,  p_login_id          =>  login_id
   );

   INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: done INV_ITEM_CATALOG_ELEM_PUB.process_Item_Catalog_grp_recs: ret_code=' || ret_code_grp);

   IF (ret_code_grp <> 0) THEN
      ret_code := ret_code_grp;
   END IF;

   RETURN (ret_code);

END inopinp_open_interface_process;


--------------------------- inopinp_OI_process_update -------------------------

FUNCTION inopinp_OI_process_update
(
    org_id      NUMBER,
    all_org     NUMBER  := 1,
    val_item_flag   NUMBER  := 1,
    pro_item_flag   NUMBER  := 1,
    del_rec_flag    NUMBER  := 1,
    prog_appid  NUMBER  := -1,
    prog_id     NUMBER  := -1,
    request_id  NUMBER  := -1,
    user_id     NUMBER  := -1,
    login_id    NUMBER  := -1,
    err_text    IN OUT  NOCOPY VARCHAR2,
    xset_id     IN  NUMBER  DEFAULT -999,
    commit_flag IN  NUMBER  DEFAULT 1
)
RETURN INTEGER
IS
   ret_code      NUMBER         :=  1;
   err_msg       VARCHAR2(300);
   err_msg_name  VARCHAR2(30);
   table_name    VARCHAR2(30);

   dumm_status     NUMBER;
   Logging_Err     EXCEPTION;

   l_return_status            VARCHAR2(1);
   l_msg_count                NUMBER;
   l_msg_data                 VARCHAR2(2000);
BEGIN

   INVPUTLI.info('INVPOPIF.inopinp_OI_process_update : begin org_id: ' || TO_CHAR(org_id));

    IF (val_item_flag = 1) THEN

       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INVUPD1B.mtl_pr_assign_item_data_update');

       ret_code := INVUPD1B.mtl_pr_assign_item_data_update (
                        org_id => org_id,
                        all_org => all_org,
                        prog_appid => prog_appid,
                        prog_id => prog_id,
                        request_id => request_id,
                        user_id => user_id,
                        login_id => login_id,
                        err_text => err_msg,
                        xset_id => xset_id);

       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: done INVUPD1B.mtl_pr_assign_item_data_update: ret_code=' || ret_code);

       IF (ret_code <> 0) THEN
          err_msg := 'INVPOPIF.inopinp_OI_process_update: error in ASSIGN phase of UPDATE;' ||
                     ' Please check mtl_interface_errors table ' || err_msg;
          goto ERROR_LABEL;
       END IF;

       IF (commit_flag = 1) THEN
          commit;
       END IF;
--Bug:3777954 added call to new pkg/processing for NIR required items (for EGO)
      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVNIRIS.mtl_validate_nir_item');

      ret_code := INVNIRIS.mtl_validate_nir_item (
               org_id => org_id,
               all_org => all_org,
               prog_appid => prog_appid,
               prog_id => prog_id,
               request_id => request_id,
               user_id => user_id,
               login_id => login_id,
               err_text => err_msg,
               xset_id => xset_id);

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVNIRIS.mtl_validate_nir_item: ret_code=' || ret_code || ' err_msg=' || err_msg);

      IF (ret_code <> 0) THEN
         err_msg := 'INVPOPIF.inopinp_OI_process_create: error in NIR ASSIGN phase of UPDATE;' ||
                   ' Please check mtl_interface_errors table ' || err_msg;
         goto ERROR_LABEL;
      END IF;

      IF (commit_flag = 1) THEN
         commit;
      END IF;
--Bug:3777954 call ends

       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INVUPD1B.mtl_pr_validate_item_update');

       ret_code := INVUPD1B.mtl_pr_validate_item_update (
                        org_id => org_id,
                        all_org => all_org,
                        prog_appid => prog_appid,
                        prog_id => prog_id,
                        request_id => request_id,
                        user_id => user_id,
                        login_id => login_id,
                        err_text => err_msg,
                        xset_id => xset_id);

       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: done INVUPD1B.mtl_pr_validate_item_update: ret_code=' || ret_code);

       IF (ret_code <> 0) THEN
          err_msg := 'INVPOPIF.inopinp_OI_process_update: error in VALIDATE phase of UPDATE;' ||
                     ' Please check mtl_interface_errors table ' || err_msg;
          goto ERROR_LABEL;
       END IF;

       IF (commit_flag = 1) THEN
          commit;
       END IF;

    END IF;  /* validate_item_flag = 1 */

    IF (pro_item_flag = 1) THEN

       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INVUPD2B.inproit_process_item_update');

       ret_code := INVUPD2B.inproit_process_item_update (
                        prg_appid => prog_appid,
                        prg_id => prog_id,
                        req_id => request_id,
                        user_id => user_id,
                        login_id => login_id,
                        error_message => err_msg,
                        message_name => err_msg_name,
                        table_name => table_name,
                        xset_id => xset_id);

       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: done INVUPD2B.inproit_process_item_update: ret_code=' || ret_code);

       IF (ret_code <> 0) THEN
          err_msg := 'INVPOPIF.inopinp_OI_process_update: error in PROCESS phase of UPDATE;' ||
                     ' Please check mtl_interface_errors table ' || err_msg;

          IF (commit_flag = 1) THEN
             rollback;
          END IF;

          goto ERROR_LABEL;
       END IF;

       IF (commit_flag = 1) THEN
          commit;
       END IF;

       --
       -- Sync processed rows with item star table
       --

       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INV_ENI_ITEMS_STAR_PKG.Sync_Star_Items_From_IOI');

       --Bug: 2718703 checking for ENI product before calling their package
       --This check has been moved to INV_ENI_ITEMS_STAR_PKG

       INV_ENI_ITEMS_STAR_PKG.Sync_Star_Items_From_IOI(
          p_api_version         =>  1.0
         ,p_init_msg_list       =>  FND_API.g_TRUE
         ,p_set_process_id      =>  xset_id
         ,x_return_status       =>  l_return_status
         ,x_msg_count           =>  l_msg_count
         ,x_msg_data            =>  l_msg_data);


       IF ( l_return_status = FND_API.g_RET_STS_SUCCESS ) THEN
          IF ( commit_flag = 1 ) THEN
             commit;
          END IF;
       ELSE
          dumm_status := INVPUOPI.mtl_log_interface_err (
                                ORG_ID        => -1,
                                USER_ID       =>user_id,
                                LOGIN_ID      =>login_id,
                                PROG_APPID    =>prog_appid,
                                PROG_ID       =>prog_id,
                                REQ_ID        =>request_id,
                                TRANS_ID      =>-1,
                                ERROR_TEXT    =>l_msg_data,
                                P_COLUMN_NAME =>NULL,
                                TBL_NAME      =>'ENI_OLTP_ITEM_STAR',
                                MSG_NAME      =>'INV_IOI_ERR',
                                ERR_TEXT      =>err_text);

          if ( dumm_status < 0 ) then
             RAISE Logging_Err;
          end if;
       END IF;

    END IF;  /* pro_item_flag = 1 */

    /*Bug: 5219928 indelitm call moved to main loop*/

    IF (commit_flag = 1) THEN
       commit;
    END IF;


   RETURN (0);

<<ERROR_LABEL>>

    err_text := SUBSTR(err_msg, 1,240);

    IF (commit_flag = 1) THEN
       commit;
    END IF;

    RETURN (ret_code);

EXCEPTION

   WHEN Logging_Err THEN
      RETURN (dumm_status);

   WHEN OTHERS THEN
      err_text := substr('INVPOPIF.inopinp_OI_process_update ' || SQLERRM , 1,240);
      INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: About to rollback.');

      ROLLBACK;

      RETURN (ret_code);

END inopinp_OI_process_update;


--------------------------- inopinp_OI_process_create -------------------------

FUNCTION inopinp_OI_process_create
(
    org_id      NUMBER,
    all_org     NUMBER      := 1,
    val_item_flag   NUMBER      := 1,
    pro_item_flag   NUMBER      := 1,
    del_rec_flag    NUMBER      := 1,
    prog_appid      NUMBER      := -1,
    prog_id     NUMBER      := -1,
    request_id      NUMBER      := -1,
    user_id     NUMBER      := -1,
    login_id        NUMBER      := -1,
    err_text     IN OUT NOCOPY VARCHAR2,
    xset_id      IN     NUMBER       DEFAULT -999,
    commit_flag  IN     NUMBER       DEFAULT 1
)
RETURN INTEGER
IS
    CURSOR Error_Items IS
         SELECT transaction_id, organization_id
           FROM mtl_system_items_interface
          WHERE process_flag = 4
            AND set_process_id = xset_id
            AND transaction_type = 'CREATE';

    err_msg_name    VARCHAR2(30);
    err_msg         VARCHAR2(300);  /* increased from 80 */
    table_name      VARCHAR2(30);
    ret_code       NUMBER := 1;

    wrong_recs     NUMBER := 0;
    create_recs    NUMBER := 0;
    update_recs    NUMBER := 0;
    p_flag         NUMBER := 0;

    l_transaction_type  VARCHAR2(10)  :=  'CREATE';

   dumm_status     NUMBER;
   Logging_Err     EXCEPTION;

   l_return_status            VARCHAR2(1);
   l_msg_count                NUMBER;
   l_msg_data                 VARCHAR2(2000);

BEGIN

   INVPUTLI.info('INVPOPIF.inopinp_OI_process_create : begin org_id: ' || TO_CHAR(org_id));

   IF (commit_flag = 1) THEN
      commit;
   END IF;

   IF (val_item_flag = 1) THEN

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVPASGI.mtl_pr_assign_item_data');

      ret_code := INVPASGI.mtl_pr_assign_item_data (
               org_id => org_id,
               all_org => all_org,
               prog_appid => prog_appid,
               prog_id => prog_id,
               request_id => request_id,
               user_id => user_id,
               login_id => login_id,
               err_text => err_msg,
               xset_id => xset_id);

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: done INVPASGI.mtl_pr_assign_item_data: ret_code=' || ret_code || ' err_msg=' || err_msg);

      IF (ret_code <> 0) THEN
         err_msg := 'INVPOPIF.inopinp_OI_process_create: error in ASSIGN phase of CREATE;' ||
                   ' Please check mtl_interface_errors table ' || err_msg;
         goto ERROR_LABEL;
      END IF;

      IF (commit_flag = 1) THEN
         commit;
      END IF;
--Bug:3777954 added call to new pkg/processing for NIR required items (for EGO)
      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVNIRIS.mtl_validate_nir_item');

      ret_code := INVNIRIS.mtl_validate_nir_item (
               org_id => org_id,
               all_org => all_org,
               prog_appid => prog_appid,
               prog_id => prog_id,
               request_id => request_id,
               user_id => user_id,
               login_id => login_id,
               err_text => err_msg,
               xset_id => xset_id);

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVNIRIS.mtl_validate_nir_item: ret_code=' || ret_code || ' err_msg=' || err_msg);

      IF (ret_code <> 0) THEN
         err_msg := 'INVPOPIF.inopinp_OI_process_create: error in NIR ASSIGN phase of CREATE;' ||
                   ' Please check mtl_interface_errors table ' || err_msg;
         goto ERROR_LABEL;
      END IF;

      IF (commit_flag = 1) THEN
         commit;
      END IF;
--Bug:3777954 call ends

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVPVALI.mtl_pr_validate_item');

      ret_code := INVPVALI.mtl_pr_validate_item (
               org_id => org_id,
               all_org => all_org,
               prog_appid => prog_appid,
               prog_id => prog_id,
               request_id => request_id,
               user_id => user_id,
               login_id => login_id,
               err_text => err_msg,
               xset_id => xset_id);

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: done INVPVALI.mtl_pr_validate_item: ret_code=' || ret_code || ' err_msg=' || err_msg);

      IF (ret_code <> 0) THEN
         err_msg := 'INVPOPIF.inopinp_OI_process_create: error in VALIDATE phase of CREATE;'||
                   ' Please check mtl_interface_errors table ' || err_msg;
         goto ERROR_LABEL;
      END IF;

      IF (commit_flag = 1) THEN
         commit;
      END IF;

   END IF;  -- val_item_flag = 1


   IF (pro_item_flag = 1) THEN

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVPPROC.inproit_process_item');


      ret_code := INVPPROC.inproit_process_item (
                     prg_appid => prog_appid,
                     prg_id => prog_id,
                     req_id => request_id,
                     user_id => user_id,
                     login_id => login_id,
                     error_message => err_msg,
                     message_name => err_msg_name,
                     table_name => table_name,
                     xset_id => xset_id,
             p_commit => commit_flag     -- Added for Bug-6061280
                  );

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: done INVPPROC.inproit_process_item: ret_code=' || ret_code);

      IF (ret_code <> 0) THEN

       --Bug 4767919 Anmurali
         FOR ee in Error_Items LOOP

           dumm_status := INVPUOPI.mtl_log_interface_err(
                                    ee.organization_id,
                                    user_id,
                                    login_id,
                                    prog_appid,
                                    prog_id,
                                    request_id,
                                    ee.transaction_id,
                                    err_msg,
                                   'INVENTORY_ITEM_ID',
                                   'MTL_SYSTEM_ITEMS_INTERFACE',
                                   'INV_IOI_ERR',
                                    err_msg);
     END LOOP;

         UPDATE mtl_system_items_interface
            SET process_flag = 3
          WHERE process_flag = 4
            AND set_process_id = xset_id
            AND transaction_type = 'CREATE';

         err_msg := 'INVPOPIF.inopinp_OI_process_create: error in PROCESS phase of CREATE;'||
                    ' Please check mtl_interface_errors table ' || err_msg;

         IF (commit_flag = 1) THEN
            rollback;
         END IF;

         goto ERROR_LABEL;
      END IF;

      IF (commit_flag = 1) THEN
         commit;
      END IF;

      --
      -- Sync processed rows with item star table
      --

      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INV_ENI_ITEMS_STAR_PKG.Sync_Star_Items_From_IOI');

      --Bug: 2718703 checking for ENI product before calling their package
      --This check has been moved to INV_ENI_ITEMS_STAR_PKG

      INV_ENI_ITEMS_STAR_PKG.Sync_Star_Items_From_IOI(
          p_api_version         =>  1.0
         ,p_init_msg_list       =>  FND_API.g_TRUE
         ,p_set_process_id      =>  xset_id
         ,x_return_status       =>  l_return_status
         ,x_msg_count           =>  l_msg_count
         ,x_msg_data            =>  l_msg_data);

      IF ( l_return_status = FND_API.g_RET_STS_SUCCESS ) THEN
         IF ( commit_flag = 1 ) THEN
            commit;
         END IF;
      ELSE
          dumm_status := INVPUOPI.mtl_log_interface_err (
                                ORG_ID        => -1,
                                USER_ID       =>user_id,
                                LOGIN_ID      =>login_id,
                                PROG_APPID    =>prog_appid,
                                PROG_ID       =>prog_id,
                                REQ_ID        =>request_id,
                                TRANS_ID      =>-1,
                                ERROR_TEXT    =>l_msg_data,
                                P_COLUMN_NAME =>NULL,
                                TBL_NAME      =>'ENI_OLTP_ITEM_STAR',
                                MSG_NAME      =>'INV_IOI_ERR',
                                ERR_TEXT      =>err_text);

         if ( dumm_status < 0 ) then
            RAISE Logging_Err;
         end if;
      END IF;
   END IF;  -- pro_item_flag = 1

   /*Bug: 5219928 indelitm call moved to main loop*/

   IF (commit_flag = 1) THEN
      commit;
   END IF;

   RETURN (0);

<<ERROR_LABEL>>

    err_text := SUBSTRB(err_msg, 1,240);

    IF (commit_flag = 1) THEN
       commit;
    END IF;

    RETURN (ret_code);

EXCEPTION

-- Parameter ret_code is defaulted to 1,  which is passed
-- back for oracle error in UPDATE st.

   WHEN Logging_Err THEN
      RETURN (dumm_status);

   WHEN others THEN
      err_text := substr('INVPOPIF.inopinp_OI_process_create ' || SQLERRM , 1,240);
      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: About to rollback.');

      ROLLBACK;

      RETURN (ret_code);

END inopinp_OI_process_create;


---------------------------- indelitm_delete_item_oi --------------------------

FUNCTION indelitm_delete_item_oi
(
   err_text    OUT    NOCOPY VARCHAR2,
   com_flag    IN     NUMBER  DEFAULT  1,
   xset_id     IN     NUMBER  DEFAULT  -999
)
RETURN INTEGER
IS
   stmt_num          NUMBER;
   l_process_flag_7  NUMBER  :=  7;
   l_rownum          NUMBER  :=  100000;
BEGIN

   INVPUTLI.info('INVPOPIF.indelitm_delete_item_oi: begin');
   stmt_num := 1;

LOOP
   DELETE FROM MTL_SYSTEM_ITEMS_INTERFACE
   WHERE process_flag = l_process_flag_7
   AND set_process_id in (xset_id, xset_id + 1000000000000)
   AND rownum < l_rownum;

   EXIT WHEN SQL%NOTFOUND;

   IF com_flag = 1 THEN
      commit;
   END IF;
END LOOP;

stmt_num := 2;


LOOP
   DELETE FROM MTL_ITEM_REVISIONS_INTERFACE
   WHERE PROCESS_FLAG = l_process_flag_7
   AND set_process_id = xset_id
   AND rownum < l_rownum;

   EXIT WHEN SQL%NOTFOUND;

   IF com_flag = 1 THEN
      commit;
   END IF;
END LOOP;


   INVPUTLI.info('INVPOPIF.indelitm_delete_item_oi: end');

   RETURN (0);

EXCEPTION

    WHEN OTHERS THEN
        err_text := SUBSTR('INVPOPIF.indelitm_delete_item_oi(' || stmt_num || ')' || SQLERRM, 1,240);
        RETURN (SQLCODE);

END indelitm_delete_item_oi;

--SYNC: IOI to support SYNC operation.
PROCEDURE UPDATE_SYNC_RECORDS(p_set_id  IN  NUMBER) IS

   CURSOR c_items_table IS
     SELECT rowid
           ,organization_id
           ,inventory_item_id
           ,segment1
           ,segment2
           ,segment3
           ,segment4
           ,segment5
           ,segment6
           ,segment7
           ,segment8
           ,segment9
           ,segment10
           ,segment11
           ,segment12
           ,segment13
           ,segment14
           ,segment15
           ,segment16
           ,segment17
           ,segment18
           ,segment19
           ,segment20
           ,item_number
           ,transaction_id
           ,transaction_type
     FROM   mtl_system_items_interface
     WHERE  set_process_id   = p_set_id
     AND    process_flag     = 1
     AND    transaction_type = 'SYNC'
     FOR UPDATE OF transaction_type;

   CURSOR c_revision_table IS
     SELECT  rowid
            ,organization_id
            ,inventory_item_id
            ,item_number
            ,revision_id
            ,revision
            ,transaction_id
            ,transaction_type
     FROM   mtl_item_revisions_interface
     WHERE  set_process_id   = p_set_id
     AND    process_flag     = 1
     AND    transaction_type = 'SYNC'
     FOR UPDATE OF transaction_type;

   CURSOR c_item_exists(cp_item_id NUMBER) IS
     SELECT  1
     FROM   mtl_system_items_b
     WHERE  inventory_item_id = cp_item_id;

   CURSOR c_revision_exists(cp_item_id   NUMBER,
                            cp_rev_id    NUMBER,
                            cp_revision  VARCHAR) IS
     SELECT  1
     FROM   mtl_item_revisions
     WHERE  inventory_item_id = cp_item_id
     AND    (revision_id      = cp_rev_id
             OR revision      = cp_revision);


   l_item_exist NUMBER(10) := 0;
   l_err_text   VARCHAR2(200);
   l_rev_exist  NUMBER(10) := 0;
   l_status      NUMBER(10):= 0;
   l_item_id    mtl_system_items_b.inventory_item_id%TYPE;

BEGIN

   FOR item_record IN c_items_table LOOP
      l_item_exist :=0;
      l_item_id    := NULL;

      IF item_record.inventory_item_id IS NULL THEN
         IF item_record.item_number IS NOT NULL THEN
            l_status  := INVPUOPI.MTL_PR_PARSE_ITEM_NUMBER(
                            ITEM_NUMBER =>item_record.item_number
               ,ITEM_ID     =>item_record.inventory_item_id
               ,TRANS_ID    =>item_record.transaction_id
               ,ORG_ID      =>item_record.organization_id
               ,ERR_TEXT    =>l_err_text
               ,P_ROWID     =>item_record.rowid);
         END IF;
         l_item_exist := INVUPD1B.EXISTS_IN_MSI(
                 ROW_ID      => item_record.rowid
                ,ORG_ID      => item_record.organization_id
                ,INV_ITEM_ID => l_item_id
                ,TRANS_ID    => item_record.transaction_id
                ,ERR_TEXT    => l_err_text
                ,XSET_ID     => p_set_id);
      ELSE
         l_item_id := item_record.inventory_item_id;
         OPEN  c_item_exists(item_record.inventory_item_id);
     FETCH c_item_exists INTO l_item_exist;
     CLOSE c_item_exists;
     l_item_exist := NVL(l_item_exist,0);
      END IF;

      IF l_item_exist = 1 THEN
         UPDATE mtl_system_items_interface
     SET    transaction_type  = 'UPDATE'
     WHERE  rowid = item_record.rowid;
      ELSE
         UPDATE mtl_system_items_interface
     SET    transaction_type = 'CREATE'
     WHERE  rowid = item_record.rowid;
      END IF;

   END LOOP;

   FOR revision_record IN c_revision_table LOOP
      l_rev_exist  := 0;
      l_item_id    := NULL;

      IF revision_record.inventory_item_id IS NOT NULL THEN
         l_item_id := revision_record.inventory_item_id;
      ELSIF revision_record.item_number is NOT NULL THEN
     l_status := INVPUOPI.mtl_pr_parse_flex_name (
                         revision_record.organization_id
                        ,'MSTK'
            ,revision_record.item_number
                        ,l_item_id
                        ,0
                        ,l_err_text);
      END IF;

      OPEN c_revision_exists(cp_item_id  => l_item_id,
                             cp_rev_id   => revision_record.revision_id,
                             cp_revision => revision_record.revision);
      FETCH c_revision_exists INTO l_rev_exist;
      CLOSE c_revision_exists;
      l_rev_exist := NVL(l_rev_exist,0);

      IF l_rev_exist = 1  THEN
         UPDATE mtl_item_revisions_interface
     SET    transaction_type  = 'UPDATE'
     WHERE rowid = revision_record.rowid;
      ELSE
         UPDATE mtl_item_revisions_interface
     SET    transaction_type  = 'CREATE'
     WHERE rowid = revision_record.rowid;
      END IF;
   END LOOP;

END UPDATE_SYNC_RECORDS;
--End SYNC: IOI to support SYNC operation.

END INVPOPIF;
/