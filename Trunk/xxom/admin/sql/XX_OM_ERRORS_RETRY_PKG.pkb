SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_ERRORs_RETRY_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_ERRORs_RETRY_PKG                                          |
-- | Description      : This Program will update missing info to create      |
-- |                    inventory_item_id, ship_from_org_id,sold_to_org_id   |
-- |                    invoice_ot_org_id ahip_to_org_id in interface tbls   |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |DRAFT 1A   02-JUN-2008   Bapuji Nanapaneni Initial draft version         |
-- +=========================================================================+

AS

PROCEDURE Get_orig_sys_document_ref( 
                                     errbuf        OUT NOCOPY VARCHAR2
                                   , retcode       OUT NOCOPY NUMBER
                                   ,p_request_id   IN VARCHAR2
                                   ) IS

  CURSOR c_orig_sys_doc_ref (p_req_id IN NUMBER) IS

  SELECT m.original_sys_document_ref
       , m.order_source_id
       , SUBSTR(m.message_text, 1, 8) message_num
       , m.original_sys_document_line_ref
       , m.request_id
       , h.ship_from_org
       , h.sold_to_org
       , h.sold_to_org_id
       , h.ship_to_org
       , h.invoice_to_org_id
       , h.ship_to_org_id
   FROM apps.oe_processing_msgs_vl m, ont.oe_headers_iface_all h
  WHERE SUBSTR(message_text, 1, 8) IN ('10000002'
                                      ,'10000017'
                                      ,'10000018'
                                      ,'10000010'
                                      ,'10000012'
                                      ,'10000015'
                                      ,'10000016'
                                      ,'10000021'
                                      ,'10000022'
                                      ,'10000024')
    AND m.request_id = p_req_id
    AND  h.orig_sys_document_ref = m.original_sys_document_ref
    AND h.order_source_id       = m.order_source_id
    AND nvl(h.error_flag,'N')   = 'Y'
  order by original_sys_document_ref
         , original_sys_document_line_ref;

  CURSOR c_more_msgs( p_req_id IN NUMBER
                    , p_orig_sys_doc_ref IN VARCHAR2
                    , p_order_source_id IN NUMBER
                    ) IS

 SELECT count(m.original_sys_document_ref) msgs_count
   FROM apps.oe_processing_msgs_vl m
      , ont.oe_headers_iface_all h
  WHERE m.request_id = p_req_id
    AND m.original_sys_document_ref = p_orig_sys_doc_ref
    AND m.order_source_id =  p_order_source_id
    AND  h.orig_sys_document_ref = m.original_sys_document_ref
    AND h.order_source_id       = m.order_source_id
    AND nvl(h.error_flag,'N')   = 'Y'
    AND NOT EXISTS
      (SELECT 'I' FROM oe_processing_msgs_vl m1
       WHERE m.original_sys_document_ref = m1.original_sys_document_ref
         AND m.order_source_id = m1.order_source_id
         AND substr(m.message_text,1,8) = substr(m1.message_text,1,8)
         AND SUBSTR(m1.message_text, 1, 8) IN ('10000002','10000010','10000016','10000017','10000018','10000012','10000015','10000021','10000022','10000024'))
  order by original_sys_document_ref
         , original_sys_document_line_ref;

  CURSOR c_validation ( p_req_id            IN NUMBER
                      , p_orig_sys_doc_ref  IN VARCHAR2
                      , p_ord_source_id     IN NUMBER
                      ) IS

  SELECT DISTINCT h.orig_sys_document_ref
       , h.order_source_id
       , h.request_id
       , h.sold_to_org_id
       , h.ship_to_org_id
       , h.invoice_to_org_id
       , h.ship_from_org_id
       , l.inventory_item_id
       , l.orig_sys_line_Ref
   FROM ont.oe_headers_iface_all h
      , ont.oe_lines_iface_all   l
  WHERE h.orig_sys_document_ref = l.orig_sys_document_ref
    AND h.order_source_id       = l.order_source_id
    AND h.orig_sys_document_ref = p_orig_sys_doc_ref
    AND h.order_source_id       = p_ord_source_id
    AND nvl(h.error_flag,'N')   = 'Y'
    AND h.request_id            = p_req_id;

ln_line_count       NUMBER       := 0;
ln_error_count      NUMBER       := 0;
ln_ord_count        NUMBER       := 0;
ln_sold_to_org_id   NUMBER       := NULL;
ln_invoice_to_org_id NUMBER      := NULL;
ln_ship_to_org_id    NUMBER      := NULL;
lc_status            VARCHAR2(1) := 'E';
lc_ord_status        VARCHAR2(1) := NULL;
lc_customer_name     hz_parties.party_name%TYPE := NULL;
ln_ship_from_org_id  NUMBER := NULL;
ln_inventory_item_id NUMBER := NULL;
lc_geocode           xx_om_header_attributes_all.ship_to_geocode%TYPE := NULL;
ln_sold_to_contact_id NUMBER := NULL;
ln_payment_term_id    NUMBER;
--ln_user                            NUMBER := 29497;
--ln_resp                            NUMBER := 51050;
--ln_appl                            NUMBER := 660;

