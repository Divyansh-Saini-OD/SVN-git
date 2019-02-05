CREATE OR REPLACE PACKAGE BODY "APPS"."INVPCOII" AS
/* $Header: INVPCOIB.pls 115.14.115100.2 2005/12/01 13:38:29 shchandr ship $ */

l_location NUMBER;

/*======================================================================*/
/* Function : CSTFVSUB                                                  */
/*                                                                      */
/* Description :                                                        */
/*   Validate the sub element                                           */
/*   If the org is average cost and there should be value for           */
/*   material overhead sub element                                      */
/*                                                                      */
/* Note :                                                               */
/*  I_COST_ELEMENT_ID : 1 Material                                      */
/*                      2 Material Overhead                             */
/*06MAY96 NPARATE                                                       */
/*This function does not need xset_id parameter since processing        */
/*done using transaction_id which is unique enough in MSII              */
/*======================================================================*/

FUNCTION CSTFVSUB (
I_TRANSID IN NUMBER,
     I_MATERIAL_SUB_ELEM IN VARCHAR2 DEFAULT NULL,
     I_MATERIAL_OH_SUB_ELEM IN VARCHAR2 DEFAULT NULL,
I_ORGANIZATION_ID IN NUMBER,
I_USER_ID IN NUMBER := -1,
I_LOGIN_ID IN NUMBER := -1,
I_REQ_ID IN NUMBER := -1,
I_PRGM_ID IN NUMBER := -1,
I_PRGM_APPL_ID IN NUMBER := -1,
O_ERR_TEXT IN OUT NOCOPY  VARCHAR2)
RETURN INTEGER IS

l_material_sub_elem VARCHAR2(10);
l_material_oh_sub_elem VARCHAR2(10);
l_organization_id NUMBER;
l_material_sub_elem_id NUMBER;
l_material_oh_sub_elem_id NUMBER;
l_cost_type_id NUMBER;
l_cost_organization_id NUMBER;
l_transaction_id NUMBER;
l_status NUMBER;
l_error_msg VARCHAR2(240);

BEGIN
O_ERR_TEXT := ' ';
l_error_msg := ' ';
l_material_sub_elem_id := 0;
l_material_oh_sub_elem_id := 0;

l_location := 100;

/* Bug 4705184. Get these values as parameters instead of querying
    select material_sub_elem,
           material_oh_sub_elem,
           organization_id,
           transaction_id
    into   l_material_sub_elem,
           l_material_oh_sub_elem,
           l_organization_id,
           l_transaction_id
    from   mtl_system_items_interface
    where  transaction_id = I_TRANSID;  */

l_material_sub_elem := I_MATERIAL_SUB_ELEM;
l_material_oh_sub_elem := I_MATERIAL_OH_SUB_ELEM;
l_organization_id := I_ORGANIZATION_ID;
l_transaction_id := I_TRANSID;

l_location := 105;
select primary_cost_method,
cost_organization_id
into l_cost_type_id,
l_cost_organization_id
from mtl_parameters
where organization_id = l_organization_id;

/* Material Sub element */
If (l_material_sub_elem is not NULL) Then
l_location := 110;
select resource_id
into l_material_sub_elem_id
from bom_resources br
where br.resource_code = l_material_sub_elem
and br.organization_id = l_cost_organization_id
and br.cost_code_type = 1;
End if;

/* moh valid for frozen std costing only */
If (l_cost_type_id = 1) Then
/* Material overhead sub element */
If (l_material_oh_sub_elem is not NULL) Then
l_location := 120;
select resource_id
into l_material_oh_sub_elem_id
from bom_resources br
where br.resource_code = l_material_oh_sub_elem
and br.organization_id = l_cost_organization_id
and br.cost_code_type = 2;
End if;
Else
If (l_material_oh_sub_elem is not NULL) Then
l_error_msg := 'CST- Average cost could not have material overhead';
l_status := INVPUOPI.mtl_log_interface_err(
l_organization_id,
I_USER_ID,
I_LOGIN_ID,
I_PRGM_APPL_ID,
I_PRGM_ID,
I_REQ_ID,
l_transaction_id,
l_error_msg,
             null,
'MTL_SYSTEM_ITEMS_INTERFACE',
'CST_INVALID_MOH_AVE',
O_ERR_TEXT);
return(1);
End if;
End if;

