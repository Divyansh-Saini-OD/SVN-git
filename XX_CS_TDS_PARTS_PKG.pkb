create or replace
PACKAGE BODY xx_cs_tds_parts_pkg
IS
-- +=============================================================================================+
-- |                       Office Depot - TDS                                                    |
-- |                                                                                             |
-- +=============================================================================================+
-- | Name         : XX_CS_TDS_PARTS_PKG.pkb                                                      |
-- | Description  : This package is used to add the selected parts, create items in inventory    |
-- |                and create the requisition and PO for the vendor                             |
-- |                                                                                             |
-- |Type        Name                       Description                                           |
-- |=========   ===========                ===================================================   |
-- |PROCEDURE   ADD_PARTS                  This procedure will add the Service Request Details   |
-- |                                       to XX_CS_TDS_PARTS Table along with Item,Quantity     |
-- |                                       and Price details                                     |
-- |                                                                                             |
-- |PROCEDURE   MAIN_PROC                  Main Procedure will calls the remaining all other     |
-- |                                       Procedures to craete the item/requisition and PO      |
-- |                                                                                             |
-- |PROCEDURE   CREATE_ITEMS               This procedure will check if the item is created or   |
-- |                                       not in Inventory.If the Item is not created in        |
-- |                                       Inventory then this procedure will create the item    |
-- |                                       in Inventory.This procedure will create the item By   |
-- |                                       calling create_item_process procedure.                |
-- |                                                                                             |
-- |PROCEDURE   CREATE_PARTS_REQ           This procedure will fetch all the required details    |
-- |                                       like resource_type,resource_id,item revision,task_id  |
-- |                                      ,task_assignment_id,shi_to_location_id and             |
-- |                                       destination subinventory.After fetches the all        |
-- |                                       required details this procedure will call's the       |
-- |                                       PROCESS_REQ API create requisition.                   |
-- |                                                                                             |
-- |PROCEDURE   PROCESS_REQ                This Procedure will insert the data into requisition  |
-- |                                       Interface tables.                                     |
-- |                                                                                             |
-- |PROCEDURE   PURCHASE_REQ               This Procedure will calls the requisition standard    |
-- |                                       Import program to create the requisition.             |
-- |                                                                                             |
-- |PROCEDURE   PURCHSE_ORDER              This procedure will insert the data into PO Interface |
-- |                                       tables and calls the PO standard import program to    |
-- |                                       create purchase order                                 |
-- |PROCEDURE   LOG_EXCEPTION              This procedure will print the error details if any    |
-- |                                       error occured due to any reason while executig the    |
-- |                                       package.                                              |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  11-Jul-2011  Deepti S             Initial draft version                            |
-- |      1B  22-Jan-2016  Vasu Raparla         Removed schema References for R.12.2             |
-- +=============================================================================================+

   -- +==================================================================================================+
-- |PROCEDURE   : LOG_EXCEPTION                                                                       |
-- |                                                                                                  |
-- |DESCRIPTION : This procedure will print the error details if any error occured due to any reason  |
-- |              while executig the package.                                                         |
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode    TYPE            DESCRIPTION                                       |
-- |-------------           ----   --------------   ---------------------------------                 |
-- | p_object_id             IN      VARCHAR2        Pass the Object ID Related to this package       |
-- |                                                                                                  |
-- | p_error_location        IN      VARCHAR2        Pass the error locaion where exactly             |
-- |                                                 error happend                                    |
-- |                                                                                                  |
-- | p_error_message_code    IN      VARCHAR2        Pass the error message code for that perticalar  |
-- |                                                 error                                            |
-- |                                                                                                  |
-- | p_error_msg             IN      VARCHAR2        Pass the error message for a perticular error    |
-- |                                                 happend during the package execution             |
-- |--------------------------------------------------------------------------------------------------|
   PROCEDURE log_exception (
      p_object_id IN VARCHAR2
    , p_error_location IN VARCHAR2
    , p_error_message_code IN VARCHAR2
    , p_error_msg IN VARCHAR2
   )
   IS
   BEGIN
      xx_com_error_log_pub.log_error (p_return_code                 => fnd_api.g_ret_sts_error
                                    , p_msg_count                   => 1
                                    , p_application_name            => 'XX_CRM'
                                    , p_program_type                => 'Custom Messages'
                                    , p_program_name                => 'XX_CS_TDS_PARTS_PKG'
                                    , p_program_id                  => NULL
                                    , p_object_id                   => p_object_id
                                    , p_module_name                 => 'CSF'
                                    , p_error_location              => p_error_location
                                    , p_error_message_code          => p_error_message_code
                                    , p_error_message               => p_error_msg
                                    , p_error_message_severity      => 'MAJOR'
                                    , p_error_status                => 'ACTIVE'
                                    , p_created_by                  => g_user_id
                                    , p_last_updated_by             => g_user_id
                                    , p_last_update_login           => g_login_id
                                     );
   END log_exception;
   
   /******************************************************************************
   -- Add advance quotation parts
   -- Raj added on 2/10/12
   *******************************************************************************/
PROCEDURE add_advance_parts (
                     p_sr_number      IN VARCHAR2
                    ,p_store_Number   IN VARCHAR2
                    ,p_quote_rec      IN xx_cs_tds_quote_rec
                    ,p_parts_table    IN Xx_Cs_Tds_Parts_Quote_Tbl
                    ,x_return_status  IN OUT VARCHAR2
                    ,x_return_message IN OUT VARCHAR2
                   )
   IS
      l_incident_id                 NUMBER;
      l_store_id                    NUMBER;
      l_return_status               VARCHAR2 (30);
      l_msg_count                   NUMBER;
      l_msg_data                    VARCHAR2 (4000);
      l_msg_index_out               VARCHAR2 (20);
      l_obj_ver_num                 NUMBER;
      l_sr_status_id                NUMBER;
      l_sr_status                   VARCHAR2 (20);
      l_que_index                   NUMBER;
      l_sku                         VARCHAR2 (80) := NULL;
      l_selling_cost                NUMBER := 0;
      l_selling_price               NUMBER := 0;
      l_interaction_id              NUMBER;
      lc_quote_flag                 VARCHAR2(1);
      lc_part_order_link            VARCHAR2(1000) := FND_PROFILE.VALUE('XX_CS_TDS_PARTS_LINK');
      lc_advance_quote_flag         VARCHAR2(1) := 'N';
   BEGIN
      l_return_status     := 'S';
      l_msg_count         := 0;
      l_msg_data          := NULL;
      l_interaction_id    := NULL;
      

      -- Get user_id
      BEGIN
         SELECT user_id
           INTO g_user_id
           FROM fnd_user
          WHERE user_name = 'CS_ADMIN';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_return_status    := 'E';
            l_msg_data         := 'Error while selecting user id for CS_ADMIN ' || SQLERRM;
      END;
      
      BEGIN
         UPDATE XX_CS_TDS_PARTS_QUOTES
         SET QUOTE_NUMBER = P_QUOTE_REC.QUOTE_NUMBER 
         WHERE REQUEST_NUMBER = P_SR_NUMBER;
         
         COMMIT;
      END;
      
      IF NVL (l_return_status, 'S') <> 'E'
      THEN
         -- Initialize the environment
         fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);

         --get Store_id
         BEGIN
            SELECT organization_id
              INTO l_store_id
              FROM hr_all_organization_units
             WHERE lpad(attribute1,5,0) = lpad(p_store_number,5,0);
         ----DBMS_OUTPUT.put_line ('Store ID  -' || l_store_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data         := 'Error in finding the Organization ID: ' || SQLERRM;
               l_return_status    := fnd_api.g_ret_sts_error;
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_ADVANCED_PARTS'
                            , p_error_message_code      => 'XX_CS_SR01_ERR_LOG'
                            , p_error_msg               => l_msg_data
                             );
         END;
          
      IF NVL (l_return_status, 'S') <> 'E'
      THEN
         l_que_index    := p_parts_table.FIRST;

          --DBMS_OUTPUT.put_line ('Looping based on no of items');
         WHILE l_que_index IS NOT NULL
         LOOP
          
        IF l_que_index = 1 THEN
          BEGIN
            -- Check Quote Number
            select 'Y'
            into lc_quote_flag
            from xx_cs_tds_parts
            where request_number = p_sr_number
            and quote_number = p_quote_rec.quote_number;

         EXCEPTION
            WHEN no_data_found THEN
               lc_quote_flag := 'N';
         
            WHEN OTHERS THEN
               lc_quote_flag := 'Y';
               l_msg_data         := 'Error while checking quotation: ' || SQLERRM;
               l_return_status    := 'E';
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_ADVANCED_PARTS'
                            , p_error_message_code      => 'XX_CS_SR01_ERR_LOG'
                             , p_error_msg               => l_msg_data
                             );
           END;
         END IF; -- index
         
                  
          IF nvl(lc_quote_flag,'Y') = 'N' then
            ---Get dummy (RMS) SKU from CS Lookups based on Category .
            BEGIN
               SELECT meaning
                 INTO l_sku
                 FROM cs_lookups
                WHERE lookup_type = 'XX_CS_TDS_PARTS_ITEM_REF'
                  AND lookup_code = p_parts_table (l_que_index).item_category;

               --DBMS_OUTPUT.put_line ('Dummy SKU - ' || l_sku);
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_msg_data         := 'Error in finding the RMS SKU: ' || SQLERRM;
                  l_return_status    := fnd_api.g_ret_sts_error;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_ADVANCED_PARTS'
                               , p_error_message_code      => 'XX_CS_SR02_ERR_LOG'
                               , p_error_msg               => l_msg_data
                                );
            END;
          
            -- Insert into custom table
            BEGIN
               INSERT INTO xx_cs_tds_parts
                           (request_number
                          , store_id
                          , line_number
                          , item_number
                          , item_description
                          , rms_sku
                          , quantity
                          , item_category
                          , purchase_price
                          , selling_price
                          , exchange_price
                          , core_flag
                          , uom
                          , schedule_date
                          , creation_date
                          , created_by
                          , last_udate_date
                          , last_updated_by
                          , attribute1
                          , attribute2
                          , attribute3
                          , attribute4
                          , attribute5
                          , sales_flag
                          , manufacturer
                          , model
                          , serial_number
                          , problem_descr
                          , special_instr
                          ,quote_number
                          ,expire_date
                          ,store_number
                           )
                    VALUES (p_sr_number
                          , l_store_id
                          , l_que_index
                          , p_parts_table (l_que_index).item_number
                          , p_parts_table (l_que_index).item_description
                          , l_sku
                          , p_parts_table (l_que_index).quantity
                          , p_parts_table (l_que_index).item_category
                          , p_parts_table (l_que_index).purchase_price
                          , p_parts_table (l_que_index).selling_price
                          , p_parts_table (l_que_index).exchange_price
                          , p_parts_table (l_que_index).core_flag
                          , upper(p_parts_table (l_que_index).uom)
                          , p_parts_table (l_que_index).schedule_date
                          , SYSDATE
                          , g_user_id
                          , SYSDATE
                          , g_user_id
                          , NULL
                          , NULL
                          , NULL
                          , NULL
                          , NULL
                          , NULL
                          , p_quote_rec.manufacturer
                          , p_quote_rec.model_no
                          , p_quote_rec.serial_number
                          , p_quote_rec.prob_descr
                          , p_quote_rec.special_instr
                          ,p_quote_rec.quote_number
                          ,p_quote_rec.expire_date
                           ,lpad(P_store_number,5,0)
                           );

                --DBMS_OUTPUT.put_line ('Success insert');
               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_msg_data    := 'Error in inserting into the table Xx_Cs_Tds_Parts ' || SQLERRM;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS'
                               , p_error_message_code      => 'XX_CS_SR03_ERR_LOG'
                               , p_error_msg               => l_msg_data
                                );
            End;
            L_Que_Index    := P_Parts_Table.Next (L_Que_Index);
             
             
             ELSE
             
                 l_msg_data         := 'Record already exist ' ;
                  l_return_status    := fnd_api.g_ret_sts_error;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_ADVANCED_PARTS'
                               , p_error_message_code      => 'XX_CS_SR02_ERR_LOG'
                               , P_Error_Msg               => L_Msg_Data
                                );
                     Exit;
          
              End If; -- quote_flag
              
                        
           EXIT WHEN L_Que_Index=P_Parts_Table.LAST+1 ; --or lc_quote_flag='Y' ;   
            
         END LOOP;
       END IF; -- Org Id
      
         -- Raj added for success message 9/6 
         x_return_status     := l_return_status;
         x_return_message    := 'Quote added successfully';
      ELSE
         x_return_status     := l_return_status;
         x_return_message    := l_msg_data;
      END IF;
     
   EXCEPTION
      WHEN OTHERS
      THEN
         l_msg_data    := 'Error in Add Advance Parts procedure ' || SQLERRM;
         log_exception (p_object_id => p_sr_number, 
                        p_error_location => 'XX_CS_TDS_PARTS_PKG.ADD_ADVANCE_PARTS', 
                        p_error_message_code => 'XX_CS_SR07_ERR_LOG', 
                        p_error_msg => l_msg_data);
   END add_advance_parts;
