CREATE OR REPLACE PACKAGE BODY XX_APC_ITEM_CATEGORY_PKG
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |            Oracle NAIO Consulting Organization                                          |
-- +=========================================================================================+
-- | Name        : XX_APC_ITEM_CATEGORY_PKG                                                  |
-- | Description : To import Categories from Oracle Inventory into Advanced Product Catalog  |
-- |               and its usage                                                             |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |DRAFT 1A   14-MAR-2007     Prakash Sowriraj     Initial draft version                    |
-- |DRAFT 1B   11-JUN-2007     Prakash Sowriraj     Delete API has been modified to delete   |
-- |                                                categories permanently from APC          |
-- |DRAFT 1C   24-JUL-2007     Prakash Sowriraj     Modified to handle duplicate segments    |
-- |                                                in the Inventory Categories              |
-- |                                                (Example : A.B.C.B.D )                   |
-- |                                                categories permanently from APC          |
-- |Draft 1D 17-Sep-2007       Piyush Khandelwal    Modified to add error handling part and  |
-- |                                                to add logic to insert categories detail |
-- |                                                in sales screen.                         |
-- |Draft 1.0 13-Nov-2007      Piyush Khandelwal    Modified the error handling part and     |
-- |                                                incorporated the onsite code review      |
-- |                                                comments                                 |
-- +=========================================================================================+

AS

gc_conc_prg_id    PLS_INTEGER DEFAULT -1;
g_MISS_CHAR       VARCHAR2(1)  :=  fnd_api.g_MISS_CHAR;
g_MISS_NUM        NUMBER       :=  fnd_api.g_MISS_NUM;
g_MISS_DATE       DATE         :=  fnd_api.g_MISS_DATE;
g_errbuf          VARCHAR2(2000);
g_inv_status_flag NUMBER := 0;
-- +===================================================================+
-- | Name        : create_category_main                                |
-- | Description : This procedure will be called from the Concurrent   |
-- |               Program 'OD: APC Synchronize Product Hierarchies'   |
-- | Parameters  : p_inv_date                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_category_main
    (
         x_errbuf       OUT   NOCOPY    VARCHAR2
        ,x_retcode      OUT   NOCOPY    VARCHAR2
        ,p_inv_date     IN              VARCHAR2
    )
AS

ln_inv_category_set_id      MTL_CATEGORY_SETS_B.CATEGORY_SET_ID%TYPE;
ln_inv_structure_id         MTL_CATEGORY_SETS_B.STRUCTURE_ID%TYPE;
lc_inv_structure_name       FND_ID_FLEX_STRUCTURES_TL.ID_FLEX_STRUCTURE_NAME%TYPE;
lc_inv_flex_structure_code  FND_ID_FLEX_STRUCTURES.ID_FLEX_STRUCTURE_CODE%TYPE;
ln_apc_category_set_id      MTL_CATEGORY_SETS_B.CATEGORY_SET_ID%TYPE;
ln_apc_structure_id         MTL_CATEGORY_SETS_B.STRUCTURE_ID%TYPE;
lc_apc_structure_name       FND_ID_FLEX_STRUCTURES_TL.ID_FLEX_STRUCTURE_NAME%TYPE;
ln_application_id           FND_ID_FLEX_STRUCTURES.application_id%TYPE;
lc_inv_flex_code            FND_ID_FLEX_STRUCTURES.ID_FLEX_CODE%TYPE;
ln_inv_flex_num             FND_ID_FLEX_STRUCTURES.ID_FLEX_NUM%TYPE;
lc_apc_flex_code            FND_ID_FLEX_STRUCTURES.ID_FLEX_CODE%TYPE;
ln_apc_flex_num             FND_ID_FLEX_STRUCTURES.ID_FLEX_NUM%TYPE;
lc_apc_flex_structure_code  FND_ID_FLEX_STRUCTURES.ID_FLEX_STRUCTURE_CODE%TYPE;
lb_cat_rel_exist            BOOLEAN;
ln_cat_id                   NUMBER := NULL;
ln_prev_cat_id              NUMBER := NULL;
ln_no_of_inv_cat            NUMBER := 0;
ln_security_group_id        NUMBER;
ln_server_id                NUMBER;
ln_request_id               NUMBER :=0;
lv_error                    VARCHAR2(1000);
lb_is_update                BOOLEAN;
lc_description              VARCHAR2(2000);
ld_inv_disable_date         DATE;

--Cursor to fetch the Product Hierarchies from Oracle Inventory
CURSOR lcu_cat_cur
IS
SELECT  '1'||segment1
       ,'2'||segment2
       ,'3'||segment3
       ,'4'||segment4
       ,'5'||segment5
       ,disable_date
FROM    mtl_categories
WHERE   structure_id = (SELECT  structure_id
        FROM    mtl_category_sets
        WHERE   category_set_id = (SELECT  category_set_id
                FROM    mtl_default_category_sets
                WHERE   functional_area_id = (
                        SELECT  lookup_code
                        FROM    mfg_lookups
                        WHERE   lookup_type = 'MTL_FUNCTIONAL_AREAS'
                        AND     meaning = 'Inventory'
                )
        )
)
AND last_update_date BETWEEN fnd_date.canonical_to_date(p_inv_date) AND SYSDATE
order by last_update_date ASC;

