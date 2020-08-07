CREATE OR REPLACE PACKAGE XX_FA_DEPR_PROJ_PKG   
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_FA_DEPR_PROJ_PKG                                       |
-- | Description :  
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-JAN-2010 P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name  :XX_DEPR_PROJ_LOAD_STG                                      |
-- | Description : Per CR646 This procedure will be used to submit the |
-- | Standard Depreciation Projection program and copy the data  from  |
-- | the temp table to the staging table.                              |
-- |                                                                   |
-- | Parameters :                                                      |
-- |               errbuff        OUT VARCHAR2  Error message          |  
-- |               retcode        OUT VARCHAR2  Error Code             | 
-- |               p_calendar     IN  VARCHAR2  Calender Date          |
-- |               p_start_period IN  VARCHAR2  Starting period        | 
-- |               p_num_periods  IN  VARCHAR2  NUmber of Periods      |
-- |               p_asset_Bk1    IN  VARCHAR2  Asset book name 1      |  
-- |               p_asset_Bk2    IN  VARCHAR2  Asset Book Name 2      |
-- |               p_asset_Bk3    IN  VARCHAR2  Asset Book Name 3      | 
-- |               p_asset_Bk4    IN  VARCHAR2  Asset book Name 4      |                   
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE XX_DEPR_PROJ_LOAD_STG (errbuff        OUT VARCHAR2
                                    ,retcode        OUT VARCHAR2
                                    ,p_calendar     IN  VARCHAR2
                                    ,p_start_period IN  VARCHAR2
                                    ,p_num_periods  IN  VARCHAR2
                                    ,p_asset_Bk1    IN  VARCHAR2 DEFAULT NULL
                                    ,p_asset_Bk2    IN  VARCHAR2 DEFAULT NULL
                                    ,p_asset_Bk3    IN  VARCHAR2 DEFAULT NULL 
                                    ,p_asset_Bk4    IN  VARCHAR2 DEFAULT NULL);


-- +===================================================================+
-- | Name  :XX_DEPR_PROJ_RPT                                           |
-- | Description :                                                     |
-- | Description : Per CR646 This procedure will be used to submit the |
-- | Standard Depreciation Projection program and copy the data from   |
-- | the temp table to the staging table.                              |  
-- |                                                                   |
-- | Parameters :                                                      |
-- |              errbuff        OUT VARCHAR2                          |
-- |              retcode        OUT VARCHAR2                          |
-- |              p_asset_book   IN  VARCHAR2 Asset Book               |  
-- |              p_corp         IN  VARCHAR2 Corporation              |  
-- |              p_cost_center  IN  VARCHAR2 Cost Center              |
-- |              p_Account      IN  VARCHAR2 Account                  |
-- |              p_location     IN  VARCHAR2 Location                 |
-- |              P_lob          IN  VARCHAR2 Line of Business         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE XX_DEPR_PROJ_RPT  (errbuff        OUT VARCHAR2
                                ,retcode        OUT VARCHAR2
                                ,p_asset_book   IN  VARCHAR2
                                ,p_corp         IN  VARCHAR2 DEFAULT NULL
                                ,p_cost_center  IN  VARCHAR2 DEFAULT NULL
                                ,p_Account      IN  VARCHAR2 DEFAULT NULL
                                ,p_location     IN  VARCHAR2 DEFAULT NULL
                                ,P_lob          IN  VARCHAR2 DEFAULT NULL
                                ,P_delimiter    IN  VARCHAR2 DEFAULT NULL  
                                );




END XX_FA_DEPR_PROJ_PKG;
/

