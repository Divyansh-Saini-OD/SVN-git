create or replace
package body XX_CDH_BPEL_PROFILE_SYNC_PKG AS
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  XX_CDH_BPEL_PROFILE_SYNC_PKG.pkb                                    |
-- | Description :  Maintain profile at account level and Account Site                  |
-- |                Use (Bill To) level based on the payment term                       |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===========================================|
-- |DRAFT 1a  26-Jun-2008 Kathirvel          Initial draft version                      |
-- |1.1       28-Jul-2008 Kathirvel          Changes made to apply the payment term     |
-- |                                         on site level which is applied for Accounts|
-- |                                         and validated the payment term ID          |
-- |1.2       03-Sep-2008 Kathirvel          Since BO API does not create               |
-- |                                         profile amount by default,                 |
-- |                                         this API is made to support                |
-- |                                         for BPEL invokation.                       |
-- +=====================================================================================+

-- +========================================================================+
-- | Name        :  Process_Profile_Main                                   |
-- | Description :  Process the inputs to create Profile at Account and    |
-- |                Account Site Use level                                 |
-- +========================================================================+

PROCEDURE Process_Profile_Main (
p_orig_system                          IN VARCHAR2,
p_account_OSR                          IN VARCHAR2,
p_site_use_OSR                         IN VARCHAR2,
p_currency_code                        IN VARCHAR2,
p_profile_cls_name                     IN VARCHAR2,
p_status                               IN VARCHAR2,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2) IS

l_acct_prf_id              NUMBER;
l_site_use_prf_id          NUMBER;
l_cust_acct_id             NUMBER;
l_site_use_id              NUMBER;
l_status                   VARCHAR2(1);
l_term                     VARCHAR2(100);
l_term_id                  NUMBER;
l_ori_term_id              NUMBER;
l_acct_prf_term_id         NUMBER;
l_prf_class_id             NUMBER;
l_acct_prf_class_id        NUMBER;
l_prof_rec                 hz_customer_profile_v2pub.customer_profile_rec_type;
l_return_status 		   VARCHAR2(1);
l_error_message            VARCHAR2(2000);
l_object_number            NUMBER;
FUNCTIONAL_ERROR           EXCEPTION;
END_PROGRAME               EXCEPTION;

    
    CURSOR l_cust_acct_cur IS
    select cac.cust_account_id 
    from   hz_orig_sys_references osr, hz_cust_accounts cac
    where  osr.orig_system_reference = p_account_OSR  
    and    osr.owner_table_name = 'HZ_CUST_ACCOUNTS'  
    and    osr.orig_system      = p_orig_system
    and    osr.owner_table_id   = cac.cust_account_id                          
    and    osr.status = 'A';                      


    CURSOR l_acct_prf_cur IS
    select cpr.cust_account_profile_id,
           cpr.object_version_number,
           cpr.status,
           cpr.profile_class_id,
           cpr.standard_terms,    
           tem.name
    from  hz_customer_profiles cpr,
          ra_terms tem
    where cpr.cust_account_id   = l_cust_acct_id
    and   cpr.site_use_id is null
    and   cpr.standard_terms    = tem.term_id;


    CURSOR l_site_use_prf_cur IS
    select cpr.cust_account_profile_id,
           cpr.object_version_number,
           cpr.status
    from  hz_customer_profiles cpr
    where cpr.cust_account_id    = l_cust_acct_id
    and   cpr.site_use_id is not null;


    CURSOR l_prf_class_cur IS
    select profile_class_id,standard_terms 
    from   hz_cust_profile_classes 
    where  name   = p_profile_cls_name
    and    status = 'A';

    CURSOR l_acct_site_use_cur IS
    select sua.site_use_id 
    from   hz_orig_sys_references osr,hz_cust_site_uses_all sua
    where  osr.orig_system_reference = p_site_use_OSR
    and    osr.owner_table_name = 'HZ_CUST_SITE_USES_ALL'  
    and    osr.orig_system      = p_orig_system
    and    osr.owner_table_id   = sua.site_use_id 
    and    osr.status = 'A';  

   CURSOR l_payment_term_cur(term_id_rec NUMBER) IS
   select term_id 
   from   ra_terms
   where  term_id  = term_id_rec
   and    NVL(end_date_active,sysdate) >= sysdate;

