SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_PROC115_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PROC115.pkb      	   	               |
-- | Description :  OD QA Process                                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       19-Sep-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

PROCEDURE XX_QA_PROC115( x_errbuf      OUT NOCOPY VARCHAR2
                     ,x_retcode     OUT NOCOPY VARCHAR2
		    )
IS

  v_request_id 		NUMBER:=0;

BEGIN


  fnd_file.put_line(fnd_file.LOG, 'Submitting OD QA Sample Approval Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQASAMP','OD QA Sample Approval Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');



  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'Submitting OD QA Factory Data Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAFADP','OD QA Factory Data Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'Submitting OD QA Regulatory Certificate Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQARGCP','OD QA Regulatory Certificate Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'OD QA ED Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAED','OD QA ED Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'OD QA Variation Notice Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAVN','OD QA Variation Notice Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'OD QA Protocol Review Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAPR','OD QA Protocol Review Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'OD QA RGA Process');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQARGA','OD QA RGA Process',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

  fnd_file.put_line(fnd_file.LOG, '');

  v_request_id:=0;

  fnd_file.put_line(fnd_file.LOG, 'OD QA PPT Inbound Loader');
  
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXMER','XXQAPPTI','OD QA PPT Inbound Loader',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;
     fnd_file.put_line(fnd_file.LOG, 'Request id : '||to_char(v_request_id));
  END IF;

END XX_QA_PROC115;

END XX_QA_PROC115_PKG;
/
