create or replace PACKAGE BODY "XX_HR_MAPPING_PKG" AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                    	    |
-- |                  Office Depot                                         	    |
-- +=================================================================================+
-- | Name  	   : XX_HR_MAPPING_PKG (XX_HR_MAPPING_PKG.pkb)                      |
-- | Description   : I0099 Employee with PSHR upgrade 				    |
-- |                                  	    				            |
-- |Change Record:                                                         	    |
-- |===============                                                        	    |
-- |Version Date        Author     Remarks        Description         	            |
-- |======= ========   =========== ===========   ===============      	            |
-- |1.0     			   Initial draft version          		    |
-- |                                                                                |
-- |1.1    19-SEP-14   Saritha M   Defect # 31846 To improve the performance        |
-- |						  of the program we have commented  |
-- |		                                  HR_USORG_LOV_V view and           |
-- |		                                  included HR_ALL_ORGANIZATION_UNITS|
-- |		                                  table.                            |
-- |                                                                         	    |
-- +=================================================================================+

  G_TRANSLATE_JOB           CONSTANT VARCHAR(30) := 'HR_PS_TO_ORACLE_JOB';
  G_TRANSLATE_ADDRESS_STYLE CONSTANT VARCHAR(30) := 'HR_PS_TO_ORACLE_ADD_STYLE';
  G_TRANSLATE_ACCOUNT       CONSTANT VARCHAR(30) := 'HR_PS_TO_ORACLE_ACCOUNT';
