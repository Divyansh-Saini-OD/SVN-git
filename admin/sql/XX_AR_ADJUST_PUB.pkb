/*=======================================================================+
 |  Copyright (c) 1997 Oracle Corporation Redwood Shores, California, USA|
 |                          All rights reserved.                         |
 +=======================================================================+
 | FILENAME
 |      ARXPADJB.pls
 |
 | DESCRIPTION
 |      PL/SQL body for package:  XX_AR_ADJUST_PUB
 |      This package creates, modifies, reverses, approves adjustments
 |
 | PUBLIC OBJECTS
 |      
 |
 | PUBLIC PROCEDURES
 |      
 |     arp_util.Debug
 |     fnd_api.compatible_api_call                                           
 |     fnd_api.g_exc_unexpected_error                                        
 |     fnd_api.g_ret_sts_error                                               
 |     fnd_api.g_ret_sts_error                                               
 |     fnd_api.g_ret_sts_success                                             
 |     fnd_api.to_boolean                                                    
 |     fnd_msg_pub.check_msg_level                                           
 |     fnd_msg_pub.count_and_get                                             
 |     fnd_msg_pub.initialize           
 |
 | PUBLIC FUNCTIONS
 |      
 |
 | PRIVATE PROCEDURES
 |
 | Validate_Adj_Insert     
 | Validate_Adj_Modify    
 | Validate_Adj_Reverse    
 | Validate_Adj_Approve    
 | Set_remaining_attributes
 |  
 | PRIVATE FUNCTIONS
 |      
 | 
 | KNOWN BUGS
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 |    Vivek Halder       06-JUN-97  Created
 |    Saloni Shah        03-FEB-00  Changes have been made for the BR/BOE project.
 |                                  Changes affect procedures Validate_Adj_Insert,
 |                                  Validate_Adj_Modify, Create_Adjustment, 
 |                                  Modify_Adjustment, Approve_Adjustment
 | 
 |    Satheesh Nambiar   04-May-00  Added Proration logic for partial adjustments. 
 |                                  When partial adjustment is done, p_ckeck_amount
 |                                  should be set to 'F'. This flag is BOE specific. 
 |    Satheesh Nambiar   17-May-00  Added p_move_deferred_tax for BOE/BR.The
 |                                  new parameter is used to detect whether
 |                                  the deferred tax is moved as part of
 |                                  maturity_date event or as a part of activity
 |                                  on the BR 
 |  Satheesh Nambiar     25-Aug-00  Bug 1395396
 |                                  Modified the code to process $0 adjustment
 |  Satheesh Nambiar     05-Sep-00  Bug 1392055 - Call prorate routine only when
 |                                  PS.amount_due_remaining > 0 
 |  Satheesh Nambiar     28-Sep-00  Bug 1415964 - Modified the code to 
 |                                  pass p_called_from and old_adjust_id parameters
 |                                  to arp_process_adjustment.insert_adjustment rountine
 |  Satheesh Nambiar     28-Nov-00  Bug 1449758 - Modified Reverse routine to initialize
 |                                  gl_posted_date and posting_control_id 
 |  V Crisostomo	 09-OCT-02  Bug 2443950 : skip validate_doc_seq in cases where
 |				    adjustment is being created for BR assignment
 |  				    per GSCC warning, removed DEFAULT values
 |  Satheesh Nambiar     05-Nov-02  Bug 2655679 - Modified to allow update of
 |                                  existing approved adjustment record conditionaly. 
 |  V Crisostomo         12-JAN-06  Bug 4758340 : pass p_created_from to
 |                                  calc_applied_and_remaining
 *=======================================================================*/
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.20.12000000.12=120.20.12010000.6):~PROD:~PATH:~FILE
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_AR_ADJUST_PUB AS
/* $Header: ARXPADJB.pls 120.20.12010000.6 2012/03/17 16:27:50 dradhakr ship $*/

G_PKG_NAME	CONSTANT VARCHAR2(30)	:='XX_AR_ADJUST_PUB';
G_MSG_UERROR    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR;
G_MSG_ERROR     CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_ERROR;
G_MSG_HIGH      CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_HIGH; 
G_MSG_MEDIUM    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_MEDIUM; 
G_MSG_LOW       CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW; 

/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Validate_Adj_Insert                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the routine that validates the inputs during creation|
 |              of adjustments                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                    |
 |     fnd_api.compatible_api_call                                           |
 |     fnd_api.g_exc_unexpected_error                                        |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_success                                             |
 |     fnd_api.to_boolean                                                    |
 |     fnd_msg_pub.check_msg_level                                           |
 |     fnd_msg_pub.count_and_get                                             |
 |     fnd_msg_pub.initialize                                                |
 |     ar_adjvalidate_pvt.Validate_Type                                      |
 |     ar_adjvalidate_pvt.Validate_Payschd                                   |
 |     ar_adjvalidate_pvt.Validate_amount                                    |
 |     ar_adjvalidate_pvt.Validate_Rcvtrxccid                                |
 |     ar_adjvalidate_pvt.Validate_dates                                     |
 |     ar_adjvalidate_pvt.Validate_Reason_code                               |
 |     ar_adjvalidate_pvt.Validate_doc_seq                                   |
 |     ar_adjvalidate_pvt.Validate_Associated_Receipt                        |
 |     ar_adjvalidate_pvt.Validate_Ussgl_code                                |
 |     ar_adjvalidate_pvt.Validate_Desc_Flexfield                            |
 |     ar_adjvalidate_pvt.Validate_Created_From                              |
 |                                                                           |
 | ARGUMENTS  : IN:  p_chk_approval_limits                                   |
 |                   p_check_amount                                          |
 |              OUT:                                                         |
 |          IN/ OUT: p_Validation_status                                     |
 |                   p_adj_rec                                               |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JUN-97  Created                                      |
 |    Saloni Shah    03-FEB-00  Changes have been made for BR/BOE project.   |
 |                              Two new IN parameters have been added        |
 |                                 - p_chk_approval_limits and p_check_amount|
 |                                   These parameters are passed to the      |
 |                                   Validate_amount procedure.              |
 |                              Vat changes have also been made to calculate |
 |                              the amounts if the adjustment type is 'LINE' |
 |                              or 'CHARGES'.                                | 
 |                                                                           |
 |  Satheesh Nambiar 25-Aug-00  Bug 1395396. Modified the code to process $0 |
 |                              adjustment for LINE			     |
 |  V Crisostomo     09-OCT-02  Bug 2443950 : skip validate_doc_seq when     |
 |				adjustment is against receivable_trx_id = -15|
+===========================================================================*/

PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

-- Added parameter p_llca_from_call for Line level Adjustment
PROCEDURE Validate_Adj_Insert (
		p_adj_rec		IN OUT NOCOPY	ar_adjustments%rowtype,
                p_chk_approval_limits   IN      varchar2,
                p_check_amount          IN      varchar2,
		p_validation_status	IN OUT NOCOPY	varchar2,
		p_llca_from_call	IN varchar2 DEFAULT 'N'
	        ) IS

l_return_status		varchar2(1);
l_ps_rec		ar_payment_schedules%rowtype;
l_prorated_tax    NUMBER;
l_prorated_amt    NUMBER;
l_error_num       NUMBER;

BEGIN

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Validate_Adj_Insert()+');
	  arp_util.debug('p_llca_from_call :'|| p_llca_from_call);
       END IF;
       
 
       /*-------------------------------------------------+
       | Initialize return status to SUCCESS              | 
       +-------------------------------------------------*/ 
       p_validation_status := FND_API.G_RET_STS_SUCCESS;

       /*-------------------------------------------------+
       |   1. Validate type                               |
       +-------------------------------------------------*/ 
       ar_adjvalidate_pvt.Validate_Type (
                                 p_adj_rec, 
                                 l_return_status
                                 ) ;
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate type ');
           END IF;
       END IF;

       /*-------------------------------------------------+
       |   2. Validate payment_schedule_id  and           |
       |      customer_trx_line_id                        |
       +-------------------------------------------------*/ 
       ar_adjvalidate_pvt.Validate_Payschd ( 
                                 p_adj_rec, 
                                 l_ps_rec, 
                                 l_return_status,
				 p_llca_from_call
                                );
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate payment_schedule id ');
           END IF;
       END IF;

       /*-------------------------------------------------+
       |   3. Validate adjustment apply_date and GL date  |
       +-------------------------------------------------*/ 

       ar_adjvalidate_pvt.Validate_dates (
		               p_adj_rec.apply_date,
                               p_adj_rec.gl_date,
                               l_ps_rec,
                               l_return_status
                               );
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate dates ');
           END IF;
       ELSE
           p_adj_rec.apply_date := trunc(p_adj_rec.apply_date);
           p_adj_rec.gl_date := trunc(p_adj_rec.gl_date);
       END IF;

       /*-------------------------------------------------+
       |   4. Validate amount and status                  |
       |                                                  |
       |      Change for the BOE/BR project has been made |
       |      parameters p_chk_approval_limits and        |
       |      p_check_amount are being passed to validate |
       |      amount.                                     |
       |      p_check_amount will only be 'F' in  of      |
       |      reversal of adjustments                     | 
       +-------------------------------------------------*/ 

       ar_adjvalidate_pvt.Validate_amount ( 
		                 p_adj_rec,
		                 l_ps_rec,
                                 p_chk_approval_limits,
				 p_check_amount,
		                 l_return_status 
                                );

       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate amount '|| p_validation_status);
           END IF;
       END IF;
      
       /*-------------------------------------------------+
       |   5. Validate receivables_trx_id and code        |
       |      combination.                                |
       +-------------------------------------------------*/ 
       
       /*-------------------------------------------------+
       |  Bug 1290698. Modified to pass PS record for     |
       |  Validating  PS class and receivable trx type    |
       +-------------------------------------------------*/ 
       ar_adjvalidate_pvt.Validate_Rcvtrxccid (
	                        p_adj_rec,
                                l_ps_rec,
                                l_return_status,
				p_llca_from_call
                               );
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate receivables trx ccid');
           END IF;
       END IF;


       /*-------------------------------------------------+
       |   6. VAT CHANGES                                 |
       |      Calculate the amount if the adjust type is  |
       |      'LINE' or 'CHARGES'                         |
       |                                                  |
       |      This need not be done if the insert of      |
       |      adjustment is for reverse_adjustment, which |
       |      is indicated by the flag p_check_amount     |
       +--------------------------------------------------*/ 
     --Bug 1395396 Calculate prorate only if adjustment amount <> 0
      -- Added call to customer_trx_line_id for Line level Adjustment
      IF (p_adj_rec.type in ('LINE', 'CHARGES') AND
          p_check_amount = FND_API.G_TRUE AND
          p_adj_rec.amount <> 0) THEN

          XX_ARP_PROCESS_ADJUSTMENT.cal_prorated_amounts(p_adj_rec.amount,
                          p_adj_rec.payment_schedule_id, 
                          p_adj_rec.type, 
                          p_adj_rec.receivables_trx_id, 
                          p_adj_rec.apply_date, 
                          l_prorated_amt, 
                          l_prorated_tax, 
                          l_error_num,
			  p_adj_rec.customer_trx_line_id);

          IF (l_error_num = 1) THEN
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Validate_Adj_Insert: ' || 'cal_prorated_amount failed - error num 1');
             END IF;
             /*-----------------------------------------------+
             |  Set the message                               |
             +-----------------------------------------------*/
             FND_MESSAGE.SET_NAME('AR','AR_TW_PRORATE_ADJ_NO_TAX_RATE');
	     FND_MSG_PUB.ADD ;
             p_validation_status := FND_API.G_RET_STS_ERROR;
          ELSIF (l_error_num = 2) THEN
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Validate_Adj_Insert: ' || 'cal_prorated_amount failed - error num 2');
             END IF;
             /*-----------------------------------------------+
             |  Set the message                               |
             +-----------------------------------------------*/
             FND_MESSAGE.SET_NAME('AR','AR_TW_PRORATE_ADJ_OVERAPPLY');
	     FND_MSG_PUB.ADD ;
             p_validation_status := FND_API.G_RET_STS_ERROR;
          ELSIF (l_error_num = 3) THEN
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Validate_Adj_Insert: ' || 'cal_prorated_amount failed - error num 3');
             END IF;
             /*-----------------------------------------------+
             |  Set the message                               |
             +-----------------------------------------------*/
              p_validation_status := FND_API.G_RET_STS_ERROR;
          ELSE
            IF (p_adj_rec.type = 'LINE') THEN
                p_adj_rec.line_adjusted := l_prorated_amt;
            ELSE
                p_adj_rec.receivables_charges_adjusted := l_prorated_amt;
            END IF;
            p_adj_rec.tax_adjusted := l_prorated_tax;
          END IF;
      END IF;

       /*-------------------------------------------------+
       |   Check for over-application (Bug 3766262)       |
       +-------------------------------------------------*/
       /*We need to check for over-application only when it's not an adjustment
         reversal*/
       IF (p_check_amount = FND_API.G_TRUE)
       THEN
          ar_adjvalidate_pvt.Validate_Over_Application(
              p_adj_rec,
              l_ps_rec,
              l_return_status);
       END IF;

       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed over-application check ');
           END IF;
       END IF;

       /*-------------------------------------------------+
       |   Check for over-application Line level Adjustment |
       +-------------------------------------------------*/
      IF  p_llca_from_call = 'Y' AND  p_adj_rec.type = 'LINE'
      THEN

	       IF (p_check_amount = FND_API.G_TRUE)
	       THEN
		  ar_adjvalidate_pvt.Validate_Over_Application_llca(
		      p_adj_rec,
		      l_ps_rec,
		      l_return_status);
	       END IF;

	       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
	       THEN
		   p_validation_status := l_return_status ;
		   IF PG_DEBUG in ('Y', 'C') THEN
		      arp_util.debug ('Validate_Adj_Insert: ' || ' failed over_application_llca check ');
		   END IF;
	       END IF;
       END IF;


       /*-------------------------------------------------+
       |   7. Validate  doc_sequence_value                |
       +-------------------------------------------------*/ 
       -- Bug 2443950 - skip checking for doc sequence when adjustment is due to BR assignment
       -- since this type of adjustment is not a document 

       if p_adj_rec.receivables_trx_id <> -15 then

          ar_adjvalidate_pvt.Validate_doc_seq (
		             p_adj_rec, 
		             l_return_status
	                     ) ;
          IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
          THEN
              p_validation_status := l_return_status ;
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate doc seq ');
              END IF;
          END IF;
       end if;


       /*-------------------------------------------------+
       |   8. Validate  reason_code                      |
       +-------------------------------------------------*/ 
       ar_adjvalidate_pvt.Validate_Reason_code (
		               p_adj_rec,
		               l_return_status
                              );
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate reason code ');
           END IF;
       END IF;

       /*-------------------------------------------------+
       |   9. Validate  associated cash_receipt_id       |
       +-------------------------------------------------*/ 
       ar_adjvalidate_pvt.Validate_Associated_Receipt (
		               p_adj_rec,
                               l_return_status 
                              );
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate associated receipt id ');
           END IF;
       END IF;

       /*-------------------------------------------------+
       |  10. Validate  ussgl transaction code           |
       +-------------------------------------------------*/ 
       ar_adjvalidate_pvt.Validate_Ussgl_code (
		               p_adj_rec,
		               l_return_status
	                      );
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate ussgl_code');
           END IF;
       END IF;

       /*-------------------------------------------------+
       |   11. Validate  descriptive flex                 |
       +-------------------------------------------------*/ 
       ar_adjvalidate_pvt.Validate_Desc_Flexfield(
                               p_adj_rec,	
		               l_return_status
                              );
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate ussgl_code');
           END IF;
       END IF;

       /*-------------------------------------------------+
       |   12. Validate  created form                     |
       +-------------------------------------------------*/ 
       ar_adjvalidate_pvt.Validate_Created_From (
		               p_adj_rec,
		               l_return_status
                              );

       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
           p_validation_status := l_return_status ;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug ('Validate_Adj_Insert: ' || ' failed to validate created from ');
           END IF;
       END IF;
     	
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Validate_Adj_Insert()-');
   arp_util.debug('Validate_Adj_Insert: ' || 'value of the status flag ' || p_validation_status);
