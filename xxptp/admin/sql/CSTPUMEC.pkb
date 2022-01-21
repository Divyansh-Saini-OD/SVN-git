CREATE OR REPLACE PACKAGE BODY "APPS"."CSTPUMEC" AS
/* $Header: CSTPUMEB.pls 115.19 2004/06/15 21:41:27 lfreyes ship $ */


--
--  stored procedure to copy a cost type before executing the mass
--  edit procedure
--
PROCEDURE CSTPECPC (
         I_ORGANIZATION_ID      IN      NUMBER,
         I_COST_TYPE_ID         IN      NUMBER,
         I_FROM_COST_TYPE       IN      NUMBER,
         I_LIST_ID              IN      NUMBER,
         I_USER_ID              IN      NUMBER,
         I_REQ_ID               IN      NUMBER,
         I_PRGM_ID              IN      NUMBER,
         I_PRGM_APPL_ID         IN      NUMBER,
         O_RETURN_CODE          OUT NOCOPY     NUMBER) IS

    l_location       NUMBER;

BEGIN

    O_RETURN_CODE := 9999;

    l_location := 1;

    DELETE FROM cst_item_costs CIC
    WHERE CIC.organization_id = I_ORGANIZATION_ID
    AND   CIC.cost_type_id    = I_COST_TYPE_ID
    AND   CIC.inventory_item_id in
             (SELECT  C2.inventory_item_id
              FROM    cst_lists CL
          ,       cst_item_costs C2
              WHERE   list_id              = I_LIST_ID
              AND     C2.cost_type_id      = I_FROM_COST_TYPE
              AND     C2.organization_id   = I_ORGANIZATION_ID
              AND     C2.inventory_item_id = CL.entity_id
    );

    l_location := 2;

    INSERT INTO cst_item_costs
         (
         inventory_item_id,   organization_id,  cost_type_id,
         request_id,          program_application_id,
         program_id,          program_update_date,
         last_update_date,    last_updated_by,
         creation_date,       created_by,
         last_update_login,   inventory_asset_flag,
         lot_size,            based_on_rollup_flag,
         shrinkage_rate,      defaulted_flag,
         pl_material,         pl_material_overhead,
         pl_resource,         pl_outside_processing,
         pl_overhead,
         tl_material,         tl_material_overhead,
         tl_resource,         tl_outside_processing,
         tl_overhead,
         material_cost,       material_overhead_cost,
         resource_cost,       outside_processing_cost,
         overhead_cost,
         pl_item_cost,        tl_item_cost,
         unburdened_cost,     burden_cost,
         item_cost,           attribute_category,
         attribute1,     attribute2,     attribute3,
         attribute4,     attribute5,     attribute6,
         attribute7,     attribute8,     attribute9,
         attribute10,    attribute11,    attribute12,
         attribute13,    attribute14,    attribute15
          )
    SELECT  CIC.inventory_item_id
    ,       CIC.organization_id
    ,       I_COST_TYPE_ID
    ,       I_REQ_ID
    ,       I_PRGM_APPL_ID
    ,       I_PRGM_ID
    ,       SYSDATE
    ,       SYSDATE
    ,       I_USER_ID
    ,       SYSDATE
    ,       I_USER_ID
    ,       -1
    ,       CIC.inventory_asset_flag
    ,       CIC.lot_size
    ,       CIC.based_on_rollup_flag
    ,       CIC.shrinkage_rate
    ,       CIC.defaulted_flag
    ,       CIC.pl_material
    ,       CIC.pl_material_overhead
    ,       CIC.pl_resource
    ,       CIC.pl_outside_processing
    ,       CIC.pl_overhead
    ,       CIC.tl_material
    ,       CIC.tl_material_overhead
    ,       CIC.tl_resource
    ,       CIC.tl_outside_processing
    ,       CIC.tl_overhead
    ,       CIC.material_cost
    ,       CIC.material_overhead_cost
    ,       CIC.resource_cost
    ,       CIC.outside_processing_cost
    ,       CIC.overhead_cost
    ,       CIC.pl_item_cost
    ,       CIC.tl_item_cost
    ,       CIC.unburdened_cost
    ,       CIC.burden_cost
    ,       CIC.item_cost
    ,       CIC.attribute_category
    ,       CIC.attribute1
    ,       CIC.attribute2
    ,       CIC.attribute3
    ,       CIC.attribute4
    ,       CIC.attribute5
    ,       CIC.attribute6
    ,       CIC.attribute7
    ,       CIC.attribute8
    ,       CIC.attribute9
    ,       CIC.attribute10
    ,       CIC.attribute11
    ,       CIC.attribute12
    ,       CIC.attribute13
    ,       CIC.attribute14
    ,       CIC.attribute15
    FROM    cst_lists CL
    ,       cst_item_costs CIC
    WHERE   CL.list_id            = I_LIST_ID
    AND     CIC.inventory_item_id = CL.entity_id
    AND     CIC.cost_type_id      = I_FROM_COST_TYPE
    AND     CIC.organization_id   = I_ORGANIZATION_ID;

    --
    --  delete any cost information from CST_ITEM_COST_DETAILS
    --  for items specified in the current edit list
    --
    l_location := 3;

    DELETE FROM cst_item_cost_details CICD
    WHERE CICD.organization_id = I_ORGANIZATION_ID
    AND   CICD.cost_type_id = I_COST_TYPE_ID
    AND   CICD.inventory_item_id in
             (SELECT  C2.inventory_item_id
              FROM    cst_lists      CL
          ,       cst_item_costs C2
              WHERE   list_id              = I_LIST_ID
              AND     C2.cost_type_id      = I_FROM_COST_TYPE
              AND     C2.organization_id   = I_ORGANIZATION_ID
              AND     C2.inventory_item_id = CL.entity_id
    );

    --
    --  copy cost information from the source cost type to
    --  the target cost type
    --
    l_location := 4;


    INSERT INTO cst_item_cost_details
    (       inventory_item_id
    ,       organization_id
    ,       cost_type_id
    ,       last_update_date
    ,       last_updated_by
    ,       creation_date
    ,       created_by
    ,       last_update_login
    ,       operation_sequence_id
    ,       operation_seq_num
    ,       department_id
    ,       level_type
    ,       activity_id
    ,       resource_seq_num
    ,       resource_id
    ,       resource_rate
    ,       item_units
    ,       activity_units
    ,       usage_rate_or_amount
    ,       basis_type
    ,       basis_resource_id
    ,       basis_factor
    ,       net_yield_or_shrinkage_factor
    ,       item_cost
    ,       cost_element_id
    ,       rollup_source_type
    ,       activity_context
    ,       request_id
    ,       program_application_id
    ,       program_id
    ,       program_update_date
    ,       yielded_cost
    ,       attribute_category
    ,       attribute1
    ,       attribute2
    ,       attribute3
    ,       attribute4
    ,       attribute5
    ,       attribute6
    ,       attribute7
    ,       attribute8
    ,       attribute9
    ,       attribute10
    ,       attribute11
    ,       attribute12
    ,       attribute13
    ,       attribute14
    ,       attribute15)
    SELECT
        CICD.inventory_item_id
    ,       CICD.organization_id
    ,       I_COST_TYPE_ID
    ,       SYSDATE
    ,       I_USER_ID
    ,       SYSDATE
    ,       I_USER_ID
    ,       I_USER_ID
    ,       CICD.operation_sequence_id
    ,       CICD.operation_seq_num
    ,       CICD.department_id
    ,       CICD.level_type
    ,       CICD.activity_id
    ,       CICD.resource_seq_num
    ,       CICD.resource_id
    ,       CICD.resource_rate
    ,       CICD.item_units
    ,       CICD.activity_units
    ,       CICD.usage_rate_or_amount
    ,       CICD.basis_type
    ,       CICD.basis_resource_id
    ,       CICD.basis_factor
    ,       CICD.net_yield_or_shrinkage_factor
    ,       CICD.item_cost
    ,       CICD.cost_element_id
    ,       CICD.rollup_source_type
    ,       CICD.activity_context
    ,       I_REQ_ID
    ,       I_PRGM_APPL_ID
    ,       I_PRGM_ID
    ,       SYSDATE
    ,       CICD.yielded_cost
    ,       CICD.attribute_category
    ,       CICD.attribute1
    ,       CICD.attribute2
    ,       CICD.attribute3
    ,       CICD.attribute4
    ,       CICD.attribute5
    ,       CICD.attribute6
    ,       CICD.attribute7
    ,       CICD.attribute8
    ,       CICD.attribute9
    ,       CICD.attribute10
    ,       CICD.attribute11
    ,       CICD.attribute12
    ,       CICD.attribute13
    ,       CICD.attribute14
    ,       CICD.attribute15
    FROM    cst_lists             CL
    ,       cst_item_cost_details CICD
    WHERE   CL.list_id               = I_LIST_ID
    AND     CICD.cost_type_id        = I_FROM_COST_TYPE
    AND     CICD.organization_id     = I_ORGANIZATION_ID
    AND     CICD.inventory_item_id   = CL.entity_id;

    O_RETURN_CODE := 0;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        O_RETURN_CODE := SQLCODE;
    WHEN OTHERS THEN
        O_RETURN_CODE := SQLCODE;
        raise_application_error(-20001,
             'CSTPECPC-' || l_location || ': ' || SQLERRM);

