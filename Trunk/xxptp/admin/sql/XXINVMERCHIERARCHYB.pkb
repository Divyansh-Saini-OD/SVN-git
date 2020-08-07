SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_MERC_HIERARCHY_PKG 
AS 
-- +===================================================================================================== +
-- |                  Office Depot - Project Simplify                                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                                          |
-- +======================================================================================================+
-- | Name       : XX_INV_MERC_HIERARCHY_PKG                                                               |
-- | Description: This package body contains the following procedures:                                    |
-- |              (1) GET_PARENT_VALUE                                                                    |
-- |              (2) DISABLE_VSET_VALUE                                                                  |
-- |              (3) CALL_UP_VSET_VALUE                                                                  |
-- |              (4) SET_VS_NAME_ID                                                                      |
-- |              (5) GET_VS_ID                                                                           |
-- |              (6) GET_CATEGORY_DETAILS                                                                |
-- |              (7) PROCESS_MERC_HIERARCHY                                                              |
-- |                                                                                                      |
-- |Change Record:                                                                                        |
-- |===============                                                                                       |
-- |Version   Date         Author           Remarks                                                       |
-- |=======   ==========   ===============  ==============================                                |
-- |DRAFT 1A  14-MAR-2007  Siddharth Singh  Initial draft version                                         |
-- |DRAFT 1B  25-APR-2007  Siddharth Singh  Incorporated changes as per CR for renaming value sets.       |
-- |DRAFT 1C  15-MAY-2007  Siddharth singh  Incorporated changes as per CR for creating PO Category Codes.|
-- |                                                                                                      |
-- +======================================================================================================+


PROCEDURE GET_PARENT_VALUE (p_vs_id      IN  NUMBER
                           ,p_vs_value   IN  VARCHAR2
                           ,x_parent_num OUT VARCHAR2
                           ,x_err_code   OUT NUMBER
                           ,x_err_msg    OUT VARCHAR2
                          )

-- +====================================================================================================================+
-- |                                                                                                                    |
-- | Name             : GET_PARENT_VALUE                                                                                |
-- |                                                                                                                    |
-- | Description      : Gets the parent value to which the p_vs_value belongs                                           |
-- |                                  .                                                                                 |
-- |                                                                                                                    |
-- | Parameters       : p_vs_id      IN   Value set id to which p_vs_value belongs                                      |
-- |                    p_vs_value   IN   Value for which parent needs to found.                                        |
-- |                    x_parent_num OUT  Value of the parent to which the p_vs_value belomgs                           |
-- |                    x_err_code   OUT .Code to Indicate Success(0),Warning(1) or Error(-1).                          |
-- |                    x_err_msg    OUT .The message associated with the error.                                        |
-- +====================================================================================================================+

IS 

BEGIN

         SELECT attribute1
         INTO   x_parent_num  
         FROM   fnd_flex_values
         WHERE  flex_value_set_id = p_vs_id
         AND    flex_value = p_vs_value;

x_err_code := 0;

EXCEPTION

WHEN NO_DATA_FOUND THEN
     x_err_code := -1;
     x_err_msg  := 'ERROR in Procedure XX_INV_MERC_HIERARCHY_PKG.GET_PARENT_VALUE ';
     x_err_msg  := x_err_msg || SQLERRM;

WHEN OTHERS THEN
     x_err_code := -1;
     x_err_msg  := 'ERROR in Procedure XX_INV_MERC_HIERARCHY_PKG.GET_PARENT_VALUE ';
     x_err_msg  := x_err_msg || SQLERRM;     
END GET_PARENT_VALUE;



PROCEDURE DISABLE_VSET_VALUE ( p_vs_id             IN  NUMBER   
                              ,p_value_to_disable  IN  VARCHAR2 
                              ,p_vs_name           IN  VARCHAR2
                              ,x_err_code          OUT NUMBER
                              ,x_err_msg           OUT VARCHAR2
                             )
-- +==================================================================================================================+
-- |                                                                                                                  |
-- | Name             : DISABLE_VSET_VALUE                                                                            |
-- |                                                                                                                  |
-- | Description      : It disables the value set value Identified by the IN Parameters                               |
-- |                                  .                                                                               |
-- |                                                                                                                  |
-- | Parameters       : p_vs_id             IN  Id of the value set to which the value to disable belongs.            |
-- |                    p_value_to_disable  IN  The value to disable                                        .         |
-- |                    p_vs_name           IN  Name of the value set to which the value to disable belongs.          |
-- |                    x_err_code          OUT Code to Indicate Success(0),Warning(1) or Error(-1).                  |
-- |                    x_err_msg           OUT The message associated with the error.                                |
-- +==================================================================================================================+
IS
le_end_procedure        EXCEPTION;
lc_existing_description VARCHAR2(3000);
lr_ffv_typ              fnd_flex_values%ROWTYPE;
lc_enabled_flag         VARCHAR2(1);


BEGIN 
 
                -- Since this Value already Exists,Get values for this record 
                BEGIN
                
                     SELECT *
                     INTO   lr_ffv_typ             
                     FROM   fnd_flex_values
                     WHERE  flex_value_set_id = p_vs_id
                     AND    flex_value = p_value_to_disable;
                
                EXCEPTION
                WHEN others THEN
                x_err_code := -1;
                x_err_msg := 'ERROR in Procedure XX_INV_MERC_HIERARCHY_PKG.DISABLE_VSET_VALUE,ffv. ';
                x_err_msg := 'Failed to fetch already existing record for disabling the value when Action = DELETE. ';
                x_err_msg  := x_err_msg || SQLERRM;
                Raise le_end_procedure;
                END;
                
                -- Get description for this value 
                BEGIN
                
                     SELECT description
                     INTO   lc_existing_description             
                     FROM   fnd_flex_values_tl
                     WHERE  flex_value_id = lr_ffv_typ.flex_value_id;
                
                EXCEPTION
                WHEN others THEN
                x_err_code := -1;
                x_err_msg := 'ERROR in Procedure XX_INV_MERC_HIERARCHY_PKG.DISABLE_VSET_VALUE. ';
                x_err_msg := 'Failed to fetch description for existing record for disabling the value when Action = DELETE. ';
                x_err_msg  := x_err_msg || SQLERRM;
                Raise le_end_procedure;
                END;                
                
               -- disable the value itself by using Disable Date feature.Setting end_date_active 
                FND_FLEX_LOADER_APIS.UP_VSET_VALUE (  p_upload_phase                 => 'BEGIN'    
                                                     ,p_upload_mode                  =>  NULL
                                                     ,p_custom_mode                  =>  NULL
                                                     ,p_flex_value_set_name          =>  p_vs_name
                                                     ,p_parent_flex_value_low        =>  NULL                
                                                     ,p_flex_value                   =>  p_value_to_disable
                                                     ,p_owner                        =>  'APPS'
                                                     ,p_last_update_date             =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                                     ,p_enabled_flag                 =>  'N'
                                                     ,p_summary_flag                 =>  lr_ffv_typ.summary_flag
                                                     ,p_start_date_active            =>  lr_ffv_typ.start_date_active
                                                     ,p_end_date_active              =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                                     ,p_parent_flex_value_high       =>  lr_ffv_typ.parent_flex_value_high
                                                     ,p_rollup_hierarchy_code        =>  NULL
                                                     ,p_hierarchy_level              =>  lr_ffv_typ.hierarchy_level
                                                     ,p_compiled_value_attributes    =>  lr_ffv_typ.compiled_value_attributes
                                                     ,p_value_category               =>  lr_ffv_typ.value_category
                                                     ,p_attribute1                   =>  lr_ffv_typ.attribute1
                                                     ,p_attribute2                   =>  lr_ffv_typ.attribute2
                                                     ,p_attribute3                   =>  lr_ffv_typ.attribute3
                                                     ,p_attribute4                   =>  lr_ffv_typ.attribute4
                                                     ,p_attribute5                   =>  lr_ffv_typ.attribute5
                                                     ,p_attribute6                   =>  lr_ffv_typ.attribute6
                                                     ,p_attribute7                   =>  lr_ffv_typ.attribute7
                                                     ,p_attribute8                   =>  lr_ffv_typ.attribute8
                                                     ,p_attribute9                   =>  lr_ffv_typ.attribute9
                                                     ,p_attribute10                  =>  lr_ffv_typ.attribute10
                                                     ,p_attribute11                  =>  lr_ffv_typ.attribute11
                                                     ,p_attribute12                  =>  lr_ffv_typ.attribute12
                                                     ,p_attribute13                  =>  lr_ffv_typ.attribute13
                                                     ,p_attribute14                  =>  lr_ffv_typ.attribute14
                                                     ,p_attribute15                  =>  lr_ffv_typ.attribute15
                                                     ,p_attribute16                  =>  lr_ffv_typ.attribute16
                                                     ,p_attribute17                  =>  lr_ffv_typ.attribute17
                                                     ,p_attribute18                  =>  lr_ffv_typ.attribute18
                                                     ,p_attribute19                  =>  lr_ffv_typ.attribute19
                                                     ,p_attribute20                  =>  lr_ffv_typ.attribute20
                                                     ,p_attribute21                  =>  lr_ffv_typ.attribute21
                                                     ,p_attribute22                  =>  lr_ffv_typ.attribute22
                                                     ,p_attribute23                  =>  lr_ffv_typ.attribute23
                                                     ,p_attribute24                  =>  lr_ffv_typ.attribute24
                                                     ,p_attribute25                  =>  lr_ffv_typ.attribute25
                                                     ,p_attribute26                  =>  lr_ffv_typ.attribute26
                                                     ,p_attribute27                  =>  lr_ffv_typ.attribute27
                                                     ,p_attribute28                  =>  lr_ffv_typ.attribute28
                                                     ,p_attribute29                  =>  lr_ffv_typ.attribute29
                                                     ,p_attribute30                  =>  lr_ffv_typ.attribute30
                                                     ,p_attribute31                  =>  lr_ffv_typ.attribute31
                                                     ,p_attribute32                  =>  lr_ffv_typ.attribute32
                                                     ,p_attribute33                  =>  lr_ffv_typ.attribute33
                                                     ,p_attribute34                  =>  lr_ffv_typ.attribute34
                                                     ,p_attribute35                  =>  lr_ffv_typ.attribute35
                                                     ,p_attribute36                  =>  lr_ffv_typ.attribute36
                                                     ,p_attribute37                  =>  lr_ffv_typ.attribute37
                                                     ,p_attribute38                  =>  lr_ffv_typ.attribute38
                                                     ,p_attribute39                  =>  lr_ffv_typ.attribute39
                                                     ,p_attribute40                  =>  lr_ffv_typ.attribute40
                                                     ,p_attribute41                  =>  lr_ffv_typ.attribute41
                                                     ,p_attribute42                  =>  lr_ffv_typ.attribute42
                                                     ,p_attribute43                  =>  lr_ffv_typ.attribute43
                                                     ,p_attribute44                  =>  lr_ffv_typ.attribute44
                                                     ,p_attribute45                  =>  lr_ffv_typ.attribute45
                                                     ,p_attribute46                  =>  lr_ffv_typ.attribute46
                                                     ,p_attribute47                  =>  lr_ffv_typ.attribute47
                                                     ,p_attribute48                  =>  lr_ffv_typ.attribute48
                                                     ,p_attribute49                  =>  lr_ffv_typ.attribute49
                                                     ,p_attribute50                  =>  lr_ffv_typ.attribute50
                                                     ,p_attribute_sort_order         =>  lr_ffv_typ.attribute_sort_order
                                                     ,p_flex_value_meaning           =>  NULL 
                                                     ,p_description                  =>  lc_existing_description
                                                   );
                COMMIT;
                
                -- check if the value got disabled by the previous UP_VSET_VALUE call
                BEGIN
                 
                     SELECT enabled_flag
                     INTO   lc_enabled_flag
                     FROM   fnd_flex_values
                     WHERE  flex_value_set_id = p_vs_id
                     AND    flex_value        = p_value_to_disable;
                     
                     IF (lc_enabled_flag = 'N') THEN
                         x_err_code := 0;
                     ELSE
                         x_err_code := -1;
                         x_err_msg  := 'Failed to disable the value ' || p_value_to_disable ;
                         x_err_msg  := ' For the Value Set ' || p_vs_name ;
                         x_err_msg  := 'in the Procedure XX_INV_MERC_HIERARCHY_PKG.DISABLE_VSET_VALUE';
                     END IF;
                
                
                EXCEPTION
                    
                     WHEN OTHERS THEN
                     x_err_code:= -1;
                     x_err_msg := 'ERROR in Procedure XX_INV_MERC_HIERARCHY_PKG.DISABLE_VSET_VALUE ';
                
                END;
                
x_err_code := 0;
                
EXCEPTION

WHEN le_end_procedure THEN
     NULL;

WHEN OTHERS THEN
     x_err_code:= -1;
     x_err_msg := 'ERROR in Procedure XX_INV_MERC_HIERARCHY_PKG.DISABLE_VSET_VALUE ';
     x_err_msg := x_err_msg || SQLERRM;     

END DISABLE_VSET_VALUE;


