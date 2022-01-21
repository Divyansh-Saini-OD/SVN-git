create or replace PACKAGE BODY XX_GL_TRANSLATE_UTL_PKG

AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_TRANSLATE_UTL_PKG                                   |
-- | Description      :  This PKG will be used to translate data that  |
-- |                      will interface with the GL interface tables  |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |1        25-JUN-2007  P.Marco				       |
-- |2        10-OCT-2007  P.Marco          Defect 2385 Created Overload|
-- |                                       Function for DERIVE_COMPANY |
-- |                                       _FROM_LOCATION to handle    |
-- |                                       "010000" location           |
-- |2.1      15-APR-2008 Raji             Defect 6166 - added exception|
-- |                                       for every function          |
-- |2.2      16-APR-2008 Raji             Defect 6212 - Perf issue     |
-- |2.3      18-JUL-2013 Sheetal          I0463 - Changes for R12      |
-- |                                      Upgrade retrofit.            |
-- |2.4      26-JUL-2013 Manasa           IO985 - Changed the flex     |
-- |                                      structure name to            |
-- |                                      OD_GL_GLOBAL_COMPANY for R12 |
-- |                                      Upgrade retrofit.            |
-- |2.5      18-Nov-2015 Avinash Baddam   R12.2 Compliance Changes     |
-- +===================================================================+


-- +===================================================================+
-- | Name  : DERIVE_SOBID_FROM_COMPANY                                 |
-- | Description      : This Function will be used to fetch Set of     |
-- |                    Books ID for a Company   (FND_FLEX_VALUES      |
-- |                     _VL.flex_value)                               |
-- |                                                                   |
-- | Parameters :       Company                                        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          set_of_books_id                                |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

   FUNCTION DERIVE_SOBID_FROM_COMPANY (p_company IN VARCHAR2)
      RETURN NUMBER

   IS
      --x_sob gl_sets_of_books.set_of_books_id%TYPE; Commented as part of R12 Retrofit
	  x_sob gl_ledgers.ledger_id%TYPE; --Added as part of R12 Retrofit

      BEGIN

          --Changed by Manasa for R12 Upgrade Retrofit.
            /*  SELECT GSB.set_of_books_id
                INTO  x_sob
                FROM  FND_ID_FLEX_SEGMENTS_VL   FIFS
                     ,FND_FLEX_VALUES_VL        FFV
                     ,GL_SETS_OF_BOOKS            GSB
                     ,FND_ID_FLEX_STRUCTURES_VL FSTR
               WHERE FIFS.application_column_name       = 'SEGMENT1'
                 AND UPPER(FSTR.id_flex_structure_name) = 'OD_GLOBAL_COA'
                 AND FIFS.id_flex_num                   = FSTR.id_flex_num
                 AND FIFS.flex_value_set_id             = FFV.flex_value_set_id
                 AND FFV.flex_value                     = p_company
             AND FFV.attribute1                     = GSB.short_name;*/


          SELECT  GLL.ledger_id
            INTO  x_sob
            FROM  fnd_flex_values_vl        FFV,
                  fnd_flex_value_sets       FFS,
                  gl_ledgers                  GLL
           WHERE  Ffv.flex_value_set_id              = FFS.flex_value_set_id
             AND  ffs.flex_value_set_name            = 'OD_GL_GLOBAL_COMPANY'
             AND  FFV.flex_value                     = p_company
             AND  FFV.attribute1                     = GLL.short_name;
           -- End of changes

	     RETURN x_sob;
      --Defect 6166
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;

       END DERIVE_SOBID_FROM_COMPANY;



