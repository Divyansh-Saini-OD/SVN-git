SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_PO_CREATE_PUNCHOUT_REQ_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY xx_po_create_punchout_req_pkg
AS

  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_PO_CREATE_PUNCHOUT_REQ_PKG                                                      |
  -- |                                                                                            |
  -- |  Description:  This package is used to create the Purchase Orders automatically 			  | 
  -- |                for Puchout POs                                                             |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         01-SEP-2017  Suresh Naragam   Initial version                                  |
  -- +============================================================================================+

  gn_user_id             fnd_user.user_id%TYPE := NVL(fnd_profile.VALUE ('USER_ID'),'-1');
  gc_success             VARCHAR2(100)         := 'SUCCESS';
  gc_failure             VARCHAR2(100)         := 'FAILURE';
  gn_length              NUMBER                := 3000;
  gc_object_name         xx_com_error_log.error_location%TYPE := 'xx_po_create_punchout_req_pkg.create_purchase_requisition';
  gc_log_date_format     CONSTANT VARCHAR2(30) := 'DD-MON-RRRR HH24:MI:SS';

  --/**************************************************************
  --* This function returns the current time
  --***************************************************************/
  FUNCTION time_now
  RETURN VARCHAR2
  IS
   lc_time_string VARCHAR2(40);
  BEGIN
    SELECT TO_CHAR(SYSDATE, gc_log_date_format)
    INTO   lc_time_string
    FROM   DUAL;

    RETURN(lc_time_string);
  END time_now;

  --/*************************************************************
  --* This function logs message
  --*************************************************************/
  PROCEDURE log_msg(
    p_log_flag IN BOOLEAN DEFAULT FALSE,
    p_string   IN VARCHAR2)
  IS
  BEGIN
    IF (p_log_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG, time_now || ' : ' || p_string);
      DBMS_OUTPUT.put_line(SUBSTR(p_string, 1, 250));

      XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXPO'
      ,p_program_type            => 'DEBUG'              --------index exists on program_type
      ,p_attribute15             => gc_object_name          --------index exists on attribute15
      ,p_program_name           => 'XX_PO_CREATE_PUNCHOUT_REQ_PKG'
      ,p_program_id              => 0
      ,p_module_name             => 'PO'                --------index exists on module_name
      ,p_error_message           => p_string
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => gn_user_id
      ,p_last_updated_by         => gn_user_id
      ,p_last_update_login       => NULL --ln_login
      );
    END IF;
  END log_msg;

  --**************************************************************************/
  --* Description: Log the exceptions
  --**************************************************************************/
  PROCEDURE log_error (p_object_id     IN VARCHAR2,
                       p_error_msg     IN VARCHAR2)
   IS
   BEGIN
      xx_com_error_log_pub.log_error (p_return_code                 => fnd_api.g_ret_sts_error
                                    , p_msg_count                   => 1
                                    , p_application_name            => 'XX_PO'
                                    , p_program_type                => 'ERROR'
                                    , p_program_name                => 'XX_PO_CREATE_PUNCHOUT_REQ_PKG'
                                    , p_attribute15                 => 'XX_PO_CREATE_PUNCHOUT_REQ_PKG'          --------index exists on attribute15
                                    , p_program_id                  => NULL
                                    , p_object_id                   => p_object_id
                                    , p_module_name                 => 'PO'
                                    , p_error_location              => NULL --p_error_location
                                    , p_error_message_code          => NULL --p_error_message_code
                                    , p_error_message               => p_error_msg
                                    , p_error_message_severity      => 'MAJOR'
                                    , p_error_status                => 'ACTIVE'
                                    , p_created_by                  => gn_user_id
                                    , p_last_updated_by             => gn_user_id
                                    , p_last_update_login           => NULL --g_login_id
                                     );
   END log_error;

