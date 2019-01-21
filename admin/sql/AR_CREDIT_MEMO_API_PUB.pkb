create or replace
PACKAGE BODY AR_CREDIT_MEMO_API_PUB AS
/* $Header: ARWCMAPB.pls 120.12.12010000.7 2011/02/06 09:37:25 manishri ship $ */

/* =======================================================================
   Global Data Types
   ======================================================================*/

G_PKG_NAME      CONSTANT VARCHAR2(30)   := 'AR_CREDIT_MEMO_API_PUB';
G_MSG_ERROR     CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_ERROR;

PG_DEBUG varchar2(1) := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');

/*Bg 7367350 Added new parameter for internal comment handling*/
PROCEDURE create_request (
  -- standard API parameters
  p_api_version          IN  NUMBER,
  p_init_msg_list        IN  VARCHAR2 	:= FND_API.G_FALSE,
  p_commit               IN  VARCHAR2 	:= FND_API.G_FALSE,
  p_validation_level     IN  NUMBER   	:= FND_API.G_VALID_LEVEL_FULL,
  x_return_status        OUT NOCOPY VARCHAR2,
  x_msg_count            OUT NOCOPY NUMBER,
  x_msg_data             OUT NOCOPY VARCHAR2,
  -- credit memo request parameters
  p_customer_trx_id      IN  ra_customer_trx.customer_trx_id%type,
  p_line_credit_flag     IN  ra_cm_requests.line_credits_flag%type,
  p_line_amount          IN  NUMBER 	:= 0 ,
  p_tax_amount           IN  NUMBER 	:= 0 ,
  p_freight_amount       IN  NUMBER 	:= 0,
  p_cm_reason_code       IN  VARCHAR2,
  p_comments             IN  VARCHAR2 	DEFAULT NULL,
  p_orig_trx_number	 IN  VARCHAR2   DEFAULT NULL,
  p_tax_ex_cert_num	 IN  VARCHAR2 	DEFAULT NULL,
  p_request_url          IN  VARCHAR2   := 'AR_CREDIT_MEMO_API_PUB.print_default_page',
  p_transaction_url      IN  VARCHAR2	:= 'AR_CREDIT_MEMO_API_PUB.print_default_page',
  p_trans_act_url        IN  VARCHAR2	:= 'AR_CREDIT_MEMO_API_PUB.print_default_page',
  p_cm_line_tbl          IN  Cm_Line_Tbl_Type_Cover%type := cm_line_tbl_type_cover ,
  p_skip_workflow_flag   IN VARCHAR2    DEFAULT 'N',
  p_credit_method_installments IN VARCHAR2 DEFAULT NULL,
  p_credit_method_rules  IN VARCHAR2    DEFAULT NULL,
  p_batch_source_name    IN VARCHAR2    DEFAULT NULL,
  p_org_id               IN NUMBER      DEFAULT NULL,
  x_request_id           OUT NOCOPY VARCHAR2,
  /*4606558*/
  p_attribute_rec           IN  arw_cmreq_cover.pq_attribute_rec_type DEFAULT attribute_rec_const,
  p_interface_attribute_rec IN  arw_cmreq_cover.pq_interface_rec_type DEFAULT
                                                interface_rec_const,
  p_global_attribute_rec    IN  arw_cmreq_cover.pq_global_attribute_rec_type DEFAULT
                                                global_attribute_rec_const,
  p_dispute_date	IN DATE	DEFAULT NULL	,-- Bug 6358930
  p_internal_comment IN VARCHAR2 DEFAULT NULL,
  p_trx_number           IN  ra_customer_trx.trx_number%type   DEFAULT NULL,
  p_gl_date              IN DATE DEFAULT NULL /*Bug 9536019*/
 )
   IS

-- Local Variables
  /*4606558*/
  l_attribute_rec           arw_cmreq_cover.pq_attribute_rec_type ;
  l_interface_attribute_rec arw_cmreq_cover.pq_interface_rec_type;
  l_global_attribute_rec    arw_cmreq_cover.pq_global_attribute_rec_type;
  l_cm_line_tbl             arw_cmreq_cover.Cm_Line_Tbl_Type_Cover;


   l_api_name     	CONSTANT VARCHAR2(20) := 'Create Request';
   l_api_version   	CONSTANT NUMBER       := 1.0;
   l_val_return_status  VARCHAR2(1);
   validation_failed	EXCEPTION;
   creation_failed	EXCEPTION;
   l_status 		VARCHAR2(100) := null;
   l_trx_number         ra_customer_trx.trx_number%type;
   l_org_return_status  VARCHAR2(1);
   l_org_id             NUMBER;

BEGIN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('AR_CREDIT_MEMO_API_PUB.Create_request()+');
       arp_util.debug (  'p_init_msg_list 			:'||p_init_msg_list);
       arp_util.debug (  'p_commit				:'||p_commit);
       arp_util.debug (  'p_validation_level			:'||p_validation_level);
       arp_util.debug (  'p_customer_trx_id 			:'||p_customer_trx_id);
       arp_util.debug (  'p_line_credit_flag			:'||p_line_credit_flag);
       arp_util.debug (  'p_line_amount			:'||p_line_amount);
       arp_util.debug (  'p_tax_amount			:'||p_tax_amount);
       arp_util.debug (  'p_freight_amount			:'||p_freight_amount);
       arp_util.debug (  'p_cm_reason_code			:'||p_cm_reason_code);
   /* Bug 3206020    arp_util.debug (  'p_comments				:'||p_comments);*/
       arp_util.debug (  'p_request_url 			:'||p_request_url);
       arp_util.debug (  'p_transaction_url 			:'||p_transaction_url);
       arp_util.debug (  'p_trans_act_url			:'||p_trans_act_url);
       arp_util.debug (  'p_dispute_date			:'||p_dispute_date); -- Bug 6358930
       arp_util.debug (  'p_gl_date				:'||p_gl_date); /*Bug 9536019*/

       FND_FILE.PUT_LINE(FND_FILE.LOG,'AR_CREDIT_MEMO_API_PUB.Create_request()+');
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_init_msg_list 			:'||p_init_msg_list);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_commit				:'||p_commit);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_validation_level			:'||p_validation_level);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_customer_trx_id 			:'||p_customer_trx_id);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_line_credit_flag			:'||p_line_credit_flag);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_line_amount			:'||p_line_amount);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_tax_amount			:'||p_tax_amount);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_freight_amount			:'||p_freight_amount);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_cm_reason_code			:'||p_cm_reason_code);
   /* Bug 3206020    FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_comments				:'||p_comments);*/
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_request_url 			:'||p_request_url);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_transaction_url 			:'||p_transaction_url);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_trans_act_url			:'||p_trans_act_url);
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_dispute_date			:'||p_dispute_date); -- Bug 6358930
       FND_FILE.PUT_LINE(FND_FILE.LOG,  'p_gl_date				:'||p_gl_date); /*Bug 9536019*/
	   
	   
   END IF;

    /*------------------------------------+
    |    Standard start of API savepoint  |
    +------------------------------------*/

    SAVEPOINT Create_request_pvt;

   /*--------------------------------------------------+
    |   Standard call to check for call compatibility  |
    +--------------------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'Checking call compatibility');
    END IF;
    IF NOT FND_API.Compatible_API_Call( l_api_version,
                                        p_api_version,
                                        l_api_name,
                                        G_PKG_NAME) THEN
       RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

   /*--------------------------------------------------------------+
    |   Initialize message list if p_init_msg_list is set to TRUE  |
    +--------------------------------------------------------------*/

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'Initializing message list');
    END IF;
    IF FND_API.to_Boolean( p_init_msg_list ) THEN
       FND_MSG_PUB.initialize;
    END IF;

   /*-----------------------------------------+
    |   Initialize return status to SUCCESS   |
    +-----------------------------------------*/

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'Initializing return status to success');
    END IF;
    x_return_status := FND_API.G_RET_STS_SUCCESS;

   /*---------------------------------------------+
    |   ========== Start of API Body ==========   |
    +---------------------------------------------*/

   -- Begin SSA change
   l_org_id            := p_org_id;
   l_org_return_status := FND_API.G_RET_STS_SUCCESS;
   ar_mo_cache_utils.set_org_context_in_api
   (
     p_org_id =>l_org_id,
     p_return_status =>l_org_return_status
   );
   -- End SSA change
   -- ORASHID 26-FEB-2004

 IF l_org_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
 ELSE


   /*------------------------------------------+
    |  Validate the receipt information.       |
    |  Do not continue if there are errors.    |
    +------------------------------------------*/

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'Validating request parameters');
    END IF;
  /*4606558*/
  l_attribute_rec:=p_attribute_rec;
  l_interface_attribute_rec:=p_interface_attribute_rec;
  l_global_attribute_rec:=p_global_attribute_rec;
  l_cm_line_tbl:=p_cm_line_tbl;

  IF nvl(p_skip_workflow_flag,'N') = 'Y' THEN
     l_trx_number := p_trx_number;
  ELSE
     l_trx_number := NULL;
  END IF;
  /*Validating for trx number here to avoid changes in existing code*/

    validate_request_parameters (
                 p_customer_trx_id     =>	p_customer_trx_id,
                 p_line_credit_flag    => 	p_line_credit_flag,
                 p_line_amount         => 	p_line_amount,
                 p_tax_amount          => 	p_tax_amount,
                 p_freight_amount      => 	p_freight_amount,
                 p_cm_reason_code      => 	p_cm_reason_code,
                 p_comments            => 	p_comments,
                 p_request_url         => 	p_request_url,
                 p_transaction_url     => 	p_transaction_url,
                 p_trans_act_url       => 	p_trans_act_url,
                 p_cm_line_tbl         =>       l_cm_line_tbl,
                 p_org_id              =>       l_org_id,
                 l_val_return_status   =>       l_val_return_status,
		 /*4606558*/
                 p_skip_workflow_flag  =>       p_skip_workflow_flag,
                 p_batch_source_name   =>       p_batch_source_name,
                 p_trx_number          =>       l_trx_number,
                 p_attribute_rec       =>       l_attribute_rec,
                 p_interface_attribute_rec =>   l_interface_attribute_rec,
                 p_global_attribute_rec    =>   l_global_attribute_rec,
		 p_dispute_date		=>	p_dispute_date	-- Bug 6358930
		 );

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'Done with validate_request_parameters');
    END IF;

    IF l_val_return_status <> FND_API.G_RET_STS_SUCCESS THEN
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug (  'Failed validation routine. Raising exception');
       END IF;
       raise validation_failed;
    ELSE
       -- call the entity handler
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug (  'will call arw_cmreq_cover.ar_request_cm');
       END IF;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'--Before Calling ARW_CMREQ_COVER.AR_REQUEST_CM--');
       x_request_id := arw_cmreq_cover.ar_request_cm(
                               p_customer_trx_id      	    =>  p_customer_trx_id,
                               p_line_credits_flag    	    =>  p_line_credit_flag,
                               p_line_amount	      	    =>  p_line_amount,
                               p_tax_amount	      	    =>  p_tax_amount,
                               p_freight_amount       	    =>  p_freight_amount,
                               p_cm_lines_tbl	      	    =>  p_cm_line_tbl,
                               p_cm_reason_code       	    =>  p_cm_reason_code,
                               p_comments	      	    =>  p_comments,
                               p_url		      	    =>  p_request_url,
			       p_transaction_url     	    =>  p_transaction_url,
                               p_trans_act_url 	      	    =>  p_trans_act_url,
			       p_orig_trx_number            =>  p_orig_trx_number,
			       p_tax_ex_cert_num      	    =>  p_tax_ex_cert_num ,
                               p_skip_workflow_flag         =>  p_skip_workflow_flag ,
                               p_trx_number                 =>  l_trx_number,
                               p_credit_method_installments =>  p_credit_method_installments ,
                               p_credit_method_rules  	    =>  p_credit_method_rules ,
                               p_batch_source_name          =>  p_batch_source_name,
			       /*4606558*/
     			       pq_attribute_rec             =>  l_attribute_rec,
     			       pq_interface_attribute_rec   =>  l_interface_attribute_rec,
     			       pq_global_attribute_rec      =>  l_global_attribute_rec,
			       p_dispute_date		    =>	p_dispute_date,	-- Bug 6358930
			       p_internal_comment       => p_internal_comment,  /*7367350*/
			       p_gl_date		    =>  p_gl_date /*Bug 9536019*/
			       );

       -- bug 2290738 : arw_cmreq_cover.ar_request_cm will pass -1 if any error is encountered
       if x_request_id = '-1' then
          FND_FILE.PUT_LINE(FND_FILE.LOG,'--Failure encountered in AR_CREDIT_MEMO_API_PUB.Create_request call to arw_cmreq_cover.ar_request_cm');
          FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Failure encountered in AR_CREDIT_MEMO_API_PUB.Create_request' ||
                                               ' call to arw_cmreq_cover.ar_request_cm');
          FND_MSG_PUB.Add;
          raise creation_failed;
       end if;

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug (  'Done with arw_cmreq_cover.ar_request_cm');
       END IF;

    END IF;
