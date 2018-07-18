create or replace
PACKAGE BODY xx_cs_tds_parts_jda_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : XX_CS_TDS_PARTS_JDA_PKG.pkb                                        |
-- | Description: Wrapper package to get the data from xx_cs_tds_parts table         |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |1.0       13-JUL-2011  Jagadeesh S        Creation                               |
-- |1.1       21-OCT-2011  Raj                Add SR verification from CS            |
-- |1.2       22-JAN-2012  Vasu Raparla       Removed schema References for R.12.2   | 
---+=================================================================================+
   PROCEDURE main_proc (
      P_Sr_Number        In       Varchar2,
      p_parts_tbl        OUT      apps.xx_cs_tds_parts_order_tbl,
      x_return_status    OUT      VARCHAR2,
      x_return_message   OUT      VARCHAR2
   )
   IS
      CURSOR item_cur
      IS
         SELECT rms_sku rms_sku,
                item_number || ':' || item_description item_desc, 
                (nvl(tot_received_qty,quantity) - nvl(excess_quantity,0)) qty,
                uom, NVL (exchange_price, purchase_price) COST,
                selling_price
           FROM xx_cs_tds_parts
          WHERE request_number = p_sr_number
          and nvl(sales_flag,'N') = 'Y';

      l_user_id           NUMBER;
      l_index             NUMBER := 0;
      L_Value             Varchar2 (1);
      lc_resolution_code  varchar2(100);
      lc_incident_number  varchar2(50);
      l_parts_tbl   xx_cs_tds_parts_order_tbl := apps.xx_cs_tds_parts_order_tbl();
      
   Begin          
      
      SELECT user_id
        INTO l_user_id
        FROM fnd_user
       Where User_Name = G_User_Name;
             
      -- Check the SR Number
      BEGIN 
         SELECT incident_number, resolution_code
         INTO   lc_incident_number, lc_resolution_code
         FROM   xx_cs_tds_parts xc,
               cs_incidents_all_b cb
        Where  cb.incident_number = xc.request_number
        AND    xc.Request_Number = p_sr_number
        AND    nvl(sales_flag,'N') = 'Y'
        AND    ROWNUM=1;
        
       X_Return_Status := Fnd_Api.G_Ret_Sts_Success;
  
      EXCEPTION
        WHEN OTHERS THEN
          x_return_Status := Fnd_Api.G_Ret_Sts_Error;
          x_return_message := 'Work Order Information Not Found';
          xx_com_error_log_pub.log_error
                    (p_return_code                 => fnd_api.g_ret_sts_error,
                     p_msg_count                   => 1,
                     p_application_name            => 'XX_CRM',
                     p_program_type                => 'Custom Messages',
                     p_program_name                => 'XX_CS_TDS_PARTS_JDA_PKG',
                     p_object_id                   => p_sr_number,
                     p_module_name                 => 'CSF',
                     p_error_location              => 'XX_CS_TDS_PARTS_JDA_PKG.MAIN_PROC',
                     p_error_message_code          => 'XX_CS_SR01_ERR_LOG',
                     p_error_message               => 'Exception in main proc',
                     p_error_message_severity      => 'MAJOR',
                     p_error_status                => 'ACTIVE',
                     p_created_by                  => l_user_id,
                     P_Last_Updated_By             => L_User_Id,
                     p_last_update_login           => g_login_id
                    );
      END;   

     IF LC_INCIDENT_NUMBER IS NULL THEN
          x_return_Status := Fnd_Api.G_Ret_Sts_Error;
          x_return_message := 'Invalid Order Number';
     ELSIF LC_RESOLUTION_CODE IS NOT NULL THEN
          x_return_Status := Fnd_Api.G_Ret_Sts_Error;
          x_return_message := 'Order already processed.. ';
     END IF;
     
     -- Raj commented out on 10/21
      -- Check payment received or not.
     /*  BEGIN
        SELECT 'Y'
        INTO   l_value
        FROM   cs_incidents_all_b
        where incident_number = p_sr_number
        and   incident_status_id <> 2
        and   resolution_code is null;  
        
        X_Return_Status := Fnd_Api.G_Ret_Sts_Success;
  
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          x_return_Status := Fnd_Api.G_Ret_Sts_Error;
          x_return_message := 'Order already processed.. ';
          xx_com_error_log_pub.log_error
                    (p_return_code                 => fnd_api.g_ret_sts_error,
                     p_msg_count                   => 1,
                     p_application_name            => 'XX_CRM',
                     p_program_type                => 'Custom Messages',
                     p_program_name                => 'XX_CS_TDS_PARTS_JDA_PKG',
                     p_object_id                   => p_sr_number,
                     p_module_name                 => 'CSF',
                     p_error_location              => 'XX_CS_TDS_PARTS_JDA_PKG.MAIN_PROC',
                     p_error_message_code          => 'XX_CS_SR01_ERR_LOG',
                     p_error_message               => 'Exception in main proc',
                     p_error_message_severity      => 'MAJOR',
                     p_error_status                => 'ACTIVE',
                     p_created_by                  => l_user_id,
                     P_Last_Updated_By             => L_User_Id,
                     p_last_update_login           => g_login_id
                    );
      END;   */
      
     IF x_return_Status = Fnd_Api.G_Ret_Sts_Success
     Then
       FOR r_item_cur IN item_cur
       Loop 
         IF r_item_cur.qty > 0 THEN
           L_Parts_Tbl.Extend(1);  
           L_Index := L_Index + 1;
           l_parts_tbl (l_index) := apps.xx_cs_tds_order_items_rec(NULL, NULL, NULL, NULL, NULL, NULL);       
           l_parts_tbl (l_index).rms_sku := r_item_cur.rms_sku;
           l_parts_tbl (l_index).item_description := r_item_cur.item_desc;
           l_parts_tbl (l_index).quantity := r_item_cur.qty;
           l_parts_tbl (l_index).uom := r_item_cur.uom;
           l_parts_tbl (l_index).purchase_price := r_item_cur.COST;
           l_parts_tbl (l_index).selling_price := r_item_cur.selling_price;
         END IF;
        END LOOP;
   
        X_Return_Status := Fnd_Api.G_Ret_Sts_Success;
       p_parts_tbl := l_parts_tbl;
      END IF;  -- Payment validation

   EXCEPTION
      WHEN OTHERS
      THEN
         X_Return_Status := Fnd_Api.G_Ret_Sts_Error;
         x_return_message := 'Exception in main proc '||SQLERRM;
         xx_com_error_log_pub.log_error
                    (p_return_code                 => fnd_api.g_ret_sts_error,
                     p_msg_count                   => 1,
                     p_application_name            => 'XX_CRM',
                     p_program_type                => 'Custom Messages',
                     p_program_name                => 'XX_CS_TDS_PARTS_JDA_PKG',
                     p_object_id                   => p_sr_number,
                     p_module_name                 => 'CSF',
                     p_error_location              => 'XX_CS_TDS_PARTS_JDA_PKG.MAIN_PROC',
                     p_error_message_code          => 'XX_CS_SR01_ERR_LOG',
                     p_error_message               => 'Exception in main proc',
                     p_error_message_severity      => 'MAJOR',
                     p_error_status                => 'ACTIVE',
                     p_created_by                  => l_user_id,
                     p_last_updated_by             => l_user_id,
                     p_last_update_login           => g_login_id
                    );
   End Main_Proc;
END xx_cs_tds_parts_jda_pkg;

/
show errors;
exit;