/* Update mtl_system_items_interface
    ** NP 06MAY96: Does not require the xset_id since transaction_id
    ** is unique to each row in MSII even though there may be multiple
    ** parallel IOI processes
    */
l_location := 130;

-- Bug 4705184. Update only when value exists
    if (l_material_sub_elem_id <> 0 or l_material_oh_sub_elem_id <> 0) then
      update mtl_system_items_interface
      set    material_sub_elem_id = decode(l_material_sub_elem_id,
                                           0,NULL,l_material_sub_elem_id),
             material_oh_sub_elem_id = decode(l_material_oh_sub_elem_id,
                                           0,NULL,l_material_oh_sub_elem_id)
      where  transaction_id = I_TRANSID;
    end if;

    return(0);

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
         if (l_location = 110) then
            l_error_msg := 'CST- Material Sub Element does not exist in costing org '||
                           to_char(l_cost_organization_id);
            l_status := INVPUOPI.mtl_log_interface_err(
                           l_organization_id,
                           I_USER_ID,
                           I_LOGIN_ID,
                           I_PRGM_APPL_ID,
                           I_PRGM_ID,
                           I_REQ_ID,
                           l_transaction_id,
                           l_error_msg,
               null,
                           'MTL_SYSTEM_ITEMS_INTERFACE',
                           'CST_INVALID_MAT_SUB',
                            O_ERR_TEXT);
         else
            l_error_msg := 'CST- Material Overhead Sub Element does not exist in costing org '||
                           to_char(l_cost_organization_id);
            l_status := INVPUOPI.mtl_log_interface_err(
                           l_organization_id,
                           I_USER_ID,
                           I_LOGIN_ID,
                           I_PRGM_APPL_ID,
                           I_PRGM_ID,
                           I_REQ_ID,
                           l_transaction_id,
                           l_error_msg,
               null,
                           'MTL_SYSTEM_ITEMS_INTERFACE',
                           'CST_INVALID_MOH_SUB',
                            O_ERR_TEXT);
         end if;
         return (1);
    WHEN OTHERS THEN
         O_ERR_TEXT := substr('CSTFVSUB - '||to_char(l_location)||' : '||SQLERRM,1, 240);
         return(SQLCODE);

END CSTFVSUB;


/*======================================================================*/
/* Procedure: CSTPIICD                                                  */
/*                                                                      */
/* Description :                                                        */
/*   Insert material and material overhead cost into                    */
/*   cst_item_cost_details                                              */
/*                                                                      */
/*                                                                      */
/* Note :                                                               */
/*  The basis type will default to the following if one is not define   */
/*  by the user in the bom_resources table.             */
/*  I_COST_ELEMENT_ID : 1 Material          item basis                  */
/*                      2 Material Overhead total value basis           */
/*  For average costing, there is no material overhead concept          */
/*  Assume that the record does not exist yet                           */
/*                                                                      */
/*======================================================================*/

PROCEDURE CSTPIICD (
         I_ORGANIZATION_ID      IN      NUMBER,
         I_INVENTORY_ITEM_ID    IN      NUMBER,
         I_COST_ELEMENT_ID      IN      NUMBER,
         I_COST_RATE            IN      NUMBER,
         I_RESOURCE_ID          IN      NUMBER,
         I_USER_ID              IN      NUMBER,
         I_LOGIN_ID             IN      NUMBER,
         I_REQ_ID               IN      NUMBER,
         I_PRGM_ID              IN      NUMBER,
         I_PRGM_APPL_ID         IN      NUMBER,
         O_RETURN_CODE          OUT     NOCOPY  NUMBER,
         O_ERR_TEXT             IN OUT  NOCOPY  VARCHAR2) IS
l_basis_type    NUMBER;
cost_update     NUMBER;
BEGIN
   O_ERR_TEXT    := ' ';
   O_RETURN_CODE := -99999;
   l_location    := 199;

   select nvl(default_basis_type,decode(i_cost_element_id,1,1,2,5,0))
   into l_basis_type
   from bom_resources
   where resource_id = i_resource_id;

   l_location    := 200;

