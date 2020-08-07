create or replace 
PACKAGE BODY XX_INV_ITEM_INTF_PKG
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  XX_INV_ITEM_INTF_PKG.pkb                                            |
-- | Description :  INV Item Interface Package Body                                     |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===================================        |
-- |1.0       10-Jun-2008 Paddy Sanjeevi	   Initital Version                     |
-- |1.1       26-Sep-2008 Paddy Sanjeevi     Modified to take care of duplicates        |
-- |1.2       26-Sep-2008 Paddy Sanjeevi     Modified to check the existence of item/loc|
-- |1.3       13-Nov-2008 Paddy Sanjeevi     Modified to resubmit the error records     |
-- |1.4       10-Mar-2009 Paddy Sanjeevi     Modified to delete error records in interface table |
-- |1.5       20-Jul-2009 Paddy Sanjeevi     Modified to performance improvement (Defect 534 |
-- |1.6       23-Apr-2010 Paddy Sanjeevi     Added od_srvc_type_cd to item master       |
-- |1.7       27-Jan-2014 Paddy Sanjeevi     R12 Index Sync            			|
-- |1.8       09-Apr-2015 Sai Kiran          Repalced the Control_id variable datatype with Number(defect#34053)|
-- |1.9       19-Oct-2015 Madhu Bolli        Remove schema for 12.2 retrofit    |
-- |1.10	  27-Dec-2018 Shalu George       Commented lines 205 to 414 for Lift and Shift(JIRA NAIT-60664)|
-- +====================================================================================+
AS
----------------------------
--Declaring Global Constants
----------------------------
G_TRANSACTION_TYPE          CONSTANT mtl_system_items_interface.transaction_type%TYPE      :=  'CREATE';
G_UTRANSACTION_TYPE         CONSTANT mtl_system_items_interface.transaction_type%TYPE      :=  'UPDATE';
G_PROCESS_FLAG              CONSTANT mtl_system_items_interface.process_flag%TYPE          :=   1;
G_USER_ID                   CONSTANT mtl_system_items_interface.created_by%TYPE            :=   FND_GLOBAL.user_id;
G_DATE                      CONSTANT mtl_system_items_interface.last_update_date%TYPE      :=   SYSDATE;
G_MER_TEMPLATE              CONSTANT mtl_item_templates.template_name%TYPE                 :=  'OD Merchandising Item';
G_DS_TEMPLATE               CONSTANT mtl_item_templates.template_name%TYPE                 :=  'OD Drop Ship Item';
G_INV_STRUCTURE_CODE        CONSTANT fnd_id_flex_structures_vl.id_flex_structure_code%TYPE :=  'ITEM_CATEGORIES';
G_ODPB_STRUCTURE_CODE       CONSTANT fnd_id_flex_structures_vl.id_flex_structure_code%TYPE :=  'OD_ITM_BRAND_CATEGORY';
G_PO_STRUCTURE_CODE         CONSTANT fnd_id_flex_structures_vl.id_flex_structure_code%TYPE :=  'PO_ITEM_CATEGORY';
G_ATP_STRUCTURE_CODE        CONSTANT fnd_id_flex_structures_vl.id_flex_structure_code%TYPE :=  'OD_ATP_PLANNING_CATEGORY';
G_ID_FLEX_CODE              CONSTANT fnd_id_flex_structures_vl.id_flex_code%TYPE           :=  'MCAT';
G_APPLICATION_ID            CONSTANT fnd_id_flex_structures_vl.application_id%TYPE         :=   401;
G_INV_CATEGORY_SET          CONSTANT mtl_category_sets.category_set_name%TYPE              :=  'Inventory';
G_ODPB_CATEGORY_SET         CONSTANT mtl_category_sets.category_set_name%TYPE              :='Office Depot Private Brand';
G_PO_CATEGORY_SET           CONSTANT mtl_category_sets.category_set_name%TYPE              :=  'PO CATEGORY';
G_ATP_CATEGORY_SET          CONSTANT mtl_category_sets.category_set_name%TYPE              :=  'ATP_CATEGORY';
G_PACKAGE_NAME              CONSTANT VARCHAR2(30)                                          :=  'XX_INV_ITEM_INTF_PKG';
G_APPLICATION               CONSTANT VARCHAR2(10)                                          :=  'INV';
G_CHILD_PROGRAM             CONSTANT VARCHAR2(50)                                          :='XX_INV_ITEM_INTF_CHILD';
G_LIMIT_SIZE                CONSTANT PLS_INTEGER                                           :=   10000;

----------------------------
--Declaring Global Variables
----------------------------

gc_master_setup_status      VARCHAR2(1);
gc_valorg_setup_status      VARCHAR2(1);
gn_val_org_count            NUMBER := NULL;
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
ln_master_org		    PLS_INTEGER := 0;
gn_prog_id			    PLS_INTEGER;
gn_threads			    PLS_INTEGER ;
gn_mbatch_size              PLS_INTEGER ;
---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------
TYPE val_org_tbl_type IS TABLE OF hr_organization_units.organization_id%TYPE INDEX BY BINARY_INTEGER;
gt_val_orgs  val_org_tbl_type;

TYPE req_id_tbl_type IS TABLE OF fnd_concurrent_requests.request_id%TYPE INDEX BY BINARY_INTEGER;
gt_req_id req_id_tbl_type;


-- +====================================================================================+
-- | Name        :  Sync_Index                                                          |
-- | Description :  This procedure is to sync index                                     |
-- |                                                                                    |
-- | Parameters  :                                                                      |
-- +====================================================================================+
PROCEDURE sync_index ( x_errbuf             OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                     )
IS

lc_message varchar2(2000);

BEGIN

  INV_ITEM_PVT.SYNC_IM_INDEX;

EXCEPTION
  WHEN others THEN
    lc_message:=SUBSTR(sqlerrm,1,1000);
    x_errbuf:=2;
END sync_index;

-- +====================================================================================+
-- | Name        :  RMS_EBS_EXTRACT                                                     |
-- | Description :  This procedure is invoked from ESP to extract records from RMS      |
-- |                                                                                    |
-- | Parameters  :                                                                      |
-- +====================================================================================+
PROCEDURE RMS_EBS_EXTRACT(
  	                    x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
                         )
IS

--Changed the datatype from PLS_INTEGER to Number as part of defect#34053
--CH ID#34053 Start
--v_mstctl_id		PLS_INTEGER;
--v_locctl_id	  PLS_INTEGER;
v_mstctl_id		NUMBER;  
v_locctl_id	  NUMBER; 
--CH ID#34053 End
i 			NUMBER:=0;
j			NUMBER:=0;
v_cnt			NUMBER:=0;
v_uom_code		VARCHAR2(3);

CURSOR c_master_org
IS
SELECT MP.organization_id
FROM   mtl_parameters MP
WHERE  MP.organization_id=MP.master_organization_id
AND    ROWNUM=1;

CURSOR C1(p_action VARCHAR2) IS
SELECT item
	,loc
	,rowid drowid
  FROM xx_inv_item_loc_int
 WHERE process_Flag=-1
   AND action_type=p_action
   AND inventory_item_id=-1;

CURSOR C2(p_action VARCHAR2) IS
SELECT item
	,rowid drowid
  FROM xx_inv_item_master_int
 WHERE process_Flag=-1
   AND action_type=p_action
   AND inventory_item_id=-1;


CURSOR c_master_set(p_action VARCHAR2) IS
SELECT DISTINCT item
  FROM xx_inv_item_master_int
 WHERE process_flag=-1
   AND action_type=p_action
   AND inventory_item_id=-1;


CURSOR c_master_setd(p_item VARCHAR2,p_action VARCHAR2) IS
SELECT  item
	 ,rms_timestamp
	 ,rowid drowid
  FROM xx_inv_item_master_int
 WHERE item=p_item
   AND action_type=p_action
   AND process_flag+0=-1
   AND inventory_item_id=-1
 ORDER BY rms_timestamp DESC;

CURSOR c_loc_set(p_action VARCHAR2) IS
SELECT DISTINCT item,loc
  FROM xx_inv_item_loc_int
 WHERE process_flag=-1
   AND action_type=p_action
   AND inventory_item_id=-1;


CURSOR c_loc_setd(p_item VARCHAR2,p_loc NUMBER, p_action VARCHAR2) IS
SELECT  item
	 ,loc
	 ,rms_timestamp
	 ,rowid drowid
  FROM xx_inv_item_loc_int
 WHERE item=p_item
   AND loc=p_loc
   AND action_type=p_action
   AND process_flag+0=-1
   AND inventory_item_id=-1
 ORDER BY rms_timestamp DESC;

BEGIN
/*  SELECT MAX(control_id)
    INTO v_mstctl_id
    FROM xx_inv_ebs_control
   WHERE process_name='ITEM_MASTER';

  SELECT MAX(control_id)
    INTO v_locctl_id
    FROM xx_inv_ebs_control
   WHERE process_name='ITEM_LOC';

  BEGIN
    INSERT
	INTO XX_INV_ITEM_MASTER_INT
	( 	 ITEM
		,CLASS
		,DEPT
		,HANDLING_SENSITIVITY
		,ITEM_DESC
		,ITEM_NUMBER_TYPE
		,ORDER_AS_TYPE
		,ORDERABLE_IND
		,PACK_IND
		,PACK_TYPE
		,PACKAGE_SIZE
		,PACKAGE_UOM
		,SELLABLE_IND
		,SHIP_ALONE_IND
		,SHORT_DESC
		,SIMPLE_PACK_IND
		,STATUS
		,STORE_ORD_MULT
		,SUBCLASS
		,OD_ASSORTMENT_CD
		,OD_CALL_FOR_PRICE_CD
		,OD_COST_UP_FLG
		,OD_GIFT_CERTIF_FLG
		,OD_GSA_FLG
		,OD_IMPRINTED_ITEM_FLG
		,OD_LIST_OFF_FLG
		,OD_META_CD
		,OD_OFF_CAT_FLG
		,OD_OVRSIZE_DELVRY_FLG
		,OD_PRIVATE_BRAND_FLG
		,OD_PRIVATE_BRAND_LABEL
		,OD_PROD_PROTECT_CD
		,OD_READY_TO_ASSEMBLE_FLG
		,OD_RECYCLE_FLG
		,OD_RETAIL_PRICING_FLG
		,OD_SKU_TYPE_CD
		,OD_TAX_CATEGORY
		,MASTER_ITEM
		,SUBSELL_MASTER_QTY
		,CONTROL_ID
		,ACTION_TYPE
		,RMS_PROCESS_ID
		,RMS_TIMESTAMP
		,PROCESS_FLAG
		,CREATION_DATE
		,CREATED_BY
		,LAST_UPDATE_DATE
		,LAST_UPDATED_BY
		,inventory_item_id
		,od_srvc_type_cd
	)
    SELECT 	 ITEM
		,CLASS
		,DEPT
		,HANDLING_SENSITIVITY
		,ITEM_DESC
		,ITEM_NUMBER_TYPE
		,ORDER_AS_TYPE
		,ORDERABLE_IND
		,PACK_IND
		,PACK_TYPE
		,PACKAGE_SIZE
		,PACKAGE_UOM
		,SELLABLE_IND
		,SHIP_ALONE_IND
		,SHORT_DESC
		,SIMPLE_PACK_IND
		,STATUS
		,STORE_ORD_MULT
		,SUBCLASS
		,OD_ASSORTMENT_CD
		,OD_CALL_FOR_PRICE_CD
		,OD_COST_UP_FLG
		,OD_GIFT_CERTIF_FLG
		,OD_GSA_FLG
		,OD_IMPRINTED_ITEM_FLG
		,OD_LIST_OFF_FLG
		,OD_META_CD
		,OD_OFF_CAT_FLG
		,OD_OVRSIZE_DELVRY_FLG
		,OD_PRIVATE_BRAND_FLG
		,OD_PRIVATE_BRAND_LABEL
		,OD_PROD_PROTECT_CD
		,OD_READY_TO_ASSEMBLE_FLG
		,OD_RECYCLE_FLG
		,OD_RETAIL_PRICING_FLG
		,OD_SKU_TYPE_CD
		,OD_TAX_CATEGORY
		,MASTER_ITEM
		,SUBSELL_MASTER_QTY
		,CONTROL_ID
		,ACTION_CODE
		,PROCESS_ID
		,CREATE_TIMESTAMP
		,-1
		,SYSDATE
		,fnd_global.user_id
		,SYSDATE
		,fnd_global.user_id
		,-1
		,od_srvc_type_cd
	FROM  OD_EBS_INT_ITEM_MASTER
     WHERE control_id>NVL(v_mstctl_id,0);

  COMMIT;

  SELECT MAX(control_id)
    INTO v_mstctl_id
    FROM xx_inv_item_master_int;

  UPDATE xx_inv_ebs_control
     SET control_id=NVL(v_mstctl_id,0)
   WHERE process_name='ITEM_MASTER';

  EXCEPTION
    WHEN others THEN
  	x_errbuf   :=SQLERRM;
      x_retcode  :=-1;
  END;

  COMMIT;

  BEGIN
    INSERT
	INTO XX_INV_ITEM_LOC_INT
	(	 CONTROL_ID
		,PROCESS_FLAG
		,ACTION_TYPE
		,RMS_PROCESS_ID
		,RMS_TIMESTAMP
		,ITEM
		,LOC
		,LOCAL_ITEM_DESC
		,LOCAL_SHORT_DESC
		,PRIMARY_SUPP
		,STATUS
		,OD_ABC_CLASS
		,OD_CHANNEL_BLOCK
		,OD_DIST_TARGET
		,OD_EBW_QTY
		,OD_INFINITE_QTY_CD
		,OD_LOCK_UP_ITEM_FLG
		,OD_PROPRIETARY_TYPE_CD
		,OD_REPLEN_SUB_TYPE_CD
		,OD_REPLEN_TYPE_CD
		,OD_WHSE_ITEM_CD
		,CREATION_DATE
		,CREATED_BY
		,LAST_UPDATE_DATE
		,LAST_UPDATED_BY
		,inventory_item_id
	)
    SELECT   CONTROL_ID
		,-1
		,ACTION_CODE
		,PROCESS_ID
		,CREATE_TIMESTAMP
		,ITEM
		,LOC
		,LOCAL_ITEM_DESC
		,LOCAL_SHORT_DESC
		,PRIMARY_SUPP
		,STATUS
		,OD_ABC_CLASS
		,OD_CHANNEL_BLOCK
		,OD_DIST_TARGET
		,OD_EBW_QTY
		,OD_INFINITE_QTY_CD
		,OD_LOCK_UP_ITEM_FLG
		,OD_PROPRIETARY_TYPE_CD
		,OD_REPLEN_SUB_TYPE_CD
		,OD_REPLEN_TYPE_CD
		,OD_WHSE_ITEM_CD
		,SYSDATE
		,fnd_global.user_id
		,SYSDATE
		,fnd_global.user_id
		,-1
	FROM  OD_EBS_INT_ITEM_LOC
     WHERE control_id>NVL(v_locctl_id,0);

    COMMIT;

    SELECT MAX(control_id)
      INTO v_locctl_id
      FROM xx_inv_item_loc_int;


    UPDATE xx_inv_ebs_control
       SET control_id=NVL(v_locctl_id,0)
     WHERE process_name='ITEM_LOC';
  EXCEPTION
    WHEN others THEN
  	x_errbuf   :=SQLERRM;
      x_retcode  :=-1;
  END;
*/
  -- To set the item records to success for duplicate 'A'
  j:=0;
  FOR cur IN c_master_set('A') LOOP
    i:=0;
    j:=j+1;
    IF j>5000 THEN
	 COMMIT;
       j:=0;
    END IF;
    FOR c IN c_master_setd(cur.item,'A') LOOP
      i:=i+1;
      IF i>1 THEN
	   UPDATE xx_inv_item_master_int
	      SET process_flag=7
		   ,item_process_flag=7
		   ,load_batch_id=-999
	    WHERE rowid=c.drowid;
	END IF;
    END LOOP;
  END LOOP;
  COMMIT;

  OPEN c_master_org;
  FETCH c_master_org INTO gn_master_org_id;
  CLOSE c_master_org;

  -- To set the item record action_type='C' if already exists in EBS for action_type='A'

  i:=0;

  FOR cur IN C2('A') LOOP
    i:=i+1;
    IF i>5000 THEN
	 COMMIT;
    END IF;
    BEGIN
      SELECT primary_uom_code
        INTO v_uom_code
        FROM mtl_system_items_b
   	 WHERE organization_id=gn_master_org_id
	   AND segment1=cur.item;
      IF v_uom_code IS NOT NULL THEN
	   UPDATE xx_inv_item_master_int
	      SET action_type='C',source_system_code=v_uom_code
	    WHERE rowid=cur.drowid;
      END IF;
    EXCEPTION
	WHEN others THEN
	   UPDATE xx_inv_item_master_int
	      SET process_flag=1
	    WHERE rowid=cur.drowid;
    END;
  END LOOP;
  COMMIT;

  -- To set the item records to success for duplicate 'C'
  j:=0;
  FOR cur IN c_master_set('C') LOOP
    i:=0;
    j:=j+1;
    IF j>5000 THEN
	 COMMIT;
       j:=0;
    END IF;
    FOR c IN c_master_setd(cur.item,'C') LOOP
      i:=i+1;
      IF i>1 THEN
	   UPDATE xx_inv_item_master_int
	      SET process_flag=7
		   ,item_process_flag=7
		   ,load_batch_id=-999
	    WHERE rowid=c.drowid;
	END IF;
    END LOOP;
  END LOOP;
  COMMIT;

  -- To set the primary_uom_code for item changed records

  i:=0;
  FOR cur IN C2('C') LOOP
    i:=i+1;
    IF i>5000 THEN
	 COMMIT;
    END IF;
    BEGIN
      SELECT primary_uom_code
        INTO v_uom_code
        FROM mtl_system_items_b
   	 WHERE organization_id=gn_master_org_id
	   AND segment1=cur.item;
      IF v_uom_code IS NOT NULL THEN
	   UPDATE xx_inv_item_master_int
	      SET process_Flag=1,source_system_code=v_uom_code
	    WHERE rowid=cur.drowid;
      END IF;
    EXCEPTION
	WHEN others THEN
	  NULL;
    END;
  END LOOP;
  COMMIT;

  -- To set the item loc records to success for duplicate 'A'

  j:=0;
  FOR cur IN c_loc_set('A') LOOP
    i:=0;
    j:=j+1;
    IF j>5000 THEN
	 COMMIT;
       j:=0;
    END IF;
    FOR c IN c_loc_setd(cur.item,cur.loc,'A') LOOP
      i:=i+1;
      IF i>1 THEN
	   UPDATE xx_inv_item_loc_int
	      SET process_flag=7
		   ,location_process_flag=7
		   ,load_batch_id=-999
	    WHERE rowid=c.drowid;
	END IF;
    END LOOP;
  END LOOP;
  COMMIT;

  -- To set the item loc records action_type='C' if already exists in EBS

  i:=0;
  FOR cur IN C1('A') LOOP
    i:=i+1;
    IF i>5000 THEN
	 COMMIT;
    END IF;
    BEGIN
   	SELECT primary_uom_code
        INTO v_uom_code
        FROM mtl_system_items_b b
		,hr_all_organization_units c
  	 WHERE c.attribute1=TO_CHAR(cur.loc)
	   AND b.organization_id=c.organization_id
	   AND b.segment1=cur.item;
      IF v_uom_code IS NOT NULL THEN
 	   UPDATE xx_inv_item_loc_int
	       SET action_type='C',source_system_code=v_uom_code
	      WHERE rowid=cur.drowid;
      END IF;
    EXCEPTION
	WHEN others THEN
	  UPDATE xx_inv_item_loc_int
	     SET process_flag=1
	   WHERE rowid=cur.drowid
	     AND EXISTS (SELECT 'x'
				 FROM mtl_system_items_b
		            WHERE organization_id=441
				  AND segment1=cur.item);
    END;
  END LOOP;
  COMMIT;

  -- To set the item loc records to success for duplicate 'C'

  j:=0;
  FOR cur IN c_loc_set('C') LOOP
    i:=0;
    j:=j+1;
    IF j>5000 THEN
	 COMMIT;
       j:=0;
    END IF;
    FOR c IN c_loc_setd(cur.item,cur.loc,'C') LOOP
      i:=i+1;
      IF i>1 THEN
	   UPDATE xx_inv_item_loc_int
	      SET process_flag=7
		   ,location_process_flag=7
		   ,load_batch_id=-999
	    WHERE rowid=c.drowid;
	END IF;
    END LOOP;
  END LOOP;
  COMMIT;

  i:=0;
  FOR cur IN C1('C') LOOP
    i:=i+1;
    IF i>5000 THEN
	 COMMIT;
    END IF;
    BEGIN
   	SELECT primary_uom_code
        INTO v_uom_code
        FROM mtl_system_items_b b
		,hr_all_organization_units c
  	 WHERE c.attribute1=TO_CHAR(cur.loc)
	   AND b.organization_id=c.organization_id
	   AND b.segment1=cur.item;
     IF v_uom_code IS NOT NULL THEN
 	  UPDATE xx_inv_item_loc_int
	     SET process_Flag=1,source_system_code=v_uom_code
	   WHERE rowid=cur.drowid;
     END IF;
   EXCEPTION
	  WHEN others THEN
	    NULL;
   END;
 END LOOP;
 COMMIT;
 UPDATE xx_inv_item_loc_int
    SET process_flag=1,location_process_Flag=null,inventory_item_id=-1,load_batch_id=null,
	  error_flag=null,error_message=null
  WHERE creation_date>sysdate-1
    AND error_message like '%Master%';
 COMMIT;

END RMS_EBS_EXTRACT;

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

-- +=========================================================================+
-- | Name        :  ITEM_INTF_ERROR_UPD                                      |
-- | Description :  This procedure is called from ESP to invoke error update |
-- |                                                                         |
-- | Parameters  :                                                           |
-- +=========================================================================+

PROCEDURE ITEM_INTF_ERROR_UPD(
					p_process		   IN  VARCHAR2
				     ,p_batch_id		   IN  NUMBER
	  	                 ,x_errbuf             OUT NOCOPY VARCHAR2
      	                 ,x_retcode            OUT NOCOPY VARCHAR2
             	           )
IS

lx_errbuf                   VARCHAR2(5000);
lx_retcode                  VARCHAR2(20);

BEGIN

  IF p_process IN ('MA','MC') THEN

     BEGIN
	 INSERT
	   INTO XX_INV_ERROR_LOG
		 ( control_id
		  ,rms_process_id
		  ,process_name
		  ,key_value_1
		  ,error_message
		  ,process_flag
		  ,created_by
		  ,creation_date
		  ,last_updated_by
		  ,last_update_date)
	 SELECT  XX_INV_ERROR_LOG_S.NEXTVAL
		  ,rms_process_id
		  ,'ITEM_MASTER'
		  ,item
		  ,error_message
		  ,'N'
		  ,FND_GLOBAL.user_id
		  ,SYSDATE
		  ,FND_GLOBAL.user_id
		  ,SYSDATE
	   FROM xx_inv_item_master_int
	  WHERE load_batch_id=p_batch_id
	    AND (   inv_category_process_flag=3
		   OR odpb_category_process_flag =3
		   OR po_category_process_flag =3
		   OR atp_category_process_flag =3
               OR error_flag='Y'
		   );
  	 UPDATE xx_inv_item_master_int
          SET error_flag='P'
	  WHERE load_batch_id=p_batch_id
	    AND (   inv_category_process_flag =3
		   OR odpb_category_process_flag =3
		   OR po_category_process_flag =3
		   OR atp_category_process_flag =3
		   OR error_flag='Y'
		   );
	 COMMIT;
     EXCEPTION
	 WHEN others THEN
	   x_errbuf:='Error in Inserting Master Errors in Error Log, '||SQLERRM;
         x_retcode:=-1;
     END;

     UPDATE xx_inv_item_master_int
        SET process_flag=7
      WHERE load_batch_id=p_batch_id
	  AND process_flag<>7;

  ELSIF p_process IN ('LA','LC') THEN

     BEGIN
	 INSERT
	   INTO XX_INV_ERROR_LOG
		 ( control_id
		  ,rms_process_id
		  ,process_name
		  ,key_value_1
		  ,key_value_2
		  ,error_message
		  ,process_flag
		  ,created_by
		  ,creation_date
		  ,last_updated_by
		  ,last_update_date)
	 SELECT  XX_INV_ERROR_LOG_S.NEXTVAL
		  ,rms_process_id
		  ,'ITEM_LOC'
		  ,item
		  ,loc
		  ,error_message
		  ,'N'
		  ,FND_GLOBAL.user_id
		  ,SYSDATE
		  ,FND_GLOBAL.user_id
		  ,SYSDATE
	   FROM xx_inv_item_loc_int
	  WHERE load_batch_id=p_batch_id
	    AND (location_process_flag=3 or error_flag='Y')
          AND error_message NOT LIKE '%Master%';

  	 UPDATE xx_inv_item_loc_int
          SET error_flag='P'
	  WHERE load_batch_id=p_batch_id
	    AND (location_process_flag=3 or error_flag='Y');
	 COMMIT;
     EXCEPTION
	 WHEN others THEN
	   x_errbuf:='Error in Inserting Location Errors in Error Log, '||SQLERRM;
         x_retcode:=-1;
     END;
     UPDATE xx_inv_item_loc_int
        SET process_flag=7
      WHERE load_batch_id=p_batch_id
	  AND process_flag<>7;
  END IF;

  DELETE
    FROM mtl_item_revisions_interface
   WHERE set_process_id=p_batch_id;
  COMMIT;

  DELETE
    FROM mtl_item_categories_interface
   WHERE set_process_id=p_batch_id;
  COMMIT;

  DELETE
    FROM mtl_interface_errors
   WHERE transaction_id IN ( SELECT transaction_id
			       FROM mtl_system_items_interface
			      WHERE set_process_id=p_batch_id);
   COMMIT;

  DELETE
    FROM mtl_system_items_interface
   WHERE set_process_id=p_batch_id;
  COMMIT;
END;

-- +==========================================================================+
-- | Name        :  RMS_EBS_INTF                                              |
-- | Description :  This procedure is called from ESP to invoke item interface|
-- |                                                                          |
-- | Parameters  :                                                            |
-- +==========================================================================+

PROCEDURE RMS_EBS_INTF(
  	                  x_errbuf             OUT NOCOPY VARCHAR2
                       ,x_retcode            OUT NOCOPY VARCHAR2
                      )
IS

ln_request_id  	FND_CONCURRENT_REQUESTS.request_id%TYPE;
ln_prog_id	   	FND_CONCURRENT_PROGRAMS.concurrent_program_id%TYPE;
ln_prog_run     	PLS_INTEGER:=0;
ln_mst_cnt		PLS_INTEGER:=0;
ln_loc_cnt		PLS_INTEGER:=0;

BEGIN
  BEGIN
    SELECT concurrent_program_id
      INTO ln_prog_id
      FROM fnd_concurrent_programs
     WHERE concurrent_program_name='XX_INV_ITEM_INTF_CHILD'
       AND application_id=401
       AND enabled_flag='Y';
  EXCEPTION
    WHEN others THEN
      ln_prog_id:=NULL;
      x_retcode:=-1;
      x_errbuf :='OD INV RMS EBS Item Interface Concurrent Program does not exists';
  END;

  SELECT COUNT(1)
    INTO ln_prog_run
    FROM fnd_concurrent_requests
   WHERE concurrent_program_id=ln_prog_id
     AND program_application_id=401
     AND phase_code='R';


  SELECT COUNT(1)
    INTO ln_mst_cnt
    FROM XX_INV_ITEM_MASTER_INT
   WHERE process_flag=1
     AND load_batch_id IS NULL
     AND ROWNUM<2;

  IF ln_mst_cnt>0 THEN

	  ln_request_id := FND_REQUEST.submit_request(
			                             application =>  G_APPLICATION
                  			          ,program     =>  'XX_INV_ITEM_INTF_MAIN'
			                            ,sub_request =>  FALSE
                                              ,argument1   =>  'Y'
                                             );
        IF ln_request_id = 0 THEN
           x_errbuf  := 'Unable to submit OD INV Item Interface Master Program for Master Records';
           x_retcode :=-1;
        ELSE
           COMMIT;
        END IF;

  END IF;

-- Added hint for performance improvement defect 534

  SELECT /*+ index(a XX_INV_ITEM_LOC_INT_N5) */
	 COUNT(1)
    INTO ln_loc_cnt
    FROM XX_INV_ITEM_LOC_INT a
   WHERE a.process_flag=1
     AND a.load_batch_id IS NULL
     AND ROWNUM<2;

  IF ln_loc_cnt>0 THEN

        ln_request_id := FND_REQUEST.submit_request(
			                             application =>  G_APPLICATION
                  			          ,program     =>  'XX_INV_ITEM_INTF_MAIN'
			                            ,sub_request =>  FALSE
                                              ,argument1   =>  'N'
                                             );
        IF ln_request_id = 0 THEN
           x_errbuf  :=x_errbuf|| ' ,Unable to submit OD INV Item Interface Master Program for Item/Loc Records';
           x_retcode :=-1;
        ELSE
           COMMIT;
        END IF;

  END IF;

EXCEPTION
  WHEN others THEN
    x_retcode:=-1;
    x_errbuf :=SQLERRM ||' Error in submission of Item Interface Concurrent Program';
END;

-- +=========================================================================+
-- | Name        :  Get_old_category_id                                      |
-- | Description :  This function returns existing category id from          |
-- |                mtl_item_categories                                      |
-- | Parameters  :  Category_Set_id, Item Id                                 |
-- +=========================================================================+

FUNCTION GET_OLD_CATEGORY_ID
              ( p_category_set_id mtl_category_sets.category_set_id%TYPE
		   ,p_item_id mtl_system_items_b.inventory_item_id%TYPE
              )
RETURN mtl_categories_b.category_id%TYPE
IS
x_old_category_id mtl_categories_b.category_id%TYPE := NULL;
BEGIN
  SELECT MIG.category_id
  INTO   x_old_category_id
  FROM   MTL_ITEM_CATEGORIES MIG
  WHERE  MIG.inventory_item_id = p_item_id
  AND    MIG.organization_id   = gn_master_org_id
  AND    MIG.category_set_id   = p_category_set_id;
  RETURN x_old_category_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN(0);
  WHEN OTHERS THEN
    RETURN -1;
END GET_OLD_CATEGORY_ID;

-- +=========================================================================+
-- | Name        :  Get_master_item_status                                   |
-- | Description :  This function returns master item status                 |
-- |                                                                         |
-- | Parameters  :  Item Id                                                  |
-- +=========================================================================+

FUNCTION GET_MASTER_ITEM_STATUS
              (p_item IN mtl_system_items_b.segment1%TYPE
              )
RETURN MTL_SYSTEM_ITEMS_B.inventory_item_status_code%TYPE
IS
x_item_status MTL_SYSTEM_ITEMS_B.inventory_item_status_code%TYPE;
BEGIN
      SELECT MSIB.inventory_item_status_code
      INTO   x_item_status
      FROM   MTL_SYSTEM_ITEMS_B MSIB
      WHERE  MSIB.organization_id   = gn_master_org_id
	AND    MSIB.segment1 = p_item;
      RETURN x_item_status;
EXCEPTION
  WHEN OTHERS THEN
    x_item_status   :='-989';
    RETURN x_item_status;
END GET_MASTER_ITEM_STATUS;

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
PROCEDURE bat_child(
			   p_master			 IN  VARCHAR2
                    ,x_errbuf              OUT NOCOPY VARCHAR2
                    ,x_retcode             OUT NOCOPY VARCHAR2
                   )

IS
------------------------------------------
--Declaring local Exceptions and Variables
------------------------------------------
EX_SUBMIT_CHILD     EXCEPTION;

ln_seq              PLS_INTEGER;
ln_master_count     PLS_INTEGER;
ln_loc_count        PLS_INTEGER;
lt_conc_request_id  FND_CONCURRENT_REQUESTS.request_id%TYPE;
lc_processing	  VARCHAR2(2):='MA';
ln_master_org	  PLS_INTEGER;
BEGIN

  BEGIN
    SELECT MP.organization_id
	INTO ln_master_org
      FROM mtl_parameters MP
     WHERE MP.organization_id=MP.master_organization_id
       AND ROWNUM=1;
  EXCEPTION
    WHEN others THEN
	ln_master_org:=NULL;
  END;
  ------------------------------------------------------------
  --Updating Master table with load batch id and process flags
  ------------------------------------------------------------
  SELECT XX_INV_ITEM_STG_BAT_S.NEXTVAL
    INTO   ln_seq
    FROM   DUAL;
  ------------------------------------------------------------
  --Updating Master table with load batch id and process flags
  ------------------------------------------------------------
  IF p_master='Y' THEN

    lc_processing :='MA';

    UPDATE XX_INV_ITEM_MASTER_INT XSIM
       SET XSIM.load_batch_id      = ln_seq
          ,XSIM.item_process_flag  = (CASE WHEN item_process_flag IS NULL OR item_process_flag= 1  THEN 2
						       ELSE item_process_flag
				              END)
          ,XSIM.inv_category_process_flag   = (CASE WHEN inv_category_process_flag  IS NULL  OR 												         inv_category_process_flag  = 1  THEN 2
								    ELSE inv_category_process_flag
							      END)
          ,XSIM.odpb_category_process_flag  = (CASE WHEN odpb_category_process_flag IS NULL  OR 													   odpb_category_process_flag  = 1 THEN 2
								    ELSE odpb_category_process_flag
								END)
          ,XSIM.po_category_process_flag    = (CASE WHEN po_category_process_flag   IS NULL  OR 												         po_category_process_flag    = 1 THEN 2
								    ELSE po_category_process_flag
								END)
          ,XSIM.atp_category_process_flag   = (CASE WHEN atp_category_process_flag  IS NULL  OR
									   atp_category_process_flag   = 1 THEN 2
								    ELSE atp_category_process_flag
								END)
          ,XSIM.validation_orgs_status_flag = (CASE WHEN validation_orgs_status_flag IS NULL THEN 'N'
								    ELSE validation_orgs_status_flag
							      END)
          ,XSIM.master_item_attr_process_flag=(CASE WHEN master_item_attr_process_flag IS NULL  THEN  1
								    ELSE master_item_attr_process_flag
								END)
    WHERE  XSIM.process_flag                   = 1
      AND  XSIM.action_type='A'
	AND  XSIM.inventory_item_id=-1
	AND  XSIM.load_batch_id                  IS NULL
      AND    ROWNUM <= gn_mbatch_size;

    ln_master_count := SQL%ROWCOUNT;

    IF SQL%NOTFOUND THEN

       lc_processing :='MC';

       UPDATE XX_INV_ITEM_MASTER_INT XSIM
          SET XSIM.load_batch_id                  = ln_seq
             ,XSIM.item_process_flag              = (CASE WHEN item_process_flag  IS NULL  OR
										   item_process_flag   = 1  THEN 2
									    ELSE item_process_flag
								      END)
             ,XSIM.inv_category_process_flag      = (CASE WHEN inv_category_process_flag IS NULL  OR 														   inv_category_process_flag   = 1   THEN 2
								          ELSE inv_category_process_flag
									END)
             ,XSIM.odpb_category_process_flag     = (CASE WHEN odpb_category_process_flag      IS NULL  OR 													   odpb_category_process_flag  = 1   THEN 2 ELSE 												   odpb_category_process_flag
									END)
             ,XSIM.po_category_process_flag       = (CASE WHEN po_category_process_flag        IS NULL  OR 													   po_category_process_flag    = 1   THEN 2
									    ELSE po_category_process_flag
									END)
             ,XSIM.atp_category_process_flag      = (CASE WHEN atp_category_process_flag       IS NULL  OR 													   atp_category_process_flag   = 1   THEN 2
									    ELSE atp_category_process_flag
									END)
             ,XSIM.validation_orgs_status_flag    = (CASE WHEN validation_orgs_status_flag  IS NULL  THEN 'N'
									    ELSE validation_orgs_status_flag   END)
             ,XSIM.master_item_attr_process_flag  = (CASE WHEN master_item_attr_process_flag   IS NULL  THEN  1
								          ELSE master_item_attr_process_flag END)
       WHERE  XSIM.process_flag                   = 1
         AND  XSIM.action_type='C'
	   AND  XSIM.inventory_item_id=-1
	   AND  XSIM.load_batch_id                  IS NULL
         AND    ROWNUM <= gn_mbatch_size;

       ln_master_count := SQL%ROWCOUNT;

    END IF;

    COMMIT;

    ELSE

    ----------------------------------------------------------
    --Updating Child table with load batch id and process flag
    ----------------------------------------------------------

      lc_processing :='LA';

	UPDATE  XX_INV_ITEM_LOC_INT XSIL
      SET     XSIL.load_batch_id         = ln_seq
             ,XSIL.location_process_flag = (CASE WHEN location_process_flag  IS NULL  OR location_process_flag = 1 									 THEN 2
								 ELSE location_process_flag
							  END)
             ,XSIL.loc_item_attr_process_flag = (CASE WHEN loc_item_attr_process_flag  IS NULL
								 THEN 1
								 ELSE loc_item_attr_process_flag
								 END)
      WHERE   XSIL.process_flag           = 1
	AND     XSIL.action_type='A'
	AND     XSIL.inventory_item_id=-1
	AND     XSIL.load_batch_id          IS NULL
      AND     ROWNUM<=gn_batch_size;

      ln_loc_count := SQL%ROWCOUNT;

      IF SQL%NOTFOUND THEN

         lc_processing :='LC';

   	   UPDATE  XX_INV_ITEM_LOC_INT XSIL
         SET     XSIL.load_batch_id           = ln_seq
                ,XSIL.location_process_flag   = (CASE WHEN location_process_flag IS NULL  OR location_process_flag = 1
									THEN 2
									ELSE location_process_flag
								 END)
                ,XSIL.loc_item_attr_process_flag = (CASE WHEN loc_item_attr_process_flag  IS NULL
									   THEN 1
									   ELSE loc_item_attr_process_flag
								    END)
         WHERE   XSIL.process_flag           = 1
	   AND     XSIL.action_type='C'
	   AND     XSIL.inventory_item_id=-1
	   AND     XSIL.load_batch_id          IS NULL
         AND     ROWNUM<=gn_batch_size;

         ln_loc_count := SQL%ROWCOUNT;

	END IF;

    END IF;
    COMMIT;

    -----------------------------------------
    --Submitting Child Program for each batch
    -----------------------------------------

    IF (ln_master_count > 0) OR (ln_loc_count > 0 ) THEN

       lt_conc_request_id := FND_REQUEST.submit_request(
                                                        application =>  G_APPLICATION
                                                       ,program     =>  G_CHILD_PROGRAM
                                                       ,sub_request =>  FALSE
                                                       ,argument1   =>  lc_processing
                                                       ,argument2   =>  ln_seq
                                                       );
        IF lt_conc_request_id = 0 THEN
                x_errbuf  := FND_MESSAGE.GET;
                RAISE EX_SUBMIT_CHILD;
        ELSE
           COMMIT;
	  END IF;

    END IF;
EXCEPTION
  WHEN EX_SUBMIT_CHILD THEN
       x_retcode := 2;
       x_errbuf  := 'Error in submitting child requests: ' || x_errbuf;
END bat_child;

-- +===================================================================+
-- | Name        :  submit_sub_requests                                |
-- | Description :  This procedure is invoked from the master_main     |
-- |                procedure. This would submit child requests based  |
-- |                on batch_size.                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :  p_master                                           |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE submit_sub_requests( p_master              IN VARCHAR2
                              ,x_errbuf              OUT NOCOPY VARCHAR2
                              ,x_retcode             OUT NOCOPY VARCHAR2
                             )
IS

ln_req_count  	   PLS_INTEGER:=0;
ln_current_count	   PLS_INTEGER:=0;
ln_run_count	   PLS_INTEGER:=0;
ln_mst_count	   PLS_INTEGER:=0;


BEGIN

  BEGIN
    SELECT MP.organization_id
	INTO ln_master_org
      FROM mtl_parameters MP
     WHERE MP.organization_id=MP.master_organization_id
       AND ROWNUM=1;
  EXCEPTION
    WHEN others THEN
	ln_master_org:=NULL;
  END;


  LOOP

    SELECT COUNT(1)
      INTO ln_run_count
      FROM fnd_concurrent_requests
     WHERE concurrent_program_id IN (SELECT concurrent_program_id
						   FROM fnd_concurrent_programs
					        WHERE concurrent_program_name='XX_INV_ITEM_INTF_CHILD'
					          AND application_id=401
					          AND enabled_flag='Y')
       AND program_application_id=401
       AND phase_code IN ('P','R');

    IF p_master='Y' THEN

       SELECT COUNT(1)
         INTO ln_mst_count
         FROM fnd_concurrent_requests
        WHERE concurrent_program_id IN (SELECT concurrent_program_id
						   FROM fnd_concurrent_programs
					        WHERE concurrent_program_name='XX_INV_ITEM_INTF_CHILD'
					          AND application_id=401
	  				          AND enabled_flag='Y')
         AND program_application_id=401
         AND phase_code IN ('P','R')
	   AND argument1 IN ('MA','MC');

         IF ln_mst_count=6 THEN
            EXIT;
         END IF;

    END IF;

    IF ln_run_count=gn_threads THEN
       EXIT;
    END IF;

    ln_req_count:=ln_req_count+1;

    IF p_master='Y' THEN
       SELECT COUNT(1)
         INTO ln_current_count
         FROM XX_INV_ITEM_MASTER_INT
        WHERE process_flag = 1
	  AND action_type in ('A','C')
	  AND inventory_item_id=-1
          AND load_batch_id IS NULL
	    AND ROWNUM<2;

    ELSE
       SELECT COUNT(1)
         INTO ln_current_count
         FROM XX_INV_ITEM_LOC_INT XILI
        WHERE XILI.process_flag = 1 and XILI.action_type in ('A','C')
	  and XILI.inventory_item_id=-1
          AND XILI.load_batch_id IS NULL
	    AND ROWNUM<2;
    END IF;

    IF ln_current_count=0 THEN
       EXIT;
    ELSE
        bat_child(
		  p_master			=> p_master
             ,x_errbuf              => x_errbuf
             ,x_retcode             => x_retcode
              );
    END IF;

    IF p_master='Y' THEN
	 IF ln_req_count=6 THEN
          EXIT;
       END IF;
    ELSE
	 IF ln_req_count=gn_threads+3 THEN
          EXIT;
       END IF;
    END IF;
  END LOOP;
END submit_sub_requests;


-- +====================================================================+
-- | Name        :  master_main                                         |
-- | Description :  This procedure is invoked from the 			|
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
			   ,p_master              IN  VARCHAR2
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

    BEGIN
      SELECT ebs_threads,
 	       ebs_batch_size
        INTO gn_threads,
  	       gn_batch_size
        FROM xx_inv_ebs_control
       WHERE process_name='ITEM_LOC';
    EXCEPTION
	WHEN others THEN
        gn_threads:=15;
        gn_batch_size:=4000;
    END;
    BEGIN
      SELECT ebs_batch_size
        INTO gn_mbatch_size
        FROM xx_inv_ebs_control
       WHERE process_name='ITEM_MASTER';
    EXCEPTION
	WHEN others THEN
        gn_mbatch_size:=500;
    END;

    submit_sub_requests( p_master
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
-- | Description :  This procedure is invoked from child_main          |
-- |                                                                   |
-- | Parameters  :  None                                               |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE validate_setups
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
WHERE  HOU.TYPE='VAL'
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
    END IF;
    IF  gn_ds_template_id IS NULL THEN
        display_log('OD Drop Ship Item Template not defined in the System');
    END IF;
    CLOSE lcu_templates;

    IF (lc_masterorg_status='N' OR lc_mer_template_status='N') THEN
        gc_master_setup_status:='N';
        display_log('Master Seups are not defined in the System');
    ELSE
        gc_master_setup_status:='Y';
    END IF;
    -------------------------
    --Category Set Validation
    -------------------------
    OPEN lcu_category_sets;
    FETCH lcu_category_sets INTO gn_inv_category_set_id,gn_odpb_category_set_id,gn_po_category_set_id,gn_atp_category_set_id;
    IF  gn_inv_category_set_id IS NULL THEN
        display_log('Inventory Category Set not defined in the System');
    END IF;
    IF  gn_odpb_category_set_id IS NULL THEN
        display_log('Office Depot Private Brand Category Set not defined in the System');
    END IF;
    IF  gn_po_category_set_id IS NULL THEN
        display_log('PO CATEGORY Category Set not defined in the System');
    END IF;
    IF  gn_atp_category_set_id IS NULL THEN
        display_log('ATP_CATEGORY Category Set not defined in the System');
    END IF;
    CLOSE lcu_category_sets;
    ---------------------------
    --Structure Code Validation
    ---------------------------
    OPEN lcu_structure_id;
    FETCH lcu_structure_id INTO gn_inv_structure_id,gn_odpb_structure_id,gn_po_structure_id,gn_atp_structure_id;
    IF  gn_inv_structure_id IS NULL THEN
        display_log('Structure Code ITEM_CATEGORIES not defined in the System');
    END IF;
    IF  gn_odpb_structure_id IS NULL THEN
        display_log('Structure Code OD_ITM_BRAND_CATEGORY not defined in the System');
    END IF;
    IF  gn_po_structure_id IS NULL THEN
        display_log('Structure Code PO_ITEM_CATEGORY not defined in the System');
    END IF;
    IF  gn_atp_structure_id IS NULL THEN
        display_log('Structure Code OD_ATP_PLANNING_CATEGORY not defined in the System');
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
    ELSE
        gc_valorg_setup_status:='Y';
        gn_val_org_count := gt_val_orgs.COUNT;
    END IF;
    CLOSE lcu_val_orgs;
EXCEPTION
WHEN OTHERS THEN
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    display_log('Unexpected error in validate_setups - '||gc_sqlerrm);
END validate_setups;


-- +===================================================================+
-- | Name        :  validate_master_data                               |
-- | Description :  This procedure is invoked from Child_main procedure|
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                p_process                                          |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+

PROCEDURE validate_master_data(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
				    ,p_process	 IN  VARCHAR2
                            ,p_batch_id    IN  NUMBER
                             )
IS

------------------------------------------
--Declaring Exceptions and local variables
------------------------------------------
EX_MASTER_NO_DATA           EXCEPTION;

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
	,XSIM.item
	,XSIM.item_desc
	,XSIM.package_uom
	,XSIM.status
	,XSIM.orderable_ind
	,XSIM.sellable_ind
	,XSIM.od_tax_category
      ,XSIM.control_id
      ,XSIM.dept
      ,XSIM.CLASS
      ,XSIM.subclass
      ,XSIM.od_private_brand_label
      ,XSIM.od_private_brand_flg
      ,XSIM.od_prod_protect_cd
      ,XSIM.od_ovrsize_delvry_flg
      ,XSIM.item_number_type
      ,XSIM.od_sku_type_cd
FROM   XX_INV_ITEM_MASTER_INT XSIM
WHERE  XSIM.load_batch_id = p_batch_id
AND    XSIM.action_type=DECODE(p_process,'MA','A','MC','C')
AND    (XSIM.item_process_flag              IN (1,2,3)
        OR XSIM.inv_category_process_flag   IN (1,2,3)
        OR XSIM.odpb_category_process_flag  IN (1,2,3)
        OR XSIM.po_category_process_flag    IN (1,2,3)
        OR XSIM.atp_category_process_flag   IN (1,2,3)
       )
ORDER BY XSIM.control_id;

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
AND   MC.enabled_flag = 'Y'
AND   (      SYSDATE BETWEEN NVL(MC.start_date_active,SYSDATE - 1)
       AND   NVL(MC.end_date_active,SYSDATE + 1)
      )
AND   (      SYSDATE <= NVL(MC.disable_date, SYSDATE + 1)
      )
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
AND   MC.enabled_flag = 'Y'
AND   (      SYSDATE BETWEEN NVL(MC.start_date_active,SYSDATE - 1)
       AND   NVL(MC.end_date_active,SYSDATE + 1)
      )
AND   (      SYSDATE <= NVL(MC.disable_date, SYSDATE + 1)
      )
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
AND   MC.enabled_flag = 'Y'
AND   (      SYSDATE BETWEEN NVL(MC.start_date_active,SYSDATE - 1)
       AND   NVL(MC.end_date_active,SYSDATE + 1)
      )
AND   (      SYSDATE <= NVL(MC.disable_date, SYSDATE + 1)
      )
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
AND   MC.enabled_flag = 'Y'
AND   (      SYSDATE BETWEEN NVL(MC.start_date_active,SYSDATE - 1)
       AND   NVL(MC.end_date_active,SYSDATE + 1)
      )
AND   (      SYSDATE <= NVL(MC.disable_date, SYSDATE + 1)
      )
;

--------------------------------
--Declaring Table Type Variables
--------------------------------
TYPE itemmaster_tbl_type IS TABLE OF lcu_item_and_category%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_itemmaster itemmaster_tbl_type;

TYPE mst_rowid_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_master_row_id mst_rowid_tbl_type;

TYPE item_pf_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.item_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_item_pf_tbl item_pf_tbl_type;

TYPE item_id_tbl_type IS TABLE OF mtl_system_items_b.inventory_item_id%TYPE
INDEX BY BINARY_INTEGER;
lt_item_id item_id_tbl_type;

TYPE inv_category_pf_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.inv_category_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_inv_categorypf inv_category_pf_tbl_type;

TYPE inv_categoryid_pf_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.inv_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_inv_categoryid inv_categoryid_pf_tbl_type;

TYPE old_inv_cid_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.inv_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_old_inv_catid old_inv_cid_tbl_type;

TYPE odpb_category_pf_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.odpb_category_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_odpb_categorypf odpb_category_pf_tbl_type;

TYPE odpb_categoryid_pf_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.odpb_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_odpb_categoryid odpb_categoryid_pf_tbl_type;

TYPE old_odpb_cid_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.odpb_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_old_odpb_catid old_odpb_cid_tbl_type;

TYPE po_category_pf_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.po_category_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_po_categorypf po_category_pf_tbl_type;

TYPE po_categoryid_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.po_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_po_categoryid po_categoryid_tbl_type;

TYPE old_po_cid_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.po_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_old_po_catid old_po_cid_tbl_type;

TYPE atp_category_pf_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.atp_category_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_atp_categorypf atp_category_pf_tbl_type;

TYPE atp_categoryid_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.atp_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_atp_categoryid atp_categoryid_tbl_type;

TYPE old_atp_cid_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.atp_category_id%TYPE
INDEX BY BINARY_INTEGER;
lt_old_atp_catid old_atp_cid_tbl_type;

TYPE shippable_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.shippable_item_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_shippable_item_flag shippable_tbl_type;

TYPE od_sku_type_cd_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.od_sku_type_cd%TYPE
INDEX BY BINARY_INTEGER;
lt_od_sku_type_cd od_sku_type_cd_tbl_type;

TYPE error_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.error_message%TYPE
INDEX BY BINARY_INTEGER;
lt_error_tbl  error_tbl_type;

TYPE errflg_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.error_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_errflg_tbl  errflg_tbl_type;


TYPE call_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.api_change%TYPE
INDEX BY BINARY_INTEGER;
lt_call_tbl  call_tbl_type;

TYPE taxc_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.tax_change%TYPE
INDEX BY BINARY_INTEGER;
lt_taxc_tbl  taxc_tbl_type;

lc_description		mtl_system_items_b.description%TYPE		  		:=NULL;
lc_uom			mtl_system_items_b.primary_uom_code%TYPE	  		:=NULL;
lc_itm_status		mtl_system_items_b.inventory_item_status_code%TYPE 	:=NULL;
lc_pur_flag			mtl_system_items_b.purchasing_item_flag%TYPE 		:=NULL;
lc_cust_flag		mtl_system_items_b.customer_order_flag%TYPE		:=NULL;
lc_item_type		mtl_system_items_b.item_type%TYPE				:=NULL;
lc_ship_flag		mtl_system_items_b.shippable_item_flag%TYPE		:=NULL;
lc_od_prod_prt_cd       xx_inv_item_master_attributes.od_prod_protect_cd%TYPE	:=NULL;
lc_tax_cat			mtl_system_items_b.attribute1%TYPE				:=NULL;
ln_inventory_item_id	mtl_system_items_b.inventory_item_id%TYPE			:=NULL;
BEGIN
    OPEN  lcu_item_and_category(p_batch_id);
    FETCH lcu_item_and_category BULK COLLECT INTO lt_itemmaster;
    CLOSE lcu_item_and_category;

    IF lt_itemmaster.COUNT <> 0 THEN
       FOR i IN 1..lt_itemmaster.COUNT
       LOOP

	   lt_shippable_item_flag(i)  := NULL;
         lt_inv_categorypf(i)		:= NULL;
         lt_odpb_categorypf(i)	:= NULL;
         lt_po_categorypf(i)		:= NULL;
         lt_atp_categorypf(i)		:= NULL;
         lt_inv_categoryid(i)		:= NULL;
         lt_odpb_categoryid(i)	:= NULL;
         lt_po_categoryid(i)		:= NULL;
         lt_atp_categoryid(i)		:= NULL;
         lt_od_sku_type_cd(i)		:= NULL;
	   lt_call_tbl(i)			:= NULL;
	   lt_taxc_tbl(i)			:= NULL;
	   lt_item_pf_tbl(i)	      := NULL;
	   lt_old_inv_catid(i)		 := NULL;
	   lt_old_odpb_catid(i)		 := NULL;
	   lt_old_po_catid(i)		 := NULL;
	   lt_old_atp_catid(i)		 := NULL;
	   lt_item_id(i)			 := NULL;
	   lt_error_tbl(i)		 := NULL;
	   lt_errflg_tbl(i)		 := 'N';
         lt_master_row_id(i)         := lt_itemmaster(i).ROWID;
         ln_inv_category_id          := NULL;
         ln_odbrand_category_id      := NULL;
         ln_po_category_id           := NULL;
         ln_atp_category_id          := NULL;
         lc_description		       := NULL;
     	   lc_uom			       := NULL;
	   lc_itm_status		       := NULL;
	   lc_pur_flag			 := NULL;
	   lc_cust_flag		       := NULL;
	   lc_item_type		       := NULL;
	   lc_ship_flag		       := NULL;
	   lc_od_prod_prt_cd           := NULL;
	   lc_tax_cat			 := NULL;
	   ln_inventory_item_id        := NULL;





         --Validating Category Id for Inventory Category Set

         IF gn_inv_structure_id IS NOT NULL THEN
            OPEN lcu_inv_category(gn_inv_structure_id,lt_itemmaster(i).dept,lt_itemmaster(i).CLASS,lt_itemmaster(i).subclass);
            FETCH lcu_inv_category INTO ln_inv_category_id;
            IF lcu_inv_category%NOTFOUND THEN
               lt_inv_categorypf(i):= 3;
               lt_inv_categoryid(i):= NULL;
		   lt_error_tbl(i):='Inventory Category Not set up';
		   lt_errflg_tbl(i):='Y';
            ELSE
               lt_inv_categoryid(i):= ln_inv_category_id;
               lt_inv_categorypf(i):= 4;
            END IF;
            CLOSE lcu_inv_category;
         ELSE
            lt_inv_categorypf(i) := 3;
            lt_inv_categoryid(i) := NULL;
            lt_error_tbl(i):='Inventory Structure Not set up';
  	      lt_errflg_tbl(i):='Y';
         END IF;--gn_inv_structure_id IS NOT NULL

         --Validating Category Id for Office Depot Private Brand Category Set
         IF gn_odpb_structure_id IS NOT NULL THEN
            IF lt_itemmaster(i).od_private_brand_flg = 'Y' THEN
               IF lt_itemmaster(i).od_private_brand_label IS NULL THEN
                  lt_odpb_categorypf(i):= 3;
                  lt_odpb_categoryid(i):= NULL;
   	            lt_errflg_tbl(i):='Y';
                  lt_error_tbl(i):=lt_error_tbl(i)||',OD_PRIVATE_BRAND_LABEL is mandatory when OD_PRIVATE_BRAND_FLAG is Y';
               ELSE
                 OPEN lcu_odpb_category(gn_odpb_structure_id,lt_itemmaster(i).od_private_brand_label);
                 FETCH lcu_odpb_category INTO ln_odbrand_category_id;
                 IF lcu_odpb_category%NOTFOUND THEN
                    lt_odpb_categorypf(i):= 3;
                    lt_odpb_categoryid(i):= NULL;
			  lt_error_tbl(i):=lt_error_tbl(i)||', OD Private Brand Category Not set up';
 		        lt_errflg_tbl(i):='Y';
                 ELSE
                    lt_odpb_categoryid(i):= ln_odbrand_category_id;
                    lt_odpb_categorypf(i):= 4;
                 END IF;
                 CLOSE lcu_odpb_category;
               END IF; -- lt_itemmaster(i).od_private_brand_flg='Y'
            ELSE -- lt_itemmaster(i).od_private_brand_flg = 'N'
               lt_odpb_categoryid(i):= NULL;
               lt_odpb_categorypf(i):= 7;
            END IF; --lt_itemmaster(i).od_private_brand_label IS NULL
         ELSE
           lt_odpb_categorypf(i) := 3;
           lt_odpb_categoryid(i) := NULL;
           lt_error_tbl(i):=lt_error_tbl(i)||', OD Private Brand Structure Not setup';
 	     lt_errflg_tbl(i):='Y';
         END IF;--gn_odpb_structure_id IS NOT NULL

         --Validating Category Id for PO Category Category Set
         IF gn_po_structure_id IS NOT NULL THEN
            OPEN lcu_po_category(gn_po_structure_id,lt_itemmaster(i).dept,lt_itemmaster(i).CLASS,lt_itemmaster(i).subclass);
            FETCH lcu_po_category INTO ln_po_category_id;
            IF lcu_po_category%NOTFOUND THEN
               lt_po_categorypf(i)     :=  3;
               lt_po_categoryid(i)     :=  NULL;
		   lt_errflg_tbl(i):='Y';
		   lt_error_tbl(i):=lt_error_tbl(i)||', PO Category Not set up';
            ELSE
               lt_po_categoryid(i):= ln_po_category_id;
               lt_po_categorypf(i):= 4;
            END IF;
            CLOSE lcu_po_category;
         ELSE
            lt_po_categorypf(i) := 3;
            lt_po_categoryid(i) := NULL;
  	      lt_errflg_tbl(i):='Y';
            lt_error_tbl(i):=lt_error_tbl(i)||', PO Category Structure Not setup';
         END IF;--gn_po_structure_id IS NOT NULL

         --Validating Category Id for ATP_CATEGORY Category Set
         IF gn_atp_structure_id IS NOT NULL THEN
            IF lt_itemmaster(i).od_ovrsize_delvry_flg IS NOT NULL THEN
               OPEN lcu_atp_category(gn_atp_structure_id,lt_itemmaster(i).od_ovrsize_delvry_flg);
               FETCH lcu_atp_category INTO ln_atp_category_id;
               IF lcu_atp_category%NOTFOUND THEN
                  lt_atp_categorypf(i)     :=  3;
                  lt_atp_categoryid(i)     :=  NULL;
 	  	      lt_errflg_tbl(i):='Y';
                  lt_error_tbl(i):=lt_error_tbl(i)||', ATP Category Not set up';
               ELSE
                  lt_atp_categoryid(i):= ln_atp_category_id;
                  lt_atp_categorypf(i):= 4;
               END IF;
               CLOSE lcu_atp_category;
            ELSE
               lt_atp_categoryid(i):= NULL;
               lt_atp_categorypf(i):= 7;
            END IF;
         ELSE
            lt_atp_categorypf(i) := 3;
            lt_atp_categoryid(i) := NULL;
  	      lt_errflg_tbl(i):='Y';
            lt_error_tbl(i):=lt_error_tbl(i)||', ATP Category Structure Not setup';
         END IF;--gn_atp_structure_id IS NOT NULL

         --Assigning 'Non-Code Item' Item type if item_number_type is ITEM7
         IF lt_itemmaster(i).item_number_type  =  'ITEM7' THEN
            lt_od_sku_type_cd(i)   :=  '08';
         ELSE
            lt_od_sku_type_cd(i)   :=   lt_itemmaster(i).od_sku_type_cd;
         END IF;

         --Disabling the Shippable item flag for Warranty Item
         IF lt_itemmaster(i).od_prod_protect_cd ='P' THEN
            lt_shippable_item_flag(i) := 'N';
         ELSE
            lt_shippable_item_flag(i) := 'Y';
         END IF;

         IF p_process='MC' THEN

		BEGIN
		  SELECT description,
			   inventory_item_id,
			   primary_uom_code,
		   	   inventory_item_status_code,
			   purchasing_item_flag,
			   customer_order_flag,
			   item_type,
			   shippable_item_flag,
			   attribute1
		    INTO lc_description,
			   ln_inventory_item_id,
			   lc_uom,
			   lc_itm_status,
			   lc_pur_flag,
			   lc_cust_flag,
			   lc_item_type,
			   lc_ship_flag,
			   lc_tax_cat
		    FROM mtl_system_items_b
		   WHERE segment1=lt_itemmaster(i).item
		     AND organization_id=gn_master_org_id;

		  lt_item_id(i):=ln_inventory_item_id;

		  IF lc_uom<>lt_itemmaster(i).package_uom THEN
                 lt_error_tbl(i):=lt_error_tbl(i)||'UOM Change has not been applied in EBS';
		     lt_errflg_tbl(i)		 := 'Y';
		  END IF;

		  IF (lt_itemmaster(i).item_desc||lt_itemmaster(i).package_uom||
		      lt_itemmaster(i).status||lt_od_sku_type_cd(i)||
		      lt_itemmaster(i).orderable_ind||lt_itemmaster(i).sellable_ind||
		      lt_shippable_item_flag(i)) <>
                  (lc_description||lc_uom||lc_itm_status||lc_item_type||lc_pur_flag||
		      lc_cust_flag||lc_ship_flag) THEN

			lt_call_tbl(i):='Y';

		  ELSE

			lt_call_tbl(i):='N';

		  END IF;
		  IF NVL(lt_itemmaster(i).od_tax_category,'X')<>NVL(lc_tax_cat,'X') THEN
		     lt_taxc_tbl(i):='Y';
		  ELSE
		     lt_taxc_tbl(i):='N';
		  END IF;

	        lt_old_inv_catid(i):=get_old_category_id(gn_inv_category_set_id,ln_inventory_item_id);
	        lt_old_odpb_catid(i):= get_old_category_id(gn_odpb_category_set_id,ln_inventory_item_id);
		  lt_old_po_catid(i):=get_old_category_id(gn_po_category_set_id,ln_inventory_item_id);
	        lt_old_atp_catid(i):=get_old_category_id(gn_atp_category_set_id,ln_inventory_item_id);

		EXCEPTION
              WHEN OTHERS THEN
		    lt_item_pf_tbl(i):=3;
                lt_error_tbl(i):=lt_error_tbl(i)||'Item not exists in EBS to change';
  		END;

	   END IF;

       END LOOP; --End of Master Items Loop

       ------------------------------------------------------------
       -- Bulk Update XX_INV_ITEM_MASTER_INT with Process flags and Ids
       ------------------------------------------------------------
	 IF p_process='MA' THEN
       FORALL i IN 1 .. lt_itemmaster.LAST
          UPDATE XX_INV_ITEM_MASTER_INT XSIM
          SET    XSIM.inv_category_process_flag  =  lt_inv_categorypf(i)
                ,XSIM.odpb_category_process_flag =  lt_odpb_categorypf(i)
                ,XSIM.po_category_process_flag   =  lt_po_categorypf(i)
                ,XSIM.atp_category_process_flag  =  lt_atp_categorypf(i)
                ,XSIM.item_process_flag          =  (CASE WHEN item_process_flag <> 7
                                                                   AND
                                                                   (   lt_inv_categorypf(i)  = 3
                                                                    OR lt_odpb_categorypf(i) = 3
                                                                    OR lt_po_categorypf(i)   = 3
                                                                    OR lt_atp_categorypf(i)  = 3
                                                                   )                            THEN 3
                                                              WHEN item_process_flag < 4        THEN 4
                                                              ELSE item_process_flag
                                                         END
                                                        )
                    ,XSIM.load_batch_id              =  p_batch_id
                    ,XSIM.inv_category_id            =  lt_inv_categoryid(i)
                    ,XSIM.odpb_category_id           =  lt_odpb_categoryid(i)
                    ,XSIM.po_category_id             =  lt_po_categoryid(i)
                    ,XSIM.atp_category_id            =  lt_atp_categoryid(i)
                    ,XSIM.od_sku_type_cd             =  lt_od_sku_type_cd(i)
                    ,XSIM.organization_id            =  gn_master_org_id
                    ,XSIM.template_id                =  gn_mer_template_id
                    ,XSIM.shippable_item_flag        =  lt_shippable_item_flag(i)
			  ,XSIM.error_message		     =  lt_error_tbl(i)
		        ,XSIM.error_Flag		     =  lt_errflg_tbl(i)
              WHERE  XSIM.ROWID                      =  lt_master_row_id(i);
              COMMIT;
       ELSE
         FORALL i IN 1 .. lt_itemmaster.LAST
          UPDATE XX_INV_ITEM_MASTER_INT XSIM
          SET    XSIM.inv_category_process_flag  =  lt_inv_categorypf(i)
                ,XSIM.odpb_category_process_flag =  lt_odpb_categorypf(i)
                ,XSIM.po_category_process_flag   =  lt_po_categorypf(i)
                ,XSIM.atp_category_process_flag  =  lt_atp_categorypf(i)
                ,XSIM.item_process_flag          =  (CASE WHEN item_process_flag <> 7
                                                                   AND
                                                                   (   lt_inv_categorypf(i)  = 3
                                                                    OR lt_odpb_categorypf(i) = 3
                                                                    OR lt_po_categorypf(i)   = 3
                                                                    OR lt_atp_categorypf(i)  = 3
											  OR lt_item_pf_tbl(i)	   = 3
                                                                   )                            THEN 3
                                                              WHEN item_process_flag < 4        THEN 4
                                                              ELSE item_process_flag
                                                         END
                                                        )
                    ,XSIM.load_batch_id              =  p_batch_id
                    ,XSIM.inv_category_id            =  lt_inv_categoryid(i)
                    ,XSIM.odpb_category_id           =  lt_odpb_categoryid(i)
                    ,XSIM.po_category_id             =  lt_po_categoryid(i)
                    ,XSIM.atp_category_id            =  lt_atp_categoryid(i)
                    ,XSIM.od_sku_type_cd             =  lt_od_sku_type_cd(i)
			  ,XSIM.api_change		     =  lt_call_tbl(i)
			  ,XSIM.tax_change		     =  lt_taxc_tbl(i)
                    ,XSIM.organization_id            =  gn_master_org_id
                    ,XSIM.template_id                =  gn_mer_template_id
                    ,XSIM.shippable_item_flag        =  lt_shippable_item_flag(i)
			  ,XSIM.error_message		     =  lt_error_tbl(i)
		        ,XSIM.error_Flag		     =  lt_errflg_tbl(i)
			  ,XSIM.old_inv_cat_id		     =  lt_old_inv_catid(i)
			  ,XSIM.old_odpb_cat_id		     =  lt_old_odpb_catid(i)
			  ,XSIM.old_po_cat_id		     =  lt_old_po_catid(i)
			  ,XSIM.old_atp_cat_id		     =  lt_old_atp_catid(i)
			  ,XSIM.inventory_item_id	     =  lt_item_id(i)
              WHERE  XSIM.ROWID                      =  lt_master_row_id(i);
              COMMIT;

       END IF;
    ELSE		--IF lt_itemmaster.COUNT <> 0 THEN
      RAISE EX_MASTER_NO_DATA;
    END IF; --lt_itemmaster.count <> 0
EXCEPTION
  WHEN EX_MASTER_NO_DATA THEN
       x_retcode := 1;
       x_errbuf  := 'No data found in the staging table XX_INV_ITEM_MASTER_INT with batch_id - '||p_batch_id;
  WHEN OTHERS THEN
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in validate_master_data - '||gc_sqlerrm;
    x_retcode := 2;
END validate_master_data;

-- +========================================================================+
-- | Name        :  validate_loc_data                                       |
-- | Description :  This procedure is invoked from the child_main procedure |
-- |                                                                        |
-- | Parameters  :  p_batch_id                                              |
-- |                p_process                                               |
-- |                                                                        |
-- | Returns     :  x_errbuf                                                |
-- |                x_retcode                                               |
-- |                                                                        |
-- +========================================================================+

PROCEDURE validate_loc_data(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
				    ,p_process	 IN  VARCHAR2
                            ,p_batch_id    IN  NUMBER
                             )
IS

------------------------------------------
--Declaring Exceptions and local variables
------------------------------------------
EX_LOCATION_NO_DATA         EXCEPTION;

lc_location_type            hr_organization_units.TYPE%TYPE;
ln_organization_id          mtl_parameters.organization_id%TYPE;

---------------------------------------------
--Cursor to get the Organization Item Details
---------------------------------------------
CURSOR lcu_location(p_batch_id IN NUMBER)
IS
SELECT XSIL.ROWID
      ,XSIL.control_id
      ,XSIL.loc
	,XSIL.item
	,XSIL.status
FROM   XX_INV_ITEM_LOC_INT XSIL
WHERE  XSIL.load_batch_id = p_batch_id
AND    XSIL.location_process_flag IN (1,2,3)
AND    XSIL.action_type=DECODE(p_process,'LA','A','LC','C')
ORDER BY XSIL.control_id;

---------------------------------------
--Cursor to determine the Location Type
---------------------------------------
CURSOR lcu_location_type (p_location VARCHAR2)
IS
SELECT HOU.organization_id
      ,HOU.TYPE
FROM   hr_organization_units HOU
WHERE  HOU.attribute1   =  p_location;

--------------------------------
--Declaring Table Type Variables
--------------------------------

TYPE loc_rowid_tbl_type IS TABLE OF ROWID
INDEX BY BINARY_INTEGER;
lt_location_row_id loc_rowid_tbl_type;

TYPE itemloc_tbl_type IS TABLE OF lcu_location%ROWTYPE
INDEX BY BINARY_INTEGER;
lt_itemlocation itemloc_tbl_type;

TYPE location_control_id_tbl_type IS TABLE OF XX_INV_ITEM_LOC_INT.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_location_control_id location_control_id_tbl_type;

TYPE location_pf_tbl_type IS TABLE OF XX_INV_ITEM_LOC_INT.location_process_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_location_pf location_pf_tbl_type;

TYPE loc_organization_id_tbl_type IS TABLE OF XX_INV_ITEM_LOC_INT.organization_id%TYPE
INDEX BY BINARY_INTEGER;
lt_org_id loc_organization_id_tbl_type;

TYPE loc_template_id_tbl_type IS TABLE OF XX_INV_ITEM_LOC_INT.template_id%TYPE
INDEX BY BINARY_INTEGER;
lt_template_id loc_template_id_tbl_type;

TYPE error_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.error_message%TYPE
INDEX BY BINARY_INTEGER;
lt_error_tbl  error_tbl_type;

TYPE errflg_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.error_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_errflg_tbl  errflg_tbl_type;

TYPE call_tbl_type IS TABLE OF XX_INV_ITEM_LOC_INT.api_change%TYPE
INDEX BY BINARY_INTEGER;
lt_call_tbl  call_tbl_type;

TYPE shippable_tbl_type IS TABLE OF mtl_system_items_b.shippable_item_flag%TYPE
INDEX BY BINARY_INTEGER;
lt_shippable_item_flag shippable_tbl_type;

ln_item_id 	  		NUMBER;
lc_loc_status 		MTL_SYSTEM_ITEMS_B.inventory_item_status_code%TYPE;
lc_master_status 		MTL_SYSTEM_ITEMS_B.inventory_item_status_code%TYPE;
lc_od_prod_prt_cd       XX_INV_ITEM_MASTER_ATTRIBUTES.od_prod_protect_cd%TYPE;
lc_ship_flag		MTL_SYSTEM_ITEMS_B.shippable_item_flag%TYPE;

BEGIN
  --------------------------------------
  --Fetching and Validating Location Data
  --------------------------------------

  OPEN lcu_location(p_batch_id);
  FETCH lcu_location BULK COLLECT INTO lt_itemlocation LIMIT G_LIMIT_SIZE;
  CLOSE lcu_location;

  IF lt_itemlocation.COUNT <> 0 THEN
     FOR i IN 1 .. lt_itemlocation.COUNT
     LOOP
       lt_location_row_id(i)       :=   lt_itemlocation(i).ROWID;
       lt_location_pf(i)	   :=   NULL;
       lt_template_id(i)	   :=   NULL;
       lt_org_id(i)		   :=	NULL;
       lt_shippable_item_flag(i)   :=   NULL;
       lt_call_tbl(i)		   :=   NULL;
       ln_organization_id          :=   NULL;
       lc_location_type            :=   NULL;
       lt_error_tbl(i)	    	     :=   NULL;
	 lt_errflg_tbl(i)		     :='N';
       OPEN lcu_location_type(lt_itemlocation(i).loc);
       LOOP
         FETCH lcu_location_type INTO ln_organization_id,lc_location_type;
         IF ln_organization_id IS NULL AND lc_location_type IS NULL THEN
            lt_location_pf(i)   :=  3;
            lt_org_id(i)        :=  0;
            lt_template_id(i)   :=  0;
		lt_error_tbl(i)	  :='Organization not set up';
		lt_errflg_tbl(i)    :='Y';
         ELSE
            lt_location_pf(i):= 4;
            lt_org_id(i)     := ln_organization_id;

            --Assigning Drop Ship Item template for Drop Ship Locations and Merchendising Item Template for Other Locations
            IF lc_location_type='DS' THEN
               lt_template_id(i):=gn_ds_template_id;
            ELSE
               lt_template_id(i):=gn_mer_template_id;
            END IF;
         END IF;  --lcu_location_type%NOTFOUND
         EXIT WHEN lcu_location_type%NOTFOUND;
       END LOOP;--End of lcu_location_type
       CLOSE lcu_location_type;

       IF lt_org_id(i) > 0 THEN

          IF p_process='LC' THEN

             lc_master_status:=GET_MASTER_ITEM_STATUS(p_item => lt_itemlocation(i).item);

             BEGIN
               SELECT od_prod_protect_cd
	           INTO lc_od_prod_prt_cd
	           FROM xx_inv_item_master_attributes
                WHERE inventory_item_id=(select inventory_item_id
						 FROM mtl_system_items_b
						where segment1=lt_itemlocation(i).item
						  and organization_id=gn_master_org_id)
  	            AND organization_id=gn_master_org_id;
  	       EXCEPTION
	         WHEN OTHERS THEN
	           lc_od_prod_prt_cd:=NULL;
             END;

             IF NVL(lc_od_prod_prt_cd,'X') = 'P' THEN
                lt_shippable_item_flag(i) := 'N';
             ELSIF NVL(lc_od_prod_prt_cd,'X') <> 'P' THEN
                lt_shippable_item_flag(i) := 'Y';
             END IF;

            IF    (lc_master_status = 'I' AND lt_itemlocation(i).status IN ('A','D'))
               OR (lc_master_status = 'D' AND lt_itemlocation(i).status='A') THEN

               lt_location_pf(i)   :=  3;
		   lt_error_tbl(i)	  :=lt_error_tbl(i)||', Master Item status in I or D';
 		   lt_errflg_tbl(i)    :='Y';

  	      ELSIF lc_master_status='-989' THEN

               lt_location_pf(i)   :=  3;
	   	   lt_error_tbl(i)	  :=lt_error_tbl(i)||', Unable to get Master Item status';
 	 	   lt_errflg_tbl(i)    :='Y';

  	      END IF;

  	      BEGIN

  	       SELECT inventory_item_status_code,shippable_item_flag,inventory_item_id
 	         INTO lc_loc_status,lc_ship_flag,ln_item_id
      	   FROM mtl_system_items_b
	        WHERE segment1=lt_itemlocation(i).item
		    AND organization_id=lt_org_id(i);

	      IF (lc_loc_status||lc_ship_flag)<>(lt_itemlocation(i).status||lt_shippable_item_flag(i)) THEN
	  	   lt_call_tbl(i):='Y';
            ELSE
		   lt_call_tbl(i):='N';
	      END IF;

 	      EXCEPTION
	       WHEN OTHERS THEN
              lt_location_pf(i)   :=  3;
		  lt_error_tbl(i)	  :=lt_error_tbl(i)||', Item/loc does not exists in EBS to change';
            END;

          END IF;	-- p_process='LC'
       END IF;	-- lt_org_id(i)>0

     END LOOP;--End of lt_itemlocation.COUNT loop

     --------------------------------------------------------
     -- Bulk Update XX_INV_ITEM_LOC_INT with Process flag and Ids
     --------------------------------------------------------
     IF p_process='LA' THEN
        FORALL i IN 1..lt_itemlocation.LAST
        UPDATE XX_INV_ITEM_LOC_INT XSIL
        SET    XSIL.location_process_flag   =   lt_location_pf(i)
              ,XSIL.load_batch_id           =   p_batch_id
              ,XSIL.template_id             =   lt_template_id(i)
              ,XSIL.organization_id         =   lt_org_id(i)
	        ,XSIL.error_message	        =   lt_error_tbl(i)
		  ,XSIL.error_Flag		  =	lt_errflg_tbl(i)
        WHERE  XSIL.ROWID                   =   lt_location_row_id(i);
        COMMIT;
     ELSE
        FORALL i IN 1..lt_itemlocation.LAST
        UPDATE XX_INV_ITEM_LOC_INT XSIL
        SET    XSIL.location_process_flag   =   lt_location_pf(i)
              ,XSIL.load_batch_id           =   p_batch_id
              ,XSIL.template_id             =   lt_template_id(i)
              ,XSIL.organization_id         =   lt_org_id(i)
	        ,XSIL.shippable_item_flag     =   lt_shippable_item_flag(i)
	        ,XSIL.api_change		  =   lt_call_tbl(i)
   	        ,XSIL.error_message	        =   lt_error_tbl(i)
		  ,XSIL.error_Flag		  =	lt_errflg_tbl(i)
        WHERE  XSIL.ROWID                   =   lt_location_row_id(i);
        COMMIT;
     END IF;
  ELSE		--IF lt_itemlocation.COUNT <> 0 THEN
    RAISE EX_LOCATION_NO_DATA;
  END IF;   -- lt_itemlocation.COUNT <> 0 THEN
EXCEPTION
WHEN EX_LOCATION_NO_DATA THEN
    x_retcode := 1;
    x_errbuf  := 'No data found in the staging table XX_INV_ITEM_LOC_INT with batch_id - '||p_batch_id;
WHEN OTHERS THEN
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in validate_loc_data - '||gc_sqlerrm;
    x_retcode := 2;
END validate_loc_data;

-- +===================================================================+
-- | Name        :  insert_item_attributes                             |
-- | Description :  This procedure is invoked from the child_main  s   |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                p_process                                          |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE insert_item_attributes(x_errbuf    OUT NOCOPY VARCHAR2
                                ,x_retcode   OUT NOCOPY VARCHAR2
					  ,p_process    IN VARCHAR2
                                ,p_batch_id   IN  NUMBER)
IS

CURSOR c_upd_master_attr IS
SELECT *
  FROM XX_INV_ITEM_MASTER_INT
 WHERE load_batch_id=p_batch_id;

CURSOR c_upd_loc_attr IS
SELECT *
  FROM XX_INV_ITEM_LOC_INT
 WHERE load_batch_id=p_batch_id;

BEGIN
  -------------------------------
  --Bulk Insert Master Attributes
  -------------------------------


  IF p_process='MA' THEN
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
                                               ,store_ord_mult
                                               ,last_update_date
                                               ,last_update_login
                                               ,last_updated_by
                                               ,creation_date
                                               ,created_by
					       ,rms_timestamp
					       ,od_srvc_type_cd
                                              )
                                        SELECT   XIMS.inventory_item_id
                                                ,XIMS.organization_id
                                                ,XIMS.order_as_type
                                                ,XIMS.pack_ind
                                                ,XIMS.pack_type
                                                ,XIMS.package_size
                                                ,XIMS.ship_alone_ind
                                                ,XIMS.handling_sensitivity
                                                ,XIMS.od_meta_cd
                                                ,XIMS.od_ovrsize_delvry_flg
                                                ,XIMS.od_prod_protect_cd
                                                ,XIMS.od_gift_certif_flg
                                                ,XIMS.od_imprinted_item_flg
                                                ,XIMS.od_recycle_flg
                                                ,XIMS.od_ready_to_assemble_flg
                                                ,XIMS.od_private_brand_flg
                                                ,XIMS.od_gsa_flg
                                                ,XIMS.od_hub_flag
                                                ,XIMS.od_call_for_price_cd
                                                ,XIMS.od_cost_up_flg
                                                ,XIMS.item
                                                ,XIMS.subsell_master_qty
                                                ,XIMS.simple_pack_ind
                                                ,XIMS.od_sell_restrict_cd
                                                ,XIMS.od_list_off_flg
                                                ,XIMS.od_assortment_cd
                                                ,XIMS.od_off_cat_flg
                                                ,XIMS.od_retail_pricing_flg
                                                ,XIMS.od_coupon_disc_flg
                                                ,XIMS.od_sku_type_cd
                                                ,XIMS.item_number_type
                                                ,XIMS.short_desc
                                                ,XIMS.store_ord_mult
                                                ,SYSDATE
                                                ,g_user_id
                                                ,g_user_id
                                                ,SYSDATE
                                                ,g_user_id
						,XIMS.rms_timestamp
						,XIMS.od_srvc_type_cd
                                        FROM     XX_INV_ITEM_MASTER_INT XIMS
                                        WHERE    XIMS.item_process_flag             = 7
                                        AND      XIMS.master_item_attr_process_flag IN (1,6)
                                        AND      XIMS.load_batch_id                 = p_batch_id;
       COMMIT;

       UPDATE XX_INV_ITEM_MASTER_INT XIMS
       SET    XIMS.master_item_attr_process_flag = 7
       WHERE  XIMS.load_batch_id                 = p_batch_id
       AND    XIMS.master_item_attr_process_flag IN (1,6)
       AND    XIMS.item_process_flag             = 7;
       COMMIT;
     EXCEPTION
        WHEN OTHERS THEN
          gc_sqlerrm := SQLERRM;
          gc_sqlcode := SQLCODE;
          x_errbuf  := 'Unexpected error in insert_item_attributes - '||gc_sqlerrm;
          x_retcode := 2;

        UPDATE XX_INV_ITEM_MASTER_INT XIMS
        SET    XIMS.master_item_attr_process_flag = 6
        WHERE  XIMS.load_batch_id                 = p_batch_id
        AND    XIMS.master_item_attr_process_flag = 1
        AND    XIMS.item_process_flag             = 7;
        COMMIT;
     END;
  ELSIF p_process='LA' THEN
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
                                          ,last_update_date
                                          ,last_update_login
                                          ,last_updated_by
                                          ,creation_date
                                          ,created_by
							,rms_timestamp
                                         )
                                   SELECT   XILS.inventory_item_id
                                           ,XILS.organization_id
                                           ,XILS.od_dist_target
                                           ,XILS.od_ebw_qty
                                           ,XILS.od_infinite_qty_cd
                                           ,XILS.od_lock_up_item_flg
                                           ,XILS.od_proprietary_type_cd
                                           ,XILS.od_replen_sub_type_cd
                                           ,XILS.od_replen_type_cd
                                           ,XILS.od_whse_item_cd
                                           ,XILS.od_abc_class
                                           ,XILS.local_item_desc
                                           ,XILS.local_short_desc
                                           ,XILS.primary_supp
                                           ,XILS.od_channel_block
                                           ,SYSDATE
                                           ,g_user_id
                                           ,g_user_id
                                           ,SYSDATE
                                           ,g_user_id
							 ,XILS.rms_timestamp
                                   FROM     XX_INV_ITEM_LOC_INT XILS
                                   WHERE    XILS.location_process_flag      = 7
                                   AND      XILS.loc_item_attr_process_flag IN (1,6)
                                   AND      XILS.load_batch_id              = p_batch_id;
       COMMIT;
        UPDATE XX_INV_ITEM_LOC_INT XILS
        SET    XILS.loc_item_attr_process_flag = 7
        WHERE  XILS.load_batch_id              = p_batch_id
        AND    XILS.loc_item_attr_process_flag IN (1,6)
        AND    XILS.location_process_flag      = 7;
        COMMIT;
     EXCEPTION
       WHEN OTHERS THEN
         gc_sqlerrm := SQLERRM;
         gc_sqlcode := SQLCODE;
         x_errbuf  := 'Unexpected error in insert_item_attributes - '||gc_sqlerrm;
         x_retcode := 2;
         UPDATE XX_INV_ITEM_LOC_INT XILS
         SET    XILS.loc_item_attr_process_flag = 6
         WHERE  XILS.load_batch_id              = p_batch_id
         AND    XILS.loc_item_attr_process_flag = 1
         AND    XILS.location_process_flag      = 7;
         COMMIT;
     END;

  ELSIF p_process='MC' THEN
    FOR cur IN c_upd_master_attr LOOP

      BEGIN
        UPDATE XX_INV_ITEM_MASTER_ATTRIBUTES XIIMA
           SET XIIMA.last_update_date         = SYSDATE
               ,XIIMA.last_updated_by          = FND_GLOBAL.user_id
               ,XIIMA.last_update_login        = FND_GLOBAL.login_id
               ,XIIMA.order_as_type            = cur.order_as_type
               ,XIIMA.pack_ind                 = cur.pack_ind
               ,XIIMA.pack_type                = cur.pack_type
               ,XIIMA.package_size             = cur.package_size
               ,XIIMA.ship_alone_ind           = cur.ship_alone_ind
               ,XIIMA.handling_sensitivity     = cur.handling_sensitivity
               ,XIIMA.od_meta_cd               = cur.od_meta_cd
               ,XIIMA.od_ovrsize_delvry_flg    = cur.od_ovrsize_delvry_flg
               ,XIIMA.od_prod_protect_cd       = cur.od_prod_protect_cd
               ,XIIMA.od_gift_certif_flg       = cur.od_gift_certif_flg
               ,XIIMA.od_imprinted_item_flg    = cur.od_imprinted_item_flg
               ,XIIMA.od_recycle_flg           = cur.od_recycle_flg
               ,XIIMA.od_ready_to_assemble_flg = cur.od_ready_to_assemble_flg
               ,XIIMA.od_private_brand_flg     = cur.od_private_brand_flg
               ,XIIMA.od_gsa_flg               = cur.od_gsa_flg
               ,XIIMA.od_call_for_price_cd     = cur.od_call_for_price_cd
               ,XIIMA.od_cost_up_flg           = cur.od_cost_up_flg
               ,XIIMA.master_item              = cur.master_item
               ,XIIMA.subsell_master_qty       = cur.subsell_master_qty
               ,XIIMA.simple_pack_ind          = cur.simple_pack_ind
               ,XIIMA.od_list_off_flg          = cur.od_list_off_flg
               ,XIIMA.od_assortment_cd         = cur.od_assortment_cd
               ,XIIMA.od_off_cat_flg           = cur.od_off_cat_flg
               ,XIIMA.od_retail_pricing_flg    = cur.od_retail_pricing_flg
               ,XIIMA.item_number_type         = cur.item_number_type
               ,XIIMA.short_desc               = cur.short_desc
               ,XIIMA.od_hub_flag              = cur.od_hub_flag
               ,XIIMA.od_sell_restrict_cd      = cur.od_sell_restrict_cd
               ,XIIMA.od_coupon_disc_flg       = cur.od_coupon_disc_flg
               ,XIIMA.od_sku_type_cd           = cur.od_sku_type_cd
               ,XIIMA.store_ord_mult           = cur.store_ord_mult
               ,XIIMA.rms_timestamp            = cur.rms_timestamp
	       ,XIIMA.od_srvc_type_cd	       = cur.od_srvc_type_cd
         WHERE XIIMA.inventory_item_id         = cur.inventory_item_id
           AND XIIMA.organization_id           = gn_master_org_id;
      EXCEPTION
        WHEN OTHERS THEN
          UPDATE XX_INV_ITEM_MASTER_INT
	       SET master_item_attr_process_flag=6
           WHERE inventory_item_id=cur.inventory_item_id
             AND load_batch_id=cur.load_batch_id;
      END;
    END LOOP;
  ELSIF p_process='LC' THEN
    FOR cur IN c_upd_loc_attr LOOP
      BEGIN
        UPDATE XX_INV_ITEM_ORG_ATTRIBUTES XIIOA
           SET XIIOA.last_update_date         = SYSDATE
              ,XIIOA.last_updated_by          = FND_GLOBAL.user_id
              ,XIIOA.last_update_login        = FND_GLOBAL.login_id
              ,XIIOA.od_dist_target           = cur.od_dist_target
              ,XIIOA.od_ebw_qty               = cur.od_ebw_qty
              ,XIIOA.od_infinite_qty_cd       = cur.od_infinite_qty_cd
              ,XIIOA.od_lock_up_item_flg      = cur.od_lock_up_item_flg
              ,XIIOA.od_proprietary_type_cd   = cur.od_proprietary_type_cd
              ,XIIOA.od_replen_sub_type_cd    = cur.od_replen_sub_type_cd
              ,XIIOA.od_replen_type_cd        = cur.od_replen_type_cd
              ,XIIOA.od_whse_item_cd          = cur.od_whse_item_cd
              ,XIIOA.od_abc_class             = cur.od_abc_class
              ,XIIOA.local_item_desc          = cur.local_item_desc
              ,XIIOA.local_short_desc         = cur.local_short_desc
              ,XIIOA.primary_supp             = cur.primary_supp
              ,XIIOA.od_channel_block         = cur.od_channel_block
              ,XIIOA.rms_timestamp            = cur.rms_timestamp
        WHERE XIIOA.inventory_item_id      = cur.inventory_item_id
          AND XIIOA.organization_id        = cur.organization_id;
      EXCEPTION
        WHEN OTHERS THEN
          UPDATE XX_INV_ITEM_LOC_INT
	       SET loc_item_attr_process_flag=6
           WHERE inventory_item_id=cur.inventory_item_id
		 AND organization_id=cur.organization_id
             AND load_batch_id=cur.load_batch_id;
      END;
    END LOOP;
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in insert_item_attributes - '||gc_sqlerrm;
    x_retcode := 2;
END insert_item_attributes;

-- +===================================================================+
-- | Name        :  process_item_data                                  |
-- | Description :  This procedure is invoked from the child_main      |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- | 		        p_process                                          |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- +===================================================================+
PROCEDURE process_item_data(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
				    ,p_process     IN  VARCHAR2
                            ,p_batch_id    IN  NUMBER
                           )
IS
---------------------------
--Declaring Local Variables
---------------------------
lc_err_text          VARCHAR2(5000);
ln_return_code       PLS_INTEGER;
ln_del_rec_flag      PLS_INTEGER:=0;
ln_val_cnt		   PLS_INTEGER:=0;

-------------------------------------------------------------
--Cursor to fetch Inventory Item ids for success item records
-------------------------------------------------------------
CURSOR lcu_success_item_ids(p_batch_id IN NUMBER)
IS
SELECT MSIB.inventory_item_id
      ,XSIM.ROWID
FROM   mtl_system_items_b  MSIB
	,XX_INV_ITEM_MASTER_INT XSIM
WHERE  XSIM.load_batch_id       =   p_batch_id
AND    XSIM.item_process_flag   =   4
AND    MSIB.segment1            =   XSIM.item
AND    MSIB.organization_id     =   XSIM.organization_id;

-----------------------------------------------------------------
--Cursor to fetch Inventory Item ids for success location records
-----------------------------------------------------------------
CURSOR lcu_success_locations_itemids(p_batch_id IN NUMBER)
IS
SELECT MSIB.inventory_item_id
      ,XSIL.ROWID
FROM   mtl_system_items_b MSIB
      ,XX_INV_ITEM_LOC_INT XSIL
WHERE  XSIL.load_batch_id           =   p_batch_id
AND    XSIL.location_process_flag   =   4
AND    MSIB.segment1                =   XSIL.item
AND    MSIB.organization_id         =   XSIL.organization_id;


--------------------------------------------------
--Cursor to fetch Item and Category Error messages
--------------------------------------------------
CURSOR lcu_item_error(p_batch_id IN NUMBER)
IS
SELECT 'MSII:'||MIE.error_message
      ,XSIM.control_id
      ,XSIM.ROWID
FROM   mtl_system_items_interface MSII
      ,mtl_interface_errors MIE
      ,XX_INV_ITEM_MASTER_INT XSIM
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
      ,XX_INV_ITEM_MASTER_INT XSIM
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
      ,XX_INV_ITEM_MASTER_INT XSIM
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
      ,XX_INV_ITEM_LOC_INT XSIL
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
      ,XX_INV_ITEM_LOC_INT XSIL
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
      ,XX_INV_ITEM_LOC_INT XSIL
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

---------------------------------------------------------------------------
--Cursor to fetch validation orgs that are either partially or fully failed
---------------------------------------------------------------------------

CURSOR c_val_org(p_batch_id IN NUMBER)
IS
SELECT  item
	 ,inventory_item_id
	 ,rowid drowid
  FROM XX_INV_ITEM_MASTER_INT
 WHERE load_batch_id               = p_batch_id
   AND item_process_flag=7;

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

TYPE item_cat_errorid_type IS TABLE OF XX_INV_ITEM_MASTER_INT.control_id%TYPE
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

TYPE loc_errorid_type IS TABLE OF XX_INV_ITEM_LOC_INT.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_loc_errorid loc_errorid_type;
--Added by Arun Andavar in ver 1.3 START
TYPE rowid_valid_orgs_stg_tbl_type IS TABLE OF ROWID;
lt_row_id rowid_valid_orgs_stg_tbl_type;

TYPE item_number_tbl_type IS TABLE OF mtl_system_items_interface.segment1%TYPE
INDEX BY BINARY_INTEGER;
lt_item_number item_number_tbl_type;

TYPE valid_orgs_status_tbl_type IS TABLE OF VARCHAR2(1)
INDEX BY BINARY_INTEGER;
lt_val_org_status_flag valid_orgs_status_tbl_type;

TYPE val_org_msii_prcs_flg_tbl_type IS TABLE OF VARCHAR2(1)
INDEX BY BINARY_INTEGER;
lt_val_org_process_flag val_org_msii_prcs_flg_tbl_type;
--Added by Arun Andavar in ver 1.3 END

BEGIN

---------------------------------------------------------------------------------
--Inserting Success items into MTL_SYSTEM_ITEMS_INTERFACE for Master Organization
---------------------------------------------------------------------------------
IF  gc_master_setup_status='Y' THEN
    IF p_process='MA' THEN
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
--	   ,attribute5
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
--	    ,XSIM.package_uom
    FROM   XX_INV_ITEM_MASTER_INT XSIM
    WHERE  XSIM.load_batch_id = p_batch_id
    AND    XSIM.item_process_flag IN (4,5,6)
    AND    XSIM.action_type='A';

    --------------------------------------------------------------------------------------
    --Inserting Success items into MTL_SYSTEM_ITEMS_INTERFACE for Validation Organizations
    --------------------------------------------------------------------------------------
    IF  gc_valorg_setup_status='Y' THEN
        FOR i IN 1..gt_val_orgs.LAST
        LOOP
            BEGIN
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
--			     ,attribute5
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
--			     ,XSIM.package_uom
                FROM    XX_INV_ITEM_MASTER_INT XSIM
                WHERE   XSIM.load_batch_id = p_batch_id
                AND     XSIM.item_process_flag IN (4,5,6,7)
                AND     XSIM.validation_orgs_status_flag IN ('N','F')
		    AND     XSIM.action_type='A';
            END;
            BEGIN
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
--			     ,attribute5
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
--			     ,XSIM.package_uom
                FROM    XX_INV_ITEM_MASTER_INT XSIM
                WHERE   XSIM.load_batch_id               = p_batch_id
                AND     XSIM.item_process_flag IN (4,5,6,7)
                AND     XSIM.validation_orgs_status_flag = 'P'
		    AND     XSIM.action_type='A'
                AND NOT EXISTS
                           (
                            SELECT  1
                            FROM    mtl_system_items_b MSIB
                            WHERE   MSIB.organization_id = gt_val_orgs(i)
                            AND     MSIB.inventory_item_id = XSIM.inventory_item_id
                           );
            END;
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
    FROM   XX_INV_ITEM_MASTER_INT XSIM
    WHERE  XSIM.load_batch_id = p_batch_id
    AND    XSIM.item_process_flag          IN (4,5,6,7)
    AND    XSIM.inv_category_process_flag  IN (4,5,6)
    AND    XSIM.action_type='A'
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
    FROM   XX_INV_ITEM_MASTER_INT XSIM
    WHERE  XSIM.load_batch_id = p_batch_id
    AND    XSIM.item_process_flag          IN (4,5,6,7)
    AND    XSIM.odpb_category_process_flag IN (4,5,6)
    AND    XSIM.action_type='A'
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
    FROM   XX_INV_ITEM_MASTER_INT XSIM
    WHERE  XSIM.load_batch_id = p_batch_id
    AND    XSIM.item_process_flag          IN (4,5,6,7)
    AND    XSIM.po_category_process_flag   IN (4,5,6)
    AND    XSIM.action_type='A'
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
    FROM   XX_INV_ITEM_MASTER_INT XSIM
    WHERE  XSIM.load_batch_id = p_batch_id
    AND    XSIM.item_process_flag          IN (4,5,6,7)
    AND    XSIM.atp_category_process_flag  IN (4,5,6)
    AND    XSIM.action_type='A';

    ELSIF p_process='LA' THEN

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
		,item_type
		,purchasing_item_flag
		,customer_order_flag
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
           ,MSI.description
           ,MSI.primary_uom_code
           ,XSIL.organization_id
           ,XSIL.template_id
           ,XSIL.status
	     ,MSI.item_type
	     ,MSI.purchasing_item_flag
	     ,MSI.customer_order_flag
           ,G_PROCESS_FLAG
           ,p_batch_id
           ,G_TRANSACTION_TYPE
           ,'Y'
           ,G_DATE
           ,G_USER_ID
           ,G_DATE
           ,G_USER_ID
           ,G_USER_ID
   FROM     mtl_system_items_b msi
	     ,XX_INV_ITEM_LOC_INT XSIL
   WHERE    XSIL.load_batch_id          = p_batch_id
   AND      XSIL.action_type='A'
   AND      XSIL.location_process_flag  IN (4,5,6)
   AND      msi.organization_id=gn_master_org_id
   AND      msi.segment1=XSIL.item;
   END IF;
   COMMIT;

   ln_del_rec_flag:=1;

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'BEFORE API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
   FND_FILE.PUT_LINE(FND_FILE.LOG,'BEFORE API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

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

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AFTER API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'AFTER API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

    ---------------------------------------------------------------------
    --Logging error details for failed Items Corresponding to Master Orgs
    ---------------------------------------------------------------------

    IF p_process='MA' THEN

    OPEN lcu_item_error(p_batch_id);
    LOOP
        FETCH lcu_item_error BULK COLLECT INTO lt_item_cat_error,lt_item_cat_errorid,lt_rowid_failure LIMIT G_LIMIT_SIZE;
        IF lt_item_cat_errorid.COUNT > 0 THEN
            ----------------------------------------------
            --Updating Item Process Flags for Failed Items
            ----------------------------------------------
            FORALL i IN 1 .. lt_item_cat_errorid.LAST
            UPDATE XX_INV_ITEM_MASTER_INT XSIM
            SET    XSIM.item_process_flag = 6
		      ,XSIM.process_flag=7
			,XSIM.error_flag='Y'
		      ,XSIM.error_message=XSIM.error_message||' ,'||lt_item_cat_error(i)
            WHERE  XSIM.ROWID             = lt_rowid_failure(i);
        END IF;
        EXIT WHEN lcu_item_error%NOTFOUND;
    END LOOP;
    CLOSE lcu_item_error;
    COMMIT;

    ----------------------------------------------------------------------
    --Updating Item Process Flags and Inventory Item Ids for Success Items
    ----------------------------------------------------------------------
    OPEN  lcu_success_item_ids(p_batch_id);
    FETCH lcu_success_item_ids BULK COLLECT INTO lt_itemid_success,lt_rowid_success;
    CLOSE lcu_success_item_ids;

    IF lt_itemid_success.COUNT > 0 THEN
       FORALL i IN 1 .. lt_itemid_success.LAST
       UPDATE XX_INV_ITEM_MASTER_INT XSIM
       SET    XSIM.item_process_flag = 7
		 ,XSIM.process_Flag=7
             ,XSIM.inventory_item_id = lt_itemid_success(i)
       WHERE  XSIM.ROWID             = lt_rowid_success(i);
    END IF;
    COMMIT;
    ------------------------------------------------------------------------
    --Updating Inventory Category Process Flags for Success Category records
    ------------------------------------------------------------------------
    UPDATE XX_INV_ITEM_MASTER_INT XSIM
    SET    XSIM.inv_category_process_flag=7
	    ,XSIM.process_Flag=7
    WHERE  EXISTS (
                   SELECT 1
                   FROM   mtl_item_categories MIC
                         ,mtl_system_items_b MSIB
                   WHERE  MSIB.inventory_item_id           =   MIC.inventory_item_id
                   AND    MSIB.organization_id             =   MIC.organization_id
                   AND    MSIB.inventory_item_id           =   XSIM.inventory_item_id
                   AND    MIC.organization_id              =   XSIM.organization_id
                   AND    XSIM.inv_category_id             =   MIC.category_id
                   AND    MIC.category_set_id              =   gn_inv_category_set_id
                  )
    AND    XSIM.inv_category_process_flag   IN  (4,5,6)
    AND    XSIM.load_batch_id               =   p_batch_id
    AND    XSIM.item_process_flag=7;
    COMMIT;
    -------------------------------------------------------------------
    --Updating ODPB Category Process Flags for Success Category records
    -------------------------------------------------------------------
    UPDATE XX_INV_ITEM_MASTER_INT XSIM
    SET    XSIM.odpb_category_process_flag=7
	    ,XSIM.process_Flag=7
    WHERE  EXISTS (
                   SELECT 1
                   FROM   mtl_item_categories MIC
                         ,mtl_system_items_b MSIB
                   WHERE  MSIB.inventory_item_id           =   MIC.inventory_item_id
                   AND    MSIB.organization_id             =   MIC.organization_id
                   AND    MSIB.inventory_item_id           =   XSIM.inventory_item_id
                   AND    MIC.organization_id              =   XSIM.organization_id
                   AND    XSIM.odpb_category_id            =   MIC.category_id
                   AND    MIC.category_set_id              =   gn_odpb_category_set_id
                  )
    AND    XSIM.odpb_category_process_flag   IN  (4,5,6)
    AND    XSIM.load_batch_id               =   p_batch_id
    AND    XSIM.item_process_flag=7;
    COMMIT;
    -----------------------------------------------------------------
    --Updating PO Category Process Flags for Success Category records
    -----------------------------------------------------------------
    UPDATE XX_INV_ITEM_MASTER_INT XSIM
    SET    XSIM.po_category_process_flag=7
	    ,XSIM.process_Flag=7
    WHERE  EXISTS (
                   SELECT 1
                   FROM   mtl_item_categories MIC
                         ,mtl_system_items_b MSIB
                   WHERE  MSIB.inventory_item_id           =   MIC.inventory_item_id
                   AND    MSIB.organization_id             =   MIC.organization_id
                   AND    MSIB.inventory_item_id           =   XSIM.inventory_item_id
                   AND    MIC.organization_id              =   XSIM.organization_id
                   AND    XSIM.po_category_id              =   MIC.category_id
                   AND    MIC.category_set_id              =   gn_po_category_set_id
                  )
    AND    XSIM.po_category_process_flag   IN  (4,5,6)
    AND    XSIM.load_batch_id               =   p_batch_id
    AND    XSIM.item_process_flag=7;
    COMMIT;

    ------------------------------------------------------------------
    --Updating ATP Category Process Flags for Success Category records
    ------------------------------------------------------------------
    UPDATE XX_INV_ITEM_MASTER_INT XSIM
    SET    XSIM.atp_category_process_flag=7
	    ,XSIM.process_Flag=7
    WHERE  EXISTS (
                   SELECT 1
                   FROM   mtl_item_categories MIC
                         ,mtl_system_items_b MSIB
                   WHERE  MSIB.inventory_item_id           =   MIC.inventory_item_id
                   AND    MSIB.organization_id             =   MIC.organization_id
                   AND    MSIB.inventory_item_id           =   XSIM.inventory_item_id
                   AND    MIC.organization_id              =   XSIM.organization_id
                   AND    XSIM.atp_category_id             =   MIC.category_id
                   AND    MIC.category_set_id              =   gn_atp_category_set_id
                  )
    AND    XSIM.atp_category_process_flag   IN  (4,5,6)
    AND    XSIM.load_batch_id               =   p_batch_id
    AND    XSIM.item_process_flag=7;
    COMMIT;

    ------------------------------------------------------------------------
    --Updating Inventory Category Process Flags for Failure Category records
    ------------------------------------------------------------------------
    UPDATE XX_INV_ITEM_MASTER_INT XSIM
    SET    XSIM.inv_category_process_flag   =   6
	    ,XSIM.process_Flag=7
	    ,XSIM.error_Flag='Y'
    WHERE  XSIM.inv_category_process_flag   IN (4,5)
    AND    XSIM.load_batch_id               =   p_batch_id;
    COMMIT;
    -------------------------------------------------------------------
    --Updating ODPB Category Process Flags for Failure Category records
    -------------------------------------------------------------------
    UPDATE XX_INV_ITEM_MASTER_INT XSIM
    SET    XSIM.odpb_category_process_flag  =  6
	    ,XSIM.process_Flag=7
	    ,XSIM.error_Flag='Y'
    WHERE  XSIM.odpb_category_process_flag  IN (4,5)
    AND    XSIM.load_batch_id               =  p_batch_id;
    COMMIT;
    -----------------------------------------------------------------
    --Updating PO Category Process Flags for Failure Category records
    -----------------------------------------------------------------
    UPDATE XX_INV_ITEM_MASTER_INT XSIM
    SET    XSIM.po_category_process_flag    =  6
	    ,XSIM.process_Flag=7
	    ,XSIM.error_Flag='Y'
    WHERE  XSIM.po_category_process_flag    IN (4,5)
    AND    XSIM.load_batch_id               =  p_batch_id;
    COMMIT;
    ------------------------------------------------------------------
    --Updating ATP Category Process Flags for Failure Category records
    ------------------------------------------------------------------
    UPDATE XX_INV_ITEM_MASTER_INT XSIM
    SET    XSIM.atp_category_process_flag    =  6
	    ,XSIM.process_Flag=7
	    ,XSIM.error_Flag='Y'
    WHERE  XSIM.atp_category_process_flag    IN (4,5)
    AND    XSIM.load_batch_id               =  p_batch_id;
    COMMIT;
    ELSIF p_process='LA' THEN
    --------------------------------------------
    --Logging error details for failed locations
    --------------------------------------------
    OPEN lcu_loc_error(p_batch_id);
    LOOP
        FETCH lcu_loc_error BULK COLLECT INTO lt_loc_error,lt_loc_errorid,lt_locationrowid_failure LIMIT G_LIMIT_SIZE;
        IF  lt_loc_errorid.COUNT>0 THEN
            -----------------------------------------------------
            --Updating Location Process Flag for Failed Locations
            -----------------------------------------------------
           FORALL i IN 1 .. lt_loc_errorid.LAST
           UPDATE XX_INV_ITEM_LOC_INT XSIL
           SET    XSIL.location_process_flag= 6
		     ,XSIL.process_flag=7
		     ,XSIL.error_flag='Y'
		     ,XSIL.error_message=XSIL.error_message||' ,'||lt_loc_error(i)
           WHERE  XSIL.ROWID           = lt_locationrowid_failure(i);
        END IF;
        EXIT WHEN lcu_loc_error%NOTFOUND;
    END LOOP;
    CLOSE lcu_loc_error;
    COMMIT;

    UPDATE XX_INV_ITEM_LOC_INT
       SET process_flag=7
     WHERE load_batch_id=p_batch_id
       AND location_process_flag<>7
       AND process_flag=1;
    COMMIT;
    -------------------------------------------------------
    --Updating Location Process Flags for Success Locations
    -------------------------------------------------------
    OPEN lcu_success_locations_itemids(p_batch_id);
    LOOP
        FETCH lcu_success_locations_itemids BULK COLLECT INTO lt_locationid_success,lt_locationrowid_success LIMIT G_LIMIT_SIZE;
        IF lt_locationid_success.COUNT>0 THEN
           FORALL i IN 1 .. lt_locationid_success.LAST
           UPDATE XX_INV_ITEM_LOC_INT XSIL
           SET    XSIL.location_process_flag= 7
		     ,XSIL.process_flag=7
                 ,XSIL.inventory_item_id    = lt_locationid_success(i)
           WHERE  XSIL.ROWID                = lt_locationrowid_success(i);
        END IF;
        COMMIT;
        EXIT WHEN lcu_success_locations_itemids%NOTFOUND;
    END LOOP;
    CLOSE lcu_success_locations_itemids;
    COMMIT;
   END IF;

   IF p_process='MA' THEN
    ----------------------------------------------------------------------------------
    --Updating validation orgs status flag for Success, Fully failed, Partially failed
    ----------------------------------------------------------------------------------
    FOR cur IN c_val_org(p_batch_id) LOOP
        SELECT COUNT(1)
	    INTO ln_val_cnt
	    FROM mtl_system_items_b
	   WHERE inventory_item_id=cur.inventory_item_id
	     AND organization_id IN ( SELECT  HOU.organization_id
                                  FROM    hr_organization_units HOU
                                  WHERE   HOU.type        = 'VAL'
                                  AND     SYSDATE BETWEEN NVL(HOU.date_from,SYSDATE-1)
                                  AND     NVL(HOU.date_to,SYSDATE+1)
                                  );
	  IF ln_val_cnt=gn_val_org_count THEN
	     UPDATE XX_INV_ITEM_MASTER_INT
		  SET  validation_orgs_status_flag='S'
			,process_flag=7
            WHERE rowid=cur.drowid;
        ELSIF ln_val_cnt=1 THEN
	     UPDATE XX_INV_ITEM_MASTER_INT
		  SET  validation_orgs_status_flag='P'
			,process_flag=7
			,error_message=error_message||' Validation Org Assignment Partially Failed'
			,error_flag='Y'
            WHERE rowid=cur.drowid;
        ELSIF ln_val_cnt=0 THEN
	     UPDATE XX_INV_ITEM_MASTER_INT
		  SET  validation_orgs_status_flag='F'
			,process_flag=7
			,error_message=error_message||' Validation Org Assignment Failed'
			,error_flag='Y'
            WHERE rowid=cur.drowid;
        END IF;
    END LOOP;
    COMMIT;
   END IF;
END IF;--gc_master_setup_status='Y'
EXCEPTION
WHEN OTHERS THEN
    IF lcu_item_error%ISOPEN THEN
        CLOSE lcu_item_error;
    END IF;
    IF lcu_loc_error%ISOPEN THEN
        CLOSE lcu_loc_error;
    END IF;
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in process_item_data - '||gc_sqlerrm;
    x_retcode := 2;
END process_item_data;

-- +===================================================================+
-- | Name        :  process_master_upd                                 |
-- | Description :  This procedure is invoked from the child_main      |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- +===================================================================+

PROCEDURE process_master_upd(
                             x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
                            ,p_batch_id    IN  NUMBER
                           )
IS
---------------------------
--Declaring Local Variables
---------------------------
lc_err_text          VARCHAR2(5000);
ln_return_code       PLS_INTEGER;
ln_del_rec_flag      PLS_INTEGER:=0;
ln_cnt		   PLS_INTEGER:=0;
-------------------------------------------------------------
--Cursor to fetch Inventory Item ids for success item records
-------------------------------------------------------------
CURSOR lcu_success_item_ids(p_batch_id IN NUMBER)
IS
SELECT MSIB.inventory_item_id
      ,XSIM.ROWID
FROM   mtl_system_items_b  MSIB
	,XX_INV_ITEM_MASTER_INT XSIM
WHERE  XSIM.load_batch_id       =   p_batch_id
AND    XSIM.item_process_flag IN (4,5,6)
AND    XSIM.action_type='C'
AND    MSIB.organization_id      =   XSIM.organization_id
AND    MSIB.segment1             =   XSIM.item;


CURSOR c_tax_change IS
SELECT  xsim.inventory_item_id,
	  xsim.od_tax_category
  FROM  XX_INV_ITEM_MASTER_INT XSIM
 WHERE XSIM.load_batch_id = p_batch_id
   AND XSIM.action_type='C'
   AND XSIM.tax_change='Y';

--------------------------------------------------
--Cursor to fetch Item and Category Error messages
--------------------------------------------------
CURSOR lcu_item_error(p_batch_id IN NUMBER)
IS
SELECT 'MSII:'||MIE.error_message
      ,XSIM.control_id
      ,XSIM.ROWID
FROM   mtl_system_items_interface MSII
      ,mtl_interface_errors MIE
      ,XX_INV_ITEM_MASTER_INT XSIM
WHERE  MSII.transaction_id    =   MIE.transaction_id
AND    MSII.set_process_id    =   p_batch_id
AND    XSIM.organization_id   =   MSII.organization_id
AND    XSIM.item              =   MSII.segment1
AND    XSIM.load_batch_id     =   p_batch_id
AND    XSIM.item_process_flag IN (4,5,6)
AND    XSIM.action_type='C'
AND    XSIM.api_change='Y'
UNION ALL
SELECT 'MIRI:'||MIE.error_message
      ,XSIM.control_id
      ,XSIM.ROWID
FROM   mtl_interface_errors MIE
      ,XX_INV_ITEM_MASTER_INT XSIM
      ,mtl_system_items_interface MSII
      ,mtl_item_revisions_interface MIRI
WHERE  MIRI.set_process_id    =   p_batch_id
AND    MSII.set_process_id    =   MIRI.set_process_id
AND    MSII.organization_id   =   MIRI.organization_id
AND    MSII.inventory_item_id =   MIRI.inventory_item_id
AND    XSIM.load_batch_id     =   MSII.set_process_id
AND    XSIM.organization_id   =   MSII.organization_id
AND    XSIM.item              =   MSII.segment1
AND    MIE.transaction_id     =   MIRI.transaction_id
AND    XSIM.item_process_flag IN (4,5,6)
AND    XSIM.action_type='C'
AND    XSIM.api_change='Y';

CURSOR lcu_valorg_error(p_batch_id IN NUMBER)
IS
SELECT 'MSII:'||MIE.error_message
      ,XSIM.control_id
      ,XSIM.ROWID
FROM   mtl_system_items_interface MSII
      ,mtl_interface_errors MIE
      ,XX_INV_ITEM_MASTER_INT XSIM
WHERE  MSII.transaction_id    =   MIE.transaction_id
AND    MSII.set_process_id    =   p_batch_id
AND    XSIM.organization_id   =   MSII.organization_id
AND    XSIM.item              =   MSII.segment1
AND    XSIM.load_batch_id     =   p_batch_id;


CURSOR c_cat_change_inv
IS
SELECT  rowid drowid
	 ,inventory_item_id
	 ,inv_category_id
	 ,old_inv_cat_id
  FROM XX_INV_ITEM_MASTER_INT
 WHERE load_batch_id=p_batch_id
   AND inv_category_process_flag  IN (4,5,6)
   AND action_type='C';


CURSOR c_cat_change_po
IS
SELECT  rowid drowid
	 ,inventory_item_id
	 ,po_category_id
	 ,old_po_cat_id
  FROM XX_INV_ITEM_MASTER_INT
 WHERE load_batch_id=p_batch_id
   AND po_category_process_flag  IN (4,5,6)
   AND action_type='C';

CURSOR c_cat_change_odpb
IS
SELECT  rowid drowid
	 ,inventory_item_id
	 ,odpb_category_id
	 ,old_odpb_cat_id
  FROM XX_INV_ITEM_MASTER_INT
 WHERE load_batch_id=p_batch_id
   AND odpb_category_process_flag  IN (4,5,6)
   AND action_type='C';

CURSOR c_cat_change_atp
IS
SELECT  rowid drowid
	 ,inventory_item_id
	 ,atp_category_id
	 ,old_atp_cat_id
  FROM XX_INV_ITEM_MASTER_INT
 WHERE load_batch_id=p_batch_id
   AND atp_category_process_flag  IN (4,5,6)
   AND action_type='C';

CURSOR c_inactive_item
IS
SELECT  item
	 ,inventory_item_id
	 ,status
	 ,rowid drowid
  FROM XX_INV_ITEM_MASTER_INT
 WHERE load_batch_id = p_batch_id
   AND action_type='C'
   AND status IN ('I','D');

CURSOR cur_all_locations(p_item_id mtl_system_items_b.inventory_item_id%TYPE
            		,p_item_status mtl_system_items_b.inventory_item_status_code%TYPE
           			)
IS
-- --------------------------------------------------------------
-- Cursor to fetch all the org id's for the given item except the
--  master org and the one with given item status.
-- --------------------------------------------------------------
SELECT MSIB.organization_id
  FROM MTL_SYSTEM_ITEMS_B MSIB
 WHERE inventory_item_id = p_item_id
   AND organization_id   <> gn_master_org_id
   AND inventory_item_status_code<> p_item_status;

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

TYPE item_cat_errorid_type IS TABLE OF XX_INV_ITEM_MASTER_INT.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_item_cat_errorid item_cat_errorid_type;

TYPE rowid_valid_orgs_stg_tbl_type IS TABLE OF ROWID;
lt_row_id rowid_valid_orgs_stg_tbl_type;

TYPE item_number_tbl_type IS TABLE OF mtl_system_items_interface.segment1%TYPE
INDEX BY BINARY_INTEGER;
lt_item_number item_number_tbl_type;

TYPE error_tbl_type IS TABLE OF XX_INV_ITEM_MASTER_INT.error_message%TYPE
INDEX BY BINARY_INTEGER;
lt_error_tbl  error_tbl_type;

x_return_status       VARCHAR2(1)                := NULL;
ln_errorcode          VARCHAR2(50)               := NULL;
ln_msg_count          NUMBER                     := NULL;
lc_msg_data           VARCHAR2(5000)             := NULL;
lc_msg_data_pub       VARCHAR2(2000)             := NULL;
ln_msg_index_out      NUMBER                     := NULL;
ln_batch_id		    NUMBER;

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
--	   ,attribute5
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
          ,XSIM.source_system_code    -- UOM from mtl_system_items_b
          ,p_batch_id
          ,G_UTRANSACTION_TYPE
          ,'Y'
          ,XSIM.od_tax_category
          ,G_DATE
          ,G_USER_ID
          ,G_DATE
          ,G_USER_ID
          ,G_USER_ID
--	    ,XSIM.package_uom
    FROM   XX_INV_ITEM_MASTER_INT XSIM
    WHERE  XSIM.load_batch_id = p_batch_id
    AND    XSIM.item_process_flag IN (4,5,6)
    AND    XSIM.action_type='C'
    AND    XSIM.api_change='Y';

    FOR i IN 1..gt_val_orgs.LAST
    LOOP
      BEGIN
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
--			     ,attribute5
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
                       ,XSIM.source_system_code   -- Primary_uom from mtl_system_items_b
                       ,p_batch_id
                       ,G_UTRANSACTION_TYPE
                       ,'Y'
                       ,XSIM.od_tax_category
                       ,G_DATE
                       ,G_USER_ID
                       ,G_DATE
                       ,G_USER_ID
                       ,G_USER_ID
--			     ,XSIM.package_uom
		    FROM   XX_INV_ITEM_MASTER_INT XSIM
		    WHERE  XSIM.load_batch_id = p_batch_id
		    AND    XSIM.item_process_flag IN (4,5,6)
		    AND    XSIM.action_type='C'
		    AND    XSIM.api_change='Y'
		    AND    EXISTS ( SELECT 'x'
					    FROM mtl_system_items_b
					   WHERE organization_id=gt_val_orgs(i)
					     AND segment1=XSIM.item
					     AND inventory_item_status_code<>XSIM.status);
	EXCEPTION
	      WHEN OTHERS THEN
	        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,SQLERRM);
      END;
    END LOOP;
    COMMIT;

   ln_del_rec_flag:=1;

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'BEFORE API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
   FND_FILE.PUT_LINE(FND_FILE.LOG,'BEFORE API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

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
                                                               ,run_mode       =>  2
                                                              );
    COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AFTER API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'AFTER API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

    ---------------------------------------------------------------------
    --Logging error details for failed Items Corresponding to Master Orgs
    ---------------------------------------------------------------------

    OPEN lcu_item_error(p_batch_id);
    LOOP
        FETCH lcu_item_error BULK COLLECT INTO lt_item_cat_error,lt_item_cat_errorid,lt_rowid_failure LIMIT G_LIMIT_SIZE;
        IF lt_item_cat_errorid.COUNT > 0 THEN
            ----------------------------------------------
            --Updating Item Process Flags for Failed Items
            ----------------------------------------------
            FORALL i IN 1 .. lt_item_cat_errorid.LAST
            UPDATE XX_INV_ITEM_MASTER_INT XSIM
            SET    XSIM.item_process_flag = 6
			,XSIM.process_flag=7
		      ,XSIM.error_flag='Y'
		      ,XSIM.error_message=XSIM.error_message||' ,'||lt_item_cat_error(i)
            WHERE  XSIM.ROWID             = lt_rowid_failure(i);
        END IF;
        EXIT WHEN lcu_item_error%NOTFOUND;
    END LOOP;
    CLOSE lcu_item_error;
    COMMIT;

    ----------------------------------------------------------------------
    --Updating Item Process Flags and Inventory Item Ids for Success Items
    ----------------------------------------------------------------------

    OPEN  lcu_success_item_ids(p_batch_id);
    FETCH lcu_success_item_ids BULK COLLECT INTO lt_itemid_success,lt_rowid_success;
    CLOSE lcu_success_item_ids;

    IF lt_itemid_success.COUNT > 0 THEN
       FORALL i IN 1 .. lt_itemid_success.LAST
       UPDATE XX_INV_ITEM_MASTER_INT XSIM
       SET    XSIM.item_process_flag = 7
   	       ,XSIM.process_flag=7
             ,XSIM.inventory_item_id = lt_itemid_success(i)
       WHERE  XSIM.ROWID             = lt_rowid_success(i);
    END IF;
    COMMIT;

    FOR cur IN c_tax_change LOOP
	  UPDATE mtl_system_items_b
	     SET  attribute1=cur.od_tax_category
               ,last_update_date=SYSDATE
	         ,last_updated_by=FND_GLOBAL.user_id
         WHERE inventory_item_id=cur.inventory_item_id
  	     AND (organization_id=gn_master_org_id
		    OR
	          organization_id in (SELECT organization_id
				         FROM    HR_ORGANIZATION_UNITS
				         WHERE   type        = 'VAL'
				         AND     SYSDATE BETWEEN NVL(date_from,SYSDATE-1)
                         	   AND NVL(date_to,SYSDATE+1))
		    );
    END LOOP;
    COMMIT;

    FOR cur IN c_cat_change_inv  LOOP
      lt_error_tbl(1):=NULL;
      IF cur.old_inv_cat_id=0 THEN
         INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY_ASSIGNMENT
                     (
                      p_api_version       => 1.0
                     ,p_init_msg_list     => FND_API.G_TRUE
                     ,p_commit            => FND_API.G_FALSE
                     ,x_return_status     => x_return_status
                     ,x_errorcode         => ln_errorcode
                     ,x_msg_count         => ln_msg_count
                     ,x_msg_data          => lc_msg_data
                     ,p_category_id       => cur.inv_category_id
                     ,p_category_set_id   => gn_inv_category_set_id
                     ,p_inventory_item_id => cur.inventory_item_id
                     ,p_organization_id   => gn_master_org_id
                     );
	ELSE
	  IF NVL(cur.inv_category_id,-1)<>NVL(cur.old_inv_cat_id,-1) THEN
	      INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY_ASSIGNMENT
                    (
                      p_api_version       => 1.0
                     ,p_init_msg_list     => FND_API.G_TRUE
                     ,p_commit            => FND_API.G_FALSE
                     ,x_return_status     => x_return_status
                     ,x_errorcode         => ln_errorcode
                     ,x_msg_count         => ln_msg_count
                     ,x_msg_data          => lc_msg_data
                     ,p_old_category_id   => cur.old_inv_cat_id
                     ,p_category_id       => cur.inv_category_id
                     ,p_category_set_id   => gn_inv_category_set_id
                     ,p_inventory_item_id => cur.inventory_item_id
                     ,p_organization_id   => gn_master_org_id
                    );
	  END IF;
      END IF;
      IF (x_return_status <> 'S') THEN
         lc_msg_data_pub  := NULL;
         ln_msg_index_out := NULL;
                     --If more than one errors
         IF (FND_MSG_PUB.COUNT_MSG > 1) THEN
            FOR j IN 1..FND_MSG_PUB.COUNT_MSG LOOP
              FND_MSG_PUB.GET(p_msg_index     => j,
                              p_encoded       => 'F',
                              p_data          => lc_msg_data_pub,
                              p_msg_index_out => ln_msg_index_out
                             );
              lt_error_tbl(1):= lt_error_tbl(1)||', '||lc_msg_data_pub;
            END LOOP;
                     --Only one error
         ELSE
           FND_MSG_PUB.GET(p_msg_index     => 1,
                           p_encoded       => 'F',
                           p_data          => lc_msg_data_pub,
                           p_msg_index_out => ln_msg_index_out
                          );
           lt_error_tbl(1):= lt_error_tbl(1)||', '||lc_msg_data_pub;
         END IF;  -- IF (FND_MSG_PUB.COUNT_MSG > 1)

	   UPDATE XX_INV_ITEM_MASTER_INT
            SET  error_message=error_message||','||lt_error_tbl(1)
		    ,error_flag='Y'
		    ,inv_category_process_flag=6
		    ,process_flag=7
	    WHERE rowid=cur.drowid;
	ELSE
  	   UPDATE XX_INV_ITEM_MASTER_INT
            SET inv_category_process_Flag=7
		    ,process_flag=7
	    WHERE rowid=cur.drowid;
      END IF;     -- IF (x_return_status <> 'S') THEN

    END LOOP;
    COMMIT;

    FOR cur IN c_cat_change_po  LOOP
      lt_error_tbl(1):=NULL;
      IF cur.old_po_cat_id=0 THEN
         INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY_ASSIGNMENT
                     (
                      p_api_version       => 1.0
                     ,p_init_msg_list     => FND_API.G_TRUE
                     ,p_commit            => FND_API.G_FALSE
                     ,x_return_status     => x_return_status
                     ,x_errorcode         => ln_errorcode
                     ,x_msg_count         => ln_msg_count
                     ,x_msg_data          => lc_msg_data
                     ,p_category_id       => cur.po_category_id
                     ,p_category_set_id   => gn_po_category_set_id
                     ,p_inventory_item_id => cur.inventory_item_id
                     ,p_organization_id   => gn_master_org_id
                     );
	ELSE
	  IF NVL(cur.po_category_id,-1)<>NVL(cur.old_po_cat_id,-1) THEN
	     INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY_ASSIGNMENT
                    (
                      p_api_version       => 1.0
                     ,p_init_msg_list     => FND_API.G_TRUE
                     ,p_commit            => FND_API.G_FALSE
                     ,x_return_status     => x_return_status
                     ,x_errorcode         => ln_errorcode
                     ,x_msg_count         => ln_msg_count
                     ,x_msg_data          => lc_msg_data
                     ,p_old_category_id   => cur.old_po_cat_id
                     ,p_category_id       => cur.po_category_id
                     ,p_category_set_id   => gn_po_category_set_id
                     ,p_inventory_item_id => cur.inventory_item_id
                     ,p_organization_id   => gn_master_org_id
                    );
	  END IF;
      END IF;
      IF (x_return_status <> 'S') THEN
         lc_msg_data_pub  := NULL;
         ln_msg_index_out := NULL;
                     --If more than one errors
         IF (FND_MSG_PUB.COUNT_MSG > 1) THEN
            FOR j IN 1..FND_MSG_PUB.COUNT_MSG LOOP
              FND_MSG_PUB.GET(p_msg_index     => j,
                              p_encoded       => 'F',
                              p_data          => lc_msg_data_pub,
                              p_msg_index_out => ln_msg_index_out
                             );
              lt_error_tbl(1):= lt_error_tbl(1)||', '||lc_msg_data_pub;
            END LOOP;
                     --Only one error
         ELSE
           FND_MSG_PUB.GET(p_msg_index     => 1,
                           p_encoded       => 'F',
                           p_data          => lc_msg_data_pub,
                           p_msg_index_out => ln_msg_index_out
                          );
           lt_error_tbl(1):= lt_error_tbl(1)||', '||lc_msg_data_pub;
         END IF;  -- IF (FND_MSG_PUB.COUNT_MSG > 1)

	   UPDATE XX_INV_ITEM_MASTER_INT
            SET error_message=error_message||','||lt_error_tbl(1),
		    error_flag='Y',
		    po_category_process_flag=6
		    ,process_flag=7
	    WHERE rowid=cur.drowid;
	ELSE
  	   UPDATE XX_INV_ITEM_MASTER_INT
            SET po_category_process_Flag=7
		    ,process_flag=7
	    WHERE rowid=cur.drowid;
      END IF;     -- IF (x_return_status <> 'S') THEN
    END LOOP;
    COMMIT;

    FOR cur IN c_cat_change_odpb  LOOP
      lt_error_tbl(1):=NULL;
      IF cur.old_odpb_cat_id=0 THEN
         INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY_ASSIGNMENT
                     (
                      p_api_version       => 1.0
                     ,p_init_msg_list     => FND_API.G_TRUE
                     ,p_commit            => FND_API.G_FALSE
                     ,x_return_status     => x_return_status
                     ,x_errorcode         => ln_errorcode
                     ,x_msg_count         => ln_msg_count
                     ,x_msg_data          => lc_msg_data
                     ,p_category_id       => cur.odpb_category_id
                     ,p_category_set_id   => gn_odpb_category_set_id
                     ,p_inventory_item_id => cur.inventory_item_id
                     ,p_organization_id   => gn_master_org_id
                     );
	ELSE
	  IF NVL(cur.odpb_category_id,-1)<>NVL(cur.old_odpb_cat_id,-1) THEN
           INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY_ASSIGNMENT
                    (
                      p_api_version       => 1.0
                     ,p_init_msg_list     => FND_API.G_TRUE
                     ,p_commit            => FND_API.G_FALSE
                     ,x_return_status     => x_return_status
                     ,x_errorcode         => ln_errorcode
                     ,x_msg_count         => ln_msg_count
                     ,x_msg_data          => lc_msg_data
                     ,p_old_category_id   => cur.old_odpb_cat_id
                     ,p_category_id       => cur.odpb_category_id
                     ,p_category_set_id   => gn_odpb_category_set_id
                     ,p_inventory_item_id => cur.inventory_item_id
                     ,p_organization_id   => gn_master_org_id
                    );
	  END IF;
      END IF;
      IF (x_return_status <> 'S') THEN
         lc_msg_data_pub  := NULL;
         ln_msg_index_out := NULL;
                     --If more than one errors
         IF (FND_MSG_PUB.COUNT_MSG > 1) THEN
            FOR j IN 1..FND_MSG_PUB.COUNT_MSG LOOP
              FND_MSG_PUB.GET(p_msg_index     => j,
                              p_encoded       => 'F',
                              p_data          => lc_msg_data_pub,
                              p_msg_index_out => ln_msg_index_out
                             );
              lt_error_tbl(1):= lt_error_tbl(1)||', '||lc_msg_data_pub;
            END LOOP;
                     --Only one error
         ELSE
           FND_MSG_PUB.GET(p_msg_index     => 1,
                           p_encoded       => 'F',
                           p_data          => lc_msg_data_pub,
                           p_msg_index_out => ln_msg_index_out
                          );
           lt_error_tbl(1):= lt_error_tbl(1)||', '||lc_msg_data_pub;
         END IF;  -- IF (FND_MSG_PUB.COUNT_MSG > 1)

	   UPDATE XX_INV_ITEM_MASTER_INT
            SET error_message=error_message||','||lt_error_tbl(1),
		    error_flag='Y',
		    odpb_category_process_flag=6
		    ,process_flag=7
	    WHERE rowid=cur.drowid;
	ELSE
  	   UPDATE XX_INV_ITEM_MASTER_INT
            SET odpb_category_process_Flag=7
		    ,process_flag=7
	    WHERE rowid=cur.drowid;
      END IF;     -- IF (x_return_status <> 'S') THEN
    END LOOP;
    COMMIT;
    FOR cur IN c_cat_change_atp  LOOP
      lt_error_tbl(1):=NULL;
      IF cur.old_atp_cat_id=0 THEN
         INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY_ASSIGNMENT
                     (
                      p_api_version       => 1.0
                     ,p_init_msg_list     => FND_API.G_TRUE
                     ,p_commit            => FND_API.G_FALSE
                     ,x_return_status     => x_return_status
                     ,x_errorcode         => ln_errorcode
                     ,x_msg_count         => ln_msg_count
                     ,x_msg_data          => lc_msg_data
                     ,p_category_id       => cur.atp_category_id
                     ,p_category_set_id   => gn_atp_category_set_id
                     ,p_inventory_item_id => cur.inventory_item_id
                     ,p_organization_id   => gn_master_org_id
                     );
	ELSE
	  IF NVL(cur.atp_category_id,-1)<>NVL(cur.old_atp_cat_id,-1) THEN
	     INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY_ASSIGNMENT
                    (
                      p_api_version       => 1.0
                     ,p_init_msg_list     => FND_API.G_TRUE
                     ,p_commit            => FND_API.G_FALSE
                     ,x_return_status     => x_return_status
                     ,x_errorcode         => ln_errorcode
                     ,x_msg_count         => ln_msg_count
                     ,x_msg_data          => lc_msg_data
                     ,p_old_category_id   => cur.old_atp_cat_id
                     ,p_category_id       => cur.atp_category_id
                     ,p_category_set_id   => gn_atp_category_set_id
                     ,p_inventory_item_id => cur.inventory_item_id
                     ,p_organization_id   => gn_master_org_id
                    );
	  END IF;
      END IF;
      IF (x_return_status <> 'S') THEN
         lc_msg_data_pub  := NULL;
         ln_msg_index_out := NULL;
                     --If more than one errors
         IF (FND_MSG_PUB.COUNT_MSG > 1) THEN
            FOR j IN 1..FND_MSG_PUB.COUNT_MSG LOOP
              FND_MSG_PUB.GET(p_msg_index     => j,
                              p_encoded       => 'F',
                              p_data          => lc_msg_data_pub,
                              p_msg_index_out => ln_msg_index_out
                             );
              lt_error_tbl(1):= lt_error_tbl(1)||', '||lc_msg_data_pub;
            END LOOP;
                     --Only one error
         ELSE
           FND_MSG_PUB.GET(p_msg_index     => 1,
                           p_encoded       => 'F',
                           p_data          => lc_msg_data_pub,
                           p_msg_index_out => ln_msg_index_out
                          );
           lt_error_tbl(1):= lt_error_tbl(1)||', '||lc_msg_data_pub;
         END IF;  -- IF (FND_MSG_PUB.COUNT_MSG > 1)

	   UPDATE XX_INV_ITEM_MASTER_INT
            SET error_message=error_message||','||lt_error_tbl(1),
		    error_flag='Y',
		    atp_category_process_flag=6
		    ,process_flag=7
	    WHERE rowid=cur.drowid;
	ELSE
  	   UPDATE XX_INV_ITEM_MASTER_INT
            SET atp_category_process_Flag=7
		    ,process_flag=7
	    WHERE rowid=cur.drowid;
      END IF;     -- IF (x_return_status <> 'S') THEN
    END LOOP;
    COMMIT;

    SELECT XX_INV_ITEM_STG_BAT_S.NEXTVAL
	INTO ln_batch_id
      FROM DUAL;

    FOR i IN 1..gt_val_orgs.LAST
    LOOP
      BEGIN
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
--			     ,attribute5
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
                       ,XSIM.source_system_code   -- primary_uom from mtl_system_items_b
                       ,ln_batch_id
                       ,G_TRANSACTION_TYPE
                       ,'Y'
                       ,XSIM.od_tax_category
                       ,G_DATE
                       ,G_USER_ID
                       ,G_DATE
                       ,G_USER_ID
                       ,G_USER_ID
--			     ,XSIM.package_uom
          FROM    XX_INV_ITEM_MASTER_INT XSIM
         WHERE   XSIM.load_batch_id               = p_batch_id
           AND NOT EXISTS
                           (
                            SELECT  1
                            FROM    mtl_system_items_b MSIB
                            WHERE   MSIB.organization_id = gt_val_orgs(i)
                            AND     MSIB.segment1 = XSIM.item
                           );
       EXCEPTION
	   WHEN others THEN
	      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'When Others in Master Upd VAL org insert :'||SQLERRM);
       END;
    END LOOP
    COMMIT;

    SELECT COUNT(1)
	INTO ln_cnt
	FROM mtl_system_items_interface
     WHERE set_process_id=ln_batch_id;

    IF ln_cnt>0 THEN
       --------------------------------------------------------------------------------------
       --Call the inopinp_open_interface_process API to process Validation Org Assignments
       --------------------------------------------------------------------------------------
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
                                                               ,xset_id        =>  ln_batch_id
                                                               ,commit_flag    =>  1
                                                               ,run_mode       =>  1
                                                              );
       COMMIT;
       OPEN lcu_valorg_error(p_batch_id);
       LOOP
        FETCH lcu_valorg_error BULK COLLECT INTO lt_item_cat_error,lt_item_cat_errorid,lt_rowid_failure LIMIT G_LIMIT_SIZE;
        IF lt_item_cat_errorid.COUNT > 0 THEN
            ----------------------------------------------
            --Updating Item Process Flags for Failed Items
            ----------------------------------------------
            FORALL i IN 1 .. lt_item_cat_errorid.LAST
            UPDATE XX_INV_ITEM_MASTER_INT XSIM
            SET    XSIM.VALIDATION_ORGS_STATUS_FLAG='F'
			,XSIM.process_flag=7
		      ,XSIM.error_flag='Y'
		      ,XSIM.error_message=XSIM.error_message||' ,'||lt_item_cat_error(i)
            WHERE  XSIM.ROWID             = lt_rowid_failure(i);
        END IF;
        EXIT WHEN lcu_valorg_error%NOTFOUND;
       END LOOP;
       CLOSE lcu_valorg_error;
       COMMIT;
    END IF;
    FOR cur IN c_inactive_item LOOP
	SELECT XX_INV_ITEM_STG_BAT_S.NEXTVAL
	  INTO ln_batch_id
        FROM DUAL;
 	FOR c IN cur_all_locations(cur.inventory_item_id,cur.status) LOOP
	  BEGIN
          INSERT INTO MTL_SYSTEM_ITEMS_INTERFACE
            ( segment1
            ,organization_id
            ,inventory_item_status_code
            ,process_flag
            ,set_process_id
            ,transaction_type
            ,last_update_date
            ,last_updated_by
            ,creation_date
            ,created_by
            ,last_update_login
		,enabled_flag
           )
	   VALUES
	     (cur.item
           ,c.organization_id
           ,cur.status
           ,G_PROCESS_FLAG
           ,ln_batch_id
           ,G_UTRANSACTION_TYPE
           ,G_DATE
           ,G_USER_ID
           ,G_DATE
           ,G_USER_ID
           ,G_USER_ID
	     ,'Y'
	     );
	  EXCEPTION
	    WHEN others THEN
		NULL;
	  END;
      END LOOP;
      COMMIT;
      --------------------------------------------------------------------------
      --Call the inopinp_open_interface_process API to process Inactive items
      --------------------------------------------------------------------------
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
                                                               ,xset_id        =>  ln_batch_id
                                                               ,commit_flag    =>  1
                                                               ,run_mode       =>  2
                                                              );
      COMMIT;

      SELECT COUNT(1)
        INTO  ln_cnt
        FROM  mtl_interface_errors MIE
             ,mtl_system_items_interface MSII
       WHERE  MSII.transaction_id    =   MIE.transaction_id
         AND  MSII.set_process_id    =   ln_batch_id;

      IF ln_cnt<>0 THEN
         UPDATE XX_INV_ITEM_MASTER_INT
	      SET item_process_flag=6
		   ,error_message=error_message||' ,Error in Inactivating Item Locs'
		   ,error_flag='Y'
	    WHERE rowid=cur.drowid;
	   COMMIT;
	END IF;
    END LOOP;
    COMMIT;
