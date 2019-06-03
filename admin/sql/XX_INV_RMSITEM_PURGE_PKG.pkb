CREATE OR REPLACE PACKAGE BODY XX_INV_RMSITEM_PURGE_PKG
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  XX_INV_RMSITEM_PURGE_PKG.pkb                                        |
-- | Description :  ESB RMS Item Purge Package Body                                     |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===================================        |
-- |1.0       10-Jun-2008 Paddy Sanjeevi       Initital Version                         |
-- |1.1       19-Oct-2015   Madhu Bolli        Remove schema for 12.2 retrofit          |
-- +====================================================================================+
AS
----------------------------
--Declaring Global Constants
----------------------------
G_USER_ID                   CONSTANT xx_inv_item_purge_int.created_by%TYPE            :=   FND_GLOBAL.user_id;
G_DATE                      CONSTANT xx_inv_item_purge_int.last_update_date%TYPE      :=   SYSDATE;
G_PACKAGE_NAME              CONSTANT VARCHAR2(30)                                     :=  'XX_INV_RMSITEM_PURGE_PKG';
G_APPLICATION               CONSTANT VARCHAR2(10)                                     :=  'XXMER';
G_CHILD_PROGRAM             CONSTANT VARCHAR2(50)                                     :=  'XX_INV_RMSITEM_PURGE_CHILD';
----------------------------
--Declaring Global Variables
----------------------------
gc_sqlerrm                  VARCHAR2(5000);
gc_sqlcode                  VARCHAR2(20);
gn_request_id               PLS_INTEGER;
gn_batch_size               PLS_INTEGER;
ln_master_org            PLS_INTEGER := 0;
gn_threads            PLS_INTEGER ;
gn_del_grp_id            PLS_INTEGER;
gn_master_org_id            mtl_parameters.organization_id%TYPE;
gn_sleep            NUMBER:=60;
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
END display_out;


PROCEDURE purge_delete_groups
IS

CURSOR C1 IS
SELECT DISTINCT a.del_grp_id
  FROM xx_inv_item_purge_int a
 WHERE process_flag=7
   AND EXISTS (SELECT 'x' 
		 FROM bom_delete_groups
		WHERE delete_group_sequence_id=a.del_grp_id);


CURSOR c3 IS
SELECT segment1,rowid drowid
  FROM xx_inv_item_purge_int
 WHERE process_Flag=7
   AND creation_date<SYSDATE-90;

i NUMBER:=0;

BEGIN
  FOR cur IN c1 LOOP
    DELETE
      FROM bom_delete_entities
     WHERE delete_group_sequence_id=cur.del_grp_id;

    DELETE
      FROM bom_delete_groups
     WHERE delete_group_sequence_id=cur.del_grp_id;
  END LOOP;
  COMMIT;  

  FOR cur IN C3 LOOP

    i :=i+1;
    IF i>5000 THEN
       COMMIT;
       i:=0;
    END IF;
    
    DELETE
      FROM xx_inv_item_purge_int
     WHERE rowid=cur.drowid;

  END LOOP;

EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while purging delete groups '||sqlerrm);
END purge_delete_groups;

PROCEDURE set_purge_items( p_item_size IN NUMBER)
IS

CURSOR c_master_org
IS
SELECT MP.organization_id
  FROM mtl_parameters MP
 WHERE MP.organization_id=MP.master_organization_id
   AND ROWNUM=1;

CURSOR C1 IS
SELECT segment1
  FROM xx_inv_item_purge_int a
 WHERE process_Flag=1
   AND master_item_flag='Y'
   AND extract_flag='D'
   AND EXISTS (SELECT 'x'
		     FROM xx_inv_item_purge_int
	            WHERE segment1=a.segment1
		      AND process_flag=4
		      AND extract_flag='V'
		      AND check_flag='Y'
		      AND delete_flag='N'
	      );


CURSOR C3 IS
SELECT segment1,rowid drowid
  FROM xx_inv_item_purge_int a
 WHERE process_Flag=1
   AND master_item_flag='Y'
   AND extract_flag='D'
   AND NOT EXISTS (SELECT 'x'
		       FROM xx_inv_item_purge_int
	              WHERE segment1=a.segment1
		        AND process_flag=4
		        AND master_item_flag='Y'
		        AND extract_flag='V'
		        AND check_flag IN ('Y','F')
		        AND delete_flag='N'
 	             );


CURSOR C_notexists IS
SELECT segment1,rowid drowid
  FROM xx_inv_item_purge_int a
 WHERE process_Flag=1
   AND master_item_flag='Y'
   AND extract_flag='D' 
   AND inventory_item_id IS NULL;




v_cnt    	NUMBER:=0;
i    	 	NUMBER:=0;
ln_pending 	NUMBER:=0;

BEGIN

  SELECT COUNT(1)
    INTO ln_pending
    FROM od_purge_confirmation@RMS.NA.ODCORP.NET
   WHERE APP_ID=19
     AND ACTION_CD='D'
     AND conf_flg IS NULL;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records to be Deleted :'||TO_CHAR(ln_pending));

  BEGIN
    INSERT 
      INTO xx_inv_item_purge_int
           (segment1,process_flag,master_item_flag,extract_flag,
            check_flag,delete_flag,error_flag,
            creation_date,created_by,last_update_date,last_updated_by)
    SELECT ITEM,1,'Y','D','N','N','N',SYSDATE,G_USER_ID,SYSDATE,G_USER_ID
      FROM od_purge_confirmation@RMS.NA.ODCORP.NET a
     WHERE APP_ID=19
       AND ACTION_CD='D' 
       AND ROWNUM<p_item_size
       AND conf_flg IS NULL;
  EXCEPTION
    WHEN others THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Extracting from RMS failed for Validation :'||SQLERRM);
  END;
  COMMIT;

  OPEN c_master_org;
  FETCH c_master_org INTO gn_master_org_id;
  CLOSE c_master_org;

  UPDATE xx_inv_item_purge_int a
     SET (inventory_item_id,organization_id)=(SELECT inventory_item_id,organization_id
                                   FROM mtl_systeM_items_b
                         WHERE organization_id=gn_master_org_id
                           AND segment1=a.segment1)
   WHERE process_Flag=1
     AND master_item_flag='Y'
     AND extract_flag='D'
     AND load_batch_id IS NULL;
  COMMIT;


  FOR cur IN C_notexists LOOP

    UPDATE od_purge_confirmation@RMS.NA.ODCORP.NET
       SET conf_flg='Y',
	   conf_user='APPS',
	   conf_date=sysdate
     WHERE item=cur.segment1
       AND action_cd='D'
       AND app_id=19;

    UPDATE xx_inv_item_purge_int a
       SET process_flag=7,request_id=gn_request_id,
	   delete_Flag='Y'
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;

  FOR cur IN C3 LOOP

    UPDATE od_purge_confirmation@RMS.NA.ODCORP.NET
       SET conf_flg='N',
           conf_reason='Item not received for Validation from RMS before Deletion',
	   conf_user='APPS',
	   conf_date=sysdate
     WHERE item=cur.segment1
       AND action_cd='D'
       AND app_id=19;

    UPDATE xx_inv_item_purge_int a
       SET error_message='Item not received for Validation from RMS before Deletion',
	   process_flag=7
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;


  FOR cur IN C1 LOOP


    i:=i+1;

    UPDATE xx_inv_item_purge_int
       SET delete_flag='P',
	   load_batch_id=NULL,
	   del_grp_id=NULL,
	   request_id=NULL,
	   delete_entity_sequence_id=NULL,
	   error_flag='N',
	   error_message=NULL
     WHERE segment1=cur.segment1
       AND extract_flag='V'
       AND check_Flag='Y'
       AND delete_flag='N';

    IF i>=5000 THEN
       i:=0;
       COMMIT;
    END IF;

  END LOOP;
  
  COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error in set_purge_items '||sqlerrm);
