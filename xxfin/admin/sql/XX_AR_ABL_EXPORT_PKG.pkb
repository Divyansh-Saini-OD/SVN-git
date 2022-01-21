create or replace
PACKAGE BODY xx_ar_abl_export_pkg IS
  -- +=================================================================================+
  -- |                       Office Depot - ABL Export                                 |
  -- |                            Providge Consulting                                  |
  -- +=================================================================================+
  -- | Name       : XX_AR_ABL_EXPORT_PKG.pkb                                           |
  -- | Description: To Export ABL data to files for a give date                        |
  -- | Rice       : R7007                                                              |
  -- |                                                                                 |
  -- |                                                                                 |
  -- |                                                                                 |
  -- |Change Record                                                                    |
  -- |==============                                                                   |
  -- |Version   Date         Authors            Remarks                                |
  -- |========  ===========  ===============    ============================           |
  -- |DRAFT 1A  04-Aug-2011  Sunildev K         Initial draft version                  |
  -- |DRAFT 1B  24-Nov-2015  Vasu Raparla       Removed Schema References for R.12.2   |  
  -- |DRAFT 1C  20-May-2016  Rakesh Polepalli   Removed create table statements and    |
  -- |                              replaced with insert statements for defect# 37760  |
  -- |1.1       06-JUN-2016  Suresh Naragam     MOD4B Rel 4 Changes(Masfer Defect#37271)|
  -- |1.2       19-AUG-2016  Havish Kasina      Removed the schema references as per   |
  -- |                                          R12.2 GSCC Changes                     |
  -- +=================================================================================+
  -- | Name        : CONS_SENT_INVOICES                                                |
  -- | Description : This procedure will be used to export consolidated unbillled      |
  -- |               Sent Invoices data                                                |
  -- |               AR Lockbox Custom Auto Cash Rules                                 |
  -- |                                                                                 |
  -- | Parameters  : p_as_of_date                                                      |
  -- |               p_email_address                                                   |
  -- |                                                                                 |
  -- | Returns     : x_errbuf                                                          |
  -- |               x_retcode                                                         |
  -- +=================================================================================+
  l_header        VARCHAR2(200) := '"OP_Unit"|"Oracle_Acct_No"|"Customer"|"Open_Amt"|"Org_Amt"|"Transaction_Number"|"Invoice_Date"|"Due_Date"|"Scheduled_Print_Date"|"LGND"|"Exception_Item"';
  l_email_address VARCHAR2(2000) := NULL;
  l_user_id number := fnd_profile.value('user_id');
  PROCEDURE get_email_address IS

   /* CURSOR c_main IS
      SELECT flv.meaning
        FROM fnd_lookup_values_vl flv
       WHERE flv.lookup_type = 'XXOD_AR_ABL_EXT_EMAIL'
         AND flv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN flv.start_date_active AND
             nvl(flv.end_date_active,
                 SYSDATE + 1);*/ -- Commented for Defect 19070 by Divya

  BEGIN

    -- Check Email ID in FND_USER
    fnd_file.put_line(fnd_file.log,'User ID :'||l_user_id);

    IF l_email_address IS NULL
    THEN

	 select email_address into l_email_address from FND_USER where user_id = l_user_id;

              -- Check Email ID in PER_ALL_PEOPLE_F if not exist in FND_USER 

               IF l_email_address IS NULL
               THEN

                    SELECT papf.email_address into l_email_address
                    FROM PER_ALL_PEOPLE_F papf ,fND_USER fu
                    where  papf.person_id = fu.employee_id
                    AND fu.user_id = l_user_id;

               END IF;

      /*FOR i_main IN c_main
      LOOP
        IF l_email_address IS NULL
        THEN
          l_email_address := i_main.meaning;
        ELSE
          l_email_address := l_email_address || ', ' || i_main.meaning;
        END IF;
      END LOOP;*/  -- Commented for Defect 19070 by Divya
    END IF;

  fnd_file.put_line(fnd_file.log,'Email Address :'||l_email_address);

  EXCEPTION
 
    WHEN OTHERS THEN l_email_address := NULL;
    fnd_file.put_line(fnd_file.log,'Email Address :'||l_email_address);

  END get_email_address;
  
  --Commented for the defect# 37760 - version 1C
/*
  PROCEDURE drop_table(p_table_name VARCHAR2) IS

  BEGIN

    EXECUTE IMMEDIATE 'drop table ' || p_table_name;

  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,
                        'Table xx_ar_abl_cbe1 does not exist');
  END drop_table;*/
  
  --Added for the defect# 37760 - version 1C
  PROCEDURE truncate_table(p_table_name VARCHAR2) IS

  BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || p_table_name;

  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,
                        'Table ' ||p_table_name|| 'Could not be truncated');
  END truncate_table;

  PROCEDURE cons_sent_invoices
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  ) IS
    ---+===============================================================================================
    ---|  This procedure will extract data for consolidated unbilled and sent invoices as of given date
    ---+===============================================================================================

    l_sql VARCHAR2(4000);

    l_p_as_of_date DATE := trunc(to_date(p_as_of_date,
                                         'RRRR/MM/DD HH24:MI:SS'));

    TYPE t_od_cc_sent_tbl IS TABLE OF OD_ABL_CONS_TBL%ROWTYPE;

    l_tab t_od_cc_sent_tbl := t_od_cc_sent_tbl();

    CURSOR c_main IS
      SELECT *
        FROM OD_ABL_CONS_TBL
       ORDER BY op_unit
               ,oracle_acct_no;

    l_request_id NUMBER;

  BEGIN

    truncate_table('xxfin.xx_ar_abl_od_cons_sent');	--Version 1C
	
	--Version 1C - modified to insert
    l_sql := 'insert into xx_ar_abl_od_cons_sent (SELECT /*+ PARALLEL(xxa) */ xxa.customer_trx_id,xxa.inv_type,trunc(xxa.creation_date),''CERTEGY''
			FROM xx_ar_cbi_trx_history xxa
		 WHERE xxa.inv_type NOT IN (''SOFTHDR_TOTALS'', ''BILLTO_TOTALS'', ''GRAND_TOTAL'')
			 AND xxa.attribute1 = ''PAYDOC'' AND trunc(xxa.creation_date) > ''' ||
             l_p_as_of_date || '''
		UNION
		SELECT /*+ PARALLEL(xxa) */ xxa.customer_trx_id,xxa.inv_type ,trunc(xxa.creation_date),''SPECIAL HANDLING''
			FROM xx_ar_cbi_rprn_trx_history xxa
		 WHERE xxa.inv_type NOT IN (''SOFTHDR_TOTALS'', ''BILLTO_TOTALS'', ''GRAND_TOTAL'')
			 AND xxa.attribute1 = ''PAYDOC'' AND xxa.created_by = 90102 AND trunc(xxa.creation_date) > ''' ||
             l_p_as_of_date || '''
		UNION
		SELECT /*+ PARALLEL(aci) */acit.customer_trx_id
					,decode(acit.transaction_type,
									''INVOICE'',
									''INV'',
									''CREDIT_MEMO'',
									''CM'')
					,nvl(to_date(aci.attribute1) - 1,trunc(cut_off_date - 1)),''EBILL''
			FROM ar_cons_inv_trx_all acit,ar_cons_inv_all     aci
		 WHERE acit.cons_inv_id = aci.cons_inv_id AND nvl(to_date(aci.attribute1) - 1,trunc(cut_off_date - 1)) > ''' ||  --modified aci.creation_date > codition per issue raised
             l_p_as_of_date ||
             ''' AND aci.attribute4 IS NOT NULL
		UNION
		SELECT /*+ PARALLEL(xxa) */xxa.customer_trx_id
					,decode(xxa.transaction_class,
									''Invoice'',
									''INV'',
									''Credit Memo'',
									''CM'')
					,trunc(xxa.creation_date),xxa.billdocs_delivery_method 
			FROM xx_ar_ebl_cons_hdr_hist xxa
		WHERE upper(xxa.document_type) = ''PAYDOC'' AND trunc(xxa.creation_date) > ''' ||
             l_p_as_of_date || ''')';

    EXECUTE IMMEDIATE l_sql;

    l_sql := 'insert /*+ append */ into OD_ABL_CONS_TBL oac SELECT rct.org_id op_unit
					,hca.account_number oracle_acct_no
					,aps.amount_due_remaining open_amt
					,aps.amount_due_original org_amt
					,to_char(rct.trx_number) transaction_number
					,xxa.print_date print_date
					,rct.trx_date invoice_date
					,aps.due_date due_date
					,xxa.lgnd legend
					,''N'' exception_item
					,REPLACE(hca.account_name,
									 '', '',
									 '' '') customer
					,xxa.del_method delivery_method
					,null status
			FROM ra_customer_trx_all      rct
					,ar_payment_schedules_all aps
					,hz_cust_accounts_all     hca
					,xx_ar_abl_od_cons_sent          xxa
		 WHERE 1 = 1
			 AND rct.trx_date <= :p_trx_date
			 AND rct.customer_trx_id = xxa.customer_trx_id
			 AND rct.customer_trx_id = aps.customer_trx_id
			 AND rct.bill_to_customer_id = hca.cust_account_id';

    EXECUTE IMMEDIATE l_sql
      USING l_p_as_of_date;

    COMMIT;

    fnd_file.put_line(fnd_file.output,
                      l_header);

    OPEN c_main;
    LOOP
      FETCH c_main BULK COLLECT
        INTO l_tab LIMIT 1000;
      EXIT WHEN l_tab.COUNT = 0;

      FOR i IN l_tab.FIRST .. l_tab.LAST
      LOOP
        fnd_file.put_line(fnd_file.output,
                          '"' || l_tab(i).op_unit || '"|"' || l_tab(i)
                          .oracle_acct_no || '"|"' || l_tab(i)
                          .customer || '"|"' || l_tab(i)
                          .open_amt || '"|"' || l_tab(i)
                          .org_amt || '"|"' || l_tab(i)
                          .transaction_number || '"|"' || l_tab(i)
                          .invoice_date || '"|"' || l_tab(i)
                          .due_date || '"|"' || l_tab(i)
                          .print_date || '"|"' || l_tab(i)
                          .legend || '"|"' || l_tab(i).exception_item || '"');
      END LOOP;

    END LOOP;
    CLOSE c_main;

    --drop_table('xxfin.xx_ar_abl_od_cons_sent');

  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,
                        'Error occured due to ' || chr(13) || SQLERRM);
  END cons_sent_invoices;

  PROCEDURE cons_unsent_invoices
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  ) IS

    l_sql VARCHAR2(4000);

    l_p_as_of_date DATE := trunc(to_date(p_as_of_date,
                                         'RRRR/MM/DD HH24:MI:SS'));

    l_p_as_of_date1 DATE := l_p_as_of_date + 1;

    l_p_as_of_date2 DATE := l_p_as_of_date;

    l_p_as_of_date3 DATE := l_p_as_of_date + 1;

    TYPE t_od_cc_sent_tbl IS TABLE OF OD_ABL_CONS_TBL%ROWTYPE;

    l_tab t_od_cc_sent_tbl := t_od_cc_sent_tbl();

    CURSOR c_main IS
      SELECT *
        FROM OD_ABL_CONS_TBL
       ORDER BY op_unit
               ,oracle_acct_no;

  BEGIN

    truncate_table('xxfin.xx_ar_abl_cbe1');		--Version 1C
	
	--Version 1C - modified to insert
    l_sql := 'Insert into xx_ar_abl_cbe1  select /*+ parallel (XCEB) */ XCEB.c_ext_attr3, XCEB.c_ext_attr4, XCEB.c_ext_attr14,
