---- This file is automatically created while creating business event outbound interface for apps adapter.
---- Apply is file on target database with apps schema to delete artifacts required to capture event.
begin
-- remove subscription
delete from wf_event_subscriptions where event_filter_guid in(
select guid from wf_events where name = 'xx.oracle.apps.om.CreateServiceOrder.out') 
and out_agent_guid in ( select guid from wf_agents where name = 'WF_BPEL_QAGENT');

-- remove agent
delete from wf_agents where name = 'WF_BPEL_QAGENT';

-- remove queue

-- Stop the queue: 
DBMS_AQADM.STOP_QUEUE (Queue_name => 'WF_BPEL_Q');
 
-- Drop the queue: 
DBMS_AQADM.DROP_QUEUE (Queue_name => 'WF_BPEL_Q');

-- remove queue table
DBMS_AQADM.DROP_QUEUE_TABLE ( queue_table        => 'WF_BPEL_QTAB');

end;
/
commit;
