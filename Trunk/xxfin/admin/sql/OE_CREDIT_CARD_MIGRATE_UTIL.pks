SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE OE_Credit_Card_Migrate_Util AUTHID CURRENT_USER AS
-- $Header: OEXECCNS.pls 115.0.11510.2 2005/09/27 06:47:40 spooruli noship $
--+=======================================================================+
--|               Copyright (c) 2000 Oracle Corporation                   |
--|                       Redwood Shores, CA, USA                         |
--|                         All rights reserved.                          |
--+=======================================================================+
--| FILENAME                                                              |
--|    OEXECCNS.pls                                                       |
--|                                                                       |
--| DESCRIPTION                                                           |
--|     Package Spec of OE_Credit_Card_Migrate_Util                       |
--|                                                                       |
--| PROCEDURE LIST                                                        |
--|     Migrate_CC_Number_MGR                                             |
--|     Migrate_CC_Number_WKR                                             |
--|                                                                       |
--| HISTORY                                                               |
--|    SEP-06-2005 Initial Creation                                       |
--|                                                                       |
--|=======================================================================+

PROCEDURE Migrate_CC_Number_MGR
(   X_errbuf       OUT NOCOPY VARCHAR2,
    X_retcode      OUT NOCOPY VARCHAR2,
    X_batch_size    IN NUMBER,
    X_Num_Workers   IN NUMBER
) ;

PROCEDURE Migrate_CC_Number_WKR
(   X_errbuf       OUT NOCOPY VARCHAR2,
    X_retcode      OUT NOCOPY VARCHAR2,
    X_batch_size    IN NUMBER,
    X_Worker_Id     IN NUMBER,
    X_Num_Workers   IN NUMBER
) ;

END OE_Credit_Card_Migrate_Util ;
/
SHOW ERRORS;
EXIT;