XCEB.cust_account_id, XCEB.d_ext_attr1, XCEB.d_ext_attr2,xceb.attr_group_id,xceb.c_ext_attr2,xceb.c_ext_attr1 from xx_cdh_cust_acct_ext_b XCEB where
XCEB.c_ext_attr1 = ''Consolidated Bill'' AND XCEB.c_ext_attr2 = ''Y'' AND XCEB.attr_group_id = 166';

    EXECUTE IMMEDIATE l_sql;

    l_sql := 'insert /*+ append nologging */ into OD_ABL_CONS_TBL oac SELECT /*+ leading (xceb) parallel (xceb) */ aci.org_id ,hca.account_number ,aps.amount_due_remaining ,aps.amount_due_original ,to_char(acit.trx_number)
			,xx_ar_inv_freq_pkg.compute_effective_date(xceb.c_ext_attr14,trunc(aci.cut_off_date - 1)),acit.transaction_date ,aps.due_date
			,decode(acit.transaction_type,''INVOICE'', ''INV'', ''CREDIT_MEMO'', ''CM''),''N'',REPLACE(hca.account_name,'','','' '')
			,decode(xceb.c_ext_attr3, ''PRINT'',nvl2(xceb.c_ext_attr4,''SPECIAL HANDLING'',''CERTEGY''),''EDI'',''EDI'',''ELEC'',''EBILL'',''ePDF'',''ePDF'',''eXLS'',''eXLS'',''eTXT'',''eTXT'',NULL)
			,null status
	FROM hz_cust_accounts_all hca,xx_ar_abl_cbe1 xceb,ar_cons_inv_all aci,ar_cons_inv_trx_all acit,ar_payment_schedules_all aps,ra_customer_trx_all rct
 WHERE xceb.cust_account_id = hca.cust_account_id AND hca.cust_account_id = aci.customer_id AND acit.cons_inv_id = aci.cons_inv_id
	 AND acit.transaction_type IN (''INVOICE'', ''CREDIT_MEMO'') AND aps.customer_trx_id = acit.customer_trx_id AND aci.customer_id = hca.cust_account_id
	 AND acit.customer_trx_id = rct.customer_trx_id AND aci.attribute2 IS NULL AND aci.attribute4 IS NULL AND aci.attribute10 IS NULL AND aci.attribute15 IS NULL
	 AND aci.status = ''ACCEPTED'' AND hca.attribute18 IN (''CONTRACT'', ''DIRECT'') AND aci.attribute1 IS NULL
	 AND xx_ar_inv_freq_pkg.compute_effective_date(xceb.c_ext_attr14, trunc(aci.cut_off_date - 1)) > :l_p_as_of_date
	 AND rct.trx_date <= :l_p_as_of_date1 AND rct.trx_date BETWEEN xceb.d_ext_attr1 AND nvl(xceb.d_ext_attr2, SYSDATE + 1)
