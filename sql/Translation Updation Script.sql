
/****
The following updation is required  to make sure the AJB FTPing process does not point to Production server 
*****/
update xxfin.xx_fin_translatevalues 
set Target_value1='https://USCHAJBUATAPP01.na.odcorp.net:28101'
where source_value1='HTTPURL' and  translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='FTP_DETAILS_AJB');

update xxfin.xx_fin_translatevalues 
set Target_value1='/app/ebs/ctgsi&instance/xxfin/archive/outbound/AJB'
where source_value1='AJB_SETTLEMENT_ARCHIVE_PATH' and  translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='FTP_DETAILS_AJB');

update xxfin.xx_fin_translatevalues 
set Target_value1='file:/app/ebs/atgsi&instance/gsi&instance'||'appl/admin '
where source_value1='HTTPWalletLoc' and  translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='FTP_DETAILS_AJB');

update xxfin.xx_fin_translatevalues 
set Target_value1='/app/ebs/ctgsi&instance/xxfin/ftp/out/amexcpc'
where source_value1='Amex File Path' and  translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='FTP_DETAILS_AJB');

update xxfin.xx_fin_translatevalues 
set Target_value1='Siva.Machavolu@OfficeDepot.com'
where source_value1='Email' and  translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='FTP_DETAILS_AJB');

/*
The following  Updation script is used for removing the  production AP check printer  from the translation
*/

update xxfin.xx_fin_translatevalues 
set source_value2=null, source_value6=null, source_value9=null, source_value10=null
where source_value1 in ('Scotia - Corp CAD AP Disb', 'Scotia - Corp USD AP Disb','Wach - Corp AP Disb') 
and  translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='AP_CHECK_PRINT_BANK_DTLS');

/*
This is to remove the FTP process not to send the vertex file to the Production
*/

update xxfin.xx_fin_translatevalues 
set target_value1='GANDHI', target_value2='SQCURRENT', target_value3='SQCURRENT', 
target_value5='SDPLIB'
where source_value1 = ('OD_AR_VERTEX_IFACE') 
and  translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='OD_FTP_PROCESSES');

/* This is to update the Email address  when a GL interface runs for various source */

update xxfin.xx_fin_translatevalues 
set target_value1=null, target_value2=null, target_value3=null, 
target_value4=null
where translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='GL_INTERFACE_EMAIL');


/* This is to update the Sales Tax Extract Email with FA name Siva Machavolu */

update xxfin.xx_fin_translatevalues 
set target_value1='siva.machavolu@wipro.com'
where translate_id = (Select translate_id from 
xxfin.xx_fin_translatedefinition where translation_name='XX_SALES_TAX_EXTRACT_MAIL');

/* This is to update the D and B Extract */
update xxfin.xx_fin_translatevalues 
set Target_value5='/app/ebs/ctgsi&instance/xxfin/ftp/out/trade/',
target_value6 ='/app/ebs/ctgsi&instance/xxfin/archive/outbound' 
WHERE translate_id = (select translate_id 
from xxfin.xx_fin_translatedefinition where translation_name = 'XX_AR_CUST_EXT_TRADE_FILE')
and target_value5 is not null;

