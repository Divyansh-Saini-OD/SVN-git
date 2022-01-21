SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_MERC_HIERARCHY_PKG AS

-- +===================================================================================================== +
-- |                  Office Depot - Project Simplify                                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                                          |
-- +======================================================================================================+
-- | Name       : XX_INV_MERC_HIERARCHY_PKG                                                               |
-- | Description: This package body contains the following procedures:                                    |
-- |              (1) DISABLE_VSET_VALUE                                                                  |
-- |              (2) CALL_UP_VSET_VALUE                                                                  |
-- |              (3) GET_CATEGORY_DETAILS                                                                |
-- |              (4) PROCESS_MERC_HIERARCHY                                                              |
-- |                                                                                                      |
-- |Change Record:                                                                                        |
-- |===============                                                                                       |
-- |Version   Date         Author           Remarks                                                       |
-- |=======   ==========   ===============  ==============================                                |
-- |DRAFT 1A  14-MAR-2007  Siddharth Singh  Initial draft version                                         |
-- |DRAFT 1B  25-APR-2007  Siddharth Singh  Incorporated changes as per CR for renaming value sets.       |
-- |DRAFT 1C  15-MAY-2007  Siddharth singh  Incorporated changes as per CR for creating PO Category Codes.|
-- |DRAFT 1D  11-JUN-2007  Siddharth Singh  Incorporated Peer Review Comments.                            |
-- |DRAFT 1E  12-JUN-2007  Jayshree kale    Reviewed and Updated                                          |
-- |DRAFT 1F  16-JUN_2007  Siddharth Singh  Added FND_MESSAGES.                                           |
-- |DRAFT 1G  21-JUN-2007  Siddharth Singh  Changed p_action Parameter in PROCESS_MERC_HIERARCHY from ADD |
-- |                                        /MODIFY/DELETE to C/D.                                        |
-- |DRAFT 1H  25-JUN-2007  Siddharth Singh  Changed value of SEGMENT2 from Trade to TRADE for PO Category |
-- |                                        Code Combination Creation.                                    |
-- |DRAFT 1I  26-JUN-2007  Siddharth Singh  Added Validation for checking existance and enabled_flag for  |
-- |                                        the values NA and TRADE.                                      |
-- |DRAFT 1J  28-JUN-2007  Siddharth Singh  Added Timestamp to start_date_active, end_date_active and     |
-- |                                        last_update_date.Changed p_owner attribute from APPS to       |
-- |                                        FND_GLOBAL.USER_NAME.Changed enabled_flag to N while disabling|
-- |                                        Value set value and Category Codes.Added ln_structure_id_po   |
-- |                                        to where clause of the cursors get_ccc_dept,get_ccc_cla,      |
-- |                                        and get_ccc_sclas                                             |
-- |DRAFT 1K  05-JUL-2007  Siddharth Singh  Added code to populate/Modify description for Item,Po category|
-- |                                        code combinations.                                            |
-- |DRAFT 1L  05-JUL-2007  Jayshree         Reviewed                                                      |
-- |DRAFT 1M  06-JUL-2007  Siddharth Singh  Added code to create Item/PO category code combinations when a|
-- |                                        (1) subclass value exists as enabled                          |
-- |                                        (2) subclass value exists as disabled                         |
-- |DRAFT 1N  09-JUL-2007  Siddharth Singh  Added error logging procedure XX_COM_ERROR_LOG_PUB.LOG_ERROR  |
-- |                                        Removed concatenation of x_error_msg.                         |
-- |                                                                                                      |
-- |DRAFT 1O  11-JUL-2007  Siddharth Singh  Modified for updating non-hierarchial DFF attributes,         |
-- |                                        along with description                                        | 
-- |1.0       11-JUL-2007  Jayshree         Baselined                                                     |
-- |1.1       13-JUL-2007  Jayshree         Modified as per Issue reported from Onsite                    |
-- |1.2       25-Jul-2007  Jayshree/        Updated for 'BUG UPDATE 6163759':                             |
-- |                       Siddharth            Who column time truncate by API FND_FLEX_LOADER_APIS      |
-- |1.3       12-Sep-2007  Paddy Sanjeevi   Modified to update the attribute1 of value sets               |
-- |1.4       30-Nov-2007  Paddy Sanjeevi   Modified for reclassification                                 |
-- +======================================================================================================+

  L_APPL_SHORT_NAME CONSTANT VARCHAR2(10) := 'INV';
  L_KF_CODE         CONSTANT VARCHAR2(10) := 'MCAT';
  L_NA_VAL          CONSTANT VARCHAR2(2) := 'NA';
  L_TRADE_VAL       CONSTANT VARCHAR2(10) := 'TRADE';

  --LogErr

  EX_END_PROCEDURE 		EXCEPTION;
  EX_ROLLBACK_END_PROCEDURE 	EXCEPTION;

  x_err_code           NUMBER := NULL;
  x_err_msg            VARCHAR2(2000) := NULL;
  lm_value             VARCHAR2(40);
  lv_segment1          VARCHAR2(40);
  lv_segment2          VARCHAR2(40);
  lv_segment3          VARCHAR2(40);
  lv_segment4          VARCHAR2(40);
  lv_segment5          VARCHAR2(40);
  lc_link_attribute_n  VARCHAR2(50) := NULL;
  lc_link_attribute_o  VARCHAR2(50) := NULL;
  lc_link_change       VARCHAR2(1) := 'N';
  lc_hierarchy_level   VARCHAR2(50) := NULL;
  lc_value             VARCHAR2(10) := NULL;
  lc_start_date_active VARCHAR2(25) := NULL;
  lc_end_date_active   VARCHAR2(25) := NULL;
  lc_action            VARCHAR2(6) := NULL;
  lc_commit            VARCHAR2(1) := FND_API.G_FALSE;
  lc_converted_value   VARCHAR(15) := NULL;
  lc_is_null_flag      VARCHAR2(1) := 'N'; -- When='Y' it indicates that the parent segment is null
  ln_flex_value_set_id NUMBER := NULL;
  lr_ffv_typ           fnd_flex_values%ROWTYPE;
  lr_ff_rec            fnd_flex_values%ROWTYPE;
  lr_mcb_typ           mtl_categories_b%ROWTYPE;

  -- IN/OUT parameters to API INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY

  lc_init_msg_list  VARCHAR2(3000) := FND_API.G_FALSE;
  lc_msg_data       VARCHAR2(3000) := FND_API.G_FALSE;
  lc_return_status  VARCHAR2(1) := NULL; -- S, E or U
  ln_api_version_uc NUMBER := 1.0; -- API Version Number for UPDATE_CATEGORY 
  ln_errorcode      NUMBER := NULL;
  ln_msg_count      NUMBER := NULL;
  lr_category_rec   Inv_Item_Category_Pub.CATEGORY_REC_TYPE;

  -- OUT parameters from API INV_ITEM_CATEGORY_PUB.Create_Category

  ln_api_version_cc           NUMBER := 1.0; -- API Version Number for Create_Category
  ln_category_id              NUMBER := NULL;
  lc_attribute1               VARCHAR2(100) := NULL;
  lc_attribute2               VARCHAR2(100) := NULL;
  lc_attribute3               VARCHAR2(100) := NULL;
  lc_attribute4               VARCHAR2(100) := NULL;
  lc_attribute5               VARCHAR2(100) := NULL;
  lc_attribute6               VARCHAR2(100) := NULL;
  lc_attribute7               VARCHAR2(100) := NULL;
  lc_attribute8               VARCHAR2(100) := NULL;
  lc_attribute9               VARCHAR2(100) := NULL;
  lc_attribute10              VARCHAR2(100) := NULL;
  lc_dept_num                 VARCHAR2(100) := NULL;
  lc_dept_val                 VARCHAR2(100) := NULL;
  lc_description              VARCHAR2(1000) := NULL;
  lc_div_num                  VARCHAR2(100) := NULL;
  lc_dummy                    VARCHAR2(100) := NULL;
  lc_enabled_flag             VARCHAR2(1) := NULL;
  lc_err_msg                  VARCHAR2(3000) := NULL;
  lc_existing_description     fnd_flex_values_tl.description%TYPE := NULL;
  lc_flex_value_set_name      VARCHAR2(100) := NULL;
  lc_grp_num                  VARCHAR2(100) := NULL;
  lc_item_delimiter           VARCHAR2(1) := NULL;
  lc_po_delimiter             VARCHAR2(1) := NULL;
  lc_summary_flag             VARCHAR2(1) := NULL;
  lc_value_category           fnd_flex_values.VALUE_CATEGORY%TYPE := NULL;
  ld_start_date_active        DATE;
  ln_class_value_set_id       NUMBER := NULL;
  ln_err_code                 NUMBER := NULL;
  ln_flex_value_set_id_class  NUMBER := NULL;
  ln_flex_value_set_id_dept   NUMBER := NULL;
  ln_flex_value_set_id_div    NUMBER := NULL;
  ln_flex_value_set_id_grp    NUMBER := NULL;
  ln_flex_value_set_id_potype NUMBER := NULL;
  ln_flex_value_set_id_unspsc NUMBER := NULL;
  ln_fvs_id                   NUMBER := NULL;
  lc_item_cc_exists_flag      VARCHAR2(1) := 'N';
  lc_po_cc_exists_flag        VARCHAR2(1) := 'N';
  ln_sclass_vs_id             NUMBER := NULL;
  ln_structure_id             NUMBER := NULL;
  ln_structure_id_po          NUMBER := NULL;
  ln_value_set_id             NUMBER := NULL;
  lc_class_description        fnd_flex_values_tl.description%TYPE := NULL;
  lc_dept_description         fnd_flex_values_tl.description%TYPE := NULL;
  lc_div_description          fnd_flex_values_tl.description%TYPE := NULL;
  lc_grp_description          fnd_flex_values_tl.description%TYPE := NULL;
  lc_na_description           fnd_flex_values_tl.description%TYPE := NULL;
  lc_sclass_description       fnd_flex_values_tl.description%TYPE := NULL;
  lc_trade_description        fnd_flex_values_tl.description%TYPE := NULL;

  PROCEDURE DISABLE_VSET_VALUE(p_vs_id            IN NUMBER,
                               p_value_to_disable IN VARCHAR2,
                               p_vs_name          IN VARCHAR2,
                               x_err_code         OUT NUMBER,
                               x_err_msg          OUT VARCHAR2)
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

    lc_existing_description fnd_flex_values_tl.description%TYPE := NULL;
    lr_ffv_typ              fnd_flex_values%ROWTYPE;
    ld_end_date_active      DATE;

    --To check the enabled flag after disabling the value

    CURSOR lcu_disable_check IS
      SELECT end_date_active
        FROM fnd_flex_values
       WHERE flex_value_set_id = p_vs_id
         AND flex_value = p_value_to_disable;

  BEGIN

    lr_ffv_typ := NULL;

    -- Since this Value already Exists,Get values for this record 

    BEGIN
      SELECT *
        INTO lr_ffv_typ
        FROM fnd_flex_values
       WHERE flex_value_set_id = p_vs_id
         AND flex_value = p_value_to_disable;
    EXCEPTION
      WHEN OTHERS THEN
        x_err_code := -1;
        x_err_msg  := 'WHEN OTHERS EXCEPTION In fetching Existing Values in Procedure DISABLE_VSET_VALUE :' ||
                      p_value_to_disable || ' In' || p_vs_name;
        RETURN;
    END;

    -- Get description for this value 

    BEGIN
      SELECT description
        INTO lc_existing_description
        FROM fnd_flex_values_tl
       WHERE flex_value_id = lr_ffv_typ.flex_value_id;
    EXCEPTION
      WHEN OTHERS THEN
        x_err_code := -1;
        x_err_msg  := 'WHEN OTHERS EXCEPTION In fetching Existing description in Procedure DISABLE_VSET_VALUE :' ||
                      p_value_to_disable || ' In' || p_vs_name;
        RETURN;
    END;

    -- disable the value itself by using Disable Date feature.Setting end_date_active 

    XX_INV_FND_FLEX_LOADER_APIS.UP_VSET_VALUE(p_upload_phase              => 'BEGIN',
                                              p_upload_mode               => NULL,
                                              p_custom_mode               => NULL,
                                              p_flex_value_set_name       => p_vs_name,
                                              p_parent_flex_value_low     => NULL,
                                              p_flex_value                => p_value_to_disable,
                                              p_owner                     => FND_GLOBAL.USER_NAME,
                                              p_last_update_date          => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'),
                                              p_enabled_flag              => 'N',
                                              p_summary_flag              => lr_ffv_typ.summary_flag,
                                              p_start_date_active         => TO_CHAR(lr_ffv_typ.start_date_active,'YYYY/MM/DD HH24:MI:SS'),
                                              p_end_date_active           => TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'),
                                              p_parent_flex_value_high    => lr_ffv_typ.parent_flex_value_high,
                                              p_rollup_hierarchy_code     => NULL,
                                              p_hierarchy_level           => lr_ffv_typ.hierarchy_level,
                                              p_compiled_value_attributes => lr_ffv_typ.compiled_value_attributes,
                                              p_value_category            => lr_ffv_typ.value_category,
                                              p_attribute1                => lr_ffv_typ.attribute1,
                                              p_attribute2                => lr_ffv_typ.attribute2,
                                              p_attribute3                => lr_ffv_typ.attribute3,
                                              p_attribute4                => lr_ffv_typ.attribute4,
                                              p_attribute5                => lr_ffv_typ.attribute5,
                                              p_attribute6                => lr_ffv_typ.attribute6,
                                              p_attribute7                => lr_ffv_typ.attribute7,
                                              p_attribute8                => lr_ffv_typ.attribute8,
                                              p_attribute9                => lr_ffv_typ.attribute9,
                                              p_attribute10               => lr_ffv_typ.attribute10,
                                              p_attribute11               => lr_ffv_typ.attribute11,
                                              p_attribute12               => lr_ffv_typ.attribute12,
                                              p_attribute13               => lr_ffv_typ.attribute13,
                                              p_attribute14               => lr_ffv_typ.attribute14,
                                              p_attribute15               => lr_ffv_typ.attribute15,
                                              p_attribute16               => lr_ffv_typ.attribute16,
                                              p_attribute17               => lr_ffv_typ.attribute17,
                                              p_attribute18               => lr_ffv_typ.attribute18,
                                              p_attribute19               => lr_ffv_typ.attribute19,
                                              p_attribute20               => lr_ffv_typ.attribute20,
                                              p_attribute21               => lr_ffv_typ.attribute21,
                                              p_attribute22               => lr_ffv_typ.attribute22,
                                              p_attribute23               => lr_ffv_typ.attribute23,
                                              p_attribute24               => lr_ffv_typ.attribute24,
                                              p_attribute25               => lr_ffv_typ.attribute25,
                                              p_attribute26               => lr_ffv_typ.attribute26,
                                              p_attribute27               => lr_ffv_typ.attribute27,
                                              p_attribute28               => lr_ffv_typ.attribute28,
                                              p_attribute29               => lr_ffv_typ.attribute29,
                                              p_attribute30               => lr_ffv_typ.attribute30,
                                              p_attribute31               => lr_ffv_typ.attribute31,
                                              p_attribute32               => lr_ffv_typ.attribute32,
                                              p_attribute33               => lr_ffv_typ.attribute33,
                                              p_attribute34               => lr_ffv_typ.attribute34,
                                              p_attribute35               => lr_ffv_typ.attribute35,
                                              p_attribute36               => lr_ffv_typ.attribute36,
                                              p_attribute37               => lr_ffv_typ.attribute37,
                                              p_attribute38               => lr_ffv_typ.attribute38,
                                              p_attribute39               => lr_ffv_typ.attribute39,
                                              p_attribute40               => lr_ffv_typ.attribute40,
                                              p_attribute41               => lr_ffv_typ.attribute41,
                                              p_attribute42               => lr_ffv_typ.attribute42,
                                              p_attribute43               => lr_ffv_typ.attribute43,
                                              p_attribute44               => lr_ffv_typ.attribute44,
                                              p_attribute45               => lr_ffv_typ.attribute45,
                                              p_attribute46               => lr_ffv_typ.attribute46,
                                              p_attribute47               => lr_ffv_typ.attribute47,
                                              p_attribute48               => lr_ffv_typ.attribute48,
                                              p_attribute49               => lr_ffv_typ.attribute49,
                                              p_attribute50               => lr_ffv_typ.attribute50,
                                              p_attribute_sort_order      => lr_ffv_typ.attribute_sort_order,
                                              p_flex_value_meaning        => NULL,
                                              p_description               => lc_existing_description);

    -- check if the value got disabled by the previous UP_VSET_VALUE call

    OPEN lcu_disable_check;
    FETCH lcu_disable_check INTO ld_end_date_active;

    IF (TO_CHAR(ld_end_date_active, 'YYYY/MM/DD') <> TO_CHAR(SYSDATE, 'YYYY/MM/DD')) THEN
      x_err_msg  := 'Cannot Disable Value ' || p_value_to_disable ||' For Value Set' || p_vs_name;
      x_err_code := -1;
      CLOSE lcu_disable_check;
      RETURN;
    END IF;

    CLOSE lcu_disable_check;

    x_err_code := 0;

  EXCEPTION
    WHEN OTHERS THEN
      x_err_code := -1;
      x_err_msg  := SQLERRM || ' ' ||' WHEN OTHERS EXCEPTION In Procedure DISABLE_VSET_VALUE ' ||
                    p_value_to_disable || ' In' || p_vs_name;
  END DISABLE_VSET_VALUE;

  PROCEDURE CALL_UP_VSET_VALUE(p_upload_phase              IN VARCHAR2 DEFAULT 'BEGIN',
                               p_upload_mode               IN VARCHAR2 DEFAULT NULL,
                               p_custom_mode               IN VARCHAR2 DEFAULT NULL,
                               p_flex_value_set_name       IN VARCHAR2,
                               p_parent_flex_value_low     IN VARCHAR2 DEFAULT NULL,
                               p_flex_value                IN VARCHAR2,
                               p_owner                     IN VARCHAR2 DEFAULT FND_GLOBAL.USER_NAME,
                               p_last_update_date          IN VARCHAR2 DEFAULT TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'),
                               p_enabled_flag              IN VARCHAR2,
                               p_summary_flag              IN VARCHAR2,
                               p_start_date_active         IN VARCHAR2,
                               p_end_date_active           IN VARCHAR2,
                               p_parent_flex_value_high    IN VARCHAR2 DEFAULT NULL,
                               p_rollup_hierarchy_code     IN VARCHAR2 DEFAULT NULL,
                               p_hierarchy_level           IN VARCHAR2 DEFAULT NULL,
                               p_compiled_value_attributes IN VARCHAR2 DEFAULT NULL,
                               p_value_category            IN VARCHAR2 DEFAULT NULL,
                               p_attribute1                IN VARCHAR2 DEFAULT NULL,
                               p_attribute2                IN VARCHAR2 DEFAULT NULL,
                               p_attribute3                IN VARCHAR2 DEFAULT NULL,
                               p_attribute4                IN VARCHAR2 DEFAULT NULL,
                               p_attribute5                IN VARCHAR2 DEFAULT NULL,
                               p_attribute6                IN VARCHAR2 DEFAULT NULL,
                               p_attribute7                IN VARCHAR2 DEFAULT NULL,
                               p_attribute8                IN VARCHAR2 DEFAULT NULL,
                               p_attribute9                IN VARCHAR2 DEFAULT NULL,
                               p_attribute10               IN VARCHAR2 DEFAULT NULL,
                               p_attribute11               IN VARCHAR2 DEFAULT NULL,
                               p_attribute12               IN VARCHAR2 DEFAULT NULL,
                               p_attribute13               IN VARCHAR2 DEFAULT NULL,
                               p_attribute14               IN VARCHAR2 DEFAULT NULL,
                               p_attribute15               IN VARCHAR2 DEFAULT NULL,
                               p_attribute16               IN VARCHAR2 DEFAULT NULL,
                               p_attribute17               IN VARCHAR2 DEFAULT NULL,
                               p_attribute18               IN VARCHAR2 DEFAULT NULL,
                               p_attribute19               IN VARCHAR2 DEFAULT NULL,
                               p_attribute20               IN VARCHAR2 DEFAULT NULL,
                               p_attribute21               IN VARCHAR2 DEFAULT NULL,
                               p_attribute22               IN VARCHAR2 DEFAULT NULL,
                               p_attribute23               IN VARCHAR2 DEFAULT NULL,
                               p_attribute24               IN VARCHAR2 DEFAULT NULL,
                               p_attribute25               IN VARCHAR2 DEFAULT NULL,
                               p_attribute26               IN VARCHAR2 DEFAULT NULL,
                               p_attribute27               IN VARCHAR2 DEFAULT NULL,
                               p_attribute28               IN VARCHAR2 DEFAULT NULL,
                               p_attribute29               IN VARCHAR2 DEFAULT NULL,
                               p_attribute30               IN VARCHAR2 DEFAULT NULL,
                               p_attribute31               IN VARCHAR2 DEFAULT NULL,
                               p_attribute32               IN VARCHAR2 DEFAULT NULL,
                               p_attribute33               IN VARCHAR2 DEFAULT NULL,
                               p_attribute34               IN VARCHAR2 DEFAULT NULL,
                               p_attribute35               IN VARCHAR2 DEFAULT NULL,
                               p_attribute36               IN VARCHAR2 DEFAULT NULL,
                               p_attribute37               IN VARCHAR2 DEFAULT NULL,
                               p_attribute38               IN VARCHAR2 DEFAULT NULL,
                               p_attribute39               IN VARCHAR2 DEFAULT NULL,
                               p_attribute40               IN VARCHAR2 DEFAULT NULL,
                               p_attribute41               IN VARCHAR2 DEFAULT NULL,
                               p_attribute42               IN VARCHAR2 DEFAULT NULL,
                               p_attribute43               IN VARCHAR2 DEFAULT NULL,
                               p_attribute44               IN VARCHAR2 DEFAULT NULL,
                               p_attribute45               IN VARCHAR2 DEFAULT NULL,
                               p_attribute46               IN VARCHAR2 DEFAULT NULL,
                               p_attribute47               IN VARCHAR2 DEFAULT NULL,
                               p_attribute48               IN VARCHAR2 DEFAULT NULL,
                               p_attribute49               IN VARCHAR2 DEFAULT NULL,
                               p_attribute50               IN VARCHAR2 DEFAULT NULL,
                               p_attribute_sort_order      IN VARCHAR2 DEFAULT NULL,
                               p_flex_value_meaning        IN VARCHAR2 DEFAULT NULL,
                               p_description               IN VARCHAR2 DEFAULT NULL,
                               p_action                    IN VARCHAR2,
                               x_err_code                  OUT NUMBER,
                               x_err_msg                   OUT VARCHAR2)
  -- +==================================================================================================================+
    -- |                                                                                                                  |
    -- | Name             : CALL_UP_VSET_VALUE                                                                            |
    -- |                                                                                                                  |
    -- | Description      : Calls UP_VSET_VALUE with default parameters to ADD,ENABLE OR UPDATE Value Set Values.         |
    -- +==================================================================================================================+
   IS

   lc_enabled_flag         VARCHAR2(1) := NULL;
   ld_end_date_active      DATE;
   lc_existing_description fnd_flex_values_tl.description%TYPE := NULL;
   ld_start_date_active    DATE;

   CURSOR lcu_check_value IS
   SELECT enabled_flag, start_date_active, end_date_active
     FROM fnd_flex_values
    WHERE flex_value = p_flex_value;

  BEGIN
    XX_INV_FND_FLEX_LOADER_APIS.UP_VSET_VALUE(p_upload_phase              => p_upload_phase,
                                              p_upload_mode               => p_upload_mode,
                                              p_custom_mode               => p_custom_mode,
                                              p_flex_value_set_name       => p_flex_value_set_name,
                                              p_parent_flex_value_low     => p_parent_flex_value_low,
                                              p_flex_value                => p_flex_value,
                                              p_owner                     => p_owner,
                                              p_last_update_date          => p_last_update_date,
                                              p_enabled_flag              => p_enabled_flag,
                                              p_summary_flag              => p_summary_flag,
                                              p_start_date_active         => p_start_date_active,
                                              p_end_date_active           => p_end_date_active,
                                              p_parent_flex_value_high    => p_parent_flex_value_high,
                                              p_rollup_hierarchy_code     => p_rollup_hierarchy_code,
                                              p_hierarchy_level           => p_hierarchy_level,
                                              p_compiled_value_attributes => p_compiled_value_attributes,
                                              p_value_category            => p_value_category,
                                              p_attribute1                => p_attribute1,
                                              p_attribute2                => p_attribute2,
                                              p_attribute3                => p_attribute3,
                                              p_attribute4                => p_attribute4,
                                              p_attribute5                => p_attribute5,
                                              p_attribute6                => p_attribute6,
                                              p_attribute7                => p_attribute7,
                                              p_attribute8                => p_attribute8,
                                              p_attribute9                => p_attribute9,
                                              p_attribute10               => p_attribute10,
                                              p_attribute11               => p_attribute11,
                                              p_attribute12               => p_attribute12,
                                              p_attribute13               => p_attribute13,
                                              p_attribute14               => p_attribute14,
                                              p_attribute15               => p_attribute15,
                                              p_attribute16               => p_attribute16,
                                              p_attribute17               => p_attribute17,
                                              p_attribute18               => p_attribute18,
                                              p_attribute19               => p_attribute19,
                                              p_attribute20               => p_attribute20,
                                              p_attribute21               => p_attribute21,
                                              p_attribute22               => p_attribute22,
                                              p_attribute23               => p_attribute23,
                                              p_attribute24               => p_attribute24,
                                              p_attribute25               => p_attribute25,
                                              p_attribute26               => p_attribute26,
                                              p_attribute27               => p_attribute27,
                                              p_attribute28               => p_attribute28,
                                              p_attribute29               => p_attribute29,
                                              p_attribute30               => p_attribute30,
                                              p_attribute31               => p_attribute31,
                                              p_attribute32               => p_attribute32,
                                              p_attribute33               => p_attribute33,
                                              p_attribute34               => p_attribute34,
                                              p_attribute35               => p_attribute35,
                                              p_attribute36               => p_attribute36,
                                              p_attribute37               => p_attribute37,
                                              p_attribute38               => p_attribute38,
                                              p_attribute39               => p_attribute39,
                                              p_attribute40               => p_attribute40,
                                              p_attribute41               => p_attribute41,
                                              p_attribute42               => p_attribute42,
                                              p_attribute43               => p_attribute43,
                                              p_attribute44               => p_attribute44,
                                              p_attribute45               => p_attribute45,
                                              p_attribute46               => p_attribute46,
                                              p_attribute47               => p_attribute47,
                                              p_attribute48               => p_attribute48,
                                              p_attribute49               => p_attribute49,
                                              p_attribute50               => p_attribute50,
                                              p_attribute_sort_order      => p_attribute_sort_order,
                                              p_flex_value_meaning        => p_flex_value_meaning,
                                              p_description               => p_description);
    IF (p_action = 'ADD') THEN

      OPEN lcu_check_value;
      FETCH lcu_check_value INTO lc_enabled_flag, ld_start_date_active, ld_end_date_active;

      IF (lcu_check_value%NOTFOUND) THEN
        x_err_code := -1;
        x_err_msg  := 'API XX_INV_FND_FLEX_LOADER_APIS.UP_VSET_VALUE Failed to Add the Value';
        CLOSE lcu_check_value;
        RETURN;
      END IF;

      CLOSE lcu_check_value;

    ELSIF (p_action = 'ENABLE') THEN
      OPEN lcu_check_value;
      FETCH lcu_check_value INTO lc_enabled_flag, ld_start_date_active, ld_end_date_active;

      IF (lcu_check_value%NOTFOUND) THEN
        x_err_code := -1;
        x_err_msg  := 'Value set value does not exist in  EBS to perform Enabling';
        CLOSE lcu_check_value;
        RETURN;
      END IF;

      CLOSE lcu_check_value;

      IF (NVL(lc_enabled_flag, 'X') <> 'Y' AND ld_end_date_active IS NOT NULL) THEN
        x_err_code := -1;
        x_err_msg  := 'API XX_INV_FND_FLEX_LOADER_APIS.UP_VSET_VALUE Failed to Enable the Value.';
        RETURN;
      END IF;

    ELSIF (p_action = 'UPDATE') THEN

      -- Check if the description got modified

      BEGIN
        SELECT FFVT.description
          INTO lc_existing_description
          FROM fnd_flex_value_sets FFVS,
               fnd_flex_values     FFV,
               fnd_flex_values_tl  FFVT
         WHERE FFVS.flex_value_set_id = FFV.flex_value_set_id
           AND FFV.flex_value_id = FFVT.flex_value_id
           AND FFVS.flex_value_set_name = p_flex_value_set_name
           AND FFV.flex_value = p_flex_value;
        IF (lc_existing_description = p_description) THEN
          x_err_code := 0;
        ELSE
          x_err_code := -1;
          RETURN;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          x_err_code := -1;
          x_err_msg  := SQLERRM || ' ' ||
                        'WHEN OTHERS EXCEPTION In Procedure CALL_UP_VSET_VALUE While checking Description.';
          RETURN;
      END;
    END IF;
    x_err_code := 0;
  EXCEPTION
    WHEN OTHERS THEN
      x_err_code := -1;
      x_err_msg  := SQLERRM || ' ' ||'WHEN OTHERS EXCEPTION In Procedure CALL_UP_VSET_VALUE.';
  END CALL_UP_VSET_VALUE;

  PROCEDURE get_catg_segments(p_value    IN VARCHAR2,
                              p_class    IN VARCHAR2,
                              x_segment1 OUT NOCOPY VARCHAR2,
                              x_segment2 OUT NOCOPY VARCHAR2,
                              x_segment3 OUT NOCOPY VARCHAR2,
                              x_segment4 OUT NOCOPY VARCHAR2,
                              x_segment5 OUT NOCOPY VARCHAR2)
  -- +===================================================================================================+
    -- |                                                                                                 |
    -- | Name             : GET_CATG_SEGMENTS                                                            |
    -- |                                                                                                 |
    -- | Description      : To get the Merchandising Hierarchy combination for the class and subclass    |
    -- |                                  .                                                              |
    -- |                                                                                                 |
    -- | Parameters       : p_value             IN  Subclass					 		   |
    -- |                    p_class             IN  Class 					                     |
    -- |                    x_segment1          OUT Division  			                           |
    -- |                    x_segment2          OUT Group   			                           |
    -- |                    x_segment3          OUT Department  			                           |
    -- |                    x_segment4          OUT Class   			                           |
    -- |                    x_segment5          OUT Subclass  			                           |
    -- +=================================================================================================+

  IS

  CURSOR lcu_get_enabled_flag(ln_flex_val_set_id NUMBER, lc_value VARCHAR2) IS
  SELECT *
    FROM fnd_flex_values
   WHERE flex_value_set_id = ln_flex_val_set_id
     AND flex_value = lc_value;

    --To get the parent value of the given record

  CURSOR lcu_get_parent_value(p_vs_id NUMBER, p_vs_value VARCHAR2) IS
  SELECT attribute1
    FROM fnd_flex_values
   WHERE flex_value_set_id = p_vs_id
     AND flex_value = p_vs_value;

    lv_div       VARCHAR2(40);
    lv_grp       VARCHAR2(40);
    lv_dep       VARCHAR2(40);
    x_error_code NUMBER;
    x_error_msg  VARCHAR2(2000);

  BEGIN

    --Get enabled flag and end_date_active for class number IN Parameter

    OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_class_value_set_id,lc_value=> p_class);
    FETCH lcu_get_enabled_flag INTO lr_ff_rec;

    IF (lcu_get_enabled_flag%NOTFOUND) THEN
      x_error_code := -1;
      x_error_msg  := 'Failed to get CLASS ' || p_class || ' for SUBCLASS' ||p_value;
      CLOSE lcu_get_enabled_flag;
      RAISE EX_ROLLBACK_END_PROCEDURE; --LogErr;
    END IF;
    CLOSE lcu_get_enabled_flag;

    -- If this class is not enabled error out

    IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND 
       NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN

      x_error_code := -1;
      x_error_msg  := 'CLASS ' || p_class ||' is not enabled for the SUBCLASS' || p_value;
      RAISE EX_ROLLBACK_END_PROCEDURE; --LogErr;

    END IF;

    lv_dep := lr_ff_rec.attribute1;

    IF lc_link_change = 'Y' THEN
      IF lc_hierarchy_level = 'CLASS' THEN
        lv_dep := lc_link_attribute_n;
      END IF;
    END IF;

    --Get enabled flag and end_date_active for department number obtained above
    OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_dept,
                              lc_value           => lv_dep);

    FETCH lcu_get_enabled_flag INTO lr_ff_rec;

    IF (lcu_get_enabled_flag%NOTFOUND) THEN
      x_error_code := -1;
      x_error_msg  := 'Failed to get DEPARTMENT ' || lv_dep || ' for CLASS' || p_class;
      CLOSE lcu_get_enabled_flag;
      RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
    END IF;

    CLOSE lcu_get_enabled_flag;

    -- If this department is not enabled error out

    IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
        NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN

      x_error_code := -1;
      x_error_msg  := 'DEPARTMENT ' || lv_dep || ' is not enabled for the CLASS' || p_class;
      RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;

    END IF;

    lv_grp := lr_ff_rec.attribute1;

    IF lc_link_change = 'Y' THEN
      IF lc_hierarchy_level = 'DEPARTMENT' THEN
        lv_grp := lc_link_attribute_n;
      END IF;
    END IF;

    --Get enabled flag and end_date_active for group number obtained above

    OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_grp,
                              lc_value           => lv_grp);
    FETCH lcu_get_enabled_flag INTO lr_ff_rec;

    IF (lcu_get_enabled_flag%NOTFOUND) THEN

      x_error_code := -1;
      x_error_msg  := 'Failed to get GROUP ' || lv_grp || ' for DEPARTMENT' || lv_dep;
      CLOSE lcu_get_enabled_flag;
      RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;

    END IF;
    CLOSE lcu_get_enabled_flag;

    -- If this group is not enabled error out
    IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
        NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN

      x_error_code := -1;
      x_error_msg  := 'GROUP ' || lv_grp || ' is not enabled for the DEPARTMENT' || lv_dep;
      RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;

    END IF;
    lv_div := lr_ff_rec.attribute1;

    IF lc_link_change = 'Y' THEN
      IF lc_hierarchy_level = 'GROUP' THEN
        lv_div := lc_link_attribute_n;
      END IF;
    END IF;

    -- The following cursor is JUST to validate the existence of division derived in the above fetch.
    -- There is no parent value expected here. The parent value extracted to dummy varaible 
    -- should always be NULL.
    OPEN lcu_get_parent_value(p_vs_id    => ln_flex_value_set_id_div,
                              p_vs_value => lv_div);
    FETCH lcu_get_parent_value INTO lc_dummy;

    IF (lcu_get_parent_value%NOTFOUND) THEN

      x_error_code := -1;
      x_error_msg  := 'Failed to get DIVISION ' || lv_div;
      CLOSE lcu_get_parent_value;
      RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;

    END IF;

    CLOSE lcu_get_parent_value;

    --Get enabled flag and end_date_active for division number obtained above
    OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_div,
                              lc_value           => lv_div);
    FETCH lcu_get_enabled_flag INTO lr_ff_rec;

    IF (lcu_get_enabled_flag%NOTFOUND) THEN
      x_error_code := -1;
      x_error_msg  := 'Failed to get DIVISION ' || lv_div || ' for GROUP' || lv_grp;
      CLOSE lcu_get_enabled_flag;
      RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
    END IF;
    CLOSE lcu_get_enabled_flag;

    -- If this division is not enabled error out
    IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
        NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN

      x_error_code := -1;
      x_error_msg  := 'DIVISION ' || lv_div ||
                      ' is not enabled for the GROUP' || lv_grp;
      RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;

    END IF;

    x_segment1 := lv_div;
    x_segment2 := lv_grp;
    x_segment3 := lv_dep;
    x_segment4 := p_class;
    x_segment5 := p_value;

  EXCEPTION
    WHEN EX_ROLLBACK_END_PROCEDURE THEN
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(P_PROGRAM_TYPE           => 'CUSTOM API',
                                     P_PROGRAM_NAME           => 'XX_INV_MERC_HIERARCHY_PKG.PROCESS_MERC_HIERARCHY',
                                     P_PROGRAM_ID             => NULL,
                                     P_MODULE_NAME            => 'INV',
                                     P_ERROR_LOCATION         => 'EX_END_PROCEDURE EXCEPTION',
                                     P_ERROR_MESSAGE_COUNT    => NULL,
                                     P_ERROR_MESSAGE_CODE     => x_error_code,
                                     P_ERROR_MESSAGE          => x_error_msg,
                                     P_ERROR_MESSAGE_SEVERITY => 'MAJOR',
                                     P_NOTIFY_FLAG            => 'Y',
                                     P_OBJECT_TYPE            => 'Merchandising Hierarchy Interface',
                                     P_OBJECT_ID              => lm_value,
                                     P_ATTRIBUTE1             => lc_hierarchy_level,
                                     P_ATTRIBUTE2             => lc_description,
                                     P_ATTRIBUTE3             => lc_action,
                                     P_RETURN_CODE            => NULL,
                                     P_MSG_COUNT              => NULL);
  END get_catg_segments;

  FUNCTION get_category_description(p_div_vs_id IN NUMBER,
                                    p_grp_vs_id IN NUMBER,
                                    p_dep_vs_id IN NUMBER,
                                    p_cls_vs_id IN NUMBER,
                                    p_scl_vs_id IN NUMBER,
                                    p_pot_vs_id IN NUMBER,
                                    p_uns_vs_id IN NUMBER,
                                    p_div       IN VARCHAR2,
                                    p_grp       IN VARCHAR2,
                                    p_dep       IN VARCHAR2,
                                    p_cls       IN VARCHAR2,
                                    p_scl       IN VARCHAR2,
                                    p_na        IN VARCHAR2,
                                    p_trd       IN VARCHAR2,
                                    p_structure IN VARCHAR2)
  -- +===================================================================================================+
    -- |                                                                                                 |
    -- | Name             : GET_CATEGORY_DESCRIPTION                                                     |
    -- |                                                                                                 |
    -- | Description      : To get the Merchandising Hierarchy category description                      |
    -- |                                  .                                                              |
    -- |                                                                                                 |
    -- | Parameters       : p_div_vs_id         IN  Division   Value set id			 		   |
    -- |                    p_grp_vs_id         IN  Group      Value set id			 		   |
    -- |                    p_dep_vs_id         IN  Department Value set id			 		   |
    -- |                    p_cls_vs_id         IN  Class      Value set id			 		   |
    -- |                    p_scl_vs_id         IN  Subclass   Value set id			 		   |
    -- |                    p_pot_vs_id         IN  PO Type    Value set id			 		   |
    -- |                    p_uns_vs_id         IN  UNS        Value set id			 		   |
    -- |                    p_div		      IN  Division  			                           |
    -- |                    p_grp		      IN  Group   			                           |
    -- |                    p_dep		      IN  Department  			                           |
    -- |                    p_cls		      IN  Class   			                           |
    -- |                    p_scl		      IN  Subclass  			                           |
    -- |                    p_na		      IN  NA     				                           |
    -- |                    p_trd		      IN  Trade   			                           |
    -- |                    p_structure	      IN  Structure id 			                           |
    -- +=================================================================================================+

  RETURN VARCHAR2 IS
 
  l_description VARCHAR2(240);
  
  CURSOR lcu_get_vs_val_description(ln_fvs_id_div NUMBER, ln_fvs_id_grp NUMBER, 
					      ln_fvs_id_dept NUMBER,ln_fvs_id_class NUMBER,
						ln_fvs_id_sclass NUMBER, ln_fvs_id_potype NUMBER,
						ln_fvs_id_unspsc NUMBER, lc_div_num VARCHAR2, 
						lc_grp_num VARCHAR2, lc_dept_num VARCHAR2, 
						lc_class_num VARCHAR2, lc_sclass_num VARCHAR2,
						lc_na_val VARCHAR2, lc_trade_val VARCHAR2) IS

  SELECT FFVT.description, FFV.flex_value_set_id
    FROM fnd_flex_values_tl FFVT, fnd_flex_values FFV
   WHERE FFVT.flex_value_id = FFV.flex_value_id
     AND (   (FFV.flex_value_set_id = ln_fvs_id_div  AND FFV.flex_value = lc_div_num) 
	    OR (FFV.flex_value_set_id = ln_fvs_id_grp  AND FFV.flex_value = lc_grp_num) 
	    OR (FFV.flex_value_set_id = ln_fvs_id_dept AND FFV.flex_value = lc_dept_num) 
	    OR (FFV.flex_value_set_id = ln_fvs_id_class AND FFV.flex_value = lc_class_num) 
	    OR (FFV.flex_value_set_id = ln_fvs_id_sclass AND FFV.flex_value = lc_sclass_num) 
	    OR (FFV.flex_value_set_id = ln_fvs_id_potype AND FFV.flex_value = lc_trade_val) 
	    OR (FFV.flex_value_set_id = ln_fvs_id_unspsc AND FFV.flex_value = lc_na_val)
	   );

  BEGIN

    lc_div_description    := NULL;
    lc_grp_description    := NULL;
    lc_dept_description   := NULL;
    lc_class_description  := NULL;
    lc_sclass_description := NULL;
    lc_trade_description  := NULL;
    lc_na_description     := NULL;

    FOR lcu_get_vs_val_description_rec IN lcu_get_vs_val_description(p_div_vs_id,
                                                                     p_grp_vs_id,
                                                                     p_dep_vs_id,
                                                                     p_cls_vs_id,
                                                                     p_scl_vs_id,
                                                                     p_pot_vs_id,
                                                                     p_uns_vs_id,
                                                                     p_div,
                                                                     p_grp,
                                                                     p_dep,
                                                                     p_cls,
                                                                     p_scl,
                                                                     p_na,
                                                                     p_trd) LOOP

      --To populate description variables

      IF (lcu_get_vs_val_description_rec.flex_value_set_id = p_div_vs_id) THEN

        lc_div_description := lcu_get_vs_val_description_rec.description;

      ELSIF (lcu_get_vs_val_description_rec.flex_value_set_id = ln_flex_value_set_id_grp) THEN

        lc_grp_description := lcu_get_vs_val_description_rec.description;

      ELSIF (lcu_get_vs_val_description_rec.flex_value_set_id =ln_flex_value_set_id_dept) THEN

        lc_dept_description := lcu_get_vs_val_description_rec.description;

      ELSIF (lcu_get_vs_val_description_rec.flex_value_set_id =ln_class_value_set_id) THEN

        lc_class_description := lcu_get_vs_val_description_rec.description;

      ELSIF (lcu_get_vs_val_description_rec.flex_value_set_id =ln_sclass_vs_id) THEN

        lc_sclass_description := lcu_get_vs_val_description_rec.description;

      ELSIF (lcu_get_vs_val_description_rec.flex_value_set_id =ln_flex_value_set_id_potype) THEN

        lc_trade_description := lcu_get_vs_val_description_rec.description;


      ELSIF (lcu_get_vs_val_description_rec.flex_value_set_id =ln_flex_value_set_id_unspsc) THEN

        lc_na_description := lcu_get_vs_val_description_rec.description;

      END IF;

      -- If to populate description variables Ends

    END LOOP;

    IF p_structure = 'ITEM_CATEGORIES' THEN

      l_description := lc_div_description || lc_item_delimiter ||
                       lc_grp_description || lc_item_delimiter ||
                       lc_dept_description || lc_item_delimiter ||
                       lc_class_description || lc_item_delimiter ||
                       lc_sclass_description;

    ELSIF p_structure = 'PO_ITEM_CATEGORY' THEN

      l_description := lc_na_description || lc_item_delimiter ||
                       lc_trade_description || lc_item_delimiter ||
                       lc_dept_description || lc_item_delimiter ||
                       lc_class_description || lc_item_delimiter ||
                       lc_sclass_description;

    END IF;

    RETURN(l_description);

  END get_category_description;

