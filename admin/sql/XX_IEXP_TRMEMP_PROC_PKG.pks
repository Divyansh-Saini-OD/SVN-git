SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_IEXP_TRMEMP_PROC_PKG AUTHID CURRENT_USER
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_IEXP_TRMEMP_PROC_PKG.pkb		                     |
-- | Description :  Plsql package for Iexpenses Terminated Employees Process |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       12-Nov-2014 Paddy Sanjeevi     Initial version                 |
-- +=========================================================================+
AS


PROCEDURE xx_purge_unsub_er ( x_errbuf      	OUT NOCOPY VARCHAR2
                              ,x_retcode     	OUT NOCOPY VARCHAR2
  		             );

PROCEDURE xx_iexp_inact_ccproc ( x_errbuf      	OUT NOCOPY VARCHAR2
                                ,x_retcode     	OUT NOCOPY VARCHAR2
			       );


PROCEDURE xx_trdmgr_actemp_proc ( x_errbuf      	OUT NOCOPY VARCHAR2
                                 ,x_retcode     	OUT NOCOPY VARCHAR2
		 	        );

PROCEDURE xx_followup_txn ( x_errbuf      	OUT NOCOPY VARCHAR2
                           ,x_retcode     	OUT NOCOPY VARCHAR2
		 	  );


PROCEDURE xx_personal_expenses ( x_errbuf      	OUT NOCOPY VARCHAR2
                              	,x_retcode     	OUT NOCOPY VARCHAR2
				,p_employee_id	IN  NUMBER
				,p_empname_id	IN  NUMBER
				,p_from_date	IN  VARCHAR2
				,p_to_date	IN  VARCHAR2
     		               );

END;
/
