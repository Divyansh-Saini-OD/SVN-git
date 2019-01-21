SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE XXOD_CDH_UPLOAD_EBLCONTACTS
AS

/* =======================================================================+
 |                       Copyright (c) 2012 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_UPLOAD_EBLCONTACTS.pkb                           |
 |Description                                                             |
 |              Package specification and body for submitting the         |
 |              request set programmatically for Ebl Contacts Upload      |
 |                                                                        |
 |  Date        Author              Comments                              |
 |  07-Jul-12   Devendra Petkar      Initial version                       |
 |======================================================================= */

 PROCEDURE upload(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_request_set_id  OUT NOCOPY  number   ,
                    p_file_upload_id       IN   NUMBER
                  );

end XXOD_CDH_UPLOAD_EBLCONTACTS;
/

SHOW ERRORS;