END IF;
       RETURN;

  
EXCEPTION
  
    WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION: Validate_Adj_Insert() ');
        END IF;
        FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME,'Validate_Adj_Insert');
	p_validation_status := FND_API.G_RET_STS_UNEXP_ERROR ;  
        RETURN;
   

END Validate_Adj_Insert;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Set_Remaining_Attributes                                     |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This routine sets data of remaining attributes which are not |
 |              not populated by the validation process. It also resets the  |
 |              the columns in the adjustment record  that should not be     |
 |              populated during creation of adjustments                     |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                    |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |              OUT:                                                         |
 |                   p_Validation_status                                     |
 |          IN/ OUT:                                                         |
 |                   p_adj_rec                                               |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JUN-97  Created                                      |
 |                                                                           |
 +===========================================================================*/

PROCEDURE Set_Remaining_Attributes (
		p_adj_rec	IN OUT NOCOPY 	ar_adjustments%rowtype,
                p_return_status IN OUT NOCOPY	varchar2
	        ) IS

BEGIN

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Set_Remaining_Attributes()+');
       END IF;

       /*-----------------------------------------------+
       |  Set the status to success                     |
       +-----------------------------------------------*/
       p_return_status := FND_API.G_RET_STS_SUCCESS ;

       /*-----------------------------------------------+
       |  Set Adjustment Type and Postable attributes   |
       +-----------------------------------------------*/
       /*-----------------------------------------------+
       |  Bug 1290698- Set the Adjustment Type to manual|
       |  only if it is null. For BOE/BR adjustment_type|
       |  can be 'E'-ENDORSEMNT or 'X'-EXCHANGE         |
       +-----------------------------------------------*/
       IF p_adj_rec.adjustment_type is null
       THEN
       	  p_adj_rec.adjustment_type := 'M' ;
       END IF;       
       p_adj_rec.postable := 'Y' ;

       /*--------------------------------------------------------+
       |  Reset the distribution_set_id, chargeback_customer_id  |
       |  and subsequent customer trx id                         |
       +--------------------------------------------------------*/
       p_adj_rec.distribution_set_id := NULL;
       p_adj_rec.chargeback_customer_trx_id := NULL ;
       p_adj_rec.subsequent_trx_id := NULL ;
       
        
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Set_Remaining_Attributes()-' );
       END IF;

EXCEPTION
  
   WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION: Set_Remaining_Attributes() ');
        END IF;
        FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME,'Set_Remaining_Attributes');
	p_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;  
        RETURN;

END Set_Remaining_Attributes;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Validate_Adj_Modify                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the validation routine for Modification of Approvals |
 |              						             |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                    |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_old_adj_rec                                           |
 |                                                                           |
 |              OUT:                                                         |
 |                   p_Validation_status                                     |
 |          IN/ OUT:                                                         |
 |                   p_adj_rec                                               |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JAN-97  Created                                      |
 |    Saloni Shah    03-FEB-00  Changes have been made for the BOE/BR project|
 |                              A new parameter p_chk_approval_limits is     |
 |                              passed. The value of this flag will indicate |
 |                              if the amount_adjusted should be validated   |
 |                              against the user approval limits or not      |
 |    S.Nambiar      31-Aug-02  Bug 2487925, if associated_application_id is |
 |                              passed, then update the adjustment with that |
 |                              id.                                          
 +===========================================================================*/

PROCEDURE Validate_Adj_modify (
		p_adj_rec	IN OUT NOCOPY 	ar_adjustments%rowtype,
		p_old_adj_rec   IN	ar_adjustments%rowtype,
		p_chk_approval_limits IN      varchar2,
		p_validation_status IN OUT NOCOPY	varchar2
	        ) IS

l_ps_rec	ar_payment_schedules%rowtype;
l_approved_flag	varchar2(1);
l_temp_adj_rec  ar_adjustments%rowtype;
l_return_status varchar2(1);
l_cash_receipt_id ar_receivable_applications.cash_receipt_id%TYPE;

BEGIN

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Validate_Adj_modify()+' );
       END IF;

       /*----------------------------------------------+
       | Validate Old Adjustment status. Cannot modify |
       | if status is 'A'                              |
       +----------------------------------------------*/ 
       --Bug 2655679 .ASSOCIATE_RECEIPT is passed when the user want to associate
       --a receipt to an existing adjustment.As per the previous design, user can't
       --modify an adjustment which is approved. This is the only exception. 

       IF ((( p_old_adj_rec.status = 'A' ) AND (p_adj_rec.created_from <> 'ASSOCIATE_RECEIPT'))
          OR (p_old_adj_rec.status = 'R'))  /*Bug 4303601*/
       THEN
            FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_NO_CHANGE_OR_REVERSE');
            FND_MESSAGE.SET_TOKEN ( 'STATUS',  p_old_adj_rec.status ) ;
            FND_MSG_PUB.ADD ;
            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_modify: ' || 'The old adjustment status is A, cannot modify');
            END IF;
       END IF;      
     
       --If approved adjustment is being modified for associating receipt,
       --then associated cash_receipt_id or application id should be passed. 
       
       IF (( p_old_adj_rec.status = 'A'                 ) AND 
           (p_adj_rec.created_from = 'ASSOCIATE_RECEIPT') AND 
           (p_adj_rec.associated_application_id IS NULL ) AND 
           (p_adj_rec.associated_cash_receipt_id IS NULL)
          ) THEN
            FND_MESSAGE.SET_NAME ('AR', 'AR_RAPI_RCPT_RA_ID_X_INVALID');
            FND_MSG_PUB.ADD ;
            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_modify: ' || 'Invalid associated cash_receipt_id or application id -should not be null');
            END IF;
       END IF;
       
     --If approved adjustment is being modified for associating receipt, 
     --no other attribute should be allowed to modify.
       
       IF (( p_old_adj_rec.status = 'A'                 ) AND 
           (p_adj_rec.created_from = 'ASSOCIATE_RECEIPT') AND 
           ((p_adj_rec.comments IS NOT NULL              ) OR 
            (p_adj_rec.status IS NOT NULL                ) OR 
            (p_adj_rec.gl_date IS NOT NULL               ))) 
       THEN
            FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_NO_CHANGE_OR_REVERSE');
            FND_MESSAGE.SET_TOKEN ( 'STATUS',  p_old_adj_rec.status ) ;
            FND_MSG_PUB.ADD ;
            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_modify: ' || 'Cannot modify comments,status or gl date of an approved adjustment');
            END IF;
       END IF; 


       /*----------------------------------------------------+
       |  Check new status. It could be NULL, 'A','R','W','M'|
       +-----------------------------------------------------*/ 
       
       IF ( (p_adj_rec.status IS NOT NULL) AND
            (p_adj_rec.status NOT IN ('A', 'R', 'W', 'M')) )
       THEN
          FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_INVALID_CHANGE_STATUS');
          FND_MESSAGE.SET_TOKEN ( 'STATUS',  p_adj_rec.status ) ;
          FND_MSG_PUB.ADD ;
          p_validation_status := FND_API.G_RET_STS_ERROR;
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('Validate_Adj_modify: ' || 'The new adjustment status is not valid, cannot modify');
          END IF;
       END IF;

       /*---------------------------------------------------+
       |   2. Validate approval limits if new status is 'A' |
       +---------------------------------------------------*/ 

       /*----------------------------------+
       |  a) Get the invoice currency code |
       +----------------------------------*/    

       BEGIN
      
         SELECT	*
           INTO	l_ps_rec
           FROM	ar_payment_schedules 
      	  WHERE	payment_schedule_id = p_old_adj_rec.payment_schedule_id;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
        
            /*-----------------------------------------------+
      	    |  Payment schedule Id does not exist            |
      	    |  Set the message and status accordingly        |
      	    +-----------------------------------------------*/
 	    FND_MESSAGE.SET_NAME ( 'AR',  'AR_AAPI_INVALID_PAYMENT_SCHEDULE');
            FND_MESSAGE.SET_TOKEN('PAYMENT_SCHEDULE_ID',to_char(p_old_adj_rec.payment_schedule_id));
 	    FND_MSG_PUB.ADD ;

            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_modify: ' || 'Invalid Payment Schedule Id');
            END IF;
       END ;

          /*------------------------------------------------------+
           | Changes made for BR/BOE project. The check for the   |
           | adjusted_amount against the users approval limits    |
           | will be done only if p_chk_approval_limits is set to |
           | 'T'.                                                 |  
           +------------------------------------------------------*/
       IF ( p_adj_rec.status = 'A' and
            p_chk_approval_limits = FND_API.G_TRUE )
       THEN
       
         /*-----------------------------------+
      	 |  Get the approval limits and check |
      	 +-----------------------------------*/

         ar_adjvalidate_pvt.Within_approval_limits(
                p_old_adj_rec.amount,
                l_ps_rec.invoice_currency_code,
                l_approved_flag,
	  	l_return_status
                         ) ;
       
         IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
         THEN
            p_validation_status := l_return_status;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_modify: ' || 'failure in get approval limits and check');
            END IF;
         END IF;

         IF ( l_approved_flag <> FND_API.G_TRUE )
         THEN
             FND_MESSAGE.SET_NAME ( 'AR',  'AR_VAL_AMT_APPROVAL_LIMIT');
             FND_MSG_PUB.ADD ;
             p_validation_status := FND_API.G_RET_STS_ERROR;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Validate_Adj_modify: ' || 'amount not in approval limits ');
             END IF;
         END IF;         

         /*-------------------------------------------------+
         | Check over application                           |
         +-------------------------------------------------*/

         -- This is done by the entity handler
       
       END IF;

       /*-------------------------------------------------+
       |   3. Validate GL date                            |
       +-------------------------------------------------*/ 

          /*Bug4303601*/
          ar_adjvalidate_pvt.Validate_dates (
	                     p_old_adj_rec.apply_date,
                             NVL(p_adj_rec.gl_date,p_old_adj_rec.gl_date),
                             l_ps_rec,
		             l_return_status
	                    ) ;
          IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
          THEN
            p_validation_status := l_return_status;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_modify: ' || 'failure in validating dates');
            END IF;
          END IF;


       p_adj_rec.gl_date := trunc(p_adj_rec.gl_date);
     
     --Bug 2487925 Validate the cash receipt id, if passed
       
       IF (p_adj_rec.associated_cash_receipt_id IS NOT NULL) THEN
   
           ar_adjvalidate_pvt.Validate_Associated_Receipt (
                               p_adj_rec,
                               l_return_status
                              );
           IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
           THEN
             p_validation_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug ('Validate_Adj_modify: ' || ' failed to validate associated receipt id ');
             END IF;
           END IF;
       END IF;

     --Bug 2487925 if the associated_application_id is passed, then validate
     --it. It should belong to a valid cash receipt and application. And the
     -- adjustment and the application should be done to the same invoice. 
 
       IF ( p_adj_rec.associated_application_id IS NOT NULL )  
       THEN
         BEGIN
          SELECT cash_receipt_id 
          INTO   l_cash_receipt_id
          FROM   ar_receivable_applications
          WHERE  status= 'APP'
          AND    display='Y'
          AND    receivable_application_id  = p_adj_rec.associated_application_id
          AND    applied_payment_schedule_id= p_old_adj_rec.payment_schedule_id;
         EXCEPTION
           WHEN no_data_found THEN
             FND_MESSAGE.SET_NAME ( 'AR',  'AR_RAPI_REC_APP_ID_INVALID');
             FND_MSG_PUB.ADD ;
             p_validation_status := FND_API.G_RET_STS_ERROR;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Validate_Adj_modify: ' || 'Associated Application ID passed is invalid');
             END IF;
         END;

       END IF;
      
       --Show error is cash receipt is id not found
 
       IF (( p_adj_rec.associated_application_id IS NOT NULL   ) AND
           ( p_old_adj_rec.associated_cash_receipt_id IS NULL  ) AND 
           ( p_adj_rec.associated_cash_receipt_id  IS NULL     ) AND
           ( l_cash_receipt_id IS NULL                         )) THEN
             
             FND_MESSAGE.SET_NAME ( 'AR',  'AR_RAPI_REC_APP_ID_INVALID');
             FND_MSG_PUB.ADD ;
             p_validation_status := FND_API.G_RET_STS_ERROR;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Validate_Adj_modify: ' || 'Associated Application ID should belongs to valid Receipt,pass cash receipt id');
             END IF;
       END IF;
 
       /*---------------------------------------------------+
       |   5. Copy all other attributes into p_adj_rec      |
       +---------------------------------------------------*/ 
       
       l_temp_adj_rec.comments := p_adj_rec.comments ;
       l_temp_adj_rec.status := p_adj_rec.status ;
       l_temp_adj_rec.gl_date := p_adj_rec.gl_date ;
    
     --Bug 2487925, if only application id is passed, take the cash receipt id of the 
     --application, if only cash receipt id is passed, just update associated cash receipt id only

       IF l_cash_receipt_id IS NOT NULL THEN 
          l_temp_adj_rec.associated_cash_receipt_id := l_cash_receipt_id;
       ELSIF p_adj_rec.associated_cash_receipt_id IS NOT NULL THEN
          l_temp_adj_rec.associated_cash_receipt_id := p_adj_rec.associated_cash_receipt_id;
       END IF;
    
       l_temp_adj_rec.associated_application_id := p_adj_rec.associated_application_id;
       
       p_adj_rec := p_old_adj_rec ;

       IF ( l_temp_adj_rec.comments IS NOT NULL )
       THEN
           p_adj_rec.comments := l_temp_adj_rec.comments;
       END IF;

       IF ( l_temp_adj_rec.status IS NOT NULL ) 
       THEN
          p_adj_rec.status := l_temp_adj_rec.status ;
       END IF ;   

       IF ( l_temp_adj_rec.gl_date IS NOT NULL ) 
       THEN
          p_adj_rec.gl_date := l_temp_adj_rec.gl_date ;
       END IF ;       

      --Bug 2487925
       IF ( l_temp_adj_rec.associated_cash_receipt_id IS NOT NULL )
       THEN
          p_adj_rec.associated_cash_receipt_id := l_temp_adj_rec.associated_cash_receipt_id ;
       END IF ;
       
       IF ( l_temp_adj_rec.associated_application_id IS NOT NULL )
       THEN
          p_adj_rec.associated_application_id := l_temp_adj_rec.associated_application_id ;
       END IF ;

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Validate_Adj_modify()-' );
       END IF;

