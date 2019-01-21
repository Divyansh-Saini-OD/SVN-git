create or replace
PACKAGE BODY XX_CDH_GP_DATA_AOPS AS
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |              Office Depot Organization                                                           |
  -- +==================================================================================================+
  -- | Name  : XX_CDH_GP_DATA_AOPS                                                                      |
  -- | Description:  Package to Grand Parent information to AOPS	                                |
  -- | Change Record:                                                                                   |
  -- |===============                                                                                   |
  -- |Version   Date           Author           Remarks                                                 |
  -- |=======   ==========    =============    ========================================                 |
  -- |1.0A      22-JUL-2014   Avinash Baddam   For defect 26998 Send Written Agreement flag to AOPS     |
  -- |                                         along with existing Grand Parent information             |
  -- |1.1       18-May-2016   Shubashree R     Removed the schema reference for GSCC compliance QC#37898|
  -- +===================================================================================================+

PROCEDURE Populate_gp_data ( x_errbuf             OUT NOCOPY VARCHAR2
                            ,x_retcode             OUT NOCOPY VARCHAR2

                       ) IS

cursor  c_gp_dump IS
select  substr(hcu.orig_system_reference,1,8) 	OSR,
        substr(gp_master.gp_id,1,8)				                  GP_ID, 
        substr(gp_master.gp_name,1,30) 			                GP_NAME, 
        substr(nvl(gp_master.legacy_rep_id,' '),1,7)			  REP_ID,
        substr(gp_master.w_agreement_flag,1,1)  L_FLAG
from    XX_CDH_GP_REL gp_rel,
        xx_cdh_gp_master    gp_master,
        hz_relationships hpr,
        hz_cust_accounts        hcu
where   gp_rel.relationship_id = hpr.relationship_id
and     hpr.object_id = hcu.party_id
and     hpr.subject_id  = gp_master.party_id
and     hpr.status = 'A'
and     sysdate between hpr.start_date and hpr.end_date;

TYPE		            t_gp_dump is TABLE OF c_gp_dump%ROWTYPE;
l_gp_dump_tab	      t_gp_dump;
v_file              UTL_FILE.FILE_TYPE;
lc_table            VARCHAR2(60) := FND_PROFILE.VALUE('XX_GP_AOPS_TABLE');
lc_host             VARCHAR2(2000):= FND_PROFILE.VALUE('XX_GP_AOPS_HOST');
lc_lib              VARCHAR2(2000):= FND_PROFILE.VALUE('XX_GP_AOPS_LIB');
l_db_string         VARCHAR2(2000);
l_insert_str        VARCHAR2(2000);

BEGIN

	x_retcode := 'S';
  --FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Name is' || lc_file_name);

	-- Open the utl file
--	v_file := UTL_FILE.FOPEN(      location     => lc_file_loc,
--                                 filename     => lc_file_name,
--                                 open_mode    => 'w');
  l_db_string := lc_lib||'.'||lc_table||'@'||lc_host;
-- l_db_string :=  'DEVDTA.CSTGPINFO@OD400C';
  execute immediate ('delete from '||l_db_string);
  l_insert_str := 'INSERT INTO ' || l_db_string ||
                ' (
                  CSTGPINFO_CUSTOMER_ID
                  ,CSTGPINFO_GRAND_PARENT_ID
                  ,CSTGPINFO_GRAND_PARENT_NAME
                  ,CSTGPINFO_GRAND_PARENT_REP_ID
                  ,CSTGPINFO_GRAND_PARENT_NUM102
                  ,CSTGPINFO_GRAND_PARENT_CODE1
                )
                VALUES
                ( :1 , :2 , :3 , :4, :5, :6 )';
	open c_gp_dump ;

	loop
	FETCH c_gp_dump  BULK COLLECT INTO l_gp_dump_tab limit g_limit;

    FOR ind IN l_gp_dump_tab.FIRST..l_gp_dump_tab.LAST loop


              FND_FILE.PUT_LINE(FND_FILE.LOG,  l_gp_dump_tab(ind).OSR
                                  || l_gp_dump_tab(ind).GP_ID
                                  ||l_gp_dump_tab(ind).GP_NAME 
                                  ||l_gp_dump_tab(ind).REP_ID
                                  ||l_gp_dump_tab(ind).L_FLAG
                                 );
            BEGIN
               EXECUTE IMMEDIATE  l_insert_str  
                        USING     l_gp_dump_tab(ind).OSR
                                  ,l_gp_dump_tab(ind).GP_ID
                                  ,l_gp_dump_tab(ind).GP_NAME 
                                  ,l_gp_dump_tab(ind).REP_ID 
                                  ,'0'
                                  ,l_gp_dump_tab(ind).L_FLAG;
            EXCEPTION WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Populate_gp_data: Error executing insert: Error' || sqlerrm);
            END;
               COMMIT;
    end loop;
  
    EXIT WHEN l_gp_dump_tab.count < g_limit;

	end loop;


	close c_gp_dump ; 


EXCEPTION WHEN OTHERS THEN

	x_retcode := 'E';
	x_errbuf  := SQLERRM;
	FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in Populate_gp_data;' || x_errbuf);

END Populate_gp_data;

END XX_CDH_GP_DATA_AOPS;
/