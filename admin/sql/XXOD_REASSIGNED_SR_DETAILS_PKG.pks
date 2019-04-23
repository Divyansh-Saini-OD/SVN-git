create or replace 
PACKAGE  XXOD_REASSIGNED_SR_DETAILS_PKG AS

/**************************************************************************
MODULE NAME:     XXOD_REASSIGNED_SR_DETAILS_PKG.pks
ORIGINAL AUTHOR: Venkateshwar Panduga
DATE:            29-MAR-2019
DESCRIPTION:

This package is used for to automate the Case Management Weekly DOB Report

CHANGE HISTORY:

VERSION DATE        AUTHOR         		DESCRIPTION
------- ---------   -------------- 		-------------------------------------
1.0     29-MAR-2019   Venkateshwar Panduga    Initial version

**************************************************************************/
TYPE SPLIT_TBL  IS TABLE OF VARCHAR2(32767);
 Function split
   (
      p_list            in      varchar2,
      P_DEL             in      varchar2
   ) return SPLIT_TBL PIPELINED;
procedure XXOD_REASSIGNED_SR_DETAILS_PRC(ERRBUF OUT varchar2 ,
                                        RETCODE OUT varchar2,
                                        P_FROM_DATE   varchar2, ---date,
                                        P_TO_DATE   varchar2, ----date,
                                        p_problem_code varchar2) ;
    PROCEDURE send_mail_prc (
      p_sender      IN   VARCHAR2,
      p_recipient   IN   VARCHAR2,
      p_subject     IN   VARCHAR2,
      p_message     IN   CLOB,
      attachlist    IN   VARCHAR2,                            -- default null,
      DIRECTORY     IN   VARCHAR2                               --default null
   ) ;

END XXOD_REASSIGNED_SR_DETAILS_PKG;
/
