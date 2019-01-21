create or replace
PACKAGE BODY XX_AR_CONS_BILL_TERM_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- |                        Providge Consulting                        |
  -- +===================================================================+
  -- | E0269                                                             |
  -- |        Name : AR Increment Consolidated Billing Terms             |
  -- | Description : Updates RA_TERMS and RA_TERMS_LINES rows for        |
  -- |               consolidated billing term types.  It sets           |
  -- |               due_cutoff_day and due_day_of_month to the day      |
  -- |               of the month of the effective date.  This           |
  -- |               process must be run before consolidated billing     |
  -- |               invoices are generated each day.                    |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date          Author              Remarks                |
  -- |=======   ==========   =============        =======================|
  -- |1.0       13-FEB-2007  Terry Banks,         Initial version        |
  -- |                       Providge Consulting                         |
  -- |1.1       15-FEB-2007  Terry Banks          Changed to read all    |
  -- |                       Providge Consulting  RA_TERMS_B rows and    |
  -- |                                            make change if the     |
  -- |                                            DFF contains the day   |
  -- |                                            of the effective-date. |
  -- |1.2       05-JUL-2007  Terry Banks          Changed to take care   |
  -- |                       Providge Consulting  of new requirements.   |
  -- |                                            Essentially a total    |
  -- |                                            rewrite.               |
  -- |1.3       23-JUL-2007  Terry Banks          Changed to use OD EBS  |
  -- |                       Providge Consulting  Common Error logging.  |
  -- |                                                                   |
  -- |1.4       27-AUG-2007  Aravind A.           Fixed defect 1574      |
  -- |                       Wipro                                       |
  -- |                                                                   |
  -- |1.5       13-FEB-2008  Bushrod Thomas       Fixed Defect 4563      |
  -- |                                                                   |
  -- |1.6       26-FEB-2008  Bushrod Thomas       Fixed Defect 4906      |
  -- |                                                                   |
  -- |1.7       18-MAR-2008  Bushrod Thomas       Fixed reopened         |
  -- |                                            Defect 4906            |
  -- |                                                                   |
  -- |1.8       21-MAY-2008  Brian J Looman       Defect 6897, for EOM   |
  -- |                                            use first day rather   |
  -- |                                            than last day of month |
  -- |                                                                   |
  -- |1.9       15-SEP-2008  Greg Dill            Fixed Defect 11185     |
  -- |2.0       06-JAN-2008  Ranjith Prabu        Fix for defect 11993   |
  -- |2.1       11-APR-2012  Deepti S             CR 623 - Calculation   |
  -- |                                            of due date and        |
  -- |                                            discount cut off date  |
  -- |2.2       30-May-2012  Jay Gupta            comment discount update|
  -- |2.3       26-OCT-2015  Vasu Raparla         Removed schema         |
  -- |                                            references for 12.2    |
    -- +===================================================================+
PROCEDURE INCREMENT_CB_TERM
  (
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER
    --       ,p_effective_date     IN DATE := SYSDATE) next line added for 11185
    ,
    lc_effective_date IN VARCHAR2)
AS
  ln_conc_login NUMBER ;
  lc_day_name   VARCHAR2(9) ;
  --       next line added for 11185
  p_effective_date DATE ;
  lc_term_day_name     VARCHAR2(9) ;
  lc_term_week         VARCHAR2(2) ;
  ln_day_of_month      NUMBER ;
  lc_error_loc         VARCHAR2(100) ;
  lc_error_msg         VARCHAR2(500) ;
  lc_oracle_error_code VARCHAR2(256) ;
  lc_oracle_error_msg  VARCHAR2(256) ;
  lc_print_line        VARCHAR2(1000) ;
  ln_process_day       NUMBER ;  
  ln_next_date_index        NUMBER ;
  ln_last_day_of_month      NUMBER ;
  ln_last_day_of_next_month NUMBER ;
  lb_req_set_ret        BOOLEAN ;
  lc_value1             VARCHAR2(10) ;
  lc_value2             VARCHAR2(10) ;
  lc_temp_date          VARCHAR2(10) ;
  lc_month              VARCHAR2(3) ;
  lc_cur_month          VARCHAR2(3) ;
  ln_first_day_of_month NUMBER ;
  ln_date_val_num       NUMBER ;
  ln_new_day_of_month   NUMBER ; -- added for defect 11993
  -- v2.1
  ld_last_date_of_next_month DATE;
  ld_last_date DATE; 
  ld_process_date DATE; 
  
