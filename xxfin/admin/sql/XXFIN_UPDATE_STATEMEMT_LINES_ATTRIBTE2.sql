-- Update script to reprocess the errored lines.
-- This should update 7118 records.

DECLARE
  v1     VARCHAR2(100);
  v_res  VARCHAR2(100);
  pos1   NUMBER;
  pos2   NUMBER;
  pos3   NUMBER;
  ln_cnt number :=0;
  ln_cnt1 number :=0;
  v_account_num VARCHAR2(100);
  v_bank_account_id VARCHAR2(100);
  v_statement_num VARCHAR2(100);
  v_line_num VARCHAR2(100);
  v_line_id number;  
  Cursor c1 is
  select distinct(description)
    from gl_je_lines where je_header_id in (
   select je_header_id from gl_je_headers where je_source = '81');
BEGIN
  for i in c1 loop
  ln_cnt := ln_cnt+1;
  v1   := i.description;
  pos1 := instr(v1,'-',1,1);
  --dbms_output.put_line('Position 1 '||pos1);
  v_res := instr(v1,'-',1,6);
  --dbms_output.put_line('Position '||v_res);
  v_account_num := SUBSTR(v1,1,pos1-1);
  --dbms_output.put_line(v_account_num);
  IF v_res > 0 THEN----7 dashes are there
    pos2  := instr(v1,'-',1,4);
    pos3  := instr(v1,'-',1,5);
   -- dbms_output.put_line('Position 2 '||pos2);
   -- dbms_output.put_line(pos2-1-pos1);
    v_statement_num := SUBSTR(v1,pos1 +1,pos2-1-pos1);
   -- dbms_output.put_line(v_statement_num);
    v_line_num := SUBSTR(v1,pos2+1,pos3-1-pos2);
    --dbms_output.put_line(v_line_num);
  ELSE
    pos2 := instr(v1,'-',1,2);
    pos3 := instr(v1,'-',1,3);
    --dbms_output.put_line(pos2-1-pos1);
    v_statement_num := SUBSTR(v1,pos1 +1,pos2-1-pos1);
   -- dbms_output.put_line(v_statement_num);
    v_line_num := SUBSTR(v1,pos2+1,pos3-1-pos2);
   -- dbms_output.put_line(v_line_num);
  END IF;
begin  
   select bank_account_id 
   into v_bank_account_id
   from ap_bank_accounts_all
   where bank_account_num = v_account_num
   and inactive_date IS NULL;
   exception 
when others then
NULL;
end;
  -- dbms_output.put_line('bank account_id :'||v_bank_account_id);
   
   Begin
   select statement_line_id 
   into v_line_id
   from ce_statement_lines where statement_header_id in (
select statement_header_id from ce_statement_headers_all where statement_number = v_statement_num
and bank_account_id = v_bank_account_id)
and line_number = v_line_num;
exception 
when others then
v_line_id := NULL;
end;

IF v_line_id IS NOT NULL THEN
 ln_cnt1:=ln_cnt1+1;
END IF;
--dbms_output.put_line(','||v_line_id); 
UPDATE ce_statement_lines
set attribute2 = 'PROC-E2027-YES'
where statement_line_id = v_line_id;
COMMIT;
END loop;
dbms_output.put_line('Total Records : ' ||ln_cnt);
dbms_output.put_line('Total Records in lines : ' ||ln_cnt1);
END;
/