END set_purge_items;


-- +======================================================================+
-- | Name        :  Extract_item                                          |
-- | Description :  This procedure extract item/locs for the item         |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  None                                                  |
-- |                                                                      |
-- | Returns     :  x_errbuf                                              |
-- |                x_retcode                                             |
-- +======================================================================+

PROCEDURE extract_item ( p_item_size IN NUMBER)
IS
CURSOR c_master_org
IS
SELECT MP.organization_id
  FROM mtl_parameters MP
 WHERE MP.organization_id=MP.master_organization_id
   AND ROWNUM=1;

CURSOR C1 IS
SELECT segment1
      ,inventory_item_id
      ,rowid drowid
  FROM xx_inv_item_purge_int a
 WHERE process_Flag=1
   AND master_item_flag='Y'
   AND extract_flag='V';

CURSOR C2(p_item_id NUMBER) IS
SELECT b.inventory_item_id
      ,b.organization_id
  FROM mtl_system_items_b b
 WHERE b.inventory_item_id=p_item_id
   AND b.organization_id<>gn_master_org_id;


CURSOR c_exists
IS
SELECT item
  FROM od_purge_confirmation@RMS.NA.ODCORP.NET a
 WHERE APP_ID=19
   AND ACTION_CD='V' 
   AND conf_flg IS NULL
   AND EXISTS (SELECT 'x'
	         FROM xx_inv_item_purge_int
   	        WHERE segment1=a.item
		  AND process_Flag<>7);


CURSOR C_notexists IS
SELECT segment1,rowid drowid
  FROM xx_inv_item_purge_int a
 WHERE process_Flag=1
   AND master_item_flag='Y'
   AND extract_flag='V' 
   AND inventory_item_id IS NULL;

j         	NUMBER:=0;
ln_seq          PLS_INTEGER;
ln_pending	NUMBER:=0;


BEGIN

  FOR cur IN c_exists LOOP

    UPDATE xx_inv_item_purge_int
       SET process_Flag=7
     WHERE segment1=cur.item;

    COMMIT;
  
  END LOOP;


  SELECT COUNT(1)
    INTO ln_pending
    FROM od_purge_confirmation@RMS.NA.ODCORP.NET
   WHERE APP_ID=19
     AND ACTION_CD='V'
     AND conf_flg IS NULL;

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Records to be Validated :'||TO_CHAR(ln_pending));

  BEGIN
    INSERT 
      INTO xx_inv_item_purge_int
           (segment1,process_flag,master_item_flag,extract_flag,
            check_flag,delete_flag,error_flag,
            creation_date,created_by,last_update_date,last_updated_by)
    SELECT ITEM,1,'Y','V','N','N','N',SYSDATE,G_USER_ID,SYSDATE,G_USER_ID
      FROM od_purge_confirmation@RMS.NA.ODCORP.NET a
     WHERE APP_ID=19
       AND ACTION_CD='V' 
       AND ROWNUM<p_item_size
       AND conf_flg IS NULL;
  EXCEPTION
    WHEN others THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Extracting from RMS failed for Validation :'||SQLERRM);
  END;
  COMMIT;

  OPEN c_master_org;
  FETCH c_master_org INTO gn_master_org_id;
  CLOSE c_master_org;

  UPDATE xx_inv_item_purge_int a
     SET (inventory_item_id,organization_id)=(SELECT inventory_item_id,organization_id
                                   FROM mtl_systeM_items_b
                         WHERE organization_id=gn_master_org_id
                           AND segment1=a.segment1)
   WHERE process_Flag=1
     AND master_item_flag='Y'
     AND load_batch_id IS NULL;
  COMMIT;


  FOR cur IN C_notexists LOOP

    UPDATE od_purge_confirmation@RMS.NA.ODCORP.NET
       SET conf_flg='Y',
	   conf_user='APPS',
	   conf_date=sysdate
     WHERE item=cur.segment1
       AND app_id=19
       AND action_cd='V';

    UPDATE xx_inv_item_purge_int a
       SET process_flag=7,
	   check_Flag='Y'
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;

  FOR cur IN C1 LOOP
    IF j>5000 THEN
       COMMIT;
       j:=0;
    END IF;
    FOR c IN C2(cur.inventory_item_id) LOOP
      BEGIN
        INSERT 
      INTO xx_inv_item_purge_int
           (segment1,inventory_item_id,organization_id,process_flag,master_item_flag,
            check_flag,delete_flag,error_flag,
            creation_date,created_by,last_update_date,last_updated_by,extract_flag)
        VALUES 
           (cur.segment1,c.inventory_item_id,c.organization_id,1,'N','N','N','N',
            sysdate,G_USER_ID,sysdate,G_USER_ID,'V');
      EXCEPTION
    WHEN others THEN
      NULL;    
      END;
      j:=J+1;
    END LOOP;
  END LOOP;
  COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'When others Exception in extract_item :'||SQLERRM);
END extract_item;