EXCEPTION
  
     WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION: Validate_Adj_Modify() ');
        END IF;
        FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME,'Validate_Adj_Modify');
	p_validation_status := FND_API.G_RET_STS_UNEXP_ERROR ;  
        RETURN;
   

END Validate_Adj_Modify;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Validate_Adj_Reverse                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the validation routine for Reversal of Approvals     |
 |              						             |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                    |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_old_adj_rec                                           |
 |                                                                           |
 |              OUT:                                                         |
 |                   p_Validation_status                                     |
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                   p_reversal_gl_date                                      |
 |                   p_reversal_date                                         |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JAN-97  Created                                      |
 |                                                                           |
 +===========================================================================*/

PROCEDURE Validate_Adj_Reverse  (
		p_old_adj_rec   	IN	ar_adjustments%rowtype,
                p_reversal_gl_date	IN OUT NOCOPY	date,
                p_reversal_date		IN OUT NOCOPY date,
		p_validation_status	IN OUT NOCOPY	varchar2
	        ) IS

l_ps_rec	ar_payment_schedules%rowtype;
l_return_status varchar2(1);

BEGIN

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Validate_Adj_Reverse()+');
       END IF;

       /*----------------------------------------------+
       | Validate Old Adjustment status. Cannot reverse|
       | if status is 'A'                              |
       +----------------------------------------------*/ 

       IF ( p_old_adj_rec.status <> 'A' )
       THEN
            FND_MESSAGE.SET_NAME ( 'AR', 'AR_AAPI_NO_CHANGE_OR_REVERSE');
            FND_MESSAGE.SET_TOKEN ( 'STATUS',  p_old_adj_rec.status);
            FND_MSG_PUB.ADD ;
            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_Reverse: ' || 'the status of the old adj is not A ');
            END IF;
       END IF;       
 
       
       /*-------------------------------------------------+
       | Validate reversal dates                          |
       +-------------------------------------------------*/ 
 

       IF ( p_reversal_gl_date IS  NULL ) 
       THEN
           p_reversal_gl_date := p_old_adj_rec.gl_date;
       END IF;

       IF ( p_reversal_date IS  NULL ) 
       THEN
           p_reversal_date := p_old_adj_rec.apply_date;
       END IF;

       /*-----------------------------------+
       |  Get the Payment schedule details  |
       +-----------------------------------*/

       BEGIN
      
         SELECT	*
           INTO	l_ps_rec
           FROM	ar_payment_schedules 
      	  WHERE	payment_schedule_id = p_old_adj_rec.payment_schedule_id;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
        
            /*-----------------------------------------------+
      	    |  Payment schedule Id does not exist            |
      	    |  Set the message and status accordingly        |
      	    +-----------------------------------------------*/

            FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_INVALID_PAYMENT_SCHEDULE');
            FND_MESSAGE.SET_TOKEN ( 'PAYMENT_SCHEDULE_ID',  to_char(p_old_adj_rec.payment_schedule_id) ) ;
            FND_MSG_PUB.ADD ;

            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_Reverse: ' || 'invalid payment schedule id');
            END IF;
       END ;

       ar_adjvalidate_pvt.Validate_dates (
	                     p_reversal_date,
                             p_reversal_gl_date,
                             l_ps_rec,
		             l_return_status
	                    ) ;
       IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
            p_validation_status := l_return_status;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_Reverse: ' || 'invalid dates');
            END IF;
       END IF;

       p_reversal_gl_date := trunc(p_reversal_gl_date);
       p_reversal_date := trunc(p_reversal_date);
     
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Validate_Adj_Reverse()-' );
       END IF;

EXCEPTION
  
     WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION: Validate_Adj_Reverse() ');
        END IF;
        FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME,'Validate_Adj_Reverse');
	p_validation_status := FND_API.G_RET_STS_UNEXP_ERROR ;  
        RETURN;
 

END Validate_Adj_Reverse;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Validate_Adj_Approve                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the validation routine for Approval                  |
 |              						             |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                    |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_old_adj_rec                                           |
 |                                                                           |
 |              OUT:                                                         |
 |                   p_Validation_status                                     |
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                   p_adj_rec                                               |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JAN-97  Created                                      |
 |                                                                           |
 +===========================================================================*/

PROCEDURE Validate_Adj_Approve  (
		p_adj_rec	IN OUT NOCOPY 	ar_adjustments%rowtype,
		p_old_adj_rec   IN	ar_adjustments%rowtype,
                p_chk_approval_limits IN      varchar2,
		p_validation_status IN OUT NOCOPY	varchar2
	        ) IS

l_ps_rec	ar_payment_schedules%rowtype;
l_approved_flag	varchar2(1);
l_temp_adj_rec  ar_adjustments%rowtype;
l_return_status varchar2(1);

BEGIN

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Validate_Adj_Approve()+');
       END IF;

      /*-----------------------------------------------+
       | Validate Old Adjustment status. Cannot approve|
       | if status is 'A' or 'R'                       |
       +----------------------------------------------*/ 

       IF ( p_old_adj_rec.status IN ('A','R') )  /*Bug 4290494*/
       THEN

          FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_NO_CHANGE_OR_REVERSE');
          FND_MESSAGE.SET_TOKEN ( 'STATUS',  p_old_adj_rec.status ) ;
          FND_MSG_PUB.ADD ;
          p_validation_status := FND_API.G_RET_STS_ERROR;
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('Validate_Adj_Approve: ' || 'the adjustment is already approved or rejected');
          END IF;
       END IF;       

       /*----------------------------------------------------+
       |  If new status is NULL set it to 'A'                |
       +----------------------------------------------------*/      
 
       IF (p_adj_rec.status IS NULL )
       THEN
           p_adj_rec.status := 'A' ;
       END IF;

       /*----------------------------------------------------+
       |  Check new status. It could be NULL, 'A','R','W','M'|
       +----------------------------------------------------*/ 
       
       IF ( (p_adj_rec.status IS NOT NULL) AND
            (p_adj_rec.status NOT IN ('A', 'R', 'W', 'M')) )
       THEN

            FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_INVALID_CHANGE_STATUS');
            FND_MESSAGE.SET_TOKEN ( 'STATUS',  p_adj_rec.status ) ;
            FND_MSG_PUB.ADD ;
            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_Approve: ' || 'the value of the new status is not in A, R, W, M');
            END IF;
           
       END IF;

       

       /*---------------------------------------------------+
       |   2. Validate approval limits if new status is 'A' |
       +---------------------------------------------------*/ 

       /*----------------------------------+
       |  a) Get the invoice currency code |
       +----------------------------------*/    

       BEGIN
      
         SELECT	*
           INTO	l_ps_rec
           FROM	ar_payment_schedules 
      	  WHERE	payment_schedule_id = p_old_adj_rec.payment_schedule_id;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
        
            /*-----------------------------------------------+
      	    |  Payment schedule Id does not exist            |
      	    |  Set the message and status accordingly        |
      	    +-----------------------------------------------*/

            FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_INVALID_PAYMENT_SCHEDULE');
            FND_MESSAGE.SET_TOKEN('PAYMENT_SCHEDULE_ID',to_char(p_old_adj_rec.payment_schedule_id));
            FND_MSG_PUB.ADD ;
            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_Approve: ' || 'Invalid payment schedule id');
            END IF;

       END ;

     /*----------------------------------------------------+
      |  Change introduced for the BR/BOE project.         |
      |  Special processing for bypassing limit check if   |
      |  p_chk_approval_limits is set to 'F'               |
      +--------------------------------------------------- */         
       IF ( p_adj_rec.status = 'A'  and
            p_chk_approval_limits = FND_API.G_TRUE)
       THEN
       
         /*-----------------------------------+
      	 |  Get the approval limits and check |
      	 +-----------------------------------*/

         ar_adjvalidate_pvt.Within_approval_limits(
                  p_old_adj_rec.amount,
                  l_ps_rec.invoice_currency_code,
                  l_approved_flag,
	  	  l_return_status
                  ) ;
       
         IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
         THEN
            p_validation_status := l_return_status;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_Approve: ' || ' Error in  Get the approval limits and check ');
            END IF;
         END IF;

         IF ( l_approved_flag <> FND_API.G_TRUE )
         THEN
            FND_MESSAGE.SET_NAME ('AR', 'AR_VAL_AMT_APPROVAL_LIMIT');
            FND_MSG_PUB.ADD ;

            p_validation_status := FND_API.G_RET_STS_ERROR;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_Approve: ' || 'not within approval limits');
            END IF;
         END IF;         

         /*-------------------------------------------------+
         | Check over application                           |
         +-------------------------------------------------*/

         -- This is done by the entity handler
       
       END IF;

       /*-------------------------------------------------+
       |   3. Validate GL date                            |
       +-------------------------------------------------*/ 
 
          /*Bug4303601*/
          ar_adjvalidate_pvt.Validate_dates (
	                     p_old_adj_rec.apply_date,
                             NVL(p_adj_rec.gl_date,p_old_adj_rec.gl_date),
                             l_ps_rec,
		             l_return_status
	                    ) ;
          IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
          THEN
            p_validation_status := l_return_status ;
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Validate_Adj_Approve: ' || 'invalid gl_date');
            END IF;
          END IF;

       p_adj_rec.gl_date := trunc(p_adj_rec.gl_date);
    
       /*---------------------------------------------------+
       |   4. Copy all other attributes into p_adj_rec      |
       +---------------------------------------------------*/ 
       
       l_temp_adj_rec := NULL ;

       l_temp_adj_rec.comments := p_adj_rec.comments ;
       l_temp_adj_rec.status := p_adj_rec.status ;
       l_temp_adj_rec.gl_date := p_adj_rec.gl_date ;
       
       p_adj_rec := p_old_adj_rec ;

       IF ( l_temp_adj_rec.comments IS NOT NULL )
       THEN
           p_adj_rec.comments := l_temp_adj_rec.comments;
       END IF;

       IF ( l_temp_adj_rec.status IS NOT NULL ) 
       THEN
          p_adj_rec.status := l_temp_adj_rec.status ;
       END IF ;   

       IF ( l_temp_adj_rec.gl_date IS NOT NULL ) 
       THEN
          p_adj_rec.gl_date := l_temp_adj_rec.gl_date ;
       END IF ;       

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('Validate_Adj_Approve ()-' );
       END IF;

EXCEPTION
  
     WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION: Validate_Adj_Approve() ');
        END IF;
        FND_MSG_PUB.Add_Exc_Msg (G_PKG_NAME,'Validate_Adj_Approve');
	p_validation_status := FND_API.G_RET_STS_UNEXP_ERROR ;  
        RETURN;
 

END Validate_Adj_Approve;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |              populate_adj_llca_gt                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the populate routine for Line level adjustment       |
 |              						             |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                    |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_customer_trx_id					     |	
 |		     p_llca_adj_trx_lines_tbl				     |
 |                                                                           |
 |              OUT:                                                         |
 |                   p_return_status                                         |
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    mpsingh 04-feb-2008  Created                                           |
 |                                                                           |
 +===========================================================================*/

PROCEDURE populate_adj_llca_gt (
	     p_customer_trx_id        IN NUMBER,
  	     p_llca_adj_trx_lines_tbl     IN llca_adj_trx_line_tbl_type,
	     p_return_status          OUT NOCOPY VARCHAR2)
