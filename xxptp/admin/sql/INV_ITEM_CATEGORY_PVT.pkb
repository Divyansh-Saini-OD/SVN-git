CREATE OR REPLACE PACKAGE BODY "INV_ITEM_CATEGORY_PVT" AS 
/* $Header: INVVCATB.pls 115.19.115100.7 2005/09/02 21:19:10 sanmani ship $ */ 
 
 
---------------------- Package variables and constants ----------------------- 
 
G_PKG_NAME CONSTANT VARCHAR2(30) := 'APPS.INV_ITEM_CATEGORY_PVT'; 
 
G_INV_APP_ID          CONSTANT  NUMBER        :=  401; 
G_INV_APP_SHORT_NAME  CONSTANT  VARCHAR2(3)   :=  'INV'; 
G_CAT_FLEX_CODE       CONSTANT  VARCHAR2(4)   :=  'MCAT'; 
 
-- Operations 
 
c_INSERT    CONSTANT  VARCHAR2(3)  :=  'INS'; 
c_UPDATE    CONSTANT  VARCHAR2(3)  :=  'UPD'; 
c_DELETE    CONSTANT  VARCHAR2(3)  :=  'DEL'; 
 
------------------------------------------------------------------------------ 
 
 
---------------------------- Validate_Assignment ----------------------------- 
/* 
PROCEDURE Validate_Assignment 
(  p_Debug_Level  IN  NUMBER 
,  p_Msg_Text     IN  VARCHAR2 
) IS 
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0); 
BEGIN 
 
   -- currently validation is done in the procedure Create_Category_Assignment 
 
END Validate_Assignment; 
------------------------------------------------------------------------------ 
*/ 
--Bug: 2996160 
FUNCTION Is_Category_Leafnode 
(  p_category_set_id    IN   NUMBER 
,  p_category_id        IN   NUMBER 
,  p_validate_flag      IN   VARCHAR2 
,  p_hierarchy_enabled IN   VARCHAR2 
) RETURN BOOLEAN; 
 
------------------------- Create_Category_Assignment ------------------------- 
 
PROCEDURE Create_Category_Assignment 
( 
   p_api_version        IN   NUMBER 
,  p_init_msg_list      IN   VARCHAR2  DEFAULT  fnd_api.g_FALSE 
,  p_commit             IN   VARCHAR2  DEFAULT  fnd_api.g_FALSE 
,  p_validation_level   IN   NUMBER    DEFAULT  INV_ITEM_CATEGORY_PVT.g_VALIDATE_ALL 
,  p_inventory_item_id  IN   NUMBER 
,  p_organization_id    IN   NUMBER 
,  p_category_set_id    IN   NUMBER 
,  p_category_id        IN   NUMBER 
,  p_transaction_id     IN   NUMBER 
,  p_request_id         IN   NUMBER 
,  x_return_status      OUT  NOCOPY VARCHAR2 
,  x_msg_count          OUT  NOCOPY NUMBER 
,  x_msg_data           OUT  NOCOPY VARCHAR2 
) 
IS 
   l_api_name        CONSTANT  VARCHAR2(30)  := 'Create_Category_Assignment'; 
   l_api_version     CONSTANT  NUMBER        := 1.0; 
   Mctx              INV_ITEM_MSG.Msg_Ctx_type; 
 
   l_exists                   VARCHAR2(1); 
   l_category_set_restrict_cats  VARCHAR2(1); 
   l_mult_item_cat_assign_flag   VARCHAR2(1); 
   l_category_set_struct_id   NUMBER; 
   l_category_struct_id       NUMBER; 
   l_the_item_assign_count    NUMBER; 
   l_the_cat_assign_count     NUMBER; 
   l_control_level            NUMBER; 
   p_master_org_id            NUMBER; 
   l_request_id               NUMBER;--2879647 
   l_hierarchy_enabled        VARCHAR2(1); 
--   l_assign_exists            BOOLEAN; 
 
   CURSOR org_item_exists_csr 
   (  p_inventory_item_id  NUMBER 
   ,  p_organization_id    NUMBER 
   ) IS 
      SELECT 'x',request_id--2879647 
      FROM  mtl_system_items_b 
      WHERE  inventory_item_id = p_inventory_item_id 
        AND  organization_id   = p_organization_id 
        AND  NVL(approval_status,'A') = 'A'; --Added for 11.5.10 PLM 
 
   CURSOR category_sets_csr (p_category_set_id  NUMBER) 
   IS 
      SELECT  structure_id, validate_flag, mult_item_cat_assign_flag, 
                                                        control_level 
                                                        ,hierarchy_enabled--Bug: 2996160 
      FROM  mtl_category_sets_b 
      WHERE  category_set_id = p_category_set_id; 
 
   CURSOR category_exists_csr (p_category_id  NUMBER) 
   IS 
      SELECT  structure_id 
      FROM  mtl_categories_b 
      WHERE  category_id = p_category_id 
        AND NVL(DISABLE_DATE,SYSDATE+1) > SYSDATE;--Bug: 2996160 
 
   CURSOR category_set_valid_cats_csr 
   (  p_category_set_id  NUMBER 
   ,  p_category_id      NUMBER 
   ) IS 
      SELECT 'x' 
      FROM  mtl_category_set_valid_cats 
      WHERE  category_set_id = p_category_set_id 
        AND  category_id = p_category_id; 
 
   CURSOR item_cat_assign_count_csr 
   (  p_inventory_item_id  NUMBER 
   ,  p_organization_id    NUMBER 
   ,  p_category_set_id    NUMBER 
   ,  p_category_id        NUMBER 
   ) IS 
      SELECT  COUNT( category_id ), COUNT( DECODE(category_id, p_category_id,1, NULL) ) 
      FROM  mtl_item_categories 
      WHERE 
              inventory_item_id = p_inventory_item_id 
         AND  organization_id   = p_organization_id 
         AND  category_set_id = p_category_set_id; 
 
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0); 
BEGIN 
 
   -- Set savepoint 
   SAVEPOINT Create_Category_Assignment_PVT; 
 
--   INVPUTLI.info('Add_Message: p_Msg_Name=' || p_Msg_Name); 
 
--dbms_output.put_line('Enter INV_ITEM_CATEGORY_PVT.Create_Category_Assignment'); 
 
   -- Check for call compatibility 
   IF NOT FND_API.Compatible_API_Call (l_api_version, p_api_version, 
                                       l_api_name, G_PKG_NAME) 
   THEN 
      RAISE FND_API.g_EXC_UNEXPECTED_ERROR; 
   END IF; 
 
--dbms_output.put_line('Before Initialize message list.'); 
 
   -- Initialize message list 
   IF (FND_API.To_Boolean (p_init_msg_list)) THEN 
      INV_ITEM_MSG.Initialize; 
   END IF; 
 
   -- Define message context 
   Mctx.Package_Name   := G_PKG_NAME; 
   Mctx.Procedure_Name := l_api_name; 
 
   -- Initialize API return status to success 
   x_return_status := FND_API.g_RET_STS_SUCCESS; 
 
   -- Check for NULL parameter values 
 
