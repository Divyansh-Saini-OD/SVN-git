SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON                              
PROMPT Creating Package Body XX_AP_SUPPLIER_VAL_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE

create or replace PACKAGE BODY XX_AP_SUPPLIER_VAL_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XX_AP_SUPPLIER_VAL_PKG                               |
-- | Description      : Common API package body for Supplier Validations and utils |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    12-APR-2016   Madhu Bolli       Initial code                  |
-- +=========================================================================+
AS

/*********************************************************************
    * Procedure used to log based on gb_debug value or if p_force is TRUE.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program log file.  Will prepend
    * timestamp to each message logged.  This is useful for determining
    * elapse times.
    *********************************************************************/
    PROCEDURE print_debug_msg(
        P_Message  In  Varchar2,
        p_force    IN  BOOLEAN DEFAULT FALSE)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    Begin
        IF (gc_debug = 'Y' OR p_force)
        Then
			lc_Message := P_Message;
			Fnd_File.Put_Line(Fnd_File.log,lc_Message);
			IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
			Then
				DBMS_OUTPUT.put_line(lc_message);
			END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END print_debug_msg;
	/*********************************************************************
    * Procedure used to out the text to the concurrent program.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program output file.     
    *********************************************************************/
    PROCEDURE print_out_msg(
        P_Message  In  Varchar2)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    Begin
        Lc_Message :=P_Message;
        Fnd_File.Put_Line(Fnd_File.output, Lc_Message);
        IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
        Then
            DBMS_OUTPUT.put_line(lc_message);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END print_out_msg; 
	