-- +=============================================================================+
-- | PROCEDURE NAME : ADD_PARTS                                                  |
-- | DESCRIPTION    : This procedure adds the parts to the corresponding         |
-- |                  service request and updates the status of service request  |
-- |                  to pending for approval                                    |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |
-- |             :  P_Store_Number    IN            VARCHAR2    SR number        |
-- |             :  P_PARTS_TABLE     IN            Table type   Table           |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE add_parts (
                     p_sr_number      IN VARCHAR2
                    ,p_store_Number   IN VARCHAR2
                    ,p_quote_rec      IN xx_cs_tds_quote_rec
                    ,p_parts_table    IN Xx_Cs_Tds_Parts_Quote_Tbl
                    ,x_return_status  IN OUT VARCHAR2
                    ,x_return_message IN OUT VARCHAR2
                   )
   IS
      l_incident_id                 NUMBER;
      l_store_id                    NUMBER;
      l_return_status               VARCHAR2 (30);
      l_msg_count                   NUMBER;
      l_msg_data                    VARCHAR2 (4000);
      l_msg_index_out               VARCHAR2 (20);
      l_obj_ver_num                 NUMBER;
      l_sr_status_id                NUMBER;
      l_sr_status                   VARCHAR2 (20);
      l_que_index                   NUMBER;
      l_sku                         VARCHAR2 (80) := NULL;
      l_selling_cost                NUMBER := 0;
      l_selling_price               NUMBER := 0;
      l_interaction_id              NUMBER;
      lc_quote_flag                 VARCHAR2(1);
      lc_part_order_link            VARCHAR2(1000) := FND_PROFILE.VALUE('XX_CS_TDS_PARTS_LINK');
      lc_advance_quote_flag         VARCHAR2(1) := 'N';
      lc_quote_number               VARCHAR2(25);
      lr_service_request_rec        CS_ServiceRequest_PUB.service_request_rec_type;
      lt_notes_table                CS_SERVICEREQUEST_PUB.notes_table;
      lt_contacts_tab               CS_SERVICEREQUEST_PUB.contacts_table;
      x_msg_count	                  NUMBER;
      x_return_msg                  VARCHAR2(1000);
      ln_msg_index_out              number;
      x_interaction_id              NUMBER;
      x_workflow_process_id         NUMBER;
   BEGIN
      l_return_status     := 'S';
      l_msg_count         := 0;
      l_msg_data          := NULL;
      l_interaction_id    := NULL;
      

      -- Get user_id
      BEGIN
         SELECT user_id
           INTO g_user_id
           FROM fnd_user
          WHERE user_name = 'CS_ADMIN';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_return_status    := 'E';
            l_msg_data         := 'Error while selecting user id for CS_ADMIN ' || SQLERRM;
      END;
      
      ---------------------------------------------------------------------
      -- Advance quote process
      ---------------------------------------------------------------------
       BEGIN
           SELECT 'Y' 
           into lc_advance_quote_flag 
           FROM xx_cs_tds_parts_quotes
           where request_number = p_sr_number;
       exception
          when no_data_found then
              lc_advance_quote_flag := 'N';
           when others then
             l_msg_data         := 'Error in finding the given incident number: ' || SQLERRM;
             l_return_status    := 'E';
             log_exception (p_object_id               => p_sr_number
                                  , p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE'
                                  , p_error_message_code      => 'XX_CS_SR01_ERR_LOG'
                                  , p_error_msg               => l_msg_data
                                   );
       end;
    
      IF nvl(lc_advance_quote_flag,'N') = 'Y' then
         add_advance_parts (
                     p_sr_number      => p_sr_number
                    ,p_store_Number   => p_store_number
                    ,p_quote_rec      => p_quote_rec
                    ,p_parts_table    => p_parts_table
                    ,x_return_status  => x_return_status
                    ,x_return_message => x_return_message
                   );
      ELSE
       BEGIN
            -- Get Incident info
            SELECT incident_id
                 , object_version_number
              INTO l_incident_id
                 , l_obj_ver_num
              FROM cs_incidents_all_b
             WHERE incident_number = p_sr_number;

         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data         := 'Error in finding the given incident number: ' || SQLERRM;
               l_return_status    := 'E';
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE'
                            , p_error_message_code      => 'XX_CS_SR02_ERR_LOG'
                            , p_error_msg               => l_msg_data
                             );
         END;
         

      IF NVL (l_return_status, 'S') <> 'E'
      THEN
         -- Initialize the environment
         fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);

         --get Store_id
         BEGIN
            SELECT organization_id
              INTO l_store_id
              FROM hr_all_organization_units
             WHERE lpad(attribute1,5,0) = lpad(p_store_number,5,0);
         ----DBMS_OUTPUT.put_line ('Store ID  -' || l_store_id);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data         := 'Error in finding the Organization ID: ' || SQLERRM;
               l_return_status    := fnd_api.g_ret_sts_error;
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS'
                            , p_error_message_code      => 'XX_CS_SR01_ERR_LOG'
                            , p_error_msg               => l_msg_data
                             );
         END;

         -- Delete previous quotes
         BEGIN
            DELETE from xx_cs_tds_parts
            where request_number = p_sr_number;
            
               l_msg_data         := 'Previous quote deleted for SR# ' || p_sr_number;
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS'
                            , p_error_message_code      => 'XX_CS_SR01_LOG'
                            , p_error_msg               => l_msg_data
                             );
            COMMIT;
            
          EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data         := 'Error while deleting quote ' || SQLERRM;
               l_return_status    := fnd_api.g_ret_sts_error;
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS'
                            , p_error_message_code      => 'XX_CS_SR01a_ERR_LOG'
                            , p_error_msg               => l_msg_data
                             );
          END;
          
      IF NVL (l_return_status, 'S') <> 'E'
      THEN
         l_que_index    := p_parts_table.FIRST;

          --DBMS_OUTPUT.put_line ('Looping based on no of items');
         WHILE l_que_index IS NOT NULL
         LOOP
          
         IF l_que_index = 1 THEN
           BEGIN
            -- Check Quote Number
            select 'Y'
            into lc_quote_flag
            from xx_cs_tds_parts
            where request_number = p_sr_number
            and quote_number = p_quote_rec.quote_number;

            LC_QUOTE_NUMBER := p_quote_rec.quote_number;
         EXCEPTION
            WHEN no_data_found THEN
               lc_quote_flag := 'N';
         
            WHEN OTHERS THEN
               lc_quote_flag := 'Y';
               l_msg_data         := 'Error while checking quotation: ' || SQLERRM;
               l_return_status    := 'E';
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE'
                            , p_error_message_code      => 'XX_CS_SR01_ERR_LOG'
                             , p_error_msg               => l_msg_data
                             );
           END;
         END IF; -- index
         
                  
          IF nvl(lc_quote_flag,'Y') = 'N' then
            ---Get dummy (RMS) SKU from CS Lookups based on Category .
            BEGIN
               SELECT meaning
                 INTO l_sku
                 FROM cs_lookups
                WHERE lookup_type = 'XX_CS_TDS_PARTS_ITEM_REF'
                  AND lookup_code = p_parts_table (l_que_index).item_category;

               --DBMS_OUTPUT.put_line ('Dummy SKU - ' || l_sku);
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_msg_data         := 'Error in finding the RMS SKU: ' || SQLERRM;
                  l_return_status    := fnd_api.g_ret_sts_error;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS'
                               , p_error_message_code      => 'XX_CS_SR02_ERR_LOG'
                               , p_error_msg               => l_msg_data
                                );
            END;
          
            -- Insert into custom table
            BEGIN
               INSERT INTO xx_cs_tds_parts
                           (request_number
                          , store_id
                          , line_number
                          , item_number
                          , item_description
                          , rms_sku
                          , quantity
                          , item_category
                          , purchase_price
                          , selling_price
                          , exchange_price
                          , core_flag
                          , uom
                          , schedule_date
                          , creation_date
                          , created_by
                          , last_udate_date
                          , last_updated_by
                          , attribute1
                          , attribute2
                          , attribute3
                          , attribute4
                          , attribute5
                          , sales_flag
                          , manufacturer
                          , model
                          , serial_number
                          , problem_descr
                          , special_instr
                          ,quote_number
                          ,expire_date
                          ,store_number
                           )
                    VALUES (p_sr_number
                          , l_store_id
                          , l_que_index
                          , p_parts_table (l_que_index).item_number
                          , p_parts_table (l_que_index).item_description
                          , l_sku
                          , p_parts_table (l_que_index).quantity
                          , p_parts_table (l_que_index).item_category
                          , p_parts_table (l_que_index).purchase_price
                          , p_parts_table (l_que_index).selling_price
                          , p_parts_table (l_que_index).exchange_price
                          , p_parts_table (l_que_index).core_flag
                          , upper(p_parts_table (l_que_index).uom)
                          , p_parts_table (l_que_index).schedule_date
                          , SYSDATE
                          , g_user_id
                          , SYSDATE
                          , g_user_id
                          , NULL
                          , NULL
                          , NULL
                          , NULL
                          , NULL
                          , NULL
                          , p_quote_rec.manufacturer
                          , p_quote_rec.model_no
                          , p_quote_rec.serial_number
                          , p_quote_rec.prob_descr
                          , p_quote_rec.special_instr
                          ,p_quote_rec.quote_number
                          ,p_quote_rec.expire_date
                           ,lpad(P_store_number,5,0)
                           );

                --DBMS_OUTPUT.put_line ('Success insert');
               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_msg_data    := 'Error in inserting into the table Xx_Cs_Tds_Parts ' || SQLERRM;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS'
                               , p_error_message_code      => 'XX_CS_SR03_ERR_LOG'
                               , p_error_msg               => l_msg_data
                                );
            End;
            L_Que_Index    := P_Parts_Table.Next (L_Que_Index);
             
             
             ELSE
             
                 l_msg_data         := 'Record already exist ' ;
                  l_return_status    := fnd_api.g_ret_sts_error;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS'
                               , p_error_message_code      => 'XX_CS_SR02_ERR_LOG'
                               , P_Error_Msg               => L_Msg_Data
                                );
                     Exit;
          
              End If; -- quote_flag
              
                        
           EXIT WHEN L_Que_Index=P_Parts_Table.LAST+1 ; --or lc_quote_flag='Y' ;   
            
         END LOOP;
       END IF; -- Org Id
     

      -- Get incident_status_id
      BEGIN
         SELECT incident_status_id
              , NAME
           INTO l_sr_status_id
              , l_sr_status
           FROM cs_incident_statuses
          WHERE incident_subtype = 'INC'
            AND NAME = 'Waiting for Approval';
       -- need to update to waiting for approval
      -- --DBMS_OUTPUT.put_line (' Incident status_id - ' || l_sr_status_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_msg_data         := 'Error in finding the incident status ID: ' || SQLERRM;
            l_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.ADD_PARTS'
                         , p_error_message_code      => 'XX_CS_SR04_ERR_LOG'
                         , p_error_msg               => l_msg_data
                          );
      END;

      IF (l_return_status = fnd_api.g_ret_sts_success)
      THEN
         
        /****************************************************************************/
        -- Update request.
        /*****************************************************************************/
        
        cs_servicerequest_pub.initialize_rec( lr_service_request_rec );
        lr_service_request_rec.status_id   := l_sr_status_id;
        lr_service_request_rec.external_attribute_13 := null;
        lr_service_request_rec.external_attribute_2 := null;
        lr_service_request_rec.external_attribute_6 := lc_part_order_link||P_SR_NUMBER;
        lr_service_request_rec.summary := 'Call Customer and get Approval';
       
         /*************************************************************************
           -- Add notes
          ************************************************************************/
            lt_notes_table(1).note        := 'Quote: '||lc_quote_number||' added to request, verify the parts and get approval and change to Approved status' ;
            lt_notes_table(1).note_detail := 'Quote: '||lc_quote_number||' added to request, verify the parts and get approval and change to Approved status' ;
            lt_notes_table(1).note_type   := 'GENERAL';
            
            /*******************************************************************************************
            -- Update Parts order
            *********************************************************************************************/
      
         cs_servicerequest_pub.Update_ServiceRequest (
            p_api_version            => 2.0,
            p_init_msg_list          => FND_API.G_TRUE,
            p_commit                 => FND_API.G_FALSE,
            x_return_status          => x_return_status,
            x_msg_count              => x_msg_count,
            x_msg_data               => x_return_msg,
            p_request_id             => l_incident_id,
            p_request_number         => NULL,
            p_audit_comments         => NULL,
            p_object_version_number  => l_obj_ver_num,
            p_resp_appl_id           => g_resp_appl_id,
            p_resp_id                => g_resp_id,
            p_last_updated_by        => g_user_id,
            p_last_update_login      => NULL,
            p_last_update_date       => sysdate,
            p_service_request_rec    => lr_service_request_rec,
            p_notes                  => lt_notes_table,
            p_contacts               => lt_contacts_tab,
            p_called_by_workflow     => FND_API.G_FALSE,
            p_workflow_process_id    => NULL,
            x_workflow_process_id    => x_workflow_process_id,
            x_interaction_id         => x_interaction_id   );
      
            commit;
      
         IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) then
            IF (FND_MSG_PUB.Count_Msg > 1) THEN
               --Display all the error messages
               FOR j in  1..FND_MSG_PUB.Count_Msg LOOP
                  FND_MSG_PUB.Get(p_msg_index     => j,
                                  p_encoded       => 'F',
                                  p_data          => x_return_msg,
                                  p_msg_index_out => ln_msg_index_out);
               END LOOP;
            ELSE      --Only one error
               FND_MSG_PUB.Get(
                  p_msg_index     => 1,
                  p_encoded       => 'F',
                  p_data          => x_return_msg,
                  p_msg_index_out => ln_msg_index_out);
      
            END IF;
          
            l_msg_data    := 'Update SR#'||p_sr_number||' - '||x_return_msg;
            log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS'
                               , p_error_message_code      => 'XX_CS_SR04a_ERR_LOG'
                               , p_error_msg               => l_msg_data
                                );
        END IF;
          
         -- Raj added for success message 9/6 
         x_return_status     := l_return_status;
         x_return_message    := 'Quote added successfully';
      ELSE
         x_return_status     := l_return_status;
         x_return_message    := l_msg_data;
      END IF;
      END IF;   -- Incident_id
     END IF;  -- advance quote flag
   EXCEPTION
      WHEN OTHERS
      THEN
         l_msg_data    := 'Error in Add Parts procedure ' || SQLERRM;
         log_exception (p_object_id => p_sr_number, p_error_location => 'XX_CS_TDS_PARTS_PKG.ADD_PARTS', p_error_message_code => 'XX_CS_SR07_ERR_LOG', p_error_msg => l_msg_data);
   END add_parts;

