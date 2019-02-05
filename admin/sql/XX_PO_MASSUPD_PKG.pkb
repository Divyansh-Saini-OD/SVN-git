SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
 
PROMPT Creating Package Body XX_PO_MASSUPD_PKG
 
PROMPT Program exits if the creation is not successful
 
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_PO_MASSUPD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Implemented to perform the PO Receipts              |
-- | Description : To perform PO Mass Update                           |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0      26-MAY-2007  MadanKumar J          Initial version        |
-- |                                                                   |
-- +===================================================================+
AS
gc_error_detail   VARCHAR2(3000)  :=       NULL;
gc_error_code     VARCHAR2(500)   :=       NULL;
gc_error_loc      VARCHAR2(150)   :=       NULL;
gc_ret_code       NUMBER          :=       0;
gc_rev_ctrl_flag  VARCHAR2(10);

 -- +===================================================================+
 -- | Name          : Main                                              |
 -- | Description   : This Procedure will prevent the users from        |
 -- |                 submitting the concurrent program for already     |
 -- |                 submitted Batch ID and if it is a new batch then  |
 -- |                 the process gets initiated.                       |
 -- | Parameters    : p_batch_id                                        |
 -- |                                                                   |
 -- | Returns       : x_error_buff, x_ret_code                          |
 -- |                                                                   |
 -- +===================================================================+
PROCEDURE MAIN(
               x_error_buff      OUT   NOCOPY    VARCHAR2
               ,x_ret_code       OUT   NOCOPY    VARCHAR2
               ,p_batch_id       IN              NUMBER
               )
IS
--VARIABLE DECLARATION
BEGIN
    gc_ret_code := 0;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'PROCEDURE: MAIN');
    INSERT_SUMMARY_RECORD;                         --Inserts Summary Details Into Status Table.
    PROCESS_MASS_UPDATE(p_batch_id,gc_ret_code);   --Calls the sub procedures based on the action selected.
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Return Code is '||gc_ret_code);
    x_ret_code := gc_ret_code;
    XX_PO_MASSUPD_REPORT(p_batch_id);                --Display the Report Output.

    DELETE xx_po_mass_upd_po_hdr_tmp;                --Purging the table
    DELETE xx_po_mass_upd_po_updline_tmp;
    DELETE xx_po_mass_upd_po_newline_tmp;
    DELETE xx_po_mass_upd_batch_all;
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      gc_error_code:=SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'gc_error_code');
      x_ret_code :=2;
      DELETE xx_po_mass_upd_po_hdr_tmp;             --Purging the table
      DELETE xx_po_mass_upd_po_updline_tmp;
      DELETE xx_po_mass_upd_po_newline_tmp;
      DELETE xx_po_mass_upd_batch_all;
      COMMIT;
    WHEN OTHERS THEN
      gc_error_code:=SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'gc_error_code');
      x_ret_code := 2;
      DELETE xx_po_mass_upd_po_hdr_tmp;             --Purging the table
      DELETE xx_po_mass_upd_po_updline_tmp;
      DELETE xx_po_mass_upd_po_newline_tmp;
      DELETE xx_po_mass_upd_batch_all;
      COMMIT;
END MAIN;

 -- +===================================================================+
 -- | Name          : Insert_summary_record                             |
 -- | Description   : This Procedure populates the status table         |
 -- |                                                                   |
 -- | Parameters    :                                                   |
 -- |                                                                   |
 -- | Returns       :                                                   |
 -- |                                                                   |
 -- +=========================================================+=========+
PROCEDURE INSERT_SUMMARY_RECORD
IS
--VARIABLE DECLARATION
lc_mass_action          VARCHAR2(50);
lc_header_status        VARCHAR2(20);
ln_org_id               NUMBER   := 0;
ln_line_num             NUMBER   := 0;
ln_exception_no         NUMBER   := 0;
ln_batch_id             NUMBER   := 0;
lc_line_close           VARCHAR2(1);
lc_updline_flag         VARCHAR2(1);
lc_line_type            VARCHAR2(10);
lc_attribute_category   po_headers_all.attribute_category%TYPE;

--CURSOR Declaration
CURSOR lcu_po_hdr_curr
IS
SELECT po_header_id
       ,batch_id
       ,po_number
       ,rev_num
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_updated_date
       ,attribute_category
       ,attribute1
       ,attribute2
       ,attribute3
       ,attribute4
       ,attribute5
       ,attribute6
       ,attribute7
       ,attribute8
       ,attribute9
       ,attribute10
       ,attribute11
       ,attribute12
       ,attribute13
       ,attribute14
       ,attribute15
FROM   xx_po_mass_upd_po_hdr_tmp;

CURSOR lcu_po_updline_curr
IS
SELECT item_id
       ,line_close_flag
       ,item_number
       ,price
       ,quantity
       ,promised_date
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_updated_date
       ,attribute_category
       ,attribute1
       ,attribute2
       ,attribute3
       ,attribute4
       ,attribute5
       ,attribute6
       ,attribute7
       ,attribute8
       ,attribute9
       ,attribute10
       ,attribute11
       ,attribute12
       ,attribute13
       ,attribute14
       ,attribute15
FROM   xx_po_mass_upd_po_updline_tmp;

CURSOR lcu_po_newline_curr
IS
SELECT line_type
       ,item_id
       ,item_number
       ,price
       ,quantity
       ,promised_date
       ,created_by
       ,creation_date
       ,last_updated_by
       ,last_updated_date
       ,attribute_category
       ,attribute1
       ,attribute2
       ,attribute3
       ,attribute4
       ,attribute5
       ,attribute6
       ,attribute7
       ,attribute8
       ,attribute9
       ,attribute10
       ,attribute11
       ,attribute12
       ,attribute13
       ,attribute14
       ,attribute15
FROM   xx_po_mass_upd_po_newline_tmp;

CURSOR lcu_po_line_curr(
                        p_po_header_id VARCHAR
                       ,p_item_id NUMBER)
IS
SELECT  po_line_id
       ,line_num
FROM    po_lines_v
WHERE   po_header_id = p_po_header_id
AND     item_id  = p_item_id;

BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'PROCEDURE: INSERT_SUMMARY_RECORD');
     gc_error_detail:=NULL;

     BEGIN
     SELECT mass_action
            ,org_id
            ,DECODE(UPPER(mass_action)
                   ,'MASS OPEN POS','OPEN'
                   ,'MASS CLOSE POS','CLOSE'
                   ,'MASS APPROVE POS','APPROVE'
                   ,'LINE UPDATE')
            ,batch_id
     INTO   lc_mass_action
            ,ln_org_id
            ,lc_header_status
            ,ln_batch_id
     FROM   xx_po_mass_upd_batch_all;
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gc_error_code := SQLERRM;
          FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code);
          gc_ret_code := 2;
        WHEN OTHERS THEN
          gc_error_code := SQLERRM;
          FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code);
          gc_ret_code := 2;
     END;
     FOR lcu_po_hdr_curr_rec
       IN lcu_po_hdr_curr
       LOOP
         IF lc_mass_action IN ('MASS OPEN POS','MASS CLOSE POS','MASS APPROVE POS') THEN
             BEGIN
                INSERT
                INTO xx_po_mass_upd_po_status_all(
                 mass_update_id
                ,batch_id
                ,po_header_id
                ,po_line_id
                ,org_id
                ,po_number
                ,po_header_status
                ,revision_no
                ,po_type
                ,approval_status
                ,mass_action_detail
                ,line_type
                ,item_id
                ,item_number
                ,line_status
                ,price
                ,quantity
                ,process_status
                ,error_description
                ,promised_date
                ,created_by
                ,creation_date
                ,last_updated_by
                ,last_updated_date
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                )
                VALUES
                (
                 xx_po_mass_upd_po_status_all_s.NEXTVAL
                ,ln_batch_id
                ,lcu_po_hdr_curr_rec.po_header_id
                ,NULL
                ,ln_org_id
                ,lcu_po_hdr_curr_rec.po_number
                ,lc_header_status
                ,lcu_po_hdr_curr_rec.rev_num
                ,'PO'
                ,'APPROVED'
                ,lc_mass_action
                ,NULL
                ,NULL
                ,NULL
                ,NULL
                ,NULL
                ,NULL
                ,'NEW'
                ,NULL
                ,NULL
                ,lcu_po_hdr_curr_rec.created_by
                ,lcu_po_hdr_curr_rec.creation_date
                ,lcu_po_hdr_curr_rec.last_updated_by
                ,lcu_po_hdr_curr_rec.last_updated_date
                ,lcu_po_hdr_curr_rec.attribute_category
                ,lcu_po_hdr_curr_rec.attribute1
                ,lcu_po_hdr_curr_rec.attribute2
                ,lcu_po_hdr_curr_rec.attribute3
                ,lcu_po_hdr_curr_rec.attribute4
                ,lcu_po_hdr_curr_rec.attribute5
                ,lcu_po_hdr_curr_rec.attribute6
                ,lcu_po_hdr_curr_rec.attribute7
                ,lcu_po_hdr_curr_rec.attribute8
                ,lcu_po_hdr_curr_rec.attribute9
                ,lcu_po_hdr_curr_rec.attribute10
                ,lcu_po_hdr_curr_rec.attribute11
                ,lcu_po_hdr_curr_rec.attribute12
                ,lcu_po_hdr_curr_rec.attribute13
                ,lcu_po_hdr_curr_rec.attribute14
                ,lcu_po_hdr_curr_rec.attribute15
                );
                COMMIT;
             EXCEPTION
               WHEN OTHERS THEN
                 gc_error_code := SQLERRM;
                 gc_error_detail  := 'Error while inserting header details into the table xx_po_mass_upd_po_status_all';
                 FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
                 gc_ret_code := 2;
                 RAISE;
             END;
        ELSIF lc_mass_action IN ('MASS UPDATE LINES') THEN
             BEGIN
               SELECT  line_close_flag
                       ,'Y'
               INTO    lc_line_close
                       ,lc_updline_flag
               FROM    xx_po_mass_upd_po_updline_tmp
               WHERE   batch_id=lcu_po_hdr_curr_rec.batch_id;
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 lc_updline_flag:='N';
               WHEN OTHERS THEN
                 lc_updline_flag:='N';
                 gc_error_code := SQLERRM;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Header_id '||lcu_po_hdr_curr_rec.po_header_id||' Error Code '||gc_error_code);
             END;

             IF (lc_line_close IN ('N','Y') AND
                 lc_updline_flag='Y' ) THEN
                 FOR lcu_po_updline_curr_rec
                 IN lcu_po_updline_curr
                 LOOP
                 EXIT WHEN lcu_po_updline_curr%NOTFOUND;
                     FOR lcu_po_line_curr_rec
                     IN lcu_po_line_curr(lcu_po_hdr_curr_rec.po_header_id,lcu_po_updline_curr_rec.item_id)
                     LOOP
                     EXIT WHEN lcu_po_updline_curr%NOTFOUND;
                       BEGIN
                         --Inserting Update Line details into the status table
                         INSERT
                         INTO XX_PO_MASS_UPD_PO_STATUS_ALL (
                         mass_update_id
                         ,batch_id
                         ,po_header_id
                         ,po_line_id
                         ,org_id
                         ,po_number
                         ,line_num
                         ,po_header_status
                         ,revision_no
                         ,po_type
                         ,approval_status
                         ,mass_action_detail
                         ,line_type
                         ,item_id
                         ,item_number
                         ,line_status
                         ,price
                         ,quantity
                         ,process_status
                         ,error_description
                         ,promised_date
                         ,created_by
                         ,creation_date
                         ,last_updated_by
                         ,last_updated_date
                         ,attribute_category
                         ,attribute1
                         ,attribute2
                         ,attribute3
                         ,attribute4
                         ,attribute5
                         ,attribute6
                         ,attribute7
                         ,attribute8
                         ,attribute9
                         ,attribute10
                         ,attribute11
                         ,attribute12
                         ,attribute13
                         ,attribute14
                         ,attribute15
                         )
                         VALUES
                         (
                         xx_po_mass_upd_po_status_all_s.NEXTVAL
                         ,ln_batch_id
                         ,lcu_po_hdr_curr_rec.po_header_id
                         ,lcu_po_line_curr_rec.po_line_id
                         ,ln_org_id
                         ,lcu_po_hdr_curr_rec.po_number
                         ,lcu_po_line_curr_rec.line_num
                         ,NULL
                         ,lcu_po_hdr_curr_rec.rev_num
                         ,NULL
                         ,NULL
                         ,DECODE(lcu_po_updline_curr_rec.line_close_flag
                                ,'N','LINE UPDATE'
                                ,'Y','LINE CLOSE')
                         ,NULL
                         ,lcu_po_updline_curr_rec.item_id
                         ,lcu_po_updline_curr_rec.item_number
                         ,lcu_po_updline_curr_rec.line_close_flag
                         ,lcu_po_updline_curr_rec.price
                         ,lcu_po_updline_curr_rec.quantity
                         ,'NEW'
                         ,NULL
                         ,lcu_po_updline_curr_rec.promised_date
                         ,lcu_po_updline_curr_rec.created_by
                         ,lcu_po_updline_curr_rec.creation_date
                         ,lcu_po_updline_curr_rec.last_updated_by
                         ,lcu_po_updline_curr_rec.last_updated_date
                         ,lcu_po_updline_curr_rec.attribute_category
                         ,lcu_po_updline_curr_rec.attribute1
                         ,lcu_po_updline_curr_rec.attribute2
                         ,lcu_po_updline_curr_rec.attribute3
                         ,lcu_po_updline_curr_rec.attribute4
                         ,lcu_po_updline_curr_rec.attribute5
                         ,lcu_po_updline_curr_rec.attribute6
                         ,lcu_po_updline_curr_rec.attribute7
                         ,lcu_po_updline_curr_rec.attribute8
                         ,lcu_po_updline_curr_rec.attribute9
                         ,lcu_po_updline_curr_rec.attribute10
                         ,lcu_po_updline_curr_rec.attribute11
                         ,lcu_po_updline_curr_rec.attribute12
                         ,lcu_po_updline_curr_rec.attribute13
                         ,lcu_po_updline_curr_rec.attribute14
                         ,lcu_po_updline_curr_rec.attribute15
                         );
                       COMMIT;
                       EXCEPTION
                         WHEN OTHERS THEN
                           gc_error_code:=SQLERRM;
                           FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code||' Error in the procedure Insert_Summary_Record while inserting Update line Details');
                           gc_ret_code := 2;
                           RAISE;
                       END;
                     END LOOP;
                 END LOOP;
              END IF;
                 BEGIN
                   SELECT     MAX(line_num)
                   INTO       ln_line_num
                   FROM       po_lines_v
                   WHERE      po_header_id = lcu_po_hdr_curr_rec.po_header_id;
                 EXCEPTION
                   WHEN OTHERS THEN
                     gc_error_loc := 'SELECT failed while getting the line number from po_lines_v ';
                     gc_error_code := 'SQLERRM';
                     FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_loc||' '||gc_error_code);
                 END;
                 BEGIN
                   SELECT     attribute_category
                   INTO       lc_attribute_category
                   FROM       po_headers_v
                   WHERE      po_header_id = lcu_po_hdr_curr_rec.po_header_id;
                 EXCEPTION
                   WHEN OTHERS THEN
                     gc_error_loc := 'SELECT failed while getting the attribute category po_headers_v ';
                     gc_error_code := 'SQLERRM';
                     FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_loc||' '||gc_error_code);
                 END;

                 FOR lcu_po_newline_curr_rec
                 IN lcu_po_newline_curr
                 LOOP
                 EXIT WHEN lcu_po_newline_curr%NOTFOUND;
                   BEGIN
                     ln_line_num := ln_line_num + 1;
                     --Inserting newline details into the status table
                     INSERT
                     INTO xx_po_mass_upd_po_status_all(
                     mass_update_id
                     ,batch_id
                     ,po_header_id
                     ,po_line_id
                     ,org_id
                     ,po_number
                     ,line_num
                     ,po_header_status
                     ,revision_no
                     ,po_type
                     ,approval_status
                     ,mass_action_detail
                     ,line_type
                     ,item_id
                     ,item_number
                     ,line_status
                     ,price
                     ,quantity
                     ,process_status
                     ,error_description
                     ,promised_date
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_updated_date
                     ,attribute_category
                     ,attribute1
                     ,attribute2
                     ,attribute3
                     ,attribute4
                     ,attribute5
                     ,attribute6
                     ,attribute7
                     ,attribute8
                     ,attribute9
                     ,attribute10
                     ,attribute11
                     ,attribute12
                     ,attribute13
                     ,attribute14
                     ,attribute15
                     )
                     VALUES
                     (
                     xx_po_mass_upd_po_status_all_s.NEXTVAL
                     ,ln_batch_id
                     ,lcu_po_hdr_curr_rec.po_header_id
                     ,NULL
                     ,ln_org_id
                     ,lcu_po_hdr_curr_rec.po_number
                     ,ln_line_num
                     ,NULL
                     ,lcu_po_hdr_curr_rec.rev_num
                     ,'PO'
                     ,' '
                     ,'NEW LINE'
                     ,lcu_po_newline_curr_rec.line_type
                     ,lcu_po_newline_curr_rec.item_id
                     ,lcu_po_newline_curr_rec.item_number
                     ,NULL
                     ,lcu_po_newline_curr_rec.price
                     ,lcu_po_newline_curr_rec.quantity
                     ,'NEW'
                     ,NULL
                     ,lcu_po_newline_curr_rec.promised_date
                     ,lcu_po_newline_curr_rec.created_by
                     ,lcu_po_newline_curr_rec.creation_date
                     ,lcu_po_newline_curr_rec.last_updated_by
                     ,lcu_po_newline_curr_rec.last_updated_date
                     ,lc_attribute_category
                     ,lcu_po_newline_curr_rec.attribute1
                     ,lcu_po_newline_curr_rec.attribute2
                     ,lcu_po_newline_curr_rec.attribute3
                     ,lcu_po_newline_curr_rec.attribute4
                     ,lcu_po_newline_curr_rec.attribute5
                     ,lcu_po_newline_curr_rec.attribute6
                     ,lcu_po_newline_curr_rec.attribute7
                     ,lcu_po_newline_curr_rec.attribute8
                     ,lcu_po_newline_curr_rec.attribute9
                     ,lcu_po_newline_curr_rec.attribute10
                     ,lcu_po_newline_curr_rec.attribute11
                     ,lcu_po_newline_curr_rec.attribute12
                     ,lcu_po_newline_curr_rec.attribute13
                     ,lcu_po_newline_curr_rec.attribute14
                     ,lcu_po_newline_curr_rec.attribute15
                     );
                     COMMIT;
                   EXCEPTION
                   WHEN OTHERS THEN
                     gc_error_code := SQLERRM;
                     gc_error_loc := ' Procedure Name:Insert_Summary_Record, Exception:Others, while inserting Newline Details';
                     FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code||gc_error_loc);
                     gc_ret_code := 2;
                     RAISE;
                   END;
                 END LOOP;
         END IF;
      END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
           gc_error_code := SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code||' No Data Found Exception in the procedure Insert_Summary_Record');
        WHEN OTHERS THEN
           gc_error_code := SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code||' Others Exception in the procedure Insert_Summary_Record');
END INSERT_SUMMARY_RECORD;

-- +===================================================================+
-- | Name          : Process Mass Update                               |
-- | Description   : This Procedure will call the respective procedures|
-- |                 based on the action detail selected               |
-- |                                                                   |
-- | Parameters    :       p_batch_id                                  |
-- |                                                                   |
-- | Returns       :       x_ret_code                                  |
-- |                                                                   |
-- +===================================================================+
PROCEDURE PROCESS_MASS_UPDATE(
                               p_batch_id NUMBER
                               ,x_ret_code OUT NOCOPY NUMBER
                             )
