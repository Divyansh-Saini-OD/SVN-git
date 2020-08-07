update hr_locations_all 
set postal_code = replace(postal_code,' ','')
where inactive_date is null
and country = 'CA';

select postal_code from hr_locations_all where country = 'CA' and inactive_date is null;