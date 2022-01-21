SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE XX_MTL_INTERORG_PARAMETERS_PKG AUTHID CURRENT_USER
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
                       );
   
END XX_MTL_INTERORG_PARAMETERS_PKG;
/
EXIT