BEGIN
  --FND_GLOBAL.apps_initialize(ln_user,ln_resp,ln_appl);
  --FND_MSG_PUB.Initialize;
  fnd_file.put_line(FND_FILE.LOG,'Inside the main cursor');
  fnd_file.put_line(FND_FILE.LOG,'Request_id :'||p_request_id);
  
      ln_line_count  := 0;
      ln_error_count := 0;

  FOR r_orig_sys_doc_ref IN c_orig_sys_doc_ref(p_request_id) LOOP

     fnd_file.put_line(FND_FILE.LOG,'The orig_sys_document_ref is'||r_orig_sys_doc_ref.original_sys_document_ref);
 --    DBMS_OUTPUT.PUT_LINE('The orig_sys_document_ref is'||r_orig_sys_doc_ref.original_sys_document_ref);

    IF r_orig_sys_doc_ref.message_num = '10000002' THEN
    
      fnd_file.put_line(FND_FILE.LOG,'Inside error num 10000002');

      Get_10000002( p_orig_sys_document_ref => r_orig_sys_doc_ref.original_sys_document_ref
                  , p_request_id            => r_orig_sys_doc_ref.request_id
                  , p_order_source_id       => r_orig_sys_doc_ref.order_source_id
                  , x_sold_to_org_id        => ln_sold_to_org_id
                  , x_invoice_to_org_id     => ln_invoice_to_org_id
                  , x_ship_to_org_id        => ln_ship_to_org_id
                  , x_customer_name         => lc_customer_name
                  , x_status                => lc_status
                  );

    DBMS_OUTPUT.PUT_LINE(' Status for 10000002 :::'||lc_status);
    fnd_file.put_line(FND_FILE.LOG, ' Status for 10000002 :::'||lc_status);

        IF lc_status = 'S' THEN

        UPDATE ont.oe_headers_iface_all
           SET sold_to_org_id    = ln_sold_to_org_id
             , invoice_to_org_id = ln_invoice_to_org_id
             , ship_to_org_id    = ln_ship_to_org_id
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
         WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
           AND order_source_id       = r_orig_sys_doc_ref.order_source_id
           AND request_id            = r_orig_sys_doc_ref.request_id;

        UPDATE ont.oe_lines_iface_all
           SET sold_to_org_id    = ln_sold_to_org_id
             , invoice_to_org_id = ln_invoice_to_org_id
             , ship_to_org_id    = ln_ship_to_org_id
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
         WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
           AND order_source_id       = r_orig_sys_doc_ref.order_source_id
           AND request_id            = r_orig_sys_doc_ref.request_id;

       UPDATE ont.oe_payments_iface_all
          SET credit_card_holder_name = lc_customer_name
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
        WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
          AND order_source_id       = r_orig_sys_doc_ref.order_source_id
          AND request_id            = r_orig_sys_doc_ref.request_id;

        END IF;
     fnd_file.put_line(FND_FILE.LOG,'After the updates payments iface in 10000002');
    END IF;


    IF  r_orig_sys_doc_ref.message_num = '10000015'
    AND r_orig_sys_doc_ref.ship_from_org IS NOT NULL THEN
      fnd_file.put_line(FND_FILE.LOG,'Inside the message num 1000000015');
      Get_10000015( p_orig_sys_documen_ref => r_orig_sys_doc_ref.original_sys_document_ref
                    , p_orig_sys_line_ref   => r_orig_sys_doc_ref.original_sys_document_line_ref
                    , p_order_source_id     => r_orig_sys_doc_ref.order_source_id
                    , p_request_id          => r_orig_sys_doc_ref.request_id
                    , p_message_number      => r_orig_sys_doc_ref.message_num
                    , x_ship_from_org_id    => ln_ship_from_org_id
                    , x_status              => lc_status
                    );
        fnd_file.put_line(FND_FILE.LOG,'After the get message num 1000000015');
        IF lc_status = 'S' THEN
            UPDATE ont.oe_headers_iface_all
               SET ship_from_org_id = ln_ship_from_org_id
                 , last_updated_by   = FND_GLOBAL.USER_ID
                 , last_update_date  = SYSDATE
             WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
               AND order_source_id       = r_orig_sys_doc_ref.order_source_id
               AND request_id            = r_orig_sys_doc_ref.request_id;

            UPDATE ont.oe_lines_iface_all
               SET ship_from_org_id = ln_ship_from_org_id
                 , ship_from_org    = null
                 , last_updated_by   = FND_GLOBAL.USER_ID
                 , last_update_date  = SYSDATE
             WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
               AND order_source_id       = r_orig_sys_doc_ref.order_source_id
               AND orig_sys_line_ref     = r_orig_sys_doc_ref.original_sys_document_line_ref
               AND request_id            = r_orig_sys_doc_ref.request_id;
         END IF;
     fnd_file.put_line(FND_FILE.LOG,' Status for 10000015 :::'||lc_status);
     fnd_file.put_line(FND_FILE.LOG,'After the updates inside 10000015');
    END IF;


    IF r_orig_sys_doc_ref.message_num = '10000018' THEN

    fnd_file.put_line(FND_FILE.LOG,'Inside 10000018');
    DBMS_OUTPUT.PUT_LINE('Inside 10000018');
      Get_10000018_17 ( p_orig_sys_documen_ref => r_orig_sys_doc_ref.original_sys_document_ref
                      , p_orig_sys_line_ref    => r_orig_sys_doc_ref.original_sys_document_line_ref
                      , p_order_source_id      => r_orig_sys_doc_ref.order_source_id
                      , p_request_id           => r_orig_sys_doc_ref.request_id
                      , p_message_number       => r_orig_sys_doc_ref.message_num
                      , x_inventory_item_id    => ln_inventory_item_id
                      , x_ship_from_org_id     => ln_ship_from_org_id
                      , x_status               => lc_status
                      );

    fnd_file.put_line(FND_FILE.LOG,' Status for 10000018 :::'||lc_status);

    ELSIF r_orig_sys_doc_ref.message_num = '10000017' THEN

      Get_10000018_17 ( p_orig_sys_documen_ref => r_orig_sys_doc_ref.original_sys_document_ref
                      , p_orig_sys_line_ref    => r_orig_sys_doc_ref.original_sys_document_line_ref
                      , p_order_source_id      => r_orig_sys_doc_ref.order_source_id
                      , p_request_id           => r_orig_sys_doc_ref.request_id
                      , p_message_number       => r_orig_sys_doc_ref.message_num
                      , x_inventory_item_id    => ln_inventory_item_id
                      , x_ship_from_org_id     => ln_ship_from_org_id
                      , x_status               => lc_status
                      );

    DBMS_OUTPUT.PUT_LINE(' Status for 10000017 :::'||lc_status);

        IF lc_status = 'S' THEN

            UPDATE ont.oe_lines_iface_all
               SET inventory_item_id = ln_inventory_item_id
                 , last_updated_by   = FND_GLOBAL.USER_ID
                 , last_update_date  = SYSDATE
             WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
               AND order_source_id       = r_orig_sys_doc_ref.order_source_id
               AND orig_sys_line_ref     = r_orig_sys_doc_ref.original_sys_document_line_ref
               AND request_id            = r_orig_sys_doc_ref.request_id;
        COMMIT;
        END IF;
        fnd_file.put_line(FND_FILE.LOG,'After the updates inside 100000017');
    END IF;

    IF r_orig_sys_doc_ref.message_num = '10000010'
    AND r_orig_sys_doc_ref.sold_to_org IS NOT NULL THEN
        fnd_file.put_line(FND_FILE.LOG,'Inside error num 10000010');
        Get_10000010 ( p_orig_sys_document_ref => r_orig_sys_doc_ref.original_sys_document_ref
                     , p_request_id            => r_orig_sys_doc_ref.request_id
                     , p_order_source_id       => r_orig_sys_doc_ref.order_source_id
                     , x_sold_to_org_id        => ln_sold_to_org_id
                     , x_invoice_to_org_id     => ln_invoice_to_org_id
                     , x_ship_to_org_id        => ln_ship_to_org_id
                     , x_customer_name         => lc_customer_name
                     , x_sold_to_contact_id    => ln_sold_to_contact_id
                     , x_geocode               => lc_geocode
                     , x_payment_term_id       => ln_payment_term_id
                     , x_status                => lc_status
                     );

     fnd_file.put_line(FND_FILE.LOG,' Status for 10000010 :::'||lc_status);

        IF lc_status = 'S' THEN

        UPDATE ont.oe_headers_iface_all
           SET sold_to_org_id    = ln_sold_to_org_id
             , sold_to_org       = NULL
             , invoice_to_org_id = ln_invoice_to_org_id
             , ship_to_org_id    = ln_ship_to_org_id
             , ship_to_org       = NULL
             , sold_to_contact_id = ln_sold_to_contact_id
             , payment_term_id    = ln_payment_term_id
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
         WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
           AND order_source_id       = r_orig_sys_doc_ref.order_source_id
           AND request_id            = r_orig_sys_doc_ref.request_id;

        UPDATE xxom.xx_om_headers_attr_iface_all
           SET SHIP_TO_GEOCODE   = lc_geocode
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
         WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
           AND order_source_id       = r_orig_sys_doc_ref.order_source_id
           AND request_id            = r_orig_sys_doc_ref.request_id;

        UPDATE ont.oe_lines_iface_all
           SET sold_to_org_id    = ln_sold_to_org_id
             , invoice_to_org_id = ln_invoice_to_org_id
             , ship_to_org_id    = ln_ship_to_org_id
             , payment_term_id    = ln_payment_term_id
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
         WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
           AND order_source_id       = r_orig_sys_doc_ref.order_source_id
           AND request_id            = r_orig_sys_doc_ref.request_id;

       UPDATE ont.oe_payments_iface_all
          SET credit_card_holder_name = lc_customer_name
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
        WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
          AND order_source_id       = r_orig_sys_doc_ref.order_source_id
          AND request_id            = r_orig_sys_doc_ref.request_id;
        COMMIT;
        END IF;
    fnd_file.put_line(FND_FILE.LOG,'After the updates inside err msg 10');
    END IF;

    IF r_orig_sys_doc_ref.message_num = '10000016'
    AND r_orig_sys_doc_ref.ship_to_org IS NOT NULL THEN
        fnd_file.put_line(FND_FILE.LOG,'Inside error num 10000016');
        Get_10000016 ( p_orig_sys_document_ref => r_orig_sys_doc_ref.original_sys_document_ref
                     , p_request_id            => r_orig_sys_doc_ref.request_id
                     , p_order_source_id       => r_orig_sys_doc_ref.order_source_id
                     , x_ship_to_org_id        => ln_ship_to_org_id
                     , x_invoice_to_org_id     => ln_invoice_to_org_id
                     , x_geocode               => lc_geocode
                     , x_status                => lc_status
                     );


    IF lc_status = 'S' THEN
        UPDATE ont.oe_headers_iface_all
           SET ship_to_org_id    = ln_ship_to_org_id
             , ship_to_org       = NULL
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
         WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
           AND order_source_id       = r_orig_sys_doc_ref.order_source_id
           AND request_id            = r_orig_sys_doc_ref.request_id;

        UPDATE xxom.xx_om_headers_attr_iface_all
           SET SHIP_TO_GEOCODE   = lc_geocode
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
         WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
           AND order_source_id       = r_orig_sys_doc_ref.order_source_id
           AND request_id            = r_orig_sys_doc_ref.request_id;

        UPDATE ont.oe_lines_iface_all
           SET ship_to_org_id    = ln_ship_to_org_id
             , last_updated_by   = FND_GLOBAL.USER_ID
             , last_update_date  = SYSDATE
         WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
           AND order_source_id       = r_orig_sys_doc_ref.order_source_id
           AND request_id            = r_orig_sys_doc_ref.request_id;
           COMMIT;
      END IF;
     fnd_file.put_line(FND_FILE.LOG,'Status for 10000016 :::'||lc_status);
   END IF;



    IF r_orig_sys_doc_ref.message_num = '10000021'
    AND r_orig_sys_doc_ref.sold_to_org_id IS NOT NULL
    AND r_orig_sys_doc_ref.invoice_to_org_id IS NULL THEN
        fnd_file.put_line(FND_FILE.LOG,'Inside error num 10000021');
        Get_10000021 ( p_orig_sys_document_ref => r_orig_sys_doc_ref.original_sys_document_ref
                     , p_request_id            => r_orig_sys_doc_ref.request_id
                     , p_order_source_id       => r_orig_sys_doc_ref.order_source_id
                     , x_invoice_to_org_id     => ln_invoice_to_org_id
                     , x_status                => lc_status
                     );

             IF lc_status = 'S' THEN
                 UPDATE ont.oe_headers_iface_all
                    SET invoice_to_org_id    = ln_invoice_to_org_id
                      , last_updated_by   = FND_GLOBAL.USER_ID
                      , last_update_date  = SYSDATE
                 WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
                   AND order_source_id       = r_orig_sys_doc_ref.order_source_id
                   AND request_id            = r_orig_sys_doc_ref.request_id;


                 UPDATE ont.oe_lines_iface_all
                    SET invoice_to_org_id    = ln_invoice_to_org_id
                      , last_updated_by   = FND_GLOBAL.USER_ID
                      , last_update_date  = SYSDATE
                  WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
                    AND order_source_id       = r_orig_sys_doc_ref.order_source_id
                    AND request_id            = r_orig_sys_doc_ref.request_id;
      END IF;

    fnd_file.put_line(FND_FILE.LOG,' Status for 10000021 :::'||lc_status);
    END IF;

    IF r_orig_sys_doc_ref.message_num = '10000022'
    AND r_orig_sys_doc_ref.sold_to_org_id IS NOT NULL
    AND r_orig_sys_doc_ref.ship_to_org_id IS NULL THEN
        fnd_file.put_line(FND_FILE.LOG,'Inside error num 10000022');
        Get_10000022 ( p_sold_to_org_id   => r_orig_sys_doc_ref.sold_to_org_id
                     , x_shipto_org_id    => ln_ship_to_org_id
                     , x_status           => lc_status
                     );
        fnd_file.put_line(FND_FILE.LOG,' Status for 10000022 :::'||lc_status);
        IF lc_status = 'S' THEN

            UPDATE ont.oe_headers_iface_all
               SET ship_to_org_id    = ln_ship_to_org_id
                 , last_updated_by   = FND_GLOBAL.USER_ID
                 , last_update_date  = SYSDATE
             WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
                AND order_source_id       = r_orig_sys_doc_ref.order_source_id
                AND request_id            = r_orig_sys_doc_ref.request_id;


            UPDATE ont.oe_lines_iface_all
               SET ship_to_org_id    = ln_ship_to_org_id
                 , last_updated_by   = FND_GLOBAL.USER_ID
                 , last_update_date  = SYSDATE
             WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
               AND order_source_id       = r_orig_sys_doc_ref.order_source_id
               AND request_id            = r_orig_sys_doc_ref.request_id;
        END IF;
    END IF;

      FOR r_more_msgs IN c_more_msgs( r_orig_sys_doc_ref.request_id
                                    , r_orig_sys_doc_ref.original_sys_document_ref
                                    , r_orig_sys_doc_ref.order_source_id
                                    ) LOOP

        IF r_more_msgs.msgs_count = 0 THEN
            fnd_file.put_line(FND_FILE.LOG,' More Messages :::'||r_more_msgs.msgs_count);
        ln_line_count := 0;
        ln_error_count :=0;

          FOR r_validation IN c_validation( r_orig_sys_doc_ref.request_id
                                          , r_orig_sys_doc_ref.original_sys_document_ref
                                          , r_orig_sys_doc_ref.order_source_id
                                          ) LOOP

              IF  r_validation.sold_to_org_id IS NOT NULL
              AND r_validation.ship_to_org_id  IS NOT NULL
              AND r_validation.invoice_to_org_id IS NOT NULL
              AND r_validation.ship_from_org_id IS NOT NULL
              AND r_validation.inventory_item_id IS NOT NULL THEN

                lc_ord_status := 'S';
                ln_line_count := ln_line_count +1;
              ELSE
                lc_ord_status := 'N';
                ln_error_count := ln_error_count + 1;

              END IF;
          END LOOP; -- r_validation
       END IF;
    END LOOP; --r_more_msgs
       fnd_file.put_line(FND_FILE.LOG,' Lines error count: '|| ln_error_count);
       IF lc_ord_status = 'S' AND ln_error_count = 0  THEN

      UPDATE ont.oe_headers_iface_all
                 SET request_id = NULL
                   , error_flag = NULL
                   , last_update_date = SYSDATE
                   , last_updated_by = FND_GLOBAL.USER_ID
               WHERE orig_sys_document_ref = r_orig_sys_doc_ref.original_sys_document_ref
                 AND order_source_id       = r_orig_sys_doc_ref.order_source_id
                 AND request_id            = r_orig_sys_doc_ref.request_id;

    fnd_file.put_line(FND_FILE.LOG,' Total orders updated : '|| SQL%ROWCOUNT);
    fnd_file.put_line(FND_FILE.LOG,' UPDATE ORIGINAL SYS DOCUMENT REF:::'||r_orig_sys_doc_ref.original_sys_document_ref);
      COMMIT;
      END IF;


  END LOOP; -- r_org_sys_doc_ref
  
  COMMIT;
EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others raised in main Procedure: '|| SQLERRM);

END get_orig_sys_document_ref;


PROCEDURE Get_10000002 ( p_orig_sys_document_ref IN VARCHAR2
                       , p_request_id            IN NUMBER
                       , p_order_source_id       IN NUMBER
                       , x_sold_to_org_id       OUT NOCOPY NUMBER
                       , x_invoice_to_org_id    OUT NOCOPY NUMBER
                       , x_ship_to_org_id       OUT NOCOPY NUMBER
                       , x_customer_name        OUT NOCOPY VARCHAR2
                       , x_status               OUT NOCOPY VARCHAR2
                       ) IS


  CURSOR c_spc_card ( p_orig_sys_doc_ref IN VARCHAR2
                    , p_req_id           IN NUMBER ) IS

  SELECT orig_sys_document_ref
       , order_source_id
       , spc_card_number
    FROM xxom.xx_om_headers_attr_iface_all
   WHERE orig_sys_document_ref = p_orig_sys_doc_ref
     AND order_source_id = p_order_source_id
     AND request_id = p_req_id;

   CURSOR c_customer_info ( p_spc_card_num IN VARCHAR2 ) IS

   SELECT e.cust_account_id     ebs_cust_account_id
        , e.N_EXT_ATTR1      spc_card_number
        , e.N_EXT_ATTR20     ebs_batch_id
        , as1.cust_acct_site_id
        , asu.site_use_id    ship_to_org_id
        , inasu.site_use_id  invoice_to_org_id
        , hp.party_name      customer_name
     FROM apps.XX_CDH_CUST_ACCT_EXT_B e
        , ar.hz_cust_accounts a
        , ar.hz_parties hp
        , ar.hz_cust_acct_sites_all as1
        , ar.hz_cust_site_uses_all asu
        , ar.hz_cust_acct_sites_all inas1
        , ar.hz_cust_site_uses_all inasu
    WHERE a.cust_account_id = e.cust_account_id
      AND a.cust_account_id = as1.cust_account_id
      AND as1.cust_acct_site_id = asu.cust_acct_site_id
      AND asu.site_use_code = 'SHIP_TO'
      AND e.attr_group_id=171
      AND asu.primary_flag = 'Y'
      AND a.cust_account_id = inas1.cust_account_id
      AND inas1.cust_acct_site_id = inasu.cust_acct_site_id
      AND inasu.site_use_code = 'BILL_TO'
      AND inasu.primary_flag = 'Y'
      AND a.party_id = hp.party_id
      AND e.n_ext_attr1 = p_spc_card_num;