IS
--VARIABLE  DECLARATION
lc_mass_action_detail   VARCHAR2(50);
p_mass_action_curr      VARCHAR2(50);
p_ret_code              NUMBER         :=0;
lb_return_code          BOOLEAN        := FALSE;
ln_err_count            NUMBER         := 0;
ln_proc_count           NUMBER         := 0;
lc_updline_flag         VARCHAR2(1)    := 'N';
lc_line_close           VARCHAR2(1);
ln_line_insert          NUMBER         := 0;
--CURSOR DECLARATION
BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: PROCESS_MASS_UPDATE');
        SELECT  DISTINCT UPPER(MASS_ACTION)
        INTO    lc_mass_action_detail
        FROM    xx_po_mass_upd_batch_all
        WHERE   batch_id = p_batch_id;

        IF (lc_mass_action_detail='MASS OPEN POS') THEN
           OPEN_PO_HDR(p_batch_id, p_ret_code);
           x_ret_code:=p_ret_code;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: '||p_ret_code||x_ret_code);
        ELSIF (lc_mass_action_detail='MASS CLOSE POS') THEN
           CLOSE_PO_HDR(p_batch_id);
        ELSIF (lc_mass_action_detail='MASS APPROVE POS') THEN
           APPROVE_PO_HDR(p_batch_id);
        ELSIF (lc_mass_action_detail='MASS UPDATE LINES') THEN
            BEGIN
              SELECT  line_close_flag
                      ,'Y'
              INTO    lc_line_close
                      ,lc_updline_flag
              FROM    xx_po_mass_upd_po_updline_tmp
              WHERE   batch_id=p_batch_id;

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  lc_updline_flag:='N';
                  lc_line_close := 'N';
               WHEN OTHERS THEN
                  gc_error_code:=SQLERRM;
                  lc_updline_flag:='N';
                  lc_line_close := 'N';
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'PROCEDURE:Process_Mass_Update '||gc_error_code);
            END;

            BEGIN
              SELECT COUNT(line_type)
              INTO   ln_line_insert
              FROM   xx_po_mass_upd_po_newline_tmp
              WHERE   batch_id=p_batch_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 ln_line_insert:=0;
              WHEN OTHERS THEN
                 ln_line_insert:=0;
                 gc_error_code:=SQLERRM;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,'PROCEDURE:Process_Mass_Update: '||gc_error_code);
            END;

             IF (lc_updline_flag='Y') AND
                (ln_line_insert <> 0) THEN
                 gc_rev_ctrl_flag := 'Y';
             ELSE
                 gc_rev_ctrl_flag := NULL;
             END IF;
                                                             
            IF (lc_line_close='Y' AND        --Only Line Close
                lc_updline_flag='Y' AND
                ln_line_insert = 0) THEN
                CLOSE_PO_HDR_LINE(p_batch_id);

            ELSIF (lc_line_close='N'   AND   --Only Line Update
                   lc_updline_flag='Y' AND 
                   ln_line_insert = 0) THEN
                UPDATE_PO_LINE(p_batch_id);
                APPROVE_PO_HDR(p_batch_id);

            ELSIF (ln_line_insert <> 0 AND   --Only Line Insert
                   lc_updline_flag NOT IN ('Y') AND
                   lc_line_close NOT IN ('Y'))  THEN
                   INSERT_PO_LINE(p_batch_id);

            ELSIF (ln_line_insert <> 0 AND   --Line Update and Insert New Line
                   lc_updline_flag IN ('Y') AND
                   lc_line_close   IN ('N'))  THEN
                   UPDATE_PO_LINE(p_batch_id);
                   INSERT_PO_LINE(p_batch_id);
                   APPROVE_PO_HDR(p_batch_id);

            ELSIF (ln_line_insert <> 0 AND   --Line Close and Insert New Line
                   lc_updline_flag IN ('Y') AND
                   lc_line_close   IN ('Y'))  THEN
                   CLOSE_PO_HDR_LINE(p_batch_id);
                   INSERT_PO_LINE(p_batch_id);
                   APPROVE_PO_HDR(p_batch_id);
            END IF;
        END IF;
EXCEPTION
        WHEN NO_DATA_FOUND THEN
          gc_error_code:=SQLERRM;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Process_mass_update: '||gc_error_code);
        WHEN OTHERS THEN
          gc_error_code:=SQLERRM;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'process_mass_update: '||gc_error_code);
END PROCESS_MASS_UPDATE;

 -- +===================================================================+
 -- | Name          : Open_PO_HDR                                       |
 -- | Description   : This Procedure will be used to open the           |
 -- |                 PO HDR on mass basis                              |
 -- |                                                                   |
 -- |                                                                   |
 -- | Parameters    :    p_batch_id                                     |
 -- |                                                                   |
 -- | Returns       :    p_ret_code                                     |
 -- |                                                                   |
 -- +===================================================================+
PROCEDURE OPEN_PO_HDR(
                      p_batch_id  NUMBER
                      ,p_ret_code OUT NOCOPY NUMBER
                     )
IS
    lc_action               VARCHAR2(30);
    lc_rollup_code          po_lines.closed_code%TYPE;
    lc_reason               VARCHAR2(45);
    lc_doctyp               VARCHAR2(10);
    lc_docsubtyp            VARCHAR2(10);
    lc_row_id               VARCHAR2(50):=NULL;
    lc_closed_code          VARCHAR2(20):=NULL;
    lc_authorization_status VARCHAR2(25);
    lc_type_lookup_code     VARCHAR2(25);
    lc_segment1             VARCHAR2(20);
    lc_summary_flag         VARCHAR2(1);
    lc_enabled_flag         VARCHAR2(1);
    lc_close_code           po_headers.closed_code%TYPE;
    ln_userid               po_lines.last_updated_by%TYPE;
    ln_loginid              po_lines.last_update_login%TYPE;
    ln_doc_id               NUMBER;
    ln_agent_id             NUMBER;
    ln_org_id               po_headers.org_id%TYPE;
--CURSOR DECLARATION

CURSOR lcu_header_details_curr(p_batch_id NUMBER)
IS
SELECT POH.ROWID
 ,POH.po_header_id
 ,POH.agent_id
 ,POH.type_lookup_code
 ,POH.last_update_date
 ,POH.last_updated_by
 ,POH.segment1
 ,POH.summary_flag
 ,POH.enabled_flag
 ,POH.segment2
 ,POH.segment3
 ,POH.segment4
 ,POH.segment5
 ,POH.start_date_active
 ,POH.end_date_active
 ,POH.last_update_login
 ,POH.vendor_id
 ,POH.vendor_site_id
 ,POH.vendor_contact_id
 ,POH.pcard_id
 ,POH.ship_to_location_id
 ,POH.bill_to_location_id
 ,POH.terms_id
 ,POH.ship_via_lookup_code
 ,POH.fob_lookup_code
 ,POH.pay_on_code
 ,POH.freight_terms_lookup_code
 ,POH.status_lookup_code
 ,POH.currency_code
 ,POH.rate_type
 ,POH.rate_date
 ,POH.rate
 ,POH.from_header_id
 ,POH.from_type_lookup_code
 ,POH.start_date
 ,POH.end_date
 ,POH.blanket_total_amount
 ,POH.authorization_status
 ,POH.revision_num
 ,POH.revised_date
 ,POH.approved_flag
 ,POH.approved_date
 ,POH.amount_limit
 ,POH.min_release_amount
 ,POH.note_to_authorizer
 ,POH.note_to_vendor
 ,POH.note_to_receiver
 ,POH.print_count
 ,POH.printed_date
 ,POH.vendor_order_num
 ,POH.confirming_order_flag
 ,POH.comments
 ,POH.reply_date
 ,POH.reply_method_lookup_code
 ,POH.rfq_close_date
 ,POH.quote_type_lookup_code
 ,POH.quotation_class_code
 ,POH.quote_warning_delay_unit
 ,POH.quote_warning_delay
 ,POH.quote_vendor_quote_number
 ,POH.acceptance_required_flag
 ,POH.acceptance_due_date
 ,POH.closed_date
 ,POH.user_hold_flag
 ,POH.approval_required_flag
 ,POH.cancel_flag
 ,POH.firm_status_lookup_code
 ,POH.firm_date
 ,POH.frozen_flag
 ,POH.attribute_category
 ,POH.attribute1
 ,POH.attribute2
 ,POH.attribute3
 ,POH.attribute4
 ,POH.attribute5
 ,POH.attribute6
 ,POH.attribute7
 ,POH.attribute8
 ,POH.attribute9
 ,POH.attribute10
 ,POH.attribute11
 ,POH.attribute12
 ,POH.attribute13
 ,POH.attribute14
 ,POH.attribute15
 ,POH.closed_code
 ,POH.ussgl_transaction_code
 ,POH.government_context
 ,POH.supply_agreement_flag
 ,POH.price_update_tolerance
 ,POH.global_attribute_category
 ,POH.global_attribute1
 ,POH.global_attribute2
 ,POH.global_attribute3
 ,POH.global_attribute4
 ,POH.global_attribute5
 ,POH.global_attribute6
 ,POH.global_attribute7
 ,POH.global_attribute8
 ,POH.global_attribute9
 ,POH.global_attribute10
 ,POH.global_attribute11
 ,POH.global_attribute12
 ,POH.global_attribute13
 ,POH.global_attribute14
 ,POH.global_attribute15
 ,POH.global_attribute16
 ,POH.global_attribute17
 ,POH.global_attribute18
 ,POH.global_attribute19
 ,POH.global_attribute20
 ,POH.shipping_control
 ,POH.encumbrance_required_flag
 ,POH.conterms_articles_upd_date
 ,POH.conterms_deliv_upd_date
 ,XXSA.mass_update_id
 FROM po_headers_v POH
      ,xx_po_mass_upd_po_status_all XXSA
WHERE XXSA.batch_id = p_batch_id
AND   XXSA.process_status = 'NEW'
AND   POH.PO_HEADER_ID=XXSA.po_header_id;

