-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        Office Depot                               |
-- +===================================================================+
-- | Name             : XXGLBSITE.SQL		                       |
-- | Rice ID	    : I1176 CreateServiceRequest                       |
-- | Description      : This scipt adds site keys for Release 1.0      |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1   28-JAN-2007 Bibiana Penski   Initial Version             |
-- |                                                                   |
-- +===================================================================+


declare

lc_site_id NUMBER;

BEGIN

DBMS_OUTPUT.PUT_LINE('PROMPT CREATING US SITE');


INSERT INTO XXOM.XX_GLB_SITEKEY_ALL
 (site_key_id,   site_brand,   site_mode,   country_code,   language_code,   operating_unit,   order_source_code,   active_from,   active_to,   attribute1,   attribute2,   creation_date,   created_by)
VALUES(xx_glb_sitekey_s.nextval,   'OD',   NULL,   'US',   'EN',   141,   'GMILL',   sysdate,   NULL,   '66105',   '22851', sysdate,  2 )
returning site_key_id into lc_site_id;

DBMS_OUTPUT.PUT_LINE('generated site key '||lc_site_id);
commit;

DBMS_OUTPUT.PUT_LINE('PROMPT CREATING CANADA SITE');

INSERT INTO XXOM.XX_GLB_SITEKEY_ALL
 (site_key_id,   site_brand,   site_mode,   country_code,   language_code,   operating_unit,   order_source_code,   active_from,   active_to,   attribute1,   attribute2,   creation_date,   created_by)
VALUES(xx_glb_sitekey_s.nextval,   'OD',   NULL,   'CA',   'EN',   161,   'GMILL',   sysdate,   NULL,   '66105',   '22851', sysdate,  2 )
returning site_key_id into lc_site_id;

DBMS_OUTPUT.PUT_LINE('generated site key '||lc_site_id);
commit;
END;