BEGIN

 -- Fetch the concurrent program id

   gc_conc_prg_id := FND_GLOBAL.CONC_REQUEST_ID;

    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, '******************Advanced Product Catalog******************');
    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10));
    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, '******************Begin******************');
    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10));

    Fnd_File.PUT_LINE(Fnd_File.LOG, '******************Advanced Product Catalog******************');
    Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10));
    Fnd_File.PUT_LINE(Fnd_File.LOG, '******************Begin******************');
    Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10));

    Fnd_File.PUT_LINE(Fnd_File.LOG, 'p_inv_date:'||p_inv_date);

    --1.Retrieving default_category_set_id, structure_id, structure_name for 'Inventory'
        
    get_default_inv_details
        (    x_inv_category_set_id   => ln_inv_category_set_id
            ,x_inv_structure_id      => ln_inv_structure_id
            ,x_inv_structure_name    => lc_inv_structure_name
        );
        
        IF g_inv_status_flag = 1 THEN   
        x_retcode := 2;
        RETURN;
        END IF;
     
     
     --2.Retrieving default_category_set_id, structure_id, structure_name for 'Product Reporting'
    get_default_apc_details
        (    x_apc_category_set_id   => ln_apc_category_set_id
            ,x_apc_structure_id      => ln_apc_structure_id
            ,x_apc_structure_name    => lc_apc_structure_name
        );
        IF g_inv_status_flag = 1 THEN   
        x_retcode := 2;
        RETURN;
        END IF;
         
        
    --3. Retrieving application_id, flex_code, flex_num, flex_structure_code for 'Inventory'
    get_inv_flex_details
        (
             p_inv_structure_name      => lc_inv_structure_name
            ,x_application_id          => ln_application_id
            ,x_inv_flex_code           => lc_inv_flex_code
            ,x_inv_flex_num            => ln_inv_flex_num
            ,x_inv_flex_structure_code => lc_inv_flex_structure_code
        );

        IF g_inv_status_flag = 1 THEN   
        x_retcode :=2;
        RETURN;
        END IF;
        
    --4.Retrieving application_id, flex_code, flex_num, flex_structure_code for 'Product Reporting'
    get_apc_flex_details
        (
             p_apc_structure_name      => lc_apc_structure_name
            ,x_application_id          => ln_application_id
            ,x_apc_flex_code           => lc_apc_flex_code
            ,x_apc_flex_num            => ln_apc_flex_num
            ,x_apc_flex_structure_code => lc_apc_flex_structure_code
        );
        
        IF g_inv_status_flag = 1 THEN   
        x_retcode :=2;
        RETURN;
        END IF;

    OPEN lcu_cat_cur;
    LOOP
        ln_no_of_inv_cat := ln_no_of_inv_cat + 1;
        FETCH lcu_cat_cur INTO CAT_SEG_TBL(ln_no_of_inv_cat);
        EXIT WHEN lcu_cat_cur%NOTFOUND;
    END LOOP;
    CLOSE lcu_cat_cur;

    IF CAT_SEG_TBL IS NULL OR CAT_SEG_TBL.COUNT = 0 THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'No Product Hierarchies fetched from Oracle Inventory');
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10));
        Fnd_File.PUT_LINE(Fnd_File.LOG, 'No Product Hierarchies fetched from Oracle Inventory');
        Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10));
        
        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0054_NO_PROD_HIER_EXIST');
        g_errbuf := FND_MESSAGE.GET;
        --x_retcode := 1;
        
        XX_COM_ERROR_LOG_PUB.log_error_crm (       
                     p_application_name        => G_APPLICATION_NAME
                    ,p_program_type            => G_PROGRAM_TYPE                    
                    ,p_program_name            => G_PROGRAM_NAME
                    ,p_program_id              => gc_conc_prg_id
                    ,p_module_name             => G_MODULE_NAME
                    ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.create_category_main'
                    ,p_error_message_code      => 'XX_TM_0054_NO_PROD_HIER_EXIST'
                    ,p_error_message           => g_errbuf
                    ,p_error_message_severity  => 'MEDIUM'
                    ,p_error_status            => G_ERROR_STATUS_FLAG 
                    );       
       
    ELSE
        IF CAT_SEG_TBL.COUNT > 0 THEN
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Total number of Product Hierarchies fetched from Inventory:'||CAT_SEG_TBL.COUNT);
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10));
            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Total number of Product Hierarchies fetched from Inventory:'||CAT_SEG_TBL.COUNT);
            Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10));

            --Main FOR LOOP to loop through each inventory category code
            FOR idx IN 1 .. CAT_SEG_TBL.last LOOP

                G_MISS_L_TBL(1).SEG_VAL := CAT_SEG_TBL(idx).SEGMENT1;
                G_MISS_L_TBL(2).SEG_VAL := CAT_SEG_TBL(idx).SEGMENT2;
                G_MISS_L_TBL(3).SEG_VAL := CAT_SEG_TBL(idx).SEGMENT3;
                G_MISS_L_TBL(4).SEG_VAL := CAT_SEG_TBL(idx).SEGMENT4;
                G_MISS_L_TBL(5).SEG_VAL := CAT_SEG_TBL(idx).SEGMENT5;
                ld_inv_disable_date     := CAT_SEG_TBL(idx).DISABLE_DATE;

                Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10)||'Inventory Category:'||idx||'->'||G_MISS_L_TBL(1).SEG_VAL||'.'||G_MISS_L_TBL(2).SEG_VAL||'.'||G_MISS_L_TBL(3).SEG_VAL||'.'||G_MISS_L_TBL(4).SEG_VAL||'.'||G_MISS_L_TBL(5).SEG_VAL);

                Fnd_File.PUT_LINE(Fnd_File.OUTPUT, '--------------------------------------------------------------');
                Fnd_File.PUT_LINE(Fnd_File.OUTPUT, '**************************** BEGIN ***********************************');
                Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10));
                Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10)||'Inventory Category:'||idx||'->'||G_MISS_L_TBL(1).SEG_VAL||'.'||G_MISS_L_TBL(2).SEG_VAL||'.'||G_MISS_L_TBL(3).SEG_VAL||'.'||G_MISS_L_TBL(4).SEG_VAL||'.'||G_MISS_L_TBL(5).SEG_VAL);
                Fnd_File.PUT_LINE(Fnd_File.LOG,' --------------------------------------------------------------');
                Fnd_File.PUT_LINE(Fnd_File.LOG, '**************************** BEGIN ***********************************');
                Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10));

                IF(ld_inv_disable_date IS NULL OR ld_inv_disable_date > SYSDATE ) THEN
                    --Loop through each segment from inventory category code
                    FOR idx in 1..5 LOOP
                        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10)||'APC Category:'||idx||'->'||G_MISS_L_TBL(idx).SEG_VAL);
                        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, '---------------------------------------------------------------');

                        Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10)||'APC Category:'||idx||'->'||G_MISS_L_TBL(idx).SEG_VAL);
                        Fnd_File.PUT_LINE(Fnd_File.LOG, '---------------------------------------------------------------');

                        --Checking whether the category already exists in APC
                        ln_cat_id := check_category
                            (
                                 p_cat_var             => G_MISS_L_TBL(idx).SEG_VAL
                                ,p_apc_structure_id    => ln_apc_structure_id
                            );

                        IF (ln_cat_id IS NULL) THEN
                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10)||'Category '||G_MISS_L_TBL(idx).SEG_VAL||' does not exist in APC..So create it in APC');
                            Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10)||'Category '||G_MISS_L_TBL(idx).SEG_VAL||' does not exist in APC..So create it in APC');

                                                        
                            --Create a new Category in APC
                            create_category
                                (
                                     p_cat_var               => G_MISS_L_TBL(idx).SEG_VAL
                                    ,p_seg_name              => 'SEGMENT'||idx
                                    ,p_inv_flex_num          => ln_inv_flex_num
                                    ,p_inv_flex_code         => lc_inv_flex_code
                                    ,p_apc_structure_id      => ln_apc_structure_id
                                    ,p_apc_structure_code    => lc_apc_flex_structure_code
                                    ,x_cat_id                => ln_cat_id
                                );
                                
                               IF g_inv_status_flag = 1 THEN   
                                  x_retcode := 1;
                               END IF;
                        ELSE

                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Category '||G_MISS_L_TBL(idx).SEG_VAL ||' already exists in APC');
                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Checking the Description for category '||G_MISS_L_TBL(idx).SEG_VAL);
                            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Category '||G_MISS_L_TBL(idx).SEG_VAL ||' already exists in APC');
                            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Checking the Description for category '||G_MISS_L_TBL(idx).SEG_VAL);

                            --Checking whether the Category Description in APC is as same as in the Inventory
                            check_description(
                                         p_cat_var               => G_MISS_L_TBL(idx).SEG_VAL
                                        ,p_seg_name              => 'SEGMENT'||idx
                                        ,p_inv_flex_num          => ln_inv_flex_num
                                        ,p_inv_flex_code         => lc_inv_flex_code
                                        ,p_cat_id                => ln_cat_id
                                        ,x_is_update             => lb_is_update
                                        ,x_description           => lc_description);
                            BEGIN
                                IF(lb_is_update = TRUE) THEN

                                    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'The Description for category '||G_MISS_L_TBL(idx).SEG_VAL||' has been changed in Inventory..So change it to be in sync with Inventory');
                                    Fnd_File.PUT_LINE(Fnd_File.LOG, 'The Description for category '||G_MISS_L_TBL(idx).SEG_VAL||' has been changed in Inventory..So change it to be in sync with Inventory');

                                    --Change the Category Description in APC
                                    update_description(
                                                 p_cat_id                =>ln_cat_id
                                                ,p_description           =>lc_description);
                                    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'The Description for category '||G_MISS_L_TBL(idx).SEG_VAL||' has been successfully updated in APC');
                                    Fnd_File.PUT_LINE(Fnd_File.LOG, 'The Description for category '||G_MISS_L_TBL(idx).SEG_VAL||' has been successfully updated in APC');

                                    
                                ELSE

                                    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'The Descriptions are same in APC and Inventory');
                                    Fnd_File.PUT_LINE(Fnd_File.LOG, 'The Descriptions are same in APC and Inventory');

                                                                                  
                                END IF;

                            EXCEPTION
                                WHEN OTHERS THEN
                                    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Error in updating the category Description'||G_MISS_L_TBL(idx).SEG_VAL||'SQL Error:'||SQLERRM);
                                    Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in updating the category Description'||G_MISS_L_TBL(idx).SEG_VAL||'SQL Error:'||SQLERRM);
                            
                                    /*Call API for inserting records in error table*/
                                    FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0063_ERR_DESC_UPDATE');
                                    FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
                                    g_errbuf := FND_MESSAGE.GET;
                                    x_retcode :=1;

                                    XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.create_category_main'
                                        ,p_error_message_code      => 'XX_TM_0063_ERR_DESC_UPDATE'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );   
                            END;
                        END IF;

                        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10)||'Category Relationships');
                        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, '----------------------');
                        Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10)||'Category Relationships');
                        Fnd_File.PUT_LINE(Fnd_File.LOG, '----------------------');

                        IF (idx = 1) THEN
                            ln_prev_cat_id := NULL;
                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Parent Category : '||G_MISS_L_TBL(idx).SEG_VAL);
                            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Parent Category : '||G_MISS_L_TBL(idx).SEG_VAL);
                        ELSE
                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Child Category : '||G_MISS_L_TBL(idx).SEG_VAL);
                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Parent Category : '||G_MISS_L_TBL(idx-1).SEG_VAL);
                            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Child Category : '||G_MISS_L_TBL(idx).SEG_VAL);
                            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Parent Category : '||G_MISS_L_TBL(idx-1).SEG_VAL);
                        END IF;


                        --Checking whether to update the exisiting category relationship
                        --between Child and Parent Categories
                        lb_cat_rel_exist := is_update_category_relation
                            (
                                 p_child_cat           => ln_cat_id
                                ,p_parent_cat          => ln_prev_cat_id
                                ,p_apc_cat_set_id      => ln_apc_category_set_id
                            );

                        IF (lb_cat_rel_exist = TRUE) THEN
                                IF(idx > 1) THEN
                                    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Updating the Category Relationship between '||G_MISS_L_TBL(idx).SEG_VAL|| ' & '||G_MISS_L_TBL(idx-1).SEG_VAL);
                                    Fnd_File.PUT_LINE(Fnd_File.LOG, 'Updating the Category Relationship between '||G_MISS_L_TBL(idx).SEG_VAL|| ' & '||G_MISS_L_TBL(idx-1).SEG_VAL);
                                END IF;
                                --Update the existing Category Relationship
                                --between Child and Parent categories
                                update_category_relation
                                    (
                                         p_child_cat           => ln_cat_id
                                        ,p_parent_cat          => ln_prev_cat_id
                                        ,p_apc_cat_set_id      => ln_apc_category_set_id
                                    );
                                    
                                    IF g_inv_status_flag =1 THEN
                                    x_retcode := 1;
                                    END IF;
                        ELSE
                                --Checking whether to create a category relationship
                                --between Child and Parent Categories
                                lb_cat_rel_exist := is_create_category_relation
                                    (
                                         p_child_cat      => ln_cat_id
                                        ,p_parent_cat     => ln_prev_cat_id
                                        ,p_apc_cat_set_id => ln_apc_category_set_id
                                    );

                                IF (lb_cat_rel_exist = TRUE) THEN
                                    IF(idx = 1) THEN
                                        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Creating a new Category Relationship for the Parent Category '||G_MISS_L_TBL(idx).SEG_VAL);
                                        Fnd_File.PUT_LINE(Fnd_File.LOG, 'Creating a new Category Relationship for the Parent Category '||G_MISS_L_TBL(idx).SEG_VAL);
                                    ELSE
                                        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Creating a new Category Relationship between '||G_MISS_L_TBL(idx).SEG_VAL|| ' & '||G_MISS_L_TBL(idx-1).SEG_VAL);
                                        Fnd_File.PUT_LINE(Fnd_File.LOG, 'Creating a new Category Relationship between '||G_MISS_L_TBL(idx).SEG_VAL|| ' & '||G_MISS_L_TBL(idx-1).SEG_VAL);
                                    END IF;
                                    --Create a new Category Relationship
                                    --between Child and Parent categories
                                    create_category_relation
                                        (
                                             p_child_cat            => ln_cat_id
                                            ,p_parent_cat           => ln_prev_cat_id
                                            ,p_apc_cat_set_id       => ln_apc_category_set_id
                                        );
                                        
                                        IF g_inv_status_flag =1 THEN
                                           x_retcode := 1;
                                        END IF;
                                ELSE
                                    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Note:Category Relationship already exists for this category');
                                    Fnd_File.PUT_LINE(Fnd_File.LOG, 'Note:Category Relationship already exists for this category');
                                                                   
                                END IF;
                        END IF;
                        ln_prev_cat_id := ln_cat_id;
                        BEGIN
                             Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Before Calling custom procedure:'||idx);
                             Fnd_File.PUT_LINE(Fnd_File.LOG, 'Before Calling custom procedure:'||idx);
                            
                             INSERT_EGO_RECORDS
                                   (
                                     ln_apc_category_set_id
                                    ,ln_cat_id
                                   );
                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'After Calling custom procedure:'||idx);
                            Fnd_File.PUT_LINE(Fnd_File.LOG, 'After Calling custom procedure:'||idx);                  
                            EXCEPTION
                              WHEN OTHERS THEN
                               Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in INSERT_EGO_RECORDS :'||SQLERRM);
                               Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in INSERT_EGO_RECORDS:'||SQLERRM); 
                               
                               /*Call API for inserting records in error table*/
                               FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0057_ERR_EGO_REC');
                               FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
                               g_errbuf := FND_MESSAGE.GET;
                               x_retcode := 1;

                                XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.create_category_main'
                                        ,p_error_message_code      => 'XX_TM_0057_ERR_EGO_REC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );   
                        END;                        

                    END LOOP;
                ELSE
                    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'This Category has been disabled in the Inventory');
                    Fnd_File.PUT_LINE(Fnd_File.LOG, 'This Category has been disabled in the Inventory');

                    delete_apc_category(
                                        p_cat_seg_tbl           =>CAT_SEG_TBL(idx)
                                       ,p_apc_structure_id      =>ln_apc_structure_id
                                       ,p_apc_category_set_id   =>ln_apc_category_set_id);
                                       
                                       IF g_inv_status_flag =1 THEN
                                           x_retcode := 1;
                                        END IF;
                END IF;
                Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10)||'**************************** END ***********************************');
                Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10)||'**************************** END ***********************************');
            END LOOP;
        END IF;
    END IF;

    --Calling the seeded concurrent program 'Load Catalog Hierarchy'
    BEGIN
       /* FND_GLOBAL.APPS_INITIALIZE(FND_GLOBAL.USER_ID
                                 , ln_resp_id
                                 , ln_resp_appl_id
                                 , ln_security_group_id
                                 , ln_server_id);*/
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, CHR(10)||'Calling Seeded Concurrent Program Load Catalog Hierarchy');
        Fnd_File.PUT_LINE(Fnd_File.LOG, CHR(10)||'Calling Seeded Concurrent Program Load Catalog Hierarchy');
        ln_request_id := FND_REQUEST.SUBMIT_REQUEST('ENI',
                                                 'ENI_DEN_INIT',
                                                 'Load Catalog Hierarchy',
                                                  '',
                                                  FALSE,
                                                  'FULL',
                                                  CHR(0));
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'ln_request_id:'||ln_request_id);
        Fnd_File.PUT_LINE(Fnd_File.LOG, 'ln_request_id:'||ln_request_id);
        lv_error := fnd_message.get;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Error in Running the Concurrent Program'||SQLERRM);
            Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in Running the Concurrent Program'||SQLERRM);
            
            /*Call API for inserting records in error table*/
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0073_CONC_PRG_ERR');
            FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
            g_errbuf := FND_MESSAGE.GET;
            x_retcode := 1;

            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => ln_request_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.create_category_main'
                                        ,p_error_message_code      => 'XX_TM_0073_CONC_PRG_ERR'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );   
    END;--End of seeded concurrent program 'Load Catalog Hierarchy'

    Fnd_File.PUT_LINE(Fnd_File.OUTPUT, '**********************End of Program****************');
    Fnd_File.PUT_LINE(Fnd_File.LOG, '**********************End of Program****************');

