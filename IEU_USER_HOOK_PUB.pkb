CREATE OR REPLACE PACKAGE BODY APPS.IEU_USER_HOOK_PUB AS
/* $Header: IEUUSHKB.pls 120.0.12010000.2 2011/12/05 06:18:32 rgandhi noship $ */



-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name    : XX_CS_CUSTOM_EVENT_PKG                                                        |
-- |                                                                                         |
-- | Description      : Customer Support Custom Event functions                              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0       14-NOV-201         Raj                 Initial draft version                   |
-- |2.0       19-Jun-13         Arun Gannarapu       added the 11i logic to R12 version      |
-- |                                                 of user hook                            |
-- +=========================================================================================+

PROCEDURE ADDITIONAL_FILTER_WORKITEM( p_resource_id       IN   NUMBER,
                                      x_filter_condition  OUT  NOCOPY VARCHAR)
IS


ld_hst_date date:=HZ_TIMEZONE_PUB.Convert_DateTime(1,10,sysdate);  --to convert Hawaii's time to EST  added for QC#23145
ld_akst_date date:= HZ_TIMEZONE_PUB.Convert_DateTime(1,7,sysdate); --to convert Alaska's time to EST  added for QC#23145
    
ld_pst_date date := HZ_TIMEZONE_PUB.Convert_DateTime(1,4,sysdate);
ld_mst_date date := HZ_TIMEZONE_PUB.Convert_DateTime(1,3,sysdate);
ld_cst_date date := HZ_TIMEZONE_PUB.Convert_DateTime(1,2,sysdate);

ln_hst_time number:=(TO_CHAR(ld_hst_date ,'HH24.MI'))*3600;       --added for QC#23145
ln_akst_time number:= (TO_CHAR(ld_akst_date ,'HH24.MI'))*3600;    --added for QC#23145

ln_cst_time number := (TO_CHAR(ld_cst_date ,'HH24.MI'))*3600;
ln_mst_time number := (TO_CHAR(ld_mst_date ,'HH24.MI'))*3600;
ln_pst_time number := (TO_CHAR(ld_pst_date ,'HH24.MI'))*3600;
ln_est_time number := (TO_CHAR(sysdate,'HH24.MI')*3600);

    BEGIN

      /* x_filter_condition should be overwritten by customer filter condition
       *  that needs to be appended to the existing  distirbution query*/

    --  x_filter_condition := NULL;
    
    /*******************************************************************************************************
  -- Rajeswari Jagarlamudi (11/14/10) added custom code here for prevent requests per customer time zone
  -- Arun Gannarapu (07/19/2013) --added the 11i logic to R12 version of user hook
********************************************************************************************************/
      x_filter_condition :=
      ' EXISTS (
      SELECT ''x''
      from cs_incidents_all_b
      where incident_id = items.workitem_pk_id
      and incident_type_id in (11004,21018)
      and incident_status_id <> 2
      and status_flag <> ''C''
      and items.workitem_obj_code = ''SR''
      and decode(time_zone_id,10,'||ln_hst_time||',7,'||ln_akst_time||',4,'||ln_pst_time||',3,'||ln_mst_time||',2,'||ln_cst_time||',1,'||ln_est_time||') between 28800 and 61200 )';
      --added Alaska and Hawaii time zones QC#23145



    EXCEPTION -- Exception block

     WHEN OTHERS THEN
      /* No Exception should be raised from this block*/
      x_filter_condition := NULL;

     END ADDITIONAL_FILTER_WORKITEM;

END IEU_USER_HOOK_PUB;
/

show errors;
exit;