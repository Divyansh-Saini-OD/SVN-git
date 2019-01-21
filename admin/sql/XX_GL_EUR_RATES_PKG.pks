CREATE OR REPLACE PACKAGE APPS.XX_GL_EUR_RATES_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_GL_EUR_RATES_PKG                                |
-- | Description      :    Package for send Euro rates to Europe IT Team      |
-- | RICE             :    I2122                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      3-Nov-2013   Paddy Sanjeevi      Defect 25578                   |
-- +==========================================================================+

    PROCEDURE send_rates          ( p_errbuf   		IN OUT    VARCHAR2
                                   ,p_retcode  		IN OUT    NUMBER
                                   ,p_date 	 	IN 	  VARCHAR2
                                  );

END XX_GL_EUR_RATES_PKG;
/
