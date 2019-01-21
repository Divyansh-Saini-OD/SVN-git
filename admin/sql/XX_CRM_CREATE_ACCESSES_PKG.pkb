SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_CRM_CREATE_ACCESSES_PKG

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_CRM_CREATE_ACCESSES_PKG
AS

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CRM_CREATE_ACCESSES_PKG                                    |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      02-JUL-2010  Vasan Santhanam       Initial version             |
-- +========================================================================+

   -- +========================================================================+
   -- | Name        : CREATE_MISSING_ACCESSES                                  |
   -- | Description : 1)Insert a row into Accesses table where the row not exist |
   -- |                                                                        |
   -- |                                                                        |
   -- |                                                                        |
   -- |                                                                        |
   -- | Returns     : x_error_buf, x_ret_code                                  |
   -- +========================================================================+

   PROCEDURE CREATE_MISSING_ACCESSES ( x_error_buf          OUT VARCHAR2
                                     , x_ret_code           OUT NUMBER
                                     , p_opp_number         IN  VARCHAR2
                                     )
   IS

       lc_error_loc                 VARCHAR2(2000);
       lc_return_status             VARCHAR2(200);
       ln_msg_count                 NUMBER;
       lc_msg_data                  VARCHAR2(200);
       lc_row_id                    VARCHAR2(2000);
       ln_access_id                 NUMBER;

       CURSOR c_inv_access
       IS
       SELECT ala.*
        FROM   apps.as_leads_all ala
              ,apps.AS_ACCESSES_ALL aaa
        WHERE  ala.lead_id = aaa.lead_id(+)
        AND    aaa.lead_id is null
        AND    ala.lead_id = nvl(p_opp_number,ala.lead_id);

       CURSOR c_get_res_det(p_opp_number NUMBER)
       IS
       (
           SELECT *
           FROM  apps.XX_TM_NAM_TERR_CURR_ASSIGN_V
           WHERE entity_type = 'OPPORTUNITY'
           AND   entity_id = p_opp_number
       );


   BEGIN
     x_ret_code := 0;

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Begin Processing');

     /*UPDATE apps.AS_ACCESSES_ALL
     SET salesforce_role_code=null
        ,object_creation_date=null
        ,person_id = 19860
     WHERE ACCESS_ID=1532059;

     COMMIT;
     */
     FOR lcu_sales_leads IN c_inv_access
     LOOP
        FOR lcu_res_det IN c_get_res_det(lcu_sales_leads.lead_id)
        LOOP
            ln_access_id := NULL;
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Processing for Opportunity '||lcu_sales_leads.lead_id);
            AS_ACCESSES_PKG.Insert_Row
                (X_Rowid                               => lc_row_id
                ,X_Access_Id                           => ln_access_id
                ,X_Last_Update_Date                    => SYSDATE
                ,X_Last_Updated_By                     => FND_GLOBAL.user_id
                ,X_Creation_Date                       => SYSDATE
                ,X_Created_By                          => FND_GLOBAL.user_id
                ,X_Last_Update_Login                   => FND_GLOBAL.login_id
                ,X_Access_Type                         => NULL
                ,X_Freeze_Flag                         => 'Y'
                ,X_Reassign_Flag                       => NULL
                ,X_Team_Leader_Flag                    => 'Y'
                ,X_Person_Id                           => NULL
                ,X_Customer_Id                         => lcu_sales_leads.customer_id
                ,X_Address_Id                          => lcu_sales_leads.address_id
                ,X_Salesforce_Id                       => lcu_res_det.resource_id
                ,X_Partner_Customer_Id                 => NULL
                ,X_Partner_Address_Id                  => NULL
                ,X_Created_Person_Id                   => NULL
                ,X_Lead_Id                             => lcu_sales_leads.lead_id
                ,X_Freeze_Date                         => NULL
                ,X_Reassign_Reason                     => NULL
                ,x_reassign_request_date               => NULL
                ,x_reassign_requested_person_id        => NULL
                ,X_Attribute_Category                  => NULL
                ,X_Attribute1                          => NULL
                ,X_Attribute2                          => NULL
                ,X_Attribute3                          => NULL
                ,X_Attribute4                          => NULL
                ,X_Attribute5                          => NULL
                ,X_Attribute6                          => NULL
                ,X_Attribute7                          => NULL
                ,X_Attribute8                          => NULL
                ,X_Attribute9                          => NULL
                ,X_Attribute10                         => NULL
                ,X_Attribute11                         => NULL
                ,X_Attribute12                         => NULL
                ,X_Attribute13                         => NULL
                ,X_Attribute14                         => NULL
                ,X_Attribute15                         => NULL
                ,X_Salesforce_Role_Code                => NULL --lcu_res_det.resource_role_id
                ,X_Salesforce_Relationship_Code        => NULL
                ,X_Internal_update_access              => NULL
                ,X_Sales_lead_id                       => NULL
                ,X_Sales_group_Id                      => lcu_res_det.group_id
                ,X_Partner_Cont_Party_Id               => NULL
                ,X_owner_flag                          => 'Y'
                ,X_created_by_tap_flag                 => NULL
                ,X_prm_keep_flag                       => NULL
                ,X_open_flag                           => NULL
                ,X_lead_rank_score                     => NULL
                ,X_object_creation_date                => NULL
                ,X_contributor_flag                    => NULL
                );
                EXIT;
            END LOOP; --lcu_res_det IN c_get_res_det(lcu_sales_leads.lead_id);
         END LOOP;  --lcu_sales_leads IN c_inv_access


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

   END CREATE_MISSING_ACCESSES;

END XX_CRM_CREATE_ACCESSES_PKG;
/
SHOW ERROR