IS 
BEGIN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('Populate_adj_llca_gt ()+ ');
  END IF;

  p_return_status := FND_API.G_RET_STS_SUCCESS;

  -- Clean the GT Table first.
  delete from ar_llca_adj_trx_lines_gt
  where customer_trx_id = p_customer_trx_id;

  delete from ar_llca_adj_trx_errors_gt
  where customer_trx_id = p_customer_trx_id;

 
 
 If p_llca_adj_trx_lines_tbl.count = 0 Then 
	  IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('=======================================================');
           arp_util.debug('   PL SQL TABLE     (    INPUT PARAMETERS ........)+    ');
           arp_util.debug('=======================================================');
           arp_util.debug('create_linelevel_adjustment: ' || 'Pl Sql Table is empty ..
                  All Lines  ');
           END IF; 
Else
	  IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('No of records in PLSQL Table
                  =>'||to_char(p_llca_adj_trx_lines_tbl.count));
          END IF;
	     For i in p_llca_adj_trx_lines_tbl.FIRST..p_llca_adj_trx_lines_tbl.LAST
	     Loop 
		 Insert into ar_llca_adj_trx_lines_gt
		 (  customer_trx_id,
		    customer_trx_line_id,
		    receivables_trx_id,
		    line_amount		   
		 )
		 values 
		 (
		    p_customer_trx_id,
		    p_llca_adj_trx_lines_tbl(i).customer_trx_line_id,
		    p_llca_adj_trx_lines_tbl(i).receivables_trx_id,
		    p_llca_adj_trx_lines_tbl(i).line_amount
		 ); 

	  IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('=======================================================');
           arp_util.debug(' Line .............=> '||to_char(i));
           arp_util.debug('customer_trx_id      => '||to_char(p_customer_trx_id));
           arp_util.debug('customer_trx_line_id => '||to_char(p_llca_adj_trx_lines_tbl(i).customer_trx_line_id));
           arp_util.debug('line_amount          => '||to_char(p_llca_adj_trx_lines_tbl(i).line_amount));
           arp_util.debug('receivables_trx_id           => '||to_char(p_llca_adj_trx_lines_tbl(i).receivables_trx_id));
           arp_util.debug('=======================================================');
          END IF;
	      End Loop;
End If; 
   
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('populate_adj_llca_gt ()- ');
  END IF;

EXCEPTION
 WHEN others THEN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('EXCEPTION: (populate_adj_llca_gt)');
   END IF;
   p_return_status := FND_API.G_RET_STS_ERROR;
   raise;
 End populate_adj_llca_gt;


 /*===========================================================================+
 | PROCEDURE                                                                 |
 |              validate_hdr_level                                           |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the validate hdr routine for Line level adjustment   |
 |              						             |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                    |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_adj_rec					             |	
 |									     |	
 |              OUT:                                                         |
 |                   p_return_status                                         |
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    mpsingh 12-feb-2008  Created                                           |
 |                                                                           |
 +===========================================================================*/

PROCEDURE validate_hdr_level (
	     p_adj_rec		IN 	ar_adjustments%rowtype,
	     p_return_status    OUT NOCOPY VARCHAR2)
IS 


 l_return_status	varchar2(1);
 ll_installment        number := 0;

 -- Legacy status
  ll_leg_app               varchar2(1);
  ll_mfar_app              varchar2(1);
  ll_leg_adj               varchar2(1);
  ll_mfar_adj              varchar2(1);

BEGIN
  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('validate_hdr_level ()+ ');
  END IF;

  p_return_status := FND_API.G_RET_STS_SUCCESS;


IF p_adj_rec.type NOT IN ('LINE')
         THEN
               
              l_return_status := FND_API.G_RET_STS_ERROR ;
	      FND_MESSAGE.SET_NAME ('AR', 'AR_ADJ_API_TYPE_DISALLOW');
              FND_MESSAGE.SET_TOKEN ( 'TYPE',   p_adj_rec.TYPE ) ;
              FND_MSG_PUB.ADD ;
              
   	    IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment : ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
		   arp_util.debug('create_linelevel_adjustment : ' || 'line level adjustment can only allowed for type LINE');
	    END IF;
             
 END IF;

 IF p_adj_rec.customer_trx_line_id IS NOT NULL 
         THEN
              
	      FND_MESSAGE.SET_NAME ('AR', 'AR_ADJ_API_CUST_LINE_ID_IG');
              FND_MESSAGE.SET_TOKEN ( 'CUSTOMER_TRX_LINE_ID',   p_adj_rec.customer_trx_line_id ) ;
              FND_MSG_PUB.ADD ;
              
   	    IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment : ' || 'Warning(s) occurred. Ignoring header level customer trx line id');
		   
	    END IF;
             
 END IF;


 IF p_adj_rec.receivables_trx_id IS NOT NULL
         THEN
              
	      FND_MESSAGE.SET_NAME ('AR', 'AR_ADJ_API_RECV_TRX_ID_IG');
              FND_MESSAGE.SET_TOKEN ( 'RECEIVABLES_TRX_ID',   p_adj_rec.receivables_trx_id ) ;
              FND_MSG_PUB.ADD ;
              
   	    IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment : ' || 'Warning(s) occurred. Ignoring header level receivables trx id');
		  
	    END IF;
             
 END IF;

  IF p_adj_rec.amount IS NOT NULL
         THEN
              FND_MESSAGE.SET_NAME ('AR', 'AR_ADJ_API_AMOUNT_IG');
              FND_MESSAGE.SET_TOKEN ( 'AMOUNT',   p_adj_rec.amount ) ;
              FND_MSG_PUB.ADD ;
              
   	    IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment : ' || 'Warning(s) occurred. Ignoring header level Amount');
		   
	    END IF;
             
 END IF;


 /* Multiple Installment transaction not allowed at line-level */
  select count(*) into ll_installment
  from ar_payment_schedules
  where class          in ('INV','DM')
  and customer_trx_id = p_adj_rec.customer_trx_id;
  
  IF nvl(ll_installment,0) > 1
  THEN
        l_return_status := FND_API.G_RET_STS_ERROR ;
	FND_MESSAGE.SET_NAME ('AR', 'AR_LL_ADJ_INSTALL_NOT_ALLOWED');
        FND_MESSAGE.SET_TOKEN ( 'CUST_TRX_ID',  p_adj_rec.customer_trx_id ) ;
        FND_MSG_PUB.ADD ;
	IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment : ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
		   arp_util.debug('create_linelevel_adjustment : ' || 'Multiple Installment transaction not allowed at line-level');
	END IF;
         
  END IF;

  /* Legacy data with activity not allowed at line-level */
  Begin 
     arp_det_dist_pkg.check_legacy_status
           (p_trx_id     => p_adj_rec.customer_trx_id,
            x_11i_adj    => ll_leg_adj,
            x_mfar_adj   => ll_mfar_adj,
            x_11i_app    => ll_leg_app,
            x_mfar_app   => ll_mfar_app );
  IF (ll_leg_adj = 'Y') OR (ll_leg_app = 'Y') 
  THEN
        l_return_status := FND_API.G_RET_STS_ERROR ;
	FND_MESSAGE.SET_NAME ('AR', 'AR_LL_ADJ_LEGACY_NOT_ALLOWED');
        FND_MESSAGE.SET_TOKEN ( 'CUST_TRX_ID',  p_adj_rec.customer_trx_id ) ;
        FND_MSG_PUB.ADD ;
	IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment : ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
		   arp_util.debug('create_linelevel_adjustment : ' || 'Legacy data with activity not allowed at line-level');
	END IF;
        
  END IF;  

  Exception
  when others then 
      p_return_status := FND_API.G_RET_STS_ERROR;
      raise;
  End; 

  p_return_status  := l_return_status;

  IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug('validate_hdr_level ()- ');
  END IF;

  EXCEPTION
   when others then 
      IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('EXCEPTION: (validate_hdr_level)');
      END IF;
      p_return_status := FND_API.G_RET_STS_ERROR;
      raise;

  END validate_hdr_level;



/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Create_Adjustment                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the main routine that creates adjustment             |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |     fnd_api.compatible_api_call                                           |
 |     fnd_api.g_exc_unexpected_error                                        |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_success                                             |
 |     fnd_api.to_boolean                                                    |
 |     fnd_msg_pub.check_msg_level                                           |
 |     fnd_msg_pub.count_and_get                                             |
 |     fnd_msg_pub.initialize                                                |
 |     ar_adjvalidate_pvt.Init_Context_Rec                                   |
 |     ar_adjvalidate_pvt.Cache_Details                                      |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_api_name                                              |
 |                   p_api_version                                           |
 |                   p_init_msg_list                                         |
 |                   p_commit                                                |
 |                   p_validation_level                                      |
 |                   p_adj_rec                                               |
 |                   p_chk_approval_limits                                   |
 |                   p_check_amount                                          |
 |              OUT:                                                         |
 |                   p_return_status                                         |
 |                   p_msg_count					     |
 |		     p_msg_data		                                     |
 |                   p_new_adjust_number                                     |
 |                   p_new_adjust_id                                         |	
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JUN-97  Created                                      |
 |    Saloni Shah    03-FEB-00  Changes for the BR/BOE project has been made.|
 |                              Two new IN parameters have been added:       |
 |                                 - p_chk_approval_limits and p_check_amount|
 |                                  These parameters are passed to           |
 |                                  Validate_Adj_Insert procedure.           |
 |                              p_chk_approval_limits flag indicates whether |
 |                              the adjustment amount should be validated    |
 |                              against the users approval limits or not.    |
 |                              p_check_amount is set to 'F' in case of      |
 |                              adjustment reversal only, this flag          |
 |                              when set to 'F' indicates that even if the   | 
 |                              adjustment type is 'INVOICE'the              |
 |                              amount_due_remaining will not be zero.       |
 |    SNAMBIAR       04-May-00  Bug 1290698                                  |
 |                              Added Proration logic for partial payments   |
 |    SNAMBIAR       05-Sep-00  Bug 1392055 - Call prorate routine only when
 |                              PS.amount_due_remaining > 0
 |    SNAMBIAR       27-Sep-00  Added new parameters p_called_from and       
 |                              p_old_adj_id for reverse 
 |    AMMISHRA       13-Feb-02  Set l_override_flag to Y if CCID is 
 |                              overridden through ADjustment API.Then the 
 |                              l_override_flag is passed to insert_adjustment 
 |                              procedure.  
+===========================================================================*/

PROCEDURE Create_Adjustment (
p_api_name		IN	varchar2,
p_api_version		IN	number,
p_init_msg_list		IN	varchar2 := FND_API.G_FALSE,
p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
p_validation_level     	IN	number := FND_API.G_VALID_LEVEL_FULL,
p_msg_count		OUT NOCOPY  	number,
p_msg_data		OUT NOCOPY	varchar2,
p_return_status		OUT NOCOPY	varchar2 ,
p_adj_rec		IN 	ar_adjustments%rowtype,
p_chk_approval_limits   IN      varchar2 := FND_API.G_TRUE, 
p_check_amount          IN      varchar2 := FND_API.G_TRUE,
p_move_deferred_tax     IN      varchar2,
p_new_adjust_number	OUT NOCOPY	ar_adjustments.adjustment_number%type,
p_new_adjust_id		OUT NOCOPY	ar_adjustments.adjustment_id%type, 
p_called_from		IN	varchar2, 
p_old_adjust_id 	IN	ar_adjustments.adjustment_id%type,
p_org_id              IN      NUMBER DEFAULT NULL
) IS

  l_api_name		CONSTANT VARCHAR2(20) := 'XX_AR_ADJUST_PUB';
  l_api_version         CONSTANT NUMBER       := 1.0;

  l_hsec		VARCHAR2(10);
  l_status		number;

  l_inp_adj_rec		ar_adjustments%rowtype; 
  l_app_ps_rec		ar_payment_schedules%rowtype;
 
  o_adjustment_number	ar_adjustments.adjustment_number%type;
  o_adjustment_id 	ar_adjustments.adjustment_id%type;
  l_return_status	varchar2(1);
  l_chk_approval_limits  varchar2(1); 
  l_check_amount         varchar2(1);

  l_override_flag   varchar2(1);  --Bug 2183969
  l_org_return_status VARCHAR2(1);
  l_org_id                           NUMBER;
 
BEGIN


        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select hsecs
           into G_START_TIME
           from v$timer;
        END IF;

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT XX_AR_ADJUST_PUB;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Create_Adjustment: ' ||  'Compatility error occurred.');
            END IF;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*-------------------------------------------------------------+
       |   Initialize message list if p_init_msg_list is set to TRUE  |
       +-------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
        THEN
            FND_MSG_PUB.initialize;
        END IF;

--      arp_util.enable_debug(100000);

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Create_Adjustment()+ ');
        END IF;

	/*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        p_return_status := FND_API.G_RET_STS_SUCCESS;

/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       p_return_status := FND_API.G_RET_STS_ERROR;
 ELSE

	/*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

	/*--------------------------------------------+
        |   Copy the input adjustment record to local |
        |   variable to allow changes to it           |
        +--------------------------------------------*/
	l_inp_adj_rec := p_adj_rec ;

       
        /*------------------------------------------------+
        |   Initialize the profile options and cache data |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Init_Context_Rec ( 
                                   p_validation_level,
                                   l_return_status  
                                 ); 

        /*---------------------------------------------------+
        |   Check the return status                          |
        /*---------------------------------------------------+


        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Create_Adjustment: ' ||  ' Init_context_rec has errors ' );
             END IF;
        END IF;


        /*------------------------------------------------+
        |   Cache details                                 |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Cache_Details ( 
                              l_return_status  
                            ); 

        /*---------------------------------------------------+
        |   Check the return status                          |
        /*---------------------------------------------------+

        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Create_Adjustment: ' ||  ' Cache_details has errors ' );
             END IF;
        END IF;

	/*------------------------------------------+
        |  Validate the input details		    |
        |  Do not continue if there are errors.     |
        +------------------------------------------*/

       /*--------------------------------------------+
       | Change for the BOE/BR project has been made |
       | parameters p_chk_approval_limits and        |
       | p_check_amount are being passed.            |
       |                                             |
       | p_check_amount will only be 'F' in case of  |
       | reversal of adjustments                     |
       +---------------------------------------------*/   

      /*--------------------------------------------------+
       | Bug 1290698- If Partial partial amount is passed |
       | Calculate prorated amounts remaining.Need not    |
       | prorate while reversing                          |
       +--------------------------------------------------*/ 
       
       IF p_adj_rec.amount is NOT NULL and p_adj_rec.type = 'INVOICE' 
          and p_adj_rec.created_from <> 'REVERSE_ADJUSTMENT'
          and p_check_amount = 'F' THEN

          /*--------------------------------------------+
           |Fetch Payment schedule record  for prorating|
           +--------------------------------------------*/
	
	   arp_ps_pkg.fetch_p(l_inp_adj_rec.payment_schedule_id,l_app_ps_rec);
        
          /*------------------------------------------+
           |   Call Prorate calculation routine       | 
           +------------------------------------------*/
         --Bug 1392055 - Prorate only if amount_due_remaining > 0
         -- Bug 3461288 - change condition for prorating to <> 0, fix provided
         -- in 1392055 prevented prorating for Credit memos

           IF NVL(l_app_ps_rec.amount_due_remaining,0) <> 0 THEN

              ARP_APP_CALC_PKG.calc_applied_and_remaining(
                         l_inp_adj_rec.amount,
                         3, -- Prorate all
                         l_app_ps_rec.invoice_currency_code,
                         l_app_ps_rec.amount_line_items_remaining,
                         l_app_ps_rec.tax_remaining,
                         l_app_ps_rec.freight_remaining,
                         l_app_ps_rec.receivables_charges_remaining,
                         l_inp_adj_rec.line_adjusted,
                         l_inp_adj_rec.tax_adjusted,
                         l_inp_adj_rec.freight_adjusted,
                         l_inp_adj_rec.receivables_charges_adjusted,
                         l_inp_adj_rec.created_from);
           END IF; 
        END IF;
 
        l_chk_approval_limits := p_chk_approval_limits; 
        l_check_amount := p_check_amount; 

        IF (l_chk_approval_limits IS NULL) THEN
	   l_chk_approval_limits := FND_API.G_TRUE;
        END IF;

        IF (l_check_amount IS NULL) THEN
	   l_check_amount := FND_API.G_TRUE;
        END IF;

        XX_AR_ADJUST_PUB.Validate_Adj_Insert( 
                          l_inp_adj_rec,
                          l_chk_approval_limits,
                          l_check_amount,          
                          l_return_status
                        );

        IF   ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Create_Adjustment: ' ||  'Validation error(s) occurred. '||
			     'and setting status to ERROR');
             END IF;
        END IF;


	/*-----------------------------------------------+
        |  Handling all the validation exceptions        |
	+-----------------------------------------------*/
        IF (p_return_status = FND_API.G_RET_STS_ERROR)
        THEN
             RAISE FND_API.G_EXC_ERROR;
                
        ELSIF (p_return_status = FND_API.G_RET_STS_UNEXP_ERROR)
           THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


	/*-----------------------------------------------+
	| Build up remaining data for the entity handler |
        | Reset attributes which should not be populated |
        +-----------------------------------------------*/

	XX_AR_ADJUST_PUB.Set_Remaining_Attributes (
  		              	              l_inp_adj_rec, 
                                              l_return_status
                                              ) ;
	
        IF   ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN

             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Create_Adjustment: ' || 
                             'Validation error(s) occurred. Rolling back '||
			     'and setting status to ERROR');
             END IF;

             IF (p_return_status = FND_API.G_RET_STS_ERROR)
             THEN
                   RAISE FND_API.G_EXC_ERROR;
             ELSIF (p_return_status = FND_API.G_RET_STS_UNEXP_ERROR)
                THEN
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
             END IF;
        END IF;

	/*-----------------------------------------------+
	| Call the entity Handler for insert             |
	+-----------------------------------------------*/

/*Bug 2183969  set  l_override_flag to Y and passed to 
	insert_adjustment function if code_combination_id is 
	overridden through Adjustment API.
*/


	IF (l_inp_adj_rec.code_combination_id is NOT NULL) THEN
                l_override_flag := 'Y';
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Create_Adjustment: ' || 'l_inp_adj_rec.line_adjusted = ' || to_char(l_inp_adj_rec.line_adjusted));
           arp_util.debug('Create_Adjustment: ' || 'l_inp_adj_rec.tax_adjusted  = ' || to_char(l_inp_adj_rec.tax_adjusted));
        END IF;

	BEGIN
	    xx_arp_process_adjustment.insert_adjustment (
                           	'DUMMY',
                           	'1', 
                           	l_inp_adj_rec,
                           	o_adjustment_number,
			  	o_adjustment_id,
				l_check_amount,
                                p_move_deferred_tax,
                                p_called_from,
                                p_old_adjust_id,
				l_override_flag
                              ) ; 
            /* Bug 4910860
               Validate if the accounting entries balance */
            arp_balance_check.Check_Adj_Balance(o_adjustment_id,p_adj_rec.request_id,'Y');
     
        EXCEPTION
           WHEN OTHERS THEN
             /*---------------------------------------------------+
             |  Rollback to the defined Savepoint                 |
             +---------------------------------------------------*/

             ROLLBACK TO XX_AR_ADJUST_PUB;
             p_return_status := FND_API.G_RET_STS_ERROR ;
             
             FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
             FND_MESSAGE.set_token( 'GENERIC_TEXT', 'arp_process_adjustment.insert_adjustment exception: '||SQLERRM );
             --2920926
             FND_MSG_PUB.ADD;
             /*--------------------------------------------------+
             |  Get message count and if 1, return message data  |
             +---------------------------------------------------*/

             FND_MSG_PUB.Count_And_Get(
					p_encoded => FND_API.G_FALSE,
                                        p_count => p_msg_count,
                                        p_data  => p_msg_data
                                      );
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Create_Adjustment: ' || 
                'Error in Insert Entity handler. Rolling back ' ||
		'and setting status to ERROR');
             END IF;
             RETURN;

        END ;

	p_new_adjust_id := o_adjustment_id ;
        p_new_adjust_number := o_adjustment_number ;

       /*-------------------------------------------+
        |   ========== End of API Body ==========   |
        +-------------------------------------------*/