/*  IF ( p_Item_ID = fnd_api.g_MISS_NUM ) OR ( p_Item_ID IS NULL ) OR 
     ( p_Org_ID  = fnd_api.g_MISS_NUM ) OR ( p_Org_ID  IS NULL ) 
*/ 
 
--dbms_output.put_line('Before IS NULL ; x_return_status = ' || x_return_status); 
 
   IF ( p_inventory_item_id IS NULL ) OR ( p_organization_id IS NULL ) OR 
      ( p_category_set_id IS NULL ) OR ( p_category_id IS NULL ) 
   THEN 
--    INV_ITEM_MSG.Add_Error('INV_INVALID_ARG_NULL_VALUE'); 
      INV_ITEM_MSG.Add_Message 
      (  p_Msg_Name        =>  'INV_INVALID_ARG_NULL_VALUE' 
      ,  p_transaction_id  =>  p_transaction_id 
      ); 
 
      RAISE fnd_api.g_EXC_UNEXPECTED_ERROR; 
   END IF; 
 
   IF (l_debug = 1) THEN 
      INV_ITEM_MSG.Debug(Mctx, 'Validate item/org Ids'); 
   END IF; 
 
   -- Validate item/org Ids 
 
--dbms_output.put_line('Before OPEN org_item_exists_csr ; x_return_status = ' || x_return_status); 
 
   OPEN org_item_exists_csr (p_inventory_item_id, p_organization_id); 
   FETCH org_item_exists_csr INTO l_exists,l_request_id; 
   IF (org_item_exists_csr%NOTFOUND) THEN 
      CLOSE org_item_exists_csr; 
      --INV_ITEM_MSG.Add_Error('INV_ORGITEM_ID_NOT_FOUND'); 
      INV_ITEM_MSG.Add_Message 
      (  p_Msg_Name        =>  'INV_ORGITEM_ID_NOT_FOUND' 
      ,  p_transaction_id  =>  p_transaction_id 
      ); 
      RAISE FND_API.g_EXC_ERROR; 
   END IF; 
   CLOSE org_item_exists_csr; 
 
--dbms_output.put_line('After OPEN org_item_exists_csr ; x_return_status = ' || x_return_status); 
 
   IF (l_debug = 1) THEN 
      INV_ITEM_MSG.Debug(Mctx, 'Validate category set id'); 
   END IF; 
 
   -- Validate category set id 
 
   OPEN category_sets_csr (p_category_set_id); 
   FETCH category_sets_csr INTO l_category_set_struct_id, 
                                l_category_set_restrict_cats, 
                                l_mult_item_cat_assign_flag, 
                                l_control_level 
                                ,l_hierarchy_enabled;--Bug: 2996160 
 
   IF (category_sets_csr%NOTFOUND) THEN 
      CLOSE category_sets_csr; 
      --INV_ITEM_MSG.Add_Error('INV_CATEGORY_SET_ID_NOT_FOUND'); 
      INV_ITEM_MSG.Add_Message 
      (  p_Msg_Name        =>  'INV_CATEGORY_SET_ID_NOT_FOUND' 
      ,  p_transaction_id  =>  p_transaction_id 
      ); 
      RAISE FND_API.g_EXC_ERROR; 
   END IF; 
   CLOSE category_sets_csr; 
 
   IF (l_debug = 1) THEN 
      INV_ITEM_MSG.Debug(Mctx, 'Validate category id'); 
   END IF; 
 
   -- Validate category id 
 
--dbms_output.put_line('Before OPEN category_exists_csr ; x_return_status = ' || x_return_status); 
 
   OPEN category_exists_csr (p_category_id); 
   FETCH category_exists_csr INTO l_category_struct_id; 
   IF (category_exists_csr%NOTFOUND) THEN 
      CLOSE category_exists_csr; 
      --INV_ITEM_MSG.Add_Error('INV_CATEGORY_ID_NOT_FOUND'); 
      INV_ITEM_MSG.Add_Message 
      (  p_Msg_Name        =>  'INV_CATEGORY_ID_NOT_FOUND' 
      ,  p_transaction_id  =>  p_transaction_id 
      ); 
      RAISE FND_API.g_EXC_ERROR; 
   END IF; 
   CLOSE category_exists_csr; 
 
--dbms_output.put_line('After OPEN category_exists_csr ; x_return_status = ' || x_return_status); 
 
   IF (l_debug = 1) THEN 
      INV_ITEM_MSG.Debug(Mctx, 'Validate category structure_id'); 
   END IF; 
 
   -- Category structure_id must be the same as structure_id defined in the Category Set. 
 
