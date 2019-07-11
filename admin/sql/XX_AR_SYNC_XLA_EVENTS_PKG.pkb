create or replace 
PACKAGE BODY XX_AR_SYNC_XLA_EVENTS_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:   XX_AR_SYNC_XLA_EVENTS_PKG							|
-- |  Issue:  When a user creates a Receipt/Transaction from respective UI,      		|
-- |          distributions are populated in XLA.  On deletion of Receipt/Transaction		|
-- |          the respective distributions of XLA not get refreshed precisely.			|
-- |  Description: RICE E3093 - AR_SLA_Data_Fixes                                               |
-- |               Deletes the orphaned events from xla_events.Then checks FOR the event_id     |
-- |               in CRH and RA and stamps the event_id IF it IS NULL AND there EXISTS an      |
-- |		   event IN xla_events. Else, script creates a NEW RECORD IN xla_events AND     |
-- |	           stamps IN CRH and RA. 							|
-- |			- Adjustment recurring issue permanent fix added           						|
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         06/11/2014   Avinash Baddam   Initial version                                  |
-- | 1.1         11/11/2014   Madhan Sanjeevi  Adjustment recurring issue permanent fix added   |
-- | 1.2         27/10/2015   Vasu Raparla     Removed Schema References for R12.2              |
-- | 1.3         11/16/2018   Bhargavi Ankolekar  Modified as per the Jira #NAIT-62249          |
-- | 1.4         07/11/2019   Bhargavi Ankolekar  Modified as per the Jira #NAIT-76213          |
-- +============================================================================================+


-- +===================================================================+
-- | Name  : UPDATE_CASH_RCPT_HIST_TS                                             |
-- |                                                                   |
-- | Description: This Procedure Removes timestamps from gl_date       |
-- |                 and trx_date in AR_CASH_RECEIPT_HISTORY_ALL       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE update_cash_rcpt_hist_ts(p_org_id 	 NUMBER
                                  ,p_start_date  DATE
                                  ,p_end_date	 DATE
                                  ,p_err_msg     OUT VARCHAR2)
AS
  l_count NUMBER := 0;
BEGIN
   UPDATE ar_cash_receipt_history_all
      SET gl_date = trunc(gl_date)
         ,trx_date = trunc(trx_date)
    WHERE posting_control_id = -3
      AND event_id is null
      AND org_id = p_org_id
      AND gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR')
                      AND to_date(p_end_date,'DD-MON-RRRR');
   l_count := sql%rowcount;
   FND_FILE.PUT_LINE(FND_FILE.LOG,to_char(l_count)||' row(s) updated in AR_CASH_RECEIPT_HISTORY_ALL for removing timestamp');
   p_err_msg := null;
EXCEPTION
WHEN others THEN
   p_err_msg := 'Error in UPDATE_CASH_RCPT_HIST_TS '||substr(sqlerrm,1,500);
END update_cash_rcpt_hist_ts;


