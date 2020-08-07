---- This file is automatically created while creating business event outbound interface for apps adapter.
---- Apply is file on target database with apps schema to create necessary queues and subscriptions required to capture event.
---- This is only required in case the target database is different from one used to build the apps adapter service.

declare
qtab_present number := 0;
q_present number := 0;
qagent_present number := 0;
subscription_present number := 0;
agent_guid varchar2(32);
creation_msg varchar2(4000);
phase_val number := 0;
event_guid varchar2(4000);

begin
  select count(*) into qtab_present from user_tables where table_name  = 'WF_BPEL_QTAB';
  if(qtab_present <> 1 ) 
  then
	dbms_aqadm.create_queue_table(
	           queue_table          => 'WF_BPEL_QTAB',
		   multiple_consumers   => true,
		   queue_payload_type   => 'WF_EVENT_T');
  end if;

  select count(*) into q_present from user_queues where name  = 'WF_BPEL_Q';
  if(q_present <> 1 ) 
  then
	dbms_aqadm.create_queue(queue_name=>'WF_BPEL_Q',queue_table => 'WF_BPEL_QTAB',retention_time => 86400);
	dbms_aqadm.start_queue('WF_BPEL_Q');
  end if;


  select count(*) into qagent_present from wf_agents where name  = 'WF_BPEL_QAGENT';
  if(qagent_present <> 1 ) 
  then
	creation_msg := '
	                <WF_TABLE_DATA>
				<WF_AGENTS>
					<VERSION>1.0</VERSION>
					<GUID>#NEW</GUID>
					<NAME>WF_BPEL_QAGENT</NAME>
					<SYSTEM_GUID>#LOCAL</SYSTEM_GUID>
					<PROTOCOL>SQLNET</PROTOCOL>
					<ADDRESS>APPS.WF_BPEL_QAGENT@#SID</ADDRESS>
					<QUEUE_HANDLER>WF_EVENT_QH</QUEUE_HANDLER>
					<QUEUE_NAME>APPS.WF_BPEL_Q</QUEUE_NAME>
					<DIRECTION>OUT</DIRECTION>
					<STATUS>ENABLED</STATUS>
					<DISPLAY_NAME>WF_BPEL_QAGENT</DISPLAY_NAME>
					<DESCRIPTION>Agent for WF_BPEL_Q</DESCRIPTION>
				</WF_AGENTS>
			</WF_TABLE_DATA>';
	wf_agents_pkg.receive(creation_msg);
  end if;

  
  select guid into agent_guid from wf_agents where name = 'WF_BPEL_QAGENT';

  select guid into event_guid from wf_events where name = 'xx.oracle.apps.om.CreateServiceOrder.out' ;
 
  select count(*) into subscription_present from wf_event_subscriptions where event_filter_guid = event_guid and out_agent_guid = agent_guid ;

  if ( subscription_present <> 1 ) 
  then
        select max(phase) into phase_val from wf_event_subscriptions where event_filter_guid = event_guid;

	phase_val := phase_val*2 + 201;

	creation_msg := 
	'<WF_TABLE_DATA>
		<WF_EVENT_SUBSCRIPTIONS>
			<VERSION>1.0</VERSION>
			<GUID>#NEW</GUID>
			<SYSTEM_GUID>#LOCAL</SYSTEM_GUID>
			<SOURCE_TYPE>LOCAL</SOURCE_TYPE>
			<SOURCE_AGENT_GUID/>
			<EVENT_FILTER_GUID>'||event_guid||'</EVENT_FILTER_GUID>
			<PHASE>'||phase_val||'</PHASE>
			<STATUS>ENABLED</STATUS>
			<RULE_DATA>KEY</RULE_DATA>
			<OUT_AGENT_GUID>'||agent_guid||'</OUT_AGENT_GUID>
			<TO_AGENT_GUID/>
			<PRIORITY>50</PRIORITY>
			<RULE_FUNCTION/>
			<WF_PROCESS_TYPE/>
			<WF_PROCESS_NAME/>
			<PARAMETERS/>
			<OWNER_NAME>FND</OWNER_NAME>
			<OWNER_TAG>FND</OWNER_TAG>
			<CUSTOMIZATION_LEVEL>U</CUSTOMIZATION_LEVEL>
			<LICENSED_FLAG>Y</LICENSED_FLAG>
			<DESCRIPTION>Subscription for enqueuing event in WF_BPEL_Q</DESCRIPTION>
			<EXPRESSION/>
		</WF_EVENT_SUBSCRIPTIONS>
	</WF_TABLE_DATA>';
	wf_event_subscriptions_pkg.receive(creation_msg);
  end if;
  end;
/
commit;
