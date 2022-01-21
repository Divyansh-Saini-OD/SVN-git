create or replace 
PACKAGE      XX_APXUATR_XMLP_WRAP
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       		Oracle                               		                 |
-- +===================================================================================+
-- | Name        : XX_APXUATR_XMLP_WRAP		                                             |
-- | Description : This Package will be executable code for the Unaccounted  		       |
-- |               Transaction report                                                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |1.0 	  21-JUN-2010  Rohit Gupta		       Initial draft version                   |
-- |                                                                                   |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       		 ORACLE                                                  |
-- +===================================================================================+
-- | Name        : SUBMIT_REPORT                                                       |
-- | Description : This Procedure is used to generate unaccounted transaction report   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |1.0 	  21-JUN-2010  Rohit Gupta		       Initial draft version                   |
-- |                                                                                   |
-- +===================================================================================+

   P_REPORTINP_LEVEL NUMBER;
   P_REPORTINP_ENTITY_ID NUMBER;
   P_LEDGER_ID VARCHAR2(30) :=NULL;
   P_START_DATE VARCHAR2(30)  :=NULL;
   P_END_DATE VARCHAR2(30) :=NULL;
   P_PERIOD_NAME VARCHAR2(30) :=NULL;
   P_SWEEP_TO_PERIOD VARCHAR2(30) :=NULL;
   P_ACTION VARCHAR2(30) :=NULL;
   P_SWEEP_NOW VARCHAR2(30) :=NULL;
   P_DEBUG VARCHAR2(30) :=NULL;
   
PROCEDURE SUBMIT_REPORT ( x_errbuff OUT VARCHAR2,
                          x_retcode OUT NUMBER,
						  p_reportinp_level 		number,
						  p_reportinp_entity_id 	number, 
						  p_ledger_id 				number,
						  p_start_date 				varchar2,  
						  p_end_date 				varchar2,
						  p_period_name 			varchar2,  
						  p_sweep_to_period 		varchar2,  
						  p_action 					varchar2,
						  p_sweep_now 				varchar2,  
						  p_debug 					varchar2
                        );
END;