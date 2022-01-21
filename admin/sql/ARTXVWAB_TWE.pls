create or replace package body arp_tax_view_taxware as
/* $Header: ARTXVWAB.pls 115.21 2005/07/05 23:48:49 sanahuja ship $ */
--2662879
PG_DEBUG varchar2(1) ;

USE_SHIP_TO_GEO CONSTANT VARCHAR2(10) := 'XXXXXXXXX';

/*===========================================================================+
 | FUNCTION                                                                  |
 |    Check_Geocode                                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns TRUE if the GEOCODE seems to be valid                          |
 |    (in the format SSZZZZZGG)                                              |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/


FUNCTION Check_Geocode(p_geocode IN VARCHAR2)
RETURN BOOLEAN
IS
BEGIN
  if substrb(p_geocode, 1, 2) between 'AA' and 'ZZ' and
     substrb(p_geocode, 3, 5) between '00000' and '99999' and
     substrb(p_geocode, 8, 2) between '00' and '99' then
    return TRUE;
  end if;

  return FALSE;
END Check_Geocode;

PROCEDURE INITIALIZE IS
BEGIN
--2662879
--     PG_DEBUG  := NVL(FND_PROFILE.value('TAX_DEBUG_FLAG'), 'N');
--3062098
     PG_DEBUG  := NVL(FND_PROFILE.value('AFLOG_ENABLED'), 'N');
  /* Bug 2158220  */
     g_usenexpro := fnd_profile.value('TAXVDR_USENEXPRO');
     g_sectaxs := TO_NUMBER(fnd_profile.value('TAXVDR_SECTAXS'));
     g_taxselparam := TO_NUMBER(fnd_profile.value('TAXVDR_TAXSELPARAM'));
     g_taxtype := TO_NUMBER(fnd_profile.value('TAXVDR_TAXTYPE'));
     g_serviceind := TO_NUMBER(fnd_profile.value('TAXVDR_SERVICEIND'));
     g_orgid := TO_NUMBER(oe_profile.value('SO_ORGANIZATION_ID'));
END INITIALIZE;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    ship_to_geocode                                                        |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the geocode of the ship to location                            |
 |    ATTRIBUTE1 OF ar_location_rates                                        |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function SHIP_TO_GEOCODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number,
	p_ship_to_address_id IN NUMBER,
	p_ship_to_location_id IN NUMBER,
	p_trx_date IN DATE,
	p_ship_to_state IN VARCHAR2,
	p_postal_code IN VARCHAR2)
return VARCHAR2
is
  l_geocode varchar2(150);
begin
/*
Original ORCL Code.
  select loc.sales_tax_geocode
  into l_geocode
  from hz_cust_acct_sites acct_site,
       hz_party_sites party_site,
       hz_locations loc
  where acct_site.cust_acct_site_id = p_ship_to_address_id
    and acct_site.party_site_id = party_site.party_site_id
    and loc.location_id = party_site.location_id;

  if Check_Geocode(l_geocode) then
	return l_geocode;
  end if;

  select nvl(substrb(lr.attribute1,1,2), '00')
  into l_geocode
  from ar_location_rates lr, ar_location_combinations lc
  where lc.location_id_segment_3 = lr.location_segment_id
  and p_trx_date between nvl(lr.start_date, p_trx_date) and nvl(lr.end_date, p_trx_date)
  and p_postal_code between nvl(lr.from_postal_code, p_postal_code) and nvl(lr.to_postal_code, p_postal_code)
  and lc.location_id = p_ship_to_location_id;

  return NVL(p_ship_to_state, 'CA') || SUBSTRB(p_postal_code,1,5) || l_geocode;
*/

--
-- Added by Taxware for TWE.
-- This code modification does not depend on any location_rates.
--

 IF PG_DEBUG = 'Y' THEN
    arp_util_tax.debug( '-->TWE - Going for ST Geo:'||p_header_id ||':');
 END IF;