-- +=============================================================================+
-- | PROCEDURE NAME : MAIN_PROC                                                  |
-- | DESCRIPTION    : Wrapper package for Item, Requisition and PO creation      |
-- |                                                                             |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE main_proc (
      p_sr_number IN VARCHAR2
    , x_return_status IN OUT VARCHAR2
    , x_return_message IN OUT VARCHAR2
   )
   IS
      l_cs_tds_parts_tbl            xx_cs_tds_items_tbl_type;
      i                             NUMBER := 1;
      l_store_number                VARCHAR2 (240);
      l_store_name                  VARCHAR2 (240);
      l_return_status               VARCHAR2 (1) := NULL;
      l_return_message              VARCHAR2 (2000) := NULL;

      CURSOR c_sr_details (
         l_sr_number VARCHAR2
      )
      IS
         SELECT store_id
              , item_number
              , item_description
              , rms_sku
              , quantity
              , item_category
              , purchase_price
              , selling_price
              , exchange_price
              , core_flag
              , uom
              , schedule_date
              , attribute1
              , attribute2
              , attribute3
              , attribute4
              , attribute5
              , manufacturer
              , model
              , serial_number
              , problem_descr
              , special_instr
              , inventory_item_id                                                                 -- Added By Bala on 28-Jul to retrive inventory item id from XX_CS_TDS_PARTS table
           FROM xx_cs_tds_parts
          WHERE request_number = p_sr_number;

      c_sr_details_rec              c_sr_details%ROWTYPE;
   BEGIN
      i                   := 1;

      ----DBMS_OUTPUT.put_line ('Entering Main procedure');
      -- To get the store_number
      BEGIN
         SELECT attribute1
              , NAME                                                                                                                                          --from Organization_Id
           INTO l_store_number
              , l_store_name
           FROM hr_all_organization_units
          WHERE organization_id = (SELECT store_id
                                     FROM xx_cs_tds_parts
                                    WHERE request_number = p_sr_number
                                      AND ROWNUM = 1);
      -- l_store_number :=207;                        --comment later
      ----DBMS_OUTPUT.put_line ('Store Number - ' || l_store_number);
      EXCEPTION
         WHEN OTHERS
         THEN
            -- --DBMS_OUTPUT.put_line ( 'Store Number issue ' || l_store_number || SQLERRM );
            x_return_message    := 'Store Number not available ' || SQLERRM;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC'
                         , p_error_message_code      => 'XX_CS_SR07_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
      END;

      OPEN c_sr_details (p_sr_number);

      LOOP
         ----DBMS_OUTPUT.put_line ('Entering Loop');
         -- Build the table
         FETCH c_sr_details
          INTO l_cs_tds_parts_tbl (i);

         EXIT WHEN c_sr_details%NOTFOUND;
         i    := i + 1;
      END LOOP;

      CLOSE c_sr_details;

  -- To Display the records
/*  FOR i IN 1 .. l_cs_tds_parts_tbl.LAST
  LOOP
    --DBMS_OUTPUT.put_line ('REQNO : ' || l_cs_tds_parts_tbl (i).rms_sku);
    --DBMS_OUTPUT.put_line ( 'itemno  : ' || l_cs_tds_parts_tbl (i).item_number );
    --DBMS_OUTPUT.put_line ( 'itemdesc    : ' || l_cs_tds_parts_tbl (i).item_description );
    --DBMS_OUTPUT.put_line ('---------------------------');
  END LOOP;  */
      x_return_status     := fnd_api.g_ret_sts_success;
      x_return_message    := 'Success';
      ----DBMS_OUTPUT.put_line ('status' || x_return_status);
      -- Calling
      -- creation procedure
      ----DBMS_OUTPUT.put_line ('Call Create Items procedure');
      create_items (p_sr_number, l_store_number, l_store_name, l_cs_tds_parts_tbl, l_return_status, l_return_message);

      IF (l_return_status = fnd_api.g_ret_sts_success)
      THEN
         create_parts_req (p_sr_number, l_store_number, l_cs_tds_parts_tbl, l_return_status, l_return_message);

          --DBMS_OUTPUT.put_line ('Item parts successfully  : ' || l_return_message || '    : ' );
         IF (l_return_status = fnd_api.g_ret_sts_success)
         THEN
             --DBMS_OUTPUT.put_line ('Purchase req started');
            purchase_req (l_return_status, l_return_message);

            -- --DBMS_OUTPUT.put_line ('Purchase req completed' || l_return_message);
            IF (l_return_status = fnd_api.g_ret_sts_success)
            THEN
               -- Purchse_Order
               purchse_order (p_sr_number, g_requirement_hdr_id, l_cs_tds_parts_tbl, l_return_status, l_return_message);

               IF (l_return_status = fnd_api.g_ret_sts_success)
               THEN
                  --  --DBMS_OUTPUT.put_line ('Purchase order created successfuly');
                  x_return_message    := 'Purchase order created successfuly';
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC'
                               , p_error_message_code      => 'XX_CS_SR08_LOG_LOG'
                               , p_error_msg               => x_return_message
                                );
               ELSE
                  x_return_message    := 'Error while creating Purchase Order ' || l_return_message || SQLERRM;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC'
                               , p_error_message_code      => 'XX_CS_SR09_ERR_LOG'
                               , p_error_msg               => x_return_message
                                );
               END IF;
            ELSE
               x_return_message    := 'Error while creating Purchase Requisition ' || l_return_message || SQLERRM;
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC'
                            , p_error_message_code      => 'XX_CS_SR010_ERR_LOG'
                            , p_error_msg               => x_return_message
                             );
            END IF;
         ELSE
            x_return_message    := 'Error while creating Parts Requirement ' || l_return_message || SQLERRM;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC'
                         , p_error_message_code      => 'XX_CS_SR011_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
         END IF;
      ELSE
         x_return_message    := 'Error while creating Items ' || l_return_message || SQLERRM;
         log_exception (p_object_id               => p_sr_number
                      , p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC'
                      , p_error_message_code      => 'XX_CS_SR012_ERR_LOG'
                      , p_error_msg               => x_return_message
                       );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_message    := 'Error in Main PROC ' || SQLERRM;
         log_exception (p_object_id               => p_sr_number
                      , p_error_location          => 'XX_CS_TDS_PARTS_PKG.MAIN_PROC'
                      , p_error_message_code      => 'XX_CS_SR013_ERR_LOG'
                      , p_error_msg               => x_return_message
                       );
   END main_proc;

-- +=================================================================================================+
-- | PROCEDURE NAME : CREATE_ITEMS                                                                   |
-- | DESCRIPTION    : Internally calls the procedure XX_INV_ITEM_CREATION_PKG.CREATE_ITEM_PROCESS    |
-- |                  for creating the item, if does not exist                                       |
-- |                                                                                                 |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number                            |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code                          |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer                         |
-- +=============================================================================+
   PROCEDURE create_items (
      p_sr_number IN VARCHAR2
    , p_store_number IN VARCHAR2
    , p_store_name IN VARCHAR2
    , p_parts_table IN xx_cs_tds_items_tbl_type
    , x_return_status IN OUT VARCHAR2
    , x_return_message IN OUT VARCHAR2
   )
   AS
      l_index                       NUMBER;
      l_part_id                     NUMBER;
      l_item_id                     NUMBER := 0;
      l_succ_msg                    VARCHAR2 (4000) := NULL;
      l_store_num                   hr_all_organization_units.NAME%TYPE;
      l_return_message              VARCHAR2 (4000) := NULL;
   BEGIN

      l_store_num    := p_store_name;
      l_item_id      := 0;
      l_index        := p_parts_table.FIRST;

      WHILE l_index IS NOT NULL
      LOOP
         -- Check item in custom parts table -- Raj 3/31
         BEGIN
            SELECT inventory_item_id
              INTO l_part_id
              FROM xx_cs_tds_parts
             WHERE item_number = p_parts_table (l_index).item_number
               --AND store_id = p_parts_table (l_index).store_id
               AND request_number <> p_sr_number
               AND ROWNUM < 2;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_part_id    := NULL;
               l_item_id    := NULL;
            WHEN OTHERS
            THEN
               l_part_id           := NULL;
               x_return_message    := 'Error while selecting PartId ' || SQLERRM;
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.create_items'
                            , p_error_message_code      => 'XX_CS_SR014_ERR_LOG'
                            , p_error_msg               => x_return_message
                             );
         END;
         
         IF l_part_id is not null then
         -- Check item for particular store in mtl_systems -- Raj 3/31
           BEGIN
              SELECT inventory_item_id
                INTO l_item_id
                FROM mtl_system_items_b
               WHERE organization_id = p_parts_table (l_index).store_id
                 AND inventory_item_id = l_part_id
                 AND ROWNUM < 2;
                 
           EXCEPTION
              WHEN NO_DATA_FOUND
              THEN
                 l_item_id    := NULL;
              WHEN OTHERS
              THEN
                 l_item_id           := NULL;
                 x_return_message    := 'Error while selecting itemId ' || SQLERRM;
                 log_exception (p_object_id               => p_sr_number
                              , p_error_location          => 'XX_CS_TDS_PARTS_PKG.create_items'
                              , p_error_message_code      => 'XX_CS_SR014_ERR_LOG'
                              , p_error_msg               => x_return_message
                               );
           END;
         ELSE
            L_ITEM_ID := NULL;
         END IF;

         IF l_item_id IS NULL
         THEN
            BEGIN
               xx_inv_item_creation_pkg.create_item_process (l_item_id
                                                           , l_succ_msg
                                                           , p_parts_table (l_index).item_description
                                                           , l_store_num
                                                           , p_parts_table (l_index).uom
                                                           , p_parts_table (l_index).purchase_price
                                                           , p_parts_table (l_index).rms_sku
                                                           , p_parts_table (l_index).item_number
                                                           , p_parts_table (l_index).purchase_price
                                                            );
            -- --DBMS_OUTPUT.put_line('create_item_process item id :- '||l_item_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_return_message    := 'INSIDE EX: Error while  creating Items process:- ' || ' - ' || SQLERRM;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.create_items'
                               , p_error_message_code      => 'XX_CS_SR015_ERR_LOG'
                               , p_error_msg               => x_return_message
                                );
            END;
         ELSE
            
            begin
                update mtl_system_items_b
                set list_price_per_unit = p_parts_table (l_index).purchase_price
                where inventory_item_id = l_item_id
                and list_price_per_unit <> p_parts_table (l_index).purchase_price;  -- Raj 9/28
              --  and organization_id = p_parts_table (l_index).store_id;
              
                commit;
             exception
                when others then
                   x_return_message    := 'Error while updating mtl_system_items_b:- ' || ' - ' || SQLERRM;
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.create_items'
                               , p_error_message_code      => 'XX_CS_SR016_ERR_LOG'
                               , p_error_msg               => x_return_message
                                );
             end;

         END IF;

         -- l_que_index := p_parts_tbl.NEXT(l_que_index);
         -- l_index := p_parts_table.NEXT (l_index); --commented  by bala on 26-jul-2011
         -- g_item_id := l_item_id;
         IF l_item_id IS NULL
         THEN
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'ITEM not created! ' || ' - ' || SQLERRM;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.create_items'
                         , p_error_message_code      => 'XX_CS_SR03_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
         ELSE
            BEGIN
               UPDATE xx_cs_tds_parts
                  SET inventory_item_id = l_item_id
                WHERE request_number = p_sr_number
                  AND item_number = p_parts_table (l_index).item_number;

             
               ----DBMS_OUTPUT.put_line(' Bala - p_parts_table(l_index).item_number  :- '||p_parts_table(l_index).item_number);
               x_return_status     := fnd_api.g_ret_sts_success;
               x_return_message    := 'SUCCESS: created items ';
               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  --DBMS_OUTPUT.put_line ('Exception while updating item  :- ' || SQLERRM);
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.create_items'
                               , p_error_message_code      => 'XX_CS_SR016_ERR_LOG'
                               , p_error_msg               => x_return_message
                                );
            END;
         END IF;

         l_index    := p_parts_table.NEXT (l_index);                                                                                                -- Added  by bala on 26-jul-2011
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_message    := 'MAIN EX: Error while  creating Items process:- ' || ' - ' || SQLERRM;
         x_return_status     := fnd_api.g_ret_sts_error;
         log_exception (p_object_id               => p_sr_number, p_error_location => 'XX_CS_TDS_PARTS_PKG.CREATE_ITEMS', p_error_message_code => 'XX_CS_SR03_ERR_LOG'
                      , p_error_msg               => l_succ_msg);
   END create_items;

