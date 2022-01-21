create or replace PACKAGE BODY ZX_TRD_SERVICES_PUB_PKG AS
 /* $Header: zxmwrecdmsrvpubb.pls 120.172.12020000.15 2015/04/04 19:34:59 ssanka ship $ */

 /* Declare constants */

 G_PKG_NAME      CONSTANT VARCHAR2(30)   := 'zx_trd_services_pub_pkg';
 G_MSG_UERROR    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_UNEXP_ERROR;
 G_MSG_ERROR     CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_ERROR;
 G_MSG_SUCCESS   CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_SUCCESS;

 G_MSG_HIGH      CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_HIGH;
 G_MSG_MEDIUM    CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_MEDIUM;
 G_MSG_LOW       CONSTANT NUMBER         := FND_MSG_PUB.G_MSG_LVL_DEBUG_LOW;

 TYPE l_jursidiction_id_rec_type IS RECORD(
     location_id                     NUMBER,
     location_type                   VARCHAR2(30),
     tax_jurisdiction_id             NUMBER
);

TYPE l_jursidiction_id_tbl_type IS TABLE OF l_jursidiction_id_rec_type INDEX BY BINARY_INTEGER;
l_jursidiction_id_tbl l_jursidiction_id_tbl_type;

 TYPE geography_type_use_type is TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
 TYPE geography_type_num_type is TABLE OF NUMBER INDEX BY BINARY_INTEGER;

 l_geography_type geography_type_use_type;
 l_geography_use  geography_type_use_type;
 l_geography_type_num geography_type_num_type;

TYPE l_party_rec_type is RECORD(
 party_id              NUMBER,
 party_tax_profile_id  NUMBER
);
TYPE l_party_tbl_type is TABLE OF l_party_rec_type index by VARCHAR2(150);
l_party_tbl    l_party_tbl_type;


 p_error_buffer  VARCHAR2(200);

 /* dummy variables */
 NUMBER_DUMMY CONSTANT NUMBER(15)     := -999999999999999;
 VAR_30_DUMMY CONSTANT VARCHAR2(30)   := '@@@###$$$***===';
 DATE_DUMMY   CONSTANT DATE           := TO_DATE('01-01-1951', 'DD-MM-YYYY');

PROCEDURE fetch_tax_lines (
  p_event_class_rec  IN          ZX_API_PUB.EVENT_CLASS_REC_TYPE,
  p_tax_line_tbl     OUT NOCOPY  tax_line_tbl_type,
  x_return_status    OUT NOCOPY  VARCHAR2);

PROCEDURE fetch_tax_distributions(
  p_event_class_rec            IN             ZX_API_PUB.EVENT_CLASS_REC_TYPE,
  p_tax_line_id                IN             NUMBER,
  p_trx_line_dist_id           IN             NUMBER,
  p_rec_nrec_dist_tbl          IN OUT NOCOPY  rec_nrec_dist_tbl_type,
  p_rec_nrec_dist_begin_index  IN             NUMBER,
  p_rec_nrec_dist_end_index       OUT NOCOPY  NUMBER,
  x_return_status                 OUT NOCOPY  VARCHAR2);

PROCEDURE populate_trx_line_info(
  p_tax_line_tbl      IN            tax_line_tbl_type,
  p_index             IN            NUMBER,
  x_return_status        OUT NOCOPY VARCHAR2);

PROCEDURE insert_item_dist(
  p_tax_line_rec     IN              zx_lines%ROWTYPE,
  x_return_status       OUT NOCOPY   VARCHAR2);

PROCEDURE insert_global_table(
  p_rec_nrec_dist_tbl             IN OUT NOCOPY   rec_nrec_dist_tbl_type,
  p_rec_nrec_dist_begin_index     IN OUT NOCOPY   NUMBER,
  p_rec_nrec_dist_end_index       IN OUT NOCOPY   NUMBER,
  x_return_status                    OUT NOCOPY   VARCHAR2);

PROCEDURE populate_mandatory_columns(
  p_rec_nrec_dist_tbl    IN OUT NOCOPY  REC_NREC_DIST_TBL_TYPE,
  x_return_status           OUT NOCOPY  VARCHAR2);

PROCEDURE delete_unnecessary_tax_dists(
  p_event_class_rec  IN             ZX_API_PUB.EVENT_CLASS_REC_TYPE,
  x_return_status       OUT NOCOPY  VARCHAR2);

PROCEDURE get_tax_jurisdiction_id(
  p_tax_line_id          IN            NUMBER,
  p_tax_rate_id          IN            NUMBER,
  p_tax_jurisdiction_id     OUT NOCOPY NUMBER,
  x_return_status           OUT NOCOPY VARCHAR2);

PROCEDURE init_mand_columns(
  p_event_class_rec   IN OUT NOCOPY ZX_API_PUB.event_class_rec_type,
  x_return_status        OUT NOCOPY   VARCHAR2);

g_current_runtime_level      NUMBER;
g_level_statement            CONSTANT  NUMBER   := FND_LOG.LEVEL_STATEMENT;
g_level_procedure            CONSTANT  NUMBER   := FND_LOG.LEVEL_PROCEDURE;
g_level_exception            CONSTANT  NUMBER   := FND_LOG.LEVEL_EXCEPTION;
g_level_event                CONSTANT  NUMBER   := FND_LOG.LEVEL_EVENT;
g_level_unexpected           CONSTANT  NUMBER   := FND_LOG.LEVEL_UNEXPECTED;

l_regime_not_effective        varchar2(2000);
l_tax_not_effective           varchar2(2000);
l_tax_status_not_effective    varchar2(2000);
l_tax_rate_percentage_invalid varchar2(2000);
l_jur_code_not_effective      varchar2(2000);
l_tax_rate_not_effective      varchar2(2000);
l_tax_rate_not_active         varchar2(2000);

/* ===========================================================================*
 |  PUBLIC PROCEDURE determine_recovery                                       |
 |                                                                            |
 |  DESCRIPTION                                                               |
 |  This procedure is used to determine the recoverable and non-recovearble   |
 |  tax distributions for the first time or when after the tax distributions  |
 |  were determined and then tax lines and/or item distributions are updated  |
 |                                                                            |
 |  This procedure will be called directly by TSRM service.                   |
 |                                                                            |
 * ===========================================================================*/

PROCEDURE determine_recovery(
  p_event_class_rec  IN     ZX_API_PUB.event_class_rec_type,
  x_return_status    OUT NOCOPY  VARCHAR2) IS

 CURSOR   get_item_dist_csr(
            c_trx_line_id     zx_lines.trx_line_id%TYPE,
            c_trx_level_type  zx_lines.trx_level_type%TYPE) IS
   SELECT /*+ INDEX(ZX_ITM_DISTRIBUTIONS_GT ZX_ITM_DISTRIBUTIONS_GT_U1 ZX_ITM_DISTRIBUTIONS_GT_U1) */
          trx_line_dist_id,
          trx_line_id,
          trx_level_type,
          dist_level_action,
          item_dist_number,
          dist_intended_use,
          task_id,
          award_id,
          project_id,
          expenditure_type,
          expenditure_organization_id,
          expenditure_item_date,
          trx_line_dist_amt,
          trx_line_dist_qty,
          ref_doc_application_id,
          ref_doc_entity_code,
          ref_doc_event_class_code,
          ref_doc_trx_id,
          ref_doc_line_id,
          ref_doc_trx_level_type,
          ref_doc_dist_id,
          ref_doc_curr_conv_rate,
          trx_line_dist_tax_amt,
          account_ccid,
          account_string,
          price_diff,
          ref_doc_trx_line_dist_qty,
          ref_doc_curr_conv_rate,
          applied_to_doc_curr_conv_rate,
--        applied_from_application_id,              commented out for bug 5580045
--        applied_from_event_class_code,
--        applied_from_entity_code,
--        applied_from_trx_id,
--        applied_from_line_id,
          applied_from_dist_id,      -- add for CR3066321
--        adjusted_doc_application_id,
--        adjusted_doc_event_class_code,
--        adjusted_doc_entity_code,
--        adjusted_doc_trx_id,
--        adjusted_doc_line_id,
          adjusted_doc_dist_id,
          overriding_recovery_rate,
--        applied_from_trx_level_type,
--        adjusted_doc_trx_level_type,
          trx_line_dist_date,          -- AP passes account_date
          char4, --Bug 11675911 / Bug 10621602
          char5,
          unit_price --Bug 20318426
    FROM  zx_itm_distributions_gt
   WHERE  trx_id = p_event_class_rec.trx_id
     AND  application_id = p_event_class_rec.application_id
     AND  entity_code = p_event_class_rec.entity_code
     AND  event_class_code = p_event_class_rec.event_class_code
     AND  trx_line_id = c_trx_line_id
     AND  trx_level_type = c_trx_level_type;

 CURSOR  get_pseuso_line_info_csr(
             c_trx_line_id     zx_lines.trx_line_id%TYPE,
             c_trx_level_type  zx_lines.trx_level_type%TYPE) IS
  SELECT trx_line_id,
         trx_level_type,
         line_intended_use,
         line_amt,
         trx_line_quantity,
         ref_doc_application_id,
         ref_doc_entity_code,
         ref_doc_event_class_code,
         ref_doc_trx_id,
         ref_doc_line_id,
         ref_doc_trx_level_type,
         account_ccid,
         account_string,
         ref_doc_line_quantity,
--       applied_from_application_id,          -- commented out for bug 5580045
--       applied_from_event_class_code,
--       applied_from_entity_code,
--       applied_from_trx_id,
--       applied_from_line_id,
--       adjusted_doc_application_id,
--       adjusted_doc_event_class_code,
--       adjusted_doc_entity_code,
--       adjusted_doc_trx_id,
--       adjusted_doc_line_id,
--       applied_from_trx_level_type,
--       adjusted_doc_trx_level_type,
         nvl(trx_line_gl_date, trx_date)       -- item dist gl date
    FROM zx_lines_det_factors
   WHERE application_id = p_event_class_rec.application_id
     AND event_class_code = p_event_class_rec.event_class_code
     AND entity_code = p_event_class_rec.entity_code
     AND trx_id = p_event_class_rec.trx_id
     AND trx_line_id = c_trx_line_id
     AND trx_level_type = c_trx_level_type;

 TYPE NUMERIC_TBL_TYPE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
 TYPE VARCHAR_30_TBL_TYPE IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
 TYPE VARCHAR_150_TBL_TYPE IS TABLE OF VARCHAR2(150) INDEX BY BINARY_INTEGER;
 TYPE VARCHAR_2000_TBL_TYPE IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;
 TYPE DATE_TBL_TYPE IS TABLE OF DATE INDEX BY BINARY_INTEGER;

 trx_line_dist_id_tbl                   NUMERIC_TBL_TYPE;
 trx_line_id_tbl                        NUMERIC_TBL_TYPE;
 trx_level_type_tbl                     VARCHAR_30_TBL_TYPE;
 dist_level_action_tbl                  VARCHAR_30_TBL_TYPE;
 item_dist_number_tbl                   NUMERIC_TBL_TYPE;
 dist_intended_use_tbl                  VARCHAR_30_TBL_TYPE;
 task_id_tbl                            NUMERIC_TBL_TYPE;
 award_id_tbl                           NUMERIC_TBL_TYPE;
 project_id_tbl                         NUMERIC_TBL_TYPE;
 expenditure_type_tbl                   VARCHAR_30_TBL_TYPE;
 expenditure_org_id_tbl                 NUMERIC_TBL_TYPE;
 expenditure_item_date_tbl              DATE_TBL_TYPE;
 gl_date_tbl        DATE_TBL_TYPE;
 trx_line_dist_amt_tbl                  NUMERIC_TBL_TYPE;
 trx_line_dist_quantity_tbl             NUMERIC_TBL_TYPE;
 ref_doc_application_id_tbl             NUMERIC_TBL_TYPE;
 ref_doc_entity_code_tbl                VARCHAR_30_TBL_TYPE;
 ref_doc_event_class_code_tbl           VARCHAR_30_TBL_TYPE;
 ref_doc_trx_id_tbl                     NUMERIC_TBL_TYPE;
 ref_doc_line_id_tbl                    NUMERIC_TBL_TYPE;
 ref_doc_trx_level_type_tbl             VARCHAR_30_TBL_TYPE;
 ref_doc_dist_id_tbl                    NUMERIC_TBL_TYPE;
 ref_doc_curr_conv_rate_tbl             NUMERIC_TBL_TYPE;
 trx_line_dist_tax_amt_tbl              NUMERIC_TBL_TYPE;
 account_ccid_tbl                       NUMERIC_TBL_TYPE;
 account_string_tbl                     VARCHAR_2000_TBL_TYPE;
 price_diff_tbl                         NUMERIC_TBL_TYPE;
 ref_doc_trx_line_dist_qty_tbl          NUMERIC_TBL_TYPE;
 applied_to_curr_conv_rate_tbl          NUMERIC_TBL_TYPE;

