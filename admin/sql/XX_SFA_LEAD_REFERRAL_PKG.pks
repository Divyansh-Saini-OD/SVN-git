-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                     Wipro Technologies                                |
-- +=======================================================================+
-- | Name             :XX_SFA_LEAD_REFERRAL_PKG.pks                       |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- |1.1      06-MAr-2008 Rizwan Appees      Restructuring the code         |
-- |1.2      28-Apr-2008 Sreekanth          Added RSD wave logic           |
-- |1.3      28-Apr-2008 Rizwan             Formatted the code             |
-- +=======================================================================+

CREATE OR REPLACE PACKAGE xx_sfa_lead_referral_pkg
AS
-- +===================================================================+
-- | Name             : GET_BATCH_ID                                   |
-- | Description      : This procedure call api to generate Batch ID.  |
-- |                                                                   |
-- | Parameters :      p_process_name                                  |
-- |                   p_group_id                                      |
-- |                   x_batch_descr                                   |
-- |                   x_batch_id                                      |
-- |                   x_error_msg                                     |
-- +===================================================================+

  PROCEDURE get_batch_id(p_process_name  IN VARCHAR2
                        ,p_group_id  IN VARCHAR2
                        ,x_batch_descr  OUT VARCHAR2
                        ,x_batch_id  OUT VARCHAR2
                        ,x_error_msg  OUT VARCHAR2);
  -- +===================================================================+
  -- | Name             : VALIDATE_DATA                                  |
  -- | Description      : This procedure extract eligible lead line and  |
  -- |                    validate the input data.                       |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- +===================================================================+
  
  PROCEDURE validate_data(x_errbuf  OUT NOCOPY VARCHAR2
                         ,x_retcode  OUT NOCOPY NUMBER);
  -- +===================================================================+
  -- | Name             : LOAD_PROSPECTS                                 |
  -- | Description      : This procedure load extracted data into common |
  -- |                    view tables to create prospect.                |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                   p_batch_id                                      |
  -- +===================================================================+
  
  PROCEDURE load_prospects(x_errbuf  OUT NOCOPY VARCHAR2
                          ,x_retcode  OUT NOCOPY NUMBER
                          ,p_batch_id  IN NUMBER);
  -- +===================================================================+
  -- | Name             : LOAD_CONTACTS                                  |
  -- | Description      : This procedure load extracted data into common |
  -- |                    view tables to create contacts.                |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                   p_batch_id                                      |
  -- +===================================================================+
  
  PROCEDURE load_contacts(x_errbuf  OUT NOCOPY VARCHAR2
                         ,x_retcode  OUT NOCOPY NUMBER
                         ,p_batch_id  IN NUMBER);
  -- +===================================================================+
  -- | Name             : LOAD_LEADS                                     |
  -- | Description      : This procedure load extracted data into        |
  -- |                    interface tables to create Leads.              |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                   p_batch_id                                      |
  -- +===================================================================+
  
  PROCEDURE load_leads(x_errbuf  OUT NOCOPY VARCHAR2
                      ,x_retcode  OUT NOCOPY NUMBER
                      ,p_batch_id  IN NUMBER);
  -- +===================================================================+
  -- | Name             : SUBMIT_REQUEST_SET                             |
  -- | Description      : This procedure calls request set that contains |
  -- |                    program to load prospect, contact and leads    |
  -- |                    into oracle base tables.                       |
  -- |                                                                   |
  -- | Parameters :      x_errbuf                                        |
  -- |                   x_retcode                                       |
  -- |                   p_batch_id                                      |
  -- +===================================================================+
  
  PROCEDURE submit_request_set(x_errbuf  OUT NOCOPY VARCHAR2
                              ,x_retcode  OUT NOCOPY NUMBER
                              ,p_batch_id  IN NUMBER);
  -- +===================================================================+
  -- | Name             : SUBMIT_PARTY_SITE_MASS_ASSGN                   |
  -- | Description      : This procedure submits the Mass Assignments    |
  -- |                    Program.                                       |
  -- |                                                                   |
  -- | Parameters :      p_from_party_site_id                            |
  -- |                   p_to_party_site_id                              |
  -- +===================================================================+
  
  PROCEDURE submit_party_site_mass_assgn(p_from_party_site_id  NUMBER
                             ,p_to_party_site_id  NUMBER);
  -- +===================================================================+
  -- | Name             : SUBMIT_LEAD_MASS_ASSGN                         |
  -- | Description      : This procedure submits the Mass Assignments    |
  -- |                    Program.                                       |
  -- |                                                                   |
  -- | Parameters :      p_from_sales_lead_id                            |
  -- |                   p_to_sales_lead_id                              |
  -- +===================================================================+
  
  PROCEDURE submit_lead_mass_assgn(p_from_sales_lead_id  NUMBER
                                  ,p_to_sales_lead_id  NUMBER);

END xx_sfa_lead_referral_pkg;
/