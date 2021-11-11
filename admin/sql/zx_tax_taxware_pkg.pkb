create or replace package body zx_tax_taxware_pkg as
/* $Header: zxtaxwarepkgb.pls 120.3 2006/06/24 01:24:45 svaze ship $ */

/* ======================================================================*
 | FND Logging infrastructure                                           |
 * ======================================================================*/
G_PKG_NAME                  CONSTANT VARCHAR2(30) := 'ZX_TAX_TAXWARE_PKG';
G_CURRENT_RUNTIME_LEVEL     CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_UNEXPECTED          CONSTANT NUMBER       := FND_LOG.LEVEL_UNEXPECTED;
G_LEVEL_ERROR               CONSTANT NUMBER       := FND_LOG.LEVEL_ERROR;
G_LEVEL_EXCEPTION           CONSTANT NUMBER       := FND_LOG.LEVEL_EXCEPTION;
G_LEVEL_EVENT               CONSTANT NUMBER       := FND_LOG.LEVEL_EVENT;
G_LEVEL_PROCEDURE           CONSTANT NUMBER       := FND_LOG.LEVEL_PROCEDURE;
G_LEVEL_STATEMENT           CONSTANT NUMBER       := FND_LOG.LEVEL_STATEMENT;
G_MODULE_NAME               CONSTANT VARCHAR2(80) := 'ZX.PLSQL.ZX_TAX_TAXWARE_PKG.';

pg_TAXWARE_INSTALLED        CHAR := NULL;

FUNCTION IS_GEOCODE_VALID(p_geocode IN VARCHAR2) return BOOLEAN is
l_api_name             CONSTANT VARCHAR2(30) := 'IS_GEOCODE_VALID';

BEGIN

   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
   END IF;

   IF (lengthb(p_geocode) = 9 and
       substrb(p_geocode, 1, 2) between 'AA' and 'ZZ' and
       substrb(p_geocode, 3, 7) between '0000000' and '9999999' )
   THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Geocode is valid.');
      END IF;
      IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
      END IF;
      return TRUE;
   ELSE
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Gecode is invalid.');
      END IF;
      FND_MESSAGE.SET_NAME('ZX','GENERIC_MESSAGE');
      FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','For TAXWARE, enter two letters for state follwed by five digits for ZIP code and two more digits for Geocode');
      FND_MSG_PUB.ADD();      -- Bug 5331410
      IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
      END IF;
      return FALSE;
   END IF;

END;

FUNCTION IS_CITY_LIMIT_VALID(p_city_limit IN VARCHAR2)return BOOLEAN is
l_api_name             CONSTANT VARCHAR2(30) := 'IS_CITY_LIMIT_VALID';
BEGIN

   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
   END IF;

   IF (p_city_limit = '1' OR p_city_limit = '0') THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'City limit is valid.');
      END IF;
      IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
      END IF;
      return TRUE;
   ELSE
     IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'City limit is invalid.');
     END IF;
     FND_MESSAGE.SET_NAME('ZX','GENERIC_MESSAGE');
     FND_MESSAGE.SET_TOKEN('GENERIC_TEXT','The City Limit should be either ''0'' or ''1''');
     FND_MSG_PUB.ADD();      -- Bug 5331410
     IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
        FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
     END IF;
     return FALSE;
   END IF;
END;

/* Bug 5139634: This function checks if Taxware has been installed in the customer instance
                and accordingly return the existence of Taxware to api (TAX_VENDOR_EXTENSION).
*/
FUNCTION INSTALLED return BOOLEAN is
l_api_name                    CONSTANT VARCHAR2(30) := 'INSTALLED';


BEGIN
   IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
      FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.BEGIN',G_PKG_NAME||': '||l_api_name||'(+)');
   END IF;

   IF ( pg_TAXWARE_INSTALLED IS NULL ) THEN

     /*------------------------------------------------------------+
      | The trick is to instantiate the stub package constructor   |
      | by accessing the Taxware stub. If the stub is still        |
      | being used exception ZX_TAX_TAXWARE.TAXWARE_NOT_INSTALLED  |
      | will be raised. If Taxware is installed, We should not see |
      | the exception and we return TRUE.                          |
      | Note: Since the exception is raised from the stub          |
      |       constructor (hence executed the first time the stub  |
      |       is called) We need to store the result in a package  |
      |       global variable.                                     |
      +------------------------------------------------------------*/
    --  ZX_TAX_TAXWARE_GEN.SELPARMTYP := '1';  -- NAIT-185309 commented
      pg_TAXWARE_INSTALLED := 'Y';

   END IF;

   IF ( pg_TAXWARE_INSTALLED = 'Y' ) THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Taxware is installed.');
      END IF;

      IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
      END IF;
      return TRUE;
   ELSE
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Taxware is not installed.');
      END IF;
      IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
      END IF;
      return FALSE;
   END IF;

EXCEPTION
  when ZX_TAX_TAXWARE_PKG.TAXWARE_NOT_INSTALLED then
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_STATEMENT,G_MODULE_NAME||l_api_name,'Taxware is not installed.');
      END IF;
      IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME||l_api_name||'.END',G_PKG_NAME || ': ' ||l_api_name||'(-)');
      END IF;
      pg_TAXWARE_INSTALLED := 'N';
      return FALSE;

  when OTHERS then
       IF ( G_LEVEL_EXCEPTION >= G_CURRENT_RUNTIME_LEVEL) THEN
         FND_LOG.STRING(G_LEVEL_EXCEPTION,G_MODULE_NAME||l_api_name,SQLERRM);
       END IF;
       pg_TAXWARE_INSTALLED := 'N';
       return FALSE;
END;   -- Function INSTALLED

End zx_tax_taxware_pkg;