create or replace package body zx_r11i_tax_partner_pkg AS
/* $Header: zxir11ipartnerpkgb.pls 120.40.12020000.8 2014/11/03 17:09:51 ssanka ship $ */

G_PKG_NAME                  CONSTANT VARCHAR2(30) := 'ZX_R11I_TAX_PARTNER_PKG';
G_CURRENT_RUNTIME_LEVEL     CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_UNEXPECTED          CONSTANT NUMBER       := FND_LOG.LEVEL_UNEXPECTED;
G_LEVEL_ERROR               CONSTANT NUMBER       := FND_LOG.LEVEL_ERROR;
G_LEVEL_EXCEPTION           CONSTANT NUMBER       := FND_LOG.LEVEL_EXCEPTION;
G_LEVEL_EVENT               CONSTANT NUMBER       := FND_LOG.LEVEL_EVENT;
G_LEVEL_PROCEDURE           CONSTANT NUMBER       := FND_LOG.LEVEL_PROCEDURE;
G_LEVEL_STATEMENT           CONSTANT NUMBER       := FND_LOG.LEVEL_STATEMENT;
G_MODULE_NAME               CONSTANT VARCHAR2(30) := 'ZX.PLSQL.ZX_R11I_TAX_PTNR_PKG.';

G_LINES_PER_FETCH       CONSTANT  NUMBER:= 1000;
G_MAX_LINES_PER_FETCH   CONSTANT  NUMBER:= 1000000;
/* ======================================================================*
 | Global Structure Data Types                                           |
 * ======================================================================*/

TYPE NUMBER_tbl_type            IS TABLE OF NUMBER         INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_1_tbl_type        IS TABLE OF VARCHAR2(1)    INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_2_tbl_type        IS TABLE OF VARCHAR2(2)    INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_15_tbl_type       IS TABLE OF VARCHAR2(15)   INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_30_tbl_type       IS TABLE OF VARCHAR2(30)   INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_40_tbl_type       IS TABLE OF VARCHAR2(40)   INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_80_tbl_type       IS TABLE OF VARCHAR2(80)   INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_50_tbl_type       IS TABLE OF VARCHAR2(50)   INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_240_tbl_type      IS TABLE OF VARCHAR2(240)  INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_300_tbl_type      IS TABLE OF VARCHAR2(300)  INDEX BY BINARY_INTEGER;
TYPE VARCHAR2_360_tbl_type      IS TABLE OF VARCHAR2(360)  INDEX BY BINARY_INTEGER;
TYPE DATE_tbl_type              IS TABLE OF DATE           INDEX BY BINARY_INTEGER;

TYPE ZX_PTNR_NEG_LINE_TYPE IS RECORD (
INTERNAL_ORGANIZATION_ID		NUMBER_tbl_type	,
EVENT_CLASS_MAPPING_ID			NUMBER_tbl_type,
TRX_ID					NUMBER_tbl_type,
ENTITY_CODE				VARCHAR2_30_tbl_type,
EVENT_CLASS_CODE			VARCHAR2_30_tbl_type,
APPLICATION_ID				NUMBER_tbl_type,
TRX_DATE				DATE_tbl_type,
TRX_CURRENCY_CODE			VARCHAR2_15_tbl_type,
TRX_NUMBER				VARCHAR2_240_tbl_type,
RECORD_TYPE_CODE			VARCHAR2_30_tbl_type,
TRX_LINE_ID				NUMBER_tbl_type,
TRX_LEVEL_TYPE				VARCHAR2_30_tbl_type,
LINE_LEVEL_ACTION			VARCHAR2_30_tbl_type,
TRX_LINE_DATE				DATE_tbl_type,
LINE_AMT				NUMBER_tbl_type,
TRX_LINE_QUANTITY			NUMBER_tbl_type,
UNIT_PRICE				NUMBER_tbl_type,
PRODUCT_ID				NUMBER_tbl_type,
PRODUCT_ORG_ID				NUMBER_tbl_type,
UOM_CODE				VARCHAR2_30_tbl_type,
PRODUCT_TYPE				VARCHAR2_240_tbl_type,
PRODUCT_CODE				VARCHAR2_300_tbl_type,
FOB_POINT				VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_TYPE1			VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_VALUE1		VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_TYPE2			VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_VALUE2		VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_TYPE3			VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_VALUE3		VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_TYPE4			VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_VALUE4		VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_TYPE5			VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_VALUE5		VARCHAR2_30_tbl_type,
SHIP_TO_GEOGRAPHY_TYPE6			VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_VALUE6		VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_TYPE7			VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_VALUE7		VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_TYPE8			VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_VALUE8		VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_TYPE9			VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_VALUE9		VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_TYPE10		VARCHAR2_30_tbl_type  ,
SHIP_TO_GEOGRAPHY_VALUE10		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE1		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE1		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE2		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE2		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE3		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE3		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE4		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE4		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE5		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE5		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE6		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE6		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE7		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE7		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE8		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE8		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE9		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE9		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_TYPE10		VARCHAR2_30_tbl_type  ,
SHIP_FROM_GEOGRAPHY_VALUE10		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE1			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE1		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE2			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE2		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE3			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE3		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE4			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE4		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE5			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE5		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE6			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE6		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE7			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE7		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE8			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE8		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE9			VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE9		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_TYPE10		VARCHAR2_30_tbl_type  ,
BILL_TO_GEOGRAPHY_VALUE10		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE1		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE1		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE2		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE2		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE3		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE3		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE4		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE4		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE5		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE5		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE6		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE6		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE7		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE7		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE8		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE8		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE9		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_VALUE9		VARCHAR2_30_tbl_type  ,
BILL_FROM_GEOGRAPHY_TYPE10		VARCHAR2_30_tbl_type,
BILL_FROM_GEOGRAPHY_VALUE10		VARCHAR2_30_tbl_type,
SHIP_FROM_LOCATION_ID                   NUMBER_tbl_type,
SHIP_TO_LOCATION_ID                     NUMBER_tbl_type,
BILL_TO_LOCATION_ID                     NUMBER_tbl_type,
BILL_FROM_LOCATION_ID                   NUMBER_tbl_type,
ACCOUNT_CCID				NUMBER_tbl_type,
APPL_FROM_TRX_ID			NUMBER_tbl_type,
APPL_FROM_LINE_ID			NUMBER_tbl_type,
APPL_FROM_TRX_LEVEL_TYPE		VARCHAR2_30_tbl_type,
APPL_FROM_TRX_NUMBER			VARCHAR2_240_tbl_type,
ADJUSTED_DOC_TRX_ID			NUMBER_tbl_type,
ADJUSTED_DOC_LINE_ID			NUMBER_tbl_type,
ADJUSTED_DOC_TRX_LEVEL_TYPE		VARCHAR2_30_tbl_type,
EXEMPT_CERTIFICATE_NUMBER		VARCHAR2_80_tbl_type,
EXEMPT_REASON				VARCHAR2_240_tbl_type,
EXEMPTION_CONTROL_FLAG			VARCHAR2_1_tbl_type,
SHIP_FROM_PARTY_TAX_PROF_ID		NUMBER_tbl_type,
BILL_FROM_PARTY_TAX_PROF_ID		NUMBER_tbl_type,
SHIP_TO_SITE_TAX_PROF_ID		NUMBER_tbl_type,
SHIP_TO_PARTY_TAX_PROF_ID		NUMBER_tbl_type,
BILL_TO_CUST_ACCT_SITE_USE_ID	        NUMBER_tbl_type,
BILL_TO_SITE_TAX_PROF_ID		NUMBER_tbl_type,
BILL_TO_PARTY_TAX_PROF_ID		NUMBER_tbl_type,
TRADING_HQ_SITE_TAX_PROF_ID			NUMBER_tbl_type,
TRADING_HQ_PARTY_TAX_PROF_ID    		NUMBER_tbl_type,
SHIP_THIRD_PTY_ACCT_ID			NUMBER_tbl_type,     -- Bug 4939819
BILL_THIRD_PTY_ACCT_ID			NUMBER_tbl_type,
ADJUSTED_DOC_APPLICATION_ID		NUMBER_tbl_type,
ADJUSTED_DOC_ENTITY_CODE		VARCHAR2_30_tbl_type,
ADJUSTED_DOC_EVENT_CLASS_CODE		VARCHAR2_30_tbl_type,
SHIP_TO_PARTY_NAME			VARCHAR2_360_tbl_type,
SHIP_FROM_PARTY_NAME			VARCHAR2_360_tbl_type,
BILL_FROM_PARTY_NAME			VARCHAR2_360_tbl_type,
BILL_TO_PARTY_NAME			VARCHAR2_360_tbl_type,
SHIP_TO_PARTY_NUMBER			VARCHAR2_30_tbl_type,
SHIP_FROM_PARTY_NUMBER			VARCHAR2_30_tbl_type,
BILL_FROM_PARTY_NUMBER			VARCHAR2_30_tbl_type,
BILL_TO_PARTY_NUMBER			VARCHAR2_30_tbl_type,
TAX_PROVIDER_ID				NUMBER_tbl_type,
TAX_REGIME_CODE				VARCHAR2_30_tbl_type,
LINE_EXT_VARCHAR_ATTRIBUTE1		VARCHAR2_240_tbl_type,
LINE_EXT_VARCHAR_ATTRIBUTE2		VARCHAR2_240_tbl_type,
LINE_EXT_VARCHAR_ATTRIBUTE3		VARCHAR2_240_tbl_type,
LINE_EXT_VARCHAR_ATTRIBUTE4		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE5 		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE6 		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE7		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE8 		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE9 		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE10		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE11		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE12		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE13		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE14		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE15		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE16		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE17		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE18		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE19		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE20		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE21		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE22		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE23		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE24		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE25		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE26		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE27		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE28		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE29		VARCHAR2_240_tbl_type ,
LINE_EXT_VARCHAR_ATTRIBUTE30		VARCHAR2_240_tbl_type ,
LINE_EXT_NUMBER_ATTRIBUTE1		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE2		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE3		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE4		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE5		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE6		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE7		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE8		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE9		NUMBER_tbl_type,
LINE_EXT_NUMBER_ATTRIBUTE10		NUMBER_tbl_type,
LINE_EXT_DATE_ATTRIBUTE1		DATE_tbl_type,
LINE_EXT_DATE_ATTRIBUTE2		DATE_tbl_type,
LINE_EXT_DATE_ATTRIBUTE3		DATE_tbl_type,
LINE_EXT_DATE_ATTRIBUTE4		DATE_tbl_type,
LINE_EXT_DATE_ATTRIBUTE5		DATE_tbl_type,
SHIP_TO_CUST_ACCT_SITE_USE_ID		NUMBER_tbl_type,
SHIP_THIRD_PTY_ACCT_SITE_ID		NUMBER_tbl_type,
BILL_THIRD_PTY_ACCT_SITE_ID		NUMBER_tbl_type,
RECEIVABLES_TRX_TYPE_ID                 NUMBER_tbl_type,
ADJUSTED_DOC_DATE			DATE_tbl_type --Bug14756523
);

zx_ptnr_neg_lines_tab ZX_PTNR_NEG_LINE_TYPE;/*Global table declaration*/
i                                       NUMBER;
g_vertex_installed                      BOOLEAN;
g_taxware_installed                     BOOLEAN;

Procedure get_service_provider(p_org_id IN NUMBER,
                               p_le_id IN NUMBER,
                               x_provider_id OUT NOCOPY NUMBER,
                               x_return_status  OUT NOCOPY VARCHAR2) is

l_use_Le_As_Subscriber_Flag    zx_party_tax_profile.Use_Le_As_Subscriber_Flag%type;
l_party_tax_profile_id         zx_party_tax_profile.party_tax_profile_id%type;
l_provider_id number;
l_return_status varchar2(50);
x_msg_count       VARCHAR2(50);
x_msg_data        VARCHAR2(50);
x_effective_date  DATE;

CURSOR  get_ou_name_csr(c_org_id   NUMBER) is
 SELECT name
   FROM hr_all_organization_units
  WHERE organization_id = c_org_id;
l_ou_name        VARCHAR2(240);

Begin

if p_org_id is NOT NULL then
 if p_le_id is NULL then
   begin
   SELECT Use_Le_As_Subscriber_Flag,
          party_tax_profile_id
   INTO   l_use_Le_As_Subscriber_Flag,
          l_party_tax_profile_id
   FROM zx_party_tax_profile
   WHERE party_id = p_org_id
   AND Party_Type_Code = 'OU';
   exception when others then
/* This error should be: not able to find PTP for the input OU */
     FND_MESSAGE.SET_NAME('ZX', 'ZX_PARTY_NOT_EXISTS');
     BEGIN
       OPEN  get_ou_name_csr(p_org_id);
       FETCH get_ou_name_csr INTO l_ou_name;
       CLOSE get_ou_name_csr;
     EXCEPTION
       WHEN OTHERS THEN NULL;
     END;

     FND_MESSAGE.SET_TOKEN('PARTY_TYPE','OU');
     FND_MESSAGE.SET_TOKEN('PARTY_NAME',l_ou_name);
     x_return_status := FND_API.G_RET_STS_ERROR;
     return;
   end;

   if nvl(l_use_le_as_subscriber_flag,'N') = 'N' then
      if l_party_tax_profile_id IS NULL THEN
/* This error should be: not able to find PTP for the input OU */
         x_return_status := FND_API.G_RET_STS_ERROR;
         FND_MESSAGE.SET_NAME('ZX', 'ZX_PARTY_NOT_EXISTS');

         BEGIN
           OPEN  get_ou_name_csr(p_org_id);
           FETCH get_ou_name_csr INTO l_ou_name;
           CLOSE get_ou_name_csr;
         EXCEPTION
           WHEN OTHERS THEN NULL;
         END;

         FND_MESSAGE.SET_TOKEN('PARTY_TYPE','OU');
         FND_MESSAGE.SET_TOKEN('PARTY_NAME',l_ou_name);
         return;
      else
         zx_security.set_security_context(p_first_party_org_id => l_party_tax_profile_id,
                p_effective_date => SYSDATE,
                x_return_status => l_return_status);
      end if;
   else
       /* We will return null x_provider_id if product does not pass LE
        but use_le_as_subscriber_flag is checked 'Y' at PTP */
      x_return_status := FND_API.G_RET_STS_SUCCESS;
      return;
   end if;
 else
 -- if p_org_id is NOT NULL and p_le_id is NOT NULL then
   zx_api_pub.set_tax_security_context(
                p_api_version => 1.0  ,
                p_init_msg_list =>NULL,
                p_commit        => 'N',
                p_validation_level => 1,
                x_msg_count =>x_msg_count,
                x_msg_data =>x_msg_data,
                p_internal_org_id => p_org_id,
                p_legal_entity_id => p_le_id,
                p_transaction_date => SYSDATE,
                p_related_doc_date => NULL,
                p_adjusted_doc_date =>NULL,
                x_effective_date    =>x_effective_date,
                x_return_status => l_return_status);

 end if;

