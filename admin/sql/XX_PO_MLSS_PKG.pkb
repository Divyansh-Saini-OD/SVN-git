SET SHOW          OFF; 
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY  XX_PO_MLSS_PKG                                                               
  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_PO_MLSS_PKG                                      |
-- | Rice ID      :E1252_MultiLocationSupplierSourcing                 |
-- | Description  :This package body is used to associate the          |
-- |               MultiLocation Source name with the corresponding    |
-- |               Supplier Sourcing assignment record.                |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      17-MAR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      09-MAY-2007  Hema Chikkanna   Included the logic for      |
-- |                                       Insert/Updating the custom  |
-- |                                       xx_po_supp_sr_assignment    |
-- |                                       Table                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

AS

g_insert_cnt          NUMBER   := 0;
g_update_cnt          NUMBER   := 0;

-- +===================================================================+
-- | Name  : Write_Exception                                           |
-- | Description :Procedure to log exceptions for the MLSS object using|
-- |               the Common Exception Handling Framework             |
-- |                                                                   |
-- | Parameters :    p_error_code                                      |
-- |                 p_error_description                               |
-- |                 p_entity_reference                                |
-- |                 p_entity_ref_id                                   |
-- | Returns    :                                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_exception ( 
                                 p_error_code             IN VARCHAR2,
                                 p_error_description      IN VARCHAR2,                          
                                 p_entity_reference       IN VARCHAR2,
                                 p_entity_ref_id          IN NUMBER
                          )
IS  

x_form_errbuf     VARCHAR2(2000);
x_form_retcode    VARCHAR2(100);

BEGIN  
    
    ge_exception.p_error_code        := p_error_code;
    ge_exception.p_error_description := p_error_description;
    ge_exception.p_entity_ref        := p_entity_reference;
    ge_exception.p_entity_ref_id     := p_entity_ref_id;
    
    -- Call the global exception package to insert the MLSS form error messages

    xx_om_global_exception_pkg.Insert_Exception (
                                                  p_report_exception => ge_exception
                                                 ,x_err_buf          => x_form_errbuf
                                                 ,x_ret_code         => x_form_retcode
                                               );
END write_exception;  



-- +===================================================================+
-- | Name  : UPDATE_MLSS_NAME                                          |
-- | Description:  This procedure is used to update  MLSS_SOURCE_NAME  |
-- |               column of custom ASL table with the MLSS Name       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:       p_using_org_id                                  |
-- |                   p_category                                      |
-- |                   p_category_level                                |
-- |                   p_vendor_id                                     |
-- |                   p_vendor_site_id                                |
-- |                                                                   |
-- | Returns :          x_err_buf                                      |
-- |                    x_ret_np                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_mlss_name (
                             p_using_org_id    IN   NUMBER,
                             p_category        IN   VARCHAR2,
                             p_category_level  IN   VARCHAR2,
                             p_vendor_id       IN   NUMBER,
                             p_vendor_site_id  IN   NUMBER,
                             x_err_buf         OUT  VARCHAR2,
                             x_ret_no          OUT  NUMBER
                           )
AS

-- local Variable declaration
ln_category_id        NUMBER;
lc_asl_exist          VARCHAR2(1);
lc_category           VARCHAR2(1);
lc_org_code           VARCHAR2(3);
lc_mlss_name          VARCHAR2(40);
ex_mlss               EXCEPTION;

p_error_code          VARCHAR2(2000);
p_error_description   VARCHAR2(2000);
p_entity_reference    VARCHAR2(400);
p_entity_ref_id       NUMBER;


ln_user_id            NUMBER   := TO_NUMBER(FND_PROFILE.VALUE('USER_ID'));

---------------------------------------------------------------------------------
-- Cursor to select active records from Supplier Souricng Assignment custom view
---------------------------------------------------------------------------------
CURSOR lcu_mlss_ssa IS
    SELECT XPSV.asl_id
          ,XPSV.item_id
          ,XPSV.item_name
    FROM   xx_po_ssa_v                XPSV
    WHERE  XPSV.vendor_id             = p_vendor_id
    AND    XPSV.vendor_site_id        = p_vendor_site_id
    AND    XPSV.using_organization_id = p_using_org_id;
    
