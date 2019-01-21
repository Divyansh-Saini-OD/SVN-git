SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_CS_TDS_PARTS_PKG
PROMPT Program exits if the creation is not successful
create or replace
PACKAGE BODY xx_cs_tds_parts_pkg
-- +=============================================================================================+
-- |                       Office Depot - TDS                                                    |
-- |                                                                                             |
-- +=============================================================================================+
-- | Name         : Xx_Cs_Tds_Parts_Pkg.sql                                                      |
-- | Description  : This package is used to add the selected parts, create items in inventory    |
-- |                and create the requisition and PO for the vendor                             |
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  11-Jul-2011  Deepti S  Initial draft version                                       |
-- +=============================================================================================+
IS
   PROCEDURE log_exception (
      p_object_id            IN   VARCHAR2,
      p_error_location       IN   VARCHAR2,
      p_error_message_code   IN   VARCHAR2,
      p_error_msg            IN   VARCHAR2
   )
   IS
   BEGIN
      xx_com_error_log_pub.log_error
                               (p_return_code                 => fnd_api.g_ret_sts_error,
                                p_msg_count                   => 1,
                                p_application_name            => 'XX_CRM',
                                p_program_type                => 'Custom Messages',
                                p_program_name                => 'XX_CS_TDS_PARTS_PKG',
                                p_program_id                  => NULL,
                                p_object_id                   => p_object_id,
                                p_module_name                 => 'CSF',
                                p_error_location              => p_error_location,
                                p_error_message_code          => p_error_message_code,
                                p_error_message               => p_error_msg,
                                p_error_message_severity      => 'MAJOR',
                                p_error_status                => 'ACTIVE',
                                p_created_by                  => g_user_id,
                                p_last_updated_by             => g_user_id,
                                p_last_update_login           => g_login_id
                               );
   END log_exception;