BEGIN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'PROCEDURE: OPEN_PO_HDR');
       FOR lcu_process_massupd_curr_rec IN lcu_header_details_curr(p_batch_id)
       LOOP

        ln_userid := FND_GLOBAL.USER_ID;
        ln_loginid := FND_GLOBAL.LOGIN_ID;

             BEGIN
                PO_HEADERS_PKG_S2.UPDATE_ROW(
                                             X_Rowid                          =>lcu_process_massupd_curr_rec.ROWID
                                            ,X_Po_Header_Id                   =>lcu_process_massupd_curr_rec.po_header_id
                                            ,X_Agent_Id                       =>lcu_process_massupd_curr_rec.agent_id
                                            ,X_Type_Lookup_Code               =>lcu_process_massupd_curr_rec.type_lookup_code
                                            ,X_Last_Update_Date               =>SYSDATE
                                            ,X_Last_Updated_By                =>ln_userid
                                            ,X_Segment1                       =>lcu_process_massupd_curr_rec.segment1
                                            ,X_Summary_Flag                   =>lcu_process_massupd_curr_rec.summary_flag
                                            ,X_Enabled_Flag                   =>lcu_process_massupd_curr_rec.enabled_flag
                                            ,X_Segment2                       =>lcu_process_massupd_curr_rec.Segment2
                                            ,X_Segment3                       =>lcu_process_massupd_curr_rec.Segment3
                                            ,X_Segment4                       =>lcu_process_massupd_curr_rec.Segment4
                                            ,X_Segment5                       =>lcu_process_massupd_curr_rec.Segment5
                                            ,X_Start_Date_Active              =>lcu_process_massupd_curr_rec.Start_Date_Active
                                            ,X_End_Date_Active                =>lcu_process_massupd_curr_rec.End_Date_Active
                                            ,X_Last_Update_Login              =>ln_loginid
                                            ,X_Vendor_Id                      =>lcu_process_massupd_curr_rec.Vendor_Id
                                            ,X_Vendor_Site_Id                 =>lcu_process_massupd_curr_rec.Vendor_Site_Id
                                            ,X_Vendor_Contact_Id              =>lcu_process_massupd_curr_rec.Vendor_Contact_Id
                                            ,X_Pcard_Id                       =>lcu_process_massupd_curr_rec.Pcard_Id
                                            ,X_Ship_To_Location_Id            =>lcu_process_massupd_curr_rec.Ship_To_Location_Id
                                            ,X_Bill_To_Location_Id            =>lcu_process_massupd_curr_rec.Bill_To_Location_Id
                                            ,X_Terms_Id                       =>lcu_process_massupd_curr_rec.Terms_Id
                                            ,X_Ship_Via_Lookup_Code           =>lcu_process_massupd_curr_rec.Ship_Via_Lookup_Code
                                            ,X_Fob_Lookup_Code                =>lcu_process_massupd_curr_rec.Fob_Lookup_Code
                                            ,X_Pay_On_Code                    =>lcu_process_massupd_curr_rec.Pay_On_Code
                                            ,X_Freight_Terms_Lookup_Code      =>lcu_process_massupd_curr_rec.Freight_Terms_Lookup_Code
                                            ,X_Status_Lookup_Code             =>lcu_process_massupd_curr_rec.Status_Lookup_Code
                                            ,X_Currency_Code                  =>lcu_process_massupd_curr_rec.Currency_Code
                                            ,X_Rate_Type                      =>lcu_process_massupd_curr_rec.Rate_Type
                                            ,X_Rate_Date                      =>lcu_process_massupd_curr_rec.Rate_Date
                                            ,X_Rate                           =>lcu_process_massupd_curr_rec.Rate
                                            ,X_From_Header_Id                 =>lcu_process_massupd_curr_rec.From_Header_Id
                                            ,X_From_Type_Lookup_Code          =>lcu_process_massupd_curr_rec.From_Type_Lookup_Code
                                            ,X_Start_Date                     =>lcu_process_massupd_curr_rec.Start_Date
                                            ,X_End_Date                       =>lcu_process_massupd_curr_rec.End_Date
                                            ,X_Blanket_Total_Amount           =>lcu_process_massupd_curr_rec.Blanket_Total_Amount
                                            ,X_Authorization_Status           =>lcu_process_massupd_curr_rec.authorization_status
                                            ,X_Revision_Num                   =>lcu_process_massupd_curr_rec.Revision_Num
                                            ,X_Revised_Date                   =>lcu_process_massupd_curr_rec.Revised_Date
                                            ,X_Approved_Flag                  =>lcu_process_massupd_curr_rec.Approved_Flag
                                            ,X_Approved_Date                  =>lcu_process_massupd_curr_rec.Approved_Date
                                            ,X_Amount_Limit                   =>lcu_process_massupd_curr_rec.Amount_Limit
                                            ,X_Min_Release_Amount             =>lcu_process_massupd_curr_rec.Min_Release_Amount
                                            ,X_Note_To_Authorizer             =>lcu_process_massupd_curr_rec.Note_To_Authorizer
                                            ,X_Note_To_Vendor                 =>lcu_process_massupd_curr_rec.Note_To_Vendor
                                            ,X_Note_To_Receiver               =>lcu_process_massupd_curr_rec.Note_To_Receiver
                                            ,X_Print_Count                    =>lcu_process_massupd_curr_rec.Print_Count
                                            ,X_Printed_Date                   =>lcu_process_massupd_curr_rec.Printed_Date
                                            ,X_Vendor_Order_Num               =>lcu_process_massupd_curr_rec.Vendor_Order_Num
                                            ,X_Confirming_Order_Flag          =>lcu_process_massupd_curr_rec.Confirming_Order_Flag
                                            ,X_Comments                       =>'Mass Update-PO Open'
                                            ,X_Reply_Date                     =>lcu_process_massupd_curr_rec.Reply_Date
                                            ,X_Reply_Method_Lookup_Code       =>lcu_process_massupd_curr_rec.Reply_Method_Lookup_Code
                                            ,X_Rfq_Close_Date                 =>lcu_process_massupd_curr_rec.Rfq_Close_Date
                                            ,X_Quote_Type_Lookup_Code         =>lcu_process_massupd_curr_rec.Quote_Type_Lookup_Code
                                            ,X_Quotation_Class_Code           =>lcu_process_massupd_curr_rec.Quotation_Class_Code
                                            ,X_Quote_Warning_Delay_Unit       =>lcu_process_massupd_curr_rec.Quote_Warning_Delay_Unit
                                            ,X_Quote_Warning_Delay            =>lcu_process_massupd_curr_rec.Quote_Warning_Delay
                                            ,X_Quote_Vendor_Quote_Number      =>lcu_process_massupd_curr_rec.Quote_Vendor_Quote_Number
                                            ,X_Acceptance_Required_Flag       =>lcu_process_massupd_curr_rec.Acceptance_Required_Flag
                                            ,X_Acceptance_Due_Date            =>lcu_process_massupd_curr_rec.Acceptance_Due_Date
                                            ,X_Closed_Date                    =>lcu_process_massupd_curr_rec.Closed_Date
                                            ,X_User_Hold_Flag                 =>lcu_process_massupd_curr_rec.User_Hold_Flag
                                            ,X_Approval_Required_Flag         =>lcu_process_massupd_curr_rec.Approval_Required_Flag
                                            ,X_Cancel_Flag                    =>lcu_process_massupd_curr_rec.Cancel_Flag
                                            ,X_Firm_Status_Lookup_Code        =>lcu_process_massupd_curr_rec.Firm_Status_Lookup_Code
                                            ,X_Firm_Date                      =>lcu_process_massupd_curr_rec.Firm_Date
                                            ,X_Frozen_Flag                    =>lcu_process_massupd_curr_rec.Frozen_Flag
                                            ,X_Attribute_Category             =>lcu_process_massupd_curr_rec.Attribute_Category
                                            ,X_Attribute1                     =>lcu_process_massupd_curr_rec.Attribute1
                                            ,X_Attribute2                     =>lcu_process_massupd_curr_rec.Attribute2
                                            ,X_Attribute3                     =>lcu_process_massupd_curr_rec.Attribute3
                                            ,X_Attribute4                     =>lcu_process_massupd_curr_rec.Attribute4
                                            ,X_Attribute5                     =>lcu_process_massupd_curr_rec.Attribute5
                                            ,X_Attribute6                     =>lcu_process_massupd_curr_rec.Attribute6
                                            ,X_Attribute7                     =>lcu_process_massupd_curr_rec.Attribute7
                                            ,X_Attribute8                     =>lcu_process_massupd_curr_rec.Attribute8
                                            ,X_Attribute9                     =>lcu_process_massupd_curr_rec.Attribute9
                                            ,X_Attribute10                    =>lcu_process_massupd_curr_rec.Attribute10
                                            ,X_Attribute11                    =>lcu_process_massupd_curr_rec.Attribute11
                                            ,X_Attribute12                    =>lcu_process_massupd_curr_rec.Attribute12
                                            ,X_Attribute13                    =>lcu_process_massupd_curr_rec.Attribute13
                                            ,X_Attribute14                    =>lcu_process_massupd_curr_rec.Attribute14
                                            ,X_Attribute15                    =>lcu_process_massupd_curr_rec.Attribute15
                                            ,X_Closed_Code                    =>'OPEN'
                                            ,X_Ussgl_Transaction_Code         =>lcu_process_massupd_curr_rec.Ussgl_Transaction_Code
                                            ,X_Government_Context             =>lcu_process_massupd_curr_rec.Government_Context
                                            ,X_Supply_Agreement_flag          =>lcu_process_massupd_curr_rec.Supply_Agreement_flag
                                            ,X_Price_Update_Tolerance         =>lcu_process_massupd_curr_rec.Price_Update_Tolerance
                                            ,X_Global_Attribute_Category      =>lcu_process_massupd_curr_rec.Global_Attribute_Category
                                            ,X_Global_Attribute1              =>lcu_process_massupd_curr_rec.Global_Attribute1
                                            ,X_Global_Attribute2              =>lcu_process_massupd_curr_rec.Global_Attribute2
                                            ,X_Global_Attribute3              =>lcu_process_massupd_curr_rec.Global_Attribute3
                                            ,X_Global_Attribute4              =>lcu_process_massupd_curr_rec.Global_Attribute4
                                            ,X_Global_Attribute5              =>lcu_process_massupd_curr_rec.Global_Attribute5
                                            ,X_Global_Attribute6              =>lcu_process_massupd_curr_rec.Global_Attribute6
                                            ,X_Global_Attribute7              =>lcu_process_massupd_curr_rec.Global_Attribute7
                                            ,X_Global_Attribute8              =>lcu_process_massupd_curr_rec.Global_Attribute8
                                            ,X_Global_Attribute9              =>lcu_process_massupd_curr_rec.Global_Attribute9
                                            ,X_Global_Attribute10             =>lcu_process_massupd_curr_rec.Global_Attribute10
                                            ,X_Global_Attribute11             =>lcu_process_massupd_curr_rec.Global_Attribute11
                                            ,X_Global_Attribute12             =>lcu_process_massupd_curr_rec.Global_Attribute12
                                            ,X_Global_Attribute13             =>lcu_process_massupd_curr_rec.Global_Attribute13
                                            ,X_Global_Attribute14             =>lcu_process_massupd_curr_rec.Global_Attribute14
                                            ,X_Global_Attribute15             =>lcu_process_massupd_curr_rec.Global_Attribute15
                                            ,X_Global_Attribute16             =>lcu_process_massupd_curr_rec.Global_Attribute16
                                            ,X_Global_Attribute17             =>lcu_process_massupd_curr_rec.Global_Attribute17
                                            ,X_Global_Attribute18             =>lcu_process_massupd_curr_rec.Global_Attribute18
                                            ,X_Global_Attribute19             =>lcu_process_massupd_curr_rec.Global_Attribute19
                                            ,X_Global_Attribute20             =>lcu_process_massupd_curr_rec.Global_Attribute20
                                            ,p_shipping_control               =>lcu_process_massupd_curr_rec.shipping_control
                                            ,p_encumbrance_required_flag      =>lcu_process_massupd_curr_rec.encumbrance_required_flag
                                            ,p_kterms_art_upd_date            =>lcu_process_massupd_curr_rec.conterms_articles_upd_date
                                            ,p_kterms_deliv_upd_date          =>lcu_process_massupd_curr_rec.conterms_deliv_upd_date
                                            );

             COMMIT WORK;

             EXCEPTION
             WHEN OTHERS THEN
                gc_error_code:=SQLERRM;
                gc_error_detail := gc_error_detail||'PO_NUMBER :'||lcu_process_massupd_curr_rec.segment1||'-'||gc_error_code;
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
                p_ret_code:=2;
                FND_FILE.PUT_LINE(FND_FILE.LOG,' Err code: '||p_ret_code);
                RAISE;
        END;
     IF (gc_error_detail IS NULL) THEN
          IF NOT PO_ACTIONS.UPDATE_ACTION_HISTORY(
                                                   p_docid     => lcu_process_massupd_curr_rec.po_header_id
                                                  ,p_doctyp    => 'PO'
                                                  ,p_docsubtyp => 'STANDARD'
                                                  ,p_lineid    => NULL
                                                  ,p_shipid    => NULL
                                                  ,p_action    => 'OPEN'
                                                  ,p_empid     => ln_userid
                                                  ,p_userid    => ln_userid
                                                  ,p_loginid   => ln_loginid
                                                  ,p_reason    => 'Mass Update-PO Open') THEN

                gc_error_detail:='Procedure: Open_PO_HDR, PO_ACTIONS.update_action_history Returns False';

                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
                UPDATE  xx_po_mass_upd_po_status_all
                SET     process_status='ERROR'
                        ,error_description = gc_error_detail
                WHERE   mass_update_id = lcu_process_massupd_curr_rec.mass_update_id;
          ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG,'HDR Open Is Successful');
                UPDATE  xx_po_mass_upd_po_status_all
                SET     process_status='PROCESSED'
                WHERE   mass_update_id = lcu_process_massupd_curr_rec.mass_update_id;
          END IF;
     ELSIF (gc_error_detail IS NOT NULL) THEN
       UPDATE  xx_po_mass_upd_po_status_all
       SET     process_status='ERROR'
              ,error_description = gc_error_detail
       WHERE   mass_update_id = lcu_process_massupd_curr_rec.mass_update_id;

     END IF;
   END LOOP;

