create or replace
PACKAGE XX_ARI_AD_HOC_REPORT_PKG AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_ARI_AD_HOC_REPORT_PKG                                                             |
-- | Description : Runs concurrent program from iReceivables and emails output                          |
-- |               Currently coded for Accounts Close to Credit Limit Report (CR804/QC4446)             |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       15-Jun-2010 Bushrod Thomas     Initial draft version.      			 	                        |
-- |                                                                                                    |
-- +====================================================================================================+
*/

  PROCEDURE RUN_ACC_CLOSE_TO_CRD_LIMIT_RPT(
    p_outstanding_amount_low  IN NUMBER
   ,p_outstanding_amount_high IN NUMBER
   ,p_collector_number_low    IN VARCHAR2
   ,p_collector_number_high   IN VARCHAR2
   ,p_customer_class          IN VARCHAR2
   ,p_recipient_email_list    IN VARCHAR2
   ,x_request_id              OUT NUMBER
  );

  PROCEDURE RUN_PROGRAM (
    x_error_buffer          OUT VARCHAR2
   ,x_return_code           OUT NUMBER
   ,p_email_list_output      IN VARCHAR2
   ,p_email_list_log         IN VARCHAR2
   ,p_application            IN VARCHAR2 := NULL
	 ,p_program                IN VARCHAR2 := NULL
   ,p_template_app           XDO_TEMPLATES_B.application_short_name%TYPE
   ,p_template_code          XDO_TEMPLATES_B.template_code%TYPE
   ,p_template_language      XDO_TEMPLATES_B.default_language%TYPE
   ,p_template_territory     XDO_TEMPLATES_B.default_territory%TYPE
   ,p_template_output_format FND_LOOKUPS.lookup_code%TYPE := 'PDF' -- see FND_LOOKUPS where lookup_type='XDO_OUTPUT_TYPE'   
   ,p_argument1              IN VARCHAR2 := CHR(0)
   ,p_argument2              IN VARCHAR2 := CHR(0)
   ,p_argument3              IN VARCHAR2 := CHR(0)
   ,p_argument4              IN VARCHAR2 := CHR(0)
   ,p_argument5              IN VARCHAR2 := CHR(0)
   ,p_argument6              IN VARCHAR2 := CHR(0)
   ,p_argument7              IN VARCHAR2 := CHR(0)
   ,p_argument8              IN VARCHAR2 := CHR(0)
   ,p_argument9              IN VARCHAR2 := CHR(0)
   ,p_argument10             IN VARCHAR2 := CHR(0)
   ,p_argument11             IN VARCHAR2 := CHR(0)
   ,p_argument12             IN VARCHAR2 := CHR(0)
   ,p_argument13             IN VARCHAR2 := CHR(0)
   ,p_argument14             IN VARCHAR2 := CHR(0)
   ,p_argument15             IN VARCHAR2 := CHR(0)
   ,p_argument16             IN VARCHAR2 := CHR(0)
   ,p_argument17             IN VARCHAR2 := CHR(0)
   ,p_argument18             IN VARCHAR2 := CHR(0)
   ,p_argument19             IN VARCHAR2 := CHR(0)
   ,p_argument20             IN VARCHAR2 := CHR(0) -- Can add up to 100, if needed
  );

END XX_ARI_AD_HOC_REPORT_PKG;

/