--
-- Commented out SQL below to test performance improvement with it.  It was deemed very inefficient SQL.
-- Todd Christensen 
--
--    SELECT  rtrim(ltrim(rad.state)) || rtrim(ltrim(rad.postal_code))
--      INTO l_geocode
--      FROM
--                 APPS.RA_ADDRESSES rad,
--                 APPS.RA_SITE_USES rasu,
--                 APPS.RA_CUSTOMER_TRX_PARTIAL_V rctp
--    WHERE
--                 rctp.customer_trx_id  = p_header_id
--             and rad.address_id        = decode(rctp.raa_ship_to_address_id, NULL, rctp.raa_bill_to_address_id,rctp.raa_ship_to_address_id)
--             and rad.ADDRESS_ID        = rasu.ADDRESS_ID
--             and rasu.SITE_USE_CODE    = 'SHIP_TO'
--             and rasu.status           = 'A';

 IF PG_DEBUG = 'Y' THEN
    arp_util_tax.debug( '-->ARP_TWE:l_shipto_geo:'||l_geocode ||':');
 END IF;

   Return l_geocode; 
exception
  when too_many_rows then
    IF PG_DEBUG = 'Y' THEN
    	arp_util_tax.debug( 'Multiple GeoCode exist for given combination of
    State '||p_ship_to_state||' GeoCode '||p_postal_code||' and Transaction date'||p_trx_date );
    END IF;
    return NVL(p_ship_to_state, 'CA')||substrb(p_postal_code,1,5)||'00';
  when no_data_found then
    return NVL(p_ship_to_state, 'CA')||substrb(p_postal_code,1,5)||'00';
end ship_to_geocode;


/*===========================================================================+
 | FUNCTION                                                                  |
 |    poa_geocode                                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the geocode of the poa location                                |
 |    POA is set to the sales rep. If this does not exist, return            |
 |    sales_tax_geocode of ar_system_parameters                              |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function POA_GEOCODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)

return VARCHAR2 is
  l_geocode Varchar2(30);
begin
/*  select sales_tax_geocode
	into l_geocode
	from ar_system_parameters;
*/
 l_geocode := arp_global.sysparam.sales_tax_geocode;

  if l_geocode is null then
    return USE_SHIP_TO_GEO;
  end if;

  if not check_geocode(l_geocode) then
    return USE_SHIP_TO_GEO;
  end if;

  return l_geocode;
exception
  when no_data_found then
	return USE_SHIP_TO_GEO;
end POA_GEOCODE;


/*===========================================================================+
 | FUNCTION                                                                  |
 |    poo_geocode                                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the geocode of the poo location                                |
 |    POA is set to the system parameters. If this does not exist,           |
 |    return                                                                 |
 |    sales_tax_geocde from ra_salesreps                                     |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function POO_GEOCODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number,
	p_salesrep_id IN Number)
return VARCHAR2 is
  l_geocode Varchar2(30);
begin
  select sales_tax_geocode
	into l_geocode
	from ra_salesreps
	where salesrep_id = p_salesrep_id;

  if l_geocode is null then
    return USE_SHIP_TO_GEO;
  end if;

  if not check_geocode(l_geocode) then
    return USE_SHIP_TO_GEO;
  end if;

  return l_geocode;
exception
  when no_data_found then
	return USE_SHIP_TO_GEO;
end POO_GEOCODE;


/*===========================================================================+
 | FUNCTION                                                                  |
 |    ship_from_geocode                                                      |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the geocode of the ship from location                          |
 |    Ship from is set to the warehouse.                                     |
 |    If this does not exist, return                                         |
 |    loc_information13 OF hr_locations_v                                    |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |     01-DEC-00    Phong La          Bugfix# 1512727: changed hr_location_v |
 |                                    to hr_locations_all                    |
 |                                                                           |
 +===========================================================================*/

function SHIP_FROM_GEOCODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number,
	p_warehouse_id IN Number)
return Varchar2 is
  l_geocode Varchar2(30);
begin
  -- bugfix 1512727 --
  select lc.loc_information13
	into l_geocode
	from hr_locations_all lc, hr_organization_units hr
	where hr.organization_id = p_warehouse_id
        and hr.location_id = lc.location_id;

  if l_geocode is null then
	return USE_SHIP_TO_GEO;
  end if;

  if not check_geocode(l_geocode) then
    return USE_SHIP_TO_GEO;
  end if;

  return l_geocode;