END IF;--gc_master_setup_status='Y'
EXCEPTION
WHEN OTHERS THEN
    IF lcu_item_error%ISOPEN THEN
        CLOSE lcu_item_error;
    END IF;
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in process_master_upd - '||gc_sqlerrm;
    x_retcode := 2;
END process_master_upd;

-- +===================================================================+
-- | Name        :  process_loc_upd                                    |
-- | Description :  This procedure is invoked from the child_main      |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- +===================================================================+

PROCEDURE process_loc_upd (  x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
                            ,p_batch_id    IN  NUMBER
                           )
IS
-----------------------------------------------------------------
--Cursor to fetch Inventory Item ids for success location records
-----------------------------------------------------------------
CURSOR lcu_success_locations_itemids(p_batch_id IN NUMBER)
IS
SELECT MSIB.inventory_item_id
      ,XSIL.ROWID
FROM   mtl_system_items_b MSIB
      ,XX_INV_ITEM_LOC_INT XSIL
WHERE  XSIL.load_batch_id           =   p_batch_id
AND    XSIL.action_type='C'
AND    XSIL.location_process_flag  IN (4,5,6)
AND    MSIB.segment1                =   XSIL.item
AND    MSIB.organization_id         =   XSIL.organization_id;

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
      ,XX_INV_ITEM_LOC_INT XSIL
