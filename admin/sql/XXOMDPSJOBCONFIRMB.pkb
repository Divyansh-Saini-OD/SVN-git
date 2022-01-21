SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_DPS_CONF_REL_PKG
-- +===================================================================+
-- | Name  :    XX_DPS_CONF_REL_PKG                                    |
-- | RICE ID :  I1153                                                  |
-- | Description      : This package is used to call the               |
-- |                    procedures                                     |
-- |                    1)  DPS_CONF_LINE_UPD                          |
-- |                        to do all necessary validations and        |
-- |                        get the information needed for updating the|
-- |                        sales order line attribute                 |
-- |                    2)  DPS_HOLD_REL                               |
-- |                        to do all necessary validations and        |
-- |                        release the sales line level hold          |
-- |                        if it is OD Hold for production            |
-- |                        and updating the line attribute            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       23-March-07    Srividhya                                 |
-- +===================================================================+
AS


 --  Global Parameters

   gc_exception_header    xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
   gc_track_code          xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
   gc_solution_domain     xx_om_global_exceptions.solution_domain%TYPE    :=  'Internal Fulfillment';
   gc_function            xx_om_global_exceptions.function%TYPE           :=  'I1153';
   gc_release_reason      oe_hold_releases.release_reason_code%TYPE       :=  'PREPAYMENT';
   gc_release_comment     oe_hold_releases.release_comment%TYPE           :=  'Prepayment has been processed.Hold released automatically.';
   gc_hold_name           oe_hold_definitions.name%TYPE                   :=  'DPS Hold';
   gc_dpsConfStatus       VARCHAR2(20)                                    :=  'XX_OM_HLD_PRODUCTION';
   gc_dspRelStatus        VARCHAR2(20)					                  :=  'XX_OM_RECONCILED';

         