/* Added delete st for bug 3219632 */

   delete from cst_item_cost_details cicd
   where  cicd.ORGANIZATION_ID = I_ORGANIZATION_ID
   AND  cicd.INVENTORY_ITEM_ID = I_INVENTORY_ITEM_ID
   AND  cicd.COST_ELEMENT_ID = I_COST_ELEMENT_ID;

/* End of bug fix 3219632 */

   insert into cst_item_cost_details
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
   select i_inventory_item_id,               -- inventory_item_id
       i_organization_id,                    -- organization_id
       mp.primary_cost_method,               -- cost_type_id
       sysdate,                              -- last_update_date
       I_USER_ID,                            -- last_updated_by
       sysdate,                              -- creation_date
       I_USER_ID,                            -- created_by
       I_LOGIN_ID,                           -- last_update_login
       NULL,                                 -- operation_sequence_id
       NULL,                                 -- operation_seq_num
       NULL,                                 -- department_id
       1,                                    -- level_type
       NULL,                                 -- activity_id
       NULL,                                 -- resource_seq_num
       I_RESOURCE_ID,                        -- resource_id
       NULL,                                 -- resource_rate
       NULL,                                 -- item_units
       NULL,                                 -- activity_units
       nvl(I_COST_RATE,0),                   -- usage_rate_or_amount
       l_basis_type,                         -- basis_type
       NULL,                                 -- basis_resource_id
       1,                                    -- basis_factor
       1,                                    -- net_yield_or_shrinkage_factor
       decode(l_basis_type,
           5,0,nvl(I_COST_RATE,0)),      -- item_cost
       I_COST_ELEMENT_ID,                    -- cost_element_id
       1,                                    -- rollup_source_type
       NULL,                                 -- activity_context
       I_REQ_ID,                             -- request_id
       I_PRGM_APPL_ID,                       -- program_application_id
       I_PRGM_ID,                            -- program_id
       NULL,                                 -- program_update_date
       NULL,                                 -- attribute_category
       NULL,                                 -- attribute1
       NULL,                                 -- attribute2
       NULL,                                 -- attribute3
       NULL,                                 -- attribute4
       NULL,                                 -- attribute5
       NULL,                                 -- attribute6
       NULL,                                 -- attribute7
       NULL,                                 -- attribute8
       NULL,                                 -- attribute9
       NULL,                                 -- attribute10
       NULL,                                 -- attribute11
       NULL,                                 -- attribute12
       NULL,                                 -- attribute13
       NULL,                                 -- attribute14
       NULL                                  -- attribute15
      from mtl_parameters mp
      where mp.organization_id    = i_organization_id;

      Select cst_lists_s.nextval
      INTO cost_update
      From DUAL;


      INSERT INTO cst_standard_costs
        (cost_update_id, organization_id,
         inventory_item_id,
         last_update_date, last_updated_by,
         creation_date, created_by, last_update_login,
         standard_cost_revision_date, standard_cost)
      SELECT cost_update, I_ORGANIZATION_ID,
             I_INVENTORY_ITEM_ID,
             SYSDATE, I_USER_ID,
             SYSDATE, I_USER_ID, I_LOGIN_ID,
             SYSDATE,  NVL(SUM(cicd.item_cost),0)
      FROM cst_item_cost_details cicd, mtl_parameters mp
      WHERE cicd.ORGANIZATION_ID = I_ORGANIZATION_ID
      AND  cicd.INVENTORY_ITEM_ID = I_INVENTORY_ITEM_ID
      AND  cicd.COST_TYPE_ID = mp.primary_cost_method
      AND  mp.ORGANIZATION_ID = I_ORGANIZATION_ID;


      INSERT INTO cst_elemental_costs
         (cost_update_id, organization_id, inventory_item_id, cost_element_id,
          last_update_date, last_updated_by, creation_date, created_by,
          last_update_login, standard_cost)
      SELECT cost_update, I_ORGANIZATION_ID,
             I_INVENTORY_ITEM_ID, cicd.cost_element_id,
             SYSDATE, I_USER_ID,
             SYSDATE, I_USER_ID, I_LOGIN_ID,
             NVL(SUM(cicd.item_cost),0)
      FROM cst_item_cost_details cicd, mtl_parameters mp
      WHERE cicd.ORGANIZATION_ID = I_ORGANIZATION_ID
      AND  cicd.INVENTORY_ITEM_ID = I_INVENTORY_ITEM_ID
      AND  cicd.COST_TYPE_ID = mp.primary_cost_method
      AND  mp.ORGANIZATION_ID = I_ORGANIZATION_ID
      GROUP BY cost_element_id;


      O_ERR_TEXT    := ' ';
      O_RETURN_CODE := 0;

