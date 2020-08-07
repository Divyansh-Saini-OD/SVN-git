CREATE OR REPLACE PACKAGE BODY XX_OD_GL_GLOBAL_COA_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Oracle GSD		                             |
-- +=====================================================================+
-- | Name : XX_OD_GL_GLOBAL_COA_PKG                                      |
-- | Defect# 10676		                                                 |
-- | Description : This package houses the report submission procedure   |
-- |              									                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  27-Jul-11      Sai Kumar Reddy      Initial version        |
-- |1.0       27-Nov-13      Veronica Mairembam   Modified for Fix of    |
-- |                                              defect# 26752          |
-- |2.0       23-Nov-15      Rma Goyal           GSCC Retrofits          |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_OD_GL_GLOBAL_COA_PRC                                     |
-- | Description : This procedure will submit the GL Global COA report	 |
-- |               			                                             |
-- | Returns     : x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE XX_OD_GL_GLOBAL_COA_PRC (
								 x_err_buff    OUT VARCHAR2,
								 x_ret_code    OUT NUMBER
								  )
AS

 ln_srequest_id NUMBER(15);

 lb_sreq_status  BOOLEAN;

 lb_layout       BOOLEAN;


 lc_sphase       VARCHAR2(50);
 lc_sstatus      VARCHAR2(50);
 lc_sdevphase    VARCHAR2(50);
 lc_sdevstatus   VARCHAR2(50);
 lc_smessage     VARCHAR2(50);


BEGIN

/*

       lb_layout := FND_REQUEST.ADD_LAYOUT(
                                          'XXFIN'
                                         ,'ODGLGLOBALCOA'
                                         ,'en'
                                         ,'US'
                                         ,'EXCEL'
                                         );

       ln_srequest_id := FND_REQUEST.SUBMIT_REQUEST('XXFIN'
                                                    ,'ODGLGLOBALCOA'
													,NULL
                                                    ,TO_CHAR(SYSDATE,'DD-MON-YY HH24:MM:SS')
                                                    ,FALSE
                                                    );
      COMMIT;


      lb_sreq_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                        request_id => ln_srequest_id
                                                       ,interval   => '2'
                                                       ,max_wait   => NULL
                                                       ,phase      => lc_sphase
                                                       ,status     => lc_sstatus
                                                       ,dev_phase  => lc_sdevphase
                                                       ,dev_status => lc_sdevstatus
                                                       ,message    => lc_smessage
                                                       );


              IF (UPPER(lc_sstatus) = 'ERROR') THEN

                  x_err_buff := 'The Report Completed in ERROR';
                  x_ret_code := 2;

              ELSIF (UPPER(lc_sstatus) = 'WARNING') THEN

                  x_err_buff := 'The Report Completed in WARNING';
                  x_ret_code := 1;

              ELSE

                  x_err_buff := 'The Report Completion is NORMAL';
                  x_ret_code := 0;

              END IF;
*/
  fnd_file.put_line(fnd_file.output,'COA|SEGMENT_NUM|APPLICATION_COLUMN_NAME|SEGMENT_NAME|VALUE_SET_NAME|VALUE_SET_DESCRIPTION|FLEX_VALUE|FLEX_VALUE_DESCRIPTION|CREATION_DATE|CREATED_USER_NAME|DESCRIPTION|LAST_UPDATE_DATE|LAST_UPDATED_USER_NAME|LAST_UPDATED_USER_DESCRIPTION');

FOR i IN (
			SELECT st.id_flex_structure_code 						 rs_coa,
			  stl.segment_num 										 rs_segment_num,
			  stl.application_column_name 							 rs_app_col_name,
			  stl.segment_name 										 rs_segment_name,
			  stl.description 										 rs_segment_desc,
			  flex_value_set_name  									 rs_value_set_name,
			  fvs.description  										 rs_value_set_desc,
			  flex_value 											 rs_flex_value,
			  flex_value_meaning 									 rs_flex_value_meaning,
			  ffv.description 				 						 rs_flex_desc,
			  TO_CHAR(ffv.creation_date,'DD-MON-YYYY HH24:MI:SS') 	 rs_creation_date,
			  fu.user_name 											 rs_created_user_name,
			  fu.description				 						 rs_created_user_desc,
			  TO_CHAR(ffv.last_update_date,'DD-MON-YYYY HH24:MI:SS') rs_last_update_date,
			  fu1.user_name 										 rs_last_updated_user_name,
			  fu1.description				  						 rs_last_updated_user_desc
			FROM 	fnd_id_flex_structures_vl st ,
			  	fnd_id_flex_segments_vl stl ,
			  	fnd_flex_value_sets fvs ,
			  	fnd_flex_values_vl ffv ,
			  	fnd_user fu ,
			  	fnd_user fu1
			WHERE st.id_flex_structure_code = 'OD_GLOBAL_COA'
		            AND st.id_flex_code = 'GL#'                      -- Added for fix of defect# 26752 on 27-Nov-2013
           		 AND st.id_flex_code = stl.ID_FLEX_CODE           -- Added for fix of defect# 26752 on 27-Nov-2013
			AND st.id_flex_num              = stl.id_flex_num
			AND stl.flex_value_set_id       = fvs.flex_value_set_id
			AND fvs.flex_value_set_id       = ffv.flex_value_set_id
			AND ffv.created_by              = fu.user_id
			AND ffv.last_updated_by         = fu1.user_id
		 ) LOOP
		 fnd_file.put_line(fnd_file.output,i.rs_coa||'|'||i.rs_segment_num||'|'||i.rs_app_col_name||'|'||i.rs_segment_name||'|'||i.rs_value_set_name||'|'||i.rs_value_set_desc||'|'||i.rs_flex_value||'|'||i.rs_flex_desc||'|'||i.rs_creation_date||'|'||i.rs_created_user_name||'|'||i.rs_created_user_desc||'|'||i.rs_last_update_date||'|'||i.rs_last_updated_user_name||'|'||i.rs_last_updated_user_desc);
		 END LOOP;

	EXCEPTION
	WHEN OTHERS THEN
	  fnd_file.put_line(fnd_file.log,'Completed in ERROR'||SQLERRM);
	  x_err_buff := 'The Report Completed in ERROR';
	  x_ret_code := 2;
END XX_OD_GL_GLOBAL_COA_PRC;

END XX_OD_GL_GLOBAL_COA_PKG;
/