SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY XX_GL_CROSS_VALID_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_GL_CROSS_VALID_PKG.pkb		       |
-- | Description :  Process for 10g to 11g                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       13-Dec-2012 Paddy Sanjeevi     Initial version           |
-- |1.1       07-28-2016  Radhika Patnala    GLLFV_CHARTS_OF_ACCOUNTS dropped in R12.25 ,
--                                           replaced with fnd_id_flex_structures_tl
-- +===================================================================+
AS

PROCEDURE XX_GL_CROSS_VALIDATION
      ( p_coa_name            IN VARCHAR2
       ,p_company             IN VARCHAR2 DEFAULT NULL
       ,p_cost_center         IN VARCHAR2
       ,p_account             IN VARCHAR2
       ,p_location            IN VARCHAR2
       ,p_intercompany        IN VARCHAR2 DEFAULT NULL
       ,p_lob                 IN VARCHAR2
       ,p_future              IN VARCHAR2 DEFAULT NULL
       ,x_return_msg          OUT VARCHAR2          -- Changed parameter from p_return_msg to x_return_msg
       ,x_valid_combo         OUT VARCHAR2          -- Changed parameter from p_valid_combo to x_valid_combo
       ,x_company             OUT VARCHAR2)         -- Fixed defect 6051
IS


   ln_coa_id         PLS_INTEGER;
   lc_concat_segs    VARCHAR2(100);
   lc_company        VARCHAR2(5);
   lc_intercompany   VARCHAR2(5);
   lc_future         VARCHAR2(6);
   lb_valid_flag     BOOLEAN;
   lc_error_msg      VARCHAR2(2000);
   lc_coa_name       VARCHAR2(30);

BEGIN

   x_valid_combo := 'X';

   --Defect 7183 - Added following SQL to convert COAName to upper case      
   SELECT UPPER(p_coa_name) INTO lc_coa_name 
   FROM DUAL;

   IF (TRIM(p_location) IS NULL OR
       TRIM(p_cost_center) IS NULL OR
       TRIM(p_account) IS NULL OR
       TRIM(p_lob) IS NULL) THEN
     x_return_msg := 'ERROR: One or all of the required segments LOCATION, COST CENTER, ACCOUNT and LOB has no value';
     x_valid_combo := 'N';
   END IF;

   IF x_valid_combo != 'N' THEN   
      IF TRIM(p_company) IS NULL THEN
         lc_company := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(p_location);
      
         IF TRIM(lc_company) IS NULL THEN
            x_return_msg := 'ERROR: Company segment was not supplied and cannot be derived from the location segment';
            x_valid_combo := 'N';
         END IF;
      ELSE
         lc_company := p_company;
      END IF;
   END IF;
   
   IF x_valid_combo != 'N' THEN
      IF TRIM(p_intercompany) IS NULL THEN
         lc_intercompany := '0000';
      ELSE
         lc_intercompany := p_intercompany;
      END IF;
   
      IF TRIM(p_future) IS NULL THEN
         lc_future := '000000';
      ELSE
         lc_future := p_future;
      END IF;
   
      BEGIN

        /*SELECT COA.chart_of_accounts_id INTO ln_coa_id 
         FROM glfv_charts_of_accounts COA
         WHERE COA.chart_of_accounts_name = lc_coa_name; */ -- glfv_charts_of_accounts is driopped in R12.2.5

 	  select id_flex_num INTO ln_coa_id 
 	    from  fnd_id_flex_structures_tl
 	   where id_flex_structure_name=lc_coa_name	  --  Replaced by fnd_id_flex_structures_tl to fetch chart_of_accounts_id as of part of Retrofit 12.2.5  --
 	    and id_flex_code='GL#'; 

         -- e.g. P_CONCAT_SEGS := '1001.00000.20301000.800003.0000.00.000000';
         lc_concat_segs := lc_company || '.' || p_cost_center || '.' || p_account || '.' || p_location || '.' || lc_intercompany || '.' || p_lob || '.' || lc_future;
   
         lb_valid_flag := FND_FLEX_KEYVAL.VALIDATE_SEGS
               (
                -- Defect 683 OPERATION         =>     'CHECK_SEGMENTS',
                OPERATION         =>     'CHECK_COMBINATION',                
                APPL_SHORT_NAME   =>     'SQLGL',
                KEY_FLEX_CODE     =>     'GL#',
                STRUCTURE_NUMBER =>       ln_coa_id,
                CONCAT_SEGMENTS     =>       lc_concat_segs);
   
         IF lb_valid_flag THEN
            x_return_msg :=  'Concatenated Segments ' || lc_concat_segs || ' is Valid';
            x_valid_combo := 'Y';

            x_company := lc_company;           --Added for defect 6051

         ELSE
            x_return_msg := 'Concatenated Segments ' || lc_concat_segs || ' is Invalid';
            x_return_msg := x_return_msg || CHR(10) || FND_FLEX_KEYVAL.ERROR_MESSAGE;

            x_valid_combo := 'N';
            x_company := NULL;                --Added for defect 6051
         END IF;
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         x_return_msg := 'ERROR: The Chart of Accounts ' || lc_coa_name || ' passed to the GL cross validation function is not valid';
         x_valid_combo := 'N';
      END;
   END IF;

END XX_GL_CROSS_VALIDATION;

END XX_GL_CROSS_VALID_PKG;
/
