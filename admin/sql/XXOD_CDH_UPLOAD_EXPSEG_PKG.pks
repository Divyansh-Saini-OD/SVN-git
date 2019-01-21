SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_UPLOAD_ATTRIBUTES.pks                            |
 |Description                                                             |
 |              Package specification for submitting the                  |
 |              request set programmatically                              |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  16-Feb-09   Anirban Chaudhuri   Initial version                       |
 |======================================================================= */

CREATE OR REPLACE package XXOD_CDH_UPLOAD_EXPSEG_PKG
as
  procedure upload(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_request_set_id  OUT NOCOPY  number   , 
                    p_file_name       IN   varchar2  
                  );

  procedure print_upload_report(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_batch_id        IN   number  
                  );

  PROCEDURE update_expseg_batch_id(
                                  p_errbuf           OUT NOCOPY VARCHAR2
                                 ,p_retcode          OUT NOCOPY varchar2
				 ,p_batch_id         IN NUMBER
                                 );
end XXOD_CDH_UPLOAD_EXPSEG_PKG;
/
