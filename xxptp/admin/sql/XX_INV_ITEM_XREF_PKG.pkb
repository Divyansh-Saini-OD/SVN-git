SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_ITEM_XREF_PKG
-- +======================================================================+
-- |                  Office Depot - Project Simplify                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization          |
-- +======================================================================+
-- | Name        :  XX_INV_ITEM_XREF_PKG.pkb                              |
-- | Description :  To create/update/delete Item/product/Wholesaler cross |
-- |                reference values in EBS                               |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date        Author           Remarks                        |
-- |=======   ==========  =============    ===============================|
-- |Draft 1a  11-Apr-2007 Madhukar Salunke Initial draft version          |
-- |Draft 1b  18-May-2007 Madhukar Salunke Incorporated as per latest MD70|
-- |Draft 1c  11-Jun-2007 Madhukar Salunke Incorporated peer review comments|
-- |Draft 1d  12-JUN-2007 Jayshree kale    Reviewed and Updated           | 
-- |Draft 1e  14-JUN-2007 Jayshree kale    Updated as per onsite comments | 
-- |Draft 1f  16-JUN-2007 Madhukar Salunke Updated as per onsite comments | 
-- |Draft 1g  21-JUN-2007 Madhukar Salunke Modified for addition of WHLS  | 
-- |                                       description and Action as C/D  | 
-- |Draft 1h  09-JUL-2007 Madhukar Salunke Added LOG_ERROR procedure for  |
-- |                                       EBS Error Handling             | 
-- |1.0       10-JUL-2007 Madhukar Salunke Baseline                        |
-- |1.1       21-Aug-2007 Paddy Sanjeevi   Modified for performance       | 
-- |1.2       29-Aug-2007 Paddy Sanjeevi   Modified vendor validation     |
-- |1.3       18-Sep-2013 Sheetal S        I0148 - R12 Upgrade Retrofit Changes.    |
-- |                                       Changed to use API.            |
-- +======================================================================+

IS

--+=======================================================================+
--| PROCEDURE  : Process_item_xref                                        |
--| p_xref_object          IN    VARCHAR2                                 |
--| p_item                 IN    VARCHAR2                                 |
--| p_action               IN    VARCHAR2                                 |
--| p_xref_item            IN    VARCHAR2                                 |
--| p_xref_type            IN    VARCHAR2                                 |
--| p_prodmultiplier       IN    NUMBER                                   |
--| p_prodmultdivcd        IN    VARCHAR2                                 |
--| p_prdxrefdesc          IN    VARCHAR2                                 |
--| p_whslrsupplier        IN    NUMBER                                   |
--| p_whslrmultiplier      IN    NUMBER                                   |
--| p_whslrmultdivcd       IN    VARCHAR2                                 |
--| p_whslrretailprice     IN    NUMBER                                   |
--| p_whslruomcd           IN    VARCHAR2                                 |
--| p_whslrprodcategory    IN    VARCHAR2                                 |
--| p_whslrgencatpgnbr     IN    NUMBER                                   |
--| p_whslrfurcatpgnbr     IN    NUMBER                                   |
--| p_whslrnnpgnbr         IN    NUMBER                                   |
--| p_whslrprgeligflg      IN    VARCHAR2                                 |
--| p_whslrbranchflg       IN    VARCHAR2                                 |
--| x_message_code         OUT   NUMBER                                   |
--| x_message_data         OUT   VARCHAR2                                 |
--+=======================================================================+

PROCEDURE Process_item_xref  (
            p_xref_object          IN    VARCHAR2,
            p_item                 IN    VARCHAR2,
            p_action               IN    VARCHAR2,
            p_xref_item            IN    VARCHAR2,
            p_xref_type            IN    VARCHAR2,
            p_prodmultiplier       IN    NUMBER,
            p_prodmultdivcd        IN    VARCHAR2,
            p_prdxrefdesc          IN    VARCHAR2,
            p_whslrsupplier        IN    NUMBER,
            p_whslrmultiplier      IN    NUMBER,
            p_whslrmultdivcd       IN    VARCHAR2,
            p_whslrretailprice     IN    NUMBER,
            p_whslruomcd           IN    VARCHAR2,
            p_whslrprodcategory    IN    VARCHAR2,
            p_whslrgencatpgnbr     IN    NUMBER,
            p_whslrfurcatpgnbr     IN    NUMBER,
            p_whslrnnpgnbr         IN    NUMBER,
            p_whslrprgeligflg      IN    VARCHAR2,
            p_whslrbranchflg       IN    VARCHAR2,
            x_message_code         OUT   NUMBER,
            x_message_data         OUT   VARCHAR2
            )