END create_category_main;


-- +===================================================================+
-- | Name        : get_default_inv_details                             |
-- | Description : Procedure to get default inventory details from the |
-- |               fucntional area 'Inventory'                         |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns       x_inv_category_set_id,x_inv_structure_id            |
-- |               x_inv_structure_name                                |
-- +===================================================================+
PROCEDURE get_default_inv_details
    (
         x_inv_category_set_id   OUT   NOCOPY   NUMBER
        ,x_inv_structure_id      OUT   NOCOPY   NUMBER
        ,x_inv_structure_name    OUT   NOCOPY   VARCHAR2
    )
AS

BEGIN

    SELECT   category_set_id
            ,structure_id
            ,structure_name
    INTO     x_inv_category_set_id
            ,x_inv_structure_id
            ,x_inv_structure_name
    FROM    mtl_category_sets_v
    WHERE   category_set_id = (SELECT  category_set_id
            FROM    mtl_default_category_sets
            WHERE   functional_area_id =(SELECT  lookup_code
                    FROM    mfg_lookups
                    WHERE   lookup_type = 'MTL_FUNCTIONAL_AREAS'
                   AND     meaning = 'Inventory'
             )
    );

EXCEPTION
    WHEN OTHERS THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Error in fetching default category set details of INV (Contact SYSADMIN) :'||SQLERRM);
        Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in fetching default category set details of INV (Contact SYSADMIN) :'||SQLERRM);
        
        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0050_ERR_DEF_CA_SET_INV');
        FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
        g_errbuf := FND_MESSAGE.GET;
        g_inv_status_flag := 1;
        XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.get_default_inv_details'
                                        ,p_error_message_code      => 'XX_TM_0050_ERR_DEF_CA_SET_INV'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );   
END get_default_inv_details;


-- +===================================================================+
-- | Name        : get_default_apc_details                             |
-- | Description : Procedure to get default APC details from the       |
-- |               functional area 'Product Reporting'                 |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns       x_apc_category_set_id,x_apc_structure_id            |
-- |               x_apc_structure_name                                |
-- +===================================================================+
PROCEDURE get_default_apc_details
    (
         x_apc_category_set_id   OUT   NOCOPY     NUMBER
        ,x_apc_structure_id      OUT   NOCOPY     NUMBER
        ,x_apc_structure_name    OUT   NOCOPY     VARCHAR2
    )
AS

BEGIN

    SELECT   category_set_id
            ,structure_id
            ,structure_name
    INTO     x_apc_category_set_id
            ,x_apc_structure_id
            ,x_apc_structure_name
    FROM    mtl_category_sets_v
    WHERE   category_set_id = (SELECT  category_set_id
            FROM    mtl_default_category_sets
            WHERE   functional_area_id = (SELECT  lookup_code
                    FROM    mfg_lookups
                    WHERE   lookup_type = 'MTL_FUNCTIONAL_AREAS'
                    AND     meaning = 'Product Reporting'
            )
    );

EXCEPTION
    WHEN OTHERS THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Error in fetching default category set details of APC (Contact SYSADMIN) :'||SQLERRM);
        Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in fetching default category set details of APC (Contact SYSADMIN) :'||SQLERRM);

        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0051_ERR_DEF_CA_SET_APC');
        FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
        g_errbuf := FND_MESSAGE.GET;
        g_inv_status_flag :=1;

        XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.get_default_apc_details'
                                        ,p_error_message_code      => 'XX_TM_0051_ERR_DEF_CA_SET_APC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );  
END get_default_apc_details;


-- +===================================================================+
-- | Name        : get_inv_flex_details                                |
-- | Description : Procedure to get the flex field structure details   |
-- |               for Inventory                                       |
-- | Parameters :  p_inv_structure_name                                |
-- |                                                                   |
-- | Returns       x_inv_flex_code,x_inv_flex_num                      |
-- |               x_inv_flex_structure_code                           |
-- +===================================================================+
PROCEDURE get_inv_flex_details
    (
         p_inv_structure_name      IN               VARCHAR2
        ,x_application_id          OUT   NOCOPY     NUMBER
        ,x_inv_flex_code           OUT   NOCOPY     VARCHAR2
        ,x_inv_flex_num            OUT   NOCOPY     NUMBER
        ,x_inv_flex_structure_code OUT   NOCOPY     VARCHAR2
    )
AS

BEGIN

    SELECT   application_id
            ,id_flex_code
            ,id_flex_num
            ,id_flex_structure_code
    INTO     x_application_id
            ,x_inv_flex_code
            ,x_inv_flex_num
            ,x_inv_flex_structure_code
    FROM    fnd_id_flex_structures_vl
    WHERE   id_flex_structure_name = p_inv_structure_name;

EXCEPTION
    WHEN OTHERS THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Error in fetching INV details:'||SQLERRM);
        Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in fetching INV details:'||SQLERRM);
        
        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0052_ERR_FETCH_INV_D');
        FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
        g_errbuf := FND_MESSAGE.GET;
        g_inv_status_flag :=1;
        

         XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.get_inv_flex_details'
                                        ,p_error_message_code      => 'XX_TM_0052_ERR_FETCH_INV_D'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );  


END get_inv_flex_details;


-- +===================================================================+
-- | Name        : get_apc_flex_details                                |
-- | Description : Procedure to get the flex field structure details   |
-- |               for 'Product Reporting'(APC)                        |
-- | Parameters  : p_apc_structure_name                                |
-- |                                                                   |
-- | Returns       x_apc_flex_code,x_apc_flex_num                      |
-- |               x_apc_flex_structure_code                           |
-- +===================================================================+
PROCEDURE get_apc_flex_details
    (
         p_apc_structure_name      IN               VARCHAR2
        ,x_application_id          OUT   NOCOPY     NUMBER
        ,x_apc_flex_code           OUT   NOCOPY     VARCHAR2
        ,x_apc_flex_num            OUT   NOCOPY     NUMBER
        ,x_apc_flex_structure_code OUT   NOCOPY     VARCHAR2
    )

