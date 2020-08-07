SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_DPS_CONF_REL_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                        WIPRO Technologies                         |
-- +===================================================================+
-- | Name  :    XX_DPS_CONF_REL_PKG                                    |
-- | RICE ID :  I1153                                                  |
-- | Description      : This package is used to call the               |
-- |                    procedures                                     |
-- |                    1)  DPS_CONF_LINE_UPD                          |
-- |                        to do all necessary validations and        |
-- |                        get the information needed for updating the|
-- |                        sales order line attribute                 |
-- |                    2)  DPS_HOLD_REL                               |
-- |                        to do all necessary validations and        |
-- |                        release the sales line level hold          |
-- |                        if it is DPS Hold                          |
-- |                        and updating the line attribute            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       23-March-07 Srividhya,WIPRO  Initial Version             |
-- |1.1       27-JUL-07   Prajeesh         Modified based on KFF in DFF|
-- +===================================================================+
AS

-- +===================================================================+
-- | Name  : DPS_CONF_LINE_UPD                                         |
-- | Description   : This Procedure will be used to update the         |
-- |                 sales order lines's attribute with                |
-- |                 'XX_OM_HLD_PRODUCTION'                            |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                    p_order_number                                 |
-- |                    p_line_id                                      |
-- |                    p_user_name                                    |
-- |                    p_resp_name                                    |
-- |                                                                   |
-- | Returns :         x_status                                        |
-- |                   x_message                                       |
-- |                                                                   |
-- +===================================================================+

  
   PROCEDURE DPS_CONF_LINE_UPD(
                               p_order_number    IN       oe_order_headers_all.order_number%TYPE
                               ,p_line_id        IN       oe_order_lines_all.line_id%TYPE
                               ,p_user_name      IN       fnd_user.user_name%TYPE
                               ,p_resp_name      IN       fnd_responsibility_tl.responsibility_name%TYPE
                               ,x_status         OUT      VARCHAR2
                               ,x_message        OUT      VARCHAR2
                               )
   IS
      -- variable declaration

      EX_FAILED                   EXCEPTION;
      lc_err_desc                 xxom.xx_om_global_exceptions.description%TYPE DEFAULT 'OTHERS';
      lc_entity_ref               xxom.xx_om_global_exceptions.entity_ref%TYPE;
      lc_entity_ref_id            xxom.xx_om_global_exceptions.entity_ref_id%TYPE;
      lc_err_code                 xxom.xx_om_global_exceptions.error_code%TYPE;
      lc_function                 VARCHAR2(100) :=  'I1153_DPSJobConfirmationInbound';
      ln_parent_cnt               NUMBER := 0 ;
      ln_hold_cnt                 NUMBER := 0 ;
      ln_order_cnt                NUMBER := 0 ;
      lr_rep_exp_type             xxom.XX_OM_REPORT_EXCEPTION_T;
      lc_app_init_status          VARCHAR2(240);
      lc_msg                      VARCHAR2(1000);
      lc_return_status            VARCHAR2 (1000);
      lc_err_buf                  VARCHAR2 (1000);
      lc_ret_code                 VARCHAR2 (40);
      x_return_status             VARCHAR2(1);

    CURSOR lcu_parent_lines_detail( p_parent_line_id xx_om_lines_attributes_all.segment14%TYPE )
       IS
       SELECT OOLA.line_id
              ,XXOL.trans_line_status
       FROM  oe_order_lines_all OOLA      
             ,xx_om_line_attributes_all XXOL
       WHERE OOLA.line_id                = XXOL.line_id                
       AND XXOL.ext_top_model_line_id    = p_parent_line_id ;

   BEGIN

      -- Initialize the Success Status

      x_status  := FND_API.G_RET_STS_SUCCESS;
      x_message :='Success';
      
         -- Apps Initialisation
      XX_OM_DPS_APPS_INIT_PKG.DPS_APPS_INIT (
                                              p_user_name       
                                              ,p_resp_name      
                                              ,lc_app_init_status
                                              ,lc_msg
                                            );

      IF (lc_app_init_status = FND_API.G_RET_STS_SUCCESS) THEN

         -- VALIDATION LIST
         -- 1) Order Number Validation; Order Number should not be null and must exist in EBS.
         -- 2) Parent Validation; Input Parent Line ID should a valid Parent Line.
         -- 3) Hold for production Validation

         --Order number Validation
        IF (p_order_number IS NULL) THEN
           FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_NULL_INPUTORDER');
           lc_err_desc      := FND_MESSAGE.GET;
           lc_err_code      := 'XX_OM_DPS_NULL_INPUTORDER';
           lc_entity_ref    := 'Order_number';
           lc_entity_ref_id := 00000;
           RAISE EX_FAILED;

        END IF;

           -- Check if the ORder is Valid order based on the TOP Model Line ID

           SELECT count(*)
           INTO ln_order_cnt
           FROM oe_order_headers_all OEH
           WHERE OEH.order_number = p_order_number
           AND exists( SELECT 1 FROM oe_order_lines_all oel,
                                     xx_om_line_attributes_all xol
                       WHERE oel.line_id               =xol.line_id
                       AND   xol.ext_top_model_line_id =p_line_id 
                       AND   oel.header_id             =oeh.header_id);
           
           
        IF ln_order_cnt <> 1 THEN
          
           FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_INVALIDORDERNUM');
           lc_err_desc      := FND_MESSAGE.GET;
           lc_err_code      := 'XX_OM_DPS_INVALIDORDERNUM';
           lc_entity_ref    := 'Order_Number';
           lc_entity_ref_id := NVL(p_order_number,0);
           RAISE EX_FAILED;
        END IF;            
        

         --PARENT Validation
       
        SELECT  COUNT(*)
        INTO  ln_parent_cnt
        FROM  oe_order_lines_all OOLA      
              ,xx_om_line_attributes_all XXOL
        WHERE  XXOL.line_id = OOLA.line_id                
        AND   XXOL.ext_top_model_line_id = p_line_id;

        IF ( ln_parent_cnt <= 0 ) THEN

           FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_INVALID_PARENT');
           lc_err_code      := 'XX_OM_DPS_INVALID_PARENT';
           lc_err_desc      := FND_MESSAGE.GET;
           lc_entity_ref    := 'Parent Line ID';
           lc_entity_ref_id := TO_CHAR( p_line_id );
           RAISE EX_FAILED;

        END IF;

       -- Hold For production Validation               
	

	SELECT count(*)
	INTO ln_hold_cnt
	FROM oe_hold_definitions OHD
	    ,oe_hold_sources_all OHSA
	    ,oe_order_holds_all  OOHO
	    ,oe_order_lines_all  OOLA
	    ,xx_om_line_attributes_all XXOL 
	WHERE OHD.NAME                      = gc_hold_name                      
	AND OHD.hold_id                     = OHSA.hold_id
	AND OHSA.hold_source_id             = OOHO.hold_source_id
	AND OOHO.released_flag              = 'N'
	AND OOHO.line_id                    = OOLA.line_id 
	AND OOLA.line_id                    = XXOL.line_id                
	AND XXOL.ext_top_model_line_id      = p_line_id  ;      
	 
        IF ( ln_hold_cnt =0 ) THEN 

         FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_HOLD');
         lc_err_desc      := FND_MESSAGE.GET;
	 lc_err_code      := 'XX_OM_DPS_HOLD';
	 lc_entity_ref    := 'Order Number';
	 lc_entity_ref_id := NVL(p_order_number,0);
         RAISE EX_FAILED;
        END IF;
                        

        FOR  parent_lines_detail_rec_type IN lcu_parent_lines_detail(p_line_id)
        LOOP   
           IF (parent_lines_detail_rec_type.trans_line_status = gc_dps_hold_new) THEN

              --Assign the DPS Status to the custom attribute table


              xx_om_dpscancel_pkg.update_status( parent_lines_detail_rec_type.line_id
                                                ,gc_dpsConfStatus
                                                ,x_return_status
                                               );

              IF x_return_status <>FND_API.G_RET_STS_SUCCESS THEN

                FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_PROCESS_ORDER_FAIL');
                lc_err_desc      := FND_MESSAGE.GET;
                lc_err_code      := 'XX_OM_DPS_PROCESS_ORDER_FAIL';
                lc_entity_ref    := 'Order Number';
                lc_entity_ref_id := NVL(p_order_number,0);
                RAISE EX_FAILED;
              END IF;
          ELSE
              FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_INVALID_STATUS');
              lc_err_desc      := FND_MESSAGE.GET;
              lc_err_code      := 'XX_OM_DPS_INVALID_STATUS';
              lc_entity_ref    := 'Order Number';
              lc_entity_ref_id := NVL(p_order_number,0);
              RAISE EX_FAILED;
          END IF;
        END LOOP;

        COMMIT;
      ELSE
         FND_MESSAGE.SET_NAME('XXOM', 'XX_OM_DPS_APPSINT_FAILED');
         x_message := FND_MESSAGE.GET;
         lc_err_code       := 'XX_OM_DPS_APPSINT_FAILED';
         lc_err_desc       := FND_MESSAGE.GET;
         lc_entity_ref     := 'Order_number';
         lc_entity_ref_id  := NVL(p_order_number,0);
         RAISE EX_FAILED;
      END IF;
   EXCEPTION
      WHEN EX_FAILED THEN
         ROLLBACK;
         lr_rep_exp_type :=
            xxom.XX_OM_REPORT_EXCEPTION_T (
                                       gc_exception_header              
                                      ,gc_track_code                    
                                      ,gc_solution_domain               
                                      ,lc_function                      
                                      ,lc_err_code
                                      ,lc_err_desc
                                      ,lc_entity_ref
                                      ,NVL(lc_entity_ref_id,0)
                                     );
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (lr_rep_exp_type
                                                      ,lc_err_buf
                                                      ,lc_ret_code
                                                    );
         x_status := 'E';
         x_message := lc_err_desc;
         
      WHEN OTHERS THEN
         ROLLBACK;
         lc_err_desc := SUBSTR(lc_err_desc || '-' || SQLERRM,1,1000);
         lr_rep_exp_type :=
            xxom.XX_OM_REPORT_EXCEPTION_T (
                                      gc_exception_header              
                                     ,gc_track_code                    
                                     ,gc_solution_domain               
                                     ,lc_function                      
                                     ,lc_err_code
                                     ,lc_err_desc
                                     ,lc_entity_ref
                                     ,NVL(lc_entity_ref_id,0)
                                     );
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                      lr_rep_exp_type
                                                      ,lc_err_buf
                                                      ,lc_ret_code
                                                     );
         x_status := 'E';
         x_message := lc_err_desc;
   END DPS_CONF_LINE_UPD;