EXCEPTION
   WHEN OTHERS THEN
     gc_error_code     :=SQLERRM;
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,gc_error_code);
     gc_error_detail := gc_error_detail||','||gc_error_code;
     UPDATE     xx_po_mass_upd_po_status_all
     SET        process_status='ERROR'
                ,error_description = gc_error_detail
     WHERE      batch_id = p_batch_id;
    COMMIT;
    p_ret_code:=2;
    FND_FILE.PUT_LINE(FND_FILE.LOG,' Err code: last '||p_ret_code);
    RAISE;
END OPEN_PO_HDR;

 -- +===================================================================+
 -- | Name          : Approve_PO_HDR                                    |
 -- | Description   : This Procedure will be used to approve the        |
 -- |                 POs on mass basis                                 |
 -- |                                                                   |
 -- | Parameters    :    p_batch_id                                     |
 -- |                                                                   |
 -- |                                                                   |
 -- | Returns       :                                                   |
 -- |                                                                   |
 -- +===================================================================+
PROCEDURE APPROVE_PO_HDR(
                         p_batch_id NUMBER
                         )
IS
ln_agent_id             NUMBER;
lc_authorization_status VARCHAR2(25);
lc_Item_Key             VARCHAR2(50);
gc_error_detail         VARCHAR2(2000) := NULL;
lc_user_hold_flag       VARCHAR2(1)    := NULL;
--CURSOR DECLARATION
CURSOR lcu_po_approve_curr(p_batch_id NUMBER)
IS
SELECT DISTINCT po_number
        ,po_header_id
FROM   xx_po_mass_upd_po_status_all
WHERE  batch_id=p_batch_id
AND    process_status IN ('NEW','UPD-NEW');

BEGIN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: APPROVE_PO_HDR');
       FOR lcu_po_approve_curr_rec
       IN lcu_po_approve_curr(p_batch_id)
       LOOP
           BEGIN
              SELECT   agent_id
                       ,NVL(authorization_status,'INCOMPLETE')
                       ,po_header_id||'-'||TO_CHAR(po_wf_itemkey_s.NEXTVAL)
                       ,NVL(user_hold_flag,'N')
              INTO     ln_agent_id
                       ,lc_authorization_status
                       ,lc_Item_Key
                       ,lc_user_hold_flag
              FROM      po_headers_v
              WHERE     segment1=lcu_po_approve_curr_rec.po_number;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
                gc_error_detail:='Procedure APPROVE_PO_HDR,Exception:NO_DATA_FOUND, PO Number Not Found ';
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
             WHEN OTHERS THEN
                gc_error_detail:='Procedure APPROVE_PO_HDR,Exception:OTHERS, while selecting agent_id,authorization_status from po_headers_v ';
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
           END;
        IF (lc_authorization_status) IN ('INCOMPLETE','REQUIRES REAPPROVAL') AND
           (lc_user_hold_flag) NOT IN ('Y')THEN
            BEGIN
                PO_REQAPPROVAL_INIT1.START_WF_PROCESS(
                                                      ItemType                => 'POAPPRV'
                                                      ,ItemKey                => lc_item_key
                                                      ,WorkflowProcess        => 'POAPPRV_TOP'
                                                      ,ActionOriginatedFrom   => NULL
                                                      ,DocumentID             => lcu_po_approve_curr_rec.po_header_id
                                                      ,DocumentNumber         => lcu_po_approve_curr_rec.po_number
                                                      ,PreparerID             => ln_agent_id
                                                      ,DocumentTypeCode       => 'PO'
                                                      ,DocumentSubtype        => 'STANDARD'
                                                      ,SubmitterAction        => NULL
                                                      ,forwardToID            => NULL
                                                      ,forwardFromID          => ln_agent_id
                                                      ,DefaultApprovalPathID  => NULL
                                                      ,Note                   => 'Mass Update PO'
                                                      ,printFlag              => 'N'
                                                      ,FaxFlag                => 'N'
                                                      ,FaxNumber              => NULL
                                                      ,EmailFlag              => 'N'
                                                      ,EmailAddress           => NULL
                                                      ,CreateSourcingRule     => NULL
                                                      ,ReleaseGenMethod       => NULL
                                                      ,UpdateSourcingRule     => NULL
                                                      ,MassUpdateReleases     => NULL
                                                      ,RetroactivePriceChange => NULL
                                                      ,OrgAssignChange        => NULL
                                                      ,CommunicatePriceChange => NULL
                                                      ,p_Background_Flag      => NULL
                                                      );
            EXCEPTION
               WHEN OTHERS THEN
                   gc_error_code := SQLERRM;
                   gc_error_detail:=gc_error_detail||-'Exception:Others occured while calling the Approval Workflow '||'SQLERRM: '||gc_error_code;
            END;
        ELSIF (lc_authorization_status) IN ('INCOMPLETE','REQUIRES REAPPROVAL') AND
              (lc_user_hold_flag) IN ('Y') THEN
             gc_error_detail:=gc_error_detail ||'Order is in hold, Cannot be Approved';
        ELSIF (lc_authorization_status) NOT IN ('INCOMPLETE','REQUIRES REAPPROVAL') THEN
             gc_error_detail := gc_error_detail ||'-The PO' || lcu_po_approve_curr_rec.po_number ||' Authorization status is: '||lc_authorization_status||', Please Select Orders with Authorization status REQUIRES REAPPROVAL or INCOMPLETE ';
             FND_FILE.PUT_LINE(FND_FILE.LOG,'The PO ' || lcu_po_approve_curr_rec.po_number ||' cannot be approved '||gc_error_detail);
        END IF;
        IF gc_error_detail IS NULL THEN
          UPDATE  xx_po_mass_upd_po_status_all
          SET     process_status='PROCESSED'
          WHERE   po_number = lcu_po_approve_curr_rec.po_number;
        ELSIF gc_error_detail IS NOT NULL THEN
          UPDATE  xx_po_mass_upd_po_status_all
          SET     process_status='ERROR'
                  ,approval_status = lc_authorization_status
                  ,error_description = gc_error_detail
          WHERE    po_number = lcu_po_approve_curr_rec.po_number;
        END IF;
       COMMIT;
       gc_error_detail := NULL;
       lc_authorization_status := NULL;
       END LOOP;
EXCEPTION
  WHEN OTHERS THEN
  gc_error_code:=SQLERRM;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'WHEN OTHERS in Approve PO Main Begin '||gc_error_code);
END APPROVE_PO_HDR;
                                                    
 -- +===================================================================+
 -- | Name          : Close PO HDR                                      |
 -- | Description   : This Procedure will close                         |
 -- |                 the POs on mass basis                             |
 -- |                                                                   |
 -- | Parameters    :    p_batch_id                                     |
 -- |                                                                   |
 -- | Returns       :                                                   |
 -- |                                                                   |
 -- +=========================================================+=========+
PROCEDURE CLOSE_PO_HDR(
                       p_batch_id NUMBER
                       )
IS
gc_error_detail         VARCHAR2(2000)  :=NULL;
xx_return_code          VARCHAR2(20)    :=NULL;
lb_return_status         BOOLEAN;
                                                    
--CURSOR DECLARATION
CURSOR lcu_close_po_hdr_curr(p_batch_id NUMBER)
IS
SELECT po_header_id
       ,mass_update_id
FROM    xx_po_mass_upd_po_status_all
WHERE   batch_id=p_batch_id
AND     process_status   = 'NEW'
AND     UPPER(mass_action_detail)='MASS CLOSE POS';
                                                    
BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: Close_PO_HDR');
     FOR lcu_close_po_hdr_curr_rec
     IN lcu_close_po_hdr_curr(p_batch_id)
     LOOP
        BEGIN
           lb_return_status := PO_ACTIONS.CLOSE_PO(
                                p_docid           =>lcu_close_po_hdr_curr_rec.po_header_id
                                ,p_doctyp         =>'PO'
                                ,p_docsubtyp      =>'STANDARD'
                                ,p_lineid         =>NULL
                                ,p_shipid         =>NULL
                                ,p_action         =>'CLOSE'
                                ,p_reason         =>'Autoclosed for Inactivity'
                                ,p_calling_mode   =>'PO'
                                ,p_conc_flag      =>'Y'
                                ,p_return_code    =>xx_return_code
                                ,p_auto_close     =>'N'
                                ,p_action_date    =>SYSDATE
                                ,p_origin_doc_id  =>NULL
                                );
                                                    
           IF lb_return_status THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'HDR Line Close Is Successful ');
              UPDATE   xx_po_mass_upd_po_status_all
              SET      process_status='PROCESSED'
              WHERE    mass_update_id = lcu_close_po_hdr_curr_rec.mass_update_id;
           ELSE
              gc_error_detail:=('Precedure:Close PO HDR'||'API PO_ACTIONS.close_po Returns False');
              FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
              UPDATE    xx_po_mass_upd_po_status_all
              SET       process_status='ERROR'
                        ,error_description = gc_error_detail
              WHERE     mass_update_id = lcu_close_po_hdr_curr_rec.mass_update_id;
              FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
           END IF;
        EXCEPTION
           WHEN OTHERS THEN
           gc_error_code:=SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: Close_PO_HDR '||gc_error_code);
        END;
        COMMIT;
        gc_error_detail:=NULL;
        gc_error_code:=NULL;
     END LOOP;