PROCEDURE CALL_UP_VSET_VALUE( p_upload_phase                 IN  VARCHAR2  DEFAULT 'BEGIN'    
                              ,p_upload_mode                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_custom_mode                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_flex_value_set_name         IN  VARCHAR2  
                              ,p_parent_flex_value_low       IN  VARCHAR2  DEFAULT  NULL                
                              ,p_flex_value                  IN  VARCHAR2  
                              ,p_owner                       IN  VARCHAR2  DEFAULT  'APPS'
                              ,p_last_update_date            IN  VARCHAR2  DEFAULT  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                              ,p_enabled_flag                IN  VARCHAR2  
                              ,p_summary_flag                IN  VARCHAR2  
                              ,p_start_date_active           IN  VARCHAR2  
                              ,p_end_date_active             IN  VARCHAR2  
                              ,p_parent_flex_value_high      IN  VARCHAR2  DEFAULT  NULL
                              ,p_rollup_hierarchy_code       IN  VARCHAR2  DEFAULT  NULL
                              ,p_hierarchy_level             IN  VARCHAR2  DEFAULT  NULL
                              ,p_compiled_value_attributes   IN  VARCHAR2  DEFAULT  NULL
                              ,p_value_category              IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute1                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute2                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute3                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute4                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute5                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute6                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute7                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute8                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute9                  IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute10                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute11                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute12                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute13                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute14                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute15                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute16                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute17                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute18                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute19                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute20                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute21                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute22                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute23                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute24                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute25                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute26                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute27                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute28                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute29                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute30                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute31                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute32                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute33                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute34                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute35                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute36                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute37                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute38                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute39                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute40                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute41                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute42                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute43                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute44                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute45                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute46                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute47                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute48                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute49                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute50                 IN  VARCHAR2  DEFAULT  NULL
                              ,p_attribute_sort_order        IN  VARCHAR2  DEFAULT  NULL
                              ,p_flex_value_meaning          IN  VARCHAR2  DEFAULT  NULL
                              ,p_description                 IN  VARCHAR2  DEFAULT  NULL
                              ,x_err_code                    OUT NUMBER
                              ,x_err_msg                     OUT VARCHAR2
                             )
-- +==================================================================================================================+
-- |                                                                                                                  |
-- | Name             : CALL_UP_VSET_VALUE                                                                            |
-- |                                                                                                                  |
-- | Description      : Calls UP_VSET_VALUE with default parameters.                                                  |
-- +==================================================================================================================+
IS

BEGIN

     FND_FLEX_LOADER_APIS.UP_VSET_VALUE(p_upload_phase               => p_upload_phase             
                                        ,p_upload_mode               => p_upload_mode              
                                        ,p_custom_mode               => p_custom_mode              
                                        ,p_flex_value_set_name       => p_flex_value_set_name      
                                        ,p_parent_flex_value_low     => p_parent_flex_value_low    
                                        ,p_flex_value                => p_flex_value               
                                        ,p_owner                     => p_owner                    
                                        ,p_last_update_date          => p_last_update_date         
                                        ,p_enabled_flag              => p_enabled_flag             
                                        ,p_summary_flag              => p_summary_flag             
                                        ,p_start_date_active         => p_start_date_active        
                                        ,p_end_date_active           => p_end_date_active          
                                        ,p_parent_flex_value_high    => p_parent_flex_value_high   
                                        ,p_rollup_hierarchy_code     => p_rollup_hierarchy_code    
                                        ,p_hierarchy_level           => p_hierarchy_level          
                                        ,p_compiled_value_attributes => p_compiled_value_attributes
                                        ,p_value_category            => p_value_category           
                                        ,p_attribute1                => p_attribute1               
                                        ,p_attribute2                => p_attribute2               
                                        ,p_attribute3                => p_attribute3               
                                        ,p_attribute4                => p_attribute4               
                                        ,p_attribute5                => p_attribute5               
                                        ,p_attribute6                => p_attribute6               
                                        ,p_attribute7                => p_attribute7               
                                        ,p_attribute8                => p_attribute8               
                                        ,p_attribute9                => p_attribute9               
                                        ,p_attribute10               => p_attribute10              
                                        ,p_attribute11               => p_attribute11              
                                        ,p_attribute12               => p_attribute12              
                                        ,p_attribute13               => p_attribute13              
                                        ,p_attribute14               => p_attribute14              
                                        ,p_attribute15               => p_attribute15              
                                        ,p_attribute16               => p_attribute16              
                                        ,p_attribute17               => p_attribute17              
                                        ,p_attribute18               => p_attribute18              
                                        ,p_attribute19               => p_attribute19              
                                        ,p_attribute20               => p_attribute20              
                                        ,p_attribute21               => p_attribute21              
                                        ,p_attribute22               => p_attribute22              
                                        ,p_attribute23               => p_attribute23              
                                        ,p_attribute24               => p_attribute24              
                                        ,p_attribute25               => p_attribute25              
                                        ,p_attribute26               => p_attribute26              
                                        ,p_attribute27               => p_attribute27              
                                        ,p_attribute28               => p_attribute28              
                                        ,p_attribute29               => p_attribute29              
                                        ,p_attribute30               => p_attribute30              
                                        ,p_attribute31               => p_attribute31              
                                        ,p_attribute32               => p_attribute32              
                                        ,p_attribute33               => p_attribute33              
                                        ,p_attribute34               => p_attribute34              
                                        ,p_attribute35               => p_attribute35              
                                        ,p_attribute36               => p_attribute36              
                                        ,p_attribute37               => p_attribute37              
                                        ,p_attribute38               => p_attribute38              
                                        ,p_attribute39               => p_attribute39              
                                        ,p_attribute40               => p_attribute40              
                                        ,p_attribute41               => p_attribute41              
                                        ,p_attribute42               => p_attribute42              
                                        ,p_attribute43               => p_attribute43              
                                        ,p_attribute44               => p_attribute44              
                                        ,p_attribute45               => p_attribute45              
                                        ,p_attribute46               => p_attribute46              
                                        ,p_attribute47               => p_attribute47              
                                        ,p_attribute48               => p_attribute48              
                                        ,p_attribute49               => p_attribute49              
                                        ,p_attribute50               => p_attribute50              
                                        ,p_attribute_sort_order      => p_attribute_sort_order     
                                        ,p_flex_value_meaning        => p_flex_value_meaning       
                                        ,p_description               => p_description              
                                        );

x_err_code := 0;

EXCEPTION
WHEN OTHERS THEN
     x_err_code:= -1;
     x_err_msg := 'ERROR in Procedure XX_INV_MERC_HIERARCHY_PKG.CALL_UP_VSET_VALUE ';
     x_err_msg := x_err_msg || SQLERRM;     

END CALL_UP_VSET_VALUE;


PROCEDURE SET_VS_NAME_ID(p_hierarchy_level IN  VARCHAR2
                        ,x_vs_name         OUT VARCHAR2
                        ,x_vs_id           OUT NUMBER
                        ,x_err_code        OUT NUMBER
                        ,x_err_msg         OUT VARCHAR2
                        )
-- +==================================================================================================================+
-- |                                                                                                                  |
-- | Name             : SET_VS_NAME_ID                                                                                |
-- |                                                                                                                  |
-- | Description      : Sets the Name and Id of the Value Set based on the Hierarchy Level                            |
-- |                                  .                                                                               |
-- |                                                                                                                  |
-- | Parameters       : p_hierarchy_level  IN  The in parameter to PROCESS_MERC_HIERARCHY       .                     |
-- |                    x_vs_name          OUT The flex value name of the value set                         .         |
-- |                    x_vs_id            OUT The flex value id of the value set                .                    |
-- |                    x_err_code         OUT Code to Indicate Success(0),Warning(1) or Error(-1).                   |
-- |                    x_err_msg          OUT The message associated with the error.                                 |
-- +==================================================================================================================+
IS

BEGIN

                   IF (p_hierarchy_level = 'DIVISION') THEN
                         x_vs_name  := 'XX_GI_DIVISION_VS';
                         
                         BEGIN
                         
                              SELECT flex_value_set_id
                              INTO   x_vs_id
                              FROM   fnd_flex_value_sets
                              WHERE  flex_value_set_name = x_vs_name;
                         
                         EXCEPTION
                              WHEN OTHERS THEN
                              x_err_code:= -1;
                              x_err_msg :='Error:Failed to get DIVISION value set id in Procedure XX_INV_MERC_HIERARCHY_PKG.SET_VS_NAME_ID. ';
                              x_err_msg := x_err_msg || SQLERRM;     
                         END;
                         

                   ELSIF (p_hierarchy_level = 'GROUP') THEN
                         x_vs_name  := 'XX_GI_GROUP_VS';
                         
                         BEGIN
                         
                              SELECT flex_value_set_id
                              INTO   x_vs_id
                              FROM   fnd_flex_value_sets
                              WHERE  flex_value_set_name = x_vs_name;
                         
                         EXCEPTION
                              WHEN OTHERS THEN
                              x_err_code:= -1;
                              x_err_msg :='Error:Failed to get GROUP value set id in Procedure XX_INV_MERC_HIERARCHY_PKG.SET_VS_NAME_ID. ';
                              x_err_msg:= x_err_msg || SQLERRM;     
                         END;

                   ELSIF (p_hierarchy_level = 'DEPARTMENT') THEN
                         x_vs_name  := 'XX_GI_DEPARTMENT_VS';
                         
                         BEGIN
                         
                              SELECT flex_value_set_id
                              INTO   x_vs_id
                              FROM   fnd_flex_value_sets
                              WHERE  flex_value_set_name = x_vs_name;
                         
                         EXCEPTION
                              WHEN OTHERS THEN
                              x_err_code:= -1;
                              x_err_msg :='Error:Failed to get DEPARTMENT value set id in Procedure XX_INV_MERC_HIERARCHY_PKG.SET_VS_NAME_ID. ';
                              x_err_msg:= x_err_msg || SQLERRM;     
                         END;

                   ELSIF (p_hierarchy_level = 'CLASS') THEN
                         x_vs_name  := 'XX_GI_CLASS_VS';

                         BEGIN
                         
                              SELECT flex_value_set_id
                              INTO   x_vs_id
                              FROM   fnd_flex_value_sets
                              WHERE  flex_value_set_name = x_vs_name;
                         
                         EXCEPTION
                              WHEN OTHERS THEN
                              x_err_code:= -1;
                              x_err_msg :='Error:Failed to get CLASS value set id in Procedure XX_INV_MERC_HIERARCHY_PKG.SET_VS_NAME_ID. ';
                              x_err_msg:= x_err_msg || SQLERRM;     
                         END;
                        
                   ELSIF (p_hierarchy_level = 'SUBCLASS') THEN
                         x_vs_name  := 'XX_GI_SUBCLASS_VS';

                         BEGIN
                         
                              SELECT flex_value_set_id
                              INTO   x_vs_id
                              FROM   fnd_flex_value_sets
                              WHERE  flex_value_set_name = x_vs_name;
                         
                         EXCEPTION
                              WHEN OTHERS THEN
                              x_err_code:= -1;
                              x_err_msg :='Error:Failed to get SUBCLASS value set id in Procedure XX_INV_MERC_HIERARCHY_PKG.SET_VS_NAME_ID. ';
                              x_err_msg:= x_err_msg || SQLERRM;     
                         END;
                   END IF;

x_err_code := 0;

EXCEPTION
WHEN OTHERS THEN
     x_err_code:= -1;
     x_err_msg := 'Error:in Procedure XX_INV_MERC_HIERARCHY_PKG.SET_VS_NAME_ID. ';
     x_err_msg := x_err_msg || SQLERRM;     

END SET_VS_NAME_ID;


PROCEDURE GET_VS_ID (p_vs_name  IN   VARCHAR2
                    ,x_vs_id    OUT  NUMBER
                    ,x_err_code OUT  NUMBER
                    ,x_err_msg  OUT  VARCHAR2) 

-- +==================================================================================================================+
-- |                                                                                                                  |
-- | Name             : GET_VS_ID                                                                                     |
-- |                                                                                                                  |
-- | Description      : Gets the value set id from the fnd_flex_value_sets table                                      |
-- |                                  .                                                                               |
-- |                                                                                                                  |
-- | Parameters       : p_vs_name   Name of the value set for which the id is required.                               |
-- |                    x_err_code  OUT Code to Indicate Success(0),Warning(1) or Error(-1).                          |
-- |                    x_err_msg   OUT The message associated with the error.                                        |
-- +==================================================================================================================+

IS 

BEGIN
   
       SELECT flex_value_set_id 
       INTO   x_vs_id
       FROM   fnd_flex_value_sets
       WHERE  flex_value_set_name = p_vs_name;

x_err_code := 0;

EXCEPTION
WHEN OTHERS THEN
     x_err_code:= -1;
     x_err_msg :='Error in Procedure XX_INV_MERC_HIERARCHY_PKG.GET_VS_ID ';
     x_err_msg := x_err_msg || SQLERRM;     

END GET_VS_ID;


PROCEDURE GET_CATEGORY_DETAILS( p_category_id IN  NUMBER
                               ,lr_mcb        OUT mtl_categories_b%ROWTYPE
                               ,x_err_code    OUT NUMBER
                               ,x_err_msg     OUT VARCHAR2
                               ) 
