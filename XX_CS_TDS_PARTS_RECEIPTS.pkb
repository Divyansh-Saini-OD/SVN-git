create or replace
PACKAGE BODY      xx_cs_tds_parts_receipts
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_PARTS_RECEIPTS                                 |
-- |                                                                   |
-- | Description: Wrapper package for scripting.                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       16-AUG-11   Raj Jagarlamudi  Initial draft version       |
-- |2.0       19-JUN-12                    Added Qty adjustments       |
-- |3.0       22-Jan-16   Vasu Raparla     Removed schema References   |
-- |                                       for R.12.2                  |
-- +===================================================================+

   g_pkg_name    CONSTANT VARCHAR2 (30) := 'XX_CS_TDS_PARTS_RECEIPTS';
   g_file_name   CONSTANT VARCHAR2 (12) := 'cspvrcvb.pls';

/******************************************************************************/
   PROCEDURE get_messages (x_message OUT NOCOPY VARCHAR2)
   IS
      l_msg_index_out   NUMBER;
      x_msg_data_temp   VARCHAR2 (2000);
      x_msg_data        VARCHAR2 (4000);
   BEGIN
      IF fnd_msg_pub.count_msg > 0
      THEN
         FOR i IN REVERSE 1 .. fnd_msg_pub.count_msg
         LOOP
            fnd_msg_pub.get (p_msg_index          => i,
                             p_encoded            => 'F',
                             p_data               => x_msg_data_temp,
                             p_msg_index_out      => l_msg_index_out
                            );
            x_msg_data := x_msg_data || x_msg_data_temp;
         END LOOP;

         x_message := SUBSTR (x_msg_data, 1, 2000);
      -- fnd_msg_pub.delete_msg;
      END IF;
   END;

/*****************************************************************************
-- Log Messages
****************************************************************************/
   PROCEDURE log_exception (
      p_error_location       IN   VARCHAR2,
      p_error_message_code   IN   VARCHAR2,
      p_error_msg            IN   VARCHAR2
   )
   IS
      ln_login     PLS_INTEGER := fnd_global.login_id;
      ln_user_id   PLS_INTEGER := fnd_global.user_id;
   BEGIN
      xx_com_error_log_pub.log_error
                               (p_return_code                 => fnd_api.g_ret_sts_error,
                                p_msg_count                   => 1,
                                p_application_name            => 'XX_CRM',
                                p_program_type                => 'Custom Messages',
                                p_program_name                => 'XX_CS_TDS_PARTS_RECEIPTS',
                                p_program_id                  => NULL,
                                p_module_name                 => 'CSF',
                                p_error_location              => p_error_location,
                                p_error_message_code          => p_error_message_code,
                                p_error_message               => p_error_msg,
                                p_error_message_severity      => 'MAJOR',
                                p_error_status                => 'ACTIVE',
                                p_created_by                  => ln_user_id,
                                p_last_updated_by             => ln_user_id,
                                p_last_update_login           => ln_login
                               );
   END log_exception;

/***************************************************************************************/
   PROCEDURE gen_receipt_num (
      x_receipt_num       OUT NOCOPY   VARCHAR2,
      p_organization_id                NUMBER,
      x_return_status     OUT NOCOPY   VARCHAR2,
      x_msg_count         OUT NOCOPY   NUMBER,
      x_msg_data          OUT NOCOPY   VARCHAR2
   )
   IS
      l_receipt_exists   NUMBER;
      l_return_status    VARCHAR2 (1);
      l_msg_data         VARCHAR2 (400);
      l_progress         VARCHAR2 (10);
      l_receipt_code     VARCHAR2 (25);
      l_api_name         VARCHAR2 (25)  := 'gen_receipt_num';
   BEGIN
      x_return_status := 'S';

      UPDATE    rcv_parameters
            SET next_receipt_num = next_receipt_num + 1
          WHERE organization_id = p_organization_id
      RETURNING next_receipt_num
           INTO x_receipt_num;

      COMMIT;

      BEGIN
         SELECT 1
           INTO l_receipt_exists
           FROM rcv_shipment_headers rsh
          WHERE receipt_num = x_receipt_num
            AND ship_to_org_id = p_organization_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_receipt_exists := 0;
         WHEN OTHERS
         THEN
            x_msg_data :=
                  x_return_status
               || 'error while selecting exits receipts '
               || SQLERRM;
            log_exception
               (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.GEN_RECEIPTS_NUM',
                p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                p_error_msg               => x_msg_data
               );
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data :=
            x_return_status || 'error while receipts number string '
            || SQLERRM;
         log_exception
            (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.GEN_RECEIPTS_NUM',
             p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
             p_error_msg               => x_msg_data
            );
   END gen_receipt_num;

/***************************************************************************************/
   FUNCTION get_employee (
      emp_id          OUT NOCOPY   NUMBER,
      emp_name        OUT NOCOPY   VARCHAR2,
      location_id     OUT NOCOPY   NUMBER,
      location_code   OUT NOCOPY   VARCHAR2,
      is_buyer        OUT NOCOPY   BOOLEAN,
      emp_flag        OUT NOCOPY   BOOLEAN
   )
      RETURN BOOLEAN
   IS
      x_user_id         VARCHAR2 (80);               /* stores the user id */
      x_emp_id          NUMBER                                := 0;
      /*   stores the employee_id */
      x_location_id     NUMBER                                := 0;
      /*   stores the location_id */
      x_emp_name        VARCHAR2 (240)                        := '';
      /* stores the employee_name */
      x_location_code   hr_locations_all.location_code%TYPE   := '';
      x_buyer_code      VARCHAR2 (1)                          := 'Y';
      /* dummy, stores buyer status */
      mesg_buffer       VARCHAR2 (2000)                       := '';
      /* for handling error messages */
      x_progress        VARCHAR2 (3)                          := '';
      l_api_name        VARCHAR2 (25)                       := 'get_employee';
      x_msg_count       NUMBER;
      x_msg_data        VARCHAR2 (4000);
      x_return_status   VARCHAR2 (1);
   BEGIN
      /* get user id */
      fnd_profile.get ('USER_ID', x_user_id);

      BEGIN
         SELECT hr.employee_id, hr.full_name, NVL (hr.location_id, 0)
           INTO x_emp_id, x_emp_name, x_location_id
           FROM fnd_user fnd, per_employees_current_x hr
          WHERE fnd.user_id = x_user_id
            AND fnd.employee_id = hr.employee_id
            AND ROWNUM = 1;

         emp_flag := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            /* the user is not an employee */
            emp_flag := FALSE;
            RETURN (TRUE);
         WHEN OTHERS
         THEN
            x_msg_data :=
                      x_return_status || 'error getting employee ' || SQLERRM;
            log_exception
                (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.GEN_EMPLOYEE',
                 p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                 p_error_msg               => x_msg_data
                );
      END;

      IF (x_location_id <> 0)
      THEN
         BEGIN
            SELECT hr.location_code
              INTO x_location_code
              FROM hr_locations hr,
                   financials_system_parameters fsp,
                   org_organization_definitions ood
             WHERE hr.location_id = x_location_id
               AND hr.inventory_organization_id = ood.organization_id(+)
               AND NVL (ood.set_of_books_id, ood.set_of_books_id) =
                                                           ood.set_of_books_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               x_location_id := 0;
            WHEN OTHERS
            THEN
               x_msg_data :=
                      x_return_status || 'error getting employee ' || SQLERRM;
               log_exception
                  (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.GEN_EMPLOYEE',
                   p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
         END;
      END IF;

      /* check if employee is a buyer */
      BEGIN
         SELECT 'Y'
           INTO x_buyer_code
           FROM po_agents
          WHERE agent_id = x_emp_id
            AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE - 1)
                            AND NVL (end_date_active, SYSDATE + 1);

         is_buyer := TRUE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            /* user is not a buyer */
            is_buyer := FALSE;
         WHEN OTHERS
         THEN
            x_msg_data :=
                      x_return_status || 'error getting employee ' || SQLERRM;
            log_exception
                (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.GEN_EMPLOYEE',
                 p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                 p_error_msg               => x_msg_data
                );
      END;

      /* assign all the local variables to the parameters */
      emp_id := x_emp_id;
      emp_name := x_emp_name;

      IF (x_location_id <> 0)
      THEN
         location_id := x_location_id;
         location_code := x_location_code;
      ELSE
         location_id := '';
         location_code := '';
      END IF;

      RETURN (TRUE);
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data :=
               x_return_status
            || 'error while selecting exits receipts '
            || SQLERRM;
         log_exception
                 (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.GET_EMPLOYEE',
                  p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                  p_error_msg               => x_msg_data
                 );
         RETURN FALSE;
   END get_employee;

