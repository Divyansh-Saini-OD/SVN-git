create or replace
PACKAGE "XX_CS_CONC_PKG" AS

PROCEDURE GET_AQ_MSG( x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode    OUT  NOCOPY  NUMBER );

PROCEDURE ROUTE_DC_QUEUE( x_errbuf     OUT  NOCOPY  VARCHAR2
                        , x_retcode    OUT  NOCOPY  NUMBER );

PROCEDURE GET_EMAIL_RES( x_errbuf     OUT  NOCOPY  VARCHAR2
                       , x_retcode    OUT  NOCOPY  NUMBER );

PROCEDURE GET_CANCEL_ORD( x_errbuf     OUT  NOCOPY  VARCHAR2
                        , x_retcode    OUT  NOCOPY  NUMBER );
                        
PROCEDURE TDS_PARTS_ITEMS( X_ERRBUF     OUT NOCOPY VARCHAR2
                          , X_RETCODE   OUT NOCOPY NUMBER
                          , P_SR_NUMBER IN VARCHAR2);
                          
PROCEDURE TDS_PARTS_OUTBOUND (X_ERRBUF  OUT NOCOPY VARCHAR2
                            , X_RETCODE OUT NOCOPY NUMBER
                            , P_SR_NUMBER IN VARCHAR2
                            , P_DOC_TYPE IN VARCHAR2);
                            
PROCEDURE SUBSCRIPTION_REQ ( x_errbuf     OUT  NOCOPY  VARCHAR2
                    , x_retcode    OUT  NOCOPY  NUMBER );
                    

PROCEDURE SMB_UPDATE ( x_errbuf     OUT  NOCOPY  VARCHAR2
                      , x_retcode    OUT  NOCOPY  NUMBER 
                      , p_request_number IN varchar2
                      , p_cust_name IN VARCHAR2
                      , p_action    IN VARCHAR2
                      , p_skus      IN VARCHAR2
                      , p_units     IN number) ;
                        

END;
/