-- +===================================================================+
-- | Name  : DPS_CONF_LINE_UPD                                         |
-- | Description   : This Procedure will be used to update the         |
-- |                 sales order lines's attribute with                |
-- |                 'XX_OM_HLD_PRODUCTION'                            |
-- |                                                                   |
-- | Parameters :       p_order_number                                 |
-- |                    p_line_number                                  |
-- |                    p_item_id                                      |
-- |                    p_user_name                                    |
-- |                    p_resp_name                                    |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_status                                       |
-- |                    x_message                                      |
-- |                                                                   |
-- |                                                                   |
-- +=========================================================+=========+

  
   PROCEDURE DPS_CONF_LINE_UPD(
      p_po_number      IN       oe_order_headers_all.cust_po_number%TYPE
     ,p_order_number   IN       oe_order_headers_all.order_number%TYPE
     ,p_line_id        IN       oe_order_lines_all.line_id%TYPE
     ,p_item           IN       oe_order_lines_all.ordered_item%TYPE
     ,p_user_name      IN       fnd_user.user_name%TYPE
     ,p_resp_name      IN       fnd_responsibility_tl.responsibility_name%TYPE
     ,x_status         OUT      VARCHAR2
     ,x_message        OUT      VARCHAR2
   )
   IS
      -- variable declaration

      ln_order_num               oe_order_headers_all.order_number%TYPE;
      ln_ordered_item            oe_order_lines_all.inventory_item_id%TYPE;
      lc_name                    oe_hold_definitions.NAME%TYPE;
      lc_attribute6              oe_order_lines_all.attribute6%TYPE;
      lc_err_desc                xxom.xx_om_global_exceptions.description%TYPE
                                                             DEFAULT 'OTHERS';
      lc_entity_ref              xxom.xx_om_global_exceptions.entity_ref%TYPE;
      lc_entity_ref_id           xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
      lc_err_code                xxom.xx_om_global_exceptions.error_code%TYPE
                                                               DEFAULT '1001';
      lc_structure_id            xx_om_lines_attributes_all.structure_id%TYPE;
      lc_segment                 VARCHAR (4000);
      ln_combination_id          xx_om_lines_attributes_all.combination_id%TYPE;
      lt_update_line_tbl         oe_order_pub.line_tbl_type;
      lr_rep_exp_type            xxom.xx_om_report_exception_t;
      x_header_rec               oe_order_pub.header_rec_type;
      x_sts                      VARCHAR2(100);
      x_msg                      VARCHAR2(100);
      x_header_val_rec           oe_order_pub.header_val_rec_type;
      x_header_adj_tbl           oe_order_pub.header_adj_tbl_type;
      x_header_adj_val_tbl       oe_order_pub.header_adj_val_tbl_type;
      x_header_price_att_tbl     oe_order_pub.header_price_att_tbl_type;
      x_header_adj_att_tbl       oe_order_pub.header_adj_att_tbl_type;
      x_header_adj_assoc_tbl     oe_order_pub.header_adj_assoc_tbl_type;
      x_header_scredit_tbl       oe_order_pub.header_scredit_tbl_type;
      x_header_scredit_val_tbl   oe_order_pub.header_scredit_val_tbl_type;
      x_line_tbl                 oe_order_pub.line_tbl_type;
      x_line_val_tbl             oe_order_pub.line_val_tbl_type;
      x_line_adj_tbl             oe_order_pub.line_adj_tbl_type;
      x_line_adj_val_tbl         oe_order_pub.line_adj_val_tbl_type;
      x_line_price_att_tbl       oe_order_pub.line_price_att_tbl_type;
      x_line_adj_att_tbl         oe_order_pub.line_adj_att_tbl_type;
      x_line_adj_assoc_tbl       oe_order_pub.line_adj_assoc_tbl_type;
      x_line_scredit_tbl         oe_order_pub.line_scredit_tbl_type;
      x_line_scredit_val_tbl     oe_order_pub.line_scredit_val_tbl_type;
      x_lot_serial_tbl           oe_order_pub.lot_serial_tbl_type;
      x_lot_serial_val_tbl       oe_order_pub.lot_serial_val_tbl_type;
      x_action_request_tbl       oe_order_pub.request_tbl_type;
      x_return_status            VARCHAR2 (1000);
      x_msg_count                NUMBER (20);
      x_msg_data                 VARCHAR2 (2000);
      x_err_buf                  VARCHAR2 (40);
      x_ret_code                 VARCHAR2 (40);
      ex_failed                  EXCEPTION;
      ex_error                   EXCEPTION;

    CURSOR lcu_parent_lines_detail(p_parent_line_id xx_om_lines_attributes_all.segment14%TYPE )
       IS
       SELECT OOLA.line_id
        FROM  oe_order_lines_all OOLA      
             ,xx_om_lines_attributes_all XXOL
        WHERE OOLA.attribute6   = to_char(xxol.combination_id)                
          AND XXOL.segment14    = p_parent_line_id ;
   BEGIN
      x_status := 'Success';
      x_message :='Success';
      
         -- Apps Initialisation
      xx_om_dps_apps_init_pkg.dps_apps_init (    		   
				                        p_user_name       
				                       ,p_resp_name      
				                       ,x_sts
				                       ,x_msg
			                               );
      

      -- VALIDATION LIST
      -- 1) Order Number Validation
      -- 2) Hold FOR production Validation
      -- 3) Item validation
      -- 4) Attribute6(Segment10) Validation


      --Order number Validation
      IF p_order_number IS NULL
      THEN
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_NULL_INPUTORDER');
         lc_err_desc := fnd_message.get;
         lc_err_code := '0004';
         lc_entity_ref := 'Order_number';
         lc_entity_ref_id := 00000;
         RAISE ex_failed;
      ELSE
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_INVALIDORDERNUM');
         lc_err_desc := fnd_message.get;
         lc_err_code := '0005';
         lc_entity_ref := 'Order_Number';
         lc_entity_ref_id := NVL(p_order_number,0);

         SELECT OEH.order_number
           INTO ln_order_num
           FROM oe_order_headers_all OEH
          WHERE OEH.order_number = p_order_number;
      END IF;

 

      FOR  parent_lines_detail_rec_type IN lcu_parent_lines_detail(p_line_id )
      LOOP
      -- Hold For production Validation
      BEGIN
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_HOLD');
         lc_err_desc := fnd_message.get;
         lc_err_code := '0006';
         lc_entity_ref := 'Order Number';
         lc_entity_ref_id := NVL(p_order_number,0);

         SELECT OHD.name
           INTO lc_name
           FROM oe_hold_definitions OHD
               ,oe_hold_sources_all OHSA
               ,oe_order_holds_all OOHO
          WHERE OHD.NAME = gc_hold_name                      
            AND OHD.hold_id = OHSA.hold_id
            AND OHSA.hold_source_id = OOHO.hold_source_id
            AND OOHO.released_flag = 'N'
            AND OOHO.line_id = parent_lines_detail_rec_type.line_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_message.set_name ('XXOM', 'ODP_OM_DPS_NO_HOLD');
            lc_err_desc := fnd_message.get;
            lc_err_code := '0007';
            lc_entity_ref := 'Order Number';
            lc_entity_ref_id := NVL(p_order_number,0);
            RAISE ex_failed;
      END;

    

      --Attribute6 Validation
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_ATTRIBUTE6');
      lc_err_code := '0010';
      lc_err_desc := fnd_message.get;
      lc_entity_ref := 'Line ID';
      lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);

      SELECT NVL (segment10, 'XXX')
        INTO lc_attribute6
        FROM xx_om_lines_attributes_all XOL
	    , oe_order_lines_all OEL
       WHERE OEL.attribute6 = XOL.combination_id
         AND OEL.line_id = parent_lines_detail_rec_type.line_id;

      IF (lc_attribute6 = 'XX_OM_HLD_NEW')
      THEN
         x_status := 'Success';
         
      ELSE
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_ATTRIBUTE6');
         lc_err_code := '0011';
         lc_err_desc := fnd_message.get;
         lc_entity_ref := 'Line ID';
         lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);
         RAISE ex_failed;
      END IF;

      --Extracting Segments for the Combination ID
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_SEGMENTS_EXTRC_FAIL');
      lc_err_code := '0012';
      lc_err_desc := fnd_message.get;
      lc_entity_ref := 'Line ID';
      lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);

      SELECT    segment6
             || '.'
             || segment7
             || '.'
             || segment8
             || '.'
             || segment5
             || '.'
             || segment3
             || '.'
             || segment2
             || '.'
             || segment4
             || '.'
             || segment9
             || '.'
             || gc_dpsConfStatus            -- 'XX_OM_HLD_PRODUCTION'
             || '.'
             || segment11
             || '.'
             || segment12
             || '.'
             || segment13
             || '.'
             || segment14
             || '.'
             || segment15
             || '.'
             || segment20
             || '.'
             || segment18
             || '.'
             || segment19
             || '.'
             || segment16
             || '.'
             || segment17
             || '.'
             || segment21
             || '.'
             || segment22
             || '.'
             || segment23
             || '.'
             || segment24
             || '.'
             || segment25
             || '.'
             || segment26
             || '.'
             || segment27
             || '.'
             || segment28
             || '.'
             || segment29
             || '.'
             || segment30
            ,structure_id
        INTO lc_segment
            ,lc_structure_id
        FROM xx_om_lines_attributes_all XOL
	    , oe_order_lines_all OOL
       WHERE TO_CHAR(XOL.combination_id) = OOL.attribute6
         AND OOL.line_id = parent_lines_detail_rec_type.line_id;

      --Generate Combination ID
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_COMBID_FAILED');
      lc_err_code := '0013';
      lc_err_desc := fnd_message.get;
      lc_entity_ref := 'Line ID';
      lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);
      ln_combination_id :=
         fnd_flex_ext.get_ccid ('XXOM'
                               ,'XXOL'
                               ,lc_structure_id
                               ,SYSDATE
                               ,lc_segment
                               );

      IF (ln_combination_id <> 0)
      THEN
         --Calling Process Order API
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_PROCESS_ORDER_FAIL');
         lc_err_code := '0014';
         lc_err_desc := fnd_message.get;
         lc_entity_ref := 'Order_number';
         lc_entity_ref_id := NVL(p_order_number,0);
         lt_update_line_tbl (1) := oe_order_pub.g_miss_line_rec;
         lt_update_line_tbl (1).line_id := parent_lines_detail_rec_type.line_id;
         lt_update_line_tbl (1).attribute6 := TO_CHAR (ln_combination_id);
         lt_update_line_tbl (1).operation := oe_globals.g_opr_update;
         oe_order_pub.process_order
                       (1.0
                       ,fnd_api.g_false
                       ,fnd_api.g_false
                       ,fnd_api.g_false
                       ,x_return_status
                       ,x_msg_count
                       ,x_msg_data
                       --in parameters
                       ,p_line_tbl                    => lt_update_line_tbl
                       --out parameters
                       ,x_header_rec                  => x_header_rec
                       ,x_header_val_rec              => x_header_val_rec
                       ,x_header_adj_tbl              => x_header_adj_tbl
                       ,x_header_adj_val_tbl          => x_header_adj_val_tbl
                       ,x_header_price_att_tbl        => x_header_price_att_tbl
                       ,x_header_adj_att_tbl          => x_header_adj_att_tbl
                       ,x_header_adj_assoc_tbl        => x_header_adj_assoc_tbl
                       ,x_header_scredit_tbl          => x_header_scredit_tbl
                       ,x_header_scredit_val_tbl      => x_header_scredit_val_tbl
                       ,x_line_tbl                    => x_line_tbl
                       ,x_line_val_tbl                => x_line_val_tbl
                       ,x_line_adj_tbl                => x_line_adj_tbl
                       ,x_line_adj_val_tbl            => x_line_adj_val_tbl
                       ,x_line_price_att_tbl          => x_line_price_att_tbl
                       ,x_line_adj_att_tbl            => x_line_adj_att_tbl
                       ,x_line_adj_assoc_tbl          => x_line_adj_assoc_tbl
                       ,x_line_scredit_tbl            => x_line_scredit_tbl
                       ,x_line_scredit_val_tbl        => x_line_scredit_val_tbl
                       ,x_lot_serial_tbl              => x_lot_serial_tbl
                       ,x_lot_serial_val_tbl          => x_lot_serial_val_tbl
                       ,x_action_request_tbl          => x_action_request_tbl
                       );
         IF (x_return_status <> 'S')
         THEN
            IF x_msg_count > 0
            THEN
               FOR i IN 1 .. x_msg_count
               LOOP
                  x_msg_data :=
                        x_msg_data
                     || ' '
                     || oe_msg_pub.get (p_msg_index      => i
                                       ,p_encoded        => 'E');
               END LOOP;

               lc_err_code       := '0015';
               lc_err_desc       := x_msg_data;
               lc_entity_ref     := 'Order_number';
               lc_entity_ref_id  := NVL(p_order_number,0);
               RAISE ex_failed;
            END IF;
         ELSE
            x_message := 'The Process Completed';
            x_status := 'Success';
         END IF;
      ELSE
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_COMBID_FAILED');
         lc_err_code := '0016';
         lc_err_desc := fnd_message.get;
         lc_entity_ref := 'Line ID';
         lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);
         RAISE ex_failed;
      END IF;
      END LOOP;
      COMMIT;
   EXCEPTION
      WHEN ex_failed
      THEN
         lr_rep_exp_type :=
            xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                      ,gc_track_code                    --'OTC'
                                      ,gc_solution_domain               --'Internal Fulfillment'
                                      ,gc_function                      --'I1153'
                                      ,lc_err_code
                                      ,lc_err_desc
                                      ,lc_entity_ref
                                      ,lc_entity_ref_id
                                     );
         xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                      ,x_err_buf
                                                      ,x_ret_code
                                                    );
         x_status := 'Failure';
         x_message := lc_err_desc;
         
      WHEN OTHERS
      THEN
         lc_err_desc := SUBSTR(lc_err_desc || '-' || SQLERRM,1000);
         lr_rep_exp_type :=
            xx_om_report_exception_t (gc_exception_header           --'OTHERS'
                                  ,gc_track_code                    --'OTC'
                                  ,gc_solution_domain               --'Internal Fulfillment'
                                  ,gc_function                      --'I1153'
                                  ,lc_err_code
                                  ,lc_err_desc
                                  ,lc_entity_ref
                                  ,lc_entity_ref_id
                                  );
         xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
	 x_status := 'Failure';
         x_message := lc_err_desc;
   END dps_conf_line_upd;