EXCEPTION
       WHEN OTHERS THEN
          O_RETURN_CODE := SQLCODE;
          O_ERR_TEXT    := substr('CSTPIICD- '||to_char(l_location)||' : '||SQLERRM, 1, 240);
END CSTPIICD;

/*======================================================================*/
/* Procedure: CSTPPCOI                                                  */
/*                                                                      */
/* Description :                                                        */
/*                                                                      */
/*                                                                      */
/* Note :                                                               */
/*  I_COST_ELEMENT_ID : 1 Material          item basis                  */
/*                      2 Material Overhead total value basis           */
/*  For average costing, there is no material overhead concept          */
/*                                                                      */
/*======================================================================*/

PROCEDURE CSTPPCOI (
         I_ORGANIZATION_ID         IN      NUMBER,
         I_INVENTORY_ITEM_ID       IN      NUMBER,
         I_MATERIAL_COST           IN      NUMBER,
         I_MATERIAL_SUB_ELEM_ID    IN      NUMBER,
         I_MATERIAL_OH_RATE        IN      NUMBER,
         I_MATERIAL_OH_SUB_ELEM_ID IN      NUMBER,
         I_USER_ID                 IN      NUMBER,
         I_LOGIN_ID                IN      NUMBER,
         I_REQ_ID                  IN      NUMBER,
         I_PRGM_ID                 IN      NUMBER,
         I_PRGM_APPL_ID            IN      NUMBER,
         O_RETURN_CODE             OUT     NOCOPY   NUMBER,
         O_ERR_TEXT                IN OUT  NOCOPY   VARCHAR2) IS

   l_cost_type_id    NUMBER;
   l_return_status   NUMBER;
   l_return_err      VARCHAR2(240);
   l_status_mat      NUMBER;
   l_status_moh      NUMBER;
   l_list_id         NUMBER;

BEGIN

   O_RETURN_CODE := -99999;
   l_return_err  := ' ';

   /* Get the cost type id, either frozen or average */
   l_location := 400;
   select primary_cost_method
   into   l_cost_type_id
   from   mtl_parameters
   where  organization_id = I_ORGANIZATION_ID;

/* Moved call to CSTPIICC.CSTPIICI before  Material Cost Processing for bug 3219632 */
   /* Create default costing information */

   CSTPIICC.CSTPIICI( I_INVENTORY_ITEM_ID,
             I_ORGANIZATION_ID,
             I_USER_ID,
             l_return_status,
             l_return_err );

   If (l_return_status <> 0) Then
      O_RETURN_CODE  := 99999;
      O_ERR_TEXT     := l_return_err;
      return;
   End if;


   /**** Material Cost Processing *****/
   If (nvl(I_MATERIAL_SUB_ELEM_ID,0) > 0 ) Then

           INVPCOII.CSTPIICD (I_ORGANIZATION_ID ,
                              I_INVENTORY_ITEM_ID,
                              1,
                              I_MATERIAL_COST,
                              I_MATERIAL_SUB_ELEM_ID,
                              I_USER_ID,
                              I_LOGIN_ID,
                              I_REQ_ID,
                              I_PRGM_ID,
                              I_PRGM_APPL_ID,
                              l_status_mat,
                              l_return_err );
           If l_status_mat <> 0 Then
              O_RETURN_CODE := 99998;
              O_ERR_TEXT    := l_return_err;
              return;
           End if;

   End if; /* For material */


   /**** Material Cost Processing *****/
   /* Material Overhead Cost Processing for std costing only */
   If (l_cost_type_id = 1) then

       If (nvl(I_MATERIAL_OH_SUB_ELEM_ID,0) > 0) Then

           INVPCOII.CSTPIICD (I_ORGANIZATION_ID ,
                              I_INVENTORY_ITEM_ID,
                              2,
                              I_MATERIAL_OH_RATE,
                              I_MATERIAL_OH_SUB_ELEM_ID,
                              I_USER_ID,
                              I_LOGIN_ID,
                              I_REQ_ID,
                              I_PRGM_ID,
                              I_PRGM_APPL_ID,
                              l_status_moh,
                              l_return_err );
           If l_status_moh <> 0 Then
              O_RETURN_CODE := 99997;
              O_ERR_TEXT    := l_return_err;
              return;
           End if;

       End if;

   End if;  /* std costing only for moh */