UNION
SELECT /*+ leading (xceb) parallel (xceb) */ aci.org_id ,hca.account_number ,aps.amount_due_remaining ,aps.amount_due_original ,to_char(acit.trx_number)
			,xx_ar_inv_freq_pkg.compute_effective_date(xceb.c_ext_attr14,TO_DATE(aci.attribute1) - 1),acit.transaction_date ,aps.due_date 
			,decode(acit.transaction_type,''INVOICE'', ''INV'', ''CREDIT_MEMO'', ''CM''),''N'',REPLACE(hca.account_name,'','','' '')
			,decode(xceb.c_ext_attr3, ''PRINT'',nvl2(xceb.c_ext_attr4,''SPECIAL HANDLING'',''CERTEGY''),''EDI'',''EDI'',''ELEC'',''EBILL'',''ePDF'',''ePDF'',''eXLS'',''eXLS'',''eTXT'',''eTXT'',NULL)
			,null status
	FROM hz_cust_accounts_all hca,xx_ar_abl_cbe1 xceb,ar_cons_inv_all aci,ar_cons_inv_trx_all acit,ar_payment_schedules_all aps,ra_customer_trx_all      rct
 WHERE xceb.cust_account_id = hca.cust_account_id AND hca.cust_account_id = aci.customer_id AND acit.cons_inv_id = aci.cons_inv_id
	 AND acit.transaction_type IN (''INVOICE'', ''CREDIT_MEMO'') AND aps.customer_trx_id = acit.customer_trx_id AND aci.customer_id = hca.cust_account_id
	 AND acit.customer_trx_id = rct.customer_trx_id AND aci.attribute2 IS NULL AND aci.attribute4 IS NULL AND aci.attribute10 IS NULL AND aci.attribute15 IS NULL
	 AND aci.status = ''ACCEPTED'' AND xceb.c_ext_attr1 = ''Consolidated Bill'' AND xceb.c_ext_attr2 = ''Y'' AND xceb.attr_group_id = 166 AND hca.attribute18 IN (''CONTRACT'', ''DIRECT'')
	 AND aci.attribute1 IS NOT NULL AND xx_ar_inv_freq_pkg.compute_effective_date(xceb.c_ext_attr14,to_date(aci.attribute1) - 1) > :l_p_as_of_date2
	 AND rct.trx_date <= :l_p_as_of_date3 AND rct.trx_date BETWEEN xceb.d_ext_attr1 AND nvl(xceb.d_ext_attr2, SYSDATE + 1)';

    EXECUTE IMMEDIATE l_sql
      USING l_p_as_of_date, l_p_as_of_date1, l_p_as_of_date2, l_p_as_of_date3;

    COMMIT;

    fnd_file.put_line(fnd_file.output,
                      l_header);

    OPEN c_main;
    LOOP
      FETCH c_main BULK COLLECT
        INTO l_tab LIMIT 1000;
      EXIT WHEN l_tab.COUNT = 0;

      FOR i IN l_tab.FIRST .. l_tab.LAST
      LOOP
        fnd_file.put_line(fnd_file.output,
                          '"' || l_tab(i).op_unit || '"|"' || l_tab(i)
                          .oracle_acct_no || '"|"' || l_tab(i)
                          .customer || '"|"' || l_tab(i)
                          .open_amt || '"|"' || l_tab(i)
                          .org_amt || '"|"' || l_tab(i)
                          .transaction_number || '"|"' || l_tab(i)
                          .invoice_date || '"|"' || l_tab(i)
                          .due_date || '"|"' ||  l_tab(i)
                          .print_date || '"|"' ||l_tab(i)
                          .legend || '"|"' || l_tab(i).exception_item || '"');
      END LOOP;

    END LOOP;
    CLOSE c_main;

    --drop_table('xxfin.xx_ar_abl_cbe1');

  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,
                        'Error occured due to ' || chr(13) || SQLERRM);

  END cons_unsent_invoices;

  PROCEDURE ind_sent_unsent_invoices
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  ) IS

    l_sql VARCHAR2(4000);

    l_p_as_of_date DATE := trunc(to_date(p_as_of_date,
                                         'RRRR/MM/DD HH24:MI:SS'));

    TYPE t_od_cc_sent_tbl IS TABLE OF OD_ABL_CONS_TBL%ROWTYPE;

    l_tab t_od_cc_sent_tbl := t_od_cc_sent_tbl();

    CURSOR c_main IS
      SELECT *
        FROM OD_ABL_CONS_TBL
       ORDER BY op_unit
               ,oracle_acct_no;

  BEGIN

    truncate_table('xxfin.xx_ar_abl_arif'); --Version 1C
	
	--Version 1C - modified to insert
    l_sql := 'insert into xx_ar_abl_arif  select /*+ PARALLEL(XAIF) */XAIF.Actual_print_date ,DECODE(XAIF.doc_delivery_method, ''PRINT'',NVL2(XAIF.BILLDOCS_SPECIAL_HANDLING,''SPECIAL HANDLING'',''CERTEGY'')
									 , ''EDI'', ''EDI'' , ''ELEC'' , ''EBILL'' , ''ePDF'', ''ePDF'' , ''eXLS'', ''eXLS'' ,  ''eTXT'', ''eTXT'', NULL)  ,XAIF.invoice_id,''SENT'' from xx_ar_invoice_freq_history  XAIF
 where XAIF.paydoc_flag                = ''Y''
	AND trunc(XAIF.Actual_print_date)        >  ''' || l_p_as_of_date || '''
