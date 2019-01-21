SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CRM_DYN_ALERTER_PKG AUTHID CURRENT_USER AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_CRM_DYN_ALERTER_PKG                                                    |
-- | Description : Dynamic Alerter Program                                                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author                 Remarks                                |
-- |=======    ==========      ================       =======================================|
-- |DRAFT 1a   21-JUL-2009     Sarah Maria Justina    Initial draft version                  |
-- +=========================================================================================+
TYPE xx_dyn_var_tbl_type IS TABLE OF VARCHAR2(4000)
      INDEX BY BINARY_INTEGER;
      
TYPE xx_dyn_others_tbl_type IS TABLE OF VARCHAR2(4000)
      INDEX BY BINARY_INTEGER;

-- +===================================================================+
-- | Name       : EMAIL_ALERT                                          |
-- | Description: Dynamic Alerter Program                              |
-- +===================================================================+   
FUNCTION EMAIL_ALERT 
                        (
                         p_subscription_guid  IN             RAW,
                         p_event              IN OUT NOCOPY  WF_EVENT_T
                        ) 
RETURN VARCHAR2;

PROCEDURE REPORT_MAIN  (
                         x_errbuf                OUT         VARCHAR2,
                         x_retcode               OUT         NUMBER
                        );
                        
-- +===================================================================+
-- | Name       : REPORT_CHILD                                         |
-- | Description: Dynamic Alerter Program                              |
-- +===================================================================+   
PROCEDURE REPORT_CHILD  (
                         x_errbuf                OUT         VARCHAR2,
                         x_retcode               OUT         NUMBER,
                         p_module_name            IN         VARCHAR2,
                         p_bpel_retry             IN         VARCHAR2,
                         p_exclude_exceptions     IN         VARCHAR2,
                         p_entity_type            IN         VARCHAR2
                        );
END XX_CRM_DYN_ALERTER_PKG;
/

SHOW ERRORS
EXIT;