AS

BEGIN

    SELECT   application_id
            ,id_flex_code
            ,id_flex_num
            ,id_flex_structure_code
    INTO     x_application_id
            ,x_apc_flex_code
            ,x_apc_flex_num
            ,x_apc_flex_structure_code
    FROM    fnd_id_flex_structures_vl
    WHERE   id_flex_structure_name = p_apc_structure_name;
    

EXCEPTION
    WHEN OTHERS THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Error in fetching APC details:'||SQLERRM);
        Fnd_File.PUT_LINE(Fnd_File.LOG, 'Error in fetching APC details:'||SQLERRM);
        
        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0053_ERR_FETCH_APC_D');
        FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
        g_errbuf := FND_MESSAGE.GET;
        g_inv_status_flag :=1;
       

        XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.get_apc_flex_details'
                                        ,p_error_message_code      => 'XX_TM_0053_ERR_FETCH_APC_D'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );  

END get_apc_flex_details;


-- +===================================================================+
-- | Name        : check_category                                      |
-- | Description : Function to check wether already exists in APC      |
-- |               Program 'OD: APC Synchronize Product Hierarchies'   |
-- |                                                                   |
-- | Parameters :  p_cat_var                                           |
-- |               p_apc_structure_id                                  |
-- |                                                                   |
-- +===================================================================+
FUNCTION check_category
    (
        p_cat_var           VARCHAR2
       ,p_apc_structure_id  NUMBER

    )   RETURN NUMBER
AS

ln_category_id  mtl_categories_b.category_id%TYPE := NULL;

BEGIN


    -- Check whether the category already created in APC
    SELECT  category_id
    INTO    ln_category_id
    FROM    mtl_categories_b
    WHERE   structure_id = p_apc_structure_id
    AND     segment1     = p_cat_var
    AND     ROWNUM=1;

    IF ln_category_id IS NOT NULL THEN
        RETURN ln_category_id;
    ELSE
        RETURN NULL;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;

END check_category;


-- +===================================================================+
-- | Name        : create_category                                     |
-- | Description : Procedure to create a new category in APC           |
-- |               Program 'OD: APC Synchronize Product Hierarchies'   |
-- |                                                                   |
-- | Parameters :  p_cat_var,p_seg_name,p_inv_flex_name,p_inv_flex_code|
-- |               p_apc_structure_id,p_apc_structure_code             |
-- |                                                                   |
-- |                                                                   |
-- | Returns       x_cat_id                                            |
-- +===================================================================+
PROCEDURE create_category
    (
         p_cat_var              IN          VARCHAR2
        ,p_seg_name             IN          VARCHAR2
        ,p_inv_flex_num         IN          NUMBER
        ,p_inv_flex_code        IN          VARCHAR
        ,p_apc_structure_id     IN          NUMBER
        ,p_apc_structure_code   IN          VARCHAR2
        ,x_cat_id               OUT NOCOPY  NUMBER
    )
AS

ln_errorcode             NUMBER:= NULL;
ln_msg_count             NUMBER:= NULL;
lc_msg_data              VARCHAR2(2000):= NULL;
lc_return_status         VARCHAR(1);
lr_category_rec          INV_ITEM_CATEGORY_PUB.category_rec_type;
lc_description           FND_FLEX_VALUES_TL.description%TYPE := NULL;
lc_error_log             VARCHAR2(2000);

BEGIN

    BEGIN

        -- Getting the description of each segment

        -- Note: p_cat_var refers to a APC Category,
        -- whereas substr(p_cat_var,2) refers to the segment of a Inventory Category

        SELECT  description
        INTO    lc_description
        FROM    fnd_flex_values_tl
        WHERE   flex_value_id = (SELECT flex_value_id
                FROM    fnd_flex_values
                WHERE   flex_value_set_id = (SELECT flex_value_set_id
                        FROM fnd_id_flex_segments
                        WHERE id_flex_num = p_inv_flex_num
                        AND id_flex_code = p_inv_flex_code
                        AND application_column_name = p_seg_name
                )
                AND flex_value = substr(p_cat_var,2)
        );

    EXCEPTION
        WHEN OTHERS THEN
            lc_description := substr(p_cat_var,2);
    END;

    ---------------------------
    -- Creating a new category
    ---------------------------
    BEGIN

        lr_category_rec.structure_id          := p_apc_structure_id;
        lr_category_rec.structure_code        := p_apc_structure_code;
        lr_category_rec.segment1              := p_cat_var;
        -- Changing the default value as per CRM requirements.
        -- Since these are NOT NULL columns.
        lr_category_rec.summary_flag          := g_MISS_CHAR;
        lr_category_rec.enabled_flag          := g_MISS_CHAR;
        lr_category_rec.description           := lc_description;
        lr_category_rec.web_status            := INV_ITEM_CATEGORY_PUB.g_miss_char ;
        lr_category_rec.supplier_enabled_flag := INV_ITEM_CATEGORY_PUB.g_miss_char ;

        INV_ITEM_CATEGORY_PUB.create_category
            (
                p_api_version       => 1.0,
                p_init_msg_list     => FND_API.G_TRUE,
                p_commit            => FND_API.G_TRUE,
                x_return_status     => lc_return_status ,
                x_errorcode         => ln_errorcode ,
                x_msg_count         => ln_msg_count ,
                x_msg_data          => lc_msg_data ,
                p_category_rec      => lr_category_rec,
                x_category_id       => x_cat_id
            );

        IF lc_return_status = 'S' THEN
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Category is successfully created in APC for segment :'||p_cat_var);
            Fnd_File.PUT_LINE(Fnd_File.LOG,'Category is successfully created in APC for segment :'||p_cat_var);
            
            
        ELSE
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in creating the category in APC for segment :'||p_cat_var);
            Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in creating the category in APC for segment :'||p_cat_var);

            /*Call API for inserting records in error table*/
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0056_ERR_CREATE_CA_APC');
            FND_MESSAGE.SET_TOKEN('CAT_VAR',p_cat_var);
            g_errbuf := FND_MESSAGE.GET;
            g_inv_status_flag :=1;
           
            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.create_category'
                                        ,p_error_message_code      => 'XX_TM_0056_ERR_CREATE_CA_APC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );  
                    
            IF ln_msg_count > 0 THEN
                fnd_file.put_line(fnd_file.log, 'API returned Error.');
                FOR counter IN 1..ln_msg_count
                LOOP
                    fnd_file.put_line(fnd_file.log,counter||'. '||SUBSTR(FND_MSG_PUB.Get(counter,FND_API.G_FALSE ), 1, 255));
                END LOOP;
            END IF;

        END IF;


    EXCEPTION
        WHEN OTHERS THEN
            lc_error_log:='Error in creating categories'||SQLERRM;
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'lc_error_log:'||lc_error_log);
            Fnd_File.PUT_LINE(Fnd_File.LOG, 'lc_error_log:'||lc_error_log);
            
            /*Call API for inserting records in error table*/
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0056_ERR_CREATE_CA_APC');
            FND_MESSAGE.SET_TOKEN('CAT_VAR',p_cat_var);
            g_errbuf := FND_MESSAGE.GET;
            g_inv_status_flag :=1;

            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.create_category'
                                        ,p_error_message_code      => 'XX_TM_0056_ERR_CREATE_CA_APC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );  

    END;

END create_category;

-- +===================================================================+
-- | Name        : check_description                                   |
-- | Description : Procedure checks whether category description in    |
-- |               APC is in sync with Inventory                       |
-- |                                                                   |
-- | Parameters  : p_cat_var,p_seg_name,p_inv_flex_num,p_inv_flex_code |
-- |               p_cat_id                                            |
-- |                                                                   |
-- |               Note: p_cat_var refers to a APC Category, whereas   |
-- |               substr(p_cat_var,2) refers to the segment of a      |
-- |               Inventory Category                                  |
-- |                                                                   |
-- | Returns     : x_is_update,x_descripiton                           |
-- +===================================================================+
PROCEDURE check_description
    (
            p_cat_var              IN           VARCHAR2
          , p_seg_name             IN           VARCHAR2
          , p_inv_flex_num         IN           NUMBER
          , p_inv_flex_code        IN           VARCHAR
          , p_cat_id               IN           NUMBER
          , x_is_update            OUT  NOCOPY  BOOLEAN
          , x_description          OUT  NOCOPY  VARCHAR2
    )
AS

lc_inv_description  fnd_flex_values_tl.description%TYPE := NULL;
lc_apc_description  mtl_categories_tl.description%TYPE := NULL;