END CLOSE_PO_HDR;
                                                    
 -- +===================================================================+
 -- | Name          : Insert_PO_Line                                    |
 -- | Description   : This Procedure Inserts new line  be used to close |
 -- |                 the POs on mass basis                             |
 -- |                                                                   |
 -- | Parameters    :    p_batch_id                                     |
 -- |                                                                   |
 -- | Returns       :                                                   |
 -- |                                                                   |
 -- +===================================================================+
PROCEDURE INSERT_PO_LINE(
                         p_batch_id NUMBER
                         )
IS
 lb_req_status          BOOLEAN;
 lc_status_create       VARCHAR2(50);
 lc_phase_insert        VARCHAR2(50);
 lc_status_insert       VARCHAR2(50);
 lc_devphase_insert     VARCHAR2(50);
 lc_devstatus_insert    VARCHAR2(50);
 lc_message_insert      VARCHAR2(50);
 lc_arg6                VARCHAR2(20);
 lc_vendor_name         po_vendors.vendor_name%TYPE;
 lc_vendor_site_code    po_vendor_sites_all.vendor_site_code%TYPE;
 lc_ship_to_location    hr_locations.location_code%TYPE;
 lc_bill_to_location    hr_locations.location_code%TYPE;
 lc_currency_code       po_headers_all.currency_code%TYPE;
 lc_ship_to_org_code    org_organization_definitions.organization_code%TYPE;
 lc_uom_code            mtl_system_items_b .primary_uom_code%TYPE;
 ln_agent_id            NUMBER;
 ln_ship_to_location_id NUMBER;
 ln_charge_account_id   NUMBER;
 ln_exception_no        NUMBER  :=0;
 ln_line_num            NUMBER  :=0;
 ln_insert_line_req_id  NUMBER  :=0;
 EX_USER_EXCEPTION      EXCEPTION;
                                                    
--Cursor to Get New Line Details
                                                    
CURSOR lcu_newline_insert_curr(p_batch_id NUMBER)
IS
SELECT po_number
      ,po_header_id
      ,org_id
      ,item_number
      ,line_num
      ,line_type
      ,quantity
      ,price
      ,promised_date
      ,attribute_category
      ,attribute2
      ,attribute13
      ,mass_update_id
FROM  xx_po_mass_upd_po_status_all
WHERE batch_id=p_batch_id
AND   line_type IS NOT NULL
AND   process_status='NEW';
                                                    
--Cursor to get interface error details
                                                    
CURSOR lcu_interface_error_curr(p_batch_id NUMBER)
IS
SELECT POIE.error_message
       ,POHI.document_num
       ,POHI.batch_id
       ,POHI.process_code
       ,POLI.line_num
       ,POLI.item
FROM  po_headers_interface POHI
      ,po_lines_interface POLI
      ,po_interface_errors POIE
WHERE POHI.batch_id=p_batch_id
AND   POHI.process_code NOT IN ('ACCEPTED')
AND   POLI.interface_header_id = POHI.interface_header_id
AND   POIE.interface_header_id = POHI.interface_header_id;

 BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: Insert_PO_Line');
    FOR lcu_newline_insert_curr_rec
    IN lcu_newline_insert_curr(p_batch_id)
    LOOP
       BEGIN
          SELECT  POA.currency_code
                  ,POA.agent_id
                  ,PV.vendor_name
                  ,PVSA.vendor_site_code
                  ,HRLS.location_code
                  ,HRLB.location_code
                  ,POA.ship_to_location_id
          INTO    lc_currency_code
                  ,ln_agent_id
                  ,lc_vendor_name
                  ,lc_vendor_site_code
                  ,lc_ship_to_location
                  ,lc_bill_to_location
                  ,ln_ship_to_location_id
          FROM    hr_locations HRLS
                  ,hr_locations HRLB
                  ,po_vendors PV
                  ,po_vendor_sites_all PVSA
                  ,po_headers_v POA
          WHERE POA.segment1 = lcu_newline_insert_curr_rec.po_number
          AND   POA.type_lookup_code='STANDARD'
          AND   PV.vendor_id = POA.vendor_id
          AND   PVSA.vendor_site_id = POA.vendor_site_id
          AND   HRLS.location_id = POA.ship_to_location_id
          AND   HRLB.location_id = POA.bill_to_location_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
            gc_error_detail:='Procedure:Insert_PO_Line, Currency_code,agent_id,vendor_name,vendor_site_code,location_code,location_code,ship_to_location_id not found';
            FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
          WHEN OTHERS THEN
            gc_error_detail:='Procedure:Insert_PO_Line, WHEN OTHERS Exception Occured while getting the vendor name and site code details';
            FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
       END;

       BEGIN
          SELECT DISTINCT primary_uom_code
          INTO   lc_uom_code
          FROM   mtl_system_items_b
          WHERE  segment1 = lcu_newline_insert_curr_rec.item_number;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
            gc_error_detail:=gc_error_detail||'UOM Not Found for the given item';
            FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
          WHEN OTHERS THEN
            gc_error_detail:=gc_error_detail||'When Others Exception Occured while getting the UOM';
            FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
       END;
       
       BEGIN
          SELECT  OOD.organization_code
          INTO    lc_ship_to_org_code
          FROM    org_organization_definitions OOD 
                  ,hr_locations_all HRLA
          WHERE   HRLA.ship_to_location_id = ln_ship_to_location_id
          AND     OOD.organization_id(+) = HRLA.inventory_organization_id;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             gc_error_detail:=gc_error_detail||'SHIP_TO_ORG_CODE Not Found ';
             FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
          WHEN OTHERS THEN
             gc_error_detail:=gc_error_detail||'When Others Exception Occured while getting the SHIP_TO_ORG_CODE';
             FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
       END;

       BEGIN
          SELECT  material_account
          INTO    ln_charge_account_id
          FROM    mtl_parameters
          WHERE   organization_code = lc_ship_to_org_code;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             gc_error_detail:=gc_error_detail||' CHARGE_ACCOUNT_ID NOT FOUND';
             FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
          WHEN OTHERS THEN
             gc_error_detail:=gc_error_detail||' When Others Exception Occured while getting the CHARGE_ACCOUNT_ID';
             FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
       END;

       BEGIN
          IF (gc_error_detail IS NULL) THEN
              INSERT
              INTO  po_headers_interface(
              interface_header_id
              ,batch_id
              ,action
              ,org_id
              ,document_type_code
              ,document_num
              ,currency_code
              ,agent_id
              ,vendor_name
              ,vendor_site_code
              ,ship_to_location
              ,bill_to_location
              ,attribute_category
              )
              VALUES
              (
              po_headers_interface_s.NEXTVAL
              ,p_batch_id
              ,'UPDATE'
              ,lcu_newline_insert_curr_rec.org_id
              ,'STANDARD'
              ,lcu_newline_insert_curr_rec.po_number
              ,lc_currency_code
              ,ln_agent_id
              ,lc_vendor_name
              ,lc_vendor_site_code
              ,lc_ship_to_location
              ,lc_bill_to_location
              ,lcu_newline_insert_curr_rec.attribute_category
              );

              INSERT
              INTO po_lines_interface(
              interface_line_id
              ,interface_header_id
              ,line_num
              ,shipment_num
              ,line_type
              ,item
              ,uom_code
              ,quantity
              ,unit_price
              ,promised_date
              ,ship_to_organization_code
              ,ship_to_location
              ,line_attribute2
              ,line_attribute13
              ,line_attribute_category_lines
              )
              VALUES
              (
               po_lines_interface_s.NEXTVAL
              ,po_headers_interface_s.CURRVAL
              ,lcu_newline_insert_curr_rec.line_num
              ,NULL
              ,lcu_newline_insert_curr_rec.line_type
              ,lcu_newline_insert_curr_rec.item_number
              ,lc_uom_code
              ,lcu_newline_insert_curr_rec.quantity
              ,lcu_newline_insert_curr_rec.price
              ,lcu_newline_insert_curr_rec.promised_date
              ,lc_ship_to_org_code
              ,lc_ship_to_location
              ,lcu_newline_insert_curr_rec.attribute2
              ,lcu_newline_insert_curr_rec.attribute13
              ,lcu_newline_insert_curr_rec.attribute_category
              );

              INSERT
              INTO po_distributions_interface(
              interface_header_id
             ,interface_line_id
             ,interface_distribution_id
             ,distribution_num
             ,quantity_ordered
             ,charge_account_id
             ,attribute_category
             ,attribute2
             ,attribute13
              )
              VALUES
              (
               po_headers_interface_s.CURRVAL
              ,po_lines_interface_s.CURRVAL
              ,po_distributions_interface_s.NEXTVAL
              ,1
              ,lcu_newline_insert_curr_rec.quantity
              ,ln_charge_account_id
              ,lcu_newline_insert_curr_rec.attribute_category
              ,lcu_newline_insert_curr_rec.attribute2
              ,lcu_newline_insert_curr_rec.attribute13
              );
                                                   
              UPDATE    xx_po_mass_upd_po_status_all
              SET       process_status=DECODE(gc_rev_ctrl_flag
                                             ,NULL,'PROCESSED'
                                             ,'NEW')
                        ,approval_status = 'APPROVED'
                        ,error_description = gc_error_detail
              WHERE     mass_update_id = lcu_newline_insert_curr_rec.mass_update_id;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Executed '||lcu_newline_insert_curr_rec.po_number);
        ELSE
              UPDATE    xx_po_mass_upd_po_status_all
              SET       process_status='ERROR'
                       ,error_description = gc_error_detail
              WHERE     mass_update_id     = lcu_newline_insert_curr_rec.mass_update_id;
              FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
        END IF;
       EXCEPTION
          WHEN OTHERS THEN
            gc_error_code:=SQLERRM;
            gc_error_detail:=gc_error_detail||'Exception Others Occured while inserting into the Interface Tables ';
            UPDATE  xx_po_mass_upd_po_status_all
            SET     process_status='ERROR'
                    ,error_description = gc_error_code
            WHERE mass_update_id = lcu_newline_insert_curr_rec.mass_update_id;
                               
            FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||','||gc_error_code);
       END;
     gc_error_code:=NULL;
    gc_error_detail:=NULL;
    END LOOP;
    COMMIT;