-- +==================================================================================================================+
-- |                                                                                                                  |
-- | Name             : GET_CATEGORY_DETAILS                                                                          |
-- |                                                                                                                  |
-- | Description      : Gets all the details for the given category_id                                                |
-- |                                                                                                                  |
-- |                                                                                                                  |
-- | Parameters       : p_category_id   IN  Category Id for which details are to be fetched.                          |
-- |                    lr_mcb          OUT Contains the details for the given category id                            |
-- |                    x_err_code      OUT Code to Indicate Success(0),Warning(1) or Error(-1).                      |
-- |                    x_err_msg       OUT The message associated with the error.                                    |
-- |                                                                                                                  |
-- +==================================================================================================================+
IS

BEGIN

 SELECT *
 INTO   lr_mcb
 FROM   mtl_categories_b mcb
 WHERE  mcb.category_id = p_category_id;


EXCEPTION
WHEN NO_DATA_FOUND THEN
     x_err_code := -1;
     x_err_msg  := 'Error:Failed to fetch category record in Procedure XX_INV_MERC_HIERARCHY_PKG.GET_CATEGORY_DETAILS';
     x_err_msg  := x_err_msg || SQLERRM;

WHEN OTHERS THEN
     x_err_code:= -1;
     x_err_msg := 'Error:in Procedure XX_INV_MERC_HIERARCHY_PKG.GET_CATEGORY_DETAILS ';
     x_err_msg := x_err_msg || SQLERRM;     

END GET_CATEGORY_DETAILS;


PROCEDURE PROCESS_MERC_HIERARCHY(p_hierarchy_level                    IN   VARCHAR2
                                ,p_value                              IN   NUMBER  
                                ,p_description                        IN   VARCHAR2
                                ,p_action                             IN   VARCHAR2
                                ,p_division_number                    IN   VARCHAR2
                                ,p_group_number                       IN   VARCHAR2
                                ,p_dept_number                        IN   VARCHAR2
                                ,p_class_number                       IN   VARCHAR2
                                ,p_dept_forecastingind                IN   VARCHAR2
                                ,p_dept_aipfilterind                  IN   VARCHAR2  DEFAULT NULL
                                ,p_dept_planningind                   IN   VARCHAR2
                                ,p_dept_noncodeind                    IN   VARCHAR2
                                ,p_dept_ppp_ind                       IN   VARCHAR2
                                ,p_class_nbrdaysamd                   IN   NUMBER  
                                ,p_class_fifthmrkdwnprocsscd          IN   VARCHAR2
                                ,p_class_prczcostflg                  IN   VARCHAR2
                                ,p_class_prczpriceflag                IN   VARCHAR2
                                ,p_class_priczlistflag                IN   VARCHAR2
                                ,p_class_furnitureflag                IN   VARCHAR2
                                ,p_class_aipfilterind                 IN   VARCHAR2  DEFAULT NULL
                                ,p_subclass_defaulttaxcat             IN   VARCHAR2
                                ,p_subclass_globalcontentind          IN   VARCHAR2
                                ,p_subclass_aipfilterind              IN   VARCHAR2  DEFAULT NULL
                                ,p_subclass_ppp_ind                   IN   VARCHAR2
                                ,x_error_msg                          OUT  VARCHAR2
                                ,x_error_code                         OUT  NUMBER  
                                )
-- +=========================================================================================================================+
-- |                                                                                                                         |
-- | Name             : PROCESS_MERC_HIERARCHY                                                                               |
-- |                                                                                                                         |
-- | Description      : This Procedure is invoked from the BPEL proces LoadMercHierarchyInProcess.                           |
-- |                    If the p_action parameter is 'ADD'                                                                   |
-- |                       The procedure adds the value (p_value) to a value set identified by p_hierarchy_level.            |
-- |                       If the value already exists in the value set and is enabled then it does nothing and exits.       |
-- |                       If the value already exists in the value set but is disabled then it first enables the code       |
-- |                       combinatons using this value then enables the value itself.                                       |
-- |                    If the p_acton parameter is 'MODIFY'                                                                 |
-- |                       the procedure checks if the value already exists and is enabled.If the values exists and is       |
-- |                       enabled the description is modified.                                                              |
-- |                       If it does not exist or is not enabled the procedure exits                                        |
-- |                    If the p_action parameter is 'DELETE'                                                                |
-- |                       it checks if this value is being used in category code combinations.If the value is used          |
-- |                       in category code combinations then first disable the code combinations then the value.            |
-- |                    The value set hierarchy is as follows:-                                                              |
-- |                    DIVISION                                                                                             |
-- |                    GROUP                                                                                                |
-- |                    DEPARTMENT                                                                                           |
-- |                    CLASS                                                                                                |
-- |                    SUBCLASS                                                                                             |
-- |                                                                                                                         |
-- | Parameters       : p_hierarchy_level             DIVISION,GROUP,DEPARTMENT,CLASS,SUBCLASS.                              |
-- |                    p_value                       The incoming value to be ADDED,MODIFIED or DELETED.                    |
-- |                    p_description                 The description of the incoming value.                                 |
-- |                    p_action                      Action to be performed on the value set ADD,MODIFY,DELETE.             |
-- |                    p_division_number             Required if p_hierarchy_level is'GROUP'.                               |
-- |                    p_group_number                Required if p_hierarchy_level is'DEPARTMENT'.                          |
-- |                    p_dept_number                 Required if p_hierarchy_level is'CLASS'.                               |
-- |                    p_class_number                Required if p_hierarchy_level is'SUBCLASS'.                            |
-- |                    p_dept_forecastingind         "Y"es when Office Depot plans the department in Retek Demand           |
-- |                                                     Forecasting (RDF) otherwise "N"o.                                   |
-- |                    p_dept_aipfilterind           AipFilterIndicator for Department.                                     |
-- |                    p_dept_planningind            Indicates if Department is Planned in TopPlan.                         |
-- |                    p_dept_noncodeind             Indicates a Special item.True indicates the SKU is a Non-Code item.    |
-- |                    p_dept_ppp_ind                Indicates if the product protection plans is offered on SKU.           |
-- |                    p_class_nbrdaysamd            This is the number of days from the day a SKU, within this class,      |
-- |                                                     would enter Auto Markdown (AMD) before coming off a                 |
-- |                                                     planogram in retail.                                                |
-- |                    p_class_fifthmrkdwnprocsscd   Indicates if SKUs in the class were eligible for a fifth Markdownstream|
-- |                    p_class_prczcostflg           Indicates if zero cost is allowed. True means the class will allow     |
-- |                                                     $0.00 to be entered as a cost.                                      |
-- |                    p_class_prczpriceflag         Indicates if zero Retail price is allowed. True means the class will   |
-- |                                                     allow $0.00 to be entered as a Retail Price.                        |
-- |                    p_class_priczlistflag         Indicates if zero List price is allowed. True means the class will     |
-- |                                                     allow $0.00 to be entered as a List Price.                          |
-- |                    p_class_furnitureflag         Identifies a furniture class to present delivery options to user.      |
-- |                    p_class_aipfilterind          AipFilterIndicator for Class.                                          |
-- |                    p_subclass_defaulttaxcat      Represents the default tax category for the subclass.                  |
-- |                    p_subclass_globalcontentind   Indicates if subclass should be entered in Global Content Management.. |
-- |                    p_subclass_aipfilterind       AipFilterIndicator for Subclass.                                       |
-- |                    p_subclass_ppp_ind            Indicates if the product protection plans is offered on SKU.           |
-- |                    x_error_code                  0 (Zero) Indicates Success.                                            |
-- |                                                  1 Indicates WARNING (Functional ERROR).                                |
-- |                                                  -1 Indicates ERROR   (System ERROR).                                   |
-- |                    x_error_msg                   Message describing the error.                                          |
-- |                                                                                                                         |
-- +=========================================================================================================================+
                                
IS
le_end_procedure              EXCEPTION;

lc_class_vs_name              VARCHAR2(100)  := 'XX_GI_CLASS_VS';
lc_commit                     VARCHAR2(1);
lc_converted_value            VARCHAR(15);
lc_is_null_flag               VARCHAR2(1);               -- When='Y' it indicates that the parent segment is null
lc_exist_enabled              VARCHAR2(1);               -- When='Y' it indicates that the value exists and is enabled 
ln_flex_value_set_id          NUMBER;
lr_ffv_typ                    fnd_flex_values%ROWTYPE;
lr_mcb_typ                    mtl_categories_b%ROWTYPE;
-- IN/OUT parameters to API INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY
lc_init_msg_list              VARCHAR2(3000);
lc_msg_data                   VARCHAR2(3000);
lc_return_status              VARCHAR2(1);  -- S, E or U
ln_api_version_uc             NUMBER         := 1.0;                         -- API Version Number for UPDATE_CATEGORY 
ln_errorcode                  NUMBER;
ln_msg_count                  NUMBER;
lr_category_rec               Inv_Item_Category_Pub.CATEGORY_REC_TYPE;
-- OUT parameters from API INV_ITEM_CATEGORY_PUB.Create_Category
ln_api_version_cc             NUMBER  := 1.0;                               -- API Version Number for Create_Category
ln_category_id                NUMBER;
-- Input parameters to API FND_FLEX_LOADER_APIS.UP_VSET_VALUE
lc_attribute1                 VARCHAR2(100);
lc_dept_num                   VARCHAR2(100);
lc_dept_val                   VARCHAR2(100);
lc_dept_vs_name               VARCHAR2(100)  := 'XX_GI_DEPARTMENT_VS';
lc_description                VARCHAR2(1000); 
lc_div_num                    VARCHAR2(100);
lc_div_vs_name                VARCHAR2(100)  := 'XX_GI_DIVISION_VS';
lc_err_msg                    VARCHAR2(3000);
lc_enabled_flag               VARCHAR2(1); 
lc_flex_value_set_name        VARCHAR2(100);
lc_group_vs_name              VARCHAR2(100)  := 'XX_GI_GROUP_VS';
lc_grp_num                    VARCHAR2(100);
lc_structure_code             VARCHAR2(30)   := 'ITEM_CATEGORIES';
lc_structure_code_po          VARCHAR2(30)   := 'PO_ITEM_CATEGORY';
lc_subclass_vs_name           VARCHAR2(100)  := 'XX_GI_SUBCLASS_VS';
lc_summary_flag               VARCHAR2(1);
lc_value_category             VARCHAR2(100);
ln_class_value_set_id         NUMBER;
ln_err_code                   NUMBER;
ln_flex_value                 VARCHAR2(150);
ln_flex_value_set_id_class    NUMBER;
ln_flex_value_set_id_dept     NUMBER;
ln_flex_value_set_id_div      NUMBER;
ln_flex_value_set_id_grp      NUMBER;
ln_sclass_vs_id               NUMBER;
ln_structure_id               NUMBER         :=101;
ln_structure_id_po            NUMBER         :=201;



-- Division Cursor
CURSOR get_ccc_div (lc_segment1 VARCHAR2)
IS
SELECT category_id
FROM   mtl_categories_b 
WHERE (structure_id=ln_structure_id) 
AND   segment1= lc_segment1;

-- Group Cursor
Cursor get_ccc_grp (lc_segment1 VARCHAR2, lc_segment2 VARCHAR2)
IS
SELECT category_id
FROM   mtl_categories_b 
WHERE (structure_id=ln_structure_id) 
AND   segment1 = lc_segment1
AND   segment2 = lc_segment2;

-- Department Cursor
Cursor get_ccc_dept (lc_segment2 VARCHAR2, lc_segment3 VARCHAR2)
IS
SELECT category_id
FROM   mtl_categories_b 
WHERE (structure_id=ln_structure_id) 
AND   segment2 = lc_segment2
AND   segment3 = lc_segment3;

-- Class Cursor
Cursor get_ccc_cla (lc_segment3 VARCHAR2, lc_segment4 VARCHAR2)
IS
SELECT category_id
FROM   mtl_categories_b 
WHERE (structure_id=ln_structure_id) 
AND   segment3 = lc_segment3
AND   segment4 = lc_segment4;

-- Subclass Cursor
Cursor get_ccc_sclas (lc_segment4 VARCHAR2, lc_segment5 VARCHAR2)
IS
SELECT category_id
FROM   mtl_categories_b 
WHERE (structure_id=ln_structure_id) 
AND   segment4 = lc_segment4
AND   segment5 = lc_segment5;

CURSOR get_grp_val (p_vs_id NUMBER,p_vs_val VARCHAR2)
IS 
SELECT flex_value 
FROM fnd_flex_values
WHERE flex_value_set_id = p_vs_id
AND attribute1        = p_vs_val;

CURSOR get_depart_val (p_vs_id NUMBER,p_vs_val VARCHAR2)
IS
SELECT flex_value 
FROM fnd_flex_values
WHERE flex_value_set_id = p_vs_id
AND attribute1        = p_vs_val;
   
CURSOR get_class_val (p_vs_id NUMBER,p_vs_val VARCHAR2)
IS
SELECT flex_value 
FROM fnd_flex_values
WHERE flex_value_set_id = p_vs_id
AND attribute1        = p_vs_val;
   
CURSOR get_subclass_val (p_vs_id NUMBER,p_vs_val VARCHAR2)
IS
SELECT flex_value 
FROM fnd_flex_values
WHERE flex_value_set_id = p_vs_id
AND attribute1        = p_vs_val;      