PROCEDURE create_od_category(p_segment1   IN VARCHAR2,
                               p_segment2   IN VARCHAR2,
                               p_segment3   IN VARCHAR2,
                               p_segment4   IN VARCHAR2,
                               p_segment5   IN VARCHAR2,
                               p_cat        IN VARCHAR2,
                               x_error_code OUT NOCOPY NUMBER,
                               x_error_msg  OUT NOCOPY VARCHAR2) 
 
 -- +===================================================================================================+
    -- |                                                                                                 |
    -- | Name             : CREATE_OD_CATEGORY                                                           |
    -- |                                                                                                 |
    -- | Description      : To create Inventory and PO Category 							   |
    -- |                                  .                                                              |
    -- |                                                                                                 |
    -- | Parameters       : p_segment1          IN  Division					 		   |
    -- |                    p_segment2          IN  Group 					                     |
    -- |                    p_segment3          IN  Department				                     |
    -- |                    p_segment4          IN  Class 					                     |
    -- |                    p_segment5          IN  Subclass 				                     |
    -- |                    p_cat	            IN  INV/PO Category		                           |
    -- |                    x_error_code        OUT Error Code  			                           |
    -- |                    x_error_msg         OUT Error Mesg  			                           |
    -- +=================================================================================================+

IS
BEGIN
  lr_category_rec.SEGMENT3          := p_segment3;
  lr_category_rec.SEGMENT4          := p_segment4;
  lr_category_rec.SEGMENT5          := p_segment5;
  lr_category_rec.END_DATE_ACTIVE   := NULL;
  lr_category_rec.DISABLE_DATE      := NULL;
  lr_category_rec.SUMMARY_FLAG      := 'N';
  lr_category_rec.ENABLED_FLAG      := 'Y';
  lr_category_rec.START_DATE_ACTIVE := SYSDATE;
  IF p_cat = 'I' THEN
     lr_category_rec.SEGMENT1       := p_segment1;
     lr_category_rec.SEGMENT2       := p_segment2;
     lr_category_rec.STRUCTURE_CODE := gc_structure_code;
     lr_category_rec.STRUCTURE_ID   := ln_structure_id;
     lr_category_rec.description    := get_category_description(ln_flex_value_set_id_div,
                                                                 ln_flex_value_set_id_grp,
                                                                 ln_flex_value_set_id_dept,
                                                                 ln_class_value_set_id,
                                                                 ln_sclass_vs_id,
                                                                 ln_flex_value_set_id_potype,
                                                                 ln_flex_value_set_id_unspsc,
                                                                 p_segment1,
                                                                 p_segment2,
                                                                 p_segment3,
                                                                 p_segment4,
                                                                 p_segment5,
                                                                 L_NA_VAL,
                                                                 L_TRADE_VAL,
                                                                 'ITEM_CATEGORIES');
      INV_ITEM_CATEGORY_PUB.Create_Category(p_api_version   => ln_api_version_cc,
                                            x_return_status => lc_return_status,
                                            x_errorcode     => ln_errorcode,
                                            x_msg_count     => ln_msg_count,
                                            x_msg_data      => lc_msg_data,
                                            p_category_rec  => lr_category_rec,
                                            x_category_id   => ln_category_id);
      IF (lc_return_status <> 'S') THEN
        x_error_code := -1;
        x_error_msg  := 'Unable to create INV Category Code Combinations. Error: ' ||
                        lc_msg_data || ' Subclass ' || p_segment5 ||
                        ' will not be added';
        RAISE EX_ROLLBACK_END_PROCEDURE;
      ELSE
        x_error_code := 0;
        x_error_msg  := 'Category Code Combinations Loaded Successfully';
      END IF;
  ELSIF p_cat = 'P' THEN
      lr_category_rec.SEGMENT1       := L_NA_VAL;
      lr_category_rec.SEGMENT2       := L_TRADE_VAL;
      lr_category_rec.STRUCTURE_CODE := gc_structure_code_po;
      lr_category_rec.STRUCTURE_ID   := ln_structure_id_po;
      lr_category_rec.description    := get_category_description(ln_flex_value_set_id_div,
                                                                 ln_flex_value_set_id_grp,
                                                                 ln_flex_value_set_id_dept,
                                                                 ln_class_value_set_id,
                                                                 ln_sclass_vs_id,
                                                                 ln_flex_value_set_id_potype,
                                                                 ln_flex_value_set_id_unspsc,
                                                                 p_segment1,
                                                                 p_segment2,
                                                                 p_segment3,
                                                                 p_segment4,
                                                                 p_segment5,
                                                                 L_NA_VAL,
                                                                 L_TRADE_VAL,
                                                                 'PO_ITEM_CATEGORY');
      INV_ITEM_CATEGORY_PUB.Create_Category(p_api_version   => ln_api_version_cc,
                                            x_return_status => lc_return_status,
                                            x_errorcode     => ln_errorcode,
                                            x_msg_count     => ln_msg_count,
                                            x_msg_data      => lc_msg_data,
                                            p_category_rec  => lr_category_rec,
                                            x_category_id   => ln_category_id);
      IF (lc_return_status <> 'S') THEN
        x_error_code := -1;
        x_error_msg  := 'Unable to create PO Category Code Combinations. Error: ' ||
                        lc_msg_data || ' Subclass ' || p_segment5 ||
                        ' will not be added';
        RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
      ELSE
        x_error_code := 0;
        x_error_msg  := 'Category Code Combinations Loaded Successfully';
      END IF;
  ELSIF p_cat = 'B' THEN
      lr_category_rec.SEGMENT1       := p_segment1;
      lr_category_rec.SEGMENT2       := p_segment2;
      lr_category_rec.STRUCTURE_CODE := gc_structure_code;
      lr_category_rec.STRUCTURE_ID   := ln_structure_id;
      lr_category_rec.description    := get_category_description(ln_flex_value_set_id_div,
                                                                 ln_flex_value_set_id_grp,
                                                                 ln_flex_value_set_id_dept,
                                                                 ln_class_value_set_id,
                                                                 ln_sclass_vs_id,
                                                                 ln_flex_value_set_id_potype,
                                                                 ln_flex_value_set_id_unspsc,
                                                                 p_segment1,
                                                                 p_segment2,
                                                                 p_segment3,
                                                                 p_segment4,
                                                                 p_segment5,
                                                                 L_NA_VAL,
                                                                 L_TRADE_VAL,
                                                                 'ITEM_CATEGORIES');
      INV_ITEM_CATEGORY_PUB.Create_Category(p_api_version   => ln_api_version_cc,
                                            x_return_status => lc_return_status,
                                            x_errorcode     => ln_errorcode,
                                            x_msg_count     => ln_msg_count,
                                            x_msg_data      => lc_msg_data,
                                            p_category_rec  => lr_category_rec,
                                            x_category_id   => ln_category_id);
      IF (lc_return_status <> 'S') THEN
        x_error_code := -1;
        x_error_msg  := 'Unable to create INV Category Code Combinations. Error: ' ||
                        lc_msg_data || ' Subclass ' || p_segment5 ||
                        ' will not be added';
        RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
      ELSE
        x_error_code := 0;
        x_error_msg  := 'Category Code Combinations Loaded Successfully';
      END IF;
      lr_category_rec.SEGMENT1       := L_NA_VAL;
      lr_category_rec.SEGMENT2       := L_TRADE_VAL;
      lr_category_rec.STRUCTURE_CODE := gc_structure_code_po;
      lr_category_rec.STRUCTURE_ID   := ln_structure_id_po;
      lr_category_rec.description    := get_category_description(ln_flex_value_set_id_div,
                                                                 ln_flex_value_set_id_grp,
                                                                 ln_flex_value_set_id_dept,
                                                                 ln_class_value_set_id,
                                                                 ln_sclass_vs_id,
                                                                 ln_flex_value_set_id_potype,
                                                                 ln_flex_value_set_id_unspsc,
                                                                 p_segment1,
                                                                 p_segment2,
                                                                 p_segment3,
                                                                 p_segment4,
                                                                 p_segment5,
                                                                 L_NA_VAL,
                                                                 L_TRADE_VAL,
                                                                 'PO_ITEM_CATEGORY');
      INV_ITEM_CATEGORY_PUB.Create_Category(p_api_version   => ln_api_version_cc,
                                            x_return_status => lc_return_status,
                                            x_errorcode     => ln_errorcode,
                                            x_msg_count     => ln_msg_count,
                                            x_msg_data      => lc_msg_data,
                                            p_category_rec  => lr_category_rec,
                                            x_category_id   => ln_category_id);
      IF (lc_return_status <> 'S') THEN
        x_error_code := -1;
        x_error_msg  := 'Unable to create PO Category Code Combinations. Error: ' ||
                        lc_msg_data || ' Subclass ' || p_segment5 ||
                        ' will not be added';
        RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
      ELSE
        x_error_code := 0;
        x_error_msg  := 'Category Code Combinations Loaded Successfully';
      END IF;
    END IF;