-- +===================================================================+
-- | Name  : DERIVE_COMPANY_FROM_LOCATION                              |
-- | Description      : This Function will be used to fetch Company    |
-- |                    ID for a Location    (FND_FLEX_VALUES          |
-- |                     _VL.flex_value) Segment4                      |
-- | Parameters :       Location (Segment4)                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          company                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     FUNCTION DERIVE_COMPANY_FROM_LOCATION (p_location IN VARCHAR2)
         RETURN VARCHAR2
     IS

         x_company FND_FLEX_VALUES_VL.attribute1%TYPE;

         BEGIN

         --- defect 6212

             SELECT FFV.attribute1
             INTO x_company
              FROM FND_FLEX_VALUES FFV ,
                   fnd_flex_value_sets FFVS
             WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
             AND  FFVS.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
             AND  FFV.flex_value = p_location;

            /* SELECT FFV.attribute1
               INTO x_company
               FROM FND_ID_FLEX_SEGMENTS_VL   FIFS
                   ,FND_FLEX_VALUES_VL        FFV
                   ,FND_ID_FLEX_STRUCTURES_VL FSTR
              WHERE FIFS.application_column_name       = 'SEGMENT4'
                AND UPPER(FSTR.id_flex_structure_name) = 'OD_GLOBAL_COA'
                AND FIFS.id_flex_num                   = FSTR.id_flex_num
                AND FIFS.flex_value_set_id             = FFV.flex_value_set_id
                AND FFV.flex_value                     = p_location;*/

             RETURN x_company;
          --Defect 6166
              EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;


      END DERIVE_COMPANY_FROM_LOCATION;
	  
	  
-- +===================================================================+
-- | Name  : DERIVE_COMPANY_FROM_LOCATION                              |
-- | Description      : This Function will be used to fetch Company    |
-- |                    ID for a Location    (FND_FLEX_VALUES          |
-- |                     _VL.flex_value) Segment4                      |
-- | Parameters :       Location (Segment4)                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          company                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     FUNCTION DERIVE_COM_FROM_LOC_SPIN (p_location IN VARCHAR2)
         RETURN VARCHAR2
     IS

         x_company FND_FLEX_VALUES_VL.attribute1%TYPE;

         BEGIN

         --- defect 6212

             SELECT FFV.attribute1
             INTO x_company
              FROM FND_FLEX_VALUES FFV ,
                   fnd_flex_value_sets FFVS
             WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
             AND  FFVS.flex_value_set_name = 'R_OD_GL_GLOBAL_LOCATION'  -- changed from OD_GL_GLOBAL_LOCATION to R_OD_GL_GLOBAL_LOCATION 2.6
             AND  FFV.flex_value = p_location;

            /* SELECT FFV.attribute1
               INTO x_company
               FROM FND_ID_FLEX_SEGMENTS_VL   FIFS
                   ,FND_FLEX_VALUES_VL        FFV
                   ,FND_ID_FLEX_STRUCTURES_VL FSTR
              WHERE FIFS.application_column_name       = 'SEGMENT4'
                AND UPPER(FSTR.id_flex_structure_name) = 'OD_GLOBAL_COA'
                AND FIFS.id_flex_num                   = FSTR.id_flex_num
                AND FIFS.flex_value_set_id             = FFV.flex_value_set_id
                AND FFV.flex_value                     = p_location;*/

             RETURN x_company;
          --Defect 6166
              EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;


      END DERIVE_COM_FROM_LOC_SPIN;

