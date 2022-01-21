SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE BODY XX_OM_HVOP_UTIL_PKG AS

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : SEND_NOTIFICATION                                               |
-- | Description      : This API will send email notification on errors      |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version  Date       Author         Remarks                               |
-- |=======  =========  =============  ==============================        |
-- |1.0      15-OCT-07  Manish Chavan  Initial code                          |
-- |1.1      21-Feb-09  Matthew Craig  Modified based on Chuck version       |
-- |1.2      22-Feb-09  Bala Edupuganti  Modified based on Chuck version     |
-- |1,3      23-Feb-09  Matthew Craig  Modifed as per Chuck                  |
-- |1.4      25-Feb-09  Matthew Craig  Modified as per chuck                 |
-- |1.5      26-Feb-09  Matthew Craig  Removed 1.3,1.4 changes,added new     |
-- |                                   change as per chuck                   |
-- |1.6      28-Feb-09  Matthew Craig  removed portion of 1.5 change (chuck) |
-- +=========================================================================+

PROCEDURE SEND_NOTIFICATION(p_subject IN VARCHAR2, p_text IN VARCHAR2)
IS
  lc_mailhost    VARCHAR2(64) := FND_PROFILE.VALUE('XX_OM_MAIL_HOST');
  lc_from        VARCHAR2(64) := 'OD-Online@officedepot.com';
  l_mail_conn    UTL_SMTP.connection;
  lc_to          VARCHAR2(100);
  lc_to_all      VARCHAR2(240) := FND_PROFILE.VALUE('XX_OM_HVOP_EMAIL_RECIPIENTS');
  i              BINARY_INTEGER;
  lc_to_tbl      T_V100;
BEGIN
  -- If setup data is missing then return
  IF lc_mailhost IS NULL OR lc_to_all IS NULL THEN
      RETURN;
  END IF;

  l_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
  UTL_SMTP.helo(l_mail_conn, lc_mailhost);
  UTL_SMTP.mail(l_mail_conn, lc_from);

  -- Check how many recipients are present in lc_to_all
  i := 1;
  LOOP
      lc_to := SUBSTR(lc_to_all,1,INSTR(lc_to_all,':') - 1);
      IF lc_to IS NULL OR i = 20 THEN
          lc_to_tbl(i) := lc_to_all;
          UTL_SMTP.rcpt(l_mail_conn, lc_to_all);
          EXIT;
      END IF;
      lc_to_tbl(i) := lc_to;
      UTL_SMTP.rcpt(l_mail_conn, lc_to);
      lc_to_all := SUBSTR(lc_to_all,INSTR(lc_to_all,':') + 1);
      i := i + 1;
  END LOOP;


  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: '    || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'From: '    || lc_from || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject ||' ***Page***'|| Chr(13));

  -- Checl all recipients
  FOR i IN 1..lc_to_tbl.COUNT LOOP

      UTL_SMTP.write_data(l_mail_conn, 'To: '      || lc_to_tbl(i) || Chr(13));

  END LOOP;

  UTL_SMTP.write_data(l_mail_conn, ''          || Chr(13));

  UTL_SMTP.write_data(l_mail_conn, p_text );

  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);
EXCEPTION
    WHEN OTHERS THEN
    NULL;
END SEND_NOTIFICATION;


--
-- FUNCTION to get the TEST credit card number using the first 6 and last 4 of CC number.
--

FUNCTION GET_TEST_CC( p_first6 IN VARCHAR2
                    , p_last4  IN VARCHAR2
                    , p_length IN NUMBER) RETURN VARCHAR2
