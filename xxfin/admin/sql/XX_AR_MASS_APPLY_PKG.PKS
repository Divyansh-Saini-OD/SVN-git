CREATE OR REPLACE PACKAGE XX_ar_mass_apply
AS
-- +=========================================================================+
-- |                                                  |
-- +=========================================================================+
-- | Name  : XX_ar_mass_apply                                               |
-- | Rice ID: E3116                                                         |
-- | Description      : This Program will extract all the RCC transactions   |
-- |                    into an XML file for RACE                            |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============== =====================================|
-- |1.0     30-JUN-2014 Arun G          Initial draft version                |
-- |2.0     15-JUL-2014 Arun G          Added debug messages/exceptions      |
-- +=========================================================================+

-- +===================================================================+
-- | Name  : extract
-- | Description     : The extract procedure is the main               |
-- |                   procedure that will extract all the unprocessed |
-- |                   records and process them via Oracle API         |
-- |                                                                   |
-- | Parameters      : x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- |                   p_debug_flag        IN -> Debug Flag            |
-- |                   p_status            IN -> Record status         |
-- +===================================================================+

PROCEDURE get_data(p_receipt_number         VARCHAR2,
                   p_customer_number        VARCHAR2,
                   p_orginal_receipt_amount VARCHAR2,        
                   p_invoice_number         VARCHAR2,        
                   p_invoice_amount         VARCHAR2,        
                   p_receipt_date           DATE ,    
                   p_created_by             VARCHAR2);

PROCEDURE extract(x_retcode         OUT NOCOPY     NUMBER,
                  x_errbuf          OUT NOCOPY     VARCHAR2
                  );

END XX_ar_mass_apply;
/