/*  Removed code for bug 2603043 */

   O_RETURN_CODE := 0;

EXCEPTION
   WHEN OTHERS THEN
     O_RETURN_CODE := SQLCODE;
     O_ERR_TEXT    := substr('CSTPPCOI -'||to_char(l_location)||' : '||SQLERRM, 1, 240);
END CSTPPCOI;

/*======================================================================*/
/* Procedure: CSTPIICP                                                  */
/*                                                                      */
/* Description :                                                        */
/*    Main program for Processing costing open interface                */
/* Logic :                                                              */
/*  Org      Master_Org   Cost_Org    Costing table                     */
/*  -------  ----------   --------    -------------                     */
/*  FRE      FRE          FRE         FRE org                           */
/*  CM1      FRE          FRE         FRE org                           */
/*  CM2      FRE          CM2         FRE org CM2 org                   */
/*                                                                      */
/*                                                                      */
/* Note: 06MAY96 NPARATE Added xset_id logic                            */
/*                                                                      */
/*======================================================================*/

PROCEDURE CSTPIICP (
         I_USER_ID                 IN      NUMBER := -1,
         I_LOGIN_ID                IN      NUMBER := -1,
         I_REQ_ID                  IN      NUMBER := -1,
         I_PRGM_ID                 IN      NUMBER := -1,
         I_PRGM_APPL_ID            IN      NUMBER := -1,
         O_RETURN_CODE             OUT     NOCOPY   NUMBER,
         O_RETURN_ERR              OUT     NOCOPY   VARCHAR2,
         xset_id       IN  NUMBER DEFAULT NULL) IS

   l_cst_exist     NUMBER;
   l_return_status NUMBER;
   l_status        NUMBER;
   l_org_id        NUMBER;
   l_trx_id        NUMBER;
   l_error_msg     VARCHAR2(240);
   l_err_out       VARCHAR2(240);
   l_cst_error     exception;

-- Bug 2603043
   l_list_id       NUMBER;
   Temp_Org_Id     Number := 0;
   Temp_Cost_Org_Id    Number := 0;
   Temp_Cost_Type  Number := 0;
   New_list_ct     Number := 0;