-- +=============================================================================+
-- | PROCEDURE NAME : CREATE_PARTS_REQ                                            |
-- | DESCRIPTION    : Procedure to create Requirement header and detail records   |
-- |                                                                              |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE create_parts_req (
      p_sr_number IN VARCHAR2
    , p_store_number IN VARCHAR2
    , p_parts_tbl IN xx_cs_tds_items_tbl_type
    , x_return_status OUT VARCHAR2
    , x_msg_data OUT VARCHAR2
   )
   AS
      l_return_status               VARCHAR2 (1) := NULL;
      l_msg_count                   NUMBER := 0;
      l_msg_data                    VARCHAR2 (4000) := NULL;
      l_header_rec                  csp_parts_requirement.header_rec_type;
      l_line_rec                    csp_parts_requirement.line_rec_type;
      l_line_tbl                    csp_parts_requirement.line_tbl_type;
      l_rqh_rec                     csp_requirement_headers_pub.rqh_rec_type;
      l_rql_rec                     csp_requirement_lines_pub.rql_rec_type;
      l_rql_tbl                     csp_requirement_lines_pub.rql_tbl_type;
      x_rql_tbl                     csp_requirement_lines_pub.rql_tbl_type;
      v_open_requirement            VARCHAR2 (240) := NULL;
      l_resource_id                 NUMBER := 0;
      l_resource_type               VARCHAR2 (30) := NULL;
      l_destination_org_id          NUMBER := 0;
      l_dest_sub_inv                VARCHAR2 (30) := NULL;
      l_task_id                     NUMBER := 0;
      l_task_assignment_id          NUMBER;
      l_inventory_item_id           NUMBER := 0;
      l_parts_tbl                   xx_cs_tds_parts_pkg.xx_cs_tds_items_tbl_type;
      l_revision                    VARCHAR2 (10);
      l_ship_to_loc_id              NUMBER := 0;
      l_incident_att11              VARCHAR2 (30) := NULL;
      l_msg_index_out               VARCHAR2 (240) := NULL;
      l_schedule_date               DATE := NULL;
      l_order_flag                  VARCHAR2 (1) := '';
      l_organization_id             NUMBER := 0;
      i                             NUMBER := 0;
      l_resp_id            CONSTANT PLS_INTEGER := 50501;                                                                                                    -- Fnd_Global.Resp_Id;
      l_resp_appl_id       CONSTANT PLS_INTEGER := 201;                                                                                                  --Fnd_Global.Resp_Appl_Id;
      l_user_id                     VARCHAR2 (20) := 1197067;
      l_org_id                      NUMBER := 404;

      -- Define cursor for Organization_id and Subinventory_code
      CURSOR c_default_org (
         v_resource_id NUMBER
      )
      IS
         SELECT organization_id
              , subinventory_code
           FROM csp_inv_loc_assignments
          WHERE resource_id = v_resource_id
            AND default_code = 'IN'
            AND SYSDATE BETWEEN NVL (effective_date_start, SYSDATE) AND NVL (effective_date_end, SYSDATE);

      r_default_org                 c_default_org%ROWTYPE;
   BEGIN
      l_parts_tbl                              := p_parts_tbl;
      -- To initialize env
      fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id, l_org_id);

      -- Select Task Id , resource_id and assignment_id
    /*  BEGIN
         SELECT jtl.task_id
              , jta.task_assignment_id
              , jta.resource_id
              , jta.resource_type_code
           INTO l_task_id
              , l_task_assignment_id
              , l_resource_id
              , l_resource_type
           FROM jtf_tasks_vl jtl
              , jtf_task_types_tl jtt
              , jtf_task_assignments jta
          WHERE jta.task_id = jtl.task_id
            AND jtt.task_type_id = jtl.task_type_id
            AND jtl.source_object_type_code = 'SR'
            AND jtl.source_object_id = (SELECT incident_id
                                          FROM cs_incidents_all_b
                                         WHERE incident_number = p_sr_number)
            AND jtt.NAME = 'TDS Diagnosis and Repair' ;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data         := 'Error while fetching the task id and task assignment id :- ' || ' - ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR017_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;  */
     
      
