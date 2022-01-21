create or replace
PACKAGE BODY ARW_CM_COVER AS
/* $Header: ARWCMCVB.pls 120.19.12010000.4 2011/02/06 06:54:55 manishri ship $ */

G_PKG_NAME     CONSTANT  VARCHAR2(30)   := 'AR_CREDIT_TRANSACTION_PUB';
G_REV_BASED_ON_SALESREP  BOOLEAN;
G_MSG_UERROR    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR;
G_MSG_ERROR     CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_ERROR;
G_MSG_HIGH      CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_HIGH;
G_MSG_MEDIUM    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_MEDIUM;
G_MSG_LOW       CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW;
G_MSG_SUCCESS   CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_SUCCESS;

l_doc_seq_status VARCHAR2(10) := FND_API.G_RET_STS_SUCCESS;


/* bug 2527439 : patterned after get_doc_seq from ARXPRELB.pls */

PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

/*Bug3041195*/
unique_seq_numbers   VARCHAR2(1) ;


PROCEDURE get_doc_seq(p_application_id 	IN NUMBER,
                      p_document_name  	IN VARCHAR2,
                      p_sob_id         	IN NUMBER,
                      p_met_code        IN CHAR,
                      p_trx_date        IN DATE,
                      p_complete_flag	IN VARCHAR2,
                      p_doc_sequence_value IN OUT NOCOPY NUMBER,
                      p_doc_sequence_id    OUT NOCOPY NUMBER,
                      p_return_status      OUT NOCOPY VARCHAR2
                      ) AS

l_doc_seq_ret_stat   NUMBER;
l_doc_sequence_name  VARCHAR2(50);
l_doc_sequence_type  VARCHAR2(50);
l_doc_sequence_value NUMBER;
l_db_sequence_name   VARCHAR2(50);
l_seq_ass_id         NUMBER;
l_prd_tab_name       VARCHAR2(50);
l_aud_tab_name       VARCHAR2(50);
l_msg_flag           VARCHAR2(1);


BEGIN

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('get_doc_seq()+');
   END IF;

   p_return_status := FND_API.G_RET_STS_SUCCESS;


   -- valid values : A - Always Used
   --                P - partially Used
   --                N - Not used

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('get_doc_seq: ' || 'UNIQUE:SEQ : '|| unique_seq_numbers);
      arp_util.debug('get_doc_seq: ' || 'p_complete_flag : ' || p_complete_flag);
   END IF;


   IF ( NVL( unique_seq_numbers, 'N') <> 'N' ) THEN
      BEGIN

         /*------------------------------+
          |  Get the document sequence.  |
          +------------------------------*/

          l_doc_seq_ret_stat:=
                   fnd_seqnum.get_seq_info (
                                         p_application_id,
                                         p_document_name,
                                         p_sob_id,
                                         p_met_code,
                                         trunc(p_trx_date),
                                         p_doc_sequence_id,
                                         l_doc_sequence_type,
                                         l_doc_sequence_name,
                                         l_db_sequence_name,
                                         l_seq_ass_id,
                                         l_prd_tab_name,
                                         l_aud_tab_name,
                                         l_msg_flag,
                                         'Y',
                                         'Y');

         IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug('Doc sequence return status :'||to_char(nvl(l_doc_seq_ret_stat,-99)));
             arp_util.debug('l_doc_sequence_name :'||l_doc_sequence_name);
             arp_util.debug('l_db_sequence_name :'|| l_db_sequence_name);
             arp_util.debug('l_doc_sequence_type :' || l_doc_sequence_type);
             arp_util.debug('l_doc_sequence_id :'||to_char(nvl(p_doc_sequence_id,-99)));
         END IF;

         IF l_doc_seq_ret_stat = -8 THEN
             --this is the case of Always Used
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('The doc sequence does not exist for the current document');
             END IF;
             p_return_status := FND_API.G_RET_STS_ERROR;
             --Error message
             FND_MESSAGE.Set_Name( 'AR','AR_RAPI_DOC_SEQ_NOT_EXIST_A');
             FND_MSG_PUB.Add;
          ELSIF l_doc_seq_ret_stat = -2  THEN
             --this is the case of Partially Used
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug('The doc sequence does not exist for the current document');
             END IF;
             --Warning
             IF FND_MSG_PUB.Check_Msg_Level(G_MSG_SUCCESS) THEN
                FND_MESSAGE.SET_NAME('AR','AR_RAPI_DOC_SEQ_NOT_EXIST_P');
                FND_MSG_PUB.Add;
             END IF;
          END IF;

          IF ( l_doc_sequence_name IS NOT NULL
               AND p_doc_sequence_id   IS NOT NULL) THEN

             /*------------------------------------+
              |  Automatic Document Numbering case |
              +------------------------------------*/
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('Automatic Document Numbering case ');
              END IF;

              l_doc_seq_ret_stat :=
                                  fnd_seqnum.get_seq_val (
                                                       p_application_id,
                                                       p_document_name,
                                                       p_sob_id,
                                                       p_met_code,
                                                       TRUNC(p_trx_date),
                                                       l_doc_sequence_value,
                                                       p_doc_sequence_id);

              IF p_doc_sequence_value IS NOT NULL THEN
                 --raise an error message because the user is not supposed to pass
                 --in a value for the document sequence number in this case.
                 p_return_status := FND_API.G_RET_STS_ERROR;
                 FND_MESSAGE.Set_Name('AR', 'AR_RAPI_DOC_SEQ_AUTOMATIC');
                 FND_MSG_PUB.Add;
              END IF;
              p_doc_sequence_value := l_doc_sequence_value;
              arp_util.debug('l_doc_sequence_value :'||to_char(nvl(p_doc_sequence_value,-99)));
              IF PG_DEBUG in ('Y', 'C') THEN
                 arp_util.debug('p_doc_sequence_id : '|| to_char(p_doc_sequence_id));
              END IF;

          ELSIF ( p_doc_sequence_id    IS NOT NULL
                 AND p_doc_sequence_value IS NOT NULL) THEN

              /*-------------------------------------+
               |  Manual Document Numbering case     |
               |  with the document value specified. |
               |  Use the specified value.           |
               +-------------------------------------*/

               NULL;

          ELSIF ( p_doc_sequence_id    IS NOT NULL
                 AND p_doc_sequence_value IS NULL) THEN

              /*-----------------------------------------+
               |  Manual Document Numbering case         |
               |  with the document value not specified. |
               |  Generate a document value mandatory    |
               |  error.                                 |
               +-----------------------------------------*/

               IF NVL(unique_seq_numbers,'N') = 'A' THEN
                  p_return_status := FND_API.G_RET_STS_ERROR;
                  FND_MESSAGE.Set_Name('AR', 'AR_RAPI_DOC_SEQ_VALUE_NULL_A');
                  FND_MESSAGE.Set_Token('SEQUENCE', l_doc_sequence_name);
                  FND_MSG_PUB.Add;
               ELSIF NVL(unique_seq_numbers,'N') = 'P'  THEN
                  --Warning
                  IF FND_MSG_PUB.Check_Msg_Level(G_MSG_SUCCESS) THEN
                     FND_MESSAGE.SET_NAME('AR','AR_RAPI_DOC_SEQ_VALUE_NULL_P');
                     FND_MSG_PUB.Add;
                  END IF;
               END IF;


           END IF;

           EXCEPTION
           WHEN NO_DATA_FOUND THEN
              /*------------------------------------------+
               |  No document assignment was found.       |
               |  Generate an error if document numbering |
               |  is mandatory.                           |
               +------------------------------------------*/

               IF PG_DEBUG in ('Y', 'C') THEN
                  arp_util.debug('EXCEPTION: no_data_found raised');
               END IF;
               IF   (unique_seq_numbers = 'A' ) THEN
                  p_return_status := FND_API.G_RET_STS_ERROR;
                  FND_MESSAGE.Set_Name( 'FND','UNIQUE-ALWAYS USED');
                  FND_MSG_PUB.Add;
               ELSE
                  p_doc_sequence_id    := NULL;
                  p_doc_sequence_value := NULL;
               END IF;

            WHEN OTHERS THEN
               IF PG_DEBUG in ('Y', 'C') THEN
                  arp_util.debug('EXCEPTION:  Unhandled exception in doc sequence assignment');
               END IF;
               raise;

            END;

   END IF;
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('get_doc_seq()+');
   END IF;
END get_doc_seq;


/*=======================================================================+
 | PROCEDURE                                                             |
 |      create_header_cm                                                 |
 |                                                                       |
 | DESCRIPTION                                                           |
 |      Procedure create_header_cm -  Entry point for header level       |
 |                                      cm creation                      |
 | ARGUMENTS  : IN:                                                      |
 |                                                                       |
 |              OUT:                                                     |
 |          IN/ OUT:                                                     |
 |                                                                       |
 | RETURNS    :                                                          |
 |                                                                       |
 | NOTES                                                                 |
 |                                                                       |
 | KNOWN BUGS                                                            |
 |                                                                       |
 | MODIFICATION HISTORY                                                  |
 |    TDEY      22-FEB-00 Created                                        |
 |    VCRISOST  15-NOV-02 Bug 2775884 : when creating a dispute          |
 |                        at the header level and neither amount nor     |
 |                        percent is given for either line/tax/freight,  |
 |                        then code should not dispute that part of the  |
 |                        invoice                                        |
 |                                                                       |
 |                                                                       |
 +=======================================================================*/

PROCEDURE create_header_cm (
  p_prev_customer_trx_id        IN ra_customer_trx.customer_trx_id%type,
  p_batch_id                    IN ra_batches.batch_id%type,
  p_trx_date                    IN ra_customer_trx.trx_date%type,
  p_gl_date                     IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_complete_flag               IN ra_customer_trx.complete_flag%type,
  p_batch_source_id             IN ra_batch_sources.batch_source_id%type,
  p_cust_trx_type_id            IN ra_cust_trx_types.cust_trx_type_id%type,
  p_currency_code               IN fnd_currencies.currency_code%type,
  p_exchange_date               IN ra_customer_trx.exchange_date%type,
  p_exchange_rate_type          IN ra_customer_trx.exchange_rate_type%type,
  p_exchange_rate               IN ra_customer_trx.exchange_rate%type,
  p_invoicing_rule_id           IN ra_customer_trx.invoicing_rule_id%type,
  p_method_for_rules            IN ra_customer_trx.credit_method_for_rules%type,
  p_split_term_method           IN ra_customer_trx.credit_method_for_installments%type,
  p_initial_customer_trx_id     IN ra_customer_trx.initial_customer_trx_id%type,
  p_primary_salesrep_id         IN ra_customer_trx.primary_salesrep_id%type,
  p_bill_to_customer_id         IN ra_customer_trx.bill_to_customer_id%type,
  p_bill_to_address_id          IN ra_customer_trx.bill_to_address_id%type,
  p_bill_to_site_use_id         IN ra_customer_trx.bill_to_site_use_id%type,
  p_bill_to_contact_id          IN ra_customer_trx.bill_to_contact_id%type,
  p_ship_to_customer_id         IN ra_customer_trx.ship_to_customer_id%type,
  p_ship_to_address_id          IN ra_customer_trx.ship_to_address_id%type,
  p_ship_to_site_use_id         IN ra_customer_trx.ship_to_site_use_id%type,
  p_ship_to_contact_id          IN ra_customer_trx.ship_to_contact_id%type,
  p_receipt_method_id           IN ra_customer_trx.receipt_method_id%type,
  p_paying_customer_id          IN ra_customer_trx.paying_customer_id%type,
  p_paying_site_use_id          IN ra_customer_trx.paying_site_use_id%type,
  p_customer_bank_account_id    IN ra_customer_trx.customer_bank_account_id%type,
  p_printing_option             IN ra_customer_trx.printing_option%type,
  p_printing_last_printed       IN ra_customer_trx.printing_last_printed%type,
  p_printing_pending            IN ra_customer_trx.printing_pending%type,
  p_doc_sequence_value          IN ra_customer_trx.doc_sequence_value%type,
  p_doc_sequence_id             IN ra_customer_trx.doc_sequence_id%type,
  p_reason_code                 IN ra_customer_trx.reason_code%type,
  p_customer_reference          IN ra_customer_trx.customer_reference%type,
  p_customer_reference_date     IN ra_customer_trx.customer_reference_date%type,
  p_internal_notes              IN ra_customer_trx.internal_notes%type,
  p_set_of_books_id             IN ra_customer_trx.set_of_books_id%type,
  p_created_from                IN ra_customer_trx.created_from%type,
  p_old_trx_number  IN ra_customer_trx.old_trx_number%type,
  p_attribute_category          IN ra_customer_trx.attribute_category%type,
  p_attribute1                  IN ra_customer_trx.attribute1%type,
  p_attribute2                  IN ra_customer_trx.attribute2%type,
  p_attribute3                  IN ra_customer_trx.attribute3%type,
  p_attribute4                  IN ra_customer_trx.attribute4%type,
  p_attribute5                  IN ra_customer_trx.attribute5%type,
  p_attribute6                  IN ra_customer_trx.attribute6%type,
  p_attribute7                  IN ra_customer_trx.attribute7%type,
  p_attribute8                  IN ra_customer_trx.attribute8%type,
  p_attribute9                  IN ra_customer_trx.attribute9%type,
  p_attribute10                 IN ra_customer_trx.attribute10%type,
  p_attribute11                 IN ra_customer_trx.attribute11%type,
  p_attribute12                 IN ra_customer_trx.attribute12%type,
  p_attribute13                 IN ra_customer_trx.attribute13%type,
  p_attribute14                 IN ra_customer_trx.attribute14%type,
  p_attribute15                 IN ra_customer_trx.attribute15%type,
  p_interface_header_context    IN ra_customer_trx.interface_header_context%type,
  p_interface_header_attribute1 IN ra_customer_trx.interface_header_attribute1%type,
  p_interface_header_attribute2 IN ra_customer_trx.interface_header_attribute2%type,
  p_interface_header_attribute3 IN ra_customer_trx.interface_header_attribute3%type,
  p_interface_header_attribute4 IN ra_customer_trx.interface_header_attribute4%type,
  p_interface_header_attribute5 IN ra_customer_trx.interface_header_attribute5%type,
  p_interface_header_attribute6 IN ra_customer_trx.interface_header_attribute6%type,
  p_interface_header_attribute7 IN ra_customer_trx.interface_header_attribute7%type,
  p_interface_header_attribute8 IN ra_customer_trx.interface_header_attribute8%type,
  p_interface_header_attribute9  IN ra_customer_trx.interface_header_attribute9%type,
  p_interface_header_attribute10 IN ra_customer_trx.interface_header_attribute10%type,
  p_interface_header_attribute11 IN ra_customer_trx.interface_header_attribute11%type,
  p_interface_header_attribute12 IN ra_customer_trx.interface_header_attribute12%type,
  p_interface_header_attribute13 IN ra_customer_trx.interface_header_attribute13%type,
  p_interface_header_attribute14 IN ra_customer_trx.interface_header_attribute14%type,
  p_interface_header_attribute15 IN ra_customer_trx.interface_header_attribute15%type,
  p_default_ussgl_trx_code      IN ra_customer_trx.default_ussgl_transaction_code%type,
  p_line_percent                IN number,
  p_freight_percent             IN number,
  p_line_amount                 IN ra_customer_trx_lines.extended_amount%type,
  p_freight_amount              IN ra_customer_trx_lines.extended_amount%type,
  p_compute_tax                 IN varchar2,
  p_comments                    IN ra_customer_trx.comments%type,
  p_customer_trx_id            OUT NOCOPY ra_customer_trx.customer_trx_id%type,
  p_trx_number              IN OUT NOCOPY ra_customer_trx.trx_number%type,
  p_computed_tax_percent    IN OUT NOCOPY number,
  p_computed_tax_amount     IN OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_errors                     OUT NOCOPY arp_trx_validate.Message_Tbl_Type,
  p_status                     OUT NOCOPY varchar2,
  p_purchase_order              IN ra_customer_trx.purchase_order%type,
  p_purchase_order_revision     IN ra_customer_trx.purchase_order_revision%type,
  p_purchase_order_date         IN ra_customer_trx.purchase_order_date%type,
  p_legal_entity_id             IN ra_customer_trx.legal_entity_id%type ,
  /*4556000-4606558*/
  p_global_attribute_category   IN  ra_customer_trx.global_attribute_category%type default null,
  p_global_attribute1           IN  ra_customer_trx.global_attribute1%type default NULL,
  p_global_attribute2           IN  ra_customer_trx.global_attribute2%type default NULL,
  p_global_attribute3           IN  ra_customer_trx.global_attribute3%type default NULL,
  p_global_attribute4           IN  ra_customer_trx.global_attribute4%type default NULL,
  p_global_attribute5           IN  ra_customer_trx.global_attribute5%type default NULL,
  p_global_attribute6           IN  ra_customer_trx.global_attribute6%type default NULL,
  p_global_attribute7           IN  ra_customer_trx.global_attribute7%type default NULL,
  p_global_attribute8           IN  ra_customer_trx.global_attribute8%type default NULL,
  p_global_attribute9       	IN  ra_customer_trx.global_attribute9%type default NULL,
  p_global_attribute10     	IN  ra_customer_trx.global_attribute10%type default NULL,
  p_global_attribute11    	IN  ra_customer_trx.global_attribute11%type default NULL,
  p_global_attribute12          IN  ra_customer_trx.global_attribute12%type default NULL,
  p_global_attribute13          IN  ra_customer_trx.global_attribute13%type default NULL,
  p_global_attribute14 		IN  ra_customer_trx.global_attribute14%type default NULL,
  p_global_attribute15          IN  ra_customer_trx.global_attribute15%type default NULL,
  p_global_attribute16          IN ra_customer_trx.global_attribute16%type default NULL,
  p_global_attribute17         	IN ra_customer_trx.global_attribute17%type default NULL,
  p_global_attribute18        	IN ra_customer_trx.global_attribute18%type default NULL,
  p_global_attribute19       	IN ra_customer_trx.global_attribute19%type default NULL,
  p_global_attribute20      	IN ra_customer_trx.global_attribute20%type default NULL,
  p_global_attribute21     	IN ra_customer_trx.global_attribute21%type default NULL,
  p_global_attribute22    	IN ra_customer_trx.global_attribute22%type default NULL,
  p_global_attribute23          IN ra_customer_trx.global_attribute23%type default NULL,
  p_global_attribute24          IN ra_customer_trx.global_attribute24%type default NULL,
  p_global_attribute25    	IN ra_customer_trx.global_attribute25%type default NULL,
  p_global_attribute26      	IN ra_customer_trx.global_attribute26%type default NULL,
  p_global_attribute27          IN ra_customer_trx.global_attribute27%type default NULL,
  p_global_attribute28        	IN ra_customer_trx.global_attribute28%type default NULL,
  p_global_attribute29       	IN ra_customer_trx.global_attribute29%type default NULL,
  p_global_attribute30      	IN ra_customer_trx.global_attribute30%type default NULL,
  p_start_date_commitment	IN ra_customer_trx.start_date_commitment%type default NULL
  )