-- +=============================================================================+
-- | PROCEDURE NAME : ADD_PARTS                                                  |
-- | DESCRIPTION    : This procedure adds the parts to the corresponding         |
-- |                  service request and updates the status of service request  |
-- |                  to pending for approval                                    |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |                                                 |
-- |             :  P_Store_Number    IN            VARCHAR2    SR number        |
-- |             :  P_PARTS_TABLE     IN            Table type   Table           |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE add_parts (
      p_sr_number        IN       VARCHAR2,
      p_store_number     IN       VARCHAR2,
      p_parts_table      IN       xx_cs_tds_parts_tbl_type,
      x_return_status    IN OUT   VARCHAR2,
      x_return_message   IN OUT   VARCHAR2
   )
   IS
      l_incident_id      NUMBER;
      l_store_id         NUMBER;
      l_return_status    VARCHAR2 (30);
      l_msg_count        NUMBER;
      l_msg_data         VARCHAR2 (4000);
      l_msg_index_out    VARCHAR2 (20);
      l_obj_ver_num      NUMBER;
      l_sr_status_id     NUMBER;
      l_sr_status        VARCHAR2 (20);
      l_que_index        NUMBER;
      l_sku              VARCHAR2 (80)   := NULL;
      l_selling_cost     NUMBER          := 0;
      l_selling_price    NUMBER          := 0;
      l_interaction_id   NUMBER;
   BEGIN
      l_return_status := NULL;
      l_msg_count := 0;
      l_msg_data := NULL;
      l_interaction_id := NULL;

      -- Get user_id
      SELECT user_id
        INTO g_user_id
        FROM fnd_user
       WHERE user_name = 'CS_ADMIN';

       -- Initialize the environment
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);

      -- fnd_global.apps_initialize (G_User_Id, 50598, --g_resp_id,
                                             -- 514) ; --g_resp_appl_id);

      --get Store_id
      BEGIN
         SELECT organization_id
           INTO l_store_id
           FROM hr_all_organization_units
          WHERE attribute1 = p_store_number;

         DBMS_OUTPUT.put_line ('Store ID  -' || l_store_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_msg_data := 'Error in finding the Organization ID: ' || SQLERRM;
            l_return_status := fnd_api.g_ret_sts_error;
            log_exception
                        (p_object_id               => p_sr_number,
                         p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS',
                         p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                         p_error_msg               => l_msg_data
                        );
      END;

      l_que_index := p_parts_table.FIRST;
      DBMS_OUTPUT.put_line ('Looping based on no of items');

      WHILE l_que_index IS NOT NULL
      LOOP
         ---Get dummy (RMS) SKU from CS Lookups based on Category .
           
         BEGIN
            SELECT meaning
              INTO l_sku
              FROM cs_lookups
             WHERE lookup_type = 'XX_CS_TDS_PARTS_ITEM_REF'
               AND lookup_code = p_parts_table (l_que_index).item_category;

            DBMS_OUTPUT.put_line ('Dummy SKU - ' || l_sku);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data := 'Error in finding the RMS SKU: ' || SQLERRM;
               l_return_status := fnd_api.g_ret_sts_error;
               log_exception
                        (p_object_id               => p_sr_number,
                         p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS',
                         p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                         p_error_msg               => l_msg_data
                        );
         END;

         --Calculate the Selling Price with Custom profile.
         BEGIN
            SELECT fnd_profile.VALUE ('XX_CS_PARTS_SELLING_COST')
              INTO l_selling_cost
              FROM DUAL;

            l_selling_price :=
                 p_parts_table (l_que_index).purchase_price
               + (  p_parts_table (l_que_index).purchase_price
                  * l_selling_cost
                  / 100
                 );
            DBMS_OUTPUT.put_line ('Success! selling cost - ' || l_selling_cost);
            DBMS_OUTPUT.put_line (   'Purchase price '
                                  || p_parts_table (l_que_index).purchase_price
                                 );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data := 'Error in finding the Selling Cost: ' || SQLERRM;
               l_return_status := fnd_api.g_ret_sts_error;
               log_exception
                        (p_object_id               => p_sr_number,
                         p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS',
                         p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                         p_error_msg               => l_msg_data
                        );
         END;

         DBMS_OUTPUT.put_line ('Selling Price:' || l_selling_price);

         -- Insert into custom table
         BEGIN
            INSERT INTO xxom.xx_cs_tds_parts
                 VALUES (p_sr_number, l_store_id, l_que_index,
                         p_parts_table (l_que_index).item_number,
                         p_parts_table (l_que_index).item_description, l_sku,
                         p_parts_table (l_que_index).quantity,
                         p_parts_table (l_que_index).item_category,
                         p_parts_table (l_que_index).purchase_price,
                         l_selling_price,
                         p_parts_table (l_que_index).exchange_price,
                         p_parts_table (l_que_index).core_flag,
                         p_parts_table (l_que_index).uom,
                         p_parts_table (l_que_index).schedule_date, SYSDATE,
                         g_user_id, SYSDATE, g_user_id, NULL, NULL, NULL,
                         NULL, NULL,NULL,
                          p_parts_table (l_que_index).Manufacturer
                         ,p_parts_table (l_que_index).Model
                         ,p_parts_table (l_que_index).Serial_number
                         ,p_parts_table (l_que_index).Prob_descr
                         ,p_parts_table (l_que_index).Special_instr
                         );

            DBMS_OUTPUT.put_line ('Success insert');
            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data :=
                     'Error in inserting into the table Xx_Cs_Tds_Parts '
                  || SQLERRM;
               log_exception
                         (p_object_id               => p_sr_number,
                          p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS',
                          p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                          p_error_msg               => l_msg_data
                         );
         END;

         l_que_index := p_parts_table.NEXT (l_que_index);
      END LOOP;

      BEGIN
         -- Get Incident info
         SELECT incident_id, object_version_number
           INTO l_incident_id, l_obj_ver_num
           FROM cs_incidents_all_b
          WHERE incident_number = p_sr_number;

         DBMS_OUTPUT.put_line ('incident info fetched');
         l_return_status := fnd_api.g_ret_sts_success;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_msg_data :=
                    'Error in finding the given incident number: ' || SQLERRM;
            l_return_status := fnd_api.g_ret_sts_error;
            log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE',
                   p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
      END;

      -- Get incident_status_id
      BEGIN
         SELECT incident_status_id, NAME
           INTO l_sr_status_id, l_sr_status
           FROM cs_incident_statuses
          WHERE incident_subtype = 'INC' AND NAME = 'Waiting for Approval';
                                     -- need to update to waiting for approval

         DBMS_OUTPUT.put_line (' Incident status_id - ' || l_sr_status_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_msg_data :=
                       'Error in finding the incident status ID: ' || SQLERRM;
            l_return_status := fnd_api.g_ret_sts_error;
            log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE',
                   p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
      END;

      
      IF (l_return_status = fnd_api.g_ret_sts_success)
      THEN
         DBMS_OUTPUT.put_line ('Calling Update API');
         -- Call standard API to update the Service Request Status.
         cs_servicerequest_pub.update_status
                                   (p_api_version                => 2.0,
                                    p_init_msg_list              => fnd_api.g_true,
                                    p_commit                     => fnd_api.g_false,
                                    x_return_status              => l_return_status,
                                    x_msg_count                  => l_msg_count,
                                    x_msg_data                   => l_msg_data,
                                    p_resp_appl_id               => g_resp_appl_id,
                                    p_resp_id                    => g_resp_id,
                                    p_user_id                    => g_user_id,
                                    p_login_id                   => NULL,
                                    p_request_id                 => l_incident_id,
                                    p_request_number             => NULL,
                                    p_object_version_number      => l_obj_ver_num,
                                    p_status_id                  => l_sr_status_id,
                                    p_status                     => l_sr_status,
                                    p_closed_date                => SYSDATE,
                                    p_audit_comments             => NULL,
                                    p_called_by_workflow         => NULL,
                                    p_workflow_process_id        => NULL,
                                    p_comments                   => NULL,
                                    p_public_comment_flag        => NULL,
                                    x_interaction_id             => l_interaction_id
                                   );
         x_return_status := l_return_status;
         x_return_message := l_msg_data;

         -- Check errors
         IF (l_return_status <> fnd_api.g_ret_sts_success)
         THEN
            IF (fnd_msg_pub.count_msg >= 1)
            THEN
               --Display all the error messages
               FOR i IN 1 .. fnd_msg_pub.count_msg
               LOOP
                  fnd_msg_pub.get (p_msg_index          => i,
                                   p_encoded            => 'F',
                                   p_data               => l_msg_data,
                                   p_msg_index_out      => l_msg_index_out
                                  );
                  DBMS_OUTPUT.put_line ('error - ' || l_msg_data);
                  
                  -- Err to BPEL
                  log_exception
                         (P_Object_Id               => P_Sr_Number,
                          P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS',
                          P_Error_Message_Code      => 'XX_CS_SR01_ERR_LOG',                          
                          P_Error_Msg               => L_Msg_Data
                         );
               END LOOP;
            ELSE
               --Only one error
               fnd_msg_pub.get (p_msg_index          => 1,
                                p_encoded            => 'F',
                                p_data               => l_msg_data,
                                p_msg_index_out      => l_msg_index_out
                               );
               DBMS_OUTPUT.put_line ('error - ' || l_msg_data);
               
               log_exception
                         (p_object_id               => p_sr_number,
                          P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS',
                          p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                          P_Error_Msg               => L_Msg_Data
                         );
                         
            END IF;

          --  l_msg_data := 'Error while updating service request ' || SQLERRM;
            
         Else
             l_msg_data := 'Success in updating service request ' || SQLERRM;
            COMMIT;
         END IF;
      ELSE
         x_return_status := l_return_status;
         x_return_message := l_msg_data;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_msg_data := 'Error in Add Parts procedure ' || SQLERRM;
         log_exception (p_object_id               => p_sr_number,
                        p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS',
                        p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                        p_error_msg               => l_msg_data
                       );
   END add_parts;

  -- +=============================================================================+
-- | PROCEDURE NAME : MAIN_PROC                                                  |
-- | DESCRIPTION    : Wrapper package for Item, Requisition and PO creation      |                   |
-- |                                                                             |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |                                                 |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE main_proc (
      p_sr_number        IN       VARCHAR2,
      x_return_status    IN OUT   VARCHAR2,
      x_return_message   IN OUT   VARCHAR2
   )
   IS
      l_cs_tds_parts_tbl   xx_cs_tds_parts_tbl_type;
      i                    NUMBER                   := 1;
      l_store_number       VARCHAR2 (240);
      l_return_status      VARCHAR2 (1)             := NULL;
      l_return_message     VARCHAR2 (2000)          := NULL;

      CURSOR c_sr_details (l_sr_number VARCHAR2)
      IS
         SELECT item_number, item_description, rms_sku, quantity,
                item_category, purchase_price, exchange_price, core_flag,
                uom, schedule_date, attribute1, attribute2, attribute3,
                attribute4, attribute5,Manufacturer,Model
                ,Serial_number,Problem_descr,Special_instr
           FROM xxom.xx_cs_tds_parts
          WHERE request_number = p_sr_number;

      c_sr_details_rec     c_sr_details%ROWTYPE;
   BEGIN
      i := 1;
      DBMS_OUTPUT.put_line ('Entering Main procedure');

      -- To get the store_number
      BEGIN
         SELECT attribute1                              --from Organization_Id
           INTO l_store_number
           FROM hr_all_organization_units
          WHERE organization_id =
                          (SELECT store_id
                             FROM xxom.xx_cs_tds_parts
                            WHERE request_number = p_sr_number AND ROWNUM = 1);

         -- l_store_number :=207;                        --comment later
         DBMS_OUTPUT.put_line ('Store Number - ' || l_store_number);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line (   'Store Number issue '
                                  || l_store_number
                                  || SQLERRM
                                 );
            x_return_message := 'Store Number not available ' || SQLERRM;
            log_exception
                         (p_object_id               => p_sr_number,
                          p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                          p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                          p_error_msg               => x_return_message
                         );
      END;

      OPEN c_sr_details (p_sr_number);

      LOOP
         DBMS_OUTPUT.put_line ('Entering Loop');

         -- Build the table
         FETCH c_sr_details
          INTO l_cs_tds_parts_tbl (i);

         EXIT WHEN c_sr_details%NOTFOUND;
         i := i + 1;
      END LOOP;

      CLOSE c_sr_details;

 -- To Display the records
      FOR i IN 1 .. l_cs_tds_parts_tbl.LAST
      LOOP
         DBMS_OUTPUT.put_line ('REQNO : ' || l_cs_tds_parts_tbl (i).rms_sku);
         DBMS_OUTPUT.put_line (   'itemno  : '
                               || l_cs_tds_parts_tbl (i).item_number
                              );
         DBMS_OUTPUT.put_line (   'itemdesc    : '
                               || l_cs_tds_parts_tbl (i).item_description
                              );
         DBMS_OUTPUT.put_line ('---------------------------');
      END LOOP;

      X_Return_Status := Fnd_Api.G_Ret_Sts_Success;
      x_return_message := 'Success';
     
      DBMS_OUTPUT.put_line ('status' || x_return_status);
      -- Calling 
      
      
     -- creation procedure
      DBMS_OUTPUT.put_line ('Call Create Items procedure');
      create_items (p_sr_number,
                    l_store_number,
                    l_cs_tds_parts_tbl,
                    l_return_status,
                    l_return_message
                   );
      

      IF (l_return_status = fnd_api.g_ret_sts_success)
      THEN
             create_parts_req (p_sr_number,
                               l_store_number,
                               l_cs_tds_parts_tbl,
                               l_return_status,
                               l_return_message
                              );
                 DBMS_OUTPUT.put_line ('Item parts successfully' || l_return_message);
        
                         IF (l_return_status = fnd_api.g_ret_sts_success)
                         Then
                            DBMS_OUTPUT.put_line ('Purchase req started');
                            Purchase_Req (L_Return_Status, L_Return_Message);
                            DBMS_OUTPUT.put_line ('Purchase req completed' || l_return_message);
                                                 
                
                                      IF (l_return_status = fnd_api.g_ret_sts_success)
                                      THEN
                                         -- Purchse_Order
                                         Purchse_Order (P_Sr_Number,
                                                       -- g_requirement_hdr_id,
                                                        l_cs_tds_parts_tbl,
                                                        l_return_status,
                                                        l_return_message
                                                       );
                          
                                                     IF (l_return_status = fnd_api.g_ret_sts_success)
                                                     THEN
                                                        DBMS_OUTPUT.put_line ('Purchase order created successfuly');
                                                     ELSE
                                                        x_return_message :=
                                                              'Error while creating Purchase Order '
                                                           || l_return_message
                                                           || SQLERRM;
                                                        log_exception
                                                               (p_object_id               => p_sr_number,
                                                                p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                                                                p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                                                                p_error_msg               => x_return_message
                                                               );
                                                     END IF;
                                      ELSE
                                         x_return_message :=
                                               'Error while creating Purchase Requisition '
                                            || l_return_message
                                            || SQLERRM;
                                         log_exception
                                                   (p_object_id               => p_sr_number,
                                                    p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                                                    p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                                                    p_error_msg               => x_return_message
                                                   );
                                      END IF;
                 ELSE
                    x_return_message :=
                          'Error while creating Parts Requirement '
                       || l_return_message
                       || SQLERRM;
                    log_exception
                                 (p_object_id               => p_sr_number,
                                  p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                                  p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                                  p_error_msg               => x_return_message
                                 );
                 END IF;
      Else
         x_return_message :=
                 'Error while creating Items ' || L_Return_Message || Sqlerrm;
          log_exception (p_object_id               => p_sr_number,
                        p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                        p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                        p_error_msg               => x_return_message
                       );
      END IF;
   Exception
      WHEN OTHERS
      Then
         x_return_message := 'Error in Main PROC ' || SQLERRM;
         log_exception (p_object_id               => p_sr_number,
                        p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                        p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                        p_error_msg               => x_return_message
                       );
   END main_proc;


  -- +=============================================================================+
-- | PROCEDURE NAME : CREATE_ITEMS                                                  |
-- | DESCRIPTION    : Internally calls the procedure XX_INV_ITEM_CREATION_PKG.CREATE_ITEM_PROCESS    |                  
-- |                  for creating the item, if does not exist                   |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |                                                 |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+



   PROCEDURE create_items (
      p_sr_number        IN       VARCHAR2,
      p_store_number     IN       VARCHAR2,
      p_parts_table      IN       xx_cs_tds_parts_tbl_type,
      x_return_status    IN OUT   VARCHAR2,
      x_return_message   IN OUT   VARCHAR2
   )
   AS
      l_index            NUMBER;
      l_item_id          NUMBER                                := 0;
      l_succ_msg         VARCHAR2 (4000)                       := NULL;
      l_store_num        hr_all_organization_units.NAME%TYPE;
      l_return_message   VARCHAR2 (4000)                       := NULL;
   BEGIN
      l_index := p_parts_table.FIRST;

      -- To find the name of the Orgnaization ID
      BEGIN
            SELECT NAME
              INTO l_store_num
              FROM hr_all_organization_units
             Where Attribute1 = P_Store_Number;
        Exception
        When Others Then
        X_Return_Message :=
                 'Error while getting the name of Organization ID ' || L_Return_Message || Sqlerrm;
          Log_Exception (P_Object_Id               => P_Sr_Number,
                        P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                        p_error_message_code      => 'XX_CS_SR03_ERR_LOG',
                        p_error_msg               => x_return_message
                       );
        END;

      WHILE l_index IS NOT NULL
      LOOP      
      BEGIN
            xx_inv_item_creation_pkg.create_item_process( l_item_id
                                                         ,l_succ_msg
                                                         ,p_parts_table(l_index).item_description
                                                         ,L_Store_Num
                                                         ,p_parts_table(l_index).uom
                                                         ,p_parts_table(l_index).purchase_price
                                                         ,p_parts_table(l_index).rms_sku
                                                         ,p_parts_table(l_index).item_number
                                                         ,p_parts_table(l_index).purchase_price
                                                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               x_return_message :=
                     'INSIDE EX: Error while  creating Items process:- '
                  || ' - '
                  || Sqlerrm;
              Log_Exception (P_Object_Id               => P_Sr_Number,
                    P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                    p_error_message_code      => 'XX_CS_SR03_ERR_LOG',
                    p_error_msg               => x_return_message
                   );
         END;

         -- l_que_index := p_parts_tbl.NEXT(l_que_index);
         l_index := p_parts_table.NEXT (l_index);
     
        -- g_item_id := l_item_id;

         IF l_item_id IS NULL
         Then
            x_return_status := fnd_api.g_ret_sts_error;               
            X_Return_Message :=
                     'ITEM not created! '
                  || ' - '
                  || Sqlerrm;
              Log_Exception (P_Object_Id      => P_Sr_Number,
                    P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC',
                    p_error_message_code      => 'XX_CS_SR03_ERR_LOG',
                    P_Error_Msg               => X_Return_Message
                   );
            
         ELSE
            x_return_status := fnd_api.g_ret_sts_success;            
            x_return_message := 'SUCCESS: created items ';  
           
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_message :=
               'MAIN EX: Error while  creating Items process:- '
            || ' - '
            || SQLERRM;
         x_return_status := fnd_api.g_ret_sts_error;                   
         log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_ITEMS',
                       p_error_message_code      => 'XX_CS_SR03_ERR_LOG',
                       p_error_msg               => l_succ_msg
                      );
   END create_items;

-- +=============================================================================+
-- | PROCEDURE NAME : CREATE_PARTS_REQ                                                  |
-- | DESCRIPTION    : Procedure to create Requirement header and detail records   |                  
-- |                                                                              |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |                                                 |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+


   PROCEDURE create_parts_req (
      p_sr_number       IN       VARCHAR2,
      p_store_number    IN       VARCHAR2,
      p_parts_tbl       IN       xx_cs_tds_parts_tbl_type,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   )
   AS
      l_return_status           VARCHAR2 (1)                          := NULL;
      l_msg_count               NUMBER                                   := 0;
      l_msg_data                VARCHAR2 (4000)                       := NULL;
      l_header_rec              csp_parts_requirement.header_rec_type;
      l_line_rec                csp_parts_requirement.line_rec_type;
      L_Line_Tbl                Csp_Parts_Requirement.Line_Tbl_Type;
      L_Rqh_Rec                 csp_Requirement_Headers_Pub.Rqh_Rec_Type;
      L_Rql_Rec                 csp_Requirement_Lines_Pub.Rql_Rec_Type;
      L_Rql_Tbl                 csp_Requirement_Lines_Pub.Rql_Tbl_Type;
      X_Rql_Tbl                 csp_Requirement_Lines_Pub.Rql_Tbl_Type;
      v_open_requirement        VARCHAR2 (240)           := NULL;
      l_resource_id             NUMBER                   := 0;
      l_resource_type           VARCHAR2 (30)            := NULL;
      l_destination_org_id      NUMBER                   := 0;
      l_dest_sub_inv            VARCHAR2 (30)            := NULL;
      l_task_id                 NUMBER                   := 0;
      l_task_assignment_id      NUMBER                   := 0;
      l_inventory_item_id       NUMBER                   := 0;
      l_parts_tbl               xx_cs_tds_parts_pkg.xx_cs_tds_parts_tbl_type;
      l_revision                VARCHAR2 (10);
      l_ship_to_loc_id          NUMBER                   := 0;
      l_incident_att11          VARCHAR2 (30)            := NULL;
      l_msg_index_out           VARCHAR2 (240)           := NULL;
      l_schedule_date           DATE                     := NULL;
      l_order_flag              VARCHAR2 (1)             := '';
      L_Organization_Id         NUMBER                   := 0;
      I                         NUMBER                   := 0;     
      L_Resp_Id                 Constant Pls_Integer     := 50501; -- Fnd_Global.Resp_Id;                                                       
      l_resp_appl_id            CONSTANT PLS_INTEGER     := 201;   --Fnd_Global.Resp_Appl_Id;                                                    
      L_User_Id                 VARCHAR2 (20)            := 1197067; 
      l_org_id                  NUMBER                   := 404;

-- Define cursor for Organization_id and Subinventory_code
      CURSOR c_default_org (v_resource_id NUMBER)
      IS
         SELECT organization_id, subinventory_code
           FROM csp_inv_loc_assignments
          WHERE resource_id = v_resource_id
            AND default_code = 'IN'
            AND SYSDATE BETWEEN NVL (effective_date_start, SYSDATE)
                            And Nvl (Effective_Date_End, Sysdate);
    
    r_default_org             c_default_org%ROWTYPE;
     
   BEGIN
      l_parts_tbl := p_parts_tbl;
      
      -- To initialize env
      fnd_global.apps_initialize (l_user_id,
                                  l_resp_id,
                                  l_resp_appl_id,
                                  l_org_id
                                 );

      -- Select Task Id , resource_id and assignment_id
      BEGIN
         SELECT jtl.task_id, jta.task_assignment_id, jta.resource_id,
                jta.resource_type_code
           INTO l_task_id, l_task_assignment_id, l_resource_id,
                l_resource_type
           FROM apps.jtf_tasks_vl jtl, apps.jtf_task_assignments jta
          WHERE jta.task_id = jtl.task_id
            AND jtl.source_object_type_code = 'SR'
            And Jtl.Source_Object_Id = (Select Incident_Id
                                          FROM apps.cs_incidents_all_b
                                         Where Incident_Number = P_Sr_Number)
             --AND     jtl.task_name LIKE '%TDS Diagnosis and Repair%'     -- Bala to uncomment
              ;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data :=
                  'Error while fetching the task id and task assignment id :- '
               || ' - '
               || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
           
            log_exception
                  (P_Object_Id               => P_Sr_Number,
                   P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
      END;

      -- Fetching the Schedule Date
      BEGIN
         SELECT schedule_date
           INTO l_schedule_date
           FROM xxom.xx_cs_tds_parts
          WHERE request_number = p_sr_number
            AND item_number = l_parts_tbl (1).item_number
            AND ROWNUM <= 1                       -- Bala need touncomment this
            ;
     EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data :=
               'Error while fetching the schedule_date :- ' || ' - '
               || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception
                 (p_object_id               => p_sr_number,
                  P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                  p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                  p_error_msg               => x_msg_data
                 );
          
      END;

      l_header_rec.resource_id   := l_resource_id;     -- Commented By Bala For Adding Raj's Logic
      l_header_rec.resource_type := l_resource_type;   -- Commented By Bala For Adding Raj's Logic
      
      l_rqh_rec.resource_id   := l_resource_id;   -- Added By Bala For Raj's Logic
      l_rqh_rec.resource_type := l_resource_type; ---- Added By Bala For Raj's Logic
          
      DBMS_OUTPUT.put_line ('l_resource_id :- ' || l_resource_id);
      DBMS_OUTPUT.put_line ('Resource_type :- ' || l_header_rec.resource_type);

      -- Adding the resource default sub inventory
      BEGIN
         OPEN c_default_org (l_resource_id);
         FETCH c_default_org
         INTO r_default_org;
         DBMS_OUTPUT.put_line (c_default_org%ROWCOUNT);
         CLOSE c_default_org;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data :=
                  'Error while fetching the cursor c_default_org :- '
               || ' - '
               || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );            
      END;

      BEGIN
         -- Determine Ship To location Id
         SELECT hrl.ship_to_location_id
           INTO l_ship_to_loc_id
           FROM csp_rs_cust_relations rcr,
                hz_cust_acct_sites cas,
                hz_cust_site_uses csu,
                po_location_associations pla,
                hr_locations_v hrl
          WHERE 1 = 1
            AND rcr.resource_id = l_resource_id
            AND rcr.customer_id = cas.cust_account_id
            AND cas.cust_acct_site_id = csu.cust_acct_site_id(+)
            AND csu.site_use_code = 'SHIP_TO'
            AND csu.site_use_id = pla.site_use_id
            AND pla.location_id = hrl.location_id;     
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data :=
                  'Error while fetching the Ship To location Id :- '
               || ' - '
               || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception
                  (P_Object_Id               => P_Sr_Number,
                   P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
        END;

      l_destination_org_id := r_default_org.organization_id;
      l_dest_sub_inv := r_default_org.subinventory_code;
      x_return_status := 'S';
      --Start Commented By Bala For Adding Raj's Logic
      
      l_header_rec.order_type_id := NULL;
      l_header_rec.ship_to_location_id := l_ship_to_loc_id;
      l_header_rec.dest_organization_id := l_destination_org_id;
      l_header_rec.operation := 'CREATE';
      l_header_rec.need_by_date := l_schedule_date;
      l_header_rec.task_id := l_task_id;
      l_header_rec.task_assignment_id := l_task_assignment_id;
      l_header_rec.dest_subinventory := l_dest_sub_inv;
      
      --End Commented By Bala For Adding Raj's Logic
      
      -- Start Added By Bala For Raj's Logic
      l_rqh_rec.open_requirement  := v_open_requirement ;
      l_rqh_rec.order_type_id := NULL;
      l_rqh_rec.ship_to_location_id := l_ship_to_loc_id;
      l_rqh_rec.destination_organization_id := l_destination_org_id;
      --l_rqh_rec.operation := 'CREATE';
      l_rqh_rec.need_by_date := l_schedule_date;
      l_rqh_rec.task_id := l_task_id;
      l_rqh_rec.task_assignment_id := l_task_assignment_id;
      l_rqh_rec.destination_subinventory := l_dest_sub_inv;
      -- End Added By Bala For Raj's Logic

      DBMS_OUTPUT.put_line (   'l_rqh_rec.order_type_id :- '
                            || l_rqh_rec.order_type_id
                           );
      DBMS_OUTPUT.put_line (   'l_rqh_rec.ship_to_location_id :- '
                            || l_rqh_rec.ship_to_location_id
                           );
      DBMS_OUTPUT.put_line (   'l_rqh_rec.dest_organization_id :- '
                            || l_rqh_rec.destination_organization_id
                           );
       DBMS_OUTPUT.put_line (   'v.need_by_date :- '
                            || l_rqh_rec.need_by_date
                           );
      DBMS_OUTPUT.put_line ('l_rqh_rec.task_id :- ' || l_rqh_rec.task_id);
      DBMS_OUTPUT.put_line (   'l_rqh_rec.task_assignment_id:- '
                            || l_rqh_rec.task_assignment_id
                           );
      DBMS_OUTPUT.put_line (   'l_rqh_rec.dest_subinventory :- '
                            || l_rqh_rec.destination_subinventory
                           );

      BEGIN
         SELECT organization_id
           INTO l_organization_id
           FROM hr_all_organization_units
          WHERE attribute1 = p_store_number;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data :=
                  'Error while fetching the Organization id :- '
               || ' - '
               || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception
                  (P_Object_Id               => P_Sr_Number,
                   P_Error_Location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
            
      END;      
      -- Start Added By Bala For Raj's Logic
      CSP_REQUIREMENT_HEADERS_PUB.Create_requirement_headers
                                                (
                                                  p_api_version_number      => 1.0
                                                 ,p_init_msg_list           => fnd_api.g_false
                                                 ,p_commit                  => fnd_api.g_false
                                                 ,p_rqh_rec                 => l_rqh_rec  
                                                 ,x_requirement_header_id   => g_requirement_hdr_id 
                                                 ,x_return_status           => l_return_status
                                                 ,x_msg_count               => l_msg_count
                                                 ,x_msg_data                => l_msg_data
                                                );
                                                
        COMMIT;
       IF (l_return_status <> fnd_api.g_ret_sts_success)
       THEN
         DBMS_OUTPUT.put_line ('First IF condition');
         DBMS_OUTPUT.put_line ('l_return_status :- ' || l_return_status);

         IF (fnd_msg_pub.count_msg > 1)
         THEN           
            --Display all the error messages
            FOR j IN 1 .. fnd_msg_pub.count_msg
            LOOP
               fnd_msg_pub.get (p_msg_index          => j,
                                p_encoded            => 'F',
                                p_data               => l_msg_data,
                                p_msg_index_out      => l_msg_index_out
                               );               
               DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
               DBMS_OUTPUT.put_line ('l_msg_index_out :- ' || l_msg_index_out);
               log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR06_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
            END LOOP;
         ELSE
            fnd_msg_pub.get (p_msg_index          => 1,
                             p_encoded            => 'F',
                             p_data               => l_msg_data,
                             p_msg_index_out      => l_msg_index_out
                            );
            DBMS_OUTPUT.put_line ('Else Part');
            DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
            DBMS_OUTPUT.put_line ('l_msg_index_out :- ' || l_msg_index_out);
            DBMS_OUTPUT.put_line ('l_msg_count :- ' || l_msg_count);
            DBMS_OUTPUT.put_line (   'IF msG =1 l_return_status :- '
                                  || l_return_status
                                 );
            log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR06_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
         END IF;
      ELSE
         DBMS_OUTPUT.PUT_LINE('CSP_REQUIREMENT_HEADERS_PUB.Create_requirement_headers IS Successes');
         DBMS_OUTPUT.PUT_LINE('l_return_status :- '||l_return_status);
         DBMS_OUTPUT.PUT_LINE('g_requirement_hdr_id is :-'||g_requirement_hdr_id);
      END IF;         
      -- End Added By Bala For Raj's Logic
      
      l_rql_tbl.delete;

      FOR i IN l_parts_tbl.FIRST .. l_parts_tbl.LAST
      LOOP
         DBMS_OUTPUT.put_line ('l_parts_tbl.FIRST :- ' || l_parts_tbl.FIRST);
         DBMS_OUTPUT.put_line ('l_parts_tbl.LAST :- ' || l_parts_tbl.LAST);
         DBMS_OUTPUT.put_line ('Entered Into First Loop');
         -- Dtermine revision no for item        
         BEGIN          
            SELECT b.inventory_item_id
              INTO l_inventory_item_id
              FROM (SELECT *
                      FROM mtl_system_items_b
                     WHERE organization_id = l_organization_id) b
             WHERE b.attribute2 = l_parts_tbl (i).item_number;          --'A2'

            SELECT revision
              INTO l_revision
              FROM mtl_item_revisions
             WHERE inventory_item_id = l_inventory_item_id
               AND organization_id = l_organization_id
               ;
            DBMS_OUTPUT.put_line (   'l_inventory_item_id :- '
                                  || l_inventory_item_id
                                 );
            DBMS_OUTPUT.put_line ('l_revision :- ' || l_revision);
         EXCEPTION
            WHEN OTHERS
            THEN
               x_msg_data :=
                     'Error while fetching the inventory item id and revision :- '
                  || ' - '
                  || SQLERRM;
               x_return_status := fnd_api.g_ret_sts_error;
               log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
               DBMS_OUTPUT.put_line ('Exception - 7 :- ' || SQLERRM);
         END;         
         -- Start Commented By Bala For Adding Raj's Logic         
        
         L_Line_Tbl (I).Inventory_Item_Id := L_Inventory_Item_Id;
         l_line_tbl (i).revision := l_revision;
         l_line_tbl (i).unit_of_measure := l_parts_tbl (i).uom;
         l_line_tbl (i).quantity := l_parts_tbl (i).quantity;
         l_line_tbl (i).ordered_quantity := l_parts_tbl (i).quantity;
         l_line_tbl (i).line_num := i;
        
         -- End Commented By Bala For Adding Raj's Logic
         --l_line_tbl(i)                    := l_line_rec;
                  
         -- Start Added By Bala For Raj's Logic
         
         l_rql_tbl(i).requirement_header_id   := g_requirement_hdr_id ; --g_header_id;
         l_rql_tbl(i).inventory_item_id       := l_inventory_item_id;
         l_rql_tbl(i).revision                := l_revision;
         l_rql_tbl(i).uom_code                := l_parts_tbl(i).uom;
         l_rql_tbl(i).ordered_quantity        := l_parts_tbl(i).quantity;
         l_rql_tbl(i).required_quantity       := l_parts_tbl(i).quantity;
         l_rql_tbl(i).source_organization_id  := l_destination_org_id ;
         l_rql_tbl(i).source_subinventory     := l_dest_sub_inv;
         l_rql_tbl(i).order_by_date           := SYSDATE;
         l_rql_tbl(i).arrival_date            := l_schedule_date;         
         
         -- End Added By Bala For Raj's Logic
         
         DBMS_OUTPUT.put_line (   'l_rql_tbl(i).inventory_item_id :- '
                               || l_rql_tbl (i).inventory_item_id
                              );
         DBMS_OUTPUT.put_line (   'l_rql_tbl(i).revision :- '
                               || l_rql_tbl (i).revision
                              );
         DBMS_OUTPUT.put_line (   'l_rql_tbl(i).unit_of_measure :- '
                               || l_rql_tbl (i).uom_code
                              );
         DBMS_OUTPUT.put_line (   'l_rql_tbl(i).quantity :- '
                               || l_rql_tbl (i).ordered_quantity
                              );
        
         DBMS_OUTPUT.put_line (   'l_rql_tbl(i).l_destination_org_id :- '
                               || l_rql_tbl (i).source_organization_id
                              );                              
      
      END LOOP;

      l_order_flag := 'N';
      --Call the standard API
      l_return_status := '';
      l_msg_data := '';
      DBMS_OUTPUT.put_line (   'Before Calling API l_return_status :- '
                            || l_return_status
                           );
      Dbms_Output.Put_Line ('Calling req lines API');
    --    Dbms_Output.Put_Line ('req line id:' || L_Rql_Tbl(1).Requirement_Line_Id);
      Dbms_Output.Put_Line ('req header id:' || L_Rql_Tbl(L_Rql_Tbl.First).Requirement_Header_Id);
      Dbms_Output.Put_Line ('req header id:' || L_Rql_Tbl(L_Rql_Tbl.first).inventory_item_Id);
      
      -- Start Commented By Bala For Adding Raj's Logic
      /*csp_parts_requirement.process_requirement
                            (p_api_version            => 1.0,
                             p_init_msg_list          => fnd_api.g_false,
                             p_commit                 => fnd_api.g_false,
                             px_header_rec            => l_header_rec
                                                           --L_Header_rec_type
                                                                     ,
                             px_line_table            => l_line_tbl
                                                             --L_Line_Tbl_type
                                                                   ,
                             p_create_order_flag      => l_order_flag,
                             x_return_status          => l_return_status,
                             x_msg_count              => l_msg_count,
                             x_msg_data               => l_msg_data
                            );
           */ 
          -- End Commented By Bala For Adding Raj's Logic
          
          -- Start Added By Bala For Raj's Logic
          
          csp_requirement_lines_pub.create_requirement_lines
                                    (
                                      p_api_version_number     => 1.0
                                     ,p_init_msg_list          => fnd_api.g_false
                                     ,p_commit                 => fnd_api.g_false
                                     ,P_Rql_Tbl                => L_Rql_Tbl
                                     ,x_requirement_line_tbl   => x_rql_tbl
                                     ,x_return_status          => l_return_status
                                     ,x_msg_count              => l_msg_count
                                     ,x_msg_data               => l_msg_data
                                   );  
                                   
        COMMIT;
          -- End Added By Bala For Raj's Logic
      Dbms_Output.Put_Line ('After lines API l_return_status :- ' || L_Return_Status);
      Dbms_Output.Put_Line ('After lines API l_msg_data :- ' || L_Msg_Data || L_Msg_Count);
      Dbms_Output.Put_Line ('req line id from x:' || To_Char(X_Rql_Tbl(X_Rql_Tbl.First).Requirement_Line_Id));
      Dbms_Output.Put_Line ('req line id: from l' || to_char(l_Rql_Tbl(l_Rql_Tbl.First).Requirement_Line_Id));
      Dbms_Output.Put_Line ('req header id:' || X_Rql_Tbl(X_Rql_Tbl.First).Requirement_Header_Id);
      Dbms_Output.Put_Line ('req item :' || x_rql_tbl(x_rql_tbl.first).inventory_item_Id);

      IF (l_return_status <> fnd_api.g_ret_sts_success)
      THEN         
         DBMS_OUTPUT.put_line ('l_return_status :- ' || l_return_status);

         IF (fnd_msg_pub.count_msg > 1)
         THEN
            DBMS_OUTPUT.put_line ('Second IF condition');
            DBMS_OUTPUT.put_line (   'FND_MSG_PUB.Count_Msg  :- '
                                  || fnd_msg_pub.count_msg
                                 );
            DBMS_OUTPUT.put_line (   'IF msG >1 x_return_status :- '
                                  || l_return_status
                                 );

            --Display all the error messages
            FOR j IN 1 .. fnd_msg_pub.count_msg
            LOOP
               fnd_msg_pub.get (p_msg_index          => j,
                                p_encoded            => 'F',
                                p_data               => l_msg_data,
                                p_msg_index_out      => l_msg_index_out
                               );
               DBMS_OUTPUT.put_line ('Second Loop');
               DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
               DBMS_OUTPUT.put_line ('l_msg_index_out :- ' || l_msg_index_out);
               log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
            END LOOP;
         ELSE
            fnd_msg_pub.get (p_msg_index          => 1,
                             p_encoded            => 'F',
                             p_data               => l_msg_data,
                             p_msg_index_out      => l_msg_index_out
                            );
            DBMS_OUTPUT.put_line ('Else Part');
            DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
            DBMS_OUTPUT.put_line ('l_msg_index_out :- ' || l_msg_index_out);
            DBMS_OUTPUT.put_line ('l_msg_count :- ' || l_msg_count);
            DBMS_OUTPUT.put_line (   'IF msG =1 l_return_status :- '
                                  || l_return_status
                                 );
            log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
         END IF;
      ELSE
    -- Callinf PROCESS_REQ Procedure  
      --Process_Req(P_Sr_Number,L_Header_Rec,L_Line_Tbl,X_Return_Status,X_Msg_Data); -- Commented By Bala For Adding Raj's Logic          
        Process_Req(P_Sr_Number,l_rqh_rec,x_rql_tbl,L_Header_Rec,L_Line_Tbl,X_Return_Status,X_Msg_Data); -- Added By Bala For Raj's Logic                 
         
         DBMS_OUTPUT.put_line ('l_return_status :- ' || l_return_status);
         DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
         DBMS_OUTPUT.put_line (   'FND_MSG_PUB.Count_Msg :- '
                               || fnd_msg_pub.count_msg
                              );
      END IF;

        x_return_status := l_return_status;
        x_msg_data      := l_msg_data;
   END create_parts_req;

   
 -- +=============================================================================+
-- | PROCEDURE NAME : PROCESS_REQ                                                  |
-- | DESCRIPTION    : Procedure to create requisition details in the interface     |                  
-- |                  table                                                       |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |                                                 |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+

PROCEDURE process_req ( p_sr_number       IN   VARCHAR2
                          ,p_req_header_rec  IN   csp_requirement_headers_pub.Rqh_rec_type
                          ,p_req_line_tbl    IN   csp_requirement_lines_pub.rql_tbl_type
                          ,p_header_rec      IN   csp_parts_requirement.header_rec_type
                          ,p_line_tbl        IN   csp_parts_requirement.line_tbl_type      
                          ,x_return_status   OUT  VARCHAR2
                          ,x_msg_data        OUT  VARCHAR2
                         )
   AS
      l_return_status      VARCHAR2 (1)     := NULL;
      l_msg_count          NUMBER           := 0;
      l_msg_data           VARCHAR2 (4000)  := NULL;
      l_msg_index_out      VARCHAR2 (2000)  := NULL;
      i                    NUMBER;
       
       l_rqh_rec           csp_requirement_headers_pub.rqh_rec_type;
       l_rql_tbl           csp_requirement_lines_pub.rql_tbl_type;
       l_header_rec        csp_parts_requirement.header_rec_type;
       l_po_Line_tbl       csp_parts_requirement.line_tbl_type; 
       l_line_rec          csp_parts_requirement.Line_rec_type;      
       
       l_resp_id           CONSTANT PLS_INTEGER     := 50501;   -- Fnd_Global.Resp_Id;
       l_resp_appl_id      CONSTANT PLS_INTEGER     := 201;     -- Fnd_Global.Resp_Appl_Id;
       l_user_id           VARCHAR2 (20)            :=1197067;  -- := 1200246;
       L_Org_Id            NUMBER                   := 404;
       L_Req_Line_Dtl_Id   NUMBER;
       L_Login_Id          NUMBER                   := L_User_Id;
       L_Req_Line_Id      Csp_Requirement_Lines.Requirement_Line_Id%Type;
       
       L_Accrual_Account Varchar2(200) :=Null;
       L_Accrual_Account_id number :=0;
       l_charge_acc              Varchar2 (200)     := Null;
      L_Charge_Acc_Id           Number             := 0;
      err varchar2(100);
             
   BEGIN
      l_header_rec  := p_header_rec;
      L_Po_Line_Tbl := P_Line_Tbl;
      L_Rqh_Rec     := P_Req_Header_Rec;
      L_Rql_Tbl     := P_req_Line_Tbl;
      fnd_global.apps_initialize (l_user_id,
                                  l_resp_id,
                                  l_resp_appl_id,
                                  l_org_id
                                 );
      csp_parts_order.process_purchase_req
                         (p_api_version        => 1.0,              --l_api_version_number
                          p_init_msg_list      => fnd_api.g_false,  --p_init_msg_list                                     
                          p_commit             => fnd_api.g_false,  --p_commit                                                                 ,
                          px_header_rec        => l_header_rec,
                          px_line_table        => l_po_line_tbl,
                          x_return_status      => l_return_status,
                          x_msg_count          => l_msg_count,
                          x_msg_data           => l_msg_data
                         );

      IF (l_return_status <> fnd_api.g_ret_sts_success)
      THEN         
         DBMS_OUTPUT.put_line (   'PROCESS_REQ l_return_status :- '
                               || l_return_status
                              );
         DBMS_OUTPUT.put_line ('PROCESS_REQ l_return_message :- '
                               || l_msg_data
                              );

         IF (fnd_msg_pub.count_msg > 1)
         THEN           
            --Display all the error messages
            FOR j IN 1 .. fnd_msg_pub.count_msg
            LOOP
               fnd_msg_pub.get (p_msg_index          => j,
                                p_encoded            => 'F',
                                p_data               => l_msg_data,
                                p_msg_index_out      => l_msg_index_out
                               );            
               DBMS_OUTPUT.put_line ('PROCESS_REQ l_msg_data :- '
                                     || l_msg_data
                                    );
               DBMS_OUTPUT.put_line (   'PROCESS_REQ l_msg_index_out :- '
                                     || l_msg_index_out
                                    );
               log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR05_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
            END LOOP;
         ELSE
             
             fnd_msg_pub.get (p_msg_index            => 1,
                                p_encoded            => 'F',
                                p_data               => l_msg_data,
                                p_msg_index_out      => l_msg_index_out
                               );
            
               DBMS_OUTPUT.put_line ('PROCESS_REQ l_msg_data :- '
                                     || l_msg_data
                                    );
               DBMS_OUTPUT.put_line (   'PROCESS_REQ l_msg_index_out :- '
                                     || l_msg_index_out
                                    );
               log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR05_ERR_LOG',
                   P_Error_Msg               => L_Msg_Data
                  );
                  END IF;
                  
            ELSE             
             
             DBMS_OUTPUT.put_line ('PROCESS_REQ Success');
             Dbms_Output.Put_Line ('req header id: ' || L_Header_Rec.Requisition_Header_Id);
             G_Req_Header_Id :=L_Header_Rec.Requisition_Header_Id;
             Dbms_Output.Put_Line ('req header id: ' || G_Req_Header_Id);
             
             -- Update the SR number into req table
           /*  BEGIN
               UPDATE  Po_Requisitions_Interface_All 
                  SET  Header_Attribute14    = P_Sr_Number
                WHERE  requisition_header_id = L_Header_Rec.Requisition_Header_Id
                ;             
             EXCEPTION
               WHEN OTHERS THEN
                 l_msg_data := 'Error while updating Po_Requisitions_Interface_All table';
                log_exception
                  (p_object_id               => p_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ',
                   p_error_message_code      => 'XX_CS_SR05_ERR_LOG',
                   P_Error_Msg               => l_msg_data
                  );
               DBMS_OUTPUT.put_line ('error in updating SR number');
              END;             
             COMMIT; */
             
        -- Raj added
          -- insert into csp_req_line_Details table with purchase req information
           For I In L_Rql_Tbl.First..L_Rql_Tbl.Last Loop
            
                
                     Dbms_Output.Put_Line ('req line id :' ||L_Rql_Tbl(I).Requirement_Header_Id);
                     Dbms_Output.Put_Line ('req line id :' || l_po_line_tbl(i).inventory_item_id);
                     

                        SELECT csp_req_line_Details_s1.nextval
                          INTO l_req_line_Dtl_id
                          From Dual;
                     Dbms_Output.Put_Line ('Calling line details API');
                     
                                       Select Requirement_Line_Id 
                                       Into L_Req_Line_Id
                                       From Csp_Requirement_Lines
                     Where Requirement_Header_Id=L_Rql_Tbl(I).Requirement_Header_Id
                     and inventory_item_id=l_po_line_tbl(i).inventory_item_id;
                     
                     Dbms_Output.Put_Line ('req line id :' ||L_Rql_Tbl(I).Requirement_Header_Id);
                     Dbms_Output.Put_Line ('req line id :' || L_Rql_Tbl(I).inventory_item_id);
                     
                          csp_req_line_Details_pkg.Insert_Row(
                            Px_Req_Line_Detail_Id   =>  L_Req_Line_Dtl_Id,
                            p_REQUIREMENT_LINE_ID   =>  L_Req_Line_Id,
                            p_CREATED_BY            =>  nvl(l_user_id, 1),
                            p_CREATION_DATE         =>  sysdate,
                            p_LAST_UPDATED_BY       =>  nvl(l_user_id, 1),
                            p_LAST_UPDATE_DATE      =>  sysdate,
                            P_Last_Update_Login     =>  Nvl(L_Login_Id, -1),
                            P_Source_Type           =>  'POREQ',
                            P_Source_Id             =>  l_po_line_tbl(i).Requisition_Line_Id);
                          
                            
          END LOOP; 
        ------           
           END IF;
     
     -- Fetching Buyer ID
     BEGIN 
       SELECT agent_id
        INTO  g_buyer_id
       From   Po_Agents_V 
       WHERE  agent_name = 'Agarwal, Gaurav' ;  --'Merchandize, Buyer'   commented for testing       
    EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data      := 'Error In Fetching Buyer ID:- ' || SQLERRM;
         x_return_status := fnd_api.g_ret_sts_error;
         DBMS_OUTPUT.put_line ('PROCESS_REQ Buyer Exception-1 :- ' || SQLERRM);
         log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.PROCESS_REQ',
                       p_error_message_code      => 'XX_CS_SR012_ERR_LOG',
                       p_error_msg               => x_msg_data
                      );
   END;
   
   -- To find the charge account
   
    /*Select Fnd_Profile.Value ('XX_TDS_PARTS_AP_LIABILITY_ACCT') 
    Into G_Charge_account
    from dual;*/
   
   -- Updating Po Requisition Interface table
   BEGIN
    SELECT    segment1
                   || '.'
                   || segment2
                   || '.'
                   || fnd_profile.VALUE ('XX_TDS_PARTS_AP_LIABILITY_ACCT')
                   || '.'
                   || segment4
                   || '.'
                   || segment5
                   || '.'
                   || segment6
                   || '.'
                   || Segment7
              INTO l_accrual_account
              FROM gl_code_combinations
             WHERE code_combination_id =
                      (SELECT material_account
                         From Mtl_Parameters
                        Where Organization_Id =
                                    l_header_rec.dest_organization_id
                      );
                      
                      
                      
                      
 EXCEPTION
            WHEN OTHERS
            THEN
                X_Return_Status  :=  Fnd_Api.G_Ret_Sts_Error;
                x_msg_data := 'Error While fetching the accrual_account code combination'; 
                log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_msg_data
                      );
               DBMS_OUTPUT.put_line (' accrual_account not found');
         END;

         DBMS_OUTPUT.put_line ('accrual_account -' || l_charge_acc);
         BEGIN
        g_accrual_account_id :=
            fnd_flex_ext.get_ccid
                             ('SQLGL',
                              'GL#',
                              50310,
                              TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS')
                                                               --OD_GLOBAL_COA
                                                                        ,
                              l_accrual_account
                             );
           DBMS_OUTPUT.put_line ('accrual_account' || l_charge_acc_id);
           err := fnd_flex_ext.GET_MESSAGE;
           DBMS_OUTPUT.put_line (err);
          EXCEPTION
            WHEN OTHERS THEN
               x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
               x_msg_data := 'Error While getting the  accrual_account from fnd_flex_ext.get_ccid'; 
               log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_msg_data
                      );
          END;
         
                         
   
   
    BEGIN
            SELECT    segment1
                   || '.'
                   || segment2
                   || '.'
                   || fnd_profile.VALUE ('XX_TDS_PARTS_MAT_ACCOUNT')
                   || '.'
                   || segment4
                   || '.'
                   || segment5
                   || '.'
                   || segment6
                   || '.'
                   || segment7
              INTO l_charge_acc
              FROM gl_code_combinations
             WHERE code_combination_id =
                      (SELECT material_account
                         FROM mtl_parameters
                        Where Organization_Id =
                                    l_header_rec.dest_organization_id
                      );
         EXCEPTION
            WHEN OTHERS
            THEN
                x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
                x_msg_data := 'Error While fetching the charge account code combination'; 
                log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_msg_data
                      );
               DBMS_OUTPUT.put_line (' Charge acc not found');
         END;

         DBMS_OUTPUT.put_line ('Charge Acc -' || l_charge_acc);
         BEGIN
         g_charge_acc_id :=
            fnd_flex_ext.get_ccid
                             ('SQLGL',
                              'GL#',
                              50310,
                              TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS')
                                                               --OD_GLOBAL_COA
                                                                        ,
                              l_charge_acc
                             );
           DBMS_OUTPUT.put_line ('charge_acc' || l_charge_acc_id);
           err := fnd_flex_ext.GET_MESSAGE;
           DBMS_OUTPUT.put_line (err);
          EXCEPTION
            WHEN OTHERS THEN
               x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
               x_msg_data := 'Error While getting the charge account from fnd_flex_ext.get_ccid'; 
               log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_msg_data
                      );
          END;
         
   
   
   BEGIN
     IF g_req_header_id IS NOT NULL THEN
   
       Update Po_Requisitions_Interface_All
       SET    PREPARER_ID   =  g_buyer_id 
             ,Deliver_To_Requestor_Id = G_Buyer_Id
             , Header_Attribute14    = P_Sr_Number
             ,Charge_Account_Id =g_charge_acc_id
            ,accrual_account_id =g_accrual_account_id
        WHERE REQUISITION_HEADER_ID = g_req_header_id
        ;
        x_msg_data := 'Prepared id and deliver to requester_id is  generated :- ' || SQLERRM;
        x_return_status := fnd_api.g_ret_sts_success;
     ELSE
       x_msg_data := 'Prepared id and deliver to requester_id not generated :- ' || SQLERRM;
       x_return_status := fnd_api.g_ret_sts_error;
     END IF;
   EXCEPTION
     WHEN OTHERS THEN
       x_msg_data      := 'Error While updating the PO_REQUISITIONS_INTERFACE_ALL table:- ' || SQLERRM;
       x_return_status := fnd_api.g_ret_sts_error;
         DBMS_OUTPUT.put_line ('Error While updating the PO_REQUISITIONS_INTERFACE_ALL table :- ' || SQLERRM);
         log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.PROCESS_REQ',
                       p_error_message_code      => 'XX_CS_SR05_ERR_LOG',
                       p_error_msg               => x_msg_data
                      );
   END;
   
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data :=
                    'Error In PROCESS_REQ Procedure Main Block:- ' || SQLERRM;
         x_return_status := fnd_api.g_ret_sts_error;
         DBMS_OUTPUT.put_line ('PROCESS_REQ Exception-1 :- ' || SQLERRM);
           log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.PROCESS_REQ',
                       p_error_message_code      => 'XX_CS_SR05_ERR_LOG',
                       p_error_msg               => x_msg_data
                      );
   END;



 -- +=============================================================================+
