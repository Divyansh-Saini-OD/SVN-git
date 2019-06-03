SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_PROCESS_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PROCESS.pkb      	   	               |
-- | Description :  OD QA Process                                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       19-Jul-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

PROCEDURE XX_QA_PROC( x_errbuf      OUT NOCOPY VARCHAR2
                     ,x_retcode     OUT NOCOPY VARCHAR2
		    )
IS

  v_request_id 		NUMBER:=0;

BEGIN


  fnd_file.put_line(fnd_file.LOG, 'Submitting FAI Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAFAIP','OD QA FAI Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'Submitting PS Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAPSPP','OD QA Purchase Specs Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'Submitting Customer ComplaintS Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQACCMP','OD QA Customer Complaint Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'Submitting Invoicing Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAINVP','OD QA Invoicing Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'OD QA Withdrawal Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAWIDP','OD QA Withdrawal Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'OD QA SPA Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQASPAP','OD QA SPA Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'OD QA SPC Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQASPCP','OD QA SPC Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

END XX_QA_PROC;

END XX_QA_PROCESS_PKG;
/
