create or replace
PACKAGE XX_AR_EBL_RENDER_STUB_PKG AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_AR_EBL_RENDER_STUB_PKG                                                            |
-- | Description : Package body for eBilling remittance stub generation                                 |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       05-Feb-2010 Bushrod Thomas     Initial draft version.      			 	                        |
-- |                                                                                                    |
-- +====================================================================================================+
*/

  -- Parent concurrent program; starts Java child threads
  PROCEDURE RENDER_STUB_P (
    Errbuf                 OUT NOCOPY VARCHAR2
   ,Retcode                OUT NOCOPY VARCHAR2
  );

  -- Returns recordset of file_id's to render
  PROCEDURE STUBS_TO_RENDER (
    P_TREAD_ID    IN NUMBER
   ,P_TREAD_COUNT IN NUMBER   
   ,X_CURSOR      OUT SYS_REFCURSOR
  );

  -- Returns XML used by BI Publisher template to generate remittance stub
  PROCEDURE GET_STUB_XML (
    P_FILE_ID IN NUMBER
   ,X_XML     OUT CLOB
  );

  -- outputs results of STUBS_TO_RENDER (for debugging)
  PROCEDURE SHOW_STUBS_TO_RENDER (
    P_TREAD_ID    IN NUMBER
   ,P_TREAD_COUNT IN NUMBER
  );

  -- outputs XML from GET_STUB_XML (for debugging)
  PROCEDURE SHOW_STUB_XML (
    P_FILE_ID IN NUMBER
  );

END XX_AR_EBL_RENDER_STUB_PKG;

/
