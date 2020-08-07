-- Query to delete the Wrong Statement lines and headers.

DELETE FROM CE_STATEMENT_LINES_INTERFACE;
-- No: of rows deleted : 5157
COMMIT;
DELETE FROM CE_STATEMENT_HEADERS_INT_ALL;
-- No: of rows deleted : 1091
COMMIT;
/