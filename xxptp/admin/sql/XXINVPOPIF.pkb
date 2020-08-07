/*==========================================================================+
|   Copyright (c) 1993, 2014 Oracle Corporation Belmont, California, USA          |
|                          All rights reserved.                             |
+===========================================================================+
|
| FILE:
|   INVPOPIB.pls
|
| DESCRIPTION:
|   This is the main package used to validate and process items
|   through the Open Interface.
|
| PARAMETERS:
|       org_id      organization_id
|       all_org     process all orgs or just current org
|               1 - all orgs
|               2 - only org_id
|       val_item_flag   validate items
|       pro_item_flag   process validated items
|       del_rec_flag    delete processed rows
|           prog_appid      program application_id
|           prog_id     program id
|           request_id      request_id
|           user_id     user id
|           login_id    login id
|               xset_id         For set processing
|               commit_flag     1 for commit
|                               2 for commitless
| Return:   1 if success
|       SQLCODE if failure
|
| HISTORY:
|    05/02/94   Shreyas Shah    creation date
|    08/01/94   Nilesh Parate   ownership taken over from Jchaney
|    10/26/94   Nilesh Parate   Changed length of error messages to 90
|    01/06/95   Nilesh Parate   Made deletions totally independent
|                                of pro_item_flag
|    04/09/95   Nilesh Parate   Fix for bug 274707: set process
|                               flag to -888 for
|                               records in MSII which do not have
|                               transaction_type  = 'CREATE'(in any CASE).
|    04/18/96   Nilesh Parate   err_msg length increased to 300
|                               New message to catch  error in ASSIGN phase
|                               This phase is before first commit,
|                                 when nothing has yet been
|                                 committed to mtl_interface_errors.
|    04/23/96   Nilesh Parate   Added xset_id, commit flag
|                               commit_flag needed to support commitless
|                               operation required by EDI group.
|    14-DEC-00   anakas         Implemented Item Category Open Interface
|                         functionality via the package INV_ITEM_CATEGORY_OI.
|   08/10/02  anakas             Ehancement 2430813: added calls to maintain
|                                DBi Item dimension STAR table.
|   07-JAN-03  Rathna Vuppala   Bug: 2718703 Replaced the ENI_ITEM_STAR_PKG
|                               Calls with EXECUTE IMMIDIATE
|   13-Jan-03  Murthy A         Bug: 2728939 Calling add grant if EGO is installed
|   04-Apr-03  Murthy A         Bug: 2808277 Supporting Item Revision Update
|   14-May-03  Murthy A         SYNC support in IOI.
|   05-May-03  Murthy A         Added call to EGO_USER_ATTRS_DATA_PUB
|   18-Jun-03  Murthy A         Sync iM index changes
|   24-Jun-03  Murthy A         3018673: For CREATE transaction type CREATE interface records
|                               only should be picked up. Similarly for UPDATE and SYNC
|   26-Jun-03  Dylan A          Worked with Wasi to replace call to EGO_USER_ATTRS_DATA_PUB
|                               with a call to EGO_ITEM_PUB (for bug 3013736)
|   09-Jul-03  Rathna Vuppala   Bug: 3033702 Moved the EGO related calls to INVEGRVB
|   08-Dec-03  Rathna Vuppala   Implemented Item Catalog group elements
|                               Open Interface functionality via the package
|                               INV_ITEM_CATALOG_ELEM_OI.
|   30-Dec-03  Murthy A         Replacing ENI_ITEMS_STAR_PKG with INV_ENI_ITEMS_STAR_PKG
|   19-Feb-04  Murthy A         2698140 : Gather stats before running the IOI
|   12-May-04  Murthy A         3515652: Collect stats only if no. records > 50
|   27-May-04  Murthy A         Run IOI on child records only when necessary.
|   28-May-04  Murthy A         Using cursor to check for interface records.
|   04-Jan-05  Deepti           4105867 : Business Event Enhancement.
|   11-Jan-05  Rathna Vuppala   11.5.10.E.EGO:Bug:3777954 NIR enh.
|   26-Apr-05  Lakshaman        R12: Business Event Enhancement
|   01-Jun-05  Lakshaman             Moving the deletion of interface table records in the
|                                    main process as the subscription code needs these records.
|   15-Jun-05 Lakshaman         Introducing private procedure UPDATE_ITEM_CATALOG_ID
|                                    to populate CATALOG_ID from CATALOG_NAME.
|   05-JUL-05 Lakshaman         Moving the code to populate bulkload table from INVPPROB
|   30-AUG-05 Murthy A          Using >= for setting back 30k,20k,60k process flag records.
|   19-SEP-05 Murthy A          Populating request id from rev's interface and merged update stmts.
|   17-OCT-05 Swapnil           Bug: 4667452 Made calls to INVPUTLI.info conditional
|   18-OCT-05 Lakshaman         Bug: 4667985 Clause the calls to External APIs
|                                 Also moving the eni_items_star_pkg calls to the main loop
|                                 Both the calls are exactly similar calling once from the main
|                                 loop is sufficient as the delete records is already moved there.
|                                 Only call Categories Open Interface if interface table has
|                                  records.
|  18-OCT-05 Murthy A           4682579 : Process SYNC,CREATE,UPDATE records in one go if run_mode = 0
|  05-May-06 Lakshaman          Bug: 5194369 Delete processed rows (7) from the interface table
|                               if the record was created for CM support and a similar row with
|                               process flag 5 exists.
|  05-Jul-06 Lakshaman          Bug: 5333010 Do not check on delete rec flag for committing.
|                               insert into bulkload_recs before raising business event.
|  31-Aug-06 Lakshaman          Bug: 5498078 Value to ID conversion for template_name in revisions interface.
|  15-Sep-06 Murthy A           Bug: 5513065 Including xref import into same transaction context of item+rev
|  19-Apr-07 Anmurali           R12 C In "inopinp_OI_process_create" and "inopinp_OI_process_update", default
|                               calls are removed from the val_item_flag = 1 check
|  19-Apr-07 Anmurali           R12 C Enabling Defaulting and Validation as seperate processes
|                               "inopinp_open_interface_process" will now pick up records in proc flag 2
|  18-May-07 Anmurali           R12C UT : NIR Required setup definition to be obtained from parent catalogs 
|                               for hierarchy enabled catalogs
|  18-Jun-07 Anmurali           R12C During Import "process_Item_Category_records" and "process_Item_Catalog_grp_recs" 
|                               called once for validation and once for processing
|  27-Jun-07 Lakshaman          Bug: 6139403 Do not raise business event for fake ITEM row.
|  24-Jul-07 Lakshaman          Bug: 6158936 Debugged c_interface_rows cursor.
|  25-Sep-07 Lakshaman          Bug: 6417028 IOI supports item number update.
|  23-Oct-07 Murthy A           Bug : 6521101 - Pending status updation for master recs only
|  23-Jan-08 kdevadas           Bug 6200383 Added one more parameter cp_org_id to the 
|				cursor c_revision_exists 
|  21-DEC-09 nendrapu		ER-9092888
|  01-Aug-16 Paddy Sanjeevi     Retrofitted for R12.2.5
+=============================================================================================*/

REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.45.12010000.17=120.61)(120.30.12000000.2=120.31)(115.56=120.3):~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY INVPOPIF AS
/* $Header: INVPOPIB.pls 120.67.12020000.4 2014/06/25 05:17:51 yingyang ship $ */
---------------------- Package variables and constants -----------------------

G_PKG_NAME       CONSTANT  VARCHAR2(30)  :=  'INVPOPIF';

G_SUCCESS          CONSTANT  NUMBER  :=  0;
G_WARNING          CONSTANT  NUMBER  :=  1;
G_ERROR            CONSTANT  NUMBER  :=  2;

------------------------------------------------------------------------------

------------------------ inopinp_open_interface_process -----------------------
PROCEDURE UPDATE_SYNC_RECORDS(p_set_id  IN  NUMBER);
PROCEDURE UPDATE_ITEM_CATALOG_ID(
            p_set_id       IN NUMBER
           ,p_prog_appid   IN NUMBER
           ,p_prog_id      IN NUMBER
           ,p_request_id   IN NUMBER
           ,p_user_id      IN NUMBER
           ,p_login_id     IN NUMBER
           ,x_err_text   IN OUT NOCOPY VARCHAR2);

PROCEDURE VALIDATE_RELEASED_ICC(
            p_set_id       IN NUMBER
           ,p_prog_appid   IN NUMBER
           ,p_prog_id      IN NUMBER
           ,p_request_id   IN NUMBER
           ,p_user_id      IN NUMBER
           ,p_login_id     IN NUMBER
           ,x_err_text   IN OUT NOCOPY VARCHAR2);

PROCEDURE inopinp_open_interface_process(
    ERRBUF           OUT NOCOPY VARCHAR2,
    RETCODE          OUT NOCOPY NUMBER,
    p_org_id          IN  NUMBER,
    p_all_org         IN  NUMBER      := 1,
    p_val_item_flag   IN  NUMBER      := 1,
    p_pro_item_flag   IN  NUMBER      := 1,
    p_del_rec_flag    IN  NUMBER      := 1,
    p_xset_id         IN  NUMBER  DEFAULT -999,
    p_run_mode        IN  NUMBER  DEFAULT 1,
    p_gather_stats    IN  NUMBER   DEFAULT 1, /* Added for Bug 8532728 */
    source_org_id     IN NUMBER DEFAULT -999 /*Added for bug 6372595. Adds the functionality for looping over the master default assignment
						when the import program is called from the copy organization program*/)
IS
    ret_status      NUMBER;
    err_text        VARCHAR2(2000);

    l_pro_flag_3    NUMBER;