--To get the enabled flag for the given record
CURSOR get_enabled_flag (ln_flex_val_set_id NUMBER, lc_value VARCHAR2)
IS      
SELECT enabled_flag
FROM   fnd_flex_values 
WHERE  flex_value_set_id = ln_flex_val_set_id
AND    flex_value = lc_value;


BEGIN

lc_is_null_flag  := 'Y';
lc_exist_enabled := 'N';
x_error_msg      := NULL;
x_error_code     := NULL;

lc_converted_value := to_char(p_value); 
ln_flex_value      := lc_converted_value;
lc_description     := p_description;


                 IF (p_action IS NULL) THEN
                     x_error_msg := 'Action Criteria is Null,Unable to Perform any action, Ending Procedure PROCESS_MERC_HIERARCHY';
                     x_error_code:=1;
                     RAISE le_end_procedure;
                 END IF;

-- Procedure to populate the value set name and id based on Hierarchy level.
SET_VS_NAME_ID (p_hierarchy_level => p_hierarchy_level
               ,x_vs_name         => lc_flex_value_set_name
               ,x_vs_id           => ln_flex_value_set_id
               ,x_err_code        => ln_err_code
               ,x_err_msg         => lc_err_msg
               );

                 IF (ln_err_code <> 0) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

-- If p_action = 'ADD' then, the value needs to be added to the value set
IF (p_action = 'ADD') THEN
      
          -- check if the value set is GROUP then p_division_number should not be null
          IF (p_hierarchy_level = 'GROUP') THEN 
               
               IF (p_division_number IS NOT NULL) THEN
                   lc_is_null_flag := 'N';
               END IF;
          
          -- check if the value set is 'DEPARTMENT' then p_group_number should not be null
          ElSIF (p_hierarchy_level = 'DEPARTMENT') THEN
               
               IF (p_group_number IS NOT NULL) THEN
                   lc_is_null_flag := 'N';
               END IF;            
            
          -- check if the value set is CLASS  then p_dept_number should not be null
          ELSIF (p_hierarchy_level = 'CLASS') THEN 
               
               IF (p_dept_number IS NOT NULL) THEN
                   lc_is_null_flag := 'N';
               END IF;          
          -- check if the value set is SUBCLASS  then p_class_number should not be null
          ELSIF (p_hierarchy_level = 'SUBCLASS') THEN
               
               IF (p_class_number IS NOT NULL) THEN
                   lc_is_null_flag := 'N';
               END IF;                    
            
          ELSIF (p_hierarchy_level = 'DIVISION') THEN
                   lc_is_null_flag := 'N';               -- Division has no parent.
          END IF;
          -- checking for value set Ends
       
      
          IF (lc_is_null_flag = 'Y') THEN
             x_error_code := 1;
             x_error_msg  := x_error_msg || 'Hierarchy Level- Input parameter validation failed';
             RAISE le_end_procedure;
          END IF;


          
            OPEN  get_enabled_flag (ln_flex_val_set_id => ln_flex_value_set_id,lc_value => lc_converted_value );
            FETCH get_enabled_flag INTO lc_enabled_flag ;
            CLOSE get_enabled_flag;          

          -- If the incoming value already exists in a value set and is enabled, then do noting and EXIT program.
          IF (lc_enabled_flag  = 'Y') THEN
             x_error_code := 0;
             x_error_msg  := x_error_msg || 'Enabled Value set Value Already exists in the Value Set';
             RAISE le_end_procedure;
          END IF;

         
            OPEN  get_enabled_flag (ln_flex_val_set_id => ln_flex_value_set_id,lc_value => lc_converted_value );
            FETCH get_enabled_flag INTO lc_enabled_flag ;
            CLOSE get_enabled_flag;         

            -- lc_exist_enabled = 'N' means the incoming value exists in a value set but is Disabled. 
            -- then try to Enable it.

            IF (lc_enabled_flag  = 'N') THEN
            -- check if this value is being used in category code combinations.
            -- structure_id=101 means id_flex_structure_code = 'ITEM_CATEGORIES'

                   -- Open get_ccc Cursors based on hierarchy level
                   IF (p_hierarchy_level = 'DIVISION') THEN
                       FOR get_ccc_div_rec IN get_ccc_div (lc_segment1 => lc_converted_value)
                       LOOP                
                            -- If used in category code combinations then call INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY 
                            -- to enable the category code combinations using this value.  

                            lr_category_rec.CATEGORY_ID   := get_ccc_div_rec.category_id;

                               -- Get details for this category id from the table
                               GET_CATEGORY_DETAILS (p_category_id => get_ccc_div_rec.category_id
                                                    ,lr_mcb        => lr_mcb_typ
                                                    ,x_err_code    => ln_err_code
                                                    ,x_err_msg     => lc_err_msg
                                                    );

                            lr_category_rec.STRUCTURE_ID          := lr_mcb_typ.STRUCTURE_ID;
                            lr_category_rec.STRUCTURE_CODE        := lc_structure_code;
                            lr_category_rec.SUMMARY_FLAG          := lr_mcb_typ.SUMMARY_FLAG;
                            -- To Enable the code combination
                            lr_category_rec.ENABLED_FLAG          := 'Y';
                            lr_category_rec.START_DATE_ACTIVE     := SYSDATE;
                            lr_category_rec.DISABLE_DATE          := NULL;
                            lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                            lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                            lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                            lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                            lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                            lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                            lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                            lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                            lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                            lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                            lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                            lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                            lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                            lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                            lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                            lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                            lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                            lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                            lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                            lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                            lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                            lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                            lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                            lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                            lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                            lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                            lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                            lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                            lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                            lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                            lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                            lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                            lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                            lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                            lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                            lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                            lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                            lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                            lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                            lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                            INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                  ,p_init_msg_list => lc_init_msg_list
                                                                  ,p_commit        => lc_commit
                                                                  ,x_return_status => lc_return_status
                                                                  ,x_errorcode     => ln_errorcode
                                                                  ,x_msg_count     => ln_msg_count
                                                                  ,x_msg_data      => lc_msg_data
                                                                  ,p_category_rec  => lr_category_rec
                                                                  );     
                            IF (lc_return_status <> 'S') THEN
                                 x_error_code := 1;
                                 x_error_msg  := x_error_msg || 'Cannot enable the category code combinations using this value'; 
                            END IF;

                       END LOOP;
                       -- Division Cursor Ends
                       x_error_msg := x_error_msg || 'Category Code combination enabled successfully';
                   
                   ELSIF (p_hierarchy_level = 'GROUP') THEN
                          -- Opening Group Cursor to enable category code combinations
                          FOR get_ccc_grp_rec IN get_ccc_grp(lc_segment1 => p_division_number, lc_segment2 => lc_converted_value)
                          LOOP

                              lr_category_rec.CATEGORY_ID   := get_ccc_grp_rec.category_id;

                               -- Get details for this category id from the table
                               GET_CATEGORY_DETAILS (p_category_id => get_ccc_grp_rec.category_id
                                                    ,lr_mcb        => lr_mcb_typ
                                                    ,x_err_code    => ln_err_code
                                                    ,x_err_msg     => lc_err_msg
                                                    );

                              lr_category_rec.STRUCTURE_ID          := lr_mcb_typ.STRUCTURE_ID;
                              lr_category_rec.STRUCTURE_CODE        := lc_structure_code;
                              lr_category_rec.SUMMARY_FLAG          := lr_mcb_typ.SUMMARY_FLAG;
                              -- To Enable the code combination
                              lr_category_rec.ENABLED_FLAG          := 'Y'; 
                              lr_category_rec.START_DATE_ACTIVE     := SYSDATE;
                              lr_category_rec.DISABLE_DATE          := NULL;
                              lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                              lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                              lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                              lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                              lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                              lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                              lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                              lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                              lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                              lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                              lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                              lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                              lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                              lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                              lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                              lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                              lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                              lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                              lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                              lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                              lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                              lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                              lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                              lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                              lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                              lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                              lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                              lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                              lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                              lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                              lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                              lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                              lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                              lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                              lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                              lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                              lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                              lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                              lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                              lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                              INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                    ,p_init_msg_list => lc_init_msg_list
                                                                    ,p_commit        => lc_commit
                                                                    ,x_return_status => lc_return_status
                                                                    ,x_errorcode     => ln_errorcode
                                                                    ,x_msg_count     => ln_msg_count
                                                                    ,x_msg_data      => lc_msg_data
                                                                    ,p_category_rec  => lr_category_rec
                                                                    );     
                              IF (lc_return_status <> 'S') THEN
                                   x_error_code := 1;
                                   x_error_msg  := x_error_msg || 'Cannot enable the category code combinations using this value';
                              END IF;

                          END LOOP;
                           -- Group Cursor Ends
                           x_error_msg := x_error_msg || 'Category Code combination enabled successfully';
                   
                   ELSIF (p_hierarchy_level = 'DEPARTMENT') THEN
                          --Opening Department Cursor to enable category code combinations
                          FOR get_ccc_dept_rec IN get_ccc_dept (lc_segment2 => p_group_number, lc_segment3 => lc_converted_value)
                          LOOP

                              lr_category_rec.CATEGORY_ID   := get_ccc_dept_rec.category_id;

                               -- Get details for this category id from the table
                               GET_CATEGORY_DETAILS (p_category_id => get_ccc_dept_rec.category_id
                                                    ,lr_mcb        => lr_mcb_typ
                                                    ,x_err_code    => ln_err_code
                                                    ,x_err_msg     => lc_err_msg
                                                    );

                              lr_category_rec.STRUCTURE_ID          := lr_mcb_typ.STRUCTURE_ID;
                              lr_category_rec.STRUCTURE_CODE        := lc_structure_code;
                              lr_category_rec.SUMMARY_FLAG          := lr_mcb_typ.SUMMARY_FLAG;
                              -- To Enable the code combination
                              lr_category_rec.ENABLED_FLAG          := 'Y';
                              lr_category_rec.START_DATE_ACTIVE     := SYSDATE;
                              lr_category_rec.DISABLE_DATE          := NULL;
                              lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                              lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                              lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                              lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                              lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                              lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                              lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                              lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                              lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                              lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                              lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                              lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                              lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                              lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                              lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                              lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                              lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                              lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                              lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                              lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                              lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                              lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                              lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                              lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;

                              lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                              lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                              lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                              lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                              lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                              lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                              lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                              lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                              lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                              lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                              lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                              lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                              lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                              lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                              lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                              lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                              INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                    ,p_init_msg_list => lc_init_msg_list
                                                                    ,p_commit        => lc_commit
                                                                    ,x_return_status => lc_return_status
                                                                    ,x_errorcode     => ln_errorcode
                                                                    ,x_msg_count     => ln_msg_count
                                                                    ,x_msg_data      => lc_msg_data
                                                                    ,p_category_rec  => lr_category_rec
                                                                    );     
                              IF (lc_return_status <> 'S') THEN
                                   x_error_code := 1;
                                   x_error_msg  := x_error_msg || 'Cannot enable the category code combinations using this value';
                              END IF;

                          END LOOP;
                          -- Department Cursor Ends
                          x_error_msg := x_error_msg || 'Category Code combination enabled successfully';

                   ELSIF (p_hierarchy_level = 'CLASS') THEN
                          
                          -- Opening Class Cursor to enable category code combinations
                          FOR get_ccc_cla_rec IN get_ccc_cla (lc_segment3 => p_dept_number, lc_segment4 => lc_converted_value)
                          LOOP

                              lr_category_rec.CATEGORY_ID   := get_ccc_cla_rec.category_id;

                               -- Get details for this category id from the table
                               GET_CATEGORY_DETAILS (p_category_id => get_ccc_cla_rec.category_id
                                                    ,lr_mcb        => lr_mcb_typ
                                                    ,x_err_code    => ln_err_code
                                                    ,x_err_msg     => lc_err_msg
                                                    );

                              lr_category_rec.STRUCTURE_ID          := lr_mcb_typ.STRUCTURE_ID;
                              lr_category_rec.STRUCTURE_CODE        := lc_structure_code;
                              lr_category_rec.SUMMARY_FLAG          := lr_mcb_typ.SUMMARY_FLAG;
                              -- To Enable the code combination
                              lr_category_rec.ENABLED_FLAG          := 'Y';    
                              lr_category_rec.START_DATE_ACTIVE     := SYSDATE;
                              lr_category_rec.DISABLE_DATE          := NULL;
                              lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                              lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                              lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                              lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                              lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                              lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                              lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                              lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                              lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                              lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                              lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                              lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                              lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                              lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                              lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                              lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                              lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                              lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                              lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                              lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                              lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                              lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                              lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                              lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                              lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                              lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                              lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                              lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                              lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                              lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                              lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                              lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                              lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                              lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                              lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                              lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                              lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                              lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                              lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                              lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                              INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                    ,p_init_msg_list => lc_init_msg_list
                                                                    ,p_commit        => lc_commit
                                                                    ,x_return_status => lc_return_status
                                                                    ,x_errorcode     => ln_errorcode
                                                                    ,x_msg_count     => ln_msg_count
                                                                    ,x_msg_data      => lc_msg_data
                                                                    ,p_category_rec  => lr_category_rec
                                                                    );     
                              IF (lc_return_status <> 'S') THEN
                                   x_error_code := 1;
                                   x_error_msg  := x_error_msg || 'Cannot enable the category code combinations using this value';
                              END IF;
                          
                          END LOOP;
                          -- Class Cursor Ends
                          x_error_msg := x_error_msg || 'Category Code combination enabled successfully';

                   ELSIF (p_hierarchy_level = 'SUBCLASS') THEN
                          
                          -- Try to enable the category code combinations using this value
                          FOR get_ccc_sclas_rec IN get_ccc_sclas (lc_segment4 => p_class_number, lc_segment5 => lc_converted_value)
                          LOOP

                              lr_category_rec.CATEGORY_ID   := get_ccc_sclas_rec.category_id;

                               -- Get details for this category id from the table
                               GET_CATEGORY_DETAILS (p_category_id => get_ccc_sclas_rec.category_id
                                                    ,lr_mcb        => lr_mcb_typ
                                                    ,x_err_code    => ln_err_code
                                                    ,x_err_msg     => lc_err_msg
                                                    );

                              lr_category_rec.STRUCTURE_ID    := lr_mcb_typ.STRUCTURE_ID;
                              lr_category_rec.STRUCTURE_CODE  := lc_structure_code;
                              lr_category_rec.SUMMARY_FLAG    := lr_mcb_typ.SUMMARY_FLAG;
                              -- To Enable the code combination
                              lr_category_rec.ENABLED_FLAG    := 'Y';          
                              lr_category_rec.START_DATE_ACTIVE     := SYSDATE;
                              lr_category_rec.DISABLE_DATE          := NULL;
                              lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                              lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                              lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                              lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                              lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                              lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                              lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                              lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                              lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                              lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                              lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                              lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                              lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                              lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                              lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                              lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                              lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                              lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                              lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                              lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                              lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                              lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                              lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                              lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                              lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                              lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                              lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                              lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                              lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                              lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                              lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                              lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                              lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                              lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                              lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                              lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                              lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                              lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                              lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                              lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                              INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                    ,p_init_msg_list => lc_init_msg_list
                                                                    ,p_commit        => lc_commit
                                                                    ,x_return_status => lc_return_status
                                                                    ,x_errorcode     => ln_errorcode
                                                                    ,x_msg_count     => ln_msg_count
                                                                    ,x_msg_data      => lc_msg_data
                                                                    ,p_category_rec  => lr_category_rec
                                                                    );     
                              IF (lc_return_status <> 'S') THEN
                                   x_error_code := 1;
                                   x_error_msg  := x_error_msg || 'Cannot enable the category code combinations using this value,SUBCLASS';
                              END IF;
                          END LOOP;
                          -- Subclass Cursor Ends 
                          x_error_msg := x_error_msg || 'Category Code combination enabled successfully';

                   END IF;
                   -- get_ccc Cursors based on hierarchy level Ends

                -- Enable the value itself by calling FND_FLEX_LOADER_APIS.UP_VSET_VALUE 
                CALL_UP_VSET_VALUE (  p_flex_value_set_name          =>  lc_flex_value_set_name
                                     ,p_flex_value                   =>  ln_flex_value
                                     ,p_enabled_flag                 =>  'Y'
                                     ,p_summary_flag                 =>  'N'
                                     ,p_start_date_active            =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                     ,p_end_date_active              =>  NULL
                                     ,p_value_category               =>  lc_value_category
                                     ,p_description                  =>  lc_description
                                     ,x_err_code                     =>  ln_err_code
                                     ,x_err_msg                      =>  lc_err_msg
                                   );

                IF (ln_err_code = -1) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                END IF;
                
                -- If control reaches here everything is fine.
                x_error_code := 0;

            END IF;
            -- IF lc_exist_enabled ='N' Ends, value exists but is diabled

            -- If the "value does not exsist", Call the Standard API  FND_FLEX_LOADER_APIS.UP_VSET_VALUE 
            -- to "populate values set values" 
            IF (p_hierarchy_level = 'DIVISION') THEN

                 lc_value_category      := lc_flex_value_set_name;

                -- Adding Incoming Value to DIVISION Value set
                CALL_UP_VSET_VALUE ( p_flex_value_set_name          =>  lc_flex_value_set_name
                                    ,p_flex_value                   =>  ln_flex_value
                                    ,p_enabled_flag                 =>  'Y'
                                    ,p_summary_flag                 =>  'N'
                                    ,p_start_date_active            =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                    ,p_end_date_active              =>  NULL 
                                    ,p_last_update_date             =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                    ,p_flex_value_meaning           =>  ln_flex_value 
                                    ,p_description                  =>  lc_description
                                    ,x_err_code                     =>  ln_err_code
                                    ,x_err_msg                      =>  lc_err_msg
                                   );

                IF (ln_err_code = -1) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                END IF;

                COMMIT;
                -- If control reaches here everything is fine
                x_error_code := 0;
                x_error_msg  := 'Value Set Value loaded Successfully';

            -- Adding Incoming Value to GROUP Value Set
            ELSIF (p_hierarchy_level = 'GROUP') THEN

                 lc_value_category      := lc_flex_value_set_name;
                 lc_attribute1          := p_division_number;

                CALL_UP_VSET_VALUE ( p_flex_value_set_name          =>  lc_flex_value_set_name
                                    ,p_flex_value                   =>  ln_flex_value
                                    ,p_enabled_flag                 =>  'Y'
                                    ,p_summary_flag                 =>  'N'
                                    ,p_start_date_active            =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                    ,p_end_date_active              =>  NULL
                                    ,p_value_category               =>  lc_value_category
                                    ,p_attribute1                   =>  p_division_number
                                    ,p_description                  =>  lc_description
                                    ,x_err_code                     =>  ln_err_code
                                    ,x_err_msg                      =>  lc_err_msg
                                   );

                IF (ln_err_code = -1) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                END IF;

                COMMIT;
                -- If control reaches here everything is fine
                x_error_code := 0;
                x_error_msg  := 'Value Set Value loaded Successfully';

            --Adding Incoming Value to DEPT value Set
            ELSIF (p_hierarchy_level = 'DEPARTMENT') THEN

                 lc_value_category      := lc_flex_value_set_name;
                 lc_attribute1          := p_group_number;

                CALL_UP_VSET_VALUE ( p_flex_value_set_name          =>  lc_flex_value_set_name
                                    ,p_flex_value                   =>  ln_flex_value
                                    ,p_last_update_date             =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                    ,p_enabled_flag                 =>  'Y'
                                    ,p_summary_flag                 =>  'N'
                                    ,p_start_date_active            =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                    ,p_end_date_active              =>  NULL
                                    ,p_value_category               =>  lc_value_category
                                    ,p_attribute1                   =>  lc_attribute1
                                    ,p_attribute3                   =>  p_dept_planningind
                                    ,p_attribute4                   =>  p_dept_forecastingind
                                    ,p_attribute5                   =>  p_dept_noncodeind
                                    ,p_attribute6                   =>  p_dept_ppp_ind
                                    ,p_attribute9                   =>  p_dept_aipfilterind
                                    ,p_flex_value_meaning           =>  ln_flex_value                 
                                    ,p_description                  =>  lc_description
                                    ,x_err_code                     =>  ln_err_code
                                    ,x_err_msg                      =>  lc_err_msg
                                   );

                IF (ln_err_code = -1) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                END IF;

                COMMIT;
                -- If control reaches here everything is fine.
                x_error_code := 0;
                x_error_msg  := 'Value Set Value loaded Successfully';

            -- Adding Incoming Value to CLASS Value Set
            ELSIF (p_hierarchy_level = 'CLASS') THEN

                 lc_value_category      := lc_flex_value_set_name;
                 lc_attribute1          := p_dept_number;

                CALL_UP_VSET_VALUE ( p_flex_value_set_name          =>  lc_flex_value_set_name
                                    ,p_flex_value                   =>  ln_flex_value
                                    ,p_enabled_flag                 =>  'Y'
                                    ,p_summary_flag                 =>  'N'
                                    ,p_start_date_active            =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                    ,p_end_date_active              =>  NULL
                                    ,p_last_update_date             =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                    ,p_value_category               =>  lc_value_category
                                    ,p_attribute1                   =>  lc_attribute1
                                    ,p_attribute3                   =>  to_char(p_class_nbrdaysamd)
                                    ,p_attribute4                   =>  p_class_fifthmrkdwnprocsscd
                                    ,p_attribute5                   =>  p_class_prczcostflg
                                    ,p_attribute6                   =>  p_class_prczpriceflag
                                    ,p_attribute7                   =>  p_class_priczlistflag
                                    ,p_attribute8                   =>  p_class_furnitureflag
                                    ,p_attribute9                   =>  p_class_aipfilterind
                                    ,p_flex_value_meaning           =>  ln_flex_value                 
                                    ,p_description                  =>  lc_description
                                    ,x_err_code                     =>  ln_err_code
                                    ,x_err_msg                      =>  lc_err_msg
                                  );

                IF (ln_err_code = -1) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                END IF;

                COMMIT;
                -- If control reaches here everything is fine.
                x_error_code := 0;
                x_error_msg  := 'Value Set Value loaded Successfully';

            -- Adding Incoming value to SUBCLASS value Set
            ELSIF (p_hierarchy_level = 'SUBCLASS') THEN

                 lc_value_category      := lc_flex_value_set_name;

                 -- Get Class value set id
                 GET_VS_ID (p_vs_name  => lc_class_vs_name
                           ,x_vs_id    => ln_class_value_set_id
                           ,x_err_code => ln_err_code
                           ,x_err_msg  => lc_err_msg
                           );

                 IF (ln_err_code <> 0 OR ln_err_code IS NULL) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

                 -- Get Department Number for the 'Class Number' IN Parameter
                 GET_PARENT_VALUE(p_vs_id      => ln_class_value_set_id
                                 ,p_vs_value   => p_class_number
                                 ,x_parent_num => lc_dept_val
                                 ,x_err_code   => ln_err_code
                                 ,x_err_msg    => lc_err_msg
                                 );

                 IF (ln_err_code <> 0 OR ln_err_code IS NULL) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

                -- Adding Value to SUBCLASS Value Set
                CALL_UP_VSET_VALUE( p_flex_value_set_name          =>  lc_flex_value_set_name
                                   ,p_flex_value                   =>  ln_flex_value
                                   ,p_last_update_date             =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                   ,p_enabled_flag                 =>  'Y'
                                   ,p_summary_flag                 =>  'N'
                                   ,p_start_date_active            =>  TO_CHAR(SYSDATE,'YYYY/MM/DD')
                                   ,p_end_date_active              =>  NULL
                                   ,p_value_category               =>  lc_value_category
                                   ,p_attribute1                   =>  p_class_number
                                   ,p_attribute2                   =>  lc_dept_val
                                   ,p_attribute6                   =>  p_subclass_ppp_ind
                                   ,p_attribute8                   =>  p_subclass_globalcontentind
                                   ,p_attribute9                   =>  p_subclass_aipfilterind
                                   ,p_attribute10                  =>  p_subclass_defaulttaxcat
                                   ,p_description                  =>  lc_description
                                   ,x_err_code                     =>  ln_err_code
                                   ,x_err_msg                      =>  lc_err_msg
                                  );

                IF (ln_err_code = -1) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                END IF;

                COMMIT;

                 -- Category code values also need to be populated.when p_hierarchy_level = 'SUBCLASS'
                 --by Invoking the INV_ITEM_CATEGORY_PUB.CREATE_CATEGORY API
                 lr_category_rec.STRUCTURE_ID       := ln_structure_id;
                 lr_category_rec.STRUCTURE_CODE     := lc_structure_code;
                 lr_category_rec.SEGMENT4           := to_char(p_class_number);
                 lr_category_rec.SEGMENT5           := lc_converted_value;

                 -- Get the Value Set Id for Class Value Set 
                 GET_VS_ID (p_vs_name  => lc_class_vs_name
                           ,x_vs_id    => ln_flex_value_set_id_class
                           ,x_err_code => ln_err_code
                           ,x_err_msg  => lc_err_msg
                           );

                 IF (ln_err_code <> 0 OR ln_err_code IS NULL) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

                 -- Get Dept number to which this class belongs
                 GET_PARENT_VALUE(p_vs_id    => ln_class_value_set_id
                                 ,p_vs_value => p_class_number
                                 ,x_parent_num => lc_dept_num
                                 ,x_err_code => ln_err_code
                                 ,x_err_msg  => lc_err_msg
                                );

                 IF (ln_err_code <> 0 OR ln_err_code IS NULL) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

                 -- Get the Value Set Id for Dept Value Set
                 GET_VS_ID (p_vs_name  => lc_dept_vs_name
                           ,x_vs_id    => ln_flex_value_set_id_dept
                           ,x_err_code => ln_err_code 
                           ,x_err_msg  => lc_err_msg 
                            );

                 IF (ln_err_code <> 0 OR ln_err_code IS NULL) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

                 -- Get group number to which this dept belongs
                 GET_PARENT_VALUE(p_vs_id      => ln_flex_value_set_id_dept
                                 ,p_vs_value   => lc_dept_num
                                 ,x_parent_num => lc_grp_num
                                 ,x_err_code   => ln_err_code
                                 ,x_err_msg    => lc_err_msg
                                );

                 IF (ln_err_code <> 0 OR ln_err_code IS NULL) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

                 -- Get the Value Set Id for Group Value Set
                 GET_VS_ID (p_vs_name  => lc_group_vs_name
                           ,x_vs_id    => ln_flex_value_set_id_grp
                           ,x_err_code => ln_err_code  
                           ,x_err_msg  => lc_err_msg 
                           );

                 IF (ln_err_code <> 0 OR ln_err_code IS NULL) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

                 --Get Division Number to which this Group belongs
                 GET_PARENT_VALUE(p_vs_id    => ln_flex_value_set_id_grp
                                 ,p_vs_value => lc_grp_num
                                 ,x_parent_num => lc_div_num
                                 ,x_err_code => ln_err_code
                                 ,x_err_msg  => lc_err_msg
                                );

                 IF (ln_err_code <> 0 OR ln_err_code IS NULL) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

                 lr_category_rec.SEGMENT1           := lc_div_num;
                 lr_category_rec.SEGMENT2           := lc_grp_num;
                 lr_category_rec.SEGMENT3           := lc_dept_num;
                 lr_category_rec.SUMMARY_FLAG       :='N';
                 lr_category_rec.ENABLED_FLAG       :='Y';
                 lr_category_rec.START_DATE_ACTIVE  := SYSDATE;
        
                 -- Create a new category with this Subclass
                 INV_ITEM_CATEGORY_PUB.Create_Category ( p_api_version     => ln_api_version_cc
                                                        ,x_return_status   => lc_return_status
                                                        ,x_errorcode       => ln_errorcode
                                                        ,x_msg_count       => ln_msg_count
                                                        ,x_msg_data        => lc_msg_data
                                                        ,p_category_rec    => lr_category_rec
                                                        ,x_category_id     => ln_category_id
                                                        );
                                           
                 IF (lc_return_status <> 'S') THEN
                   x_error_code :=1;
                   x_error_msg  := x_error_msg || 'Unable to create category code combinations when hierarchy level=SUBCLASS';
                 END IF;

                 -- Populating Values for PO Category code creation
                 lr_category_rec.STRUCTURE_ID       := ln_structure_id_po;
                 lr_category_rec.STRUCTURE_CODE     := lc_structure_code_po;
                 lr_category_rec.SEGMENT1           := 'NA';
                 lr_category_rec.SEGMENT2           := 'Trade';
                 lr_category_rec.SEGMENT3           := lc_dept_num;
                 lr_category_rec.SEGMENT4           := to_char(p_class_number);
                 lr_category_rec.SEGMENT5           := lc_converted_value;
                 lr_category_rec.SUMMARY_FLAG       :='N';
                 lr_category_rec.ENABLED_FLAG       :='Y';
                 lr_category_rec.START_DATE_ACTIVE  := SYSDATE;

                 -- Create a new PO category with this Subclass
                 INV_ITEM_CATEGORY_PUB.Create_Category ( p_api_version     => ln_api_version_cc
                                                        ,x_return_status   => lc_return_status
                                                        ,x_errorcode       => ln_errorcode
                                                        ,x_msg_count       => ln_msg_count
                                                        ,x_msg_data        => lc_msg_data
                                                        ,p_category_rec    => lr_category_rec
                                                        ,x_category_id     => ln_category_id
                                                        );
                                           
                 IF (lc_return_status <> 'S') THEN
                   x_error_code :=1;
                   x_error_msg  := x_error_msg || 'Unable to create PO category code combinations when hierarchy level=SUBCLASS';
                 END IF;

                -- If control reaches here everything is fine.                 
                x_error_code := 0;                 
                x_error_msg  := 'Value Set Value loaded Successfully';
                x_error_msg  := x_error_msg || 'Item Category Code values loaded successfully';
                x_error_msg  := x_error_msg || 'PO Category Codes loaded successfully';
            END IF;
            -- when "value does not exist" Ends
            -- ending "populating values set values"

