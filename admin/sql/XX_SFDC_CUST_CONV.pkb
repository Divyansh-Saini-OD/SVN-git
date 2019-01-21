SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE BODY XX_SFDC_CUST_CONV AS





  PROCEDURE create_gp (
   x_errbuf                 OUT NOCOPY VARCHAR2,
   x_retcode                OUT NOCOPY VARCHAR2,
   p_conv_type              VARCHAR2 DEFAULT 'FULL'
  )
  IS
  l_rec_status          VARCHAR2(5);
  l_rec_msg             VARCHAR2(2000);
  l_batch_id            NUMBER := 1;
  l_tot_cust_updated    NUMBER := 0;
  l_cust_rec_type       VARCHAR2(100);

  CURSOR gp_cur
  IS
  SELECT DISTINCT PARTY_ID EBIZ_PARTY_ID,GP_ID,SUBSTR(GP_NAME,0,30) NAME, GP_NAME LEGAL_NAME,
         NVL(cid.user_name,'000000') CREATED_BY,
         NVL(mid.user_name,'000000') LAST_MODIFIED_BY ,
         gp.creation_date,
         gp.last_update_date,
         gp.status,
         gp.w_agreement_flag
  FROM xx_cdh_gp_master gp,
  xx_crm_emp_resources_v cid,
  xx_crm_emp_resources_v mid
  WHERE gp.created_by = cid.user_id(+)
  and gp.last_updated_by = mid.user_id(+);

  BEGIN
    l_rec_status := 0;
  l_rec_msg  := NULL;
  XX_SFDC_CUST_CONV.set_delta_times(x_errbuf => l_rec_msg, x_retcode => l_rec_status);


  IF l_rec_status = 2 THEN
    fnd_file.put_line(fnd_file.log,'Cannot modify delta datetime profile' || SQLERRM);
  END IF;

    l_cust_rec_type  := fnd_profile.value ('XX_CRM_SFDC_CUSTOMER_RECTYPE');

    xx_crm_exp_batch_pkg.generate_batch_id (l_batch_id, '', 'GRANDPARENT');

     FOR gp IN gp_cur LOOP

        l_rec_status  := NULL;
        l_rec_msg     := NULL;

      BEGIN

        xx_sfdc_cust_conv_pvt.insert_XX_CRM_EXP_ACCOUNT (

                   BATCH_ID                  => l_batch_id,
                   EBIZ_PARTY_ID             => gp.EBIZ_PARTY_ID,
                   NAME                      => gp.NAME,
                   LEGAL_NAME                => gp.LEGAL_NAME,
                   GP_LEGAL_FLAG             => gp.w_agreement_flag,
                   AOPS_CUST_ID              => NULL,
                   GRANDPARENT_ID            => NULL,
                   PARENT_AOPS_CUST_ID       => NULL,
                   PARENT_EBIZ_PARTY_ID      => NULL,
                   PARENT_EBIZ_ACCOUNT_ID    => NULL,
                   SEGMENT                   => NULL,
                   SECTOR                  => NULL,
                   DUNS_NUMBER               => NULL,
                   SIC_CODE                  => NULL,
                   TOTAL_EMPLOYEES           => NULL,
                   OD_WCW                    => NULL,
                   DNB_WCW                   => NULL,
                   TYPE                      => NULL,
                   BILLING_STREET            => NULL,
                   BILLING_CITY              => NULL,
                   BILLING_STATE             => NULL,
                   BILLING_POSTALCODE        => NULL,
                   BILLING_COUNTRY           => NULL,
                   SHIPPING_STREET           => '6600 N Military Trl',
                   SHIPPING_CITY             => 'BOCA RATON',
                   SHIPPING_STATE            => 'FL',
                   SHIPPING_POSTALCODE       => '33496',
                   SHIPPING_COUNTRY          => 'US',
                   PHONE                     => NULL,
                   PHONE_EXT                 => NULL,
                   INDUSTRY_OD_SIC_REP       => NULL,
                   INDUSTRY_OD_SIC_DNB       => NULL,
                   CREATED_BY                => gp.created_by,
                   CREATION_DATE             => gp.creation_date,
                   OWNER_ID                  => NULL,
                   LAST_MODIFIED_BY          => gp.last_modified_by,
                   LAST_MODIFIED_DATE        => gp.last_update_date,
                   EBIZ_PARTY_NUMBER         => NULL,
                   STATUS                    => gp.status,
                   REVENUE_BAND              => NULL,
                   LOYALTY_TYPE              => NULL,
                   SFDC_RECORD_TYPE_ID       => l_cust_rec_type,
                   RECORD_TYPE               => 'GP',
                   GP_ID                     => gp.gp_id,
                   x_ret_status              => l_rec_status,
                   x_ret_msg                 => l_rec_msg
                  );

               IF l_rec_status = 'E' THEN
                  fnd_file.put_line(fnd_file.log,'Error During Insert:' || gp.ebiz_party_id || '::' || l_rec_msg);
               ELSE
                  l_tot_cust_updated := l_tot_cust_updated + 1;
               END IF;

          EXCEPTION WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Error during API insert of GP party id:' || gp.ebiz_party_id || '::' || SQLERRM);
          END;
          COMMIT;
        END LOOP;

        xx_crm_exp_batch_pkg.generate_file (x_errbuf, x_retcode, l_batch_id);

 EXCEPTION WHEN OTHERS THEN
     x_retcode := 2;
     x_errbuf  := 'Unexpected Error during Customer Load:' || SQLERRM;
 END;