--------------------------------------------------------------------
-- Cusor to select the Category Description for the given Category
--------------------------------------------------------------------
CURSOR lcu_category  IS
    SELECT FFVV.description        SEGMENT_DESC
    FROM   fnd_id_flex_segments    FIFG 
          ,fnd_id_flex_structures  FIFS 
          ,fnd_flex_values_vl      FFVV 
    WHERE  FIFG.id_flex_num              = FIFS.id_flex_num  
    AND    FIFG.id_flex_code             = FIFS.id_flex_code 
    AND    FIFG.application_id           = FIFS.application_id
    AND    FIFG.flex_value_set_id        = FFVV.flex_value_set_id
    AND    FIFS.id_flex_structure_code   = 'ITEM_CATEGORIES'
    AND    FIFG.application_id           = 401
    AND    FIFG.segment_name             = p_category_level 
    AND    FFVV.flex_value               = p_category;
                
                
BEGIN
    
    --Initializing the variables
    p_error_code         := NULL;
    p_error_description  := NULL;
    p_entity_reference   := NULL;
    p_entity_ref_id      := 0;

    BEGIN
        -- Query to select the organization_code for the given organization Id
        SELECT MP.organization_code
        INTO   lc_org_code
        FROM   mtl_parameters MP
        WHERE  MP.organization_id = p_using_org_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME('XXOM','XX_PO_65121_ORGANIZATION_ERR');
            FND_MESSAGE.SET_TOKEN('ORG_ID',p_using_org_id);
            p_error_code         := 'XX_PO_65121_ORGANIZATION_ERR';
            p_error_description  := FND_MESSAGE.GET;
            p_entity_reference   := 'Organization ID';
            p_entity_ref_id      := p_using_org_id;
            RAISE ex_mlss;

        WHEN OTHERS THEN
            RAISE;
    END;
    
    -- Deriving the MLS Name
   
    FOR lr_category IN lcu_category
    LOOP
        lc_mlss_name  := lc_org_code||'-'||lr_category.segment_desc;
    END LOOP;
    

    FOR lr_mlss_ssa IN lcu_mlss_ssa
    LOOP

        --Initializing the variables
        lc_category          := 'N';
        lc_asl_exist         := 'N';
        p_error_code         := NULL;
        p_error_description  := NULL;
        p_entity_reference   := NULL;
        p_entity_ref_id      := 0;

        BEGIN
            -- Query to select the category id for the given item
            SELECT MIC.category_id
            INTO   ln_category_id
            FROM   mtl_item_categories          MIC
                  ,mtl_category_sets            MSC  
            WHERE  MIC.inventory_item_id        = lr_mlss_ssa.item_id
            AND    MIC.organization_id          = p_using_org_id
            AND    MIC.category_set_id          = MSC.category_set_id
            AND    UPPER(MSC.category_set_name) = UPPER('Inventory'); -- For Inventory Category Set
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME('XXOM','XX_PO_65122_ITEM_CATEGORY_ERR');
                FND_MESSAGE.SET_TOKEN('ITEM',lr_mlss_ssa.item_name);
                p_error_code         := 'XX_PO_65122_ITEM_CATEGORY_ERR';
                p_error_description  := FND_MESSAGE.GET;
                p_entity_reference   := 'Item ID';
                p_entity_ref_id      := lr_mlss_ssa.item_id;
                RAISE ex_mlss;

            WHEN OTHERS THEN
                RAISE;
        END;

        --To check if the item belongs to the given category
        
        IF p_category_level ='Class' THEN

            BEGIN

                SELECT 'Y' 
                INTO    lc_category
                FROM    mtl_categories   MC
                WHERE   MC.segment4      = p_category
                AND     MC.category_id   = ln_category_id;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    lc_category := 'N';

                WHEN OTHERS THEN
                    RAISE;
            END;    

        ELSIF  p_category_level ='Department' THEN

            BEGIN
                SELECT 'Y' 
                INTO   lc_category
                FROM   mtl_categories   MC
                WHERE  MC.segment3      = p_category
                AND    MC.category_id   = ln_category_id; 


            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    lc_category := 'N';

                WHEN OTHERS THEN
                    RAISE;
            END;    

        ELSIF  p_category_level ='Division' THEN
            BEGIN

                SELECT 'Y' 
                INTO    lc_category
                FROM    mtl_categories   MC
                WHERE   MC.segment1      = p_category
                AND     MC.category_id   = ln_category_id;


            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    lc_category := 'N';

                WHEN OTHERS THEN
                    RAISE;                          

            END;   

        END IF; -- end of Category Level branch
        
        
        -- To Insert/Update the xx_po_supp_sr_assignment table
        
        IF (lc_category = 'Y' ) THEN
        
            BEGIN
                SELECT 'Y'
                INTO   lc_asl_exist
                FROM   xx_po_supp_sr_assignment XPSSA
                WHERE  XPSSA.asl_id   = lr_mlss_ssa.asl_id; 

            EXCEPTION    
                WHEN NO_DATA_FOUND THEN
                    lc_asl_exist := 'N';
                
                WHEN OTHERS THEN
                    RAISE;
            END;
            
            IF lc_asl_exist = 'N' THEN
            