-- +===================================================================+
-- | Name  : DERIVE_COMPANY_FROM_LOCATION (Overloaded)                 |
-- | Description :  This function will derive company for a given      |
-- |                Location and a Org ID using the GL_OU_DEFAULT_     |
-- |                COMPANY transaltion definition. If company value   |
-- |                can not be derived on table, the  location code    |
-- |                will be passed to the standard DERIVE_COMPANY      |
-- |                _FROM LOCATION function.                           |
-- |                                                                   |
-- | Parameters :       Location (Segment4), ORG_ID                    |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          company                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     FUNCTION DERIVE_COMPANY_FROM_LOCATION (p_location IN VARCHAR2
                                          , p_org_id IN NUMBER)
         RETURN VARCHAR2
     IS

        x_company            xx_fin_translatevalues.target_value1%TYPE;
        x_org_name           HR_OPERATING_UNITS.name%TYPE;
        x_error_message      VARCHAR(2000);

        L_TRANSLATION_TYPE  CONSTANT VARCHAR(21):= 'GL_OU_DEFAULT_COMPANY';

        x_target_value2_out  xx_fin_translatevalues.target_value2%TYPE;
        x_target_value3_out  xx_fin_translatevalues.target_value3%TYPE;
        x_target_value4_out  xx_fin_translatevalues.target_value4%TYPE;
        x_target_value5_out  xx_fin_translatevalues.target_value5%TYPE;
        x_target_value6_out  xx_fin_translatevalues.target_value6%TYPE;
        x_target_value7_out  xx_fin_translatevalues.target_value7%TYPE;
        x_target_value8_out  xx_fin_translatevalues.target_value8%TYPE;
        x_target_value9_out  xx_fin_translatevalues.target_value9%TYPE;
        x_target_value10_out xx_fin_translatevalues.target_value10%TYPE;
        x_target_value11_out xx_fin_translatevalues.target_value11%TYPE;
        x_target_value12_out xx_fin_translatevalues.target_value12%TYPE;
        x_target_value13_out xx_fin_translatevalues.target_value13%TYPE;
        x_target_value14_out xx_fin_translatevalues.target_value14%TYPE;
        x_target_value15_out xx_fin_translatevalues.target_value15%TYPE;
        x_target_value16_out xx_fin_translatevalues.target_value16%TYPE;
        x_target_value17_out xx_fin_translatevalues.target_value17%TYPE;
        x_target_value18_out xx_fin_translatevalues.target_value18%TYPE;
        x_target_value19_out xx_fin_translatevalues.target_value19%TYPE;
        x_target_value20_out xx_fin_translatevalues.target_value20%TYPE;

     BEGIN

         -- Retrieve organization name from org id

          SELECT name
            INTO x_org_name
            FROM HR_OPERATING_UNITS
           WHERE organization_id  = p_org_id;



         XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC (
                              p_translation_name =>  L_TRANSLATION_TYPE
                             ,p_source_value1    =>  p_location
                             ,p_source_value2    =>  x_org_name
                             ,x_target_value1    =>  x_company
                             ,x_target_value2    =>  x_target_value2_out
                             ,x_target_value3    =>  x_target_value3_out
                             ,x_target_value4    =>  x_target_value4_out
                             ,x_target_value5    =>  x_target_value5_out
                             ,x_target_value6    =>  x_target_value6_out
                             ,x_target_value7    =>  x_target_value7_out
                             ,x_target_value8    =>  x_target_value8_out
                             ,x_target_value9    =>  x_target_value9_out
                             ,x_target_value10   =>  x_target_value10_out
                             ,x_target_value11   =>  x_target_value11_out
                             ,x_target_value12   =>  x_target_value12_out
                             ,x_target_value13   =>  x_target_value13_out
                             ,x_target_value14   =>  x_target_value14_out
                             ,x_target_value15   =>  x_target_value15_out
                             ,x_target_value16   =>  x_target_value16_out
                             ,x_target_value17   =>  x_target_value17_out
                             ,x_target_value18   =>  x_target_value18_out
                             ,x_target_value19   =>  x_target_value19_out
                             ,x_target_value20   =>  x_target_value20_out
                             ,x_error_message    =>  x_error_message
                                                                 );

           IF x_company IS NULL THEN

                  x_company := DERIVE_COMPANY_FROM_LOCATION (p_location);

           END IF;

           RETURN x_company;

      --Defect 6166
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;


      END DERIVE_COMPANY_FROM_LOCATION;


