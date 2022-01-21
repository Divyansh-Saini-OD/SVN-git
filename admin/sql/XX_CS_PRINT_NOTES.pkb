create or replace
PACKAGE BODY "XX_CS_PRINT_NOTES" AS
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name    : XX_CS_PRINT_NOTES                                                             |
-- |                                                                                         |
-- | Description      : Filter Log notes and Sales Rep SRs list                              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |1.0       04-28-08        Raj Jagarlamudi        Initial draft version                   |
-- |1.1       08-29-08        Raj Jagarlamudi        Sales Rep SRs List added                | 
-- |1.2       10-29-08        Raj Jagarlamudi        Order Details added to Request          |
-- |1.3       11-12-08        Raj Jagarlamudi        Note Type 'Discard' validation added    |
-- |1.4       05-08-09        Raj Jagarlamudi        Contact details problem fixed           |
-- +=========================================================================================+

PROCEDURE PRINT_SR_DETAILS (P_INCIDENT_ID  IN NUMBER) AS

ln_sr_number    number;
lc_status       varchar2(50);
lc_summary      varchar2(1000);
lc_cust_name    varchar2(250);
lc_cont_name    varchar2(250);
lc_cust_phone   varchar2(50);
lc_cust_email   varchar2(250);
lc_status_flag  varchar2(1) := 'S';
lc_msg          varchar2(2000); 
lt_notes_tbl    XX_CS_SR_NOTES_TBL;
ln_party_id     number;
lc_con_context  varchar2(250);
lc_con_name     varchar2(250);
lc_con_add1     varchar2(250);
lc_con_add2     varchar2(250);
lc_con_city     varchar2(100);
lc_con_state    varchar2(100);
lc_con_code     varchar2(100);
lc_con_phone    varchar2(100);
lc_con_method   varchar2(100);
lc_con_email     varchar2(100);
lc_order_num     varchar2(100);
lc_offer_num     varchar2(100);
lc_contract_num  varchar2(100);
lc_serial_num    varchar2(100);
lc_int_context   varchar2(50);
ln_con_point_id  number;
ln_rel_con_point_id   number;
 

