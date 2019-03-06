--Holds to be applied on SO Line before booking process
-------------------------------------------------------

   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1007
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'L'
                       ,P_Org_Id                 =>141 
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>1
                       ,P_Order_Booking_Status   =>'B'
                       ,P_SEND_TO_POOL           =>'Y'
                          );
                                          
   END;
   /
   
  DECLARE
  
  ln_org_id NUMBER;
  ln_Stock_Reserved NUMBER;
  ln_Escalation_No_Of_Days NUMBER;
  lc_Authorities_To_Notify VARCHAR2(240);
  
  BEGIN
  
  Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                       P_Hold_Id                =>1010
                      ,P_Type_Code              =>'HOLD'
                      ,P_Hold_Type              =>'A'
                      ,P_Apply_To_Order_Or_Line =>'L'
                      ,P_Org_Id                 =>ln_org_id
                      ,P_No_Of_Days             =>1
                      ,P_Stock_Reserved         =>1
                      ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                      ,P_Credit_Authorization   =>'N'
                      ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                      ,P_Priority               =>2
                      ,P_Order_Booking_Status   =>'B'
                      ,P_SEND_TO_POOL           => 'Y'
                         );
                                         
  END;
  /
  
  DECLARE
      
      ln_org_id NUMBER;
      ln_Stock_Reserved NUMBER;
      ln_Escalation_No_Of_Days NUMBER;
      lc_Authorities_To_Notify VARCHAR2(240);
      
      BEGIN
      
      Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                           P_Hold_Id                =>1013
                          ,P_Type_Code              =>'HOLD'
                          ,P_Hold_Type              =>'A'
                          ,P_Apply_To_Order_Or_Line =>'L'
                          ,P_Org_Id                 =>ln_org_id
                          ,P_No_Of_Days             =>1
                          ,P_Stock_Reserved         =>1
                          ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                          ,P_Credit_Authorization   =>'N'
                          ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                          ,P_Priority               =>3
                       ,P_Order_Booking_Status   =>'B'
                       ,P_SEND_TO_POOL           => 'Y'
                             );
                                             
   END;
   /
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1048
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'L'
                       ,P_Org_Id                 =>141
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>4
                    ,P_Order_Booking_Status   =>'B'
                    ,P_SEND_TO_POOL           => 'N'
                          );
                                          
   END;
   /

--Holds to be applied on SO Line after booking process
-------------------------------------------------------   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1081
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'L'
                       ,P_Org_Id                 =>141 
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>5
                       ,P_Order_Booking_Status   =>'A'
                       ,P_SEND_TO_POOL           =>'Y'
                          );
                                          
   END; 
   /
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1004
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'L'
                       ,P_Org_Id                 =>ln_org_id
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>6
                       ,P_Order_Booking_Status   =>'A'
                        ,P_SEND_TO_POOL           => 'N'
                          );
                                          
    END;
    /

--Holds to be applied on SO Header before booking process
---------------------------------------------------------       

   DECLARE
      
      ln_org_id NUMBER;
      ln_Stock_Reserved NUMBER;
      ln_Escalation_No_Of_Days NUMBER;
      lc_Authorities_To_Notify VARCHAR2(240);
      
      BEGIN
      
      Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                           P_Hold_Id                =>1001
                          ,P_Type_Code              =>'HOLD'
                          ,P_Hold_Type              =>'A'
                          ,P_Apply_To_Order_Or_Line =>'O'
                          ,P_Org_Id                 =>ln_org_id
                          ,P_No_Of_Days             =>1
                          ,P_Stock_Reserved         =>1
                          ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                          ,P_Credit_Authorization   =>'Y'
                          ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                          ,P_Priority               =>1
                       ,P_Order_Booking_Status   =>'B'
                       ,P_SEND_TO_POOL           => 'N'
                             );
                                             
   END;
   /
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1044
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'O'
                       ,P_Org_Id                 =>ln_org_id
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>ln_Stock_Reserved
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>2
                    ,P_Order_Booking_Status   =>'B'
                    ,P_SEND_TO_POOL           => 'N'
                          );
                                          
   END;
   /
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1041
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'O'
                       ,P_Org_Id                 =>ln_org_id
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>3
                    ,P_Order_Booking_Status   =>'B'
                    ,P_SEND_TO_POOL           => 'N'
                          );
                                          
   END;
   /
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1005
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'O'
                       ,P_Org_Id                 =>141
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>4
                       ,P_Order_Booking_Status   =>'B'
                       ,P_SEND_TO_POOL           => 'N'
                          );
                                          
   END;
   /
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1012
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'O'
                       ,P_Org_Id                 =>161
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'Y'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>5
                       ,P_Order_Booking_Status   =>'B'
                       ,P_SEND_TO_POOL           => 'N'
                       );
                                          
   END;
   /
   
   