END IF;

    /*--------------------------------+
     |   Standard check of p_commit   |
     +--------------------------------*/

    IF FND_API.To_Boolean( p_commit ) THEN
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(  'committing');
       END IF;
       Commit;
    END IF;

    IF jg_zz_ar_trx_pkg.is_reg_loc_enabled  THEN
           arp_util.debug('calling: jg_zz_ar_trx_pkg.is_reg_loc_enabled');
        DECLARE
           temp_customer_trx_id ra_customer_trx_all.customer_trx_id%type;
           p_return_flag      boolean;
           p_return_code      number;
           p_return_message   varchar2(1024);
        BEGIN
            select cm_customer_trx_id into temp_customer_trx_id from  ra_cm_requests where customer_trx_id = p_customer_trx_id
                        and request_id=x_request_id;

             jg_zz_ar_trx_pkg.do_trx_complete(null,temp_customer_trx_id,'CMAPI',p_return_flag, p_return_code,p_return_message);

             IF  (p_return_flag = FALSE)  THEN
                  arp_util.debug('Creating the Credit memo in Complete Status ');
                  arp_util.debug('Issue at the time of signature generation for localization');
                  arp_util.debug('Message : '||p_return_message);
                   x_msg_data := p_return_message;
                   x_return_status :=FND_API.G_RET_STS_ERROR;

             END IF;
          EXCEPTION
          WHEN OTHERS THEN
          arp_util.debug (' error from jg_zz_ar_trx_pkg.is_reg_loc_enabled Call');

        END;
        arp_util.debug(' Exiting from PT Code Hook');
     END IF;

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('AR_CREDIT_MEMO_API_PUB.Create_request()-');
    END IF;

EXCEPTION
WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'Exception FND_API.G_EXC_UNEXPECTED_ERROR');
       arp_util.debug(  SQLERRM, G_MSG_ERROR);
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in ARW_CMREQ_COVER.AR_REQUEST_CM: ' || SQLERRM);
    END IF;
    ROLLBACK TO Create_request_PVT;
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

    --  Display_Parameters;
    FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                              p_count       =>      x_msg_count,
                              p_data        =>      x_msg_data);

WHEN creation_failed THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'Exception creation_failed');
       arp_util.debug(  SQLERRM, G_MSG_ERROR);
    END IF;
    -- ROLLBACK TO Create_request_cm;
    x_return_status := FND_API.G_RET_STS_ERROR;

    --  Display_Parameters;
    FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                              p_count       =>      x_msg_count,
                              p_data        =>      x_msg_data);

WHEN validation_failed THEN
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'Exception validation_failed');
       arp_util.debug(  SQLERRM, G_MSG_ERROR);
    END IF;
    ROLLBACK TO Create_request_PVT;
    /* bug 2290738 - returns the validation status, rather than the 'unexpected' status  */
    x_return_status := l_val_return_status;

    --  Display_Parameters;
    FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                              p_count       =>      x_msg_count,
                              p_data        =>      x_msg_data);

WHEN OTHERS THEN

    /*-------------------------------------------------------+
     |  Handle application errors that result from trapable  |
     |  error conditions. The error messages have already    |
     |  been put on the error stack.                         |
     +-------------------------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'Exception OTHERS');
    END IF;
    ROLLBACK TO Create_request_pvt;

    --If only one error message on the stack, retrieve it

    x_return_status := FND_API.G_RET_STS_ERROR ;

    FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
    FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','AR_CREDIT_MEMO_API_PUB.Create_request');
    FND_MSG_PUB.Add;

    FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                              p_count  =>  x_msg_count,
                              p_data   => x_msg_data);

END create_request;

/*old one*/
PROCEDURE validate_request_parameters (
    p_customer_trx_id      IN  ra_customer_trx.customer_trx_id%type,
    p_line_credit_flag     IN  VARCHAR2,
    p_line_amount          IN  NUMBER,
    p_tax_amount           IN  NUMBER,
    p_freight_amount       IN  NUMBER,
    p_cm_reason_code       IN  VARCHAR2,
    p_comments             IN  VARCHAR2,
    p_request_url          IN  VARCHAR2,
    p_transaction_url      IN  VARCHAR2,
    p_trans_act_url        IN  VARCHAR2,
    p_cm_line_tbl          IN  Cm_Line_Tbl_Type_Cover%type,
    p_org_id               IN NUMBER DEFAULT NULL,
    l_val_return_status    OUT NOCOPY VARCHAR2,
    p_dispute_date	   IN  DATE DEFAULT NULL) -- Bug 6358930
 IS

-- Local Variables

l_allow_overapplication         VARCHAR2(1);
l_lines_remaining		NUMBER;
l_tax_remaining 		NUMBER;
l_freight_remaining		NUMBER;
l_lines_original		NUMBER;
l_tax_original    		NUMBER;
l_line_percent 			NUMBER;
l_tax_percent 	    		NUMBER;
l_count_reason_code 		NUMBER;
l_extended_amount		NUMBER;
l_credited_amount		NUMBER :=0 ;
l_count_trx			NUMBER;
l_credit_memo_type_id		NUMBER;
l_org_return_status             VARCHAR2(1);
l_org_id                        NUMBER;
l_trx_date			DATE;