exception
  when no_data_found then
	return USE_SHIP_TO_GEO;
end SHIP_FROM_GEOCODE;


/*===========================================================================+
 | FUNCTION                                                                  |
 |    product_code                                                           |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the product_code                                               |
 |    Returns segment1 from MTL_SYSTEM_ITEMS.                                |
 |    Users may have a different segment for the product code.               |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |     12-AUG-99    Manoj Gudivaka    OE/OM change : replaced fnd_profile    |
 |                                    with oe_profile for profile            |
 |                                    SO_ORGANIZATION_ID                     |
 |                                                                           |
 +===========================================================================*/

function PRODUCT_CODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number,
	p_item_id IN NUMBER,
	p_memo_line_id IN NUMBER)
return VARCHAR2 is
  l_segment1 varchar2(40);
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  select segment1
  into l_segment1
  from mtl_system_items
  where inventory_item_id=p_item_id
  and organization_id= g_orgid;

  return l_segment1;
exception
 when too_many_rows then
    return to_char(NULL);
 when no_data_found then
    return to_char(NULL);
end product_code;



/*===========================================================================+
 | FUNCTION                                                                  |
 |    company_code                                                           |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the company_code.                                              |
 |    Constant value of '01'.                                                |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 |     09-AUG-2006  Camilo Paredes  Taxware/Carlson                          |
 +===========================================================================*/

function COMPANY_CODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return VARCHAR2 is
begin
  -- return '01';
  return substr(p_view_name,1,30); 
end company_code;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    division_code                                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the division_code                                              |
 |    Constant value of '01'.                                                |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function DIVISION_CODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return VARCHAR2 is
begin
  return '01';
end division_code;


