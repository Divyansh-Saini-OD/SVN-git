create or replace
package XX_COMN_WFERR_ABORT_PKG
AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name    : XX_WFERR_ABORT_PKG                                                            |
-- |                                                                                         |
-- | Description      : Common program to abort WFERROR workflows.                           |
-- |                    To be used once you have investigated RCA and still want to abort    |
-- |                    Date ranges are provided so that you can control how many workflows  |
-- |                    become eligible for Purge .                                          |
-- |                    2 profile options will play a role here                              |
-- |                    a)  XX_WFERR_ABORT_LIMIT limits the max number of wf's you can abort |
-- |                       so that too many workflows do not become eligible for purge, and  |
--                         to control undo growth                                            |
-- |                                                                                         |
-- |                    a)  XX_WFERR_ABORT_AGE [in days]. Only wfs older than this will be   |
--                           eligible for abort, so that time is allowed for investigation   |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0       03-Mar-13         AMS                  Initiated from Defect 21878             |
-- |                                                 but to be used for purging other WFERROR| 
--=========================================================================================
 PROCEDURE main ( 
                 x_errbuf          OUT VARCHAR2,
                 x_retcode         OUT NUMBER,    
                 p_parent_itemtype IN  VARCHAR2,
                 p_start_date      IN  VARCHAR2,
                 p_end_date        IN  VARCHAR2,
                 p_wf_itemkey      IN  VARCHAR2,
                 p_force_purge     IN  VARCHAR2,
                 p_commit          IN  VARCHAR2
                  ) ;


end XX_COMN_WFERR_ABORT_PKG ;
/