PROCEDURE purge_item( x_errbuf      OUT NOCOPY VARCHAR2
                     ,x_retcode     OUT NOCOPY VARCHAR2
	             ,p_process        IN  VARCHAR2   
                     ,p_batch_id    IN  VARCHAR2
                    )
IS
ln_cnt                 NUMBER:=0;
ln_request_id            NUMBER;
j                NUMBER:=0;
v_wait                 BOOLEAN;
v_req_phase             VARCHAR2(100);
v_req_status             VARCHAR2(100);
v_dev_phase             VARCHAR2(100); 
v_dev_status             VARCHAR2(100);
v_req_message             VARCHAR2(1000);
EX_DEL_GRP_SETUP             EXCEPTION;
EX_DEL_GRP_ENT              EXCEPTION;


CURSOR c_master_org
IS
SELECT MP.organization_id
  FROM mtl_parameters MP
 WHERE MP.organization_id=MP.master_organization_id
   AND ROWNUM=1;

CURSOR c_del_org IS
SELECT a.inventory_item_id,
       a.organization_id,
       a.del_grp_id,
       a.rowid drowid
  FROM xx_inv_item_purge_int a
 WHERE del_grp_id=gn_del_grp_id
   AND EXISTS (SELECT 'x'
              FROM bom_delete_entities
        WHERE delete_group_sequence_id=a.del_grp_id
          AND inventory_item_id=a.inventory_item_id
          AND organization_id=a.organization_id
          AND delete_status_type=4);

CURSOR c_del_errors IS
SELECT  d.message_text
       ,a.delete_entity_sequence_id
       ,a.inventory_item_id
       ,a.organization_id
       ,e.rowid drowid
       ,e.segment1
       ,e.loc
       ,e.master_item_flag
  FROM  fnd_new_messages d
       ,bom_delete_sql_statements c
       ,bom_delete_errors  b
       ,bom_delete_entities a
       ,xx_inv_item_purge_int e
 WHERE e.del_grp_id=gn_del_grp_id
   AND a.delete_group_sequence_id=e.del_grp_id
   AND a.delete_status_type=3
   AND b.delete_entity_sequence_id=a.delete_entity_sequence_id
   AND c.sql_statement_name=b.sql_statement_name
   AND d.message_name=c.message_name
   AND e.inventory_item_id=a.inventory_item_id
   AND e.organization_id=a.organization_id;


CURSOR c_delseq(p_delgrp_id NUMBER) IS
SELECT   a.rowid drowid
    ,b.delete_group_sequence_id
    ,b.delete_entity_sequence_id
  FROM  bom_delete_entities b,
    xx_inv_item_purge_int a
 WHERE  a.load_batch_id=p_batch_id
   AND  b.delete_group_sequence_id=p_delgrp_id
   AND  b.inventory_item_id=a.inventory_item_id
   AND  b.organization_id=a.organization_id;

BEGIN

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Inside Purge Item');

  OPEN c_master_org;
  FETCH c_master_org INTO gn_master_org_id;
  CLOSE c_master_org;

  BEGIN
    INSERT 
      INTO bom_delete_groups 
         (DELETE_GROUP_SEQUENCE_ID, 
          DELETE_GROUP_NAME, 
          DESCRIPTION, 
          ORGANIZATION_ID, 
          DELETE_TYPE, 
          ACTION_TYPE, 
          ENGINEERING_FLAG, 
          LAST_UPDATE_DATE, 
          LAST_UPDATED_BY, 
          CREATION_DATE, 
          CREATED_BY) 
    VALUES
        (BOM_DELETE_GROUPS_S.NEXTVAL, 
         TO_CHAR(p_batch_id), 
         'RMSITEM Delete group for Deletion '||TO_CHAR(p_batch_id),
         gn_master_org_id, -- Master Organization Id
         1,     --1 stands for Item 
         2, --1 stands for CHECK, 2 stands for DELETE
         1, --1 stands for Production Item, 2 stands for Engineering Item
         sysdate, 
         -1, -- This has to be updated to the current Login iD value 
         sysdate, 
         -1 -- This has to be updated to the current Login iD value 
        ); 
  EXCEPTION
    WHEN others THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'when others while set up group for deletion :'||sqlerrm);
      RAISE EX_DEL_GRP_SETUP;
  END;

  BEGIN
    SELECT delete_group_sequence_id
      INTO gn_del_grp_id
      FROM bom_delete_groups
     WHERE organization_id=gn_master_org_id
       AND delete_group_name=TO_CHAR(p_batch_id);
  EXCEPTION
    WHEN others THEN
      x_errbuf :='Delete group is not defined '||SQLERRM;
      x_retcode:=2;
  END;

  BEGIN
    INSERT 
    INTO bom_delete_entities
          (   delete_entity_sequence_id
         ,delete_group_sequence_id
         ,delete_entity_type
         ,delete_status_type
         ,inventory_item_id
         ,organization_id
         ,item_description
         ,item_concat_segments
         ,prior_process_Flag
         ,prior_commit_flag
         ,last_update_date
         ,last_updated_by
         ,creation_date
         ,created_by
         ,last_update_login)
    SELECT  BOM_DELETE_ENTITIES_S.NEXTVAL
         ,gn_del_grp_id
         ,1            -- delete_entity_type (item)
         ,1            -- delete_status_type (Pending)
         ,m.inventory_item_id
         ,m.organization_id
         ,m.description
         ,m.segment1    
         ,2        -- prior_process_flag  (No)
         ,1        -- prior_commit_flag   (Yes)
         ,G_DATE
         ,G_USER_ID
         ,G_DATE
         ,G_USER_ID
         ,G_USER_ID
    FROM  mtl_system_items_b m
        , xx_inv_item_purge_int xil 
     WHERE xil.load_batch_id=p_batch_id
       AND m.inventory_item_id=xil.inventory_item_id
       AND m.organization_id=xil.organization_id;
  EXCEPTION
    WHEN others THEN
      RAISE EX_DEL_GRP_ENT;
  END;
  COMMIT;

  FOR cur IN c_delseq(gn_del_grp_id) LOOP

      UPDATE xx_inv_item_purge_int
     SET del_grp_id=gn_del_grp_id,
         delete_entity_sequence_id=cur.delete_entity_sequence_id
       WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;

  SELECT COUNT(1)
    INTO ln_cnt
    FROM bom_delete_entities
   WHERE delete_group_sequence_id=gn_del_grp_id;

  IF ln_cnt>0 THEN
     ln_request_id := FND_REQUEST.submit_request(
                                       application => 'BOM'
                                        ,program     => 'BMCDEL'
                                      ,sub_request =>  FALSE
                                                  ,argument1   =>  TO_CHAR(gn_del_grp_id)
                                                  ,argument2   =>  '2'
                                                  ,argument3   =>  '1'
                                                );
     IF ln_request_id = 0 THEN
        x_errbuf  := 'Unable to submit Delete Item information in Delete Mode';
        x_retcode :=2;
     ELSE
       COMMIT;

       IF (FND_CONCURRENT.WAIT_FOR_REQUEST(ln_request_id,1,60000,v_req_phase,
			v_req_status,v_dev_phase,v_dev_status,v_req_message))  THEN
          IF v_dev_phase = 'COMPLETE' THEN
             fnd_file.put_line(fnd_file.LOG, 'Request completed normal');
	  END IF;
       END IF;

     END IF;
  END IF;

  j:=0;
  FOR cur IN c_del_org LOOP
    j:=j+1;
    IF j>5000 THEN
       COMMIT;
       j:=0;
    END IF;
    IF p_process='LD' THEN

       DELETE
       FROM xx_inv_item_org_attributes
        WHERE inventory_item_id=cur.inventory_item_id
          AND organization_id=cur.organization_id;

        UPDATE xx_inv_item_purge_int
           SET process_Flag=7,
               loc_process_Flag=7,
               delete_flag='Y'
         WHERE rowid=cur.drowid;

    ELSIF p_process='MD' THEN

       DELETE
       FROM xx_inv_item_master_attributes
        WHERE inventory_item_id=cur.inventory_item_id
          AND organization_id=cur.organization_id;

       UPDATE xx_inv_item_purge_int
          SET process_Flag=5,
              loc_process_Flag=7,
              delete_flag='Y'
        WHERE rowid=cur.drowid;

    END IF;
  END LOOP;
  COMMIT;

  FOR cur IN c_del_errors LOOP

    UPDATE xx_inv_item_purge_int
       SET process_Flag=DECODE(cur.master_item_flag,'N',7,'Y',5),
       loc_process_Flag=6,
       delete_flag='F',
       error_flag='Y',
       error_message=error_message||','||cur.message_text
     WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;