WHERE  MSII.transaction_id    =   MIE.transaction_id
AND    MSII.set_process_id    =   p_batch_id
AND    XSIL.organization_id   =   MSII.organization_id
AND    XSIL.item              =   MSII.segment1
AND    XSIL.load_batch_id     =   p_batch_id
AND    XSIL.action_type='C'
AND    XSIL.location_process_flag  IN (4,5,6)
AND    XSIL.api_change='Y'
UNION ALL
SELECT 'MIRI:'||MIE.error_message
      ,XSIL.control_id
      ,XSIL.ROWID
FROM   mtl_interface_errors MIE
      ,XX_INV_ITEM_LOC_INT XSIL
      ,mtl_system_items_interface MSII
      ,mtl_item_revisions_interface MIRI
WHERE  MIRI.set_process_id    =   p_batch_id
AND    MSII.set_process_id    =   MIRI.set_process_id
AND    MSII.organization_id   =   MIRI.organization_id
AND    MSII.inventory_item_id =   MIRI.inventory_item_id
AND    XSIL.load_batch_id     =   MSII.set_process_id
AND    XSIL.organization_id   =   MSII.organization_id
AND    XSIL.item              =   MSII.segment1
AND    XSIL.action_type='C'
AND    XSIL.location_process_flag  IN (4,5,6)
AND    XSIL.api_change='Y'
AND    MIE.transaction_id     =   MIRI.transaction_id;

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