BEGIN
    
   RETCODE := G_SUCCESS;
   
   FND_FILE.put_line (FND_FILE.log, 'Import Items');  
   FND_FILE.put_line (FND_FILE.log, '--------------------------------------------------------------------------------');
   FND_FILE.put_line (FND_FILE.log, 'Argument 1 (ORG_ID) = '||p_org_id);
   FND_FILE.put_line (FND_FILE.log, 'Argument 2 (ALL_ORG) = '||p_all_org);
   FND_FILE.put_line (FND_FILE.log, 'Argument 3 (VAL_ITEM_FLAG) = '||p_val_item_flag);
   FND_FILE.put_line (FND_FILE.log, 'Argument 4 (PRO_ITEM_FLAG) = '||p_pro_item_flag);
   FND_FILE.put_line (FND_FILE.log, 'Argument 5 (DEL_REC_FLAG) = '||p_del_rec_flag);
   FND_FILE.put_line (FND_FILE.log, 'Argument 6 (PROCESS_SET) = '||p_xset_id);
   FND_FILE.put_line (FND_FILE.log, 'Argument 7 (MODE) = '||p_run_mode);
   FND_FILE.put_line (FND_FILE.log, 'Argument 8 (Gather Stats) = '||p_gather_stats);
   FND_FILE.put_line (FND_FILE.log, '--------------------------------------------------------------------------------');
   FND_FILE.put_line (FND_FILE.log, ' ');

   IF p_xset_id IS NULL THEN
    
     IF p_run_mode = 1 THEN

        UPDATE MTL_SYSTEM_ITEMS_INTERFACE
           SET SET_PROCESS_ID = -999
         WHERE  PROCESS_FLAG = 1
           AND  TRANSACTION_TYPE in ('CREATE','Create','create');
       
        UPDATE MTL_ITEM_REVISIONS_INTERFACE
           SET SET_PROCESS_ID = -999 
         WHERE  PROCESS_FLAG = 1 
           AND  TRANSACTION_TYPE in ('CREATE','Create','create');

      ELSIF p_run_mode = 2 THEN

        UPDATE MTL_SYSTEM_ITEMS_INTERFACE
           SET SET_PROCESS_ID = -999
         WHERE  PROCESS_FLAG = 1
           AND  TRANSACTION_TYPE in ('UPDATE','Update','update');
       
        UPDATE MTL_ITEM_REVISIONS_INTERFACE
           SET SET_PROCESS_ID = -999 
         WHERE  PROCESS_FLAG = 1 
           AND  TRANSACTION_TYPE in ('UPDATE','Update','update');
  
       ELSIF p_run_mode = 3 THEN

         UPDATE MTL_SYSTEM_ITEMS_INTERFACE
            SET SET_PROCESS_ID = -999
          WHERE  PROCESS_FLAG = 1
            AND  TRANSACTION_TYPE in ('SYNC','Sync','sync');
       
         UPDATE MTL_ITEM_REVISIONS_INTERFACE
            SET SET_PROCESS_ID = -999 
          WHERE  PROCESS_FLAG = 1 
            AND  TRANSACTION_TYPE in ('SYNC','Sync','sync');

        END IF;

   END IF;
 
   BEGIN
     ret_status := INVPOPIF.inopinp_open_interface_process(
   		org_id => p_org_id,
     		all_org => p_all_org,
    		val_item_flag => p_val_item_flag,
    		pro_item_flag => p_pro_item_flag,
		del_rec_flag => p_del_rec_flag,
		prog_appid => FND_GLOBAL.prog_appl_id,
		prog_id => FND_GLOBAL.conc_program_id,
		request_id => FND_GLOBAL.conc_request_id,
		user_id =>  FND_GLOBAL.user_id,
		login_id => FND_GLOBAL.login_id,
    		err_text => err_text,
                xset_id  => NVL(p_xset_id,-999),
                run_mode => p_run_mode,
		source_org_id => source_org_id,
  gather_stats => p_gather_stats);

      SELECT count(*) INTO l_pro_flag_3
      FROM mtl_system_items_interface
      WHERE process_flag = 3
        AND request_id = FND_GLOBAL.conc_request_id
        AND rownum = 1;
    
      IF l_pro_flag_3 > 0 THEN
         FND_FILE.put_line (FND_FILE.log, 'Validation errors occured during Import Item');  
         FND_FILE.put_line (FND_FILE.log, 'Refer to table MTL_INTERFACE_ERRORS to access validation errors');
         ERRBUF  := 'Validation errors occured during Import Item';
         RETCODE := G_WARNING;
      END IF;

      IF ret_status <> 0 THEN
         FND_FILE.put_line (FND_FILE.log, 'Exceptions occured during Import Item');
         FND_FILE.put_line (FND_FILE.log, err_text);
         ERRBUF  := err_text;
         RETCODE := G_ERROR;
      END IF;

    EXCEPTION
      WHEN others THEN
         FND_FILE.put_line (FND_FILE.log, 'Exceptions occured during Import Item');
	 FND_FILE.put_line (FND_FILE.log, SQLERRM);
         ERRBUF  := SQLERRM;
	 RETCODE := G_ERROR;
    END;

 END inopinp_open_interface_process;


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
    default_flag IN NUMBER       DEFAULT 1,
    commit_flag IN  NUMBER       DEFAULT 1,
    run_mode    IN  NUMBER       DEFAULT 1,
    source_org_id   IN NUMBER DEFAULT -999,
    gather_stats  IN  NUMBER   DEFAULT 1) /* Added for Bug 8532728 */
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
   err_msg          VARCHAR2(300);
   l_return_status  VARCHAR2(1);
   l_msg_data       VARCHAR2(2000);
   l_msg_count      NUMBER;

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
      SELECT  COUNT(*)
        FROM  mtl_system_items_interface msii
             ,mtl_parameters mp1
       WHERE  set_process_id   = xset_id
         AND  transaction_type = cp_transaction_type
         AND  process_flag in (1,2,4)
         AND  mp1.master_organization_id = msii.organization_id
	 AND  ROWNUM = 1;

   CURSOR c_master_revs(cp_transaction_type VARCHAR2) IS
      SELECT  count(*)
        FROM  mtl_item_revisions_interface msii
             ,mtl_parameters mp1
       WHERE  set_process_id   = xset_id
         AND  transaction_type = cp_transaction_type
         AND  process_flag in (1,2,4)
         AND  mp1.master_organization_id = msii.organization_id
	 AND  ROWNUM = 1;

   --: Bug 6158936
   --: Child counts
   CURSOR c_child_items(cp_transaction_type VARCHAR2) IS
      SELECT  count(*)
        FROM  mtl_system_items_interface 
       WHERE  set_process_id   = xset_id
         AND  transaction_type = cp_transaction_type
         AND  process_flag in (1,2,4)
         AND  organization_id
      NOT IN  (SELECT master_organization_id
                 FROM mtl_parameters)
	 AND  ROWNUM = 1;

   CURSOR c_child_revs(cp_transaction_type VARCHAR2) IS
      SELECT  count(*)
        FROM  mtl_item_revisions_interface 
       WHERE  set_process_id   = xset_id
         AND  transaction_type = cp_transaction_type
         AND  process_flag in (1,2,4)
         AND  organization_id
      NOT IN  (SELECT master_organization_id
                 FROM mtl_parameters)
	 AND  ROWNUM = 1;

   CURSOR c_interface_items(cp_transaction_type VARCHAR2) IS
      SELECT  count(*) 
        FROM  mtl_system_items_interface
       WHERE  set_process_id   = xset_id
         AND  transaction_type = cp_transaction_type
         AND  process_flag in (1,4);

   CURSOR c_interface_revs(cp_transaction_type VARCHAR2) IS
      SELECT  count(*)
        FROM  mtl_item_revisions_interface
       WHERE  set_process_id   = xset_id
         AND  transaction_type = cp_transaction_type
         AND  process_flag in (1,4);

   l_processed_flag  BOOLEAN := FALSE;

   -- added for bug 13430047
   CURSOR wrong_trans_type_msii IS
      select rowid, transaction_id
      from mtl_system_items_interface
      where  (transaction_type NOT IN ('CREATE', 'UPDATE','SYNC','ADD','DELETE') --bug13585063,13595665
            OR transaction_type IS NULL OR set_process_id >= 900000000000)
      AND   set_process_id = xset_id
      and process_flag   = 1;

   -- added for bug 13430047
   CURSOR wrong_trans_type_miri IS
      select rowid, transaction_id
      from mtl_item_revisions_interface
      where  (transaction_type NOT IN ('CREATE', 'UPDATE','SYNC','ADD','DELETE') --bug13585063,13595665
            OR transaction_type IS NULL OR set_process_id >= 900000000000)
      AND   set_process_id = xset_id
      and process_flag   = 1;
		    

   --2698140 : Gather stats before running the IOI
   l_schema             VARCHAR2(30);
   l_status             VARCHAR2(1);
   l_industry           VARCHAR2(1);
   l_records            NUMBER(10);
   l_inv_debug_level    NUMBER := INVPUTLI.get_debug_level;  --Bug: 4667452
   l_source_system_id   EGO_IMPORT_BATCHES_B.source_system_id%TYPE;
   l_import_xref_only   EGO_IMPORT_OPTION_SETS.import_xref_only%TYPE;
   l_items_bulk_rec_cnt NUMBER;

   -- Bug 9092888 - changes
   l_err_bug          VARCHAR2(1000);
   l_ret_code         VARCHAR2(1000);
   l_commit_flag      VARCHAR2(1);
   l_style_item_id    NUMBER;
   l_style_item_flag  VARCHAR2(1);
   l_transaction_type VARCHAR2(10);
   -- Bug 9092888 - changes

