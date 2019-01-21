create or replace
PACKAGE XX_FIN_COPY_TO_XPTR_PKG IS
 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Wipro Technologies                          |
-- +===================================================================+
-- | Name  : XX_FIN_HTTP_PKG                                           |
-- | Description      :  This PKG will get req id output to XPTR       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |          13-JAN-2014 Ray Strauss      Initial draft version       |
-- +===================================================================+
PROCEDURE SEND_TO_XPTR(x_error_buff              OUT  VARCHAR2
                      ,x_ret_code                OUT  NUMBER
                      ,p_req_id                  IN   NUMBER
                      ,p_child_pgm               IN   VARCHAR2
                      ,p_path_name               IN   VARCHAR2
                       );
 END XX_FIN_COPY_TO_XPTR_PKG;
/