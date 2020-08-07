SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_MTL_INTERORG_PARAMETERS_PKG
--Version 1.0
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- +=============================================================================+
-- |Package Name : XX_MTL_INTERORG_PARAMETERS_PKG                                |
-- |Purpose      : This package contains a procedure that actually inserts the   |
-- |                shipping networks information that is passed as parameters   |
-- |                into mtl_interorg_parameters table.                          |
-- |                                                                             |
-- |Tables Accessed :                                                            |
-- |Access Type----------------- (I - Insert, S - Select, U - Update, D - Delete)|
-- |                                                                             |
-- |MTL_INTERORG_PARAMETERS     : I                                              |
-- |                                                                             |
-- |Change History                                                               |
-- |                                                                             |
-- |Ver      Date          Author           Description                          |
-- |---      -----------   ---------------  -----------------------------        |
-- |Draft1A  09-Sep-2007   Arun Andavar     Initial version                      |
-- |1.0      18-Sep-2007   Vikas Raina      Reviewed and updated                 |
-- +=============================================================================+
IS
   PROCEDURE INSERT_ROW(
                        X_Rowid                          IN OUT NOCOPY VARCHAR2
                       ,X_Err_msg                        OUT VARCHAR2
                       ,X_From_organization_id           NUMBER
                       ,X_To_organization_id             NUMBER
                       ,X_Last_update_date               DATE 
                       ,X_Last_updated_by                NUMBER
                       ,X_Creation_date                  DATE 
                       ,X_Created_by                     NUMBER
                       ,X_Last_update_login              NUMBER
                       ,X_Intransit_type                 NUMBER
                       ,X_Distance_uom_code              VARCHAR
                       ,X_To_organization_distance       NUMBER
                       ,X_Fob_point                      NUMBER
                       ,X_Matl_interorg_transfer_code    NUMBER
                       ,X_Routing_header_id              NUMBER
                       ,X_Internal_order_required_flag   NUMBER
                       ,X_Intransit_inv_account          NUMBER
                       ,X_Interorg_trnsfr_chrge_percnt   NUMBER
                       ,X_Interorg_transfer_cr_account   NUMBER
                       ,X_Interorg_receivables_account   NUMBER
                       ,X_Interorg_payables_account      NUMBER
                       ,X_Interorg_price_var_account     NUMBER
                       ,X_Attribute_category             VARCHAR
                       ,X_Attribute1                     VARCHAR
                       ,X_Attribute2                     VARCHAR
                       ,X_Attribute3                     VARCHAR
                       ,X_Attribute4                     VARCHAR
                       ,X_Attribute5                     VARCHAR
                       ,X_Attribute6                     VARCHAR
                       ,X_Attribute7                     VARCHAR
                       ,X_Attribute8                     VARCHAR
                       ,X_Attribute9                     VARCHAR
                       ,X_Attribute10                    VARCHAR
                       ,X_Attribute11                    VARCHAR
                       ,X_Attribute12                    VARCHAR
                       ,X_Attribute13                    VARCHAR
                       ,X_Attribute14                    VARCHAR
                       ,X_Attribute15                    VARCHAR
                       ,X_Global_attribute_category      VARCHAR
                       ,X_Global_attribute1              VARCHAR
                       ,X_Global_attribute2              VARCHAR
                       ,X_Global_attribute3              VARCHAR
                       ,X_Global_attribute4              VARCHAR
                       ,X_Global_attribute5              VARCHAR
                       ,X_Global_attribute6              VARCHAR
                       ,X_Global_attribute7              VARCHAR
                       ,X_Global_attribute8              VARCHAR
                       ,X_Global_attribute9              VARCHAR
                       ,X_Global_attribute10             VARCHAR
                       ,X_Global_attribute11             VARCHAR
                       ,X_Global_attribute12             VARCHAR
                       ,X_Global_attribute13             VARCHAR
                       ,X_Global_attribute14             VARCHAR
                       ,X_Global_attribute15             VARCHAR
                       ,X_Global_attribute16             VARCHAR
                       ,X_Global_attribute17             VARCHAR
                       ,X_Global_attribute18             VARCHAR
                       ,X_Global_attribute19             VARCHAR
                       ,X_Global_attribute20             VARCHAR
                       ,X_Elemental_visibility_enabled   VARCHAR
                       ,X_Manual_receipt_expense         VARCHAR
                       ,X_Profit_in_inv_account          NUMBER
                       )
   IS
      lc_err_msg VARCHAR2(1000) := NULL;
   BEGIN

      INSERT INTO MTL_INTERORG_PARAMETERS
            (
             FROM_ORGANIZATION_ID
            ,TO_ORGANIZATION_ID
            ,LAST_UPDATE_DATE
            ,LAST_UPDATED_BY
            ,CREATION_DATE
            ,CREATED_BY
            ,LAST_UPDATE_LOGIN
            ,INTRANSIT_TYPE
            ,DISTANCE_UOM_CODE
            ,TO_ORGANIZATION_DISTANCE
            ,FOB_POINT
            ,MATL_INTERORG_TRANSFER_CODE
            ,ROUTING_HEADER_ID
            ,INTERNAL_ORDER_REQUIRED_FLAG
            ,INTRANSIT_INV_ACCOUNT
            ,INTERORG_TRNSFR_CHARGE_PERCENT
            ,INTERORG_TRANSFER_CR_ACCOUNT
            ,INTERORG_RECEIVABLES_ACCOUNT
            ,INTERORG_PAYABLES_ACCOUNT
            ,INTERORG_PRICE_VAR_ACCOUNT
            ,ATTRIBUTE_CATEGORY
            ,ATTRIBUTE1
            ,ATTRIBUTE2
            ,ATTRIBUTE3
            ,ATTRIBUTE4
            ,ATTRIBUTE5
            ,ATTRIBUTE6
            ,ATTRIBUTE7
            ,ATTRIBUTE8
            ,ATTRIBUTE9
            ,ATTRIBUTE10
            ,ATTRIBUTE11
            ,ATTRIBUTE12
            ,ATTRIBUTE13
            ,ATTRIBUTE14
            ,ATTRIBUTE15
            ,GLOBAL_ATTRIBUTE_CATEGORY
            ,GLOBAL_ATTRIBUTE1
            ,GLOBAL_ATTRIBUTE2
            ,GLOBAL_ATTRIBUTE3
            ,GLOBAL_ATTRIBUTE4
            ,GLOBAL_ATTRIBUTE5
            ,GLOBAL_ATTRIBUTE6
            ,GLOBAL_ATTRIBUTE7
            ,GLOBAL_ATTRIBUTE8
            ,GLOBAL_ATTRIBUTE9
            ,GLOBAL_ATTRIBUTE10
            ,GLOBAL_ATTRIBUTE11
            ,GLOBAL_ATTRIBUTE12
            ,GLOBAL_ATTRIBUTE13
            ,GLOBAL_ATTRIBUTE14
            ,GLOBAL_ATTRIBUTE15
            ,GLOBAL_ATTRIBUTE16
            ,GLOBAL_ATTRIBUTE17
            ,GLOBAL_ATTRIBUTE18
            ,GLOBAL_ATTRIBUTE19
            ,GLOBAL_ATTRIBUTE20
            ,ELEMENTAL_VISIBILITY_ENABLED
            ,MANUAL_RECEIPT_EXPENSE
            ,PROFIT_IN_INV_ACCOUNT
            )
            VALUES 
            (
             X_From_organization_id         
            ,X_To_organization_id           
            ,X_Last_update_date             
            ,X_Last_updated_by              
            ,X_Creation_date                
            ,X_Created_by                   
            ,X_Last_update_login            
            ,X_Intransit_type               
            ,X_Distance_uom_code            
            ,X_To_organization_distance     
            ,X_Fob_point                    
            ,X_Matl_interorg_transfer_code  
            ,X_Routing_header_id            
            ,X_Internal_order_required_flag 
            ,X_Intransit_inv_account        
            ,X_Interorg_trnsfr_chrge_percnt
            ,X_Interorg_transfer_cr_account 
            ,X_Interorg_receivables_account 
            ,X_Interorg_payables_account    
            ,X_Interorg_price_var_account   
            ,X_Attribute_category           
            ,X_Attribute1                   
            ,X_Attribute2                   
            ,X_Attribute3                   
            ,X_Attribute4                   
            ,X_Attribute5                   
            ,X_Attribute6                   
            ,X_Attribute7                   
            ,X_Attribute8                   
            ,X_Attribute9                   
            ,X_Attribute10                  
            ,X_Attribute11                  
            ,X_Attribute12                  
            ,X_Attribute13                  
            ,X_Attribute14                  
            ,X_Attribute15                  
            ,X_Global_attribute_category    
            ,X_Global_attribute1            
            ,X_Global_attribute2            
            ,X_Global_attribute3            
            ,X_Global_attribute4            
            ,X_Global_attribute5            
            ,X_Global_attribute6            
            ,X_Global_attribute7            
            ,X_Global_attribute8            
            ,X_Global_attribute9            
            ,X_Global_attribute10           
            ,X_Global_attribute11           
            ,X_Global_attribute12           
            ,X_Global_attribute13           
            ,X_Global_attribute14           
            ,X_Global_attribute15           
            ,X_Global_attribute16           
            ,X_Global_attribute17           
            ,X_Global_attribute18           
            ,X_Global_attribute19           
            ,X_Global_attribute20           
            ,X_Elemental_visibility_enabled 
            ,X_Manual_receipt_expense       
            ,X_Profit_in_inv_account        
            )
            RETURNING ROWID INTO X_Rowid
            ;

   EXCEPTION
      WHEN OTHERS THEN
         FND_MESSAGE.SET_NAME('XXPTP','XX_INV_62502_UNEXPECTED_ERR');
         FND_MESSAGE.SET_TOKEN('PROC','XX_MTL_INTERORG_PARAMETERS_PKG.INSERT_ROW');
         FND_MESSAGE.SET_TOKEN('ERR',SQLERRM);
         lc_err_msg := FND_MESSAGE.GET;
         
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_err_msg);

         dbms_output.put_line(lc_err_msg);

         ROLLBACK;

         XX_COM_ERROR_LOG_PUB.LOG_ERROR 
                           (
                            p_program_type            => 'CUSTOM API'                     --IN VARCHAR2  DEFAULT NULL
                           ,p_program_name            => 'XX_MTL_INTERORG_PARAMETERS_PKG' --IN VARCHAR2  DEFAULT NULL
                           ,p_module_name             => 'INV'                            --IN VARCHAR2  DEFAULT NULL
                           ,p_error_location          => 'OTHERS'                         --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_code      => -1                               --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message           => lc_err_msg                       --IN VARCHAR2  DEFAULT NULL
                           ,p_error_message_severity  => 'MAJOR'                          --IN VARCHAR2  DEFAULT NULL
                           ,p_notify_flag             => 'Y'                              --IN VARHCAR2  DEFAULT NULL
                           );
   END INSERT_ROW;
   
END XX_MTL_INTERORG_PARAMETERS_PKG;
/
EXIT