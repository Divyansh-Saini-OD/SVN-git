create or replace 
PACKAGE BODY XX_CE_CUST_JE_LINES_CREATE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_CE_CUST_JE_LINES_CREATE_PKG                            |
-- | Description      :  This Package is created for custom JE creation|
-- |                     extension that excludes certain BAI2          |
-- |                     Transaction codes on the bank statement lines |
-- |                     from standard JE creation so they are not sent|
-- |                     through the standard JE and reconciliation    |
-- |                     process, enabling processing by the           |
-- |                     other CE custom extensions.                   |
-- |                                                                   |
-- |                                                                   |
-- | RICE#            : E2027                                          |
-- | Main ITG Package :                                                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date         Author            Remarks                    |
-- |=======  ==========   =============     ===========================|
-- |DRAFT 1A 09-DEC-2008  Pradeep Krishnan  Initial draft version      |
-- |1.1      12-JAN-2009  Pradeep Krishnan  Updated the code for the   |
-- |                                        defect 12790.              |
-- |1.2      04-FEB-2009  Pradeep Krishnan  Updated the code for the   |
-- |                                        defect 12914.              |
-- |1.3      11-OCT-2012  Abdul Khan        QC 20234 - Added condition |
-- |                                        so that Reconciled  lines  |
-- |                                        doesnt get picked by E2027 |
-- |1.4      15-JUL-2013  Arun Pandian	    Retrofitted with R12       | 
-- |1.5      18-MAY-2016  Avinash Baddam    Changes for defect#37859   |
-- |1.6      06-APR-2017  Leelakrishna.G    Defect#40651			   |
-- +===================================================================+

-- +===================================================================+
-- | Name  : XX_CE_ISSUE_JRNLS_EMAIL                                     |
-- | Description      : This Procedure can be used to send the Issue   |
-- |                    Journals details to the business               |
-- |                                                                   |
-- | Parameters :p_last_noofdays                                       |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
procedure XX_CE_ISSUE_JRNLS_EMAIL( X_RETCODE OUT  number
                               ,X_errbuf OUT VARCHAR2
			       ,P_LAST_NOOFDAYS in number)
is 
cursor cur_iss_jrnls is
SELECT CSH.BANK_ACCOUNT_ID, CSH.STATEMENT_NUMBER, CSH.STATEMENT_DATE, CSL.LINE_NUMBER, CSL.STATEMENT_LINE_ID, CSL.TRX_DATE, CSL.TRX_TYPE, CSL.AMOUNT, CSL.STATEMENT_HEADER_ID, CSL.INVOICE_TEXT, CTC.TRX_CODE, ABA.CURRENCY_CODE, GCC.SEGMENT1, GCC.SEGMENT2, GCC.SEGMENT3, GCC.SEGMENT4, GCC.SEGMENT5, GCC.SEGMENT6, GCC.SEGMENT7
FROM CE_STATEMENT_HEADERS CSH,
CE_STATEMENT_LINES CSL,
CE_TRANSACTION_CODES CTC,
GL_CODE_COMBINATIONS GCC,
CE_BANK_ACCOUNTS ABA
WHERE CSH.STATEMENT_HEADER_ID = CSL.STATEMENT_HEADER_ID
AND CSH.BANK_ACCOUNT_ID       = CTC.BANK_ACCOUNT_ID
AND CTC.BANK_ACCOUNT_ID       = ABA.BANK_ACCOUNT_ID
and NVL (CSL.ATTRIBUTE2,'N') <> 'PROC-E2027-YES'
--AND CSH.CREATION_DATE > SYSDATE-650
AND CSH.CREATION_DATE > SYSDATE-P_LAST_NOOFDAYS
AND CSL.TRX_CODE              = CTC.TRX_CODE
AND GCC.CODE_COMBINATION_ID   = CTC.ATTRIBUTE10
and CTC.ATTRIBUTE10          is not null;
cur_type cur_iss_jrnls%rowtype;

