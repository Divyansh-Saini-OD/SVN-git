create or replace PACKAGE BODY ZX_TAX_TAXWARE_REV AS
/* $Header: zxtxtrevb.pls 120.4.12020000.2 2014/10/22 05:45:46 srajapar ship $ */

/* ======================================================================*
 | Global Structure Data Types                                           |
 * ======================================================================*/

G_CURRENT_RUNTIME_LEVEL  CONSTANT NUMBER   := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_UNEXPECTED       CONSTANT NUMBER   := FND_LOG.LEVEL_UNEXPECTED;
G_LEVEL_ERROR            CONSTANT NUMBER   := FND_LOG.LEVEL_ERROR;
G_LEVEL_EXCEPTION        CONSTANT NUMBER   := FND_LOG.LEVEL_EXCEPTION;
G_LEVEL_EVENT            CONSTANT NUMBER   := FND_LOG.LEVEL_EVENT;
G_LEVEL_PROCEDURE        CONSTANT NUMBER   := FND_LOG.LEVEL_PROCEDURE;
G_LEVEL_STATEMENT        CONSTANT NUMBER   := FND_LOG.LEVEL_STATEMENT;

/*----------------------------------------------------------------------------*
 | PUBLIC FUNCTION                                                            |
 |    Get_Release                                                             |
 |                                                                            |
 | DESCRIPTION                                                                |
 |                                                                            |
 |    The function will return                                                |
 |      '0' on successful install check of Taxware                            |
 |      '9' if the product is not installed OR any other unexpected errors    |
 |                                                                            |
 +----------------------------------------------------------------------------*/
FUNCTION Get_Release RETURN VARCHAR2 IS

  l_module   CONSTANT VARCHAR2(50) := 'ZX.PLSQL.ZX_TAX_TAXWARE_REV.get_release';
  l_string            VARCHAR2(200);
  pg_release_number   VARCHAR2(50) := NULL;
  ----------------------------
  -- SuB-Procedures Section
  ----------------------------
  PROCEDURE error_exception_handle_pvt(str  varchar2) is

    cursor error_exception_cursor is
      select EVNT_CLS_MAPPING_ID,
             TRX_ID,
             TAX_REGIME_CODE
      from ZX_TRX_PRE_PROC_OPTIONS_GT;

    l_docment_type_id number;
    l_trasaction_id   number;
    l_tax_regime_code varchar2(80);

  Begin
    open error_exception_cursor;
    fetch error_exception_cursor into l_docment_type_id,l_trasaction_id,l_tax_regime_code;

    ZX_TAXWARE_TAX_SERVICE_PKG.G_MESSAGES_TBL.DOCUMENT_TYPE_ID(zx_taxware_TAX_SERVICE_PKG.err_count)  := l_docment_type_id;
    zx_taxware_TAX_SERVICE_PKG.G_MESSAGES_TBL.TRANSACTION_ID(zx_taxware_TAX_SERVICE_PKG.err_count)    := l_trasaction_id;
    zx_taxware_TAX_SERVICE_PKG.G_MESSAGES_TBL.COUNTRY_CODE(zx_taxware_TAX_SERVICE_PKG.err_count)    := l_tax_regime_code;
    zx_taxware_TAX_SERVICE_PKG.G_MESSAGES_TBL.ERROR_MESSAGE_TYPE(zx_taxware_TAX_SERVICE_PKG.err_count)  := 'ERROR';
    zx_taxware_TAX_SERVICE_PKG.G_MESSAGES_TBL.ERROR_MESSAGE_STRING(zx_taxware_TAX_SERVICE_PKG.err_count)  := str;
    zx_taxware_TAX_SERVICE_PKG.err_count :=zx_taxware_TAX_SERVICE_PKG.err_count+1;

    close error_exception_cursor;
  END error_exception_handle_pvt;

  -- pg_compatible_release_number VARCHAR2(50) := '3.5';
  -- pg_comp_rel_num_major CONSTANT  BINARY_INTEGER := 3;
  -- pg_comp_rel_num_minor_low CONSTANT  BINARY_INTEGER := 1;
  -- pg_comp_rel_num_minor_high CONSTANT  BINARY_INTEGER := 5;
  -- pg_compatable_release  BOOLEAN := FALSE;
  ----------------------------------
  -- MAIN Section for GET_RELEASE
  ----------------------------------
