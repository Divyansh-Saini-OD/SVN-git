CREATE OR REPLACE
PACKAGE  BODY  XX_CDH_AOPS_SYNCH_DET_PKG
AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  XX_CDH_AOPS_SYNCH_DET_PKG.pkb                                       |
-- | Description :  This Package gives the reocrd count details those were synchronized |
-- |                for the given period and user.                                      |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  26-Sep-2008 Kathirvel          Initial draft version                      |
-- +=====================================================================================+

PROCEDURE SYNCH_COUNT_MAIN(
                                            x_errbuf		OUT NOCOPY    VARCHAR2
                                          , x_retcode		OUT NOCOPY    VARCHAR2
                                          , p_from_date         IN            VARCHAR2
					  , p_to_date           IN            VARCHAR2
					  , p_user_name         IN            VARCHAR2
                                          , p_entity_level      IN            VARCHAR2
                                          )  
                                          
 IS
     
   l_user_id       NUMBER;
   l_group_id      NUMBER;
   l_from_date     DATE;
   l_to_date       DATE;
   l_create   NUMBER;
   l_update   NUMBER;

   l_error_messege VARCHAR2(2000);

    CURSOR attr_group_cur IS
    SELECT attr_group_id
    FROM   ego_fnd_dsc_flx_ctx_ext
    WHERE  descriptive_flexfield_name = 'XX_CDH_CUST_ACCOUNT'
    AND descriptive_flex_context_code = 'SPC_INFO';

   INPUT_FAIL        EXCEPTION;
 BEGIN
    

    IF p_user_name IS NULL
    THEN
        l_error_messege   :=  'User name can not be empty to get this report';
        RAISE INPUT_FAIL;
    END IF;

    l_user_id := get_user_name(p_user_name);

    IF l_user_id = 0
    THEN
        l_error_messege   :=  'The User name does not exist. Please enter valid user name';
        RAISE INPUT_FAIL;
    END IF;

    IF p_from_date IS NULL OR
       p_to_date   IS NULL
    THEN
        l_error_messege   :=  'From Date and To Date can not be empty';
        RAISE INPUT_FAIL;
    END IF;


dbms_output.put_line ('p_from_date '||p_from_date);
dbms_output.put_line ('p_to_date '||p_to_date);

    BEGIN
         l_from_date  := to_date(p_from_date,'mm/dd/yyyy hh24:mi:ss');
         l_to_date    := to_date(p_to_date,'mm/dd/yyyy hh24:mi:ss');
    EXCEPTION
      WHEN OTHERS
      THEN
        l_error_messege   :=  'Please enter the Date in valid format of mm/dd/yyyy hh24:mi:ss';
        RAISE INPUT_FAIL;
    END;


   fnd_file.put_line (fnd_file.output,chr(9));
   fnd_file.put_line (fnd_file.output,chr(9));
   fnd_file.put_line (fnd_file.output,'                  Office DEPOT ');
   fnd_file.put_line (fnd_file.output,'                  ============= ');
   fnd_file.put_line (fnd_file.output,'         Data Creation/Updation Count Details');
   fnd_file.put_line (fnd_file.output,'         From Date : '|| p_from_date|| '  To Date : '||p_to_date);
   fnd_file.put_line (fnd_file.output,'         By the user :'||p_user_name);

   fnd_file.put_line (fnd_file.output,chr(9));

   fnd_file.put_line (fnd_file.output,'---------------------------------------------------------------------------------');


   IF p_entity_level = 'ACCOUNTS' or p_entity_level = 'ALL'
   THEN
       l_create   := get_account_create_count(l_user_id,l_from_date,l_to_date);
       l_update   := get_account_update_count(l_user_id,l_from_date,l_to_date);

       fnd_file.put_line (fnd_file.output,'Accounts Created      :'||l_create);
       fnd_file.put_line (fnd_file.output,'Accounts Updated      :'||l_update);

       fnd_file.put_line (fnd_file.output,chr(9));
       fnd_file.put_line (fnd_file.output,chr(9));

   END IF;

   IF p_entity_level = 'ACCOUNT_SITES' or p_entity_level = 'ALL'
   THEN
       l_create   := get_site_create_count(l_user_id,l_from_date,l_to_date);
       l_update   := get_site_update_count(l_user_id,l_from_date,l_to_date);

       fnd_file.put_line (fnd_file.output,'Account Sites Created :'||l_create);
       fnd_file.put_line (fnd_file.output,'Account Sites Updated :'||l_update);

       fnd_file.put_line (fnd_file.output,chr(9));
       fnd_file.put_line (fnd_file.output,chr(9));

   END IF;

   IF p_entity_level = 'ORG_CONTACTS' or p_entity_level = 'ALL'
   THEN
       l_create   := get_org_contact_create_count(l_user_id,l_from_date,l_to_date);
       l_update   := get_org_contact_update_count(l_user_id,l_from_date,l_to_date);

       fnd_file.put_line (fnd_file.output,'Org Contacts Created  :'||l_create);
       fnd_file.put_line (fnd_file.output,'Org Contacts Updated  :'||l_update);

       fnd_file.put_line (fnd_file.output,chr(9));
       fnd_file.put_line (fnd_file.output,chr(9));

   END IF;

   IF p_entity_level = 'CONTACT_POINTS' or p_entity_level = 'ALL'
   THEN
       l_create   := get_contact_point_create_count(l_user_id,l_from_date,l_to_date);
       l_update   := get_contact_point_update_count(l_user_id,l_from_date,l_to_date);

       fnd_file.put_line (fnd_file.output,'Contact Points Created:'||l_create);
       fnd_file.put_line (fnd_file.output,'Contact Points Updated:'||l_update);

       fnd_file.put_line (fnd_file.output,chr(9));
       fnd_file.put_line (fnd_file.output,chr(9));

   END IF;

   IF p_entity_level = 'WEB_USERS' or p_entity_level = 'ALL'
   THEN
       l_create   := get_web_user_create_count(l_user_id,l_from_date,l_to_date);
       l_update   := get_web_user_update_count(l_user_id,l_from_date,l_to_date);

       fnd_file.put_line (fnd_file.output,'Web Users Created     :'||l_create);
       fnd_file.put_line (fnd_file.output,'Web Users Updated     :'||l_update);

       fnd_file.put_line (fnd_file.output,chr(9));
       fnd_file.put_line (fnd_file.output,chr(9));

   END IF;

   IF p_entity_level = 'SPC_INFO' or p_entity_level = 'ALL'
   THEN

       OPEN  attr_group_cur;
       FETCH attr_group_cur INTO l_group_id;
       CLOSE attr_group_cur;

       l_create   := get_spc_create_count(l_user_id,l_from_date,l_to_date,l_group_id);
       l_update   := get_spc_update_count(l_user_id,l_from_date,l_to_date,l_group_id);

       fnd_file.put_line (fnd_file.output,'SPC Card Created      :'||l_create);
       fnd_file.put_line (fnd_file.output,'SPC Card Updated      :'||l_update);

       fnd_file.put_line (fnd_file.output,chr(9));
       fnd_file.put_line (fnd_file.output,chr(9));

   END IF;


   EXCEPTION 
     WHEN INPUT_FAIL THEN
	fnd_file.put_line (fnd_file.log,l_error_messege);
	x_errbuf  := l_error_messege;
	x_retcode := 2;    
     WHEN OTHERS THEN
	fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - SYNCH_COUNT_MAIN : ' || SQLERRM);
	x_errbuf  := 'UnExpected Error Occured In the Procedure - SYNCH_COUNT_MAIN : ' || SQLERRM;
	x_retcode := 2;      
