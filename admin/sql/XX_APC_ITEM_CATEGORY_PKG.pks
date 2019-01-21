CREATE OR REPLACE PACKAGE XX_APC_ITEM_CATEGORY_PKG AUTHID CURRENT_USER
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
-- |                                                categories permanently from APC          |
-- |Draft 1D 17-Sep-2007       Piyush Khandelwal    Modified to add error handling part and  |
-- |                                                to add logic to insert categories detail |
-- |                                                in sales screen.                         |
-- |Draft 1.0 13-Nov-2007      Piyush Khandelwal    Modified the error handling part and     |
-- |                                                incorporated the onsite code review      |
-- |                                                comments                                 |
-- +=========================================================================================+

AS

----------------------------
--Declaring Global Constants
----------------------------
G_PROGRAM_TYPE            CONSTANT  VARCHAR2(100) := 'I1004_APC_INTERFACE';
G_APPLICATION_NAME        CONSTANT  VARCHAR2(30) := 'XXCRM';
G_PROGRAM_NAME            CONSTANT  VARCHAR2(100) := 'XX_APC_ITEM_CATEGORY_PKG.create_category_main';
G_MODULE_NAME             CONSTANT  VARCHAR2(80) := 'TM';
G_ERROR_STATUS_FLAG       CONSTANT  VARCHAR2(80) := 'ACTIVE';

TYPE L_REC_TYPE IS RECORD
    (    SEG_VAL   VARCHAR2(2000) );

TYPE L_TBL_TYPE IS TABLE OF L_REC_TYPE INDEX BY BINARY_INTEGER;

G_MISS_L_TBL                    L_TBL_TYPE;

TYPE SEG_REC_TYPE IS RECORD
    (
         SEGMENT1       VARCHAR(2000),
         SEGMENT2       VARCHAR(2000),
         SEGMENT3       VARCHAR(2000),
         SEGMENT4       VARCHAR(2000),
         SEGMENT5       VARCHAR(2000),
         DISABLE_DATE   DATE
    );

TYPE SEG_TBL_TYPE IS TABLE OF SEG_REC_TYPE INDEX BY BINARY_INTEGER;

CAT_SEG_TBL SEG_TBL_TYPE;

-- +===================================================================+
-- | Name        : create_category_main                                |
-- | Description : This procedure will be called from the Concurrent   |
-- |               Program 'OD: APC Synchronize Product Hierarchies'   |
-- | Parameters  : p_inv_date                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_category_main
    (
         x_errbuf       OUT NOCOPY  VARCHAR2
        ,x_retcode      OUT NOCOPY  VARCHAR2
        ,p_inv_date     IN          VARCHAR2
    );

-- +===================================================================+
-- | Name        : Get_Default_Inv_Details                             |
-- | Description : Procedure to get default inventory details from the |
-- |               fucntional area 'Inventory'                         |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     : x_inv_category_set_id,x_inv_structure_id            |
-- |               x_inv_structure_name                                |
-- +===================================================================+
PROCEDURE get_default_inv_details
    (         
         x_inv_category_set_id   OUT   NOCOPY     NUMBER
        ,x_inv_structure_id      OUT   NOCOPY     NUMBER
        ,x_inv_structure_name    OUT   NOCOPY     VARCHAR2
    );

-- +===================================================================+
-- | Name        : get_default_apc_details                             |
-- | Description : Procedure to get default APC details from the       |
-- |               functional area 'Product Reporting'                 |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     : x_apc_category_set_id,x_apc_structure_id            |
-- |               x_apc_structure_name                                |
-- +===================================================================+
PROCEDURE get_default_apc_details
    (
         x_apc_category_set_id   OUT   NOCOPY     NUMBER
        ,x_apc_structure_id      OUT   NOCOPY     NUMBER
        ,x_apc_structure_name    OUT   NOCOPY     VARCHAR2
    );

-- +===================================================================+
-- | Name        : get_inv_flex_details                                |
-- | Description : Procedure to get the flex field structure details   |
-- |               for Inventory                                       |
-- | Parameters  : p_inv_structure_name                                |
-- |                                                                   |
-- | Returns     : x_inv_flex_code,x_inv_flex_num                      |
-- |               x_inv_flex_structure_code                           |
-- +===================================================================+
PROCEDURE get_inv_flex_details
    (
         p_inv_structure_name      IN               VARCHAR2
        ,x_application_id          OUT   NOCOPY     NUMBER
        ,x_inv_flex_code           OUT   NOCOPY     VARCHAR2
        ,x_inv_flex_num            OUT   NOCOPY     NUMBER
        ,x_inv_flex_structure_code OUT   NOCOPY     VARCHAR2
    );