EXCEPTION
  WHEN EX_DEL_GRP_SETUP THEN
      ROLLBACK;
      x_errbuf :='Error in setting up delete group :'||SQLERRM;
      x_retcode:=2;
  WHEN EX_DEL_GRP_ENT THEN
      ROLLBACK;
      x_errbuf :='Error in inserting bom_delete_entities :'||SQLERRM;
      x_retcode:=2;
  WHEN others THEN
    x_errbuf  :='Error in end of When others : '||SQLERRM;
    x_retcode :=2;    
END purge_item;


-- +======================================================================+
-- | Name        :  bat_child                                             |
-- | Description :  This procedure is invoked from the submit_sub_requests|
-- |                procedure. This would submit child requests based     |
-- |                on batch_size.                                        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_request_id, p_master                                |
-- |                                                                      |
-- | Returns     :  x_errbuf                                              |
-- |                x_retcode                                             |
-- +======================================================================+
PROCEDURE bat_child( x_errbuf              OUT NOCOPY VARCHAR2
                    ,x_retcode             OUT NOCOPY VARCHAR2
            ,p_process           IN  VARCHAR2
                   )
IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_SUBMIT_CHILD         EXCEPTION;
ln_seq                  PLS_INTEGER;
ln_run_count           PLS_INTEGER:=0;
ln_loc_count            PLS_INTEGER;
lt_conc_request_id      FND_CONCURRENT_REQUESTS.request_id%TYPE;
ln_del_grp_id            PLS_INTEGER;
BEGIN

  SELECT XX_INV_ITEM_PURGE_S.NEXTVAL
    INTO   ln_seq
    FROM   DUAL;

    ----------------------------------------------------------------------------
    --Updating xx_inv_item_purge_int table with load batch id and process flag
    ----------------------------------------------------------------------------
   IF p_process='LC' THEN
      UPDATE XX_INV_ITEM_PURGE_INT
         SET load_batch_id=ln_seq
        ,request_id=gn_request_id
            ,loc_process_flag = (CASE WHEN loc_process_flag  IS NULL  OR loc_process_flag = 1                     

                THEN 2 
                   ELSE loc_process_flag      
                   END)
      WHERE process_flag   = 1
        AND master_item_flag='N'
        AND check_Flag='N'
        AND load_batch_id  IS NULL
        AND del_grp_id IS NULL
        AND ROWNUM<=gn_batch_size;
  ELSIF p_process='MC' THEN
      UPDATE XX_INV_ITEM_PURGE_INT
         SET load_batch_id=ln_seq
        ,request_id=gn_request_id
            ,loc_process_flag = (CASE WHEN loc_process_flag  IS NULL  OR loc_process_flag = 1                     

                THEN 2 
                   ELSE loc_process_flag      
                   END)
      WHERE process_flag   = 1
        AND master_item_flag='Y'
        AND check_Flag='N'
        AND del_grp_id IS NULL
        AND load_batch_id  IS NULL
        AND ROWNUM<=gn_batch_size;
  ELSIF p_process='LD' THEN
   
      UPDATE xx_inv_item_purge_int
         SET load_batch_id=ln_seq
            ,request_id=gn_request_id
       WHERE process_flag = 4
         AND master_item_flag='N'
         AND check_flag='Y'
         AND delete_flag='P'
	 AND load_batch_id IS NULL
	 AND ROWNUM<=gn_batch_size;

  ELSIF p_process='MD' THEN

      UPDATE xx_inv_item_purge_int
         SET load_batch_id=ln_seq
            ,request_id=gn_request_id
       WHERE process_flag = 4
         AND master_item_flag='Y'
         AND check_flag='Y'
         AND delete_flag='P'
         AND load_batch_id IS NULL
         AND ROWNUM<=gn_batch_size;
  END IF;
  ln_loc_count := SQL%ROWCOUNT;
  COMMIT;

  LOOP
    SELECT COUNT(1)
      INTO ln_run_count
      FROM fnd_concurrent_requests
     WHERE concurrent_program_id IN (SELECT concurrent_program_id
                           FROM fnd_concurrent_programs
                      WHERE concurrent_program_name='XX_INV_RMSITEM_PURGE_CHILD'
                        AND enabled_flag='Y')
       AND phase_code IN ('P','R');

       IF ln_run_count<gn_threads THEN

           -----------------------------------------
           --Submitting Child Program for each batch
           -----------------------------------------
          IF p_process IN ('LC','MC') THEN
             IF ln_loc_count > 0  THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG,'SUbmitting Child for the batch :'||TO_CHAR(ln_seq)||','||p_process);

                lt_conc_request_id := FND_REQUEST.submit_request(
                                                        application =>  G_APPLICATION
                                                       ,program     =>  G_CHILD_PROGRAM
                                                       ,sub_request =>  FALSE
                               ,argument1   =>  p_process
                                                       ,argument2   =>  ln_seq
                                                       );
                IF lt_conc_request_id = 0 THEN
                   x_errbuf  := FND_MESSAGE.GET;
                   RAISE EX_SUBMIT_CHILD;
                ELSE
                   COMMIT;
               END IF;
             END IF; --  IF ln_loc_count > 0  THEN

          ELSIF p_process IN ('LD','MD') THEN

             lt_conc_request_id := FND_REQUEST.submit_request(
                                                        application =>  G_APPLICATION
                                                       ,program     =>  G_CHILD_PROGRAM
 	        	                               ,sub_request =>  FALSE
        	        		               ,argument1   =>  p_process
                                                       ,argument2   =>  ln_seq
                                                       );
              IF lt_conc_request_id = 0 THEN
                   x_errbuf  := FND_MESSAGE.GET;
                   RAISE EX_SUBMIT_CHILD;
              ELSE
                   COMMIT;

              END IF;
 
          END IF;  --          ELSIF p_process IN ('LD','MD') THEN
         EXIT;
       ELSE        --       IF ln_run_count<gn_threads THEN
         DBMS_LOCK.SLEEP(gn_sleep);
       END IF;

  END LOOP;

