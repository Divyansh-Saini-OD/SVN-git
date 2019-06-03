Set Verify Off;
SET SERVEROUTPUT on 200000;


-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             :  Create_XX_PA_PB_COMPLIANCE_EMAIL               |
-- | Description      : This script will create translation  XX_PA_PB_COMPLIANCE_EMAIL|
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    5-Aug-2014   Lakshmi Tangirala Initial code                   |
-- |    1.1   25-Aug-2014   Paddy Sanjeevi    Replace Sabrina with Sandy Stantain
-- +=========================================================================+


Declare

lc_compl_email_def  apps.Xx_Fin_Translatedefinition%Rowtype;
lc_compl_email_val  apps.Xx_Fin_Translatevalues%Rowtype ;
LN_TRANSLATION_ID  NUMBER;

Begin

Begin
Select Translate_Id
INTO LN_TRANSLATION_ID
From apps.Xx_Fin_Translatedefinition 
Where Translation_Name ='XX_PA_PB_COMPLIANCE_EMAIL';

DELETE
From apps.Xx_Fin_Translatevalues 
Where Translate_ID=LN_TRANSLATION_ID;

DELETE
From apps.Xx_Fin_Translatedefinition 
Where Translate_Id=Ln_Translation_Id;

DELETE
From apps.XX_FIN_TRANSLATERESPONSIBILITY
Where Translate_ID=LN_TRANSLATION_ID;

Dbms_Output.Put_Line('Translation with name :XX_PA_PB_COMPLIANCE_EMAIL exists. Deleted to create new Translation');


COMMIT;

EXCEPTION

When No_Data_Found Then

DBMS_OUTPUT.PUT_LINE('No Translation with name :XX_PA_PB_COMPLIANCE_EMAIL. Creating new Translation');


End;


lc_compl_email_def.Translate_Id                   :=Xx_Fin_Translatedefinition_S.Nextval; 
lc_compl_email_def.Translation_Name               :='XX_PA_PB_COMPLIANCE_EMAIL';
lc_compl_email_def.Purpose                        :='DEFAULT';
lc_compl_email_def.Translate_Description          :='Email addresses used in  xx_pa_pb_compliance_pkg'; 
lc_compl_email_def.Source_Field1                  :='XX_COMPLIANCE_EMAIL';
lc_compl_email_def.Target_Field1                  :='Notify_contact1';
Lc_Compl_Email_Def.Target_Field2                  :='Notify_contact2';  
lc_compl_email_def.Target_Field3                  :='Notify_contact3';  
lc_compl_email_def.Target_Field4                  :='SA_Compliance_sender';  
lc_compl_email_def.Target_Field5                  :='audit_regrush_notify';  
lc_compl_email_def.Target_Field6                  :='aud_result_notify';  
lc_compl_email_def.Target_Field7                  :='vendsk_notify';  
lc_compl_email_def.Target_Field8                  :='gso_social_notify';  
Lc_Compl_Email_Def.Target_Field9                  :='eu_social_notify';  
lc_compl_email_def.Target_Field10                 :='asia_social_noitfy';  
lc_compl_email_def.Target_Field11                 :='odmx_social_notify';  
lc_compl_email_def.Start_Date_Active              :=Sysdate;          
lc_compl_email_def.Enabled_Flag                   :='Y';   
lc_compl_email_def.Do_Not_Refresh                 :='N';

Insert Into apps.Xx_Fin_Translatedefinition Values Lc_Compl_Email_Def;
Dbms_Output.Put_Line(' Translation DEFINITION with name :XX_PA_PB_COMPLIANCE_EMAIL is Created');

commit;





lc_compl_email_val.Translate_Id                :=Xx_Fin_Translatedefinition_S.Currval;        
lc_compl_email_val.Source_Value1               :='XX_COMPLIANCE_EMAIL'; 
lc_compl_email_val.Target_Value1               :='padmanaban.sanjeevi@officedepot.com'; 
lc_compl_email_val.Target_Value2               :='francia.pampillonia@officedepot.com'; 
lc_compl_email_val.Target_Value3               :='sandy.stainton@officedepot.com'; 
Lc_Compl_Email_Val.Target_Value4               :='SA-Compliance@officedepot.com'; 
lc_compl_email_val.Target_Value5               :='OfficeDepot@ul.com'; 
lc_compl_email_val.Target_Value6               :='sandy.stainton@officedepot.com'; 
lc_compl_email_val.Target_Value7               :='VendorDesk@officedepot.com'; 
lc_compl_email_val.Target_Value8               :='gso.socialaccountability@officedepot.com'; 
lc_compl_email_val.Target_Value9               :='Compliance.EU@officedepot.com'; 
lc_compl_email_val.Target_Value10              :='asia.socialaccountability@officedepot.com'; 
lc_compl_email_val.Target_Value11              :='ODMX.socialaccountability@officedepot.com.mx'; 
lc_compl_email_val.Start_Date_Active           :=Sysdate   ;       
lc_compl_email_val.Enabled_Flag                :='Y';   
lc_compl_email_val.Translate_Value_Id          :=XX_FIN_TRANSLATEVALUES_S.NEXTVAL;

Insert Into  apps.Xx_Fin_Translatevalues Values Lc_Compl_Email_Val;
Dbms_Output.Put_Line(' Translation Values with name :XX_PA_PB_COMPLIANCE_EMAIL is Created');





COMMIT;


End;
       
/