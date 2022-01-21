create or replace
PACKAGE BODY XX_FIN_COPY_TO_XPTR_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Wipro Technologies                          |
-- +===================================================================+
-- | Name  : XX_FIN_HTTP_PKG                                           |
-- | Description      :  This PKG will get req id output to XPTR       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |          13-JAN-2014 Ray Strauss      Initial draft version       |
--            30-NOV-2015 Vasu Raparla     Removed Schema References   |
-- |                                       for R12.2                   |
-- +===================================================================+ 
 
PROCEDURE SEND_TO_XPTR(x_error_buff              OUT  VARCHAR2
                      ,x_ret_code                OUT  NUMBER
                      ,p_req_id                  IN   NUMBER
                      ,p_child_pgm               IN   VARCHAR2
                      ,p_path_name               IN   VARCHAR2)
IS

ln_conc_id		     NUMBER  :=0;
lc_level               NUMBER;
lc_req_id              NUMBER;
lc_child_req_id        NUMBER  := 0;
lc_child_pgm           VARCHAR2(50);
lc_path_name           VARCHAR2(50);
lc_source_file_name    VARCHAR2(500);
lc_dest_file_name      VARCHAR2(500);


-- ==========================================================================
-- primary cursor 
-- ==========================================================================
CURSOR get_child_req_cur IS
       SELECT LEVEL,
              r.request_id,
              r.parent_request_id  
       FROM   fnd_concurrent_requests    R,
              FND_CONCURRENT_PROGRAMS_VL P
       WHERE  r.concurrent_program_id = p.concurrent_program_id
       AND    p.concurrent_program_name = lc_child_pgm
       START WITH        r.request_id = lc_req_id
       CONNECT BY PRIOR  r.request_id = r.parent_request_id;

-- ==========================================================================
-- Main process
-- ==========================================================================
BEGIN

	FND_FILE.PUT_LINE(fnd_file.log,'XX_FIN_COPY_TO_XPTR_PKG.SEND_TO_XPTR - parameters:      ');

      lc_req_id    := p_req_id;
      lc_child_pgm := p_child_pgm;
      lc_path_name := p_path_name;

	FND_FILE.PUT_LINE(fnd_file.log,'                                        Request id   : '||lc_req_id);
	FND_FILE.PUT_LINE(fnd_file.log,'                                        Child program: '||lc_child_pgm);
	FND_FILE.PUT_LINE(fnd_file.log,'                                        XPTRPath name: '||lc_path_name);
	FND_FILE.PUT_LINE(fnd_file.log,' ');

 
	FND_FILE.PUT_LINE(fnd_file.log,'Checking child request ids');
	FND_FILE.PUT_LINE(fnd_file.log,' ');

	FOR rid_rec IN get_child_req_cur
	LOOP

         lc_child_req_id := rid_rec.request_id;

      END LOOP;

	FND_FILE.PUT_LINE(fnd_file.log,'Found the following child request id: '||lc_child_req_id);
	FND_FILE.PUT_LINE(fnd_file.log,' ');

      IF lc_child_req_id > 0 THEN
         FND_FILE.PUT_LINE(fnd_file.log,'Sending request output to XPTR');
         FND_FILE.PUT_LINE(fnd_file.log,' ');

         lc_source_file_name := '$APPLCSF/$APPLOUT/'||'o'||lc_child_req_id||'.out';
         lc_dest_file_name   := lc_path_name||lc_child_req_id||'.txt';

         FND_FILE.PUT_LINE(fnd_file.log,'Source file path/name      = '||lc_source_file_name);
         FND_FILE.PUT_LINE(fnd_file.log,'Destination file path/name = '||lc_dest_file_name);

         ln_conc_id := fnd_request.submit_request(
                                                         'XXFIN'
                                                        ,'XXCOMFILCOPY'
                                                        ,''
                                                        ,''
                                                        ,FALSE
                                                        ,lc_source_file_name
                                                        ,lc_dest_file_name
                                                        ,NULL
                                                        ,NULL
                                                 );
      END IF;

   EXCEPTION
        WHEN OTHERS THEN
             FND_FILE.PUT_LINE(fnd_file.log,'Error - 999 SQLCODE = '||SQLCODE||' SQLERRM = '||SQLERRM); 

END SEND_TO_XPTR;	

END XX_FIN_COPY_TO_XPTR_PKG;
/