-- +===================================================================+
-- | Name  : DERIVE_COMPANY_FROM_LOCATION (Overloaded)                 |
-- | Description :  This function will derive company for a given      |
-- |                Location and a Org Name using the GL_OU_DEFAULT_   |
-- |                COMPANY transaltion definition. If company value   |
-- |                can not be derived on table, the  location code    |
-- |                will be passed to the standard DERIVE_COMPANY      |
-- |                _FROM LOCATION function.                           |
-- |                                                                   |
-- | Parameters :   Location (Segment4), ORG_NAME                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :       company                                           |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     FUNCTION DERIVE_COMPANY_FROM_LOCATION (p_location IN VARCHAR2
                                          , p_org_name IN VARCHAR2)
         RETURN VARCHAR2
     IS

        x_company            xx_fin_translatevalues.target_value1%TYPE;
        x_error_message      VARCHAR(2000);

        L_TRANSLATION_TYPE  CONSTANT VARCHAR(21):= 'GL_OU_DEFAULT_COMPANY';

        x_target_value2_out  xx_fin_translatevalues.target_value2%TYPE;
        x_target_value3_out  xx_fin_translatevalues.target_value3%TYPE;
        x_target_value4_out  xx_fin_translatevalues.target_value4%TYPE;
        x_target_value5_out  xx_fin_translatevalues.target_value5%TYPE;
        x_target_value6_out  xx_fin_translatevalues.target_value6%TYPE;
        x_target_value7_out  xx_fin_translatevalues.target_value7%TYPE;
        x_target_value8_out  xx_fin_translatevalues.target_value8%TYPE;
        x_target_value9_out  xx_fin_translatevalues.target_value9%TYPE;
        x_target_value10_out xx_fin_translatevalues.target_value10%TYPE;
        x_target_value11_out xx_fin_translatevalues.target_value11%TYPE;
        x_target_value12_out xx_fin_translatevalues.target_value12%TYPE;
        x_target_value13_out xx_fin_translatevalues.target_value13%TYPE;
        x_target_value14_out xx_fin_translatevalues.target_value14%TYPE;
        x_target_value15_out xx_fin_translatevalues.target_value15%TYPE;
        x_target_value16_out xx_fin_translatevalues.target_value16%TYPE;
        x_target_value17_out xx_fin_translatevalues.target_value17%TYPE;
        x_target_value18_out xx_fin_translatevalues.target_value18%TYPE;
        x_target_value19_out xx_fin_translatevalues.target_value19%TYPE;
        x_target_value20_out xx_fin_translatevalues.target_value20%TYPE;

     BEGIN



          XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC (
                              p_translation_name =>  L_TRANSLATION_TYPE
                             ,p_source_value1    =>  p_location
                             ,p_source_value2    =>  p_org_name
                             ,x_target_value1    =>  x_company
                             ,x_target_value2    =>  x_target_value2_out
                             ,x_target_value3    =>  x_target_value3_out
                             ,x_target_value4    =>  x_target_value4_out
                             ,x_target_value5    =>  x_target_value5_out
                             ,x_target_value6    =>  x_target_value6_out
                             ,x_target_value7    =>  x_target_value7_out
                             ,x_target_value8    =>  x_target_value8_out
                             ,x_target_value9    =>  x_target_value9_out
                             ,x_target_value10   =>  x_target_value10_out
                             ,x_target_value11   =>  x_target_value11_out
                             ,x_target_value12   =>  x_target_value12_out
                             ,x_target_value13   =>  x_target_value13_out
                             ,x_target_value14   =>  x_target_value14_out
                             ,x_target_value15   =>  x_target_value15_out
                             ,x_target_value16   =>  x_target_value16_out
                             ,x_target_value17   =>  x_target_value17_out
                             ,x_target_value18   =>  x_target_value18_out
                             ,x_target_value19   =>  x_target_value19_out
                             ,x_target_value20   =>  x_target_value20_out
                             ,x_error_message    =>  x_error_message
                                                                 );

           IF x_company IS NULL THEN

                  x_company := DERIVE_COMPANY_FROM_LOCATION (p_location);

           END IF;

           RETURN x_company;

      --Defect 6166
              EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;


      END DERIVE_COMPANY_FROM_LOCATION;



-- +===================================================================+
-- | Name  : DERIVE_GL_ORA_LOC_TYPE                                    |
-- | Description      : This Function will be used to fetch Location   |
-- |                    type for a Location_id (FND_FLEX_VALUES   |
-- |                     _VL.flex_value) Segment4. Location type will  |
-- |                    be derived from dff segment 1                  |
-- | Parameters :       Location    (Segment4)                         |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          Location type                                  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     FUNCTION DERIVE_GL_ORA_LOC_TYPE  (p_location IN VARCHAR2)
            RETURN VARCHAR2
     IS

        x_location_type FND_FLEX_VALUES_VL.attribute2%TYPE;

        BEGIN

         --- defect 6212

             SELECT FFV.attribute2
             INTO x_Location_type
              FROM FND_FLEX_VALUES FFV ,
                   fnd_flex_value_sets FFVS
             WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
             AND  FFVS.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
             AND  FFV.flex_value = p_location;

            /*  SELECT FFV.attribute2
                INTO  x_Location_type
                FROM  FND_ID_FLEX_SEGMENTS_VL   FIFS
                     ,FND_FLEX_VALUES_VL        FFV
                     ,FND_ID_FLEX_STRUCTURES_VL FSTR
               WHERE FIFS.application_column_name       = 'SEGMENT4'
                 AND UPPER(FSTR.id_flex_structure_name) = 'OD_GLOBAL_COA'
                 AND FIFS.id_flex_num                   = FSTR.id_flex_num
                 AND FIFS.flex_value_set_id             = FFV.flex_value_set_id
                 AND FFV.flex_value                     = p_location;*/

               RETURN x_Location_type;

      --Defect 6166
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;

      END DERIVE_GL_ORA_LOC_TYPE;


