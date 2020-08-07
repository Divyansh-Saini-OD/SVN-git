
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name : XX_AR_GET_DELIVERY_EMAIL.sql                                      |
-- | Description :  This procedure determines the delivery method             |
-- |                email address for a given Site Use ID.                    |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author              Remarks                       |
-- |=======   ==========   ==============       ==============================|
-- |1.0       06-JUL-2007  Shivkumar Iyer       Initial version               |
-- |1.1       22-MAY-2008  Sambasiva Reddy D    Changed for the Defect# 7225  |
-- |                                            to get Multiple E-mail address|
-- |                                            from Contacts tab Instead of  |
-- |                                            Comminication Tab             |
-- +==========================================================================+
-- +==========================================================================+
-- | Name : XX_AR_GET_DELIVERY_EMAIL                                          |
-- | Description :  Procedure to derive email address for the                 |
-- |                associated bill to Site Use ID.                           |
-- |                                                                          |
-- | Parameters : OUT : x_mail_add                                            |
-- |              IN  : p_site_use_id                                         |
-- | Returns    : Email Address corresponding to Site Use Id.                 |
-- +==========================================================================+

CREATE OR REPLACE PROCEDURE XX_AR_GET_DELIVERY_EMAIL (
    p_site_use_id       IN       VARCHAR2                              
   ,x_mail_add          OUT      VARCHAR2
)
AS
lc_concat VARCHAR2(5000);

/*The following code has been added to get the multiple Email address
from Contacts tab instead of Communication tab for the Defect #7225*/

CURSOR lcu_email
IS
SELECT HCP.email_address
FROM   hz_cust_site_uses_all HCSU
      ,hz_cust_acct_sites_all HCAS
      ,hz_cust_account_roles  HCAR
      ,hz_contact_points HCP
WHERE  HCSU.site_use_id =p_site_use_id
AND    HCAS.cust_acct_site_id=HCSU.cust_acct_site_id 
AND    HCSU.cust_acct_site_id = HCAR.cust_acct_site_id 
AND    HCP.owner_table_id = HCAR.party_id
AND    HCSU.site_use_code = 'BILL_TO'
AND    HCAS.status='A'
AND    HCP.status = 'A'
AND    HCP.contact_point_type='EMAIL'
AND    HCP.contact_point_purpose='STATEMENTS'
ORDER BY HCP.email_address;

email_rec lcu_email%ROWTYPE;


BEGIN
    
    BEGIN
    /*The following code has been commented to get the multiple Email address
              from Contacts tab instead of Communication tab for the Defect #7225*/
    /*  SELECT HCP.email_address
        INTO x_mail_add
        FROM hz_party_sites          HPS
            ,hz_contact_points       HCP
            ,hz_party_site_uses      HPSU
            ,hz_cust_acct_sites_all  HCAS
            ,hz_cust_site_uses       HCSU
            ,hz_cust_accounts        HCA
            ,ar_lookups              LOOK
        WHERE HCP.owner_table_id=HPS.party_site_id
        AND   HCP.status = 'A'
        AND   HCP.primary_flag = 'Y'
        AND   HCP.contact_point_type NOT IN ('EDI')
        AND   NVL(HCP.phone_line_type, HCP.contact_point_type) = LOOK.lookup_code
        AND   LOOK.lookup_type = 'COMMUNICATION_TYPE'
        AND   LOOK.lookup_code = 'EMAIL'
        AND   HPS.party_site_id=HPSU.party_site_id
        AND   HPSU.site_use_type = 'BILL_TO'
        AND   HPS.party_site_id = HCAS.party_site_id
        AND   HCAS.cust_acct_site_id = HCSU.cust_acct_site_id 
        AND   HCSU.SITE_USE_ID = p_site_use_id
        AND   HCA.cust_account_id=HCAS.cust_account_id
        AND   HCAS.status = 'A'; 
    */
    /*The following code has been added to get the multiple Email address
      from Contacts tab instead of Communication tab for the Defect #7225*/
        OPEN lcu_email;
        FETCH lcu_email INTO email_rec;

        IF email_rec.email_address IS NULL THEN

           x_mail_add := 'No_Email_Addr';

        ELSE

           WHILE (lcu_email%FOUND)
           LOOP
              x_mail_add := x_mail_add||','||email_rec.email_address;
              FETCH lcu_email INTO email_rec;
           END LOOP;

           x_mail_add := substr(x_mail_add,2,length(x_mail_add));

        END IF;

        CLOSE lcu_email;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            x_mail_add := 'No_Email_Addr';
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                    p_program_type            => 'CONCURRENT PROGRAM'
                   ,p_program_name            => 'OD: AR Customer Document Delivery Method'
                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                   ,p_module_name             => 'AR'
                   ,p_error_location          => 'Error at XX_AR_GET_DELIVERY_EMAIL procedure for Site Use ID '||p_site_use_id
                   ,p_error_message_count     => 1
                   ,p_error_message_code      => 'E'
                   ,p_error_message           => 'There is no email Address found for Site Use ID '||p_site_use_id
                   ,p_error_message_severity  => 'Major'
                   ,p_notify_flag             => 'N'
                   ,p_object_type             => ''
        );

        WHEN OTHERS THEN
            x_mail_add := 'Email_Addr_Err';
            DBMS_OUTPUT.PUT_LINE(SQLERRM);
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                    p_program_type            => 'CONCURRENT PROGRAM'
                   ,p_program_name            => 'OD: AR Customer Document Delivery Method'
                   ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                   ,p_module_name             => 'AR'
                   ,p_error_location          => 'Error at XX_AR_GET_DELIVERY_EMAIL procedure for Site Use ID '||p_site_use_id
                   ,p_error_message_count     => 1
                   ,p_error_message_code      => 'E'
                   ,p_error_message           => SQLERRM
                   ,p_error_message_severity  => 'Major'
                   ,p_notify_flag             => 'N'
                   ,p_object_type             => ''
            );
    END;

   lc_concat := '~'||x_mail_add||'~';
   DBMS_OUTPUT.PUT_LINE(lc_concat);

END XX_AR_GET_DELIVERY_EMAIL;
/

SHOW ERROR