END CSTPECPC;

--
--  stored procedure to insert new item costs for actual cost edits
--
PROCEDURE CSTPEIIC (
         I_ORGANIZATION_ID      IN      NUMBER,
         I_COST_TYPE_ID         IN      NUMBER,
         I_LIST_ID              IN      NUMBER,
         I_RESOURCE_ID          IN      NUMBER,
         I_USER_ID              IN      NUMBER,
         I_REQ_ID               IN      NUMBER,
         I_PRGM_ID              IN      NUMBER,
         I_PRGM_APPL_ID         IN      NUMBER,
         O_RETURN_CODE          OUT NOCOPY     NUMBER) IS


    l_location       NUMBER;


BEGIN

    O_RETURN_CODE := 9999;

    l_location := 1;

    INSERT INTO cst_item_costs
    (       inventory_item_id
    ,       organization_id
    ,       cost_type_id
    ,       request_id
    ,       program_application_id
    ,       program_id
    ,       program_update_date
    ,       last_update_date
    ,       last_updated_by
    ,       creation_date
    ,       created_by
    ,       last_update_login
    ,       inventory_asset_flag
    ,       lot_size
    ,       based_on_rollup_flag
    ,       shrinkage_rate
    ,       defaulted_flag
    ,       attribute_category
    ,       attribute1
    ,       attribute2
    ,       attribute3
    ,       attribute4
    ,       attribute5
    ,       attribute6
    ,       attribute7
    ,       attribute8
    ,       attribute9
    ,       attribute10
    ,       attribute11
    ,       attribute12
    ,       attribute13
    ,       attribute14
    ,       attribute15
    )
    SELECT
        CIC.inventory_item_id
    ,       CIC.organization_id
    ,       I_COST_TYPE_ID
    ,       I_REQ_ID
    ,       I_PRGM_APPL_ID
    ,       I_PRGM_ID
    ,       SYSDATE
    ,       SYSDATE
    ,       I_USER_ID
    ,       SYSDATE
    ,       I_USER_ID
    ,       -1
    ,       1
    ,       CIC.lot_size
    ,       CIC.based_on_rollup_flag
    ,       CIC.shrinkage_rate
    ,       CIC.defaulted_flag
    ,       CIC.attribute_category
    ,       CIC.attribute1
    ,       CIC.attribute2
    ,       CIC.attribute3
    ,       CIC.attribute4
    ,       CIC.attribute5
    ,       CIC.attribute6
    ,       CIC.attribute7
    ,       CIC.attribute8
    ,       CIC.attribute9
    ,       CIC.attribute10
    ,       CIC.attribute11
    ,       CIC.attribute12
    ,       CIC.attribute13
    ,       CIC.attribute14
    ,       CIC.attribute15
    FROM    cst_lists L
    ,       cst_item_costs CIC
    WHERE   CIC.organization_id      = I_ORGANIZATION_ID
    AND     CIC.cost_type_id         in (1,2)     /* from frozen or average */
    AND     L.list_id                = I_LIST_ID
    AND     CIC.inventory_item_id    = L.entity_id
    AND     CIC.inventory_asset_flag = 1
    AND L.entity_id not in (
        SELECT  inventory_item_id
        FROM    cst_item_costs
        WHERE   organization_id   = I_ORGANIZATION_ID
        AND     cost_type_id      = I_COST_TYPE_ID
    );