IF gc_rev_ctrl_flag IN ('Y') THEN
lc_arg6 := 'INCOMPLETE';
ELSE
lc_arg6 := 'INITIATE APPROVAL';
END IF;
                                 
    ln_insert_line_req_id:=FND_REQUEST.SUBMIT_REQUEST(
                                                      APPLICATION  => 'PO'
                                                     ,PROGRAM      => 'POXPOPDOI'
                                                     ,DESCRIPTION  => NULL
                                                     ,START_TIME   => NULL
                                                     ,SUB_REQUEST  => NULL
                                                     ,ARGUMENT1    => NULL
                                                     ,ARGUMENT2    => 'STANDARD'
                                                     ,ARGUMENT3    => NULL
                                                     ,ARGUMENT4    => 'N'
                                                     ,ARGUMENT5    => NULL
                                                     ,ARGUMENT6    => lc_arg6
                                                     ,ARGUMENT7    => NULL
                                                     ,ARGUMENT8    => p_batch_id
                                                     ,ARGUMENT9    => NULL
                                                     ,ARGUMENT10   => NULL
                                                     );
      COMMIT;
     lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                      ln_insert_line_req_id
                                                     ,'15'
                                                     ,''
                                                     ,lc_phase_insert
                                                     ,lc_status_insert
                                                     ,lc_devphase_insert
                                                     ,lc_devstatus_insert
                                                     ,lc_message_insert
                                                     );
            --Checking the status of the 'Import Items' program
            IF (lc_status_insert = 'Warning') THEN
                gc_ret_code := 1;
                gc_error_detail := 'Conc Prog Completed with Warning, Req Id ';
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||ln_insert_line_req_id);
                FOR lcu_interface_error_curr_rec
                IN lcu_interface_error_curr(p_batch_id)
                LOOP
                EXIT WHEN lcu_interface_error_curr%NOTFOUND;
                     BEGIN
                        UPDATE  xx_po_mass_upd_po_status_all
                        SET     process_status='ERROR'
                                ,error_description = lcu_interface_error_curr_rec.error_message
                        WHERE   batch_id = lcu_interface_error_curr_rec.batch_id
                        AND     po_number = lcu_interface_error_curr_rec.document_num
                        AND     item_number = lcu_interface_error_curr_rec.item;
                     EXCEPTION
                     WHEN OTHERS THEN
                       gc_error_code := SQLERRM;
                       gc_error_loc := 'Insert Line Conc Program Failed: Error while updating the table with error details';
                       FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||','||gc_error_code||','||gc_error_loc);
                     END;
                END LOOP;
                COMMIT;
                RAISE EX_USER_EXCEPTION;
            ELSIF (lc_status_insert = 'Error') THEN
                gc_ret_code := 2;
                gc_error_detail := 'Conc Prog Completed with Errors, Req Id ';
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||ln_insert_line_req_id);
                FOR lcu_interface_error_curr_rec
                IN lcu_interface_error_curr(p_batch_id)
                LOOP
                EXIT WHEN lcu_interface_error_curr%NOTFOUND;
                     BEGIN
                        UPDATE  xx_po_mass_upd_po_status_all
                        SET     process_status='ERROR'
                                ,error_description = lcu_interface_error_curr_rec.error_message
                        WHERE   batch_id = lcu_interface_error_curr_rec.batch_id
                        AND     po_number = lcu_interface_error_curr_rec.document_num
                        AND     item_number = lcu_interface_error_curr_rec.item;
                     EXCEPTION
                     WHEN OTHERS THEN
                       gc_error_code := SQLERRM;
                       gc_error_loc := 'Insert Line Conc Program Failed: Error While Updating the table with error details';
                       FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||','||gc_error_code||','||gc_error_loc);
                     END;
                     END LOOP;
                     gc_error_detail := NULL;
                     gc_error_code   := NULL;
                     gc_error_loc    := NULL;
                COMMIT;
                RAISE EX_USER_EXCEPTION;
            ELSE 
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||ln_insert_line_req_id);
                FOR lcu_interface_error_curr_rec
                IN lcu_interface_error_curr(p_batch_id)
                LOOP
                EXIT WHEN lcu_interface_error_curr%NOTFOUND;
                     BEGIN
                        UPDATE  xx_po_mass_upd_po_status_all
                        SET     process_status=DECODE(lcu_interface_error_curr_rec.process_code
                                                      ,'REJECTED','ERROR')
                                ,error_description = lcu_interface_error_curr_rec.error_message
                        WHERE   batch_id = lcu_interface_error_curr_rec.batch_id
                        AND     po_number = lcu_interface_error_curr_rec.document_num
                        AND     item_number = lcu_interface_error_curr_rec.item;
                     EXCEPTION
                     WHEN OTHERS THEN
                       gc_error_code := SQLERRM;
                       gc_error_loc := 'Insert Line Conc Program Failed: Error while updating the table with error details';
                       FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||','||gc_error_code||','||gc_error_loc);
                     END;
                     gc_error_detail := NULL;
                     gc_error_code   := NULL;
                     gc_error_loc    := NULL;
                     END LOOP;
                COMMIT;
            END IF;
                           
 EXCEPTION
   WHEN EX_USER_EXCEPTION THEN
     UPDATE  xx_po_mass_upd_po_status_all
     SET     process_status='ERROR'
             ,error_description = gc_error_detail||' '||gc_error_code
     WHERE   batch_id = p_batch_id;
    gc_error_code:=NULL;
   WHEN OTHERS THEN
     gc_error_code:=SQLERRM;
   UPDATE  xx_po_mass_upd_po_status_all
   SET     process_status='ERROR'
           ,error_description = gc_error_detail||' '||gc_error_code
   WHERE   batch_id = p_batch_id;
   gc_error_code:=NULL;
END INSERT_PO_LINE;
                            
 -- +===================================================================+
 -- | Name          : Close_PO_HDR_Line                                 |
 -- | Description   : This Procedure will be used to close the          |
 -- |                 PO Lines on mass basis                            |
 -- |                                                                   |
 -- | Parameters    :       p_batch_id                                  |
 -- |                                                                   |
 -- |                                                                   |
 -- | Returns       :                                                   |
 -- |                                                                   |
 -- |                                                                   |
 -- +=========================================================+=========+
PROCEDURE CLOSE_PO_HDR_LINE(
                            p_batch_id NUMBER
                            )
IS
--VARIABLE DECLARATION
xx_return_code          VARCHAR2(40)   := NULL;
gc_error_detail         VARCHAR2(2000) := NULL;
lb_return_status         BOOLEAN;

--CURSOR DECLARATION
CURSOR lcu_close_po_line_curr(p_batch_id NUMBER) IS
SELECT po_header_id
       ,po_line_id
       ,mass_update_id
FROM    xx_po_mass_upd_po_status_all
WHERE   batch_id=p_batch_id
AND     mass_action_detail = 'LINE CLOSE'
AND     process_status  = 'NEW';

BEGIN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: Close_PO_HDR_Line');
     FOR lcu_close_po_line_curr_rec
     IN lcu_close_po_line_curr(p_batch_id)
     LOOP
         BEGIN
            lb_return_status := PO_ACTIONS.CLOSE_PO(
                                 p_docid =>        lcu_close_po_line_curr_rec.po_header_id
                                 ,p_doctyp =>       'PO'
                                 ,p_docsubtyp=>     'STANDARD'
                                 ,p_lineid =>       lcu_close_po_line_curr_rec.po_line_id
                                 ,p_shipid=>        NULL
                                 ,p_action=>        'CLOSE'
                                 ,p_reason=>        'Autoclosed for Inactivity'
                                 ,p_calling_mode => 'PO'
                                 ,p_conc_flag =>    'Y'
                                 ,p_return_code=>   xx_return_code
                                 ,p_auto_close=>    'N'
                                 ,p_action_date=>   SYSDATE
                                 ,p_origin_doc_id=> NULL
                                 );
            IF lb_return_status THEN
                UPDATE  xx_po_mass_upd_po_status_all
                SET     process_status = 'PROCESSED'
                WHERE   mass_update_id = lcu_close_po_line_curr_rec.mass_update_id;
            ELSE
                gc_error_detail:=('Precedure:Close PO HDR'||'API PO_ACTIONS.close_po Returns False');
                gc_error_code:=SQLERRM;
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||','||gc_error_code);
                UPDATE  xx_po_mass_upd_po_status_all
                SET     process_status = 'ERROR'
                        ,error_description = gc_error_detail||','||gc_error_code
                WHERE   mass_update_id = lcu_close_po_line_curr_rec.mass_update_id;
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               gc_error_code:=SQLERRM;
               FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code||' Exception:Others Occured while calling the API PO_ACTIONS');
         END;
         COMMIT;
     END LOOP;
END CLOSE_PO_HDR_LINE;
                                            
 -- +===================================================================+
 -- | Name          : Update_PO_Line                                    |
 -- | Description   : This Procedure will be used to update the         |
 -- |                 PO Lines on mass basis                            |
 -- |                                                                   |
 -- | Parameters    :       p_batch_id                                  |
 -- |                                                                   |
 -- | Returns       :                                                   |
 -- |                                                                   |
 -- +===================================================================+
PROCEDURE UPDATE_PO_LINE(
                         p_batch_id NUMBER
                         )
IS
                                              
gc_error_detail   VARCHAR2(2000) := NULL;
lc_buyer_name     per_all_people_f.full_name%TYPE;
l_api_errors      po_api_errors_rec_type;
ln_err_var        NUMBER;
lc_la_flag        VARCHAR2(2);
ln_rev_num        NUMBER;
                                                
CURSOR lcu_upd_po_line_curr(p_batch_id NUMBER) IS
SELECT po_header_id
       ,po_number
       ,po_line_id
       ,revision_no
       ,line_num
       ,quantity
       ,price
       ,promised_date
       ,mass_update_id
FROM    xx_po_mass_upd_po_status_all
WHERE   batch_id=p_batch_id
AND     process_status     = 'NEW'
AND     mass_action_detail = 'LINE UPDATE';
                                               