--Holds to be applied on SO Header after booking process
--------------------------------------------------------- 
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1009
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'O'
                       ,P_Org_Id                 =>ln_org_id
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>6
                    ,P_Order_Booking_Status   =>'A'
                    ,P_SEND_TO_POOL           => 'N'
                          );
                                          
   END;
   /
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1002
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'O'
                       ,P_Org_Id                 =>ln_org_id
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>ln_Stock_Reserved
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'Y'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>7
                    ,P_Order_Booking_Status   =>'A'
                    ,P_SEND_TO_POOL           => 'N'
                          );
                                          
   END;
   /
   
   DECLARE
   
   ln_org_id NUMBER;
   ln_Stock_Reserved NUMBER;
   ln_Escalation_No_Of_Days NUMBER;
   lc_Authorities_To_Notify VARCHAR2(240);
   
   BEGIN
   
   Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1043
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'A'
                       ,P_Apply_To_Order_Or_Line =>'O'
                       ,P_Org_Id                 =>ln_org_id
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>1
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>8
                       ,P_Order_Booking_Status   =>'A'
                       ,P_SEND_TO_POOL           => 'N'
                          );
                                          
   END;
   /

--Mannual Holds to be applied by other calling API using the Holds Framework custom API
--------------------------------------------------------------------------------------

   DECLARE

     ln_org_id NUMBER;
     ln_Stock_Reserved NUMBER;
     ln_Escalation_No_Of_Days NUMBER;
     lc_Authorities_To_Notify VARCHAR2(240);

   BEGIN

     Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                        P_Hold_Id                =>1048
                       ,P_Type_Code              =>'HOLD'
                       ,P_Hold_Type              =>'M'
                       ,P_Apply_To_Order_Or_Line =>'O'
                       ,P_Org_Id                 =>141
                       ,P_No_Of_Days             =>1
                       ,P_Stock_Reserved         =>ln_Stock_Reserved
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                       ,P_Credit_Authorization   =>'N'
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                       ,P_Priority               =>1
                       ,P_Order_Booking_Status   =>'B'
                       ,P_SEND_TO_POOL           => 'N'
                          );
                                          
   END;
   /
   
    DECLARE
      
      ln_org_id NUMBER;  
      ln_Stock_Reserved NUMBER;  
      ln_Escalation_No_Of_Days NUMBER;  
      lc_Authorities_To_Notify VARCHAR2(240);  
      
    BEGIN  
      
      Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (  
                         P_Hold_Id                =>1011  
                        ,P_Type_Code              =>'HOLD'  
                        ,P_Hold_Type              =>'M'  
                        ,P_Apply_To_Order_Or_Line =>'O'  
                        ,P_Org_Id                 =>ln_org_id  
                        ,P_No_Of_Days             =>1  
                        ,P_Stock_Reserved         =>1  
                        ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days  
                        ,P_Credit_Authorization   =>'N'  
                        ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify  
                        ,P_Priority               =>2  
                        ,P_Order_Booking_Status   =>'B'  
                        ,P_SEND_TO_POOL           => 'N'  
                           );  
                                             
   END;  
   /   
   
   DECLARE
      
     ln_org_id NUMBER;   
     ln_Stock_Reserved NUMBER;   
     ln_Escalation_No_Of_Days NUMBER;   
     lc_Authorities_To_Notify VARCHAR2(240);   
      
   BEGIN   
      
     Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (   
                        P_Hold_Id                =>1042   
                       ,P_Type_Code              =>'HOLD'   
                       ,P_Hold_Type              =>'M'   
                       ,P_Apply_To_Order_Or_Line =>'O'   
                       ,P_Org_Id                 =>ln_org_id   
                       ,P_No_Of_Days             =>1   
                       ,P_Stock_Reserved         =>1   
                       ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days   
                       ,P_Credit_Authorization   =>'Y'   
                       ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify   
                       ,P_Priority               =>3   
                       ,P_Order_Booking_Status   =>'A'   
                       ,P_SEND_TO_POOL           => 'N'   
                          );   
                                             
   END;   
   /
   DECLARE
      
      ln_org_id NUMBER;
      ln_Stock_Reserved NUMBER;
      ln_Escalation_No_Of_Days NUMBER;
      lc_Authorities_To_Notify VARCHAR2(240);
      
   BEGIN
      
      Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                           P_Hold_Id                =>1045
                          ,P_Type_Code              =>'HOLD'
                          ,P_Hold_Type              =>'M'
                          ,P_Apply_To_Order_Or_Line =>'O'
                          ,P_Org_Id                 =>ln_org_id
                          ,P_No_Of_Days             =>1
                          ,P_Stock_Reserved         =>ln_Stock_Reserved
                          ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                          ,P_Credit_Authorization   =>'N'
                          ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                          ,P_Priority               =>4
                       ,P_Order_Booking_Status   =>'B'
                       ,P_SEND_TO_POOL           => 'Y'
                             );
                                             
   END;
   
