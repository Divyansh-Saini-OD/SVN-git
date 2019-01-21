CREATE OR REPLACE PACKAGE BODY xx_lead_upload_script_pkg
IS
PROCEDURE xx_lead_upload_script_proc (p_errbuf OUT VARCHAR2,p_retcode OUT number,p_in_party_site_num IN VARCHAR2)
IS

CURSOR lcu_party_det (p_in_party_site_num IN VARCHAR2)
IS  
SELECT 
asl.description,
hzpp.person_first_name,
hzpp.person_last_name
FROM apps.as_sales_leads asl,
apps.hz_parties hzpp
WHERE 
asl.address_id = (select party_site_id from apps.hz_party_sites 
                  where party_site_number = p_in_party_site_num ) --69815427 
AND asl.primary_cnt_person_party_id = hzpp.party_id;

CURSOR lcu_duns_num (C_IN_DUNS_NUMBER NUMBER)
IS 
SELECT *
FROM (
SELECT HZPP.party_site_id,
HZPS.party_site_number,
HZPP.n_ext_attr1,
ACT.last_activity_date,
HP.party_name,
HL.address1,
HL.address2,
HL.city,
HL.state,
HL.country,
HL.postal_code
FROM 
apps.HZ_PARTY_SITES_EXT_B HZPP,
apps.HZ_PARTY_SITES HZPS,
apps.hz_locations HL,
apps.hz_parties HP,
XXCRM.XXBI_ACTIVITIES ACT
WHERE 
HZPP.attr_group_id = 161 
AND HZPS.party_site_id = HZPP.party_site_id
AND HZPP.n_ext_attr1 = c_in_duns_number
AND ACT.source_type = 'PARTY SITE'
AND ACT.source_id =  HZPP.party_site_id
AND HL.location_id=HZPS.location_id
AND HP.party_id=HZPS.party_id
ORDER BY last_activity_date desc)
WHERE ROWNUM = 1;
lrec_duns_num lcu_duns_num%rowtype;
lrec_party_det lcu_party_det%rowtype;
ln_cnt NUMBER :=0;

BEGIN
--FOR i IN lcu_party_det
FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
   'Description'||'|'||'person_first_name(Name)'||'|'|| 'person_last_name(DUNS num)'||'|'||'party_site_number'||'|'||'last_activity_date'
   ||'|'||'party_name'||'|'||'address1'||'|'||'address2'||'|'||
   'city'||'|'||'state'||'|'||'country'||'|'||'postal_code');
OPEN lcu_party_det(p_in_party_site_num);
LOOP
 
 FETCH lcu_party_det INTO lrec_party_det;
  IF lcu_party_det%rowcount=0 THEN
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Error : Invalid party number. No data found for this party number');
     p_retcode:=2;
     p_errbuf:='Invalid party number';
  END IF;
 EXIT WHEN lcu_party_det%NOTFOUND;
 FND_FILE.PUT_LINE (FND_FILE.LOG,'Inside loop');
 

 --for lrec_duns_num in lcu_duns_num (lrec_party_det.person_last_name)
 OPEN lcu_duns_num (lrec_party_det.person_last_name);
 lrec_duns_num := NULL;
 FETCH lcu_duns_num INTO lrec_duns_num;
   ln_cnt := ln_cnt + 1;
   FND_FILE.PUT_LINE (FND_FILE.OUTPUT,
   lrec_party_det.description||'|'||lrec_party_det.person_first_name||'|'|| lrec_party_det.person_last_name||'|'||NVL(lrec_duns_num.party_site_number,'NA')||'|'||NVL((to_char(lrec_duns_num.last_activity_date,'dd-Mon-yyyy HH:mi:ss AM')),'NA')
   ||'|'||NVL(lrec_duns_num.party_name,'NA')||'|'||NVL(lrec_duns_num.address1,'NA')||'|'||NVL(lrec_duns_num.address2,'NA')||'|'||
   NVL(lrec_duns_num.city,'NA')||'|'||NVL(lrec_duns_num.state,'NA')||'|'||NVL(lrec_duns_num.country,'NA')||'|'||NVL(lrec_duns_num.postal_code,'NA'));
 CLOSE lcu_duns_num;
  
END LOOP;
fnd_file.put_line (fnd_file.log,'No. of rows processed : '||ln_cnt);
CLOSE lcu_party_det;
EXCEPTION
WHEN OTHERS THEN
fnd_file.put_line (fnd_file.log,'Error : '||SQLCODE || SQLERRM); 
END xx_lead_upload_script_proc;
END xx_lead_upload_script_pkg;

/
SHOW ERROR;