-- Raj added on 8/29/11
      -- Task id
      BEGIN
         SELECT jtl.task_id
         INTO l_task_id
           FROM jtf_tasks_b jtl
          WHERE jtl.source_object_type_code = 'SR'
            AND jtl.source_object_id = (SELECT incident_id
                                          FROM cs_incidents_all_b
                                         WHERE incident_number = p_sr_number)
            AND jtl.attribute5 = 'A'
            AND rownum < 2;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data         := 'Error while fetching the task id and task assignment id :- ' || ' - ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR017_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;
      -- resource id and resource_type
      BEGIN
        select jtt.resource_id, 
                'RS_'||jtt.category
        into   l_resource_id
              , l_resource_type
        from   jtf_rs_resource_extns jtt,
               jtf_rs_group_members jtm
        where jtm.resource_id = jtt.resource_id
        and   jtt.category = 'PARTY'
        and   jtm.delete_flag = 'N'
        and   exists (select 'x' from csp_inv_loc_assignments
                      where resource_id = jtt.resource_id )
        and   jtm.group_id = (SELECT owner_group_id
                            FROM cs_incidents_all_b
                            WHERE incident_number = p_sr_number);
      EXCEPTION
         WHEN OTHERS THEN
            x_msg_data         := 'Error while fetching the resource id :- ' || ' - ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR017a_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;
   -- 9/21 Raj 
         l_schedule_date := sysdate + 2;
 ----8/29/11     
      -- Fetching the Schedule Date
    /*  BEGIN
         SELECT schedule_date
           INTO l_schedule_date
           FROM xx_cs_tds_parts
          WHERE request_number = p_sr_number
            AND item_number = l_parts_tbl (1).item_number
            AND ROWNUM <= 1 ;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data         := 'Error while fetching the schedule_date :- ' || ' - ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR018_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;  */

      l_header_rec.resource_id                 := l_resource_id;                                                                         -- Commented By Bala For Adding Raj's Logic
      l_header_rec.resource_type               := l_resource_type;                                                                       -- Commented By Bala For Adding Raj's Logic
      l_rqh_rec.resource_id                    := l_resource_id;                                                                                    -- Added By Bala For Raj's Logic
      l_rqh_rec.resource_type                  := l_resource_type;                                                                                ---- Added By Bala For Raj's Logic

      ----DBMS_OUTPUT.put_line ('l_resource_id :- ' || l_resource_id);
      ----DBMS_OUTPUT.put_line ('Resource_type :- ' || l_header_rec.resource_type);
      -- Adding the resource default sub inventory
      BEGIN
         OPEN c_default_org (l_resource_id);

         FETCH c_default_org
          INTO r_default_org;

         ----DBMS_OUTPUT.put_line (c_default_org%ROWCOUNT);
         CLOSE c_default_org;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data         := 'Error while fetching the cursor c_default_org :- ' || ' - ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR019_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;

      BEGIN
         -- Determine Ship To location Id
         SELECT hrl.ship_to_location_id
           INTO l_ship_to_loc_id
           FROM csp_rs_cust_relations rcr
              , hz_cust_acct_sites cas
              , hz_cust_site_uses csu
              , po_location_associations pla
              , hr_locations_v hrl
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
            x_msg_data         := 'Error while fetching the Ship To location Id :- ' || ' - ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR20_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;

      BEGIN
         SELECT organization_id
              , location_id
           INTO l_organization_id
              , l_rqh_rec.ship_to_location_id
           FROM hr_all_organization_units
          WHERE attribute1 = p_store_number;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data         := 'Error while fetching the Organization id :- ' || ' - ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR21_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;



      l_destination_org_id                     := r_default_org.organization_id;
      l_dest_sub_inv                           := r_default_org.subinventory_code;
      x_return_status                          := 'S';
      --Start Commented By Bala For Adding Raj's Logic
      l_header_rec.order_type_id               := NULL;
      l_header_rec.ship_to_location_id         := l_rqh_rec.ship_to_location_id;--l_ship_to_loc_id;
      l_header_rec.dest_organization_id        := l_destination_org_id;
      l_header_rec.operation                   := 'CREATE';
      l_header_rec.need_by_date                := l_schedule_date;
      l_header_rec.task_id                     := l_task_id;
      l_header_rec.task_assignment_id          := l_task_assignment_id;
      l_header_rec.dest_subinventory           := l_dest_sub_inv;
      --End Commented By Bala For Adding Raj's Logic
      -- Start Added By Bala For Raj's Logic
      l_rqh_rec.open_requirement               := v_open_requirement;
      l_rqh_rec.order_type_id                  := NULL;
      l_rqh_rec.ship_to_location_id            := l_rqh_rec.ship_to_location_id ; -- l_ship_to_loc_id;
      l_rqh_rec.destination_organization_id    := l_destination_org_id;
      --l_rqh_rec.operation := 'CREATE';
      l_rqh_rec.need_by_date                   := l_schedule_date;
      l_rqh_rec.task_id                        := l_task_id;
      l_rqh_rec.task_assignment_id             := l_task_assignment_id;
      l_rqh_rec.destination_subinventory       := l_dest_sub_inv;

      -- End Added By Bala For Raj's Logic

      DBMS_OUTPUT.put_line ( 'l_header_rec.ship_to_location_id :- ' || l_header_rec.ship_to_location_id );
      ----DBMS_OUTPUT.put_line ( 'l_rqh_rec.ship_to_location_id :- ' || l_rqh_rec.ship_to_location_id );
      DBMS_OUTPUT.put_line ( 'l_rqh_rec.dest_organization_id :- ' || l_rqh_rec.destination_organization_id );
      ----DBMS_OUTPUT.put_line ( 'v.need_by_date :- ' || l_rqh_rec.need_by_date );
      ----DBMS_OUTPUT.put_line ('l_rqh_rec.task_id :- ' || l_rqh_rec.task_id);
      ----DBMS_OUTPUT.put_line ( 'l_rqh_rec.task_assignment_id:- ' || l_rqh_rec.task_assignment_id );
      ----DBMS_OUTPUT.put_line ( 'l_rqh_rec.dest_subinventory :- ' || l_rqh_rec.destination_subinventory );

      BEGIN
         -- Start Added By Bala For Raj's Logic
         csp_requirement_headers_pub.create_requirement_headers (p_api_version_number         => 1.0
                                                               , p_init_msg_list              => fnd_api.g_false
                                                               , p_commit                     => fnd_api.g_false
                                                               , p_rqh_rec                    => l_rqh_rec
                                                               , x_requirement_header_id      => g_requirement_hdr_id
                                                               , x_return_status              => l_return_status
                                                               , x_msg_count                  => l_msg_count
                                                               , x_msg_data                   => l_msg_data
                                                                );
         COMMIT;


      IF (l_return_status <> fnd_api.g_ret_sts_success)
      THEN
         -- --DBMS_OUTPUT.put_line ('First IF condition');
         -- --DBMS_OUTPUT.put_line ('l_return_status :- ' || l_return_status);
         IF (fnd_msg_pub.count_msg > 1)
         THEN
            --Display all the error messages
            FOR j IN 1 .. fnd_msg_pub.count_msg
            LOOP
               fnd_msg_pub.get (p_msg_index => j, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => l_msg_index_out);
               -- --DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
               -- --DBMS_OUTPUT.put_line ('l_msg_index_out :- ' || l_msg_index_out);
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                            , p_error_message_code      => 'XX_CS_SR23_ERR_LOG'
                            , p_error_msg               => l_msg_data
                             );
            END LOOP;
         ELSE
            fnd_msg_pub.get (p_msg_index => 1, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => l_msg_index_out);
            ----DBMS_OUTPUT.put_line ('Else Part');
            ----DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
            ----DBMS_OUTPUT.put_line ('l_msg_index_out :- ' || l_msg_index_out);
            ----DBMS_OUTPUT.put_line ('l_msg_count :- ' || l_msg_count);
            ----DBMS_OUTPUT.put_line ( 'IF msG =1 l_return_status :- ' || l_return_status );
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR24_ERR_LOG'
                         , p_error_msg               => l_msg_data
                          );
         END IF;
      ELSE
         ----DBMS_OUTPUT.put_line('CSP_REQUIREMENT_HEADERS_PUB.Create_requirement_headers IS Successes');
         ----DBMS_OUTPUT.put_line('l_return_status :- '||l_return_status);
         ----DBMS_OUTPUT.put_line('g_requirement_hdr_id is :-'||g_requirement_hdr_id);
         x_msg_data    := 'CSP_REQUIREMENT_HEADERS_PUB.Create_requirement_headers IS Successes';
         log_exception (p_object_id               => p_sr_number
                      , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                      , p_error_message_code      => 'XX_CS_SR25_log_LOG'
                      , p_error_msg               => x_msg_data
                       );

      -- End Added By Bala For Raj's Logic
      l_rql_tbl.DELETE;

      FOR i IN l_parts_tbl.FIRST .. l_parts_tbl.LAST
      LOOP
         ----DBMS_OUTPUT.put_line ('l_parts_tbl.FIRST :- ' || l_parts_tbl.FIRST);
         ----DBMS_OUTPUT.put_line ('l_parts_tbl.LAST :- ' || l_parts_tbl.LAST);
         ----DBMS_OUTPUT.put_line ('Entered Into First Loop');
         -- Dtermine revision no for item
         BEGIN
            -- Start Commented By Bala on 28-Jul to retrive inventory item id from XX_CS_TDS_PARTS table
            /*
            SELECT b.inventory_item_id
            INTO l_inventory_item_id
            FROM (SELECT *
            FROM mtl_system_items_b
            WHERE organization_id = l_organization_id) b
            WHERE b.attribute2 = l_parts_tbl (i).item_number;*/
            --'A2'
            -- End Commented By Bala on 28-Jul to retrive inventory item id from XX_CS_TDS_PARTS table
            SELECT inventory_item_id
              INTO l_inventory_item_id
              FROM xx_cs_tds_parts
             WHERE request_number = p_sr_number
               AND item_number = l_parts_tbl (i).item_number
               AND store_id = l_organization_id
               AND ROWNUM <= 1;

            ----DBMS_OUTPUT.put_line ('l_parts_tbl(i).inventory_item_id : ' || l_inventory_item_id);
            ----DBMS_OUTPUT.put_line ('l_parts_tbl(i).l_organization_id : ' || l_organization_id );
            SELECT revision
              INTO l_revision
              FROM mtl_item_revisions
             WHERE inventory_item_id = l_inventory_item_id                                            -- Commented By Bala on 28-Jul to inventory item id from XX_CS_TDS_PARTS table
               --     WHERE inventory_item_id = l_parts_tbl(i).inventory_item_id -- Added By Bala on 28-Jul to inventory item id from XX_CS_TDS_PARTS table
               AND organization_id = l_organization_id;
         ----DBMS_OUTPUT.put_line ( 'l_inventory_item_id :- ' || l_inventory_item_id );
         ----DBMS_OUTPUT.put_line ('l_revision :- ' || l_revision);
         EXCEPTION
            WHEN OTHERS
            THEN
               x_msg_data         := 'Error while fetching the inventory item id and revision :- ' || ' - ' || SQLERRM;
               x_return_status    := fnd_api.g_ret_sts_error;
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                            , p_error_message_code      => 'XX_CS_SR26_ERR_LOG'
                            , p_error_msg               => x_msg_data
                             );
         ----DBMS_OUTPUT.put_line ('Exception - 7 :- ' || SQLERRM);
         END;

         -- Start Commented By Bala For Adding Raj's Logic
         l_line_tbl (i).inventory_item_id        := l_inventory_item_id;                              -- Commented By Bala on 28-Jul to inventory item id from XX_CS_TDS_PARTS table
         --L_Line_Tbl (I).Inventory_Item_Id := l_parts_tbl(i).inventory_item_id; -- Added By Bala on 28-Jul to inventory item id from XX_CS_TDS_PARTS table
         l_line_tbl (i).revision                 := l_revision;
         l_line_tbl (i).unit_of_measure          := l_parts_tbl (i).uom;
         l_line_tbl (i).quantity                 := l_parts_tbl (i).quantity;
         l_line_tbl (i).ordered_quantity         := l_parts_tbl (i).quantity;
         l_line_tbl (i).line_num                 := i;
         -- End Commented By Bala For Adding Raj's Logic
         --l_line_tbl(i)                    := l_line_rec;
         -- Start Added By Bala For Raj's Logic
         l_rql_tbl (i).requirement_header_id     := g_requirement_hdr_id;                                                                                             --g_header_id;
         --l_rql_tbl(i).inventory_item_id       := l_inventory_item_id; -- Commented By Bala on 28-Jul to inventory item id from XX_CS_TDS_PARTS table
         l_rql_tbl (i).inventory_item_id         := l_inventory_item_id;                    -- Added By Bala on 28-Jul to inventory item id from XX_CS_TDS_PARTS table
         l_rql_tbl (i).revision                  := l_revision;
         l_rql_tbl (i).uom_code                  := l_parts_tbl (i).uom;
         l_rql_tbl (i).ordered_quantity          := l_parts_tbl (i).quantity;
         l_rql_tbl (i).required_quantity         := l_parts_tbl (i).quantity;
         l_rql_tbl (i).source_organization_id    := l_destination_org_id;
         l_rql_tbl (i).source_subinventory       := l_dest_sub_inv;
         l_rql_tbl (i).order_by_date             := SYSDATE;
         l_rql_tbl (i).arrival_date              := l_schedule_date;
        -- End Added By Bala For Raj's Logic
      --  --DBMS_OUTPUT.put_line ( 'l_rql_tbl(i).inventory_item_id :- ' || l_rql_tbl (i).inventory_item_id );
      --  --DBMS_OUTPUT.put_line ( 'l_rql_tbl(i).revision :- ' || l_rql_tbl (i).revision );
      --  --DBMS_OUTPUT.put_line ( 'l_rql_tbl(i).unit_of_measure :- ' || l_rql_tbl (i).uom_code );
      --  --DBMS_OUTPUT.put_line ( 'l_rql_tbl(i).quantity :- ' || l_rql_tbl (i).ordered_quantity );
      --  --DBMS_OUTPUT.put_line ( 'l_rql_tbl(i).l_destination_org_id :- ' || l_rql_tbl (i).source_organization_id );
      END LOOP;

      l_order_flag                             := 'N';
      --Call the standard API
      l_return_status                          := '';
      l_msg_data                               := '';

      ----DBMS_OUTPUT.put_line ( 'Before Calling API l_return_status :- ' || l_return_status );
      --DBMS_OUTPUT.put_line ('Calling req lines API');
      --DBMS_OUTPUT.put_line ('req line id:' || L_Rql_Tbl(1).Requirement_Line_Id);
      --DBMS_OUTPUT.put_line ('req header id:' || L_Rql_Tbl(L_Rql_Tbl.First).Requirement_Header_Id);
      --DBMS_OUTPUT.put_line ('inventory_item_Id:' || L_Rql_Tbl(L_Rql_Tbl.first).inventory_item_Id);
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
      BEGIN
         csp_requirement_lines_pub.create_requirement_lines (p_api_version_number        => 1.0
                                                           , p_init_msg_list             => fnd_api.g_false
                                                           , p_commit                    => fnd_api.g_false
                                                           , p_rql_tbl                   => l_rql_tbl
                                                           , x_requirement_line_tbl      => x_rql_tbl
                                                           , x_return_status             => l_return_status
                                                           , x_msg_count                 => l_msg_count
                                                           , x_msg_data                  => l_msg_data
                                                            );
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_msg_data    := 'Error while calling CSP Requirement lines ' || SQLERRM;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR27_ERR_LOG'
                         , p_error_msg               => l_msg_data
                          );
      END;

      -- End Added By Bala For Raj's Logic
      /*
      --DBMS_OUTPUT.put_line ('After lines API l_return_status :- ' || L_Return_Status);
      --DBMS_OUTPUT.put_line ('After lines API l_msg_data :- ' || L_Msg_Data || L_Msg_Count);
      --DBMS_OUTPUT.put_line ('req line id from x:' || TO_CHAR(X_Rql_Tbl(X_Rql_Tbl.First).Requirement_Line_Id));
      --DBMS_OUTPUT.put_line ('req line id: from l' || TO_CHAR(l_Rql_Tbl(l_Rql_Tbl.First).Requirement_Line_Id));
      --DBMS_OUTPUT.put_line ('req header id:' || X_Rql_Tbl(X_Rql_Tbl.First).Requirement_Header_Id);
      --DBMS_OUTPUT.put_line ('req item :' || x_rql_tbl(x_rql_tbl.first).inventory_item_Id);
      */
      IF (l_return_status <> fnd_api.g_ret_sts_success)
      THEN
         ----DBMS_OUTPUT.put_line ('l_return_status :- ' || l_return_status);
         IF (fnd_msg_pub.count_msg > 1)
         THEN
            ----DBMS_OUTPUT.put_line ('Second IF condition');
            ----DBMS_OUTPUT.put_line ( 'FND_MSG_PUB.Count_Msg  :- ' || fnd_msg_pub.count_msg );
            ----DBMS_OUTPUT.put_line ( 'IF msG >1 x_return_status :- ' || l_return_status );
            --Display all the error messages
            FOR j IN 1 .. fnd_msg_pub.count_msg
            LOOP
               fnd_msg_pub.get (p_msg_index => j, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => l_msg_index_out);
               ----DBMS_OUTPUT.put_line ('Second Loop');
               ----DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
               ----DBMS_OUTPUT.put_line ('l_msg_index_out :- ' || l_msg_index_out);
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                            , p_error_message_code      => 'XX_CS_SR28_ERR_LOG'
                            , p_error_msg               => l_msg_data
                             );
            END LOOP;
         ELSE
            fnd_msg_pub.get (p_msg_index => 1, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => l_msg_index_out);
            /* --DBMS_OUTPUT.put_line ('Else Part');
             --DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
             --DBMS_OUTPUT.put_line ('l_msg_index_out :- ' || l_msg_index_out);
             --DBMS_OUTPUT.put_line ('l_msg_count :- ' || l_msg_count);
             --DBMS_OUTPUT.put_line ( 'IF msG =1 l_return_status :- ' || l_return_status ); */
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR29_ERR_LOG'
                         , p_error_msg               => l_msg_data
                          );
         END IF;
      ELSE
         -- Callinf PROCESS_REQ Procedure
         --Process_Req(P_Sr_Number,L_Header_Rec,L_Line_Tbl,X_Return_Status,X_Msg_Data); -- Commented By Bala For Adding Raj's Logic
         BEGIN
            process_req (p_sr_number, l_rqh_rec, x_rql_tbl, l_header_rec, l_line_tbl, x_return_status, x_msg_data);                                -- Added By Bala For Raj's Logic
         ----DBMS_OUTPUT.put_line ('l_return_status :- ' || l_return_status);
         ----DBMS_OUTPUT.put_line ('l_msg_data :- ' || l_msg_data);
         ----DBMS_OUTPUT.put_line ( 'FND_MSG_PUB.Count_Msg :- ' || fnd_msg_pub.count_msg );
         EXCEPTION
            WHEN OTHERS
            THEN
               l_msg_data    := 'error while calling process_req ' || SQLERRM;
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                            , p_error_message_code      => 'XX_CS_SR30_ERR_LOG'
                            , p_error_msg               => l_msg_data
                             );
         END;
      END IF;

      END IF;
    EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data         := 'Error while calling csp headers package :- ' || ' - ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR22_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;

      x_return_status                          := l_return_status;
      x_msg_data                               := l_msg_data;
   END create_parts_req;

