SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_RAISE_BE 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_RAISE_BE.pkb                                |
-- | Description :  Custom Code To Raise Business Events               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  13-Nov-2008 Indra Varada       Initial draft version     |
-- |1.1       12-Jan-2009 Indra Varada       Code Modified To Read Fin |
-- |                                         Setup XX_CDH_RAISE_BE     |
-- |1.2       14-Jan-2009 Indra Varada       Added Logic to set profile|
-- |                                         value for bpel start time |
-- +===================================================================+
AS

PROCEDURE event_main
   (
    x_errbuf                OUT   VARCHAR2
   ,x_retcode               OUT   VARCHAR2
   ,p_event_name            IN    VARCHAR2
   ,p_arg_name              IN    VARCHAR2
   ,p_arg_value             IN    VARCHAR2
   )
AS

l_list                                  WF_PARAMETER_LIST_T;
l_param                                 WF_PARAMETER_T;
l_key                                   VARCHAR2(240);
l_arg_name                              VARCHAR2(2000);
l_arg_value                             VARCHAR2(2000);
l_one_arg_name                          VARCHAR2(200);
l_one_arg_value                         VARCHAR2(200);
l_event                                 VARCHAR2(240);
l_event_enabled                         VARCHAR2(2) := NULL;
l_data                                  CLOB := NULL;
l_module_name                           VARCHAR2(50);
fnd_status                              BOOLEAN;
BEGIN
 
 
   fnd_file.put_line (fnd_file.log,' Raising Business Event:' || p_event_name);
 
 --Get the item key
   l_key := HZ_EVENT_PKG.item_key( p_event_name );
   
 -- initialization of object variables
   l_list := WF_PARAMETER_LIST_T();
   
  -- Add Context values to the list
   hz_event_pkg.AddParamEnvToList(l_list); 

   l_arg_name := p_arg_name || '/';
   l_arg_value := p_arg_value || '/';
   
   l_module_name := substr(l_arg_value,0,instr(l_arg_value,'/')-1);
  
  BEGIN 
   SELECT target_value1 
   INTO l_event_enabled
   FROM xx_fin_translatedefinition def,xx_fin_translatevalues val
   WHERE def.translate_id=val.translate_id
   AND   def.translation_name = 'XX_CDH_RAISE_BE'
   AND   source_value1 = p_event_name
   AND   source_value2 = l_module_name;
  EXCEPTION WHEN NO_DATA_FOUND THEN
     fnd_file.put_line (fnd_file.log, 'Translation Data: XX_CDH_ENABLE_BE Is Not Setup');
  END;
   
 IF TRIM(UPPER(l_event_enabled)) = 'Y' THEN
   
   WHILE TRIM(l_arg_name) IS NOT NULL LOOP
    
    l_one_arg_name  := substr(l_arg_name,0,instr(l_arg_name,'/')-1);
    l_one_arg_value := substr(l_arg_value,0,instr(l_arg_value,'/')-1);
    
    IF TRIM(l_one_arg_name) IS NOT NULL AND l_one_arg_value IS NOT NULL THEN
     
     l_param := WF_PARAMETER_T( NULL, NULL );
     l_list.extend;
     l_param.SetName( l_one_arg_name );
     
     IF INSTR(l_one_arg_value,'$') > 0 THEN
        l_one_arg_value := fnd_profile.value(LTRIM(l_one_arg_value,'$'));
     END IF;   
     
     l_param.SetValue(l_one_arg_value);
     l_list(l_list.last) := l_param; 
     fnd_file.put_line (fnd_file.log, 'Parameter Name and Value ::' || l_one_arg_name || ' and ' || l_one_arg_value);
    END IF;
   
    l_arg_name := substr(l_arg_name,instr(l_arg_name,'/')+1);
    l_arg_value := substr(l_arg_value,instr(l_arg_value,'/')+1);
   
   END LOOP; 

    
   l_event := HZ_EVENT_PKG.event(p_event_name); 
   -- Raise Event         
      Wf_Event.Raise
        ( p_event_name   =>  l_event,
          p_event_key    =>  l_key,
          p_parameters   =>  l_list,
          p_event_data   =>  l_data);

      l_list.DELETE; 
      
      fnd_file.put_line (fnd_file.log, 'Event Successfully Triggered');
      
      IF l_module_name = 'EFND' THEN
        fnd_status := fnd_profile.save('XX_CDH_BPEL_EXTRACT_START_TIME',TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS'),'SITE');
        IF fnd_status THEN
            fnd_file.put_line (fnd_file.log,'Profile - XX_CDH_BPEL_EXTRACT_START_TIME Set to(Site Level) :' ||TO_CHAR(SYSDATE,'MM/DD/YYYY/HH24:MI:SS'));
        ELSE
            fnd_file.put_line (fnd_file.log,'Profile - XX_CDH_BPEL_EXTRACT_START_TIME Could Not Be Set');
        END IF;
      END IF; 
      
   ELSE  
      fnd_file.put_line (fnd_file.log, 'No Events Raised - FIN Translation Setup XX_CDH_ENABLE_BE For This Event and Code is Turned OFF ');
      x_retcode := 1;
   END IF;    

EXCEPTION WHEN OTHERS THEN
     fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - event_main : ' || SQLERRM);
     x_errbuf := 'UnExpected Error Occured In the Procedure - event_main : ' || SQLERRM;
     x_retcode := 2;  
END;
END XX_CDH_RAISE_BE;
/
SHOW ERRORS;
EXIT;