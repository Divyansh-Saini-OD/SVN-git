create or replace
PACKAGE XXOD_PO_REQ_ALRT_PKG
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XXOD_PO_REQ_ALRT_PKG                                            |
-- | Rice ID:                                                                |
-- | Description      : This Program will send email alert for requisition   |
-- |                    having no distribution                               |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |1.0        21-AUG-2017   Neeraj Kr         Initial draft version         |
-- +=========================================================================+
    PROCEDURE main(retcode OUT  NUMBER
                  ,errbuf OUT VARCHAR2
				  ,p_date_from IN VARCHAR2
				  ,p_date_to IN VARCHAR2
				  ,p_email_to IN VARCHAR2
          ,p_num_days IN NUMBER);

	PROCEDURE print_log(p_message IN VARCHAR2);
	PROCEDURE print_out(p_message IN VARCHAR2);
	PROCEDURE submit_email_program (p_email_to         IN     VARCHAR2,
							   p_email_cc         IN     VARCHAR2,
							   p_subject          IN     VARCHAR2,
							   p_email_body       IN     VARCHAR2,
							   p_attchment_file   IN     VARCHAR2,
							   p_file_name        IN     VARCHAR2,
							   p_request_id          OUT NUMBER,
							   p_return_status       OUT VARCHAR2);

END XXOD_PO_REQ_ALRT_PKG;
/