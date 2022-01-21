SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace
PACKAGE BODY XX_AP_INV_PCARD_PROCESS_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_AP_INV_PCARD_PROCESS_PKG                                     |
-- | Description      : This Program will load all Pcard AP Inva             |
-- |                    into EBIZ                                            |
-- |                                                                         |
-- +=========================================================================+
-- |=================== Change History ======================================|
-- | V1.0         Bala E          Initial version                            |
-- | V1.1         Bala E          Defect#                                    |               
-- |                              Changed the GL Description                 |
-- | V1.2         Bala E          Changed for Defect#14431                   | 
-- | V1.3         Paddy Sanjeevi  Modified for the layout change Defect 19041| 
-- | V1.4         Harvinder Rakhra Retroffit R12.2                           | 
-- |=========================================================================|


PROCEDURE log_exception (
      p_error_location       IN   VARCHAR2,
      p_error_message_code   IN   VARCHAR2,
      p_error_msg            IN   VARCHAR2
   )
   IS
      ln_login     PLS_INTEGER := fnd_global.login_id;
      ln_user_id   PLS_INTEGER := fnd_global.user_id;
   BEGIN
      xx_com_error_log_pub.log_error
                               (p_return_code                 => fnd_api.g_ret_sts_error,
                                p_msg_count                   => 1,
                                p_application_name            => 'XX_APINV_PCARD',
                                p_program_type                => 'Custom Messages',
                                p_program_name                => 'XX_AP_INV_PCARD_PKG',
                                p_program_id                  => NULL,
                                p_module_name                 => 'APINVPCARD',
                                p_error_location              => p_error_location,
                                p_error_message_code          => p_error_message_code,
                                p_error_message               => p_error_msg,
                                p_error_message_severity      => 'MAJOR',
                                p_error_status                => 'ACTIVE',
                                p_created_by                  => 500904, --ln_user_id
                                p_last_updated_by             => 500904,
                                p_last_update_login           => 500904
                               );
 END log_exception;



PROCEDURE PROCESS_PCARD_INVOICE_PUB(p_header_rec    IN OUT XX_AP_INVINB_PCARD_HDR_REC       
                               ,p_detail_tbl    IN  XX_AP_INVINB_PCARD_DTL_TBL
                               ,x_return_cd     OUT VARCHAR2
                               ,x_return_msg    OUT VARCHAR2)
IS

-- Declare Local Variables

Ln_Invoice_Id           Number;
Ln_Invoice_Line_Id      Number;
Ln_User_Id              Number;
Ln_Dtl_Stax_Total_Amt   Number (25,2) := 0.00;
Ln_Gross_Amt            Number(20,2);
Ln_Dtl_Trans_Amt        Number(20,2):=0.00;
Ln_Dtl_Stax_Amt         Number(20,2):=0.00;
Ln_Batch_Id             Number :=0 ;
Ln_Line_No              Number := 0;
Ln_Trail_Count          Number :=0;
Ln_Total_Rec_Count      Number :=0;
Ln_Trail_Gross_Amt      Number(25,2) := 0.00;  
Ln_Dtl_Trans_Total_Amt  Number(25,2):= 0.00; 
Ln_Rec_Exists           Number :=0;
Ln_Max_Line_No          Number :=0;
ln_rec_count            NUMBER;

lc_hdr_Inv_date        VARCHAR2(25);
lc_hdr_inv_time        VARCHAR2(25);
lc_company_ref         VARCHAR2(250);
Lc_Comp_Map            VARCHAR2(250);
Lc_Invc_No             VARCHAR2(50);
Lc_Dtl_Ac_Code         VARCHAR2(250);
lc_emp_id              VARCHAR2(250);
lc_dtl_ac_no           VARCHAR2(250);
lc_dtl_transdate       VARCHAR2(250);
Lc_Trail_Debit_amt     VARCHAR2(250);
Lc_Trail_Credit_Amt    VARCHAR2(250);
lc_rec_count           VARCHAR2(250); 
Lc_Gl_Cost_Center      VARCHAR2(150);
lc_gl_account          VARCHAR2(150);
Lc_Gl_Location         VARCHAR2(150);
lc_gl_InterCompany     VARCHAR2(150);
Lc_Gl_Lineofbusiness   VARCHAR2(150);
Lc_Gl_Description      VARCHAR2(150);
Lc_Gl_Future1          VARCHAR2(150);
Lc_Dist_Code           VARCHAR2(250);
Lc_Pcard_Ac_No         VARCHAR2(50);
Lc_Trailer_Flag        VARCHAR2(1) := 'N';
X_Proc_Return_Cd       VARCHAR2(1) := 'Y';
x_proc_return_msg      VARCHAR2(2000);


