CREATE OR REPLACE FORCE VIEW XX_AP_C2FO_USER_V (
    "COMPANY_ID",
    "DIVISION_ID",
    "EMAIL_ADDRESS",
    "FIRST_NAME",
    "LAST_NAME",
    "TITLE",
    "PHONE_NUMBER",    
    "ADDRESS_1",
    "ADDRESS_2",
    "CITY",
    "STATE",
    "POSTAL_CODE",
    "COUNTRY"
)
AS SELECT
        replace(replace(assa.org_id|| '|'||assa.vendor_id|| '|'|| assa.vendor_site_id,',',''),'"','') AS company_id,   --concatenation to get a unique ORGANIZATION for each vendor/site combinationa.vendor_id,
        NULL AS division_id,
        replace(replace(apsc.email_address,',',''),'"','') AS email_address,
        replace(replace(apsc.first_name,',',''),'"','') AS first_name,
        replace(replace(apsc.last_name,',',''),'"','') AS last_name,
        replace(replace(apsc.title,',',''),'"','') AS title,
        replace(replace(apsc.area_code|| '-'||apsc.phone,',',''),'"','') AS phone_number,        
        replace(replace(assa.address_line1,',',''),'"','') AS address_1,
        replace(replace(assa.address_line2,',',''),'"','') AS address_2,
        replace(replace(assa.city,',',''),'"','') AS city,
        replace(replace(assa.state,',',''),'"','') AS state,
        replace(replace(assa.zip,',',''),'"','') AS postal_code,
        --replace(replace(assa.country,',',''),'"','') AS country
        replace(replace(assa.country|| '|'|| (select hg.geography_name from ar.hz_geographies hg where hg.geography_type = 'COUNTRY' and hg.country_code =assa.country),',',''),'"','') AS country
    FROM
        apps.ap_supplier_sites_all assa,
        apps.ap_supplier_contacts apsc
    WHERE
           apsc.vendor_site_id = assa.vendor_site_id
        AND nvl(assa.inactive_date,SYSDATE + 1) > SYSDATE
        AND nvl(apsc.inactive_date,SYSDATE + 1) > SYSDATE;
