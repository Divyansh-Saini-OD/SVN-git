SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF 
SET FEEDBACK OFF
SET TERM ON  

PROMPT Creating Package BODY XX_IEX_DEL_WRAP_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE 
PACKAGE BODY XX_IEX_DEL_WRAP_PKG
AS
 -- +==================================================================+
 -- |                  Office Depot - Project Simplify                 |
 -- |                       WIPRO Technologies                         |
 -- +==================================================================+
 -- | Name :    XX_IEX_DEL_WRAP_PKG                                    |
 -- | RICE :    E0984                                                  |
 -- | Description : This package submits 'OD:IEX Bulk XML              |
 -- |               Delivery Manager Wrapper'Program and it            |
 -- |               submits the IEX_BULK_XML_DELIVERY procedure which  |
 -- |               inturn submits the Standard 'IEX: Bulk XML         |
 -- |               Delivery Manager                                   |
 -- |Change Record:                                                    |
 -- |===============                                                   |
 -- |Version   Date          Author              Remarks               |
 -- |=======   ==========   =============        ======================|
 -- |1.0       17-JUN-10    Poornimadevi R       Initial version       |
 -- |1.1       02-AUG-10    Poornimadevi R       Modified for          |
 -- |                                            Defect#6451           |
 -- +==================================================================+
 -- +==================================================================+
 -- | Name        : IEX_BULK_XML_DELIVERY                              |
 -- | Description : The procedure submits standard 'IEX: Bulk XML      |
 -- |                Delivery Manager' program from the wrapper        |
 -- |                                                                  |
 -- |Change Record:                                                    |
 -- |===============                                                   |
 -- |Version   Date          Author              Remarks               |
 -- |=======   ==========   =============        ======================|
 -- |1.0       17-JUN-10    Poornimadevi R       Initial version       |
 -- |                                                                  |
 -- +==================================================================+

    PROCEDURE IEX_BULK_XML_DELIVERY  (  x_errbuf         OUT NOCOPY      VARCHAR2
                                       ,x_retcode        OUT NOCOPY      NUMBER
                                       ,p_workers        IN              NUMBER
                                       ,p_from_date      IN              VARCHAR2
                                       ,p_retry_errors   IN              VARCHAR2
                                       ,p_get_status     IN              VARCHAR2
                                       )
    IS

   --Local Variable's
    ln_req_id                    NUMBER:=0;
    lc_chk_status                VARCHAR2(120) := NULL;
    lc_req_data                  VARCHAR2(100) := NULL;
    ln_err_cnt                   NUMBER:=0;
    ln_child_cnt                 NUMBER:=0;
  --ld_from_date                 DATE := fnd_conc_date.string_to_date(p_from_date); - Modified for defect#6451
  --ld_from_date                 DATE :=fnd_date.canonical_to_date(p_from_date);
    ln_request_id                NUMBER:=0;
    lc_status                    FND_AMP_REQUESTS_V.status%TYPE;

    BEGIN

       ln_request_id := fnd_global.conc_request_id ;
       lc_chk_status := FND_CONC_GLOBAL.REQUEST_DATA;

       IF (NVL(SUBSTR(lc_chk_status,1,INSTR(lc_chk_status,'-',1)-1),'FIRST') = 'FIRST') THEN

           FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Wrapper Request ID:   '||ln_request_id);
           FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************************');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Current system time is '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
           FND_FILE.PUT_LINE(FND_FILE.LOG,'********************************************');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting Standard IEX: Bulk XML Delivery Manager Program....');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'     ');

           ln_req_id :=  FND_REQUEST.SUBMIT_REQUEST ( 'IEX'
                                                     ,'IEX_BULK_XML_DELIVERY'
                                                     ,NULL
                                                     ,NULL
                                                     ,TRUE
                                                     ,p_workers
                                                     ,p_from_date  -- Modified for defect#6451
                                                     ,p_retry_errors
                                                     ,p_get_status
                                                     );
           COMMIT;

           FND_FILE.put_line(FND_FILE.LOG,'Request ID of IEX: Bulk XML Delivery Manager Program '||ln_req_id);
           lc_req_data := 'COMPLETE'||'-'||ln_req_id;
           FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=> lc_req_data);

           COMMIT;

       ELSE

          ln_req_id := TO_NUMBER(SUBSTR(lc_chk_status,INSTR(lc_chk_status,'-',1)+1));

          IF (ln_req_id > 0) THEN

             SELECT  COUNT(1)
             INTO    ln_child_cnt
             FROM    fnd_concurrent_requests FCR
             WHERE   FCR.parent_request_id = ln_req_id;

             SELECT  STATUS
             INTO    lc_status
             FROM    fnd_amp_requests_v FAR
             WHERE   FAR.request_id = ln_req_id;

             IF (ln_child_cnt > 0) THEN

                  SELECT  COUNT(1)
                  INTO    ln_err_cnt
                  FROM    fnd_concurrent_requests FCR
                  WHERE   FCR.parent_request_id = ln_req_id
                  AND     FCR.phase_code = 'C'
                  AND     FCR.status_code = 'E';

                  IF (ln_child_cnt = ln_err_cnt) THEN -- Errors when all childs errors out
                     FND_FILE.put_line(FND_FILE.LOG,'IEX Bulk XML Delivery Manager - Status: '||lc_status );
                     FND_FILE.put_line(FND_FILE.LOG,'Total No of Child records Errored out: '||ln_err_cnt);
                     x_retcode := 2;
                  ELSIF (ln_err_cnt > 0) THEN -- Ends in warning when atleast child record completes in Normal
                     FND_FILE.put_line(FND_FILE.LOG,'IEX Bulk XML Delivery Manager - Status: '||lc_status );
                     FND_FILE.put_line(FND_FILE.LOG,'Total No of Child records Errored out: '||ln_err_cnt);
                     x_retcode := 1;
                  END IF;
             ELSE
                  FND_FILE.put_line(FND_FILE.LOG,'No Childs Submitted for IEX Bulk XML Delivery Manager: '||ln_req_id );
             END IF;

          ELSE
             FND_FILE.PUT_LINE(FND_FILE.LOG,'IEX Bulk XML Delivery Manager is not Submitted');
          END IF;

        END IF;

    EXCEPTION
       WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Code :'||SQLERRM);
          x_retcode  := FND_API.G_RET_STS_ERROR;

    END IEX_BULK_XML_DELIVERY;

END XX_IEX_DEL_WRAP_PKG;
/
SHOW ERR