BEGIN
/*Added for bug 6372595*/ 
   IF source_org_id <> -999 
   THEN 
     INVPOPIF.g_source_org := FALSE ; 
   END IF ; 

   IF l_inv_debug_level IN(101, 102) THEN
           INVPUTLI.info('INVPOPIF: *** Starting a new IOI process: run_mode='|| TO_CHAR(run_mode) ||' all_org='|| TO_CHAR(all_org));
           INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: org_id = '|| TO_CHAR(org_id) || 'Default flag=' || To_Char(default_flag) );
           INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: gather_stats = ' || gather_stats);  /* Added for Bug 8532728 */
   END IF;
   /*
   ** Make sure transaction type is in upper case
   */
   --Start 2698140 : Gather stats before running the IOI
   --When called through GRP pac, or through PLM prog_id will be -1.
   --IF fnd_global.conc_program_id <> -1 THEN  Bug:3547401
   IF NVL(prog_id,-1) <> -1 AND gather_stats = 1 THEN  /* Added for Bug 8532728 */

      IF l_inv_debug_level IN(101, 102) THEN
              INVPUTLI.info('INVPOPIF: Gathering interface table stats');
      END IF;

      -- Fix for bug#9336604 
      --3515652: Collect stats only if no. records > 50
      --SELECT count(*) INTO l_records
      --FROM   mtl_system_items_interface
      --WHERE  set_process_id = xset_id
      --AND    process_flag = 1;

      -- Fix for bug#9336604
      /* Bug 7042156. Collect statistics only if the no.of records is bigger than the profile 
         option threshold */
      --IF (l_records > nvl(fnd_profile.value('EGO_GATHER_STATS'),100))
      --   AND FND_INSTALLATION.GET_APP_INFO('INV', l_status, l_industry, l_schema)
      
      IF (nvl(fnd_profile.value('EGO_ENABLE_GATHER_STATS'),'N') = 'Y')
         AND FND_INSTALLATION.GET_APP_INFO('INV', l_status, l_industry, l_schema)      
      THEN
         IF l_schema IS NOT NULL    THEN
         /* Bug 12669091 : Commenting the Gather Stats.
 	          As mentioned in the note 1208945.1 and suggested by performance team,
 	           for any performance issues we need to gather stats manualy so no need to gather stats in the code.
 	         */
 	         /*
            FND_STATS.GATHER_TABLE_STATS(l_schema, 'MTL_SYSTEM_ITEMS_INTERFACE');
            FND_STATS.GATHER_TABLE_STATS(l_schema, 'MTL_ITEM_REVISIONS_INTERFACE');
            */
 	          -- Bug 12669091 : End
            FND_STATS.GATHER_TABLE_STATS(l_schema, 'MTL_DESC_ELEM_VAL_INTERFACE');
         END IF;
      END IF;

      IF l_inv_debug_level IN(101, 102) THEN
           INVPUTLI.info('INVPOPIF: Gathering interface table stats done');
      END IF;

   END IF;
   --End 2698140 : Gather stats before running the IOI

   -- Populate request_id to have a correct value in case
   -- validation fails while Creating or Updating an Item.

   -- Bug 3975408 :Changed the where clause to (1,4) of the following update.

   UPDATE mtl_system_items_interface
   SET transaction_type = UPPER(transaction_type)
      ,request_id       = req_id
      ,transaction_id   = NVL(transaction_id, MTL_SYSTEM_ITEMS_INTERFACE_S.NEXTVAL)
   WHERE set_process_id = xset_id
   AND   process_flag IN (1,4);

   UPDATE mtl_item_revisions_interface
   SET    transaction_type = UPPER(transaction_type)
         ,request_id       = req_id
   WHERE  set_process_id   = xset_id
   AND    process_flag IN (1,4);
   /*Bug 13430047
   --SYNC: IOI to support SYNC operation.
   UPDATE + first_rows index(msii, MTL_SYSTEM_ITEMS_INTERFACE_N3) (need add hint if added)	-- Bug 10404086
		mtl_system_items_interface msii
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
   */
   --wrong transaction type in msii
   FOR cr IN wrong_trans_type_msii  LOOP
      dumm_status := INVPUOPI.mtl_log_interface_err(
                        -1,
                        user_id,
                        login_id,
                        prog_appid,
                        prog_id,
                        request_id,
                        cr.transaction_id,
                        'INVPOPIF: Invalid transaction type',
                        'TRANSACTION_TYPE',
                        'MTL_SYSTEM_ITEMS_INTERFACE',
                        'INV_INT_TRXTYPCODE',
                        err_text);
      if dumm_status < 0 then
         raise LOGGING_ERR;
      end if;

      update mtl_system_items_interface
      set process_flag = 3
      where rowid  = cr.rowid ;

   END LOOP;

   -- wrong transaction_type in mtl_item_revisions_interface
   FOR cr IN wrong_trans_type_miri  LOOP
      dumm_status := INVPUOPI.mtl_log_interface_err(
                        -1,
                        user_id,
                        login_id,
                        prog_appid,
                        prog_id,
                        request_id,
                        cr.transaction_id,
                        'INVPOPIF: Invalid transaction type',
                        'TRANSACTION_TYPE',
                        'mtl_item_revisions_interface',
                        'INV_INT_TRXTYPCODE',
                        err_text);
      if dumm_status < 0 then
         raise LOGGING_ERR;
      end if;

      update mtl_item_revisions_interface
      set process_flag = 3
      where rowid  = cr.rowid ;
   END LOOP;
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
   set miri.template_id =
            ( select template_id
              FROM mtl_item_templates_vl
              WHERE template_name = miri.template_name
            )
   where miri.template_id   IS NULL
     and miri.template_name IS NOT NULL
     and miri.set_process_id = xset_id
     and miri.process_flag   = 1;


   update MTL_ITEM_REVISIONS_INTERFACE MIRI
   set MIRI.organization_id =
            ( select MP.organization_id
              from MTL_PARAMETERS MP
              where MP.organization_code = MIRI.organization_code
            )
   where MIRI.organization_id is NULL
   and MIRI.set_process_id = xset_id
   and MIRI.process_flag = 1;

   --Bug: 3614120 Making sure that revision code is in upper case.
   update MTL_ITEM_REVISIONS_INTERFACE MIRI
   set MIRI.REVISION = UPPER(MIRI.REVISION)
   WHERE MIRI.set_process_id = xset_id
   AND MIRI.process_flag=1;

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

   -- Bug 9092888 - changes
   IF ( INV_EGO_REVISION_VALIDATE.Get_Process_Control_HTML_API = 'API') THEN
      SELECT style_item_id, style_item_flag , Upper(transaction_type)
        INTO l_style_item_id, l_style_item_flag, l_transaction_type
      FROM MTL_SYSTEM_ITEMS_INTERFACE
        WHERE set_process_id = xset_id
        AND process_flag=1;

      IF(l_transaction_type = 'CREATE'  AND l_style_item_flag = 'N' AND l_style_item_id IS NOT NULL)
      THEN
        UPDATE ego_itm_usr_attr_intrfc uai
        SET (transaction_type, transaction_id,organization_code , organization_id)
            = (SELECT Upper(transaction_type), transaction_id, organization_code, organization_id
              FROM mtl_system_items_interface msii
              WHERE msii.set_process_id = xset_id)
        WHERE DATA_SET_ID = xset_id
        AND PROCESS_STATUS = 1;

        UPDATE mtl_system_items_interface
        SET inventory_item_id = MTL_SYSTEM_ITEMS_S.NEXTVAL
        WHERE inventory_item_id IS NULL
        AND set_process_id = xset_id
        AND process_flag = 1;

        -- Bug 12758661 : Start
        -- here populating the revision id so that while defaulting the revision UDAs we need this.
        UPDATE MTL_ITEM_REVISIONS_INTERFACE
        SET revision_id = MTL_ITEM_REVISIONS_B_S.NEXTVAL
        WHERE revision_id IS NULL
        AND set_process_id = xset_id
        AND process_flag = 1;

        -- Defaulting org assignments from Style to SKU.
        EGO_IMPORT_UTIL_PVT.Default_Org_Assignments(retcode    => l_ret_code,
                                                    errbuf     => l_err_bug,
                                                    p_batch_id => xset_id);

        -- Bug 12758661 : End

        EGO_ITEM_USER_ATTRS_CP_PUB.Process_Item_User_Attrs_Data(
                 ERRBUF        => l_err_bug
                ,RETCODE       => l_ret_code
                ,p_data_set_id => xset_id
                ,p_validate_only => FND_API.G_TRUE
                ,p_ignore_security_for_validate => FND_API.G_FALSE
                ,p_commit => FND_API.G_TRUE
              );
      END IF;

      IF ( l_ret_code <> 0) THEN
        UPDATE mtl_system_items_interface
        SET process_flag = 3
        WHERE  set_process_id = xset_id;

        RETURN l_ret_code;
      END IF;

    END IF;
   -- Bug 9092888 - changes

  /* Bug 5738958
   ** Update Item Status to pending for ITEM CREATE rows in a 
   ** ICC with NIR enabled. This will prevent Active status
   ** to be defaulted and subsequently applied.
   
   R12C : Changing the New Item Req Reqd = 'Y' sub-query for hierarchy enabled Catalogs */
   --6521101 - Pending status updation for master recs only
   UPDATE mtl_system_items_interface msii
      SET msii.INVENTORY_ITEM_STATUS_CODE = 'Pending' 
    WHERE (msii.organization_id = org_id OR all_Org = 1)
      AND msii.INVENTORY_ITEM_STATUS_CODE IS NULL
      AND msii.ITEM_CATALOG_GROUP_ID IS NOT NULL
      AND msii.process_flag = 1
      AND msii.set_process_id = xset_id
      AND msii.TRANSACTION_TYPE = 'CREATE'
      AND EXISTS (SELECT NULL 
                  FROM MTL_PARAMETERS PARAM
		  WHERE PARAM.ORGANIZATION_ID        = MSII.ORGANIZATION_ID
		  AND   PARAM.MASTER_ORGANIZATION_ID = PARAM.ORGANIZATION_ID)
      AND 'Y' =   
             ( SELECT  ICC.NEW_ITEM_REQUEST_REQD
                 FROM  MTL_ITEM_CATALOG_GROUPS_B ICC
                WHERE  ICC.NEW_ITEM_REQUEST_REQD IS NOT NULL
                  AND  ICC.NEW_ITEM_REQUEST_REQD <> 'I'
                  AND  ROWNUM = 1
               CONNECT BY PRIOR ICC.PARENT_CATALOG_GROUP_ID = ICC.ITEM_CATALOG_GROUP_ID
               START WITH ICC.ITEM_CATALOG_GROUP_ID = msii.ITEM_CATALOG_GROUP_ID );   --R12C          

   --SYNC: IOI to support SYNC operation.
	  /* Bug 9660959  Need to disable this since EGO Import Catalog Item program is calling INVPOPIF more than once
			the SYNC rows in pervious round will become create/update rows which shouldn't be disabled
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
   END IF;
   */
   --4682579
   IF run_mode IN (3,2,0) THEN
     UPDATE_SYNC_RECORDS(p_set_id => xset_id);
   END IF;

   IF (run_mode IN (1,3,0)) THEN --{    /* transaction_type IN  'CREATE' 'SYNC' */

      l_processed_flag := TRUE;

      UPDATE /*+ first_rows index(msii, MTL_SYSTEM_ITEMS_INTERFACE_N3) */  -- Bug 10404086
				mtl_system_items_interface msii
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

            UPDATE /*+ first_rows index(msii, MTL_SYSTEM_ITEMS_INTERFACE_N3) */  -- Bug 10404086
							mtl_system_items_interface msii
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
            IF l_inv_debug_level IN(101, 102) THEN
               INVPUTLI.info('INVPOPIF all_org=1: Calling create process for masters');
            END IF;
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
                                  ,commit_flag
                                  ,default_flag);

            UPDATE mtl_system_items_interface msii
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag >= 60000
            AND set_process_id = xset_id;

            UPDATE mtl_item_revisions_interface
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag >= 60000
            AND set_process_id = xset_id;
         END IF;

         --Master item records are processed above, now time for childs
         --All master records will be having process flag as 3, 7. Not valid
	 --with predefaulting phase introduction. Master items will be in process flag 1
         --We need to check only for REMAINING records with process flag in 1,4

         OPEN  c_child_items(cp_transaction_type => 'CREATE');
         FETCH c_child_items INTO mtl_count;
         CLOSE c_child_items;

         OPEN  c_child_revs(cp_transaction_type => 'CREATE');
         FETCH c_child_revs INTO mtli_count;
         CLOSE c_child_revs;

         /*  Added the below If condition so that if no records are present in the
             interface table for creating child org Items then we can skip calling of
             inopinp_OI_process_create for the child org */
         IF (mtl_count <> 0 or mtli_count <> 0) THEN

            /* R12C Bug 6158936 - All Master Items and revs will be isolated during child procesing */

            UPDATE /*+ first_rows index(msii, MTL_SYSTEM_ITEMS_INTERFACE_N3) */  -- Bug 10404086
						mtl_system_items_interface msii
            SET process_flag = process_flag + 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag < 60000
            AND set_process_id = xset_id
            AND EXISTS (select mp1.organization_id    /*BUG 6158936*/
                          from mtl_parameters mp1
                         where msii.organization_id = mp1.master_organization_id);

            UPDATE mtl_item_revisions_interface miri
            SET process_flag = process_flag + 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag < 60000
            AND set_process_id = xset_id
            AND EXISTS (select mp1.organization_id   /*BUG 6158936*/
                          from mtl_parameters mp1
                         where miri.organization_id = mp1.master_organization_id);

            IF l_inv_debug_level IN(101, 102) THEN
               INVPUTLI.info('INVPOPIF all_org=1: Calling create process for childs');
            END IF;
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
                                  commit_flag,
                                  default_flag);

           /* R12C Bug 6158936 : Moving Master Items and revs back to batch */

            UPDATE mtl_system_items_interface msii
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag >= 60000
            AND set_process_id = xset_id;

            UPDATE mtl_item_revisions_interface
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'CREATE'
            AND process_flag >= 60000
            AND set_process_id = xset_id;

         END IF;

      ELSE  /* all_org <> 1 */
         --Creating Items under a specific org.
         OPEN  c_interface_items(cp_transaction_type => 'CREATE');
         FETCH c_interface_items INTO mtl_count;
         CLOSE c_interface_items;

         OPEN  c_interface_revs(cp_transaction_type => 'CREATE');
         FETCH c_interface_revs INTO mtli_count;
         CLOSE c_interface_revs;

         IF l_inv_debug_level IN(101, 102) THEN
            INVPUTLI.info('INVPOPIF all_org<>1: Calling create process');
         END IF;

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
                               commit_flag,
                               default_flag);
         END IF;
      END IF;  --}

      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag - 30000
      WHERE transaction_type IN ('UPDATE','SYNC') --3018673
      AND process_flag >= 30000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag - 30000
      WHERE transaction_type IN ('UPDATE','SYNC') --3018673
      AND process_flag >= 30000
      AND set_process_id = xset_id;

   END IF;

   IF (run_mode IN (2,3,0)) THEN    /* transaction_type IN  'UPDATE' 'SYNC' */

      l_processed_flag := TRUE;

      UPDATE /*+ first_rows index(msii, MTL_SYSTEM_ITEMS_INTERFACE_N3) */  -- Bug 10404086
				mtl_system_items_interface msii
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

            UPDATE /*+ first_rows index(msii, MTL_SYSTEM_ITEMS_INTERFACE_N3) */  -- Bug 10404086
							mtl_system_items_interface msii
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
                                  commit_flag,
                                  default_flag);

            UPDATE mtl_system_items_interface msii
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag >= 60000
            AND set_process_id = xset_id;

            UPDATE mtl_item_revisions_interface
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag >= 60000
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

            /* R12C Bug 6158936 - All Master Items and revs will be isolated during child procesing */

            UPDATE /*+ first_rows index(msii, MTL_SYSTEM_ITEMS_INTERFACE_N3) */  -- Bug 10404086
							mtl_system_items_interface msii
            SET process_flag = process_flag + 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag < 60000
            AND set_process_id = xset_id
            AND not exists (select mp1.organization_id
                            from mtl_parameters mp1
                            where msii.organization_id <> mp1.master_organization_id);

            UPDATE mtl_item_revisions_interface miri
            SET process_flag = process_flag + 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag < 60000
            AND set_process_id = xset_id
            AND not exists (select mp1.organization_id
                            from mtl_parameters mp1
                            where miri.organization_id <> mp1.master_organization_id);

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
                                  commit_flag,
                                  default_flag);

           /* R12C Bug 6158936 : Moving Master Items and revs back to batch */

            UPDATE mtl_system_items_interface msii
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag >= 60000
            AND set_process_id = xset_id;

            UPDATE mtl_item_revisions_interface
            SET process_flag = process_flag - 60000
            WHERE transaction_type = 'UPDATE'
            AND process_flag >= 60000
            AND set_process_id = xset_id;

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
                        commit_flag,
                        default_flag);
         END IF;

      END IF;  --}

      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag - 30000
      WHERE transaction_type IN ('CREATE','SYNC') --3018673
      AND process_flag >= 30000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag - 30000
      WHERE transaction_type IN ('CREATE','SYNC') --3018673
      AND process_flag >= 30000
      AND set_process_id = xset_id;

   END IF;  --}

   --3018673: Start of bug fix.
   IF run_mode = 3 THEN

      UPDATE mtl_system_items_interface msii
      SET process_flag = process_flag - 20000
      WHERE transaction_type IN ('CREATE','UPDATE')
      AND process_flag >= 20000
      AND set_process_id = xset_id;

      UPDATE mtl_item_revisions_interface
      SET process_flag = process_flag - 20000
      WHERE transaction_type  IN ('CREATE','UPDATE')
      AND process_flag >= 20000
      AND set_process_id = xset_id;

   END IF;
   --3018673: End of bug fix.
   
   --Start : 5513065 Including xref import into same transaction context of item+rev
   BEGIN
      SELECT batch.source_system_id, NVL(opt.import_xref_only,'N')
      INTO   l_source_system_id, l_import_xref_only
      FROM   ego_import_batches_b batch
            ,ego_import_option_sets opt
      WHERE  batch.batch_id = xset_id
      AND    batch.batch_id = opt.batch_id;
   EXCEPTION
      WHEN OTHERS THEN
         l_source_system_id := EGO_IMPORT_PVT.get_pdh_source_system_id;
         l_import_xref_only := 'N';
   END;

   IF NOT(l_source_system_id <> EGO_IMPORT_PVT.get_pdh_source_system_id AND l_import_xref_only = 'Y') THEN

      --Calling Demerge_Batch_After_Import
      IF l_inv_debug_level IN(101, 102) THEN
         INVPUTLI.info('Calling EGO_IMPORT_PVT.Demerge_Batch_After_Import');
      END IF;
      EGO_IMPORT_PVT.Demerge_Batch_After_Import(
           ERRBUF        => err_text
          ,RETCODE       => ret_code
          ,p_batch_id    => xset_id);
      IF l_inv_debug_level IN(101, 102) THEN
         INVPUTLI.info('Returned EGO_IMPORT_PVT.Demerge_Batch_After_Import '||ret_code);
         INVPUTLI.info(err_text);
      END IF;
      
      --Calling source system xref bulkloader
      IF l_inv_debug_level IN(101, 102) THEN
         INVPUTLI.info('Calling EGO_IMPORT_PVT.Process_SSXref_Intf_Rows');
      END IF;

      EGO_IMPORT_PVT.Process_SSXref_Intf_Rows(
           ERRBUF        => err_text
          ,RETCODE       => ret_code
          ,p_data_set_id => xset_id);

      IF l_inv_debug_level IN(101, 102) THEN
         INVPUTLI.info('Returned EGO_IMPORT_PVT.Process_SSXref_Intf_Rows '||ret_code);
         INVPUTLI.info(err_text);
      END IF;

   END IF;

   IF (commit_flag = 1 ) THEN
      commit;
   END IF;

   --End : 5513065 Including xref import into same transaction context of item+rev


   IF NOT l_processed_flag THEN
      ret_code := 1;
   END IF;

   IF l_inv_debug_level IN(101, 102) THEN
           INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Before Sync IM Index');
   END IF;

   --Start : Sync iM index changes
   IF  pro_item_flag = 1 --Bug 4667985
   THEN

	 -- Begin Removed as part of Retrofit R12.2.5
      --IF commit_flag   = 1 THEN					
      --   INV_ITEM_PVT.SYNC_IM_INDEX;
      --END IF;

	 -- End Removed as part of Retrofit R12.2.5

      --Bug 4667985 Moving the code to Synch Up eni_oltp_item_star table here
      --            from Create and Update calls
      --
      -- Sync processed rows with item star table
      --
      IF l_inv_debug_level IN(101, 102) THEN
         INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INV_ENI_ITEMS_STAR_PKG.Sync_Star_Items_From_IOI');
      END IF;

      --Bug: 2718703 checking for ENI product before calling their package
      --This check has been moved to INV_ENI_ITEMS_STAR_PKG
      BEGIN
         INV_ENI_ITEMS_STAR_PKG.Sync_Star_Items_From_IOI(
             p_api_version         =>  1.0
            ,p_init_msg_list       =>  FND_API.g_TRUE
            ,p_set_process_id      =>  xset_id
            ,x_return_status       =>  l_return_status
            ,x_msg_count           =>  l_msg_count
            ,x_msg_data            =>  l_msg_data);


         IF NOT ( l_return_status = FND_API.g_RET_STS_SUCCESS ) THEN
            INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Synch Up of ENI tables failed');
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
                                MSG_NAME      =>'INV_IOI_ERR_SS_ITMS_FRM_IOI', --added by bug 11894684, replace INV_IOI_ERR with specific message name so we can identify error easily
                                ERR_TEXT      =>err_text);

            if ( dumm_status < 0 ) then
               INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Logging Error');
            end if;
         END IF; --l_return_status
      EXCEPTION
      WHEN OTHERS THEN
            l_msg_data := 'Unhandled Excpetion in INV_ENI_ITEMS_STAR_PKG: ';
            l_msg_data := l_msg_data || SQLERRM;
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
                                MSG_NAME      =>'INV_IOI_ERR_USS_ITMS_FRM_IOI',--added by bug 11894684, replace INV_IOI_ERR with specific message name so we can identify error easily
                                ERR_TEXT      =>err_text);

      END;

      IF l_inv_debug_level IN(101, 102) THEN
           INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Start Raising Business Events');
      END IF;

      --R12: Business Event Enhancement:
      --Raise events for EGO Bulk Load and Excel Import
      IF (request_id <> -1 ) THEN

        --Populate Item Bulkload Recs for items and revisions
        BEGIN
          IF l_inv_debug_level IN(101, 102) THEN
             INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Insert in to bulkloadrecs for Item');
          END IF;

           INSERT INTO MTL_ITEM_BULKLOAD_RECS(
              REQUEST_ID
             ,ENTITY_TYPE
             ,INVENTORY_ITEM_ID
             ,ORGANIZATION_ID
             ,TRANSACTION_TYPE
             ,CREATION_DATE
             ,CREATED_BY
             ,LAST_UPDATE_DATE
             ,LAST_UPDATED_BY
             ,LAST_UPDATE_LOGIN)
           (SELECT  /*+ first_rows index(msi, MTL_SYSTEM_ITEMS_INTERFACE_N3) */ -- Bug 10404086
              msi.REQUEST_ID
             ,'ITEM'
             ,msi.INVENTORY_ITEM_ID
             ,msi.ORGANIZATION_ID
             ,msi.TRANSACTION_TYPE
             ,NVL(msi.CREATION_DATE, SYSDATE)
             ,NVL(msi.CREATED_BY, -1)
             ,NVL(msi.LAST_UPDATE_DATE, SYSDATE)
             ,NVL(msi.LAST_UPDATED_BY, -1)
             ,msi.LAST_UPDATE_LOGIN
           FROM  mtl_system_items_interface msi
           WHERE msi.request_id = request_id
           and   msi.set_process_id = xset_id
           and   msi.process_flag   = 7
	   /* Bug 6139403 Do not raise BE for fake rows*/
	   and   nvl(msi.confirm_status,'isnull') 
	         not in ('CFC', 'CFM', 'FMR', 'UFN', 'UFS', 'UFM', 'FK', 'FEX'));

           l_items_bulk_rec_cnt := SQL%ROWCOUNT;

	   -- Raise for IOI and EGO Bulkload both
	   IF ( SQL%ROWCOUNT > 0 ) THEN
           BEGIN
              INV_ITEM_EVENTS_PVT.Raise_Events(
                p_request_id    => request_id
               ,p_xset_id       => xset_id
               ,p_event_name    => 'EGO_WF_WRAPPER_PVT.G_ITEM_BULKLOAD_EVENT'
               ,p_dml_type      => 'BULK');

                IF l_inv_debug_level IN(101, 102) THEN
                   INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Raised Item Bulkload Event');
                END IF;
 
           EXCEPTION
              WHEN OTHERS THEN
                    err_msg := SUBSTR('INVPOPIF: Error:' ||SQLERRM ||' while raising Item Change Event',1,240);
                     IF l_inv_debug_level IN(101, 102) THEN
                             INVPUTLI.info(err_msg);
                     END IF;
           END;	     
	   END IF;


           IF l_inv_debug_level IN(101, 102) THEN
                INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Insert in to bulkloadrecs for Revision.');
           END IF;

           INSERT INTO MTL_ITEM_BULKLOAD_RECS(
              REQUEST_ID
             ,ENTITY_TYPE
             ,INVENTORY_ITEM_ID
             ,ORGANIZATION_ID
             ,REVISION_ID
             ,TRANSACTION_TYPE
             ,CREATION_DATE
             ,CREATED_BY
             ,LAST_UPDATE_DATE
             ,LAST_UPDATED_BY
            ,LAST_UPDATE_LOGIN)
           (SELECT
              mir.REQUEST_ID
             ,'ITEM_REVISION'
             ,mir.INVENTORY_ITEM_ID
             ,mir.ORGANIZATION_ID
             ,mir.REVISION_ID
             ,mir.TRANSACTION_TYPE
             ,NVL(mir.CREATION_DATE, SYSDATE)
             ,NVL(mir.CREATED_BY, -1)
             ,NVL(mir.LAST_UPDATE_DATE, SYSDATE)
             ,NVL(mir.LAST_UPDATED_BY, -1)
             ,mir.LAST_UPDATE_LOGIN
           FROM  mtl_item_revisions_interface mir
           WHERE mir.request_id     = request_id
           and   mir.set_process_id = xset_id
           and   mir.process_flag   = 7);

           --Raise for revision bulkload also
	   IF ( SQL%ROWCOUNT > 0 ) THEN
           BEGIN
              INV_ITEM_EVENTS_PVT.Raise_Events(
                p_request_id    => request_id
               ,p_xset_id       => xset_id
               ,p_event_name    => 'EGO_WF_WRAPPER_PVT.G_REV_CHANGE_EVENT'
               ,p_dml_type      => 'BULK');

                IF l_inv_debug_level IN(101, 102) THEN
                     INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Raised Revision Bulkload Event');
                END IF;

           EXCEPTION
              WHEN OTHERS THEN
                   err_msg := SUBSTR('INVPOPIF: Error:' ||SQLERRM ||' while raising REV Change Event',1,240);
                   IF l_inv_debug_level IN(101, 102) THEN
                      INVPUTLI.info(err_msg);
                   END IF;
           END;
	     
	   END IF;


        EXCEPTION
           WHEN OTHERS THEN
                err_msg := SUBSTR('INVPOPIF: Error:' ||SQLERRM ||' while inserting records in MTL_ITEM_BULKLOAD_RECS',1,240);
                  IF l_inv_debug_level IN(101, 102) THEN
                     INVPUTLI.info(err_msg);
                  END IF;
        END;


        IF ( l_items_bulk_rec_cnt > 0 ) THEN
        BEGIN
           INV_ITEM_EVENTS_PVT.Invoke_ICX_APIs(
             p_request_id    => request_id
            ,p_xset_id       => xset_id
            ,p_entity_type   => 'ITEM'
            ,p_dml_type      => 'BULK');
           IF l_inv_debug_level IN(101, 102) THEN
              INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: ' || 'Calling ICX Bulkload Event');
           END IF;
        EXCEPTION
           WHEN OTHERS THEN
                err_msg := SUBSTR('INVPOPIF: Error:' ||SQLERRM ||'while invoking ICX APIs',1,240);
                     IF l_inv_debug_level IN(101, 102) THEN
                             INVPUTLI.info(err_msg);
                  END IF;
        END;          
        END IF; --l_items_bulk_rec_cnt

      END IF; --request_id <> -1
      --R12: Business Event Enhancement:
      --Raise events for EGO Bulk Load and Excel Import
      
      /* Fix for iProc bug 9237356, Added below call to sync IP IM Index */
      IF commit_flag   = 1 THEN
        INV_ITEM_EVENTS_PVT.Sync_IP_IM_Index;
      END IF;
      
   END IF; -- pro_item_flag
   --End : Sync iM index changes

   --Delete processed records from IOI tables.
   --Bug: 5473976 Rows will not be deleted if control is coming from Import Workbench
   IF (del_rec_flag = 1 AND (NVL(INV_EGO_REVISION_VALIDATE.Get_Process_Control,'!') <> 'EGO_ITEM_BULKLOAD')) THEN
      IF l_inv_debug_level IN(101, 102) THEN
         INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVPOPIF.indelitm_delete_item_oi');
      END IF;

      ret_code := INVPOPIF.indelitm_delete_item_oi (err_text => err_msg,
                                                    com_flag => commit_flag,
                                                    xset_id  => xset_id);

      IF l_inv_debug_level IN(101, 102) THEN
         INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: done INVPOPIF.indelitm_delete_item_oi: ret_code=' || ret_code);
      END IF;

   ELSE
      /****Added for bug 5194369
     Delete processed rows (7) from the interface table
     if the record was created for CM support, and a similar row with
     process flag 5 exists in the interface table.
     ***/
      DELETE 
      FROM mtl_system_items_interface msii
      WHERE process_flag = 7
        AND (inventory_item_id, organization_id, set_process_id) IN
                (SELECT inventory_item_id, organization_id, set_process_id
    	         FROM mtl_system_items_interface intf
                 WHERE set_process_id = xset_id
                 AND   process_flag = 5);
   END IF;  -- del_rec_flag = 1

   IF (commit_flag = 1 ) THEN
      commit;
   END IF;

   -- Bug 12758661 : Start
   -- Calling the EGO code to default child entities here so that non default categories
   IF(INV_EGO_REVISION_VALIDATE.Get_Process_Control_HTML_API = 'API' AND
     l_transaction_type = 'CREATE'  AND l_style_item_flag = 'N' AND l_style_item_id IS NOT NULL) THEN
      EGO_IMPORT_UTIL_PVT.Default_Child_Entities(retcode               => l_ret_code,
                                                 errbuf                => l_err_bug,
                                                 p_batch_id            => xset_id,
                                                 p_msii_miri_process_flag => 7);
   END IF;
   -- Bug 12758661 : End

   --
   -- Process Item Category Open Interface records
   --

   IF l_inv_debug_level IN(101, 102) THEN
      INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: calling INV_ITEM_CATEGORY_OI.process_Item_Category_records '||pro_item_flag);
   END IF;

   SELECT COUNT(1)  INTO mtl_count
   FROM mtl_item_categories_interface mici
   WHERE mici.SET_PROCESS_ID = xset_id
   AND mici.process_flag  IN (1,2,4);

   IF mtl_count > 0 THEN
      INV_ITEM_CATEGORY_OI.process_Item_Category_records (
            ERRBUF              =>  err_text
         ,  RETCODE             =>  ret_code
         ,  p_rec_set_id        =>  xset_id
         ,  p_validate_rec_flag =>  val_item_flag
         ,  p_upload_rec_flag   =>  pro_item_flag
         ,  p_delete_rec_flag   =>  del_rec_flag
         ,  p_commit_flag       =>  commit_flag
         ,  p_prog_appid        =>  prog_appid
         ,  p_prog_id           =>  prog_id
         ,  p_request_id        =>  request_id
         ,  p_user_id           =>  user_id
         ,  p_login_id          =>  login_id
         ,  p_gather_stats      =>  gather_stats /* Added for Bug 8532728 */ );
   END IF;

   IF l_inv_debug_level IN(101, 102) THEN
      INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: done INV_ITEM_CATEGORY_OI.process_Item_Category_records: ret_code=' || ret_code);
   END IF;

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
   IF l_inv_debug_level IN(101, 102) THEN
      INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: calling INV_ITEM_CATALOG_ELEM_PUB.process_Item_Catalog_grp_recs');
   END IF;
     
   SELECT COUNT(1) INTO mtl_count
   FROM mtl_desc_elem_val_interface  mdei
   WHERE  mdei.set_process_id = xset_id
   AND mdei.process_flag IN (1, 2, 4);

   IF mtl_count > 0 THEN
      INV_ITEM_CATALOG_ELEM_PUB.process_Item_Catalog_grp_recs (
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
         ,  p_login_id          =>  login_id);
   ELSE
      ret_code_grp := 0;
   END IF;

   IF l_inv_debug_level IN(101, 102) THEN
      INVPUTLI.info('INVPOPIF.inopinp_open_interface_process: done INV_ITEM_CATALOG_ELEM_PUB.process_Item_Catalog_grp_recs: ret_code=' || ret_code_grp);
   END IF;

   IF (ret_code_grp <> 0) THEN
      ret_code := ret_code_grp;
   END IF;
   
   RETURN (ret_code);