TYPE loc_errorid_type IS TABLE OF XX_INV_ITEM_LOC_INT.control_id%TYPE
INDEX BY BINARY_INTEGER;
lt_loc_errorid loc_errorid_type;

ln_del_rec_flag      PLS_INTEGER:=0;
ln_return_code       PLS_INTEGER;
lc_err_text          VARCHAR2(5000);

BEGIN
--  BEGIN
    INSERT INTO MTL_SYSTEM_ITEMS_INTERFACE
            (
             segment1
            ,description
            ,primary_uom_code
            ,organization_id
            ,template_id
            ,inventory_item_status_code
		,shippable_item_flag
	      ,item_type
	      ,purchasing_item_flag
	      ,customer_order_flag
            ,process_flag
            ,set_process_id
            ,transaction_type
            ,summary_flag
            ,last_update_date
            ,last_updated_by
            ,creation_date
            ,created_by
            ,last_update_login
		,enabled_flag
		,end_date_active
           )
   SELECT   XSIL.item
           ,MSI.description
           ,MSI.primary_uom_code
           ,XSIL.organization_id
           ,XSIL.template_id
           ,XSIL.status
	     ,XSIL.shippable_item_flag
	     ,MSI.item_type
	     ,MSI.purchasing_item_flag
	     ,MSI.customer_order_flag
           ,G_PROCESS_FLAG
           ,p_batch_id
           ,G_UTRANSACTION_TYPE
           ,'Y'
           ,G_DATE
           ,G_USER_ID
           ,G_DATE
           ,G_USER_ID
           ,G_USER_ID
	     ,'Y'
	     ,DECODE(status,'I',SYSDATE,'D',SYSDATE,NULL)
   FROM     mtl_system_items_b msi
	     ,XX_INV_ITEM_LOC_INT XSIL
   WHERE    XSIL.load_batch_id          = p_batch_id
   AND      XSIL.action_type='C'
   AND      XSIL.location_process_flag  IN (4,5,6)
   AND      XSIL.api_change='Y'
   AND      msi.organization_id=gn_master_org_id
   AND      msi.segment1=XSIL.item;
   COMMIT;

   ln_del_rec_flag:=1;

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'BEFORE API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
   FND_FILE.PUT_LINE(FND_FILE.LOG,'BEFORE API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));

    ----------------------------------------------------------------------------------------
    --Call the inopinp_open_interface_process API to process Organization Assignments
    ----------------------------------------------------------------------------------------
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
                                                               ,run_mode       =>  2
                                                              );
    COMMIT;

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'AFTER API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));
    FND_FILE.PUT_LINE(FND_FILE.LOG,'AFTER API CALL :'||TO_CHAR(SYSDATE,'DD-MON-RR HH24:MI:SS'));


    --------------------------------------------
    --Logging error details for failed locations
    --------------------------------------------
    OPEN lcu_loc_error(p_batch_id);
    LOOP
        FETCH lcu_loc_error BULK COLLECT INTO lt_loc_error,lt_loc_errorid,lt_locationrowid_failure LIMIT G_LIMIT_SIZE;
        IF  lt_loc_errorid.COUNT>0 THEN
            -----------------------------------------------------
            --Updating Location Process Flag for Failed Locations
            -----------------------------------------------------
           FORALL i IN 1 .. lt_loc_errorid.LAST
           UPDATE XX_INV_ITEM_LOC_INT XSIL
           SET    XSIL.location_process_flag= 6
		     ,XSIL.error_flag='Y'
		     ,XSIL.process_flag=7
		     ,XSIL.error_message=XSIL.error_message||' ,'||lt_loc_error(i)
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
           UPDATE XX_INV_ITEM_LOC_INT XSIL
           SET    XSIL.location_process_flag= 7
		     ,XSIL.process_flag=7
                 ,XSIL.inventory_item_id    = lt_locationid_success(i)
           WHERE  XSIL.ROWID                = lt_locationrowid_success(i);
        END IF;
        COMMIT;
        EXIT WHEN lcu_success_locations_itemids%NOTFOUND;
    END LOOP;
    CLOSE lcu_success_locations_itemids;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    IF lcu_loc_error%ISOPEN THEN
        CLOSE lcu_loc_error;
    END IF;
    gc_sqlerrm := SQLERRM;
    gc_sqlcode := SQLCODE;
    x_errbuf  := 'Unexpected error in process_loc_upd  - '||gc_sqlerrm;
    x_retcode := 2;
