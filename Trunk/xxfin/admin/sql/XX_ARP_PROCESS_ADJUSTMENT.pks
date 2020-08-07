/*=======================================================================+
 |  Copyright (c) 1995 Oracle Corporation Redwood Shores, California, USA|
 |                          All rights reserved.                         |
 +=======================================================================+
 | FILENAME
 |      ARTEADJS.pls
 |
 | DESCRIPTION
 |      PL/SQL specification for package: XX_ARP_PROCESS_ADJUSTMENT
 |
 | PUBLIC VARIABLES
 |
 | PUBLIC PROCEDURES
 |    insert_adjustment
 |    update_adjustment
 |    update_approve_adj
 |    update_approve_adj
 |    test_adj
 |    reverse_adjustment - Entity handler to reverse an adjustment
 |    insert_reverse_actions -  This procedure performs all actions to modify
 |                              the passed in adjustments record and calls
 |                              adjustments insert table handler to 
 |                              insert the reversed adjuetments row
 |    cal_prorated_amounts - calculate prorated revenue and tax amounts for
 |			     an adjustment amount
 |
 | PUBLIC FUNCTIONS
 | 
 | KNOWN BUGS
 |
 | NOTES
 |	This module is called by AutoInstall (<driver file>) on install and
 |	upgrade.  The WHENEVER SQLERROR and EXIT (at bottom) are required.
 |
 | MODIFICATION HISTORY
 |      25-AUG-95  Martin Johnson      Created
 |      11-DEC-95  Martin Johnson      Merged in procedures from ARCEADJS.pls
 |                                     (reverse_adjustment and 
 |                                      insert_reverse_actions).
 |      03-FEB-00  Saloni Shah         Modified procedures for BR/BOE project:
 |                                     - insert_adjustment
 |                                       added an IN parameter - p_check_amount
 |                                     - update_approve_adj
 |                                       added an IN parameter - 
 |                                       p_chk_approval_limits
 |      17-May-00 Satheesh Nambiar     - Added p_move_deferred_tax for BOE/BR.
 |                                       The new parameter is used to detect
 |                                       whether the deferred tax is moved as 
 |                                       part of maturity_date event or as a 
 |                                       part of activity on the BR(Bug 1290698)
 |      28-Sep-00 Satheesh Nambiar      Bug 1415964 - Modified the code to avoid
 |                                      avoice recalculating the acctd_amount 
 |                                      when adjustment is being reversed. 
 |                                      Instead take the amounts from old
 |                                      adjustment and reverse it. Added 
 |                                      p_called_from,old_adjust_id parameters
 |                                      to insert_adjustment rountine
 |     12-mar-01  YREDDY                Bug 1686556: Added parameter
 |                                      p_override_flag to the procedure
 |                                      insert_adjustment  
 |     12-AUG-02  VCRISOST              Bug 2505544 : add dbdrv
 |     17-Aug-05  Debbie Sue Jancis     Added cust_Trx_line_id to
 |                                      cal_prorated_amount for llca
 *=======================================================================*/
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=pls \
REM dbdrv: checkfile(120.3.12000000.2=120.3.12010000.2):~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_ARP_PROCESS_ADJUSTMENT AS
/* $Header: ARTEADJS.pls 120.3.12010000.2 2012/04/06 09:46:10 dradhakr ship $ */

PROCEDURE insert_adjustment(p_form_name IN varchar2,
                            p_form_version IN number,
                            p_adj_rec IN OUT NOCOPY
                              ar_adjustments%rowtype,
                            p_adjustment_number OUT NOCOPY
                              ar_adjustments.adjustment_number%type,
                            p_adjustment_id OUT NOCOPY
                              ar_adjustments.adjustment_id%type,
			    p_check_amount IN varchar2 := FND_API.G_TRUE,
			    p_move_deferred_tax IN varchar2 DEFAULT 'Y',
			    p_called_from IN varchar2 DEFAULT NULL,
			    p_old_adjust_id IN ar_adjustments.adjustment_id%TYPE DEFAULT NULL,
                            p_override_flag IN varchar2 DEFAULT NULL,
                            p_app_level IN VARCHAR2 DEFAULT 'TRANSACTION');

PROCEDURE update_adjustment(
  p_form_name           IN varchar2,
  p_form_version        IN varchar2,
  p_adj_rec             IN ar_adjustments%rowtype,
  p_move_deferred_tax   IN varchar2 DEFAULT 'Y',
  p_adjustment_id       IN ar_adjustments.adjustment_id%type);

PROCEDURE update_approve_adj(p_form_name IN varchar2,
                            p_form_version    IN number,
                            p_adj_rec         IN ar_adjustments%rowtype,
                            p_adjustment_code ar_lookups.lookup_code%type,
                            p_adjustment_id   IN ar_adjustments.adjustment_id%type ,
			    p_chk_approval_limits IN varchar2, 
			    p_move_deferred_tax IN varchar2 DEFAULT 'Y');

PROCEDURE test_adj( p_adj_rec IN OUT NOCOPY ar_adjustments%rowtype,
                    p_result IN OUT NOCOPY varchar2,
                    p_old_ps_rec IN OUT NOCOPY ar_payment_schedules%rowtype);

PROCEDURE reverse_adjustment(
                p_adj_id IN ar_adjustments.adjustment_id%TYPE,
                p_reversal_gl_date IN DATE,
                p_reversal_date IN DATE,
                p_module_name IN VARCHAR2,
                p_module_version IN VARCHAR2 );

PROCEDURE insert_reverse_actions (
                p_adj_rec               IN OUT NOCOPY ar_adjustments%ROWTYPE,
                p_module_name           IN VARCHAR2,
                p_module_version        IN VARCHAR2 );

PROCEDURE validate_inv_line_amount_cover(
                                    p_customer_trx_line_id   IN number,
                                    p_customer_trx_id        IN number,
                                    p_payment_schedule_id    IN number,
                                    p_amount                 IN number,
   				    p_receivables_trx_id     IN NUMBER DEFAULT NULL); -- Bug 13882660

/* VAT changes */
PROCEDURE cal_prorated_amounts( p_adj_amount          IN number,
                                p_payment_schedule_id IN number,
                                p_type IN varchar2,
                                p_receivables_trx_id  IN number,
                                p_apply_date IN date,
                                p_prorated_amt OUT NOCOPY number,
                                p_prorated_tax OUT NOCOPY number,
				p_error_num OUT NOCOPY number,
                                p_cust_trx_line_id IN NUMBER DEFAULT NULL);

END XX_ARP_PROCESS_ADJUSTMENT;
/


COMMIT;
EXIT;