AS

  l_cm_header              		ra_customer_trx%rowtype;
  l_customer_trx_id        		ra_customer_trx.customer_trx_id%type;
  l_compute_tax       			VARCHAR2(1);
  l_line_orig           	      	number;
  l_tax_orig                 		number;
  l_frt_orig                 		number;
  l_tot_orig                 		number;
  l_line_bal                 		number;
  l_tax_bal                 		number;
  l_frt_bal                 		number;
  l_tot_bal                 		number;
  l_num_line_lines                 	number;
  l_num_tax_lines                 	number;
  l_num_frt_lines                 	number;
  l_num_installments                 	number;
  l_pmt_exist_flag                 	varchar2(1);
--
  l_line_amount           		ra_customer_trx_lines.extended_amount%type ;
  l_line_percent                 	number ;
  l_freight_amount               	ra_customer_trx_lines.extended_amount%type ;
  l_freight_percent              	number ;
  l_computed_tax_percent    		number;
  l_computed_tax_amount     		ra_customer_trx_lines.extended_amount%type;
  l_credited_trx_rec      		ra_customer_trx_cr_trx_v%rowtype  ;
  l_credited_trx_cm_type_id 		ra_cust_trx_types.credit_memo_type_id%TYPE ;
  l_credited_trx_open_rec_flag 		ra_cust_trx_types.accounting_affect_flag%TYPE ;
--
  l_default_bs_name              varchar2(50);
  l_auto_trx_numbering_flag      varchar2(1);
  l_bs_type                      varchar2(10);
  l_copy_doc_number_flag         varchar2(1);
  l_bs_default_cust_trx_type_id  number;
  l_default_cust_trx_type_id     number;
  l_default_type_name            varchar2(50);
  l_open_receivable_flag         varchar2(1);
  l_post_to_gl_flag              varchar2(1);
  l_allow_freight_flag           varchar2(1);
  l_creation_sign                varchar2(1);
  l_allow_overapplication_flag   varchar2(1);
  l_natural_app_only_flag        varchar2(1);
  l_tax_calculate_flag           varchar2(1);

  l_default_printing_option      varchar2(30);
  l_default_gl_date              date;
  l_default_ship_to_customer_id  number;
  l_default_ship_to_site_use_id  number;
  l_default_ship_to_contact_id   number;
  l_default_bill_to_customer_id  number;
  l_default_bill_to_site_use_id  number;
  l_default_bill_to_contact_id   number;
  l_default_primary_salesrep_id  number;

  l_default_receipt_method_id    number;
  l_default_cust_bank_account_id number;
  l_default_paying_customer_id   number;
  l_default_paying_site_use_id   number;

  l_default_ship_via             varchar2(30);
  l_default_ship_date_actual     date;
  l_default_waybill_number       varchar2(50);
  l_default_fob_point            varchar2(30);
--
  p_form_name                    varchar2(20) := 'ARXTWCMI';
  p_form_version                 number := NULL;
  l_batch_date   		 date ;
  l_crtrx_date   		 date ;
  l_sysdate      		 date ;
  e_handled_error 		 EXCEPTION;
  e_unexpected_error 		 EXCEPTION;
  l_message_name 		 VARCHAR2(255);
  l_debug_point 		 NUMBER;
  l_ue_message 			 VARCHAR2(2000);
  l_return_status      		 VARCHAR2(1);
  l_msg_data			 VARCHAR2(4000);
  l_msg_count			 NUMBER;

BEGIN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('create_header_cm()+');
   END IF;

       /*------------------------------------+
        |   Standard start of API savepoint  |
        +------------------------------------*/

        SAVEPOINT Credit_Transaction_Pub;


   --
   -- populate the record with the values passed
   --
   l_cm_header.batch_id                 := p_batch_id;
   l_cm_header.trx_number               := p_trx_number;
   l_cm_header.trx_date                 := p_trx_date;
   l_cm_header.complete_flag            := p_complete_flag;
   l_cm_header.previous_customer_trx_id := p_prev_customer_trx_id;
   l_cm_header.batch_source_id          := p_batch_source_id;
   l_cm_header.cust_trx_type_id         := p_cust_trx_type_id;
   l_cm_header.invoice_currency_code    := p_currency_code;
   l_cm_header.exchange_date            := p_exchange_date;
   l_cm_header.exchange_rate_type       := p_exchange_rate_type;
   l_cm_header.exchange_rate            := p_exchange_rate;
   l_cm_header.credit_method_for_rules  := p_method_for_rules;
   l_cm_header.credit_method_for_installments := p_split_term_method;
   l_cm_header.initial_customer_trx_id  := p_initial_customer_trx_id;
   l_cm_header.primary_salesrep_id      := p_primary_salesrep_id;
   l_cm_header.invoicing_rule_id        := p_invoicing_rule_id;
   l_cm_header.bill_to_customer_id      := p_bill_to_customer_id;
   l_cm_header.bill_to_address_id       := p_bill_to_address_id;
   l_cm_header.bill_to_site_use_id      := p_bill_to_site_use_id;
   l_cm_header.bill_to_contact_id       := p_bill_to_contact_id;
   l_cm_header.ship_to_customer_id      := p_ship_to_customer_id;
   l_cm_header.ship_to_address_id       := p_ship_to_address_id;
   l_cm_header.ship_to_site_use_id      := p_ship_to_site_use_id;
   l_cm_header.ship_to_contact_id       := p_ship_to_contact_id;
   l_cm_header.receipt_method_id        := p_receipt_method_id;
   l_cm_header.paying_customer_id       := p_paying_customer_id;
   l_cm_header.paying_site_use_id       := p_paying_site_use_id;
   l_cm_header.customer_bank_account_id := p_customer_bank_account_id;
   l_cm_header.printing_option          := p_printing_option;
   l_cm_header.printing_last_printed    := p_printing_last_printed;
   l_cm_header.printing_pending         := p_printing_pending;
   l_cm_header.reason_code              := p_reason_code;
   l_cm_header.doc_sequence_value       := p_doc_sequence_value;
   l_cm_header.doc_sequence_id          := p_doc_sequence_id;
   l_cm_header.customer_reference       := p_customer_reference;
   l_cm_header.customer_reference_date  := p_customer_reference_date;
   l_cm_header.internal_notes           := p_internal_notes;
   l_cm_header.set_of_books_id          := p_set_of_books_id;
   l_cm_header.created_from             := p_created_from;
   l_cm_header.old_trx_number           := p_old_trx_number;
   l_cm_header.attribute_category       := p_attribute_category;
   l_cm_header.attribute1               := p_attribute1;
   l_cm_header.attribute2               := p_attribute2;
   l_cm_header.attribute3               := p_attribute3;
   l_cm_header.attribute4               := p_attribute4;
   l_cm_header.attribute5               := p_attribute5;
   l_cm_header.attribute6               := p_attribute6;
   l_cm_header.attribute7               := p_attribute7;
   l_cm_header.attribute8               := p_attribute8;
   l_cm_header.attribute9               := p_attribute9;
   l_cm_header.attribute10              := p_attribute10;
   l_cm_header.attribute11              := p_attribute11;
   l_cm_header.attribute12              := p_attribute12;
   l_cm_header.attribute13              := p_attribute13;
   l_cm_header.attribute14              := p_attribute14;
   l_cm_header.attribute15              := p_attribute15;
   l_cm_header.interface_header_context       := p_interface_header_context;
   l_cm_header.interface_header_attribute1    := p_interface_header_attribute1;
   l_cm_header.interface_header_attribute2    := p_interface_header_attribute2;
   l_cm_header.interface_header_attribute3    := p_interface_header_attribute3;
   l_cm_header.interface_header_attribute4    := p_interface_header_attribute4;
   l_cm_header.interface_header_attribute5    := p_interface_header_attribute5;
   l_cm_header.interface_header_attribute6    := p_interface_header_attribute6;
   l_cm_header.interface_header_attribute7    := p_interface_header_attribute7;
   l_cm_header.interface_header_attribute8    := p_interface_header_attribute8;
   l_cm_header.interface_header_attribute9    := p_interface_header_attribute9;
   l_cm_header.interface_header_attribute10   := p_interface_header_attribute10;
   l_cm_header.interface_header_attribute11   := p_interface_header_attribute11;
   l_cm_header.interface_header_attribute12   := p_interface_header_attribute12;
   l_cm_header.interface_header_attribute13   := p_interface_header_attribute13;
   l_cm_header.interface_header_attribute14   := p_interface_header_attribute14;
   l_cm_header.interface_header_attribute15   := p_interface_header_attribute15;
   l_cm_header.default_ussgl_transaction_code :=  p_default_ussgl_trx_code;
--
   l_cm_header.status_trx := null;
--
   l_cm_header.comments := p_comments;
   l_cm_header.purchase_order :=  p_purchase_order;
   l_cm_header.purchase_order_revision :=  p_purchase_order_revision;
   l_cm_header.purchase_order_date :=  p_purchase_order_date;
   l_cm_header.legal_entity_id :=  p_legal_entity_id;

   --
   --   Ensure that p_prev_customer_trx_id is not null
   --

   --
   --   Populate Default values
   --
   --  Amounts : get the credit memo amounts.
   --            for each : line, freight, tax,
   --            if both percentage and amount are null, assume 100%
   --            populate l_cm_header values accordingly.
   --            else if either (amount or %) is null, populate the other

   BEGIN
      ARP_PROCESS_CREDIT_UTIL.GET_CREDITED_TRX_DETAILS(
                          p_prev_customer_trx_id,
                          p_initial_customer_trx_id,
                          l_line_orig,
                          l_tax_orig,
                          l_frt_orig,
                          l_tot_orig,
                          l_line_bal,
                          l_tax_bal,
                          l_frt_bal,
                          l_tot_bal,
                          l_num_line_lines,
                          l_num_tax_lines,
                          l_num_frt_lines,
                          l_num_installments,
                          l_pmt_exist_flag);
   EXCEPTION
   WHEN OTHERS THEN
       ROLLBACK TO Credit_Transaction_Pub;
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('EXCEPTION Calling arp_process_credit_util.get_credited_trx_details.');
       END IF;
       /*Bug3041195: Commented out this portion as it would overwrite errors
        raised by get_credited_trx_details*/