--dbms_output.put_line('Before IF l_category_struct_id ; x_return_status = ' || x_return_status); 
 
   IF (l_category_struct_id <> l_category_set_struct_id) THEN 
      --INV_ITEM_MSG.Add_Error('INV_INVALID_CATEGORY_STRUCTURE'); 
      INV_ITEM_MSG.Add_Message 
      (  p_Msg_Name        =>  'INV_INVALID_CATEGORY_STRUCTURE' 
      ,  p_transaction_id  =>  p_transaction_id 
      ); 
      RAISE FND_API.g_EXC_ERROR; 
   END IF; 
 
   -- If Category set control level is master and organization being processed is not master then error 
 
         -- Get master org 
         SELECT MASTER_ORGANIZATION_ID 
         INTO           p_master_org_id 
         FROM           mtl_parameters 
         WHERE  organization_id = p_organization_id; 
 
   IF ((l_control_level = 1) and (p_organization_id <> p_master_org_id)) THEN 
              --INV_ITEM_MSG.Add_Error('INV_CAT_CANNOT_CREATE_DELETE'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CAT_CANNOT_CREATE_DELETE' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
        RAISE FND_API.g_EXC_ERROR; 
         END IF; 
 
   -- End If Category set control level is master 
 
   -- If a Category Set is defined with the VALIDATE_FLAG = 'Y' then 
   -- a Category must belong to a list of categories in the table MTL_CATEGORY_SET_VALID_CATS. 
 
   IF (l_category_set_restrict_cats = 'Y') THEN 
 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'Category Set has a restricted list of categories'); 
         INV_ITEM_MSG.Debug(Mctx, 'Validate Category Set valid category'); 
      END IF; 
 
      OPEN category_set_valid_cats_csr (p_category_set_id, p_category_id); 
      FETCH category_set_valid_cats_csr INTO l_exists; 
      IF (category_set_valid_cats_csr%NOTFOUND) THEN 
         CLOSE category_set_valid_cats_csr; 
        -- INV_ITEM_MSG.Add_Error('INV_CATEGORY_SET_INVALID_CAT'); 
        -- INV_ITEM_MSG.Add_Error('INV_CATEGORY_NOT_IN_VALID_SET'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CATEGORY_NOT_IN_VALID_SET' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
         RAISE FND_API.g_EXC_ERROR; 
      END IF; 
      CLOSE category_set_valid_cats_csr; 
   END IF; 
--Bug: 2996160 Added function Is_Category_Leafnode,code to validate leaf node 
   IF (l_debug = 1) THEN 
      INV_ITEM_MSG.Debug(Mctx, 'Validate Is category is leafnode or not'); 
   END IF; 
   IF  NOT Is_Category_Leafnode ( p_category_set_id, 
                                  p_category_id, 
                                  l_category_set_restrict_cats, 
                                  l_hierarchy_enabled ) THEN 
         --INV_ITEM_MSG.Add_Error('INV_ITEM_CAT_ASSIGN_LEAF_ONLY'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_ITEM_CAT_ASSIGN_LEAF_ONLY' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
         RAISE FND_API.g_EXC_ERROR; 
   END IF; 
 
--Bug: 2996160 Ends here 
 
   IF (l_debug = 1) THEN 
      INV_ITEM_MSG.Debug(Mctx, 'Validate item cat assignments'); 
   END IF; 
 
   -- Get this item all category assignments count, and this category assignments count 
 
   OPEN item_cat_assign_count_csr (p_inventory_item_id, 
                                   p_organization_id, 
                                   p_category_set_id, 
                                   p_category_id); 
 
   FETCH item_cat_assign_count_csr INTO l_the_item_assign_count, l_the_cat_assign_count; 
 
   -- If a Category Set is defined with the MULT_ITEM_CAT_ASSIGN_FLAG set to 'N' 
   -- then an Item may be assigned to only one Category in the Category Set. 
 
   IF ( l_mult_item_cat_assign_flag = 'N' 
        AND (l_the_item_assign_count - l_the_cat_assign_count) > 0 ) 
   THEN 
      --INV_ITEM_MSG.Debug(Mctx, 'Multiple item category assignment is not allowed'); 
--2879647 If the Item Category Assignment is happening while creating an item 
--        then take the user given values instead of default 
     IF (l_request_id = p_request_id ) THEN 
        -- Delete a row from the table and create with new category 
        --Modified for bug 3255128 
       IF (l_control_level = 1) THEN 
              DELETE FROM mtl_item_categories 
               WHERE inventory_item_id = p_inventory_item_id 
               AND category_set_id = p_category_set_id; 
       ELSE 
               DELETE FROM mtl_item_categories 
               WHERE organization_id   = p_organization_id 
               AND inventory_item_id = p_inventory_item_id 
               AND category_set_id = p_category_set_id; 
       END IF; 
     ELSE 
      --INV_ITEM_MSG.Add_Error('INV_ITEM_CAT_ASSIGN_NO_MULT'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_ITEM_CAT_ASSIGN_NO_MULT' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
      RAISE FND_API.g_EXC_ERROR; 
     END IF; 
   --ELSIF (l_the_cat_assign_count = 0) THEN 
      -- TODO: 
      -- Check if Master Item category assignment permits the Org Item assignment. 
 
   END IF; 
 
   -- If an assignment does not exist, insert into the assignments table 
 
   IF (l_the_cat_assign_count = 0) THEN 
 
     IF (l_debug = 1) THEN 
        INV_ITEM_MSG.Debug(Mctx, 'begin INSERT INTO mtl_item_categories'); 
     END IF; 
 
    IF ((l_control_level = 1) and (p_organization_id = p_master_org_id)) THEN 
 
        -- If the category control level is 1 and we are inserting for master record then the assignemnt should also be made for child records. 
         INSERT INTO mtl_item_categories 
                ( 
                inventory_item_id 
                , organization_id 
                , category_set_id 
                , category_id 
                , creation_date 
                , created_by 
                , last_update_date 
                , last_updated_by 
                , last_update_login 
                , request_id   --4105867 
                ) 
                SELECT 
                p_inventory_item_id 
                , p.organization_id 
                , p_category_set_id 
                , p_category_id 
                , SYSDATE 
                , FND_GLOBAL.user_id 
                , SYSDATE 
                , FND_GLOBAL.user_id 
                , FND_GLOBAL.login_id 
                , FND_GLOBAL.conc_request_id 
                FROM    mtl_parameters p , mtl_system_items_b i 
                WHERE   p.master_organization_id = p_master_org_id 
                  AND     i.inventory_item_id = p_inventory_item_id 
                  AND     i.organization_id = p.organization_id 
                  AND not exists 
                  (SELECT 'x' 
                   FROM    mtl_item_categories 
                   whERE   inventory_item_id = p_inventory_item_id 
                     AND   organization_id = p.organization_id 
                     AND   category_set_id = p_category_set_id 
                     AND   category_id = p_category_id); 
     ELSE 
       INSERT INTO mtl_item_categories 
        ( 
          inventory_item_id 
        , organization_id 
        , category_set_id 
        , category_id 
        , creation_date 
        , created_by 
        , last_update_date 
        , last_updated_by 
        , last_update_login 
        , request_id   --4105867 
        ) 
        VALUES 
        ( 
           p_inventory_item_id 
        ,  p_organization_id 
        ,  p_category_set_id 
        ,  p_category_id 
        ,  SYSDATE 
        ,  FND_GLOBAL.user_id 
        ,  SYSDATE 
        ,  FND_GLOBAL.user_id 
        ,  FND_GLOBAL.login_id 
        ,  FND_GLOBAL.conc_request_id 
        ); 
    END IF; 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'end INSERT INTO mtl_item_categories'); 
      END IF; 
   ELSIF (l_request_id <> p_request_id ) THEN -- Bug:3260965 Incase of Default assignment donot show error 
      --INV_ITEM_MSG.Add_Warning('INV_CAT_ASSGN_ALREADY_EXISTS'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CAT_ASSGN_ALREADY_EXISTS' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
   END IF; 
 
   -- Standard check of p_commit 
   IF (FND_API.To_Boolean (p_commit)) THEN 
 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'before COMMIT WORK'); 
      END IF; 
 
      COMMIT WORK; 
   END IF; 
 
   INV_ITEM_MSG.Count_And_Get 
   (  p_count  =>  x_msg_count 
   ,  p_data   =>  x_msg_data 
   ); 
 
EXCEPTION 
 
   WHEN FND_API.g_EXC_ERROR THEN 
      ROLLBACK TO Create_Category_Assignment_PVT; 
 
      x_return_status := FND_API.g_RET_STS_ERROR; 
      INV_ITEM_MSG.Count_And_Get 
      (  p_count  =>  x_msg_count 
      ,  p_data   =>  x_msg_data 
      ); 
 
   WHEN FND_API.g_EXC_UNEXPECTED_ERROR THEN 
      ROLLBACK TO Create_Category_Assignment_PVT; 
 
      x_return_status := FND_API.g_RET_STS_UNEXP_ERROR; 
      INV_ITEM_MSG.Count_And_Get 
      (  p_count  =>  x_msg_count 
      ,  p_data   =>  x_msg_data 
      ); 
 
   WHEN others THEN 
      ROLLBACK TO Create_Category_Assignment_PVT; 
 
      x_return_status := FND_API.g_RET_STS_UNEXP_ERROR; 
      --INV_ITEM_MSG.Add_Unexpected_Error (Mctx, SQLERRM); 
        INV_ITEM_MSG.Add_Message 
      (  p_Msg_Name    =>  'INV_ITEM_UNEXPECTED_ERROR' 
      ,  p_token1      =>  'PKG_NAME' 
      ,  p_value1      =>  Mctx.Package_Name 
      ,  p_token2      =>  'PROCEDURE_NAME' 
      ,  p_value2      =>  Mctx.Procedure_Name 
      ,  p_token3      =>  'ERROR_TEXT' 
      ,  p_value3      =>  SQLERRM 
      ,  p_transaction_id  =>  p_transaction_id 
      ); 
 
      INV_ITEM_MSG.Count_And_Get 
      (  p_count  =>  x_msg_count 
      ,  p_data   =>  x_msg_data 
      ); 
 
END Create_Category_Assignment; 
------------------------------------------------------------------------------ 
 
 
------------------------- Delete_Category_Assignment ------------------------- 
 
PROCEDURE Delete_Category_Assignment 
( 
   p_api_version        IN   NUMBER 
,  p_init_msg_list      IN   VARCHAR2  DEFAULT  fnd_api.g_FALSE 
,  p_commit             IN   VARCHAR2  DEFAULT  fnd_api.g_FALSE 
,  p_inventory_item_id  IN   NUMBER 
,  p_organization_id    IN   NUMBER 
,  p_category_set_id    IN   NUMBER 
,  p_category_id        IN   NUMBER 
,  p_transaction_id     IN   NUMBER 
,  x_return_status      OUT  NOCOPY VARCHAR2 
,  x_msg_count          OUT  NOCOPY NUMBER 
,  x_msg_data           OUT  NOCOPY VARCHAR2 
) 
IS 
   l_api_name        CONSTANT  VARCHAR2(30)  := 'Delete_Category_Assignment'; 
   l_api_version     CONSTANT  NUMBER        := 1.0; 
   Mctx              INV_ITEM_MSG.Msg_Ctx_type; 
   l_row_count       NUMBER; 
   l_control_level       NUMBER; 
   p_master_org_id         NUMBER; 
   l_category_struct_id       NUMBER; 
   l_category_id         NUMBER; 
   l_count NUMBER; 
   FF1  VARCHAR2(1); 
   FF2  VARCHAR2(1); 
   FF3  VARCHAR2(1); 
   FF4  VARCHAR2(1); 
   FF5  VARCHAR2(1); 
   FF6  VARCHAR2(1); 
   FF7  VARCHAR2(1); 
   FF8  VARCHAR2(1); 
   FF9  VARCHAR2(1); 
   FF10  VARCHAR2(1); 
   FF11  VARCHAR2(1); 
   inv_item_flagg           VARCHAR2(1); 
   purch_item_flagg         VARCHAR2(1); 
   int_order_flagg          VARCHAR2(1); 
   serv_item_flagg          VARCHAR2(1); 
   cost_enab_flagg          VARCHAR2(1); 
   engg_item_flagg          VARCHAR2(1); 
   cust_order_flagg         VARCHAR2(1); 
   mrp_plan_code            number; 
   default_cat_id           NUMBER; 
   cat_flagg                VARCHAR2(1); 
   cnt_cat                  NUMBER ; 
   eam_item_type            NUMBER; 
   contract_item_type       VARCHAR2(60); 
 
 
   CURSOR category_sets_csr (p_category_set_id  NUMBER) 
   IS 
      SELECT  control_level,default_category_id--Bug:2527058 
      FROM    mtl_category_sets_b 
      WHERE   category_set_id = p_category_set_id; 
 
   CURSOR category_exists_csr (p_category_id  NUMBER) 
   IS 
      SELECT  structure_id 
      FROM  mtl_categories_b 
      WHERE  category_id = p_category_id; 
 
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0); 
 
   BEGIN 
 
   -- Set savepoint 
   SAVEPOINT Delete_Category_Assignment_PVT; 
 
   -- Check for call compatibility 
   IF NOT FND_API.Compatible_API_Call (l_api_version, p_api_version, 
                                       l_api_name, G_PKG_NAME) 
   THEN 
      RAISE FND_API.g_EXC_UNEXPECTED_ERROR; 
   END IF; 
 
   -- Initialize message list 
   IF (FND_API.To_Boolean (p_init_msg_list)) THEN 
      INV_ITEM_MSG.Initialize; 
   END IF; 
 
   -- Define message context 
   Mctx.Package_Name   := G_PKG_NAME; 
   Mctx.Procedure_Name := l_api_name; 
 
   -- Initialize API return status to success 
   x_return_status := FND_API.g_RET_STS_SUCCESS; 
 
   --INV_ITEM_MSG.Debug(Mctx, 'NO VALIDATION IMPLEMENTED'); 
   --INV_ITEM_MSG.Debug(Mctx, 'before DELETE FROM mtl_item_categories'); 
 
   OPEN category_sets_csr (p_category_set_id); 
   FETCH category_sets_csr INTO l_control_level, l_category_id; 
 
   IF (category_sets_csr%NOTFOUND) THEN 
      CLOSE category_sets_csr; 
      --INV_ITEM_MSG.Add_Error('INV_CATEGORY_SET_ID_NOT_FOUND'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CATEGORY_SET_ID_NOT_FOUND' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
      RAISE FND_API.g_EXC_ERROR; 
   ELSE 
/* Bug 4046670 To check if he item belongs to a functional area for which the category set is mandatory before deletion - Anmurali */ 
/*Raise error if the category set is a mandatory category set for the functional area to which the item belongs */ 
      INVIDSCS.CHECK_CAT_SET_MANDATORY(p_category_set_id, 
                                       FF1, FF2, FF3, FF4, FF5, FF6, FF7, FF8, FF9, FF10, FF11); 
 
 --FF1 will be Y if category set is a mandatory set for func_area_id = 1 
 --FF2 will be Y if ......... func_area_id = 2...and so on 
 
      INVIDSCS.GET_ITEM_DEFINING_FLAGS(p_inventory_item_id, 
                                       p_organization_id, 
				       inv_item_flagg, 
				       purch_item_flagg, 
				       int_order_flagg, 
				       serv_item_flagg, 
				       cost_enab_flagg, 
				       engg_item_flagg, 
				       cust_order_flagg, 
				       mrp_plan_code, 
				       eam_item_type, 
				       contract_item_type); 
 
     if (l_category_id = p_category_id) then 
         cat_flagg := 'Y'; 
     else 
         cat_flagg := 'N'; 
     end if; 
 
     SELECT  count(category_id) 
     INTO    cnt_cat 
     FROM    mtl_item_categories 
     WHERE   INVENTORY_ITEM_ID = p_inventory_item_id 
     AND     ORGANIZATION_ID   = p_organization_id 
     AND     CATEGORY_SET_ID   = p_category_set_id; 
 
     IF ((FF1 =  'Y' and  inv_item_flagg = 'Y') 
       or(FF2 =  'Y' and  purch_item_flagg = 'Y') 
       or(FF2 =  'Y' and  int_order_flagg = 'Y') --note: there are 2 cases for FF2 = Y 
       or(FF3 =  'Y' and  mrp_plan_code <> 6) 
       or(FF4 =  'Y' and  serv_item_flagg = 'Y') 
       or(FF5 =  'Y' and  cost_enab_flagg = 'Y') 
       or(FF6 =  'Y' and  engg_item_flagg = 'Y') 
       or(FF7 =  'Y' and  cust_order_flagg = 'Y') 
       or(FF9 =  'Y' and  eam_item_type IS NOT NULL)  --Bug: 2527058 
       or(FF10 = 'Y' and contract_item_type IS NOT NULL) 
       or(FF11 = 'Y' and (cust_order_flagg = 'Y' OR int_order_flagg = 'Y'))) THEN 
  	   IF ((cnt_cat <= 1) or (cat_flagg = 'Y')) then 
   		INV_ITEM_MSG.Add_Message 
		(  p_Msg_Name        =>  'INV_DEL_MAND_CAT_SET' 
		,  p_transaction_id  =>  p_transaction_id 
		); 
		RAISE FND_API.g_EXC_ERROR; 
	END IF; 
     END IF; 
 -- End of bug fix for Bug 4046670 - Anmurali 
   END IF; 
   CLOSE category_sets_csr; 
 
   OPEN category_exists_csr (p_category_id); 
   FETCH category_exists_csr INTO l_category_struct_id; 
 
   IF (category_exists_csr%NOTFOUND) THEN 
      CLOSE category_exists_csr; 
      --INV_ITEM_MSG.Add_Error('INV_CATEGORY_ID_NOT_FOUND'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CATEGORY_ID_NOT_FOUND' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
      RAISE FND_API.g_EXC_ERROR; 
   END IF; 
   CLOSE category_exists_csr; 
 
   SELECT MASTER_ORGANIZATION_ID 
   INTO   p_master_org_id 
   FROM   mtl_parameters 
   WHERE  organization_id = p_organization_id; 
 
   IF ((l_control_level = 1) and (p_organization_id <> p_master_org_id)) THEN 
              --INV_ITEM_MSG.Add_Error('INV_CAT_CANNOT_CREATE_DELETE'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CAT_CANNOT_CREATE_DELETE' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
        RAISE FND_API.g_EXC_ERROR; 
         END IF; 
 
   IF ((l_control_level = 1) and (p_organization_id = p_master_org_id)) THEN 
--Bug: 3561206 Added an index for performance improvement 
--          DELETE /*+ INDEX(MIC MTL_ITEM_CATEGORIES_U1) */ 
          DELETE 
            FROM  mtl_item_categories MIC 
           WHERE  category_set_id+0 = p_category_set_id 
             AND  category_id     = p_category_id 
             AND  inventory_item_id = p_inventory_item_id 
             AND  organization_id+0 = 
                  (SELECT organization_id 
                     FROM mtl_parameters p 
                    WHERE p.master_organization_id = p_master_org_id 
                      AND p.organization_id = mic.organization_id); 
   ELSE 
                -- Delete a row from the table 
                -- 
                DELETE FROM mtl_item_categories 
                WHERE organization_id   = p_organization_id 
                  AND inventory_item_id = p_inventory_item_id 
                  AND category_set_id   = p_category_set_id 
                  AND category_id       = p_category_id; 
   END IF; 
 
   IF (SQL%NOTFOUND) THEN 
      --INV_ITEM_MSG.Add_Warning('INV_CAT_ASSGN_NOT_FOUND'); 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CAT_ASSGN_NOT_FOUND' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
   END IF; 
 
   IF (l_debug = 1) THEN 
      INV_ITEM_MSG.Debug(Mctx, 'after DELETE FROM mtl_item_categories'); 
   END IF; 
 
   -- Standard check of p_commit 
   IF (FND_API.To_Boolean (p_commit)) THEN 
      COMMIT WORK; 
   END IF; 
 
   INV_ITEM_MSG.Count_And_Get 
   (  p_count  =>  x_msg_count 
   ,  p_data   =>  x_msg_data 
   ); 
 
EXCEPTION 
 
   WHEN FND_API.g_EXC_ERROR THEN 
      ROLLBACK TO Delete_Category_Assignment_PVT; 
      x_return_status := FND_API.g_RET_STS_ERROR; 
      INV_ITEM_MSG.Count_And_Get 
      (  p_count  =>  x_msg_count 
      ,  p_data   =>  x_msg_data 
      ); 
 
   WHEN FND_API.g_EXC_UNEXPECTED_ERROR THEN 
      ROLLBACK TO Delete_Category_Assignment_PVT; 
      x_return_status := FND_API.g_RET_STS_UNEXP_ERROR; 
      INV_ITEM_MSG.Count_And_Get 
      (  p_count  =>  x_msg_count 
      ,  p_data   =>  x_msg_data 
      ); 
 
   WHEN others THEN 
      ROLLBACK TO Delete_Category_Assignment_PVT; 
      x_return_status := FND_API.g_RET_STS_UNEXP_ERROR; 
 
      --INV_ITEM_MSG.Add_Unexpected_Error (Mctx, SQLERRM); 
        INV_ITEM_MSG.Add_Message 
      (  p_Msg_Name    =>  'INV_ITEM_UNEXPECTED_ERROR' 
      ,  p_token1      =>  'PKG_NAME' 
      ,  p_value1      =>  Mctx.Package_Name 
      ,  p_token2      =>  'PROCEDURE_NAME' 
      ,  p_value2      =>  Mctx.Procedure_Name 
      ,  p_token3      =>  'ERROR_TEXT' 
      ,  p_value3      =>  SQLERRM 
      ,  p_transaction_id  =>  p_transaction_id 
      ); 
 
 
      INV_ITEM_MSG.Count_And_Get 
      (  p_count  =>  x_msg_count 
      ,  p_data   =>  x_msg_data 
      ); 
 
END Delete_Category_Assignment; 
------------------------------------------------------------------------------ 
 
 
-- Get_Category_Rec_Type 
------------------------------------------------------------------------------ 
/* 
FUNCTION Get_Category_Rec_Type 
RETURN INV_ITEM_CATEGORY_PVT.CATEGORY_REC_TYPE 
IS 
   l_category_rec_type INV_ITEM_CATEGORY_PVT.CATEGORY_REC_TYPE; 
    l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0); 
BEGIN 
   RETURN l_category_rec_type; 
END; 
*/ 
 
/*Bug: 2996160 Category set dependency validations 
 Validate Flag          Hieararchy Flag              Validation 
 Y                            Y            Only Valid Categories and which 
                                          does not have children. 
 Y                            N          All Valid Categories 
 N                            Y          All categories but which does not 
                                        have  children 
 N                            N        All Categories for that structure. 
 */ 
 
FUNCTION Is_Category_Leafnode 
(  p_category_set_id    IN   NUMBER 
,  p_category_id        IN   NUMBER 
,  p_validate_flag      IN   VARCHAR2 
,  p_hierarchy_enabled IN   VARCHAR2 
) RETURN BOOLEAN 
IS 
 
   CURSOR hierarchy_and_validate_csr 
   (  p_category_set_id NUMBER 
    , p_category_id      NUMBER 
   ) IS 
      SELECT 'x' 
      FROM  mtl_Category_set_valid_cats VC 
      WHERE  VC.category_set_id = p_category_set_id 
        AND  VC.category_id = p_category_id 
        AND NOT EXISTS 
           (SELECT NULL FROM  mtl_Category_set_valid_cats 
            WHERE parent_category_id = VC.category_id 
              AND category_set_id = p_category_set_id); 
 
   CURSOR hierarchy_and_not_validate_csr 
   (  p_category_set_id NUMBER 
    , p_category_id      NUMBER 
   ) IS 
      SELECT 'x' 
      FROM  mtl_Category_set_valid_cats 
      WHERE category_set_id = p_category_set_id 
        AND parent_category_id = p_category_id ; 
 
   l_exists VARCHAR2(10); 
BEGIN 
    IF (p_hierarchy_enabled = 'Y') THEN 
     IF ( p_validate_flag  = 'Y') THEN 
       OPEN hierarchy_and_validate_csr (p_category_set_id , p_category_id); 
       FETCH hierarchy_and_validate_csr INTO l_exists; 
       IF (hierarchy_and_validate_csr%NOTFOUND) THEN 
        CLOSE hierarchy_and_validate_csr; 
        RETURN false; 
       END IF; 
       CLOSE hierarchy_and_validate_csr; 
     ELSE  --validate_flag is 'N' 
       OPEN hierarchy_and_not_validate_csr (p_category_set_id, p_category_id); 
       FETCH hierarchy_and_not_validate_csr INTO l_exists; 
       IF (hierarchy_and_not_validate_csr%FOUND) THEN 
        CLOSE hierarchy_and_not_validate_csr; 
        RETURN false; 
       END IF; 
       CLOSE hierarchy_and_not_validate_csr; 
     END IF; 
    END IF; 
    RETURN true; 
END Is_Category_Leafnode; 
 
  ---------------------------------------------------------------------------- 
  --  Create Valid Category 
  -- API to create a valid Category in Category Sets for ENI Upgrade 
  ---------------------------------------------------------------------------- 
  PROCEDURE Create_Valid_Category( 
    p_api_version         IN  NUMBER, 
    p_init_msg_list       IN  VARCHAR2 DEFAULT FND_API.G_FALSE, 
    p_commit              IN  VARCHAR2 DEFAULT FND_API.G_FALSE, 
    p_category_set_id     IN  NUMBER, 
    p_category_id         IN  NUMBER, 
    p_parent_category_id  IN  NUMBER, 
    x_return_status       OUT  NOCOPY VARCHAR2, 
    x_errorcode           OUT  NOCOPY NUMBER, 
    x_msg_count           OUT  NOCOPY NUMBER, 
    x_msg_data            OUT  NOCOPY VARCHAR2 
  ) IS 
    -- Start OF comments 
    -- API name  : Create_Valid_Category 
    -- TYPE      : Private and USed by ENI Upgrade program alone 
    -- Pre-reqs  : 11.5.10 level 
    -- FUNCTION  : Create a category. 
    --             This sets the PUB API package level variable 
    --             and calls the corresponding PUB API procedure. 
    --             This will not do validations for ENABLED_FLAG and DISABLE_DATE 
    -- END OF comments 
  BEGIN 
      INV_ITEM_CATEGORY_PUB.g_eni_upgarde_flag := 'Y'; 
      INV_ITEM_CATEGORY_PUB.Create_Valid_Category 
      ( 
        p_api_version        => p_api_version  , 
        p_init_msg_list      => p_init_msg_list, 
        p_commit             => p_commit       , 
        p_category_set_id    => p_category_set_id , 
        p_category_id        => p_category_id  , 
        p_parent_category_id => p_parent_category_id, 
        x_return_status      => x_return_status, 
        x_errorcode          => x_errorcode    , 
        x_msg_count          => x_msg_count    , 
        x_msg_data           => x_msg_data 
      ); 
      INV_ITEM_CATEGORY_PUB.g_eni_upgarde_flag := 'N'; 
  EXCEPTION 
   WHEN OTHERS THEN 
      INV_ITEM_CATEGORY_PUB.g_eni_upgarde_flag := 'N'; 
      RAISE; 
  END Create_Valid_Category; 
 
  ---------------------------------------------------------------------------- 
  --  Update Category 
  -- API to update a valid Category for ENI Upgrade 
  ---------------------------------------------------------------------------- 
  PROCEDURE Update_Valid_Category( 
    p_api_version         IN  NUMBER, 
    p_init_msg_list       IN  VARCHAR2 DEFAULT FND_API.G_FALSE, 
    p_commit              IN  VARCHAR2 DEFAULT FND_API.G_FALSE, 
    p_category_set_id     IN  NUMBER, 
    p_category_id         IN  NUMBER, 
    p_parent_category_id  IN  NUMBER, 
    x_return_status       OUT  NOCOPY VARCHAR2, 
    x_errorcode           OUT  NOCOPY NUMBER, 
    x_msg_count           OUT  NOCOPY NUMBER, 
    x_msg_data            OUT  NOCOPY VARCHAR2 
  ) IS 
    -- Start OF comments 
    -- API name  : Update_Valid_Category 
    -- TYPE      : Private and USed by ENI Upgrade program alone 
    -- Pre-reqs  : 11.5.10 level 
    -- FUNCTION  : Create a category. 
    --             This sets the PUB API package level variable 
    --             and calls the corresponding PUB API procedure. 
    --             This will not do validations for ENABLED_FLAG and DISABLE_DATE 
    -- END OF comments 
  BEGIN 
      INV_ITEM_CATEGORY_PUB.g_eni_upgarde_flag := 'Y'; 
      INV_ITEM_CATEGORY_PUB.Update_Valid_Category 
      ( 
        p_api_version        => p_api_version  , 
        p_init_msg_list      => p_init_msg_list, 
        p_commit             => p_commit       , 
        p_category_set_id    => p_category_set_id , 
        p_category_id        => p_category_id  , 
        p_parent_category_id => p_parent_category_id, 
        x_return_status      => x_return_status, 
        x_errorcode          => x_errorcode    , 
        x_msg_count          => x_msg_count    , 
        x_msg_data           => x_msg_data 
      ); 
      INV_ITEM_CATEGORY_PUB.g_eni_upgarde_flag := 'N'; 
  EXCEPTION 
   WHEN OTHERS THEN 
      INV_ITEM_CATEGORY_PUB.g_eni_upgarde_flag := 'N'; 
      RAISE; 
  END Update_Valid_Category; 
 
  -- Procedure Update_Category_Assignment added for Bug #3991044 
  PROCEDURE Update_Category_Assignment 
  ( 
     p_api_version        IN   NUMBER 
  ,  p_init_msg_list      IN   VARCHAR2 
  ,  p_commit             IN   VARCHAR2 
  ,  p_inventory_item_id  IN   NUMBER 
  ,  p_organization_id    IN   NUMBER 
  ,  p_category_set_id    IN   NUMBER 
  ,  p_category_id        IN   NUMBER 
  ,  p_old_category_id    IN   NUMBER 
  ,  p_transaction_id   IN   NUMBER 
  ,  x_return_status      OUT  NOCOPY VARCHAR2 
  ,  x_msg_count          OUT  NOCOPY NUMBER 
  ,  x_msg_data           OUT  NOCOPY VARCHAR2 
  ) 
  IS 
     l_api_name        CONSTANT  VARCHAR2(30)  := 'Update_Category_Assignment'; 
     l_api_version     CONSTANT  NUMBER        := 1.0; 
     Mctx              INV_ITEM_MSG.Msg_Ctx_type; 
     l_row_count       NUMBER; 
     l_control_level     NUMBER; 
     p_master_org_id     NUMBER; 
     l_category_struct_id       NUMBER; 
 
     l_old_category_struct_id     NUMBER; 
     l_old_category_id          NUMBER; 
     l_reccount                 NUMBER :=0; 
     l_category_set_restrict_cats VARCHAR2(1); 
     l_exists                   VARCHAR2(1); 
     l_category_set_struct_id   NUMBER; 
     l_hierarchy_enabled                VARCHAR2(1); 
     l_mult_item_cat_assign_flag  VARCHAR2(1); 
 
     CURSOR category_sets_csr (p_category_set_id  NUMBER) 
     IS 
       SELECT structure_id, 
             validate_flag, 
             mult_item_cat_assign_flag, 
             control_level, 
             hierarchy_enabled 
       FROM   mtl_category_sets_b 
       WHERE  category_set_id = p_category_set_id; 
 
     CURSOR category_set_valid_cats_csr 
     (  p_category_set_id  NUMBER 
     ,  p_category_id      NUMBER 
     ) IS 
       SELECT 'x' 
       FROM  mtl_category_set_valid_cats 
       WHERE  category_set_id = p_category_set_id 
         AND  category_id = p_category_id; 
 
 
     CURSOR category_exists_csr (p_category_id  NUMBER) 
     IS 
       SELECT  structure_id 
       FROM  mtl_categories_b 
       WHERE  category_id = p_category_id; 
 
     l_debug number := NVL(FND_PROFILE.VALUE('INV_DEBUG_TRACE'),0); 
   BEGIN 
 
      -- Set savepoint 
      SAVEPOINT Update_Category_Assignment_PVT; 
 
     -- Check for call compatibility 
      IF NOT FND_API.Compatible_API_Call (l_api_version, p_api_version, 
                                        l_api_name, G_PKG_NAME) 
       THEN 
         RAISE FND_API.g_EXC_UNEXPECTED_ERROR; 
      END IF; 
 
      -- Initialize message list 
      IF (FND_API.To_Boolean (p_init_msg_list)) THEN 
         INV_ITEM_MSG.Initialize; 
      END IF; 
 
      -- Define message context 
      Mctx.Package_Name   := G_PKG_NAME; 
      Mctx.Procedure_Name := l_api_name; 
 
      -- Initialize API return status to success 
      x_return_status := FND_API.g_RET_STS_SUCCESS; 
 
      --* Checking whether Category Set Id is valid or not 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'Checking whether Category Set Id is valid or not'); 
      END IF; 
      OPEN category_sets_csr (p_category_set_id); 
      FETCH category_sets_csr INTO l_category_set_struct_id, 
                                 l_category_set_restrict_cats, 
                                 l_mult_item_cat_assign_flag, 
                                l_control_level 
                                ,l_hierarchy_enabled; 
 
      IF (category_sets_csr%NOTFOUND) THEN 
         CLOSE category_sets_csr; 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CATEGORY_SET_ID_NOT_FOUND' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
       RAISE FND_API.g_EXC_ERROR; 
      END IF; 
      CLOSE category_sets_csr; 
 
      --* Checking whether Category Assignment exists for old category id 
      SELECT  Count(1) 
      INTO    l_reccount 
      FROM    mtl_item_categories 
      WHERE   inventory_item_id = p_inventory_item_id 
      AND     organization_id = p_organization_id 
      AND     category_set_id = p_category_set_id 
      AND     category_id = p_old_category_id; 
 
      IF l_reccount = 0 THEN 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CAT_ASSGN_NOT_FOUND' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
         RAISE FND_API.g_EXC_ERROR; 
      END IF; 
 
      --* Checking whether New Category Id is valid or not 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'Checking whether New Category Id is valid or not'); 
      END IF; 
      OPEN category_exists_csr (p_category_id); 
      FETCH category_exists_csr INTO l_category_struct_id; 
 
      IF (category_exists_csr%NOTFOUND) THEN 
        CLOSE category_exists_csr; 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CATEGORY_ID_NOT_FOUND' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
       RAISE FND_API.g_EXC_ERROR; 
      END IF; 
      CLOSE category_exists_csr; 
 
      -- Category structure_id must be the same as structure_id defined in the Category Set. 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'Checking whether Category structure id  is the same as structure_id defined in the Category Set.'); 
      END IF; 
      IF (l_category_struct_id <> l_category_set_struct_id) THEN 
       INV_ITEM_MSG.Add_Message 
       (  p_Msg_Name        =>  'INV_INVALID_CATEGORY_STRUCTURE' 
       ,  p_transaction_id  =>  p_transaction_id 
       ); 
       RAISE FND_API.g_EXC_ERROR; 
      END IF; 
 
      -- If a Category Set is defined with the VALIDATE_FLAG = 'Y' then 
      -- a Category must belong to a list of categories in the table MTL_CATEGORY_SET_VALID_CATS. 
      IF (l_category_set_restrict_cats = 'Y') THEN 
         IF (l_debug = 1) THEN 
            INV_ITEM_MSG.Debug(Mctx, 'Category Set has a restricted list of categories'); 
            INV_ITEM_MSG.Debug(Mctx, 'Validate Category Set valid category'); 
         END IF; 
 
         --* Validating whether new category id exists in table MTL_CATEGORY_SET_VALID_CATS 
         OPEN category_set_valid_cats_csr (p_category_set_id, p_category_id); 
         FETCH category_set_valid_cats_csr INTO l_exists; 
         IF (category_set_valid_cats_csr%NOTFOUND) THEN 
            CLOSE category_set_valid_cats_csr; 
            INV_ITEM_MSG.Add_Message 
           (  p_Msg_Name        =>  'INV_CATEGORY_NOT_IN_VALID_SET' 
            ,  p_transaction_id  =>  p_transaction_id 
           ); 
           RAISE FND_API.g_EXC_ERROR; 
         END IF; 
         CLOSE category_set_valid_cats_csr; 
      END IF; 
 
      --* Disallow updation if category is master controlled and current org 
      --* is not master org. 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'Select Master Org from Mtl_Parameters'); 
      END IF; 
 
      SELECT MASTER_ORGANIZATION_ID 
      INTO   p_master_org_id 
      FROM   mtl_parameters 
      WHERE  organization_id = p_organization_id; 
 
      IF ((l_control_level = 1) and (p_organization_id <> p_master_org_id)) THEN 
         INV_ITEM_MSG.Add_Message 
         (  p_Msg_Name        =>  'INV_CAT_CANNOT_CREATE_DELETE' 
          ,  p_transaction_id  =>  p_transaction_id 
         ); 
         RAISE FND_API.g_EXC_ERROR; 
      END IF; 
 
 
      --* checking for duplicate records 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'Checking for duplicate records'); 
      END IF; 
      SELECT  Count(1) 
      INTO    l_reccount 
      FROM    mtl_item_categories 
      WHERE   inventory_item_id = p_inventory_item_id 
      AND     organization_id = p_organization_id 
      AND     category_set_id = p_category_set_id 
      AND     category_id = p_category_id; 
 
      IF l_reccount > 0 THEN 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_CAT_ASSGN_ALREADY_EXISTS' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
         RAISE FND_API.g_EXC_ERROR; 
      END IF; 
 
      --* Validating if new category is leafnode or not 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'Validate If new category is leafnode or not'); 
      END IF; 
 
      IF  NOT Is_Category_Leafnode ( p_category_set_id, 
                                  p_category_id, 
                                  l_category_set_restrict_cats, 
                                  l_hierarchy_enabled ) THEN 
        INV_ITEM_MSG.Add_Message 
        (  p_Msg_Name        =>  'INV_ITEM_CAT_ASSIGN_LEAF_ONLY' 
        ,  p_transaction_id  =>  p_transaction_id 
        ); 
          RAISE FND_API.g_EXC_ERROR; 
      END IF; 
 
 
      --* Updating Master Org or Master Org + Child Orgs depending on Control Level 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'Updating Mtl_Item_Categories...'); 
      END IF; 
 
      IF ((l_control_level = 1) and (p_organization_id = p_master_org_id)) THEN 
