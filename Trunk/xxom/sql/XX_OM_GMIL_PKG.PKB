CREATE OR REPLACE PACKAGE BODY XX_OM_GMIL_PKG AS

  PROCEDURE insert_file(
                            p_country         IN VARCHAR2
                          , p_lang            IN VARCHAR2
                          , p_brand           IN VARCHAR2
                          , p_html_file       IN BLOB
                          , p_cost_center     IN VARCHAR2
                          , p_date_created    IN DATE
                          , p_updated_user    IN VARCHAR2
                          , p_status          IN VARCHAR2)

   IS

  BEGIN

    INSERT INTO XX_HZ_GMIL_BANNER(
                                   country
                                 , lang
                                 , brand
                                 , html_file
                                 , cost_center
                                 , date_created
                                 , updated_user
                                 , status
                                 ) VALUES (
                                   p_country
                                 , p_lang
                                 , p_brand
                                 , p_html_file
                                 , p_cost_center
                                 , p_date_created
                                 , p_updated_user
                                 , p_status
                                 );

    COMMIT;

  EXCEPTION

    WHEN others THEN

      ROLLBACK;

END insert_file;

END XX_OM_GMIL_PKG;
/