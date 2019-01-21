SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XXCDH_CUSTEMAILFMT_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXCDH_CUSTEMAILFMT_PKG                                    |
-- | Description      : Package Specification containing procedure to  | 
-- |                    validate customer email address                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  | 
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   27-NOV-2006   Nabarun Ghosh    Initial draft version    |
-- |                                                                   |
-- +===================================================================+

--Declare a Exception used globally
g_invalid_email_add_exp  EXCEPTION;

--This Function will be used to validate customer email format.
PROCEDURE Validate_Customer_Email_Format(
    p_contact_points_rec IN OUT NOCOPY HZ_CONTACT_POINT_V2PUB.contact_point_rec_type,
    p_edi_rec            IN OUT NOCOPY HZ_CONTACT_POINT_V2PUB.edi_rec_type,
    p_email_rec          IN OUT NOCOPY HZ_CONTACT_POINT_V2PUB.email_rec_type,
    p_phone_rec          IN OUT NOCOPY HZ_CONTACT_POINT_V2PUB.phone_rec_type,
    p_telex_rec          IN OUT NOCOPY HZ_CONTACT_POINT_V2PUB.telex_rec_type,
    p_web_rec            IN OUT NOCOPY HZ_CONTACT_POINT_V2PUB.web_rec_type,
    x_return_status      IN OUT NOCOPY VARCHAR2,
    x_msg_count          OUT    NOCOPY NUMBER,
    x_msg_data           OUT    NOCOPY VARCHAR2 );


END XXCDH_CUSTEMAILFMT_PKG;
/
SHOW ERRORS;
EXIT;
