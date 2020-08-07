CREATE OR REPLACE PACKAGE BODY XX_OD_UPDATE_PROFILES_PKG
AS
-- +===================================================================================+
-- |                                 Office Depot                                      |
-- +===================================================================================+
-- | Name        :  XX_OD_UPDATE_PROFILES_PKG                                          |
-- | Description :  This Package will be used to update the Profile option values and  |
-- |                Translation values                                                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version  Date           Author          Remarks                                    |
-- |=======  ============   =============   ===========================================|
-- |1.0      30-Nov-2016    Havish Kasina   Added a new procedure                      |
-- |                                        xx_update_profile_values for Defect 39631  |
-- +===================================================================================+
   PROCEDURE xx_update_profile_values(lc_run_top IN VARCHAR2)
   AS 
  -- +=======================================================================================+
  -- | Name            : xx_update_profile_values                                            |
  -- | Description     : Procedure to update the Profile option values and Translation values|
  -- | Parameters      : lc_run_top                                                          |
  -- |                                                                                       |
  -- +=======================================================================================+
   lb_profile_chg_result BOOLEAN;
   BEGIN  
      -- Step 1 : Updating the Translation XX_EBL_COMMON_TRANS
      DBMS_OUTPUT.PUT_LINE(' Post Clone Identifier : Bill_IS_01');
	  DBMS_OUTPUT.PUT_LINE(' Module                : Billing');
	  DBMS_OUTPUT.PUT_LINE(' Object Type           : Translation');
	  DBMS_OUTPUT.PUT_LINE(' Object Name           : XX_EBL_COMMON_TRANS');
      DBMS_OUTPUT.PUT_LINE(' Start of updating the Translation XX_EBL_COMMON_TRANS');
      UPDATE xx_fin_translatevalues 
         SET target_value1 =lc_run_top||'/EBSapps/appl/xxfin/12.0.0/media'
       WHERE source_value1 = 'FPATH'
         AND translate_id IN (SELECT translate_id 
                                FROM xx_fin_translatedefinition 
                               WHERE translation_name ='XX_EBL_COMMON_TRANS');
      DBMS_OUTPUT.PUT_LINE('Number of rows updated :'||SQL%rowcount);
      COMMIT;
	  DBMS_OUTPUT.PUT_LINE(' End of updating the Translation XX_EBL_COMMON_TRANS');
      DBMS_OUTPUT.PUT_LINE(CHR(10));
	  
	  -- Step 2 : Updating the Profile Option OD: iRec Receipts Confirm Page Template Url
      DBMS_OUTPUT.PUT_LINE(' Post Clone Identifier : iREC_IS_02');
	  DBMS_OUTPUT.PUT_LINE(' Module                : iReceivables');
	  DBMS_OUTPUT.PUT_LINE(' Object Type           : Profile Option');
	  DBMS_OUTPUT.PUT_LINE(' Object Name           : OD: iRec Receipts Confirm Page Template Url');
      DBMS_OUTPUT.PUT_LINE(' Start of updating the Profile Option OD: iRec Receipts Confirm Page Template Url');
      lb_profile_chg_result := NULL;
      lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'XX_FIN_IREC_CONF_PAGE_TEMPLATE_URL'
                                               ,x_value      => lc_run_top||'/EBSapps/appl/xxfin/12.0.0/xml/templates/'
                                               ,x_level_name => 'SITE');
        IF lb_profile_chg_result THEN
            DBMS_OUTPUT.PUT_LINE('lb_profile_result = TRUE - profile updated, for iREC_IS_02');
        ELSE
            DBMS_OUTPUT.PUT_LINE('lb_profile_result = FALSE - profile NOT updated, for iREC_IS_02');
        END IF;
        COMMIT;
	  DBMS_OUTPUT.PUT_LINE(' End of updating the Profile Option OD: iRec Receipts Confirm Page Template Url');
      DBMS_OUTPUT.PUT_LINE(CHR(10));
	  
	  -- Step 3 : Updating the Profile Option IBY: XML Base
      DBMS_OUTPUT.PUT_LINE(' Post Clone Identifier : iPAY_IS_05');
	  DBMS_OUTPUT.PUT_LINE(' Module                : iPayments');
	  DBMS_OUTPUT.PUT_LINE(' Object Type           : Profile Option');
	  DBMS_OUTPUT.PUT_LINE(' Object Name           : IBY: XML Base');
      DBMS_OUTPUT.PUT_LINE(' Start of updating the Profile Option IBY: XML Base');
      lb_profile_chg_result := NULL;
      lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'IBY_XML_BASE'
                                               ,x_value      => lc_run_top||'/EBSapps/appl/iby/12.0.0/xml'
                                               ,x_level_name => 'SITE');
        IF lb_profile_chg_result THEN
            DBMS_OUTPUT.PUT_LINE('Profile is updated for iPAY_IS_05');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Profile is NOT updated for iPAY_IS_05');
        END IF;
        COMMIT;
	  DBMS_OUTPUT.PUT_LINE(' End of updating the Profile Option IBY: XML Base');
      DBMS_OUTPUT.PUT_LINE(CHR(10));
	  
	  -- Step 4 : Updating the Profile Option FND: Personalization Document Root Path
      DBMS_OUTPUT.PUT_LINE(' Post Clone Identifier : FND_IS_01');
	  DBMS_OUTPUT.PUT_LINE(' Module                : FND');
	  DBMS_OUTPUT.PUT_LINE(' Object Type           : Profile Option');
	  DBMS_OUTPUT.PUT_LINE(' Object Name           : FND: Personalization Document Root Path');
      DBMS_OUTPUT.PUT_LINE(' Start of updating the Profile Option FND: Personalization Document Root Path');
      lb_profile_chg_result := NULL;
	  lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'FND_PERZ_DOC_ROOT_PATH'
                                               ,x_value      => lc_run_top||'/EBSapps/appl/xxcomn/12.0.0/java/personalizations'
                                               ,x_level_name => 'SITE');
      IF lb_profile_chg_result THEN
            DBMS_OUTPUT.PUT_LINE('Profile is updated for FND_IS_01');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Profile is NOT updated for FND_IS_01');
        END IF;
        COMMIT;
	  DBMS_OUTPUT.PUT_LINE(' End of updating the Profile Option FND: Personalization Document Root Path');
      DBMS_OUTPUT.PUT_LINE(CHR(10));
	  
	  -- Step 5 : Updating the Profile Option POR : CA Certificate File Name
      DBMS_OUTPUT.PUT_LINE(' Post Clone Identifier : ');
	  DBMS_OUTPUT.PUT_LINE(' Module                : ');
	  DBMS_OUTPUT.PUT_LINE(' Object Type           : Profile Option');
	  DBMS_OUTPUT.PUT_LINE(' Object Name           : POR : CA Certificate File Name');
      DBMS_OUTPUT.PUT_LINE(' Start of updating the Profile Option POR : CA Certificate File Name');
      lb_profile_chg_result := NULL;
	  lb_profile_chg_result := FND_PROFILE.SAVE(x_name       => 'POR_CACERT_FILE_NAME'
                                               ,x_value      => lc_run_top||'/EBSapps/10.1.2/sysman/config/b64InternetCertificate.txt'
                                               ,x_level_name => 'SITE');
      IF lb_profile_chg_result THEN
            DBMS_OUTPUT.PUT_LINE('Profile is updated');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Profile is NOT updated ');
        END IF;
        COMMIT;
	  DBMS_OUTPUT.PUT_LINE(' End of updating the Profile Option POR : CA Certificate File Name');
      DBMS_OUTPUT.PUT_LINE(CHR(10));
   EXCEPTION
     WHEN OTHERS 
	 THEN
         DBMS_OUTPUT.PUT_LINE('Unable to update_table ERROR:' || ' ' || SQLERRM);
   END;
	  
END XX_OD_UPDATE_PROFILES_PKG;
/
SHOW ERRORS;
EXIT;