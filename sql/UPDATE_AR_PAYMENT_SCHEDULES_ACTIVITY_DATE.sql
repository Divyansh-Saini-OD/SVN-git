UPDATE apps.ar_payment_schedules_all
   SET last_update_date = trx_date    -- set activity date to trx date
 WHERE amount_due_remaining < 0       -- credit balance
   AND status = 'OP'                  -- open status
   AND created_by =                   -- created by CONVERSION user
       (SELECT user_id 
          FROM apps.fnd_user 
         WHERE user_name = 'CONVERSION')