IS
ln_debug_level    CONSTANT NUMBER := oe_debug_pub.g_debug_level;
l_num  VARCHAR2(5);
digit  T_NUM;
i      NUMBER;
j      NUMBER;
ln     NUMBER;
m1     VARCHAR2(10);
m2     VARCHAR2(4);
cc     VARCHAR2(20);
osum   NUMBER;
csum   NUMBER;
adj    NUMBER;
tot    NUMBER;
cdigit NUMBER;
cc_length NUMBER;
BEGIN
    ln := p_length;
    m1 := p_first6;
    m2 := p_last4;
    --dbms_output.put_line('Entering Get TEST CC ' ||m1);

    IF m1 = '601116' OR SUBSTR(p_first6,1,4) IN ('2014','2149') THEN -- US CITI COMMERCIAL, enroute cc with 15 digits ADD ('2014','2149') by NB
        ln := 15;
    END IF;
    
    IF SUBSTR(p_first6,1,2) IN (30,36,38) THEN -- Diners Club 14 digits added by NB
        ln := 14;
    END IF;
    
   

    -- Check if it is CANADA CITI card
    IF m1 =  '603528' THEN -- CITI card
        IF substr(m2,4,1) = '1' THEN -- CITI CA Consumer
            m1 := m1||'101';
        ELSE  -- CITI CA Commercial
            m1 := m1||'802';
        END IF;
    ELSIF m1 = '600525' THEN -- CITI canada with 18 digit length
        ln := 18;
        IF substr(m2,4,1) = '1' THEN
            m1 := m1||'1540';
        ELSIF substr(m2,4,1) = '4' THEN
            m1 := m1||'1544';
        END IF;
    END IF;
    --dbms_output.put_line('M1 is ' ||m1);

    cc := RPAD(m1, ln - 4,'0') || m2;
    --dbms_output.put_line('CC is ' ||cc);

    -- calculate the check digit
    cdigit := ln - 4;
    --dbms_output.put_line('cdigit is ' ||cdigit);

    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('The CC number init is '||cc);
    END IF;
    i := ln;
    osum := 0;
    j := 1;
    LOOP
        osum := osum + to_number(SUBSTR(cc,i,1));
        
        IF i > 6 AND i < ln - 4 THEN
            digit(j) := i;
            j := j + 1;
            
        END IF;
        i := i - 2;
        IF  i <= 0 THEN
            EXIT;
        END IF;
    END LOOP;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('The sum is '||osum);
    END IF;

    i := ln - 1;
    j := 1;
    csum := 0;
    LOOP
        l_num := substr(cc,i,1)*2;
        FOR i IN 1..LENGTH(l_num) LOOP
            csum := csum + SUBSTR(l_num,i,1);
        END LOOP;
        i := i - 2;
        IF i <= 0 THEN
           exit;
        END IF;
    END LOOP;
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('The csum is '||csum);
    END IF;
    osum := osum + csum;
    l_num := osum;
    --dbms_output.put_line('l_num Value ' ||l_num);
    IF MOD(osum,10) = 0 THEN
        -- No need to replace zeros.
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('Zeros are good');
        END IF;
        --dbms_output.put_line('MOD(osum,10) ' ||MOD(osum,10));
    ELSE
        IF l_num < 10 THEN
           --dbms_output.put_line('if l_num ' ||l_num);
           -- tot := l_num  +9; -- mfc 21-feb-09 changed from 10 to 9
           -- tot := l_num  +10; -- BE reverted to 10 from 9 on 22-FEB-09
           -- mfc 26-Feb-09 added the following IF
           -- mfc 28-Feb-09 commented out the IF
--          IF m1 = '601100' THEN
              tot := 10;
--          ELSE
--              tot := l_num + 10;
--          END IF;
        ELSE
           tot := to_number(substr(l_num,1,1)||'0') + 10;
        END IF;
       -- tot := to_number(substr(l_num,1,1)||'0') + 10;
        --dbms_output.put_line('tot Value ' ||tot);
        adj := tot - osum;
        --dbms_output.put_line('adj Value ' ||adj);
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('The length of difference is :'||adj);
        END IF;
        --cc := substr(cc,1,digit(1)-1)||adj||substr(cc,digit(1)+1,ln);
        --dbms_output.put_line('cc1 Value ' ||cc);
        --dbms_output.put_line('adj ' ||adj);
        --dbms_output.put_line('substr(cc,1,cdigit-1) ' ||substr(cc,1,cdigit-1));
        --dbms_output.put_line('substr(cc,1,cdigit-1) ' ||substr(cc,cdigit+1,ln));
        
        -- cc := substr(cc,1,cdigit-1)||substr(adj,1,1)||substr(cc,cdigit+1,ln); -- Added by NB changed adj to substr(adj,1,1)
         -- BE Added this code on 22-FEB-09
           IF length(adj) > 1 then
           adj := 0;
           END If;
         cc := substr(cc,1,cdigit-1)||adj||substr(cc,cdigit+1,ln); -- mfc 21-feb-09 reverted back to orig method
        --dbms_output.put_line('cc2 Value ' ||cc);
    END IF;
     ----dbms_output.put_line('cc Value ' ||cc);
    IF ln_debug_level > 0 THEN
        oe_debug_pub.add('Final CC Number is :'||cc);
    END IF;
    RETURN cc;
EXCEPTION
    WHEN OTHERS THEN
        --dbms_output.put_line('In others '||SQLERRM);
        IF ln_debug_level > 0 THEN
            oe_debug_pub.add('GET_TEST_CC: IN others : ' || SQLERRM);
        END IF;
        RETURN NULL;
END GET_TEST_CC;

END XX_OM_HVOP_UTIL_PKG;
/
SHOW ERRORS PACKAGE XX_OM_HVOP_UTIL_PKG;
EXIT;
