CREATE OR REPLACE PACKAGE XX_AR_MT_WC_PKG
AS
-- This procedure is used to submit the AR Transaction program using multi threading
   PROCEDURE txn_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   );

   PROCEDURE cr_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   );

   PROCEDURE adj_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   );

   PROCEDURE ps_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   );

   PROCEDURE recappl_mt (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
   );

-- Table type declaration
   TYPE REQ_ID IS TABLE OF NUMBER
      INDEX BY PLS_INTEGER;

--Global Initialization
   gn_user_id   NUMBER := fnd_profile.VALUE ('USER_ID');
   gn_appl_id   NUMBER := fnd_profile.VALUE ('RESP_APPL_ID');
   gn_resp_id   NUMBER := FND_PROFILE.VALUE ('RESP_ID');
END;
/

SHOW errors;