/*  These columns won't be needed since we get them from tax line instead, commented out for bug 5580045
 applied_from_appli_id_tbl              NUMERIC_TBL_TYPE;
 applied_from_evnt_cls_code_tbl         VARCHAR_30_TBL_TYPE;
 applied_from_entity_code_tbl           VARCHAR_30_TBL_TYPE;
 applied_from_trx_id_tbl                NUMERIC_TBL_TYPE;
 applied_from_line_id_tbl               NUMERIC_TBL_TYPE;
 adjusted_doc_appli_id_tbl              NUMERIC_TBL_TYPE;
 adjusted_doc_evnt_cls_code_tbl         VARCHAR_30_TBL_TYPE;
 adjusted_doc_entity_code_tbl           VARCHAR_30_TBL_TYPE;
 adjusted_doc_trx_id_tbl                NUMERIC_TBL_TYPE;
 adjusted_doc_line_id_tbl               NUMERIC_TBL_TYPE;
 applied_from_trx_level_tp_tbl          VARCHAR_30_TBL_TYPE;
 adjusted_doc_trx_level_tp_tbl          VARCHAR_30_TBL_TYPE;
*/

 applied_from_dist_id_tbl               NUMERIC_TBL_TYPE;
 adjusted_doc_dist_id_tbl               NUMERIC_TBL_TYPE;
 overriding_recovery_rate_tbl           NUMERIC_TBL_TYPE;

 l_tax_line_tbl          tax_line_tbl_type;
 tax_line_counter    NUMBER;

 l_counter      NUMBER;
 l_old_trx_line_id    zx_lines.trx_line_id%TYPE;
 l_old_trx_level_type    zx_lines.trx_level_type%TYPE;
 l_trx_line_id      zx_lines.trx_line_id%TYPE;
 l_trx_level_type    zx_lines.trx_level_type%TYPE;
 l_rec_nrec_dist_tbl       rec_nrec_dist_tbl_type;

 -- begin and end index for tax distribution for the same tax line and item dist
 l_rec_nrec_dist_begin_index   NUMBER;
 l_rec_nrec_dist_end_index   NUMBER;

 -- begin index for tax distribution for the same tax line
 l_dist_tbl_begin_index     NUMBER;
 l_action      VARCHAR2(30);
 l_trx_line_dist_tbl_type  ZX_GLOBAL_STRUCTURES_PKG.trx_line_dist_rec_type;

 l_exist_frozen_tax_dist_flag   VARCHAR2(1);

 -- Bug 11675911 / Bug 10621602
 char4_tbl                 VARCHAR_30_TBL_TYPE;
 char5_tbl                 NUMERIC_TBL_TYPE;

 -- Bug 20318426
 unit_price_tbl                         NUMERIC_TBL_TYPE;

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(+) ');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;
  -- g_variance_calc_flag := 'N';

  l_old_trx_line_id    := NUMBER_DUMMY;
  l_old_trx_level_type := VAR_30_DUMMY;

  --
  -- init msg record to be passed back to TSRM
  --
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.application_id :=
              p_event_class_rec.application_id;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.entity_code :=
              p_event_class_rec.entity_code;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.event_class_code :=
              p_event_class_rec.event_class_code;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.trx_id :=
              p_event_class_rec.trx_id;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.trx_line_id := NULL;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.trx_level_type := NULL;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.summary_tax_line_number :=
              NULL;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.tax_line_id := NULL;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.trx_line_dist_id := NULL;

  SELECT ZX_REC_NREC_DIST_S.nextval
  INTO   ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id
  FROM   dual;

  -- For a update event in quote calls(only PO has such case now),
  -- no need to Update_Item_Dist_Changed_Flag, since all tax lines have been
  -- brought back to zx_detail_tax_lines_gt (bug 4313177).

  IF (p_event_class_rec.tax_event_type_code = 'RE-DISTRIBUTE')
    AND p_event_class_rec.quote_flag <> 'Y'
  THEN

    -- call TRL service to update Item_Dist_Changed_Flag on ZX_LINES.
    --
    ZX_TRL_MANAGE_TAX_PKG.Update_Item_Dist_Changed_Flag(
        x_return_status,
        p_event_class_rec);

    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                      'After calling TRL, x_return_status = '|| x_return_status);
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                      'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
      END IF;
      RETURN;
    END IF;
  END IF;

 /*======================================================================*
  | Fetch tax lines for recovery calculation                             |
  *======================================================================*/

  fetch_tax_lines ( p_event_class_rec,
                    l_tax_line_tbl,
                    x_return_status);

  IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                    'After calling fetch tax lines, x_return_status = '
                       || x_return_status);
      FND_LOG.STRING(g_level_statement,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                    'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
    END IF;
    RETURN;
  END IF;

  tax_line_counter := l_tax_line_tbl.count;

  l_rec_nrec_dist_end_index := 0;

  -- populate header information,
  -- this is the same for every tax line so only need to do it once.
  --
  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.APPLICATION_ID(1)  := p_event_class_rec.APPLICATION_ID;
  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ENTITY_CODE(1)     := p_event_class_rec.ENTITY_CODE;
  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.EVENT_CLASS_CODE(1):= p_event_class_rec.EVENT_CLASS_CODE;
  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.EVENT_TYPE_CODE(1) := p_event_class_rec.EVENT_TYPE_CODE;
  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TAX_EVENT_CLASS_CODE(1):= p_event_class_rec.TAX_EVENT_CLASS_CODE;
  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TAX_EVENT_TYPE_CODE(1) := p_event_class_rec.TAX_EVENT_TYPE_CODE;
  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_ID(1)          := p_event_class_rec.TRX_ID;
  -- Initialize l_rec_nrec_dist_tbl
  l_rec_nrec_dist_tbl.delete;

  IF tax_line_counter = 0 THEN
    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                    'there is no tax lines that need to be processed ');

      FND_LOG.STRING(g_level_statement,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                    'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)'||x_return_status);
    END IF;
    RETURN;

  ELSE

    l_exist_frozen_tax_dist_flag := 'N';

    FOR i IN 1 .. tax_line_counter LOOP
      l_trx_line_id := l_tax_line_tbl(i).trx_line_id;
      l_trx_level_type := l_tax_line_tbl(i).trx_level_type;
      l_dist_tbl_begin_index := l_rec_nrec_dist_end_index + 1;

      IF l_tax_line_tbl(i).associated_child_frozen_flag = 'Y' AND
         l_tax_line_tbl(i).cancel_flag = 'N'
      THEN
        l_exist_frozen_tax_dist_flag := 'Y';
      END IF;


      IF l_trx_line_id <> l_old_trx_line_id OR
         l_trx_level_type <> l_old_trx_level_type THEN  -- for a new trx line

  -- Fetch all the trx line info from detail tax line table and populate
  -- the global PL/SQL table ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.
  -- This only needs to be done for a new trx line.


        populate_trx_line_info( l_tax_line_tbl,
        i,
        x_return_status);

        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,
                          'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                          'After calling populate_trx_line_info, x_return_status = '
                           || x_return_status);
            FND_LOG.STRING(g_level_statement,
                          'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                          'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
          END IF;
         RETURN;
        END IF;

        IF l_tax_line_tbl(i).tax_only_line_flag = 'Y' THEN

          -- to handle tax only lines, create dummy item distributions and
          --  populate this dummy item distributions into pl/sql tables,
          --
          OPEN  get_pseuso_line_info_csr(
                    l_tax_line_tbl(i).trx_line_id,
                    l_tax_line_tbl(i).trx_level_type);
          FETCH get_pseuso_line_info_csr INTO
                trx_line_id_tbl(1),
                trx_level_type_tbl(1),
                dist_intended_use_tbl(1),
                trx_line_dist_amt_tbl(1),
                trx_line_dist_quantity_tbl(1),
                ref_doc_application_id_tbl(1),
                ref_doc_entity_code_tbl(1) ,
                ref_doc_event_class_code_tbl(1),
                ref_doc_trx_id_tbl(1),
                ref_doc_line_id_tbl(1),
                ref_doc_trx_level_type_tbl(1),
                account_ccid_tbl(1),
                account_string_tbl(1),
                ref_doc_trx_line_dist_qty_tbl(1),
             -- applied_from_appli_id_tbl(1),
             -- applied_from_evnt_cls_code_tbl(1),
             -- applied_from_entity_code_tbl(1),
             -- applied_from_trx_id_tbl(1),
             -- applied_from_line_id_tbl(1),
             -- adjusted_doc_appli_id_tbl(1),
             -- adjusted_doc_evnt_cls_code_tbl(1),
             -- adjusted_doc_entity_code_tbl(1),
             -- adjusted_doc_trx_id_tbl(1),
             -- adjusted_doc_line_id_tbl(1),
             -- applied_from_trx_level_tp_tbl(1),
             -- adjusted_doc_trx_level_tp_tbl(1),
                gl_date_tbl(1);
          CLOSE get_pseuso_line_info_csr;

          trx_line_dist_id_tbl(1) := trx_line_id_tbl(1);
          dist_level_action_tbl(1) := 'CREATE';
          item_dist_number_tbl(1) := 1;
          task_id_tbl(1) := NULL;
          award_id_tbl(1) := NULL;
          project_id_tbl(1) := NULL;
          expenditure_type_tbl(1) := NULL;
          expenditure_org_id_tbl(1) := NULL;
          expenditure_item_date_tbl(1) := NULL;
          trx_line_dist_tax_amt_tbl(1) :=  l_tax_line_tbl(i).tax_amt;
          ref_doc_dist_id_tbl(1) := NULL;
          price_diff_tbl(1) := NULL;
          ref_doc_curr_conv_rate_tbl(1) := NULL;
          applied_to_curr_conv_rate_tbl(1) := NULL;

          applied_from_dist_id_tbl(1) := NULL;
          adjusted_doc_dist_id_tbl(1) := NULL;
          overriding_recovery_rate_tbl(1) := NULL;
          unit_price_tbl(1) := NULL;

          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,
                          'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                          'trx_line_dist_id_tbl '
                           ||to_char(trx_line_dist_id_tbl(1)));
          END IF;
        ELSE

          -- Fetch item distributions of this transaction line from
          -- zx_itm_distributions_gt into pl/sql tables
          --
          OPEN  get_item_dist_csr(l_trx_line_id, l_trx_level_type);
          FETCH get_item_dist_csr BULK COLLECT INTO
                trx_line_dist_id_tbl,
                trx_line_id_tbl,
                trx_level_type_tbl,
                dist_level_action_tbl,
                item_dist_number_tbl,
                dist_intended_use_tbl,
                task_id_tbl,
                award_id_tbl,
                project_id_tbl,
                expenditure_type_tbl,
                expenditure_org_id_tbl,
                expenditure_item_date_tbl,
                trx_line_dist_amt_tbl,
                trx_line_dist_quantity_tbl,
                ref_doc_application_id_tbl,
                ref_doc_entity_code_tbl,
                ref_doc_event_class_code_tbl,
                ref_doc_trx_id_tbl,
                ref_doc_line_id_tbl,
                ref_doc_trx_level_type_tbl,
                ref_doc_dist_id_tbl,
                ref_doc_curr_conv_rate_tbl,
                trx_line_dist_tax_amt_tbl,
                account_ccid_tbl,
                account_string_tbl,
                price_diff_tbl,
                ref_doc_trx_line_dist_qty_tbl,
                ref_doc_curr_conv_rate_tbl,
                applied_to_curr_conv_rate_tbl,
             -- applied_from_appli_id_tbl,
             -- applied_from_evnt_cls_code_tbl,
             -- applied_from_entity_code_tbl,
             -- applied_from_trx_id_tbl,
             -- applied_from_line_id_tbl,
                applied_from_dist_id_tbl,
             -- adjusted_doc_appli_id_tbl,
             -- adjusted_doc_evnt_cls_code_tbl,
             -- adjusted_doc_entity_code_tbl,
             -- adjusted_doc_trx_id_tbl,
             -- adjusted_doc_line_id_tbl,
                adjusted_doc_dist_id_tbl,
                overriding_recovery_rate_tbl,
             -- applied_from_trx_level_tp_tbl,
             -- adjusted_doc_trx_level_tp_tbl,
                gl_date_tbl,
                char4_tbl,
                char5_tbl,
                unit_price_tbl;
          CLOSE get_item_dist_csr;

        END IF;    -- tax_only_line_flag = 'Y'
      END IF;      -- trx_line_id <> l_old_trx_line_id

      IF l_tax_line_tbl(i).cancel_flag = 'Y' THEN   -- cancelled tax line

        -- For cancelled tax line, reverse frozen tax distributions and cancel others.
        --

        ZX_TRD_INTERNAL_SERVICES_PVT.cancel_tax_line(
          l_tax_line_tbl,
          i,
          l_rec_nrec_dist_tbl,
          l_dist_tbl_begin_index,
          l_rec_nrec_dist_end_index,
          p_event_class_rec,
          x_return_status,
          p_error_buffer);

        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,
                          'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                          'After calling cancel_tax_line x_return_status = '
                           || x_return_status);
            FND_LOG.STRING(g_level_statement,
                          'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                          'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
          END IF;
          RETURN;
        END IF;

      ELSE    -- cancel_flag <> 'Y'

        IF p_event_class_rec.tax_variance_calc_flag = 'Y' THEN

          -- populate g_tax_variance_info_tbl
          --
          IF trx_line_dist_id_tbl.COUNT > 0 AND
             ref_doc_application_id_tbl(trx_line_dist_id_tbl.FIRST) IS NOT NULL
          THEN

            g_variance_calc_flag := 'Y';

            --Bug 11675911 / Bug 10621602
            g_ret_doc_type := char4_tbl(1);
            g_retained_value := to_number(char5_tbl(1));

            FOR j IN trx_line_dist_id_tbl.FIRST .. trx_line_dist_id_tbl.LAST LOOP

              g_tax_variance_info_tbl(
                     trx_line_dist_id_tbl(j)).trx_line_dist_qty :=
                                               trx_line_dist_quantity_tbl(j);
              g_tax_variance_info_tbl(
                     trx_line_dist_id_tbl(j)).price_diff := price_diff_tbl(j);
              g_tax_variance_info_tbl(
                     trx_line_dist_id_tbl(j)).ref_doc_trx_line_dist_qty :=
                                             ref_doc_trx_line_dist_qty_tbl(j);
              g_tax_variance_info_tbl(
                     trx_line_dist_id_tbl(j)).ref_doc_curr_conv_rate :=
                                                ref_doc_curr_conv_rate_tbl(j);
              g_tax_variance_info_tbl(
                trx_line_dist_id_tbl(j)).applied_to_doc_curr_conv_rate :=
                                             applied_to_curr_conv_rate_tbl(j);
            END LOOP;
          END IF;     -- ref_doc_dist_id_tbl(j) IS NOT NULL
        END IF;       -- p_event_class_rec.tax_variance_calc_flag = 'Y'

  -- populate item distribution information into
  -- ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL
        --
        IF NVL(l_tax_line_tbl(i).process_for_recovery_flag,'N') = 'N' THEN

    -- there is no change on the tax line, i.e., item dist is either
    -- updated or new
          --
          FOR j IN NVL(trx_line_dist_id_tbl.FIRST, 0) .. NVL(trx_line_dist_id_tbl.LAST, -1)
          LOOP
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_ID(1) := trx_line_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LEVEL_TYPE(1) := trx_level_type_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_ID(1) := trx_line_dist_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.DIST_LEVEL_ACTION(1) := dist_level_action_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ITEM_DIST_NUMBER(1) := item_dist_number_tbl(j);
            IF ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.application_id(1) <> 201 THEN
              ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.LINE_INTENDED_USE(1) := dist_intended_use_tbl(j);
            END IF;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TASK_ID(1) := task_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.AWARD_ID(1) := award_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.PROJECT_ID(1) := project_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.EXPENDITURE_TYPE(1) := expenditure_type_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.EXPENDITURE_ORGANIZATION_ID(1):= expenditure_org_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.EXPENDITURE_ITEM_DATE(1) := expenditure_item_date_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_AMT(1) := trx_line_dist_amt_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_QUANTITY(1) := trx_line_dist_quantity_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_APPLICATION_ID(1) := ref_doc_application_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_ENTITY_CODE(1) := ref_doc_entity_code_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_EVENT_CLASS_CODE(1) := ref_doc_event_class_code_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_TRX_ID(1) := ref_doc_trx_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_LINE_ID(1) := ref_doc_line_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_TRX_LEVEL_TYPE(1) := ref_doc_trx_level_type_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_DIST_ID(1) := ref_doc_dist_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_CURR_CONV_RATE(1) := ref_doc_curr_conv_rate_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_TAX_AMT(1) := trx_line_dist_tax_amt_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ACCOUNT_CCID(1) := account_ccid_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ACCOUNT_STRING(1):= account_string_tbl(j);
            -- get the applied from and adjusted to doc trx line keys from tax line bug 5580045
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_application_id(1) :=
                    l_tax_line_tbl(i).applied_from_application_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_event_class_code(1) :=
                        l_tax_line_tbl(i).applied_from_event_class_code;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_entity_code(1) :=
                        l_tax_line_tbl(i).applied_from_entity_code;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_trx_id(1) :=
                        l_tax_line_tbl(i).applied_from_trx_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_line_id(1) :=
                        l_tax_line_tbl(i).applied_from_line_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_dist_id(1) := applied_from_dist_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_application_id(1) :=
                        l_tax_line_tbl(i).adjusted_doc_application_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_event_class_code(1) :=
                        l_tax_line_tbl(i).adjusted_doc_event_class_code;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_entity_code(1) :=
                        l_tax_line_tbl(i).adjusted_doc_entity_code;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_trx_id(1) :=
                        l_tax_line_tbl(i).adjusted_doc_trx_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_line_id(1) :=
                        l_tax_line_tbl(i).adjusted_doc_line_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_dist_id(1) := adjusted_doc_dist_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.overriding_recovery_rate(1) := overriding_recovery_rate_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_trx_level_type(1) :=
                        l_tax_line_tbl(i).applied_from_trx_level_type;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_trx_level_type(1) :=
                        l_tax_line_tbl(i).adjusted_doc_trx_level_type;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_line_gl_date(1) := gl_date_tbl(j); -- store gl date in trx_line_gl_date
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.unit_price(1) := unit_price_tbl(j);

            l_rec_nrec_dist_begin_index := l_rec_nrec_dist_end_index + 1;
            l_action := ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.DIST_LEVEL_ACTION(1);

            IF l_action = 'CREATE' or l_action = 'UPDATE' THEN

              -- get new tax distributions for this tax line and item dist

              ZX_TRD_INTERNAL_SERVICES_PVT.calc_tax_dist(
                l_tax_line_tbl,
                i,
                1,
                l_rec_nrec_dist_tbl,
                l_rec_nrec_dist_begin_index,
                l_rec_nrec_dist_end_index,
                p_event_class_rec,
                x_return_status,
                p_error_buffer);

              IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                IF (g_level_statement >= g_current_runtime_level ) THEN
                  FND_LOG.STRING(g_level_statement,
                                'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                                'After calling calc_tax_dist x_return_status = '
                                 || x_return_status);
                  FND_LOG.STRING(g_level_statement,
                                'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                                'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
                END IF;
                RETURN;
              END IF;
            ELSIF l_action = 'NO_ACTION' THEN

              -- this tax line or item dist has no change, but other item dist might
              --
              fetch_tax_distributions(
                    p_event_class_rec,
                    l_tax_line_tbl(i).tax_line_id,
                    ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_ID(1),
                    l_rec_nrec_dist_tbl,
                    l_rec_nrec_dist_begin_index,
                    l_rec_nrec_dist_end_index,
                    x_return_status);

              IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                IF (g_level_statement >= g_current_runtime_level ) THEN
                  FND_LOG.STRING(g_level_statement,
                              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                              'After calling fetch_tax_distributions x_return_status = '
                               || x_return_status);
                  FND_LOG.STRING(g_level_statement,
                              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                              'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
                END IF;
                RETURN;
              END IF;
            ELSE   -- wrong l_action
              x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;     -- bug 4893261
              IF (g_level_statement >= g_current_runtime_level ) THEN
                FND_LOG.STRING(g_level_statement,
                              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                              'wrong dist level action code. l_action= '||l_action );
                FND_LOG.STRING(g_level_statement,
                              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                              'RETURN_STATUS = ' || x_return_status);
              END IF;
              RETURN;
            END IF;      -- l_action
          END LOOP;      -- loop through trx_line_dist_id_tbl

        ELSE             -- this is a new or updated tax line

          FOR j IN NVL(trx_line_dist_id_tbl.FIRST, 0) .. NVL(trx_line_dist_id_tbl.LAST,-1)
          LOOP
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_ID(1)                := trx_line_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_Level_type(1)             := trx_level_type_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_ID(1)           := trx_line_dist_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.DIST_LEVEL_ACTION(1)          := dist_level_action_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ITEM_DIST_NUMBER(1)           := item_dist_number_tbl(j);
            IF ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.application_id(1) <> 201 THEN
              ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.LINE_INTENDED_USE(1)        := dist_intended_use_tbl(j);
            END IF;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TASK_ID(1)                    := task_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.AWARD_ID(1)                   := award_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.PROJECT_ID(1)                 := project_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.EXPENDITURE_TYPE(1)           := expenditure_type_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.EXPENDITURE_ORGANIZATION_ID(1):= expenditure_org_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.EXPENDITURE_ITEM_DATE(1)      := expenditure_item_date_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_AMT(1)          := trx_line_dist_amt_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_QUANTITY(1)     := trx_line_dist_quantity_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_APPLICATION_ID(1)     := ref_doc_application_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_ENTITY_CODE(1)        := ref_doc_entity_code_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_EVENT_CLASS_CODE(1)   := ref_doc_event_class_code_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_TRX_ID(1)             := ref_doc_trx_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_LINE_ID(1)            := ref_doc_line_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_TRX_LEVEL_TYPE(1)     := ref_doc_trx_level_type_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_DIST_ID(1)            := ref_doc_dist_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.REF_DOC_CURR_CONV_RATE(1)     := ref_doc_curr_conv_rate_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.TRX_LINE_DIST_TAX_AMT(1)      := trx_line_dist_tax_amt_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ACCOUNT_CCID(1)               := account_ccid_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ACCOUNT_STRING(1)             := account_string_tbl(j);

            -- get the applied from and adjusted to doc trx line keys from tax line bug 5580045
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_application_id(1) :=
                    l_tax_line_tbl(i).applied_from_application_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_event_class_code(1) :=
                        l_tax_line_tbl(i).applied_from_event_class_code;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_entity_code(1) :=
                        l_tax_line_tbl(i).applied_from_entity_code;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_trx_id(1) :=
                        l_tax_line_tbl(i).applied_from_trx_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_line_id(1) :=
                        l_tax_line_tbl(i).applied_from_line_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_dist_id(1) := applied_from_dist_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_application_id(1) :=
                        l_tax_line_tbl(i).adjusted_doc_application_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_event_class_code(1) :=
                        l_tax_line_tbl(i).adjusted_doc_event_class_code;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_entity_code(1) :=
                        l_tax_line_tbl(i).adjusted_doc_entity_code;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_trx_id(1) :=
                        l_tax_line_tbl(i).adjusted_doc_trx_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_line_id(1) :=
                        l_tax_line_tbl(i).adjusted_doc_line_id;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_dist_id(1)         := adjusted_doc_dist_id_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.overriding_recovery_rate(1)     := overriding_recovery_rate_tbl(j);
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.applied_from_trx_level_type(1) :=
                        l_tax_line_tbl(i).applied_from_trx_level_type;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.adjusted_doc_trx_level_type(1) :=
                        l_tax_line_tbl(i).adjusted_doc_trx_level_type;
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_line_gl_date(1) := gl_date_tbl(j); -- store gl date in trx_line_gl_date
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.unit_price(1) := unit_price_tbl(j);

            l_rec_nrec_dist_begin_index := l_rec_nrec_dist_end_index + 1;
            l_action := ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.DIST_LEVEL_ACTION(1);

            IF (g_level_statement >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_statement,
                            'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                            'dist level action = ' || l_action);
            END IF;

            IF l_action = 'CREATE' OR l_action = 'UPDATE' OR l_action = 'NO_ACTION'
            THEN
              -- get new tax distributions for this tax line and item dist
              --

              ZX_TRD_INTERNAL_SERVICES_PVT.calc_tax_dist(
                l_tax_line_tbl,
                i,
                1,
                l_rec_nrec_dist_tbl,
                l_rec_nrec_dist_begin_index,
                l_rec_nrec_dist_end_index,
                p_event_class_rec,
                x_return_status,
                p_error_buffer);

              IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
                IF (g_level_statement >= g_current_runtime_level ) THEN
                  FND_LOG.STRING(g_level_statement,
                                'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                                'After calling calc_tax_dist x_return_status = '
                                 || x_return_status);
                  FND_LOG.STRING(g_level_statement,
                                'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                                'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
                END IF;
                RETURN;
              END IF;

            ELSE  -- wrong l_action
              x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
              IF (g_level_statement >= g_current_runtime_level ) THEN
                FND_LOG.STRING(g_level_statement,
                               'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                               'wrong dist level action code ' );

              END IF;
              RETURN;
            END IF;        -- l_action
          END LOOP;   -- loop through trx_line_dist_id_tbl
        END IF;  -- process for recovery flag

  -- calculate recovery/non tax amount
        --

        IF trx_line_dist_id_tbl.COUNT > 0 THEN
          ZX_TRD_INTERNAL_SERVICES_PVT.get_rec_nrec_dist_amt(
            l_tax_line_tbl,
            i,
            l_rec_nrec_dist_tbl,
            l_dist_tbl_begin_index,
            l_rec_nrec_dist_end_index,
            x_return_status,
            p_error_buffer);

          IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            IF (g_level_statement >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_statement,
                            'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                            'After calling get_rec_nrec_dist_amt x_return_status = '
                               || x_return_status);
              FND_LOG.STRING(g_level_statement,
                            'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                            'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
            END IF;
            RETURN;
          END IF;

    -- perform rounding

          ZX_TRD_INTERNAL_SERVICES_PVT.round_rec_nrec_amt(
            l_rec_nrec_dist_tbl,
            l_dist_tbl_begin_index,
            l_rec_nrec_dist_end_index,
            l_tax_line_tbl(i).tax_amt,
            l_tax_line_tbl(i).tax_amt_tax_curr,
            l_tax_line_tbl(i).tax_amt_funcl_curr,
            x_return_status,
            p_error_buffer);

          IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            IF (g_level_statement >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_statement,
                            'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                            'After calling ROUND_REC_NREC_AMT x_return_status = '
                             || x_return_status);
              FND_LOG.STRING(g_level_statement,
                            'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                            'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
            END IF;
           RETURN;
          END IF;

          -- Bug 4352593: comment out the call to MRC processing procedure
          --
          -- IF p_event_class_rec.enable_mrc_flag = 'Y' THEN
          --   -- create MRC tax distributions
          --   --
          --
          --   ZX_TRD_INTERNAL_SERVICES_PVT.create_mrc_tax_dists(
          --               p_event_class_rec,
      --     l_rec_nrec_dist_tbl,
      --       l_dist_tbl_begin_index,
      --     l_rec_nrec_dist_end_index,
      --     x_return_status,
      --     p_error_buffer);
          --
          --   IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          --     IF (g_level_statement >= g_current_runtime_level ) THEN
          --       FND_LOG.STRING(g_level_statement,
          --              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
          --              'After calling create_mrc_tax_dists x_return_status = '
          --               || x_return_status);
          --       FND_LOG.STRING(g_level_statement,
          --              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
          --              'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
          --     END IF;
           --   RETURN;
          --   END IF;
          -- END IF;    -- p_event_class_rec.enable_mrc_flag = 'Y'
        END IF;    -- trx_line_dist_id_tbl.COUNT > 0
      END IF;      -- cancel flag

      -- insert into global temporary table
      insert_global_table(
        l_rec_nrec_dist_tbl,
        l_dist_tbl_begin_index,
        l_rec_nrec_dist_end_index,
        x_return_status);

      IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,
                        'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                        'After calling insert_global_table x_return_status = '
                         || x_return_status);
          FND_LOG.STRING(g_level_statement,
                        'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                        'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
        END IF;
       RETURN;
      END IF;

      l_old_trx_line_id := l_trx_line_id;
      l_old_trx_level_type := l_trx_level_type;

    END LOOP;       -- loop through l_tax_line_tbl
  END IF;           -- tax line counter.COUNT = 0 OR ELSE 0

  -- populate mandatory columns before inserting.
  populate_mandatory_columns(l_rec_nrec_dist_tbl,x_return_status);

  IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                    'After calling populate_mandatory_columns x_return_status = '
                     || x_return_status);
      FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                  'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
    END IF;
    RETURN;
  END IF;

  FORALL ctr IN NVL(l_rec_nrec_dist_tbl.FIRST,0) .. NVL(l_rec_nrec_dist_tbl.LAST,-1)
        INSERT INTO zx_rec_nrec_dist_gt VALUES l_rec_nrec_dist_tbl(ctr);

  -- when is tax_variance_calc_flag is 'Y', calculate variance factors for all
  -- the  tax distributions in global table zx_rec_nrec_dist_gt

  IF l_exist_frozen_tax_dist_flag = 'Y' THEN

    delete_unnecessary_tax_dists(p_event_class_rec  => p_event_class_rec,
                                 x_return_status    => x_return_status);

    IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      IF g_level_statement >= g_current_runtime_level THEN
        FND_LOG.STRING(g_level_statement,
               'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
               'After calling delete_unnecessary_tax_dists, x_return_status = '
                || x_return_status);
        FND_LOG.STRING(g_level_statement,
               'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
               'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');
      END IF;
      RETURN;
    END IF;
  END IF;


  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                  'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                  'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)'||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    p_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY',
                     p_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY.END',
                    'ZX_TRD_SERVICES_PUB_PKG.DETERMINE_RECOVERY(-)');

    END IF;

END DETERMINE_RECOVERY;

/* ===========================================================================*
 |  PUBLIC PROCEDURE override_recovery                                        |
 |                                                                            |
 |  DESCRIPTION                                                               |
 |  This procedure is used to get the recoverable and non-recovearble tax     |
 |  distributions after user makes changes on the tax distribution UI.        |
 |                                                                            |
 |  This procedure will be called directly by TSRM service.                   |
 |                                                                            |
 * ===========================================================================*/

PROCEDURE  OVERRIDE_RECOVERY(
  p_event_class_rec     IN          ZX_API_PUB.EVENT_CLASS_REC_TYPE,
  x_return_status       OUT NOCOPY  VARCHAR2) IS

l_tax_line_id      NUMBER;
l_rec_nrec_dist_tbl        rec_nrec_dist_tbl_type;
l_rec_nrec_dist_begin_index   NUMBER;
l_rec_nrec_dist_end_index   NUMBER;
i        NUMBER;

CURSOR fetch_tax_line_id_csr IS
 SELECT tax_line_id,
        tax_amt,
        tax_amt_tax_curr,
        tax_amt_funcl_curr
   FROM zx_lines
   WHERE  trx_id =
             p_event_class_rec.trx_id
     AND  application_id =
             p_event_class_rec.application_id
     AND  entity_code =
             p_event_class_rec.entity_code
     AND  event_class_code =
             p_event_class_rec.event_class_code
     AND  Reporting_Only_Flag = 'N'             -- do not process reporting only lines
     AND  Process_For_Recovery_Flag = 'Y'
     AND  mrc_tax_line_flag = 'N';

CURSOR  fetch_tax_distributions_csr(l_tax_line_id NUMBER) IS
 SELECT *
   FROM zx_rec_nrec_dist
  WHERE trx_id = p_event_class_rec.trx_id
    AND application_id = p_event_class_rec.application_id
    AND entity_code = p_event_class_rec.entity_code
    AND event_class_code = p_event_class_rec.event_class_code
    AND tax_line_id = l_tax_line_id
    AND NVL(freeze_flag, 'N') = 'N'
    AND NVL(reverse_flag, 'N') = 'N'
    AND mrc_tax_dist_flag = 'N';

 l_tax_line_amt      NUMBER;
 l_tax_line_amt_tax_curr  NUMBER;
 l_tax_line_amt_funcl_curr  NUMBER;

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY(+)');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  -- Initialize p_tax_line_tbl
  l_rec_nrec_dist_tbl.delete;
  g_variance_calc_flag := 'N';

  --
  -- init msg record to be passed back to TSRM
  --
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.application_id :=
              p_event_class_rec.application_id;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.entity_code :=
              p_event_class_rec.entity_code;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.event_class_code :=
              p_event_class_rec.event_class_code;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.trx_id :=
              p_event_class_rec.trx_id;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.trx_line_id := NULL;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.trx_level_type := NULL;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.summary_tax_line_number :=
              NULL;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.tax_line_id := NULL;
  ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec.trx_line_dist_id := NULL;


  OPEN fetch_tax_line_id_csr;

  i := 1;

  LOOP
    FETCH fetch_tax_line_id_csr INTO l_tax_line_id, l_tax_line_amt,
          l_tax_line_amt_tax_curr, l_tax_line_amt_funcl_curr;

 -- Bug 5985143. Recovery rate and amount were not getting changed after changing recovery rate code in distributions form.
 -- After changes to payables code, when user clicks on OK button, application hangs.
 -- There is not exit condition to the above. Hence added exit condition when cursor doesn't return any row.

    EXIT WHEN fetch_tax_line_id_csr%notfound;

    OPEN  fetch_tax_distributions_csr(l_tax_line_id);

    l_rec_nrec_dist_begin_index := i;

    LOOP

      FETCH fetch_tax_distributions_csr into l_rec_nrec_dist_tbl(i);

      EXIT WHEN fetch_tax_distributions_csr%notfound;

      IF p_event_class_rec.tax_variance_calc_flag = 'Y' AND
        l_rec_nrec_dist_tbl(i).recoverable_flag = 'N'  AND
        l_rec_nrec_dist_tbl(i).ref_doc_application_id IS NOT NULL THEN

        g_variance_calc_flag := 'Y';

      END IF;

      i := i + 1;

    END LOOP;

    l_rec_nrec_dist_end_index := i - 1;

    CLOSE fetch_tax_distributions_csr;

  -- on UI, recovery rate and non-recovery rate has already been determined.
  -- and the unrounded rec/non-rec tax distribution amount has already been calculated.
  -- perform rounding

    IF l_rec_nrec_dist_end_index >= l_rec_nrec_dist_begin_index THEN
      ZX_TRD_INTERNAL_SERVICES_PVT.ROUND_REC_NREC_AMT(
        l_rec_nrec_dist_tbl,
        l_rec_nrec_dist_begin_index,
        l_rec_nrec_dist_end_index,
        l_tax_line_amt,
        l_tax_line_amt_tax_curr,
        l_tax_line_amt_funcl_curr,
        x_return_status,
        p_error_buffer
      );

      IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,
                             'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY',
                             'After calling ROUND_REC_NREC_AMT x_return_status = '
                             || x_return_status);
          FND_LOG.STRING(g_level_statement,
                             'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY.END',
                             'ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY(-)');
        END IF;
        RETURN;

      END IF;

      -- Bug 4352593: comment out the call to MRC processing procedure
      --
      -- IF p_event_class_rec.enable_mrc_flag = 'Y' THEN
      --   -- create MRC tax distributions
      --   --
      --   IF (g_level_statement >= g_current_runtime_level ) THEN
      --     FND_LOG.STRING(g_level_statement,
      --            'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY',
      --            'create MRC tax distributions' );
      --   END IF;
      --
      --   ZX_TRD_INTERNAL_SERVICES_PVT.create_mrc_tax_dists(
       --          p_event_class_rec,
      --          l_rec_nrec_dist_tbl,
      --     l_rec_nrec_dist_begin_index,
      --          l_rec_nrec_dist_end_index,
      --          x_return_status,
      --          p_error_buffer);
          --
          --   IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          --     IF (g_level_statement >= g_current_runtime_level ) THEN
          --       FND_LOG.STRING(g_level_statement,
          --              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY',
          --              'After calling create_mrc_tax_dists x_return_status = '
          --               || x_return_status);
          --       FND_LOG.STRING(g_level_statement,
          --              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY.END',
          --              'ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY(-)');
          --     END IF;
           --   RETURN;
          --   END IF;
          -- END IF;     -- p_event_class_rec.enable_mrc_flag = 'Y'
    END IF;       -- l_rec_nrec_dist_end_index >= l_rec_nrec_dist_begin_index

  -- insert into global temporary table
    insert_global_table(
      l_rec_nrec_dist_tbl,
      l_rec_nrec_dist_begin_index,
      l_rec_nrec_dist_end_index,
      x_return_status);

    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                           'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY',
                           'After calling insert_global_table x_return_status = '
                           || x_return_status);
        FND_LOG.STRING(g_level_statement,
                           'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY.END',
                           'ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY(-)');
      END IF;
      RETURN;

    END IF;

    i := l_rec_nrec_dist_end_index + 1;

  END LOOP;

  CLOSE fetch_tax_line_id_csr;

  -- populate mandatory columns before inserting.
  populate_mandatory_columns(l_rec_nrec_dist_tbl, x_return_status);

  IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,
                         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY',
                         'After calling populate_mandatory_columns x_return_status = '
                         || x_return_status);
      FND_LOG.STRING(g_level_statement,
                         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY.END',
                         'ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY(-)');
        END IF;
       RETURN;

  END IF;

  FORALL ctr IN NVL(l_rec_nrec_dist_tbl.FIRST,0) .. NVL(l_rec_nrec_dist_tbl.LAST,-1)
        INSERT INTO zx_rec_nrec_dist_gt VALUES l_rec_nrec_dist_tbl(ctr);

  -- bug fix 3313938: add tax_variance_calc_flag check.
  IF g_variance_calc_flag = 'Y' THEN
    -- when is tax_variance_calc_flag is 'Y', calculate variance factors for
    -- all the  tax distributions in global table zx_rec_nrec_dist_gt

    ZX_TRD_INTERNAL_SERVICES_PVT.calc_variance_factors(
        x_return_status,
        p_error_buffer
        );

    IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

       IF (g_level_statement >= g_current_runtime_level ) THEN
         FND_LOG.STRING(g_level_statement,
                        'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY',
                        'After calling calc_variance_factors ' ||
                        'x_return_status = ' || x_return_status);
       FND_LOG.STRING(g_level_statement,
                        'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY.END',
                        'ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY(-)');
       END IF;
       RETURN;

    END IF;
  END IF;

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY.END',
                   'ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY(-)'||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    p_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY',
                      p_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY.END',
                   'ZX_TRD_SERVICES_PUB_PKG.OVERRIDE_RECOVERY(-)');

    END IF;

END OVERRIDE_RECOVERY;

/* ============================================================================*
 | PUBLIC PROCEDURE REVERSE_TAX_DIST                                           |
 |                                                                             |
 | DESCRIPTION                                                                 |
 | This procedure is used to reverse all the frozen tax distributions on UI,   |
 | it reads all the reversed tax distribution ids from global temporary table  |
 | zx_tax_dist_id_gt and put all the returned tax distributions to PL/SQL table|
 | p_rec_nrec_dist_tbl.  UI needs to delete all the tax distributions uses want|
 | to freeze and insert all the tax distributions from p_rec_nrec_dist_tbl to  |
 | tax reporsitory.                                                            |
 |                                                                             |
 | This procedure will be called from the tax distribution UI.                 |
 |                                                                             |
 * ============================================================================*/

PROCEDURE REVERSE_TAX_DIST(
  p_rec_nrec_dist_tbl    OUT NOCOPY    REC_NREC_DIST_TBL_TYPE,
  x_return_status        OUT NOCOPY    VARCHAR2)
is

l_index         number;

CURSOR  get_rec_nrec_dist_cur is
 SELECT *
   FROM zx_rec_nrec_dist
  WHERE rec_nrec_tax_dist_id IN (SELECT tax_dist_id FROM zx_tax_dist_id_gt);

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
   FND_LOG.STRING(g_level_procedure,
                  'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_TAX_DIST.BEGIN',
                  'ZX_TRD_SERVICES_PUB_PKG.REVERSE_TAX_DIST(+)');
  END IF;
  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  l_index:= 1;

  OPEN get_rec_nrec_dist_cur;

  LOOP
    FETCH get_rec_nrec_dist_cur INTO p_rec_nrec_dist_tbl(l_index);
     EXIT when get_rec_nrec_dist_cur%NOTFOUND;

    -- get g_tax_dist_id
    --
    SELECT ZX_REC_NREC_DIST_S.nextval
    INTO   ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id
    FROM   dual;

    p_rec_nrec_dist_tbl(l_index).Reverse_Flag:= 'Y';

    l_index:= l_index + 1;
    p_rec_nrec_dist_tbl(l_index):= p_rec_nrec_dist_tbl(l_index-1);
    -- reversed tax dist id is the original rec nrec tax dist id.
    p_rec_nrec_dist_tbl(l_index).reversed_tax_dist_id := p_rec_nrec_dist_tbl(l_index-1).rec_nrec_tax_dist_id;
    p_rec_nrec_dist_tbl(l_index).freeze_flag:= 'N';
    p_rec_nrec_dist_tbl(l_index).rec_nrec_tax_dist_id:= ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id;

    p_rec_nrec_dist_tbl(l_index).rec_nrec_tax_amt :=
                                  -p_rec_nrec_dist_tbl(l_index).rec_nrec_tax_amt;
    p_rec_nrec_dist_tbl(l_index).rec_nrec_tax_amt_tax_curr :=
                         -p_rec_nrec_dist_tbl(l_index).rec_nrec_tax_amt_tax_curr;
    p_rec_nrec_dist_tbl(l_index).rec_nrec_tax_amt_funcl_curr :=
                       -p_rec_nrec_dist_tbl(l_index).rec_nrec_tax_amt_funcl_curr;
    p_rec_nrec_dist_tbl(l_index).unrounded_rec_nrec_tax_amt:=
                        -p_rec_nrec_dist_tbl(l_index).unrounded_rec_nrec_tax_amt;
    p_rec_nrec_dist_tbl(l_index).trx_line_dist_amt :=
                                 -p_rec_nrec_dist_tbl(l_index).trx_line_dist_amt;
    p_rec_nrec_dist_tbl(l_index).trx_line_dist_tax_amt :=
                             -p_rec_nrec_dist_tbl(l_index).trx_line_dist_tax_amt;
    p_rec_nrec_dist_tbl(l_index).orig_rec_nrec_tax_amt :=
                             -p_rec_nrec_dist_tbl(l_index).orig_rec_nrec_tax_amt;
    p_rec_nrec_dist_tbl(l_index).orig_rec_nrec_tax_amt_tax_curr :=
                    -p_rec_nrec_dist_tbl(l_index).orig_rec_nrec_tax_amt_tax_curr;
    p_rec_nrec_dist_tbl(l_index).taxable_amt :=
                                       -p_rec_nrec_dist_tbl(l_index).taxable_amt;
    p_rec_nrec_dist_tbl(l_index).taxable_amt_tax_curr :=
                              -p_rec_nrec_dist_tbl(l_index).taxable_amt_tax_curr;
    p_rec_nrec_dist_tbl(l_index).taxable_amt_funcl_curr :=
                            -p_rec_nrec_dist_tbl(l_index).taxable_amt_funcl_curr;
    p_rec_nrec_dist_tbl(l_index).unrounded_taxable_amt:=
                             -p_rec_nrec_dist_tbl(l_index).unrounded_taxable_amt;
    p_rec_nrec_dist_tbl(l_index).prd_tax_amt :=
                                       -p_rec_nrec_dist_tbl(l_index).prd_tax_amt;
    p_rec_nrec_dist_tbl(l_index).prd_tax_amt_tax_curr :=
                              -p_rec_nrec_dist_tbl(l_index).prd_tax_amt_tax_curr;
    p_rec_nrec_dist_tbl(l_index).prd_tax_amt_funcl_curr :=
                            -p_rec_nrec_dist_tbl(l_index).prd_tax_amt_funcl_curr;
    p_rec_nrec_dist_tbl(l_index).prd_total_tax_amt:=
                                 -p_rec_nrec_dist_tbl(l_index).prd_total_tax_amt;
    p_rec_nrec_dist_tbl(l_index).prd_total_tax_amt_tax_curr :=
                        -p_rec_nrec_dist_tbl(l_index).prd_total_tax_amt_tax_curr;
    p_rec_nrec_dist_tbl(l_index).prd_total_tax_amt_funcl_curr :=
                      -p_rec_nrec_dist_tbl(l_index).prd_total_tax_amt_funcl_curr;
    p_rec_nrec_dist_tbl(l_index).per_trx_curr_unit_nr_amt :=
                          -p_rec_nrec_dist_tbl(l_index).per_trx_curr_unit_nr_amt;
    p_rec_nrec_dist_tbl(l_index).ref_per_trx_curr_unit_nr_amt :=
                      -p_rec_nrec_dist_tbl(l_index).ref_per_trx_curr_unit_nr_amt;
    p_rec_nrec_dist_tbl(l_index).per_unit_nrec_tax_amt :=
                             -p_rec_nrec_dist_tbl(l_index).per_unit_nrec_tax_amt;
    p_rec_nrec_dist_tbl(l_index).ref_doc_per_unit_nrec_tax_amt :=
                     -p_rec_nrec_dist_tbl(l_index).ref_doc_per_unit_nrec_tax_amt;
    p_rec_nrec_dist_tbl(l_index).trx_line_dist_qty :=
                                 -p_rec_nrec_dist_tbl(l_index).trx_line_dist_qty;
    p_rec_nrec_dist_tbl(l_index).ref_doc_trx_line_dist_qty :=
                         -p_rec_nrec_dist_tbl(l_index).ref_doc_trx_line_dist_qty;

    p_rec_nrec_dist_tbl(l_index).created_by := fnd_global.user_id;
    p_rec_nrec_dist_tbl(l_index).creation_date := sysdate;
    p_rec_nrec_dist_tbl(l_index).last_updated_by := fnd_global.user_id;
    p_rec_nrec_dist_tbl(l_index).last_update_login := fnd_global.login_id;
    p_rec_nrec_dist_tbl(l_index).last_update_date := sysdate;
    p_rec_nrec_dist_tbl(l_index).object_version_number := 1;

    -- bug 6706941: populate gl_date for the reversed tax distribution
    --
    p_rec_nrec_dist_tbl(l_index).gl_date :=
          AP_UTILITIES_PKG.get_reversal_gl_date(
                    p_date   => p_rec_nrec_dist_tbl(l_index).gl_date,
                    p_org_id => p_rec_nrec_dist_tbl(l_index).internal_organization_id);

    l_index:= l_index + 1;

    -- get g_tax_dist_id
    --
    SELECT ZX_REC_NREC_DIST_S.nextval
    INTO   ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id
    FROM   dual;

--    ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id:= ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id + 1;

    p_rec_nrec_dist_tbl(l_index):= p_rec_nrec_dist_tbl(l_index - 2);
    p_rec_nrec_dist_tbl(l_index).rec_nrec_tax_dist_id:= ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id;
    p_rec_nrec_dist_tbl(l_index).Freeze_Flag:= 'N';
    p_rec_nrec_dist_tbl(l_index).Reverse_Flag:= 'N';
    p_rec_nrec_dist_tbl(l_index).created_by := fnd_global.user_id;
    p_rec_nrec_dist_tbl(l_index).creation_date := sysdate;
    p_rec_nrec_dist_tbl(l_index).last_updated_by := fnd_global.user_id;
    p_rec_nrec_dist_tbl(l_index).last_update_login := fnd_global.login_id;
    p_rec_nrec_dist_tbl(l_index).last_update_date := sysdate;
    p_rec_nrec_dist_tbl(l_index).object_version_number := 1;

    l_index:= l_index + 1;
--    ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id:= ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id + 1;

  END LOOP;

  CLOSE get_rec_nrec_dist_cur;

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_TAX_DIST.END',
                   'ZX_TRD_SERVICES_PUB_PKG.REVERSE_TAX_DIST(-)'||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    p_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_TAX_DIST',
                      p_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_TAX_DIST.END',
                   'ZX_TRD_SERVICES_PUB_PKG.REVERSE_TAX_DIST(-)');

    END IF;

END REVERSE_TAX_DIST;


/* ======================================================================*
 |  PUBLIC PROCEDURE  validate_document_for_tax                          |
 |                                                                       |
 |  This procedure is called from TSRM for validate docuemnt service     |
 |  for tax                                                              |
 |                                                                       |
 * ======================================================================*/

PROCEDURE VALIDATE_DOCUMENT_FOR_TAX(
  p_event_class_rec      IN             ZX_API_PUB.EVENT_CLASS_REC_TYPE,
  p_transaction_rec      IN             ZX_API_PUB.transaction_rec_type,
  x_hold_status             OUT NOCOPY  ZX_API_PUB.HOLD_CODES_TBL_TYPE,
  x_validate_status         OUT NOCOPY  VARCHAR2,  -- bug fix 3541452
  x_return_status           OUT NOCOPY  VARCHAR2)  IS

  CURSOR get_hold_status_csr IS
  SELECT DISTINCT tax_hold_code - tax_hold_released_code
    FROM zx_lines
   WHERE tax_hold_code > 0
     AND trx_id = p_transaction_rec.trx_id
     AND application_id = p_transaction_rec.application_id
     AND entity_code = p_transaction_rec.entity_code
     AND event_class_code = p_transaction_rec.event_class_code
     AND mrc_tax_line_flag = 'N'
     AND nvl(cancel_flag,'N') <> 'Y';

  l_code      NUMBER;
  l_tax_variance    VARCHAR2(1);
  l_tax_amount_range  VARCHAR2(1);

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX(+)');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  l_code                := NULL;
  l_tax_variance        := 'N';
  l_tax_amount_range    := 'N';

  x_hold_status.DELETE;

  --Commented IF statement for Bug#13893772
  --IF p_event_class_rec.tax_tol_amt_range IS NOT NULL
  --  OR p_event_class_rec.tax_tolerance IS NOT NULL
  --THEN
    -- need special handling for historical data

    OPEN get_hold_status_csr;
    LOOP
      FETCH get_hold_status_csr INTO l_code;
      EXIT when get_hold_status_csr%NOTFOUND;
      IF l_code = 1 THEN
        IF l_tax_variance = 'N' THEN
          x_hold_status(x_hold_status.count + 1) := ZX_TDS_CALC_SERVICES_PUB_PKG.G_TAX_VARIANCE_HOLD;
          l_tax_variance := 'Y';

          IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,
              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX',
              'hold code 1 : tax variance ');
          END IF;
        END IF;
      ELSIF l_code = 2 THEN
        IF l_tax_amount_range = 'N' THEN
          x_hold_status(x_hold_status.count + 1) := ZX_TDS_CALC_SERVICES_PUB_PKG.G_TAX_AMT_RANGE_HOLD;
          l_tax_amount_range := 'Y';

          IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,
              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX',
              'hold code 2 : tax amount range');
          END IF;
        END IF;
      ELSIF l_code = 3 THEN
        IF l_tax_variance = 'N' THEN
          x_hold_status(x_hold_status.count + 1) := ZX_TDS_CALC_SERVICES_PUB_PKG.G_TAX_VARIANCE_HOLD;
          l_tax_variance := 'Y';

          IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,
              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX',
              'hold code 3 : tax variance ');
          END IF;
        END IF;
        IF l_tax_amount_range = 'N' THEN
          x_hold_status(x_hold_status.count + 1) := ZX_TDS_CALC_SERVICES_PUB_PKG.G_TAX_AMT_RANGE_HOLD;
          l_tax_amount_range := 'Y';

          IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,
              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX',
              'hold code 3 : tax amount range');
          END IF;
        END IF;
      END IF;

    END LOOP;
    CLOSE get_hold_status_csr;
  --END IF; -- IF p_event_class_rec.tax_tol_amt_range IS NOT NULL

  -- bug fix 3541452 begin
  x_validate_status := 'Y';

  IF p_event_class_rec.prod_family_grp_code = 'O2C'  THEN
    INSERT ALL
    WHEN (REGIME_NOT_EFFECTIVE = 'Y')  THEN

      INTO ZX_VALIDATION_ERRORS_GT(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          message_name,
          message_text
          )
      VALUES(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          'ZX_REGIME_NOT_EFFECTIVE',
          l_regime_not_effective
           )
    WHEN (TAX_NOT_EFFECTIVE = 'Y')  THEN

      INTO ZX_VALIDATION_ERRORS_GT(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          message_name,
          message_text
          )
      VALUES(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          'ZX_TAX_NOT_EFFECTIVE',
          l_tax_not_effective
           )

    WHEN (TAX_STATUS_NOT_EFFECTIVE = 'Y')  THEN

      INTO ZX_VALIDATION_ERRORS_GT(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          message_name,
          message_text
          )
      VALUES(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          'ZX_TAX_STATUS_NOT_EFFECTIVE',
          l_tax_status_not_effective
           )
    WHEN (TAX_RATE_ID_NOT_EFFECTIVE = 'Y')  THEN

      INTO ZX_VALIDATION_ERRORS_GT(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          message_name,
          message_text
          )
      VALUES(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          'ZX_TAX_RATE_NOT_EFFECTIVE',
          l_tax_rate_not_effective
           )

    WHEN (TAX_RATE_ID_NOT_ACTIVE = 'Y')  THEN

      INTO ZX_VALIDATION_ERRORS_GT(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          message_name,
          message_text
          )
      VALUES(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          'ZX_TAX_RATE_NOT_ACTIVE',
          l_tax_rate_not_active
           )

    WHEN (TAX_RATE_PERCENTAGE_INVALID = 'Y')  THEN

      INTO ZX_VALIDATION_ERRORS_GT(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          message_name,
          message_text
          )
      VALUES(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          'ZX_TAX_RATE_PERCENTAGE_INVALID',
          l_tax_rate_percentage_invalid
           )
    WHEN (JUR_CODE_NOT_EFFECTIVE = 'Y')  THEN

      INTO ZX_VALIDATION_ERRORS_GT(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          message_name,
          message_text
          )
      VALUES(
          application_id,
          entity_code,
          event_class_code,
          trx_id,
          trx_line_id,
          trx_level_type,
          'ZX_JUR_CODE_NOT_EFFECTIVE',
          l_jur_code_not_effective
           )
      SELECT
         line.application_id,
         line.entity_code,
         line.event_class_code,
         line.trx_id,
         line.trx_line_id,
         line.trx_level_type,
         -- Check for Regime Effectivity
         CASE WHEN line.tax_determine_date
              BETWEEN regime.effective_from
                  AND nvl(regime.effective_to, line.tax_determine_date)
         THEN 'N'
         ELSE 'Y' END REGIME_NOT_EFFECTIVE,

         -- Check for Tax Effectivity
         CASE WHEN line.tax_determine_date
              BETWEEN tax.effective_from
                  AND nvl(tax.effective_to, line.tax_determine_date)
         THEN 'N'
         ELSE 'Y' END TAX_NOT_EFFECTIVE,

         -- Check for Status Effectivity
         CASE WHEN line.tax_determine_date
              BETWEEN status.effective_from
                  AND nvl(status.effective_to, line.tax_determine_date)
         THEN 'N'
         ELSE 'Y' END TAX_STATUS_NOT_EFFECTIVE,

         -- Check for Rate Id Date Effectivity
         CASE WHEN line.tax_determine_date
              BETWEEN rate.effective_from
                  AND nvl(rate.effective_to, line.tax_determine_date)
         THEN 'N'
         ELSE 'Y' END TAX_RATE_ID_NOT_EFFECTIVE,

         -- Check Rate Id is Active
         CASE WHEN rate.active_flag = 'Y'
         THEN 'N'
         ELSE 'Y' END TAX_RATE_ID_NOT_ACTIVE,

         -- Check for Rate Percentage
         CASE WHEN (rate.tax_rate_id = line.tax_rate_id
                         AND (line.tax_exemption_id IS NULL AND exempt_rate_modifier IS NULL)
                         AND line.tax_provider_id IS NULL
                         AND (line.tax_exception_id is NULL AND exception_rate IS NULL)
                         AND rate.percentage_rate <> line.tax_rate
                         AND rate.allow_adhoc_tax_rate_flag <> 'Y'
                         AND line.tax_determine_date
                          BETWEEN rate.effective_from
                              AND nvl(rate.effective_to, line.tax_determine_date))
         THEN 'Y'
         ELSE 'N' END TAX_RATE_PERCENTAGE_INVALID,

         -- Check for Jurisdiction Code Effectivity
         CASE WHEN line.tax_determine_date
                    BETWEEN jur.effective_from
                        AND nvl(jur.effective_to, line.tax_determine_date)
         THEN 'N'
         ELSE 'Y' END JUR_CODE_NOT_EFFECTIVE

         FROM
              ZX_LINES                  line   ,
              ZX_REGIMES_B              regime ,
              ZX_TAXES_B                tax    ,
              ZX_STATUS_B               status ,
              ZX_RATES_B                rate   ,
              ZX_JURISDICTIONS_B        jur
         WHERE line.APPLICATION_ID             = p_transaction_rec.APPLICATION_ID
           AND line.ENTITY_CODE                = p_transaction_rec.ENTITY_CODE
           AND line.EVENT_CLASS_CODE           = p_transaction_rec.EVENT_CLASS_CODE
           AND line.TRX_ID                     = p_transaction_rec.TRX_ID
           and regime.tax_regime_code          = line.tax_regime_code
           and tax.tax_id                      = line.tax_id
           and status.tax_status_id            = line.tax_status_id
           and rate.tax_rate_id                = line.tax_rate_id
           and jur.tax_jurisdiction_id         = line.tax_jurisdiction_id
           and line.mrc_tax_line_flag = 'N'
     and line.adjusted_doc_application_id is null
     and line.applied_from_application_id is null;

    IF SQL%ROWCOUNT >0 THEN
      x_validate_status := 'N';
    END IF;
  END IF; -- IF prod_family_grp_code = 'O2C'
  -- bug fix 3541452 end


  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX.END',
                   'ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX(-)'||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

    IF get_hold_status_csr%ISOPEN THEN
     CLOSE get_hold_status_csr;
    END IF;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX',
                     'x_hold_status.tax_variance = '||l_tax_variance);
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX',
                     'x_hold_status.tax_amount_range = '||l_tax_amount_range);
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
      FND_LOG.STRING(g_level_unexpected,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX.END',
                   'ZX_TRD_SERVICES_PUB_PKG.VALIDATE_DOCUMENT_FOR_TAX(-)');

    END IF;