--  G_TRANSLATE_LOCATION      CONSTANT VARCHAR(30) := 'GL_PSFIN_LOCATION';
--  G_TRANSLATE_COST_CENTER   CONSTANT VARCHAR(30) := 'GL_PSFIN_COST_CENTER';

  FUNCTION GET_MESSAGE (
     p_message_name   IN VARCHAR2
    ,p_token1_name    IN VARCHAR2 := NULL
    ,p_token1_value   IN VARCHAR2 := NULL
    ,p_token2_name    IN VARCHAR2 := NULL
    ,p_token2_value   IN VARCHAR2 := NULL
  ) RETURN VARCHAR2
  IS
  BEGIN
    FND_MESSAGE.CLEAR;
    FND_MESSAGE.SET_NAME('XXFIN','XX_PER_PS_' || p_message_name);
    IF p_token1_name IS NOT NULL THEN
      FND_MESSAGE.SET_TOKEN(p_token1_name,p_token1_value);
    END IF;
    IF p_token2_name IS NOT NULL THEN
      FND_MESSAGE.SET_TOKEN(p_token2_name,p_token2_value);
    END IF;
    RETURN FND_MESSAGE.GET();
  END;


  FUNCTION TRANSLATION (
    p_translation_name   IN  VARCHAR2
   ,p_source_value1      IN  XX_FIN_TRANSLATEVALUES.source_value1%TYPE := NULL
   ,p_source_value2      IN  XX_FIN_TRANSLATEVALUES.source_value2%TYPE := NULL
   ,p_source_value3      IN  XX_FIN_TRANSLATEVALUES.source_value3%TYPE := NULL
   ,p_source_value4      IN  XX_FIN_TRANSLATEVALUES.source_value4%TYPE := NULL
   ,p_source_value5      IN  XX_FIN_TRANSLATEVALUES.source_value5%TYPE := NULL
   ,p_source_value6      IN  XX_FIN_TRANSLATEVALUES.source_value5%TYPE := NULL
   ,p_source_value7      IN  XX_FIN_TRANSLATEVALUES.source_value5%TYPE := NULL
   ,p_source_value8      IN  XX_FIN_TRANSLATEVALUES.source_value5%TYPE := NULL
   ,p_source_value9      IN  XX_FIN_TRANSLATEVALUES.source_value5%TYPE := NULL
   ,p_source_value10     IN  XX_FIN_TRANSLATEVALUES.source_value5%TYPE := NULL
  ) RETURN XX_FIN_TRANSLATEVALUES.target_value1%TYPE
  IS
      l_target_value1 XX_FIN_TRANSLATEVALUES.target_value1%TYPE;
      l_target_value2 XX_FIN_TRANSLATEVALUES.target_value2%TYPE;
      l_target_value3 XX_FIN_TRANSLATEVALUES.target_value3%TYPE;
      l_target_value4 XX_FIN_TRANSLATEVALUES.target_value4%TYPE;
      l_target_value5 XX_FIN_TRANSLATEVALUES.target_value5%TYPE;
      l_target_value6 XX_FIN_TRANSLATEVALUES.target_value6%TYPE;
      l_target_value7 XX_FIN_TRANSLATEVALUES.target_value7%TYPE;
      l_target_value8 XX_FIN_TRANSLATEVALUES.target_value8%TYPE;
      l_target_value9 XX_FIN_TRANSLATEVALUES.target_value9%TYPE;
      l_target_value10 XX_FIN_TRANSLATEVALUES.target_value10%TYPE;
      l_target_value11 XX_FIN_TRANSLATEVALUES.target_value11%TYPE;
      l_target_value12 XX_FIN_TRANSLATEVALUES.target_value12%TYPE;
      l_target_value13 XX_FIN_TRANSLATEVALUES.target_value13%TYPE;
      l_target_value14 XX_FIN_TRANSLATEVALUES.target_value14%TYPE;
      l_target_value15 XX_FIN_TRANSLATEVALUES.target_value15%TYPE;
      l_target_value16 XX_FIN_TRANSLATEVALUES.target_value16%TYPE;
      l_target_value17 XX_FIN_TRANSLATEVALUES.target_value17%TYPE;
      l_target_value18 XX_FIN_TRANSLATEVALUES.target_value18%TYPE;
      l_target_value19 XX_FIN_TRANSLATEVALUES.target_value19%TYPE;
      l_target_value20 XX_FIN_TRANSLATEVALUES.target_value20%TYPE;
      l_error_message varchar2(700);
  BEGIN
    XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC (
       p_translation_name => p_translation_name
      ,p_source_value1    => p_source_value1
      ,p_source_value2    => p_source_value2
      ,p_source_value3    => p_source_value3
      ,p_source_value4    => p_source_value4
      ,p_source_value5    => p_source_value5
      ,p_source_value6    => p_source_value6
      ,p_source_value7    => p_source_value7
      ,p_source_value8    => p_source_value8
      ,p_source_value9    => p_source_value9
      ,p_source_value10   => p_source_value10
      ,x_target_value1    => l_target_value1
      ,x_target_value2    => l_target_value2
      ,x_target_value3    => l_target_value3
      ,x_target_value4    => l_target_value4
      ,x_target_value5    => l_target_value5
      ,x_target_value6    => l_target_value6
      ,x_target_value7    => l_target_value7
      ,x_target_value8    => l_target_value8
      ,x_target_value9    => l_target_value9
      ,x_target_value10   => l_target_value10
      ,x_target_value11   => l_target_value11
      ,x_target_value12   => l_target_value12
      ,x_target_value13   => l_target_value13
      ,x_target_value14   => l_target_value14
      ,x_target_value15   => l_target_value15
      ,x_target_value16   => l_target_value16
      ,x_target_value17   => l_target_value17
      ,x_target_value18   => l_target_value18
      ,x_target_value19   => l_target_value19
      ,x_target_value20   => l_target_value20
      ,x_error_message    => l_error_message
    );
    IF l_target_value1 = '-1' THEN
      l_target_value1 := NULL;  -- Functionality recently changed to return -1 when no data found
    END IF;
    RETURN l_target_value1;
  END TRANSLATION;


  FUNCTION JOB_TRANSLATION (
    p_job_country_code   IN  VARCHAR2 := '%'
   ,p_job_business_unit  IN  VARCHAR2 := '%'
   ,p_job_code           IN  VARCHAR2 := '%'
   ,p_manager_level      IN  VARCHAR2 := '%'
   ,p_grade              IN  VARCHAR2 := '%'
  ) RETURN XX_FIN_TRANSLATEVALUES.target_value1%TYPE
  IS
  BEGIN
    RETURN TRANSLATION(G_TRANSLATE_JOB
                      ,p_source_value1 => p_job_country_code
                      ,p_source_value2 => p_job_business_unit
                      ,p_source_value3 => p_job_code
                      ,p_source_value4 => p_manager_level
                      ,p_source_value5 => p_grade);
  END JOB_TRANSLATION;


  FUNCTION JOB_ID (
      p_job_title          IN VARCHAR2
     ,p_job_country_code   IN VARCHAR2
     ,p_job_business_unit  IN VARCHAR2
     ,p_job_code           IN VARCHAR2
     ,p_grade              IN VARCHAR2
     ,p_manager_level      IN VARCHAR2
  ) RETURN PER_JOBS.job_id%TYPE
  IS
     l_error_message           VARCHAR2(700);
     l_job_name                PER_JOBS.name%TYPE := NULL;
     l_job_id                  PER_JOBS.job_id%TYPE;
     ld_sysdate                DATE := TRUNC(SYSDATE);
  BEGIN
    BEGIN -- if Peoplesoft job setid:jobcode exist in the prefix of an Oracle job name, use it
      SELECT name,job_id
      INTO l_job_name, l_job_id
      FROM PER_JOBS
      WHERE UPPER(name) like UPPER(p_job_country_code || p_job_business_unit || ':' || p_job_code || ':%')
        AND ld_sysdate BETWEEN date_from AND NVL(date_to,SYSDATE)
        and BUSINESS_GROUP_ID = fnd_profile.value('PER_BUSINESS_GROUP_ID')
        AND rownum=1
      ORDER BY job_id DESC; -- could be more than one temporarily when new job is added with updated title.
                            -- in that case, use the most recent job (highest job_id)
      fnd_file.put_line(fnd_file.log,'l_job_id '||l_job_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN -- else use translation mappings to find job...
      l_job_name := JOB_TRANSLATION(p_job_country_code      => p_job_country_code
                                   ,p_job_business_unit     => p_job_business_unit
                                   ,p_job_code              => p_job_code);
      IF l_job_name IS NULL THEN
        l_job_name := JOB_TRANSLATION(p_manager_level       => p_manager_level
                                     ,p_job_business_unit   => p_job_business_unit
                                     ,p_grade               => p_grade);
        IF l_job_name IS NULL THEN
          l_job_name := JOB_TRANSLATION(p_manager_level     => p_manager_level
                                       ,p_job_business_unit => p_job_business_unit);
          IF l_job_name IS NULL THEN
            l_job_name := JOB_TRANSLATION(p_manager_level   => p_manager_level);
            IF l_job_name IS NULL THEN
              l_job_name := 'STAFF';
            END IF;
          END IF;
        END IF;
      END IF;
      SELECT job_id
      INTO l_job_id
      FROM PER_JOBS
      WHERE UPPER(name)=UPPER(l_job_name);
    END;

    RETURN l_job_id;

    EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20111,'Job mapping failed for country_code=' || p_job_country_code || ' business_unit=' || p_job_business_unit
                              || ' job_code=' || p_job_code || ' manager_level=' || p_manager_level || ' grade=' || p_grade || ' translated_job_name=' || l_job_name,TRUE);
      RETURN NULL;
  END JOB_ID;


  FUNCTION SET_OF_BOOKS_ID (
    p_company            IN  VARCHAR2
  ) RETURN GL_SETS_OF_BOOKS.set_of_books_id%TYPE
  IS
    ln_sob_id                GL_SETS_OF_BOOKS.set_of_books_id%TYPE := NULL;
  BEGIN
    IF p_company IS NOT NULL THEN
      SELECT XX_GL_TRANSLATE_UTL_PKG.DERIVE_SOBID_FROM_COMPANY(p_company)
      INTO ln_sob_id
      FROM SYS.DUAL;
    END IF;

    RETURN ln_sob_id;
  END SET_OF_BOOKS_ID;


  FUNCTION LOCATION_ID (
     p_location_number    IN  VARCHAR2
  ) RETURN HR_LOCATIONS.location_id%TYPE
  IS
    ln_location_id            HR_LOCATIONS.location_id%TYPE := NULL;
  BEGIN
    IF p_location_number IS NOT NULL THEN
      SELECT location_id
      INTO   ln_location_id
      FROM   HR_LOCATIONS_ALL
      WHERE  ATTRIBUTE1=p_location_number AND ATTRIBUTE2='Y'
      AND    (inactive_date IS NULL OR inactive_date>SYSDATE);
    END IF;

    RETURN ln_location_id;

    EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20222,GET_MESSAGE('0015_MAP_LOC_FAILED','LOC',p_location_number),TRUE);
      RETURN NULL;
  END;


  FUNCTION ORGANIZATION_ID (
     p_cost_center    IN  VARCHAR2,
	 p_bg_id          IN  NUMBER
  ) RETURN                 HR_ALL_ORGANIZATION_UNITS.organization_id%TYPE
  IS
    ln_organization_id     HR_ALL_ORGANIZATION_UNITS.organization_id%TYPE := NULL;
    ld_sysdate DATE := TRUNC(SYSDATE);
  BEGIN
    IF p_cost_center IS NOT NULL THEN
    -- Commented as per Ver 1.1 to improve performance as per defect # 31846.
    /*  SELECT organization_id
      INTO ln_organization_id
      FROM HR_USORG_LOV_V
      WHERE UPPER(org_name) like 'CC' || p_cost_center || '-%'
        AND ld_sysdate BETWEEN date_from AND NVL(date_to,SYSDATE);*/

    -- Added as per Ver 1.1 as per defect # 31846.
      SELECT organization_id
      INTO ln_organization_id
      FROM HR_ALL_ORGANIZATION_UNITS
     WHERE  UPPER(name) like '%CC' || p_cost_center || '-%'
        AND ld_sysdate BETWEEN date_from AND NVL(date_to,SYSDATE)
		AND business_group_id = p_bg_id;


    END IF;

    RETURN ln_organization_id;

    EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20333,GET_MESSAGE('0016_MAP_ORG_FAILED','CC', p_cost_center),TRUE);
      RETURN NULL;
  END ORGANIZATION_ID;


  FUNCTION BUSINESS_GROUP_ID (
    p_organization_id    IN NUMBER
  ) RETURN                  HR_ALL_ORGANIZATION_UNITS.business_group_id%TYPE
  IS
    ln_business_group_id    HR_ALL_ORGANIZATION_UNITS.business_group_id%TYPE := 0;
  BEGIN
    IF p_organization_id IS NOT NULL THEN
      SELECT business_group_id
      INTO ln_business_group_id
      FROM HR_ALL_ORGANIZATION_UNITS
      WHERE organization_id = p_organization_id;
    END IF;

    RETURN ln_business_group_id;
  END BUSINESS_GROUP_ID;


  FUNCTION ADDRESS_STYLE (
    p_country         IN VARCHAR2
  ) RETURN               VARCHAR2
  IS
    ln_default_address_style      VARCHAR2(20) := 'GENERIC';
  BEGIN
    RETURN NVL(TRANSLATION(G_TRANSLATE_ADDRESS_STYLE, p_country),ln_default_address_style);

    EXCEPTION WHEN OTHERS THEN
      RETURN ln_default_address_style;
  END ADDRESS_STYLE;


  FUNCTION COMPANY (
     p_company           IN VARCHAR2
    ,p_location           IN VARCHAR2
  ) RETURN GL_CODE_COMBINATIONS.segment1%TYPE
  IS
    lc_company       GL_CODE_COMBINATIONS.segment1%TYPE := NULL;
    lc_error_message VARCHAR2(2000);
  BEGIN
    IF p_location IS NOT NULL THEN
      IF p_location='010000' THEN --Location 010000 may exist for multiple companies, so get Oracle company from Peoplesoft company
        XX_GL_PSHR_INTERFACE_PKG.DERIVE_COMPANY(p_ps_company    => p_company
                                               ,x_ora_company   => lc_company
                                               ,x_error_message => lc_error_message);
      ELSE
        lc_company := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(p_location); --all other locations should be uniquely associated with one company
      END IF;

      IF lc_company IS NULL THEN
        RAISE_APPLICATION_ERROR(-20563,GET_MESSAGE('0017_MAP_COM_FAILED','COMPANY', p_company, 'LOCATION', p_location),TRUE);
        RETURN NULL;
      END IF;
    END IF;

    RETURN lc_company;

    EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20564,GET_MESSAGE('0017_MAP_COM_FAILED','COMPANY', p_company, 'LOCATION', p_location),TRUE);
      RETURN NULL;
  END;

  FUNCTION GET_LEDGER (
     p_company           IN VARCHAR2
    ,p_location          IN VARCHAR2
  ) RETURN gl_ledgers.ledger_id%TYPE
  IS
    lc_company       GL_CODE_COMBINATIONS.segment1%TYPE := NULL;
    lc_error_message VARCHAR2(2000);
	ln_ledger_id     gl_ledgers.ledger_id%TYPE;
  BEGIN
    IF p_location IS NOT NULL THEN
      IF p_location='010000' THEN --Location 010000 may exist for multiple companies, so get Oracle company from Peoplesoft company
        XX_GL_PSHR_INTERFACE_PKG.DERIVE_COMPANY(p_ps_company    => p_company
                                               ,x_ora_company   => lc_company
                                               ,x_error_message => lc_error_message);
      ELSE
        lc_company := XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(p_location); --all other locations should be uniquely associated with one company
      END IF;

      IF lc_company IS NULL THEN
      --  RAISE_APPLICATION_ERROR(-20563,GET_MESSAGE('0017_MAP_COM_FAILED','COMPANY', p_company, 'LOCATION', p_location),TRUE);
        RETURN NULL;
      END IF;
	  BEGIN
	   SELECT gl.ledger_id
	     INTO ln_ledger_id
		 FROM FND_FLEX_VALUES FFV ,
			   fnd_flex_value_sets FFVS,
               gl_ledgers gl
	    WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
		  AND  FFVS.flex_value_set_name IN ( 'OD_GL_GLOBAL_COMPANY')
          AND  gl.short_name = ffv.attribute1
		  AND  FFV.flex_value = lc_company;
	  EXCEPTIOn WHEN OTHERS THEN
	     ln_ledger_id := -1;
	  END;
    END IF;
    RETURN ln_ledger_id;

    EXCEPTION WHEN OTHERS THEN
     -- RAISE_APPLICATION_ERROR(-20564,GET_MESSAGE('0017_MAP_COM_FAILED','COMPANY', p_company, 'LOCATION', p_location),TRUE);
      RETURN NULL;
  END;