PROCEDURE create_cust_hier(
   x_errbuf                 OUT NOCOPY VARCHAR2,
   x_retcode                OUT NOCOPY VARCHAR2,
   p_conv_type              VARCHAR2 DEFAULT 'FULL'
  )
IS

l_batch_id                   NUMBER := 1;
l_rec_status                 VARCHAR2(5);
l_rec_msg                    VARCHAR2(2000);
l_tot_hier_updated           NUMBER := 0;
l_start_date                 DATE := SYSDATE-1;
l_end_date                   DATE := SYSDATE;
l_cust_rec_type              VARCHAR2(100);

CURSOR pid_cur (p_start_date DATE , p_end_date  DATE)
IS
SELECT p.party_id
FROM
(
SELECT prel.object_id  party_id
FROM hz_relationships prel
WHERE prel.relationship_type = 'OD_CUST_HIER'
AND prel.relationship_code = 'PARENT_COMPANY'
AND prel.direction_code = 'P'
AND prel.last_update_date BETWEEN p_start_date AND p_end_date
UNION
SELECT grel.object_id  party_id
FROM
      hz_relationships grel,
      (
       select * from hz_relationships
       where relationship_type = 'OD_CUST_HIER'
       and relationship_code = 'PARENT_COMPANY'
       and direction_code = 'P'
       and status = 'A'
       and sysdate between start_date and end_date
       ) prel
WHERE grel.relationship_type = 'OD_CUST_HIER'
AND grel.relationship_code = 'GRANDPARENT'
AND grel.last_update_date BETWEEN p_start_date AND p_end_date
AND grel.direction_code = 'P'
AND prel.subject_id(+) = grel.object_id
UNION
SELECT prel.object_id  party_id
FROM
      hz_relationships grel,
      (
       select * from hz_relationships
       where relationship_type = 'OD_CUST_HIER'
       and relationship_code = 'PARENT_COMPANY'
       and direction_code = 'P'
       and status = 'A'
       and sysdate between start_date and end_date
       ) prel
WHERE grel.relationship_type = 'OD_CUST_HIER'
AND grel.relationship_code = 'GRANDPARENT'
AND grel.last_update_date BETWEEN p_start_date AND p_end_date
AND grel.direction_code = 'P'
AND prel.subject_id(+) = grel.object_id
) p, hz_cust_accounts act
WHERE act.party_id = p.party_id
AND act.status = 'A';

CURSOR cust_rec_cur (p_party_id NUMBER)
IS
select distinct
       p.PARTY_ID EBIZ_PARTY_ID,
       trf_null(NVL(gp_m.gp_id,gpc_m.gp_id)) grandparent_id,
       trf_null(substr(prnt_c.orig_system_reference,0,8)) parent_aops_cust_id,
       trf_null(NVL(prnt_c.party_id,gpc.subject_id)) parent_ebiz_party_id
