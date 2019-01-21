-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
package XXSCS_LOAD_STG_DATA AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XXSCS_LOAD_STG_DATA                                                       |
-- | Description : Custom package for data migration.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        08-Apr-2009     Kalyan               Initial version                          |
-- +=========================================================================================+
G_LEVEL_ID                      CONSTANT  NUMBER       := 10001;
G_LEVEL_VALUE                   CONSTANT  NUMBER       := 0;
--This procedure is invoked to print in the log file
PROCEDURE display_log( p_message IN VARCHAR2
                         );
--This procedure is invoked to print in the output
PROCEDURE display_out( p_message IN VARCHAR2
                         );
--This procedure extracts Completed Tasks
procedure GENERATE_TASKS_REPORT( x_errbuf              OUT NOCOPY VARCHAR2
                        ,x_retcode             OUT NOCOPY VARCHAR2
                                          , p_start_date         IN            VARCHAR2
					  , p_end_date           IN            VARCHAR2
                                          , p_update_prof       IN            VARCHAR2

                       ) ;
-- Load into feedback Header Staging Table
procedure load_feedback_hdr(  x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                           ) ;
-- Load into feedback Line Detail Staging Table
procedure load_feedback_line( x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                            ) ;
-- -- Load into feedback Question Staging Table
procedure load_feedback_qstn( x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                            ) ; 
-- -- Load into feedback Response Staging Table
procedure load_feedback_resp( x_errbuf	  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY VARCHAR2
                            ) ; 
-- Load Stage Data  Main                  
procedure load_stage_data ( x_errbuf	  OUT NOCOPY VARCHAR2
                            ,x_retcode  OUT NOCOPY VARCHAR2
                          ) ;
-- Load Feedback Header and Lines
procedure load_fdbk_hdr_line ( x_errbuf	  OUT NOCOPY VARCHAR2
                            ,x_retcode  OUT NOCOPY VARCHAR2
                          );
function count_diff(
                    p_attr_group_id IN HZ_PARTY_SITES_EXT_B.attr_group_id%type,
                    p_party_site IN HZ_PARTY_SITES_EXT_B.party_site_id%TYPE,
                    p_wcw_count  IN HZ_PARTY_SITES_EXT_B.N_EXT_ATTR8%type)
return varchar2;

function count_diff_sic(
                    p_attr_group_id IN HZ_PARTY_SITES_EXT_B.attr_group_id%type,
                    p_party_site    IN HZ_PARTY_SITES_EXT_B.party_site_id%TYPE,
                    p_sic           IN HZ_PARTY_SITES_EXT_B.C_EXT_ATTR10%type)
return varchar2;



END XXSCS_LOAD_STG_DATA;


/
SHOW ERRORS;