BEGIN

  SAVEPOINT Process_Profile_Main;

    x_return_status 	:= 'S';


---------------------------------------
-- Check whether the Account exists for the given OSR. 
-- If does not exist, riase an error to stop the process
---------------------------------------

     OPEN  l_cust_acct_cur ;
     FETCH l_cust_acct_cur INTO  l_cust_acct_id;
     CLOSE l_cust_acct_cur ; 

     IF  l_cust_acct_id IS NULL
     THEN
          l_error_message  := 'There is no Customer Account for the OSR '||p_account_OSR;
          l_return_status  := 'E';
          RAISE FUNCTIONAL_ERROR;
     END IF;

---------------------------------------
-- Check whether the Profile Class exists for given class Name. 
-- If does not exist, riase an error to stop the process
---------------------------------------

     OPEN  l_prf_class_cur ;
     FETCH l_prf_class_cur INTO  l_prf_class_id,l_term_id;
     CLOSE l_prf_class_cur ;

     IF l_prf_class_id IS NULL
     THEN
          l_error_message  := 'There is no Profile Class for the name '||p_profile_cls_name;
          l_return_status  := 'E';
          RAISE FUNCTIONAL_ERROR;
     END IF;

---------------------------------------
-- Get the Account level profile details. 
---------------------------------------
    
     OPEN  l_acct_prf_cur;
     FETCH l_acct_prf_cur  INTO  l_acct_prf_id,l_object_number,l_status,l_acct_prf_class_id,l_acct_prf_term_id,l_term;
     CLOSE l_acct_prf_cur;  
 

     IF l_acct_prf_id IS NULL 
     THEN
          l_prof_rec.cust_account_id        := l_cust_acct_id;
          l_prof_rec.standard_terms         := l_term_id;
          l_prof_rec.profile_class_id       := l_prf_class_id;    
          l_prof_rec.created_by_module      := 'BO_API';
          l_prof_rec.status                 := NVL(p_status,'A'); 

     	  OPEN  l_payment_term_cur(l_term_id);
          FETCH l_payment_term_cur INTO  l_ori_term_id;
          CLOSE l_payment_term_cur;  

         IF l_ori_term_id IS NULL
         THEN
             l_error_message  := 'There is no Active Payment Term for the ID '||l_term_id;
             l_return_status  := 'E';
             RAISE FUNCTIONAL_ERROR;
         END IF;                          

---------------------------------------
-- If Account level profile does not exist, 
-- Call the child procedure Create_Profile_Details 
---------------------------------------

              Create_Profile_Details (
                 p_profile_rec       => l_prof_rec,
                 p_currency_code     => NULL,                      
                 x_return_status     => l_return_status,
                 x_error_message     => l_error_message    
                    );

             IF l_return_status <> 'S'
             THEN
                  RAISE FUNCTIONAL_ERROR;
             END IF;

     ELSIF  l_acct_prf_id IS NOT NULL 
           or NVL(p_status,'A') <> NVL(l_status,'X')
     THEN
             l_prof_rec.cust_account_profile_id   := l_acct_prf_id; 
             l_prof_rec.profile_class_id          := l_acct_prf_class_id;
             l_prof_rec.cust_account_id           := l_cust_acct_id;
             l_prof_rec.status                    := p_status;

---------------------------------------
-- If Account level profile exists but the existing status and required status is different, 
-- Call the child procedure Update_Profile_Details
---------------------------------------       

              Update_Profile_Details (
                 p_profile_rec       => l_prof_rec,
                 p_currency_code     => p_currency_code,                                       
                 p_object_version    => l_object_number,                      
                 x_return_status     => l_return_status,
                 x_error_message     => l_error_message    
                    );

             IF l_return_status <> 'S'
             THEN
                  RAISE FUNCTIONAL_ERROR;
             END IF;
     END IF;