BEGIN


    ------------------------------------------------------------------------
    -- Getting the description for each segment of a Inventory Category
    -- Example:
    -- If A.B.C.D.E is a Inventory Category,then each dot seperated value
    -- is the segment
    ------------------------------------------------------------------------
    BEGIN

        SELECT  DESCRIPTION
        INTO    lc_inv_description
        FROM    fnd_flex_values_tl
        WHERE   flex_value_id IN (SELECT flex_value_id
                FROM    fnd_flex_values
                WHERE   flex_value_set_id = (SELECT flex_value_set_id
                FROM    fnd_id_flex_segments
                        WHERE   id_flex_num = p_inv_flex_num
                        AND     id_flex_code = p_inv_flex_code
                        AND     application_column_name = p_seg_name
                )
            AND flex_value = substr(p_cat_var,2)
        )
        AND USERENV('LANG') IN (LANGUAGE, source_lang);

    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'No Description defined for this category in Inventory');
            Fnd_File.PUT_LINE(Fnd_File.LOG,'No Description defined for this category in Inventory');
            
            /*Call API for inserting records in error table*/
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0059_NO_INV_DESC');
            g_errbuf := FND_MESSAGE.GET;

            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.check_description'
                                        ,p_error_message_code      => 'XX_TM_0059_NO_INV_DESC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );      

        WHEN OTHERS THEN
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in retrieving description of the segment = '||substr(p_cat_var,2));
            Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in retrieving description of the segment = '||substr(p_cat_var,2));
          
            /*Call API for inserting records in error table*/
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0060_ERR_INV_DESC');
            FND_MESSAGE.SET_TOKEN('SEGMENT',substr(p_cat_var,2));
            g_errbuf := FND_MESSAGE.GET;

            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.check_description'
                                        ,p_error_message_code      => 'XX_TM_0060_ERR_INV_DESC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );      

    END;

    -----------------------------------------------------------------
    -- Getting the description for a APC category
    -----------------------------------------------------------------
    BEGIN

        SELECT description
        INTO lc_apc_description
        FROM mtl_categories_tl
        WHERE category_id  = p_cat_id
        AND USERENV('LANG') IN (LANGUAGE, source_lang);

    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'No Description defined for this category in APC');
            Fnd_File.PUT_LINE(Fnd_File.LOG,'No Description defined for this category in APC');
            
            /*Call API for inserting records in error table*/
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0061_NO_APC_DESC');
            g_errbuf := FND_MESSAGE.GET;

           XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.check_description'
                                        ,p_error_message_code      => 'XX_TM_0061_NO_APC_DESC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );    
        WHEN OTHERS THEN
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in retrieving description of the segment = '||p_cat_var);
            Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in retrieving description of the segment = '||p_cat_var);
            
            /*Call API for inserting records in error table*/
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0060_ERR_INV_DESC');
            FND_MESSAGE.SET_TOKEN('SEGMENT',substr(p_cat_var,2));
            g_errbuf := FND_MESSAGE.GET;

            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.check_description'
                                        ,p_error_message_code      => 'XX_TM_0060_ERR_INV_DESC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );     

    END;

    ----------------------------------------------------------
    -- Comparing lc_inv_description and lc_apc_description
    ----------------------------------------------------------
    IF(lc_inv_description IS NULL AND lc_apc_description IS NOT NULL) THEN
        x_is_update := TRUE;
        x_description := lc_inv_description;
    ELSE
        IF(lc_inv_description IS NOT NULL AND lc_apc_description IS NULL) THEN
            x_is_update := TRUE;
            x_description := lc_inv_description;
        ELSE
            IF(lc_inv_description IS NULL AND lc_apc_description IS NULL) THEN
                x_is_update := FALSE;
                x_description := lc_inv_description;
            ELSE
                IF(lc_inv_description <> lc_apc_description) THEN
                    x_is_update := TRUE;
                    x_description := lc_inv_description;
                ELSE
                    x_is_update := FALSE;
                    x_description := lc_inv_description;
                END IF;
            END IF;
        END IF;
    END IF;

END check_description;


-- +===================================================================+
-- | Name        : update_description                                  |
-- | Description : Procedure updates the category description in APC   |
-- |               to be sync with Inventory Category Description      |
-- |                                                                   |
-- | Parameters :  p_cat_id,p_description                              |
-- |               p_cat_id                                            |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
PROCEDURE update_description
    (
         p_cat_id                IN NUMBER
        ,p_description           IN VARCHAR2
    )
AS

BEGIN

    --------------------------------------------
    -- Updating the category description in APC
    --------------------------------------------

    UPDATE  mtl_categories_tl
    SET     description = p_description
    WHERE   category_id = p_cat_id
    AND     USERENV('LANG') IN (LANGUAGE, source_lang);

EXCEPTION
    WHEN OTHERS THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in Updating the Description'||SQLERRM);
        Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in Updating the Description'||SQLERRM);
        
        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0063_ERR_DESC_UPDATE');
        FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
        g_errbuf := FND_MESSAGE.GET;

             XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.update_description'
                                        ,p_error_message_code      => 'XX_TM_0063_ERR_DESC_UPDATE'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );   

END update_description;


-- +===================================================================+
-- | Name        : is_update_category_relation                         |
-- | Description : Function checks whether category relationship needs |
-- |               to be updated in APC                                |
-- |                                                                   |
-- | Parameters  : p_child_cat,p_parent_cat,p_apc_cat_set_id           |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
FUNCTION is_update_category_relation
    (
         p_child_cat         IN  NUMBER
        ,p_parent_cat        IN  NUMBER
        ,p_apc_cat_set_id    IN  NUMBER

    )   RETURN BOOLEAN
AS

ln_category_id          mtl_category_set_valid_cats.category_id%TYPE := NULL;
ln_parent_category_id   mtl_category_set_valid_cats.parent_category_id%TYPE:= NULL;
ln_child_category_id    mtl_category_set_valid_cats.category_id%TYPE := NULL;

CURSOR LCU_CUR1
    (
        cp_child_cat        IN NUMBER
       ,cp_apc_cat_set_id   IN NUMBER
    )

IS

SELECT   category_id
        ,parent_category_id
FROM    mtl_category_set_valid_cats
WHERE   category_id     = p_child_cat
AND     category_set_id = p_apc_cat_set_id;

BEGIN

    -- If both the child and parent categories are same, then  do not update
    IF(p_child_cat IS NOT NULL AND p_parent_cat IS NOT NULL) THEN
        IF( p_child_cat = p_parent_cat )THEN
               Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Warning! Both Child and Parent categories are SAME - Updating the Category Relationship is not possible');
               Fnd_File.PUT_LINE(Fnd_File.LOG, 'Warning! Both Child and Parent categories are SAME - Updating the Category Relationship is not possible');

               RETURN FALSE;
        END IF;
    END IF;

    OPEN LCU_CUR1
        (
             cp_child_cat        => p_child_cat
            ,cp_apc_cat_set_id   => p_apc_cat_set_id
    );

    FETCH LCU_CUR1 INTO ln_child_category_id,ln_parent_category_id;

    IF LCU_CUR1%NOTFOUND THEN
        ln_child_category_id := NULL;
        ln_parent_category_id:= NULL;
    END IF;

    CLOSE LCU_CUR1;

    -- Update the relation, if the ln_parent_category_id and p_parent_cat are differnet
    IF(p_parent_cat IS NOT NULL AND ln_child_category_id IS NOT NULL) THEN
        IF((ln_parent_category_id IS NULL) OR (ln_parent_category_id <> p_parent_cat)) THEN
            RETURN TRUE;
        END IF;
    END IF;

    RETURN FALSE;

END is_update_category_relation;


-- +===================================================================+
-- | Name        : update_category_relation                            |
-- | Description : Procedure updates the category relationship between |
-- |               the categories in APC                               |
-- |                                                                   |
-- | Parameters  : p_child_cat,p_parent_cat,p_apc_cat_set_id           |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
PROCEDURE update_category_relation
    (
         p_child_cat             IN  NUMBER
        ,p_parent_cat            IN  NUMBER
        ,p_apc_cat_set_id        IN  NUMBER
    )
AS

ln_category_id          NUMBER:= NULL;
ln_parent_category_id   NUMBER:= NULL;
ln_child_category_id    NUMBER:= NULL;
lc_return_status        VARCHAR2(10);
lc_errorcode            VARCHAR2(10);
ln_msg_count            NUMBER;
lc_msg_data             VARCHAR2(2000);

BEGIN
    --------------------------------------
    -- Updating the category relationship
    --------------------------------------
    INV_ITEM_CATEGORY_PUB.Update_Valid_Category
        (
             p_api_version         => 1.0,
             p_init_msg_list       => Fnd_Api.G_TRUE,
             p_commit              => Fnd_Api.G_TRUE,
             p_category_set_id     => p_apc_cat_set_id,
             p_category_id         => p_child_cat,
             p_parent_category_id  => p_parent_cat,
             x_return_status       => lc_return_status,
             x_errorcode           => lc_errorcode,
             x_msg_count           => ln_msg_count,
             x_msg_data            => lc_msg_data
         );

        IF lc_return_status = 'S' THEN
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Category Relationship Updated Successfully!!!');
            Fnd_File.PUT_LINE(Fnd_File.LOG,'Category Relationship Updated Successfully!!!');
            
        ELSE
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in updating the category relationship');
            Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in updating the category relationship');
            
            /*Call API for inserting records in error table*/
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0068_ERR_CA_UPDATE');
            g_errbuf := FND_MESSAGE.GET;
            g_inv_status_flag :=1;
            
            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.update_category_relation'
                                        ,p_error_message_code      => 'XX_TM_0068_ERR_CA_UPDATE'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );   


            IF ln_msg_count > 0 THEN
                fnd_file.put_line(fnd_file.log, 'API returned Error.');
                FOR counter IN 1..ln_msg_count
                LOOP
                    fnd_file.put_line(fnd_file.log,counter||'. '||SUBSTR(FND_MSG_PUB.Get(counter,FND_API.G_FALSE),1,255));
                END LOOP;
            END IF;

        END IF;

EXCEPTION

    WHEN OTHERS THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in Updating Category Relationships'||SQLERRM);
        Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in Updating Category Relationships'||SQLERRM);
        
        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0068_ERR_CA_UPDATE');
        g_errbuf := FND_MESSAGE.GET;
        g_inv_status_flag :=1;

            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.update_category_relation'
                                        ,p_error_message_code      => 'XX_TM_0068_ERR_CA_UPDATE'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );  

END update_category_relation;


-- +===================================================================+
-- | Name        : is_Create_Category_Relation                         |
-- | Description : Function checks whether a new category relationship |
-- |               has to be created in APC                            |
-- |                                                                   |
-- | Parameters : p_child_cat,p_parent_cat,p_apc_cat_set_id            |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
FUNCTION is_create_category_relation
    (
         p_child_cat         IN  NUMBER
        ,p_parent_cat        IN  NUMBER
        ,p_apc_cat_set_id    IN  NUMBER

    )   RETURN BOOLEAN
