SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK ON
SET TERM ON

PROMPT Creating PACKAGE XX_AR_CUST_STMTXL_WRAP_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE 
PACKAGE XX_AR_CUST_STMTXL_WRAP_PKG
AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  XX_AR_CUST_STMTXL_WRAP  E2048(Defect 3261)    |
-- | Description      :  This Package is used to fetch all the Customer|
-- |                     Statements and mail the Customer statements   |
-- |                     in  the Excel format                          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-NOV-2009  Vinaykumar S   Initial draft version(CR 622)|
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as  |
-- |                                      Per Subbu's Comments         |
-- |                                      Defect 3261(CR 622)          |
-- +===================================================================+

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  GET_CUST_DETAILS                              |
-- | Description      :  This Procedure is used to Extract all the     |
-- |                   Customer Details and insert into customer master|
-- |                  and call the Batching and Submit Child Procedures|
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-NOV-2009  Vinaykumar S    Initial draft version       |
-- | 1.1     14-Dec-2009  Vinaykumar S     Added for Defect 3261 as    |
-- |                                       per subbu's comments        |
-- |                                      Defect 3261(CR 622)          |
-- +===================================================================+

PROCEDURE GET_CUST_DETAILS(x_errbuf            OUT  VARCHAR2
                          ,x_retcode           OUT  VARCHAR2
                          ,p_stmt_date         IN   VARCHAR2
                          ,p_stmt_cycle        IN   NUMBER
                          ,p_no_of_customers   IN   NUMBER
                          ,p_customer_id       IN   NUMBER
                          ,p_debug_flag        IN   VARCHAR2
                          );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  SUBMIT_REP_BURST                              |
-- | Description      :  This Procedure is used to submit the report   |
-- |                     for the batch id passed and to submit the     |
-- |                     respective bursting program                   |
-- |                     Statements                                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 08-Jun-2010  Bhuvaneswary S    Initial draft version     |
-- +===================================================================+

PROCEDURE SUBMIT_REP_BURST(x_errbuf        OUT   VARCHAR2
                          ,x_retcode       OUT   VARCHAR2
                          ,p_stmt_date     IN VARCHAR2
                          ,p_burst_flag    IN VARCHAR2
                          ,p_debug_flag    IN VARCHAR2
                          ,p_batch_id      IN NUMBER
                          );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  STORE_CHILD_DETAILS                           |
-- | Description      :  This Procedure is find the individual and     |
-- |                     Consolidated Customer Details,Unapplied cash  |
-- |                     Receipts,calculate aging buckets and insert   |
-- |                     into the Store Child table                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-Nov-2009  Vinaykumar S    Initial draft version       |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as  |
-- |                                      Per Subbu's Comments         |
-- |                                      Defect 3261(CR 622)          |
-- +===================================================================+

PROCEDURE STORE_CHILD_DETAILS(x_errbuf            OUT  VARCHAR2
                             ,x_retcode           OUT  VARCHAR2
                             ,p_stmt_date         IN   DATE
                             ,p_batch_id          IN   NUMBER
                             ,p_debug_flag        IN   VARCHAR2
                             );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  SUBMIT_REP_BURST                              |
-- | Description      :  This Procedure is used for calling the shell  |
-- |                     script program which in turn mails the        |
-- |                     statements   to the respective e mail ids     |
-- |                     for the batch id passed and to submit the     |
-- |                     respective bursting program                   |
-- |                     Statements                                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 08-Jun-2010  Bhuvaneswary S    Initial draft version     |
-- +===================================================================+



PROCEDURE SUBMIT_SEND_MAIL(p_stmt_date     IN  VARCHAR2
                          ,p_burst_flag    IN  VARCHAR2
                          ,p_send_email    IN  VARCHAR2
                          ,p_user_emailid  IN  VARCHAR2
                          ,p_debug_flag    IN  VARCHAR2
                          ,p_status        OUT NUMBER
                          );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  CUST_STMT_RESEND_MAIN                         |
