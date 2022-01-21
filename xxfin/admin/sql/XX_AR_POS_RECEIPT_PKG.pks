CREATE OR REPLACE PACKAGE apps.xx_ar_pos_receipt_pkg
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  XX_AR_POS_RECEIPT_PKG                                                              |
-- |                                                                                            |
-- |  Description:  This package creates and applies cash receipts for POS Receipts             |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         18-Mar-2011  R.Strauss            Initial version                              |
-- | 1.1         25-feb-2104  V Deepak             Changes for Defect 27868.                    |
-- | 2.0         16-Mar-2014  Edson Morales        Changes for Defect 27868                     |
-- +============================================================================================+
    PROCEDURE create_summary_receipt(
        errbuf        OUT NOCOPY     VARCHAR2,
        retcode       OUT NOCOPY     NUMBER,
        p_org_id      IN             NUMBER,
        p_store_num   IN             VARCHAR2,
        p_rcpt_date   IN             DATE,
        p_pay_type    IN             VARCHAR2,
        p_debug_flag  IN             VARCHAR2);
		
		PROCEDURE CREATE_APPLY_SUBSC_REVREC_RCPT(
        errbuf        OUT NOCOPY     VARCHAR2,
        retcode       OUT NOCOPY     NUMBER,
        p_org_id      IN             NUMBER,
        p_store_num   IN             VARCHAR2,
        p_rcpt_date   IN             DATE,
        p_pay_type    IN             VARCHAR2,
        p_debug_flag  IN             VARCHAR2);


    PROCEDURE apply_summary_receipt_child(
        errbuf              OUT NOCOPY     VARCHAR2,
        retcode             OUT NOCOPY     NUMBER,
        p_org_id            IN             NUMBER,
        p_rcpt_date         IN             VARCHAR2,
        p_tolerance         IN             NUMBER,
        p_debug_flag        IN             VARCHAR2,
        p_min_store_number  IN             VARCHAR2,
        p_max_store_number  IN             VARCHAR2);

    PROCEDURE sync_manual_write_offs(
        errbuf        OUT NOCOPY     VARCHAR2,
        retcode       OUT NOCOPY     NUMBER,
        p_org_id      IN             NUMBER,
        p_store_num   IN             VARCHAR2,
        p_rcpt_date   IN             DATE,
        p_debug_flag  IN             VARCHAR2);

    PROCEDURE apply_summary_receipt(
        errbuf                   OUT NOCOPY     VARCHAR2,
        retcode                  OUT NOCOPY     NUMBER,
        p_org_id                 IN             NUMBER,
        p_store_number           IN             VARCHAR2,
        p_receipt_date           IN             VARCHAR2,
        p_tolerance              IN             NUMBER,
        p_debug_flag             IN             VARCHAR2,
        p_max_number_of_threads  IN             NUMBER);
END xx_ar_pos_receipt_pkg;
/