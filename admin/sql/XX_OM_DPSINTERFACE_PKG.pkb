SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET SHOW OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_DPSINTERFACE_PKG

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_OM_DPSINTERFAE_PKG                                 |
-- | RICE ID:   I1148                                                  |
-- |                                                                   |
-- | Description      : This package contains procedures peforming     |
-- |                    following activities                           |
-- |                    1) To Raise Business Event                     |
-- |                    2) To Update Acknowledgement information in    |
-- |                       Order Lines Table.                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- | 1.0     05-MAR-2007  Aravind A        Initial draft version       |
-- | 1.1     27-JUL-2007  Aravind A        Modified code to reflect    |
-- |                                       new attribute structure     |
-- +===================================================================+
AS

   PROCEDURE RAISE_BUSINESS_EVENT  (
                                    p_parent_line_id   IN       xx_om_line_attributes_all.ext_top_model_line_id%TYPE
                                   ,x_return_status    OUT      VARCHAR2
                                   ,x_message          OUT      VARCHAR2
                                   )
   IS
-- +===================================================================+
-- | Name  : RAISE_BUSINESS_EVENT                                      |
-- | Description   : This Procedure will be used to raise a business   |
-- |                 event for an input Parent_line_id.This will       |
-- |                 validate the input parent line id before raising  |
-- |                 the business event.                               |
-- |                                                                   |
-- | Parameters :       p_parent_line_id                               |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_return_status,x_message                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

