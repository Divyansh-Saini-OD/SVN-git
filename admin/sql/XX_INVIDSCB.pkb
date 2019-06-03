/*===========================================================================+
 |               Copyright (c) 1995 Oracle Corporation                       |
 |                  Redwood Shores, California, USA                          |
 |                       All rights reserved.                                |
 +===========================================================================*/

/* This server side package is used by form INVIDSCS
   It includes the following:
   A procedure to get information about whether a given category set 
   is used as a mandatory category set.
   A procedure which finds all the functional areas that a given
   item is enabled for.
   A procedure to populate mtl_item_categories for all child org items if
   a item level category set is assigned to an item.
   A procedure to update  mtl_item_categories for all child org items if
   a item level category set is assigned to an item.
   A procedure to delete from  mtl_item_categories for all child org items 
    CALLED if a item level category set is assigned to an item.

   History
   11-MAY-95     Nilesh Parate    Created
   14-MAY-96     Rajesh Devakumar Added procedures
                                  redefault_material_overheads
                                  & get_costing_values ( for costing )

*/
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE


SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE or REPLACE PACKAGE BODY INVIDSCS as
/* $Header: INVIDSCB.pls 115.11.115100.6 2008/06/05 06:35:40 rmpartha ship $ */

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  :    INVIDSCS (INVIDSCS.PKB)                                      |
-- | Description      : This is a custom package developed as a replication  |
-- |                    of the standard Package INVIDSCS as per defect# 19887|
-- |                    Null value was fetched by column current_created_by  |
-- |                    in the procedure INSERT_CATSET_CHILD_ORGS,while      |
-- |                    assigning Categories to an Item where Control Level  |
-- |                    is at Master Organization Level                      |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============     ==========================         |
-- |DRAFT1A 10-AUG-12   Oracle AMS Team   Initial draft version              |
-- +=========================================================================+


PROCEDURE  CHECK_CAT_SET_MANDATORY(
current_cat_set_id          IN     NUMBER,
func_area_flag1             OUT  NOCOPY    VARCHAR2,
func_area_flag2             OUT  NOCOPY    VARCHAR2,
func_area_flag3             OUT  NOCOPY    VARCHAR2,
func_area_flag4             OUT  NOCOPY    VARCHAR2,
func_area_flag5             OUT  NOCOPY    VARCHAR2,
func_area_flag6             OUT  NOCOPY    VARCHAR2,
func_area_flag7             OUT  NOCOPY    VARCHAR2,
func_area_flag8             OUT  NOCOPY    VARCHAR2,--Bug : 2527058
func_area_flag9             OUT  NOCOPY    VARCHAR2,
func_area_flag10            OUT  NOCOPY    VARCHAR2,
func_area_flag11            OUT  NOCOPY    VARCHAR2
) IS

temp varchar2(10); 

BEGIN
 null;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 1;
  /*If no data found then set flag to 'N'*/
  func_area_flag1 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag1 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 2;
  /*If no data found then set flag to 'N'*/
  func_area_flag2 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag2 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 3;
  /*If no data found then set flag to 'N'*/
  func_area_flag3 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag3 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 4;
  /*If no data found then set flag to 'N'*/
  func_area_flag4 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag4 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 5;
  /*If no data found then set flag to 'N'*/
  func_area_flag5 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag5 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 6;
  /*If no data found then set flag to 'N'*/
  func_area_flag6 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag6 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 7;
  /*If no data found then set flag to 'N'*/
  func_area_flag7 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag7 := 'N';
 END;
--Bug : 2527058 Added
 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 8;
  /*If no data found then set flag to 'N'*/
  func_area_flag8 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag8 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 9;
  /*If no data found then set flag to 'N'*/
  func_area_flag9 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag9 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 10;
  /*If no data found then set flag to 'N'*/
  func_area_flag10 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag6 := 'N';
 END;

 BEGIN
  select 'X'  into temp
    from MTL_DEFAULT_CATEGORY_SETS MDCS
   where MDCS.category_set_id = current_cat_set_id
     and MDCS.functional_area_id = 11;
  /*If no data found then set flag to 'N'*/
  func_area_flag11 := 'Y';
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
   func_area_flag11 := 'N';
 END;