END IF;

       /*---------------------------------------------------+
        |  Get message count and if 1, return message data  |
        +---------------------------------------------------*/

        FND_MSG_PUB.Count_And_Get(
				   p_encoded => FND_API.G_FALSE,
                                   p_count => p_msg_count,
                                   p_data  => p_msg_data
                                 );

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit_flag )
        THEN 
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('Create_Adjustment: ' || 'committing');
              END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Create_Adjustment()- ');
        END IF;

        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select TO_CHAR( (hsecs - G_START_TIME) / 100)
           into l_hsec
           from v$timer;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Create_Adjustment: ' || 'Elapsed Time : '||l_hsec||' seconds');
           END IF;
        END IF;

EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Create_Adjustment: ' || SQLCODE);
                   arp_util.debug('Create_Adjustment: ' || SQLERRM);
                END IF;

                ROLLBACK TO XX_AR_ADJUST_PUB;
                p_return_status := FND_API.G_RET_STS_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Create_Adjustment: ' || SQLERRM);
                END IF;
                ROLLBACK TO XX_AR_ADJUST_PUB ;
                p_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN  
                      p_return_status := FND_API.G_RET_STS_ERROR ;
                      ROLLBACK TO XX_AR_ADJUST_PUB;
                      IF PG_DEBUG in ('Y', 'C') THEN
                         arp_util.debug('Create_Adjustment: ' || 
                            'Completion validation error(s) occurred. ' ||
                            'Rolling back and setting status to ERROR');
                      END IF;

                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
					   );
                      RETURN;
                ELSE 
                      NULL;
                END IF;
              
         arp_util.disable_debug;

END Create_Adjustment; 



/*===========================================================================+
 | PROCEDURE                                                                 |
 |              create_linelevel_adjustment                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the main routine that creates adjustment             |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |     fnd_api.compatible_api_call                                           |
 |     fnd_api.g_exc_unexpected_error                                        |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_success                                             |
 |     fnd_api.to_boolean                                                    |
 |     fnd_msg_pub.check_msg_level                                           |
 |     fnd_msg_pub.count_and_get                                             |
 |     fnd_msg_pub.initialize                                                |
 |     ar_adjvalidate_pvt.Init_Context_Rec                                   |
 |     ar_adjvalidate_pvt.Cache_Details                                      |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_api_name                                              |
 |                   p_api_version                                           |
 |                   p_init_msg_list                                         |
 |                   p_commit                                                |
 |                   p_validation_level                                      |
 |                   p_adj_rec                                               |
 |                   p_chk_approval_limits				     |
 |		     p_llca_adj_trx_lines_tbl				     |
 |                   p_check_amount                                          |
 |              OUT:                                                         |
 |                   p_return_status                                         |
 |                   p_msg_count					     |
 |		     p_msg_data		                                     |
 |                   p_new_adjust_number                                     |
 |                   p_new_adjust_id                                         |	
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                                                                           |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    mpsingh   04-FEB-2008  Created                                         |
 |									     |
+===========================================================================*/

PROCEDURE create_linelevel_adjustment (
p_api_name		IN	varchar2,
p_api_version		IN	number,
p_init_msg_list		IN	varchar2 := FND_API.G_FALSE,
p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
p_validation_level     	IN	number := FND_API.G_VALID_LEVEL_FULL,
p_msg_count		OUT NOCOPY  	number,
p_msg_data		OUT NOCOPY	varchar2,
p_return_status		OUT NOCOPY	varchar2 ,
p_adj_rec		IN 	ar_adjustments%rowtype,
p_chk_approval_limits   IN      varchar2 := FND_API.G_TRUE,
p_llca_adj_trx_lines_tbl IN llca_adj_trx_line_tbl_type, 
p_check_amount          IN      varchar2 := FND_API.G_TRUE,
p_move_deferred_tax     IN      varchar2,
p_llca_adj_create_tbl_type OUT NOCOPY llca_adj_create_tbl_type,
p_called_from		IN	varchar2, 
p_old_adjust_id 	IN	ar_adjustments.adjustment_id%type,
p_org_id              IN      NUMBER DEFAULT NULL
) IS

  l_api_name		CONSTANT VARCHAR2(20) := 'XX_AR_ADJUST_PUB';
  l_api_version         CONSTANT NUMBER       := 1.0;

  l_hsec		VARCHAR2(10);
  l_status		number;

  l_inp_adj_rec		ar_adjustments%rowtype; 
  l_app_ps_rec		ar_payment_schedules%rowtype;
 
  o_adjustment_number	ar_adjustments.adjustment_number%type;
  o_adjustment_id 	ar_adjustments.adjustment_id%type;
  l_return_status	varchar2(1);
  l_gt_return_status    varchar2(1);
  l_hdr_return_status   varchar2(1);
  l_line_return_status  varchar2(1);
  l_chk_approval_limits  varchar2(1); 
  l_check_amount         varchar2(1);

  l_override_flag   varchar2(1);  
  l_org_return_status VARCHAR2(1);
  l_org_id                           NUMBER;
  l_adj_int_count	number := 0;
  l_chk_count           number := 0;
  
  cursor gt_adj_lines_cur (p_cust_trx_id in number) is 
	select * from ar_llca_adj_trx_lines_gt
	where customer_trx_id = p_cust_trx_id; 

   
BEGIN


        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select hsecs
           into G_START_TIME
           from v$timer;
        END IF;

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT ar_adjust_line_PUB;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('create_linelevel_adjustment : ' ||  'Compatility error occurred.');
            END IF;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*-------------------------------------------------------------+
       |   Initialize message list if p_init_msg_list is set to TRUE  |
       +-------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
        THEN
            FND_MSG_PUB.initialize;
        END IF;

--      arp_util.enable_debug(100000);

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('create_linelevel_adjustment()+ ');
        END IF;

	/*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        p_return_status := FND_API.G_RET_STS_SUCCESS;

/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       p_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
        --Verify whether line level adjustment is allowed for given org/invoice 
	IF NOT arp_standard.is_llca_allowed(l_org_id,p_adj_rec.customer_trx_id) THEN
	  FND_MESSAGE.set_name('AR', 'AR_SUMMARIZED_DIST_NO_LLCA_ADJ');
	  FND_MSG_PUB.Add;
          l_return_status := FND_API.G_RET_STS_ERROR;
	  RAISE FND_API.G_EXC_ERROR;
	END IF;

	/*---------------------------------------------+
        |   ========== Start of API Body ==========   |
        +---------------------------------------------*/

	/*--------------------------------------------+
        |   Copy the input adjustment record to local |
        |   variable to allow changes to it           |
        +--------------------------------------------*/
	l_inp_adj_rec := p_adj_rec ;

       
        /*------------------------------------------------+
        |   Initialize the profile options and cache data |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Init_Context_Rec ( 
                                   p_validation_level,
                                   l_return_status  
                                 ); 

        /*---------------------------------------------------+
        |   Check the return status                          |
        /*---------------------------------------------------+


        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('create_linelevel_adjustment: ' ||  ' Init_context_rec has errors ' );
             END IF;
        END IF;


        /*------------------------------------------------+
        |   Cache details                                 |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Cache_Details ( 
                              l_return_status  
                            ); 

        /*---------------------------------------------------+
        |   Check the return status                          |
        /*---------------------------------------------------+

        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('create_linelevel_adjustment: ' ||  ' Cache_details has errors ' );
             END IF;
        END IF;

	/*------------------------------------------+
        |  Validate the input details		    |
        |  Do not continue if there are errors.     |
        +------------------------------------------*/

       /*--------------------------------------------+
       | Change for the BOE/BR project has been made |
       | parameters p_chk_approval_limits and        |
       | p_check_amount are being passed.            |
       |                                             |
       | p_check_amount will only be 'F' in case of  |
       | reversal of adjustments                     |
       +---------------------------------------------*/   

      /*--------------------------------------------------+
       | Bug 1290698- If Partial partial amount is passed |
       | Calculate prorated amounts remaining.Need not    |
       | prorate while reversing                          |
       +--------------------------------------------------*/ 
       
        l_chk_approval_limits := p_chk_approval_limits; 
        l_check_amount := p_check_amount; 

        IF (l_chk_approval_limits IS NULL) THEN
	   l_chk_approval_limits := FND_API.G_TRUE;
        END IF;

        IF (l_check_amount IS NULL) THEN
	   l_check_amount := FND_API.G_TRUE;
        END IF;


         populate_adj_llca_gt (
	     p_customer_trx_id		=> p_adj_rec.customer_trx_id,
  	     p_llca_adj_trx_lines_tbl   => p_llca_adj_trx_lines_tbl, 
	     p_return_status		=> l_gt_return_status);


	IF l_gt_return_status <> FND_API.G_RET_STS_SUCCESS
         THEN
               
               p_return_status := FND_API.G_RET_STS_ERROR ;
              
   	    IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment : ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
		   arp_util.debug('create_linelevel_adjustment : ' || 'Error while populating GT table');
	    END IF;
               
        END IF;

	IF (p_return_status = FND_API.G_RET_STS_ERROR)
		THEN
		     RAISE FND_API.G_EXC_ERROR;
			
		ELSIF (p_return_status = FND_API.G_RET_STS_UNEXP_ERROR)
		   THEN
		     RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
	END IF;

/*--------------------------------------------------+
| Header level Validation Call		            |
+--------------------------------------------------*/


	validate_hdr_level (
	     p_adj_rec,
	     l_hdr_return_status);


	IF l_hdr_return_status <> FND_API.G_RET_STS_SUCCESS
		 THEN
		       p_return_status := FND_API.G_RET_STS_ERROR ;
		      
		    IF PG_DEBUG in ('Y', 'C') THEN
			   arp_util.debug('create_linelevel_adjustment : ' || 'Error(s) occurred. Rolling back and setting status to ERROR');
			   arp_util.debug('create_linelevel_adjustment : ' || 'Error while populating GT table');
		    END IF;
		       
	 END IF;


	 IF (p_return_status = FND_API.G_RET_STS_ERROR)
			THEN
			     RAISE FND_API.G_EXC_ERROR;
				
			ELSIF (p_return_status = FND_API.G_RET_STS_UNEXP_ERROR)
			   THEN
			     RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
	END IF;


 IF  ( p_return_status = FND_API.G_RET_STS_SUCCESS )  -- Start of for loop processing
 THEN


--For i in p_llca_adj_trx_lines_tbl.FIRST..p_llca_adj_trx_lines_tbl.LAST
FOR gt_adj_lines_row IN gt_adj_lines_cur(p_adj_rec.customer_trx_id)
Loop 

       /* l_inp_adj_rec.customer_trx_line_id := p_llca_adj_trx_lines_tbl(i).customer_trx_line_id;
	l_inp_adj_rec.receivables_trx_id   := p_llca_adj_trx_lines_tbl(i).receivables_trx_id;
	l_inp_adj_rec.amount		   := p_llca_adj_trx_lines_tbl(i).line_amount;*/

        l_line_return_status := FND_API.G_RET_STS_SUCCESS;


	l_inp_adj_rec.customer_trx_line_id := gt_adj_lines_row.customer_trx_line_id;
	l_inp_adj_rec.receivables_trx_id   := gt_adj_lines_row.receivables_trx_id;
	l_inp_adj_rec.amount		   := gt_adj_lines_row.line_amount;

	l_adj_int_count := l_adj_int_count + 1;
	p_llca_adj_create_tbl_type(l_adj_int_count).adjustment_number := 0;
	p_llca_adj_create_tbl_type(l_adj_int_count).adjustment_id     := 0;
	p_llca_adj_create_tbl_type(l_adj_int_count).customer_trx_line_id := gt_adj_lines_row.customer_trx_line_id;

-- Check for null customer trx line id
  IF gt_adj_lines_row.customer_trx_line_id IS NULL  -- Check for null Customer Trx Line Id
  THEN
        insert into ar_llca_adj_trx_errors_gt
	        (
		customer_trx_id,   
		customer_trx_line_id,
		receivables_trx_id,
		error_message,
		invalid_value
		)
		values
		(
		l_inp_adj_rec.customer_trx_id,   
		0,
		l_inp_adj_rec.receivables_trx_id,
		'AR_RAPI_TRX_LINE_ID_INVALID ',
		'customer_trx_line_id'
		);

            l_line_return_status := FND_API.G_RET_STS_ERROR;

   ELSIF gt_adj_lines_row.receivables_trx_id IS NULL
   THEN
     
     insert into ar_llca_adj_trx_errors_gt
	        (
		customer_trx_id,   
		customer_trx_line_id,
		receivables_trx_id,
		error_message,
		invalid_value
		)
		values
		(
		l_inp_adj_rec.customer_trx_id,   
		l_inp_adj_rec.customer_trx_line_id,
		0,
		'AR_RAPI_RECEIVABLES_TRX_ID_INVALID ',
		'receivables_trx_id'
		);
     
            l_line_return_status := FND_API.G_RET_STS_ERROR;

   ELSE
	
	XX_AR_ADJUST_PUB.Validate_Adj_Insert( 
                          l_inp_adj_rec,
                          l_chk_approval_limits,
                          l_check_amount,          
                          l_return_status,
			  'Y'
                        );

        IF   ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             l_line_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('create_linelevel_adjustment: ' ||  'Validation error(s) occurred.');
             END IF;
        END IF;


	
	/*-----------------------------------------------+
	| Build up remaining data for the entity handler |
        | Reset attributes which should not be populated |
        +-----------------------------------------------*/

	
	IF   ( l_line_return_status = FND_API.G_RET_STS_SUCCESS ) THEN
		XX_AR_ADJUST_PUB.Set_Remaining_Attributes (
						      l_inp_adj_rec, 
						      l_return_status
						      ) ;
		
		IF   ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
		THEN

		    l_line_return_status := l_return_status ;
		     IF PG_DEBUG in ('Y', 'C') THEN
			arp_util.debug('create_linelevel_adjustment: ' || 
				     'Validation error(s) occurred.');
		     END IF;
		    
		END IF;
	 ELSE
	      p_return_status := FND_API.G_RET_STS_ERROR ; -- Bug 12635650 

	END IF;

 END IF; -- Check for null Customer Trx Line Id

	/*-----------------------------------------------+
	| Call the entity Handler for insert             |
	+-----------------------------------------------*/

