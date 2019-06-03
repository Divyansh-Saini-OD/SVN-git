CREATE OR REPLACE PACKAGE xx_mer_exec_cp_pkg AS
------------------------------------------------------------------------------------------------------
-- Package Name: xx_mer_exec_cp_pkg
-- Author:       Antonio Morales
-- Objective:    Excecute Concurrent Programs
-- Date:         13-Nov-2007
-- History:

------------------------------------------------------------------------------------------------------

 v_user_id           NUMBER := 0;                    -- EBs user id
 v_resp_id           NUMBER := 0;                    -- Responsibility_id (fnd_responsibility table)
                                                     -- All purchasing super user
 v_app_id            NUMBER := 0;                    -- Application_id from (fnd_responsibility table), 'XXMER''
 x_error_buff        VARCHAR2(300);
 x_ret_code          PLS_INTEGER := 0;
 v_rcode             NUMBER;                 

FUNCTION xx_mer_get_cp_default ( p_parname IN VARCHAR2,
                                 p_nrec    IN PLS_INTEGER
                               ) RETURN VARCHAR2;
                               
FUNCTION xx_mer_get_cp_npar    ( p_conc_pgm_shortname IN VARCHAR2
                               ) RETURN NUMBER;
                               
FUNCTION xx_mer_get_user_id    ( p_module_name        IN VARCHAR2
                                ,p_app_name           IN VARCHAR2
                                ,p_username           IN VARCHAR2
                               ) RETURN NUMBER;