/*===========================================================================+
 | FUNCTION                                                                  |
 |    vendor_control_exemptions                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the Job No. ATTRIBUTE1 of ra_cust_trx_types                    |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function VENDOR_CONTROL_EXEMPTIONS(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number,
	p_trx_type_id In Number)
return VARCHAR2 is
  l_jobno varchar2(150);
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  select attribute1
	into l_jobno
	from ra_cust_trx_types
	where cust_trx_type_id = p_trx_type_id;

  return l_jobno;
exception
when no_data_found then
  return null;
end vendor_control_exemptions;



/*===========================================================================+
 | FUNCTION                                                                  |
 |    use_nexpro                                                             |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the use nexpro flag.                                           |
 |    'Y' - use Nexpro                                                       |
 |    'N' - use Nexpro                                                       |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function Use_Nexpro (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return VARCHAR2
is
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  return g_usenexpro;
end Use_Nexpro;


/*===========================================================================+
 | FUNCTION                                                                  |
 |    use_secondary                                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the use Secondary taxes flag                                   |
 |    1 = Use secondary taxes                                                |
 |    2 = Do not use secondary taxes                                         |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function Use_Secondary (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return NUMBER
is
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  --return To_Number(fnd_profile.value_specific('TAXVDR_SECTAXS'));
    return g_sectaxs;
end Use_secondary;


/*===========================================================================+
 | FUNCTION                                                                  |
 |    Tax_Sel_Parm                                                           |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the Tax Selection parameter flag                               |
 |    2 = Use only ship-to address                                           |
 |    3 = Use only all jurisdications                                        |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function Tax_Sel_Parm (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return NUMBER
is
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  --return To_Number(fnd_profile.value_specific('TAXVDR_TAXSELPARAM'));
  return g_taxselparam;
end tax_sel_parm;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    Tax_Type                                                               |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the tax type.                                                  |
 |    '1' = Sales Tax                                                        |
 |    '2' = Use Tax                                                          |
 |    '3' = Rental                                                           |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function Tax_Type (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return NUMBER
is
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  --return To_Number(fnd_profile.value_specific('TAXVDR_TAXTYPE'));
  return g_taxtype;
end tax_type;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    Service_Indicator                                                      |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the service indicator flag                                     |
 |    1 = Service                                                            |
 |    2 = Rental                                                             |
 |    3 = Non-Service                                                        |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function Service_Indicator (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return NUMBER
is
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  --return To_Number(fnd_profile.value_specific('TAXVDR_SERVICEIND'));
  return g_serviceind;
end SERVICE_INDICATOR;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |    get_exemptions                                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the separated State/County/City/Sec Cnty/Sec City              |
 |    exemption levels.                                                      |
 |    Also returns the STEP90 flags - UseStep, StepProcFlag, CritFlag        |
 |                                                                           |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

procedure GET_EXEMPTIONS(
	p_exemption_id In Number,
	p_State_Exempt_Percent Out NOCOPY Number,
	p_State_Exempt_Reason Out NOCOPY Varchar2,
	p_State_Cert_No Out NOCOPY Varchar2,
	p_County_Exempt_Percent Out NOCOPY Number,
	p_County_Exempt_Reason Out NOCOPY Varchar2,
	p_County_Cert_No Out NOCOPY Varchar2,
	p_City_Exempt_Percent Out NOCOPY Number,
	p_City_Exempt_Reason Out NOCOPY Varchar2,
	p_City_Cert_No Out NOCOPY Varchar2,
	p_Sec_County_Exempt_Percent Out NOCOPY Number,
	p_Sec_City_Exempt_Percent Out NOCOPY Number,
	p_Use_Step Out NOCOPY Varchar2,
	p_Step_Proc_Flag Out NOCOPY Varchar2,
	p_Crit_Flag Out NOCOPY Varchar2)
is
  l_reason Varchar2(30);
  l_cert_no Varchar2(80);
  l_percent Number;
begin
  if p_exemption_id is null then
	p_State_Exempt_percent := NULL;
	p_County_Exempt_percent := NULL;
	p_City_Exempt_percent := NULL;
	p_Sec_County_Exempt_percent := NULL;
	p_Sec_City_Exempt_percent := NULL;

	p_State_Exempt_Reason := NULL;
	p_County_Exempt_Reason := NULL;
	p_City_Exempt_Reason := NULL;

	p_State_Cert_No := NULL;
	p_County_Cert_No := NULL;
	p_City_Cert_No := NULL;

	p_Use_Step := 'Y';
	p_Step_Proc_Flag := '1';
	p_Crit_Flag := 'R';

	return;
  end if;

  select
	nvl(exempt_percent1, percent_exempt),
	nvl(exempt_percent2, percent_exempt),
	nvl(exempt_percent3, percent_exempt),
	nvl(exempt_percent4, percent_exempt),
	nvl(exempt_percent5, percent_exempt),
	'N', null, null,
	reason_code, customer_exemption_number
	into
	p_State_Exempt_Percent,
	p_County_Exempt_Percent,
	p_City_Exempt_Percent,
	p_Sec_County_Exempt_Percent,
	p_Sec_City_Exempt_Percent,
	p_Use_Step,
	p_Step_Proc_Flag,
	p_Crit_Flag,
	l_reason,
	l_cert_no from ra_tax_exemptions
	where tax_exemption_id = p_exemption_id;

  p_State_Exempt_Reason := l_reason;
  p_County_Exempt_Reason := l_reason;
  p_City_Exempt_Reason := l_reason;

  p_State_Cert_No := l_cert_no;
  p_County_Cert_No := l_cert_no;
  p_City_Cert_No := l_cert_no;

exception
  when no_data_found then
    select percent_exempt,
	reason_code, customer_exemption_number
	into
	l_percent,
	l_reason,
	l_cert_no from ra_tax_exemptions
	where tax_exemption_id = p_exemption_id;

  p_State_Exempt_percent := l_percent;
  p_County_Exempt_percent := l_percent;
  p_City_Exempt_percent := l_percent;
  p_Sec_County_Exempt_percent := l_percent;
  p_Sec_City_Exempt_percent := l_percent;

  p_State_Exempt_Reason := l_reason;
  p_County_Exempt_Reason := l_reason;
  p_City_Exempt_Reason := l_reason;

  p_State_Cert_No := l_cert_no;
  p_County_Cert_No := l_cert_no;
  p_City_Cert_No := l_cert_no;

  p_Use_Step := 'N';
  p_Step_Proc_Flag := null;
  p_Crit_Flag := null;
end get_exemptions;





/*===========================================================================+
 | FUNCTION                                                                  |
 |    poa_address_code                                                       |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns POA Geocode                                                    |
 |    Character 1 = In/Out City Limits                                       |
 |    Character 2-10 = Geocode                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/


function POA_ADDRESS_CODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return Varchar2 is
  l_geocode Varchar2(30);
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  l_geocode :=
         poa_geocode(
		p_view_name,
		p_header_id,
		p_line_id);
  if l_geocode = USE_SHIP_TO_GEO then
	return USE_SHIP_TO;
  else
        return '1' || l_geocode;
  end if;
end poa_address_code;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    poo_address_code                                                       |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns POO Geocode                                                    |
 |    Character 1 = In/Out City Limits                                       |
 |    Character 2-10 = Geocode                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/


function POO_ADDRESS_CODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number,
	p_salesrep_id IN Number)
return Varchar2 is
  l_geocode Varchar2(30);
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  l_geocode :=
	poo_geocode(
		p_view_name,
		p_header_id,
		p_line_id,
		p_salesrep_id);
  if l_geocode = USE_SHIP_TO_GEO then
	return USE_SHIP_TO;
  else
        return '1' || l_geocode;
  end if;
end poo_address_code;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    ship_from_address_code                                                 |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns Ship From Geocode                                              |
 |    Character 1 = In/Out City Limits                                       |
 |    Character 2-10 = Geocode                                               |
 |                                                                           |
 | SCOPE - Private                                                           |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/


function SHIP_FROM_ADDRESS_CODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number,
	p_warehouse_id IN Number)
return Varchar2 is
  l_geocode Varchar2(30);
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

  l_geocode :=
         ship_from_geocode(
		p_view_name,
		p_header_id,
		p_line_id,
		p_warehouse_id);
  if l_geocode = USE_SHIP_TO_GEO then
	return USE_SHIP_TO;
  else
        return '1' || l_geocode;
  end if;
end ship_from_address_code;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    ship_to_address_code                                                   |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns Ship To Geocode                                                |
 |    Character 1 = In/Out City Limits                                       |
 |    Character 2-10 = Geocode                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/

function SHIP_TO_ADDRESS_CODE(
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number,
	p_ship_to_address_id In Number,
	p_ship_to_location_id In Number,
	p_trx_date In Date,
	p_ship_to_state In Varchar2,
	p_postal_code In Varchar2)
return Varchar2 is
  l_geocode Varchar2(30);
begin
  if arp_process_tax.vendor_installed_flag = 'N' then
	return NULL;
  end if;

 /*
    bug1674303. If State is more than 2 characters in length, return -99Length to the
    calling code so that this can be trapped and a suitable error message is raised
    in the Transaction form.
 */

  if lengthb(p_ship_to_state) > 2 then
     return '-99Length';
  end if;

  l_geocode :=
       ship_to_geocode(
		p_view_name,
		p_header_id,
		p_line_id,
		p_ship_to_address_id,
		p_ship_to_location_id,
		p_trx_date,
		p_ship_to_state,
		p_postal_code);
  return '1' || l_geocode;