BEGIN
    begin
      select incident_number, 
             status_code, 
             summary ,
             company_name, 
             contact_name, 
             area_code||phone_number, 
             email,
             incident_context,
             incident_attribute_1,
             incident_attribute_12,
             incident_attribute_5,
             incident_attribute_7
      into   ln_sr_number,
             lc_status,
             lc_summary,
             lc_cust_name,
             lc_cont_name,
             lc_cust_phone,
             lc_cust_email,
             lc_int_context,
             lc_order_num,
             lc_offer_num,
             lc_contract_num,
             lc_serial_num
      from cs_incidents_v
      where incident_id = p_incident_id;
    exception
      when others then
        lc_status_flag  := 'F';
        lc_msg          := 'Error while selecting SR Details,  '||sqlerrm;
    end;    

    -- Select external information for ECR team
    IF lc_status_flag = 'S' then
      -- Select contact point id and party id
            begin
               SELECT CSH.CONTACT_POINT_ID,
                      CSH.PARTY_ID,
                      'Contact Details'
               INTO LN_CON_POINT_ID,
                    LN_PARTY_ID,
                    LC_CON_CONTEXT
               FROM CS_HZ_SR_CONTACT_POINTS CSH
               WHERE INCIDENT_ID = P_INCIDENT_ID
               AND  CSH.CONTACT_TYPE = 'PARTY_RELATIONSHIP';
            exception
               when others then 
                    LN_CON_POINT_ID := NULL;
              end;
               IF LN_PARTY_ID IS NOT NULL THEN
                 -- Select party site address
                  BEGIN 
                    SELECT HZL.ADDRESS1,
                           HZL.ADDRESS2,
                           HZL.CITY,
                           HZL.POSTAL_CODE,
                           HZL.STATE
                      INTO  LC_CON_ADD1,
                            LC_CON_ADD2,
                            LC_CON_CITY,
                            LC_CON_CODE,
                            LC_CON_STATE
                      FROM HZ_PARTY_SITES HZP,
                           HZ_LOCATIONS HZL
                      WHERE HZL.LOCATION_ID = HZP.LOCATION_ID 
                      AND  HZP.PARTY_ID = LN_PARTY_ID
                      AND  HZP.STATUS = 'A';
                   EXCEPTION
                      WHEN OTHERS THEN
                           LC_CON_ADD1    := NULL;
                   END;
                 IF LC_CON_ADD1 IS NULL THEN
                       -- Select relationship address
                         BEGIN
                              select hzp.address1, 
                                   hzp.address2, 
                                   hzp.city,
                                   hzp.postal_code,
                                   hzp.state,
                                   hzo.org_contact_id 
                              into lc_con_add1,
                                   lc_con_add2,
                                   lc_con_city,
                                   lc_con_code,
                                   lc_con_state,
                                   ln_rel_con_point_id
                             from hz_party_relationships hzr,
                                  hz_parties hzp,
                                  hz_org_contacts hzo
                            where hzo.party_relationship_id = hzr.party_relationship_id
                            and   hzp.party_id = hzr.object_id
                            and   hzr.party_id = ln_party_id;
                           EXCEPTION
                          WHEN OTHERS THEN
                               LC_CON_ADD1    := 'No Contact Points created for this customer ';
                          END;
                   END IF;
                END IF;  
              IF LN_CON_POINT_ID IS NOT NULL THEN 
                LN_CON_POINT_ID := ln_rel_con_point_id;
              END IF;
              -- Select contact details
              IF LN_CON_POINT_ID IS NULL THEN 
                   BEGIN
                    SELECT  HZC.CONTACT_POINT_TYPE CONTACT_METHOD,
                            HZC.PHONE_COUNTRY_CODE||HZC.PHONE_AREA_CODE||HZC.PHONE_NUMBER PHONE,
                            HZC.EMAIL_ADDRESS
                      INTO  LC_CON_METHOD,
                            LC_CON_PHONE,
                            LC_CON_EMAIL
                      FROM  HZ_CONTACT_POINTS HZC
                      WHERE HZC.CONTACT_POINT_ID = LN_CON_POINT_ID
                      AND   HZC.STATUS = 'A'
                      AND   ROWNUM < 2;
                    EXCEPTION 
                      WHEN OTHERS THEN
                        LC_CON_METHOD := null;
                    END;
              END IF;
      END IF;
    IF lc_status_flag = 'S' then
      -- get note details 
      get_log_details(p_incident_id, lt_notes_tbl, lc_status_flag, lc_msg);         
    end if;
    
    -- Print note details
    IF lc_status_flag = 'S' then
      htp.htmlOpen; 
      htp.print; htp.print;
      htp.headOpen;
      htp.Title('Service Request Details');
      htp.headClose;
      htp.bodyOpen;   
      --htp.centerOpen;
      htp.nl;
      htp.fontOpen(ccolor=>'"red", csize="+1"');
      htp.print('<FONT FACE="Times New Roman" SIZE="+2" COLOR="blue">');
      htp.print('<U>');
      htp.print('Service Request Quick View');
      htp.print('</U>');
      htp.print ('</FONT>');
      htp.nl;htp.nl;htp.nl;
      htp.print('<FONT FACE="Times New Roman" SIZE="+1" COLOR="blue">');
      htp.print('<U>');
      htp.print('Customer Details');
      htp.print('</U>');
      htp.print ('</FONT>');
      htp.nl;
      htp.print(' Name               : '||lc_cust_name);
      htp.nl;
      htp.print(' Contact Name       : '||lc_cont_name);
      htp.nl;
      htp.print(' Phone              : '||lc_cust_phone);
      htp.nl;
      htp.print(' Email              : '||lc_cust_email);
      IF lc_con_context IS NOT NULL THEN
        htp.nl;htp.nl;htp.nl;
        htp.print('<FONT FACE="Times New Roman" SIZE="+1" COLOR="blue">');
        htp.print('<U>');
        htp.print('Contact Details');
        htp.print('</U>');
        htp.print ('</FONT>');
        htp.nl;
        htp.print(' Address            : '||lc_con_add1||' '||lc_con_add2);
        htp.nl;
        htp.print(' City and State     : '||lc_con_city||' '||lc_con_State);
        htp.nl;
        htp.print(' Zip Code           : '||lc_con_code);
        htp.nl;
        IF LN_CON_POINT_ID IS NOT NULL THEN
          htp.print(' Phone              : '||lc_con_phone);
          htp.nl;
          htp.print(' Email              : '||lc_con_email);
          htp.nl;
          htp.print(' Contact Method     : '||lc_con_method);
        END IF;
      END IF;
      IF lc_int_context = 'ECR Addl.' then  -- (1) 
       If lc_order_num is not null OR lc_offer_num is not null 
          OR lc_contract_num is not null OR lc_serial_num is not null then  -- (2)
        htp.nl;htp.nl;htp.nl;
        htp.print('<FONT FACE="Times New Roman" SIZE="+1" COLOR="blue">');
        htp.print('<U>');
        htp.print('Offer Details');
        htp.print('</U>');
        htp.print ('</FONT>');
        htp.nl;
        if lc_order_num is not null then
          htp.print(' Order Num          : '||lc_order_num);
          htp.nl;
        end if;
        if lc_offer_num is not null then
          htp.print(' Offer Num          : '||lc_offer_num);
          htp.nl;
        end if;
        if lc_contract_num is not null then
          htp.print(' Contract Num       : '||lc_contract_num);
          htp.nl;
        end if;
        if lc_serial_num is not null then
          htp.print(' Serial Num         : '||lc_serial_num);
          htp.nl;
        end if;
        
       end if; -- (2)
      end if;  -- (1)
      
      htp.nl;htp.nl;htp.nl;
      htp.print('<FONT FACE="Times New Roman" SIZE="+1" COLOR="blue">');
      htp.print('<U>');
      htp.print('Service Request Details');
      htp.print('</U>');
      htp.print ('</FONT>');
      htp.nl;
      htp.print(' Number            : '||ln_sr_number); 
      htp.nl;
      htp.print(' Status            : '||lc_status);
      htp.nl;
      htp.print(' Summary           : '||lc_summary);
      htp.nl;htp.nl;htp.nl;
      htp.print('<FONT FACE="Times New Roman" SIZE="+1" COLOR="blue">');
      htp.print('<U>');
      htp.print('Comments :');
      htp.print('</U>');
      htp.print ('</FONT>');
      htp.tableOpen(cattributes => 'BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="90%"'); 
      for i in 1..lt_notes_tbl.count loop
       htp.print('<TR><TD>');
       htp.tableRowOpen; 
       htp.tableData(cvalue => lt_notes_tbl(i).creation_date||' :  '||htf.bold(lt_notes_tbl(i).notes)||'  : '||lt_notes_tbl(i).note_details, calign=>'left'); 
       htp.print ('</TD></TR>');
       htp.tableRowClose; 
      end loop; 
      htp.tableClose; 
      htp.bodyClose; 
      htp.htmlClose; 

    else
        htp.p('<html>');
        htp.p('<body><hr>');
        htp.p('SR Details');
        htp.p('</form></body></hr></html>');
    end IF;