/     
   DECLARE
      
      ln_org_id NUMBER;
      ln_Stock_Reserved NUMBER;
      ln_Escalation_No_Of_Days NUMBER;
      lc_Authorities_To_Notify VARCHAR2(240);
      
   BEGIN
      
      Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                           P_Hold_Id                =>1046
                          ,P_Type_Code              =>'HOLD'
                          ,P_Hold_Type              =>'M'
                          ,P_Apply_To_Order_Or_Line =>'L'
                          ,P_Org_Id                 =>ln_org_id
                          ,P_No_Of_Days             =>1
                          ,P_Stock_Reserved         =>ln_Stock_Reserved
                          ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                          ,P_Credit_Authorization   =>'N'
                          ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                          ,P_Priority               =>5
                       ,P_Order_Booking_Status   =>'A'
                       ,P_SEND_TO_POOL           => 'N'
                             );
                                             
   END;
/
   DECLARE
      
      ln_org_id NUMBER;
      ln_Stock_Reserved NUMBER;
      ln_Escalation_No_Of_Days NUMBER;
      lc_Authorities_To_Notify VARCHAR2(240);
      
   BEGIN
      
      Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                           P_Hold_Id                =>1047
                          ,P_Type_Code              =>'HOLD'
                          ,P_Hold_Type              =>'M'
                          ,P_Apply_To_Order_Or_Line =>'L'
                          ,P_Org_Id                 =>ln_org_id
                          ,P_No_Of_Days             =>1
                          ,P_Stock_Reserved         =>ln_Stock_Reserved
                          ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                          ,P_Credit_Authorization   =>'N'
                          ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                          ,P_Priority               =>6
                       ,P_Order_Booking_Status   =>'A'
                       ,P_SEND_TO_POOL           => 'N'
                             );
                                             
   END;
   
      
      DECLARE
         
         ln_org_id NUMBER;
         ln_Stock_Reserved NUMBER;
         ln_Escalation_No_Of_Days NUMBER;
         lc_Authorities_To_Notify VARCHAR2(240);
         
      BEGIN
         
         Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                              P_Hold_Id                =>1049
                             ,P_Type_Code              =>'HOLD'
                             ,P_Hold_Type              =>'M'
                             ,P_Apply_To_Order_Or_Line =>'L'
                             ,P_Org_Id                 =>ln_org_id
                             ,P_No_Of_Days             =>1
                             ,P_Stock_Reserved         =>ln_Stock_Reserved
                             ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                             ,P_Credit_Authorization   =>'N'
                             ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                             ,P_Priority               =>7
                          ,P_Order_Booking_Status   =>'A'
                          ,P_SEND_TO_POOL           => 'N'
                                );
                                                
      END;
      

     DECLARE
         
         ln_org_id NUMBER;
         ln_Stock_Reserved NUMBER;
         ln_Escalation_No_Of_Days NUMBER;
         lc_Authorities_To_Notify VARCHAR2(240);
         
         BEGIN
         
         Xx_Om_Holdmgmtfrmwk_Pkg.Populate_Additional_Hold_Info (
                              P_Hold_Id                =>1016
                             ,P_Type_Code              =>'HOLD'
                             ,P_Hold_Type              =>'M'
                             ,P_Apply_To_Order_Or_Line =>'L'
                             ,P_Org_Id                 =>ln_org_id
                             ,P_No_Of_Days             =>1
                             ,P_Stock_Reserved         =>ln_Stock_Reserved
                             ,P_Escalation_No_Of_Days  =>ln_Escalation_No_Of_Days
                             ,P_Credit_Authorization   =>'N'
                             ,P_Authorities_To_Notify  =>lc_Authorities_To_Notify
                             ,P_Priority               =>8
                             ,P_Order_Booking_Status   =>'A'
                             ,P_SEND_TO_POOL           => 'N'
                            );
                                                
      END;
/



/* Script to test Apply OD Holds Manually */
----------------------------------------------

--Order header Id is mandatory
------------------------------

declare

  l_return_status            VARCHAR2(10);
  l_msg_count                NUMBER;
  l_msg_data                 VARCHAR2(2000);

begin
    Xx_Om_Holdmgmtfrmwk_Pkg.Apply_Hold_Manually(20166            --Order header Id
                                               ,NULL             --Order line Id
                                               ,NULL             --Hold Id
                                               ,l_return_status
                                               ,l_msg_count
                                               ,l_msg_data);
    dbms_output.put_line('l_return_status: '||l_return_status||' l_msg_count: '||l_msg_count||' l_msg_data: '||l_msg_data);
end;
 
 
 
/* Script to test Release OD Holds Manually */
----------------------------------------------
--Order header Id / Hold Id is mandatory
----------------------------------------
declare

 l_return_status            VARCHAR2(10);
 l_msg_count                NUMBER;
 l_msg_data                 VARCHAR2(2000);

begin
    Xx_Om_Holdmgmtfrmwk_Pkg.Release_Hold_Manually(20166      --Order header Id
                                                 ,null	     --Order line Id
                                                 ,1011	     --Hold Id
                                                 ,null       --POOL Id
                                                 ,l_return_status
                                                 ,l_msg_count
                                                 ,l_msg_data);
    dbms_output.put_line('l_return_status: '||l_return_status||' l_msg_count: '||l_msg_count||' l_msg_data: '||l_msg_data);
end;