--       fnd_message.set_name( 'AR', 'AR_RAXTRX-1666');
--       l_message_name :=  'AR_RAXTRX-1666' ;
       RAISE e_unexpected_error;
   END;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('l_line_orig = ' || to_char(l_line_orig));
   END IF;


   -- VCRISOST 01/29/03 : bug 2775884, null amount and null percent means zero dispute

   --- TDEY 99/09/27 : need an outer IF condition for $0 invoice case
   IF nvl(l_line_orig,0) <> 0 THEN
      IF p_line_amount IS NULL THEN
         IF p_line_percent IS NULL THEN
           -- 2775884 : do not dispute line if neither line amount nor line percent is given
           l_line_amount := 0;
           l_line_percent := 0;
         ELSE
           l_line_amount := -1 * l_line_orig * p_line_percent /100 ;
           l_line_percent := p_line_percent;
         END IF;
      ELSE
         IF p_line_percent IS NULL THEN
           l_line_amount := p_line_amount;
           l_line_percent := ((p_line_amount / l_line_orig) * 100 ) ;
         ELSE
           l_line_amount := p_line_amount;
           l_line_percent := p_line_percent;
         END IF;
      END IF;
   ELSE
      l_line_amount := 0;
      l_line_percent := 0;
   END IF;

   --- TDEY 99/09/27 : need an outer IF condition for $0 freight case
   IF nvl(l_frt_orig,0) <> 0 THEN
      IF p_freight_amount IS NULL THEN
         IF p_freight_percent IS NULL THEN
           -- 2775884 : do not dispute freight, if neither freight amount nor percent is given
           l_freight_amount := 0;
           l_freight_percent := 0;
         ELSE
           l_freight_amount := -1 * l_frt_orig * p_freight_percent / 100 ;
           l_freight_percent := p_freight_percent;
         END IF;
      ELSE
         IF p_freight_percent IS NULL THEN
           l_freight_amount := p_freight_amount;
           l_freight_percent := ((p_freight_amount / l_frt_orig) * 100 * -1) ;
         ELSE
           l_freight_amount := p_freight_amount;
           l_freight_percent := p_freight_percent;
         END IF;
      END IF;
   ELSE
      l_freight_amount := 0;
      l_freight_percent := 0;
   END IF;

   --- TDEY 99/09/27 : need an outer IF condition for $0 tax case
   IF nvl(l_tax_orig,0) <> 0 THEN
      IF p_computed_tax_amount IS NULL THEN
         IF p_computed_tax_percent IS NULL THEN
           -- 2775884 : do not dispute tax, if neither tax amount nor tax percent is given
           l_computed_tax_amount := 0;
           l_computed_tax_percent := 0;
         ELSE
           l_computed_tax_amount := -1 * l_tax_orig * p_computed_tax_percent / 100;
           l_computed_tax_percent := p_computed_tax_percent;
         END IF;
      ELSE
         IF p_computed_tax_percent IS NULL THEN
           l_computed_tax_amount := p_computed_tax_amount;
           l_computed_tax_percent := ((p_computed_tax_amount / l_tax_orig) * 100 * -1) ;
         ELSE
           l_computed_tax_amount := p_computed_tax_amount;
           l_computed_tax_percent := p_computed_tax_percent;
         END IF;
      END IF;
   ELSE
    /* Bug 8627604 : For Deposits and Guarantee - p_start_date_commitment will be NOT NULL */
	IF p_start_date_commitment IS NOT NULL THEN
		l_computed_tax_amount  := NULL;
		l_computed_tax_percent := NULL;
	ELSE
		l_computed_tax_amount  := 0;
          	l_computed_tax_percent := 0;
	END IF;

   END IF;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('p_prev_customer_trx_id = ' || p_prev_customer_trx_id);
      arp_util.debug('p_start_date_commitment = ' || p_start_date_commitment );
      arp_util.debug('l_line_orig = ' || to_char(l_line_orig));
      arp_util.debug('l_line_amount = ' || to_char(l_line_amount));
      arp_util.debug('l_line_percent = ' || to_char(l_line_percent));
      arp_util.debug('l_freight_amount = ' || to_char(l_freight_amount));
      arp_util.debug('l_freight_percent = ' || to_char(l_freight_percent));
      arp_util.debug('l_computed_tax_amount = ' ||to_char(l_computed_tax_amount));
      arp_util.debug('l_computed_tax_percent = '||to_char(l_computed_tax_percent));
   END IF;

   --
   -- Default complete flag :
   -- If complete flag has not been passed in then, complete_flag is 'N'
   --
   IF p_complete_flag IS NULL THEN
      l_cm_header.complete_flag := 'N' ;
   END IF;

   --
   -- Other defaluts : use arp_process_credit_util.get_cm_header_defaults
   --
   -- First, get the details of the transaction being credited.
   -- This info is used as parameter into get_cm_header_defaults
   --
   BEGIN
      SELECT *
      INTO l_credited_trx_rec
      FROM ra_customer_trx_cr_trx_v
      WHERE customer_trx_id = p_prev_customer_trx_id  ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      --- TDEY 99/09/27 : Bug 913062
      --- Situation : The user is trying to credit a transaction that
      --- is not of the correct trx class, incomplete, or simply does
      --- not exist in the system.
      --- Proposed error message : AR_RAXTRX-1666  Your credit memo
      --- transaction can only credit an invoice or a debit memo line
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('EXCEPTION: select from ra_customer_trx_cr_trx_v returns no data');
      END IF;

      fnd_message.set_name( 'AR', 'AR_RAXTRX-1666');
      l_message_name :=  'AR_RAXTRX-1666' ;
      RAISE e_handled_error;

   WHEN OTHERS THEN
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('EXCEPTION:  Debug point 1 : Unknown Error fetching credited trx details ');
      END IF;
      l_debug_point := 1;
      l_ue_message := SUBSTR('Error fetching credited trx details ' || SQLERRM, 1, 2000);
      RAISE e_unexpected_error;
   END;


   /*
   Bug915313  : Need to catch the over appilcation case upfront
                Logic borrowed from  ARXTWCMI.pld
   Bug3041195 : Even if overapplication is allowed, you
                cannot overapply at header level
   */

   IF ( l_line_orig = 0 AND l_line_amount = 0 AND l_line_bal = 0) THEN
        NULL;
   ELSE
       IF NOT( ( ( l_line_amount + l_line_bal = 0 )
              OR ( sign(l_line_amount + l_line_bal) = sign (l_line_orig) )
                 )
             AND ( sign(l_line_amount) <> sign (l_line_orig)  )
              )
       THEN
            fnd_message.set_name('AR', 'AR_TW_CMI_HEADER_OVERAPP_NA');
            l_message_name := 'AR_TW_CMI_HEADER_OVERAPP_NA';
            RAISE e_handled_error;
        END IF;
   END IF;


   --
   -- Default trx_date
   -- Bugfix 2745276
   -- The trx date will be latest of credited transaction and sysdate
   --

   l_crtrx_date   := trunc(l_credited_trx_rec.trx_date);
   l_sysdate      := trunc(SYSDATE);

   IF (l_sysdate < l_crtrx_date) THEN
       l_cm_header.trx_date := l_crtrx_date;
   ELSE
       l_cm_header.trx_date := l_sysdate;
   END IF;

   --
   -- Default currency code
   --
   l_cm_header.invoice_currency_code := l_credited_trx_rec.invoice_currency_code;
   l_cm_header.exchange_date   := l_credited_trx_rec.exchange_date;
   l_cm_header.exchange_rate_type  := l_credited_trx_rec.exchange_rate_type;
   l_cm_header.exchange_rate := l_credited_trx_rec.exchange_rate;

   --
   -- Default created_from
   --
   IF l_cm_header.created_from IS NULL
   THEN
      l_cm_header.created_from := 'ARXTWCMI';
   END IF;

   -- Bug 2105483 : rather then calling arp_global at the start
   -- of the package, where it can error out NOCOPY since org_id is not yet set,
   -- do the call right before it is needed

   -- 5885313 commented out init routine here.
   -- arp_global.init_global;

   IF PG_DEBUG in ('Y', 'C') THEN
     arp_util.debug(' Org from arp_global is ' || arp_global.sysparam.org_id
                  || ' , SOB from arp_global is '|| arp_global.sysparam.set_of_books_id
                  || ' , SOB from trx_global is '|| arp_trx_global.system_info.system_parameters.set_of_books_id
);
   END IF;

   ARP_PROCESS_CREDIT_UTIL.GET_CM_HEADER_DEFAULTS(
                 -- bug 3796595, pass l_cm_header.trx_date instead of NULL
                 l_cm_header.trx_date, -- p_trx_date,
                 l_credited_trx_rec.customer_trx_id,
                 NULL, -- p_customer_trx_id,
                 p_batch_source_id,  -- bug 2347286, use provided BS id
                 p_gl_date, -- p_gl_date, /*Bug 9536019*/
                 NULL, -- p_currency_code,
                 NULL, -- p_cust_trx_type_id,
                 NULL, -- p_ship_to_customer_id,
                 NULL, -- p_ship_to_site_use_id,
                 NULL, -- p_ship_to_contact_id,
                 NULL, -- p_bill_to_customer_id,
                 NULL, -- p_bill_to_site_use_id,
                 NULL, -- p_bill_to_contact_id,
                 NULL, -- p_primary_salesrep_id,
                 NULL, -- p_receipt_method_id,
                 NULL, -- p_customer_bank_account_id,
                 NULL, -- p_paying_customer_id,
                 NULL, -- p_paying_site_use_id,
                 NULL, -- Name_In('TCMI_HEADER.ship_via'),
                 NULL, -- Name_In('TCMI_HEADER.fob_point'),
                 NULL, -- p_invoicing_rule_id,
                 NULL, -- Name_In('TCMI_HEADER.rev_recog_run_flag'),
                 NULL, -- p_complete_flag,
                 ARP_GLOBAL.sysparam.salesrep_required_flag, -- Name_In('AR_WORLD.salesrep_required_flag'),
                 -- credited trx info
                 l_credited_trx_rec.batch_source_id,
                 l_credited_trx_rec.bs_credit_memo_batch_source_id, -- Name_In('TCMI_CRTRX.bs_credit_memo_batch_source_id'),
                 l_credited_trx_rec.rab_batch_source_id, -- Name_In('TCMI_HEADER.rab_batch_source_id'),
                 NULL, -- Name_In('AR_WORLD.ar_ra_batch_source'),
                 l_credited_trx_rec.cust_trx_type_id,
                 l_credited_trx_rec.ctt_credit_memo_type_id, -- Name_In('TCMI_CRTRX.ctt_credit_memo_type_id'),
                 trunc(l_credited_trx_rec.gd_gl_date), -- credited invoice's gl_date
                 trunc(l_credited_trx_rec.trx_date), -- batch gl_date
                 l_credited_trx_rec.ship_to_customer_id,
                 l_credited_trx_rec.ship_to_site_use_id,
                 l_credited_trx_rec.ship_to_contact_id,
                 l_credited_trx_rec.bill_to_customer_id,
                 l_credited_trx_rec.bill_to_site_use_id,
                 l_credited_trx_rec.bill_to_contact_id,
                 l_credited_trx_rec.primary_salesrep_id,
                 l_credited_trx_rec.ctt_open_receivables_flag, -- Name_In('TCMI_CRTRX.ctt_open_receivables_flag'),
                 l_credited_trx_rec.receipt_method_id,
                 l_credited_trx_rec.customer_bank_account_id,
                 l_credited_trx_rec.ship_via, -- Name_In('TCMI_CRTRX.ship_via'),
                 l_credited_trx_rec.ship_date_actual, -- app_date.field_to_date('TCMI_CRTRX.ship_date_actual'),
                 l_credited_trx_rec.waybill_number, -- Name_In('TCMI_CRTRX.waybill_number'),
                 l_credited_trx_rec.fob_point, -- Name_In('TCMI_CRTRX.fob_point'),
--
                 l_cm_header.batch_source_id,
                 l_default_bs_name,
                 l_auto_trx_numbering_flag,
                 l_bs_type,
                 l_copy_doc_number_flag,
                 l_bs_default_cust_trx_type_id,
                 l_cm_header.cust_trx_type_id,
                 l_default_type_name,
                 l_open_receivable_flag,
                 l_post_to_gl_flag,
                 l_allow_freight_flag,
                 l_creation_sign,
                 l_allow_overapplication_flag,
                 l_natural_app_only_flag,
                 l_tax_calculate_flag,
                 l_cm_header.printing_option,
                 l_default_gl_date,
                 l_cm_header.ship_to_customer_id,
                 l_cm_header.ship_to_site_use_id,
                 l_cm_header.ship_to_contact_id,
                 l_cm_header.bill_to_customer_id,
                 l_cm_header.bill_to_site_use_id,
                 l_cm_header.bill_to_contact_id,
                 l_cm_header.primary_salesrep_id,
                 l_cm_header.receipt_method_id,
                 l_cm_header.customer_bank_account_id,
                 l_cm_header.paying_customer_id,
                 l_cm_header.paying_site_use_id,
                 l_default_ship_via,
                 l_default_ship_date_actual,
                 l_default_waybill_number,
                 l_default_fob_point);
   --
   -- However, if values have been passed in, use those
   --



   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('l_cm_header.batch_source_id = '
                    || to_char(l_cm_header.batch_source_id));
      arp_util.debug('l_cm_header.cust_trx_type_id = '
                    || to_char(l_cm_header.cust_trx_type_id));
      arp_util.debug('l_cm_header.primary_salesrep_id = '
                    || to_char(l_cm_header.primary_salesrep_id));
      arp_util.debug('l_cm_header.bill_to_customer_id = '
                    || to_char(l_cm_header.bill_to_customer_id));
      arp_util.debug('l_cm_header.bill_to_site_use_id = '
                    || to_char(l_cm_header.bill_to_site_use_id));
      arp_util.debug('l_cm_header.bill_to_contact_id = '
                    || to_char(l_cm_header.bill_to_contact_id));
      arp_util.debug('l_cm_header.ship_to_customer_id = '
                    || to_char(l_cm_header.ship_to_customer_id));
      arp_util.debug('l_cm_header.ship_to_site_use_id = '
                    || to_char(l_cm_header.ship_to_site_use_id));
      arp_util.debug('l_cm_header.ship_to_contact_id = '
                    || to_char(l_cm_header.ship_to_contact_id));
      arp_util.debug('l_cm_header.receipt_method_id = '
                    || to_char(l_cm_header.receipt_method_id));
      arp_util.debug('l_cm_header.paying_customer_id = '
                    || to_char(l_cm_header.paying_customer_id));
      arp_util.debug('l_cm_header.customer_bank_account_id = '
                    || to_char(l_cm_header.customer_bank_account_id));
      arp_util.debug('l_cm_header.printing_option = '
                    || l_cm_header.printing_option);
      arp_util.debug('l_cm_header.set_of_books_id = '
                    || to_char(l_cm_header.set_of_books_id));
      arp_util.debug('l_cm_header.legal_entity_id = '
                    || to_char(l_cm_header.legal_entity_id));
   END IF;


   --- Assign individual in parameter values to l_cm_header
   --- if not null. The transaction flexfields need to be
   --- set to the parameter values even if NULL is passed in

   IF p_cust_trx_type_id IS NOT NULL THEN
      l_cm_header.CUST_TRX_TYPE_ID := p_cust_trx_type_id ;
   ELSE
      IF l_cm_header.cust_trx_type_id IS NULL THEN
         ROLLBACK TO Credit_Transaction_Pub;
         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('Error: l_cm_header.cust_trx_type_id IS NULL');
         END IF;
         fnd_message.set_name( 'AR', 'AR_TW_BAD_DATE_TRX_TYPE');
         l_message_name :=  'AR_TW_BAD_DATE_TRX_TYPE' ;
         RAISE e_handled_error;
      END IF;
   END IF;

   IF p_batch_id IS NOT NULL THEN
      l_cm_header.batch_id                 := p_batch_id;
   END IF;
   IF p_trx_number IS NOT NULL THEN
      l_cm_header.trx_number               := p_trx_number;
   END IF;
   IF p_trx_date IS NOT NULL THEN
      l_cm_header.trx_date                 := trunc(p_trx_date);
   END IF;
   IF p_complete_flag IS NOT NULL THEN
      l_cm_header.complete_flag            := p_complete_flag;
   END IF;
   IF p_batch_source_id IS NOT NULL THEN
      l_cm_header.batch_source_id          := p_batch_source_id;
   END IF;
   IF p_currency_code IS NOT NULL THEN
      l_cm_header.invoice_currency_code    := p_currency_code;
   END IF;
   IF p_exchange_date IS NOT NULL THEN
      l_cm_header.exchange_date            := p_exchange_date;
   END IF;
   IF p_exchange_rate_type IS NOT NULL THEN
      l_cm_header.exchange_rate_type       := p_exchange_rate_type;
   END IF;
   IF p_exchange_rate IS NOT NULL THEN
      l_cm_header.exchange_rate            := p_exchange_rate;
   END IF;
   IF p_method_for_rules IS NOT NULL THEN
      l_cm_header.credit_method_for_rules  := p_method_for_rules;
   END IF;
   IF p_split_term_method IS NOT NULL THEN
      l_cm_header.credit_method_for_installments := p_split_term_method;
   END IF;
   IF p_initial_customer_trx_id IS NOT NULL THEN
      l_cm_header.initial_customer_trx_id  := p_initial_customer_trx_id;
   END IF;
   IF p_primary_salesrep_id IS NOT NULL THEN
      l_cm_header.primary_salesrep_id      := p_primary_salesrep_id;
   END IF;
   IF p_invoicing_rule_id IS NOT NULL THEN
      l_cm_header.invoicing_rule_id        := p_invoicing_rule_id;
   ELSE
      l_cm_header.invoicing_rule_id        := l_credited_trx_rec.invoicing_rule_id;
   END IF;
   IF p_bill_to_customer_id IS NOT NULL THEN
          l_cm_header.bill_to_customer_id      := p_bill_to_customer_id;
   END IF;
   IF p_bill_to_address_id IS NOT NULL THEN
          l_cm_header.bill_to_address_id       := p_bill_to_address_id;
   END IF;
   IF p_bill_to_site_use_id IS NOT NULL THEN
          l_cm_header.bill_to_site_use_id      := p_bill_to_site_use_id;
   END IF;
   IF p_bill_to_contact_id IS NOT NULL THEN
      l_cm_header.bill_to_contact_id       := p_bill_to_contact_id;
   END IF;
   IF p_ship_to_customer_id IS NOT NULL THEN
      l_cm_header.ship_to_customer_id      := p_ship_to_customer_id;
   END IF;
   IF p_ship_to_address_id IS NOT NULL THEN
      l_cm_header.ship_to_address_id       := p_ship_to_address_id;
   END IF;
   IF p_ship_to_site_use_id IS NOT NULL THEN
      l_cm_header.ship_to_site_use_id      := p_ship_to_site_use_id;
   END IF;
   IF p_ship_to_contact_id IS NOT NULL THEN
      l_cm_header.ship_to_contact_id       := p_ship_to_contact_id;
   END IF;
   IF p_receipt_method_id IS NOT NULL THEN
      l_cm_header.receipt_method_id        := p_receipt_method_id;
   END IF;
   IF p_paying_customer_id IS NOT NULL THEN
      l_cm_header.paying_customer_id       := p_paying_customer_id;
   END IF;
   IF p_paying_site_use_id IS NOT NULL THEN
      l_cm_header.paying_site_use_id       := p_paying_site_use_id;
   END IF;
   IF p_customer_bank_account_id IS NOT NULL THEN
      l_cm_header.customer_bank_account_id := p_customer_bank_account_id;
   END IF;
   IF p_printing_option IS NOT NULL THEN
      l_cm_header.printing_option          := p_printing_option;
   END IF;
   IF p_printing_last_printed IS NOT NULL THEN
      l_cm_header.printing_last_printed    := p_printing_last_printed;
   END IF;
   IF p_printing_pending IS NOT NULL THEN
      l_cm_header.printing_pending         := p_printing_pending;
   END IF;
   IF p_reason_code IS NOT NULL THEN
      l_cm_header.reason_code              := p_reason_code;
   END IF;
   IF p_doc_sequence_value IS NOT NULL THEN
      l_cm_header.doc_sequence_value       := p_doc_sequence_value;
   END IF;
   IF p_doc_sequence_id IS NOT NULL THEN
      l_cm_header.doc_sequence_id          := p_doc_sequence_id;
   END IF;
   IF p_customer_reference IS NOT NULL THEN
      l_cm_header.customer_reference       := p_customer_reference;
   END IF;
   IF p_customer_reference_date IS NOT NULL THEN
      l_cm_header.customer_reference_date  := p_customer_reference_date;
   END IF;
   IF p_internal_notes IS NOT NULL THEN
      l_cm_header.internal_notes           := p_internal_notes;
   END IF;
   IF p_set_of_books_id IS NOT NULL THEN
      l_cm_header.set_of_books_id          := p_set_of_books_id;
   END IF;
   IF p_old_trx_number IS NOT NULL THEN
      l_cm_header.old_trx_number           := p_old_trx_number;
   END IF;
   IF p_attribute_category IS NOT NULL THEN
      l_cm_header.attribute_category       := p_attribute_category;
   END IF;
   IF p_attribute1 IS NOT NULL THEN
      l_cm_header.attribute1               := p_attribute1;
   END IF;
   IF p_attribute2 IS NOT NULL THEN
      l_cm_header.attribute2               := p_attribute2;
   END IF;
   IF p_attribute3 IS NOT NULL THEN
      l_cm_header.attribute3               := p_attribute3;
   END IF;
   IF p_attribute4 IS NOT NULL THEN
      l_cm_header.attribute4               := p_attribute4;
   END IF;
   IF p_attribute5 IS NOT NULL THEN
      l_cm_header.attribute5               := p_attribute5;
   END IF;
   IF p_attribute6 IS NOT NULL THEN
      l_cm_header.attribute6               := p_attribute6;
   END IF;
   IF p_attribute7 IS NOT NULL THEN
      l_cm_header.attribute7               := p_attribute7;
   END IF;
   IF p_attribute8 IS NOT NULL THEN
      l_cm_header.attribute8               := p_attribute8;
   END IF;
   IF p_attribute9 IS NOT NULL THEN
      l_cm_header.attribute9               := p_attribute9;
   END IF;
   IF p_attribute10 IS NOT NULL THEN
      l_cm_header.attribute10              := p_attribute10;
   END IF;
   IF p_attribute11 IS NOT NULL THEN
      l_cm_header.attribute11              := p_attribute11;
   END IF;
   IF p_attribute12 IS NOT NULL THEN
      l_cm_header.attribute12              := p_attribute12;
   END IF;
   IF p_attribute13 IS NOT NULL THEN
      l_cm_header.attribute13              := p_attribute13;
   END IF;
   IF p_attribute14 IS NOT NULL THEN
      l_cm_header.attribute14              := p_attribute14;
   END IF;
   IF p_attribute15 IS NOT NULL THEN
      l_cm_header.attribute15              := p_attribute15;
   END IF;

   l_cm_header.interface_header_context       := p_interface_header_context;
   l_cm_header.interface_header_attribute1    := p_interface_header_attribute1;
   l_cm_header.interface_header_attribute2    := p_interface_header_attribute2;
   l_cm_header.interface_header_attribute3    := p_interface_header_attribute3;
   l_cm_header.interface_header_attribute4    := p_interface_header_attribute4;
   l_cm_header.interface_header_attribute5    := p_interface_header_attribute5;
   l_cm_header.interface_header_attribute6    := p_interface_header_attribute6;
   l_cm_header.interface_header_attribute7    := p_interface_header_attribute7;
   l_cm_header.interface_header_attribute8    := p_interface_header_attribute8;
   l_cm_header.interface_header_attribute9    := p_interface_header_attribute9;
   l_cm_header.interface_header_attribute10   := p_interface_header_attribute10;
   l_cm_header.interface_header_attribute11   := p_interface_header_attribute11;
   l_cm_header.interface_header_attribute12   := p_interface_header_attribute12;
   l_cm_header.interface_header_attribute13   := p_interface_header_attribute13;
   l_cm_header.interface_header_attribute14   := p_interface_header_attribute14;
   l_cm_header.interface_header_attribute15   := p_interface_header_attribute15;
   /*4556000-4606558*/
   l_cm_header.global_attribute_category      := p_global_attribute_category;
   l_cm_header.global_attribute1    	      := p_global_attribute1;
   l_cm_header.global_attribute2    	      := p_global_attribute2;
   l_cm_header.global_attribute3	      := p_global_attribute3;
   l_cm_header.global_attribute4    	      := p_global_attribute4;
   l_cm_header.global_attribute5    	      := p_global_attribute5;
   l_cm_header.global_attribute6	      := p_global_attribute6;
   l_cm_header.global_attribute7    	      := p_global_attribute7;
   l_cm_header.global_attribute8              := p_global_attribute8;
   l_cm_header.global_attribute9    	      := p_global_attribute9;
   l_cm_header.global_attribute10    	      := p_global_attribute10;
   l_cm_header.global_attribute11    	      := p_global_attribute11;
   l_cm_header.global_attribute12    	      := p_global_attribute12;
   l_cm_header.global_attribute13    	      := p_global_attribute13;
   l_cm_header.global_attribute14    	      := p_global_attribute14;
   l_cm_header.global_attribute15    	      := p_global_attribute15;
   l_cm_header.global_attribute16    	      := p_global_attribute16;
   l_cm_header.global_attribute17    	      := p_global_attribute17;
   l_cm_header.global_attribute18	      := p_global_attribute18;
   l_cm_header.global_attribute19    	      := p_global_attribute19;
   l_cm_header.global_attribute20    	      := p_global_attribute20;
   l_cm_header.global_attribute21	      := p_global_attribute21;
   l_cm_header.global_attribute22    	      := p_global_attribute22;
   l_cm_header.global_attribute23    	      := p_global_attribute23;
   l_cm_header.global_attribute24    	      := p_global_attribute24;
   l_cm_header.global_attribute25    	      := p_global_attribute25;
   l_cm_header.global_attribute26    	      := p_global_attribute26;
   l_cm_header.global_attribute27    	      := p_global_attribute27;
   l_cm_header.global_attribute28    	      := p_global_attribute28;
   l_cm_header.global_attribute29    	      := p_global_attribute29;
   l_cm_header.global_attribute30    	      := p_global_attribute30;
   IF p_default_ussgl_trx_code IS NOT NULL THEN
      l_cm_header.default_ussgl_transaction_code :=  p_default_ussgl_trx_code;
   END IF;
   IF p_comments IS NOT NULL THEN
      l_cm_header.comments := p_comments;
   END IF;

   --
   -- default gl_date
   --

   IF p_gl_date IS NOT NULL THEN
      l_default_gl_date := p_gl_date;
   END IF;

   /* Bug 3152685 Setting the l_compute_tax to the value of the
    parameter passed in which is N , for Header level credits. */

   l_compute_tax := p_compute_tax;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('l_compute_tax = ' || l_compute_tax);
   END IF;

   --
   -- call the entity handler
   --

   BEGIN
      ARP_PROCESS_CREDIT.INSERT_HEADER(
                             p_form_name,
                             1.0,
                             l_cm_header,
                             'CM',
                             l_default_gl_date,
                             -- p_primary_salesrep_id,
                             l_cm_header.primary_salesrep_id,
                             l_cm_header.invoice_currency_code, -- p_currency_code,
                             p_prev_customer_trx_id,
                             p_line_percent,
                             p_freight_percent,
                             l_line_amount,
                             l_freight_amount,
                             l_compute_tax,
                             p_trx_number,
                             l_customer_trx_id,
                             l_computed_tax_percent,
                             l_computed_tax_amount,
                             p_status);
      l_computed_tax_percent := l_computed_tax_percent;
      p_computed_tax_amount := l_computed_tax_amount;

   EXCEPTION
   WHEN OTHERS THEN
       ROLLBACK TO Credit_Transaction_Pub;
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('EXCEPTION:  Debug point 2 : Error Calling arp_process_credit.insert_header.');
       END IF;
       l_debug_point := 2;
       l_ue_message := SUBSTR('EXCEPTION: Error Calling arp_process_credit.insert_header '
                         || SQLERRM, 1, 2000);
       RAISE e_unexpected_error;
   END ;

   /* R12 eTax uptake - call to calculate_tax to create tax lines */

   ARP_ETAX_SERVICES_PKG.Calculate_tax (
                   p_customer_trx_id => l_customer_trx_id,
                   p_action => 		'CREATE',
                   x_return_status => 	l_return_status,
                   x_msg_count =>  	l_msg_count,
                   x_msg_data =>    	l_msg_data);

   IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      p_status := 'ETAX_ERROR';
   END IF;

   /*
   TDEY 99/09/21 : bug 983278 : Need Post commit logic !!!

   Bug3041195: Changed the parameters passed to post_commit. We need to pass
   the value for the credited trx invoice type for - overapplication flag;
   natural application flag and previous open receivables flag

   */

   BEGIN
      arp_process_header.post_commit(
                 p_form_name => p_form_name
                ,p_form_version => 70.1
                ,p_customer_trx_id => l_customer_trx_id
                ,p_previous_customer_trx_id => p_prev_customer_trx_id
                ,p_complete_flag => l_cm_header.complete_flag
                ,p_trx_open_receivables_flag  =>  l_open_receivable_flag
                ,p_prev_open_receivables_flag  => l_credited_trx_rec.ctt_open_receivables_flag
                ,p_creation_sign  => l_creation_sign
                ,p_allow_overapplication_flag  => l_credited_trx_rec.ctt_allow_overapp_flag
                ,p_natural_application_flag  => l_credited_trx_rec.ctt_natural_app_only_flag
                ,p_cash_receipt_id  => NULL
                   );
   EXCEPTION
   WHEN OTHERS THEN
       ROLLBACK TO Credit_Transaction_Pub;
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('EXCEPTION: Debug point 3 : Error Calling arp_process_header.post_commit.');
       END IF;
       l_debug_point := 3;
       l_ue_message := SUBSTR('Error Calling arp_process_header.post_commit '
                         || SQLERRM, 1, 2000);
       RAISE e_unexpected_error;
   END ;

   /*
       Bug 2527439 : check if doc sequence is required/used
       Bug 3041195 : 1. ra_customer_trx_table was not getting updated with the
                     doc seq no/value when copy_doc_number_flag = 'N'. Modified
                     if ..else clause.
                     2. Document sequence Nos were getting lost if errors were
                     encountered during completion checking. Re-arranged the
                     code to generate nos only if no errors were encountered.
  */


   BEGIN
      get_doc_seq(222,
                  l_default_type_name,
                  arp_global.set_of_books_id,
                  'A',
                  l_cm_header.trx_date,
                  l_cm_header.complete_flag,
                  l_cm_header.doc_sequence_value,
                  l_cm_header.doc_sequence_id,
                  l_doc_seq_status);

     IF l_doc_seq_status = FND_API.G_RET_STS_ERROR THEN
         RAISE e_unexpected_error;
     END IF;


     IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug('create_header_cm: ' || 'l_copy_doc_number_flag = ' || l_copy_doc_number_flag);
            arp_util.debug('create_header_cm: ' || 'doc_sequence_value = ' || to_char(l_cm_header.doc_sequence_value));
            arp_util.debug('create_header_cm: ' || 'doc_sequence_id = ' || to_char(l_cm_header.doc_sequence_id));
     END IF;

    -- check copy_doc_number_flag
    IF l_cm_header.doc_sequence_value is not null THEN

       IF ( NVL(l_copy_doc_number_flag,'N') = 'Y' ) THEN
            l_cm_header.old_trx_number := p_trx_number;
            l_cm_header.trx_number     := to_char(l_cm_header.doc_sequence_value);

            UPDATE ar_payment_schedules
              SET trx_number = l_cm_header.trx_number
              WHERE customer_trx_id = l_customer_trx_id;
       ELSE
            l_cm_header.trx_number     := p_trx_number;
       END IF;

       UPDATE ra_customer_trx
       SET   doc_sequence_value = l_cm_header.doc_sequence_value,
             doc_sequence_id    = l_cm_header.doc_sequence_id,
             trx_number         = l_cm_header.trx_number,
             old_trx_number     = l_cm_header.old_trx_number
       WHERE customer_trx_id    = l_customer_trx_id;

   END IF;


   EXCEPTION
   WHEN OTHERS THEN
       ROLLBACK TO Credit_Transaction_Pub;
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug('create_header_cm: ' || 'Debug point 4 : Error Processing Doc Seq No.');
       END IF;
       l_debug_point := 4;
       l_ue_message := SUBSTR(' Error Processing Doc Seq No ' || SQLERRM, 1, 2000);
       RAISE e_unexpected_error;
   END ;

   p_customer_trx_id := l_customer_trx_id;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('create_header_cm: ' ||  'p_customer_trx_id = ' || to_char(p_customer_trx_id));
      arp_util.debug('create_header_cm: ' ||  'p_trx_number = ' || p_trx_number);
      arp_util.debug('create_header_cm: ' ||  'l_compute_tax = ' || l_compute_tax);
      arp_util.debug('create_header_cm: ' ||  'p_computed_tax_percent = ' || to_char(p_computed_tax_percent));
      arp_util.debug('create_header_cm: ' ||  'p_computed_tax_amount = ' || to_char(p_computed_tax_amount));
      arp_util.debug('create_header_cm: ' ||  'p_status = ' || p_status);
      arp_util.debug('create_header_cm()-');
   END IF;

