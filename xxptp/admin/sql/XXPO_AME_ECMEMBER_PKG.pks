create or replace 
PACKAGE XXPO_AME_ECMEMBER_PKG IS
/******************************************************************************************************/
--- Name: XXPO_AME_ECMEMBER_PKG
--- Description: This package will identify if EC Member is in the Hierarchy
--- 
--- Change Records
--- Version              Author              Date
--- 1.0              Elangovan, Arun      02-NOV-2017
/********************************************************************************************************/
FUNCTION xxod_get_req_approver_id (p_transaction_id IN NUMBER)
RETURN VARCHAR2;
END XXPO_AME_ECMEMBER_PKG;
/