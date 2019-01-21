SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_CDH_TMP_CRD_LMT_PKG

WHENEVER SQLERROR CONTINUE
create or replace package body XX_CDH_FIN_HIER_PKG
IS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_CDH_FIN_HIER_PKG                                                                  |
-- |                                                                                                     |
-- | Description :  Package to Create and Remove customer relationship using webadi                      |
-- | Rice ID     : E3056                                                                                 |
-- |Change Record:                                                                                       |
-- |===============                                                                                      |
-- |Version   Date         Author           Remarks                                                      |
-- |=======   ==========   =============    ======================                                       |
-- | 1.0      09-Jan-2017  Vasu Raparla    Initial Version                                               |
-- +=====================================================================================================+
g_proc              VARCHAR2(80) := NULL;
g_debug             VARCHAR2(1)  := 'N';
gc_success          VARCHAR2(100)   := 'SUCCESS';
gc_failure          VARCHAR2(100)   := 'FAILURE';

-- +======================================================================+
-- | Name             : log_debug_msg                                     |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      09-Jan-2017  Vasu Raparla    Initial Version                |
-- +======================================================================+

PROCEDURE log_debug_msg ( p_debug_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;

BEGIN
  
  IF (g_debug = 'Y') THEN
    XX_COM_ERROR_LOG_PUB.log_error
      (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCDH'
        ,p_program_type            => 'LOG'             
        ,p_attribute15             => 'XX_CDH_FIN_HIER_PKG'      
        ,p_attribute16             => g_proc
        ,p_program_id              => 0                    
        ,p_module_name             => 'CDH'      
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
    FND_FILE.PUT_LINE(FND_FILE.log, p_debug_msg);
  END IF;
END log_debug_msg;
-- +======================================================================+
-- | Name             : log_error                                         |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      09-Jan-2017  Vasu Raparla    Initial Version                |
-- +======================================================================+

PROCEDURE log_error ( p_error_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.Login_Id;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.User_Id;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.user_name;
 
BEGIN
  
  XX_COM_ERROR_LOG_PUB.log_error
      (
        p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCDH'
      ,p_program_type            => 'ERROR'             
      ,p_attribute15             => 'XX_CDH_FIN_HIER_PKG'      
      ,p_attribute16             => g_proc
      ,p_program_id              => 0                    
      ,p_module_name             => 'CDH'      
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
  FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);    

END log_error;
  -- +===================================================================+
-- | Name  : update stg table
-- | Description     : The update stg table sets the record status     |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      :
-- +===================================================================+

PROCEDURE update_stg_table(p_record_id        IN     xx_cdh_fin_hier_stg.record_id%TYPE,
                             p_status         IN     xx_cdh_fin_hier_stg.status%TYPE,
                             p_error_msg      IN     xx_cdh_fin_hier_stg.error_message%TYPE,
                             x_return_status  OUT    VARCHAR2  
                             )

  AS
  BEGIN   
  x_return_status := null;
    UPDATE xx_cdh_fin_hier_stg
             SET status        = p_status,
                 error_message = p_error_msg
           WHERE record_id     = p_record_id;

        log_debug_msg( SQL%ROWCOUNT ||' Row(s) updated in xx_cdh_fin_hier_stg for record id  :'|| p_record_id);
         x_return_status := gc_success;
  EXCEPTION
    WHEN OTHERS
    THEN
      x_return_status := gc_failure;
      log_error('Error Updating Staging table xx_cdh_temp_credit_limit_stg '||substr(sqlerrm,1,100));
  END update_stg_table;
 -- +===================================================================+
-- | Name  : SET_CONTEXT                                               |
-- | Description     : This process sets context                       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      :                                                 |
-- +===================================================================+ 
PROCEDURE SET_CONTEXT
   AS 
     l_user_id                       NUMBER;
     l_responsibility_id             NUMBER;
     l_responsibility_appl_id        NUMBER;  
  
  -- set the user to ODCDH for bypassing VPD
   BEGIN
    SELECT user_id,
           responsibility_id,
           responsibility_application_id
      INTO l_user_id,                      
           l_responsibility_id,            
           l_responsibility_appl_id
      FROM fnd_user_resp_groups 
     WHERE user_id=(SELECT user_id 
                      FROM fnd_user 
                     WHERE user_name='ODCDH')
       AND responsibility_id=(SELECT responsibility_id 
                                FROM FND_RESPONSIBILITY 
                               WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
							   
    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );
					   
     log_debug_msg (' User Id:' || l_user_id);
     log_debug_msg (' Responsibility Id:' || l_responsibility_id);
     log_debug_msg (' Responsibility Application Id:' || l_responsibility_appl_id);

  EXCEPTION
    WHEN OTHERS THEN
    log_debug_msg ('Exception in initializing : ' || SQLERRM);
    
  END SET_CONTEXT;
 -- +===================================================================+
-- | Name  : generate_report                                           |
-- | Description     : This process generates the report output        |
-- |                                                                   |
-- |                                                                   |
-- | Parameters      :  p_batch_id                                     |
-- +===================================================================+ 
  PROCEDURE generate_report(p_batch_id       IN     xx_cdh_fin_hier_stg.batch_id%TYPE
                            )
  AS

  CURSOR cur_rep(p_batch_id  IN  xx_cdh_fin_hier_stg.batch_id%TYPE,
                 p_status    IN  xx_cdh_fin_hier_stg.status%TYPE)
  IS
      SELECT *
      FROM xx_cdh_fin_hier_stg 
      WHERE batch_id   =  p_batch_id
        AND status     =  p_status;

  ln_header_rec          NUMBER := 1;
  lc_line                VARCHAR2(4000) := NULL;
  lc_header              VARCHAR2(4000) := NULL;
  lc_head_line           VARCHAR2(4000) := NULL;

  BEGIN


    log_debug_msg('Batch id : '|| p_batch_id);
    log_debug_msg(chr(10));

    FOR cur_rep_rec IN cur_rep(p_batch_id => p_batch_id , 
                              p_status    => 'C')
    LOOP
      BEGIN
      lc_line := NULL;

      IF ln_header_rec = 1
       THEN
        log_debug_msg('Processing successful records ..');
        fnd_file.put_line(fnd_file.output, '****************************************** REPORT FOR SUCCESSFUL RECORDS ***********************************************');
        fnd_file.put_line(fnd_file.output, chr(10));

        ln_header_rec := 2;

        lc_header := RPAD('ParentPartyNumber',25, ' ')||chr(9)||
		                 RPAD('RelationshipType', 25, ' ')||chr(9)||
                     RPAD('ChildPartyNumber', 25, ' ')||chr(9)||
                     RPAD('StartDate',  15, ' ')||chr(9)||
                     RPAD('EndDate',  15, ' ')
                     ;


        fnd_file.put_line(fnd_file.output , lc_header);

        lc_head_line := RPAD('----------------',  25, '-')||chr(9)||
		                    RPAD('----------------',  25, '-')||chr(9)||
                        RPAD('----------------',  25, '-')||chr(9)||
                        RPAD('--------------------------',  15, '-')||chr(9)||
                        RPAD('--------------------------',  15, '-')||chr(9)
                        ;

        fnd_file.put_line(fnd_file.output , lc_head_line);
      END IF;

      lc_line := RPAD(cur_rep_rec.parent_party_number,25, ' ')||chr(9)||
	               RPAD(cur_rep_rec.relationship_type,25, ' ')||chr(9)||
                  RPAD(cur_rep_rec.child_party_number,25, ' ')||chr(9)||
                 RPAD(nvl(cur_rep_rec.start_date,' '),15, ' ')||chr(9)||
                 RPAD(nvl(cur_rep_rec.end_date,' '),15, ' ')
                 ;

       fnd_file.put_line(fnd_file.output, lc_line);

      EXCEPTION
        WHEN OTHERS
        THEN
         fnd_file.put_line(fnd_file.log, ' unable to write record id '|| cur_rep_rec.record_id ||' to report output '|| SQLERRM);
      END;
    END LOOP;

    ln_header_rec := 1;

    FOR cur_err_rec IN cur_rep(p_batch_id  =>  p_batch_id ,
                               p_status    =>  'E')
    LOOP
      BEGIN

      lc_line := NULL;

      IF ln_header_rec = 1
      THEN
      
        log_debug_msg('Processing Failed records ..');
        fnd_file.put_line(fnd_file.output, chr(10));
        fnd_file.put_line(fnd_file.output, chr(10));
        fnd_file.put_line(fnd_file.output, '********************************************* REPORT FOR FAILED RECORDS ********************************************');
        fnd_file.put_line(fnd_file.output, chr(10));

        lc_header := RPAD('ParentPartyNumber',25, ' ')||chr(9)||
		                 RPAD('RelationshipType', 25, ' ')||chr(9)||
                     RPAD('ChildPartyNumber', 25, ' ')||chr(9)||
                     RPAD('StartDate',  15, ' ')||chr(9)||
                     RPAD('EndDate',  15, ' ')||chr(9)||
                     RPAD('Error Message',250,' ')||chr(9);

        fnd_file.put_line(fnd_file.output , lc_header);

        lc_head_line := RPAD('----------------',  25, '-')||chr(9)||
		                    RPAD('----------------',  25, '-')||chr(9)||
                        RPAD('----------------',  25, '-')||chr(9)||
                        RPAD('--------------------------',  15, '-')||chr(9)||
                        RPAD('--------------------------',  15, '-')||chr(9)||
                        RPAD('--------------------------',  250, '-')
                        ;

        fnd_file.put_line(fnd_file.output , lc_head_line);
        ln_header_rec := 2;
      END IF;

      lc_line := RPAD(cur_err_rec.parent_party_number,25, ' ')||chr(9)||
	               RPAD(cur_err_rec.relationship_type,25, ' ')||chr(9)||
                 RPAD(cur_err_rec.child_party_number,25, ' ')||chr(9)||
                 RPAD(nvl(cur_err_rec.start_date,' '),15, ' ')||chr(9)||
                 RPAD(nvl(cur_err_rec.end_date,' '),15, ' ')||chr(9)||
                 RPAD(NVL(cur_err_rec.error_message,' '),250, ' ')||chr(9)
                 ;
       fnd_file.put_line(fnd_file.output, lc_line);

      EXCEPTION
        WHEN OTHERS
        THEN
         fnd_file.put_line(fnd_file.log, ' unable to write record id '|| cur_err_rec.record_id ||' to report output '|| SQLERRM);
      END;
    END LOOP;

  EXCEPTION
    WHEN OTHERS
    THEN
      log_debug_msg('Error generating report '||substr(SQLERRM,1,100));
  END generate_report;
  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_CDH_FIN_HIER_STG table             |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+                                  
PROCEDURE fetch_data(p_parent_party_number      hz_parties.party_number%TYPE,
                     p_relationship_type        hz_relationships.relationship_code%TYPE,
                     p_child_party_number       hz_parties.party_number%TYPE,
                     p_start_date               VARCHAR2,
                     p_end_date                 VARCHAR2
                     ) is
BEGIN 
  g_proc :='FETCH_DATA';
   insert into xx_cdh_fin_hier_stg(batch_id,
                                   record_id,
                                   parent_party_number,                          
                                   relationship_type,
                                   child_party_number,
                                   start_date,
                                   end_date,
                                   status,
                                   attribute1,
                                   creation_date,
                                   created_by,
                                   last_update_date,
                                   last_updated_by
                                    )
                            values (fnd_global.session_id,
                                    xx_cdh_fin_hier_stg_rec_s.nextval,
                                    p_parent_party_number,
                                    p_relationship_type,
                                    p_child_party_number,
                                    p_start_date,
                                    p_end_date,
                                    'N',
                                    'CREATE',
                                    sysdate,
                                    fnd_global.user_id,
                                    sysdate,
                                    fnd_global.user_id
                                      );
                                        commit;   
exception when others then        
                    log_error('Error Inserting Data into XX_CDH_FIN_HIER_STG '||substr(sqlerrm,1,50));
                    Raise_Application_Error (-20343, 'Error inserting the data..'||SQLERRM);
END fetch_data ;
  -- +===================================================================+
  -- | Name  : extract
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_CDH_FIN_HIER_STG and            |
  -- |                   create/end date customer relationships          |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- |                   p_debug_flag        IN -> Debug Flag            |
  -- |                   p_status            IN -> Record status         |
  -- +===================================================================+                     
PROCEDURE extract(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER) IS
CURSOR cur_extract(p_batch_id  IN xx_cdh_fin_hier_stg.batch_id%TYPE,
                   p_status    IN xx_cdh_fin_hier_stg.status%TYPE
                      ) is 
SELECT *
  FROM xx_cdh_fin_hier_stg
  WHERE 1 =1
    AND status     = NVL(p_status,status)
    AND batch_id   = NVL(p_batch_id,batch_id)
    AND attribute1 = 'CREATE'
    ORDER BY record_id ;
   --------------------------------
   -- Local Variable Declaration --
   -------------------------------- 
  lc_err_flag           VARCHAR2(1);
  lc_err_message        VARCHAR2(4000):=null;
  ln_batch_id           NUMBER;
  ln_user_id            fnd_user.user_id%TYPE;
  lc_user_name          fnd_user.user_name%TYPE;
  lc_debug_flag         VARCHAR2(1) := NULL;
  lc_err_rec_exists     VARCHAR2(5):='N';
  lc_upd_err_msg        VARCHAR2(2000);
  lc_upd_ret_status     VARCHAR2(20);
  lc_rel_creation_status   VARCHAR2(2000);

BEGIN
      g_proc :='EXTRACT';
      x_retcode :=0;
    -- Get the Debug flag
    BEGIN     
     SELECT xftv.source_value1
       INTO lc_debug_flag
       FROM xx_fin_translatedefinition xft,
            xx_fin_translatevalues xftv
      WHERE xft.translate_id    = xftv.translate_id
        AND xft.enabled_flag      = 'Y'
        AND xftv.enabled_flag     = 'Y'
        AND xft.translation_name  = 'XXOD_CDH_FIN_HIER_UPLOAD';

    EXCEPTION
      WHEN OTHERS
      THEN
        lc_debug_flag := 'N';
    END;
    
    log_debug_msg ('Debug Flag :'||lc_debug_flag);

    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF; 
    
    ln_user_id := fnd_global.user_id;
    log_debug_msg('Getting the user name ..');
    
    SELECT user_name
    INTO lc_user_name
    FROM fnd_user
    WHERE user_id = ln_user_id;

    log_debug_msg('User Name :'|| lc_user_name);

    fnd_file.put_line(fnd_file.log ,'Purge all the successful records from staging table for USER :'||lc_user_name);
    
    DELETE FROM xx_cdh_fin_hier_stg
    WHERE status = 'C'
    AND attribute1 ='CREATE'
    AND Created_by = ln_user_id;

    fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Record(s) deleted from staging table');

    COMMIT;
    
     fnd_file.put_line(fnd_file.log, 'Removing Duplicate records from staging table ..');

    DELETE FROM xx_cdh_fin_hier_stg a
    WHERE EXISTS ( SELECT 1
                   FROM xx_cdh_fin_hier_stg b
                   WHERE  1=1
                     AND  b.parent_party_number =a.parent_party_number
                     AND  b.child_party_number  =a.child_party_number
                     AND  b.relationship_type   =a.relationship_type
                     AND  start_date = a.start_date   
                     AND  nvl(b.end_date,sysdate)   = nvl(a.end_date,sysdate) 
                     AND  status     = a.status
                     AND  attribute1 =a.attribute1
                     AND  ROWID < A.ROWID );

    IF SQL%ROWCOUNT > 0
    THEN
      fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Duplicate Records deleted from staging table');
    END IF;
	
	COMMIT;

    log_debug_msg('Getting the next batch id .............');

    SELECT xx_cdh_fin_hier_stg_batch_s.nextval                                      --create sequence
    INTO ln_batch_id
    FROM dual;

    fnd_file.put_line(fnd_file.log, 'Batch id      :'||  ln_batch_id);
    fnd_file.put_line(fnd_file.log, 'session_id    :'||  fnd_global.session_id);
    fnd_file.put_line(fnd_file.log, 'User id       :'||  ln_user_id);

    fnd_file.put_line(fnd_file.log, 'Update the batch id in stg table for User id :'|| ln_user_id);

    UPDATE xx_cdh_fin_hier_stg
       SET batch_id   = ln_batch_id
     WHERE created_by = ln_user_id
       AND attribute1 = 'CREATE'
       AND status     = 'N';

    fnd_file.put_line(fnd_file.log ,SQL%ROWCOUNT||'  records Updated for user : '|| ln_user_id || ' with batch id :'|| ln_batch_id );

    COMMIT;
  for rec in cur_extract(p_batch_id => ln_batch_id,
                          p_status   => 'N') 
    loop

    lc_err_message        := null;
    lc_upd_err_msg        := null;
    lc_upd_ret_status     := null;
    lc_err_flag           :='N';
    
       SET_CONTEXT;
    
      lc_rel_creation_status := xx_fin_rels_credit_upload_pkg.create_rel(rec.parent_party_number,
                                                 rec.relationship_type,
                                                 rec.child_party_number,
                                                 rec.start_date,
                                                 rec.end_date);
            if(upper(lc_rel_creation_status) like 'FALSE%') 
            then
                lc_err_flag:='Y';
            end if;
         if (nvl(lc_err_flag,'N') ='N')
             then
            log_debug_msg ('Updating staging Table for Success ');
            update_stg_table( p_record_id  => rec.record_id,
                             p_status        => 'C',
                             p_error_msg     => null,
                             x_return_status => lc_upd_ret_status);
          else 
           log_debug_msg ('Updating staging Table for Error ');
           lc_err_rec_exists     :='Y';
           update_stg_table( p_record_id  => rec.record_id,
                             p_status        => 'E',
                             p_error_msg     => lc_rel_creation_status,
                             x_return_status => lc_upd_ret_status);                     
      end if;
    commit;
    end loop;
    generate_report(ln_batch_id);
    if(lc_err_rec_exists ='Y')
     then
      log_debug_msg ('Error Creating Relationship : ');
      fnd_file.put_line(fnd_file.log,'Relationship Creation Process Ended in Error....');
      x_retcode := 2;
    end if;
    fnd_file.put_line(fnd_file.log,'Relationship Creation Process Ends....');
EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Customer Relation creation - Process Ended in Error....'||SQLERRM);
      x_retcode := 2;
END extract;
  -- +===================================================================+
  -- | Name  : fetch_data_upd                                            |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_CDH_FIN_HIER_STG table             |
  -- |                                                                   |
  -- |                                                                   |
  -- | Parameters      : p_parent_party_number                           |
  -- |                   p_relationship_type                             |
  -- |                   p_child_party_number                            |
 --  |                   p_end_date                                      |
  -- +===================================================================+                                  
PROCEDURE fetch_data_upd(p_parent_party_number hz_parties.party_number%TYPE,
                     p_relationship_type        hz_relationships.relationship_code%TYPE,
                     p_child_party_number       hz_parties.party_number%TYPE,
                     p_end_date                 varchar2
                     ) is 
BEGIN 
  g_proc :='FETCH_DATA_UPD';
   insert into xx_cdh_fin_hier_stg(batch_id,
                                   record_id,
                                   parent_party_number,                          
                                   relationship_type,
                                   child_party_number,
                                   end_date,
                                   status,
                                   attribute1,
                                   creation_date,
                                   created_by,
                                   last_update_date,
                                   last_updated_by
                                    )
                            values (fnd_global.session_id,
                                    xx_cdh_fin_hier_stg_rec_s.nextval,
                                    p_parent_party_number,
                                    p_relationship_type,
                                    p_child_party_number,
                                    p_end_date,
                                    'N',
                                    'END_DATE',
                                    sysdate,
                                    fnd_global.user_id,
                                    sysdate,
                                    fnd_global.user_id
                                      );
                                        commit;   
exception when others then        
                    log_error('Error Inserting Data into XX_CDH_FIN_HIER_STG '||substr(sqlerrm,1,50));
                    Raise_Application_Error (-20343, 'Error inserting data into XX_CDH_FIN_HIER_STG for End dating..'||SQLERRM);
END fetch_data_upd ;  

  -- +===================================================================+
  -- | Name  : end_date_relationship
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_CDH_FIN_HIER_STG and            |
  -- |                   end date customer relationships                 |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- +===================================================================+                     
PROCEDURE end_date_relationship(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER) is
CURSOR cur_extract(p_batch_id  IN xx_cdh_fin_hier_stg.batch_id%TYPE,
                   p_status    IN xx_cdh_fin_hier_stg.status%TYPE
                      ) is 
SELECT *
  FROM xx_cdh_fin_hier_stg
  WHERE 1 =1
    AND status     = NVL(p_status,status)
    AND batch_id   = NVL(p_batch_id,batch_id)
    AND attribute1 = 'END_DATE'
    ORDER BY record_id ;
   --------------------------------
   -- Local Variable Declaration --
   -------------------------------- 
  lc_err_flag           VARCHAR2(1);
  lc_err_message        VARCHAR2(4000):=null;
  ln_batch_id           NUMBER;
  ln_user_id            fnd_user.user_id%TYPE;
  lc_user_name          fnd_user.user_name%TYPE;
  lc_debug_flag         VARCHAR2(1) := NULL;
  lc_err_rec_exists     VARCHAR2(5):='N';
  lc_upd_err_msg        VARCHAR2(2000);
  lc_upd_ret_status     VARCHAR2(20);
  lc_rel_creation_status   VARCHAR2(2000);

BEGIN
      g_proc :='END_DATE_RELATIONSHIP';
      x_retcode :=0;
    -- Get the Debug flag
    BEGIN     
     SELECT xftv.source_value1
       INTO lc_debug_flag
       FROM xx_fin_translatedefinition xft,
            xx_fin_translatevalues xftv
      WHERE xft.translate_id    = xftv.translate_id
        AND xft.enabled_flag      = 'Y'
        AND xftv.enabled_flag     = 'Y'
        AND xft.translation_name  = 'XXOD_CDH_FIN_HIER_UPLOAD';

    EXCEPTION
      WHEN OTHERS
      THEN
        lc_debug_flag := 'N';
    END;
    
    log_debug_msg ('Debug Flag :'||lc_debug_flag);

    IF (lc_debug_flag = 'Y')
      THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF; 
    
    ln_user_id := fnd_global.user_id;
    log_debug_msg('Getting the user name ..');
    
    SELECT user_name
    INTO lc_user_name
    FROM fnd_user
    WHERE user_id = ln_user_id;

    log_debug_msg('User Name :'|| lc_user_name);

    fnd_file.put_line(fnd_file.log ,'Purge all the successful records from staging table for USER :'||lc_user_name);
    
    DELETE FROM xx_cdh_fin_hier_stg
    WHERE status = 'C'
    AND attribute1 ='END_DATE'
    AND Created_by = ln_user_id;

    fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Record(s) deleted from staging table');

    COMMIT;
    
     fnd_file.put_line(fnd_file.log, 'Removing Duplicate records from staging table ..');

    DELETE FROM xx_cdh_fin_hier_stg a
    WHERE EXISTS ( SELECT 1
                   FROM xx_cdh_fin_hier_stg b
                   WHERE  1=1
                     AND  b.parent_party_number =a.parent_party_number
                     AND  b.child_party_number  =a.child_party_number
                     AND  b.relationship_type   =a.relationship_type
                     AND  nvl(b.start_date,sysdate) =nvl(a.start_date,sysdate)   
                     AND  nvl(b.end_date,sysdate)   = nvl(a.end_date,sysdate) 
                     AND  status     = a.status
                     AND  attribute1 = a.attribute1
                     AND  ROWID < A.ROWID );

    IF SQL%ROWCOUNT > 0
    THEN
      fnd_file.put_line(fnd_file.log, SQL%ROWCOUNT || ' Duplicate Records deleted from staging table');
    END IF;
	
	COMMIT;

    log_debug_msg('Getting the next batch id .............');

    SELECT xx_cdh_fin_hier_stg_batch_s.nextval                                      --create sequence
    INTO ln_batch_id
    FROM dual;

    fnd_file.put_line(fnd_file.log, 'Batch id      :'||  ln_batch_id);
    fnd_file.put_line(fnd_file.log, 'session_id    :'||  fnd_global.session_id);
    fnd_file.put_line(fnd_file.log, 'User id       :'||  ln_user_id);

    fnd_file.put_line(fnd_file.log, 'Update the batch id in stg table for User id :'|| ln_user_id);

    UPDATE xx_cdh_fin_hier_stg
       SET batch_id   = ln_batch_id
     WHERE created_by = ln_user_id
       AND attribute1 = 'END_DATE'
       AND status     = 'N';

    fnd_file.put_line(fnd_file.log ,SQL%ROWCOUNT||'  records Updated for user : '|| ln_user_id || ' with batch id :'|| ln_batch_id );

    COMMIT;
  for rec in cur_extract(p_batch_id => ln_batch_id,
                          p_status   => 'N') 
    loop

    lc_err_message        := null;
    lc_upd_err_msg        := null;
    lc_upd_ret_status     := null;
    lc_err_flag           :='N';
    
       SET_CONTEXT;
    
      lc_rel_creation_status := xx_fin_rels_credit_upload_pkg.remove_rel(rec.parent_party_number,
                                                 rec.relationship_type,
                                                 rec.child_party_number,
                                                 rec.end_date);
            if(upper(lc_rel_creation_status) like 'FALSE%') 
            then
                lc_err_flag:='Y';
            end if;
         if (nvl(lc_err_flag,'N') ='N')
             then
            log_debug_msg ('Updating staging Table for Success ');
            update_stg_table( p_record_id  => rec.record_id,
                             p_status        => 'C',
                             p_error_msg     => null,
                             x_return_status => lc_upd_ret_status);
          else 
           log_debug_msg ('Updating staging Table for Error ');
           lc_err_rec_exists     :='Y';
           update_stg_table( p_record_id  => rec.record_id,
                             p_status        => 'E',
                             p_error_msg     => lc_rel_creation_status,
                             x_return_status => lc_upd_ret_status);                     
      end if;
    commit;
    end loop;
    generate_report(ln_batch_id);
    if(lc_err_rec_exists ='Y')
     then
      log_debug_msg ('Error End Dating Relationship : ');
      fnd_file.put_line(fnd_file.log,'Customer Relation End Dating - Process Ended in Error....');
      x_retcode := 2;
    end if;
    fnd_file.put_line(fnd_file.log,'End Dating Relationship Creation Process Ends....');
EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Customer Relation End Dating - Process Ended in Error....'||SQLERRM);
      x_retcode := 2;
END end_date_relationship;
END XX_CDH_FIN_HIER_PKG;
/
