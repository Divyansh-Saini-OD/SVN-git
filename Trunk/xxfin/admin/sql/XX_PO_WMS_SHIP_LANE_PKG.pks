create or replace
PACKAGE XX_PO_WMS_SHIP_LANE_PKG AS
PROCEDURE Process_Shiplane(
      x_retcode           OUT NOCOPY  NUMBER
    , x_errbuf            OUT NOCOPY  VARCHAR2
    , p_filepath          IN          VARCHAR2
    , p_filename          IN          VARCHAR2);
END;

/
