SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_BACKORDER_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name  :  XX_OM_BACKORDER_PKG                                      |
-- | Rice ID : E0282                                                   |
-- | Description: This package contains the function that determines   |
-- |              whether the back order is allowed or not.            |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       18-Jul-07   Senthil Kumar.   Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
gc_exp_header       xx_om_global_exceptions.exception_header%TYPE  DEFAULT  'OTHERS';
gc_track_code       xx_om_global_exceptions.track_code%TYPE        DEFAULT  'OTC';
gc_sol_domain       xx_om_global_exceptions.solution_domain%TYPE   DEFAULT  'Sourcing';
gc_function         xx_om_global_exceptions.function_name%TYPE     DEFAULT  'E0282_Backorder_Process';
-- +===================================================================+
-- | Name  : IS_BACKORDERABLE                                          |
-- | Description: This Function is used to determine whether           |
-- |              back order is allowed or not.                        |
-- |                 suppliers                                         |
-- |                                                                   |
-- | Parameters :      NONE                                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :         1 - Backorde Allowed                            |
-- |                   2 - Backorder Not Allowed                       |
-- |                                                                   |
-- +===================================================================+

FUNCTION IS_BACKORDERABLE (
                         p_inventory_item_id      mtl_system_items.inventory_item_id%TYPE                 DEFAULT NULL
                        ,p_organization_id        hr_operating_units.organization_id%TYPE                 DEFAULT NULL
                        ,p_order_line_value       NUMBER                                                  DEFAULT NULL
                        ,p_item_status            VARCHAR2                                                DEFAULT NULL
                        ,p_customer_id            hz_cust_accounts.cust_account_id%TYPE                   DEFAULT NULL
                        ,p_replen_type            xx_inv_item_org_attributes.od_replen_type_cd%TYPE       DEFAULT NULL
                        ,p_replen_sub_type        xx_inv_item_org_attributes.od_replen_sub_type_cd%TYPE   DEFAULT NULL
                        ,p_backorder_threshold    NUMBER                                                  DEFAULT NULL
                        ,p_backorder_override     VARCHAR2                                                DEFAULT NULL
                        )
RETURN NUMBER IS
   err_report_type           xx_om_report_exception_t;
   lc_err_code               xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
   lc_err_desc               xx_om_global_exceptions.description%TYPE DEFAULT ' ';
   lc_entity_ref             xx_om_global_exceptions.entity_ref%TYPE;

   lc_item_status         mtl_system_items.inventory_item_status_code%TYPE;
   ln_back_order_flag     NUMBER;
   ln_threshold_value     NUMBER;
   lc_replen_type         xx_inv_item_org_attributes.od_replen_type_cd%TYPE;
   lc_replen_sub_type     xx_inv_item_org_attributes.od_replen_sub_type_cd%TYPE;
   lc_backorder_ind       hz_cust_accounts.attribute7%TYPE;
   lb_replenishable_flag  BOOLEAN;
   lc_err_buf             VARCHAR2(240);
   lc_ret_code            VARCHAR2(30);
