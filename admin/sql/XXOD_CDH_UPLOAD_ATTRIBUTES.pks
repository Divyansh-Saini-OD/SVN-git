SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_UPLOAD_ATTRIBUTES.pkb                            |
 |Description                                                             |
 |              Package specification and body for submitting the         |
 |              request set programmatically                              |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  29-Dec-08   Sreedhar Mohan      Initial version                       |
 |======================================================================= */

create or replace package XXOD_CDH_UPLOAD_ATTRIBUTES
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
  function get_osr (p_account_number in varchar2)  return varchar2;

  procedure copy_customer_profiles(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_batch_id        IN   number  
                    );
  procedure update_batch(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_batch_id        IN   number  
                    );
  procedure uploadCustStatus(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_request_set_id  OUT NOCOPY  number   , 
                    p_file_name       IN   varchar2  
                  );
  procedure processCustStatus(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_file_name       IN   varchar2  
                  );
end XXOD_CDH_UPLOAD_ATTRIBUTES;
/
