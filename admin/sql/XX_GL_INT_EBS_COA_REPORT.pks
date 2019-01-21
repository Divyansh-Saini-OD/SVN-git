create or replace
PACKAGE XX_GL_INT_EBS_COA_REPORT IS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                       Office Depot Inc.,                                      |
-- +===============================================================================+
-- | Name :      XX_GL_INT_EBS_COA_REPORT                                          |
-- | Description : Package used for created COA report from Peoplesoft             |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date          Author             Remarks                             | 
-- |=======   ==========   =============       =======================             |
-- |1.0       07-Jun-2012  Sinon Perlas        Initial version                     |
-- +===============================================================================+

  PROCEDURE COA_REPORT_MAIN (ERRBUFF     OUT VARCHAR2,
                             retcode     OUT varchar2,
                             p_source_nm  in VARCHAR2);
                             --p_request_id in VARChAR2);
END XX_GL_INT_EBS_COA_REPORT;
/