IS
  
   ln_exists_item            NUMBER := 0;
   ln_vendor_exists          NUMBER := 0;
   ln_xrefobj_exists         NUMBER := 0;
   ln_xref_type_exists       NUMBER := 0;
   ln_inventory_item_id      NUMBER := NULL;
   ln_inventory_item_mcr     NUMBER := NULL;
   ln_supplier             VARCHAR2(10);
   lc_rowid                  ROWID;
   lc_transaction_type      VARCHAR2(30) := NULL;
   lc_lookup_code            fnd_lookup_values.lookup_code%TYPE            := NULL;
   lc_description            mtl_system_items_b.description%TYPE           := NULL;
   lc_attribute_category     mtl_cross_references.attribute_category%TYPE  := NULL;
   lc_attribute1             mtl_cross_references.attribute1%TYPE          := NULL;
   lc_attribute2             mtl_cross_references.attribute2%TYPE          := NULL;
   lc_attribute3             mtl_cross_references.attribute3%TYPE          := NULL;
   lc_attribute4             mtl_cross_references.attribute4%TYPE          := NULL;
   lc_attribute5             mtl_cross_references.attribute5%TYPE          := NULL;
   lc_attribute6             mtl_cross_references.attribute6%TYPE          := NULL;
   lc_attribute7             mtl_cross_references.attribute7%TYPE          := NULL;
   lc_attribute8             mtl_cross_references.attribute8%TYPE          := NULL;
   lc_attribute9             mtl_cross_references.attribute9%TYPE          := NULL;
   lc_attribute10            mtl_cross_references.attribute10%TYPE         := NULL;
   lc_attribute11            mtl_cross_references.attribute11%TYPE         := NULL;
   LC_ATTRIBUTE12            MTL_CROSS_REFERENCES.ATTRIBUTE12%TYPE         := NULL;
   lc_attribute13            mtl_cross_references.attribute13%TYPE         := NULL;
   lc_severity               VARCHAR2(15) := NULL;
   LC_ERROR_LOCATION         VARCHAR2(50);
   EX_XREF_ERROR             EXCEPTION;
   --Added of part of R12 Retrofit Changes
   l_XRef_Tbl                MTL_CROSS_REFERENCES_PUB.XRef_Tbl_Type; 
   LC_RETURN_STATUS          VARCHAR2(1) := NULL;
   lc_message_list           Error_Handler.Error_Tbl_Type;
   LN_MSG_COUNT              NUMBER;
   --End of Addition
   
