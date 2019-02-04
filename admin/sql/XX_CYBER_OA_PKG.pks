CREATE OR REPLACE PACKAGE apps.cyber_oa_pkg AS
-- -----------------------------------------------------------------------------
-- Copyright 2004 Cybermation Inc.
-- All Rights Reserved
--
-- Name           : CYBER_OA_PKG
-- Creation Date  : May 2004
-- Author         : Art Muszynski
--
-- Description : Cybermation package for submitting requests to
--                Oracle Application 11i concurrent manager.
--
-- Dependencies Tables        : None
-- Dependencies Views         : None
-- Dependencies Sequences     : None
-- Dependencies Procedures    : None
-- Dependencies Functions     : None
-- Dependencies Packages      : FND_PROFILE, FND_CONCURRENT, FND_REQUEST
-- Dependencies Types         : None
-- Dependencies Database Links: None
--
-- Modification History:
--
-- Date         Name           Modifications
-- ------------ -------------- ----------------------------------------------------
-- 04-Oct-2003  Art Muszynski  Have 5 levels of depth for GET_SUB_REQUESTS.
-- 12-Oct-2003  Art Muszynski  Add SET_SET_PRINT_OPTIONS.
--------------- -------------- ----------------------------------------------------

   FUNCTION SET_PRINT_OPTIONS (
            p_printer      IN VARCHAR2 DEFAULT NULL,
            p_style        IN VARCHAR2 DEFAULT NULL,
            p_copies       IN NUMBER  DEFAULT NULL,
            p_save_output  IN NUMBER DEFAULT 1,
            p_print_together IN VARCHAR2 DEFAULT 'N')
            RETURN NUMBER;

   FUNCTION SET_SET_PRINT_OPTIONS (
            p_printer      IN VARCHAR2 DEFAULT NULL,
            p_style        IN VARCHAR2 DEFAULT NULL,
            p_copies       IN NUMBER  DEFAULT NULL,
            p_save_output  IN NUMBER DEFAULT 1,
            p_print_together IN VARCHAR2 DEFAULT 'N')
            RETURN NUMBER;

   FUNCTION SUBMIT_REQUEST(
            p_cm_resp   IN VARCHAR2,
            p_cm_user   IN VARCHAR2,
            p_application IN VARCHAR2,
            p_program     IN VARCHAR2,
            p_description IN VARCHAR2 DEFAULT NULL,
            p_argument1  IN VARCHAR2 DEFAULT CHR (0),
            p_argument2  IN VARCHAR2 DEFAULT CHR (0),
            p_argument3  IN VARCHAR2 DEFAULT CHR (0),
            p_argument4  IN VARCHAR2 DEFAULT CHR (0),
            p_argument5  IN VARCHAR2 DEFAULT CHR (0),
            p_argument6  IN VARCHAR2 DEFAULT CHR (0),
            p_argument7  IN VARCHAR2 DEFAULT CHR (0),
            p_argument8  IN VARCHAR2 DEFAULT CHR (0),
            p_argument9  IN VARCHAR2 DEFAULT CHR (0),
            p_argument10 IN VARCHAR2 DEFAULT CHR (0),
            p_argument11 IN VARCHAR2 DEFAULT CHR (0),
            p_argument12 IN VARCHAR2 DEFAULT CHR (0),
            p_argument13 IN VARCHAR2 DEFAULT CHR (0),
            p_argument14 IN VARCHAR2 DEFAULT CHR (0),
            p_argument15 IN VARCHAR2 DEFAULT CHR (0),
            p_argument16 IN VARCHAR2 DEFAULT CHR (0),
            p_argument17 IN VARCHAR2 DEFAULT CHR (0),
            p_argument18 IN VARCHAR2 DEFAULT CHR (0),
            p_argument19 IN VARCHAR2 DEFAULT CHR (0),
            p_argument20 IN VARCHAR2 DEFAULT CHR (0),
            p_argument21 IN VARCHAR2 DEFAULT CHR (0),
            p_argument22 IN VARCHAR2 DEFAULT CHR (0),
            p_argument23 IN VARCHAR2 DEFAULT CHR (0),
            p_argument24 IN VARCHAR2 DEFAULT CHR (0),
            p_argument25 IN VARCHAR2 DEFAULT CHR (0),
            p_argument26 IN VARCHAR2 DEFAULT CHR (0),
            p_argument27 IN VARCHAR2 DEFAULT CHR (0),
            p_argument28 IN VARCHAR2 DEFAULT CHR (0),
            p_argument29 IN VARCHAR2 DEFAULT CHR (0),
            p_argument30 IN VARCHAR2 DEFAULT CHR (0),
            p_argument31 IN VARCHAR2 DEFAULT CHR (0),
            p_argument32 IN VARCHAR2 DEFAULT CHR (0),
            p_argument33 IN VARCHAR2 DEFAULT CHR (0),
            p_argument34 IN VARCHAR2 DEFAULT CHR (0),
            p_argument35 IN VARCHAR2 DEFAULT CHR (0),
            p_argument36 IN VARCHAR2 DEFAULT CHR (0),
            p_argument37 IN VARCHAR2 DEFAULT CHR (0),
            p_argument38 IN VARCHAR2 DEFAULT CHR (0),
            p_argument39 IN VARCHAR2 DEFAULT CHR (0),
            p_argument40 IN VARCHAR2 DEFAULT CHR (0),
            p_argument41 IN VARCHAR2 DEFAULT CHR (0),
            p_argument42 IN VARCHAR2 DEFAULT CHR (0),
            p_argument43 IN VARCHAR2 DEFAULT CHR (0),
            p_argument44 IN VARCHAR2 DEFAULT CHR (0),
            p_argument45 IN VARCHAR2 DEFAULT CHR (0),
            p_argument46 IN VARCHAR2 DEFAULT CHR (0),
            p_argument47 IN VARCHAR2 DEFAULT CHR (0),
            p_argument48 IN VARCHAR2 DEFAULT CHR (0),
            p_argument49 IN VARCHAR2 DEFAULT CHR (0),
            p_argument50 IN VARCHAR2 DEFAULT CHR (0),
            p_argument51 IN VARCHAR2 DEFAULT CHR (0),
            p_argument52 IN VARCHAR2 DEFAULT CHR (0),
            p_argument53 IN VARCHAR2 DEFAULT CHR (0),
            p_argument54 IN VARCHAR2 DEFAULT CHR (0),
            p_argument55 IN VARCHAR2 DEFAULT CHR (0),
            p_argument56 IN VARCHAR2 DEFAULT CHR (0),
            p_argument57 IN VARCHAR2 DEFAULT CHR (0),
            p_argument58 IN VARCHAR2 DEFAULT CHR (0),
            p_argument59 IN VARCHAR2 DEFAULT CHR (0),
            p_argument60 IN VARCHAR2 DEFAULT CHR (0),
            p_argument61 IN VARCHAR2 DEFAULT CHR (0),
            p_argument62 IN VARCHAR2 DEFAULT CHR (0),
            p_argument63 IN VARCHAR2 DEFAULT CHR (0),
            p_argument64 IN VARCHAR2 DEFAULT CHR (0),
            p_argument65 IN VARCHAR2 DEFAULT CHR (0),
            p_argument66 IN VARCHAR2 DEFAULT CHR (0),
            p_argument67 IN VARCHAR2 DEFAULT CHR (0),
            p_argument68 IN VARCHAR2 DEFAULT CHR (0),
            p_argument69 IN VARCHAR2 DEFAULT CHR (0),
            p_argument70 IN VARCHAR2 DEFAULT CHR (0),
            p_argument71 IN VARCHAR2 DEFAULT CHR (0),
            p_argument72 IN VARCHAR2 DEFAULT CHR (0),
            p_argument73 IN VARCHAR2 DEFAULT CHR (0),
            p_argument74 IN VARCHAR2 DEFAULT CHR (0),
            p_argument75 IN VARCHAR2 DEFAULT CHR (0),
            p_argument76 IN VARCHAR2 DEFAULT CHR (0),
            p_argument77 IN VARCHAR2 DEFAULT CHR (0),
            p_argument78 IN VARCHAR2 DEFAULT CHR (0),
            p_argument79 IN VARCHAR2 DEFAULT CHR (0),
            p_argument80 IN VARCHAR2 DEFAULT CHR (0),
            p_argument81 IN VARCHAR2 DEFAULT CHR (0),
            p_argument82 IN VARCHAR2 DEFAULT CHR (0),
            p_argument83 IN VARCHAR2 DEFAULT CHR (0),
            p_argument84 IN VARCHAR2 DEFAULT CHR (0),
            p_argument85 IN VARCHAR2 DEFAULT CHR (0),
            p_argument86 IN VARCHAR2 DEFAULT CHR (0),
            p_argument87 IN VARCHAR2 DEFAULT CHR (0),
            p_argument88 IN VARCHAR2 DEFAULT CHR (0),
            p_argument89 IN VARCHAR2 DEFAULT CHR (0),
            p_argument90 IN VARCHAR2 DEFAULT CHR (0),
            p_argument91 IN VARCHAR2 DEFAULT CHR (0),
            p_argument92 IN VARCHAR2 DEFAULT CHR (0),
            p_argument93 IN VARCHAR2 DEFAULT CHR (0),
            p_argument94 IN VARCHAR2 DEFAULT CHR (0),
            p_argument95 IN VARCHAR2 DEFAULT CHR (0),
            p_argument96 IN VARCHAR2 DEFAULT CHR (0),
            p_argument97 IN VARCHAR2 DEFAULT CHR (0),
            p_argument98 IN VARCHAR2 DEFAULT CHR (0),
            p_argument99 IN VARCHAR2 DEFAULT CHR (0),
            p_argument100 IN VARCHAR2 DEFAULT CHR (0))
            RETURN NUMBER;

   FUNCTION SUBMIT_PROGRAM(
            p_application IN VARCHAR2,
            p_program IN VARCHAR2,
            p_stage IN VARCHAR2,
            p_argument1 IN VARCHAR2 DEFAULT CHR (0),
            p_argument2 IN VARCHAR2 DEFAULT CHR (0),
            p_argument3 IN VARCHAR2 DEFAULT CHR (0),
            p_argument4 IN VARCHAR2 DEFAULT CHR (0),
            p_argument5 IN VARCHAR2 DEFAULT CHR (0),
            p_argument6 IN VARCHAR2 DEFAULT CHR (0),
            p_argument7 IN VARCHAR2 DEFAULT CHR (0),
            p_argument8 IN VARCHAR2 DEFAULT CHR (0),
            p_argument9 IN VARCHAR2 DEFAULT CHR (0),
            p_argument10 IN VARCHAR2 DEFAULT CHR (0),
            p_argument11 IN VARCHAR2 DEFAULT CHR (0),
            p_argument12 IN VARCHAR2 DEFAULT CHR (0),
            p_argument13 IN VARCHAR2 DEFAULT CHR (0),
            p_argument14 IN VARCHAR2 DEFAULT CHR (0),
            p_argument15 IN VARCHAR2 DEFAULT CHR (0),
            p_argument16 IN VARCHAR2 DEFAULT CHR (0),
            p_argument17 IN VARCHAR2 DEFAULT CHR (0),
            p_argument18 IN VARCHAR2 DEFAULT CHR (0),
            p_argument19 IN VARCHAR2 DEFAULT CHR (0),
            p_argument20 IN VARCHAR2 DEFAULT CHR (0),
            p_argument21 IN VARCHAR2 DEFAULT CHR (0),
            p_argument22 IN VARCHAR2 DEFAULT CHR (0),
            p_argument23 IN VARCHAR2 DEFAULT CHR (0),
            p_argument24 IN VARCHAR2 DEFAULT CHR (0),
            p_argument25 IN VARCHAR2 DEFAULT CHR (0),
            p_argument26 IN VARCHAR2 DEFAULT CHR (0),
            p_argument27 IN VARCHAR2 DEFAULT CHR (0),
            p_argument28 IN VARCHAR2 DEFAULT CHR (0),
            p_argument29 IN VARCHAR2 DEFAULT CHR (0),
            p_argument30 IN VARCHAR2 DEFAULT CHR (0),
            p_argument31 IN VARCHAR2 DEFAULT CHR (0),
            p_argument32 IN VARCHAR2 DEFAULT CHR (0),
            p_argument33 IN VARCHAR2 DEFAULT CHR (0),
            p_argument34 IN VARCHAR2 DEFAULT CHR (0),
            p_argument35 IN VARCHAR2 DEFAULT CHR (0),
            p_argument36 IN VARCHAR2 DEFAULT CHR (0),
            p_argument37 IN VARCHAR2 DEFAULT CHR (0),
            p_argument38 IN VARCHAR2 DEFAULT CHR (0),
            p_argument39 IN VARCHAR2 DEFAULT CHR (0),
            p_argument40 IN VARCHAR2 DEFAULT CHR (0),
            p_argument41 IN VARCHAR2 DEFAULT CHR (0),
            p_argument42 IN VARCHAR2 DEFAULT CHR (0),
            p_argument43 IN VARCHAR2 DEFAULT CHR (0),
            p_argument44 IN VARCHAR2 DEFAULT CHR (0),
            p_argument45 IN VARCHAR2 DEFAULT CHR (0),
            p_argument46 IN VARCHAR2 DEFAULT CHR (0),
            p_argument47 IN VARCHAR2 DEFAULT CHR (0),
            p_argument48 IN VARCHAR2 DEFAULT CHR (0),
            p_argument49 IN VARCHAR2 DEFAULT CHR (0),
            p_argument50 IN VARCHAR2 DEFAULT CHR (0),
            p_argument51 IN VARCHAR2 DEFAULT CHR (0),
            p_argument52 IN VARCHAR2 DEFAULT CHR (0),
            p_argument53 IN VARCHAR2 DEFAULT CHR (0),
            p_argument54 IN VARCHAR2 DEFAULT CHR (0),
            p_argument55 IN VARCHAR2 DEFAULT CHR (0),
            p_argument56 IN VARCHAR2 DEFAULT CHR (0),
            p_argument57 IN VARCHAR2 DEFAULT CHR (0),
            p_argument58 IN VARCHAR2 DEFAULT CHR (0),
            p_argument59 IN VARCHAR2 DEFAULT CHR (0),
            p_argument60 IN VARCHAR2 DEFAULT CHR (0),
            p_argument61 IN VARCHAR2 DEFAULT CHR (0),
            p_argument62 IN VARCHAR2 DEFAULT CHR (0),
            p_argument63 IN VARCHAR2 DEFAULT CHR (0),
            p_argument64 IN VARCHAR2 DEFAULT CHR (0),
            p_argument65 IN VARCHAR2 DEFAULT CHR (0),
            p_argument66 IN VARCHAR2 DEFAULT CHR (0),
            p_argument67 IN VARCHAR2 DEFAULT CHR (0),
            p_argument68 IN VARCHAR2 DEFAULT CHR (0),
            p_argument69 IN VARCHAR2 DEFAULT CHR (0),
            p_argument70 IN VARCHAR2 DEFAULT CHR (0),
            p_argument71 IN VARCHAR2 DEFAULT CHR (0),
            p_argument72 IN VARCHAR2 DEFAULT CHR (0),
            p_argument73 IN VARCHAR2 DEFAULT CHR (0),
            p_argument74 IN VARCHAR2 DEFAULT CHR (0),
            p_argument75 IN VARCHAR2 DEFAULT CHR (0),
            p_argument76 IN VARCHAR2 DEFAULT CHR (0),
            p_argument77 IN VARCHAR2 DEFAULT CHR (0),
            p_argument78 IN VARCHAR2 DEFAULT CHR (0),
            p_argument79 IN VARCHAR2 DEFAULT CHR (0),
            p_argument80 IN VARCHAR2 DEFAULT CHR (0),
            p_argument81 IN VARCHAR2 DEFAULT CHR (0),
            p_argument82 IN VARCHAR2 DEFAULT CHR (0),
            p_argument83 IN VARCHAR2 DEFAULT CHR (0),
            p_argument84 IN VARCHAR2 DEFAULT CHR (0),
            p_argument85 IN VARCHAR2 DEFAULT CHR (0),
            p_argument86 IN VARCHAR2 DEFAULT CHR (0),
            p_argument87 IN VARCHAR2 DEFAULT CHR (0),
            p_argument88 IN VARCHAR2 DEFAULT CHR (0),
            p_argument89 IN VARCHAR2 DEFAULT CHR (0),
            p_argument90 IN VARCHAR2 DEFAULT CHR (0),
            p_argument91 IN VARCHAR2 DEFAULT CHR (0),
            p_argument92 IN VARCHAR2 DEFAULT CHR (0),
            p_argument93 IN VARCHAR2 DEFAULT CHR (0),
            p_argument94 IN VARCHAR2 DEFAULT CHR (0),
            p_argument95 IN VARCHAR2 DEFAULT CHR (0),
            p_argument96 IN VARCHAR2 DEFAULT CHR (0),
            p_argument97 IN VARCHAR2 DEFAULT CHR (0),
            p_argument98 IN VARCHAR2 DEFAULT CHR (0),
            p_argument99 IN VARCHAR2 DEFAULT CHR (0),
            p_argument100 IN VARCHAR2 DEFAULT CHR (0))
            RETURN NUMBER;

   FUNCTION SET_REQUEST_SET(
            p_application IN VARCHAR2,
            p_request_set IN VARCHAR2)
            RETURN NUMBER;

   FUNCTION SUBMIT_SET RETURN NUMBER;

   FUNCTION GET_REQUEST_STATUS(
            p_request_id IN OUT NUMBER,
            p_phase OUT VARCHAR2,
            p_status OUT VARCHAR2,
            p_dev_phase OUT VARCHAR2,
            p_dev_status OUT VARCHAR2,
            p_message OUT VARCHAR2)
            RETURN NUMBER;

   FUNCTION CHILDREN_DONE(
            p_parentId IN NUMBER)
            RETURN NUMBER;

   FUNCTION GET_SUB_REQUESTS(
            p_parentId IN NUMBER)
            RETURN VARCHAR2;
END;