EXCEPTION
  WHEN EX_SUBMIT_CHILD THEN
       x_retcode := 2;
       x_errbuf  := 'Error in submitting child requests: ' || x_errbuf;
END bat_child;



-- +====================================================================+
-- | Name        :  Update_RMS                                          |
-- | Description :  This procedure is invoked from the master_main      |
-- |                procedure to update the RMS with the validation     |
-- |                and delete mode results                             |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_mode                                              |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+
PROCEDURE update_rms( p_mode IN VARCHAR2
                    )
IS

CURSOR C1 IS
SELECT segment1,
       substr(error_message,1,240) error_message,
       error_flag
  FROM xx_inv_item_purge_int
 WHERE request_id=gn_request_id
   AND master_item_flag='Y'
   AND check_flag IN ('Y','F')
   AND delete_flag='N'
   AND extract_flag='V';



CURSOR C2 IS
SELECT segment1,substr(error_message,1,240) error_message,
       error_flag
  FROM xx_inv_item_purge_int
 WHERE process_flag=5
   AND master_item_flag='Y'
   AND check_flag IN ('Y','F')
   AND delete_flag IN ('Y','F');

BEGIN

  IF p_mode='V' THEN


     FOR cur IN C1 LOOP

       UPDATE od_purge_confirmation@RMS.NA.ODCORP.NET
          SET conf_flg=DECODE(cur.error_Flag,'Y','N','N','Y'),
              conf_reason=DECODE(cur.error_Flag,'Y',cur.error_message,'N',NULL),
              conf_user='APPS',
              conf_date=SYSDATE
        WHERE item=cur.segment1
          AND app_id=19
          AND action_cd='V';

     END LOOP;

     
  ELSIF p_mode='D' THEN

     FOR cur IN C2 LOOP

       UPDATE od_purge_confirmation@RMS.NA.ODCORP.NET
          SET conf_flg=DECODE(cur.error_Flag,'Y','N','N','Y'),
              conf_reason=DECODE(cur.error_Flag,'Y',cur.error_message,'N',NULL),
              conf_user='APPS',
              conf_date=SYSDATE
        WHERE item=cur.segment1
          AND app_id=19
          AND action_cd='D';

       UPDATE xx_inv_item_purge_int
          SET process_flag=7,
	      delete_Flag=decode(extract_Flag,'D','Y','V',delete_Flag)
	WHERE segment1=cur.segment1;

     END LOOP;

  END IF;
  COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in update_rms :'||sqlerrm);
END update_rms;



-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the             |
-- |                OD INV Item Interface Master Program. This would    |
-- |                submit child programs based on batch_size           |
-- |                                                                    |
-- |                                                                    |
-- | Parameters  :  p_master                                            |
-- |                                                                    |
-- | Returns     :  x_errbuf                                            |
-- |                x_retcode                                           |
-- |                                                                    |
-- +====================================================================+
PROCEDURE master_main(
                      x_errbuf              OUT NOCOPY VARCHAR2
                     ,x_retcode             OUT NOCOPY VARCHAR2
		     ,p_item_size	    IN  NUMBER
	             ,p_mode                IN  VARCHAR2
        	     ,p_threads             IN  NUMBER
	             ,p_batch_size          IN  NUMBER
                     )
IS

j             NUMBER:=0;
ln_total_count        PLS_INTEGER:=0;
ln_current_count    PLS_INTEGER:=0;
ln_request_id           NUMBER;
lc_error_message    VARCHAR2(4000);
ln_run_count        NUMBER;
p_process        VARCHAR2(2);
ln_mst_run        NUMBER;
ln_error_len        NUMBER;
lc_purge_stop    VARCHAR2(1);

CURSOR C2 IS
SELECT segment1,length(error_message) error_length
  FROM xx_inv_item_purge_int a
 WHERE process_Flag=1
   AND master_item_flag='Y'
   AND extract_flag='V'
   AND EXISTS (SELECT 'x'
		 FROM xx_inv_item_purge_int
		WHERE segment1=a.segment1
		  AND extract_flag='V'
	          AND check_Flag IN ('Y','F')
	      );

CURSOR C3(p_segment1 varchar2) IS
SELECT DISTINCT SUBSTR(error_message,1,90) error_message
  FROM xx_inv_item_purge_int
 WHERE segment1=p_segment1
   AND process_Flag=1
   AND master_item_flag='N'
   AND error_flag='Y'
   AND check_flag='F'
   AND delete_flag='N'
   AND error_message IS NOT NULL;