lc_mail_from varchar2(100):='CE_JOURNALS';
lc_mail_recipient VARCHAR2(1000);
lc_mail_host VARCHAR2(100):= fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER');
lc_mail_conn utl_smtp.connection;
crlf  VARCHAR2(10) := chr(13) || chr(10);
slen number :=1;
v_addr Varchar2(1000);
lc_instance varchar2(100);
lc_msg_body CLOB;
lc_mail_subject     VARCHAR2(2000);
lc_mail_body_det1        VARCHAR2(32767):=NULL;
lc_mail_body_det2       VARCHAR2(5000):=NULL;
lc_mail_header1      VARCHAR2(1000);
lc_mail_body_det3       VARCHAR2(5000):=NULL;
lc_mail_body_det4       VARCHAR2(5000):=NULL;
lc_mail_body_det5       VARCHAR2(5000):=NULL;
lc_mail_body_det6       VARCHAR2(5000):=NULL;
lc_mail_header2         VARCHAR2(1000);
lc_mail_body1        VARCHAR2(5000):=NULL;
lc_mail_body2       VARCHAR2(5000):=NULL;
lc_mail_header      VARCHAR2(1000);
lc_mail_body3       VARCHAR2(5000):=NULL;
lc_mail_body4       VARCHAR2(5000):=NULL;
lc_mail_body5       VARCHAR2(5000):=NULL;
lc_mail_body6       VARCHAR2(5000):=NULL;
LC_MAIL_BODY7       varchar2(5000):=null; 	
p_email_list varchar2(1000);
begin

begin
SELECT target_value9 into p_email_list
    FROM xx_fin_translatedefinition def,
      xx_fin_translatevalues val
    Where Def.Translate_Id   =Val.Translate_Id
    And Def.Translation_Name = 'XX_CE_JRNLS_NOTIFICATION';
Exception
When Others Then
 FND_FILE.put_line(FND_FILE.log,'Error while fetching the email list:' || p_email_list);
end;

lc_mail_conn := utl_smtp.open_connection(lc_mail_host,25);
--lc_mail_recipient := 'l.guravarajapet@officedepot.com';
lc_mail_recipient := p_email_list;
utl_smtp.helo(lc_mail_conn, lc_mail_host);
utl_smtp.mail(lc_mail_conn, lc_mail_from);
if (instr(lc_mail_recipient,',') = 0) then
v_addr:= lc_mail_recipient;
utl_smtp.rcpt(lc_mail_conn,v_addr);
else
lc_mail_recipient := replace(lc_mail_recipient,' ','_') || ',';
while (instr(lc_mail_recipient,',',slen)> 0) loop
v_addr := substr(lc_mail_recipient,slen,instr(substr(lc_mail_recipient,slen),',')-1);
slen := slen + instr(substr(lc_mail_recipient,slen),',');
utl_smtp.rcpt(lc_mail_conn,v_addr);
end loop;
end if;

FOR cur_type IN cur_iss_jrnls LOOP
/*
lc_mail_body_det1 :=lc_mail_body_det1||'<TR><TD>'||cur_type.BANK_ACCOUNT_ID||'</TD><TD>'||cur_type.STATEMENT_NUMBER||'</TD><TD>'||cur_type.STATEMENT_DATE||'</TD><TD>'||cur_type.LINE_NUMBER||'</TD><TD>'||cur_type.STATEMENT_LINE_ID||'</TD><TD>'||cur_type.TRX_DATE||'</TD><TD>'||cur_type.TRX_TYPE||'</TD><TD>'||cur_type.AMOUNT||'</TD><TD>'||cur_type.STATEMENT_HEADER_ID||'</TD>
<TD>'||cur_type.INVOICE_TEXT||'</TD><TD>'||cur_type.TRX_CODE||'</TD><TD>'||cur_type.CURRENCY_CODE||'</TD><TD>'||cur_type.SEGMENT1||'</TD><TD>'||cur_type.SEGMENT2||'</TD><TD>'||cur_type.SEGMENT3||'</TD><TD>'||cur_type.SEGMENT4||'</TD><TD>'||cur_type.SEGMENT5||'</TD><TD>'||cur_type.SEGMENT6||'</TD><TD>'||cur_type.SEGMENT7||'</TD></TR>';
*/
lc_mail_body_det1 :=lc_mail_body_det1||'</TD><TD>'||cur_type.STATEMENT_NUMBER||'</TD><TD>'||cur_type.STATEMENT_DATE||'</TD><TD>'||cur_type.LINE_NUMBER||'</TD><TD>'||cur_type.TRX_DATE||'</TD><TD>'||cur_type.TRX_TYPE||'</TD><TD>'||cur_type.AMOUNT||'</TD><TD>'||cur_type.CURRENCY_CODE||'</TD></TR>';

end loop;