END PRINT_SR_DETAILS;

/******************************************************************************
*******************************************************************************/

PROCEDURE PRINT_SALES_REP(P_RES_ID IN NUMBER)
IS

l_user_id       number;
l_user_name     varchar2(200);
l_session_id    number;

CURSOR SR_DET IS
select alb.incident_id,
       alb.incident_number,
       alb.creation_date,
       tlc.summary,
       nvl(alb.incident_attribute_9,'-') AOPS_NO,
       tlb.name,
       st.name status
from cs_incidents_all_b alb,
     cs_incident_types_tl tlb,
     cs_incidents_all_tl tlc,
     cs_incident_statuses st,
     fnd_user f
where st.incident_status_id = alb.incident_status_id
and   tlc.incident_id = alb.incident_id
and   alb.incident_type_id = tlb.incident_type_id
and   f.user_id = alb.created_by
and   alb.created_by = l_user_id
--and   st.name <> 'Closed'
and   st.incident_subtype = 'INC'
order by alb.incident_id desc;

sr_rec          sr_det%rowtype;
v_Columns       NUMBER(2); 
ln_request_id   number;
lc_status_flag  varchar2(1) := 'S';
lc_msg          varchar2(2000); 
lt_notes_tbl    XX_CS_SR_NOTES_TBL;