BEGIN

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('AR_CREDIT_MEMO_API_PUB.validate_request_parameters()+');
    END IF;
   /*-----------------------------------------+
    |  Validating customer_trx_id             |
    +-----------------------------------------*/

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'Validating customer_trx_id');
    END IF;

    -- Begin SSA change
    l_org_id            := p_org_id;
    l_org_return_status := FND_API.G_RET_STS_SUCCESS;
    ar_mo_cache_utils.set_org_context_in_api
    (
      p_org_id =>l_org_id,
      p_return_status =>l_org_return_status
    );
    -- End SSA change
    -- ORASHID 26-FEB-2004

    select count(*) into l_count_trx from
    ra_customer_trx
    where customer_trx_id = p_customer_trx_id;

    -- If customer trx is invalid
    IF l_count_trx = 0 THEN
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(  'Did not find customer_trx_id');
       END IF;
       -- Put error message on stack
       FND_MESSAGE.SET_NAME('AR','AR_TAPI_TRANS_NOT_EXIST');
       FND_MESSAGE.SET_TOKEN('CUSTOMER_TRX_ID',p_customer_trx_id);

       FND_MSG_PUB.Add;
       l_val_return_status := FND_API.G_RET_STS_ERROR ;
       return;
    END IF;

    /*-----------------------------------------+
    |  Validating line_credit_flag             |
    +-----------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'Validating line_credit_flag');
    END IF;
    IF p_line_credit_flag not in ('Y','L','N') THEN
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug (  'Invalid line_credit_flag');
       END IF;
       FND_MESSAGE.SET_NAME('AR','AR_CMWF_API_INVALID_VALUE');
       FND_MSG_PUB.Add;
       l_val_return_status := FND_API.G_RET_STS_ERROR ;
       return;
    ELSE
    /* If dispute is at line level, there has to be atleast one line */
       IF p_line_credit_flag = 'Y' AND p_cm_line_tbl.count = 0 THEN
	  IF PG_DEBUG in ('Y', 'C') THEN
	     arp_util.debug (  'line_credit_flag is Y and there are no lines');
	  END IF;
          l_val_return_status := FND_API.G_RET_STS_ERROR ;
          FND_MESSAGE.SET_NAME('AR','AR_CMWF_API_NO_LINES_INFO ');
          FND_MSG_PUB.Add;
          return;
       END IF;
    END IF;

    /*--------------------------------------------------------------------+
    | Validating tax, freight and line amounts 				  |
    | Bug 2290738 : also check if this trx type has a default CM trx type |
    +---------------------------------------------------------------------*/
    -- Checking to see if over application is allowed for transaction type
    SELECT ctt.allow_overapplication_flag, ctt.credit_memo_type_id
    INTO   l_allow_overapplication, l_credit_memo_type_id
    FROM   ra_cust_trx_types ctt,
	   ra_customer_trx ct
    WHERE  ct.cust_trx_type_id = ctt.cust_trx_type_id
    AND    ct.customer_trx_id  = p_customer_trx_id;

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'CM trx type id = ' || to_char(l_credit_memo_type_id));
    END IF;
    IF l_credit_memo_type_id IS NULL THEN
       l_val_return_status := FND_API.G_RET_STS_ERROR ;
       FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
       FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error : no CM trx type id defined.');
       FND_MSG_PUB.Add;
       return;
    END IF;

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug(  'Overapplication allowed ? ' || l_allow_overapplication);
    END IF;

    -- Selecting the amount remaining for the transaction
    /* r12 eTax - get amounts original for pct calculation */
    IF p_line_credit_flag = 'N' THEN
       SELECT SUM(NVL(amount_line_items_remaining,0)),
              SUM(NVL(tax_remaining,0)),
	      SUM(NVL(freight_remaining,0)),
              SUM(NVL(amount_line_items_original,0)),
              SUM(NVL(tax_original,0))
       INTO   l_lines_remaining,
	      l_tax_remaining,
	      l_freight_remaining,
	      l_lines_original,
	      l_tax_original
       FROM   ar_payment_schedules ct
       WHERE  ct.customer_trx_id  = p_customer_trx_id ;

       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(  'l_lines_remaining   = ' || to_char(l_lines_remaining));
          arp_util.debug(  'l_tax_remaining     = ' || to_char(l_tax_remaining));
          arp_util.debug(  'l_freight_remaining = ' || to_char(l_freight_remaining));
       END IF;

       -- If over application flag is 'N' and amount remaining is more than amount
       -- requested, then raise error
       -- Bug 2290738
       -- This should be the other way round i.e. error if amount being credited is
       -- greater than amount due remaining, so signs must be flipped on the former

  /*-------------------------------------------------------------------------+
   | Bug # 2768573: The following piece of code will throw an error to
   | the iReceivable user if user requests a credit memo for an amount
   | that is more than the balance remaining and the over application is
   | turned not allowed.
   |
   | Although, this is a correct validation to happen, it shuld not
   | happen here.  When the actual credit memo is being created, this
   | validation happens again (arw_cm_cover.create_header_cm), and that
   | is the correct place for it to happen. So, commenting out the
   | validation from here.
   |
   | ORASHID 17-FEB-2003
   +-------------------------------------------------------------------------*/

/*
       IF l_allow_overapplication = 'N' THEN

          IF (((p_line_amount * -1) > l_lines_remaining) OR
	      ((p_tax_amount * -1) > l_tax_remaining)     OR
	      ((p_freight_amount * -1) > l_freight_remaining)) THEN
   	     IF PG_DEBUG in ('Y', 'C') THEN
   	        arp_util.debug(  'Over application flag is N and amount remaining is more than amount requested');
   	     END IF;

             l_val_return_status := FND_API.G_RET_STS_ERROR ;
	     FND_MESSAGE.SET_NAME('AR','AR_CKAP_OVERAPP');
             FND_MSG_PUB.Add;
             return;
          END IF;
       END IF;
*/

    END IF;

    /* R12 eTax line and tax percents must be the same if not zero */
    l_line_percent := ROUND( ((p_line_amount * -1 / l_lines_original) * 100), 4);
    l_tax_percent := ROUND( ((p_tax_amount * -1 / l_tax_original) * 100), 4);

    IF (NVL(l_tax_percent,0) <> 0 AND
        NVL(l_line_percent,0) <> 0 AND
        NVL(l_line_percent,0) <> NVL(l_tax_percent,0)) THEN
        FND_MESSAGE.set_name( 'AR', 'AR_ETX_BAD_CM_LINE_TAX_RATIO');
        FND_MSG_PUB.Add;
	RETURN;
    END IF;

    /*-----------------------------------------+
    | Validating the reason_code	       |
    +-----------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'Validating the reason code');
    END IF;
    SELECT
	count(*)
    INTO
	l_count_reason_code
    FROM
	ar_lookups
    WHERE    lookup_type ='CREDIT_MEMO_REASON'
    AND      lookup_code = p_cm_reason_code ;

    IF l_count_reason_code = 0 THEN
       l_val_return_status := FND_API.G_RET_STS_ERROR ;
       FND_MESSAGE.SET_NAME('AR','AR_RAXTRX-1719');
       FND_MSG_PUB.Add;
       return;
    END IF;

    /*-------------------------------------------------+
    | Validating the line when dispute is at line level|
    +--------------------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'Validating the line when dispute is at line level');
    END IF;

    IF p_line_credit_flag = 'Y' THEN

       FOR i in 1..p_cm_line_tbl.count
       LOOP
	  SELECT count(*)
            INTO l_count_trx
            FROM ra_customer_trx_lines
           WHERE customer_trx_id    = p_customer_trx_id
             AND customer_trx_line_id = p_cm_line_tbl(i).customer_trx_line_id;

          IF l_count_trx = 0 THEN
             IF PG_DEBUG in ('Y', 'C') THEN
                arp_util.debug ('validate_request_parameters: ' || 'Transaction does not exist');
             END IF;
             FND_MESSAGE.SET_NAME('AR','AR_TAPI_LINE_NOT_EXIST');
	     FND_MESSAGE.SET_TOKEN('CUSTOMER_TRX_LINE_ID',p_cm_line_tbl(i).customer_trx_line_id);
             FND_MSG_PUB.Add;
             l_val_return_status := FND_API.G_RET_STS_ERROR ;
             return;
          END IF;

  /*-------------------------------------------------------------------------+
   | Bug # 2768573: The following piece of code will throw an error to
   | the iReceivable user if user requests a credit memo for an amount
   | that is more than the balance remaining and the over application is
   | turned not allowed.
   |
   | Although, this is a correct validation to happen, it shuld not
   | happen here.  When the actual credit memo is being created, this
   | validation happens again (arw_cm_cover.create_header_cm), and that
   | is the correct place for it to happen. So, commenting out the
   | validation from here.
   |
   | ORASHID 17-FEB-2003
   +-------------------------------------------------------------------------*/

