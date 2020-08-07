update apps.hr_locations_all hl set timezone_code=(select htt.name
from 
apps.HZ_TIMEZONE_mapping htm, apps.hz_timezones_tl htt,apps.hz_timezones ht 
where htm.country=hl.country and decode(htm.country,'US',htm.state,'X')
             = decode(htm.country,'US',hl.region_2,'X')
and htm.timezone_id=htt.timezone_id
and htt.timezone_id=ht.timezone_id
) 
where  hl.inactive_date is null and hl.country <> 'CA';