-- +===============================================================================================+
-- | Name  : get_translation_info                                                                  |
-- | Description     : This function returns the transaltion info for Punchout CONFIG Details      |
-- | Parameters      : pi_translation_name, pi_source_record, pi_target_record,                    |
-- |                   po_translation_info, po_error_msg                                           |
-- +================================================================================================+

  FUNCTION get_translation_info(pi_translation_name   IN  xx_fin_translatedefinition.translation_name%TYPE,
                                pi_source_record      IN  xx_fin_translatevalues.source_value1%TYPE,
                                pi_target_record      IN  xx_fin_translatevalues.target_value1%TYPE,
                                po_translation_info   OUT xx_fin_translatevalues%ROWTYPE,
                                po_error_msg          OUT VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    po_error_msg        := NULL;
    po_translation_info := NULL;

    SELECT xftv.*
    INTO po_translation_info
    FROM xx_fin_translatedefinition xft,
         xx_fin_translatevalues xftv
    WHERE xft.translate_id    = xftv.translate_id
    AND xft.enabled_flag      = 'Y'
    AND xftv.enabled_flag     = 'Y'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
    AND xft.translation_name  = pi_translation_name
    AND xftv.source_value1    = pi_source_record --'CONFIG_DETAILS'
    AND xftv.target_value1    = pi_target_record;

    RETURN gc_success;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       po_error_msg := 'No Translation info found for '||pi_translation_name||' - '||pi_source_record;
       log_msg(TRUE, po_error_msg);
       RETURN gc_failure;
     WHEN OTHERS
     THEN
       po_error_msg := 'Error while getting the trans info '|| substr(SQLERRM,1,2000);
       log_msg(TRUE, po_error_msg);
       RETURN gc_failure;
  END get_translation_info;
  
-- +===============================================================================================+
-- | Name  : get_translation_info                                                                  |
-- | Description     : This function returns the transaltion info for Punchout CONFIG Details      |
-- | Parameters      : pi_translation_name, pi_source_record1, pi_source_record2,                  |
-- |                   pi_source_record3, po_translation_info,po_error_msg                         |
-- +================================================================================================+

  FUNCTION get_translation_info(pi_translation_name   IN  xx_fin_translatedefinition.translation_name%TYPE,
                                pi_source_record1     IN  xx_fin_translatevalues.source_value1%TYPE,
                                pi_source_record2     IN  xx_fin_translatevalues.source_value2%TYPE,
                                pi_source_record3     IN  xx_fin_translatevalues.source_value3%TYPE,
                                po_translation_info   OUT xx_fin_translatevalues%ROWTYPE,
                                po_error_msg          OUT VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    po_error_msg        := NULL;
    po_translation_info := NULL;

    SELECT xftv.*
    INTO po_translation_info
    FROM xx_fin_translatedefinition xft,
         xx_fin_translatevalues xftv
    WHERE xft.translate_id    = xftv.translate_id
    AND xft.enabled_flag      = 'Y'
    AND xftv.enabled_flag     = 'Y'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
    AND xft.translation_name  = pi_translation_name   --XX_PO_VENDOR_UOM_MAP
    AND xftv.source_value1    = pi_source_record1      --Vendor Name
    AND xftv.source_value2    = pi_source_record2      --Vendor Name
    AND xftv.source_value3    = pi_source_record3;

   RETURN gc_success;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       po_error_msg := 'No Translation info found for '||pi_translation_name;
       log_msg(TRUE, po_error_msg);
       RETURN gc_failure;
     WHEN OTHERS
     THEN
       po_error_msg := 'Error while getting the trans info '|| substr(SQLERRM,1,2000);
       log_msg(TRUE, po_error_msg);
       RETURN gc_failure;
  END get_translation_info;
  
-- +===============================================================================================+
-- | Name  : get_item_info                                                                         |
-- | Description     : This function returns the item details                                      |
-- | Parameters      : p_item_name, p_organization_id, xx_item_info, xx_error_message              |
-- +================================================================================================+

  FUNCTION get_item_info (p_item_name          IN  mtl_system_items_b.segment1%TYPE,
                          p_organization_id   IN  mtl_system_items_b.organization_id%TYPE,
                          xx_item_info         OUT mtl_system_items_b%ROWTYPE,
                          xx_error_message    OUT  VARCHAR2)
  RETURN VARCHAR2
  IS
  lc_return_status     VARCHAR2(20) := NULL;

  BEGIN
    BEGIN
      xx_error_message     := NULL;
      xx_item_info         := NULL;

      SELEcT *
      INTO xx_item_info
      FROM mtl_system_items_b
      WHERE segment1       = p_item_name
      AND organization_id  = p_organization_id;

      lc_return_status  := gc_success;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        xx_error_message  := ' Inventory Item not found for item' || p_item_name || 'Organization id ' || p_organization_id ;
        lc_return_status  := gc_failure;
      WHEN OTHERS
      THEN
        xx_error_message  :=
          SUBSTR('error while getting the item info '||p_item_name || 'Organization id ' || p_organization_id ||SQLERRM,1,gn_length);
        lc_return_status  := gc_failure;
    END;

    RETURN lc_return_status;

  END get_item_info;
  
-- +=======================================================================================================+
-- | Name  : insert_po_req_distribution                                                                    |
-- | Description     : This procedure will load the data into PO Requisition distribution interface tables | 
-- | Parameters      : pi_dist_sequence_id, pi_req_line_rec, pi_dist_line_num, pi_req_quantity,            |
-- |                   pi_batch_id, pi_debug_flag, xx_error_message                                        |
-- +================================================================================================+
  FUNCTION insert_po_req_distribution( pi_dist_sequence_id   IN  po_req_dist_interface.dist_sequence_id%TYPE,
                                       pi_req_line_rec       IN  po_requisition_lines_all%ROWTYPE,
                                       pi_dist_line_num      IN  po_req_distributions_all.distribution_num%TYPE,
                                       pi_req_quantity       IN  po_requisitions_interface_all.quantity%TYPE,
                                       pi_batch_id           IN  NUMBER,
                                       pi_debug_flag         IN  BOOLEAN,
                                       xx_error_message     OUT VARCHAR2)

  RETURN VARCHAR2
  IS
   lc_return_status           VARCHAR2(100) := NULL;
   l_object_name              xx_com_error_log.error_location%TYPE := 'xx_po_create_punchout_req_pkg.insert_po_req_distribution';
   l_message_code             xx_com_error_log.error_message_code%TYPE := NULL;
   l_req_dist_intf_rec        po_req_dist_interface%ROWTYPE := NULL;

   e_process_exception       EXCEPTION;

   po_req_dist_rec           po_req_distributions_all%ROWTYPE;
  BEGIN
    BEGIN 
      SELECT prda.*
      INTO po_req_dist_rec
      FROM po_req_distributions_all prda
      WHERE requisition_line_id = pi_req_line_rec.requisition_line_id;
    EXCEPTION WHEN OTHERS THEN
      log_msg(pi_debug_flag, 'No Distribution Record Found  ..') ;
      xx_error_message := 'No Distribution Record Found the Requisition '||pi_req_line_rec.line_num;
      RAISE e_process_exception;
    END;

    log_msg(pi_debug_flag, 'Inserting the Requisition Distribution Records  ..') ;

    l_req_dist_intf_rec.dist_sequence_id            := pi_dist_sequence_id;
    l_req_dist_intf_rec.distribution_number         := pi_dist_line_num;
    l_req_dist_intf_rec.quantity                    := pi_req_quantity;
    l_req_dist_intf_rec.charge_account_id           := po_req_dist_rec.code_combination_id;
    l_req_dist_intf_rec.project_id                  := po_req_dist_rec.project_id;
    l_req_dist_intf_rec.task_id                     := po_req_dist_rec.task_id;
    l_req_dist_intf_rec.expenditure_type            := po_req_dist_rec.expenditure_type;
    l_req_dist_intf_rec.expenditure_organization_id := po_req_dist_rec.expenditure_organization_id;
    l_req_dist_intf_rec.destination_type_code       := pi_req_line_rec.destination_type_code;  
    l_req_dist_intf_rec.destination_organization_id := pi_req_line_rec.destination_organization_id; 
    --l_req_dist_intf_rec.interface_source_code       := 'INV'; --null;
    l_req_dist_intf_rec.interface_source_code       := substr(pi_req_line_rec.supplier_duns,instr(pi_req_line_rec.supplier_duns,'-',1)+1);
    l_req_dist_intf_rec.batch_id                    := pi_batch_id;
    l_req_dist_intf_rec.project_accounting_context  := po_req_dist_rec.project_accounting_context;
    l_req_dist_intf_rec.expenditure_item_date       := po_req_dist_rec.expenditure_item_date;
    l_req_dist_intf_rec.org_id                      := pi_req_line_rec.org_id;
    l_req_dist_intf_rec.creation_date               := SYSDATE;
    l_req_dist_intf_rec.created_by                  := gn_user_id;
    l_req_dist_intf_rec.last_update_date            := SYSDATE ;
    l_req_dist_intf_rec.last_updated_by             := gn_user_id;

    INSERT INTO po_req_dist_interface_all
    VALUES l_req_dist_intf_rec;

    lc_return_status  := gc_success;

    RETURN lc_return_status;
  EXCEPTION
    WHEN OTHERS
    THEN
      IF xx_error_message IS NULL
      THEN
        xx_error_message  := SUBSTR('Unable to insert into Po distributions interface table ' || SQLERRM,1,gn_length);
      END IF;
      lc_return_status  := gc_failure;

    RETURN lc_return_status;
  END insert_po_req_distribution;

-- +=======================================================================================================+
-- | Name  : insert_po_req_line                                                                            |
-- | Description     : This procedure will load the data into PO Requisition Lines interface tables        |
-- | Parameters      : pi_req_header_rec, pi_req_line_rec, pi_req_line_num, pi_vendor_site_info,           |
-- |                   pi_translation_rec, pi_req_batch_id, pi_debug_flag, xx_error_message                |
-- +=======================================================================================================+

  FUNCTION insert_po_req_line( pi_req_header_rec         IN  xx_po_req_hdr_rec%TYPE,
                               pi_req_line_rec           IN  po_requisition_lines_all%ROWTYPE,
                               pi_req_line_num           IN  po_requisition_lines_all.line_num%TYPE,
                               pi_vendor_site_info       IN  po_vendor_sites_all%ROWTYPE,
                               pi_translation_rec        IN  xx_fin_translatevalues%ROWTYPE,
                               pi_req_batch_id           IN  NUMBER,
                               pi_debug_flag             IN  BOOLEAN,
                               xx_error_message          OUT VARCHAR2)

  RETURN VARCHAR2
  IS
   lc_status                 VARCHAR2(100) := NULL;
   l_message_code            xx_com_error_log.error_message_code%TYPE := NULL;
   l_po_req_intf_rec         po_requisitions_interface%ROWTYPE := NULL;
   ln_dist_sequence_id       po_requisitions_interface.req_dist_sequence_id%TYPE;
   l_item_rec                mtl_system_items_b%ROWTYPE := NULL;
   ln_category_id            mtl_item_categories.category_id%TYPE := NULL;

   e_process_exception       EXCEPTION;
   lc_translation_info       xx_fin_translatevalues%ROWTYPE;
   lc_source_org_name        org_organization_definitions.organization_name%TYPE;
   lc_error_message          VARCHAR2(4000)  := NULL;
   
  BEGIN

    log_msg(pi_debug_flag , pi_translation_rec.target_value10||' - '||pi_req_line_rec.suggested_vendor_product_code);
    log_msg(pi_debug_flag , pi_req_line_rec.unit_meas_lookup_code);
    lc_status := get_translation_info( pi_translation_name => 'XX_PO_VENDOR_UOM_MAP',
                                       pi_source_record1   => pi_translation_rec.target_value10,              -- Vendor Name
                                       pi_source_record2   => pi_req_line_rec.suggested_vendor_product_code,  -- SKU Number
                                       pi_source_record3   => pi_req_line_rec.unit_meas_lookup_code,          -- BSD UOM Code 
                                       po_translation_info => lc_translation_info,
                                       po_error_msg        => xx_error_message);
									   
    IF xx_error_message IS NOT NULL
    THEN
      xx_error_message := 'UOM Tranlations are not defined for '||pi_translation_rec.target_value10||' ,BSD UOM Code: '||pi_req_line_rec.unit_meas_lookup_code;
      RAISE e_process_exception;
    END IF;
	
	log_msg(pi_debug_flag , 'Getting the iProcurement Item Data for BSD Item: '||pi_req_line_rec.suggested_vendor_product_code);
	
	lc_status := get_item_info (p_item_name         => lc_translation_info.target_value2 ,
                                p_organization_id   => pi_req_line_rec.destination_organization_id,
                                xx_item_info        => l_item_rec,
                                xx_error_message    => xx_error_message);

    IF (lc_status != gc_success)
    THEN
      RAISE e_process_exception;
    END IF;
	
    IF lc_translation_info.source_value3 != lc_translation_info.target_value1    --source_value3 is BSD UOM, target_value1 is Vendor UOM,
    THEN
      l_po_req_intf_rec.unit_of_measure := lc_translation_info.target_value1;    --target_value1 is Vendor UOM,
      l_po_req_intf_rec.quantity := ceil (pi_req_line_rec.quantity/lc_translation_info.source_value4);   --source_value4 is BSD Qty
    ELSE
      l_po_req_intf_rec.unit_of_measure := pi_req_line_rec.unit_meas_lookup_code;
      l_po_req_intf_rec.quantity := pi_req_line_rec.quantity;
    END IF;
    
    -- Getting Distribution Sequence Id
    SELECT po_req_dist_interface_s.nextval
    INTO ln_dist_sequence_id
    FROM DUAL;
    
    l_po_req_intf_rec.autosource_flag            := 'Y';	
    l_po_req_intf_rec.req_dist_sequence_id       := ln_dist_sequence_id;
    l_po_req_intf_rec.requisition_type           := 'PURCHASE';
    l_po_req_intf_rec.preparer_id                := pi_req_header_rec.preparer_id;
    --l_po_req_intf_rec.interface_source_code      := 'INV';
    l_po_req_intf_rec.interface_source_code      := substr(pi_req_line_rec.supplier_duns,instr(pi_req_line_rec.supplier_duns,'-',1)+1);
    l_po_req_intf_rec.group_code                 := pi_req_header_rec.segment1;
    l_po_req_intf_rec.source_type_code           := 'VENDOR';
    l_po_req_intf_rec.line_attribute10           := pi_req_line_rec.supplier_duns;   -- Supplier Duns Number
    
    l_po_req_intf_rec.deliver_to_requestor_id    := pi_req_header_rec.preparer_id;
    l_po_req_intf_rec.destination_type_code      := pi_req_line_rec.destination_type_code;
    l_po_req_intf_rec.authorization_status       := pi_req_header_rec.authorization_status;
    l_po_req_intf_rec.header_description         := 'Previous Buy From Ourselves Req #:'||pi_req_header_rec.segment1;
    l_po_req_intf_rec.line_type                  := pi_req_line_rec.line_type_id;
    l_po_req_intf_rec.item_id                    := l_item_rec.inventory_item_id;
    l_po_req_intf_rec.item_description           := l_item_rec.description;
    l_po_req_intf_rec.need_by_date               := sysdate + NVL(pi_translation_rec.target_value14,0);
    l_po_req_intf_rec.suggested_buyer_id         := pi_req_line_rec.suggested_buyer_id;
    l_po_req_intf_rec.suggested_vendor_id        := pi_vendor_site_info.vendor_id;
    l_po_req_intf_rec.suggested_vendor_site_id   := pi_vendor_site_info.vendor_site_id;
    l_po_req_intf_rec.suggested_vendor_site      := pi_vendor_site_info.vendor_site_code;
    l_po_req_intf_rec.deliver_to_location_id     := pi_req_line_rec.deliver_to_location_id;
    l_po_req_intf_rec.destination_organization_id:= pi_req_line_rec.destination_organization_id;
    --l_po_req_intf_rec.multi_distributions        := 'Y';
    l_po_req_intf_rec.batch_id                   := pi_req_batch_id;
    l_po_req_intf_rec.org_id                     := pi_req_line_rec.org_id;
    --l_po_req_intf_rec.line_num                   := pi_req_line_num;
    --l_po_req_intf_rec.interface_source_line_id   := pi_req_line_num;
    l_po_req_intf_rec.note_to_buyer              := NULL;--'Previous Buy From Ourselves Req #:'||pi_req_header_rec.segment1;
    l_po_req_intf_rec.item_segment1              := pi_req_line_rec.suggested_vendor_product_code;  -- SKU Number
    l_po_req_intf_rec.creation_date              := SYSDATE;
    l_po_req_intf_rec.created_by                 := gn_user_id;
    l_po_req_intf_rec.last_update_date           := SYSDATE ;
    l_po_req_intf_rec.last_updated_by            := gn_user_id;

    log_msg(pi_debug_flag , 'Inserting the records into po requisitions interface ');
	
    INSERT INTO po_requisitions_interface_all
    VALUES      l_po_req_intf_rec;

    IF (lc_status != gc_success)
    THEN
      RAISE e_process_exception;
    END IF;

    log_msg(pi_debug_flag , 'Calling Insert PO Distribution for line interface line id '|| ln_dist_sequence_id);

    lc_status := insert_po_req_distribution(pi_dist_sequence_id    => ln_dist_sequence_id,
                                            pi_req_line_rec        => pi_req_line_rec,
                                            pi_dist_line_num       => pi_req_line_num,
                                            pi_req_quantity        => l_po_req_intf_rec.quantity,
                                            pi_batch_id            => pi_req_batch_id,
                                            pi_debug_flag          => pi_debug_flag,
                                            xx_error_message       => xx_error_message);

    IF (lc_status != gc_success)
    THEN
      RAISE e_process_exception;
    END IF;

    lc_status  := gc_success;

    RETURN lc_status;
  EXCEPTION
    WHEN OTHERS
    THEN
      IF xx_error_message IS NULL
      THEN
        xx_error_message  := SUBSTR('Unable to insert into Po lines interface table ' || SQLERRM,1,gn_length);
      END IF;
      lc_status  := gc_failure;

    RETURN lc_status;
  END insert_po_req_line;

-- +=======================================================================================================+
-- | Name  : get_vendor_site_info                                                                          |
-- | Description     : This Function used to get the Vendor Site Details                                   |
-- | Parameters      : pi_tranlation_rec,  x_vendor_site_rec,  x_error_message                             |
-- +=======================================================================================================+

  FUNCTION get_vendor_site_info(pi_tranlation_rec   IN  xx_fin_translatevalues%ROWTYPE,
                                x_vendor_site_rec   OUT  po_vendor_sites_all%ROWTYPE,
                                x_error_message     OUT  VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_return_status     VARCHAR2(20) := NULL;
  ln_vendor_id         po_vendor_sites_all.vendor_id%TYPE := NULL;

  BEGIN
    BEGIN
      x_error_message          := NULL;
      x_vendor_site_rec        := NULL;
	  
      SELECT pv.vendor_id
      INTO ln_vendor_id
      FROM po_vendors pv
      WHERE vendor_name = trim(pi_tranlation_rec.target_value10);

      SELECT *
      INTO x_vendor_site_rec
      FROM po_vendor_sites_all
      WHERE vendor_id      = ln_vendor_id
      AND vendor_site_code   = trim(pi_tranlation_rec.target_value11)
      AND ( inactive_date IS NULL OR inactive_date >= SYSDATE ) ;

      lc_return_status  := gc_success;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        x_error_message  := 'Vendor details not found ';
        lc_return_status  := gc_failure;

      WHEN OTHERS
      THEN
        x_error_message  := SUBSTR('error while getting the Vendor details '|| SQLERRM, 1, gn_length);
        lc_return_status  := gc_failure;
    END;
    RETURN lc_return_status;

  END get_vendor_site_info;

  -- +=======================================================================================================+
  -- | Name  : get_vendor_info                                                                               |
  -- | Description     : This Function used to get the Vendor Info                                           |
  -- | Parameters      : pi_translation_rec,  pi_debug_flag, xx_vendor_site_rec, x_error_message             |
  -- +=======================================================================================================+

  FUNCTION get_vendor_info(pi_translation_rec        IN  xx_fin_translatevalues%ROWTYPE,
                           pi_debug_flag             IN  BOOLEAN,
                           xx_vendor_site_rec        OUT po_vendor_sites_all%ROWTYPE,
                           xx_error_message          OUT VARCHAR2)

  RETURN VARCHAR2
  IS
    lc_status           VARCHAR2(100) := gc_success;
    e_process_exception EXCEPTION;

  BEGIN

    lc_status := get_vendor_site_info(pi_tranlation_rec   =>  pi_translation_rec,
	                              x_vendor_site_rec   =>  xx_vendor_site_rec,
                                      x_error_message     =>  xx_error_message);

    IF (lc_status != gc_success)
    THEN
      RAISE e_process_exception;
    END IF;

    RETURN lc_status;

  EXCEPTION
    WHEN OTHERS
    THEN
      IF xx_error_message IS NULL
      THEN
        xx_error_message :=  SUBSTR('Error While getting the header info'||SQLERRM , 1, gn_length);
      END IF;
      RETURN gc_failure;
  END get_vendor_info ;

  -- +=======================================================================================================+
  -- | Name  : create_purchase_requisition                                                                   |
  -- | Description     : This is the Main Procedure to create the Purchase Requisition.                      |  
  -- |                   This procedure will be called from PO Punchout packages.                            |
  -- | Parameters      : po_req_return_status,  po_req_return_message, pi_debug_flag, pi_batch_id,           |
  -- |                   pi_req_header_rec, pi_req_line_detail_tab                                           |
  -- +=======================================================================================================+
  
 PROCEDURE create_purchase_requisition(po_req_return_status      OUT VARCHAR2,
                                       po_req_return_message     OUT VARCHAR2,
                                       po_submit_req_import      OUT VARCHAR2,
                                       pi_debug_flag             IN  BOOLEAN,
                                       pi_batch_id               IN  NUMBER,
                                       pi_req_header_rec         IN  xx_po_req_hdr_rec%TYPE,
                                       pi_req_line_detail_tab    IN  xx_po_req_line_tbl%TYPE,
                                       pi_translation_info       IN  xx_fin_translatevalues%ROWTYPE
 )
  AS
   lc_error_message           xx_com_error_log.error_message%TYPE;
   lc_return_status           VARCHAR2(100);
   lc_status                  VARCHAR2(100) := NULL;
   lc_debug_flag              BOOLEAN;
   lc_prev_po_number          po_headers_all.segment1%TYPE  := NULL;
   l_message_code             xx_com_error_log.error_message_code%TYPE := NULL;
   l_line_number              NUMBER := 0;
   ln_pos_loaded              NUMBER := 0;
   
   lr_vendor_info             po_vendors%ROWTYPE           := NULL;
   lr_vendor_site_info        po_vendor_sites_all%ROWTYPE  := NULL;

   lr_lines_rec               po_requisition_lines_all%ROWTYPE;
   ln_req_line_num            po_requisition_lines_all.line_num%TYPE;

   e_header_exception         EXCEPTION;
   lc_translation_info        xx_fin_translatevalues%ROWTYPE;

  BEGIN

    lc_debug_flag := pi_debug_flag;
    ln_req_line_num := 1;

    log_msg(lc_debug_flag, 'Requisition Number: '||pi_req_header_rec.segment1||' - '||' Lines Count: '||pi_req_line_detail_tab.COUNT);
    IF pi_req_header_rec.segment1 IS NOT NULL AND pi_req_line_detail_tab.COUNT>0
    THEN
       log_msg(lc_debug_flag, 'Process request for Requisition number  ..'||pi_req_header_rec.segment1);

       FOR i in pi_req_line_detail_tab.first..pi_req_line_detail_tab.last
       LOOP
         BEGIN
           lr_lines_rec := pi_req_line_detail_tab(i);
		   
           log_msg(lc_debug_flag, 'Getting the Vendor info for Requisition Number..'||pi_req_header_rec.segment1||' Requisition Number: '||lr_lines_rec.line_num);
             
           lc_return_status := get_vendor_info(pi_translation_rec          => pi_translation_info,
                                               pi_debug_flag               => lc_debug_flag,
                                               xx_vendor_site_rec          => lr_vendor_site_info,
                                               xx_error_message            => lc_error_message);

           IF (lc_return_status != gc_success)
           THEN
             RAISE e_header_exception;
           END IF;

           log_msg (lc_debug_flag, 'Calling Insert PO Requisition line for Line number '||lr_lines_rec.line_num );

           lc_return_status := insert_po_req_line(pi_req_header_rec        => pi_req_header_rec,
                                                  pi_req_line_rec          => lr_lines_rec,
                                                  pi_req_line_num          => ln_req_line_num,
                                                  pi_vendor_site_info      => lr_vendor_site_info,
                                                  pi_translation_rec       => pi_translation_info,
                                                  pi_req_batch_id          => pi_batch_id,
                                                  pi_debug_flag            => lc_debug_flag,
                                                  xx_error_message         => lc_error_message); 

            IF (lc_return_status != gc_success)
            THEN
              RAISE e_header_exception;
            END IF;
            ln_req_line_num := ln_req_line_num + 1;
            po_submit_req_import := 'Y';
         EXCEPTION
           WHEN OTHERS
           THEN
             log_msg (lc_debug_flag, 'Error '|| SQLERRM);
             po_submit_req_import := 'N';
             RAISE e_header_exception;
         END;
       END LOOP; -- line tab
    END IF;-- count

    log_msg(lc_debug_flag ,' Commit the changes');
    COMMIT ;
  EXCEPTION
    WHEN OTHERS
    THEN
      log_msg(lc_debug_flag, 'Rollback the changes ..');
      ROLLBACK;
      IF lc_error_message  IS NULL
      THEN
        lc_error_message := SUBSTR('Error While creating the purchase requisition '||pi_req_header_rec.segment1||' '||SQLERRM , 1,300);
      END IF;
      log_error(p_object_id      => NULL,
                p_error_msg      => lc_error_message);

      log_msg (TRUE,lc_error_message);

      po_req_return_status  := gc_failure;
      po_req_return_message := lc_error_message;
      po_submit_req_import := 'N';

  END create_purchase_requisition;
  
  FUNCTION get_inteface_error_msg(pi_request_id     IN NUMBER,
                                  pi_batch_id       IN NUMBER,
                                  pi_transaction_id IN NUMBER)
  RETURN VARCHAR2
  IS
   lc_interface_err_msg VARCHAR2(32000);
  BEGIN
    FOR req_int_errors IN (
      SELECT distinct 'Request ID: '||request_id||' - '||ltrim(SUBSTR(ERROR_MESSAGE,(INSTR(ERROR_MESSAGE,':',1,1)+2),(INSTR(ERROR_MESSAGE,'Action:',1,1)-(INSTR(ERROR_MESSAGE,':',1,1)+2)))) req_int_error_message 
      FROM po_interface_errors
      WHERE request_id = pi_request_id
      AND batch_id = pi_batch_id
      AND interface_transaction_id = pi_transaction_id)
	LOOP
	  lc_interface_err_msg:= req_int_errors.req_int_error_message;
	END LOOP;

    RETURN lc_interface_err_msg;
  EXCEPTION WHEN OTHERS THEN
    lc_interface_err_msg := 'Error while getting Interface Errors';
    RETURN lc_interface_err_msg;
  END;
  
  -- +=======================================================================================================+
  -- | Name  : send_req_import_errors                                                                        |
  -- | Description     : This Procedure will email the Requisition import Errors                             |
  -- | Parameters      : errbuf,  retcode                                                                    |
  -- +=======================================================================================================+

  PROCEDURE send_req_import_errors(errbuf     OUT VARCHAR2,
                                   retcode    OUT VARCHAR2)
  IS
   lc_status                 VARCHAR2(100) := NULL;
   lc_error_message          VARCHAR2(2000) := NULL;
   e_process_exception       EXCEPTION;
   lc_translation_info       xx_fin_translatevalues%ROWTYPE;
   lc_req_mail_body          VARCHAR2(32000) := NULL;
   lc_int_mail_body          VARCHAR2(32000) := NULL;
   lc_int_mail_subject VARCHAR2(32000);
   lc_int_body_hdr     VARCHAR2(32000);
   lc_int_body_trl     VARCHAR2(32000);
   lc_req_mail_subject VARCHAR2(32000);
   lc_req_body_hdr     VARCHAR2(32000);
   lc_req_body_trl     VARCHAR2(32000);
   
   lc_cur_req_num            po_requisition_headers_all.segment1%TYPE;
   lc_prev_req_num           po_requisition_headers_all.segment1%TYPE;
   lc_supplier_duns          po_requisition_lines_all.supplier_duns%TYPE;
   
   CURSOR c_req_errors IS
   SELECT distinct group_code requisition_number, 
          pap.first_name||' '||pap.last_name Requestor, 
          pria.line_num, 
          pria.item_segment1, 
          pria.item_description, 
          pria.quantity, 
          hr.description,
          pria.line_attribute10,
          pria.request_id,
          pria.batch_id,
          pria.transaction_id,
          pria.preparer_id
   FROM po_interface_errors pie, 
        po_requisitions_interface_all pria,
        per_all_people_f pap,
        hr_locations_all hr
   WHERE 1=1 
   AND pie.creation_date > ( SELECT max(fcr.request_date)
                             FROM fnd_concurrent_programs_tl fcpt,
                                  fnd_concurrent_requests fcr
                             WHERE fcpt.user_concurrent_program_name = 'OD: Notify Punchout PO Requsition Import Errors'
                             AND fcpt.concurrent_program_id = fcr.concurrent_program_id
                             AND fcr.phase_code = 'C'
                             AND fcr.status_code = 'C')
   AND pie.interface_type = 'REQIMPORT'
   --AND pria.interface_source_code = 'INV'
   AND pria.source_type_code = 'VENDOR'
   AND pie.interface_transaction_id = pria.transaction_id
   AND pria.preparer_id = pap.person_id (+)
   AND pria.deliver_to_location_id = hr.location_id (+)
   AND pria.line_attribute10 IN (SELECT xftv.target_value1
                                 FROM xx_fin_translatedefinition xft,
                                      xx_fin_translatevalues xftv
                                 WHERE xft.translate_id    = xftv.translate_id
                                 AND xft.enabled_flag      = 'Y'
                                 AND xftv.enabled_flag     = 'Y'
                                 AND TRUNC(SYSDATE) BETWEEN TRUNC(xftv.start_date_active) AND TRUNC(NVL(xftv.end_date_active,SYSDATE+1))
                                 AND xft.translation_name  = 'XXPO_PUNCHOUT_CONFIG'
                                 AND xftv.source_value1    = 'SUPPLIER_DUNS')
   ORDER BY 1;
   lr_req_errors          c_req_errors%ROWTYPE;
   lc_interface_err_msg   VARCHAR2(32000);
   l_req_info             per_people_v7%ROWTYPE;
    
  BEGIN

    log_msg(TRUE, 'Sending the Mail with Requistion Import Errors');
      
    lc_req_mail_body := NULL;
    lc_int_mail_body := NULL;
    log_msg(TRUE, 'Getting the Import Errors.');
	   
    OPEN c_req_errors;
	LOOP
	  FETCH c_req_errors INTO lr_req_errors;
      lc_cur_req_num := lr_req_errors.requisition_number;
	  log_msg(TRUE, 'Requisition Number: ' ||lc_cur_req_num);

      IF lc_cur_req_num != lc_prev_req_num OR c_req_errors%NOTFOUND THEN
        IF c_req_errors%NOTFOUND THEN
		  lc_prev_req_num := lc_cur_req_num;  -- Last Record
		END IF;

        log_msg(TRUE, 'Supplier Duns Number is: ' ||lr_req_errors.line_attribute10);  
        lc_status := get_translation_info( pi_translation_name => 'XXPO_PUNCHOUT_CONFIG',
                                           pi_source_record    => 'SUPPLIER_DUNS',
                                           pi_target_record    => lc_supplier_duns,
                                           po_translation_info => lc_translation_info,
                                           po_error_msg        => lc_error_message);
		IF lc_req_mail_body IS NOT NULL AND NVL(lc_translation_info.target_value8,'N') = 'Y' THEN
		  
          -- Getting Mail Body Header
						   
          lc_req_mail_subject := NULL;
          lc_req_body_hdr := NULL;
          lc_req_body_trl := NULL;
	
          -- Getting Mail Subject and body for Requestor.
          xx_po_punchout_conf_pkg.get_mailing_info(pi_template           => lc_translation_info.target_value21,
                     pi_requisition_number => lc_prev_req_num,
                     pi_po_number          => NULL,
                     pi_aops_number        => NULL,
                     po_mail_subject       => lc_req_mail_subject,
                     po_mail_body_hdr      => lc_req_body_hdr,
                     po_mail_body_trl      => lc_req_body_trl,
                     pi_translation_info   => lc_translation_info);
	
          lc_int_mail_subject := NULL;
          lc_int_body_hdr := NULL;
          lc_int_body_trl := NULL;

          -- Getting Mail Subject and body for Internal Team.	
          xx_po_punchout_conf_pkg.get_mailing_info(pi_template           => lc_translation_info.target_value20,
                     pi_requisition_number => lc_prev_req_num,
                     pi_po_number          => NULL,
                     pi_aops_number        => NULL,
                     po_mail_subject       => lc_int_mail_subject,
                     po_mail_body_hdr      => lc_int_body_hdr,
                     po_mail_body_trl      => lc_int_body_trl,
                     pi_translation_info   => lc_translation_info);
					 
          log_msg(TRUE, 'Getting the Requestor Info, Requestor Name, Requestor Email ');
	      lc_status := xx_po_punchout_conf_pkg.get_requestor_info (pi_preparer_id     => lr_req_errors.preparer_id ,
                                                                   xx_requestor_info  => l_req_info,
                                                                   xx_error_message   => lc_error_message);

          IF lc_error_message IS NOT NULL
          THEN
            RAISE e_process_exception;
          END IF;	
			  
          log_msg(TRUE, 'Sending the Mail with Req Import Errors.');

          -- Sending Mail to Requestor 		   
          xx_po_punchout_conf_pkg.send_mail(pi_mail_subject       =>  lc_req_mail_subject,
                                            pi_mail_body          =>  lc_req_body_hdr||lc_req_mail_body||lc_req_body_trl,
                                            pi_mail_sender        =>  lc_translation_info.target_value3,
                                            pi_mail_recipient     =>  l_req_info.email_address,
                                                                      --lc_translation_info.target_value17,										
                                            pi_mail_cc_recipient  =>  NULL,  --lc_translation_info.target_value18,
                                            po_return_msg         =>  lc_error_message);
           IF lc_error_message IS NOT NULL
           THEN
             RAISE e_process_exception ;
           END IF;
           lc_req_mail_body := NULL;
		   
           -- Sending Mail to Internal/AMS Team 		   
           xx_po_punchout_conf_pkg.send_mail(pi_mail_subject       =>  lc_int_mail_subject,
                                             pi_mail_body          =>  lc_int_body_hdr||lc_int_mail_body||lc_int_body_trl,
                                             pi_mail_sender        =>  lc_translation_info.target_value3,
                                             pi_mail_recipient     =>  lc_translation_info.target_value4,
                                             pi_mail_cc_recipient  =>  lc_translation_info.target_value5,
                                             po_return_msg         =>  lc_error_message);
           IF lc_error_message IS NOT NULL
           THEN
             RAISE e_process_exception ;
           END IF;
           lc_int_mail_subject := NULL;
           lc_int_body_hdr := NULL;
           lc_int_mail_body := NULL;
           lc_int_body_trl := NULL;
		   lc_req_mail_subject := NULL;
           lc_req_body_hdr := NULL;
           lc_req_mail_body := NULL;
           lc_req_body_trl := NULL;
        END IF;
		log_msg(TRUE, 'Getting Mail Body.');
        lc_req_mail_body := lc_req_mail_body||xx_po_punchout_conf_pkg.get_mail_body (
                                                             lc_translation_info.target_value21,
		                                                     lr_req_errors.requisition_number,
                                                             lr_req_errors.Requestor,
										                     lr_req_errors.line_num,
										                     lr_req_errors.item_segment1,
										                     lr_req_errors.item_description,
										                     lr_req_errors.quantity,
										                     lr_req_errors.description,
															 NULL, NULL);
															 
        lc_int_mail_body := lc_int_mail_body||xx_po_punchout_conf_pkg.get_mail_body (
                                                             lc_translation_info.target_value20,
		                                                     lr_req_errors.requisition_number,
                                                             lr_req_errors.Requestor,
										                     lr_req_errors.line_num,
										                     lr_req_errors.item_segment1,
										                     lr_req_errors.item_description,
										                     lr_req_errors.quantity,
										                     lr_req_errors.description,
															 get_inteface_error_msg(lr_req_errors.request_id,
                                                                                    lr_req_errors.batch_id,
                                                                                    lr_req_errors.transaction_id), 
                                                             NULL);
      ELSE
        log_msg(TRUE, 'Getting Mail Body Else.');
        log_msg(TRUE, 'Supplier Duns Number is: ' ||lr_req_errors.line_attribute10);  
        lc_status := get_translation_info( pi_translation_name => 'XXPO_PUNCHOUT_CONFIG',
                                           pi_source_record    => 'SUPPLIER_DUNS',
                                           pi_target_record    => lr_req_errors.line_attribute10,
                                           po_translation_info => lc_translation_info,
                                           po_error_msg        => lc_error_message);
										   
		log_msg(TRUE, lc_translation_info.target_value21||' - '||lr_req_errors.requisition_number
		              ||lr_req_errors.Requestor||' - '||lr_req_errors.line_num);
	    lc_req_mail_body := lc_req_mail_body||xx_po_punchout_conf_pkg.get_mail_body (
                                                             lc_translation_info.target_value21,
		                                                     lr_req_errors.requisition_number,
                                                             lr_req_errors.Requestor,
										                     lr_req_errors.line_num,
										                     lr_req_errors.item_segment1,
										                     lr_req_errors.item_description,
										                     lr_req_errors.quantity,
										                     lr_req_errors.description,
															 NULL, NULL);
															 
		lc_int_mail_body := lc_int_mail_body||xx_po_punchout_conf_pkg.get_mail_body (
                                                             lc_translation_info.target_value20,
		                                                     lr_req_errors.requisition_number,
                                                             lr_req_errors.Requestor,
										                     lr_req_errors.line_num,
										                     lr_req_errors.item_segment1,
										                     lr_req_errors.item_description,
										                     lr_req_errors.quantity,
										                     lr_req_errors.description,
															 get_inteface_error_msg(lr_req_errors.request_id,
                                                                                    lr_req_errors.batch_id,
                                                                                    lr_req_errors.transaction_id),
                                                             NULL);
      END IF;

      lc_prev_req_num := lr_req_errors.requisition_number;
      lc_supplier_duns := lr_req_errors.line_attribute10;

      EXIT WHEN c_req_errors%NOTFOUND;
	END LOOP;
	   
  EXCEPTION
  WHEN OTHERS
  THEN
      IF lc_error_message IS NULL
      THEN
        lc_error_message  := SUBSTR('Unable to send the Requisition Import Errors ' || SQLERRM,1,gn_length);
      END IF;
      retcode := 1;
  END send_req_import_errors;  

END xx_po_create_punchout_req_pkg;
/

SHOW ERR