select INSTANCE_NAME into LC_INSTANCE from V$INSTANCE;
LC_MAIL_SUBJECT := 'Issue Journals (Pending Pending ) IN - ' || LC_INSTANCE;
/*
LC_MAIL_HEADER1 := '<TABLE border="1"><TR align="left"><TH><B>BANK_ACCOUNT_ID</B></TH><TH><B>STATEMENT_NUMBER</B></TH><TH><B>STATEMENT_DATE</B></TH><TH><B>LINE_NUMBER</B></TH><TH><B>STATEMENT_LINE_ID</B></TH><TH><B>TRX_DATE</B></TH><TH><B>TRX_TYPE</B></TH><TH><B>AMOUNT</B></TH><TH><B>STATEMENT_HEADER_ID</B></TH><TH><B>INVOICE_TEXT</B></TH><TH><B>TRX_CODE</B></TH><TH><B>CURRENCY_CODE</B></TH>
<TH><B>SEGMENT1</B></TH><TH><B>SEGMENT2</B></TH><TH><B>SEGMENT3</B></TH><TH><B>SEGMENT4</B></TH><TH><B>SEGMENT5</B></TH><TH><B>SEGMENT6</B></TH><TH><B>SEGMENT7</B></TH></TR>';
*/
LC_MAIL_HEADER1 := '<TABLE border="1"><TR align="left"><TH><B>STATEMENT_NUMBER</B></TH><TH><B>STATEMENT_DATE</B></TH><TH><B>LINE_NUMBER</B></TH><TH><B>TRX_DATE</B></TH><TH><B>TRX_TYPE</B></TH><TH><B>AMOUNT</B></TH><TH><B>CURRENCY_CODE</B></TH></TR>';
UTL_SMTP.DATA
         (lc_mail_conn,
             'From:'
          || lc_mail_from
          || UTL_TCP.crlf
          || 'To: '
          || v_addr
          || UTL_TCP.crlf
          || 'Subject: '
          || lc_mail_subject
          || UTL_TCP.crlf||'MIME-Version: 1.0' || crlf || 'Content-type: text/html'
	  ||utl_tcp.CRLF
	  ||'<HTML><head><meta http-equiv="Content-Language" content="en-us" /><meta http-equiv="Content-Type" content="text/html; charset=windows-1252" /></head><BODY><BR>Hi All,<BR><BR>'
          || crlf
          || crlf
          || crlf
          ||'*********** Issue Journals Summary  ***********:<BR><BR>'
          ||crlf
          ||crlf
          ||lc_mail_header1
		  ||lc_mail_body_det1		  
          ||'</TABLE><BR>'
          || crlf	      
          || crlf||'</BODY></HTML>'
         );
UTL_SMTP.QUIT(LC_MAIL_CONN);

EXCEPTION
 when UTL_SMTP.TRANSIENT_ERROR or UTL_SMTP.PERMANENT_ERROR then
   RAISE_APPLICATION_ERROR(-20000, 'Unable to send mail: '||SQLERRM);         
end XX_CE_ISSUE_JRNLS_EMAIL;

-- +===================================================================+
-- | Name  : CREATE_GL_INTRF_STG_LINE_MAIN                             |
-- | Description      : This Procedure can be used to insert GL Journal|
-- |                    entry line into the XX_GL_INTERFACE_NA_STG     |
-- |                    table.                                         |
-- |                                                                   |
-- | Parameters :p_bank_branch_id                                      |
-- |             p_bank_account_id                                     |
-- |             p_statement_number_from                               |
-- |             p_statement_number_to                                 |
-- |             p_statement_date_from                                 |
-- |             p_statement_date_to                                   |
-- |             p_gl_date                                             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE CREATE_GL_INTRF_STG_LINE_MAIN (
           x_errbuf                OUT NOCOPY  VARCHAR2
          ,x_retcode               OUT NOCOPY  NUMBER
          ,p_bank_branch_id        IN NUMBER
          ,p_bank_account_id       IN NUMBER
          ,p_statement_number_from IN VARCHAR2
          ,p_statement_number_to   IN VARCHAR2
          ,p_statement_date_from   IN VARCHAR2
          ,p_statement_date_to     IN VARCHAR2
          ,p_gl_date               IN VARCHAR2
          )
