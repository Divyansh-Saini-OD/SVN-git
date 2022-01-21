create or replace
PACKAGE      XX_AR_EBL_DAILY_PROCESS_RPT
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_DAILY_PROCESS_RPT                                         |
-- | Description : This Package will be executable code for the Daily processing report|                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2010  Ranjith Thnangasamy     Initial draft version               |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : DATA_EXTRACT                                                        |
-- | Description : This Procedure is used to generate the daile processing report      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2010  Ranjith Thnangasamy     Initial draft version               |
-- |2.0       25-JAN-2013  KirubhaSamuel           Changes were made for defect #21679 |
-- |                                                1.Procedure DATA_EXTRACT has been  |
-- |                                                 commented out                     |
-- |                                                2.Procedure DATA_REPORT has been,  |
-- |                                                 has been created                  |
-- |                                                3.P_AS_OF_DATE,P_STATUShas been    |
-- |                                                  declared as global variables     |
-- |                                                                                   |
-- +===================================================================================+

   P_AS_OF_DATE VARCHAR2(30) := NULL;
     P_STATUS VARCHAR2(30) :=NULL;

   /*PROCEDURE DATA_EXTRACT (P_AS_OF_DATE VARCHAR2,
                           P_STATUS VARCHAR2
                           /*p_file_path VARCHAR2,
                           p_file_name VARCHAR2,
                           p_delimiter VARCHAR2,
                  --         p_ftp        VARCHAR2,  commented for defect 7924
                           p_copy_files   VARCHAR2,  --added for defect 7924
                  --         p_processname VARCHAR2,   commented for defect 7924
                           p_dest_path     VARCHAR2,
                           p_dest_file_name VARCHAR2,
                           p_delete_source_file VARCHAR2 --commented for defect #21679
                          ) return boolean;*/

PROCEDURE DATA_REPORT ( x_errbuff OUT VARCHAR2,
                           x_retcode OUT NUMBER,
                           p_as_of_date VARCHAR2,
                           p_status VARCHAR2
                           );
END;
/