-- +=============================================================================+
-- | PROCEDURE NAME : PROCESS_REQ                                                  |
-- | DESCRIPTION    : Procedure to create requisition details in the interface     |
-- |                  table                                                       |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE process_req (
      p_sr_number IN VARCHAR2
    , p_req_header_rec IN csp_requirement_headers_pub.rqh_rec_type
    , p_req_line_tbl IN csp_requirement_lines_pub.rql_tbl_type
    , p_header_rec IN csp_parts_requirement.header_rec_type
    , p_line_tbl IN csp_parts_requirement.line_tbl_type
    , x_return_status OUT VARCHAR2
    , x_msg_data OUT VARCHAR2
   )
   AS
      l_return_status               VARCHAR2 (1) := NULL;
      l_msg_count                   NUMBER := 0;
      l_msg_data                    VARCHAR2 (4000) := NULL;
      l_msg_index_out               VARCHAR2 (2000) := NULL;
      i                             NUMBER;
      l_rqh_rec                     csp_requirement_headers_pub.rqh_rec_type;
      l_rql_tbl                     csp_requirement_lines_pub.rql_tbl_type;
      l_header_rec                  csp_parts_requirement.header_rec_type;
      l_po_line_tbl                 csp_parts_requirement.line_tbl_type;
      l_line_rec                    csp_parts_requirement.line_rec_type;
      l_resp_id            CONSTANT PLS_INTEGER := 50501;                                                                                                    -- Fnd_Global.Resp_Id;
      l_resp_appl_id       CONSTANT PLS_INTEGER := 201;                                                                                                 -- Fnd_Global.Resp_Appl_Id;
      l_user_id                     VARCHAR2 (20) := 1197067;                                                                                                        -- := 1200246;
      l_org_id                      NUMBER := 404;
      l_req_line_dtl_id             NUMBER;
      l_login_id                    NUMBER := l_user_id;
      l_req_line_id                 csp_requirement_lines.requirement_line_id%TYPE;
      l_accrual_account             VARCHAR2 (200) := NULL;
      l_accrual_account_id          NUMBER := 0;
      l_charge_acc                  VARCHAR2 (200) := NULL;
      l_charge_acc_id               NUMBER := 0;
      err                           VARCHAR2 (100);
   BEGIN
      l_header_rec     := p_header_rec;
      l_po_line_tbl    := p_line_tbl;
      l_rqh_rec        := p_req_header_rec;
      l_rql_tbl        := p_req_line_tbl;
      fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id, l_org_id);
      csp_parts_order.process_purchase_req (p_api_version        => 1.0
                                          ,                                                                                                                   --l_api_version_number
                                            p_init_msg_list      => fnd_api.g_false
                                          ,                                                                                                                        --p_init_msg_list
                                            p_commit             => fnd_api.g_false
                                          ,                                                             --p_commit                                                                 ,
                                            px_header_rec        => l_header_rec
                                          , px_line_table        => l_po_line_tbl
                                          , x_return_status      => l_return_status
                                          , x_msg_count          => l_msg_count
                                          , x_msg_data           => l_msg_data
                                           );
  --DBMS_OUTPUT.put_line ( 'PROCESS_REQ l_return_status :- ' || l_return_status );
         --DBMS_OUTPUT.put_line ('PROCESS_REQ l_return_message :- ' || l_msg_data );
      IF (l_return_status <> fnd_api.g_ret_sts_success)
      THEN

         IF (fnd_msg_pub.count_msg > 1)
         THEN
            --Display all the error messages
            FOR j IN 1 .. fnd_msg_pub.count_msg
            LOOP
               fnd_msg_pub.get (p_msg_index => j, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => l_msg_index_out);
               ----DBMS_OUTPUT.put_line ('PROCESS_REQ l_msg_data :- ' || l_msg_data );
               ----DBMS_OUTPUT.put_line ( 'PROCESS_REQ l_msg_index_out :- ' || l_msg_index_out );
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                            , p_error_message_code      => 'XX_CS_SR31_ERR_LOG'
                            , p_error_msg               => l_msg_data
                             );
            END LOOP;
         ELSE
            fnd_msg_pub.get (p_msg_index => 1, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => l_msg_index_out);
            -- --DBMS_OUTPUT.put_line ('PROCESS_REQ l_msg_data :- ' || l_msg_data );
             ----DBMS_OUTPUT.put_line ( 'PROCESS_REQ l_msg_index_out :- ' || l_msg_index_out );
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.CREATE_PARTS_REQ'
                         , p_error_message_code      => 'XX_CS_SR32_ERR_LOG'
                         , p_error_msg               => l_msg_data
                          );
         END IF;
      ELSE
         --DBMS_OUTPUT.put_line ('PROCESS_REQ Success');
         --DBMS_OUTPUT.put_line ('req header id: ' || L_Header_Rec.Requisition_Header_Id);
         g_req_header_id    := l_header_rec.requisition_header_id;

         ----DBMS_OUTPUT.put_line ('req header id: ' || G_Req_Header_Id);
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
         --DBMS_OUTPUT.put_line ('error in updating SR number');
         END;
         COMMIT; */
         -- Raj added
         -- insert into csp_req_line_Details table with purchase req information
         FOR i IN l_rql_tbl.FIRST .. l_rql_tbl.LAST
         LOOP
            --DBMS_OUTPUT.put_line ('req line id :' ||L_Rql_Tbl(I).Requirement_Header_Id);
            --DBMS_OUTPUT.put_line ('req line id :' || l_po_line_tbl(i).inventory_item_id);
            SELECT csp_req_line_details_s1.NEXTVAL
              INTO l_req_line_dtl_id
              FROM DUAL;

            --DBMS_OUTPUT.put_line ('Calling line details API');

            begin
            SELECT requirement_line_id
              INTO l_req_line_id
              FROM csp_requirement_lines
             WHERE requirement_header_id = l_rql_tbl (i).requirement_header_id
               AND inventory_item_id = l_po_line_tbl (i).inventory_item_id;