EXCEPTION
  -- bug 2290738 : populate error table with message and pass value to p_status

  WHEN e_handled_error THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION WHEN e_handled_error : create_header_cm');
        END IF;
        p_status := 'e_handled_error';

        ROLLBACK TO Credit_Transaction_Pub;
        p_errors(1).customer_trx_id     := p_prev_customer_trx_id;
        p_errors(1).message_name        := l_message_name;
        p_errors(1).translated_message  := fnd_message.get;

        fnd_message.set_name( 'AR', l_message_name);
        FND_MSG_PUB.Add;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('create_header_cm: ' || 'p_errors(1).message_name = '
                     || p_errors(1).message_name);
           arp_util.debug('create_header_cm: ' || 'p_errors(1).encoded_message = '
                     || p_errors(1).encoded_message);
           arp_util.debug('create_header_cm: ' || 'p_errors(1).translated_message = '
                     || p_errors(1).translated_message);
        END IF;

  WHEN e_unexpected_error THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION WHEN e_unexpected_error : create_header_cm');
        END IF;
        p_status := 'e_unexpected_error';

        ROLLBACK TO Credit_Transaction_Pub;
        p_errors(1).customer_trx_id     := p_prev_customer_trx_id;
        p_errors(1).encoded_message     := fnd_message.get_encoded;
        fnd_message.set_encoded(p_errors(1).encoded_message);
        p_errors(1).translated_message  := fnd_message.get;

        IF p_errors(1).translated_message IS NULL
        THEN
            p_errors(1).message_name        := 'GENERIC_MESSAGE';
            p_errors(1).token_name_1        := 'GENERIC_TEXT';
            p_errors(1).token_1             :=  NVL(l_ue_message, 'CREATE_HEADER_CM : UNEXPECTED ERROR') ;

            fnd_message.set_name('AR','GENERIC_MESSAGE');
            fnd_message.set_token('GENERIC_TEXT', p_errors(1).token_1 );
            FND_MSG_PUB.Add;

            p_errors(1).translated_message     := fnd_message.get;
        ELSE
            /*Bug3041195 - Set Message on API stack */
            fnd_message.set_encoded(p_errors(1).encoded_message);
            FND_MSG_PUB.Add;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('create_header_cm: ' || 'p_errors(1).message_name = '
                     || p_errors(1).message_name);
           arp_util.debug('create_header_cm: ' || 'p_errors(1).encoded_message = '
                     || p_errors(1).encoded_message);
           arp_util.debug('create_header_cm: ' || 'p_errors(1).translated_message = '
                     || p_errors(1).translated_message);
        END IF;

  WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION WHEN OTHERS : create_header_cm');
        END IF;
        p_status := 'others';

        ROLLBACK TO Credit_Transaction_Pub;
        p_errors(1).customer_trx_id     := p_prev_customer_trx_id;
        p_errors(1).message_name        := 'GENERIC_MESSAGE';
        p_errors(1).token_name_1        := 'GENERIC_TEXT';
        p_errors(1).token_1             := 'CREATE_HEADER_CM : ERROR AT UNKNOWN POINT '|| SQLERRM ;

        fnd_message.set_name('AR','GENERIC_MESSAGE');
        fnd_message.set_token('GENERIC_TEXT', p_errors(1).token_1 );
        FND_MSG_PUB.Add;

        p_errors(1).translated_message     := fnd_message.get;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('create_header_cm: ' || 'p_errors(1).message_name = '
                     || p_errors(1).message_name);
           arp_util.debug('create_header_cm: ' || 'p_errors(1).encoded_message = '
                     || p_errors(1).encoded_message);
           arp_util.debug('create_header_cm: ' || 'p_errors(1).translated_message = '
                     || p_errors(1).translated_message);
       arp_util.debug('create_header_cm: ' || 'EXCEPTION WHEN OTHERS : credit_transaction');
    END IF;
