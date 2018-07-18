create or replace
PACKAGE BODY XX_CS_TDS_UTIL_PKG
AS
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name  :  XX_CS_TDS_UTIL_PKG                                       |
  -- |                                                                   |
  -- | Description: Wrapper package for Warranty and Confirmation mail   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author           Remarks                     |
  -- |=======   ==========  =============    ============================|
  -- |1.0       24-OCT-10   Raj Jagarlamudi  Initial draft version       |
  -- |1.0       07-MAR-12   Raj              Release excess hold         |
  -- |3.0       22-Jan-16   Vasu Raparla     Removed schema References   |
  -- |                                       for R.12.2                  |
  -- +===================================================================+
  /*****************************************************************************
  -- Log Messages
  ****************************************************************************/
PROCEDURE Log_Exception(
    p_error_location     IN VARCHAR2 ,
    p_error_message_code IN VARCHAR2 ,
    p_error_msg          IN VARCHAR2 )
IS
  ln_login PLS_INTEGER   := FND_GLOBAL.Login_Id;
  ln_user_id PLS_INTEGER := FND_GLOBAL.User_Id;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error ( p_return_code => FND_API.G_RET_STS_ERROR ,
                                  p_msg_count => 1 ,
                                  p_application_name => 'XX_CRM' ,
                                  p_program_type => 'Custom Messages' ,
                                  p_program_name => 'XX_CS_TDS_UTIL_PKG' ,
                                  p_program_id => NULL ,
                                  p_module_name => 'CSF' ,
                                  p_error_location => p_error_location ,
                                  p_error_message_code => p_error_message_code ,
                                  p_error_message => p_error_msg ,
                                  p_error_message_severity => 'MAJOR' ,
                                  p_error_status => 'ACTIVE' ,
                                  p_created_by => ln_user_id ,
                                  p_last_updated_by => ln_user_id ,
                                  p_last_update_login => ln_login );
END Log_Exception;
/************************************************************************************************/
-- Update Receipts
/************************************************************************************************/
PROCEDURE UPDATE_RECEIPTS
AS
cursor c1 is
select xa.request_number
from xx_cs_tds_parts xa,
      po_headers_all ph,
     po_lines_all pl,
     po_line_locations_all pll
where xa.request_number = ph.segment1
and  pl.po_header_id = ph.po_header_id
AND NVL (pll.closed_code, 'OPEN') NOT IN
                                ('FINALLY CLOSED', 'CLOSED FOR RECEIVING')
AND pll.shipment_type IN ('STANDARD', 'BLANKET', 'SCHEDULED')
AND pl.po_line_id = pll.po_line_id
and pll.quantity_received = 0
and xa.received_shipment_flag = 'Y'
and xa.received_quantity > 0;

c1_rec        c1%rowtype;
l_resource_id  number;
lc_message    varchar2(250);
ln_msg_count  number;
lc_status     varchar2(25);

BEGIN
     begin
       open c1;
       loop
       fetch c1 into c1_rec;
       exit when c1%notfound;
       
        begin
               select jtt.resource_id
                into   l_resource_id
                from   jtf_rs_resource_extns jtt,
                       jtf_rs_group_members jtm
                where jtm.resource_id = jtt.resource_id
                and   jtt.category = 'PARTY'
                 and   jtm.delete_flag = 'N'
                and   exists (select 'x' from csp_inv_loc_assignments
                              where resource_id = jtt.resource_id )
                and   jtm.group_id = (SELECT owner_group_id
                                    FROM cs_incidents_all_b
                                    WHERE incident_number = c1_rec.request_number );
                                    
            exception
             when others then
                lc_message := 'Error while selecting resource_id '||c1_rec.request_number ;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.UPDATE_RECEIPTS'
                                 ,p_error_message_code =>   'XX_CS_0002d_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                );
                fnd_file.put_line (fnd_file.log, lc_message );
            end;
       
         begin
            xx_cs_tds_parts_receipts.receive_shipments (
                              p_api_version_number => 1.0,
                              p_init_msg_list      => fnd_api.g_false,
                              p_commit             => fnd_api.g_false,
                              p_validation_level   => null,
                              p_document_number    => c1_rec.request_number,
                              p_resource_id        => l_resource_id,
                              x_return_status      => lc_status,
                              x_msg_count          => ln_msg_count,
                              x_msg_data           => lc_message );
          exception
             when others then
                lc_message := 'Error while calling receive shipments '||c1_rec.request_number ||' '||lc_message;
                 Log_Exception ( p_error_location     =>  'XX_CS_CUSTOM_EVENT.UPDATE_RECEIPTS'
                                 ,p_error_message_code =>   'XX_CS_0002c_ERR_LOG'
                                 ,p_error_msg          =>  lc_message
                                );
                  fnd_file.put_line (fnd_file.log, lc_message );
          end;
            lc_message := c1_rec.request_number || 'Processed '|| lc_status;
            fnd_file.put_line (fnd_file.log, lc_message );
        end loop;
        close c1;
      end;

