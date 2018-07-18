create or replace
PACKAGE BODY xx_cs_contracts_pkg AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_CONTRACTS_PKG.pkb                                                              |
-- | Description  : This package contains procedures related to Service Contracts creation        |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        15-AUG-2012   RAJ Jagarlamudi    Initial version                                   |
-- |                                                                                              |
-- +==============================================================================================+

  FUNCTION payment_term(p_term IN VARCHAR2) RETURN NUMBER;

  PROCEDURE create_contract ( p_party_id       IN NUMBER
                            , p_sales_rep_id   IN VARCHAR2
                            , p_contract_type  IN VARCHAR2
                            , p_contract_rec   IN XX_CS_MPS_CONTRACT_REC_TYPE
                            , x_contract_num   IN OUT VARCHAR2
                            , x_return_status  IN OUT VARCHAR2
                            , x_return_mesg    IN OUT VARCHAR2
                            ) AS
  -- +=====================================================================+
  -- | Name  : create_contract                                             |
  -- | Description      : This Procedure will create Service Contract      |
  -- |                                                                     |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_party_id      IN NUMBER party ID               |
  -- |                    p_sales_rep_id  IN VARCHAR2 Sales Rep Name       |
  -- |                    p_contract_type IN VARCHAR2 Contact Type         |
  -- |                    p_contract_rec  IN XX_CS_MPS_CONTRACT_REC_TYPE   |
  -- |                    x_return_status IN OUT VARCHAR2 Return status    |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message   |
  -- |                    x_contract_num  IN OUT VARCHAR2 Contract Number  |
  -- +=====================================================================+

    /* Variable Declaration */
    l_k_header_rec          OKS_CONTRACTS_PUB.header_rec_type;
    l_header_contacts_tbl   OKS_CONTRACTS_PUB.contact_tbl;
    l_header_sales_crd_tbl  OKS_CONTRACTS_PUB.SalesCredit_tbl;
    l_header_articles_tbl   OKS_CONTRACTS_PUB.obj_articles_tbl;
    l_k_line_rec            OKS_CONTRACTS_PUB.line_rec_type;
    l_line_contacts_tbl     OKS_CONTRACTS_PUB.contact_tbl;
    l_line_sales_crd_tbl    OKS_CONTRACTS_PUB.SalesCredit_tbl;
    l_k_Support_rec         OKS_CONTRACTS_PUB.line_rec_type;
    l_Support_contacts_tbl  OKS_CONTRACTS_PUB.contact_tbl;
    l_Support_sales_crd_tbl OKS_CONTRACTS_PUB.SalesCredit_tbl;
    l_k_covd_rec            OKS_CONTRACTS_PUB.Covered_level_Rec_Type;
    l_price_attribs_in      OKS_CONTRACTS_PUB.pricing_attributes_type;
    l_Strm_hdr_rec          OKS_BILL_SCH.StreamHdr_type;
    l_strm_level_tbl        OKS_BILL_SCH.StreamLvl_tbl;
    lx_msg_tbl              okc_qa_check_pub.msg_tbl_type;
    l_descr                 okc_k_headers_tl.short_description%TYPE;
    l_contract_number       okc_k_headers_b.contract_number%TYPE;
    l_billing_sch_type      VARCHAR2(100);
    l_merge_rule            VARCHAR2(100);
    l_usage_instantiate     VARCHAR2(100);
    l_ib_creation           VARCHAR2(100);
    lx_chrid                NUMBER;
    lx_service_line_id      NUMBER;
    lx_cp_line_id           NUMBER;
    lx_return_status        VARCHAR2(1);
    lx_msg_count            NUMBER;
    lx_msg_data             VARCHAR2(2000);
    l_qa_error              BOOLEAN;
    hcon                    INTEGER := 1;
    exc_failed              EXCEPTION;
    ln_party_id             NUMBER;
    ln_price_list_id        NUMBER;
    ln_billto_id            NUMBER;
    ln_contact_id           NUMBER;
    ln_payment_term_id      NUMBER;
    lr_contract_rec         XX_CS_MPS_CONTRACT_REC_TYPE;
    ln_tran_type_id         NUMBER;
    ln_salesrep_id          NUMBER := NULL;


  BEGIN
      -- Initialization
      FND_GLOBAL . APPS_INITIALIZE ( 1176 , 50259 , 515 );
      okc_context.set_okc_org_context;
      fnd_client_info.set_org_context(404);

      okc_api.init_msg_list(OKC_API.G_TRUE);

      ln_party_id := p_party_id;

      -- Record data
      lr_contract_rec := xx_cs_mps_contract_rec_type(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
      lr_contract_rec := p_contract_rec;

      IF ln_party_id IS NULL THEN
          dbms_output.put_line('Party ID is NULL');
          RAISE exc_failed;
      ELSE
          get_cust_bill_to( p_party_id     => ln_party_id
                          , x_site_use_id => ln_billto_id
							 );

          get_contact_id( p_party_id     => ln_party_id
                        , x_contact_id   => ln_contact_id
						  );
      END IF;

      -- Get price list id
      ln_price_list_id := OE_Sys_Parameters.value('XX_OM_SAS_PRICE_LIST',G_Org_Id);

      -- Get payment Term id
      ln_payment_term_id := payment_term( p_term => lr_contract_rec.payment_terms );

      l_descr := 'MPS Contract API Test '||to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS');

      SELECT cust_trx_type_id
        INTO ln_tran_type_id
        FROM ra_cust_trx_types_all
       WHERE name = 'US MPS INVOICE';

      l_k_header_rec.contract_number     := l_contract_number;
      l_k_header_rec.start_date          := TRUNC(SYSDATE);
      l_k_header_rec.end_date            := TRUNC(SYSDATE)+365;
      l_k_header_rec.sts_code            := 'ENTERED';
      l_k_header_rec.scs_code            := 'SERVICE';
      l_k_header_rec.authoring_org_id    := g_org_id;
      l_k_header_rec.short_description   := l_descr;
      --l_k_header_rec.chr_group           := 2; -- CBS DK Service Contracts
      --l_k_header_rec.pdf_id              := 3; -- Approval Workflow OKCAUKAP
      l_k_header_rec.party_id            := ln_party_id; --21323399; -- '21ST CENTURY ONCOLOGY'
      l_k_header_rec.bill_to_id          := ln_billto_id;
      --l_k_header_rec.ship_to_id        :=
      l_k_header_rec.price_list_id       := ln_price_list_id;
      --l_k_header_rec.agreement_id      :=
      l_k_header_rec.currency            := lr_contract_rec.currency_code; --'USD';
      l_k_header_rec.accounting_rule_type := 1; --1002; -- 12 MONTHS ADVANCE
      --l_k_header_rec.invoice_rule_type := -2;
      l_k_header_rec.payment_term_id     := ln_payment_term_id; --1024; -- 1ST OF MONTH
      l_k_header_rec.contact_id          := ln_contact_id;
      l_k_header_rec.merge_type          := 'NEW';
      l_k_header_rec.merge_object_id     := NULL;
      l_k_header_rec.Ar_interface_yn     := 'N';
      l_k_header_rec.transaction_type    := ln_tran_type_id ; --1089; -- SERV-Invoice
      l_k_header_rec.Summary_invoice_yn  := 'N';
      l_k_header_rec.qcl_id              := 1;


      l_header_contacts_tbl(hcon).party_role          := 'CUSTOMER';
      l_header_contacts_tbl(hcon).contact_role        := 'USER';
      l_header_contacts_tbl(hcon).contact_object_code := 'OKX_PCONTACT';
      l_header_contacts_tbl(hcon).contact_id          := ln_contact_id;

      hcon := hcon + 1;

      IF ln_salesrep_id is NULL THEN
        SELECT salesrep_id
          INTO ln_salesrep_id
          FROM jtf_rs_salesreps
         WHERE name   = 'Depot, Office'
           AND org_id = g_org_id;
      END IF;

      l_header_contacts_tbl(hcon).party_role           := 'VENDOR';
      l_header_contacts_tbl(hcon).contact_role         := 'SALESPERSON';
      l_header_contacts_tbl(hcon).contact_object_code  := 'OKX_SALEPERS';
      l_header_contacts_tbl(hcon).contact_id           := ln_salesrep_id;


      /******************************************************************/
      --  Create Contract
      /*******************************************************************/
      OKS_CONTRACTS_PUB.create_contract( p_k_header_rec          => l_k_header_rec
                                       , p_header_contacts_tbl   => l_header_contacts_tbl
                                       , p_header_sales_crd_tbl  => l_header_sales_crd_tbl
                                       , p_header_articles_tbl   => l_header_articles_tbl
                                       , p_k_line_rec            => l_k_line_rec
                                       , p_line_contacts_tbl     => l_line_contacts_tbl
                                       , p_line_sales_crd_tbl    => l_line_sales_crd_tbl
                                       , p_k_Support_rec         => l_k_Support_rec
                                       , p_support_contacts_tbl  => l_support_contacts_tbl
                                       , p_support_sales_crd_tbl => l_support_sales_crd_tbl
                                       --, p_line_articles_tbl
                                       , p_k_covd_rec            => l_k_covd_rec
                                       , p_price_attribs_in      => l_price_attribs_in
                                       , p_merge_rule            => l_merge_rule
                                       , p_usage_instantiate     => l_usage_instantiate
                                       , p_ib_creation           => l_ib_creation
                                       , p_billing_sch_type      => l_billing_sch_type
                                       , p_strm_level_tbl        => l_strm_level_tbl
                                       , x_chrid                 => lx_chrid
                                       , x_return_status         => lx_return_status
                                       , x_msg_count             => lx_msg_count
                                       , x_msg_data              => lx_msg_data
                                       );

      dbms_output.put_line('Contract Return Status is : '||lx_return_status);
      dbms_output.put_line('Message Count is : '||TO_CHAR(lx_msg_count));

      IF lx_return_status != 'S' THEN
        IF NVL(lx_msg_count,0) > 0 THEN
          FOR i IN 1..lx_msg_count LOOP
            dbms_output.put_line('OKS API:'||fnd_msg_pub.get(i, 'F'));
          END LOOP;
        END IF;
        RAISE exc_failed;
      END IF;


      /******************************************************************/
       -- Automatic approval
      /*******************************************************************/
      okc_contract_approval_pub.k_approved( p_contract_id   => lx_chrid
                                          , p_date_approved => sysdate
                                          , x_return_status => lx_return_status
                                          );

      IF lx_return_status != 'S' THEN
          dbms_output.put_line('Unable to Approve');
          RAISE exc_failed;
      END IF;

      /******************************************************************/
       -- Auto signed
      /******************************************************************/
      okc_contract_approval_pub.k_signed( p_contract_id   => lx_chrid
                                        , p_date_signed   => sysdate
                                        , x_return_status => lx_return_status
                                        );

      IF lx_return_status != 'S' THEN
          dbms_output.put_line('Unable to Sign');
          RAISE exc_failed;
      END IF;

      dbms_output.put_line('Contract Approved and Signed');
      COMMIT;

      BEGIN
        SELECT contract_number
          INTO l_contract_number
          FROM okc_k_headers_b
         WHERE id = lx_chrid;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;

      dbms_output.put_line('Contract No:'||l_contract_number);


    EXCEPTION
       WHEN exc_failed THEN
         dbms_output.put_line('Rolled back to savepoint');
       WHEN OTHERS THEN
         dbms_output.put_line('When Others:'||SQLERRM);
  END CREATE_CONTRACT;

  PROCEDURE create_contract_lin( p_header_id        IN NUMBER
                               , x_return_status   OUT VARCHAR2
                               , x_return_mesg     OUT VARCHAR2
                               , x_service_line_id OUT NUMBER
                               ) IS
  -- +=====================================================================+
  -- | Name  : create_contract_lin                                         |
  -- | Description      : This Procedure will create Service Contract line |
  -- |                                                                     |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_header_id        IN NUMBER ID                  |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                    x_service_line_id  OUT VARCHAR2 Contract Number  |
  -- +=====================================================================+

    ln_hrd_ct            NUMBER := 0;
    ln_max_lin_id        NUMBER := 0;
    ln_line_number       NUMBER := 0;
    ln_header_id         okc_k_headers_b.id%TYPE;
    ln_customer_id       okc_k_headers_b.cust_acct_id%TYPE;
    ln_bill_to_id        okc_k_headers_b.bill_to_site_use_id%TYPE;
    lc_currency_code     okc_k_headers_b.currency_code%TYPE;

    l_k_line_rec         oks_contracts_pub.line_rec_type;
    l_line_contacts_tbl  oks_contracts_pub.contact_tbl;
    l_line_sales_crd_tbl oks_contracts_pub.salescredit_tbl;
    ln_service_line_id   okc_k_lines_b.id%TYPE;
    lc_return_status     VARCHAR2(1);
    ln_msg_count         NUMBER;
    lc_msg_data          VARCHAR2(2000);
    exc_failed           EXCEPTION;

    CURSOR c_ship_to(p_customer_id IN NUMBER)  IS
      SELECT site_use_id ship_to_id, HL.Postal_Code
        FROM hz_cust_site_uses_all  hcs
           , hz_cust_acct_sites_all hca
           , hz_cust_accounts       hc
           , hz_party_sites         hps
           , hz_locations           hl
       WHERE hc.cust_account_id    = p_customer_id
         AND hc.cust_account_id    = hca.cust_account_id
         AND hca.cust_acct_site_id = hcs.cust_acct_site_id
         AND hcs.site_use_code     = 'SHIP_TO'
         AND hcs.status            = 'A'
         AND hca.status            = 'A'
         AND hc.status             = 'A'
         AND hca.party_site_id     = hps.party_site_id
         AND hps.location_id       = hl.location_id;
  BEGIN

    SELECT COUNT(*)
      INTO ln_hrd_ct
      FROM okc_k_headers_b
     WHERE id = p_header_id;

    SELECT NVL(MAX(line_number),0)
      INTO ln_max_lin_id
      FROM okc_k_lines_b
     WHERE id = p_header_id;

    ln_line_number := ln_max_lin_id;

    IF  ln_hrd_ct = 0 THEN
        dbms_output.put_line('No Header Info Found For : '||p_header_id);

    ELSE
        SELECT id
             , cust_acct_id
             , bill_to_site_use_id
             , currency_code
          INTO ln_header_id
             , ln_customer_id
             , ln_bill_to_id
             , lc_currency_code
          FROM okc_k_headers_b
         WHERE id = p_header_id;

        FOR r_ship_to IN c_ship_to(ln_customer_id) LOOP
          ln_line_number := ln_line_number +1;

           --line type should be derived based on S or U

          l_k_line_rec.k_hdr_id             := ln_header_id;
          l_k_line_rec.k_line_number        := ln_line_number;
          l_k_line_rec.line_sts_code        := 'ACTIVE';
          l_k_line_rec.cust_account         := NULL;
          l_k_line_rec.org_id               := g_org_id;
          l_k_line_rec.organization_id      := 404; -- need to determin nearest CSC location id
          l_k_line_rec.bill_to_id           := ln_bill_to_id;
          l_k_line_rec.ship_to_id           := r_ship_to.ship_to_id;
          l_k_line_rec.accounting_rule_type := 1; --1002; -- 12 MONTHS ADVANCE
          l_k_line_rec.invoicing_rule_type  := -2; -- Advance Invoice
          l_k_line_rec.line_type            := 'U'; -- Usage ---E,U.W,S,SB,SU
          l_k_line_rec.currency             := lc_currency_code; -- Danish Kroner
          l_k_line_rec.list_price           := 24;
          l_k_line_rec.negotiated_amount    := 24;
          l_k_line_rec.customer_product_id  := NULL;
          l_k_line_rec.customer_id          := ln_customer_id;
          l_k_line_rec.start_date_active    := TRUNC(SYSDATE);
          l_k_line_rec.end_date_active      := TRUNC(SYSDATE)+365;
          l_k_line_rec.quantity             := 1;
          l_k_line_rec.net_amount           := 0;
          l_k_line_rec.srv_id               := 374;
          l_k_line_rec.srv_sdt              := TRUNC(SYSDATE);
          l_k_line_rec.srv_edt              := TRUNC(SYSDATE)+365;
          l_k_line_rec.usage_type           := 'USD';
          l_k_line_rec.usage_period         := 'YR';

          -- Sales Rep details
          --  l_line_sales_crd_tbl(1).ctc_id :=
          -- l_line_sales_crd_tbl(1).sales_credit_type_id := 1; --  Sales Credit
          -- l_line_sales_crd_tbl(1).percent := ;


          --l_k_covd_rec.line_number         := '1.1';
          --l_k_covd_rec.product_sts_code    := 'ACTIVE';
          --l_K_covd_rec.Customer_Product_Id := NULL;
          --l_K_covd_rec.Product_Desc        := NULL;
          --l_k_covd_rec.Product_Start_Date  := TRUNC(SYSDATE);
          --l_k_covd_rec.Product_End_Date    := TRUNC(SYSDATE)+365;
          --l_k_covd_rec.Quantity            := 1;
          --l_k_covd_rec.settlement_flag     := 'N';
          --l_k_covd_rec.average_bill_flag   := 'N';
          --l_k_covd_rec.Uom_Code            := 'EA';
          --l_k_covd_rec.list_price          := 24;
          --l_k_covd_rec.negotiated_amount   := 24;
          --l_k_covd_rec.currency_code       := 'USD';
          --l_k_covd_rec.period              := 'Year';


          oks_contracts_pub.create_service_line( p_k_line_rec         => l_k_line_rec
                                               , p_Contact_tbl        => l_line_contacts_tbl
                                               , p_line_sales_crd_tbl => l_line_sales_crd_tbl
                                               , x_service_line_id    => ln_service_line_id
                                               , x_return_status      => lc_return_status
                                               , x_msg_count          => ln_msg_count
                                               , x_msg_data           => lc_msg_data
                                               );

          dbms_output.put_line('Service Return Status is:'||lc_return_status);
          dbms_output.put_line('Message Count is:'||to_char(ln_msg_count));

          x_service_line_id := ln_service_line_id;

          IF lc_return_status != 'S' THEN
            IF NVL(ln_msg_count,0) > 0 THEN
              FOR i IN 1..ln_msg_count LOOP
                dbms_output.put_line('OKS API:'||fnd_msg_pub.get(i, 'F'));
              END LOOP;
            END IF;
            RAISE exc_failed;
          END IF;

        END LOOP;

    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('NO Header ID for : ' || p_header_id);

    WHEN OTHERS THEN
      dbms_output.put_line('When Others Raised in create_contract_lin : ' || SQLERRM);

  END create_contract_lin;

  PROCEDURE get_cust_bill_to ( p_party_id     IN NUMBER
                             , x_site_use_id OUT NUMBER
                             ) IS
  -- +=====================================================================+
  -- | Name  : get_cust_bill_to                                            |
  -- | Description      : This Procedure will derive bill to site id       |
  -- |                                                                     |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_party_id       IN NUMBER   party ID            |
  -- |                    x_site_use_id   OUT VARCHAR2 BILL_TO ID          |
  -- +=====================================================================+

  ln_site_use_id NUMBER;

  BEGIN

    SELECT site_use_id
	  INTO ln_site_use_id
      FROM hz_cust_site_uses_all  hcs
         , hz_cust_acct_sites_all hca
         , hz_cust_accounts       hc
     WHERE hc.party_id           = p_party_id
       AND hc.cust_account_id    = hca.cust_account_id
       AND hca.cust_acct_site_id = hcs.cust_acct_site_id
       AND hcs.site_use_code     = 'BILL_TO'
       AND hcs.status            = 'A'
       AND hca.status            = 'A'
       AND hc.status             = 'A';

    x_site_use_id := ln_site_use_id;

  EXCEPTION

    WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('No Data Found raised at get_cust_bill_to : ');
      x_site_use_id := NULL;

    WHEN OTHERS THEN
      dbms_output.put_line('When Others raised at get_cust_bill_to : '||SQLERRM);
      x_site_use_id := NULL;

  END  get_cust_bill_to;

  FUNCTION payment_term (p_term IN VARCHAR2) RETURN NUMBER IS
  -- +===================================================================+
  -- | Name  : payment_term                                              |
  -- | Description     : To derive payment_term_id by passing            |
  -- |                   term name                                       |
  -- |                                                                   |
  -- | Parameters     : p_term  IN -> pass term name                     |
  -- |                                                                   |
  -- | Return         : payment_term_id                                  |
  -- +===================================================================+

    ln_payment_term_id  NUMBER;

  BEGIN
      SELECT r.term_id
        INTO ln_payment_term_id
        FROM ra_terms_tl r
	       , ra_terms_b  b
       WHERE r.name         = p_term
	     AND r.language = USERENV('LANG')
	     AND r.term_id  = b.term_id
	     AND NVL(END_DATE_ACTIVE,SYSDATE) >= SYSDATE+1;

      RETURN ln_payment_term_id;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;

  END payment_term;

  -- +===================================================================+
  -- | Name  : get_contact_id                                            |
  -- | Description : To derive customer id and contact id                |
  -- |                                                                   |
  -- | Parameters  : p_party_id   IN -> pass party_id                    |
  -- |             : x_contact_id OUT -> pass out conatct id             |
  -- |                                                                   |
  -- +===================================================================+
  Procedure get_contact_id( p_party_id           IN        NUMBER
                          , x_contact_id         OUT       NUMBER
                          ) IS
  BEGIN

    SELECT cust_account_role_id
      INTO x_contact_id
      FROM HZ_CUST_ACCOUNT_ROLES
     WHERE party_id      = p_party_id
	   AND status        = 'A'
       AND primary_flag  = 'Y';

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      x_contact_id := NULL;

    WHEN OTHERS THEN
      x_contact_id := NULL;

  END get_contact_id;

END XX_CS_CONTRACTS_PKG;
/
show errors;
exit;