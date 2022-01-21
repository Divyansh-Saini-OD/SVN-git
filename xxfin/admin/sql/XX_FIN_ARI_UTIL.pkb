create or replace PACKAGE BODY XX_FIN_ARI_UTIL AS

  FUNCTION IS_LARGE_CUSTOMER(
                              P_CUSTOMER_ID           IN NUMBER
  ) RETURN VARCHAR2
  IS
    l_large_cust_flag VARCHAR2(1) :='N';
  BEGIN
    select 'Y'
    into   l_large_cust_flag
    from   xx_fin_irec_large_customers
    where  cust_account_id =  p_customer_id
    ;

    return l_large_cust_flag;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_large_cust_flag := 'N';
      return l_large_cust_flag;
  END IS_LARGE_CUSTOMER;

  FUNCTION IS_LARGE_CUSTOMER(
                              P_CUSTOMER_ID           IN NUMBER
                            , P_SESSION_ID            IN NUMBER
                            , P_POPULATE_SESSION      IN VARCHAR2
  ) RETURN VARCHAR2
  IS
    l_large_cust_flag VARCHAR2(1) :='N';
    l_site_use_id       NUMBER;
  --pragma autonomous_transaction ;
    /*
    cursor c_site_uses
    is
      select site_use_id
      from   xx_fin_site_use_locations
      where  cust_account_id =  p_customer_id
      and    site_use_code = 'BILL_TO'
      and    BILL_TO_FLAG='P'
      ;
      */

  BEGIN
    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,'XX_FIN_AR_UTIL.IS_LARGE_CUSTOMER', '--In XX_FIN_ARI_UTIL.IS_LARGE_CUSTOMER, P_CUSTOMER_ID: ' ||
       P_CUSTOMER_ID || ', P_POPULATE_SESSION: ' || P_POPULATE_SESSION);
    end if;

   --Delete Old session values for this User
    delete from ar_irec_user_acct_sites_all
      where 1=1
      and org_id  = FND_GLOBAL.org_id
      and session_id = P_SESSION_ID
      and user_id = FND_GLOBAL.user_id
      --and customer_id = p_customer_id
      ;

   commit;

    begin
    select 'Y'
    into   l_large_cust_flag
    from   xx_fin_irec_large_customers
    where  cust_account_id =  p_customer_id
    ;
    exception
      when no_data_found then
      l_large_cust_flag := 'N';
    end;

    /*
    begin
    select site_use_id
    into   l_site_use_id
    from   hz_cust_acct_sites_all cas
          ,hz_cust_site_uses_all  csu
    where  cas.cust_account_id =  p_customer_id
    and    cas.cust_acct_site_id = csu.cust_acct_site_id
    and    cas.status='A'
    and    csu.status='A'
    and    cas.bill_to_flag = 'P'
    and    csu.site_use_code = 'BILL_TO'
    ;
    exception
      when no_data_found then
      l_large_cust_flag := 'N';
    end;
    */

    INSERT INTO ar_irec_user_acct_sites_all
      (SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE)
        VALUES(P_SESSION_ID,p_customer_id,'-1',FND_GLOBAL.user_id,sysdate,FND_GLOBAL.org_id, trunc(sysdate));

    commit;
    /*
    for i_rec in c_site_uses
    loop
      INSERT INTO ar_irec_user_acct_sites_all
        (SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE)
          VALUES(P_SESSION_ID,p_customer_id,i_rec.site_use_id,FND_GLOBAL.user_id,sysdate,FND_GLOBAL.org_id, trunc(sysdate));
      commit;
    end loop;
    */

    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,'XX_FIN_AR_UTIL.IS_LARGE_CUSTOMER', '--In XX_FIN_ARI_UTIL.IS_LARGE_CUSTOMER, l_large_cust_flag: ' ||
       l_large_cust_flag);
    end if;

    --Delete Duplicates
    /*
    DELETE FROM  AR_IREC_USER_ACCT_SITES_ALL A
    WHERE A.SESSION_ID = p_session_Id AND
          A.ROWID > ( SELECT MIN(ROWID)
                    FROM AR_IREC_USER_ACCT_SITES_ALL B
                    WHERE A.ORG_ID = B.ORG_ID AND
                          A.SESSION_ID=B.SESSION_ID AND
                          A.USER_ID=B.USER_ID AND
                          A.CUSTOMER_ID=B.CUSTOMER_ID AND
                          --A.CUSTOMER_SITE_USE_ID=B.CUSTOMER_SITE_USE_ID AND
                          A.CREATION_DATE=B.CREATION_DATE );

    */

    --Delete the older duplicate records. That means if there is a duplicate, remove the older duplicate record
    DELETE FROM ar_irec_user_acct_sites_all A 
    WHERE ROWID < (
      SELECT max(rowid) 
      FROM ar_irec_user_acct_sites_all B
      WHERE A.org_id = B.org_id
      AND A.SESSION_ID=B.SESSION_ID
      AND A.USER_ID=B.USER_ID
      AND A.CUSTOMER_ID=B.CUSTOMER_ID
      --AND A.CUSTOMER_SITE_USE_ID=B.CUSTOMER_SITE_USE_ID
      AND A.CREATION_DATE=B.CREATION_DATE
     );
    
    commit;

    return l_large_cust_flag;
  EXCEPTION
    WHEN OTHERS THEN
      l_large_cust_flag := 'N';
      return l_large_cust_flag;
  END IS_LARGE_CUSTOMER;

  FUNCTION IS_LARGE_CUSTOMER(
                              P_CUSTOMER_ID           IN NUMBER
                            , P_CUSTOMER_SITE_USE_ID  IN NUMBER
                            , P_SESSION_ID            IN NUMBER
                            , P_POPULATE_SESSION      IN VARCHAR2
  ) RETURN VARCHAR2
  IS
    l_large_cust_flag VARCHAR2(1) :='N';
    l_site_use_id       NUMBER;
  --pragma autonomous_transaction ;


  BEGIN
    if( FND_LOG.LEVEL_STATEMENT >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) then
      fnd_log.string(fnd_log.LEVEL_STATEMENT,'XX_FIN_AR_UTIL.IS_LARGE_CUSTOMER', '--In XX_FIN_ARI_UTIL.IS_LARGE_CUSTOMER, P_CUSTOMER_ID: ' ||
       P_CUSTOMER_ID || ', P_POPULATE_SESSION: ' || P_POPULATE_SESSION);
    end if;

    begin
    select 'Y'
    into   l_large_cust_flag
    from   xx_fin_irec_large_customers
    where  cust_account_id =  p_customer_id
    ;
    exception
      when no_data_found then
      l_large_cust_flag := 'N';
    end;


   --Delete Old session values for this User
    delete from ar_irec_user_acct_sites_all
      where 1=1
      and org_id  = FND_GLOBAL.org_id
      and session_id = P_SESSION_ID
      and user_id = FND_GLOBAL.user_id
      --and customer_id = p_customer_id
      ;
    commit;

    INSERT INTO ar_irec_user_acct_sites_all
      (SESSION_ID,CUSTOMER_ID,CUSTOMER_SITE_USE_ID,USER_ID,CURRENT_DATE,ORG_ID, CREATION_DATE)
        VALUES(P_SESSION_ID,p_customer_id,P_CUSTOMER_SITE_USE_ID,FND_GLOBAL.user_id,sysdate,FND_GLOBAL.org_id, trunc(sysdate));

    commit;
    --Delete Duplicates
    /*
    DELETE FROM  AR_IREC_USER_ACCT_SITES_ALL A
    WHERE A.SESSION_ID = p_session_Id AND
          A.ROWID > ( SELECT MIN(ROWID)
                    FROM AR_IREC_USER_ACCT_SITES_ALL B
                    WHERE A.ORG_ID = B.ORG_ID AND
                          A.SESSION_ID=B.SESSION_ID AND
                          A.USER_ID=B.USER_ID AND
                          A.CUSTOMER_ID=B.CUSTOMER_ID AND
                          --A.CUSTOMER_SITE_USE_ID=B.CUSTOMER_SITE_USE_ID AND
                          A.CREATION_DATE=B.CREATION_DATE );

    */

    --Delete the older duplicate records. That means if there is a duplicate, remove the older duplicate record
    DELETE FROM ar_irec_user_acct_sites_all A 
    WHERE ROWID < (
      SELECT max(rowid) 
      FROM ar_irec_user_acct_sites_all B
      WHERE A.org_id = B.org_id
      AND A.SESSION_ID=B.SESSION_ID
      AND A.USER_ID=B.USER_ID
      AND A.CUSTOMER_ID=B.CUSTOMER_ID
      --AND A.CUSTOMER_SITE_USE_ID=B.CUSTOMER_SITE_USE_ID
      AND A.CREATION_DATE=B.CREATION_DATE
     );
    
    commit;

    return l_large_cust_flag;
  EXCEPTION
    WHEN OTHERS THEN
      l_large_cust_flag := 'N';
      return l_large_cust_flag;
  END IS_LARGE_CUSTOMER;

  FUNCTION GET_AMOUNT(
                                      P_CUSTOMER_ID           IN NUMBER
                                     ,P_CUST_SITE_USE_ID      IN NUMBER
                                     ,P_INVOICE_CURRENCY_CODE IN VARCHAR2
                                     ,P_STATUS                IN VARCHAR2
                                     ,P_CASH_RECEIPT_ID       IN NUMBER
  ) RETURN NUMBER AS

    lv_query_string VARCHAR2(2000) := '';
    ln_return_val   NUMBER := 0.0;
    ln_cust_site_use_id NUMBER := 0;

  BEGIN
   ln_cust_site_use_id := P_CUST_SITE_USE_ID;
   lv_query_string :=
   '
   select   -sum(app.amount_applied)
   from   AR_PAYMENT_SCHEDULES_ALL ps
        , ar_receivable_applications_all app
  where   ps.customer_id = :1
   AND    decode( (:2),
                  NULL, nvl(ps.customer_site_use_id,-10), :3)
                     = nvl(ps.customer_site_use_id,-10)
   AND    ps.invoice_currency_code = :4
   AND    app.cash_receipt_id = ps.cash_receipt_id
   AND    nvl( app.confirmed_flag, ''Y'' ) = ''Y''
   AND    app.status = :5
   AND    app.cash_receipt_id = :6
   AND    app.PAYMENT_SCHEDULE_ID = ps.PAYMENT_SCHEDULE_ID
   ';

   EXECUTE IMMEDIATE lv_query_string
    INTO ln_return_val
    USING P_CUSTOMER_ID, P_CUST_SITE_USE_ID, ln_cust_site_use_id, P_INVOICE_CURRENCY_CODE, P_STATUS, P_CASH_RECEIPT_ID;
   --dbms_output.put_line('lv_query_string:' || lv_query_string);

   RETURN ln_return_val;

  EXCEPTION
    WHEN OTHERS THEN
      fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_ARI_UTIL.GET_AMOUNT', 'EXCEPTION in GET_AMOUNT_DUE_REMAINING: ' ||  SQLERRM);
      dbms_output.put_line('lv_query_string:' || lv_query_string);

  END GET_AMOUNT;


  FUNCTION GET_ON_ACCOUNT_AMOUNT(
                                      P_CUSTOMER_ID           IN NUMBER
                                     ,P_CUST_SITE_USE_ID      IN NUMBER
                                     ,P_INVOICE_CURRENCY_CODE IN VARCHAR2
                                     ,P_STATUS                IN VARCHAR2
                                     ,P_CASH_RECEIPT_ID       IN NUMBER
  ) RETURN NUMBER AS

    lv_query_string VARCHAR2(2000) := '';
    ln_return_val   NUMBER := 0.0;
    ln_cust_site_use_id NUMBER := 0;

  BEGIN
   ln_cust_site_use_id := P_CUST_SITE_USE_ID;

   lv_query_string :=
   '
   select   -sum(app.amount_applied)
   from   AR_PAYMENT_SCHEDULES_ALL ps
        , ar_receivable_applications_all app
  where   ps.customer_id = :1
   AND    decode( (:2),
                   NULL, nvl(ps.customer_site_use_id,-10)
                  , :3) = nvl(ps.customer_site_use_id,-10)
   AND    ps.invoice_currency_code = :4
   AND    app.cash_receipt_id = ps.cash_receipt_id
   AND    app.applied_payment_schedule_id = -4
   AND    nvl( app.confirmed_flag, ''Y'' ) = ''Y''
   AND    app.status = :5
   AND    app.cash_receipt_id = :6
   AND    app.PAYMENT_SCHEDULE_ID = ps.PAYMENT_SCHEDULE_ID
   ';

   EXECUTE IMMEDIATE lv_query_string
    INTO ln_return_val
    USING P_CUSTOMER_ID, P_CUST_SITE_USE_ID, ln_cust_site_use_id, P_INVOICE_CURRENCY_CODE, P_STATUS, P_CASH_RECEIPT_ID;
   dbms_output.put_line('lv_query_string:' || lv_query_string);
   RETURN ln_return_val;

  EXCEPTION
    WHEN OTHERS THEN
      fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_ARI_UTIL.GET_ON_ACCOUNT_AMOUNT', 'EXCEPTION in GET_ON_ACCOUNT_AMOUNT: ' ||  SQLERRM);
      dbms_output.put_line('lv_query_string:' || lv_query_string);
  END GET_ON_ACCOUNT_AMOUNT;

  FUNCTION GET_TOTAL_AMOUNT(
                                      P_CUSTOMER_TRX_ID       IN NUMBER
  ) RETURN NUMBER AS

    lv_query_string VARCHAR2(2000) := '';
    ln_return_val   NUMBER := 0.0;

  BEGIN
   lv_query_string :=
   '
   select sum(l.extended_amount)
   from  ra_customer_trx_lines_all l
   where 1 = 1
   and   l.customer_trx_id = :1
   and   l.line_type IN  (''LINE'',''CB'')
   ';

   EXECUTE IMMEDIATE lv_query_string
    INTO ln_return_val
    USING P_CUSTOMER_TRX_ID;
   dbms_output.put_line('lv_query_string:' || lv_query_string);

   RETURN ln_return_val;

  EXCEPTION
    WHEN OTHERS THEN
      fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_ARI_UTIL.GET_TOTAL_AMOUNT',  'EXCEPTION in GET_TOTAL_AMOUNT: ' ||  SQLERRM);
      dbms_output.put_line('lv_query_string:' || lv_query_string);
  END GET_TOTAL_AMOUNT;

  PROCEDURE IDENTIFY_LARGE_CUSTOMERS (
     x_errbuf            OUT NOCOPY VARCHAR2
    ,x_retcode           OUT NOCOPY NUMBER
    ,p_last_run_date     IN  VARCHAR2
  )
  AS
    l_cust_account_id   NUMBER(15);
    l_last_run_date     DATE;
    CURSOR C1 (l_last_update_date in date)
    is
     select /*+ parallel (cas 8)*/ cust_account_id, count(1) as sites_count
     from   hz_cust_acct_sites_all cas
     where  cas.last_update_date > l_last_update_date
     group by cust_account_id
     having count(1) >= 950;

    CURSOR C2 (l_last_update_date in date)
    is
     select /*+ parallel (rct 8)*/ psa.CUSTOMER_ID as cust_account_id, count(1) as trx_count
     from   AR_PAYMENT_SCHEDULES_ALL psa
     where psa.status = 'OP'
      AND  psa.last_update_date > l_last_update_date
     group by psa.CUSTOMER_ID
     having count(1) > 2000;

  BEGIN

  BEGIN -- this block is to compute l_last_run_date

      IF (p_last_run_date is null)
      THEN
          select b.actual_start_date
          into   l_last_run_date
          from  (
                 select rownum as rn, cp.actual_start_date
                 from (
                       select actual_start_date
                       from   fnd_concurrent_requests
                       where  concurrent_program_id = (select concurrent_program_id
                                                       from   fnd_concurrent_programs_vl
                                                       where  user_concurrent_program_name = 'OD: Identify iReceivables Large Customers'
                                                       )
                       order by actual_start_date desc) cp) b
          where  rn = 2;

      ELSE
      l_last_run_date := to_date(p_last_run_date,'DD-MON-RRRR');
      END IF;

      fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_ARI_UTIL.identify_customers', 'l_last_run_date:' || to_char(l_last_run_date, 'DD-MON-RRRR'));
      fnd_file.put_line(FND_FILE.LOG, 'l_last_run_date:' || to_char(l_last_run_date, 'DD-MON-RRRR'));
  EXCEPTION
  WHEN OTHERS
    THEN
      fnd_file.put_line(FND_FILE.LOG, 'Exception in deriving last_run_date: ' || SQLERRM);
  END;  -- this block is to compute l_last_run_date


    dbms_output.put_line('Start step1--');
    l_cust_account_id := null;
    for i in C1 (l_last_run_date)
    loop
      BEGIN
        SELECT firl.CUST_ACCOUNT_ID
        INTO   l_cust_account_id
        FROM   xx_fin_irec_large_customers firl
        WHERE  i.CUST_ACCOUNT_ID = firl.CUST_ACCOUNT_ID;

        UPDATE xx_fin_irec_large_customers firl
        SET    SITES_COUNT = i.SITES_COUNT
        WHERE  firl.CUST_ACCOUNT_ID = l_cust_account_id;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          insert into xx_fin_irec_large_customers (cust_account_id, sites_count)
          values (i.cust_account_id, i.sites_count);
      END;

      commit;
      insert into xx_fin_irec_large_customers (cust_account_id, sites_count)
      values (i.cust_account_id, i.sites_count);

      commit;
    end loop;
    dbms_output.put_line('Start Step2--');

    l_cust_account_id := null;
    for j in C2 (l_last_run_date)
    loop
      BEGIN
        SELECT firl.CUST_ACCOUNT_ID
        INTO   l_cust_account_id
        FROM   xx_fin_irec_large_customers firl
        WHERE  j.CUST_ACCOUNT_ID = firl.CUST_ACCOUNT_ID;

        UPDATE xx_fin_irec_large_customers firl
        SET    TRX_COUNT = j.TRX_COUNT
        WHERE  firl.CUST_ACCOUNT_ID = l_cust_account_id;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          insert into xx_fin_irec_large_customers (cust_account_id, trx_count)
          values (j.cust_account_id, j.trx_count);
      END;

      commit;
    end loop;
    dbms_output.put_line('End Step2--');


  EXCEPTION
    WHEN OTHERS THEN
      fnd_log.STRING (fnd_log.level_statement, 'XX_FIN_ARI_UTIL.IDENTIFY_LARGE_CUSTOMERS',  'EXCEPTION in IDENTIFY_LARGE_CUSTOMERS: ' ||  SQLERRM);
  END IDENTIFY_LARGE_CUSTOMERS;


END XX_FIN_ARI_UTIL;
/