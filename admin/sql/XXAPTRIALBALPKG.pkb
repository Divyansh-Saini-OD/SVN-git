SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_AP_TRIAL_BAL_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Organization                                            |
-- +================================================================================+
-- | Name        :   XXAPTRIALBALPKG.pkb                                            |
-- | Rice Id     :  E0453_AP Trial Balance                                          |
-- | Description :  This script creates custom package body required for            |
-- |                AP Trial Balance                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author           Remarks                                  |
-- |=======   ==========  =============    ============================             |
-- |1.0      02-NOV-2007  Rahul Bagul      Initial draft version                    |
-- |1.1      10-Jan-2014  Paddy Sanjeevi   Defect 27205 for Performance             |
-- +================================================================================+
AS
-- +================================================================================+
-- | Name        :  get_approval_status                                             |
-- | Description :  This  custom procedure is main procedure.  It will return       |
-- |                approval status of invoice                                      |
-- | Parameters   : p_invoice_id,p_invoice_amount,p_payment_status_flag,            |
-- |                p_invoice_type_lookup_code, p_org_id                            |
-- +================================================================================+

FUNCTION get_approval_status (p_invoice_id IN NUMBER
				 , p_invoice_amount IN NUMBER
				  ,p_payment_status_flag IN VARCHAR2
				  ,p_invoice_type_lookup_code IN VARCHAR2
                                  , p_org_id IN NUMBER)
         RETURN VARCHAR2
     IS
         invoice_approval_status         VARCHAR2(25);
         invoice_approval_flag           VARCHAR2(1);
         distribution_approval_flag      VARCHAR2(1);
         encumbrance_flag                VARCHAR2(1);
         invoice_holds                   NUMBER;
         cancelled_date                  DATE;
         sum_distributions               NUMBER;
         dist_var_hold                   NUMBER;      --added for bug 787373
         match_flag_cnt                  NUMBER;
         ---------------------------------------------------------------------
         -- Declare cursor to establish the invoice-level approval flag
         --
         -- The first select simply looks at the match status flag for the
         -- distributions.  The rest is to cover one specific case when some
         -- of the distributions are tested (T or A) and some are untested
         -- (NULL).  The status should be needs reapproval (N).
         --
         -- Bug 963755: Modified the approval_cursor below to select the records
         -- correctly.

         CURSOR approval_cursor IS
         SELECT nvl(match_status_flag, 'N')
         FROM   ap_invoice_distributions_all
         WHERE  invoice_id = p_invoice_id
         AND     org_id     =p_org_id;

     BEGIN

         ---------------------------------------------------------------------
         -- Get the encumbrance flag
         --
         SELECT NVL(purch_encumbrance_flag,'N')
         INTO   encumbrance_flag
         FROM   financials_system_params_all
         WHERE  org_id     =p_org_id;

         ---------------------------------------------------------------------
         -- Get the number of holds for the invoice
         --
         SELECT count(*)
         INTO   invoice_holds
         FROM   ap_holds_all
         WHERE  invoice_id = p_invoice_id
         AND     org_id     =p_org_id
         AND    release_lookup_code is NULL;

         ---------------------------------------------------------------------
         -- Bug 787373: Check if DIST VAR hold is placed on this invoice.
         -- DIST VAR is a special case because it could be placed
         -- when no distributions exist and in this case, the invoice
         -- status should be NEEDS REAPPROVAL.
         --
         SELECT count(*)
         INTO   dist_var_hold
         FROM   ap_holds_all
         WHERE  invoice_id = p_invoice_id
         AND     org_id     =p_org_id
         AND    hold_lookup_code = 'DIST VARIANCE'
         AND    release_lookup_code is NULL;

         ---------------------------------------------------------------------
         -- If invoice is cancelled, return 'CANCELLED'.
	 --
	 SELECT ai.cancelled_date
	 INTO   cancelled_date
	 FROM   ap_invoices_all ai
	 WHERE  ai.invoice_id = p_invoice_id
         AND     org_id     =p_org_id;

         IF (cancelled_date IS NOT NULL) THEN
             RETURN('CANCELLED');
         END IF;

         ---------------------------------------------------------------------
         -- Bug 963755: Getting the count of distributions with
         -- match_status_flag not null. We will open the approval_cursor
         -- only if the count is more than 0.
         --
         SELECT count(*)
         INTO match_flag_cnt
         FROM ap_invoice_distributions_all aid
         WHERE aid.invoice_id = p_invoice_id
         AND     org_id       =p_org_id
         AND aid.match_status_flag IS NOT NULL
         AND rownum < 2;

         ---------------------------------------------------------------------
         -- Establish the invoice-level approval flag
         --
         -- Use the following ordering sequence to determine the invoice-level
         -- approval flag:
         --                     'N' - Needs Reapproval
         --                     'T' - Tested
         --                     'A' - Approved
         --                     ''  - Never Approved
         --
         --                     'X' - No Distributions Exist! --666401
         --
         -- Initialize invoice-level approval flag
         --
         invoice_approval_flag := 'X';         --bug 787373, initialized invoice_approval_flag to 'X'

        IF match_flag_cnt > 0 THEN

         OPEN approval_cursor;

         LOOP
             FETCH approval_cursor INTO distribution_approval_flag;
             EXIT WHEN approval_cursor%NOTFOUND;

             IF (distribution_approval_flag IS NULL) THEN
                 invoice_approval_flag := '';
             ELSIF (distribution_approval_flag = 'N') THEN
                 invoice_approval_flag := 'N';
             ELSIF (distribution_approval_flag = 'T' AND
                    (invoice_approval_flag <> 'N'
		     or invoice_approval_flag is null)) THEN
                 invoice_approval_flag := 'T';
             ELSIF (distribution_approval_flag = 'A' AND
                    (invoice_approval_flag NOT IN ('N','T')
                     or invoice_approval_flag is null)) THEN
                 invoice_approval_flag := 'A';
             END IF;

         END LOOP;

         CLOSE approval_cursor;

        END IF;
         ---------------------------------------------------------------------
         -- Bug 719322: Bug 719322 was created by the fix to bug 594189. Re-fix
         -- for bug 594189 would fix bug 719322.

         -- Re-fix for bug 594189
         -- With encumbrance on, if after an invoice has been approved, the
         -- user changes the invoice amount, then the invoice amount would
         -- no longer match the sum of the distribution amounts. In this case,
         -- the status should go to 'NEEDS REAPPROVAL'.

         IF (encumbrance_flag = 'Y') AND (invoice_approval_flag = 'A') THEN

           -- Bug 1542699. Excluding the awt, prepay and prepay tax lines
           -- from the distributions total

           -- Bug 1639039. Including the Prepayment and Prepayment Tax from
           -- the distribution total if the invoice_includes_prepay_flag is
           -- set to Y.
           SELECT SUM(nvl(amount,0))
           INTO   sum_distributions
           FROM   ap_invoice_distributions_all
           WHERE  invoice_id = p_invoice_id
           AND     org_id     =p_org_id
           AND    ((line_type_lookup_code NOT IN ('AWT','PREPAY')
                    AND    prepay_tax_parent_id IS NULL)
                    OR     nvl(invoice_includes_prepay_flag,'N') = 'Y')
           GROUP BY invoice_id;

           IF (p_invoice_amount <> sum_distributions) THEN
             invoice_approval_flag := 'N';
           END IF;

         END IF;

         ---------------------------------------------------------------------
         -- Derive the translated approval status from the approval flag
         --
         IF (encumbrance_flag = 'Y') THEN
	     IF (invoice_approval_flag = 'A' AND invoice_holds = 0) THEN
	         invoice_approval_status := 'APPROVED';
	     ELSIF ((invoice_approval_flag in ('A') AND invoice_holds > 0)
		     OR (invoice_approval_flag IN ('T','N'))) THEN
	         invoice_approval_status := 'NEEDS REAPPROVAL';
             ELSIF (dist_var_hold >= 1) THEN
                 --It's assumed here that the user won't place this hold
                 --manually before approving.  If he does, status will be
                 --NEEDS REAPPROVAL.  dist_var_hold can result when there
                 --are no distributions or there are but amounts don't
                 --match.  It can also happen when an invoice is created with
                 --no distributions, then approve the invoice, then create the
                 --distribution.  So, in this case, although the match flag
                 --is null, we still want to see the status as NEEDS REAPPR.
                 invoice_approval_status := 'NEEDS REAPPROVAL';
	     ELSIF (invoice_approval_flag is null
                    OR (invoice_approval_flag = 'X' AND dist_var_hold = 0)) THEN
	         invoice_approval_status := 'NEVER APPROVED';
	     END IF;
         ELSIF (encumbrance_flag = 'N') THEN
	     IF (invoice_approval_flag IN ('A','T') AND invoice_holds = 0) THEN
	         invoice_approval_status := 'APPROVED';
	     ELSIF ((invoice_approval_flag IN ('A','T') AND
                     invoice_holds > 0) OR
		    (invoice_approval_flag = 'N')) THEN
	         invoice_approval_status := 'NEEDS REAPPROVAL';
             ELSIF (dist_var_hold >= 1) THEN
                 invoice_approval_status := 'NEEDS REAPPROVAL';
	     ELSIF (invoice_approval_flag is null
                    OR (invoice_approval_flag = 'X' AND dist_var_hold = 0)) THEN
                 -- Bug 787373: A NULL flag indicate that APPROVAL has not
                 -- been run for this invoice, therefore, even if manual
                 -- holds exist, status should be NEVER APPROVED.
	         invoice_approval_status := 'NEVER APPROVED';
             END IF;
         END IF;

         ---------------------------------------------------------------------
         -- If this a prepayment, find the appropriate prepayment status
         --
         if (p_invoice_type_lookup_code = 'PREPAYMENT') then
           if (invoice_approval_status = 'APPROVED') then
             if (p_payment_status_flag IN ('P','N')) then
               invoice_approval_status := 'UNPAID';
             else
	       -- This prepayment is paid
               if (AP_INVOICES_UTILITY_PKG.get_prepay_amount_remaining(p_invoice_id) = 0) then
                 invoice_approval_status := 'FULL';
               elsif (AP_INVOICES_UTILITY_PKG.get_prepayment_type(p_invoice_id) = 'PERMANENT') THEN
		 invoice_approval_status := 'PERMANENT';
	       else
                 invoice_approval_status := 'AVAILABLE';
	       end if;
             end if;
           elsif (invoice_approval_status = 'NEVER APPROVED') then
             -- This prepayment in unapproved
             invoice_approval_status := 'UNAPPROVED';
           end if;
         end if;

         RETURN(invoice_approval_status);

     END get_approval_status;

     -----------------------------------------------------------------------
     -- Function get_posting_status returns the invoice posting status flag.
     --
     --                     'Y' - Posted
     --                     'S' - Selected
     --                     'P' - Partial
     --                     'N' - Unposted
     --
     FUNCTION get_posting_status(p_invoice_id IN NUMBER)
         RETURN VARCHAR2
     IS
         invoice_posting_flag           VARCHAR2(1);
         distribution_posting_flag      VARCHAR2(1);
         accounting_method_option	VARCHAR2(25);
         secondary_accounting_method	VARCHAR2(25);

         ---------------------------------------------------------------------
         -- Declare cursor to establish the invoice-level posting flag
         --
         -- The first two selects simply look at the posting flags (cash and/or
         -- accrual) for the distributions.  The rest is to cover one specific
         -- case when some of the distributions are fully posting (Y) and some
         -- are unposting (N).  The status should be partial (P).
         --

	 -- Defect 27205 -- Modified the cursor posting_cursor for performance 

         CURSOR posting_cursor IS
         with AID as (SELECT CASH_POSTED_FLAG, 
			     ACCRUAL_POSTED_FLAG,
			     accounting_method_option,
			     secondary_accounting_method
			FROM AP_INVOICE_DISTRIBUTIONS_ALL
		       WHERE invoice_id=p_invoice_id
		     )
	 SELECT cash_posted_flag
           FROM AID
	  WHERE (accounting_method_option = 'Cash' OR secondary_accounting_method = 'Cash')
         UNION
         SELECT accrual_posted_flag
           FROM AID
          WHERE (accounting_method_option = 'Accrual' OR secondary_accounting_method = 'Accrual')
         UNION
         SELECT 'P'
           FROM AID
          WHERE (   (       cash_posted_flag || '' = 'Y'
                       AND ( accounting_method_option = 'Cash' OR secondary_accounting_method = 'Cash')
                    )
                 OR
	            (       accrual_posted_flag || '' = 'Y'
		       AND (accounting_method_option = 'Accrual' OR secondary_accounting_method = 'Accrual')
		    )

                 )
	    AND  EXISTS
       		     (SELECT 'An N is also in the valid flags'
		        FROM AID
	               WHERE (   (      cash_posted_flag || '' = 'N'
                                  AND ( accounting_method_option = 'Cash' OR secondary_accounting_method = 'Cash')
				 )
                              OR
  			         (      accrual_posted_flag || '' = 'N'
				  AND ( accounting_method_option = 'Accrual' OR secondary_accounting_method = 'Accrual')
			         )
	                     )
		      );