BEGIN

-- Get user Id
Select Nvl (Fnd_Profile.Value ('USER_ID'), 0) Into Ln_User_Id From Dual; 

-- Assign Header values to temporary variables

lc_Hdr_Inv_Date   := To_Date(P_Header_Rec.Invoice_Date,'DD-MM-YYYY');    
lc_Hdr_Inv_Time   := P_Header_Rec.Invoice_Time;              
Lc_Invc_No        := Lc_Pcard_Ac_No || P_Header_Rec.Invoice_Date;
Ln_Batch_Id       := To_Number(P_Header_Rec.Attribute1);
--lc_company_ref    := p_header_rec.COMPANY_REF;        
--Lc_Comp_Map       := P_Header_Rec.Company_Map ; 

-- #############################################################################################
-- Verify for Header Record
-- #############################################################################################
  BEGIN
   Select Count(*) Into Ln_Rec_Exists From Xx_Ap_Inv_Interface_Stg
   Where Trim(Batch_Id) = Trim(Ln_Batch_Id);
   
      If Ln_Rec_Exists = 0 Then
-- #############################################################################################      
-- No Header Record existrs. Insert Header Record        
-- #############################################################################################
        Select Ap_Invoices_Interface_S.Nextval Into Ln_Invoice_Id From Dual;    
         
        INSERT INTO XX_AP_INV_INTERFACE_STG
            ( INVOICE_ID
             ,INVOICE_NUM
             ,Invoice_Date
    --       ,INVOICE_AMOUNT
             ,INVOICE_TYPE_LOOKUP_CODE
             ,Source
             ,BATCH_ID
             ,CREATION_DATE 
             ,CREATED_BY
             ,LAST_UPDATED_By
             ,LAST_UPDATE_DATE
             ,LAST_UPDATE_LOGIN
           )
        VALUES
           (
            ln_invoice_id 
            ,lc_invc_no
            ,Lc_Hdr_Inv_Date
  --        ,to_number(ln_gross_amt)
            ,'STANDARD'
            ,'US_OD_PCARD'
            ,to_char(ln_batch_id)
            ,sysdate
            ,ln_user_id
            ,ln_user_id
            ,sysdate
            ,ln_user_id
          );        
          Ln_Line_No := 1;
   
     ELSE -- Header Record already Exists , Get Invoice Id
     Select /*+ rule ls.XX_AP_INV_LINES_INT_STG_N1 */ max(lh.invoice_id), Max(Line_Number) Into ln_invoice_id,ln_Max_Line_No
     From Xx_Ap_Inv_Lines_Interface_Stg Ls,
          Xx_Ap_Inv_Interface_Stg Lh
     Where Ls.Invoice_Id = Lh.Invoice_Id
     And Lh.Batch_Id = Ln_Batch_Id;    
     Ln_Line_No := Ln_Max_Line_No +1 ;  
     End If;
  EXCEPTION
  WHEN OTHERS THEN
            X_Proc_Return_Cd := 'N';
            x_proc_return_msg := 'Error in Inserting Header Record into Staging table' || sqlerrm;
  
  End;
-- ###########################################################################################  
-- Find Detail records count including 2nd header and Trailer
-- ###########################################################################################  
      Ln_Rec_Count := P_Detail_Tbl.Count;