from hz_parties P,
       (
       select * from hz_relationships
       where relationship_type = 'OD_CUST_HIER'
       and relationship_code = 'PARENT_COMPANY'
       and direction_code = 'P'
       and status = 'A'
       and sysdate between start_date and end_date
       ) prnt,
       (
       select * from hz_relationships
       where relationship_type = 'OD_CUST_HIER'
       and relationship_code = 'GRANDPARENT'
       and direction_code = 'P'
       and status = 'A'
       and sysdate between start_date and end_date
       ) gp,
         (
       select * from hz_relationships
       where relationship_type = 'OD_CUST_HIER'
       and relationship_code = 'GRANDPARENT'
       and direction_code = 'P'
       and status = 'A'
       and sysdate between start_date and end_date
       ) gpc,
       hz_cust_accounts prnt_c,
       xx_cdh_gp_master gp_m,
       xx_cdh_gp_master gpc_m
where prnt.object_id(+) = p.party_id
and prnt_c.party_id(+) = prnt.subject_id
and gp.object_id(+) = prnt.subject_id
and gpc.object_id(+) = p.party_id
and gp_m.party_id(+) = gp.subject_id
and gpc_m.party_id(+) = gpc.subject_id
and p.party_id = p_party_id;

BEGIN

    xx_crm_exp_batch_pkg.generate_batch_id (l_batch_id, '', 'CUST_HIER');

    l_cust_rec_type  := fnd_profile.value ('XX_CRM_SFDC_CUSTOMER_RECTYPE');

    l_start_date     := TO_DATE(fnd_profile.value('XX_CRM_SFDC_CUST_CONV_START_DATE'),'MM/DD/YYYY HH24:MI:SS');
    l_end_date       := TO_DATE(fnd_profile.value('XX_CRM_SFDC_CUST_CONV_END_DATE'),'MM/DD/YYYY HH24:MI:SS');

    FOR pid IN pid_cur (l_start_date, l_end_date) LOOP
      FOR cst IN cust_rec_cur(pid.party_id) LOOP

      BEGIN
         xx_sfdc_cust_conv_pvt.insert_XX_CRM_EXP_CUST_HIER (
          BATCH_ID                    => l_batch_id,
          EBIZ_PARTY_ID               => cst.ebiz_party_id,
          GRANDPARENT_ID              => cst.grandparent_id,
          PARENT_AOPS_CUST_ID         => cst.parent_aops_cust_id,
          PARENT_EBIZ_PARTY_ID        => cst.parent_ebiz_party_id,
          SFDC_RECORD_TYPE_ID         => l_cust_rec_type,
          x_ret_status                => l_rec_status,
          x_ret_msg                   => l_rec_msg
          );

         IF l_rec_status = 'E' THEN
            fnd_file.put_line(fnd_file.log,'Error in insert:' || l_rec_msg);
         ELSE
            l_tot_hier_updated := l_tot_hier_updated + 1;
         END IF;


       EXCEPTION WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log,'Error during API Call insert_xx_crm_exp_cust_hier:' || SQLERRM);
       END;

      END LOOP;
      COMMIT;
    END LOOP;

     fnd_file.put_line(fnd_file.log,'Total Hierarchies Updated:' || l_tot_hier_updated);

     xx_crm_exp_batch_pkg.generate_file (x_errbuf, x_retcode, l_batch_id);

EXCEPTION WHEN OTHERS THEN
   x_retcode := 2;
   x_errbuf  := 'Unexpected Error during Hierarchy Generation:' || SQLERRM;
END;




 FUNCTION fnc_created_by (p_created_by VARCHAR2)
 RETURN VARCHAR2
   IS
      lc_employee_number   VARCHAR2 (30);
   BEGIN

      SELECT user_name
        INTO lc_employee_number
--        FROM jtf_rs_emp_dtls_vl
	FROM xx_crm_emp_resources_v
       WHERE user_id = p_created_by
         AND user_name IS NOT NULL
	 AND USER_NAME NOT IN ('ODCDH', 'ODSFA', 'ODCRMBPEL')
	 AND STATUS='A'
         AND ROWNUM = 1;

      RETURN lc_employee_number;
   EXCEPTION
      WHEN OTHERS
      THEN
         lc_employee_number:='000000';
	 RETURN lc_employee_number;
   END fnc_created_by;


  FUNCTION trf_country (
    p_country       VARCHAR2
  ) RETURN VARCHAR2
  IS
  BEGIN
    IF p_country = 'CA' THEN
      RETURN 'CAN';
    ELSE
      RETURN 'USA';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Country Could Not Be Derived:' || SQLERRM);
    RETURN p_country;
  END;


