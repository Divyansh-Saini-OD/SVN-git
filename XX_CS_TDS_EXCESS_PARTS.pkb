create or replace
PACKAGE BODY      xx_cs_tds_excess_parts
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_TDS_EXCESS_PARTS                                   |
-- |                                                                   |
-- | Description: Wrapper package for excess returns.                  |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       21-Jul-11   Raj Jagarlamudi  Initial draft version       |
-- |2.0       22-Jan-16   Vasu Raparla     Removed Schema References   |
-- |                                       for R.12.2                  |
-- +===================================================================+

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
                              p_program_name                => 'XX_CS_TDS_EXCESS_PARTS_PKG',
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

/**************************************************************************/
   PROCEDURE excess_returns (
      p_document_number    IN              VARCHAR2,
      p_validation_level   IN              NUMBER,
      p_resource_id        IN              NUMBER,
      x_return_status      OUT NOCOPY      VARCHAR2,
      x_msg_count          OUT NOCOPY      NUMBER,
      x_msg_data           OUT NOCOPY      VARCHAR2
   )
   AS
      l_sqlcode                       NUMBER;
      l_sqlerrm                       VARCHAR2 (4000);
      l_api_name                      CONSTANT VARCHAR2 (30) := 'excess_returns';
      l_api_version_number            CONSTANT NUMBER := 1.0;
      l_return_status_full            VARCHAR2 (1);
      x_message                       VARCHAR2 (2000);
      i                               NUMBER;

      CURSOR c_subinventory (p_inv_loc_assignment_id NUMBER)
      IS
         SELECT subinventory_code, organization_id
           FROM csp_inv_loc_assignments
          WHERE csp_inv_loc_assignment_id = p_inv_loc_assignment_id;

      CURSOR get_line_cur (l_doc_number IN VARCHAR2)
      IS
         SELECT xc.request_number, 
                xc.item_number, 
                xc.rms_sku,
                xc.received_quantity, 
                xc.received_shipment_flag,
                xc.excess_quantity, 
                xc.excess_flag, 
                xc.line_number,
                rs.transaction_type,
                'PO' order_type_code, 
                'VENDOR' receipt_source_code,
                rs.organization_id,
                NVL (rs.subinventory, 'STOCK') subinventory, 
                pol.item_id,
                pol.item_description, 
                pol.category_id, 
                rs.vendor_id,
                rs.vendor_site_id, 
                rs.deliver_to_location_id,
                rs.deliver_to_person_id, 
                rs.location_id,
                rs.inspection_status_code, 
                rs.routing_step_id,
                rs.routing_header_id,
                NVL (rs.currency_conversion_date,
                     SYSDATE
                    ) currency_conversion_date,
                rs.currency_conversion_rate, 
                rs.currency_conversion_type,
                rs.currency_code, 
                rs.po_unit_price, 
                rs.po_header_id,
                rs.po_line_id, 
                rs.po_line_location_id, 
                rs.po_distribution_id,
                rs.parent_transaction_id, 
                rs.employee_id, 
                rs.uom_code,
                rs.primary_unit_of_measure, 
                rs.primary_quantity,
                rs.destination_type_code, 
                rs.source_document_code,
                rs.interface_source_code, 
                rs.shipment_line_id,
                rs.shipment_header_id, 
                rs.unit_of_measure, 
                rs.quantity,
                rs.transaction_id
           FROM xx_cs_tds_parts xc,
                po_headers_all poh,
                po_lines_all pol,
                po_line_locations_all poll,
                po_distributions_all pod,
                rcv_shipment_headers rsh,
                rcv_shipment_lines rsl,
                rcv_transactions rs
          WHERE xc.request_number = poh.segment1
            AND poh.po_header_id = pol.po_header_id
            AND xc.inventory_item_id = pol.item_id
            AND pol.po_line_id = poll.po_line_id
            AND xc.store_id = poll.ship_to_organization_id
            AND poll.line_location_id = pod.line_location_id
            AND rsh.shipment_header_id = rsl.shipment_header_id
            AND rsl.shipment_line_id = rs.shipment_line_id
            AND rs.po_header_id = pod.po_header_id
            AND rs.po_line_id = pod.po_line_id
            AND rs.po_line_location_id = pod.line_location_id
            AND rs.po_distribution_id = pod.po_distribution_id
            AND rs.transaction_type = 'DELIVER'
            AND xc.request_number = p_document_number             
            AND xc.excess_quantity > 0
            AND xc.received_shipment_flag = 'R'
            AND NVL (xc.excess_flag, 'N') = 'Y'
            AND nvl(xc.attribute2,'N') = 'N'
            AND nvl(xc.attribute4,'N') <> 'Y';

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
      l_rcv_transaction_rec           xx_cs_tds_parts_receipts.rcv_rec_type;
      l_employee_id                   NUMBER;
      l_employee_name                 VARCHAR2 (240);
      l_location_code                 VARCHAR2 (60);
      l_location_id                   NUMBER;
      l_is_buyer                      BOOLEAN;
      l_emp_flag                      BOOLEAN;
      l_po_header_id                  NUMBER;
      l_request_id                    NUMBER;
      lc_excess_flag                  VARCHAR2 (1)                      := 'N';
      l_resp_id                       NUMBER                          := 50501;
      -- Fnd_Global.Resp_Id;
      l_resp_appl_id         CONSTANT PLS_INTEGER                       := 201;
      --Fnd_Global.Resp_Appl_Id;
      l_user_id                       NUMBER                        := 1197067;
   BEGIN
      x_return_status := 'S';

      -- Check receipt flag
      BEGIN
         SELECT 'Y'
           INTO lc_excess_flag
           FROM xx_cs_tds_parts
          WHERE request_number = p_document_number
            AND NVL (excess_flag, 'N') = 'Y'
            AND nvl(attribute4,'N') <> 'Y'
            AND ROWNUM < 2;
      EXCEPTION
         WHEN OTHERS
         THEN
            lc_excess_flag := 'N';
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

      IF NVL (lc_excess_flag, 'N') = 'Y'
      THEN
         IF (l_group_id IS NULL)
         THEN
            SELECT rcv_interface_groups_s.NEXTVAL
              INTO l_group_id
              FROM SYS.DUAL;
         END IF;

         FOR c_line_rec IN get_line_cur (p_document_number)
         LOOP
            l_po_header_id := c_line_rec.po_header_id;

            SELECT employee_id
              INTO l_employee_id
              FROM fnd_user
             WHERE user_name LIKE UPPER ('Merchandize Buyer');

            i := i + 1;
            l_organization_id := c_line_rec.organization_id;
            l_subinventory := 'STOCK';
            l_rcv_transaction_rec.source_type_code := 'VENDOR';
            l_rcv_transaction_rec.transaction_type := 'RETURN TO VENDOR';
            l_rcv_transaction_rec.destination_type_code := c_line_rec.destination_type_code;
            l_rcv_transaction_rec.order_type_code := c_line_rec.order_type_code;
            l_rcv_transaction_rec.routing_id := c_line_rec.routing_header_id;
            l_rcv_transaction_rec.header_interface_id := NULL;
                                                      --l_header_interface_id;
            l_rcv_transaction_rec.GROUP_ID := l_group_id;
            l_rcv_transaction_rec.employee_id := l_employee_id;
            --l_rcv_transaction_rec.to_organization_id := c_line_rec.organization_id;
            l_rcv_transaction_rec.from_organization_id :=
                                                    c_line_rec.organization_id;
            --l_organization_id;
            l_rcv_transaction_rec.from_subinventory := c_line_rec.subinventory;
            --l_subinventory;
            l_rcv_transaction_rec.po_line_location_id :=
                                                c_line_rec.po_line_location_id;
            l_rcv_transaction_rec.item_id := c_line_rec.item_id;
            l_rcv_transaction_rec.uom_code := c_line_rec.uom_code;
            l_rcv_transaction_rec.transaction_uom :=
                                                    c_line_rec.unit_of_measure;
            l_rcv_transaction_rec.primary_uom :=
                                            c_line_rec.primary_unit_of_measure;
            l_rcv_transaction_rec.item_description :=
                                                   c_line_rec.item_description;
            l_rcv_transaction_rec.item_category_id := c_line_rec.category_id;
            l_rcv_transaction_rec.primary_uom_class := NULL;
                                               --c_line_rec.primary_uom_class;
            l_rcv_transaction_rec.ship_to_location_id := NULL;
                                          --c_line_rec.deliver_to_location_id;
            l_rcv_transaction_rec.vendor_id := c_line_rec.vendor_id;
            l_rcv_transaction_rec.vendor_site_id := c_line_rec.vendor_site_id;
            l_rcv_transaction_rec.po_header_id := c_line_rec.po_header_id;
            l_rcv_transaction_rec.po_release_id := NULL;
                                                   --c_line_rec.po_release_id;
            l_rcv_transaction_rec.po_line_id := c_line_rec.po_line_id;
            l_rcv_transaction_rec.po_line_location_id :=
                                                c_line_rec.po_line_location_id;
            l_rcv_transaction_rec.po_distribution_id :=
                                                 c_line_rec.po_distribution_id;
            l_rcv_transaction_rec.receipt_source_code :=
                                                c_line_rec.receipt_source_code;
            l_rcv_transaction_rec.req_line_id := NULL;
                                                     --c_line_rec.req_line_id;
            l_rcv_transaction_rec.rcv_shipment_header_id :=
                                                 c_line_rec.shipment_header_id;
            l_rcv_transaction_rec.rcv_shipment_line_id :=
                                                   c_line_rec.shipment_line_id;
            l_rcv_transaction_rec.parent_transaction_id :=
                                                     c_line_rec.transaction_id;
            l_rcv_transaction_rec.unit_price := c_line_rec.po_unit_price;
            l_rcv_transaction_rec.currency_code := c_line_rec.currency_code;
            l_rcv_transaction_rec.currency_conversion_type :=
                                           c_line_rec.currency_conversion_type;
            l_rcv_transaction_rec.currency_conversion_date :=
                    NVL (c_line_rec.currency_conversion_date, TRUNC (SYSDATE));
            l_rcv_transaction_rec.currency_conversion_rate :=
                                           c_line_rec.currency_conversion_rate;
            l_rcv_transaction_rec.ordered_qty := c_line_rec.quantity;
            l_rcv_transaction_rec.transaction_quantity :=
                                                    c_line_rec.excess_quantity;
            l_rcv_transaction_rec.deliver_to_person_id :=
                          NVL (c_line_rec.deliver_to_person_id, l_employee_id);
            l_rcv_transaction_rec.deliver_to_location_id := NULL;
                                         -- c_line_rec.deliver_to_location_id;
            l_rcv_transaction_rec.create_debit_memo_flag := 'Y';
                                         
            l_rcv_transaction_rec.primary_quantity :=
               rcv_transactions_interface_sv.convert_into_correct_qty
                                          (c_line_rec.excess_quantity,
                                           c_line_rec.primary_unit_of_measure,
                                           c_line_rec.item_id,
                                           c_line_rec.primary_unit_of_measure
                                          );
            -- dbms_output.put_line('Before calling rcv_txn_interface');
            xx_cs_tds_parts_receipts.insert_rcv_txn_interface
                    (p_api_version_number            => l_api_version_number,
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
                  (p_error_location          => 'XX_CS_TDS_EXCESS_PARTS_PKG.EXCESS_PARTS',
                   p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
                  
                  UPDATE xx_cs_tds_parts
                     SET attribute2 = 'E',
                     last_udate_date = sysdate
                   WHERE request_number = p_document_number
                     AND line_number = c_line_rec.line_number
                     AND inventory_item_id = c_line_rec.item_id;
              ELSE
                  UPDATE xx_cs_tds_parts
                     SET attribute2 = 'N',
                        last_udate_date = sysdate
                   WHERE request_number = p_document_number
                     AND line_number = c_line_rec.line_number
                     AND inventory_item_id = c_line_rec.item_id;
            END IF;
         END LOOP;
      

         COMMIT;
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
            -- DBMS_OUTPUT.put_line ('Request ID:' || l_request_id);

             IF l_request_id <= 0
             THEN
                 x_msg_data :=
                      x_msg_data
                   || 'error in concurrent request '
                   || l_header_interface_id
                   || SQLERRM;
                log_exception
                   (p_error_location          => 'XX_CS_TDS_EXCESS_PARTS.EXCESS_PARTS',
                    p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                    p_error_msg               => x_msg_data
                   );
             END IF;
                           
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data :=
               x_return_status
            || ' When Others error while inserting receipts data'
            || SQLERRM;
         log_exception
                  (p_error_location          => 'XX_CS_TDS_EXCESS_PARTS.EXCESS_PARTS',
                   p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
   END excess_returns;
END xx_cs_tds_excess_parts;
/
show errors;
exit;