---------------------------------------
-- If the existing payment term is not IMMEDIATE or 
-- there is no profile exists but input profile class is 'Low Risk',
-- process the profile creation/updation of Site use level
---------------------------------------       


     IF (l_acct_prf_id IS NOT NULL AND
        l_term != 'IMMEDIATE') or (l_acct_prf_id IS NULL and p_profile_cls_name = 'Low Risk')
     THEN

         l_acct_prf_id     := NULL; 
         l_object_number   := NULL; 
         l_status          := NULL; 
         l_prof_rec        := NULL;

---------------------------------------
-- Get the Site Use level profile details
---------------------------------------       

         OPEN  l_site_use_prf_cur;
         FETCH l_site_use_prf_cur INTO  l_site_use_prf_id,l_object_number,l_status;
         CLOSE l_site_use_prf_cur; 
 
---------------------------------------
-- If Site Use level profile does not exist, 
-- Get the site details and Call the child procedure Create_Profile_Details 
---------------------------------------

              OPEN  l_acct_site_use_cur ;
              FETCH l_acct_site_use_cur INTO  l_site_use_id;
              CLOSE l_acct_site_use_cur ; 

              IF l_site_use_id IS NULL
              THEN
                  l_error_message  := 'There is no Account Site Uses for the OSR '||p_site_use_OSR;
                  l_return_status  := 'E';
                  RAISE FUNCTIONAL_ERROR;
              END IF;
        
         IF l_site_use_prf_id IS NULL 
         THEN


     	      OPEN  l_payment_term_cur (NVL(l_acct_prf_term_id,l_term_id));
              FETCH l_payment_term_cur INTO  l_ori_term_id;
              CLOSE l_payment_term_cur;  

              IF l_ori_term_id IS NULL
              THEN
                  l_error_message  := 'There is no Active Payment Term for the ID '||NVL(l_acct_prf_term_id,l_term_id);
                  l_return_status  := 'E';
                  RAISE FUNCTIONAL_ERROR;
              END IF;                          


              l_prof_rec.cust_account_id        := l_cust_acct_id;  
              l_prof_rec.profile_class_id       := NVL(l_acct_prf_class_id,l_prf_class_id);       
              l_prof_rec.standard_terms         := NVL(l_acct_prf_term_id,l_term_id);
              l_prof_rec.created_by_module      := 'BO_API';
              l_prof_rec.status                 := NVL(p_status,'A');                               
              l_prof_rec.site_use_id            := l_site_use_id; 
                             

              Create_Profile_Details (
                 p_profile_rec       => l_prof_rec,
                 p_currency_code     => p_currency_code,                      
                 x_return_status 	 => l_return_status,
                 x_error_message     => l_error_message    
                    );

              IF l_return_status <> 'S'
              THEN
                  RAISE FUNCTIONAL_ERROR;
              END IF;

         ELSIF  l_site_use_prf_id IS NOT NULL 
                OR NVL(p_status,'A') <> nvl(l_status,'X')
         THEN
---------------------------------------
-- If Site Use level profile exists but the existing status and required status is different, 
-- Call the child procedure Update_Profile_Details
---------------------------------------  

             l_prof_rec.cust_account_profile_id   := l_site_use_prf_id; 
             l_prof_rec.profile_class_id          := l_acct_prf_class_id;
             l_prof_rec.cust_account_id           := l_cust_acct_id;
             l_prof_rec.site_use_id               := l_site_use_id;
             l_prof_rec.status                    := NVL(p_status,'A');

              Update_Profile_Details (
                 p_profile_rec       => l_prof_rec,
                 p_currency_code     => p_currency_code,                                       
                 p_object_version    => l_object_number,                      
                 x_return_status 	 => l_return_status,
                 x_error_message     => l_error_message    
                    );

             IF l_return_status <> 'S'
             THEN
                  RAISE FUNCTIONAL_ERROR;
             END IF;

         END IF;
     END IF;
