CREATE OR REPLACE PACKAGE BODY APPS.XX_INV_ITEM_IN_PKG
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                Oracle NAIO Consulting Organization                            |
-- +===============================================================================+
-- +===============================================================================+
-- |Package Name : XX_INV_ITEM_IN_PKG                                              |
-- |Purpose      : This package contains three procedures that interface the data  |
-- |                 from RMS to EBS.                                              |
-- |                                                                               |
-- |Tables Accessed :                                                              |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)  |
-- |                                                                               |
-- |MTL_SYSTEM_ITEMS_B          : I,S,U                                            |
-- |MTL_ITEM_CATEGORIES         : I,U                                              |
-- |MTL_CATEGORIES_B            : S                                                |
-- |MTL_CATEGORY_SETS           : S                                                |
-- |MTL_PARAMETERS              : S                                                |
-- |HR_ORGAINZATION_UNTIS       : S                                                |
-- |MTL_CATEGORY_SET_VALID_CATS : S                                                |
-- |FND_ID_FLEX_STRUCTURES_VL   : S                                                |
-- |HR_LOOKUPS                  : S                                                |
-- |                                                                               |
-- |Change History                                                                 |
-- |                                                                               |
-- |Ver   Date          Author             Description                             |
-- |---   -----------   -----------------  ----------------------------------------|
-- |1.0   23-May-2007   Arun Andavar       Original Code                           |
-- |1.1   22-Jun-2007   Arun Andavar       Changed for ActionExpression            |
-- |1.2   27-Jun-2007   Susheel/Jayshree   Reviewed and updated                    |
-- |1.3   28-Jun-2007   Arun Andavar       1.Bug fix-Enable flag not updated for   |
-- |                                       location                                |
-- |                                       2.Private brand logic modified, use     |
-- |                                        private brand flag to decide whether   |
-- |                                        PB is to be derived or not.            |
-- |1.4   03-Jul-2007   Arun Andavar       1.Non-code itemtype derivation added(CR)|
-- |                                       2.Enabled_flag will always be Y (CR)    |
-- |                                       3.ATP Category assignment added (CR)    |
-- |                                       4.Category derivation modified for      |
-- |                                        increasing the performance             |
-- |1.5   16-Jul-2007   Arun Andavar       Modified category cursors to fetch      |
-- |                                       the active category code combinations.  |
-- |1.6   17-Jul-2007   Arun Andavar       Modified tax category mapping to map    |
-- |                                       attribute1.                             |
-- |1.7   24-Jul-2007   Arun Andavar       1.Program logic is changed to process   |
-- |                                        item only if all the categories are    |
-- |                                        through the validation.                |
-- |                                       2.Bug fix-Validation org reprocessing   |
-- |                                       3.Bug fix-Custom attributes reprocessing|
-- |1.8   28-Sep-2007   Paddy Sanjeevi     Modified to call API only if anychange  |
-- |1.9   03-Jan-2008   Ganesh Nadakudhiti Changed the User name and resp key to   |
-- |1.10  07-Jan-2008   Ganesh Nadakudhiti Changed code to handle null rmstimestamp|
-- |							 values					     |
-- |1.11  19-May-2008   Paddy Sanjeevi     Modified to insert messages in staging  |
-- |                                       table rather than processing            |
-- +===============================================================================+
IS
PROCEDURE INTERFACE_ITEM_DATA
               (p_actionexpression         IN VARCHAR2
               ,p_reason_code              IN VARCHAR2
	         ,p_rms_timestamp            IN VARCHAR2
               ,p_master_item_hdr_rec      IN g_master_itm_hdr_rec_type
               ,p_master_item_category_rec IN g_master_itm_category_rec_type
               ,p_master_item_attri_rec    IN xx_inv_item_master_attributes%ROWTYPE
               ,p_location_rec             IN g_location_rec
               ,x_message_code             OUT NUMBER
               ,x_message_data             OUT VARCHAR2
               )