-- As per the change request 09-May-2007
                BEGIN
                    INSERT INTO xx_po_supp_sr_assignment XPSSA
                                ( asl_id
                                 ,mls_source_name
                                 ,creation_date
                                 ,created_by
                                 ,last_updated_by
                                 ,last_update_date
                                )VALUES
                                (
                                  lr_mlss_ssa.asl_id
                                 ,lc_mlss_name
                                 ,SYSDATE
                                 ,ln_user_id
                                 ,ln_user_id
                                 ,SYSDATE
                                );
                                
                     g_insert_cnt := g_insert_cnt + 1;           
            
                EXCEPTION            
                    WHEN OTHERS THEN
                        RAISE;
                END;
-- End of changes 09-May-2007                
            ELSE          
                -- Update the custom ASL table with the MLSS Name
                UPDATE xx_po_supp_sr_assignment XPSSA
                SET    XPSSA.mls_source_name   = lc_mlss_name,
                       XPSSA.last_updated_by   = ln_user_id,
                       XPSSA.last_update_date  = SYSDATE                    
                WHERE  XPSSA.asl_id            = lr_mlss_ssa.asl_id;
                
                g_update_cnt := g_update_cnt + 1;
                
            END IF;--End of ASL branch   

        END IF;--End of category branch

    END LOOP;--End of main Loop
     
    COMMIT;
    
    
     
EXCEPTION
    WHEN ex_mlss THEN
         x_err_buf := p_error_description;
         x_ret_no  := 1;
         -- Call the write_exception procedure to insert into
         -- Global exception table
         write_exception ( p_error_code        => p_error_code
                          ,p_error_description => p_error_description
                          ,p_entity_reference  => p_entity_reference
                          ,p_entity_ref_id     => p_entity_ref_id);
             
       
    WHEN OTHERS THEN
         ROLLBACK;
         FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');
         FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
         p_error_code          := 'XX_OM_65100_UNEXPECTED_ERR'; 
         p_entity_reference    := 'Unexpeted Error in MLSS Program';
         p_entity_ref_id       := 0;
         x_err_buf             := FND_MESSAGE.GET;
         p_error_description   := x_err_buf;
         x_ret_no              := 1;
         
         -- Call the write_exception procedure to insert into
         -- Global exception table
         write_exception ( p_error_code        => p_error_code
                          ,p_error_description => p_error_description
                          ,p_entity_reference  => p_entity_reference
                          ,p_entity_ref_id     => p_entity_ref_id);
             
       
                         
END update_mlss_name;
     
     
-- +===================================================================+
-- | Name  : UPDATE_MLSS_MAIN                                          |
-- | Description:  This is the main procedure to update the custom ASL |
-- |               table with ASL_ID and  MLS Source Name              |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_org_id                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_errbuf                                       |
-- |                    x_retcode                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_mlss_main(
                             x_errbuf    OUT VARCHAR2
                            ,x_retcode   OUT NUMBER
                            ,p_org_id    IN  NUMBER
                          )
AS
------------------------------
-- Local variable declaration
------------------------------
  
lc_temp              VARCHAR2(1);
lc_exist             VARCHAR2(1);

x_err_msg            VARCHAR2(2000);
x_ret_code           NUMBER; 

ln_conc_req_id       NUMBER         := FND_GLOBAL.CONC_REQUEST_ID;
ln_user_id           NUMBER         := FND_GLOBAL.USER_ID;

p_error_code         VARCHAR2(2000);
p_error_description  VARCHAR2(2000);
p_entity_reference   VARCHAR2(400);
p_entity_ref_id      NUMBER;



-----------------------
-- Cursor declarations
-----------------------