/*
          IF l_allow_overapplication = 'N' THEN
	     IF PG_DEBUG in ('Y', 'C') THEN
	        arp_util.debug ('validate_request_parameters: ' || 'This transaction type does not  allow over application');
	     END IF;
             -- Get the extended amount for the customer_trx_line_id
	     SELECT NVL(extended_amount,0)
	       INTO l_extended_amount
	       FROM ra_customer_trx_lines
	      WHERE customer_trx_id = p_customer_trx_id
	        AND customer_trx_line_id = p_cm_line_tbl(i).customer_trx_line_id;

	     -- Get the credited amount, if any, for this customer_trx_line
	     SELECT NVL(extended_amount,0)
	       INTO l_credited_amount
	       FROM ra_customer_trx_lines
	      WHERE previous_customer_trx_id = p_customer_trx_id
                AND previous_customer_trx_line_id = p_cm_line_tbl(i).customer_trx_line_id;

 	     IF p_cm_line_tbl(i).extended_amount > (l_extended_amount - l_credited_amount) THEN
		IF PG_DEBUG in ('Y', 'C') THEN
		   arp_util.debug('validate_request_parameters: ' || 'Over application is not allowed. raising exception');
		END IF;
		FND_MESSAGE.SET_NAME('AR','AR_CKAP_OVERAPP');
                FND_MSG_PUB.Add;
                l_val_return_status := FND_API.G_RET_STS_ERROR ;
                return;
	     END IF;
          END IF;
*/
       END LOOP;
    END IF;

-- START Bug 6358930
    /*--------------------------------------------------+
    | Validating the dispute date			|
    +--------------------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug (  'Validating the dispute date passed');
    END IF;
    IF p_dispute_date IS NOT NULL THEN
    SELECT trx_date INTO l_trx_date
    FROM   ra_customer_trx
    WHERE customer_trx_id = p_customer_trx_id;

    -- If dispute date is less than trxn date
    IF trunc(l_trx_date) > trunc(p_dispute_date) THEN
       IF PG_DEBUG in ('Y', 'C') THEN
          arp_util.debug(  'Dispute date is less than transaction date');
       END IF;
       -- Put error message on stack
       FND_MESSAGE.SET_NAME ('AR','AR_DISPUTE_BEFORE_TRX_DATE');
       FND_MSG_PUB.Add;
       l_val_return_status := FND_API.G_RET_STS_ERROR ;
       return;
    END IF;

    END IF;
-- END Bug 6358930
    l_val_return_status :=  FND_API.G_RET_STS_SUCCESS;
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('AR_CREDIT_MEMO_API_PUB.Validate_request_parameters()-');
    END IF;

EXCEPTION
WHEN OTHERS THEN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Exception : Others in validate_request_parameters');
   END IF;
END validate_request_parameters;

PROCEDURE get_request_status (
    -- standard API parameters
    p_api_version       IN  NUMBER,
    p_init_msg_list     IN  VARCHAR2 := FND_API.G_FALSE,
    x_msg_count         OUT NOCOPY NUMBER,
    x_msg_data          OUT NOCOPY VARCHAR2,
    x_return_status 	OUT NOCOPY VARCHAR2,
    -- CREDIT MEMO REQUEST PARAMETERS
    p_request_id  	IN varchar2,
    x_status_meaning	OUT NOCOPY varchar2,
    x_reason_meaning	OUT NOCOPY varchar2,
    x_customer_trx_id	OUT NOCOPY ra_customer_trx.customer_trx_id%type,
    x_cm_customer_trx_id   OUT NOCOPY ra_customer_trx.customer_trx_id%type,
    x_line_amount	OUT NOCOPY ra_cm_requests.line_amount%type,
    x_tax_amount	OUT NOCOPY ra_cm_requests.tax_amount%type,
    x_freight_amount	OUT NOCOPY ra_cm_requests.freight_amount%type,
    x_line_credits_flag	OUT NOCOPY varchar2,
    x_created_by	OUT NOCOPY wf_users.display_name%type,
    x_creation_date	OUT NOCOPY DATE,
    x_approval_date     OUT NOCOPY DATE,
    x_comments	        OUT NOCOPY ra_cm_requests.comments%type,
    x_cm_line_tbl	OUT NOCOPY Cm_Line_Tbl_Type_Cover%type,
    x_cm_activity_tbl	OUT NOCOPY x_cm_activity_tbl%type,
    x_cm_notes_tbl      OUT NOCOPY x_cm_notes_tbl%type)

 IS

-- Local variables
l_api_version   CONSTANT    NUMBER := 1.0;
l_api_name      	     VARCHAR2(100) := 'Get Request Status';
l_reason_code  	     VARCHAR2(240);
l_created_by                VARCHAR2(240);
l_line_count		     NUMBER;
l_count_activities  	     NUMBER;
l_count_notes		     NUMBER;

CURSOR per_user_cur is
    SELECT display_name
    FROM   wf_users
    WHERE  orig_system = 'PER'
    AND    orig_system_id = l_created_by;

CURSOR fnd_user_cur is
    SELECT  display_name
    FROM    wf_users
    WHERE   orig_system = 'FND_USR'
    AND     orig_system_id = l_created_by;

CURSOR line_det_cur is
    SELECT customer_trx_line_id,
	   extended_amount,
	   quantity,
	   price
    FROM   ra_cm_request_lines_all
    WHERE  request_id = p_request_id;

line_det_rec   line_det_cur%rowtype;

CURSOR activities_cur is
	SELECT  to_char(ias.begin_date,'DD-MON-RR HH24:MI:SS') begin_date ,
		ap.display_name||'/'||ac.display_name activity_name ,
		ias.activity_status status,
		ias.activity_result_code result_code,
		ias.assigned_user -- user
	FROM  	wf_item_activity_statuses ias,
		wf_process_activities pa,
		wf_activities_vl ac,
		wf_activities_vl ap,
		wf_items i
	WHERE   ias.item_type		= 'ARCMREQ'
	AND	ias.item_key		= p_request_id
	AND	ias.process_activity 	= pa.instance_id
	AND	pa.activity_name	= ac.name
	AND	pa.activity_item_type	= ac.item_type
	AND	pa.process_name		= ap.name
	AND	pa.process_item_type	= ap.item_type
	AND	i.item_key		= ias.item_key
	AND 	i.begin_date		>=ac.begin_date
	AND	i.begin_date		< nvl(ac.end_date, i.begin_date+1)
	ORDER BY ias.begin_date,ias.execution_time;

	activities_rec	activities_cur%rowtype;

 CURSOR notes_cur is
	SELECT text
	FROM   ar_notes
	WHERE  customer_trx_id = x_customer_trx_id;

	notes_rec 	notes_cur%rowtype;

p_line_credits_flag   VARCHAR2(3);
l_request_id 	       NUMBER;

BEGIN

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('AR_CREDIT_MEMO_API_PUB.Get_request_status()+');
       arp_util.debug ('get_request_status: ' || 'p_init_msg_list 			:'||p_init_msg_list);
       arp_util.debug ('get_request_status: ' || 'p_api_version  			:'||p_api_version);
       arp_util.debug ('get_request_status: ' || 'p_request_id 			:'||p_request_id);
    END IF;

   /*--------------------------------------------------+
    |   Standard call to check for call compatibility  |
    +--------------------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('get_request_status: ' || 'Standard call to check for call compatibility');
    END IF;
    IF NOT FND_API.Compatible_API_Call( l_api_version,
                                        p_api_version,
                                        l_api_name,
                                        G_PKG_NAME)
    THEN
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

   /*--------------------------------------------------------------+
    |   Initialize message list if p_init_msg_list is set to TRUE  |
    +--------------------------------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('get_request_status: ' || 'Initializing message list');
    END IF;
    IF FND_API.to_Boolean( p_init_msg_list ) THEN
       FND_MSG_PUB.initialize;
    END IF;

   /*-----------------------------------------+
    |   Initialize return status to SUCCESS   |
    +-----------------------------------------*/

    x_return_status := FND_API.G_RET_STS_SUCCESS;

   /*---------------------------------------------+
    |   ========== Start of API Body ==========   |
    +---------------------------------------------*/

   /*---------------------------------------------+
    |      ===Validate the request_id===          |
    +---------------------------------------------*/
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('get_request_status: ' || 'Validating the request_id');
    END IF;
    BEGIN
	SELECT customer_trx_id,
	       cm_customer_trx_id,
   	       cm_reason_code,
	       nvl(line_amount,0),
	       nvl(tax_amount,0),
	       nvl(freight_amount,0),
	       line_credits_flag,
	       created_by,
	       creation_date,
	       approval_date,
	       comments
	INTO   x_customer_trx_id,
	       x_cm_customer_trx_id,
	       l_reason_code,
	       x_line_amount,
	       x_tax_amount,
	       x_freight_amount,
	       x_line_credits_flag,
	       l_created_by,
	       x_creation_date,
	       x_approval_date,
	       x_comments
	FROM   ra_cm_requests
	WHERE  request_id = p_request_id;

        p_line_credits_flag := x_line_credits_flag;

       /* bug 2290738 : check if x_cm_customer_trx_id is null that means the CM was not created
          raise an error */

       if x_cm_customer_trx_id is null then
          x_return_status := FND_API.G_RET_STS_ERROR;
          FND_MESSAGE.SET_NAME( 'AR','GENERIC_MESSAGE');
          FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','Error : Could not find credit memo, unknown failure.');
          FND_MSG_PUB.ADD;
          FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                    p_count       =>      x_msg_count,
                                    p_data        =>      x_msg_data);
          return;
       end if;

    EXCEPTION
    WHEN no_data_found THEN
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
       FND_MESSAGE.SET_NAME( 'AR','AR_CMWF_API_INVALID_REQUEST_ID');
       FND_MESSAGE.SET_TOKEN('REQUEST_ID',p_request_id);
       FND_MSG_PUB.ADD;

       --  Display_Parameters;

       FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                 p_count       =>      x_msg_count,
                                 p_data        =>      x_msg_data);
   END;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug ('get_request_status: ' || 'Selecting the meaning for the credit memo dispute from ar_lookups');
   END IF;
   SELECT meaning
   INTO   x_reason_meaning
   FROM   ar_lookups
   WHERE  lookup_type='CREDIT_MEMO_REASON'
   AND    lookup_code = l_reason_code;

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug ('get_request_status: ' || 'Selecting user information');
   END IF;
   IF ( l_created_by <> -1)  THEN
      OPEN per_user_cur;
      FETCH per_user_cur INTO x_created_by;
      IF per_user_cur%NOTFOUND THEN
         x_created_by := null;
         CLOSE per_user_cur;
         OPEN fnd_user_cur;
         FETCH fnd_user_cur INTO x_created_by;
         IF fnd_user_cur%notfound THEN
            CLOSE fnd_user_cur;
	 END IF;
      END IF;
   END IF;

   -- Getting the line details
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug ('get_request_status: ' || 'Selecting line details');
   END IF;

   IF p_line_credits_flag = 'Y' THEN
        SELECT count(*)
	INTO   l_line_count
	FROM ra_cm_request_lines
	WHERE request_id = p_request_id;

	OPEN line_det_cur;
	FOR i in 1..(l_line_count)
	LOOP
	   FETCH line_det_cur INTO line_det_rec;
	   x_cm_line_tbl(i).customer_trx_line_id := line_det_rec.customer_trx_line_id;
	   x_cm_line_tbl(i).extended_amount      := line_det_rec.extended_amount;
	   x_cm_line_tbl(i).quantity_credited    := line_det_rec.quantity;
	   x_cm_line_tbl(i).price		       := line_det_rec.price;
  	END LOOP;
	CLOSE line_det_cur;

   END IF;

    -- Getting the activities details

   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug ('get_request_status: ' || 'Getting the activities details');
   END IF;
   SELECT count(*)
   INTO   l_count_activities
   FROM   wf_item_activity_statuses ias,
          wf_process_activities pa,
	  wf_activities_vl ac,
	  wf_activities_vl ap,
          wf_items i
    WHERE ias.item_type		= 'ARCMREQ'
    AND	ias.item_key		= p_request_id
    AND	ias.process_activity 	= pa.instance_id
    AND	pa.activity_name	= ac.name
    AND	pa.activity_item_type	= ac.item_type
    AND	pa.process_name		= ap.name
    AND	pa.process_item_type	= ap.item_type
    AND	i.item_key		= ias.item_key
    AND i.begin_date		>=ac.begin_date
    AND	i.begin_date		< nvl(ac.end_date, i.begin_date+1);

    OPEN activities_cur;
    FOR j in 1..l_count_activities
    LOOP
       FETCH activities_cur into activities_rec;
       x_cm_activity_tbl(j).activity_name := activities_rec.activity_name;
       x_cm_activity_tbl(j).status	   := activities_rec.status;
       x_cm_activity_tbl(j).result_code   := activities_rec.result_code;
       x_cm_activity_tbl(j).user	   := activities_rec.assigned_user;
    END LOOP;
    CLOSE activities_cur;

   -- Getting the notes text
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug ('get_request_status: ' || 'Getting the notes text');
   END IF;
   SELECT count(*)
   INTO   l_count_notes
   FROM   ar_notes
   WHERE  customer_trx_id = x_customer_trx_id;

   OPEN notes_cur;
   FOR k in 1..l_count_notes
   LOOP
      FETCH notes_cur into notes_rec;
      x_cm_notes_tbl(k).notes		 := notes_rec.text;
      EXIT WHEN notes_cur%notfound;
   END LOOP;
   CLOSE notes_cur;

   x_return_status := FND_API.G_RET_STS_SUCCESS;
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug ('AR_CREDIT_MEMO_API_PUB.get_request_status()-');
   END IF;

   EXCEPTION
   WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      IF PG_DEBUG in ('Y', 'C') THEN
         arp_util.debug('get_request_status : unexpected error');
         arp_util.debug('get_request_status: ' || SQLERRM, G_MSG_ERROR);
      END IF;
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

      --  Display_Parameters;
      FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                                p_count       =>      x_msg_count,
                                p_data        =>      x_msg_data);

   WHEN OTHERS THEN
      /*-------------------------------------------------------+
       |  Handle application errors that result from trapable  |
       |  error conditions. The error messages have already    |
       |  been put on the error stack.                         |
       +-------------------------------------------------------*/
     IF PG_DEBUG in ('Y', 'C') THEN
        arp_util.debug ('get_request_status: ' || 'Exception OTHERS');
     END IF;
     x_return_status := FND_API.G_RET_STS_ERROR ;
     FND_MESSAGE.SET_NAME ('AR','GENERIC_MESSAGE');
     FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','AR_CREDIT_MEMO_API_PUB.Get_request_status');

     --  Display_Parameters;
     FND_MSG_PUB.Count_And_Get(p_encoded => FND_API.G_FALSE,
                               p_count  =>  x_msg_count,
                               p_data   => x_msg_data);

