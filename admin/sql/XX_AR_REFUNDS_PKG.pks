CREATE OR REPLACE PACKAGE APPS.XX_AR_REFUNDS_PKG AS
-- +=========================================================================+
-- |		      Office Depot - Project Simplify			     |
-- |			   Oracle Corporation	     		             |
-- +=========================================================================+
-- | Name : Insert_into_int_tables					     |
-- | Description : Procedure to insert the values in interim tables	     |
-- |								      .      |
-- |									     |
-- | Parameters :    Errbuf and retcode 				     |
-- |===============							     |
-- |Version   Date	    Author		Remarks 		     |
-- |=======   ==========   =============   ==================================|
-- |   1      24-MAR-10   Usha R       Initial version--Added for defect 4901|
-- |   2      14-APR-10   Deepak       Edited create_refund proc. usedid made| 
-- |                                   it default to null                    |
-- |   3      12-AUG-19   Jitendra A   Added ref_mailcheck_id in idtrxrec    |
-- +==========================================================================+

   g_print_line  VARCHAR2 (120):= '-------------------------------------------------------------';

   TYPE idcustrec IS RECORD (
      customer_id      NUMBER
    , customer_number  VARCHAR2 (30)
    , org_id	       NUMBER
    , refund_alt       VARCHAR2 (30)
    , trx_count        NUMBER
   );

   TYPE idtrxrec IS RECORD (
      source		      xx_ar_refund_trx_id_v.source%TYPE
    , customer_id	      NUMBER
    , customer_number	      hz_cust_accounts.account_number%TYPE
    , party_name	      hz_parties.party_name%TYPE
    , aops_customer_number    hz_cust_accounts.orig_system_reference%TYPE --Added for R1.2 CR#714(Defect#2532)

    , cash_receipt_id	      NUMBER
    , customer_trx_id	      NUMBER
    , trx_id		      NUMBER
    , class		      VARCHAR2 (30)
    , trx_number	      VARCHAR2 (30)
    , trx_date		      DATE
    , trx_currency_code       VARCHAR2 (15)
    , refund_amount	      NUMBER
    , cash_applied_date_last  DATE
    , selected_flag	      VARCHAR2 (1)
    -- defect 8298 - B.Looman - performance enhancements
    , refund_request	      VARCHAR2 (150)
    , refund_status	      VARCHAR2 (150)
    --, pmt_dff1		VARCHAR2 (30)
    --, pmt_dff2		VARCHAR2 (30)
    --, cm_dff1 		VARCHAR2 (30)
    --, cm_dff2 		VARCHAR2 (30)
    , org_id		      NUMBER
    , location_id	      NUMBER
    , address1		      VARCHAR2 (240)
    , address2		      VARCHAR2 (240)
    , address3		      VARCHAR2 (240)
    , city		      VARCHAR2 (60)
    , state		      VARCHAR2 (60)
    , province		      VARCHAR2 (60)
    , postal_code	      VARCHAR2 (60)
    , country		      VARCHAR2 (60)
    , om_hold_status	      VARCHAR2 (10)
    , om_delete_status	      VARCHAR2 (10)
    , om_store_number	      VARCHAR2 (60)
    , store_customer_name     VARCHAR2 (200)  -- defect 11109, add store_customer_name if OM/SAS mailcheck
    , ref_mailcheck_id 		  NUMBER -- Added by Gaurav Agarwal for SDR Changes V 1.8
   );

   PROCEDURE identify_refund_trx (
      errbuf		   OUT NOCOPY	  VARCHAR2
    , retcode		   OUT NOCOPY	  VARCHAR2
    , p_trx_date_from	   IN		  VARCHAR2
    , p_trx_date_to	   IN		  VARCHAR2
    , p_amount_from	   IN		  NUMBER DEFAULT 0.000001
    , p_amount_to	   IN		  NUMBER DEFAULT 9999999999999
    , p_no_activity_in	   IN		  NUMBER		  --# OF DAYS.
    , p_only_pre_selected  IN		  VARCHAR2			--Y/N.
    , p_process_type	   IN		  VARCHAR2	  -- ESCHEAT / OTHERS.
    , p_only_for_user_id   IN		  NUMBER DEFAULT NULL
    , p_org_id		   IN		  VARCHAR2
    , p_limit_size	   IN		  NUMBER     --Added for defect 4901 on 05-APR-2010

   );

   PROCEDURE create_refund (
      errbuf	     OUT NOCOPY     VARCHAR2
    , retcode	     OUT NOCOPY     VARCHAR2
    , p_om_escheats  IN 	    VARCHAR2
    , p_user_id      IN 	   NUMBER DEFAULT NULL	      --Added for Defect #8304, DEFAULT NULL added for Defect #10957
   );

   PROCEDURE create_cm_adjustment (
      p_payment_schedule_id  IN 	    NUMBER
    , p_customer_trx_id      IN 	    NUMBER
    , p_customer_number      IN 	    VARCHAR2
    , p_amount		     IN 	    NUMBER
    , p_org_id		     IN 	    NUMBER
    , p_adj_name	     IN 	    VARCHAR2
    , p_reason_code	     IN 	    VARCHAR2
    , p_comments	     IN 	    VARCHAR2
    , o_adj_num 	     OUT NOCOPY     VARCHAR2
    , x_return_status	     OUT NOCOPY     VARCHAR2
    , x_msg_count	     OUT NOCOPY     NUMBER
    , x_msg_data	     OUT NOCOPY     VARCHAR2
   );

   PROCEDURE create_receipt_writeoff (
      p_refund_header_id	   IN		  NUMBER --Added for the Defect#3340

    , p_cash_receipt_id 	   IN		  NUMBER
    , p_customer_number 	   IN		  VARCHAR2
    , p_amount			   IN		  NUMBER
    , p_org_id			   IN		  NUMBER
    , p_wo_name 		   IN		  VARCHAR2
    , p_reason_code		   IN		  VARCHAR2
    , p_comments		   IN		  VARCHAR2
    , p_escheat_flag		   IN		  VARCHAR2
    , o_receivable_application_id  OUT NOCOPY	  VARCHAR2
    , x_return_status		   OUT NOCOPY	  VARCHAR2
    , x_msg_count		   OUT NOCOPY	  NUMBER
    , x_msg_data		   OUT NOCOPY	  VARCHAR2
   );

   PROCEDURE unapply_prepayment (
      p_receivable_application_id  IN		  NUMBER
    , x_return_status		   OUT NOCOPY	  VARCHAR2
    , x_msg_count		   OUT NOCOPY	  NUMBER
    , x_msg_data		   OUT NOCOPY	  VARCHAR2
   );

   PROCEDURE unapply_on_account (
      p_receivable_application_id  IN		  NUMBER
    , x_return_status		   OUT NOCOPY	  VARCHAR2
    , x_msg_count		   OUT NOCOPY	  NUMBER
    , x_msg_data		   OUT NOCOPY	  VARCHAR2
   );

   PROCEDURE insert_supplier_interface (
      p_refund_hdr_rec	     IN 	    xx_ar_refund_trx_tmp%ROWTYPE
    , p_sob_name	     IN 	    VARCHAR2
    , x_vendor_interface_id  OUT NOCOPY     NUMBER
    , x_err_mesg	     OUT NOCOPY     VARCHAR2
   );

   PROCEDURE insert_supplier_site_int (
      p_refund_hdr_rec	     IN 	    xx_ar_refund_trx_tmp%ROWTYPE
    , p_vendor_interface_id  IN 	    NUMBER
    , p_vendor_id	     IN 	    NUMBER
    , p_sob_name	     IN 	    VARCHAR2
    , x_sitecode	     OUT NOCOPY     VARCHAR2
    , x_err_mesg	     OUT NOCOPY     VARCHAR2
   );

   PROCEDURE create_ap_invoice (
      errbuf   IN OUT NOCOPY  VARCHAR2
    , errcode  IN OUT NOCOPY  INTEGER
   );

   PROCEDURE get_om_refund_status (
      p_cash_receipt_id  IN		NUMBER
    , x_escheat_flag	 OUT NOCOPY	VARCHAR2
    , x_write_off_only	 OUT NOCOPY	VARCHAR2
    , x_activity_code	 OUT NOCOPY	VARCHAR2
    , x_approved_flag	 OUT NOCOPY	VARCHAR2
   );

   PROCEDURE print_errors (p_request_id IN NUMBER);

   PROCEDURE update_dffs;

   FUNCTION get_status_descr (p_status_code   IN  VARCHAR2
			     ,p_escheat_flag  IN  VARCHAR2
			     )
			     RETURN VARCHAR2;
