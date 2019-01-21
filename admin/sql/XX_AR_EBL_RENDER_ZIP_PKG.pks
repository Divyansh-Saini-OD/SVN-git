create or replace
PACKAGE XX_AR_EBL_RENDER_ZIP_PKG AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_AR_EBL_RENDER_ZIP_PKG                                                             |
-- | Description : Package body for eBilling zip rendering concurrent program                           |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       15-Apr-2010 Bushrod Thomas     Initial draft version.      			 	                        |
-- |                                                                                                    |
-- +====================================================================================================+
*/

  PROCEDURE RENDER_ZIP_P (
    Errbuf                 OUT NOCOPY VARCHAR2
   ,Retcode                OUT NOCOPY VARCHAR2
  );

  PROCEDURE TRANSMISSIONS_TO_ZIP (
    P_TREAD_ID    IN NUMBER
   ,P_TREAD_COUNT IN NUMBER   
   ,X_CURSOR      OUT SYS_REFCURSOR
  );

  PROCEDURE FILES_TO_ZIP (
    P_TRANSMISSION_ID IN NUMBER
   ,X_CURSOR          OUT SYS_REFCURSOR
  );  

  PROCEDURE SHOW_FILES_TO_ZIP (
    P_TREAD_ID    IN NUMBER
   ,P_TREAD_COUNT IN NUMBER
  );

END XX_AR_EBL_RENDER_ZIP_PKG;


/