BEGIN

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure, l_module,
               'ZX_TAX_TAXWARE_REV.GET_RELEASE(+)');
  END IF;

  /*-----------------------------------------------------------
   | Retrieve product version information.                    |
   -----------------------------------------------------------*/
  --pg_release_number := rtrim(ltrim(ZX_TAX_TAXWARE_010.TAXFN_release_number)); --NAIT-185309
  pg_release_number := 0;  -- NAIT-185309

  IF ( g_level_procedure >= g_current_runtime_level) THEN
    FND_LOG.STRING(g_level_procedure, l_module,
        'Version Number: '||pg_release_number);
    FND_LOG.STRING(g_level_procedure, l_module,
        'major: '||substrb(pg_release_number, 1,instrb(pg_release_number, '.')-1));
    FND_LOG.STRING(g_level_procedure, l_module,
        'minor: '||substrb(pg_release_number, instrb(pg_release_number,'.')+1,1));
  END IF;

  --------------------------------------------------------------
  -- bug 18958155
  -- avoiding check of major and minor version
  --------------------------------------------------------------
  -- IF to_number(substrb(pg_release_number, 1,
  --     instrb(pg_release_number, '.')-1)) <> pg_comp_rel_num_major THEN
  --
  --  pg_compatible_release := FALSE;
  --  IF ( g_level_exception  >= g_current_runtime_level) THEN
  --           FND_LOG.STRING(g_level_exception,'ZX_TAX_TAXWARE_REV.GET_RELEASE',
  --           'Version Error: '||to_char(SQLCODE)||SQLERRM);
  --  END IF;
  --  --x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
  --  l_string :='Release number of Taxware SALES/USE TAX SYSTEM is '||
  --                  pg_release_number||' on this system. '||
  --      'Oracle Application supports only '||pg_comp_rel_num_major||'.'||
  --                   pg_comp_rel_num_minor_low ||' through  '||pg_comp_rel_num_major||'.'||
  --                   pg_comp_rel_num_minor_high ||'.'||' Please contact Taxware representatives.';
  --  error_exception_handle_pvt(l_string);
  --  RETURN ('9');

  -- ELSE
  --  --  major release = 3, check for minor release
  --  IF to_number(substrb(pg_release_number,
  --          instrb(pg_release_number,'.')+1,1)) > pg_comp_rel_num_minor_high
  --  or
  --     to_number(substrb(pg_release_number,
  --          instrb(pg_release_number,'.')+1,1)) < pg_comp_rel_num_minor_low
  --  THEN
  --      pg_compatible_release := FALSE;
  --
  --    IF ( g_level_exception  >= g_current_runtime_level) THEN
  --           FND_LOG.STRING(g_level_exception,'ZX_TAX_TAXWARE_REV.GET_RELEASE',
  --           'Version Error: '||to_char(SQLCODE)||SQLERRM);
  --    END IF;
  --  --x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
  --  l_string :='Release number of Taxware SALES/USE TAX SYSTEM is '||
  --                  pg_release_number||' on this system. '||
  --      'Oracle Application supports only '||pg_comp_rel_num_major||'.'||
  --                   pg_comp_rel_num_minor_low ||' through  '||pg_comp_rel_num_major||'.'||
  --                   pg_comp_rel_num_minor_high ||'.'||' Please contact Taxware representatives.';
  --    error_exception_handle_pvt(l_string);
  --    RETURN ('9');
  --
  --  ELSE
  --        pg_compatible_release := TRUE;
  --  END IF;
  --
  --END IF;

  IF ( g_level_procedure >= g_current_runtime_level) THEN
    FND_LOG.STRING(g_level_procedure, l_module,
        'ZX_TAX_TAXWARE_REV.GET_RELEASE(TRUE)-');
  END IF;
  RETURN('0');

EXCEPTION
  WHEN OTHERS THEN
    IF ( g_level_exception  >= g_current_runtime_level) THEN
      FND_LOG.STRING(g_level_exception, l_module,
        'ZX_TAX_TAXWARE_REV.GET_RELEASE(FALSE)-');
      FND_LOG.STRING(g_level_exception, l_module,
              'SQLERRM: '||to_char(SQLCODE)||' - ' ||SQLERRM);
    END IF;
    l_string :='Not compaitable to TAXWARE Release';
    error_exception_handle_pvt(l_string);
    RETURN ('9');
END Get_Release;

END ZX_TAX_TAXWARE_REV;
/
show error;