AS

ln_category_id     mtl_category_set_valid_cats.category_id%TYPE := NULL;

-- Cursor will be called if the parent_category_id is null
-- If parent_category_id is null then it is a parent category
CURSOR lcu_cur1
    (
         cp_child_cat_id        IN NUMBER
        ,cp_apc_cat_set_id      IN NUMBER
)
IS

SELECT  category_id
FROM    mtl_category_set_valid_cats
WHERE   category_set_id    =  p_apc_cat_set_id
AND     category_id        =  p_child_cat
AND     parent_category_id IS NULL;

-- Cursor will be called if both p_child_cat and p_parent_cat are not null
CURSOR lcu_cur2
    (
         cp_child_cat_id        IN NUMBER
        ,cp_apc_cat_set_id      IN NUMBER
        ,cp_parent_cat_id       IN NUMBER
    )
IS

SELECT  category_id
FROM    mtl_category_set_valid_cats
WHERE   category_set_id     = p_apc_cat_set_id
AND     category_id         = p_child_cat
AND     parent_category_id  = p_parent_cat;

BEGIN

    -- Cannot create a relationship if both child and parent categories are same
    IF(p_child_cat IS NOT NULL AND p_parent_cat IS NOT NULL) THEN
        IF( p_child_cat = p_parent_cat )THEN
               Fnd_File.PUT_LINE(Fnd_File.OUTPUT, 'Warning! Cannot create a new category relationship - Both the child and parent categories are same');
               Fnd_File.PUT_LINE(Fnd_File.LOG, 'Warning! Cannot create a new category relationship - Both the child and parent categories are same');
               RETURN FALSE;
        END IF;
    END IF;

   -- Calling cursor lcu_cur1 if p_parent_cat is null (parent category)
   IF p_parent_cat IS NULL THEN
        OPEN lcu_cur1
            (
                 cp_child_cat_id         => p_child_cat
                ,cp_apc_cat_set_id       => p_apc_cat_set_id
            );
        FETCH lcu_cur1 INTO ln_category_id;

        IF lcu_cur1%NOTFOUND THEN
            ln_category_id := NULL;
            -- parent category has to be created in APC
            RETURN TRUE;
        END IF;
        CLOSE LCU_CUR1;

        IF ln_category_id IS NOT NULL THEN
            -- parent category is already created in APC
            RETURN FALSE;
        ELSE
            -- parent category has to be created in APC
            RETURN TRUE;
        END IF;

    ELSE

        -- Calling cursor lcu_cur2 if p_child_cat and p_parent_cat is not null
        OPEN lcu_cur2
            (
                 cp_child_cat_id         => p_child_cat
                ,cp_apc_cat_set_id       => p_apc_cat_set_id
                ,cp_parent_cat_id        => p_parent_cat
            );

        FETCH lcu_cur2 INTO ln_category_id;

        IF lcu_cur2%NOTFOUND THEN
          ln_category_id := NULL;
          -- Create a relationship between p_child_cat and p_parent_cat
          RETURN TRUE;
        END IF;

        CLOSE lcu_cur2;

        IF ln_category_id IS NOT NULL THEN
          -- Relationship alredy exists between p_child_cat and p_parent_cat
          RETURN FALSE;
        ELSE
          -- Create a relationship between p_child_cat and p_parent_cat
          RETURN TRUE;
        END IF;

    END IF;
END is_create_category_relation;


-- +===================================================================+
-- | Name        : create_category_relation                            |
-- | Description : Procedure creates a new category relationship       |
-- |               between categories in APC                           |
-- |                                                                   |
-- | Parameters  : p_child_cat,p_parent_cat,p_apc_cat_set_id           |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
PROCEDURE create_category_relation
    (
         p_child_cat            IN NUMBER
        ,p_parent_cat           IN NUMBER
        ,p_apc_cat_set_id       IN NUMBER
    )

AS

ln_errorcode             NUMBER:= NULL;
ln_msg_count             NUMBER:= NULL;
lc_msg_data              VARCHAR2(2000):= NULL;
lc_return_status         VARCHAR(1);
lc_error_log             VARCHAR2(4000);

BEGIN
    /* We should not use this method if already we have one set of unique category_id and category_set_id, or otherwise it will throw the following constraint violation error
    category_set_id + category_id
    OTHERS:ORA-00001: unique constraint (INV.MTL_CATEGORY_SET_VALID_CATS_U1)
    violated.
    To update hierarchies please use XX_INV_ITEM_CATEGORY_PUB.Update_Valid_Category
    */
    INV_ITEM_CATEGORY_PUB.create_valid_category
        (
            p_api_version         => 1.0,
            p_init_msg_list       => FND_API.G_TRUE,
            p_commit              => FND_API.G_TRUE,
            p_category_set_id     => p_apc_cat_set_id,
            p_category_id         => p_child_cat,
            p_parent_category_id  => p_parent_cat,
            x_return_status       => lc_return_status,
            x_errorcode           => ln_errorcode,
            x_msg_count           => ln_msg_count,
            x_msg_data            => lc_msg_data
        );

    IF lc_return_status = 'S' THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'A new category relationship is successfully created in APC!!!');
        Fnd_File.PUT_LINE(Fnd_File.LOG,'A new category relationship is successfully created in APC!!!');
       
    ELSE
        IF ln_msg_count > 0 THEN
            fnd_file.put_line(fnd_file.log, 'API returned Error.');
            FOR counter IN 1..ln_msg_count
            LOOP
                fnd_file.put_line(fnd_file.log,counter||'. '||SUBSTR(FND_MSG_PUB.Get(counter,FND_API.G_FALSE ), 1, 255));
            END LOOP;
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in making a new Category Relationship:'||SQLERRM);
        Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in making a new Category Relationship:'||SQLERRM);
        
        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0070_ERR_CA_CREATE');
        FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
        
        g_errbuf := FND_MESSAGE.GET;
        g_inv_status_flag :=1;

            XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.create_category_relation'
                                        ,p_error_message_code      => 'XX_TM_0070_ERR_CA_CREATE'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );  

END create_category_relation;

-- +===================================================================+
-- | Name : Insert_Ego_Records                                         |
-- | Description : Procedure inserts category records into             |
-- |               EGO_PRODUCT_CAT_SET_EXT table                       |
-- |                                                                   |
-- | Parameters :  p_category_id,p_category_set_id                     |
-- |                                                                   |
-- |                                                                   |
-- | Returns       x_is_update,x_descripiton                           |
-- +===================================================================+
PROCEDURE Insert_Ego_Records(
        p_category_set_id       IN NUMBER
       ,p_category_id           IN NUMBER)
AS
        ln_attr_group_id        NUMBER;
        ln_extension_id         NUMBER := NULL;
BEGIN

     Fnd_File.PUT_LINE(Fnd_File.LOG,'Inside Insert_Ego_Records');
     Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Inside Insert_Ego_Records');
    
    BEGIN
    SELECT ATTR_GROUP_ID 
    INTO ln_attr_group_id 
    FROM EGO_FND_DSC_FLX_CTX_EXT 
    WHERE APPLICATION_ID = 431 
    AND DESCRIPTIVE_FLEXFIELD_NAME = 'EGO_PRODUCT_CATEGORY_SET' 
    AND DESCRIPTIVE_FLEX_CONTEXT_CODE = 'SalesAndMarketing';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        Fnd_File.PUT_LINE(Fnd_File.LOG,'ATTR_GROUP_ID not found');
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'ATTR_GROUP_ID not found');
    END;
    
    BEGIN
        SELECT EXTENSION_ID
        INTO ln_extension_id
        FROM EGO_PRODUCT_CAT_SET_EXT
        WHERE category_id = p_category_id
        AND ROWNUM=1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        ln_extension_id := NULL;
        Fnd_File.PUT_LINE(Fnd_File.LOG,'Extension ID not found for category  = '||p_category_id);
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Extension ID not found for category  = '||p_category_id);
    END;
    
    IF(ln_extension_id IS NULL) THEN    
        Fnd_File.PUT_LINE(Fnd_File.LOG,'Before Inserting Records');
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Before Inserting Records');
        
        INSERT INTO EGO_PRODUCT_CAT_SET_EXT(
            EXTENSION_ID
           ,category_set_id
           ,category_id
           ,ATTR_GROUP_ID
           ,CREATED_BY
           ,CREATION_DATE
           ,LAST_UPDATED_BY
           ,LAST_UPDATE_DATE
           ,LAST_UPDATE_LOGIN
           ,INCLUDE_IN_FORECAST
           ,EXPECTED_PURCHASE
           ,EXCLUDE_USER_VIEW
           )VALUES(
           EGO_EXTFWK_S.NEXTVAL
           ,p_category_set_id
           ,p_category_id
           ,ln_attr_group_id
           ,-1
           ,SYSDATE
           ,-1
           ,SYSDATE
           ,-1
           ,'Y'
           ,'Y'
           ,'N'
        );
        Fnd_File.PUT_LINE(Fnd_File.LOG,'After Inserting Records');
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'After Inserting Records');
    END IF;      

END Insert_Ego_Records; 


-- +===================================================================+
-- | Name        : delete_apc_category                                 |
-- | Description : Procedure checks whether categories are disabled in |
-- |               Inventory,if YES,throws message to users to delete  |
-- |               the categories manually from APC.                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     : x_inv_category_set_id,x_inv_structure_id            |
-- |               x_inv_structure_name                                |
-- +===================================================================+
PROCEDURE delete_apc_category
    (
        p_cat_seg_tbl           IN SEG_REC_TYPE
       ,p_apc_structure_id      IN NUMBER
       ,p_apc_category_set_id   IN NUMBER
)