END create_header_cm;

 /*======================================================+
  |  The following procedure is for line level credit  |
  +======================================================*/

/*=======================================================================+
 | PROCEDURE                                                             |
 |      create_line_cm                                               |
 |                                                                       |
 | DESCRIPTION                                                           |
 |      Procedure create_line_cm -  Entry point for line level       |
 |                                      cm creation                      |
 | ARGUMENTS  : IN:                                                      |
 |                                                                       |
 |              OUT:                                                     |
 |          IN/ OUT:                                                     |
 |                                                                       |
 | RETURNS    :                                                          |
 |                                                                       |
 | NOTES                                                                 |
 |                                                                       |
 | KNOWN BUGS                                                            |
 |                                                                       |
 | MODIFICATION HISTORY                                                  |
 |    TDEY     22-FEB-00 Created                                         |
 |    MRAYMOND 21-JAN-09 Modified use of p_compute_tax flag for line
 |                       level credits to calculate or not based on
 |                       passed value.
 +=======================================================================*/

PROCEDURE create_line_cm (
  p_prev_customer_trx_id        IN ra_customer_trx.customer_trx_id%type,
  p_batch_id                    IN ra_batches.batch_id%type,
  p_trx_date                    IN ra_customer_trx.trx_date%type,
  p_gl_date                     IN ra_cust_trx_line_gl_dist.gl_date%type,
  p_complete_flag               IN ra_customer_trx.complete_flag%type,
  p_batch_source_id             IN ra_batch_sources.batch_source_id%type,
  p_cust_trx_type_id            IN ra_cust_trx_types.cust_trx_type_id%type,
  p_currency_code               IN fnd_currencies.currency_code%type,
  p_exchange_date               IN ra_customer_trx.exchange_date%type,
  p_exchange_rate_type          IN ra_customer_trx.exchange_rate_type%type,
  p_exchange_rate               IN ra_customer_trx.exchange_rate%type,
  p_invoicing_rule_id           IN ra_customer_trx.invoicing_rule_id%type,
  p_method_for_rules            IN ra_customer_trx.credit_method_for_rules%type,
  p_split_term_method           IN ra_customer_trx.credit_method_for_installments%type,
  p_initial_customer_trx_id     IN ra_customer_trx.initial_customer_trx_id%type,
  p_primary_salesrep_id         IN ra_customer_trx.primary_salesrep_id%type,
  p_bill_to_customer_id         IN ra_customer_trx.bill_to_customer_id%type,
  p_bill_to_address_id          IN ra_customer_trx.bill_to_address_id%type,
  p_bill_to_site_use_id         IN ra_customer_trx.bill_to_site_use_id%type,
  p_bill_to_contact_id          IN ra_customer_trx.bill_to_contact_id%type,
  p_ship_to_customer_id         IN ra_customer_trx.ship_to_customer_id%type,
  p_ship_to_address_id          IN ra_customer_trx.ship_to_address_id%type,
  p_ship_to_site_use_id         IN ra_customer_trx.ship_to_site_use_id%type,
  p_ship_to_contact_id          IN ra_customer_trx.ship_to_contact_id%type,
  p_receipt_method_id           IN ra_customer_trx.receipt_method_id%type,
  p_paying_customer_id          IN ra_customer_trx.paying_customer_id%type,
  p_paying_site_use_id          IN ra_customer_trx.paying_site_use_id%type,
  p_customer_bank_account_id    IN ra_customer_trx.customer_bank_account_id%type,
  p_printing_option             IN ra_customer_trx.printing_option%type,
  p_printing_last_printed       IN ra_customer_trx.printing_last_printed%type,
  p_printing_pending            IN ra_customer_trx.printing_pending%type,
  p_doc_sequence_value          IN ra_customer_trx.doc_sequence_value%type,
  p_doc_sequence_id             IN ra_customer_trx.doc_sequence_id%type,
  p_reason_code                 IN ra_customer_trx.reason_code%type,
  p_customer_reference          IN ra_customer_trx.customer_reference%type,
  p_customer_reference_date     IN ra_customer_trx.customer_reference_date%type,
  p_internal_notes              IN ra_customer_trx.internal_notes%type,
  p_set_of_books_id             IN ra_customer_trx.set_of_books_id%type,
  p_created_from                IN ra_customer_trx.created_from%type,
  p_old_trx_number  IN ra_customer_trx.old_trx_number%type,
  p_attribute_category          IN ra_customer_trx.attribute_category%type,
  p_attribute1                  IN ra_customer_trx.attribute1%type,
  p_attribute2                  IN ra_customer_trx.attribute2%type,
  p_attribute3                  IN ra_customer_trx.attribute3%type,
  p_attribute4                  IN ra_customer_trx.attribute4%type,
  p_attribute5                  IN ra_customer_trx.attribute5%type,
  p_attribute6                  IN ra_customer_trx.attribute6%type,
  p_attribute7                  IN ra_customer_trx.attribute7%type,
  p_attribute8                  IN ra_customer_trx.attribute8%type,
  p_attribute9                  IN ra_customer_trx.attribute9%type,
  p_attribute10                 IN ra_customer_trx.attribute10%type,
  p_attribute11                 IN ra_customer_trx.attribute11%type,
  p_attribute12                 IN ra_customer_trx.attribute12%type,
  p_attribute13                 IN ra_customer_trx.attribute13%type,
  p_attribute14                 IN ra_customer_trx.attribute14%type,
  p_attribute15                 IN ra_customer_trx.attribute15%type,
  p_interface_header_context    IN ra_customer_trx.interface_header_context%type,
  p_interface_header_attribute1 IN ra_customer_trx.interface_header_attribute1%type,
  p_interface_header_attribute2 IN ra_customer_trx.interface_header_attribute2%type,
  p_interface_header_attribute3 IN ra_customer_trx.interface_header_attribute3%type,
  p_interface_header_attribute4 IN ra_customer_trx.interface_header_attribute4%type,
  p_interface_header_attribute5 IN ra_customer_trx.interface_header_attribute5%type,
  p_interface_header_attribute6 IN ra_customer_trx.interface_header_attribute6%type,
  p_interface_header_attribute7 IN ra_customer_trx.interface_header_attribute7%type,
  p_interface_header_attribute8 IN ra_customer_trx.interface_header_attribute8%type,
  p_interface_header_attribute9     IN ra_customer_trx.interface_header_attribute9%type,
  p_interface_header_attribute10    IN ra_customer_trx.interface_header_attribute10%type,
  p_interface_header_attribute11    IN ra_customer_trx.interface_header_attribute11%type,
  p_interface_header_attribute12    IN ra_customer_trx.interface_header_attribute12%type,
  p_interface_header_attribute13    IN ra_customer_trx.interface_header_attribute13%type,
  p_interface_header_attribute14    IN ra_customer_trx.interface_header_attribute14%type,
  p_interface_header_attribute15    IN ra_customer_trx.interface_header_attribute15%type,
  p_default_ussgl_trx_code      IN ra_customer_trx.default_ussgl_transaction_code%type,
  p_line_percent                IN number,
  p_freight_percent             IN number,
  p_line_amount                 IN ra_customer_trx_lines.extended_amount%type,
  p_freight_amount              IN ra_customer_trx_lines.extended_amount%type,
  p_compute_tax                 IN varchar2,
  p_comments                    IN ra_customer_trx.comments%type,
  p_customer_trx_id            OUT NOCOPY ra_customer_trx.customer_trx_id%type,
  p_trx_number              IN OUT NOCOPY ra_customer_trx.trx_number%type,
  p_computed_tax_percent    IN OUT NOCOPY number,
  p_computed_tax_amount     IN OUT NOCOPY ra_customer_trx_lines.extended_amount%type,
  p_errors                     OUT NOCOPY arp_trx_validate.Message_Tbl_Type,
  p_status                     OUT NOCOPY varchar2,
  p_credit_line_table           IN arw_cm_cover.credit_lines_table_type,
  p_purchase_order              IN ra_customer_trx.purchase_order%type,
  p_purchase_order_revision     IN ra_customer_trx.purchase_order_revision%type,
  p_purchase_order_date         IN ra_customer_trx.purchase_order_date%type,
  p_legal_entity_id             IN ra_customer_trx.legal_entity_id%type ,
  /*4556000-4606558*/
  p_global_attribute_category   IN  ra_customer_trx.global_attribute_category%type default null,
  p_global_attribute1           IN  ra_customer_trx.global_attribute1%type default NULL,
  p_global_attribute2           IN  ra_customer_trx.global_attribute2%type default NULL,
  p_global_attribute3           IN  ra_customer_trx.global_attribute3%type default NULL,
  p_global_attribute4           IN  ra_customer_trx.global_attribute4%type default NULL,
  p_global_attribute5           IN  ra_customer_trx.global_attribute5%type default NULL,
  p_global_attribute6           IN  ra_customer_trx.global_attribute6%type default NULL,
  p_global_attribute7           IN  ra_customer_trx.global_attribute7%type default NULL,
  p_global_attribute8           IN  ra_customer_trx.global_attribute8%type default NULL,
  p_global_attribute9       	IN  ra_customer_trx.global_attribute9%type default NULL,
  p_global_attribute10     	IN  ra_customer_trx.global_attribute10%type default NULL,
  p_global_attribute11    	IN  ra_customer_trx.global_attribute11%type default NULL,
  p_global_attribute12          IN  ra_customer_trx.global_attribute12%type default NULL,
  p_global_attribute13          IN  ra_customer_trx.global_attribute13%type default NULL,
  p_global_attribute14 		IN  ra_customer_trx.global_attribute14%type default NULL,
  p_global_attribute15          IN  ra_customer_trx.global_attribute15%type default NULL,
  p_global_attribute16          IN ra_customer_trx.global_attribute16%type default NULL,
  p_global_attribute17         	IN ra_customer_trx.global_attribute17%type default NULL,
  p_global_attribute18        	IN ra_customer_trx.global_attribute18%type default NULL,
  p_global_attribute19       	IN ra_customer_trx.global_attribute19%type default NULL,
  p_global_attribute20      	IN ra_customer_trx.global_attribute20%type default NULL,
  p_global_attribute21     	IN ra_customer_trx.global_attribute21%type default NULL,
  p_global_attribute22    	IN ra_customer_trx.global_attribute22%type default NULL,
  p_global_attribute23          IN ra_customer_trx.global_attribute23%type default NULL,
  p_global_attribute24          IN ra_customer_trx.global_attribute24%type default NULL,
  p_global_attribute25    	IN ra_customer_trx.global_attribute25%type default NULL,
  p_global_attribute26      	IN ra_customer_trx.global_attribute26%type default NULL,
  p_global_attribute27          IN ra_customer_trx.global_attribute27%type default NULL,
  p_global_attribute28        	IN ra_customer_trx.global_attribute28%type default NULL,
  p_global_attribute29       	IN ra_customer_trx.global_attribute29%type default NULL,
  p_global_attribute30      	IN ra_customer_trx.global_attribute30%type default NULL
)
AS

--
  p_do_tax                    VARCHAR2(1)  := 'N';
  p_do_freight                VARCHAR2(1)  := 'N';
  p_do_salescredits           VARCHAR2(1)  := 'N';
  p_do_autoaccounting         VARCHAR2(1)  := 'N';
  p_commit                    VARCHAR2(1)  := FND_API.G_TRUE;
  l_compute_tax               VARCHAR2(1);
  l_customer_trx_id           ra_customer_trx.customer_trx_id%type;
  l_temp                      varchar2(30);
  l_start_time                varchar2(100);
  l_header_time               varchar2(100);
  l_line_time                 varchar2(100);
  l_update_time               varchar2(100);
  l_start                     date;
  l_end                       date;
  l_time                      number := 0;
  l_start_hsec                number := 0;
  l_min_time                  number := 99999999999;
  l_max_time                  number := 0;
  l_elapsed_time              number := 0;
  l_commitment_rec            arp_process_commitment.commitment_rec_type;
  l_return_status             varchar2(1);
  l_msg_count                 NUMBER;
  l_msg_data                  varchar2(4000);
  l_errors                    arp_trx_validate.Message_Tbl_Type;
  l_new_customer_trx_id       ra_customer_trx.customer_trx_id%type;
  l_cursor                    INTEGER;
  i                           BINARY_INTEGER := 0;
  n                           BINARY_INTEGER := 0;
  l_ignore                    INTEGER;
  l_sql                       VARCHAR2(1000);
  l_class             	      ra_cust_trx_types.type%TYPE ;
  l_commitment_gl_date	      ra_cust_trx_line_gl_dist.gl_date%type ;
  l_prev_trx_gl_date	      ra_cust_trx_line_gl_dist.gl_date%type ;


  l_rec_gl_date               ra_cust_trx_line_gl_dist.gl_date%type;
  l_trx_rec                   ra_customer_trx_cr_trx_v%rowtype;
  l_batch_rec                 ra_batches%rowtype;

  l_cr           	      CONSTANT char(1)        := '
';
  j 			      number;

  ct_customer_trx_line_id     ra_customer_trx_lines.customer_trx_line_id%TYPE;
  ct_quantity_invoiced        ra_customer_trx_lines.quantity_invoiced%TYPE;
  ct_extended_amount          ra_customer_trx_lines.extended_amount%TYPE;
----
  l_dist_index                NUMBER ;
  l_lines_index               NUMBER ;
  l_credit_memo_type_id       ra_cust_trx_types.credit_memo_type_id%type;
  l_line_matched              NUMBER := 0;
  l_lines_to_delete_index     NUMBER := 1;
  TYPE lines_to_delete_rec IS RECORD
       (line_index BINARY_INTEGER,
        line_type  ra_customer_trx_lines.Line_type%type
       );
  TYPE lines_to_delete_tbl_type IS TABLE OF lines_to_delete_rec INDEX BY BINARY_INTEGER;
  l_lines_to_delete_tbl       lines_to_delete_tbl_type;

  l_batch_date                date ;
  l_crtrx_date                date ;
  l_sysdate                   date ;

  e_handled_error             EXCEPTION;
  e_unexpected_error          EXCEPTION;
  l_message_name              VARCHAR2(255);
  l_debug_point               NUMBER;

  l_cm_header                 ra_customer_trx%rowtype;

  l_line_amount               ra_customer_trx_lines.extended_amount%type ;
  l_line_percent              number ;
  l_freight_amount            ra_customer_trx_lines.extended_amount%type ;
  l_freight_percent           number ;
  l_computed_tax_percent      number;
  l_computed_tax_amount       ra_customer_trx_lines.extended_amount%type;

  l_default_bs_name           varchar2(50);
  l_bs_type                   varchar2(10);
  l_copy_doc_number_flag      varchar2(1);
  l_bs_default_cust_trx_type_id  number;
  l_default_cust_trx_type_id  number;
  l_default_type_name         varchar2(50);
  l_open_receivable_flag      varchar2(1);
  l_post_to_gl_flag           varchar2(1);
  l_allow_freight_flag        varchar2(1);
  l_creation_sign             varchar2(1);
  l_allow_overapplication_flag   varchar2(1);
  l_natural_app_only_flag     varchar2(1);
  l_tax_calculate_flag        varchar2(1);

  l_default_gl_date           date;

  l_default_ship_via          varchar2(30);
  l_default_ship_date_actual  date;
  l_default_waybill_number    varchar2(50);
  l_default_fob_point         varchar2(30);

  l_form_name                 varchar2(20) := 'ARXTWCMI';
  l_form_version              number := NULL;

  l_auto_trx_numbering_flag   varchar2(1);

  l_credited_trx_rec          ra_customer_trx_cr_trx_v%rowtype  ;
--
  l_line_orig                 number;
  l_tax_orig                  number;
  l_frt_orig                  number;
  l_tot_orig                  number;
  l_line_bal                  number;
  l_tax_bal                   number;
  l_frt_bal                   number;
  l_tot_bal                   number;
  l_num_line_lines            number;
  l_num_tax_lines             number;
  l_num_frt_lines             number;
  l_num_installments          number;
  l_pmt_exist_flag            varchar2(1);
--
  l_credited_trx_line_tbl     arw_cm_cover.credit_lines_table_type;

  l_customer_trx_line_id      ra_customer_trx_lines.customer_trx_line_id%TYPE;

  l_err_mesg                  VARCHAR2(2000);
  l_ue_message                VARCHAR2(2000);