union
select /*+ PARALLEL(XAIF) */ XAIF.estimated_print_date ,DECODE(XAIF.doc_delivery_method, ''PRINT'',NVL2(XAIF.BILLDOCS_SPECIAL_HANDLING,''SPECIAL HANDLING'',''CERTEGY'')
									 , ''EDI'', ''EDI'', ''ELEC'' , ''EBILL'', ''ePDF'', ''ePDF'', ''eXLS'', ''eXLS'', ''eTXT'', ''eTXT'', NULL),XAIF.invoice_id,''UNSENT''
FROM xx_ar_invoice_frequency     XAIF
where XAIF.paydoc_flag                 = ''Y''
AND NVL(XAIF.printed_flag,''N'')         <> ''Y''
AND trunc(XAIF.estimated_print_date)   > ''' || l_p_as_of_date || '''';

    EXECUTE IMMEDIATE l_sql;


    l_sql := 'insert /*+ append nologging */ into OD_ABL_CONS_TBL oac SELECT /*+ PARALLEL(xaif) */rct.org_id,hca.account_number,aps.amount_due_remaining,aps.amount_due_original,to_char(rct.trx_number),xaif.scheduled_print_date,rct.trx_date,aps.due_date
			,rctt.TYPE,''N'',REPLACE(hp.party_name,'','','' ''),xaif.delivery_method,xaif.status
	FROM xx_ar_abl_arif xaif,ra_cust_trx_types_all rctt,ra_customer_trx_all rct,ar_payment_schedules_all aps,hz_parties hp,hz_cust_accounts_all hca
 WHERE rct.customer_trx_id = xaif.invoice_id AND rctt.cust_trx_type_id = rct.cust_trx_type_id AND rct.customer_trx_id = aps.customer_trx_id
	 AND hca.party_id = hp.party_id AND hca.cust_account_id = rct.bill_to_customer_id AND rct.trx_date <= :l_p_as_of_date';

    EXECUTE IMMEDIATE l_sql
      USING l_p_as_of_date;

    COMMIT;

    fnd_file.put_line(fnd_file.output,
                      l_header);

    OPEN c_main;
    LOOP
      FETCH c_main BULK COLLECT
        INTO l_tab LIMIT 1000;
      EXIT WHEN l_tab.COUNT = 0;

      FOR i IN l_tab.FIRST .. l_tab.LAST
      LOOP
        fnd_file.put_line(fnd_file.output,
                          '"' || l_tab(i).op_unit || '"|"' || l_tab(i)
                          .oracle_acct_no || '"|"' || l_tab(i)
                          .customer || '"|"' || l_tab(i)
                          .open_amt || '"|"' || l_tab(i)
                          .org_amt || '"|"' || l_tab(i)
                          .transaction_number || '"|"' || l_tab(i)
                          .invoice_date || '"|"' || l_tab(i)
                          .due_date || '"|"' || l_tab(i)
                          .print_date || '"|"' || l_tab(i)
                          .legend || '"|"' || l_tab(i).exception_item || '"');
      END LOOP;

    END LOOP;
    CLOSE c_main;
    --drop_table('xxfin.xx_ar_abl_arif');
  END ind_sent_unsent_invoices;

  PROCEDURE ind_unbilled
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  ) IS
    l_sql VARCHAR2(4000);

    l_p_as_of_date DATE := trunc(to_date(p_as_of_date,
                                         'RRRR/MM/DD HH24:MI:SS'));

    l_p_as_of_date1 DATE := l_p_as_of_date + 1;

    l_p_as_of_date2 DATE := l_p_as_of_date + 1;

    TYPE t_od_cc_sent_tbl IS TABLE OF OD_ABL_CONS_TBL%ROWTYPE;

    l_tab t_od_cc_sent_tbl := t_od_cc_sent_tbl();

    CURSOR c_main IS
      SELECT *
        FROM OD_ABL_CONS_TBL
       ORDER BY op_unit
               ,oracle_acct_no;
  BEGIN

    truncate_table('xxfin.xx_ar_abl_xceb_inv');	--Version 1C
	
	--Version 1C - modified to insert	 
    l_sql := 'insert into xx_ar_abl_xceb_inv  select XCCA.c_ext_attr14,DECODE(XCCA.c_ext_attr3, ''PRIN'',NVL2(XCCA.c_ext_attr4,''SPECIAL HANDLING'',''CERTEGY''),''EDI'', ''EDI'' , ''ELEC'',''EBILL'',''ePDF'',''ePDF'',''eXLS'', ''eXLS'',  ''eTXT'', ''eTXT'',NULL)
							 ,XCCA.cust_account_id,XCCA.d_ext_attr1,XCCA.d_ext_attr2,xcca.attr_group_id,XCCA.extension_id
							 from xx_cdh_cust_acct_ext_b  XCCA
							 where XCCA.attr_group_id   = 166
							 AND XCCA.C_EXT_ATTR1 = ''Invoice''
							 AND XCCA.C_EXT_ATTR2 = ''Y'' AND trunc(XCCA.creation_date) > ''' ||
             l_p_as_of_date || '''';

    EXECUTE IMMEDIATE l_sql;

    l_sql := 'insert /*+ append nologging */ into OD_ABL_CONS_TBL oac SELECT /*+ PARALLEL(XCCA) */ RCT.org_id,HCA.account_number,APS.amount_due_remaining,APS.amount_due_original,to_char(RCT.trx_number),xx_ar_inv_freq_pkg.compute_effective_date(XCCA.c_ext_attr14,trunc(TO_DATE(RCT.creation_date))),RCT.trx_date,APS.Due_date
			,RCTT.TYPE,''Y'',REPLACE(Hca.account_name,'','','' ''),XCCA.delivery_method,null