END;
/****************************************************************************/
PROCEDURE WARRANTY_UPDATE(
    x_errbuf OUT NOCOPY  VARCHAR2 ,
    x_retcode OUT NOCOPY NUMBER )
AS
  ln_sdc_war_period NUMBER;
  CURSOR SDC_CUR
  IS
    SELECT TASK_ID,
      SOURCE_OBJECT_ID
    FROM JTF_TASKS_B
    WHERE SOURCE_OBJECT_TYPE_CODE = 'SR'
    AND LAST_UPDATE_DATE  < SYSDATE - LN_SDC_WAR_PERIOD
    AND TASK_STATUS_ID IN (11,8,4,7)
    AND ATTRIBUTE1 = 'Support.com'
    AND EXISTS
      (SELECT CB.INCIDENT_ID
      FROM  CS_INCIDENTS_ALL_B CB,
            CS_INCIDENT_TYPES_VL CT,
            CS_INCIDENT_STATUSES_TL CL
      WHERE CL.INCIDENT_STATUS_ID = CB.INCIDENT_STATUS_ID
      AND CT.INCIDENT_TYPE_ID     = CB.INCIDENT_TYPE_ID
      AND CT.INCIDENT_SUBTYPE     = 'INC'
      AND CT.END_DATE_ACTIVE     IS NULL
      AND CT.NAME LIKE 'TDS%'
      AND CL.NAME NOT IN ('Awaiting Service', 'Work In Progress')
      AND CL.SOURCE_LANG  = 'US'
      AND CB.EXTERNAL_ATTRIBUTE_14 IS NOT NULL
      AND CB.INCIDENT_ID  = JTF_TASKS_B.SOURCE_OBJECT_ID
      );
  SDC_REC SDC_CUR%ROWTYPE;
  lc_message       VARCHAR2(2000);
  lc_return_msg    VARCHAR2(2000);
  ln_msg_count     NUMBER;
  ln_return_code   NUMBER;
  lc_return_status VARCHAR2(25);
  
  CURSOR DM_REL_CUR 
  IS 
  select  distinct xa.request_number
  from ap_invoices_all apn,
       ap_invoice_distributions_all apd,
       po_distributions_all pod,
       po_headers_all poa,
       xx_cs_tds_parts xa
  where xa.request_number = poa.segment1
  and   poa.po_header_id = pod.po_header_id
  and   pod.po_distribution_id = apd.po_distribution_id
  and   apd.invoice_id = apn.invoice_id  
  and   apn.invoice_type_lookup_code = 'STANDARD'
  and   xa.attribute2 in ('P','E');
  DM_REL_REC  DM_REL_CUR%ROWTYPE;
  
  CURSOR DM_CUR
  IS
    SELECT DISTINCT xc.request_number,
      poa.segment1
    FROM ap_invoices_all apn,
      ap_invoice_distributions_all apd,
      po_distributions_all pod,
      po_headers_all poa,
      po_lines_all pll,
      xx_cs_tds_parts xc
    WHERE xc.inventory_item_id       = pll.item_id
    AND xc.request_number            = poa.segment1
    AND poa.po_header_id             = pod.po_header_id
    AND pod.po_distribution_id       = apd.po_distribution_id
    AND apd.invoice_id               = apn.invoice_id
    AND NVL(xc.excess_flag,'N')     IN ( 'R','Y')
    AND NVL(xc.attribute2,'N')       = 'N'
    AND NVL(xc.attribute4,'N')      <> 'Y'
    AND apn.invoice_type_lookup_code = 'DEBIT';
  DM_REC DM_CUR%ROWTYPE;
  CURSOR OVER_CUR
  IS
    SELECT DISTINCT xc.request_number
    FROM xx_cs_tds_parts xc
    WHERE NVL(xc.excess_flag,'N') IN ( 'R','Y')
    AND NVL(xc.attribute2,'N')     = 'N'
    AND NVL(xc.attribute4,'N')     = 'Y';
  OVER_REC OVER_CUR%ROWTYPE;
  ln_incident_id NUMBER;
