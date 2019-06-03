SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_PA_PB_COMPLIANCE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PB_PRDUPLD_PKG.pkb                       |
-- | Description :  OD PB PA Product Upload Package                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       23-Sep-2010 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

------------------------------------------------------------------------------------------------
--Declaring xx_process_data
------------------------------------------------------------------------------------------------
FUNCTION check_vend_dup(p_vend_no IN VARCHAR2) RETURN VARCHAR2;

PROCEDURE vend_request(p_subject IN VARCHAR2,p_email IN VARCHAR2,p_ccmail IN VARCHAR2,p_text IN VARCHAR2,
               p_plan_id IN NUMBER,p_ocr IN NUMBER);

PROCEDURE SEND_NOTIFICATION( p_subject IN VARCHAR2
                ,p_email_list IN VARCHAR2
                ,p_cc_email_list IN VARCHAR2
                ,p_text IN VARCHAR2 );

FUNCTION xx_preaudit_check(p_waiver IN VARCHAR2,p_waiver_apr IN VARCHAR2,
                       p_pastatus IN VARCHAR2,p_pafadate IN DATE,
                p_plan_id IN NUMBER,p_ocr IN NUMBER)
RETURN VARCHAR2;


FUNCTION xx_init_audit(p_plan_id IN NUMBER,p_ocr IN NUMBER) RETURN VARCHAR2;



FUNCTION xx_cap_check(p_waiver IN VARCHAR2,p_waiver_apr IN VARCHAR2,
                p_castatus IN VARCHAR2,p_cafadate IN DATE)
RETURN VARCHAR2;

FUNCTION xx_doc_check(p_type IN VARCHAR2,p_plan_id IN NUMBER,p_ocr IN NUMBER)
RETURN VARCHAR2;


FUNCTION xx_vendsk_check(p_agent IN VARCHAR2,p_vtype IN VARCHAR2,p_waiver IN VARCHAR2,p_waiver_apr IN VARCHAR2,
               p_potadate IN DATE,p_ocr IN NUMBER,p_plan_id IN NUMBER)
RETURN VARCHAR2;


FUNCTION xx_doc_exists(p_action IN VARCHAR2,p_agent IN VARCHAR2,p_vtype IN VARCHAR2,
               p_waiver IN VARCHAR2,p_waiver_apr IN VARCHAR2,p_potadate IN DATE,
               p_inactive IN DATE,p_reactive IN DATE,
               p_plan_id IN NUMBER,p_ocr IN NUMBER) RETURN VARCHAR2;

PROCEDURE xx_status_upd (p_vend_id IN VARCHAR2,p_vend_name IN VARCHAR2,
             p_fact_id IN VARCHAR2,p_fact_name IN VARCHAR2,
             p_task IN VARCHAR2);

PROCEDURE XX_SC_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
               );
PROCEDURE XX_SC_INT_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                            ,x_retcode     OUT NOCOPY VARCHAR2
               );               

PROCEDURE xx_sc_status_alert( x_errbuf      OUT NOCOPY VARCHAR2
                             ,x_retcode     OUT NOCOPY VARCHAR2
                            );

END;
/