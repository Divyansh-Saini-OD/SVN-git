SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XXCDH_POPULATE_AB_FLAG_PKG
as

procedure MAIN (
                 p_errbuf            OUT NOCOPY varchar2,
                 p_retcode           OUT NOCOPY varchar2,
                 p_summary_batch_id             number
               );

end XXCDH_POPULATE_AB_FLAG_PKG;
/
SHOW ERRORS;
