create or replace 
PACKAGE XX_TOPS_RETIRE_OAF_PKG
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |            Oracle Office Depot   Organization                                             |
-- +===========================================================================================+
-- | Name        : XX_TOPS_RETIRE_OAF_PKG                                                          |
-- | Description : This package is developed to TOPS Retire Project to Drop OAF Pages from Mds repository            |
-- |                                                                                           |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version     Date           Author               Remarks                                    |
-- |=======    ==========      ================     ===========================================|
-- |1.0        11-May-2016     Shubashree Rajanna   Initial draft version                     |
-- +===========================================================================================+
AS
-- +===================================================================+
-- | Name        : main                                                |
-- | Description : This program is directly called from the concurrent | 
-- |               Program to drop objects                             |
-- |                                                                   |
-- | Parameters  : P_DROP_FLAG flag list objects or drop               |
-- +===================================================================+
PROCEDURE MAIN
          (X_ERRBUF                         OUT   VARCHAR2
          ,X_RETCODE                        OUT   varchar2 
          ,P_DROP_FLAG                      IN    VARCHAR2  
          );
 

      
END XX_TOPS_RETIRE_OAF_PKG ;
/

SHOW ERRORS;