END CHECK_CAT_SET_MANDATORY;
    


PROCEDURE GET_ITEM_DEFINING_FLAGS(
current_item_id             IN   NUMBER,
current_org_id              IN   NUMBER,
inv_item_flag               OUT  NOCOPY  VARCHAR2,
purch_item_flag             OUT  NOCOPY  VARCHAR2,
int_order_flag              OUT  NOCOPY  VARCHAR2,
serv_item_flag              OUT  NOCOPY  VARCHAR2,
cost_enab_flag              OUT  NOCOPY  VARCHAR2,
engg_item_flag              OUT  NOCOPY  VARCHAR2,
cust_order_flag             OUT  NOCOPY  VARCHAR2,
mrp_plan_code               OUT  NOCOPY  NUMBER,
eam_item_type               OUT  NOCOPY  NUMBER, --Bug : 2527058
contract_item_type          OUT  NOCOPY  VARCHAR2
) IS
BEGIN

 select INVENTORY_ITEM_FLAG, PURCHASING_ITEM_FLAG,
        INTERNAL_ORDER_FLAG, decode(SERVICE_ITEM_FLAG,'Y',SERVICE_ITEM_FLAG,
	SERVICEABLE_PRODUCT_FLAG),
        COSTING_ENABLED_FLAG, ENG_ITEM_FLAG, CUSTOMER_ORDER_FLAG,
        MRP_PLANNING_CODE,EAM_ITEM_TYPE,CONTRACT_ITEM_TYPE_CODE	--Bug: 2527058
   into inv_item_flag, purch_item_flag,
        int_order_flag, serv_item_flag,
        cost_enab_flag, engg_item_flag, cust_order_flag,
        mrp_plan_code, eam_item_type, contract_item_type  --Bug: 2527058
   from MTL_SYSTEM_ITEMS MSI
  where MSI.inventory_item_id = current_item_id
    and MSI.organization_id = current_org_id;

END GET_ITEM_DEFINING_FLAGS;

PROCEDURE INSERT_CATSET_CHILD_ORGS(
current_inv_item_id      IN    NUMBER,
current_org_id           IN    NUMBER,
current_master_org_id    IN    NUMBER,
current_cat_set_id       IN    NUMBER, 
current_cat_id           IN    NUMBER,
cat_set_control_level    IN    NUMBER,
current_created_by       IN    NUMBER := NULL -- Added Bug-6045866
)
IS
BEGIN

IF  (cat_set_control_level = 1) THEN 
 BEGIN
 insert into mtl_item_categories
        (inventory_item_id,
         category_set_id,
         category_id,
         last_update_date,
         last_updated_by,
         creation_date,
         created_by,
         last_update_login,
         program_application_id,
         program_id,
         program_update_date,
         request_id,
         organization_id)
   select  current_inv_item_id,
        current_cat_set_id,
        current_cat_id,
        sysdate,
        nvl(current_created_by,fnd_global.user_id),    --bug 6045866, pradeep
        sysdate,
        nvl(current_created_by,fnd_global.user_id),    --bug 6045866, pradeep
        -1,
        -1,
        -1,
        sysdate,
        -1,
        p.organization_id
   from    mtl_parameters p
    where   p.master_organization_id = current_master_org_id
    and     p.organization_id <> current_master_org_id 
    and exists
       (select  'x'
        from    mtl_system_items i
        where   i.inventory_item_id = current_inv_item_id
        and     i.organization_id = p.organization_id)
    and exists 
	(select 'x' 
	 from org_organization_definitions ood
	 where  ood.organization_id = p.organization_id
	 and    ood.inventory_enabled_flag = 'Y');
  EXCEPTION
  WHEN NO_DATA_FOUND THEN NULL;
  END;

END IF;
END INSERT_CATSET_CHILD_ORGS;