BEGIN
  x_status := 'E';
  FOR r_spc_card IN c_spc_card ( p_orig_sys_document_ref
                               , p_request_id ) LOOP

    FOR r_customer_info IN c_customer_info (r_spc_card.spc_card_number) LOOP

    x_sold_to_org_id := r_customer_info.ebs_cust_account_id;
    x_invoice_to_org_id := r_customer_info.invoice_to_org_id;
    x_ship_to_org_id    := r_customer_info.ship_to_org_id;
    x_customer_name     := r_customeR_info.customer_name;

    IF   x_sold_to_org_id IS NOT NULL
     AND x_invoice_to_org_id IS NOT NULL
     AND x_ship_to_org_id IS NOT NULL
     AND x_customer_name  IS NOT NULL THEN


     x_status := 'S';

    ELSE

     x_status := 'E';

    END IF;
    END LOOP; --r_customer_info

  END LOOP; --r_spc_card


EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others raised in Get_10000002: '|| SQLERRM);
    x_status := 'E';

END Get_10000002;

PROCEDURE GET_10000015 ( p_orig_sys_documen_ref IN VARCHAR2
                       , p_orig_sys_line_ref    IN VARCHAR2
                       , p_order_source_id      IN NUMBER
                       , p_request_id           IN NUMBER
                       , p_message_number       IN VARCHAR2
                       , x_ship_from_org_id    OUT NOCOPY NUMBER
                       , x_status              OUT NOCOPY VARCHAR2
                       ) IS

  CURSOR c_ship_from_org_id ( p_orig_sys_doc_ref IN VARCHAR2
                            , p_orig_sys_ln_ref  IN VARCHAR2
                            , p_req_id           IN NUMBER
                            , p_ord_source_id    IN NUMBER
                            , p_message_num      IN VARCHAR2
                            ) IS

  SELECT ou.organization_id
    FROM apps.oe_processing_msgs_vl om
       , apps.hr_all_organization_units ou
   WHERE SUBSTR(om.message_text, 74, INSTR(SUBSTR(om.message_text, 74), '. ', 1) -1) = ou.attribute1
     AND SUBSTR(om.message_text,1,8)       = p_message_num
     AND om.original_sys_document_ref      = p_orig_sys_doc_ref
     AND om.original_sys_document_line_ref = p_orig_sys_ln_ref
     AND om.order_source_id                = p_ord_source_id
     AND om.request_id                     = p_req_id;

