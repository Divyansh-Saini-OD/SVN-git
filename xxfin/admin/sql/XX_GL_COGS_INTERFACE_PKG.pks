create or replace
PACKAGE XX_GL_COGS_INTERFACE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_GL_GSS_INTERFACE_PKG                                   |
-- | Description      :  This PKG will be used to COGS interfaces      |
-- |                     data feed with with the Oracle GL             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       06-25/2007  P.Marco          Initial draft version       |
-- |1.1       24-JUNE-08  Raji             Added values for defect 8242|
-- |1.2       25-JUL-2008 Mano             Added a parameter           |
-- |                                       for Batch Size              |
-- |1.3       04-AUG-2008 Manovinayak      Added parameter for the     |
-- |                                       defect#9419                 |
-- +===================================================================+

-- +===================================================================+
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for ce intface  |
-- |                                                                   |
-- | Parameters :   p_source_name,  p_debug_flg                        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :  x_return_message, x_return_code                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

--G_BATCH_SIZE NUMBER  := 50000;   --- added for defect 8242
G_SYSDATE DATE := SYSDATE ;      --- added for defect 8242

     PROCEDURE PROCESS_JOURNALS (
                                  x_return_message    OUT  VARCHAR2
                                 ,x_return_code      OUT  VARCHAR2
                                 ,p_source_name       IN  VARCHAR2
                                 ,p_debug_flg         IN  VARCHAR2 DEFAULT 'N'
                                 ,P_BATCH_SIZE        IN  NUMBER DEFAULT '50000' -- Added as part of defect # 9123
                                 ,P_SET_OF_BOOKS_ID   IN NUMBER --Added for the defect#9419
                                );
------------Funtion To fetch the LOB values                                    -------------Added as part of Defect #3456

     FUNCTION XX_DERIVE_LOB(p_location IN VARCHAR2)
     RETURN NUMBER;

END XX_GL_COGS_INTERFACE_PKG;
/