BEGIN

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('create_line_cm()+');
   END IF;

   /*------------------------------------+
    |   Standard start of API savepoint  |
    +------------------------------------*/

   SAVEPOINT Credit_Transaction_Pub;

   --
   -- populate the record with the values passed
   --
   l_cm_header.batch_id                 := p_batch_id;
   l_cm_header.trx_number               := p_trx_number;
   l_cm_header.trx_date                 := p_trx_date;
   l_cm_header.complete_flag            := p_complete_flag;
   l_cm_header.previous_customer_trx_id := p_prev_customer_trx_id;
   l_cm_header.batch_source_id          := p_batch_source_id;
   l_cm_header.cust_trx_type_id         := p_cust_trx_type_id;
   l_cm_header.invoice_currency_code    := p_currency_code;
   l_cm_header.exchange_date            := p_exchange_date;
   l_cm_header.exchange_rate_type       := p_exchange_rate_type;
   l_cm_header.exchange_rate            := p_exchange_rate;
   l_cm_header.credit_method_for_rules  := p_method_for_rules;
   l_cm_header.credit_method_for_installments := p_split_term_method;
   l_cm_header.initial_customer_trx_id  := p_initial_customer_trx_id;
   l_cm_header.primary_salesrep_id      := p_primary_salesrep_id;
   l_cm_header.invoicing_rule_id        := p_invoicing_rule_id;
   l_cm_header.bill_to_customer_id      := p_bill_to_customer_id;
   l_cm_header.bill_to_address_id       := p_bill_to_address_id;
   l_cm_header.bill_to_site_use_id      := p_bill_to_site_use_id;
   l_cm_header.bill_to_contact_id       := p_bill_to_contact_id;
   l_cm_header.ship_to_customer_id      := p_ship_to_customer_id;
   l_cm_header.ship_to_address_id       := p_ship_to_address_id;
   l_cm_header.ship_to_site_use_id      := p_ship_to_site_use_id;
   l_cm_header.ship_to_contact_id       := p_ship_to_contact_id;
   l_cm_header.receipt_method_id        := p_receipt_method_id;
   l_cm_header.paying_customer_id       := p_paying_customer_id;
   l_cm_header.paying_site_use_id       := p_paying_site_use_id;
   l_cm_header.customer_bank_account_id := p_customer_bank_account_id;
   l_cm_header.printing_option          := p_printing_option;
   l_cm_header.printing_last_printed    := p_printing_last_printed;
   l_cm_header.printing_pending         := p_printing_pending;
   l_cm_header.reason_code              := p_reason_code;
   l_cm_header.doc_sequence_value       := p_doc_sequence_value;
   l_cm_header.doc_sequence_id          := p_doc_sequence_id;
   l_cm_header.customer_reference       := p_customer_reference;
   l_cm_header.customer_reference_date  := p_customer_reference_date;
   l_cm_header.internal_notes           := p_internal_notes;
   l_cm_header.set_of_books_id          := p_set_of_books_id;
   l_cm_header.created_from             := p_created_from;
   l_cm_header.old_trx_number           := p_old_trx_number;
   l_cm_header.attribute_category       := p_attribute_category;
   l_cm_header.attribute1               := p_attribute1;
   l_cm_header.attribute2               := p_attribute2;
   l_cm_header.attribute3               := p_attribute3;
   l_cm_header.attribute4               := p_attribute4;
   l_cm_header.attribute5               := p_attribute5;
   l_cm_header.attribute6               := p_attribute6;
   l_cm_header.attribute7               := p_attribute7;
   l_cm_header.attribute8               := p_attribute8;
   l_cm_header.attribute9               := p_attribute9;
   l_cm_header.attribute10              := p_attribute10;
   l_cm_header.attribute11              := p_attribute11;
   l_cm_header.attribute12              := p_attribute12;
   l_cm_header.attribute13              := p_attribute13;
   l_cm_header.attribute14              := p_attribute14;
   l_cm_header.attribute15              := p_attribute15;
   l_cm_header.interface_header_context       := p_interface_header_context;
   l_cm_header.interface_header_attribute1    := p_interface_header_attribute1;
   l_cm_header.interface_header_attribute2    := p_interface_header_attribute2;
   l_cm_header.interface_header_attribute3    := p_interface_header_attribute3;
   l_cm_header.interface_header_attribute4    := p_interface_header_attribute4;
   l_cm_header.interface_header_attribute5    := p_interface_header_attribute5;
   l_cm_header.interface_header_attribute6    := p_interface_header_attribute6;
   l_cm_header.interface_header_attribute7    := p_interface_header_attribute7;
   l_cm_header.interface_header_attribute8    := p_interface_header_attribute8;
   l_cm_header.interface_header_attribute9    := p_interface_header_attribute9;
   l_cm_header.interface_header_attribute10   := p_interface_header_attribute10;
   l_cm_header.interface_header_attribute11   := p_interface_header_attribute11;
   l_cm_header.interface_header_attribute12   := p_interface_header_attribute12;
   l_cm_header.interface_header_attribute13   := p_interface_header_attribute13;
   l_cm_header.interface_header_attribute14   := p_interface_header_attribute14;
   l_cm_header.interface_header_attribute15   := p_interface_header_attribute15;
   l_cm_header.default_ussgl_transaction_code :=  p_default_ussgl_trx_code;
--
   l_cm_header.status_trx := null;
--
   l_cm_header.comments := p_comments;
   l_cm_header.purchase_order :=  p_purchase_order;
   l_cm_header.purchase_order_revision :=  p_purchase_order_revision;
   l_cm_header.purchase_order_date :=  p_purchase_order_date;
   l_cm_header.legal_entity_id :=  p_legal_entity_id;

   --
   --   Ensure that p_prev_customer_trx_id is not null
   --

   --
   --   Populate Default values
   --
   --  Amounts : get the credit memo amounts.
   --            for each : line, freight, tax,
   --            if both percentage and amount are null, assume 100%
   --            populate l_cm_header values accordingly.
   --            else if either (amount or %) is null, populate the other

   BEGIN
      ARP_PROCESS_CREDIT_UTIL.GET_CREDITED_TRX_DETAILS(
                          p_prev_customer_trx_id,
                          p_initial_customer_trx_id,
                          l_line_orig,
                          l_tax_orig,
                          l_frt_orig,
                          l_tot_orig,
                          l_line_bal,
                          l_tax_bal,
                          l_frt_bal,
                          l_tot_bal,
                          l_num_line_lines,
                          l_num_tax_lines,
                          l_num_frt_lines,
                          l_num_installments,
                          l_pmt_exist_flag);

   EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK TO Credit_Transaction_Pub;
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('EXCEPTION:  Error Calling arp_process_credit_util.get_credited_trx_details.');
      END IF;
       /*Bug3041196: Commented out this portion as it was overwriting message
        names set by get_credited_trx_details*/