BEGIN
   
   -----------------------
   -- Action Add or Update
   -----------------------
   IF p_xref_object IS NULL OR
      p_item        IS NULL OR
      p_xref_item   IS NULL OR
      p_xref_type   IS NULL OR
      p_action      IS NULL    THEN
      
      x_message_code  := -1;
      fnd_message.set_name('XXPTP','XX_INV_MANDATORY_PARAMETERS');
      x_message_data  := fnd_message.get;
      lc_error_location    := 'XX_INV_MANDATORY_PARAMETERS';
      RAISE EX_XREF_ERROR;
      
   END IF;
   
   IF p_action = 'C' OR p_action = 'D' THEN
      ---------------------------------------------------------------------------------------
      -- Validate XREF_OBJECT, XREF_TYPE for existence and get respective lookup_code value
      ---------------------------------------------------------------------------------------
      BEGIN
         
         SELECT lookup_code
         INTO   lc_lookup_code
         FROM   fnd_lookup_values
         WHERE  lookup_type = 'RMS_EBS_CROSS_REFERENCE_TYPES'
         AND    tag           = p_xref_object
         AND    meaning       = p_xref_type
         AND    enabled_flag  = 'Y';
      EXCEPTION
         
         WHEN NO_DATA_FOUND THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_CROSS_REFERENCE_CODE');
            x_message_data := fnd_message.get;
            lc_error_location    := 'XX_INV_CROSS_REFERENCE_CODE';
            RAISE EX_XREF_ERROR;
         
         WHEN OTHERS THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
            fnd_message.set_token('SQLERR',SQLERRM); 
            x_message_data := fnd_message.get;
            lc_error_location    := 'XX_INV_XREF_OTHERS';
            RAISE EX_XREF_ERROR;

      END;         
   
      ----------------------------------------------------------------
      -- Check cross_reference_type in mtl_cross_reference_types table
      ----------------------------------------------------------------
      BEGIN
         
         SELECT count(1)
         INTO   ln_xref_type_exists
         FROM   mtl_cross_reference_types
         WHERE  cross_reference_type = lc_lookup_code;
         IF ln_xref_type_exists = 0 THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_CROSS_REFERENCE_TYPE');
            x_message_data := fnd_message.get;
            lc_error_location    := 'XX_INV_CROSS_REFERENCE_TYPE';
            RAISE EX_XREF_ERROR;
         END IF;
      
      EXCEPTION
      
         WHEN OTHERS THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
            fnd_message.set_token('SQLERR',SQLERRM); 
            x_message_data := fnd_message.get;
            lc_error_location    := 'XX_INV_XREF_OTHERS';
            RAISE EX_XREF_ERROR;

      END;         
      
      --------------------------------------------
      -- validate item in mtl_system_items_b table
      --------------------------------------------
      BEGIN
         
         SELECT inventory_item_id
         INTO   ln_inventory_item_id
         FROM   mtl_system_items_b
         WHERE  organization_id=(SELECT master_organization_id
                       FROM mtl_parameters
                          WHERE ROWNUM<2)
         AND  segment1 = p_item;  
      EXCEPTION
         
         WHEN NO_DATA_FOUND THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_INVALID_ITEM');
            x_message_data := fnd_message.get;
            lc_error_location    := 'XX_INV_INVALID_ITEM';
            RAISE EX_XREF_ERROR;
   
         WHEN OTHERS THEN
            x_message_code  := -1;
            fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
            fnd_message.set_token('SQLERR',SQLERRM); 
            x_message_data := fnd_message.get;
            lc_error_location    := 'XX_INV_XREF_OTHERS';
            RAISE EX_XREF_ERROR;
      END;
   
      ---------------------------------------------------------
      -- Action 'C' - Create or update Cross references record
      ---------------------------------------------------------
      IF p_action = 'C' THEN 
       
         -------------------------------------------------------------------------------------------
         -- Validate xref_item and select description from mtl_system_items_b table in case of 'XREF'
         -------------------------------------------------------------------------------------------
         IF p_xref_object = 'XREF' THEN
         
            BEGIN
            
               SELECT description
               INTO   lc_description
               FROM   mtl_system_items_b
               WHERE  organization_id=(SELECT master_organization_id
                           FROM mtl_parameters
                              WHERE ROWNUM<2)
               AND  segment1 = p_xref_item;
            EXCEPTION
            
               WHEN NO_DATA_FOUND THEN
         
                  x_message_code  := -1;
                  fnd_message.set_name('XXPTP','XX_INV_CROSS_REFERENCE_ITEM');
                  x_message_data := fnd_message.get;
                  lc_error_location    := 'XX_INV_CROSS_REFERENCE_ITEM';
                  RAISE EX_XREF_ERROR;

               WHEN OTHERS THEN
               
                  x_message_code  := -1;
                  fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
                  fnd_message.set_token('SQLERR',SQLERRM); 
                  x_message_data := fnd_message.get;
                  lc_error_location    := 'XX_INV_XREF_OTHERS';
                  RAISE EX_XREF_ERROR;
               
            END;      
         
         --------------------------------------------------------------------------------
         -- Populate Product Cross References for Office Depot to Non Office Depot Items.
         --------------------------------------------------------------------------------
         ELSIF p_xref_object = 'PRDS' THEN
            
            lc_description          := p_prdxrefdesc;
            lc_attribute_category   := 'PRDS';
            lc_attribute1           := p_xref_type;
            lc_attribute2           := p_prodmultiplier;
            lc_attribute3           := p_prodmultdivcd;
            
         --------------------------------------------------------------------------------
         -- Populate Wholesaler  Cross References for Office Depot to Wholesaler's Items.
         --------------------------------------------------------------------------------
         ELSIF p_xref_Object = 'WHLS' THEN
         
            ln_supplier:=LPAD(p_whslrsupplier,10,0);

        ln_vendor_exists:=xx_po_global_vendor_pkg.f_translate_inbound(ln_supplier);

          IF ln_vendor_exists=-1 THEN

               x_message_code  := -1;
               fnd_message.set_name('XXPTP','XX_INV_VENDOR');
               x_message_data := fnd_message.get;
               lc_error_location    := 'XX_INV_VENDOR';
               RAISE EX_XREF_ERROR;                  

            END IF;

            lc_attribute_category   := 'WHLS';
            lc_description          := p_prdxrefdesc;         
            lc_attribute1           := p_xref_type;
            lc_attribute2           := Null;
            lc_attribute3           := p_whslrsupplier;
            lc_attribute4           := p_whslrmultiplier;
            lc_attribute5           := p_whslrmultdivcd;
            lc_attribute6           := p_whslrprodcategory;
            lc_attribute7           := p_whslrretailprice;
            lc_attribute8           := p_whslruomcd;
            lc_attribute9           := p_whslrgencatpgnbr;
            lc_attribute10          := p_whslrfurcatpgnbr;
            lc_attribute11          := p_whslrnnpgnbr;
            lc_attribute12          := p_whslrprgeligflg;
            lc_attribute13          := p_whslrbranchflg;
            
         END IF; --p_xref_object = 'XREF'
		 BEGIN
            
            SELECT rowid,inventory_item_id
            INTO   lc_rowid,
                   ln_inventory_item_mcr
            FROM   mtl_cross_references
            WHERE  inventory_item_id = ln_inventory_item_id
            AND    cross_reference = p_xref_item
            AND    cross_reference_type = lc_lookup_code;
         EXCEPTION
            
            WHEN NO_DATA_FOUND THEN
                ln_inventory_item_mcr:= NULL;
            
            WHEN OTHERS THEN
               x_message_code  := -1;
               fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
               fnd_message.set_token('SQLERR',SQLERRM); 
               x_message_data := fnd_message.get;
               lc_error_location    := 'XX_INV_XREF_OTHERS';
               RAISE EX_XREF_ERROR;
         END;
         
         -------------------------------------------------
         -- populating data in mtl_cross_references table
         -------------------------------------------------
         IF ln_inventory_item_mcr IS NULL THEN
            L_XREF_TBL(1).TRANSACTION_TYPE 				:= 'CREATE'; --Added as part of R12 Retrofit Changes
			L_XREF_TBL(1).INVENTORY_ITEM_ID             := LN_INVENTORY_ITEM_ID; --Added as part of R12 Retrofit Changes
            /*BEGIN
               INSERT INTO mtl_cross_references mcr
                  (
                  mcr.inventory_item_id,
                  mcr.organization_id,
                  mcr.cross_reference_type,
                  mcr.cross_reference,
                  mcr.last_update_date,
                  mcr.last_updated_by,
                  mcr.creation_date,
                  mcr.created_by,
                  mcr.description,
                  mcr.org_independent_flag,
                  mcr.attribute1,
                  mcr.attribute2,
                  mcr.attribute3,
                  mcr.attribute4,
                  mcr.attribute5,
                  mcr.attribute6,
                  mcr.attribute7,
                  mcr.attribute8,
                  mcr.attribute9,
                  mcr.attribute10,
                  mcr.attribute11,
                  mcr.attribute12,
                  mcr.attribute13,
                  mcr.attribute_category
                  )
               VALUES 
                  ( 
                  ln_inventory_item_id,
                  NULL,
                  lc_lookup_code,
                  p_xref_item,
                  SYSDATE,
                  fnd_global.user_id,
                  SYSDATE,
                  fnd_global.user_id,
                  lc_description,
                  'Y',
                  lc_attribute1,
                  lc_attribute2,
                  lc_attribute3,
                  lc_attribute4,
                  lc_attribute5,
                  lc_attribute6,
                  lc_attribute7,
                  lc_attribute8,
                  lc_attribute9,
                  lc_attribute10,
                  lc_attribute11,
                  lc_attribute12,
                  lc_attribute13,
                  lc_attribute_category
                  );                         
            EXCEPTION
               
               WHEN OTHERS THEN
                  x_message_code  := -1;
                  fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
                  fnd_message.set_token('SQLERR',SQLERRM); 
                  x_message_data := fnd_message.get;
                  lc_error_location    := 'XX_INV_XREF_OTHERS';
                  RAISE EX_XREF_ERROR;
            END;
            
            COMMIT;
            x_message_code := 0;
            fnd_message.set_name('XXPTP','XX_INV_SUCCESSFUL_INSERTION');
            x_message_data := fnd_message.get;*/
         
         ELSE
         L_XREF_TBL(1).TRANSACTION_TYPE 			 := 'UPDATE'; --Added as part of R12 Retrofit Changes
		 L_XREF_TBL(1).INVENTORY_ITEM_ID             := ln_inventory_item_mcr; --Added as part of R12 Retrofit Changes
		 ------------------------------------------------------------------------------------------------------
         -- Cross check data in MTL_CROSS_REFERENCES table if exists update it else populate data in base table
         ------------------------------------------------------------------------------------------------------
         
            /*BEGIN
               ------------------------------
               -- Updating data in base table
               ------------------------------
              UPDATE mtl_cross_references mcr
               SET    mcr.cross_reference_type = lc_lookup_code,
                      mcr.cross_reference      = p_xref_item,
                      mcr.last_update_date     = SYSDATE,
                      mcr.last_updated_by      = fnd_global.user_id,
                      mcr.org_independent_flag = 'Y',
                      mcr.description          = lc_description,
                      mcr.attribute_category   = lc_attribute_category,
                      mcr.attribute1           = lc_attribute1,
                      mcr.attribute2           = lc_attribute2,
                      mcr.attribute3           = lc_attribute3,
                      mcr.attribute4           = lc_attribute4,
                      mcr.attribute5           = lc_attribute5,
                      mcr.attribute6           = lc_attribute6,
                      mcr.attribute7           = lc_attribute7,
                      mcr.attribute8           = lc_attribute8,
                      mcr.attribute9           = lc_attribute9,
                      mcr.attribute10          = lc_attribute10,
                      mcr.attribute11          = lc_attribute11,
                      mcr.attribute12          = lc_attribute12,
                      mcr.attribute13          = lc_attribute13
               WHERE  mcr.rowid                = lc_rowid;
               
            EXCEPTION
               WHEN OTHERS THEN
                  x_message_code  := -1;
                  fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
                  fnd_message.set_token('SQLERR',SQLERRM); 
                  x_message_data := fnd_message.get;
                  lc_error_location    := 'XX_INV_XREF_OTHERS';
                  RAISE EX_XREF_ERROR;
            END;
            
            COMMIT;
            x_message_code := 0;
            fnd_message.set_name('XXPTP','XX_INV_SUCCESSFUL_UPDATION');
            x_message_data := fnd_message.get; */

         END IF;
      END IF;-- Action 'C'
      
      ----------------------------------------------
      -- Action 'D' - Delete Cross references record
      ----------------------------------------------
      IF p_action = 'D' THEN
      L_XREF_TBL(1).TRANSACTION_TYPE := 'DELETE'; --Added as part of R12 Retrofit Changes
      /*
            ---------------------------------------------------
            -- Delete cross reference value from the base table
            ---------------------------------------------------
            DELETE
            FROM  mtl_cross_references
            WHERE cross_reference_type = lc_lookup_code
            AND   inventory_item_id    = ln_inventory_item_id
            AND   cross_reference      = p_xref_item;
         
            IF SQL%ROWCOUNT > 0 THEN
            
               COMMIT;
               x_message_code := 0;
               fnd_message.set_name('XXPTP','XX_INV_SUCCESSFUL_DELETION');
               x_message_data := fnd_message.get;
            ELSE
               x_message_code  := -1;
               fnd_message.set_name('XXPTP','XX_INV_UNSUCCESSFUL_DELETION');
               x_message_data := fnd_message.get;
               lc_error_location    := 'XX_INV_UNSUCCESSFUL_DELETION';
               RAISE EX_XREF_ERROR;
               
            END IF;*/

      END IF;-- Action 'D' 
   
   ELSE
      
      x_message_code  := -1;
      fnd_message.set_name('XXPTP','XX_INV_INVALID_ACTION');
      x_message_data := fnd_message.get;
      lc_error_location    := 'XX_INV_INVALID_ACTION';
      RAISE EX_XREF_ERROR;
   
    END IF;
   --Added as part of R12 Retrofit Changes
    l_XRef_Tbl(1).X_Return_Status                := NULL;
    L_XREF_TBL(1).ORGANIZATION_ID               := NULL;
    L_XREF_TBL(1).CROSS_REFERENCE_TYPE          := LC_LOOKUP_CODE;
    l_XRef_Tbl(1).Cross_Reference                := p_xref_item;
    L_XREF_TBL(1).CROSS_REFERENCE_ID            := MTL_CROSS_REFERENCES_B_S.nextval;
    L_XREF_TBL(1).DESCRIPTION                   := LC_DESCRIPTION;
    L_XREF_TBL(1).ORG_INDEPENDENT_FLAG          := 'Y';  
    L_XREF_TBL(1).ATTRIBUTE1                    := LC_ATTRIBUTE1;
    L_XREF_TBL(1).ATTRIBUTE2                    := LC_ATTRIBUTE2;
    L_XREF_TBL(1).ATTRIBUTE3                    := LC_ATTRIBUTE3;
    L_XREF_TBL(1).ATTRIBUTE4                    := LC_ATTRIBUTE4;
    L_XREF_TBL(1).ATTRIBUTE5                    := LC_ATTRIBUTE5;
    L_XREF_TBL(1).ATTRIBUTE6                    := LC_ATTRIBUTE6;
    L_XREF_TBL(1).ATTRIBUTE7                    := LC_ATTRIBUTE7;
    L_XREF_TBL(1).ATTRIBUTE8                    := LC_ATTRIBUTE8;
    L_XREF_TBL(1).ATTRIBUTE9                    := LC_ATTRIBUTE9;
    L_XREF_TBL(1).ATTRIBUTE10                   := LC_ATTRIBUTE10;
    L_XREF_TBL(1).ATTRIBUTE11                   := LC_ATTRIBUTE11;
    l_XRef_Tbl(1).Attribute12                   := lc_attribute12;
    L_XREF_TBL(1).ATTRIBUTE13                   := LC_ATTRIBUTE13;         
    L_XREF_TBL(1).ATTRIBUTE_CATEGORY            := LC_ATTRIBUTE_CATEGORY;
    L_XREF_TBL(1).UOM_CODE                      := NULL;
    l_XRef_Tbl(1).Revision_Id                   := NULL;

    
            --API Call
                mtl_cross_references_pub.process_xref
                (
                  P_API_VERSION        => 1.0,
                  P_INIT_MSG_LIST      => 'F',
                  P_COMMIT             => 'F',
                  p_XRef_Tbl           => l_XRef_Tbl,
                  x_return_status      => lc_return_status,
                  X_MSG_COUNT          => LN_MSG_COUNT,
                  x_message_list       => lc_message_list);        
        IF NOT (lc_return_status = fnd_api.g_ret_sts_success)
            THEN
			x_message_code  := -1;
			fnd_message.set_name('XXPTP','XX_INV_INVALID_ACTION');
			x_message_data := fnd_message.get;
			lc_error_location    := 'XX_INV_INVALID_ACTION';
			RAISE EX_XREF_ERROR;
        ELSE
            COMMIT;
            x_message_code := 0;
            fnd_message.set_name('XXPTP','XX_INV_SUCCESSFUL_INSERTION');
            x_message_data := fnd_message.get;
        END IF;
          
    --End of Addition by Sheetal on 18-Sep-2013
    