-- | PROCEDURE NAME : PURCHASE_REQ                                                 |
-- | DESCRIPTION    : Procedure to create requisition through REQIMPORT           |                  
-- |                                                                             |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |                                                 |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE purchase_req ( x_return_status    IN OUT   VARCHAR2
                           ,x_return_message   IN OUT   VARCHAR2
                          )
   IS
      l_reqimport_request_id   NUMBER;
      l_resp_id                CONSTANT PLS_INTEGER    := 50501;     -- Fnd_Global.Resp_Id;
      l_resp_appl_id           CONSTANT PLS_INTEGER    := 201;       --Fnd_Global.Resp_Appl_Id;
      l_user_id                VARCHAR2 (20)           := 1197067 ;  --1200246;
      -- G_User_Name    Constant Varchar2 (20) := '598133' ; --'CS_ADMIN';
      l_org_id                  NUMBER                 := 404;       -- need to set
      L_Phase                   VARCHAR2(100)          := NULL;
      L_Status                  VARCHAR2(100)          := NULL;
      L_Dev_Phase               VARCHAR2(100)          := NULL;
      L_Dev_Status              VARCHAR2(100)          := NULL;
      L_Message                 VARCHAR2(100)          := NULL;
      L_Count                   NUMBER                 := 0;
      L_Req_Status              BOOLEAN;
      Lc_Error_Msg              VARCHAR2(4000)         := NULL;            
                
      CURSOR C_Err_Msg(l_request NUMBER)
      IS
        SELECT error_message 
        FROM   po_interface_errors 
        WHERE  request_id =l_request
        ;              
   BEGIN
      l_reqimport_request_id := 0;
      -- Initializing the environment
      fnd_global.apps_initialize (l_user_id,
                                  l_resp_id,
                                  l_resp_appl_id,
                                  l_org_id
                                 );
      -- Submit the REQIMPORT
      DBMS_OUTPUT.put_line ('REQIMPORT - started');    
    BEGIN
      l_reqimport_request_id :=
         apps.fnd_request.submit_request ('PO','REQIMPORT','Requisition Import',Null,False,
                                         'Spares',NULL,'Vendor',NULL,'N','Y',CHR(0),
                                           '', '', '', '', '', '', '', '', '', '',
                                           '', '', '', '', '', '', '', '', '', '',
                                           '', '', '', '', '', '', '', '', '', '',
                                           '', '', '', '', '', '', '', '', '', '',
                                                 '', '', '', '', '', '', '', '', '', '',
                                           '', '', '', '', '', '', '', '', '', '',
                                           '', '', '', '', '', '', '', '', '', '',
                                           '', '', '', '', '', '', '', '', '', '',
                                           '', '', '', '', '', '', '', '' );
        
   Dbms_Output.Put_Line('started! Req ID ' || L_Reqimport_Request_Id);
  
   L_Dev_Phase := 'XX';
        
 COMMIT;
  WHILE NVL(L_Dev_Phase,'XX') != 'COMPLETE'
   LOOP   
       l_req_status :=    FND_CONCURRENT.WAIT_FOR_REQUEST  (L_Reqimport_Request_Id, 
                         10, 
                          0, 
                          L_Phase      , 
                          L_Status     , 
                          L_Dev_Phase  , 
                          L_Dev_Status , 
                          L_Message    ) ;
                      
          EXIT WHEN L_Dev_Phase = 'COMPLETE';
          END LOOP;                                                                
        COMMIT;                                                 
 EXCEPTION
   WHEN OTHERS THEN
      x_return_message :='error while submitting the Requisition Import concurrent program';
      x_return_status  := fnd_api.g_ret_sts_error;
      log_exception
                      (p_object_id               => NULL,--p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchase_req',
                       p_error_message_code      => 'XX_CS_SR06_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
     Dbms_Output.Put_Line('error while submitting the Requisition Import concurrent program :- '||SQLERRM);
END;
                                                                                                           
  IF  L_Reqimport_Request_Id !=0
  THEN 
   x_return_status  := Fnd_Api.G_Ret_Sts_Success;
   x_return_message := ' Requisition Import Succeded ' || L_Reqimport_Request_Id ||SQLERRM;
   
   SELECT COUNT(*)
     INTO L_Count
   FROM   Po_Interface_Errors
   WHERE  Request_Id= L_Reqimport_Request_Id
   ;     
      IF L_Count >0 THEN
          OPEN C_Err_Msg(L_Reqimport_Request_Id);
          LOOP
            EXIT WHEN C_Err_Msg%NOTFOUND;
            FETCH C_Err_Msg  INTO Lc_Error_Msg;
            Dbms_Output.Put_Line(Lc_Error_Msg);
          END LOOP;
          CLOSE C_Err_Msg;
          
          x_return_status   := Fnd_Api.G_Ret_Sts_Error;
          x_return_message  := 'Requisition Import Ran but errors occur' || Lc_Error_Msg;
          log_exception
                      (p_object_id               => NULL,--p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchase_req',
                       p_error_message_code      => 'XX_CS_SR06_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
     END IF;        
  ELSE
    x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
    x_return_message := 'Requisition Import failed ' || L_Reqimport_Request_Id ||SQLERRM;
    log_exception
                      (p_object_id               => NULL,--p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchase_req',
                       p_error_message_code      => 'XX_CS_SR06_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
  END IF;
END purchase_req;



 -- +=============================================================================+
-- | PROCEDURE NAME : PROCESS_REQ                                                  |
-- | DESCRIPTION    : Procedure to create PO based on requisition                 |                  
-- |                                                                             |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |                                                 |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+

PROCEDURE purchse_order    ( p_sr_number           IN    VARCHAR2
                            --,p_requirement_hdr_id  IN    NUMBER
                            ,p_parts_table         IN       xx_cs_tds_parts_tbl_type
                            ,x_return_status       IN OUT   VARCHAR2
                            ,x_return_message      IN OUT   VARCHAR2
                           )
   IS
      l_org_id                  po_requisition_headers_all.org_id%TYPE;
      l_vendor_id               po_requisition_lines_all.vendor_id%TYPE;
      L_Vendor_Site_Id          Po_Requisition_Lines_All.Vendor_Site_Id%Type;
      p_req_header_id           po_requisition_headers_all.requisition_header_id%TYPE;
      l_deliver_to_loc_id       po_requisition_lines_all.deliver_to_location_id%TYPE;
      l_term                    ap_terms.NAME%TYPE := NULL;
      l_store_id                NUMBER             := 0;
      L_Dist_Num                Po_Req_Distributions_All.Distribution_Num%Type;
      l_charge_acc              VARCHAR2 (200)     := NULL;
      L_Charge_Acc_Id           Number             := 0;
      L_Req_Id                  Number             := 0;
      L_Poimport_Request_Id     Number             := 0;
      L_Phase     varchar2(100);
      L_Status   varchar2(100);
      L_Dev_Phase  Varchar2(100);
      L_Dev_Status Varchar2(100);
      L_Message  Varchar2(4000);
      l_req_status boolean;
      
      Err                       Varchar2 (4000)    := Null;
      
      --remove when added to pkg
      l_resp_id        CONSTANT PLS_INTEGER      := 50501; -- Fnd_Global.Resp_Id;
      l_resp_appl_id   CONSTANT PLS_INTEGER      := 201;   --Fnd_Global.Resp_Appl_Id;
      l_user_id                 VARCHAR2 (20)    := 1197067;     
      g_org_Id                  NUMBER           := 404;
      l_count                   NUMBER           := 0;
      -- To get the payment term for the vendor
      CURSOR c_terms (l_vendor_id po_requisition_lines_all.vendor_id%TYPE)
      IS
         SELECT NAME
           FROM ap_terms
          WHERE term_id = (SELECT terms_id
                             FROM po_vendors
                            WHERE vendor_id = l_vendor_id);

      -- To get the req line details
      CURSOR c_req_lines (
         l_req_header_id   po_requisition_headers_all.requisition_header_id%TYPE,
         l_store_id        NUMBER
      )
      IS
         SELECT prla.line_num, prla.line_type_id, prla.item_id,
                prla.category_id, prla.quantity, prla.unit_price,
                prla.destination_organization_id, prla.need_by_date,
                prla.deliver_to_location_id, msib.description,
                msib.primary_uom_code, prla.requisition_line_id,
                prla.destination_type_code
           FROM po_requisition_lines_all prla, mtl_system_items_b msib
          WHERE prla.requisition_header_id = l_req_header_id
            AND msib.inventory_item_id = prla.item_id
            AND organization_id = l_store_id;

      c_req_line_rec            c_req_lines%ROWTYPE;

      CURSOR c_req_dist (
         l_req_line_id   po_requisition_lines_all.requisition_line_id%TYPE
      )
      IS
         SELECT distribution_num
           FROM po_req_distributions_all
          WHERE requisition_line_id = l_req_line_id;
   BEGIN   
   -- To get the requisition header id from requirement header id
   
 /*Select Requisition_Header_Id
 Into p_req_header_id
 From Po_Requisition_Lines_All Where Requisition_Line_Id In
 (Select Source_Id From Csp_Req_Line_Details  C , Csp_Requirement_Lines Crl Where C.Source_Type='POREQ'
 and c.requirement_line_id =crl.requirement_line_id and rownum<2 and crl.requirement_header_id = 11440) ;*/
 
 
 --- To get the requisition header id from SR number
   BEGIN
     SELECT Requisition_Header_Id
     INTO   P_Req_Header_Id
     FROM   Po_Requisition_Headers_All
     WHERE  Attribute14 = P_Sr_Number
     ;
      dbms_output.put_line('Requsition ID: ' || P_Req_Header_Id);
   EXCEPTION
     WHEN OTHERS THEN
       x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
       x_return_message := 'Error While fetching the requisition header id';
       log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
   END;   
  -- p_req_header_id :=p_requirement_hdr_id;    
     -- To get the store_id
      BEGIN
         SELECT store_id
           INTO l_store_id
           FROM xxom.xx_cs_tds_parts
          WHERE request_number = p_sr_number AND ROWNUM = 1;

         DBMS_OUTPUT.put_line (' Store ID ' || l_store_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
            x_return_message := 'Error While fetching the requisition store id';
            log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
            DBMS_OUTPUT.put_line (' Store ID not found');
      END;

      -- To find Org ID
      BEGIN
         SELECT org_id
           INTO l_org_id
           FROM po_requisition_headers_all
          WHERE requisition_header_id = p_req_header_id;

         DBMS_OUTPUT.put_line (' Org ID ' || l_org_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
            x_return_message := 'Error While fetching the org id';
            log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
            DBMS_OUTPUT.put_line (' Org ID not found');
      END;

      -- To select  deliver_to_location
      Begin
         SELECT deliver_to_location_id
           INTO  l_deliver_to_loc_id
           FROM po_requisition_lines_all
          WHERE requisition_header_id = p_req_header_id AND ROWNUM = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
            x_return_message := 'Error While fetching the deliver to location id';
            log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
            DBMS_OUTPUT.put_line ('  deliver to loc ID not found');
      END;

  -- To find vendor id and vendoe site id
  BEGIN
    SELECT Vendor_Id
          ,Vendor_Site_Id 
    INTO   L_Vendor_Id
          ,L_Vendor_Site_Id
    FROM   Po_Vendor_Sites_All 
    WHERE  Vendor_Id IN (SELECT Vendor_Id 
                           FROM Po_Vendors 
                           WHERE Vendor_Name Like 'NEXICORE SER%'
                        )
    AND    vendor_site_code='TDS682916'
   ;
 EXCEPTION
         WHEN OTHERS
         THEN
           x_return_status   :=  Fnd_Api.G_Ret_Sts_Error;
            x_return_message := 'Error While fetching the vendor id and vendor site id';
            log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
            Dbms_Output.Put_Line (' vendor  not found');
      END;

      -- To find term
      BEGIN
         OPEN  c_terms (l_vendor_id);
         FETCH c_terms
          INTO l_term;
         CLOSE c_terms;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
            x_return_message := 'Error While fetching the payment term details';
            log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
            DBMS_OUTPUT.put_line (' Terms not found');
      END;

      DBMS_OUTPUT.put_line (' Start Inserting into Headers');
    BEGIN
      INSERT INTO po_headers_interface
                  ( interface_header_id
                   ,batch_id
                   ,process_code
                   ,action
                   ,org_id
                   ,document_type_code
                   ,document_num
                   ,currency_code
                   ,agent_id
                   ,vendor_id
                   ,vendor_site_id
                   --,Bill_To_Location
                   ,ship_to_location_id
                   ,payment_terms
                   ,freight_carrier
                   ,approval_status
                   ,comments
                   ,attribute_category
                   ,attribute1
                   ,creation_date
                   ,created_by
                   ,last_update_date
                   ,last_updated_by
                   ,last_update_login
                  )
           VALUES ( po_headers_interface_s.NEXTVAL
                   ,po_headers_interface_s.CURRVAL
                   ,NULL --'OPEN'
                   ,'ORIGINAL'
                   ,l_org_id
                   ,'STANDARD'
                   ,p_sr_number
                   ,'USD'
                   ,g_buyer_id
                   ,l_vendor_id
                   ,l_vendor_site_id
                   --,l_deliver_to_loc_id
                   ,l_deliver_to_loc_id
                   ,l_term
                   ,'OD_GUIDE'
                   ,'APPROVED'
                   ,'TDS Parts PO for Service Request # '
                   ,'Trade','NA-TDSPARTS'  --Raj added
                   ,SYSDATE
                   ,fnd_profile.VALUE ('USER_ID')
                   ,SYSDATE
                   ,fnd_profile.VALUE ('USER_ID')
                   ,fnd_profile.VALUE ('USER_ID')
                  );            
          x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
          x_return_message := 'Error While inserting the data into po_headers_interface table'; 
            log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
    END;
      --  To insert into PO_lines_interface
      BEGIN
      OPEN c_req_lines (p_req_header_id, l_store_id);
      LOOP
         FETCH c_req_lines
          INTO c_req_line_rec;
         EXIT WHEN c_req_lines%NOTFOUND;
         DBMS_OUTPUT.put_line ('Item' || c_req_line_rec.item_id);
         DBMS_OUTPUT.put_line (' Start Inserting into lines');

         --BEGIN
            INSERT INTO po_lines_interface
                        ( interface_header_id
                         ,interface_line_id
                         ,action
                         ,line_num
                         ,shipment_num
                         ,line_type_id
                         ,item_id
                         ,category_id
                         ,item_description
                         ,uom_code --Derive From Item_Id
                         ,quantity
                         ,unit_price
                         ,receiving_routing_id
                         ,qty_rcv_tolerance
                         ,ship_to_organization_id
                         ,need_by_date
                         ,promised_date
                         ,accrue_on_receipt_flag
                         ,fob
                         ,last_update_date
                         ,last_updated_by
                         ,last_update_login
                         ,created_by
                         ,creation_date
                        )
                 VALUES ( po.po_headers_interface_s.CURRVAL
                         ,po.po_lines_interface_s.NEXTVAL
                         ,'ORIGINAL'
                         ,c_req_line_rec.line_num
                         ,1
                         ,c_req_line_rec.line_type_id
                         ,c_req_line_rec.item_id
                         ,c_req_line_rec.category_id
                         ,c_req_line_rec.description
                         ,c_req_line_rec.primary_uom_code
                         ,c_req_line_rec.quantity
                         ,c_req_line_rec.unit_price
                         ,3
                         ,0
                         ,C_Req_Line_Rec.Destination_Organization_Id
                         ,C_Req_Line_Rec.Need_By_Date
                         ,c_req_line_rec.need_by_date
                         ,'Y'
                         ,'SHIPPING'
                         ,SYSDATE
                         ,fnd_profile.VALUE ('USER_ID')
                         ,fnd_profile.VALUE ('USER_ID')
                         ,fnd_profile.VALUE ('USER_ID')
                         ,SYSDATE
                        );

            DBMS_OUTPUT.put_line (' Inserted into liness');
        
              
         /*
          EXCEPTION
            WHEN OTHERS
            THEN
             x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
             x_return_message := 'Error While inserting the data into po_lines_interface table'; 
             log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
         END;
*/
         -- To insert into PO_REQ_DISTRIBUTIONS

         -- To find charge account
         BEGIN
            SELECT    segment1
                   || '.'
                   || segment2
                   || '.'
                   || fnd_profile.VALUE ('XX_TDS_PARTS_MAT_ACCOUNT')
                   || '.'
                   || segment4
                   || '.'
                   || segment5
                   || '.'
                   || segment6
                   || '.'
                   || segment7
              INTO l_charge_acc
              FROM gl_code_combinations
             WHERE code_combination_id =
                      (SELECT material_account
                         FROM mtl_parameters
                        WHERE organization_id =
                                    c_req_line_rec.destination_organization_id
                      );
         EXCEPTION
            WHEN OTHERS
            THEN
                x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
                x_return_message := 'Error While fetching the charge account code combination'; 
                log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
               DBMS_OUTPUT.put_line (' Charge acc not found');
         END;

         DBMS_OUTPUT.put_line ('Charge Acc -' || l_charge_acc);
         BEGIN
         l_charge_acc_id :=
            fnd_flex_ext.get_ccid
                             ('SQLGL',
                              'GL#',
                              50310,
                              TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS')
                                                               --OD_GLOBAL_COA
                                                                        ,
                              l_charge_acc
                             );
           DBMS_OUTPUT.put_line ('charge_acc' || l_charge_acc_id);
           err := fnd_flex_ext.GET_MESSAGE;
           DBMS_OUTPUT.put_line (err);
          EXCEPTION
            WHEN OTHERS THEN
               x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
               x_return_message := 'Error While getting the charge account from fnd_flex_ext.get_ccid'; 
               log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
          END;
         
         OPEN   c_req_dist (c_req_line_rec.requisition_line_id);
         FETCH  c_req_dist
          INTO  l_dist_num;
          CLOSE c_req_dist;

         DBMS_OUTPUT.put_line (' Start Inserting into distribution');
       --BEGIN
         INSERT INTO po.po_distributions_interface
                     ( interface_header_id
                      ,interface_line_id
                      ,interface_distribution_id
                      ,distribution_num
                      ,quantity_ordered
                      ,deliver_to_location_id
                      ,destination_type_code
                      ,destination_organization_id
                      ,destination_subinventory
                      ,charge_account_id
                      ,accrual_account_id -- added by gaurav
                      ,creation_date
                      ,created_by
                      ,last_update_date
                      ,last_updated_by
                     )
              VALUES ( po.po_headers_interface_s.CURRVAL
                      ,po.po_lines_interface_s.CURRVAL
                      ,po.po_distributions_interface_s.NEXTVAL
                      ,l_dist_num
                      ,c_req_line_rec.quantity
                      ,c_req_line_rec.deliver_to_location_id
                      ,'INVENTORY'
                      ,C_Req_Line_Rec.Destination_Organization_Id
                      ,'STOCK'
                      ,l_charge_acc_id
                      ,g_accrual_account_id
                      ,SYSDATE
                      ,fnd_profile.VALUE ('USER_ID')
                      ,SYSDATE
                      ,fnd_profile.VALUE ('USER_ID')
                     );

         DBMS_OUTPUT.put_line (' Inserted into distribution');
      END LOOP;
      CLOSE c_req_lines;
       EXCEPTION    
        WHEN OTHERS THEN
             x_return_status  :=  Fnd_Api.G_Ret_Sts_Error;
             x_return_message := 'Error While inserting the data into po_distributions_interface table'; 
             log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
      END;
      COMMIT;
-- Call PO Import API
      fnd_global.apps_initialize (l_user_id,
                                  l_resp_id,
                                  l_resp_appl_id,
                                  l_org_id
                                 );
      DBMS_OUTPUT.put_line ('started Import PO');
      l_poimport_request_id :=
         apps.fnd_request.submit_request
                               (Application => 'PO' --Application,
                               ,Program => 'POXPOPDOI'--Program,
                               ,Argument1 => ''--Buyer ID,
                               ,Argument2 => 'STANDARD'--Document Type,
                               ,Argument3 => ''--Document Subtype,
                               ,Argument4 => 'N'--Process Items Flag,
                               ,Argument5 => 'N'--Create Sourcing rule,
                               ,Argument6 => ''--Approval Status,
                               ,Argument7 => ''--Release Generation Method,
                               ,Argument8 => ''--NULL,
                               ,Argument9 => g_Org_Id--Operating Unit ID,
                               ,argument10 => ''--Global Agreement
                                                          );
      DBMS_OUTPUT.put_line ('completed - Req ID :' || l_poimport_request_id);
      COMMIT;
      
      
      L_Dev_Phase := 'XX';
        
 
  WHILE NVL(L_Dev_Phase,'XX') != 'COMPLETE'
   LOOP   
       l_req_status :=  FND_CONCURRENT.WAIT_FOR_REQUEST  (l_poimport_request_id, 
                         10, 
                          0, 
                          L_Phase      , 
                          L_Status     , 
                          L_Dev_Phase  , 
                          L_Dev_Status , 
                          L_Message    ) ;
                      
          EXIT WHEN L_Dev_Phase = 'COMPLETE';
          END LOOP;                                                                
        COMMIT;         
        
        
                 
    
    BEGIN
      IF l_poimport_request_id != 0
      THEN
         x_return_status := fnd_api.g_ret_sts_success;
         x_return_message :=
               ' PO Import Succeded '
            || l_poimport_request_id
            || SQLERRM;
            
             SELECT COUNT(*)
             INTO  L_Count
             FROM  Po_Interface_Errors
             WHERE Request_Id= l_poimport_request_id;
               
      IF L_Count >0 THEN     
          x_return_status :=Fnd_Api.G_Ret_Sts_Error;
          x_return_message := ' POImport Ran but errors occur. Check the PO error table for errors' ;
           log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
     END IF;            
      ELSE
         x_return_status := fnd_api.g_ret_sts_error;
         x_return_message :=
            ' PO Import failed ' || l_poimport_request_id
            || SQLERRM;
            log_exception
                      (p_object_id               => p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order',
                       p_error_message_code      => 'XX_CS_SR07_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
      END IF;
        
        
        
 EXCEPTION
   WHEN OTHERS THEN
      x_return_message :='error while submitting the PO Import concurrent program';
      x_return_status  := fnd_api.g_ret_sts_error;
      log_exception
                      (p_object_id               => NULL,--p_sr_number,
                       p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchase_req',
                       p_error_message_code      => 'XX_CS_SR06_ERR_LOG',
                       p_error_msg               => x_return_message
                      );
     Dbms_Output.Put_Line('error while submitting the PO Import concurrent program :- '||SQLERRM);
END;
                                                                                                           
                              
  
  
   End Purchse_Order;
   
END xx_cs_tds_parts_pkg;
/
SHOW ERROR