BEGIN
  BEGIN
    SELECT FND_PROFILE.VALUE('XX_TDS_SDC_WAR_PERIOD')
    INTO LN_SDC_WAR_PERIOD
    FROM DUAL;
  EXCEPTION
  WHEN OTHERS THEN
    LN_SDC_WAR_PERIOD := 11;
  END;
  -- SDC UPDATES
  BEGIN
    OPEN SDC_CUR;
    LOOP
      FETCH SDC_CUR INTO SDC_REC;
      EXIT
    WHEN SDC_CUR%NOTFOUND;
      BEGIN
        UPDATE CS_INCIDENTS_ALL_B
        SET EXTERNAL_ATTRIBUTE_14 = NULL
        WHERE INCIDENT_ID         = SDC_REC.SOURCE_OBJECT_ID;
        COMMIT;
        lc_message := SDC_REC.SOURCE_OBJECT_ID||' REQUEST Updated';
        fnd_file.put_line(fnd_file.log, lc_message);
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        lc_message := SDC_REC.SOURCE_OBJECT_ID||' REQUEST failed. '||sqlerrm;
        fnd_file.put_line(fnd_file.log, lc_message);
      END;
    END LOOP;
    CLOSE SDC_CUR;
    x_retcode := 0;
  EXCEPTION
  WHEN OTHERS THEN
    lc_message := 'error '||sqlerrm;
    fnd_file.put_line(fnd_file.log, lc_message);
    x_retcode := 2;
  END;
  /*****************************************************************
   -- Release hold returns DM 
  ******************************************************************/
  BEGIN
    OPEN DM_REL_CUR;
    LOOP
     FETCH DM_REL_CUR INTO DM_REL_REC;
     EXIT WHEN DM_REL_CUR%NOTFOUND;
     
            XX_CS_TDS_EXCESS_PARTS.EXCESS_RETURNS (
                              p_document_number    => dm_rel_rec.request_number,
                              p_validation_level   => null,
                              p_resource_id        => null,
                              x_return_status      => lc_return_status,
                              x_msg_count          => ln_msg_count,
                              x_msg_data           => lc_message );
                              
              lc_message := 'Release excess parts '||dm_rel_rec.request_number||' : Status: '||lc_return_status;
              fnd_file.put_line(fnd_file.log, lc_message);
                              
                
                begin
                   UPDATE xx_cs_tds_parts
                     SET attribute2 = 'N'
                   WHERE request_number = dm_rel_rec.request_number;
                  
                    commit;
                exception
                  when others then
                     lc_message := 'update failed '||dm_rel_rec.request_number||' : Status: '||sqlerrm;
                     fnd_file.put_line(fnd_file.log, lc_message);     
                end;
         
     END LOOP;
     CLOSE DM_REL_CUR;
  END;
  /*****************************************************************/
  -- DM Processes
  /******************************************************************/
  BEGIN
    OPEN DM_CUR;
    LOOP
      FETCH DM_CUR INTO DM_REC;
      EXIT
    WHEN DM_CUR%NOTFOUND;
      XX_CS_TDS_PARTS_VEN_PKG.PART_OUTBOUND (p_incident_number => dm_rec.request_number, 
                                              p_incident_id => ln_incident_id, 
                                              p_doc_type => 'EXCESS', 
                                              p_doc_number => dm_rec.segment1, 
                                              x_return_status => lc_return_status, 
                                              x_return_msg => lc_return_msg);
                                              
      lc_message := 'Debit Memo Proc. for '||dm_rec.request_number||' : Status: '||lc_return_status;
      fnd_file.put_line(fnd_file.log, lc_message);
      
    END LOOP;
    CLOSE DM_CUR;
    x_retcode := 0;
  EXCEPTION
  WHEN OTHERS THEN
    lc_return_msg := 'Error while calling DM Process :' || SQLERRM;
    x_retcode     := 2;
    fnd_file.put_line (fnd_file.log, lc_return_msg );
  END;
  /*****************************************************************************
    -- Over Qty
  *****************************************************************************/
  BEGIN
    OPEN OVER_CUR;
    LOOP
      FETCH OVER_CUR INTO OVER_REC;
      EXIT
    WHEN OVER_CUR%NOTFOUND;
      XX_CS_TDS_PARTS_VEN_PKG.PART_OUTBOUND (p_incident_number => over_rec.request_number, 
                                             p_incident_id => ln_incident_id, 
                                             p_doc_type => 'OVER', 
                                             p_doc_number => over_rec.request_number, 
                                             x_return_status => lc_return_status, 
                                             x_return_msg => lc_return_msg);
      lc_message := 'Over qty Proc. for '||dm_rec.request_number||' : Status: '||lc_return_status;
      fnd_file.put_line(fnd_file.log, lc_message);
    END LOOP;
    CLOSE OVER_CUR;
    x_retcode := 0;
    
    -- Reciepts update 
        UPDATE_RECEIPTS;
        
  EXCEPTION
  WHEN OTHERS THEN
    lc_return_msg := 'Error while calling DM Process :' || SQLERRM;
    x_retcode     := 2;
    fnd_file.put_line (fnd_file.log, lc_return_msg );
  END;