TYPE date_values_type
IS
  TABLE OF VARCHAR2(100); --Fixed defect 1574
  lt_date_values date_values_type;
  CURSOR C_CB_Term
  IS
    --  Select all RA_Terms rows
    --  consolidated billing terms
    --  as indicated by values in DFF1 and DFF2
    SELECT RT.term_id ,
      RT.due_cutoff_day ,
      UPPER(RT.attribute1) term_type ,
      UPPER(RT.attribute2) term ,
      RTL.name
    FROM RA_TERMS_B RT ,     --Removed ar schema Reference
      RA_TERMS_TL RTL ,      --Removed ar schema Reference
      RA_TERMS_LINES RTLS -- Added as a part of changes for defect 11993 --Removed ar schema Reference
    WHERE RT.attribute1       IS NOT NULL
    AND RT.attribute2         IS NOT NULL
    AND RT.term_id             = RTL.term_id
    AND RT.term_id             = RTLS.term_id
    AND RT.due_cutoff_day     IS NOT NULL -- Added as a part of changes for defect 11993
    AND RTLS.due_day_of_month IS NOT NULL -- Added as a part of changes for defect 11993
    FOR UPDATE OF RT.due_cutoff_day;
PROCEDURE lp_print
  (
    lp_line IN VARCHAR2 ,
    lp_both IN VARCHAR2)
            IS
BEGIN
  IF fnd_global.conc_request_id() >0 THEN
    CASE
    WHEN UPPER(lp_both) = 'BOTH' THEN
      fnd_file.put_line (fnd_file.log, lp_line);
      fnd_file.put_line (fnd_file.output, lp_line);
    WHEN UPPER(lp_both) = 'LOG' THEN
      fnd_file.put_line (fnd_file.log, lp_line);
    ELSE
      fnd_file.put_line (fnd_file.output, lp_line);
    END CASE;
  ELSE
    DBMS_OUTPUT.put_line (lp_line);
  END IF;
END;
PROCEDURE LP_UPDATE_TERM
  (
    lpv_term_id          IN NUMBER ,
    lpv_new_cutoff_day   IN NUMBER ,
    lpv_new_day_of_month IN NUMBER -- added for defect 11993
    ,
    lpv_term_name    IN VARCHAR2 ,
    lpv_process_date IN DATE  --v2.1
    )
   IS
  lpv_pline    VARCHAR2(100);
  lpv_pay_term NUMBER :=0;
  lpv_discount_date DATE;
  
  -- v2.1 Added for updation of due day, due months_forward and discount cut off day and discount months forward
  
  CURSOR lpv_disc_records
  IS
    SELECT *
    FROM ra_terms_lines_discounts
    WHERE term_id=lpv_term_id
    ORDER BY terms_lines_discount_id ;
BEGIN

    UPDATE RA_TERMS_B RTB   --Removed ar schema Reference
      SET RTB.due_cutoff_day = lpv_new_cutoff_day ,
        RTB.last_update_date = SYSDATE ,
        RTB.last_updated_by  = 4 -- Concurrent Manager
        , RTB.last_update_login = ln_conc_login
      WHERE RTB.term_id       = lpv_term_id ;
      
      lc_error_loc := 'Update of RA_TERMS ';

  -- To find due date
  BEGIN
    SELECT attribute3 INTO lpv_pay_term FROM ra_terms_b WHERE term_id=lpv_term_id;
   
    EXCEPTION WHEN NO_DATA_FOUND Then
    lc_error_loc := 'No Pay term Days present in DFF'; 
  END;
  
  UPDATE RA_TERMS_LINES RTL  --Removed ar schema Reference
  SET
    --   RTL.due_day_of_month  = lpv_new_cutoff_day  -- commented for defect 11993
    RTL.due_day_of_month   =TO_NUMBER(TO_CHAR((lpv_process_date             +lpv_pay_term),'DD')) ,
    RTL.due_months_forward = TRUNC(MONTHS_BETWEEN(last_day((lpv_process_date+lpv_pay_term)),last_day(lpv_process_date))) ,
    RTL.last_update_date   = SYSDATE ,
    RTL.last_updated_by    = 4 -- Concurrent Manager
    ,    RTL.last_update_login = ln_conc_login
  WHERE RTL.term_id       = lpv_term_id;
 
  -- to calculate discount
  
  lpv_discount_date := lpv_process_date;
  -- V2.2, Commented discount update