/*
 Fix for Bug#2122019 - Added activity_id in the insert to populate default
 activity assigned to the sub element being edited. Selected default_activity_id
 from bom_resources for the edited sub element
*/
    l_location := 2;

    INSERT INTO cst_item_cost_details
    (       inventory_item_id
    ,       organization_id
    ,       cost_type_id
    ,       last_update_date
    ,       last_updated_by
    ,       creation_date
    ,       created_by
    ,       level_type
    ,       activity_id
    ,       resource_id
    ,       resource_rate
    ,       usage_rate_or_amount
    ,       basis_type
    ,       basis_factor
    ,       net_yield_or_shrinkage_factor
    ,       item_cost
    ,       cost_element_id
    ,       rollup_source_type
    ,       request_id
    ,       program_application_id
    ,       program_id
    ,       program_update_date
    ,       attribute_category
    ,       attribute1
    ,       attribute2
    ,       attribute3
    ,       attribute4
    ,       attribute5
    ,       attribute6
    ,       attribute7
    ,       attribute8
    ,       attribute9
    ,       attribute10
    ,       attribute11
    ,       attribute12
    ,       attribute13
    ,       attribute14
    ,       attribute15
    )
    SELECT
        CIC.inventory_item_id
    ,       CIC.organization_id
    ,       CIC.cost_type_id
    ,       SYSDATE
    ,       I_USER_ID
    ,       SYSDATE
    ,       I_USER_ID
    ,       1
    ,       BR.default_activity_id
    ,       I_RESOURCE_ID
    ,       1
    ,       0
    ,       1    /* Item */
    ,       1
    ,       1
    ,       0
    ,       1    /* Material */
    ,       1    /* User defined */
    ,       I_REQ_ID
    ,       I_PRGM_APPL_ID
    ,       I_PRGM_ID
    ,       SYSDATE
    ,       CIC.attribute_category
    ,       CIC.attribute1
    ,       CIC.attribute2
    ,       CIC.attribute3
    ,       CIC.attribute4
    ,       CIC.attribute5
    ,       CIC.attribute6
    ,       CIC.attribute7
    ,       CIC.attribute8
    ,       CIC.attribute9
    ,       CIC.attribute10
    ,       CIC.attribute11
    ,       CIC.attribute12
    ,       CIC.attribute13
    ,       CIC.attribute14
    ,       CIC.attribute15
    FROM    cst_lists L
    ,       cst_item_costs CIC
    ,       bom_resources BR
    WHERE   CIC.organization_id      = I_ORGANIZATION_ID
    AND     L.list_id                = I_LIST_ID
    AND     BR.resource_id           = I_RESOURCE_ID
    AND     CIC.cost_type_id         = I_COST_TYPE_ID
    AND     CIC.inventory_item_id    = L.entity_id
    AND     CIC.inventory_asset_flag = 1
    AND     L.entity_id not in (
              SELECT  inventory_item_id
              FROM    cst_item_cost_details
              WHERE   organization_id   = I_ORGANIZATION_ID
              AND     cost_type_id      = I_COST_TYPE_ID
--  Commented out lines to fix bug # 1962252 , mass edit adds new
--  sub-elements on unit cost of items.The changes were introduced due to fix made
--  for bug #  1175172
--              AND     resource_id       = I_RESOURCE_ID
--              AND     level_type        = 1
--              AND     cost_element_id   = 1


);

    O_RETURN_CODE := 0;

EXCEPTION
       WHEN NO_DATA_FOUND THEN
              O_RETURN_CODE := SQLCODE;
       WHEN OTHERS THEN
              O_RETURN_CODE := SQLCODE;
              raise_application_error(-20001,
                     'CSTPEIIC-'||l_location||': '||SQLERRM);

END CSTPEIIC;

--
--  stored procedure to recompute item costs after mass edit execution
--
PROCEDURE CSTPERIC (
        I_ORGANIZATION_ID   IN       NUMBER,
        I_COST_TYPE_ID      IN       NUMBER,
        I_LIST_ID           IN       NUMBER,
        I_USER_ID           IN       NUMBER,
        I_REQ_ID            IN       NUMBER,
        I_PRGM_ID           IN       NUMBER,
        I_PRGM_APPL_ID      IN       NUMBER,
        O_RETURN_CODE       OUT NOCOPY       NUMBER) IS

       l_round_unit   NUMBER;
       l_precision    NUMBER;
       l_ext_prec     NUMBER;
       l_basis_factor NUMBER;

      /* Cursor UPD_ITEM_ID modified for bug 1970016 , 2592136 */

       Cursor   UPD_ITEM_ID is
         SELECT entity_id
         FROM   cst_lists cl
     WHERE CL.list_id= I_LIST_ID
     AND EXISTS (SELECT NULL FROM
       CST_ITEM_COST_DETAILS CICD
           WHERE  CICD.organization_id   = I_ORGANIZATION_ID
           AND    CICD.cost_type_id      = I_COST_TYPE_ID
           AND    CICD.level_type      = 1
           AND    CICD.cost_element_id = 2
           AND    CICD.basis_type      = 5
           AND  CL.entity_id = CICD.inventory_item_id);

       Cursor   C_ITEM_ID is
         -- MODIFIED for item interface test 04-14-08
         select /*+ index(cst_lists CST_LISTS_X1) */ entity_id from cst_lists
          where list_id   = I_LIST_ID ;

    l_location       NUMBER;