--
--  FUNCTION COST_CENTER (
--    p_dept               IN VARCHAR2
--  ) RETURN GL_CODE_COMBINATIONS.segment2%TYPE
--  IS
--    lc_cost_center GL_CODE_COMBINATIONS.segment2%TYPE := NULL;
--    ld_sysdate DATE := TRUNC(SYSDATE);
--  BEGIN
--    IF p_dept IS NOT NULL THEN  -- international employee depts not setup yet, so check if dept exists
--       -- Commented as per Ver 1.1 to improve performance as per defect# 31846
--     /* SELECT p_dept
--      INTO lc_cost_center
--      FROM HR_USORG_LOV_V
--      WHERE UPPER(org_name) like 'CC' || p_dept || '-%'
--        AND ld_sysdate BETWEEN date_from AND NVL(date_to,SYSDATE);*/
--
--      -- Added as per Ver 1.1 as per defect# 31846
--            SELECT p_dept
--              INTO lc_cost_center
--              FROM HR_ALL_ORGANIZATION_UNITS
--             WHERE UPPER(name) like 'CC' || p_dept || '-%'
--               AND ld_sysdate BETWEEN date_from AND NVL(date_to,SYSDATE);
--
--    END IF;
--
----    RETURN TRANSLATION(G_TRANSLATE_COST_CENTER, p_dept);  -- Peoplesoft now in sync, so no translation needed
--    RETURN lc_cost_center;
--
--    EXCEPTION WHEN OTHERS THEN
--      RAISE_APPLICATION_ERROR(-20333,GET_MESSAGE('0018_MAP_CC_FAILED','DEPT', p_dept),TRUE);
--      RETURN NULL;
--  END;  
  
  
  FUNCTION COST_CENTER (
    p_dept               IN VARCHAR2,
	p_BG_id              IN NUMBER
  ) RETURN GL_CODE_COMBINATIONS.segment2%TYPE
  IS
    lc_cost_center GL_CODE_COMBINATIONS.segment2%TYPE := NULL;
    ld_sysdate DATE := TRUNC(SYSDATE);
  BEGIN
    IF p_dept IS NOT NULL THEN  -- international employee depts not setup yet, so check if dept exists
       -- Commented as per Ver 1.1 to improve performance as per defect# 31846
     /* SELECT p_dept
      INTO lc_cost_center
      FROM HR_USORG_LOV_V
      WHERE UPPER(org_name) like 'CC' || p_dept || '-%'
        AND ld_sysdate BETWEEN date_from AND NVL(date_to,SYSDATE);*/

      -- Added as per Ver 1.1 as per defect# 31846
			SELECT p_dept
			  INTO lc_cost_center
			  FROM HR_ALL_ORGANIZATION_UNITS
			 WHERE UPPER(name) like '%CC' || p_dept || '-%'
			   AND ld_sysdate BETWEEN date_from AND NVL(date_to,SYSDATE)
			   AND business_group_id = p_BG_id;
    END IF;