/*
  FOR disc_rec      IN lpv_disc_records
  LOOP
    UPDATE AR.RA_TERMS_LINES_DISCOUNTS RTLD
    SET
      RTLD.discount_day_of_month   =TO_NUMBER(TO_CHAR((lpv_discount_date             +disc_rec.attribute1),'DD')) ,
      RTLD.discount_months_forward = TRUNC(MONTHS_BETWEEN(last_day((lpv_discount_date+disc_rec.attribute1)),last_day(lpv_process_date))) ,
      RTLD.last_update_date        = SYSDATE ,
      RTLD.last_updated_by         = 4 -- Concurrent Manager
      , RTLD.last_update_login  = ln_conc_login
    WHERE RTLD.term_id        = disc_rec.term_id
    AND RTLD.discount_percent = disc_rec.discount_percent
    and rtld.terms_lines_discount_id =disc_rec.terms_lines_discount_id;
    
     END LOOP;
    lc_error_loc := 'Update of RA_TERMS_LINES_DISCOUNTS ';
*/
  -- v2.1 End 
  -- V2.2, End
  lpv_pline := 'Term ' || lpv_term_id || ' ' || lpv_term_name || ' had the due cutoff day set to: ' || lpv_new_cutoff_day || '.';
  lp_print (lpv_pline, 'OUT');
EXCEPTION
WHEN OTHERS THEN
  lc_oracle_error_msg  := SQLERRM ;
  lc_oracle_error_code := SQLCODE ;
  lc_error_msg         := ': Oracle Error: ' ||lc_oracle_error_code ||': '|| lc_oracle_error_msg ;
  lc_print_line        := 'Program Error for TERM: ' ||lpv_term_id ||' ' ||lpv_term_name ||' in ' ||lc_error_loc ||lc_error_msg ;
  lp_print (lc_print_line, 'BOTH') ;
  FND_MESSAGE.SET_NAME('XXFIN','XX_AR_CONS_BILL_TERM_PKG_ERR');
  FND_MESSAGE.SET_TOKEN('ERR_LOC',lc_error_loc);
  FND_MESSAGE.SET_TOKEN('ERR_ORA',lc_oracle_error_msg);
  lc_error_msg := FND_MESSAGE.GET;
  XX_COM_ERROR_LOG_PUB.LOG_ERROR( p_program_type => 'CONCURRENT PROGRAM' ,p_program_name => 'XXAR_INCR_CB_TERM' ,p_program_id => FND_GLOBAL.CONC_PROGRAM_ID ,p_module_name => 'AR' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 ,p_error_message_code => 'E' ,p_error_message => lc_error_msg ,p_error_message_severity => 'Major' ,p_notify_flag => 'N' ,p_object_type => 'UPDATE RA_TERMS_B/RA_TERMS_LINES' ,p_object_id => lpv_term_id );
END LP_UPDATE_TERM;

FUNCTION GET_DATE_VALUES
  (
    p_input IN VARCHAR2)
  RETURN date_values_type
IS
  ln_hyp_cnt  NUMBER;
  lc_temp_txt VARCHAR2(100) := p_input;
  lt_date_values date_values_type;