END get_request_status;

-- This procedure will print a default message if the calling program does not
-- pass the urls to display the request, transaction and activities information
-- in the notifications.

PROCEDURE print_default_page IS

default_message varchar2(240);

BEGIN

   FND_MESSAGE.SET_NAME ('AR','AR_REPORTS_UNAVAILABLE');
   default_message := FND_MESSAGE.GET;
   HTP.P (default_message);

END print_default_page;

/*NEW ONE OVER LOADED FOR 4606558*/
PROCEDURE validate_request_parameters (
    p_customer_trx_id      IN  ra_customer_trx.customer_trx_id%type,
    p_line_credit_flag     IN  VARCHAR2,
    p_line_amount          IN  NUMBER,
    p_tax_amount           IN  NUMBER,
    p_freight_amount       IN  NUMBER,
    p_cm_reason_code       IN  VARCHAR2,
    p_comments             IN  VARCHAR2,
    p_request_url          IN  VARCHAR2,
    p_transaction_url      IN  VARCHAR2,
    p_trans_act_url        IN  VARCHAR2,
    p_cm_line_tbl          IN OUT NOCOPY  Cm_Line_Tbl_Type_Cover%type,
    p_org_id               IN NUMBER DEFAULT NULL,
    l_val_return_status    OUT NOCOPY VARCHAR2,
    /*4556000*/
    p_skip_workflow_flag   IN   VARCHAR2,
    p_batch_source_name    IN   VARCHAR2,
    p_trx_number           IN   ra_customer_trx.trx_number%type  DEFAULT NULL,
    p_attribute_rec           IN OUT NOCOPY arw_cmreq_cover.pq_attribute_rec_type,
    p_interface_attribute_rec IN OUT NOCOPY arw_cmreq_cover.pq_interface_rec_type,
    p_global_attribute_rec    IN OUT NOCOPY arw_cmreq_cover.pq_global_attribute_rec_type,
    p_dispute_date	   IN  DATE DEFAULT NULL) -- Bug 6358930
 IS

-- Local Variables
/*4556000*/
l_ct_trx			ra_customer_trx%rowtype;
x_return_status			VARCHAR2(1);
p_desc_flex_rec         arp_util.attribute_rec_type;
l_copy_inv_tidff_flag   	VARCHAR2(1);
interface_line_rec      interface_line_rec_type;
L_TRX_NO_ERR            VARCHAR2(1);
BEGIN

    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('AR_CREDIT_MEMO_API_PUB.validate_request_parameters(OVERLOADED)+');
       arp_util.debug ('Batch source name :  ' || p_batch_source_name);
    END IF;