-- Bug 2603043

   cursor cst1 is
         select  /*+ ordered */ msii.transaction_id,
         msii.inventory_item_id,
                 msii.material_cost,
                 msii.material_sub_elem,
                 msii.material_sub_elem_id,
                 msii.material_oh_rate,
                 msii.material_oh_sub_elem,
                 msii.material_oh_sub_elem_id,
         mp.primary_cost_method,
         mp.organization_id,
                 mp.master_organization_id,
                 mp.cost_organization_id
     from   mtl_system_items_interface msii,
        mtl_parameters mp
     where  msii.process_flag = 4
     and    msii.transaction_type = 'CREATE'
     and    msii.costing_enabled_flag = 'Y'
     and    msii.organization_id = mp.organization_id
         and    mp.organization_id   = mp.cost_organization_id
         and    msii.set_process_id = xset_id
     order by mp.organization_id;


   cursor cst2 is
         select  /*+ ordered */ msii.transaction_id,
         msii.inventory_item_id,
                 msii.material_cost,
                 msii.material_sub_elem,
                 msii.material_sub_elem_id,
                 msii.material_oh_rate,
                 msii.material_oh_sub_elem,
                 msii.material_oh_sub_elem_id,
         mp.primary_cost_method,
         mp.organization_id,
                 mp.master_organization_id,
                 mp.cost_organization_id
     from   mtl_system_items_interface msii,
        mtl_parameters mp
     where  msii.process_flag = 4
     and    msii.transaction_type = 'CREATE'
     and    msii.costing_enabled_flag = 'Y'
     and    msii.organization_id = mp.organization_id
         and    msii.set_process_id = xset_id
         and    mp.organization_id  <> mp.cost_organization_id
         and    mp.cost_organization_id = mp.master_organization_id
     order by mp.organization_id;


   cursor cst3 is
         select  /*+ ordered */ msii.transaction_id,
         msii.inventory_item_id,
                 msii.material_cost,
                 msii.material_sub_elem,
                 msii.material_sub_elem_id,
                 msii.material_oh_rate,
                 msii.material_oh_sub_elem,
                 msii.material_oh_sub_elem_id,
         mp.primary_cost_method,
         mp.organization_id,
                 mp.master_organization_id,
                 mp.cost_organization_id
     from   mtl_system_items_interface msii,
        mtl_parameters mp
     where  msii.process_flag = 4
     and    msii.transaction_type = 'CREATE'
     and    msii.costing_enabled_flag = 'Y'
     and    msii.organization_id = mp.organization_id
         and    msii.set_process_id = xset_id
         and    mp.organization_id   = mp.cost_organization_id
         and    mp.organization_id  <> mp.master_organization_id
     order by mp.organization_id;

BEGIN

   O_RETURN_CODE := -99999;

   /*NP 06MAY96: All logic in this procedure is within cursors
   ** and all cursors have already ben modified to take xset_id
   ** so no further checks required.
   */

   l_location := 410;
   select cst_lists_s.nextval
   into   l_list_id
   from   dual;

   FOR cc1 IN cst1 LOOP
-- fix for 3425593
--      Temp_Cost_Org_Id := cc1.cost_organization_id;

   If (Temp_Org_Id =  0) then
    Temp_Org_Id := cc1.organization_id;
    Temp_Cost_Type := cc1.primary_cost_method;
-- fix for 3425593
    Temp_Cost_Org_Id := cc1.cost_organization_id;
   end if;

       INVPCOII.CSTPPCOI ( cc1.cost_organization_id,
                           cc1.inventory_item_id,
                           cc1.material_cost,
                           cc1.material_sub_elem_id,
                           cc1.material_oh_rate,
                           cc1.material_oh_sub_elem_id,
                           I_USER_ID,
                           I_LOGIN_ID,
                           I_REQ_ID,
                           I_PRGM_ID,
                           I_PRGM_APPL_ID,
                           l_return_status,
                           l_error_msg);


    -- Bug 2603043
       if (Temp_Org_Id <> cc1.organization_id) then
       CSTPUMEC.CSTPERIC (Temp_Cost_Org_Id,
                      Temp_Cost_type,
                      l_list_id,
                      I_USER_ID,
                      I_REQ_ID,
                      I_PRGM_ID,
                      I_PRGM_APPL_ID,
                      l_return_status);

       l_location := 430;
       -- MODIFIED 04-14-08 FOR ITEM INTERFACE TEST
       delete /*+ index(cst_lists CST_LISTS_X1) */ from cst_lists
           where  list_id = l_list_id;

       Temp_Org_Id := cc1.organization_id;
       Temp_Cost_Type := cc1.primary_cost_method;
-- fix for 3425593
           Temp_Cost_Org_Id := cc1.cost_organization_id;
    end if;

   l_location := 420;
   insert into cst_lists (LIST_ID,ENTITY_ID)
   values (l_list_id,cc1.inventory_item_id);

       If (l_return_status <> 0) Then
          l_org_id := cc1.organization_id;
          l_trx_id := cc1.transaction_id;
          raise l_cst_error;
       End if;
   END LOOP; /* cst1 cursor */

