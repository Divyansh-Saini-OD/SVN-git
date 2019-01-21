SET VERIFY OFF
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR CONTINUE;
 

 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_ASN_ACCTBUSEVT_PKG                                           |
 -- | Description      : This custom package parses Account Request Table 		   |	
 -- |			 'XX_CDH_ACCOUNT_SETUP_REQ and checks for exiatence of any         |
 -- |                    request record in 'Submitted' status and if exists triggers       |
 -- |                    a custom Business event 'Account Creation Batch Event'.	   |	
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    RAISE_BUSINESS_EVENT  This procedure parses Account Request table and    | 
 -- |                                   checks for request status as 'Submitted'and        |       
 -- |                                   calls the AR business event                        | 
 -- |                                   			                           |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   ===============  ============================================= |
 -- |Draft 1a  18-Sep-2007  Satyasrinivas D  Initial draft version                         |
 -- +===================================================================================== +

CREATE OR REPLACE PACKAGE XX_ASN_ACCTBUSEVT_PKG
AS
PROCEDURE RAISE_BUSINESS_EVENT(x_errbuf OUT NOCOPY  VARCHAR2,
                               x_retcode OUT NOCOPY  VARCHAR2);
END;
/
SHOW ERRORS;