declare

  cursor c1 is
  select a.*
  from   apps.jtf_rs_salesreps a, apps.jtf_rs_resource_extns_vl b,
         apps.jtf_rs_group_mbr_role_vl c, apps.jtf_rs_roles_vl d
  where  d.role_type_code = 'SALES'
    --and  nvl(d.attribute14, 'X') not in ('HSE', 'OT', 'PRXY')
    and  c.role_id = d.role_id
    and  sysdate between c.start_date_active and nvl(c.end_date_active, sysdate + 1)
    and  b.resource_id = c.resource_id
    and  sysdate between b.start_date_active and nvl(b.end_date_active, sysdate + 1)
    and  a.resource_id = b.resource_id
    and  not (sysdate between a.start_date_active and nvl(a.end_date_active, sysdate + 1))
  order by 5;

  lc_return_status         VARCHAR2(1) ;
  X_MSG_COUNT              NUMBER ;
  X_MSG_DATA               VARCHAR2(5000);

begin
  for rs_rec in c1 loop
            JTF_RS_SALESREPS_PUB.update_salesrep
                             ( P_API_VERSION           => 1.0,
                               P_SALESREP_ID           => rs_rec.salesrep_id,
                               P_END_DATE_ACTIVE       => null,
                               P_ORG_ID                => rs_rec.org_id,
                               P_SALES_CREDIT_TYPE_ID  => rs_rec.sales_credit_type_id,
                               P_OBJECT_VERSION_NUMBER => rs_rec.object_version_number,
                               X_RETURN_STATUS         => lc_return_status,
                               X_MSG_COUNT             => x_msg_count,
                               X_MSG_DATA              => x_msg_data
                             );
  end loop;

  commit;
end;


/
