SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_ROADNET_TO_EBS_PKG
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization           |
-- +=======================================================================+
-- | Name  : XX_OM_ROADNET_TO_EBS_PKG                                      |
-- | RICE ID : I1014_RoadnetToEBS                                          |
-- | Description      : Package Body containing Updation of route          |
-- |                    number and stop number in EBS which is sent by     |
-- |                    Roadnet System.                                    |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version    Date          Author           Remarks                      |
-- |=======    ==========    =============    ========================     |
-- |DRAFT 1A   25-Apr-2007   Shashi Kumar.    Initial Draft version        |
-- |                                                                       |
-- |1.0        18-jun-2007   Shashi Kumar.    Base Lined After Testing     |
-- |                                                                       |
-- |1.1        20-jul-2007   Shashi Kumar.    Altered the code to include  |
-- |                                          the custom attribute table   |
-- |                                          for deliveries.              |
-- +=======================================================================+
AS

-- Global Exception variables --

g_entity_ref        VARCHAR2(1000) := 'DELIVERY_ID';
g_entity_ref_id     NUMBER;

-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Description: This procedure will be responsible to store all      |
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  p_error_code , p_error_description                   |
-- |                                                                   |
-- | Returns :    None                                                 |
-- +===================================================================+

PROCEDURE log_exceptions(
                         p_error_code        IN  VARCHAR2
                        ,p_error_description IN  VARCHAR2
                        )

AS

-- Variables holding the values from the global exception framework package
----------------------------------------------------------------------------
lc_errbuf                   VARCHAR2(1000);
x_retcode                   VARCHAR2(40);

BEGIN

   g_exception.p_error_code        := p_error_code;
   g_exception.p_error_description := p_error_description;
   g_exception.p_entity_ref        := g_entity_ref;
   g_exception.p_entity_ref_id     := g_entity_ref_id;

   BEGIN
      xx_om_global_exception_pkg.insert_exception(g_exception
                                                 ,lc_errbuf
                                                 ,x_retcode
                                                 );
   END;

END log_exceptions;

-- +===================================================================+
-- | Name  : import_route                                              |
-- |                                                                   |
-- | Description: This Procedure is used to update the route and       |
-- |              delivery details in EBS.                             |
-- |                                                                   |
-- | Parameters:  p_delivery_tbl                                       |
-- |                                                                   |
-- | Returns :    None                                                 |
-- |                                                                   |
-- +===================================================================+