BEGIN
   IF ( p_inventory_item_id IS NULL) THEN
      lc_err_code := 'XX_OM_MANDATORY_PARAM';
      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_MANDATORY_PARAM');
      FND_MESSAGE.SET_TOKEN('PARAM_NAME','Inventory Item Id');
      lc_err_desc := FND_MESSAGE.GET;
      lc_entity_ref:='Inventory Item Id';

      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,0);

                  XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                               err_report_type
                                                               ,lc_err_buf
                                                               ,lc_ret_code
                                                              );
      RETURN 2;
   END IF;

   IF (p_organization_id IS NULL) THEN
      lc_err_code := 'XX_OM_MANDATORY_PARAM';
      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_MANDATORY_PARAM');
      FND_MESSAGE.SET_TOKEN('PARAM_NAME','Organization Id');
      lc_err_desc := FND_MESSAGE.GET;
      lc_entity_ref:='Organization Id';
      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,0);

                  XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                               err_report_type
                                                               ,lc_err_buf
                                                               ,lc_ret_code
                                                              );
      RETURN 2;
   END IF;

   IF (p_order_line_value IS NULL) THEN
      lc_err_code := 'XX_OM_MANDATORY_PARAM';
      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_MANDATORY_PARAM');
      FND_MESSAGE.SET_TOKEN('PARAM_NAME','Order Line Value');
      lc_err_desc := FND_MESSAGE.GET;
      lc_entity_ref:='Order Line Value';

      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,0);
                  XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                               err_report_type
                                                               ,lc_err_buf
                                                               ,lc_ret_code
                                                              );
      RETURN 2;
   END IF;

   IF (p_item_status IS NULL) THEN
      BEGIN
         --Fetch the inventory item status code from MTL_SYSYTEM_ITEMS to check whether the given item is
         --in active status or not.If not no further validations are done and the program exits
         SELECT CASE NVL(MSI.inventory_item_status_code,'A')
                  WHEN 'A' THEN 'Active'
                  WHEN 'Active' THEN 'Active'
                  ELSE 'Inactive'
                END
         INTO lc_item_status
         FROM mtl_system_items MSI
         WHERE MSI.inventory_item_id = p_inventory_item_id
         AND MSI.organization_id = p_organization_id;

         ln_back_order_flag:=1;
         --If the item is in any other status other than Active then exit
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN 2;--Backorder Not Allowed
      END;
   ELSE
      lc_item_status:=p_item_status;
   END IF;

   IF ((lc_item_status='Active')
   OR (lc_item_status='A'))THEN
            ln_back_order_flag:=1;
   ELSE
            RETURN 2;
   END IF;

   IF(ln_back_order_flag=1) THEN
      IF(p_backorder_threshold is not null) THEN
         ln_threshold_value:=p_backorder_threshold;
      ELSE
         BEGIN
            SELECT NVL(profile_option_value,0)
            INTO ln_threshold_value
            FROM  fnd_profile_options FPO
                  ,fnd_profile_options_tl FPOT
                  ,fnd_profile_option_values FPOV
            WHERE FPO.profile_option_id=FPOV.profile_option_id
            AND FPOT.profile_option_name=FPO.profile_option_name
            AND FPO.profile_option_name='XX_OM_BACK_THRESHOLD'
            AND FPOV.level_value=FND_PROFILE.VALUE('RESP_ID');
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               RETURN 2;
         END;
      END IF;

      IF(p_order_line_value>=ln_threshold_value)THEN
         ln_back_order_flag:=1;
      ELSE
         RETURN 2;
      END IF;
   END IF;

   IF(ln_back_order_flag=1) THEN
      IF(p_backorder_override is null) THEN
         IF(p_customer_id is not null) THEN
            BEGIN
               SELECT NVL(attribute7,'Y')
               INTO lc_backorder_ind
               FROM hz_cust_accounts
               WHERE cust_account_id=p_customer_id;

               IF(lc_backorder_ind='Y') THEN
                  ln_back_order_flag:=1;
               ELSE
                  RETURN 2;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  lc_err_code := 'XX_OM_002_CUSTOMER_NOT_FOUND';
                  FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_002_CUSTOMER_NOT_FOUND');
                  FND_MESSAGE.SET_TOKEN('PARAM_NAME',p_customer_id);
                  lc_err_desc := FND_MESSAGE.GET;
                  lc_entity_ref:='Customer ID';
                  err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,0);

                  XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                               err_report_type
                                                               ,lc_err_buf
                                                               ,lc_ret_code
                                                              );
                  RETURN 2;
            END;
         ELSE
            ln_back_order_flag:=1;
         END IF;
      ELSIF(p_backorder_override='Y') THEN
         ln_back_order_flag:=1;
      ELSE
         RETURN 2;
      END IF;
   END IF;

   IF(ln_back_order_flag=1) THEN
      IF((p_replen_type is NOT NULL)
      AND (p_replen_sub_type is NOT NULL)) THEN
         lc_replen_type:=p_replen_type;
         lc_replen_sub_type:=p_replen_sub_type;
      ELSE
         BEGIN
            --Fetch the replen_type_cd and replen_sub_type_cd from item org attributes table
            SELECT NVL(XIIOA.od_replen_type_cd,'N')
                  ,NVL(XIIOA.od_replen_sub_type_cd,'N')
            INTO  lc_replen_type
                 ,lc_replen_sub_type
            FROM xx_inv_item_org_attributes XIIOA
            WHERE XIIOA.inventory_item_id=p_inventory_item_id
            AND XIIOA.organization_id=p_organization_id;

            IF(p_replen_type IS NOT NULL) THEN
               lc_replen_type:=p_replen_type;
            END IF;
            IF(p_replen_sub_type IS NOT NULL) THEN
               lc_replen_sub_type:=p_replen_sub_type;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               RETURN 2;
         END;
      END IF;

      --Call the is_replenished to determine whether the item is replenishable or not.
      lb_replenishable_flag:=XX_OM_DMDEXTLEG_PKG.is_replenished(lc_replen_type,lc_replen_sub_type);

      IF(lb_replenishable_flag=FALSE)THEN
         RETURN 2;
      ELSE
         ln_back_order_flag:=1;
      END IF;
   END IF;
   ---Return Back order allowed
   RETURN ln_back_order_flag;
EXCEPTION
   WHEN OTHERS THEN
      lc_err_code := 'XX_OM_0001_UNKNOWN_ERROR';
      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_UNKNOWN_ERROR');
      FND_MESSAGE.SET_TOKEN('PARAM_NAME','E0282-Backorder Process');
      lc_err_desc := FND_MESSAGE.GET;
      lc_entity_ref:='E0282';
      err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,lc_err_code
                                                ,SUBSTR(lc_err_desc,1,1000)
                                                ,lc_entity_ref
                                                ,0);

                  XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                               err_report_type
                                                               ,lc_err_buf
                                                               ,lc_ret_code
                                                              );
       RETURN 2;

END IS_BACKORDERABLE;
END XX_OM_BACKORDER_PKG;
/
SHOW ERROR