BEGIN
  x_status := 'E';
  
  FOR r_ship_from_org_id in c_ship_from_org_id ( p_orig_sys_documen_ref
                                               , p_orig_sys_line_ref
                                               , p_request_id
                                               , p_order_source_id
                                               , p_message_number
                                               ) LOOP
    fnd_file.put_line(FND_FILE.LOG,' Inside loop ship_from org id 1');

    IF r_ship_from_org_id.organization_id IS NOT NULL THEN

    x_ship_from_org_id := r_ship_from_org_id.organization_id;

    x_status := 'S';

    ELSE

    x_ship_from_org_id := NULL;

    x_status := 'E';

    END IF;

END LOOP; --r_ship_org_id

EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others raised in Get_10000015: '|| SQLERRM);
    x_status := 'E';

END GET_10000015;

PROCEDURE Get_10000018_17 ( p_orig_sys_documen_ref IN VARCHAR2
                          , p_orig_sys_line_ref    IN VARCHAR2
                          , p_order_source_id      IN NUMBER
                          , p_request_id           IN NUMBER
                          , p_message_number       IN VARCHAR2
                          , x_inventory_item_id   OUT NOCOPY NUMBER
                          , x_ship_from_org_id    OUT NOCOPY NUMBER
                          , x_status              OUT NOCOPY VARCHAR2
                          ) IS

  CURSOR c_item_assigned ( p_org_sys_doc_ref  IN VARCHAR2
                         , p_org_sys_ln_ref   IN VARCHAR2
                         , p_ord_source_id    IN NUMBER
                         , p_req_id           IN NUMBER
                         , p_message_num      IN VARCHAR2
                         ) IS
  SELECT msi.organization_id
       , msi.inventory_item_id
    FROM inv.mtl_system_items_b msi
       , ont.oe_lines_iface_all ol
       , apps.oe_processing_msgs_vl op
   WHERE op.original_sys_document_ref      = p_org_sys_doc_ref
     AND op.original_sys_document_line_ref = p_org_sys_ln_ref
     AND op.order_source_id                = p_order_source_id
     AND op.request_id                     = p_request_id
     AND SUBSTR(op.message_text,1,8)       = p_message_num
     AND op.original_sys_document_ref      = ol.orig_sys_document_ref
     AND op.original_sys_document_line_ref = ol.orig_sys_line_ref
     AND op.order_source_id                = ol.order_source_id
     AND op.request_id                     = ol.request_id
     AND ol.inventory_item_id              = msi.inventory_item_id
     AND ol.ship_from_org_id               = msi.organization_id
  UNION
  SELECT msi.organization_id
       , msi.inventory_item_id
    FROM inv.mtl_system_items_b msi
       , ont.oe_lines_iface_all ol
       , apps.oe_processing_msgs_vl op
   WHERE op.original_sys_document_ref      = p_org_sys_doc_ref
     AND op.original_sys_document_line_ref = p_org_sys_ln_ref
     AND op.order_source_id                = p_order_source_id
     AND op.request_id                     = p_request_id
     AND SUBSTR(op.message_text,1,8)       = p_message_num
     AND op.original_sys_document_ref      = ol.orig_sys_document_ref
     AND op.original_sys_document_line_ref = ol.orig_sys_line_ref
     AND op.order_source_id                = ol.order_source_id
     AND op.request_id                     = ol.request_id
     AND TRIM(SUBSTR(message_text, 36 ,INSTR(SUBSTR(message_text,36),' ',1))) = msi.segment1
     AND ol.ship_from_org_id               = msi.organization_id;

