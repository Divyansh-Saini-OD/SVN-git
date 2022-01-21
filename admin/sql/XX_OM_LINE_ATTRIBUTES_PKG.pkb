SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY xx_om_line_attributes_pkg 
AS
 
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                        Wipro Technologies                                 |
-- +===========================================================================+
-- | Name         :XX_OM_LINE_ATTRIBUTES_PKG                                   |
-- | Rice ID      :E1334_OM_Attributes_Setup                                   |
-- | Description  :This package specification is used to Insert, Update        |
-- |               Delete, Lock rows of XX_OM_LINE_ATTRIBUTES_ALL              |
-- |               Table                                                       |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ============================        |
-- |DRAFT 1A  12-JUL-2007 Prajeesh         Initial draft version               |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

-- +===================================================================+
-- | Name  : insert_row                                                |
-- | Description:  This procedure is used to invoke Insert row api     |
-- |               to insert into custom table                         |
-- |                                                                   |
-- +===================================================================+


 PROCEDURE insert_row(p_line_rec      IN OUT NOCOPY    XXOM.XX_OM_LINE_ATTRIBUTES_T,
                      x_return_status OUT    NOCOPY    VARCHAR2,
		      x_errbuf        OUT    NOCOPY    VARCHAR2)
 IS
 BEGIN
   INSERT INTO
   xx_om_line_attributes_all
   (
    line_id
   ,licence_address
   ,vendor_config_id
   ,fulfillment_type 
   ,line_type
   ,line_modifier
   ,release_num
   ,cost_center_dept
   ,desktop_del_addr
   ,vendor_site_id
   ,pos_trx_num
   ,one_time_deal
   ,trans_line_status
   ,cust_price
   ,cust_uom
   ,cust_comments
   ,pip_campaign_id
   ,ext_top_model_line_id
   ,ext_link_to_line_id
   ,config_code
   ,gift_message
   ,gift_email
   ,return_rga_number
   ,delivery_date_from
   ,delivery_date_to
   ,wholesaler_fac_cd
   ,wholesaler_acct_num
   ,return_act_cat_code
   ,pO_del_details
   ,ret_ref_header_id
   ,ret_ref_line_id
   ,ship_to_flag
   ,item_note
   ,special_desc
   ,non_cd_line_type
   ,supplier_type
   ,vendor_product_code
   ,contract_details
   ,aops_orig_order_num
   ,aops_orig_order_date
   ,item_comments
   ,backordered_qty
   ,taxable_flag
   ,waca_parent_id
   ,aops_orig_order_line_num
   ,sku_dept
   ,item_source
   ,average_cost
   ,canada_pst_tax
   ,PO_COST
   ,resourcing_flag
   ,waca_status
   ,cust_item_number
   ,pod_date
   ,return_auth_id
   ,return_code
   ,sku_list_price
   ,waca_item_ctr_num
   ,new_schedule_ship_date 
   ,new_schedule_arr_date
   ,taylor_unit_price
   ,taylor_Unit_cost
   ,xdock_inv_org_id
   ,payment_subtype_cod_ind
   ,del_to_post_office_ind
   ,wholesaler_item
   ,cust_comm_pref
   ,cust_pref_email
   ,cust_pref_fax  
   ,cust_pref_phone
   ,cust_pref_phextn
   ,freight_line_id
   ,freight_primary_line_id
   ,creation_date
   ,created_by
   ,last_update_date
   ,last_updated_by
   ,last_update_login
 )
 VALUES
 (
    p_line_rec.line_id
   ,p_line_rec.licence_address
   ,p_line_rec.vendor_config_id
   ,p_line_rec.fulfillment_type
   ,p_line_rec.line_type
   ,p_line_rec.line_modifier
   ,p_line_rec.release_num
   ,p_line_rec.cost_center_dept
   ,p_line_rec.desktop_del_addr
   ,p_line_rec.vendor_site_id
   ,p_line_rec.pos_trx_num
   ,p_line_rec.one_time_deal
   ,p_line_rec.trans_line_status
   ,p_line_rec.cust_price
   ,p_line_rec.cust_uom
   ,p_line_rec.cust_comments
   ,p_line_rec.pip_campaign_id
   ,p_line_rec.ext_top_model_line_id
   ,p_line_rec.ext_link_to_line_id
   ,p_line_rec.config_code
   ,p_line_rec.gift_message
   ,p_line_rec.gift_email
   ,p_line_rec.return_rga_number
   ,p_line_rec.delivery_date_from
   ,p_line_rec.delivery_date_to
   ,p_line_rec.wholesaler_fac_cd
   ,p_line_rec.wholesaler_acct_num
   ,p_line_rec.return_act_cat_code
   ,p_line_rec.pO_del_details
   ,p_line_rec.ret_ref_header_id
   ,p_line_rec.ret_ref_line_id
   ,p_line_rec.ship_to_flag
   ,p_line_rec.item_note
   ,p_line_rec.special_desc
   ,p_line_rec.non_cd_line_type
   ,p_line_rec.supplier_type
   ,p_line_rec.vendor_product_code
   ,p_line_rec.contract_details
   ,p_line_rec.aops_orig_order_num
   ,p_line_rec.aops_orig_order_date
   ,p_line_rec.item_comments
   ,p_line_rec.backordered_qty
   ,p_line_rec.taxable_flag
   ,p_line_rec.waca_parent_id
   ,p_line_rec.aops_orig_order_line_num
   ,p_line_rec.sku_dept
   ,p_line_rec.item_source
   ,p_line_rec.average_cost
   ,p_line_rec.canada_pst_tax
   ,p_line_rec.PO_COST
   ,p_line_rec.resourcing_flag
   ,p_line_rec.waca_status
   ,p_line_rec.cust_item_number
   ,p_line_rec.pod_date
   ,p_line_rec.return_auth_id
   ,p_line_rec.return_code
   ,p_line_rec.sku_list_price
   ,p_line_rec.waca_item_ctr_num
   ,p_line_rec.new_schedule_ship_date
   ,p_line_rec.new_schedule_arr_date
   ,p_line_rec.taylor_unit_price
   ,p_line_rec.taylor_Unit_cost
   ,p_line_rec.xdock_inv_org_id
   ,p_line_rec.payment_subtype_cod_ind
   ,p_line_rec.del_to_post_office_ind
   ,p_line_rec.wholesaler_item
   ,p_line_rec.cust_comm_pref
   ,p_line_rec.cust_pref_email
   ,p_line_rec.cust_pref_fax  
   ,p_line_rec.cust_pref_phone
   ,p_line_rec.cust_pref_phextn
   ,p_line_rec.freight_line_id
   ,p_line_rec.freight_primary_line_id
   ,p_line_rec.creation_date
   ,p_line_rec.created_by
   ,p_line_rec.last_update_date
   ,p_line_rec.last_updated_by
   ,p_line_rec.last_update_login
  );
  x_return_status := FND_API.G_RET_STS_SUCCESS ;
  x_errbuf       := 'Success';
 EXCEPTION
 WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      -- Call the xx_log_exception_proc procedure to insert into Global exception table
      XX_OM_HEADER_ATTRIBUTES_PKG.xx_log_exception_proc ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                       		    		         ,p_error_description => FND_MESSAGE.GET
							 ,p_entity_ref        => 'Header_id'
                                                         ,p_entity_ref_id     => p_line_rec.line_id
							 ,x_return_status     => x_return_status
                                                         ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;
     

