SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_wsh_delivery_det_att_pkg

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                 Oracle NAIO Consulting Organization               |
-- +===================================================================+
-- | Name         :XX_WSH_DELIVERY_DET_ATT_PKG               |
-- | Rice Id      : E1334_OM_Attributes_Setup                          |
-- | Description  :This package body is used to Insert, Update         |
-- |               Delete, Lock rows of XX_PO_MLSS_DET Table           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  06-JUL-2007 Milind Rane      Initial draft version       |
-- |                                                                   |
-- +===================================================================+
AS


  -- +===================================================================+
-- | Name  : WRITE_EXCEPTION                                           |
-- | Description:  This procedure is used to invoke Global Exceptions  |
-- |               API xx_om_global_exception_pkg.insert_exception     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
  PROCEDURE write_exception ( p_error_code        IN VARCHAR2
                             ,p_error_description IN VARCHAR2
                             ,p_entity_ref_id     IN NUMBER
                             ,x_return_status     IN OUT NOCOPY VARCHAR2
                             ,x_errbuf            IN OUT NOCOPY VARCHAR2) IS

    lc_errbuf              VARCHAR2(1000) :='Success';
    lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;
    lt_gl_exception  xx_om_report_exception_t := xx_om_report_exception_t( 'OTHERS'
                                                                          ,'OTC'
                                                                          ,'ATTRIBUTES_SETUP'
                                                                          ,'DELIVERY_DETAILS_ATTRIBUTES'
                                                                          ,NULL
                                                                          ,NULL
                                                                          ,'DELIVERY_DETAIL_ID'
                                                                          ,NULL
                                                                         );

  BEGIN

    lt_gl_exception.p_error_code        := p_error_code;
    lt_gl_exception.p_error_description := p_error_description;
    lt_gl_exception.p_entity_ref_id     := p_entity_ref_id;

    -- Call the global exception package to insert the exceptions
    xx_om_global_exception_pkg.Insert_Exception ( lt_gl_exception
                                                 ,lc_errbuf
                                                 ,lc_return_status
                                             );

    x_return_status := lc_return_status;
    x_errbuf        := lc_errbuf;

  EXCEPTION
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
      x_return_status  := FND_API.G_RET_STS_ERROR;
      x_errbuf         := SUBSTR(FND_MESSAGE.GET,1,1000);

  END write_exception;

-- +===================================================================+
-- | Name  : INSERT_ROW                                                |
-- | Description:  This procedure is used to insert the rows into      |
-- |               xx_wsh_delivery_det_att_all table                 |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
  PROCEDURE insert_row (  x_return_status        IN OUT NOCOPY VARCHAR2
                         ,x_errbuf            IN OUT NOCOPY VARCHAR2
                         ,p_delivery_details_attributes    IN xx_wsh_delivery_det_att_t
                     ) IS

    lc_errbuf              VARCHAR2(1000) :='Success';
    lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;


  BEGIN

    INSERT INTO xx_wsh_delivery_det_att_all
             (   delivery_detail_id
               , pkt_transmission_ind
               , del_creation_ind
               , old_delivery_number
               , backtoback_del_creation_ind
               , lpn_length
               , lpn_width
               , lpn_height
               , lpn_type
               , creation_date
               , created_by
               , last_update_date
               , last_updated_by
               , last_update_login
              )
       VALUES (  p_delivery_details_attributes.delivery_detail_id
               , p_delivery_details_attributes.pkt_transmission_ind
               , p_delivery_details_attributes.del_creation_ind
               , p_delivery_details_attributes.old_delivery_number
               , p_delivery_details_attributes.backtoback_del_creation_ind
               , p_delivery_details_attributes.lpn_length
               , p_delivery_details_attributes.lpn_width
               , p_delivery_details_attributes.lpn_height
               , p_delivery_details_attributes.lpn_type
               , p_delivery_details_attributes.creation_date
               , p_delivery_details_attributes.created_by
               , p_delivery_details_attributes.last_update_date
               , p_delivery_details_attributes.last_updated_by
               , p_delivery_details_attributes.last_update_login
              );

     x_return_status := lc_return_status;
     x_errbuf        := lc_errbuf;

  EXCEPTION
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      -- Call the write_exception procedure to insert into Global exception table
      write_exception ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                       ,p_error_description => FND_MESSAGE.GET
                       ,p_entity_ref_id     => p_delivery_details_attributes.delivery_detail_id
                       ,x_return_status     => x_return_status
                       ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_errbuf         := SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;

  END insert_row;