END WARRANTY_UPDATE;

/************************************************************************
-- Service completion mail confirmation
************************************************************************/
PROCEDURE EMAIL_SEND(
    p_incident    IN VARCHAR2,
    p_order_num   IN VARCHAR2,
    p_email       IN VARCHAR2,
    x_status_flag IN OUT nocopy VARCHAR2,
    x_return_msg  IN OUT nocopy VARCHAR2)
AS
  mailhost VARCHAR2 (100) := fnd_profile.value('XX_CS_SMTP_SERVER');
  mail_conn UTL_SMTP.connection;
  p_fun_url VARCHAR2(250) := fnd_profile.value('XX_CS_EMAIL_WORK_ORDER');
BEGIN
  IF p_incident IS NOT NULL THEN
    mail_conn   := UTL_SMTP.open_connection (mailhost);
    UTL_SMTP.helo (mail_conn, mailhost);
    UTL_SMTP.mail (mail_conn, 'noreply@officedepot.support.com');
    UTL_SMTP.rcpt (mail_conn, p_email);
    UTL_SMTP.open_data (mail_conn);
    UTL_SMTP.write_data (mail_conn, 'From:' || 'noreply@officedepot.support.com' || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'To:' || p_email || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'Subject:' || 'Work Order Service Receipt#' || p_incident || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'MIME-version: 1.0' || UTL_TCP.crlf);
    UTL_SMTP.write_data (mail_conn, 'Content-Type: text/html' || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, '<HTML>');
    UTL_SMTP.write_data (mail_conn, '<BODY>');
    UTL_SMTP.write_data (mail_conn, '<BR>');
    UTL_SMTP.write_data (mail_conn, '<table width="100%" >');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data(mail_conn, '<td><P><IMG SRC="http://gsiuatgb.na.odcorp.net/XXCRM_HTML/Worder/logo.gif" WIDTH="210" HEIGHT="42" BORDER="0" ALT=""></P></td>' );
    --UTL_SMTP.write_data (mail_conn, '<td><P><B>1-866-483-9162</B></P></td>');
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '</table>');
    UTL_SMTP.write_data (mail_conn, '<BR>');
    UTL_SMTP.write_data (mail_conn, '<HR>');
    UTL_SMTP.write_data (mail_conn, '<table width="100%" style="border: 1px solid #999;" >');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><FONT FACE="Arial" SIZE="4" color="#CC0000"><B>Work Order Receipt ' || p_incident || ' </FONT></B></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="3">Thank you for shopping at Office Depot.</font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="2">Thank you for choosing Tech Depot Services.</font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="2"><B>We appreciate the chance to provide you with these services on Work Order#'||p_incident || '.</B></font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="2">Your service receipt is available at: <a href="'|| p_fun_url || p_order_num || ' ">Click here </a></font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td>');
    UTL_SMTP.write_data (mail_conn, '<table width="100%" style="border: 1px solid #999;" >');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000"  FONT FACE="Arial" size="2">Thank you again, we look forward to helping you! </font><font color="#CC0000" FONT FACE="Arial" size="2" ><B>Tell us how it went<B></font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR></td>');
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="2">Office Depot values your feedback.Please <a href="#">click here </a>and take a moment to tell us about your Tech Depot Services experience.

