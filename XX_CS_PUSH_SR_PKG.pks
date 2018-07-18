create or replace
PACKAGE XX_CS_PUSH_SR_PKG AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */
PROCEDURE ASSIGN_SRs (X_ERRBUF      OUT NOCOPY VARCHAR2, 
                        X_RETCODE     OUT NOCOPY NUMBER,
                        P_GROUP_ID  IN NUMBER,
                        P_RESOURCE_ID IN NUMBER, 
                        P_NUMBER      IN NUMBER);
                      
END XX_CS_PUSH_SR_PKG;
/
show errors;
exit;
