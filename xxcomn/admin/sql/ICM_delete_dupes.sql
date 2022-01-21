delete from amw_ap_executions aae
where execution_type = 'STEP'
and (pk1,pk2,pk3,audit_procedure_rev_id,ap_step_id) in
(select pk1, pk2, pk3, audit_procedure_rev_id,ap_step_id
from amw_ap_executions where execution_type = 'STEP'
group by pk1,pk2,pk3,audit_procedure_rev_id,ap_step_id
having count(audit_procedure_rev_id) > 1)
and execution_id < (select max(execution_id)
from amw_ap_executions
where execution_type = 'STEP'
and pk1 = aae.pk1
and pk2 = aae.pk2
and pk3 = aae.pk3
and audit_procedure_rev_id = aae.audit_procedure_rev_id
and ap_step_id = aae.ap_step_id);