IF  ( l_line_return_status = FND_API.G_RET_STS_SUCCESS ) THEN -- Processing the adjustment

	IF (l_inp_adj_rec.code_combination_id is NOT NULL) THEN
                l_override_flag := 'Y';
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('create_linelevel_adjustment: ' || 'l_inp_adj_rec.line_adjusted = ' || to_char(l_inp_adj_rec.line_adjusted));
           arp_util.debug('create_linelevel_adjustment: ' || 'l_inp_adj_rec.tax_adjusted  = ' || to_char(l_inp_adj_rec.tax_adjusted));
        END IF;

	BEGIN
	    xx_arp_process_adjustment.insert_adjustment (
                           	'DUMMY',
                           	'1', 
                           	l_inp_adj_rec,
                           	o_adjustment_number,
			  	o_adjustment_id,
				l_check_amount,
                                p_move_deferred_tax,
                                p_called_from,
                                p_old_adjust_id,
				l_override_flag,
				'LINE'
                              ) ; 
            /* Bug 4910860
               Validate if the accounting entries balance */
            arp_balance_check.Check_Adj_Balance(o_adjustment_id,p_adj_rec.request_id,'Y');

 
        EXCEPTION
           WHEN OTHERS THEN
             /*---------------------------------------------------+
             |  Rollback to the defined Savepoint                 |
             +---------------------------------------------------*/

             ROLLBACK TO ar_adjust_line_PUB;
             p_return_status := FND_API.G_RET_STS_ERROR ;
             
             FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
             FND_MESSAGE.set_token( 'GENERIC_TEXT', 'arp_process_adjustment.insert_adjustment exception: '||SQLERRM );
             --2920926
             FND_MSG_PUB.ADD;
             /*--------------------------------------------------+
             |  Get message count and if 1, return message data  |
             +---------------------------------------------------*/

             FND_MSG_PUB.Count_And_Get(
					p_encoded => FND_API.G_FALSE,
                                        p_count => p_msg_count,
                                        p_data  => p_msg_data
                                      );
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('create_linelevel_adjustment: ' || 
                'Error in Insert Entity handler. Rolling back ' ||
		'and setting status to ERROR');
             END IF;
             RETURN;

        END ;

	

	p_llca_adj_create_tbl_type(l_adj_int_count).adjustment_number    := o_adjustment_number ;
	p_llca_adj_create_tbl_type(l_adj_int_count).adjustment_id        := o_adjustment_id ;
	

	 
         

       /*-------------------------------------------+
        |   ========== End of API Body ==========   |
        +-------------------------------------------*/
   END IF; -- END of Processing the adjustment
END LOOP;  -- END of table loop
END IF;    -- END of for loop processing
END IF;

       /*---------------------------------------------------+
        |  Get message count and if 1, return message data  |
        +---------------------------------------------------*/

        FND_MSG_PUB.Count_And_Get(
				   p_encoded => FND_API.G_FALSE,
                                   p_count => p_msg_count,
                                   p_data  => p_msg_data
                                 );

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit_flag )
        THEN 
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('create_linelevel_adjustment: ' || 'committing');
              END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('create_linelevel_adjustment()- ');
        END IF;

        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select TO_CHAR( (hsecs - G_START_TIME) / 100)
           into l_hsec
           from v$timer;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('create_linelevel_adjustment: ' || 'Elapsed Time : '||l_hsec||' seconds');
           END IF;
        END IF;

EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment: ' || SQLCODE);
                   arp_util.debug('create_linelevel_adjustment: ' || SQLERRM);
                END IF;

                ROLLBACK TO ar_adjust_line_PUB;
                p_return_status := FND_API.G_RET_STS_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('create_linelevel_adjustment: ' || SQLERRM);
                END IF;
                ROLLBACK TO ar_adjust_line_PUB ;
                p_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN  
                      p_return_status := FND_API.G_RET_STS_ERROR ;
                      ROLLBACK TO ar_adjust_line_PUB;
                      IF PG_DEBUG in ('Y', 'C') THEN
                         arp_util.debug('create_linelevel_adjustment: ' || 
                            'Completion validation error(s) occurred. ' ||
                            'Rolling back and setting status to ERROR');
                      END IF;

                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
					   );
                      RETURN;
                ELSE 
                      NULL;
                END IF;
              
         arp_util.disable_debug;

END create_linelevel_adjustment;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Modify_Adjustment                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the main routine that modifies an adjustment         |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |     fnd_api.compatible_api_call                                           |
 |     fnd_api.g_exc_unexpected_error                                        |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_success                                             |
 |     fnd_api.to_boolean                                                    |
 |     fnd_msg_pub.check_msg_level                                           |
 |     fnd_msg_pub.count_and_get                                             |
 |     fnd_msg_pub.initialize                                                |
 |     ar_adjustments_pkg.fetch_p                                            |
 |     ar_process_adjustment.update_adjustment                               |
 |     ar_adjvalidate_pvt.within_approval_limit                              |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_api_name                                              |
 |                   p_api_version                                           |
 |                   p_init_msg_list                                         |
 |                   p_commit_flag                                           |
 |                   p_validation_level                                      |
 |                   p_adj_rec                                               |
 |                   p_chk_approval_limits                                   |
 | 		     p_old_adjust_id                                         |
 |              OUT:                                                         |
 |                   p_return_status                                         |
 |                   p_msg_count					     |
 |		     p_msg_data		                                     |
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JAN-97  Created                                      |
 |    Saloni Shah    03-FEB-00  Changes have been made for the BR/BOE project|
 |                              One new parameter has been added:            |
 |                                  - p_chk_approval_limits.                 |
 |                                  This parameter will be passed to         |
 |                                  Validate_Adj_Modify procedure.           |
 |                              If the value of the flag p_chk_approval_limit|
 |                              is set to 'F' then the adjusted amount will  |
 |                              not be validated against the users approval  |
 |                              limits.                                      |
 |    Satheesh Nambiar 17-May-00 Added one more parameter p_move_deferred_tax|
 |                               for BOE/BR
 +===========================================================================*/

PROCEDURE Modify_Adjustment (
p_api_name		IN	varchar2,
p_api_version		IN	number,
p_init_msg_list		IN	varchar2 := FND_API.G_FALSE,
p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
p_validation_level     	IN	number := FND_API.G_VALID_LEVEL_FULL,
p_msg_count		OUT NOCOPY  	number,
p_msg_data		OUT NOCOPY	varchar2,
p_return_status		OUT NOCOPY	varchar2 ,
p_adj_rec		IN 	ar_adjustments%rowtype,
p_chk_approval_limits   IN      varchar2 := FND_API.G_TRUE,
p_move_deferred_tax     IN      varchar2, 
p_old_adjust_id		IN	ar_adjustments.adjustment_id%type,
p_org_id              IN      NUMBER DEFAULT NULL
) IS

  l_api_name		CONSTANT VARCHAR2(20) := 'XX_AR_ADJUST_PUB';
  l_api_version         CONSTANT NUMBER       := 1.0;
  l_old_adj_rec		ar_adjustments%rowtype;		
  l_hsec		VARCHAR2(10);
  l_status		number;
  l_inp_adj_rec		ar_adjustments%rowtype; 
  l_return_status   varchar2(1)    := FND_API.G_RET_STS_SUCCESS;
  l_chk_approval_limits varchar2(1);
  l_org_return_status VARCHAR2(1);
  l_org_id                           NUMBER;
  
 
BEGIN
        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select hsecs
           into G_START_TIME
           from v$timer;
        END IF;

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT XX_AR_ADJUST_PUB;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Modify_Adjustment: ' ||  'Compatility error occurred.');
            END IF;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*-------------------------------------------------------------+
       |   Initialize message list if p_init_msg_list is set to TRUE  |
       +-------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
        THEN
            FND_MSG_PUB.initialize;
        END IF;

--      arp_util.enable_debug(100000);


        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Modify_Adjustment()+ ');
        END IF;

	/*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        p_return_status := FND_API.G_RET_STS_SUCCESS;



/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       p_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
	/*---------------------------------------------+
        |   ========== Start of API Body ==========    |
        +---------------------------------------------*/

	/*---------------------------------------------+
        |   Copy the input record to local variable to |
        |   allow changes to it                        |
        +---------------------------------------------*/
	l_inp_adj_rec := p_adj_rec ;


        /*------------------------------------------------+
        |   Initialize the profile options and cache data |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Init_Context_Rec ( 
                                   p_validation_level,
                                   l_return_status  
                                 ); 
        /*------------------------------------------------+
        |   Check status and return if error              |
        +------------------------------------------------*/

        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Modify_Adjustment: ' || 'failed to initialize the profile options ');
             END IF;
        END IF;

        /*------------------------------------------------+
        |   Cache details                                 |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Cache_Details ( 
                              l_return_status  
                            ); 
        /*------------------------------------------------+
        |   Check status and return if error              |
        +------------------------------------------------*/

        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Modify_Adjustment: ' || 'failed to cache details ');
             END IF;
        END IF;
            
	/*------------------------------------------------+
        |   Fetch details of the old adjustment record    |
        +------------------------------------------------*/
        BEGIN
	 arp_adjustments_pkg.fetch_p (
				       l_old_adj_rec,
                                       p_old_adjust_id
                                     );
        EXCEPTION
           WHEN OTHERS THEN
             /*---------------------------------------------------+
             |  Rollback to the defined Savepoint                 |
             +---------------------------------------------------*/
             ROLLBACK TO XX_AR_ADJUST_PUB;
             p_return_status := FND_API.G_RET_STS_ERROR ;
            FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_INVALID_ADJ_ID');
            FND_MESSAGE.SET_TOKEN ( 'ADJUSTMENT_ID',  to_char(p_old_adjust_id) ) ;
            FND_MSG_PUB.ADD ;
            RETURN;
        END ; 
	
        /* Removed the validation for Line Level adjustment as part of Bug 13036360. */


        /*-----------------------------------------------+
        |  Handling Line level the validation exceptions        |
        +-----------------------------------------------*/
        IF (p_return_status = FND_API.G_RET_STS_ERROR)
        THEN
             RAISE FND_API.G_EXC_ERROR;
        ELSIF (p_return_status = FND_API.G_RET_STS_UNEXP_ERROR)
           THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;
	  
	

	/*------------------------------------------+
        |  Validate the input details		    |
        |  Do not continue if there are errors.     |
        +------------------------------------------*/

      /*--------------------------------------------------+
       | Change for the BOE/BR project has been made      |
       | parameter p_chk_approval_limits is being passed. |
       +--------------------------------------------------*/
        l_chk_approval_limits := p_chk_approval_limits;
        IF (l_chk_approval_limits IS NULL) THEN
	   l_chk_approval_limits := FND_API.G_TRUE;
        END IF;

        XX_AR_ADJUST_PUB.Validate_Adj_Modify ( 
                                           l_inp_adj_rec,
					   l_old_adj_rec,
                                           l_chk_approval_limits,
                                           l_return_status
                                         );


        IF   ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Modify_Adjustment: ' || 
                'Validation error(s) occurred. Rolling back ' ||
		'and setting status to ERROR');
             END IF;
        END IF;


        /*-----------------------------------------------+
        |  Handling all the validation exceptions        |
        +-----------------------------------------------*/
        IF (p_return_status = FND_API.G_RET_STS_ERROR)
        THEN
             RAISE FND_API.G_EXC_ERROR;
        ELSIF (p_return_status = FND_API.G_RET_STS_UNEXP_ERROR)
           THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;


	/*-----------------------------------------------+
	| Call the entity Handler for Modify             |
	+-----------------------------------------------*/
        BEGIN	
	     arp_process_adjustment.update_adjustment (
                           	'DUMMY',
                           	'1', 
  				l_inp_adj_rec,
                                p_move_deferred_tax,
				p_old_adjust_id 
                              ) ; 
     
       EXCEPTION
           WHEN OTHERS THEN
             /*---------------------------------------------------+
             |  Rollback to the defined Savepoint                 |
             +---------------------------------------------------*/

             ROLLBACK TO XX_AR_ADJUST_PUB;

             p_return_status := FND_API.G_RET_STS_ERROR ;

             FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
             FND_MESSAGE.set_token( 'GENERIC_TEXT', 'arp_process_adjustment.update_adjustment exception: '||SQLERRM );
             --2920926
             FND_MSG_PUB.ADD;

             /*--------------------------------------------------+
             |  Get message count and if 1, return message data  |
             +---------------------------------------------------*/

             FND_MSG_PUB.Count_And_Get(
					p_encoded => FND_API.G_FALSE,
                                        p_count => p_msg_count,
                                        p_data  => p_msg_data
                                      );
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Modify_Adjustment: ' || 
                'Error in Insert Entity handler. Rolling back '||
		'and setting status to ERROR');
             END IF;

             RETURN;

        END ;

       /*-------------------------------------------+
        |   ========== End of API Body ==========   |
        +-------------------------------------------*/
END IF;

       /*---------------------------------------------------+
        |  Get message count and if 1, return message data  |
        +---------------------------------------------------*/

        FND_MSG_PUB.Count_And_Get(
				   p_encoded => FND_API.G_FALSE,
                                   p_count => p_msg_count,
                                   p_data  => p_msg_data
                                 );

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit_flag )
        THEN 
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('Modify_Adjustment: ' || 'committing');
              END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Modify_Adjustment()- ');
        END IF;

        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select TO_CHAR( (hsecs - G_START_TIME) / 100)
           into l_hsec
           from v$timer;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Modify_Adjustment: ' || 'Elapsed Time : '||l_hsec||' seconds');
           END IF;
        END IF;
        


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Modify_Adjustment: ' || SQLCODE);
                   arp_util.debug('Modify_Adjustment: ' || SQLERRM);
                END IF;

                ROLLBACK TO XX_AR_ADJUST_PUB;
                p_return_status := FND_API.G_RET_STS_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Modify_Adjustment: ' || SQLERRM);
                END IF;
                ROLLBACK TO XX_AR_ADJUST_PUB ;
                p_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN  
                      p_return_status := FND_API.G_RET_STS_ERROR ;
                      ROLLBACK TO XX_AR_ADJUST_PUB;
                      IF PG_DEBUG in ('Y', 'C') THEN
                         arp_util.debug('Modify_Adjustment: ' || 
                            'Completion validation error(s) occurred. ' ||
                            'Rolling back and setting status to ERROR');
                      END IF;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );
                      RETURN;
                ELSE 
                      NULL;
                END IF;
              
         arp_util.disable_debug;

END Modify_Adjustment; 


/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Reverse_Adjustment                                           |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the main routine that reverses an adjustment         |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXTERNAL PROCEDURES/FUNCTIONS ACCESSED                                    |
 |     fnd_api.compatible_api_call                                           |
 |     fnd_api.g_exc_unexpected_error                                        |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_success                                             |
 |     fnd_api.to_boolean                                                    |
 |     fnd_msg_pub.check_msg_level                                           |
 |     fnd_msg_pub.count_and_get                                             |
 |     fnd_msg_pub.initialize                                                |
 |     ar_adjustments_pkg.fetch_p                                            |
 |     ar_process_adjustment.reverse_adjustment                              |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_api_name                                              |
 |                   p_api_version                                           |
 |                   p_init_msg_list                                         |
 |                   p_commit_flag                                           |
 |                   p_validation_level                                      |
 |                   p_chk_approval_limits                                   |
 | 		     p_old_adjust_id                                         |
 |              OUT:                                                         |
 |                   p_return_status                                         |
 |                   p_msg_count					     |
 |		     p_msg_data		                                     |
 |                   p_new_adj_id                                            |
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JAN-97  Created                                      |
 |    Saloni Shah    03-FEB-00  Made changes for BR/BOE project.             |
 |                              Added 1 new parameter:                       |
 |                                - p_chk_approval_limits                    |
 |                              Made changes the way a reverse adjustment is |
 |                              created. It used to used to call             |
 |                              arp_process_adjustment.reverse_adjustment    |
 |                              which used to create a reverse adjustment but|
 |                              not update the payment schedules. This has   |
 |                              been changed to call Create Adjustment.      |
 |   S.Nambiar       27-Sep-00  Added a new parameter p_called_from for BR   |
 |   S.Nambiar       28-Nov-00  Bug 1449758 - Modified Reverse routine to    | 
 |                              initialize gl_posted_date and posting_control_id 
 +===========================================================================*/