-- +===================================================================+
-- | FUNCTION  : is_email_valid                                        |
-- |                                                                   |
-- | DESCRIPTION: Checks and returns valid or invalid email		       |
-- |        Taken code snippet from method - PO_CORE_S.is_email_valid()|
-- |                                                                   |
-- |                                                                   |
-- | Parameters : 										 			   |
-- |             p_email_address                                       |
-- | RETURNS    :                                                      |
-- |             Boolean Value (TRUE  or FALSE)                        |
-- +===================================================================+
	FUNCTION is_email_valid(p_email_address VARCHAR2) RETURN BOOLEAN
	IS

	BEGIN

	  /* Validating the special characters in the email address local part
		 as per the RFC5322 specification.
	  */
	  IF REGEXP_LIKE(p_email_address, '^[A-Z0-9._%+-\''\&$`^|!#*~{}]+@[A-Z0-9.-]+\.[A-Zz0-9]+$','i') THEN
		  RETURN TRUE;
	  ELSE
		  RETURN FALSE;
	  END IF;

	END is_email_valid;	

	
-- +===================================================================+
-- | Procedure  : update_supp_site                                     |
-- |                                                                   |
-- | DESCRIPTION: Update vendor_site_code in AP Supplier Site and      |
-- |              party_site_name in hz_party_site                     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters : 										 |
-- |             p_vendor_id                                           |
-- |             p_vendor_site_id                                      |
-- |             p_party_site_id                                       |
-- |             p_org_id                                              |
-- |             p_prefix                                              |
-- | RETURNS    :                                                      |
-- |             p_error_status                                        |
-- |             p_error_mesg                                          |
-- +===================================================================+
PROCEDURE update_supp_site(
					 p_vendor_id 		IN NUMBER	
					,p_vendor_site_id	IN NUMBER
					,p_party_site_id	IN NUMBER	
					,p_org_id			IN NUMBER
					,p_prefix			IN VARCHAR2
					,p_error_status		OUT VARCHAR2
					,p_error_mesg		OUT VARCHAR2
				     )
IS
 ln_party_id             NUMBER;
 l_site_obj_ver_num      NUMBER;
 ln_location_id          NUMBER;
 l_error_status		    VARCHAR2(1):='N';
 l_error_msg		    VARCHAR2(2000);
 l_msg_data              VARCHAR2 (2000) := NULL;
 ln_new_site_code        VARCHAR2(50);
 l_init_msg_list         VARCHAR2 (10) := 'T';
 lc_return_status        VARCHAR2(2000);
 l_api_error_message     VARCHAR2 (4000);
 ln_msg_count            NUMBER;
 l_msg_index_out         NUMBER;
 ll_msg_data             LONG;
 ln_message_int          NUMBER;
 lrec_vendor_site_rec    ap_vendor_pub_pkg.r_vendor_site_rec_type;
 l_party_site_rec        hz_party_site_v2pub.party_site_rec_type;
BEGIN
  ln_new_site_code := p_prefix||TO_CHAR(p_vendor_site_id);
  Lrec_Vendor_site_Rec.vendor_site_code_alt := TO_CHAR(p_vendor_site_id);
  Lrec_Vendor_site_Rec.vendor_id := p_vendor_id;
  Lrec_Vendor_site_Rec.vendor_site_id := p_vendor_site_id;
  Lrec_Vendor_site_Rec.org_id := p_org_id;
  Lrec_Vendor_site_Rec.vendor_site_code := ln_new_site_code;
  Lrec_Vendor_site_Rec.attribute7 := p_vendor_site_id;
  ap_vendor_pub_pkg.update_vendor_site(p_api_version => 1.0,
                                       x_return_status         => lc_return_status,
                                       x_msg_count             => ln_msg_count,
                                       x_msg_data              => ll_msg_data,
                                       p_vendor_site_rec       => Lrec_Vendor_site_Rec,
                                       p_vendor_site_id        => p_vendor_site_id);
  IF (lc_return_status <> 'S') THEN
      IF ln_msg_count >= 1 THEN
         FOR v_index IN 1..ln_msg_count
         LOOP
           fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => ll_msg_data, p_msg_index_out => ln_message_int );
            Ll_Msg_Data := 'UPDATE_VENDOR_SITE '||SUBSTR(Ll_Msg_Data,1,3900);
         END LOOP;
         l_error_msg:='Error in update AP vendor site :'||l_msg_data;
	    l_error_status:='Y';
	   END IF;
  End If;
  BEGIN
    SELECT party_id,
           location_id,
           object_version_number
      INTO ln_party_id,
           ln_location_id,
           l_site_obj_ver_num
      FROM hz_party_sites
     WHERE party_site_id=p_party_site_id;
  EXCEPTION
    WHEN others THEN
     ln_party_id:=NULL;
  END;
  IF ln_party_id IS NOT NULL THEN
     l_party_site_rec.party_id := ln_party_id;
     l_party_site_rec.party_site_id := p_party_site_id;
     l_party_site_rec.party_site_name := ln_new_site_code;
     l_party_site_rec.location_id := ln_location_id;
     hz_party_site_v2pub.update_party_site
                                         (p_init_msg_list              => l_init_msg_list,
                                          p_party_site_rec             => l_party_site_rec,
                                          p_object_version_number      => l_site_obj_ver_num,
                                          x_return_status              => lc_return_status,
                                          x_msg_count                  => ln_msg_count,
                                          x_msg_data                   => ll_msg_data
                                         );
     IF lc_return_status <> 'S'  THEN
        IF (fnd_msg_pub.count_msg > 0)  THEN
           FOR i IN 1 .. fnd_msg_pub.count_msg
           LOOP
             fnd_msg_pub.get (p_msg_index          => i,
                                        p_encoded            => 'F',
                                        p_data               => ll_msg_data,
                                        p_msg_index_out      => l_msg_index_out
                                       );
             l_api_error_message :=l_api_error_message || ' ,' || ll_msg_data;
           END LOOP;
         END IF;
         l_error_msg:=l_error_msg||', Error in update HZ Party Site :'||l_api_error_message;
	    l_error_status:='Y';
     END IF;     
  END IF;
  p_error_status:=l_error_status;
  p_error_mesg	:=l_error_msg;
  COMMIT;
EXCEPTION
  WHEN others THEN
    p_error_status:='Y';
    p_error_mesg:=l_error_msg||','||SUBSTR(SQLERRM,1,200);
END update_supp_site;
-- +===================================================================+
-- | Procedure  : submit_supplier_import                               |
-- |                                                                   |
-- | DESCRIPTION: Submit Supplier Open Interface Import                |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Request_id                                           |
-- +===================================================================+
PROCEDURE submit_supplier_import (
                                    p_request_id 	OUT NUMBER
						   ,p_status		OUT VARCHAR2
						   ,p_error_msg		OUT VARCHAR2
					       )
IS
v_request_id	NUMBER;
v_phase		varchar2(100)   ;
v_status		varchar2(100)   ;
v_dphase		varchar2(100)	;
v_dstatus		varchar2(100)	;
x_dummy		varchar2(2000) 	;
BEGIN
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('SQLAP','APXSUIMP','Supplier Open Interface Import',NULL,FALSE,
								'ALL','1000','N','N','N');

  IF v_request_id>0 THEN
     COMMIT;
     p_request_id:=v_request_id;
  ELSE
     p_request_id:=-1;
     p_error_msg:='Error in submitting Supplier Open Interface Import';
  END IF;
  IF v_request_id > 0 THEN
     IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN
         IF v_dphase = 'COMPLETE' THEN
	       p_status:=v_dstatus;
         END IF;
     END IF;
  END IF;
EXCEPTION
  WHEN others THEN
    p_request_id:=-1;
    p_error_msg:='When others in submit_supplier_import' || SUBSTR (SQLERRM, 1, 1000);
END submit_supplier_import;
-- +===================================================================+
-- | FUNCTION   : submit_supp_site_import                              |
-- |                                                                   |
-- | DESCRIPTION: Submit Supplier Site Open Interface Import           |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Varchar (if junck character exists or not)           |
-- +===================================================================+
PROCEDURE submit_supp_site_import (
						    p_ou		 	IN  NUMBER
                           ,p_request_id 	OUT NUMBER
						   ,p_status		OUT VARCHAR2
						   ,p_error_msg		OUT VARCHAR2
					       )
IS
v_request_id	NUMBER;
v_phase		varchar2(100)   ;
v_status		varchar2(100)   ;
v_dphase		varchar2(100)	;
v_dstatus		varchar2(100)	;
x_dummy		varchar2(2000) 	;
BEGIN
  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('SQLAP','APXSSIMP','Supplier Site Open Interface Import',NULL,FALSE,
								TO_CHAR(p_ou),'ALL','1000','N','N','N');
  IF v_request_id>0 THEN
     COMMIT;
     p_request_id:=v_request_id;
  ELSE
     p_request_id:=-1;
     p_error_msg:='Error in submitting Supplier Site Open Interface Import';
  END IF;
  IF v_request_id > 0 THEN
     IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 			v_status,v_dphase,v_dstatus,x_dummy))  THEN
         IF v_dphase = 'COMPLETE' THEN
	       p_status:=v_dstatus;
         END IF;
     END IF;
  END IF;
EXCEPTION
  WHEN others THEN
    p_request_id:=-1;
    p_error_msg:='When others in submit_supp_site_import' || SUBSTR (SQLERRM, 1, 1000);
END submit_supp_site_import;
-- +===================================================================+
-- | FUNCTION   : find_special_chars                                   |
-- |                                                                   |
-- | DESCRIPTION: Checks if special chars exist in a string            |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Varchar (if junck character exists or not)           |
-- +===================================================================+
FUNCTION find_special_chars(p_string IN VARCHAR2) RETURN VARCHAR2 IS
  v_string         VARCHAR2(4000);
  v_char           VARCHAR2(1);
  v_out_string     VARCHAR2(4000) := NULL;
Begin
  v_string := LTRIM(RTRIM(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' find_special_chars() - p_string '||p_string
                                  ,p_force=> FALSE);
    SELECT LENGTH(TRIM(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', ' ')))
      INTO v_out_string
      FROM DUAL;
  EXCEPTION
    WHEN others THEN
      v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
     RETURN 'JUNK_CHARS_EXIST';
  ELSE
     RETURN v_string;
  END IF;
End Find_Special_Chars;
	-- +===================================================================+
	-- | FUNCTION   : isAlphaNumeric                                       |
	-- |                                                                   |
	-- | DESCRIPTION: Checks if only AlphaNumeric in a string              |
	-- |                                                                   |
	-- |                                                                   |
	-- | RETURNS    : Boolean (if alpha numeric exists or not)             |
	-- +===================================================================+
	FUNCTION isAlphaNumeric(p_string IN VARCHAR2) RETURN BOOLEAN IS
	  l_string         VARCHAR2(4000);
	  l_out_string     VARCHAR2(4000) := NULL;
	Begin
	  l_string := LTRIM(RTRIM(upper(p_string)));
	  BEGIN
		print_debug_msg(p_message=> ' isAlphaNumeric() - p_string '||p_string
									  ,p_force=> FALSE);
		SELECT LENGTH(TRIM(TRANSLATE(l_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', ' ')))
		  INTO l_out_string
		  FROM DUAL;
	  EXCEPTION
		WHEN others THEN
		  l_out_string:=NULL;
	  END;
	  IF l_out_string IS NOT NULL THEN
		 RETURN FALSE;
	  ELSE
		 RETURN TRUE;
	  END IF;
	End isAlphaNumeric;
   /*==========================================================================+
   ==  PROCEDURE NAME :   get_application_id
   ==  Description    :   get_application_id return Application ID based on Application Short Name
   IN Arguments:
     p_app_short_name VARCHAR2  -- mandatory
   OUT Arguments:
     Returns p_application_id or p_error_msg
     Check
     p_application_id   > 0  (returns valid Application ID)
     p_error_msg
   ============================
   ==  Modification History:
   ==  DATE         NAME       DESC
   ==  ----------   ------------  ---------------------------------------------
   ==  12-APR-2016  Madhu Bolli    Initial Version
   ============================================================================*/
   PROCEDURE get_application_id (
      p_app_short_name   IN       VARCHAR2,
      p_application_id   OUT      NUMBER,
      p_error_msg        OUT      VARCHAR2
   )
   IS
      l_err_text   VARCHAR2 (255);
   BEGIN
     l_err_text := 'Deriving Application Id for app_short_name ->' || p_app_short_name;
     p_error_msg := NULL;
     SELECT application_id
       INTO p_application_id
       FROM fnd_application
      WHERE application_short_name = p_app_short_name;
     IF p_application_id IS NULL THEN
         p_application_id := -1;
         p_error_msg      := 'No Application ID found for the Application short_name ->' || p_app_short_name;
     END IF;
   EXCEPTION
     WHEN OTHERS THEN
       p_application_id := -99;
       p_error_msg :=
                    l_err_text || '-' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
   END get_application_id;
-- +===================================================================+
-- | FUNCTION   : get_term_id                                          |
-- |                                                                   |
-- | DESCRIPTION: Checks if terms exists in ap_terms                   |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Number (term_id)                                     |
-- +===================================================================+
  PROCEDURE get_term_id(
      p_term_name   IN       VARCHAR2,
      p_term_id	    OUT	   NUMBER,
      p_valid       OUT      VARCHAR2,
      p_error_msg   OUT      VARCHAR2
   )
   IS
      l_err_text   VARCHAR2 (255);
      ln_count     NUMBER;
      ln_term_id   NUMBER;
   BEGIN
     l_err_text :='Validating Term value ' || p_term_name;
     p_error_msg := NULL;
     ln_count := 0;
      SELECT TERM_ID
        INTO ln_term_id
        FROM AP_TERMS_VL
      WHERE NAME = p_term_name
        AND ENABLED_FLAG = 'Y'
        AND trunc(sysdate) between trunc(NVL(start_date_active, SYSDATE-1)) and trunc(NVL(end_date_active, sysdate+1));     
      IF ln_term_id IS NULL THEN
         p_valid := 'N';
         p_term_id:=-1;
         p_error_msg := 'Term ' || p_term_name || ' is not valid.';
      ELSE
         p_valid := 'Y';
         p_term_id:= ln_term_id;
         p_error_msg := NULL;
      END IF;
   EXCEPTION
	WHEN others THEN
       p_term_id:=-1;
       p_valid := 'N';
       p_error_msg := l_err_text || '-' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
   END get_term_id;
   /*==========================================================================+
   ==  PROCEDURE NAME :   valid_valueset_value
   ==  Description    :   Validates a input Value in provided valueSet
      IN Arguments:
        Value Set Name
        Value
      OUT Arguments:
      Returns p_valid or p_error_msg
     Check
        p_valid   (returns 'Y' for valid)
        p_error_msg
   ============================
   ==  Modification History:
   ==  DATE         NAME       DESC
   ==  ----------   ---------  ---------------------------------------------
   ==  12-APR-2016  Madhu Bollli    Created
   ============================================================================*/
   PROCEDURE validate_valueset_value (
      p_value_set   IN       VARCHAR2,
      p_value       IN       VARCHAR2,
      p_valid       OUT      VARCHAR2,
      p_error_msg   OUT      VARCHAR2
   )
   IS
      l_err_text   VARCHAR2 (255);
      ln_count     NUMBER;
   BEGIN
     l_err_text :='Validating value ' || p_value || ' in the valueset ' || p_value_set;
     p_error_msg := NULL;
     ln_count := 0;
      SELECT COUNT (1)
        INTO ln_count
        FROM fnd_flex_value_sets vs, fnd_flex_values_vl v
       WHERE vs.flex_value_set_name = p_value_set
         AND vs.flex_value_set_id = v.flex_value_set_id
         AND v.flex_value = p_value
         AND v.enabled_flag = 'Y';
      IF ln_count <= 0  THEN
         p_valid := 'N';
         p_error_msg := 'Value ' || p_value || ' is not valid.';
      ELSE
         p_valid := 'Y';
         p_error_msg := NULL;
      END IF;
   END validate_valueset_value;
   /*==========================================================================+
     ==  PROCEDURE NAME :   is_supplier_exists
     ==  Description    :   Check if the Supplier exists in Oracle Seeded Table
     IN Arguments:
       p_supp_name
     OUT Arguments:
       Returns  p_valid or p_error_msg
       Check
       p_valid   (returns 'Y' for valid)
       p_error_msg
     ============================
     ==  Modification History:
     ==  DATE         NAME     DESC
     ==  ----------   -----------   ---------------------------------------------
     ==  12-APR-2016  Madhu Bolli    -----
     ============================================================================*/
   PROCEDURE is_supplier_exists (
      p_supp_name        IN       VARCHAR2,
      p_vendor_id	    OUT      NUMBER,
      p_valid            OUT      VARCHAR2,
      p_error_msg        OUT      VARCHAR2
   )
   IS
      l_err_text   	VARCHAR2 (255);
      ln_count     	NUMBER;
      ln_vendor_id 	NUMBER;
   BEGIN
     l_err_text := 'Supplier Exists in AP Suppliers Tables';
     p_error_msg := NULL;
     ln_count := 0;
     SELECT vendor_id
        INTO ln_vendor_id
        FROM ap_suppliers
       WHERE UPPER(vendor_name)=UPPER(p_supp_name);
     IF ln_vendor_id IS NULL THEN
	   p_vendor_id:=-1;
	   p_valid:='Y';
     ELSE
	   p_vendor_id:=ln_vendor_id;
	   p_valid:='Y';
     END IF;
   EXCEPTION
      WHEN others THEN
        p_valid := '-99';
        p_error_msg := l_err_text || '-' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
   END is_supplier_exists;
   /*==========================================================================+
   ==  PROCEDURE NAME :   validate_lookup_meaning
   ==  Description    :   Validates a input Value with the meaning of the input lookupType
      IN Arguments:
        p_lookup_type
        p_meaning
      OUT Arguments:
		p_lookup_code		 NUMBER 
			-- '-1'  if the input value is not valid
			-- '-99' if exception raises
			-- AnyNumber - If ther terms Code is Valid
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises			
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
     Check
        p_lookup_code
        p_valid   (returns 'Y' for valid)
        p_error_msg
   ============================
   ==  Modification History:
   ==  DATE         NAME       DESC
   ==  ----------   ---------  ---------------------------------------------
   ==  12-APR-2016  Madhu Bollli    Created
   ============================================================================*/
   PROCEDURE validate_lookup_meaning (
      p_lookup_type   IN       VARCHAR2
     ,p_meaning       IN       VARCHAR2
     ,p_application_id IN	   VARCHAR2
     ,p_lookup_code   OUT      VARCHAR2
     ,p_valid         OUT      VARCHAR2
     ,p_error_code	  OUT	   VARCHAR2
     ,p_error_msg     OUT      VARCHAR2
   )
   IS
      l_err_text   VARCHAR2 (255);
   BEGIN
      l_err_text := 'Validating value '|| p_meaning|| ' in the valueset '|| p_lookup_type;
      p_error_code := NULL;
   	 p_error_msg  := NULL;
	 p_lookup_code := NULL;
 	 SELECT lookup_code
	   INTO p_lookup_code
	   FROM FND_LOOKUP_VALUES
	  WHERE lookup_type = p_lookup_type        
   	    AND meaning = p_meaning        
	    AND view_application_id = p_application_id
	    AND source_lang = 'US'
	    AND trunc(sysdate) BETWEEN TRUNC(NVL(start_date_active, sysdate-1)) 
					      AND TRUNC(NVL(end_date_active, sysdate+1)); 
      IF p_lookup_code IS NULL THEN
         p_valid := 'N';
  	    p_error_code := 'XXOD_INVALID_VAL';
         p_error_msg := 'Invalid Value ' || p_meaning;
      ELSE
         p_valid := 'Y';
	    p_error_code := NULL;
         p_error_msg := NULL;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_valid := '-1';
        p_error_code := 'XXOD_INVALID_VAL';
        p_error_msg := 'Invalid Value ' || p_meaning;		 
      WHEN OTHERS THEN
         p_valid := '-99';
   	    p_error_code := 'XXOD_INVALID_VAL_EXC';
         p_error_msg := l_err_text || '-' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
   END validate_lookup_meaning;
    /*==========================================================================+
    ==  PROCEDURE NAME :   validate_valueset_description
    ==  Description    :   Validates a input Value, which is description of valueset, in provided valueSet
      IN Arguments:
        Value Set Name
        Description Value
      OUT Arguments:
      Returns p_valid and p_error_msg
     Check
        p_valid   (returns 'Y' for valid)
        p_error_msg
    ============================
    ==  Modification History:
    ==  DATE         NAME       DESC
    ==  ----------   ---------  ---------------------------------------------
    ==  12-APR-2016  Madhu Bollli    Created
    ============================================================================*/
    PROCEDURE validate_valueset_description (
      p_value_set     IN       VARCHAR2
     ,p_desc_value    IN       VARCHAR2
     ,p_flex_value	 OUT	    VARCHAR2
     ,p_valid         OUT      VARCHAR2
     ,p_error_code	  OUT	   VARCHAR2
     ,p_error_msg     OUT      VARCHAR2
    )
    IS
    l_err_text   VARCHAR2 (255);
    ln_count     NUMBER;
    lc_flex_value VARCHAR2(150);
    BEGIN
  	 l_err_text :='Validating description value ' || p_desc_value || ' in the valueset ' || p_value_set;
  	 p_error_code := NULL;
	 p_error_msg  := NULL;
  	 SELECT v.flex_value
   	   INTO lc_flex_value
        FROM fnd_flex_value_sets vs, 
	        fnd_flex_values_vl v
     	  WHERE vs.flex_value_set_name = p_value_set
	    AND vs.flex_value_set_id = v.flex_value_set_id
          AND v.description = p_desc_value
          AND v.enabled_flag = 'Y';
      IF lc_flex_value IS NULL THEN
         p_valid := 'N';
  	    p_error_code := 'XXOD_INVALID_VAL';
         p_error_msg := 'Invalid Value ' || p_desc_value;
      ELSE
         p_valid := 'Y';
	    p_flex_value:=lc_flex_value;
	    p_error_code := NULL;
         p_error_msg := NULL;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        p_valid := '-1';
        p_error_code := 'XXOD_INVALID_VAL';
        p_error_msg := 'Invalid Value ' || p_desc_value;
      WHEN OTHERS THEN
         p_valid := '-99';
   	    p_error_code := 'XXOD_INVALID_VAL_EXC';
         p_error_msg := l_err_text || '-' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
   END validate_valueset_description;
	/*==========================================================================
	==  PROCEDURE NAME :   valid_supplier_name_format
	==  Description    :   Validate the SUPPLIER NAME
	IN Arguments:
		p_sup_name	 	VARCHAR2  -- mandatory
	OUT Arguments:
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
    =============================================================================
	==  Modification History:
	==  DATE         NAME       DESC  	
	==  ----------   ---------  ---------------------------------------------
	==  13-APR-2016  Madhu Bollli    Created
	============================================================================*/
	PROCEDURE valid_supplier_name_format (
     				 p_sup_name   	  IN       VARCHAR2,
			      p_valid         OUT      VARCHAR2,
				 p_error_code    OUT      VARCHAR2,
			      p_error_msg     OUT      VARCHAR2
								)
	IS
        l_err_text   VARCHAR2 (255);
	BEGIN
   	  l_err_text := 'Validating the format of Supplier Number ' || p_sup_name;
	  p_error_msg := NULL;
	  p_valid	  := 'Y';
       IF ((find_special_chars(p_sup_name) = 'JUNK_CHARS_EXIST') OR (length(p_sup_name) > 30 )) 
       THEN
		p_valid := 'N';				
		p_error_code := 'XXOD_SUPPLIER_NAME_INVALID';
		p_error_msg := 'Supplier Name '''||p_sup_name||''' cannot contain junk characters and length must be less than or equal to 30';
       END IF;
	EXCEPTION
       WHEN OTHERS THEN
         p_valid := '-99';
   	    p_error_code := 'SUPPLIER_NAME format Validation Exception - See Log';
         p_error_msg :=  l_err_text || ' - ' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
	END valid_supplier_name_format;
	/*==========================================================================
	==  PROCEDURE NAME :   validate_address_line
	==  Description    :   Validate the Address Line
	IN Arguments:
		p_address_line 	VARCHAR2  -- mandatory
	OUT Arguments:
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
    =============================================================================
	==  Modification History:
	==  DATE         NAME       DESC  	
	==  ----------   ---------  ---------------------------------------------
	==  13-APR-2016  Madhu Bollli    Created
	============================================================================*/
     PROCEDURE validate_address_line (
    			  p_address_line  IN       VARCHAR2,
		       p_valid         OUT      VARCHAR2,
			  p_error_code    OUT      VARCHAR2,
		       p_error_msg     OUT      VARCHAR2
							)	
     IS
       l_err_text   VARCHAR2 (255);
	BEGIN
 	  l_err_text := 'Validating the format of Address Line ' || p_address_line;
	  p_error_msg := NULL;
	  p_valid	  := 'Y';
       IF ((find_special_chars(p_address_line) = 'JUNK_CHARS_EXIST')
            OR (length(p_address_line) > 38 )) 
       THEN
			p_valid := 'N';				
			p_error_code := 'XXOD_SITE_ADDR_LINE_INVALID';			
			p_error_msg := ' should contain only alphanumber characters and length must be less than or equal to 38';
       END IF;
	EXCEPTION
       WHEN OTHERS THEN
         p_valid := '-99';
   	   p_error_code := 'Address Line format Validation Exception - See Log';
        p_error_msg :=  l_err_text || ' - ' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
     END validate_address_line; 
    /*==========================================================================+
    ==  PROCEDURE NAME :   validate_term_code
    ==  Description    :   validate_term_code returns term Id if the input value is valid
    IN Arguments:
		p_app_short_name VARCHAR2  -- mandatory
	OUT Arguments:
		p_term_id		 NUMBER 
			-- '-1'  if the input value is not valid
			-- '-99' if exception raises
			-- AnyNumber - If ther terms Code is Valid
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises			
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
	============================
	==  Modification History:
	==  DATE         NAME       DESC
	==  ----------   ------------  ---------------------------------------------
	==  12-APR-2016  Madhu Bolli    Initial Version
	============================================================================*/
	PROCEDURE validate_term_code (
	       p_term_code	  IN   VARCHAR2
		 ,p_term_id	 OUT	  NUMBER
	    	 ,p_valid		 OUT	  VARCHAR2
		 ,p_error_code   OUT   VARCHAR2
            ,p_error_msg    OUT   VARCHAR2
					        )
	IS
	l_err_text   VARCHAR2 (255);
 	BEGIN
  	  l_err_text :='Validate and derive Terms Id for Term Code ->' || p_term_code;
   	  p_valid := 'N';
       p_error_code := NULL;
	  p_error_msg := NULL;
    	  SELECT  TERM_ID
	    INTO p_term_id
	    FROM AP_TERMS
	   WHERE NAME = p_term_code
          AND ENABLED_FLAG = 'Y'
          AND trunc(sysdate) between trunc(NVL(start_date_active, SYSDATE-1)) and trunc(NVL(end_date_active, sysdate+1)); 
     	  IF p_term_id IS NULL  THEN
  		p_valid := 'N';
		p_error_code := 'XXOD_INVALID_TERMS_CODE';
		p_error_msg := 'Terms Code does not exist in the system.';
		p_term_id	:= -1;
  	  ELSE
		p_valid := 'Y';
		p_error_code := NULL;
		p_error_msg := NULL;
	  END IF;
	EXCEPTION
  	  WHEN NO_DATA_FOUND 	THEN
			p_valid := '-1';
			p_error_code := 'XXOD_INVALID_TERMS_CODE';
			p_error_msg := 'Terms Code does not exist in the system.';	
			p_term_id	:= -1;			
  	  WHEN OTHERS THEN
			p_valid := '-99';
			p_error_code := 'XXOD_INVALID_TERMS_CODE_EXC:Please check log.';
			p_error_msg :=
						l_err_text || '-' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
			p_term_id	:= -99;
 	END validate_term_code;
    /*==========================================================================+
    ==  PROCEDURE NAME :   validate_and_get_account
    ==  Description    :   validate_and_get_account returns CCId if the input value is valid
    IN Arguments:
		p_concat_segments VARCHAR2  -- mandatory
		p_account_type    VARCHAR2  -- mandatory
					-- For Liability Account Type, use 'L'
	OUT Arguments:
		p_cc_id			 NUMBER 
			-- '-1'  if the input value is not valid
			-- '-99' if exception raises
			-- AnyNumber - If ther terms Code is Valid
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises			
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
	============================
	==  Modification History:
	==  DATE         NAME       DESC
	==  ----------   ------------  ---------------------------------------------
	==  18-APR-2016  Madhu Bolli    Initial Version
	============================================================================*/
	PROCEDURE validate_and_get_account (
	       p_concat_segments	IN      VARCHAR2
		 ,p_account_type    In		VARCHAR2
		 ,p_cc_id	  		OUT	  	NUMBER
		 ,p_valid		 	OUT	  	VARCHAR2
		 ,p_error_code   	OUT     VARCHAR2
	      ,p_error_msg    	OUT		VARCHAR2
						   	   )
	IS
	l_err_text   VARCHAR2 (255);
	BEGIN
 	  l_err_text :='Validate and derive CCID for input concated segments account->' || p_concat_segments;
 	  p_valid := 'N';
	  p_error_code := NULL;
	  p_error_msg := NULL;
	  SELECT Code_Combination_Id
	    INTO p_cc_id
	    FROM gl_code_combinations gcc
	   WHERE Gcc.Segment1||'.'||Gcc.Segment2||'.'||Gcc.Segment3||'.'||Gcc.Segment4||'.'||Gcc.Segment5||'.'||Gcc.Segment6||'.'||Gcc.Segment7 = p_concat_segments 
		AND gcc.enabled_flag='Y'
		AND gcc.ACCOUNT_TYPE = p_account_type; 		
	 IF p_cc_id IS NULL THEN
 	    p_valid := 'N';
	    p_error_code := 'XXOD_ACCOUNT_INVALID';
	    p_error_msg := 'Account does not exist in the system.';
 	    p_cc_id := -1;
 	 ELSE
	    p_valid := 'Y';
	    p_error_code := NULL;
	    p_error_msg := NULL;
  	 END IF;
	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
			p_valid := '-1';
			p_error_code := 'XXOD_ACCOUNT_INVALID';
			p_error_msg := 'Account does not exist in the system.';	
			p_cc_id := -1;			
 	  WHEN OTHERS THEN
			p_valid := '-99';
			p_error_code := 'XXOD_ACCOUNT_EXC:Please check log.';
			p_error_msg :=l_err_text || '-' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
			p_cc_id := -99;
	END validate_and_get_account;
    /*==========================================================================+
    ==  PROCEDURE NAME :   validate_and_get_account
    ==  Description    :   validate_and_get_account returns CCId if the input value is valid
    IN Arguments:
		p_concat_segments VARCHAR2  -- mandatory
		p_account_type    VARCHAR2  -- mandatory
					-- For Liability Account Type, use 'L'
	OUT Arguments:
		p_cc_id			 NUMBER 
			-- '-1'  if the input value is not valid
			-- '-99' if exception raises
			-- AnyNumber - If ther terms Code is Valid
		p_valid		 	VARCHAR2 
							-- 'Y'   if valid
							-- 'N'   if not valid
							-- '-1'  if the input value is NULL
							-- '-99' if exception raises			
		p_error_code	VARCHAR2
		p_error_msg		VARCHAR2
	============================
	==  Modification History:
	==  DATE         NAME       DESC
	==  ----------   ------------  ---------------------------------------------
	==  18-APR-2016  Madhu Bolli    Initial Version
	============================================================================*/
	PROCEDURE validate_and_get_billtoloc (
	  		    p_bill_to_loc_code	IN   VARCHAR2
			   ,p_bill_to_loc_id  	OUT	NUMBER
		  	   ,p_valid		 	OUT	VARCHAR2
	 	        ,p_error_code   		OUT  VARCHAR2
		        ,p_error_msg    		OUT	VARCHAR2
								)
	IS
	l_err_text   VARCHAR2 (255);
	BEGIN
 	  l_err_text :='Validate and derive bill to location Id for input bill to location code ->' || p_bill_to_loc_code;
  	  p_valid := 'N';
	  p_error_code := NULL;
	  p_error_msg := NULL;
  	  SELECT LOCATION_ID
	    INTO p_bill_to_loc_id
	    FROM HR_LOCATIONS_ALL
	   WHERE LOCATION_CODE = p_bill_to_loc_code
		AND BILL_TO_SITE_FLAG = 'Y'
		AND INACTIVE_DATE IS NULL or INACTIVE_DATE >= SYSDATE;   		
  	 IF p_bill_to_loc_id IS NULL THEN
  	    p_valid := 'N';
	    p_error_code := 'XXOD_BILL_TO_LOCATION_INVALID';
	    p_error_msg := 'Bill To Location Code '||p_bill_to_loc_code||' is Invalid.';
 	    p_bill_to_loc_id := -1;
      ELSE
  	    p_valid := 'Y';
	    p_error_code := NULL;
	    p_error_msg := NULL;
  	END IF;
	EXCEPTION
  	  WHEN NO_DATA_FOUND THEN
			p_valid := '-1';
			p_error_code := 'XXOD_BILL_TO_LOCATION_INVALID';
			p_error_msg := 'Bill To Location Code '||p_bill_to_loc_code||' is Invalid.';	
			p_bill_to_loc_id := -1;			
  	  WHEN OTHERS THEN
			p_valid := '-99';
			p_error_code := 'XXOD_BILL_TO_LOCATION_EXC:Please check log.';
			p_error_msg :=
						l_err_text || '-' || SQLCODE || SUBSTR (SQLERRM, 1, 1000);
			p_bill_to_loc_id := -99;
	END validate_and_get_billtoloc;	
    



    /*==========================================================================+
    ==  FUNCTION_NAME :    isValidDateFormat
    ==  Description    :   isValidDateFormat returns TRUE/FALSE
                             -- Checks only for format 'DD-MON-YY' though we take format as input.
    
    IN Arguments:
        p_date      VARCHAR2  -- mandatory
        p_format    VARCHAR2  -- mandatory
        
    Return Value  TRUE/FALSE:
        

    ============================
    ==  Modification History:
    ==  DATE         NAME       DESC
    ==  ----------   ------------  ---------------------------------------------
    ==  28-JUN-2016  Madhu Bolli    Initial Version
    ============================================================================*/
    FUNCTION isValidDateFormat(p_date VARCHAR2, p_format VARCHAR2) RETURN BOOLEAN
    IS
        ld_date DATE; 
    BEGIN
    
        ld_date := to_date(p_date,p_format);
        -- To make sure that the Year part is of 2 digits.B'coz above to_date(), doesn't throw error if the year is YYY also...
        
        IF length(substr(p_date, 8,9)) = 2 THEN
            return TRUE;
        ELSE
            return FALSE;
        END IF;
                     
    EXCEPTION
    WHEN OTHERS THEN
        return FALSE;        
    END isValidDateFormat;

    
END XX_AP_SUPPLIER_VAL_PKG;
/
SHOW ERRORS;