EXCEPTION
  WHEN EX_ROLLBACK_END_PROCEDURE THEN
    ROLLBACK;
    XX_COM_ERROR_LOG_PUB.LOG_ERROR(P_PROGRAM_TYPE           => 'CUSTOM API',
                                     P_PROGRAM_NAME           => 'XX_INV_MERC_HIERARCHY_PKG.PROCESS_MERC_HIERARCHY',
                                     P_PROGRAM_ID             => NULL,
                                     P_MODULE_NAME            => 'INV',
                                     P_ERROR_LOCATION         => 'EX_ROLLBACK_END_PROCEDURE EXCEPTION',
                                     P_ERROR_MESSAGE_COUNT    => NULL,
                                     P_ERROR_MESSAGE_CODE     => x_error_code,
                                     P_ERROR_MESSAGE          => x_error_msg,
                                     P_ERROR_MESSAGE_SEVERITY => 'MAJOR',
                                     P_NOTIFY_FLAG            => 'Y',
                                     P_OBJECT_TYPE            => 'Merchandising Hierarchy Interface',
                                     P_OBJECT_ID              => lm_value,
                                     P_ATTRIBUTE1             => lc_hierarchy_level,
                                     P_ATTRIBUTE2             => lc_description,
                                     P_ATTRIBUTE3             => lc_action,
                                     P_RETURN_CODE            => NULL,
                                     P_MSG_COUNT              => NULL);
    RAISE;
