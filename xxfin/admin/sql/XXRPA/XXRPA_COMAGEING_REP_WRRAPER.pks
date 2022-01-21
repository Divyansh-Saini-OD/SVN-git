create or replace PACKAGE  XXRPA_COMAGEING_REP_WRRAPER
AS
-- +============================================================================================+
-- |  Office Depot - RPA Project Simplify                                                       |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_COMAGEING_REP_WRRAPER                                                           |
-- |  Description:  Plsql Package to run the   OD: AR Combined Aging Views report      		      |
-- |                and send report output over email                                           |
-- |  RICE ID : R1399                                                                           |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author             Remarks                                        |
-- | =========   ===========  =============      =============================================  |
-- | 1.0         14-May-2021  Gitanjali Singh    Initial version                                |
-- +============================================================================================+
-- +============================================================================================+
-- |  Name: SUBMIT_REPORT                                                                       |
-- |  Description: This procedure will run the OD: AR Combined Aging Views report               |
-- |               and email the output                                                         |
-- =============================================================================================|

PROCEDURE SUBMIT_REPORT(/*errbuff     OUT  VARCHAR2
                       ,retcode     OUT  VARCHAR2                       
                       ,P_end_time   IN  VARCHAR2 */
                        p_customer 		IN NUMBER
                       ,p_recipients_id	IN VARCHAR2
                       ,p_cc_recipients		IN VARCHAR2	default NULL
                       ,p_user_name		IN VARCHAR2
                        )
                        ;
END XXRPA_COMAGEING_REP_WRRAPER;
/