FROM  ra_customer_trx_all RCT,ra_cust_trx_types_all RCTT,ar_payment_schedules_all APS,hz_cust_accounts_all HCA,xx_ar_abl_xceb_inv XCCA
WHERE RCT.customer_trx_id = APS.customer_trx_id AND RCTT.cust_trx_type_id = RCT.cust_trx_type_id AND RCT.bill_to_customer_id = HCA.cust_account_id
AND   RCT.bill_to_customer_id = XCCA.cust_account_id AND   XCCA.attr_group_id   = 166 AND   NOT EXISTS ( SELECT 1 FROM   xx_ar_invoice_freq_history  XAIH WHERE  XAIH.invoice_id = RCT.customer_trx_id AND XAIH.extension_id = XCCA.extension_id)
AND   APS.amount_due_original NOT BETWEEN 0 AND 0.5 AND    NOT EXISTS (SELECT 1 FROM xx_om_return_tenders_All ort WHERE ort.header_id = RCT.attribute14)
AND   RCTT.TYPE=''CM'' AND  RCT.trx_date BETWEEN XCCA.d_ext_attr1 AND NVL(XCCA.d_ext_attr2,SYSDATE+1) AND RCT.trx_date <= :l_p_as_of_date1
UNION
SELECT /*+ PARALLEL(XCCA) */ RCT.org_id,HCA.account_number,APS.amount_due_remaining,APS.amount_due_original,to_char(RCT.trx_number),xx_ar_inv_freq_pkg.compute_effective_date(XCCA.c_ext_attr14,trunc(TO_DATE(RCT.creation_date))),RCT.trx_date,APS.Due_date
			,RCTT.TYPE,''Y'',REPLACE(Hca.account_name,'','','' ''),XCCA.delivery_method,null
FROM  ra_customer_trx_all RCT,ra_cust_trx_types_all RCTT,ar_payment_schedules_all APS,hz_cust_accounts_all HCA,xx_ar_abl_xceb_inv XCCA
WHERE RCT.customer_trx_id = APS.customer_trx_id AND RCTT.cust_trx_type_id = RCT.cust_trx_type_id AND RCT.bill_to_customer_id= HCA.cust_account_id AND RCT.bill_to_customer_id = XCCA.cust_account_id
AND   XCCA.attr_group_id   = 166 AND   NOT EXISTS ( SELECT 1 FROM xx_ar_invoice_freq_history  XAIH WHERE XAIH.invoice_id = RCT.customer_trx_id AND    XAIH.extension_id = XCCA.extension_id)
AND   APS.amount_due_original NOT BETWEEN 0 AND 0.5 AND   NOT EXISTS (SELECT 1 FROM oe_payments op WHERE op.header_id = RCT.attribute14 AND OP.attribute11 <> ''18'' )
AND   RCTT.TYPE=''INV'' AND  RCT.trx_date BETWEEN XCCA.d_ext_attr1 and NVL(XCCA.d_ext_attr2,sysdate+1) AND RCT.trx_date <= :l_p_as_of_date2';

    EXECUTE IMMEDIATE l_sql
      USING l_p_as_of_date1, l_p_as_of_date2;

    COMMIT;

    fnd_file.put_line(fnd_file.output,
                      l_header);

    OPEN c_main;
    LOOP
      FETCH c_main BULK COLLECT
        INTO l_tab LIMIT 1000;
      EXIT WHEN l_tab.COUNT = 0;

      FOR i IN l_tab.FIRST .. l_tab.LAST
      LOOP
        fnd_file.put_line(fnd_file.output,
                          '"' || l_tab(i).op_unit || '"|"' || l_tab(i)
                          .oracle_acct_no || '"|"' || l_tab(i)
                          .customer || '"|"' || l_tab(i)
                          .open_amt || '"|"' || l_tab(i)
                          .org_amt || '"|"' || l_tab(i)
                          .transaction_number || '"|"' ||  l_tab(i)
                          .invoice_date || '"|"' || l_tab(i)
                          .due_date || '"|"'  || l_tab(i)
                          .print_date || '"|"' || l_tab(i)
                          .legend || '"|"' || l_tab(i).exception_item || '"');
      END LOOP;

    END LOOP;
    CLOSE c_main;

    --drop_table('xxfin.xx_ar_abl_xceb_inv');

  END ind_unbilled;

  PROCEDURE cons_unsent_non_cons
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  ) IS

    l_sql VARCHAR2(4000);

    l_p_as_of_date DATE := trunc(to_date(p_as_of_date,
                                         'RRRR/MM/DD HH24:MI:SS'));

    l_p_as_of_date1 DATE := l_p_as_of_date - 210;
    l_p_as_of_date2 DATE := l_p_as_of_date - 240;
    l_p_as_of_date3 DATE := l_p_as_of_date - 1;

  BEGIN
    truncate_table('xxfin.xx_ar_abl_rct_5');
    truncate_table('xxfin.xx_ar_abl_cbe1_5');
    truncate_table('xxfin.xx_ar_abl_cons_unsent_non_5');	--Vesrion 1C
	
	--Version 1C - modified to insert
    l_sql := 'insert into xx_ar_abl_rct_5 
							SELECT /*+ parallel (rct) full(rct) */
										 rct.creation_date, rct.customer_trx_id, rct.org_id, rct.printing_pending, rct.trx_date
									 , rct.trx_number, rct.bill_to_customer_id, RCT.cust_trx_type_id
								FROM ra_customer_trx_all rct WHERE NOT EXISTS (SELECT /*+ parallel(acit) full(acit) */ 1
															 FROM ar_cons_inv_trx_all acit WHERE acit.customer_trx_id = RCT.customer_Trx_id )
								AND rct.trx_date BETWEEN ''' || l_p_as_of_date1 ||
             ''' AND ''' || l_p_as_of_date3 || ''' AND trunc(RCT.creation_date) > ''' ||
             l_p_as_of_date2 || '''';

    EXECUTE IMMEDIATE l_sql;
	
	--Version 1C - modified to insert
    l_sql := 'insert into xx_ar_abl_cbe1_5 select /*+ parallel (XCEB) */ XCEB.c_ext_attr3, XCEB.c_ext_attr4, XCEB.c_ext_attr14,
							XCEB.cust_account_id, XCEB.d_ext_attr1, XCEB.d_ext_attr2 from xx_cdh_cust_acct_ext_b XCEB where XCEB.c_ext_attr1 = ''Consolidated Bill''  AND XCEB.c_ext_attr2 = ''Y''  AND XCEB.attr_group_id = 166';

    EXECUTE IMMEDIATE l_sql;
	
	--Version 1C - modified to insert
    l_sql := 'insert into xx_ar_abl_cons_unsent_non_5 (id,customer_Trx_id,creation_date,org_id,PRINTING_PENDING,account_number,amount_due_remaining,amount_due_original,
	trx_number,trx_date,Due_date,c_ext_attr14,TYPE,exception_item,customer,Delivery_Method) 