/*2404776*/
    IF nvl(p_skip_workflow_flag,'N') = 'Y' THEN
      arp_util.debug ('Before validating trx number');
      BEGIN
        SELECT 'Y' INTO l_trx_no_err
        FROM   ra_batch_sources b
        WHERE  b.name = p_batch_source_name
        AND   ((p_trx_number IS NULL AND
               NVL(b.auto_trx_numbering_flag,'N') = 'N')
        OR     (p_trx_number IS NOT NULL AND
               b.auto_trx_numbering_flag = 'Y'));

        fnd_message.set_name('AR', 'AR_INAPI_TRX_NUM_NOT_REQUIRED');
        FND_MSG_PUB.Add;
        l_val_return_status:=FND_API.G_RET_STS_ERROR;
        return;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          IF PG_DEBUG in ('Y', 'C') THEN
             arp_util.debug ('Error at time of validating for trx number' || sqlerrm);
          END IF;
          l_val_return_status:=FND_API.G_RET_STS_ERROR;
          return;
        END;
    END IF;
    arp_util.debug ('Before old validate_request_parameters');
    /*Still call old procedure*/
    validate_request_parameters (
                 p_customer_trx_id     =>	p_customer_trx_id,
                 p_line_credit_flag    => 	p_line_credit_flag,
                 p_line_amount         => 	p_line_amount,
                 p_tax_amount          => 	p_tax_amount,
                 p_freight_amount      => 	p_freight_amount,
                 p_cm_reason_code      => 	p_cm_reason_code,
                 p_comments            => 	p_comments,
                 p_request_url         => 	p_request_url,
                 p_transaction_url     => 	p_transaction_url,
                 p_trans_act_url       => 	p_trans_act_url,
                 p_cm_line_tbl         =>       p_cm_line_tbl,
		 p_org_id 	       =>       p_org_id,
                 l_val_return_status   =>       l_val_return_status,
		 p_dispute_date	       =>	p_dispute_date);

    /*4556000*/
    IF l_val_return_status <>  FND_API.G_RET_STS_SUCCESS then
	l_val_return_status:=FND_API.G_RET_STS_ERROR;
        IF PG_DEBUG in ('Y', 'C') THEN
           arp_util.debug ('AR_CREDIT_MEMO_API_PUB.Validate_request_parameters returned error');
        END IF;
	return;
    END IF;

    select * into l_ct_trx from
    ra_customer_trx
    where customer_trx_id = p_customer_trx_id;

    IF p_line_credit_flag = 'Y' AND NVL(p_skip_workflow_flag,'N')='Y' THEN

       FOR i in 1..p_cm_line_tbl.count
       LOOP
	  /*4556000 Flex field validation for line level*/
	  interface_line_rec.interface_line_context:=p_cm_line_tbl(i).interface_line_context;
	  interface_line_rec.interface_line_attribute1:=p_cm_line_tbl(i).interface_line_attribute1;
	  interface_line_rec.interface_line_attribute2:=p_cm_line_tbl(i).interface_line_attribute2;
	  interface_line_rec.interface_line_attribute3:=p_cm_line_tbl(i).interface_line_attribute3;
	  interface_line_rec.interface_line_attribute4:=p_cm_line_tbl(i).interface_line_attribute4;
	  interface_line_rec.interface_line_attribute5:=p_cm_line_tbl(i).interface_line_attribute5;
	  interface_line_rec.interface_line_attribute6:=p_cm_line_tbl(i).interface_line_attribute6;
	  interface_line_rec.interface_line_attribute7:=p_cm_line_tbl(i).interface_line_attribute7;
	  interface_line_rec.interface_line_attribute8:=p_cm_line_tbl(i).interface_line_attribute8;
	  interface_line_rec.interface_line_attribute9:=p_cm_line_tbl(i).interface_line_attribute9;
	  interface_line_rec.interface_line_attribute10:=p_cm_line_tbl(i).interface_line_attribute10;
	  interface_line_rec.interface_line_attribute11:=p_cm_line_tbl(i).interface_line_attribute11;
	  interface_line_rec.interface_line_attribute12:=p_cm_line_tbl(i).interface_line_attribute12;
	  interface_line_rec.interface_line_attribute13:=p_cm_line_tbl(i).interface_line_attribute13;
	  interface_line_rec.interface_line_attribute14:=p_cm_line_tbl(i).interface_line_attribute14;
	  interface_line_rec.interface_line_attribute15:=p_cm_line_tbl(i).interface_line_attribute15;

            Validate_Line_Int_Flex(
                p_desc_flex_rec       => interface_line_rec,
                p_desc_flex_name      => 'RA_INTERFACE_LINES',
                p_return_status       => x_return_status );
            IF x_return_status <>  FND_API.G_RET_STS_SUCCESS
            THEN
		  IF PG_DEBUG in ('Y', 'C') THEN
                     arp_util.debug ( 'Err. Line Transaction FF Validation');
                  END IF;
                  FND_MESSAGE.SET_NAME('AR','AR_INAPI_INVALID_DESC_FLEX');
                  FND_MESSAGE.SET_TOKEN('CUSTOMER_TRX_LINE_ID',p_cm_line_tbl(i).customer_trx_line_id);
                  FND_MSG_PUB.Add;
                  l_val_return_status := FND_API.G_RET_STS_ERROR ;
                  return;
            END IF;
	    p_cm_line_tbl(i).interface_line_context:=interface_line_rec.interface_line_context;
	    p_cm_line_tbl(i).interface_line_attribute1:=interface_line_rec.interface_line_attribute1;
	    p_cm_line_tbl(i).interface_line_attribute2:=interface_line_rec.interface_line_attribute2;
	    p_cm_line_tbl(i).interface_line_attribute3:=interface_line_rec.interface_line_attribute3;
	    p_cm_line_tbl(i).interface_line_attribute4:=interface_line_rec.interface_line_attribute4;
	    p_cm_line_tbl(i).interface_line_attribute5:=interface_line_rec.interface_line_attribute5;
	    p_cm_line_tbl(i).interface_line_attribute6:=interface_line_rec.interface_line_attribute6;
	    p_cm_line_tbl(i).interface_line_attribute7:=interface_line_rec.interface_line_attribute7;
	    p_cm_line_tbl(i).interface_line_attribute8:=interface_line_rec.interface_line_attribute8;
	    p_cm_line_tbl(i).interface_line_attribute9:=interface_line_rec.interface_line_attribute9;
	    p_cm_line_tbl(i).interface_line_attribute10:=interface_line_rec.interface_line_attribute10;
	    p_cm_line_tbl(i).interface_line_attribute11:=interface_line_rec.interface_line_attribute11;
	    p_cm_line_tbl(i).interface_line_attribute12:=interface_line_rec.interface_line_attribute12;
	    p_cm_line_tbl(i).interface_line_attribute13:=interface_line_rec.interface_line_attribute13;
	    p_cm_line_tbl(i).interface_line_attribute14:=interface_line_rec.interface_line_attribute14;
	    p_cm_line_tbl(i).interface_line_attribute15:=interface_line_rec.interface_line_attribute15;


	  p_desc_flex_rec.attribute_category:=p_cm_line_tbl(i).attribute_category;
	  p_desc_flex_rec.attribute1:=p_cm_line_tbl(i).attribute1;
	  p_desc_flex_rec.attribute2:=p_cm_line_tbl(i).attribute2;
	  p_desc_flex_rec.attribute3:=p_cm_line_tbl(i).attribute3;
	  p_desc_flex_rec.attribute4:=p_cm_line_tbl(i).attribute4;
	  p_desc_flex_rec.attribute5:=p_cm_line_tbl(i).attribute5;
	  p_desc_flex_rec.attribute6:=p_cm_line_tbl(i).attribute6;
	  p_desc_flex_rec.attribute7:=p_cm_line_tbl(i).attribute7;
	  p_desc_flex_rec.attribute8:=p_cm_line_tbl(i).attribute8;
	  p_desc_flex_rec.attribute9:=p_cm_line_tbl(i).attribute9;
	  p_desc_flex_rec.attribute10:=p_cm_line_tbl(i).attribute10;
	  p_desc_flex_rec.attribute11:=p_cm_line_tbl(i).attribute11;
	  p_desc_flex_rec.attribute12:=p_cm_line_tbl(i).attribute12;
	  p_desc_flex_rec.attribute13:=p_cm_line_tbl(i).attribute13;
	  p_desc_flex_rec.attribute14:=p_cm_line_tbl(i).attribute14;
	  p_desc_flex_rec.attribute15:=p_cm_line_tbl(i).attribute15;

	     arp_util.Validate_Desc_Flexfield(
                p_desc_flex_rec       => p_desc_flex_rec,
                p_desc_flex_name      => 'RA_CUSTOMER_TRX_LINES',
                p_return_status       => x_return_status );

            IF x_return_status <>  FND_API.G_RET_STS_SUCCESS
            THEN
		  IF PG_DEBUG in ('Y', 'C') THEN
                     arp_util.debug ( 'Err. Line Information FF Validation');
                  END IF;
                  FND_MESSAGE.SET_NAME('AR','AR_INAPI_INVALID_DESC_FLEX');
                  FND_MESSAGE.SET_TOKEN('CUSTOMER_TRX_LINE_ID',p_cm_line_tbl(i).customer_trx_line_id);
                  FND_MSG_PUB.Add;
                  l_val_return_status := FND_API.G_RET_STS_ERROR ;
                  return;
            END IF;
	  p_cm_line_tbl(i).attribute_category:=p_desc_flex_rec.attribute_category;
	  p_cm_line_tbl(i).attribute1:=p_desc_flex_rec.attribute1;
	  p_cm_line_tbl(i).attribute2:=p_desc_flex_rec.attribute2;
	  p_cm_line_tbl(i).attribute3:=p_desc_flex_rec.attribute3;
	  p_cm_line_tbl(i).attribute4:=p_desc_flex_rec.attribute4;
	  p_cm_line_tbl(i).attribute5:=p_desc_flex_rec.attribute5;
	  p_cm_line_tbl(i).attribute6:=p_desc_flex_rec.attribute6;
	  p_cm_line_tbl(i).attribute7:=p_desc_flex_rec.attribute7;
	  p_cm_line_tbl(i).attribute8:=p_desc_flex_rec.attribute8;
	  p_cm_line_tbl(i).attribute9:=p_desc_flex_rec.attribute9;
	  p_cm_line_tbl(i).attribute10:=p_desc_flex_rec.attribute10;
	  p_cm_line_tbl(i).attribute11:=p_desc_flex_rec.attribute11;
	  p_cm_line_tbl(i).attribute12:=p_desc_flex_rec.attribute12;
	  p_cm_line_tbl(i).attribute13:=p_desc_flex_rec.attribute13;
	  p_cm_line_tbl(i).attribute14:=p_desc_flex_rec.attribute14;
	  p_cm_line_tbl(i).attribute15:=p_desc_flex_rec.attribute15;

       END LOOP;
    END IF;
	  /*4556000*/
	  /*Flex field validation incorporated here*/
         /* bug fix 5583733, Validate RA_INTERFACE_HEADER only when the user has passed values for the flexfield*/
	 if p_interface_attribute_rec.interface_header_context is NULL then
	    p_interface_attribute_rec.interface_header_context:=l_ct_trx.interface_header_context;
	    p_interface_attribute_rec.interface_header_attribute1:=l_ct_trx.interface_header_attribute1;
	    p_interface_attribute_rec.interface_header_attribute2:=l_ct_trx.interface_header_attribute2;
	    p_interface_attribute_rec.interface_header_attribute3:=l_ct_trx.interface_header_attribute3;
	    p_interface_attribute_rec.interface_header_attribute4:=l_ct_trx.interface_header_attribute4;
	    p_interface_attribute_rec.interface_header_attribute5:=l_ct_trx.interface_header_attribute5;
	    p_interface_attribute_rec.interface_header_attribute6:=l_ct_trx.interface_header_attribute6;
	    p_interface_attribute_rec.interface_header_attribute7:=l_ct_trx.interface_header_attribute7;
	    p_interface_attribute_rec.interface_header_attribute8:=l_ct_trx.interface_header_attribute8;
	    p_interface_attribute_rec.interface_header_attribute9:=l_ct_trx.interface_header_attribute9;
	    p_interface_attribute_rec.interface_header_attribute10:=l_ct_trx.interface_header_attribute10;
	    p_interface_attribute_rec.interface_header_attribute11:=l_ct_trx.interface_header_attribute11;
	    p_interface_attribute_rec.interface_header_attribute12:=l_ct_trx.interface_header_attribute12;
	    p_interface_attribute_rec.interface_header_attribute13:=l_ct_trx.interface_header_attribute13;
	    p_interface_attribute_rec.interface_header_attribute14:=l_ct_trx.interface_header_attribute14;
	    p_interface_attribute_rec.interface_header_attribute15:=l_ct_trx.interface_header_attribute15;

        ELSE

	  IF NVL(p_skip_workflow_flag,'N')='Y' THEN
	    Validate_int_Desc_Flex(
                p_desc_flex_rec       => p_interface_attribute_rec,
                p_desc_flex_name      => 'RA_INTERFACE_HEADER',
                p_return_status       => x_return_status );

              IF x_return_status <>  FND_API.G_RET_STS_SUCCESS
              THEN
		    IF PG_DEBUG in ('Y', 'C') THEN
                       arp_util.debug ( 'Err. Invoice Transaction FF Validation');
                    END IF;
                    FND_MESSAGE.SET_NAME('AR','AR_INAPI_INVALID_DESC_FLEX');
                    FND_MESSAGE.SET_TOKEN('CUSTOMER_TRX_ID',p_customer_trx_id);
                    FND_MSG_PUB.Add;
                    l_val_return_status := FND_API.G_RET_STS_ERROR ;
                    return;
              END IF;
	  END IF;
       END IF;

	  BEGIN
             SELECT NVL(COPY_INV_TIDFF_TO_CM_FLAG,'N') into l_copy_inv_tidff_flag
	     FROM ra_batch_sources where name=p_batch_source_name;
	  EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	       BEGIN
             	SELECT NVL(COPY_INV_TIDFF_TO_CM_FLAG,'N') into l_copy_inv_tidff_flag
	     	FROM ra_batch_sources where batch_source_id=l_ct_trx.batch_source_id;
	       EXCEPTION
	         WHEN NO_DATA_FOUND THEN
                  FND_MESSAGE.SET_NAME('AR','AR_INAPI_INVALID_BATCH_SOURCE');
                  FND_MESSAGE.SET_TOKEN('CUSTOMER_TRX_ID',p_customer_trx_id);
                  FND_MSG_PUB.Add;
                  l_val_return_status := FND_API.G_RET_STS_ERROR ;
                  return;
	       END;
	  END;

	     p_desc_flex_rec.attribute_category:=p_attribute_rec.attribute_category;
	     p_desc_flex_rec.attribute1:=p_attribute_rec.attribute1;
	     p_desc_flex_rec.attribute2:=p_attribute_rec.attribute2;
	     p_desc_flex_rec.attribute3:=p_attribute_rec.attribute3;
	     p_desc_flex_rec.attribute4:=p_attribute_rec.attribute4;
	     p_desc_flex_rec.attribute5:=p_attribute_rec.attribute5;
	     p_desc_flex_rec.attribute6:=p_attribute_rec.attribute6;
	     p_desc_flex_rec.attribute7:=p_attribute_rec.attribute7;
	     p_desc_flex_rec.attribute8:=p_attribute_rec.attribute8;
	     p_desc_flex_rec.attribute9:=p_attribute_rec.attribute9;
	     p_desc_flex_rec.attribute10:=p_attribute_rec.attribute10;
	     p_desc_flex_rec.attribute11:=p_attribute_rec.attribute11;
	     p_desc_flex_rec.attribute12:=p_attribute_rec.attribute12;
	     p_desc_flex_rec.attribute13:=p_attribute_rec.attribute13;
	     p_desc_flex_rec.attribute14:=p_attribute_rec.attribute14;
	     p_desc_flex_rec.attribute15:=p_attribute_rec.attribute15;

	  IF p_desc_flex_rec.attribute_category is NULL AND l_copy_inv_tidff_flag='Y' then
	     p_desc_flex_rec.attribute_category:=l_ct_trx.attribute_category;
	     p_desc_flex_rec.attribute1:=l_ct_trx.attribute1;
	     p_desc_flex_rec.attribute2:=l_ct_trx.attribute2;
	     p_desc_flex_rec.attribute3:=l_ct_trx.attribute3;
	     p_desc_flex_rec.attribute4:=l_ct_trx.attribute4;
	     p_desc_flex_rec.attribute5:=l_ct_trx.attribute5;
	     p_desc_flex_rec.attribute6:=l_ct_trx.attribute6;
	     p_desc_flex_rec.attribute7:=l_ct_trx.attribute7;
	     p_desc_flex_rec.attribute8:=l_ct_trx.attribute8;
	     p_desc_flex_rec.attribute9:=l_ct_trx.attribute9;
	     p_desc_flex_rec.attribute10:=l_ct_trx.attribute10;
	     p_desc_flex_rec.attribute11:=l_ct_trx.attribute11;
	     p_desc_flex_rec.attribute12:=l_ct_trx.attribute12;
	     p_desc_flex_rec.attribute13:=l_ct_trx.attribute13;
	     p_desc_flex_rec.attribute14:=l_ct_trx.attribute14;
	     p_desc_flex_rec.attribute15:=l_ct_trx.attribute15;
          END IF;
	  IF NVL(p_skip_workflow_flag,'N')='Y' THEN
	     arp_util.Validate_Desc_Flexfield(
                p_desc_flex_rec       => p_desc_flex_rec,
                p_desc_flex_name      => 'RA_CUSTOMER_TRX',
                p_return_status       => x_return_status );

            IF x_return_status <>  FND_API.G_RET_STS_SUCCESS
            THEN
		  IF PG_DEBUG in ('Y', 'C') THEN
                     arp_util.debug ( 'Err. Transaction Information FF Validation');
                  END IF;
                  FND_MESSAGE.SET_NAME('AR','AR_INAPI_INVALID_DESC_FLEX');
                  FND_MESSAGE.SET_TOKEN('CUSTOMER_TRX_ID',p_customer_trx_id);
                  FND_MSG_PUB.Add;
                  l_val_return_status := FND_API.G_RET_STS_ERROR ;
                  return;
            END IF;
	  END IF;
	     p_attribute_rec.attribute_category:=p_desc_flex_rec.attribute_category;
	     p_attribute_rec.attribute1:=p_desc_flex_rec.attribute1;
	     p_attribute_rec.attribute2:=p_desc_flex_rec.attribute2;
	     p_attribute_rec.attribute3:=p_desc_flex_rec.attribute3;
	     p_attribute_rec.attribute4:=p_desc_flex_rec.attribute4;
	     p_attribute_rec.attribute5:=p_desc_flex_rec.attribute5;
	     p_attribute_rec.attribute6:=p_desc_flex_rec.attribute6;
	     p_attribute_rec.attribute7:=p_desc_flex_rec.attribute7;
	     p_attribute_rec.attribute8:=p_desc_flex_rec.attribute8;
	     p_attribute_rec.attribute9:=p_desc_flex_rec.attribute9;
	     p_attribute_rec.attribute10:=p_desc_flex_rec.attribute10;
	     p_attribute_rec.attribute11:=p_desc_flex_rec.attribute11;
	     p_attribute_rec.attribute12:=p_desc_flex_rec.attribute12;
	     p_attribute_rec.attribute13:=p_desc_flex_rec.attribute13;
	     p_attribute_rec.attribute14:=p_desc_flex_rec.attribute14;
	     p_attribute_rec.attribute15:=p_desc_flex_rec.attribute15;

    l_val_return_status :=  FND_API.G_RET_STS_SUCCESS;
    IF PG_DEBUG in ('Y', 'C') THEN
       arp_util.debug ('AR_CREDIT_MEMO_API_PUB.Validate_request_parameters(OVERLOADED)-');
    END IF;