END create_od_category;

PROCEDURE CATEGORY_LINK_UPDATE(p_category_id  IN NUMBER,
                               p_structure_id IN NUMBER,
                               p_subclass     IN VARCHAR2) 
 -- +===================================================================================================+
    -- |                                                                                                 |
    -- | Name             : CATEGORY_LINK_UPDATE                                                         |
    -- |                                                                                                 |
    -- | Description      : To recreate the Inv and PO Category based on the reclassification            |
    -- |                                  .                                                              |
    -- |                                                                                                 |
    -- | Parameters       : p_category_id       IN  Category Id					 		   |
    -- |                    p_structure_id      IN  Structure Id				                     |
    -- |                    p_subclass          IN  Subclass				                     |
    -- +=================================================================================================+

IS

v_cnt        NUMBER:=1;   -- Paddy
v_segment1   VARCHAR2(40);
v_segment2   VARCHAR2(40);
v_segment3   VARCHAR2(40);
v_segment4   VARCHAR2(40);
v_segment5   VARCHAR2(40);
v_cat        VARCHAR2(1);
v_error_code NUMBER;
v_error_msg  VARCHAR2(2000);
lv_cat_rec   mtl_categories_b%ROWTYPE;
v_class      VARCHAR2(40);
v_con        varchar2(2000);