EXCEPTION

   WHEN EX_XREF_ERROR THEN
      
      -- Log error in error table
      XX_COM_ERROR_LOG_PUB.LOG_ERROR 
          (
           p_program_type            => G_PROG_TYPE     
          ,p_program_name            => G_PROG_NAME     
          ,p_module_name             => G_MODULE_NAME   
          ,p_error_location          => lc_error_location
          ,p_error_message_code      => x_message_code          
          ,p_error_message           => x_message_data       
          ,p_error_message_severity  => G_MAJOR     
          ,p_notify_flag             => G_NOTIFY        
         );

   WHEN OTHERS THEN

      x_message_code  := -1;
      fnd_message.set_name('XXPTP','XX_INV_XREF_OTHERS');
      fnd_message.set_token('SQLERR',SQLERRM);
      x_message_data  := fnd_message.get;
      lc_error_location    := 'XX_INV_XREF_OTHERS';
      
     
      -- Log error in error table
      XX_COM_ERROR_LOG_PUB.LOG_ERROR
          (
           p_program_type            => G_PROG_TYPE     
          ,p_program_name            => G_PROG_NAME     
          ,p_module_name             => G_MODULE_NAME   
          ,p_error_location          => lc_error_location
          ,p_error_message_code      => x_message_code          
          ,p_error_message           => x_message_data       
          ,p_error_message_severity  => G_MAJOR     
          ,p_notify_flag             => G_NOTIFY        
         );

END Process_item_xref;
END xx_inv_item_xref_pkg;
/
SHOW ERRORS;
EXIT;
-- --------------------------------------------------------------------------------
-- +==============================================================================+
-- |                         End of Script                                        |
-- +==============================================================================+
-- --------------------------------------------------------------------------------