PROCEDURE import_route(
                       p_delivery_tbl IN  XX_OM_DELIVERY_TBL
                      ) IS

   GC_USER_NAME   CONSTANT VARCHAR2(100) := 'SHASHIK';
   GC_RESP_NAME   CONSTANT VARCHAR2(240) := 'OD US Order Management Super User';

   GN_USER_ID              NUMBER;
   GN_RESP_ID              NUMBER;
   GN_RESP_APP_ID          NUMBER;
   GN_ORG_ID               NUMBER;

   lr_delivery_info        WSH_NEW_DELIVERIES_PVT.delivery_rec_type;
   lt_delivery_tbl         XX_OM_DELIVERY_TBL;
   lc_processs_dff         VARCHAR2(240);
   lc_route_number         VARCHAR2(240);
   lc_init_msg_list        VARCHAR2(4000);
   lc_return_status        VARCHAR2(10);
   ln_msg_count            NUMBER;
   lc_msg_data             VARCHAR2(4000);
   lr_trip_info            WSH_TRIPS_PUB.TRIP_PUB_REC_TYPE;
   p_trip_name             WSH_TRIPS.name%TYPE;
   p_trip_id               WSH_TRIPS.trip_id%TYPE;
   ln_dlvy_id              WSH_NEW_DELIVERIES.delivery_id%TYPE;
   ln_trip_id              WSH_TRIPS.trip_id%TYPE;
   lc_process_dff          VARCHAR2(240);
   lc_trip_name            WSH_TRIPS.name%TYPE;
   p_rowid                 ROWID;
   ln_delivery_number      WSH_NEW_DELIVERIES.name%TYPE;
   p_error_code            VARCHAR2(100);
   p_error_description     VARCHAR2(4000);
   lc_errbuf               VARCHAR2(4000);

   CURSOR  lcu_user IS
   SELECT  FU.user_id
   FROM    fnd_user FU
   WHERE   FU.user_name = GC_USER_NAME;

   CURSOR  lcu_resp IS
   SELECT  FRV.responsibility_id,
           FRV.application_id
   FROM    fnd_responsibility_vl FRV
   WHERE   FRV.responsibility_name = GC_RESP_NAME;

   CURSOR  lcu_procees_dff(ln_delivery_id NUMBER) IS
   SELECT  XWDA.od_internal_delivery_status
   FROM    xx_wsh_delivery_att_all XWDA
   WHERE   XWDA.delivery_id = ln_delivery_id;

   CURSOR  lcu_attr(ln_del_id NUMBER) IS
   SELECT  XWDA.delivery_id,
           XWDA.od_internal_delivery_status,
           XWDA.redelivery_flag,
           XWDA.del_backtoback_ind,
           XWDA.no_of_shiplabels,
           XWDA.new_sch_ship_date,
           XWDA.new_sch_arr_date,
           XWDA.actual_deliverd_date,
           XWDA.new_del_date_from_time,
           XWDA.new_del_date_to_time,
           XWDA.delivery_cancelled_ind,
           XWDA.delivery_trans_ind,
           XWDA.pod_exceptions_comments,
           XWDA.retransmit_pick_ticket,
           XWDA.payment_subtype_cod_ind,
           XWDA.del_to_post_office_ind,
           XWDA.creation_date,
           XWDA.created_by,
           XWDA.last_update_date,
           XWDA.last_updated_by,
           XWDA.last_update_login
   FROM    xx_wsh_delivery_att_all XWDA
   WHERE   XWDA.delivery_id = ln_del_id;

   CURSOR  lcu_delivery_info(ln_delivery_id NUMBER) IS
   SELECT  WND.delivery_id
          ,WND.NAME
          ,WND.planned_flag
          ,WND.status_code
          ,WND.delivery_type
          ,WND.loading_sequence
          ,WND.loading_order_flag
          ,WND.initial_pickup_date
          ,WND.initial_pickup_location_id
          ,WND.organization_id
          ,WND.ultimate_dropoff_location_id
          ,WND.ultimate_dropoff_date
          ,WND.customer_id
          ,WND.intmed_ship_to_location_id
          ,WND.pooled_ship_to_location_id
          ,WND.carrier_id
          ,WND.ship_method_code
          ,WND.freight_terms_code
          ,WND.fob_code
          ,WND.fob_location_id
          ,WND.waybill
          ,WND.dock_code
          ,WND.acceptance_flag
          ,WND.accepted_by
          ,WND.accepted_date
          ,WND.acknowledged_by
          ,WND.confirmed_by
          ,WND.confirm_date
          ,WND.asn_date_sent
          ,WND.asn_status_code
          ,WND.asn_seq_number
          ,WND.gross_weight
          ,WND.net_weight
          ,WND.weight_uom_code
          ,WND.volume
          ,WND.volume_uom_code
          ,WND.additional_shipment_info
          ,WND.currency_code
          ,WND.attribute_category
          ,WND.attribute1
          ,WND.attribute2
          ,WND.attribute3
          ,WND.attribute4
          ,WND.attribute5
          ,WND.attribute6
          ,WND.attribute7
          ,WND.attribute8
          ,WND.attribute9
          ,WND.attribute10
          ,WND.attribute11
          ,WND.attribute12
          ,WND.attribute13
          ,WND.attribute14
          ,WND.attribute15
          ,WND.tp_attribute_category
          ,WND.tp_attribute1
          ,WND.tp_attribute2
          ,WND.tp_attribute3
          ,WND.tp_attribute4
          ,WND.tp_attribute5
          ,WND.tp_attribute6
          ,WND.tp_attribute7
          ,WND.tp_attribute8
          ,WND.tp_attribute9
          ,WND.tp_attribute10
          ,WND.tp_attribute11
          ,WND.tp_attribute12
          ,WND.tp_attribute13
          ,WND.tp_attribute14
          ,WND.tp_attribute15
          ,WND.global_attribute_category
          ,WND.global_attribute1
          ,WND.global_attribute2
          ,WND.global_attribute3
          ,WND.global_attribute4
          ,WND.global_attribute5
          ,WND.global_attribute6
          ,WND.global_attribute7
          ,WND.global_attribute8
          ,WND.global_attribute9
          ,WND.global_attribute10
          ,WND.global_attribute11
          ,WND.global_attribute12
          ,WND.global_attribute13
          ,WND.global_attribute14
          ,WND.global_attribute15
          ,WND.global_attribute16
          ,WND.global_attribute17
          ,WND.global_attribute18
          ,WND.global_attribute19
          ,WND.global_attribute20
          ,WND.last_update_date
          ,WND.last_updated_by
          ,WND.last_update_login
          ,WND.program_application_id
          ,WND.program_id
          ,WND.program_update_date
          ,WND.request_id
          ,WND.number_of_lpn
          ,WND.cod_amount
          ,WND.cod_currency_code
          ,WND.cod_remit_to
          ,WND.cod_charge_paid_by
          ,WND.problem_contact_reference
          ,WND.port_of_loading
          ,WND.port_of_discharge
          ,WND.ftz_number
          ,WND.routed_export_txn
          ,WND.entry_number
          ,WND.routing_instructions
          ,WND.in_bond_code
          ,WND.shipping_marks
          ,WND.service_level
          ,WND.mode_of_transport
          ,WND.assigned_to_fte_trips
          ,WND.auto_sc_exclude_flag
          ,WND.auto_ap_exclude_flag
          ,WND.vendor_id
          ,WND.party_id
          ,WND.routing_response_id
          ,WND.rcv_shipment_header_id
          ,WND.asn_shipment_header_id
          ,WND.shipping_control
          ,WND.tp_delivery_number
          ,WND.earliest_pickup_date
          ,WND.latest_pickup_date
          ,WND.earliest_dropoff_date
          ,WND.latest_dropoff_date
          ,WND.tp_plan_name
          ,WND.hash_value
          ,WND.hash_string
          ,WND.delivered_date
          ,WND.reason_of_transport
          ,WND.description
   FROM   wsh_new_deliveries WND
   WHERE  WND.delivery_id = ln_delivery_id;

   CURSOR lcu_trip(ln_delivery_id NUMBER) IS
   SELECT WT.name,
          WT.trip_id,
          WT.attribute1
   FROM   wsh_new_deliveries WND,
          wsh_delivery_legs  WDL,
          wsh_trip_stops     WTS,
          wsh_trip_stops     WTS1,
          wsh_trips          WT
   WHERE  WDL.delivery_id  = WND.delivery_id
   AND    WTS.stop_id      = WDL.pick_up_stop_id
   AND    WTS1.stop_id     = WDL.drop_off_stop_id
   AND    WTS1.trip_id     = WT.trip_id
   AND    WND.delivery_id  = ln_delivery_id;

