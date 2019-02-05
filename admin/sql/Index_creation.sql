create index xx_WF_nots_N1 on applsys.WF_NOTIFICATIONS (MESSAGE_NAME,MESSAGE_TYPE) tablespace APPS_TS_TX_IDX parallel 4;
exec dbms_stats.gather_index_stats('APPS','XX_WF_NOTIFICATIONS_N1')
alter index XX_WF_NOTIFICATIONS_N1 noparallel;
execute dbms_stats.gather_table_stats(ownname => 'APPLSYS', tabname => 'WF_NOTIFICATIONS',METHOD_OPT => 'FOR COLUMNS SIZE 64 STATUS,MESSAGE_NAME');