END insert_row;


-- +===================================================================+
-- | Name  : update_row                                                |
-- | Description:  This procedure is used to invoke update row api     |
-- |               to update into custom table                         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_row(p_line_rec    IN OUT NOCOPY    XXOM.XX_OM_LINE_ATTRIBUTES_T,
                     x_return_status  OUT NOCOPY    VARCHAR2,
		     x_errbuf         OUT NOCOPY    VARCHAR2)
IS
BEGIN
 UPDATE xx_om_line_attributes_all
 SET
  licence_address         	=	p_line_rec.licence_address
  ,vendor_config_id        	=	p_line_rec.vendor_config_id
  ,fulfillment_type        	=	p_line_rec.fulfillment_type
  ,line_type               	=	p_line_rec.line_type
  ,line_modifier           	=	p_line_rec.line_modifier
  ,release_num             	=	p_line_rec.release_num
  ,cost_center_dept        	=	p_line_rec.cost_center_dept
  ,desktop_del_addr        	=	p_line_rec.desktop_del_addr
  ,vendor_site_id          	=	p_line_rec.vendor_site_id
  ,pos_trx_num             	=	p_line_rec.pos_trx_num
  ,one_time_deal           	=	p_line_rec.one_time_deal
  ,trans_line_status       	=	p_line_rec.trans_line_status
  ,cust_price              	=	p_line_rec.cust_price
  ,cust_uom                	=	p_line_rec.cust_uom
  ,cust_comments           	=	p_line_rec.cust_comments
  ,pip_campaign_id         	=	p_line_rec.pip_campaign_id
  ,ext_top_model_line_id   	=	p_line_rec.ext_top_model_line_id
  ,ext_link_to_line_id     	=	p_line_rec.ext_link_to_line_id
  ,config_code             	=	p_line_rec.config_code
  ,gift_message            	=	p_line_rec.gift_message
  ,gift_email              	=	p_line_rec.gift_email
  ,return_rga_number       	=	p_line_rec.return_rga_number
  ,delivery_date_from      	=	p_line_rec.delivery_date_from
  ,delivery_date_to        	=	p_line_rec.delivery_date_to
  ,wholesaler_fac_cd       	=	p_line_rec.wholesaler_fac_cd
  ,wholesaler_acct_num     	=	p_line_rec.wholesaler_acct_num
  ,return_act_cat_code     	=	p_line_rec.return_act_cat_code
  ,pO_del_details          	=	p_line_rec.pO_del_details
  ,ret_ref_header_id            =	p_line_rec.ret_ref_header_id
  ,ret_ref_line_id              =	p_line_rec.ret_ref_line_id
  ,ship_to_flag            	=	p_line_rec.ship_to_flag
  ,item_note               	=	p_line_rec.item_note
  ,special_desc            	=	p_line_rec.special_desc
  ,non_cd_line_type        	=	p_line_rec.non_cd_line_type
  ,supplier_type           	=	p_line_rec.supplier_type
  ,vendor_product_code     	=	p_line_rec.vendor_product_code
  ,contract_details        	=	p_line_rec.contract_details
  ,aops_orig_order_num     	=	p_line_rec.aops_orig_order_num
  ,aops_orig_order_date    	=	p_line_rec.aops_orig_order_date
  ,item_comments           	=	p_line_rec.item_comments
  ,backordered_qty         	=	p_line_rec.backordered_qty
  ,taxable_flag            	=	p_line_rec.taxable_flag
  ,waca_parent_id          	=	p_line_rec.waca_parent_id
  ,aops_orig_order_line_num	=	p_line_rec.aops_orig_order_line_num
  ,sku_dept                	=	p_line_rec.sku_dept
  ,item_source             	=	p_line_rec.item_source
  ,average_cost            	=	p_line_rec.average_cost
  ,canada_pst_tax          	=	p_line_rec.canada_pst_tax
  ,PO_COST                 	=	p_line_rec.PO_COST
  ,resourcing_flag         	=	p_line_rec.resourcing_flag
  ,waca_status             	=	p_line_rec.waca_status
  ,cust_item_number        	=	p_line_rec.cust_item_number
  ,pod_date                	=	p_line_rec.pod_date
  ,return_auth_id          	=	p_line_rec.return_auth_id
  ,return_code             	=	p_line_rec.return_code
  ,sku_list_price          	=	p_line_rec.sku_list_price
  ,waca_item_ctr_num       	=	p_line_rec.waca_item_ctr_num
  ,new_schedule_ship_date       =       p_line_rec.new_schedule_ship_date     
  ,new_schedule_arr_date        =       p_line_rec.new_schedule_arr_date      
  ,taylor_unit_price       	=	p_line_rec.taylor_unit_price
  ,taylor_Unit_cost        	=	p_line_rec.taylor_Unit_cost
  ,xdock_inv_org_id        	=	p_line_rec.xdock_inv_org_id
  ,payment_subtype_cod_ind 	=	p_line_rec.payment_subtype_cod_ind
  ,del_to_post_office_ind  	=	p_line_rec.del_to_post_office_ind
  ,wholesaler_item              =       p_line_rec.wholesaler_item
  ,cust_comm_pref               =       p_line_rec.cust_comm_pref
  ,cust_pref_email              =       p_line_rec.cust_pref_email
  ,cust_pref_fax                =       p_line_rec.cust_pref_fax
  ,cust_pref_phone              =       p_line_rec.cust_pref_phone
  ,cust_pref_phextn             =       p_line_rec.cust_pref_phextn
  ,freight_line_id              =       p_line_rec.freight_line_id
  ,freight_primary_line_id      =       p_line_rec.freight_primary_line_id
  ,creation_date           	=	p_line_rec.creation_date
  ,created_by              	=	p_line_rec.created_by
  ,last_update_date        	=	p_line_rec.last_update_date
  ,last_updated_by         	=	p_line_rec.last_updated_by
  ,last_update_login       	=	p_line_rec.last_update_login
  WHERE line_id                 =       p_line_rec.line_id;

  x_return_status := FND_API.G_RET_STS_SUCCESS ;
  x_errbuf       := 'Success';

 EXCEPTION

 WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN

      FND_MESSAGE.SET_NAME('ONT','OE_LOCK_ROW_ALREADY_LOCKED');
      

      XX_OM_HEADER_ATTRIBUTES_PKG.xx_log_exception_proc(p_error_code        => 'OE_LOCK_ROW_ALREADY_LOCKED'
                       		    		       ,p_error_description => FND_MESSAGE.GET
						       ,p_entity_ref        => 'Header_id'
                                                       ,p_entity_ref_id     => p_line_rec.line_id
						       ,x_return_status     => x_return_status
                                                       ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;
      

 WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
      
      -- Call the xx_log_exception_proc procedure to insert into Global exception table
      XX_OM_HEADER_ATTRIBUTES_PKG.xx_log_exception_proc ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                       		    		         ,p_error_description => FND_MESSAGE.GET
							 ,p_entity_ref        => 'Header_id'
                                                         ,p_entity_ref_id     => p_line_rec.line_id
							 ,x_return_status     => x_return_status
                                                         ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
               
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;


END update_row;

-- +===================================================================+
-- | Name  : lock_row                                                  |
-- | Description:  This procedure is used to invoke lock row api       |
-- |               to lock  custom table                               |
-- |                                                                   |
-- +=================================================================

PROCEDURE lock_row(p_line_rec        IN OUT NOCOPY     XXOM.XX_OM_LINE_ATTRIBUTES_T,
                   x_return_status      OUT NOCOPY     VARCHAR2,
		   x_errbuf             OUT NOCOPY     VARCHAR2)
IS
  ln_line_id xx_om_line_attributes_all.line_id%TYPE;
BEGIN
 SAVEPOINT lock_row;

  SELECT line_id
  INTO ln_line_id
  FROM xx_om_line_attributes_ALL
  WHERE line_id = p_line_rec.line_id
  FOR UPDATE NOWAIT;

  x_return_status := FND_API.G_RET_STS_SUCCESS ;
  x_errbuf       := 'Success';
 EXCEPTION

 WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN
      ROLLBACK to SAVEPOINT lock_row;
      fnd_message.set_name('ONT','OE_LOCK_ROW_ALREADY_LOCKED');

      XX_OM_HEADER_ATTRIBUTES_PKG.xx_log_exception_proc(p_error_code        => 'OE_LOCK_ROW_ALREADY_LOCKED'
                       		    		       ,p_error_description => FND_MESSAGE.GET
						       ,p_entity_ref        => 'Header_id'
                                                       ,p_entity_ref_id     => p_line_rec.line_id
						       ,x_return_status     => x_return_status
                                                       ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;


 WHEN OTHERS THEN
      ROLLBACK to SAVEPOINT lock_row;
      FND_MESSAGE.SET_NAME('XXOM','XXX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      -- Call the xx_log_exception_proc procedure to insert into Global exception table
      XX_OM_HEADER_ATTRIBUTES_PKG.xx_log_exception_proc ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                       		    		         ,p_error_description => FND_MESSAGE.GET
							 ,p_entity_ref        => 'Header_id'
                                                         ,p_entity_ref_id     => p_line_rec.line_id
							 ,x_return_status     => x_return_status
                                                         ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;


END lock_row;

-- +===================================================================+
-- | Name  : delete_row                                                |
-- | Description:  This procedure is used to invoke delete row api     |
-- |               to delete  custom table                             |
-- |                                                                   |
-- +===================================================================

PROCEDURE delete_row(p_line_id       IN            xx_om_line_attributes_all.line_id%TYPE,
                     x_return_status OUT NOCOPY    VARCHAR2,
		     x_errbuf        OUT NOCOPY    VARCHAR2) IS
BEGIN
  DELETE FROM 
  xx_om_line_attributes_all 
  WHERE line_id=p_line_id;

  x_return_status := FND_API.G_RET_STS_SUCCESS ;
  x_errbuf       := 'Success';

 EXCEPTION

 WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN

      fnd_message.set_name('ONT','OE_LOCK_ROW_ALREADY_LOCKED');

      XX_OM_HEADER_ATTRIBUTES_PKG.xx_log_exception_proc(p_error_code        => 'OE_LOCK_ROW_ALREADY_LOCKED'
                       		    		       ,p_error_description => FND_MESSAGE.GET
						       ,p_entity_ref        => 'Header_id'
                                                       ,p_entity_ref_id     => p_line_id
						       ,x_return_status     => x_return_status
                                                       ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;


 WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
      

      -- Call the xx_log_exception_proc procedure to insert into Global exception table
      XX_OM_HEADER_ATTRIBUTES_PKG.xx_log_exception_proc ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                       		    		         ,p_error_description => FND_MESSAGE.GET
							 ,p_entity_ref        => 'Header_id'
                                                         ,p_entity_ref_id     => p_line_id
							 ,x_return_status     => x_return_status
                                                         ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;

END delete_row;

END xx_om_line_attributes_pkg;
/

SHOW ERRORS