exception when others then
            --DBMS_OUTPUT.put_line ('req line id :' ||L_Rql_Tbl(I).Requirement_Header_Id);
            --DBMS_OUTPUT.put_line ('req line id :' || L_Rql_Tbl(I).inventory_item_id);
            NULL;
            end;
              --DBMS_OUTPUT.put_line ('req line id  out side :' ||L_Rql_Tbl(I).Requirement_Header_Id);
            begin
            csp_req_line_details_pkg.insert_row (px_req_line_detail_id      => l_req_line_dtl_id
                                               , p_requirement_line_id      => l_req_line_id
                                               , p_created_by               => NVL (l_user_id, 1)
                                               , p_creation_date            => SYSDATE
                                               , p_last_updated_by          => NVL (l_user_id, 1)
                                               , p_last_update_date         => SYSDATE
                                               , p_last_update_login        => NVL (l_login_id, -1)
                                               , p_source_type              => 'POREQ'
                                               , p_source_id                => l_po_line_tbl (i).requisition_line_id
                                                );

                                                exception when others then
                                                NULL; --DBMS_OUTPUT.put_line (' csp_req_line_details_pkg.insert_row  :' ||SQLERRM );
                                                end;
         END LOOP;
      ------
      END IF;

      -- Fetching Buyer ID
      BEGIN
         SELECT agent_id
           INTO g_buyer_id
           FROM po_agents_v
          WHERE agent_name = 'Merchandize, Buyer';                                                             --'Agarwal, Gaurav' ;  --'Merchandize, Buyer'   commented for testing
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data         := 'Error In Fetching Buyer ID:- ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            ----DBMS_OUTPUT.put_line ('PROCESS_REQ Buyer Exception-1 :- ' || SQLERRM);
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.PROCESS_REQ'
                         , p_error_message_code      => 'XX_CS_SR33_ERR_LOG'
                         , p_error_msg               => x_msg_data
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
                || '010000'                                                                                                                                              -- segment4
                || '.'
                || segment5
                || '.'
                || segment6
                || '.'
                || segment7
           INTO l_accrual_account
           FROM gl_code_combinations
          WHERE code_combination_id = (SELECT material_account
                                         FROM mtl_parameters
                                        WHERE organization_id = l_header_rec.dest_organization_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status    := fnd_api.g_ret_sts_error;
            x_msg_data         := 'Error While fetching the accrual_account code combination';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR34_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      ----DBMS_OUTPUT.put_line (' accrual_account not found');
      END;

      --DBMS_OUTPUT.put_line ('accrual_account -' || l_charge_acc);

      BEGIN
         g_accrual_account_id    := fnd_flex_ext.get_ccid ('SQLGL', 'GL#', 50310, TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS')
                                                                                                                            --OD_GLOBAL_COA
                                                           , l_accrual_account);
         ----DBMS_OUTPUT.put_line ('accrual_account' || l_charge_acc_id);
         err                     := fnd_flex_ext.GET_MESSAGE;
      ----DBMS_OUTPUT.put_line (err);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status    := fnd_api.g_ret_sts_error;
            x_msg_data         := 'Error While getting the  accrual_account from fnd_flex_ext.get_ccid';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR35_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;

      BEGIN
         SELECT segment1 || '.' || segment2 || '.' || fnd_profile.VALUE ('XX_TDS_PARTS_MAT_ACCOUNT') || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.' || segment7
           INTO l_charge_acc
           FROM gl_code_combinations
          WHERE code_combination_id = (SELECT material_account
                                         FROM mtl_parameters
                                        WHERE organization_id = l_header_rec.dest_organization_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status    := fnd_api.g_ret_sts_error;
            x_msg_data         := 'Error While fetching the charge account code combination';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR36_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      ----DBMS_OUTPUT.put_line (' Charge acc not found');
      END;

      ----DBMS_OUTPUT.put_line ('Charge Acc -' || l_charge_acc);
      BEGIN
         g_charge_acc_id    := fnd_flex_ext.get_ccid ('SQLGL', 'GL#', 50310, TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS')
                                                                                                                       --OD_GLOBAL_COA
                                                      , l_charge_acc);
         ----DBMS_OUTPUT.put_line ('charge_acc' || l_charge_acc_id);
         err                := fnd_flex_ext.GET_MESSAGE;
      ----DBMS_OUTPUT.put_line (err);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status    := fnd_api.g_ret_sts_error;
            x_msg_data         := 'Error While getting the charge account from fnd_flex_ext.get_ccid';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR37_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;

      BEGIN

       --DBMS_OUTPUT.put_line ( '   g_req_header_id   : ' || g_req_header_id  );


         IF g_req_header_id IS NOT NULL
         THEN
            UPDATE po_requisitions_interface_all
               SET preparer_id = g_buyer_id
                 , deliver_to_requestor_id = g_buyer_id
                 , header_attribute14 = p_sr_number
                 , charge_account_id = g_charge_acc_id
                 , accrual_account_id = g_accrual_account_id
             WHERE requisition_header_id = g_req_header_id;

            -- Start Added by bala on 27-jul
            /*   Update Po_Requisitions_Interface_All
            SET authorization_status='APPROVED'
            WHERE REQUISITION_HEADER_ID = g_req_header_id
            ;
            */
            -- end Added by bala on 27-jul
            x_msg_data         := 'Prepared id and deliver to requester_id is  generated :- ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_success;
         ELSE
            x_msg_data         := 'Prepared id and deliver to requester_id not generated :- ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_msg_data         := 'Error While updating the PO_REQUISITIONS_INTERFACE_ALL table:- ' || SQLERRM;
            x_return_status    := fnd_api.g_ret_sts_error;
            ----DBMS_OUTPUT.put_line ('Error While updating the PO_REQUISITIONS_INTERFACE_ALL table :- ' || SQLERRM);
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.PROCESS_REQ'
                         , p_error_message_code      => 'XX_CS_SR38_ERR_LOG'
                         , p_error_msg               => x_msg_data
                          );
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_msg_data         := 'Error In PROCESS_REQ Procedure Main Block:- ' || SQLERRM;
         x_return_status    := fnd_api.g_ret_sts_error;
         ----DBMS_OUTPUT.put_line ('PROCESS_REQ Exception-1 :- ' || SQLERRM);
         log_exception (p_object_id               => p_sr_number, p_error_location => 'XX_CS_TDS_PARTS_PKG.PROCESS_REQ', p_error_message_code => 'XX_CS_SR05_ERR_LOG'
                      , p_error_msg               => x_msg_data);
   END;

-- +=============================================================================+
-- | PROCEDURE NAME : PURCHASE_REQ                                                 |
-- | DESCRIPTION    : Procedure to create requisition through REQIMPORT           |
-- |                                                                             |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE purchase_req (
      x_return_status IN OUT VARCHAR2
    , x_return_message IN OUT VARCHAR2
   )
   IS
      l_reqimport_request_id        NUMBER;
      l_resp_id           PLS_INTEGER; -- := 50501;                                                                                                    -- Fnd_Global.Resp_Id;
      l_resp_appl_id        PLS_INTEGER ; --:= 201;                                                                                                  --Fnd_Global.Resp_Appl_Id;
      l_user_id                     VARCHAR2 (20);-- := 1197067;                                                                                                            --1200246;
      -- G_User_Name    Constant Varchar2 (20) := '598133' ; --'CS_ADMIN';
      l_org_id                      NUMBER := 404;                                                                                                                   -- need to set
      l_phase                       VARCHAR2 (100) := NULL;
      l_status                      VARCHAR2 (100) := NULL;
      l_dev_phase                   VARCHAR2 (100) := NULL;
      l_dev_status                  VARCHAR2 (100) := NULL;
      l_message                     VARCHAR2 (100) := NULL;
      l_count                       NUMBER := 0;
      l_req_status                  BOOLEAN;
      lc_error_msg                  VARCHAR2 (4000) := NULL;

      CURSOR c_err_msg (
         l_request NUMBER
      )
      IS
         SELECT error_message
           FROM po_interface_errors
          WHERE request_id = l_request;
   BEGIN
   
     -- To get the user_id/resp_is
     
      BEGIN
           SELECT fnd.user_id
           , fresp.responsibility_id
           , fresp.application_id
        INTO l_user_id
           , l_resp_id
           , l_resp_appl_id
        FROM fnd_user fnd
           , fnd_responsibility_tl fresp
       WHERE fnd.user_name = 'SVC_ESP_MER'
         AND fresp.responsibility_name = 'OD (US) PO Superuser';
         
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status    := 'E';
            x_return_message         := 'Error while getting the user_id/resp ID for PO ' || SQLERRM;
      END;
     

  
   
   
      l_reqimport_request_id    := 0;
      -- Initializing the environment
      fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id, l_org_id);
      
      -- Submit the REQIMPORT
      --DBMS_OUTPUT.put_line ('REQIMPORT - started');

      BEGIN
         l_reqimport_request_id    := fnd_request.submit_request ('PO'
                                                                     , 'REQIMPORT'
                                                                     , 'Requisition Import'
                                                                     , NULL
                                                                     , FALSE
                                                                     , 'Spares'
                                                                     , NULL
                                                                     , 'Vendor'
                                                                     , NULL
                                                                     , 'N'
                                                                     , 'Y'
                                                                     , CHR (0)
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                     , ''
                                                                      );
         --DBMS_OUTPUT.put_line ('started! Req ID ' || l_reqimport_request_id);
         l_dev_phase               := 'XX';
         COMMIT;

         WHILE NVL (l_dev_phase, 'XX') != 'COMPLETE'
         LOOP
            l_req_status    := fnd_concurrent.wait_for_request (l_reqimport_request_id, 10, 0, l_phase, l_status, l_dev_phase, l_dev_status, l_message);
            EXIT WHEN l_dev_phase = 'COMPLETE';
         END LOOP;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_message    := 'error while submitting the Requisition Import concurrent program';
            x_return_status     := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => NULL
                         ,                                                                                                                                            --p_sr_number,
                           p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchase_req'
                         , p_error_message_code      => 'XX_CS_SR39_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
      ----DBMS_OUTPUT.put_line('error while submitting the Requisition Import concurrent program :- '||SQLERRM);
      END;

      IF l_reqimport_request_id != 0
      THEN
         x_return_status     := fnd_api.g_ret_sts_success;
         x_return_message    := ' Requisition Import Succeded ' || l_reqimport_request_id || SQLERRM;

         SELECT COUNT (*)
           INTO l_count
           FROM po_interface_errors
          WHERE request_id = l_reqimport_request_id;

         IF l_count > 0
         THEN
            OPEN c_err_msg (l_reqimport_request_id);

            LOOP
               EXIT WHEN c_err_msg%NOTFOUND;

               FETCH c_err_msg
                INTO lc_error_msg;

               --DBMS_OUTPUT.put_line (lc_error_msg);
            END LOOP;

            CLOSE c_err_msg;

            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'Requisition Import Ran but errors occur' || lc_error_msg;
            log_exception (p_object_id               => NULL
                         ,                                                                                                                                            --p_sr_number,
                           p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchase_req'
                         , p_error_message_code      => 'XX_CS_SR40_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
         END IF;
      ELSE
         x_return_status     := fnd_api.g_ret_sts_error;
         x_return_message    := 'Requisition Import failed ' || l_reqimport_request_id || SQLERRM;
         log_exception (p_object_id               => NULL,                                                                                                           --p_sr_number,
                        p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchase_req', p_error_message_code => 'XX_CS_SR06_ERR_LOG', p_error_msg => x_return_message);
      END IF;
   END purchase_req;

-- +=============================================================================+
-- | PROCEDURE NAME : purchse_order                                               |
-- | DESCRIPTION    : Procedure to create PO based on requisition                 |
-- |                                                                             |
-- |                                                                             |
-- | Parameters  :  P_Sr_Number       IN            VARCHAR2    SR number        |
-- |   Returns   :  x_return_status   OUT NOCOPY    VARCHAR2    Return Code      |
-- |             :  x_return_message  OUT NOCOPY    VARCHAR2    Error buffer     |
-- +=============================================================================+
   PROCEDURE purchse_order (
      p_sr_number IN VARCHAR2
    , p_requirement_hdr_id IN NUMBER
    , p_parts_table IN xx_cs_tds_items_tbl_type
    , x_return_status IN OUT VARCHAR2
    , x_return_message IN OUT VARCHAR2
   )
   IS
      l_org_id                      po_requisition_headers_all.org_id%TYPE;
      l_vendor_id                   po_requisition_lines_all.vendor_id%TYPE;
      l_vendor_site_id              po_requisition_lines_all.vendor_site_id%TYPE;
      p_req_header_id               po_requisition_headers_all.requisition_header_id%TYPE;
      l_deliver_to_loc_id           po_requisition_lines_all.deliver_to_location_id%TYPE;
      l_term                        ap_terms.NAME%TYPE := NULL;
      l_store_id                    NUMBER := 0;
      l_dist_num                    po_req_distributions_all.distribution_num%TYPE;
      l_charge_acc                  VARCHAR2 (200) := NULL;
      l_charge_acc_id               NUMBER := 0;
      l_req_id                      NUMBER := 0;
      l_poimport_request_id         NUMBER := 0;
      l_phase                       VARCHAR2 (100);
      l_status                      VARCHAR2 (100);
      l_dev_phase                   VARCHAR2 (100);
      l_dev_status                  VARCHAR2 (100);
      l_message                     VARCHAR2 (4000);
      l_req_status                  BOOLEAN;
      l_req_dist_id                 NUMBER := 0;
      err                           VARCHAR2 (4000) := NULL;
      --remove when added to pkg
      l_resp_id             PLS_INTEGER ;--:= 50501;                                                                                                    -- Fnd_Global.Resp_Id;
      l_resp_appl_id        PLS_INTEGER ; -- := 201;                                                                                                  --Fnd_Global.Resp_Appl_Id;
      l_user_id                     VARCHAR2 (20); -- := 1197067;
      g_org_id                      NUMBER := 404;
      l_count                       NUMBER := 0;
      l_req_num                     VARCHAR2 (50) := NULL;                                                                                                --Added By Bala on 28-Jul

      -- To get the payment term for the vendor
      CURSOR c_terms (
         l_vendor_id po_requisition_lines_all.vendor_id%TYPE
      )
      IS
         SELECT NAME
           FROM ap_terms
          WHERE term_id = (SELECT terms_id
                             FROM po_vendors
                            WHERE vendor_id = l_vendor_id);

      -- To get the req line details
      CURSOR c_req_lines (
         l_req_header_id po_requisition_headers_all.requisition_header_id%TYPE
       , l_store_id NUMBER
      )
      IS
         SELECT prla.line_num
              , prla.line_type_id
              , prla.item_id
              , prla.category_id
              , prla.quantity
              , prla.unit_price
              , prla.destination_organization_id
              , prla.need_by_date
              , prla.deliver_to_location_id
              , msib.description
              , msib.primary_uom_code
              , prla.requisition_line_id
              , prla.destination_type_code
              , prla.requisition_header_id                                                                                                                -- added by bala on 27-Jul
           FROM po_requisition_lines_all prla
              , mtl_system_items_b msib
          WHERE prla.requisition_header_id = l_req_header_id
            AND msib.inventory_item_id = prla.item_id
            AND organization_id = l_store_id;

      c_req_line_rec                c_req_lines%ROWTYPE;

      CURSOR c_req_dist (
         l_req_line_id po_requisition_lines_all.requisition_line_id%TYPE
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
      
          
      
      
      -- To get the user_id/resp_id
     
      BEGIN
        SELECT fnd.user_id
           , fresp.responsibility_id
           , fresp.application_id
        INTO l_user_id
           , l_resp_id
           , l_resp_appl_id
        FROM fnd_user fnd
           , fnd_responsibility_tl fresp
       WHERE fnd.user_name = 'SVC_ESP_MER'
         AND fresp.responsibility_name = 'OD (US) PO Superuser';

      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status    := 'E';
            x_return_message         := 'Error while getting the user_id/resp ID for PO ' || SQLERRM;
      END;
     

      --- To get the requisition header id from SR number
      BEGIN
         SELECT requisition_header_id
              , segment1                                                                                                                                  -- Added By Bala on 28-Jul
           INTO p_req_header_id
              , l_req_num                                                                                                                                 -- Added By Bala on 28-Jul
           FROM po_requisition_headers_all
          WHERE attribute14 = p_sr_number;
      ----DBMS_OUTPUT.put_line('Requsition ID: ' || P_Req_Header_Id);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'Error While fetching the requisition header id';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR41_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
      END;

      -- p_req_header_id :=p_requirement_hdr_id;
      -- To get the store_id
      BEGIN
         SELECT store_id
           INTO l_store_id
           FROM xx_cs_tds_parts
          WHERE request_number = p_sr_number
            AND ROWNUM = 1;

         --DBMS_OUTPUT.put_line (' Store ID ' || l_store_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'Error While fetching the requisition store id';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR42_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
            --DBMS_OUTPUT.put_line (' Store ID not found');
      END;

      -- To find Org ID
      BEGIN
         SELECT org_id
           INTO l_org_id
           FROM po_requisition_headers_all
          WHERE requisition_header_id = p_req_header_id;

         --DBMS_OUTPUT.put_line (' Org ID ' || l_org_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'Error While fetching the org id';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR43_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
      ----DBMS_OUTPUT.put_line (' Org ID not found');
      END;

      -- To select  deliver_to_location
      BEGIN
         SELECT deliver_to_location_id
           INTO l_deliver_to_loc_id
           FROM po_requisition_lines_all
          WHERE requisition_header_id = p_req_header_id
            AND ROWNUM = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'Error While fetching the deliver to location id';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR44_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
      ----DBMS_OUTPUT.put_line ('  deliver to loc ID not found');
      END;

      -- To find vendor id and vendoe site id
      BEGIN
         SELECT vendor_id
              , vendor_site_id
           INTO l_vendor_id
              , l_vendor_site_id
           FROM po_vendor_sites_all
          WHERE vendor_id IN (SELECT vendor_id
                                FROM po_vendors
                               WHERE vendor_name LIKE 'NEXICORE SER%')
            AND vendor_site_code like  '%TDS%' --682916'; Added by Gaurav on 8/2.
            AND rownum =1 ;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'Error While fetching the vendor id and vendor site id';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR45_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
      ----DBMS_OUTPUT.put_line (' vendor  not found');
      END;

      -- To find term
      BEGIN
         OPEN c_terms (l_vendor_id);

         FETCH c_terms
          INTO l_term;

         CLOSE c_terms;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'Error While fetching the payment term details';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR46_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
            --DBMS_OUTPUT.put_line (' Terms not found');
      END;

      ----DBMS_OUTPUT.put_line (' Start Inserting into Headers');
      BEGIN
         INSERT INTO po_headers_interface
                     (interface_header_id
                    , batch_id
                    , process_code
                    , action
                    , org_id
                    , document_type_code
                    , document_num
                    , currency_code
                    , agent_id
                    , vendor_id
                    , vendor_site_id
                    --,Bill_To_Location
         ,            ship_to_location_id
                    , payment_terms
                    , freight_carrier
                    , approval_status
                    , comments
                    , attribute_category
                    , attribute1
                    , creation_date
                    , created_by
                    , last_update_date
                    , last_updated_by
                    , last_update_login
                     )
              VALUES (po_headers_interface_s.NEXTVAL
                    , po_headers_interface_s.CURRVAL
                    , NULL                                                                                                                                                  --'OPEN'
                    , 'ORIGINAL'
                    , l_org_id
                    , 'STANDARD'
                    , p_sr_number
                    , 'USD'
                    , g_buyer_id
                    , l_vendor_id
                    , l_vendor_site_id
                    --,l_deliver_to_loc_id
         ,            l_deliver_to_loc_id
                    , l_term
                    , 'OD_GUIDE'
                    , 'APPROVED'
                    , 'TDS Parts PO for Service Request # '
                    , 'Trade'
                    , 'NA-TDSPARTS'                                                                                                                                      --Raj added
                    , SYSDATE
                    , fnd_profile.VALUE ('USER_ID')
                    , SYSDATE
                    , fnd_profile.VALUE ('USER_ID')
                    , fnd_profile.VALUE ('USER_ID')
                     );
        EXCEPTION
            WHEN OTHERS
            THEN
         x_return_status     := fnd_api.g_ret_sts_error;
         x_return_message    := 'Error While inserting the data into po_headers_interface table';
         log_exception (p_object_id               => p_sr_number
                      , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                      , p_error_message_code      => 'XX_CS_SR47_ERR_LOG'
                      , p_error_msg               => x_return_message
                       );
      END;

      --  To insert into PO_lines_interface
      BEGIN
         OPEN c_req_lines (p_req_header_id, l_store_id);

         LOOP
            FETCH c_req_lines
             INTO c_req_line_rec;

            EXIT WHEN c_req_lines%NOTFOUND;

            ----DBMS_OUTPUT.put_line ('Item' || c_req_line_rec.item_id);
            ----DBMS_OUTPUT.put_line (' Start Inserting into lines');
            ----DBMS_OUTPUT.put_line (' c_req_line_rec.requisition_line_id   : ' || c_req_line_rec.requisition_line_id) ;
            --END;
            --BEGIN
            INSERT INTO po_lines_interface
                        (interface_header_id
                       , interface_line_id
                       , action
                       , line_num
                       , shipment_num
                       , line_type_id
                       , item_id
                       , category_id
                       , item_description
                       , uom_code                                                                                                                              --Derive From Item_Id
                       , quantity
                       , unit_price
                       , receiving_routing_id
                       , qty_rcv_tolerance
                       , ship_to_organization_id
                       , need_by_date
                       , promised_date
                       , accrue_on_receipt_flag
                       , fob
                       , last_update_date
                       , last_updated_by
                       , last_update_login
                       , created_by
                       , creation_date
                       , requisition_line_id
                       , from_header_id                                                                                                                   -- added By Bala on 27-Jul
                       , from_line_id                                                                                                                     -- added by bala on 27-Jul
                        )
                 VALUES (po_headers_interface_s.CURRVAL
                       , po_lines_interface_s.NEXTVAL
                       , 'ORIGINAL'
                       , c_req_line_rec.line_num
                       , 1
                       , c_req_line_rec.line_type_id
                       , c_req_line_rec.item_id
                       , c_req_line_rec.category_id
                       , c_req_line_rec.description
                       , c_req_line_rec.primary_uom_code
                       , c_req_line_rec.quantity
                       , c_req_line_rec.unit_price
                       , 3
                       , 0
                       , c_req_line_rec.destination_organization_id
                       , c_req_line_rec.need_by_date
                       , c_req_line_rec.need_by_date
                       , 'Y'
                       , 'SHIPPING'
                       , SYSDATE
                       , fnd_profile.VALUE ('USER_ID')
                       , fnd_profile.VALUE ('USER_ID')
                       , fnd_profile.VALUE ('USER_ID')
                       , SYSDATE
                       , c_req_line_rec.requisition_line_id                                                                                               -- added by gaurav on 6/26
                       , c_req_line_rec.requisition_header_id                                                                                             -- added by bala on 27-Jul
                       , c_req_line_rec.requisition_line_id                                                                                                --added by bala on 27-Jul
                        );

            --DBMS_OUTPUT.put_line (' Inserted into liness');

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
               SELECT segment1 || '.' || segment2 || '.' || fnd_profile.VALUE ('XX_TDS_PARTS_MAT_ACCOUNT') || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.'
                      || segment7
                 INTO l_charge_acc
                 FROM gl_code_combinations
                WHERE code_combination_id = (SELECT material_account
                                               FROM mtl_parameters
                                              WHERE organization_id = c_req_line_rec.destination_organization_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_return_status     := fnd_api.g_ret_sts_error;
                  x_return_message    := 'Error While fetching the charge account code combination';
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                               , p_error_message_code      => 'XX_CS_SR48_ERR_LOG'
                               , p_error_msg               => x_return_message
                                );
            ----DBMS_OUTPUT.put_line (' Charge acc not found');
            END;

            --DBMS_OUTPUT.put_line ('Charge Acc -' || l_charge_acc);

            BEGIN
               l_charge_acc_id    := fnd_flex_ext.get_ccid ('SQLGL', 'GL#', 50310, TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS')
                                                                                                                             --OD_GLOBAL_COA
                                                            , l_charge_acc);
               ----DBMS_OUTPUT.put_line ('charge_acc' || l_charge_acc_id);
               err                := fnd_flex_ext.GET_MESSAGE;
            ----DBMS_OUTPUT.put_line (err);
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_return_status     := fnd_api.g_ret_sts_error;
                  x_return_message    := 'Error While getting the charge account from fnd_flex_ext.get_ccid';
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                               , p_error_message_code      => 'XX_CS_SR49_ERR_LOG'
                               , p_error_msg               => x_return_message
                                );
            END;

            OPEN c_req_dist (c_req_line_rec.requisition_line_id);

            FETCH c_req_dist
             INTO l_dist_num;

            CLOSE c_req_dist;

            BEGIN
               SELECT distribution_id
                 INTO l_req_dist_id
                 FROM po_req_distributions_all
                WHERE requisition_line_id = c_req_line_rec.requisition_line_id;
            ----DBMS_OUTPUT.put_line('Requisition Distribution id :- '||l_req_dist_id);
            EXCEPTION
               WHEN OTHERS
               THEN
                  ----DBMS_OUTPUT.put_line('Exception Requisition Distribution id :- '||SQLERRM);
                  x_return_status     := fnd_api.g_ret_sts_error;
                  x_return_message    := 'Error While fetching the distribution id from po_req_distributions_all table';
                  log_exception (p_object_id               => p_sr_number
                               , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                               , p_error_message_code      => 'XX_CS_SR50_ERR_LOG'
                               , p_error_msg               => x_return_message
                                );
            END;

            ----DBMS_OUTPUT.put_line (' Start Inserting into distribution');
            --BEGIN
            INSERT INTO po_distributions_interface
                        (interface_header_id
                       , interface_line_id
                       , interface_distribution_id
                       , distribution_num
                       , quantity_ordered
                       , deliver_to_location_id
                       , destination_type_code
                       , destination_organization_id
                       , destination_subinventory
                       , charge_account_id
                       , accrual_account_id                                                                                                                       -- added by gaurav
                       , creation_date
                       , created_by
                       , last_update_date
                       , last_updated_by
                       , req_distribution_id
                       , source_distribution_id
                       , req_header_reference_num                                                                                                         -- Added By Bala on 28-Jul
                       , req_line_reference_num                                                                                                           -- Added By Bala on 28-Jul
                        )
                 VALUES (po_headers_interface_s.CURRVAL
                       , po_lines_interface_s.CURRVAL
                       , po_distributions_interface_s.NEXTVAL
                       , l_dist_num
                       , c_req_line_rec.quantity
                       , c_req_line_rec.deliver_to_location_id
                       , 'INVENTORY'
                       , c_req_line_rec.destination_organization_id
                       , 'STOCK'
                       , l_charge_acc_id
                       , g_accrual_account_id
                       , SYSDATE
                       , fnd_profile.VALUE ('USER_ID')
                       , SYSDATE
                       , fnd_profile.VALUE ('USER_ID')
                       , l_req_dist_id
                       , l_req_dist_id
                       , l_req_num                                                                                                                        -- Added By Bala on 28-Jul
                       , c_req_line_rec.line_num                                                                                                          -- Added By Bala on 28-Jul
                        );
         ----DBMS_OUTPUT.put_line(' Inserted into distribution' );
         END LOOP;

         CLOSE c_req_lines;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := 'Error While inserting the data into po_distributions_interface table';
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR51_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
      END;

      COMMIT;
      -- Call PO Import API
      fnd_global.apps_initialize (l_user_id, l_resp_id, l_resp_appl_id, l_org_id);
       --fnd_global.apps_initialize (l_user_id, l_resp_id,  l_org_id);
      ----DBMS_OUTPUT.put_line('started Import PO');
      l_poimport_request_id    := fnd_request.submit_request (application      => 'PO'                                                                           --Application,
                                                                 , program          => 'POXPOPDOI'                                                                        --Program,
                                                                 , argument1        => ''                                                                                --Buyer ID,
                                                                 , argument2        => 'STANDARD'                                                                   --Document Type,
                                                                 , argument3        => ''                                                                        --Document Subtype,
                                                                 , argument4        => 'N'                                                                     --Process Items Flag,
                                                                 , argument5        => 'N'                                                                   --Create Sourcing rule,
                                                                 , argument6        => ''                                                                         --Approval Status,
                                                                 , argument7        => ''                                                               --Release Generation Method,
                                                                 , argument8        => ''                                                                                    --NULL,
                                                                 , argument9        => g_org_id                                                                 --Operating Unit ID,
                                                                 , argument10       => ''                                                                         --Global Agreement
                                                                  );
      ----DBMS_OUTPUT.put_line ('completed - Req ID :' || l_poimport_request_id);
      COMMIT;
      l_dev_phase              := 'XX';

      WHILE NVL (l_dev_phase, 'XX') != 'COMPLETE'
      LOOP
         l_req_status    := fnd_concurrent.wait_for_request (l_poimport_request_id, 10, 0, l_phase, l_status, l_dev_phase, l_dev_status, l_message);
         EXIT WHEN l_dev_phase = 'COMPLETE';
      END LOOP;

      COMMIT;

      BEGIN
         IF l_poimport_request_id != 0
         THEN
            x_return_status     := fnd_api.g_ret_sts_success;
            x_return_message    := 'PO Import Succeded ' || l_poimport_request_id || SQLERRM;
            -- Raj added 7/30 for sending PO message to Vendor
            xx_cs_tds_parts_ven_pkg.part_outbound (p_incident_number      => p_sr_number
                                                 , p_incident_id          => NULL
                                                 , p_doc_type             => 'PO'
                                                 , p_doc_number           => p_sr_number
                                                 , x_return_status        => x_return_status
                                                 , x_return_msg           => x_return_message
                                                  );
                                                  
                                                  
                Begin
                   delete from xx_cs_tds_parts_quotes
                   where request_number = p_sr_number;   
                 exception
                  when others then
                      x_return_message   := 'Error while removing quote from xx_cs_tds_parts_quotes ' || SQLERRM;
                       log_exception (p_object_id => p_sr_number, 
                                      p_error_location => 'XX_CS_TDS_PARTS_PKG.purchse_order', 
                                      p_error_message_code => 'XX_CS_SR52a_ERR_LOG', 
                                      p_error_msg => x_return_message);
                END;                           

            SELECT COUNT (*)
              INTO l_count
              FROM po_interface_errors
             WHERE request_id = l_poimport_request_id;

            IF l_count > 0
            THEN
               x_return_status     := fnd_api.g_ret_sts_error;
               x_return_message    := ' POImport Ran but errors occur. Check the PO error table for errors';
               log_exception (p_object_id               => p_sr_number
                            , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                            , p_error_message_code      => 'XX_CS_SR52_ERR_LOG'
                            , p_error_msg               => x_return_message
                             );
            END IF;
         ELSE
            x_return_status     := fnd_api.g_ret_sts_error;
            x_return_message    := ' PO Import failed ' || l_poimport_request_id || SQLERRM;
            log_exception (p_object_id               => p_sr_number
                         , p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchse_order'
                         , p_error_message_code      => 'XX_CS_SR53_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_message    := 'error while submitting the PO Import concurrent program';
            x_return_status     := fnd_api.g_ret_sts_error;
            log_exception (p_object_id               => NULL
                         ,                                                                                                                                            --p_sr_number,
                           p_error_location          => 'XX_CS_TDS_PARTS_PKG.purchase_req'
                         , p_error_message_code      => 'XX_CS_SR54_ERR_LOG'
                         , p_error_msg               => x_return_message
                          );
      ----DBMS_OUTPUT.put_line('error while submitting the PO Import concurrent program :- '||SQLERRM);
      END;
   END purchse_order;
END xx_cs_tds_parts_pkg;
/
show errors;
exit;