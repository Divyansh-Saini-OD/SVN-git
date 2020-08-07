begin
apps.JDR_UTILS.PRINTDOCUMENT('/oracle/apps/fnd/framework/webui/customizations/site/0/OADialogPage');
APPS.JDr_UTILS.deleteDOCUMENT('/oracle/apps/fnd/framework/webui/customizations/site/0/OADialogPage');
commit;
end;
/