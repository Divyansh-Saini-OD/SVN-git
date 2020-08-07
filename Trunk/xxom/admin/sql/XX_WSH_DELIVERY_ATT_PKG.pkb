SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_wsh_delivery_attributes_pkg

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                 Oracle NAIO Consulting Organization               |
-- +===================================================================+
-- | Name         :xx_wsh_delivery_attributes_pkg                       |
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
-- |DRAFT 1A  12-JUL-2007 Milin Rane       Initial draft version       |
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
    lc_return_status       VARCHAR2(40)   := FND_API.G_RET_STS_SUCCESS;
    lt_gl_exception  xx_om_report_exception_t := xx_om_report_exception_t( 'OTHERS'
                                                                     ,'OTC'
                                                                     ,'ATTRIBUTES_SETUP'
                                                                     ,'DELIVERY_ATTRIBUTES'
                                                                     ,NULL
                                                                     ,NULL
                                                                     ,'DELIVERY_ID'
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
-- |               xx_wsh_delivery_att_all table                 |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
  PROCEDURE insert_row (  x_return_status          IN OUT NOCOPY VARCHAR2
                         ,x_errbuf                 IN OUT NOCOPY VARCHAR2
                         ,p_delivery_attributes    IN xxom.xx_wsh_delivery_att_t
                     ) IS

    lc_errbuf              VARCHAR2(1000) :='Success';
    lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;

  BEGIN

    INSERT INTO xx_wsh_delivery_att_all
             (   delivery_id
               , od_internal_delivery_status
               , redelivery_flag
               , del_backtoback_ind
               , no_of_shiplabels
               , new_sch_ship_date
               , new_sch_arr_date
               , actual_deliverd_date
               , new_del_date_from_time
               , new_del_date_to_time
               , delivery_cancelled_ind
               , delivery_trans_ind
               , pod_exceptions_comments
               , retransmit_pick_ticket
               , payment_subtype_cod_ind
               , del_to_post_office_ind
               , creation_date
               , created_by
               , last_update_date
               , last_updated_by
               , last_update_login
              )
       VALUES (  p_delivery_attributes.delivery_id
               , p_delivery_attributes.od_internal_delivery_status
               , p_delivery_attributes.redelivery_flag
               , p_delivery_attributes.del_backtoback_ind
               , p_delivery_attributes.no_of_shiplabels
               , p_delivery_attributes.new_sch_ship_date
               , p_delivery_attributes.new_sch_arr_date
               , p_delivery_attributes.actual_deliverd_date
               , p_delivery_attributes.new_del_date_from_time
               , p_delivery_attributes.new_del_date_to_time
               , p_delivery_attributes.delivery_cancelled_ind
               , p_delivery_attributes.delivery_trans_ind
               , p_delivery_attributes.pod_exceptions_comments
               , p_delivery_attributes.retransmit_pick_ticket
               , p_delivery_attributes.payment_subtype_cod_ind
               , p_delivery_attributes.del_to_post_office_ind
               , p_delivery_attributes.creation_date
               , p_delivery_attributes.created_by
               , p_delivery_attributes.last_update_date
               , p_delivery_attributes.last_updated_by
               , p_delivery_attributes.last_update_login
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
                       ,p_entity_ref_id     => p_delivery_attributes.delivery_id
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
-- |               xx_wsh_delivery_att_all table for update      |
-- |                                                                   |
-- +===================================================================+


  PROCEDURE lock_row ( x_return_status          IN OUT NOCOPY VARCHAR2
                      ,x_errbuf                 IN OUT NOCOPY VARCHAR2
                      ,p_delivery_attributes    IN xxom.xx_wsh_delivery_att_t
                     ) IS

    ln_delivery_id         NUMBER;
    lc_errbuf              VARCHAR2(1000) :='Success';
    lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;

  BEGIN
    SAVEPOINT lock_row;

    SELECT XODA.delivery_id
      INTO ln_delivery_id
      FROM   xx_wsh_delivery_att_all XODA
     WHERE  XODA.delivery_id = p_delivery_attributes.delivery_id
     FOR UPDATE NOWAIT;

    x_return_status := lc_return_status ;
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
                       ,p_entity_ref_id     => p_delivery_attributes.delivery_id
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
-- |               xx_om_delivery_details_attributes_all table         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


  PROCEDURE update_row (x_return_status          IN OUT NOCOPY VARCHAR2
                       ,x_errbuf                 IN OUT NOCOPY VARCHAR2
                       ,p_delivery_attributes    IN xxom.xx_wsh_delivery_att_t
                     )IS

    lc_errbuf              VARCHAR2(1000) :='Success';
    lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;

  BEGIN

    UPDATE xx_wsh_delivery_att_all XODA
       SET   XODA.od_internal_delivery_status  = p_delivery_attributes.od_internal_delivery_status
           , XODA.redelivery_flag              = p_delivery_attributes.redelivery_flag
           , XODA.del_backtoback_ind           = p_delivery_attributes.del_backtoback_ind
           , XODA.no_of_shiplabels             = p_delivery_attributes.no_of_shiplabels
           , XODA.new_sch_ship_date            = p_delivery_attributes.new_sch_ship_date
           , XODA.new_sch_arr_date             = p_delivery_attributes.new_sch_arr_date
           , XODA.actual_deliverd_date         = p_delivery_attributes.actual_deliverd_date
           , XODA.new_del_date_from_time       = p_delivery_attributes.new_del_date_from_time
           , XODA.new_del_date_to_time         = p_delivery_attributes.new_del_date_to_time
           , XODA.delivery_cancelled_ind       = p_delivery_attributes.delivery_cancelled_ind
           , XODA.delivery_trans_ind           = p_delivery_attributes.delivery_trans_ind
           , XODA.pod_exceptions_comments      = p_delivery_attributes.pod_exceptions_comments
           , XODA.retransmit_pick_ticket       = p_delivery_attributes.retransmit_pick_ticket
           , XODA.payment_subtype_cod_ind      = p_delivery_attributes.payment_subtype_cod_ind
           , XODA.del_to_post_office_ind       = p_delivery_attributes.del_to_post_office_ind
           , XODA.creation_date                = p_delivery_attributes.creation_date
           , XODA.created_by                   = p_delivery_attributes.created_by
           , XODA.last_update_date             = p_delivery_attributes.last_update_date
           , XODA.last_updated_by              = p_delivery_attributes.last_updated_by
           , XODA.last_update_login            = p_delivery_attributes.last_update_login
    WHERE  delivery_id                    = p_delivery_attributes.delivery_id
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
                       ,p_entity_ref_id     => p_delivery_attributes.delivery_id
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
                     ,p_delivery_id            IN NUMBER
                     )IS

 lc_errbuf              VARCHAR2(1000) :='Success';
 lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;

BEGIN
  DELETE FROM xx_wsh_delivery_att_all XODA
  WHERE XODA.delivery_id  = p_delivery_id;

  x_return_status := lc_return_status;
  x_errbuf        := lc_errbuf;

EXCEPTION
  WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN
    FND_MESSAGE.SET_NAME('ONT','OE_LOCK_ROW_ALREADY_LOCKED');

    write_exception (p_error_code        => 'OE_LOCK_ROW_ALREADY_LOCKED'
                    ,p_error_description => FND_MESSAGE.GET
                    ,p_entity_ref_id     => p_delivery_id
                    ,x_return_status     => x_return_status
                    ,x_errbuf            => x_errbuf);

    IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

      x_return_status  := FND_API.G_RET_STS_ERROR;
      x_errbuf         := SUBSTR(FND_MESSAGE.GET,1,1000);

    END IF;

  WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
    FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
    FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

    -- Call the write_exception procedure to insert into Global exception table
    write_exception ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                     ,p_error_description => FND_MESSAGE.GET
                     ,p_entity_ref_id     => p_delivery_id
                     ,x_return_status     => x_return_status
                     ,x_errbuf            => x_errbuf);

    IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN

      x_return_status  := FND_API.G_RET_STS_ERROR;
      x_errbuf         := SUBSTR(FND_MESSAGE.GET,1,1000);

    END IF;

END delete_row;

END xx_wsh_delivery_attributes_pkg;
/

SHOW ERRORS