-- +===================================================================+
-- | Name        : get_apc_flex_details                                |
-- | Description : Procedure to get the flex field structure details   |
-- |               for 'Product Reporting'(APC)                        |
-- | Parameters  : p_apc_structure_name                                |
-- |                                                                   |
-- | Returns     : x_apc_flex_code,x_apc_flex_num                      |
-- |               x_apc_flex_structure_code                           |
-- +===================================================================+
PROCEDURE get_apc_flex_details
    (
         p_apc_structure_name      IN               VARCHAR2
        ,x_application_id          OUT   NOCOPY     NUMBER
        ,x_apc_flex_code           OUT   NOCOPY     VARCHAR2
        ,x_apc_flex_num            OUT   NOCOPY     NUMBER
        ,x_apc_flex_structure_code OUT   NOCOPY     VARCHAR2
    );

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
         p_cat_var              IN  VARCHAR2
        ,p_apc_structure_id     IN  NUMBER

    )    RETURN NUMBER;

-- +===================================================================+
-- | Name        : create_category                                     |
-- | Description : Procedure to create a new category in APC           |
-- |               Program 'OD: APC Synchronize Product Hierarchies'   |
-- |                                                                   |
-- | Parameters  : p_cat_var,p_seg_name,p_inv_flex_name,p_inv_flex_code|
-- |               p_apc_structure_id,p_apc_structure_code             |
-- |                                                                   |
-- | Returns     : x_cat_id (A new category_id created in APC          |
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
    );

-- +===================================================================+
-- | Name        : is_update_category_relation                         |
-- | Description : Function checks whether category relationship needs |
-- |               to be updated in APC                                |
-- |                                                                   |
-- | Parameters  :  p_child_cat,p_parent_cat,p_apc_cat_set_id          |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
FUNCTION is_update_category_relation
    (
         p_child_cat        IN  NUMBER
        ,p_parent_cat       IN  NUMBER
        ,p_apc_cat_set_id   IN  NUMBER

    )   RETURN BOOLEAN;

-- +===================================================================+
-- | Name        : update_category_relation                            |
-- | Description : Procedure updates the category relationship between |
-- |               the categories in APC                               |
-- |                                                                   |
-- | Parameters  :  p_child_cat,p_parent_cat,p_apc_cat_set_id          |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
PROCEDURE update_category_relation
    (
         p_child_cat        IN  NUMBER
        ,p_parent_cat       IN  NUMBER
        ,p_apc_cat_set_id   IN  NUMBER
    );

-- +===================================================================+
-- | Name        : is_create_category_relation                         |
-- | Description : Function checks whether a new category relationship |
-- |               has to be created in APC                            |
-- |                                                                   |
-- | Parameters  :  p_child_cat,p_parent_cat,p_apc_cat_set_id          |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
FUNCTION is_create_category_relation
    (
         p_child_cat        IN  NUMBER
        ,p_parent_cat       IN  NUMBER
        ,p_apc_cat_set_id   IN  NUMBER

    )   RETURN BOOLEAN;


-- +===================================================================+
-- | Name        : create_category_relation                            |
-- | Description : Procedure creates a new category relationship       |
-- |               between categories in APC                           |
-- |                                                                   |
-- | Parameters   :  p_child_cat,p_parent_cat,p_apc_cat_set_id         |
-- |                                                                   |
-- | Returns                                                           |
-- +===================================================================+
PROCEDURE create_category_relation
    (
         p_child_cat        IN  NUMBER
        ,p_parent_cat       IN  NUMBER
        ,p_apc_cat_set_id   IN  NUMBER
    );

-- +===================================================================+
-- | Name        : check_description                                   |
-- | Description : Procedure checks whether category description in    |
-- |               APC is in sync with Inventory                       |
-- |                                                                   |
-- | Parameters  : p_cat_var,p_seg_name,p_inv_flex_num,p_inv_flex_code |
-- |               p_cat_id                                            |
-- |                                                                   |
-- | Returns       x_is_update,x_descripiton                           |
-- +===================================================================+
PROCEDURE check_description
    (
         p_cat_var          IN          VARCHAR2
        ,p_seg_name         IN          VARCHAR2
        ,p_inv_flex_num     IN          NUMBER
        ,p_inv_flex_code    IN          VARCHAR
        ,p_cat_id           IN          NUMBER
        ,x_is_update        OUT NOCOPY  BOOLEAN
        ,x_description      OUT NOCOPY  VARCHAR2
    );

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
         p_cat_id           IN NUMBER
        ,p_description      IN VARCHAR2
    );

    
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
    PROCEDURE Insert_Ego_Records
    (
        p_category_set_id       IN NUMBER
       ,p_category_id           IN NUMBER
    );

-- +===================================================================+
-- | Name        : delete_apc_category                                 |
-- | Description : Procedure checks whether categories are disabled in |
-- |               Inventory,if YES,throws message to users to delete  |
-- |               the categories manually from APC.                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns       x_inv_category_set_id,x_inv_structure_id            |
-- |               x_inv_structure_name                                |
-- +===================================================================+
PROCEDURE delete_apc_category
    (
        p_cat_seg_tbl           IN SEG_REC_TYPE
       ,p_apc_structure_id      IN NUMBER
       ,p_apc_category_set_id   IN NUMBER
    );



END;
/