CURSOR C5 IS
SELECT segment1,length(error_message) error_length
  FROM xx_inv_item_purge_int a
 WHERE process_Flag=5
   AND master_item_flag='Y'
   AND EXISTS (SELECT 'x'
		 FROM xx_inv_item_purge_int
		WHERE segment1=a.segment1
		  AND extract_flag='V'
	          AND delete_Flag IN ('Y','F')
	      );

CURSOR C6(p_segment1 varchar2) IS
SELECT DISTINCT SUBSTR(error_message,1,90) error_message
  FROM xx_inv_item_purge_int
 WHERE segment1=p_segment1
   AND master_item_flag='N'
   AND error_flag='Y'
   AND delete_flag='F'
   AND error_message IS NOT NULL;

BEGIN

  -------------------------------------------------------------
  --Submitting Sub Requests corresponding to the Child Programs
  -------------------------------------------------------------
  gn_request_id   := FND_GLOBAL.CONC_REQUEST_ID;
  gn_threads        :=p_threads;
  gn_batch_size   :=p_batch_size;

  SELECT COUNT(1)
    INTO ln_mst_run
    FROM fnd_concurrent_requests
   WHERE concurrent_program_id IN (SELECT concurrent_program_id
                                     FROM fnd_concurrent_programs
                                    WHERE concurrent_program_name='XX_INV_RMSITEM_PURGE'
                                      AND enabled_flag='Y')
     AND phase_code IN ('P','R');

  IF ln_mst_run<=1 THEN
 
     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling Purge_delete_groups');  

     purge_delete_groups;



     IF p_mode='V' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling extract_item');  
        extract_item(p_item_size);
     END IF;

     IF p_mode='D' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling Set_Purge_items');  
        set_purge_items(p_item_size);
     END IF;

 
     LOOP    
 

       IF p_mode='V' THEN

          SELECT COUNT(1)
            INTO ln_current_count
            FROM DUAL
           WHERE EXISTS ( SELECT 'x'
                            FROM XX_INV_ITEM_PURGE_INT 
                           WHERE process_flag = 1
                             AND load_batch_id IS NULL
                             AND master_item_flag='N'
                             AND check_flag='N'
                        );
      
          p_process:='LC';

          IF ln_current_count=0 THEN

            LOOP   
              SELECT COUNT(1)
                INTO ln_run_count
                FROM fnd_concurrent_requests
               WHERE concurrent_program_id IN (SELECT concurrent_program_id
                                                 FROM fnd_concurrent_programs
			                        WHERE concurrent_program_name='XX_INV_RMSITEM_PURGE_CHILD'
                        		          AND enabled_flag='Y')
                 AND argument_text LIKE 'LC%'
                 AND phase_code IN ('P','R');

              IF ln_run_count=0 THEN
                 EXIT;
              ELSE
                 DBMS_LOCK.SLEEP(gn_sleep);
              END IF;
 
            END LOOP;


             SELECT COUNT(1)
               INTO ln_current_count
               FROM DUAL
              WHERE EXISTS ( SELECT 'x'
                              FROM XX_INV_ITEM_PURGE_INT 
                             WHERE process_flag = 1
                               AND master_item_flag='Y'
			       AND load_batch_id IS NULL
                               AND check_flag='N'
                           );

             p_process:='MC';

          END IF;

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Process :'||p_process);  


       ELSIF p_mode='D' THEN

         SELECT COUNT(1)
           INTO ln_current_count
           FROM DUAL
          WHERE EXISTS ( SELECT 'x'
                           FROM XX_INV_ITEM_PURGE_INT 
                          WHERE process_flag = 4
                            AND master_item_flag='N'
                            AND check_flag='Y'
                            AND delete_flag='P'
			    AND load_batch_id IS NULL
                       );

         p_process:='LD';

         IF ln_current_count=0 THEN

            LOOP   
              SELECT COUNT(1)
                INTO ln_run_count
                FROM fnd_concurrent_requests
               WHERE concurrent_program_id IN (SELECT concurrent_program_id
                                                 FROM fnd_concurrent_programs
			                        WHERE concurrent_program_name='XX_INV_RMSITEM_PURGE_CHILD'
                        		          AND enabled_flag='Y')
                 AND argument_text LIKE 'LD%'
                 AND phase_code IN ('P','R');

              IF ln_run_count=0 THEN
                 EXIT;
              ELSE
                 DBMS_LOCK.SLEEP(gn_sleep);
              END IF;
 
            END LOOP;

            SELECT COUNT(1)
              INTO ln_current_count
              FROM DUAL
             WHERE EXISTS ( SELECT 'x'
                              FROM XX_INV_ITEM_PURGE_INT 
                             WHERE process_flag = 4
                               AND master_item_flag='Y'
                               AND check_flag='Y'
                               AND delete_flag='P'
			       AND load_batch_id IS NULL
                          );
       
            p_process:='MD';

         END IF;  --      IF ln_current_count=0 THEN

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Process :' ||p_process);  

       END IF; --       IF p_mode='V' THEN

       IF ln_current_count=0 THEN
          EXIT;
       ELSE

          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling bat_child');  

          bat_child( x_errbuf    => x_errbuf
                    ,x_retcode   => x_retcode
                    ,p_process   => p_process
                   );
       END IF;

     END LOOP;
  
     LOOP   
      SELECT COUNT(1)
        INTO ln_run_count
        FROM fnd_concurrent_requests
       WHERE concurrent_program_id IN (SELECT concurrent_program_id
                           FROM fnd_concurrent_programs
                      WHERE concurrent_program_name='XX_INV_RMSITEM_PURGE_CHILD'
                        AND enabled_flag='Y')
         AND phase_code IN ('P','R');

      IF ln_run_count=0 THEN
         EXIT;
      ELSE
         DBMS_LOCK.SLEEP(gn_sleep);
      END IF;
     END LOOP;
 

     IF p_process='MC' THEN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Updating error messages for Validation');  

        FOR cur IN C2 LOOP

          lc_error_message:=NULL;

          FOR c IN C3(cur.segment1) LOOP

              lc_error_message:=lc_error_message||','||c.error_message;
    
          END LOOP;


          IF lc_error_message IS NOT NULL THEN

              ln_error_len:=length(lc_error_message);

              IF (ln_error_len+cur.error_length)>3999 THEN
 
                 lc_error_message:=substr(lc_error_message,1,(3999-cur.error_length));

              END IF;

              UPDATE xx_inv_item_purge_int
                 SET error_message= error_message||','||lc_error_message
                                   ,check_flag='F'
                                   ,error_flag='Y'
		   	           ,loc_process_Flag=6
               WHERE segment1=cur.segment1
		 AND extract_flag='V';

          END IF; --          IF lc_error_message IS NOT NULL THEN

          UPDATE xx_inv_item_purge_int
             SET process_flag=4
	   WHERE segment1=cur.segment1
	     AND error_Flag='N'; --rowid=cur.drowid;

          UPDATE xx_inv_item_purge_int
             SET process_flag=7
	   WHERE segment1=cur.segment1
	     AND error_Flag='Y'; --rowid=cur.drowid;

        END LOOP;   --        FOR cur IN C2 LOOP
        COMMIT;    

     END IF;  --IF p_process='MC' THEN


     IF p_process='MD' THEN

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Updating error messages for Deletion');  

        FOR cur IN C5 LOOP

          lc_error_message:=NULL;

          FOR c IN C6(cur.segment1) LOOP

              lc_error_message:=lc_error_message||','||c.error_message;
    
          END LOOP;


          IF lc_error_message IS NOT NULL THEN

              ln_error_len:=length(lc_error_message);

              IF (ln_error_len+cur.error_length)>3999 THEN
 
                 lc_error_message:=substr(lc_error_message,1,(3999-cur.error_length));

              END IF;

              UPDATE xx_inv_item_purge_int
                 SET error_message= error_message||','||lc_error_message
                                   ,delete_flag='F'
                                   ,error_flag='Y'
               WHERE segment1=cur.segment1;

          END IF; --          IF lc_error_message IS NOT NULL THEN

        END LOOP;   --        FOR cur IN C2 LOOP
        COMMIT;    
 
     END IF;  --     IF p_process='MD'

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Calling update_rms');  

     update_rms(p_mode);

  END IF;  --  IF ln_mst_run<=1 THEN

EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf  := 'Unexpected error in master_main procedure - '||SQLERRM;
END master_main;


PROCEDURE CHECK_ITEM_LOC(
                     x_errbuf             OUT NOCOPY VARCHAR2
                        ,x_retcode            OUT NOCOPY VARCHAR2
            ,p_batch_id          IN  NUMBER
                        )
IS
ln_cnt                  PLS_INTEGER;
ln_locations_processed            PLS_INTEGER;
ln_locations_failed               PLS_INTEGER;
ln_location_total        PLS_INTEGER;
j                  NUMBER:=0;
v_request_id                NUMBER;
v_wait                 BOOLEAN;
v_req_phase             VARCHAR2(100);
v_req_status             VARCHAR2(100);
v_dev_phase             VARCHAR2(100); 
v_dev_status             VARCHAR2(100);
v_req_message             VARCHAR2(1000);
EX_DEL_GRP_SETUP             EXCEPTION;
EX_DEL_GRP_ENT              EXCEPTION;

CURSOR C1 IS
SELECT delete_entity_sequence_id,
       del_grp_id
  FROM xx_inv_item_purge_int
 WHERE load_batch_id=p_batch_id
   AND error_flag='Y'
   AND delete_entity_sequence_id IS NOT NULL;

CURSOR c_master_org
IS
SELECT MP.organization_id
  FROM mtl_parameters MP
 WHERE MP.organization_id=MP.master_organization_id
   AND ROWNUM=1;

CURSOR c_del_errors IS
SELECT  d.message_text,
     a.delete_entity_sequence_id
     ,a.inventory_item_id
     ,a.organization_id
     ,e.rowid drowid
     ,e.segment1
     ,e.loc
  FROM  fnd_new_messages d
       ,bom_delete_sql_statements c
       ,bom_delete_errors  b
       ,bom_delete_entities a
       ,xx_inv_item_purge_int e
 WHERE a.delete_group_sequence_id=e.del_grp_id
   AND a.delete_status_type=3
   AND a.delete_entity_sequence_id=e.delete_entity_sequence_id
   AND b.delete_entity_sequence_id=a.delete_entity_sequence_id
   AND c.sql_statement_name=b.sql_statement_name
   AND d.message_name=c.message_name
   AND e.inventory_item_id=a.inventory_item_id
   AND e.organization_id=a.organization_id
   AND e.load_batch_id=p_batch_id
   AND d.message_text not like 'Item still exists in child organizations%';


CURSOR c_delseq(p_delgrp_id NUMBER) IS
SELECT   a.rowid drowid
    ,b.delete_group_sequence_id
    ,b.delete_entity_sequence_id
  FROM  bom_delete_entities b,
    xx_inv_item_purge_int a
 WHERE  a.load_batch_id=p_batch_id
   AND  b.delete_group_sequence_id=p_delgrp_id
   AND  b.inventory_item_id=a.inventory_item_id
   AND  b.organization_id=a.organization_id;