-- +=========================================================================+
-- |		      Office Depot - Project Simplify			     |
-- |			   WIPRO Technologies				     |
-- +=========================================================================+
-- | Name : Insert_into_int_tables					     |
-- | Description : Procedure to insert the values in interim tables	     |
-- |								      .      |
-- |									     |
-- | Parameters :    Errbuf and retcode 				     |
-- |===============							     |
-- |Version   Date	    Author		Remarks 		     |
-- |=======   ==========   =============   ==================================|
-- |   1      24-MAR-10   Usha R       Initial version--Added for defect 4901|
-- +==========================================================================+
   PROCEDURE insert_into_int_tables(errbuf OUT VARCHAR2
				   ,retcode OUT NUMBER);
-- Commented for defect 4901

-- +=========================================================================+
-- |		      Office Depot - Project Simplify			     |
-- |			   WIPRO Technologies				     |
-- +=========================================================================+
-- | Name : xx_ar_get_customer_id_type					     |
-- | Description : Function is added due to performance issue		     |
-- |								      .      |
-- |									     |
-- | Parameters :    x_CUSTOMER_ID					     |
-- |===============							     |
-- |Version   Date	    Author		Remarks 		     |
-- |=======   ==========   =============   ==================================|
-- |   1      24-MAR-10   Usha R       Initial version--Added for defect 4901|
-- +==========================================================================+
/*
   FUNCTION xx_ar_get_customer_id_type(x_CUSTOMER_ID IN NUMBER
				      )
				      RETURN NUMBER;*/
-- +=========================================================================+
-- |		      Office Depot - Project Simplify			     |
-- |			   WIPRO Technologies				     |
-- +=========================================================================+
-- | Name : check_cust							     |
-- | Description : Function is added due to performance issue		     |
-- |								      .      |
-- |									     |
-- | Parameters :     p_no_activity_in,p_inact_days,p_customer_id	     |
-- |===============							     |
-- |Version   Date	    Author		Remarks 		     |
-- |=======   ==========   =============   ==================================|
-- |   1      24-MAR-10   Usha R       Initial version--Added for defect 4901|
-- |   1.6    16-MAY-10   Rama Krishna K   Added Cash Receipt Id as IN parameter
-- |
-- |					   to handle performance issue for UNID
-- |					    for QC #5755
-- +============================================================================

FUNCTION check_cust( p_no_activity_in	 IN  NUMBER -- parameter
		    ,p_inact_days	 IN NUMBER -- from look up
		    ,p_customer_id	 IN NUMBER
		    ,p_cash_receipt_id	 IN NUMBER
		   )
		      RETURN NUMBER;

END xx_ar_refunds_pkg;
/