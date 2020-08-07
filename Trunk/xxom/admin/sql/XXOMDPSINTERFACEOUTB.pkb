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
-- | Name  :    XX_OM_DPSInterface_PKG                                 |
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
-- |DRAFT 1A 05-MAR-2007  Aravind A        Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
AS
   -- Global parameters
      gc_event_name          VARCHAR2(100)                                   :=  'xx.oracle.apps.om.DPSLines.out';
      gc_hold_name           VARCHAR2(100)                                   :=  'DPS Hold';
      gc_exception_header    xxom.xx_om_global_exceptions.exception_header%TYPE   :=  'OTHERS';
      gc_track_code          xxom.xx_om_global_exceptions.track_code%TYPE         :=  'OTC';
      gc_solution_domain     xxom.xx_om_global_exceptions.solution_domain%TYPE    :=  'Internal Fulfillment';
      gc_function            xxom.xx_om_global_exceptions.function%TYPE           :=  'I1148_DPSCreateOrderOutbound';
      gc_dps_status	     VARCHAR2(24)                                    :=  'XX_OM_HLD_NEW';
 





   PROCEDURE RAISE_BUSINESS_EVENT (
      p_parent_line_id   IN       VARCHAR2
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
      EX_NO_HOLD          EXCEPTION;
      EX_MULTIPLE_HOLDS   EXCEPTION;
      EX_NOT_PARENT       EXCEPTION;
 
      lc_flv_code         FND_LOOKUP_VALUES.lookup_code%TYPE DEFAULT 'DPS';
      lc_flv_lang         FND_LOOKUP_VALUES.language%TYPE DEFAULT 'US';
      lc_flv_type         FND_LOOKUP_VALUES.lookup_type%TYPE DEFAULT 'XX_OM_LINE_TYPES';
 
      lc_hold_name        OE_HOLD_DEFINITIONS.NAME%TYPE;
      lc_parent_line      OE_ORDER_LINES_ALL.attribute7%TYPE;
      lc_err_code         xxom.xx_om_global_exceptions.ERROR_CODE%TYPE
                                                                  DEFAULT ' ';
     
      lc_err_desc         xxom.xx_om_global_exceptions.description%TYPE
                                                                  DEFAULT ' ';
      
      lc_entity_ref       xxom.xx_om_global_exceptions.entity_ref%TYPE;
     
      lc_error_flag       VARCHAR2 (10)                                := 'N';
      ln_dps_count        NUMBER                                    DEFAULT 0;
      ln_conf_id_count    NUMBER                                    DEFAULT 0;
      ln_line_id          OE_ORDER_LINES_ALL.attribute7%TYPE;
      ln_resp_id          FND_RESPONSIBILITY_TL.responsibility_id%TYPE;
      ln_resp_appl_id     FND_RESPONSIBILITY_TL.application_id%TYPE;
      ln_user_id          FND_USER.user_id%TYPE;
      err_report_type     xx_om_report_exception_t;
      x_err_buf           VARCHAR2 (40);
      x_ret_code          VARCHAR2 (10);
   BEGIN
      lc_error_flag := 'N';
 
      FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_BE_FAILED');
      x_return_status := 'Failed';
      x_message := FND_MESSAGE.GET;
 
      --To check whether the Line ID equals the Parent Line ID
      --Ensuring that the event is raised only once per bundle
      BEGIN
         SELECT OOLA.line_id
           INTO ln_line_id
           FROM oe_order_lines_all OOLA
         ,xx_om_lines_attributes_all XOLAA
          WHERE OOLA.attribute6 = TO_CHAR(XOLAA.combination_id)
            AND XOLAA.segment14 = p_parent_line_id
            AND XOLAA.segment15 IS NULL;
 
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            RAISE EX_NOT_PARENT;       --Ensure the business event is not raised for non parent line_idd
         WHEN TOO_MANY_ROWS
         THEN
            RAISE EX_NOT_PARENT;
      END;
 
      --To Check whether the bundle contais DPS lines,
      --Check whether the Parent Line is of DPS Type.

      SELECT COUNT (line_id)
        INTO ln_dps_count
        FROM oe_order_lines_all OOLA
      ,xx_om_lines_attributes_all XOLAA
      ,fnd_lookup_values FLV
       WHERE OOLA.attribute6 = TO_CHAR(XOLAA.combination_id)
         AND XOLAA.segment14 = p_parent_line_id
         AND XOLAA.segment7 = FLV.meaning
         AND FLV.lookup_type = lc_flv_type
         AND FLV.lookup_code  = lc_flv_code
         AND FLV.language = lc_flv_lang;

 
      --If the DPS Count is ZERO then appropriate message
      --is recorded in the global exceptions table

      IF (ln_dps_count = 0)
      THEN
         lc_error_flag := 'Y';
         lc_err_code := '0001';
         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_NO_DPS_TYPE');
         lc_err_desc := FND_MESSAGE.GET;
         x_return_status := 'Failed';
         x_message := FND_MESSAGE.GET;
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
            xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                      ,gc_track_code                    --'OTC'
                                      ,gc_solution_domain               --'Internal Fulfillment'
                                      ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                      ,lc_err_code
                                      ,lc_err_desc
                                      ,lc_entity_ref
                                      ,NVL(p_parent_line_id,0)
                                     );
         xx_om_global_exception_pkg.INSERT_EXCEPTION (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
      ELSE
         --To Check whether the DPS lines contains hold of type "DPS Hold".
         --Obtain the Hold name using the Hold ID
         BEGIN
            SELECT DISTINCT OHD.NAME
              INTO lc_hold_name
              FROM oe_hold_definitions OHD
                  ,oe_order_holds_all OOHO
                  ,oe_hold_sources_all OHSA
                  ,oe_order_lines_all OOLA
                  ,xx_om_lines_attributes_all XOLAA
             WHERE OOLA.attribute6 = TO_CHAR (XOLAA.combination_id)
               AND OOLA.line_id = OOHO.line_id
               AND OOHO.hold_source_id = OHSA.hold_source_id
               AND OHSA.hold_id = OHD.hold_id
               AND XOLAA.segment14 = p_parent_line_id
               AND OOHO.released_flag != 'Y';
 
            --If the Hold is not "DPS Hold" then appropriate message
            --is recorded in the global exceptions table
            IF (lc_hold_name <> gc_hold_name)
            THEN
               lc_error_flag := 'Y';
               lc_err_code := '0002';
               FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_NO_HOLD_FOR_PROD');
               lc_err_desc := FND_MESSAGE.GET;
               x_message := FND_MESSAGE.GET;
               x_return_status := 'Failed';
               lc_entity_ref := 'Parent_line_id';
               err_report_type :=
                   xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                             ,gc_track_code                    --'OTC'
					     ,gc_solution_domain               --'Internal Fulfillment'
                                             ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                             ,lc_err_code
                                             ,lc_err_desc
                                             ,lc_entity_ref
                                             ,NVL(p_parent_line_id,0)
                                            );
               xx_om_global_exception_pkg.INSERT_EXCEPTION (err_report_type
                                                          ,x_err_buf
                                                          ,x_ret_code
                                                          );
            ELSE
               --To Check atleast one DPS line has Configuration ID value
               --Obtain the count of DPS lines having Configuration ID value in the given bundle.
               SELECT COUNT (line_id)
                 INTO ln_conf_id_count
                 FROM oe_order_lines_all OOLA
                     ,xx_om_lines_attributes_all XOLAA
                     ,xx_om_lines_attributes_all XOLAA1
                WHERE OOLA.attribute7 = TO_CHAR (XOLAA.combination_id)
                  AND OOLA.attribute6 = TO_CHAR (XOLAA1.combination_id)
                  AND XOLAA.segment3 IS NOT NULL
                  AND XOLAA1.segment14 = p_parent_line_id;
 
               --If the Count is ZERO then appropriate message
               --is recorded in the global exceptions table
               IF (ln_conf_id_count = 0)
               THEN
                  lc_error_flag := 'Y';
                  lc_err_code := '0003';
                  FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_NO_CONFIG_ID');
                  lc_err_desc := FND_MESSAGE.GET;
                  --lc_err_desc := 'None of the lines in the given Bundle has Configuration ID';
                  x_message := FND_MESSAGE.GET;
                  x_return_status := 'Failed';
                  lc_entity_ref := 'Parent_line_id';
                  err_report_type :=
                     xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                               ,gc_track_code                    --'OTC'
                                               ,gc_solution_domain               --'Internal Fulfillment'
                                               ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );
                  xx_om_global_exception_pkg.INSERT_EXCEPTION (err_report_type
                                                             ,x_err_buf
                                                             ,x_ret_code
                                                             );
               END IF;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               lc_error_flag := 'Y';
               RAISE EX_NO_HOLD;
            WHEN TOO_MANY_ROWS
            THEN
               lc_error_flag := 'Y';
               RAISE EX_MULTIPLE_HOLDS;
         END;
      END IF;
 
      IF lc_error_flag = 'N'
      THEN
         --Raising Business Event
         --Passing Parent line id as the event_key parameter.
         WF_EVENT.RAISE (p_event_name      => gc_event_name
                        ,p_event_key       => p_parent_line_id);
         x_return_status := 'Success';
         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_BE_SUCCESS');
         x_message := FND_MESSAGE.GET;
      END IF;
 
      COMMIT;
   EXCEPTION
      WHEN EX_NOT_PARENT
      THEN
         lc_err_code := '0013';
         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_NOT_PARENT');
         lc_err_desc := FND_MESSAGE.GET;
         x_return_status := 'Failed';
         x_message := FND_MESSAGE.GET;
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
                 xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                               ,gc_track_code                    --'OTC'
                                               ,gc_solution_domain               --'Internal Fulfillment'
                                               ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );
         xx_om_global_exception_pkg.INSERT_EXCEPTION (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
      WHEN EX_NO_HOLD
      THEN
         lc_err_code := '0002';
         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_NO_HOLD_FOR_PROD');
         lc_err_desc := FND_MESSAGE.GET;
         x_message := FND_MESSAGE.GET;
         x_return_status := 'Failed';
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
                 xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                               ,gc_track_code                    --'OTC'
                                               ,gc_solution_domain               --'Internal Fulfillment'
                                               ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );
         xx_om_global_exception_pkg.INSERT_EXCEPTION (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
      WHEN EX_MULTIPLE_HOLDS
      THEN
         lc_err_code := '0011';
         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_MULTIPLE_HOLDS');
         lc_err_desc := FND_MESSAGE.GET;
         x_message := FND_MESSAGE.GET;
         x_return_status := 'Failed';
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
                 xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                               ,gc_track_code                    --'OTC'
                                               ,gc_solution_domain               --'Internal Fulfillment'
                                               ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );
         xx_om_global_exception_pkg.INSERT_EXCEPTION (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
      WHEN OTHERS
      THEN
         lc_err_code := '0004';
         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_BE_FAILED');
         lc_err_desc := FND_MESSAGE.GET||' The error message is '||SQLERRM;
         x_message := FND_MESSAGE.GET;
         x_return_status := 'Failed';
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
                     xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                               ,gc_track_code                    --'OTC'
                                               ,gc_solution_domain               --'Internal Fulfillment'
                                               ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );         --entity_ref_id subject to change
         xx_om_global_exception_pkg.INSERT_EXCEPTION (err_report_type
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
   -- 1.Acknowledgement from the BPEL Process is updated in the OE_ORDER_LINES_ALL table
   -- Steps involved:-
   -- a.Fetch the DPS lines having configuration id value for the given bundle(Parent Line Id)
   -- b.Set the required dps status in a variable
   -- c.Call the OE_ORDER_PUB.Process_Order API to update the DPS Status in OE_ORDER_LINES_ALL table
   -- d.If any exceptions occur those are recorded in the Global exceptions table
   PROCEDURE UPDATE_ACKNOWLEDGEMENT (
      p_parent_line_id   IN       VARCHAR2
      ,p_user_name       IN       VARCHAR2
      ,p_resp_name       IN       VARCHAR2
      ,x_return_status   OUT      VARCHAR2
      ,x_message         OUT      VARCHAR2
   )
   IS
      EX_INVALID_COMBINATION         EXCEPTION;
 
      lc_err_code                    xx_om_global_exceptions.error_code%TYPE
                                                               DEFAULT '0000';
      lc_err_desc                    xx_om_global_exceptions.description%TYPE
                                                             DEFAULT 'OTHERS';
      lc_entity_ref                  xx_om_global_exceptions.entity_ref%TYPE
                                                             DEFAULT 'OTHERS';
      lc_segment                     VARCHAR2 (4000);
 
      lc_flv_code                    FND_LOOKUP_VALUES.lookup_code%TYPE DEFAULT 'DPS';
      lc_flv_lang                    FND_LOOKUP_VALUES.language%TYPE DEFAULT 'US';
      lc_flv_type                    FND_LOOKUP_VALUES.lookup_type%TYPE DEFAULT 'XX_OM_LINE_TYPES';
 
      lc_init_status                 VARCHAR2(40);
      lc_init_message                VARCHAR2(100);
      ln_invalid_comb_line           OE_ORDER_LINES_ALL.line_id%TYPE;
      err_report_type                xx_om_report_exception_t;
      x_err_buf                      VARCHAR2 (40);
      x_ret_code                     VARCHAR2 (10);
      ln_count                       NUMBER                         DEFAULT 0;
      lc_status                      VARCHAR2 (1);
      ln_combination_id              NUMBER;
      ln_structure_id                NUMBER;
      ln_msg_count                   NUMBER;
      ln_resp_id                     FND_RESPONSIBILITY_TL.responsibility_id%TYPE;
      ln_resp_appl_id                FND_RESPONSIBILITY_TL.application_id%TYPE;
      ln_user_id                     fnd_user.user_id%TYPE;
      lc_msg_data                    VARCHAR2 (4000)              DEFAULT ' ';
      lc_dps_status                  VARCHAR2(100)                DEFAULT ' ';
      lt_in_line_tbl                 OE_ORDER_PUB.line_tbl_type;
      lr_header_rec                  OE_ORDER_PUB.header_rec_type;
      lr_header_val_rec              OE_ORDER_PUB.header_val_rec_type;
      lt_header_adj_tbl              OE_ORDER_PUB.header_adj_tbl_type;
      lt_header_adj_val_tbl          OE_ORDER_PUB.header_adj_val_tbl_type;
      lt_header_price_att_tbl        OE_ORDER_PUB.header_price_att_tbl_type;
      lt_header_adj_att_tbl          OE_ORDER_PUB.header_adj_att_tbl_type;
      lt_header_adj_assoc_tbl        OE_ORDER_PUB.header_adj_assoc_tbl_type;
      lt_header_scredit_tbl          OE_ORDER_PUB.header_scredit_tbl_type;
      lt_header_scredit_val_tbl      OE_ORDER_PUB.header_scredit_val_tbl_type;
      lt_out_line_tbl                OE_ORDER_PUB.line_tbl_type;
      lt_line_val_tbl                OE_ORDER_PUB.line_val_tbl_type;
      lt_line_adj_tbl                OE_ORDER_PUB.line_adj_tbl_type;
      lt_line_adj_val_tbl            OE_ORDER_PUB.line_adj_val_tbl_type;
      lt_line_price_att_tbl          OE_ORDER_PUB.line_price_att_tbl_type;
      lt_line_adj_att_tbl            OE_ORDER_PUB.line_adj_att_tbl_type;
      lt_line_adj_assoc_tbl          OE_ORDER_PUB.line_adj_assoc_tbl_type;
      lt_line_scredit_tbl            OE_ORDER_PUB.line_scredit_tbl_type;
      lt_line_scredit_val_tbl        OE_ORDER_PUB.line_scredit_val_tbl_type;
      lt_lot_serial_tbl              OE_ORDER_PUB.lot_serial_tbl_type;
      lt_lot_serial_val_tbl          OE_ORDER_PUB.lot_serial_val_tbl_type;
      lt_action_request_tbl          OE_ORDER_PUB.request_tbl_type;
 
      --Cursor Declaration
      CURSOR lcu_lines
      IS
         SELECT OOLA.line_id
               ,OOLA.header_id
               ,OOLA.attribute6
         FROM oe_order_lines_all OOLA
               ,xx_om_lines_attributes_all XOLAA
               ,xx_om_lines_attributes_all XOLAA1
               ,fnd_lookup_values FLV
         WHERE OOLA.attribute7 = TO_CHAR (XOLAA.combination_id)
            AND OOLA.attribute6 = TO_CHAR (XOLAA1.combination_id)
            AND XOLAA1.segment14 = p_parent_line_id
            AND XOLAA1.segment7 = FLV.meaning
            AND FLV.lookup_code = lc_flv_code
            AND FLV.lookup_type = lc_flv_type
            AND FLV.language = lc_flv_lang
            AND XOLAA.segment3 IS NOT NULL;
   BEGIN
 
      XX_OM_DPS_APPS_INIT_PKG.XX_OM_DPS_APPS_INIT_PROC(p_user_name,p_resp_name,lc_init_status,lc_init_message);
 
      --Assigning the DPS status
      lc_dps_status := 'XX_OM_HLD_NEW';
 
      --Loop each of the bundle lines to set the acknowledgement details
      --using the line tbl type variable
      FOR lines_rec_type IN lcu_lines
      LOOP
         lc_err_code := '0014';
         FND_MESSAGE.SET_NAME ('XXOM', 'ODP_OM_DPS_INVALID_STRUC');
         lc_err_desc := FND_MESSAGE.GET;
         lc_entity_ref := 'Parent_line_id';
 
         SELECT    segment6
                || '.'
                || segment7
                || '.'
                || segment8
                || '.'
                || segment5
                || '.'
                || segment3
                || '.'
                || segment2
                || '.'
                || segment4
                || '.'
                || segment9
                || '.'
                || gc_dps_status
                || '.'
                || segment11
                || '.'
                || segment12
                || '.'
                || segment13
                || '.'
                || segment14
                || '.'
                || segment15
                || '.'
                || segment20
                || '.'
                || segment18
                || '.'
                || segment19
                || '.'
                || segment16
                || '.'
                || segment17
                || '.'
                || segment21
                || '.'
                || segment22
                || '.'
                || segment23
                || '.'
                || segment24
                || '.'
                || segment25
                || '.'
                || segment26
                || '.'
                || segment27
                || '.'
                || segment28
                || '.'
                || segment29
                || '.'
                || segment30
               ,structure_id
           INTO lc_segment
               ,ln_structure_id
           FROM XX_OM_LINES_ATTRIBUTES_ALL
          WHERE combination_id = TO_NUMBER (lines_rec_type.attribute6);
         --get the new combination ID to be updated in attribute6 column
         --of the OE_ORDER_LINES_ALL table
 
         ln_combination_id :=
            FND_FLEX_EXT.GET_CCID ('XXOM'
                                  ,'XXOL'
                                  ,ln_structure_id
                                  ,SYSDATE
                                  ,lc_segment
                                  );
 
         --if no such combination exists then log the error
         --in the global exceptions table
         IF (ln_combination_id = 0)
         THEN
            ln_invalid_comb_line := lines_rec_type.line_id;
            RAISE EX_INVALID_COMBINATION;
         END IF;
 
         ln_count := ln_count + 1;
         --Initialising the required attibutes
         --that are necessary for using the Process_Order API
         lt_in_line_tbl (ln_count) := OE_ORDER_PUB.G_MISS_LINE_REC;
         lt_in_line_tbl (ln_count).header_id := lines_rec_type.header_id;
         lt_in_line_tbl (ln_count).operation := OE_GLOBALS.G_OPR_UPDATE;
         lt_in_line_tbl (ln_count).line_id := lines_rec_type.line_id;
         lt_in_line_tbl (ln_count).attribute6 := TO_CHAR (ln_combination_id);
      END LOOP;
 
      lc_err_code := '0005';
      fnd_message.set_name ('XXOM', 'ODP_OM_DPS_PROCESS_ORDER_FAIL');
      lc_err_desc := fnd_message.get;
      lc_entity_ref := 'oe_order_pub.process_order';
      --Call the Process_Order API passing the required parameters
 
     
      oe_order_pub.process_order
                    (p_api_version_number          => 1.0
                    ,p_init_msg_list               => fnd_api.g_true
                    ,p_return_values               => fnd_api.g_false
                    ,p_action_commit               => fnd_api.g_true
                    ,p_line_tbl                    => lt_in_line_tbl
                    ,x_return_status               => lc_status
                    ,x_msg_count                   => ln_msg_count
                    ,x_msg_data                    => lc_msg_data
                    ,x_header_rec                  => lr_header_rec
                    ,x_header_val_rec              => lr_header_val_rec
                    ,x_header_adj_tbl              => lt_header_adj_tbl
                    ,x_header_adj_val_tbl          => lt_header_adj_val_tbl
                    ,x_header_price_att_tbl        => lt_header_price_att_tbl
                    ,x_header_adj_att_tbl          => lt_header_adj_att_tbl
                    ,x_header_adj_assoc_tbl        => lt_header_adj_assoc_tbl
                    ,x_header_scredit_tbl          => lt_header_scredit_tbl
                    ,x_header_scredit_val_tbl      => lt_header_scredit_val_tbl
                    ,x_line_tbl                    => lt_out_line_tbl
                    ,x_line_val_tbl                => lt_line_val_tbl
                    ,x_line_adj_tbl                => lt_line_adj_tbl
                    ,x_line_adj_val_tbl            => lt_line_adj_val_tbl
                    ,x_line_price_att_tbl          => lt_line_price_att_tbl
                    ,x_line_adj_att_tbl            => lt_line_adj_att_tbl
                    ,x_line_adj_assoc_tbl          => lt_line_adj_assoc_tbl
                    ,x_line_scredit_tbl            => lt_line_scredit_tbl
                    ,x_line_scredit_val_tbl        => lt_line_scredit_val_tbl
                    ,x_lot_serial_tbl              => lt_lot_serial_tbl
                    ,x_lot_serial_val_tbl          => lt_lot_serial_val_tbl
                    ,x_action_request_tbl          => lt_action_request_tbl
                    );
 
      --If Process_Order API fails to update the records
      --then record the exception in global exceptions table
      IF (lc_status != 'S')
      THEN
         IF (ln_msg_count > 0)
         THEN
            FOR i IN 1 .. ln_msg_count
            LOOP
               lc_msg_data :=
                     lc_msg_data
                  || ' '
                  || OE_MSG_PUB.GET (p_msg_index      => i, p_encoded => 'F');
            END LOOP;
         END IF;
         x_message := lc_msg_data;
         lc_err_code := '0006';
         lc_err_desc := lc_msg_data;
         lc_entity_ref := 'Parent_line_id';
         err_report_type :=
                 xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                               ,gc_track_code                    --'OTC'
                                               ,gc_solution_domain               --'Internal Fulfillment'
                                               ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );
         xx_om_global_exception_pkg.insert_exception (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
      END IF;
 
      COMMIT;
   EXCEPTION
      WHEN ex_invalid_combination
      THEN
         fnd_message.set_name ('XXOM', 'ODP_OM_DPS_INVALID_COMB');
         lc_err_code := '0012';
         lc_err_desc := FND_MESSAGE.GET;
         lc_entity_ref := 'LINE_ID';
         err_report_type :=
                 xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                               ,gc_track_code                    --'OTC'
                                               ,gc_solution_domain               --'Internal Fulfillment'
                                               ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );
         xx_om_global_exception_pkg.INSERT_EXCEPTION (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
      WHEN OTHERS
      THEN
         lc_err_desc := lc_err_desc||' The error is '||SQLERRM;
         err_report_type :=
                 xxom.xx_om_report_exception_t (gc_exception_header               --'OTHERS'
                                               ,gc_track_code                    --'OTC'
                                               ,gc_solution_domain               --'Internal Fulfillment'
                                               ,gc_function                      --'I1148_DPSCreateOrderOutbound'
                                               ,lc_err_code
                                               ,lc_err_desc
                                               ,lc_entity_ref
                                               ,NVL(p_parent_line_id,0)
                                               );
         xx_om_global_exception_pkg.insert_exception (err_report_type
                                                    ,x_err_buf
                                                    ,x_ret_code
                                                    );
   END UPDATE_ACKNOWLEDGEMENT;

END XX_OM_DPSINTERFACE_PKG;
/
SHOW ERROR