-- Calling this for the last org for cc1 cursor
      CSTPUMEC.CSTPERIC (Temp_Cost_Org_Id,
                      Temp_Cost_type,
                      l_list_id,
                      I_USER_ID,
                      I_REQ_ID,
                      I_PRGM_ID,
                      I_PRGM_APPL_ID,
                      l_return_status);


      l_location := 480;
      -- MODIFIED 04-14-08 FOR ITEM INTERFACE
      delete /*+ index(cst_lists CST_LISTS_X1) */ from cst_lists
      where  list_id = l_list_id;

      Temp_Org_Id := 0;
      Temp_Cost_Org_Id := 0;
      Temp_Cost_Type := 0;

-- Completed Calling this for the last org for cc1 cursor

   FOR cc2 IN cst2 LOOP

-- fix for 3425593
--       Temp_Cost_Org_Id := cc2.cost_organization_id;
       /* Check the existence of the costing org for this item */
       select count(*)
       into   l_cst_exist
       from   cst_item_costs
       where  inventory_item_id = cc2.inventory_item_id
       and    organization_id   = cc2.cost_organization_id
       and    cost_type_id      = cc2.primary_cost_method;

       If (l_cst_exist = 0) then

       If (Temp_Org_Id = 0) then
            Temp_Org_Id := cc2.organization_id;
            Temp_Cost_Type := cc2.primary_cost_method;
-- fix for 3425593
                Temp_Cost_Org_Id := cc2.cost_organization_id;
       end if;

           INVPCOII.CSTPPCOI ( cc2.cost_organization_id,
                           cc2.inventory_item_id,
                           cc2.material_cost,
                           cc2.material_sub_elem_id,
                           cc2.material_oh_rate,
                           cc2.material_oh_sub_elem_id,
                           I_USER_ID,
                           I_LOGIN_ID,
                           I_REQ_ID ,
                           I_PRGM_ID,
                           I_PRGM_APPL_ID,
                           l_return_status,
                           l_error_msg);

        -- Bug 2603043
       if (Temp_Org_Id <> cc2.organization_id) then
           CSTPUMEC.CSTPERIC (Temp_Cost_Org_Id,
                      Temp_Cost_type,
                      l_list_id,
                      I_USER_ID,
                      I_REQ_ID,
                      I_PRGM_ID,
                      I_PRGM_APPL_ID,
                      l_return_status);


           l_location := 450;
           -- MODIFIED 04-14-08 FOR ITEM INTERFACE
           delete /*+ index(cst_lists CST_LISTS_X1) */ from cst_lists
           where  list_id = l_list_id;

           Temp_Org_Id := cc2.organization_id;
           Temp_Cost_Type := cc2.primary_cost_method;
-- fix for 3425593
           Temp_Cost_Org_Id := cc2.cost_organization_id;
        end if;

       l_location := 440;
       insert into cst_lists (LIST_ID,ENTITY_ID)
       values (l_list_id,cc2.inventory_item_id);

           If (l_return_status <> 0) Then
               l_org_id := cc2.organization_id;
               l_trx_id := cc2.transaction_id;
               raise l_cst_error;
           End if;

       End if;

   END LOOP; /* cst2 cursor */
   -- modified for item interface test 04-14-08
   select /*+ index(cst_lists CST_LISTS_X1) */ count(*)
   into   New_List_ct
   from   cst_lists
   where  list_id = l_list_id
    and rownum =1;

   if (New_list_ct = 1) then
-- Calling this for the last org for cc2 cursor
      CSTPUMEC.CSTPERIC (Temp_Cost_Org_Id,
                      Temp_Cost_type,
                      l_list_id,
                      I_USER_ID,
                      I_REQ_ID,
                      I_PRGM_ID,
                      I_PRGM_APPL_ID,
                      l_return_status);


      l_location := 480;
      -- MODIFIED FOR ITEM INTERFACE 04-14-08
      delete /*+ index(cst_lists CST_LISTS_X1) */ from cst_lists
      where  list_id = l_list_id;
  End if;
      Temp_Org_Id := 0;
      Temp_Cost_Org_Id := 0;
      Temp_Cost_Type := 0;
      New_list_ct := 0;

-- Completed Calling this for the last org for cc2 cursor

   FOR cc3 IN cst3 LOOP