ELSIF (p_action = 'MODIFY') THEN


            OPEN  get_enabled_flag (ln_flex_val_set_id => ln_flex_value_set_id,lc_value => lc_converted_value );
            FETCH get_enabled_flag INTO lc_enabled_flag ;
            CLOSE get_enabled_flag;

        -- if the value does not exist ERROR out
        IF (lc_enabled_flag  IS NULL) THEN
           x_error_code := 1;
           x_error_msg  := x_error_msg || 'Value set values does not exists in  EBS to perform modification';
           RAISE le_end_procedure;
        END IF;

                   ln_flex_value          := lc_converted_value;

        -- Get values for this record 
        BEGIN
        
             SELECT *
             INTO   lr_ffv_typ             
             FROM   fnd_flex_values
             WHERE  flex_value_set_id = ln_flex_value_set_id
             AND    flex_value = ln_flex_value;
        
        EXCEPTION
        WHEN others THEN
        x_error_code := -1;
        x_error_msg  := x_error_msg || SQLERRM;
        END;

        -- modify the Description; the number values will not be modified.
        -- Rest of the values are copied back as such

        -- Modifying value description
        CALL_UP_VSET_VALUE (  p_flex_value_set_name          =>  lc_flex_value_set_name
                             ,p_flex_value                   =>  ln_flex_value
                             ,p_enabled_flag                 =>  lr_ffv_typ.enabled_flag
                             ,p_summary_flag                 =>  lr_ffv_typ.summary_flag
                             ,p_start_date_active            =>  lr_ffv_typ.start_date_active
                             ,p_end_date_active              =>  lr_ffv_typ.end_date_active
                             ,p_parent_flex_value_high       =>  lr_ffv_typ.parent_flex_value_high
                             ,p_hierarchy_level              =>  lr_ffv_typ.hierarchy_level
                             ,p_compiled_value_attributes    =>  lr_ffv_typ.compiled_value_attributes
                             ,p_value_category               =>  lr_ffv_typ.value_category
                             ,p_attribute1                   =>  lr_ffv_typ.attribute1
                             ,p_attribute2                   =>  lr_ffv_typ.attribute2
                             ,p_attribute3                   =>  lr_ffv_typ.attribute3
                             ,p_attribute4                   =>  lr_ffv_typ.attribute4
                             ,p_attribute5                   =>  lr_ffv_typ.attribute5
                             ,p_attribute6                   =>  lr_ffv_typ.attribute6
                             ,p_attribute7                   =>  lr_ffv_typ.attribute7
                             ,p_attribute8                   =>  lr_ffv_typ.attribute8
                             ,p_attribute9                   =>  lr_ffv_typ.attribute9
                             ,p_attribute10                  =>  lr_ffv_typ.attribute10
                             ,p_attribute11                  =>  lr_ffv_typ.attribute11
                             ,p_attribute12                  =>  lr_ffv_typ.attribute12
                             ,p_attribute13                  =>  lr_ffv_typ.attribute13
                             ,p_attribute14                  =>  lr_ffv_typ.attribute14
                             ,p_attribute15                  =>  lr_ffv_typ.attribute15
                             ,p_attribute16                  =>  lr_ffv_typ.attribute16
                             ,p_attribute17                  =>  lr_ffv_typ.attribute17
                             ,p_attribute18                  =>  lr_ffv_typ.attribute18
                             ,p_attribute19                  =>  lr_ffv_typ.attribute19
                             ,p_attribute20                  =>  lr_ffv_typ.attribute20
                             ,p_attribute21                  =>  lr_ffv_typ.attribute21
                             ,p_attribute22                  =>  lr_ffv_typ.attribute22
                             ,p_attribute23                  =>  lr_ffv_typ.attribute23
                             ,p_attribute24                  =>  lr_ffv_typ.attribute24
                             ,p_attribute25                  =>  lr_ffv_typ.attribute25
                             ,p_attribute26                  =>  lr_ffv_typ.attribute26
                             ,p_attribute27                  =>  lr_ffv_typ.attribute27
                             ,p_attribute28                  =>  lr_ffv_typ.attribute28
                             ,p_attribute29                  =>  lr_ffv_typ.attribute29
                             ,p_attribute30                  =>  lr_ffv_typ.attribute30
                             ,p_attribute31                  =>  lr_ffv_typ.attribute31
                             ,p_attribute32                  =>  lr_ffv_typ.attribute32
                             ,p_attribute33                  =>  lr_ffv_typ.attribute33
                             ,p_attribute34                  =>  lr_ffv_typ.attribute34
                             ,p_attribute35                  =>  lr_ffv_typ.attribute35
                             ,p_attribute36                  =>  lr_ffv_typ.attribute36
                             ,p_attribute37                  =>  lr_ffv_typ.attribute37
                             ,p_attribute38                  =>  lr_ffv_typ.attribute38
                             ,p_attribute39                  =>  lr_ffv_typ.attribute39
                             ,p_attribute40                  =>  lr_ffv_typ.attribute40
                             ,p_attribute41                  =>  lr_ffv_typ.attribute41
                             ,p_attribute42                  =>  lr_ffv_typ.attribute42
                             ,p_attribute43                  =>  lr_ffv_typ.attribute43
                             ,p_attribute44                  =>  lr_ffv_typ.attribute44
                             ,p_attribute45                  =>  lr_ffv_typ.attribute45
                             ,p_attribute46                  =>  lr_ffv_typ.attribute46
                             ,p_attribute47                  =>  lr_ffv_typ.attribute47
                             ,p_attribute48                  =>  lr_ffv_typ.attribute48
                             ,p_attribute49                  =>  lr_ffv_typ.attribute49
                             ,p_attribute50                  =>  lr_ffv_typ.attribute50
                             ,p_attribute_sort_order         =>  lr_ffv_typ.attribute_sort_order
                             ,p_description                  =>  lc_description
                             ,x_err_code                     =>  ln_err_code
                             ,x_err_msg                      =>  lc_err_msg
                           );

                IF (ln_err_code = -1) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                END IF;

                COMMIT;

                -- If control reaches here everything is fine.                                           
                x_error_code := 0;                                   