-- +===================================================================+
-- | Name  : GL_ORA_COSCTR_TYPE                                        |
-- | Description      : This Function will be used to return Cost      |
-- |                    Center Type from a given Cost Center           |
-- |                    APPLSYS.FND_FLEX_VALUES_VL.flex_value)         |
-- |                                                                   |
-- | Parameters :       Cost_Center                                    |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          Cost_center_type                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     FUNCTION DERIVE_GL_ORA_COSCTR_TYPE   (p_cost_center IN VARCHAR2)
             RETURN VARCHAR2
     IS
          x_cost_center_type FND_FLEX_VALUES_VL.attribute2%TYPE;

     BEGIN

      --- defect 6212

             SELECT FFV.attribute1
             INTO x_cost_center_type
              FROM FND_FLEX_VALUES FFV ,
                   fnd_flex_value_sets FFVS
             WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
             AND  FFVS.flex_value_set_name = 'OD_GL_GLOBAL_COST_CENTER'
             AND  FFV.flex_value = p_cost_center;

/*          SELECT FFV.attribute1
            INTO x_cost_center_type
            FROM FND_ID_FLEX_SEGMENTS_VL    FIFS
                ,FND_FLEX_VALUES_VL        FFV
                ,FND_ID_FLEX_STRUCTURES_VL FSTR
           WHERE FIFS.application_column_name       = 'SEGMENT2'
             AND UPPER(FSTR.id_flex_structure_name) = 'OD_GLOBAL_COA'
             AND FIFS.id_flex_num                   = FSTR.id_flex_num
             AND FIFS.flex_value_set_id             = FFV.flex_value_set_id
             AND FFV.flex_value                     = p_cost_center;*/

          RETURN x_cost_center_type;
           --Defect 6166
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;

     END DERIVE_GL_ORA_COSCTR_TYPE ;

-- +===================================================================+
-- | Name  :  DERIVE_GL_PERIOD_NAME                                    |
-- | Description      : This Function will be used to return gl_period |
-- |                    based on the transaction date.                 |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Transaction_date must be in the format of      |
-- |                    DD-MON-YY or DD-MON-YYYY, Set of books id      |
-- |                                                                   |
-- | Returns :          GL_Period                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


FUNCTION DERIVE_GL_PERIOD_NAME  (p_trans_date IN DATE, p_sob_id IN NUMBER)
     RETURN VARCHAR2
IS
     x_gl_period_name GL_PERIODS.period_name%TYPE;

     BEGIN
           SELECT  GP.period_name
             INTO  x_gl_period_name
             FROM  GL_PERIODS        GP
                  --,GL_SETS_OF_BOOKS  GSB Commented as part of R12 Retrofit
				  ,GL_LEDGERS        GL --Added as part of R12 Retrofit
            WHERE GP.start_date      <= p_trans_date
              AND GP.end_date        >= p_trans_date
              AND GP.period_set_name  = GL.period_set_name
              --AND GSB.set_of_books_id = p_sob_id; Commented as part of R12 Retrofit
			  AND GL.ledger_id = p_sob_id; --Added as part of R12 Retrofit

           RETURN x_gl_period_name;

      --Defect 6166

              EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;

      END DERIVE_GL_PERIOD_NAME;