EXCEPTION
WHEN OTHERS THEN
   IF PG_DEBUG in ('Y', 'C') THEN
      arp_util.debug('Exception : Others in validate_request_parameters(OVERLOADED)');
   END IF;
END validate_request_parameters;

/*4556000*/
PROCEDURE Validate_Int_Desc_Flex(
    p_desc_flex_rec       IN OUT NOCOPY  arw_cmreq_cover.pq_interface_rec_type,
    p_desc_flex_name      IN VARCHAR2,
    p_return_status       IN OUT NOCOPY  varchar2
                         ) IS

l_flex_name     fnd_descriptive_flexs.descriptive_flexfield_name%type;
l_count         NUMBER;
l_col_name     VARCHAR2(50);
l_flex_exists  VARCHAR2(1);
CURSOR desc_flex_exists IS
  SELECT 'Y'
  FROM fnd_descriptive_flexs
  WHERE application_id = 222
    and descriptive_flexfield_name = p_desc_flex_name;
BEGIN
      IF PG_DEBUG = 'Y' THEN
         ar_invoice_utils.debug('' || 'AR_CREDIT_MEMO_API_PUB.Validate_Int_Desc_Flex ()+');
      END IF;
      p_return_status := FND_API.G_RET_STS_SUCCESS;

      OPEN desc_flex_exists;
      FETCH desc_flex_exists INTO l_flex_exists;
      IF desc_flex_exists%NOTFOUND THEN
       CLOSE desc_flex_exists;
       p_return_status :=  FND_API.G_RET_STS_ERROR;
       return;
      END IF;
      CLOSE desc_flex_exists;

    IF p_desc_flex_name = 'RA_INTERFACE_HEADER'
    THEN
        fnd_flex_descval.set_context_value(p_desc_flex_rec.interface_header_context);

        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE1',
                                p_desc_flex_rec.interface_header_attribute1);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE2',
                                p_desc_flex_rec.interface_header_attribute2);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE3',
                                p_desc_flex_rec.interface_header_attribute3);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE4',
                                p_desc_flex_rec.interface_header_attribute4);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE5',
                                p_desc_flex_rec.interface_header_attribute5);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE6',
                                p_desc_flex_rec.interface_header_attribute6);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE7',
                                p_desc_flex_rec.interface_header_attribute7);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE8',
                                p_desc_flex_rec.interface_header_attribute8);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE9',
                                p_desc_flex_rec.interface_header_attribute9);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE10',
                                p_desc_flex_rec.interface_header_attribute10);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE11',
                                p_desc_flex_rec.interface_header_attribute11);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE12',
                                p_desc_flex_rec.interface_header_attribute12);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE13',
                                p_desc_flex_rec.interface_header_attribute13);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE14',
                                p_desc_flex_rec.interface_header_attribute14);
        fnd_flex_descval.set_column_value('INTERFACE_HEADER_ATTRIBUTE15',
                                p_desc_flex_rec.interface_header_attribute15);


        IF ( NOT fnd_flex_descval.validate_desccols('AR',p_desc_flex_name,'I') )
        THEN
            p_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

        l_count := fnd_flex_descval.segment_count;


        FOR i in 1..l_count LOOP
            l_col_name := fnd_flex_descval.segment_column_name(i);

            IF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE1' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute1 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_CONTEXT'  THEN
                p_desc_flex_rec.interface_header_context := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE2' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute2 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE3' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute3 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE4' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute4 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE5' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute5 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE6' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute6 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE7' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute7 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE8' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute8 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE9' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute9 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE10' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute10 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE11' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute11 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE12' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute12 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE13' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute13 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE14' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute14 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_HEADER_ATTRIBUTE15' THEN
                p_desc_flex_rec.INTERFACE_HEADER_attribute15 := fnd_flex_descval.segment_id(i);
            END IF;

            IF i > l_count  THEN
                EXIT;
            END IF;
        END LOOP;
    END IF;