--          UPDATE  /*+ INDEX(MIC MTL_ITEM_CATEGORIES_U1) */ 
          UPDATE 
		 Mtl_Item_Categories MIC 
          SET    Category_Id = p_category_id 
                ,last_update_date  = SYSDATE 
                ,last_updated_by   = FND_GLOBAL.user_id 
                ,last_update_login = FND_GLOBAL.login_id 
                ,request_id        = FND_GLOBAL.conc_request_id -- 4105867 
          WHERE  category_set_id+0 = p_category_set_id 
          AND    category_id = p_old_category_id 
          AND    inventory_item_id = p_inventory_item_id 
          AND    organization_id+0 =(SELECT organization_id 
                                FROM   mtl_parameters p 
                                WHERE  p.master_organization_id = p_master_org_id 
                                AND    p.organization_id = mic.organization_id); 
      ELSE 
         UPDATE Mtl_Item_Categories 
         SET    Category_Id = p_category_id 
                ,last_update_date  = SYSDATE 
                ,last_updated_by   = FND_GLOBAL.user_id 
                ,last_update_login = FND_GLOBAL.login_id 
                ,request_id        = FND_GLOBAL.conc_request_id --4105867 
         WHERE  organization_id   = p_organization_id 
         AND     inventory_item_id = p_inventory_item_id 
         AND     category_set_id = p_category_set_id 
         AND     category_id = p_old_category_id; 
      END IF; 
 
      IF (l_debug = 1) THEN 
         INV_ITEM_MSG.Debug(Mctx, 'after update FROM mtl_item_categories'); 
      END IF; 
 
      -- Standard check of p_commit 
      IF (FND_API.To_Boolean (p_commit)) THEN 
         COMMIT WORK; 
      END IF; 
 
      INV_ITEM_MSG.Count_And_Get 
      (  p_count  =>  x_msg_count 
       ,  p_data   =>  x_msg_data 
      ); 
 
      EXCEPTION 
 
         WHEN FND_API.g_EXC_ERROR THEN 
            ROLLBACK TO Update_Category_Assignment_PVT; 
            x_return_status := FND_API.g_RET_STS_ERROR; 
            INV_ITEM_MSG.Count_And_Get 
            (  p_count  =>  x_msg_count 
            ,  p_data   =>  x_msg_data 
             ); 
 
         WHEN FND_API.g_EXC_UNEXPECTED_ERROR THEN 
            ROLLBACK TO Update_Category_Assignment_PVT; 
            x_return_status := FND_API.g_RET_STS_UNEXP_ERROR; 
            INV_ITEM_MSG.Count_And_Get 
            (  p_count  =>  x_msg_count 
               ,  p_data   =>  x_msg_data 
            ); 
 
         WHEN others THEN 
            ROLLBACK TO Update_Category_Assignment_PVT; 
            x_return_status := FND_API.g_RET_STS_UNEXP_ERROR; 
 
            INV_ITEM_MSG.Add_Message 
            (  p_Msg_Name    =>  'INV_ITEM_UNEXPECTED_ERROR' 
            ,  p_token1      =>  'PKG_NAME' 
            ,  p_value1      =>  Mctx.Package_Name 
            ,  p_token2      =>  'PROCEDURE_NAME' 
            ,  p_value2      =>  Mctx.Procedure_Name 
            ,  p_token3      =>  'ERROR_TEXT' 
            ,  p_value3      =>  SQLERRM 
            ,  p_transaction_id  =>  p_transaction_id 
            ); 
 
 
         INV_ITEM_MSG.Count_And_Get 
         (  p_count  =>  x_msg_count 
         ,  p_data   =>  x_msg_data 
         ); 
 
   END Update_Category_Assignment; 
   -- End of code for Bug #3991044 
 
END INV_ITEM_CATEGORY_PVT; 
/