END VALIDATE_DOCUMENT_FOR_TAX;

/* ======================================================================*
 |  PUBLIC PROCEDURE  reverse_distributions                              |
 |                                                                       |
 |  This procedure is called from TSRM for reverse whole docuemnt        |
 |  distributions service                                                |
 |                                                                       |
 * ======================================================================*/

PROCEDURE REVERSE_DISTRIBUTIONS(
        x_return_status        OUT NOCOPY        VARCHAR2)  IS

 TYPE num_tbl_type IS TABLE OF zx_rec_nrec_dist.rec_nrec_tax_dist_id%TYPE
   INDEX BY BINARY_INTEGER;
  --Bug 9651174
 TYPE num2_tbl_type IS TABLE OF zx_rec_nrec_dist.trx_line_id%TYPE
   INDEX BY BINARY_INTEGER;

 TYPE char30_tbl_type IS TABLE OF zx_rec_nrec_dist.entity_code%TYPE
   INDEX BY BINARY_INTEGER;
 TYPE char150_tbl_type IS TABLE OF zx_rec_nrec_dist.trx_number%TYPE
   INDEX BY BINARY_INTEGER;
 TYPE date_tbl_type IS TABLE OF zx_rec_nrec_dist.gl_date%TYPE
   INDEX BY BINARY_INTEGER;

 l_rvrsed_tax_dist_id_tbl       num_tbl_type;
 l_rvrsng_appln_id_tbl          num_tbl_type;
 l_rvrsng_entity_code_tbl       char30_tbl_type;
 l_rvrsng_evnt_cls_code_tbl     char30_tbl_type;
 l_rvrsng_trx_id_tbl            num_tbl_type;
 --l_rvrsng_trx_line_id_tbl       num_tbl_type;
 -- Bug 9651174
 l_rvrsng_trx_line_id_tbl       num2_tbl_type;
 l_rvrsng_trx_level_type_tbl    char30_tbl_type;
 l_rvrsng_tax_line_id_tbl       num_tbl_type;
 l_rvrsng_trx_line_dist_id_tbl  num_tbl_type;
 l_summary_tax_line_id_tbl      num_tbl_type;
 l_rvrsng_trx_number_tbl        char150_tbl_type;

 l_org_id_tbl                   num_tbl_type;
 l_gl_date_tbl                  date_tbl_type;
 l_tax_dist_num_tbl             num_tbl_type;
 l_old_tax_line_id       NUMBER;
 l_old_trx_line_dist_id  NUMBER;
 l_new_tax_dist_num      NUMBER;

 l_dist_count NUMBER;

  CURSOR  get_max_tax_dist_num_csr(
            c_tax_line_id    NUMBER,
            c_trx_line_dist_id  NUMBER) IS
   SELECT max(rec_nrec_tax_dist_number)
     FROM zx_rec_nrec_dist
    WHERE tax_line_id = c_tax_line_id
      AND trx_line_dist_id = c_trx_line_dist_id;
BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS(+)');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

 -- Bug 9088833. This is used to populate reverse_flag and reversed_tax_dist_id
  SELECT count(*) INTO l_dist_count
  FROM zx_rec_nrec_dist
  WHERE (application_id,
         entity_code,
         event_class_code,
         trx_id) IN (SELECT DISTINCT reversing_appln_id,
                            reversing_entity_code,
                            reversing_evnt_cls_code,
                            reversing_trx_id
                      FROM zx_reverse_dist_gt);
  -- Bug 9088833

  -- Bug 9883546
  IF l_dist_count = 0 THEN --quick credit memo creation. Query in ELSE part is in the original/previous version.

  IF (g_level_statement >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS',
                   'Quick Credit Memo :: l_dist_count : '||l_dist_count);
  END IF;

  SELECT zd.rec_nrec_tax_dist_id,
         gt.reversing_appln_id,
         gt.reversing_entity_code,
         gt.reversing_evnt_cls_code,
         gt.reversing_trx_id,
         gt.reversing_trx_line_id,
         gt.reversing_trx_level_type,
         zl.tax_line_id,
         gt.reversing_trx_line_dist_id,
         zl.summary_tax_line_id,
         zl.trx_number,
         zd.internal_organization_id,
         --zd.gl_date,
         --Bug 9883546
         lines_gt.trx_line_gl_date
  BULK COLLECT INTO
         l_rvrsed_tax_dist_id_tbl,
         l_rvrsng_appln_id_tbl,
         l_rvrsng_entity_code_tbl,
         l_rvrsng_evnt_cls_code_tbl,
         l_rvrsng_trx_id_tbl,
         l_rvrsng_trx_line_id_tbl,
         l_rvrsng_trx_level_type_tbl,
         l_rvrsng_tax_line_id_tbl,
         l_rvrsng_trx_line_dist_id_tbl,
         l_summary_tax_line_id_tbl,
         l_rvrsng_trx_number_tbl,
         l_org_id_tbl,
         l_gl_date_tbl
    FROM zx_rec_nrec_dist zd, zx_reverse_dist_gt gt,
         --Bug 9883546
         zx_reverse_trx_lines_gt lines_gt, zx_lines zl
   WHERE zd.application_id = gt.reversed_appln_id
     AND zd.entity_code = gt.reversed_entity_code
     AND zd.event_class_code = gt.reversed_evnt_cls_code
     AND zd.trx_id = gt.reversed_trx_id
     AND zd.trx_line_id = gt.reversed_trx_line_id
     AND zd.trx_level_type = gt.reversed_trx_level_type
     AND zd.tax_line_id = NVL(gt.reversed_tax_line_id, zd.tax_line_id)
     AND zd.trx_line_dist_id = gt.reversed_trx_line_dist_id
     AND nvl(zd.Reverse_Flag, 'N') = 'N'
     --Bug 9883546
     AND zl.application_id = lines_gt.reversing_appln_id
     AND zl.entity_code = lines_gt.reversing_entity_code
     AND zl.event_class_code = lines_gt.reversing_evnt_cls_code
     AND zl.trx_id = lines_gt.reversing_trx_id
     AND zl.trx_line_id = lines_gt.reversing_trx_line_id
     AND zl.trx_level_type = lines_gt.reversing_trx_level_type
     --End Bug 9883546
     AND zl.application_id = gt.reversing_appln_id
     AND zl.entity_code = gt.reversing_entity_code
     AND zl.event_class_code = gt.reversing_evnt_cls_code
     AND zl.trx_id = gt.reversing_trx_id
     AND zl.trx_line_id = gt.reversing_trx_line_id
     AND zl.trx_level_type = gt.reversing_trx_level_type
     AND ((zl.reversed_tax_line_id IS NOT NULL AND
           zl.reversed_tax_line_id = zd.tax_line_id
          ) OR
          (
          zl.reversed_tax_line_id IS NOT NULL AND -- Bug 9088833
          zl.tax_line_id = gt.reversing_tax_line_id
          ) OR
          (zl.reversed_tax_line_id IS NULL AND
           zl.tax_line_id = gt.reversing_tax_line_id
          )
         )
     --Bug 9189035
     AND NOT EXISTS (SELECT 1
                       FROM zx_rec_nrec_dist zxd
                      WHERE zxd.application_id = zd.application_id
                        AND zxd.entity_code = zd.entity_code
                        AND zxd.event_class_code = zd.event_class_code
                        AND zxd.trx_id = zd.trx_id
                        AND zxd.trx_line_id = zd.trx_line_id
                        AND zxd.trx_level_type = zd.trx_level_type
                        AND zxd.tax_line_id = zl.tax_line_id
                        AND zxd.trx_line_dist_id = gt.reversing_trx_line_dist_id
                        AND zxd.rec_nrec_tax_dist_number = zd.rec_nrec_tax_dist_number);
     --End Bug 9189035

  ELSE

    -- bug 14740699 forcing hint
  SELECT /*+ leading (GT, ZL) index (ZL ZX_LINES_U1) */
         zd.rec_nrec_tax_dist_id,
         gt.reversing_appln_id,
         gt.reversing_entity_code,
         gt.reversing_evnt_cls_code,
         gt.reversing_trx_id,
         gt.reversing_trx_line_id,
         gt.reversing_trx_level_type,
         zl.tax_line_id,
         gt.reversing_trx_line_dist_id,
         zl.summary_tax_line_id,
         zl.trx_number,
         zd.internal_organization_id,
         zd.gl_date
  BULK COLLECT INTO
         l_rvrsed_tax_dist_id_tbl,
         l_rvrsng_appln_id_tbl,
         l_rvrsng_entity_code_tbl,
         l_rvrsng_evnt_cls_code_tbl,
         l_rvrsng_trx_id_tbl,
         l_rvrsng_trx_line_id_tbl,
         l_rvrsng_trx_level_type_tbl,
         l_rvrsng_tax_line_id_tbl,
         l_rvrsng_trx_line_dist_id_tbl,
         l_summary_tax_line_id_tbl,
         l_rvrsng_trx_number_tbl,
         l_org_id_tbl,
         l_gl_date_tbl
    FROM zx_rec_nrec_dist zd, zx_reverse_dist_gt gt, zx_lines zl
   WHERE zd.application_id = gt.reversed_appln_id
     AND zd.entity_code = gt.reversed_entity_code
     AND zd.event_class_code = gt.reversed_evnt_cls_code
     AND zd.trx_id = gt.reversed_trx_id
     AND zd.trx_line_id = gt.reversed_trx_line_id
     AND zd.trx_level_type = gt.reversed_trx_level_type
     AND zd.tax_line_id = NVL(gt.reversed_tax_line_id, zd.tax_line_id)
     AND zd.trx_line_dist_id = gt.reversed_trx_line_dist_id
     AND nvl(zd.Reverse_Flag, 'N') = 'N'
     AND zl.application_id = gt.reversing_appln_id
     AND zl.entity_code = gt.reversing_entity_code
     AND zl.event_class_code = gt.reversing_evnt_cls_code
     AND zl.trx_id = gt.reversing_trx_id
     AND zl.trx_line_id = gt.reversing_trx_line_id
     AND zl.trx_level_type = gt.reversing_trx_level_type
     AND ((zl.reversed_tax_line_id IS NOT NULL AND
           zl.reversed_tax_line_id = zd.tax_line_id
          ) OR
          (
          zl.reversed_tax_line_id IS NOT NULL AND -- Bug 9088833
          zl.tax_line_id = gt.reversing_tax_line_id
          ) OR
          (zl.reversed_tax_line_id IS NULL AND
           zl.tax_line_id = gt.reversing_tax_line_id
          )
         );
     /*--Bug 9189035
     AND NOT EXISTS (SELECT 1
                       FROM zx_rec_nrec_dist zxd
                      WHERE zxd.application_id = zd.application_id
                        AND zxd.entity_code = zd.entity_code
                        AND zxd.event_class_code = zd.event_class_code
                        AND zxd.trx_id = zd.trx_id
                        AND zxd.trx_line_id = zd.trx_line_id
                        AND zxd.trx_level_type = zd.trx_level_type
                        AND zxd.tax_line_id = zl.tax_line_id
                        AND zxd.trx_line_dist_id = gt.reversing_trx_line_dist_id
                        AND zxd.rec_nrec_tax_dist_number = zd.rec_nrec_tax_dist_number);
     --End Bug 9189035
    */
  --Bug 13434422
    -- Update the REVERSE_FLAG of the original dist line to 'Y'
    FORALL i IN NVL(l_rvrsed_tax_dist_id_tbl.FIRST, 0)..NVL(l_rvrsed_tax_dist_id_tbl.LAST, -1)
      UPDATE ZX_REC_NREC_DIST
         SET REVERSE_FLAG = 'Y'
       WHERE REC_NREC_TAX_DIST_ID = l_rvrsed_tax_dist_id_tbl(i);

  END IF;


  l_old_tax_line_id := NUMBER_DUMMY;
  l_old_trx_line_dist_id := NUMBER_DUMMY;
  l_new_tax_dist_num := 0;

  FOR i IN NVL(l_gl_date_tbl.FIRST, 0) .. NVL(l_gl_date_tbl.LAST, -1) LOOP

    l_gl_date_tbl(i) := AP_UTILITIES_PKG.get_reversal_gl_date(
                    p_date   => l_gl_date_tbl(i),
                    p_org_id => l_org_id_tbl(i));

    IF l_old_tax_line_id      = l_rvrsng_tax_line_id_tbl(i) AND
       l_old_trx_line_dist_id = l_rvrsng_trx_line_dist_id_tbl(i) THEN
       l_new_tax_dist_num := l_new_tax_dist_num + 1;
    ELSE
      OPEN  get_max_tax_dist_num_csr(
                l_rvrsng_tax_line_id_tbl(i),
                l_rvrsng_trx_line_dist_id_tbl(i));
      FETCH get_max_tax_dist_num_csr INTO l_new_tax_dist_num;
      CLOSE get_max_tax_dist_num_csr;
      l_new_tax_dist_num := NVL(l_new_tax_dist_num,0) + 1;

      l_old_tax_line_id      := l_rvrsng_tax_line_id_tbl(i);
      l_old_trx_line_dist_id := l_rvrsng_trx_line_dist_id_tbl(i);
    END IF;

    l_tax_dist_num_tbl(i) := l_new_tax_dist_num;

  END LOOP;

  -- Insert the reversing tax distributions

  FORALL i IN NVL(l_rvrsed_tax_dist_id_tbl.FIRST, 0)..
              NVL(l_rvrsed_tax_dist_id_tbl.LAST, -1)
    INSERT INTO ZX_REC_NREC_DIST(
              REC_NREC_TAX_DIST_ID,
              APPLICATION_ID,
              ENTITY_CODE,
              EVENT_CLASS_CODE,
              EVENT_TYPE_CODE,
              TAX_EVENT_CLASS_CODE,
              TAX_EVENT_TYPE_CODE,
              TRX_ID,
              TRX_LINE_ID,
              TRX_LEVEL_TYPE,
              TRX_LINE_NUMBER,
              TAX_LINE_ID,
              TAX_LINE_NUMBER,
              TRX_LINE_DIST_ID,
              ITEM_DIST_NUMBER,
              CONTENT_OWNER_ID,
              REC_NREC_TAX_DIST_NUMBER,
              TAX_REGIME_ID,
              TAX_REGIME_CODE,
              TAX_ID,
              TAX,
              TAX_STATUS_ID,
              TAX_STATUS_CODE,
              TAX_RATE_ID,
              TAX_RATE_CODE,
              TAX_RATE,
              INCLUSIVE_FLAG,
              RECOVERY_TYPE_ID,
              RECOVERY_TYPE_CODE,
              RECOVERY_RATE_ID,
              RECOVERY_RATE_CODE,
              REC_NREC_RATE,
              REC_TYPE_RULE_FLAG,
              NEW_REC_RATE_CODE_FLAG,
              RECOVERABLE_FLAG,
              REVERSE_FLAG,
              HISTORICAL_FLAG,
              REVERSED_TAX_DIST_ID,
              REC_NREC_TAX_AMT,
              REC_NREC_TAX_AMT_TAX_CURR,
              REC_NREC_TAX_AMT_FUNCL_CURR,
              INTENDED_USE,
              PROJECT_ID,
              TASK_ID,
              AWARD_ID,
              EXPENDITURE_TYPE,
              EXPENDITURE_ORGANIZATION_ID,
              EXPENDITURE_ITEM_DATE,
              REC_RATE_DET_RULE_FLAG,
              LEDGER_ID,
              SUMMARY_TAX_LINE_ID,
              RECORD_TYPE_CODE,
              CURRENCY_CONVERSION_DATE,
              CURRENCY_CONVERSION_TYPE,
              CURRENCY_CONVERSION_RATE,
              TAX_CURRENCY_CONVERSION_DATE,
              TAX_CURRENCY_CONVERSION_TYPE,
              TAX_CURRENCY_CONVERSION_RATE,
              TRX_CURRENCY_CODE,
              TAX_CURRENCY_CODE,
              TRX_LINE_DIST_AMT,
              TRX_LINE_DIST_TAX_AMT,
              ORIG_REC_NREC_RATE,
              ORIG_REC_RATE_CODE,
              ORIG_REC_NREC_TAX_AMT,
              ORIG_REC_NREC_TAX_AMT_TAX_CURR,
              UNROUNDED_REC_NREC_TAX_AMT,
              APPLICABILITY_RESULT_ID,
              REC_RATE_RESULT_ID,
              BACKWARD_COMPATIBILITY_FLAG,
              OVERRIDDEN_FLAG,
              SELF_ASSESSED_FLAG,
              FREEZE_FLAG,
              POSTING_FLAG,
              ATTRIBUTE_CATEGORY,
              ATTRIBUTE1,
              ATTRIBUTE2,
              ATTRIBUTE3,
              ATTRIBUTE4,
              ATTRIBUTE5,
              ATTRIBUTE6,
              ATTRIBUTE7,
              ATTRIBUTE8,
              ATTRIBUTE9,
              ATTRIBUTE10,
              ATTRIBUTE11,
              ATTRIBUTE12,
              ATTRIBUTE13,
              ATTRIBUTE14,
              ATTRIBUTE15,
              GLOBAL_ATTRIBUTE_CATEGORY,
              GLOBAL_ATTRIBUTE1,
              GLOBAL_ATTRIBUTE2,
              GLOBAL_ATTRIBUTE3,
              GLOBAL_ATTRIBUTE4,
              GLOBAL_ATTRIBUTE5,
              GLOBAL_ATTRIBUTE6,
              GLOBAL_ATTRIBUTE7,
              GLOBAL_ATTRIBUTE8,
              GLOBAL_ATTRIBUTE9,
              GLOBAL_ATTRIBUTE10,
              GLOBAL_ATTRIBUTE11,
              GLOBAL_ATTRIBUTE12,
              GLOBAL_ATTRIBUTE13,
              GLOBAL_ATTRIBUTE14,
              GLOBAL_ATTRIBUTE15,
              GL_DATE,
              CREATED_BY,
              CREATION_DATE,
              LAST_UPDATED_BY,
              LAST_UPDATE_LOGIN,
              LAST_UPDATE_DATE,
              REF_DOC_APPLICATION_ID,
              REF_DOC_ENTITY_CODE,
              REF_DOC_EVENT_CLASS_CODE,
              REF_DOC_TRX_ID,
              REF_DOC_LINE_ID,
              REF_DOC_TRX_LEVEL_TYPE,
              REF_DOC_DIST_ID,
              MINIMUM_ACCOUNTABLE_UNIT,
              PRECISION,
              ROUNDING_RULE_CODE,
              TAXABLE_AMT,
              TAXABLE_AMT_TAX_CURR,
              TAXABLE_AMT_FUNCL_CURR,
              TAX_ONLY_LINE_FLAG,
              UNROUNDED_TAXABLE_AMT,
              LEGAL_ENTITY_ID,
              ACCOUNT_CCID,
              ACCOUNT_STRING,
              PRD_TAX_AMT,
              PRD_TAX_AMT_TAX_CURR,
              PRD_TAX_AMT_FUNCL_CURR,
              PRD_TOTAL_TAX_AMT,
              PRD_TOTAL_TAX_AMT_TAX_CURR,
              PRD_TOTAL_TAX_AMT_FUNCL_CURR,
              APPLIED_FROM_TAX_DIST_ID,
              ADJUSTED_DOC_TAX_DIST_ID,
              FUNC_CURR_ROUNDING_ADJUSTMENT,
              GLOBAL_ATTRIBUTE16,
              GLOBAL_ATTRIBUTE17,
              GLOBAL_ATTRIBUTE18,
              GLOBAL_ATTRIBUTE19,
              GLOBAL_ATTRIBUTE20,
              LAST_MANUAL_ENTRY,
              TAX_APPORTIONMENT_LINE_NUMBER,
              REF_DOC_TAX_DIST_ID,
              MRC_TAX_DIST_FLAG,
              MRC_LINK_TO_TAX_DIST_ID,
              TAX_APPORTIONMENT_FLAG,
              RATE_TAX_FACTOR,
              REF_DOC_PER_UNIT_NREC_TAX_AMT,
              PER_UNIT_NREC_TAX_AMT,
              TRX_LINE_DIST_QTY,
              REF_DOC_TRX_LINE_DIST_QTY,
              PRICE_DIFF,
              QTY_DIFF,
              PER_TRX_CURR_UNIT_NR_AMT,
              REF_PER_TRX_CURR_UNIT_NR_AMT,
              REF_DOC_CURR_CONV_RATE,
              UNIT_PRICE,
              REF_DOC_UNIT_PRICE,
              APPLIED_TO_DOC_CURR_CONV_RATE,
              TRX_NUMBER,
              OBJECT_VERSION_NUMBER,
              INTERNAL_ORGANIZATION_ID,
              DEF_REC_SETTLEMENT_OPTION_CODE,
              TAX_JURISDICTION_ID,
              ACCOUNT_SOURCE_TAX_RATE_ID
              )
       SELECT
              ZX_REC_NREC_DIST_S.NEXTVAL,
              l_rvrsng_appln_id_tbl(i),              -- GT.REVERSING_APPLN_ID,
              l_rvrsng_entity_code_tbl(i),           -- GT.REVERSING_ENTITY_CODE,
              l_rvrsng_evnt_cls_code_tbl(i),         -- GT.REVERSING_EVNT_CLS_CODE,
              ZD.EVENT_TYPE_CODE,
              ZD.TAX_EVENT_CLASS_CODE,
              ZD.TAX_EVENT_TYPE_CODE,
              l_rvrsng_trx_id_tbl(i),                -- GT.REVERSING_TRX_ID,
              l_rvrsng_trx_line_id_tbl(i),           -- GT.REVERSING_TRX_LINE_ID,
              l_rvrsng_trx_level_type_tbl(i),        -- GT.REVERSING_TRX_LEVEL_TYPE,
              ZD.TRX_LINE_NUMBER,
              l_rvrsng_tax_line_id_tbl(i),           -- GT.REVERSING_TAX_LINE_ID,
              ZD.TAX_LINE_NUMBER,
              l_rvrsng_trx_line_dist_id_tbl(i),      -- GT.REVERSING_TRX_LINE_DIST_ID,
              ZD.ITEM_DIST_NUMBER,
              ZD.CONTENT_OWNER_ID,
              l_tax_dist_num_tbl(i),                    -- ZD.REC_NREC_TAX_DIST_NUMBER,
              ZD.TAX_REGIME_ID,
              ZD.TAX_REGIME_CODE,
              ZD.TAX_ID,
              ZD.TAX,
              ZD.TAX_STATUS_ID,
              ZD.TAX_STATUS_CODE,
              ZD.TAX_RATE_ID,
              ZD.TAX_RATE_CODE,
              ZD.TAX_RATE,
              ZD.INCLUSIVE_FLAG,
              ZD.RECOVERY_TYPE_ID,
              ZD.RECOVERY_TYPE_CODE,
              ZD.RECOVERY_RATE_ID,
              ZD.RECOVERY_RATE_CODE,
              ZD.REC_NREC_RATE,
              ZD.REC_TYPE_RULE_FLAG,
              ZD.NEW_REC_RATE_CODE_FLAG,
              ZD.RECOVERABLE_FLAG,
              DECODE(l_dist_count,0,null,'Y'),                     -- ZD.REVERSE_FLAG,
              ZD.HISTORICAL_FLAG,
              DECODE(l_dist_count,0,null,ZD.REC_NREC_TAX_DIST_ID), -- REVERSED_TAX_DIST_ID,
              -ZD.REC_NREC_TAX_AMT,
              -ZD.REC_NREC_TAX_AMT_TAX_CURR,
              -ZD.REC_NREC_TAX_AMT_FUNCL_CURR,
              ZD.INTENDED_USE,
              ZD.PROJECT_ID,
              ZD.TASK_ID,
              ZD.AWARD_ID,
              ZD.EXPENDITURE_TYPE,
              ZD.EXPENDITURE_ORGANIZATION_ID,
              ZD.EXPENDITURE_ITEM_DATE,
              ZD.REC_RATE_DET_RULE_FLAG,
              ZD.LEDGER_ID,
              l_summary_tax_line_id_tbl(i),          -- ZL.SUMMARY_TAX_LINE_ID,
              ZD.RECORD_TYPE_CODE,
              ZD.CURRENCY_CONVERSION_DATE,
              ZD.CURRENCY_CONVERSION_TYPE,
              ZD.CURRENCY_CONVERSION_RATE,
              ZD.TAX_CURRENCY_CONVERSION_DATE,
              ZD.TAX_CURRENCY_CONVERSION_TYPE,
              ZD.TAX_CURRENCY_CONVERSION_RATE,
              ZD.TRX_CURRENCY_CODE,
              ZD.TAX_CURRENCY_CODE,
              -ZD.TRX_LINE_DIST_AMT,
              -ZD.TRX_LINE_DIST_TAX_AMT,
              ZD.ORIG_REC_NREC_RATE,
              ZD.ORIG_REC_RATE_CODE,
              -ZD.ORIG_REC_NREC_TAX_AMT,
              -ZD.ORIG_REC_NREC_TAX_AMT_TAX_CURR,
              -ZD.UNROUNDED_REC_NREC_TAX_AMT,
              ZD.APPLICABILITY_RESULT_ID,
              ZD.REC_RATE_RESULT_ID,
              ZD.BACKWARD_COMPATIBILITY_FLAG,
              ZD.OVERRIDDEN_FLAG,
              ZD.SELF_ASSESSED_FLAG,
              'N',                        -- ZD.FREEZE_FLAG
              'N',                        -- ZD.POSTING_FLAG
              ZD.ATTRIBUTE_CATEGORY,
              ZD.ATTRIBUTE1,
              ZD.ATTRIBUTE2,
              ZD.ATTRIBUTE3,
              ZD.ATTRIBUTE4,
              ZD.ATTRIBUTE5,
              ZD.ATTRIBUTE6,
              ZD.ATTRIBUTE7,
              ZD.ATTRIBUTE8,
              ZD.ATTRIBUTE9,
              ZD.ATTRIBUTE10,
              ZD.ATTRIBUTE11,
              ZD.ATTRIBUTE12,
              ZD.ATTRIBUTE13,
              ZD.ATTRIBUTE14,
              ZD.ATTRIBUTE15,
              ZD.GLOBAL_ATTRIBUTE_CATEGORY,
              ZD.GLOBAL_ATTRIBUTE1,
              ZD.GLOBAL_ATTRIBUTE2,
              ZD.GLOBAL_ATTRIBUTE3,
              ZD.GLOBAL_ATTRIBUTE4,
              ZD.GLOBAL_ATTRIBUTE5,
              ZD.GLOBAL_ATTRIBUTE6,
              ZD.GLOBAL_ATTRIBUTE7,
              ZD.GLOBAL_ATTRIBUTE8,
              ZD.GLOBAL_ATTRIBUTE9,
              ZD.GLOBAL_ATTRIBUTE10,
              ZD.GLOBAL_ATTRIBUTE11,
              ZD.GLOBAL_ATTRIBUTE12,
              ZD.GLOBAL_ATTRIBUTE13,
              ZD.GLOBAL_ATTRIBUTE14,
              ZD.GLOBAL_ATTRIBUTE15,
              l_gl_date_tbl(i),             -- ZD.GL_DATE,
              FND_GLOBAL.USER_ID,           -- CREATED_BY,
              SYSDATE,                      -- CREATION_DATE,
              FND_GLOBAL.USER_ID,           -- LAST_UPDATED_BY,
              FND_GLOBAL.LOGIN_ID,          -- LAST_UPDATE_LOGIN,
              SYSDATE,                      -- LAST_UPDATE_DATE,
              ZD.REF_DOC_APPLICATION_ID,
              ZD.REF_DOC_ENTITY_CODE,
              ZD.REF_DOC_EVENT_CLASS_CODE,
              ZD.REF_DOC_TRX_ID,
              ZD.REF_DOC_LINE_ID,
              ZD.REF_DOC_TRX_LEVEL_TYPE,
              ZD.REF_DOC_DIST_ID,
              ZD.MINIMUM_ACCOUNTABLE_UNIT,
              ZD.PRECISION,
              ZD.ROUNDING_RULE_CODE,
              -ZD.TAXABLE_AMT,
              -ZD.TAXABLE_AMT_TAX_CURR,
              -ZD.TAXABLE_AMT_FUNCL_CURR,
              ZD.TAX_ONLY_LINE_FLAG,
              -ZD.UNROUNDED_TAXABLE_AMT,
              ZD.LEGAL_ENTITY_ID,
              ZD.ACCOUNT_CCID,
              ZD.ACCOUNT_STRING,
              -ZD.PRD_TAX_AMT,
              -ZD.PRD_TAX_AMT_TAX_CURR,
              -ZD.PRD_TAX_AMT_FUNCL_CURR,
              -ZD.PRD_TOTAL_TAX_AMT,
              -ZD.PRD_TOTAL_TAX_AMT_TAX_CURR,
              -ZD.PRD_TOTAL_TAX_AMT_FUNCL_CURR,
              ZD.APPLIED_FROM_TAX_DIST_ID,
              ZD.ADJUSTED_DOC_TAX_DIST_ID,
              ZD.FUNC_CURR_ROUNDING_ADJUSTMENT,
              ZD.GLOBAL_ATTRIBUTE16,
              ZD.GLOBAL_ATTRIBUTE17,
              ZD.GLOBAL_ATTRIBUTE18,
              ZD.GLOBAL_ATTRIBUTE19,
              ZD.GLOBAL_ATTRIBUTE20,
              ZD.LAST_MANUAL_ENTRY,
              ZD.TAX_APPORTIONMENT_LINE_NUMBER,
              ZD.REF_DOC_TAX_DIST_ID,
              ZD.MRC_TAX_DIST_FLAG,
              ZD.MRC_LINK_TO_TAX_DIST_ID,
              ZD.TAX_APPORTIONMENT_FLAG,
              ZD.RATE_TAX_FACTOR,
              -ZD.REF_DOC_PER_UNIT_NREC_TAX_AMT,
              -ZD.PER_UNIT_NREC_TAX_AMT,
              -ZD.TRX_LINE_DIST_QTY,
              -ZD.REF_DOC_TRX_LINE_DIST_QTY,
              ZD.PRICE_DIFF,
              -ZD.QTY_DIFF,
              -ZD.PER_TRX_CURR_UNIT_NR_AMT,
              -ZD.REF_PER_TRX_CURR_UNIT_NR_AMT,
              ZD.REF_DOC_CURR_CONV_RATE,
              ZD.UNIT_PRICE,
              ZD.REF_DOC_UNIT_PRICE,
              ZD.APPLIED_TO_DOC_CURR_CONV_RATE,
              l_rvrsng_trx_number_tbl(i),
              1,
              ZD.INTERNAL_ORGANIZATION_ID,
              ZD.DEF_REC_SETTLEMENT_OPTION_CODE,
              ZD.TAX_JURISDICTION_ID,
              ZD.ACCOUNT_SOURCE_TAX_RATE_ID
         FROM zx_rec_nrec_dist zd
        WHERE zd.rec_nrec_tax_dist_id = l_rvrsed_tax_dist_id_tbl(i);

  IF (g_level_statement >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS',
                   'Number of rows inserted in zx_rec_nrec_dist = '||SQL%ROWCOUNT);
  END IF;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS.END',
                   'ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS(-)'||
                   'RETURN_STATUS = ' || x_return_status);
  END IF;

EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS',
                     'Tax Lines Distribution Record Already Exists');
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
    END IF;

  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
    END IF;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS.END',
                     'ZX_TRD_SERVICES_PUB_PKG.REVERSE_DISTRIBUTIONS(-)');
    END IF;

END REVERSE_DISTRIBUTIONS;


/* ======================================================================*
 |  PUBLIC PROCEDURE  get_ccid                                           |
 |                                                                       |
 |  This procedure is called from TSRM to derive CCID for a tax          |
 |  distribution.                                                        |
 |                                                                       |
 * ======================================================================*/

PROCEDURE GET_CCID(
  p_gl_date                     IN            DATE,
  p_tax_rate_id                 IN            NUMBER,
  p_rec_rate_id                 IN            NUMBER,
  p_Self_Assessed_Flag          IN            VARCHAR2,
  p_Recoverable_Flag            IN            VARCHAR2,
  p_tax_jurisdiction_id         IN            NUMBER,
  p_tax_regime_id               IN            NUMBER,
  p_tax_id                      IN            NUMBER,
  p_tax_status_id               IN            NUMBER,
  p_org_id                      IN            NUMBER,
  p_revenue_expense_ccid        IN            NUMBER,
  p_ledger_id                   IN            NUMBER,
  p_account_source_tax_rate_id  IN            NUMBER,
  p_rec_nrec_tax_dist_id        IN            NUMBER,
  p_rec_nrec_ccid                 OUT NOCOPY  NUMBER,
  p_tax_liab_ccid                 OUT NOCOPY  NUMBER,
  x_return_status                 OUT NOCOPY  VARCHAR2)  IS

  CURSOR get_rec_nrec_ccid_cur(c_tax_account_entity_id NUMBER,
                               c_tax_account_entity_code VARCHAR2,
                               c_org_id NUMBER) IS
  SELECT interim_tax_ccid, tax_account_ccid, non_rec_account_ccid
    FROM zx_accounts
   WHERE TAX_ACCOUNT_ENTITY_ID = c_tax_account_entity_id
     AND tax_account_entity_code = c_tax_account_entity_code
     AND internal_organization_id = c_org_id;

  CURSOR is_ccid_valid(l_ccid NUMBER) IS
  SELECT 'x'
    FROM gl_code_combinations
   WHERE code_combination_id = l_ccid
     AND enabled_flag = 'Y'
     AND p_gl_date BETWEEN NVL(start_date_active,p_gl_date)
         AND NVL(end_date_active, p_gl_date);

  CURSOR get_def_rec_settle_option_code(c_tax_rate_id NUMBER) IS
  SELECT def_rec_settlement_option_code
    FROM zx_rates_b
   WHERE tax_rate_id = c_tax_rate_id;

  CURSOR get_rate_code_csr(c_rate_id NUMBER) IS
  SELECT tax_rate_code
    FROM zx_rates_b
   WHERE tax_rate_id = c_rate_id;

  -- Added following 2 cursors for Bug#13948234 --
  CURSOR get_chart_of_account(c_sob_id NUMBER) IS
  SELECT chart_of_accounts_id
    FROM gl_sets_of_books
   WHERE set_of_books_id = c_sob_id;

  CURSOR get_account_string (l_ccid NUMBER) IS
  SELECT SUBSTRB(concatenated_segments,1,250) account_string
    FROM gl_code_combinations_kfv
   WHERE code_combination_id = l_ccid;

  l_source_rate_code              VARCHAR2(30);
  l_rate_code                     VARCHAR2(30);
  l_rec_rate_code                 VARCHAR2(30);
  l_tax_rate_id                   NUMBER;
  l_ccid                          NUMBER;
  l_val                           CHAR;
  l_interim_tax_ccid              NUMBER;
  l_nrec_ccid                     NUMBER;
  l_rec_ccid                      NUMBER;
  l_tax_liab_ccid                 NUMBER;
  l_def_rec_settle_option_code    ZX_RATES_B.DEF_REC_SETTLEMENT_OPTION_CODE%TYPE;
  l_chart_of_accounts_id          NUMBER;           -- Added for Bug#13948234 --
  l_account_string                VARCHAR2(250);    -- Added for Bug#13948234 --
  l_error_buffer                  VARCHAR2(2000);

BEGIN
  -- rewritten this API for bug 5645569. Per this bug
  --When Self Assessed Flag is 'N', then
  --
  -- - Tax liability account should always be returned as NULL, for both
  --   Recoverable and non-recoverable distributions
  -- - For recoverable tax distributions, the REC_NREC_ACCOUNT_CCID should be
  --   obtained by joining to  ZX_ACCOUNTS using Receovery Rate Id first.
  --   If account is not found using recovery rate id, then the account should
  --   be obtained from ZX_ACCOUNTS using tax_rate_id. If default reocovery
  --   settlement option code is DEFERRED, then return the interim_tax_ccid
  --   otherwise return tax_account_ccid.
  -- - For non-recoverable tax distributions, the REC_NREC_ACCOUNT_CCID should be
  --   obtained from ZX_ACCOUNTS using Tax Rate Id first. The account returned
  --   should be the Non-Recoverable or Expense Account from zx_accounts. If
  --   account is not found usnig this logic then the API should return the
  --   Item/Expense Account passed in (p_revenue_expense_ccid). (We do not make
  --   use of default recovery settlement option code in this case)
  --
  --When Self Assessed Flag is 'Y', then
  -- - REC_NREC_ACCOUNT_CCID should be derived in the same manner as previously,
  --   for both recoverable and non-recoverable tax distributions.
  --
  -- -  The Tax Liability Account should be derived using regular tax rate_id.
  --    the CCID to be returned in this case is the TAX_ACCOUNT_CCID.


  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.GET_CCID(+)');

  END IF;

  IF (g_level_statement >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Input Parameters:');
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','GL Date:'||p_gl_date );
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Tax Rate Id:'||p_tax_rate_id);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Recovery Rate Id:'||p_rec_rate_id);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Self Assessed Flag:'||p_Self_Assessed_Flag);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Recoverable Flag:'|| p_Recoverable_Flag);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Org Id:'|| p_org_id);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Ledger Id:'|| p_ledger_id);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Tax regime id:'||p_tax_regime_id);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Tax Id:'|| p_tax_id);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Tax Status Id:'|| p_tax_status_id);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Revenue_Expense_ccid:'|| p_revenue_expense_ccid);
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID','Account Source Tax Rate Id:'|| p_account_source_tax_rate_id);
  END IF;

  x_return_status := FND_API.G_RET_STS_SUCCESS;

  IF p_Recoverable_Flag = 'Y' then
    --start - Bug Fix - 5950624
    OPEN get_def_rec_settle_option_code(p_tax_rate_id);
    FETCH get_def_rec_settle_option_code INTO l_def_rec_settle_option_code;
    CLOSE get_def_rec_settle_option_code;

    IF l_def_rec_settle_option_code IS NULL THEN
    --end - Bug Fix - 5950624
      IF ZX_TDS_UTILITIES_PKG.g_tax_rec_tbl.exists(p_tax_id) then
        l_def_rec_settle_option_code :=
            nvl(ZX_TDS_UTILITIES_PKG.g_tax_rec_tbl(p_tax_id).def_rec_settlement_option_code,'IMMEDIATE');
      ELSE
         ZX_TDS_UTILITIES_PKG.populate_tax_cache (
                  p_tax_id  => p_tax_id,
                  p_return_status  => x_return_status,
                  p_error_buffer   => l_error_buffer);
         l_def_rec_settle_option_code :=
              nvl(ZX_TDS_UTILITIES_PKG.g_tax_rec_tbl(p_tax_id).def_rec_settlement_option_code,'IMMEDIATE');
      END IF;
    END IF;

    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                   'Def_rec_settle_option_code: '|| l_def_rec_settle_option_code);
    END IF;

    IF p_account_source_tax_rate_id IS NOT NULL THEN
      BEGIN
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'Getting account information using account source tax rate id:'||p_account_source_tax_rate_id);
        END IF;

        IF ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl.EXISTS(TO_CHAR(p_account_source_tax_rate_id)||'RATES'||TO_CHAR(p_org_id)) THEN
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from cache for p_account_sourece_tax_rate_id ');
          END IF;

          l_interim_tax_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid;
          l_rec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid;
          l_nrec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid;

        ELSE
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from database for p_account_sourece_tax_rate_id ');
          END IF;

          OPEN get_rec_nrec_ccid_cur(p_account_source_tax_rate_id, 'RATES',p_org_id);
          FETCH get_rec_nrec_ccid_cur INTO l_interim_tax_ccid, l_rec_ccid, l_nrec_ccid;
          CLOSE get_rec_nrec_ccid_cur;

          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid := l_interim_tax_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid := l_rec_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid := l_nrec_ccid;

        END IF;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          IF (g_level_exception >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'There are more than one set of accounts defined for this tax rate id: '||p_account_source_tax_rate_id||
                           ' Please specify ledger in the input structure while calling get_ccid API.');
          END IF;
          IF get_rec_nrec_ccid_cur%ISOPEN THEN
            CLOSE get_rec_nrec_ccid_cur;
          END IF;
        WHEN OTHERS THEN
          IF (g_level_exception >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'EXCEPTION: OTHERS: '||SQLCODE||' ; '||SQLERRM);
          END IF;
          IF get_rec_nrec_ccid_cur%ISOPEN THEN
            CLOSE get_rec_nrec_ccid_cur;
          END IF;
      END;

      IF l_def_rec_settle_option_code = 'DEFERRED' THEN
        l_ccid := l_interim_tax_ccid;
      ELSE
        l_ccid := l_rec_ccid;
      END IF;

    END IF;

    IF l_ccid IS NULL THEN
      BEGIN
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'Getting account information using recovery rate id:'||p_rec_rate_id);
        END IF;

        IF ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl.EXISTS(TO_CHAR(p_rec_rate_id)||'RATES'||TO_CHAR(p_org_id)) THEN
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from cache for p_rec_rate_id ');
          END IF;

          l_interim_tax_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_rec_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid;
          l_rec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_rec_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid;
          l_nrec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_rec_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid;

        ELSE
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from database for p_rec_rate_id ');
          END IF;

          OPEN get_rec_nrec_ccid_cur(p_rec_rate_id, 'RATES',p_org_id);
          FETCH get_rec_nrec_ccid_cur INTO l_interim_tax_ccid, l_rec_ccid, l_nrec_ccid;
          CLOSE get_rec_nrec_ccid_cur;

          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_rec_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid := l_interim_tax_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_rec_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid := l_rec_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_rec_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid := l_nrec_ccid;

        END IF;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          IF (g_level_exception >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'There are more than one set of accounts defined for this tax rate id: '||p_rec_rate_id||
                           ' Please specify ledger in the input structure while calling get_ccid API.');
          END IF;
          IF get_rec_nrec_ccid_cur%ISOPEN THEN
            CLOSE get_rec_nrec_ccid_cur;
          END IF;
        WHEN OTHERS THEN
          IF (g_level_exception >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'EXCEPTION: OTHERS: '||SQLCODE||' ; '||SQLERRM);
          END IF;
          IF get_rec_nrec_ccid_cur%ISOPEN THEN
            CLOSE get_rec_nrec_ccid_cur;
          END IF;
      END;

      IF l_def_rec_settle_option_code = 'DEFERRED' then
        l_ccid := l_interim_tax_ccid;
      ELSE
        l_ccid := l_rec_ccid;
      END IF;

      IF l_ccid IS NULL THEN
        BEGIN
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting account information using tax rate id:'||p_tax_rate_id);
          END IF;

          IF ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl.EXISTS(TO_CHAR(p_tax_rate_id)||'RATES'||TO_CHAR(p_org_id)) THEN
            IF (g_level_statement >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                             'Getting from cache for p_tax_rate_id ');
            END IF;

            l_interim_tax_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid;
            l_rec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid;
            l_nrec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid;

          ELSE
            IF (g_level_statement >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                             'Getting from database for p_tax_rate_id ');
            END IF;

            OPEN get_rec_nrec_ccid_cur(p_tax_rate_id, 'RATES',p_org_id);
            FETCH get_rec_nrec_ccid_cur INTO l_interim_tax_ccid, l_rec_ccid, l_nrec_ccid;
            CLOSE get_rec_nrec_ccid_cur;

            ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid := l_interim_tax_ccid;
            ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid := l_rec_ccid;
            ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid := l_nrec_ccid;

          END IF;
        EXCEPTION
          WHEN TOO_MANY_ROWS THEN
            IF (g_level_exception >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                             'There are more than one set of accounts defined for this tax rate id: '||p_tax_rate_id||
                             ' Please specify ledger in the input structure while calling get_ccid API.');
             END IF;
             IF get_rec_nrec_ccid_cur%ISOPEN THEN
               CLOSE get_rec_nrec_ccid_cur;
             END IF;
           WHEN OTHERS THEN
             IF (g_level_exception >= g_current_runtime_level ) THEN
               FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                              'EXCEPTION: OTHERS: '||SQLCODE||' ; '||SQLERRM);
             END IF;
             IF get_rec_nrec_ccid_cur%ISOPEN THEN
               CLOSE get_rec_nrec_ccid_cur;
             END IF;
        END;

        IF l_def_rec_settle_option_code = 'DEFERRED' then
          l_ccid := l_interim_tax_ccid;
        ELSE
          l_ccid := l_rec_ccid;
        END IF;

      END IF;  -- l_ccid is null
    END IF;   -- l_ccid is null

  ELSIF p_Recoverable_Flag <> 'Y' THEN
    IF p_account_source_tax_rate_id IS NOT NULL THEN
      BEGIN
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'Getting account information using account source tax rate id:'||p_account_source_tax_rate_id);
        END IF;

        IF ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl.EXISTS(TO_CHAR(p_account_source_tax_rate_id)||'RATES'||TO_CHAR(p_org_id)) THEN
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from cache for p_account_source_tax_rate_id ');
          END IF;

          l_interim_tax_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid;
          l_rec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid;
          l_nrec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid;

        ELSE
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from database for p_account_source_tax_rate_id ');
          END IF;

          OPEN get_rec_nrec_ccid_cur(p_account_source_tax_rate_id, 'RATES',p_org_id);
          FETCH get_rec_nrec_ccid_cur INTO l_interim_tax_ccid, l_rec_ccid, l_nrec_ccid;
          CLOSE get_rec_nrec_ccid_cur;

          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid := l_interim_tax_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid := l_rec_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid := l_nrec_ccid;

        END IF;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          IF (g_level_exception >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'There are more than one set of accounts defined for this tax rate id: '||p_account_source_tax_rate_id||
                           ' Please specify ledger in the input structure while calling get_ccid API.');
          END IF;
          IF get_rec_nrec_ccid_cur%ISOPEN THEN
            CLOSE get_rec_nrec_ccid_cur;
          END IF;
        WHEN OTHERS THEN
          IF (g_level_exception >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'EXCEPTION: OTHERS: '||SQLCODE||' ; '||SQLERRM);
          END IF;
          IF get_rec_nrec_ccid_cur%ISOPEN THEN
            CLOSE get_rec_nrec_ccid_cur;
          END IF;
      END;

      l_ccid := l_nrec_ccid;
    END IF;

    IF l_ccid IS NULL THEN
      BEGIN
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'Getting account information using tax rate id:'||p_tax_rate_id);
        END IF;

        IF ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl.EXISTS(TO_CHAR(p_tax_rate_id)||'RATES'||TO_CHAR(p_org_id)) THEN
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                   'Getting from cache for p_tax_rate_id ');
          END IF;

          l_interim_tax_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid;
          l_rec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid;
          l_nrec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid;

        ELSE
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from database for p_tax_rate_id ');
          END IF;

          OPEN get_rec_nrec_ccid_cur(p_tax_rate_id, 'RATES', p_org_id);
          FETCH get_rec_nrec_ccid_cur INTO l_interim_tax_ccid, l_rec_ccid, l_nrec_ccid;
          CLOSE get_rec_nrec_ccid_cur;

          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid := l_interim_tax_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid := l_rec_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid := l_nrec_ccid;

        END IF;
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          IF (g_level_exception >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'There are more than one set of accounts defined for this tax rate id: '||p_tax_rate_id||
                           ' Please specify ledger in the input structure while calling get_ccid API.');
          END IF;
          IF get_rec_nrec_ccid_cur%ISOPEN THEN
            CLOSE get_rec_nrec_ccid_cur;
          END IF;
        WHEN OTHERS THEN
          IF (g_level_exception >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'EXCEPTION: OTHERS: '||SQLCODE||' ; '||SQLERRM);
          END IF;
          IF get_rec_nrec_ccid_cur%ISOPEN THEN
            CLOSE get_rec_nrec_ccid_cur;
          END IF;
      END;

      l_ccid := l_nrec_ccid;
    END IF;

    IF l_ccid IS NULL THEN
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                       'Assigning the value of Revenue_Expense_CCID ');
      END IF;
      l_ccid := p_revenue_expense_ccid;
    END IF;

  END IF; -- p_Recoverable_Flag = 'Y'

  IF l_ccid IS NOT NULL THEN -- Validate the CCID
    -- If ccid is invalid, EBTax will not nullify it and raise an error for
    -- normal rec or nrec case. AP will check if the ccid is valid and if it
    -- is not valid, it will place invoice on hold

    /*OPEN is_ccid_valid(l_ccid);
      FETCH is_ccid_valid INTO l_val;

      IF is_ccid_valid%NOTFOUND THEN
        l_ccid := NULL;
      END IF;

      CLOSE is_ccid_valid;*/

    p_rec_nrec_ccid := l_ccid;

  END IF;

  IF p_Self_Assessed_Flag = 'Y' THEN
    -- return liability account only for self assessed taxes
    -- The Tax Liability Account should be derived using regular tax rate_id.
    -- the CCID to be returned in this case is the TAX_ACCOUNT_CCID.

    BEGIN
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                       'Getting Liability account information using tax rate id:'||p_tax_rate_id);
      END IF;

      IF ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl.EXISTS(TO_CHAR(p_tax_rate_id)||'RATES'||TO_CHAR(p_org_id)) THEN
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'Getting from cache for p_tax_rate_id ');
        END IF;

        l_interim_tax_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid;
        -- Bug 7299892 --
        l_tax_liab_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid;
        l_nrec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid;

      ELSE
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'Getting from database for p_tax_rate_id ');
        END IF;

        OPEN get_rec_nrec_ccid_cur(p_tax_rate_id, 'RATES',p_org_id);
        FETCH get_rec_nrec_ccid_cur INTO l_interim_tax_ccid, l_tax_liab_ccid, l_nrec_ccid;
        CLOSE get_rec_nrec_ccid_cur;

        ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid := l_interim_tax_ccid;
        --Bug 7299892 --
        ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid := l_tax_liab_ccid;
        ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid := l_nrec_ccid;

      END IF;

      IF l_tax_liab_ccid IS NULL AND p_Recoverable_Flag <> 'Y' THEN
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'Getting Liability account information using Account source tax rate id:'||p_account_source_tax_rate_id);
        END IF;

        IF ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl.EXISTS(TO_CHAR(p_account_source_tax_rate_id)||'RATES'||TO_CHAR(p_org_id)) THEN
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from cache for p_account_source_tax_rate_id ');
          END IF;

          l_interim_tax_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid;
          -- Bug 7299892 --
          l_tax_liab_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid;
          l_nrec_ccid := ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid;

        ELSE
          IF (g_level_statement >= g_current_runtime_level ) THEN
            FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                           'Getting from database for p_account_source_tax_rate_id ');
          END IF;

          OPEN get_rec_nrec_ccid_cur(p_account_source_tax_rate_id, 'RATES',p_org_id);
          FETCH get_rec_nrec_ccid_cur INTO l_interim_tax_ccid, l_tax_liab_ccid, l_nrec_ccid;
          CLOSE get_rec_nrec_ccid_cur;

          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(P_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).interim_tax_ccid := l_interim_tax_ccid;
          -- Bug 7299892 --
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).tax_account_ccid := l_tax_liab_ccid;
          ZX_GLOBAL_STRUCTURES_PKG.rec_nrec_ccid_tbl(to_char(p_account_source_tax_rate_id)||'RATES'||to_char(p_org_id)).non_rec_account_ccid := l_nrec_ccid;

        END IF;
      END IF;
    EXCEPTION
      WHEN TOO_MANY_ROWS THEN
        IF (g_level_exception >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'There are more than one set of accounts defined for this tax rate id: '||p_tax_rate_id||
                         ' Please specify ledger in the input structure while calling get_ccid API.');
        END IF;
        IF get_rec_nrec_ccid_cur%ISOPEN THEN
          CLOSE get_rec_nrec_ccid_cur;
        END IF;
      WHEN OTHERS THEN
        IF (g_level_exception >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_exception,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                         'EXCEPTION: OTHERS: '||SQLCODE||' ; '||SQLERRM);
        END IF;
        IF get_rec_nrec_ccid_cur%ISOPEN THEN
          CLOSE get_rec_nrec_ccid_cur;
        END IF;
    END;

    -- Validate l_tax_liab_ccid if it is different from l_ccid --
    IF  l_tax_liab_ccid IS NOT NULL AND l_ccid IS NOT NULL AND l_tax_liab_ccid <> l_ccid THEN
      -- If l_tax_liab_ccid is invalid, EBTax will continue to nullify and raise an error for
      -- self assessed case.

      /*OPEN is_ccid_valid(l_tax_liab_ccid);
        FETCH is_ccid_valid INTO l_val;

        IF is_ccid_valid%NOTFOUND THEN
          l_tax_liab_ccid := NULL;
        END IF;
        CLOSE is_ccid_valid;*/

      NULL;
    END IF;

    p_tax_liab_ccid := l_tax_liab_ccid;
  END IF;  -- p_Self_Assessed_Flag = 'Y'

  -- Raise error in case of NULL CCIDs --
  IF p_rec_nrec_ccid IS NULL THEN
    BEGIN
      IF p_account_source_tax_rate_id IS NOT NULL THEN
        OPEN  get_rate_code_csr(p_account_source_tax_rate_id);
        FETCH get_rate_code_csr INTO l_source_rate_code;
        CLOSE get_rate_code_csr;
      END IF;

      IF p_tax_rate_id IS NOT NULL THEN
        OPEN  get_rate_code_csr(p_tax_rate_id);
        FETCH get_rate_code_csr INTO l_rate_code;
        CLOSE get_rate_code_csr;
      END IF;

      IF p_rec_rate_id IS NOT NULL THEN
        OPEN  get_rate_code_csr(p_rec_rate_id);
        FETCH get_rate_code_csr INTO l_rec_rate_code;
        CLOSE get_rate_code_csr;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

    IF p_Recoverable_Flag = 'Y' THEN                        -- bug 4893261
      x_return_status := FND_API.G_RET_STS_ERROR;
      FND_MESSAGE.SET_NAME('ZX', 'ZX_INVALID_REC_CCID');
      FND_MESSAGE.SET_TOKEN('TAXRATE', l_rate_code);
      FND_MESSAGE.SET_TOKEN('SOURCE_TAXRATE', l_source_rate_code);
      FND_MSG_PUB.Add;
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                       'error: p_Recoverable_Flag is Y, but p_rec_nrec_ccid is null');
      END IF;

    ELSIF p_Recoverable_Flag = 'N' THEN
      x_return_status := FND_API.G_RET_STS_ERROR;     -- bug 4893261,
      FND_MESSAGE.SET_NAME('ZX', 'ZX_INVALID_NREC_CCID');
      FND_MESSAGE.SET_TOKEN('TAXRATE', l_rate_code);
      FND_MESSAGE.SET_TOKEN('SOURCE_TAXRATE', l_source_rate_code);
      FND_MSG_PUB.Add;
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                      'error: p_Recoverable_Flag is N, but p_rec_nrec_ccid is null');
      END IF;
    END IF;
  END IF;

  --Bug#6448736 : Need to error if tax liabilty account is not defined
  --              at the tax rate level of the self assessed tax
  --Bug#6807089 : Need to display proper error message when the ccid is invalid.

  IF p_Self_Assessed_Flag = 'Y' AND p_tax_liab_ccid IS NULL THEN
    x_return_status := FND_API.G_RET_STS_ERROR;
    -- bug 8568734
    BEGIN
      IF p_account_source_tax_rate_id IS NOT NULL AND l_source_rate_code IS NULL
      THEN
        OPEN  get_rate_code_csr(p_account_source_tax_rate_id);
        FETCH get_rate_code_csr INTO l_source_rate_code;
        CLOSE get_rate_code_csr;
      END IF;

      IF p_tax_rate_id IS NOT NULL AND l_rate_code IS NULL THEN
        OPEN  get_rate_code_csr(p_tax_rate_id);
        FETCH get_rate_code_csr INTO l_rate_code;
        CLOSE get_rate_code_csr;
      END IF;

      IF p_rec_rate_id IS NOT NULL AND l_rec_rate_code IS NULL THEN
        OPEN  get_rate_code_csr(p_rec_rate_id);
        FETCH get_rate_code_csr INTO l_rec_rate_code;
        CLOSE get_rate_code_csr;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

    FND_MESSAGE.SET_NAME('ZX', 'ZX_INVALID_LIAB_CCID');
    -- bug 8568734
    FND_MESSAGE.SET_TOKEN('TAXRATE', l_rate_code);
    FND_MESSAGE.SET_TOKEN('SOURCE_TAXRATE', l_source_rate_code);
    FND_MSG_PUB.Add;
    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                     'error: p_Self_Assessed_Flag is Y, but p_tax_liab_ccid is null');
    END IF;
  END IF;

  -- Start : Bug#13948234 : Execute the Security Rules Validation --
  OPEN get_chart_of_account(p_ledger_id);
  FETCH get_chart_of_account INTO l_chart_of_accounts_id;
  CLOSE get_chart_of_account;

  IF (g_level_statement >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                   'Chart Of Accounts Id : '||l_chart_of_accounts_id);
  END IF;

  IF p_rec_nrec_ccid IS NOT NULL AND p_rec_nrec_ccid <> -99 AND
     l_chart_of_accounts_id IS NOT NULL
  THEN

    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                     'Running security rules validation for Rec_Nrec_CCID : '||p_rec_nrec_ccid);
    END IF;

    IF NOT fnd_flex_keyval.validate_ccid
                            (appl_short_name  =>'SQLGL',
                             key_flex_code    => 'GL#',
                             structure_number => l_chart_of_accounts_id,
                             combination_id   => p_rec_nrec_ccid,
                             security         => 'ENFORCE')
    THEN
      x_return_status := FND_API.G_RET_STS_ERROR;

      OPEN get_account_string(p_rec_nrec_ccid);
      FETCH get_account_string INTO l_account_string;
      CLOSE get_account_string;

      FND_MESSAGE.SET_NAME('ZX','ZX_TAX_ACCOUNT_RULE_VIOLATE');
      FND_MESSAGE.SET_TOKEN('ACCOUNT', l_account_string);
      FND_MSG_PUB.Add;
      -- The account ACCOUNT derived for tax distribution violates the defined security rules --
      -- Please contact your Tax Manager --
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                       'error: Rec_Nrec_CCID violates the defined security rules');
        FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                       'CCID: '||p_rec_nrec_ccid||', Account : '||l_account_string);
      END IF;
    END IF;
  END IF;

  IF p_Self_Assessed_Flag = 'Y' AND
     p_tax_liab_ccid IS NOT NULL AND
     l_chart_of_accounts_id IS NOT NULL
  THEN

    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                     'Running security rules validation for Tax_Liab_CCID : '||p_tax_liab_ccid);
    END IF;

    IF NOT fnd_flex_keyval.validate_ccid
                            (appl_short_name  =>'SQLGL',
                             key_flex_code    => 'GL#',
                             structure_number => l_chart_of_accounts_id,
                             combination_id   => p_tax_liab_ccid,
                             security         => 'ENFORCE')
    THEN
      x_return_status := FND_API.G_RET_STS_ERROR;

      OPEN get_account_string(p_tax_liab_ccid);
      FETCH get_account_string INTO l_account_string;
      CLOSE get_account_string;

      FND_MESSAGE.SET_NAME('ZX','ZX_TAX_ACCOUNT_RULE_VIOLATE');
      FND_MESSAGE.SET_TOKEN('ACCOUNT', l_account_string);
      FND_MSG_PUB.Add;

      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                       'error: Self Assessed Flag is Y and Tax_Liab_CCID violates the defined security rules');
        FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                       'CCID: '||p_tax_liab_ccid||', Account : '||l_account_string);
      END IF;
    END IF;
  END IF;
  -- End : Bug#13948234 --

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID.END',
                   'ZX_TRD_SERVICES_PUB_PKG.GET_CCID(-)'||
                   ' p_rec_nrec_ccid = '||p_rec_nrec_ccid||
                   ' p_tax_liab_ccid = '||p_tax_liab_ccid||
                   ' return status = '||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
    END IF;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_CCID.END',
                     'ZX_TRD_SERVICES_PUB_PKG.GET_CCID(-)');
    END IF;

END GET_CCID;

/* ======================================================================*
 |  PUBLIC PROCEDURE  get_output_tax_ccid                                |
 |                                                                       |
 |  This procedure is called from TSRM to derive CCID for a tax          |
 |  distribution.                                                        |
 |                                                                       |
 * ======================================================================*/

PROCEDURE GET_OUTPUT_TAX_CCID(
        p_gl_date               IN              DATE,
        p_tax_rate_id           IN              NUMBER,
        p_location_segment_id   IN              NUMBER,
        p_tax_line_id           IN              NUMBER,
        p_org_id                IN              NUMBER,
        p_ledger_id             IN              NUMBER,
        p_event_class_code      IN              VARCHAR2,
        p_entity_code           IN              VARCHAR2,
        p_application_id        IN              NUMBER,
        p_document_id           IN              NUMBER,
        p_document_line_id      IN              NUMBER,
        p_trx_level_type        IN              VARCHAR2,
        p_tax_account_ccid         OUT NOCOPY   NUMBER,
        p_interim_tax_ccid         OUT NOCOPY   NUMBER,
        p_adj_ccid                 OUT NOCOPY   NUMBER,
        p_edisc_ccid               OUT NOCOPY   NUMBER,
        p_unedisc_ccid             OUT NOCOPY   NUMBER,
        p_finchrg_ccid             OUT NOCOPY   NUMBER,
        p_adj_non_rec_tax_ccid     OUT NOCOPY   NUMBER,
        p_edisc_non_rec_tax_ccid   OUT NOCOPY   NUMBER,
        p_unedisc_non_rec_tax_ccid OUT NOCOPY   NUMBER,
        p_finchrg_non_rec_tax_ccid OUT NOCOPY   NUMBER,
        x_return_status            OUT NOCOPY   VARCHAR2) IS

Cursor get_loc_account_ccid(p_loc_segment_id number, p_org_id number) is
select tax_account_ccid, interim_tax_ccid, adj_ccid, edisc_ccid,
        unedisc_ccid, finchrg_ccid, adj_non_rec_tax_ccid, edisc_non_rec_tax_ccid,
        unedisc_non_rec_tax_ccid, finchrg_non_rec_tax_ccid
from  ar_location_accounts_all
where location_segment_id = p_loc_segment_id
and   org_id = p_org_id;

Cursor get_zx_account_ccid(c_tax_account_entity_id number, c_tax_account_entity_code varchar2, c_org_id number,
                           c_ledger_id number) is
select tax_account_ccid, interim_tax_ccid, adj_ccid, edisc_ccid,
        unedisc_ccid, finchrg_ccid, adj_non_rec_tax_ccid, edisc_non_rec_tax_ccid,
        unedisc_non_rec_tax_ccid, finchrg_non_rec_tax_ccid
from   zx_accounts
where  TAX_ACCOUNT_ENTITY_ID = c_tax_account_entity_id
and    tax_account_entity_code = c_tax_account_entity_code
and    internal_organization_id  = c_org_id
and    ledger_id = c_ledger_id;

Cursor is_ccid_valid(l_ccid number) is
select 'x'
from   gl_code_combinations
where  code_combination_id = l_ccid
and    enabled_flag = 'Y'
and    p_gl_date between nvl(start_date_active,p_gl_date) and nvl(end_date_active, p_gl_date);

Cursor line_acc_src_tax_rate_id(p_tax_line_id IN NUMBER) is
select account_source_tax_rate_id
from   zx_lines
where  tax_line_id = p_tax_line_id;