BEGIN
  BEGIN
    SELECT *
      INTO lv_cat_rec
      FROM mtl_categories_b
     WHERE structure_id = p_structure_id
       AND segment5 = p_subclass;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_cnt := 0;
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'WHEN others in Category check ' || p_subclass || ' ' ||
                          to_char(p_structure_id));
      RAISE EX_ROLLBACK_END_PROCEDURE;
  END;
  SELECT attribute1
    INTO v_class
    FROM fnd_flex_values
   WHERE flex_value_set_id = ln_sclass_vs_id
     AND flex_value = p_subclass;
  IF lc_hierarchy_level = 'SUBCLASS' THEN
     v_class := lc_link_attribute_n;
  END IF;
  IF v_cnt = 0 THEN
      get_catg_segments(p_subclass,
                        v_class,
                        v_segment1,
                        v_segment2,
                        v_segment3,
                        v_segment4,
                        v_segment5);
      IF p_structure_id = ln_structure_id THEN
         v_cat := 'I';
      ELSIF p_structure_id = ln_structure_id_po THEN
         v_cat := 'P';
      END IF;
      create_od_category(v_segment1,
                         v_segment2,
                         v_segment3,
                         v_segment4,
                         v_segment5,
                         v_cat,
                         v_error_code,
                         v_error_msg);
  ELSE
     get_catg_segments(p_subclass,
                        v_class,
                        v_segment1,
                        v_segment2,
                        v_segment3,
                        v_segment4,
                        v_segment5);
      IF p_structure_id = ln_structure_id THEN
        lv_cat_rec.description := get_category_description(ln_flex_value_set_id_div,
                                                           ln_flex_value_set_id_grp,
                                                           ln_flex_value_set_id_dept,
                                                           ln_class_value_set_id,
                                                           ln_sclass_vs_id,
                                                           ln_flex_value_set_id_potype,
                                                           ln_flex_value_set_id_unspsc,
                                                           v_segment1,
                                                           v_segment2,
                                                           v_segment3,
                                                           v_segment4,
                                                           v_segment5,
                                                           L_NA_VAL,
                                                           L_TRADE_VAL,
                                                           'ITEM_CATEGORIES');
      ELSIF p_structure_id = ln_structure_id_po THEN
        lv_cat_rec.description := get_category_description(ln_flex_value_set_id_div,
                                                           ln_flex_value_set_id_grp,
                                                           ln_flex_value_set_id_dept,
                                                           ln_class_value_set_id,
                                                           ln_sclass_vs_id,
                                                           ln_flex_value_set_id_potype,
                                                           ln_flex_value_set_id_unspsc,
                                                           v_segment1,
                                                           v_segment2,
                                                           v_segment3,
                                                           v_segment4,
                                                           v_segment5,
                                                           L_NA_VAL,
                                                           L_TRADE_VAL,
                                                           'PO_ITEM_CATEGORY');
        v_segment1             := L_NA_VAL;
        v_segment2             := L_TRADE_VAL;
      END IF;
      MTL_CATEGORIES_PKG.Update_Row(X_CATEGORY_ID           => lv_cat_rec.category_id,
                                    X_DESCRIPTION           => lv_cat_rec.description,
                                    X_STRUCTURE_ID          => lv_cat_rec.structure_id,
                                    X_DISABLE_DATE          => lv_cat_rec.disable_date,
                                    X_WEB_STATUS            => lv_cat_rec.web_status, --Bug: 2430879
                                    X_SUPPLIER_ENABLED_FLAG => lv_cat_rec.supplier_enabled_flag, --Bug: 2645153
                                    X_SEGMENT1              => v_segment1,
                                    X_SEGMENT2              => v_segment2,
                                    X_SEGMENT3              => v_segment3,
                                    X_SEGMENT4              => v_segment4,
                                    X_SEGMENT5              => v_segment5,
                                    X_SEGMENT6              => lv_cat_rec.segment6,
                                    X_SEGMENT7              => lv_cat_rec.segment7,
                                    X_SEGMENT8              => lv_cat_rec.segment8,
                                    X_SEGMENT9              => lv_cat_rec.segment9,
                                    X_SEGMENT10             => lv_cat_rec.segment10,
                                    X_SEGMENT11             => lv_cat_rec.segment11,
                                    X_SEGMENT12             => lv_cat_rec.segment12,
                                    X_SEGMENT13             => lv_cat_rec.segment13,
                                    X_SEGMENT14             => lv_cat_rec.segment14,
                                    X_SEGMENT15             => lv_cat_rec.segment15,
                                    X_SEGMENT16             => lv_cat_rec.segment16,
                                    X_SEGMENT17             => lv_cat_rec.segment17,
                                    X_SEGMENT18             => lv_cat_rec.segment18,
                                    X_SEGMENT19             => lv_cat_rec.segment19,
                                    X_SEGMENT20             => lv_cat_rec.segment20,
                                    X_SUMMARY_FLAG          => lv_cat_rec.summary_flag,
                                    X_ENABLED_FLAG          => lv_cat_rec.enabled_flag,
                                    X_START_DATE_ACTIVE     => lv_cat_rec.start_date_active,
                                    X_END_DATE_ACTIVE       => lv_cat_rec.end_date_active,
                                    X_ATTRIBUTE_CATEGORY    => lv_cat_rec.attribute_category,
                                    X_ATTRIBUTE1            => lv_cat_rec.attribute1,
                                    X_ATTRIBUTE2            => lv_cat_rec.attribute2,
                                    X_ATTRIBUTE3            => lv_cat_rec.attribute3,
                                    X_ATTRIBUTE4            => lv_cat_rec.attribute4,
                                    X_ATTRIBUTE5            => lv_cat_rec.attribute5,
                                    X_ATTRIBUTE6            => lv_cat_rec.attribute6,
                                    X_ATTRIBUTE7            => lv_cat_rec.attribute7,
                                    X_ATTRIBUTE8            => lv_cat_rec.attribute8,
                                    X_ATTRIBUTE9            => lv_cat_rec.attribute9,
                                    X_ATTRIBUTE10           => lv_cat_rec.attribute10,
                                    X_ATTRIBUTE11           => lv_cat_rec.attribute11,
                                    X_ATTRIBUTE12           => lv_cat_rec.attribute12,
                                    X_ATTRIBUTE13           => lv_cat_rec.attribute13,
                                    X_ATTRIBUTE14           => lv_cat_rec.attribute14,
                                    X_ATTRIBUTE15           => lv_cat_rec.attribute15,
                                    X_LAST_UPDATE_DATE      => sysdate,
                                    X_LAST_UPDATED_BY       => fnd_global.user_id,
                                    X_LAST_UPDATE_LOGIN     => fnd_global.login_id);
  END IF;
  EXCEPTION
    WHEN EX_ROLLBACK_END_PROCEDURE THEN
      ROLLBACK;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(P_PROGRAM_TYPE           => 'CUSTOM API',
                                     P_PROGRAM_NAME           => 'XX_INV_MERC_HIERARCHY_PKG.PROCESS_MERC_HIERARCHY',
                                     P_PROGRAM_ID             => NULL,
                                     P_MODULE_NAME            => 'INV',
                                     P_ERROR_LOCATION         => 'EX_ROLLBACK_END_PROCEDURE EXCEPTION',
                                     P_ERROR_MESSAGE_COUNT    => NULL,
                                     P_ERROR_MESSAGE_CODE     => v_error_code,
                                     P_ERROR_MESSAGE          => v_error_msg,
                                     P_ERROR_MESSAGE_SEVERITY => 'MAJOR',
                                     P_NOTIFY_FLAG            => 'Y',
                                     P_OBJECT_TYPE            => 'Merchandising Hierarchy Interface',
                                     P_OBJECT_ID              => lm_value,
                                     P_ATTRIBUTE1             => lc_hierarchy_level,
                                     P_ATTRIBUTE2             => lc_description,
                                     P_ATTRIBUTE3             => lc_action,
                                     P_RETURN_CODE            => NULL,
                                     P_MSG_COUNT              => NULL);
  END CATEGORY_LINK_UPDATE;


  PROCEDURE category_update(p_category_id IN NUMBER,
                            p_div_vs_id   IN NUMBER,
                            p_grp_vs_id   IN NUMBER,
                            p_dep_vs_id   IN NUMBER,
                            p_cls_vs_id   IN NUMBER,
                            p_scl_vs_id   IN NUMBER,
                            p_pot_vs_id   IN NUMBER,
                            p_uns_vs_id   IN NUMBER,
                            p_na_val      IN VARCHAR2,
                            p_trade_val   IN VARCHAR2,
                            p_action      IN VARCHAR2,
                            x_err_code    OUT NOCOPY NUMBER,
                            x_err_msg     OUT NOCOPY VARCHAR2)
 -- +===================================================================================================+
    -- |                                                                                                 |
    -- | Name             : CATEGORY_UPDATE                                                              |
    -- |                                                                                                 |
    -- | Description      : To Update Inventory and PO Category    				               |
    -- |                                  .                                                              |

    -- | Parameters       : p_category_id       IN  Category Id					 		   |
    -- | 			    p_div_vs_id         IN  Division   Value set id			 		   |
    -- |                    p_grp_vs_id         IN  Group      Value set id			 		   |
    -- |                    p_dep_vs_id         IN  Department Value set id			 		   |
    -- |                    p_cls_vs_id         IN  Class      Value set id			 		   |
    -- |                    p_scl_vs_id         IN  Subclass   Value set id			 		   |
    -- |                    p_pot_vs_id         IN  PO Type    Value set id			 		   |
    -- |                    p_uns_vs_id         IN  UNS        Value set id			 		   |
    -- |                    p_na		      IN  NA     				                           |
    -- |                    p_trd		      IN  Trade   			                           |
    -- |                    p_action	      IN  Create/Update  		                           |
    -- |                    x_err_code          OUT Error Code				                     |
    -- |                    x_err_msg           IN  Error Mesg				                     |
    -- +=================================================================================================+
 IS

 lr_mcb_typ    	  	mtl_categories_b%ROWTYPE;
 lr_category_rec 		Inv_Item_Category_Pub.CATEGORY_REC_TYPE;
 v_structure     		VARCHAR2(30);

 BEGIN
   BEGIN
     SELECT *
       INTO lr_mcb_typ
       FROM mtl_categories_b mcb
      WHERE mcb.category_id = p_category_id;
      x_err_code := 0;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        x_err_msg := SQLERRM;
        RAISE EX_ROLLBACK_END_PROCEDURE;
      WHEN OTHERS THEN
        x_err_code := -1;
        x_err_msg  := SQLERRM || ' ' ||'WHEN OTHERS EXCEPTION In Procedure GET_CATEGORY_DETAILS ' ||
                      TO_CHAR(p_category_id);
        RAISE EX_ROLLBACK_END_PROCEDURE; --LogErr;
   END;

   IF lr_mcb_typ.STRUCTURE_ID = ln_structure_id THEN
      lr_category_rec.STRUCTURE_CODE := 'ITEM_CATEGORIES';
      v_structure                    := 'ITEM_CATEGORIES';
   ELSIF lr_mcb_typ.STRUCTURE_ID = ln_structure_id_po THEN
      lr_category_rec.STRUCTURE_CODE := 'PO_ITEM_CATEGORY';
      v_structure                    := 'PO_ITEM_CATEGORY';
   END IF;

   IF p_action = 'C' THEN
      lr_category_rec.description := get_category_description(p_div_vs_id,
                                                              p_grp_vs_id,
                                                              p_dep_vs_id,
                                                              p_cls_vs_id,
                                                              p_scl_vs_id,
                                                              p_pot_vs_id,
                                                              p_uns_vs_id,
                                                              lr_mcb_typ.SEGMENT1,
                                                              lr_mcb_typ.SEGMENT2,
                                                              lr_mcb_typ.SEGMENT3,
                                                              lr_mcb_typ.SEGMENT4,
                                                              lr_mcb_typ.SEGMENT5,
                                                              P_NA_VAL,
                                                              P_TRADE_VAL,
                                                              v_structure);
    END IF;

    lr_category_rec.category_id           := lr_mcb_typ.category_id;
    lr_category_rec.STRUCTURE_ID          := lr_mcb_typ.STRUCTURE_ID;
    lr_category_rec.SUMMARY_FLAG          := lr_mcb_typ.SUMMARY_FLAG;
    lr_category_rec.ENABLED_FLAG          := 'Y';
    lr_category_rec.START_DATE_ACTIVE     := lr_mcb_typ.START_DATE_ACTIVE;
    lr_category_rec.DISABLE_DATE          := NULL;
    lr_category_rec.END_DATE_ACTIVE       := NULL;
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

    IF p_action = 'D' THEN
       lr_category_rec.ENABLED_FLAG    := 'N';
       lr_category_rec.DISABLE_DATE    := SYSDATE;
       lr_category_rec.END_DATE_ACTIVE := SYSDATE;
    END IF;
   
    INV_ITEM_CATEGORY_PUB.UPDATE_CATEGORY(p_api_version   => ln_api_version_uc,
                                          p_init_msg_list => lc_init_msg_list,
                                          p_commit        => lc_commit,
                                          x_return_status => lc_return_status,
                                          x_errorcode     => ln_errorcode,
                                          x_msg_count     => ln_msg_count,
                                          x_msg_data      => lc_msg_data,
                                          p_category_rec  => lr_category_rec);
    IF (lc_return_status <> 'S') THEN
        x_err_code := -1;
        x_err_msg  := 'Failed to update description for category code combination for ' ||
                    TO_CHAR(lr_category_rec.category_id) || ' ' ||
                    lc_msg_data;
        RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
    ELSE
        x_err_code := 0;
        x_err_msg  := 'Description for category code combinations updated successfully';
    END IF;
  EXCEPTION
    WHEN EX_ROLLBACK_END_PROCEDURE THEN
      ROLLBACK;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(P_PROGRAM_TYPE           => 'CUSTOM API',
                                     P_PROGRAM_NAME           => 'XX_INV_MERC_HIERARCHY_PKG.PROCESS_MERC_HIERARCHY',
                                     P_PROGRAM_ID             => NULL,
                                     P_MODULE_NAME            => 'INV',
                                     P_ERROR_LOCATION         => 'EX_ROLLBACK_END_PROCEDURE EXCEPTION',
                                     P_ERROR_MESSAGE_COUNT    => NULL,
                                     P_ERROR_MESSAGE_CODE     => x_err_code,
                                     P_ERROR_MESSAGE          => x_err_msg,
                                     P_ERROR_MESSAGE_SEVERITY => 'MAJOR',
                                     P_NOTIFY_FLAG            => 'Y',
                                     P_OBJECT_TYPE            => 'Merchandising Hierarchy Interface',
                                     P_OBJECT_ID              => lm_value,
                                     P_ATTRIBUTE1             => lc_hierarchy_level,
                                     P_ATTRIBUTE2             => lc_description,
                                     P_ATTRIBUTE3             => lc_action,
                                     P_RETURN_CODE            => NULL,
                                     P_MSG_COUNT              => NULL);
      RAISE;
  END category_update;

  PROCEDURE PROCESS_MERC_HIERARCHY(p_hierarchy_level           IN VARCHAR2,
                                   p_value                     IN NUMBER,
                                   p_description               IN VARCHAR2,
                                   p_action                    IN VARCHAR2,
                                   p_division_number           IN VARCHAR2,
                                   p_group_number              IN VARCHAR2,
                                   p_dept_number               IN VARCHAR2,
                                   p_class_number              IN VARCHAR2,
                                   p_dept_forecastingind       IN VARCHAR2,
                                   p_dept_aipfilterind         IN VARCHAR2 DEFAULT NULL,
                                   p_dept_planningind          IN VARCHAR2,
                                   p_dept_noncodeind           IN VARCHAR2,
                                   p_dept_ppp_ind              IN VARCHAR2,
                                   p_class_nbrdaysamd          IN NUMBER,
                                   p_class_fifthmrkdwnprocsscd IN VARCHAR2,
                                   p_class_prczcostflg         IN VARCHAR2,
                                   p_class_prczpriceflag       IN VARCHAR2,
                                   p_class_priczlistflag       IN VARCHAR2,
                                   p_class_furnitureflag       IN VARCHAR2,
                                   p_class_aipfilterind        IN VARCHAR2 DEFAULT NULL,
                                   p_subclass_defaulttaxcat    IN VARCHAR2,
                                   p_subclass_globalcontentind IN VARCHAR2,
                                   p_subclass_aipfilterind     IN VARCHAR2 DEFAULT NULL,
                                   p_subclass_ppp_ind          IN VARCHAR2,
                                   x_error_msg                 OUT VARCHAR2,
                                   x_error_code                OUT NUMBER) 
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
-- |                    p_value                       The Input value to be ADDED,MODIFIED or DELETED.                    |
-- |                    p_description                 The description of the Input value.                                 |
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
    -- Division Cursor

    CURSOR get_ccc_div(lc_segment1 VARCHAR2) IS
      SELECT category_id
        FROM mtl_categories_b
       WHERE (structure_id = ln_structure_id)
         AND segment1 = lc_segment1;

    -- Group Cursor

    Cursor get_ccc_grp(lc_segment1 VARCHAR2, lc_segment2 VARCHAR2) IS
      SELECT category_id, structure_id, segment5
        FROM mtl_categories_b
       WHERE (structure_id = ln_structure_id)
         AND segment1 = lc_segment1
         AND segment2 = lc_segment2;

    -- Department Cursor

    Cursor get_ccc_dept(lc_segment2 VARCHAR2, lc_segment3 VARCHAR2) IS
      SELECT category_id, structure_id, segment5
        FROM mtl_categories_b
       WHERE (structure_id in (ln_structure_id, ln_structure_id_po))
         AND (segment2 = lc_segment2 OR segment2 = L_TRADE_VAL)
         AND segment3 = lc_segment3;

    -- Class Cursor

    Cursor get_ccc_cla(lc_segment3 VARCHAR2, lc_segment4 VARCHAR2) IS
      SELECT category_id, structure_id, segment5
        FROM mtl_categories_b
       WHERE (structure_id in (ln_structure_id, ln_structure_id_po))
         AND segment3 = lc_segment3
         AND segment4 = lc_segment4;

    -- Subclass Cursor

    Cursor get_ccc_sclas(lc_segment4 VARCHAR2, lc_segment5 VARCHAR2) IS
      SELECT category_id, structure_id, segment5
        FROM mtl_categories_b
       WHERE (structure_id in (ln_structure_id, ln_structure_id_po))
         AND segment4 = lc_segment4
         AND segment5 = lc_segment5;

    --To get all the Groups belonging to a Division

    CURSOR get_grp_val(p_vs_id NUMBER, p_vs_val VARCHAR2) IS
      SELECT flex_value
        FROM fnd_flex_values
       WHERE flex_value_set_id = p_vs_id
         AND attribute1 = p_vs_val;

    --To get all the Departments belonging to a Group

    CURSOR get_depart_val(p_vs_id NUMBER, p_vs_val VARCHAR2) IS
      SELECT flex_value
        FROM fnd_flex_values
       WHERE flex_value_set_id = p_vs_id
         AND attribute1 = p_vs_val;

    --To get all the Classes belonging to a Department

    CURSOR get_class_val(p_vs_id NUMBER, p_vs_val VARCHAR2) IS
      SELECT flex_value
        FROM fnd_flex_values
       WHERE flex_value_set_id = p_vs_id
         AND attribute1 = p_vs_val;

    --To get all the Subclasses belonging to a Class

    CURSOR get_subclass_val(p_vs_id NUMBER, p_vs_val VARCHAR2) IS
      SELECT flex_value
        FROM fnd_flex_values
       WHERE flex_value_set_id = p_vs_id
         AND attribute1 = p_vs_val;

    --To get the parent value of the given record

    CURSOR lcu_get_parent_value(p_vs_id NUMBER, p_vs_value VARCHAR2) IS
      SELECT attribute1
        FROM fnd_flex_values
       WHERE flex_value_set_id = p_vs_id
         AND flex_value = p_vs_value;

    --To get the enabled flag for the given record

    CURSOR lcu_get_enabled_flag(ln_flex_val_set_id NUMBER, lc_value VARCHAR2) IS
      SELECT *
        FROM fnd_flex_values
       WHERE flex_value_set_id = ln_flex_val_set_id
         AND flex_value = lc_value;

    --To get the Key flexfield structure number for the given structure_code 

    CURSOR lcu_get_structure_id(p_flex_structure_code VARCHAR2) IS
      SELECT id_flex_num
        FROM fnd_id_flex_structures
       WHERE id_flex_code = L_KF_CODE
         AND id_flex_structure_code = p_flex_structure_code;

    CURSOR lcu_get_all_vs_id IS
      SELECT flex_value_set_id, flex_value_set_name
        FROM fnd_flex_value_sets
       WHERE flex_value_set_name IN
             (gc_div_vs_name, gc_group_vs_name, gc_dept_vs_name,
              gc_class_vs_name, gc_subclass_vs_name, gc_unspsc_vs_name,
              gc_potype_vs_name);

  BEGIN
    x_error_msg            := NULL;
    x_error_code           := 0;
    lr_ffv_typ             := NULL;
    lc_attribute1          := NULL;
    lc_attribute2          := NULL;
    lc_attribute3          := NULL;
    lc_attribute4          := NULL;
    lc_attribute5          := NULL;
    lc_attribute6          := NULL;
    lc_attribute7          := NULL;
    lc_attribute8          := NULL;
    lc_attribute9          := NULL;
    lc_attribute10         := NULL;
    lc_start_date_active   := NULL;
    lc_end_date_active     := NULL;
    lc_summary_flag        := NULL;
    lc_enabled_flag        := NULL;
    lc_value_category      := NULL;
    lc_action              := NULL;
    lc_flex_value_set_name := NULL;
    ln_flex_value_set_id   := NULL;
    lc_flex_value_set_name := NULL;
    lc_link_attribute_n    := NULL;
    lc_link_attribute_o    := NULL;
    lc_link_change         := NULL;
    lc_hierarchy_level     := NULL;
    lm_value               := NULL;
    lc_description         := NULL;
    lc_hierarchy_level     := p_hierarchy_level;
    lm_value               := TO_CHAR(p_value);
    lc_description         := p_description;

    --
    -- Validate Parameters Action Code,p_value etc
    --

    IF (p_action IS NULL) THEN
      x_error_code := -1;
      x_error_msg  := 'Action Criteria is Null,Unable to Perform any action, Ending Procedure PROCESS_MERC_HIERARCHY';
      RAISE EX_END_PROCEDURE;
    ELSIF (p_action <> 'C' AND p_action <> 'D') THEN
      x_error_code := -1;
      x_error_msg  := 'Invalid Action : Action should be either C OR D';
      RAISE EX_END_PROCEDURE;
    ELSIF (p_hierarchy_level IS NULL) THEN
      x_error_code := -1;
      x_error_msg  := 'Error: HIERARCHY Level is NULL';
      RAISE EX_END_PROCEDURE;
    ELSIF (p_value IS NULL) THEN
      x_error_code := -1;
      x_error_msg  := 'Parameter p_value is NULL.Ending Procedure PROCESS_MERC_HIERARCHY';
      RAISE EX_END_PROCEDURE;
    END IF;

    IF NOT (p_hierarchy_level = 'DIVISION' OR p_hierarchy_level = 'GROUP' OR
        p_hierarchy_level = 'DEPARTMENT' OR p_hierarchy_level = 'CLASS' OR
        p_hierarchy_level = 'SUBCLASS') THEN
      x_error_code := -1;
      x_error_msg  := 'Error : Invalid Value for Hierarchy Level. It should be Either DIVISION/GROUP/DEPARTMENT/CLASS/SUBCLASS';
      RAISE EX_END_PROCEDURE;
    END IF;

    --
    -- End Validate Parameters Action Code,p_value etc
    --
    --To get the Key flexfield structure number for ITEM_CATEGORIES structure_code 
    --

    OPEN lcu_get_structure_id(p_flex_structure_code => gc_structure_code);
    FETCH lcu_get_structure_id INTO ln_structure_id;
    IF (lcu_get_structure_id%NOTFOUND) THEN
      x_error_code := -1;
      x_error_msg  := 'Unable to get KFF structure id for ITEM_CATEGORIES structure_code.Ending Procedure PROCESS_MERC_HIERARCHY';
      CLOSE lcu_get_structure_id;
      RAISE EX_END_PROCEDURE;
    END IF;
    CLOSE lcu_get_structure_id;

    --   
    --To get the Key flexfield structure number for PO_ITEM_CATEGORY structure_code 
    --

    OPEN lcu_get_structure_id(p_flex_structure_code => gc_structure_code_po);
    FETCH lcu_get_structure_id INTO ln_structure_id_po;
    IF (lcu_get_structure_id%NOTFOUND) THEN
      x_error_code := -1;
      x_error_msg  := 'Unable to get KFF structure id for PO ITEM_CATEGORY structure_code.Ending Procedure PROCESS_MERC_HIERARCHY';
      CLOSE lcu_get_structure_id;
      RAISE EX_END_PROCEDURE; --LogErr;
    END IF;
    CLOSE lcu_get_structure_id;

    --
    --To get the value set id for all the value sets of Categories
    --

    FOR lcu_get_all_vs_id_rec IN lcu_get_all_vs_id LOOP

      IF (lcu_get_all_vs_id_rec.flex_value_set_name = gc_div_vs_name) THEN
        ln_flex_value_set_id_div := lcu_get_all_vs_id_rec.flex_value_set_id;
      ELSIF (lcu_get_all_vs_id_rec.flex_value_set_name = gc_group_vs_name) THEN
        ln_flex_value_set_id_grp := lcu_get_all_vs_id_rec.flex_value_set_id;
      ELSIF (lcu_get_all_vs_id_rec.flex_value_set_name = gc_dept_vs_name) THEN
        ln_flex_value_set_id_dept := lcu_get_all_vs_id_rec.flex_value_set_id;
      ELSIF (lcu_get_all_vs_id_rec.flex_value_set_name = gc_class_vs_name) THEN
        ln_flex_value_set_id_class := lcu_get_all_vs_id_rec.flex_value_set_id;
        ln_class_value_set_id      := lcu_get_all_vs_id_rec.flex_value_set_id;
      ELSIF (lcu_get_all_vs_id_rec.flex_value_set_name =
            gc_subclass_vs_name) THEN
        ln_sclass_vs_id := lcu_get_all_vs_id_rec.flex_value_set_id;
      ELSIF (lcu_get_all_vs_id_rec.flex_value_set_name = gc_unspsc_vs_name) THEN
        ln_flex_value_set_id_unspsc := lcu_get_all_vs_id_rec.flex_value_set_id;
      ELSIF (lcu_get_all_vs_id_rec.flex_value_set_name = gc_potype_vs_name) THEN
        ln_flex_value_set_id_potype := lcu_get_all_vs_id_rec.flex_value_set_id;
      END IF;

    END LOOP;

    IF (   ln_flex_value_set_id_div 	IS NULL
	  OR ln_flex_value_set_id_grp 	IS NULL
        OR ln_flex_value_set_id_dept 	IS NULL 
        OR ln_flex_value_set_id_class 	IS NULL
        OR ln_sclass_vs_id 			IS NULL 
        OR ln_flex_value_set_id_unspsc 	IS NULL 
        OR ln_flex_value_set_id_potype 	IS NULL) THEN

        x_error_msg := 'Failed to get Value Set Id';
        RAISE EX_ROLLBACK_END_PROCEDURE;

    END IF;

    IF p_hierarchy_level = 'DIVISION' THEN
       ln_flex_value_set_id   := ln_flex_value_set_id_div;
       lc_flex_value_set_name := 'XX_GI_DIVISION_VS';
    ELSIF p_hierarchy_level = 'GROUP' THEN
       ln_flex_value_set_id   := ln_flex_value_set_id_grp;
       lc_flex_value_set_name := 'XX_GI_GROUP_VS';
    ELSIF p_hierarchy_level = 'DEPARTMENT' THEN
       ln_flex_value_set_id   := ln_flex_value_set_id_dept;
       lc_flex_value_set_name := 'XX_GI_DEPARTMENT_VS';
    ELSIF p_hierarchy_level = 'CLASS' THEN
       ln_flex_value_set_id   := ln_class_value_set_id;
       lc_flex_value_set_name := 'XX_GI_CLASS_VS';
    ELSIF p_hierarchy_level = 'SUBCLASS' THEN
       ln_flex_value_set_id   := ln_sclass_vs_id;
       lc_flex_value_set_name := 'XX_GI_SUBCLASS_VS';
    END IF;

    -- End of get the value set id for all the value sets of Categories
    --
    --To get the delimiter for the structure ITEM_CATEGORIES

    lc_item_delimiter := fnd_flex_ext.get_delimiter(L_APPL_SHORT_NAME,
                                                    L_KF_CODE,
                                                    ln_structure_id);
    IF (lc_item_delimiter IS NULL) THEN
        x_error_msg  := 'Failed to get Item Delimiter';
        x_error_code := -1;
        RAISE EX_END_PROCEDURE; --LogErr;
    END IF;

    --
    --To get the delimiter for the structure PO_ITEM_CATEGORY
    --

    lc_po_delimiter := fnd_flex_ext.get_delimiter(L_APPL_SHORT_NAME,
                                                  L_KF_CODE,
                                                  ln_structure_id_po);
    IF (lc_po_delimiter IS NULL) THEN
        x_error_msg  := 'Failed to get PO Delimiter';
        x_error_code := -1;
        RAISE EX_END_PROCEDURE; --LogErr;
    END IF;

    --
    -- Check Enabled Flag for TRADE value 
    --

    OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_potype,
                              lc_value           => L_TRADE_VAL);
    FETCH lcu_get_enabled_flag  INTO lr_ff_rec;

    IF (lcu_get_enabled_flag%NOTFOUND) THEN
      x_error_code := -1;
      x_error_msg  := 'Item Type value - TRADE does not exists';
      CLOSE lcu_get_enabled_flag;
      RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
    END IF;

    CLOSE lcu_get_enabled_flag;

    -- If the value TRADE is not enabled error out

    IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
        NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN
       x_error_code := -1;
       x_error_msg  := 'Item Type value - TRADE is disabled';
       RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
    END IF;

    --Get enabled flag and end_date_active for the value NA

    OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_unspsc,
                              lc_value           => L_NA_VAL);
    FETCH lcu_get_enabled_flag INTO lr_ff_rec;
    IF (lcu_get_enabled_flag%NOTFOUND) THEN
       x_error_code := -1;
       x_error_msg  := 'UNSPSC Code value-NA does not exists';
       RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
    END IF;
   
    CLOSE lcu_get_enabled_flag;

    -- If the value NA is not enabled error out

    IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
        NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN
        x_error_code := -1;
        x_error_msg  := 'UNSPSC Code value-NA is disabled';
        RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
    END IF;

    --
    -- Start action based in p_action
    --

    IF (p_action = 'C') THEN

       -- check if the value set is GROUP then p_division_number should not be null

      IF (p_hierarchy_level = 'GROUP' AND p_division_number IS NULL) THEN

         x_error_msg  := 'For Hierarchy Level ' || p_hierarchy_level || ': ' ||
                         'Division No should be populated';
         x_error_code := -1;
         RAISE EX_END_PROCEDURE; --LogErr;

        -- check if the value set is 'DEPARTMENT' then p_group_number should not be null
 
      ELSIF (p_hierarchy_level = 'DEPARTMENT' AND p_group_number IS NULL) THEN
    
         x_error_msg  := 'For Hierarchy Level ' || p_hierarchy_level || ': ' ||
                        'Group No should be populated';
         x_error_code := -1;
         RAISE EX_END_PROCEDURE; --LogErr;

        -- check if the value set is CLASS  then p_dept_number should not be null

      ELSIF (p_hierarchy_level = 'CLASS' AND p_dept_number IS NULL) THEN

         x_error_msg  := 'For Hierarchy Level ' || p_hierarchy_level || ': ' ||
                        'Dept No should be populated';
         x_error_code := -1;
         RAISE EX_END_PROCEDURE; --LogErr;

        -- check if the value set is SUBCLASS  then p_class_number should not be null
      ELSIF (p_hierarchy_level = 'SUBCLASS' AND p_class_number IS NULL) THEN

         x_error_msg  := 'For Hierarchy Level ' || p_hierarchy_level || ': ' ||
                        'Class No should be populated';
         x_error_code := -1;
         RAISE EX_END_PROCEDURE; --LogErr;
   
      END IF;

      --
      -- Get all the details for the given value from flex values
      --

      OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id,
                                lc_value           => TO_CHAR(p_value));
      FETCH lcu_get_enabled_flag INTO lr_ffv_typ;

      -- If record does not exist

      IF (lcu_get_enabled_flag%NOTFOUND) THEN
        lc_enabled_flag := 'X';
      END IF;
      CLOSE lcu_get_enabled_flag;

      lc_attribute1        := lr_ffv_typ.attribute1;
      lc_attribute2        := lr_ffv_typ.attribute2;
      lc_attribute3        := lr_ffv_typ.attribute3;
      lc_attribute4        := lr_ffv_typ.attribute4;
      lc_attribute5        := lr_ffv_typ.attribute5;
      lc_attribute6        := lr_ffv_typ.attribute6;
      lc_attribute7        := lr_ffv_typ.attribute7;
      lc_attribute8        := lr_ffv_typ.attribute8;
      lc_attribute9        := lr_ffv_typ.attribute9;
      lc_attribute10       := lr_ffv_typ.attribute10;
      lc_start_date_active := TO_CHAR(lr_ffv_typ.start_date_active,'YYYY/MM/DD HH24:MI:SS');
      lc_end_date_active   := TO_CHAR(lr_ffv_typ.end_date_active,'YYYY/MM/DD HH24:MI:SS');
      lc_summary_flag      := lr_ffv_typ.summary_flag;
      lc_enabled_flag      := lr_ffv_typ.enabled_flag;
      lc_value_category    := lr_ffv_typ.value_category;

      /*==================================================================+
      | Set the action as per the scenario.                               |
      |   1. If Input value exists in value set and enabled     -- UPDATE |
      |   2. If Input value exists in value set and not enabled -- ENABLE |
      |   3. If Input value does not exist in value set         -- ADD    |
      +==================================================================*/

      IF (NVL(lr_ffv_typ.enabled_flag, 'X') = 'Y' AND
          NVL(lr_ffv_typ.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN
  
          lc_action := 'UPDATE';
  
      ELSIF (NVL(lr_ffv_typ.enabled_flag, 'X') = 'N' OR
            NVL(lr_ffv_typ.end_date_active, TRUNC(SYSDATE + 1)) < TRUNC(SYSDATE)) THEN

          lc_action          := 'ENABLE';
          lc_end_date_active := NULL;
          lc_enabled_flag    := 'Y';

      ELSIF NVL(lr_ffv_typ.enabled_flag, 'X') = 'X' THEN

          lc_action            := 'ADD';
          lc_start_date_active := TO_CHAR(SYSDATE, 'YYYY/MM/DD HH24:MI:SS');
          lc_end_date_active   := NULL;
          lc_summary_flag      := 'N';
          lc_enabled_flag      := 'Y';
          lc_value_category    := lc_flex_value_set_name;
    
      END IF;

      /*==============================================================+
      | Determine if the category chain has to be updated             |
      +==============================================================*/

      IF p_hierarchy_level = 'GROUP' THEN
        IF p_division_number <> NVL(lr_ffv_typ.attribute1,'-1') THEN
          lc_link_attribute_n := p_division_number;
          lc_link_attribute_o := lr_ffv_typ.attribute1;
          lc_link_change      := 'Y';
        ELSE
          lc_link_attribute_n := p_division_number;
          lc_link_attribute_o := p_division_number;
          lc_link_change      := 'N';
        END IF;
      ELSIF p_hierarchy_level = 'DEPARTMENT' THEN
        IF p_group_number <> NVL(lr_ffv_typ.attribute1,'-1') THEN
          lc_link_attribute_n := p_group_number;
          lc_link_attribute_o := lr_ffv_typ.attribute1;
          lc_link_change      := 'Y';
        ELSE
          lc_link_attribute_n := p_group_number;
          lc_link_attribute_o := p_group_number;
          lc_link_change      := 'N';
        END IF;
      ELSIF p_hierarchy_level = 'CLASS' THEN
        IF p_dept_number <> NVL(lr_ffv_typ.attribute1,'-1') THEN
          lc_link_attribute_n := p_dept_number;
          lc_link_attribute_o := lr_ffv_typ.attribute1;
          lc_link_change      := 'Y';
        ELSE
          lc_link_attribute_n := p_dept_number;
          lc_link_attribute_o := p_dept_number;
          lc_link_change      := 'N';
        END IF;
      ELSIF p_hierarchy_level = 'SUBCLASS' THEN
        IF p_class_number <> NVL(lr_ffv_typ.attribute1,'-1') THEN
          lc_link_attribute_n := p_class_number;
          lc_link_attribute_o := lr_ffv_typ.attribute1;
          lc_link_change      := 'Y';
        ELSE
          lc_link_attribute_n := p_class_number;
          lc_link_attribute_o := p_class_number;
          lc_link_change      := 'N';
        END IF;
      END IF;

      --
      -- Check if parent values exist and are enabled
      --

      IF p_hierarchy_level = 'GROUP' THEN
 
         lc_attribute1 := lc_link_attribute_n;
 
         --Get enabled flag and end_date_active for division number provided as IN Parameter

         OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_div,
                                   lc_value           => lc_link_attribute_n);
         FETCH lcu_get_enabled_flag INTO lr_ff_rec;
         IF (lcu_get_enabled_flag%NOTFOUND) THEN
             x_error_code := -1;
             x_error_msg  := 'Failed to get DIVISION ' || lc_link_attribute_n ||' for Group ' || to_char(p_value);
             CLOSE lcu_get_enabled_flag;
             RAISE EX_END_PROCEDURE; --LogErr;
         END IF;
         CLOSE lcu_get_enabled_flag;
  
         -- If this division is not enabled error out

         IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
            NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN
            x_error_code := -1;
            x_error_msg  := lc_link_attribute_n || ' Division is disabled';
            RAISE EX_END_PROCEDURE; --LogErr;
         END IF;

      ELSIF p_hierarchy_level = 'DEPARTMENT' THEN

         lc_attribute1 := lc_link_attribute_n;
         lc_attribute3 := p_dept_planningind;
         lc_attribute4 := p_dept_forecastingind;
         lc_attribute5 := p_dept_noncodeind;
         lc_attribute6 := p_dept_ppp_ind;
         lc_attribute9 := p_dept_aipfilterind;
      
         --Get enabled flag and end_date_active for group number provided in the IN parameter
 
         OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_grp,
                                   lc_value           => lc_link_attribute_n);
         FETCH lcu_get_enabled_flag INTO lr_ff_rec;
         IF (lcu_get_enabled_flag%NOTFOUND) THEN
             x_error_code := -1;
             x_error_msg  := 'Failed to get Group ' || lc_link_attribute_n ||' for Dept ' || to_char(p_value);
             CLOSE lcu_get_enabled_flag;
             RAISE EX_END_PROCEDURE; --LogErr;
         END IF;
         CLOSE lcu_get_enabled_flag;

         -- If this group is not enabled error out
         IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
            NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN
            x_error_code := -1;
            x_error_msg  := lc_link_attribute_n || ' Group is disabled';
            RAISE EX_END_PROCEDURE; --LogErr;
         END IF;

      ELSIF p_hierarchy_level = 'CLASS' THEN

         lc_attribute1 := lc_link_attribute_n;
         lc_attribute3 := TO_CHAR(p_class_nbrdaysamd);
         lc_attribute4 := p_class_fifthmrkdwnprocsscd;
         lc_attribute5 := p_class_prczcostflg;
         lc_attribute6 := p_class_prczpriceflag;
         lc_attribute7 := p_class_priczlistflag;
         lc_attribute8 := p_class_furnitureflag;
         lc_attribute9 := p_class_aipfilterind;

         --Get enabled flag and end_date_active for department number provided as IN Parameter

         OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_dept,
                                   lc_value           => lc_link_attribute_n);
         FETCH lcu_get_enabled_flag INTO lr_ff_rec;
         IF (lcu_get_enabled_flag%NOTFOUND) THEN
             x_error_code := -1;
             x_error_msg  := 'Failed to get Dept ' || lc_link_attribute_n ||' for Class ' || to_char(p_value);
             CLOSE lcu_get_enabled_flag;
             RAISE EX_END_PROCEDURE; --LogErr;
         END IF;
         CLOSE lcu_get_enabled_flag;

         -- If this department is not enabled error out
 
         IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
            NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN
            x_error_code := -1;
            x_error_msg  := lc_link_attribute_n || ' Dept is disabled';
            RAISE EX_END_PROCEDURE; --LogErr;
         END IF;

      ELSIF p_hierarchy_level = 'SUBCLASS' THEN

         lc_attribute1  := lc_link_attribute_n;
         lc_attribute6  := p_subclass_ppp_ind;
         lc_attribute8  := p_subclass_globalcontentind;
         lc_attribute9  := p_subclass_aipfilterind;
         lc_attribute10 := p_subclass_defaulttaxcat;

         --Get enabled flag and end_date_active for class number IN Parameter

         OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_class_value_set_id,
                                   lc_value           => lc_link_attribute_n);
         FETCH lcu_get_enabled_flag  INTO lr_ff_rec;
         IF (lcu_get_enabled_flag%NOTFOUND) THEN
             x_error_code := -1;
             x_error_msg  := 'Failed to get Class ' || lc_link_attribute_n ||' for Subclass ' || to_char(p_value);
             CLOSE lcu_get_enabled_flag;
             RAISE EX_END_PROCEDURE; --LogErr;
         END IF;
         CLOSE lcu_get_enabled_flag;
  
         -- If this class is not enabled error out

         IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
            NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN
            x_error_code := -1;
            x_error_msg  := lc_link_attribute_n || ' class is disabled';
            RAISE EX_END_PROCEDURE; --LogErr;
         END IF;
 
         -- Get Department Number for the 'Class Number' IN Parameter

         OPEN lcu_get_parent_value(p_vs_id    => ln_class_value_set_id,
                                  p_vs_value => lc_link_attribute_n);
         FETCH lcu_get_parent_value INTO lc_dept_val;
         IF (lcu_get_parent_value%NOTFOUND) THEN
             x_error_code := -1;
             x_error_msg  := 'Failed to get Dept for the class ' || lc_link_attribute_n;
             CLOSE lcu_get_parent_value;
             RAISE EX_END_PROCEDURE;
         END IF;
         CLOSE lcu_get_parent_value;

        --Get enabled flag and end_date_active for department number obtained above

         OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id_dept,
                                  lc_value           => lc_dept_val);
         FETCH lcu_get_enabled_flag INTO lr_ff_rec;
         IF (lcu_get_enabled_flag%NOTFOUND) THEN
             x_error_code := -1;
             x_error_msg  := 'Failed to get Dept ' || lc_dept_val ||' for Class ' || lc_link_attribute_n;
             CLOSE lcu_get_enabled_flag;
             RAISE EX_END_PROCEDURE; --LogErr;
         END IF;
         CLOSE lcu_get_enabled_flag;

         -- If this department is not enabled error out

         IF NOT (NVL(lr_ff_rec.enabled_flag, 'X') = 'Y' AND
            NVL(lr_ff_rec.end_date_active, TRUNC(SYSDATE + 1)) >= TRUNC(SYSDATE)) THEN
            x_error_code := -1;
            x_error_msg  := lc_link_attribute_n || ' Class is disabled';
            RAISE EX_END_PROCEDURE; --LogErr;
         END IF;
         lc_attribute2 := lc_dept_val;
      END IF;

      --
      -- End of Check if parent values exist and are enabled
      --
      -- call the procedure to Create/Update the value set
      --

      CALL_UP_VSET_VALUE(p_flex_value_set_name       => lc_flex_value_set_name,
                         p_flex_value                => TO_CHAR(p_value),
                         p_flex_value_meaning        => TO_CHAR(p_value),
                         p_enabled_flag              => lc_enabled_flag,
                         p_summary_flag              => lc_summary_flag,
                         p_start_date_active         => lc_start_date_active,
                         p_end_date_active           => lc_end_date_active,
                         p_parent_flex_value_high    => lr_ffv_typ.parent_flex_value_high,
                         p_hierarchy_level           => lr_ffv_typ.hierarchy_level,
                         p_compiled_value_attributes => lr_ffv_typ.compiled_value_attributes,
                         p_value_category            => lc_value_category,
                         p_attribute1                => lc_attribute1,
                         p_attribute2                => lc_attribute2,
                         p_attribute3                => lc_attribute3,
                         p_attribute4                => lc_attribute4,
                         p_attribute5                => lc_attribute5,
                         p_attribute6                => lc_attribute6,
                         p_attribute7                => lc_attribute7,
                         p_attribute8                => lc_attribute8,
                         p_attribute9                => lc_attribute9,
                         p_attribute10               => lc_attribute10,
                         p_attribute11               => lr_ffv_typ.attribute11,
                         p_attribute12               => lr_ffv_typ.attribute12,
                         p_attribute13               => lr_ffv_typ.attribute13,
                         p_attribute14               => lr_ffv_typ.attribute14,
                         p_attribute15               => lr_ffv_typ.attribute15,
                         p_attribute16               => lr_ffv_typ.attribute16,
                         p_attribute17               => lr_ffv_typ.attribute17,
                         p_attribute18               => lr_ffv_typ.attribute18,
                         p_attribute19               => lr_ffv_typ.attribute19,
                         p_attribute20               => lr_ffv_typ.attribute20,
                         p_attribute21               => lr_ffv_typ.attribute21,
                         p_attribute22               => lr_ffv_typ.attribute22,
                         p_attribute23               => lr_ffv_typ.attribute23,
                         p_attribute24               => lr_ffv_typ.attribute24,
                         p_attribute25               => lr_ffv_typ.attribute25,
                         p_attribute26               => lr_ffv_typ.attribute26,
                         p_attribute27               => lr_ffv_typ.attribute27,
                         p_attribute28               => lr_ffv_typ.attribute28,
                         p_attribute29               => lr_ffv_typ.attribute29,
                         p_attribute30               => lr_ffv_typ.attribute30,
                         p_attribute31               => lr_ffv_typ.attribute31,
                         p_attribute32               => lr_ffv_typ.attribute32,
                         p_attribute33               => lr_ffv_typ.attribute33,
                         p_attribute34               => lr_ffv_typ.attribute34,
                         p_attribute35               => lr_ffv_typ.attribute35,
                         p_attribute36               => lr_ffv_typ.attribute36,
                         p_attribute37               => lr_ffv_typ.attribute37,
                         p_attribute38               => lr_ffv_typ.attribute38,
                         p_attribute39               => lr_ffv_typ.attribute39,
                         p_attribute40               => lr_ffv_typ.attribute40,
                         p_attribute41               => lr_ffv_typ.attribute41,
                         p_attribute42               => lr_ffv_typ.attribute42,
                         p_attribute43               => lr_ffv_typ.attribute43,
                         p_attribute44               => lr_ffv_typ.attribute44,
                         p_attribute45               => lr_ffv_typ.attribute45,
                         p_attribute46               => lr_ffv_typ.attribute46,
                         p_attribute47               => lr_ffv_typ.attribute47,
                         p_attribute48               => lr_ffv_typ.attribute48,
                         p_attribute49               => lr_ffv_typ.attribute49,
                         p_attribute50               => lr_ffv_typ.attribute50,
                         p_attribute_sort_order      => lr_ffv_typ.attribute_sort_order,
                         p_description               => p_description,
                         p_action                    => lc_action,
                         x_err_code                  => ln_err_code,
                         x_err_msg                   => lc_err_msg);

      IF (ln_err_code <> 0) THEN
          x_error_code := ln_err_code;
          x_error_msg  := 'Failed to Update Value Set Value Description' || '-' || lc_err_msg;
          RAISE EX_END_PROCEDURE; --LogErr;
      ELSIF (ln_err_code = 0) THEN
          x_error_msg := 'Value Set Value Description modified successfully';
      END IF;
    
      --
      -- End of call to procedure to Create/Update the value set
      --
      -- Call category creation 
      --

      IF lc_action = 'ADD' AND p_hierarchy_level = 'SUBCLASS' THEN

	   -- To get merchandising hierarchy based on the subclass and class

         get_catg_segments(TO_CHAR(p_value),
                           p_class_number,
                           lv_segment1,
                           lv_segment2,
                           lv_segment3,
                           lv_segment4,
                           lv_segment5);

	   -- To Create Category based on the merchandising hierarchy

         create_od_category(lv_segment1,
                            lv_segment2,
                            lv_segment3,
                            lv_segment4,
                            lv_segment5,
                            'B',
                            x_error_code,
                            x_error_msg);

 	   IF x_error_code <> 0 THEN
            RAISE EX_END_PROCEDURE; --LogErr;
         END IF; 

      END IF;

      IF lc_action <> 'ADD' THEN

         IF (p_hierarchy_level = 'DIVISION') THEN

            FOR get_ccc_div_rec IN get_ccc_div(lc_segment1 => TO_CHAR(p_value)) LOOP
                category_update(get_ccc_div_rec.category_id,
                                ln_flex_value_set_id_div,
                                ln_flex_value_set_id_grp,
                                ln_flex_value_set_id_dept,
                                ln_flex_value_set_id_class,
                                ln_sclass_vs_id,
                                ln_flex_value_set_id_potype,
                                ln_flex_value_set_id_unspsc,
                                L_NA_VAL,
                                L_TRADE_VAL,
                                p_action,
                                x_err_code,
                                x_err_msg);
            END LOOP;

         ELSIF (p_hierarchy_level = 'GROUP') THEN

            FOR get_ccc_grp_rec IN get_ccc_grp(lc_segment1 => lc_link_attribute_o, --p_division_number, 
                                               lc_segment2 => TO_CHAR(p_value)) LOOP
            IF lc_link_change = 'N' THEN
              category_update(get_ccc_grp_rec.category_id,
                              ln_flex_value_set_id_div,
                              ln_flex_value_set_id_grp,
                              ln_flex_value_set_id_dept,
                              ln_flex_value_set_id_class,
                              ln_sclass_vs_id,
                              ln_flex_value_set_id_potype,
                              ln_flex_value_set_id_unspsc,
                              L_NA_VAL,
                              L_TRADE_VAL,
                              p_action,
                              x_err_code,
                              x_err_msg);
            ELSE
              category_link_update(get_ccc_grp_rec.category_id,
                                   get_ccc_grp_rec.structure_id,
                                   get_ccc_grp_rec.segment5);
            END IF;
            END LOOP;

        ELSIF (p_hierarchy_level = 'DEPARTMENT') THEN

            FOR get_ccc_dept_rec IN get_ccc_dept(lc_segment2 => lc_link_attribute_o, --p_group_number,
                                               lc_segment3 => TO_CHAR(p_value)) LOOP
            IF lc_link_change = 'N' THEN
              category_update(get_ccc_dept_rec.category_id,
                              ln_flex_value_set_id_div,
                              ln_flex_value_set_id_grp,
                              ln_flex_value_set_id_dept,
                              ln_flex_value_set_id_class,
                              ln_sclass_vs_id,
                              ln_flex_value_set_id_potype,
                              ln_flex_value_set_id_unspsc,
                              L_NA_VAL,
                              L_TRADE_VAL,
                              p_action,
                              x_err_code,
                              x_err_msg);
            ELSE
              category_link_update(get_ccc_dept_rec.category_id,
                                   get_ccc_dept_rec.structure_id,
                                   get_ccc_dept_rec.segment5);
            END IF;
            END LOOP;

        ELSIF (p_hierarchy_level = 'CLASS') THEN
  
            FOR get_ccc_cla_rec IN get_ccc_cla(lc_segment3 => lc_link_attribute_o, --p_dept_number, 
                                               lc_segment4 => TO_CHAR(p_value)) LOOP
            IF lc_link_change = 'N' THEN
              category_update(get_ccc_cla_rec.category_id,
                              ln_flex_value_set_id_div,
                              ln_flex_value_set_id_grp,
                              ln_flex_value_set_id_dept,
                              ln_flex_value_set_id_class,
                              ln_sclass_vs_id,
                              ln_flex_value_set_id_potype,
                              ln_flex_value_set_id_unspsc,
                              L_NA_VAL,
                              L_TRADE_VAL,
                              p_action,
                              x_err_code,
                              x_err_msg);
            ELSE
              category_link_update(get_ccc_cla_rec.category_id,
                                   get_ccc_cla_rec.structure_id,
                                   get_ccc_cla_rec.segment5);
            END IF;
            END LOOP;

        ELSIF (p_hierarchy_level = 'SUBCLASS') THEN

            FOR get_ccc_sclas_rec IN get_ccc_sclas(lc_segment4 => lc_link_attribute_o, --p_class_number,
                                                 lc_segment5 => TO_CHAR(p_value)) LOOP