-----------------------------------------------------------------------
    -- Release Procedure
-- +===================================================================+
-- | Name  :DPS_HOLD_REL                                               |
-- | Description   : This Procedure will be used to update the         |
-- |                 sales order lines's attribute with                |
-- |                 'XX_OM_RECONCILED'		                       |
-- |                                                                   |
-- | Parameters :      p_order_number                                  |
-- |                   p_line_number                                   |
-- |                   p_item                                          |
-- |                   p_user_name                                     |
-- |                   p_resp_name                                     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :        x_status                                         |
-- |                  x_message                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE DPS_HOLD_REL (
      p_order_number   IN       oe_order_headers_all.order_number%TYPE
     ,p_line_id        IN       oe_order_lines_all.line_id%TYPE
     ,p_item           IN       oe_order_lines_all.ordered_item%TYPE
     ,p_user_name      IN       fnd_user.user_name%TYPE
     ,p_resp_name      IN       fnd_responsibility_tl.responsibility_name%TYPE
     ,x_status         OUT      VARCHAR2
     ,x_message        OUT      VARCHAR2
     )                 
   IS
      -- Variable Declaration

      lc_err_desc                xx_om_global_exceptions.description%TYPE
                                                             DEFAULT 'OTHERS';
      lc_entity_ref              xx_om_global_exceptions.entity_ref%TYPE;
      lc_entity_ref_id           xx_om_global_exceptions.entity_ref_id%TYPE;
      lc_err_code                xx_om_global_exceptions.ERROR_CODE%TYPE
                                                               DEFAULT '1001';
      ln_ordered_item            oe_order_lines_all.ordered_item%TYPE;
      lc_err_msg                 VARCHAR2 (200);
      ln_header_id               oe_order_headers_all.header_id%TYPE;
      ln_order_num               oe_order_headers_all.order_number%TYPE;
      lc_attr                    xx_om_lines_attributes_all.SEGMENT10%TYPE;
      lt_order_tbl               oe_holds_pvt.order_tbl_type;
      ln_hold_id                 oe_hold_definitions.hold_id%TYPE;
      ln_release_reason_code     oe_hold_releases.release_reason_code%TYPE;
      lc_release_comment         oe_hold_releases.release_comment%TYPE;
      lc_relhold_status          VARCHAR2 (10);
      ln_msg_count               NUMBER;
      lc_relhold_msg_data        VARCHAR2 (2000);
      lc_structure_id            xx_om_lines_attributes_all.structure_id%TYPE;
      lc_segment                 VARCHAR (4000);
      ln_combination_id          xx_om_lines_attributes_all.combination_id%TYPE;
      lt_update_line_tbl         oe_order_pub.line_tbl_type;
      lr_rep_exp_type            xx_om_report_exception_t;
      x_sts                      VARCHAR2(100);
      x_msg                      VARCHAR2(100);
      x_header_rec               oe_order_pub.header_rec_type;
      x_header_val_rec           oe_order_pub.header_val_rec_type;
      x_header_adj_tbl           oe_order_pub.header_adj_tbl_type;
      x_header_adj_val_tbl       oe_order_pub.header_adj_val_tbl_type;
      x_header_price_att_tbl     oe_order_pub.header_price_att_tbl_type;
      x_header_adj_att_tbl       oe_order_pub.header_adj_att_tbl_type;
      x_header_adj_assoc_tbl     oe_order_pub.header_adj_assoc_tbl_type;
      x_header_scredit_tbl       oe_order_pub.header_scredit_tbl_type;
      x_header_scredit_val_tbl   oe_order_pub.header_scredit_val_tbl_type;
      x_line_tbl                 oe_order_pub.line_tbl_type;
      x_line_val_tbl             oe_order_pub.line_val_tbl_type;
      x_line_adj_tbl             oe_order_pub.line_adj_tbl_type;
      x_line_adj_val_tbl         oe_order_pub.line_adj_val_tbl_type;
      x_line_price_att_tbl       oe_order_pub.line_price_att_tbl_type;
      x_line_adj_att_tbl         oe_order_pub.line_adj_att_tbl_type;
      x_line_adj_assoc_tbl       oe_order_pub.line_adj_assoc_tbl_type;
      x_line_scredit_tbl         oe_order_pub.line_scredit_tbl_type;
      x_line_scredit_val_tbl     oe_order_pub.line_scredit_val_tbl_type;
      x_lot_serial_tbl           oe_order_pub.lot_serial_tbl_type;
      x_lot_serial_val_tbl       oe_order_pub.lot_serial_val_tbl_type;
      x_action_request_tbl       oe_order_pub.request_tbl_type;
      x_return_status            VARCHAR2 (1000);
      x_msg_count                NUMBER (12);
      x_msg_data                 VARCHAR2 (2000);
      ex_failed                  EXCEPTION;
      ex_error                   EXCEPTION;
      x_err_buf                  VARCHAR2 (100);
      x_ret_code                 VARCHAR2 (100);

       CURSOR lcu_parent_lines_detail(p_parent_line_id xx_om_lines_attributes_all.segment14%TYPE )
       IS
       SELECT OOLA.line_id
        FROM  oe_order_lines_all OOLA      
             ,xx_om_lines_attributes_all XXOL
        WHERE OOLA.attribute6   = to_char(xxol.combination_id)                
          AND XXOL.segment14    = p_parent_line_id ;

   BEGIN
      -- Apps Initialisation
      x_status := 'Success';
      x_message := 'Success';

      -- Apps Initialisation
      XX_OM_DPS_APPS_INIT_PKG.DPS_APPS_INIT (    		   
				                        p_user_name       
				                       ,p_resp_name      
				                       ,x_sts
				                       ,x_msg
			                               );
     

      --Order number Validation
      
      IF p_order_number IS NULL
      THEN
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_NULL_INPUTORDER');
         lc_err_desc := fnd_message.get;
         lc_err_code := '0004';
         lc_entity_ref := 'Order_number';
         lc_entity_ref_id := 00000;
         RAISE ex_failed;
      ELSE
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_INVALIDORDERNUM');
         lc_err_desc := fnd_message.get;
         lc_err_code := '0005';
         lc_entity_ref := 'Order_Number';
         lc_entity_ref_id := NVL(p_order_number,0);

         SELECT OEH.order_number
           INTO ln_order_num
           FROM oe_order_headers_all OEH
          WHERE OEH.order_number = p_order_number;
      END IF;

    

      -- Fetching all the lines in the bundle and releasing holds.

      FOR  parent_lines_detail_rec_type IN lcu_parent_lines_detail(p_line_id )
      LOOP 
      --Attribute6 Validation
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_ATTR6NOTACCEPTED');
      lc_err_desc := fnd_message.get;
      lc_err_code := '0017';
      lc_entity_ref := 'Line ID';
      lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);

      SELECT NVL (segment10, 'XXX')
        INTO lc_attr
        FROM xx_om_lines_attributes_all xol, oe_order_lines_all oel
       WHERE oel.attribute6 = xol.combination_id
         AND oel.line_id = parent_lines_detail_rec_type.line_id;

      IF (lc_attr = gc_dpsConfStatus )
      THEN
         x_status := 'Success';
         
      ELSE
        
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_ATTR6NOTACCEPTED');
         lc_err_desc := fnd_message.get;
         lc_err_code := '0017';
         lc_entity_ref := 'Line ID';
         lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);
         RAISE ex_failed;
      END IF;

      --Hold Check
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_NO_HOLD');
      lc_err_desc := fnd_message.get;
      lc_err_code := '0018';
      lc_entity_ref := 'Line ID';
      lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);

      SELECT OHSA.hold_id                                          --   
            ,OOHO.header_id
      INTO ln_hold_id
            ,ln_header_id
      FROM oe_hold_definitions OHD
               ,oe_hold_sources_all OHSA
               ,oe_order_holds_all OOHO
      WHERE OHD.NAME = gc_hold_name                      
      AND OHD.hold_id = OHSA.hold_id
      AND OHSA.hold_source_id = OOHO.hold_source_id
      AND OOHO.released_flag = 'N'
      AND OOHO.line_id = parent_lines_detail_rec_type.line_id;
      
      --Calling Release Holds API
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_RELEASEHOLD');
      lc_err_desc := fnd_message.get;
      lc_err_code := '0019';
      lc_entity_ref := 'Order Number';
      lc_entity_ref_id := p_order_number;
      lt_order_tbl (1).header_id := ln_header_id;
      lt_order_tbl (1).line_id := NVL(parent_lines_detail_rec_type.line_id,0);
      
      oe_holds_pub.release_holds
         (p_api_version              => 1.0
         ,p_order_tbl                => lt_order_tbl
         ,p_hold_id                  => ln_hold_id
         ,p_release_reason_code      => gc_release_reason       
         ,p_release_comment          => gc_release_comment      
         ,x_return_status            => lc_relhold_status
         ,x_msg_count                => ln_msg_count
         ,x_msg_data                 => lc_relhold_msg_data
         );

      IF (lc_relhold_status = 'S')
      THEN
         
         x_status  := 'Success';
         x_message := 'Succefully Updated';
      ELSE
         IF ln_msg_count > 0
         THEN
            FOR i IN 1 .. ln_msg_count
            LOOP
               lc_relhold_msg_data :=
                          oe_msg_pub.get (p_msg_index      => i
                                         ,p_encoded        => 'E');
            END LOOP;
         END IF;

         lc_err_code := '0020';
         lc_err_desc := lc_relhold_msg_data;
         lc_entity_ref := 'Order_number';
         lc_entity_ref := NVL(p_order_number,0);
         RAISE ex_failed;
      END IF;

      --Extracting Segments for the Combination ID
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_SEGMENTS_EXTRC_FAIL');
      lc_err_code := '0012';
      lc_err_desc := fnd_message.get;
      lc_entity_ref := 'Line ID';
      lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);

      SELECT    segment6
             || '.'
             || segment7
             || '.'
             || segment8
             || '.'
             || segment5
             || '.'
             || segment3
             || '.'
             || segment2
             || '.'
             || segment4
             || '.'
             || segment9
             || '.'
             || gc_dspRelStatus        
             || '.'
             || segment11
             || '.'
             || segment12
             || '.'
             || segment13
             || '.'
             || segment14
             || '.'
             || segment15
             || '.'
             || segment20
             || '.'
             || segment18
             || '.'
             || segment19
             || '.'
             || segment16
             || '.'
             || segment17
             || '.'
             || segment21
             || '.'
             || segment22
             || '.'
             || segment23
             || '.'
             || segment24
             || '.'
             || segment25
             || '.'
             || segment26
             || '.'
             || segment27
             || '.'
             || segment28
             || '.'
             || segment29
             || '.'
             || segment30
            ,structure_id
        INTO lc_segment
            ,lc_structure_id
        FROM xx_om_lines_attributes_all xol, oe_order_lines_all ool
       WHERE TO_CHAR(xol.combination_id) = ool.attribute6             
         AND ool.line_id = NVL(parent_lines_detail_rec_type.line_id,0);

      --Generate Combination ID
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_COMBID_FAILED');
      lc_err_code := '0013';
      lc_err_desc := fnd_message.get;
      lc_entity_ref := 'Line ID';
      lc_entity_ref_id := NVL(p_line_id,0);
      ln_combination_id :=
         fnd_flex_ext.get_ccid ('XXOM'
                               ,'XXOL'
                               ,lc_structure_id
                               ,SYSDATE
                               ,lc_segment
                               );
      IF ln_combination_id <> 0
      THEN
         --Calling Process Order API
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_PROCESS_ORDER_FAIL');
         lc_err_code := '0014';
         lc_err_desc := fnd_message.get;
         lc_entity_ref := 'Order_number';
         lc_entity_ref_id := NVL(p_order_number,0);
        
         lt_update_line_tbl (1) := oe_order_pub.g_miss_line_rec;
         lt_update_line_tbl (1).line_id := parent_lines_detail_rec_type.line_id;
         lt_update_line_tbl (1).attribute6 := TO_CHAR (ln_combination_id);
         --'RECONCILED';
         lt_update_line_tbl (1).operation := oe_globals.g_opr_update;
         oe_order_pub.process_order
                       (p_api_version_number          => 1.0
                       ,p_init_msg_list               => fnd_api.g_false
                       ,p_return_values               => fnd_api.g_false
                       ,p_action_commit               => fnd_api.g_false
                       ,x_return_status               => x_return_status
                       ,x_msg_count                   => x_msg_count
                       ,x_msg_data                    => x_msg_data
                       ,p_line_tbl                    => lt_update_line_tbl
                       --in parameters
                       ,x_header_rec                  => x_header_rec
                       --out parameters
                       ,x_header_val_rec              => x_header_val_rec
                       ,x_header_adj_tbl              => x_header_adj_tbl
                       ,x_header_adj_val_tbl          => x_header_adj_val_tbl
                       ,x_header_price_att_tbl        => x_header_price_att_tbl
                       ,x_header_adj_att_tbl          => x_header_adj_att_tbl
                       ,x_header_adj_assoc_tbl        => x_header_adj_assoc_tbl
                       ,x_header_scredit_tbl          => x_header_scredit_tbl
                       ,x_header_scredit_val_tbl      => x_header_scredit_val_tbl
                       ,x_line_tbl                    => x_line_tbl
                       ,x_line_val_tbl                => x_line_val_tbl
                       ,x_line_adj_tbl                => x_line_adj_tbl
                       ,x_line_adj_val_tbl            => x_line_adj_val_tbl
                       ,x_line_price_att_tbl          => x_line_price_att_tbl
                       ,x_line_adj_att_tbl            => x_line_adj_att_tbl
                       ,x_line_adj_assoc_tbl          => x_line_adj_assoc_tbl
                       ,x_line_scredit_tbl            => x_line_scredit_tbl
                       ,x_line_scredit_val_tbl        => x_line_scredit_val_tbl
                       ,x_lot_serial_tbl              => x_lot_serial_tbl
                       ,x_lot_serial_val_tbl          => x_lot_serial_val_tbl
                       ,x_action_request_tbl          => x_action_request_tbl
                       );

         IF (x_return_status <> 'S')
         THEN
            IF x_msg_count > 0
            THEN
               FOR i IN 1 .. x_msg_count
               LOOP
                  x_msg_data :=
                        x_msg_data
                     || ' '
                     || oe_msg_pub.get (p_msg_index      => i
                                       ,p_encoded        => 'E');
               END LOOP;

               lc_err_code       := '0015';
               lc_err_desc       := x_msg_data;
               lc_entity_ref     := 'Order_number';
               lc_entity_ref_id  := NVL(p_order_number,0);
               RAISE ex_failed;
            END IF;
         ELSE
            x_message := 'The Process Completed';
            x_status := 'Success';
         END IF;
      ELSE
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_COMBID_FAILED');
         lc_err_code := '0016';
         lc_err_desc := fnd_message.get;
         lc_entity_ref := 'Line ID';
         lc_entity_ref_id := NVL(parent_lines_detail_rec_type.line_id,0);
         RAISE ex_failed;
      END IF;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN ex_failed
      THEN


         lr_rep_exp_type :=
            xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                      ,gc_track_code                    --'OTC'
                                      ,gc_solution_domain               --'Internal Fulfillment'
                                      ,gc_function                      --'I1153'
                                      ,lc_err_code
                                      ,lc_err_desc
                                      ,lc_entity_ref
                                      ,lc_entity_ref_id
                                     );
         
         xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
         x_status := 'Failure';
         x_message := lc_err_desc;
         
      WHEN OTHERS
      THEN
         lc_err_desc := lc_err_desc || '-' || SQLERRM;
	 lr_rep_exp_type :=
            xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                      ,gc_track_code                    --'OTC'
                                      ,gc_solution_domain               --'Internal Fulfillment'
                                      ,gc_function                      --'I1153'
                                      ,lc_err_code
                                      ,lc_err_desc
                                      ,lc_entity_ref
                                      ,lc_entity_ref_id
                                     );
        
         xx_om_global_exception_pkg.insert_exception (lr_rep_exp_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
	x_status := 'Failure';
         x_message := lc_err_desc;
   END dps_hold_rel;
END xx_om_dps_conf_rel_pkg;
/
SHOW ERROR