-- +===================================================================+
-- | Name  : LOCK_ROW                                                  |
-- | Description:  This procedure is used to lock the rows of          |
-- |               xx_wsh_delivery_det_att_all table for update      |
-- |                                                                   |
-- +===================================================================+


  PROCEDURE lock_row ( x_return_status        IN OUT NOCOPY VARCHAR2
                      ,x_errbuf            IN OUT NOCOPY VARCHAR2
                      ,p_delivery_details_attributes    IN xx_wsh_delivery_det_att_t
                     ) IS

    ln_delivery_detail_id  NUMBER;
    lc_errbuf              VARCHAR2(1000) :='Success';
    lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;

  BEGIN

    SAVEPOINT lock_row;

    SELECT delivery_detail_id
      INTO ln_delivery_detail_id
      FROM xx_wsh_delivery_det_att_all XODDA
     WHERE  XODDA.delivery_detail_id = p_delivery_details_attributes.delivery_detail_id
       FOR UPDATE NOWAIT;

     x_return_status := lc_return_status;
     x_errbuf        := lc_errbuf;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK to SAVEPOINT lock_row;
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      -- Call the write_exception procedure to insert into Global exception table
      write_exception ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                       ,p_error_description => FND_MESSAGE.GET
                       ,p_entity_ref_id     => p_delivery_details_attributes.delivery_detail_id
                       ,x_return_status     => x_return_status
                       ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_errbuf         := SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;


  END lock_row;

-- +===================================================================+
-- | Name  : UPDATE_ROW                                                |
-- | Description:  This procedure is used to update the rows of        |
-- |               xx_wsh_delivery_det_att_all table                                |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


  PROCEDURE update_row (x_return_status        IN OUT NOCOPY VARCHAR2
                       ,x_errbuf            IN OUT NOCOPY VARCHAR2
                       ,p_delivery_details_attributes    IN xx_wsh_delivery_det_att_t
                     )IS

    lc_errbuf              VARCHAR2(1000) :='Success';
    lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;

  BEGIN

    UPDATE xx_wsh_delivery_det_att_all XODDA
       SET   XODDA.pkt_transmission_ind         = p_delivery_details_attributes.pkt_transmission_ind
           , XODDA.del_creation_ind             = p_delivery_details_attributes.del_creation_ind
           , XODDA.old_delivery_number          = p_delivery_details_attributes.old_delivery_number
           , XODDA.backtoback_del_creation_ind  = p_delivery_details_attributes.backtoback_del_creation_ind
           , XODDA.lpn_length                   = p_delivery_details_attributes.lpn_length
           , XODDA.lpn_width                    = p_delivery_details_attributes.lpn_width
           , XODDA.lpn_height                   = p_delivery_details_attributes.lpn_height
           , XODDA.lpn_type                     = p_delivery_details_attributes.lpn_type
           , XODDA.creation_date                = p_delivery_details_attributes.creation_date
           , XODDA.created_by                   = p_delivery_details_attributes.created_by
           , XODDA.last_update_date             = p_delivery_details_attributes.last_update_date
           , XODDA.last_updated_by              = p_delivery_details_attributes.last_updated_by
           , XODDA.last_update_login            = p_delivery_details_attributes.last_update_login
    WHERE  XODDA.delivery_detail_id           = p_delivery_details_attributes.delivery_detail_id
    ;

     x_return_status := lc_return_status;
     x_errbuf        := lc_errbuf;

  EXCEPTION
    WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      -- Call the write_exception procedure to insert into Global exception table
      write_exception ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                       ,p_error_description => FND_MESSAGE.GET
                       ,p_entity_ref_id     => p_delivery_details_attributes.delivery_detail_id
                       ,x_return_status     => x_return_status
                       ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_errbuf         := SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;

  END update_row;

-- +===================================================================+
-- | Name  : DELETE_ROW                                                |
-- | Description:  This procedure is used to delete the rows from      |
-- |               XX_PO_MLSS_DET table                                |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_mlss_header_id                               |
-- |                    p_mlss_line_id                                 |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE delete_row (x_return_status          IN OUT NOCOPY VARCHAR2
                     ,x_errbuf                 IN OUT NOCOPY VARCHAR2
                     ,p_delivery_detail_id     IN NUMBER
                     )IS

    lc_errbuf              VARCHAR2(1000) :='Success';
    lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;

BEGIN
  DELETE FROM xx_wsh_delivery_det_att_all XODDA
  WHERE XODDA.delivery_detail_id  = p_delivery_detail_id;

  x_return_status := lc_return_status;
  x_errbuf        := lc_errbuf;

EXCEPTION
  WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN
    FND_MESSAGE.SET_NAME('ONT','OE_LOCK_ROW_ALREADY_LOCKED');
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_errbuf  :=SUBSTR(SQLERRM,1,1000);

    write_exception (p_error_code        => 'OE_LOCK_ROW_ALREADY_LOCKED'
                    ,p_error_description => FND_MESSAGE.GET
                    ,p_entity_ref_id     => p_delivery_detail_id
                    ,x_return_status     => x_return_status
                    ,x_errbuf            => x_errbuf);

  WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      -- Call the write_exception procedure to insert into Global exception table
      write_exception ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                       ,p_error_description => FND_MESSAGE.GET
                       ,p_entity_ref_id     => p_delivery_detail_id
                       ,x_return_status     => x_return_status
                       ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

        x_return_status  := FND_API.G_RET_STS_ERROR;
        x_errbuf         := SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;

END delete_row;

END xx_wsh_delivery_det_att_pkg;
/

SHOW ERRORS

