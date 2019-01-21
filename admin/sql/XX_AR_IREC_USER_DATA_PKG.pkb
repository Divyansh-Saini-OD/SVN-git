create or replace
PACKAGE BODY XX_AR_IREC_USER_DATA_PKG
 AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_IREC_USER_DATA_PKG                                     |
-- | RICE ID : R1173                                                     |
-- | Description : This packages helps to get a report with              |
-- |                ireceivables user data                               |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author                 Remarks           |
-- |======   ==========     =============        ======================= |
-- |Draft 1A 23-AUG-2010    Cindhu Nagarajan      Initial version        |
-- |                                              CR 803 Defect # 4221   |
-- |1.1      05-Jan-2016    Manikant Kasu        Removed schema alias as | 
-- |                                             part of GSCC R12.2.2    |
-- |                                              Retrofit               |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  GET_IREC_USER_DATA                                          |
-- | RICE ID : R1173                                                     |
-- | Description : This  procedure will get irec user data               |
-- |                                                                     |
-- | Parameters :  p_from_date,p_to_date,p_report_type                   |
-- | Returns    :  x_err_buff,x_ret_code                                 |
-- +=====================================================================+

 PROCEDURE GET_IREC_USER_DATA(x_err_buff        OUT NOCOPY VARCHAR2
                             ,x_ret_code        OUT NOCOPY NUMBER
                             ,p_from_date       IN  VARCHAR2
                             ,p_to_date         IN  VARCHAR2
                             ,p_report_type     IN  VARCHAR2
                             )
 IS

    ln_error_flag          NUMBER  :=0;
    ld_from_date           DATE    := TO_DATE(p_from_date,'YYYY/MM/DD HH24:MI:SS');
    ld_to_date             DATE    := TO_DATE(p_to_date,'YYYY/MM/DD HH24:MI:SS');
    ln_org                 NUMBER  := fnd_profile.value('ORG_ID');
    lc_account_number      VARCHAR2(1000);
    lc_account_name        VARCHAR2(1000);
    lc_job_title           VARCHAR2(1000);
    lc_responsibility_name VARCHAR2(1000);


