SET SERVEROUTPUT ON;
update XX_CDH_EBL_TRANSMISSION_DTL
set email_std_message= replace(email_std_message,'electronicbilling','billingsetup');
COMMIT;
