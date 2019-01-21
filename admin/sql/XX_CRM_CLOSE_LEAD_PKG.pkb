SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_CRM_CLOSE_LEAD_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_CRM_CLOSE_LEAD_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CRM_CLOSE_LEAD_PKG                                    |
-- | Description : 1) Systematically Close out ALL leads that have not been |
-- |                  touched or updated in 250 days and greater.           |
-- |                                                                        |
-- |               2) Systematically Close out Leads with a Status of " New"|
-- |                  that have not been touched or updated in 180 days.    |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      18-JUN-2010  Anitha Devarajulu     Initial version             |
-- |2.0      01-JUL-2010                        Added Lead Number parameter |
-- |                                            Modified Lead ID to Number  |
-- +========================================================================+

-- +========================================================================+
-- | Name        : UPDATE_TO_CLOSE_LEAD                                     |
-- | Description : 1) Systematically Close out ALL leads that have not been |
-- |                  touched or updated in 250 days and greater.           |
-- |                                                                        |
-- |               2) Systematically Close out Leads with a Status of " New"|
-- |                  that have not been touched or updated in 180 days.    |
-- | Returns     : x_error_buf, x_ret_code                                  |
-- +========================================================================+

   PROCEDURE UPDATE_TO_CLOSE_LEAD (
                                    x_error_buf          OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
                                   ,p_status             IN  VARCHAR2
                                   ,p_no_of_days         IN  NUMBER
                                   ,p_close_reason       IN  VARCHAR2
                                   ,p_update             IN  VARCHAR2
                                   ,p_lead_number        IN  NUMBER
                                   )
   IS

   lc_error_loc                 VARCHAR2(4000);
   lt_sales_lead_profile_tbl    APPS.AS_UTILITY_PUB.PROFILE_TBL_TYPE;
   lr_sales_lead_rec            APPS.AS_SALES_LEADS_PUB.SALES_LEAD_REC_TYPE;
   lc_return_status             VARCHAR2(200);
   ln_msg_count                 NUMBER;
   lc_msg_data                  VARCHAR2(200);
   lb_flag                      BOOLEAN := FALSE;
   l_close_reason               VARCHAR2(80);
   l_valid_close_reason_flag    VARCHAR2(1) := 'Y';

   CURSOR c_sales_leads (p_status VARCHAR2 , p_no_of_days NUMBER)
   IS
   (SELECT *
    FROM   apps.as_sales_leads ASL
    WHERE  ASL.status_code      = DECODE(p_status,'ALL',ASL.status_code,p_status)
    AND    ASL.last_update_date < SYSDATE - p_no_of_days
    AND    ASL.status_code      NOT IN ('CLOSED' ,'CONVERTED_TO_OPPORTUNITY','LOST')
    AND    ASL.lead_number = nvl(p_lead_number,ASL.lead_number)
    );

    CURSOR  c_close_reason
    IS
     (SELECT meaning
       FROM FND_LOOKUPS
      WHERE lookup_code = p_close_reason
      and lookup_type = 'ASN_LEAD_CLOSE_REASON' and enabled_flag = 'Y' 
      and lookup_code <> 'CONVERTED_TO_OPPORTUNITY');

   BEGIN

      OPEN c_close_reason;
      FETCH c_close_reason into l_close_reason;
      
      IF c_close_reason%NOTFOUND THEN
        l_valid_close_reason_flag := 'N';
      END IF; 
      
      CLOSE c_close_reason;
      
      IF l_valid_close_reason_flag = 'Y' THEN
      
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, rpad('Sales Lead No',15)||rpad('Status',40)||rpad('Close Reason',100));
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   ');


      FOR lc_sales_leads IN c_sales_leads(p_status , p_no_of_days)
      LOOP

         lb_flag                            := TRUE;
         lr_sales_lead_rec.sales_lead_id    := lc_sales_leads.sales_lead_id;
         lr_sales_lead_rec.status_code      := 'CLOSED';
         lr_sales_lead_rec.close_reason     := substr(p_close_reason,0,30);
         lr_sales_lead_rec.last_update_date := lc_sales_leads.last_update_date;

	 IF p_update = 'Y' THEN

         as_sales_leads_pub.update_sales_lead(
                                              p_api_version_number       => 2.0
                                             ,p_init_msg_list            => FND_API.G_TRUE
                                             ,p_commit                   => FND_API.G_TRUE
                                             ,p_validation_level         => NULL
                                             ,p_check_access_flag        => NULL
                                             ,p_admin_flag               => NULL
                                             ,p_admin_group_id           => NULL
                                             ,p_identity_salesforce_id   => NULL
                                             ,p_sales_lead_profile_tbl   => lt_sales_lead_profile_tbl
                                             ,p_sales_lead_rec           => lr_sales_lead_rec
                                             ,x_return_status            => lc_return_status
                                             ,x_msg_count                => ln_msg_count
                                             ,x_msg_data                 => lc_msg_data
                                             );
         
	 ELSE
          
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, rpad(to_char(lc_sales_leads.lead_number),15)
                                          ||rpad(lc_sales_leads.status_code,40));
         
         END IF;  


         IF (lc_return_status = 'S') THEN

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT, rpad(to_char(lc_sales_leads.lead_number),15)
                                          ||rpad(lr_sales_lead_rec.status_code,40)
                                          ||rpad(l_close_reason,100));

         ELSE

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Lead with ID '||to_char(lc_sales_leads.sales_lead_id)||' was not closed due to this reason : ' || lc_msg_data);

         END IF;

      END LOOP;

   COMMIT;

   IF (lb_flag = FALSE) THEN

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'No Data found for the Status: ' || p_status);

   END IF;

   ELSE
     x_ret_code := 2;
     FND_FILE.PUT_LINE(FND_FILE.LOG,p_close_reason||' is not a valid close reason');
   
   END IF;

   EXCEPTION

   WHEN OTHERS THEN

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error Msg: '||SQLERRM);
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
           p_program_type            => 'Closing Leads'
          ,p_program_name            => 'Closing Leads'
          ,p_program_id              => NULL
          ,p_module_name             => 'XXCRM'
          ,p_error_message_count     => 1
          ,p_error_message_code      => 'E'
          ,p_error_message           => 'Error at : ' || lc_error_loc 
                       ||' - '||SQLERRM
          ,p_error_message_severity  => 'Minor'
          ,p_notify_flag             => 'N'
          ,p_object_type             => 'Closing Leads'
          ,p_object_id               => NULL);

           x_ret_code := 2;
           x_error_buf := 'Error at XX_CRM_CLOSE_LEAD_PKG.UPDATE_TO_CLOSE_LEAD : '
                          ||lc_error_loc ||'Error Message: '||SQLERRM;

   END UPDATE_TO_CLOSE_LEAD;


   PROCEDURE REVERT_BACK_CLOSE_LEAD_DATA (
                                    x_error_buf          OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER                                   
                                   ,P_REQUEST_ID         IN  NUMBER
                                   ,P_RECORDS_TO_UPDATE  IN  NUMBER
                                   ,P_LEAD_NUMBER        IN  NUMBER
                                   ,P_REVERT_TO_DATE     IN  VARCHAR2
                                   )
   IS
   
     lt_sales_lead_profile_tbl    APPS.AS_UTILITY_PUB.PROFILE_TBL_TYPE;
     lr_sales_lead_rec            APPS.AS_SALES_LEADS_PUB.SALES_LEAD_REC_TYPE;
     lc_return_status             VARCHAR2(200);
     ln_msg_count                 NUMBER;
     lc_msg_data                  VARCHAR2(200);
     lc_err_msgs                  VARCHAR2(3000);
     lc_new_lead                  VARCHAR2(1):='N';
     l_last_rec_update_date       DATE;
     lc_revert_to_date            VARCHAR2(23);
     INVALID_DATE                 EXCEPTION;
     
      CURSOR C_LEAD_DATA IS
      SELECT *
      FROM 
        apps.AS_SALES_LEADS
      WHERE
          lead_number = nvl(P_LEAD_NUMBER,lead_number)
      AND request_id = P_REQUEST_ID
      AND ROWNUM < nvl(P_RECORDS_TO_UPDATE,10000000);

      CURSOR C_LOG_DATA_TO_REVERT (C_IN_LEAD_ID IN NUMBER,C_IN_REVERT_TO_DATE IN VARCHAR2) IS
      SELECT *
      FROM
        (SELECT *
        FROM as_sales_leads_log
        WHERE sales_lead_id = C_IN_LEAD_ID
        AND STATUS_CODE NOT IN ('CLOSED' ,'CONVERTED_TO_OPPORTUNITY','LOST')
        AND creation_date   =
          (SELECT MAX(creation_date)
            FROM as_sales_leads_log
           WHERE sales_lead_id = C_IN_LEAD_ID
           AND creation_date   < to_date(C_IN_REVERT_TO_DATE,'DD-MON-YYYY HH:MI:SS AM')
          )
        ORDER BY creation_date,
          log_id DESC
        )
      WHERE rownum < 2;
         
      
   BEGIN
   BEGIN
   lc_revert_to_date := to_date(P_REVERT_TO_DATE,'DD-MON-YYYY HH:MI:SS AM');
   EXCEPTION WHEN OTHERS THEN
   RAISE INVALID_DATE;
   END;

                  
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, rpad('Sales Lead No',15)||rpad('Status',40)||rpad('Last Update Date',100));
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'   ');
  
      FOR i in C_LEAD_DATA
      LOOP
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing Lead with ID:'||i.sales_lead_id||' for P_REVERT_TO_DATE: '||P_REVERT_TO_DATE);
        FOR j in C_LOG_DATA_TO_REVERT (i.sales_lead_id,P_REVERT_TO_DATE)
          LOOP
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Processing Lead Log ID:'||j.log_id);         
              lr_sales_lead_rec.sales_lead_id    := i.sales_lead_id;
              lr_sales_lead_rec.status_code      := j.status_code;
              lr_sales_lead_rec.close_reason     := null;
              lr_sales_lead_rec.last_update_date := i.last_update_date;
