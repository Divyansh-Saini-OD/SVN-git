create or replace
PACKAGE BODY xx_ce_cc_common_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_ce_cc_common_pkg.pkb                                            |
-- | Description: Common package for procedures called by multiple XX_CE_CC packages.|
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  1.0     2011-03-04   Joe Klein          New package copied from E1310 to       |
-- |                                          create separate package for the        |
-- |                                          common procedures used by other        |
-- |                                          XX_CE_CC packages.                     |
-- |  1.1     2011-06-03   Joe Klein          For defect 11660, replaced TELCHK      |
-- |                                          default from 'ECA' to 'TELECHECK ECA'. |
-- |                                                                                 | 
-- |  1.2     2011-06-17   Gaurav Agarwal     For defect 12137, replaced CCSCRD      |
-- |                                          default from 'PL COMMERCIAL' to        |
-- |                                          'CITI_Com'.       
-- |  1.3     2014-06-26  Manjusha Tangirala  Added Paypal for defect 27667          |
-- |                                                                                 |                                                                                     |
-- +=================================================================================+
-- | Name        : GET_DEFAULT_CARD_TYPE                                             |
-- | Description : This function returns the credit card type based on the           |
-- |               processor_id (provider).                                          |
-- |                                                                                 |
-- +=================================================================================+
FUNCTION get_default_card_type
           ( p_processor_id IN VARCHAR2
            ,p_org_id       IN NUMBER    --Added for Defect #1061
           ) RETURN VARCHAR2
   IS
   BEGIN
      IF p_processor_id IN ('MPSCRD', 'NABCRD')
      THEN
         RETURN 'VISA';
      ELSIF p_processor_id = 'CCSCRD'
      THEN
         --RETURN 'PL COMMERCIAL';           --Defect 12137 commented
         RETURN 'CITI_Com';                --Defect 12137 added   
      ELSIF p_processor_id = 'AMX3RD'
      THEN
         RETURN 'AMEX';
      ELSIF p_processor_id = 'DCV3RN'
      THEN
         RETURN 'DISCOVER';
      ELSIF (p_processor_id = 'TELCHK' AND p_org_id = 404) -- Added for Defect #1061
      THEN
         --RETURN 'ECA';            --Defect 11660 commented
         RETURN 'TELECHECK ECA';    --Defect 11660 added
      ELSIF (p_processor_id = 'TELCHK' AND p_org_id = 403) -- Added for Defect #1061
      THEN
         RETURN 'Paper';
  Elsif (P_Processor_Id= 'PAYPAL')
      THEN RETURN 'PAYPAL';
      
      END IF;
END get_default_card_type;


-- +=================================================================================+
-- | Name        : OD_MESSAGE                                                        |
-- | Description : This procedure will be used to create generic message to the      |
-- |               concurrent program's output, log, and error log.                  |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE od_message 
           ( p_msg_type         IN   VARCHAR2
            ,p_msg              IN   VARCHAR2
            ,p_msg_loc          IN   VARCHAR2 DEFAULT NULL
            ,p_addnl_line_len   IN   NUMBER DEFAULT 110
           )
   IS
      ln_char_count   NUMBER := 0;
      ln_line_count   NUMBER := 0;
   BEGIN
      IF p_msg_type = 'M'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
      ELSIF p_msg_type = 'O'
      THEN
         /* If message cannot fit on one line,
         -- break into multiple lines */-- fnd_file.put_line(fnd_file.output, p_msg);
         IF NVL (LENGTH (p_msg), 0) > 120
         THEN
            FOR x IN 1 .. (TRUNC ((LENGTH (p_msg) - 120) / p_addnl_line_len) + 2
                          )
            LOOP
               ln_line_count := NVL (ln_line_count, 0) + 1;
               IF ln_line_count = 1
               THEN
                  fnd_file.put_line (fnd_file.output, SUBSTR (p_msg, 1, 120));
                  ln_char_count := NVL (ln_char_count, 0) + 120;
               ELSE
                  fnd_file.put_line (fnd_file.output
                                   ,    LPAD (' ', 120 - p_addnl_line_len, ' ')
                                     || SUBSTR (LTRIM (p_msg)
                                              , ln_char_count + 1
                                              , p_addnl_line_len
                                               )
                                    );
                  ln_char_count := NVL (ln_char_count, 0) + p_addnl_line_len;
               END IF;
            END LOOP;
         ELSE
            fnd_file.put_line (fnd_file.output, p_msg);
         END IF;
      ELSIF p_msg_type = 'E'
      THEN
         fnd_file.put_line (fnd_file.LOG, p_msg);
         DECLARE
            l_return_code             VARCHAR2 (1)                       := 'E';
            l_msg_count               NUMBER                               := 1;
            ln_request_id             NUMBER
                                       := fnd_profile.VALUE ('CONC_REQUEST_ID');
            lc_conc_prog_short_name   fnd_concurrent_programs.concurrent_program_name%TYPE;
         BEGIN
            SELECT concurrent_program_name
              INTO lc_conc_prog_short_name
              FROM fnd_concurrent_requests fcr, fnd_concurrent_programs_vl fcp
             WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
               AND fcr.request_id = ln_request_id;
            xx_com_error_log_pub.log_error
                                     (p_program_type => 'CONCURRENT PROGRAM'
                                    , p_program_name => lc_conc_prog_short_name
                                    , p_program_id => ln_request_id
                                    , p_module_name => 'xxfin'
                                    , p_error_location => p_msg_loc
                                    , p_error_message_count => 1
                                    , p_error_message_code => 'E'
                                    , p_error_message => p_msg || ' / '
                                       || SQLCODE || ':' || SQLERRM
                                    , p_error_message_severity => 'MAJOR'
                                    , p_notify_flag => 'N'
                                    , p_object_type => 'OD Refunds'
                                    , p_object_id => NULL
                                    , p_return_code => l_return_code
                                    , p_msg_count => l_msg_count
                                     );
         -- COMMIT;
         END;
      END IF;
   END od_message;
   
END xx_ce_cc_common_pkg;

/