CURSOR lcu_upd_po_ship_curr(p_header_id NUMBER, p_line_id NUMBER)
IS
SELECT shipment_num
FROM po_line_locations_v
WHERE po_header_id = p_header_id
AND po_line_id=p_line_id;
                                                
BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: Update_PO_Line');
                                       
      FOR lcu_upd_po_line_curr_rec
      IN lcu_upd_po_line_curr(p_batch_id)
      LOOP
        EXIT WHEN lcu_upd_po_line_curr%NOTFOUND;
        BEGIN
           SELECT revision_num
           INTO   ln_rev_num
           FROM   po_headers_v
           WHERE  po_header_id=lcu_upd_po_line_curr_rec.po_header_id;
        EXCEPTION
        WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
        END;
        FOR lcu_upd_po_ship_curr_rec
        IN lcu_upd_po_ship_curr(lcu_upd_po_line_curr_rec.po_header_id,lcu_upd_po_line_curr_rec.po_line_id)
        LOOP
          BEGIN
             SELECT PPF.full_name
             INTO   lc_buyer_name
             FROM   po_headers_v POH
                    ,per_all_people_f PPF
             WHERE  POH.po_header_id = lcu_upd_po_line_curr_rec.po_header_id
             AND    PPF.person_id = POH.agent_id;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                gc_error_code := SQLERRM;
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code);
             WHEN OTHERS THEN
                gc_error_code := SQLERRM;
                FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code);
          END;
          IF gc_error_detail IS NULL THEN
             ln_err_var := PO_CHANGE_API1_S.UPDATE_PO(
                        X_PO_NUMBER             =>       lcu_upd_po_line_curr_rec.po_number
                        ,X_RELEASE_NUMBER        =>      NULL
                        ,X_REVISION_NUMBER       =>      ln_rev_num
                        ,X_LINE_NUMBER           =>      lcu_upd_po_line_curr_rec.line_num
                        ,X_SHIPMENT_NUMBER       =>      lcu_upd_po_ship_curr_rec.shipment_num
                        ,NEW_QUANTITY            =>      lcu_upd_po_line_curr_rec.quantity
                        ,NEW_PRICE               =>      lcu_upd_po_line_curr_rec.price
                        ,NEW_PROMISED_DATE       =>      lcu_upd_po_line_curr_rec.promised_date
                        ,LAUNCH_APPROVALS_FLAG   =>      'N'
                        ,UPDATE_SOURCE           =>      NULL
                        ,VERSION                 =>      '1.0'
                        ,X_OVERRIDE_DATE         =>      NULL
                        ,X_API_ERRORS            =>      l_api_errors
                        ,p_BUYER_NAME            =>      lc_buyer_name
                        );
                    IF (ln_err_var <>0) THEN
                      gc_error_code := SQLERRM;
                      UPDATE xx_po_mass_upd_po_status_all
                      SET    process_status = 'UPD-NEW'
                      WHERE  mass_update_id=lcu_upd_po_line_curr_rec.mass_update_id;
                      FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_code);
                    ELSIF (ln_err_var = 0) THEN
                      FOR i IN 1..l_api_errors.message_text.COUNT LOOP
                      gc_error_detail := gc_error_detail || l_api_errors.message_text(i);
                      END LOOP;
                      UPDATE xx_po_mass_upd_po_status_all
                      SET    process_status='ERROR'
                            ,error_description = gc_error_detail
                      WHERE  mass_update_id=lcu_upd_po_line_curr_rec.mass_update_id;
                      FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail);
                    END IF;
          ELSIF gc_error_detail IS NOT NULL THEN
             UPDATE xx_po_mass_upd_po_status_all
             SET    process_status='ERROR'
                   ,error_description = gc_error_detail||','||gc_error_code
             WHERE  mass_update_id=lcu_upd_po_line_curr_rec.mass_update_id;
          FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_detail||' '||gc_error_code);
          END IF;
      gc_error_code := NULL;
      gc_error_detail := NULL;
      END LOOP;
END LOOP;
COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    gc_error_code:=SQLERRM;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Procedure: Update_PO_line when others  '||gc_error_code);
END UPDATE_PO_LINE;
                                                                      
 -- + ==============================================================+
 -- | Name        : XX_PO_MASSUPD_REPORT                            |
 -- | Description : This procedure reports the number of POs which  |
 -- |               got updated in MASS.                            |
 -- | Parameters  : p_batch_id                                      |
 -- |                                                               |
 -- | Returns     :                                                 |
 -- |                                                               |
 -- + ==============================================================+
PROCEDURE XX_PO_MASSUPD_REPORT(
                              p_batch_id IN NUMBER
                              )
 IS
    CURSOR lcu_details_curr IS
     SELECT po_number
            ,po_header_id
            ,po_header_status
            ,revision_no
            ,po_type
            ,approval_status
            ,mass_action_detail
            ,item_number
            ,quantity
            ,price
            ,promised_date
            ,'Buyer'
            ,line_status
            ,process_status
            ,error_description
       FROM xx_po_mass_upd_po_status_all
       WHERE batch_id = p_batch_id;
                                                             
    ld_date                    DATE;
    ln_lines_processed         NUMBER;
    ln_orders_processed        NUMBER;
    ln_orders_approved         NUMBER;
    ln_orders_disapproved      NUMBER;
    lc_buyer                   VARCHAR2(100);
                                                              
 BEGIN
    BEGIN
       SELECT TO_CHAR(SYSDATE,'DD-MON-YY')
       INTO   ld_date
       FROM   dual;
    END;
    BEGIN
       SELECT COUNT(1)
       INTO   ln_lines_processed
       FROM   xx_po_mass_upd_po_status_all
       WHERE  batch_id = p_batch_id;
    END;
    BEGIN
       SELECT COUNT(DISTINCT po_header_id)
       INTO   ln_orders_processed
       FROM   xx_po_mass_upd_po_status_all
       WHERE  batch_id = p_batch_id
       AND    process_status = 'PROCESSED';
    END;
    BEGIN
       SELECT COUNT(1)
       INTO   ln_orders_approved
       FROM   xx_po_mass_upd_po_status_all
       WHERE  batch_id = p_batch_id
       AND    approval_status = 'APPROVED';
    END;
    BEGIN
       SELECT COUNT(1)
       INTO   ln_orders_disapproved
       FROM   xx_po_mass_upd_po_status_all
       WHERE  batch_id = p_batch_id
       AND    approval_status = 'ERROR';
    END;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Office Depot, Inc.'||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)
                     ||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)
                     ||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||'Date:'||ld_date);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)
                     ||CHR(9)||CHR(9)||CHR(9)||'Mass Purchase Order Update Summary');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)
                     ||CHR(9)||CHR(9)||'Batch ID:'||p_batch_id);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||RPAD('PO Number',16,' ')
                                   ||RPAD('Header Closure Status',23,' ')
                                   ||RPAD('Rev',8,' ')
                                   ||RPAD('PO Type',10,' ')
                                   ||RPAD('Approval Status',18,' ')
                                   ||RPAD('Action',15,' ')
                                   ||RPAD('Item',15,' ')
                                   ||RPAD('Quantity',10,' ')
                                   ||RPAD('Price',10,' ')
                                   ||RPAD('Promised Date',23,' ')
                                   ||RPAD('Buyer',17,' ')
                                   ||RPAD('Line Closure Status',20,' ')
                                   ||RPAD('Update Status',14,' ')
                                   ||RPAD('Error Message',50,' ')
                     );
                                                                                         
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('---------',16,' ')
                                         ||RPAD('----------------------',23,' ')
                                         ||RPAD('----',8,' ')||RPAD('-------',10,' ')
                                         ||RPAD('---------------',18,' ')
                                         ||RPAD('-------------',15,' ')
                                         ||RPAD('-----------',15,' ')
                                         ||RPAD('--------',10,' ')
                                         ||RPAD('-----',10,' ')
                                         ||RPAD('-------------',23,' ')
                                         ||RPAD('-------------',17,' ')
                                         ||RPAD('-------------------',20,' ')
                                         ||RPAD('-------------',14,' ')
                                         ||RPAD('-------------',50,' ')
                                         );
                                                                                         
    FOR lcu_details_curr_rec IN lcu_details_curr
    LOOP
                                                                                         
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                                                                                         
       SELECT DISTINCT PPF.first_name||' '||PPF.last_name
       INTO   lc_buyer
       FROM   xx_po_mass_upd_po_status_all XXPU
             ,po_headers_v POH
             ,per_people_f PPF
       WHERE XXPU.po_header_id = POH.po_header_id
       AND   POH.agent_id      = PPF.person_id
       AND   POH.po_header_id  = lcu_details_curr_rec.po_header_id;
                                                                                         
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(NVL(lcu_details_curr_rec.po_number,' '),16,' ')
                          ||RPAD(NVL(lcu_details_curr_rec.po_header_status,' '),23,' ')
                          ||RPAD(NVL(lcu_details_curr_rec.revision_no,' '),8,' ')
                          ||RPAD(NVL(lcu_details_curr_rec.po_type,' '),10,' ')
                          ||RPAD(NVL(lcu_details_curr_rec.approval_status,' '),18,' ')
                          ||RPAD(NVL(lcu_details_curr_rec.mass_action_detail,' '),15,' ')
                          ||RPAD(NVL(lcu_details_curr_rec.item_number,' '),15, ' ')
                          ||RPAD(NVL(RPAD(lcu_details_curr_rec.quantity,10,' '),' '),10,' ')
                          ||NVL(RPAD(lcu_details_curr_rec.price,10,' '),' ')
                          ||RPAD(RTRIM(NVL(TO_CHAR(lcu_details_curr_rec.promised_date,'DD-MON-YYYY'),' ')),23,' ')
                          ||RPAD(NVL(lc_Buyer,' '),21,' ')
                          ||RPAD(NVL(lcu_details_curr_rec.line_status,' '),16,' ')
                          ||RPAD(NVL(lcu_details_curr_rec.process_status,' '),14,' ')
                          ||lcu_details_curr_rec.error_description
                         );
    END LOOP;

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||'No of lines processed                  :'||ln_lines_processed);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||'No of purchase Orders Processed        :'||ln_orders_processed);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||'No of Purchase Orders Approved         :'||ln_orders_approved);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||'No of Purchase Orders Not Approved     :'||ln_orders_disapproved);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)||CHR(9)
                     ||CHR(9)||CHR(9)||CHR(9)||CHR(9)||'**** End of Report****');

 END XX_PO_MASSUPD_REPORT;

END XX_PO_MASSUPD_PKG;
/
SHOW ERROR