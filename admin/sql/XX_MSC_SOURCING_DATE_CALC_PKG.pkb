CREATE OR REPLACE PACKAGE BODY XX_MSC_SOURCING_DATE_CALC_PKG AS

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization               |
-- +===========================================================================+
-- | Name  : XX_MSC_SOURCING_DATE_CALC_PKG                                     |
-- | Description: Office Depot - Custom ATP                                    |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ====================================|
-- |Draft 1A 21-jun-2007  Roy Gomes        Initial draft version               |
-- |V 1.1    22-aug-2007  Roy Gomes        Added functions for                 |
-- |                                       Is_Carrier_Calendar_Open() &        |
-- |                                       Is_Customer_Calendar_Open() for     |
-- |                                       Appointment Scheduling              |
-- |v1.2     01-oct-2007  Roy Gomes        Included procedures for External ATP|
-- |                                                                           |
-- +===========================================================================+


   PG_DEBUG VARCHAR2(1) := NVL(FND_PROFILE.Value('MSC_ATP_DEBUG'), 'N');

   CUSTOMER_TYPE      CONSTANT  INTEGER := 2;
   ORGANIZATION_TYPE  CONSTANT  INTEGER := 3;
   CARRIER_TYPE       CONSTANT  INTEGER := 4;
   ASSOCIATION_LEVEL  CONSTANT  INTEGER := 4;

   PROCEDURE Check_CutOff_Times
      (
          p_ship_from_loc_id    IN  MSC_LOCATION_ASSOCIATIONS.location_id%Type,
          p_ship_from_org_id    IN  MTL_PARAMETERS_VIEW.organization_id%Type,
          p_current_date_time   IN  DATE,
          p_timezone_code       IN  HR_LOCATIONS_V.timezone_code%Type,
          p_pickup              IN  VARCHAR2,
          p_category_name       IN  MSC_ITEM_CATEGORIES.category_name%Type,
          x_next_day            OUT NUMBER,
          x_return_status       OUT VARCHAR2,
          x_msg                 OUT VARCHAR2
      ) AS

      CURSOR c_tz (c_ship_from_loc_id MSC_LOCATION_ASSOCIATIONS.location_id%Type) IS
         SELECT timezone_code
         FROM   hr_locations_v
         WHERE  location_id = c_ship_from_loc_id;


      l_timezone_code     HR_LOCATIONS.timezone_code%Type;
      l_time              VARCHAR2(5);

      l_delivery_code     XX_INV_ORG_LOC_RMS_ATTRIBUTE.od_delivery_cd_sw%Type;
      l_pickup_cutoff     XX_INV_ORG_LOC_RMS_ATTRIBUTE.pickup_delivery_cutoff_sw%Type; 
      l_sameday_cutoff    XX_INV_ORG_LOC_RMS_ATTRIBUTE.sameday_delivery_sw%Type; 
      l_furniture_cutoff  XX_INV_ORG_LOC_RMS_ATTRIBUTE.furniture_cutoff_sw%Type;

   BEGIN

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Check_Cutoff_Times() ...');
      END IF;

      x_return_status := 'S';

      OPEN  c_tz (p_ship_from_loc_id);
      FETCH c_tz INTO l_timezone_code;
      CLOSE c_tz;

      IF l_timezone_code IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine timezone code for location. (LOCATION ID: '||p_ship_from_loc_id||')';
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Org timezone: '||l_timezone_code);
      END IF;

      -- dbms_output.put_line('  -> Org timezone: '||l_timezone_code);

      l_time := To_Char(FND_TIMEZONE_PUB.Adjust_Datetime
                           (p_current_date_time,p_timezone_code,l_timezone_code), 'HH24:MI');

      XX_MSC_Sourcing_Util_Pkg.Get_Org_Attributes
        (
           p_organization_id      => p_ship_from_org_id,
           x_delivery_code        => l_delivery_code,
           x_pickup_cutoff        => l_pickup_cutoff,
           x_sameday_cutoff       => l_sameday_cutoff,
           x_furniture_cutoff     => l_furniture_cutoff,
           x_return_status        => x_return_status,
           x_msg                  => x_msg
        );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Org time: '||l_time);
         MSC_SCH_WB.ATP_Debug('  -> Pickup Cutoff: '||l_pickup_cutoff);
         MSC_SCH_WB.ATP_Debug('  -> Sameday Cutoff: '||l_sameday_cutoff);
         MSC_SCH_WB.ATP_Debug('  -> Furniture Cuttoff: '||l_furniture_cutoff);
      END IF;

      -- dbms_output.put_line('  -> Org time: '||l_time);
      -- dbms_output.put_line('  -> Pickup Cutoff: '||l_pickup_cutoff);
      -- dbms_output.put_line('  -> Sameday Cutoff: '||l_sameday_cutoff);
      -- dbms_output.put_line('  -> Furniture Cutoff: '||l_furniture_cutoff);

      IF l_time >= l_sameday_cutoff THEN
         x_next_day := 1;
         Return;
      END IF;

      IF p_pickup = 'Y' THEN
         IF l_time >= l_pickup_cutoff THEN
            x_next_day := 1;
            Return;
         END IF;
      END IF;

      IF p_category_name = 'F' THEN
         IF l_time >= l_furniture_cutoff THEN
            x_next_day := 1;
            Return;
         END IF;
      END IF;

      x_next_day := 0;

      -- dbms_output.put_line('next_day: '||x_next_day);


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Check_Cutoff_Times() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Check_CutOff_Times()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Check_CutOff_Times;

   PROCEDURE Get_Intransit_Time
      (
          p_ship_from_loc_id     IN  MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
          p_ship_to_region_id    IN  MSC_INTERORG_SHIP_METHODS.to_region_id%Type,
          p_ship_method          IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
          p_category_name        IN  MSC_ITEM_CATEGORIES.category_name%Type,
          p_bulk                 IN  VARCHAR2,
          x_ship_method          OUT MSC_INTERORG_SHIP_METHODS.ship_method%Type,
          x_intransit_time       OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
          x_return_status        OUT VARCHAR2,
          x_msg                  OUT VARCHAR2
      )  AS

      CURSOR c_sm_exists (c_ship_from_loc_id     MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                          c_ship_to_region_id    MSC_INTERORG_SHIP_METHODS.to_region_id%Type,
                          c_ship_method          MSC_INTERORG_SHIP_METHODS.ship_method%Type) IS
         SELECT 1
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id 
         AND    to_region_id = c_ship_to_region_id
         AND    Upper(ship_method) = Upper(c_ship_method);


      CURSOR c_no_sm_fur (c_ship_from_loc_id     MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                          c_ship_to_region_id    MSC_INTERORG_SHIP_METHODS.to_region_id%Type) IS
         SELECT ship_method, Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id 
         AND    to_region_id = c_ship_to_region_id
         AND    Nvl(attribute1, 'N') = 'Y';

      CURSOR c_no_sm_bulk (c_ship_from_loc_id     MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                           c_ship_to_region_id    MSC_INTERORG_SHIP_METHODS.to_region_id%Type) IS
         SELECT ship_method, Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id 
         AND    to_region_id = c_ship_to_region_id
         AND    Nvl(attribute2, 'N') = 'Y';

      CURSOR c_no_sm (c_ship_from_loc_id     MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                      c_ship_to_region_id    MSC_INTERORG_SHIP_METHODS.to_region_id%Type) IS
         SELECT ship_method, Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id
         AND    to_region_id = c_ship_to_region_id
         AND    default_flag = 1;

      CURSOR c_sm (c_ship_from_loc_id    MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                   c_ship_to_region_id   MSC_INTERORG_SHIP_METHODS.to_region_id%Type,
                   c_ship_method         MSC_INTERORG_SHIP_METHODS.ship_method%Type) IS
         SELECT ship_method, Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id 
         AND    to_region_id = c_ship_to_region_id
         AND    Upper(ship_method) = Upper(c_ship_method);

      l_exists NUMBER;
      

   BEGIN
     
      x_return_status := 'S';


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Intransit_Time() ...');
      END IF;

      IF p_ship_method IS Null THEN

         IF p_category_name = 'F' THEN
 
            OPEN c_no_sm_fur (p_ship_from_loc_id, p_ship_to_region_id);
            FETCH c_no_sm_fur INTO x_ship_method, x_intransit_time;
            CLOSE c_no_sm_fur;

         END IF;

         IF x_intransit_time IS NOT Null THEN
            Return;
         END IF;

         IF p_bulk = 'Y' THEN
 
            OPEN c_no_sm_bulk (p_ship_from_loc_id, p_ship_to_region_id);
            FETCH c_no_sm_bulk INTO x_ship_method, x_intransit_time;
            CLOSE c_no_sm_bulk;

         END IF; 

         IF x_intransit_time IS NOT Null THEN
            Return;
         END IF;

         OPEN c_no_sm (p_ship_from_loc_id, p_ship_to_region_id);
         FETCH c_no_sm INTO x_ship_method, x_intransit_time;
         CLOSE c_no_sm;
              

         IF x_intransit_time IS Null THEN
 
            x_return_status := 'E';
            x_msg := 'Cannot determine intransit time. (SHIP FROM LOC: '||p_ship_from_loc_id||
                                                        ', SHIP TO REGION: '||p_ship_to_region_id||')';
            Return;

         END IF;

      ELSE

         OPEN c_sm_exists (p_ship_from_loc_id, p_ship_to_region_id, p_ship_method);
         FETCH c_sm_exists INTO l_exists;
         CLOSE c_sm_exists;

         IF l_exists = 1 THEN

            OPEN c_sm (p_ship_from_loc_id, p_ship_to_region_id, p_ship_method);
            FETCH c_sm INTO x_ship_method, x_intransit_time;
            CLOSE c_sm;

            IF x_intransit_time IS Null THEN

               x_return_status := 'E';
               x_msg := 'Cannot determine intransit time. (SHIP METHOD: '||x_ship_method||
                                                           ', SHIP FROM LOC: '||p_ship_from_loc_id||
                                                           ', SHIP TO REGION: '||p_ship_to_region_id||')';
               Return;

            END IF;
          

         ELSE

            IF p_category_name = 'F' THEN
 
               OPEN c_no_sm_fur (p_ship_from_loc_id, p_ship_to_region_id);
               FETCH c_no_sm_fur INTO x_ship_method, x_intransit_time;
               CLOSE c_no_sm_fur;

            END IF;

            IF x_intransit_time IS NOT Null THEN
               Return;
            END IF;

            IF p_bulk = 'Y' THEN
 
               OPEN c_no_sm_bulk (p_ship_from_loc_id, p_ship_to_region_id);
               FETCH c_no_sm_bulk INTO x_ship_method, x_intransit_time;
               CLOSE c_no_sm_bulk;

            END IF; 

            IF x_intransit_time IS NOT Null THEN
               Return;
            END IF;

            OPEN c_no_sm (p_ship_from_loc_id, p_ship_to_region_id);
            FETCH c_no_sm INTO x_ship_method, x_intransit_time;
            CLOSE c_no_sm;

            IF x_intransit_time IS Null THEN
 
               x_return_status := 'E';
               x_msg := 'Cannot determine intransit time. (SHIP METHOD: '||x_ship_method||
                                                           ', SHIP FROM LOC: '||p_ship_from_loc_id||
                                                           ', SHIP TO REGION: ' ||p_ship_to_region_id||')';
               Return;

            END IF;

         END IF;
          

      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Intransit_Time() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Intransit_Time()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Intransit_Time;

   PROCEDURE Get_Intransit_Time
      (
          p_ship_from_loc_id     IN  MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
          p_ship_to_loc_id       IN  MSC_INTERORG_SHIP_METHODS.to_location_id%Type,
          p_ship_method          IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
          p_category_name        IN  MSC_ITEM_CATEGORIES.category_name%Type,
          p_bulk                 IN  VARCHAR2,
          x_ship_method          OUT MSC_INTERORG_SHIP_METHODS.ship_method%Type,
          x_intransit_time       OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
          x_return_status        OUT VARCHAR2,
          x_msg                  OUT VARCHAR2
      )  AS

      CURSOR c_sm_exists (c_ship_from_loc_id     MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                          c_ship_to_loc_id       MSC_INTERORG_SHIP_METHODS.to_location_id%Type,
                          c_ship_method          MSC_INTERORG_SHIP_METHODS.ship_method%Type) IS
         SELECT 1
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id 
         AND    to_location_id = c_ship_to_loc_id
         AND    Upper(ship_method) = Upper(c_ship_method);


      CURSOR c_no_sm_fur (c_ship_from_loc_id     MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                          c_ship_to_loc_id       MSC_INTERORG_SHIP_METHODS.to_location_id%Type) IS
         SELECT ship_method, Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id
         AND    to_location_id = c_ship_to_loc_id
         AND    Nvl(attribute1, 'N') = 'Y';

      CURSOR c_no_sm_bulk (c_ship_from_loc_id     MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                           c_ship_to_loc_id       MSC_INTERORG_SHIP_METHODS.to_location_id%Type) IS
         SELECT ship_method, Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id 
         AND    to_location_id = c_ship_to_loc_id
         AND    Nvl(attribute2, 'N') = 'Y';

      CURSOR c_no_sm (c_ship_from_loc_id     MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                      c_ship_to_loc_id       MSC_INTERORG_SHIP_METHODS.to_location_id%Type) IS
         SELECT ship_method, Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id
         AND    to_location_id = c_ship_to_loc_id 
         AND    default_flag = 1;

      CURSOR c_sm (c_ship_from_loc_id    MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                   c_ship_to_loc_id      MSC_INTERORG_SHIP_METHODS.to_location_id%Type,
                   c_ship_method         MSC_INTERORG_SHIP_METHODS.ship_method%Type) IS
         SELECT ship_method, Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id 
         AND    to_location_id = c_ship_to_loc_id
         AND    Upper(ship_method) = Upper(c_ship_method);

      l_exists NUMBER;

   BEGIN

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Intransit_Time() ...');
      END IF;
     
      x_return_status := 'S';

      IF p_ship_method IS Null THEN

         IF p_category_name = 'F' THEN
 
            OPEN c_no_sm_fur (p_ship_from_loc_id, p_ship_to_loc_id);
            FETCH c_no_sm_fur INTO x_ship_method, x_intransit_time;
            CLOSE c_no_sm_fur;

         END IF;

         IF x_intransit_time IS NOT Null THEN
            Return;
         END IF;

         IF p_bulk = 'Y' THEN
 
            OPEN c_no_sm_bulk (p_ship_from_loc_id, p_ship_to_loc_id);
            FETCH c_no_sm_bulk INTO x_ship_method, x_intransit_time;
            CLOSE c_no_sm_bulk;

         END IF; 

         IF x_intransit_time IS NOT Null THEN
            Return;
         END IF;

         OPEN c_no_sm (p_ship_from_loc_id, p_ship_to_loc_id);
         FETCH c_no_sm INTO x_ship_method, x_intransit_time;
         CLOSE c_no_sm;
              

         IF x_intransit_time IS Null THEN
 
            x_return_status := 'E';
            x_msg := 'Cannot determine intransit time. (SHIP FROM LOC: '||p_ship_from_loc_id||
                                                        ', SHIP TO LOC: '||p_ship_to_loc_id||')';
            Return;

         END IF;

      ELSE

         OPEN c_sm_exists (p_ship_from_loc_id, p_ship_to_loc_id, p_ship_method);
         FETCH c_sm_exists INTO l_exists;
         CLOSE c_sm_exists;

         IF l_exists = 1 THEN

            OPEN c_sm (p_ship_from_loc_id, p_ship_to_loc_id, p_ship_method);
            FETCH c_sm INTO x_ship_method, x_intransit_time;
            CLOSE c_sm;

            IF x_intransit_time IS Null THEN

               x_return_status := 'E';
               x_msg := 'Cannot determine intransit time. (SHIP METHOD: '||x_ship_method||
                                                           ', SHIP FROM LOC: '||p_ship_from_loc_id||
                                                           ', SHIP TO LOC: '||p_ship_to_loc_id||')';
               Return;

            END IF;
          

         ELSE

            IF p_category_name = 'F' THEN
 
               OPEN c_no_sm_fur (p_ship_from_loc_id, p_ship_to_loc_id);
               FETCH c_no_sm_fur INTO x_ship_method, x_intransit_time;
               CLOSE c_no_sm_fur;

            END IF;

            IF x_intransit_time IS NOT Null THEN
               Return;
            END IF;

            IF p_bulk = 'Y' THEN
 
               OPEN c_no_sm_bulk (p_ship_from_loc_id, p_ship_to_loc_id);
               FETCH c_no_sm_bulk INTO x_ship_method, x_intransit_time;
               CLOSE c_no_sm_bulk;

            END IF; 

            IF x_intransit_time IS NOT Null THEN
               Return;
            END IF;

            OPEN c_no_sm (p_ship_from_loc_id, p_ship_to_loc_id);
            FETCH c_no_sm INTO x_ship_method, x_intransit_time;
            CLOSE c_no_sm;

            IF x_intransit_time IS Null THEN
 
               x_return_status := 'E';
               x_msg := 'Cannot determine intransit time. (SHIP METHOD: '||x_ship_method||
                                                           ', SHIP FROM LOC: '||p_ship_from_loc_id||
                                                           ', SHIP TO LOC: ' ||p_ship_to_loc_id||')';
               Return;

            END IF;

         END IF;
          

      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Intransit_Time() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Intransit_Time()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Intransit_Time;


   PROCEDURE Get_Intransit_Time
      (
          p_ship_from_loc_id     IN  MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
          p_ship_to_region_id    IN  MSC_INTERORG_SHIP_METHODS.to_region_id%Type,
          p_ship_method          IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
          x_intransit_time       OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
          x_return_status        OUT VARCHAR2,
          x_msg                  OUT VARCHAR2
      )  AS


      CURSOR c_sm (c_ship_from_loc_id    MSC_INTERORG_SHIP_METHODS.from_location_id%Type,
                   c_ship_to_region_id   MSC_INTERORG_SHIP_METHODS.to_region_id%Type,
                   c_ship_method         MSC_INTERORG_SHIP_METHODS.ship_method%Type) IS
         SELECT Nvl(intransit_time,0)
         FROM   mtl_interorg_ship_methods 
         WHERE  from_location_id = c_ship_from_loc_id 
         AND    to_region_id = c_ship_to_region_id
         AND    Upper(ship_method) = Upper(c_ship_method);
      

   BEGIN
     
      x_return_status := 'S';


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Intransit_Time() ...');
      END IF;


      OPEN  c_sm (p_ship_from_loc_id, p_ship_to_region_id, p_ship_method);
      FETCH c_sm INTO x_intransit_time;
      CLOSE c_sm;

      IF x_intransit_time IS Null THEN

         x_return_status := 'E';
         x_msg := 'Cannot determine intransit time. (SHIP METHOD: '||p_ship_method||
                                                    ', SHIP FROM LOC: '||p_ship_from_loc_id||
                                                    ', SHIP TO REGION: '||p_ship_to_region_id||')';
         Return;

      END IF;
          

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Intransit_Time() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Intransit_Time()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Intransit_Time;



   PROCEDURE Get_Zone_Arrival_Date
      (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_from_loc_id              IN  MTL_INTERORG_SHIP_METHODS.from_location_id%Type, 
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_ship_method                   IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_category_name                 IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_order_type                    IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_to_region_id             IN  MTL_INTERORG_SHIP_METHODS.to_region_id%Type,
         p_current_date_time             IN  DATE,
         p_timezone_code                 IN  HR_LOCATIONS_V.timezone_code%Type,
         p_pickup                        IN  VARCHAR2,
         p_bulk                          IN  VARCHAR2,
         x_ship_date                     IN OUT DATE,
         x_arrival_date                  OUT DATE,
         x_intransit_time                OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_ship_method                   OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_partner_id                    OUT MSC_TRADING_PARTNERS.partner_id%Type,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      ) AS

      l_intransit_time                   MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_partner_id                       MSC_TRADING_PARTNERS.partner_id%Type;
      l_date                             DATE;
      l_next_day                         NUMBER;
      l_ship_method                      MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_no_customer_calendar             BOOLEAN := FALSE;
      l_date1                            DATE;
      l_date2                            DATE;
      l_today                            DATE := Trunc(Sysdate);

      i number := 0;

      l_debug_date                       VARCHAR2(4000);

   BEGIN

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Zone_Arrival_Date() ...');
      END IF;
      
      x_return_status := 'S';

      IF p_partner_number      IS Null OR
         p_ship_from_loc_id    IS Null OR
         p_ship_to_region_id   IS Null THEN

         x_return_status := 'E';
         x_msg := 'Need customer Number, ship-from location, and ship-to zone to determine ship and arrival dates';
         Return;

      END IF;

      Check_CutOff_Times
         (
             p_ship_from_loc_id     => p_ship_from_loc_id,
             p_ship_from_org_id     => p_ship_from_org_id,
             p_current_date_time    => p_current_date_time,
             p_timezone_code        => p_timezone_code,
             p_pickup               => p_pickup,
             p_category_name        => p_category_name,
             x_next_day             => l_next_day,
             x_return_status        => x_return_status,
             x_msg                  => x_msg
         ); 


      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         IF l_next_day = 1 THEN
            MSC_SCH_WB.ATP_Debug('  -> Next Day Delivery');
         ELSE
            MSC_SCH_WB.ATP_Debug('  -> Same Day Delivery');
         END IF;
      END IF;
      /*
      if l_next_day = 1 then
         dbms_output.put_line('  -> Next Day Delivery');
      else
         dbms_output.put_line('  -> Same Day Delivery');
      end if;
      */

      BEGIN


         l_date := x_ship_date;

         IF Trunc(x_ship_date) = l_today AND l_next_day = 1 THEN

            SELECT c2.calendar_date
            INTO   l_date
            FROM   msc_calendar_dates c,
	           msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.organization_id = p_ship_from_org_id
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = ORGANIZATION_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = ORGANIZATION_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'SHIPPING'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = Trunc(x_ship_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num + l_next_day; 

         END IF;

         x_ship_date := l_date;

         l_debug_date := l_date;
	

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_ship_from_org_id||')';
            Return;
      END;

      Get_Intransit_Time
         (
             p_ship_from_loc_id       => p_ship_from_loc_id,
             p_ship_to_region_id      => p_ship_to_region_id,
             p_ship_method            => p_ship_method,
             p_category_name          => p_category_name,
             p_bulk                   => p_bulk,
             x_ship_method            => l_ship_method,
             x_intransit_time         => l_intransit_time,
             x_return_status          => x_return_status,
             x_msg                    => x_msg
         );

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Transit time: '||l_intransit_time);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method: '||l_ship_method);
      END IF;

      -- dbms_output.put_line('-> Transit time: '||l_intransit_time);
      -- dbms_output.put_line('-> Ship Method: '||l_ship_method);

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      BEGIN
         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.ship_method_code = l_ship_method
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CARRIER_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = CARRIER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'CARRIER'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num + l_intransit_time; 

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||l_ship_method||')';
            Return;
      END;


      XX_MSC_Sourcing_Util_Pkg.Get_Customer_Partner_ID
         (
            p_partner_number    => p_partner_number,
            x_partner_id        => l_partner_id,
            x_return_status     => x_return_status,
            x_msg               => x_msg
         );


      IF x_return_status <> 'S' THEN
         Return;
      END IF;     



      -- Get Customer Calendar
      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.partner_id = l_partner_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CUSTOMER_TYPE
         AND    ca.association_level= ASSOCIATION_LEVEL
         AND    ca.association_type = CUSTOMER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'RECEIVING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num; 

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_no_customer_calendar := True;
            -- dbms_output.put_line('  -> No Customer Calendar exists.');

            IF PG_DEBUG in ('Y', 'C') THEN
               MSC_SCH_WB.ATP_Debug('  -> No Customer Calendar exists.');
            END IF;
         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (PARTNER NUMBER:'||p_partner_number||')';
            Return;
      END;


      IF NOT l_no_customer_calendar THEN

         LOOP

            i := i+1;
            -- dbms_output.put_line('i: '||i);

            SELECT c2.calendar_date
            INTO   l_date1
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.ship_method_code = l_ship_method
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CARRIER_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = CARRIER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'CARRIER'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num;

            -- dbms_output.put_line('Date1: '||l_date1);

            SELECT c2.calendar_date
            INTO   l_date2
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.partner_id = l_partner_id
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CUSTOMER_TYPE
            AND    ca.association_level= ASSOCIATION_LEVEL
            AND    ca.association_type = CUSTOMER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'RECEIVING'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num;

            -- dbms_output.put_line('Date2: '||l_date2);

            IF Trunc(l_date1) = Trunc(l_date2) THEN
               Exit;
            ELSE
               IF Trunc(l_date1) > Trunc(l_date2) THEN
                  l_date := l_date1;
               ELSE
                  l_date := l_date2;
               END IF;
            END IF;

            -- dbms_output.put_line('Date: '||l_date);

            IF i > 100 THEN
               x_return_status := 'E';
               x_msg := 'Check Customer/Carrier Calendars. Customer closed when carrier open and vice versa.';
               Return;
            END IF;

        END LOOP;

      END IF;


      l_debug_date := l_debug_date || ' => '||l_date;


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Date Path: '||l_debug_date);
      END IF;

      -- dbms_output.put_line('  -> Date Path: '||l_debug_date); 


      x_arrival_date := l_date;
      x_intransit_time := l_intransit_time;
      x_ship_method := l_ship_method;
      x_partner_id := l_partner_id;


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Zone_Arrival_Date() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Zone_Arrival_Date()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Zone_Arrival_Date;

   PROCEDURE Get_Org_Ship_Date
      (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_partner_id                    IN  MSC_TRADING_PARTNERS.partner_id%Type,
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type, 
         p_ship_method                   IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_intransit_time                IN  MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_requested_date                IN OUT DATE,
         x_ship_date                     OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      ) AS

      l_date                             DATE;
      l_no_customer_calendar             BOOLEAN := FALSE;
      l_date1                            DATE;
      l_date2                            DATE;
      l_date3                            DATE;

      i number := 0;

      l_debug_date                       VARCHAR2(4000);

   BEGIN

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Org_Ship_Date() ...');
      END IF;
      
      x_return_status := 'S';

      -- Get Customer Calendar
      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.partner_id = p_partner_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CUSTOMER_TYPE
         AND    ca.association_level= ASSOCIATION_LEVEL
         AND    ca.association_type = CUSTOMER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'RECEIVING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(x_requested_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num; 

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_no_customer_calendar := True;
            -- dbms_output.put_line('  -> No Customer Calendar exists.');
            IF PG_DEBUG in ('Y', 'C') THEN
               MSC_SCH_WB.ATP_Debug('  -> No Customer Calendar exists.');
            END IF;
 
         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (PARTNER NUMBER:'||p_partner_number||')';
            Return;
      END;

      IF NOT l_no_customer_calendar THEN

         LOOP

            i := i+1;
            -- dbms_output.put_line('i: '||i);

            SELECT c2.calendar_date
            INTO   l_date1
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.ship_method_code = p_ship_method
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CARRIER_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = CARRIER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'CARRIER'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.prior_seq_num;

            -- dbms_output.put_line('Date1: '||l_date1);

            SELECT c2.calendar_date
            INTO   l_date2
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.partner_id = p_partner_id
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CUSTOMER_TYPE
            AND    ca.association_level= ASSOCIATION_LEVEL
            AND    ca.association_type = CUSTOMER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'RECEIVING'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.prior_seq_num;

            -- dbms_output.put_line('Date2: '||l_date2);

            IF Trunc(l_date1) = Trunc(l_date2) THEN
               Exit;
            ELSE
               IF Trunc(l_date1) < Trunc(l_date2) THEN
                  l_date := l_date1;
               ELSE
                  l_date := l_date2;
               END IF;
            END IF;

            -- dbms_output.put_line('Date: '||l_date);

            IF i > 100 THEN
               x_return_status := 'E';
               x_msg := 'Check Customer/Carrier Calendars. Customer closed when carrier open and vice versa.';
               Return;
            END IF;

        END LOOP;

      ELSE

         BEGIN

            SELECT c2.calendar_date
            INTO   l_date
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.ship_method_code = p_ship_method
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CARRIER_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = CARRIER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'CARRIER'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(x_requested_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.prior_seq_num;

         EXCEPTION

            WHEN OTHERS THEN
               x_return_status := 'E';
               x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||p_ship_method||')';
               Return;
         END;

      END IF;

      x_requested_date := l_date;

      l_debug_date := l_date;

      BEGIN
         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.ship_method_code = p_ship_method
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CARRIER_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = CARRIER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'CARRIER'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num - p_intransit_time; 

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||p_ship_method||')';
            Return;
      END;

      -- dbms_output.put_line('Org dely to Carrier: '||l_date);

      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
	        msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.organization_id = p_ship_from_org_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = ORGANIZATION_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = ORGANIZATION_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'SHIPPING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = Trunc(l_date)
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num; 


      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_ship_from_org_id||')';
            Return;
      END;

      l_debug_date := l_debug_date ||' <= ' || l_date;

      x_ship_date := l_date;

      -- dbms_output.put_line('  -> Date Path: '||l_debug_date);  

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Date Path: '||l_debug_date);  
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Org_Ship_Date() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Org_Ship_Date()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Org_Ship_Date;

   PROCEDURE Get_Zone_Arrival_Date
      (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_ship_from_loc_id              IN  MTL_INTERORG_SHIP_METHODS.from_location_id%Type, 
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_base_org_id                   IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_base_loc_id                   IN  MTL_INTERORG_SHIP_METHODS.from_location_id%Type, 
         p_ship_method                   IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_category_name                 IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_order_type                    IN  OE_TRANSACTION_TYPES_TL.name%Type,
         p_ship_to_region_id             IN  MTL_INTERORG_SHIP_METHODS.to_region_id%Type,
         p_current_date_time             IN  DATE,
         p_timezone_code                 IN  HR_LOCATIONS_V.timezone_code%Type,
         p_pickup                        IN  VARCHAR2,
         p_bulk                          IN  VARCHAR2,
         x_ship_date                     IN OUT DATE,
         x_arrival_date                  OUT DATE,
         x_intransit_time_1              OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_ship_method_1                 OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_intransit_time_2              OUT MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_ship_method_2                 OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         x_partner_id                    OUT MSC_TRADING_PARTNERS.partner_id%Type,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      ) AS

      l_intransit_time_1                 MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_intransit_time_2                 MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_partner_id                       MSC_TRADING_PARTNERS.partner_id%Type;
      l_date                             DATE;
      l_next_day                         NUMBER;
      l_ship_method_1                    MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_ship_method_2                    MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_no_customer_calendar             BOOLEAN := FALSE;
      l_date1                            DATE;
      l_date2                            DATE;
      l_today                            DATE := Trunc(Sysdate);

      i number := 0;

      l_debug_date                       VARCHAR2(4000);

   BEGIN

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Zone_Arrival_Date() ...');
      END IF;

      x_return_status := 'S';

      IF p_partner_number      IS Null OR
         p_ship_from_loc_id    IS Null OR
         p_ship_to_region_id   IS Null THEN

         x_return_status := 'E';
         x_msg := 'Need customer Number, ship-from location, and ship-to zone to determine ship and arrival dates';
         Return;

      END IF;

      Check_CutOff_Times
         (
             p_ship_from_loc_id     => p_ship_from_loc_id,
             p_ship_from_org_id     => p_ship_from_org_id,
             p_current_date_time    => p_current_date_time,
             p_timezone_code        => p_timezone_code,
             p_pickup               => p_pickup,
             p_category_name        => p_category_name,
             x_next_day             => l_next_day,
             x_return_status        => x_return_status,
             x_msg                  => x_msg
         ); 


      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         IF l_next_day = 1 THEN
            MSC_SCH_WB.ATP_Debug('  -> Next Day Delivery');
         ELSE
            MSC_SCH_WB.ATP_Debug('  -> Same Day Delivery');
         END IF;
      END IF;
      /*
      if l_next_day = 1 then
         dbms_output.put_line('  -> Next Day Delivery');
      else
         dbms_output.put_line('  -> Same Day Delivery');
      end if;
      */
      BEGIN
 

         l_date := x_ship_date;

         IF Trunc(x_ship_date) = l_today AND l_next_day = 1 THEN

            SELECT c2.calendar_date
            INTO   l_date
            FROM   msc_calendar_dates c,
	           msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.organization_id = p_ship_from_org_id
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = ORGANIZATION_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = ORGANIZATION_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'SHIPPING'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = Trunc(x_ship_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num + l_next_day; 

         END IF;

         x_ship_date := l_date;

	

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_ship_from_org_id||')';
            Return;
      END;

      l_debug_date := l_date;

      Get_Intransit_Time
         (
             p_ship_from_loc_id       => p_ship_from_loc_id,
             p_ship_to_loc_id         => p_base_loc_id,
             p_ship_method            => p_ship_method,
             p_category_name          => p_category_name,
             p_bulk                   => p_bulk,
             x_ship_method            => l_ship_method_1,
             x_intransit_time         => l_intransit_time_1,
             x_return_status          => x_return_status,
             x_msg                    => x_msg
         );

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Transit time (Org->Base): '||l_intransit_time_1);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method (Org->Base): '||l_ship_method_1);
      END IF;

      -- dbms_output.put_line('  -> Transit time (Org->Base): '||l_intransit_time_1);
      -- dbms_output.put_line('  -> Ship Method (Org->Base): '||l_ship_method_1);

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      BEGIN
         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.ship_method_code = l_ship_method_1
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CARRIER_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = CARRIER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'CARRIER'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num + l_intransit_time_1; 

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||l_ship_method_1||')';
            Return;
      END;

      -- dbms_output.put_line('Date: '||l_date);

      BEGIN
 

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.organization_id = p_base_org_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = ORGANIZATION_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = ORGANIZATION_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'RECEIVING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = Trunc(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num; 

	

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_base_org_id||')';
            Return;
      END;

      l_debug_date := l_debug_date ||' => '||l_date;


      BEGIN
 

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.organization_id = p_base_org_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = ORGANIZATION_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = ORGANIZATION_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'SHIPPING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = Trunc(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num; 

	

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_base_org_id||')';
            Return;
      END;

      l_debug_date := l_debug_date ||' => '||l_date;

      Get_Intransit_Time
         (
             p_ship_from_loc_id       => p_base_loc_id,
             p_ship_to_region_id      => p_ship_to_region_id,
             p_ship_method            => p_ship_method,
             p_category_name          => p_category_name,
             p_bulk                   => p_bulk,
             x_ship_method            => l_ship_method_2,
             x_intransit_time         => l_intransit_time_2,
             x_return_status          => x_return_status,
             x_msg                    => x_msg
         );


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Transit time (Base->Zone): '||l_intransit_time_2);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method: (Base->Zone)'||l_ship_method_2);
      END IF;

      -- dbms_output.put_line('  -> Transit time (Base->Zone): '||l_intransit_time_2);
      -- dbms_output.put_line('  -> Ship Method: (Base->Zone)'||l_ship_method_2);

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      BEGIN
         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.ship_method_code = l_ship_method_2
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CARRIER_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = CARRIER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'CARRIER'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num + l_intransit_time_2; 

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||l_ship_method_2||')';
            Return;
      END;

      -- dbms_output.put_line('Date: '||l_date);


      XX_MSC_Sourcing_Util_Pkg.Get_Customer_Partner_ID
         (
            p_partner_number    => p_partner_number,
            x_partner_id        => l_partner_id,
            x_return_status     => x_return_status,
            x_msg               => x_msg
         );


      IF x_return_status <> 'S' THEN
         Return;
      END IF;     



      -- Get Customer Calendar
      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.partner_id = l_partner_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CUSTOMER_TYPE
         AND    ca.association_level= ASSOCIATION_LEVEL
         AND    ca.association_type = CUSTOMER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'RECEIVING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num; 

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_no_customer_calendar := True;
            -- dbms_output.put_line('  -> No Customer Calendar exists.');
            IF PG_DEBUG in ('Y', 'C') THEN
               MSC_SCH_WB.ATP_Debug('  -> No Customer Calendar exists.');
            END IF;
         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (PARTNER NUMBER:'||p_partner_number||')';
            Return;
      END;

      -- dbms_output.put_line('Customer Receives from Carrier: '||l_date);


      IF NOT l_no_customer_calendar THEN

         LOOP

            i := i+1;
            -- dbms_output.put_line('i: '||i);

            SELECT c2.calendar_date
            INTO   l_date1
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.ship_method_code = l_ship_method_2
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CARRIER_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = CARRIER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'CARRIER'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num;

            -- dbms_output.put_line('Date1: '||l_date1);

            SELECT c2.calendar_date
            INTO   l_date2
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.partner_id = l_partner_id
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CUSTOMER_TYPE
            AND    ca.association_level= ASSOCIATION_LEVEL
            AND    ca.association_type = CUSTOMER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'RECEIVING'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num;

            -- dbms_output.put_line('Date2: '||l_date2);

            IF Trunc(l_date1) = Trunc(l_date2) THEN
               Exit;
            ELSE
               IF Trunc(l_date1) > Trunc(l_date2) THEN
                  l_date := l_date1;
               ELSE
                  l_date := l_date2;
               END IF;
            END IF;

            -- dbms_output.put_line('Date: '||l_date);

            IF i > 100 THEN
               x_return_status := 'E';
               x_msg := 'Check Customer/Carrier Calendars. Customer closed when carrier open and vice versa.';
               Return;
            END IF;

        END LOOP;

      END IF;

      l_debug_date := l_debug_date ||' => '||l_date;

      x_arrival_date := l_date;
      x_intransit_time_1 := l_intransit_time_1;
      x_intransit_time_2 := l_intransit_time_2;
      x_ship_method_1 := l_ship_method_1;
      x_ship_method_2 := l_ship_method_2;
      x_partner_id := l_partner_id;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Date Path: '||l_debug_date);
      END IF;

      -- dbms_output.put_line('  -> Date Path: '||l_debug_date);

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Zone_Arrival_Date() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Zone_Arrival_Date()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Zone_Arrival_Date;

   PROCEDURE Get_XDock_Ship_Date
      (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_partner_id                    IN  MSC_TRADING_PARTNERS.partner_id%Type,
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_base_org_id                   IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_ship_method_1                 IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_intransit_time_1              IN  MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         p_ship_method_2                 IN  MTL_INTERORG_SHIP_METHODS.ship_method%Type,
         p_intransit_time_2              IN  MSC_INTERORG_SHIP_METHODS.intransit_time%Type,
         x_requested_date                IN OUT DATE,
         x_ship_date                     OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
      ) AS

      l_date                             DATE;
      l_no_customer_calendar             BOOLEAN := FALSE;
      l_date1                            DATE;
      l_date2                            DATE;
      l_date3                            DATE;

      i number := 0;

      l_debug_date                       VARCHAR2(4000);

   BEGIN
      
      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Get_XDock_Ship_Date() ...');
      END IF;

      x_return_status := 'S';

      -- Get Customer Calendar
      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.partner_id = p_partner_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CUSTOMER_TYPE
         AND    ca.association_level= ASSOCIATION_LEVEL
         AND    ca.association_type = CUSTOMER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'RECEIVING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(x_requested_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num; 

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_no_customer_calendar := True;
            -- dbms_output.put_line('  -> No Customer Calendar exists.');
            IF PG_DEBUG in ('Y', 'C') THEN
               MSC_SCH_WB.ATP_Debug('  -> No Customer Calendar exists.');
            END IF;
         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (PARTNER NUMBER:'||p_partner_number||')';
            Return;
      END;

      -- dbms_output.put_line('Date1: '||l_date);


      IF NOT l_no_customer_calendar THEN

         LOOP

            i := i+1;
            -- dbms_output.put_line('i: '||i);

            SELECT c2.calendar_date
            INTO   l_date1
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.ship_method_code = p_ship_method_2
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CARRIER_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = CARRIER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'CARRIER'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.prior_seq_num;

            -- dbms_output.put_line('Date1: '||l_date1);

            SELECT c2.calendar_date
            INTO   l_date2
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.partner_id = p_partner_id
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CUSTOMER_TYPE
            AND    ca.association_level= ASSOCIATION_LEVEL
            AND    ca.association_type = CUSTOMER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'RECEIVING'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.prior_seq_num;

            -- dbms_output.put_line('Date2: '||l_date2);

            IF Trunc(l_date1) = Trunc(l_date2) THEN
               Exit;
            ELSE
               IF Trunc(l_date1) < Trunc(l_date2) THEN
                  l_date := l_date1;
               ELSE
                  l_date := l_date2;
               END IF;
            END IF;


            IF i > 100 THEN
               x_return_status := 'E';
               x_msg := 'Check Customer/Carrier Calendars. Customer closed when carrier open and vice versa.';
               Return;
            END IF;

        END LOOP;

      ELSE

         BEGIN

            SELECT c2.calendar_date
            INTO   l_date
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.ship_method_code = p_ship_method_2
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CARRIER_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = CARRIER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'CARRIER'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(x_requested_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.prior_seq_num;

         EXCEPTION

            WHEN OTHERS THEN
               x_return_status := 'E';
               x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||p_ship_method_2||')';
               Return;
         END;

      END IF;

      -- dbms_output.put_line('Date2: '||l_date);

      x_requested_date := l_date;

      l_debug_date := l_date;

      BEGIN
         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.ship_method_code = p_ship_method_2
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CARRIER_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = CARRIER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'CARRIER'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num - p_intransit_time_2; 

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||p_ship_method_2||')';
            Return;
      END;

      -- dbms_output.put_line('Date3: '||l_date);

      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
	        msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.organization_id = p_base_org_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = ORGANIZATION_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = ORGANIZATION_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'SHIPPING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = Trunc(l_date)
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num; 


      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_base_org_id||')';
            Return;
      END;

      -- dbms_output.put_line('Date4: '||l_date);

      l_debug_date := l_debug_date ||' <= '||l_date;

      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
	        msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.organization_id = p_base_org_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = ORGANIZATION_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = ORGANIZATION_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'RECEIVING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = Trunc(l_date)
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num; 


      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_base_org_id||')';
            Return;
      END;

      -- dbms_output.put_line('Date5: '||l_date);

      l_debug_date := l_debug_date || ' <= ' ||l_date;

      BEGIN
         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.ship_method_code = p_ship_method_1
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CARRIER_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = CARRIER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'CARRIER'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num - p_intransit_time_1; 

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||p_ship_method_1||')';
            Return;
      END;

      -- dbms_output.put_line('Date6: '||l_date);


      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
	        msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.organization_id = p_ship_from_org_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = ORGANIZATION_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = ORGANIZATION_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'SHIPPING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = Trunc(l_date)
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.prior_seq_num; 


      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_ship_from_org_id||')';
            Return;
      END;

      -- dbms_output.put_line('Date7: '||l_date);

      l_debug_date := l_debug_date || ' <= ' ||l_date;

      x_ship_date := l_date;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Date Path: '||l_debug_date);
      END IF;

      -- dbms_output.put_line('  -> Date Path: '||l_debug_date);

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Get_XDock_Ship_Date() ...');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_XDock_Ship_Date()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_XDock_Ship_Date;

   PROCEDURE Get_Pickup_Date
     (
         p_ship_from_loc_id              IN  MTL_INTERORG_SHIP_METHODS.from_location_id%Type,
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_category_name                 IN  MSC_ITEM_CATEGORIES.category_name%Type,
         p_pickup                        IN  VARCHAR2,
         p_current_date_time             IN  DATE,
         p_timezone_code                 IN  HR_LOCATIONS_V.timezone_code%Type,
         x_ship_date                     IN OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     ) AS

      l_date      DATE;
      l_next_day  NUMBER;
      l_today     DATE := Trunc(Sysdate);

   BEGIN

      Check_CutOff_Times
         (
             p_ship_from_loc_id     => p_ship_from_loc_id,
             p_ship_from_org_id     => p_ship_from_org_id,
             p_current_date_time    => p_current_date_time,
             p_timezone_code        => p_timezone_code,
             p_pickup               => p_pickup,
             p_category_name        => p_category_name,
             x_next_day             => l_next_day,
             x_return_status        => x_return_status,
             x_msg                  => x_msg
         ); 


      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         IF l_next_day = 1 THEN
            MSC_SCH_WB.ATP_Debug('  -> Next Day Delivery');
         ELSE
            MSC_SCH_WB.ATP_Debug('  -> Same Day Delivery');
         END IF;
      END IF;
      /*
      if l_next_day = 1 then
         dbms_output.put_line('  -> Next Day Delivery');
      else
         dbms_output.put_line('  -> Same Day Delivery');
      end if;
      */
      BEGIN
 

         l_date := x_ship_date;

         IF Trunc(x_ship_date) = l_today AND l_next_day = 1 THEN

            SELECT c2.calendar_date
            INTO   l_date
            FROM   msc_calendar_dates c,
	           msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.organization_id = p_ship_from_org_id
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = ORGANIZATION_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = ORGANIZATION_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'SHIPPING'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = Trunc(x_ship_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num + l_next_day; 

         END IF;

         x_ship_date := l_date;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Pickup Date: '||x_ship_date);
         END IF;

         -- dbms_output.put_line('  -> Pickup Date: '||x_ship_date);


      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_ship_from_org_id||')';
            Return;
      END;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Pickup_Date()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Pickup_Date;


   PROCEDURE Get_Future_Pickup_Date
     (
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         x_ship_date                     IN OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     ) AS

      l_date DATE;

   BEGIN


      BEGIN
 
         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.organization_id = p_ship_from_org_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = ORGANIZATION_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = ORGANIZATION_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'SHIPPING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = Trunc(x_ship_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num; 

         x_ship_date := l_date;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Future Pickup Date: '||x_ship_date);
         END IF;

         -- dbms_output.put_line('  -> Future Pickup Date: '||x_ship_date);

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (ORG ID:'||p_ship_from_org_id||')';
            Return;
      END;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Future_Pickup_Date()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Future_Pickup_Date;

   PROCEDURE Get_Schedule_Arrival_Date
     (
         p_ship_from_org_id              IN  MSC_SYSTEM_ITEMS.organization_id%Type,
         p_customer_site_id              IN  HZ_CUST_SITE_USES_ALL.site_use_id%Type,
         p_sr_item_id                    IN  MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type,
         p_ship_method                   IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_customer_id                   IN  RA_CUSTOMERS.customer_id%Type,
         p_ship_date                     IN  DATE,
         x_arrival_date                  OUT DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     ) AS

      l_date                             DATE;
      l_location_id                      MSC_LOCATION_ASSOCIATIONS.location_id%Type; 
      l_intransit_time                   MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_ship_to_location                 HZ_CUST_SITE_USES_ALL.location%Type;
      l_postal_code                      WSH_ZONE_REGIONS_V.postal_code_from%Type;
      l_category_set_id                  MSC_CATEGORY_SETS.category_set_id%Type;
      l_item_id                          MSC_SYSTEM_ITEMS.inventory_item_id%Type;
      l_sr_item_id                       MSC_SYSTEM_ITEMS.sr_inventory_item_id%Type;
      l_category_name                    MSC_ITEM_CATEGORIES.Category_name%Type;
      l_zone_id                          WSH_ZONE_REGIONS_V.zone_id%Type;
      l_customer_number                  RA_CUSTOMERS.customer_number%Type;
      l_partner_id                       MSC_TRADING_PARTNERS.partner_id%Type;
      l_item                             MTL_SYSTEM_ITEMS_B.segment1%Type;
      l_debug_date                       VARCHAR2(4000);
      l_no_customer_calendar             BOOLEAN := FALSE;
      l_date1                            DATE;
      l_date2                            DATE;

      i number := 0;
      

   BEGIN


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Start: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Schedule_Arrival_Date() ...');
      END IF;
      
      x_return_status := 'S';

      XX_MSC_Sourcing_Util_Pkg.Get_Location_From_Org
         (
            p_organization_id       => p_ship_from_org_id,
            x_location_id           => l_location_id,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Ship From location ID: '||l_location_id);
      END IF;      

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      XX_MSC_Sourcing_Params_Pkg.Get_Ship_To_Location
         (
            p_customer_site_id      => p_customer_site_id,
            x_ship_to_loc           => l_ship_to_location,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Ship To location: '||l_ship_to_location);
      END IF;   

      XX_MSC_Sourcing_Params_Pkg.Get_Postal_Code
         (
             p_ship_to_loc          => l_ship_to_location,
             x_postal_code          => l_postal_code,
             x_return_status        => x_return_status,
             x_msg                  => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Postal Code: '||l_postal_code);
      END IF;   

      XX_MSC_Sourcing_Util_Pkg.Get_Category_Set_ID
         (
             x_category_set_id      => l_category_set_id,
             x_return_status        => x_return_status,
             x_msg                  => x_msg
          );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Category Set ID: '||l_category_set_id);
      END IF;   

      XX_MSC_Sourcing_Util_Pkg.Get_Item_Name
         (
            p_inventory_item_id     => p_sr_item_id,
            p_organization_id       => p_ship_from_org_id,
            x_item                  => l_item,
            x_return_status         => x_return_status,
            x_msg                   => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Item Name: '||l_item);
      END IF; 

      XX_MSC_Sourcing_Params_Pkg.Get_Item_ID
         (
             p_item_name           => l_item,
             p_organization_id     => p_ship_from_org_id,
             x_item_id             => l_item_id,  
             x_sr_item_id          => l_sr_item_id,
             x_return_status       => x_return_status,
             x_msg                 => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Planning instance Item ID: '||l_item_id);
      END IF;   

      XX_MSC_Sourcing_Params_Pkg.Get_Category_Name
         (
            p_item_id              => l_item_id,
            p_org_id               => p_ship_from_org_id,
            p_category_set_id      => l_category_set_id,
            x_category_name        => l_category_name,
            x_return_status        => x_return_status,
            x_msg                  => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Category Name: '||l_category_name);
      END IF;   

      XX_MSC_Sourcing_Params_Pkg.Get_Zone
         (
             p_postal_code         => l_postal_code,
             p_category_name       => l_category_name,
             x_zone_id             => l_zone_id,
             x_return_status       => x_return_status,
             x_msg                 => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Zone ID: '||l_zone_id);
      END IF;   

      Get_Intransit_Time
         (
             p_ship_from_loc_id       => l_location_id,
             p_ship_to_region_id      => l_zone_id,
             p_ship_method            => p_ship_method,
             x_intransit_time         => l_intransit_time,
             x_return_status          => x_return_status,
             x_msg                    => x_msg
         );

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Transit time: '||l_intransit_time);
      END IF;

      -- dbms_output.put_line('-> Transit time: '||l_intransit_time);

      IF x_return_status <> 'S' THEN
         Return;
      END IF;


      BEGIN
         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.ship_method_code = p_ship_method
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CARRIER_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = CARRIER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'CARRIER'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(p_ship_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num + l_intransit_time; 

      EXCEPTION

         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (SHIP METHOD:'||p_ship_method||')';
            Return;
      END;

      XX_MSC_Sourcing_Util_Pkg.Get_Customer_Number   
         (
             p_customer_id         => p_customer_id,
             x_customer_number     => l_customer_number,
             x_return_status       => x_return_status,
             x_msg                 => x_msg
         );


      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Customer Number: '||l_customer_number);
      END IF;   

      XX_MSC_Sourcing_Util_Pkg.Get_Customer_Partner_ID
         (
            p_partner_number    => l_customer_number,
            x_partner_id        => l_partner_id,
            x_return_status     => x_return_status,
            x_msg               => x_msg
         );


      IF x_return_status <> 'S' THEN
         Return;
      END IF;     

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Partner ID: '||l_partner_id);
      END IF;   

      -- Get Customer Calendar
      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.partner_id = l_partner_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CUSTOMER_TYPE
         AND    ca.association_level= ASSOCIATION_LEVEL
         AND    ca.association_type = CUSTOMER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'RECEIVING'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(l_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num; 

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_no_customer_calendar := True;
            -- dbms_output.put_line('  -> No Customer Calendar exists.');

            IF PG_DEBUG in ('Y', 'C') THEN
               MSC_SCH_WB.ATP_Debug('  -> No Customer Calendar exists.');
            END IF;
         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. (PARTNER NUMBER:'||l_customer_number||')';
            Return;
      END;


      IF NOT l_no_customer_calendar THEN

         LOOP

            i := i+1;
            -- dbms_output.put_line('i: '||i);

            SELECT c2.calendar_date
            INTO   l_date1
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.ship_method_code = p_ship_method
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CARRIER_TYPE
            AND    ca.association_level = ASSOCIATION_LEVEL
            AND    ca.association_type = CARRIER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'CARRIER'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num;

            -- dbms_output.put_line('Date1: '||l_date1);

            SELECT c2.calendar_date
            INTO   l_date2
            FROM   msc_calendar_dates c,
                   msc_calendar_dates c2,
                   msc_calendar_assignments ca
            WHERE  ca.partner_id = l_partner_id
            AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
            AND    ca.partner_type = CUSTOMER_TYPE
            AND    ca.association_level= ASSOCIATION_LEVEL
            AND    ca.association_type = CUSTOMER_TYPE
            AND    c.calendar_code = ca.calendar_code
            AND    ca.calendar_type = 'RECEIVING'
            AND    c.sr_instance_id = ca.sr_instance_id
            AND    c.calendar_date = TRUNC(l_date) 
            AND    c2.exception_set_id = c.exception_set_id
            AND    c2.calendar_code = c.calendar_code
            AND    c2.seq_num = c.next_seq_num;

            -- dbms_output.put_line('Date2: '||l_date2);

            IF Trunc(l_date1) = Trunc(l_date2) THEN
               Exit;
            ELSE
               IF Trunc(l_date1) > Trunc(l_date2) THEN
                  l_date := l_date1;
               ELSE
                  l_date := l_date2;
               END IF;
            END IF;

            -- dbms_output.put_line('Date: '||l_date);

            IF i > 100 THEN
               x_return_status := 'E';
               x_msg := 'Check Customer/Carrier Calendars. Customer closed when carrier open and vice versa.';
               Return;
            END IF;

        END LOOP;

      END IF;


      l_debug_date := l_debug_date || ' => '||l_date;


      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Date Path: '||l_debug_date);
      END IF;

      -- dbms_output.put_line('  -> Date Path: '||l_debug_date); 


      x_arrival_date := l_date;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Arrival Date: '||x_arrival_date);
         MSC_SCH_WB.ATP_Debug('  -> End: XX_MSC_SOURCING_DATE_CALC_PKG.Get_Schedule_Arrival_Date() ...');
      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Schedule_Arrival_Date()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);

   END Get_Schedule_Arrival_Date;

   -- 22-Aug-2007 v1.1 New function for appointment scheduling
   FUNCTION Is_Carrier_Calendar_Open
     (
         p_ship_method                   IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
         p_date                          IN  DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     ) RETURN BOOLEAN AS

   BEGIN

      DECLARE

         l_date DATE;
      
      BEGIN

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.ship_method_code = p_ship_method
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CARRIER_TYPE
         AND    ca.association_level = ASSOCIATION_LEVEL
         AND    ca.association_type = CARRIER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = 'CARRIER'
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(p_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num;

         IF Trunc(l_date) = Trunc(p_date) THEN
            Return (TRUE);
         ELSE
            Return (FALSE);
         END IF;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date.';
            Return (FALSE);
         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Is_Carrier_Calendar_Open()';
            x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
            Return (FALSE);
      END;

   END Is_Carrier_Calendar_Open;

   -- 22-Aug-2007 v1.1 New function for appointment scheduling
   FUNCTION Is_Customer_Calendar_Open
     (
         p_partner_number                IN  MSC_TRADING_PARTNERS.partner_number%Type,
         p_calendar_usage                IN  VARCHAR2,	
         p_date                          IN  DATE,
         x_return_status                 OUT VARCHAR2,
         x_msg                           OUT VARCHAR2
     ) RETURN BOOLEAN AS

   BEGIN

      IF Upper(p_calendar_usage) NOT IN 
                   ('SHIPPING', 'RECEIVING') THEN
         x_return_status := 'E';
         x_msg := 'Invalid Calendar Usage.';
         Return (FALSE);

      END IF;

      DECLARE

         l_date DATE;
         l_partner_id MSC_TRADING_PARTNERS.partner_id%Type;

      BEGIN

         XX_MSC_SOURCING_UTIL_PKG.Get_Customer_Partner_ID
            (
               p_partner_number => p_partner_number,
               x_partner_id     => l_partner_id,
               x_return_status  => x_return_status,
               x_msg            => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return (FALSE);
         END IF;

         SELECT c2.calendar_date
         INTO   l_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2,
                msc_calendar_assignments ca
         WHERE  ca.partner_id = l_partner_id
         AND    ca.sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    ca.partner_type = CUSTOMER_TYPE
         AND    ca.association_level= ASSOCIATION_LEVEL
         AND    ca.association_type = CUSTOMER_TYPE
         AND    c.calendar_code = ca.calendar_code
         AND    ca.calendar_type = Upper(p_calendar_usage)
         AND    c.sr_instance_id = ca.sr_instance_id
         AND    c.calendar_date = TRUNC(p_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num; 

         IF Trunc(l_date) = Trunc(p_date) THEN
            Return (TRUE);
         ELSE
            Return (FALSE);
         END IF;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date.';
            Return (FALSE);
         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Is_Customer_Calendar_Open()';
            x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
            Return (FALSE);
      END;

   END Is_Customer_Calendar_Open;

   -- 01-Oct-2007 v1.2 New procedures for External ATP

   PROCEDURE Get_Location_Timezone_Code
      (
         p_loc_id         IN  MSC_LOCATION_ASSOCIATIONS.location_id%Type,
         x_timezone_code  OUT HR_LOCATIONS.timezone_code%Type,
         x_return_status  OUT VARCHAR2,
         x_msg            OUT VARCHAR2
      ) AS

      CURSOR c_tz (c_loc_id MSC_LOCATION_ASSOCIATIONS.location_id%Type) IS
         SELECT timezone_code
         FROM   hr_locations_v
         WHERE  location_id = c_loc_id;

   BEGIN

      x_return_status := 'S';

      OPEN  c_tz (p_loc_id);
      FETCH c_tz INTO x_timezone_code;
      CLOSE c_tz;

      IF x_timezone_code IS Null THEN
         x_return_status := 'E';
         x_msg := 'Cannot determine timezone code for location. (LOCATION ID: '||p_loc_id||')';
         Return;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Location_Timezone_Code()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Location_Timezone_Code;

   PROCEDURE Get_Carrier_Calendar
      (
          p_ship_method      IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type, 
          p_calendar_type    IN  VARCHAR2,
          x_calendar_code    OUT MSC_CALENDAR_ASSIGNMENTS.calendar_code%Type,
          x_calendar_exists  OUT BOOLEAN,
          x_return_status    OUT VARCHAR2,
          x_msg              OUT VARCHAR2
      ) AS

   BEGIN

      x_calendar_exists := TRUE;

      BEGIN
         SELECT calendar_code
         INTO   x_calendar_code
         FROM   msc_calendar_assignments
         WHERE  ship_method_code = p_ship_method
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    partner_type = CARRIER_TYPE
         AND    association_level = ASSOCIATION_LEVEL
         AND    association_type = CARRIER_TYPE
         AND    calendar_type = p_calendar_type;  

      EXCEPTION
         WHEN OTHERS THEN
            x_calendar_exists := FALSE;
      END;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Carrier_Calendar()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Carrier_Calendar;

   PROCEDURE Get_Customer_Calendar
      (
          p_partner_id       IN  MSC_TRADING_PARTNERS.partner_id%Type,  
          p_calendar_type    IN  VARCHAR2,
          x_calendar_code    OUT MSC_CALENDAR_ASSIGNMENTS.calendar_code%Type,
          x_calendar_exists  OUT BOOLEAN,
          x_return_status    OUT VARCHAR2,
          x_msg              OUT VARCHAR2
      ) AS

   BEGIN

      x_calendar_exists := TRUE;

      BEGIN
         SELECT calendar_code
         INTO   x_calendar_code
         FROM   msc_calendar_assignments ca
         WHERE  partner_id = p_partner_id
         AND    sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    partner_type = CUSTOMER_TYPE
         AND    association_level= ASSOCIATION_LEVEL
         AND    association_type = CUSTOMER_TYPE
         AND    ca.calendar_type = p_calendar_type;
      EXCEPTION
         WHEN OTHERS THEN
            x_calendar_exists := FALSE;

      END;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Customer_Calendar()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Customer_Calendar;

   PROCEDURE Get_Org_Calendar
      (
          p_org_id           IN  MTL_PARAMETERS_VIEW.organization_id%Type,  
          p_calendar_type    IN  VARCHAR2,
          x_calendar_code    OUT MSC_CALENDAR_ASSIGNMENTS.calendar_code%Type,
          x_return_status    OUT VARCHAR2,
          x_msg              OUT VARCHAR2
      ) AS

   BEGIN

      BEGIN
         SELECT calendar_code
         INTO   x_calendar_code
         FROM   msc_calendar_assignments  
         WHERE  sr_instance_id = XX_MSC_SOURCING_UTIL_PKG.SR_INSTANCE_ID
         AND    partner_type = ORGANIZATION_TYPE
         AND    association_level = ASSOCIATION_LEVEL
         AND    association_type = ORGANIZATION_TYPE
         AND    calendar_type = p_calendar_type
         AND    organization_id = p_org_id
         AND    calendar_type = p_calendar_type;  

      EXCEPTION
         WHEN OTHERS THEN
            x_return_status := 'E';
            x_msg := 'Unable to find calendar assignment. ORG ID: '||p_org_id||' TYPE: '||p_calendar_type;
      END;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Org_Calendar()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Org_Calendar;

   PROCEDURE Get_Next_Calendar_Date
      (
          p_calendar_code     IN  MSC_CALENDAR_DATES.calendar_code%Type,
          p_date              IN  DATE,
          p_days              IN  NUMBER,
          x_date              OUT DATE,
          x_calendar_exists   OUT BOOLEAN,
          x_return_status     OUT VARCHAR2,
          x_msg               OUT VARCHAR2
      ) AS

   BEGIN

       x_calendar_exists := TRUE;

       BEGIN

         SELECT c2.calendar_date
         INTO   x_date
         FROM   msc_calendar_dates c,
                msc_calendar_dates c2
         WHERE  c.calendar_date = TRUNC(p_date) 
         AND    c2.exception_set_id = c.exception_set_id
         AND    c2.calendar_code = c.calendar_code
         AND    c2.seq_num = c.next_seq_num + p_days
         AND    c2.calendar_code = p_calendar_code; 

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            x_calendar_exists := FALSE;
      END;

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_Next_Calendar_Date()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_Next_Calendar_Date;

   PROCEDURE Get_External_ATP_Dates
      (
          p_customer_number              IN  MSC_TRADING_PARTNERS.partner_number%Type,
          p_ship_method                  IN  MSC_INTERORG_SHIP_METHODS.ship_method%Type,
          p_category_name                IN  MSC_ITEM_CATEGORIES.category_name%Type,
          p_bulk                         IN  VARCHAR2,
          p_zone_id                      IN  WSH_ZONE_REGIONS_V.zone_id%Type,
          p_base_org_id                  IN  MTL_PARAMETERS_VIEW.organization_id%Type,
          p_drop_ship_cd                 IN  XX_PO_SSA_V.drop_ship_cd%Type,
          p_supply_type                  IN  XX_PO_SSA_V.supp_loc_count_ind%Type,
          p_ssa_lead_time                IN  XX_PO_SSA_V.lead_time%Type,
          p_supply_loc_no                IN  XX_PO_MLSS_DET.supply_loc_no%Type,
          p_vendor_id                    IN  XX_PO_SSA_V.vendor_id%Type,
          p_vendor_site_id               IN  XX_PO_SSA_V.vendor_site_id%Type,
          p_mlss_ds_lt                   IN  XX_PO_MLSS_DET.ds_lt%Type,
          p_mlss_b2b_lt                  IN  XX_PO_MLSS_DET.b2b_lt%Type,
          p_current_date_time            IN  DATE,
          p_timezone_code                IN  HR_LOCATIONS_V.timezone_code%Type,
          p_mlss_cutoff_time             IN  VARCHAR2,
          x_ship_date                    OUT DATE,
          x_arrival_date                 OUT DATE,
          x_ship_method                  OUT MTL_INTERORG_SHIP_METHODS.ship_method%Type,
          x_return_status                OUT VARCHAR2,
          x_msg                          OUT VARCHAR2
       ) AS

      CURSOR c_supply_loc ( c_vendor_id XX_PO_SSA_V.vendor_id%Type,
                            c_vendor_site_id XX_PO_SSA_V.vendor_site_id%Type,
                            c_supply_loc_no XX_PO_MLSS_DET.supply_loc_no%Type) IS
         SELECT calendar_code
         FROM   xx_msc_sourcing_vendor_cals
         WHERE  supply_loc_no = c_supply_loc_no
         AND    vendor_id = c_vendor_id
         AND    vendor_site_id = c_vendor_site_id;

      l_date                      DATE;
      l_date1                     DATE;
      l_date2                     DATE;
      l_ext_cal_code              MSC_CALENDAR_DATES.calendar_code%Type;
      l_base_org_cal_code         MSC_CALENDAR_DATES.calendar_code%Type;
      l_carrier_cal_code          MSC_CALENDAR_DATES.calendar_code%Type;
      l_customer_cal_code         MSC_CALENDAR_DATES.calendar_code%Type;
      l_base_loc_id               MSC_LOCATION_ASSOCIATIONS.location_id%Type;
      l_timezone_code             HR_LOCATIONS.timezone_code%Type;
      l_time                      VARCHAR2(5);
      l_ship_method               MTL_INTERORG_SHIP_METHODS.ship_method%Type;
      l_intransit_time            MSC_INTERORG_SHIP_METHODS.intransit_time%Type;
      l_partner_id                MSC_TRADING_PARTNERS.partner_id%Type;
      l_debug_date                VARCHAR2(4000);
      l_lead_time                 NUMBER;
      l_next_day                  NUMBER := 0;
      l_cust_calendar_exists      BOOLEAN := FALSE;
      l_carrier_calendar_exists   BOOLEAN := FALSE;
      l_ext_calendar_exists       BOOLEAN := TRUE;
      l_base_org_cal_exists       BOOLEAN := TRUE;
      i                           NUMBER := 0;

   BEGIN

      x_return_status := 'S';

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Supply Type: '||p_supply_type);
      END IF;

      /*
      dbms_output.put_line('  -> Supply Type: '||p_supply_type);
      */

      l_date := Trunc(Sysdate);

      l_debug_date := l_date;

      XX_MSC_SOURCING_UTIL_PKG.Get_Location_From_Org
        (
           p_organization_id       => p_base_org_id,
           x_location_id           => l_base_loc_id,
           x_return_status         => x_return_status,
           x_msg                   => x_msg
        );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      Get_Org_Calendar
         (
             p_org_id           => p_base_org_id,  
             p_calendar_type    => 'SHIPPING',
             x_calendar_code    => l_base_org_cal_code,
             x_return_status    => x_return_status,
             x_msg              => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF p_mlss_cutoff_time IS NOT Null THEN

         Get_Next_Calendar_Date
            (
                p_calendar_code     => l_base_org_cal_code,
                p_date              => l_date,
                p_days              => 0,
                x_date              => l_date,
                x_calendar_exists   => l_base_org_cal_exists,
                x_return_status     => x_return_status,
                x_msg               => x_msg
           );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF NOT l_base_org_cal_exists THEN
            x_return_status := 'E';
            x_msg := 'Unable to find a calendar date. Calendar Code: '||l_base_org_cal_code;
            Return;
         END IF;

         IF l_date = Trunc(Sysdate) THEN

            Get_Location_Timezone_Code
               (
                   p_loc_id           => l_base_loc_id,
                   x_timezone_code    => l_timezone_code, 
                   x_return_status    => x_return_status,
                   x_msg              => x_msg
               );

            IF x_return_status <> 'S' THEN
               Return;
            END IF;

            l_time := To_Char(FND_TIMEZONE_PUB.Adjust_Datetime
                (p_current_date_time,p_timezone_code,l_timezone_code), 'HH24:MI');

            IF PG_DEBUG in ('Y', 'C') THEN
               MSC_SCH_WB.ATP_Debug('  -> Location Time: '||l_time);
               MSC_SCH_WB.ATP_Debug('  -> MLS Cutoff Time: '||p_mlss_cutoff_time);
            END IF;

            /*
            dbms_output.put_line('  -> Location Time: '||l_time);
            dbms_output.put_line('  -> MLS Cutoff Time: '||p_mlss_cutoff_time);
            */

            IF l_time >= p_mlss_cutoff_time THEN
  
               l_next_day := 1;

            END IF;

         END IF;

      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Next Day: '||l_next_day);
      END IF;

      /*
      dbms_output.put_line('  -> Next Day: '||l_next_day);
      */

      SELECT Decode(p_supply_type, 'S', Nvl(p_ssa_lead_time,0), 
               Decode(p_drop_ship_cd, 'D', Nvl(p_mlss_ds_lt,0), Nvl(p_mlss_b2b_lt,0)))
      INTO   l_lead_time
      FROM  Dual;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Lead Time: '||l_lead_time);
      END IF;

      /*
      dbms_output.put_line('  -> Lead Time: '||l_lead_time);
      */

      IF p_supply_type = 'M' THEN

         OPEN c_supply_loc(p_vendor_id, p_vendor_site_id, p_supply_loc_no);
         FETCH c_supply_loc INTO l_ext_cal_code;
         CLOSE c_supply_loc;

      ELSE

         l_ext_cal_code := FND_PROFILE.Value('XX_MSC_SOURCING_SLS_CAL_CODE');

      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> MLS/SLS Calendar Code: '||l_ext_cal_code);
      END IF;

      /*
      dbms_output.put_line('  -> MLS/SLS Calendar Code: '||l_ext_cal_code);
      */

      IF l_ext_cal_code IS NOT Null THEN

         l_ext_calendar_exists := TRUE;
         Get_Next_Calendar_date
            (
               p_calendar_code    => l_ext_cal_code,
               p_date             => Trunc(Sysdate) + l_next_day,
               p_days             => l_lead_time,
               x_date             => l_date,
               x_calendar_exists  => l_ext_calendar_exists,
               x_return_status    => x_return_status,
               x_msg              => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF NOT l_ext_calendar_exists THEN
            l_ext_cal_code := Null;
         END IF;

      END IF;

      IF l_ext_cal_code IS Null THEN
   
         SELECT Trunc(Sysdate) + l_next_day + l_lead_time
         INTO   l_date
         FROM Dual;

      END IF;

      l_debug_date := l_debug_date || ' > '||l_date;

      IF p_drop_ship_cd = 'D' THEN
         x_arrival_date := l_date;
         x_ship_date := l_date;
         Return;
      END IF;

      Get_Next_Calendar_Date
         (
             p_calendar_code     => l_base_org_cal_code,
             p_date              => l_date,
             p_days              => 0,
             x_date              => l_date,
             x_calendar_exists   => l_base_org_cal_exists,
             x_return_status     => x_return_status,
             x_msg               => x_msg
        );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF NOT l_base_org_cal_exists THEN
         x_return_status := 'E';
         x_msg := 'Unable to find a calendar date. Calendar Code: '||l_base_org_cal_code;
         Return;
      END IF;

      x_ship_date := l_date;

      l_debug_date := l_debug_date || ' >> '||l_date;

      Get_Intransit_Time
         (
             p_ship_from_loc_id       => l_base_loc_id,
             p_ship_to_region_id      => p_zone_id,
             p_ship_method            => p_ship_method,
             p_category_name          => p_category_name,
             p_bulk                   => p_bulk,
             x_ship_method            => l_ship_method,
             x_intransit_time         => l_intransit_time,
             x_return_status          => x_return_status,
             x_msg                    => x_msg
         );

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Transit time: '||l_intransit_time);
         MSC_SCH_WB.ATP_Debug('  -> Ship Method: '||l_ship_method);
      END IF;

      dbms_output.put_line('  -> Transit time: '||l_intransit_time);
      dbms_output.put_line('  -> Ship Method: '||l_ship_method);

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      Get_Carrier_Calendar
         (
             p_ship_method       => l_ship_method, 
             p_calendar_type     => 'CARRIER',
             x_calendar_code     => l_carrier_cal_code,
             x_calendar_exists   => l_carrier_calendar_exists,
             x_return_status     => x_return_status,
             x_msg               => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Carrier Calendar: '||l_carrier_cal_code);
      END IF;

      /*
      dbms_output.put_line('  -> Carrier Calendar: '||l_carrier_cal_code);
      */

      IF l_carrier_calendar_exists THEN

        Get_Next_Calendar_date
            (
               p_calendar_code    => l_carrier_cal_code,
               p_date             => l_date,
               p_days             => l_intransit_time,
               x_date             => l_date,
               x_calendar_exists  => l_carrier_calendar_exists,
               x_return_status    => x_return_status,
               x_msg              => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

      END IF;

      IF l_carrier_calendar_exists THEN

         x_arrival_date := l_date;

      ELSE
   
         SELECT x_ship_date + Nvl(l_intransit_time, 0)
         INTO   x_arrival_date
         FROM Dual;

      END IF;

      l_debug_date := l_debug_date || ' > '||x_arrival_date;

      XX_MSC_Sourcing_Util_Pkg.Get_Customer_Partner_ID
         (
            p_partner_number    => p_customer_number,
            x_partner_id        => l_partner_id,
            x_return_status     => x_return_status,
            x_msg               => x_msg
         );


      IF x_return_status <> 'S' THEN
         Return;
      END IF;     

      Get_Customer_Calendar
         (
             p_partner_id       => l_partner_id,  
             p_calendar_type    => 'RECEIVING',
             x_calendar_code    => l_customer_cal_code,
             x_calendar_exists  => l_cust_calendar_exists,
             x_return_status    => x_return_status,
             x_msg              => x_msg
         );

      IF x_return_status <> 'S' THEN
         Return;
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Customer Calendar: '||l_customer_cal_code);
      END IF;

      /*
      dbms_output.put_line('  -> Customer Calendar: '||l_customer_cal_code);
      */

      l_date := x_arrival_date;

      IF l_cust_calendar_exists THEN

        Get_Next_Calendar_date
            (
               p_calendar_code    => l_customer_cal_code,
               p_date             => l_date,
               p_days             => 0,
               x_date             => x_arrival_date,
               x_calendar_exists  => l_cust_calendar_exists,
               x_return_status    => x_return_status,
               x_msg              => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF NOT l_cust_calendar_exists THEN
            x_arrival_date := x_ship_date;
         END IF;

      END IF;

      l_debug_date := l_debug_date || ' > '||x_arrival_date;

      l_date := x_arrival_date;

      WHILE l_cust_calendar_exists AND l_carrier_calendar_exists LOOP

         i := i+1;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> i: '||i);
         END IF;

         /*
         dbms_output.put_line('  -> i: '||i);
         */

         Get_Next_Calendar_date
            (
               p_calendar_code    => l_carrier_cal_code,
               p_date             => l_date,
               p_days             => 0,
               x_date             => l_date1,
               x_calendar_exists  => l_carrier_calendar_exists,
               x_return_status    => x_return_status,
               x_msg              => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Date1: '||l_date1);
         END IF;

         /*         
         dbms_output.put_line('  -> Date1: '||l_date1);
         */

         Get_Next_Calendar_date
            (
               p_calendar_code    => l_customer_cal_code,
               p_date             => l_date,
               p_days             => 0,
               x_date             => l_date2,
               x_calendar_exists  => l_cust_calendar_exists,
               x_return_status    => x_return_status,
               x_msg              => x_msg
            );

         IF x_return_status <> 'S' THEN
            Return;
         END IF;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Date2: '||l_date2);
         END IF;

         /*
         dbms_output.put_line('  -> Date2: '||l_date2);
         */

         IF Trunc(l_date1) = Trunc(l_date2) THEN
            Exit;
         ELSE
            IF Trunc(l_date1) > Trunc(l_date2) THEN
               l_date := l_date1;
            ELSE
               l_date := l_date2;
            END IF;
         END IF;

         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Date: '||l_date);
         END IF;

         /*
         dbms_output.put_line('  -> Date: '||l_date);
         */

         IF i > 100 THEN
            x_return_status := 'E';
            x_msg := 'Check Customer/Carrier Calendars. Customer closed when carrier open and vice versa.';
            Return;
         END IF;

      END LOOP;

      IF l_carrier_calendar_exists THEN
         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Carrier Calendar available');
         END IF;
         /*
         dbms_output.put_line('  -> Carrier Calendar available');
         */
      ELSE
         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> No Carrier Calendar');
         END IF; 
         /*        
         dbms_output.put_line('  -> No Carrier Calendar');
         */
      END IF;

      IF l_cust_calendar_exists THEN
         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> Customer Calendar available');
         END IF;
         /*
         dbms_output.put_line('  -> Customer Calendar available');
         */
      ELSE
         IF PG_DEBUG in ('Y', 'C') THEN
            MSC_SCH_WB.ATP_Debug('  -> No Customer Calendar');
         END IF;
         /*
         dbms_output.put_line('  -> No Customer Calendar');
         */
      END IF;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Date Path: '||l_debug_date);
      END IF;
      /*
      dbms_output.put_line('  -> Date Path: '||l_debug_date);
      */

      IF l_date IS NOT Null THEN
         x_arrival_date := l_date;
      END IF;

      x_ship_method := l_ship_method;

      l_debug_date := l_debug_date || ' > ' ||l_date;

      IF PG_DEBUG in ('Y', 'C') THEN
         MSC_SCH_WB.ATP_Debug('  -> Ship Date: '||x_ship_date); 
         MSC_SCH_WB.ATP_Debug('  -> Arrival Date: '||x_arrival_date); 
      END IF;

      /*
      dbms_output.put_line('  -> Ship Date: '||x_ship_date); 
      dbms_output.put_line('  -> Arrival Date: '||x_arrival_date); 
      */

   EXCEPTION
      WHEN OTHERS THEN
         x_return_status := 'E';
         x_msg := 'Error: XX_MSC_Sourcing_Date_Calc_Pkg.Get_External_ATP_Dates()';
         x_msg := x_msg||'-'||Substr(sqlerrm,1,120);
   END Get_External_ATP_Dates;


END XX_MSC_SOURCING_DATE_CALC_PKG;
/