-- +===================================================================+
-- | Name  :  DERIVE_GL_PERIOD_NAME_NEXT                               |
-- | Description      : This Function will be used to return gl_period |
-- |                    based on the transaction date.                 |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Transaction_date must be in the format of      |
-- |                    DD-MON-YY or DD-MON-YYYY, set of books id      |
-- |                                                                   |
-- | Returns :          GL_Period  + 1                                 |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


   FUNCTION DERIVE_GL_PERIOD_NAME_NEXT(p_trans_date IN DATE, p_sob_id IN NUMBER)
        RETURN VARCHAR2
   IS
        x_gl_period_name  GL_PERIODS.period_name%TYPE;
        x_gl_period_num   GL_PERIODS.period_num%TYPE;
        x_gl_period_year  GL_PERIODS.period_year%TYPE;

        BEGIN

             SELECT GP.period_num, GP.period_year --find cur period_num and year
               INTO x_gl_period_num, x_gl_period_year
               FROM GL_PERIODS         GP
                   --,GL_SETS_OF_BOOKS   GSB Commented as part of R12 Retrofit
				   ,GL_LEDGERS   GL --Added as part of R12 Retrofit
              WHERE GP.start_date      <= p_trans_date
                AND GP.end_date        >= p_trans_date
                --AND GP.period_set_name  = GSB.period_set_name Commented as part of R12 Retrofit
				AND GP.period_set_name  = GL.period_set_name --Added as part of R12 Retrofit
                --AND GSB.set_of_books_id = p_sob_id; Commented as part of R12 Retrofit
				AND GL.ledger_id = p_sob_id; --Added as part of R12 Retrofit
             IF x_gl_period_num   = 12 then       -- if Dec then increment year.
                x_gl_period_num  :=  1;
                x_gl_period_year :=  x_gl_period_year + 1;

             ELSE

                x_gl_period_num  :=  x_gl_period_num + 1;

             END IF;

             SELECT GP.period_name                   -- find next period.
               INTO x_gl_period_name
               FROM  GL_PERIODS       GP
                    --,GL_SETS_OF_BOOKS GSB Commented as part of R12 Retrofit
					,GL_LEDGERS GL --Added as part of R12 Retrofit
              WHERE  GP.period_num          =  x_gl_period_num
                AND    GP.period_year       =  x_gl_period_year
                --AND    GP.period_set_name   =  GSB.period_set_name Commented as part of R12 Retrofit
				AND    GP.period_set_name   =  GL.period_set_name --Added as part of R12 Retrofit
                --AND    GSB.set_of_books_id  =  p_sob_id; Commented as part of R12 Retrofit
				AND    GL.ledger_id  =  p_sob_id; --Added as part of R12 Retrofit

             RETURN x_gl_period_name;

      --Defect 6166
                EXCEPTION
             WHEN NO_DATA_FOUND THEN
             RETURN NULL;

	END DERIVE_GL_PERIOD_NAME_NEXT;