--      fnd_message.set_name( 'AR', 'AR_RAXTRX-1666');
--      l_message_name :=  'AR_RAXTRX-1666' ;
      RAISE e_unexpected_error;
   END;


   --
   -- Default complete flag :
   -- If complete flag has not been passed in then, complete_flag is 'N'
   --
      IF p_complete_flag IS NULL THEN
         l_cm_header.complete_flag := 'N' ;
      END IF;

   --
   -- Other defaluts : use arp_process_credit_util.get_cm_header_defaults
   --
   -- First, get the details of the transaction being credited.
   -- This info is used as parameter into get_cm_header_defaults
   --
   BEGIN
      SELECT *
      INTO l_credited_trx_rec
      FROM ra_customer_trx_cr_trx_v
      WHERE customer_trx_id = p_prev_customer_trx_id  ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      --- TDEY 99/09/27 : Bug 913062
      --- Situation : The user is trying to credit a transaction that
      --- is not of the correct trx class, incomplete, or simply does
      --- not exist in the system.
      --- Proposed error message : AR_RAXTRX-1666  Your credit memo
      --- transaction can only credit an invoice or a debit memo line

      fnd_message.set_name( 'AR', 'AR_RAXTRX-1666');
      l_message_name :=  'AR_RAXTRX-1666' ;
      RAISE e_handled_error;
   WHEN OTHERS THEN
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('EXCEPTION: Debug point 1 : Unknown Error fetching credited trx details ');
      END IF;
      l_debug_point := 1;
      l_ue_message := SUBSTR('Error fetching credited trx details ' || SQLERRM, 1, 2000);
      RAISE e_unexpected_error;

   END;

   --
   -- Default trx_date
   -- Bugfix 2745276
   -- The trx date will be latest of credited transaction and sysdate
   --

   l_crtrx_date   := trunc(l_credited_trx_rec.trx_date);
   l_sysdate      := trunc(SYSDATE);

   IF (l_sysdate < l_crtrx_date) THEN
       l_cm_header.trx_date := l_crtrx_date;
   ELSE
       l_cm_header.trx_date := l_sysdate;
   END IF;

   --
   -- Default currency code
   --
   l_cm_header.invoice_currency_code := l_credited_trx_rec.invoice_currency_code;
   l_cm_header.exchange_date   := l_credited_trx_rec.exchange_date;
   l_cm_header.exchange_rate_type  := l_credited_trx_rec.exchange_rate_type;
   l_cm_header.exchange_rate := l_credited_trx_rec.exchange_rate;

   --
   -- Default created_from
   --
   IF l_cm_header.created_from IS NULL
   THEN
      l_cm_header.created_from := 'ARXTWCMI';
   END IF;

   -- Bug 2105483 : rather then calling arp_global at the start
   -- of the package, where it can error out NOCOPY since org_id is not yet set,
   -- do the call right before it is needed
   -- 5885313 commented out init routine here.
   -- arp_global.init_global;

   ARP_PROCESS_CREDIT_UTIL.GET_CM_HEADER_DEFAULTS(
                 -- bug 3796595 : pass l_cm_header.trx_date instead of NULL
                 l_cm_header.trx_date, -- p_trx_date,
                 l_credited_trx_rec.customer_trx_id,
                 NULL, -- p_customer_trx_id,
                 p_batch_source_id,  -- bug 3041195/2347286, use provided BS id
                 p_gl_date, -- p_gl_date, /*Bug 9536019*/
                 NULL, -- p_currency_code,
                 NULL, -- p_cust_trx_type_id,
                 NULL, -- p_ship_to_customer_id,
                 NULL, -- p_ship_to_site_use_id,
                 NULL, -- p_ship_to_contact_id,
                 NULL, -- p_bill_to_customer_id,
                 NULL, -- p_bill_to_site_use_id,
                 NULL, -- p_bill_to_contact_id,
                 NULL, -- p_primary_salesrep_id,
                 NULL, -- p_receipt_method_id,
                 NULL, -- p_customer_bank_account_id,
                 NULL, -- p_paying_customer_id,
                 NULL, -- p_paying_site_use_id,
                 NULL, -- Name_In('TCMI_HEADER.ship_via'),
                 NULL, -- Name_In('TCMI_HEADER.fob_point'),
                 NULL, -- p_invoicing_rule_id,
                 NULL, -- Name_In('TCMI_HEADER.rev_recog_run_flag'),
                 NULL, -- p_complete_flag,
                 ARP_GLOBAL.sysparam.salesrep_required_flag, -- Name_In('AR_WORLD.salesrep_required_flag'),
                 -- credited trx info
                 l_credited_trx_rec.batch_source_id,
                 l_credited_trx_rec.bs_credit_memo_batch_source_id, -- Name_In('TCMI_CRTRX.bs_credit_memo_batch_source_id'),
                 l_credited_trx_rec.rab_batch_source_id, -- Name_In('TCMI_HEADER.rab_batch_source_id'),
                 NULL, -- Name_In('AR_WORLD.ar_ra_batch_source'),
                 l_credited_trx_rec.cust_trx_type_id,
                 l_credited_trx_rec.ctt_credit_memo_type_id, -- Name_In('TCMI_CRTRX.ctt_credit_memo_type_id'),
                 trunc(l_credited_trx_rec.gd_gl_date), --gl_date
                 trunc(l_credited_trx_rec.trx_date), -- gl_date
                 l_credited_trx_rec.ship_to_customer_id,
                 l_credited_trx_rec.ship_to_site_use_id,
                 l_credited_trx_rec.ship_to_contact_id,
                 l_credited_trx_rec.bill_to_customer_id,
                 l_credited_trx_rec.bill_to_site_use_id,
                 l_credited_trx_rec.bill_to_contact_id,
                 l_credited_trx_rec.primary_salesrep_id,
                 l_credited_trx_rec.ctt_open_receivables_flag, -- Name_In('TCMI_CRTRX.ctt_open_receivables_flag'),
                 l_credited_trx_rec.receipt_method_id,
                 l_credited_trx_rec.customer_bank_account_id,
                 l_credited_trx_rec.ship_via, -- Name_In('TCMI_CRTRX.ship_via'),
                 l_credited_trx_rec.ship_date_actual, -- app_date.field_to_date('TCMI_CRTRX.ship_date_actual'),
                 l_credited_trx_rec.waybill_number, -- Name_In('TCMI_CRTRX.waybill_number'),
                 l_credited_trx_rec.fob_point, -- Name_In('TCMI_CRTRX.fob_point'),
                 --
                 l_cm_header.batch_source_id,
                 l_default_bs_name,
                 l_auto_trx_numbering_flag,
                 l_bs_type,
                 l_copy_doc_number_flag,
                 l_bs_default_cust_trx_type_id,
                 l_cm_header.cust_trx_type_id,
                 l_default_type_name,
                 l_open_receivable_flag,
                 l_post_to_gl_flag,
                 l_allow_freight_flag,
                 l_creation_sign,
                 l_allow_overapplication_flag,
                 l_natural_app_only_flag,
                 l_tax_calculate_flag,
                 l_cm_header.printing_option,
                 l_default_gl_date,
                 l_cm_header.ship_to_customer_id,
                 l_cm_header.ship_to_site_use_id,
                 l_cm_header.ship_to_contact_id,
                 l_cm_header.bill_to_customer_id,
                 l_cm_header.bill_to_site_use_id,
                 l_cm_header.bill_to_contact_id,
                 l_cm_header.primary_salesrep_id,
                 l_cm_header.receipt_method_id,
                 l_cm_header.customer_bank_account_id,
                 l_cm_header.paying_customer_id,
                 l_cm_header.paying_site_use_id,
                 l_default_ship_via,
                 l_default_ship_date_actual,
                 l_default_waybill_number,
                 l_default_fob_point);

   --
   -- However, if values have been passed in, use those
   --
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug(   'l_cm_header.batch_source_id = '
                    || to_char(l_cm_header.batch_source_id));
      arp_util.debug(   'l_cm_header.cust_trx_type_id = '
                    || to_char(l_cm_header.cust_trx_type_id));
      arp_util.debug(   'l_cm_header.primary_salesrep_id = '
                    || to_char(l_cm_header.primary_salesrep_id));
      arp_util.debug(   'l_cm_header.bill_to_customer_id = '
                    || to_char(l_cm_header.bill_to_customer_id));
      arp_util.debug(   'l_cm_header.bill_to_site_use_id = '
                    || to_char(l_cm_header.bill_to_site_use_id));
      arp_util.debug(   'l_cm_header.bill_to_contact_id = '
                    || to_char(l_cm_header.bill_to_contact_id));
      arp_util.debug(   'l_cm_header.ship_to_customer_id = '
                    || to_char(l_cm_header.ship_to_customer_id));
      arp_util.debug(   'l_cm_header.ship_to_site_use_id = '
                    || to_char(l_cm_header.ship_to_site_use_id));
      arp_util.debug(   'l_cm_header.ship_to_contact_id = '
                    || to_char(l_cm_header.ship_to_contact_id));
      arp_util.debug(   'l_cm_header.receipt_method_id = '
                    || to_char(l_cm_header.receipt_method_id));
      arp_util.debug(   'l_cm_header.paying_customer_id = '
                    || to_char(l_cm_header.paying_customer_id));
      arp_util.debug(   'l_cm_header.customer_bank_account_id = '
                    || to_char(l_cm_header.customer_bank_account_id));
      arp_util.debug(   'l_cm_header.printing_option = '
                    || l_cm_header.printing_option);
      arp_util.debug(   'l_cm_header.set_of_books_id = '
                    || to_char(l_cm_header.set_of_books_id));
      arp_util.debug(   'l_cm_header.legal_entity_id = '
                    || to_char(l_cm_header.legal_entity_id));
   END IF;

   --- Assign individual in parameter values to l_cm_header
   --- if not null. The transaction flexfields need to be
   --- set to the parameter values even if NULL is passed in

   IF p_cust_trx_type_id IS NOT NULL THEN
      l_cm_header.CUST_TRX_TYPE_ID := p_cust_trx_type_id ;
   ELSE
      IF l_cm_header.cust_trx_type_id IS NULL THEN
         ROLLBACK TO Credit_Transaction_Pub;
         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug(  'Error: l_cm_header.cust_trx_type_id IS NULL');
         END IF;
         fnd_message.set_name( 'AR', 'AR_TW_BAD_DATE_TRX_TYPE');
         l_message_name :=  'AR_TW_BAD_DATE_TRX_TYPE' ;
         RAISE e_handled_error;
      END IF;
   END IF;
   IF p_batch_id IS NOT NULL THEN
      l_cm_header.batch_id                 := p_batch_id;
   END IF;
   IF p_trx_number IS NOT NULL THEN
      l_cm_header.trx_number               := p_trx_number;
   END IF;
   IF p_trx_date IS NOT NULL THEN
      l_cm_header.trx_date                 := trunc(p_trx_date);
   END IF;
   IF p_complete_flag IS NOT NULL THEN
      l_cm_header.complete_flag            := p_complete_flag;
   END IF;
   IF p_batch_source_id IS NOT NULL THEN
      l_cm_header.batch_source_id          := p_batch_source_id;
   END IF;
   IF p_currency_code IS NOT NULL THEN
      l_cm_header.invoice_currency_code    := p_currency_code;
   END IF;
   IF p_exchange_date IS NOT NULL THEN
      l_cm_header.exchange_date            := p_exchange_date;
   END IF;
   IF p_exchange_rate_type IS NOT NULL THEN
      l_cm_header.exchange_rate_type       := p_exchange_rate_type;
   END IF;
   IF p_exchange_rate IS NOT NULL THEN
      l_cm_header.exchange_rate            := p_exchange_rate;
   END IF;
   IF p_method_for_rules IS NOT NULL THEN
      l_cm_header.credit_method_for_rules  := p_method_for_rules;
   END IF;
   IF p_split_term_method IS NOT NULL THEN
      l_cm_header.credit_method_for_installments := p_split_term_method;
   END IF;
   IF p_initial_customer_trx_id IS NOT NULL THEN
      l_cm_header.initial_customer_trx_id  := p_initial_customer_trx_id;
   END IF;
   IF p_primary_salesrep_id IS NOT NULL THEN
      l_cm_header.primary_salesrep_id      := p_primary_salesrep_id;
   END IF;
   IF p_invoicing_rule_id IS NOT NULL THEN
      l_cm_header.invoicing_rule_id        := p_invoicing_rule_id;
   ELSE
      l_cm_header.invoicing_rule_id        := l_credited_trx_rec.invoicing_rule_id;
   END IF;
   IF p_bill_to_customer_id IS NOT NULL THEN
          l_cm_header.bill_to_customer_id      := p_bill_to_customer_id;
   END IF;
   IF p_bill_to_address_id IS NOT NULL THEN
      l_cm_header.bill_to_address_id       := p_bill_to_address_id;
   END IF;
   IF p_bill_to_site_use_id IS NOT NULL THEN
      l_cm_header.bill_to_site_use_id      := p_bill_to_site_use_id;
   END IF;
   IF p_bill_to_contact_id IS NOT NULL THEN
      l_cm_header.bill_to_contact_id       := p_bill_to_contact_id;
   END IF;
   IF p_ship_to_customer_id IS NOT NULL THEN
      l_cm_header.ship_to_customer_id      := p_ship_to_customer_id;
   END IF;
   IF p_ship_to_address_id IS NOT NULL THEN
      l_cm_header.ship_to_address_id       := p_ship_to_address_id;
   END IF;
   IF p_ship_to_site_use_id IS NOT NULL THEN
      l_cm_header.ship_to_site_use_id      := p_ship_to_site_use_id;
   END IF;
   IF p_ship_to_contact_id IS NOT NULL THEN
      l_cm_header.ship_to_contact_id       := p_ship_to_contact_id;
   END IF;
   IF p_receipt_method_id IS NOT NULL THEN
      l_cm_header.receipt_method_id        := p_receipt_method_id;
   END IF;
   IF p_paying_customer_id IS NOT NULL THEN
      l_cm_header.paying_customer_id       := p_paying_customer_id;
   END IF;
   IF p_paying_site_use_id IS NOT NULL THEN
      l_cm_header.paying_site_use_id       := p_paying_site_use_id;
   END IF;
   IF p_customer_bank_account_id IS NOT NULL THEN
      l_cm_header.customer_bank_account_id := p_customer_bank_account_id;
   END IF;
   IF p_printing_option IS NOT NULL THEN
      l_cm_header.printing_option          := p_printing_option;
   END IF;
   IF p_printing_last_printed IS NOT NULL THEN
      l_cm_header.printing_last_printed    := p_printing_last_printed;
   END IF;
   IF p_printing_pending IS NOT NULL THEN
      l_cm_header.printing_pending         := p_printing_pending;
   END IF;
   IF p_reason_code IS NOT NULL THEN
      l_cm_header.reason_code              := p_reason_code;
   END IF;
   IF p_doc_sequence_value IS NOT NULL THEN
      l_cm_header.doc_sequence_value       := p_doc_sequence_value;
   END IF;
   IF p_doc_sequence_id IS NOT NULL THEN
      l_cm_header.doc_sequence_id          := p_doc_sequence_id;
   END IF;
   IF p_customer_reference IS NOT NULL THEN
      l_cm_header.customer_reference       := p_customer_reference;
   END IF;
   IF p_customer_reference_date IS NOT NULL THEN
      l_cm_header.customer_reference_date  := p_customer_reference_date;
   END IF;
   IF p_internal_notes IS NOT NULL THEN
      l_cm_header.internal_notes           := p_internal_notes;
   END IF;
   IF p_set_of_books_id IS NOT NULL THEN
      l_cm_header.set_of_books_id          := p_set_of_books_id;
   END IF;
   IF p_old_trx_number IS NOT NULL THEN
      l_cm_header.old_trx_number           := p_old_trx_number;
   END IF;
   IF p_attribute_category IS NOT NULL THEN
      l_cm_header.attribute_category       := p_attribute_category;
   END IF;
   IF p_attribute1 IS NOT NULL THEN
      l_cm_header.attribute1               := p_attribute1;
   END IF;
   IF p_attribute2 IS NOT NULL THEN
      l_cm_header.attribute2               := p_attribute2;
   END IF;
   IF p_attribute3 IS NOT NULL THEN
      l_cm_header.attribute3               := p_attribute3;
   END IF;
   IF p_attribute4 IS NOT NULL THEN
      l_cm_header.attribute4               := p_attribute4;
   END IF;
   IF p_attribute5 IS NOT NULL THEN
      l_cm_header.attribute5               := p_attribute5;
   END IF;
   IF p_attribute6 IS NOT NULL THEN
      l_cm_header.attribute6               := p_attribute6;
   END IF;
   IF p_attribute7 IS NOT NULL THEN
      l_cm_header.attribute7               := p_attribute7;
   END IF;
   IF p_attribute8 IS NOT NULL THEN
      l_cm_header.attribute8               := p_attribute8;
   END IF;
   IF p_attribute9 IS NOT NULL THEN
      l_cm_header.attribute9               := p_attribute9;
   END IF;
   IF p_attribute10 IS NOT NULL THEN
      l_cm_header.attribute10              := p_attribute10;
   END IF;
   IF p_attribute11 IS NOT NULL THEN
      l_cm_header.attribute11              := p_attribute11;
   END IF;
   IF p_attribute12 IS NOT NULL THEN
      l_cm_header.attribute12              := p_attribute12;
   END IF;
   IF p_attribute13 IS NOT NULL THEN
      l_cm_header.attribute13              := p_attribute13;
   END IF;
   IF p_attribute14 IS NOT NULL THEN
      l_cm_header.attribute14              := p_attribute14;
   END IF;
   IF p_attribute15 IS NOT NULL THEN
      l_cm_header.attribute15              := p_attribute15;
   END IF;
   l_cm_header.interface_header_context       := p_interface_header_context;
   l_cm_header.interface_header_attribute1    := p_interface_header_attribute1;
   l_cm_header.interface_header_attribute2    := p_interface_header_attribute2;
   l_cm_header.interface_header_attribute3    := p_interface_header_attribute3;
   l_cm_header.interface_header_attribute4    := p_interface_header_attribute4;
   l_cm_header.interface_header_attribute5    := p_interface_header_attribute5;
   l_cm_header.interface_header_attribute6    := p_interface_header_attribute6;
   l_cm_header.interface_header_attribute7    := p_interface_header_attribute7;
   l_cm_header.interface_header_attribute8    := p_interface_header_attribute8;
   l_cm_header.interface_header_attribute9    := p_interface_header_attribute9;
   l_cm_header.interface_header_attribute10   := p_interface_header_attribute10;
   l_cm_header.interface_header_attribute11   := p_interface_header_attribute11;
   l_cm_header.interface_header_attribute12   := p_interface_header_attribute12;
   l_cm_header.interface_header_attribute13   := p_interface_header_attribute13;
   l_cm_header.interface_header_attribute14   := p_interface_header_attribute14;
   l_cm_header.interface_header_attribute15   := p_interface_header_attribute15;
   /*4556000-4606558*/
   l_cm_header.global_attribute_category      := p_global_attribute_category;
   l_cm_header.global_attribute1    	      := p_global_attribute1;
   l_cm_header.global_attribute2    	      := p_global_attribute2;
   l_cm_header.global_attribute3	      := p_global_attribute3;
   l_cm_header.global_attribute4    	      := p_global_attribute4;
   l_cm_header.global_attribute5    	      := p_global_attribute5;
   l_cm_header.global_attribute6	      := p_global_attribute6;
   l_cm_header.global_attribute7    	      := p_global_attribute7;
   l_cm_header.global_attribute8    	      := p_global_attribute8;
   l_cm_header.global_attribute9    	      := p_global_attribute9;
   l_cm_header.global_attribute10    	      := p_global_attribute10;
   l_cm_header.global_attribute11    	      := p_global_attribute11;
   l_cm_header.global_attribute12    	      := p_global_attribute12;
   l_cm_header.global_attribute13    	      := p_global_attribute13;
   l_cm_header.global_attribute14    	      := p_global_attribute14;
   l_cm_header.global_attribute15    	      := p_global_attribute15;
   l_cm_header.global_attribute16    	      := p_global_attribute16;
   l_cm_header.global_attribute17    	      := p_global_attribute17;
   l_cm_header.global_attribute18	      := p_global_attribute18;
   l_cm_header.global_attribute19    	      := p_global_attribute19;
   l_cm_header.global_attribute20    	      := p_global_attribute20;
   l_cm_header.global_attribute21	      := p_global_attribute21;
   l_cm_header.global_attribute22    	      := p_global_attribute22;
   l_cm_header.global_attribute23    	      := p_global_attribute23;
   l_cm_header.global_attribute24   	      := p_global_attribute24;
   l_cm_header.global_attribute25    	      := p_global_attribute25;
   l_cm_header.global_attribute26    	      := p_global_attribute26;
   l_cm_header.global_attribute27    	      := p_global_attribute27;
   l_cm_header.global_attribute28    	      := p_global_attribute28;
   l_cm_header.global_attribute29    	      := p_global_attribute29;
   l_cm_header.global_attribute30    	      := p_global_attribute30;
   IF p_default_ussgl_trx_code IS NOT NULL THEN
      l_cm_header.default_ussgl_transaction_code :=  p_default_ussgl_trx_code;
   END IF;
   IF p_comments IS NOT NULL THEN
      l_cm_header.comments := p_comments;
   END IF;

   --
   -- default gl_date
   --

   IF p_gl_date IS NOT NULL THEN
      l_default_gl_date := p_gl_date;
   END IF;

   /* 7658882 - set l_compute_tax based on parameter p_compute_tax.
      This value is ultimately set by p_line_credit_flag where a
      Y there indicates a Y here and an L there indicates line-only
      so we set N here. */

   IF p_compute_tax IS NOT NULL THEN
      l_compute_tax := p_compute_tax;
   ELSE
      l_compute_tax := 'N';
   END IF;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug(   'l_compute_tax = ' || l_compute_tax);
   END IF;

   --
   -- call the entity handler
   --

   l_line_amount  := NULL;
   l_freight_amount := NULL;
   l_customer_trx_id := NULL;
   l_computed_tax_percent := NULL;
   l_computed_tax_amount := NULL;

   BEGIN
      ARP_PROCESS_CREDIT.INSERT_HEADER(
                             l_form_name,
                             1.0,
                             l_cm_header,
                             'CM',
                             l_default_gl_date,
                             -- p_primary_salesrep_id,
                             l_cm_header.primary_salesrep_id,
                             l_cm_header.invoice_currency_code, -- p_currency_code,
                             p_prev_customer_trx_id,
                             p_line_percent,
                             p_freight_percent,
                             l_line_amount,
                             l_freight_amount,
                             l_compute_tax,
                             p_trx_number,
                             l_customer_trx_id,
                             l_computed_tax_percent,
                             l_computed_tax_amount,
                             p_status);
      p_computed_tax_percent := l_computed_tax_percent;
      p_computed_tax_amount := l_computed_tax_amount;

   EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK TO Credit_Transaction_Pub;
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug(  'Debug point 2 : Error Calling arp_process_credit.insert_header.');
      END IF;
      l_debug_point := 2;
      l_ue_message := SUBSTR('Error Calling arp_process_credit.insert_header '
                         || SQLERRM, 1, 2000);
      RAISE e_unexpected_error;
   END ;

   BEGIN

      FOR i IN 1..p_credit_line_table.count
      LOOP
         l_credited_trx_line_tbl(i).Extended_amount
               := p_credit_line_table(i).Extended_amount ;
         l_credited_trx_line_tbl(i).Unit_selling_price :=
              p_credit_line_table(i).Unit_selling_price ;
         l_credited_trx_line_tbl(i).QUANTITY_CREDITED :=
              p_credit_line_table(i).QUANTITY_CREDITED ;
         l_credited_trx_line_tbl(i).customer_trx_line_id := NULL;
         l_credited_trx_line_tbl(i).Previous_customer_trx_line_id :=
            p_credit_line_table(i).Previous_customer_trx_line_id;
	 /*4556000 added copy assignment statements for Line level FF attributes*/
         l_credited_trx_line_tbl(i).ATTRIBUTE_CATEGORY :=
            p_credit_line_table(i).ATTRIBUTE_CATEGORY;
         l_credited_trx_line_tbl(i).ATTRIBUTE1 :=
            p_credit_line_table(i).ATTRIBUTE1;
         l_credited_trx_line_tbl(i).ATTRIBUTE2 :=
            p_credit_line_table(i).ATTRIBUTE2;
         l_credited_trx_line_tbl(i).ATTRIBUTE3 :=
            p_credit_line_table(i).ATTRIBUTE3;
         l_credited_trx_line_tbl(i).ATTRIBUTE4 :=
            p_credit_line_table(i).ATTRIBUTE4;
         l_credited_trx_line_tbl(i).ATTRIBUTE5 :=
            p_credit_line_table(i).ATTRIBUTE5;
         l_credited_trx_line_tbl(i).ATTRIBUTE6 :=
            p_credit_line_table(i).ATTRIBUTE6;
         l_credited_trx_line_tbl(i).ATTRIBUTE7 :=
            p_credit_line_table(i).ATTRIBUTE7;
         l_credited_trx_line_tbl(i).ATTRIBUTE8 :=
            p_credit_line_table(i).ATTRIBUTE8;
         l_credited_trx_line_tbl(i).ATTRIBUTE9 :=
            p_credit_line_table(i).ATTRIBUTE9;
         l_credited_trx_line_tbl(i).ATTRIBUTE10 :=
            p_credit_line_table(i).ATTRIBUTE10;
         l_credited_trx_line_tbl(i).ATTRIBUTE11 :=
            p_credit_line_table(i).ATTRIBUTE11;
         l_credited_trx_line_tbl(i).ATTRIBUTE12 :=
            p_credit_line_table(i).ATTRIBUTE12;
         l_credited_trx_line_tbl(i).ATTRIBUTE13 :=
            p_credit_line_table(i).ATTRIBUTE13;
         l_credited_trx_line_tbl(i).ATTRIBUTE14 :=
            p_credit_line_table(i).ATTRIBUTE14;
         l_credited_trx_line_tbl(i).ATTRIBUTE15 :=
            p_credit_line_table(i).ATTRIBUTE15;

         l_credited_trx_line_tbl(i).interface_line_context := p_credit_line_table(i).interface_line_context;
         l_credited_trx_line_tbl(i).interface_line_attribute1 := p_credit_line_table(i).interface_line_attribute1;
         l_credited_trx_line_tbl(i).interface_line_attribute2 := p_credit_line_table(i).interface_line_attribute2;
         l_credited_trx_line_tbl(i).interface_line_attribute3 := p_credit_line_table(i).interface_line_attribute3;
         l_credited_trx_line_tbl(i).interface_line_attribute4 := p_credit_line_table(i).interface_line_attribute4;
         l_credited_trx_line_tbl(i).interface_line_attribute5 := p_credit_line_table(i).interface_line_attribute5;
         l_credited_trx_line_tbl(i).interface_line_attribute6 := p_credit_line_table(i).interface_line_attribute6;
         l_credited_trx_line_tbl(i).interface_line_attribute7 := p_credit_line_table(i).interface_line_attribute7;
         l_credited_trx_line_tbl(i).interface_line_attribute8 := p_credit_line_table(i).interface_line_attribute8;
         l_credited_trx_line_tbl(i).interface_line_attribute9 := p_credit_line_table(i).interface_line_attribute9;
         l_credited_trx_line_tbl(i).interface_line_attribute10 := p_credit_line_table(i).interface_line_attribute10;
         l_credited_trx_line_tbl(i).interface_line_attribute11 := p_credit_line_table(i).interface_line_attribute11;
         l_credited_trx_line_tbl(i).interface_line_attribute12 := p_credit_line_table(i).interface_line_attribute12;
         l_credited_trx_line_tbl(i).interface_line_attribute13 := p_credit_line_table(i).interface_line_attribute13;
         l_credited_trx_line_tbl(i).interface_line_attribute14 := p_credit_line_table(i).interface_line_attribute14;
         l_credited_trx_line_tbl(i).interface_line_attribute15 := p_credit_line_table(i).interface_line_attribute15;

         l_credited_trx_line_tbl(i).global_attribute_category := p_credit_line_table(i).global_attribute_category;
         l_credited_trx_line_tbl(i).global_attribute1 := p_credit_line_table(i).global_attribute1;
         l_credited_trx_line_tbl(i).global_attribute2 := p_credit_line_table(i).global_attribute2;
         l_credited_trx_line_tbl(i).global_attribute3 := p_credit_line_table(i).global_attribute3;
         l_credited_trx_line_tbl(i).global_attribute4 := p_credit_line_table(i).global_attribute4;
         l_credited_trx_line_tbl(i).global_attribute5 := p_credit_line_table(i).global_attribute5;
         l_credited_trx_line_tbl(i).global_attribute6 := p_credit_line_table(i).global_attribute6;
         l_credited_trx_line_tbl(i).global_attribute7 := p_credit_line_table(i).global_attribute7;
         l_credited_trx_line_tbl(i).global_attribute8 := p_credit_line_table(i).global_attribute8;
         l_credited_trx_line_tbl(i).global_attribute9 := p_credit_line_table(i).global_attribute9;
         l_credited_trx_line_tbl(i).global_attribute10 := p_credit_line_table(i).global_attribute10;
         l_credited_trx_line_tbl(i).global_attribute11 := p_credit_line_table(i).global_attribute11;
         l_credited_trx_line_tbl(i).global_attribute12 := p_credit_line_table(i).global_attribute12;
         l_credited_trx_line_tbl(i).global_attribute13 := p_credit_line_table(i).global_attribute13;
         l_credited_trx_line_tbl(i).global_attribute14 := p_credit_line_table(i).global_attribute14;
         l_credited_trx_line_tbl(i).global_attribute15 := p_credit_line_table(i).global_attribute15;
         l_credited_trx_line_tbl(i).global_attribute16 := p_credit_line_table(i).global_attribute16;
         l_credited_trx_line_tbl(i).global_attribute17 := p_credit_line_table(i).global_attribute17;
         l_credited_trx_line_tbl(i).global_attribute18 := p_credit_line_table(i).global_attribute18;
         l_credited_trx_line_tbl(i).global_attribute19 := p_credit_line_table(i).global_attribute19;
         l_credited_trx_line_tbl(i).global_attribute20 := p_credit_line_table(i).global_attribute20;

         /*Bug2880106 - Validate Amount Passed
           1. If extended amount is null, then quantity has to be passed
           2. If extended amount is not zero, then
                i) if quantity is passed, it must not be zero
               ii) if quantity is not passed, then unit selling price
                   must not be zero
           (If quantity is non zero, unit selling price is zero and amount
             is non zero, then unit seeling price will be re-derived to
            be non-zero)
         */
         IF p_credit_line_table(i).Extended_amount IS NULL AND
            p_credit_line_table(i).quantity_credited IS NULL
         THEN
             l_message_name := 'AR_CM_API_NULL_QTY_AMT';
             RAISE e_handled_error;
         ELSIF l_cm_header.credit_method_for_rules = 'UNIT' AND
              p_credit_line_table(i).quantity_credited IS NULL
         THEN
             l_message_name := 'AR_RAXTRX-1768';
             RAISE e_handled_error;
         ELSIF p_credit_line_table(i).Extended_amount <> 0 AND
            ( (p_credit_line_table(i).quantity_credited is NULL
               AND
               NVL(p_credit_line_table(i).Unit_selling_price,1) = 0)
           OR
               NVL(p_credit_line_table(i).quantity_credited,1) = 0 )
         THEN
             l_message_name := 'AR_CM_API_INVALID_AMOUNT';
             RAISE e_handled_error;
         END IF;

      END LOOP;

   EXCEPTION
   WHEN e_handled_error THEN
        fnd_message.set_name( 'AR', 'l_message_name');
        RAISE e_handled_error;
   WHEN OTHERS THEN
      ROLLBACK TO Credit_Transaction_Pub;
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug(  'Debug point 9 : Error fetching credit line details');
      END IF;
      l_debug_point := 9;
      l_ue_message := SUBSTR('Error fetching credit line details '
                         || SQLERRM, 1, 2000);
      RAISE e_unexpected_error;
   END ;

   -----------------------------Insert_line------------------------
   BEGIN
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug(  'Before Insert line loop');
      END IF;

      /* 7658882 - identify source of credit as
         either ARXTWCMI or AR_CREDIT_MEMO_API and
         handle etax calls differently for each */
      l_form_name := p_created_from;

      FOR i IN 1..l_credited_trx_line_tbl.COUNT
      LOOP

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug(  'Before Insert line call');
         END IF;
         ARP_PROCESS_CREDIT.insert_line(
           p_form_name		      => l_form_name,
           p_form_version	      => 1.0 ,
           p_credit_rec	       	      => l_credited_trx_line_tbl(i) ,
           p_line_amount               => p_credit_line_table(i).Extended_amount,
           p_freight_amount            => NULL,
           p_line_percent              => NULL,
           p_freight_percent           => NULL,
           p_memo_line_type            => 'LINE',
           p_gl_date                   => l_default_gl_date,
           p_currency_code             => l_cm_header.invoice_currency_code ,
           p_primary_salesrep_id       => l_cm_header.primary_salesrep_id,
           p_compute_tax               => l_compute_tax,
           p_customer_trx_id           => l_customer_trx_id,
           p_prev_customer_trx_id      => p_prev_customer_trx_id,
           p_prev_customer_trx_line_id => p_credit_line_table(i).Previous_customer_trx_line_id,
           p_tax_percent               => l_computed_tax_percent,
           p_tax_amount                => l_computed_tax_amount,
           p_customer_trx_line_id      => l_customer_trx_line_id,
           p_status                    => p_status
         );

         IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug(  'After Insert line call');
         END IF;
      END LOOP;
   EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK TO Credit_Transaction_Pub;
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug(  'Debug point 8 : Error inserting credit line details');
      END IF;
      l_err_mesg := SQLERRM;
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug(  l_err_mesg);
      END IF;
      l_debug_point := 8;
      l_ue_message := SUBSTR('Error inserting credit line details '
                         || SQLERRM, 1, 2000);
      RAISE e_unexpected_error;
   END ;

   /* R12 eTax uptake - call to calculate_tax to create tax lines */

   ARP_ETAX_SERVICES_PKG.Calculate_tax (
                   p_customer_trx_id => l_customer_trx_id,
                   p_action => 		'CREATE',
                   x_return_status => 	l_return_status,
                   x_msg_count =>  	l_msg_count,
                   x_msg_data =>    	l_msg_data);

   IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      p_status := 'ETAX_ERROR';
   END IF;

   /*
   TDEY 99/09/21 : bug 983278 : Need Post commit logic !!!

   Bug3041195: Changed the parameters passed to post_commit. We need to pass
   the credited trx invoice type settings for - overapplication flag; natural
   application flag and previous open receivables flag.

   */

   BEGIN
      arp_process_header.post_commit(
                 p_form_name => l_form_name
                ,p_form_version => 70.1
                ,p_customer_trx_id => l_customer_trx_id
                ,p_previous_customer_trx_id => p_prev_customer_trx_id
                ,p_complete_flag => l_cm_header.complete_flag
                ,p_trx_open_receivables_flag  =>  l_open_receivable_flag
                ,p_prev_open_receivables_flag  => l_credited_trx_rec.ctt_open_receivables_flag
                ,p_creation_sign  => l_creation_sign
                ,p_allow_overapplication_flag  => l_credited_trx_rec.ctt_allow_overapp_flag
                ,p_natural_application_flag  => l_credited_trx_rec.ctt_natural_app_only_flag
                ,p_cash_receipt_id  => NULL
                   );
   EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK TO Credit_Transaction_Pub;
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug(  'Debug point 3 : Error Calling arp_process_header.post_commit.');
      END IF;
      l_debug_point := 3;
      l_ue_message := SUBSTR('Error Calling arp_process_header.post_commit '
                         || SQLERRM, 1, 2000);
      RAISE e_unexpected_error;
   END ;


   /*
       Bug 2527439 : check if doc sequence is required/used
       Bug 3041195 : 1. ra_customer_trx_table was not getting updated with the
                     doc seq no/value when copy_doc_number_flag = 'N'. Modified
                     if ..else clause.
                     2. Document sequence Nos were getting lost if errors were
                     encountered during completion checking. Re-arranged the
                     code to generate nos only if no errors were encountered.
  */


   BEGIN
      get_doc_seq(222,
                  l_default_type_name,
                  arp_global.set_of_books_id,
                  'A',
                  l_cm_header.trx_date,
                  l_cm_header.complete_flag,
                  l_cm_header.doc_sequence_value,
                  l_cm_header.doc_sequence_id,
                  l_doc_seq_status);

     IF l_doc_seq_status = FND_API.G_RET_STS_ERROR THEN
         RAISE e_unexpected_error;
     END IF;


     IF PG_DEBUG in ('Y', 'C') THEN
            arp_util.debug(  'l_copy_doc_number_flag = ' || l_copy_doc_number_flag);
            arp_util.debug(  'doc_sequence_value = ' || to_char(l_cm_header.doc_sequence_value));
            arp_util.debug(  'doc_sequence_id = ' || to_char(l_cm_header.doc_sequence_id));
     END IF;

    -- check copy_doc_number_flag
    IF l_cm_header.doc_sequence_value is not null THEN

       IF ( NVL(l_copy_doc_number_flag,'N') = 'Y' ) THEN
            l_cm_header.old_trx_number := p_trx_number;
            l_cm_header.trx_number     := to_char(l_cm_header.doc_sequence_value);

            UPDATE ar_payment_schedules
              SET trx_number = l_cm_header.trx_number
              WHERE customer_trx_id = l_customer_trx_id;
       ELSE
            l_cm_header.trx_number     := p_trx_number;
       END IF;

       UPDATE ra_customer_trx
       SET   doc_sequence_value = l_cm_header.doc_sequence_value,
             doc_sequence_id    = l_cm_header.doc_sequence_id,
             trx_number         = l_cm_header.trx_number,
             old_trx_number     = l_cm_header.old_trx_number
       WHERE customer_trx_id    = l_customer_trx_id;

    END IF;

   EXCEPTION
   WHEN OTHERS THEN
       ROLLBACK TO Credit_Transaction_Pub;
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(  'Debug point 4 : Error Processing Doc Seq No.');
       END IF;
       l_debug_point := 4;
       l_ue_message := SUBSTR(' Error Processing Doc Seq No ' || SQLERRM, 1, 2000);
       RAISE e_unexpected_error;
   END ;

   p_customer_trx_id := l_customer_trx_id;
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug(   'p_customer_trx_id = ' || to_char(p_customer_trx_id));
      arp_util.debug(   'p_trx_number = ' || p_trx_number);
      arp_util.debug(   'p_computed_tax_percent = ' || to_char(p_computed_tax_percent));
      arp_util.debug(   'p_computed_tax_amount = ' || to_char(p_computed_tax_amount));
      arp_util.debug(   'p_status = ' || p_status);
      arp_util.debug('create_line_cm()-');
   END IF;

