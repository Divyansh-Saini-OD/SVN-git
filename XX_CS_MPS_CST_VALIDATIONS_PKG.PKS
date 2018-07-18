create or replace
PACKAGE XX_CS_MPS_CST_VALIDATIONS_PKG AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_MPS_CST_VALIDATIONS_PKG.pks                                                   |
-- | Description  :                                                                               |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        21-MAY-2013   Sreedhar Mohan	    Validations for MPS Customers                     |
-- +==============================================================================================+

--check po_number and cost_center are valid for the customer
PROCEDURE  is_cost_ctr_po_nbr_valid(
              p_errbuf                OUT NOCOPY  VARCHAR2
            , p_retcode               OUT NOCOPY  VARCHAR2
            , p_aops_customer_id      IN          NUMBER
            , p_cost_center           IN          VARCHAR2
            , p_po_number             IN          VARCHAR2
            , p_is_valid_cost_center  OUT         VARCHAR2
            , p_is_valid_po           OUT         VARCHAR2
          );

--check po_number and cost_center are valid for the customer
PROCEDURE  is_cost_ctr_po_nbr_valid(
              p_errbuf                OUT NOCOPY  VARCHAR2
            , p_retcode               OUT NOCOPY  VARCHAR2
            , p_aops_customer_id      IN          NUMBER
            , p_cost_center           IN          VARCHAR2
            , p_po_number             IN          VARCHAR2
          );

--Update Cost Center and PO Number to MPS Devices 
PROCEDURE UPDATE_CC_PO_NUMBER(  p_errbuf                OUT NOCOPY VARCHAR2
                              , p_retcode               OUT NOCOPY VARCHAR2
                              , p_aops_cust_id          IN         NUMBER  
                              , p_device_cost_center    IN          VARCHAR2
                              , p_po_number             IN          VARCHAR2
                             );

END XX_CS_MPS_CST_VALIDATIONS_PKG;
/
show errors;