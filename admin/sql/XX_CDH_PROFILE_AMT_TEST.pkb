create or replace
PACKAGE BODY XX_CDH_PROFILE_AMT_TEST AS


  procedure proc_main 
  (
  x_errbuf OUT VARCHAR2,
  x_retcode OUT VARCHAR2,
  p_cust_account_id IN NUMBER,
  p_site_use_id in number :=null,
  p_profile_class_id in number := 0,
  p_create_amt IN VARCHAR2:= 'T'
  )
  
  AS
  
cust_prof_rec_type HZ_CUSTOMER_PROFILE_V2PUB.customer_profile_rec_type;

ln_cust_prof_id NUMBER;
lc_prof_return_status VARCHAR2(10);
lc_msg_data VARCHAR2(4000);
ln_msg_count NUMBER;


  
  BEGIN
  
  
  cust_prof_rec_type := NULL;

cust_prof_rec_type.cust_account_id := p_cust_account_id;
cust_prof_rec_type.site_use_id := p_site_use_id;
cust_prof_rec_type.profile_class_id := p_profile_class_id;
cust_prof_rec_type.created_by_module := 'TCA_API';


hz_customer_profile_v2pub.create_customer_profile
            (
                p_init_msg_list              => FND_API.G_TRUE,
                p_customer_profile_rec       => cust_prof_rec_type,
                p_create_profile_amt         => p_create_amt,
                x_cust_account_profile_id    => ln_cust_prof_id,
                x_return_status              => lc_prof_return_status,
                x_msg_count                  => ln_msg_count,
                x_msg_data                   => lc_msg_data
           );


IF lc_prof_return_status <> FND_API.G_RET_STS_SUCCESS 
THEN


 IF (ln_msg_count>0) THEN
                      lc_msg_data:=NULL;
                      FOR counter IN 1 .. ln_msg_count
                      LOOP
                      lc_msg_data := lc_msg_data || ' ' || fnd_msg_pub.GET(counter,   fnd_api.g_false);
                      END LOOP;                    
 END IF;
 
 fnd_msg_pub.DELETE_MSG;


--dbms_output.put_line('Error:'||lc_msg_data);
fnd_file.put_line(fnd_file.log,'Error: '|| lc_msg_data);

ELSE

--x_profile_id := ln_cust_prof_id;
--dbms_output.put_line('Success: Relationship_id='||ln_cust_prof_id);
fnd_file.put_line(fnd_file.log, 'Sucess, Profile_ID: '||ln_cust_prof_id);

END IF;

COMMIT;

EXCEPTION
WHEN OTHERS THEN
x_retcode:=0;
ROLLBACK;
  
  END proc_main;

END XX_CDH_PROFILE_AMT_TEST;
/