END SYNCH_COUNT_MAIN;

FUNCTION get_user_name(p_user_name IN VARCHAR2) RETURN NUMBER
IS
   CURSOR cur_user IS
   SELECT /* parallel (a,8) */
          a.user_id
   FROM   fnd_user a
   WHERE  user_name  = p_user_name;

   l_user_id      NUMBER;

BEGIN
     OPEN  cur_user;
     FETCH cur_user INTO l_user_id;
     CLOSE cur_user;
     
     RETURN (NVL(l_user_id,0));
END;


FUNCTION get_account_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_create(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   hz_cust_accounts a
   WHERE  a.creation_date BETWEEN cur_from_date AND cur_to_date
   AND    a.created_by = cur_user_id;

   l_create  NUMBER;

BEGIN

     OPEN  cur_create(p_user_id, p_form_date,p_to_date);
     FETCH cur_create INTO l_create;
     CLOSE cur_create;
    
     RETURN (NVL(l_create,0));

END;

FUNCTION get_account_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_update(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   hz_cust_accounts a
   WHERE  a.last_update_date BETWEEN cur_from_date AND cur_to_date
   AND    a.creation_date <> a.last_update_date
   AND    a.last_updated_by = cur_user_id;

   l_update  NUMBER;

BEGIN

     OPEN  cur_update(p_user_id, p_form_date,p_to_date);
     FETCH cur_update INTO l_update;
     CLOSE cur_update;
    
     RETURN (NVL(l_update,0));

END;


FUNCTION get_site_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_create(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   hz_cust_acct_sites_all  a
   WHERE  a.creation_date BETWEEN cur_from_date AND cur_to_date
   AND    a.created_by = cur_user_id;

   l_create  NUMBER;

BEGIN

     OPEN  cur_create(p_user_id, p_form_date,p_to_date);
     FETCH cur_create INTO l_create;
     CLOSE cur_create;
    
     RETURN (NVL(l_create,0));

END;

FUNCTION get_site_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_update(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   hz_cust_acct_sites_all a
   WHERE  a.last_update_date BETWEEN cur_from_date AND cur_to_date
   AND    a.creation_date <> a.last_update_date
   AND    a.last_updated_by = cur_user_id;

   l_update  NUMBER;

BEGIN

     OPEN  cur_update(p_user_id, p_form_date,p_to_date);
     FETCH cur_update INTO l_update;
     CLOSE cur_update;
    
     RETURN (NVL(l_update,0));

END;

FUNCTION get_org_contact_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_create(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   hz_org_contacts a
   WHERE  a.creation_date BETWEEN cur_from_date AND cur_to_date
   AND    a.created_by = cur_user_id;

   l_create  NUMBER;

BEGIN

     OPEN  cur_create(p_user_id, p_form_date,p_to_date);
     FETCH cur_create INTO l_create;
     CLOSE cur_create;
    
     RETURN (NVL(l_create,0));

END;

FUNCTION get_org_contact_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_update(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   hz_org_contacts a
   WHERE  a.last_update_date BETWEEN cur_from_date AND cur_to_date
   AND    a.creation_date <> a.last_update_date
   AND    a.last_updated_by = cur_user_id;

   l_update  NUMBER;

BEGIN

     OPEN  cur_update(p_user_id, p_form_date,p_to_date);
     FETCH cur_update INTO l_update;
     CLOSE cur_update;
    
     RETURN (NVL(l_update,0));

END;

FUNCTION get_contact_point_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_create(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   hz_contact_points a
   WHERE  a.creation_date BETWEEN cur_from_date AND cur_to_date
   AND    a.created_by = cur_user_id;

   l_create  NUMBER;

BEGIN

     OPEN  cur_create(p_user_id, p_form_date,p_to_date);
     FETCH cur_create INTO l_create;
     CLOSE cur_create;
    
     RETURN (NVL(l_create,0));

END;

FUNCTION get_contact_point_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_update(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   hz_contact_points a
   WHERE  a.last_update_date BETWEEN cur_from_date AND cur_to_date
   AND    a.creation_date <> a.last_update_date
   AND    a.last_updated_by = cur_user_id;

   l_update  NUMBER;

BEGIN

     OPEN  cur_update(p_user_id, p_form_date,p_to_date);
     FETCH cur_update INTO l_update;
     CLOSE cur_update;
    
     RETURN (NVL(l_update,0));

END;

FUNCTION get_web_user_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_create(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   xx_external_users a
   WHERE  a.creation_date BETWEEN cur_from_date AND cur_to_date
   AND    a.created_by = cur_user_id;

   l_create  NUMBER;

BEGIN

     OPEN  cur_create(p_user_id, p_form_date,p_to_date);
     FETCH cur_create INTO l_create;
     CLOSE cur_create;
    
     RETURN (NVL(l_create,0));

END;

FUNCTION get_web_user_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE) RETURN NUMBER
IS
   CURSOR cur_update(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   xx_external_users a
   WHERE  a.last_update_date BETWEEN cur_from_date AND cur_to_date
   AND    a.creation_date <> a.last_update_date
   AND    a.last_updated_by = cur_user_id;

   l_update  NUMBER;

BEGIN

     OPEN  cur_update(p_user_id, p_form_date,p_to_date);
     FETCH cur_update INTO l_update;
     CLOSE cur_update;
    
     RETURN (NVL(l_update,0));

END;

FUNCTION get_spc_create_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE
				  ,p_group_id  IN NUMBER) RETURN NUMBER
IS
   CURSOR cur_create(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE,cur_group_id NUMBER) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM   XX_CDH_CUST_ACCT_EXT_B  a
   WHERE  attr_group_id = cur_group_id 
   AND    a.creation_date BETWEEN cur_from_date AND cur_to_date
   AND    a.created_by = cur_user_id;

   l_create  NUMBER;

BEGIN

     OPEN  cur_create(p_user_id, p_form_date,p_to_date,p_group_id);
     FETCH cur_create INTO l_create;
     CLOSE cur_create;
    
     RETURN (NVL(l_create,0));

END;

FUNCTION get_spc_update_count (p_user_id   IN NUMBER
                                  ,p_form_date IN DATE
				  ,p_to_date   IN DATE
				  ,p_group_id  IN NUMBER) RETURN NUMBER
IS
   CURSOR cur_update(cur_user_id NUMBER, cur_from_date DATE, cur_to_date DATE,cur_group_id NUMBER) IS
   SELECT /* parallel (a,8) */
   COUNT(1)
   FROM  XX_CDH_CUST_ACCT_EXT_B  a
   WHERE  attr_group_id = cur_group_id 
   AND    a.last_update_date BETWEEN cur_from_date AND cur_to_date
   AND    a.creation_date <> a.last_update_date
   AND    a.last_updated_by = cur_user_id;

   l_update  NUMBER;

BEGIN

     OPEN  cur_update(p_user_id, p_form_date,p_to_date,p_group_id);
     FETCH cur_update INTO l_update;
     CLOSE cur_update;
    
     RETURN (NVL(l_update,0));

END;

END XX_CDH_AOPS_SYNCH_DET_PKG;
/