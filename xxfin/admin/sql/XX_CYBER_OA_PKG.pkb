CREATE OR REPLACE PACKAGE BODY APPS.cyber_oa_pkg 
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : CYBER_OA_PKG                                         |
-- | Description      : Cybermation package for submitting requests          |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    06-APR-2016   Paddy Sanjeevi    Initial code                  |
-- +=========================================================================+

AS
   FUNCTION SET_PRINT_OPTIONS (
            p_printer         IN VARCHAR2 default NULL,
            p_style         IN VARCHAR2 default NULL,
            p_copies         IN NUMBER     default NULL,
            p_save_output    IN NUMBER default 1,
            p_print_together IN VARCHAR2 default 'N')
            RETURN NUMBER
   IS
      saveOutputBool BOOLEAN := true;
      success   BOOLEAN  := FALSE;
      ret_succ  NUMBER := 0;

   BEGIN
      IF p_save_output = 0 then
         saveOutputBool := false;
      END IF;
      success := FND_REQUEST.SET_PRINT_OPTIONS(p_printer,
                                               p_style,
                                               p_copies,
                                               saveOutputBool,
                                               p_print_together);
      IF success=true then
         ret_succ := 1;
      END IF;
      RETURN(ret_succ);
   END SET_PRINT_OPTIONS;

   FUNCTION SET_SET_PRINT_OPTIONS(
            p_printer         IN VARCHAR2 default NULL,
            p_style         IN VARCHAR2 default NULL,
            p_copies         IN NUMBER     default NULL,
            p_save_output    IN NUMBER default 1,
            p_print_together IN VARCHAR2 default 'N')
            RETURN NUMBER
   IS
      saveOutputBool BOOLEAN := true;
      success   BOOLEAN  := FALSE;
      ret_succ  NUMBER := 0;

   BEGIN
      IF p_save_output = 0 then
         saveOutputBool := false;
      END IF;
      success := FND_SUBMIT.SET_PRINT_OPTIONS(p_printer,
                                               p_style,
                                               p_copies,
                                               saveOutputBool,
                                               p_print_together);
      IF success=true then
         ret_succ := 1;
      END IF;
      RETURN(ret_succ);
   END SET_SET_PRINT_OPTIONS;


   FUNCTION SUBMIT_REQUEST(
            p_cm_resp   IN VARCHAR2,
            p_cm_user   IN VARCHAR2,
            p_application IN VARCHAR2,
            p_program     IN VARCHAR2,
            p_description IN VARCHAR2 default NULL,
            p_argument1  IN VARCHAR2 default CHR (0),
            p_argument2  IN VARCHAR2 default CHR (0),
            p_argument3  IN VARCHAR2 default CHR (0),
            p_argument4  IN VARCHAR2 default CHR (0),
            p_argument5  IN VARCHAR2 default CHR (0),
            p_argument6  IN VARCHAR2 default CHR (0),
            p_argument7  IN VARCHAR2 default CHR (0),
            p_argument8  IN VARCHAR2 default CHR (0),
            p_argument9  IN VARCHAR2 default CHR (0),
            p_argument10 IN VARCHAR2 default CHR (0),
            p_argument11 IN VARCHAR2 default CHR (0),
            p_argument12 IN VARCHAR2 default CHR (0),
            p_argument13 IN VARCHAR2 default CHR (0),
            p_argument14 IN VARCHAR2 default CHR (0),
            p_argument15 IN VARCHAR2 default CHR (0),
            p_argument16 IN VARCHAR2 default CHR (0),
            p_argument17 IN VARCHAR2 default CHR (0),
            p_argument18 IN VARCHAR2 default CHR (0),
            p_argument19 IN VARCHAR2 default CHR (0),
            p_argument20 IN VARCHAR2 default CHR (0),
            p_argument21 IN VARCHAR2 default CHR (0),
            p_argument22 IN VARCHAR2 default CHR (0),
            p_argument23 IN VARCHAR2 default CHR (0),
            p_argument24 IN VARCHAR2 default CHR (0),
            p_argument25 IN VARCHAR2 default CHR (0),
            p_argument26 IN VARCHAR2 default CHR (0),
            p_argument27 IN VARCHAR2 default CHR (0),
            p_argument28 IN VARCHAR2 default CHR (0),
            p_argument29 IN VARCHAR2 default CHR (0),
            p_argument30 IN VARCHAR2 default CHR (0),
            p_argument31 IN VARCHAR2 default CHR (0),
            p_argument32 IN VARCHAR2 default CHR (0),
            p_argument33 IN VARCHAR2 default CHR (0),
            p_argument34 IN VARCHAR2 default CHR (0),
            p_argument35 IN VARCHAR2 default CHR (0),
            p_argument36 IN VARCHAR2 default CHR (0),
            p_argument37 IN VARCHAR2 default CHR (0),
            p_argument38 IN VARCHAR2 default CHR (0),
            p_argument39 IN VARCHAR2 default CHR (0),
            p_argument40 IN VARCHAR2 default CHR (0),
            p_argument41 IN VARCHAR2 default CHR (0),
            p_argument42 IN VARCHAR2 default CHR (0),
            p_argument43 IN VARCHAR2 default CHR (0),
            p_argument44 IN VARCHAR2 default CHR (0),
            p_argument45 IN VARCHAR2 default CHR (0),
            p_argument46 IN VARCHAR2 default CHR (0),
            p_argument47 IN VARCHAR2 default CHR (0),
            p_argument48 IN VARCHAR2 default CHR (0),
            p_argument49 IN VARCHAR2 default CHR (0),
            p_argument50 IN VARCHAR2 default CHR (0),
            p_argument51 IN VARCHAR2 default CHR (0),
            p_argument52 IN VARCHAR2 default CHR (0),
            p_argument53 IN VARCHAR2 default CHR (0),
            p_argument54 IN VARCHAR2 default CHR (0),
            p_argument55 IN VARCHAR2 default CHR (0),
            p_argument56 IN VARCHAR2 default CHR (0),
            p_argument57 IN VARCHAR2 default CHR (0),
            p_argument58 IN VARCHAR2 default CHR (0),
            p_argument59 IN VARCHAR2 default CHR (0),
            p_argument60 IN VARCHAR2 default CHR (0),
            p_argument61 IN VARCHAR2 default CHR (0),
            p_argument62 IN VARCHAR2 default CHR (0),
            p_argument63 IN VARCHAR2 default CHR (0),
            p_argument64 IN VARCHAR2 default CHR (0),
            p_argument65 IN VARCHAR2 default CHR (0),
            p_argument66 IN VARCHAR2 default CHR (0),
            p_argument67 IN VARCHAR2 default CHR (0),
            p_argument68 IN VARCHAR2 default CHR (0),
            p_argument69 IN VARCHAR2 default CHR (0),
            p_argument70 IN VARCHAR2 default CHR (0),
            p_argument71 IN VARCHAR2 default CHR (0),
            p_argument72 IN VARCHAR2 default CHR (0),
            p_argument73 IN VARCHAR2 default CHR (0),
            p_argument74 IN VARCHAR2 default CHR (0),
            p_argument75 IN VARCHAR2 default CHR (0),
            p_argument76 IN VARCHAR2 default CHR (0),
            p_argument77 IN VARCHAR2 default CHR (0),
            p_argument78 IN VARCHAR2 default CHR (0),
            p_argument79 IN VARCHAR2 default CHR (0),
            p_argument80 IN VARCHAR2 default CHR (0),
            p_argument81 IN VARCHAR2 default CHR (0),
            p_argument82 IN VARCHAR2 default CHR (0),
            p_argument83 IN VARCHAR2 default CHR (0),
            p_argument84 IN VARCHAR2 default CHR (0),
            p_argument85 IN VARCHAR2 default CHR (0),
            p_argument86 IN VARCHAR2 default CHR (0),
            p_argument87 IN VARCHAR2 default CHR (0),
            p_argument88 IN VARCHAR2 default CHR (0),
            p_argument89 IN VARCHAR2 default CHR (0),
            p_argument90 IN VARCHAR2 default CHR (0),
            p_argument91 IN VARCHAR2 default CHR (0),
            p_argument92 IN VARCHAR2 default CHR (0),
            p_argument93 IN VARCHAR2 default CHR (0),
            p_argument94 IN VARCHAR2 default CHR (0),
            p_argument95 IN VARCHAR2 default CHR (0),
            p_argument96 IN VARCHAR2 default CHR (0),
            p_argument97 IN VARCHAR2 default CHR (0),
            p_argument98 IN VARCHAR2 default CHR (0),
            p_argument99 IN VARCHAR2 default CHR (0),
            p_argument100 IN VARCHAR2 default CHR (0))
            RETURN NUMBER
     IS
          ret_REQUESTId  NUMBER := 0;
          l_goodval       BOOLEAN;
     BEGIN

        IF p_program='XX_COM_REQUEST_PKG_SUBMIT' THEN RETURN XX_COM_REQUEST_WRAPPER_PKG.submit_REQUEST(p_argument1); END IF;

        ret_REQUESTId := FND_REQUEST.submit_REQUEST(
                                      p_application,
                                      p_program,
                                      p_description,
                                      '',
                                      FALSE,
                                      p_argument1,
                                      p_argument2,
                                      p_argument3,
                                      p_argument4,
                                      p_argument5,
                                      p_argument6,
                                      p_argument7,
                                      p_argument8,
                                      p_argument9,
                                      p_argument10,
                                      p_argument11,
                                      p_argument12,
                                      p_argument13,
                                      p_argument14,
                                      p_argument15,
                                      p_argument16,
                                      p_argument17,
                                      p_argument18,
                                      p_argument19,
                                      p_argument20,
                                      p_argument21,
                                      p_argument22,
                                      p_argument23,
                                      p_argument24,
                                      p_argument25,
                                      p_argument26,
                                      p_argument27,
                                      p_argument28,
                                      p_argument29,
                                      p_argument30,
                                      p_argument31,
                                      p_argument32,
                                      p_argument33,
                                      p_argument34,
                                      p_argument35,
                                      p_argument36,
                                      p_argument37,
                                      p_argument38,
                                      p_argument39,
                                      p_argument40,
                                      p_argument41,
                                      p_argument42,
                                      p_argument43,
                                      p_argument44,
                                      p_argument45,
                                      p_argument46,
                                      p_argument47,
                                      p_argument48,
                                      p_argument49,
                                      p_argument50,
                                      p_argument51,
                                      p_argument52,
                                      p_argument53,
                                      p_argument54,
                                      p_argument55,
                                      p_argument56,
                                      p_argument57,
                                      p_argument58,
                                      p_argument59,
                                      p_argument60,
                                      p_argument61,
                                      p_argument62,
                                      p_argument63,
                                      p_argument64,
                                      p_argument65,
                                      p_argument66,
                                      p_argument67,
                                      p_argument68,
                                      p_argument69,
                                      p_argument70,
                                      p_argument71,
                                      p_argument72,
                                      p_argument73,
                                      p_argument74,
                                      p_argument75,
                                      p_argument76,
                                      p_argument77,
                                      p_argument78,
                                      p_argument79,
                                      p_argument80,
                                      p_argument81,
                                      p_argument82,
                                      p_argument83,
                                      p_argument84,
                                      p_argument85,
                                      p_argument86,
                                      p_argument87,
                                      p_argument88,
                                      p_argument89,
                                      p_argument90,
                                      p_argument91,
                                      p_argument92,
                                      p_argument93,
                                      p_argument94,
                                      p_argument95,
                                      p_argument96,
                                      p_argument97,
                                      p_argument98,
                                      p_argument99,
                                      p_argument100);

       COMMIT;

       RETURN(ret_REQUESTId);

    END SUBMIT_REQUEST;

   FUNCTION SUBMIT_PROGRAM(
            p_application IN VARCHAR2,
            p_program IN VARCHAR2,
            p_stage IN VARCHAR2,
            p_argument1 IN VARCHAR2 default CHR (0),
            p_argument2 IN VARCHAR2 default CHR (0),
            p_argument3 IN VARCHAR2 default CHR (0),
            p_argument4 IN VARCHAR2 default CHR (0),
            p_argument5 IN VARCHAR2 default CHR (0),
            p_argument6 IN VARCHAR2 default CHR (0),
            p_argument7 IN VARCHAR2 default CHR (0),
            p_argument8 IN VARCHAR2 default CHR (0),
            p_argument9 IN VARCHAR2 default CHR (0),
            p_argument10 IN VARCHAR2 default CHR (0),
            p_argument11 IN VARCHAR2 default CHR (0),
            p_argument12 IN VARCHAR2 default CHR (0),
            p_argument13 IN VARCHAR2 default CHR (0),
            p_argument14 IN VARCHAR2 default CHR (0),
            p_argument15 IN VARCHAR2 default CHR (0),
            p_argument16 IN VARCHAR2 default CHR (0),
            p_argument17 IN VARCHAR2 default CHR (0),
            p_argument18 IN VARCHAR2 default CHR (0),
            p_argument19 IN VARCHAR2 default CHR (0),
            p_argument20 IN VARCHAR2 default CHR (0),
            p_argument21 IN VARCHAR2 default CHR (0),
            p_argument22 IN VARCHAR2 default CHR (0),
            p_argument23 IN VARCHAR2 default CHR (0),
            p_argument24 IN VARCHAR2 default CHR (0),
            p_argument25 IN VARCHAR2 default CHR (0),
            p_argument26 IN VARCHAR2 default CHR (0),
            p_argument27 IN VARCHAR2 default CHR (0),
            p_argument28 IN VARCHAR2 default CHR (0),
            p_argument29 IN VARCHAR2 default CHR (0),
            p_argument30 IN VARCHAR2 default CHR (0),
            p_argument31 IN VARCHAR2 default CHR (0),
            p_argument32 IN VARCHAR2 default CHR (0),
            p_argument33 IN VARCHAR2 default CHR (0),
            p_argument34 IN VARCHAR2 default CHR (0),
            p_argument35 IN VARCHAR2 default CHR (0),
            p_argument36 IN VARCHAR2 default CHR (0),
            p_argument37 IN VARCHAR2 default CHR (0),
            p_argument38 IN VARCHAR2 default CHR (0),
            p_argument39 IN VARCHAR2 default CHR (0),
            p_argument40 IN VARCHAR2 default CHR (0),
            p_argument41 IN VARCHAR2 default CHR (0),
            p_argument42 IN VARCHAR2 default CHR (0),
            p_argument43 IN VARCHAR2 default CHR (0),
            p_argument44 IN VARCHAR2 default CHR (0),
            p_argument45 IN VARCHAR2 default CHR (0),
            p_argument46 IN VARCHAR2 default CHR (0),
            p_argument47 IN VARCHAR2 default CHR (0),
            p_argument48 IN VARCHAR2 default CHR (0),
            p_argument49 IN VARCHAR2 default CHR (0),
            p_argument50 IN VARCHAR2 default CHR (0),
            p_argument51 IN VARCHAR2 default CHR (0),
            p_argument52 IN VARCHAR2 default CHR (0),
            p_argument53 IN VARCHAR2 default CHR (0),
            p_argument54 IN VARCHAR2 default CHR (0),
            p_argument55 IN VARCHAR2 default CHR (0),
            p_argument56 IN VARCHAR2 default CHR (0),
            p_argument57 IN VARCHAR2 default CHR (0),
            p_argument58 IN VARCHAR2 default CHR (0),
            p_argument59 IN VARCHAR2 default CHR (0),
            p_argument60 IN VARCHAR2 default CHR (0),
            p_argument61 IN VARCHAR2 default CHR (0),
            p_argument62 IN VARCHAR2 default CHR (0),
            p_argument63 IN VARCHAR2 default CHR (0),
            p_argument64 IN VARCHAR2 default CHR (0),
            p_argument65 IN VARCHAR2 default CHR (0),
            p_argument66 IN VARCHAR2 default CHR (0),
            p_argument67 IN VARCHAR2 default CHR (0),
            p_argument68 IN VARCHAR2 default CHR (0),
            p_argument69 IN VARCHAR2 default CHR (0),
            p_argument70 IN VARCHAR2 default CHR (0),
            p_argument71 IN VARCHAR2 default CHR (0),
            p_argument72 IN VARCHAR2 default CHR (0),
            p_argument73 IN VARCHAR2 default CHR (0),
            p_argument74 IN VARCHAR2 default CHR (0),
            p_argument75 IN VARCHAR2 default CHR (0),
            p_argument76 IN VARCHAR2 default CHR (0),
            p_argument77 IN VARCHAR2 default CHR (0),
            p_argument78 IN VARCHAR2 default CHR (0),
            p_argument79 IN VARCHAR2 default CHR (0),
            p_argument80 IN VARCHAR2 default CHR (0),
            p_argument81 IN VARCHAR2 default CHR (0),
            p_argument82 IN VARCHAR2 default CHR (0),
            p_argument83 IN VARCHAR2 default CHR (0),
            p_argument84 IN VARCHAR2 default CHR (0),
            p_argument85 IN VARCHAR2 default CHR (0),
            p_argument86 IN VARCHAR2 default CHR (0),
            p_argument87 IN VARCHAR2 default CHR (0),
            p_argument88 IN VARCHAR2 default CHR (0),
            p_argument89 IN VARCHAR2 default CHR (0),
            p_argument90 IN VARCHAR2 default CHR (0),
            p_argument91 IN VARCHAR2 default CHR (0),
            p_argument92 IN VARCHAR2 default CHR (0),
            p_argument93 IN VARCHAR2 default CHR (0),
            p_argument94 IN VARCHAR2 default CHR (0),
            p_argument95 IN VARCHAR2 default CHR (0),
            p_argument96 IN VARCHAR2 default CHR (0),
            p_argument97 IN VARCHAR2 default CHR (0),
            p_argument98 IN VARCHAR2 default CHR (0),
            p_argument99 IN VARCHAR2 default CHR (0),
            p_argument100 IN VARCHAR2 default CHR (0))
                        RETURN NUMBER
    IS
       success BOOLEAN  := FALSE;
       ret_succ  NUMBER := 0;
       msg VARCHAR2(2000);

    BEGIN

        success := FND_SUBMIT.SUBMIT_PROGRAM(
                                      p_application,
                                      p_program,
                                      p_stage,
                                      p_argument1,
                                      p_argument2,
                                      p_argument3,
                                      p_argument4,
                                      p_argument5,
                                      p_argument6,
                                      p_argument7,
                                      p_argument8,
                                      p_argument9,
                                      p_argument10,
                                      p_argument11,
                                      p_argument12,
                                      p_argument13,
                                      p_argument14,
                                      p_argument15,
                                      p_argument16,
                                      p_argument17,
                                      p_argument18,
                                      p_argument19,
                                      p_argument20,
                                      p_argument21,
                                      p_argument22,
                                      p_argument23,
                                      p_argument24,
                                      p_argument25,
                                      p_argument26,
                                      p_argument27,
                                      p_argument28,
                                      p_argument29,
                                      p_argument30,
                                      p_argument31,
                                      p_argument32,
                                      p_argument33,
                                      p_argument34,
                                      p_argument35,
                                      p_argument36,
                                      p_argument37,
                                      p_argument38,
                                      p_argument39,
                                      p_argument40,
                                      p_argument41,
                                      p_argument42,
                                      p_argument43,
                                      p_argument44,
                                      p_argument45,
                                      p_argument46,
                                      p_argument47,
                                      p_argument48,
                                      p_argument49,
                                      p_argument50,
                                      p_argument51,
                                      p_argument52,
                                      p_argument53,
                                      p_argument54,
                                      p_argument55,
                                      p_argument56,
                                      p_argument57,
                                      p_argument58,
                                      p_argument59,
                                      p_argument60,
                                      p_argument61,
                                      p_argument62,
                                      p_argument63,
                                      p_argument64,
                                      p_argument65,
                                      p_argument66,
                                      p_argument67,
                                      p_argument68,
                                      p_argument69,
                                      p_argument70,
                                      p_argument71,
                                      p_argument72,
                                      p_argument73,
                                      p_argument74,
                                      p_argument75,
                                      p_argument76,
                                      p_argument77,
                                      p_argument78,
                                      p_argument79,
                                      p_argument80,
                                      p_argument81,
                                      p_argument82,
                                      p_argument83,
                                      p_argument84,
                                      p_argument85,
                                      p_argument86,
                                      p_argument87,
                                      p_argument88,
                                      p_argument89,
                                      p_argument90,
                                      p_argument91,
                                      p_argument92,
                                      p_argument93,
                                      p_argument94,
                                      p_argument95,
                                      p_argument96,
                                      p_argument97,
                                      p_argument98,
                                      p_argument99,
                                      p_argument100);


       IF success then
          ret_succ := 1;
         END IF;

       RETURN(ret_succ);
   END SUBMIT_PROGRAM;


   FUNCTION SET_REQUEST_SET
        (p_application IN VARCHAR2,
        p_request_set IN VARCHAR2)
        RETURN NUMBER
   IS
     success BOOLEAN  := FALSE;
     ret_succ  NUMBER := 0;

   BEGIN

     success := FND_SUBMIT.SET_REQUEST_SET(p_application, p_request_set);

     IF success=true then
        ret_succ := 1;
        COMMIT;
     END IF;
     RETURN(ret_succ);

   END SET_REQUEST_SET;


   FUNCTION SUBMIT_SET RETURN NUMBER
   IS
   BEGIN
           RETURN (FND_SUBMIT.SUBMIT_SET('', FALSE));
   END SUBMIT_SET;


   FUNCTION GET_REQUEST_STATUS
        (p_request_id IN OUT NUMBER,
        p_phase OUT VARCHAR2,
        p_status OUT VARCHAR2,
        p_dev_phase OUT VARCHAR2,
        p_dev_status OUT VARCHAR2,
        p_message OUT VARCHAR2)
        RETURN NUMBER IS
     success BOOLEAN  := FALSE;
     ret_succ  NUMBER := 0;

   BEGIN
      success := FND_CONCURRENT.GET_REQUEST_STATUS( p_request_id,
                                                    '',
                                                    '',
                                                    p_phase,
                                                    p_status,
                                                    p_dev_phase,
                                                    p_dev_status,
                                                    p_message);
      IF success=true then
         ret_succ := 1;
      END IF;
      RETURN(ret_succ);

   END GET_REQUEST_STATUS;

   FUNCTION CHILDREN_DONE(p_parentId IN NUMBER)
   RETURN NUMBER
   IS
        success  BOOLEAN  := FALSE;
     ret_succ NUMBER   := 0;
   BEGIN
      success := FND_CONCURRENT.CHILDREN_DONE(p_parentId,
                                                'Y');
      IF success=true then
         ret_succ := 1;
      END IF;
      RETURN(ret_succ);

   END CHILDREN_DONE;

   FUNCTION GET_SUB_REQUESTS( p_parentId IN NUMBER)
   RETURN VARCHAR2
   IS
      v_tab     FND_CONCURRENT.REQUESTS_TAB_TYPE;
      v_tab2     FND_CONCURRENT.REQUESTS_TAB_TYPE;
      v_tab3     FND_CONCURRENT.REQUESTS_TAB_TYPE;
      v_tab4     FND_CONCURRENT.REQUESTS_TAB_TYPE;
      v_tab5     FND_CONCURRENT.REQUESTS_TAB_TYPE;
      e_req_not_found    EXCEPTION;
      ret_subRequests VARCHAR2(2000) := NULL;
   BEGIN

     v_tab := FND_CONCURRENT.GET_SUB_REQUESTS(p_parentId);

     -- see IF we got anything back

     IF v_tab.EXISTS(1) THEN

        -- we did, pop the results off the table

        FOR i IN v_tab.FIRST..v_tab.LAST LOOP
           IF v_tab(i).dev_status <> 'NORMAL' THEN

               ret_subRequests := ret_subRequests || v_tab(i).request_id || ' ' ||
                                     v_tab(i).dev_status || ' ';
           END IF;
           --------------------------------------------------
           -- now, get results of this sub_REQUEST's children
           --------------------------------------------------

           v_tab2 := FND_CONCURRENT.GET_SUB_REQUESTS(v_tab(i).request_id);

           ----------------------------------------
           -- see IF we got anything back this time
           ----------------------------------------

           IF v_tab2.EXISTS(1) THEN

              -- we did, pop the results off this table

              FOR j IN v_tab2.FIRST..v_tab2.LAST LOOP
                IF v_tab2(j).dev_status <> 'NORMAL' THEN

                        ret_subRequests := ret_subRequests || v_tab2(j).request_id || ' ' ||
                                     v_tab2(j).dev_status || ' ';
                END IF;

                v_tab3 := FND_CONCURRENT.GET_SUB_REQUESTS(v_tab2(j).request_id);

                ----------------------------------------
                -- see IF we got anything back this time
                ----------------------------------------

                IF v_tab3.EXISTS(1) THEN

                  -- we did, pop the results off this table

                  FOR k IN v_tab3.FIRST..v_tab3.LAST LOOP
                    IF v_tab3(k).dev_status <> 'NORMAL' THEN

                      ret_subRequests := ret_subRequests || v_tab3(k).request_id || ' ' ||
                                         v_tab3(k).dev_status || ' ';
                    END IF; --v_tab3 p_status <> NORMAL

                    v_tab4 := FND_CONCURRENT.GET_SUB_REQUESTS(v_tab3(k).request_id);

                    ----------------------------------------
                    -- see IF we got anything back this time
                    ----------------------------------------

                    IF v_tab4.EXISTS(1) THEN

                      -- we did, pop the results off this table

                      FOR l IN v_tab4.FIRST..v_tab4.LAST LOOP
                        IF v_tab4(l).dev_status <> 'NORMAL' THEN

                        ret_subRequests := ret_subRequests || v_tab4(l).request_id || ' ' ||
                    		 v_tab4(l).dev_status || ' ';
                        END IF; --v_tab4 p_status <> NORMAL

                        v_tab5 := FND_CONCURRENT.GET_SUB_REQUESTS(v_tab4(l).request_id);

                        ----------------------------------------
                        -- see IF we got anything back this time
                        ----------------------------------------

                        IF v_tab5.EXISTS(1) THEN

                          -- we did, pop the results off this table

                          FOR m IN v_tab5.FIRST..v_tab5.LAST LOOP
                            IF v_tab5(m).dev_status <> 'NORMAL' THEN

                              ret_subRequests := ret_subRequests || v_tab5(m).request_id || ' ' ||
                                               v_tab5(m).dev_status || ' ';
                            END IF; -- v_tab5 p_status <> NORMAL
                          END LOOP; -- v_tab5

                        END IF;	    -- v_tab5.EXISTS

                      END LOOP; -- v_tab4
                    END IF;     -- v_tab4.EXISTS
                  END LOOP; -- v_tab3
                END IF;     -- v_tab3.EXISTS
              END LOOP; -- v_tab2
           END IF;      -- v_tab2.EXISTS
        END LOOP; --v_tab
     END IF;      --v_tab.EXISTS

     RETURN ret_subRequests;

   END GET_SUB_REQUESTS;

END cyber_oa_pkg;
/