-- +===================================================================+
-- | Name  : debug                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- +===================================================================+
PROCEDURE debug(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

END debug;


FUNCTION print_spaces(n IN number) RETURN Varchar2 IS
      l_return_string varchar2(100);
BEGIN
   SELECT substr('                                                   ',1,n)
     INTO l_return_String
     FROM dual;
   return(l_return_String);
END print_spaces;

-- +===================================================================+
-- | Name  : DEL_ORPHANS_XLA_EVENTS                                    |
-- |                                                                   |
-- | Description:       This Procedure delete the events from          |
-- |                    xla_events                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE del_orphans_xla_events(p_ledger_id	  NUMBER
				,p_read_only_mode VARCHAR2
			        ,p_start_date   DATE
			        ,p_end_date	DATE
			        ,p_err_msg      OUT VARCHAR2)
AS
   l_rule           number;
   l_count          number;

   CURSOR get_orphan_trx_events IS
      SELECT xte.source_id_int_1, xte.entity_id, xe.event_id, xe.event_date,
             xe.event_type_code, xe.event_status_code
        FROM  xla_events xe,
              xla_transaction_entities xte
       WHERE xte.entity_code = 'TRANSACTIONS'
         AND xte.entity_id = xe.entity_id
   	 AND xte.application_id = 222
         AND xte.ledger_id = p_ledger_id
         AND xe.event_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
         AND xe.application_id = 222
         AND xe.event_status_code <> 'P'
         AND NOT EXISTS
   	     (SELECT 'x'
   	        FROM ra_cust_Trx_line_gl_dist_all
               WHERE gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
                 AND customer_trx_id = xte.source_id_int_1
    	         AND posting_control_id = -3
    	         AND event_id = xe.event_id
              UNION
	     SELECT 'x'
	      FROM ar_receivable_applications_all
	     WHERE gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
	       AND customer_trx_id = xte.source_id_int_1
	       AND posting_control_id = -3
	       AND event_id = xe.event_id
	     UNION
	    SELECT 'x'
	      FROM ar_receivable_applications_all
	     WHERE gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
	       AND applied_customer_trx_id = xte.source_id_int_1
	       AND posting_control_id = -3
	       AND event_id = xe.event_id)
    ORDER BY xe.event_id;

   CURSOR get_orphan_rct_events IS
   SELECT xte.source_id_int_1, xte.entity_id, xe.event_id, xe.event_date,
          xe.event_type_code, xe.event_status_code
     FROM xla_events xe, xla_transaction_entities xte
    WHERE xte.application_id = 222
      AND xe.application_id= xte.application_id
      AND xte.ledger_id = p_ledger_id
      AND xe.entity_id = xte.entity_id
      AND xte.entity_code='RECEIPTS'
      AND xe.event_status_code <> 'P'
      AND xe.event_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
      AND NOT EXISTS
	   (SELECT 'x'
	      FROM ar_distributions_all dis, ar_receivable_applications_all ra
	     WHERE ra.cash_receipt_id = xte.source_id_int_1
	       AND dis.source_table = 'RA'
	       AND dis.source_id = ra.receivable_application_id
	       AND ra.gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
	       AND ra.posting_control_id = -3
	       AND ra.event_id = xe.event_id
	    UNION
	    SELECT 'x'
	      FROM ar_distributions_all dis, ar_cash_receipt_history_all crh
	    WHERE crh.cash_receipt_id = xte.source_id_int_1
	    and dis.source_table = 'CRH'
	    and dis.source_id = crh.cash_receipt_history_id
	    and crh.gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
	    and crh.posting_control_id = -3
	    and crh.event_id = xe.event_id
	    UNION
	    SELECT 'x' from ar_distributions_all dis, ar_misc_cash_distributions_all mcd
	    where mcd.cash_receipt_id = xte.source_id_int_1
	    and   dis.source_table = 'MCD'
	    and   dis.source_id = mcd.misc_cash_distribution_id
	    and   mcd.gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
	    and   mcd.posting_control_id = -3
	    and   mcd.event_id = xe.event_id
	    )
   ORDER BY xe.event_id;

   CURSOR get_orphan_adj_events IS
   SELECT xte.source_id_int_1, xte.entity_id, xe.event_id, xe.event_date, xe.event_type_code, xe.event_status_code
     FROM xla_events xe, xla_transaction_entities xte
    WHERE xte.entity_code = 'ADJUSTMENTS'
      and xte.entity_id = xe.entity_id
      and xte.application_id = 222
      and xte.ledger_id = p_ledger_id
      and xe.event_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
      and xe.application_id = 222
      and xe.event_status_code <> 'P'
      and not exists
	   (select 'x' from ar_adjustments_all
	    where gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
	    and   adjustment_id = xte.source_id_int_1
	    and   posting_control_id = -3
	    and   event_id = xe.event_id
	   )
    ORDER BY xe.event_id;


   /*PROCEDURE backup_table_xe is
   l_create_bk_table varchar2(500);
   BEGIN
   l_create_bk_table := 'create table xla_events_bk_'||l_bug_number||'  as
                         select * from xla_events
                         where 1=2';
   EXECUTE IMMEDIATE l_create_bk_table;
   EXCEPTION
   When others then
     IF sqlcode = -955 then
     null;
     ELSE
      raise;
     END IF;
   END backup_table_xe;

   PROCEDURE insert_into_backup_xe(l_event_id number) IS
   l_insert_events  varchar2(500);
   BEGIN
   l_insert_events := 'insert into xla_events_bk_'||l_bug_number||
                   '( select * from xla_events
                      where event_id = '||l_event_id||')';
   EXECUTE IMMEDIATE l_insert_events;
   END;

   PROCEDURE debug(s varchar2) is
   BEGIN
     dbms_output.put_line(s);
   END debug;*/



   BEGIN

   	/*If  nvl(upper(l_read_only_mode),'Y') = 'N' then
   		backup_table_xe;
   	End if;*/

   	debug('                                                                                                         ');
   	debug('Entity Id        '||' '||'Customer Trx Id  '||' '||'Event Type Code    '||' '||'Event Date   '||' '||'Event Status Code '||' '||'Event Id           ');
   	debug('================='||' '||'================='||' '||'==================='||' '||'============='||' '||'=================='||' '||'===================');
   	debug('                                                                                                         ');

   	FOR rec IN get_orphan_trx_events
   	LOOP

   	  l_rule := null;
   	  l_count := 0;

          BEGIN

           SELECT invoicing_rule_id
             INTO l_rule
             FROM ra_customer_trx_all
            WHERE customer_trx_id = rec.source_id_int_1;

           SELECT count(*)
             INTO l_count
             FROM ra_cust_trx_line_gl_dist_all
            WHERE customer_trx_id = rec.source_id_int_1
              AND account_set_flag = 'N';

         EXCEPTION
         WHEN others then
           l_rule := null;
         END;


         IF ( l_rule is null or
            (l_rule is not null and l_count <> 0) ) then

   		  IF  nvl(upper(p_read_only_mode),'Y') = 'N' then

   			   --insert_into_backup_xe(rec.event_id);

   			   DELETE from xla_distribution_links
   			   where application_id = 222
   			   and   ae_header_id in
   				 (SELECT h.ae_header_id
   				  FROM  xla_ae_headers h
   				  WHERE h.application_id   = 222
   				  AND   h.event_id = rec.event_id
   				  );

   			   DELETE from xla_ae_lines
   			   where application_id = 222
   			   and   ae_header_id in
   				 (SELECT h.ae_header_id
   				  FROM  xla_ae_headers h
   				  WHERE h.application_id   = 222
   				  AND   h.event_id = rec.event_id
   				  );

   			   DELETE from xla_ae_headers
   			   where application_id = 222
   			   and   event_id = rec.event_id;

   			   DELETE from xla_events
   			   where event_id = rec.event_id
   			   and application_id = 222;

   		  END IF;


   		  debug(rec.entity_id||
   	 	        print_spaces(18-length(rec.entity_id))||
   		        rec.source_id_int_1||
   		        print_spaces(18-length(rec.source_id_int_1))||
   		        rec.event_type_code||
   		        print_spaces(20-length(rec.event_type_code))||
   		        rec.event_date||
   		        print_spaces(14-length(rec.event_date))||
   		        rec.event_status_code||
   		        print_spaces(19-length(rec.event_status_code))||
   		        rec.event_id||
   		        print_spaces(20-length(rec.event_id))
   		        );

          END IF;

   	END LOOP;

   	debug('                                                                                                         ');
   	debug('Entity Id        '||' '||'Cash Receipt Id  '||' '||'Event Type Code    '||' '||'Event Date   '||' '||'Event Status Code '||' '||'Event Id           ');
   	debug('================='||' '||'================='||' '||'==================='||' '||'============='||' '||'=================='||' '||'===================');
   	debug('                                                                                                         ');


   	FOR rec IN get_orphan_rct_events
   	LOOP

   		IF  nvl(upper(p_read_only_mode),'Y') = 'N' then

   			--insert_into_backup_xe(rec.event_id);

   			DELETE from xla_distribution_links
   			where application_id = 222
   			and   ae_header_id in
   				 (SELECT h.ae_header_id
   				  FROM  xla_ae_headers h
   				  WHERE h.application_id   = 222
   				  AND   h.event_id = rec.event_id);

   			DELETE from xla_ae_lines
   			where application_id = 222
   			and   ae_header_id in
   				 (SELECT h.ae_header_id
   				  FROM  xla_ae_headers h
   				  WHERE h.application_id   = 222
   				  AND   h.event_id = rec.event_id);

   			DELETE from xla_ae_headers
   			where application_id = 222
   			and   event_id = rec.event_id;

   			DELETE from xla_events
   			where event_id = rec.event_id
   			and application_id = 222;

   		END IF;


   		debug(rec.entity_id||
   	 	      print_spaces(18-length(rec.entity_id))||
   		      rec.source_id_int_1||
   		      print_spaces(18-length(rec.source_id_int_1))||
   		      rec.event_type_code||
   		      print_spaces(20-length(rec.event_type_code))||
   		      rec.event_date||
   		      print_spaces(14-length(rec.event_date))||
   		      rec.event_status_code||
   		      print_spaces(19-length(rec.event_status_code))||
   		      rec.event_id||
   		      print_spaces(20-length(rec.event_id))
   		      );

   	END LOOP;

   	debug('                                                                                                         ');
   	debug('Entity Id        '||' '||'Adjustment Id    '||' '||'Event Type Code    '||' '||'Event Date   '||' '||'Event Status Code '||' '||'Event Id           ');
   	debug('================='||' '||'================='||' '||'==================='||' '||'============='||' '||'=================='||' '||'===================');
   	debug('                                                                                                         ');


   	FOR rec IN get_orphan_adj_events
   	LOOP

   		IF  nvl(upper(p_read_only_mode),'Y') = 'N' then

   			--insert_into_backup_xe(rec.event_id);

   			DELETE from xla_distribution_links
   			where application_id = 222
   			and   ae_header_id in
   				 (SELECT h.ae_header_id
   				  FROM  xla_ae_headers h
   				  WHERE h.application_id   = 222
   				  AND   h.event_id = rec.event_id
   				  );

   			DELETE from xla_ae_lines
   			where application_id = 222
   			and   ae_header_id in
   				 (SELECT h.ae_header_id
   				  FROM  xla_ae_headers h
   				  WHERE h.application_id   = 222
   				  AND   h.event_id = rec.event_id
   				  );

   			DELETE from xla_ae_headers
   			where application_id = 222
   			and   event_id = rec.event_id;

   			DELETE from xla_events
   			where event_id = rec.event_id
   			and application_id = 222;

   			DELETE from xla_transaction_entities_upg xte
   			where xte.entity_id = rec.entity_id
   			and xte.application_id = 222
         		and not exists (SELECT 1
                     			from xla_events
                     			where entity_id = xte.entity_id
                      			and application_id = 222);


   		END IF;

   		debug(rec.entity_id||
   	 	      print_spaces(18-length(rec.entity_id))||
   		      rec.source_id_int_1||
   		      print_spaces(18-length(rec.source_id_int_1))||
   		      rec.event_type_code||
   		      print_spaces(20-length(rec.event_type_code))||
   		      rec.event_date||
   		      print_spaces(14-length(rec.event_date))||
   		      rec.event_status_code||
   		      print_spaces(19-length(rec.event_status_code))||
   		      rec.event_id||
   		      print_spaces(20-length(rec.event_id))
   		      );

   	END LOOP;

        p_err_msg := null;
EXCEPTION
WHEN others then
    p_err_msg := 'Error in DEL_ORPHANS_XLA_EVENTS : '||substr(sqlerrm,1,500);
    ROLLBACK;
END del_orphans_xla_events;

-- +===================================================================+
-- | Name  : CREATE_MISSING_RCT_EVENTS                                 |
-- |                                                                   |
-- | Description:This Procedure checks FOR the event_id IN CRH and RA  |
-- |             AND stamps the event_id IF it IS NULL AND there EXISTS|
-- |             an event IN xla_events. Else, script creates a NEW    |
-- |             RECORD IN xla_events AND stamps IN CRH and RA.        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_missing_rct_events(p_org_id 	     NUMBER
				   ,p_read_only_mode VARCHAR2
				   ,p_start_date     DATE
				   ,p_end_date	     DATE
				   ,p_err_msg         OUT VARCHAR2)
AS

l_xla_ev_rec      arp_xla_events.xla_events_type;

CURSOR crh_missing_event_rows IS
  SELECT DISTINCT  crh.cash_receipt_history_id cash_receipt_history_id, crh.cash_receipt_id cash_receipt_id
    FROM ar_cash_receipt_history crh
   WHERE crh.posting_control_id = -3
     --AND crh.cash_receipt_id = DECODE(l_cr_id,0,crh.cash_receipt_id,l_cr_id)
     AND crh.gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
     AND crh.event_id is null
   ORDER BY cash_receipt_id;


CURSOR ra_missing_event_rows IS
  SELECT DISTINCT  ra.receivable_application_id receivable_application_id,
	 ra.cash_receipt_id cash_receipt_id
    FROM ar_receivable_applications ra
   WHERE ra.posting_control_id = -3
     AND ra.cash_receipt_id is not null
     --AND ra.cash_receipt_id = DECODE(l_cr_id,0,ra.cash_receipt_id,l_cr_id)
     AND ra.gl_date BETWEEN to_date(p_start_date,'DD-MON-RRRR') AND to_date(p_end_date,'DD-MON-RRRR')
     AND ra.event_id is null
  ORDER BY cash_receipt_id;


BEGIN
    -- Org Setting
    mo_global.init('AR');
    mo_global.set_policy_context('S',p_org_id);

    debug('Missing events in ar_cash_receipt_history                 ');
    debug('Cash_Receipt_Id  '||' '||'Cash_Receipt_History_Id    ');
    debug('================='||' '||'===========================');


    FOR crh_cr IN crh_missing_event_rows
    LOOP

	debug(
	crh_cr.cash_receipt_id||
	print_spaces(17-length(crh_cr.cash_receipt_id))||
	crh_cr.cash_receipt_history_id||
	print_spaces(28-length(crh_cr.cash_receipt_history_id))
	);

	IF  nvl(upper(p_read_only_mode),'Y') = 'N'
	THEN

	   -- Calling Event Creation Routines
	   l_xla_ev_rec.xla_from_doc_id := crh_cr.cash_receipt_id;
	   l_xla_ev_rec.xla_to_doc_id   := crh_cr.cash_receipt_id;
	   l_xla_ev_rec.xla_mode        := 'O';
	   l_xla_ev_rec.xla_call        := 'B';
	   l_xla_ev_rec.xla_doc_table := 'CRH';
	   ARP_XLA_EVENTS.create_events(p_xla_ev_rec => l_xla_ev_rec);

	END IF;

     END LOOP;

     debug('Missing events in ar_receivable_applications                 ');
     debug('Cash_Receipt_Id  '||' '||'Receivable_application_id  ');
     debug('================='||' '||'===========================');


     FOR app_ra IN ra_missing_event_rows LOOP

	debug(
	app_ra.cash_receipt_id||
	print_spaces(17-length(app_ra.cash_receipt_id))||
	app_ra.receivable_application_id||
	print_spaces(28-length(app_ra.receivable_application_id))
	);

	IF  nvl(upper(p_read_only_mode),'Y') = 'N'
	THEN

		-- Calling Event Creation Routines
		l_xla_ev_rec.xla_from_doc_id := app_ra.receivable_application_id;
		l_xla_ev_rec.xla_to_doc_id   := app_ra.receivable_application_id;
		l_xla_ev_rec.xla_mode        := 'O';
		l_xla_ev_rec.xla_call        := 'B';
		l_xla_ev_rec.xla_doc_table := 'APP';

		ARP_XLA_EVENTS.create_events(p_xla_ev_rec => l_xla_ev_rec);

	END IF;

     END LOOP;

     p_err_msg := null;
EXCEPTION
WHEN others THEN
    p_err_msg := 'Error in CREATE_MISSING_RCT_EVENTS : '||substr(sqlerrm,1,500);
    ROLLBACK;
END create_missing_rct_events;

-- New procedure added for Defect# 31618
-- +===================================================================+
-- | Name  : XX_OD_AR_ADJ_UNBAL_JOURNAL                                |
-- |                                                                   |
-- | Description:This Procedure will fix the Unbalanced adjustment issue.          |
-- |                                                                   |
-- +===================================================================+

-----PROCEDURE XX_OD_AR_ADJ_UNBAL_JOURNAL AS ---Commented as per the jira  #NAIT-62249  

PROCEDURE XX_OD_AR_ADJ_UNBAL_JOURNAL( p_start_date VARCHAR2) AS---- Added the parameter p_start_date as per the Jira #NAIT-62249   

Cursor unposted_adj_items Is
Select
        l1.meaning category,
        ct.invoice_currency_code currency_code,
        art.name activity,
        adj.adjustment_number adj_number,
        ct.trx_number adjinv_number,
        adj.gl_date gl_date,
        --d.amount_dr  dr_amount,
        --d.amount_cr  cr_amount,
        decode('Y',decode(gcc.enabled_flag, 'N', 'Y',
                             decode(gcc.summary_flag, 'Y', 'Y',
                                 decode(least(adj.gl_date, nvl(gcc.start_date_active+1,
                                                      to_date('01/01/0001','MM/DD/RRRR'))),
                                                      adj.gl_date, 'Y',
                                       decode(greatest(adj.gl_date, nvl(gcc.end_date_active-1,
                                                                  to_date('12/31/4712','MM/DD/RRRR'))),
                                                                   adj.gl_date, 'Y', 'N')))),'Y','N') bad_ccid_flag_adj,
        adj.adjustment_id,
        ct.customer_trx_id,
        ctt.name,
        d.line_id,
        d.code_combination_id, 
        d.amount_dr,
        d.amount_cr,
        d.acctd_amount_dr,
        d.acctd_amount_cr,
        adj.payment_schedule_id,
        adj.receivables_trx_id,
        adj.posting_control_id,
        adj.acctd_amount,
        adj.event_id
From
        ar_adjustments_all adj,
        ar_receivables_trx_all art,
        ra_customer_trx_all ct,
        ra_cust_trx_types_all ctt,
        ar_lookups l1,
        gl_code_combinations gcc,
        ar_distributions_all d
Where   adj.posting_control_id = -3
and     nvl(adj.postable,'Y')='Y'
/*and     adj.gl_date >= (SELECT start_date--Current open AR Period start date
          FROM gl_period_statuses
          WHERE application_id = 222 -- represents the GL Application
          AND set_of_books_id  = (select ledger_id from gl_ledgers where name = 'US USD Corp GAAP Primary')--6003 -- determine your set of books_id
          AND sysdate BETWEEN start_date AND end_date
          AND ROWNUM = 1
          ) */ --- Commented as per the jira  #NAIT-62249  


AND adj.gl_date >= fnd_date.canonical_to_date(p_start_date) --- Added as per the Jira #NAIT-62249
and     adj.gl_date <= trunc(sysdate-1)
and     adj.customer_trx_id = ct.customer_trx_id (+)
and     ct.cust_trx_type_id = ctt.cust_trx_type_id (+)
and     adj.receivables_trx_id = art.receivables_trx_id (+)
and    l1.lookup_type = 'ARRGTA_CATEGORIES'
and    l1.lookup_code = 'ADJ'
and    d.code_combination_id = gcc.code_combination_id
and    adj.adjustment_id = d.source_id
and    d.source_table = 'ADJ'
and   (NVL(d.amount_dr,0) <> NVL(acctd_amount_dr,0) or  NVL(d.amount_cr,0) <> NVL(acctd_amount_cr,0))
order by 2,3,4,6;

BEGIN
For UnPosted_Adj_Rec IN unposted_adj_items 
Loop
Begin
Update ar_distributions_all ada
Set ada.acctd_amount_cr = ada.amount_cr,
ada.acctd_amount_dr = ada.amount_dr
where ada.line_id = UnPosted_Adj_Rec.line_id;
Commit;
fnd_file.put_line(fnd_file.log, 'Line ID ' || UnPosted_Adj_Rec.line_id || ' updated.');
Exception
When Others Then
NULL;
End;
End Loop;
END XX_OD_AR_ADJ_UNBAL_JOURNAL;


-- +===================================================================+
-- | Name  : CREATE_MISSING_RCT_EVENTS                                 |
-- |                                                                   |
-- | Description:This Procedure calls the fix steps		       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE main_proc(p_errbuf       OUT  VARCHAR2
                   ,p_retcode      OUT  VARCHAR2
		   ,p_ledger_id	  	NUMBER
		   ,p_org_id		NUMBER
	 	   ,p_read_only_mode 	VARCHAR2
		   ,p_start_date   	VARCHAR2
	           ,p_end_date		VARCHAR2)
AS
  l_err_msg 	  VARCHAR2(2000);
  proc_exception  EXCEPTION;
  l_start_date    DATE;
  l_end_date      DATE;
BEGIN
   l_err_msg := NULL;
   l_start_date := to_date(p_start_date,'MM/DD/YYYY'); --- changed the date format as per the Jira #NAIT-76213
   l_end_date   := to_date(p_end_date,'MM/DD/YYYY'); --- changed the date format as per the Jira #NAIT-76213
   /*l_start_date := fnd_date.canonical_to_date(p_start_date);
   l_end_date   := fnd_date.canonical_to_date(p_end_date); */

/*  update_cash_rcpt_hist_ts(p_org_id
                           ,l_start_date
                           ,l_end_date
                           ,l_err_msg);
  IF l_err_msg IS NOT NULL THEN
      raise proc_exception;
   END IF;
   COMMIT;

   del_orphans_xla_events(p_ledger_id
   			 ,p_read_only_mode
   			 ,l_start_date
   			 ,l_end_date
			 ,l_err_msg);
   IF l_err_msg IS NOT NULL THEN
      raise proc_exception;
   END IF;
   COMMIT;

   create_missing_rct_events(p_org_id
   			    ,p_read_only_mode
   			    ,l_start_date
   			    ,l_end_date
			    ,l_err_msg);
   IF l_err_msg IS NOT NULL THEN
      raise proc_exception;
   END IF;
   COMMIT;
   
   --Added as per defect# 31618
*/-------Commented as per the jira  #NAIT-62249

----XX_OD_AR_ADJ_UNBAL_JOURNAL;------Commented as per the jira  #NAIT-62249

XX_OD_AR_ADJ_UNBAL_JOURNAL(l_start_date);------Added as per the jira  #NAIT-62249

   p_retcode   := '0';
EXCEPTION
WHEN proc_exception THEN
   p_errbuf    := l_err_msg;
   p_retcode   := '2';
WHEN others THEN
   p_errbuf    := 'error in MAIN_PROC '||SQLERRM;
   p_retcode   := '2'; -- error
END main_proc;

END XX_AR_SYNC_XLA_EVENTS_PKG;
/