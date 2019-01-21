create or replace package XX_CRM_INACTIVATE_PROSPECTS
as
  procedure main (
                   errbuf       OUT NOCOPY VARCHAR2
                 , retcode      OUT NOCOPY VARCHAR2
				 , p_batch_size IN         NUMBER   DEFAULT 10000
				 , p_debug      IN         VARCHAR2 DEFAULT 'Y'
				 );
				 
end XX_CRM_INACTIVATE_PROSPECTS;
/