AS

G_MISS_L_TBL                L_TBL_TYPE;
ln_non_null_id              NUMBER DEFAULT 0;
ln_cat_id                   NUMBER;
ln_prev_cat_id              NUMBER;
lb_cat_rel_exist            BOOLEAN;
lb_flag                     BOOLEAN := TRUE;
ln_def_category_id          NUMBER;
lc_display_category         VARCHAR(2000);

ln_inv_item_id              mtl_item_categories.inventory_item_id%TYPE := NULL;
lc_inv_item_name            mtl_system_items_b.segment1%TYPE;
ln_organization_id          mtl_item_categories.organization_id%TYPE;
l_return_status             VARCHAR2(10);
l_error_code                NUMBER;
l_msg_count                 NUMBER;
l_msg_data                  VARCHAR2(1000);
ln_parent_cat_count         NUMBER DEFAULT 0;
l_valid_cat_return_status   VARCHAR2(1);
l_del_cat_return_status     VARCHAR2(1);

-- For parent category
-- Cursor to be called if parent_category_id is not null
CURSOR lcu_cur1
    (
         cp_category_id             IN NUMBER
        ,cp_apc_category_set_id     IN NUMBER
    )

IS

SELECT  category_id
FROM    mtl_category_set_valid_cats
WHERE   category_id = cp_category_id
AND     parent_category_id  IS NULL
AND     category_set_id     = cp_apc_category_set_id;


-- Cursor to be called if category_id and parent_category_id is not null
CURSOR lcu_cur2
    (
         cp_category_id             IN NUMBER
        ,cp_parent_cat_id           IN NUMBER
        ,cp_apc_category_set_id     IN NUMBER
)

IS

SELECT  category_id
FROM    mtl_category_set_valid_cats
WHERE   category_id         = cp_category_id
AND     parent_category_id  = cp_parent_cat_id
AND     category_set_id     = cp_apc_category_set_id;



-- Cursor to retrieve inventory items and their organizations
CURSOR lcu_cur3
    (
         cp_apc_category_set_id     IN NUMBER
        ,cp_category_id             IN NUMBER
    )

IS

SELECT  inventory_item_id
        ,organization_id
FROM    mtl_item_categories
WHERE   category_set_id   = cp_apc_category_set_id
AND     category_id       = cp_category_id;

TYPE cat_id_rec is RECORD
    (
         category_id      NUMBER
        ,parent_cat_count NUMBER DEFAULT 0
    );
TYPE cat_id_table is TABLE OF cat_id_rec INDEX BY BINARY_INTEGER;
cat_id_tbl cat_id_table;

ln_master_org_id        NUMBER;
l_inv_item              NUMBER;