BEGIN

   g_entity_ref_id     := 0;

   -- Fetching the user id --

   FOR cur_user in lcu_user LOOP
      GN_USER_ID := cur_user.user_id;
   END LOOP;

   -- Fetching the Responsibility and responsibility application id --

   FOR cur_resp in lcu_resp LOOP

      GN_RESP_ID     := cur_resp.responsibility_id;
      GN_RESP_APP_ID := cur_resp.application_id;

   END LOOP;

   IF (GN_USER_ID IS NULL) OR (GN_RESP_ID IS NULL) OR (GN_RESP_APP_ID IS NULL) THEN

      g_entity_ref_id      := 0;
      p_error_code         := 'XX_OM_65100_USERRESP_ID_NULL';
      p_error_description  := fnd_message.get_string('XXOM','XX_OM_65100_USERRESP_ID_NULL');
      log_exceptions(p_error_code,
                     p_error_description
                    );

   ELSE

      FND_GLOBAL.APPS_INITIALIZE(GN_USER_ID, GN_RESP_ID, GN_RESP_APP_ID);

      lt_delivery_tbl    := p_delivery_tbl;
      lc_process_dff     := NULL;
      ln_delivery_number := NULL;

      IF lt_delivery_tbl.COUNT > 0 THEN

         FOR i IN lt_delivery_tbl.FIRST..lt_delivery_tbl.LAST LOOP

            ln_delivery_number := lt_delivery_tbl(i).delivery_number;

            IF ln_delivery_number IS NULL THEN

               g_entity_ref_id := 0;
               p_error_code   := 'XX_OM_65101_DELIVERY_NO_NULL';
               p_error_description     := fnd_message.get_string('XXOM','XX_OM_65101_DELIVERY_NO_NULL');
               log_exceptions(p_error_code,
                              p_error_description
                             );

            ELSE

               BEGIN

                  SELECT wnd.delivery_id
                  INTO   ln_dlvy_id
                  FROM   wsh_new_deliveries wnd
                  WHERE  wnd.name = ln_delivery_number;

               EXCEPTION
                  WHEN OTHERS THEN

                  g_entity_ref        := 'DELIVERY_NUMBER';
                  g_entity_ref_id     := ln_delivery_number;

                  FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                  FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                  FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                  p_error_description:= FND_MESSAGE.GET;
                  p_error_code       := 'ODP_OM_UNEXPECTED_ERR';

                  log_exceptions(p_error_code,
                                 p_error_description
                                );
               END;

            END IF;

            IF lt_delivery_tbl(i).route_number IS NULL THEN

               g_entity_ref    := 'DELIVERY_NUMBER';
               g_entity_ref_id := ln_delivery_number;
               p_error_code    := 'XX_OM_65102_ROUTE_NO_NULL';
               p_error_description     := fnd_message.get_string('XXOM','XX_OM_65102_ROUTE_NO_NULL');
               log_exceptions(p_error_code,
                              p_error_description
                             );

            END IF;

            IF lt_delivery_tbl(i).stop_number IS NULL THEN

               g_entity_ref_id := ln_delivery_number;
               p_error_code    := 'XX_OM_65103_STOP_NO_NULL';
               p_error_description     := fnd_message.get_string('XXOM','XX_OM_65103_STOP_NO_NULL');

               log_exceptions(p_error_code,
                              p_error_description
                             );

            END IF;

            IF lt_delivery_tbl(i).user_field3 IS NULL THEN

               g_entity_ref_id := ln_delivery_number;
               p_error_code   := 'XX_OM_65104_USER_FIELD_NULL';
               p_error_description     := fnd_message.get_string('XXOM','XX_OM_65104_USER_FIELD_NULL');

               log_exceptions(p_error_code,
                              p_error_description
                             );

            END IF;

            IF lt_delivery_tbl(i).regionid IS NULL THEN

               g_entity_ref_id := ln_delivery_number;
               p_error_code   := 'XX_OM_65105_REGION_ID_NULL';
               p_error_description     := fnd_message.get_string('XXOM','XX_OM_65105_REGION_ID_NULL');

               log_exceptions(p_error_code,
                              p_error_description
                              );

            END IF;

            IF lt_delivery_tbl(i).delivery_date IS NULL THEN

               g_entity_ref_id := ln_delivery_number;
               p_error_code   := 'XX_OM_65106_REGION_ID_NULL';
               p_error_description     := fnd_message.get_string('XXOM','XX_OM_65106_REGION_ID_NULL');

               log_exceptions(p_error_code,
                              p_error_description
                             );

            END IF;

            -- Check if the process status DFF is 'ROADNET_IMPORT_COMPLETE'
            FOR cur_procees_dff IN lcu_procees_dff(ln_delivery_number) LOOP
               lc_process_dff := cur_procees_dff.od_internal_delivery_status;
            END LOOP;

            lt_delivery_tbl(i).user_field3 := 'Test-E';  -- To be removed once the userifeld3 mapping is given and to be mapped to the original column

            IF lc_process_dff = 'ROADNET_IMPORT_COMPLETE' AND SUBSTR(lt_delivery_tbl(i).user_field3,-2) = '-E' THEN

               -- Get the route# from the EBS system for the delivery
               FOR cur_trip IN lcu_trip(ln_dlvy_id) LOOP

                  ln_trip_id         := cur_trip.trip_id;
                  lc_trip_name       := cur_trip.name;
                  lc_route_number    := NVL(cur_trip.attribute1,-999);      -- If value is NULL then NVL -999

               END LOOP;

               -- Check if the route # has changed from the Roadnet
               IF lc_route_number != lt_delivery_tbl(i).route_number THEN

                  FOR cur_delivery_info IN lcu_delivery_info(ln_dlvy_id) LOOP

                     lr_delivery_info.delivery_id                   :=   cur_delivery_info.delivery_id;
                     lr_delivery_info.name                          :=   cur_delivery_info.name;
                     lr_delivery_info.planned_flag                  :=   cur_delivery_info.planned_flag;
                     lr_delivery_info.status_code                   :=   cur_delivery_info.status_code;
                     lr_delivery_info.delivery_type                 :=   cur_delivery_info.delivery_type;
                     lr_delivery_info.loading_sequence              :=   cur_delivery_info.loading_sequence;
                     lr_delivery_info.loading_order_flag            :=   cur_delivery_info.loading_order_flag;
                     lr_delivery_info.initial_pickup_date           :=   cur_delivery_info.initial_pickup_date;
                     lr_delivery_info.initial_pickup_location_id    :=   cur_delivery_info.initial_pickup_location_id;
                     lr_delivery_info.organization_id               :=   cur_delivery_info.organization_id;
                     lr_delivery_info.ultimate_dropoff_location_id  :=   cur_delivery_info.ultimate_dropoff_location_id;
                     lr_delivery_info.ultimate_dropoff_date         :=   cur_delivery_info.ultimate_dropoff_date;
                     lr_delivery_info.customer_id                   :=   cur_delivery_info.customer_id;
                     lr_delivery_info.intmed_ship_to_location_id    :=   cur_delivery_info.intmed_ship_to_location_id;
                     lr_delivery_info.pooled_ship_to_location_id    :=   cur_delivery_info.pooled_ship_to_location_id;
                     lr_delivery_info.carrier_id                    :=   cur_delivery_info.carrier_id;
                     lr_delivery_info.ship_method_code              :=   cur_delivery_info.ship_method_code;
                     lr_delivery_info.freight_terms_code            :=   cur_delivery_info.freight_terms_code;
                     lr_delivery_info.fob_code                      :=   cur_delivery_info.fob_code;
                     lr_delivery_info.fob_location_id               :=   cur_delivery_info.fob_location_id;
                     lr_delivery_info.waybill                       :=   cur_delivery_info.waybill;
                     lr_delivery_info.dock_code                     :=   cur_delivery_info.dock_code;
                     lr_delivery_info.acceptance_flag               :=   cur_delivery_info.acceptance_flag;
                     lr_delivery_info.accepted_by                   :=   cur_delivery_info.accepted_by;
                     lr_delivery_info.accepted_date                 :=   cur_delivery_info.accepted_date;
                     lr_delivery_info.acknowledged_by               :=   cur_delivery_info.acknowledged_by;
                     lr_delivery_info.confirmed_by                  :=   cur_delivery_info.confirmed_by;
                     lr_delivery_info.confirm_date                  :=   cur_delivery_info.confirm_date;
                     lr_delivery_info.asn_date_sent                 :=   cur_delivery_info.asn_date_sent;
                     lr_delivery_info.asn_status_code               :=   cur_delivery_info.asn_status_code;
                     lr_delivery_info.asn_seq_number                :=   cur_delivery_info.asn_seq_number;
                     lr_delivery_info.gross_weight                  :=   cur_delivery_info.gross_weight;
                     lr_delivery_info.net_weight                    :=   cur_delivery_info.net_weight;
                     lr_delivery_info.weight_uom_code               :=   cur_delivery_info.weight_uom_code;
                     lr_delivery_info.volume                        :=   cur_delivery_info.volume;
                     lr_delivery_info.volume_uom_code               :=   cur_delivery_info.volume_uom_code;
                     lr_delivery_info.additional_shipment_info      :=   cur_delivery_info.additional_shipment_info;
                     lr_delivery_info.currency_code                 :=   cur_delivery_info.currency_code;
                     lr_delivery_info.attribute_category            :=   cur_delivery_info.attribute_category;
                     lr_delivery_info.attribute1                    :=   cur_delivery_info.attribute1;
                     lr_delivery_info.attribute2                    :=   cur_delivery_info.attribute2;
                     lr_delivery_info.attribute3                    :=   cur_delivery_info.attribute3;
                     lr_delivery_info.attribute4                    :=   cur_delivery_info.attribute4;
                     lr_delivery_info.attribute5                    :=   cur_delivery_info.attribute5;
                     lr_delivery_info.attribute6                    :=   cur_delivery_info.attribute6;
                     lr_delivery_info.attribute7                    :=   cur_delivery_info.attribute7;
                     lr_delivery_info.attribute8                    :=   cur_delivery_info.attribute8;
                     lr_delivery_info.attribute9                    :=   cur_delivery_info.attribute9;
                     lr_delivery_info.attribute10                   :=   cur_delivery_info.attribute10;
                     lr_delivery_info.attribute11                   :=   cur_delivery_info.attribute11;
                     lr_delivery_info.attribute12                   :=   cur_delivery_info.attribute12;
                     lr_delivery_info.attribute13                   :=   cur_delivery_info.attribute13;
                     lr_delivery_info.attribute14                   :=   cur_delivery_info.attribute14;
                     lr_delivery_info.attribute15                   :=   cur_delivery_info.attribute15;
                     lr_delivery_info.tp_attribute_category         :=   cur_delivery_info.tp_attribute_category;
                     lr_delivery_info.tp_attribute1                 :=   cur_delivery_info.tp_attribute1;
                     lr_delivery_info.tp_attribute2                 :=   cur_delivery_info.tp_attribute2;
                     lr_delivery_info.tp_attribute3                 :=   cur_delivery_info.tp_attribute3;
                     lr_delivery_info.tp_attribute4                 :=   cur_delivery_info.tp_attribute4;
                     lr_delivery_info.tp_attribute5                 :=   cur_delivery_info.tp_attribute5;
                     lr_delivery_info.tp_attribute6                 :=   cur_delivery_info.tp_attribute6;
                     lr_delivery_info.tp_attribute7                 :=   cur_delivery_info.tp_attribute7;
                     lr_delivery_info.tp_attribute8                 :=   cur_delivery_info.tp_attribute8;
                     lr_delivery_info.tp_attribute9                 :=   cur_delivery_info.tp_attribute9;
                     lr_delivery_info.tp_attribute10                :=   cur_delivery_info.tp_attribute10;
                     lr_delivery_info.tp_attribute11                :=   cur_delivery_info.tp_attribute11;
                     lr_delivery_info.tp_attribute12                :=   cur_delivery_info.tp_attribute12;
                     lr_delivery_info.tp_attribute13                :=   cur_delivery_info.tp_attribute13;
                     lr_delivery_info.tp_attribute14                :=   cur_delivery_info.tp_attribute14;
                     lr_delivery_info.tp_attribute15                :=   cur_delivery_info.tp_attribute15;
                     lr_delivery_info.global_attribute_category     :=   cur_delivery_info.global_attribute_category;
                     lr_delivery_info.global_attribute1             :=   cur_delivery_info.global_attribute1;
                     lr_delivery_info.global_attribute2             :=   cur_delivery_info.global_attribute2;
                     lr_delivery_info.global_attribute3             :=   cur_delivery_info.global_attribute3;
                     lr_delivery_info.global_attribute4             :=   cur_delivery_info.global_attribute4;
                     lr_delivery_info.global_attribute5             :=   cur_delivery_info.global_attribute5;
                     lr_delivery_info.global_attribute6             :=   cur_delivery_info.global_attribute6;
                     lr_delivery_info.global_attribute7             :=   cur_delivery_info.global_attribute7;
                     lr_delivery_info.global_attribute8             :=   cur_delivery_info.global_attribute8;
                     lr_delivery_info.global_attribute9             :=   cur_delivery_info.global_attribute9;
                     lr_delivery_info.global_attribute10            :=   cur_delivery_info.global_attribute10;
                     lr_delivery_info.global_attribute11            :=   cur_delivery_info.global_attribute11;
                     lr_delivery_info.global_attribute12            :=   cur_delivery_info.global_attribute12;
                     lr_delivery_info.global_attribute13            :=   cur_delivery_info.global_attribute13;
                     lr_delivery_info.global_attribute14            :=   cur_delivery_info.global_attribute14;
                     lr_delivery_info.global_attribute15            :=   cur_delivery_info.global_attribute15;
                     lr_delivery_info.global_attribute16            :=   cur_delivery_info.global_attribute16;
                     lr_delivery_info.global_attribute17            :=   cur_delivery_info.global_attribute17;
                     lr_delivery_info.global_attribute18            :=   cur_delivery_info.global_attribute18;
                     lr_delivery_info.global_attribute19            :=   cur_delivery_info.global_attribute19;
                     lr_delivery_info.global_attribute20            :=   cur_delivery_info.global_attribute20;
                     lr_delivery_info.last_update_date              :=   cur_delivery_info.last_update_date;
                     lr_delivery_info.last_updated_by               :=   cur_delivery_info.last_updated_by;
                     lr_delivery_info.last_update_login             :=   cur_delivery_info.last_update_login;
                     lr_delivery_info.program_application_id        :=   cur_delivery_info.program_application_id;
                     lr_delivery_info.program_id                    :=   cur_delivery_info.program_id;
                     lr_delivery_info.program_update_date           :=   cur_delivery_info.program_update_date;
                     lr_delivery_info.request_id                    :=   cur_delivery_info.request_id;
                     lr_delivery_info.number_of_lpn                 :=   cur_delivery_info.number_of_lpn;
                     lr_delivery_info.cod_amount                    :=   cur_delivery_info.cod_amount;
                     lr_delivery_info.cod_currency_code             :=   cur_delivery_info.cod_currency_code;
                     lr_delivery_info.cod_remit_to                  :=   cur_delivery_info.cod_remit_to;
                     lr_delivery_info.cod_charge_paid_by            :=   cur_delivery_info.cod_charge_paid_by;
                     lr_delivery_info.problem_contact_reference     :=   cur_delivery_info.problem_contact_reference;
                     lr_delivery_info.port_of_loading               :=   cur_delivery_info.port_of_loading;
                     lr_delivery_info.port_of_discharge             :=   cur_delivery_info.port_of_discharge;
                     lr_delivery_info.ftz_number                    :=   cur_delivery_info.ftz_number;
                     lr_delivery_info.routed_export_txn             :=   cur_delivery_info.routed_export_txn;
                     lr_delivery_info.entry_number                  :=   cur_delivery_info.entry_number;
                     lr_delivery_info.routing_instructions          :=   cur_delivery_info.routing_instructions;
                     lr_delivery_info.in_bond_code                  :=   cur_delivery_info.in_bond_code;
                     lr_delivery_info.shipping_marks                :=   cur_delivery_info.shipping_marks;
                     lr_delivery_info.service_level                 :=   cur_delivery_info.service_level;
                     lr_delivery_info.mode_of_transport             :=   cur_delivery_info.mode_of_transport;
                     lr_delivery_info.assigned_to_fte_trips         :=   cur_delivery_info.assigned_to_fte_trips;
                     lr_delivery_info.auto_sc_exclude_flag          :=   cur_delivery_info.auto_sc_exclude_flag;
                     lr_delivery_info.auto_ap_exclude_flag          :=   cur_delivery_info.auto_ap_exclude_flag;
                     lr_delivery_info.vendor_id                     :=   cur_delivery_info.vendor_id;
                     lr_delivery_info.party_id                      :=   cur_delivery_info.party_id;
                     lr_delivery_info.routing_response_id           :=   cur_delivery_info.routing_response_id;
                     lr_delivery_info.rcv_shipment_header_id        :=   cur_delivery_info.rcv_shipment_header_id;
                     lr_delivery_info.asn_shipment_header_id        :=   cur_delivery_info.asn_shipment_header_id;
                     lr_delivery_info.shipping_control              :=   cur_delivery_info.shipping_control;
                     lr_delivery_info.tp_delivery_number            :=   cur_delivery_info.tp_delivery_number;
                     lr_delivery_info.earliest_pickup_date          :=   cur_delivery_info.earliest_pickup_date;
                     lr_delivery_info.latest_pickup_date            :=   cur_delivery_info.latest_pickup_date;
                     lr_delivery_info.earliest_dropoff_date         :=   lt_delivery_tbl(i).delivery_date;
                     lr_delivery_info.latest_dropoff_date           :=   cur_delivery_info.latest_dropoff_date;
                     lr_delivery_info.tp_plan_name                  :=   cur_delivery_info.tp_plan_name;
                     lr_delivery_info.hash_value                    :=   cur_delivery_info.hash_value;
                     lr_delivery_info.hash_string                   :=   cur_delivery_info.hash_string;
                     lr_delivery_info.delivered_date                :=   cur_delivery_info.delivered_date;
                     lr_delivery_info.reason_of_transport           :=   cur_delivery_info.reason_of_transport;
                     lr_delivery_info.description                   :=   cur_delivery_info.description;

                     -- Call the API wsh_new_deliveries_pvt to update the delivery information
                     wsh_new_deliveries_pvt.update_delivery
                     (
                      p_rowid,
                      lr_delivery_info,
                      lc_return_status
                     );

                     COMMIT;

                     -- Call the API WSH_TRIPS_PUB to update the delivery information

                     IF lc_return_status = 'S' THEN

                        lr_trip_info.trip_id    := ln_trip_id;
                        lr_trip_info.name       := lc_trip_name;
                        lr_trip_info.attribute1 := lt_delivery_tbl(i).route_number;
                        lr_trip_info.attribute4 := lt_delivery_tbl(i).stop_number;

                        WSH_TRIPS_PUB.CREATE_UPDATE_TRIP(
                                                         1.0,
                                                         lc_init_msg_list,
                                                         lc_return_status,
                                                         ln_msg_count,
                                                         lc_msg_data,
                                                         'UPDATE',
                                                         lr_trip_info,
                                                         lc_trip_name,
                                                         p_trip_id,
                                                         p_trip_name
                                                        );

                        COMMIT;

                        IF  lc_return_status = 'S' THEN

                           BEGIN

                              FOR cur_attr IN lcu_attr(ln_dlvy_id) LOOP

                                 lt_delivery_attributes.delivery_id                  := ln_dlvy_id;
                                 lt_delivery_attributes.od_internal_delivery_status  := 'ROADNET_ROUTING_COMPLETE';
                                 lt_delivery_attributes.redelivery_flag              := cur_attr.redelivery_flag;
                                 lt_delivery_attributes.del_backtoback_ind           := cur_attr.del_backtoback_ind;
                                 lt_delivery_attributes.no_of_shiplabels             := cur_attr.no_of_shiplabels;
                                 lt_delivery_attributes.new_sch_ship_date            := cur_attr.new_sch_ship_date;
                                 lt_delivery_attributes.new_sch_arr_date             := cur_attr.new_sch_arr_date;
                                 lt_delivery_attributes.actual_deliverd_date         := cur_attr.actual_deliverd_date;
                                 lt_delivery_attributes.new_del_date_from_time       := cur_attr.new_del_date_from_time;
                                 lt_delivery_attributes.new_del_date_to_time         := cur_attr.new_del_date_to_time;
                                 lt_delivery_attributes.delivery_cancelled_ind       := cur_attr.delivery_cancelled_ind;
                                 lt_delivery_attributes.delivery_trans_ind           := cur_attr.delivery_trans_ind;
                                 lt_delivery_attributes.pod_exceptions_comments      := cur_attr.pod_exceptions_comments;
                                 lt_delivery_attributes.retransmit_pick_ticket       := cur_attr.retransmit_pick_ticket;
                                 lt_delivery_attributes.payment_subtype_cod_ind      := cur_attr.payment_subtype_cod_ind;
                                 lt_delivery_attributes.del_to_post_office_ind       := cur_attr.del_to_post_office_ind;
                                 lt_delivery_attributes.creation_date                := cur_attr.creation_date;
                                 lt_delivery_attributes.created_by                   := cur_attr.created_by;
                                 lt_delivery_attributes.last_update_date             := SYSDATE;
                                 lt_delivery_attributes.last_updated_by              := GN_USER_ID;
                                 lt_delivery_attributes.last_update_login            := GN_USER_ID;

                                 xx_wsh_delivery_attributes_pkg.update_row(lc_return_status
                                                                          ,lc_errbuf
                                                                          ,lt_delivery_attributes
                                                                          );
                                 COMMIT;

                              END LOOP;

                              /*UPDATE wsh_new_deliveries WND
                              SET    WND.attribute1  = 'ROADNET_ROUTING_COMPLETE'
                              WHERE  WND.delivery_id = ln_dlvy_id;*/

                              UPDATE hr_all_organization_units HAOU
                              SET    HAOU.attribute6  = lt_delivery_tbl(i).regionid
                              WHERE  HAOU.location_id = (SELECT initial_pickup_location_id
                                                         FROM   wsh_new_deliveries WND
                                                         WHERE  WND.delivery_id = ln_dlvy_id
                                                        );
                              COMMIT;

                              EXCEPTION WHEN OTHERS THEN

                                  g_entity_ref        := 'DELIVERY_ID';
                                  g_entity_ref_id     := ln_delivery_number;

                                  FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                                  FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                                  FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                                  p_error_description:= FND_MESSAGE.GET;
                                  p_error_code       := 'ODP_OM_UNEXPECTED_ERR';

                                  log_exceptions(p_error_code,
                                                 p_error_description
                                                );

                           END;

                        ELSE

                           BEGIN

                              FOR cur_attr IN lcu_attr(ln_dlvy_id) LOOP

                                  lt_delivery_attributes.delivery_id                  := ln_dlvy_id;
                                  lt_delivery_attributes.od_internal_delivery_status  := 'ROADNET_ROUTING_FAILED';
                                  lt_delivery_attributes.redelivery_flag              := cur_attr.redelivery_flag;
                                  lt_delivery_attributes.del_backtoback_ind           := cur_attr.del_backtoback_ind;
                                  lt_delivery_attributes.no_of_shiplabels             := cur_attr.no_of_shiplabels;
                                  lt_delivery_attributes.new_sch_ship_date            := cur_attr.new_sch_ship_date;
                                  lt_delivery_attributes.new_sch_arr_date             := cur_attr.new_sch_arr_date;
                                  lt_delivery_attributes.actual_deliverd_date         := cur_attr.actual_deliverd_date;
                                  lt_delivery_attributes.new_del_date_from_time       := cur_attr.new_del_date_from_time;
                                  lt_delivery_attributes.new_del_date_to_time         := cur_attr.new_del_date_to_time;
                                  lt_delivery_attributes.delivery_cancelled_ind       := cur_attr.delivery_cancelled_ind;
                                  lt_delivery_attributes.delivery_trans_ind           := cur_attr.delivery_trans_ind;
                                  lt_delivery_attributes.pod_exceptions_comments      := cur_attr.pod_exceptions_comments;
                                  lt_delivery_attributes.retransmit_pick_ticket       := cur_attr.retransmit_pick_ticket;
                                  lt_delivery_attributes.payment_subtype_cod_ind      := cur_attr.payment_subtype_cod_ind;
                                  lt_delivery_attributes.del_to_post_office_ind       := cur_attr.del_to_post_office_ind;
                                  lt_delivery_attributes.creation_date                := cur_attr.creation_date;
                                  lt_delivery_attributes.created_by                   := cur_attr.created_by;
                                  lt_delivery_attributes.last_update_date             := SYSDATE;
                                  lt_delivery_attributes.last_updated_by              := GN_USER_ID;
                                  lt_delivery_attributes.last_update_login            := GN_USER_ID;

                                  xx_wsh_delivery_attributes_pkg.update_row(lc_return_status
                                                                           ,lc_errbuf
                                                                           ,lt_delivery_attributes
                                                                           );
                                  COMMIT;

                              END LOOP;

                              /*UPDATE wsh_new_deliveries WND
                              SET    WND.attribute1  = 'ROADNET_ROUTING_FAILED'
                              WHERE  WND.delivery_id = ln_dlvy_id;*/ -- Commentd the code

                              EXCEPTION WHEN OTHERS THEN

                                 g_entity_ref        := 'DELIVERY_ID';
                                 g_entity_ref_id     := ln_delivery_number;

                                 FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                                 FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                                 FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                                 p_error_description:= FND_MESSAGE.GET;
                                 p_error_code       := 'ODP_OM_UNEXPECTED_ERR';

                                 log_exceptions(p_error_code,
                                                p_error_description
                                               );

                           END;

                        END IF;

                     ELSE

                        BEGIN

                           FOR cur_attr IN lcu_attr(ln_dlvy_id) LOOP

                               lt_delivery_attributes.delivery_id                  := ln_dlvy_id;
                               lt_delivery_attributes.od_internal_delivery_status  := 'ROADNET_ROUTING_FAILED';
                               lt_delivery_attributes.redelivery_flag              := cur_attr.redelivery_flag;
                               lt_delivery_attributes.del_backtoback_ind           := cur_attr.del_backtoback_ind;
                               lt_delivery_attributes.no_of_shiplabels             := cur_attr.no_of_shiplabels;
                               lt_delivery_attributes.new_sch_ship_date            := cur_attr.new_sch_ship_date;
                               lt_delivery_attributes.new_sch_arr_date             := cur_attr.new_sch_arr_date;
                               lt_delivery_attributes.actual_deliverd_date         := cur_attr.actual_deliverd_date;
                               lt_delivery_attributes.new_del_date_from_time       := cur_attr.new_del_date_from_time;
                               lt_delivery_attributes.new_del_date_to_time         := cur_attr.new_del_date_to_time;
                               lt_delivery_attributes.delivery_cancelled_ind       := cur_attr.delivery_cancelled_ind;
                               lt_delivery_attributes.delivery_trans_ind           := cur_attr.delivery_trans_ind;
                               lt_delivery_attributes.pod_exceptions_comments      := cur_attr.pod_exceptions_comments;
                               lt_delivery_attributes.retransmit_pick_ticket       := cur_attr.retransmit_pick_ticket;
                               lt_delivery_attributes.payment_subtype_cod_ind      := cur_attr.payment_subtype_cod_ind;
                               lt_delivery_attributes.del_to_post_office_ind       := cur_attr.del_to_post_office_ind;
                               lt_delivery_attributes.creation_date                := cur_attr.creation_date;
                               lt_delivery_attributes.created_by                   := cur_attr.created_by;
                               lt_delivery_attributes.last_update_date             := SYSDATE;
                               lt_delivery_attributes.last_updated_by              := GN_USER_ID;
                               lt_delivery_attributes.last_update_login            := GN_USER_ID;

                               xx_wsh_delivery_attributes_pkg.update_row(lc_return_status
                                                                        ,lc_errbuf
                                                                        ,lt_delivery_attributes
                                                                        );
                               COMMIT;

                           END LOOP;

                           /*UPDATE wsh_new_deliveries WND
                           SET    WND.attribute1  = 'ROADNET_ROUTING_FAILED'
                           WHERE  WND.delivery_id = ln_dlvy_id; */

                        EXCEPTION WHEN OTHERS THEN

                           g_entity_ref        := 'DELIVERY_ID ';
                           g_entity_ref_id     := ln_delivery_number;

                           FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
                           FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
                           FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

                           p_error_description:= FND_MESSAGE.GET;
                           p_error_code       := 'ODP_OM_UNEXPECTED_ERR';

                           log_exceptions(p_error_code,
                                          p_error_description
                                         );

                        END;

                     END IF;  -- End IF lc_return_status = 'S' for TRIP updation

                  END LOOP;  -- END LOOP for cur_delivery_info

                  COMMIT;

               ELSE -- ELSE IF lc_route_number != lr_delivery_rec.route_number

                   FOR cur_attr IN lcu_attr(ln_dlvy_id) LOOP

                       lt_delivery_attributes.delivery_id                  := ln_dlvy_id;
                       lt_delivery_attributes.od_internal_delivery_status  := 'ROADNET_ROUTING_COMPLETE';
                       lt_delivery_attributes.redelivery_flag              := cur_attr.redelivery_flag;
                       lt_delivery_attributes.del_backtoback_ind           := cur_attr.del_backtoback_ind;
                       lt_delivery_attributes.no_of_shiplabels             := cur_attr.no_of_shiplabels;
                       lt_delivery_attributes.new_sch_ship_date            := cur_attr.new_sch_ship_date;
                       lt_delivery_attributes.new_sch_arr_date             := cur_attr.new_sch_arr_date;
                       lt_delivery_attributes.actual_deliverd_date         := cur_attr.actual_deliverd_date;
                       lt_delivery_attributes.new_del_date_from_time       := cur_attr.new_del_date_from_time;
                       lt_delivery_attributes.new_del_date_to_time         := cur_attr.new_del_date_to_time;
                       lt_delivery_attributes.delivery_cancelled_ind       := cur_attr.delivery_cancelled_ind;
                       lt_delivery_attributes.delivery_trans_ind           := cur_attr.delivery_trans_ind;
                       lt_delivery_attributes.pod_exceptions_comments      := cur_attr.pod_exceptions_comments;
                       lt_delivery_attributes.retransmit_pick_ticket       := cur_attr.retransmit_pick_ticket;
                       lt_delivery_attributes.payment_subtype_cod_ind      := cur_attr.payment_subtype_cod_ind;
                       lt_delivery_attributes.del_to_post_office_ind       := cur_attr.del_to_post_office_ind;
                       lt_delivery_attributes.creation_date                := cur_attr.creation_date;
                       lt_delivery_attributes.created_by                   := cur_attr.created_by;
                       lt_delivery_attributes.last_update_date             := SYSDATE;
                       lt_delivery_attributes.last_updated_by              := GN_USER_ID;
                       lt_delivery_attributes.last_update_login            := GN_USER_ID;

                       xx_wsh_delivery_attributes_pkg.update_row(lc_return_status
                                                                ,lc_errbuf
                                                                ,lt_delivery_attributes
                                                                );
                       COMMIT;

                   END LOOP;

                   /*UPDATE wsh_new_deliveries WND
                   SET    WND.attribute1  = 'ROADNET_ROUTING_COMPLETE'
                   WHERE  WND.delivery_id = ln_dlvy_id;*/

               END IF; -- END IF lc_route_number != lr_delivery_rec.route_number

            END IF;  -- End If of lc_process_dff = 'ROADNET_IMPORT_COMPLETE'

         END LOOP; --

         COMMIT;

      END IF;  -- lt_delivery_tbl.COUNT > 0

   END IF; -- End If responsibility

EXCEPTION WHEN OTHERS THEN

    g_entity_ref        := 'DELIVERY_ID';
    g_entity_ref_id     := ln_delivery_number;

    FND_MESSAGE.SET_NAME('XXOM','ODP_OM_UNEXPECTED_ERR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    p_error_description:= FND_MESSAGE.GET;
    p_error_code       := 'ODP_OM_UNEXPECTED_ERR';

    log_exceptions(p_error_code,
                   p_error_description
                  );

END import_route;

END XX_OM_ROADNET_TO_EBS_PKG;
/
SHOW ERRORS;
EXIT;