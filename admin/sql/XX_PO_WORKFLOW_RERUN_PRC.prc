create or replace 
PROCEDURE XX_PO_WORKFLOW_RERUN_PRC
(
 RETCODE            OUT   NUMBER,
 ERRBUF             OUT   VARCHAR2,
 P_ITEM_KEY          IN   VARCHAR2,
 P_ITEM_TYPE         IN   VARCHAR2,
 P_PROCESS_ACTIVITY  IN   NUMBER,
 P_FROM_DATE         IN   VARCHAR2,
 P_TO_DATE           IN   VARCHAR2
)

/**********************************************************************************************
MODULE NAME:     XX_PO_WORKFLOW_RERUN_PRC.prc
ORIGINAL AUTHOR: Venkateshwar Panduga
DATE:            18-MAY-2018
DESCRIPTION:

This procedure is used to retry the workflow for the "PO OUTPUT FOR COMMUNICATION"

CHANGE HISTORY:

VERSION DATE             AUTHOR         		DESCRIPTION
------- ---------    -------------- 		-------------------------------------
1.00    18-MAY-2018   Venkateshwar Panduga      	Initial version for Defect#43084

**********************************************************************************************/
  
AS
CURSOR C1(L_ITEM_KEY varchar2,
          L_ITEM_TYPE varchar2,
          L_PROCESS_ACTIVITY number,
          L_FROM_DATE varchar2,
          L_DATE_TO   varchar2
          )
          
Is
SELECT  * FROM APPS.WF_ITEM_ACTIVITY_STATUSES
where ITEM_TYPE = L_ITEM_TYPE  
AND ACTIVITY_STATUS IN('ACTIVE' ,'ERROR')
and ITEM_KEY =nvl(L_ITEM_KEY,ITEM_KEY) 
and PROCESS_ACTIVITY = L_PROCESS_ACTIVITY  
and (BEGIN_DATE > TO_DATE(L_FROM_DATE,'DD-MON-YY')
     and BEGIN_DATE < = L_DATE_TO);

P_LABEL       WF_PROCESS_ACTIVITIES.INSTANCE_LABEL%TYPE;
L_DATE_FROM varchar2(30);
l_Date_to   varchar2(30);
l_cnt    NUMBER :=0;

BEGIN
FND_FILE.PUT_LINE (FND_FILE.LOG,'Item Type:  ' ||P_ITEM_TYPE);
FND_FILE.PUT_LINE (FND_FILE.LOG,'Process Activity:  ' ||P_PROCESS_ACTIVITY);
FND_FILE.PUT_LINE (FND_FILE.LOG,'From Date:  ' ||P_FROM_DATE);
FND_FILE.PUT_LINE (FND_FILE.LOG,'Script Loop Starts:  ');
L_DATE_FROM  := FND_DATE.CANONICAL_TO_DATE(P_FROM_DATE);
L_DATE_TO  := FND_DATE.CANONICAL_TO_DATE(P_TO_DATE);

FND_FILE.PUT_LINE (FND_FILE.log,'DATE FROM:  ' ||L_DATE_FROM);
FND_FILE.PUT_LINE (FND_FILE.LOG,'DATE TO:  ' ||L_DATE_TO);

FOR I IN C1(P_ITEM_KEY,P_ITEM_TYPE,P_PROCESS_ACTIVITY,L_DATE_FROM,L_DATE_TO)
LOOP
P_Label := null;
fnd_file.put_line (fnd_file.log,'Item Type : '|| I.Item_type);
FND_FILE.PUT_LINE (FND_FILE.log,'Item Key : '|| I.ITEM_KEY);
l_cnt := l_cnt+1;
Begin
select  PA.INSTANCE_LABEL  --Label
        INTO P_Label 
from    wf_item_activity_statuses ias,
        wf_process_activities pa
Where   Ias.Item_Type = I.Item_Type
and     ias.item_key  = i.item_key
and     IAS.PROCESS_ACTIVITY = PA.INSTANCE_ID
AND     IAS.ACTIVITY_STATUS IN('ACTIVE' ,'ERROR')
And Process_Activity = I.Process_Activity  ; ---345338 ;
Exception
When Others Then
   P_LABEL := null;
   
end;
FND_FILE.PUT_LINE (FND_FILE.log,'Activity/Label : '|| P_LABEL);

If P_Label Is Not Null
then
fnd_file.put_line(fnd_file.log,'Before api start:');
Wf_Engine.Handleerror(I.Item_Type, I.Item_Key, P_Label , --activity, 
                          'RETRY' ,--comflag 
                          null -- result
                          );
fnd_file.put_line(fnd_file.log,'After api :');                          
else
fnd_file.put_line (fnd_file.log,'Workflow is not fired for the item key :'|| I.Item_key);
end if;                          
fnd_file.put_line (fnd_file.log,'--------------------------------------------------------------------------------------------------------------');                          
end LOOP;     
fnd_file.put_line(fnd_file.log,'Total number of records :'||l_cnt);
END XX_PO_WORKFLOW_RERUN_PRC;
/