-- Cursor to select MLSS header records
CURSOR lcu_mlss_rec IS
    SELECT XPMH.mlss_header_id
          ,XPMH.using_organization_id
          ,XPMH.category
          ,XPMH.category_level
          ,XPMH.end_date
          ,XPMD.vendor_id
          ,XPMD.vendor_site_id
    FROM   xx_po_mlss_hdr XPMH
          ,xx_po_mlss_det XPMD
    WHERE  XPMH.using_organization_id = NVL (p_org_id,XPMH.using_organization_id)
    AND    XPMH.mlss_header_id        = XPMD.mlss_header_id;
    
        
           
BEGIN
   
    FND_FILE.PUT_LINE (FND_FILE.LOG,'+------------------------------------------------+');
    FND_FILE.PUT_LINE (FND_FILE.LOG,'|         Multi Location Supplier Sourcing       |');
    FND_FILE.PUT_LINE (FND_FILE.LOG,'+------------------------------------------------+');
   
   
   
 
    FOR lr_mlss_rec IN lcu_mlss_rec 
    LOOP
      
        --Intilizing the variables
        lc_temp              := 'N';
        lc_exist             := 'N';
        p_error_code         := NULL;
        p_error_description  := NULL;
        p_entity_reference   := NULL;
        p_entity_ref_id      := 0;

        
        IF lr_mlss_rec.category_level = 'Class' THEN
        
            IF (lr_mlss_rec.end_date >= SYSDATE OR lr_mlss_rec.end_date IS NULL) THEN

                x_err_msg   := NULL;
                x_ret_code  := NULL;

                ---------------------------------------  
                -- Call the update_mlss_name procedure
                ---------------------------------------
                update_mlss_name (
                                    p_using_org_id   => lr_mlss_rec.using_organization_id,
                                    p_category       => lr_mlss_rec.category,
                                    p_category_level => lr_mlss_rec.category_level,
                                    p_vendor_id      => lr_mlss_rec.vendor_id,
                                    p_vendor_site_id => lr_mlss_rec.vendor_site_id,
                                    x_err_buf        => x_err_msg,
                                    x_ret_no         => x_ret_code
                                );

                IF x_ret_code = 1 THEN
                    FND_FILE.PUT_LINE (FND_FILE.LOG,x_err_msg);
                END IF;  

            ELSIF (lr_mlss_rec.end_date < SYSDATE AND lr_mlss_rec.end_date IS NOT NULL) THEN

                BEGIN 
                -- Check if any Department or Divison is Active for the given class
                    SELECT 'Y'
                    INTO   lc_exist
                    FROM   mtl_categories MC
                    WHERE  MC.segment4 = lr_mlss_rec.category
                    AND EXISTS 
                        (SELECT 1 
                         FROM   xx_po_mlss_hdr XPMH
                         WHERE (XPMH.category = MC.segment1 OR XPMH.category = MC.segment3)
                         AND    XPMH.category_level IN ('Division','Department')
                         AND    XPMH.using_organization_id = lr_mlss_rec.using_organization_id
                         AND   (XPMH.end_date IS NULL OR XPMH.end_date > SYSDATE))
                         AND ROWNUM = 1; 

                EXCEPTION

                    WHEN NO_DATA_FOUND THEN
                        lc_exist := 'N';
                        FND_MESSAGE.SET_NAME('XXOM','XX_PO_65120_CATEGORY_END_DATE');
                        FND_MESSAGE.SET_TOKEN('CATEGORY_LEVEL',lr_mlss_rec.category_level);
                        FND_MESSAGE.SET_TOKEN('CATEGORY',lr_mlss_rec.category);
                        p_error_description      := FND_MESSAGE.GET;
                        p_error_code             := 'XX_PO_65120_CATEGORY_END_DATE';  
                        p_entity_reference       := lr_mlss_rec.category_level||'-'|| lr_mlss_rec.category ;
                        p_entity_ref_id          := 0; 

                        write_exception ( p_error_code        => p_error_code
                                         ,p_error_description => p_error_description
                                         ,p_entity_reference  => p_entity_reference
                                         ,p_entity_ref_id     => p_entity_ref_id);

                        FND_FILE.PUT_LINE(FND_FILE.LOG,p_error_description);

                    WHEN OTHERS THEN
                        RAISE;
                END;

            END IF;  -- end of class category END_DATE branch

        ELSIF lr_mlss_rec.category_level = 'Department' THEN

            IF (lr_mlss_rec.end_date >= SYSDATE OR lr_mlss_rec.end_date IS NULL) THEN

                -- Query to check if there are any classes that belong
                -- to the given department in MLSS header table

                BEGIN
                    SELECT 'Y'
                    INTO   lc_temp
                    FROM   mtl_categories MC
                    WHERE  MC.segment3 = lr_mlss_rec.category
                    AND EXISTS 
                        (SELECT 1 
                        FROM  xx_po_mlss_hdr XPMH
                        WHERE XPMH.category              = MC.segment4
                        AND   XPMH.category_level        = 'Class'
                        AND   XPMH.using_organization_id = lr_mlss_rec.using_organization_id
                        AND  (XPMH.end_date IS NULL OR XPMH.end_date > SYSDATE))
                        AND ROWNUM = 1;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lc_temp := 'N';

                    WHEN OTHERS THEN
                        RAISE;
                END;

                IF lc_temp = 'N' THEN

                    x_err_msg   := NULL;
                    x_ret_code  := NULL;
                    ---------------------------------------  
                    -- Call the update_mlss_name procedure
                    ---------------------------------------
                    update_mlss_name (
                                         p_using_org_id   => lr_mlss_rec.using_organization_id,
                                         p_category       => lr_mlss_rec.category,
                                         p_category_level => lr_mlss_rec.category_level,
                                         p_vendor_id      => lr_mlss_rec.vendor_id,
                                         p_vendor_site_id => lr_mlss_rec.vendor_site_id,
                                         x_err_buf        => x_err_msg,
                                         x_ret_no         => x_ret_code
                                     );

                    IF x_ret_code = 1 THEN
                        FND_FILE.PUT_LINE (FND_FILE.LOG,x_err_msg);
                    END IF;       

                END IF;

            ELSIF (lr_mlss_rec.end_date < SYSDATE AND lr_mlss_rec.end_date IS NOT NULL) THEN

                BEGIN 
                    -- Check if any Class or Divison is Active for the given department
                    SELECT 'Y'
                    INTO   lc_exist
                    FROM   mtl_categories MC
                    WHERE  MC.segment3 = lr_mlss_rec.category
                    AND EXISTS 
                        (SELECT 1 
                        FROM   xx_po_mlss_hdr XPMH
                        WHERE (XPMH.category = MC.segment1 OR XPMH.category = MC.segment4)
                        AND    XPMH.category_level IN ('Division','Class')
                        AND    XPMH.using_organization_id = lr_mlss_rec.using_organization_id
                        AND   (XPMH.end_date IS NULL OR XPMH.end_date > SYSDATE))
                        AND ROWNUM = 1; 

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN 
                        lc_exist := 'N';
                        FND_MESSAGE.SET_NAME('XXOM','XX_PO_65120_CATEGORY_END_DATE');
                        FND_MESSAGE.SET_TOKEN('CATEGORY_LEVEL',lr_mlss_rec.category_level);
                        FND_MESSAGE.SET_TOKEN('CATEGORY',lr_mlss_rec.category);
                        p_error_description      := FND_MESSAGE.GET;
                        p_error_code             := 'XX_PO_65120_CATEGORY_END_DATE';  
                        p_entity_reference       := lr_mlss_rec.category_level||'-'|| lr_mlss_rec.category ;
                        p_entity_ref_id          := 0;  

                        write_exception ( p_error_code        => p_error_code
                                         ,p_error_description => p_error_description
                                         ,p_entity_reference  => p_entity_reference
                                         ,p_entity_ref_id     => p_entity_ref_id);
                                         
                        FND_FILE.PUT_LINE(FND_FILE.LOG,p_error_description);

                    WHEN OTHERS THEN
                        RAISE;
                END;  

            END IF;  -- end of department END_DATE branch

        ELSIF lr_mlss_rec.category_level = 'Division'  THEN

            IF (lr_mlss_rec.end_date >= SYSDATE OR lr_mlss_rec.end_date IS NULL) THEN

                -- Query to check if there are any Departments and Classes 
                -- that belong to the given Division in MLSS header table
                BEGIN
                    SELECT 'Y'
                    INTO   lc_temp
                    FROM   mtl_categories MC
                    WHERE  MC.segment1 = lr_mlss_rec.category
                    AND EXISTS 
                        (SELECT 1 
                        FROM xx_po_mlss_hdr XPMH
                        WHERE (XPMH.category = MC.segment4 
                                OR XPMH.category = MC.segment3)
                        AND XPMH.category_level IN ('Class','Department')         
                        AND XPMH.using_organization_id = lr_mlss_rec.using_organization_id
                        AND (XPMH.end_date IS NULL OR XPMH.end_date > SYSDATE))
                        AND ROWNUM = 1;

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lc_temp := 'N';

                    WHEN OTHERS THEN
                        RAISE;
                END;

                IF lc_temp ='N' THEN

                    x_err_msg   := NULL;
                    x_ret_code  := NULL;
                    ---------------------------------------  
                    -- Call the update_mlss_name procedure
                    ---------------------------------------
                    update_mlss_name (
                                       p_using_org_id   => lr_mlss_rec.using_organization_id,
                                       p_category       => lr_mlss_rec.category,
                                       p_category_level => lr_mlss_rec.category_level,
                                       p_vendor_id      => lr_mlss_rec.vendor_id,
                                       p_vendor_site_id => lr_mlss_rec.vendor_site_id,
                                       x_err_buf        => x_err_msg,
                                       x_ret_no         => x_ret_code
                                     );

                    IF x_ret_code = 1 THEN
                        FND_FILE.PUT_LINE (FND_FILE.LOG,x_err_msg);
                    END IF;

                END IF; 


            ELSIF (lr_mlss_rec.end_date < SYSDATE AND lr_mlss_rec.end_date IS NOT NULL) THEN

                BEGIN 
                    -- Check if any Class or Department is Active for the given Division
                    SELECT 'Y'
                    INTO   lc_exist
                    FROM   mtl_categories MC
                    WHERE  MC.segment1 = lr_mlss_rec.category
                    AND EXISTS 
                        (SELECT 1 
                         FROM   xx_po_mlss_hdr XPMH
                         WHERE (XPMH.category = MC.segment3 OR XPMH.category = MC.segment4)
                         AND    XPMH.category_level IN ('Class','Department')
                         AND    XPMH.using_organization_id = lr_mlss_rec.using_organization_id
                         AND   (XPMH.end_date IS NULL OR XPMH.end_date > SYSDATE))
                         AND ROWNUM = 1; 

                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        lc_exist := 'N';
                        FND_MESSAGE.SET_NAME('XXOM','XX_PO_65120_CATEGORY_END_DATE');
                        FND_MESSAGE.SET_TOKEN('CATEGORY_LEVEL',lr_mlss_rec.category_level);
                        FND_MESSAGE.SET_TOKEN('CATEGORY',lr_mlss_rec.category);
                        p_error_description      := FND_MESSAGE.GET;
                        p_error_code             := 'XX_PO_65120_CATEGORY_END_DATE';  
                        p_entity_reference       := lr_mlss_rec.category_level||'-'|| lr_mlss_rec.category ;
                        p_entity_ref_id          := 0;  

                        write_exception ( p_error_code        => p_error_code
                                         ,p_error_description => p_error_description
                                         ,p_entity_reference  => p_entity_reference
                                         ,p_entity_ref_id     => p_entity_ref_id);

                        FND_FILE.PUT_LINE(FND_FILE.LOG,p_error_description);


                    WHEN OTHERS THEN
                        RAISE;
                END;  

            END IF;    -- end of division END_DATE branch

        END IF;    -- end of CATEGORY_LEVEL branch

    END LOOP;  -- end of the main loop
    
    FND_FILE.PUT_LINE (FND_FILE.LOG,'No of Records Insert into MLSS Custom table :' || g_insert_cnt);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'No of Records updated in MLSS Custom table :' || g_update_cnt);
    
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,'+------------------------------------------------+');                
    FND_FILE.PUT_LINE(FND_FILE.LOG, '           END of MLSS Program                  ' );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'+------------------------------------------------+');        


    x_retcode := 0;


EXCEPTION

    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERR');
        FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
        FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
        x_errbuf              := FND_MESSAGE.GET;
        p_error_description   := x_errbuf;
        x_retcode             := 1;
        p_entity_reference    := 'Unexpected Error in MLSS Program';
        p_entity_ref_id       := 0;
        p_error_code          := 'XX_OM_65100_UNEXPECTED_ERR';             

        -- Call the write_exception procedure to insert into
        -- Global exception table
        write_exception ( p_error_code        => p_error_code
                         ,p_error_description => p_error_description
                         ,p_entity_reference  => p_entity_reference
                         ,p_entity_ref_id     => p_entity_ref_id);


        FND_FILE.PUT_LINE (FND_FILE.LOG,x_errbuf);     
END update_mlss_main;


END XX_PO_MLSS_PKG;
/

SHOW ERRORS

EXIT;