-- ###########################################################################################  
-- Read Detail records (avoid 2nd header and Trailer)
-- ###########################################################################################  
For J In 1..Ln_Rec_Count 
Loop --Line read loop starts

    Ln_Dtl_Trans_Amt    := To_Number(P_Detail_Tbl(J).Line_Transact_Amount) ;
    Ln_Dtl_Stax_Amt     := To_Number(P_Detail_Tbl(J).Line_Sales_Tax_Amount);
    lc_dtl_ac_code      := p_detail_tbl(j).ACCOUNTING_CODE;
    Lc_Emp_Id           := P_Detail_Tbl(J).Employee_No;
    Lc_Dtl_Ac_No        := P_Detail_Tbl(J).Account_Number;
    Lc_Dtl_Transdate    := P_Detail_Tbl(J).Line_Trasact_Date;
    lc_emp_id           := p_detail_tbl(j).EMPLOYEE_NO;
    Lc_Dtl_Ac_No        := Substr(P_Detail_Tbl(J).Account_Number,1,16); 
    Lc_Dtl_Transdate    := Substr(P_Detail_Tbl(J).Account_Number,18,8); 
    Lc_Gl_Cost_Center   := Substr(Lc_Dtl_Ac_Code,6,5);
    Lc_Gl_Account       := Substr(Lc_Dtl_Ac_Code,12,8);
    lc_gl_location      := SUBSTR(lc_dtl_ac_code,21,6);
    lc_gl_InterCompany  := '0000';
    Lc_Gl_Lineofbusiness:= Substr(Lc_Dtl_Ac_Code,33,2);
    Lc_Gl_Future1       := '000000';
    Lc_Gl_Description   :=  Lc_Emp_Id ||'_' || Substr(Lc_Dtl_Ac_No,-4,4) ||'_' ||Lc_Dtl_Transdate;    
    lc_dist_code        := '.' || lc_gl_cost_center || '.' || lc_gl_account || '.' || lc_gl_location || '.' || lc_gl_InterCompany || '.' || lc_gl_LineOfBusiness ||'.' || lc_gl_future1 ;

    Begin      