PROCEDURE Reverse_Adjustment (
p_api_name		IN	varchar2,
p_api_version		IN	number,
p_init_msg_list		IN	varchar2 := FND_API.G_FALSE,
p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
p_validation_level     	IN	number := FND_API.G_VALID_LEVEL_FULL,
p_msg_count		OUT NOCOPY  	number,
p_msg_data		OUT NOCOPY	varchar2,
p_return_status		OUT NOCOPY	varchar2,
p_old_adjust_id		IN	ar_adjustments.adjustment_id%type,
p_reversal_gl_date	IN	date,
p_reversal_date		IN	date,
p_comments              IN      ar_adjustments.comments%type,
p_chk_approval_limits   IN      varchar2 := FND_API.G_TRUE,
p_move_deferred_tax     IN      varchar2,
p_new_adj_id            OUT NOCOPY     ar_adjustments.adjustment_id%type,
p_called_from           IN      varchar2,
p_org_id              IN      NUMBER DEFAULT NULL
) IS

  l_api_name		CONSTANT VARCHAR2(20) := 'XX_AR_ADJUST_PUB';
  l_api_version         CONSTANT NUMBER       := 1.0;
   
  l_reversal_date	ar_adjustments.apply_date%type;
  l_reversal_gl_date 	ar_adjustments.gl_date%type;
  l_hsec		VARCHAR2(10);
  l_status		number;
  l_adj_rec		ar_adjustments%rowtype;
  l_msg_count           number;
  l_msg_data            varchar2(250);
  l_new_adj_num         ar_adjustments.adjustment_number%type;
  l_check_amount        varchar2(1);

  l_return_status   varchar2(1)    := FND_API.G_RET_STS_SUCCESS;
  l_chk_approval_limits   varchar2(1);
  l_org_return_status VARCHAR2(1);
  l_org_id                           NUMBER;

   -- Line Leve Reversal
  l_llca_adj_trx_lines_tbl             XX_AR_ADJUST_PUB.llca_adj_trx_line_tbl_type;
  l_llca_adj_create_tbl_type           XX_AR_ADJUST_PUB.llca_adj_create_tbl_type;
  l_count_chk			       NUMBER;
  
  
 
BEGIN
        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select hsecs
           into G_START_TIME
           from v$timer;
        END IF;

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT XX_AR_ADJUST_PUB;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Reverse_Adjustment: ' ||  'Compatility error occurred.');
            END IF;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*-------------------------------------------------------------+
       |   Initialize message list if p_init_msg_list is set to TRUE  |
       +-------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
        THEN
            FND_MSG_PUB.initialize;
        END IF;

--      arp_util.enable_debug(100000);


        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Reverse_Adjustment()+ ');
        END IF;

	/*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        p_return_status := FND_API.G_RET_STS_SUCCESS;



/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       p_return_status := FND_API.G_RET_STS_ERROR;
 ELSE
	/*---------------------------------------------+
        |   ========== Start of API Body ==========    |
        +---------------------------------------------*/


        /*------------------------------------------------+
        |   Initialize the profile options and cache data |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Init_Context_Rec ( 
                                   p_validation_level,
                                   l_return_status  
                                 ); 
        /*------------------------------------------------+
        |   Check status and return if error              |
        +------------------------------------------------*/

        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Reverse_Adjustment: ' || ' failed to Initialize the profile options ');
             END IF;
        END IF;
      
	/*------------------------------------------------+
        |   Fetch details of the old adjustment record    |
        +------------------------------------------------*/
        BEGIN

	 arp_adjustments_pkg.fetch_p (
				       l_adj_rec,
                                       p_old_adjust_id
                                     );
        EXCEPTION
           WHEN OTHERS THEN
             /*---------------------------------------------------+
             |  Rollback to the defined Savepoint                 |
             +---------------------------------------------------*/

             ROLLBACK TO XX_AR_ADJUST_PUB;

             p_return_status := FND_API.G_RET_STS_ERROR ;

            FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_INVALID_ADJ_ID');
            FND_MESSAGE.SET_TOKEN ( 'ADJUSTMENT_ID',  to_char(p_old_adjust_id) ) ;
            FND_MSG_PUB.ADD ;
            RETURN;
        END ;            
            
        /*------------------------------------------------+
        |   Cache details                                 |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Cache_Details ( 
                              l_return_status  
                            ); 
        /*------------------------------------------------+
        |   Check status and return if error              |
        +------------------------------------------------*/

        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Reverse_Adjustment: ' || ' failed to Cache_Details ');
             END IF;
        END IF;

	/*--------------------------------------------+
        |  Validate the input details. Copy the dates |
        |  into local variables                       |
        +--------------------------------------------*/
                
        l_reversal_gl_date := p_reversal_gl_date ;
        l_reversal_date := p_reversal_date ;  

        /*------------------------------------------------+
        |   Validate if the adjustment can be reversed    |
        +------------------------------------------------*/

	
        XX_AR_ADJUST_PUB.Validate_Adj_Reverse ( 
					   l_adj_rec,
                                           l_reversal_gl_date,
                                           l_reversal_date,
                                           l_return_status
                                         );


       IF   ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
       THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Reverse_Adjustment: ' || 
                'Validation error(s) occurred. Rolling back '||
		'and setting status to ERROR');
             END IF;
        END IF;

        /*-----------------------------------------------+
        |  Handling all the validation exceptions        |
        +-----------------------------------------------*/
        IF (p_return_status = FND_API.G_RET_STS_ERROR)
        THEN
             RAISE FND_API.G_EXC_ERROR;
        ELSIF (p_return_status = FND_API.G_RET_STS_UNEXP_ERROR)
           THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*------------------------------------------------------------+
        | Reverse the amounts and create a new adj adjustment record.|
        | The new adjustment record should have the date and gl_date |
        | same as the reversal date and gl_date.                     |
        +------------------------------------------------------------*/
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Reverse_Adjustment: ' || 'Preparing the values for the new adjustment');
        END IF;

--   setting all the new values for the new adjustment 

--   setting all the new values for the new adjustment

BEGIN
		Select count(*)
		into  l_count_chk
		from  AR_ACTIVITY_DETAILS
		where source_id = p_old_adjust_id
		and   source_table = 'ADJ'
		and   nvl(CURRENT_ACTIVITY_FLAG,'Y') = 'Y' -- Bug 7241111
		and   customer_trx_line_id = l_adj_rec.customer_trx_line_id;
EXCEPTION
  When others then
     l_count_chk := 0;
END;


IF NVL(l_count_chk,0) <> 0 
THEN
	l_adj_rec.status := NULL; 
        l_adj_rec.adjustment_id := NULL;
        l_adj_rec.apply_date := p_reversal_date ;
        l_adj_rec.gl_date := p_reversal_gl_date; 
        l_adj_rec.amount := -l_adj_rec.amount; 
        l_adj_rec.acctd_amount := -l_adj_rec.acctd_amount; 
        l_adj_rec.line_adjusted := -l_adj_rec.line_adjusted; 
        l_adj_rec.freight_adjusted := -l_adj_rec.freight_adjusted; 
        l_adj_rec.tax_adjusted := -l_adj_rec.tax_adjusted; 
        l_adj_rec.receivables_charges_adjusted := 
				-l_adj_rec.receivables_charges_adjusted ;
        l_adj_rec.created_from := 'REVERSE_ADJUSTMENT'; 
        l_adj_rec.comments := p_comments;
	
	l_llca_adj_trx_lines_tbl(1).customer_trx_line_id := l_adj_rec.customer_trx_line_id;
	l_llca_adj_trx_lines_tbl(1).line_amount := l_adj_rec.amount;
	l_llca_adj_trx_lines_tbl(1).receivables_trx_id := l_adj_rec.receivables_trx_id;
	l_adj_rec.customer_trx_line_id := NULL; -- Line level Adjustment does not allow line id at header.
	l_adj_rec.receivables_trx_id := NULL; -- Line level Adjustment does not allow line id at header.

ELSE
        l_adj_rec.status := NULL; 
        l_adj_rec.adjustment_id := NULL;
        l_adj_rec.apply_date := p_reversal_date ;
        l_adj_rec.gl_date := p_reversal_gl_date; 
        l_adj_rec.amount := -l_adj_rec.amount; 
        l_adj_rec.acctd_amount := -l_adj_rec.acctd_amount; 
        l_adj_rec.line_adjusted := -l_adj_rec.line_adjusted; 
        l_adj_rec.freight_adjusted := -l_adj_rec.freight_adjusted; 
        l_adj_rec.tax_adjusted := -l_adj_rec.tax_adjusted; 
        l_adj_rec.receivables_charges_adjusted := 
				-l_adj_rec.receivables_charges_adjusted ;
        l_adj_rec.created_from := 'REVERSE_ADJUSTMENT'; 
        l_adj_rec.comments := p_comments; 
END IF;

      --Bug 1449758 - While reversing, null out NOCOPY the gl posting fiedls
        
        l_adj_rec.gl_posted_date     := NULL;
        l_adj_rec.posting_control_id := -3;

        /* Bugfix 2734179. Null out doc_seq columns so that they get
        fresh values for the reversed row. */
        l_adj_rec.doc_sequence_id := NULL;
        l_adj_rec.doc_sequence_value := NULL;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Reverse_Adjustment: ' || '--------------------------------------------------');
           arp_util.debug('Reverse_Adjustment: ' || 'New values for the new adjustment');
           arp_util.debug('Reverse_Adjustment: ' || 'status = ' || l_adj_rec.status );
           arp_util.debug('Reverse_Adjustment: ' || 'adjustment_id = ' || l_adj_rec.adjustment_id  );
           arp_util.debug('Reverse_Adjustment: ' || 'apply_date = ' ||  l_adj_rec.apply_date );
           arp_util.debug('Reverse_Adjustment: ' || 'gl_date = ' || l_adj_rec.gl_date );
           arp_util.debug('Reverse_Adjustment: ' || 'amount = ' ||  l_adj_rec.amount );
           arp_util.debug('Reverse_Adjustment: ' || 'acctd_amount = ' || l_adj_rec.acctd_amount );
           arp_util.debug('Reverse_Adjustment: ' || 'line_adjusted = ' ||  l_adj_rec.line_adjusted);
           arp_util.debug('Reverse_Adjustment: ' || 'freight_adjusted = ' || l_adj_rec.freight_adjusted );
           arp_util.debug('Reverse_Adjustment: ' || 'tax_adjusted = ' ||  l_adj_rec.tax_adjusted);
           arp_util.debug('Reverse_Adjustment: ' || 'receivables_charges_adjusted = ' || l_adj_rec.receivables_charges_adjusted );
           arp_util.debug('Reverse_Adjustment: ' || 'created_from = ' || l_adj_rec.created_from );
           arp_util.debug('Reverse_Adjustment: ' || 'comments = ' ||  l_adj_rec.comments);
           arp_util.debug('Reverse_Adjustment: ' || '--------------------------------------------------');
        END IF;


	l_check_amount := FND_API.G_FALSE;

        l_chk_approval_limits := p_chk_approval_limits;
        IF (l_chk_approval_limits IS NULL) THEN
            l_chk_approval_limits := FND_API.G_TRUE;
        END IF;

       /*--------------------------------------------------------------+
        | Call the create adjustment api to insert the new adjustment. | 
        +--------------------------------------------------------------*/

        BEGIN

          IF NVL(l_count_chk,0) <> 0 
	THEN
	   
	
	    XX_AR_ADJUST_PUB.create_linelevel_adjustment( 
	        p_api_name                 =>   'XX_AR_ADJUST_PUB',
        	p_api_version              =>   1.0,
        	p_msg_count                =>   l_msg_count ,
        	p_msg_data                 =>   l_msg_data,
        	p_return_status            =>   l_return_status,
        	p_adj_rec                  =>   l_adj_rec,
        	p_chk_approval_limits      =>   l_chk_approval_limits,
		p_llca_adj_trx_lines_tbl   =>   l_llca_adj_trx_lines_tbl,
        	p_check_amount             =>   l_check_amount,
                p_move_deferred_tax        =>   p_move_deferred_tax,
		p_llca_adj_create_tbl_type =>   l_llca_adj_create_tbl_type,
                p_called_from              =>   p_called_from,
                p_old_adjust_id            =>   p_old_adjust_id);

	   IF l_llca_adj_create_tbl_type(1).adjustment_id IS NULL THEN 
	      p_return_status := FND_API.G_RET_STS_ERROR;
	   ELSE
              IF PG_DEBUG in ('Y', 'C') THEN
	         p_new_adj_id := l_llca_adj_create_tbl_type(1).adjustment_id;
                 arp_util.debug('Reverse_Adjustment: ' || 
			'After Create_Adjustment , new_adjustment_id = ' || 
			p_new_adj_id || ' new_adjustment_num = ' || l_llca_adj_create_tbl_type(1).adjustment_number);
              END IF;
           END IF;

	ELSE
	   XX_AR_ADJUST_PUB.Create_Adjustment( 
	        p_api_name             =>   'XX_AR_ADJUST_PUB',
        	p_api_version          =>   1.0,
        	p_msg_count            =>   l_msg_count ,
        	p_msg_data             =>   l_msg_data,
        	p_return_status        =>   l_return_status,
        	p_adj_rec              =>   l_adj_rec,
        	p_chk_approval_limits  =>   l_chk_approval_limits,
        	p_new_adjust_number    =>   l_new_adj_num,
        	p_new_adjust_id        =>   p_new_adj_id,
	        p_check_amount         =>   l_check_amount,
                p_move_deferred_tax    =>   p_move_deferred_tax,
                p_called_from          =>   p_called_from,
                p_old_adjust_id        =>   p_old_adjust_id);



	   /* Bugfix 2734179. Check if the new adjustment record was created. */
	   IF p_new_adj_id IS NULL THEN 
	      p_return_status := FND_API.G_RET_STS_ERROR;
	   ELSE
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('Reverse_Adjustment: ' || 
			'After Create_Adjustment , new_adjustment_id = ' || 
			p_new_adj_id || ' new_adjustment_num = ' || l_new_adj_num);
              END IF;
           END IF;
	  END IF;
          
        EXCEPTION
           WHEN OTHERS THEN
             /*---------------------------------------------------+
             |  Rollback to the defined Savepoint                 |
             +---------------------------------------------------*/

             ROLLBACK TO XX_AR_ADJUST_PUB;
             p_return_status := FND_API.G_RET_STS_ERROR ;

             /*--------------------------------------------------+
             |  Get message count and if 1, return message data  |
             +---------------------------------------------------*/

             FND_MSG_PUB.Count_And_Get(
                                        p_encoded => FND_API.G_FALSE,
                                        p_count => p_msg_count,
                                        p_data  => p_msg_data
                                      );
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Reverse_Adjustment: ' || 
                'Error in Insert Entity handler. Rolling back ' ||
                'and setting status to ERROR');
             END IF;
             if (l_msg_count > 0) then
                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Reverse_Adjustment: ' || l_msg_data);
                END IF;
             end if;

             RETURN;

        END ;


       /*-------------------------------------------+
        |   ========== End of API Body ==========   |
        +-------------------------------------------*/
