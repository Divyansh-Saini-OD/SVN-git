CREATE MATERIALIZED VIEW LOG ON OSM.AS_LEAD_LINES_ALL
WITH ROWID, sequence(lead_id)
INCLUDING NEW VALUES;