-- +===================================================================+
-- | Name  : DERIVE_LOB_FROM_COSTCTR_LOC                               |
-- | Description      : This Procedure will derive the LOB from the    |
-- |                    cost_center_type and the location_type.        |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Cost_Center, Location                          |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          line_of_business, error_message, return_code   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE DERIVE_LOB_FROM_COSTCTR_LOC (p_location            IN  VARCHAR2
                                         , p_cost_center         IN  VARCHAR2
                                         , x_lob                 OUT VARCHAR2
                                         , x_error_message       OUT VARCHAR2
					   )
    IS

	EX_LOC_AND_CC_TYPE  EXCEPTION;
	EX_LOC_TYPE         EXCEPTION;
        EX_CC_TYPE          EXCEPTION;


        lc_location_type    FND_FLEX_VALUES_VL.attribute2%TYPE;
        lc_cost_center_type FND_FLEX_VALUES_VL.attribute1%TYPE;

	L_TRANSLATION_TYPE  CONSTANT VARCHAR(21):= 'GL_COSTCTR_LOC_TO_LOB';

	lc_loc_type_err     VARCHAR2(1000);
	lc_cc_type_err      VARCHAR2(1000);


       -- Nothing is loaded to the following  x_target_value... variables.
       -- They are only needed to make XX_FIN_TRANSLATEVALUE_PROC exec correctly

        x_target_value2_out  xx_fin_translatevalues.target_value2%TYPE;
        x_target_value3_out  xx_fin_translatevalues.target_value3%TYPE;
        x_target_value4_out  xx_fin_translatevalues.target_value4%TYPE;
        x_target_value5_out  xx_fin_translatevalues.target_value5%TYPE;
        x_target_value6_out  xx_fin_translatevalues.target_value6%TYPE;
        x_target_value7_out  xx_fin_translatevalues.target_value7%TYPE;
        x_target_value8_out  xx_fin_translatevalues.target_value8%TYPE;
        x_target_value9_out  xx_fin_translatevalues.target_value9%TYPE;
        x_target_value10_out xx_fin_translatevalues.target_value10%TYPE;
        x_target_value11_out xx_fin_translatevalues.target_value11%TYPE;
        x_target_value12_out xx_fin_translatevalues.target_value12%TYPE;
        x_target_value13_out xx_fin_translatevalues.target_value13%TYPE;
        x_target_value14_out xx_fin_translatevalues.target_value14%TYPE;
        x_target_value15_out xx_fin_translatevalues.target_value15%TYPE;
        x_target_value16_out xx_fin_translatevalues.target_value16%TYPE;
        x_target_value17_out xx_fin_translatevalues.target_value17%TYPE;
        x_target_value18_out xx_fin_translatevalues.target_value18%TYPE;
        x_target_value19_out xx_fin_translatevalues.target_value19%TYPE;
        x_target_value20_out xx_fin_translatevalues.target_value20%TYPE;

	BEGIN


           BEGIN
              -- Calling function to find location type.

              lc_location_type := DERIVE_GL_ORA_LOC_TYPE (p_location);

            EXCEPTION
                WHEN OTHERS THEN

                     lc_loc_type_err :=' XX_GL_TRANSLATE_UTL_PKG.'||
                                       'DERIVE_GL_ORA_LOC_TYPE:'  || SQLERRM;
           END;


           BEGIN
              -- Calling function to find location type.

              lc_cost_center_type := DERIVE_GL_ORA_COSCTR_TYPE (p_cost_center);

           EXCEPTION
                WHEN OTHERS THEN
                      lc_cc_type_err := ' XX_GL_TRANSLATE_UTL_PKG.'||
                                      'DERIVE_GL_ORA_COSCTR_TYPE: '||SQLERRM;
           END;


              IF lc_loc_type_err IS NULL AND  lc_cc_type_err IS NULL THEN

                  XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC (
                                    p_translation_name =>  L_TRANSLATION_TYPE
                                   ,p_source_value2    =>  lc_location_type
                                   ,p_source_value1    =>  lc_cost_center_type
                                   ,x_target_value1    =>  x_lob
                                   ,x_target_value2    =>  x_target_value2_out
                                   ,x_target_value3    =>  x_target_value3_out
                                   ,x_target_value4    =>  x_target_value4_out
                                   ,x_target_value5    =>  x_target_value5_out
                                   ,x_target_value6    =>  x_target_value6_out
                                   ,x_target_value7    =>  x_target_value7_out
                                   ,x_target_value8    =>  x_target_value8_out
                                   ,x_target_value9    =>  x_target_value9_out
                                   ,x_target_value10   =>  x_target_value10_out
                                   ,x_target_value11   =>  x_target_value11_out
                                   ,x_target_value12   =>  x_target_value12_out
                                   ,x_target_value13   =>  x_target_value13_out
                                   ,x_target_value14   =>  x_target_value14_out
                                   ,x_target_value15   =>  x_target_value15_out
                                   ,x_target_value16   =>  x_target_value16_out
                                   ,x_target_value17   =>  x_target_value17_out
                                   ,x_target_value18   =>  x_target_value18_out
                                   ,x_target_value19   =>  x_target_value19_out
                                   ,x_target_value20   =>  x_target_value20_out
                                   ,x_error_message    =>  x_error_message
                                                                       );

                ELSIF lc_loc_type_err IS NOT NULL AND lc_cc_type_err IS NOT NULL
                    THEN
                         RAISE EX_LOC_AND_CC_TYPE;

                    ELSIF lc_loc_type_err IS NOT NULL THEN
                            RAISE EX_LOC_TYPE;

                        ELSE
                               RAISE EX_CC_TYPE;

                END IF;

	 EXCEPTION
                 WHEN EX_LOC_AND_CC_TYPE THEN
                        x_error_message := lc_loc_type_err ||' and' ||
                                           lc_cc_type_err;

                 WHEN EX_LOC_TYPE THEN
                        x_error_message := lc_loc_type_err;


                 WHEN EX_CC_TYPE THEN
                        x_error_message := lc_cc_type_err;

   		 WHEN OTHERS THEN
			x_error_message := SQLERRM;

	END DERIVE_LOB_FROM_COSTCTR_LOC;

END XX_GL_TRANSLATE_UTL_PKG;
/