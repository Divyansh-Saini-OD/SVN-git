SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +======================================================================================+
-- |                  Office Depot - Project Simplify                                     |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
-- +======================================================================================|
-- | Name       : XX_HZ_CONTACT_POINTS_BIR1                                               |
-- | Description: This trigger shall be fired for each row being inserted or updated      |
-- |              on HZ_CONTACT_POINTS table.  This shall call the custom package to      | 
-- |              validate the email id and terminate if there is an error.               |
-- |                                                                                      |
-- |Change Record:                                                                        |
-- |===============                                                                       |
-- |Version   Date         Author           Remarks                                       |
-- |=======   ===========  =============    ==============================================|
-- |DRAFT 1A  25-APR-2007  Prem Kumar B     Initial draft version                         |
-- |1.0       21-Jul-2007  Rajeev Kamath    Move drops to other script                    |
-- +======================================================================================+


SET TERM ON

WHENEVER SQLERROR EXIT 1;

PROMPT
PROMPT Create Trigger XX_HZ_CONTACT_POINTS_BIR1
PROMPT

CREATE TRIGGER XX_HZ_CONTACT_POINTS_BIR1
BEFORE INSERT OR UPDATE OF EMAIL_ADDRESS ON HZ_CONTACT_POINTS
FOR EACH ROW 
DECLARE

   l_contact_points_rec  hz_contact_point_v2pub.contact_point_rec_type;
   l_email_rec           hz_contact_point_v2pub.email_rec_type;
   l_return_status       VARCHAR2(10);
   l_msg_count           NUMBER;
   l_msg_data            VARCHAR2(2000);
   

BEGIN

   l_contact_points_rec.contact_point_type := :new.contact_point_type;
   l_email_rec.email_address               := :new.email_address;

   --
   -- Call the custom package to validate the email id.
   --
   IF ( NVL( FND_PROFILE.VALUE('XX_CDH_CUST_EMAIL_FORMAT'),'N') = 'Y' ) THEN
   
      XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => l_contact_points_rec,
               p_edi_rec            => hz_contact_point_v2pub.g_miss_edi_rec,
               p_email_rec          => l_email_rec,
               p_phone_rec          => hz_contact_point_v2pub.g_miss_phone_rec,
               p_telex_rec          => hz_contact_point_v2pub.g_miss_telex_rec,
               p_web_rec            => hz_contact_point_v2pub.g_miss_web_rec,
               x_return_status      => l_return_status,
               x_msg_count          => l_msg_count,
               x_msg_data           => l_msg_data);

      --
      -- Check for the return status to be error, and raise application error.
      --
      IF NVL(l_return_status,'X') = FND_API.G_RET_STS_ERROR THEN
         RAISE_APPLICATION_ERROR(-20001, fnd_message.get_string('XXCRM','XXOD_INVALID_EMAIL')); 
      END IF;
   
   END IF;
 
END;
/

SHOW ERRORS
EXIT;

