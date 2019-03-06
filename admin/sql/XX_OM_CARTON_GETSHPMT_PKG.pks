SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE  XX_OM_CARTON_GETSHPMT_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name         : XX_OM_CARTON_WMOS_GETSHIPMNT_PKG                                         |
-- | Rice Id      : I0030_Cartonization                                                      | 
-- | Description  : Custom Test Package to create the XML DOc for OAGIS GetShipmentUnit      |
-- |                used for WMOS Cartonization.                                             |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   03-JUL-2007       Nabarun          Initial Version                            |
-- |                                                                                         |
-- +=========================================================================================+
AS

  --Declaring a record, which contains all the input attributes to wmos system
  
  TYPE xx_om_getshipmentunit_t IS RECORD 
                   (  delivery_id                NUMBER
                     ,delivery_number            VARCHAR2(100)
                     ,whse                       VARCHAR2(100)
                     ,delivery_line_number       NUMBER
                     ,sku                        VARCHAR2(200)
                     ,ctn_type                   VARCHAR2(200)
                     ,season                     VARCHAR2(200)
                     ,season_yr                  NUMBER
                     ,style                      VARCHAR2(200)
                     ,style_sfx                  VARCHAR2(200)
                     ,color                      VARCHAR2(200)
                     ,color_sfx                  VARCHAR2(200)
                     ,sec_dim                    NUMBER
                     ,qual                       VARCHAR2(200)
                     ,size_desc                  VARCHAR2(200)
                     ,sku_qty                    NUMBER
                     ,wholesale_sku_flag         VARCHAR2(200)
                     ,spl_instr_code_1           VARCHAR2(200)
                     ,spl_instr_code_2           VARCHAR2(200)
                     ,spl_instr_code_3           VARCHAR2(200)
                     ,spl_instr_code_4           VARCHAR2(200)
                     ,spl_instr_code_5           VARCHAR2(200)
                     ,spl_instr_code_6           VARCHAR2(200)
                     ,spl_instr_code_7           VARCHAR2(200)
                     ,spl_instr_code_8           VARCHAR2(200)
                     ,spl_instr_code_9           VARCHAR2(200)
                     ,spl_instr_code_10          VARCHAR2(200)
                     ,host_input_id              NUMBER
                     ,return_type                VARCHAR2(200)
                     );


  --Table of the record item_info
  TYPE xx_om_getshipmentunit_tbl IS TABLE OF xx_om_getshipmentunit_t INDEX BY BINARY_INTEGER;
  lt_getshipmentunit_tbl xx_om_getshipmentunit_tbl;
  
  --Declaring record type variable
  --------------------------------
  rec_getshipmentunit_t            xx_om_getshipmentunit_t;
  
  --Declaring the refcursor
  -------------------------
  TYPE lcu_delivery_details_rfcur IS REF CURSOR;
  
  --Declaring the variables holding the constant values for global exception handling framework
  ---------------------------------------------------------------------------------------------
  g_exception_header  CONSTANT xx_om_global_exceptions.exception_header%TYPE := 'OTHERS'            ;
  g_track_code        CONSTANT xx_om_global_exceptions.track_code%TYPE       := 'OTC'               ;
  g_solution_domain   CONSTANT xx_om_global_exceptions.solution_domain%TYPE  := 'Pick Release'      ;
  g_function          CONSTANT xx_om_global_exceptions.function_name%TYPE    := 'Cartonization WMOS';
  
  --Initializing the object type to parse the exception infos to global exception handling framework
  --------------------------------------------------------------------------------------------------
  lrec_excepn_obj_type xx_om_report_exception_t:= 
                                   xx_om_report_exception_t(NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL
                                                           ,NULL);

  -- +=================================================================+
  -- | Name  : Log_Exceptions                                          |
  -- | Rice Id      : I0030_Cartonization                              | 
  -- | Description: This procedure will be responsible to store all    |  
  -- |              the exceptions occured during the procees using    | 
  -- |              global custom exception handling framework         |
  -- +=================================================================+
  PROCEDURE log_exceptions( p_error_code        IN  VARCHAR2
                           ,p_error_description IN  VARCHAR2
                           ,p_entity_ref        IN  VARCHAR2
                           ,p_entity_ref_id     IN  PLS_INTEGER
                          );
  
  -- +===================================================================+
  -- | Name  : GetShipmentUnit_To_Wmos                                   |
  -- | Rice Id      : I0030_Cartonization                                | 
  -- | Description:       This Procedure will be used to generate        |
  -- |                    OAGIS9.0 XML Document as an input parameters to|
  -- |                    Manhattan EIS Server for WMoS                  |
  -- +===================================================================+
  PROCEDURE GetShipmentUnit_To_Wmos(
                                    p_delivery_id            IN   wsh_new_deliveries.delivery_id%TYPE
                                   ,x_getshipmentunit_tbl   OUT  NOCOPY xx_om_getshipmentunit_tbl
                                   );


END XX_OM_CARTON_GETSHPMT_PKG;
/
SHOW ERRORS;
--EXIT;