Cursor get_location_segment_id_csr(p_tax_line_id IN NUMBER) is
select location_segment_id
from   ra_customer_trx_lines_all inv, zx_lines cm, zx_lines zxinv
where  cm.tax_line_id = p_tax_line_id
and    cm.adjusted_doc_trx_id = inv.customer_trx_id
and    cm.adjusted_doc_tax_line_id = inv.tax_line_id
and    inv.line_type = 'TAX'
and    cm.adjusted_doc_tax_line_id = zxinv.tax_line_id
and    cm.tax_provider_id is not null
and    zxinv.record_type_code = 'MIGRATED';


l_content_owner_id              NUMBER;
l_tax_id                        NUMBER;
l_tax_jurisdiction_id           NUMBER;
l_acc_src_tax_rate_id           NUMBER;
l_tax_rate_id                   NUMBER;
l_def_rec_settle_option_code    VARCHAR2(30);
l_ccid        NUMBER;
l_val        char;
l_location_segment_id           NUMBER;

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID(+)');

  END IF;

  IF (g_level_statement >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'Input Parameters:');
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'GL Date:'||p_gl_date );
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'Tax Rate Id:'||p_tax_rate_id);
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'Location Segment Id:'||p_location_segment_id);
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'Tax Line Id:'|| p_tax_line_id);
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'Org Id:'|| p_org_id);
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'Ledger Id:'|| p_ledger_id);
  END IF;


  x_return_status := FND_API.G_RET_STS_SUCCESS;

  IF p_location_segment_id IS NULL THEN
   -- Get location_segment_id in case of credit memo for a migrated transaction
    open get_location_segment_id_csr(p_tax_line_id ) ;
    fetch get_location_segment_id_csr into l_location_segment_id;
    close get_location_segment_id_csr;
  ELSE
    l_location_segment_id := p_location_segment_id;
  END IF;


  IF l_location_segment_id IS NOT NULL THEN

    IF (g_level_statement >= g_current_runtime_level ) THEN

       FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID',
                   'Getting accounts using Location Segment.. '||to_char(l_location_segment_id));

    END IF;

    open get_loc_account_ccid(l_location_segment_id, p_org_id);
    fetch get_loc_account_ccid into p_tax_account_ccid, p_interim_tax_ccid,
                                    p_adj_ccid, p_edisc_ccid,
                                    p_unedisc_ccid, p_finchrg_ccid,
                                    p_adj_non_rec_tax_ccid, p_edisc_non_rec_tax_ccid,
                                    p_unedisc_non_rec_tax_ccid, p_finchrg_non_rec_tax_ccid;
    close get_loc_account_ccid;

    IF p_tax_account_ccid is not null THEN

      open is_ccid_valid(p_tax_account_ccid);
      fetch is_ccid_valid into l_val;

      if is_ccid_valid%notfound then
  p_tax_account_ccid := null;
      end if;

      close is_ccid_valid;

    END IF;  -- p_tax_account_ccid is not null


  END IF;  --location segment id not null

  -- Getting the tax jurisdiction id to derive accounts only for
  -- VERTEX tax calculation for migated records only.
  get_tax_jurisdiction_id(
                          p_tax_line_id,
        p_tax_rate_id,
        l_tax_jurisdiction_id,
        x_return_status);

  IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID',
                      'After calling get_tax_jurisdiction_id, x_return_status = '|| x_return_status);
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.END',
                      'ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID(-)');
      END IF;
      RETURN;
  END IF;

  IF p_tax_account_ccid IS NULL THEN
    IF p_tax_line_id IS NOT NULL THEN
        IF (g_level_statement >= g_current_runtime_level ) THEN
           FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID',
                       'Getting account information for the jurisdiction id '||to_char(l_tax_jurisdiction_id));
        END IF;
  IF l_tax_jurisdiction_id IS NOT NULL THEN
          open get_zx_account_ccid(l_tax_jurisdiction_id, 'JURISDICTION', p_org_id, p_ledger_id);
          fetch get_zx_account_ccid into p_tax_account_ccid, p_interim_tax_ccid,
                                       p_adj_ccid, p_edisc_ccid,
                                       p_unedisc_ccid, p_finchrg_ccid,
                                       p_adj_non_rec_tax_ccid, p_edisc_non_rec_tax_ccid,
                                       p_unedisc_non_rec_tax_ccid, p_finchrg_non_rec_tax_ccid;

         close get_zx_account_ccid;


        IF (g_level_statement >= g_current_runtime_level ) THEN
               FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID',
                       'Tax account for jurisdiction_id '||to_char(l_tax_jurisdiction_id)||
                       ' is: '||to_char(p_tax_account_ccid));
        END IF;
  IF p_tax_account_ccid is not null THEN

          open is_ccid_valid(p_tax_account_ccid);
          fetch is_ccid_valid into l_val;

          if is_ccid_valid%notfound then
            p_tax_account_ccid := null;
          end if;

          close is_ccid_valid;

        END IF; -- p_tax_account_ccid is not null
       END IF;  --l_tax_jurisdiction_id is not null
    END IF; --p_tax_line_id is not null
  END IF; --p_tax_account_ccid is null

    l_tax_rate_id := p_tax_rate_id;

    IF p_tax_account_ccid IS NULL THEN

      IF p_tax_line_id IS NOT NULL THEN

        IF (g_level_statement >= g_current_runtime_level ) THEN
           FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID',
                       'Getting account source tax rate id for tax line id '||to_char(p_tax_line_id));
        END IF;

        open line_acc_src_tax_rate_id(p_tax_line_id);
        fetch line_acc_src_tax_rate_id into l_acc_src_tax_rate_id;
        IF l_acc_src_tax_rate_id IS NOT NULL THEN
          open get_zx_account_ccid(l_acc_src_tax_rate_id, 'RATES', p_org_id, p_ledger_id);
          fetch get_zx_account_ccid into p_tax_account_ccid, p_interim_tax_ccid,
                                       p_adj_ccid, p_edisc_ccid,
                                       p_unedisc_ccid, p_finchrg_ccid,
                                       p_adj_non_rec_tax_ccid, p_edisc_non_rec_tax_ccid,
                                       p_unedisc_non_rec_tax_ccid, p_finchrg_non_rec_tax_ccid;

        close get_zx_account_ccid;


        IF (g_level_statement >= g_current_runtime_level ) THEN
               FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID',
                       'Tax account for acct_source_tax_rate_id '||to_char(l_acc_src_tax_rate_id)||
                       ' is: '||to_char(p_tax_account_ccid));
        END IF;

        IF p_tax_account_ccid is not null THEN

          open is_ccid_valid(p_tax_account_ccid);
          fetch is_ccid_valid into l_val;

          if is_ccid_valid%notfound then
            p_tax_account_ccid := null;
          end if;

          close is_ccid_valid;

        END IF; -- p_tax_account_ccid is not null

      END IF; --l_acc_src_tax_rate_id is not null check
    END IF; -- p_tax_line_id is not null check
  END IF;

IF p_tax_account_ccid is null THEN
      IF l_tax_rate_id is not null THEN

        IF (g_level_statement >= g_current_runtime_level ) THEN
           FND_LOG.STRING(g_level_statement,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID',
                       'Getting account information using tax rate id: '||to_char(l_tax_rate_id));
        END IF;

        open get_zx_account_ccid(l_tax_rate_id, 'RATES', p_org_id, p_ledger_id);
        fetch get_zx_account_ccid into p_tax_account_ccid, p_interim_tax_ccid,
                                       p_adj_ccid, p_edisc_ccid,
                                       p_unedisc_ccid, p_finchrg_ccid,
                                       p_adj_non_rec_tax_ccid, p_edisc_non_rec_tax_ccid,
                                       p_unedisc_non_rec_tax_ccid, p_finchrg_non_rec_tax_ccid;

        close get_zx_account_ccid;

        IF p_tax_account_ccid is not null THEN

          open is_ccid_valid(p_tax_account_ccid);
          fetch is_ccid_valid into l_val;

          if is_ccid_valid%notfound then
            p_tax_account_ccid := null;
          end if;

          close is_ccid_valid;

        END IF;  -- p_tax_account_ccid is not null

      END IF; -- l_tax_rate_id is not null check
    END IF;


      IF p_interim_tax_ccid is not null THEN

        open is_ccid_valid(p_interim_tax_ccid);
        fetch is_ccid_valid into l_val;

        if is_ccid_valid%notfound then
          p_interim_tax_ccid := null;
        end if;

        close is_ccid_valid;

      END IF;  -- p_interim_tax_ccid is not null

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.END',
                   'ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID(-)'||
                   ' tax_account_ccid = ' ||        p_tax_account_ccid          ||
                   ' interim_tax_ccid = ' ||        p_interim_tax_ccid          ||
                   ' adj_ccid  = ' ||               p_adj_ccid                  ||
                   ' edisc_ccid = ' ||              p_edisc_ccid                ||
                   ' unedisc_ccid  = ' ||           p_unedisc_ccid              ||
                   ' finchrg_ccid = ' ||            p_finchrg_ccid              ||
                   ' adj_non_rec_tax_ccid = ' ||    p_adj_non_rec_tax_ccid      ||
                   ' edisc_non_rec_tax_ccid = ' ||  p_edisc_non_rec_tax_ccid    ||
                   ' unedisc_non_rec_tax_ccid = ' ||p_unedisc_non_rec_tax_ccid  ||
                   ' finchrg_non_rec_tax_ccid = ' ||p_finchrg_non_rec_tax_ccid  ||
                   ' RETURN_STATUS = ' || x_return_status);

  END IF;



EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
    END IF;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.END',
                     'ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID(-)');
    END IF;

END GET_OUTPUT_TAX_CCID;


/* ======================================================================*
 |  PRIVATE PROCEDURE  insert_item_dist                                  |
 |                                                                       |
 |  This procedure is insert dummy item distributions into the global    |
 |  temporary table for the tax only tax line.                           |
 |                                                                       |
 * ======================================================================*/

 PROCEDURE insert_item_dist(
  p_tax_line_rec    IN              zx_lines%ROWTYPE,
  x_return_status      OUT NOCOPY   VARCHAR2) IS

 BEGIN

  IF (g_level_procedure >= g_current_runtime_level ) THEN
   FND_LOG.STRING(g_level_procedure,
                  'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.INSERT_ITEM_DIST.BEGIN',
                  'ZX_TRD_SERVICES_PUB_PKG.INSERT_ITEM_DIST(+)');
  END IF;

  INSERT INTO zx_itm_distributions_gt(
               --internal_organization_id,
              application_id,
              entity_code,
              event_class_code,
--              event_type_code,
              trx_id  ,
              trx_line_id,
              trx_level_type,
              trx_line_dist_id,
              dist_level_action,
              trx_line_dist_date,
              --set_of_books_id,
              --trx_currency_code,
              --currency_conversion_date,
              --currency_conversion_rate,
              --currency_conversion_type,
              --minimum_accountable_unit,
              --precision,
              item_dist_number,
              dist_intended_use,
              tax_inclusion_flag,
              tax_code,
              task_id ,
              award_id,
              project_id,
              expenditure_type,
              expenditure_organization_id,
              expenditure_item_date,
              trx_line_dist_amt,
              trx_line_dist_qty,
              trx_line_quantity,
              account_ccid,
              account_string,
              --trx_number,       -- check later
              ref_doc_application_id,
              ref_doc_entity_code,
              ref_doc_event_class_code,
              ref_doc_trx_id,
              ref_doc_line_id,
              ref_doc_trx_level_type,
              ref_doc_dist_id,
              ref_doc_curr_conv_rate,
              --content_owner_id,    -- check later
              --tax_event_class_code,          -- check later
              --tax_event_type_code,
              --doc_event_status,
              trx_line_dist_tax_amt,
              --quote_flag,
              historical_flag)
      SELECT
              --p_tax_line_rec.internal_organization_id,
              application_id,
              entity_code,
              event_class_code,
--              event_type_code,
              trx_id,
              trx_line_id,
              trx_level_type,
              -99,                                      -- p_tax_line_rec.TRX_LINE_DIST_ID
              'CREATE',                                 -- p_tax_line_rec.DIST_LEVEL_ACTION
              nvl(trx_line_gl_date, trx_date),          -- trx_line_dist_date
              --p_tax_line_rec.ledger_id,               -- set_of_books_id
              --p_tax_line_rec.trx_currency_code,
              --p_tax_line_rec.currency_conversion_date,
              --p_tax_line_rec.currency_conversion_rate,
              --p_tax_line_rec.currency_conversion_type,
              --p_tax_line_rec.minimum_accountable_unit,
              --p_tax_line_rec.precision,
              1,           -- item dist number
              line_intended_use,            -- copy line intended use to dist
              p_tax_line_rec.tax_amt_included_flag,     -- tax_inclusion_flag
              p_tax_line_rec.tax_code,
              NULL,                                     -- TASK_ID
              NULL,          -- AWARD_ID
              NULL,          -- PROJECT_ID
              NULL,          -- EXPENDITURE_TYPE
              NULL,           -- EXPENDITURE_ORGANIZATION_ID
              NULL,          -- EXPENDITURE_ITEM_DATE
              line_amt,
              trx_line_quantity,
              trx_line_quantity,
              account_ccid,
              account_string,
              --p_tax_line_rec.trx_number,
              ref_doc_application_id,
              ref_doc_entity_code,
              ref_doc_event_class_code,
              ref_doc_trx_id,
              ref_doc_line_id,
              ref_doc_trx_level_type,
              NULL,          -- REF_DOC_DIST_ID
              NULL,          -- REF_DOC_CURR_CONV_RATE
              --p_tax_line_rec.content_owner_id,
              --p_tax_line_rec.tax_event_class_code,
              --p_tax_line_rec.tax_event_type_code,
              --p_tax_line_rec.doc_event_status,
              p_tax_line_rec.tax_amt,
              -- 'N',                -- Quote_Flag what should it be?
              Historical_Flag
         FROM zx_lines_det_factors
        WHERE application_id = p_tax_line_rec.application_id
          AND event_class_code = p_tax_line_rec.event_class_code
          AND entity_code = p_tax_line_rec.entity_code
          AND trx_id = p_tax_line_rec.trx_id
          AND trx_line_id = p_tax_line_rec.trx_line_id
          AND trx_level_type = p_tax_line_rec.trx_level_type;

   IF (g_level_procedure >= g_current_runtime_level ) THEN
     FND_LOG.STRING(g_level_procedure,
                  'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.INSERT_ITEM_DIST.END',
                  'ZX_TRD_SERVICES_PUB_PKG.INSERT_ITEM_DIST(-)');
   END IF;

EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_item_dist',
                     'TRL Record Already Exists');
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_item_dist',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
    END IF;

  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_item_dist',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
    END IF;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_unexpected,
                         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_item_dist.END',
                         'ZX_TRD_SERVICES_PUB_PKG.INSERT_ITEM_DIST(-)');
    END IF;
END insert_item_dist;

/* ======================================================================*
 |  PRIVATE PROCEDURE  fetch_tax_lines                                   |
 |                                                                       |
 |  This procedure is used to fetch all the tax lines that need to be    |
 |  for recovery.                                                        |
 |                                                                       |
 * ======================================================================*/

PROCEDURE fetch_tax_lines (
  p_event_class_rec  IN              ZX_API_PUB.EVENT_CLASS_REC_TYPE,
  p_tax_line_tbl        OUT NOCOPY   tax_line_tbl_type,
  x_return_status       OUT NOCOPY   VARCHAR2) IS

 detail_ctr         number;

 CURSOR fetch_tax_lines_csr IS
   SELECT * FROM zx_lines zl
    WHERE trx_id = p_event_class_rec.trx_id
      AND application_id = p_event_class_rec.application_id
      AND entity_code = p_event_class_rec.entity_code
      AND event_class_code = p_event_class_rec.event_class_code
      -- Added the EXISTS clause to pick only those tax lines for processing
      -- whose trx lines are updated with the current event_id : Bug#17834748
      AND EXISTS
          (SELECT 1 FROM zx_lines_det_factors zldf
            WHERE zldf.application_id   = zl.application_id
              AND zldf.entity_code      = zl.entity_code
              AND zldf.event_class_code = zl.event_class_code
              AND zldf.trx_id           = zl.trx_id
              AND zldf.trx_line_id      = zl.trx_line_id
              AND zldf.trx_level_type   = zl.trx_level_type
              AND zldf.event_id         = p_event_class_rec.event_id
          )
      AND nvl(Reporting_Only_Flag, 'N') = 'N'    -- do not process reporting only lines
      AND (Process_For_Recovery_Flag = 'Y' OR (nvl(Item_Dist_Changed_Flag, 'Y') = 'Y'))
      AND mrc_tax_line_flag = 'N'
    ORDER BY trx_line_id, trx_level_type, account_source_tax_rate_id nulls first ;

 CURSOR fetch_tax_lines_gt_csr IS
  SELECT /*+ INDEX(ZX_DETAIL_TAX_LINES_GT ZX_DETAIL_TAX_LINES_GT_U1) */
         *
    FROM zx_detail_tax_lines_gt
   WHERE application_id = p_event_class_rec.application_id
     AND entity_code = p_event_class_rec.entity_code
     AND event_class_code = p_event_class_rec.event_class_code
     AND trx_id = p_event_class_rec.trx_id
     AND nvl(reporting_only_flag, 'N') = 'N'
     AND (process_for_recovery_flag = 'Y' OR (nvl(Item_Dist_Changed_Flag, 'Y') = 'Y'))
     AND mrc_tax_line_flag = 'N'
   ORDER BY trx_line_id, trx_level_type, account_source_tax_rate_id nulls first;

 CURSOR get_funcl_curr_info_csr (c_ledger_id ZX_LINES.LEDGER_ID%TYPE) IS
  SELECT cur.currency_code
    FROM fnd_currencies cur, gl_sets_of_books sob
   WHERE sob.set_of_books_id = c_ledger_id
     AND cur.currency_code = sob.currency_code;

 l_funcl_curr_code FND_CURRENCIES.CURRENCY_CODE%TYPE;
 l_error_buffer VARCHAR2(240);

BEGIN

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines(+)');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  -- Initialize p_tax_line_tbl
  p_tax_line_tbl.delete;
  detail_ctr := 1;

  IF (nvl(p_event_class_rec.Quote_Flag,'N') = 'N') THEN
    OPEN fetch_tax_lines_csr;
    LOOP
      FETCH fetch_tax_lines_csr into p_tax_line_tbl(detail_ctr);
      EXIT when fetch_tax_lines_csr%notfound;

      OPEN  get_funcl_curr_info_csr(p_tax_line_tbl(detail_ctr).ledger_id);
      FETCH get_funcl_curr_info_csr into l_funcl_curr_code;

      IF get_funcl_curr_info_csr%NOTFOUND THEN
        x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
        IF (g_level_procedure >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines',
                   'No data found for the specified ledger_id');
        END IF;
      END IF;

      CLOSE get_funcl_curr_info_csr;

      IF p_tax_line_tbl(detail_ctr).trx_currency_code <> nvl(l_funcl_curr_code,'$$$')
         AND (p_tax_line_tbl(detail_ctr).tax_amt_funcl_curr is NULL
                OR p_tax_line_tbl(detail_ctr).taxable_amt_funcl_curr is NULL) THEN

        x_return_status := FND_API.G_RET_STS_ERROR;

        FND_MESSAGE.SET_NAME('ZX','ZX_ROUND_NO_EXCH_RATE');
        FND_MESSAGE.SET_TOKEN('FROM_CURRENCY', p_tax_line_tbl(detail_ctr).trx_currency_code);
        FND_MESSAGE.SET_TOKEN('TO_CURRENCY', nvl(l_funcl_curr_code,'$$$'));
        FND_MESSAGE.SET_TOKEN('CURRENCY_CONV_DATE', p_tax_line_tbl(detail_ctr).currency_conversion_date);

        ZX_API_PUB.add_msg(ZX_TDS_CALC_SERVICES_PUB_PKG.g_msg_context_info_rec);
        return;
      END IF;

      detail_ctr := detail_ctr + 1;
    END LOOP;
    CLOSE fetch_tax_lines_csr;

  ELSE
    OPEN fetch_tax_lines_gt_csr;
    LOOP
      FETCH fetch_tax_lines_gt_csr into p_tax_line_tbl(detail_ctr);
      EXIT when fetch_tax_lines_gt_csr%notfound;
      detail_ctr := detail_ctr + 1;
    END LOOP;
    CLOSE fetch_tax_lines_gt_csr;

  END IF;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines',
                   TO_CHAR(detail_ctr)||' tax line[s] fetched');
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines.END',
                   'ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines(-)'||x_return_status);
  END IF;

  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

      IF (g_level_unexpected >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
        FND_LOG.STRING(g_level_unexpected,
        'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines.END',
        'ZX_TRD_SERVICES_PUB_PKG.fetch_tax_lines(-)');
      END IF;

END fetch_tax_lines;

/* ======================================================================*
 |  PRIVATE PROCEDURE  fetch_tax_distributions                           |
 |                                                                       |
 |  This procedure is used to fetch all the tax distributions from       |
 |  ZX_REC_NREC_DIST table to the PL/SQL table p_rec_nrec_dist_tbl       |
 |                                                                       |
 * ======================================================================*/

PROCEDURE fetch_tax_distributions(
  p_event_class_rec            IN             ZX_API_PUB.EVENT_CLASS_REC_TYPE,
  p_tax_line_id                IN             NUMBER,
  p_trx_line_dist_id           IN             NUMBER,
  p_rec_nrec_dist_tbl          IN OUT NOCOPY  rec_nrec_dist_tbl_type,
  p_rec_nrec_dist_begin_index  IN             NUMBER,
  p_rec_nrec_dist_end_index      OUT NOCOPY   NUMBER,
  x_return_status                OUT NOCOPY   VARCHAR2) IS

  CURSOR fetch_tax_distributions_csr IS
   SELECT * FROM zx_rec_nrec_dist
    WHERE trx_id = p_event_class_rec.trx_id
      AND application_id = p_event_class_rec.application_id
      AND entity_code = p_event_class_rec.entity_code
      AND event_class_code = p_event_class_rec.event_class_code
      AND tax_line_id = p_tax_line_id
      AND trx_line_dist_id = p_trx_line_dist_id
      AND nvl(Reverse_Flag,'N') = 'N';

  i	NUMBER;

BEGIN

  IF (g_level_procedure>= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions(+)'||
                   ' tax_line_id = ' || p_tax_line_id||
                   ' trx_line_dist_id = ' || p_trx_line_dist_id);

  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  -- Initialize p_tax_line_tbl
  -- p_rec_nrec_dist_tbl.delete;

  i := p_rec_nrec_dist_begin_index;
  OPEN fetch_tax_distributions_csr;
  FETCH fetch_tax_distributions_csr INTO p_rec_nrec_dist_tbl(i);

  IF fetch_tax_distributions_csr%NOTFOUND THEN
    -- there is no tax distribution for the tax line and item dist, error out
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    CLOSE fetch_tax_distributions_csr;
    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions.END',
                     'ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions(-)'||' unexpected: No tax dist');
    END IF;
    RETURN;
  END IF;

  LOOP
    EXIT WHEN fetch_tax_distributions_csr%NOTFOUND;
    i := i + 1;
    FETCH fetch_tax_distributions_csr INTO p_rec_nrec_dist_tbl(i);
  END LOOP;

  --p_rec_nrec_dist_end_index := fetch_tax_distributions_csr%ROWCOUNT + p_rec_nrec_dist_begin_index - 1;
  p_rec_nrec_dist_end_index := p_rec_nrec_dist_tbl.COUNT;

  CLOSE fetch_tax_distributions_csr;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions.END',
                   'ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions(-)'||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
      FND_LOG.STRING(g_level_unexpected,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions.END',
                   'ZX_TRD_SERVICES_PUB_PKG.fetch_tax_distributions(-)');
    END IF;

END fetch_tax_distributions;

/* ======================================================================*
 |  PRIVATE PROCEDURE  populate_trx_line_info                            |
 |                                                                       |
 |  This procedure is used to populate the trx line information from the |
 |  to the tax line table to the global PL/SQL table                     |
 |  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL                           |
 |                                                                       |
 * ======================================================================*/

 PROCEDURE populate_trx_line_info(
  p_tax_line_tbl    IN             tax_line_tbl_type,
  p_index           IN             NUMBER,
  x_return_status      OUT NOCOPY  VARCHAR2) IS

 CURSOR  get_trx_info_csr IS
  SELECT internal_organization_id,
         trx_line_id,
         trx_level_type,
         trx_date,
         ledger_id,
         trx_currency_code,
         currency_conversion_date,
         currency_conversion_rate,
         currency_conversion_type,
         minimum_accountable_unit,
         precision,
         trx_shipping_date,
         trx_receipt_date,
         legal_entity_id,
         establishment_id,
         trx_line_number,
         trx_line_date,
         trx_business_category,
         line_intended_use,
         user_defined_fisc_class,
         line_amt,
         trx_line_quantity,
         unit_price,
         exempt_certificate_number,
         exempt_reason,
         cash_discount,
         volume_discount,
         trading_discount,
         transfer_charge,
         transportation_charge,
         insurance_charge,
         other_charge,
         product_id,
         product_fisc_classification,
         product_org_id,
         uom_code,
         product_type,
         product_code,
         product_category,
         account_ccid,
         account_string,
         total_inc_tax_amt,
         ship_to_location_id,
         ship_from_location_id,
         bill_to_location_id,
         bill_from_location_id,
         default_taxation_country,
         -- Start : Added columns for Bug#7008557
         first_pty_org_id,
         rdng_ship_to_pty_tx_prof_id,
         rdng_ship_from_pty_tx_prof_id,
         rdng_bill_to_pty_tx_prof_id,
         rdng_bill_from_pty_tx_prof_id,
         rdng_ship_to_pty_tx_p_st_id,
         rdng_ship_from_pty_tx_p_st_id,
         rdng_bill_to_pty_tx_p_st_id,
         rdng_bill_from_pty_tx_p_st_id,
         ship_to_party_tax_prof_id,
         ship_from_party_tax_prof_id,
         bill_to_party_tax_prof_id,
         bill_from_party_tax_prof_id,
         ship_to_site_tax_prof_id,
         ship_from_site_tax_prof_id,
         bill_to_site_tax_prof_id,
         bill_from_site_tax_prof_id,
         ship_third_pty_acct_id,
         bill_third_pty_acct_id,
         document_sub_type,
         -- End : Added columns for Bug#7008557
         line_class, -- Added for Bug#19933177
         tax_reporting_flag,
         input_tax_classification_code,
         output_tax_classification_code,
         hq_estb_party_tax_prof_id
    FROM zx_lines_det_factors
   WHERE application_id = p_tax_line_tbl(p_index).application_id
     AND entity_code = p_tax_line_tbl(p_index).entity_code
     AND event_class_code = p_tax_line_tbl(p_index).event_class_code
     AND trx_id = p_tax_line_tbl(p_index).trx_id
     AND trx_line_id = p_tax_line_tbl(p_index).trx_line_id
     AND trx_level_type = p_tax_line_tbl(p_index).trx_level_type;

l_index           NUMBER := 1;
l_count           NUMBER;
l_tbl_index       VARCHAR2(150);