-----------------------------------------------------------------------
    -- Release Procedure
-- +===================================================================+
-- | Name  : DPS_HOLD_REL                                              |
-- | Description   : This Procedure will be used to Release the Hold   |
-- |                 namely 'DPS Hold' and update the order lines's    |
-- |                 attribute with XX_OM_RECONCILED                   |
-- |                                                                   |
-- | Parameters :      p_order_number                                  |
-- |                   p_line_id                                       |
-- |                   p_user_name                                     |
-- |                   p_resp_name                                     |
-- |                                                                   |
-- | Returns :     x_status                                            |
-- |               x_message                                           |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE DPS_HOLD_REL (
                            p_order_number   IN       oe_order_headers_all.order_number%TYPE
                           ,p_line_id        IN       oe_order_lines_all.line_id%TYPE
                           ,p_user_name      IN       fnd_user.user_name%TYPE
                           ,p_resp_name      IN       fnd_responsibility_tl.responsibility_name%TYPE
                           ,x_status         OUT      VARCHAR2
                           ,x_message        OUT      VARCHAR2
                          )                 
   IS
      -- Variable Declaration

      EX_FAILED                   EXCEPTION;
      lc_err_desc                 xx_om_global_exceptions.description%TYPE
                                                             DEFAULT 'OTHERS';
      lc_entity_ref               xx_om_global_exceptions.entity_ref%TYPE;
      lc_entity_ref_id            xx_om_global_exceptions.entity_ref_id%TYPE;
      lc_err_code                 xx_om_global_exceptions.ERROR_CODE%TYPE;
      lc_function                 VARCHAR2(100) :=  'I1153_DPSReleaseOrderInbound';
      lc_relhold_status           VARCHAR2 (240);
      lc_relhold_msg_data         VARCHAR2 (2000);
      lc_release_comment          fnd_lookup_values.meaning%TYPE;
      ln_header_id                oe_order_headers_all.header_id%TYPE;
      lt_order_tbl                oe_holds_pvt.order_tbl_type;
      ln_hold_id                  oe_hold_definitions.hold_id%TYPE;
      ln_msg_count                NUMBER;
      ln_combination_id           xx_om_lines_attributes_all.combination_id%TYPE;
      ln_parent_cnt               NUMBER := 0 ;
      ln_order_cnt                NUMBER := 0;
      ln_line_id                  NUMBER ;
      ln_count                    NUMBER := 0 ;
      lr_rep_exp_type             xxom.xx_om_report_exception_t;
      lc_app_init_status          VARCHAR2(100);
      lc_msg                      VARCHAR2(1000);
      lc_return_status            VARCHAR2 (1000);
      lc_msg_count                NUMBER;
      lc_msg_data                 VARCHAR2 (2000);
      lc_err_buf                  VARCHAR2 (1000);
      lc_ret_code                 VARCHAR2 (100);
      x_return_status             VARCHAR2(1);
       CURSOR lcu_parent_lines_detail(p_parent_line_id xx_om_line_attributes_all.ext_top_model_line_id%TYPE )
       IS
       SELECT OOLA.line_id
              ,XXOL.trans_line_status
        FROM  oe_order_lines_all OOLA      
             ,xx_om_line_attributes_all XXOL
        WHERE OOLA.line_id                = XXOL.line_id
        AND XXOL.ext_top_model_line_id    = p_parent_line_id;

   BEGIN
      -- Apps Initialisation
      x_status  := FND_API.G_RET_STS_SUCCESS;
      x_message := 'Success';

      -- Apps Initialisation
      XX_OM_DPS_APPS_INIT_PKG.DPS_APPS_INIT ( 
                                               p_user_name       
                                               ,p_resp_name      
                                               ,lc_app_init_status
                                               ,lc_msg
                                             );
     
      IF  (lc_app_init_status =FND_API.G_RET_STS_SUCCESS) THEN
 
         -- VALIDATION LIST
              -- 1) Order Number Validation; Order Number should not be null and should exist in EBS.
              -- 2) Parent Validation; Input Parent Line ID should a valid Parent Line.

              --Order number Validation
           
         IF (p_order_number IS NULL) THEN
            FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_NULL_INPUTORDER');
            lc_err_desc      := FND_MESSAGE.GET;
            lc_err_code      := 'XX_OM_DPS_NULL_INPUTORDER';
            lc_entity_ref    := 'Order_number';
            lc_entity_ref_id := 00000;
            RAISE EX_FAILED;
         END IF;
         
            -- Check for the Existence of Order for the Given Parent Line ID
            SELECT count(*)
            INTO ln_order_cnt
            FROM oe_order_headers_all OEH
            WHERE OEH.order_number = p_order_number
            AND exists( SELECT 1 FROM oe_order_lines_all oel,
                                     xx_om_line_attributes_all xol
                       WHERE oel.line_id               =xol.line_id
                       AND   xol.ext_top_model_line_id =p_line_id 
                       AND   oel.header_id             =oeh.header_id);

         
            IF ln_order_cnt >0 THEN

              FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_INVALIDORDERNUM');
              lc_err_desc      := FND_MESSAGE.GET;
              lc_err_code      := 'XX_OM_DPS_INVALIDORDERNUM';
              lc_entity_ref    := 'Order_Number';
              lc_entity_ref_id := NVL(p_order_number,0);
            
            END IF;

              --Check if there is atleast one parent exists (PARENT Validation)
              SELECT  COUNT(*)
              INTO  ln_parent_cnt
              FROM  oe_order_lines_all OOLA      
                    ,xx_om_line_attributes_all XXOL
              WHERE  OOLA.line_id                = XXOL.line_id                
              AND  XXOL.ext_top_model_line_id    = p_line_id;

             IF ( ln_parent_cnt = 0 ) THEN
                 
               FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_INVALID_PARENT');
               lc_err_code      := 'XX_OM_DPS_INVALID_PARENT';
               lc_err_desc      := FND_MESSAGE.GET;
               lc_entity_ref    := 'Parent Line ID';
               lc_entity_ref_id := TO_CHAR( p_line_id );
               RAISE EX_FAILED;
            END IF;


         -- Fetching all the lines in the bundle and releasing holds.
         lc_relhold_msg_data := NULL;

         
            
           
          --Hold Check
         
        BEGIN
        
          SELECT OHSA.hold_id                                            
                ,OOHO.header_id
                ,OOLA.line_id
          INTO   ln_hold_id
                ,ln_header_id
                ,ln_line_id
          FROM   oe_hold_definitions OHD
                ,oe_hold_sources_all OHSA
                ,oe_order_holds_all  OOHO
                ,oe_order_lines_all  OOLA
                ,xx_om_line_attributes_all XXOL 
          WHERE OHD.NAME                    = gc_hold_name                      
          AND OHD.hold_id                   = OHSA.hold_id
          AND OHSA.hold_source_id           = OOHO.hold_source_id
          AND OOHO.released_flag            = 'N'
          AND OOHO.line_id                  = OOLA.line_id 
          AND XXOL.ext_top_model_line_id    = p_line_id
          AND XXOL.line_id                  = OOLA.line_id;  
          
          lt_order_tbl (1).header_id := ln_header_id;
          lt_order_tbl (1).line_id := NVL(ln_line_id,0);

      EXCEPTION 
       WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_NO_HOLD');
          lc_err_desc      := FND_MESSAGE.GET;
          lc_err_code      := 'XX_OM_DPS_NO_HOLD';
          lc_entity_ref    := 'Line ID';
          lc_entity_ref_id := NVL(p_line_id,0);
          RAISE EX_FAILED;
       WHEN TOO_MANY_ROWS THEN
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_INVALID_HOLD');
          lc_err_desc      := FND_MESSAGE.GET;
          lc_err_code      := 'XX_OM_DPS_INVALID_HOLD';
          lc_entity_ref    := 'Line ID';
          lc_entity_ref_id := NVL(p_line_id,0);
          RAISE EX_FAILED;
      END;
      
       --Calling Release Holds API
          
      BEGIN        
          SELECT FLV.meaning
          INTO lc_release_comment
          FROM fnd_lookup_values FLV
          WHERE FLV.lookup_type = gc_release_type
          AND FLV.lookup_code = gc_release_code
          AND FLV.enabled_flag = 'Y'
          AND FLV.language = USERENV('LANG');
          
      EXCEPTION 
       WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_RELEASEHOLD');
          lc_err_desc        := FND_MESSAGE.GET;
          lc_err_code        := 'XX_OM_DPS_RELEASEHOLD';
          lc_entity_ref      := 'Order Number';
          lc_entity_ref_id   := p_order_number;
          RAISE EX_FAILED;
       WHEN TOO_MANY_ROWS THEN
          FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_RELEASEHOLD');
          lc_err_desc      := FND_MESSAGE.GET;
          lc_err_code      := 'XX_OM_DPS_RELEASEHOLD';
          lc_entity_ref    := 'Order Number';
          lc_entity_ref_id := p_order_number;
          RAISE EX_FAILED;
        END;
        
          -- Release Holds
          OE_HOLDS_PUB.RELEASE_HOLDS (
                                      p_api_version              => 1.0
                                     ,p_order_tbl                => lt_order_tbl
                                     ,p_hold_id                  => ln_hold_id
                                     ,p_release_reason_code      => gc_release_code       
                                     ,p_release_comment          => lc_release_comment      
                                     ,x_return_status            => lc_relhold_status
                                     ,x_msg_count                => ln_msg_count
                                     ,x_msg_data                 => lc_relhold_msg_data
                                    );

         IF (lc_relhold_status <> FND_API.G_RET_STS_SUCCESS) THEN
            IF (ln_msg_count > 0) THEN
               FOR i IN 1 .. ln_msg_count
               LOOP
                  lc_relhold_msg_data := lc_relhold_msg_data || '  ' ||
                  OE_MSG_PUB.GET ( 
                                   p_msg_index       => i
                                   ,p_encoded        => 'E'
                                  );
               END LOOP;
            END IF;

            lc_err_code   := 'PROCESS ORDER ERR';
            lc_err_desc   := lc_relhold_msg_data;
            lc_entity_ref := 'Order_number';
            lc_entity_ref := NVL(p_order_number,0);
            RAISE EX_FAILED;
         END IF;       
            -- call the Custom API to update the DPS Cancel Status

  FOR  parent_lines_detail_rec_type IN lcu_parent_lines_detail(p_line_id )
  LOOP 
           IF (parent_lines_detail_rec_type.trans_line_status in (gc_dpsConfStatus,gc_dps_hold_new) ) THEN
               ln_count := ln_count + 1;  

              xx_om_dpscancel_pkg.update_status( parent_lines_detail_rec_type.line_id
                                                ,gc_dspRelStatus
                                                ,x_return_status
                                               );

            IF x_return_status <>FND_API.G_RET_STS_SUCCESS THEN

                FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_PROCESS_ORDER_FAIL');
                lc_err_desc      := FND_MESSAGE.GET;
                lc_err_code      := 'XX_OM_DPS_PROCESS_ORDER_FAIL';
                lc_entity_ref    := 'Order Number';
                lc_entity_ref_id := NVL(p_order_number,0);
                RAISE EX_FAILED;
  
            
           END IF; -- release hold status
         
      ELSE
               FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_DPS_INVALID_STATUS');
               lc_err_desc      := FND_MESSAGE.GET;
               lc_err_code      := 'XX_OM_DPS_INVALID_STATUS';
               lc_entity_ref    := 'Order Number';
               lc_entity_ref_id := NVL(p_order_number,0);
               RAISE EX_FAILED;
     END IF;
    END LOOP;
   
  ELSE
         FND_MESSAGE.SET_NAME('XXOM', 'XX_OM_DPS_APPSINT_FAILED');
         x_message := FND_MESSAGE.GET;                             
         lc_err_code       := 'XX_OM_DPS_APPSINT_FAILED';         
         lc_err_desc       := FND_MESSAGE.GET;                     
         lc_entity_ref     := 'Order_number';                      
         lc_entity_ref_id  := NVL(p_order_number,0);               
         RAISE EX_FAILED;                                          
  END IF; -- apps status end if
  COMMIT;
   EXCEPTION
      WHEN EX_FAILED THEN
         ROLLBACK;
         lr_rep_exp_type :=
            XX_OM_REPORT_EXCEPTION_T (
                                      gc_exception_header               
                                      ,gc_track_code                   
                                      ,gc_solution_domain               
                                      ,lc_function                      
                                      ,lc_err_code
                                      ,lc_err_desc
                                      ,lc_entity_ref
                                      ,NVL(lc_entity_ref_id,0)
                                     );
         
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                     lr_rep_exp_type
                                                    ,lc_err_buf
                                                    ,lc_ret_code
                                                    );
         x_status := 'E';
         x_message := lc_err_desc;
         
      WHEN OTHERS THEN
         ROLLBACK;
         lc_err_desc := SUBSTR(lc_err_desc || '-' || SQLERRM,1,1000);
         lr_rep_exp_type :=
                  XX_OM_REPORT_EXCEPTION_T (
                                            gc_exception_header              
                                            ,gc_track_code                    
                                            ,gc_solution_domain              
                                            ,lc_function                     
                                            ,lc_err_code
                                            ,lc_err_desc
                                            ,lc_entity_ref
                                            ,NVL(lc_entity_ref_id,0)
                                           );
              
         XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                      lr_rep_exp_type
                                                      ,lc_err_buf
                                                      ,lc_ret_code
                                                      );
         x_status := 'E';
         x_message := lc_err_desc;
   END DPS_HOLD_REL;

   

END XX_OM_DPS_CONF_REL_PKG;
/
SHOW ERROR