end ship_to_address_code;


/*===========================================================================+
 | FUNCTION                                                                  |
 |    Calculation_Flag                                                       |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the levels that tax should be calculated at                    |
 |    Character 1 = Calculate tax at State                                   |
 |    Character 2 = Calculate tax at County                                  |
 |    Character 3 = Calculate tax at City                                    |
 |    Character 4 = Calculate tax at Secondary County                        |
 |    Character 5 = Calculate tax at Secondary City                          |
 |    0 = Calculate tax                                                      |
 |    1 = Do not Calculate tax                                               |
 |                                                                           |
 | SCOPE - PRIVATE                                                           |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     09-DEC-97    Kenichi Mizuta    Created                                |
 |                                                                           |
 +===========================================================================*/
function Calculation_Flag (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return Varchar2 is
  l_flag Varchar2(10) := null;
begin
  return '00000';
end Calculation_Flag;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    audit_flag                                                             |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Return appropriate audit_flag                                          |
 |                                                                           |
 | SCOPE - Public                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     20-MAY-99    Toru Kawamura    Created                                 |
 |                                                                           |
 +===========================================================================*/

function AUDIT_FLAG(
        p_view_name IN VARCHAR2,
        p_header_id IN Number,
        p_line_id IN Number)
return Varchar2 is
  l_audit_flag  Varchar2(10);
begin
  select nvl(act.attribute15, 'Y')
  into   l_audit_flag
  from   ar_receivables_trx act
  where  act.receivables_trx_id in (select adj.receivables_trx_id
                                    from   ar_adjustments adj
                                    where  adj.adjustment_id = p_header_id);
  return l_audit_flag;
exception
  when others then
    return 'Y';
end audit_flag;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    total_tax                                                              |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Return total tax amount for an invoice                                 |
 |    This function is used in view TAX_ADJUSTMENTS_V_A and                  |
 |    TAX_ADJUSTMENTS_V_V                                                    |
 |                                                                           |
 | SCOPE - Public                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     14-JUN-99    Nilesh Patel     Created                                 |
 |                                                                           |
 +===========================================================================*/

function total_tax(
        p_customer_trx_id IN Number
                   )
        return number is
        l_amount number;
begin
        select sum(extended_amount) into l_amount
        from   ra_customer_trx_lines
        where  customer_trx_id = p_customer_trx_id
        and line_type = 'TAX';
        return l_amount;
exception
        when others then
        return 0;
end total_tax;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    customer_code                                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the customer code to be passed to Taxware                      |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     03-SEP-03    Santosh Vaze      Created (Bug # 3139351)                |
 |     16-JUL-04    Debasis Choudhuri        BUG 3768303                     |
 |                                                                           |
 +===========================================================================*/

function customer_code (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return VARCHAR2
--bug 3768303return NUMBER
is
begin
  return arp_tax.tax_info_rec.bill_to_customer_number;
exception
 when others then
    IF PG_DEBUG = 'Y' THEN
    	arp_util_tax.debug('ARP_TAX_VIEW_TAXWARE.CUSTOMER_CODE EXCEPTION ERROR:'|| SQLERRM);
    END IF;
end customer_code;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    transaction_date                                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the transaction date to be passed to Vertex                    |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     29-Jun-2005 Sanjeev Ahuja      Created                                |
 |                                                                           |
 +===========================================================================*/

function transaction_date (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return  DATE
-- Bug 4175816 return DATE
is
begin
  return arp_tax.tax_info_rec.gl_date;
exception
 when others then
    IF PG_DEBUG = 'Y' THEN
    	arp_util_tax.debug('ARP_TAX_VIEW_VERTEX.TRANSACTION_DATE EXCEPTION ERROR:'|| SQLERRM);
    END IF;
end transaction_date;

/*===========================================================================+
 | FUNCTION                                                                  |
 |    customer_name                                                          |
 |                                                                           |
 | DESCRIPTION                                                               |
 |    Returns the customer name to be passed to Taxware                      |
 |                                                                           |
 | SCOPE - PUBLIC                                                            |
 |                                                                           |
 | MODIFICATION HISTORY                                                      |
 |     03-SEP-03    Santosh Vaze      Created (Bug # 3139351)                |
 |                                                                           |
 +===========================================================================*/

function customer_name (
	p_view_name IN VARCHAR2,
	p_header_id IN Number,
	p_line_id IN Number)
return VARCHAR2
is
begin
  return arp_tax.tax_info_rec.bill_to_customer_name;
exception
 when others then
    IF PG_DEBUG = 'Y' THEN
    	arp_util_tax.debug('ARP_TAX_VIEW_VERTEX.CUSTOMER_NAME EXCEPTION ERROR:'|| SQLERRM);
    END IF;
end customer_name;

/* For bug 2158220 and 2287506 */
BEGIN /* Package Constructor */

--  IF PG_DEBUG = 'Y' THEN
--  	arp_util_tax.debug( 'arp_tax_vendor.constructor+');
--  END IF;
  initialize;
  IF PG_DEBUG = 'Y' THEN
  	arp_util_tax.debug( 'arp_tax_taxware_view.constructor+-');
  END IF;

end ARP_TAX_VIEW_TAXWARE;
/
sho errors
