create or replace
PACKAGE xx_cs_contracts_pkg AS
-- +==============================================================================================+
-- |                            Office Depot - Project Simplify                                   |
-- |                                    Office Depot                                              |
-- +==============================================================================================+
-- | Name  : XX_CS_CONTRACTS_PKG.pks                                                              |
-- | Description  : This package contains procedures related to Service Contracts creation        |
-- |Change Record:                                                                                |
-- |===============                                                                               |
-- |Version    Date          Author             Remarks                                           |
-- |=======    ==========    =================  ==================================================|
-- |1.0        15-AUG-2012   Bapuji Nanapaneni  Initial version                                   |
-- |                                                                                              |
-- +==============================================================================================+

  g_org_id       CONSTANT NUMBER := FND_PROFILE.VALUE('ORG_ID');

  -- +=====================================================================+
  -- | Name  : create_contract                                             |
  -- | Description      : This Procedure will create Service Contract      |
  -- |                                                                     |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_party_id      IN NUMBER party ID               |
  -- |                    p_sales_rep_id  IN VARCHAR2 Sales Rep Name       |
  -- |                    p_contract_type IN VARCHAR2 Contact Type         |
  -- |                    p_contract_rec  IN XX_CS_MPS_CONTRACT_REC_TYPE   |
  -- |                    x_return_status IN OUT VARCHAR2 Return status    |
  -- |                    x_return_msg    IN OUT VARCHAR2 Return Message   |
  -- |                    x_contract_num  IN OUT VARCHAR2 Contract Number  |
  -- +=====================================================================+
  PROCEDURE create_contract ( p_party_id       IN NUMBER
                            , p_sales_rep_id   IN VARCHAR2
                            , p_contract_type  IN VARCHAR2
                            , p_contract_rec   IN XX_CS_MPS_CONTRACT_REC_TYPE
                            , x_contract_num   IN OUT VARCHAR2
                            , x_return_status  IN OUT VARCHAR2
                            , x_return_mesg    IN OUT VARCHAR2
                            );

  -- +=====================================================================+
  -- | Name  : create_contract_lin                                         |
  -- | Description      : This Procedure will create Service Contract line |
  -- |                                                                     |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_header_id        IN NUMBER ID                  |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                    x_service_line_id  OUT VARCHAR2 Contract Number  |
  -- +=====================================================================+
  PROCEDURE create_contract_lin ( p_header_id        IN NUMBER
                                , x_return_status   OUT VARCHAR2
                                , x_return_mesg     OUT VARCHAR2
                                , x_service_line_id OUT NUMBER
                                );


  -- +=====================================================================+
  -- | Name  : create_contract                                             |
  -- | Description      : This Procedure will derive bill to site id       |
  -- |                                                                     |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_party_id       IN NUMBER   party ID            |
  -- |                    x_site_use_id   OUT VARCHAR2 BILL_TO ID          |
  -- +=====================================================================+

  PROCEDURE get_cust_bill_to ( p_party_id IN NUMBER
                             , x_site_use_id OUT NUMBER
							 );
  -- +===================================================================+
  -- | Name  : Get_contact_id                                            |
  -- | Description : To derive customer id and contact id                |
  -- |                                                                   |
  -- | Parameters  : p_party_id   IN -> pass party_id                    |
  -- |             : x_contact_id OUT -> pass out conatct id             |
  -- |                                                                   |
  -- +===================================================================+
  Procedure Get_contact_id( p_party_id           IN        NUMBER
                          , x_contact_id         OUT       NUMBER
						  );

END xx_cs_contracts_pkg;
/