IS
  ------------------------------------------------------------------
  -- Cursor to get all the statement lines based on the parameters
  -- which has a cash account value in the Attribute10 field of the
  -- CE_STATEMENT_LINES table and which is not yet processed
  ------------------------------------------------------------------

  CURSOR lcu_gl_line
  IS
     SELECT CSH.bank_account_id
           ,CSH.statement_number
           ,CSH.statement_date
           ,CSL.line_number
           ,CSL.statement_line_id
           ,CSL.trx_date
           ,CSL.trx_type
           ,CSL.amount
           ,CSL.statement_header_id
           ,CSL.invoice_text
           ,CTC.trx_code
           ,ABA.currency_code
           ,GCC.segment1
           ,GCC.segment2
           ,GCC.segment3
           ,GCC.segment4
           ,GCC.segment5
           ,GCC.segment6
           ,GCC.segment7
     FROM   ce_statement_headers     CSH
           ,ce_statement_lines       CSL
           ,ce_transaction_codes     CTC
           ,gl_code_combinations     GCC
           --,ap_bank_accounts       ABA   -- Commented for the R12 Retrofit
           ,ce_bank_accounts         ABA   -- Added as part of R12 Retrofit
     WHERE CSH.statement_header_id   = CSL.statement_header_id
     AND   CSH.bank_account_id       = CTC.bank_account_id
     AND   CTC.bank_account_id       = ABA.bank_account_id
     AND   NVL(CSL.attribute2,'N')   <> 'PROC-E2027-YES'
     AND   CSL.status                <> 'RECONCILED' -- Added this condition so that Reconciled  lines  doesnt get picked by E2027 process - QC Defect # 20234
     AND   CSH.bank_account_id       = NVL(p_bank_account_id,CSH.bank_account_id)
     AND   ABA.bank_branch_id        = NVL(p_bank_branch_id,ABA.bank_branch_id)
     AND   CSH.statement_number BETWEEN NVL(p_statement_number_from,CSH.statement_number)
                                    AND NVL(p_statement_number_to,CSH.statement_number)
     AND   fnd_date.canonical_to_date(CSH.statement_date) BETWEEN NVL(fnd_date.canonical_to_date(p_statement_date_from),fnd_date.canonical_to_date(CSH.statement_date))
                                                              AND NVL(fnd_date.canonical_to_date(p_statement_date_to),fnd_date.canonical_to_date(CSH.statement_date))
     AND   CSL.trx_code = CTC.trx_code         -- modified for Retrofit to R12
     AND   GCC.code_combination_id   = CTC.attribute10
     AND   CTC.attribute10 IS NOT NULL;

  ln_cash_bank_account_id    ce_statement_headers.bank_account_id%TYPE;  --Commented ce_statement_headers_all as part of R12 Retrofit
  ln_statement_number        ce_statement_headers.statement_number%TYPE; --Commented ce_statement_headers_all as part of R12 Retrofit
  ln_header_id               ce_statement_lines.statement_header_id%TYPE;
  ld_statement_date          ce_statement_headers.statement_date%TYPE;   --Commented ce_statement_headers_all as part of R12 Retrofit 
  ln_statement_line_number   ce_statement_lines.line_number%TYPE;
  ln_statement_line_id       ce_statement_lines.statement_line_id%TYPE;
  ld_trx_date                ce_statement_lines.trx_date%TYPE;
  lc_trx_type                ce_statement_lines.trx_type%TYPE;
  ln_amount                  ce_statement_lines.amount%TYPE;
  lc_invoice_text            ce_statement_lines.invoice_text%TYPE;
  lc_trx_code                ce_transaction_codes.trx_code%TYPE;
  ln_user_id                 NUMBER := fnd_global.user_id;
  ln_group_id                NUMBER;
  ld_gl_date                 VARCHAR2(20);
  
  /* Defect #37859 - Removed ap_bank references
  ln_asset_bank_account_id   ap_bank_accounts_all.bank_account_id%TYPE;
  lc_bank_acct_num           ap_bank_accounts_all.bank_account_num%TYPE;
  lc_bank_account            ap_bank_accounts_all.bank_account_num%TYPE;
  lc_currency_code           ap_bank_accounts_all.currency_code%TYPE;
  ln_sob_id                  ap_bank_accounts_all.set_of_books_id%TYPE;
  ln_org_id                  ap_bank_accounts_all.org_id%TYPE;
  lc_bank_name               ap_bank_branches.bank_name%TYPE;*/
  
  ln_asset_bank_account_id   ce_bank_accounts.bank_account_id%TYPE;
  lc_bank_acct_num           ce_bank_accounts.bank_account_num%TYPE;
  lc_bank_account            ce_bank_accounts.bank_account_num%TYPE;
  lc_currency_code           ce_bank_accounts.currency_code%TYPE;
  ln_sob_id                  hr_operating_units.set_of_books_id%TYPE;
  ln_org_id                  ce_bank_acct_uses.org_id%TYPE;
  lc_bank_name               hz_organization_profiles.organization_name%TYPE;
  lpv_description            VARCHAR2(240);
  lc_output_msg              VARCHAR2(240);
  lc_output_msg1             VARCHAR2(240);
  --lc_bank_branch           ap_bank_branches.bank_branch_name%TYPE; --commented defect#37859
  lc_bank_branch	     hz_parties.party_name%TYPE; --Added for defect#37859
  lc_ba_segment1             gl_code_combinations.segment1%TYPE;
  lc_ba_segment2             gl_code_combinations.segment2%TYPE;
  lc_ba_segment3             gl_code_combinations.segment3%TYPE;
  lc_ba_segment4             gl_code_combinations.segment4%TYPE;
  lc_ba_segment5             gl_code_combinations.segment5%TYPE;
  lc_ba_segment6             gl_code_combinations.segment6%TYPE;
  lc_ba_segment7             gl_code_combinations.segment7%TYPE;
  lc_segment1                gl_code_combinations.segment1%TYPE;
  lc_segment2                gl_code_combinations.segment2%TYPE;
  lc_segment3                gl_code_combinations.segment3%TYPE;
  lc_segment4                gl_code_combinations.segment4%TYPE;
  lc_segment5                gl_code_combinations.segment5%TYPE;
  lc_segment6                gl_code_combinations.segment6%TYPE;
  lc_segment7                gl_code_combinations.segment7%TYPE;
