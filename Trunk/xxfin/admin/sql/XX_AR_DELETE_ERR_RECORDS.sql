---Clear the error records from ra_interface_errors_all table
---for 4/1 E0080 load.
---Script created by Raghu on 05/19/2008.

DELETE FROM apps.ra_interface_errors_all  b
WHERE  message_text in (
'Duplicate invoice number',
'This line has the same transaction flexfield as another invoice within Receivables. For each transaction line in
Receivables, the combination of interface_line_context and interface_line_attribute values must be unique.'
)
and org_id=404 ;

--139907 records should be deleted