/*    As per bug 3985196, the regime codes have been hard coded */

   If(l_return_status=FND_API.G_RET_STS_SUCCESS) then

        ZX_TPI_SERVICES_PKG.get_service_provider (p_application_id => 222,
                p_entity_code => 'TRANSACTIONS',
                p_event_class_code => 'INVOICE',
                p_tax_regime_code => 'US-SALES-TAX-VERTEX',
                x_provider_id => l_provider_id,
                x_return_status => l_return_status);

      if nvl(x_provider_id, -1) <> 1 then
         ZX_TPI_SERVICES_PKG.get_service_provider (p_application_id => 222,
                p_entity_code => 'TRANSACTIONS',
                p_event_class_code => 'INVOICE',
                p_tax_regime_code => 'US-SALES-TAX-TAXWARE',
                x_provider_id => l_provider_id,
                x_return_status => l_return_status);
      end if;
    end if;
    x_return_status:=l_return_status;
    x_provider_id  :=l_provider_id;
end if;

end ;

FUNCTION IS_CITY_LIMIT_VALID(p_organization_id IN NUMBER,
                             p_legal_entity_id IN NUMBER,
                             p_city_limit IN VARCHAR2) return boolean is
l_provider_id number;
l_return_status varchar2(200);
 BEGIN

    return is_city_limit_valid(p_city_limit);

 END ;

FUNCTION IS_GEOCODE_VALID(p_organization_id IN NUMBER,
                          p_legal_entity_id IN NUMBER,
                          p_geocode IN VARCHAR2)return BOOLEAN is
l_provider_id number;
l_return_status varchar2(200);

 BEGIN

      return is_geocode_valid(p_geocode);

 END ;


FUNCTION TAX_VENDOR_EXTENSION(p_organization_id IN NUMBER,
                              p_legal_entity_id IN NUMBER)return BOOLEAN is
l_provider_id number;
l_return_status varchar2(200);
l_api_name           CONSTANT VARCHAR2(80) := 'TAX_VENDOR_EXTENSION';

 BEGIN

    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;

    return TAX_VENDOR_EXTENSION;

 END TAX_VENDOR_EXTENSION;

/* Bug 5139634: Overloaded api for city limit validation without requiring OU/LE context.
*/
FUNCTION IS_CITY_LIMIT_VALID(p_city_limit IN VARCHAR2) return BOOLEAN IS
l_api_name           CONSTANT VARCHAR2(80) := 'IS_CITY_LIMIT_VALID';

BEGIN

  IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
     FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
  END IF;

  IF p_city_limit IS NULL THEN
     IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Null city limit passed.');
     END IF;
     IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
     END IF;
     return TRUE;
  END IF;

  IF g_vertex_installed THEN
     IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Validating City Limit for Vertex.');
     END IF;
     IF ZX_TAX_VERTEX_PKG.IS_CITY_LIMIT_VALID(p_city_limit) THEN
        IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
        END IF;
        return TRUE;
     ELSE
        IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
        END IF;
        return FALSE;
     END IF;
  END IF;

  IF g_taxware_installed THEN
     IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Validating City Limit for Taxware.');
     END IF;
     IF ZX_TAX_TAXWARE_PKG.IS_CITY_LIMIT_VALID(p_city_limit) THEN
        IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
        END IF;
        return TRUE;
     ELSE
        IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
        END IF;
        return FALSE;
     END IF;
  END IF;

  -- Bug 5331410, Now for eBTax also, we are capturing City Limit.

  IF (p_city_limit IN (0,1)) THEN
     IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
     END IF;
     return TRUE;
  ELSE
     IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
     END IF;
     return FALSE;
  END IF;

END IS_CITY_LIMIT_VALID;

/* Bug 5139634: Overloaded api for geocode validation without requiring OU/LE context.
*/
FUNCTION IS_GEOCODE_VALID(p_geocode IN VARCHAR2) return BOOLEAN IS
l_api_name           CONSTANT VARCHAR2(80) := 'IS_GEOCODE_VALID';

BEGIN

  IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
     FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
  END IF;

  IF p_geocode IS NULL THEN
     IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Null geocode passed.');
     END IF;
     IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
     END IF;
     return TRUE;
  END IF;

  IF g_vertex_installed THEN
     IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Validating Geocode for Vertex.');
     END IF;
     IF ZX_TAX_VERTEX_PKG.IS_GEOCODE_VALID(p_geocode) THEN
        IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
        END IF;
        return TRUE;
     END IF;
  END IF;

  IF g_taxware_installed THEN
     IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Validating Geocode for Taxware.');
     END IF;
     IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
     END IF;
     return ZX_TAX_TAXWARE_PKG.IS_GEOCODE_VALID(p_geocode);
  END IF;

  IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
  END IF;
  return FALSE;

END IS_GEOCODE_VALID;

/* Bug 5139634: This function checks if Vertex and/or Taxware has been installed in the customer instance
                and accordingly return the existence of partner to the calling product.
*/
FUNCTION TAX_VENDOR_EXTENSION return BOOLEAN is
l_api_name           CONSTANT VARCHAR2(80) := 'TAX_VENDOR_EXTENSION';

BEGIN

    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;

/*  Check if Vertex Q-Series have been installed in the customer instance */

    IF nvl(g_vertex_installed, ZX_TAX_VERTEX_PKG.INSTALLED) THEN
       g_vertex_installed := TRUE;
    ELSE
       g_vertex_installed := FALSE;
    END IF;

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       IF g_vertex_installed THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Vertex is installed');
       ELSE
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Vertex is not installed');
       END IF;
    END IF;

    IF nvl(g_taxware_installed, ZX_TAX_TAXWARE_PKG.INSTALLED) THEN
       g_taxware_installed := TRUE;
    ELSE
       g_taxware_installed := FALSE;
    END IF;

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
     --Bug 7299805: Modified the incorrect check for taxware installation
	 --IF g_vertex_installed THEN
	   IF g_taxware_installed THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Taxware is installed');
       ELSE
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Taxware is not installed');
       END IF;
    END IF;

    IF ( g_vertex_installed OR g_taxware_installed ) THEN
       IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
       END IF;
       return TRUE;
    ELSE
       IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
       END IF;
       return FALSE;
    END IF;

END TAX_VENDOR_EXTENSION;