END inopinp_open_interface_process;


--------------------------- inopinp_OI_process_update -------------------------

FUNCTION inopinp_OI_process_update
(
    org_id          NUMBER,
    all_org         NUMBER  := 1,
    val_item_flag   NUMBER  := 1,
    pro_item_flag   NUMBER  := 1,
    del_rec_flag    NUMBER  := 1,
    prog_appid      NUMBER  := -1,
    prog_id         NUMBER  := -1,
    request_id      NUMBER  := -1,
    user_id         NUMBER  := -1,
    login_id        NUMBER  := -1,
    err_text    IN OUT  NOCOPY VARCHAR2,
    xset_id     IN  NUMBER  DEFAULT -999,
    commit_flag IN  NUMBER  DEFAULT 1,
    default_flag IN NUMBER  DEFAULT 1)
RETURN INTEGER IS

   ret_code        NUMBER:=  1;
   err_msg         VARCHAR2(300);
   err_msg_name    VARCHAR2(30);
   table_name      VARCHAR2(30);
   dumm_status     NUMBER;
   Logging_Err     EXCEPTION;
   l_return_status VARCHAR2(1);
   l_msg_count     NUMBER;
   l_msg_data      VARCHAR2(2000);
   l_inv_debug_level    NUMBER := INVPUTLI.get_debug_level;  --Bug: 4667452

