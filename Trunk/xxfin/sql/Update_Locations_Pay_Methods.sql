update apps.hr_locations_all hl 
set attribute3=
    (select location_type 
     from apps_rw.xx_master_locations ml 
     where ml.needed='Y' and 
     substr(ml.descr,1,6) = substr(hl.location_code,1,6))
where hl.location_code  not in ('010000 ICM Auditable Unit',
                            '010012',
                            'OD US HEADQUARTERS',
                            '010000:CORPORATE',
                            '010012:BUNKER NC DATA CTR',
                            'OFFICE DEPOT TRADE PAYABLES',
                            'OFFICE DEPOT NON-TRADE PAYABLES',
                            'OD US ONE TIME SHIP TO LOCATION',
                            'OD US VIRTUAL V01',
                            '00708 Calgary ICM Auditable Unit',
							'010000:CORPORATE - DELRAY BEACH FL',
                            '010012:GLOBAL DATA CTR - CHARLOTTE NC',
                            '200010',
                            '200080',
                            '200500',
                            '200600',
                            '201240',
                            '201310',
                            '203390',
                            '203620',
                            'SHIP TO LOCATION',
							'003066:XDOCK - LANSING IL',
							'003066',
							'003066-4109')
and (hl.inactive_date > sysdate or hl.inactive_date is null);

update apps.ar_receipt_methods arm 
set attribute_category='North America', 
    attribute6 = (select location_code 
                  from apps.hr_locations_all hl
                  where substr(hl.location_code,1,6)=substr(arm.name,-6,6)
                  and inactive_date is null
                  and location_code not in ('010000 ICM Auditable Unit',
                                            '010012',
                                            'OD US ONE TIME SHIP TO LOCATION',
                                            'OD US VIRTUAL V01',
                                            'OFFICE DEPOT TRADE PAYABLES',
                                            'OFFICE DEPOT NON-TRADE PAYABLES',
											'003066:XDOCK - LANSING IL',
											'003066-4109')
                  )
where  receipt_class_id in (2012,2025) 
and arm.name not in ('SunTrust.0104 - 000052',
             'SunTrust.0104 - 000446',
             'zzUS_OM_CASH_000503',
             'US_OM_CASH_0000305',
             'US_OM_CASH_000705',
             'US_OM_CASH_000715');

update apps.ar_receipt_methods set attribute_category =null where attribute6 is null;
     