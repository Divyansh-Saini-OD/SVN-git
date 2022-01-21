PROMPT "---------------Droping Package--------------"
PROMPT "Drop Package   ..."
drop package APPS.XX_AR_UPD_PS_WC_PKG;
PROMPT "Drop Package   ..."
drop package APPS.XX_AR_MT_WC_PKG;
PROMPT "Drop Package   ..."
drop package APPS.XX_AR_TXN_WC_PKG;
PROMPT "Drop Package   ..."
drop package APPS.XX_AR_CR_WC_PKG;
PROMPT "Drop Package   ..."
drop package APPS.XX_AR_ADJ_WC_PKG;
PROMPT "Drop Package   ..."
drop package APPS.XX_AR_PS_WC_PKG;
PROMPT "Drop Package   ..."
drop package APPS.XX_AR_RECAPPL_WC_PKG;

PROMPT "---------------Droping Synonym--------------"

PROMPT "Drop SYNONYM XX_AR_WC_UPD_PS  ..."
drop synonym APPS.XX_AR_WC_UPD_PS;

PROMPT "Drop SYNONYM XX_AR_MT_WC_DETAILS  ..."
drop synonym APPS.XX_AR_MT_WC_DETAILS;

PROMPT "Drop SYNONYM XX_AR_TRANS_WC_STG  ..."
drop synonym APPS.XX_AR_TRANS_WC_STG;

PROMPT "Drop SYNONYM XX_AR_PS_WC_STG  ..."
drop synonym APPS.XX_AR_PS_WC_STG;

PROMPT "Drop SYNONYM XX_AR_RECAPPL_WC_STG  ..."
drop synonym APPS.XX_AR_RECAPPL_WC_STG;

PROMPT "Drop SYNONYM XX_AR_ADJ_WC_STG  ..."
drop synonym APPS.XX_AR_ADJ_WC_STG;

PROMPT "Drop SYNONYM XX_AR_CR_WC_STG  ..."
drop synonym APPS.XX_AR_CR_WC_STG;

PROMPT "Drop SYNONYM XX_AR_MT_WC_S  ..."
drop synonym APPS.XX_AR_MT_WC_S;

PROMPT "---------------Deleting concurrent Programs--------------"

PROMPT "Delete Concurrent Program XXARFTXNWCMT  ..."
begin
apps.fnd_program.delete_program('XXARFTXNWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFTXNWC  ..."
begin
apps.fnd_program.delete_program('XXARFTXNWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDTXNWCMT  ..."
begin
apps.fnd_program.delete_program('XXARDTXNWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDTXNWC  ..."
begin
apps.fnd_program.delete_program('XXARDTXNWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARTXNEXTWC  ..."
begin
apps.fnd_program.delete_program('XXARTXNEXTWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFCRWCMT  ..."
begin
apps.fnd_program.delete_program('XXARFCRWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFCRWC  ..."
begin
apps.fnd_program.delete_program('XXARFCRWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDCRWCMT  ..."
begin
apps.fnd_program.delete_program('XXARDCRWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDCRWC  ..."
begin
apps.fnd_program.delete_program('XXARDCRWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARCREXTWC  ..."
begin
apps.fnd_program.delete_program('XXARCREXTWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFADJWCMT  ..."
begin
apps.fnd_program.delete_program('XXARFADJWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFADJWC  ..."
begin
apps.fnd_program.delete_program('XXARFADJWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDADJWCMT  ..."
begin
apps.fnd_program.delete_program('XXARDADJWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDADJWC  ..."
begin
apps.fnd_program.delete_program('XXARDADJWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARADJEXTWC  ..."
begin
apps.fnd_program.delete_program('XXARADJEXTWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFPSWCMT  ..."
begin
apps.fnd_program.delete_program('XXARFPSWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFPSWC  ..."
begin
apps.fnd_program.delete_program('XXARFPSWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program  XXARDPSWCMT ..."
begin
apps.fnd_program.delete_program('XXARDPSWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDPSWC  ..."
begin
apps.fnd_program.delete_program('XXARDPSWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARPSEXTWC  ..."
begin
apps.fnd_program.delete_program('XXARPSEXTWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFRAWCMT  ..."
begin
apps.fnd_program.delete_program('XXARFRAWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARFRAWC  ..."
begin
apps.fnd_program.delete_program('XXARFRAWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDRAWCMT  ..."
begin
apps.fnd_program.delete_program('XXARDRAWCMT','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARDRAWC  ..."
begin
apps.fnd_program.delete_program('XXARDRAWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARRAEXTWC  ..."
begin
apps.fnd_program.delete_program('XXARRAEXTWC','XXFIN');
end;
/
PROMPT "Delete Concurrent Program XXARUPDPSWCPRG  ..."
begin
apps.fnd_program.delete_program('XXARUPDPSWCPRG','XXFIN');
end;
/
PROMPT "---------------Deleting CP Executables--------------"

PROMPT "Delete Execulable XXARTXNWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARTXNWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARFTXNWC  ..."
begin
apps.fnd_program.delete_executable('XXARFTXNWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARTXNWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARTXNWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARDTXNWC  ..."
begin
apps.fnd_program.delete_executable('XXARDTXNWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARTXNEXTWC  ..."
begin
apps.fnd_program.delete_executable('XXARTXNEXTWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARCRWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARCRWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARFCRWC  ..."
begin
apps.fnd_program.delete_executable('XXARFCRWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARCRWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARCRWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARDCRWC  ..."
begin
apps.fnd_program.delete_executable('XXARDCRWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARCREXTWC  ..."
begin
apps.fnd_program.delete_executable('XXARCREXTWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARFADJWC  ..."
begin
apps.fnd_program.delete_executable('XXARFADJWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARCREXTWC  ..."
begin
apps.fnd_program.delete_executable('XXARCREXTWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARADJWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARADJWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARDADJWC  ..."
begin
apps.fnd_program.delete_executable('XXARDADJWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARADJEXTWC  ..."
begin
apps.fnd_program.delete_executable('XXARADJEXTWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARPSWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARPSWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARFPSWC  ..."
begin
apps.fnd_program.delete_executable('XXARFPSWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARPSWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARPSWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARDPSWC  ..."
begin
apps.fnd_program.delete_executable('XXARDPSWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARPSEXTWC  ..."
begin
apps.fnd_program.delete_executable('XXARPSEXTWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARRAWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARRAWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARFRAWC  ..."
begin
apps.fnd_program.delete_executable('XXARFRAWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARRAWCMT  ..."
begin
apps.fnd_program.delete_executable('XXARRAWCMT','XXFIN');
end;
/
PROMPT "Delete Execulable XXARDRAWC  ..."
begin
apps.fnd_program.delete_executable('XXARDRAWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARRAEXTWC  ..."
begin
apps.fnd_program.delete_executable('XXARRAEXTWC','XXFIN');
end;
/
PROMPT "Delete Execulable XXARUPDPSWC  ..."
begin
apps.fnd_program.delete_executable('XXARUPDPSWC','XXFIN');
end;
/
commit;

exit;