PROCEDURE UPDATE_CATSET_CHILD_ORGS( 
current_inv_item_id      IN    NUMBER,
current_org_id           IN    NUMBER,
current_master_org_id    IN    NUMBER,
current_cat_set_id       IN    NUMBER, 
current_cat_id           IN    NUMBER,
cat_set_control_level    IN    NUMBER, 
old_cat_id		 IN    NUMBER,
current_last_updated_by  IN    NUMBER := NULL     -- Added Bug-4949084 
)
IS
BEGIN
IF  (cat_set_control_level = 1) THEN 
 BEGIN
	update  mtl_item_categories c 
	/*+ INDEX MTL_ITEM_CATEGORIES MTL_ITEM_CATEGORIES_U1 */
	set 	c.category_id = current_cat_id,
		c.last_update_date = sysdate,
		c.last_updated_by = nvl(current_last_updated_by, FND_GLOBAL.USER_ID)    -- Added Bug-4949084 NVL added for Bug:5356689
	where   c.inventory_item_id = current_inv_item_id 
	and     c.category_set_id = current_cat_set_id
	and     c.category_id = old_cat_id
	and     c.organization_id in
		(select p.organization_id from mtl_parameters p
		 where  p.master_organization_id =
		         current_master_org_id	
		 and    exists (select 'x' from mtl_system_items i
				where  i.inventory_item_id =
				  current_inv_item_id	
				and    i.organization_id = p.organization_id)
		 and    exists (select 'x' from org_organization_definitions ood
				where  ood.organization_id = p.organization_id
				and    ood.inventory_enabled_flag = 'Y'));
 EXCEPTION
  WHEN NO_DATA_FOUND THEN NULL;
 END;
END IF;
END UPDATE_CATSET_CHILD_ORGS; 



PROCEDURE redefault_material_overheads ( 
current_inv_item_id      IN    NUMBER,
current_org_id           IN    NUMBER,
current_master_org_id    IN    NUMBER,
current_cat_set_id       IN    NUMBER, 
current_cat_id           IN    NUMBER,
cat_set_control_level    IN    NUMBER,
current_cst_item_type    IN    NUMBER,
current_last_updated_by  IN    NUMBER 
)
IS
  CURSOR other_orgs_cur IS
    select organization_id 
    from   mtl_system_items
    where  
     inventory_item_id = current_inv_item_id and
     organization_id  <> current_org_id      and
     organization_id  in 
      ( select organization_id 
        from mtl_parameters
        where 
          master_organization_id = current_master_org_id 
      )
  ;
  tmp_default_cat_set_id       number;
  tmp_category_id              number;
  proceed_flag                 char;
  tmp_cost_method              number;
  tmp_cst_lot_size             number;
  tmp_cst_shrink_rate          number;
  tmp_cst_return               number;
  tmp_cst_error                varchar2(100);
  tmp_organization_id          number;
BEGIN

proceed_flag := 'N';

-- get default category set for Costing (functional area 5)
select category_set_id 
into tmp_default_cat_set_id
from mtl_default_category_sets
where functional_area_id = 5;

-- This is called from post-update.
-- fires only after update is done. if updated, and if cat set id
-- is def cat set, then proceed.
if current_cat_set_id = tmp_default_cat_set_id then
    proceed_flag := 'Y';
end if;

-- if redefaulting is necessary then
if proceed_flag = 'Y' then

 INVIDSCS.get_costing_values ( 
  current_inv_item_id, 
  current_org_id,
  tmp_cost_method,
  tmp_cst_lot_size,
  tmp_cst_shrink_rate
 );

 CSTPPCAT.CSTPCCAT ( 
  current_inv_item_id,
  current_org_id,
  current_last_updated_by,
  tmp_cost_method,
  current_cst_item_type,
  tmp_cst_lot_size,
  tmp_cst_shrink_rate,
  tmp_cst_return,
  tmp_cst_error
 );

end if;