BEGIN

   IF l_inv_debug_level IN(101, 102) THEN
           INVPUTLI.info('INVPOPIF.inopinp_OI_process_update : begin org_id: ' || TO_CHAR(org_id));
        INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling UPDATE_ITEM_CATALOG_ID');
   END IF;

   --Validate Catalog_Group_name
   UPDATE_ITEM_CATALOG_ID(
            p_set_id     => xset_id
                ,p_prog_appid => prog_appid
           ,p_prog_id    => prog_id
           ,p_request_id => request_id
           ,p_user_id    => user_id
           ,p_login_id   => login_id
           ,x_err_text   => err_text);

   IF('Y' = FND_PROFILE.VALUE('EGO_ENABLE_P4T')) THEN          
                  VALIDATE_RELEASED_ICC(
                                       p_set_id     => xset_id
                                      ,p_prog_appid => prog_appid
                                      ,p_prog_id    => prog_id
                                      ,p_request_id => request_id
                                      ,p_user_id    => user_id
                                      ,p_login_id   => login_id
                                      ,x_err_text   => err_text);
   END IF ;



  IF l_inv_debug_level IN(101, 102) THEN
     INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INVNIRIS.change_policy_check');
  END IF;

  ret_code := INVNIRIS.change_policy_check (
                      org_id     => org_id,
                      all_org    => all_org,
                      prog_appid => prog_appid,
                      prog_id    => prog_id,
                      request_id => request_id,
                      user_id    => user_id,
                      login_id   => login_id,
                      err_text   => err_msg,
                      xset_id    => xset_id);

  IF l_inv_debug_level IN(101, 102) THEN
     INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INVNIRIS.change_policy_check RETURN'||ret_code);
     INVPUTLI.info('INVNIRIS.change_policy_check->l'||err_msg);
  END IF;

  IF (ret_code <> 0) THEN
    err_msg := 'INVNIRIS.change_policy_check: error in policy phase of UPDATE;' ||
               ' Please check mtl_interface_errors table ' || err_msg;
    goto ERROR_LABEL;
  END IF;

  IF default_flag = 1 THEN
    IF l_inv_debug_level IN(101, 102) THEN
       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INVUPD1B.mtl_pr_assign_item_data_update');
    END IF;



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
  elsif default_flag = 2 then --Rules ER 11830273, populate revision_id for UPDATE case when default_flag is 2 
    IF l_inv_debug_level IN(101, 102) THEN
       INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: POPULATE REVISION_ID TO mtl_item_revisions_interface IF REVISION_ID IS NULL');
    END IF;
      UPDATE  mtl_item_revisions_interface MIRI set revision_id = (SELECT R.REVISION_ID FROM MTL_ITEM_REVISIONS_B R WHERE R.REVISION = MIRI.REVISION AND R.ORGANIZATION_ID = MIRI.ORGANIZATION_ID AND R.INVENTORY_ITEM_ID = MIRI.INVENTORY_ITEM_ID )
      where process_flag = 1
      AND   set_process_id  = xset_id
      AND   (organization_id = org_id or all_org = 1)
      AND REVISION_ID IS NULL
      AND REVISION IS NOT NULL;

  END IF;
  
  IF (val_item_flag = 1) THEN
     IF (ret_code <> 0) THEN
        err_msg := 'INVPOPIF.inopinp_OI_process_update: error in ASSIGN phase of UPDATE;' ||
                   ' Please check mtl_interface_errors table ' || err_msg;
        goto ERROR_LABEL;
     END IF;

  --Bug:3777954 added call to new pkg/processing for NIR required items (for EGO)
     IF l_inv_debug_level IN(101, 102) THEN
        INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVNIRIS.mtl_validate_nir_item');
     END IF;

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


     IF l_inv_debug_level IN(101, 102) THEN
        INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVNIRIS.mtl_validate_nir_item: ret_code=' || ret_code || ' err_msg=' || err_msg);
     END IF;

     IF (ret_code <> 0) THEN
        err_msg := 'INVPOPIF.inopinp_OI_process_create: error in NIR ASSIGN phase of UPDATE;' ||
                   ' Please check mtl_interface_errors table ' || err_msg;
        goto ERROR_LABEL;
     END IF;

     --Bug:3777954 call ends

     IF l_inv_debug_level IN(101, 102) THEN
        INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INVUPD1B.mtl_pr_validate_item_update');
     END IF;

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

     IF (ret_code <> 0) THEN
        err_msg := 'INVPOPIF.inopinp_OI_process_update: error in VALIDATE phase of UPDATE;' ||
                   ' Please check mtl_interface_errors table ' || err_msg;
        goto ERROR_LABEL;
     END IF;

  END IF;  /* validate_item_flag = 1 */

  IF (pro_item_flag = 1) THEN

     IF l_inv_debug_level IN(101, 102) THEN
          INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INVUPD2B.inproit_process_item_update');
     END IF;

     ret_code := INVUPD2B.inproit_process_item_update (
                        prg_appid => prog_appid,
                        prg_id => prog_id,
                        req_id => request_id,
                        user_id => user_id,
                        login_id => login_id,
                        error_message => err_msg,
                        message_name => err_msg_name,
                        table_name => table_name,
                        xset_id => xset_id, 
                        commit_flag => commit_flag); /*Added to fix Bug 8359046*/
     IF l_inv_debug_level IN(101, 102) THEN
        INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: done INVUPD2B.inproit_process_item_update: ret_code=' || ret_code);
     END IF;

     IF (ret_code <> 0) THEN
        err_msg := 'INVPOPIF.inopinp_OI_process_update: error in PROCESS phase of UPDATE;' ||
                   ' Please check mtl_interface_errors table ' || err_msg;
        goto ERROR_LABEL;
     END IF;

       --
       -- Sync processed rows with item star table
       --

      IF l_inv_debug_level IN(101, 102) THEN
         INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling INV_ENI_ITEMS_STAR_PKG.Sync_Star_Items_From_IOI');
      END IF;

       --Bug: 2718703 checking for ENI product before calling their package
       --This check has been moved to INV_ENI_ITEMS_STAR_PKG