----------------------------------------------------
------ Cursor to get Ireceivables user data --------
----------------------------------------------------

    CURSOR lcu_get_irec_user_data(ld_from_date    IN DATE
                                 ,ld_to_date      IN DATE
                                 ,p_report_type  IN VARCHAR2
                                 )
    IS
       (SELECT   fu.user_name external_user_id
                ,xeu.person_first_name||' '||xeu.Person_last_name User_Name
                ,xeu.creation_date date_added
                ,MAX(iss.last_connect) last_used
                ,xeu.last_update_date last_modified
                ,xeu.email
                ,xeu.party_id
                ,xeu.access_code
       FROM     xx_external_users  xeu
                ,fnd_user fu
                ,icx_sessions iss
       WHERE    p_report_type              IN ('User Info Last Updated','All')
       AND      TRUNC(xeu.last_update_date) BETWEEN ld_from_date AND ld_to_date
       AND      xeu.fnd_user_name           = fu.user_name
       AND      fu.user_id                  = iss.user_id(+)
       GROUP BY fu.user_name
                ,xeu.person_first_name||' '||xeu.Person_last_name
                ,xeu.creation_date
                ,xeu.last_update_date
                ,xeu.email
                ,xeu.party_id
                ,xeu.access_code
       UNION
       SELECT   fu.user_name external_user_id
                ,xeu.person_first_name||' '||xeu.Person_last_name User_Name
                ,xeu.creation_date date_added
                ,MAX(iss.last_connect) last_used
                ,xeu.last_update_date last_modified
                ,xeu.email
                ,xeu.party_id
                ,xeu.access_code
       FROM     xx_external_users  xeu
                ,fnd_user fu
                ,icx_sessions iss
       WHERE    p_report_type IN ('User Last Accessed','All')
       AND      TRUNC(iss.last_connect) BETWEEN ld_from_date AND ld_to_date
       AND      xeu.fnd_user_name     = fu.user_name
       AND      fu.user_id            = iss.user_id
       GROUP BY fu.user_name
                ,xeu.person_first_name||' '||xeu.Person_last_name
                ,xeu.creation_date
                ,xeu.last_update_date
                ,xeu.email
                ,xeu.party_id
                ,xeu.access_code
              );
    BEGIN
       IF (ld_to_date - ld_from_date) <= 60 THEN
          BEGIN
             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                               --  '||||OD: Ireceivables User Data Report||From Date: ' || ld_from_date || CHR(13)
                             -- || '||||||To Date    : ' || ld_to_date || CHR(13)
                                       'From Date' 
                              || '|' ||'To Date'
                              || '|' ||'External User ID'
                              || '|' ||'User Name'
                              || '|' ||'Date Added'
                              || '|' ||'Last Used'
                              || '|' ||'last modified'
                              || '|' ||'Responsibility Name'
                              || '|' ||'Account Number'
                              || '|' ||'Account Name'
                              || '|' ||'User job title'
                              || '|' ||'User email'
                              );
             FND_FILE.PUT_LINE(FND_FILE.LOG,'Header details have been written successfully');
             EXCEPTION
                WHEN OTHERS THEN
                   ln_error_flag := 1;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while writing header details '|| SQLERRM);
                   RAISE;
          END;


          FOR lr_get_irec_user_data IN lcu_get_irec_user_data(ld_from_date
                                                             ,ld_to_date
                                                             ,p_report_type)
             LOOP
                 ln_error_flag := 0;
                 BEGIN
                    SELECT hca.account_number
                           ,hca.account_name
                           ,hoc.job_title
                    INTO   lc_account_number
                           ,lc_account_name
                           ,lc_job_title
                    FROM   hz_relationships hr
                           ,hz_cust_accounts hca
                           ,hz_org_contacts hoc
                    WHERE  hr.party_id           = lr_get_irec_user_data.party_id
                    AND    hr.object_type        = 'ORGANIZATION'
                    AND    hr.object_id          = hca.party_id
                    AND    hca.status            = 'A'
                    AND    hr.relationship_id    = hoc.party_relationship_id;
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'No data available for the party id - ' || lr_get_irec_user_data.party_id || ' External user id - ' || lr_get_irec_user_data.external_user_id);
                        ln_error_flag := 2;
                    WHEN TOO_MANY_ROWS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Too many data available for the party id - ' || lr_get_irec_user_data.party_id || ' External user id - ' || lr_get_irec_user_data.external_user_id);
                        ln_error_flag := 3;
                 END;

                 BEGIN
                    SELECT REPLACE(frv.responsibility_name,(DECODE(ln_org,404,'(US)',403,'(CA)')),'(XX)') responsibility_name
                    INTO   lc_responsibility_name
                    FROM   xx_fin_translatedefinition xftd
                           ,xx_fin_translatevalues xftv
                           ,FND_RESPONSIBILITY_VL frv
                    WHERE  frv.responsibility_key      = xftv.target_value1
                    AND    xftd.translate_id           = xftv.translate_id
                    AND    xftd.translation_name       ='XX_IREC_RESP_MAP'
                    AND    xftv.source_value2          = lr_get_irec_user_data.access_code
                    AND    frv.responsibility_name     LIKE (DECODE(ln_org,404,'%(US)%',403,'%(CA)%'));
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'No data available for the access code - ' || lr_get_irec_user_data.access_code || ' External user id - ' || lr_get_irec_user_data.external_user_id);
                        ln_error_flag := 4;
                    WHEN TOO_MANY_ROWS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'No data available for the access code - ' || lr_get_irec_user_data.access_code || ' External user id - ' || lr_get_irec_user_data.external_user_id);
                        ln_error_flag := 5;
                 END;

                 BEGIN
                    IF ln_error_flag < 1 THEN
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ld_from_date
                                                || '|' || ld_to_date
                                                || '|' || lr_get_irec_user_data.external_user_id
                                                || '|' || lr_get_irec_user_data.User_Name
                                                || '|' || lr_get_irec_user_data.date_added
                                                || '|' || lr_get_irec_user_data.last_used
                                                || '|' || lr_get_irec_user_data.last_modified
                                                || '|' || lc_responsibility_name
                                                || '|' || lc_account_number
                                                || '|' || lc_account_name
                                                || '|' || lc_job_title
                                                || '|' || lr_get_irec_user_data.email
                                        );
                    END IF;
                 EXCEPTION
                    WHEN OTHERS THEN
                        ln_error_flag := 6;
                 END;
             END LOOP;

             IF ln_error_flag >= 1 THEN
               -- x_ret_code := 1;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'End of Get Irec User Data Procedure with ln_error_flag value ' || ln_error_flag);
             ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG,'File has been written successfully with user data' || CHR(13)
                                      || 'End of Get Irec User Data Procedure  with ln_error_flag value is ' || ln_error_flag);
             END IF;

       ELSE
          FND_FILE.PUT_LINE(FND_FILE.LOG,'The report can be fetched for a period of 60 days only, Pls try with different date range.');
         --  x_ret_code := 1;
       END IF;

    EXCEPTION
       WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,' Exception raised while Ending of Get Irec User Data Procedure with ln_error_flag value is ' || ln_error_flag || '-----' || SQLERRM);
       --x_ret_code := 1;
    END GET_IREC_USER_DATA;

 END XX_AR_IREC_USER_DATA_PKG;
/