ELSIF (p_action = 'DELETE') THEN
        --check if this value is being used in category code combinations.
        -- structure_id=101 means id_flex_structure_code = 'ITEM_CATEGORIES'

                   -- Opening Cursors based on hierarchy_level
                   IF (p_hierarchy_level = 'DIVISION') THEN
                       FOR get_ccc_div_rec IN get_ccc_div (lc_segment1 => lc_converted_value)
                       LOOP                
                            -- If used in category code combinations then call INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY 
                            -- to disable the category code combinations using this value.  


                            lr_category_rec.CATEGORY_ID   := get_ccc_div_rec.category_id;

                            -- Get details for this category id from the table
                            GET_CATEGORY_DETAILS (p_category_id => get_ccc_div_rec.category_id
                                                 ,lr_mcb        => lr_mcb_typ
                                                 ,x_err_code    => ln_err_code
                                                 ,x_err_msg     => lc_err_msg
                                                 );

                            lr_category_rec.STRUCTURE_ID    := lr_mcb_typ.STRUCTURE_ID;
                            lr_category_rec.STRUCTURE_CODE  := lc_structure_code;
                            lr_category_rec.SUMMARY_FLAG    := lr_mcb_typ.SUMMARY_FLAG;
                            -- To Disable the code combination
                            lr_category_rec.ENABLED_FLAG          := 'N';                     
                            lr_category_rec.START_DATE_ACTIVE     := lr_mcb_typ.START_DATE_ACTIVE;
                            lr_category_rec.DISABLE_DATE          := SYSDATE;
                            lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                            lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                            lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                            lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                            lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                            lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                            lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                            lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                            lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                            lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                            lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                            lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                            lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                            lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                            lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                            lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                            lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                            lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                            lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                            lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                            lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                            lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                            lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                            lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                            lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                            lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                            lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                            lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                            lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                            lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                            lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                            lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                            lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                            lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                            lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                            lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                            lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                            lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                            lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                            lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                            -- Disabling the category code combination for DIVISION value set value
                            INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                  ,p_init_msg_list => lc_init_msg_list
                                                                  ,p_commit        => lc_commit
                                                                  ,x_return_status => lc_return_status
                                                                  ,x_errorcode     => ln_errorcode
                                                                  ,x_msg_count     => ln_msg_count
                                                                  ,x_msg_data      => lc_msg_data
                                                                  ,p_category_rec  => lr_category_rec
                                                                  );     
                            IF (lc_return_status <> 'S') THEN
                                 x_error_code := 1;
                                 x_error_msg  := x_error_msg || 'Cannot disable the category code combinations using this value';
                            END IF;

                       END LOOP;
                       -- Division Cursor Ends
                       x_error_msg := x_error_msg || 'Category Code combination disabled successfully';

                   --Checking if category code exist for this Value in GROUP Value Set
                   ELSIF (p_hierarchy_level = 'GROUP') THEN
                          -- Open Group Cursor
                          FOR get_ccc_grp_rec IN get_ccc_grp(lc_segment1 => p_division_number, lc_segment2 => lc_converted_value)
                          LOOP


                              lr_category_rec.CATEGORY_ID   := get_ccc_grp_rec.category_id;

                                -- Get details for this category id from the table
                                BEGIN

                                        SELECT *
                                        INTO   lr_mcb_typ
                                        FROM   mtl_categories_b
                                        WHERE  category_id = get_ccc_grp_rec.category_id;

                                EXCEPTION
                                        WHEN OTHERS THEN
                                        fnd_file.put_line (fnd_file.log,'Others Exception then ');
                                        x_error_code := -1;
                                        x_error_msg  := x_error_msg || SQLERRM;
                                END;

                              lr_category_rec.STRUCTURE_ID    := lr_mcb_typ.STRUCTURE_ID;
                              lr_category_rec.STRUCTURE_CODE  := lc_structure_code;
                              lr_category_rec.SUMMARY_FLAG    := lr_mcb_typ.SUMMARY_FLAG;
                              -- To Disable the code combination
                              lr_category_rec.ENABLED_FLAG    := 'N';                    
                              lr_category_rec.START_DATE_ACTIVE     := lr_mcb_typ.START_DATE_ACTIVE;
                              lr_category_rec.DISABLE_DATE          := SYSDATE;
                              lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                              lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                              lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                              lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                              lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                              lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                              lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                              lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                              lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                              lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                              lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                              lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                              lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                              lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                              lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                              lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                              lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                              lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                              lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                              lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                              lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                              lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                              lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                              lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                              lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                              lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                              lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                              lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                              lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                              lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                              lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                              lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                              lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                              lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                              lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                              lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                              lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                              lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                              lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                              lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                              -- Disabling the category code combination for GROUP value set value
                              INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                    ,p_init_msg_list => lc_init_msg_list
                                                                    ,p_commit        => lc_commit
                                                                    ,x_return_status => lc_return_status
                                                                    ,x_errorcode     => ln_errorcode
                                                                    ,x_msg_count     => ln_msg_count
                                                                    ,x_msg_data      => lc_msg_data
                                                                    ,p_category_rec  => lr_category_rec
                                                                    );     
                              IF (lc_return_status <> 'S') THEN
                                   x_error_code := 1;
                                   x_error_msg  := x_error_msg || 'Cannot disable the category code combinations using this value';
                              END IF;

                          END LOOP;
                           -- Group Cursor Ends
                           x_error_msg := x_error_msg || 'Category Code combination disabled successfully';
                   
                   ELSIF (p_hierarchy_level = 'DEPARTMENT') THEN
                          --Open Department Cursor
                          FOR get_ccc_dept_rec IN get_ccc_dept (lc_segment2 => p_group_number, lc_segment3 => lc_converted_value)
                          LOOP

                              lr_category_rec.CATEGORY_ID   := get_ccc_dept_rec.category_id;

                              -- Get details for this category id from the table
                              GET_CATEGORY_DETAILS (p_category_id => get_ccc_dept_rec.category_id
                                                   ,lr_mcb        => lr_mcb_typ
                                                   ,x_err_code    => ln_err_code
                                                   ,x_err_msg     => lc_err_msg
                                                   );

                              lr_category_rec.STRUCTURE_ID          := lr_mcb_typ.STRUCTURE_ID;
                              lr_category_rec.STRUCTURE_CODE        := lc_structure_code;
                              lr_category_rec.SUMMARY_FLAG          := lr_mcb_typ.SUMMARY_FLAG;
                              -- To Disable the code combination
                              lr_category_rec.ENABLED_FLAG          := 'N';                    
                              lr_category_rec.START_DATE_ACTIVE     := lr_mcb_typ.START_DATE_ACTIVE;
                              lr_category_rec.DISABLE_DATE          := SYSDATE;
                              lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                              lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                              lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                              lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                              lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                              lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                              lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                              lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                              lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                              lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                              lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                              lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                              lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                              lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                              lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                              lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                              lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                              lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                              lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                              lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                              lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                              lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                              lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                              lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                              lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                              lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                              lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                              lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                              lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                              lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                              lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                              lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                              lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                              lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                              lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                              lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                              lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                              lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                              lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                              lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                              -- Disabling the category code combination for DEPT value set value
                              INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                    ,p_init_msg_list => lc_init_msg_list
                                                                    ,p_commit        => lc_commit
                                                                    ,x_return_status => lc_return_status
                                                                    ,x_errorcode     => ln_errorcode
                                                                    ,x_msg_count     => ln_msg_count
                                                                    ,x_msg_data      => lc_msg_data
                                                                    ,p_category_rec  => lr_category_rec
                                                                    );
                              IF (lc_return_status <> 'S') THEN
                                   x_error_code := 1;
                                   x_error_msg  := x_error_msg || 'Cannot disable the category code combinations using this value';
                              END IF;

                          END LOOP;
                          -- Department Cursor Ends
                          x_error_msg := x_error_msg || 'Category Code combination disabled successfully';

                   ELSIF (p_hierarchy_level = 'CLASS') THEN

                          -- Opening Class Cursor to disable category code combinations
                          FOR get_ccc_cla_rec IN get_ccc_cla (lc_segment3 => p_dept_number, lc_segment4 => lc_converted_value)
                          LOOP

                              lr_category_rec.CATEGORY_ID   := get_ccc_cla_rec.category_id;

                              -- Get details for this category id from the table
                              GET_CATEGORY_DETAILS (p_category_id => get_ccc_cla_rec.category_id
                                                   ,lr_mcb        => lr_mcb_typ
                                                   ,x_err_code    => ln_err_code
                                                   ,x_err_msg     => lc_err_msg
                                                   );

                              lr_category_rec.STRUCTURE_ID          := lr_mcb_typ.STRUCTURE_ID;
                              lr_category_rec.STRUCTURE_CODE        := lc_structure_code;
                              lr_category_rec.SUMMARY_FLAG          := lr_mcb_typ.SUMMARY_FLAG;
                              -- To Disable the code combination
                              lr_category_rec.ENABLED_FLAG          := 'N';                    
                              lr_category_rec.START_DATE_ACTIVE     := lr_mcb_typ.START_DATE_ACTIVE;
                              lr_category_rec.DISABLE_DATE          := SYSDATE;
                              lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                              lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                              lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                              lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                              lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                              lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                              lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                              lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                              lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                              lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                              lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                              lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                              lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                              lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                              lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                              lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                              lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                              lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                              lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                              lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                              lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                              lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                              lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                              lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                              lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                              lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                              lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                              lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                              lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                              lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                              lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                              lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                              lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                              lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                              lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                              lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                              lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                              lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                              lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                              lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                              -- Disabling the category code combination for CLASS value set value
                              INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                    ,p_init_msg_list => lc_init_msg_list
                                                                    ,p_commit        => lc_commit
                                                                    ,x_return_status => lc_return_status
                                                                    ,x_errorcode     => ln_errorcode
                                                                    ,x_msg_count     => ln_msg_count
                                                                    ,x_msg_data      => lc_msg_data
                                                                    ,p_category_rec  => lr_category_rec
                                                                    );     
                              IF (lc_return_status <> 'S') THEN
                                   x_error_code := 1;
                                   x_error_msg  := x_error_msg || chr(10) || 'Cannot disable the category code combinations using this value';
                              END IF;
                          END LOOP;
                          -- Class cursor Ends
                          x_error_msg := x_error_msg || chr(10) || 'Category Code combination disabled successfully';

                   ELSIF (p_hierarchy_level = 'SUBCLASS') THEN

                          -- Disabling category code combinations using this SUBCLASS value
                          FOR get_ccc_sclas_rec IN get_ccc_sclas (lc_segment4 => p_class_number, lc_segment5 => lc_converted_value)
                          LOOP

                              lr_category_rec.CATEGORY_ID   := get_ccc_sclas_rec.category_id;

                              -- Get details for this category id from the table
                              GET_CATEGORY_DETAILS (p_category_id => get_ccc_sclas_rec.category_id
                                                   ,lr_mcb        => lr_mcb_typ
                                                   ,x_err_code    => ln_err_code
                                                   ,x_err_msg     => lc_err_msg
                                                   );

                              lr_category_rec.STRUCTURE_ID          := lr_mcb_typ.STRUCTURE_ID;
                              lr_category_rec.STRUCTURE_CODE        := lc_structure_code;
                              lr_category_rec.SUMMARY_FLAG          := lr_mcb_typ.SUMMARY_FLAG;
                              -- To Disable the code combination
                              lr_category_rec.ENABLED_FLAG          := 'N';                    
                              lr_category_rec.START_DATE_ACTIVE     := lr_mcb_typ.START_DATE_ACTIVE;
                              lr_category_rec.DISABLE_DATE          := SYSDATE;
                              lr_category_rec.END_DATE_ACTIVE       := lr_mcb_typ.END_DATE_ACTIVE;
                              lr_category_rec.DESCRIPTION           := lr_mcb_typ.DESCRIPTION;
                              lr_category_rec.WEB_STATUS            := lr_mcb_typ.WEB_STATUS;
                              lr_category_rec.SUPPLIER_ENABLED_FLAG := lr_mcb_typ.SUPPLIER_ENABLED_FLAG;
                              lr_category_rec.SEGMENT1              := lr_mcb_typ.SEGMENT1;
                              lr_category_rec.SEGMENT2              := lr_mcb_typ.SEGMENT2;
                              lr_category_rec.SEGMENT3              := lr_mcb_typ.SEGMENT3;
                              lr_category_rec.SEGMENT4              := lr_mcb_typ.SEGMENT4;
                              lr_category_rec.SEGMENT5              := lr_mcb_typ.SEGMENT5;
                              lr_category_rec.SEGMENT6              := lr_mcb_typ.SEGMENT6;
                              lr_category_rec.SEGMENT7              := lr_mcb_typ.SEGMENT7;
                              lr_category_rec.SEGMENT8              := lr_mcb_typ.SEGMENT8;
                              lr_category_rec.SEGMENT9              := lr_mcb_typ.SEGMENT9;
                              lr_category_rec.SEGMENT10             := lr_mcb_typ.SEGMENT10;
                              lr_category_rec.SEGMENT11             := lr_mcb_typ.SEGMENT11;
                              lr_category_rec.SEGMENT12             := lr_mcb_typ.SEGMENT12;
                              lr_category_rec.SEGMENT13             := lr_mcb_typ.SEGMENT13;
                              lr_category_rec.SEGMENT14             := lr_mcb_typ.SEGMENT14;
                              lr_category_rec.SEGMENT15             := lr_mcb_typ.SEGMENT15;
                              lr_category_rec.SEGMENT16             := lr_mcb_typ.SEGMENT16;
                              lr_category_rec.SEGMENT17             := lr_mcb_typ.SEGMENT17;
                              lr_category_rec.SEGMENT18             := lr_mcb_typ.SEGMENT18;
                              lr_category_rec.SEGMENT19             := lr_mcb_typ.SEGMENT19;
                              lr_category_rec.SEGMENT20             := lr_mcb_typ.SEGMENT20;
                              lr_category_rec.ATTRIBUTE_CATEGORY    := lr_mcb_typ.ATTRIBUTE_CATEGORY;
                              lr_category_rec.ATTRIBUTE1            := lr_mcb_typ.ATTRIBUTE1;
                              lr_category_rec.ATTRIBUTE2            := lr_mcb_typ.ATTRIBUTE2;
                              lr_category_rec.ATTRIBUTE3            := lr_mcb_typ.ATTRIBUTE3;
                              lr_category_rec.ATTRIBUTE4            := lr_mcb_typ.ATTRIBUTE4;
                              lr_category_rec.ATTRIBUTE5            := lr_mcb_typ.ATTRIBUTE5;
                              lr_category_rec.ATTRIBUTE6            := lr_mcb_typ.ATTRIBUTE6;
                              lr_category_rec.ATTRIBUTE7            := lr_mcb_typ.ATTRIBUTE7;
                              lr_category_rec.ATTRIBUTE8            := lr_mcb_typ.ATTRIBUTE8;
                              lr_category_rec.ATTRIBUTE9            := lr_mcb_typ.ATTRIBUTE9;
                              lr_category_rec.ATTRIBUTE10           := lr_mcb_typ.ATTRIBUTE10;
                              lr_category_rec.ATTRIBUTE11           := lr_mcb_typ.ATTRIBUTE11;
                              lr_category_rec.ATTRIBUTE12           := lr_mcb_typ.ATTRIBUTE12;
                              lr_category_rec.ATTRIBUTE13           := lr_mcb_typ.ATTRIBUTE13;
                              lr_category_rec.ATTRIBUTE14           := lr_mcb_typ.ATTRIBUTE14;
                              lr_category_rec.ATTRIBUTE15           := lr_mcb_typ.ATTRIBUTE15;

                              -- Disabling the category code combination for SUBCLASS value set value
                              INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY (p_api_version   => ln_api_version_uc
                                                                    ,p_init_msg_list => lc_init_msg_list
                                                                    ,p_commit        => lc_commit
                                                                    ,x_return_status => lc_return_status
                                                                    ,x_errorcode     => ln_errorcode
                                                                    ,x_msg_count     => ln_msg_count
                                                                    ,x_msg_data      => lc_msg_data
                                                                    ,p_category_rec  => lr_category_rec
                                                                    );     
                              IF (lc_return_status <> 'S') THEN
                                   x_error_code := 1;
                                   x_error_msg  := x_error_msg || chr(10) || 'Cannot disable the category code combinations using this value';
                              END IF;
                          END LOOP;
                          -- Subclass Cursor Ends 
                          x_error_msg := x_error_msg || chr(10) || 'Category Code combination disabled successfully';

                   END IF;
                   -- closing IF for opening cursors based on hierarchy level

