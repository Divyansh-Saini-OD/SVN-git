create or replace
PACKAGE XX_CS_MPS_G1_VALIDATION_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_G1_VALIDATION_PKG.pks                                                   |
-- | Description  :                                                                               |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        21-MAY-2013   Sreedhar Mohan	    Group1 Address Validations for MPS Customers      |
-- +==============================================================================================+

--check address is valid for the customer
PROCEDURE  validate_address(
              p_errbuf                OUT NOCOPY  VARCHAR2
            , p_retcode               OUT NOCOPY  VARCHAR2
            , p_business_name         IN          VARCHAR2
            , p_address1              IN          VARCHAR2
            , p_address2              IN          VARCHAR2
            , p_city                  IN          VARCHAR2
            , p_state                 IN          VARCHAR2
            , p_postal_code           IN          VARCHAR2
            , p_g1_address1           OUT NOCOPY  VARCHAR2
            , p_g1_address2           OUT NOCOPY  VARCHAR2
            , p_g1_city               OUT NOCOPY  VARCHAR2
            , p_g1_state              OUT NOCOPY  VARCHAR2
            , p_g1_postal_code        OUT NOCOPY  VARCHAR2
            , p_g1_county             OUT NOCOPY  VARCHAR2			
            , p_g1_addr_error         OUT NOCOPY  VARCHAR2
            , p_g1_addr_code          OUT NOCOPY  VARCHAR2
            , p_g1_ws_error           OUT NOCOPY  VARCHAR2
          );

END XX_CS_MPS_G1_VALIDATION_PKG;
/
SHOW ERRORS;