FUNCTION trf_null(trval VARCHAR2)
RETURN VARCHAR2
IS
  BEGIN
    IF trim(trval) IS NULL THEN
      RETURN '#N/A';
    ELSE
      RETURN trval;
    END IF;
 END;

 FUNCTION trf_phone (
    p_country_code       VARCHAR2,
    p_area_code          VARCHAR2,
    p_phone_num          VARCHAR2,
    p_raw_phone          VARCHAR2,
    p_extension          VARCHAR2,
    p_type               VARCHAR2
  ) RETURN VARCHAR2
  IS

  l_phone_str     VARCHAR2(100);
  l_ext           VARCHAR2(240);
  l_numeric_val   NUMBER;

  BEGIN

  IF p_type = 'p' THEN

     BEGIN

       IF p_country_code IS NOT NULL AND p_country_code = '1' AND length(trim(p_area_code)) = 3 AND length(trim(p_phone_num)) = 7 THEN

        l_numeric_val   := TO_NUMBER(trim(p_area_code));
        l_numeric_val   := TO_NUMBER(trim(p_phone_num));

        l_phone_str := l_phone_str || '(' || TRIM(p_area_code) || ') ' || substr(trim(p_phone_num),0,3) || '-' || substr(trim(p_phone_num),4,4);

       ELSE

        RETURN NULL;

       END IF;

       RETURN l_phone_str;

     EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
     END;

   ELSIF p_type = 's' THEN

     BEGIN

       IF p_country_code IS NOT NULL AND p_country_code = '1' AND length(trim(p_area_code)) = 3 AND length(trim(p_phone_num)) = 7 THEN

         l_numeric_val   := TO_NUMBER(trim(p_area_code));
         l_numeric_val   := TO_NUMBER(trim(p_phone_num));

         RETURN NULL;

       ELSE

          l_phone_str := p_country_code || p_area_code || p_phone_num;

       END IF;

       RETURN l_phone_str;

     EXCEPTION WHEN OTHERS THEN
        l_phone_str := '(' || TRIM(p_area_code) || ') ' || substr(trim(p_phone_num),0,3) || '-' || substr(trim(p_phone_num),4,4);
        RETURN l_phone_str;
     END;

   ELSE

      IF p_extension IS NOT NULL THEN
         l_ext := p_extension;
      ELSE

        IF substr(p_raw_phone,14) IS NOT NULL THEN
           l_ext := substr(p_raw_phone,14);
        END IF;

      END IF;

      RETURN l_ext;


   END IF;

  END;

 PROCEDURE set_delta_times(
   x_errbuf                 OUT NOCOPY VARCHAR2,
   x_retcode                OUT NOCOPY VARCHAR2
  )
  IS
  l_start_date            DATE;
  l_end_date              DATE;
  l_ret_st               BOOLEAN;
  l_ret_en               BOOLEAN;
  BEGIN

   l_ret_st := FND_PROFILE.SAVE('XX_CRM_SFDC_CUST_CONV_START_DATE',FND_PROFILE.VALUE('XX_CRM_SFDC_CUST_CONV_END_DATE'),'SITE');
   l_ret_en := FND_PROFILE.SAVE('XX_CRM_SFDC_CUST_CONV_END_DATE',TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS'),'SITE');

   COMMIT;

   IF l_ret_st IS NULL OR l_ret_st = false OR l_ret_en IS NULL OR l_ret_st = false THEN
       x_retcode := 2;
       x_errbuf  := 'Profile Option for SFDC Conversion Time Could not be Set';
   END IF;

  EXCEPTION WHEN OTHERS THEN
     x_retcode := 2;
     x_errbuf  := 'Unexpected Error during Contact Load:' || SQLERRM;
  END;


END XX_SFDC_CUST_CONV;
/


SHOW ERRORS;