END process_loc_upd;

-- +===================================================================+
-- | Name        :  child_main                                         |
-- | Description :  This procedure is invoked from the                 |
-- |                OD INV Item Interface Child Program.This would     |
-- |                                                                   |
-- | Parameters  :  p_process                                          |
-- |                p_batch_id                                         |
-- |                                                                   |
-- | Returns     :  x_errbuf                                           |
-- |                x_retcode                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE child_main(
                       x_errbuf             OUT NOCOPY VARCHAR2
                      ,x_retcode            OUT NOCOPY VARCHAR2
                      ,p_process            IN  VARCHAR2
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
      ,COUNT (CASE WHEN item_process_flag ='6' THEN 1 END)
      ,COUNT (CASE WHEN item_process_flag ='7' THEN 1 END)
FROM   XX_INV_ITEM_MASTER_INT XSIM
WHERE  XSIM.load_batch_id=p_batch_id;
-----------------------------------------------------
--Cursor to get the Control Information for Locations
-----------------------------------------------------
CURSOR lcu_location_info (p_batch_id IN NUMBER)
IS
SELECT COUNT (CASE WHEN location_process_flag ='3' THEN 1 END)
      ,COUNT (CASE WHEN location_process_flag ='6' THEN 1 END)
      ,COUNT (CASE WHEN location_process_flag ='7' THEN 1 END)
FROM   XX_INV_ITEM_LOC_INT XSIL
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

	  validate_setups;

	  IF p_process IN ('MA','MC') THEN
           validate_master_data( x_errbuf                  =>lx_errbuf
                                ,x_retcode                 =>lx_retcode
                                ,p_batch_id                =>p_batch_id
		    		        ,p_process			=>p_process
                               );
 	  ELSIF p_process IN ('LA','LC') THEN
           validate_loc_data(  x_errbuf                  =>lx_errbuf
                              ,x_retcode                 =>lx_retcode
                              ,p_batch_id                =>p_batch_id
		    		      ,p_process			=>p_process
                             );
	  END IF;
        IF lx_retcode <> 0 THEN
            x_retcode := lx_retcode;
            CASE WHEN x_errbuf IS NULL
                 THEN x_errbuf  := lx_errbuf;
                 ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
            END CASE;
        END IF;

        lx_errbuf     := NULL;
        lx_retcode    := NULL;

	  IF p_process IN ('MA','LA') THEN
           process_item_data(
                             x_errbuf     =>lx_errbuf
                            ,x_retcode    =>lx_retcode
				    ,p_process    =>p_process
                            ,p_batch_id   =>p_batch_id
                           );
	  ELSIF p_process='MC' THEN
           process_master_upd(
                               x_errbuf     =>lx_errbuf
                              ,x_retcode    =>lx_retcode
                              ,p_batch_id   =>p_batch_id
                             );
        ELSIF p_process='LC' THEN
           process_loc_upd(
                               x_errbuf     =>lx_errbuf
                              ,x_retcode    =>lx_retcode
                              ,p_batch_id   =>p_batch_id
                             );
	  END IF;

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
					     ,p_process    =>p_process
                                   ,p_batch_id   =>p_batch_id
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

	  ITEM_INTF_ERROR_UPD(
					p_process    =>p_process
            	           ,p_batch_id   =>p_batch_id
                             ,x_errbuf     =>lx_errbuf
                             ,x_retcode    =>lx_retcode
             	           );
        COMMIT;
        IF lx_retcode <> 0 THEN
           x_retcode := lx_retcode;
                CASE WHEN x_errbuf IS NULL
                     THEN x_errbuf  := lx_errbuf;
                     ELSE x_errbuf  := x_errbuf||'/'||lx_errbuf;
                END CASE;
        END IF;
    EXCEPTION
    WHEN OTHERS THEN
        x_retcode := lx_retcode;
        CASE WHEN x_errbuf IS NULL
             THEN x_errbuf  := gc_sqlerrm;
             ELSE x_errbuf  := x_errbuf||'/'||gc_sqlerrm;
        END CASE;
        x_retcode := 2;
    END;

    --Fetching Number of  Invalid,Processing Failed and Processed Master Items
    IF p_process IN ('MA','MC') THEN

        OPEN lcu_master_info(p_batch_id);
        FETCH lcu_master_info INTO ln_items_invalid,ln_items_failed,ln_items_processed;
        CLOSE lcu_master_info;

    ELSIF p_process IN ('LA','LC') THEN
        OPEN lcu_location_info(p_batch_id);
        FETCH lcu_location_info INTO ln_locations_invalid,ln_locations_failed,ln_locations_processed;
        CLOSE lcu_location_info;
    END IF;

    --------------------------------------------------
    --Displaying the Items Information in the Out file
    --------------------------------------------------
    IF p_process IN ('MA','MC') THEN

    ln_item_total := ln_items_invalid+ ln_items_failed + ln_items_processed;
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of Item Records      : ',49,' ')||RPAD(ln_item_total,9,' '));
    display_out(RPAD('No. Of Item Records Processed  : ',49,' ')||RPAD(ln_items_processed,9,' '));
    display_out(RPAD('No. Of Item Records Errored    : ',49,' ')||RPAD(ln_items_failed,9,' '));
    display_out(RPAD('No. Of Item Records Failed Validation    : ',49,' ')||RPAD(ln_items_invalid,9,' '));
    display_out(RPAD('=',58,'='));
    ------------------------------------------------------
    --Displaying the Locations Information in the Out file
    ------------------------------------------------------
    ELSIF p_process IN ('LA','LC') THEN
    ln_location_total := ln_locations_invalid+ ln_locations_failed + ln_locations_processed;
    display_out(RPAD('=',58,'='));
    display_out(RPAD('Total No. Of Location Records      : ',49,' ')||RPAD(ln_location_total,9,' '));
    display_out(RPAD('No. Of Location Records Processed  : ',49,' ')||RPAD(ln_locations_processed,9,' '));
    display_out(RPAD('No. Of Location Records Errored    : ',49,' ')||RPAD(ln_locations_failed,9,' '));
    display_out(RPAD('No. Of Location Records Failed Validation    : ',49,' ')||RPAD(ln_locations_invalid,9,' '));
    display_out(RPAD('=',58,'='));
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    x_errbuf  := 'Unexpected error in child_main - '||SQLERRM;
    x_retcode := 2;
END child_main;
END XX_INV_ITEM_INTF_PKG;
/
exit;