BEGIN

    O_RETURN_CODE := 9999;

    CSTPUTIL.CSTPUGCI(I_ORGANIZATION_ID, l_round_unit, l_precision, l_ext_prec);

    --
    --  recompute any material overhead which is based on total value
    --
    l_location := 0;


    FOR ITEMS in UPD_ITEM_ID LOOP
       /* added for bug 2592136 */
       BEGIN
         SELECT SUM(NVL(CICD.item_cost,0))
         into l_basis_factor
         FROM  cst_item_cost_details  CICD
         WHERE CICD.inventory_item_id = ITEMS.entity_id
         AND CICD.organization_id   = I_ORGANIZATION_ID
         AND    CICD.cost_type_id      = I_COST_TYPE_ID
         AND NOT (CICD.cost_element_id = 2 AND CICD.level_type = 1);
       EXCEPTION
       WHEN Others THEN
         l_basis_factor := -1;
       END;


       if (l_basis_factor >= 0) THEN
      /* added for bug 1970016 */
      UPDATE cst_item_cost_details CICD
      SET last_update_date = SYSDATE,
          last_updated_by = I_USER_ID,
          basis_factor = l_basis_factor,
          item_cost = ROUND((CICD.usage_rate_or_amount*l_basis_factor), l_ext_prec),
          request_id = I_REQ_ID,
          program_application_id = I_PRGM_APPL_ID,
          program_id = I_PRGM_ID,
          program_update_date = SYSDATE
      WHERE  organization_id = I_ORGANIZATION_ID
      AND    cost_type_id    = I_COST_TYPE_ID
      AND    level_type      = 1      /* This Level */
      AND    cost_element_id = 2      /* Material Overhead */
      AND    basis_type      = 5      /* Total Value */
      AND CICD.inventory_item_id = ITEMS.entity_id;
      END IF;

    END LOOP;
    --
    --  Update denormalized data in CST_ITEM_COSTS table
    --
    l_location := 1;

    For C_ITEM_ID_REC in C_ITEM_ID
    LOOP
     UPDATE cst_item_costs CIC
       SET (
        last_update_date,
        last_updated_by,
        pl_material,
        pl_material_overhead,
        pl_resource,
        pl_outside_processing,
        pl_overhead,
        tl_material,
        tl_material_overhead,
        tl_resource,
        tl_outside_processing,
        tl_overhead,
        material_cost,
        material_overhead_cost,
        resource_cost,
        outside_processing_cost,
        overhead_cost,
        pl_item_cost,
        tl_item_cost,
        item_cost,
        unburdened_cost,
        burden_cost,
        request_id,
        program_application_id,
        program_id,
        program_update_date) =
        (
        SELECT SYSDATE
        ,      I_USER_ID
        ,      SUM(DECODE(level_type,2,DECODE(cost_element_id,1,item_cost,0),0))
        ,      SUM(DECODE(level_type,2,DECODE(cost_element_id,2,item_cost,0),0))
        ,      SUM(DECODE(level_type,2,DECODE(cost_element_id,3,item_cost,0),0))
        ,      SUM(DECODE(level_type,2,DECODE(cost_element_id,4,item_cost,0),0))
        ,      SUM(DECODE(level_type,2,DECODE(cost_element_id,5,item_cost,0),0))
        ,      SUM(DECODE(level_type,1,DECODE(cost_element_id,1,item_cost,0),0))
        ,      SUM(DECODE(level_type,1,DECODE(cost_element_id,2,item_cost,0),0))
        ,      SUM(DECODE(level_type,1,DECODE(cost_element_id,3,item_cost,0),0))
        ,      SUM(DECODE(level_type,1,DECODE(cost_element_id,4,item_cost,0),0))
        ,      SUM(DECODE(level_type,1,DECODE(cost_element_id,5,item_cost,0),0))
        ,      SUM(DECODE(cost_element_id,1,item_cost))
        ,      SUM(DECODE(cost_element_id,2,item_cost))
        ,      SUM(DECODE(cost_element_id,3,item_cost))
        ,      SUM(DECODE(cost_element_id,4,item_cost))
        ,      SUM(DECODE(cost_element_id,5,item_cost))
        ,      SUM(DECODE(level_type,2,item_cost,0))
        ,      SUM(DECODE(level_type,1,item_cost,0))
        ,      SUM(item_cost)
        ,      SUM(DECODE(cost_element_id,
                             2, DECODE(level_type,2,item_cost,0),
                             item_cost))
        ,      SUM(DECODE(cost_element_id,
                             2, DECODE(level_type,1,item_cost,0),
                             0))
        ,      I_REQ_ID, I_PRGM_APPL_ID, I_PRGM_ID, SYSDATE
        FROM   cst_item_cost_details CICD
        WHERE  organization_id   = I_ORGANIZATION_ID
        AND    cost_type_id      = I_COST_TYPE_ID
        AND    inventory_item_id = C_ITEM_ID_REC.ENTITY_ID
        )
    WHERE CIC.organization_id    = I_ORGANIZATION_ID
    AND   CIC.cost_type_id       = I_COST_TYPE_ID
    AND   CIC.inventory_item_id  = C_ITEM_ID_REC.ENTITY_ID ;

    END LOOP;

    O_RETURN_CODE := 0;

EXCEPTION
       WHEN NO_DATA_FOUND THEN
              O_RETURN_CODE := SQLCODE;
       WHEN OTHERS THEN
              O_RETURN_CODE := SQLCODE;
              raise_application_error(-20001,
                     'CSTPERIC-' || l_location || ': ' || SQLERRM);

END CSTPERIC;


-- Start of comments
--
-- PROCEDURE
--  set_cost_controls       Invoked from the Mass Edit Menu as a concurrent
--                          request. This function allows the user to set
--                          the values of the following three fields in
--                          cst_item_costs:
--                          BASED_ON_ROLLUP_FLAG
--                          DEFAULTED_FLAG
--                          LOT_SIZE
--
--
-- PARAMETERS
--   O_Err_Num         output parameter for errors
--   O_Err_Msg         output parameter for errors
--   i_org_id          organization
--   i_cost_type       target cost type
--   i_range           All items, specific item, item range, category range
--   i_specific_item   Will contain an inventory_item_id
--   i_category_set    Contains the category set ID # for the category set the user selected
--   i_cat_strct       Contains the default category_structure assigned to the above category set
--   i_category_from   Contains the category ID for the FROM category that the user selected
--   i_category_to     Contains the category ID for the TO category that the user selected
--   i_item_from       A character string containing the flexfield concatenated segs (segment1||...)
--   i_item_to         A character string containing the flexfield concatenated segs (segment1||...)
--   i_copy_option     Choices are: 1. From system item definition - meaning copy the fields from the
--                     MSI table for the chosen item(s) and organization.
--                     2. From cost type - meaning copy the fields from the CIC table for the chosen
--                     item(s), organization, and cost type.
--   i_co_dummy        NULL unless copy option = From cost type (used to enable the src_cost_type param)
--   i_src_cost_type   Source cost type when copy option = From cost type
--   i_bor_flag        Based on rollup flag setting (flag indicating whether cost is rolled up):
--                     1 = Set to 1(YES), 2 = Set to 2(NO), 3 = Copy(from MSI or CIC), 4 = keep current
--   i_def_flag        Defaulted flag setting (flag indicating whether the cost of the item is
--                     defaulted from the default cost type during cost rollup):
--                     1 = Set to 1(YES), 2 = Set to 2(NO), 3 = Copy(from CIC), 4 = keep current
--   i_lotsz_lov       Selection made from lot size LOV: 1 = Set to #(which is provided in i_lot_size)
--                     2 = Copy (from MSI or CIC), 3 = keep current
--   i_lot_size        lot size (ignored unless the lot size selection = 1)
--
-- End of comments