IS
BEGIN
  x_message_code         := 0;
  IF p_reason_code = 'ITEM_MASTER' THEN
     UPDATE xx_item_master_intf
        SET  item				=p_master_item_hdr_rec.item_number
		,class			=p_master_item_category_rec.class
		,dept				=p_master_item_category_rec.dept
		,handling_sensitivity	=p_master_item_attri_rec.handling_sensitivity
		,item_desc			=p_master_item_hdr_rec.description
		,item_number_type		=p_master_item_attri_rec.item_number_type
		,order_as_type		=p_master_item_attri_rec.order_as_type
		,orderable_ind		=p_master_item_hdr_rec.orderable_ind
		,pack_ind			=p_master_item_attri_rec.pack_ind
		,pack_type			=p_master_item_attri_rec.pack_type
		,package_size		=p_master_item_attri_rec.package_size
		,package_uom		=p_master_item_hdr_rec.base_uom_code
		,sellable_ind		=p_master_item_hdr_rec.sellable
		,ship_alone_ind		=p_master_item_attri_rec.ship_alone_ind
		,short_desc			=p_master_item_attri_rec.short_desc
		,simple_pack_ind		=p_master_item_attri_rec.simple_pack_ind
		,status			=p_master_item_hdr_rec.item_status
		,store_ord_mult		=p_master_item_attri_rec.store_ord_mult
		,subclass			=p_master_item_category_rec.subclass
		,od_assortment_cd		=p_master_item_attri_rec.od_assortment_cd
		,od_call_for_price_cd	=p_master_item_attri_rec.od_call_for_price_cd
		,od_cost_up_flg		=p_master_item_attri_rec.od_cost_up_flg
		,od_gift_certif_flg	=p_master_item_attri_rec.od_gift_certif_flg
		,od_gsa_flg			=p_master_item_attri_rec.od_gsa_flg
		,od_imprinted_item_flg	=p_master_item_attri_rec.od_imprinted_item_flg
		,od_list_off_flg		=p_master_item_attri_rec.od_list_off_flg
		,od_meta_cd			=p_master_item_attri_rec.od_meta_cd
		,od_off_cat_flg		=p_master_item_attri_rec.od_off_cat_flg
		,od_ovrsize_delvry_flg	=p_master_item_attri_rec.od_ovrsize_delvry_flg
		,od_private_brand_flg	=p_master_item_attri_rec.od_private_brand_flg
		,od_private_brand_label	=p_master_item_category_rec.private_brand_label
		,od_prod_protect_cd	=p_master_item_attri_rec.od_prod_protect_cd
		,od_ready_to_assemble_flg=p_master_item_attri_rec.od_ready_to_assemble_flg
		,od_recycle_flg		=p_master_item_attri_rec.od_recycle_flg
		,od_retail_pricing_flg	=p_master_item_attri_rec.od_retail_pricing_flg
		,od_sku_type_cd		=p_master_item_hdr_rec.item_type 
		,od_tax_category		=p_master_item_hdr_rec.tax_category
		,master_item		=p_master_item_attri_rec.master_item
		,subsell_master_qty	=p_master_item_attri_rec.subsell_master_qty
		,creation_date		=SYSDATE
		,last_update_date		=SYSDATE
		,action_type		=p_actionexpression
		,process_id			=p_master_item_attri_rec.created_by
		,rms_timestamp		=p_rms_timestamp
	WHERE item=p_master_item_hdr_rec.item_number
	  AND process_flag=1
	  AND load_batch_id IS NULL;
     IF SQL%NOTFOUND THEN
        BEGIN
          INSERT INTO xx_item_master_intf
	   ( 	 item
		,class
		,dept
		,handling_sensitivity
		,item_desc
		,item_number_type
		,order_as_type
		,orderable_ind
		,pack_ind
		,pack_type
		,package_size
		,package_uom
		,sellable_ind
		,ship_alone_ind
		,short_desc
		,simple_pack_ind
		,status
		,store_ord_mult
		,subclass
		,od_assortment_cd
		,od_call_for_price_cd
		,od_cost_up_flg
		,od_gift_certif_flg
		,od_gsa_flg
		,od_imprinted_item_flg
		,od_list_off_flg
		,od_meta_cd
		,od_off_cat_flg
		,od_ovrsize_delvry_flg
		,od_private_brand_flg
		,od_private_brand_label
		,od_prod_protect_cd
		,od_ready_to_assemble_flg
		,od_recycle_flg
		,od_retail_pricing_flg
		,od_sku_type_cd
		,od_tax_category
		,master_item
		,subsell_master_qty
		,process_flag
		,creation_date
		,created_by		
		,last_update_date
		,last_updated_by
		,action_type
		,process_id
		,rms_timestamp
	   )
	   VALUES
         ( 	 p_master_item_hdr_rec.item_number
		,p_master_item_category_rec.class
		,p_master_item_category_rec.dept
		,p_master_item_attri_rec.handling_sensitivity
		,p_master_item_hdr_rec.description
		,p_master_item_attri_rec.item_number_type
		,p_master_item_attri_rec.order_as_type
		,p_master_item_hdr_rec.orderable_ind
		,p_master_item_attri_rec.pack_ind
		,p_master_item_attri_rec.pack_type
		,p_master_item_attri_rec.package_size
		,p_master_item_hdr_rec.base_uom_code
		,p_master_item_hdr_rec.sellable
		,p_master_item_attri_rec.ship_alone_ind
		,p_master_item_attri_rec.short_desc
		,p_master_item_attri_rec.simple_pack_ind
		,p_master_item_hdr_rec.item_status
		,p_master_item_attri_rec.store_ord_mult
		,p_master_item_category_rec.subclass
		,p_master_item_attri_rec.od_assortment_cd
		,p_master_item_attri_rec.od_call_for_price_cd
		,p_master_item_attri_rec.od_cost_up_flg
		,p_master_item_attri_rec.od_gift_certif_flg
		,p_master_item_attri_rec.od_gsa_flg
		,p_master_item_attri_rec.od_imprinted_item_flg
		,p_master_item_attri_rec.od_list_off_flg
		,p_master_item_attri_rec.od_meta_cd
		,p_master_item_attri_rec.od_off_cat_flg
		,p_master_item_attri_rec.od_ovrsize_delvry_flg
		,p_master_item_attri_rec.od_private_brand_flg
		,p_master_item_category_rec.private_brand_label
		,p_master_item_attri_rec.od_prod_protect_cd
		,p_master_item_attri_rec.od_ready_to_assemble_flg
		,p_master_item_attri_rec.od_recycle_flg
		,p_master_item_attri_rec.od_retail_pricing_flg
		,p_master_item_hdr_rec.item_type 
		,p_master_item_hdr_rec.tax_category
		,p_master_item_attri_rec.master_item
		,p_master_item_attri_rec.subsell_master_qty
		,1
		,SYSDATE
		,-1		
		,SYSDATE
		,-1
		,p_actionexpression
		,p_master_item_attri_rec.created_by
	      ,p_rms_timestamp
	   );
	   x_message_code         := 0;
	   x_message_data	        := NULL;
        EXCEPTION
 	    WHEN others THEN
	      x_message_code         := -1;
	      x_message_data         :=SQLERRM;
        END;
     END IF;
  ELSIF p_reason_code = 'ITEM_LOC' THEN
     UPDATE xx_item_loc_intf
        SET  item					=p_master_item_hdr_rec.item_number
		,loc					=p_location_rec.location
	      ,LOCAL_ITEM_DESC			=p_location_rec.attribute.local_item_desc
		,LOCAL_SHORT_DESC			=p_location_rec.attribute.local_short_desc
		,PRIMARY_SUPP			=p_location_rec.attribute.primary_supp
		,STATUS				=p_location_rec.item_status
		,OD_ABC_CLASS			=p_location_rec.attribute.od_abc_class
		,OD_CHANNEL_BLOCK			=p_location_rec.attribute.od_channel_block
		,OD_DIST_TARGET  			=p_location_rec.attribute.od_dist_target
		,OD_EBW_QTY      			=p_location_rec.attribute.od_ebw_qty
		,OD_INFINITE_QTY_CD		=p_location_rec.attribute.od_infinite_qty_cd
		,OD_LOCK_UP_ITEM_FLG		=p_location_rec.attribute.od_lock_up_item_flg
		,OD_PROPRIETARY_TYPE_CD		=p_location_rec.attribute.od_proprietary_type_cd
		,OD_REPLEN_SUB_TYPE_CD 		=p_location_rec.attribute.od_replen_sub_type_cd
		,OD_REPLEN_TYPE_CD     		=p_location_rec.attribute.od_replen_type_cd
		,OD_WHSE_ITEM_CD       		=p_location_rec.attribute.od_whse_item_cd
		,CREATION_DATE         		=SYSDATE
		,LAST_UPDATE_DATE      		=SYSDATE
		,ACTION_TYPE  			=p_actionexpression
		,process_id				=p_location_rec.attribute.created_by
		,rms_timestamp	    	      =p_rms_timestamp
	WHERE item=p_master_item_hdr_rec.item_number
	  AND loc =p_location_rec.location
        AND process_flag=1
	  AND load_batch_id IS NULL;
     IF SQL%NOTFOUND THEN
        BEGIN
          INSERT INTO xx_item_loc_intf
	    (  item
		,loc
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
		,PROCESS_FLAG          
		,CREATION_DATE         
		,CREATED_BY            
		,LAST_UPDATE_DATE      
		,LAST_UPDATED_BY       
		,ACTION_TYPE  
		,process_id
		,rms_timestamp
	   )
	   VALUES
	   ( 	 p_master_item_hdr_rec.item_number
		,p_location_rec.location
	      ,p_location_rec.attribute.local_item_desc
		,p_location_rec.attribute.local_short_desc
		,p_location_rec.attribute.primary_supp
		,p_location_rec.item_status
		,p_location_rec.attribute.od_abc_class
		,p_location_rec.attribute.od_channel_block
		,p_location_rec.attribute.od_dist_target
		,p_location_rec.attribute.od_ebw_qty
		,p_location_rec.attribute.od_infinite_qty_cd
		,p_location_rec.attribute.od_lock_up_item_flg
		,p_location_rec.attribute.od_proprietary_type_cd
		,p_location_rec.attribute.od_replen_sub_type_cd
		,p_location_rec.attribute.od_replen_type_cd
		,p_location_rec.attribute.od_whse_item_cd
		,1
		,SYSDATE
		,-1
		,SYSDATE      
		,-1
		,p_actionexpression
		,p_location_rec.attribute.created_by
		,p_rms_timestamp
	   );
        EXCEPTION
	    WHEN others THEN
	      x_message_code         := -1;
	      x_message_data         :=SQLERRM;
        END;
     END IF;
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    x_message_code         := -1;
    x_message_data         :=SQLERRM;
END INTERFACE_ITEM_DATA;
END XX_INV_ITEM_IN_PKG;
/
