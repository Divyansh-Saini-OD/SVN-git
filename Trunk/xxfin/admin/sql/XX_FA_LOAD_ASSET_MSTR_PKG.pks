create or replace
PACKAGE XX_FA_LOAD_ASSET_MSTR_PKG   
AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		                         |
-- +===================================================================+
-- | Name  : VALIDATION_REPORT                                         |
-- | Description : Procedure to allow user to run validation report    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+

    procedure VALIDATION_REPORT (ERRBUFF               OUT NOCOPY VARCHAR2
                                ,RETCODE               OUT NOCOPY VARCHAR2
                                ,P_BOOK_TYPE_CODE1     IN VARCHAR2
                                ,P_BOOK_TYPE_CODE2     IN VARCHAR2
                                ,P_BOOK_TYPE_CODE3     IN VARCHAR2
                                ,P_BOOK_TYPE_CODE4     IN VARCHAR2
                                ,P_BOOK_TYPE_CODE5     IN VARCHAR2                                
                                ,P_ATTRIBUTE11         IN VARCHAR2
                                ,P_PERIOD_NAME         IN NUMBER
                                ,P_DELIMITER           IN VARCHAR2
                                 );


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization                     		       |
-- +===================================================================+
-- | Name  : PURGE_INTERFACE_TBL                                       |
-- | Description : Procedure for purging interface tables              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+


  PROCEDURE PURGE_INTERFACE_TBL (ERRBUFF        OUT NOCOPY VARCHAR2
                                ,RETCODE        OUT NOCOPY VARCHAR2
                                ,P_PURG_MASS_FLG IN  VARCHAR2 DEFAULT 'N'
                                ,P_PURG_TAX_FLG  IN  VARCHAR2 DEFAULT 'N'
                             --   ,P_TAX_LABEL    IN  VARCHAR2
                            --    ,p_asset_book   IN  VARCHAR2
                                 );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : GET_ASSET_NUMBER                                          |
-- | Description : Used during the SQLLOADING of Adjusted Asset.  The  |
-- |  Function will look up the new created asset number to and add it |  
-- |  to the  FA_TAX_INTERACE table                                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+


   FUNCTION  GET_ASSET_NUMBER (P_BUS_UNIT     IN  VARCHAR2
                              ,P_TAX_ASSET_ID IN VARCHAR2 ) 
      RETURN VARCHAR2;

    -- +===================================================================+
    -- |                  Office Depot - Project Simplify                  |
    -- |      		Office Depot Organization   		                         |
    -- +===================================================================+
    -- | Name  : GET_LOCATION_ID                                           |
    -- | Description : Used during the SQLLOADING of Reinstated Assets. The|
    -- |  Function will look up the location_ID and add it                 |  
    -- |  to the FA_MASS_ADDTIONS table                                    |
    -- |                                                                   |
    -- |Change Record:                                                     |
    -- |===============                                                    |
    -- |Version   Date        Author           Remarks            	       |
    -- |=======   ==========  =============    ============================|
    -- |DRAFT 1A  07-OCT-2010 P.Marco          Initial draft version       |
    -- |                                                                   |
    -- +===================================================================+  
    FUNCTION  GET_LOCATION_ID (P_LOCATION  IN  VARCHAR2 ) 
      RETURN  NUMBER;

-- +===================================================================+
-- | Name  :EXECUTE_LOAD                           |
-- | Description : Main program called from the following concurrent   |
-- |   OD: FA Mass Additions for Reinstated R and M Assets             |
-- |   OD: FA Tax Interface for Accelerated R And M Assets                 |
-- |   OD: FA Tax Interface for Reinstated Adjusted R AND M Assets         |
-- |   OD: FA Tax Interface for Bonus Depreciation                     |
-- | Parameters :                                                      |
-- |      errbuff          OUT VARCHAR2  Error message                 |  
-- |      retcode          OUT VARCHAR2  Error Code                    |
-- |      P_LOAD_PROGRAM    IN VARCHAR2  Sql Loader program            | 
-- |      P_DATA_FILE       IN VARCHAR2  Loader dta file               |
-- |      P_ATTRIBUTE11     IN VARCHAR2  Label to identify records     | 
-- |      P_PURGE_TABLE_FLG IN VARCHAR2  Purge table flag              |
-- |                                                                   | 
-- +===================================================================+

    PROCEDURE EXECUTE_LOAD     (ERRBUFF               OUT NOCOPY VARCHAR2
                               ,retcode               OUT NOCOPY VARCHAR2
                               ,P_LOAD_PROGRAM        IN  VARCHAR2 
                               ,P_DATA_FILE           IN VARCHAR2
                               ,P_PURGE_TABLE_FLG     IN VARCHAR2
                               ,P_ATTRIBUTE11         IN VARCHAR2 DEFAULT NULL
                               ,P_ATTRIBUTE11_1       IN VARCHAR2 DEFAULT NULL

                               );



END XX_FA_LOAD_ASSET_MSTR_PKG;
/