--  lc_cr_ccid                 VARCHAR2(25);
--  lc_dr_ccid                 VARCHAR2(25);
  lc_cr_company              gl_code_combinations.segment1%TYPE;
  lc_cr_cost_center          gl_code_combinations.segment2%TYPE;
  lc_cr_account              gl_code_combinations.segment3%TYPE;
  lc_cr_location             gl_code_combinations.segment4%TYPE;
  lc_cr_intercompany         gl_code_combinations.segment5%TYPE;
  lc_cr_channel              gl_code_combinations.segment6%TYPE;
  lc_cr_future               gl_code_combinations.segment7%TYPE;
  lc_dr_company              gl_code_combinations.segment1%TYPE;
  lc_dr_cost_center          gl_code_combinations.segment2%TYPE;
  lc_dr_account              gl_code_combinations.segment3%TYPE;
  lc_dr_location             gl_code_combinations.segment4%TYPE;
  lc_dr_intercompany         gl_code_combinations.segment5%TYPE;
  lc_dr_channel              gl_code_combinations.segment6%TYPE;
  lc_dr_future               gl_code_combinations.segment7%TYPE;
  ln_cnt                     NUMBER := 0;
  ln_cnt1                    NUMBER := 0;
  ln_cnt2                    NUMBER := 0;
  EX_ERROR                   EXCEPTION;
  BEGIN
  
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Main Begin started'); 		--Defect#40651
    IF p_bank_branch_id IS NOT NULL THEN
    BEGIN
        SELECT bank_branch_name, bank_name
          INTO lc_bank_branch, lc_bank_name
          FROM ce_bank_branches_v--ap_bank_branches Commented and added as part of R12 retrofit
         WHERE branch_party_id = p_bank_branch_id;--bank_branch_id = p_bank_branch_id;Commented and added as part of R12 retrofit
    Exception     
         When Others Then
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in fetching the bank branch name.');
    END;
    END IF;
    
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Checking for bank_account_id');		--Defect#40651
    IF p_bank_account_id IS NOT NULL
    THEN
    BEGIN
        SELECT bank_account_num
          INTO lc_bank_account
          FROM ce_bank_accounts--ap_bank_accounts Commented and added as part of R12 retrofit
         WHERE bank_account_id = p_bank_account_id;
    Exception     
         When Others Then
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in fetching the bank account number.');
    END;
    END IF;
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                             Custom Journal Entry Creation Execution Report                                                     Report Date :  ' ||to_char(sysdate,'DD-MON-YY HH:MM'));
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Name             :' || lc_bank_name);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Branch Name      :' || lc_bank_branch);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Bank Account Number   :' || lc_bank_account);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Number From :' || p_statement_number_from);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Number to   :' || p_statement_number_to);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Date From   :' || p_statement_date_from);
    FND_FILE.PUT_LINE(FND_FILE.Output,' Statement Date To     :' || p_statement_date_to);
    FND_FILE.PUT_LINE(FND_FILE.Output,' GL Date               :' || p_gl_date);
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                                                  ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'Bank Acc #               Statement #          Currency    Statement Date    Statement Line    TRX Code   GL Acct String                                             DR $ Amount                CR $ Amount');
    FND_FILE.PUT_LINE(FND_FILE.Output,'----------               -----------          --------    --------------    --------------    --------   --------------                                             ------------               -----------');

    BEGIN
	     FND_FILE.PUT_LINE(FND_FILE.LOG,'Creating GL Interface sequence value');		--Defect#40651
         SELECT gl_interface_control_s.NEXTVAL
         INTO   ln_group_id
         FROM   SYS.DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in GL Interface sequence.');				
    END;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Open Cursor lcu_gl_line');		--Defect#40651
    OPEN lcu_gl_line;
    LOOP
      ln_cnt := ln_cnt + 1;
       BEGIN
        FETCH lcu_gl_line
        INTO  ln_cash_bank_account_id
             ,ln_statement_number
             ,ld_statement_date
             ,ln_statement_line_number
             ,ln_statement_line_id
             ,ld_trx_date
             ,lc_trx_type
             ,ln_amount
             ,ln_header_id
             ,lc_invoice_text
             ,lc_trx_code
             ,lc_currency_code
             ,lc_segment1
             ,lc_segment2
             ,lc_segment3
             ,lc_segment4
             ,lc_segment5
             ,lc_segment6
             ,lc_segment7;
        EXIT WHEN lcu_gl_line%NOTFOUND OR lcu_gl_line%NOTFOUND IS NULL;

        BEGIN
		FND_FILE.PUT_LINE(FND_FILE.LOG,'cash_bank_account_id - statement number :'||ln_cash_bank_account_id||'-'||ln_statement_number);		--Defect#40651
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin ln_cnt1 := ln_cnt1 + 1');		--Defect#40651
        ln_cnt1 := ln_cnt1 + 1;
         ---------------------------------------------------------------------------
         -- This statement will fetch the Asset Account for a given bank_account_id
         ---------------------------------------------------------------------------
           SELECT ABA.bank_account_id
                 ,ABA.bank_account_num
                 ,ABA.currency_code
                 ,hou.set_of_books_id      --   aba.set_of_books_id   ----Changed for R12 retrofit 
		 ,cbau.org_id              -- Added as part of R12 Retrofit    
                 --,ABA.set_of_books_id    -- Commented as part of R12 Retrofit
                 --,ABA.org_id             -- Commented as part of R12 Retrofit
                 ,GCC.segment1
                 ,GCC.segment2
                 ,GCC.segment3
                 ,GCC.segment4
                 ,GCC.segment5
                 ,GCC.segment6
                 ,GCC.segment7
           INTO   ln_asset_bank_account_id
                 ,lc_bank_acct_num
                 ,lc_currency_code
                 ,ln_sob_id
                 ,ln_org_id
                 ,lc_ba_segment1
                 ,lc_ba_segment2
                 ,lc_ba_segment3
                 ,lc_ba_segment4
                 ,lc_ba_segment5
                 ,lc_ba_segment6
                 ,lc_ba_segment7
           FROM   gl_code_combinations GCC
                 --,ap_bank_accounts     ABA --Commented as part of R12 Retrofit
                 ,ce_bank_accounts     ABA   --Added as part of R12 Retrofit
                 ,ce_bank_acct_uses    cbau  --Added as part of R12 retrofit
		 ,hr_operating_units   hou   --Added as part of R12 Retrofit
           WHERE  ABA.asset_code_combination_id    = GCC.code_combination_id
           AND    ABA.bank_account_id              = NVL(p_bank_account_id,ln_cash_bank_account_id)
           AND    NVL (ABA.end_date, SYSDATE + 1) > TRUNC (SYSDATE) --Changed Inactive_date to end_date as part of R12 retrofit
           AND aba.bank_account_id = cbau.bank_account_id             ----Added for R12 retrofit 
           AND hou.organization_id = cbau.org_id  ; 
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Before RAISE EX_ERROR EXECPTION');     ----Added for R12 retrofit 
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'RAISED EX_ERROR'||SQLERRM||'-'||SQLCODE);		--Defect#40651
          RAISE EX_ERROR;
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'RAISED EX_ERROR');							--Defect#40651
        WHEN OTHERS THEN
		 FND_FILE.PUT_LINE(FND_FILE.LOG,'RAISED EX_ERROR in when others then exception'||SQLERRM||'-'||SQLCODE);		--Defect#40651
         RAISE EX_ERROR;
		 FND_FILE.PUT_LINE(FND_FILE.LOG,'RAISED EX_ERROR in when others exception');									--Defect#40651
        END;
        ld_gl_date := to_char(to_date(p_gl_date,'YYYY/MM/DD HH24:MI:SS'));
        lpv_description := lc_bank_acct_num||'-'||ln_statement_number||'-'||ln_statement_line_number||'-'||lc_trx_code||'-'||lc_invoice_text;
        
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Checking MISC_CREDIT transaction type');		--Defect#40651
		
        IF UPPER(lc_trx_type) = 'CREDIT' OR UPPER(lc_trx_type) = 'MISC_CREDIT' THEN
          --ln_amount := get it from cursor
          -- lc_cr_ccid := trx code setup;
          -- lc_dr_ccid := bank acct setup;
          lc_cr_company       := lc_segment1;
          lc_cr_cost_center   := lc_segment2;
          lc_cr_account       := lc_segment3;
          lc_cr_location      := lc_segment4;
          lc_cr_intercompany  := lc_segment5;
          lc_cr_channel       := lc_segment6;
          lc_cr_future        := lc_segment7;
          lc_dr_company       := lc_ba_segment1;
          lc_dr_cost_center   := lc_ba_segment2;
          lc_dr_account       := lc_ba_segment3;
          lc_dr_location      := lc_ba_segment4;
          lc_dr_intercompany  := lc_ba_segment5;
          lc_dr_channel       := lc_ba_segment6;
          lc_dr_future        := lc_ba_segment7;
        ELSE
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Checking MISC_CREDIT transaction type Else Condtion');		--Defect#40651
          -- lc_dr_ccid := trx code setup;
          -- lc_cr_ccid := bank acct setup;
          lc_dr_company       := lc_segment1;
          lc_dr_cost_center   := lc_segment2;
          lc_dr_account       := lc_segment3;
          lc_dr_location      := lc_segment4;
          lc_dr_intercompany  := lc_segment5;
          lc_dr_channel       := lc_segment6;
          lc_dr_future        := lc_segment7;
          lc_cr_company       := lc_ba_segment1;
          lc_cr_cost_center   := lc_ba_segment2;
          lc_cr_account       := lc_ba_segment3;
          lc_cr_location      := lc_ba_segment4;
          lc_cr_intercompany  := lc_ba_segment5;
          lc_cr_channel       := lc_ba_segment6;
          lc_cr_future        := lc_ba_segment7;
        END IF;
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Ending MISC_CREDIT transaction type Condtion');			--Defect#40651
        FND_FILE.PUT_LINE(FND_FILE.log, 'ln_user_id : ' || ln_user_id ||','||'ln_group_id : ' || ln_group_id  ||','||'ld_gl_date :' || ld_gl_date ||','||'ln_sob_id : ' || ln_sob_id ||','||'lc_currency_code : ' || lc_currency_code ||','||'ln_statement_number : ' || ln_statement_number ||','|| 'ln_statement_line_number : ' || ln_statement_line_number ||','|| 'ln_amount : ' || ln_amount);
        
		 FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling packge xx_gl_interface_pkg.create_stg_jrnl_line for lc_cr_account');		--Defect#40651
        xx_gl_interface_pkg.create_stg_jrnl_line(
                                                 p_status => 'NEW'
                                               , p_date_created => SYSDATE
                                               , p_created_by => ln_user_id
                                               , p_actual_flag => 'A'
                                               , p_group_id => ln_group_id
                                               , p_batch_name => ld_trx_date
                                               , p_batch_desc => ' '
                                               , p_user_source_name => 'OD CM Other'
                                               , p_user_catgory_name => 'Other'
                                               , p_set_of_books_id => ln_sob_id
                                               , p_accounting_date => NVL(ld_gl_date,SYSDATE)
                                               , p_currency_code => lc_currency_code
                                               , p_company => lc_cr_company
                                               , p_cost_center => lc_cr_cost_center
                                               , p_account => lc_cr_account
                                               , p_location => lc_cr_location
                                               , p_intercompany => lc_cr_intercompany
                                               , p_channel => lc_cr_channel
                                               , p_future => lc_cr_future
                                               , p_entered_dr => 0
                                               , p_entered_cr => ln_amount
                                               , p_je_name => NULL
                                               , p_je_reference => ln_group_id
                                               , p_je_line_dsc => SUBSTR (lpv_description , 1 , 240 )
                                               , x_output_msg => lc_output_msg1
                                               );

        FND_FILE.PUT_LINE(FND_FILE.log, 'lc_Output_Message1 - Credit : ' || lc_output_msg1);
        FND_FILE.PUT_LINE(FND_FILE.Output,(RPAD(lc_bank_acct_num,25,' ')
                                          ||RPAD(ln_statement_number,21,' ')
                                          ||RPAD(lc_currency_code,12,' ')
                                          ||RPAD(ld_statement_date,18,' ')
                                          ||RPAD(ln_statement_line_number,18,' ')
                                          ||RPAD(lc_trx_code,11,' ')
                                          ||RPAD(lc_dr_company||'.'||lc_dr_cost_center||'.'||lc_dr_account||'.'||lc_dr_location||'.'||lc_dr_intercompany||'.'||lc_dr_channel||'.'||lc_dr_future,45,' ')
                                          ||LPAD(LTRIM(RTRIM(TO_CHAR(ln_amount,'$999,999,999,990.00'))),26,' ')
                                          ||LPAD('$0.00',26,' ')
                                          )
                         );
        
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Calling packge xx_gl_interface_pkg.create_stg_jrnl_line for lc_dr_account');		--Defect#40651
        xx_gl_interface_pkg.create_stg_jrnl_line(
                                                  p_status => 'NEW'
                                                , p_date_created => SYSDATE
                                                , p_created_by => ln_user_id
                                                , p_actual_flag => 'A'
                                                , p_group_id => ln_group_id
                                                , p_batch_name => ld_trx_date
                                                , p_batch_desc => ' '
                                                , p_user_source_name => 'OD CM Other'
                                                , p_user_catgory_name => 'Other'
                                                , p_set_of_books_id => ln_sob_id
                                                , p_accounting_date => NVL(ld_gl_date,SYSDATE)
                                                , p_currency_code => lc_currency_code
                                                , p_company => lc_dr_company
                                                , p_cost_center => lc_dr_cost_center
                                                , p_account => lc_dr_account
                                                , p_location => lc_dr_location
                                                , p_intercompany => lc_dr_intercompany
                                                , p_channel => lc_dr_channel
                                                , p_future => lc_dr_future
                                                , p_entered_dr => ln_amount
                                                , p_entered_cr => 0
                                                , p_je_name => NULL
                                                , p_je_reference => ln_group_id
                                                , p_je_line_dsc => SUBSTR (lpv_description , 1 , 240 )
                                                , x_output_msg => lc_output_msg
                                                );
        FND_FILE.PUT_LINE(FND_FILE.log, 'lc_Output_Message1 - Debit : ' || lc_output_msg);
        FND_FILE.PUT_LINE(FND_FILE.Output,(RPAD(lc_bank_acct_num,25,' ')
                                          ||RPAD(ln_statement_number,21,' ')
                                          ||RPAD(lc_currency_code,12,' ')
                                          ||RPAD(ld_statement_date,18,' ')
                                          ||RPAD(ln_statement_line_number,18,' ')
                                          ||RPAD(lc_trx_code,11,' ')
                                          ||RPAD(lc_cr_company||'.'||lc_cr_cost_center||'.'||lc_cr_account||'.'||lc_cr_location||'.'||lc_cr_intercompany||'.'||lc_cr_channel||'.'||lc_cr_future,45,' ')
                                          ||LPAD('$0.00',26,' ')
                                          ||LPAD(LTRIM(RTRIM(TO_CHAR(ln_amount,'$999,999,999,990.00'))),26,' ')
                                          )
                         );
                         
        ------------------------------------------------------
         -- Update the processed record with the status as 'Y'
        -----------------------------------------------------
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Updating table ce_statement_lines');		--Defect#40651
        UPDATE ce_statement_lines
        SET    attribute2          = 'PROC-E2027-YES'
        WHERE  statement_line_id   = ln_statement_line_id
        AND    statement_header_id = ln_header_id;
        ln_cnt2 := ln_cnt2 + 1;
      EXCEPTION
        WHEN EX_ERROR THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error:'|| SQLERRM);
      END;
      IF ln_cnt >= 2000 THEN
        COMMIT;
        ln_cnt :=0;
      END IF;
    END LOOP;
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Total No. Of records updated in the table ce_statement_lines:'|| SQL%ROWCOUNT);		--Defect#40651
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                       ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                                                                                                                       ');
    FND_FILE.PUT_LINE(FND_FILE.Output,'                                ***************** End of Report *******************                                                    ');
    FND_FILE.PUT_LINE(FND_FILE.log,'Total No. Of records fetched : '||ln_cnt1);
    FND_FILE.PUT_LINE(FND_FILE.log,'Total No. Of inserted in GL Tables : '||ln_cnt2);
    COMMIT;
  END;
END;
/