--              l_total_count := l_total_count + 1;
              
              as_sales_leads_pub.update_sales_lead(
                                              p_api_version_number       => 2.0
                                             ,p_init_msg_list            => FND_API.G_TRUE
                                             ,p_commit                   => FND_API.G_TRUE
                                             ,p_validation_level         => NULL
                                             ,p_check_access_flag        => NULL
                                             ,p_admin_flag               => NULL
                                             ,p_admin_group_id           => NULL
                                             ,p_identity_salesforce_id   => NULL
                                             ,p_sales_lead_profile_tbl   => lt_sales_lead_profile_tbl
                                             ,p_sales_lead_rec           => lr_sales_lead_rec
                                             ,x_return_status            => lc_return_status
                                             ,x_msg_count                => ln_msg_count
                                             ,x_msg_data                 => lc_msg_data
                                             );
                                             
               IF  lc_return_status = 'S' THEN
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, rpad(i.lead_number,15)||rpad(j.status_code,40)||rpad(to_char(j.last_update_date,'dd-Mon-YYYY HH:MI:SS AM'),100));
--                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Lead '||lc_sales_closed_leads.sales_lead_id||' will be updated with last_updated_date = '||j.last_update_date);

                UPDATE AS_SALES_LEADS
                 SET last_update_date = j.last_update_date --, close_reason = null, status_code = lc_sales_closed_leads.status_code
                 where sales_lead_id = i.sales_lead_id;

                ELSE
                  FOR k in 1..ln_msg_count
                  LOOP
                   lc_err_msgs := lc_err_msgs||' '||lc_msg_data;
                  END LOOP; 
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error While updating Lead with Number'||i.lead_number||' reason :' ||lc_err_msgs); 
                END IF; 
          
          END LOOP;
      END LOOP;
  
    EXCEPTION
    WHEN INVALID_DATE THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Date format for Revert to date. Please enter the date in format DD-MON-YYYY HH:MI:SS AM');
    x_error_buf  := 'Invalid Date format for Revert to date. Please enter the date in format DD-MON-YYYY HH:MI:SS AM';
    x_ret_code := '2';    
    
    WHEN OTHERS THEN
    x_error_buf  := sqlerrm;
    x_ret_code := '2';    
        
      
    END REVERT_BACK_CLOSE_LEAD_DATA;


END XX_CRM_CLOSE_LEAD_PKG;
/
SHOW ERR

EXIT