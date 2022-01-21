SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE XX_AR_GEN_EBILL_WRAP_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        XX_AR_GEN_EBILL_WRAP_PKG                            |
-- | Description :The Program is used to run multithreaded             | 
-- |               based on different customer number ranges.          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |Draft 1   12-AUG-09     Vinaykumar S       Initial version         |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name : SUBMIT_CONS_EBILL                                          |
-- | Description : Procedure used to fetch all the ebill               |
-- |               customers and split them to ranges                  |
-- |                                                                   |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: AR Consolidated Ebill    Program                    |
-- | Parameters :  x_error_buff                                        |
-- |               x_ret_code                                          |
-- |               p_limit_size                                        |
-- |               p_file_path                                         |
-- |               p_as_of_date                                        |
-- |  Returns   :  Error Message                                       |
-- +===================================================================+

PROCEDURE SUBMIT_CONS_EBILL (x_error_buff      OUT  NOCOPY    VARCHAR2
                            ,x_ret_code        OUT  NOCOPY    VARCHAR2
                            ,p_limit_size      IN             NUMBER
                            ,p_file_path       IN             VARCHAR2
                            ,p_as_of_date      IN             VARCHAR2
                             );

END XX_AR_GEN_EBILL_WRAP_PKG;
/
SHOW ERROR
