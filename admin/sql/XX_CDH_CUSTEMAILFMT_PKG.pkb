SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_CUSTEMAILFMT_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |                      Oracle NAIO Consulting Organization                                |
-- +=========================================================================================+
-- | Name             : XXCDH_CUSTEMAILFMT_PKG                                               |
-- | Description      : Package Body containing procedure to validate customer email address |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date         Author              Remarks                                      |
-- |=======    ==========   =============       ========================                     |
-- |DRAFT 1A   27-NOV-2006  Nabarun Ghosh       Initial draft version                        |
-- |Draft 1b   16-Apr-2007  Ambarish Mukherjee  Modified to return 'a.b@oracle.com' as       |
-- |                                            a valid email id                             |
-- |Draft 1c   28-Jan-2008  Ambarish Mukherjee  QC#1894, Modified to return 'c@127.0.0.0.1'  |
-- |                                            as invalid email.                            |
-- +=========================================================================================+
   AS

--Declare all the Local variables to be used in procedure
   ln_sp_chr_exists        NUMBER := 0;
   ln_length_email_str     NUMBER := 0;
   ln_first_pos_at         NUMBER := 0;
   ln_second_pos_at        NUMBER := 0;
   ln_dot_pos              NUMBER := 0;
   lc_tld_email_address    VARCHAR2(100);
   ln_ip_first_seg         NUMBER := 0;
   ln_ip_second_seg        NUMBER := 0;
   ln_ip_third_seg         NUMBER := 0;
   ln_ip_fourth_seg        NUMBER := 0;
   ln_tld_exists           NUMBER := 0;
   ln_tld_exists_as_cty_cd NUMBER := 0;
   ln_at_pos               NUMBER := 0;
   ln_dot_rt_pos           NUMBER := 0;
   lv_email_cut            VARCHAR2(500); 
   ln_dot_count            NUMBER := 0;
   le_skip_validation      EXCEPTION;
   
-- +===================================================================+
-- | Name        :         NUM_CHARS                                   |
-- | Description :         This Function will be used to find the      |
-- |                       count of a patterm in a string              |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :         INSTRING, INPATTERN                         |
-- |                                                                   |
-- | Returns     :         error message                               |
-- |                                                                   |
-- +===================================================================+   
   
FUNCTION NUM_CHARS(INSTRING VARCHAR2, INPATTERN VARCHAR2)
RETURN NUMBER
IS
   COUNTER       NUMBER;
   NEXT_INDEX    NUMBER;
   STRING        VARCHAR2(2000);
   PATTERN       VARCHAR2(2000);
BEGIN
   COUNTER    := 0;
   NEXT_INDEX := 1;
   STRING     := LOWER(INSTRING);
   PATTERN    := LOWER(INPATTERN);
   FOR I IN 1 .. LENGTH(STRING) 
   LOOP
      IF (LENGTH(PATTERN) <= LENGTH(STRING)-NEXT_INDEX+1) AND 
         (SUBSTR(STRING,NEXT_INDEX,LENGTH(PATTERN)) = PATTERN) THEN
         COUNTER := COUNTER+1;
      END IF;
      NEXT_INDEX := NEXT_INDEX+1;
   END LOOP;
RETURN COUNTER;
END NUM_CHARS;
   

-- +===================================================================+
-- | Name  : Validate_Customer_Email_Format                            |
-- | Description:       This Procedure will be used to validate        |
-- |                    customer                                       |
-- |                                                                   |
-- |                    email format.                                  |
-- |                                                                   |
-- | Parameters:        p_email_id                                     |
-- |                                                                   |
-- | Returns :          error message                                  |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Validate_Customer_Email_Format (
    p_contact_points_rec    IN OUT NOCOPY   HZ_CONTACT_POINT_V2PUB.contact_point_rec_type,
    p_edi_rec               IN OUT NOCOPY   HZ_CONTACT_POINT_V2PUB.EDI_REC_TYPE,
    p_email_rec             IN OUT NOCOPY   HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE,
    p_phone_rec             IN OUT NOCOPY   HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE,
    p_telex_rec             IN OUT NOCOPY   HZ_CONTACT_POINT_V2PUB.TELEX_REC_TYPE,
    p_web_rec               IN OUT NOCOPY   HZ_CONTACT_POINT_V2PUB.WEB_REC_TYPE,
    x_return_status         IN OUT NOCOPY   VARCHAR2,
    x_msg_count             OUT    NOCOPY   NUMBER,
    x_msg_data              OUT    NOCOPY   VARCHAR2 
)
AS

