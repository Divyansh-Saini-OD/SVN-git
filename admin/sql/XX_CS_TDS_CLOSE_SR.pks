create or replace
PACKAGE XX_CS_TDS_CLOSE_SR AS 

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_CS_TDS_CLOSE_SR Package Specification                                           |
-- |  Description:     OD: TDS Mass Close SR                                                    |
-- |  Description:     OD: TDS Mass Close SR Tasks                                              |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- +============================================================================================+
-- |  Name:  XX_CS_TDS_CLOSE_SR.UPDATE_SRS                                                      |
-- |  Description: This pkg.procedure will close the SRs with a particular status older than    |
-- |  certain number of days.                                                                   |
-- |  Name:  XX_CS_TDS_CLOSE_SR.UPDATE_TASK                                                     |
-- |  Description: This pkg.procedure will close the SR tasks for closed/cancelled SRs.         |
-- =============================================================================================|

PROCEDURE UPDATE_SRS(ERRBUF OUT NOCOPY VARCHAR2,
                      RETCODE OUT NOCOPY NUMBER,
                      p_no_of_days IN NUMBER,
                      p_status IN VARCHAR2,
                      p_sr_number number,
                      p_owner_group_name varchar2);
                      
 PROCEDURE UPDATE_TASK( ERRBUF OUT NOCOPY VARCHAR2,
                      RETCODE OUT NOCOPY NUMBER,
                      p_sr_number number,
                      p_owner_group_name varchar2);
 

END XX_CS_TDS_CLOSE_SR;

/