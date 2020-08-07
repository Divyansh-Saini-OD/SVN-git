
CREATE OR REPLACE PACKAGE XX_GL_TRANSLATE_UTL_PKG
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
-- |                                                                   |
-- +===================================================================+


-- +===================================================================+
-- | Name  : DERIVE_SOBID_FROM_COMPANY                                 |
-- | Description      : This Function will be used to fetch Set of     |
-- |                    Books ID for a Company (APPS.FND_FLEX_VALUES   |
-- |                     _VL.flex_value)                               |
-- | Parameters :       Company                                        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          set_of_books_id                                |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

	FUNCTION DERIVE_SOBID_FROM_COMPANY (p_company IN VARCHAR2)
	RETURN NUMBER;


-- +===================================================================+
-- | Name  : DERIVE_COMPANY_FROM_LOCATION                              |
-- | Description      : This Function will be used to fetch Company    |
-- |                    ID for a Location    (APPS.FND_FLEX_VALUES     |
-- |                     _VL.flex_value) Segment4                      |
-- | Parameters :       Location (Segment4)                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          company                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

	FUNCTION DERIVE_COMPANY_FROM_LOCATION  (p_location IN VARCHAR2)
	RETURN VARCHAR2;


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
                                           ,p_org_id IN NUMBER)
         RETURN VARCHAR2;





-- +===================================================================+
-- | Name  : DERIVE_COMPANY_FROM_LOCATION (Overloaded)                 |
-- | Description :  This function will derive company for a given      | 
-- |                Location and a Org Name using the GL_OU_DEFAULT_   |
-- |                COMPANY transaltion definition. If company value   | 
-- |                can not be derived on table, the  location code    |
-- |                will be passed to the standard DERIVE_COMPANY      |
-- |                _FROM LOCATION function.                           |
-- |                                                                   |
-- | Parameters :       Location (Segment4), ORG_NAME                  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          company                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     FUNCTION DERIVE_COMPANY_FROM_LOCATION (p_location IN VARCHAR2 
                                           ,p_org_name IN VARCHAR2)
         RETURN VARCHAR2;



-- +===================================================================+
-- | Name  :  DERIVE_GL_PERIOD_NAME                                    |
-- | Description      : This Function will be used to return gl_period |
-- |                    based on the transaction date.                 |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Transaction_date                               |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          GL_Period                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

	FUNCTION DERIVE_GL_PERIOD_NAME  (p_trans_date IN DATE, p_sob_id number)
		RETURN VARCHAR2;



-- +===================================================================+
-- | Name  :  DERIVE_GL_PERIOD_NAME_NEXT                               |
-- | Description      : This Function will be used to return gl_period |
-- |                    based on the transaction date.                 |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Transaction_date                               |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          GL_Period                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

	FUNCTION DERIVE_GL_PERIOD_NAME_NEXT  (p_trans_date IN DATE 
                                              ,p_sob_id IN NUMBER)
		RETURN VARCHAR2;



-- +===================================================================+
-- | Name  : DERIVE_LOB_FROM_COSTCTR_LOC                               |
-- | Description      : This Procedure will derive the LOB from the    |
-- |                    cost_center_type and the location_type.        |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Cost_Center, Location                          |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          line_of_business                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

	PROCEDURE DERIVE_LOB_FROM_COSTCTR_LOC (	p_location        IN  VARCHAR2
						, p_cost_center   IN  VARCHAR2
						, x_lob           OUT VARCHAR2
						, x_error_message OUT VARCHAR2
					       );



END XX_GL_TRANSLATE_UTL_PKG;

/




