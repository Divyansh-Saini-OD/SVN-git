select count(*)
from apps.mtl_categories_b mc
where structure_id in (101,201)
--and enabled_flag = 'Y'
and segment2 <> 'NON-TRADE'
and segment5 in (select to_char(fnd_value)
from apps.xx_inv_merchier_val_stg
where flex_value_set_name = 'SUBCLASS');

set serveroutput on size 1000000
Declare
cursor cat_cur is
select *
from apps.mtl_categories_b mc
where structure_id in (101,201)
--and enabled_flag = 'Y'
and segment2 <> 'NON-TRADE'
and segment5 in (select to_char(fnd_value)
from apps.xx_inv_merchier_val_stg
where flex_value_set_name = 'SUBCLASS');
--
x_msg_data                   VARCHAR2(3000) :=FND_API.G_FALSE;
x_return_status              VARCHAR2(1)    := NULL;      -- S, E or U
x_errorcode                  NUMBER         := NULL;
x_msg_count                  NUMBER         := NULL;
x_error_msg		varchar2(32767);
v_rec_count         number :=0;
v_err_count         number :=0;
--
begin
    For cat_rec in cat_cur
    Loop
        v_rec_count := v_rec_count +1;
	INV_ITEM_CATEGORY_PUB.DELETE_CATEGORY(
		p_api_version   => 1.0
		,p_init_msg_list => FND_API.G_TRUE
		,p_commit        => FND_API.G_FALSE
		,x_return_status => x_return_status
		,x_errorcode     => x_errorcode
		,x_msg_count     => x_msg_count
		,x_msg_data      => x_msg_data
		,p_category_id  => cat_rec.category_id
	); 
	IF (x_return_status <> 'S') THEN
                v_err_count := v_err_count +1;
		IF x_msg_count = 1 THEN
                    dbms_output.put_line(substr(x_msg_data,1,255));
                else  
		    FOR I IN 1..x_msg_count
		    LOOP
			dbms_output.put_line(I||'. '||SubStr(FND_MSG_PUB.Get(p_encoded =>
			    FND_API.G_FALSE ), 1, 255));
		    END LOOP;
		END IF;
	END IF;
    End Loop;
    dbms_output.put_line('Records Processed = '||v_rec_count);
    dbms_output.put_line('Records Errored = '||v_err_count);
End;
/

select count(*)
from apps.mtl_categories_b mc
where structure_id in (101,201)
--and enabled_flag = 'Y'
and segment2 <> 'NON-TRADE'
and segment5 in (select to_char(fnd_value)
from apps.xx_inv_merchier_val_stg
where flex_value_set_name = 'SUBCLASS');