procedure set_cost_controls (
  O_Err_Num         OUT NOCOPY  NUMBER,
  O_Err_Msg         OUT NOCOPY  VARCHAR2,
  i_org_id          IN          NUMBER,
  i_cost_type       IN          NUMBER,
  i_range           IN          NUMBER,
  i_item_dummy      IN          NUMBER,
  i_specific_item   IN          NUMBER,
  i_category_set    IN          NUMBER,
  i_cat_strct       IN          NUMBER,
  i_category_from   IN          VARCHAR2,
  i_category_to     IN          VARCHAR2,
  i_item_from       IN          VARCHAR2,
  i_item_to         IN          VARCHAR2,
  i_copy_option     IN          NUMBER,
  i_co_dummy        IN          NUMBER,
  i_src_cost_type   IN          NUMBER,
  i_bor_flag        IN          NUMBER,
  i_def_flag        IN          NUMBER,
  i_lotsz_lov       IN          NUMBER,
  i_lot_size        IN          NUMBER
)
IS

-- the following 5 variables get WHO info from global FND variables
l_request_id      NUMBER;
l_user_id         NUMBER;
l_login_id        NUMBER;
l_pgm_app_id      NUMBER;
l_pgm_id          NUMBER;

l_stmt_num        NUMBER := 0;   -- keeps track of position in program
l_err_msg         VARCHAR2(240); -- stores any error message
l_num_CIC_rows    NUMBER := 0;   -- number of rows updated in CIC
l_num_CICD_rows   NUMBER := 0;   -- number of rows updated in CICD

CONC_STATUS       BOOLEAN;       -- variable for SET_COMPLETION_STATUS

-- the following datatype holds the BULK COLLECTed item list
TYPE ItemList IS TABLE OF cst_item_costs.inventory_item_id%TYPE;

l_items ItemList; -- Collection of items that will generate warnings due to
                  -- shrinkage_rate/BOR conflicts and defaulted_flag conflicts
l_nonzero_shrinkage   NUMBER;   -- the number of such items

-- The next three variables are used to print a warning message with the
-- fnd_message utilities.
l_orgcode  mtl_parameters.organization_code%TYPE := NULL;
l_costtype  cst_cost_types.cost_type%TYPE := NULL;
l_itemname  mtl_system_items_kfv.concatenated_segments%TYPE;

