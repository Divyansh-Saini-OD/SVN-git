SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_DMDEXTLEG_PKG

AS
-- +=================================================================================================+
-- |                  Office Depot - Project Simplify                                                |
-- |                                                                                                 |
-- +=================================================================================================+
-- | Name        :  XX_OM_DMDEXTLEG_PKG.pkb                                                          |
-- | Description :  This package will extracts the Sales Order demand into 2 files for use in the    |
-- |                Legacy replenishment engine                                                      |
-- |                                                                                                 |
-- |Change Record:                                                                                   |
-- |===============                                                                                  |
-- |RiceID   Version   Date        Author           Remarks                                          |
-- |======  =======   ==========  =============    ================================                  |
-- |E1315   V1.0      27-Jun-2007 Marc Kelly       First Version                                     |
-- |                             |
-- |                             |
-- +=================================================================================================+



   G_exception_header   CONSTANT VARCHAR2(40) := 'DemandExtractToLegacy';
   G_track_code         CONSTANT VARCHAR2(5)  := 'OTC';
   G_solution_domain    CONSTANT VARCHAR2(40) := 'Order Management';

   -- NOTE: for now define a local seasonal_max_days and let nvl default to 365. just to run.
   -- when OM parameter is defined and finalized, edit cursor to use parameter value instead.
   g_seasonal_max_days  CONSTANT NUMBER := 365;


   exception_object_type xx_om_report_exception_t := xx_om_report_exception_t(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

-- +======================================================================+
-- | Name: Demand_Extract                                                 |
-- | Description: This procedure serves as the entry point to the package.|
-- |              It calls both DEMAND_EXTRACT_FUTURE and                 |
-- |              DEMAND_EXTRACT_SEASONAL private procedures.  Errors     |
-- |              creating flat files will be logged in global exceptions.|
-- |              Other errors wil be caught and logged and a business    |
-- |              event raised.                                           |
-- |                                                                      |
-- | Parameters:                                                          |
-- |              p_seasonal_file  - seasonal demand file name by default |
-- |                                 file name is XXOMDMDEXTLEGSEA.txt    |
-- |              p_future_file    - future demand file name by default   |
-- |                                 file name is XXOMDMDEXTLEGFUT.txt    |
-- |              p_file_location  - EBS XXOM output directory            |
-- |              x_retcode                                              |
-- |              x_errbuf                                               |
-- +======================================================================+
PROCEDURE Demand_Extract(
      x_retcode OUT NOCOPY NUMBER
      ,x_errbuf OUT NOCOPY VARCHAR2
      ,p_seasonal_file IN VARCHAR2
      ,p_future_file IN VARCHAR2
      ,p_file_location IN VARCHAR2
      )
IS

   lc_error_code VARCHAR2(40) DEFAULT '0';
   lc_error_message VARCHAR2(1000) DEFAULT '';


BEGIN


   --Call to Future Demand Extract procedure
   Demand_Extract_Future (
         p_future_file
         ,p_file_location
         ,lc_error_code
         ,lc_error_message
         );

   --If any error occured during processing or during the file
   --creation.
   IF TO_NUMBER(lc_error_code) <> 0 THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
      x_retcode := TO_NUMBER(lc_error_code);
      x_errbuf  := lc_error_message;
   ELSE
      --Call to Seasonal Demand Extract procedure
      Demand_Extract_seasonal (
            p_seasonal_file
            ,p_file_location
            ,lc_error_code
            ,lc_error_message
            );

      --If any error occured during processing or during the
      -- file creation.
      IF TO_NUMBER(lc_error_code) <> 0 THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
         x_retcode := TO_NUMBER(lc_error_code);
         x_errbuf  := lc_error_message;
      END IF;
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      x_retcode := 2;
      --Resubmit the concurrent program again.
      x_errbuf := 'Please check errors and resubmit sesonal demand extract';
      RAISE;

 END Demand_Extract;

-- +======================================================================+
-- | Name: Demand_Extract_Seasonal                                        |
-- | Description: This procedure extracts seasonal orders and creates     |
-- |              a flat file. Errors creating flat files will be         |
-- |              logged in global exception log.                         |
-- |                                                                      |
-- | Parameters:                                                          |
-- |              p_seasonal_file  - seasonal demand file name            |
-- |              p_file_location  - EBS XXOM output directory            |
-- |              x_ret_code                                              |
-- |              x_err_buf                                               |
-- +======================================================================+
PROCEDURE Demand_Extract_Seasonal (
                p_seasonal_file IN VARCHAR2
                ,p_file_location IN VARCHAR2
                ,x_error_code OUT NOCOPY NUMBER
                ,x_error_status OUT NOCOPY VARCHAR2
        )
IS

   l_utl_filetype UTL_FILE.FILE_TYPE;

   ln_primary_reserved_quantity NUMBER DEFAULT 0;
   ln_ordered_quantity NUMBER DEFAULT 0;
   lc_blank_2 VARCHAR2(2) := '  '; -- 2 spaces
   lc_blank_3 VARCHAR2(3) := '   '; -- 3 spaces
   lc_blank_8 VARCHAR2(8) := '        '; -- 8 spaces
   lc_blank_20 VARCHAR2(20) := '                    ';   -- 20 spaces
   lc_blank_38 VARCHAR2(38) := '                                      '; -- 38 spaces
   l_record VARCHAR2(500);

   lc_error_message VARCHAR2(1000);
   lc_error_code VARCHAR2(40);
   lc_function VARCHAR2(40):= 'DemandExtractSeasonal';


   CURSOR cursor_seasonal_lines IS
   SELECT
      H.order_number order_number
      ,H.order_type_id order_type_id
      ,L.header_id header_id
      ,L.line_type_id line_type_id
      ,L.line_id line_id
      ,SUBSTR(MSI.segment1,1,20) sku
      ,substr(MSI.description,1,30) sku_description
      ,HOU.Attribute1 Legacy_Org
      ,L.ordered_quantity ordered_quantity
      ,L.inventory_item_id inventory_item_id
      ,L.ship_from_org_id ship_from_org_id
      ,L.order_quantity_uom order_quantity_uom
      ,substr(MSI.primary_unit_of_measure,1,2) primary_uom
      ,IA.od_replen_sub_type_cd
      ,IA.od_replen_type_cd
      ,L.cust_po_number cust_po_number
      ,TO_CHAR(L.schedule_ship_date,'MMDDYYYY') schedule_ship_date
      ,TO_CHAR(NVL(L.promise_date,SYSDATE),'MMDDYYYY') promise_date
      ,TO_CHAR(L.creation_date,'MMDDYYYY') ordered_date
   FROM
      oe_order_headers_all H
      ,oe_order_lines_all L
      ,mtl_parameters MP
      ,mtl_system_items_b MSI
      ,hr_all_organization_units HOU
      ,oe_transaction_types_all OTT
      ,xx_om_line_attributes_all LA
      ,xx_inv_item_org_attributes IA
--      ,mtl_item_categories MIC
--      ,mtl_category_sets MCS
   WHERE
      H.booked_flag = 'Y'
      AND H.open_flag = 'Y'
      AND H.header_id = L.header_id
      AND L.schedule_ship_date IS NOT NULL
      AND L.ordered_quantity > 0
      AND L.ship_from_org_id = MP.organization_id
      AND L.ship_from_org_id IS NOT NULL
      AND L.source_type_code = 'INTERNAL'
      AND L.ato_line_id IS NULL
      AND L.Open_Flag = 'Y'
      AND L.Booked_Flag = 'Y'
      AND L.inventory_item_id = MSI.inventory_item_id
      AND L.ship_from_org_id = IA.organization_id
      AND L.inventory_item_id = IA.inventory_item_id
      AND MP.organization_id = MSI.organization_id
      AND MSI.organization_id = HOU.organization_id
      AND TRUNC(L.schedule_ship_date) <=
          TRUNC(NVL(MSI.end_date_active,SYSDATE+g_seasonal_max_days))
      AND L.line_id = LA.line_id
      AND H.order_type_id = OTT.transaction_type_id
      AND (NVL(OTT.attribute15,'X') = 'SEASONAL'
          OR NVL(LA.line_modifier,'X') = 'LARGE')
--      AND MIC.inventory_item_id = MSI.inventory_item_id
--      AND MIC.organization_id =  MP.organization_id
--      AND MCS.default_category_id = MIC.category_id
--      AND MCS.category_set_id = MIC.category_set_id
--      AND MCS.category_set_name = 'RMS Location Traits Attributes'
      AND NVL(L.ordered_quantity,0) >
          NVL((
            SELECT
               SUM(MR.primary_reservation_quantity)
            FROM
               mtl_reservations MR
               ,mfg_lookups ML
               ,mtl_sales_orders MSO
            WHERE
                   MR.demand_source_header_id = MSO.sales_order_id
               AND to_number(MSO.segment1) = H.order_number
               AND MR.demand_source_line_id = L.line_id
               AND MR.organization_id = L.ship_from_org_id
               AND MR.inventory_item_id = L.inventory_item_id
               AND MR.demand_source_type_id = ML.lookup_code
               AND NVL(ML.lookup_type,'X') = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
               AND ML.lookup_code in (2,9)
             ),0);

   record_seasonal_lines cursor_seasonal_lines%ROWTYPE;

BEGIN

   -- first open the flat file for write.
   IF NOT UTL_FILE.IS_OPEN(l_utl_filetype) THEN
      l_utl_filetype := UTL_FILE.FOPEN( p_file_location, p_seasonal_file, 'W' );
   END IF;

   -- then read through each of the order lines.
   -- ignore items not replenished.
   -- reduce ordered quantity by reserved quantity
   -- write the flat file..
   IF NOT cursor_seasonal_lines%ISOPEN THEN
      OPEN cursor_seasonal_lines;
   END IF;

   LOOP
      FETCH cursor_seasonal_lines INTO record_seasonal_lines;
      EXIT WHEN cursor_seasonal_lines%NOTFOUND;
      IF is_replenished(record_seasonal_lines.od_replen_type_cd
                        ,record_seasonal_lines.od_replen_sub_type_cd) THEN

         SELECT
            SUM (MR.primary_reservation_quantity)
         INTO
            ln_primary_reserved_quantity
         FROM
            mtl_reservations MR
            ,mfg_lookups ML
            ,mtl_sales_orders MSO
         WHERE
                MR.demand_source_header_id  = MSO.sales_order_id
            AND to_number(MSO.segment1) = record_seasonal_lines.order_number
            AND MR.demand_source_line_id = record_seasonal_lines.line_id
            AND MR.organization_id = record_seasonal_lines.ship_from_org_id
            AND MR.demand_source_type_id  = ML.lookup_code
            AND ML.lookup_type = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
            AND ML.lookup_code in (2,9);

         ln_ordered_quantity := NVL(record_seasonal_lines.ordered_quantity,0) -
                                NVL(ln_primary_reserved_quantity,0);

         l_record :=
               lc_blank_8                                             --vendor
            || RPAD(record_seasonal_lines.sku,20,' ')              --item
            || RPAD(record_seasonal_lines.legacy_org,4,'0')        --location
            || RPAD(record_seasonal_lines.sku_description,30,' ')  --description
            || lc_blank_20                                            --vendor item
            || RPAD(record_seasonal_lines.primary_uom,2,' ')       -- uom
            || lc_blank_8                                             -- customer
            || RPAD(NVL(record_seasonal_lines.cust_po_number, ' '),22,' ')   -- customer PO
            || record_seasonal_lines.promise_date                  -- delivery date
            || record_seasonal_lines.schedule_ship_date            -- in whse date
            || lc_blank_2                                             -- week
            || LPAD(TRUNC(ln_ordered_quantity), 5, '0')               -- quantity
            || '00000'                                             -- reserved qty
            || LPAD(record_seasonal_lines.order_number, 9, '0')    -- order number
            || lc_blank_3                                             -- sub number
            || record_seasonal_lines.ordered_date                  -- cust order date
            || lc_blank_38;

         UTL_FILE.put_line (l_utl_filetype, l_record);
      END IF;

   END LOOP;

   IF cursor_seasonal_lines%ISOPEN THEN
      CLOSE cursor_seasonal_lines;
   END IF;
   IF UTL_FILE.IS_OPEN(l_utl_filetype) THEN
      UTL_FILE.FCLOSE_ALL;
   END IF;

EXCEPTION
   WHEN UTL_FILE.INVALID_FILEHANDLE THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_I1315_INVALID_FILEHANDLE');
      x_error_code := 'XX_OM_I1315_INVALID_FILEHANDLE';
      x_error_status := FND_MESSAGE.GET;
      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    -1;
      exception_object_type.p_entity_ref        :=    'File_Name';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

   WHEN UTL_FILE.WRITE_ERROR THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_I1315_WRITE_ERROR');
      x_error_code := 'XX_OM_I1315_WRITE_ERROR';
      x_error_status := FND_MESSAGE.GET;
      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    -2;
      exception_object_type.p_entity_ref        :=    'File_Name';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

   WHEN UTL_FILE.INVALID_PATH THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_I1315_INVALID_PATH');
      x_error_code := 'XX_OM_I1315_INVALID_PATH';
      x_error_status := FND_MESSAGE.GET;
      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    -3;
      exception_object_type.p_entity_ref        :=    'File_Path';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

   WHEN UTL_FILE.INTERNAL_ERROR THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_I1315_INTERNAL_ERROR');
      x_error_code := 'XX_OM_I1315_INTERNAL_ERROR';
      x_error_status := FND_MESSAGE.GET;
      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    -4;
      exception_object_type.p_entity_ref        :=    'File_Name';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

   WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_65100_UNEXPECTED_ERROR');
      x_error_code := 'XX_OM_65100_UNEXPECTED_ERROR';
      x_error_status := FND_MESSAGE.GET;
      
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    SQLCODE;
      exception_object_type.p_entity_ref        :=    'SQLERROR';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

END Demand_Extract_Seasonal;

-- +======================================================================+
-- | Name: Demand_Extract_Future                                          |
-- | Description: This procedure extracts future orders and creates       |
-- |              a flat file. Errors creating flat files will be         |
-- |              logged in global exception log.                         |
-- |                                                                      |
-- | Parameters:                                                          |
-- |              p_future_file    - future demand file name              |
-- |              p_file_location  - EBS XXOM output directory            |
-- |              x_ret_code                                              |
-- |              x_err_buf                                               |
-- +======================================================================+
PROCEDURE Demand_Extract_Future (
                p_future_file IN VARCHAR2
                ,p_file_location IN VARCHAR2
                ,x_error_code OUT NOCOPY NUMBER
                ,x_error_status OUT NOCOPY VARCHAR2
        )
IS

   l_utl_filetype UTL_FILE.FILE_TYPE;

   ln_primary_reserved_quantity NUMBER DEFAULT 0;
   ln_ordered_quantity NUMBER DEFAULT 0;
   l_record VARCHAR2(500);

   lc_error_message VARCHAR2(1000);
   lc_error_code VARCHAR2(40);
   lc_function VARCHAR2(40):= 'DemandExtractFuture';

   CURSOR cursor_future_lines IS
   SELECT
      H.order_number order_number
      ,H.order_type_id order_type_id
      ,L.header_id header_id
      ,L.line_id line_id
      ,SUBSTR(MSI.segment1,1,20) sku
      ,HOU.Attribute1 Legacy_Org
      ,L.ordered_quantity ordered_quantity
      ,L.inventory_item_id inventory_item_id
      ,L.ship_from_org_id ship_from_org_id
      ,L.order_quantity_uom order_quantity_uom
      ,substr(MSI.primary_unit_of_measure,1,2) primary_uom
      ,IA.od_replen_sub_type_cd
      ,IA.od_replen_type_cd
   FROM
      oe_order_headers_all H
      ,oe_order_lines_all L
      ,mtl_parameters MP
      ,mtl_system_items_b MSI
      ,hr_all_organization_units HOU
      ,oe_transaction_types_all OTT
      ,xx_om_line_attributes_all LA
      ,xx_inv_item_org_attributes IA
--      ,mtl_item_categories MIC
--      ,mtl_category_sets MCS
   WHERE
      H.booked_flag = 'Y'
      AND H.open_flag = 'Y'
      AND H.header_id = L.header_id
      AND L.schedule_ship_date IS NOT NULL
      AND NVL(L.ordered_quantity,0) > 0
      AND L.ship_from_org_id = MP.organization_id
      AND L.ship_from_org_id IS NOT NULL
      AND L.source_type_code = 'INTERNAL'
      AND L.ato_line_id IS NULL
      AND L.Open_Flag = 'Y'
      AND L.Booked_Flag = 'Y'
      AND L.ship_from_org_id = IA.organization_id 
      AND L.inventory_item_id = IA.inventory_item_id 
      AND L.inventory_item_id = MSI.inventory_item_id
      AND MP.organization_id = MSI.organization_id
      AND MSI.organization_id = HOU.organization_id
      AND TRUNC(L.schedule_ship_date) <=
          TRUNC(NVL(MSI.end_date_active,SYSDATE+g_seasonal_max_days))
      AND L.line_id = LA.line_id
      AND H.order_type_id = OTT.transaction_type_id
      AND NVL(OTT.attribute15,'X') <> 'SEASONAL'
      AND NVL(LA.line_modifier,'X') <> 'LARGE'
--      AND MIC.inventory_item_id = MSI.inventory_item_id
--      AND MIC.organization_id =  MP.organization_id
--      AND MCS.default_category_id = MIC.category_id
--      AND MCS.category_set_id = MIC.category_set_id
--      AND NVL(MCS.category_set_name,'X') = 'RMS Location Traits Attributes'
      AND NVL(L.ordered_quantity,0) >
          NVL(( SELECT
                   SUM(MR.primary_reservation_quantity)
                FROM
                   mtl_reservations MR
                   ,mfg_lookups ML
                   ,mtl_sales_orders MSO
                WHERE
                       MR.demand_source_header_id = MSO.sales_order_id
                   AND to_number(MSO.segment1) = H.order_number
                   AND MR.demand_source_line_id = L.line_id
                   AND MR.organization_id = L.ship_from_org_id
                   AND MR.inventory_item_id = L.inventory_item_id
                   AND MR.demand_source_type_id = ML.lookup_code
                   AND NVL(ML.lookup_type,'X') = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
                   AND ML.lookup_code in (2,9)
              ),0);

   record_future_lines cursor_future_lines%ROWTYPE;

BEGIN

   -- first open the flat file for write.
   IF NOT UTL_FILE.IS_OPEN(l_utl_filetype) THEN
      l_utl_filetype := UTL_FILE.FOPEN( p_file_location, p_future_file, 'W' );
   END IF;

   -- then read through each of the order lines.
   -- ignore items not replenished.
   -- reduce ordered quantity by reserved quantity
   -- write the flat file..
   IF NOT cursor_future_lines%ISOPEN THEN
      OPEN cursor_future_lines;
   END IF;

   LOOP
      FETCH cursor_future_lines INTO record_future_lines;
      EXIT WHEN cursor_future_lines%NOTFOUND;
      IF is_replenished(record_future_lines.od_replen_type_cd
                        ,record_future_lines.od_replen_sub_type_cd) THEN

         SELECT
            SUM(MR.primary_reservation_quantity)
         INTO
            ln_primary_reserved_quantity
         FROM
            mtl_reservations MR
            ,mfg_lookups ML
            ,mtl_sales_orders MSO
         WHERE
                MR.demand_source_header_id  = MSO.sales_order_id
            AND to_number(MSO.segment1) = record_future_lines.order_number
            AND MR.demand_source_line_id = record_future_lines.line_id
            AND MR.organization_id = record_future_lines.ship_from_org_id
            AND MR.inventory_item_id = record_future_lines.inventory_item_id
            AND MR.demand_source_type_id  = ML.lookup_code
            AND ML.lookup_type = 'MTL_SUPPLY_DEMAND_SOURCE_TYPE'
            AND ML.lookup_code in (2,9);

         ln_ordered_quantity := NVL(record_future_lines.ordered_quantity,0) -
                               NVL(ln_primary_reserved_quantity,0);

         l_record :=
               RPAD(record_future_lines.legacy_org,4,'0')   --location
            || RPAD(record_future_lines.sku,20,' ')     --item
            || TRUNC(ln_ordered_quantity);

         UTL_FILE.put_line (l_utl_filetype, l_record);
      END IF;

   END LOOP;

   IF cursor_future_lines%ISOPEN THEN
      CLOSE cursor_future_lines;
   END IF;
   IF UTL_FILE.IS_OPEN(l_utl_filetype) THEN
      UTL_FILE.FCLOSE_ALL;
   END IF;

EXCEPTION
   WHEN UTL_FILE.INVALID_FILEHANDLE THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_I1315_INVALID_FILEHANDLE');
      x_error_code := 'XX_OM_I1315_INVALID_FILEHANDLE';
      x_error_status := FND_MESSAGE.GET;
      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    -5;
      exception_object_type.p_entity_ref        :=    'File_Name';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

   WHEN UTL_FILE.WRITE_ERROR THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_I1315_WRITE_ERROR');
      x_error_code := 'XX_OM_I1315_WRITE_ERROR';
      x_error_status := FND_MESSAGE.GET;
      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    -6;
      exception_object_type.p_entity_ref        :=    'File_Name';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

   WHEN UTL_FILE.INVALID_PATH THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_I1315_INVALID_PATH');
      x_error_code := 'XX_OM_I1315_INVALID_PATH';
      x_error_status := FND_MESSAGE.GET;
      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    -7;
      exception_object_type.p_entity_ref        :=    'File_Path';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

   WHEN UTL_FILE.INTERNAL_ERROR THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_I1315_INTERNAL_ERROR');
      x_error_code := 'XX_OM_I1315_INTERNAL_ERROR';
      x_error_status := FND_MESSAGE.GET;
      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    -8;
      exception_object_type.p_entity_ref        :=    'File_Name';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

   WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME ('xxom','XX_OM_65100_UNEXPECTED_ERROR');
      x_error_code := 'XX_OM_65100_UNEXPECTED_ERROR';
      x_error_status := FND_MESSAGE.GET;

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      exception_object_type.p_exception_header  :=    G_exception_header;
      exception_object_type.p_track_code        :=    G_track_code;
      exception_object_type.p_solution_domain   :=    G_solution_domain;
      exception_object_type.p_function          :=    lc_function;
      exception_object_type.p_error_code        :=    x_error_code;
      exception_object_type.p_error_description :=    x_error_status;
      exception_object_type.p_entity_ref_id     :=    SQLCODE;
      exception_object_type.p_entity_ref        :=    'SQLERROR';

      XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(
         exception_object_type
         ,lc_error_message
         ,lc_error_code
         );

END Demand_Extract_Future;


-- +======================================================================+
-- | Name: is_replenished                                                 |
-- | Description: This function decides if the item is replenishable based|
-- |              on the item attributes defined.                         |
-- |                                                                      |
-- | Parameters:                                                          |
-- |              p_replen_type                                           |
-- |              p_replen_subtype                                        |
-- +======================================================================+
FUNCTION is_replenished (
      p_replen_type     IN  mtl_categories_b.segment7%TYPE
      ,p_replen_subtype IN  mtl_categories_b.segment6%TYPE
      ) RETURN BOOLEAN

IS
  replenished BOOLEAN := FALSE;
BEGIN

   IF p_replen_type = 'A' AND p_replen_subtype = 'A' THEN
      replenished := TRUE;
   ELSIF p_replen_type = 'M' AND p_replen_subtype = 'M' THEN
      replenished := TRUE;
   ELSIF p_replen_type = 'N' AND p_replen_subtype = 'I' THEN
      replenished := TRUE;
   ELSIF p_replen_type = 'N' AND p_replen_subtype = 'Q' THEN
      replenished := TRUE;
   ELSIF p_replen_type = 'N' AND p_replen_subtype = 'B' THEN
      replenished := TRUE;
   ELSIF p_replen_type = 'R' AND p_replen_subtype = 'R' THEN
      replenished := TRUE;
   ELSIF p_replen_type = 'S' AND p_replen_subtype = 'S' THEN
      replenished := TRUE;
   ELSIF p_replen_type = 'NA' AND p_replen_subtype = 'NA' THEN
      replenished := TRUE;
   ELSE
      replenished := FALSE;
   END IF;

   RETURN replenished;

END is_replenished;

END XX_OM_DMDEXTLEG_PKG;

/
SHOW ERRORS

