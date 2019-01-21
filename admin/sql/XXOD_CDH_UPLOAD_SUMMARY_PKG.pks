SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_UPLOAD_SUMMARY_PKG.pkb                           |
 |Description                                                             |
 |              Package Spec for uploading into xxod_hz_sammary           |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  08-May-09   Sreedhar Mohan      Initial version                       |
 |======================================================================= */

create or replace package XXOD_CDH_UPLOAD_SUMMARY_PKG
as
  procedure upload(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_request_set_id  OUT NOCOPY  number   ,
                    p_file_name       IN   varchar2
                  );
                  
end XXOD_CDH_UPLOAD_SUMMARY_PKG;
/