-- In this custom Raise Business Event program
-- 1.Business event is raised with the given parent line ID as the event key
-- Steps involved:-
-- a.Check whether the bundle contais DPS lines
-- b.Check whether Hold for production hold is applied on the bundle
-- c.Check whether the Configuration ID column is not null
-- d.On success of above validations,raise the business event or else update the global exceptions table

      EX_NOT_PARENT       EXCEPTION;
      lc_err_code         xxom.xx_om_global_exceptions.error_code%TYPE  DEFAULT ' ';    
      lc_err_desc         xxom.xx_om_global_exceptions.description%TYPE DEFAULT ' ';      
      lc_entity_ref       xxom.xx_om_global_exceptions.entity_ref%TYPE;     
      lc_error_flag       VARCHAR2 (10)                                := 'N';
      ln_dps_count        NUMBER                                    DEFAULT 0;
      ln_conf_id_count    NUMBER                                    DEFAULT 0;
      ln_line_id          oe_order_lines_all.attribute7%TYPE;
      err_report_type     XX_OM_REPORT_EXCEPTION_T;
      x_err_buf           VARCHAR2 (240);
      x_ret_code          VARCHAR2 (10);
      ln_hold_cnt         NUMBER :=0 ;

   BEGIN
      lc_error_flag := 'N';
 
      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_1001_DPS_BE_FAILED');
      x_return_status := 'E';
      x_message := FND_MESSAGE.GET;
 
      --To check whether the Line ID equals the Parent Line ID
      --Ensuring that the event is raised only once for each bundle

      BEGIN
         SELECT OOLA.line_id
           INTO ln_line_id
           FROM oe_order_lines_all OOLA                 
               ,xx_om_line_attributes_all XOLAA
          WHERE OOLA.line_id = XOLAA.line_id             
            AND XOLAA.ext_top_model_line_id = p_parent_line_id
            AND XOLAA.ext_link_to_line_id IS NULL;
 
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --Ensure the business event is not raised for non parent line_id            
	    RAISE EX_NOT_PARENT;       
         WHEN TOO_MANY_ROWS
         THEN
            --If there more than one line acting as a parent in a bundle
	    --then it is again said to be an invalid parent line id.
	    RAISE EX_NOT_PARENT;
      END;
 
      --To Check whether the bundle contains atleast one DPS type line,
      --Business event is raised only if atleast one line is of DPS Line Type.
      
      SELECT COUNT (OOLA.line_id)
        INTO ln_dps_count
        FROM oe_order_lines_all OOLA            
             ,xx_om_line_attributes_all XOLAA
             ,fnd_lookup_values FLV
       WHERE OOLA.line_id = XOLAA.line_id          
         AND XOLAA.ext_top_model_line_id = p_parent_line_id
         AND XOLAA.line_type = FLV.meaning
         AND FLV.lookup_type = gc_flv_type
         AND FLV.lookup_code  = gc_flv_code
         AND FLV.language     = USERENV('LANG')  ;

 
      --If the DPS Count is ZERO then appropriate message
      --is recorded in the global exceptions table

      IF (ln_dps_count = 0)
      THEN
         lc_error_flag := 'Y';
         lc_err_code := 'XX_OM_1002_DPS_NO_DPS_TYPE';
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_1002_DPS_NO_DPS_TYPE');
         lc_err_desc := FND_MESSAGE.GET;
         x_return_status := 'E';
         x_message := FND_MESSAGE.GET;
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
            XXOM.XX_OM_REPORT_EXCEPTION_T (
	                                    gc_exception_header            
                                           ,gc_track_code                    
                                           ,gc_solution_domain               
                                           ,gc_function                      
                                           ,lc_err_code
                                           ,lc_err_desc
                                           ,lc_entity_ref
                                           ,NVL(p_parent_line_id,0)
                                           );
             XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
	                                                   err_report_type
                                                          ,x_err_buf
                                                          ,x_ret_code
                                                          );
      ELSE
         --To Check whether the Parent Line of a bundle contains hold of type "DPS Hold".
         --Obtain the Hold name using the Hold ID

            SELECT COUNT(*)
              INTO ln_hold_cnt
              FROM oe_hold_definitions OHD
                  ,oe_order_holds_all OOHO
                  ,oe_hold_sources_all OHSA
                  ,oe_order_lines_all OOLA                   
                  ,xx_om_line_attributes_all XOLAA
             WHERE OOLA.line_id = XOLAA.line_id
               AND OOLA.line_id = OOHO.line_id                
               AND OOHO.hold_source_id = OHSA.hold_source_id
               AND OHSA.hold_id = OHD.hold_id
               AND XOLAA.ext_top_model_line_id = p_parent_line_id
               AND OOHO.released_flag != 'Y'
	       AND OHD.NAME = gc_hold_name 
	       AND XOLAA.ext_link_to_line_id IS NULL;
 
            --If the Hold is not "DPS Hold" then appropriate message
            --is recorded in the global exceptions table

            IF (ln_hold_cnt = 0 )
            THEN
               lc_error_flag := 'Y';
               lc_err_code := 'XX_OM_1003_DPS_NO_HOLD_FOR_PROD';
               FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_1003_DPS_NO_HOLD_FOR_PROD');
               lc_err_desc := FND_MESSAGE.GET;
               x_message := FND_MESSAGE.GET;
               x_return_status := 'E';
               lc_entity_ref := 'Parent_line_id';
               err_report_type :=
                   XXOM.XX_OM_REPORT_EXCEPTION_T (
		                                   gc_exception_header               
                                                  ,gc_track_code                   
					          ,gc_solution_domain               
                                                  ,gc_function                      
                                                  ,lc_err_code
                                                  ,lc_err_desc
                                                  ,lc_entity_ref
                                                  ,NVL(p_parent_line_id,0)
                                                 );
               XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
	                                                    err_report_type
                                                           ,x_err_buf
                                                           ,x_ret_code
                                                           );
            ELSE
               --To Check atleast one DPS line has Configuration ID value
               --Obtain the count of DPS lines having Configuration ID value in the given bundle.
               SELECT COUNT (OOLA.line_id)
                 INTO ln_conf_id_count
                 FROM oe_order_lines_all OOLA                      
                     ,xx_om_line_attributes_all XOLAA                     
                WHERE OOLA.line_id = XOLAA.line_id                                      
                  AND XOLAA.vendor_config_id IS NOT NULL
                  AND XOLAA.ext_top_model_line_id = p_parent_line_id;
 
               --If the Count is ZERO then appropriate message
               --is recorded in the global exceptions table
               IF (ln_conf_id_count = 0)
               THEN
                  lc_error_flag := 'Y';
                  lc_err_code := 'XX_OM_1004_DPS_NO_CONFIG_ID';
                  FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_1004_DPS_NO_CONFIG_ID');
                  lc_err_desc := FND_MESSAGE.GET;
                  x_message := FND_MESSAGE.GET;
                  x_return_status := 'E';
                  lc_entity_ref := 'Parent_line_id';
                  err_report_type :=
                     XXOM.XX_OM_REPORT_EXCEPTION_T (
						   gc_exception_header               
						  ,gc_track_code                    
						  ,gc_solution_domain               
						  ,gc_function                     
						  ,lc_err_code
						  ,lc_err_desc
						  ,lc_entity_ref
						  ,NVL(p_parent_line_id,0)
						  );
                  XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
		                                               err_report_type
                                                              ,x_err_buf
                                                              ,x_ret_code
                                                              );
               END IF;
            END IF;       
      END IF;

 
      IF lc_error_flag = 'N'
      THEN
         --Raising Business Event
         --Passing Parent line id as the event_key parameter.
         WF_EVENT.RAISE (
	                 p_event_name      => gc_event_name
                        ,p_event_key       => p_parent_line_id
			);
         x_return_status := 'S';
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_1005_DPS_BE_SUCCESS');
         x_message := FND_MESSAGE.GET;
	 COMMIT;
      END IF;
 
     
   EXCEPTION
      WHEN EX_NOT_PARENT
      THEN
         lc_err_code := 'XX_OM_1006_DPS_NOT_PARENT';
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_1006_DPS_NOT_PARENT');
         lc_err_desc := FND_MESSAGE.GET;
         x_return_status := 'E';
         x_message := FND_MESSAGE.GET;
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
                 XXOM.XX_OM_REPORT_EXCEPTION_T (gc_exception_header               
                                               ,gc_track_code                   
                                               ,gc_solution_domain               
                                               ,gc_function                      
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );     
      WHEN OTHERS
      THEN
         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_1001_DPS_BE_FAILED');
         lc_err_desc := SUBSTR(FND_MESSAGE.GET||' The error message is '||SQLERRM,1,1000);
         x_message := FND_MESSAGE.GET;
         x_return_status := 'E';
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
                     XXOM.XX_OM_REPORT_EXCEPTION_T (
						   gc_exception_header               
						  ,gc_track_code                   
						  ,gc_solution_domain               
						  ,gc_function                      
						  ,SQLCODE
						  ,lc_err_desc
						  ,lc_entity_ref
						  ,NVL(p_parent_line_id,0)
						  );         --entity_ref_id subject to change
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
	                                               err_report_type
                                                      ,x_err_buf
                                                      ,x_ret_code
                                                     );
   END RAISE_BUSINESS_EVENT;
 
