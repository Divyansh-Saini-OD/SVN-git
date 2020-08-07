create or replace 
PACKAGE XX_OD_GL_GLOBAL_COA_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Oracle GSD		                             |
-- +=====================================================================+
-- | Name : XX_OD_GL_GLOBAL_COA_PKG                                      |
-- | Defect# 10676		                                                 |
-- | Description : This package houses the report submission procedure   |
-- |              									                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  27-Jul-11      Sai Kumar Reddy      Initial version        |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_OD_GL_GLOBAL_COA_PRC                                     |
-- | Description : This procedure will submit the GL Global COA report	 |
-- |               			                                             |
-- | Returns     : x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE XX_OD_GL_GLOBAL_COA_PRC (
                             x_err_buff    OUT VARCHAR2,
							 x_ret_code    OUT NUMBER
                            );
END XX_OD_GL_GLOBAL_COA_PKG;
/