SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XXCDH_BILLDOCS_CORRECTION_PKG
as

procedure ADD_BILLDOCS (
                         p_errbuf    OUT NOCOPY varchar2,
                         p_retcode   OUT NOCOPY varchar2,
			 p_batch_id  number
                       );

procedure MOVE_NON_AB_CONTRACT_BILLDOCS (
                         p_errbuf    OUT NOCOPY varchar2,
                         p_retcode   OUT NOCOPY varchar2
                       );

end XXCDH_BILLDOCS_CORRECTION_PKG;
/
SHOW ERRORS;