/*
		Modified to update category table for anychange in subclass
            IF lc_link_change = 'N' THEN
              category_update(get_ccc_sclas_rec.category_id,
                              ln_flex_value_set_id_div,
                              ln_flex_value_set_id_grp,
                              ln_flex_value_set_id_dept,
                              ln_flex_value_set_id_class,
                              ln_sclass_vs_id,
                              ln_flex_value_set_id_potype,
                              ln_flex_value_set_id_unspsc,
                              L_NA_VAL,
                              L_TRADE_VAL,
                              p_action,
                              x_err_code,
                              x_err_msg);
            ELSE
              category_link_update(get_ccc_sclas_rec.category_id,
                                   get_ccc_sclas_rec.structure_id,
                                   get_ccc_sclas_rec.segment5);
            END IF;
*/

            category_link_update(get_ccc_sclas_rec.category_id,
                                 get_ccc_sclas_rec.structure_id,
                                 get_ccc_sclas_rec.segment5);
  
            IF get_ccc_sclas_rec.structure_id = ln_structure_id THEN
              lc_item_cc_exists_flag := 'Y';
            ELSIF get_ccc_sclas_rec.structure_id = ln_structure_id_po THEN
              lc_po_cc_exists_flag := 'Y';
            END IF;
  
            END LOOP;
            IF lc_item_cc_exists_flag = 'N' THEN
               get_catg_segments(TO_CHAR(p_value),
                              p_class_number,
                              lv_segment1,
                              lv_segment2,
                              lv_segment3,
                              lv_segment4,
                              lv_segment5);
               create_od_category(lv_segment1,
                               lv_segment2,
                               lv_segment3,
                               lv_segment4,
                               lv_segment5,
                               'I',
                               x_error_code,
                               x_error_msg);
            END IF;
            IF lc_po_cc_exists_flag = 'N' THEN
               get_catg_segments(TO_CHAR(p_value),
                              p_class_number,
                              lv_segment1,
                              lv_segment2,
                              lv_segment3,
                              lv_segment4,
                              lv_segment5);
               create_od_category(lv_segment1,
                                 lv_segment2,
                                lv_segment3,
                               lv_segment4,
                               lv_segment5,
                               'P',
                               x_error_code,
                               x_error_msg);
            END IF;
        END IF; -- End of (p_hierarchy_level 
      END IF; -- End of  lc_action<>'ADD' THEN 

    ELSIF (p_action = 'D') THEN

      OPEN lcu_get_enabled_flag(ln_flex_val_set_id => ln_flex_value_set_id,
                                lc_value           => TO_CHAR(p_value));
      FETCH lcu_get_enabled_flag INTO lr_ffv_typ;

      -- If the value does not exist ERROR out

      IF (lcu_get_enabled_flag%NOTFOUND) THEN
        x_error_code := -1;
        x_error_msg  := 'Value set value does not exist in  EBS to perform Deletion ';
        CLOSE lcu_get_enabled_flag;
        RAISE EX_END_PROCEDURE; --LogErr;
      END IF;
      CLOSE lcu_get_enabled_flag;

      lc_link_attribute_o := lr_ffv_typ.attribute1;
      lc_link_change      := 'N';
      lc_link_attribute_n := lr_ffv_typ.attribute1;

      IF (p_hierarchy_level = 'DIVISION') THEN
        FOR get_ccc_div_rec IN get_ccc_div(lc_segment1 => TO_CHAR(p_value)) LOOP
          category_update(get_ccc_div_rec.category_id,
                          ln_flex_value_set_id_div,
                          ln_flex_value_set_id_grp,
                          ln_flex_value_set_id_dept,
                          ln_flex_value_set_id_class,
                          ln_sclass_vs_id,
                          ln_flex_value_set_id_potype,
                          ln_flex_value_set_id_unspsc,
                          L_NA_VAL,
                          L_TRADE_VAL,
                          p_action,
                          x_err_code,
                          x_err_msg);
        END LOOP;
      ELSIF (p_hierarchy_level = 'GROUP') THEN
        FOR get_ccc_grp_rec IN get_ccc_grp(lc_segment1 => lc_link_attribute_o, --p_division_number, 
                                           lc_segment2 => TO_CHAR(p_value)) LOOP
          category_update(get_ccc_grp_rec.category_id,
                          ln_flex_value_set_id_div,
                          ln_flex_value_set_id_grp,
                          ln_flex_value_set_id_dept,
                          ln_flex_value_set_id_class,
                          ln_sclass_vs_id,
                          ln_flex_value_set_id_potype,
                          ln_flex_value_set_id_unspsc,
                          L_NA_VAL,
                          L_TRADE_VAL,
                          p_action,
                          x_err_code,
                          x_err_msg);
        END LOOP;
      ELSIF (p_hierarchy_level = 'DEPARTMENT') THEN
        FOR get_ccc_dept_rec IN get_ccc_dept(lc_segment2 => lc_link_attribute_o, --p_group_number,
                                             lc_segment3 => TO_CHAR(p_value)) LOOP
          category_update(get_ccc_dept_rec.category_id,
                          ln_flex_value_set_id_div,
                          ln_flex_value_set_id_grp,
                          ln_flex_value_set_id_dept,
                          ln_flex_value_set_id_class,
                          ln_sclass_vs_id,
                          ln_flex_value_set_id_potype,
                          ln_flex_value_set_id_unspsc,
                          L_NA_VAL,
                          L_TRADE_VAL,
                          p_action,
                          x_err_code,
                          x_err_msg);
        END LOOP;
      ELSIF (p_hierarchy_level = 'CLASS') THEN
        FOR get_ccc_cla_rec IN get_ccc_cla(lc_segment3 => lc_link_attribute_o, --p_dept_number, 
                                           lc_segment4 => TO_CHAR(p_value)) LOOP
          category_update(get_ccc_cla_rec.category_id,
                          ln_flex_value_set_id_div,
                          ln_flex_value_set_id_grp,
                          ln_flex_value_set_id_dept,
                          ln_flex_value_set_id_class,
                          ln_sclass_vs_id,
                          ln_flex_value_set_id_potype,
                          ln_flex_value_set_id_unspsc,
                          L_NA_VAL,
                          L_TRADE_VAL,
                          p_action,
                          x_err_code,
                          x_err_msg);
        END LOOP;
      ELSIF (p_hierarchy_level = 'SUBCLASS') THEN
        FOR get_ccc_sclas_rec IN get_ccc_sclas(lc_segment4 => lc_link_attribute_o, --p_class_number, 
                                               lc_segment5 => TO_CHAR(p_value)) LOOP
          category_update(get_ccc_sclas_rec.category_id,
                          ln_flex_value_set_id_div,
                          ln_flex_value_set_id_grp,
                          ln_flex_value_set_id_dept,
                          ln_flex_value_set_id_class,
                          ln_sclass_vs_id,
                          ln_flex_value_set_id_potype,
                          ln_flex_value_set_id_unspsc,
                          L_NA_VAL,
                          L_TRADE_VAL,
                          p_action,
                          x_err_code,
                          x_err_msg);
        END LOOP;
      END IF;

      -- Disable Value Set Value Based on Hierarchy level

      IF (p_hierarchy_level = 'DIVISION') THEN
        FOR get_grp_val_rec IN get_grp_val(p_vs_id  => ln_flex_value_set_id_grp,
                                           p_vs_val => TO_CHAR(p_value)) LOOP
          FOR get_depart_val_rec IN get_depart_val(p_vs_id  => ln_flex_value_set_id_dept,
                                                   p_vs_val => get_grp_val_rec.flex_value) LOOP
            FOR get_class_val_rec IN get_class_val(p_vs_id  => ln_class_value_set_id,
                                                   p_vs_val => get_depart_val_rec.flex_value) LOOP
              FOR get_subclass_val_rec IN get_subclass_val(p_vs_id  => ln_sclass_vs_id,
                                                           p_vs_val => get_class_val_rec.flex_value) LOOP
                -- Disabling Subclasses
                DISABLE_VSET_VALUE(p_vs_id            => ln_sclass_vs_id,
                                   p_value_to_disable => get_subclass_val_rec.flex_value,
                                   p_vs_name          => gc_subclass_vs_name,
                                   x_err_code         => ln_err_code,
                                   x_err_msg          => lc_err_msg);
                IF (ln_err_code <> 0) THEN
                  x_error_code := ln_err_code;
                  x_error_msg  := lc_err_msg;
                  RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
                ELSE
                  x_error_code := 0;
                  x_error_msg  := lc_flex_value_set_name ||
                                  ' Value Set Values Disabled Successfully';
                END IF;
              END LOOP;
              -- Disabling Classes
              DISABLE_VSET_VALUE(p_vs_id            => ln_class_value_set_id,
                                 p_value_to_disable => get_class_val_rec.flex_value,
                                 p_vs_name          => gc_class_vs_name,
                                 x_err_code         => ln_err_code,
                                 x_err_msg          => lc_err_msg);
              IF (ln_err_code <> 0) THEN
                x_error_code := ln_err_code;
                x_error_msg  := lc_err_msg;
                RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
              ELSE
                x_error_code := 0;
                x_error_msg  := lc_flex_value_set_name ||
                                ' Value Set Values Disabled Successfully';
              END IF;
            END LOOP;
            --Disabling Departments
            DISABLE_VSET_VALUE(p_vs_id            => ln_flex_value_set_id_dept,
                               p_value_to_disable => get_depart_val_rec.flex_value,
                               p_vs_name          => gc_dept_vs_name,
                               x_err_code         => ln_err_code,
                               x_err_msg          => lc_err_msg);
            IF (ln_err_code <> 0) THEN
              x_error_code := ln_err_code;
              x_error_msg  := lc_err_msg;
              RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
            ELSE
              x_error_code := 0;
              x_error_msg  := lc_flex_value_set_name ||
                              ' Value Set Values Disabled Successfully';
            END IF;
          END LOOP;
          -- Disabling Groups
          DISABLE_VSET_VALUE(p_vs_id            => ln_flex_value_set_id_grp,
                             p_value_to_disable => get_grp_val_rec.flex_value,
                             p_vs_name          => gc_group_vs_name,
                             x_err_code         => ln_err_code,
                             x_err_msg          => lc_err_msg);
          IF (ln_err_code <> 0) THEN
            x_error_code := ln_err_code;
            x_error_msg  := lc_err_msg;
            RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
          ELSE
            x_error_code := 0;
            x_error_msg  := lc_flex_value_set_name ||
                            ' Value Set Values Disabled Successfully';
          END IF;
        END LOOP;
        --Disable the Division itself
        DISABLE_VSET_VALUE(p_vs_id            => ln_flex_value_set_id_div,
                           p_value_to_disable => TO_CHAR(p_value),
                           p_vs_name          => lc_flex_value_set_name,
                           x_err_code         => ln_err_code,
                           x_err_msg          => lc_err_msg);
        IF (ln_err_code <> 0) THEN
          x_error_code := ln_err_code;
          x_error_msg  := lc_err_msg;
          RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
        ELSE
          x_error_code := 0;
          x_error_msg  := lc_flex_value_set_name ||
                          ' Value Set Values Disabled Successfully';
        END IF;
      ELSIF (p_hierarchy_level = 'GROUP') THEN
        FOR get_depart_val_rec IN get_depart_val(p_vs_id  => ln_flex_value_set_id_dept,
                                                 p_vs_val => TO_CHAR(p_value)) LOOP
          FOR get_class_val_rec IN get_class_val(p_vs_id  => ln_class_value_set_id,
                                                 p_vs_val => get_depart_val_rec.flex_value) LOOP
            FOR get_subclass_val_rec IN get_subclass_val(p_vs_id  => ln_sclass_vs_id,
                                                         p_vs_val => get_class_val_rec.flex_value) LOOP
              --Disabling Subclasses
              DISABLE_VSET_VALUE(p_vs_id            => ln_sclass_vs_id,
                                 p_value_to_disable => get_subclass_val_rec.flex_value,
                                 p_vs_name          => gc_subclass_vs_name,
                                 x_err_code         => ln_err_code,
                                 x_err_msg          => lc_err_msg);
              IF (ln_err_code <> 0) THEN
                x_error_code := ln_err_code;
                x_error_msg  := lc_err_msg;
                RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
              ELSE
                x_error_code := 0;
                x_error_msg  := lc_flex_value_set_name ||
                                ' Value Set Values Disabled Successfully';
              END IF;
            END LOOP;
            --Disable Classes
            DISABLE_VSET_VALUE(p_vs_id            => ln_class_value_set_id,
                               p_value_to_disable => get_class_val_rec.flex_value,
                               p_vs_name          => gc_class_vs_name,
                               x_err_code         => ln_err_code,
                               x_err_msg          => lc_err_msg);
            IF (ln_err_code <> 0) THEN
              x_error_code := ln_err_code;
              x_error_msg  := lc_err_msg;
              RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
            ELSE
              x_error_code := 0;
              x_error_msg  := lc_flex_value_set_name ||
                              ' Value Set Values Disabled Successfully';
            END IF;
          END LOOP;
          --Disabling Departments
          DISABLE_VSET_VALUE(p_vs_id            => ln_flex_value_set_id_dept,
                             p_value_to_disable => get_depart_val_rec.flex_value,
                             p_vs_name          => gc_dept_vs_name,
                             x_err_code         => ln_err_code,
                             x_err_msg          => lc_err_msg);
          IF (ln_err_code <> 0) THEN
            x_error_code := ln_err_code;
            x_error_msg  := lc_err_msg;
            RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
          ELSE
            x_error_code := 0;
            x_error_msg  := lc_flex_value_set_name ||
                            ' Value Set Values Disabled Successfully';
          END IF;
        END LOOP;
        --Disable group itself
        DISABLE_VSET_VALUE(p_vs_id            => ln_flex_value_set_id_grp,
                           p_value_to_disable => TO_CHAR(p_value),
                           p_vs_name          => lc_flex_value_set_name,
                           x_err_code         => ln_err_code,
                           x_err_msg          => lc_err_msg);
        IF (ln_err_code <> 0) THEN
          x_error_code := ln_err_code;
          x_error_msg  := lc_err_msg;
          RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
        ELSE
          x_error_code := 0;
          x_error_msg  := lc_flex_value_set_name ||
                          ' Value Set Values Disabled Successfully';
        END IF;
      ELSIF (p_hierarchy_level = 'DEPARTMENT') THEN
        FOR get_class_val_rec IN get_class_val(p_vs_id  => ln_class_value_set_id,
                                               p_vs_val => TO_CHAR(p_value)) LOOP
          FOR get_subclass_val_rec IN get_subclass_val(p_vs_id  => ln_sclass_vs_id,
                                                       p_vs_val => get_class_val_rec.flex_value) LOOP
            --Disabling Subclasses
            DISABLE_VSET_VALUE(p_vs_id            => ln_sclass_vs_id,
                               p_value_to_disable => get_subclass_val_rec.flex_value,
                               p_vs_name          => gc_subclass_vs_name,
                               x_err_code         => ln_err_code,
                               x_err_msg          => lc_err_msg);
            IF (ln_err_code <> 0) THEN
              x_error_code := ln_err_code;
              x_error_msg  := lc_err_msg;
              RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
            ELSE
              x_error_code := 0;
              x_error_msg  := lc_flex_value_set_name ||
                              ' Value Set Values Disabled Successfully';
            END IF;
          END LOOP;
          --Disabling Classes
          DISABLE_VSET_VALUE(p_vs_id            => ln_class_value_set_id,
                             p_value_to_disable => get_class_val_rec.flex_value,
                             p_vs_name          => gc_class_vs_name,
                             x_err_code         => ln_err_code,
                             x_err_msg          => lc_err_msg);
          IF (ln_err_code <> 0) THEN
            x_error_code := ln_err_code;
            x_error_msg  := lc_err_msg;
            RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
          ELSE
            x_error_code := 0;
            x_error_msg  := lc_flex_value_set_name ||
                            ' Value Set Values Disabled Successfully';
          END IF;
        END LOOP;
        -- Disable Department Itself
        DISABLE_VSET_VALUE(p_vs_id            => ln_flex_value_set_id_dept,
                           p_value_to_disable => TO_CHAR(p_value),
                           p_vs_name          => lc_flex_value_set_name,
                           x_err_code         => ln_err_code,
                           x_err_msg          => lc_err_msg);
        IF (ln_err_code <> 0) THEN
          x_error_code := ln_err_code;
          x_error_msg  := lc_err_msg;
          RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
        ELSE
          x_error_code := 0;
          x_error_msg  := lc_flex_value_set_name ||
                          ' Value Set Values Disabled Successfully';
        END IF;
      ELSIF (p_hierarchy_level = 'CLASS') THEN
        FOR get_subclass_val_rec IN get_subclass_val(p_vs_id  => ln_sclass_vs_id,
                                                     p_vs_val => TO_CHAR(p_value)) LOOP
          --Disable Subclasses
          DISABLE_VSET_VALUE(p_vs_id            => ln_sclass_vs_id,
                             p_value_to_disable => get_subclass_val_rec.flex_value,
                             p_vs_name          => gc_subclass_vs_name,
                             x_err_code         => ln_err_code,
                             x_err_msg          => lc_err_msg);
          IF (ln_err_code <> 0) THEN
            x_error_code := ln_err_code;
            x_error_msg  := lc_err_msg;
            RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
          ELSE
            x_error_code := 0;
            x_error_msg  := lc_flex_value_set_name ||
                            ' Value Set Values Disabled Successfully';
          END IF;
        END LOOP;
        -- Disable the Class itself
        DISABLE_VSET_VALUE(p_vs_id            => ln_class_value_set_id,
                           p_value_to_disable => TO_CHAR(p_value),
                           p_vs_name          => lc_flex_value_set_name,
                           x_err_code         => ln_err_code,
                           x_err_msg          => lc_err_msg);
        IF (ln_err_code <> 0) THEN
          x_error_code := ln_err_code;
          x_error_msg  := lc_err_msg;
          RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
        ELSE
          x_error_code := 0;
          x_error_msg  := lc_flex_value_set_name ||
                          ' Value Set Values Disabled Successfully';
        END IF;
      ELSIF (p_hierarchy_level = 'SUBCLASS') THEN
        -- Disable Subclass Only
        DISABLE_VSET_VALUE(p_vs_id            => ln_sclass_vs_id,
                           p_value_to_disable => TO_CHAR(p_value),
                           p_vs_name          => lc_flex_value_set_name,
                           x_err_code         => ln_err_code,
                           x_err_msg          => lc_err_msg);
        IF (ln_err_code <> 0) THEN
          x_error_code := ln_err_code;
          x_error_msg  := lc_err_msg;
          RAISE EX_ROLLBACK_END_PROCEDURE; -- LogErr;
        ELSE
          x_error_code := 0;
          x_error_msg  := lc_flex_value_set_name ||
                          ' Value Set Values Disabled Successfully';
        END IF;
      END IF;
    END IF;
    COMMIT;
  EXCEPTION
    WHEN EX_END_PROCEDURE THEN
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(P_PROGRAM_TYPE           => 'CUSTOM API',
                                     P_PROGRAM_NAME           => 'XX_INV_MERC_HIERARCHY_PKG.PROCESS_MERC_HIERARCHY',
                                     P_PROGRAM_ID             => NULL,
                                     P_MODULE_NAME            => 'INV',
                                     P_ERROR_LOCATION         => 'EX_END_PROCEDURE EXCEPTION',
                                     P_ERROR_MESSAGE_COUNT    => NULL,
                                     P_ERROR_MESSAGE_CODE     => x_error_code,
                                     P_ERROR_MESSAGE          => x_error_msg,
                                     P_ERROR_MESSAGE_SEVERITY => 'MAJOR',
                                     P_NOTIFY_FLAG            => 'Y',
                                     P_OBJECT_TYPE            => 'Merchandising Hierarchy Interface',
                                     P_OBJECT_ID              => TO_CHAR(p_value),
                                     P_ATTRIBUTE1             => p_hierarchy_level,
                                     P_ATTRIBUTE2             => p_description,
                                     P_ATTRIBUTE3             => p_action,
                                     P_RETURN_CODE            => NULL,
                                     P_MSG_COUNT              => NULL);
    WHEN EX_ROLLBACK_END_PROCEDURE THEN
      ROLLBACK;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(P_PROGRAM_TYPE           => 'CUSTOM API',
                                     P_PROGRAM_NAME           => 'XX_INV_MERC_HIERARCHY_PKG.PROCESS_MERC_HIERARCHY',
                                     P_PROGRAM_ID             => NULL,
                                     P_MODULE_NAME            => 'INV',
                                     P_ERROR_LOCATION         => 'EX_ROLLBACK_END_PROCEDURE EXCEPTION',
                                     P_ERROR_MESSAGE_COUNT    => NULL,
                                     P_ERROR_MESSAGE_CODE     => x_error_code,
                                     P_ERROR_MESSAGE          => x_error_msg,
                                     P_ERROR_MESSAGE_SEVERITY => 'MAJOR',
                                     P_NOTIFY_FLAG            => 'Y',
                                     P_OBJECT_TYPE            => 'Merchandising Hierarchy Interface',
                                     P_OBJECT_ID              => TO_CHAR(p_value),
                                     P_ATTRIBUTE1             => p_hierarchy_level,
                                     P_ATTRIBUTE2             => p_description,
                                     P_ATTRIBUTE3             => p_action,
                                     P_RETURN_CODE            => NULL,
                                     P_MSG_COUNT              => NULL);
    WHEN OTHERS THEN
      x_error_code := -1;
      x_error_msg  := SQLERRM || ' ' ||
                      ' WHEN OTHERS EXCEPTION In Procedure Process_Merc_Hierarchy';
      XX_COM_ERROR_LOG_PUB.LOG_ERROR(P_PROGRAM_TYPE           => 'CUSTOM API',
                                     P_PROGRAM_NAME           => 'XX_INV_MERC_HIERARCHY_PKG.PROCESS_MERC_HIERARCHY',
                                     P_PROGRAM_ID             => NULL,
                                     P_MODULE_NAME            => 'INV',
                                     P_ERROR_LOCATION         => 'WHEN OTHERS EXCEPTION',
                                     P_ERROR_MESSAGE_COUNT    => NULL,
                                     P_ERROR_MESSAGE_CODE     => x_error_code,
                                     P_ERROR_MESSAGE          => x_error_msg,
                                     P_ERROR_MESSAGE_SEVERITY => 'MAJOR',
                                     P_NOTIFY_FLAG            => 'Y',
                                     P_OBJECT_TYPE            => 'Merchandising Hierarchy Interface',
                                     P_OBJECT_ID              => TO_CHAR(p_value),
                                     P_ATTRIBUTE1             => p_hierarchy_level,
                                     P_ATTRIBUTE2             => p_description,
                                     P_ATTRIBUTE3             => p_action,
                                     P_RETURN_CODE            => NULL,
                                     P_MSG_COUNT              => NULL);
  END PROCESS_MERC_HIERARCHY;
END XX_INV_MERC_HIERARCHY_PKG;
/

SHOW ERRORS;

EXIT;