EXCEPTION
   WHEN FUNCTIONAL_ERROR 
   THEN
      ROLLBACK TO Process_Profile_Main;
      x_return_status := NVL(l_return_status,'E');
      x_error_message := l_error_message; 

   WHEN OTHERS 
   THEN
      ROLLBACK TO Process_Profile_Main;
      x_return_status := 'E';
      x_error_message := SQLERRM; 
END Process_Profile_Main;


-- +===========================================================================+
-- | Name        :  Create_Profile_Details                                    |
-- | Description :  Creates the profile at Account and Site Use level based on| 
-- |                the payment term or profile class name                    |
-- +===========================================================================+

PROCEDURE Create_Profile_Details(
p_profile_rec                          IN  hz_customer_profile_v2pub.customer_profile_rec_type,
p_currency_code                        IN  VARCHAR2,
x_return_status 		       OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2)
IS

    l_return_status            varchar2(1)     := null;
    l_msg_count                number          := 0;
    l_msg_data                 varchar2(2000)  := null;
    l_cust_account_profile_id  number          := 0;
    l_account_profile_amt_id   number          := 0;
    
    l_prof_amt_rec             hz_customer_profile_v2pub.cust_profile_amt_rec_type;

    CURSOR l_prf_amt_cur IS
    select cust_acct_profile_amt_id
    from   hz_cust_profile_amts
    where  cust_account_profile_id = l_cust_account_profile_id  
    and    currency_code        = p_currency_code;                                       

BEGIN


x_return_status     := 'S';

---------------------------------------
-- Call the standard API HZ_CUSTOMER_PROFILE_V2PUB.create_customer_profile
-- to create profile at Account/ Site Use level
---------------------------------------  

              HZ_CUSTOMER_PROFILE_V2PUB.create_customer_profile (
               p_init_msg_list                      => 'F',
               p_customer_profile_rec               => p_profile_rec,
               x_cust_account_profile_id            => l_cust_account_profile_id,
               x_return_status                      => l_return_status,
               x_msg_count                          => l_msg_count,
               x_msg_data                           => l_msg_data
              );


           IF l_return_status <> 'S'
           THEN
              x_return_status  := l_return_status;
              if l_msg_count > 0 THEN  
                  FOR I IN 1..l_msg_count
                  LOOP
                     l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                  END LOOP;
              end if;
              x_error_message := l_msg_data;
              RETURN;
          END IF;

---------------------------------------
-- AS per the CDH setup, the standard API HZ_CUSTOMER_PROFILE_V2PUB.create_customer_profile
-- creates profiles and profile amount(currency) as well.
-- Suppose the CDH setup is missing or not working, we can manullay create the 
-- currency in the profile amount table  
---------------------------------------  
---------------------------------------
-- Get the existing profile amount details. 
---------------------------------------  

         OPEN  l_prf_amt_cur ;
         FETCH l_prf_amt_cur INTO  l_account_profile_amt_id;
         CLOSE l_prf_amt_cur ; 

          IF     p_currency_code IS NOT NULL 
             and nvl(l_account_profile_amt_id,0) = 0
             and p_profile_rec.site_use_id > 0
          THEN


               l_prof_amt_rec.cust_account_profile_id   := l_cust_account_profile_id;
               l_prof_amt_rec.currency_code             := p_currency_code;
               l_prof_amt_rec.cust_account_id           := p_profile_rec.cust_account_id;
               l_prof_amt_rec.site_use_id               := p_profile_rec.site_use_id;
               l_prof_amt_rec.created_by_module         := 'BO_API';