</font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr></table>');
    UTL_SMTP.write_data (mail_conn, '</td></tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR><BR></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '</table>');
    UTL_SMTP.write_data (mail_conn, '</FONT></B></P>');
    UTL_SMTP.write_data (mail_conn, '<B><FONT FACE="Arial" SIZE="2" color="#CC0000">' || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, '</FONT></B>');
    UTL_SMTP.write_data (mail_conn, '</HTML>');
    UTL_SMTP.write_data (mail_conn, '</BODY>');
    UTL_SMTP.close_data (mail_conn);
    UTL_SMTP.quit (mail_conn);
  END IF;
EXCEPTION
WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error THEN
  UTL_SMTP.quit (mail_conn);
  -- (-20000, 'Failed to send mail due to the following error: ' || SQLERRM );
  x_return_msg := 'Failed to send mail due to the following error: ' || SQLERRM;
WHEN OTHERS THEN
  --raise_application_error (-20001, 'The following error has occured: ' || SQLERRM );
  x_return_msg := 'The following error has occured: ' || SQLERRM;
END EMAIL_SEND ;
/**************************************************************************************************/
-- Pick up mail
/************************************************************************************************/
PROCEDURE EMAIL_SEND_PICKUP(
    p_incident    IN VARCHAR2,
    p_order_num   IN VARCHAR2,
    p_email       IN VARCHAR2,
    x_status_flag IN OUT nocopy VARCHAR2,
    x_return_msg  IN OUT nocopy VARCHAR2)
AS
  mailhost VARCHAR2 (100) := fnd_profile.value('XX_CS_SMTP_SERVER');
  mail_conn UTL_SMTP.connection;
  p_fun_url        VARCHAR2(250) := fnd_profile.value('XX_CS_EMAIL_WORK_ORDER');
  ln_task_id       NUMBER;
  ln_incident_id   NUMBER;
  lc_message       VARCHAR2(2000);
  lc_success       VARCHAR2(50);
  ln_msg_count     NUMBER;
  lc_msg_data      VARCHAR2(50);
  ln_status_id     NUMBER;
  ln_obj_ver       NUMBER;
  lc_return_status VARCHAR2(25);
BEGIN
  IF p_incident IS NOT NULL THEN
    mail_conn   := UTL_SMTP.open_connection (mailhost);
    UTL_SMTP.helo (mail_conn, mailhost);
    UTL_SMTP.mail (mail_conn, 'noreply@officedepot.support.com');
    UTL_SMTP.rcpt (mail_conn, p_email);
    UTL_SMTP.open_data (mail_conn);
    UTL_SMTP.write_data (mail_conn, 'From:' || 'noreply@officedepot.support.com' || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'To:' || p_email || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'Subject:' || 'Work Order Service Receipt#' || p_incident || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, 'MIME-version: 1.0' || UTL_TCP.crlf);
    UTL_SMTP.write_data (mail_conn, 'Content-Type: text/html' || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, '<HTML>');
    UTL_SMTP.write_data (mail_conn, '<BODY>');
    UTL_SMTP.write_data (mail_conn, '<BR>');
    UTL_SMTP.write_data (mail_conn, '<table width="100%" >');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data(mail_conn, '<td><P><IMG SRC="http://gsiuatgb.na.odcorp.net/XXCRM_HTML/Worder/logo.gif" WIDTH="210" HEIGHT="42" BORDER="0" ALT=""></P></td>' );
    --UTL_SMTP.write_data (mail_conn, '<td><P><B>1-866-483-9162</B></P></td>');
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '</table>');
    UTL_SMTP.write_data (mail_conn, '<BR>');
    UTL_SMTP.write_data (mail_conn, '<HR>');
    UTL_SMTP.write_data (mail_conn, '<table width="100%" style="border: 1px solid #999;" >');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><FONT FACE="Arial" SIZE="4" color="#CC0000"><B>Work Order Receipt ' || p_incident || ' </FONT></B></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="3"><U><B>Your PC is ready for Pickup.</B></U> Thank you for shopping at Office Depot.</font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="2">Thank you for choosing Tech Depot Services.</font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="2"><B>We appreciate the chance to provide you with these services on Work Order#'||p_incident || '.</B></font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="2">Your service receipt is available at: <a href="'|| p_fun_url || p_order_num || ' ">Click here </a></font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td>');
    UTL_SMTP.write_data (mail_conn, '<table width="100%" style="border: 1px solid #999;" >');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000"  FONT FACE="Arial" size="2">Thank you again, we look forward to helping you! </font><font color="#CC0000" FONT FACE="Arial" size="2" ><B>Tell us how it went<B></font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR></td>');
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><font color="#000000" FONT FACE="Arial" size="2">Office Depot values your feedback.Please <a href="#">click here </a>and take a moment to tell us about your Tech Depot Services experience.  