-- | Description      :  This Procedure is used to resend the Customer |
-- |                     Statements                                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 12-Nov-2009  Vinaykumar S    Initial draft version       |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as  |
-- |                                      Per Subbu's Comments         |
-- |                                      Defect 3261(CR 622)          |
-- +===================================================================+

PROCEDURE CUST_STMT_RESEND_MAIN
                             (x_errbuf           OUT  VARCHAR2
                             ,x_retcode          OUT  VARCHAR2
                             ,p_stmt_date        IN   VARCHAR2 
                             ,p_customer_id      IN   NUMBER
                             ,p_customer_site_id IN   NUMBER
                             ,p_email_id         IN   VARCHAR2
                             ,p_send_email       IN   VARCHAR2
                             ,p_debug_flag       IN   VARCHAR2
                             );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  GENERATE_MAIL_BODY                            |
-- | Description      : This Procedure is used to generate the mailbody|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-NOV-2009  Vinaykumar S    Initial draft version       |
-- |  1.1     14-DEC-2009  Vinaykumar S   Made changes to the code as  |
-- |                                      Per Subbu's Comments         |
-- |                                      Defect 3261(CR 622)          |
-- +===================================================================+

PROCEDURE GENERATE_MAIL_BODY (p_stmt_date  IN VARCHAR2
                             ,p_debug_flag IN VARCHAR2
                             );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  GET_DELIVERY_EMAILID                          |
-- | Description      : This Procedure is used to fetch the Email Ids  |
-- |                    at Customer Header Level and Site Level        |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 05-NOV-2009  Vinaykumar S    Initial draft version       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE GET_DELIVERY_EMAILID(p_site_use_id       IN       VARCHAR2
                              ,p_customer_flag     IN       VARCHAR2
                              ,p_resend_flag       IN       VARCHAR2
                              ,p_stmt_date         IN       VARCHAR2
			      ,p_org_id            IN       NUMBER
                              ,x_mail_add          OUT      VARCHAR2
                              ,x_cust_acct_no      OUT      VARCHAR2
                              ,x_aops_cust_no      OUT      VARCHAR2
                              ,x_location          OUT      VARCHAR2
                              ,x_bill_sequence     OUT      VARCHAR2
                              ,x_stmt_date         OUT      VARCHAR2
                              );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  DEBUG_MESSAGE                                 |
-- | Description      : This Procedure is used to print the debug      |
-- |                    messages wherever required                     |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- | 1.1     14-Dec-2009  Vinaykumar S     Added for Defect 3261 as    |
-- |                                       per subbu's comments        |
-- |                                      Defect 3261(CR 622)          |
-- +===================================================================+

PROCEDURE DEBUG_MESSAGE(p_debug_flag       IN       VARCHAR2
                       ,p_debug_msg        IN       VARCHAR2
                       );

 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  DEBUG_MESSAGE                                 |
-- | Description      : This Procedure is used to print dbms outputs   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- | 1.1     19-FEB-2010  Ranjith Thangasamy Added for Defect 4519     |
-- +===================================================================+

PROCEDURE CUSTOM_OUTPUT(p_string IN VARCHAR2 );

  -- +======================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                          Wipro-Office Depot                            |
-- +========================================================================+
-- | Name             :  Get_Chid_Status                                    |
-- | Description      : This function is get the Status Of the              |
-- |                    Child Requests                                      |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date         Author           Remarks                         |
-- |=======   ==========   =============    ======================          |
-- | 1.0     11-Jun-2010  Bhuvaneshwari     Performance Changes             |
-- |                                        for Defect 5117                 |
-- +========================================================================+

FUNCTION Get_Chid_Status (p_par_req_id NUMBER)
        RETURN NUMBER;



END XX_AR_CUST_STMTXL_WRAP_PKG;
/