--    RETURN TRANSLATION(G_TRANSLATE_COST_CENTER, p_dept);  -- Peoplesoft now in sync, so no translation needed
    RETURN lc_cost_center;

    EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20333,GET_MESSAGE('0018_MAP_CC_FAILED','DEPT', p_dept),TRUE);
      RETURN NULL;
  END;


  FUNCTION LOCATION (
    p_location           IN VARCHAR2
  ) RETURN GL_CODE_COMBINATIONS.segment4%TYPE
  IS
    ln_location            GL_CODE_COMBINATIONS.segment4%TYPE := NULL;
  BEGIN
    IF p_location IS NOT NULL THEN    -- international employee locations not setup yet, so check if location exists
      SELECT p_location
      INTO   ln_location
      FROM   HR_LOCATIONS_ALL
      WHERE  ATTRIBUTE1=p_location AND ATTRIBUTE2='Y'
        AND  (inactive_date IS NULL OR inactive_date>SYSDATE);
    END IF;

--    RETURN TRANSLATION(G_TRANSLATE_LOCATION, p_location);  -- Peoplesoft now in sync, so no translation needed
    RETURN ln_location;

    EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20223,GET_MESSAGE('0015_MAP_LOC_FAILED','LOC',p_location),TRUE);
      RETURN NULL;
  END;


  FUNCTION ACCOUNT (
    p_description        IN VARCHAR2
  ) RETURN GL_CODE_COMBINATIONS.segment3%TYPE
  IS
  BEGIN
    RETURN TRANSLATION(G_TRANSLATE_ACCOUNT, p_description);
  END;


  FUNCTION INTERCOMPANY
    RETURN GL_CODE_COMBINATIONS.segment5%TYPE
  IS
  BEGIN
    RETURN '0000';
  END;

  FUNCTION LINE_OF_BUSINESS (
    p_location     IN VARCHAR2
   ,p_cost_center  IN VARCHAR2
  ) RETURN GL_CODE_COMBINATIONS.segment6%TYPE
  IS
    lc_lob           GL_CODE_COMBINATIONS.segment6%TYPE := NULL;
    lc_error_message VARCHAR2(2000);
  BEGIN
    XX_GL_TRANSLATE_UTL_PKG.DERIVE_LOB_FROM_COSTCTR_LOC(p_location      => p_location
                                                       ,p_cost_center   => p_cost_center
                                                       ,x_lob           => lc_lob
                                                       ,x_error_message => lc_error_message);
    RETURN lc_lob;
  END;

  FUNCTION FUTURE
    RETURN GL_CODE_COMBINATIONS.segment7%TYPE
  IS
  BEGIN
    RETURN '000000';
  END;


  FUNCTION DEFAULT_CODE_COMB_ID (
     p_set_of_books_id    IN GL_SETS_OF_BOOKS.set_of_books_id%TYPE
    ,p_concat_segs        IN VARCHAR2
  ) RETURN GL_CODE_COMBINATIONS.code_combination_id%TYPE
  IS
    ln_coa_id                GL_SETS_OF_BOOKS.chart_of_accounts_id%TYPE;
    ln_ccid                  GL_CODE_COMBINATIONS.code_combination_id%TYPE;
  BEGIN
    SELECT chart_of_accounts_id INTO ln_coa_id FROM GL_SETS_OF_BOOKS WHERE set_of_books_id=p_set_of_books_id;

    --see GL_CODE_COMBINATIONS_KFV
    ln_ccid := FND_FLEX_EXT.GET_CCID (
                  application_short_name => 'SQLGL'    --application short name of GL, i.e. SQLGL
                 ,key_flex_code          => 'GL#'      --id_flex_code of GL, i.e. GL#
                 ,structure_number       => ln_coa_id  --chart of accounts ID
                 ,validation_date        => TO_CHAR(SYSDATE,'DD-MON-YYYY')
                 ,concatenated_segments  => p_concat_segs
               );
    IF ln_ccid <= 0 THEN -- invalid combo (possibly cross-validation rules are violated)
      RAISE_APPLICATION_ERROR(-20444,FND_FLEX_EXT.GET_MESSAGE || '  ' || p_concat_segs,TRUE);
    ELSE
      COMMIT; -- required if a new combo is created
    END IF;

    RETURN ln_ccid;
  END DEFAULT_CODE_COMB_ID;



END XX_HR_MAPPING_PKG;
/