/** Bug 4667985 Moved to main loop**/

  END IF;  /* pro_item_flag = 1 */

  RETURN (0);

  <<ERROR_LABEL>>

  err_text := SUBSTR(err_msg, 1,240);

  RETURN (ret_code);

EXCEPTION

   WHEN OTHERS THEN
      err_text := substr('INVPOPIF.inopinp_OI_process_update ' || SQLERRM , 1,240);
        IF l_inv_debug_level IN(101, 102) THEN
           INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: About to rollback.');
        END IF;
      ROLLBACK;
      RETURN (ret_code);
END inopinp_OI_process_update;


--------------------------- inopinp_OI_process_create -------------------------

FUNCTION inopinp_OI_process_create
(
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
    err_text     IN OUT NOCOPY VARCHAR2,
    xset_id      IN  NUMBER       DEFAULT -999,
    commit_flag  IN  NUMBER       DEFAULT 1,
    default_flag IN  NUMBER       DEFAULT 1
)
RETURN INTEGER IS

    CURSOR Error_Items IS
         SELECT transaction_id, organization_id
           FROM mtl_system_items_interface
          WHERE process_flag = 4
            AND set_process_id = xset_id
            AND transaction_type = 'CREATE';

    err_msg_name        VARCHAR2(30);
    err_msg             VARCHAR2(300);
    table_name          VARCHAR2(30);
    ret_code            NUMBER := 1;
    wrong_recs          NUMBER := 0;
    create_recs         NUMBER := 0;
    update_recs         NUMBER := 0;
    p_flag              NUMBER := 0;
    l_transaction_type  VARCHAR2(10)  :=  'CREATE';
    dumm_status         NUMBER;
    Logging_Err         EXCEPTION;
    l_return_status     VARCHAR2(1);
    l_msg_count         NUMBER;
    l_msg_data          VARCHAR2(2000);
    l_child_records     VARCHAR2(1);
    l_inv_debug_level   NUMBER := INVPUTLI.get_debug_level; --Bug: 4667452
    trans_id            NUMBER;