BEGIN
  x_status := 'E';
  fnd_file.put_line(FND_FILE.LOG,'Inside error num 10000018');
  FOR r_item_assigned IN c_item_assigned ( p_orig_sys_documen_ref
                                         , p_orig_sys_line_ref
                                         , p_order_source_id
                                         , p_request_id
                                         , p_message_number
                                         ) LOOP

  IF r_item_assigned.inventory_item_id IS NOT NULL
  AND r_item_assigned.organization_id IS NOT NULL THEN

    x_inventory_item_id := r_item_assigned.inventory_item_id;
    x_ship_from_org_id  := r_item_assigned.organization_id;
    x_status            := 'S';
  ELSE
   x_status := 'E';
  END IF;
  END LOOP; -- r_item_assigned
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       x_status := 'E';
       fnd_file.put_line(FND_FILE.LOG,'WHEN NO DATA FOUND ::'||x_status);
    WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others raised in Get_10000018_17: '|| SQLERRM);
    x_status := 'E';

END Get_10000018_17;

PROCEDURE Get_10000010 ( p_orig_sys_document_ref IN VARCHAR2
                       , p_request_id            IN NUMBER
                       , p_order_source_id       IN NUMBER
                       , x_sold_to_org_id       OUT NOCOPY NUMBER
                       , x_invoice_to_org_id    OUT NOCOPY NUMBER
                       , x_ship_to_org_id       OUT NOCOPY NUMBER
                       , x_customer_name        OUT NOCOPY VARCHAR2
                       , x_sold_to_contact_id   OUT NOCOPY NUMBER
                       , x_geocode              OUT NOCOPY VARCHAR2
                       , x_payment_term_id      OUT NOCOPY NUMBER
                       , x_status           OUT NOCOPY VARCHAR2
                       ) IS

  CURSOR c_sold_to_org_id ( p_orig_sys_doc_ref IN VARCHAR2
                          , p_req_id           IN NUMBER
                          , p_ord_source_id    IN NUMBER
                          ) IS
  SELECT oh.orig_sys_document_ref
       , oh.order_source_id
       , oh.ordered_date
       , xx.ship_to_address1
       , xx.ship_to_address2
       , xx.ship_to_city
       , xx.ship_to_state
       , xx.ship_to_country
       , xx.ship_to_zip
       , oh.sold_to_org
       , oh.ship_to_org
       , oh.sold_to_contact
    FROM ont.oe_headers_iface_all oh
        , xxom.xx_om_headers_attr_iface_all xx
   WHERE oh.orig_sys_document_ref = p_orig_sys_doc_ref
     AND oh.order_source_id = p_ord_source_id
     AND oh.request_id      = p_req_id
     AND oh.orig_sys_document_ref = xx.orig_sys_document_ref
     AND oh.order_source_id = xx.order_source_id
     AND oh.request_id      = xx.request_id;