---------------------------------------
-- If profile amount does not exist,
-- call the standard API HZ_CUSTOMER_PROFILE_V2PUB.create_cust_profile_amt
-- to create a required currency in the profile amount table  
---------------------------------------  

               HZ_CUSTOMER_PROFILE_V2PUB.create_cust_profile_amt (
    			p_init_msg_list                         => 'F',
                  p_check_foreign_key                     => FND_API.G_TRUE,
                  p_cust_profile_amt_rec                  => l_prof_amt_rec,
                  x_cust_acct_profile_amt_id              => l_account_profile_amt_id,
                  x_return_status                         => l_return_status,
                  x_msg_count                             => l_msg_count,
                  x_msg_data                              => l_msg_data
                 );

                 IF l_return_status <> 'S'
                 THEN
                     x_return_status  := l_return_status;
                     if l_msg_count > 0 THEN  
                        FOR I IN 1..l_msg_count
                        LOOP
                            l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                        END LOOP;
                     end if;
                END IF;
                x_error_message := l_msg_data;
          END IF;
  
  EXCEPTION
      WHEN OTHERS 
      THEN
           x_return_status := 'E';
           x_error_message := SQLERRM; 
 
  END Create_Profile_Details;

-- +================================================================================+
-- | Name        :  Update_Profile_Details                                         |
-- | Description :  Updates the existing profile for Activate or Inactivate purpose|
-- +================================================================================+

PROCEDURE Update_Profile_Details(
p_profile_rec                          IN  hz_customer_profile_v2pub.customer_profile_rec_type,
p_currency_code                        IN  VARCHAR2,                                       
p_object_version                       IN  NUMBER,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2)
IS

    l_return_status            varchar2(1)     := null;
    l_msg_count                number          := 0;
    l_msg_data                 varchar2(2000)  := null;
    l_object_version           number          := p_object_version;
    l_cust_account_profile_id  number;
    l_profile_class_id         number;
    l_account_profile_amt_id   number;
    l_trx_credit_limit         number;
    
    l_prof_amt_rec             hz_customer_profile_v2pub.cust_profile_amt_rec_type;                                     

    CURSOR l_prf_class_amt_cur is
    select *
    from   HZ_CUST_PROF_CLASS_AMTS
    where  profile_class_id = l_profile_class_id;

    CURSOR l_prf_amt_cur(cur_currency_code VARCHAR2) IS
    select cust_acct_profile_amt_id,trx_credit_limit
    from   hz_cust_profile_amts
    where  cust_account_profile_id = l_cust_account_profile_id
    and    currency_code           = cur_currency_code;  


BEGIN

x_return_status     := 'S';

l_cust_account_profile_id  :=  p_profile_rec.cust_account_profile_id;
l_profile_class_id         :=  p_profile_rec.profile_class_id;

