CREATE OR REPLACE PACKAGE body APPS.XX_PO_SHIPSTATUS_PKG AS
/******************************************************************************
   NAME:       XX_PO_SHIPSTATUS_PKG 
   FUNCTION:   XX_PO_SHIPSTATUS_UPDATE 
   PURPOSE:    Take Oagis Canonical input of an EDI 214 record and insert PO Ship Status
               data into Oracle EBS table XX_PO_SHIP_STATUS 
   CALLED BY:  BPEL Ship Status Interfaces solution 
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        6/12/2007   Roc Polimeni     1. Created this package and function
                                              XX_PO_SHIPSTATUS_UPDATE 
******************************************************************************/

               
  /*  Don't take audit fields as input and just populate them in final table when processed */  
  FUNCTION XX_PO_SHIPSTATUS_UPDATE (I_Bill_of_Lading   in VARCHAR2,
                                     I_Document_Nbr     in VARCHAR2,    -- includes Loc_ID 
                                    I_Pro_Bill_Nbr     in VARCHAR2,
                                    I_Reason_CD        in VARCHAR2,
                                    I_SCAC             in VARCHAR2,
                                    I_Status_Code      in VARCHAR2,
                                    I_ShipDateTime     in VARCHAR2)  -- includes Date, Time, and Time Zone 
    RETURN NUMBER is
    
    /*  Date - Time - Time Zone can be either 

        Arrival Date                          if I_Status_Code is X1 
        Estimated Arrival Date                if I_Status_Code is X2 
        Ship Date                             if I_Status_Code is AG 
    */

   L_Loc_ID                          VARCHAR2(6);       -- Loc extracted from PO-Loc concatenated string
   L_PO_Nbr                          VARCHAR2(12);      -- PO Number Extracted from PO-Loc concatenated string
   L_ShipDateString                  VARCHAR2(20);      -- Formed Oracle compatible Date String from XML Input
   L_Ship_Dt                         date;              -- Ship Date 
   L_Est_Arrival_Dt                  date;              -- Est Arrival Date 
   L_Arrival_Dt                      date;              -- Arrival Date 
   L_Operating_Unit                  VARCHAR2(10);      -- ebs var 
   L_PO_Result                       number := 0;       -- count number of po's detected in headers table  
   err_code                          number;
   err_msg                           VARCHAR2 (100);
   RECORD_LOCKED                     EXCEPTION;
   PRAGMA                            EXCEPTION_INIT(Record_Locked, -54);
   L_Return_Code                     number := 0;

     
   BEGIN

     /* Break I_Document_Nbr into a PO and a Loc  */
     L_PO_Nbr         := SUBSTR(I_Document_Nbr, 1, INSTR(I_Document_Nbr, '-') - 1); 
     L_Loc_ID         := SUBSTR(I_Document_Nbr, INSTR(I_Document_Nbr, '-') + 1, LENGTH(I_Document_Nbr));                 

     /* Reform Date-Time String so that it can be inserted into Oracle (remove timezone 
           ex: 20070131-2159-ES becomes  013107 21:59  or mmddyy hh:mm */ 
     L_ShipDateString := SUBSTR (I_ShipDateTime, 5, 4) || SUBSTR (I_ShipDateTime, 3, 2) 
                          || ' ' || SUBSTR (I_ShipDateTime, 10, 2) ||':'|| 
                          SUBSTR (I_ShipDateTime, 12, 2);
   
     DBMS_OUTPUT.PUT_LINE('Debug: Date '     || L_ShipDateString);                                           

     -- Does the PO already exist in EBS? 
     SELECT COUNT (*) INTO L_PO_Result
     FROM po_headers_all
     WHERE segment1 = L_PO_Nbr;
      
     IF (L_PO_Result = 1) THEN  -- if 1 PO exists in EBS (unique)  

        DBMS_OUTPUT.PUT_LINE('Debug: PO Exists once');
      
        SELECT Org_ID INTO L_Operating_Unit
        FROM po_headers_all
        WHERE segment1 = L_PO_Nbr;

        DBMS_OUTPUT.PUT_LINE('Debug: Select operating_unit (Org_ID) ' ||  L_Operating_Unit);                              
   
     ELSIF (L_PO_Result > 1) THEN  -- if more than 1 PO exists in EBS (not unique)  

        DBMS_OUTPUT.PUT_LINE('Debug: PO Exists more than once');

        BEGIN  
            SELECT operating_unit INTO L_Operating_Unit
            FROM org_organization_definitions
            WHERE organization_id = 
               (SELECT inventory_organization_id
                FROM hr_locations_all
                WHERE location_code = L_Loc_ID);

            DBMS_OUTPUT.PUT_LINE('Debug: Select operating_unit ' ||  L_Operating_Unit);                              

        EXCEPTION 
         WHEN TOO_MANY_ROWS THEN 
               err_code := SQLCODE;
               err_msg := substr(SQLERRM, 1, 200);        
               DBMS_OUTPUT.PUT_LINE('Debug: Too many rows on select ' ||TRIM (L_Loc_ID));
               L_Return_Code := err_code;
               return L_Return_Code;

         WHEN NO_DATA_FOUND THEN
               err_code := SQLCODE;
               err_msg := substr(SQLERRM, 1, 200);        
               DBMS_OUTPUT.PUT_LINE('Debug: No Data Found for Loc ' || TRIM (L_Loc_ID));
               L_Return_Code := err_code;
               return L_Return_Code;
  
         WHEN others THEN               
               err_code := SQLCODE;
               err_msg := substr(SQLERRM, 1, 200);    
               DBMS_OUTPUT.PUT_LINE('Debug: Unknown Error on insert ' ||
                TRIM (L_Loc_ID) || ' err code ' || err_code || ' err msg '  || err_msg);
               L_Return_Code := err_code;
               return L_Return_Code;                           
        END;       

     ELSE      -- PO does not exist
        DBMS_OUTPUT.PUT_LINE('Debug: PO does not exist in EBS ' || TRIM (L_PO_Nbr));         
        -- err_code := SQLCODE;
        -- err_msg := substr(SQLERRM, 1, 200);
        -- L_Return_Code := NO_DATA_FOUND;                        
        L_Return_Code := 1403;            
        return L_Return_Code;
     END IF;   

     BEGIN
       
       IF I_Status_Code = 'AG' THEN
          L_Est_Arrival_Dt := '';
          L_Arrival_Dt := '';
          L_Ship_Dt := TO_DATE(L_ShipDateString, 'MMDDYY HH24:MI');                
       END IF;
                
       IF I_Status_Code = 'X2' THEN
          L_Ship_Dt := '';
          L_Arrival_Dt := '';                
          L_Est_Arrival_Dt := TO_DATE(L_ShipDateString, 'MMDDYY HH24:MI');
       END IF;

       IF I_Status_Code = 'X1' THEN
          L_Ship_Dt := '';
          L_Est_Arrival_Dt := '';                
          L_Arrival_Dt := TO_DATE(L_ShipDateString, 'MMDDYY HH24:MI');
       END IF;
                     
       INSERT INTO xx_po_ship_status
       (po_number, carrier_code, bill_of_lading, pro_bill_number,
        actual_Arrival_Date,
        shipped_date, 
        estimated_arrival_date, 
        org_id, 
        created_by, 
        creation_date, 
        last_updated_by, 
        last_update_date,
        last_update_login)

       VALUES(L_PO_Nbr, I_SCAC,
              I_Bill_of_Lading, I_Pro_Bill_Nbr,
              L_Arrival_Dt, 
              L_Ship_Dt,
              L_Est_Arrival_Dt,  
              L_Operating_Unit,   
              apps.fnd_global.user_id,    -- pgm ent 
              SYSDATE,                    -- dt ent 
              apps.fnd_global.user_id,    -- user_id_chg_by 
              SYSDATE,                    -- last update date 
              apps.fnd_global.login_id);  -- last update login 
       
     EXCEPTION
      WHEN others THEN
         err_code := SQLCODE;
         err_msg := substr(SQLERRM, 1, 200);        
         DBMS_OUTPUT.PUT_LINE('Debug: Error on insert ' ||
                 ' PO '  || L_PO_Nbr ||
                 ' Loc ' ||TRIM (L_Loc_ID) ||
                 ' err code ' || err_code ||
                 ' err msg '  || err_msg);
         L_Return_Code := err_code;            
         return L_Return_Code;
     END;
      
     COMMIT;
   
     DBMS_OUTPUT.PUT_LINE('PO Ship Status processing completed for PO: ' || 
     L_PO_Nbr || ' and Location ' ||  L_Loc_ID);                                      

     return L_Return_Code;
   
   END XX_PO_SHIPSTATUS_UPDATE;  
  
END XX_PO_SHIPSTATUS_PKG;
/