SELECT /* leading (RCT) index (RCT RA_CUSTOMER_TRX_N5) parallel (RCT) */
1 id,rct.customer_trx_id,rct.creation_date, RCT.org_id,rct.PRINTING_PENDING,HCA.account_number,APS.amount_due_remaining,APS.amount_due_original,TO_CHAR(RCT.trx_number)
,RCT.trx_date,APS.Due_date,XCEB.c_ext_attr14,RCTT.TYPE,''N'',REPLACE(Hca.account_name,'','','' ''),DECODE(XCEB.c_ext_attr3, ''PRINT'',NVL2(XCEB.c_ext_attr4,''SPECIAL HANDLING'',''CERTEGY'')
									 , ''EDI'', ''EDI'', ''ELEC'' , ''EBILL'', ''ePDF'', ''ePDF'', ''eXLS'', ''eXLS'', ''eTXT'', ''eTXT'', NULL)
FROM ra_cust_trx_types_all RCTT ,xx_ar_abl_rct_5 RCT,ar_payment_schedules_all APS,hz_cust_accounts HCA,xx_ar_abl_cbe1_5 XCEB
WHERE  XCEB.cust_account_id = HCA.cust_account_id  AND    HCA.cust_account_id  = RCT.bill_to_customer_id AND    RCTT.cust_trx_type_id = RCT.cust_trx_type_id
AND    RCT.customer_trx_id = APS.customer_trx_id AND    HCA.attribute18 IN(''CONTRACT'',''DIRECT'') AND    APS.exclude_from_cons_bill_flag IS NULL
AND    RCT.trx_date BETWEEN XCEB.d_ext_attr1 and NVL(XCEB.d_ext_attr2,sysdate+1)';

    EXECUTE IMMEDIATE l_sql;

		--EXECUTE IMMEDIATE 'alter table xxfin.xx_ar_abl_cons_unsent_non_5 add xx_func_2 date';	--Version 1C

    EXECUTE IMMEDIATE 'UPDATE xx_ar_abl_cons_unsent_non_5 xceb SET xx_func_2 = xx_ar_inv_freq_pkg.compute_effective_date(xceb.c_ext_attr14,trunc(xceb.creation_date))';

    COMMIT;

    --EXECUTE IMMEDIATE 'alter table xxfin.xx_ar_abl_cons_unsent_non_5 add xx_func_1 date';	--Version 1C

    EXECUTE IMMEDIATE 'UPDATE xx_ar_abl_cons_unsent_non_5 xceb SET xx_func_1 = xx_ar_inv_freq_pkg.compute_effective_date(xceb.c_ext_attr14,xceb.trx_date)';

    COMMIT;

    EXECUTE IMMEDIATE 'DELETE FROM xx_ar_abl_cons_unsent_non_5 WHERE xx_func_1 < ''' ||
                      l_p_as_of_date3 || '''';

    COMMIT;

    fnd_file.put_line(fnd_file.output,
                      l_header);

    l_sql := 'declare
							TYPE t_od_cc_sent_tbl IS TABLE OF xx_ar_abl_cons_unsent_non_5%ROWTYPE;
							l_tab t_od_cc_sent_tbl := t_od_cc_sent_tbl();

							CURSOR c_main IS
								SELECT * FROM xx_ar_abl_cons_unsent_non_5 ORDER BY org_id,account_number;
							begin
								 OPEN c_main;
		LOOP
			FETCH c_main BULK COLLECT
				INTO l_tab LIMIT 1000;
			EXIT WHEN l_tab.COUNT = 0;

			FOR i IN l_tab.FIRST .. l_tab.LAST
			LOOP
				fnd_file.put_line(fnd_file.output,
													''"'' || l_tab(i).org_id || ''"|"'' || l_tab(i)
													.account_number || ''"|"'' || l_tab(i)
													.customer || ''"|"'' || l_tab(i)
													.amount_due_remaining || ''"|"'' || l_tab(i)
													.amount_due_original || ''"|"'' || l_tab(i)
													.trx_number || ''"|"'' || l_tab(i)
													.trx_date || ''"|"'' || l_tab(i)
													.due_date || ''"|"'' || l_tab(i)
													.xx_func_2 || ''"|"'' || l_tab(i)
													.TYPE || ''"|"'' || l_tab(i)
													.exception_item || ''"'');
			END LOOP;

		 END LOOP;
		 CLOSE c_main;
		end;';

    EXECUTE IMMEDIATE l_sql;

    --drop_table('xxfin.xx_ar_abl_rct_5');
    --drop_table('xxfin.xx_ar_abl_cbe1_5');
    --drop_table('xxfin.xx_ar_abl_cons_unsent_non_5');

  END cons_unsent_non_cons;

  PROCEDURE ind_unsent_non_ind
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  ) IS

    l_sql VARCHAR2(4000);

    l_p_as_of_date DATE := trunc(to_date(p_as_of_date,
                                         'RRRR/MM/DD HH24:MI:SS'));

    l_p_as_of_date1 DATE := l_p_as_of_date - 210;
    l_p_as_of_date2 DATE := l_p_as_of_date - 240;
    l_p_as_of_date3 DATE := l_p_as_of_date - 1;

    ln_set_print_options BOOLEAN;

  BEGIN
    truncate_table('xxfin.xx_ar_abl_rct_6');
    truncate_table('xxfin.xx_ar_abl_cbe_inv_6');
    truncate_table('xxfin.xx_ar_abl_ind_unsent_non_6');	--Version 1C
	
	--Version 1C - modified to insert
    l_sql := 'insert into xx_ar_abl_cbe_inv_6  select /*+ parallel (XCEB) */ xceb.c_Ext_attr14, xceb.c_ext_attr3, xceb.c_ext_attr4, xceb.cust_account_id, xceb.c_ext_attr2,xceb.d_ext_attr1,xceb.d_ext_attr2,XCEB.creation_date
from xx_cdh_cust_acct_ext_b XCEB where XCEB.c_ext_attr1 = ''Invoice'' AND XCEB.c_ext_attr2 = ''Y'' AND XCEB.attr_group_id = 166 ';

    EXECUTE IMMEDIATE l_sql;
	
	--Version 1C - modified to insert
    l_sql := 'insert into xx_ar_abl_rct_6  select /*+ parallel (RCT) full(rct) */  rct.creation_date, rct.customer_trx_id, rct.org_id,rct.attribute14, rct.printing_pending, rct.trx_date,  rct.trx_number, rct.bill_to_customer_id , RCT.cust_trx_type_id
from ra_customer_trx_all rct where rct.attribute15 = ''N'' and RCT.INTERFACE_HEADER_CONTEXT = ''ORDER ENTRY'' and rct.trx_date <= ''' ||
             l_p_as_of_date || ''' AND  trunc(RCT.creation_date) > ''' ||
             l_p_as_of_date2 || '''';

    EXECUTE IMMEDIATE l_sql;
	
	--Version 1C - modified to insert
    l_sql := 'insert into xx_ar_abl_ind_unsent_non_6(org_id,attribute14,creation_Date,customer_Trx_id,account_number,amount_due_remaining,amount_due_original,
	trx_number,trx_date,Due_date,TYPE,c_ext_attr14,customer,CREATION_DATE1,Delivery_Method) 
SELECT RCT.org_id,RCT.attribute14,rct.creation_Date,rct.customer_Trx_id,HCA.account_number,APS.amount_due_remaining,APS.amount_due_original,TO_CHAR(RCT.trx_number)
,RCT.trx_date,APS.Due_date,RCTT.TYPE,XCEB.c_ext_attr14,REPLACE(Hca.account_name,'','','' ''),XCEB.creation_date
,DECODE(XCEB.c_ext_attr3, ''PRINT'',NVL2(XCEB.c_ext_attr4,''SPECIAL HANDLING'',''CERTEGY''), ''EDI'', ''EDI'', ''ELEC'' , ''EBILL'', ''ePDF'', ''ePDF'', ''eXLS'', ''eXLS'', ''eTXT'', ''eTXT'', NULL)
FROM ra_cust_trx_types_all RCTT ,xx_ar_abl_rct_6  RCT,ar_payment_schedules_all APS,hz_cust_accounts HCA,xx_ar_abl_cbe_inv_6 XCEB,oe_order_headers_all OOH
WHERE  XCEB.cust_account_id = HCA.cust_account_id AND HCA.cust_account_id = RCT.bill_to_customer_id AND RCTT.cust_trx_type_id = RCT.cust_trx_type_id
AND    RCT.customer_trx_id = APS.customer_trx_id AND RCT.attribute14 = OOH.header_id AND OOH.order_source_id  NOT IN (1006,1025,1027) AND    HCA.attribute18 IN (''CONTRACT'',''DIRECT'')
AND    APS.amount_due_original NOT BETWEEN 0 AND 0.50 AND RCT.trx_date BETWEEN XCEB.d_ext_attr1 and NVL(XCEB.d_ext_attr2,sysdate+1)';

    EXECUTE IMMEDIATE l_sql;

    --EXECUTE IMMEDIATE 'Alter table xxfin.xx_ar_abl_ind_unsent_non_6 add scheduled_print_date DATE'; 		--Version 1C

    EXECUTE IMMEDIATE 'update xx_ar_abl_ind_unsent_non_6 XCEB set scheduled_print_date = xx_ar_inv_freq_pkg.compute_effective_date(XCEB.c_ext_attr14, trunc(TO_DATE(XCEB.creation_date)))';

    COMMIT;

    --EXECUTE IMMEDIATE 'Alter table xxfin.xx_ar_abl_ind_unsent_non_6 add xx_func2 VARCHAR2(100)'; 		--Version 1C

    EXECUTE IMMEDIATE 'update xx_ar_abl_ind_unsent_non_6 SCEB set xx_func2 = DECODE(SCEB.type,''INV'',xx_ar_inv_freq_pkg.gift_card_inv( SCEB.customer_Trx_id
																		 ,SCEB.attribute14),''CM'',xx_ar_inv_freq_pkg.gift_card_cm( SCEB.customer_Trx_id,SCEB.attribute14),''N'')';
    COMMIT;

    EXECUTE IMMEDIATE 'delete from xx_ar_abl_ind_unsent_non_6 where nvl(xx_func2,''N'') = ''N''';

    COMMIT;

    fnd_file.put_line(fnd_file.output,
                      l_header);

    l_sql := 'declare
							TYPE t_od_cc_sent_tbl IS TABLE OF xx_ar_abl_ind_unsent_non_6%ROWTYPE;
							l_tab t_od_cc_sent_tbl := t_od_cc_sent_tbl();

							CURSOR c_main IS
								SELECT * FROM xx_ar_abl_ind_unsent_non_6 ORDER BY org_id,account_number;
							begin
								 OPEN c_main;
		LOOP
			FETCH c_main BULK COLLECT
				INTO l_tab LIMIT 1000;
			EXIT WHEN l_tab.COUNT = 0;

			FOR i IN l_tab.FIRST .. l_tab.LAST
			LOOP
				fnd_file.put_line(fnd_file.output,
													''"'' ||
													 l_tab(i).org_id                || ''"|"'' ||
													 l_tab(i).account_number        || ''"|"'' ||
													 l_tab(i).customer              || ''"|"'' ||
													 l_tab(i).amount_due_remaining  || ''"|"'' ||
													 l_tab(i).amount_due_original   || ''"|"'' ||
													 l_tab(i).trx_number            || ''"|"'' ||													 
													 l_tab(i).trx_date              || ''"|"'' ||
													 l_tab(i).due_date              || ''"|"'' || 
													 l_tab(i).scheduled_print_date  || ''"|"'' ||
													 l_tab(i).TYPE                  || ''"|"'' ||
													 ''N''                          || ''"'');
			END LOOP;

		 END LOOP;
		 CLOSE c_main;
		end;';

    EXECUTE IMMEDIATE l_sql;

    --drop_table('xxfin.xx_ar_abl_rct_6');
    --drop_table('xxfin.xx_ar_abl_cbe_inv_6');
    --drop_table('xxfin.xx_ar_abl_ind_unsent_non_6');

  END ind_unsent_non_ind;

  PROCEDURE sumbit_conc_program
  (
    p_conc_program            IN VARCHAR2
   ,p_conc_program_short_name IN VARCHAR2
   ,p_application             IN VARCHAR2
   ,p_date                    IN VARCHAR2
  ) IS
    l_request_id       NUMBER;
    l_phase            VARCHAR2(200);
    l_status           VARCHAR2(200);
    l_dev_phase        VARCHAR2(200);
    l_dev_status       VARCHAR2(200);
    l_message          VARCHAR2(200);
    l_wait_for_request BOOLEAN;
    l_conc_comp_status BOOLEAN;

  BEGIN

    l_request_id := fnd_request.submit_request(application => p_application,
                                                    program     => p_conc_program_short_name,
                                                    description => p_conc_program,
                                                    start_time  => to_char(SYSDATE,
                                                                           'DD-MON-YY HH24:MI:SS'),
                                                    sub_request => FALSE,
                                                    argument1   => p_date);

    IF l_request_id = 0
    THEN
      fnd_file.put_line(fnd_file.output,
                        '+----------------------------------------------------------------+');
      fnd_file.put_line(fnd_file.output,
                        '                                                                  ');
      fnd_file.put_line(fnd_file.output,
                        'Concurrent Program ' || p_conc_program ||
                        ' is not invoked');
    ELSE
      COMMIT;

      BEGIN
        -- Wait for completion of request submitted above
        l_wait_for_request := fnd_concurrent.wait_for_request(request_id => l_request_id,
                                                              INTERVAL   => 20,
                                                              max_wait   => '',
                                                              phase      => l_phase,
                                                              status     => l_status,
                                                              dev_phase  => l_dev_phase,
                                                              dev_status => l_dev_status,
                                                              message    => l_message);
        fnd_file.put_line(fnd_file.output,
                          '+---------------------------------------------------------------------------+');
        fnd_file.put_line(fnd_file.output,
                          '                                                                             ');
        fnd_file.put_line(fnd_file.output,
                          p_conc_program || ' ' || l_dev_phase || ' - ' ||
                          l_dev_status);

        IF l_dev_phase = 'COMPLETE'
        THEN
          IF (l_dev_status <> 'NORMAL')
          THEN
            IF (l_dev_status <> 'WARNING')
            THEN
              fnd_file.put_line(fnd_file.output,
                                p_conc_program || ' Program with request id ' ||
                                l_request_id ||
                                ' could not be completed normal');
              l_conc_comp_status := fnd_concurrent.set_completion_status('ERROR',
                                                                         'error');
            ELSE
              fnd_file.put_line(fnd_file.output,
                                p_conc_program || ' Program with request id ' ||
                                l_request_id || ' completed with warning');
              l_conc_comp_status := fnd_concurrent.set_completion_status('WARNING',
                                                                         'warning');
            END IF;
					ELSE
					   fnd_file.put_line(fnd_file.output,
                          p_conc_program || ' program with request id ' ||
                          l_request_id || ' completed normaly');
          END IF;
        ELSE
          fnd_file.put_line(fnd_file.output,
                            p_conc_program || ' program with request id ' ||
                            l_request_id || ' could not be completed normal');
          l_conc_comp_status := fnd_concurrent.set_completion_status('ERROR',
                                                                     'error');
        END IF;


        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,
                            p_conc_program ||
                            ' Wait_for_request, failed to invoke');
      END;
    END IF;

  END sumbit_conc_program;

  PROCEDURE main_process
  (
    x_errbuf     OUT NOCOPY VARCHAR2
   ,x_retcode    OUT NOCOPY NUMBER
   ,p_as_of_date IN VARCHAR2
  ) IS

    ln_mail_request_id NUMBER;

  BEGIN

    sumbit_conc_program(p_conc_program            => 'OD: AR ABL Consolidated Sent Extract',
                        p_conc_program_short_name => 'XX_AR_ABL_CONS_SENT',
                        p_application             => 'XXFIN',
                        p_date                    => p_as_of_date);
    sumbit_conc_program(p_conc_program            => 'OD: AR ABL Consolidated UnSent Extract',
                        p_conc_program_short_name => 'XX_AR_ABL_CONS_UNSENT',
                        p_application             => 'XXFIN',
                        p_date                    => p_as_of_date);
    sumbit_conc_program(p_conc_program            => 'OD: AR ABL Individual Sent and Unsent Extract',
                        p_conc_program_short_name => 'XX_AR_ABL_IND_SENT_UNSENT',
                        p_application             => 'XXFIN',
                        p_date                    => p_as_of_date);
    sumbit_conc_program(p_conc_program            => 'OD: AR ABL Individual Unbilled',
                        p_conc_program_short_name => 'XX_AR_ABL_IND_UNBILLED',
                        p_application             => 'XXFIN',
                        p_date                    => p_as_of_date);
    sumbit_conc_program(p_conc_program            => 'OD: AR ABL Consolidated UnSent Non Extract',
                        p_conc_program_short_name => 'XX_AR_ABL_CONS_UNSENT_NON',
                        p_application             => 'XXFIN',
                        p_date                    => p_as_of_date);
    sumbit_conc_program(p_conc_program            => 'OD: AR ABL Individual UnSent Non Extract',
                        p_conc_program_short_name => 'XX_AR_ABL_IND_UNSENT_NON',
                        p_application             => 'XXFIN',
                        p_date                    => p_as_of_date);

    get_email_address();

    IF l_email_address IS NOT NULL
    THEN
      -- -------------------------------------------
      -- Call the Common Emailer Program
      -- -------------------------------------------
      ln_mail_request_id := fnd_request.submit_request(application => 'xxfin',
                                                       program     => 'XXODROEMAILER',
                                                       description => '',
                                                       sub_request => FALSE,
                                                       start_time  => to_char(SYSDATE,
                                                                              'DD-MON-YY HH:MI:SS'),
                                                       argument1   => '',
                                                       argument2   => l_email_address,
                                                       argument3   => 'OD ABL Extract - ' ||
                                                                      trunc(SYSDATE),
                                                       argument4   => '',
                                                       argument5   => 'Y',
                                                       argument6   => fnd_global.conc_request_id);
      COMMIT;

      IF ln_mail_request_id IS NULL OR
         ln_mail_request_id = 0
      THEN
        fnd_file.put_line(fnd_file.log,
                          'Failed to submit the Standard Common Emailer Program');
      END IF;
    END IF;

  END main_process;

END xx_ar_abl_export_pkg;
/