--Declare a cursor to obtain special characters from lookup table
CURSOR cur_sp_char IS
SELECT lookup_code
FROM   fnd_lookup_values
WHERE  lookup_type  = 'XXOD_EMAIL_SPECIAL_CHARS';

BEGIN

   ----------------------------------------------------
   -- Start Changes BY Ambarish 28-Jan-08

   IF ( NVL( FND_PROFILE.VALUE('XX_CDH_CUST_EMAIL_FORMAT'),'N') = 'N' ) THEN    
      RAISE le_skip_validation;
   END IF;

   -- END Changes BY Ambarish 28-Jan-08
   ----------------------------------------------------

   --Initializing the message pub
   FND_MSG_PUB.initialize;
 
   IF (p_contact_points_rec.contact_point_type =  'EMAIL') THEN
       -- Open cursor to fetching all the special characters
       FOR rec_sp_char IN cur_sp_char
       LOOP
          --Validating if the email address contains any of the special characters
          --Fetched in the cursor.
          BEGIN 
             SELECT INSTR(p_email_rec.email_address,rec_sp_char.lookup_code,1)
             INTO   ln_sp_chr_exists
             FROM   DUAL;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                ln_sp_chr_exists := NULL;
             WHEN OTHERS THEN
                ln_sp_chr_exists := NULL;
          END;   

          IF (ln_sp_chr_exists > 0) THEN
             --If the email address contains any special characters then
             --raise a custom error and exit from the loop.
             RAISE g_invalid_email_add_exp;
             x_return_status := FND_API.G_RET_STS_ERROR;
             EXIT;
          END IF;
       END LOOP;

       -- If the email address does not contain any special characters
       IF ln_sp_chr_exists = 0 THEN

          -- Obtain the entire length of the email address
          ln_length_email_str := LENGTH(p_email_rec.email_address);
        
          -- Obtain the position of the first occurrence of the @
          ln_first_pos_at := INSTR(p_email_rec.email_address,'@',1,1);
        
          -- Obtain the position of the second occurrence of the @ if any
          ln_second_pos_at := INSTR(p_email_rec.email_address,'@',1,2);
        
          -- Obtain the position of the dot
          ln_dot_pos := INSTR(p_email_rec.email_address,'.',1);
          ln_dot_rt_pos := INSTR(p_email_rec.email_address,'.',-1);
        
          -- Obtain the position of the @
          ln_at_pos := INSTR(p_email_rec.email_address,'@',1);
        
          -- Truncate email starting from '@'
          lv_email_cut := SUBSTR (p_email_rec.email_address,ln_at_pos+1,length(p_email_rec.email_address)) ;
        
          ------------------------------------------------------------------------------------
          -- Start Changes Ambarish - 28-Jan
                
          ln_dot_count := NUM_CHARS (lv_email_cut,'.');
                
          IF ln_dot_count > 3 THEN
           
             IF REGEXP_SUBSTR(REPLACE (lv_email_cut,'.',' '),'[1234567890]') IS NOT NULL THEN
                RAISE g_invalid_email_add_exp;
                x_return_status := FND_API.G_RET_STS_ERROR;
             END IF;   
          END IF;
        
          -- END Changes Ambarish - 28-Jan
          ------------------------------------------------------------------------------------
          
          -- Validating @ should not be the last Char
          IF ln_first_pos_at = ln_length_email_str THEN
             RAISE g_invalid_email_add_exp;
             x_return_status := FND_API.G_RET_STS_ERROR;
          END IF;
        
          -- Validating dot should not be the last Char
          IF TRIM (substr(p_email_rec.email_address,length(p_email_rec.email_address),LENGTH(p_email_rec.email_address)))  = '.' THEN
             RAISE g_invalid_email_add_exp;
             x_return_status := FND_API.G_RET_STS_ERROR;
          END IF; 
        
          -- There should not be more than one occurrence of @ in the email address
          IF ln_second_pos_at  > 0 THEN
             RAISE g_invalid_email_add_exp;
             x_return_status := FND_API.G_RET_STS_ERROR;
          END IF;
        
          -- Validating @ should not be the first char of the email
          -- or email address does not contain @
          IF ln_first_pos_at <= 1 THEN
             RAISE g_invalid_email_add_exp;
             x_return_status := FND_API.G_RET_STS_ERROR;
          END IF;        
           
          -- Validating dot should not be the last Char of the email
          IF ln_dot_pos = ln_length_email_str THEN
             RAISE g_invalid_email_add_exp;
             x_return_status := FND_API.G_RET_STS_ERROR;
          END IF;
        
          -- Validating dot should not be the first char of the email.
          IF ln_dot_pos <= 1 THEN
             RAISE g_invalid_email_add_exp;
             x_return_status := FND_API.G_RET_STS_ERROR;
          END IF;       
                                
          lc_tld_email_address := UPPER (SUBSTR ( p_email_rec.email_address,ln_dot_rt_pos+1,length(p_email_rec.email_address)));
       
          --Validating email address TLD from lookup table 
          SELECT COUNT (1)
          INTO   ln_tld_exists
          FROM   fnd_lookup_values
          WHERE  lookup_code = TRIM(lc_tld_email_address)
          AND    lookup_type = 'XXOD_EMAIL_VALIDATION_TLD';
        
          IF ln_tld_exists = 0 THEN
           
             -- Validating if TLD is not available in lookup then,whether TLD should be
             -- a Country Code of 2 chars.
             SELECT COUNT(1) 
             INTO   ln_tld_exists_as_cty_cd
             FROM   fnd_territories_vl fv
             WHERE  UPPER(territory_code) = TRIM(lc_tld_email_address);          
                    
             IF ln_tld_exists_as_cty_cd = 0 THEN
           
                -- Validating if TLD is of type IP address
                -- Obtaining the First segment of the IP-Address
                IF ln_dot_pos > ln_at_pos THEN
                   ln_ip_first_seg :=
                         NVL (RTRIM (
                              SUBSTR (p_email_rec.email_address,
                                 INSTR (p_email_rec.email_address,'@',1,1)+1,
                                 (INSTR (p_email_rec.email_address,'.',1,1)-1) - (INSTR(p_email_rec.email_address,'@',1,1))
                         ), '.'),0);
                ELSIF ln_dot_pos < ln_at_pos AND ln_dot_rt_pos > ln_at_pos THEN

                   ln_ip_first_seg := to_number (
                         NVL (RTRIM (
                              SUBSTR (lv_email_cut,
                                 INSTR (lv_email_cut,'@',1,1)+1,
                                 (INSTR (lv_email_cut,'.',1,1)-1) - (INSTR(lv_email_cut,'@',1,1))
                          ), '.'),0));         
                END IF;      
                    
                -- Validating the first segment of the IP-Address
                IF ln_ip_first_seg*0 <> 0 THEN
                   -- Validate if any special characters in 1st segment.
                   RAISE g_invalid_email_add_exp;
                   x_return_status := FND_API.G_RET_STS_ERROR;
                END IF;
              
                IF ln_ip_first_seg = 0 THEN
                 
                   RAISE g_invalid_email_add_exp;
                   x_return_status := 'E';
                END IF;
              
                IF LENGTH (ln_ip_first_seg) > 3 THEN
                 
                   RAISE g_invalid_email_add_exp;
                   x_return_status := FND_API.G_RET_STS_ERROR;
                END IF;
              
                --Obtaining the Second segment of the IP-Address
                IF ln_dot_pos > ln_at_pos THEN
                   ln_ip_second_seg := 
                        NVL(RTRIM(
                            SUBSTR (p_email_rec.email_address,
                                   INSTR (p_email_rec.email_address,'@',1,1)+LENGTH(ln_ip_first_seg)+2,
                                       (INSTR (p_email_rec.email_address,'.',1,2)-1) - 
                                          (INSTR(p_email_rec.email_address,'@',1,1)+LENGTH(ln_ip_first_seg)+1)
                        ), '.'), 0);
                ELSIF ln_dot_pos < ln_at_pos AND ln_dot_rt_pos > ln_at_pos THEN
                   ln_ip_second_seg := to_number (
                        NVL(RTRIM(
                            SUBSTR (lv_email_cut,
                                   INSTR (lv_email_cut,'@',1,1)+LENGTH(ln_ip_first_seg)+2,
                                       (INSTR (lv_email_cut,'.',1,2)-1) - 
                                          (INSTR(lv_email_cut,'@',1,1)+LENGTH(ln_ip_first_seg)+1)
                        ), '.'), 0));
                END IF;        
                   
                -- Validating the Second segment of the IP-Address
              
                IF ln_ip_first_seg*0 <> 0 THEN
                   --Validate if any special characters in 2nd segment.   
                   RAISE g_invalid_email_add_exp;
                   x_return_status := FND_API.G_RET_STS_ERROR;
                END IF;
              
                IF LENGTH (ln_ip_second_seg) > 3 THEN
                   RAISE g_invalid_email_add_exp;
                END IF;
              
                -- Obtaining the Third segment of the IP-Address
                IF ln_dot_pos > ln_at_pos THEN
                   ln_ip_third_seg := 
                         NVL(RTRIM(
                             SUBSTR (p_email_rec.email_address,
                                INSTR (p_email_rec.email_address,'@',1,1)+LENGTH(ln_ip_first_seg)
                                        +LENGTH(ln_ip_second_seg)+3,
                                   (INSTR (p_email_rec.email_address,'.',1,3)-1) -(INSTR(p_email_rec.email_address,'@',1,1)
                                        +LENGTH(ln_ip_first_seg)+LENGTH(ln_ip_second_seg)+2)
                         ),'.'),0);
                ELSIF ln_dot_pos < ln_at_pos AND ln_dot_rt_pos > ln_at_pos THEN
                   ln_ip_third_seg := to_number (
                                        NVL(RTRIM(
                                            SUBSTR (lv_email_cut,
                                               INSTR (lv_email_cut,'@',1,1)+LENGTH(ln_ip_first_seg)
                                                       +LENGTH(ln_ip_second_seg)+3,
                                                  (INSTR (lv_email_cut,'.',1,3)-1) -(INSTR(lv_email_cut,'@',1,1)
                                                       +LENGTH(ln_ip_first_seg)+LENGTH(ln_ip_second_seg)+2)
                       ),'.'),0));
                END IF;         
                    
                --Validating the Third segment of the IP-Address
                IF ln_ip_first_seg*0 <> 0 THEN
                   --Validate if any special characters in 3rd segment.
                   RAISE g_invalid_email_add_exp;
                   x_return_status := FND_API.G_RET_STS_ERROR;
                END IF;
              
                IF LENGTH(ln_ip_third_seg) > 3 THEN
                 
                   RAISE g_invalid_email_add_exp;
                   x_return_status := 'E';
                END IF;
              
                --Obtaining the Fourth segment of the IP-Address
                IF ln_dot_pos > ln_at_pos THEN
                   ln_ip_fourth_seg := 
                         NVL(RTRIM(
                            SUBSTR(p_email_rec.email_address,
                              INSTR (p_email_rec.email_address,'@',1,1)+LENGTH(ln_ip_first_seg)+
                                      LENGTH(ln_ip_second_seg)+LENGTH(ln_ip_third_seg)+4,
                                         (LENGTH (p_email_rec.email_address)) - (INSTR(p_email_rec.email_address,'@',1,1)+
                                          LENGTH(ln_ip_first_seg)+LENGTH(ln_ip_second_seg)+LENGTH(ln_ip_third_seg)+2)
                       ),'.'),0);
                ELSIF ln_dot_pos < ln_at_pos AND ln_dot_rt_pos > ln_at_pos THEN
                   ln_ip_fourth_seg := to_number (
                                          NVL(RTRIM(
                                              SUBSTR(lv_email_cut,
                                               INSTR (lv_email_cut,'@',1,1)+LENGTH(ln_ip_first_seg)+
                                                       LENGTH(ln_ip_second_seg)+LENGTH(ln_ip_third_seg)+4,
                                                           (LENGTH (lv_email_cut)) - (INSTR(lv_email_cut,'@',1,1)+
                                                             LENGTH(ln_ip_first_seg)+LENGTH(ln_ip_second_seg)+LENGTH(ln_ip_third_seg)+2)
                         ),'.'),0));
                END IF;         
                    
                --Validating the Fourth segment of the IP-Address
                IF ln_ip_first_seg*0 <> 0 THEN
                   --Validate if any special characters in 4th segment.
                   RAISE g_invalid_email_add_exp;
                   x_return_status := FND_API.G_RET_STS_ERROR;
                END IF;
              
                IF LENGTH (ln_ip_fourth_seg) > 3 THEN
                 
                   RAISE g_invalid_email_add_exp;
                   x_return_status := FND_API.G_RET_STS_ERROR;
                END IF;
              
             END IF; -- End validation of TLD as country code
           
         END IF; -- End of validation for TLD, whether exists in Lookup tables or not
       
      END IF;
  
   END IF;
  
EXCEPTION
   WHEN le_skip_validation THEN
      NULL;
   WHEN g_invalid_email_add_exp THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      x_msg_data      := 'Invalid mail format';
   WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_ERROR;
      x_msg_data      := 'Invalid mail format';
    
END Validate_Customer_Email_Format;

END XX_CDH_CUSTEMAILFMT_PKG ;
/
SHOW ERRORS;
EXIT;