BEGIN
   IF l_inv_debug_level IN(101, 102) THEN
      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create : begin org_id: ' || TO_CHAR(org_id));
   END IF;

   IF l_inv_debug_level IN(101, 102) THEN
      INVPUTLI.info('INVPOPIF.inopinp_OI_process_update: calling UPDATE_ITEM_CATALOG_ID');
   END IF;

   --Validate Catalog_Group_name
   UPDATE_ITEM_CATALOG_ID(
            p_set_id     => xset_id
                ,p_prog_appid => prog_appid
           ,p_prog_id    => prog_id
           ,p_request_id => request_id
           ,p_user_id    => user_id
           ,p_login_id   => login_id
           ,x_err_text   => err_text);

         IF('Y' = FND_PROFILE.VALUE('EGO_ENABLE_P4T')) THEN          
                  VALIDATE_RELEASED_ICC(
                                       p_set_id     => xset_id
                                      ,p_prog_appid => prog_appid
                                      ,p_prog_id    => prog_id
                                      ,p_request_id => request_id
                                      ,p_user_id    => user_id
                                      ,p_login_id   => login_id
                                      ,x_err_text   => err_text);
         END IF ;

   IF l_inv_debug_level IN(101, 102) THEN
      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVPASGI.mtl_pr_assign_item_data');
   END IF;

   ret_code := INVPASGI.mtl_pr_assign_item_data (
               org_id => org_id,
               all_org => all_org,
               prog_appid => prog_appid,
               prog_id => prog_id,
               request_id => request_id,
               user_id => user_id,
               login_id => login_id,
               err_text => err_msg,
               xset_id => xset_id,
               default_flag => default_flag);

   IF l_inv_debug_level IN(101, 102) THEN
      INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: done INVPASGI.mtl_pr_assign_item_data: ret_code=' || ret_code || ' err_msg=' || err_msg);
   END IF;

   IF (ret_code <> 0) THEN
      err_msg := 'INVPOPIF.inopinp_OI_process_create: error in ASSIGN phase of CREATE;' ||
                 ' Please check mtl_interface_errors table ' || err_msg;
      goto ERROR_LABEL;
   END IF;

   IF (val_item_flag = 1) THEN
      --Bug:3777954 added call to new pkg/processing for NIR required items (for EGO)

        IF l_inv_debug_level IN(101, 102) THEN
              INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVNIRIS.mtl_validate_nir_item');
        END IF;

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

        IF l_inv_debug_level IN(101, 102) THEN
                INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVNIRIS.mtl_validate_nir_item: ret_code=' || ret_code || ' err_msg=' || err_msg);
        END IF;

      IF (ret_code <> 0) THEN
         err_msg := 'INVPOPIF.inopinp_OI_process_create: error in NIR ASSIGN phase of CREATE;' ||
                   ' Please check mtl_interface_errors table ' || err_msg;
         goto ERROR_LABEL;
      END IF;

      --Bug:3777954 call ends

        IF l_inv_debug_level IN(101, 102) THEN
                INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVPVALI.mtl_pr_validate_item');
        END IF;

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

        IF l_inv_debug_level IN(101, 102) THEN
                INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: done INVPVALI.mtl_pr_validate_item: ret_code=' || ret_code || ' err_msg=' || err_msg);
        END IF;

      IF (ret_code <> 0) THEN
         err_msg := 'INVPOPIF.inopinp_OI_process_create: error in VALIDATE phase of CREATE;'||
                   ' Please check mtl_interface_errors table ' || err_msg;
         goto ERROR_LABEL;
      END IF;

   END IF;  -- val_item_flag = 1


   IF (pro_item_flag = 1) THEN

        IF l_inv_debug_level IN(101, 102) THEN
              INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INVPPROC.inproit_process_item');
        END IF;

      ret_code := INVPPROC.inproit_process_item (
                     prg_appid => prog_appid,
                     prg_id => prog_id,
                     req_id => request_id,
                     user_id => user_id,
                     login_id => login_id,
                     error_message => err_msg,
                     message_name => err_msg_name,
                     table_name => table_name,
                     xset_id => xset_id);

        IF l_inv_debug_level IN(101, 102) THEN
              INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: done INVPPROC.inproit_process_item: ret_code=' || ret_code);
        END IF;

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
                                   'INV_IOI_ERR_IN_PROCESS_ITEM',--added by bug 11894684, replace INV_IOI_ERR with specific message name so we can identify error easily
                                    err_msg);
	 END LOOP;
 
         UPDATE mtl_system_items_interface
            SET process_flag = 3
          WHERE process_flag = 4
            AND set_process_id = xset_id
            AND transaction_type = 'CREATE';

         err_msg := 'INVPOPIF.inopinp_OI_process_create: error in PROCESS phase of CREATE;'||
                    ' Please check mtl_interface_errors table ' || err_msg;

         goto ERROR_LABEL;
      END IF;

      --
      -- Sync processed rows with item star table
      --
        IF l_inv_debug_level IN(101, 102) THEN
                INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: calling INV_ENI_ITEMS_STAR_PKG.Sync_Star_Items_From_IOI');
        END IF;

      --Bug: 2718703 checking for ENI product before calling their package
      --This check has been moved to INV_ENI_ITEMS_STAR_PKG
      -- Call India localization API
      BEGIN
         SELECT 'Y' INTO l_child_records
         FROM DUAL
         WHERE EXISTS (SELECT NULL
                    FROM  mtl_system_items_interface msii,
                          mtl_parameters mp
                    WHERE transaction_type   =  'CREATE'
                    AND process_flag         =  7
                    AND set_process_id       =  xset_id
                    AND msii.organization_id =  mp.organization_id
                    AND mp.organization_id   <> mp.master_organization_id);

         INV_ITEM_EVENTS_PVT.Invoke_JAI_API(
            p_action_type              =>  'IMPORT'
           ,p_organization_id          =>  null
           ,p_inventory_item_id        =>  null
           ,p_source_organization_id   =>  null
           ,p_source_inventory_item_id =>  null
           ,p_set_process_id           =>  xset_id
           ,p_called_from              => 'INVPOPIB');

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL; --Child records not created, no need to call JAI api's
         WHEN OTHERS THEN
              err_msg := SUBSTR('INVPOPIF: Error:' ||SQLERRM ||' while IL API call ',1,240);
                IF l_inv_debug_level IN(101, 102) THEN
                        INVPUTLI.info(err_msg);
                END IF;
      END;

   END IF;  -- pro_item_flag = 1

   RETURN (0);

   <<ERROR_LABEL>>
    err_text := SUBSTRB(err_msg, 1,240);

    RETURN (ret_code);

EXCEPTION

-- Parameter ret_code is defaulted to 1,  which is passed
-- back for oracle error in UPDATE st.

   WHEN others THEN
      err_text := substr('INVPOPIF.inopinp_OI_process_create ' || SQLERRM , 1,240);
      IF l_inv_debug_level IN(101, 102) THEN
              INVPUTLI.info('INVPOPIF.inopinp_OI_process_create: About to rollback.');
      END IF;
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
   l_inv_debug_level    NUMBER  := INVPUTLI.get_debug_level;  --Bug: 4667453
BEGIN

        IF l_inv_debug_level IN(101, 102) THEN
                INVPUTLI.info('INVPOPIF.indelitm_delete_item_oi: begin');
        END IF;

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

   IF l_inv_debug_level IN(101, 102) THEN
           INVPUTLI.info('INVPOPIF.indelitm_delete_item_oi: end');
   END IF;


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
     AND    (transaction_type = 'SYNC' OR
             (transaction_type = 'UPDATE' AND inventory_item_id IS NOT NULL AND
	      (item_number IS NOT NULL OR 
	       SEGMENT1 IS NOT NULL OR SEGMENT2 IS NOT NULL OR SEGMENT3 IS NOT NULL OR SEGMENT4 IS NOT NULL OR
	       SEGMENT5 IS NOT NULL OR SEGMENT6 IS NOT NULL OR SEGMENT7 IS NOT NULL OR SEGMENT8 IS NOT NULL OR
	       SEGMENT9 IS NOT NULL OR SEGMENT10 IS NOT NULL OR SEGMENT11 IS NOT NULL OR SEGMENT12 IS NOT NULL OR
	       SEGMENT13 IS NOT NULL OR SEGMENT14 IS NOT NULL OR SEGMENT15 IS NOT NULL OR SEGMENT16 IS NOT NULL OR
	       SEGMENT17 IS NOT NULL OR SEGMENT18 IS NOT NULL OR SEGMENT19 IS NOT NULL OR SEGMENT20 IS NOT NULL
	      )
             )
            )
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

   CURSOR c_item_exists(cp_item_id NUMBER,
		        cp_org_id  NUMBER) IS
     SELECT 1 ,concatenated_segments 
     FROM   mtl_system_items_b_kfv
     WHERE  inventory_item_id = cp_item_id
--Bug 4964023 - Adding the org id clause for org assign case     
       AND  organization_id = cp_org_id;

   CURSOR c_fetch_by_item_number(cp_item_number MTL_SYSTEM_ITEMS_B_KFV.CONCATENATED_SEGMENTS%TYPE,
		        cp_org_id  NUMBER) IS
     SELECT inventory_item_id
     FROM   mtl_system_items_b_kfv
     WHERE  concatenated_segments = cp_item_number
       AND  organization_id = cp_org_id;

    /* Bug 6200383 Added one more AND condition on organization_id */  
   CURSOR c_revision_exists(cp_item_id   NUMBER,
                            cp_rev_id    NUMBER,
                            cp_revision  VARCHAR, 
			    cp_org_id    NUMBER) IS
     SELECT  1
     FROM   mtl_item_revisions
     WHERE  inventory_item_id = cp_item_id
     AND    (revision_id      = cp_rev_id
             OR revision      = cp_revision)
     AND    organization_id   = cp_org_id ; 



   l_item_exist NUMBER(10) := 0;
   l_err_text   VARCHAR2(200);
   l_rev_exist  NUMBER(10) := 0;
   l_status      NUMBER(10):= 0;
   l_item_id    mtl_system_items_b.inventory_item_id%TYPE;
   l_item_number MTL_SYSTEM_ITEMS_B_KFV.CONCATENATED_SEGMENTS%TYPE;
   l_inv_debug_level    NUMBER := INVPUTLI.get_debug_level;
   dumm_status         NUMBER;
   l_updateable_item_number varchar2(10);
   LOGGING_ERR EXCEPTION;

   FUNCTION isMasterOrg ( cp_orgid NUMBER
   		        ) RETURN NUMBER
   IS
   l_masterOrg NUMBER;
   BEGIN
      SELECT 1
        INTO l_masterOrg
        FROM mtl_parameters
       WHERE master_organization_id = cp_orgid
         AND rownum = 1;

      return 1;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           return 0;
   END isMasterOrg;