END Validate_Int_Desc_Flex;

/*4556000*/
PROCEDURE Validate_Line_Int_Flex(
    p_desc_flex_rec         IN OUT NOCOPY  interface_line_rec_type,
    p_desc_flex_name        IN VARCHAR2,
    p_return_status         IN OUT NOCOPY  varchar2
                         ) IS

l_flex_name     fnd_descriptive_flexs.descriptive_flexfield_name%type;
l_count         NUMBER;
l_col_name     VARCHAR2(50);
l_flex_exists  VARCHAR2(1);
CURSOR desc_flex_exists IS
  SELECT 'Y'
  FROM fnd_descriptive_flexs
  WHERE application_id = 222
    and descriptive_flexfield_name = p_desc_flex_name;
BEGIN
      IF PG_DEBUG = 'Y' THEN
         ar_invoice_utils.debug('' || 'AR_CREDIT_MEMO_API_PUB.Validate_LINE_Int_Flex ()+');
      END IF;
      p_return_status := FND_API.G_RET_STS_SUCCESS;

      OPEN desc_flex_exists;
      FETCH desc_flex_exists INTO l_flex_exists;
      IF desc_flex_exists%NOTFOUND THEN
       CLOSE desc_flex_exists;
       p_return_status :=  FND_API.G_RET_STS_ERROR;
       return;
      END IF;
      CLOSE desc_flex_exists;

    IF p_desc_flex_name = 'RA_INTERFACE_LINES'
    THEN
        fnd_flex_descval.set_context_value(p_desc_flex_rec.interface_line_context);

        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE1',
                                p_desc_flex_rec.interface_line_attribute1);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE2',
                                p_desc_flex_rec.interface_line_attribute2);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE3',
                                p_desc_flex_rec.interface_line_attribute3);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE4',
                                p_desc_flex_rec.interface_line_attribute4);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE5',
                                p_desc_flex_rec.interface_line_attribute5);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE6',
                                p_desc_flex_rec.interface_line_attribute6);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE7',
                                p_desc_flex_rec.interface_line_attribute7);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE8',
                                p_desc_flex_rec.interface_line_attribute8);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE9',
                                p_desc_flex_rec.interface_line_attribute9);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE10',
                                p_desc_flex_rec.interface_line_attribute10);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE11',
                                p_desc_flex_rec.interface_line_attribute11);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE12',
                                p_desc_flex_rec.interface_line_attribute12);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE13',
                                p_desc_flex_rec.interface_line_attribute13);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE14',
                                p_desc_flex_rec.interface_line_attribute14);
        fnd_flex_descval.set_column_value('INTERFACE_LINE_ATTRIBUTE15',
                                p_desc_flex_rec.interface_line_attribute15);


        IF ( NOT fnd_flex_descval.validate_desccols('AR',p_desc_flex_name,'I') )
        THEN
            p_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

        l_count := fnd_flex_descval.segment_count;


        FOR i in 1..l_count LOOP
            l_col_name := fnd_flex_descval.segment_column_name(i);

            IF l_col_name = 'INTERFACE_LINE_ATTRIBUTE1' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute1 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_CONTEXT'  THEN
                p_desc_flex_rec.interface_LINE_context := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE2' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute2 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE3' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute3 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE4' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute4 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE5' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute5 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE6' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute6 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE7' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute7 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE8' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute8 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE9' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute9 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE10' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute10 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE11' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute11 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE12' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute12 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE13' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute13 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE14' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute14 := fnd_flex_descval.segment_id(i);
            ELSIF l_col_name = 'INTERFACE_LINE_ATTRIBUTE15' THEN
                p_desc_flex_rec.INTERFACE_LINE_attribute15 := fnd_flex_descval.segment_id(i);
            END IF;

            IF i > l_count  THEN
                EXIT;
            END IF;
        END LOOP;
    END IF;

END Validate_Line_Int_Flex;

END AR_CREDIT_MEMO_API_PUB;
/