BEGIN

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_trx_line_info.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.populate_trx_line_info(+)');
  END IF;

  x_return_status := FND_API.G_RET_STS_SUCCESS;
  l_index    := 1;

  OPEN  get_trx_info_csr;
  FETCH get_trx_info_csr INTO
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.internal_organization_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_line_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_level_type(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_date(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ledger_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_currency_code(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.currency_conversion_date(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.currency_conversion_rate(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.currency_conversion_type(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.minimum_accountable_unit(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.precision(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_shipping_date(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_receipt_date(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.legal_entity_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.establishment_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_line_number(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_line_date(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_business_category(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_Tbl.line_intended_use(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.user_defined_fisc_class(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.line_amt(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trx_line_quantity(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.unit_price(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.exempt_certificate_number(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.exempt_reason(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.cash_discount(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.volume_discount(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.trading_discount(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.transfer_charge(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.transportation_charge(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.insurance_charge(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.other_charge(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.product_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.product_fisc_classification(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.product_org_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.uom_code(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.product_type(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.product_code(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.product_category(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.account_ccid(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.account_string(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.total_inc_tax_amt(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_location_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_location_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.bill_to_location_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.bill_from_location_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.default_taxation_country(l_index),
        -- Start : Added code for Bug#7008557
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.first_pty_org_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.rdng_ship_to_pty_tx_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.rdng_ship_from_pty_tx_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.rdng_bill_to_pty_tx_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.rdng_bill_from_pty_tx_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.rdng_ship_to_pty_tx_p_st_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.rdng_ship_from_pty_tx_p_st_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.rdng_bill_to_pty_tx_p_st_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.rdng_bill_from_pty_tx_p_st_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_tax_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_tax_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.bill_to_party_tax_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.bill_from_party_tax_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_site_tax_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_site_tax_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.bill_to_site_tax_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.bill_from_site_tax_prof_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_third_pty_acct_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.bill_third_pty_acct_id(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.document_sub_type(l_index),
        -- End : Added code for Bug#7008557

        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.line_class(l_index),  -- Added for Bug#19933177
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.tax_reporting_flag(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.input_tax_classification_code(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.output_tax_classification_code(l_index),
        ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.hq_estb_party_tax_prof_id(l_index);

        l_count := ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.internal_organization_id.COUNT;

        FOR rec IN 1 .. l_count LOOP

          IF ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_tax_prof_id(rec) IS NOT NULL
          THEN
            l_tbl_index := TO_CHAR(ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_tax_prof_id(rec));
            IF l_party_tbl.EXISTS(l_tbl_index) AND
               l_party_tbl(l_tbl_index).party_tax_profile_id = ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_tax_prof_id(rec)
            THEN
              ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_id(rec) :=
                       l_party_tbl(l_tbl_index).party_id;
            ELSE
              SELECT party_id
              INTO ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_id(rec)
              FROM zx_party_tax_profile
              WHERE party_tax_profile_id = ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_tax_prof_id(rec);

              l_party_tbl(l_tbl_index).party_id := ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_id(rec);
              l_party_tbl(l_tbl_index).party_tax_profile_id := ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_tax_prof_id(rec);

            END IF;
          ELSE
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_from_party_id(rec) := NULL;
          END IF;

          IF ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_tax_prof_id(rec) IS NOT NULL
          THEN

            l_tbl_index := TO_CHAR(ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_tax_prof_id(rec));
            IF l_party_tbl.EXISTS(l_tbl_index) AND
               l_party_tbl(l_tbl_index).party_tax_profile_id = ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_tax_prof_id(rec)
            THEN
              ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec) :=
                       l_party_tbl(l_tbl_index).party_id;
            ELSE
               -- Bug#20741824 --
              /*SELECT party_id
              INTO ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec)
              FROM zx_party_tax_profile
              WHERE party_tax_profile_id = ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_tax_prof_id(rec);
              */

           IF p_tax_line_tbl(p_index).application_id = 201 THEN
                BEGIN
                  select ship_to_party_id
                  into ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec)
                  from zx_transaction_lines_gt
                  where application_id = p_tax_line_tbl(p_index).application_id
                  AND entity_code = p_tax_line_tbl(p_index).entity_code
                  AND event_class_code = p_tax_line_tbl(p_index).event_class_code
                  AND trx_id = p_tax_line_tbl(p_index).trx_id
                  AND trx_line_id = p_tax_line_tbl(p_index).trx_line_id;
                EXCEPTION WHEN OTHERS THEN
                  ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec) := null;
                END;
              ELSIF p_tax_line_tbl(p_index).application_id = 200 THEN
                BEGIN
                  select poll.ship_to_organization_id
                  into ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec)
                  from po_line_locations_all poll,
                       zx_itm_distributions_gt dist
                  where application_id = p_tax_line_tbl(p_index).application_id
                  AND entity_code = p_tax_line_tbl(p_index).entity_code
                  AND event_class_code = p_tax_line_tbl(p_index).event_class_code
                  AND trx_id = p_tax_line_tbl(p_index).trx_id
                  AND trx_line_id = p_tax_line_tbl(p_index).trx_line_id
                  AND dist.ref_doc_line_id = poll.line_location_id
                  AND rownum = 1;
                EXCEPTION WHEN OTHERS THEN
                  BEGIN
                    SELECT rel.entity_id
                    INTO ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec)
                    FROM  xle_tax_associations  rel
                       ,zx_party_tax_profile ptp
                       ,xle_etb_profiles etb
                    WHERE rel.legal_construct_id = etb.establishment_id
                    AND   etb.party_id   = ptp.party_id
                    AND   rel.legal_party_id   = ptp.party_id
                    and   ptp.party_tax_profile_id = ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_tax_prof_id(rec)
                    AND   rel.LEGAL_CONSTRUCT   = 'ESTABLISHMENT'
                    AND   rel.entity_type       = 'INVENTORY_ORGANIZATION'
                    AND   rel.context           = 'TAX_CALCULATION'
                    AND   rel.effective_from <= sysdate
                    AND   nvl(rel.effective_to,sysdate+1) >= sysdate;
                  EXCEPTION
                    WHEN OTHERS THEN
                      ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec) := null;
                  END;
                END;
              ELSE
                BEGIN
                  SELECT rel.entity_id
                  INTO ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec)
                  FROM  xle_tax_associations  rel
                     ,zx_party_tax_profile ptp
                     ,xle_etb_profiles etb
                  WHERE rel.legal_construct_id = etb.establishment_id
                  AND   etb.party_id   = ptp.party_id
                  AND   rel.legal_party_id   = ptp.party_id
                  and   ptp.party_tax_profile_id = ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_tax_prof_id(rec)
                  AND   rel.LEGAL_CONSTRUCT   = 'ESTABLISHMENT'
                  AND   rel.entity_type       = 'INVENTORY_ORGANIZATION'
                  AND   rel.context           = 'TAX_CALCULATION'
                  AND   rel.effective_from <= sysdate
                  AND   nvl(rel.effective_to,sysdate+1) >= sysdate;
                EXCEPTION
                  WHEN OTHERS THEN
                    ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec) := null;
                END;
              END IF;


              l_party_tbl(l_tbl_index).party_id := ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec);
              l_party_tbl(l_tbl_index).party_tax_profile_id := ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_tax_prof_id(rec);

            END IF;
          ELSE
            ZX_GLOBAL_STRUCTURES_PKG.TRX_LINE_DIST_TBL.ship_to_party_id(rec) := NULL;
          END IF;

       END LOOP;

  IF get_trx_info_csr%NOTFOUND THEN
     IF (g_level_statement >= g_current_runtime_level ) THEN
       FND_LOG.STRING(g_level_statement,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_trx_line_info',
      'NO DATA found in zx_lines_det_factors for trx line'||
      p_tax_line_tbl(p_index).trx_line_id);
       END IF;
  END IF;
  CLOSE get_trx_info_csr;

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_trx_line_info.END',
                   'ZX_TRD_SERVICES_PUB_PKG.populate_trx_line_info(-)'||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_trx_line_info',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
      FND_LOG.STRING(g_level_unexpected,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_trx_line_info.END',
                   'ZX_TRD_SERVICES_PUB_PKG.populate_trx_line_info(-)');
  END IF;

END populate_trx_line_info;

/* ============================================================================*
 |  PRIVATE PROCEDURE  insert_global_table                                     |
 |                                                                             |
 |  DESCRIPTION                                                                |
 |  This procedure is used to insert rec/non-rec tax distributions from the    |
 |  PL/SQL table to the global tempoarary table zx_rec_nrec_dist_gt when there |
 |  are more than 1000 records in the PL/SQL table                             |
 |                                                                             |
 * ============================================================================*/

PROCEDURE insert_global_table(
  p_rec_nrec_dist_tbl          IN OUT NOCOPY  rec_nrec_dist_tbl_type,
  p_rec_nrec_dist_begin_index  IN OUT NOCOPY  NUMBER,
  p_rec_nrec_dist_end_index    IN OUT NOCOPY  NUMBER,
  x_return_status                 OUT NOCOPY  VARCHAR2) IS

BEGIN

  IF (g_level_procedure >= g_current_runtime_level ) THEN
     FND_LOG.STRING(g_level_procedure,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_global_table.BEGIN',
                    'ZX_TRD_SERVICES_PUB_PKG.insert_global_table(+)');
  END IF;

   x_return_status:= FND_API.G_RET_STS_SUCCESS;

  IF p_rec_nrec_dist_tbl.count > 1000 THEN

          -- insert into global temporary table when there are more than 1000 tax distributions.


    -- populate mandatory columns before inserting.
    populate_mandatory_columns(p_rec_nrec_dist_tbl, x_return_status);

      IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN

                        IF (g_level_statement >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_statement,
                                         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_global_table',
                                         'After calling populate_mandatory_columns x_return_status = '
                                         || x_return_status);
          FND_LOG.STRING(g_level_statement,
                                         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_global_table.END',
                                         'ZX_TRD_SERVICES_PUB_PKG.insert_global_table(-)');
                        END IF;
           RETURN;

      END IF;


          FORALL ctr IN NVL(p_rec_nrec_dist_tbl.FIRST,0) .. NVL(p_rec_nrec_dist_tbl.LAST,-1)
            INSERT INTO zx_rec_nrec_dist_gt VALUES p_rec_nrec_dist_tbl(ctr);

    -- reinitialize the PL/SQL table.
      p_rec_nrec_dist_tbl.delete;
      p_rec_nrec_dist_end_index   := 0;
      p_rec_nrec_dist_begin_index   := 1;

  END IF;

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_global_table.END',
                   'ZX_TRD_SERVICES_PUB_PKG.insert_global_table(-)'||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_global_table',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
      FND_LOG.STRING(g_level_unexpected,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.insert_global_table.END',
                   'ZX_TRD_SERVICES_PUB_PKG.insert_global_table(-)');
  END IF;


END insert_global_table;

/* ========================================================================*
 |  PRIVATE PROCEDURE  populate_mandatory_columns                          |
 |                                                                         |
 |  DESCRIPTION                                                            |
 |  This procedure is used to populate mandatory columns into PL/SQL table |
 |                                                                         |
 * ========================================================================*/

PROCEDURE populate_mandatory_columns(
  p_rec_nrec_dist_tbl     IN OUT NOCOPY   REC_NREC_DIST_TBL_TYPE,
  x_return_status            OUT NOCOPY   VARCHAR2)

IS

i      NUMBER;

BEGIN

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns.BEGIN',
                   'populate_mandatory_columns(+)');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  IF p_rec_nrec_dist_tbl.count <> 0 THEN

    FOR i IN NVL(p_rec_nrec_dist_tbl.FIRST,0) .. NVL(p_rec_nrec_dist_tbl.LAST,-1)
    LOOP
      --
      -- populate rec_nrec_tax_dist_id if it is null
      --
      IF p_rec_nrec_dist_tbl(i).rec_nrec_tax_dist_id IS NULL THEN

        -- get g_tax_dist_id
        --
        SELECT ZX_REC_NREC_DIST_S.nextval
        INTO   ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id
        FROM   dual;

        p_rec_nrec_dist_tbl(i).rec_nrec_tax_dist_id :=
                                            ZX_TRD_SERVICES_PUB_PKG.g_tax_dist_id;

      END IF;

      -- populate the object_version_number
      p_rec_nrec_dist_tbl(i).object_version_number
        := NVL(p_rec_nrec_dist_tbl(i).object_version_number, 1);

    -- populate who columns if it is null

    IF p_rec_nrec_dist_tbl(i).created_by IS NULL THEN

         p_rec_nrec_dist_tbl(i).created_by      := fnd_global.user_id;

    END IF;

    IF p_rec_nrec_dist_tbl(i).creation_date IS NULL THEN
        p_rec_nrec_dist_tbl(i).creation_date   := sysdate;
    END IF;

    p_rec_nrec_dist_tbl(i).last_updated_by   := fnd_global.user_id;
    p_rec_nrec_dist_tbl(i).last_update_login := fnd_global.login_id;
    p_rec_nrec_dist_tbl(i).last_update_date  := sysdate;

        -- populate mrc flag if it is null

        IF p_rec_nrec_dist_tbl(i).mrc_tax_dist_flag IS NULL THEN
          p_rec_nrec_dist_tbl(i).mrc_tax_dist_flag := 'N';
        END IF;

  IF p_rec_nrec_dist_tbl(i).REC_NREC_TAX_DIST_NUMBER IS NULL THEN

                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;     -- bug 4893261

                IF (g_level_procedure >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_procedure,
                                 'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns',
                                 'error: tax dist number is null ');

          FND_LOG.STRING(g_level_procedure,
                                 'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns.END',
                                 'populate_mandatory_columns(-)');
                END IF;
    RETURN;

  END IF;

  IF p_rec_nrec_dist_tbl(i).REC_NREC_RATE IS NULL THEN
                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

                IF (g_level_procedure >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_procedure,
                                 'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns',
                                 'error: rec nrec rate is null ');

          FND_LOG.STRING(g_level_procedure,
                                 'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns.END',
                                 'populate_mandatory_columns(-)');
                END IF;
    RETURN;

  END IF;

  IF p_rec_nrec_dist_tbl(i).Recoverable_Flag IS NULL THEN

                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
                IF (g_level_procedure >= g_current_runtime_level ) THEN

          FND_LOG.STRING(g_level_procedure,
                                 'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns',
                                 'error: RECOVERABLE FLG is null ');
             FND_LOG.STRING(g_level_procedure,
                                 'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns.END',
                                 'populate_mandatory_columns(-)');
                END IF;
    RETURN;

  END IF;

  IF p_rec_nrec_dist_tbl(i).REC_NREC_TAX_AMT IS NULL THEN

                x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

                IF (g_level_procedure >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_procedure,
                                 'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns',
                                 'error: tax dist amount is null ');
          FND_LOG.STRING(g_level_procedure,
                                 'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns.END',
                                 'populate_mandatory_columns(-)');
                END IF;
    RETURN;

  END IF;


  END LOOP;

  else

    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns',
                     'No record in p_rec_nrec_dist_tbl ... ');
    END IF;

  end if;

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns.END',
                   'ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns(-)'||x_return_status);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                     'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns',
                      sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
      FND_LOG.STRING(g_level_unexpected,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns.END',
                   'ZX_TRD_SERVICES_PUB_PKG.populate_mandatory_columns(-)');
  END IF;

END populate_mandatory_columns;


PROCEDURE update_exchange_rate (
  p_event_class_rec        IN          ZX_API_PUB.EVENT_CLASS_REC_TYPE,
  p_ledger_id      IN          NUMBER,
  p_currency_conversion_rate    IN          NUMBER,
  p_currency_conversion_type    IN          VARCHAR2,
  p_currency_conversion_date    IN          DATE,
  x_return_status          OUT NOCOPY  VARCHAR2 ) IS

 CURSOR  get_rec_nrec_tax_dists_csr IS
  SELECT rec_nrec_tax_dist_id,
         tax_line_id,
         recoverable_flag,
         rec_nrec_tax_amt,
         taxable_amt,
         rec_nrec_tax_amt_funcl_curr,
         taxable_amt_funcl_curr,
         unrounded_rec_nrec_tax_amt,
         unrounded_taxable_amt,
         NVL(p_ledger_id, ledger_id) ledger_id,
         trx_currency_code,
         tax_rate,
         0
    FROM zx_rec_nrec_dist
   WHERE application_id = p_event_class_rec.application_id
     AND entity_code = p_event_class_rec.entity_code
     AND event_class_code  = p_event_class_rec.event_class_code
     AND trx_id = p_event_class_rec.trx_id
     AND NVL(Reverse_Flag, 'N') = 'N'
     AND NVL(mrc_tax_dist_flag, 'N') = 'N'
   ORDER BY tax_line_id, unrounded_rec_nrec_tax_amt DESC;

 CURSOR  get_tax_line_amt_csr(p_tax_line_id   NUMBER) IS
  SELECT tax_amt_funcl_curr
    FROM zx_lines
   WHERE tax_line_id = p_tax_line_id;

 CURSOR  get_mau_info_csr IS
  SELECT nvl( cur.minimum_accountable_unit, power( 10, (-1 * precision))),
         cur.currency_code
    FROM fnd_currencies cur, gl_sets_of_books sob
   WHERE sob.set_of_books_id = p_ledger_id
     AND cur.currency_code = sob.currency_code;

 TYPE rec_nrec_tax_dist_id_tbl_type IS TABLE OF
       zx_rec_nrec_dist.rec_nrec_tax_dist_id%TYPE INDEX BY BINARY_INTEGER;

 TYPE tax_line_id_tbl_type IS TABLE OF zx_rec_nrec_dist.tax_line_id%TYPE
       INDEX BY BINARY_INTEGER;

 TYPE recoverable_flg_tbl_type IS TABLE OF
       zx_rec_nrec_dist.Recoverable_Flag%TYPE INDEX BY BINARY_INTEGER;

 TYPE rec_nrec_tax_amt_tbl_type  IS TABLE OF
       zx_rec_nrec_dist.rec_nrec_tax_amt%TYPE INDEX BY BINARY_INTEGER;

 TYPE taxable_amt_tbl_type  IS TABLE OF zx_rec_nrec_dist.taxable_amt%TYPE
       INDEX BY BINARY_INTEGER;

 TYPE tax_amt_funcl_curr_tbl_type  IS TABLE OF
       zx_rec_nrec_dist.rec_nrec_tax_amt_funcl_curr%TYPE INDEX BY BINARY_INTEGER;

 TYPE txable_amt_funcl_curr_tbl_type  IS TABLE OF
       zx_rec_nrec_dist.taxable_amt_funcl_curr%TYPE  INDEX BY BINARY_INTEGER;

 TYPE unrounded_tax_amt_tbl_type IS TABLE OF
       zx_rec_nrec_dist.unrounded_rec_nrec_tax_amt%TYPE  INDEX BY BINARY_INTEGER;

 TYPE unrounded_taxable_amt_tbl_type IS TABLE OF
       zx_rec_nrec_dist.unrounded_taxable_amt%TYPE  INDEX BY BINARY_INTEGER;

 TYPE ledger_id_tbl_type  IS TABLE OF zx_rec_nrec_dist.ledger_id%TYPE
       INDEX BY BINARY_INTEGER;

 TYPE trx_currency_code_tbl_type IS TABLE OF zx_rec_nrec_dist.trx_currency_code%TYPE
       INDEX BY BINARY_INTEGER;

 TYPE rec_nrec_rate_tbl_type IS TABLE OF zx_rec_nrec_dist.rec_nrec_rate%TYPE
       INDEX BY BINARY_INTEGER;
 TYPE func_curr_rnd_adjust_tbl_type IS TABLE OF
      zx_rec_nrec_dist.func_curr_rounding_adjustment%TYPE INDEX BY BINARY_INTEGER;

 l_rec_nrec_tax_dist_id_tbl            rec_nrec_tax_dist_id_tbl_type;
 l_tax_line_id_tbl                     tax_line_id_tbl_type;
 l_recoverable_flg_tbl                 recoverable_flg_tbl_type;
 l_rec_nrec_tax_amt_tbl                rec_nrec_tax_amt_tbl_type;
 l_taxable_amt_tbl                     taxable_amt_tbl_type;
 l_tax_amt_funcl_curr_tbl              tax_amt_funcl_curr_tbl_type;
 l_taxable_amt_funcl_curr_tbl          txable_amt_funcl_curr_tbl_type;
 l_unrounded_tax_amt_tbl               unrounded_tax_amt_tbl_type;
 l_unrounded_taxable_amt_tbl           unrounded_taxable_amt_tbl_type;
 l_ledger_id_tbl                       ledger_id_tbl_type;
 l_trx_currency_code_tbl               trx_currency_code_tbl_type;
 l_rec_nrec_rate_tbl           rec_nrec_rate_tbl_type;
 l_func_curr_rnd_adjustment_tbl        func_curr_rnd_adjust_tbl_type;

 TYPE index_info_tbl_type IS TABLE OF NUMBER  INDEX BY BINARY_INTEGER;

 l_non_zero_rec_tax_lines_tbl         index_info_tbl_type;
 l_non_zero_nrec_tax_lines_tbl         index_info_tbl_type;

 l_num_of_min_units          NUMBER;
 l_num_of_multiples          NUMBER;
 l_remainder                          NUMBER;
 l_index                              NUMBER;

 l_non_zero_rec_tax_line_index        NUMBER;
 l_non_zero_nrec_tax_line_index        NUMBER;

 l_error_buffer            VARCHAR2(200);

 l_sum_of_rnd_rec_tax_amt          NUMBER;
 l_sum_of_rnd_nrec_tax_amt            NUMBER;

 l_total_unrounded_rec_tax_amt        NUMBER;
 l_total_unrounded_nrec_tax_amt       NUMBER;
 l_rnd_total_rec_tax_amt          NUMBER;
 l_rnd_total_nrec_tax_amt          NUMBER;
 l_total_tax_line_amt          NUMBER;

 l_rec_tax_rounding_diff        NUMBER;
 l_nrec_tax_rounding_diff        NUMBER;

 l_tax_line_rounding_diff        NUMBER;

 l_current_tax_line_id                zx_rec_nrec_dist.tax_line_id%TYPE;
 l_rec_begin_index          NUMBER;
 l_nrec_begin_index          NUMBER;

 l_minimum_accountable_unit        NUMBER;
 l_funcl_currency_code               fnd_currencies.currency_code%TYPE;

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
             'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate.BEGIN',
             'ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate(+)');
  END IF;

  x_return_status :=  FND_API.G_RET_STS_SUCCESS;

  OPEN get_rec_nrec_tax_dists_csr;

    FETCH  get_rec_nrec_tax_dists_csr BULK COLLECT  INTO
           l_rec_nrec_tax_dist_id_tbl,
           l_tax_line_id_tbl,
           l_recoverable_flg_tbl,
           l_rec_nrec_tax_amt_tbl,
           l_taxable_amt_tbl,
           l_tax_amt_funcl_curr_tbl,
           l_taxable_amt_funcl_curr_tbl,
           l_unrounded_tax_amt_tbl,
           l_unrounded_taxable_amt_tbl,
           l_ledger_id_tbl,
           l_trx_currency_code_tbl,
           l_rec_nrec_rate_tbl,
           l_func_curr_rnd_adjustment_tbl;

  CLOSE get_rec_nrec_tax_dists_csr;

  IF l_rec_nrec_tax_dist_id_tbl.FIRST IS NULL THEN

    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
              'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate',
              'No tax distributions are fetched from ZX_REC_NREC_DIST.');
    END IF;
    RETURN;
  ELSE

    -- Initialize l_current_tax_line_id to tax_line_id of the first record
    --
    l_current_tax_line_id := l_tax_line_id_tbl(l_rec_nrec_tax_dist_id_tbl.FIRST);

    -- Initialize plsql tables and local variables
    --
    l_non_zero_rec_tax_lines_tbl.DELETE;
    l_non_zero_nrec_tax_lines_tbl.DELETE;

    l_non_zero_rec_tax_line_index := 0;
    l_non_zero_nrec_tax_line_index := 0;

    l_sum_of_rnd_rec_tax_amt := 0;
    l_sum_of_rnd_nrec_tax_amt := 0;

    l_total_unrounded_rec_tax_amt := 0;
    l_total_unrounded_nrec_tax_amt := 0;
    l_rnd_total_rec_tax_amt := 0;
    l_rnd_total_nrec_tax_amt := 0;

    l_total_tax_line_amt := 0;

  END IF;

  -- get the l_minimum_accountable_unit
  --
  OPEN  get_mau_info_csr;
  FETCH get_mau_info_csr INTO
        l_minimum_accountable_unit, l_funcl_currency_code;
  CLOSE get_mau_info_csr;

  IF (g_level_statement >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_statement,
             'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate',
             'l_minimum_accountable_unit = ' || l_minimum_accountable_unit);
  END IF;

  -- loop through the table of l_rec_nrec_tax_dists_tbl
  --
  FOR i IN NVL(l_rec_nrec_tax_dist_id_tbl.FIRST,0).. NVL(l_rec_nrec_tax_dist_id_tbl.LAST,-1)
  LOOP

    -- If rec_nrec_tax_amt is zero, set rec_nrec_tax_amt_funcl_curr to zero.
    -- Otherwise, convert rec_nrec_tax_amt to functional currency.
    --
    IF l_rec_nrec_tax_amt_tbl(i) = 0 THEN

      l_tax_amt_funcl_curr_tbl(i) := 0;

    ELSE
      IF l_funcl_currency_code <> l_trx_currency_code_tbl(i) THEN
        -- convert tax amount to functional currency and
        -- perform rounding for rec_nrec_tax_amt_funcl_curr
        --
        l_tax_amt_funcl_curr_tbl(i) :=
        GL_CURRENCY_API.convert_amount (
                    x_set_of_books_id   => p_ledger_id,
                    x_from_currency     => l_trx_currency_code_tbl(i),
                    x_conversion_date   => p_currency_conversion_date,
                    x_conversion_type   => p_currency_conversion_type,
                    x_amount            => l_unrounded_tax_amt_tbl(i));
      ELSE
        l_tax_amt_funcl_curr_tbl(i) :=
          round(l_tax_amt_funcl_curr_tbl(i)/l_minimum_accountable_unit) *
            l_minimum_accountable_unit;
      END IF;

    END IF;

    IF (l_tax_line_id_tbl(i) = l_current_tax_line_id)
    THEN

      -- For tax line with the same tax_line_id, or for the first tax line:
      --
      -- 1. Accumulate the converted recoverable tax amount and
      --    non-recoverable tax amount separately.
      -- 2. Record the non-zero recoverable and non-recoverable tax
      --    distributions in separate plsql tables
      -- 3. Record the rounded-to-zero recoverable and non-recoverable
      --    tax distributions in separate plsql tables
      -- 4. Accumulate tax amount of unrounded recoverable tax distributions.
      --    (not converted).
      -- 5. Accumulate tax amount of unrounded non-recoverable distributions.
      --    (not converted).

      IF l_recoverable_flg_tbl(i) = 'N' THEN

        -- Accumulate tax amount of converted non-recoverable tax lines
        --
        l_sum_of_rnd_nrec_tax_amt := l_sum_of_rnd_nrec_tax_amt +
                                                   l_tax_amt_funcl_curr_tbl(i);

        -- Record the non-zero non-recoverable tax lines
        --
        IF (l_rec_nrec_tax_amt_tbl(i) <> 0) THEN

          l_non_zero_nrec_tax_line_index := l_non_zero_nrec_tax_line_index + 1;

          l_non_zero_nrec_tax_lines_tbl(l_non_zero_nrec_tax_line_index) := i;


        END IF;

        -- Accumulate unrounded non-recoverable tax amount(not converted)
        --
        l_total_unrounded_nrec_tax_amt :=  l_total_unrounded_nrec_tax_amt +
                                                    l_unrounded_tax_amt_tbl(i);


      ELSIF l_recoverable_flg_tbl(i) = 'Y' THEN

        -- Accumulate amount of converted recoverable tax lines
        --
        l_sum_of_rnd_rec_tax_amt := l_sum_of_rnd_rec_tax_amt +
                                                l_tax_amt_funcl_curr_tbl(i);

        -- Record the non-zero recoverable tax lines
        --
        IF l_rec_nrec_tax_amt_tbl(i) <> 0 THEN

          l_non_zero_rec_tax_line_index := l_non_zero_rec_tax_line_index + 1;

          l_non_zero_rec_tax_lines_tbl(l_non_zero_rec_tax_line_index) := i;


        END IF;

        -- Accumulate unrounded recoverable tax amount(not converted)
        --
        l_total_unrounded_rec_tax_amt :=  l_total_unrounded_rec_tax_amt +
                                                    l_unrounded_tax_amt_tbl(i);


      END IF;    -- l_recoverable_flg_tbl(i)

      IF ( i = l_rec_nrec_tax_dist_id_tbl.LAST OR
           l_current_tax_line_id <> l_tax_line_id_tbl(i+1)) THEN

        -- If this is the last tax line with the same tax_line_id:,
        --
        -- 1. Convert the unrounded accumulatve recoverable tax amount to
        --    functional currency and perform rounding.
        -- 2. Convert the unrounded accumulatve non-recoverable tax amount to
        --    functional currency and perform rounding.
        -- 3. Calculate rounding difference for recoverable tax.
        -- 4. Calculate rounding difference for non-recoverable tax.
        -- 5. If rounding difference exists, adjust it to recoverable or
        --    non-recoverable tax distribution repeecttively.
        -- 6. Get tax amount from zx_lines for this tax_line_id
        -- 7. Calculate rounding difference for all tax distributions with
        --    the same tax_line_id.
        -- 8. If rounding difference > 0, adjust it to the largest
        --    non_recoverable tax distribution. If rounding difference < 0,
        --    adjust it to the largest recoverable tax distribution.

        IF l_funcl_currency_code <> l_trx_currency_code_tbl(i) THEN

          -- convert accumulative unrounded recoverable tax amt to functional
          -- currency and perform rounding
          --
          l_rnd_total_rec_tax_amt :=
        GL_CURRENCY_API.convert_amount (
                    x_set_of_books_id   => p_ledger_id,
                    x_from_currency     => l_trx_currency_code_tbl(i),
                    x_conversion_date   => p_currency_conversion_date,
                    x_conversion_type   => p_currency_conversion_type,
                    x_amount            => l_total_unrounded_rec_tax_amt);

          -- convert accumulative unrounded non-recoverable tax amt to functional
          -- currency and perform rounding
          --
          l_rnd_total_nrec_tax_amt :=
        GL_CURRENCY_API.convert_amount (
                    x_set_of_books_id   => p_ledger_id,
                    x_from_currency     => l_trx_currency_code_tbl(i),
                    x_conversion_date   => p_currency_conversion_date,
                    x_conversion_type   => p_currency_conversion_type,
                    x_amount            => l_total_unrounded_nrec_tax_amt);

        ELSE
          -- round l_rnd_total_rec_tax_amt (recoverable tax dists)
          --
          l_rnd_total_rec_tax_amt :=
             round(l_rnd_total_rec_tax_amt/l_minimum_accountable_unit) *
                l_minimum_accountable_unit;

          -- round l_rnd_total_nrec_tax_amt (non-recoverable tax dists)
          --
          l_rnd_total_nrec_tax_amt :=
             round(l_rnd_total_nrec_tax_amt/l_minimum_accountable_unit) *
                l_minimum_accountable_unit;

        END IF;


        -- calculate rounding difference for recoverable and non-recoverable
        -- tax distributions
        --
        l_rec_tax_rounding_diff :=  l_rnd_total_rec_tax_amt -
                                                      l_sum_of_rnd_rec_tax_amt;
        l_nrec_tax_rounding_diff := l_rnd_total_nrec_tax_amt -
                                                     l_sum_of_rnd_nrec_tax_amt;

        -- Adjust rounding difference for recoverable tax distributions
        --
        IF l_rec_tax_rounding_diff <> 0 THEN

          l_num_of_min_units := ABS(TRUNC(l_rec_tax_rounding_diff/
                                          l_minimum_accountable_unit));


          IF l_non_zero_rec_tax_lines_tbl.COUNT > 0 THEN


            l_num_of_multiples := TRUNC(l_num_of_min_units/
                                      l_non_zero_rec_tax_lines_tbl.COUNT);
            l_remainder := MOD(l_num_of_min_units,
                             l_non_zero_rec_tax_lines_tbl.COUNT);

            IF l_num_of_multiples <> 0 THEN


              FOR j IN NVL(l_non_zero_rec_tax_lines_tbl.FIRST, 0)..
                       NVL(l_non_zero_rec_tax_lines_tbl.LAST, -1)
              LOOP

                l_index := l_non_zero_rec_tax_lines_tbl(j);

                l_tax_amt_funcl_curr_tbl(l_index) :=
                    l_tax_amt_funcl_curr_tbl(l_index) +
                       l_minimum_accountable_unit *
                        l_num_of_multiples * SIGN(l_rec_tax_rounding_diff);


              END LOOP;
            END IF;         -- l_num_of_multiples <> 0

            IF l_remainder <> 0 THEN


              FOR j IN 1 .. l_remainder LOOP

                l_index := l_non_zero_rec_tax_lines_tbl(j);

                l_tax_amt_funcl_curr_tbl(l_index) :=
                              l_tax_amt_funcl_curr_tbl(l_index) +
                                l_minimum_accountable_unit *
                                  SIGN(l_rec_tax_rounding_diff);


              END LOOP;
            END IF;        -- l_remainder <> 0

            -- Reset the value of l_sum_of_rnd_rec_tax_amt after adjustment
            --
            l_sum_of_rnd_rec_tax_amt := l_sum_of_rnd_rec_tax_amt +
                                                      l_rec_tax_rounding_diff;

          ELSIF l_non_zero_nrec_tax_lines_tbl.COUNT > 0 THEN



            l_num_of_multiples := TRUNC(l_num_of_min_units/
                                      l_non_zero_nrec_tax_lines_tbl.COUNT);
            l_remainder := MOD(l_num_of_min_units,
                             l_non_zero_nrec_tax_lines_tbl.COUNT);

            IF l_num_of_multiples <> 0 THEN



              FOR j IN NVL(l_non_zero_nrec_tax_lines_tbl.FIRST, 0) ..
                       NVL(l_non_zero_nrec_tax_lines_tbl.LAST, -1)
              LOOP

                l_index := l_non_zero_nrec_tax_lines_tbl(j);

                l_tax_amt_funcl_curr_tbl(l_index) :=
                    l_tax_amt_funcl_curr_tbl(l_index) +
                      l_minimum_accountable_unit *
                        l_num_of_multiples * SIGN(l_rec_tax_rounding_diff);


              END LOOP;

            END IF;      -- l_num_of_multiples <> 0

            IF l_remainder <> 0 THEN



              FOR j IN 1 .. l_remainder LOOP

                l_index := l_non_zero_nrec_tax_lines_tbl(j);

                l_tax_amt_funcl_curr_tbl(l_index) :=
                              l_tax_amt_funcl_curr_tbl(l_index) +
                                l_minimum_accountable_unit *
                                  SIGN(l_rec_tax_rounding_diff);



              END LOOP;

            END IF;        -- l_remainder <> 0

            -- Reset the value of l_sum_of_rnd_nrec_tax_amt after adjustment
            --
            l_sum_of_rnd_nrec_tax_amt := l_sum_of_rnd_nrec_tax_amt +
                                                       l_rec_tax_rounding_diff;

          END IF;          -- l_non_zero_rec(or nrec)_tax_lines_tbl.COUNT > 0

        END IF;            -- l_rec_tax_rounding_diff <> 0

        -- Adjust rounding difference for recoverable tax distributions
        --
        IF l_nrec_tax_rounding_diff <> 0 THEN

          l_num_of_min_units := ABS(TRUNC(l_nrec_tax_rounding_diff/
                                          l_minimum_accountable_unit));



          IF l_non_zero_nrec_tax_lines_tbl.COUNT > 0 THEN


            l_num_of_multiples := TRUNC(l_num_of_min_units/
                                      l_non_zero_nrec_tax_lines_tbl.COUNT);
            l_remainder := MOD(l_num_of_min_units,
                             l_non_zero_nrec_tax_lines_tbl.COUNT);

            IF l_num_of_multiples <> 0 THEN


              FOR j IN NVL(l_non_zero_nrec_tax_lines_tbl.FIRST, 0) ..
                       NVL(l_non_zero_nrec_tax_lines_tbl.LAST, -1)
              LOOP

                l_index := l_non_zero_nrec_tax_lines_tbl(j);

                l_tax_amt_funcl_curr_tbl(l_index) :=
                    l_tax_amt_funcl_curr_tbl(l_index) +
                      l_minimum_accountable_unit *
                        l_num_of_multiples * SIGN(l_nrec_tax_rounding_diff);



              END LOOP;

            END IF;      -- l_num_of_multiples <> 0

            IF l_remainder <> 0 THEN



              FOR j IN 1 .. l_remainder LOOP

                l_index := l_non_zero_nrec_tax_lines_tbl(j);

                l_tax_amt_funcl_curr_tbl(l_index) :=
                              l_tax_amt_funcl_curr_tbl(l_index) +
                                l_minimum_accountable_unit *
                                  SIGN(l_nrec_tax_rounding_diff);



              END LOOP;

            END IF;        --  l_remaunder <> 0

            -- Reset the value of l_sum_of_rnd_nrec_tax_amt after adjustment
            --
            l_sum_of_rnd_nrec_tax_amt := l_sum_of_rnd_nrec_tax_amt +
                                                       l_nrec_tax_rounding_diff;

          ELSIF l_non_zero_rec_tax_lines_tbl.COUNT > 0 THEN



            l_num_of_multiples := TRUNC(l_num_of_min_units/
                                      l_non_zero_rec_tax_lines_tbl.COUNT);
            l_remainder := MOD(l_num_of_min_units,
                             l_non_zero_rec_tax_lines_tbl.COUNT);

            IF l_num_of_multiples <> 0 THEN



              FOR j IN NVL(l_non_zero_rec_tax_lines_tbl.FIRST,0) ..
                       NVL(l_non_zero_rec_tax_lines_tbl.LAST,-1)
              LOOP

                l_index := l_non_zero_rec_tax_lines_tbl(j);

                l_tax_amt_funcl_curr_tbl(l_index) :=
                    l_tax_amt_funcl_curr_tbl(l_index) +
                      l_minimum_accountable_unit *
                        l_num_of_multiples * SIGN(l_nrec_tax_rounding_diff);



              END LOOP;

            END IF;    -- l_num_of_multiples <> 0

            IF l_remainder <> 0 THEN



              FOR j IN 1 .. l_remainder LOOP

                l_index := l_non_zero_rec_tax_lines_tbl(j);

                l_tax_amt_funcl_curr_tbl(l_index) :=
                              l_tax_amt_funcl_curr_tbl(l_index) +
                                l_minimum_accountable_unit *
                                  SIGN(l_nrec_tax_rounding_diff);



              END LOOP;

            END IF;        --  l_remaunder <> 0

            -- Reset the value of l_sum_of_rnd_nrec_tax_amt after adjustment
            --
            l_sum_of_rnd_rec_tax_amt := l_sum_of_rnd_rec_tax_amt +
                                                      l_nrec_tax_rounding_diff;

          END IF;    -- l_non_zero_nrec(or rec)_tax_lines_tbl.COUNT  <> 0

        END IF;      -- l_nrec_tax_rounding_diff <> 0

        -- check rounding difference between tax line in zx_lines and
        -- the tax distributions in zx_rec_nrec_tax_dist with the same
        -- tax_line_id.
        --
        -- get the tax_amt for this tax_line_id in zx_lines
        --
        OPEN  get_tax_line_amt_csr(l_tax_line_id_tbl(i));
        FETCH get_tax_line_amt_csr INTO l_total_tax_line_amt;
        CLOSE get_tax_line_amt_csr;



        -- calculate rounding difference for amount of tax line
        --
        l_tax_line_rounding_diff := l_total_tax_line_amt -
                (l_sum_of_rnd_rec_tax_amt + l_sum_of_rnd_nrec_tax_amt);



        IF l_tax_line_rounding_diff > 0 THEN

          -- Adjust this rounding difference to the largest non-zero
          -- non-recoverabletax distribution (check first), or adjust it to
          -- the largest non-zero recoverable tax distribution.
          --
          IF l_non_zero_nrec_tax_lines_tbl.COUNT > 0 THEN

            l_nrec_begin_index := l_non_zero_nrec_tax_lines_tbl.FIRST;

            l_tax_amt_funcl_curr_tbl(l_nrec_begin_index) :=
                   l_tax_amt_funcl_curr_tbl(l_nrec_begin_index) +
                                                     l_tax_line_rounding_diff;

            -- store rounding adjustment in functional currency
            --
            l_func_curr_rnd_adjustment_tbl(l_nrec_begin_index) :=
                                                        l_tax_line_rounding_diff;


          ELSIF l_non_zero_rec_tax_lines_tbl.COUNT > 0 THEN

            l_rec_begin_index := l_non_zero_rec_tax_lines_tbl.FIRST;

            l_tax_amt_funcl_curr_tbl(l_rec_begin_index) :=
                      l_tax_amt_funcl_curr_tbl(l_rec_begin_index) +
                                                   l_tax_line_rounding_diff;

            -- store rounding adjustment in functional currency
            --
            l_func_curr_rnd_adjustment_tbl(l_rec_begin_index) :=
                                                        l_tax_line_rounding_diff;



          END IF;

        ElSIF l_tax_line_rounding_diff < 0 THEN

          -- Adjust this rounding difference to the largest non-zero
          -- recoverabletax distribution (check first), or adjust it to
          -- the largest non-zero non-recoverable tax distribution.
          --
          IF l_non_zero_rec_tax_lines_tbl.COUNT > 0  THEN

            l_rec_begin_index := l_non_zero_rec_tax_lines_tbl.FIRST;

            l_tax_amt_funcl_curr_tbl(l_rec_begin_index) :=
                      l_tax_amt_funcl_curr_tbl(l_rec_begin_index) +
                                                      l_tax_line_rounding_diff;

            -- store rounding adjustment in functional currency
            --
            l_func_curr_rnd_adjustment_tbl(l_rec_begin_index) :=
                                                        l_tax_line_rounding_diff;



          ELSIF l_non_zero_nrec_tax_lines_tbl.COUNT > 0 THEN

            l_nrec_begin_index := l_non_zero_nrec_tax_lines_tbl.FIRST;

            l_tax_amt_funcl_curr_tbl(l_nrec_begin_index) :=
                      l_tax_amt_funcl_curr_tbl(l_nrec_begin_index) +
                                                      l_tax_line_rounding_diff;

            -- store rounding adjustment in functional currency
            --
            l_func_curr_rnd_adjustment_tbl(l_nrec_begin_index) :=
                                                        l_tax_line_rounding_diff;


          END IF;
        END IF;
      END IF;        -- end of the same tax_line_id
    ELSE             -- start of new tax_line_id

      -- For tax distribution with new tax_line_id and l_begin_index:
      -- Reset l_current_tax_line_id
      --

      l_current_tax_line_id := l_tax_line_id_tbl(i);



      -- If this tax distribution has a new tax_line_id, and it is the
      -- only tax distribution with this tax_line_id, no adjustment
      -- is needed because rounding difference will not exist.
      --

      -- If this tax distribution has a new tax_line_id and it is not the only
      -- tax distributions that has this tax_line_id, adjustment will be done
      -- when the last tax distribution with this current tax_line_id is
      -- processed, if rounding difference exists,.
      --

      IF (i = l_rec_nrec_tax_dist_id_tbl.LAST OR
          l_current_tax_line_id <> l_tax_line_id_tbl(i+1))
      THEN

        -- If a tax line has only one tax distribution, there should not
        -- be rounding difference between the tax_amt_funcl_curr of the tax
        -- line in zx_lines and rec_nrec_tax_amt_funcl_curr of the tax
        -- distributions in zx_rec_nrec_tax_dist with the same tax_line_id.
        -- They are all converted from the same unrounded_tax_amt.
        -- So, no action is required here.

        NULL;

      ELSE
        -- Tax distribution has new tax_line_id, but there are multiple tax
        -- tax distributions with the same tax_line_id.
        --


        -- Initialize the PLSQL tables and local variables if a tax line in
        -- zx_lines has multiple tax distributions in rec_nrec_tax_dist.
        --
        l_non_zero_rec_tax_lines_tbl.DELETE;
        l_non_zero_nrec_tax_lines_tbl.DELETE;

        l_non_zero_rec_tax_line_index := 0;
        l_non_zero_nrec_tax_line_index := 0;

        l_sum_of_rnd_rec_tax_amt := 0;
        l_sum_of_rnd_nrec_tax_amt := 0;

        l_total_unrounded_rec_tax_amt := 0;
        l_total_unrounded_nrec_tax_amt := 0;

        l_rnd_total_rec_tax_amt := 0;
        l_rnd_total_nrec_tax_amt := 0;
        l_total_tax_line_amt := 0;

        l_rec_tax_rounding_diff := 0;
        l_nrec_tax_rounding_diff := 0;

        -- For new tax_line_id, reset plsql tables and local variables
        --
        IF l_recoverable_flg_tbl(i) = 'N' THEN

          --  For non-recoverable tax line
          --
          l_sum_of_rnd_nrec_tax_amt := l_tax_amt_funcl_curr_tbl(i);
          l_total_unrounded_nrec_tax_amt :=  l_unrounded_tax_amt_tbl(i);
          l_total_unrounded_rec_tax_amt :=  0;

          IF (l_rec_nrec_tax_amt_tbl(i) <> 0) THEN

            -- Record this rnon-zero non-recoverable tax lines
            --
            l_non_zero_nrec_tax_line_index := 1;

            l_non_zero_nrec_tax_lines_tbl(1) := i;

           END IF;

        ELSIF l_recoverable_flg_tbl(i) = 'Y' THEN

          -- For recoverable tax line
          --
          l_sum_of_rnd_rec_tax_amt := l_tax_amt_funcl_curr_tbl(i);
          l_total_unrounded_rec_tax_amt :=  l_unrounded_tax_amt_tbl(i);
          l_total_unrounded_nrec_tax_amt :=  0;

          IF l_rec_nrec_tax_amt_tbl(i) <> 0 THEN

            -- Record this non-zero recoverable tax lines
            --
            l_non_zero_rec_tax_line_index := 1;

            l_non_zero_rec_tax_lines_tbl(1) := i;

          END IF;

        END IF;    -- check Recoverable_Flag



      END IF;      -- check if this is the only tax dist with this tax_line_id

    END IF;        -- check tax_line_id
  END LOOP;

  -- update taxable_amt_funcl_curr from tax_amt_funcl_curr/tax_rate.
  -- If tax_rate = 0, get taxable_amt_funcl_curr by converting
  -- taxable_amt to functional currency
  --
  FOR i IN NVL(l_rec_nrec_tax_dist_id_tbl.FIRST, 0).. NVL(l_rec_nrec_tax_dist_id_tbl.LAST, -1)
  LOOP

    -- convert taxable_amt to functional currency and perform rounding
    -- for taxable_amt_funcl_curr
    --
    IF l_rec_nrec_rate_tbl(i) <> 0 THEN

      l_taxable_amt_funcl_curr_tbl(i) := l_tax_amt_funcl_curr_tbl(i)/
                                                    l_rec_nrec_rate_tbl(i);

      -- rounding to the correct precision and minumum accountable units
      --
      l_taxable_amt_funcl_curr_tbl(i) := round(l_taxable_amt_funcl_curr_tbl(i)/
                      l_minimum_accountable_unit ) * l_minimum_accountable_unit;

    ELSE

      IF l_funcl_currency_code <> l_trx_currency_code_tbl(i) THEN
        l_taxable_amt_funcl_curr_tbl(i) :=
        GL_CURRENCY_API.convert_amount (
                    x_set_of_books_id   => p_ledger_id,
                    x_from_currency     => l_trx_currency_code_tbl(i),
                    x_conversion_date   => p_currency_conversion_date,
                    x_conversion_type   => p_currency_conversion_type,
                    x_amount            => l_unrounded_taxable_amt_tbl(i));
      ELSE
        l_taxable_amt_funcl_curr_tbl(i) :=
          round(l_taxable_amt_funcl_curr_tbl(i)/l_minimum_accountable_unit) *
            l_minimum_accountable_unit;
      END IF;
    END IF;



  END LOOP;



  -- Update Table ZX_REC_NREC_DIST
  --
  FORALL i IN NVL(l_rec_nrec_tax_dist_id_tbl.FIRST,0) .. NVL(l_rec_nrec_tax_dist_id_tbl.LAST,-1)

    UPDATE  zx_rec_nrec_dist
       SET  currency_conversion_rate       = p_currency_conversion_rate,
            currency_conversion_type       = p_currency_conversion_type,
            currency_conversion_date       = p_currency_conversion_date,
            rec_nrec_tax_amt_funcl_curr    = l_tax_amt_funcl_curr_tbl(i),
            taxable_amt_funcl_curr         = l_taxable_amt_funcl_curr_tbl(i),
            func_curr_rounding_adjustment  = l_func_curr_rnd_adjustment_tbl(i),
            object_version_number          = object_version_number + 1
     WHERE  rec_nrec_tax_dist_id = l_rec_nrec_tax_dist_id_tbl(i)
       AND  application_id = p_event_class_rec.application_id
       AND  entity_code = p_event_class_rec.entity_code
       AND  event_class_code  = p_event_class_rec.event_class_code
       AND  trx_id = p_event_class_rec.trx_id;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
             'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate.END',
             'ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate(-)');
  END IF;

EXCEPTION

  WHEN OTHERS THEN

    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    l_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate',
                     l_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate.END',
                     'ZX_TRD_SERVICES_PUB_PKG.update_exchange_rate(-)');
      END IF;

END update_exchange_rate;

/* =========================================================================*
 |  PUBLIC FUNCTION  round_amt_to_mau                                       |
 |                                                                          |
 |  DESCRIPTION:                                                            |
 |  This procedure is used to round the amount to minimum_accountable_unit  |
 |                                                                          |
 * =========================================================================*/

FUNCTION round_amt_to_mau (
  p_ledger_id       NUMBER,
  p_unrounded_amt   NUMBER ) RETURN NUMBER IS

 CURSOR  get_mau_info_csr IS
  SELECT nvl( cur.minimum_accountable_unit, power( 10, (-1 * precision)))
    FROM fnd_currencies cur, gl_sets_of_books sob
   WHERE sob.set_of_books_id = p_ledger_id
     AND cur.currency_code = sob.currency_code;

  l_rounded_amt_to_mau    NUMBER;
  l_mau        NUMBER;
  l_error_buffer    VARCHAR2(200);

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_statement >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.round_amt_to_mau.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.round_amt_to_mau(+)');
  END IF;

  -- get the l_minimum_accountable_unit
  --
  OPEN  get_mau_info_csr;
  FETCH get_mau_info_csr INTO l_mau;
  CLOSE get_mau_info_csr;

  -- rounding to the correct precision and minumum accountable units
  --
  l_rounded_amt_to_mau := round(p_unrounded_amt/l_mau ) * l_mau;

  IF (g_level_statement >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.round_amt_to_mau.END',
                   'ZX_TRD_SERVICES_PUB_PKG.round_amt_to_mau(-)'||
                   ' rounded amt to mau '||l_rounded_amt_to_mau);
  END IF;

  RETURN l_rounded_amt_to_mau;

EXCEPTION
  WHEN OTHERS THEN
    l_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.round_amt_to_mau',
                     l_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
                    'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.round_amt_to_mau.END',
                     'ZX_TRD_SERVICES_PUB_PKG.round_amt_to_mau(-)');
      END IF;
    RAISE;
END round_amt_to_mau;

/* ===========================================================================*
 |  PUBLIC FUNCTION  get_tax_hold_rls_val_frm_code                            |
 |                                                                            |
 |  DESCRIPTION:                                                              |
 |  This function is used to get the correpsonding numeric value of the input |
 |  tax_hold_release_code.                                                    |
 |                                                                            |
 |  Called from ZX_TRL_MANAGE_TAX_PKG.RELEASE_DOCUMENT_TAX_HOLD()             |
 |                                                                            |
 * ===========================================================================*/

FUNCTION get_tax_hold_rls_val_frm_code (
  p_tax_hold_released_code IN VARCHAR2
) RETURN NUMBER IS
  l_tax_hold_release_value NUMBER;
BEGIN
  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_statement >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.get_tax_hold_rls_val_frm_code.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.get_tax_hold_rls_val_frm_code(+)');
  END IF;

  IF p_tax_hold_released_code = ZX_TDS_CALC_SERVICES_PUB_PKG.G_TAX_VARIANCE_CORRECTED THEN
    l_tax_hold_release_value := ZX_TDS_CALC_SERVICES_PUB_PKG.g_tax_variance_corrected_val;
  ELSIF p_tax_hold_released_code = ZX_TDS_CALC_SERVICES_PUB_PKG.G_TAX_AMT_RANGE_CORRECTED THEN
    l_tax_hold_release_value := ZX_TDS_CALC_SERVICES_PUB_PKG.g_tax_amt_range_corrected_val;
  ELSE
    l_tax_hold_release_value := 0;
  END IF;

  IF (g_level_statement >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.get_tax_hold_rls_val_frm_code.END',
                   'ZX_TRD_SERVICES_PUB_PKG.get_tax_hold_rls_val_frm_code(-)');
  END IF;
  RETURN l_tax_hold_release_value;

END get_tax_hold_rls_val_frm_code;

/* ========================================================================*
 |  PUBLIC FUNCTION  get_prod_total_tax_amt                                |
 |                                                                         |
 |  DESCRIPTION:                                                           |
 |  This function is called by TSRM to get the pro-rated tax amount in     |
 |  transaction/functional/tax currency                                    |
 |                                                                         |
 |  HISTORY:                                                               |
 |    Aug-11-2004  Created for bug fix 3551605                             |
 |                                                                         |
 * ========================================================================*/

FUNCTION get_prod_total_tax_amt(
  p_prepay_tax_amt     NUMBER,
  p_line_amt           NUMBER,
  p_prepay_line_amt    NUMBER ) RETURN NUMBER IS

  l_prd_total_tax_amt  NUMBER;

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.get_prod_total_tax_amt.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.get_prod_total_tax_amt(+)');
  END IF;

  IF NVL(p_prepay_line_amt, 0) <> 0 THEN
    l_prd_total_tax_amt := p_prepay_tax_amt  * p_line_amt / p_prepay_line_amt;

  ELSE
    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.get_prod_total_tax_amt',
                   'p_prepay_line_amt is '||NVL(TO_CHAR(p_prepay_line_amt), 'NULL'));
    END IF;

  END IF;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.get_prod_total_tax_amt.END',
                   'ZX_TRD_SERVICES_PUB_PKG.get_prod_total_tax_amt(-)');
  END IF;

  return l_prd_total_tax_amt;

END get_prod_total_tax_amt;

/* =======================================================================*
 |  PUBLIC PROCEDURE  is_recoverability_affected                          |
 |                                                                        |
 |  DESCRIPTION:                                                          |
 |  This procedure is called by TSRM to check if the item's project       |
 |    information like project_id, task_id, can be changed.               |
 |                                                                        |
 |  HISTORY:                                                              |
 |    Apr-05-2005  Created for bug fix 4220119                            |
 * =======================================================================*/
PROCEDURE is_recoverability_affected(
  p_pa_item_info_tbl IN OUT NOCOPY ZX_API_PUB.pa_item_info_tbl_type,
  x_return_status       OUT NOCOPY VARCHAR2) IS

 CURSOR get_tax_dists_csr(
          c_application_id         zx_rec_nrec_dist.application_id%TYPE,
          c_entity_code            zx_rec_nrec_dist.entity_code%TYPE,
          c_event_class_code       zx_rec_nrec_dist.entity_code%TYPE,
          c_trx_id                 zx_rec_nrec_dist.trx_id%TYPE,
          c_trx_line_id            zx_rec_nrec_dist.trx_line_id%TYPE,
          c_trx_level_type         zx_rec_nrec_dist.trx_level_type%TYPE,
          c_item_expense_dist_id   zx_rec_nrec_dist.trx_line_dist_id %TYPE) IS
  SELECT *
    FROM zx_rec_nrec_dist
   WHERE trx_line_dist_id = c_item_expense_dist_id
     AND application_id = c_application_id
     AND entity_code = c_entity_code
     AND event_class_code = c_event_class_code
     AND trx_id = c_trx_id
     AND trx_line_id = c_trx_line_id
     AND trx_level_type = c_trx_level_type;

 CURSOR check_migrated_rule_code_csr(
           c_tax_rate_id   zx_rates_b.tax_rate_id%TYPE) IS
   SELECT rates.recovery_rule_code
     FROM zx_rates_b rates
    WHERE rates.tax_rate_id = c_tax_rate_id;

 CURSOR check_current_rule_csr(
           c_rec_rate_result_id   zx_rec_nrec_dist.rec_rate_result_id%TYPE) IS
   SELECT rules.service_type_code,
          rules.priority,
          factor_dtls.determining_factor_code
     FROM zx_process_results results,
          zx_rules_b rules,
          zx_det_factor_templ_b factors,
          zx_det_factor_templ_dtl factor_dtls
    WHERE results.result_id = c_rec_rate_result_id
      AND rules.tax_rule_id = results.tax_rule_id
      AND factors.det_factor_templ_code = rules.det_factor_templ_code
      AND factor_dtls.det_factor_templ_id = factors.det_factor_templ_id;

 CURSOR check_other_rules_csr(
          c_service_type_code        zx_rules_b.service_type_code%TYPE,
          c_priority                 zx_rules_b.priority%TYPE,
          c_application_id           NUMBER,
          c_entity_code              VARCHAR2,
          c_event_class_code         VARCHAR2,
          c_tax                      zx_taxes_b.tax%TYPE,
          c_tax_regime_code          zx_regimes_b.tax_regime_code%TYPE,
          c_recovery_type_code       zx_rules_b.recovery_type_code%TYPE,
--          c_reference_application_id zx_rules_b.application_id%TYPE,
          c_tax_line_id              zx_lines.tax_line_id%TYPE) IS
   SELECT rules.service_type_code,
          rules.priority,
          factor_dtls.determining_factor_code
     FROM zx_sco_rules_b_v rules,
          zx_lines lines,
          zx_evnt_cls_mappings mappings,
          zx_det_factor_templ_b factors,
          zx_det_factor_templ_dtl factor_dtls
    WHERE rules.service_type_code = c_service_type_code
      AND rules.tax = c_tax     -- In phase 1, tax and regime should not be NULL
      AND rules.tax_regime_code = c_tax_regime_code
      AND rules.system_default_flag <> 'Y'
      AND rules.enabled_flag  = 'Y'
      AND rules.priority < c_priority
      AND rules.recovery_type_code = c_recovery_type_code
      AND EXISTS (SELECT result_id
                    FROM zx_process_results results
                   WHERE results.tax_rule_id = rules.tax_rule_id
                     AND results.enabled_flag = 'Y')
      AND mappings.event_class_code = c_event_class_code
      AND mappings.application_id   = c_application_id
      AND mappings.entity_code      = c_entity_code
      AND (rules.application_id = mappings.reference_application_id OR
           rules. application_id IS NULL)
      AND lines.tax_line_id = c_tax_line_id
      AND lines.tax_determine_date >= effective_from
      AND (lines.tax_determine_date <= effective_to OR
           rules.effective_to IS NULL)
      AND factors.det_factor_templ_code = rules.det_factor_templ_code
      AND factor_dtls.det_factor_templ_id = factors.det_factor_templ_id;

 l_service_type_code  zx_rules_b.service_type_code%TYPE;
 l_priority    zx_rules_b.priority%TYPE;
 l_recovery_rule_code   zx_rates_b.recovery_rule_code%TYPE;
 l_error_buffer    VARCHAR2(200);

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.is_recoverability_affected.BEGIN',
       'ZX_TRD_SERVICES_PUB_PKG.is_recoverability_affected(+)');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  -- loop through the item distribution data structure passed by product
  --
  FOR i IN NVL(p_pa_item_info_tbl.FIRST, 0) .. NVL(p_pa_item_info_tbl.LAST, -1)
  LOOP

    -- initialize p_pa_item_info_tbl(i).recoverability_affected to FALSE
    --
    p_pa_item_info_tbl(i).recoverability_affected := FALSE;

    -- loop through the tax distributions of each item distribution
    --
    FOR tax_dist_rec IN get_tax_dists_csr(
             p_pa_item_info_tbl(i).application_id,
             p_pa_item_info_tbl(i).entity_code,
             p_pa_item_info_tbl(i).event_class_code,
             p_pa_item_info_tbl(i).trx_id,
             p_pa_item_info_tbl(i).trx_line_id,
             p_pa_item_info_tbl(i).trx_level_type,
             p_pa_item_info_tbl(i).item_expense_dist_id)
    LOOP

      IF tax_dist_rec.rec_rate_result_id IS NULL THEN

        IF tax_dist_rec.historical_flag = 'Y' THEN

          -- check recovery rule code defined in 11i
          --
          OPEN check_migrated_rule_code_csr(tax_dist_rec.tax_rate_id);
          FETCH check_migrated_rule_code_csr INTO l_recovery_rule_code;
          CLOSE check_migrated_rule_code_csr;

          IF l_recovery_rule_code IS NULL THEN
            p_pa_item_info_tbl(i).recoverability_affected := FALSE;
          ELSE
            p_pa_item_info_tbl(i).recoverability_affected := TRUE;
          END IF;
          EXIT;   -- Exit processing other tax distributions
        END IF;

      ELSE    -- rec_rate_result_id IS NOT NULL:

        -- Loop through the rule associated with the determining factor
        -- details defined in the rule associated with the current result id.
        -- IF any determining factor code is 'ACCOUNT_STRING', set
        -- recoverability_affected := TRUE and stop processing the
        -- current item distribution;
        --
        FOR det_factor_detail_rec IN
            check_current_rule_csr(tax_dist_rec.rec_rate_result_id) LOOP

          l_service_type_code := det_factor_detail_rec.service_type_code;
          l_priority := det_factor_detail_rec.priority;

          IF det_factor_detail_rec.determining_factor_code  IN
                                      ('ACCOUNT_STRING', 'LINE_ACCOUNT') THEN
            p_pa_item_info_tbl(i).recoverability_affected := TRUE;
            EXIT;   -- Exit processing other determining factor details
          END IF;
        END LOOP;   -- det_factor_detail_rec IN ...

        IF p_pa_item_info_tbl(i).recoverability_affected THEN
          EXIT;     -- Exit processing other tax distributions
        ELSE

          -- If recoverability_affected is still FALSE, need to check
          -- the other previously processed rules for this recovery rate.
          --
          FOR det_factor_detail_rec IN check_other_rules_csr(
                                          l_service_type_code,
                                          l_priority,
                                          tax_dist_rec.application_id,
                                          tax_dist_rec.entity_code,
                                          tax_dist_rec.event_class_code,
                                          tax_dist_rec.tax,
                                          tax_dist_rec.tax_regime_code,
                                          tax_dist_rec.recovery_type_code,
                                          tax_dist_rec.tax_line_id)
          LOOP

            IF det_factor_detail_rec.determining_factor_code IN
                                        ('ACCOUNT_STRING', 'LINE_ACCOUNT') THEN
              p_pa_item_info_tbl(i).recoverability_affected := TRUE;
              EXIT;   -- Exit processing other determining factor details
            END IF;
          END LOOP;   -- det_factor_detail_rec IN check_other_rules_csr

          -- If recoverability_affected := TRUE, exit processing other
          -- tax distributions
          --
          IF p_pa_item_info_tbl(i).recoverability_affected THEN
            EXIT;   -- Exit processing other tax distributions
          END IF;

        END IF;     -- p_pa_item_info_tbl(i).recoverability_affected or ELSE
      END IF;       -- tax_dist_rec.rec_rate_result_id IS NULL OR ELSE
    END LOOP;       -- tax_dist_rec IN get_tax_dists_csr
  END LOOP;         -- i IN p_pa_item_info_tbl.FIRST .. p_pa_item_info_tbl.LAST

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.is_recoverability_affected.END',
       'ZX_TRD_SERVICES_PUB_PKG.is_recoverability_affected(-)');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    l_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.is_recoverability_affected',
          l_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.is_recoverability_affected.END',
         'ZX_TRD_SERVICES_PUB_PKG.ZX_TRD_SERVICES_PUB_PKG(-)');
      END IF;

END is_recoverability_affected;

FUNCTION GET_RECOVERABLE_CCID(
        p_rec_nrec_dist_id      IN              NUMBER,
        p_tax_line_id           IN              NUMBER,
        p_gl_date               IN              DATE,
  p_tax_rate_id    IN    NUMBER,
  p_rec_rate_id    IN     NUMBER,
        p_ledger_id             IN              NUMBER,
        p_source_rate_id        IN              NUMBER,
  p_content_owner_id  IN    NUMBER) RETURN NUMBER IS

/* Note - this function is called from view zx_ap_def_tax_extract_v
   This view is used only during payment accounting, where we need not check
   the def_recovery_setlement_option_code like we do in get_ccid procedure
*/

Cursor get_rec_ccid_cur(c_tax_account_entity_id number,
                        c_ledger_id number,
                        c_internal_org_id number) is
   select tax_account_ccid
   from   zx_accounts
   where  TAX_ACCOUNT_ENTITY_ID = c_tax_account_entity_id
   and    TAX_ACCOUNT_ENTITY_CODE = 'RATES'
   and    ledger_id = c_ledger_id
   and    internal_organization_id = c_internal_org_id;

Cursor is_ccid_valid(l_ccid number) is
   select 'x'
   from   gl_code_combinations
   where  code_combination_id = l_ccid
   and    enabled_flag = 'Y'
   and    p_gl_date between nvl(start_date_active,p_gl_date) and nvl(end_date_active, p_gl_date);

l_ccid        NUMBER;
l_val        char;
l_internal_org_id               NUMBER;
l_error_buffer                  VARCHAR2(200);

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_RECOVERABLE_CCID.BEGIN',
       'ZX_TRD_SERVICES_PUB_PKG.GET_RECOVERABLE_CCID(+)');
  END IF;

  BEGIN

    SELECT INTERNAL_ORGANIZATION_ID
    INTO   l_internal_org_id
    FROM   ZX_LINES
    WHERE  tax_line_id = p_tax_line_id;

  EXCEPTION
    WHEN OTHERS THEN

      l_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);
      IF (g_level_unexpected >= g_current_runtime_level ) THEN
         FND_LOG.STRING(g_level_unexpected,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_RECOVERABLE_CCID',
       'Exception in ZX_TRD_SERVICES_PUB_PKG.GET_RECOVERABLE_CCID: '||l_error_buffer);
      END IF;

         return(null);

  END;


  open get_rec_ccid_cur(nvl(p_source_rate_id,p_tax_rate_id),
                        p_ledger_id,
                        l_internal_org_id);
  fetch get_rec_ccid_cur into l_ccid;

  close get_rec_ccid_cur;

  IF l_ccid is not null THEN

     open is_ccid_valid(l_ccid);
     fetch is_ccid_valid into l_val;

     if is_ccid_valid%notfound then
  l_ccid := null;
     end if;

     close is_ccid_valid;

  END IF;  -- l_ccid is not null

  IF l_ccid is null THEN

     open get_rec_ccid_cur(p_rec_rate_id, p_ledger_id, l_internal_org_id);
     fetch get_rec_ccid_cur into l_ccid;

     close get_rec_ccid_cur;

     if l_ccid is not null then

  open is_ccid_valid(l_ccid);
         fetch is_ccid_valid into l_val;

  if is_ccid_valid%notfound then
     l_ccid := null;
  end if;

  close is_ccid_valid;

     end if;  -- l_ccid is not null

  END IF;  -- l_ccid is null

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_RECOVERABLE_CCID.BEGIN',
       'ZX_TRD_SERVICES_PUB_PKG.GET_RECOVERABLE_CCID(-)'||
       ' ccid = '||l_ccid);
  END IF;

  return(l_ccid);

EXCEPTION
    WHEN OTHERS THEN

      l_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);
      IF (g_level_unexpected >= g_current_runtime_level ) THEN
         FND_LOG.STRING(g_level_unexpected,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_RECOVERABLE_CCID',
       'Exception in ZX_TRD_SERVICES_PUB_PKG.GET_RECOVERABLE_CCID: '||l_error_buffer);
      END IF;
      return(null);
END GET_RECOVERABLE_CCID;


/* ===========================================================================*
 |  PUBLIC PROCEDURE  delete_unnecessary_tax_dists                            |
 |                                                                            |
 |  DESCRIPTION:                                                              |
 |    This procedure is called if associate_child_frozen_flag on detail tax   |
 |     lines is 'Y' after tax dists are inserted into zx_rec_nrec_dist_gt.    |
 |     If there is no change on tax_line and item distribution, the reversed  |
 |     tax_distributions and the new created tax distributions, which are     |
 |     created for the frozen taxdistributions, will be deleted.              |
 |                                                                            |
 |  When there are frozen tax distributions and recovery redetermination is   |
 |  needed for the parent tax line, we reverse the existing frozen tax        |
 |  distributions and create new tax distributions. If there is no difference |
 |  between the existing frozen tax distribution and the corresponding new    |
 |  tax distribution (excluding reverse flag and frozen flag), we should      |
 |  honor the existing frozen tax distribution and remove the newly created   |
 |  tax distributions. In the following example, suppose there is a frozen    |
 |  tax distribution D1, during internal processing, we create a negative     |
 |  D2 and a positive D3.                                                     |
 |    D1  frozen                                                              |
 |    D2  negative D1 reverse                                                 |
 |    D3  same as D1                                                          |
 |  If D3 is exactly the same as D1 (excluding reverse flag and frozen flag), |
 |   we delete  both D2 and D3 and simply keep D1.                            |
 |                                                                            |
 |  The columns used for the comparison reviewed by Helen                     |
 |                                                                            |
 |     application_id       |                                                 |
 |     entity_code          |                                                 |
 |     event_class_code     |                                                 |
 |     trx_id               | -- through tax_line_id                          |
 |     trx_line_id          |                                                 |
 |     tax_level_type       |                                                 |
 |     tax_regime_id        |                                                 |
 |     tax_id               |                                                 |
 |     tax_line_id                                                            |
 |     trx_line_dist_id                                                       |
 |     tax_status_id                                                          |
 |     tax_rate_id                                                            |
 |     inclusive_flag                                                         |
 |     recovery_type_id                                                       |
 |     recovery_type_code                                                     |
 |     recovery_rate_id                                                       |
 |     recoverable_flag                                                       |
 |     rec_nrec_tax_amt                                                       |
 |     intended_use                                                           |
 |     project_id                        |                                    |
 |     task_id                           |                                    |
 |     award_id                          |    For reporting purpose           |
 |     expenditure_type                  |                                    |
 |     expenditure_organization_id       |                                    |
 |     expenditure_item_date             |                                    |
 |     currency_conversion_date                                               |
 |     currency_conversion_type                                               |
 |     currency_conversion_rate                                               |
 |     tax_currency_conversion_date                                           |
 |     tax_currency_conversion_type                                           |
 |     tax_currency_conversion_rate                                           |
 |     trx_currency_code                                                      |
 |     tax_currency_code                                                      |
 |     backward_compatibility_flag                                            |
 |     self_assessed_flag                                                     |
 |     ref_doc_application_id         |                                       |
 |     ref_doc_entity_code            |                                       |
 |     ref_doc_event_class_code       | through ref_doc_tax_dist_id           |
 |     ref_doc_trx_id                 |                                       |
 |     ref_doc_line_id                |                                       |
 |     ref_doc_dist_id                |                                       |
 |     tax_only_line_flag                                                     |
 |     account_ccid                                                           |
 |                                                                            |
* ============================================================================*/
PROCEDURE delete_unnecessary_tax_dists(
       p_event_class_rec  IN          ZX_API_PUB.EVENT_CLASS_REC_TYPE,
       x_return_status    OUT NOCOPY  VARCHAR2) IS

 TYPE NUMERIC_TBL_TYPE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

 l_reversed_tax_dist_id_tbl     NUMERIC_TBL_TYPE;
 l_rec_nrec_tax_Dist_id_tbl1    NUMERIC_TBL_TYPE;
 l_rec_nrec_tax_Dist_id_tbl2    NUMERIC_TBL_TYPE;

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.delete_unnecessary_tax_dists.BEGIN',
       'ZX_TRD_SERVICES_PUB_PKG.delete_unnecessary_tax_dists(+)');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  -- Modified code as part of bug#7515711 to ensure that additional distributions
  -- are not created for Historical Invoices on re-validation.

  SELECT REC_NREC_TAX_DIST_ID, REVERSED_TAX_DIST_ID
  BULK COLLECT INTO l_rec_nrec_tax_Dist_id_tbl1, l_reversed_tax_dist_id_tbl
  FROM ZX_REC_NREC_DIST_GT gt
   WHERE reversed_tax_dist_id IS NOT NULL
     AND EXISTS
           (SELECT /*+ first_rows (1) index (gt1, ZX_REC_NREC_DIST_GT_N1) */ 1
              FROM ZX_REC_NREC_DIST_GT gt1
             WHERE gt1.tax_line_id = gt.tax_line_id
               AND gt1.trx_line_dist_id = gt.trx_line_dist_id
               AND gt1.tax_status_id = gt.tax_status_id
               AND gt1.tax_rate_id = gt.tax_rate_id
               AND gt1.recoverable_flag = gt.recoverable_flag
               AND NVL(gt1.inclusive_flag, 'N') = NVL(gt.inclusive_flag, 'N')
               AND NVL(gt1.recovery_type_id, -999) = NVL(gt.recovery_type_id, -999)
               AND NVL(gt1.recovery_type_code, 'x') = NVL(gt.recovery_type_code, 'x')
               AND NVL(gt1.recovery_rate_code, 'x') = NVL(gt.recovery_rate_code, 'x')
               /*AND NVL(gt1.project_id, -999) = NVL(gt.project_id, -999)
               AND NVL(gt1.task_id, -999) = NVL(gt.task_id, -999)
               AND NVL(gt1.award_id, -999) = NVL(gt.award_id, -999)
               AND NVL(gt1.expenditure_type, 'x') = NVL(gt.expenditure_type, 'x')
               AND NVL(gt1.expenditure_organization_id, -999) = NVL(gt.expenditure_organization_id, -999)
               AND NVL(TRUNC(gt1.expenditure_item_date), DATE_DUMMY) = NVL(TRUNC(gt.expenditure_item_date), DATE_DUMMY)*/
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.project_id, -999), -999)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.project_id, -999), -999)
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.task_id, -999), -999)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.task_id, -999), -999)
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.award_id, -999), -999)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.award_id, -999), -999)
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.expenditure_type, 'x'), 'x')
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.expenditure_type, 'x'), 'x')
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.expenditure_organization_id, -999), -999)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.expenditure_organization_id, -999), -999)
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(TRUNC(gt1.expenditure_item_date), DATE_DUMMY), DATE_DUMMY)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(TRUNC(gt.expenditure_item_date), DATE_DUMMY), DATE_DUMMY)
               AND NVL(TRUNC(gt1.currency_conversion_date), DATE_DUMMY) = NVL(TRUNC(gt.currency_conversion_date), DATE_DUMMY)
               AND NVL(gt1.currency_conversion_type, 'x') = NVL(gt.currency_conversion_type, 'x')
               AND NVL(gt1.currency_conversion_rate, 1) = NVL(gt.currency_conversion_rate, 1)
               AND NVL(TRUNC(gt1.tax_currency_conversion_date), DATE_DUMMY) = NVL(TRUNC(gt.tax_currency_conversion_date), DATE_DUMMY)
               AND NVL(gt1.tax_currency_conversion_type, 'x') = NVL(gt.tax_currency_conversion_type, 'x')
               AND NVL(gt1.tax_currency_conversion_rate, 1) = NVL(gt.tax_currency_conversion_rate, 1)
               AND NVL(gt1.trx_currency_code, 'x') = NVL(gt.trx_currency_code, 'x')
               AND NVL(gt1.tax_currency_code, 'x') = NVL(gt.tax_currency_code, 'x')
               AND NVL(gt1.backward_compatibility_flag, 'x') = NVL(gt.backward_compatibility_flag, 'x')
               AND NVL(gt1.self_assessed_flag, 'N') = NVL(gt.self_assessed_flag, 'N')
               AND NVL(gt1.intended_use, 'x') = NVL(gt.intended_use, 'x')
               AND NVL(gt1.tax_only_line_flag, 'N') = NVL(gt.tax_only_line_flag, 'N')
               --AND NVL(gt1.account_ccid, -999) = NVL(gt.account_ccid, -999)
               AND gt1.rec_nrec_tax_amt = -gt.rec_nrec_tax_amt
               AND gt1.trx_line_dist_amt = -gt.trx_line_dist_amt           -- bug 6709478
               AND gt1.trx_line_dist_tax_amt = -gt.trx_line_dist_tax_amt   -- bug 6709478
               AND gt1.rec_nrec_tax_dist_number > gt.rec_nrec_tax_dist_number
               AND gt1.freeze_flag = 'N'
               AND gt1.reverse_flag = 'N'
               AND rownum = 1
           );
  --RETURNING reversed_tax_dist_id BULK COLLECT INTO l_reversed_tax_dist_id_tbl;

  IF l_rec_nrec_tax_Dist_id_tbl1.count > 0 THEN

  SELECT rec_nrec_tax_dist_id
  BULK COLLECT INTO l_rec_nrec_tax_Dist_id_tbl2
  FROM ZX_REC_NREC_DIST_GT gt
  WHERE gt.freeze_flag = 'N'
    AND gt.reverse_flag = 'N'
    AND EXISTS
           (SELECT /*+ first_rows (1) index (gt1, ZX_REC_NREC_DIST_GT_N1) */ 1
              FROM ZX_REC_NREC_DIST_GT gt1
             WHERE gt1.tax_line_id = gt.tax_line_id
               AND gt1.trx_line_dist_id = gt.trx_line_dist_id
               AND gt1.tax_status_id = gt.tax_status_id
               AND gt1.tax_rate_id = gt.tax_rate_id
               AND gt1.recoverable_flag = gt.recoverable_flag
               AND NVL(gt1.inclusive_flag, 'N') = NVL(gt.inclusive_flag, 'N')
               AND NVL(gt1.recovery_type_id, -999) = NVL(gt.recovery_type_id, -999)
               AND NVL(gt1.recovery_type_code, 'x') = NVL(gt.recovery_type_code, 'x')
               AND NVL(gt1.recovery_rate_code, 'x') = NVL(gt.recovery_rate_code, 'x')
               /*AND NVL(gt1.project_id, -999) = NVL(gt.project_id, -999)
               AND NVL(gt1.task_id, -999) = NVL(gt.task_id, -999)
               AND NVL(gt1.award_id, -999) = NVL(gt.award_id, -999)
               AND NVL(gt1.expenditure_type, 'x') = NVL(gt.expenditure_type, 'x')
               AND NVL(gt1.expenditure_organization_id, -999) = NVL(gt.expenditure_organization_id, -999)
               AND NVL(TRUNC(gt1.expenditure_item_date), DATE_DUMMY) = NVL(TRUNC(gt.expenditure_item_date), DATE_DUMMY)*/
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.project_id, -999), -999)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.project_id, -999), -999)
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.task_id, -999), -999)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.task_id, -999), -999)
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.award_id, -999), -999)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.award_id, -999), -999)
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.expenditure_type, 'x'), 'x')
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.expenditure_type, 'x'), 'x')
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(gt1.expenditure_organization_id, -999), -999)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(gt.expenditure_organization_id, -999), -999)
               AND DECODE(gt1.HISTORICAL_FLAG, 'N', NVL(TRUNC(gt1.expenditure_item_date), DATE_DUMMY), DATE_DUMMY)
                       = DECODE(gt.HISTORICAL_FLAG, 'N', NVL(TRUNC(gt.expenditure_item_date), DATE_DUMMY), DATE_DUMMY)
               AND NVL(TRUNC(gt1.currency_conversion_date), DATE_DUMMY) = NVL(TRUNC(gt.currency_conversion_date), DATE_DUMMY)
               AND NVL(gt1.currency_conversion_type, 'x') = NVL(gt.currency_conversion_type, 'x')
               AND NVL(gt1.currency_conversion_rate, 1) = NVL(gt.currency_conversion_rate, 1)
               AND NVL(TRUNC(gt1.tax_currency_conversion_date), DATE_DUMMY) = NVL(TRUNC(gt.tax_currency_conversion_date), DATE_DUMMY)
               AND NVL(gt1.tax_currency_conversion_type, 'x') = NVL(gt.tax_currency_conversion_type, 'x')
               AND NVL(gt1.tax_currency_conversion_rate, 1) = NVL(gt.tax_currency_conversion_rate, 1)
               AND NVL(gt1.trx_currency_code, 'x') = NVL(gt.trx_currency_code, 'x')
               AND NVL(gt1.tax_currency_code, 'x') = NVL(gt.tax_currency_code, 'x')
               AND NVL(gt1.backward_compatibility_flag, 'x') = NVL(gt.backward_compatibility_flag, 'x')
               AND NVL(gt1.self_assessed_flag, 'N') = NVL(gt.self_assessed_flag, 'N')
               AND NVL(gt1.intended_use, 'x') = NVL(gt.intended_use, 'x')
               AND NVL(gt1.tax_only_line_flag, 'N') = NVL(gt.tax_only_line_flag, 'N')
               --AND NVL(gt1.account_ccid, -999) = NVL(gt.account_ccid, -999)
               AND gt1.rec_nrec_tax_amt = gt.rec_nrec_tax_amt
               AND gt1.trx_line_dist_amt = gt.trx_line_dist_amt           -- bug 6709478
               AND gt1.trx_line_dist_tax_amt = gt.trx_line_dist_tax_amt   -- bug 6709478
               AND gt1.rec_nrec_tax_dist_number < gt.rec_nrec_tax_dist_number
               AND gt1.freeze_flag = 'Y'
               AND gt1.reverse_flag = 'Y'
               AND rownum = 1
           );

  END IF;

  -- This will take care that one set should not deleted.
  -- Both the negetive and positive additional distributions should be deleted.

  IF l_rec_nrec_tax_Dist_id_tbl1.COUNT > 0 AND l_rec_nrec_tax_Dist_id_tbl2.COUNT > 0 THEN

    FORALL j in l_rec_nrec_tax_Dist_id_tbl1.FIRST .. l_rec_nrec_tax_Dist_id_tbl1.LAST
      DELETE FROM zx_rec_nrec_dist_gt
      WHERE rec_nrec_tax_dist_id IN l_rec_nrec_tax_Dist_id_tbl1(j);

    FORALL j in l_rec_nrec_tax_Dist_id_tbl2.FIRST .. l_rec_nrec_tax_Dist_id_tbl2.LAST
      DELETE FROM zx_rec_nrec_dist_gt
      WHERE rec_nrec_tax_dist_id IN l_rec_nrec_tax_Dist_id_tbl2(j);

  END IF;

  IF l_reversed_tax_dist_id_tbl.COUNT > 0 AND l_rec_nrec_tax_Dist_id_tbl1.count > 0
     AND l_rec_nrec_tax_Dist_id_tbl2.COUNT > 0 THEN

    FORALL i IN l_reversed_tax_dist_id_tbl.FIRST .. l_reversed_tax_dist_id_tbl.LAST
      UPDATE zx_rec_nrec_dist_gt gt
      SET reverse_flag = 'N'
      WHERE rec_nrec_tax_dist_id  = l_reversed_tax_dist_id_tbl(i);

  END IF;


  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.delete_unnecessary_tax_dists.END',
       'ZX_TRD_SERVICES_PUB_PKG.delete_unnecessary_tax_dists(-)');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.delete_unnecessary_tax_dists',
          sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80));
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.delete_unnecessary_tax_dists.END',
         'ZX_TRD_SERVICES_PUB_PKG.delete_unnecessary_tax_dists(-)');
      END IF;