-- fix for 3425593
--       Temp_Cost_Org_Id := cc3.master_organization_id;
       /* Check the existence of the master org for this item */
       select count(*)
       into   l_cst_exist
       from   cst_item_costs
       where  inventory_item_id = cc3.inventory_item_id
       and    organization_id   = cc3.master_organization_id
       and    cost_type_id      = cc3.primary_cost_method;

       If (l_cst_exist = 0) then


           If (Temp_Org_Id = 0) then
                Temp_Org_Id := cc3.organization_id;
                Temp_Cost_Type := cc3.primary_cost_method;
-- fix for 3425593
                Temp_Cost_Org_Id := cc3.master_organization_id;
           end if;

           INVPCOII.CSTPPCOI ( cc3.master_organization_id,
                           cc3.inventory_item_id,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           I_USER_ID,
                           I_LOGIN_ID,
                           I_REQ_ID,
                           I_PRGM_ID,
                           I_PRGM_APPL_ID,
                           l_return_status,
                           l_error_msg);

        -- Bug 2603043
       if (Temp_Org_Id <> cc3.organization_id) then
           CSTPUMEC.CSTPERIC (Temp_Cost_Org_Id,
                      Temp_Cost_type,
                      l_list_id,
                      I_USER_ID,
                      I_REQ_ID,
                      I_PRGM_ID,
                      I_PRGM_APPL_ID,
                      l_return_status);


           l_location := 470;
           -- MODIFIED FOR ITEM INTERFACE TEST 04-14-08
           delete /*+ index(cst_lists CST_LISTS_X1) */ from cst_lists
           where  list_id = l_list_id;

           Temp_Org_Id := cc3.organization_id;
           Temp_Cost_Type := cc3.primary_cost_method;
-- fix for 3425593
           Temp_Cost_Org_Id := cc3.master_organization_id;
        end if;

           l_location := 460;
           insert into cst_lists (LIST_ID,ENTITY_ID)
           values (l_list_id,cc3.inventory_item_id);

           If (l_return_status <> 0) Then
               l_org_id := cc3.organization_id;
               l_trx_id := cc3.transaction_id;
               raise l_cst_error;
           End if;

       End if;

   END LOOP; /* cst3 cursor */
-- Calling this for the last org for cc3 cursor
   -- modified 04-14-08 for item interface
   select /*+ index(cst_lists CST_LISTS_X1) */ count(*)
   into   New_List_ct
   from   cst_lists
   where  list_id = l_list_id
    and rownum =1;

  if (New_list_ct = 1 ) then
      CSTPUMEC.CSTPERIC (Temp_Cost_Org_Id,
                      Temp_Cost_type,
                      l_list_id,
                      I_USER_ID,
                      I_REQ_ID,
                      I_PRGM_ID,
                      I_PRGM_APPL_ID,
                      l_return_status);


      l_location := 480;
      -- MODIFIED FOR ITEM INTERFACE 04-14-08
      delete /*+ index(cst_lists CST_LISTS_X1) */ from cst_lists
      where  list_id = l_list_id;

   end if;

      Temp_Org_Id := 0;
      Temp_Cost_Org_Id := 0;
      Temp_Cost_Type := 0;
      New_list_ct := 0;
-- Completed Calling this for the last org for cc3 cursor

   O_RETURN_CODE := 0;

exception
   when l_cst_error then
          O_RETURN_CODE := l_return_status;
          O_RETURN_ERR  := l_error_msg;
          l_status := INVPUOPI.mtl_log_interface_err(
                           l_org_id,
                           I_USER_ID,
                           I_LOGIN_ID,
                           I_PRGM_APPL_ID,
                           I_PRGM_ID,
                           I_REQ_ID,
                           l_trx_id,
                           l_error_msg,
               null,
                           'MTL_SYSTEM_ITEMS_INTERFACE',
                           'CST_ERR_IN_OI',
                            l_err_out);
   WHEN OTHERS THEN
     O_RETURN_CODE := SQLCODE;
     O_RETURN_ERR  := substr('CSTPIICP -'||to_char(l_location)||' : '||SQLERRM,1, 240);

END CSTPIICP;


END INVPCOII;
/