PROCEDURE ship_to_geo_names_derive(p_trx_copy_for_tax_update IN VARCHAR2) IS
  l_geography_id      number;
  l_geography_code    varchar2(30);
  l_return_status     varchar2(20);
  l_api_name          CONSTANT VARCHAR2(80) := 'SHIP_TO_GEO_NAMES_DERIVE';
 BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;
   IF nvl(p_trx_copy_for_tax_update, 'N') = 'Y' OR
      ZX_API_PUB.G_PUB_SRVC = 'GLOBAL_DOCUMENT_UPDATE' THEN                  -- Bug 5200373
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE1(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE1(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE2(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE2(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE3(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE3(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE4(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE4(i) := NULL;             -- Bug 5200373
   ELSE
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE1(i) := 'STATE';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.ship_to_location_id(i),
 						p_location_type => 'SHIP_TO',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE1(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE1(i)   ,
 						x_return_status =>l_return_status);
 	 ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE2(i):='COUNTY';
          ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.ship_to_location_id(i),
 						p_location_type => 'SHIP_TO',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE2(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE2(i)   ,
 						x_return_status =>l_return_status);
 	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE3(i):='CITY';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.ship_to_location_id(i),
 						p_location_type => 'SHIP_TO',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE3(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE3(i)   ,
 						x_return_status =>l_return_status);
 	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE4(i):='POSTAL_CODE';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id =>ZX_PTNR_NEG_LINES_TAB.ship_to_location_id(i),
 						p_location_type => 'SHIP_TO',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE4(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE4(i)   ,
 						x_return_status =>l_return_status);
   END IF;
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

  END ship_to_geo_names_derive;

PROCEDURE ship_from_geo_names_derive(p_trx_copy_for_tax_update IN VARCHAR2) IS
  l_geography_id      number;
  l_geography_code    varchar2(30);
  l_return_status     varchar2(20);
  l_api_name          CONSTANT VARCHAR2(80) := 'SHIP_FROM_GEO_NAMES_DERIVE';
 BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;

   IF nvl(p_trx_copy_for_tax_update, 'N') = 'Y' OR
      ZX_API_PUB.G_PUB_SRVC = 'GLOBAL_DOCUMENT_UPDATE' THEN                  -- Bug 5200373
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE1(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE1(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE2(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE2(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE3(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE3(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE4(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE4(i) := NULL;        -- Bug 5200373
   ELSE
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE1(i):='STATE';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_location_id(i),
 						p_location_type => 'SHIP_FROM',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE1(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE1(i)   ,
 						x_return_status =>l_return_status);
 	 ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE2(i):='COUNTY';
          ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_location_id(i),
 						p_location_type => 'SHIP_FROM',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE2(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE2(i)   ,
 						x_return_status =>l_return_status);
 	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE3(i):='CITY';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_location_id(i),
 						p_location_type => 'SHIP_FROM',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE3(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE3(i)   ,
 						x_return_status =>l_return_status);
 	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE4(i):='POSTAL_CODE';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_location_id(i),
 						p_location_type => 'SHIP_FROM',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE4(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE4(i)   ,
 						x_return_status =>l_return_status);
   END IF;
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

END ship_from_geo_names_derive;

PROCEDURE bill_from_geo_names_derive(p_trx_copy_for_tax_update IN VARCHAR2) IS
  l_geography_id      number;
  l_geography_code    varchar2(30);
  l_return_status     varchar2(20);
  l_api_name          CONSTANT VARCHAR2(80) := 'BILL_FROM_GEO_NAMES_DERIVE';
 BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;

   IF nvl(p_trx_copy_for_tax_update, 'N') = 'Y' OR
      ZX_API_PUB.G_PUB_SRVC = 'GLOBAL_DOCUMENT_UPDATE' THEN                  -- Bug 5200373
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE1(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE1(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE2(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE2(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE3(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE3(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE4(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE4(i) := NULL;         -- Bug 5200373
   ELSE
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE1(i):='STATE';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.BILL_FROM_location_id(i),
 						p_location_type => 'BILL_FROM',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE1(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE1(i)   ,
 						x_return_status =>l_return_status);
 	 ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE2(i):='COUNTY';
          ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.BILL_FROM_location_id(i),
 						p_location_type => 'BILL_FROM',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE2(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE2(i)   ,
 						x_return_status =>l_return_status);
 	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE3(i):='CITY';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.BILL_FROM_location_id(i),
 						p_location_type => 'BILL_FROM',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE3(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE3(i)   ,
 						x_return_status =>l_return_status);
 	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE4(i):='POSTAL_CODE';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.BILL_FROM_location_id(i),
 						p_location_type => 'BILL_FROM',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE4(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE4(i)   ,
 						x_return_status =>l_return_status);
   END IF;
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

END bill_from_geo_names_derive;

PROCEDURE bill_to_geo_names_derive(p_trx_copy_for_tax_update IN VARCHAR2) IS
  l_geography_id      number;
  l_geography_code    varchar2(30);
  l_return_status     varchar2(20);
  l_api_name          CONSTANT VARCHAR2(80) := 'BILL_TO_GEO_NAMES_DERIVE';
 BEGIN

   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;

   IF nvl(p_trx_copy_for_tax_update, 'N') = 'Y' OR
      ZX_API_PUB.G_PUB_SRVC = 'GLOBAL_DOCUMENT_UPDATE' THEN                  -- Bug 5200373
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE1(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE1(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE2(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE2(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE3(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE3(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE4(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE4(i) := NULL;      -- Bug 5200373
   ELSE
      ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE1(i):='STATE';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.BILL_TO_location_id(i),
 						p_location_type => 'BILL_TO',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE1(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  => ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE1(i)   ,
 						x_return_status => l_return_status);
 	 ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE2(i):='COUNTY';
          ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.BILL_TO_location_id(i),
 						p_location_type => 'BILL_TO',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE2(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  => ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE2(i)   ,
 						x_return_status => l_return_status);
 	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE3(i):='CITY';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.BILL_TO_location_id(i),
 						p_location_type => 'BILL_TO',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE3(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE3(i)   ,
 						x_return_status =>l_return_status);
 	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE4(i):='POSTAL_CODE';
 	ZX_TCM_GEO_JUR_PKG.get_master_geography(p_location_id => ZX_PTNR_NEG_LINES_TAB.BILL_TO_location_id(i),
 						p_location_type => 'BILL_TO',
 						p_geography_type => ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE4(i)  ,
 						x_geography_id  => l_geography_id    ,
 						x_geography_code =>  l_geography_code  ,
 						x_geography_name  =>ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE4(i)   ,
 						x_return_status =>l_return_status);
   END IF;
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

END bill_to_geo_names_derive;


/* Bug 4939819
The source of party number and name information varies depending upon the family group.

For O2C products, the information can be derived as follows.
Party Type         PTP known   Other Info              Derivation Logic
---------------    -----       -----------             ----------------
SHIP/BILL TO       Y                                   Via ZX_PARTY_TAX_PROFILE, HZ_PARTIES

SHIP/BILL TO       N           SHIP_THIRD_PTY_ACCT_ID  Via HZ_CUST_ACCOUNTS, HZ_PARTIES
In this case, SHIP_THIRD_PTY_ACCT_ID holds value of CUST_ACCOUNT_ID from HZ_CUST_ACCOUNTS.

SHIP/BILL FROM     Y                                   Via ZX_PARTY_TAX_PROFILE, HZ_PARTIES
As per Desh's update in the bug, If a eBiz customer wants to pass first party inv org id in
Rel 12 with new partner integration, he must do legal to business association using LE form.
That would create a PTP for the first party inv org.
Hence, there will be a record in HZ_PARTIES and is correct to derive info from HZ_PARTIES.

SHIP/BILL FROM     N                                   NULL (PTP is always expected)

-------------------------------------------------------------------------------------------
For P2P products, the information can be derived as follows.
Party Type         PTP known   Other Info              Derivation Logic
---------------    -----       -----------             ----------------
SHIP/BILL TO       Y                                   Via ZX_PARTY_TAX_PROFILE, HZ_PARTIES
As per Desh's update in the bug, If a eBiz customer wants to pass first party inv org id in
Rel 12 with new partner integration, he must do legal to business association using LE form.
That would create a PTP for the first party inv org.
Hence, there will definitely be record in HZ_PARTIES.

SHIP/BILL TO       N                                   NULL (PTP is always expected)

SHIP/BILL FROM     Y                                   Via ZX_PARTY_TAX_PROFILE, HZ_PARTIES

SHIP/BILL FROM     N           SHIP_THIRD_PTY_ACCT_ID  Via PO_VENDORS
In this case, SHIP_THIRD_PTY_ACCT_ID holds value of VENDOR_ID.

*/

PROCEDURE bill_to_party_name_derive IS
  l_api_name           CONSTANT VARCHAR2(80) := 'BILL_TO_PARTY_NAME_DERIVE';

BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'l_bill_to_ptp_id = '||ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID(i));
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'l_bill_third_pty_acct_id = '||ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_ID(i));
   END IF;

   IF ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID(i) IS NOT NULL THEN
      BEGIN
 	SELECT pty.party_name,
                pty.party_number
           INTO ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NAME(i),
                ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NUMBER(i)
           FROM hz_parties pty,
                zx_party_tax_profile ptp
          WHERE ptp.party_tax_profile_id = ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID(i)
            AND ptp.party_id = pty.party_id;
      EXCEPTION WHEN OTHERS THEN
          ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NAME(i)   := NULL;
          ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NUMBER(i) := NULL;
      END;
   ELSE
      IF ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_ID(i) IS NOT NULL THEN
         BEGIN
            SELECT hzp.party_name,
                   hzp.party_number
              INTO ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NAME(i),
                   ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NUMBER(i)
              FROM hz_cust_accounts hzca,
                   hz_parties hzp
             WHERE hzp.party_id = hzca.party_id
               AND hzca.cust_account_id = ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_ID(i);
         END;
      ELSE
         ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NAME(i)   := NULL;
         ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NUMBER(i) := NULL;
      END IF;
   END IF;

   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

END bill_to_party_name_derive;

PROCEDURE ship_to_party_name_derive IS
  l_api_name           CONSTANT VARCHAR2(80) := 'SHIP_TO_PARTY_NAME_DERIVE';

BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'l_ship_to_ptp_id = '||ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID(i));
       FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'l_ship_third_pty_acct_id = '||ZX_PTNR_NEG_LINES_TAB.SHIP_THIRD_PTY_ACCT_ID(i));
   END IF;

   IF ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID(i) IS NULL THEN
      IF ZX_PTNR_NEG_LINES_TAB.SHIP_THIRD_PTY_ACCT_ID(i) IS NOT NULL THEN
         BEGIN
            SELECT hzp.party_name,
                   hzp.party_number
              INTO ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NAME(i),
                   ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NUMBER(i)
              FROM hz_cust_accounts hzca,
                   hz_parties hzp
             WHERE hzp.party_id = hzca.party_id
               AND hzca.cust_account_id = ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_ID(i);
         EXCEPTION WHEN OTHERS THEN
            ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NAME(i)   := NULL;
            ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NUMBER(i) := NULL;
         END;
      ELSE
         ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NAME(i)   := NULL;
         ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NUMBER(i) := NULL;
      END IF;
   ELSIF ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID(i) = ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID(i) THEN
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NAME(i) := ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NAME(i);
      ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NUMBER(i) := ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NUMBER(i);
   ELSE
      BEGIN
         SELECT pty.party_name,
               pty.party_number
          INTO ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NAME(i),
               ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NUMBER(i)
          FROM hz_parties pty,
               zx_party_tax_profile ptp
         WHERE ptp.party_tax_profile_id = ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID(i)
           AND ptp.party_id = pty.party_id;
      EXCEPTION WHEN OTHERS THEN
         ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NAME(i)   := NULL;
         ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NUMBER(i) := NULL;
      END;
   END IF;
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

END ship_to_party_name_derive;

PROCEDURE bill_from_party_name_derive IS
  l_api_name           CONSTANT VARCHAR2(80) := 'BILL_FROM_PARTY_NAME_DERIVE';

BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;
   IF ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_TAX_PROF_ID(i) IS NOT NULL THEN
      BEGIN
         SELECT pty.party_name,
                pty.party_number
           INTO ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NAME(i),
                ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NUMBER(i)
           FROM hz_parties pty,
                zx_party_tax_profile ptp
          WHERE ptp.party_tax_profile_id = ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_TAX_PROF_ID(i)
            AND ptp.party_id = pty.party_id;
      EXCEPTION WHEN OTHERS THEN
          ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NAME(i)   := NULL;
          ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NUMBER(i) := NULL;
      END;
   ELSE
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NAME(i)   := NULL;
      ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NUMBER(i) := NULL;
   END IF;
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

END bill_from_party_name_derive;

PROCEDURE ship_from_party_name_derive IS
  l_api_name           CONSTANT VARCHAR2(80) := 'SHIP_FROM_PARTY_NAME_DERIVE';

BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;
   IF ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_TAX_PROF_ID(i) IS NULL THEN
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NAME(i) := NULL;
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NUMBER(i) := NULL;
   ELSIF ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_TAX_PROF_ID(i) = ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_TAX_PROF_ID(i) THEN
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NAME(i) := ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NAME(i);
      ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NUMBER(i) := ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NUMBER(i);
   ELSE
      BEGIN
         SELECT pty.party_name,
                pty.party_number
           INTO ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NAME(i),
                ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NUMBER(i)
           FROM hz_parties pty,
                zx_party_tax_profile ptp
          WHERE ptp.party_tax_profile_id = ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_TAX_PROF_ID(i)
            AND ptp.party_id = pty.party_id;
      EXCEPTION WHEN OTHERS THEN
         ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NAME(i)   := NULL;
         ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NUMBER(i) := NULL;
      END;
   END IF;
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

END ship_from_party_name_derive;

PROCEDURE get_hz_location_id(p_site_use_id IN NUMBER, x_location_id OUT NOCOPY NUMBER) IS

BEGIN
  BEGIN
    SELECT ps.location_id
    INTO x_location_id
    FROM hz_cust_site_uses_all siteuse, hz_cust_acct_sites_all site, hz_party_sites ps
    WHERE  siteuse.site_use_id = p_site_use_id and
           siteuse.cust_acct_site_id = site.cust_acct_site_id and
           site.party_site_id = ps.party_site_id ;

   EXCEPTION WHEN OTHERS THEN
     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'get_hz_location_id', 'Location not found.');
     END IF;


   END;

   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||'get_hz_location_id'||'.END',G_PKG_NAME
|| ': ' ||'get_hz_location_id'||'(-)');
   END IF;

END get_hz_location_id;

PROCEDURE get_party_tax_profile_id(p_site_use_id IN NUMBER, x_party_tax_profile_id OUT NOCOPY NUMBER) IS

BEGIN
  BEGIN
    SELECT ptp.party_tax_profile_id
    INTO  x_party_tax_profile_id
    FROM hz_cust_site_uses_all siteuse, hz_cust_acct_sites_all site, hz_cust_accounts acct, zx_party_tax_profile ptp
    WHERE  siteuse.site_use_id = p_site_use_id and
           siteuse.cust_acct_site_id = site.cust_acct_site_id and
           site.cust_account_id = acct.cust_account_id and
           acct.party_id = ptp.party_id and
           ptp.party_type_code = 'THIRD_PARTY' ;

   EXCEPTION WHEN OTHERS THEN
     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||'get_party_tax_profile_id', 'Party tax profile id not found.');
     END IF;


   END;

   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||'get_party_tax_profile_id'||'.END',G_PKG_NAME
|| ': ' ||'get_party_tax_profile_id' ||'(-)');
   END IF;

END get_party_tax_profile_id;


PROCEDURE FLUSH_TABLE_INFORMATION IS
  l_api_name           CONSTANT VARCHAR2(80) := 'FLUSH_TABLE_INFORMATION';

BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME || ': ' ||l_api_name||'(+)');
   END IF;

   zx_ptnr_neg_lines_tab.INTERNAL_ORGANIZATION_ID.DELETE;
   zx_ptnr_neg_lines_tab.EVENT_CLASS_MAPPING_ID.DELETE;
   zx_ptnr_neg_lines_tab.TRX_ID.DELETE;
   zx_ptnr_neg_lines_tab.ENTITY_CODE.DELETE;
   zx_ptnr_neg_lines_tab.EVENT_CLASS_CODE.DELETE;
   zx_ptnr_neg_lines_tab.APPLICATION_ID.DELETE;
   zx_ptnr_neg_lines_tab.TRX_DATE.DELETE;
   zx_ptnr_neg_lines_tab.TRX_CURRENCY_CODE.DELETE;
   zx_ptnr_neg_lines_tab.TRX_NUMBER.DELETE;
   zx_ptnr_neg_lines_tab.RECORD_TYPE_CODE.DELETE;
   zx_ptnr_neg_lines_tab.TRX_LINE_ID.DELETE;
   zx_ptnr_neg_lines_tab.TRX_LEVEL_TYPE.DELETE;
   zx_ptnr_neg_lines_tab.LINE_LEVEL_ACTION.DELETE;
   zx_ptnr_neg_lines_tab.TRX_LINE_DATE.DELETE;
   zx_ptnr_neg_lines_tab.LINE_AMT.DELETE;
   zx_ptnr_neg_lines_tab.TRX_LINE_QUANTITY.DELETE;
   zx_ptnr_neg_lines_tab.UNIT_PRICE.DELETE;
   zx_ptnr_neg_lines_tab.PRODUCT_ID.DELETE;
   zx_ptnr_neg_lines_tab.PRODUCT_ORG_ID.DELETE;
   zx_ptnr_neg_lines_tab.UOM_CODE.DELETE;
   zx_ptnr_neg_lines_tab.PRODUCT_TYPE.DELETE;
   zx_ptnr_neg_lines_tab.PRODUCT_CODE.DELETE;
   zx_ptnr_neg_lines_tab.FOB_POINT.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE1.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE1.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE2.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE2.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE3.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE3.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE4.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE4.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE5.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE5.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE6.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE6.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE7.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE7.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE8.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE8.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE9.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE9.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_TYPE10.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_GEOGRAPHY_VALUE10.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE1.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE1.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE2.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE2.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE3.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE3.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE4.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE4.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE5.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE5.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE6.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE6.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE7.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE7.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE8.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE8.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE9.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE9.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_TYPE10.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_GEOGRAPHY_VALUE10.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE1.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE1.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE2.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE2.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE3.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE3.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE4.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE4.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE5.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE5.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE6.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE6.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE7.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE7.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE8.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE8.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE9.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE9.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_TYPE10.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_GEOGRAPHY_VALUE10.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE1.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE1.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE2.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE2.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE3.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE3.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE4.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE4.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE5.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE5.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE6.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE6.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE7.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE7.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE8.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE8.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE9.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE9.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_TYPE10.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_GEOGRAPHY_VALUE10.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_LOCATION_ID.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_LOCATION_ID.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_LOCATION_ID.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_LOCATION_ID.DELETE;
   zx_ptnr_neg_lines_tab.ACCOUNT_CCID.DELETE;
   zx_ptnr_neg_lines_tab.APPL_FROM_TRX_ID.DELETE;
   zx_ptnr_neg_lines_tab.APPL_FROM_LINE_ID.DELETE;
   zx_ptnr_neg_lines_tab.APPL_FROM_TRX_LEVEL_TYPE.DELETE;
   zx_ptnr_neg_lines_tab.APPL_FROM_TRX_NUMBER.DELETE;
   zx_ptnr_neg_lines_tab.ADJUSTED_DOC_TRX_ID.DELETE;
   zx_ptnr_neg_lines_tab.ADJUSTED_DOC_LINE_ID.DELETE;
   zx_ptnr_neg_lines_tab.ADJUSTED_DOC_TRX_LEVEL_TYPE.DELETE;
   zx_ptnr_neg_lines_tab.EXEMPT_CERTIFICATE_NUMBER.DELETE;
   zx_ptnr_neg_lines_tab.EXEMPT_REASON.DELETE;
   zx_ptnr_neg_lines_tab.EXEMPTION_CONTROL_FLAG.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_PARTY_TAX_PROF_ID.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_PARTY_TAX_PROF_ID.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_SITE_TAX_PROF_ID.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_PARTY_TAX_PROF_ID.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_CUST_ACCT_SITE_USE_ID.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_SITE_TAX_PROF_ID.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_PARTY_TAX_PROF_ID.DELETE;
   zx_ptnr_neg_lines_tab.TRADING_HQ_SITE_TAX_PROF_ID.DELETE;
   zx_ptnr_neg_lines_tab.TRADING_HQ_PARTY_TAX_PROF_ID.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_THIRD_PTY_ACCT_ID.DELETE;		-- Bug 4939819
   zx_ptnr_neg_lines_tab.BILL_THIRD_PTY_ACCT_ID.DELETE;
   zx_ptnr_neg_lines_tab.ADJUSTED_DOC_APPLICATION_ID.DELETE;
   zx_ptnr_neg_lines_tab.ADJUSTED_DOC_ENTITY_CODE.DELETE;
   zx_ptnr_neg_lines_tab.ADJUSTED_DOC_EVENT_CLASS_CODE.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_PARTY_NAME.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_PARTY_NAME.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_PARTY_NAME.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_PARTY_NAME.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_PARTY_NUMBER.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_FROM_PARTY_NUMBER.DELETE;
   zx_ptnr_neg_lines_tab.BILL_FROM_PARTY_NUMBER.DELETE;
   zx_ptnr_neg_lines_tab.BILL_TO_PARTY_NUMBER.DELETE;
   zx_ptnr_neg_lines_tab.TAX_PROVIDER_ID.DELETE;
   zx_ptnr_neg_lines_tab.TAX_REGIME_CODE.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE1.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE2.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE3.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE4.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE5.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE6.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE7.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE8.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE9.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE10.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE11.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE12.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE13.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE14.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE15.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE16.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE17.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE18.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE19.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE20.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE21.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE22.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE23.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE24.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE25.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE26.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE27.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE28.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE29.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_VARCHAR_ATTRIBUTE30.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE1.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE2.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE3.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE4.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE5.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE6.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE7.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE8.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE9.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_NUMBER_ATTRIBUTE10.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_DATE_ATTRIBUTE1.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_DATE_ATTRIBUTE2.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_DATE_ATTRIBUTE3.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_DATE_ATTRIBUTE4.DELETE;
   zx_ptnr_neg_lines_tab.LINE_EXT_DATE_ATTRIBUTE5.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_THIRD_PTY_ACCT_SITE_ID.DELETE;
   zx_ptnr_neg_lines_tab.BILL_THIRD_PTY_ACCT_SITE_ID.DELETE;
   zx_ptnr_neg_lines_tab.SHIP_TO_CUST_ACCT_SITE_USE_ID.DELETE;
   zx_ptnr_neg_lines_tab.RECEIVABLES_TRX_TYPE_ID.DELETE;
   zx_ptnr_neg_lines_tab.ADJUSTED_DOC_DATE.DELETE; --Bug14756523

/* This initialization of zx_ptnr_neg_line_gt is incorrect.
   When multiple item lines are updated, "COPY_PTNR_TAX_LINE_BEF_UPD" is called
   individually for each item line updated. Hence, subsequent calls delete the
   earlier records inserted in zx_ptnr_neg_line_gt.
   As far as updating multiple item lines is concerned, records are deleted from
   zx_ptnr_neg_line_gt after each line update in zxvtxsrvcpkgb.pls */

   -- delete from zx_ptnr_neg_line_gt;

   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
   END IF;

END flush_table_information;

PROCEDURE COPY_PTNR_TAX_LINE_BEF_UPD
(p_tax_line_id       IN   ZX_LINES.tax_line_id%type,
 x_return_status         OUT  NOCOPY VARCHAR2) IS

  l_application_id     zx_lines.application_id%type;
  l_api_name           CONSTANT VARCHAR2(80) := 'COPY_PTNR_TAX_LINE_BEF_UPD';

 BEGIN

    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;

    /*Set the return status to Success */
    x_return_status := FND_API.G_RET_STS_SUCCESS;

/* We should not call this API for products other than AR. */

  BEGIN
     select application_id
       into l_application_id
       from zx_lines
      where tax_line_id      = p_tax_line_id;
  EXCEPTION
     WHEN OTHERS THEN
        l_application_id := NULL;
  END;
  IF nvl(l_application_id, -1) <> 222 THEN
     IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, ' Skipping this procedure as no synchronization needed.');
     END IF;
     IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
     END IF;
     return;
  END IF;

  BEGIN
      INSERT INTO
	ZX_PTNR_NEG_TAX_LINE_GT
	(
	tax_line_id			,
	document_type_id		,
	application_id			,
	entity_code			,
	event_class_code		,
	trx_id				,
	trx_line_id			,
	trx_level_type			,
	country_code			,
	tax				,
	situs				,
	tax_jurisdiction		,
	tax_currency_code		,
	tax_curr_tax_amount		,
	tax_amount			,
	tax_rate_percentage		,
	taxable_amount			,
	exempt_certificate_number 	,
	exempt_rate_modifier 	 	,
	exempt_reason 	 	        ,
	tax_only_line_flag 	 	,
	inclusive_tax_line_flag 	,
	use_tax_flag 	       	        ,
	ebiz_override_flag 	  	,
	user_override_flag 	 	,
	last_manual_entry 		,
	manually_entered_flag     	,
	cancel_flag 	 	        ,
	delete_flag
	)

	SELECT
	  p_tax_line_id,
	  zxevnt.EVENT_CLASS_MAPPING_ID,
	  zxlines.application_id,
	  zxlines.entity_code,
	  zxlines.event_class_code,
	  zxlines.trx_id,
	  zxlines.trx_line_id,
	  zxlines.trx_level_type,
	  zxlines.tax_regime_code,
	  zxlines.tax,
	  zxlines.place_of_supply_type_code,
	  zxlines.tax_jurisdiction_code,
	  zxlines.tax_currency_code,
	  zxlines.tax_amt_tax_curr,
	  zxlines. TAX_AMT ,
	  zxlines.tax_rate,
	  zxlines.TAXABLE_AMT,
	  zxlines.exempt_certificate_number,
	  zxlines.exempt_rate_modifier,
	  zxlines.exempt_reason,
	  zxlines.tax_only_line_flag,
	  zxlines.tax_amt_included_flag,
	  zxlines.self_assessed_flag,
	  decode(zxlines.overridden_flag, 'N', 'Y', 'N') ,
	  zxlines.overridden_flag,
	  zxlines.last_manual_entry,
          zxlines.manually_entered_flag,
	  zxlines.cancel_flag,
	  zxlines.delete_flag

	FROM  zx_lines zxlines, zx_evnt_cls_mappings zxevnt
	WHERE zxlines.tax_line_id      = p_tax_line_id
	AND   zxevnt.event_class_code  = zxlines.event_class_code
	AND   zxevnt.application_id    = zxlines.application_id
	AND   zxevnt.entity_code       = zxlines.entity_code;


     EXCEPTION WHEN OTHERS THEN
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                        'Exception Encoutered in zx_r11i_tax_partner_pkg.COPY_PTNR_TAX_LINE_BEF_UPD: '||sqlerrm);
      END IF;
     END;

     IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
       FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
     END IF;

 END COPY_PTNR_TAX_LINE_BEF_UPD;

 PROCEDURE COPY_TRX_LINE_FOR_PTNR_BEF_UPD
 (p_trx_line_dist_tbl       IN    ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_tbl%TYPE,
  p_event_class_rec         IN    ZX_API_PUB.event_class_rec_type,
  p_update_index            IN    NUMBER,
  p_trx_copy_for_tax_update IN    VARCHAR2,
  p_regime_code             IN    VARCHAR2,
  p_tax_provider_id         IN    VARCHAR2,
  x_return_status           OUT  NOCOPY VARCHAR2) is
  l_geography_id      number;
  l_geography_code    varchar2(30);
  l_tax_provider_id   number;
  l_return_status     varchar2(20);
  l_regime_code       varchar2(30);
  l_bill_from_ptp_id  number;
  ptr		      number;
  l_count             number :=0;
--  zx_ptnr_neg_lines_tab ZX_PTNR_NEG_LINE_TYPE;

  l_user_extns         VARCHAR2(1);
  l_old_regime_code    varchar2(30);

  x_messages_tbl ZX_TAX_PARTNER_PKG.messages_tbl_type;

  Cursor lines(p_event_class_rec ZX_API_PUB.event_class_rec_type) is
    SELECT
     	INTERNAL_ORGANIZATION_ID,
     	EVENT_CLASS_MAPPING_ID,
     	TRX_ID,
     	ENTITY_CODE,
     	EVENT_CLASS_CODE,
     	APPLICATION_ID,
     	TRX_DATE,
     	TRX_CURRENCY_CODE,
     	TRX_NUMBER,
      RECORD_TYPE_CODE,
     	TRX_LINE_ID,
     	TRX_LEVEL_TYPE,
     	LINE_LEVEL_ACTION,
     	TRX_LINE_DATE,
     	LINE_AMT,
     	TRX_LINE_QUANTITY,
     	UNIT_PRICE,
     	PRODUCT_ID,
     	PRODUCT_ORG_ID,
     	UOM_CODE,
     	PRODUCT_TYPE,
     	PRODUCT_CODE,
      FOB_POINT,
     	EXEMPT_CERTIFICATE_NUMBER,
     	EXEMPT_REASON_CODE,		--Bug 6434040
     	EXEMPTION_CONTROL_FLAG,
     	SHIP_FROM_PARTY_TAX_PROF_ID,
     	BILL_FROM_PARTY_TAX_PROF_ID,
     	SHIP_TO_SITE_TAX_PROF_ID,
     	SHIP_TO_PARTY_TAX_PROF_ID,
     	SHIP_TO_LOCATION_ID,
     	BILL_TO_CUST_ACCT_SITE_USE_ID,
     	BILL_TO_SITE_TAX_PROF_ID,
     	BILL_TO_PARTY_TAX_PROF_ID,
     	BILL_TO_LOCATION_ID,
    	BILL_FROM_LOCATION_ID,
     	--POA_LOCATION_ID,
     	--POO_LOCATION_ID,
     	SHIP_FROM_LOCATION_ID,
     	TRADING_HQ_SITE_TAX_PROF_ID,
     	TRADING_HQ_PARTY_TAX_PROF_ID,
     	SHIP_THIRD_PTY_ACCT_ID,           -- Bug 4939819
     	BILL_THIRD_PTY_ACCT_ID,
     	ADJUSTED_DOC_APPLICATION_ID,
     	ADJUSTED_DOC_ENTITY_CODE,
     	ADJUSTED_DOC_EVENT_CLASS_CODE,
     	ADJUSTED_DOC_TRX_ID,
     	ADJUSTED_DOC_LINE_ID,
     	ADJUSTED_DOC_TRX_LEVEL_TYPE,
    	SHIP_TO_CUST_ACCT_SITE_USE_ID,
    	SHIP_THIRD_PTY_ACCT_SITE_ID,
    	BILL_THIRD_PTY_ACCT_SITE_ID,
      RECEIVABLES_TRX_TYPE_ID,
    	ADJUSTED_DOC_DATE --Bug14756523
    FROM ZX_LINES_DET_FACTORS
    WHERE APPLICATION_ID   = p_event_class_rec.APPLICATION_ID
    AND   ENTITY_CODE      = p_event_class_rec.ENTITY_CODE
    AND   EVENT_CLASS_CODE = p_event_class_rec.EVENT_CLASS_CODE
    AND   TRX_ID           = p_event_class_rec.TRX_ID;

  l_api_name           CONSTANT VARCHAR2(80) := 'COPY_TRX_LINE_FOR_PTNR_BEF_UPD';

 Begin
    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;
    /*Set the return status to Success */
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    /* TSRM calls the ZX_SRVC_TYP_PKG.db_update_line_det_factors after the tax calculation
    is successfully completed to update some flags on ZX_LINE_DET_FACTORS. In this scenario,
    we need not take the snapshot of the ZX_LINE_DET_FACTORS as these updates may not be
    relevant for the partners.
    If the call is made during the post tax calculation, the ZX_API_PUB.G_PUB_SRVC is set to
    'CALCULATE_TAX'. Hence, we will aviod the snapshot capturing during this scenario.
    We should not call this API for products other than AR. */

    IF p_event_class_rec.application_id = 222 THEN
      IF ZX_API_PUB.G_PUB_SRVC = 'CALCULATE_TAX' THEN
         IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, ' Skipping this procedure as no synchronization needed.');
         END IF;
         IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
         END IF;
         return;
      END IF;
      /* Required for real-time P2P integration – START OF CODE */
      ELSIF p_event_class_rec.application_id = 200 THEN
      null;
      /* Required for real-time P2P integration – END OF CODE */
    ELSE
      IF (G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL ) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name, ' Skipping this procedure as no synchronization needed.');
      END IF;
      IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
      END IF;
      return;
    END IF;

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                'p_trx_copy_for_tax_update: '|| p_trx_copy_for_tax_update ||
                ' APPLICATION_ID: '|| p_event_class_rec.APPLICATION_ID ||
                ' ENTITY_CODE: ' ||  p_event_class_rec.ENTITY_CODE ||
                ' EVENT_CLASS_CODE: '|| p_event_class_rec.EVENT_CLASS_CODE ||
                ' TRX_ID: '|| to_char(p_event_class_rec.TRX_ID));
    END IF;

    --Rewrite for TWE adapter changes - Bug 18666825, Bug 18324858
    -- initializing counter for storing data into ZX_PTNR_NEG_LINES_TAB
    --Bug 17785103
    i := 1;

    IF p_trx_line_dist_tbl.application_id.exists(1) THEN

      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
        ' p_trx_line_dist_tbl is passed');
      END IF;

      FOR ptr IN p_trx_line_dist_tbl.application_id.FIRST .. p_update_index loop

        IF nvl(p_trx_copy_for_tax_update, 'N') = 'Y' OR p_tax_provider_id is NULL THEN
          begin
            select tax_regime_code,
                   tax_provider_id
            into   l_regime_code,
                   l_tax_provider_id
            from zx_lines
            WHERE  APPLICATION_ID   = p_event_class_rec.APPLICATION_ID
            AND ENTITY_CODE      = p_event_class_rec.ENTITY_CODE
            AND EVENT_CLASS_CODE = p_event_class_rec.EVENT_CLASS_CODE
            AND TRX_ID           = p_trx_line_dist_tbl.TRX_ID(ptr)
            AND TRX_LINE_ID      = p_trx_line_dist_tbl.TRX_LINE_ID(ptr)
            AND TAX_PROVIDER_ID in (1,2)
            AND rownum = 1;
          exception when others then
            l_tax_provider_id := NULL;
          end;
        else
          l_regime_code     := p_regime_code;
          l_tax_provider_id := p_tax_provider_id;
        end if;

        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                    'l_regime_code: '|| to_char(l_regime_code) ||
                    ' l_tax_provider_id: '|| to_char(l_tax_provider_id) ||
                    ' Line Level Action: ' || p_trx_line_dist_tbl.line_level_action(ptr));
        END IF;

        -- bug 17785103
        IF  nvl(l_tax_provider_id, -1) IN (1, 2)
            AND p_trx_line_dist_tbl.line_level_action(ptr) IN ('NO_CHANGE',
                                                         'UPDATE',
                                                         'DISCARD',
                                                         'CANCEL',
                                                         'SYNCHRONIZE',
                                                         'DELETE') THEN
          --I:=ptr;
          Select
            INTERNAL_ORGANIZATION_ID,
            EVENT_CLASS_MAPPING_ID,
            TRX_ID,
            ENTITY_CODE,
            EVENT_CLASS_CODE,
            APPLICATION_ID,
            TRX_DATE,
            TRX_CURRENCY_CODE,
            TRX_NUMBER,
            RECORD_TYPE_CODE,
            TRX_LINE_ID,
            TRX_LEVEL_TYPE,
            LINE_LEVEL_ACTION,
            TRX_LINE_DATE,
            LINE_AMT,
            TRX_LINE_QUANTITY,
            UNIT_PRICE,
            PRODUCT_ID,
            PRODUCT_ORG_ID,
            UOM_CODE,
            PRODUCT_TYPE,
            PRODUCT_CODE,
            FOB_POINT,
            EXEMPT_CERTIFICATE_NUMBER,
            EXEMPT_REASON_CODE, --Bug 6434040
            EXEMPTION_CONTROL_FLAG,
            SHIP_FROM_PARTY_TAX_PROF_ID,
            BILL_FROM_PARTY_TAX_PROF_ID,
            SHIP_TO_SITE_TAX_PROF_ID,
            SHIP_TO_PARTY_TAX_PROF_ID,
            SHIP_TO_LOCATION_ID,
            BILL_TO_CUST_ACCT_SITE_USE_ID,
            BILL_TO_SITE_TAX_PROF_ID,
            BILL_TO_PARTY_TAX_PROF_ID,
            BILL_TO_LOCATION_ID,
            BILL_FROM_LOCATION_ID,
            --POA_LOCATION_ID,
            --POO_LOCATION_ID,
            SHIP_FROM_LOCATION_ID,
            TRADING_HQ_SITE_TAX_PROF_ID,
            TRADING_HQ_PARTY_TAX_PROF_ID,
            SHIP_THIRD_PTY_ACCT_ID,                -- Bug 4939819
            BILL_THIRD_PTY_ACCT_ID,
            ADJUSTED_DOC_APPLICATION_ID,
            ADJUSTED_DOC_ENTITY_CODE,
            ADJUSTED_DOC_EVENT_CLASS_CODE,
            ADJUSTED_DOC_TRX_ID,
            ADJUSTED_DOC_LINE_ID,
            ADJUSTED_DOC_TRX_LEVEL_TYPE,
            SHIP_TO_CUST_ACCT_SITE_USE_ID,
            SHIP_THIRD_PTY_ACCT_SITE_ID,
            BILL_THIRD_PTY_ACCT_SITE_ID,
            RECEIVABLES_TRX_TYPE_ID,
            ADJUSTED_DOC_DATE --Bug14756523
          INTO
            ZX_PTNR_NEG_LINES_TAB.INTERNAL_ORGANIZATION_ID(i),
            ZX_PTNR_NEG_LINES_TAB.EVENT_CLASS_MAPPING_ID(i),
            ZX_PTNR_NEG_LINES_TAB.TRX_ID(i),
            ZX_PTNR_NEG_LINES_TAB.ENTITY_CODE(i),
            ZX_PTNR_NEG_LINES_TAB.EVENT_CLASS_CODE(i),
            ZX_PTNR_NEG_LINES_TAB.APPLICATION_ID(i),
            ZX_PTNR_NEG_LINES_TAB.TRX_DATE(i),
            ZX_PTNR_NEG_LINES_TAB.TRX_CURRENCY_CODE(i),
            ZX_PTNR_NEG_LINES_TAB.TRX_NUMBER(i),
            ZX_PTNR_NEG_LINES_TAB.RECORD_TYPE_CODE(i),
            ZX_PTNR_NEG_LINES_TAB.TRX_LINE_ID(i),
            ZX_PTNR_NEG_LINES_TAB.TRX_LEVEL_TYPE(i),
            ZX_PTNR_NEG_LINES_TAB.LINE_LEVEL_ACTION(i),
            ZX_PTNR_NEG_LINES_TAB.TRX_LINE_DATE(i),
            ZX_PTNR_NEG_LINES_TAB.LINE_AMT(i),
            ZX_PTNR_NEG_LINES_TAB.TRX_LINE_QUANTITY(i),
            ZX_PTNR_NEG_LINES_TAB.UNIT_PRICE(i),
            ZX_PTNR_NEG_LINES_TAB.PRODUCT_ID(i),
            ZX_PTNR_NEG_LINES_TAB.PRODUCT_ORG_ID(i),
            ZX_PTNR_NEG_LINES_TAB.UOM_CODE(i),
            ZX_PTNR_NEG_LINES_TAB.PRODUCT_TYPE(i),
            ZX_PTNR_NEG_LINES_TAB.PRODUCT_CODE(i),
            ZX_PTNR_NEG_LINES_TAB.FOB_POINT(i),
            ZX_PTNR_NEG_LINES_TAB.EXEMPT_CERTIFICATE_NUMBER(i),
            ZX_PTNR_NEG_LINES_TAB.EXEMPT_REASON(i),
            ZX_PTNR_NEG_LINES_TAB.EXEMPTION_CONTROL_FLAG(i),
            ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_TAX_PROF_ID(i),
            ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_TAX_PROF_ID(i),
            ZX_PTNR_NEG_LINES_TAB.SHIP_TO_SITE_TAX_PROF_ID(i),
            ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID(i),
            ZX_PTNR_NEG_LINES_TAB.SHIP_TO_LOCATION_ID(i),
            ZX_PTNR_NEG_LINES_TAB.BILL_TO_CUST_ACCT_SITE_USE_ID(i),
            ZX_PTNR_NEG_LINES_TAB.BILL_TO_SITE_TAX_PROF_ID(i),
            ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID(i),
            ZX_PTNR_NEG_LINES_TAB.BILL_TO_LOCATION_ID(i),
            ZX_PTNR_NEG_LINES_TAB.BILL_FROM_LOCATION_ID(i),
            --ZX_PTNR_NEG_LINES_TAB.POA_LOCATION_ID(i),
            --ZX_PTNR_NEG_LINES_TAB.POO_LOCATION_ID(i),
            ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_LOCATION_ID(i),
            ZX_PTNR_NEG_LINES_TAB.TRADING_HQ_SITE_TAX_PROF_ID(i),
            ZX_PTNR_NEG_LINES_TAB.TRADING_HQ_PARTY_TAX_PROF_ID(i),
            ZX_PTNR_NEG_LINES_TAB.SHIP_THIRD_PTY_ACCT_ID(i),               -- Bug 4939819
            ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_ID(i),
            ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_APPLICATION_ID(i),
            ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_ENTITY_CODE(i),
            ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_EVENT_CLASS_CODE(i),
            ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_TRX_ID(i),
            ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_LINE_ID(i),
            ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_TRX_LEVEL_TYPE(i),
            ZX_PTNR_NEG_LINES_TAB.SHIP_TO_CUST_ACCT_SITE_USE_ID(i),
            ZX_PTNR_NEG_LINES_TAB.SHIP_THIRD_PTY_ACCT_SITE_ID(i),
            ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_SITE_ID(i),
            ZX_PTNR_NEG_LINES_TAB.RECEIVABLES_TRX_TYPE_ID(i),
            ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_DATE(i) --Bug14756523
          FROM ZX_LINES_DET_FACTORS
          WHERE APPLICATION_ID   = p_event_class_rec.APPLICATION_ID
          AND   ENTITY_CODE      = p_event_class_rec.ENTITY_CODE
          AND   EVENT_CLASS_CODE = p_event_class_rec.EVENT_CLASS_CODE
          AND   TRX_ID           = p_trx_line_dist_tbl.TRX_ID(ptr)
          AND   TRX_LINE_ID      = p_trx_line_dist_tbl.TRX_LINE_ID(ptr)
          AND   TRX_LEVEL_TYPE   = p_trx_line_dist_tbl.TRX_LEVEL_TYPE(ptr);

          IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
            'TRX_LINE_ID: '|| to_char(p_trx_line_dist_tbl.TRX_LINE_ID(ptr)));
            FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
            'TRX_LEVEL_TYPE: '|| p_trx_line_dist_tbl.TRX_LEVEL_TYPE(ptr));
          END IF;

          ZX_PTNR_NEG_LINES_TAB.TAX_REGIME_CODE(i) := l_regime_code;
          ZX_PTNR_NEG_LINES_TAB.TAX_PROVIDER_ID(i) := l_tax_provider_id;

          ship_to_geo_names_derive(p_trx_copy_for_tax_update);
          ship_from_geo_names_derive(p_trx_copy_for_tax_update);
          bill_to_geo_names_derive(p_trx_copy_for_tax_update);
          bill_from_geo_names_derive(p_trx_copy_for_tax_update);

          --/*Here logic for derivation of party name and number
          bill_to_party_name_derive;
          ship_to_party_name_derive;
          bill_from_party_name_derive;
          ship_from_party_name_derive;

          i := i + 1;
        END IF; -- bug 17785103
      End loop;
    ELSE  -- p_trx_line_dist_tbl.application_id.exists(1)
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
        ' p_trx_line_dist_tbl is not passed');
      END IF;

      IF nvl(p_trx_copy_for_tax_update, 'N') = 'Y' OR p_tax_provider_id is NULL THEN
        begin
          select tax_regime_code,
                 tax_provider_id
          into   l_regime_code,
                 l_tax_provider_id
          from zx_lines
          WHERE  APPLICATION_ID   = p_event_class_rec.APPLICATION_ID
          AND ENTITY_CODE      = p_event_class_rec.ENTITY_CODE
          AND EVENT_CLASS_CODE = p_event_class_rec.EVENT_CLASS_CODE
          AND TRX_ID           = p_event_class_rec.TRX_ID
          AND TAX_PROVIDER_ID in (1,2)
          AND rownum = 1;
        exception when others then
          l_tax_provider_id := NULL;
        end;
      else
        l_regime_code     := p_regime_code;
        l_tax_provider_id := p_tax_provider_id;
      end if;

      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
                  'l_regime_code: '|| to_char(l_regime_code) ||
                  ' l_tax_provider_id: '|| to_char(l_tax_provider_id));
      END IF;

      IF nvl(l_tax_provider_id, -1) IN (1, 2) THEN
        OPEN lines(p_event_class_rec);

        FETCH lines BULK COLLECT INTO
          ZX_PTNR_NEG_LINES_TAB.INTERNAL_ORGANIZATION_ID,
          ZX_PTNR_NEG_LINES_TAB.EVENT_CLASS_MAPPING_ID,
          ZX_PTNR_NEG_LINES_TAB.TRX_ID,
          ZX_PTNR_NEG_LINES_TAB.ENTITY_CODE,
          ZX_PTNR_NEG_LINES_TAB.EVENT_CLASS_CODE,
          ZX_PTNR_NEG_LINES_TAB.APPLICATION_ID,
          ZX_PTNR_NEG_LINES_TAB.TRX_DATE,
          ZX_PTNR_NEG_LINES_TAB.TRX_CURRENCY_CODE,
          ZX_PTNR_NEG_LINES_TAB.TRX_NUMBER,
          ZX_PTNR_NEG_LINES_TAB.RECORD_TYPE_CODE,
          ZX_PTNR_NEG_LINES_TAB.TRX_LINE_ID,
          ZX_PTNR_NEG_LINES_TAB.TRX_LEVEL_TYPE,
          ZX_PTNR_NEG_LINES_TAB.LINE_LEVEL_ACTION,
          ZX_PTNR_NEG_LINES_TAB.TRX_LINE_DATE,
          ZX_PTNR_NEG_LINES_TAB.LINE_AMT,
          ZX_PTNR_NEG_LINES_TAB.TRX_LINE_QUANTITY,
          ZX_PTNR_NEG_LINES_TAB.UNIT_PRICE,
          ZX_PTNR_NEG_LINES_TAB.PRODUCT_ID,
          ZX_PTNR_NEG_LINES_TAB.PRODUCT_ORG_ID,
          ZX_PTNR_NEG_LINES_TAB.UOM_CODE,
          ZX_PTNR_NEG_LINES_TAB.PRODUCT_TYPE,
          ZX_PTNR_NEG_LINES_TAB.PRODUCT_CODE,
          ZX_PTNR_NEG_LINES_TAB.FOB_POINT,
          ZX_PTNR_NEG_LINES_TAB.EXEMPT_CERTIFICATE_NUMBER,
          ZX_PTNR_NEG_LINES_TAB.EXEMPT_REASON,
          ZX_PTNR_NEG_LINES_TAB.EXEMPTION_CONTROL_FLAG,
          ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_TAX_PROF_ID,
          ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_TAX_PROF_ID,
          ZX_PTNR_NEG_LINES_TAB.SHIP_TO_SITE_TAX_PROF_ID,
          ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID,
          ZX_PTNR_NEG_LINES_TAB.SHIP_TO_LOCATION_ID,
          ZX_PTNR_NEG_LINES_TAB.BILL_TO_CUST_ACCT_SITE_USE_ID,
          ZX_PTNR_NEG_LINES_TAB.BILL_TO_SITE_TAX_PROF_ID,
          ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID,
          ZX_PTNR_NEG_LINES_TAB.BILL_TO_LOCATION_ID,
          ZX_PTNR_NEG_LINES_TAB.BILL_FROM_LOCATION_ID,
          --ZX_PTNR_NEG_LINES_TAB.POA_LOCATION_ID,
          --ZX_PTNR_NEG_LINES_TAB.POO_LOCATION_ID,
          ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_LOCATION_ID,
          ZX_PTNR_NEG_LINES_TAB.TRADING_HQ_SITE_TAX_PROF_ID,
          ZX_PTNR_NEG_LINES_TAB.TRADING_HQ_PARTY_TAX_PROF_ID,
          ZX_PTNR_NEG_LINES_TAB.SHIP_THIRD_PTY_ACCT_ID,       -- Bug 4939819
          ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_ID,
          ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_APPLICATION_ID,
          ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_ENTITY_CODE,
          ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_EVENT_CLASS_CODE,
          ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_TRX_ID,
          ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_LINE_ID,
          ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_TRX_LEVEL_TYPE,
          ZX_PTNR_NEG_LINES_TAB.SHIP_TO_CUST_ACCT_SITE_USE_ID,
          ZX_PTNR_NEG_LINES_TAB.SHIP_THIRD_PTY_ACCT_SITE_ID,
          ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_SITE_ID,
          ZX_PTNR_NEG_LINES_TAB.RECEIVABLES_TRX_TYPE_ID,
          ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_DATE;

        CLOSE lines;

        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
           ' ZX_API_PUB.G_PUB_SRVC '|| ZX_API_PUB.G_PUB_SRVC);
           FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
           ' No of records in ZX_PTNR_NEG_LINES_TAB = '|| ZX_PTNR_NEG_LINES_TAB.application_id.LAST);
        END IF;

        FOR ptr IN  ZX_PTNR_NEG_LINES_TAB.application_id.FIRST .. ZX_PTNR_NEG_LINES_TAB.application_id.LAST loop

          I:=ptr;

          IF ZX_PTNR_NEG_LINES_TAB.ship_to_location_id(i) is null THEN
            get_hz_location_id(ZX_PTNR_NEG_LINES_TAB.SHIP_TO_CUST_ACCT_SITE_USE_ID(i), ZX_PTNR_NEG_LINES_TAB.ship_to_location_id(i));
          END IF;

          IF ZX_PTNR_NEG_LINES_TAB.bill_to_location_id(i) is null THEN
            get_hz_location_id(ZX_PTNR_NEG_LINES_TAB.BILL_TO_CUST_ACCT_SITE_USE_ID(i), ZX_PTNR_NEG_LINES_TAB.bill_to_location_id(i));
          END IF;

          IF ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID(i) is null THEN
            get_party_tax_profile_id(ZX_PTNR_NEG_LINES_TAB.BILL_TO_CUST_ACCT_SITE_USE_ID(i),ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID(i));
          END IF;

          IF ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID(i) is null THEN
            get_party_tax_profile_id(ZX_PTNR_NEG_LINES_TAB.SHIP_TO_CUST_ACCT_SITE_USE_ID(i),ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID(i));
          END IF;

          ZX_PTNR_NEG_LINES_TAB.TAX_REGIME_CODE(i) := l_regime_code;
          ZX_PTNR_NEG_LINES_TAB.TAX_PROVIDER_ID(i) := l_tax_provider_id;

          ship_to_geo_names_derive(p_trx_copy_for_tax_update);
          ship_from_geo_names_derive(p_trx_copy_for_tax_update);
          bill_to_geo_names_derive(p_trx_copy_for_tax_update);
          bill_from_geo_names_derive(p_trx_copy_for_tax_update);

          --/*Here logic for derivation of party name and number
          bill_to_party_name_derive;
          ship_to_party_name_derive;
          bill_from_party_name_derive;
          ship_from_party_name_derive;

          i := i + 1;
        END LOOP;
      END IF;
    END IF; -- p_trx_line_dist_tbl.application_id.exists(1)

    IF i > 1 THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
        ' Inserting into zx_ptnr_neg_line_gt');
      END IF;

      FORALL i  IN zx_ptnr_neg_lines_tab.application_id.FIRST ..  zx_ptnr_neg_lines_tab.application_id.LAST
        Insert into zx_ptnr_neg_line_gt(
        	INTERNAL_ORGANIZATION_ID,
        	EVENT_CLASS_MAPPING_ID,
        	TRX_ID,
        	ENTITY_CODE,
        	EVENT_CLASS_CODE,
        	APPLICATION_ID,
        	TRX_DATE,
        	TRX_CURRENCY_CODE,
        	TRX_NUMBER,
        	RECORD_TYPE_CODE,
        	TRX_LINE_ID,
        	TRX_LEVEL_TYPE,
        	LINE_LEVEL_ACTION,
        	TRX_LINE_DATE,
        	LINE_AMT,
        	TRX_LINE_QUANTITY,
        	UNIT_PRICE,
        	PRODUCT_ID,
        	PRODUCT_ORG_ID,
        	UOM_CODE,
        	PRODUCT_TYPE,
        	PRODUCT_CODE,
          FOB_POINT,
        	TAX_REGIME_CODE,
        	TAX_PROVIDER_ID,
        	EXEMPT_CERTIFICATE_NUMBER,
        	EXEMPT_REASON,
        	EXEMPTION_CONTROL_FLAG,
        	SHIP_TO_PARTY_TAX_PROF_ID,
        	SHIP_FROM_PARTY_TAX_PROF_ID,
        	SHIP_TO_PARTY_NUMBER,
        	SHIP_TO_PARTY_NAME,
        	SHIP_FROM_PARTY_NUMBER,
        	SHIP_FROM_PARTY_NAME,
        	BILL_TO_PARTY_NUMBER,
        	BILL_TO_PARTY_NAME,
        	BILL_FROM_PARTY_NUMBER,
        	BILL_FROM_PARTY_NAME,
        	SHIP_TO_SITE_TAX_PROF_ID,
        	SHIP_TO_LOCATION_ID,
        	BILL_TO_CUST_ACCT_SITE_USE_ID,
        	BILL_TO_SITE_TAX_PROF_ID,
        	BILL_TO_PARTY_TAX_PROF_ID,
        	BILL_TO_LOCATION_ID,
        	TRADING_HQ_SITE_TAX_PROF_ID,
        	TRADING_HQ_PARTY_TAX_PROF_ID,
        	BILL_THIRD_PTY_ACCT_ID,
        	ADJUSTED_DOC_EVENT_CLASS_CODE,
        	ADJUSTED_DOC_APPLICATION_ID,
        	ADJUSTED_DOC_ENTITY_CODE,
        	ADJUSTED_DOC_TRX_ID,
        	ADJUSTED_DOC_LINE_ID,
        	ADJUSTED_DOC_TRX_LEVEL_TYPE,
        	SHIP_TO_CUST_ACCT_SITE_USE_ID,
        	SHIP_THIRD_PTY_ACCT_SITE_ID,
        	BILL_THIRD_PTY_ACCT_SITE_ID,
        	SHIP_TO_GEOGRAPHY_TYPE1,
        	SHIP_TO_GEOGRAPHY_VALUE1,
        	SHIP_TO_GEOGRAPHY_TYPE2,
        	SHIP_TO_GEOGRAPHY_VALUE2,
        	SHIP_TO_GEOGRAPHY_TYPE3,
        	SHIP_TO_GEOGRAPHY_VALUE3,
        	SHIP_TO_GEOGRAPHY_TYPE4,
        	SHIP_TO_GEOGRAPHY_VALUE4,
        	SHIP_FROM_GEOGRAPHY_TYPE1,
        	SHIP_FROM_GEOGRAPHY_VALUE1,
        	SHIP_FROM_GEOGRAPHY_TYPE2,
        	SHIP_FROM_GEOGRAPHY_VALUE2,
        	SHIP_FROM_GEOGRAPHY_TYPE3,
        	SHIP_FROM_GEOGRAPHY_VALUE3,
        	SHIP_FROM_GEOGRAPHY_TYPE4,
        	SHIP_FROM_GEOGRAPHY_VALUE4,
        	BILL_TO_GEOGRAPHY_TYPE1,
        	BILL_TO_GEOGRAPHY_VALUE1,
        	BILL_TO_GEOGRAPHY_TYPE2,
        	BILL_TO_GEOGRAPHY_VALUE2,
        	BILL_TO_GEOGRAPHY_TYPE3,
        	BILL_TO_GEOGRAPHY_VALUE3,
        	BILL_TO_GEOGRAPHY_TYPE4,
        	BILL_TO_GEOGRAPHY_VALUE4,
        	BILL_FROM_GEOGRAPHY_TYPE1,
        	BILL_FROM_GEOGRAPHY_VALUE1,
        	BILL_FROM_GEOGRAPHY_TYPE2,
        	BILL_FROM_GEOGRAPHY_VALUE2,
        	BILL_FROM_GEOGRAPHY_TYPE3,
        	BILL_FROM_GEOGRAPHY_VALUE3,
        	BILL_FROM_GEOGRAPHY_TYPE4,
        	BILL_FROM_GEOGRAPHY_VALUE4,
        	RECEIVABLES_TRX_TYPE_ID,
        	ADJUSTED_DOC_DATE --Bug14756523
        	)
         SELECT
        	ZX_PTNR_NEG_LINES_TAB.INTERNAL_ORGANIZATION_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.EVENT_CLASS_MAPPING_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.TRX_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.ENTITY_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.EVENT_CLASS_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.APPLICATION_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.TRX_DATE(i),
        	ZX_PTNR_NEG_LINES_TAB.TRX_CURRENCY_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.TRX_NUMBER(i),
        	ZX_PTNR_NEG_LINES_TAB.RECORD_TYPE_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.TRX_LINE_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.TRX_LEVEL_TYPE(i),
        	ZX_PTNR_NEG_LINES_TAB.LINE_LEVEL_ACTION(i),
        	ZX_PTNR_NEG_LINES_TAB.TRX_LINE_DATE(i),
        	ZX_PTNR_NEG_LINES_TAB.LINE_AMT(i),
        	ZX_PTNR_NEG_LINES_TAB.TRX_LINE_QUANTITY(i),
        	ZX_PTNR_NEG_LINES_TAB.UNIT_PRICE(i),
        	ZX_PTNR_NEG_LINES_TAB.PRODUCT_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.PRODUCT_ORG_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.UOM_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.PRODUCT_TYPE(i),
        	ZX_PTNR_NEG_LINES_TAB.PRODUCT_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.FOB_POINT(i),
        	ZX_PTNR_NEG_LINES_TAB.TAX_REGIME_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.TAX_PROVIDER_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.EXEMPT_CERTIFICATE_NUMBER(i),
        	ZX_PTNR_NEG_LINES_TAB.EXEMPT_REASON(i),
        	ZX_PTNR_NEG_LINES_TAB.EXEMPTION_CONTROL_FLAG(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_TAX_PROF_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_TAX_PROF_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NUMBER(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_PARTY_NAME(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NUMBER(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_PARTY_NAME(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NUMBER(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_NAME(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NUMBER(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_PARTY_NAME(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_SITE_TAX_PROF_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_LOCATION_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_CUST_ACCT_SITE_USE_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_SITE_TAX_PROF_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_PARTY_TAX_PROF_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_LOCATION_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.TRADING_HQ_SITE_TAX_PROF_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.TRADING_HQ_PARTY_TAX_PROF_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_EVENT_CLASS_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_APPLICATION_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_ENTITY_CODE(i),
        	ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_TRX_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_LINE_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_TRX_LEVEL_TYPE(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_CUST_ACCT_SITE_USE_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_THIRD_PTY_ACCT_SITE_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_THIRD_PTY_ACCT_SITE_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE1(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE1(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE2(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE2(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE3(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE3(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_TYPE4(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_TO_GEOGRAPHY_VALUE4(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE1(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE1(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE2(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE2(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE3(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE3(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_TYPE4(i),
        	ZX_PTNR_NEG_LINES_TAB.SHIP_FROM_GEOGRAPHY_VALUE4(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE1(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE1(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE2(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE2(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE3(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_VALUE3(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_TO_GEOGRAPHY_TYPE4(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE4(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE1(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE1(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE2(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE2(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE3(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE3(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_TYPE4(i),
        	ZX_PTNR_NEG_LINES_TAB.BILL_FROM_GEOGRAPHY_VALUE4(i),
        	ZX_PTNR_NEG_LINES_TAB.RECEIVABLES_TRX_TYPE_ID(i),
        	ZX_PTNR_NEG_LINES_TAB.ADJUSTED_DOC_DATE(i) --Bug14756523
        FROM DUAL
        WHERE NOT EXISTS (SELECT 'Y'
                            FROM zx_ptnr_neg_line_gt
                           WHERE application_id = ZX_PTNR_NEG_LINES_TAB.APPLICATION_ID(i)
        	                   AND entity_code = ZX_PTNR_NEG_LINES_TAB.ENTITY_CODE(i)
        	                   AND event_class_code = ZX_PTNR_NEG_LINES_TAB.EVENT_CLASS_CODE(i)
        	                   AND trx_id = ZX_PTNR_NEG_LINES_TAB.TRX_ID(i)
        	                   AND trx_line_id = ZX_PTNR_NEG_LINES_TAB.TRX_LINE_ID(i)
                          );
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
        ' Fetching Extensibile Attributes during negation');
      END IF;

      /*Bug 4950953 , 4950901 making default value as NULL as it causing issue in update operation subsequently*/

      FOR i IN  zx_ptnr_neg_lines_tab.application_id.FIRST ..  zx_ptnr_neg_lines_tab.application_id.LAST LOOP
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE1(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE2(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE3(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE4(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE5(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE6(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE7(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE8(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE9(i)   := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE10(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE11(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE12(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE13(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE14(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE15(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE16(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE17(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE18(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE19(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE20(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE21(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE22(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE23(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE24(i)  := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE1(i)    := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE2(i)    := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE3(i)    := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE4(i)    := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE5(i)    := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE6(i)    := NULL;
        ZX_PTNR_NEG_LINES_TAB.LINE_EXT_DATE_ATTRIBUTE1(i)      := NULL;

        -- Bug 4950953 , 4950901 During Invoice update,complete scenario's need to populate the
        -- ZX_TRX_PRE_PROC_OPTIONS_GT as it used in user procedures.
        Begin
          select count(*)
          into l_count
          from ZX_TRX_PRE_PROC_OPTIONS_GT
          where APPLICATION_ID	= p_event_class_rec.application_id
          AND  ENTITY_CODE    	= p_event_class_rec.entity_code
          AND  EVENT_CLASS_CODE = p_event_class_rec.event_class_code
          AND  TRX_ID 		      = zx_ptnr_neg_lines_tab.trx_id(i);
        Exception
          when no_data_found then
            l_count:=0;
        end;

        If(l_count=0) then
          INSERT into ZX_TRX_PRE_PROC_OPTIONS_GT (INTERNAL_ORGANIZATION_ID,
                                      APPLICATION_ID,
                                      ENTITY_CODE,
                                      EVENT_CLASS_CODE,
                                      EVNT_CLS_MAPPING_ID,
                                      TAX_EVENT_TYPE_CODE,
                                      PROD_FAMILY_GRP_CODE,
                                      TRX_ID,
                                      TAX_REGIME_CODE,
                                      PARTNER_PROCESSING_FLAG,
                                      TAX_PROVIDER_ID,
                                      EVENT_ID,
                                      QUOTE_FLAG,
                                      RECORD_FLAG,
                                      RECORD_FOR_PARTNERS_FLAG,
                                      APPLICATION_SHORT_NAME,
                                      LEGAL_ENTITY_NUMBER,
                                      ESTABLISHMENT_NUMBER,           -- Bug 5139731
                                      ALLOW_TAX_CALCULATION_FLAG,
                                      CREATION_DATE,
                                      CREATED_BY,
                                      LAST_UPDATE_DATE,
                                      LAST_UPDATED_BY,
                                      LAST_UPDATE_LOGIN
                                      )
                             VALUES  (p_event_class_rec.internal_organization_id,
                                      p_event_class_rec.application_id,
                                      p_event_class_rec.entity_code,
                                      p_event_class_rec.event_class_code,
                                      p_event_class_rec.event_class_mapping_id,
                                      p_event_class_rec.tax_event_type_code,
                                      p_event_class_rec.prod_family_grp_code,
                                      zx_ptnr_neg_lines_tab.trx_id(i),
                                      zx_ptnr_neg_lines_tab.tax_regime_code(i),
                                      NULL, --p_ptnr_processing_flag,
                                      zx_ptnr_neg_lines_tab.tax_provider_id(i),
                                      p_event_class_rec.event_id,
                                      p_event_class_rec.quote_flag,
                                      p_event_class_rec.record_flag,
                                      p_event_class_rec.record_for_partners_flag,
                                      NULL,--l_application_short_name,
                                      NULL,--l_legal_entity_number,
                                      NULL,--l_establishment_number,
                                      p_event_class_rec.process_for_applicability_flag,
                                      sysdate,
                                      fnd_global.user_id,
                                      sysdate,
                                      fnd_global.user_id,
                                      fnd_global.conc_login_id);
        end if;

        IF nvl(l_old_regime_code,'X$XX$$') <> zx_ptnr_neg_lines_tab.tax_regime_code(i) THEN
          BEGIN
            SELECT 'Y'
            INTO l_user_extns
            FROM ZX_API_REGISTRATIONS reg,
               ZX_SERVICE_TYPES     srvc,
               ZX_API_CODE_COMBINATIONS api
            WHERE api.code_combination_id = reg.context_ccid
            AND api.segment_attribute1  = zx_ptnr_neg_lines_tab.tax_regime_code(i)
            AND reg.api_owner_id        = p_event_class_rec.first_pty_org_id
            AND srvc.service_type_id    = reg.service_type_id
            AND srvc.service_type_code  = 'DERIVE_LINE_ATTRS'
            AND reg.package_name = decode(l_tax_provider_id,1,'ZX_VTX_USER_PKG'
                                                  ,2,'ZX_TAXWARE_USER_PKG');
          EXCEPTION WHEN OTHERS THEN
            l_user_extns := null;
          END;

          l_old_regime_code := zx_ptnr_neg_lines_tab.tax_regime_code(i);
        END IF;

        If l_tax_provider_id = 1 then/*Case for VERTEX*/
 	        ZX_VTX_USER_PKG.g_line_negation := TRUE;
 	        ZX_VTX_USER_PKG.g_trx_line_id := zx_ptnr_neg_lines_tab.TRX_LINE_ID(i);
          ZX_VTX_USER_PKG.Derive_Hdr_Ext_Attr(x_return_status
                                            , x_messages_tbl);
          IF l_user_extns = 'Y' THEN
            ZX_VTX_USER_PKG.Derive_Line_Ext_Attr(x_return_status
                                              ,  x_messages_tbl);

            /*Assigning values fetched from user procedures*/
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE1(i)  :=ZX_VTX_USER_PKG.arp_trx_line_type_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE2(i)  :=ZX_VTX_USER_PKG.arp_product_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE3(i)  :=ZX_VTX_USER_PKG.cert_num_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE4(i)  :=ZX_VTX_USER_PKG.arp_state_exempt_reason_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE5(i)  :=ZX_VTX_USER_PKG.arp_county_exempt_reason_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE6(i)  :=ZX_VTX_USER_PKG.arp_city_exempt_reason_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE7(i)  :=ZX_VTX_USER_PKG.arp_district_exempt_rs_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE8(i)  :=ZX_VTX_USER_PKG.arp_audit_flag_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE9(i)  :=ZX_VTX_USER_PKG.arp_ship_to_add_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE10(i) :=ZX_VTX_USER_PKG.arp_ship_from_add_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE11(i) :=ZX_VTX_USER_PKG.arp_poa_add_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE12(i) :=ZX_VTX_USER_PKG.arp_customer_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE13(i) :=ZX_VTX_USER_PKG.arp_customer_class_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE14(i) :=ZX_VTX_USER_PKG.arp_company_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE15(i) :=ZX_VTX_USER_PKG.arp_division_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE1(i)   :=ZX_VTX_USER_PKG.arp_state_exempt_percent_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE2(i)   :=ZX_VTX_USER_PKG.arp_county_exempt_pct_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE3(i)   :=ZX_VTX_USER_PKG.arp_city_exempt_pct_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE4(i)   :=ZX_VTX_USER_PKG.arp_district_exempt_pct_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_DATE_ATTRIBUTE1(i)     :=ZX_VTX_USER_PKG.arp_transaction_date_tab(1);
          END IF;

          ZX_VTX_USER_PKG.g_line_negation := FALSE;
        elsif l_tax_provider_id = 2 then  /*Case for TAXWARE*/
          ZX_TAXWARE_USER_PKG.g_line_negation := TRUE;
          ZX_TAXWARE_USER_PKG.g_trx_line_id :=  zx_ptnr_neg_lines_tab.TRX_LINE_ID(i);
          ZX_TAXWARE_USER_PKG.Derive_Hdr_Ext_Attr(x_return_status
                                                      , x_messages_tbl);
          IF l_user_extns = 'Y' THEN
            ZX_TAXWARE_USER_PKG.Derive_Line_Ext_Attr(x_return_status
                                                         , x_messages_tbl);
            /*Assigning values fetched from user procedures*/
            --ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE1(i)   :=ZX_TAXWARE_USER_PKG.arp_tax_type_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE1(i)   :=NULL;
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE2(i)   :=ZX_TAXWARE_USER_PKG.arp_product_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE3(i)   :=ZX_TAXWARE_USER_PKG.use_step_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE4(i)   :=ZX_TAXWARE_USER_PKG.arp_state_exempt_reason_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE5(i)   :=ZX_TAXWARE_USER_PKG.arp_county_exempt_reason_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE6(i)   :=ZX_TAXWARE_USER_PKG.arp_city_exempt_reason_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE7(i)   :=ZX_TAXWARE_USER_PKG.step_proc_flag_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE8(i)   :=ZX_TAXWARE_USER_PKG.arp_audit_flag_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE9(i)   :=ZX_TAXWARE_USER_PKG.arp_ship_to_add_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE10(i)  :=ZX_TAXWARE_USER_PKG.arp_ship_from_add_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE11(i)  :=ZX_TAXWARE_USER_PKG.arp_poa_add_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE12(i)  :=ZX_TAXWARE_USER_PKG.arp_customer_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE13(i)  :=ZX_TAXWARE_USER_PKG.arp_customer_name_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE14(i)  :=ZX_TAXWARE_USER_PKG.arp_company_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE15(i)  :=ZX_TAXWARE_USER_PKG.arp_division_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE16(i)  :=ZX_TAXWARE_USER_PKG.arp_vnd_ctrl_exmpt_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE17(i)  :=ZX_TAXWARE_USER_PKG.arp_use_nexpro_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE18(i)  :=ZX_TAXWARE_USER_PKG.arp_service_ind_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE19(i)  :=ZX_TAXWARE_USER_PKG.crit_flag_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE20(i)  :=ZX_TAXWARE_USER_PKG.arp_poo_add_code_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE21(i)  :=ZX_TAXWARE_USER_PKG.calculation_flag_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE22(i)  :=ZX_TAXWARE_USER_PKG.state_cert_no_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE23(i)  :=ZX_TAXWARE_USER_PKG.county_cert_no_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE24(i)  :=ZX_TAXWARE_USER_PKG.city_cert_no_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE1(i)    :=ZX_TAXWARE_USER_PKG.arp_state_exempt_percent_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE2(i)    :=ZX_TAXWARE_USER_PKG.arp_county_exempt_pct_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE3(i)    :=ZX_TAXWARE_USER_PKG.arp_city_exempt_pct_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE4(i)    :=ZX_TAXWARE_USER_PKG.sec_county_exempt_pct_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE5(i)    :=ZX_TAXWARE_USER_PKG.sec_city_exempt_pct_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE6(i)    :=ZX_TAXWARE_USER_PKG.arp_tax_sel_param_tab(1);
            ZX_PTNR_NEG_LINES_TAB.LINE_EXT_DATE_ATTRIBUTE1(i)	:=ZX_TAXWARE_USER_PKG.arp_transaction_date_tab(1);
          END IF;

          ZX_TAXWARE_USER_PKG.g_line_negation := FALSE;
        end if;
        IF l_count = 0 THEN
          delete from ZX_TRX_PRE_PROC_OPTIONS_GT
          where APPLICATION_ID	= p_event_class_rec.application_id
          AND  ENTITY_CODE    	= p_event_class_rec.entity_code
          AND  EVENT_CLASS_CODE = p_event_class_rec.event_class_code
          AND  TRX_ID 		      = zx_ptnr_neg_lines_tab.trx_id(i);
        END IF;
      End loop;

      IF ZX_API_PUB.G_PUB_SRVC NOT IN ('GLOBAL_DOCUMENT_UPDATE', 'OVERRIDE_TAX') THEN            -- Bug 5200373
        DELETE FROM ZX_TRX_PRE_PROC_OPTIONS_GT
        WHERE APPLICATION_ID   = p_event_class_rec.APPLICATION_ID
        AND ENTITY_CODE      = p_event_class_rec.ENTITY_CODE
        AND EVENT_CLASS_CODE = p_event_class_rec.EVENT_CLASS_CODE
        AND TRX_ID           = p_event_class_rec.TRX_ID;
      END IF;

      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,
        ' updating zx_ptnr_neg_line_gt');
      END IF;

      FORALL i IN  zx_ptnr_neg_lines_tab.application_id.FIRST ..  zx_ptnr_neg_lines_tab.application_id.LAST
        Update ZX_PTNR_NEG_LINE_GT SET
          LINE_EXT_VARCHAR_ATTRIBUTE1 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE1(i)  ,
          LINE_EXT_VARCHAR_ATTRIBUTE2 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE2(i)  ,
          LINE_EXT_VARCHAR_ATTRIBUTE3 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE3(i)  ,
          LINE_EXT_VARCHAR_ATTRIBUTE4 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE4(i)  ,
          LINE_EXT_VARCHAR_ATTRIBUTE5 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE5(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE6 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE6(i)  ,
          LINE_EXT_VARCHAR_ATTRIBUTE7 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE7(i)  ,
          LINE_EXT_VARCHAR_ATTRIBUTE8 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE8(i)  ,
          LINE_EXT_VARCHAR_ATTRIBUTE9 	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE9(i)  ,
          LINE_EXT_VARCHAR_ATTRIBUTE10	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE10(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE11	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE11(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE12	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE12(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE13	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE13(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE14	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE14(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE15	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE15(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE16	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE16(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE17	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE17(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE18	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE18(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE19	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE19(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE20	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE20(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE21	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE21(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE22	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE22(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE23	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE23(i) ,
          LINE_EXT_VARCHAR_ATTRIBUTE24	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_VARCHAR_ATTRIBUTE24(i) ,
          LINE_EXT_NUMBER_ATTRIBUTE1  	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE1(i)   ,
          LINE_EXT_NUMBER_ATTRIBUTE2  	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE2(i)   ,
          LINE_EXT_NUMBER_ATTRIBUTE3  	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE3(i)   ,
          LINE_EXT_NUMBER_ATTRIBUTE4  	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE4(i)   ,
          LINE_EXT_NUMBER_ATTRIBUTE5  	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE5(i)   ,
          LINE_EXT_NUMBER_ATTRIBUTE6  	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_NUMBER_ATTRIBUTE6(i)   ,
          LINE_EXT_DATE_ATTRIBUTE1	= ZX_PTNR_NEG_LINES_TAB.LINE_EXT_DATE_ATTRIBUTE1(i)
        WHERE APPLICATION_ID   = p_event_class_rec.APPLICATION_ID
        AND   ENTITY_CODE      = p_event_class_rec.ENTITY_CODE
        AND   EVENT_CLASS_CODE = p_event_class_rec.EVENT_CLASS_CODE
        AND   TRX_ID           = zx_ptnr_neg_lines_tab.TRX_ID(i)
        AND   TRX_LINE_ID      = zx_ptnr_neg_lines_tab.TRX_LINE_ID(i)
        AND   TRX_LEVEL_TYPE   = zx_ptnr_neg_lines_tab.TRX_LEVEL_TYPE(i);
    end if;
    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
    END IF;
 END COPY_TRX_LINE_FOR_PTNR_BEF_UPD;

 PROCEDURE CREATE_SRVC_REGISTN_FROM_UI
 (p_api_version		IN	NUMBER,
  x_error_msg	   OUT NOCOPY   VARCHAR2,
  x_return_status  OUT NOCOPY   VARCHAR2,
  p_srvc_prvdr_id	IN      NUMBER,
  p_regime_usage_id	IN	NUMBER,
  p_business_flow	IN	VARCHAR2) IS

  l_api_name         CONSTANT VARCHAR2(80) := 'CREATE_SRVC_REGISTN_FROM_UI';
  l_error_counter              NUMBER;
  l_srvc_prvdr_name            VARCHAR2(80);
  x_error_msg_tbl	       ERROR_MESSAGE_TBL%TYPE;
  p_country_code	       VARCHAR2(30);

Begin
    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;
    /*Set the return status to Success */
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    l_error_counter := 1;

    /*Fetch the parnter name*/

    select tax_regime_code
      into p_country_code
    from zx_regimes_usages
    where regime_usage_id=p_regime_usage_id;

    IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,' p_srvc_prvdr_id :'||p_srvc_prvdr_id);
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,' p_country_code :'||p_country_code);
	FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,' p_business_flow :'||p_business_flow);
     END IF;

   Begin
    SELECT pty.party_name
         INTO  l_srvc_prvdr_name
         FROM HZ_PARTIES pty,
              ZX_PARTY_TAX_PROFILE ptp
        WHERE ptp.party_tax_profile_id =p_srvc_prvdr_id
          AND pty.party_id = ptp.party_id
          AND ptp.provider_type_code in ('BOTH', 'SERVICE');
   Exception
     When others then
       -- fnd_message.set_name('ZX', 'ZX_TAX_PARTNER_NOTFOUND');
       x_error_msg_tbl(l_error_counter) := fnd_message.get;
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
       l_error_counter := l_error_counter+1;
       return;
   End;

   IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,' l_srvc_prvdr_name :'|| l_srvc_prvdr_name);
   END IF;


if(p_srvc_prvdr_id = 1) then

    ZX_API_PRVDR_PUB.create_srvc_registration(
	p_api_version,
	x_error_msg_tbl,
	x_return_status,
	l_srvc_prvdr_name,
	'CALCULATE_TAX',
	p_country_code,
	p_business_flow,
	'ZX_VERTEX_TAX_SERVICE_PKG',
	'CALCULATE_TAX_API');

	ZX_API_PRVDR_PUB.create_srvc_registration(
	p_api_version,
	x_error_msg_tbl,
	x_return_status,
	l_srvc_prvdr_name,
	'SYNCHRONIZE_FOR_TAX',
	p_country_code,
	p_business_flow,
	'ZX_VERTEX_TAX_SERVICE_PKG',
	'SYNCHRONIZE_VERTEX_REPOSITORY');


ZX_API_PRVDR_PUB.create_srvc_registration(
	p_api_version,
	x_error_msg_tbl,
	x_return_status,
	l_srvc_prvdr_name,
	'DOCUMENT_LEVEL_CHANGES',
	p_country_code,
	p_business_flow,
	'ZX_VERTEX_TAX_SERVICE_PKG',
	'GLOBAL_DOCUMENT_UPDATE');

elsif(p_srvc_prvdr_id = 2) then
  ZX_API_PRVDR_PUB.create_srvc_registration(
	p_api_version,
	x_error_msg_tbl,
	x_return_status,
	l_srvc_prvdr_name,
	'CALCULATE_TAX',
	p_country_code,
	p_business_flow,
	'ZX_TAXWARE_TAX_SERVICE_PKG',
	'CALCULATE_TAX_API');

   ZX_API_PRVDR_PUB.create_srvc_registration(
	p_api_version,
	x_error_msg_tbl,
	x_return_status,
	l_srvc_prvdr_name,
	'SYNCHRONIZE_FOR_TAX',
	p_country_code,
	p_business_flow,
	'ZX_TAXWARE_TAX_SERVICE_PKG',
	'SYNCHRONIZE_TAXWARE_REPOSITORY');

  ZX_API_PRVDR_PUB.create_srvc_registration(
	p_api_version,
	x_error_msg_tbl,
	x_return_status,
	l_srvc_prvdr_name,
	'DOCUMENT_LEVEL_CHANGES',
	p_country_code,
	p_business_flow,
	'ZX_TAXWARE_TAX_SERVICE_PKG',
	'GLOBAL_DOCUMENT_UPDATE');
 else
       --fnd_message.set_name('ZX', 'ZX_TAX_PARTNER_NOTFOUND');
       x_error_msg_tbl(l_error_counter) := fnd_message.get;
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
       l_error_counter := l_error_counter+1;
       return;

       IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(falied -)');
    END IF;


 End if;

    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(-)');
    END IF;

End CREATE_SRVC_REGISTN_FROM_UI;

procedure CREATE_EXTN_REGISTN_FROM_UI
  (p_api_version      IN  NUMBER,
   x_error_msg    OUT NOCOPY varchar2,
   x_return_status    OUT NOCOPY VARCHAR2,
   p_srvc_prvdr_id    IN  NUMBER,
   p_regime_usage_id  IN  NUMBER,
   p_code_generator_flag IN  VARCHAR2) is

l_context_flex_structure_id	NUMBER;
l_error_counter			NUMBER;

l_api_name varchar2(80) := 'CREATE_EXTN_REGISTN_FROM_UI';
l_tax_regime_code  ZX_REGIMES_USAGES.tax_regime_code%type;
x_error_msg_tbl    error_message_tbl%type;
l_api_owner_id number;
l_context_cc_id number;

Begin
    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;
    /*Set the return status to Success */
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    l_error_counter := 1;

Begin
SELECT context_flex_structure_id
      INTO l_context_flex_structure_id
      FROM ZX_SERVICE_TYPES
     WHERE service_category_code = 'USER_EXT'
       AND rownum=1;
 Exception when others then
       x_error_msg_tbl(l_error_counter) := 'No service type defined for user extension';
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
       l_error_counter := l_error_counter+1;
       return;
  END;


  Begin
      SELECT distinct ru.tax_regime_code
         into l_tax_regime_code
          FROM zx_regimes_usages ru,
               zx_srvc_subscriptions srvc
         WHERE srvc.regime_usage_id=p_regime_usage_id
	   and srvc.regime_usage_id=ru.regime_usage_id
        AND NOT EXISTS (SELECT 1
                         FROM ZX_API_CODE_COMBINATIONS comb
                        WHERE comb.segment_attribute1 = ru.tax_regime_code
                          AND comb.segment_attribute2 is null
                       );
  Exception
     when others then
     l_tax_regime_code :=  NULL;
  End;

  IF (p_srvc_prvdr_id IN (1,2)) THEN --bug8746079
   if (l_tax_regime_code is not NULL) then
      INSERT INTO ZX_API_CODE_COMBINATIONS (
          CONTEXT_FLEX_STRUCTURE_ID,
          CODE_COMBINATION_ID,
          SEGMENT_ATTRIBUTE1,
          SUMMARY_FLAG,
          ENABLED_FLAG,
          RECORD_TYPE_CODE,
          CREATION_DATE,
          CREATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_LOGIN)
        VALUES (l_context_flex_structure_id,
                ZX_API_CODE_COMBINATIONS_S.nextval,
                l_tax_regime_code,
                'N',
                'Y',
                'EBTAX_CREATED',
                sysdate,                       --creation_date
                fnd_global.user_Id,            --created_by
                sysdate,                       --last_update_date
                fnd_global.user_id,            --last_updated_by
                fnd_global.conc_login_id       --last_update_login
                );


      INSERT INTO ZX_API_REGISTRATIONS (
         API_REGISTRATION_ID,
         API_OWNER_ID,
         CONTEXT_CCID,
         PACKAGE_NAME,
         PROCEDURE_NAME,
         SERVICE_TYPE_ID,
         RECORD_TYPE_CODE,
         OBJECT_VERSION_NUMBER,
         CREATION_DATE,
         CREATED_BY,
         LAST_UPDATE_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_LOGIN
         )
      SELECT ZX_API_REGISTRATIONS_S.nextval,
               ru.first_pty_org_id,
               comb.code_combination_id,
               decode(srvc.srvc_provider_id,1,'ZX_VTX_USER_PKG','ZX_TAXWARE_USER_PKG'),
               decode(srvctypes.service_type_code,'DERIVE_HDR_ATTRS','DERIVE_HDR_EXT_ATTR',
                                                  'DERIVE_LINE_ATTRS','DERIVE_LINE_EXT_ATTR'),
               srvctypes.service_type_id,
               'EBTAX_CREATED',
               1,
               sysdate,                       --creation_date
               fnd_global.user_Id,            --created_by
               sysdate,                       --last_update_date
               fnd_global.user_id,            --last_updated_by
               fnd_global.conc_login_id       --last_update_login;
         FROM  ZX_REGIMES_USAGES ru,
               ZX_API_CODE_COMBINATIONS comb,
               ZX_SRVC_SUBSCRIPTIONS srvc,
               ZX_SERVICE_TYPES srvctypes
        WHERE ru.regime_usage_id = p_regime_usage_id
	  AND srvc.srvc_provider_id = p_srvc_prvdr_id
	  AND srvctypes.context_flex_structure_id= l_context_flex_structure_id
	  AND srvc.regime_usage_id = ru.regime_usage_id
          AND ru.tax_regime_code = comb.segment_attribute1
          AND comb.segment_attribute2 is null
          AND comb.context_flex_structure_id = srvctypes.context_flex_structure_id
          AND srvctypes.service_type_code in ('DERIVE_HDR_ATTRS','DERIVE_LINE_ATTRS')
          AND  NOT EXISTS (SELECT   1
                           FROM ZX_API_REGISTRATIONS api
                           WHERE api.service_type_id = srvctypes.service_type_id
                             AND api.context_ccid = comb.code_combination_id
                             AND api.api_owner_id  = ru.first_pty_org_id
                           );


      INSERT INTO zx_api_owner_statuses (
	 API_OWNER_ID,
	 SERVICE_CATEGORY_CODE,
	 STATUS_CODE,
         CREATION_DATE,
         CREATED_BY,
         LAST_UPDATE_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_LOGIN
         )
      SELECT ru.first_pty_org_id,
	       'USER_EXT',
	       'NEW',
                sysdate,                       --creation_date
                fnd_global.user_Id,            --created_by
                sysdate,                       --last_update_date
                fnd_global.user_id,            --last_updated_by
                fnd_global.conc_login_id       --last_update_login;
           FROM ZX_SRVC_SUBSCRIPTIONS srvc,
                ZX_REGIMES_USAGES ru
          WHERE ru.regime_usage_id =   p_regime_usage_id
	    AND srvc.srvc_provider_id = p_srvc_prvdr_id
	    AND srvc.regime_usage_id = ru.regime_usage_id
            AND NOT EXISTS (SELECT 1
                              FROM ZX_API_OWNER_STATUSES sts
                             WHERE sts.api_owner_id = ru.first_pty_org_id
                           );

if(p_code_generator_flag = 'Y') then
  Begin
      select ru.first_pty_org_id,
             comb.code_combination_id
        INTO l_api_owner_id,
	     l_context_cc_id
        FROM  ZX_REGIMES_USAGES ru,
               ZX_API_CODE_COMBINATIONS comb,
               ZX_SRVC_SUBSCRIPTIONS srvc,
               ZX_SERVICE_TYPES srvctypes
        WHERE ru.regime_usage_id = p_regime_usage_id
	  AND srvc.srvc_provider_id = p_srvc_prvdr_id
	  AND srvctypes.context_flex_structure_id= l_context_flex_structure_id
	  AND srvc.regime_usage_id = ru.regime_usage_id
          AND ru.tax_regime_code = comb.segment_attribute1
          AND comb.segment_attribute2 is null
          AND comb.context_flex_structure_id = srvctypes.context_flex_structure_id
          AND srvctypes.service_type_code in ('DERIVE_HDR_ATTRS','DERIVE_LINE_ATTRS');

	EXECUTE_EXTN_PLUGIN_FROM_UI(P_API_VERSION   => 1.0,
				    X_ERROR_MSG     => x_error_msg,
				    X_RETURN_STATUS => x_return_status ,
				    P_API_OWNER_ID  => l_api_owner_id ,
				    P_CONTEXT_CC_ID => l_context_cc_id  );
  Exception When Others then
       x_error_msg_tbl(l_error_counter) := fnd_message.get;
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
       l_error_counter := l_error_counter+1;
       return;
   End;

END if;
END IF; -- p_srvc_prvdr_id

    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(-)');
    END IF;


   END IF;

   End CREATE_EXTN_REGISTN_FROM_UI;

Procedure execute_srvc_plugin_from_ui
(  p_api_version      IN	 NUMBER,
   x_error_msg        OUT NOCOPY VARCHAR2,
   x_return_status    OUT NOCOPY VARCHAR2,
   p_srvc_prvdr_id    IN	 NUMBER) is

   l_srvc_prvdr_name varchar2(80);
   l_error_counter   number;
   l_api_name constant varchar2(80) := 'EXECUTE_SRVC_PLUGIN_FROM_UI';
   x_error_msg_tbl    error_message_tbl%type;

   Begin
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;
    /*Set the return status to Success */
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    l_error_counter := 1;

    /*Fetch the parnter name*/

   Begin
    SELECT pty.party_name
         INTO  l_srvc_prvdr_name
         FROM HZ_PARTIES pty,
              ZX_PARTY_TAX_PROFILE ptp
        WHERE ptp.party_tax_profile_id =p_srvc_prvdr_id
          AND pty.party_id = ptp.party_id
          AND ptp.provider_type_code in ('BOTH', 'SERVICE');
   Exception
     When others then
       --fnd_message.set_name('ZX', 'ZX_TAX_PARTNER_NOTFOUND');
       x_error_msg_tbl(l_error_counter) := fnd_message.get;
       x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
       l_error_counter := l_error_counter+1;
       return;
   End;

	ZX_API_PRVDR_PUB.execute_srvc_plugin(p_api_version  ,
						x_error_msg_tbl,
						x_return_status,
						l_srvc_prvdr_name);

	IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
		x_error_msg_tbl(l_error_counter) := fnd_message.get;
		-- x_return_status := FND_API.G_RET_STS_ERROR;
		l_error_counter := l_error_counter+1;
		return;
	End if;

    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;

End execute_srvc_plugin_from_ui;

Procedure execute_extn_plugin_from_ui
(  p_api_version      IN  NUMBER,
   x_error_msg    OUT NOCOPY varchar2,
   x_return_status    OUT NOCOPY VARCHAR2,
   p_api_owner_id     IN  number,
   p_context_cc_id    IN  number) is

   l_srvc_provider_id number;
   l_error_counter   number;
   l_api_name constant  varchar2(80) := 'EXECUTE_EXTN_PLUGIN_FROM_UI';
   l_request_id number;
   x_error_msg_tbl    error_message_tbl%type;

   Begin
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;
    /*Set the return status to Success */
    x_return_status := FND_API.G_RET_STS_SUCCESS;
    l_error_counter := 1;

      Begin
	Select
	  distinct srvc.srvc_provider_id
	into l_srvc_provider_id
	  from zx_api_code_combinations comb,
	  zx_regimes_usages usage,
          zx_srvc_subscriptions srvc
	where comb.code_combination_id= p_context_cc_id
	and   comb.segment_attribute1= usage.tax_regime_code
	and   comb.segment_attribute2= 'O2C'
	and   usage.first_pty_org_id= p_api_owner_id
	and   srvc.regime_usage_id=usage.regime_usage_id
	and not exists (select 1 from zx_api_registrations
	                   where API_OWNER_ID = srvc.srvc_provider_id
			   and	CONTEXT_CCID = p_context_cc_id);
      Exception
        When others then
	 l_srvc_provider_id := NULL;
      End;

     IF(l_srvc_provider_id is not NULL) then
	execute_srvc_plugin_from_ui(p_api_version,
		                    x_error_msg,
				    x_return_status,
				    l_srvc_provider_id);
     End if;

savepoint execute_srvc_plugin_pvt;

      Begin
	l_request_id  := fnd_request.submit_request
                       (
                         application      => 'ZX',
                         program          => 'ZXPTNRSRVCPLUGIN',
                         sub_request      => false,
                         argument1        => 'USER_EXT',
                         argument2        => P_api_owner_id
                        );
	commit;

      EXCEPTION
       WHEN OTHERS THEN
         ROLLBACK TO execute_srvc_plugin_pvt;
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
         fnd_message.set_name('ZX', 'ZX_UNEXPECTED_ERROR');
         x_error_msg_tbl(l_error_counter) := fnd_message.get;
         l_error_counter := l_error_counter+1;
         IF ( G_LEVEL_UNEXPECTED >= G_CURRENT_RUNTIME_LEVEL) THEN
            FND_LOG.STRING(G_LEVEL_UNEXPECTED,G_MODULE_NAME||l_api_name,SQLERRM);
         END IF;
      End;

    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
    END IF;

  END  execute_extn_plugin_from_ui;

END zx_r11i_tax_partner_pkg;
/
SHOW ERROR