END delete_unnecessary_tax_dists;

PROCEDURE update_posting_flag(
  p_tax_dist_id_tbl     IN ZX_API_PUB.tax_dist_id_tbl_type,
  x_return_status       OUT NOCOPY VARCHAR2) IS

 l_error_buffer    VARCHAR2(200);

BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_posting_flag.BEGIN',
       'ZX_TRD_SERVICES_PUB_PKG.update_posting_flag(+)');
  END IF;

  x_return_status:= FND_API.G_RET_STS_SUCCESS;

  FORALL i IN NVL(p_tax_dist_id_tbl.FIRST, 0) .. NVL(p_tax_dist_id_tbl.LAST, -1)
    UPDATE ZX_Rec_Nrec_Dist
     SET   posting_flag = 'A'
   WHERE   rec_nrec_tax_dist_id = p_tax_dist_id_tbl(i);

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_posting_flag.END',
       'ZX_TRD_SERVICES_PUB_PKG.update_posting_flag(-)');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    l_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_posting_flag',
          l_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.update_posting_flag.END',
         'ZX_TRD_SERVICES_PUB_PKG.ZX_TRD_SERVICES_PUB_PKG(-)');
      END IF;

END update_posting_flag;

PROCEDURE get_tax_jurisdiction_id(
       p_tax_line_id          IN  NUMBER,
       p_tax_rate_id          IN  NUMBER,
       p_tax_jurisdiction_id  OUT NOCOPY NUMBER,
       x_return_status        OUT NOCOPY   VARCHAR2) IS

   l_error_buffer    VARCHAR2(200);

   Cursor line_acc_src_tax_rate_id(p_tax_line_id IN NUMBER) is
   select account_source_tax_rate_id
   from   zx_lines
   where  tax_line_id = p_tax_line_id;

   Cursor get_location_id(c_tax_line_id number) is
   SELECT det.ship_to_location_id,det.ship_from_location_id,
          det.bill_to_location_id,det.bill_from_location_id,
    det.internal_organization_id, det.legal_entity_id,
    det.ledger_id, det.application_id, det.entity_code,
    det.event_class_code, det.event_type_code,
    det.ctrl_total_hdr_tx_amt, det.trx_id, det.trx_date,
    det.related_doc_date, det.provnl_tax_determination_date,
    det.trx_currency_code, det.precision,
    det.currency_conversion_type, det.currency_conversion_rate,
    det.currency_conversion_date, 'N' quote_flag,
    det.icx_session_id, det.rdng_ship_to_pty_tx_prof_id,
    det.rdng_ship_from_pty_tx_prof_id, det.rdng_bill_to_pty_tx_prof_id,
    det.rdng_bill_from_pty_tx_prof_id, det.rdng_ship_to_pty_tx_p_st_id,
    det.rdng_ship_from_pty_tx_p_st_id, det.rdng_bill_to_pty_tx_p_st_id,
    det.rdng_bill_from_pty_tx_p_st_id
   FROM zx_lines_det_factors det, zx_lines
   WHERE det.trx_id = zx_lines.trx_id
   and det.trx_line_id = zx_lines.trx_line_id
   and det.application_id = zx_lines.application_id
   and det.entity_code = zx_lines.entity_code
   and det.event_class_code = zx_lines.event_class_code
   and zx_lines.tax_line_id = c_tax_line_id;

   Cursor get_geography_type(c_tax_rate_id number) is
   SELECT zone_geography_type, override_geography_type,
          tax_id, tax, tax_regime_code
   FROM ZX_SCO_TAXES_B_V
   WHERE (tax_regime_code,tax) =
            (SELECT tax_regime_code,tax from ZX_RATES_B
       WHERE tax_rate_id = c_tax_rate_id);

   Cursor is_jurisdiction_acc_appl(c_tax_line_id number) is
   SELECT Count(*)
   FROM zx_lines
   WHERE tax_line_id = c_tax_line_id
   AND tax_provider_id IS NOT NULL;

   Cursor get_geography_use(c_zone_geography_type varchar2,
                            c_override_geo_type varchar2) is
   SELECT geography_type, geography_use, geography_type_num
   FROM
   (SELECT gt.geography_type geography_type,
           gt.geography_use geography_use,
           1 geography_type_num
    FROM  hz_geography_types_b gt
    WHERE gt.geography_type = c_zone_geography_type
    UNION
    SELECT gt.geography_type geography_type,
           gt.geography_use geography_use,
           2 geography_type_num
    FROM  hz_geography_types_b gt
    WHERE gt.geography_type = c_override_geo_type)
   ORDER BY 2 desc;

   l_event_class_rec               ZX_API_PUB.event_class_rec_type;
   l_content_owner_id              NUMBER;
   l_tax_id                        NUMBER;
   l_acc_src_tax_rate_id           NUMBER;
   l_tax_rate_id                   NUMBER;
   l_location_id                   NUMBER;
   l_ship_to_location_id           NUMBER;
   l_ship_from_location_id         NUMBER;
   l_bill_to_location_id           NUMBER;
   l_bill_from_location_id         NUMBER;
   l_place_of_supply_type_code     VARCHAR2(100);
   l_trx_date                      DATE;
   l_location_type                 VARCHAR2(100);
   --l_geography_type                VARCHAR2(100);
   l_tax                           VARCHAR2(100);
   l_tax_regime_code               VARCHAR2(100);
   l_inner_city_jurisdiction_flag  VARCHAR2(1);
   l_geography_id                  NUMBER;
   l_zone_tbl                      HZ_GEO_GET_PUB.zone_tbl_type;
   l_lines_count                   NUMBER;

   x_geography_id                  HZ_GEOGRAPHIES.geography_id%TYPE;
   x_geography_code                HZ_GEOGRAPHIES.geography_code%TYPE;
   x_geography_name                HZ_GEOGRAPHIES.geography_name%TYPE;
   l_geo_use_count                 NUMBER;

   l_zone_geography_type           VARCHAR2(100);
   l_override_geo_type             VARCHAR2(100);

   --l_jursidiction_id_indx          BINARY_INTEGER;
   g_geography_use_info_tbl        ZX_GLOBAL_STRUCTURES_PKG.GEOGRAPHY_USE_INFO_TBL_TYPE;
   i                               NUMBER;
   l_tbl_index                     BINARY_INTEGER;
   l_log_msg                       VARCHAR2(4000);
   l_jurisdiction_found            BOOLEAN;

 BEGIN

   g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  IF (g_level_procedure >= g_current_runtime_level ) THEN

    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID(+)');

  END IF;

  x_return_status := FND_API.G_RET_STS_SUCCESS;
  p_tax_jurisdiction_id := NULL;

  open is_jurisdiction_acc_appl(p_tax_line_id);
  fetch is_jurisdiction_acc_appl into l_lines_count;
  close is_jurisdiction_acc_appl;

  IF l_lines_count = 0 THEN
    IF (g_level_procedure >= g_current_runtime_level ) THEN
       FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'This processing is done only for partner tax calculation, this is not partner processing');
       FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_OUTPUT_TAX_CCID.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID(-)');
    END IF;
    RETURN;
  END IF;

  open get_location_id(p_tax_line_id);
  fetch get_location_id into l_ship_to_location_id, l_ship_from_location_id,
                             l_bill_to_location_id, l_bill_from_location_id,
           l_event_class_rec.internal_organization_id,
           l_event_class_rec.legal_entity_id,
           l_event_class_rec.ledger_id,
           l_event_class_rec.application_id,
           l_event_class_rec.entity_code,
                             l_event_class_rec.event_class_code,
           l_event_class_rec.event_type_code,
                       l_event_class_rec.ctrl_total_hdr_tx_amt,
           l_event_class_rec.trx_id,
           l_trx_date,
                       l_event_class_rec.rel_doc_date,
           l_event_class_rec.provnl_tax_determination_date,
                       l_event_class_rec.trx_currency_code,
           l_event_class_rec.precision,
                       l_event_class_rec.currency_conversion_type,
           l_event_class_rec.currency_conversion_rate,
                       l_event_class_rec.currency_conversion_date,
           l_event_class_rec.quote_flag,
                       l_event_class_rec.icx_session_id,
           l_event_class_rec.rdng_ship_to_pty_tx_prof_id,
                       l_event_class_rec.rdng_ship_from_pty_tx_prof_id,
           l_event_class_rec.rdng_bill_to_pty_tx_prof_id,
                       l_event_class_rec.rdng_bill_from_pty_tx_prof_id,
           l_event_class_rec.rdng_ship_to_pty_tx_p_st_id,
                       l_event_class_rec.rdng_ship_from_pty_tx_p_st_id,
           l_event_class_rec.rdng_bill_to_pty_tx_p_st_id,
                       l_event_class_rec.rdng_bill_from_pty_tx_p_st_id;
  close get_location_id;

  l_event_class_rec.trx_date := l_trx_date;

  init_mand_columns(l_event_class_rec,
                    x_return_status);
  IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
                      'After calling init_mand_columns, x_return_status = '|| x_return_status);
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID.END',
                      'ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID(-)');
      END IF;
      RETURN;
  END IF;

  -- deriving the location_id and location_type
  IF l_ship_to_location_id is not NULL then
    l_location_id := l_ship_to_location_id;
    l_location_type := 'SHIP_TO';
  ELSIF l_bill_to_location_id IS NOT NULL THEN
    l_location_id := l_bill_to_location_id;
    l_location_type := 'BILL_TO';
  ELSIF l_bill_from_location_id IS NOT NULL THEN
    l_location_id := l_bill_from_location_id;
    l_location_type := 'BILL_FROM';
  ELSIF l_ship_from_location_id IS NOT NULL THEN
    l_location_id := l_bill_from_location_id;
    l_location_type := 'SHIP_FROM';
  ELSE
    l_location_id := NULL;
    l_location_type := NULL;
  END IF;

  --l_jursidiction_id_indx := dbms_utility.get_hash_value(to_char(l_location_id)|| l_location_type,1,8192);

  IF l_location_id is not null then

   --IF l_jursidiction_id_tbl.EXISTS(l_jursidiction_id_indx)
   --   AND l_jursidiction_id_tbl(l_jursidiction_id_indx).location_id = l_location_id
   --   AND l_jursidiction_id_tbl(l_jursidiction_id_indx).location_type = l_location_type THEN
   --     p_tax_jurisdiction_id := l_jursidiction_id_tbl(l_jursidiction_id_indx).tax_jurisdiction_id;
   --ELSE
    --fetching the l_acc_src_tax_rate_id for the tax line
    open line_acc_src_tax_rate_id(p_tax_line_id);
    fetch line_acc_src_tax_rate_id into l_acc_src_tax_rate_id;
    close line_acc_src_tax_rate_id;

    IF (g_level_statement >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_statement,
            'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
            'l_acc_src_tax_rate_id: ' || l_acc_src_tax_rate_id);
    END IF;

    -- getting geography type based on the acc_src_tax_rate_id if it is not null
    -- otherwise deriving it from tax_rate_id
    IF l_acc_src_tax_rate_id is not null then
      open get_geography_type(l_acc_src_tax_rate_id);
      fetch get_geography_type into l_zone_geography_type, l_override_geo_type,
                                    l_tax_id, l_tax, l_tax_regime_code;
      close get_geography_type;

    ELSE --l_acc_src_tax_rate_id is null
      open get_geography_type(p_tax_rate_id);
      fetch get_geography_type into l_zone_geography_type, l_override_geo_type,
                                    l_tax_id, l_tax, l_tax_regime_code;
      close get_geography_type;

    END IF; --l_acc_src_tax_rate_id is not null

    --SELECT count(1)
    --INTO   l_geo_use_count
    --FROM   hz_geography_types_b
    --WHERE  geography_type = l_geography_type
    --AND    geography_use <> 'MASTER_REF'
    --AND    rownum = 1;
    BEGIN
      l_tbl_index := dbms_utility.get_hash_value(to_char(l_tax_id) || '1',1,8192);

      IF g_geography_use_info_tbl.EXISTS(l_tbl_index) AND
        g_geography_use_info_tbl(l_tbl_index).tax_id = l_tax_id THEN
        IF (g_level_statement >= g_current_runtime_level ) THEN
          FND_LOG.STRING(g_level_statement,
                         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
                         'Found Geography usage information in cache ');
        END IF;
      ELSE
        IF (l_zone_geography_type IS NOT NULL OR
            l_override_geo_type IS NOT NULL) THEN

          OPEN get_geography_use(l_zone_geography_type, l_override_geo_type);
          FETCH get_geography_use
          BULK COLLECT INTO l_geography_type, l_geography_use, l_geography_type_num;

          FOR i IN NVL(l_geography_type.FIRST,0)..nvl(l_geography_type.LAST,-1) LOOP

            l_tbl_index := dbms_utility.get_hash_value(l_tax_id || to_char(i),1,8192);

            g_geography_use_info_tbl(l_tbl_index).tax_id              := l_tax_id;
            g_geography_use_info_tbl(l_tbl_index).GEOGRAPHY_TYPE_NUM  := i;
            g_geography_use_info_tbl(l_tbl_index).GEOGRAPHY_TYPE      := l_geography_type(i);
            g_geography_use_info_tbl(l_tbl_index).GEOGRAPHY_USE       := l_geography_use(i);
          END LOOP;
        END IF;
      END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
        l_log_msg := 'hz_geography_type: Not Found for Tax';
        FND_LOG.STRING(G_LEVEL_STATEMENT,
                       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
                        l_log_msg);
      END IF;
    END;
    --IF l_geography_type IS NOT NULL THEN
    i := 1;
    l_jurisdiction_found := FALSE;
    WHILE NOT l_jurisdiction_found LOOP
      l_tbl_index := dbms_utility.get_hash_value(l_tax_id || to_char(i),1,8192);
      IF NOT g_geography_use_info_tbl.EXISTS(l_tbl_index) THEN
        EXIT;
      ELSE
      --IF l_geo_use_count = 0 THEN
        IF ( G_LEVEL_STATEMENT >= G_CURRENT_RUNTIME_LEVEL) THEN
          l_log_msg := 'hz_geography_type: out:' ||
                       ', l_geography_type = ' || g_geography_use_info_tbl(l_tbl_index).geography_type ||
                       ', l_geography_use = ' || g_geography_use_info_tbl(l_tbl_index).geography_use;
          FND_LOG.STRING(G_LEVEL_STATEMENT,
                         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
                         l_log_msg);
        END IF;
        IF g_geography_use_info_tbl(l_tbl_index).geography_use = 'MASTER_REF' THEN
          ZX_TCM_GEO_JUR_PKG.get_master_geography(
                              l_location_id,
                              l_location_type,
                              g_geography_use_info_tbl(l_tbl_index).geography_type,
                              x_geography_id,
                              x_geography_code,
                              x_geography_name,
                              x_return_status);
          IF x_return_status <> FND_API.G_RET_STS_SUCCESS  THEN
            IF (g_level_statement >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
                   'Incorrect return_status after calling ' ||
                   'ZX_TCM_GEO_JUR_PKG.get_master_geography');
              FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
                   'RETURN_STATUS = ' || x_return_status);
              FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID.END',
                   'ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID(-)');
           END IF;
           RETURN;
          ELSE
            IF x_geography_id IS NOT NULL THEN
              l_geography_id := x_geography_id;
              BEGIN
                SELECT tax_jurisdiction_id
                INTO p_tax_jurisdiction_id
                FROM   zx_jurisdictions_b
                WHERE  effective_from <= l_trx_date
                AND    (effective_to >= l_trx_date or effective_to is null)
                AND    tax = l_tax
                AND    tax_regime_code = l_tax_regime_code
                AND    zone_geography_id = l_geography_id
                AND    (nvl(inner_city_jurisdiction_flag,'xx') = nvl(l_inner_city_jurisdiction_flag, 'xx') OR
                       (inner_city_jurisdiction_flag is null and l_inner_city_jurisdiction_flag is not null) OR
                       (inner_city_jurisdiction_flag is not null and l_inner_city_jurisdiction_flag is null));
                --tax jurisdiction is found.
                IF p_tax_jurisdiction_id IS NOT NULL THEN
                  l_jurisdiction_found := TRUE;
                END IF;
              EXCEPTION
                WHEN OTHERS THEN
                  NULL;
              END;
            END IF;
          END IF;
        ELSIF g_geography_use_info_tbl(l_tbl_index).geography_use = 'TAX' THEN
          ZX_TCM_GEO_JUR_PKG.get_zone(
                               l_location_id,
                               l_location_type,
                               g_geography_use_info_tbl(l_tbl_index).geography_type,
                               l_trx_date,
                               l_zone_tbl,
                               -----l_geography_id(i),
                               x_return_status);
          IF x_return_status <> FND_API.G_RET_STS_SUCCESS  THEN
            IF (g_level_statement >= g_current_runtime_level ) THEN
              FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
                   'Incorrect return_status after calling ' ||
                   'ZX_TCM_GEO_JUR_PKG.get_zone');
              FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
                   'RETURN_STATUS = ' || x_return_status);
              FND_LOG.STRING(g_level_statement,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID.END',
                   'ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID(-)');
            END IF;
            RETURN;
          ELSE
            IF l_zone_tbl.count > 0 THEN
              FOR j in l_zone_tbl.first..l_zone_tbl.last LOOP
                l_geography_id := l_zone_tbl(j).zone_id;
                BEGIN
                  SELECT tax_jurisdiction_id
                  INTO p_tax_jurisdiction_id
                  FROM   zx_jurisdictions_b
                  WHERE  effective_from <= l_trx_date
                  AND    (effective_to >= l_trx_date or effective_to is null)
                  AND    tax = l_tax
                  AND    tax_regime_code = l_tax_regime_code
                  AND    zone_geography_id = l_geography_id
                  AND    (nvl(inner_city_jurisdiction_flag,'xx') = nvl(l_inner_city_jurisdiction_flag, 'xx') OR
                         (inner_city_jurisdiction_flag is null and l_inner_city_jurisdiction_flag is not null) OR
                         (inner_city_jurisdiction_flag is not null and l_inner_city_jurisdiction_flag is null));
                  -- tax jurisdiction found.
                  IF p_tax_jurisdiction_id IS NOT NULL THEN
                    l_jurisdiction_found := TRUE;
                    EXIT; --to exit from FOR j in l_zone_tbl.first..l_zone_tbl.last LOOP
                  END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                END;
              END LOOP; --j in l_zone_tbl.first..l_zone_tbl.last LOOP
            END IF; --l_zone_tbl.count > 0 THEN
          END IF; --x_return_status <> FND_API.G_RET_STS_SUCCESS
        END IF; --g_geography_use_info_tbl(l_tbl_index).geography_use = 'MASTER_REF' THEN
      END IF; --NOT g_geography_use_info_tbl.EXISTS(l_tbl_index) THEN
      i := i + 1;
    END LOOP; --WHILE NOT l_jurisdiction_found LOOP
      --END IF;
    --END IF;
  END IF; --l_location_id is not null

  --l_jursidiction_id_tbl(l_jursidiction_id_indx).location_id := l_location_id;
  --l_jursidiction_id_tbl(l_jursidiction_id_indx).location_type := l_location_type;
 -- l_jursidiction_id_tbl(l_jursidiction_id_indx).tax_jurisdiction_id := p_tax_jurisdiction_id;

 --END IF; -- caching end

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
       'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID.END',
       'ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID(-)');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    l_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
          l_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID.END',
         'ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID(-)');
      END IF;

