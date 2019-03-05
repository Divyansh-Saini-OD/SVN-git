CREATE OR REPLACE PROCEDURE xxdba_fndconcreq_arch( errbuff OUT VARCHAR2, retcode OUT VARCHAR2 ) AS
 /**********************************************************************************
   NAME:       xxdba_fndconcreq_arch
   PURPOSE:    This procedure archives concurrent requests.

   REVISIONS:
  -- Version Date        Author                               Description
  -- ------- ----------- ----------------------               ---------------------
  -- 1.0     30-May-2017 Suresh Ponnambalam           Modified this procedure for defect 41823.
  -- 1.1     05-MAR-2018 Dinesh Nagapuri              GSCC Violation removed schema reference.
 **********************************************************************************/

ln_arc_req_id 	NUMBER;
ln_act_req_id 	NUMBER;

BEGIN
	SELECT MAX(request_id) 
	  INTO ln_arc_req_id 
	  FROM xxfnd_concurrent_requests_arch ;								--V1.1
	
	fnd_file.put_line(fnd_file.log,'Max Request Id in xxfnd_concurrent_requests_arch ' || NVL(ln_arc_req_id,0));
	  
	SELECT MAX(request_id) 
	  INTO ln_act_req_id 
	  FROM fnd_concurrent_requests 										--V1.1
	  WHERE phase_code='C' ;

	fnd_file.put_line(fnd_file.log,'Max Request Id in fnd_concurrent_requests ' || ln_act_req_id);
	
	fnd_file.put_line(fnd_file.log,'Inserting Records into xxfnd_concurrent_requests_arch');
	
	INSERT INTO 
	       xxfnd_concurrent_requests_arch 
	(SELECT * FROM 
	        fnd_concurrent_requests 									--V1.1
	  WHERE request_id> NVL(ln_arc_req_id,0) 
	    AND request_id<=ln_act_req_id);

COMMIT;

EXCEPTION
  WHEN OTHERS THEN
	fnd_file.put_line(fnd_file.log,'Error encountered - Error Code : ' || SQLCODE ||'. Error Message  : ' || SQLERRM );
end;
/