GET_VS_ID (p_vs_name  => lc_div_vs_name
          ,x_vs_id    => ln_flex_value_set_id_div
          ,x_err_code => ln_err_code  
          ,x_err_msg  => lc_err_msg 
          );

                 IF (ln_err_code <> 0) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

GET_VS_ID (p_vs_name  => lc_group_vs_name
          ,x_vs_id    => ln_flex_value_set_id_grp
          ,x_err_code => ln_err_code  
          ,x_err_msg  => lc_err_msg 
          );

                 IF (ln_err_code <> 0) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

GET_VS_ID (p_vs_name  => lc_dept_vs_name
          ,x_vs_id    => ln_flex_value_set_id_dept
          ,x_err_code => ln_err_code  
          ,x_err_msg  => lc_err_msg 
          );

                 IF (ln_err_code <> 0) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

GET_VS_ID (p_vs_name  => lc_class_vs_name 
          ,x_vs_id    => ln_class_value_set_id
          ,x_err_code => ln_err_code  
          ,x_err_msg  => lc_err_msg 
          );

                 IF (ln_err_code <> 0) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

GET_VS_ID (p_vs_name  => lc_subclass_vs_name 
          ,x_vs_id    => ln_sclass_vs_id
          ,x_err_code => ln_err_code  
          ,x_err_msg  => lc_err_msg 
          );

                 IF (ln_err_code <> 0) THEN
                    x_error_msg := x_error_msg || lc_err_msg;
                    RAISE le_end_procedure;
                 END IF;

               -- Disable Value Set Value Based on Hierarchy level
               IF (p_hierarchy_level = 'DIVISION') THEN 

                   FOR get_grp_val_rec IN get_grp_val (p_vs_id => ln_flex_value_set_id_grp,p_vs_val => to_char(ln_flex_value))
                   LOOP

                        FOR get_depart_val_rec IN get_depart_val (p_vs_id => ln_flex_value_set_id_dept,p_vs_val => get_grp_val_rec.flex_value)
                        LOOP

                             FOR get_class_val_rec IN get_class_val (p_vs_id => ln_class_value_set_id,p_vs_val => get_depart_val_rec.flex_value)
                             LOOP

                                 FOR get_subclass_val_rec IN get_subclass_val (p_vs_id => ln_sclass_vs_id,p_vs_val => get_class_val_rec.flex_value)
                                 LOOP
                                     
                                     -- Disabling Subclasses
                                     DISABLE_VSET_VALUE ( p_vs_id             => ln_sclass_vs_id
                                                         ,p_value_to_disable  => get_subclass_val_rec.flex_value
                                                         ,p_vs_name           => lc_subclass_vs_name
                                                         ,x_err_code          => ln_err_code  
                                                         ,x_err_msg           => lc_err_msg 
                                                        );
                                                        
                                     IF (ln_err_code <> 0) THEN
                                         x_error_msg := x_error_msg || lc_err_msg;
                                         RAISE le_end_procedure;
                                     END IF;
                                     
                                     
                                 END LOOP;

                                      -- Disabling Classes
                                      DISABLE_VSET_VALUE ( p_vs_id             => ln_class_value_set_id
                                                          ,p_value_to_disable  => get_class_val_rec.flex_value
                                                          ,p_vs_name           => lc_class_vs_name
                                                          ,x_err_code          => ln_err_code  
                                                          ,x_err_msg           => lc_err_msg 
                                                         );
                                                         
                                      IF (ln_err_code <> 0) THEN
                                          x_error_msg := x_error_msg || lc_err_msg;
                                          RAISE le_end_procedure;
                                      END IF;

                             END LOOP; 

                                --Disabling Departments
                                DISABLE_VSET_VALUE ( p_vs_id             => ln_flex_value_set_id_dept
                                                    ,p_value_to_disable  => get_depart_val_rec.flex_value
                                                    ,p_vs_name           => lc_dept_vs_name
                                                    ,x_err_code          => ln_err_code  
                                                    ,x_err_msg           => lc_err_msg 
                                                   );
                                                   
                                IF (ln_err_code <> 0) THEN                   
                                    x_error_msg := x_error_msg || lc_err_msg;
                                    RAISE le_end_procedure;
                                END IF;

                        END LOOP; 

                           -- Disabling Groups
                           DISABLE_VSET_VALUE ( p_vs_id             => ln_flex_value_set_id_grp
                                               ,p_value_to_disable  => get_grp_val_rec.flex_value
                                               ,p_vs_name           => lc_group_vs_name
                                               ,x_err_code          => ln_err_code  
                                               ,x_err_msg           => lc_err_msg 
                                              );
                           
                           IF (ln_err_code <> 0) THEN
                               x_error_msg := x_error_msg || lc_err_msg;
                               RAISE le_end_procedure;
                           END IF;

                   END LOOP;
                       --Disable the Division itself
                       DISABLE_VSET_VALUE ( p_vs_id             => ln_flex_value_set_id_div
                                           ,p_value_to_disable  => to_char(ln_flex_value)
                                           ,p_vs_name           => lc_flex_value_set_name
                                           ,x_err_code          => ln_err_code  
                                           ,x_err_msg           => lc_err_msg 
                                          );

                       IF (ln_err_code <> 0) THEN
                           x_error_msg := x_error_msg || lc_err_msg;
                           RAISE le_end_procedure;
                       END IF;
                       
                       x_error_msg := x_error_msg || chr(10) || 'Value set values disabled successfully';

               ELSIF (p_hierarchy_level = 'GROUP') THEN

                    FOR get_depart_val_rec IN get_depart_val (p_vs_id => ln_flex_value_set_id_dept,p_vs_val => to_char(ln_flex_value))
                    LOOP

                                      FOR get_class_val_rec IN get_class_val (p_vs_id => ln_class_value_set_id,p_vs_val => get_depart_val_rec.flex_value)
                                      LOOP

                                         FOR get_subclass_val_rec IN get_subclass_val (p_vs_id => ln_sclass_vs_id,p_vs_val => get_class_val_rec.flex_value)
                                         LOOP

                                                 --Disabling Subclasses
                                                 DISABLE_VSET_VALUE ( p_vs_id             => ln_sclass_vs_id
                                                                     ,p_value_to_disable  => get_subclass_val_rec.flex_value
                                                                     ,p_vs_name           => lc_subclass_vs_name
                                                                     ,x_err_code          => ln_err_code  
                                                                     ,x_err_msg           => lc_err_msg 
                                                                    );
                                                                    
                                                 IF (ln_err_code <> 0) THEN
                                                     x_error_msg := x_error_msg || lc_err_msg;
                                                     RAISE le_end_procedure;
                                                 END IF;

                                         END LOOP;

                                              --Disable Classes
                                              DISABLE_VSET_VALUE ( p_vs_id             => ln_class_value_set_id
                                                                  ,p_value_to_disable  => get_class_val_rec.flex_value
                                                                  ,p_vs_name           => lc_class_vs_name
                                                                  ,x_err_code          => ln_err_code  
                                                                  ,x_err_msg           => lc_err_msg 
                                                                 );
                                                                 
                                              IF (ln_err_code <> 0) THEN
                                                  x_error_msg := x_error_msg || lc_err_msg;
                                                  RAISE le_end_procedure;
                                              END IF;

                                      END LOOP; 

                             --Disabling Departments
                             DISABLE_VSET_VALUE ( p_vs_id             => ln_flex_value_set_id_dept
                                                 ,p_value_to_disable  => get_depart_val_rec.flex_value
                                                 ,p_vs_name           => lc_dept_vs_name
                                                 ,x_err_code          => ln_err_code  
                                                 ,x_err_msg           => lc_err_msg 
                                                );

                             IF (ln_err_code <> 0) THEN
                                 x_error_msg := x_error_msg || lc_err_msg;
                                 RAISE le_end_procedure;
                             END IF;

                     END LOOP; 
                     
                     --Disable group
                     DISABLE_VSET_VALUE ( p_vs_id             => ln_flex_value_set_id_grp
                                         ,p_value_to_disable  => to_char(ln_flex_value)
                                         ,p_vs_name           => lc_flex_value_set_name
                                         ,x_err_code          => ln_err_code  
                                         ,x_err_msg           => lc_err_msg 
                                        );

                     IF (ln_err_code <> 0) THEN
                         x_error_msg := x_error_msg || lc_err_msg;
                         RAISE le_end_procedure;
                     END IF;
                     
                     x_error_msg := x_error_msg || chr(10) || 'Value set values disabled successfully';

               ELSIF (p_hierarchy_level = 'DEPARTMENT') THEN
                                      FOR get_class_val_rec IN get_class_val (p_vs_id => ln_class_value_set_id,p_vs_val => to_char(ln_flex_value))
                                      LOOP

                                         FOR get_subclass_val_rec IN get_subclass_val (p_vs_id => ln_sclass_vs_id,p_vs_val => get_class_val_rec.flex_value)
                                         LOOP

                                             --Disabling Subclasses
                                             DISABLE_VSET_VALUE ( p_vs_id             => ln_sclass_vs_id
                                                                 ,p_value_to_disable  => get_subclass_val_rec.flex_value
                                                                 ,p_vs_name           => lc_subclass_vs_name
                                                                 ,x_err_code          => ln_err_code  
                                                                 ,x_err_msg           => lc_err_msg 
                                                                );
                                             IF (ln_err_code <> 0) THEN
                                             x_error_msg := x_error_msg || lc_err_msg;
                                             RAISE le_end_procedure;
                                             END IF;
                                             
                                         END LOOP;

                                            --Disabling Classes
                                            DISABLE_VSET_VALUE ( p_vs_id             => ln_class_value_set_id
                                                                ,p_value_to_disable  => get_class_val_rec.flex_value
                                                                ,p_vs_name           => lc_class_vs_name
                                                                ,x_err_code          => ln_err_code  
                                                                ,x_err_msg           => lc_err_msg 
                                                               );
                                            
                                            IF (ln_err_code <> 0) THEN
                                              x_error_msg := x_error_msg || lc_err_msg;
                                              RAISE le_end_procedure;
                                            END IF;

                                      END LOOP;

                          -- Disable Department Itselft
                          DISABLE_VSET_VALUE ( p_vs_id             => ln_flex_value_set_id_dept
                                              ,p_value_to_disable  => to_char(ln_flex_value)
                                              ,p_vs_name           => lc_flex_value_set_name
                                              ,x_err_code          => ln_err_code  
                                              ,x_err_msg           => lc_err_msg 
                                             );
                                             
                   IF (ln_err_code <> 0) THEN
                       x_error_msg := x_error_msg || lc_err_msg;
                       RAISE le_end_procedure;
                   END IF;

                   x_error_msg := x_error_msg || chr(10) || 'Value set values disabled successfully';


               ELSIF (p_hierarchy_level = 'CLASS') THEN
                                         FOR get_subclass_val_rec IN get_subclass_val (p_vs_id => ln_sclass_vs_id,p_vs_val => to_char(ln_flex_value))
                                         LOOP

                                             --Disable Subclasses
                                             DISABLE_VSET_VALUE ( p_vs_id             => ln_sclass_vs_id
                                                                 ,p_value_to_disable  => get_subclass_val_rec.flex_value
                                                                 ,p_vs_name           => lc_subclass_vs_name
                                                                 ,x_err_code          => ln_err_code 
                                                                 ,x_err_msg           => lc_err_msg 
                                                                );
                                             
                                             IF (ln_err_code <> 0) THEN
                                               x_error_msg := x_error_msg || lc_err_msg;
                                               RAISE le_end_procedure;
                                             END IF;

                                         END LOOP;

                          -- Disable the Class itself
                          DISABLE_VSET_VALUE ( p_vs_id             => ln_class_value_set_id
                                              ,p_value_to_disable  => to_char(ln_flex_value)
                                              ,p_vs_name           => lc_flex_value_set_name
                                              ,x_err_code          => ln_err_code 
                                              ,x_err_msg           => lc_err_msg 
                                             );

                          IF (ln_err_code <> 0) THEN
                              x_error_msg := x_error_msg || lc_err_msg;
                              RAISE le_end_procedure;
                          END IF;
                          
                          x_error_msg := x_error_msg || chr(10) || 'Value set values disabled successfully';

               ELSIF (p_hierarchy_level = 'SUBCLASS') THEN

                   -- Disable Subclass Only
                   DISABLE_VSET_VALUE ( p_vs_id             => ln_sclass_vs_id
                                       ,p_value_to_disable  => to_char(ln_flex_value)
                                       ,p_vs_name           => lc_flex_value_set_name
                                       ,x_err_code          => ln_err_code 
                                       ,x_err_msg           => lc_err_msg 
                                      );

                   IF (ln_err_code <> 0) THEN
                       x_error_msg := x_error_msg || lc_err_msg;
                       RAISE le_end_procedure;
                   END IF;
                   
                   x_error_msg := x_error_msg || chr(10) ||'Value set values disabled successfully';

               END IF;
               -- Ending IF Condition for Disabling Value Set Value Based on Hierarchy level

               COMMIT;

               -- If control reaches here everything is fine.
               x_error_code := 0;
  
END IF;
-- IF p_action=ADD Ends

EXCEPTION

WHEN le_end_procedure THEN
     NULL;

WHEN OTHERS THEN
     x_error_code := 1;
     x_error_msg  := x_error_msg || SQLERRM;

END Process_Merc_Hierarchy;

END XX_INV_MERC_HIERARCHY_PKG;
/

SHOW ERRORS

EXIT;