BEGIN

     G_MISS_L_TBL(1).SEG_VAL := p_cat_seg_tbl.SEGMENT1;
     G_MISS_L_TBL(2).SEG_VAL := p_cat_seg_tbl.SEGMENT2;
     G_MISS_L_TBL(3).SEG_VAL := p_cat_seg_tbl.SEGMENT3;
     G_MISS_L_TBL(4).SEG_VAL := p_cat_seg_tbl.SEGMENT4;
     G_MISS_L_TBL(5).SEG_VAL := p_cat_seg_tbl.SEGMENT5;

     --
     --  To find duplicate categories if any
     --  Note: If we have any duplicate category eg: A.B.C.D.C then
     --  display error and exit from the program
     --

     FOR i IN REVERSE 1..5 LOOP
         FOR j IN REVERSE 1..(i-1) LOOP
           IF (G_MISS_L_TBL(i).SEG_VAL = G_MISS_L_TBL(j).SEG_VAL) THEN
                G_MISS_L_TBL(j) := NULL;
                Fnd_File.PUT_LINE(Fnd_File.OUTPUT,CHR(10)||'Note:');
                Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'There is no such category hierarchy created in APC.It cannot be deleted');
                Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'-----------------------------------------------------------------------');
                Fnd_File.PUT_LINE(Fnd_File.LOG,CHR(10)||'Note:');
                Fnd_File.PUT_LINE(Fnd_File.LOG,'There is no such category hierarchy created in APC.It cannot be deleted');
                Fnd_File.PUT_LINE(Fnd_File.LOG,'-----------------------------------------------------------------------');
                RETURN;
           END IF;
         END LOOP;
     END LOOP;

     --
     -- Remove the null segments from the table
     --

     FOR i IN 1..5  LOOP
         IF(G_MISS_L_TBL(i).SEG_VAL IS NOT NULL) THEN
             ln_non_null_id := ln_non_null_id+1;
             G_MISS_L_TBL(ln_non_null_id).SEG_VAL := G_MISS_L_TBL(i).SEG_VAL;
         END IF;
     END LOOP;

     --
     --  Find if the category hierarchy exists in APC
     --

     FOR i IN 1..ln_non_null_id  LOOP
         lc_display_category := lc_display_category||'.'||G_MISS_L_TBL(i).SEG_VAL;

         -- Check whether the category exists in APC
         ln_cat_id := check_category
            (
               p_cat_var             => G_MISS_L_TBL(i).seg_val
              ,p_apc_structure_id    => p_apc_structure_id
            );

        IF (ln_cat_id IS NULL) THEN
           -- Categpry does not exist, exit from the loop
           lb_flag := FALSE;
           EXIT;
        END IF;

        -- If i = 1, then it is a parent category
        IF i = 1 THEN

            -- Check whether the relationship exists for parent category in APC
            OPEN lcu_cur1
                (
                     cp_category_id               => ln_cat_id
                    ,cp_apc_category_set_id       => p_apc_category_set_id
                );

            FETCH lcu_cur1 INTO ln_def_category_id;

            IF lcu_cur1%NOTFOUND THEN
                ln_def_category_id := NULL;
                -- Parent category does not exist in relationship table,so exit
                lb_flag := FALSE;
                EXIT;
            END IF;
            CLOSE lcu_cur1;
        ELSE
            -- Check whether the relationship exists for child categories
            OPEN lcu_cur2
                (
                     cp_category_id                 => ln_cat_id
                    ,cp_parent_cat_id               => ln_prev_cat_id
                    ,cp_apc_category_set_id         => p_apc_category_set_id
                );

            FETCH lcu_cur2 INTO ln_def_category_id;

            IF lcu_cur2%NOTFOUND THEN
                ln_def_category_id := NULL;
                -- Relationship does not exist for the child category,so exit
                lb_flag := FALSE;
                EXIT;
            END IF;
            CLOSE lcu_cur2;
        END IF;
        ln_prev_cat_id := ln_cat_id;


        IF lb_flag = TRUE THEN

            cat_id_tbl(i).category_id := ln_cat_id;

            BEGIN
               SELECT count(*)
               INTO   cat_id_tbl(i).parent_cat_count
               FROM   mtl_category_set_valid_cats
               WHERE  parent_category_id = ln_cat_id;
            EXCEPTION
              WHEN OTHERS THEN
                  cat_id_tbl(i).parent_cat_count := 0;
                  Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in finding no.of.parent categories');
                  Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Error in finding no.of.parent categories');
                  
                  /*Call API for inserting records in error table*/
                  FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0076_ERR_F_PA_CA');
                  FND_MESSAGE.SET_TOKEN('CATEGORY',ln_cat_id);
                  g_errbuf := FND_MESSAGE.GET;

                   XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.delete_apc_category'
                                        ,p_error_message_code      => 'XX_TM_0076_ERR_F_PA_CA'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );  

            END;

        END IF;

     END LOOP;
     -- Note: After the above loop, if lb_flag is true,
     -- then all the categories and their relationships exist in APC,
     -- so we can delete the structure

     --
     -- If category hierarchy exists in APC,
     -- delete the category starting from the lowest category
     --


    IF lb_flag = TRUE THEN

        FOR  i IN REVERSE 1..ln_non_null_id
        LOOP


            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,' ');
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'APC Category = '||G_MISS_L_TBL(i).seg_val);
            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'----------------------------------------------'||CHR(10));
            Fnd_File.PUT_LINE(Fnd_File.LOG,' ');
            Fnd_File.PUT_LINE(Fnd_File.LOG,'APC Category = '||G_MISS_L_TBL(i).seg_val);
            Fnd_File.PUT_LINE(Fnd_File.LOG,'----------------------------------------------'||CHR(10));


            FOR inv_rec IN lcu_cur3
                (
                 cp_apc_category_set_id => p_apc_category_set_id
                ,cp_category_id         => cat_id_tbl(i).category_id
                )
            LOOP
                --
                -- If inventory assignment exists, delete the same.
                --

                ln_master_org_id := NULL;

                BEGIN
                    SELECT MASTER_ORGANIZATION_ID
                    INTO   ln_master_org_id
                    FROM   mtl_parameters
                    WHERE  organization_id = inv_rec.organization_id;

                EXCEPTION
                    WHEN OTHERS THEN
                        Fnd_File.PUT_LINE(Fnd_File.LOG,'Error in retreiving master organization id:'||SQLERRM);
                        
                        /*Call API for inserting records in error table*/
                        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0077_M_ORG_ID_NOT_FOUND');
                        FND_MESSAGE.SET_TOKEN('SQLERR',SQLERRM);
                        g_errbuf := FND_MESSAGE.GET;
                        g_inv_status_flag := 1;
                       
                   XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.delete_apc_category'
                                        ,p_error_message_code      => 'XX_TM_0077_M_ORG_ID_NOT_FOUND'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );   
                END;

                IF ln_master_org_id IS NOT NULL THEN

                    l_msg_count := 0;
                    l_inv_item  := NULL;
                    ---
                    -- Check Item association already deleted
                    ---
                    BEGIN

                    SELECT  inventory_item_id
                    INTO    l_inv_item
                    FROM    mtl_item_categories
                    WHERE   category_set_id    = p_apc_category_set_id
                    AND     category_id        = cat_id_tbl(i).category_id
                    AND     organization_id    = inv_rec.organization_id
                    AND     inventory_item_id  = inv_rec.inventory_item_id;

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            l_inv_item := NULL;
                        WHEN OTHERS THEN
                            l_inv_item := NULL;
                    END;

                    IF l_inv_item IS NOT NULL THEN

                        --Fnd_File.PUT_LINE(Fnd_File.LOG,'Note:'||G_MISS_L_TBL(i).seg_val||' is a Leaf Category, delete all its item associations');
                        --Fnd_File.PUT_LINE(Fnd_File.LOG,'**************************************************************');

                        --Fnd_File.PUT_LINE(Fnd_File.LOG,'cat_id_tbl('||i||').category_id = '||cat_id_tbl(i).category_id);
                        --Fnd_File.PUT_LINE(Fnd_File.LOG,'inventory_item_id = '||inv_rec.inventory_item_id);
                        --Fnd_File.PUT_LINE(Fnd_File.LOG,'ln_master_org_id = '||ln_master_org_id);
                        --Fnd_File.PUT_LINE(Fnd_File.LOG,'-----------------------------------------------------------'||CHR(10));


                        -- Note:
                        -- This API will throw an error if we pass any organization_id other than the master_organization_id
                        -- By passing the master organization id, the API will delete
                        -- the item associaiton from the master organization as well as all its child organizations
                        INV_ITEM_CATEGORY_PUB.Delete_Category_Assignment
                        (
                            p_api_version       => 1.0,
                            p_init_msg_list     => FND_API.G_TRUE,
                            p_commit            => FND_API.G_FALSE,
                            x_return_status     => l_return_status,
                            x_errorcode         => l_error_code,
                            x_msg_count         => l_msg_count,
                            x_msg_data          => l_msg_data,
                            p_category_id       => cat_id_tbl(i).category_id,
                            p_category_set_id   => p_apc_category_set_id,
                            p_inventory_item_id => inv_rec.inventory_item_id,
                            p_organization_id   => ln_master_org_id
                        );

                        --Fnd_File.PUT_LINE(Fnd_File.LOG,'l_return_status:'||l_return_status);

                        IF l_return_status  = FND_API.G_RET_STS_SUCCESS  THEN
                            Fnd_File.PUT_LINE(Fnd_File.LOG,inv_rec.inventory_item_id ||' -> Inventory item association has been deleted for the above Category ');
                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,inv_rec.inventory_item_id ||' -> Inventory item association has been deleted for the above Category ');
                        ELSE
                            Fnd_File.PUT_LINE(Fnd_File.LOG,'Unable to delete the item from the above category :'||inv_rec.inventory_item_id);
                            Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Unable to delete the item from the above category :'||inv_rec.inventory_item_id);

                            /*Call API for inserting records in error table*/
                            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0078_ITEM_NOT_DEL');
                            FND_MESSAGE.SET_TOKEN('INV_ID',inv_rec.inventory_item_id);
                            g_errbuf := FND_MESSAGE.GET;
                            g_inv_status_flag := 1;
                           XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.delete_apc_category'
                                        ,p_error_message_code      => 'XX_TM_0078_ITEM_NOT_DEL'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );
                            
                            IF l_msg_count >= 1 THEN
                                  Fnd_File.PUT_LINE(Fnd_File.LOG,CHR(10)||': Errors in deleting item');
                                  Fnd_File.PUT_LINE(Fnd_File.LOG,'---------------------------------');
                                  FOR I IN 1..l_msg_count
                                  LOOP
                                      IF i = 1 THEN
                                          Fnd_File.PUT_LINE(Fnd_File.LOG,I||'. '||l_msg_data);
                                      ELSE
                                          Fnd_File.PUT_LINE(Fnd_File.LOG,I||'. '||SUBSTR(FND_MSG_PUB.Get(I,FND_API.G_FALSE ), 1, 255));
                                      END IF;
                                  END LOOP;
                                  Fnd_File.PUT_LINE(Fnd_File.LOG,'-------------------------------'||CHR(10));
                            END IF;

                        END IF;

                    END IF;

                END IF;

            END LOOP;


        --
        -- Delete the category hierarchy
        --

        l_valid_cat_return_status := 'E';

        Fnd_File.PUT_LINE(Fnd_File.LOG,'cat_id_tbl('||i||').category_id = '||cat_id_tbl(i).category_id);
        Fnd_File.PUT_LINE(Fnd_File.LOG,'cat_id_tbl('||i||').parent_cat_count = '||cat_id_tbl(i).parent_cat_count);

        IF cat_id_tbl(i).parent_cat_count > 1 THEN
           Fnd_File.PUT_LINE(Fnd_File.LOG,'Note:'||CHR(10)||'Cannot delete the above category - It is being used by some other category as a parent');
           Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Note:'||CHR(10)||'Cannot delete the above category - It is being used by some other category as a parent');
        
           /*Call API for inserting records in error table*/
           FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0079_CA_NOT_DEL');
           FND_MESSAGE.SET_TOKEN('CATEGORY',cat_id_tbl(i).category_id);
           g_errbuf := FND_MESSAGE.GET;
           g_inv_status_flag := 1;
           
           XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.delete_apc_category'
                                        ,p_error_message_code      => 'XX_TM_0079_CA_NOT_DEL'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );
          
        ELSE
            INV_ITEM_CATEGORY_PUB.Delete_Valid_Category
                (
                    p_api_version       => 1.0,
                    x_return_status     => l_valid_cat_return_status,
                    x_errorcode         => l_error_code,
                    x_msg_count         => l_msg_count,
                    x_msg_data          => l_msg_data,
                    p_category_id       => cat_id_tbl(i).category_id,
                    p_category_set_id   => p_apc_category_set_id
                );

            IF l_valid_cat_return_status  = 'S' THEN
                Fnd_File.PUT_LINE(Fnd_File.LOG,'The above category has been deleted from the hierarchy');
                Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'The above category has been deleted from the hierarchy');
            ELSE
                Fnd_File.PUT_LINE(Fnd_File.LOG,'Unable to delete Category Hierarchy ');
                Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'Unable to delete Category Hierarchy ');
                
                /*Call API for inserting records in error table*/
                FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0080_CA_HIER_NOT_DEL');
                g_errbuf := FND_MESSAGE.GET;
                g_inv_status_flag := 1;
                XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.delete_apc_category'
                                        ,p_error_message_code      => 'XX_TM_0080_CA_HIER_NOT_DEL'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );
            END IF;

        END IF;

        --
        -- Delete the category
        --

        IF l_valid_cat_return_status = 'S' THEN

           l_del_cat_return_status := 'E';

           INV_ITEM_CATEGORY_PUB.Delete_Category
              ( p_api_version       => 1.0,
                x_return_status     => l_del_cat_return_status,
                x_errorcode         => l_error_code,
                x_msg_count         => l_msg_count,
                x_msg_data          => l_msg_data,
                p_category_id       => cat_id_tbl(i).category_id);

           IF l_del_cat_return_status = 'S' THEN
              Fnd_File.PUT_LINE(Fnd_File.OUTPUT,CHR(10)||'The above category has been completely deleted from APC ');
              Fnd_File.PUT_LINE(Fnd_File.LOG,CHR(10)||'The above category has been completely deleted from APC');
           ELSE
              Fnd_File.PUT_LINE(Fnd_File.OUTPUT,CHR(10)||'Unable to delete Category ');
              Fnd_File.PUT_LINE(Fnd_File.LOG,CHR(10)||'Unable to delete Category ');
              
              /*Call API for inserting records in error table*/
              FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0081_CA_NOT_DEL');
              FND_MESSAGE.SET_TOKEN('CATEGORY',cat_id_tbl(i).category_id);
              g_errbuf := FND_MESSAGE.GET;
              g_inv_status_flag := 1;
              
               XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.delete_apc_category'
                                        ,p_error_message_code      => 'XX_TM_0081_CA_NOT_DEL'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );
           END IF;

           Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'----------------------------------------------');
           Fnd_File.PUT_LINE(Fnd_File.LOG,'----------------------------------------------');

        END IF;

       END LOOP;
    ELSE
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,CHR(10)||'Note:');
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'There is no such category hierarchy created in APC.It cannot be deleted');
        Fnd_File.PUT_LINE(Fnd_File.OUTPUT,'-----------------------------------------------------------------------');
        Fnd_File.PUT_LINE(Fnd_File.LOG,CHR(10)||'Note:');
        Fnd_File.PUT_LINE(Fnd_File.LOG,'There is no such category hierarchy created in APC.It cannot be deleted');
        Fnd_File.PUT_LINE(Fnd_File.LOG,'-----------------------------------------------------------------------');
        
        /*Call API for inserting records in error table*/
        FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0082_NO_CA_HIER_APC');
        g_errbuf := FND_MESSAGE.GET;
        g_inv_status_flag := 1;
        XX_COM_ERROR_LOG_PUB.log_error_crm (       
                                         p_application_name        => G_APPLICATION_NAME
                                        ,p_program_type            => G_PROGRAM_TYPE                     
                                        ,p_program_name            => G_PROGRAM_NAME
                                        ,p_program_id              => gc_conc_prg_id
                                        ,p_module_name             => G_MODULE_NAME
                                        ,p_error_location          => 'XX_APC_ITEM_CATEGORY_PKG.delete_apc_category'
                                        ,p_error_message_code      => 'XX_TM_0082_NO_CA_HIER_APC'
                                        ,p_error_message           => g_errbuf
                                        ,p_error_message_severity  => 'MEDIUM'
                                        ,p_error_status            => G_ERROR_STATUS_FLAG 
                                        );
    
    END IF;


END delete_apc_category;


END XX_APC_ITEM_CATEGORY_PKG;
/