-- ###########################################################################################  
-- verfiy whether detail line is Trailer or not
-- ###########################################################################################  
       
      If    Length(Lc_Dtl_Ac_Code) > 23  And Instr(Lc_Dtl_Ac_Code,'\') > 0  Then
    
         SELECT ap_invoice_lines_interface_s.NEXTVAL INTO ln_invoice_line_id FROM DUAL;  
         INSERT INTO XX_AP_INV_LINES_INTERFACE_STG
           (
             INVOICE_ID
            ,INVOICE_LINE_ID
            ,LINE_NUMBER 
        --  ,LINE_TYPE_LOOKUP_CODE
            ,Amount
            ,STAT_AMOUNT
            ,ORACLE_GL_COMPANY -- Company
            ,ORACLE_GL_COST_CENTER -- Cost Center
            ,ORACLE_GL_LOCATION -- Location
            ,ORACLE_GL_ACCOUNT -- Account
            ,ORACLE_GL_INTERCOMPANY -- InterCompany
            ,ORACLE_GL_LOB        -- Line of Business 
            ,ORACLE_GL_FUTURE1 -- GL Future
            ,DESCRIPTION
            ,ACCOUNTING_DATE
            ,DIST_CODE_CONCATENATED
            ,CREATION_DATE 
            ,CREATED_BY
            ,LAST_UPDATED_By
            ,LAST_UPDATE_DATE
            ,LAST_UPDATE_LOGIN         
           )
           VALUES (
             ln_invoice_id 
            ,ln_invoice_line_id
            ,ln_line_no  --j -1 
        --  ,'ITEM'
            ,ln_Dtl_Trans_Amt 
           ,ln_dtl_stax_amt           
            ,''  --Company
            ,lc_gl_cost_center 
            ,lc_gl_location 
            ,lc_gl_account
            ,lc_gl_InterCompany            
            ,lc_gl_LineOfBusiness
            ,lc_gl_future1
            ,lc_gl_description
            ,to_date(lc_dtl_transdate,'MM-DD-YYYY') 
            ,lc_dist_code
            ,sysdate
            ,ln_user_id
            ,ln_user_id
            ,sysdate
            ,ln_user_id
           ) ;
         
         Ln_Line_No := Ln_Line_No + 1;  -- Loop counter increments
         -- Totals of Line amount
         Ln_Dtl_Trans_Total_Amt := Ln_Dtl_Trans_Total_Amt + Ln_Dtl_Trans_Amt;
         Ln_Dtl_Stax_Total_Amt := Ln_Dtl_Stax_Total_Amt + Ln_Dtl_Stax_Amt;     
-- ###########################################################################################  
-- Line is TRAILER 
-- ###########################################################################################  
        Else 
          Ln_Trail_Count := Ln_Trail_Count + 1;   
          Lc_Trail_Debit_Amt := P_Detail_Tbl(J).Line_Sales_Tax_Amount;
          Lc_Trail_Credit_Amt := P_Detail_Tbl(J).Employee_No; 
          lc_trailer_flag := 'Y';
        End if;           
           
      EXCEPTION
         WHEN OTHERS THEN
            x_proc_return_cd := 'N';
            x_proc_return_msg := 'Error in Inserting into Staging table' || sqlerrm;
           
      End;    
End Loop;  -- detail read Loop ends

-- If the chunk has the trailer record update invoice amount from triler dara
Begin

If Lc_Trailer_Flag = 'Y' THEN
  Ln_Gross_Amt := To_Number(Lc_Trail_Debit_Amt) + To_Number(Lc_Trail_Credit_Amt);
-- Update the Amount at header level  
   Update Xx_Ap_Inv_Interface_Stg
   Set Invoice_Amount = Ln_Gross_Amt
   Where Invoice_Id = Ln_Invoice_Id;

Else

 Ln_Gross_Amt := Ln_Dtl_Trans_Total_Amt + Ln_Dtl_Stax_Total_Amt; 
-- ln_trail_gross_amt := to_number(Lc_Trail_Debit_Amt) + to_number(lc_trail_credit_amt);
-- Update the Amount at header level  
   Update Xx_Ap_Inv_Interface_Stg
   Set Invoice_Amount = Ln_Gross_Amt
   Where Invoice_Id = Ln_Invoice_Id;
   
End If;   
EXCEPTION
When Others Then
  X_Proc_Return_Cd := 'F';
  x_proc_return_msg := 'Error in Processing Invoices to Staging table' || sqlerrm;

END;
   
-- Get the Total number of Lines for the batch data  
   Select Count(*) Into Ln_Total_Rec_Count From Xx_Ap_Inv_Lines_Interface_Stg Ls,Xx_Ap_Inv_Interface_Stg Lh
   Where Lh.Invoice_Id = Ls.Invoice_Id
   and lh.batch_id = to_char(ln_batch_id);
     
-- Passing back Additional Header Values 
If x_proc_return_cd = 'Y' Then

P_Header_Rec.Attribute3 := Lc_Hdr_Inv_Date;
p_header_rec.attribute4 := to_char(ln_total_rec_count);
P_Header_Rec.Attribute5:= Ln_Gross_Amt;
x_proc_return_msg:= ln_rec_count - ln_trail_count || ' Records' ;

Else

x_return_cd := 'F';
x_proc_return_msg:= 'Process of chunk failed' ;

End if;
-- Passing back to calling procedure the status variables
x_return_cd := x_proc_return_cd;
x_return_msg := x_proc_return_msg; 

Exception
 When No_Data_Found Then
  X_Proc_Return_Cd := 'F';
  x_proc_return_msg := 'Error in Processing Invoices to Staging table' || sqlerrm;
 
 When Others Then
  x_proc_return_cd := 'F';
  x_proc_return_msg := 'Error in Processing Invoices to Staging table' || sqlerrm;
END   PROCESS_PCARD_INVOICE_PUB;                          

END XX_AP_INV_PCARD_PROCESS_PKG;
/
SHOW ERRORS PACKAGE XX_QA_SC_VEN_AUDIT_BPEL_PKG;
EXIT;