lc_return_status VARCHAR2(1);
lc_status        VARCHAR2(1);

BEGIN
  x_status := 'E';
  FOR r_sold_to_org_id IN c_sold_to_org_id( p_orig_sys_document_ref
                                          , p_request_id
                                          , p_order_source_id
                                          ) LOOP
                                          
      fnd_file.put_line(FND_FILE.LOG,'Inside deriving sold_to_org_id');

      HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id(
                                                 p_orig_system           => 'A0'
                                               , p_orig_system_reference => r_sold_to_org_id.sold_to_org
                                               , p_owner_table_name      => 'HZ_CUST_ACCOUNTS'
                                               , x_owner_table_id        => x_sold_to_org_id
                                               , x_return_status         =>  lc_return_status );

     IF x_sold_to_org_id IS NOT NULL AND lc_return_status = 'S' THEN

         HZ_ORIG_SYSTEM_REF_PUB.get_owner_table_id( p_orig_system           => 'A0'
                                                  , p_orig_system_reference => r_sold_to_org_id.sold_to_contact
                                                  , p_owner_table_name      =>'HZ_CUST_ACCOUNT_ROLES'
                                                  , x_owner_table_id        => x_sold_to_contact_id
                                                  , x_return_status         =>  lc_return_status);

         BEGIN

         SELECT status
           INTO lc_status
           FROM HZ_CUST_ACCOUNT_ROLES
          WHERE cust_account_role_id = x_sold_to_contact_id
            AND cust_account_id      =  x_sold_to_org_id
            AND status               = 'A';

           IF lc_status IS NULL THEN
               x_sold_to_contact_id := NULL;
           END IF;

         EXCEPTION

         WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others sold to contact id: '||SQLERRM );

         END;

         BEGIN
         SELECT party_name
           INTO x_customer_name
           FROM hz_cust_accounts hca
              , hz_parties hp
          WHERE hca.cust_account_id = x_sold_to_org_id
            AND hca.party_id = hp.party_id;

         EXCEPTION

         WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others customer name: '||SQLERRM );

         END;

         fnd_file.put_line(FND_FILE.LOG,' Before calling derive ship to');
         xx_om_sacct_conc_pkg.Derive_Ship_To( p_orig_sys_document_ref => r_sold_to_org_id.orig_sys_document_ref
                                            , p_sold_to_org_id        => x_sold_to_org_id
                                            , p_order_source_id       => r_sold_to_org_id.order_source_id
                                            , p_orig_sys_ship_ref     => r_sold_to_org_id.ship_to_org
                                            , p_ordered_date          => r_sold_to_org_id.ordered_date
                                            , p_address_line1         => r_sold_to_org_id.ship_to_address1
                                            , p_address_line2         => r_sold_to_org_id.ship_to_address2
                                            , p_city                  => r_sold_to_org_id.ship_to_city
                                            , p_state                 => r_sold_to_org_id.ship_to_state
                                            , p_country               => r_sold_to_org_id.ship_to_country
                                            , p_province              => ''
                                            , p_postal_code           => r_sold_to_org_id.ship_to_zip
                                            , p_order_source          => ''
                                            , x_ship_to_org_id        => x_ship_to_org_id
                                            , x_invoice_to_org_id     => x_invoice_to_org_id
                                            , x_ship_to_geocode       => x_geocode
                                            );

          xx_om_sacct_conc_pkg.Get_Def_Billto( x_sold_to_org_id
                                             , x_invoice_to_org_id);

           SELECT xx_om_sacct_conc_pkg.payment_term(x_sold_to_org_id)
             INTO x_payment_term_id
             FROM dual;

     END IF;

     IF x_sold_to_org_id IS NOT NULL
    AND x_ship_to_org_id IS NOT NULL
    AND x_invoice_to_org_id IS NOT NULL
    AND x_geocode IS NOT NULL
    AND x_payment_term_id IS NOT NULL THEN

         x_status := 'S';
     ELSE
         x_status := 'E';

     END IF;

  END LOOP; -- r_sold_to_org_id

EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others raised in Get_10000010: '|| SQLERRM);
    x_status := 'E';

END Get_10000010;

PROCEDURE Get_10000016 ( p_orig_sys_document_ref IN VARCHAR2
                       , p_request_id            IN NUMBER
                       , p_order_source_id       IN NUMBER
                       , x_ship_to_org_id       OUT NOCOPY NUMBER
                       , x_invoice_to_org_id    OUT NOCOPY NUMBER
                       , x_geocode              OUT NOCOPY VARCHAR2
                       , x_status               OUT NOCOPY VARCHAR2
                       ) IS

  CURSOR c_ship_to_org_id ( p_orig_sys_doc_ref IN VARCHAR2
                          , p_req_id           IN NUMBER
                          , p_ord_source_id    IN NUMBER
                          ) IS
  SELECT ohi.orig_sys_document_ref
       , ohi.order_source_id
       , ohi.sold_to_org_id
       , ohi.ship_to_org
       , ohi.ordered_date
       , xoh.ship_to_address1
       , xoh.ship_to_address2
       , xoh.ship_to_city
       , xoh.ship_to_state
       , xoh.ship_to_country
       , xoh.ship_to_zip
    FROM xxom.xx_om_headers_attr_iface_all xoh
       , ont.oe_headers_iface_all ohi
   WHERE ohi.orig_sys_document_ref = p_orig_sys_doc_ref
     AND ohi.order_source_id       = p_ord_source_id
     AND ohi.request_id            = p_req_id
     AND ohi.orig_sys_document_ref = xoh.orig_sys_document_ref
     AND ohi.order_source_id       = xoh.order_source_id
     AND ohi.request_id            = xoh.request_id;