END get_tax_jurisdiction_id;

PROCEDURE init_mand_columns(
             p_event_class_rec   IN OUT NOCOPY  ZX_API_PUB.event_class_rec_type,
       x_return_status        OUT NOCOPY   VARCHAR2) IS

   l_error_buffer    VARCHAR2(200);
BEGIN

  g_current_runtime_level := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
  x_return_status := FND_API.G_RET_STS_SUCCESS;

  IF (g_level_procedure >= g_current_runtime_level ) THEN
    FND_LOG.STRING(g_level_procedure,
                   'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.INIT_MAND_COLUMNS.BEGIN',
                   'ZX_TRD_SERVICES_PUB_PKG.INIT_MAND_COLUMNS(+)');
  END IF;

  SELECT ZX_LINES_DET_FACTORS_S.nextval
  INTO p_event_class_rec.event_id
  FROM DUAL;


  IF p_event_class_rec.trx_currency_code IS NOT NULL
  AND p_event_class_rec.precision IS NOT NULL THEN
     p_event_class_rec.header_level_currency_flag := 'Y';
  END IF;

  IF p_event_class_rec.QUOTE_FLAG = 'Y' and
    p_event_class_rec.ICX_SESSION_ID IS NOT NULL THEN
    ZX_SECURITY.G_ICX_SESSION_ID := p_event_class_rec.ICX_SESSION_ID;
    ZX_SECURITY.name_value('SESSIONID',to_char(ZX_SECURITY.G_ICX_SESSION_ID));
    -- dbms_session.set_context('my_ctx','SESSIONID',to_char(ZX_SECURITY.G_ICX_SESSION_ID));
  ELSE
    ZX_SECURITY.G_ICX_SESSION_ID := null;
    -- dbms_session.set_context('my_ctx','SESSIONID',to_char(ZX_SECURITY.G_ICX_SESSION_ID));
    ZX_SECURITY.name_value('SESSIONID',to_char(ZX_SECURITY.G_ICX_SESSION_ID));
  END IF;
  IF ZX_API_PUB.G_DATA_TRANSFER_MODE <> 'TAB' THEN
    ZX_VALID_INIT_PARAMS_PKG.calculate_tax(x_return_status   => x_return_status,
                                           p_event_class_rec => p_event_class_rec);

    IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      IF (g_level_statement >= g_current_runtime_level ) THEN
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.INIT_MAND_COLUMNS',
                      'After calling calculate_tax, x_return_status = '|| x_return_status);
        FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.INIT_MAND_COLUMNS.END',
                      'ZX_TRD_SERVICES_PUB_PKG.INIT_MAND_COLUMNS(-)');
      END IF;
    END IF;
  ELSE
    ZX_VALID_INIT_PARAMS_PKG.import_document_with_tax(x_return_status   => x_return_status,
                                                        p_event_class_rec => p_event_class_rec);
      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        IF (g_level_statement >= g_current_runtime_level ) THEN
           FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.INIT_MAND_COLUMNS',
                      'After calling import_document_with_tax, x_return_status = '|| x_return_status);
           FND_LOG.STRING(g_level_statement,
                      'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.INIT_MAND_COLUMNS.END',
                      'ZX_TRD_SERVICES_PUB_PKG.INIT_MAND_COLUMNS(-)');
        END IF;
      END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
    l_error_buffer  := sqlcode || ': ' || SUBSTR(SQLERRM, 1, 80);

    IF (g_level_unexpected >= g_current_runtime_level ) THEN
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID',
          l_error_buffer);
      FND_LOG.STRING(g_level_unexpected,
         'ZX.PLSQL.ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID.END',
         'ZX_TRD_SERVICES_PUB_PKG.GET_TAX_JURISDICTION_ID(-)');
    END IF;
END init_mand_columns;

-- Constructor
BEGIN

  l_regime_not_effective        :=fnd_message.get_string('ZX','ZX_REGIME_NOT_EFFECTIVE' );
  l_tax_not_effective           :=fnd_message.get_string('ZX','ZX_TAX_NOT_EFFECTIVE' );
  l_tax_status_not_effective    :=fnd_message.get_string('ZX','ZX_TAX_STATUS_NOT_EFFECTIVE' );
  l_tax_rate_not_effective      :=fnd_message.get_string('ZX','ZX_TAX_RATE_NOT_EFFECTIVE' );
  l_tax_rate_not_active         :=fnd_message.get_string('ZX','ZX_TAX_RATE_NOT_ACTIVE' );
  l_tax_rate_percentage_invalid :=fnd_message.get_string('ZX','ZX_TAX_RATE_PERCENTAGE_INVALID' );
  l_jur_code_not_effective      :=fnd_message.get_string('ZX','ZX_JUR_CODE_NOT_EFFECTIVE' );

END ZX_TRD_SERVICES_PUB_PKG ;
/
SHOW ERROR