-- +===================================================================+
-- | Name  : UPDATE_ACKNOWLEDGEMENT                                    |
-- | Description   : This Procedure is used to update DPS Status in the|
-- |                 order lines table for a given Parent_line_id      |
-- |                                                                   |
-- | Parameters :       p_parent_line_id,p_user_name,p_resp_name       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_return_status,x_message                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
 
   -- In this custom Update Acknowledgement program
   -- 1.Acknowledgement from the BPEL Process is updated in the oe_order_lines_all table
   -- Steps involved:-
   -- a.Fetch the DPS lines having configuration id value for the given bundle(Parent Line Id)
   -- b.Set the required dps status in a variable
   -- c.Call the OE_ORDER_PUB.Process_Order API to update the DPS Status in oe_order_lines_all table
   -- d.If any exceptions occur those are recorded in the Global exceptions table


   PROCEDURE UPDATE_ACKNOWLEDGEMENT (
                                      p_parent_line_id   IN       xx_om_line_attributes_all.ext_top_model_line_id%TYPE
                                     ,p_user_name        IN       fnd_user.user_name%TYPE
                                     ,p_resp_name        IN       fnd_responsibility_tl.responsibility_name%TYPE
                                     ,x_return_status    OUT      VARCHAR2
                                     ,x_message          OUT      VARCHAR2
                                    )
   IS
      EX_INVALID_COMBINATION         EXCEPTION;
      lc_err_code                    xx_om_global_exceptions.error_code%TYPE  DEFAULT ' ';
      lc_err_desc                    xx_om_global_exceptions.description%TYPE DEFAULT 'OTHERS';
      lc_entity_ref                  xx_om_global_exceptions.entity_ref%TYPE  DEFAULT 'OTHERS';
      lc_segment                     VARCHAR2 (4000);
      x_init_status                  VARCHAR2(40);
      x_init_message                 VARCHAR2(100);
      ln_invalid_comb_line           oe_order_lines_all.line_id%TYPE;
      err_report_type                xx_om_report_exception_t;
      x_err_buf                      VARCHAR2 (240);
      x_ret_code                     VARCHAR2 (10);
      ln_count                       PLS_INTEGER                         DEFAULT 0;
      lc_status                      VARCHAR2 (1);
      ln_combination_id              NUMBER;
      ln_structure_id                NUMBER;
      ln_msg_count                   NUMBER;
      lc_msg_data                    VARCHAR2 (4000)              DEFAULT ' ';
      
 
      --Cursor Declaration
      CURSOR lcu_lines
      IS
         SELECT OOLA.line_id
               ,OOLA.header_id
               ,OOLA.attribute6
         FROM   oe_order_lines_all OOLA              
               ,xx_om_line_attributes_all XOLAA              
               ,fnd_lookup_values FLV
         WHERE  
                OOLA.line_id = XOLAA.line_id             
            AND XOLAA.ext_top_model_line_id = p_parent_line_id
            AND XOLAA.line_type = FLV.meaning
            AND FLV.lookup_code = gc_flv_code
            AND FLV.lookup_type = gc_flv_type
            AND FLV.language = userenv('LANG'); 
   BEGIN
 
      XX_OM_DPS_APPS_INIT_PKG.DPS_APPS_INIT( 
                                             p_user_name
					    ,p_resp_name
					    ,x_init_status
					    ,x_init_message
					    );

      IF (x_init_status = 'S') THEN
    
         --Loop each of the bundle lines to set the acknowledgement details
         --using the line tbl type variable
         FOR lines_rec_type IN lcu_lines
         LOOP
         
         XX_OM_DPSCANCEL_PKG.UPDATE_STATUS (p_order_line_id => lines_rec_type.line_id
	                                   ,p_update_status => gc_dps_status
	                                   ,x_return_status => x_return_status   
	                                    );
	 
	                                                           
            IF x_return_status = 'S' THEN
               COMMIT;
            END IF;
         
         END LOOP;
      ELSE
       x_return_status := 'E';
       x_message       := x_init_message ;
      END IF;
   EXCEPTION
   WHEN OTHERS
	THEN
	           x_return_status := 'E';
	           lc_err_desc := SUBSTR(lc_err_desc||' The error is '||SQLERRM,1,1000);
	 	   x_message   := lc_err_desc ; 
	           err_report_type :=
	                  XXOM.XX_OM_REPORT_EXCEPTION_T (
	 		                                gc_exception_header               
	                                                ,gc_track_code                    
	                                                ,gc_solution_domain              
	                                                ,gc_function                     
	                                                ,SQLCODE
	                                                ,lc_err_desc
	                                                ,lc_entity_ref
	                                                ,NVL(p_parent_line_id,0)
	                                                );
	          XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
	 	                                             err_report_type
	                                                     ,x_err_buf
	                                                     ,x_ret_code
                                                    );
              
   END UPDATE_ACKNOWLEDGEMENT;

END XX_OM_DPSINTERFACE_PKG;
/
SHOW ERROR