/********************************************************************************/
   PROCEDURE receive_shipments (
      p_api_version_number   IN              NUMBER,
      p_init_msg_list        IN              VARCHAR2,
      p_commit               IN              VARCHAR2,
      p_validation_level     IN              NUMBER,
      p_document_number      IN              VARCHAR2,
      p_resource_id          IN              NUMBER,
      x_return_status        OUT NOCOPY      VARCHAR2,
      x_msg_count            OUT NOCOPY      NUMBER,
      x_msg_data             OUT NOCOPY      VARCHAR2
   )
   IS
      l_sqlcode                       NUMBER;
      l_sqlerrm                       VARCHAR2 (4000);
      l_api_name             CONSTANT VARCHAR2 (30)   := 'receive_shipments';
      l_api_version_number   CONSTANT NUMBER          := 1.0;
      l_return_status_full            VARCHAR2 (1);
      x_message                       VARCHAR2 (2000);
      i                               NUMBER;

      CURSOR c_subinventory (p_inv_loc_assignment_id NUMBER)
      IS
         SELECT subinventory_code, organization_id
           FROM csp_inv_loc_assignments
          WHERE csp_inv_loc_assignment_id = p_inv_loc_assignment_id;

      CURSOR get_hdr_cur (l_doc_number IN VARCHAR2)
      IS
         SELECT flv.meaning doc_type,
                flv.lookup_code doc_type_code,
                ph.po_header_id header_id,
                ph.segment1 document_number,
                'VENDOR' source_type_code,
                'VENDOR' receipt_source_code,
                ph.vendor_id,
                ph.vendor_site_id,
                pll.ship_to_organization_id ship_to_organization_id,
                pll.shipment_num po_shipment_num,
                ph.po_header_id po_header_id,
                ph.po_header_id rcv_shipment_header_id,
                ph.segment1 rcv_shipment_number,
                NULL receipt_number,
                NULL bill_of_lading,
                NULL packing_slip,
                TO_DATE (NULL) shipped_date,
                NULL freight_carrier_code,
                NVL (pll.promised_date,
                     pll.need_by_date ) expected_receipt_date,
                NULL employee_id,
                TO_NUMBER (NULL) num_of_containers,
                NULL waybill_airbill_num,
                NULL comments,
                ph.attribute_category,
                ph.attribute1,
                ph.attribute2,
                ph.attribute3,
                ph.attribute4,
                ph.attribute5,
                ph.attribute6,
                ph.attribute7,
                ph.attribute8,
                ph.attribute9,
                ph.attribute10,
                ph.attribute11,
                ph.attribute12,
                ph.attribute13,
                ph.attribute14,
                ph.attribute15,
                pod.destination_subinventory,
                mp.organization_code ship_to_organization_code,
                pv.vendor_name,
                cil.resource_id,
                cil.resource_type
           FROM po_headers_all ph,
                po_line_locations_all pll,
                po_lines_all pl,
                po_releases_all pr,
                po_distributions_all pod,
                fnd_lookup_values_vl flv,
                mtl_parameters mp,
                po_vendors pv,
                csp_inv_loc_assignments cil,
                xx_cs_tds_parts xc
          WHERE xc.inventory_item_id = pl.item_id
            AND xc.request_number = ph.segment1
            AND flv.lookup_code = 'PO'
            AND flv.lookup_type = 'DOC_TYPE'
            AND NVL (flv.start_date_active, SYSDATE) <= SYSDATE
            AND NVL (flv.end_date_active, SYSDATE) >= SYSDATE
            AND flv.enabled_flag = 'Y'
            AND ph.type_lookup_code IN
                               ('STANDARD', 'PLANNED', 'BLANKET', 'CONTRACT')
            AND NVL (ph.cancel_flag, 'N') IN ('N', 'I')
            AND NVL (ph.closed_code, 'OPEN') NOT IN
                         ('FINALLY CLOSED', 'CLOSED FOR RECEIVING', 'CLOSED')
            AND ph.po_header_id = pll.po_header_id
            AND NVL (pll.approved_flag, 'N') = 'Y'
            AND NVL (pll.cancel_flag, 'N') = 'N'
            AND NVL (pll.closed_code, 'OPEN') NOT IN
                                   ('FINALLY CLOSED', 'CLOSED FOR RECEIVING')
            AND pll.shipment_type IN ('STANDARD', 'BLANKET', 'SCHEDULED')
            AND pl.po_line_id = pll.po_line_id
            AND pll.po_release_id = pr.po_release_id(+)
            AND pod.line_location_id = pll.line_location_id
            AND mp.organization_id = pll.ship_to_organization_id
            AND pv.vendor_id = ph.vendor_id
            AND pll.receiving_routing_id = 3
            AND pod.destination_organization_id = cil.organization_id
            AND pod.destination_subinventory = cil.subinventory_code
            AND pod.po_header_id = ph.po_header_id
           -- AND ph.creation_date > (SYSDATE - 365)
            AND TRUNC (NVL (cil.effective_date_end, SYSDATE)) >=  TRUNC (SYSDATE)
            AND ph.segment1 = l_doc_number
            AND xc.request_number = l_doc_number
            AND cil.subinventory_code = 'STOCK'
            AND NVL (xc.received_shipment_flag, 'N') = 'Y'
            --AND cil.resource_type = 'RS_EMPLOYEE'
            AND cil.resource_id = p_resource_id;

      l_organization_id               NUMBER;
      l_subinventory                  VARCHAR2 (10);
      l_lot_exists                    VARCHAR2 (1);
      l_serial_exists                 VARCHAR2 (1);
      l_lot_interface_id              NUMBER;
      l_serial_interface_id           NUMBER;
      x_serial_transaction_temp_id    NUMBER;
      x_interface_transaction_id      NUMBER;
      l_header_interface_id           NUMBER;
      l_group_id                      NUMBER;
      l_source_doc_code               VARCHAR2 (25);
      l_rcv_transaction_rec           rcv_rec_type;
      l_employee_id                   NUMBER;
      l_employee_name                 VARCHAR2 (240);
      l_location_code                 VARCHAR2 (60);
      l_location_id                   NUMBER;
      l_is_buyer                      BOOLEAN;
      l_emp_flag                      BOOLEAN;
      l_po_header_id                  NUMBER;
      l_request_id                    NUMBER;
      lc_receipt_flag                 VARCHAR2 (1)    := 'N';
      lc_over_qty_flag                VARCHAR2 (1)    := 'N';
      ln_over_qty                     number;
      l_resp_id                       NUMBER     := 50501;
                                                        -- Fnd_Global.Resp_Id;
      l_resp_appl_id         CONSTANT PLS_INTEGER     := 201;
                                                    --Fnd_Global.Resp_Appl_Id;
      l_user_id                       NUMBER   := 1197067;

      CURSOR c_line_cur (p_po_header_id IN NUMBER)
      IS
         SELECT CV.source_type_code,
                CV.doc_type_code,
                CV.item_id,
                CV.item_revision,
                CV.item_category_id,
                CV.item_description,
                CV.ordered_qty,
                CV.ordered_uom,
                xc.tot_received_qty,
                xc.received_quantity,
                xc.line_number,
                CV.primary_uom,
                CV.rcv_shipment_header_id,
                CV.rcv_shipment_line_id,
                CV.po_header_id,
                CV.po_line_id,
                CV.po_line_location_id,
                CV.req_line_id,
                CV.po_release_id,
                CV.oe_order_header_id,
                CV.oe_order_line_id,
                CV.po_distribution_id,
                CV.uom_code,
                CV.currency_code,
                CV.currency_conversion_type,
                CV.currency_conversion_date,
                CV.currency_conversion_rate,
                CV.unit_price,
                CV.deliver_to_person_id,
                CV.deliver_to_location_id,
                CV.lot_num,
                CV.receipt_source_code,
                CV.vendor_id,
                CV.vendor_site_id,
                CV.serial_num,
                CV.to_organization_id,
                CV.destination_subinventory,
                CV.destination_type_code,
                CV.routing_id,
                CV.ship_to_location_id,
                CV.ship_to_location,
                CV.set_of_books_id_sob,
                CV.currency_code_sob,
                CV.lot_primary_quantity,
                CV.lot_quantity,
                CV.expected_receipt_date,
                CV.vendor_lot_num,
                CV.from_organization_id,
                CV.serial_number_control_code,
                CV.lot_control_code,
                CV.oe_order_num,
                'LotText' lot_flag,
                'SerialFlag' serial_flag,
                'LocText' locator_falg,
                'RevText' rev_flag,
                CV.item_number,
                CV.primary_uom_class,
                CV.enforce_ship_to_location_code,
                mp.organization_code,
                CV.item_rev_control_flag_to,
                'N' row_selected,
                CV.order_type_code,
                CV.item_locator_control,
                DECODE (CV.restrict_locators_code,
                        'Y', 1,
                        0) restrict_locators_code,
                CV.restrict_subinventories_code,
                NULL locator_id,
                NULL locator_code,
                'QuantityInput' qtyswitcher,
                NULL row_value_id,
                NULL resource_identifier
           FROM csp_receive_lines_v CV,
                mtl_parameters mp,
                xx_cs_tds_parts xc
          WHERE xc.inventory_item_id = CV.item_id
            AND mp.organization_id(+) = CV.to_organization_id
            AND NVL (xc.received_shipment_flag, 'N') = 'Y'
            AND xc.request_number = p_document_number
            AND po_header_id = p_po_header_id
            AND NVL(xc.received_quantity,0) > 0;
   BEGIN
      x_return_status := 'S';

      -- Check receipt flag
      BEGIN
         SELECT 'Y'
           INTO lc_receipt_flag
           FROM xx_cs_tds_parts
          WHERE request_number = p_document_number
            AND NVL (received_shipment_flag, 'N') = 'Y'
            AND ROWNUM < 2;
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_receipt_flag := 'N';
      END;

      BEGIN
         SELECT user_id
           INTO l_user_id
           FROM fnd_user
          WHERE user_name = 'SVC_ESP_MER';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_user_id := 0;
      END;


      BEGIN
         SELECT responsibility_id
           INTO l_resp_id
           FROM fnd_responsibility_tl
          WHERE responsibility_name = 'OD (US) PO Superuser';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_resp_id := 0;
      END;

      IF NVL (lc_receipt_flag, 'N') = 'Y'
      THEN
         FOR c_hdr_rec IN get_hdr_cur (p_document_number)
         LOOP
            l_po_header_id := c_hdr_rec.header_id;

            SELECT employee_id
              INTO l_employee_id
              FROM fnd_user
             WHERE user_name LIKE UPPER ('Merchandize Buyer');

            BEGIN
               insert_rcv_hdr_interface
                  (p_api_version_number          => 1.0,
                   p_init_msg_list               => fnd_api.g_false,
                   p_commit                      => fnd_api.g_false,
                   p_validation_level            => p_validation_level,
                   x_return_status               => x_return_status,
                   x_msg_count                   => x_msg_count,
                   x_msg_data                    => x_msg_data,
                   p_header_interface_id         => NULL,
                   p_group_id                    => NULL,
                   p_source_type_code            => c_hdr_rec.source_type_code,
                   p_receipt_source_code         => c_hdr_rec.receipt_source_code,
                   p_vendor_id                   => c_hdr_rec.vendor_id,
                   p_vendor_site_id              => c_hdr_rec.vendor_site_id,
                   p_ship_to_org_id              => c_hdr_rec.ship_to_organization_id,
                   p_shipment_num                => c_hdr_rec.rcv_shipment_number,
                   p_receipt_header_id           => c_hdr_rec.po_header_id,
                   p_receipt_num                 => c_hdr_rec.receipt_number,
                   p_bill_of_lading              => c_hdr_rec.bill_of_lading,
                   p_packing_slip                => c_hdr_rec.packing_slip,
                   p_shipped_date                => c_hdr_rec.shipped_date,
                   p_freight_carrier_code        => c_hdr_rec.freight_carrier_code,
                   p_expected_receipt_date       => c_hdr_rec.expected_receipt_date,
                   p_employee_id                 => NVL
                                                       (c_hdr_rec.employee_id,
                                                        l_employee_id
                                                       ),
                   p_waybill_airbill_num         => c_hdr_rec.waybill_airbill_num,
                   p_usggl_transaction_code      => NULL,
                   p_processing_request_id       => NULL,
                   p_customer_id                 => NULL,
                   p_customer_site_id            => NULL,
                   x_header_interface_id         => l_header_interface_id,
                   x_group_id                    => l_group_id
                  );
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_msg_data :=
                        'error while calling insert_rcv_hdr_interface '
                     || SQLERRM;
                  log_exception
                     (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.RECEIVE_SHIPMENTS',
                      p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                      p_error_msg               => x_msg_data
                     );
            END;
         END LOOP;

         IF NVL (x_return_status, 'S') <> 'S'
         THEN
            x_msg_data :=
                  x_return_status
               || 'error in insert_rcv_hdr_interface '
               || SQLERRM;
            log_exception
               (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.INSERT_RCV_HEADER',
                p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                p_error_msg               => x_msg_data
               );
         ELSE
            FOR c_line_rec IN c_line_cur (l_po_header_id)
            LOOP
               i := i + 1;
               l_organization_id := c_line_rec.to_organization_id;
               l_subinventory := c_line_rec.destination_subinventory;
               l_rcv_transaction_rec.source_type_code := c_line_rec.source_type_code;
                                                                  --'VENDOR';
               l_rcv_transaction_rec.destination_type_code :=  c_line_rec.destination_type_code;
               l_rcv_transaction_rec.transaction_type :=  'RECEIVE';
               l_rcv_transaction_rec.order_type_code := c_line_rec.order_type_code;
               l_rcv_transaction_rec.routing_id := 3;
               l_rcv_transaction_rec.header_interface_id := l_header_interface_id;
               l_rcv_transaction_rec.GROUP_ID := l_group_id;
               l_rcv_transaction_rec.employee_id := l_employee_id;
               l_rcv_transaction_rec.to_organization_id := c_line_rec.to_organization_id;
                                                         --l_organization_id;
               l_rcv_transaction_rec.destination_subinventory := c_line_rec.destination_subinventory;
                                                            --l_subinventory;
               l_rcv_transaction_rec.po_line_location_id := c_line_rec.po_line_location_id;
               l_rcv_transaction_rec.item_id := c_line_rec.item_id;
               l_rcv_transaction_rec.uom_code := c_line_rec.uom_code;
               l_rcv_transaction_rec.transaction_uom := c_line_rec.ordered_uom;
               l_rcv_transaction_rec.primary_uom := c_line_rec.primary_uom;
               l_rcv_transaction_rec.item_description := c_line_rec.item_description;
               l_rcv_transaction_rec.item_category_id := c_line_rec.item_category_id;
               l_rcv_transaction_rec.primary_uom_class := c_line_rec.primary_uom_class;
               l_rcv_transaction_rec.ship_to_location_id := c_line_rec.ship_to_location_id;
               l_rcv_transaction_rec.vendor_id := c_line_rec.vendor_id;
               l_rcv_transaction_rec.vendor_site_id :=  c_line_rec.vendor_site_id;
               l_rcv_transaction_rec.po_header_id := c_line_rec.po_header_id;
               l_rcv_transaction_rec.po_release_id := c_line_rec.po_release_id;
               l_rcv_transaction_rec.po_line_id := c_line_rec.po_line_id;
               l_rcv_transaction_rec.po_line_location_id := c_line_rec.po_line_location_id;
               l_rcv_transaction_rec.po_distribution_id := c_line_rec.po_distribution_id;
               l_rcv_transaction_rec.receipt_source_code := c_line_rec.receipt_source_code;
               l_rcv_transaction_rec.req_line_id := c_line_rec.req_line_id;
               l_rcv_transaction_rec.from_organization_id := c_line_rec.from_organization_id;
               -- l_rcv_transaction_rec.substitute_receipt := c_line_rec.substitute_receipt;
            --   l_rcv_transaction_rec.rcv_shipment_header_id := c_line_rec.rcv_shipment_header_id;
            --   l_rcv_transaction_rec.rcv_shipment_line_id := c_line_rec.rcv_shipment_line_id;
               l_rcv_transaction_rec.unit_price := c_line_rec.unit_price;
               l_rcv_transaction_rec.currency_code := c_line_rec.currency_code;
               l_rcv_transaction_rec.currency_conversion_type := c_line_rec.currency_conversion_type;
               l_rcv_transaction_rec.currency_conversion_date :=
                   NVL (c_line_rec.currency_conversion_date, TRUNC (SYSDATE));
               l_rcv_transaction_rec.currency_conversion_rate := c_line_rec.currency_conversion_rate;
               l_rcv_transaction_rec.ordered_qty := c_line_rec.ordered_qty;
               IF c_line_rec.received_quantity > c_line_rec.ordered_qty THEN
                l_rcv_transaction_rec.transaction_quantity :=  c_line_rec.ordered_qty;
                lc_over_qty_flag := 'Y';
                ln_over_qty := c_line_rec.received_quantity - c_line_rec.ordered_qty;
               ELSE
                l_rcv_transaction_rec.transaction_quantity :=  c_line_rec.received_quantity;
               END IF;
               l_rcv_transaction_rec.expected_receipt_date := c_line_rec.expected_receipt_date;
               l_rcv_transaction_rec.deliver_to_person_id := c_line_rec.deliver_to_person_id;
               l_rcv_transaction_rec.deliver_to_location_id :=  c_line_rec.deliver_to_location_id;
               l_rcv_transaction_rec.primary_quantity :=
                  rcv_transactions_interface_sv.convert_into_correct_qty
                                               (c_line_rec.received_quantity,
                                                c_line_rec.primary_uom,
                                                c_line_rec.item_id,
                                                c_line_rec.primary_uom
                                               );
               -- dbms_output.put_line('Before calling rcv_txn_interface');
               insert_rcv_txn_interface
                    (p_api_version_number            => 1.0,
                     p_init_msg_list                 => fnd_api.g_false,
                     p_commit                        => fnd_api.g_false,
                     p_validation_level              => p_validation_level,
                     x_return_status                 => x_return_status,
                     x_msg_count                     => x_msg_count,
                     x_msg_data                      => x_msg_data,
                     x_interface_transaction_id      => x_interface_transaction_id,
                     p_receive_rec                   => l_rcv_transaction_rec
                    );

               IF NVL (x_return_status, 'S') <> 'S'
               THEN
                  x_msg_data :=
                        x_msg_data
                     || 'error while calling insert_rcv_txn_interface for '
                     || l_header_interface_id
                     || SQLERRM;
                  log_exception
                     (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.INSERT_RCV_TXN_IFACE',
                      p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                      p_error_msg               => x_msg_data
                     );

                  UPDATE xx_cs_tds_parts
                     SET received_shipment_flag = 'E'
                   WHERE request_number = p_document_number
                     AND line_number = c_line_rec.line_number
                     AND inventory_item_id = c_line_rec.item_id;
               ELSE
                  IF nvl(lc_over_qty_flag,'N') = 'Y' then
                   -- Update over qty into excess qty
                    UPDATE xx_cs_tds_parts
                       SET received_shipment_flag = 'R',
                           excess_flag = 'Y',
                           excess_quantity = ln_over_qty,
                           attribute4 = lc_over_qty_flag
                     WHERE request_number = p_document_number
                       AND line_number = c_line_rec.line_number
                       AND inventory_item_id = c_line_rec.item_id;
                  else
                    IF c_line_rec.tot_received_qty < c_line_rec.ordered_qty then
                       UPDATE xx_cs_tds_parts
                         SET received_shipment_flag = 'N',
                             received_quantity = 0
                       WHERE request_number = p_document_number
                         AND line_number = c_line_rec.line_number
                         AND inventory_item_id = c_line_rec.item_id;
                    else
                      UPDATE xx_cs_tds_parts
                         SET received_shipment_flag = 'R'
                       WHERE request_number = p_document_number
                         AND line_number = c_line_rec.line_number
                         AND inventory_item_id = c_line_rec.item_id;
                    end if;
                  end if;
               END IF;
            END LOOP;
         END IF;

         COMMIT;

         --FND_GLOBAL.APPS_INITIALIZE(28709,50501,201);
         fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id);
         l_request_id :=
            fnd_request.submit_request ('PO',
                                        'RVCTP',
                                        'Receiving Transaction Processor',
                                        NULL,
                                        FALSE,
                                        'BATCH',
                                        TO_CHAR (l_group_id)
                                       );
         COMMIT;
    --     DBMS_OUTPUT.put_line ('Request ID:' || l_request_id);

           x_msg_data := 'Request submitted for header '||l_header_interface_id||' Request Id '||l_request_id;

            log_exception
               (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.FND_SUBMIT_REQUEST',
                p_error_message_code      => 'XX_CS_SR02_LOG',
                p_error_msg               => x_msg_data
               );

         IF l_request_id <= 0
         THEN
            get_messages (x_msg_data);
            x_msg_data :=
                  x_msg_data
               || 'error in concurrent request '
               || l_header_interface_id
               || SQLERRM;
            log_exception
               (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.FND_SUBMIT_REQUEST',
                p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                p_error_msg               => x_msg_data
               );
         END IF;
      END IF;  -- receipt_flag
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data :=
               x_return_status
            || ' When Others error while inserting receipts data'
            || SQLERRM;
         log_exception
                  (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.WHEN_OTHERS',
                   p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
   END;

/************************************************************************************/
   PROCEDURE insert_rcv_hdr_interface (
      p_api_version_number       IN              NUMBER,
      p_init_msg_list            IN              VARCHAR2,
      p_commit                   IN              VARCHAR2,
      p_validation_level         IN              NUMBER,
      x_return_status            OUT NOCOPY      VARCHAR2,
      x_msg_count                OUT NOCOPY      NUMBER,
      x_msg_data                 OUT NOCOPY      VARCHAR2,
      p_header_interface_id      IN              NUMBER,
      p_group_id                 IN              NUMBER,
      p_receipt_source_code      IN              VARCHAR2,
      p_source_type_code         IN              VARCHAR2,
      p_vendor_id                IN              NUMBER,
      p_vendor_site_id           IN              NUMBER,
      p_ship_to_org_id           IN              NUMBER,
      p_shipment_num             IN              VARCHAR2,
      p_receipt_header_id        IN              NUMBER,
      p_receipt_num              IN              VARCHAR2,
      p_bill_of_lading           IN              VARCHAR2,
      p_packing_slip             IN              VARCHAR2,
      p_shipped_date             IN              DATE,
      p_freight_carrier_code     IN              VARCHAR2,
      p_expected_receipt_date    IN              DATE,
      p_employee_id              IN              NUMBER,
      p_waybill_airbill_num      IN              VARCHAR2,
      p_usggl_transaction_code   IN              VARCHAR2,
      p_processing_request_id    IN              NUMBER,
      p_customer_id              IN              NUMBER,
      p_customer_site_id         IN              NUMBER,
      x_header_interface_id      OUT NOCOPY      NUMBER,
      x_group_id                 OUT NOCOPY      NUMBER
   )
   IS
      l_api_name             CONSTANT VARCHAR2 (30)
                                                := 'INSERT_RCV_HDR_INTERFACE';
      l_api_version_number   CONSTANT NUMBER        := 1.0;
      l_header_interface_id           NUMBER;
      l_group_id                      NUMBER;
      l_receipt_num                   NUMBER;
      l_receipt_header_id             NUMBER;
      l_shipment_num                  VARCHAR2 (30);
   BEGIN
      SAVEPOINT insert_rcv_hdr_interface_pvt;

      -- Standard call to check for call compatibility.
      IF NOT fnd_api.compatible_api_call (l_api_version_number,
                                          p_api_version_number,
                                          l_api_name,
                                          g_pkg_name
                                         )
      THEN
         RAISE fnd_api.g_exc_unexpected_error;
      END IF;

      -- Initialize message list if p_init_msg_list is set to TRUE.
      IF fnd_api.to_boolean (p_init_msg_list)
      THEN
         fnd_msg_pub.initialize;
      END IF;

      x_return_status := fnd_api.g_ret_sts_success;
      l_header_interface_id := p_header_interface_id;

      IF (l_header_interface_id IS NULL)
      THEN
         SELECT rcv_headers_interface_s.NEXTVAL
           INTO l_header_interface_id
           FROM DUAL;
      END IF;

      l_group_id := p_group_id;

      IF (l_group_id IS NULL)
      THEN
         SELECT rcv_interface_groups_s.NEXTVAL
           INTO l_group_id
           FROM DUAL;
      END IF;

      l_receipt_num := p_receipt_num;

      IF l_receipt_num IS NULL
      THEN
         gen_receipt_num (x_receipt_num          => l_receipt_num,
                          p_organization_id      => p_ship_to_org_id,
                          x_return_status        => x_return_status,
                          x_msg_count            => x_msg_count,
                          x_msg_data             => x_msg_data
                         );

         IF x_return_status <> fnd_api.g_ret_sts_success
         THEN
            --get_messages (x_msg_data);
            RAISE fnd_api.g_exc_unexpected_error;
         END IF;
      END IF;

      IF p_source_type_code = 'INTERNAL'
      THEN
         l_receipt_header_id := p_receipt_header_id;
         l_shipment_num := p_shipment_num;
      ELSE
         l_receipt_header_id := NULL;
         l_shipment_num := NULL;
      END IF;

      INSERT INTO rcv_headers_interface
                  (header_interface_id,
                   GROUP_ID,
                   processing_status_code,
                   transaction_type,
                   validation_flag,
                   auto_transact_code,
                   last_update_date,
                   last_updated_by,
                   creation_date,
                   created_by,
                   last_update_login,
                   receipt_source_code,
                   vendor_id,
                   vendor_site_id,
                   ship_to_organization_id,
                   shipment_num,
                   receipt_header_id,
                   receipt_num,
                   bill_of_lading,
                   packing_slip,
                   shipped_date,
                   freight_carrier_code,
                   expected_receipt_date,
                   employee_id,
                   waybill_airbill_num,
                   usggl_transaction_code,
                   processing_request_id,
                   customer_id, customer_site_id
                  )
           VALUES (l_header_interface_id,
                   l_group_id,
                   'PENDING',
                   'NEW', 'Y',
                   'RECEIVE',
                   SYSDATE,
                   fnd_global.user_id,
                   SYSDATE,
                   fnd_global.user_id,
                   fnd_global.login_id,
                   p_receipt_source_code,
                   p_vendor_id,
                   p_vendor_site_id,
                   p_ship_to_org_id,
                   l_shipment_num,
                   l_receipt_header_id,
                   l_receipt_num,
                   p_bill_of_lading,
                   p_packing_slip,
                   p_shipped_date,
                   p_freight_carrier_code,
                   NVL (p_expected_receipt_date, SYSDATE),
                   p_employee_id,
                   p_waybill_airbill_num,
                   p_usggl_transaction_code,
                   p_processing_request_id,
                   p_customer_id,
                   p_customer_site_id
                  );

      x_header_interface_id := l_header_interface_id;
      x_group_id := l_group_id;
   EXCEPTION
      WHEN fnd_api.g_exc_error
      THEN
         jtf_plsql_api.handle_exceptions
                           (p_api_name             => l_api_name,
                            p_pkg_name             => g_pkg_name,
                            p_exception_level      => fnd_msg_pub.g_msg_lvl_error,
                            p_package_type         => jtf_plsql_api.g_pvt,
                            x_msg_count            => x_msg_count,
                            x_msg_data             => x_msg_data,
                            x_return_status        => x_return_status
                           );
      WHEN fnd_api.g_exc_unexpected_error
      THEN
         jtf_plsql_api.handle_exceptions
                     (p_api_name             => l_api_name,
                      p_pkg_name             => g_pkg_name,
                      p_exception_level      => fnd_msg_pub.g_msg_lvl_unexp_error,
                      p_package_type         => jtf_plsql_api.g_pvt,
                      x_msg_count            => x_msg_count,
                      x_msg_data             => x_msg_data,
                      x_return_status        => x_return_status
                     );
      WHEN OTHERS
      THEN
         fnd_message.set_name ('CSP', 'CSP_UNEXPECTED_EXEC_ERRORS');
         fnd_message.set_token ('ROUTINE', l_api_name, TRUE);
         fnd_message.set_token ('SQLERRM', SQLERRM, TRUE);
         fnd_msg_pub.ADD;
         jtf_plsql_api.handle_exceptions
                            (p_api_name             => l_api_name,
                             p_pkg_name             => g_pkg_name,
                             p_exception_level      => jtf_plsql_api.g_exc_others,
                             p_package_type         => jtf_plsql_api.g_pvt,
                             x_msg_count            => x_msg_count,
                             x_msg_data             => x_msg_data,
                             x_return_status        => x_return_status
                            );
   END;

/************************************************************************************/
   PROCEDURE insert_rcv_txn_interface (
      p_api_version_number         IN              NUMBER,
      p_init_msg_list              IN              VARCHAR2,
      p_commit                     IN              VARCHAR2,
      p_validation_level           IN              NUMBER,
      x_return_status              OUT NOCOPY      VARCHAR2,
      x_msg_count                  OUT NOCOPY      NUMBER,
      x_msg_data                   OUT NOCOPY      VARCHAR2,
      x_interface_transaction_id   OUT NOCOPY      NUMBER,
      p_receive_rec                IN              rcv_rec_type
   )
   IS
      l_api_name             CONSTANT VARCHAR2 (30)
                                                := 'INSERT_RCV_TXN_INTERFACE';
      l_api_version_number   CONSTANT NUMBER          := 1.0;
      l_transaction_interface_id      NUMBER;
      l_source_code                   NUMBER;
      l_source_line_id                NUMBER;
      l_interface_transaction_id      NUMBER;
      x_message                       VARCHAR2 (2000);
      l_rcv_transaction_rec           rcv_rec_type;
      l_auto_transact_code            VARCHAR2 (30);
      l_shipment_line_id              NUMBER;
      l_primary_uom                   VARCHAR2 (25);
      l_blind_receiving_flag          VARCHAR2 (1);
      l_receipt_source_code           VARCHAR2 (30);
      l_vendor_id                     NUMBER;
      l_vendor_site_id                NUMBER;
      l_from_org_id                   NUMBER;
      l_to_org_id                     NUMBER;
      l_source_doc_code               VARCHAR2 (30);
      l_po_header_id                  NUMBER;
      l_po_release_id                 NUMBER;
      l_po_line_id                    NUMBER;
      l_po_line_location_id           NUMBER;
      l_po_distribution_id            NUMBER;
      l_req_line_id                   NUMBER;
      l_sub_unordered_code            VARCHAR2 (30);
      l_deliver_to_person_id          NUMBER;
      l_location_id                   NUMBER;
      l_deliver_to_location_id        NUMBER;
      l_subinventory                  VARCHAR2 (10);
      l_locator_id                    NUMBER;
      l_wip_entity_id                 NUMBER;
      l_wip_line_id                   NUMBER;
      l_department_code               VARCHAR2 (30);
      l_wip_rep_sched_id              NUMBER;
      l_wip_oper_seq_num              NUMBER;
      l_wip_res_seq_num               NUMBER;
      l_bom_resource_id               NUMBER;
      l_oe_order_header_id            NUMBER;
      l_oe_order_line_id              NUMBER;
      l_customer_item_num             NUMBER;
      l_customer_id                   NUMBER;
      l_customer_site_id              NUMBER;
      l_rate                          NUMBER;
      l_rate_date                     DATE;
      l_rate_gl                       NUMBER;
      l_shipment_header_id            NUMBER;
      l_header_interface_id           NUMBER;
      l_lpn_group_id                  NUMBER;
      l_num_of_distributions          NUMBER;
      l_validation_flag               VARCHAR2 (1);
      l_project_id                    NUMBER;
      l_task_id                       NUMBER;
      x_available_qty                 NUMBER;
      x_ordered_qty                   NUMBER;
      x_primary_qty                   NUMBER;
      x_tolerable_qty                 NUMBER;
      x_uom                           VARCHAR2 (25);
      x_primary_uom                   VARCHAR2 (25);
      x_valid_ship_to_location        BOOLEAN;
      x_num_of_distributions          NUMBER;
      x_po_distribution_id            NUMBER;
      x_destination_type_code         VARCHAR2 (30);
      x_destination_type_dsp          VARCHAR2 (80);
      x_deliver_to_location_id        NUMBER;
      x_deliver_to_location           VARCHAR2 (80);
      x_deliver_to_person_id          NUMBER;
      x_deliver_to_person             VARCHAR2 (240);
      x_deliver_to_sub                VARCHAR2 (10);
      x_deliver_to_locator_id         NUMBER;
      x_wip_entity_id                 NUMBER;
      x_wip_repetitive_schedule_id    NUMBER;
      x_wip_line_id                   NUMBER;
      x_wip_operation_seq_num         NUMBER;
      x_wip_resource_seq_num          NUMBER;
      x_bom_resource_id               NUMBER;
      x_to_organization_id            NUMBER;
      x_job                           VARCHAR2 (80);
      x_line_num                      VARCHAR2 (10);
      x_sequence                      NUMBER;
      x_department                    VARCHAR2 (40);
      x_enforce_ship_to_loc           VARCHAR2 (30);
      x_allow_substitutes             VARCHAR2 (3);
      x_routing_id                    NUMBER;
      x_qty_rcv_tolerance             NUMBER;
      x_qty_rcv_exception             VARCHAR2 (30);
      x_days_early_receipt            NUMBER;
      x_days_late_receipt             NUMBER;
      x_rcv_days_exception            VARCHAR2 (30);
      x_item_revision                 VARCHAR2 (3);
      x_locator_control               NUMBER;
      x_inv_destinations              BOOLEAN;
      x_rate                          NUMBER;
      x_rate_date                     DATE;
      x_project_id                    NUMBER;
      x_task_id                       NUMBER;
      x_req_line_id                   NUMBER;
      x_pos                           NUMBER;
      x_oe_order_line_id              NUMBER;
      x_item_id                       NUMBER;
      x_org_id                        NUMBER;
      x_category_id                   NUMBER;
      x_category_set_id               NUMBER;
      x_routing_name                  VARCHAR2 (240);
   BEGIN
      SAVEPOINT insert_rcv_txn_interface_pvt;

      -- Standard call to check for call compatibility.
--      IF NOT fnd_api.compatible_api_call (l_api_version_number,
--                                          p_api_version_number,
--                                          l_api_name,
--                                          g_pkg_name
--                                         )
--      THEN
--         RAISE fnd_api.g_exc_unexpected_error;
--      END IF;

      -- Initialize message list if p_init_msg_list is set to TRUE.
      IF fnd_api.to_boolean (p_init_msg_list)
      THEN
         fnd_msg_pub.initialize;
      END IF;

      x_return_status := fnd_api.g_ret_sts_success;
      l_rcv_transaction_rec := p_receive_rec;
      l_interface_transaction_id :=
                                l_rcv_transaction_rec.interface_transaction_id;

      IF (l_interface_transaction_id IS NULL)
      THEN
         SELECT rcv_transactions_interface_s.NEXTVAL
           INTO l_interface_transaction_id
           FROM DUAL;
      END IF;

      l_to_org_id := l_rcv_transaction_rec.to_organization_id;
      l_from_org_id := l_rcv_transaction_rec.from_organization_id;
      l_receipt_source_code := l_rcv_transaction_rec.receipt_source_code;
      l_source_doc_code := l_rcv_transaction_rec.order_type_code;
      l_to_org_id := l_rcv_transaction_rec.to_organization_id;
      l_sub_unordered_code := l_rcv_transaction_rec.substitute_receipt;
      l_shipment_header_id := l_rcv_transaction_rec.rcv_shipment_header_id;
      l_shipment_line_id := l_rcv_transaction_rec.rcv_shipment_line_id;

      IF l_rcv_transaction_rec.source_type_code IN ('VENDOR', 'ASN')
      THEN
         l_vendor_id := l_rcv_transaction_rec.vendor_id;
         l_vendor_site_id := l_rcv_transaction_rec.vendor_site_id;
         l_po_header_id := l_rcv_transaction_rec.po_header_id;
         l_po_release_id := l_rcv_transaction_rec.po_release_id;
         l_po_line_id := l_rcv_transaction_rec.po_line_id;
         l_po_line_location_id := l_rcv_transaction_rec.po_line_location_id;
      ELSIF l_rcv_transaction_rec.source_type_code = 'INTERNAL'
      THEN
         l_req_line_id := l_rcv_transaction_rec.req_line_id;
         l_from_org_id := l_rcv_transaction_rec.from_organization_id;
         l_shipment_line_id := l_rcv_transaction_rec.rcv_shipment_line_id;
      END IF;

      IF l_rcv_transaction_rec.destination_type_code = 'RECEIVING'
      THEN
         l_auto_transact_code := 'RECEIVE';
         l_location_id := l_rcv_transaction_rec.ship_to_location_id;
         l_subinventory := l_rcv_transaction_rec.destination_subinventory;
         l_locator_id := l_rcv_transaction_rec.locator_id;
      ELSE
         l_auto_transact_code := 'DELIVER';
         l_po_distribution_id := l_rcv_transaction_rec.po_distribution_id;
         l_deliver_to_person_id := l_rcv_transaction_rec.deliver_to_person_id;
         l_deliver_to_location_id :=
                                 l_rcv_transaction_rec.deliver_to_location_id;
         l_subinventory := l_rcv_transaction_rec.destination_subinventory;
         l_locator_id := l_rcv_transaction_rec.locator_id;
         l_location_id := l_rcv_transaction_rec.deliver_to_location_id;

         IF l_rcv_transaction_rec.source_type_code IN ('VENDOR', 'ASN')
         THEN
            l_wip_entity_id := l_rcv_transaction_rec.wip_entity_id;
            l_wip_line_id := l_rcv_transaction_rec.wip_line_id;
            l_department_code := l_rcv_transaction_rec.department_code;
            l_wip_rep_sched_id :=
                             l_rcv_transaction_rec.wip_repetitive_schedule_id;
            l_wip_oper_seq_num := l_rcv_transaction_rec.wip_operation_seq_num;
            l_wip_res_seq_num := l_rcv_transaction_rec.wip_resource_seq_num;
            l_bom_resource_id := l_rcv_transaction_rec.bom_resource_id;
         END IF;
      END IF;

      l_sub_unordered_code := l_rcv_transaction_rec.substitute_receipt;

      l_lpn_group_id := l_rcv_transaction_rec.GROUP_ID;
      l_validation_flag := 'Y';
      l_header_interface_id := l_rcv_transaction_rec.header_interface_id;
      l_project_id := NULL;
      l_task_id := NULL;

      -- dbms_output.put_line('Before inserting into rcv_transactions_interface:');

      -- populate DB items in rcv_transaction block
      INSERT INTO rcv_transactions_interface
                  (interface_transaction_id, header_interface_id,
                   GROUP_ID, last_update_date,
                   last_updated_by, creation_date, created_by,
                   last_update_login, transaction_type, transaction_date,
                   processing_status_code, processing_mode_code,
                   processing_request_id, transaction_status_code,
                   category_id,
                   quantity,
                   unit_of_measure,
                   interface_source_code,
                   interface_source_line_id,
                   inv_transaction_id,
                   item_id,
                   item_description,
                   item_revision,
                   uom_code,
                   employee_id,
                   auto_transact_code,
                   shipment_header_id,
                   shipment_line_id,
                   ship_to_location_id,
                   primary_quantity,
                   primary_unit_of_measure,
                   receipt_source_code,
                   vendor_id, vendor_site_id,
                   from_organization_id,
                   from_subinventory,
                   to_organization_id,
                   routing_header_id, routing_step_id,
                   source_document_code,
                   parent_transaction_id, po_header_id,
                   po_revision_num, po_release_id,
                   po_line_id, po_line_location_id,
                   po_unit_price,
                   currency_code,
                   currency_conversion_type,
                   currency_conversion_rate,
                   currency_conversion_date,
                   po_distribution_id,
                   requisition_line_id, req_distribution_id,
                   charge_account_id,
                   substitute_unordered_code,
                   receipt_exception_flag,
                   accrual_status_code,
                   inspection_status_code,
                   inspection_quality_code,
                   destination_type_code,
                   deliver_to_person_id,
                   location_id,
                   deliver_to_location_id,
                   subinventory,
                   locator_id,
                   wip_entity_id,
                   wip_line_id,
                   department_code,
                   wip_repetitive_schedule_id,
                   wip_operation_seq_num,
                   wip_resource_seq_num,
                   bom_resource_id,
                   shipment_num, freight_carrier_code,
                   bill_of_lading, packing_slip,
                   shipped_date,
                   expected_receipt_date,
                   actual_cost, transfer_cost,
                   transportation_cost,
                   transportation_account_id,
                   num_of_containers,
                   waybill_airbill_num,
                   vendor_item_num,
                   vendor_lot_num,
                   rma_reference,
                   comments,
                   attribute_category,
                   attribute1,
                   attribute2,
                   attribute3,
                   attribute4,
                   attribute5,
                   attribute6,
                   attribute7,
                   attribute8,
                   attribute9,
                   attribute10,
                   attribute11,
                   attribute12,
                   attribute13,
                   attribute14,
                   attribute15,
                   ship_head_attribute_category,
                   ship_head_attribute1,
                   ship_head_attribute2,
                   ship_head_attribute3,
                   ship_head_attribute4,
                   ship_head_attribute5,
                   ship_head_attribute6,
                   ship_head_attribute7,
                   ship_head_attribute8,
                   ship_head_attribute9,
                   ship_head_attribute10,
                   ship_head_attribute11,
                   ship_head_attribute12,
                   ship_head_attribute13,
                   ship_head_attribute14,
                   ship_head_attribute15,
                   ship_line_attribute_category,
                   ship_line_attribute1,
                   ship_line_attribute2,
                   ship_line_attribute3,
                   ship_line_attribute4,
                   ship_line_attribute5,
                   ship_line_attribute6,
                   ship_line_attribute7,
                   ship_line_attribute8,
                   ship_line_attribute9,
                   ship_line_attribute10,
                   ship_line_attribute11,
                   ship_line_attribute12,
                   ship_line_attribute13,
                   ship_line_attribute14,
                   ship_line_attribute15,
                   ussgl_transaction_code,
                   government_context,
                   reason_id,
                   destination_context,
                   source_doc_quantity,
                   source_doc_unit_of_measure,
                   use_mtl_lot,
                   use_mtl_serial, qa_collection_id,
                   country_of_origin_code,
                   oe_order_header_id, oe_order_line_id,
                   customer_item_num, customer_id, customer_site_id,
                   mobile_txn, lpn_group_id,create_debit_memo_flag,
                   validation_flag
                  --, project_id
                  --, task_id
                  )
           VALUES (l_interface_transaction_id, l_header_interface_id
               --l_rcv_transaction_rec.header_interface_id
                  ,
                   l_rcv_transaction_rec.GROUP_ID, SYSDATE,
                   fnd_global.user_id, SYSDATE, fnd_global.user_id,
                   fnd_global.login_id, l_rcv_transaction_rec.transaction_type, SYSDATE,
                   'PENDING'                      /* Processing status code */
                            , 'BATCH',
                   NULL, 'PENDING'               /* Transaction status code */
                                  ,
                   l_rcv_transaction_rec.item_category_id,
                   l_rcv_transaction_rec.transaction_quantity,
                   l_rcv_transaction_rec.transaction_uom,
                   l_rcv_transaction_rec.product_code
                   /* interface source code */
                  ,
                   NULL                         /* interface source line id */
                       ,
                   NULL                               /* inv_transaction id */
                       ,
                   l_rcv_transaction_rec.item_id,
                   l_rcv_transaction_rec.item_description,
                   l_rcv_transaction_rec.item_revision,
                   l_rcv_transaction_rec.uom_code,
                   l_rcv_transaction_rec.employee_id,
                   l_auto_transact_code               /* Auto transact code */
                                       ,
                   l_shipment_header_id               /* shipment header id */
                                       ,
                   l_shipment_line_id                   /* shipment line id */
                                     ,
                   l_rcv_transaction_rec.ship_to_location_id,
                   l_rcv_transaction_rec.primary_quantity
                                                         /* primary quantity */
                    ,
                   l_rcv_transaction_rec.primary_uom         /* primary uom */
                                                    ,
                   l_receipt_source_code             /* receipt source code */
                                        ,
                   l_vendor_id, l_vendor_site_id,
                   l_from_org_id                             /* from org id */
                                ,
                   l_rcv_transaction_rec.from_subinventory,
                   l_to_org_id                                 /* to org id */
                              ,
                   l_rcv_transaction_rec.routing_id, 1    /* routing step id*/
                                                      ,
                   l_source_doc_code                /* source document code */
                                    ,
                   l_rcv_transaction_rec.parent_transaction_id                                    /* Parent trx id */
                       , l_po_header_id,
                   NULL                               /* PO Revision number */
                       , l_po_release_id,
                   l_po_line_id, l_po_line_location_id,
                   l_rcv_transaction_rec.unit_price,
                   l_rcv_transaction_rec.currency_code     /* Currency_Code */
                                                      ,
                   l_rcv_transaction_rec.currency_conversion_type,
                   l_rcv_transaction_rec.currency_conversion_rate,
                   TRUNC (l_rcv_transaction_rec.currency_conversion_date),
                   l_po_distribution_id               /* po_distribution_Id */
                                       ,
                   l_req_line_id, l_rcv_transaction_rec.req_distribution_id,
                   NULL                                /* Charge_Account_Id */
                       ,
                   l_sub_unordered_code        /* Substitute_Unordered_Code */
                                       ,
                   l_rcv_transaction_rec.receipt_exception
                                                          /* Receipt_Exception_Flag  forms check box?*/
      ,
                   NULL                              /* Accrual_Status_Code */
                       ,
                   'NOT INSPECTED'                /* Inspection_Status_Code */
                                  ,
                   NULL                          /* Inspection_Quality_Code */
                       ,
                   l_rcv_transaction_rec.destination_type_code
                                                              /* Destination_Type_Code */
      ,
                   l_deliver_to_person_id           /* Deliver_To_Person_Id */
                                         ,
                   l_location_id                             /* Location_Id */
                                ,
                   l_deliver_to_location_id       /* Deliver_To_Location_Id */
                                           ,
                   l_subinventory                           /* Subinventory */
                                 ,
                   l_locator_id                               /* Locator_Id */
                               ,
                   l_wip_entity_id                         /* Wip_Entity_Id */
                                  ,
                   l_wip_line_id                             /* Wip_Line_Id */
                                ,
                   l_department_code                     /* Department_Code */
                                    ,
                   l_wip_rep_sched_id         /* Wip_Repetitive_Schedule_Id */
                                     ,
                   l_wip_oper_seq_num              /* Wip_Operation_Seq_Num */
                                     ,
                   l_wip_res_seq_num                /* Wip_Resource_Seq_Num */
                                    ,
                   l_bom_resource_id                     /* Bom_Resource_Id */
                                    ,
                   l_rcv_transaction_rec.rcv_shipment_number, NULL,
                   NULL                                   /* Bill_Of_Lading */
                       , NULL                               /* Packing_Slip */
                             ,
                   TRUNC (l_rcv_transaction_rec.shipped_date),
                   TRUNC (l_rcv_transaction_rec.expected_receipt_date)
                                                                      /* Expected_Receipt_Date */
      ,
                   NULL                                      /* Actual_Cost */
                       , NULL                              /* Transfer_Cost */
                             ,
                   NULL                              /* Transportation_Cost */
                       ,
                   NULL                        /* Transportation_Account_Id */
                       ,
                   NULL                                /* Num_Of_Containers */
                       ,
                   NULL                              /* Waybill_Airbill_Num */
                       ,
                   l_rcv_transaction_rec.vendor_item_number
                                                           /* Vendor_Item_Num */
      ,
                   l_rcv_transaction_rec.vendor_lot_num   /* Vendor_Lot_Num */
                                                       ,
                   NULL                                    /* Rma_Reference */
                       ,
                   l_rcv_transaction_rec.comments   /* Comments  ? from form*/
                                                 ,
                   l_rcv_transaction_rec.attribute_category
                                                           /* Attribute_Category */
      ,
                   l_rcv_transaction_rec.attribute1           /* Attribute1 */
                                                   ,
                   l_rcv_transaction_rec.attribute2           /* Attribute2 */
                                                   ,
                   l_rcv_transaction_rec.attribute3           /* Attribute3 */
                                                   ,
                   l_rcv_transaction_rec.attribute4           /* Attribute4 */
                                                   ,
                   l_rcv_transaction_rec.attribute5           /* Attribute5 */
                                                   ,
                   l_rcv_transaction_rec.attribute6           /* Attribute6 */
                                                   ,
                   l_rcv_transaction_rec.attribute7           /* Attribute7 */
                                                   ,
                   l_rcv_transaction_rec.attribute8           /* Attribute8 */
                                                   ,
                   l_rcv_transaction_rec.attribute9           /* Attribute9 */
                                                   ,
                   l_rcv_transaction_rec.attribute10         /* Attribute10 */
                                                    ,
                   l_rcv_transaction_rec.attribute11         /* Attribute11 */
                                                    ,
                   l_rcv_transaction_rec.attribute12         /* Attribute12 */
                                                    ,
                   l_rcv_transaction_rec.attribute13         /* Attribute13 */
                                                    ,
                   l_rcv_transaction_rec.attribute14         /* Attribute14 */
                                                    ,
                   l_rcv_transaction_rec.attribute15         /* Attribute15 */
                                                    ,
                   NULL                     /* Ship_Head_Attribute_Category */
                       ,
                   NULL                             /* Ship_Head_Attribute1 */
                       ,
                   NULL                             /* Ship_Head_Attribute2 */
                       ,
                   NULL                             /* Ship_Head_Attribute3 */
                       ,
                   NULL                             /* Ship_Head_Attribute4 */
                       ,
                   NULL                             /* Ship_Head_Attribute5 */
                       ,
                   NULL                             /* Ship_Head_Attribute6 */
                       ,
                   NULL                             /* Ship_Head_Attribute7 */
                       ,
                   NULL                             /* Ship_Head_Attribute8 */
                       ,
                   NULL                             /* Ship_Head_Attribute9 */
                       ,
                   NULL                            /* Ship_Head_Attribute10 */
                       ,
                   NULL                            /* Ship_Head_Attribute11 */
                       ,
                   NULL                            /* Ship_Head_Attribute12 */
                       ,
                   NULL                            /* Ship_Head_Attribute13 */
                       ,
                   NULL                            /* Ship_Head_Attribute14 */
                       ,
                   NULL                            /* Ship_Head_Attribute15 */
                       ,
                   NULL                     /* Ship_Line_Attribute_Category */
                       ,
                   NULL                             /* Ship_Line_Attribute1 */
                       ,
                   NULL                             /* Ship_Line_Attribute2 */
                       ,
                   NULL                             /* Ship_Line_Attribute3 */
                       ,
                   NULL                             /* Ship_Line_Attribute4 */
                       ,
                   NULL                             /* Ship_Line_Attribute5 */
                       ,
                   NULL                             /* Ship_Line_Attribute6 */
                       ,
                   NULL                             /* Ship_Line_Attribute7 */
                       ,
                   NULL                             /* Ship_Line_Attribute8 */
                       ,
                   NULL                             /* Ship_Line_Attribute9 */
                       ,
                   NULL                            /* Ship_Line_Attribute10 */
                       ,
                   NULL                            /* Ship_Line_Attribute11 */
                       ,
                   NULL                            /* Ship_Line_Attribute12 */
                       ,
                   NULL                            /* Ship_Line_Attribute13 */
                       ,
                   NULL                            /* Ship_Line_Attribute14 */
                       ,
                   NULL                            /* Ship_Line_Attribute15 */
                       ,
                   l_rcv_transaction_rec.ussgl_transaction_code
                                                               /* Ussgl_Transaction_Code */
      ,
                   l_rcv_transaction_rec.government_context
                                                           /* Government_Context */
      ,
                   l_rcv_transaction_rec.reason_id                     /* ? */
                                                  ,
                   l_rcv_transaction_rec.destination_type_code
                                                              /* Destination_Context */
      ,
                   l_rcv_transaction_rec.ordered_qty,
                   l_rcv_transaction_rec.ordered_uom,
                   l_rcv_transaction_rec.lot_control_code,
                   l_rcv_transaction_rec.serial_number_control_code, NULL,
                   l_rcv_transaction_rec.country_of_origin_code,
                   l_oe_order_header_id, l_oe_order_line_id,
                   l_customer_item_num, l_customer_id, l_customer_site_id,
                   'N'                                        /* mobile_txn */
                      , NULL                                 -- l_lpn_group_id
                            ,l_rcv_transaction_rec.create_debit_memo_flag,
                   l_validation_flag
                  --, l_project_id
                  --, l_task_id
                  );

      x_interface_transaction_id := l_interface_transaction_id;
   EXCEPTION
      WHEN fnd_api.g_exc_error
      THEN
         jtf_plsql_api.handle_exceptions
                           (p_api_name             => l_api_name,
                            p_pkg_name             => g_pkg_name,
                            p_exception_level      => fnd_msg_pub.g_msg_lvl_error,
                            p_package_type         => jtf_plsql_api.g_pvt,
                            x_msg_count            => x_msg_count,
                            x_msg_data             => x_message,
                            x_return_status        => x_return_status
                           );
      WHEN fnd_api.g_exc_unexpected_error
      THEN
         jtf_plsql_api.handle_exceptions
                     (p_api_name             => l_api_name,
                      p_pkg_name             => g_pkg_name,
                      p_exception_level      => fnd_msg_pub.g_msg_lvl_unexp_error,
                      p_package_type         => jtf_plsql_api.g_pvt,
                      x_msg_count            => x_msg_count,
                      x_msg_data             => x_message,
                      x_return_status        => x_return_status
                     );
      WHEN OTHERS
      THEN
         fnd_message.set_name ('CSP', 'CSP_UNEXPECTED_EXEC_ERRORS');
         fnd_message.set_token ('ROUTINE', l_api_name, TRUE);
         fnd_message.set_token ('SQLERRM', SQLERRM, TRUE);
         fnd_msg_pub.ADD;
         jtf_plsql_api.handle_exceptions
                            (p_api_name             => l_api_name,
                             p_pkg_name             => g_pkg_name,
                             p_exception_level      => jtf_plsql_api.g_exc_others,
                             p_package_type         => jtf_plsql_api.g_pvt,
                             x_msg_count            => x_msg_count,
                             x_msg_data             => x_message,
                             x_return_status        => x_return_status
                            );
   END;

/***************************************************************************************/
   PROCEDURE rcv_online_request (
      p_group_id        IN              NUMBER,
      x_return_status   OUT NOCOPY      VARCHAR2,
      x_msg_data        OUT NOCOPY      VARCHAR2
   )
   IS
      rc                NUMBER;
      l_api_name        VARCHAR2 (20)   := 'rcv_online_request';
      l_timeout         NUMBER          := 300;
      l_outcome         VARCHAR2 (200)  := NULL;
      l_message         VARCHAR2 (2000) := NULL;
      l_return_status   VARCHAR2 (5)    := fnd_api.g_ret_sts_success;
      l_msg_count       NUMBER;
      x_str             VARCHAR2 (6000) := NULL;
      delete_rows       BOOLEAN         := FALSE;
      r_val1            VARCHAR2 (300)  := NULL;
      r_val2            VARCHAR2 (300)  := NULL;
      r_val3            VARCHAR2 (300)  := NULL;
      r_val4            VARCHAR2 (300)  := NULL;
      r_val5            VARCHAR2 (300)  := NULL;
      r_val6            VARCHAR2 (300)  := NULL;
      r_val7            VARCHAR2 (300)  := NULL;
      r_val8            VARCHAR2 (300)  := NULL;
      r_val9            VARCHAR2 (300)  := NULL;
      r_val10           VARCHAR2 (300)  := NULL;
      r_val11           VARCHAR2 (300)  := NULL;
      r_val12           VARCHAR2 (300)  := NULL;
      r_val13           VARCHAR2 (300)  := NULL;
      r_val14           VARCHAR2 (300)  := NULL;
      r_val15           VARCHAR2 (300)  := NULL;
      r_val16           VARCHAR2 (300)  := NULL;
      r_val17           VARCHAR2 (300)  := NULL;
      r_val18           VARCHAR2 (300)  := NULL;
      r_val19           VARCHAR2 (300)  := NULL;
      r_val20           VARCHAR2 (300)  := NULL;
      l_progress        VARCHAR2 (10)   := '10';
      --  debug_handler utl_file.file_type;
      x_msg_count       NUMBER;
      po_message        VARCHAR2 (2000);
   BEGIN
      x_return_status := fnd_api.g_ret_sts_success;
      --   debug_handler := UTL_FILE.FOPEN('/slot06/oracle/SCMC1MQ1db/9.2.0/temp', 'FieldServicePortal.log','a');
      rc :=
         fnd_transaction.synchronous (l_timeout,
                                      l_outcome,
                                      l_message,
                                      'PO',
                                      'RCVTPO',
                                      'ONLINE',
                                      p_group_id,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL,
                                      NULL
                                     );
      DBMS_OUTPUT.put_line ('The RC outcome :' || l_outcome || '   '
                            || l_message
                           );
      DBMS_OUTPUT.put_line ('The RC Values IS :' || rc);

      IF (rc = 1)
      THEN
         fnd_message.set_name ('FND', 'TM-TIMEOUT');
         fnd_message.set_name ('FND', 'CONC-Error running standalone');
         fnd_message.set_token ('PROGRAM',
                                'Receiving Transaction Manager - RCVOLTM'
                               );
         fnd_message.set_token ('REQUEST', p_group_id);
         fnd_message.set_token ('REASON', x_str);
         fnd_msg_pub.ADD;
         x_return_status := fnd_api.g_ret_sts_error;
      ELSIF (rc = 2)
      THEN
         fnd_message.set_name ('FND', 'TM-SVC LOCK HANDLE FAILED');
         fnd_message.set_name ('FND', 'CONC-Error running standalone');
         fnd_message.set_token ('PROGRAM',
                                'Receiving Transaction Manager - RCVOLTM'
                               );
         fnd_message.set_token ('REQUEST', p_group_id);
         fnd_message.set_token ('REASON', x_str);
         fnd_msg_pub.ADD;
         x_return_status := fnd_api.g_ret_sts_error;
      ELSIF (rc = 3 OR (l_outcome IN ('WARNING', 'ERROR')))
      THEN
         BEGIN
            SELECT error_message
              INTO po_message
              FROM po_interface_errors pie, rcv_headers_interface rhi
             WHERE batch_id = p_group_id
               AND table_name = 'RCV_HEADERS_INTERFACE'
               AND pie.interface_header_id = rhi.header_interface_id
               AND processing_status_code = 'ERROR';

            fnd_message.set_name ('CSP', 'CSP_PO_RECEIVE_ERROR');
            fnd_message.set_token ('ERROR_MESSAGE', po_message);
            fnd_msg_pub.ADD;
            x_return_status := fnd_api.g_ret_sts_error;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               rc :=
                  fnd_transaction.get_values (r_val1,
                                              r_val2,
                                              r_val3,
                                              r_val4,
                                              r_val5,
                                              r_val6,
                                              r_val7,
                                              r_val8,
                                              r_val9,
                                              r_val10,
                                              r_val11,
                                              r_val12,
                                              r_val13,
                                              r_val14,
                                              r_val15,
                                              r_val16,
                                              r_val17,
                                              r_val18,
                                              r_val19,
                                              r_val20
                                             );
               x_str := r_val1;

               IF (r_val2 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val2;
               END IF;

               IF (r_val3 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val3;
               END IF;

               IF (r_val4 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val4;
               END IF;

               IF (r_val5 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val5;
               END IF;

               IF (r_val6 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val6;
               END IF;

               IF (r_val7 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val7;
               END IF;

               IF (r_val8 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val8;
               END IF;

               IF (r_val9 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val9;
               END IF;

               IF (r_val10 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val10;
               END IF;

               IF (r_val11 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val11;
               END IF;

               IF (r_val12 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val12;
               END IF;

               IF (r_val13 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val13;
               END IF;

               IF (r_val14 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val14;
               END IF;

               IF (r_val15 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val15;
               END IF;

               IF (r_val16 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val16;
               END IF;

               IF (r_val17 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val17;
               END IF;

               IF (r_val18 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val18;
               END IF;

               IF (r_val19 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val19;
               END IF;

               IF (r_val20 IS NOT NULL)
               THEN
                  x_str := x_str || ' ' || r_val20;
               END IF;

               DBMS_OUTPUT.put_line ('String Value Is :' || x_str);
               fnd_message.set_name ('FND', 'CONC-Error running standalone');
               fnd_message.set_token
                                    ('PROGRAM',
                                     'Receiving Transaction Manager - RCVOLTM'
                                    );
               fnd_message.set_token ('REQUEST', p_group_id);
               fnd_message.set_token ('REASON', x_str);
               fnd_msg_pub.ADD;
               x_return_status := fnd_api.g_ret_sts_error;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data :=
               x_return_status
            || 'error while submitting rcv_online_request '
            || SQLERRM;
         log_exception
               (p_error_location          => 'XX_CS_TDS_PARTS_RECEIPTS.RCV_ONLINE_REQ',
                p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                p_error_msg               => x_msg_data
               );
         DBMS_OUTPUT.put_line
                      (   'Other Exceptions in rcv_online_request procedure :'
                       || SQLERRM
                      );
   END rcv_online_request;

/*
Function : USER_INPUT_REQUIRED
*/
   FUNCTION user_input_required (p_header_id NUMBER)
      RETURN VARCHAR2
   IS
      l_header_id             NUMBER;
      l_count                 NUMBER;
      l_locator_controlled    VARCHAR2 (1);
      l_user_input_required   VARCHAR2 (1);

      CURSOR check_serial_lot_revision
      IS
         SELECT source_type_code, serial_number_control_code,
                lot_control_code, item_rev_control_flag_to, serial_num,
                lot_num, item_revision, doc_type_code, item_id,
                to_organization_id, destination_subinventory
           FROM csp_receive_lines_v
          WHERE rcv_shipment_header_id = l_header_id;

      CURSOR locator_check (
         v_org_id    NUMBER,
         v_item_id   NUMBER,
         v_sub_inv   VARCHAR2
      )
      IS
         SELECT 'Y'
           FROM mtl_parameters a,
                mtl_system_items_b b,
                mtl_secondary_inventories c
          WHERE a.organization_id = b.organization_id
            AND a.organization_id = c.organization_id
            AND a.organization_id = v_org_id
            AND b.inventory_item_id = v_item_id
            AND c.secondary_inventory_name = v_sub_inv
            AND (   a.stock_locator_control_code IN
                                        (2, 3) --Org Control should be  2 or 3
                 OR     a.stock_locator_control_code = 4
                    AND c.locator_type IN
                                 (2, 3) --org Control 4 and sub control 2 or 3
                 OR     a.stock_locator_control_code = 4
                    AND c.locator_type = 5
                    AND b.location_control_code IN (2, 3)
                );
   BEGIN
      l_header_id := p_header_id;
      l_locator_controlled := 'N';                  -- not locator controlled
      l_count := 0;
      l_user_input_required := 'N';

--First Check Serial Lot and Revision Control of Item
      FOR l_serial_lot_rec IN check_serial_lot_revision
      LOOP
         IF (    l_serial_lot_rec.serial_number_control_code > 1
             AND l_serial_lot_rec.serial_num IS NULL
            )
         THEN
            IF     l_serial_lot_rec.serial_number_control_code = 6
               AND l_serial_lot_rec.doc_type_code = 'PO'
            THEN
               l_user_input_required := 'N';
            ELSE
               l_user_input_required := 'Y';
               EXIT;
            END IF;
         END IF;

         IF (    l_serial_lot_rec.lot_control_code > 1
             AND l_serial_lot_rec.lot_num IS NULL
            )
         THEN
            l_user_input_required := 'Y';
            EXIT;
         END IF;

         IF (    l_serial_lot_rec.item_rev_control_flag_to = 'Y'
             AND l_serial_lot_rec.item_revision IS NULL
            )
         THEN
            l_user_input_required := 'Y';
            EXIT;
         END IF;

         OPEN locator_check (l_serial_lot_rec.to_organization_id,
                             l_serial_lot_rec.item_id,
                             l_serial_lot_rec.destination_subinventory
                            );

         FETCH locator_check
          INTO l_locator_controlled;

         CLOSE locator_check;

         IF (l_locator_controlled = 'Y')
         THEN
            RETURN 'Y';
         END IF;
      END LOOP;

      IF l_user_input_required = 'Y'
      THEN
         RETURN 'Y';
      END IF;

      RETURN 'N';
   END user_input_required;

/******************************************************************************/
   FUNCTION vendor (p_vendor_id NUMBER)
      RETURN VARCHAR2
   IS
      l_vendor   VARCHAR2 (240);

      CURSOR c_vendor
      IS
         SELECT vendor_name
           FROM po_vendors
          WHERE vendor_id = p_vendor_id;
   BEGIN
      OPEN c_vendor;

      FETCH c_vendor
       INTO l_vendor;

      CLOSE c_vendor;

      RETURN l_vendor;
   END vendor;
END xx_cs_tds_parts_receipts;
/
show errors;
exit;