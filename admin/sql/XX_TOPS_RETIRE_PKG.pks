 

CREATE OR REPLACE PACKAGE XX_TOPS_RETIRE_PKG
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- |            Oracle Office Depot   Organization                                             |
-- +===========================================================================================+
-- | Name        : XX_TOPS_RETIRE_PKG                                                          |
-- | Description : This package is developed to TOPS Retire Project to Drop Objects            |
-- |                                                                                           |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version     Date           Author               Remarks                                    |
-- |=======    ==========      ================     ===========================================|
-- |1.0        06-May-2016     Praveen Vanga         Initial draft version                     |

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
          ,P_SCHEMA                        IN    VARCHAR2  
          ,P_DROP_FLAG                      IN    VARCHAR2  
          );
       
 PROCEDURE DROP_PROCESS
          (P_SCHEMA                        IN    VARCHAR2,
		   P_RET_STATUS                    OUT   varchar2 
          );       
 

      
END XX_TOPS_RETIRE_PKG ;
/
SHOW ERRORS;