FUNCTION exec_cp  ( p_module_name        IN VARCHAR2
                   ,p_app_name           IN VARCHAR2
                   ,p_conc_pgm_shortname IN VARCHAR2
                   ,p_username           IN VARCHAR2
                   ,argument1            IN VARCHAR2 DEFAULT chr(0)
                   ,argument2            IN VARCHAR2 DEFAULT chr(0)
                   ,argument3            IN VARCHAR2 DEFAULT chr(0)
                   ,argument4            IN VARCHAR2 DEFAULT chr(0)
                   ,argument5            IN VARCHAR2 DEFAULT chr(0)
                   ,argument6            IN VARCHAR2 DEFAULT chr(0)
                   ,argument7            IN VARCHAR2 DEFAULT chr(0)
                   ,argument8            IN VARCHAR2 DEFAULT chr(0)
                   ,argument9            IN VARCHAR2 DEFAULT chr(0)
                   ,argument10           IN VARCHAR2 DEFAULT chr(0)
                   ,argument11           IN VARCHAR2 DEFAULT chr(0)
                   ,argument12           IN VARCHAR2 DEFAULT chr(0)
                   ,argument13           IN VARCHAR2 DEFAULT chr(0)
                   ,argument14           IN VARCHAR2 DEFAULT chr(0)
                   ,argument15           IN VARCHAR2 DEFAULT chr(0)
                   ,argument16           IN VARCHAR2 DEFAULT chr(0)
                   ,argument18           IN VARCHAR2 DEFAULT chr(0)
                   ,argument19           IN VARCHAR2 DEFAULT chr(0)
                   ,argument20           IN VARCHAR2 DEFAULT chr(0)
                   ,argument21           IN VARCHAR2 DEFAULT chr(0)
                   ,argument22           IN VARCHAR2 DEFAULT chr(0)
                   ,argument23           IN VARCHAR2 DEFAULT chr(0)
                   ,argument24           IN VARCHAR2 DEFAULT chr(0)
                   ,argument25           IN VARCHAR2 DEFAULT chr(0)
                   ,argument26           IN VARCHAR2 DEFAULT chr(0)
                   ,argument27           IN VARCHAR2 DEFAULT chr(0)
                   ,argument28           IN VARCHAR2 DEFAULT chr(0)
                   ,argument29           IN VARCHAR2 DEFAULT chr(0)
                   ,argument30           IN VARCHAR2 DEFAULT chr(0)
                   ,argument31           IN VARCHAR2 DEFAULT chr(0)
                   ,argument32           IN VARCHAR2 DEFAULT chr(0)
                   ,argument33           IN VARCHAR2 DEFAULT chr(0)
                   ,argument34           IN VARCHAR2 DEFAULT chr(0)
                   ,argument35           IN VARCHAR2 DEFAULT chr(0)
                   ,argument36           IN VARCHAR2 DEFAULT chr(0)
                   ,argument37           IN VARCHAR2 DEFAULT chr(0)
                   ,argument38           IN VARCHAR2 DEFAULT chr(0)
                   ,argument39           IN VARCHAR2 DEFAULT chr(0)
                   ,argument40           IN VARCHAR2 DEFAULT chr(0)
                   ,argument41           IN VARCHAR2 DEFAULT chr(0)
                   ,argument42           IN VARCHAR2 DEFAULT chr(0)
                   ,argument43           IN VARCHAR2 DEFAULT chr(0)
                   ,argument44           IN VARCHAR2 DEFAULT chr(0)
                   ,argument45           IN VARCHAR2 DEFAULT chr(0)
                   ,argument46           IN VARCHAR2 DEFAULT chr(0)
                   ,argument47           IN VARCHAR2 DEFAULT chr(0)
                   ,argument48           IN VARCHAR2 DEFAULT chr(0)
                   ,argument49           IN VARCHAR2 DEFAULT chr(0)
                   ,argument50           IN VARCHAR2 DEFAULT chr(0)
                   ,argument51           IN VARCHAR2 DEFAULT chr(0)
                   ,argument52           IN VARCHAR2 DEFAULT chr(0)
                   ,argument53           IN VARCHAR2 DEFAULT chr(0)
                   ,argument54           IN VARCHAR2 DEFAULT chr(0)
                   ,argument55           IN VARCHAR2 DEFAULT chr(0)
                   ,argument56           IN VARCHAR2 DEFAULT chr(0)
                   ,argument57           IN VARCHAR2 DEFAULT chr(0)
                   ,argument58           IN VARCHAR2 DEFAULT chr(0)
                   ,argument59           IN VARCHAR2 DEFAULT chr(0)
                   ,argument60           IN VARCHAR2 DEFAULT chr(0)
                   ,argument61           IN VARCHAR2 DEFAULT chr(0)
                   ,argument62           IN VARCHAR2 DEFAULT chr(0)
                   ,argument63           IN VARCHAR2 DEFAULT chr(0)
                   ,argument64           IN VARCHAR2 DEFAULT chr(0)
                   ,argument65           IN VARCHAR2 DEFAULT chr(0)
                   ,argument66           IN VARCHAR2 DEFAULT chr(0)
                   ,argument67           IN VARCHAR2 DEFAULT chr(0)
                   ,argument68           IN VARCHAR2 DEFAULT chr(0)
                   ,argument69           IN VARCHAR2 DEFAULT chr(0)
                   ,argument70           IN VARCHAR2 DEFAULT chr(0)
                   ,argument71           IN VARCHAR2 DEFAULT chr(0)
                   ,argument72           IN VARCHAR2 DEFAULT chr(0)
                   ,argument73           IN VARCHAR2 DEFAULT chr(0)
                   ,argument74           IN VARCHAR2 DEFAULT chr(0)
                   ,argument75           IN VARCHAR2 DEFAULT chr(0)
                   ,argument76           IN VARCHAR2 DEFAULT chr(0)
                   ,argument77           IN VARCHAR2 DEFAULT chr(0)
                   ,argument78           IN VARCHAR2 DEFAULT chr(0)
                   ,argument79           IN VARCHAR2 DEFAULT chr(0)
                   ,argument80           IN VARCHAR2 DEFAULT chr(0)
                   ,argument81           IN VARCHAR2 DEFAULT chr(0)
                   ,argument82           IN VARCHAR2 DEFAULT chr(0)
                   ,argument83           IN VARCHAR2 DEFAULT chr(0)
                   ,argument84           IN VARCHAR2 DEFAULT chr(0)
                   ,argument85           IN VARCHAR2 DEFAULT chr(0)
                   ,argument86           IN VARCHAR2 DEFAULT chr(0)
                   ,argument87           IN VARCHAR2 DEFAULT chr(0)
                   ,argument88           IN VARCHAR2 DEFAULT chr(0)
                   ,argument89           IN VARCHAR2 DEFAULT chr(0)
                   ,argument90           IN VARCHAR2 DEFAULT chr(0)
                   ,argument91           IN VARCHAR2 DEFAULT chr(0)
                   ,argument92           IN VARCHAR2 DEFAULT chr(0)
                   ,argument93           IN VARCHAR2 DEFAULT chr(0)
                   ,argument94           IN VARCHAR2 DEFAULT chr(0)
                   ,argument95           IN VARCHAR2 DEFAULT chr(0)
                   ,argument96           IN VARCHAR2 DEFAULT chr(0)
                   ,argument97           IN VARCHAR2 DEFAULT chr(0)
                   ,argument98           IN VARCHAR2 DEFAULT chr(0)
                   ,argument99           IN VARCHAR2 DEFAULT chr(0)
                   ,argument100          IN VARCHAR2 DEFAULT chr(0)
                  ) RETURN NUMBER;

END xx_mer_exec_cp_pkg;