BEGIN
  ln_hyp_cnt     := LENGTH(p_input)-LENGTH(REPLACE(p_input,'-',''));
  lt_date_values := date_values_type(NULL);
  FOR i          IN 1..ln_hyp_cnt
  LOOP
    lt_date_values.extend;
    lt_date_values(i) := SUBSTR(lc_temp_txt,1,INSTR(lc_temp_txt,'-')-1);
    lc_temp_txt       := SUBSTR(lc_temp_txt,INSTR(lc_temp_txt,'-')  +1);
  END LOOP;
  lt_date_values(ln_hyp_cnt+1) := lc_temp_txt;
  RETURN lt_date_values;
END GET_DATE_VALUES;
BEGIN -- Start of Main Procedure
  --next line added for 11185
  p_effective_date           := TRUNC(NVL(fnd_conc_date.string_to_date(lc_effective_date),SYSDATE));
  lc_error_loc               := 'Get Concurrent Login ID';
  ln_conc_login              := FND_GLOBAL.CONC_LOGIN_ID;
  lc_error_loc               := 'Get Day Week of Month ';
  ln_day_of_month            := TO_NUMBER(TO_CHAR(p_effective_date,'DD'));
  ln_new_day_of_month        :=0;
  lc_day_name                := RTRIM(TO_CHAR(p_effective_date,'DAY'));
  ln_last_day_of_month       := TO_NUMBER(TO_CHAR(TRUNC(LAST_DAY(p_effective_date)), 'DD'));
    ln_last_day_of_next_month  := TO_NUMBER(TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(TRUNC(p_effective_date,'MM'),+1))), 'DD'));  
  lc_error_loc               := 'In Term Table Loop  ';
  ln_first_day_of_month      := 1;
  --v2.1
  ld_last_date               := LAST_DAY(p_effective_date); 
  ld_last_date_of_next_month := LAST_DAY(ADD_MONTHS(TRUNC(p_effective_date,'MM'), +1)); 
  
   <<Term_Table_Loop>> FOR rt IN C_CB_Term
  LOOP --  Loop through appropriate RA_Terms rows and update
    ln_process_day  := 0;
    ld_process_date :=NULL; --v2.1
    lc_error_loc    := 'Processing ' || rt.term_type || ' type ' || rt.term;
    CASE
    WHEN rt.term_type      = 'WEEK' THEN      --  row is a Day-of-The-Week type
      IF rt.term           = lc_day_name THEN -- i.e. MONDAY
        ln_process_day    := TO_NUMBER(TO_CHAR(NEXT_DAY(p_effective_date,lc_day_name),'DD'));
        ld_process_date   := NEXT_DAY(p_effective_date,lc_day_name); --v2.1
      ELSIF rt.term        ='WEEKDAYS' AND lc_day_name<>'SATURDAY' AND lc_day_name<>'SUNDAY' THEN
        IF lc_day_name     = 'FRIDAY' THEN
          ln_process_day  := TO_NUMBER(TO_CHAR(p_effective_date + 3, 'DD'));
          ld_process_date := p_effective_date                   + 3; --v2.1
        ELSE
          ln_process_day  := TO_NUMBER(TO_CHAR(p_effective_date + 1, 'DD'));
          ld_process_date := p_effective_date                   + 1; --v2.1
        END IF;
      END IF;
    WHEN rt.term_type    = 'MNTHDAY' THEN
   
      IF ln_day_of_month = ln_last_day_of_month THEN -- If run on 15-Feb-2008 with a term of THIRD FRIDAY, would bill twice in one month,
        -- so only update on last day of month
        lc_term_day_name := SUBSTR(rt.term,1,LENGTH(rt.term)-1); -- term up to last character
        lc_term_week     := SUBSTR(rt.term,                 -1);
        IF lc_term_week   = 'L' THEN -- e.g., term = MONDAYL, last character is L meaning last MONDAY of month.
          lc_temp_date   := TO_CHAR(p_effective_date);
          lc_cur_month   := TO_CHAR(TRUNC(ADD_MONTHS(p_effective_date,1), 'MONTH'),'MON');
          lc_month       := lc_cur_month;
          FOR i          IN 1..5
          LOOP
            EXIT
          WHEN lc_cur_month<>lc_month;
            lc_temp_date   := NEXT_DAY(TO_DATE(lc_temp_date),lc_term_day_name);
            lc_cur_month   := TO_CHAR(TRUNC(TO_DATE(lc_temp_date), 'MONTH'),'MON');
          END LOOP;
          IF lc_cur_month    = lc_month THEN
            ln_process_day  := TO_NUMBER(TO_CHAR(TO_DATE(lc_temp_date),'DD'));
            ld_process_date := TO_DATE(lc_temp_date); --v2.1
          ELSE
            ln_process_day  := TO_NUMBER(TO_CHAR(TO_DATE(lc_temp_date)-7,'DD'));
            ld_process_date := TO_DATE(lc_temp_date)                  -7; --v2.1
          END IF;
        ELSIF lc_term_week IN ('1','2','3','4') THEN                      -- e.g., MONDAY4
          lc_temp_date     := TO_CHAR(TRUNC(LAST_DAY(p_effective_date))); -- start from last day of this month
          FOR i            IN 1..TO_NUMBER(lc_term_week)
          LOOP
            lc_temp_date := TO_CHAR(NEXT_DAY(TO_DATE(lc_temp_date),lc_term_day_name));
          END LOOP;
          ln_process_day  := TO_NUMBER(TO_CHAR(TO_DATE(lc_temp_date),'DD'));
          ld_process_date := TO_DATE(lc_temp_date) ; --v2.1
        END IF;
      END IF;
    WHEN rt.term_type        ='MNTH' OR rt.term_type='SEMI' THEN
      IF INSTR(rt.term, '-') > 0 THEN
        lt_date_values      := GET_DATE_VALUES(rt.term);
        FOR j               IN 1..lt_date_values.COUNT
        LOOP
          BEGIN
            ln_date_val_num := TO_NUMBER(lt_date_values(j));
          EXCEPTION
          WHEN OTHERS THEN
            NULL; -- ignore if char to number errors, when value is EOM
          END;
          IF ( lt_date_values(j) = TO_CHAR(ln_day_of_month)
            -- defect 6897, for EOM use first day rather than last day
            --   OR (ln_day_of_month = ln_first_day_of_month AND lt_date_values(j) = 'EOM' ) -- commented for 11993
            OR (ln_day_of_month                   = ln_last_day_of_month AND lt_date_values(j) = 'EOM' ) -- added for 11993
            OR (ln_day_of_month                   = ln_last_day_of_month AND ln_date_val_num >= ln_last_day_of_month) ) THEN
            ln_next_date_index                   := MOD(j,lt_date_values.COUNT)+1;
            IF lt_date_values(ln_next_date_index) = 'EOM' THEN
              IF ln_day_of_month                  = ln_last_day_of_month THEN
                -- defect 6897, for EOM use first day rather than last day
                --ln_process_day := ln_last_day_of_next_month;
                -- ln_process_day := ln_first_day_of_month; -- commented for 11993
                ln_process_day  := ln_last_day_of_month; -- added for 11993
                ld_process_date := ld_last_date; --v2.1
              ELSE
                -- defect 6897, for EOM use first day rather than last day
                --ln_process_day := ln_last_day_of_month;
                -- ln_process_day := ln_first_day_of_month;  -- commented for 11993
                ln_process_day  := ln_last_day_of_month; -- added for 11993
                ld_process_date := ld_last_date; --v2.1
              END IF;
            ELSE
              ln_process_day                                   := TO_NUMBER(lt_date_values(ln_next_date_index));
            --  ld_process_date                                  :=p_effective_date;
              IF (TO_NUMBER(lt_date_values(ln_next_date_index)) >= ln_day_of_month) THEN
                ld_process_date    :=p_effective_date + ( (TO_NUMBER(lt_date_values(ln_next_date_index)))-ln_day_of_month ); --v2.1
              ELSE
                ld_process_date :=p_effective_date + ( (ln_last_day_of_month - ln_day_of_month + (TO_NUMBER(lt_date_values(ln_next_date_index)))) ); --v2.1
              END IF;
              IF ln_day_of_month   = ln_last_day_of_month THEN
                IF ln_process_day  > ln_last_day_of_next_month THEN
                  ln_process_day  := ln_last_day_of_next_month;
                  ld_process_date := ld_last_date_of_next_month; --v2.1
                END IF;
              ELSIF ln_process_day > ln_last_day_of_month THEN
                ln_process_day    := ln_last_day_of_month;
                ld_process_date   := ld_last_date_of_next_month; --v2.1
              END IF;
            END IF;
            EXIT;
          END IF;
        END LOOP;
        lt_date_values.DELETE;
        ELSIF rt.term = TO_CHAR(ln_day_of_month) then
            ln_process_day    := TO_NUMBER(TO_CHAR(p_effective_date, 'DD'));
            ld_process_date := ADD_MONTHS(p_effective_date,1) ;           
      END IF; -- End of MNTH, SEMI ELSIF test
    WHEN rt.term_type    = 'WDAY' THEN
      IF lc_day_name     ='THURSDAY' THEN
        ln_process_day  := TO_NUMBER(TO_CHAR(p_effective_date + 4, 'DD'));
        ld_process_date := p_effective_date                   + 4; --v2.1
      ELSIF lc_day_name  ='MONDAY' OR lc_day_name='TUESDAY' OR lc_day_name='WEDNESDAY' THEN
        ln_process_day  := TO_NUMBER(TO_CHAR(p_effective_date + 1, 'DD'));
        ld_process_date := p_effective_date                   + 1; --v2.1
      END IF;                                                      -- End of Weekday test
    WHEN rt.term_type  = 'DAIL' OR rt.term_type = 'DAILY' THEN
      ln_process_day  := TO_NUMBER(TO_CHAR(p_effective_date + 1, 'DD'));
      ld_process_date := p_effective_date                   + 1; --v2.1
    ELSE
      NULL;   -- unknown / unsupported term type
    END CASE; --  End of term_type test
    IF ln_process_day <> 0 THEN
      lc_error_loc    := 'Main Body Update Terms Block' ;
      -- Added for defect 11993
      ln_new_day_of_month := ln_process_day;
      IF (ln_process_day   = ln_last_day_of_month) THEN
        ln_process_day    := 32; -- value of 32 would ensure that 'last day of month' check box in payment term would be checked
      ELSE
        ln_process_day := ln_process_day+1;
      END IF;
      --  Changes end;
      --     LP_UPDATE_TERM(rt.term_id, ln_process_day, rt.name); --  Update terms tables row   commented for 11993
      LP_UPDATE_TERM(rt.term_id, ln_process_day, ln_new_day_of_month, rt.name, ld_process_date); --v2.1
      lp_print('Billing DATE : '|| ld_process_date, 'OUT'); 
      
    END IF;
  END LOOP; --  End of loop through terms tables
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  lc_oracle_error_msg  := SQLERRM;
  lc_oracle_error_code := SQLCODE;
  lc_error_msg         := ': Oracle Error: ' || lc_oracle_error_code || ': '|| lc_oracle_error_msg;
  lc_print_line        := 'Untrapped Program Error in ' || lc_error_loc || lc_error_msg;
  lp_print(lc_print_line, 'BOTH');
  IF FND_GLOBAL.CONC_REQUEST_ID()>0 THEN
    lb_req_set_ret              := FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR', '');
  END IF;
  XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type => 'CONCURRENT PROGRAM' ,p_program_name => 'XXAR_INCR_CB_TERM' ,p_program_id => FND_GLOBAL.CONC_PROGRAM_ID ,p_module_name => 'AR' ,p_error_location => 'Error at ' || lc_error_loc ,p_error_message_count => 1 ,p_error_message_code => 'E' ,p_error_message => lc_error_msg ,p_error_message_severity => 'Major' ,p_notify_flag => 'N');
END; --   End of Main Procedure
END; -- End Package
/