</font></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr></table>');
    UTL_SMTP.write_data (mail_conn, '</td></tr>');
    UTL_SMTP.write_data (mail_conn, '<tr>');
    UTL_SMTP.write_data (mail_conn, '<td><BR><BR></td>' );
    UTL_SMTP.write_data (mail_conn, '</tr>');
    UTL_SMTP.write_data (mail_conn, '</table>');
    UTL_SMTP.write_data (mail_conn, '</FONT></B></P>');
    UTL_SMTP.write_data (mail_conn, '<B><FONT FACE="Arial" SIZE="2" color="#CC0000">' || UTL_TCP.crlf );
    UTL_SMTP.write_data (mail_conn, '</FONT></B>');
    UTL_SMTP.write_data (mail_conn, '</HTML>');
    UTL_SMTP.write_data (mail_conn, '</BODY>');
    UTL_SMTP.close_data (mail_conn);
    UTL_SMTP.quit (mail_conn);
    /*************************************************************************/
    -- Release In Home Services to Nexicore
    /**************************************************************************/
    BEGIN
      SELECT incident_id
      INTO ln_incident_id
      FROM cs_incidents_all_b
      WHERE incident_number = p_incident;
    EXCEPTION
    WHEN OTHERS THEN
      LC_MESSAGE := 'Error while SELECTING incident_id '||sqlerrm;
      Log_Exception ( p_error_location => 'XX_CS_TDS_UTIL_PKG.EMAIL_SEND_PICKUP' ,p_error_message_code => 'XX_CS_SR01_ERR_LOG' ,p_error_msg => LC_MESSAGE);
    END;
    IF ln_incident_id IS NOT NULL THEN
      BEGIN
        SELECT task_id ,
          object_version_number
        INTO ln_task_id,
          ln_obj_ver
        FROM jtf_tasks_b
        WHERE source_object_id  = ln_incident_id
        AND attribute5          = 'H'
        AND task_status_id NOT IN (11,8)
        AND rownum              < 2;
      EXCEPTION
      WHEN no_data_found THEN
        NULL;
      WHEN OTHERS THEN
        LC_MESSAGE := 'Error while SELECTING task_id '||sqlerrm;
        Log_Exception ( p_error_location => 'XX_CS_TDS_UTIL_PKG.EMAIL_SEND_PICKUP' ,p_error_message_code => 'XX_CS_SR02_ERR_LOG' ,p_error_msg => LC_MESSAGE);
      END;
      --- Update Task ---
      IF ln_task_id  IS NOT NULL THEN
        ln_status_id := 14;
        BEGIN
          jtf_tasks_pub.update_task ( p_object_version_number => ln_obj_ver ,p_api_version => 1.0 ,p_init_msg_list => fnd_api.g_true ,p_commit => fnd_api.g_false ,p_task_id => ln_task_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data ,p_task_status_id => ln_status_id ,p_attribute2 => 'Y' );
          COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
          Log_Exception ( p_error_location => 'XX_CS_TDS_UTIL_PKG.EMAIL_SEND_PICKUP' ,p_error_message_code => 'XX_CS_SR03_ERR_LOG' ,p_error_msg => lc_return_status||' '||lc_msg_data);
        END;
      END IF; -- Task Id
    END IF;   -- Incident_id
  END IF;
EXCEPTION
WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error THEN
  UTL_SMTP.quit (mail_conn);
  x_return_msg := 'Failed to send PICKUP mail due to the following error: ' || SQLERRM;
WHEN OTHERS THEN
  --raise_application_error (-20001, 'The following error has occured: ' || SQLERRM );
  x_return_msg := 'The following error has occured: ' || SQLERRM;
END EMAIL_SEND_PICKUP ;
/*****************************************************************************************************/
END XX_CS_TDS_UTIL_PKG;
/
show errors;
exit;