END IF;

       /*---------------------------------------------------+
        |  Get message count and if 1, return message data  |
        +---------------------------------------------------*/

        FND_MSG_PUB.Count_And_Get(
					p_encoded =>FND_API.G_FALSE,
                                   p_count => p_msg_count,
                                   p_data  => p_msg_data
                                 );

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit_flag )
        THEN 
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('Reverse_Adjustment: ' || 'committing');
              END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Reverse_Adjustment()- ');
        END IF;

        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select TO_CHAR( (hsecs - G_START_TIME) / 100)
           into l_hsec
           from v$timer;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Reverse_Adjustment: ' || 'Elapsed Time : '||l_hsec||' seconds');
           END IF;
        END IF;


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Reverse_Adjustment: ' || SQLCODE);
                   arp_util.debug('Reverse_Adjustment: ' || SQLERRM);
                END IF;

                ROLLBACK TO XX_AR_ADJUST_PUB;
                p_return_status := FND_API.G_RET_STS_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
					   );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Reverse_Adjustment: ' || SQLERRM);
                END IF;
                ROLLBACK TO XX_AR_ADJUST_PUB ;
                p_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
					   );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN  
                      p_return_status := FND_API.G_RET_STS_ERROR ;
                      ROLLBACK TO XX_AR_ADJUST_PUB;
                      IF PG_DEBUG in ('Y', 'C') THEN
                         arp_util.debug('Reverse_Adjustment: ' || 
                            'Completion validation error(s) occurred. ' ||
                            'Rolling back and setting status to ERROR');
                      END IF;

                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
					   );
                      RETURN;
                ELSE 
                      NULL;
                END IF;
              
         arp_util.disable_debug;

END Reverse_Adjustment;


 /*===========================================================================+
 | PROCEDURE                                                                 |
 |              Approve_Adjustment                                           |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the main routine that approves an adjustment         |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | EXETERNAL PROCEDURES/FUNCTIONS ACCESSED                                   |
 |     fnd_api.compatible_api_call                                           |
 |     fnd_api.g_exc_unexpected_error                                        |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_error                                               |
 |     fnd_api.g_ret_sts_success                                             |
 |     fnd_api.to_boolean                                                    |
 |     fnd_msg_pub.check_msg_level                                           |
 |     fnd_msg_pub.count_and_get                                             |
 |     fnd_msg_pub.initialize                                                |
 |     ar_adjustments_pkg.fetch_p                                            |
 |     ar_process_adjustment.update_approve_adjustment                       |
 |                                                                           |
 | ARGUMENTS  : IN:                                                          |
 |                   p_api_name                                              |
 |                   p_api_version                                           |
 |                   p_init_msg_list                                         |
 |                   p_commit_flag                                           |
 |                   p_validation_level                                      |
 |                   p_adj_rec                                               |
 |                   p_chk_approval_limits                                   |
 |                   p_old_adjust_id                                         |
 |              OUT:                                                         |
 |                   p_return_status                                         |
 |                   p_msg_count					     |
 |		     p_msg_data		                                     |
 |                                                                           |
 |          IN/ OUT:                                                         |
 |                                                                           |
 |                                                                           |
 | RETURNS    : NONE                                                         |
 |                                                                           |
 | NOTES                                                                     |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |    Vivek Halder   30-JAN-97  Created                                      |
 |                                                                           |
 |    Saloni Shah    03-FEB-00  Changes have been made for the BR/BOE project|
 |                              One new parameter has been added:            |
 |                                  - p_chk_approval_limits.                 |
 |                                  This parameter will be passed to         |
 |                                  Validate_Adj_Approve procedure.          |
 |                              If the value of the flag p_chk_approval_limit|
 |                              is set to 'F' then the adjusted amount will  |
 |                              not be validated against the users approval  |
 |                              limits.                                      |
 |    Satheesh Nambiar 17-May-00 Added one more parameter p_move_deferred_tax|
 |                               for BOE/BR
 |                                                                           |
 +===========================================================================*/

PROCEDURE Approve_Adjustment (
p_api_name		IN	varchar2,
p_api_version		IN	number,
p_init_msg_list		IN	varchar2 := FND_API.G_FALSE,
p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
p_validation_level     	IN	number := FND_API.G_VALID_LEVEL_FULL,
p_msg_count		OUT NOCOPY  	number,
p_msg_data		OUT NOCOPY	varchar2,
p_return_status		OUT NOCOPY	varchar2 ,
p_adj_rec		IN 	ar_adjustments%rowtype,
p_chk_approval_limits   IN      varchar2 := FND_API.G_TRUE,
p_move_deferred_tax     IN      varchar2,
p_old_adjust_id		IN	ar_adjustments.adjustment_id%type,
p_org_id              IN      NUMBER DEFAULT NULL
) IS

  l_api_name		CONSTANT VARCHAR2(20) := 'XX_AR_ADJUST_PUB';
  l_api_version         CONSTANT NUMBER       := 1.0;
  l_old_adj_rec		ar_adjustments%rowtype;		
  
  l_inp_adj_rec		ar_adjustments%rowtype; 
  l_hsec		VARCHAR2(10);
  l_status		number;
 
  l_return_status   varchar2(1)    := FND_API.G_RET_STS_SUCCESS;
  l_chk_approval_limits   varchar2(1); 
  l_org_return_status VARCHAR2(1);
  l_org_id                           NUMBER;
  
 
BEGIN
        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select hsecs
           into G_START_TIME
           from v$timer;
        END IF;

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT XX_AR_ADJUST_PUB;

       /*--------------------------------------------------+
        |   Standard call to check for call compatibility  |
        +--------------------------------------------------*/

        IF NOT FND_API.Compatible_API_Call(
                                            l_api_version,
                                            p_api_version,
                                            l_api_name,
                                            G_PKG_NAME
                                          )
        THEN
            IF PG_DEBUG in ('Y', 'C') THEN
               arp_util.debug('Approve_Adjustment: ' ||  'Compatility error occurred.');
            END IF;
            RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

       /*-------------------------------------------------------------+
       |   Initialize message list if p_init_msg_list is set to TRUE  |
       +-------------------------------------------------------------*/

        IF FND_API.to_Boolean( p_init_msg_list )
        THEN
            FND_MSG_PUB.initialize;
        END IF;

--      arp_util.enable_debug(100000);


        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Approve_Adjustment()+ ');
        END IF;

	/*-----------------------------------------+
        |   Initialize return status to SUCCESS   |
        +-----------------------------------------*/

        p_return_status := FND_API.G_RET_STS_SUCCESS;





/* SSA change */
       l_org_id            := p_org_id;
       l_org_return_status := FND_API.G_RET_STS_SUCCESS;
       ar_mo_cache_utils.set_org_context_in_api(p_org_id =>l_org_id,
                                                p_return_status =>l_org_return_status);
 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       p_return_status := FND_API.G_RET_STS_ERROR;
 ELSE


	/*---------------------------------------------+
        |   ========== Start of API Body ==========    |
        +---------------------------------------------*/


	/*---------------------------------------------+
        |   Copy the input record to local variable to |
        |   allow changes to it                        |
        +---------------------------------------------*/
	l_inp_adj_rec := p_adj_rec ;


        /*------------------------------------------------+
        |   Initialize the profile options and cache data |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Init_Context_Rec ( 
                                   p_validation_level,
                                   l_return_status  
                                 ); 
        /*------------------------------------------------+
        |   Check status and return if error              |
        +------------------------------------------------*/

        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Approve_Adjustment: ' || 'failed to Initialize the profile options ');
             END IF;
        END IF;

        /*------------------------------------------------+
        |   Cache details                                 |
        +------------------------------------------------*/
	
        ar_adjvalidate_pvt.Cache_Details ( 
                              l_return_status  
                            ); 
        /*------------------------------------------------+
        |   Check status and return if error              |
        +------------------------------------------------*/

        IF ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN
             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Approve_Adjustment: ' || 'failed to Initialize the profile options ');
             END IF;
        END IF;
            
	/*------------------------------------------------+
        |   Fetch details of the old adjustment record    |
        +------------------------------------------------*/
        BEGIN

	 arp_adjustments_pkg.fetch_p (
				       l_old_adj_rec,
                                       p_old_adjust_id
                                     );

        EXCEPTION
           WHEN OTHERS THEN
             /*---------------------------------------------------+
             |  Rollback to the defined Savepoint                 |
             +---------------------------------------------------*/

             ROLLBACK TO XX_AR_ADJUST_PUB;

             p_return_status := FND_API.G_RET_STS_ERROR ;

            FND_MESSAGE.SET_NAME ('AR', 'AR_AAPI_INVALID_ADJ_ID');
            FND_MESSAGE.SET_TOKEN ( 'ADJUSTMENT_ID',  to_char(p_old_adjust_id) ) ;
            FND_MSG_PUB.ADD ;
            RETURN;
        END ;            

	/*------------------------------------------+
        |  Validate the input details		    |
        |  Do not continue if there are errors.     |
        +------------------------------------------*/

      /*--------------------------------------------------+
       | Change for the BOE/BR project has been made      |
       | parameter p_chk_approval_limits is being passed. |
       +--------------------------------------------------*/

	l_chk_approval_limits := p_chk_approval_limits;
        IF (l_chk_approval_limits IS NULL) THEN
            l_chk_approval_limits := FND_API.G_TRUE;
        END IF;

        XX_AR_ADJUST_PUB.Validate_Adj_Approve ( 
                                           l_inp_adj_rec,
					   l_old_adj_rec,
                                           l_chk_approval_limits,
                                           l_return_status
                                         );


        IF   ( l_return_status <> FND_API.G_RET_STS_SUCCESS )
        THEN

             p_return_status := l_return_status ;
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Approve_Adjustment: ' || 
                'Validation error(s) occurred. Rolling back ' ||
		'and setting status to ERROR');
             END IF;
        END IF;

        /*-----------------------------------------------+
        |  Handling all the validation exceptions        |
        +-----------------------------------------------*/
        IF (p_return_status = FND_API.G_RET_STS_ERROR)
        THEN
             RAISE FND_API.G_EXC_ERROR;
        ELSIF (p_return_status = FND_API.G_RET_STS_UNEXP_ERROR)
           THEN
             RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
        END IF;

	/*-----------------------------------------------+
	| Call the entity Handler for Approve            |
	+-----------------------------------------------*/
	BEGIN
      /*-------------------------------------------------------+
       | Change for the BOE/BR project has been made parameter |
       | p_chk_approval_limits is being passed to the entity   | 
       | handler to indicate that check the amount_adjusted    | 
       | with the user approval limits only if                 |
       | p_chk_approval_limit flag is set to 'T'.              |
       +-------------------------------------------------------*/
	         arp_process_adjustment.update_approve_adj (
                           	'DUMMY',
                           	'1', 
  				l_inp_adj_rec,
                                l_inp_adj_rec.status,
                                p_old_adjust_id   ,
                                p_chk_approval_limits,
                                p_move_deferred_tax  
                              ) ; 

       EXCEPTION
           WHEN OTHERS THEN
             /*---------------------------------------------------+
             |  Rollback to the defined Savepoint                 |
             +---------------------------------------------------*/

             ROLLBACK TO XX_AR_ADJUST_PUB;

             p_return_status := FND_API.G_RET_STS_ERROR ;
          
             FND_MESSAGE.set_name( 'AR', 'GENERIC_MESSAGE' );
             FND_MESSAGE.set_token( 'GENERIC_TEXT', 'arp_process_adjustment.update_approve_adj exception: '||SQLERRM );
             --2920926
             FND_MSG_PUB.ADD;
             /*--------------------------------------------------+
             |  Get message count and if 1, return message data  |
             +---------------------------------------------------*/

             FND_MSG_PUB.Count_And_Get(
					p_encoded => FND_API.G_FALSE,
                                        p_count => p_msg_count,
                                        p_data  => p_msg_data
                                      );

             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('Approve_Adjustment: ' || 
                'Error in Insert Entity handler. Rolling back ' ||
		'and setting status to ERROR');
             END IF;

             RETURN;

        END ;


       /*-------------------------------------------+
        |   ========== End of API Body ==========   |
        +-------------------------------------------*/
END IF;

       /*---------------------------------------------------+
        |  Get message count and if 1, return message data  |
        +---------------------------------------------------*/

        FND_MSG_PUB.Count_And_Get(
				   p_encoded => FND_API.G_FALSE,
                                   p_count => p_msg_count,
                                   p_data  => p_msg_data
                                 );

       /*--------------------------------+
        |   Standard check of p_commit   |
        +--------------------------------*/

        IF FND_API.To_Boolean( p_commit_flag )
        THEN 
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('Approve_Adjustment: ' || 'committing');
              END IF;
              Commit;
        END IF;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('Approve_Adjustment()- ');
        END IF;

        IF (FND_MSG_PUB.Check_Msg_Level (G_MSG_LOW)) THEN
           select TO_CHAR( (hsecs - G_START_TIME) / 100)
           into l_hsec
           from v$timer;
           IF PG_DEBUG in ('Y', 'C') THEN
              arp_util.debug('Approve_Adjustment: ' || 'Elapsed Time : '||l_hsec||' seconds');
           END IF;
        END IF;


EXCEPTION
       WHEN FND_API.G_EXC_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Approve_Adjustment: ' || SQLCODE);
                   arp_util.debug('Approve_Adjustment: ' || SQLERRM);
                END IF;

                ROLLBACK TO XX_AR_ADJUST_PUB;
                p_return_status := FND_API.G_RET_STS_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );

        WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN

                IF PG_DEBUG in ('Y', 'C') THEN
                   arp_util.debug('Approve_Adjustment: ' || SQLERRM);
                END IF;
                ROLLBACK TO XX_AR_ADJUST_PUB ;
                p_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );

        WHEN OTHERS THEN

               /*-------------------------------------------------------+
                |  Handle application errors that result from trapable  |
                |  error conditions. The error messages have already    |
                |  been put on the error stack.                         |
                +-------------------------------------------------------*/

                IF (SQLCODE = -20001)
                THEN  
                      p_return_status := FND_API.G_RET_STS_ERROR ;
                      ROLLBACK TO XX_AR_ADJUST_PUB;
                      IF PG_DEBUG in ('Y', 'C') THEN
                         arp_util.debug('Approve_Adjustment: ' || 
                            'Completion validation error(s) occurred. ' ||
                            'Rolling back and setting status to ERROR');
                      END IF;

                FND_MSG_PUB.Count_And_Get( p_encoded     => FND_API.G_FALSE,
					   p_count       =>      p_msg_count,
                                           p_data        =>      p_msg_data
                                         );
                      RETURN;
                ELSE 
                      NULL;
                END IF;
              
         arp_util.disable_debug;

END Approve_Adjustment; 

   
END XX_AR_ADJUST_PUB;
/

COMMIT;
EXIT ;