BEGIN
   fnd_profile.get('INV_UPDATEABLE_ITEM', l_updateable_item_number);
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
         ELSIF (item_record.segment1 || item_record.segment2 || item_record.segment3 || item_record.segment4 || 
                  item_record.segment5 || item_record.segment6 || item_record.segment7 || item_record.segment8 || 
         	  item_record.segment9 || item_record.segment10 || item_record.segment11 || item_record.segment12 ||
                  item_record.segment13 || item_record.segment14 || item_record.segment15 || item_record.segment16 || 
         	  item_record.segment17 || item_record.segment18 || item_record.segment19 || item_record.segment20  )
		  IS NOT NULL THEN
             l_status := INVPUOPI.mtl_pr_parse_item_segments(
	                    P_ROW_ID    => item_record.rowid,
			    ITEM_NUMBER => item_record.item_number,
			    ITEM_ID     => item_record.inventory_item_id,
			    ERR_TEXT    => l_err_text);
         END IF; --ITEM NUMBER
         l_item_exist := INVUPD1B.EXISTS_IN_MSI(
                 ROW_ID      => item_record.rowid
                ,ORG_ID      => item_record.organization_id
                ,INV_ITEM_ID => l_item_id
                ,TRANS_ID    => item_record.transaction_id
                ,ERR_TEXT    => l_err_text
                ,XSET_ID     => p_set_id);

      ELSE --INVENTORY_ITEM_ID IS NOT NULL
        l_item_id := item_record.inventory_item_id;
        OPEN  c_item_exists(item_record.inventory_item_id,
                         item_record.organization_id);
        FETCH c_item_exists INTO l_item_exist, l_item_number;
        CLOSE c_item_exists;

        l_item_exist := NVL(l_item_exist,0);
       
	IF ( item_record.transaction_type = 'UPDATE' AND l_item_exist <> 0 AND REPLACE(item_record.item_number,'\','') <> REPLACE(item_record.item_number,'\','') ) THEN
	-- UPDATE row MSII item number is different than compared to  
	--        MSIBKFV item number fetched using MSII inventory_item_id
	-- Both l_item_number and item_record.item_number cannot be NULL, hence NVL is not used
	
           IF l_inv_debug_level IN(101, 102) THEN
                INVPUTLI.info('INVPOPIF.update sync records: Item Number update' || item_record.item_number || ' ' || l_item_number || ' ' || l_item_id);
           END IF;

           IF ( l_updateable_item_number <> 'Y' ) THEN
              dumm_status := INVPUOPI.mtl_log_interface_err(-1,fnd_global.user_id,fnd_global.login_id,
	                fnd_global.prog_appl_id,fnd_global.conc_program_id,fnd_global.conc_request_id,item_record.transaction_id,
                        'INVPOPIF: Update to Item number not allowed',
                        'ITEM NUMBER',
                        'MTL_SYSTEM_ITEMS_INTERFACE',
                        'INV_ITEM_NUMBER_NO_UDPATE',
                        l_err_text);
             IF dumm_status < 0 THEN
               raise LOGGING_ERR;
             END IF;           

             update mtl_system_items_interface
                set process_flag = 3
              where rowid  = item_record.rowid ;

           END IF;

           IF ( isMasterOrg(item_record.organization_id) = 0 ) THEN
              dumm_status := INVPUOPI.mtl_log_interface_err(-1,fnd_global.user_id,fnd_global.login_id,
	                fnd_global.prog_appl_id,fnd_global.conc_program_id,fnd_global.conc_request_id,item_record.transaction_id,
                        'INVPOPIF: Update to Item number not allowed in child organization',
                        'ITEM NUMBER',
                        'MTL_SYSTEM_ITEMS_INTERFACE',
                        'INV_ITEM_NUMBER_ORG_NO_UDPATE',
                        l_err_text);
             IF dumm_status < 0 THEN
               raise LOGGING_ERR;
             END IF;           

             update mtl_system_items_interface
                set process_flag = 3
              where rowid  = item_record.rowid ;

           END IF;

           l_item_exist := 0;
           --This update might lead to duplicate ITEM NUMBER in MSIBKFV
	   OPEN c_fetch_by_item_number(item_record.item_number, item_record.organization_id);
           FETCH c_fetch_by_item_number INTO l_item_exist;
	   CLOSE c_fetch_by_item_number;

	   IF (l_item_exist <> 0 AND l_item_exist <> l_item_id) THEN
              IF l_inv_debug_level IN(101, 102) THEN
                INVPUTLI.info('INVPOPIF.update sync records: Item Number update to duplicate case:' || item_record.item_number || ' ' || l_item_exist || ' ' || l_item_id);
              END IF;
              dumm_status := INVPUOPI.mtl_log_interface_err(-1,fnd_global.user_id,fnd_global.login_id,
	                fnd_global.prog_appl_id,fnd_global.conc_program_id,fnd_global.conc_request_id,item_record.transaction_id,
                        'INVPOPIF: Update to Duplicate Item number',
                        'ITEM NUMBER',
                        'MTL_SYSTEM_ITEMS_INTERFACE',
                        'INV_UPDATE_TO_EXIST_ITEM_NAME',
                        l_err_text);
             IF dumm_status < 0 THEN
               raise LOGGING_ERR;
             END IF;

             update mtl_system_items_interface
                set process_flag = 3
              where rowid  = item_record.rowid ;

	   END IF;  
	 END IF;
      END IF; --ITEM ID

      IF l_item_exist <> 0 THEN
         UPDATE mtl_system_items_interface
            SET transaction_type  = 'UPDATE'
          WHERE rowid = item_record.rowid
	    AND transaction_type  = 'SYNC';
      ELSE
         UPDATE mtl_system_items_interface
            SET transaction_type = 'CREATE'
          WHERE rowid = item_record.rowid
 	    AND transaction_type  = 'SYNC';
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

      /* Bug 6200383 Added one more parameter cp_org_id to the cursor c_revision_exists */
      OPEN c_revision_exists(cp_item_id  => l_item_id,
                             cp_rev_id   => revision_record.revision_id,
			     cp_revision => revision_record.revision, 
                             cp_org_id   => revision_record.organization_id); 
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

/*
This Procedure populates ITEM_CATALOG_GROUP_ID column for IOI records
where a valid ITEM_CATALOG_GROUP_NAME is provided and the ID field is NULL.
If both the fields are NOT NULL no than action is taken.
It also marks the records as errored if the ITEM_CATALOG_GROUP_NAME
fails to validate against the Item Catalogs KFV.
*/
PROCEDURE UPDATE_ITEM_CATALOG_ID(
            p_set_id       IN NUMBER
           ,p_prog_appid   IN NUMBER
           ,p_prog_id      IN NUMBER
           ,p_request_id   IN NUMBER
           ,p_user_id      IN NUMBER
           ,p_login_id     IN NUMBER
           ,x_err_text   IN OUT NOCOPY VARCHAR2) IS

LOGGING_ERR      EXCEPTION;
CURSOR update_catg_name(p_catg_name IN VARCHAR2) IS
      SELECT ROWID, msii.TRANSACTION_ID
      FROM mtl_system_items_interface msii
      WHERE SET_PROCESS_ID = p_set_id
        AND msii.ITEM_CATALOG_GROUP_NAME = p_catg_name;

--Holds {Item Catalog Group Name: Item Catalog ID}
TYPE Item_Catalog_Group_Type IS TABLE OF
   VARCHAR2(2000)
   INDEX BY BINARY_INTEGER;
Item_Catalogs_Table  Item_Catalog_Group_Type;

l_Item_Catalog_Group_ID
            mtl_item_catalog_groups_b.ITEM_CATALOG_GROUP_ID%TYPE;
l_Item_Catalog_Group_Name
            mtl_system_items_interface.ITEM_CATALOG_GROUP_NAME%TYPE;

l_Item_Catalog     VARCHAR2(2000);
l_index            INTEGER;
l_dumm_status      NUMBER;

BEGIN
	 -- Bug 10404086 : Added below query.
   SELECT /*+ first_rows index(msii, MTL_SYSTEM_ITEMS_INTERFACE_N3) */ 
	 DISTINCT msii.ITEM_CATALOG_GROUP_NAME ||
             ':' || bkfv.ITEM_CATALOG_GROUP_ID
     BULK COLLECT INTO Item_Catalogs_Table
   FROM mtl_system_items_interface msii,
        mtl_item_catalog_groups_b_kfv bkfv
   WHERE msii.ITEM_CATALOG_GROUP_ID IS NULL
     AND msii.ITEM_CATALOG_GROUP_NAME IS NOT NULL
     AND msii.SET_PROCESS_ID = p_set_id
     AND msii.ITEM_CATALOG_GROUP_NAME = bkfv.CONCATENATED_SEGMENTS(+);

   l_index := Item_Catalogs_Table.FIRST;
   WHILE l_index IS NOT NULL
   LOOP
   l_Item_Catalog := Item_Catalogs_Table(l_index);
   l_Item_Catalog_Group_Name := SUBSTR(l_Item_Catalog, 1,
                                      INSTR(l_Item_Catalog,':') - 1);

   IF LENGTH(l_Item_Catalog) = INSTR(l_Item_Catalog,':') THEN
   --No ID is selected for this catalog name ...Mark these records as errored
      FOR cr IN update_catg_name(p_catg_name => l_Item_Catalog_Group_Name)
      LOOP
         l_dumm_status := INVPUOPI.mtl_log_interface_err(
                        -1,
                        p_user_id,
                        p_login_id,
                        p_prog_appid,
                        p_prog_id,
                        p_request_id,
                        cr.transaction_id,
                        'INVPOPIF: Invalid Item Catalog Group Name',
                        'ITEM_CATALOG_GROUP_NAME',
                        'MTL_SYSTEM_ITEMS_INTERFACE',
                        'INV_IOI_CATG_NAME_INVALID',
                        x_err_text);
         IF l_dumm_status < 0 then
            raise LOGGING_ERR;
         END IF;

         UPDATE MTL_SYSTEM_ITEMS_INTERFACE MSII
         SET PROCESS_FLAG = 3
         WHERE ROWID  = cr.ROWID ;
      END LOOP; --cr

   ELSE --Get the ID and populate in the ITEM_CATALOG_GROUP_ID column
      l_Item_Catalog_Group_ID
           := SUBSTR(l_Item_Catalog, INSTR(l_Item_Catalog,':',-1) +1);--bug14083302

			-- Bug 10404086 : Added below query.
      UPDATE /*+ first_rows index(MSII, MTL_SYSTEM_ITEMS_INTERFACE_N3) */ 
			MTL_SYSTEM_ITEMS_INTERFACE MSII
      SET MSII.ITEM_CATALOG_GROUP_ID = l_Item_Catalog_Group_ID
      WHERE SET_PROCESS_ID = p_set_id
        AND MSII.ITEM_CATALOG_GROUP_NAME = l_Item_Catalog_Group_Name;
   END IF;
   l_index := Item_Catalogs_Table.NEXT(l_index);
   END LOOP;

END UPDATE_ITEM_CATALOG_ID;


/* This procedure is validate released ICC,As PIM 4 Telco only released ICC are allowed for Item Creation.*/
PROCEDURE VALIDATE_RELEASED_ICC(
            p_set_id       IN NUMBER
           ,p_prog_appid   IN NUMBER
           ,p_prog_id      IN NUMBER
           ,p_request_id   IN NUMBER
           ,p_user_id      IN NUMBER
           ,p_login_id     IN NUMBER
           ,x_err_text   IN OUT NOCOPY VARCHAR2) IS
           dumm_status      NUMBER;
           LOGGING_ERR      EXCEPTION;
           CURSOR cur_non_released_icc IS
                          SELECT  msii.item_catalog_group_id, msii.ROWID, msii.transaction_id
                                  FROM    mtl_system_items_interface msii
                                  WHERE     msii.item_catalog_group_id IS NOT NULL
                                  AND     msii.set_process_id  = p_set_id -- p_set_process_id
                                  AND     msii.process_flag  = 1
                                  AND     NOT EXISTS
                                  ( SELECT  1 FROM EGO_MTL_CATALOG_GRP_VERS_B emcgvb
                                    WHERE     emcgvb.item_catalog_group_id=msii.item_catalog_group_id
                                    AND       emcgvb.VERSION_SEQ_ID <> 0
                                    AND        emcgvb.START_ACTIVE_DATE IS NOT NULL AND emcgvb.START_ACTIVE_DATE <= SYSDATE)  ;

      BEGIN  
        FOR cr IN cur_non_released_icc LOOP
                  dumm_status := INVPUOPI.mtl_log_interface_err(
                                    -1,
                                    p_user_id,
                                    p_login_id,
                                    p_prog_appid,
                                    p_prog_id,
                                    p_request_id,
                                    cr.transaction_id,
                                    'Item Catalog Category should have released version for creating item.',
                                    'ITEM_CATALOG_GROUP_NAME',
                                    'MTL_SYSTEM_ITEMS_INTERFACE',
                                    'INV_IOI_NON_REL_CATG',
                                     x_err_text);
                  if dumm_status < 0 then
                    raise LOGGING_ERR;
                  end if;

              update mtl_system_items_interface
              set process_flag = 3
              where rowid  = cr.rowid ;
        END LOOP;
END VALIDATE_RELEASED_ICC;


END INVPOPIF;
/
--show errors package body INVPOPIF

COMMIT;
EXIT;