/*
---------------------------------------
-- Call the standard API HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile 
-- to update the existing profile for status changes
---------------------------------------  

              HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile (
               p_init_msg_list                      => 'T',
               p_customer_profile_rec               => p_profile_rec,
               p_object_version_number              => l_object_version,
               x_return_status                      => l_return_status,
               x_msg_count                          => l_msg_count,
               x_msg_data                           => l_msg_data
              );


           IF l_return_status <> 'S'
           THEN
              x_return_status  := l_return_status;
              if l_msg_count > 0 THEN  
                  FOR I IN 1..l_msg_count
                  LOOP
                     l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                  END LOOP;
              end if;
              x_error_message := l_msg_data;
          END IF;

*/
---------------------------------------
-- Get the existing profile amount details. 
---------------------------------------  

               FOR I IN l_prf_class_amt_cur
               LOOP

                        l_account_profile_amt_id := 0;

         		OPEN  l_prf_amt_cur(I.currency_code) ;
         		FETCH l_prf_amt_cur INTO  l_account_profile_amt_id,l_trx_credit_limit;
         		CLOSE l_prf_amt_cur ; 


          		IF  nvl(l_account_profile_amt_id,0) = 0 
          		THEN
				l_prof_amt_rec.cust_account_profile_id   := l_cust_account_profile_id;
				l_prof_amt_rec.currency_code             := I.currency_code;
				l_prof_amt_rec.cust_account_id           := p_profile_rec.cust_account_id;
				l_prof_amt_rec.site_use_id               := p_profile_rec.site_use_id;
				l_prof_amt_rec.created_by_module         := 'BO_API';
				l_prof_amt_rec.trx_credit_limit          := I.trx_credit_limit;
				l_prof_amt_rec.overall_credit_limit      := I.overall_credit_limit; 
				l_prof_amt_rec.min_dunning_amount        := I.min_dunning_amount;
				l_prof_amt_rec.min_dunning_invoice_amount:= I.min_dunning_invoice_amount; 
				l_prof_amt_rec.max_interest_charge       := I.max_interest_charge;
				l_prof_amt_rec.min_statement_amount      := I.min_statement_amount;
				l_prof_amt_rec.auto_rec_min_receipt_amount:= I.auto_rec_min_receipt_amount;
				l_prof_amt_rec.interest_rate             := I.interest_rate;
				l_prof_amt_rec.min_fc_balance_amount     := I.min_fc_balance_amount;
				l_prof_amt_rec.min_fc_invoice_amount     := I.min_fc_invoice_amount;
	---------------------------------------
	-- If profile amount does not exist,
	-- call the standard API HZ_CUSTOMER_PROFILE_V2PUB.create_cust_profile_amt
	-- to create a required currency in the profile amount table  
	---------------------------------------  


			       HZ_CUSTOMER_PROFILE_V2PUB.create_cust_profile_amt (
				  p_init_msg_list                         => 'F',
				  p_check_foreign_key                     => FND_API.G_TRUE,
				  p_cust_profile_amt_rec                  => l_prof_amt_rec,
				  x_cust_acct_profile_amt_id              => l_account_profile_amt_id,
				  x_return_status                         => l_return_status,
				  x_msg_count                             => l_msg_count,
				  x_msg_data                              => l_msg_data
				 );

				 IF l_return_status <> 'S'
				 THEN
				     x_return_status  := l_return_status;
				     if l_msg_count > 0 THEN  
					FOR I IN 1..l_msg_count
					LOOP
					    l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
					END LOOP;
				     end if;
				     x_error_message := l_msg_data;
                                     exit;
				END IF;
                      END IF;

               END LOOP;


  EXCEPTION
      WHEN OTHERS 
      THEN
           x_return_status := 'E';
           x_error_message := SQLERRM; 
 
  END Update_Profile_Details;

-- +================================================================================+
-- | Name        :  Get_Site_Use_Profile                                         |
-- | Description :  To look up the profile which is store at Site use level      |
-- +================================================================================+

  PROCEDURE Get_Site_Use_Profile (
  p_orig_system                          IN VARCHAR2,
  p_site_use_OSR                         IN VARCHAR2,
  x_profile_id                           OUT NOCOPY NUMBER,
  x_return_status 		           OUT NOCOPY VARCHAR2,
  x_error_message                        OUT NOCOPY VARCHAR2) IS

  l_profile_id         NUMBER;

    CURSOR l_site_prf_cur IS
    select cpr.cust_account_profile_id
    from  hz_orig_sys_references osr,
          hz_customer_profiles cpr
    where  osr.orig_system_reference = p_site_use_OSR
    and    osr.owner_table_name = 'HZ_CUST_SITE_USES_ALL'  
    and    osr.orig_system      = p_orig_system
    and    osr.owner_table_id   = cpr.site_use_id 
    and    osr.status = 'A';  

  BEGIN

         OPEN  l_site_prf_cur ;
         FETCH l_site_prf_cur INTO  l_profile_id;
         CLOSE l_site_prf_cur ; 
         
         IF l_profile_id > 0 
         THEN
              x_profile_id      := l_profile_id;
              x_return_status   := 'S';	
         ELSE
              x_profile_id      := 0;
              x_return_status   := 'E';
              x_error_message   := 'No Profile Exists for the Site Use OSR '||p_site_use_OSR;
         END IF;

  EXCEPTION
      WHEN OTHERS 
      THEN
           x_return_status := 'E';
           x_error_message := SQLERRM; 
 
  END Get_Site_Use_Profile ;

END XX_CDH_BPEL_PROFILE_SYNC_PKG;

/