BEGIN

  -- Start of program SAVEPOINT
  SAVEPOINT set_cost_controls_PUB;

  -- Get identifying information from global variables
  l_request_id          := FND_GLOBAL.conc_request_id;
  l_user_id             := FND_GLOBAL.user_id;
  l_login_id            := FND_GLOBAL.login_id;
  l_pgm_app_id          := FND_GLOBAL.PROG_APPL_ID;
  l_pgm_id              := FND_GLOBAL.CONC_PROGRAM_ID;

  -- Write descriptive info to log file
  fnd_file.put_line(fnd_file.log,'Request ID: '||to_char(l_request_id));
  fnd_file.put_line(fnd_file.log,'PARAMETERS');
  fnd_file.put_line(fnd_file.log,'Organization ID: '||to_char(i_org_id));
  fnd_file.put_line(fnd_file.log,'Cost Type: '||to_char(i_cost_type));
  fnd_file.put_line(fnd_file.log,'Range: '||to_char(i_range));
  fnd_file.put_line(fnd_file.log,'Specific item: '||to_char(i_specific_item));
  fnd_file.put_line(fnd_file.log,'Item From: '||i_item_from);
  fnd_file.put_line(fnd_file.log,'Item To: '||i_item_to);
  fnd_file.put_line(fnd_file.log,'Category Set: '||to_char(i_category_set));
  fnd_file.put_line(fnd_file.log,'Category struct: '||to_char(i_cat_strct));
  fnd_file.put_line(fnd_file.log,'Category From: '||i_category_from);
  fnd_file.put_line(fnd_file.log,'Category To: '||i_category_to);
  fnd_file.put_line(fnd_file.log,'Copy Option: '||to_char(i_copy_option));
  fnd_file.put_line(fnd_file.log,'CO Dummy: '||to_char(i_co_dummy));
  fnd_file.put_line(fnd_file.log,'Src Cost Type: '||to_char(i_src_cost_type));
  fnd_file.put_line(fnd_file.log,'Based On Rollup: '||to_char(i_bor_flag));
  fnd_file.put_line(fnd_file.log,'Defaulted Flag: '||to_char(i_def_flag));
  fnd_file.put_line(fnd_file.log,'Lot Size Selection: '||to_char(i_lotsz_lov));
  fnd_file.put_line(fnd_file.log,'Lot Size: '||to_char(i_lot_size));


  if (i_bor_flag <> 3 AND i_def_flag <> 3 AND i_lotsz_lov <> 2) then
  -- Update CIC in the case where none of the fields are copied - avoids superfluous subquery in SET stmt

    l_stmt_num := 10;
    UPDATE cst_item_costs cic
    SET  based_on_rollup_flag = decode(i_bor_flag, 1,1, 2,2, 4,cic.BASED_ON_ROLLUP_FLAG, NULL),
     defaulted_flag = decode(i_def_flag, 1,1, 2,2, 4,cic.DEFAULTED_FLAG, NULL),
         lot_size = decode(i_lotsz_lov, 1,nvl(i_lot_size,cic.LOT_SIZE), 3,cic.LOT_SIZE, NULL),
         last_update_date = sysdate,
         last_updated_by = l_user_id,
         last_update_login = l_login_id,
         request_id = l_request_id,
         program_application_id = l_pgm_app_id,
         program_id = l_pgm_id,
         program_update_date = sysdate
    WHERE cic.cost_type_id = i_cost_type
    AND cic.organization_id = i_org_id
    AND (i_range = 1
     OR (i_range = 2
         AND cic.inventory_item_id = i_specific_item)
     OR (i_range = 3
         AND cic.inventory_item_id IN
          (SELECT msi1.inventory_item_id
           FROM mtl_system_items_kfv msi1
           WHERE msi1.concatenated_segments BETWEEN i_item_from AND i_item_to))
     OR (i_range = 5
         AND cic.inventory_item_id IN
          (SELECT msi2.inventory_item_id
           FROM mtl_system_items msi2, mtl_item_categories mic, mtl_categories_kfv mc
           WHERE mic.organization_id = i_org_id
           AND mic.category_set_id = i_category_set
           AND mic.inventory_item_id = msi2.inventory_item_id
           AND mic.organization_id = msi2.organization_id
           AND mic.category_id = mc.category_id
           AND mc.concatenated_segments BETWEEN i_category_from AND i_category_to)));

  elsif (i_copy_option = 1) then
  -- Update CIC where some fields are copied from MSI and others keep current settings

    l_stmt_num := 20;
    UPDATE cst_item_costs cic
    SET (based_on_rollup_flag,
     defaulted_flag,
     lot_size,
         last_update_date,
         last_updated_by,
         last_update_login,
         request_id,
         program_application_id,
         program_id,
         program_update_date) =
     (SELECT decode(i_bor_flag, 1,1, 2,2, 3,nvl(msi.PLANNING_MAKE_BUY_CODE,cic.BASED_ON_ROLLUP_FLAG),
                                          4,cic.BASED_ON_ROLLUP_FLAG, NULL),
             decode(i_def_flag, 1,1, 2,2, 4,cic.DEFAULTED_FLAG, NULL),
             decode(i_lotsz_lov, 1,nvl(i_lot_size,cic.LOT_SIZE), 2,nvl(msi.STD_LOT_SIZE,cic.LOT_SIZE),
                                               3,cic.LOT_SIZE, NULL),
         sysdate,
         l_user_id,
         l_login_id,
         l_request_id,
         l_pgm_app_id,
         l_pgm_id,
         sysdate
      FROM mtl_system_items msi
      WHERE msi.organization_id = cic.organization_id
      AND msi.inventory_item_id = cic.inventory_item_id)
    WHERE cic.cost_type_id = i_cost_type
    AND cic.organization_id = i_org_id
    AND (i_range = 1
     OR (i_range = 2
         AND cic.inventory_item_id = i_specific_item)
     OR (i_range = 3
         AND cic.inventory_item_id IN
          (SELECT msi1.inventory_item_id
           FROM mtl_system_items_kfv msi1
           WHERE msi1.concatenated_segments BETWEEN i_item_from AND i_item_to))
     OR (i_range = 5
         AND cic.inventory_item_id IN
          (SELECT msi2.inventory_item_id
           FROM mtl_system_items msi2, mtl_item_categories mic, mtl_categories_kfv mc
           WHERE mic.organization_id = i_org_id
           AND mic.category_set_id = i_category_set
           AND mic.inventory_item_id = msi2.inventory_item_id
           AND mic.organization_id = msi2.organization_id
           AND mic.category_id = mc.category_id
           AND mc.concatenated_segments BETWEEN i_category_from AND i_category_to)));

  elsif (i_copy_option = 2) then
  -- Update CIC where some fields are copied from src cost type and others keep current settings

    l_stmt_num := 30;
    UPDATE cst_item_costs cic
    SET (based_on_rollup_flag,
     defaulted_flag,
     lot_size,
         last_update_date,
         last_updated_by,
         last_update_login,
         request_id,
         program_application_id,
         program_id,
         program_update_date) =
     (SELECT decode(i_bor_flag, 1,1, 2,2, 3,nvl(cic1.BASED_ON_ROLLUP_FLAG,cic2.BASED_ON_ROLLUP_FLAG),
                                          4,cic2.BASED_ON_ROLLUP_FLAG, NULL),
             decode(i_def_flag, 1,1, 2,2, 3,nvl(cic1.DEFAULTED_FLAG,cic2.DEFAULTED_FLAG),
                                          4,cic2.DEFAULTED_FLAG, NULL),
             decode(i_lotsz_lov, 1,nvl(i_lot_size,cic2.LOT_SIZE), 2,nvl(cic1.LOT_SIZE,cic2.LOT_SIZE),
                                               3,cic2.LOT_SIZE, NULL),
         sysdate,
         l_user_id,
         l_login_id,
         l_request_id,
         l_pgm_app_id,
         l_pgm_id,
         sysdate
      FROM cst_item_costs cic1, cst_item_costs cic2
      WHERE cic2.organization_id = cic.organization_id
      AND cic2.inventory_item_id = cic.inventory_item_id
      AND cic2.cost_type_id = cic.cost_type_id
      AND cic1.organization_id (+) = cic2.organization_id
      AND cic1.inventory_item_id (+) = cic2.inventory_item_id
      AND cic1.cost_type_id (+) = i_src_cost_type)
    WHERE cic.cost_type_id = i_cost_type
    AND cic.organization_id = i_org_id
    AND (i_range = 1
     OR (i_range = 2
         AND cic.inventory_item_id = i_specific_item)
     OR (i_range = 3
         AND cic.inventory_item_id IN
          (SELECT msi1.inventory_item_id
           FROM mtl_system_items_kfv msi1
           WHERE msi1.concatenated_segments BETWEEN i_item_from AND i_item_to))
     OR (i_range = 5
         AND cic.inventory_item_id IN
          (SELECT msi2.inventory_item_id
           FROM mtl_system_items msi2, mtl_item_categories mic, mtl_categories_kfv mc
           WHERE mic.organization_id = i_org_id
           AND mic.category_set_id = i_category_set
           AND mic.inventory_item_id = msi2.inventory_item_id
           AND mic.organization_id = msi2.organization_id
           AND mic.category_id = mc.category_id
           AND mc.concatenated_segments BETWEEN i_category_from AND i_category_to)));

  end if;

  l_num_CIC_rows := SQL%ROWCOUNT;
  fnd_file.put_line(fnd_file.log,'');
  fnd_file.put_line(fnd_file.log,'Updated '||to_char(l_num_CIC_rows)||' rows in cst_item_costs.');

  if (i_bor_flag = 1 OR i_bor_flag = 3) then
  -- Based On Rollup may have been updated to YES, print a NOTE message
    fnd_file.put_line(fnd_file.log,'');
    fnd_message.set_name('BOM', 'CST_SCC_SHRINKAGE_NOTE');
    fnd_file.put_line(fnd_file.log, fnd_message.get);
  end if;

  if (i_lotsz_lov = 2 OR (i_lotsz_lov = 1 AND i_lot_size IS NOT NULL)) then
  -- Update CICD usage rate and basis factor with new lot size information
  -- Only rows where basis_type = 2 (lot) and level_type = 1 (this level) should be touched
  -- Adjust usage rate: new usage rate = old usage rate * (old basis factor / new basis factor)
  -- Adjust basis factor: new basis factor = 1 / new lot size
    l_stmt_num := 40;
    UPDATE cst_item_cost_details cicd
    SET (cicd.basis_factor,
         cicd.usage_rate_or_amount,
         last_update_date,
         last_updated_by,
         last_update_login,
         request_id,
         program_application_id,
         program_id,
         program_update_date) =
      (SELECT nvl( (1/cic.lot_size), cicd.basis_factor),
             nvl( (cicd.usage_rate_or_amount * cicd.basis_factor * cic.lot_size), cicd.usage_rate_or_amount),
             sysdate,
             l_user_id,
             l_login_id,
             l_request_id,
             l_pgm_app_id,
             l_pgm_id,
             sysdate
       FROM cst_item_costs cic
       WHERE cic.organization_id = cicd.organization_id
       AND cic.cost_type_id = cicd.cost_type_id
       AND cic.inventory_item_id = cicd.inventory_item_id)
    WHERE cicd.cost_type_id = i_cost_type
    AND cicd.organization_id = i_org_id
    AND (i_range = 1
     OR (i_range = 2
         AND cicd.inventory_item_id = i_specific_item)
     OR (i_range = 3
         AND cicd.inventory_item_id IN
          (SELECT msi1.inventory_item_id
           FROM mtl_system_items_kfv msi1
           WHERE msi1.concatenated_segments BETWEEN i_item_from AND i_item_to))
     OR (i_range = 5
         AND cicd.inventory_item_id IN
          (SELECT msi2.inventory_item_id
           FROM mtl_system_items msi2, mtl_item_categories mic, mtl_categories_kfv mc
           WHERE mic.organization_id = i_org_id
           AND mic.category_set_id = i_category_set
           AND mic.inventory_item_id = msi2.inventory_item_id
           AND mic.organization_id = msi2.organization_id
           AND mic.category_id = mc.category_id
           AND mc.concatenated_segments BETWEEN i_category_from AND i_category_to)))
    AND cicd.basis_type = 2
    AND cicd.level_type = 1;

    l_num_CICD_rows := SQL%ROWCOUNT;
    fnd_file.put_line(fnd_file.log,'Updated '||to_char(l_num_CICD_rows)||' rows in cst_item_cost_details for lotsize.');

  end if;  -- end of lot size change affecting CICD

  if (i_bor_flag = 2 OR i_bor_flag = 3) then
  -- Now the based_on_rollup_flag may have been set to NO for some records where
  -- the shrinkage_rate <> 0.  This is illegal.  Reset the shrinkage_rate for such
  -- rows back to 0 (effectively removing shrinkage rate).  The RETURNING clause
  -- captures the list of inventory_item_ids for which the shrinkage rate was
  -- reset.  Note that costs will not be changed for affected items.  Instead, the
  -- usage_rate_or_amount in CICD will be adjusted to keep it consistent with the cost
  -- and the new net_yield_or_shrinkage_factor.
    l_stmt_num := 50;
    UPDATE cst_item_costs cic
    SET cic.shrinkage_rate = 0
    WHERE cic.cost_type_id = i_cost_type
    AND cic.organization_id = i_org_id
    AND (i_range = 1
     OR (i_range = 2
         AND cic.inventory_item_id = i_specific_item)
     OR (i_range = 3
         AND cic.inventory_item_id IN
          (SELECT msi1.inventory_item_id
           FROM mtl_system_items_kfv msi1
           WHERE msi1.concatenated_segments BETWEEN i_item_from AND i_item_to))
     OR (i_range = 5
         AND cic.inventory_item_id IN
          (SELECT msi2.inventory_item_id
           FROM mtl_system_items msi2, mtl_item_categories mic, mtl_categories_kfv mc
           WHERE mic.organization_id = i_org_id
           AND mic.category_set_id = i_category_set
           AND mic.inventory_item_id = msi2.inventory_item_id
           AND mic.organization_id = msi2.organization_id
           AND mic.category_id = mc.category_id
           AND mc.concatenated_segments BETWEEN i_category_from AND i_category_to)))
    AND cic.shrinkage_rate <> 0
    AND cic.based_on_rollup_flag = 2
    RETURNING cic.inventory_item_id BULK COLLECT INTO l_items;

    l_nonzero_shrinkage := l_items.COUNT;

    if (l_nonzero_shrinkage > 0) then
    -- print a warning message to the log file and set the request status to WARNING - yellow highlight
      fnd_file.put_line(fnd_file.log,'');
      fnd_message.set_name('BOM', 'CST_SCC_SHRINKAGE_TO_ZERO');
      fnd_message.set_token('NUMBER', to_char(l_nonzero_shrinkage));

      select organization_code
      into l_orgcode
      from mtl_parameters
      where organization_id = i_org_id;
      fnd_message.set_token('ORG', l_orgcode);

      select cost_type
      into l_costtype
      from cst_cost_types
      where cost_type_id = i_cost_type;
      fnd_message.set_token('CT', l_costtype);
      fnd_file.put_line(fnd_file.log, fnd_message.get);

      FOR i in 1..l_nonzero_shrinkage LOOP
        select concatenated_segments
        into l_itemname
        from mtl_system_items_kfv
        where organization_id = i_org_id
        and inventory_item_id = l_items(i);
        fnd_file.put_line(fnd_file.log, l_itemname);
      END LOOP;
      fnd_file.put_line(fnd_file.log,'');

    -- Now update the usage_rate_or_amount and the net_yield_or_shrinkage_factor in CICD
      l_stmt_num := 60;
      FORALL i in l_items.FIRST..l_items.LAST
        UPDATE cst_item_cost_details
        SET usage_rate_or_amount = (usage_rate_or_amount * net_yield_or_shrinkage_factor),
            net_yield_or_shrinkage_factor = 1,
            last_update_date = sysdate,
            last_updated_by = l_user_id,
            last_update_login = l_login_id,
            request_id = l_request_id,
            program_application_id = l_pgm_app_id,
            program_id = l_pgm_id,
            program_update_date = sysdate
        WHERE cost_type_id = i_cost_type
        AND organization_id = i_org_id
        AND inventory_item_id = l_items(i);

      fnd_file.put_line(fnd_file.log,'Updated '||to_char(SQL%ROWCOUNT)||' rows in cst_item_cost_details related to the shrinkage rate.');

      l_err_msg := 'Forcing shrinkage rate to 0';
      CONC_STATUS := FND_CONCURRENT.SET_COMPLETION_STATUS('WARNING',l_err_msg);
    end if;
  end if; -- end of based on rollup affecting shrinkage rate

  if (i_def_flag = 1 or i_def_flag = 3) then
  -- The defaulted_flag cannot be updated to YES for items with user defined costs, or for items that
  -- do not exist in the default cost type.  The defaulted_flag should be set back to NO for these
  -- rows in CIC.

    l_stmt_num := 70;
    if l_items.EXISTS(1) then
      l_items.DELETE; -- reset the collection
    end if;

    UPDATE cst_item_costs cic
    SET cic.defaulted_flag = 2
    WHERE cic.cost_type_id = i_cost_type
    AND cic.organization_id = i_org_id
    AND (i_range = 1
     OR (i_range = 2
         AND cic.inventory_item_id = i_specific_item)
     OR (i_range = 3
         AND cic.inventory_item_id IN
          (SELECT msi1.inventory_item_id
           FROM mtl_system_items_kfv msi1
           WHERE msi1.concatenated_segments BETWEEN i_item_from AND i_item_to))
     OR (i_range = 5
         AND cic.inventory_item_id IN
          (SELECT msi2.inventory_item_id
           FROM mtl_system_items msi2, mtl_item_categories mic, mtl_categories_kfv mc
           WHERE mic.organization_id = i_org_id
           AND mic.category_set_id = i_category_set
           AND mic.inventory_item_id = msi2.inventory_item_id
           AND mic.organization_id = msi2.organization_id
           AND mic.category_id = mc.category_id
           AND mc.concatenated_segments BETWEEN i_category_from AND i_category_to)))
    AND cic.defaulted_flag = 1
    AND (EXISTS (SELECT 'X'
                 FROM cst_item_cost_details cicd
                 WHERE cicd.organization_id = cic.organization_id
                 AND cicd.cost_type_id = cic.cost_type_id
                 AND cicd.inventory_item_id = cic.inventory_item_id
                 AND cicd.rollup_source_type = 1) -- user defined
         OR NOT EXISTS (SELECT 'X'
                 FROM cst_item_costs cic1, cst_cost_types cct
                 WHERE cic1.organization_id = cic.organization_id
                 AND cic1.cost_type_id = cct.default_cost_type_id
                 AND cct.cost_type_id = cic.cost_type_id
                 AND cic1.inventory_item_id = cic.inventory_item_id))
    RETURNING cic.inventory_item_id BULK COLLECT INTO l_items;

  -- print warning CANNOT UPDATE DEFAULT_FLAG!!!!
    if (l_items.COUNT > 0) then
      fnd_file.put_line(fnd_file.log,'');
      fnd_message.set_name('BOM', 'CST_SCC_CANT_UPDT_DEFAULT');
      fnd_message.set_token('NUMBER', to_char(l_items.COUNT));

      if (l_orgcode IS NULL) then
        select organization_code
        into l_orgcode
        from mtl_parameters
        where organization_id = i_org_id;
      end if;
      fnd_message.set_token('ORG', l_orgcode);

      if (l_costtype IS NULL) then
        select cost_type
        into l_costtype
        from cst_cost_types
        where cost_type_id = i_cost_type;
      end if;
      fnd_message.set_token('CT', l_costtype);
      fnd_file.put_line(fnd_file.log, fnd_message.get);

      FOR i in 1..l_items.COUNT LOOP
        select concatenated_segments
        into l_itemname
        from mtl_system_items_kfv
        where organization_id = i_org_id
        and inventory_item_id = l_items(i);
        fnd_file.put_line(fnd_file.log, l_itemname);
      END LOOP;
      fnd_file.put_line(fnd_file.log,'');

      l_err_msg := 'Cannot update defaulted_flag to YES';
      CONC_STATUS := FND_CONCURRENT.SET_COMPLETION_STATUS('WARNING',l_err_msg);
    end if;

  end if;

  if (i_def_flag = 2 or i_def_flag = 3) then
  -- When the defaulted flag is updated to NO, any subcosts with a source type of defaulted
  -- should be changed to user defined.
    l_stmt_num := 80;

    UPDATE cst_item_cost_details cicd
    SET cicd.rollup_source_type = 1
    WHERE cicd.rollup_source_type = 2
    AND cicd.cost_type_id = i_cost_type
    AND cicd.organization_id = i_org_id
    AND (i_range = 1
     OR (i_range = 2
         AND cicd.inventory_item_id = i_specific_item)
     OR (i_range = 3
         AND cicd.inventory_item_id IN
          (SELECT msi1.inventory_item_id
           FROM mtl_system_items_kfv msi1
           WHERE msi1.concatenated_segments BETWEEN i_item_from AND i_item_to))
     OR (i_range = 5
         AND cicd.inventory_item_id IN
          (SELECT msi2.inventory_item_id
           FROM mtl_system_items msi2, mtl_item_categories mic, mtl_categories_kfv mc
           WHERE mic.organization_id = i_org_id
           AND mic.category_set_id = i_category_set
           AND mic.inventory_item_id = msi2.inventory_item_id
           AND mic.organization_id = msi2.organization_id
           AND mic.category_id = mc.category_id
           AND mc.concatenated_segments BETWEEN i_category_from AND i_category_to)))
    AND EXISTS (SELECT 'X'
                FROM cst_item_costs cic
                WHERE cic.organization_id = cicd.organization_id
                AND cic.cost_type_id = cicd.cost_type_id
                AND cic.inventory_item_id = cicd.inventory_item_id
                AND cic.defaulted_flag = 2);

    fnd_file.put_line(fnd_file.log,'Updated '||to_char(SQL%ROWCOUNT)||' rows in cst_item_cost_details making them user-defined.');
  end if;


  commit;

  O_Err_Num := 0;
  O_Err_Msg := '';

EXCEPTION

  when others then
    l_err_msg := 'CSTPUMEC.set_cost_controls - error in statement '||to_char(l_stmt_num)||': '|| substrb(SQLERRM,1,150);
    fnd_file.put_line(fnd_file.log,l_err_msg);
    fnd_file.put_line(fnd_file.log,'All changes rolled back.');
    CONC_STATUS := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR',l_err_msg);
    O_Err_Num := SQLCODE;
    O_Err_Msg := l_err_msg;
    ROLLBACK TO SAVEPOINT set_cost_controls_PUB;

END set_cost_controls;

END CSTPUMEC;
/