BEGIN



  OPEN c_master_org;
  FETCH c_master_org INTO gn_master_org_id;
  CLOSE c_master_org;

  BEGIN
    INSERT 
      INTO bom_delete_groups 
    (DELETE_GROUP_SEQUENCE_ID, 
     DELETE_GROUP_NAME, 
     DESCRIPTION, 
     ORGANIZATION_ID, 
     DELETE_TYPE, 
     ACTION_TYPE, 
     ENGINEERING_FLAG, 
     LAST_UPDATE_DATE, 
     LAST_UPDATED_BY, 
     CREATION_DATE, 
     CREATED_BY) 
    VALUES
    (BOM_DELETE_GROUPS_S.NEXTVAL, 
     TO_CHAR(p_batch_id), 
     'RMSITEM Delete group for '||TO_CHAR(p_batch_id),
     gn_master_org_id, -- Master Organization Id
     1,     --1 stands for Item 
     1, --1 stands for CHECK, 2 stands for DELETE
     1, --1 stands for Production Item, 2 stands for Engineering Item
     sysdate, 
    -1, -- This has to be updated to the current Login iD value 
    sysdate, 
    -1 -- This has to be updated to the current Login iD value 
    ); 
  EXCEPTION
    WHEN others THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while set up bom_delete_group for Validation : '||sqlerrm);
      RAISE EX_DEL_GRP_SETUP;
  END;

  BEGIN
    SELECT delete_group_sequence_id
      INTO gn_del_grp_id
      FROM bom_delete_groups
     WHERE organization_id=gn_master_org_id
       AND delete_group_name=TO_CHAR(p_batch_id);
  EXCEPTION
    WHEN others THEN
      x_errbuf :='Delete group is not defined '||SQLERRM;
        x_retcode:=2;
  END;

  BEGIN
    INSERT 
    INTO bom_delete_entities
          (   delete_entity_sequence_id
         ,delete_group_sequence_id
         ,delete_entity_type
         ,delete_status_type
         ,inventory_item_id
         ,organization_id
         ,item_description
         ,item_concat_segments
         ,prior_process_Flag
         ,prior_commit_flag
         ,last_update_date
         ,last_updated_by
         ,creation_date
         ,created_by
         ,last_update_login)
    SELECT  BOM_DELETE_ENTITIES_S.NEXTVAL
         ,gn_del_grp_id
         ,1            -- delete_entity_type (item)
         ,1            -- delete_status_type (Pending)
         ,m.inventory_item_id
         ,m.organization_id
         ,m.description
         ,m.segment1    
         ,2        -- prior_process_flag  (No)
         ,1        -- prior_commit_flag   (Yes)
         ,G_DATE
         ,G_USER_ID
         ,G_DATE
         ,G_USER_ID
         ,G_USER_ID
    FROM  mtl_system_items_b m
        , xx_inv_item_purge_int xil 
     WHERE xil.load_batch_id=p_batch_id
       AND m.inventory_item_id=xil.inventory_item_id
       AND m.organization_id=xil.organization_id;
  EXCEPTION
    WHEN others THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting bom_delete_entities for Validation : '||sqlerrm);
      RAISE EX_DEL_GRP_ENT;
  END;
  COMMIT;

  FOR cur IN c_delseq(gn_del_grp_id) LOOP

      UPDATE xx_inv_item_purge_int
     SET del_grp_id=gn_del_grp_id,
         delete_entity_sequence_id=cur.delete_entity_sequence_id
       WHERE rowid=cur.drowid;

  END LOOP;
  COMMIT;
  
  SELECT COUNT(1)
    INTO ln_cnt
    FROM bom_delete_entities
   WHERE delete_group_sequence_id=gn_del_grp_id;

  IF ln_cnt>0 THEN

     v_request_id := FND_REQUEST.submit_request(  application => 'BOM'
                                        ,program     => 'BMCDEL'
                                      ,sub_request =>  FALSE
                                                  ,argument1   =>  TO_CHAR(gn_del_grp_id)
                                                  ,argument2   =>  '1'
                                                  ,argument3   =>  '1'
                                                 );
    IF v_request_id = 0 THEN
       x_errbuf  := 'Unable to submit Delete Item information in Check Mode';
       x_retcode :=2;
    ELSE
       COMMIT;

       IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_req_phase,
			v_req_status,v_dev_phase,v_dev_status,v_req_message))  THEN
          IF v_dev_phase = 'COMPLETE' THEN
             fnd_file.put_line(fnd_file.LOG, 'Request completed normal');
	  END IF;
       END IF;

    END IF;
  END IF;

  UPDATE xx_inv_item_purge_int
     SET check_flag='Y',
     loc_process_flag=4
   WHERE load_batch_id=p_batch_id;
  COMMIT;

  FOR cur IN c_del_errors LOOP
    UPDATE xx_inv_item_purge_int 
       SET error_message=','||cur.message_text
          ,error_flag='Y'
          ,check_flag='F'
          ,loc_process_flag=3
     WHERE rowid=cur.drowid;
  END LOOP;
  COMMIT;

  FOR cur IN C1 LOOP
    DELETE
      FROM bom_delete_entities
     WHERE delete_group_sequence_id=cur.del_grp_id
       AND delete_entity_sequence_id=cur.delete_entity_sequence_id;
  END LOOP;
  COMMIT;

  UPDATE xx_inv_item_purge_int
     SET error_message=null,error_flag='N',loc_process_Flag=4
   WHERE load_batch_id=p_batch_id
     AND error_message like '%Item still exists in child organizations%';
 COMMIT;

EXCEPTION
  WHEN EX_DEL_GRP_SETUP THEN
      ROLLBACK;
      x_errbuf :='Error in setting up delete group'||SQLERRM;
      x_retcode:=2;
  WHEN EX_DEL_GRP_ENT THEN
      ROLLBACK;
      x_errbuf :='Error in inserting bom_delete_entities'||SQLERRM;
      x_retcode:=2;
  WHEN others THEN
    x_errbuf  :='Error in end of When others '||SQLERRM;
    x_retcode :=2;    
END CHECK_ITEM_LOC;
-- +======================================================================+
-- | Name        :  bat_child                                             |
-- | Description :  This procedure is invoked from the submit_sub_requests|
-- |                procedure. This would submit child requests based     |
-- |                on batch_size.                                        |
-- |                                                                      |
-- |                                                                      |
-- | Parameters  :  p_request_id, p_master                                |
-- |                                                                      |
-- | Returns     :  x_errbuf                                              |
-- |                x_retcode                                             |
-- +======================================================================+
PROCEDURE child_main(
                       x_errbuf             OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
              ,p_process        IN  VARCHAR2
                      ,p_batch_id           IN  NUMBER
                    )
IS
---------------------------
--Declaring local variables
---------------------------
lx_errbuf                   VARCHAR2(5000);
lx_retcode                  VARCHAR2(20);
BEGIN

    BEGIN

        display_out('*Batch_id* '||p_batch_id);

    IF p_process IN ('LC','MC') THEN

           check_item_loc(lx_errbuf,lx_retcode,p_batch_id);
  
           x_errbuf:=lx_errbuf;
           x_retcode:=lx_retcode;
        

    ELSIF p_process IN ('LD','MD') THEN

       purge_item(lx_errbuf,lx_retcode,p_process,p_batch_id);

       x_errbuf:=lx_errbuf;
       x_retcode:=lx_retcode;

    END IF;
        COMMIT;

    EXCEPTION
    WHEN OTHERS THEN
        x_retcode := lx_retcode;
        CASE WHEN x_errbuf IS NULL
             THEN x_errbuf  := gc_sqlerrm;
             ELSE x_errbuf  := x_errbuf||'/'||gc_sqlerrm;
        END CASE;
        x_retcode := 2;
    END;
EXCEPTION
  WHEN OTHERS THEN
    x_errbuf  := 'Unexpected error in child_main - '||SQLERRM;
    x_retcode := 2;
END child_main;
END XX_INV_RMSITEM_PURGE_PKG; 
/
