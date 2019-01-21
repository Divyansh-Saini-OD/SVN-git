create or replace
PACKAGE XX_CDH_GP_DATA_AOPS AS

g_limit	 NUMBER :=  500;

PROCEDURE Populate_gp_data ( x_errbuf              OUT NOCOPY VARCHAR2
                            ,x_retcode             OUT NOCOPY VARCHAR2
                       ) ;
END XX_CDH_GP_DATA_AOPS ;
/