EXCEPTION
  -- bug 2290738 : populate error table with message and pass value to p_status

  WHEN e_handled_error THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION WHEN e_handled_error : create_line_cm');
        END IF;
        p_status := 'e_handled_error';

        ROLLBACK TO Credit_Transaction_Pub;
        p_errors(1).customer_trx_id     := p_prev_customer_trx_id;
        p_errors(1).message_name        := l_message_name;
        p_errors(1).translated_message  := fnd_message.get;

        fnd_message.set_name( 'AR', l_message_name);
        FND_MSG_PUB.Add;

        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug(  'p_errors(1).message_name = '
                     || p_errors(1).message_name);
           arp_util.debug(  'p_errors(1).encoded_message = '
                     || p_errors(1).encoded_message);
           arp_util.debug(  'p_errors(1).translated_message = '
                     || p_errors(1).translated_message);
        END IF;

  WHEN e_unexpected_error THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION WHEN e_unexpected_error : create_line_cm');
        END IF;
        p_status := 'e_unexpected_error';

        ROLLBACK TO Credit_Transaction_Pub;
        p_errors(1).customer_trx_id     := p_prev_customer_trx_id;
        p_errors(1).encoded_message     := fnd_message.get_encoded;
        fnd_message.set_encoded(p_errors(1).encoded_message);
        p_errors(1).translated_message  := fnd_message.get;

        IF p_errors(1).translated_message IS NULL
        THEN
            p_errors(1).message_name        := 'GENERIC_MESSAGE';
            p_errors(1).token_name_1        := 'GENERIC_TEXT';
            p_errors(1).token_1             := NVL(l_ue_message, 'CREATE_LINE_CM : UNEXPECTED ERROR') ;

            fnd_message.set_name('AR','GENERIC_MESSAGE');
            fnd_message.set_token('GENERIC_TEXT', p_errors(1).token_1 );
            FND_MSG_PUB.Add;

            p_errors(1).translated_message     := fnd_message.get;
        ELSE
            /*Bug3041195 - Set Message on API stack */
            fnd_message.set_encoded(p_errors(1).encoded_message);
            FND_MSG_PUB.Add;
        END IF;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug(  'p_errors(1).message_name = '
                     || p_errors(1).message_name);
           arp_util.debug(  'p_errors(1).encoded_message = '
                     || p_errors(1).encoded_message);
           arp_util.debug(  'p_errors(1).translated_message = '
                     || p_errors(1).translated_message);
        END IF;

  WHEN OTHERS THEN
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug('EXCEPTION WHEN OTHERS : create_line_cm');
        END IF;
        p_status := 'others';

        ROLLBACK TO Credit_Transaction_Pub;
        p_errors(1).customer_trx_id     := p_prev_customer_trx_id;
        p_errors(1).message_name        := 'GENERIC_MESSAGE';
        p_errors(1).token_name_1        := 'GENERIC_TEXT';
        p_errors(1).token_1             := 'CREATE_LINE_CM : ERROR AT UNKNOWN POINT '|| SQLERRM ;

        fnd_message.set_name('AR','GENERIC_MESSAGE');
        fnd_message.set_token('GENERIC_TEXT', p_errors(1).token_1 );
        FND_MSG_PUB.Add;

        p_errors(1).translated_message     := fnd_message.get;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug(  'p_errors(1).message_name = '
                     || p_errors(1).message_name);
           arp_util.debug(  'p_errors(1).encoded_message = '
                     || p_errors(1).encoded_message);
           arp_util.debug(  'p_errors(1).translated_message = '
                     || p_errors(1).translated_message);
        END IF;

END create_line_cm;

BEGIN
   /*Bug3041195: Need to get profile value only once */
   fnd_profile.get('UNIQUE:SEQ_NUMBERS', unique_seq_numbers);
END arw_cm_cover;
/
