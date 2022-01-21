CREATE OR REPLACE PACKAGE APPS.xx_arp_consinv AUTHID CURRENT_USER AS
/** $Header: ARPCBIS.pls 120.2 2005/08/01 11:02:10 naneja ship $            **/

    TYPE ReportParametersType Is RECORD
    (
        print_option          VARCHAR2(12),
        detail_option         VARCHAR2(8),
        currency_code         VARCHAR2(15),
        customer_id           NUMBER(15),
        customer_number       VARCHAR2(30),
        bill_to_site          NUMBER(15),
        cutoff_date           DATE,
        last_day_of_month     VARCHAR2(1),
        interim_cutoff_date   DATE,                  --Added for Prod defect # 6693 on 06-JUL-10
        term_id               NUMBER(15),
        consinv_id            NUMBER(15),
        request_id            NUMBER(15),
        print_status          VARCHAR2(8));
--
    PROCEDURE Report( P_report IN ReportParametersType );
    PROCEDURE Report( P_print_option    VARCHAR2,
                      P_detail_option   VARCHAR2,
                      P_currency_code   VARCHAR2,
                      P_customer_id     NUMBER,
                      P_customer_number VARCHAR2,
                      P_bill_to_site    NUMBER,
                      P_cutoff_date     DATE,
                      P_last_day_of_month VARCHAR2,
                      P_interim_cut_off_date DATE,    --Added for Prod defect # 6693 on 06-JUL-10
                      P_term_id         NUMBER,
                      P_consinv_id      NUMBER,
                      P_request_id      NUMBER,
                      P_print_status    VARCHAR2);
--
END;
/
