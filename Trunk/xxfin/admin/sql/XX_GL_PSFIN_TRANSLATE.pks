create or replace PACKAGE      XX_GL_PSFIN_TRANSLATE_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |              	Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_GL_PSFIN_TRANSLATE_PKG                                 |
-- | Description :   Package to extract Oracle to Peoplesoft GL        |
-- |                 translations into a file that is FTPed to the     |
-- |                 mainframe. The file is used to update DB2 table   |
-- |                 OD.TRANTBL.                                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       07-JUL-2008 D.Nardo          Initial version             |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name  : GL_PSFIN_TRANSLATIONS                                     |
-- | Description :                                                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : Process invoked as a concurrent program therefore    |
-- |              pass errbuff and retcode.                            |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

  PROCEDURE  GL_PSFIN_TRANSLATIONS( errbuff OUT varchar2, 
                                  retcode OUT varchar2);



END XX_GL_PSFIN_TRANSLATE_PKG;
/