/*
         CURSOR posting_cursor IS
         SELECT cash_posted_flag
         FROM   ap_invoice_distributions_all
         WHERE  invoice_id = p_invoice_id
         AND    (accounting_method_option = 'Cash'
                 OR secondary_accounting_method = 'Cash')
         UNION
         SELECT accrual_posted_flag
         FROM   ap_invoice_distributions_all
         WHERE  invoice_id = p_invoice_id
         AND    (accounting_method_option = 'Accrual'
                 OR secondary_accounting_method = 'Accrual')
         UNION
         SELECT 'P'
         FROM   ap_invoice_distributions_all
         WHERE  invoice_id = p_invoice_id
         AND    ((cash_posted_flag || '' = 'Y'
                  AND (accounting_method_option = 'Cash'
                       OR secondary_accounting_method = 'Cash'))
             OR
                 (accrual_posted_flag || '' = 'Y'
                  AND (accounting_method_option = 'Accrual'
                       OR secondary_accounting_method = 'Accrual')))
         AND EXISTS
                (SELECT 'An N is also in the valid flags'
                 FROM   ap_invoice_distributions_all
                 WHERE  invoice_id = p_invoice_id
                 AND    ((cash_posted_flag || '' = 'N'
                          AND (accounting_method_option = 'Cash'
                               OR secondary_accounting_method = 'Cash'))
                    OR
                         (accrual_posted_flag || '' = 'N'
                          AND (accounting_method_option = 'Accrual'
                               OR secondary_accounting_method = 'Accrual'))));

*/
     BEGIN

         ---------------------------------------------------------------------
         -- Get Primary and Secondary Accounting Methods
         --
         SELECT accounting_method_option,
                secondary_accounting_method
         INTO   accounting_method_option,
                secondary_accounting_method
         FROM   ap_system_parameters;

         ---------------------------------------------------------------------
         -- Establish the invoice-level posting flag
         --
         -- Use the following ordering sequence to determine the invoice-level
         -- posting flag:
         --                     'S' - Selected
         --                     'P' - Partial
         --                     'N' - Unposted
         --                     'Y' - Posted
         --
         -- Initialize invoice-level posting flag
         --
         invoice_posting_flag := 'X';

         OPEN posting_cursor;

         LOOP
             FETCH posting_cursor INTO distribution_posting_flag;
             EXIT WHEN posting_cursor%NOTFOUND;

             IF (distribution_posting_flag = 'S') THEN
                 invoice_posting_flag := 'S';
             ELSIF (distribution_posting_flag = 'P' AND
                    invoice_posting_flag <> 'S') THEN
                 invoice_posting_flag := 'P';
             ELSIF (distribution_posting_flag = 'N' AND
                    invoice_posting_flag NOT IN ('S','P')) THEN
                 invoice_posting_flag := 'N';
             ELSIF (invoice_posting_flag NOT IN ('S','P','N')) THEN
                 invoice_posting_flag := 'Y';
             END IF;

         END LOOP;

         CLOSE posting_cursor;

         if (invoice_posting_flag = 'X') then
           -- No distributions belong to this invoice; therefore,
	   -- the invoice-level posting status should be 'N'
           invoice_posting_flag := 'N';
         end if;

         RETURN(invoice_posting_flag);

     END get_posting_status;

END XX_AP_TRIAL_BAL_PKG;
/
SHOW ERROR