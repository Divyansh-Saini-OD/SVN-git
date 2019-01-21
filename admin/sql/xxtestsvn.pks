$Id$
$Rev$
$HeadURL$
$Author$
$Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xxtestsvn
AS
PROCEDURE Get_Request (x_batch_id  OUT NUMBER
                      ,x_status    OUT VARCHAR
                      ,x_message   OUT VARCHAR);

END xxtestsvn;
/
SHOW ERRORS;
