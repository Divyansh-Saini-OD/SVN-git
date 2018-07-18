CREATE OR REPLACE PACKAGE BODY APPS.xx_cs_mps_po_create_pkg
AS

--+=============================================================================================+
--/*                     Office Depot - MPS PO
--/*
-- +=============================================================================================+
--/* Name         : XX_CS_po_create_pkg.pks
--/*Description  : This package is used to create the Purchase Orders automatically for MPS
--/*                Bussiness
--/*  Revision History:
--/*
--/*  Date         By                   Description of Revision
--/*  10-SEP-2013  Arun Gannarapu       Initial Creation
--/*  09-OCT-2013  Arun Gannarapu       Made changes to add vendor name logic
--/*  23-OCT-2013  Arun Gannarapu       Made changes to pass the batch id to sumbit import process
--/*
-- +=============================================================================================+

  TYPE header_misc_rec IS RECORD
  (
   payment_term_name             ra_terms_vl.name%TYPE,
   vendor_name                   po_vendors.vendor_name%TYPE,
   user_id                       fnd_user.user_id%TYPE,
   interface_header_id           po_headers_interface.interface_header_id%TYPE,
   agent_id                      po_agents.agent_id%TYPE,
   approval_status               VARCHAR2(20),
   od_po_source                  po_headers_all.attribute1%TYPE,
   od_po_type                    po_headers_all.attribute_category%TYPE,
   buyer_name                    po_agents_v.agent_name%TYPE,
   buyer_id                      po_agents_v.agent_id%TYPE,
   resp_name                     fnd_responsibility_vl.responsibility_name%TYPE,
   user_name                     fnd_user.user_name%TYPE);

  gn_user_id             fnd_user.user_id%TYPE := NVL(fnd_profile.VALUE ('USER_ID'),'-1');
  gc_success             VARCHAR2(100)         := 'SUCCESS';
  gc_failure             VARCHAR2(100)         := 'FAILURE';
  gn_length              NUMBER                := 3000;
  gc_object_name         xx_com_error_log.error_location%TYPE := 'xx_cs_po_create_pkg.create_purchase_order';
  gc_lookup_type_name    cs_lookups.lookup_type%TYPE := 'OD_MPS_PO_DEFAULTS';
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
      ,p_application_name        => 'XXCS'
      ,p_program_type            => 'DEBUG'              --------index exists on program_type
      ,p_attribute15             => gc_object_name          --------index exists on attribute15
      ,p_program_name           => 'XX_CS_MPS_PO_CREATE_PKG'
      ,p_program_id              => 0
      ,p_module_name             => 'MPS'                --------index exists on module_name
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
                                    , p_application_name            => 'XX_CS'
                                    , p_program_type                => 'ERROR'
                                    , p_program_name                => 'XX_CS_MPS_PO_CREATE_PKG'
                                    , p_attribute15                 => 'XX_CS_MPS_PO_CREATE_PKG'          --------index exists on attribute15
                                    , p_program_id                  => NULL
                                    , p_object_id                   => p_object_id
                                    , p_module_name                 => 'MPS'
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

  --**************************************************************************/
  --* Description: Get Lookup values
  --**************************************************************************/

  FUNCTION get_lookup_values(p_lookup_type      IN  cs_lookups.lookup_type%TYPE,
                             p_lookup_code      IN  cs_lookups.lookup_code%TYPE,
                             xx_lookup_rec      OUT cs_lookups%ROWTYPE,
                             xx_error_message   OUT VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_return_status     VARCHAR2(20) := NULL;

  BEGIN
    BEGIN
      xx_error_message     := NULL;
      xx_lookup_rec        := NULL;

      SELEcT *
      INTO xx_lookup_rec
      FROM cs_lookups cs
      WHERE cs.lookup_type  = p_lookup_type
      AND cs.lookup_code    = p_lookup_code
      AND cs.enabled_flag    = 'Y';


      lc_return_status  := gc_success;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        xx_error_message  := 'Lookup '||p_lookup_type || 'AND Lookup code'|| p_lookup_code ||' does not exists' ;
        lc_return_status  := gc_failure;
      WHEN OTHERS
      THEN
        xx_error_message  :=
          SUBSTR('error while getting the lookup info for lookup code '||p_lookup_code || SQLERRM,1,gn_length);
        lc_return_status  := gc_failure;
    END;

    RETURN lc_return_status;

  END get_lookup_values;

  --**************************************************************************/
  --* Description: Get buyer details
  --**************************************************************************/

  FUNCTION get_buyer_id(p_buyer_name       IN  po_agents_v.agent_name%TYPE,
                        xx_buyer_id         OUT po_agents_v.agent_id%TYPE,
                        xx_error_message    OUT VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_return_status     VARCHAR2(20) := NULL;

  BEGIN
    BEGIN
      xx_error_message     := NULL;
      xx_buyer_id          := NULL;

      SELEcT agent_id
      INTO xx_buyer_id
      FROM po_agents_v
      WHERE agent_name = p_buyer_name
      AND (end_date_active IS NULL or end_date_active >= SYSDATE);

      lc_return_status  := gc_success;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        xx_error_message  := ' Buyer Name ' || p_buyer_name || 'Not found' ;
        lc_return_status  := gc_failure;
      WHEN OTHERS
      THEN
        xx_error_message  :=
          SUBSTR('error while getting the Buyer Name'||p_buyer_name || SQLERRM,1,gn_length);
        lc_return_status  := gc_failure;
    END;

    RETURN lc_return_status;

  END get_buyer_id;
 --**************************************************************************/
 --* Description: Get charge account id details
 --**************************************************************************/

  FUNCTION get_charge_account_id (p_sku                IN  mtl_system_items_b.segment1%TYPE,
                                  p_debug_flag         IN  BOOLEAN,
                                  x_charge_account_id  OUT gl_code_combinations.code_combination_id%TYPE,
                                  x_error_message      OUT VARCHAR2)
  RETURN VARCHAR2
  IS
  lc_status            VARCHAR2(20) := NULL;
  lc_charge_acc        VARCHAR2(100) := NULL;
  lr_task_type_rec     JTF_TASK_TYPES_VL%ROWTYPE := NULL;
  lr_lookup_rec        cs_lookups%ROWTYPE := NULL;

  e_process_exception  EXCEPTION;

  BEGIN
    BEGIN
      x_error_message       := NULL;
      x_charge_account_id   := NULL;

      log_msg(p_debug_flag, 'Getting the accouting details for SKU '|| p_sku);

      SELECT gcc.code_combination_id
      INTO x_charge_account_id
      FROM xx_fin_translatedefinition xft,
           xx_fin_translatevalues xftv,
           gl_code_combinations gcc
      WHERE xft.translate_id = xftv.translate_id
      AND xftv.source_value1 = p_sku -- '00001'
      and xft.enabled_flag = 'Y'
      and xftv.enabled_flag = 'Y'
      AND translation_name = 'PO_MPS_ACCOUNTING'
      AND gcc.segment1 = xftv.target_value1
      AND gcc.segment2 = xftv.target_value2
      AND gcc.segment3 = xftv.target_value3
      AND gcc.segment4 = xftv.target_value4
      AND gcc.segment5 = xftv.target_value5
      AND gcc.segment6 = xftv.target_value6
      AND gcc.segment7 = xftv.target_value7
      AND gcc.enabled_flag = 'Y';

      log_msg(p_debug_flag , 'Charge account id '|| x_charge_account_id);

      --  x_charge_account_id    := fnd_flex_ext.get_ccid('SQLGL', 'GL#', 50310, TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'), lc_charge_acc);

      lc_status  := gc_success;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        x_error_message  := 'Accouting details not found for SKU ' ||p_sku;
       -- x_charge_account_id := 5059003 ;  -- TESTING PURPOSE
        lc_status  := gc_success; -- gc_failure; --
      WHEN OTHERS
      THEN
        IF x_error_message IS NULL
        THEN
          x_error_message  :=
            SUBSTR('error while getting accounting details for SKU ' || p_sku ||SQLERRM,1,gn_length);
        END IF;
        lc_status  := gc_failure;
    END;

    RETURN lc_status;

  END get_charge_account_id;

  --**************************************************************************/
  --* Description: Get item details
  --**************************************************************************/

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


  --**************************************************************************/
  --* Description: Get item category details
  --**************************************************************************/

  FUNCTION get_item_category_info (p_item_id           IN  mtl_system_items_b.inventory_item_id%TYPE,
                                   p_organization_id   IN  mtl_system_items_b.organization_id%TYPE,
                                   xx_category_id      OUT mtl_item_categories.category_id%TYPE,
                                   xx_error_message    OUT VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_return_status     VARCHAR2(20) := NULL;

  BEGIN
    BEGIN
      xx_error_message     := NULL;
      xx_category_id       := NULL;

      SELECT mic.category_id
      INTO xx_category_id
      FROM mtl_category_sets mcs,
           mtl_item_categories mic
      WHERE category_set_name   = 'PO CATEGORY'
      AND mcs.category_set_id   = mic.category_set_id
      AND mic.inventory_item_id = p_item_id
      AND mic.organization_id   = p_organization_id;

      lc_return_status  := gc_success;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        xx_error_message  := ' Inventory Item not found ' || p_item_id || 'Organization id ' || p_organization_id ;
        lc_return_status  := gc_failure;
      WHEN OTHERS
      THEN
        xx_error_message  :=
          SUBSTR('error while getting the item info '||p_item_id || 'Organization id ' || p_organization_id||SQLERRM,1,gn_length);
        lc_return_status  := gc_failure;
    END;

    RETURN lc_return_status;

  END get_item_category_info;

-- +=============================================================================================+
   -- Procedure : Insert PO header .
   -- Description : This procedure will load the data into PO header interface tables
-- +=============================================================================================+

  FUNCTION insert_po_header( pio_header_info_rec   IN OUT header_misc_rec,
                             p_header_rec          IN     xx_cs_po_hdr_rec,
                             p_location_info       IN     hr_locations%ROWTYPE,
                             p_vendor_site_info    IN     po_vendor_sites_all%ROWTYPE,
                             xx_error_message      OUT    VARCHAR2)
  RETURN VARCHAR2
  IS
   lc_return_status          VARCHAR2(100) := NULL;
   l_object_name             xx_com_error_log.error_location%TYPE := 'xx_cs_po_create_pkg.create_purchase_order';
   l_message_code            xx_com_error_log.error_message_code%TYPE := NULL;
   l_header_intf_rec         po_headers_interface%ROWTYPE := NULL;

  BEGIN

    SELECT po_headers_interface_s.NEXTVAL
    INTO pio_header_info_rec.interface_header_id
    FROM DUAL;

    l_header_intf_rec.interface_header_id    := pio_header_info_rec.interface_header_id;
    l_header_intf_rec.batch_id               := pio_header_info_rec.interface_header_id;
    l_header_intf_rec.action                 :=  'ORIGINAL';
    l_header_intf_rec.org_id                 := p_header_rec.org_id ;
    l_header_intf_rec.document_type_code     := 'STANDARD';
    l_header_intf_rec.document_num           := p_header_rec.request_number;
    l_header_intf_rec.currency_code          := p_header_rec.currency_code;
    l_header_intf_rec.agent_id               := pio_header_info_rec.buyer_id;
    l_header_intf_rec.vendor_id              := p_vendor_site_info.vendor_id;
    l_header_intf_rec.vendor_site_id         := p_vendor_site_info.vendor_site_id;
    l_header_intf_rec.ship_to_location_id    := p_location_info.location_id;     --- ???
    l_header_intf_rec.terms_id               := p_vendor_site_info.terms_id;
    l_header_intf_rec.approval_status        := 'APPROVED'; --p_header_rec.status_code;
    l_header_intf_rec.comments               := p_header_rec.comments;
    l_header_intf_rec.attribute_category     := p_header_rec.order_category ;  --attribute_category ; --'Non-Trade MPS' ;
    l_header_intf_rec.attribute1             := p_header_rec.order_type;--attribute1; --'NA- MPS';
    l_header_intf_rec.note_to_vendor         := p_header_rec.attribute2;
    l_header_intf_rec.creation_date          := SYSDATE;
    l_header_intf_rec.created_by             := gn_user_id;
    l_header_intf_rec.last_update_date       := SYSDATE ;
    l_header_intf_rec.last_updated_by        := gn_user_id;

    INSERT INTO po_headers_interface
    VALUES      l_header_intf_rec;

    lc_return_status  := gc_success;

    RETURN lc_return_status;

  EXCEPTION
    WHEN OTHERS
    THEN
      xx_error_message  := SUBSTR('Unable to insert into Po Headers interface table ' || SQLERRM,1,gn_length);
      lc_return_status  := gc_failure;

      RETURN lc_return_status;

  END insert_po_header;

   -- +=============================================================================================+
   -- Procedure : Insert PO Distribution
   -- Description : This procedure will load the data into PO distribution interface tables
  -- +=============================================================================================+

  FUNCTION insert_po_distribution( p_header_info_rec    IN  header_misc_rec,
                                   p_interface_line_id  IN  po_distributions_interface.interface_line_id%TYPE,
                                   p_line_detail_rec    IN  xx_cs_order_lines_rec,
                                   p_location_rec       IN  hr_locations%ROWTYPE,
                                   p_debug_flag         IN  BOOLEAN,
                                   xx_error_message     OUT VARCHAR2)

  RETURN VARCHAR2
  IS
   lc_return_status           VARCHAR2(100) := NULL;
   l_object_name             xx_com_error_log.error_location%TYPE := 'xx_cs_po_create_pkg.create_purchase_order';
   l_message_code            xx_com_error_log.error_message_code%TYPE := NULL;
   l_dist_intf_rec           po_distributions_interface%ROWTYPE := NULL;
   ln_distribution_id        po_distributions_interface.interface_distribution_id%TYPE;
   ln_charge_account_id      gl_code_combinations.code_combination_id%TYPE;

   e_process_exception       EXCEPTION;

  BEGIN

    SELECT po_distributions_interface_s.NEXTVAL
    INTO ln_distribution_id
    FROM DUAL;

    log_msg(p_debug_flag, 'Getting the charge account id for SKU  ..' || p_line_detail_rec.sku) ;

    lc_return_status := get_charge_account_id (p_sku                =>  p_line_detail_rec.sku,
                                               p_debug_flag         =>  p_debug_flag,
                                               x_charge_account_id  =>  ln_charge_account_id,
                                               x_error_message      =>  xx_error_message);
    IF (lc_return_status != gc_success)
    THEN
      RAISE e_process_exception;
    END IF;

    l_dist_intf_rec.interface_header_id             := p_header_info_rec.interface_header_id ;
    l_dist_intf_rec.interface_line_id               := p_interface_line_id ;
    l_dist_intf_rec.interface_distribution_id       := ln_distribution_id;
    l_dist_intf_rec.distribution_num                := p_line_detail_rec.line_number;
    l_dist_intf_rec.quantity_ordered                := p_line_detail_rec.order_qty;
   -- l_dist_intf_rec.deliver_to_location_id          := p_location_rec.location_id;
    l_dist_intf_rec.destination_type_code           := 'EXPENSE';
    l_dist_intf_rec.destination_organization_id     := p_line_detail_rec.attribute1;
    l_dist_intf_rec.destination_subinventory        := NULL;
    l_dist_intf_rec.charge_account_id               := ln_charge_account_id;
    l_dist_intf_rec.accrual_account_id              := ln_charge_account_id;
    l_dist_intf_rec.variance_account_id             := ln_charge_account_id;
    l_dist_intf_rec.creation_date                   := SYSDATE ;
    l_dist_intf_rec.created_by                      := gn_user_id;
    l_dist_intf_rec.last_update_date                := SYSDATE;
    l_dist_intf_rec.last_updated_by                 := gn_user_id;

    INSERT INTO po_distributions_interface
    VALUES l_dist_intf_rec;

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
  END insert_po_distribution;

  -- +=============================================================================================+
   -- Procedure : Insert PO Lines
   -- Description : This procedure will load the data into PO Lines interface tables
  -- +=============================================================================================+

  FUNCTION insert_po_line( p_header_rec             IN  xx_cs_po_hdr_rec,
                           p_header_info_rec        IN  header_misc_rec,
                           p_line_detail_rec        IN  xx_cs_order_lines_rec,
                           p_location_info          IN  hr_locations%ROWTYPE,
                           p_debug_flag             IN  BOOLEAN,
                           xx_error_message         OUT VARCHAR2)

  RETURN VARCHAR2
  IS
   lc_status                 VARCHAR2(100) := NULL;
   l_message_code            xx_com_error_log.error_message_code%TYPE := NULL;
   l_line_intf_rec           po_lines_interface%ROWTYPE := NULL;
   ln_interface_line_id      po_lines_interface.interface_line_id%TYPE;
   l_item_rec                mtl_system_items_b%ROWTYPE := NULL;
   ln_category_id            mtl_item_categories.category_id%TYPE := NULL;

   e_process_exception       EXCEPTION;

  BEGIN
    SELECT po_lines_interface_s.NEXTVAL
    INTO ln_interface_line_id
    FROM DUAL;


    IF ( p_line_detail_rec.attribute2 IS NULL -- inventory item id
         OR p_line_detail_rec.attribute4 IS NULL )
    THEN

      log_msg(p_debug_flag , 'Calling get item info for item name '|| p_line_detail_rec.sku || ' Organization_id '|| p_line_detail_rec.attribute1);

      lc_status := get_item_info (p_item_name         => p_line_detail_rec.sku ,
                                  p_organization_id   => p_line_detail_rec.attribute1,
                                  xx_item_info        => l_item_rec,
                                  xx_error_message    => xx_error_message);

      IF (lc_status != gc_success)
      THEN
        RAISE e_process_exception;
      END IF;

      log_msg(p_debug_flag , 'Calling get item category info for item id '|| l_item_rec.inventory_item_id || ' Organization_id '|| p_line_detail_rec.attribute1);

      lc_status :=  get_item_category_info( p_item_id          => l_item_rec.inventory_item_id,
                                            p_organization_id  => p_line_detail_rec.attribute1,
                                            xx_category_id     => ln_category_id,
                                            xx_error_message   => xx_error_message);

      IF (lc_status != gc_success)
      THEN
        RAISE e_process_exception;
      END IF;
   END IF; -- inventory item id

      l_line_intf_rec.interface_header_id       :=  p_header_info_rec.interface_header_id;
    l_line_intf_rec.interface_line_id         :=  ln_interface_line_id ;
    l_line_intf_rec.action                    :=  'ORIGINAL' ;
    l_line_intf_rec.line_num                  :=  p_line_detail_rec.line_number;
    l_line_intf_rec.shipment_num              :=  p_line_detail_rec.line_number;
    l_line_intf_rec.line_type_id              :=  1;
    l_line_intf_rec.item_id                   := NVL(p_line_detail_rec.attribute2,l_item_rec.inventory_item_id);
    l_line_intf_rec.category_id               := NVL(p_line_detail_rec.attribute4,ln_category_id);
    l_line_intf_rec.item_description          := NVL(p_line_detail_rec.item_description,l_item_rec.description);  -- p_line_detail_rec.item_description
    l_line_intf_rec.uom_code                  := NVL(p_line_detail_rec.uom,l_item_rec.primary_uom_code);
    l_line_intf_rec.quantity                  := p_line_detail_rec.order_qty;
    l_line_intf_rec.unit_price                := p_line_detail_rec.selling_price;
    l_line_intf_rec.receiving_routing_id      := 3;
    l_line_intf_rec.qty_rcv_tolerance         := 0;
    l_line_intf_rec.ship_to_organization_id   := p_line_detail_rec.attribute1;
    l_line_intf_rec.need_by_date              := SYSDATE+2;
    l_line_intf_rec.promised_date             := SYSDATE+2;
    l_line_intf_rec.accrue_on_receipt_flag    := 'N'; --'Y';
    l_line_intf_rec.fob                       := 'SHIPPING';
    l_line_intf_rec.last_update_date          := SYSDATE;
    l_line_intf_rec.last_updated_by           := gn_user_id;
    l_line_intf_rec.created_by                := gn_user_id;
    l_line_intf_rec.creation_date             := SYSDATE;
    l_line_intf_rec.receipt_required_flag     := 'N';
--    l_line_intf_rec.line_reference_num        := p_cursor_rec.task_id;
    l_line_intf_rec.receive_close_tolerance   := 100;

    INSERT INTO po_lines_interface
    VALUES      l_line_intf_rec;

    IF (lc_status != gc_success)
    THEN
      RAISE e_process_exception;
    END IF;

    --xx_cs_tds_parts_pkg

  --  xx_Cs_tds_sr_pkg

    log_msg(p_debug_flag , 'Calling Insert PO Distribution for line interface line id '|| ln_interface_line_id);

    lc_status := insert_po_distribution(p_header_info_rec    => p_header_info_rec,
                                        p_interface_line_id  => ln_interface_line_id,
                                        p_line_detail_rec    => p_line_detail_rec,
                                        p_location_rec       => p_location_info,
                                        p_debug_flag         => p_debug_flag,
                                        xx_error_message     => xx_error_message);

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
  END insert_po_line;

  --**************************************************************************/
  --* Description: get vendor site info
  --**************************************************************************/

  FUNCTION get_vendor_site_info(p_item              IN   mtl_system_items_b.segment1%TYPE,
                                p_header_rec        IN  xx_cs_po_hdr_rec,
                                p_organization_id   IN   hr_locations.inventory_organization_id%TYPE,
                                x_vendor_site_rec   OUT  po_vendor_sites_all%ROWTYPE,
                                x_error_message     OUT  VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_return_status     VARCHAR2(20) := NULL;
  ln_vendor_site_id    po_vendor_sites_all.vendor_site_id%TYPE := NULL;
  ln_vendor_id         po_vendor_sites_all.vendor_id%TYPE := NULL;
  ln_master_org_id     mtl_parameters.organization_id%TYPE :=NULL;

  BEGIN
    BEGIN
      x_error_message          := NULL;
      x_vendor_site_rec        := NULL;

      SELECT fnd_profile.value('CSF_INVENTORY_ORG')
      INTO ln_master_org_id
      FROM DUAL;

      SELECT pasl.vendor_site_id,
            pasl.vendor_id
      INTO ln_vendor_site_id,
           ln_vendor_id
      FROM po_approved_supplier_list pasl,
           mtl_system_items_b msi,
           po_vendors pv
      WHERE msi.inventory_item_id = pasl.item_id
      AND msi.organization_id     = pasl.owning_organization_id
      --AND pasl.aslc_status_id      = 2
      AND pasl.disable_flag IS NULL
      AND msi.segment1            = p_item
      AND msi.organization_id     = ln_master_org_id
      AND pasl.vendor_id          = pv.vendor_id
      AND pv.vendor_name          = p_header_rec.attribute1 -- vendor name ???
      ;

      SELECT *
      INTO x_vendor_site_rec
      FROM po_vendor_sites_all
      WHERE vendor_id      = ln_vendor_id
      AND vendor_site_id   = ln_vendor_site_id
      AND ( inactive_date IS NULL OR inactive_date >= SYSDATE ) ;

      lc_return_status  := gc_success;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        x_error_message  := 'Vendor details not found for SKU '||p_item || 'And org combination'|| ln_master_org_id || 'Vendor '|| p_header_rec.attribute1;
        lc_return_status  := gc_failure;

      WHEN OTHERS
      THEN
        x_error_message  :=
          SUBSTR('error while getting the Vendor details for SKU '||p_item ||' And org combination'|| p_organization_id|| SQLERRM,
              1,
              gn_length);
        lc_return_status  := gc_failure;
    END;
    RETURN lc_return_status;

  END get_vendor_site_info;

  --**************************************************************************/
   --* Description: get location details
  --**************************************************************************/

  FUNCTION get_location_info(p_location_code    IN   hr_locations.location_code%TYPE,
                             xx_location_info    OUT  hr_locations%ROWTYPE,
                             xx_error_message    OUT  VARCHAR2)
  RETURN VARCHAR2
  IS

  lc_return_status     VARCHAR2(20) := NULL;

  BEGIN
    BEGIN
      xx_error_message     := NULL;
      xx_location_info     := NULL;

      SELECT *
      INTO xx_location_info
      FROM hr_locations hl
      WHERE hl.location_code = TRIM(p_location_code)
      AND (Inactive_date IS NULL OR inactive_date >= SYSDATE ) ;

      lc_return_status  := gc_success;

    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        xx_error_message  := 'No loacation info found for location code: '||p_location_code;
        lc_return_status  := gc_failure;
      WHEN OTHERS
      THEN
        xx_error_message  :=
          SUBSTR('error while getting the location info for location name:  '||p_location_code || SQLERRM,
              1,
              gn_length);

        lc_return_status  := gc_failure;
    END;

    RETURN lc_return_status;

  END get_location_info;

  /*******************************************************************************
  --   Description : Get all the header details
  ******************************************************************************/

  FUNCTION get_header_info(p_lookup_rec         IN  cs_lookups%ROWTYPE,
                           p_header_rec         IN  xx_cs_po_hdr_rec,
                           p_line_detail_rec    IN  XX_CS_ORDER_LINES_REC,
                           p_debug_flag         IN  BOOLEAN,
                           xx_location_rec      OUT hr_locations%ROWTYPE,
                           xx_vendor_site_rec   OUT po_vendor_sites_all%ROWTYPE,
                           xx_header_misc_rec   OUT header_misc_rec,
                           xx_error_message     OUT VARCHAR2)

  RETURN VARCHAR2
  IS
  lc_status           VARCHAR2(100) := gc_success;
  ln_agent_id         po_headers_interface.agent_id%TYPE := NULL;

  e_process_exception EXCEPTION;

  BEGIN

    log_msg(p_debug_flag, 'Getting location info for location code ' ||p_lookup_rec.attribute5 );

    lc_status := get_location_info(p_location_code    => p_lookup_rec.attribute5, --location_code,
                                   xx_location_info   => xx_location_rec,
                                   xx_error_message   => xx_error_message);

    IF (lc_status != gc_success)
    THEN
      RAISE e_process_exception;
    END IF;

    log_msg(p_debug_flag, 'Getting vendor details for SKU ' ||p_line_detail_rec.sku || 'And inventory org'||p_line_detail_rec.attribute1|| 'vendor '|| p_header_rec.attribute1);

    lc_status := get_vendor_site_info(p_item              =>  p_line_detail_rec.sku,
                                      p_header_rec        =>  p_header_rec,
                                      p_organization_id   =>  p_line_detail_rec.attribute1,
                                      x_vendor_site_rec   =>  xx_vendor_site_rec,
                                      x_error_message     =>  xx_error_message);

    IF (lc_status != gc_success)
    THEN
      RAISE e_process_exception;
    END IF;

    xx_header_misc_rec.buyer_id         :=  p_lookup_rec.attribute1;
    xx_header_misc_rec.resp_name        :=  p_lookup_rec.attribute4; --resp_name;
    xx_header_misc_rec.user_name        :=  p_lookup_rec.attribute5; --user_name;

    RETURN lc_status;

  EXCEPTION
    WHEN OTHERS
    THEN
      IF xx_error_message IS NULL
      THEN
        xx_error_message :=  SUBSTR('Error While getting the header info'||SQLERRM , 1, gn_length);
      END IF;
      RETURN gc_failure;
  END get_header_info ;

  /*******************************************************************************
  --   Description : Submit PO Import
  ******************************************************************************/

  PROCEDURE submit_po_import ( p_lookup_rec       IN   cs_lookups%ROWTYPE,
                               p_org_id           IN   NUMBER,
                               p_batch_id         IN   NUMBER,
                               p_debug_flag       IN   BOOLEAN,
                               x_error_message    OUT  VARCHAR2,
                               x_return_status    OUT  VARCHAR2)
  IS
   ln_conc_request_id        fnd_concurrent_requests.request_id%TYPE;
   ln_responsibility_id      fnd_responsibility_tl.responsibility_id%TYPE;
   ln_user_id                fnd_user.user_id%TYPE;
   ln_application_id         fnd_responsibility_tl.application_id%TYPE;
   lc_req_status             BOOLEAN;
   lc_req_wait               BOOLEAN;
   lc_phase                  VARCHAR2 (100);
   lc_status                 VARCHAR2 (30);
   lc_dev_phase              VARCHAR2 (100);
   lc_dev_status             VARCHAR2 (100);
   l_mesg                    VARCHAR2 (2000);
   ln_po_exists              NUMBER;
   ln_count                  NUMBER;
   ve_program_exception               EXCEPTION;

  BEGIN

    SELECT frt.responsibility_id,
           fu.user_id,
           frt.application_id
    INTO   ln_responsibility_id,
           ln_user_id,
           ln_application_id
    FROM   fnd_user fu,
           fnd_user_resp_groups_all furga,
           fnd_responsibility_tl frt
    WHERE   frt.LANGUAGE         = USERENV('LANG')
    AND    frt.responsibility_id = furga.responsibility_id
    AND    (furga.start_date <= SYSDATE OR furga.start_date IS NULL)
    AND    (furga.end_date >= SYSDATE OR furga.end_date IS NULL)
    AND    furga.user_id      = fu.user_id
    AND    (fu.start_date <= SYSDATE OR fu.start_date IS NULL)
    AND    (fu.end_date >= SYSDATE OR fu.end_date IS NULL)
    AND    fu.user_id               =  p_lookup_rec.attribute2  --'641633'
    AND    frt.responsibility_name  =  p_lookup_rec.attribute3 ; --'OD (US) MPS Service Rep'


    log_msg (p_debug_flag, 'Inside in the PO submit Import');

    log_msg (p_debug_flag, 'ln_user_id :' || ln_user_id ||' ln_responsibility_id :'||ln_responsibility_id ||
                            'ln_application_id :'|| ln_application_id || ' p_org_id :'|| p_org_id );

    fnd_global.apps_initialize (ln_user_id, ln_responsibility_id, ln_application_id); --, p_org_id);

    --fnd_global.apps_initialize (ln_user_id, 20707, ln_application_id, p_org_id);

     MO_GLOBAL.init('PO');
     mo_global.set_policy_context('S',p_org_id);
     FND_REQUEST.SET_ORG_ID((p_org_id));

    log_msg (p_debug_flag, 'Submitting PO Import for batch id.....' || p_batch_id);

    ln_conc_request_id  := fnd_request.submit_request(application    => 'PO', 
                                                      program        => 'POXPOPDOI',
                                                      description    => null,
                                                      start_time     => null, 
                                                      -- To start immediately 
                                                      sub_request    => false, 
                                                      argument1      => NULL, -- Buyer_ID 
                                                      argument2      => 'STANDARD', -- Doc Type 
                                                      argument3      => '', -- doc subtype 
                                                      argument4      => 'N', -- update items 
                                                      argument5      => '', -- create sourcing rules not used 
                                                      argument6      => 'APPROVED', --INCOMPLETE', -- Approval status 
                                                      argument7      => '', -- release generation method 
                                                      argument8      => p_batch_id, --3652158, --'3652160xxxx', -- batch_id 
                                                      argument9      => p_org_id , --404, --NULL, -- operating unit null 
                                                      argument10     => NULL, -- global agreement null 
                                                      argument11     => NULL, -- enable sourcing null 
                                                      argument12     => null, --
                                                      argument13     => NULL, -- inv org enabled null 
                                                      argument14     => NULL, -- inv org null
                                                      argument15     => 5000 ,-- inv org null 
                                                      argument16     => 'N' -- inv org null  
                                                       );                                                                  
                                                                  
    log_msg(p_debug_flag, 'Concurrent request id '||ln_conc_request_id);

    COMMIT;

    IF ln_conc_request_id = 0
    THEN
       x_error_message := SUBSTR( 'Error in submitting PO Import request program '|| SQLERRM ,1 , gn_length);
       RAISE ve_program_exception;
    END IF;

    lc_dev_phase   := 'XX';

    WHILE NVL (lc_dev_phase, 'XX') != 'COMPLETE'
    LOOP
      lc_req_status    := fnd_concurrent.wait_for_request(request_id  => ln_conc_request_id ,
                                                         interval     => 10,              --IN number default 60,
                                                         max_wait     => 0,               --IN number default 0,
                                                         phase        => lc_phase,
                                                         status       => lc_status,
                                                         dev_phase    => lc_dev_phase ,
                                                         dev_status   => lc_dev_status,
                                                         message      => x_error_message );
      EXIT WHEN ( UPPER(lc_dev_phase) = 'COMPLETE' OR lc_phase = 'C');
    END LOOP;

    COMMIT;

    IF  ln_conc_request_id != 0
    THEN
      SELECT COUNT (*)
      INTO ln_count
      FROM po_interface_errors
      WHERE request_id = ln_conc_request_id;

      log_msg (p_debug_flag, 'PO Error Count :'|| ln_count);

      IF ln_count > 0
      THEN
        x_error_message    := ' POImport Ran but errors occur. Check the PO error table for errors';
        RAISE ve_program_exception;
      END IF; -- count
   ELSE
      x_error_message    := ' PO Import failed ' || ln_conc_request_id || SQLERRM;
      RAISE ve_program_exception;
    END IF; -- concurrent request id
  EXCEPTION
    WHEN OTHERS
    THEN
      IF x_error_message IS NULL
      THEN
        x_error_message := SUBSTR('Error while submitting the PO import concurrent program' || SQLERRM , 1, gn_length) ;
      END IF;
       x_return_status     := gc_failure;
  END submit_po_import;


 /*******************************************************************************
  ||   Filename    :
  ||   Description:
  ||------------------------------------------------------------------------------
  ||   Ver  Date          Author            Modification
  --------------------------------------------------------------------------------
  ||   0.1  Sep 10th, 2013  Arun Gannarapu  Initial creation.
  ||------------------------------------------------------------------------------
  ||
  ||   Usage : Public
  ||
  ******************************************************************************/
 -- +=============================================================================================+
   -- Procedure : Create Purchase Order .
   -- Description : This is the Main Procedure to create the Purchase Orders for given SR number
   -- This procedure will be called from Case Management/MPS packages .
-- +=============================================================================================+/
 PROCEDURE create_purchase_order(x_return_status      OUT VARCHAR2,
                                 x_return_message     OUT VARCHAR2,
                                 p_header_rec         IN  OUT xx_cs_po_hdr_rec,
                                 p_line_detail_tab    IN  OUT xx_cs_order_lines_tbl,
                                 p_submit_po_import   IN  VARCHAR2 DEFAULT 'Y'
 )
  AS
   lc_error_message           xx_com_error_log.error_message%TYPE;
   lc_status                  VARCHAR2(100) := NULL;
   lc_lookup_code             cs_lookups.lookup_code%TYPE := 'MPS_DEFAULTS'; --XX_CS_MPS';
   lc_debug_flag              BOOLEAN;
   lc_prev_sr_number          cs_incidents_all_b.incident_number%TYPE  := NULL;
   l_message_code             xx_com_error_log.error_message_code%TYPE := NULL;
   l_line_number              NUMBER := 0;
   ln_pos_loaded              NUMBER := 0;
   lc_return_status           VARCHAR2(100);

   lr_header_info_rec         header_misc_rec              := NULL;
   lr_location_info           hr_locations%ROWTYPE         := NULL;
   lr_vendor_info             po_vendors%ROWTYPE           := NULL;
   lr_vendor_site_info        po_vendor_sites_all%ROWTYPE  := NULL;
   lr_lookup_rec              cs_lookups%ROWTYPE           := NULL;

   lr_lines_rec              XX_CS_ORDER_LINES_REC := NULL;

   e_header_exception        EXCEPTION;


  BEGIN
    lc_status := get_lookup_values(p_lookup_type     => gc_lookup_type_name,
                                   p_lookup_code     => lc_lookup_code, -- One for Installation , and one for Monthly
                                   xx_lookup_rec     => lr_lookup_rec,
                                   xx_error_message  => lc_error_message);

    log_msg(TRUE, 'Status'||lc_status|| 'Error Message'|| lc_error_message);

    IF (lc_status != gc_success)
    THEN
      RAISE e_header_exception;
    END IF;

    log_msg(TRUE, 'lc_debug_flag'||' '||lr_lookup_rec.attribute4);

    IF (lr_lookup_rec.attribute4 = 'Y') -- Debug flag
    THEN
      lc_debug_flag  := TRUE ;
    ELSE
      lc_debug_flag  := FALSE ;
    END IF;

    IF p_header_rec.request_number IS NOT NULL AND p_line_detail_tab.COUNT>0
    THEN
      log_msg(lc_debug_flag, 'Process request for Request number  ..'||p_header_rec.request_number);

       FOR i in p_line_detail_tab.first..p_line_detail_tab.last
       LOOP
         BEGIN

           lr_lines_rec := p_line_detail_tab(i);
           IF (p_header_rec.request_number != lc_prev_sr_number OR lc_prev_sr_number IS NULL )
           THEN
              log_msg(lc_debug_flag, 'Getting the header info for request number..'||p_header_rec.request_number);

              lc_status := get_header_info(p_lookup_rec                => lr_lookup_rec,
                                           p_header_rec                => p_header_rec,
                                           p_line_detail_rec           => lr_lines_rec,
                                           p_debug_flag                => lc_debug_flag,
                                           xx_location_rec             => lr_location_info,
                                           xx_vendor_site_rec          => lr_vendor_site_info,
                                           xx_header_misc_rec          => lr_header_info_rec,
                                           xx_error_message            => lc_error_message);

              IF (lc_status != gc_success)
              THEN
                RAISE e_header_exception;
              END IF;
              log_msg (lc_debug_flag, 'Calling Insert PO Header' );

              lc_status := insert_po_header(pio_header_info_rec  => lr_header_info_rec,
                                            p_header_rec         => p_header_rec,
                                            p_location_info      => lr_location_info,
                                            p_vendor_site_info   => lr_vendor_site_info,
                                            xx_error_message     => lc_error_message);
              IF (lc_status != gc_success)
              THEN
                RAISE e_header_exception;
              END IF;
              ln_pos_loaded := ln_pos_loaded + 1;
              lc_prev_sr_number := p_header_rec.request_number;
           END IF; -- prev number

           log_msg (lc_debug_flag, 'Calling Insert PO line for Line number '||lr_lines_rec.line_number );

           lc_status := insert_po_line(p_header_rec        => p_header_rec,
                                       p_header_info_rec   => lr_header_info_rec,
                                       p_line_detail_rec   => lr_lines_rec,
                                       p_location_info     => lr_location_info,
                                       p_debug_flag        => lc_debug_flag,
                                       xx_error_message    => lc_error_message);

            IF (lc_status != gc_success)
            THEN
              RAISE e_header_exception;
            END IF;
         EXCEPTION
           WHEN OTHERS
           THEN
             log_msg (lc_debug_flag, 'Error '|| SQLERRM);
             RAISE e_header_exception;
         END;
       END LOOP; -- line tab
    END IF;-- count

    log_msg(TRUE, 'ln_pos_loaded '|| ln_pos_loaded ||' P_submit_po_import'|| p_submit_po_import ||' Batch id'||lr_header_info_rec.interface_header_id );
    log_msg(lc_debug_flag ,' Commit the changes');
    COMMIT ;

    IF ln_pos_loaded > 0 AND p_submit_po_import = 'Y'
    THEN
      log_msg(TRUE, 'Submitting PO import process for Batch id '|| lr_header_info_rec.interface_header_id );

       submit_po_import(p_lookup_rec       =>  lr_lookup_rec,
                        p_org_id           =>  lr_vendor_site_info.org_id,
                        p_batch_id         =>  lr_header_info_rec.interface_header_id ,
                        p_debug_flag       =>  lc_debug_flag,
                        x_error_message    =>  lc_error_message,
                        x_return_status    =>  lc_return_status);


       IF (lc_return_status != gc_success)
       THEN
         RAISE e_header_exception;
       END IF;

    END IF;
  EXCEPTION
    WHEN OTHERS
    THEN
      log_msg(lc_debug_flag, 'Rollback the changes ..');
      ROLLBACK;
      IF lc_error_message  IS NULL
      THEN
        lc_error_message := SUBSTR('Error While creating the purchase order '||p_header_rec.request_number||' '||SQLERRM , 1,300);
      END IF;
      log_error(p_object_id      => NULL, --p_sr_number   ,
                p_error_msg      => lc_error_message);

      log_msg (TRUE,lc_error_message);

      x_return_status  := gc_failure;
      x_return_message := lc_error_message;

  END create_purchase_order;

END xx_cs_mps_po_create_pkg;
/