SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF 
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification XX_PO_AUTO_REQ_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

create or replace PACKAGE XX_PO_AUTO_REQ_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      PO Auto Requisition Import                            |
-- | Description : To automatically import the Requisitions into Oracle|
-- |                from the staging tables.                           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       21-MAR-2007  Gowri Shankar        Initial version        |
-- |1.1       25-JUL-2008  Radhika Raman        Fixed defect 9178      |
-- |1.2       17-JUL-2013  Satyajeet Mishra     E0980 - Added following for    |
-- |                                            Web ADI and retrofit   |
-- |                                            a)submit_request       |
-- |                                            b)get_record           |   
-- |                                                                   |
-- +===================================================================+

   -- FUNCTION GET_REQUEST_ID RETURN NUMBER; 
   -- commented for defect 9178 as this function is not needed anymore

-- +===================================================================+
-- | Name : PROCESS                                                    |
-- | Description : To automatically import the Rquisitions into Oracle |
-- |                                                                   |
-- |    It will validate the Requisition information from the staging  |
-- |    tables and then insert into standard interface tables          |
-- |    PO_REQUISITIONS_INTERFACE_ALL, PO_REQ_DIST_INTERFACE_ALL       |
-- |    Then it will submit the standard import request set            |
-- |                                   "Requisition Import"            |
-- |    This procedure is the executable of the concurrent program     |
-- |          'OD: PO Auto Requisition Load Program'                   |
-- | Parameters : x_error_buff, x_ret_code, p_batch_id                 |
-- |                                                                   |
-- | Returns: x_error_buff, x_ret_code                                 |
-- +===================================================================+
    PROCEDURE PROCESS(
        x_error_buff         OUT VARCHAR2
       ,x_ret_code           OUT NUMBER
       ,p_batch_id          IN VARCHAR2);
     
-- +===================================================================+
-- | Name :  get_record                                                |
-- | Description : To automatically import the Rquisitions into Oracle |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE get_record(
        p_requisition_type  IN  VARCHAR2
    , p_preparer_emp_nbr  IN  VARCHAR2
    ,   p_req_description IN  VARCHAR2
    ,   p_req_line_number IN  VARCHAR2
    ,   p_line_type         IN  VARCHAR2
    ,   p_item              IN  VARCHAR2
    ,   p_category          IN  VARCHAR2
    ,   p_item_description  IN  VARCHAR2
    ,   p_unit_of_measure IN  VARCHAR2
    ,   p_price             IN  VARCHAR2
    ,   p_need_by_date      IN  VARCHAR2
    ,   p_quantity          IN  VARCHAR2
    ,   p_organization          IN  VARCHAR2
    ,   p_source_organization IN  VARCHAR2
    ,   p_location              IN  VARCHAR2
    ,   p_req_line_number_dist  IN  VARCHAR2
    ,   p_distribution_quantity IN  VARCHAR2
    ,   p_charge_acct_segment1  IN  VARCHAR2
    ,   p_charge_acct_segment2  IN  VARCHAR2
    ,   p_charge_acct_segment3  IN  VARCHAR2
    ,   p_charge_acct_segment4  IN  VARCHAR2
    ,   p_charge_acct_segment5  IN  VARCHAR2
    ,   p_charge_acct_segment6  IN  VARCHAR2
    ,   p_charge_acct_segment7  IN  VARCHAR2
    ,   p_project             IN  VARCHAR2
    ,   p_task                  IN  VARCHAR2
    ,   p_expenditure_type      IN  VARCHAR2
    ,   p_expenditure_org     IN  VARCHAR2
    ,   p_expenditure_item_date IN  VARCHAR2
        ,   p_file_name             IN VARCHAR2         
    );

-- +===================================================================+
-- | Name :  Submit_request                                            |
-- | Description : Submits request for custom program for validatio    |
-- +===================================================================+
    PROCEDURE submit_request(x_message OUT VARCHAR2);    

    gc_concurrent_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;

end XX_PO_AUTO_REQ_PKG;
/
SHOW ERROR;