BEGIN
    x_status := 'E';
fnd_file.put_line(FND_FILE.LOG,'Inside the Get_10000016');

    FOR r_ship_to_org_id IN c_ship_to_org_id( p_orig_sys_document_ref
                                            , p_request_id
                                            , p_order_source_id
                                            ) LOOP

fnd_file.put_line(FND_FILE.LOG,'The orig sys is '|| p_orig_sys_document_ref);
fnd_file.put_line(FND_FILE.LOG,'The request id is' || p_request_id);

        IF r_ship_to_org_id.ship_to_org is NOT NULL THEN

            xx_om_sacct_conc_pkg.Derive_Ship_To( p_orig_sys_document_ref => r_ship_to_org_id.orig_sys_document_ref
                                               , p_sold_to_org_id        => r_ship_to_org_id.sold_to_org_id
                                               , p_order_source_id       => r_ship_to_org_id.order_source_id
                                               , p_orig_sys_ship_ref     => r_ship_to_org_id.ship_to_org
                                               , p_ordered_date          => r_ship_to_org_id.ordered_date
                                               , p_address_line1         => r_ship_to_org_id.ship_to_address1
                                               , p_address_line2         => r_ship_to_org_id.ship_to_address2
                                               , p_city                  => r_ship_to_org_id.ship_to_city
                                               , p_state                 => r_ship_to_org_id.ship_to_state
                                               , p_country               => r_ship_to_org_id.ship_to_country
                                               , p_province              => ''
                                               , p_postal_code           => r_ship_to_org_id.ship_to_zip
                                               , p_order_source          => ''
                                               , x_ship_to_org_id        => x_ship_to_org_id
                                               , x_invoice_to_org_id     => x_invoice_to_org_id
                                               , x_ship_to_geocode       => x_geocode
                                               );

        END IF;


      IF x_ship_to_org_id IS NOT NULL THEN
          x_status         := 'S';

      ELSE
          x_status         := 'E';

      END IF;
    END LOOP; --r_ship_to_org_id
    

EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others raised in Get_10000016: '|| SQLERRM);
    x_status := 'E';

    DBMS_OUTPUT.PUT_LINE(' when others for 10000016 :::'||x_status);

END Get_10000016;

PROCEDURE Get_10000021 ( p_orig_sys_document_ref IN VARCHAR2
                       , p_request_id            IN NUMBER
                       , p_order_source_id       IN NUMBER
                       , x_invoice_to_org_id       OUT NOCOPY NUMBER
                       , x_status               OUT NOCOPY VARCHAR2
                       ) IS

  CURSOR c_invoice_to_org_id ( p_orig_sys_doc_ref IN VARCHAR2
                             , p_req_id           IN NUMBER
                             , p_ord_source_id    IN NUMBER
                             ) IS

   SELECT sold_to_org_id
     FROM ont.oe_headers_iface_all
    WHERE orig_sys_document_ref = p_orig_sys_doc_ref
      AND order_source_id       = p_ord_source_id
      AND request_id            = p_req_id;

BEGIN
    x_status := 'E';
    FOR r_invoice_to_org_id IN c_invoice_to_org_id( p_orig_sys_document_ref
                                                  , p_request_id
                                                  , p_order_source_id
                                                  ) LOOP

     IF r_invoice_to_org_id.sold_to_org_id IS NOT NULL THEN

       xx_om_sacct_conc_pkg.Get_Def_BillTo( p_cust_account_id => r_invoice_to_org_id.sold_to_org_id
                                          , x_bill_to_org_id => x_invoice_to_org_id
                                          );

     END IF;


      IF x_invoice_to_org_id IS NOT NULL THEN
          x_status         := 'S';

      ELSE
          x_status         := 'E';

      END IF;
    END LOOP; --r_invoice_to_org_id



EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others raised in Get_10000021: '|| SQLERRM);
    x_status := 'E';

END Get_10000021;

PROCEDURE Get_10000022 ( p_sold_to_org_id       IN NUMBER
                       , x_shipto_org_id       OUT NOCOPY NUMBER
                       , x_status               OUT NOCOPY VARCHAR2
                       ) IS

 BEGIN
    x_status := 'E';
  IF p_sold_to_org_id IS NOT NULL THEN
      xx_om_sacct_conc_pkg.Get_Def_Shipto
                          ( p_cust_account_id => p_sold_to_org_id
                          , x_ship_to_org_id  => x_shipto_org_id);
      IF x_shipto_org_id IS NOT NULL THEN
          x_status := 'S';
      ELSE
          x_status := 'E';
      END IF;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(FND_FILE.LOG,'When Others raised in Get_10000022: '|| SQLERRM);
    x_status := 'E';

END Get_10000022;

END XX_OM_ERRORS_RETRY_PKG;
/
SHOW ERRORS PACKAGE BODY XX_OM_ERRORS_RETRY_PKG;

EXIT;