-- if category is controll at master level (item)
if  (proceed_flag = 'Y') and 
    (cat_set_control_level = 1) then 
 OPEN other_orgs_cur;
 LOOP
 FETCH other_orgs_cur into tmp_organization_id;
 EXIT when other_orgs_cur%NOTFOUND;
  
 INVIDSCS.get_costing_values ( 
  current_inv_item_id, 
  tmp_organization_id,
  tmp_cost_method,
  tmp_cst_lot_size,
  tmp_cst_shrink_rate
 );

 CSTPPCAT.CSTPCCAT ( 
  current_inv_item_id,
  tmp_organization_id,
  current_last_updated_by,
  tmp_cost_method,
  current_cst_item_type,
  tmp_cst_lot_size,
  tmp_cst_shrink_rate,
  tmp_cst_return,
  tmp_cst_error
 );

 END LOOP;
 CLOSE other_orgs_cur;
end if;

END redefault_material_overheads;


PROCEDURE get_costing_values ( 
tmp_inv_item_id          IN    NUMBER,
tmp_organization_id      IN    NUMBER,
tmp_cost_method         OUT  NOCOPY    NUMBER,
tmp_cst_lot_size        OUT  NOCOPY    NUMBER,
tmp_cst_shrink_rate     OUT  NOCOPY    NUMBER
)
IS

BEGIN

--dbms_output.put_line ( 'Inside get_costing_values ' );

  select primary_cost_method
  into   tmp_cost_method
  from   mtl_parameters
  where  organization_id = tmp_organization_id;
 
  begin
    select  lot_size, shrinkage_rate
    into    tmp_cst_lot_size, tmp_cst_shrink_rate
    from    cst_item_costs
    where 
      inventory_item_id   = tmp_inv_item_id
      and organization_id = tmp_organization_id
      and cost_type_id    = tmp_cost_method; --Bug#7136948 : Changed from cost_type_id = 1 to cost_type_id = tmp_cost_method
  
  exception
      when NO_DATA_FOUND then
        tmp_cst_lot_size := null;
        tmp_cst_shrink_rate := null;
  end;


EXCEPTION
 when NO_DATA_FOUND then
   tmp_cost_method := null;
   tmp_cst_lot_size := null;
   tmp_cst_shrink_rate := null;

END get_costing_values;

   

/* The following procedure called ONLY when category_set control level is "Item"
*/
  /* Prasad Peddamatham - 12/8/2000
  Added current_cat_id parameter to allow the deletion of a Item Category
  Assignment based upon Multiple Item Category Assignment flag
  */
PROCEDURE DELETE_CATSET_CHILD_ORGS( 
current_inv_item_id      IN    NUMBER,
current_master_org_id    IN    NUMBER,
current_cat_set_id       IN    NUMBER,
current_cat_id       IN    NUMBER
)
IS
BEGIN
   /* Prasad Peddamatham - 12/8/2000
      added the clause : c.category_id = current_cat_id
      to be able include the category_id while deletion of "Item Category"
      Assignment.
	In 11.5.3, the Multiple Item Category Assignment is allowed.
	That is Assigning an Item to multiple categories within a CategorySet.
	This caused the Unique Index on MTL_CATEGORIES to be the following
	4 columns: INVENTORY_ITEM_ID, ORG_ID, CATEGORY_SET_ID, CATEGORY_ID.
	So, during Deleting need to use all these 4 column values to delete
	a single assignment.
   */
	delete  from mtl_item_categories c
		where c.inventory_item_id = current_inv_item_id 
		and   c.category_set_id = current_cat_set_id 
		and   c.category_id = current_cat_id 
                and   c.organization_id in
                              (select  p.organization_id
                               from mtl_parameters p
                               where p.master_organization_id = current_master_org_id);
                               

EXCEPTION
  WHEN NO_DATA_FOUND THEN NULL;
END DELETE_CATSET_CHILD_ORGS;
   

END INVIDSCS; 
/
/*
*show errors package body &PACKAGE_NAME;
*
*SELECT to_date('SQLERROR') FROM user_errors
*WHERE  name = '&PACKAGE_NAME'
*AND    type = 'PACKAGE_BODY';
*/
commit;
exit;

