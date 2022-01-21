create or replace
PACKAGE BODY xx_ar_remit_to_addr_report_pkg
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name :      AR Remit-to Address Exception Reporting                 |
-- | Description :   Program that creates a report that by customers that|
-- |                 shows the remit-to address based on the DFF value,  |
-- |                 the desired remit-to based on the customer's bill-to|
-- |                 state, and the acutal remit-to                      |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version   Date          Author              Remarks                  |
-- |=======   ==========   =============        =========================|
-- |1.0       18-SEP-2011  Sinon Perlas         Initial version          |
-- |2.0      15-OCT-2012 Oracle AMS Team Defect # 20429 Adding Parameter |
-- |2.1      09-11-2015   Shubashree R     R12.2  Compliance changes Defect# 36369 |
-- |                                                                     |
-- +=====================================================================+

   -- +=====================================================================+
-- | Name :  Name : XX_AR_REMIT_TO_ADDR_REPORT_PROC                      |
-- | Description :                                                       |
-- | Parameters : P_country, p_customer_Num, P_mismatch_match,           |
-- |              p_locbox_number                                        |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- |Defect # 20429 Adding New parameter :p_locbox_number_from_date       |
-- +=====================================================================+
   fname1           VARCHAR2 (50);
   ln_req_id        NUMBER;
   lc_ftp_process   VARCHAR2 (50);
   cursor_var1      VARCHAR (4000);
   l_output         UTL_FILE.file_type;

   PROCEDURE xx_ar_remit_to_addr_rpt_proc (
      x_err_buff                   OUT      VARCHAR2,
      x_ret_code                   OUT      NUMBER,
      p_country                    IN       VARCHAR2,
      p_customer_num               IN       NUMBER,
      p_mismatch_match             IN       VARCHAR2,
      p_lockbox_number             IN       VARCHAR2,
      p_lockbox_number_from_date   IN       VARCHAR2 DEFAULT NULL
   )
   AS
      TYPE extract_record_type IS RECORD (
         ext_account_name         hz_cust_accounts.account_name%TYPE,
         ext_account_number       hz_cust_accounts.account_number%TYPE,
         ext_aops_cust_number     VARCHAR (8),
         ext_direct_flag          xx_cdh_cust_acct_ext_b.c_ext_attr7%TYPE,
         ext_sequence             VARCHAR (17),
         ext_status               hz_cust_accounts.status%TYPE,
         ext_site_use_code        hz_cust_site_uses_all.site_use_code%TYPE,
         ext_remit_to_channel     hz_cust_site_uses_all.attribute25%TYPE,
         ext_remit_to_lockbox     ar_remit_to_addresses_v.address_lines_phonetic%TYPE
                                                                                     --Varchar(30)
         ,
         ext_bill_to_state        hz_locations.state%TYPE,
         ext_preferred_remit_to   hz_cust_site_uses_all.attribute25%TYPE
                                                                        --Varchar(2)
         ,
         ext_preferred_lockbox    ar_remit_to_addresses_v.address_lines_phonetic%TYPE
                                                                                     --Varchar(30)
         ,
         ext_remittances          ar_receipt_methods.NAME%TYPE  --Varchar(30)
      );

      extract_record         extract_record_type;

      TYPE extact_cursor_type IS REF CURSOR;

      extract_cursor         extact_cursor_type;
      dl_from_lockbox_date   DATE;      -- Added as part of the Defect # 20429
   BEGIN
      DBMS_OUTPUT.put_line ('Build SQL Statement');
      fnd_file.put_line (fnd_file.LOG, 'Build SQL Statement');

      -- ***BUILD SQL STATEMENT BASED ON PARAMETERS PASSED***

       Cursor_Var1 := 'Select distinct Account_Name                      ,
                    Account_Number                    ,
                    orig_sys_ref ,
                    c_ext_attr7                       ,
                    orig_sys_ref2,
                    status                            ,
                    Site_Use_Code                     ,
                    attribute25                       ,
                    address_lines_phonetic1           ,
                    state                              ,
                    attribute1                       ,
                    address_lines_phonetic2           ,
                    Name
          from (
                Select /*+ LEADING(Cdhext) PARALLEL(Cdhext,4) */  -- Added Hint as per defect 27160
                Hzacct.Account_Name,
                 Hzacct.Account_Number,
                 Substr(Hzacct.Orig_System_Reference,1,8) orig_sys_ref,
                 Cdhext.c_ext_attr7,
                 Substr(Hzsite.Orig_System_Reference,1,17)orig_sys_ref2,
                 Hzacct.status,
                 Hzuses.Site_Use_Code,
                 hzuses.attribute25,
                 Araddr1.address_lines_phonetic address_lines_phonetic1,
                 hzloc.state,
                 Araddr2.attribute1,
                 Araddr2.address_lines_phonetic address_lines_phonetic2,
                 Armeth.Name
            From Hz_Cust_Accounts        Hzacct
                ,Hz_Cust_Acct_Sites_All  Hzsite
                ,Hz_Cust_Site_Uses_All   Hzuses
                ,Hz_Party_Sites          Hzparty
                ,Hz_Locations            Hzloc
                ,Xx_cdh_cust_acct_ext_b  Cdhext
                ,Ar_Remit_To_Addresses_V Araddr1
                ,Ra_Remit_Tos_All        raremt
                ,Ar_Remit_To_Addresses_V Araddr2
                ,Ar_cash_receipts_all    Arcash
                ,Ar_receipt_methods      Armeth
                ,Hz_customer_profiles    Hzprofile
                ,AR_Lockboxes_all       ARLockbox
            Where Hzacct.Cust_Account_Id = Hzsite.Cust_Account_Id
            And   Hzsite.Cust_Acct_Site_Id = Hzuses.Cust_Acct_Site_Id
            And   Hzsite.Party_Site_Id =  Hzparty.Party_Site_Id
            And   Hzparty.Location_Id = Hzloc.Location_Id
            And   Hzacct.cust_account_id = Hzprofile.cust_account_profile_id
            And   Hzacct.Status=' || '''' ||'A'|| '''' ||
            ' And  Hzprofile.attribute3=' || '''' ||'Y' || '''' ||
            ' And   Hzuses.Site_Use_Code =' ||'''' || 'BILL_TO' || '''' ||
            ' and   hzprofile.status =' || '''' ||'A'|| '''' ||
            ' And   Hzprofile.Site_Use_Id Is Null
            and   hzuses.attribute25 = Araddr1.attribute1
            and   hzloc.state = raremt.state
            and   raremt.address_id = araddr2.address_id
            And   Hzacct.Cust_Account_Id = Cdhext.Cust_Account_Id
            And   Cdhext.Attr_Group_Id=166
            and   Cdhext.c_ext_attr16=' || '''' || 'COMPLETE' || '''' ||
            ' And  Cdhext.c_ext_attr2=' || '''' || 'Y' || '''' ||
            ' And  NVL(cdhext.c_ext_attr13,' || '''' || 'DB' || '''' || ')=' || '''' || 'DB' || '''' ||
            ' And   hzuses.site_use_id = Arcash.Customer_site_use_id (+)
            and   Arcash.Receipt_method_id = Armeth.Receipt_Method_id (+)
            and   nvl(Arcash.Receipt_method_id,ARLockbox.Receipt_Method_id) = ARLockbox.Receipt_Method_id';
            
       --
       -- Start of the Defect # 20429 Changes
      IF p_lockbox_number_from_date IS NOT NULL
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'From Lockbox Date: '
                            || p_lockbox_number_from_date
                           );
         dl_from_lockbox_date :=
                 TO_DATE (p_lockbox_number_from_date, 'YYYY/MM/DD HH24:MI:SS');
         fnd_file.put_line (fnd_file.LOG,
                               'From Lockbox Date in the date Format: '
                            || dl_from_lockbox_date
                           );
         fnd_file.put_line
                      (fnd_file.LOG,
                          'From Lockbox Date in the date Format after Trunc: '
                       || TRUNC (dl_from_lockbox_date)
                      );
          cursor_var1 :=
               cursor_var1
            || ' and trunc(Arcash.receipt_date)>='
            || ''''
            || trunc(dl_from_Lockbox_date)
            || '''';
                     
      END IF;

      -- Ending  of the Defect # 20429 Changes
      --

      -- *** IF Organization Id PARM IS PASSED ****
      IF p_country IS NOT NULL
      THEN
         IF p_country = 'USD'
         THEN
            cursor_var1 := cursor_var1 || ' and Hzsite.Org_id = 404 ';
         END IF;

         IF p_country = 'CAD'
         THEN
            cursor_var1 := cursor_var1 || ' and Hzsite.Org_id = 403 ';
         END IF;
      END IF;

      -- *** IF CUSTOMER NUMBER PARM IS PASSED ****
      IF p_customer_num IS NOT NULL
      THEN
         cursor_var1 :=
             cursor_var1 || ' and Hzacct.Account_Number = ' || p_customer_num;
      END IF;

      -- *** IF LOCKBOX NUMBER IS PASSED ****
      IF p_lockbox_number IS NOT NULL
      THEN
         cursor_var1 :=
               cursor_var1
            || ' and Armeth.Name ='
            || ''''
            || p_lockbox_number
            || '''';
      END IF;

      -- *** IF LOCKBOX NUMBER IS NOT PASSED ****
      IF p_lockbox_number IS NULL
      THEN
         cursor_var1 :=
               cursor_var1
            || ' and Armeth.Name IN (SELECT FLEX_VALUE FROM FND_FLEX_VALUES_VL WHERE  (('''' IS NULL) OR (STRUCTURED_HIERARCHY_LEVEL IN   (SELECT HIERARCHY_ID   FROM FND_FLEX_HIERARCHIES_VL H
                              WHERE h.flex_value_set_id in (select flex_value_set_id from fnd_flex_value_sets where flex_value_Set_name = ''XX_AR_LOCKBOX_NAMES'')   AND h.hierarchy_name LIKE '''')))
                              AND (FLEX_VALUE_SET_ID in (select flex_value_set_id from fnd_flex_value_sets where flex_value_Set_name = ''XX_AR_LOCKBOX_NAMES'')))';
      END IF;

      --Dbms_Output.Put_Line('Check if request is for Matched or Mismatch');
      fnd_file.put_line (fnd_file.LOG,
                         'Check if request is for Matched or Mismatch'
                        );

      -- **** IF MISMATCH ONLY ****
      IF p_mismatch_match = 'X'
      THEN
         cursor_var1 :=
               cursor_var1 || ' and hzuses.attribute25 <> Araddr2.attribute1';
      END IF;

      -- **** IF MATCH ONLY ****
      IF p_mismatch_match = 'M'
      THEN
         cursor_var1 :=
                 cursor_var1 || 'and hzuses.attribute25 = Araddr2.attribute1';
      END IF;

      --Cursor_Var1 := Cursor_Var1 || ' and   rownum < 100';

      --Dbms_Output.Put_Line('Add Order by');
      fnd_file.put_line (fnd_file.LOG, 'Add Order by');
      -- ***Add Sort Statement***
      cursor_var1 := cursor_var1 || ' order By Hzacct.Account_Number)';
      -- *** open extract file and create column header record ***
      --Dbms_Output.Put_Line('Build Extract file name and create header record');
      fnd_file.put_line (fnd_file.LOG,
                         'Build Extract file name and create header record'
                        );
      fname1 :=
            'REMIT_TO_EXTRACT_FILE'
         || '_'
         || TO_CHAR (SYSDATE, 'MMDDYY_HHMISS')
         || '.csv';
      --Fname1 := 'REMIT_TO_EXTRACT_FILE' || '_' || Sysdate || '.csv';
      l_output := UTL_FILE.fopen ('XXFIN_OUTBOUND', fname1, 'W');
      UTL_FILE.fflush (l_output);
      UTL_FILE.put_line
         (l_output,
             'CUSTOMER NAME " CUSTOMER NUMBER  "AOPS CUSTOMER NUMBER  " DIRECT  " SEQUENCE  "'
          || 'STATUS "  SITE USE CODE  "  DFF REMIT-TO SALES   "'
          || 'DFF REMIT-TO LOCK BOX " BILL-TO STATE  " DERIVED REMIT-TO   " DERIVED LOCKBOX   " CURRENT REMIT-TO"'
         );
      UTL_FILE.fflush (l_output);
      -- *** run sql statement ***
       --Dbms_Output.Put_Line('Go into Loop statement to read files and create extract record');
      DBMS_OUTPUT.put_line (cursor_var1);
      fnd_file.put_line (fnd_file.LOG, cursor_var1);
      fnd_file.put_line
             (fnd_file.LOG,
              'Go into Loop statement to read files and create extract record'
             );

      OPEN extract_cursor FOR cursor_var1;

      --dbms_output.put_line('cursor opened');
      LOOP
         DBMS_OUTPUT.put_line ('loop');

         FETCH extract_cursor
          INTO extract_record;

         IF extract_cursor%NOTFOUND
         THEN
            DBMS_OUTPUT.put_line ('no record found');
            EXIT;
         END IF;

         --If (Extract_Record.Ext_Direct_Flag = 'Y' And Extract_Record.Ext_Remittances is Not Null) Or
         --   (Extract_Record.Ext_Direct_Flag = 'N') then
         --Dbms_Output.Put_Line('fetched');
         --Utl_File.Put_Line(L_Output,'"' || Extract_Record.Ext_Org_Id || '" "' || Extract_Record.Ext_Account_Name || '" "'
         UTL_FILE.put_line (l_output,
                               extract_record.ext_account_name
                            || '"'
                            || extract_record.ext_account_number
                            || '"'
                            || extract_record.ext_aops_cust_number
                            || '"'
                            || extract_record.ext_direct_flag
                            || '"'
                            || extract_record.ext_sequence
                            || '"'
                            --|| Extract_Record.Ext_Customer_Type || '"'
                            || extract_record.ext_status
                            || '"'
                            || extract_record.ext_site_use_code
                            || '"'
                            || extract_record.ext_remit_to_channel
                            || '"'
                            || extract_record.ext_remit_to_lockbox
                            || '"'
                            || extract_record.ext_bill_to_state
                            || '"'
                            || extract_record.ext_preferred_remit_to
                            || '"'
                            || extract_record.ext_preferred_lockbox
                            || '"'
                            || extract_record.ext_remittances
                            || '"'
                           );
         UTL_FILE.fflush (l_output);
      --end if;
      --dbms_output.put_line('extract record :' || Extract_Record.Ext_Account_Name);
      END LOOP;

      CLOSE extract_cursor;

--    FTP EXTRACT FILE TO USER’S NETWORK DIRECTORY
        --Dbms_Output.Put_Line('FTP Extract file to user');
      fnd_file.put_line (fnd_file.LOG, 'FTP Extract file to user');
      lc_ftp_process := 'OD_REMIT_TO_EXTRACT_FILE';
      ln_req_id :=
         fnd_request.submit_request ('XXFIN',
                                     'XXCOMFTP',
                                     '',
                                     '01-OCT-04 00:00:00',
                                     FALSE,
                                     lc_ftp_process,
                                     fname1,
                                     fname1,
                                     'Y'
                                    );
      COMMIT;

      IF ln_req_id > 0
      THEN
         fnd_file.put_line (fnd_file.LOG, 'SUBMITTED FOR ' || fname1);
      ELSE
         fnd_file.put_line (fnd_file.LOG, 'FAILED SUBMISSION FOR ' || fname1);
      END IF;
   EXCEPTION
      WHEN TOO_MANY_ROWS
      THEN
         --Dbms_Output.Put_Line('too many rows : ' || Sqlerrm);
         fnd_file.put_line (fnd_file.LOG, 'too many rows : ' || SQLERRM);
      WHEN NO_DATA_FOUND
      THEN
         --Dbms_Output.Put_Line('No data found');
         fnd_file.put_line (fnd_file.LOG, 'No data found');
      WHEN INVALID_CURSOR
      THEN
         --Dbms_Output.Put_Line('Invalid cursor' || Sqlerrm);
         fnd_file.put_line (fnd_file.LOG, 'Invalid cursor' || SQLERRM);
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('Others ' || SQLERRM);
         fnd_file.put_line
            (fnd_file.LOG,
                'Exception raised while Submiting the OD: AR Remit to Address Report : '
             || SQLERRM
            );
   END xx_ar_remit_to_addr_rpt_proc;
END xx_ar_remit_to_addr_report_pkg;
/

SHOW ERROR