BEGIN
      htp.htmlOpen; 
      htp.print; htp.print;
      htp.headOpen;
      htp.Title('My Service Requests');
      htp.headClose;
      htp.bodyOpen;   
      htp.centerOpen;
      htp.nl;
    begin
      v_Columns := 5;
      
     begin
      select user_id 
      into l_user_id
      from jtf_rs_resource_extns 
      where resource_id = p_res_id;
     exception
       when others then
         htp.print('This user not exists in Resource Manager ');
         htp.nl;
     end;
      
      open sr_det;
        htp.print('<FONT FACE="Times New Roman" SIZE="+2" COLOR="blue">');
        htp.print('<U>');
        htp.print('My Service Requests ');
        htp.print('</U>');
        htp.print ('</FONT>');  
        htp.tableOpen(cattributes => 'BORDER="1" CELLPADDING="0" CELLSPACING="0" WIDTH="90%"'); 
        htp.TableRowOpen;     
        htp.TableRowClose;
        htp.TableRowOpen;     
        htp.tableheader('<U>SR Number</U>',calign=>'center');     
        htp.tableheader('<U>Date</U>',calign=>'center');     
        htp.tableheader('<U>Status</U>',calign=>'center');     
        htp.tableheader('<U>Summary</U>',calign=>'center'); 
        htp.tableheader('<U>Customer No</U>',calign=>'center'); 
        htp.TableRowClose;
      loop
      fetch sr_det into sr_rec;
      exit when sr_det%NOTFOUND; 
      
        htp.print('<TR><TD>');
        htp.tableRowOpen; 
        htp.tableData(cvalue => sr_rec.incident_number, calign=>'left'); 
        htp.tableData(cvalue => sr_rec.creation_date, calign=>'left'); 
        htp.tableData(cvalue => sr_rec.status, calign=>'left'); 
        htp.tableData(cvalue => sr_rec.summary, calign=>'left'); 
        /*
         -- get note details 
            get_log_details(sr_rec.incident_id, lt_notes_tbl, lc_status_flag, lc_msg);
            IF lc_status_flag = 'S' then
             for i in 1..lt_notes_tbl.count loop
                htp.tableRowOpen;
                htp.tableData(cvalue =>lt_notes_tbl(i).note_details, calign=>'left'); 
                htp.tableRowClose;
             end loop; 
            end if;
        */
        htp.tableData(cvalue => sr_rec.aops_no, calign=>'left'); 
        htp.print ('</TD></TR>');
        htp.tableRowClose; 
      
      end loop;
        htp.tableClose; 
        htp.bodyClose; 
        htp.htmlClose;
      close sr_det;
     exception
      when others then
          htp.print('No SRs created by this user ');
          htp.nl;
    end;
END PRINT_SALES_REP;

/******************************************************************************
******************************************************************************/

PROCEDURE GET_LOG_DETAILS (P_INCIDENT_ID  IN NUMBER,
                           P_SR_NOTES_TBL IN OUT NOCOPY XX_CS_SR_NOTES_TBL,
                           X_STATUS_FLAG  IN OUT NOCOPY VARCHAR2,
                           X_MSG          IN OUT NOCOPY VARCHAR2)
is 
    l_user_id Number  := Fnd_global.user_id;
    I         NUMBER   := 0;
    
     cursor note_cursor is 
      select jtf.creation_date,
             jtf.note_type_meaning meaning,
             jtf.notes notes 
            from jtf_notes_vl jtf
            where source_object_code='SR'
            and source_object_id= p_incident_id
            and jtf.note_status <> 'P'
            and jtf.note_type_meaning not like 'Discard'
      order by jtf.creation_date desc;    

  begin

/* This function executes each of the SQL and stores the data in 
   the Main array and Other Array	*/
      I                        := 1;
      P_SR_NOTES_TBL           := XX_CS_SR_NOTES_TBL();
     for i_ctn in note_cursor
     loop
        p_sr_notes_tbl.extend;
        p_sr_notes_tbl(i) := xx_cs_sr_notes_rec(null,null,null,null);
       
       BEGIN
         p_sr_notes_tbl(i).notes          := i_ctn.meaning;
         p_sr_notes_tbl(i).note_details   := i_ctn.notes;
         p_sr_notes_tbl(i).created_by     := NULL;
         p_sr_notes_tbl(i).creation_date  := i_ctn.creation_date;

         I := I + 1;
       END;
     end loop;		-- end of note_cursor loop
  exception
    when others then
      x_status_flag := 'F';
      x_msg         := 'Error while selecting note details, '||sqlerrm;
  
  end get_log_details;

END;
/
show errors;
exit;