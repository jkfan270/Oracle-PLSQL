100, 250, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 0;
begin

    update CHECK_CLASSIFY
    set DEL_FLAG=1,
        UPDATED_BY=:USER_ID,
        UPDATED_DATE=sysdate
    where CLASSIFY_ID in (select * from UTILS_PKG.SPLIT_STR(:P250_CLASSIFY_IDS, '',''));
    row_count := SQL%ROWCOUNT;

    apex_util.set_session_state(''P250_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P250_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 251, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 0;
    v_count   number(20) := 0;
begin

    select count(1)
    into v_count
    from CHECK_CLASSIFY
    where TENANT_ID = :USERTENANT
      and NAME = :P251_NAME
      and DEL_FLAG = 0
      and CLASSIFY_ID != :P251_CLASSIFY_ID;

    if v_count = 0 then
        update CHECK_CLASSIFY
        set NAME=:P251_NAME,
            REMARK=:P251_REMARK,
            UPDATED_BY=:USER_ID,
            UPDATED_DATE=sysdate
        where CLASSIFY_ID = :P251_CLASSIFY_ID;
        row_count := SQL%ROWCOUNT;
    else
        row_count := -1;
    end if;

    apex_util.set_session_state(''P251_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P251_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 251, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 0;
    v_count   number(20) := 0;
begin

    select count(1)
    into v_count
    from CHECK_CLASSIFY
    where TENANT_ID = :USERTENANT
      and NAME = :P251_NAME
      and DEL_FLAG = 0;
    if v_count = 0 then
        insert into CHECK_CLASSIFY(created_by, creation_date, updated_by, updated_date, remark, tenant_id, name,
                                   del_flag,
                                   is_enable)
        values (:USER_ID, sysdate, :USER_ID, sysdate, :P251_REMARK, :USERTENANT, :P251_NAME, 0, 1);
        row_count := SQL%ROWCOUNT;
    else
        row_count := -1;
    end if;


    apex_util.set_session_state(''P251_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P251_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 252, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 1;
begin

    update CHECK_FORM
    set DEL_FLAG=1,
        UPDATED_BY=:USER_ID,
        UPDATED_DATE=sysdate
    where FORM_ID in (select * from JA_UTILS_PKG.SPLIT_STR(:P252_FORM_IDS, '',''));
    -- 点检对象和子表数据
    update CHECK_OBJECT
    set DEL_FLAG=1
    where OBJECT_ID in (
        select OBJECT_ID
        from (select t.OBJECT_ID
              from CHECK_OBJECT t
                       left join CHECK_OBJECT_FORM_ASSO s on t.OBJECT_ID = s.OBJECT_ID
              where t.OBJECT_ID in (
                  select s.OBJECT_ID
                  from CHECK_OBJECT t
                           left join CHECK_OBJECT_FORM_ASSO s on t.OBJECT_ID = s.OBJECT_ID
                  where t.DEL_FLAG = 0
                    and s.FORM_ID in (
                      select to_number(data_val)
                      from JA_UTILS_PKG.SPLIT_STR(
                              :P252_FORM_IDS,
                              '','')
                  ))
              group by t.OBJECT_ID
              having count(s.FORM_ID) = 1));
    delete CHECK_OBJECT_FORM_ASSO where FORM_ID in (select * from JA_UTILS_PKG.SPLIT_STR(:P252_FORM_IDS, '',''));

    apex_util.set_session_state(''P252_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P252_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 252, 'declare
    v_err_msg     nvarchar2(2000);
    row_count     number(20) := 1;
    v_form_id     number(20);
    v_form_name   nvarchar2(256);
    v_classify_id number(20);
    v_is_enable   number(20);
begin

    select NAME,
           CLASSIFY_ID,
           IS_ENABLE
    into v_form_name,v_classify_id,v_is_enable
    from CHECK_FORM
    where FORM_ID = :P252_FORM_ID;

    insert into CHECK_FORM(created_by, creation_date, updated_by, updated_date, tenant_id, form_serial_no, name,
                           classify_id, plan_id, del_flag, is_enable)
    values (:USER_ID,
            sysdate,
            :USER_ID,
            sysdate,
            :USERTENANT,
            ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss''),
            to_char(sysdate, ''yyyymmddhh24misssss'')||''-副本'',
            v_classify_id,
            null,
            0,
            v_is_enable)
    returning FORM_ID into v_form_id;


    for c in (select * from CHECK_FORM_ITEM where FORM_ID = :P252_FORM_ID)
        loop
            insert into CHECK_FORM_ITEM(created_by, creation_date, updated_by, updated_date, remark, tenant_id, form_id,
                                        name,
                                        type, number_value_max, number_value_min, number_unit, abnormal_show,
                                        image_show,
                                        image_num)
            values (:USER_ID,
                    sysdate,
                    :USER_ID,
                    sysdate,
                    c.REMARK,
                    c.TENANT_ID,
                    v_form_id,
                    c.NAME,
                    c.TYPE,
                    c.NUMBER_VALUE_MAX,
                    c.NUMBER_VALUE_MIN,
                    c.NUMBER_UNIT,
                    c.ABNORMAL_SHOW,
                    c.IMAGE_SHOW,
                    c.IMAGE_NUM);

        end loop;

    commit;
    apex_util.set_session_state(''P252_FORM_ID'', v_form_id);
    apex_util.set_session_state(''P252_ROW_COUNT'', row_count);
exception
    when others then
        rollback;
        apex_util.set_session_state(''P252_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 253, 'declare
    v_err_msg        nvarchar2(2000);
    v_form_serial_no nvarchar2(32);
    row_count        number(20) := 1;
    v_count          number(20) := 0;
begin

    if :P253_FORM_SERIAL_NO is null then
        select ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss'') into v_form_serial_no from dual;
    else
        v_form_serial_no := :P253_FORM_SERIAL_NO;
    end if;
    if :P253_FORM_ID is null then
        select count(1)
        into v_count
        from CHECK_FORM
        where TENANT_ID = :USERTENANT
          and NAME = :P253_FORM_NAME
          and DEL_FLAG = 0;
        if v_count = 0 then
            select count(1)
            into v_count
            from CHECK_FORM
            where TENANT_ID = :USERTENANT
              and FORM_SERIAL_NO = :P253_FORM_SERIAL_NO
              and DEL_FLAG = 0;
            if v_count > 0 then
                row_count := -1;
                apex_util.set_session_state(''P253_MESSAGE'', ''表单编号重复'');
            end if;
        else
            row_count := -1;
            apex_util.set_session_state(''P253_MESSAGE'', ''表单名称重复'');
        end if;
    else
        select count(1)
        into v_count
        from CHECK_FORM
        where TENANT_ID = :USERTENANT
          and NAME = :P253_FORM_NAME
          and DEL_FLAG = 0
          and FORM_ID != :P253_FORM_ID;
        if v_count = 0 then
            select count(1)
            into v_count
            from CHECK_FORM
            where TENANT_ID = :USERTENANT
              and FORM_SERIAL_NO = :P253_FORM_SERIAL_NO
              and DEL_FLAG = 0
              and FORM_ID != :P253_FORM_ID;
            if v_count > 0 then
                row_count := -1;
                apex_util.set_session_state(''P253_MESSAGE'', ''表单编号重复'');
            end if;
        else
            row_count := -1;
            apex_util.set_session_state(''P253_MESSAGE'', ''表单名称重复'');
        end if;
    end if;

    apex_util.set_session_state(''P253_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P253_ROW_COUNT'', 0);
        apex_util.set_session_state(''P253_MESSAGE'', ''数据异常，请联系管理员'');
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;
', 100, 253, 'declare
    v_err_msg        nvarchar2(2000);
    v_form_serial_no nvarchar2(32);
    v_form_id        number(20) ;
    row_count        number(20) := 0;
begin

    if :P253_FORM_SERIAL_NO is null then
        select ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss'') into v_form_serial_no from dual;
    else
        v_form_serial_no := :P253_FORM_SERIAL_NO;
    end if;
    -- insert or update
    if :P253_FORM_ID is null then
        insert into CHECK_FORM(created_by,UPDATED_BY, remark, tenant_id, form_serial_no, name,
                               classify_id)
        values (:USER_ID, :USER_ID, null, :USERTENANT, v_form_serial_no, :P253_FORM_NAME, :P253_CLASSIFY_ID)
        returning FORM_ID into v_form_id;
        row_count := SQL%ROWCOUNT;
        apex_util.set_session_state(''P253_FORM_ID'', v_form_id);
    else
        update CHECK_FORM
        set UPDATED_BY=:USER_ID,
            UPDATED_DATE=sysdate,
            form_serial_no=v_form_serial_no,
            NAME=:P253_FORM_NAME,
            classify_id=:P253_CLASSIFY_ID
        where FORM_ID = :P253_FORM_ID;
        row_count := SQL%ROWCOUNT;
        v_form_id :=:P253_FORM_ID;
    end if;

    apex_util.set_session_state(''P253_ROW_COUNT'', row_count);
    apex_util.set_session_state(''P253_FORM_ID'', v_form_id);

exception
    when others then
        apex_util.set_session_state(''P253_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;
', 100, 253, 'declare
    v_err_msg        nvarchar2(2000);
    v_form_serial_no nvarchar2(32);
    row_count        number(20) := 1;
    v_count          number(20) := 0;
begin

    if :P253_FORM_SERIAL_NO is null then
        select ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss'') into v_form_serial_no from dual;
    else
        v_form_serial_no := :P253_FORM_SERIAL_NO;
    end if;
    if :P253_FORM_ID is null then
        select count(1)
        into v_count
        from CHECK_FORM
        where TENANT_ID = :USERTENANT
          and NAME = :P253_FORM_NAME
          and DEL_FLAG = 0;
        if v_count = 0 then
            select count(1)
            into v_count
            from CHECK_FORM
            where TENANT_ID = :USERTENANT
              and FORM_SERIAL_NO = :P253_FORM_SERIAL_NO
              and DEL_FLAG = 0;
            if v_count > 0 then
                row_count := -1;
                apex_util.set_session_state(''P253_MESSAGE'', ''表单编号重复'');
            end if;
        else
            row_count := -1;
            apex_util.set_session_state(''P253_MESSAGE'', ''表单名称重复'');
        end if;
    else
        select count(1)
        into v_count
        from CHECK_FORM
        where TENANT_ID = :USERTENANT
          and NAME = :P253_FORM_NAME
          and DEL_FLAG = 0
          and FORM_ID != :P253_FORM_ID;
        if v_count = 0 then
            select count(1)
            into v_count
            from CHECK_FORM
            where TENANT_ID = :USERTENANT
              and FORM_SERIAL_NO = :P253_FORM_SERIAL_NO
              and DEL_FLAG = 0
              and FORM_ID != :P253_FORM_ID;
            if v_count > 0 then
                row_count := -1;
                apex_util.set_session_state(''P253_MESSAGE'', ''表单编号重复'');
            end if;
        else
            row_count := -1;
            apex_util.set_session_state(''P253_MESSAGE'', ''表单名称重复'');
        end if;
    end if;

    apex_util.set_session_state(''P253_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P253_ROW_COUNT'', 0);
        apex_util.set_session_state(''P253_MESSAGE'', ''数据异常，请联系管理员'');
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;
', 100, 253, 'declare
    v_err_msg        nvarchar2(2000);
    v_form_serial_no nvarchar2(32);
    v_form_id        number(20) ;
    row_count        number(20) := 0;
begin

    if :P253_FORM_SERIAL_NO is null then
        select ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss'') into v_form_serial_no from dual;
    else
        v_form_serial_no := :P253_FORM_SERIAL_NO;
    end if;
    -- insert or update
    if :P253_FORM_ID is null then
        insert into CHECK_FORM(created_by,UPDATED_BY, remark, tenant_id, form_serial_no, name,
                               classify_id)
        values (:USER_ID, :USER_ID, null, :USERTENANT, v_form_serial_no, :P253_FORM_NAME, :P253_CLASSIFY_ID)
        returning FORM_ID into v_form_id;
        row_count := SQL%ROWCOUNT;
        -- apex_util.set_session_state(''P253_FORM_ID'', v_form_id);
    else
        update CHECK_FORM
        set UPDATED_BY=:USER_ID,
            UPDATED_DATE=sysdate,
            form_serial_no=v_form_serial_no,
            NAME=:P253_FORM_NAME,
            classify_id=:P253_CLASSIFY_ID
        where FORM_ID = :P253_FORM_ID;
        row_count := SQL%ROWCOUNT;
        v_form_id :=:P253_FORM_ID;
    end if;

    apex_util.set_session_state(''P253_ROW_COUNT'', row_count);
    apex_util.set_session_state(''P253_FORM_ID'', v_form_id);
    apex_util.set_session_state(''P253_IS_SHOW'', v_form_id);
    apex_util.set_session_state(''P253_FORM_SERIAL_NO'', v_form_serial_no);


exception
    when others then
        apex_util.set_session_state(''P253_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;
', 100, 253, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 0;
begin

    delete CHECK_FORM_ITEM
    where FORM_ITEM_ID in (select * from UTILS_PKG.SPLIT_STR(:P253_FORM_ITEM_IDS, '',''));
    row_count := SQL%ROWCOUNT;

    apex_util.set_session_state(''P253_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P253_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 254, 'declare
    v_err_msg   nvarchar2(2000);
    v_row_count number(20) := 0;
    v_count     number(20) := 0;
begin

    if :P254_FORM_ITEM_ID is null then
        select count(1)
        into v_count
        from CHECK_FORM_ITEM
        where NAME = :P254_FORM_NAME
          and FORM_ID = :P254_FORM_ID
          and TENANT_ID = :USERTENANT;
        if v_count = 0 then
            insert into CHECK_FORM_ITEM(created_by, creation_date, updated_by, updated_date, remark,
                                        tenant_id, form_id, name, type, number_value_max, number_value_min,
                                        number_unit, abnormal_show, image_show, image_num)
            values (:USER_ID, sysdate, :USER_ID, sysdate, null,
                    :USERTENANT, :P254_FORM_ID, :P254_FORM_NAME, :P254_TYPE, :P254_NUMBER_VALUE_MAX, :P254_NUMBER_VALUE_MIN,
                    :P254_NUMBER_UNIT,
                    :P254_ABNORMAL_SHOW, :P254_IMAGE_SHOW, :P254_IMAGE_NUM);
            v_row_count := SQL%ROWCOUNT;
        else
            v_row_count := -1;
        end if;
    else
        select count(1)
        into v_count
        from CHECK_FORM_ITEM
        where NAME = :P254_FORM_NAME
          and FORM_ITEM_ID != :P254_FORM_ITEM_ID
          and FORM_ID = :P254_FORM_ID
          and TENANT_ID = :USERTENANT;
        if v_count = 0 then
            update CHECK_FORM_ITEM
            set UPDATED_BY=:USER_ID,
                UPDATED_DATE=SYSDATE,
                NAME=:P254_FORM_NAME,
                TYPE=:P254_TYPE,
                NUMBER_VALUE_MAX=:P254_NUMBER_VALUE_MAX,
                NUMBER_VALUE_MIN=:P254_NUMBER_VALUE_MIN,
                NUMBER_UNIT=:P254_NUMBER_UNIT,
                ABNORMAL_SHOW=:P254_ABNORMAL_SHOW,
                IMAGE_SHOW=:P254_IMAGE_SHOW,
                IMAGE_NUM=:P254_IMAGE_NUM
            where FORM_ITEM_ID = :P254_FORM_ITEM_ID;
            v_row_count := SQL%ROWCOUNT;
        else
            v_row_count := -1;
        end if;
    end if;

    apex_util.set_session_state(''P254_ROW_COUNT'', v_row_count);
exception
    when others then
        apex_util.set_session_state(''P254_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end ;
', 100, 255, 'declare
    v_row_count number(20);
    v_err_msg   nvarchar2(2000);
    v_msg       nvarchar2(512);
    v_status    nvarchar2(64);
begin

    ja_import_check_form_item(:P255_XLSX_WORKSHEET, :P255_FILE, :USER_ID, :USERTENANT,:P255_FORM_ID, v_status, v_msg, v_row_count);

    if v_status = ''success'' then
        apex_util.set_session_state(''P255_ERROR_ROW_COUNT'', 0);
    else
        apex_util.set_session_state(''P255_ERROR_ROW_COUNT'', 1);
    end if;
    apex_util.set_session_state(''P255_MESSAGE'', v_msg);
    apex_util.set_session_state(''P255_ROW_COUNT'', v_row_count);
    apex_util.set_session_state(''P255_IMPORT_STATUS'', v_status);
exception

    when others then
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        WRITE_LOG(GET_FN_NAME(), ''error'', v_err_msg, -1, -1);
end;', 100, 257, 'declare
    v_err_msg        nvarchar2(2000);
    v_plan_serial_no nvarchar2(32);
    v_previous_shift nvarchar2(32);
    row_count        number(20) := 1;
    v_count          number(20) := 0;
begin

    if :P257_PLAN_SERIAL_NO is null then
        select ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss'') into v_plan_serial_no from dual;
    else
        v_plan_serial_no := :P257_PLAN_SERIAL_NO;
    end if;
    if :P257_PLAN_ID is null then
        select count(1)
        into v_count
        from CHECK_FORM_PLAN
        where TENANT_ID = :USERTENANT
          and PLAN_NAME = :P257_PLAN_NAME
          and DEL_FLAG = 0;
        if v_count = 0 then
            select count(1)
            into v_count
            from CHECK_FORM_PLAN
            where TENANT_ID = :USERTENANT
              and PLAN_SERIAL_NO = :P257_PLAN_SERIAL_NO
              and DEL_FLAG = 0;
            if v_count > 0 then
                row_count := -1;
                apex_util.set_session_state(''P257_MESSAGE'', ''计划编号重复'');
            end if;
        else
            row_count := -1;
            apex_util.set_session_state(''P257_MESSAGE'', ''计划名称重复'');
        end if;
    else
        select count(1)
        into v_count
        from CHECK_FORM_PLAN
        where TENANT_ID = :USERTENANT
          and PLAN_NAME = :P257_PLAN_NAME
          and DEL_FLAG = 0
          and PLAN_ID != :P257_PLAN_ID;
        if v_count = 0 then
            select count(1)
            into v_count
            from CHECK_FORM_PLAN
            where TENANT_ID = :USERTENANT
              and PLAN_SERIAL_NO = :P257_PLAN_SERIAL_NO
              and DEL_FLAG = 0
              and PLAN_ID != :P257_PLAN_ID;
            if v_count > 0 then
                row_count := -1;
                apex_util.set_session_state(''P257_MESSAGE'', ''计划编号重复'');
            end if;
        else
            row_count := -1;
            apex_util.set_session_state(''P257_MESSAGE'', ''计划名称重复'');
        end if;
        select PREVIOUS_SHIFT into v_previous_shift from CHECK_FORM_PLAN where PLAN_ID = :P257_PLAN_ID;
    end if;
    apex_util.set_session_state(''P257_PREVIOUS_SHIFT'', v_previous_shift);
    apex_util.set_session_state(''P257_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P257_ROW_COUNT'', 0);
        apex_util.set_session_state(''P257_MESSAGE'', ''数据异常，请联系管理员'');
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end ;
', 100, 257, 'declare
    v_err_msg        nvarchar2(2000);
    v_plan_serial_no nvarchar2(32);
    v_cron           nvarchar2(32);
    v_next_execute   nvarchar2(32);
    v_previousShift  nvarchar2(32);
    v_domain            nvarchar2(256);
    -- v_url            nvarchar2(256) := :MPF_API_URL || ''dianjian/apex/cron/generate'';
    v_url            nvarchar2(256) := ''dianjian/apex/cron/generate'';
    v_resp           clob;
    v_plan_id        number(20);
    row_count        number(20)     := 0;
begin
    select decode(regexp_count(:MPF_API_URL, ''com/''), 0, :MPF_API_URL || ''/'', :MPF_API_URL) into v_domain
    from dual;
    v_resp := JA_HTTP_REQUEST(v_domain||v_url, ''POST'', :P257_REQ, :APPKEY, :APPSECRET, :USER_ID);
    if json_value(v_resp, ''$.code'') = 200 then
        v_cron := json_value(v_resp, ''$.data.cronStr'');
        v_next_execute := json_value(v_resp, ''$.data.nextExecute'');
        v_previousShift := json_value(v_resp, ''$.data.previousShift'');
    else
        apex_util.set_session_state(''P257_ROW_COUNT'', -1);
        return;
    end if;
    if :P257_PLAN_SERIAL_NO is null then
        select ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss'') into v_plan_serial_no from dual;
    else
        v_plan_serial_no := :P257_PLAN_SERIAL_NO;
    end if;
    if :P257_PLAN_ID is null then
        insert into CHECK_FORM_PLAN(created_by, updated_by, tenant_id, plan_serial_no, start_date, end_date, interval,
                                    freq, day_month,
                                    day_week, hour, first_start_time, first_end_time, second_start_time,
                                    second_end_time, cron,
                                    next_execute, PREVIOUS_SHIFT, is_enable, plan_name)
        values (:USER_ID, :USER_ID, :USERTENANT, v_plan_serial_no, to_date(:P257_START_DATE, ''yyyy-mm-dd''),
                to_date(:P257_END_DATE, ''yyyy-mm-dd''), :P257_INTERVAL, :P257_FREQ_TYPE, :P257_PLAN_MON,
                :P257_PLAN_WEEK, :P257_HOUR, :P257_DAY_SHIFT_START, :P257_DAY_SHIFT_END, :P257_NIGHT_SHIFT_START,
                :P257_NIGHT_SHIFT_END, v_cron,
                to_date(v_next_execute, ''yyyy-mm-dd hh24:mi:ss''), v_previousShift, :P257_PLAN_STATUS, :P257_PLAN_NAME)
        returning PLAN_ID into v_plan_id;
        row_count := SQL%ROWCOUNT;
        apex_util.set_session_state(''P257_PLAN_ID'', v_plan_id);
    else
        update CHECK_FORM_PLAN
        set UPDATED_BY=:USER_ID,
            UPDATED_DATE=sysdate,
            PLAN_SERIAL_NO=v_plan_serial_no,
            START_DATE=to_date(:P257_START_DATE, ''yyyy-mm-dd''),
            END_DATE=to_date(:P257_END_DATE, ''yyyy-mm-dd''),
            INTERVAL=:P257_INTERVAL,
            FREQ=:P257_FREQ_TYPE,
            DAY_MONTH=:P257_PLAN_MON,
            DAY_WEEK=:P257_PLAN_WEEK,
            HOUR=:P257_HOUR,
            FIRST_START_TIME=:P257_DAY_SHIFT_START,
            FIRST_END_TIME=:P257_DAY_SHIFT_END,
            SECOND_START_TIME=:P257_NIGHT_SHIFT_START,
            SECOND_END_TIME=:P257_NIGHT_SHIFT_END,
            CRON=v_cron,
            NEXT_EXECUTE=to_date(v_next_execute, ''yyyy-mm-dd hh24:mi:ss''),
            PREVIOUS_SHIFT=v_previousShift,
            IS_ENABLE=:P257_PLAN_STATUS,
            PLAN_NAME=:P257_PLAN_NAME
        where PLAN_ID = :P257_PLAN_ID;
        row_count := SQL%ROWCOUNT;
        v_plan_id := :P257_PLAN_ID;
    end if;

    apex_util.set_session_state(''P257_ROW_COUNT'', row_count);
    apex_util.set_session_state(''P257_PLAN_ID'', v_plan_id);

exception
    when others then
        apex_util.set_session_state(''P257_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 257, 'declare
    v_err_msg        nvarchar2(2000);
    v_plan_serial_no nvarchar2(32);
    row_count        number(20) := 1;
    v_count          number(20) := 0;
begin

    if :P257_PLAN_SERIAL_NO is null then
        select ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss'') into v_plan_serial_no from dual;
    else
        v_plan_serial_no := :P257_PLAN_SERIAL_NO;
    end if;
    if :P257_PLAN_ID is null then
        select count(1)
        into v_count
        from CHECK_FORM_PLAN
        where TENANT_ID = :USERTENANT
          and PLAN_NAME = :P257_PLAN_NAME
          and DEL_FLAG = 0;
        if v_count = 0 then
            select count(1)
            into v_count
            from CHECK_FORM_PLAN
            where TENANT_ID = :USERTENANT
              and PLAN_SERIAL_NO = :P257_PLAN_SERIAL_NO
              and DEL_FLAG = 0;
            if v_count > 0 then
                row_count := -1;
                apex_util.set_session_state(''P257_MESSAGE'', ''计划编号重复'');
            end if;
        else
            row_count := -1;
            apex_util.set_session_state(''P257_MESSAGE'', ''计划名称重复'');
        end if;
    else
        select count(1)
        into v_count
        from CHECK_FORM_PLAN
        where TENANT_ID = :USERTENANT
          and PLAN_NAME = :P257_PLAN_NAME
          and DEL_FLAG = 0
          and PLAN_ID != :P257_PLAN_ID;
        if v_count = 0 then
            select count(1)
            into v_count
            from CHECK_FORM_PLAN
            where TENANT_ID = :USERTENANT
              and PLAN_SERIAL_NO = :P257_PLAN_SERIAL_NO
              and DEL_FLAG = 0
              and PLAN_ID != :P257_PLAN_ID;
            if v_count > 0 then
                row_count := -1;
                apex_util.set_session_state(''P257_MESSAGE'', ''计划编号重复'');
            end if;
        else
            row_count := -1;
            apex_util.set_session_state(''P257_MESSAGE'', ''计划名称重复'');
        end if;
    end if;

    apex_util.set_session_state(''P257_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P257_ROW_COUNT'', 0);
        apex_util.set_session_state(''P257_MESSAGE'', ''数据异常，请联系管理员'');
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;
', 100, 257, 'declare
    v_err_msg        nvarchar2(2000);
    v_plan_serial_no nvarchar2(32);
    v_plan_id        number(20) ;
    row_count        number(20) := 0;
begin

    if :P257_PLAN_SERIAL_NO is null then
        select ''JAYW-'' || to_char(sysdate, ''yymmddhh24misssss'') into v_plan_serial_no from dual;
    else
        v_plan_serial_no := :P257_PLAN_SERIAL_NO;
    end if;
    -- insert or update
    if :P257_PLAN_ID is null then
        insert into CHECK_FORM_PLAN(created_by, UPDATED_BY, remark, tenant_id, PLAN_SERIAL_NO, PLAN_NAME,
                                    IS_ENABLE)
        values (:USER_ID, :USER_ID, null, :USERTENANT, v_plan_serial_no, :P257_PLAN_NAME, :P257_PLAN_STATUS)
        returning PLAN_ID into v_plan_id;
        row_count := SQL%ROWCOUNT;
    else
        update CHECK_FORM_PLAN
        set UPDATED_BY=:USER_ID,
            UPDATED_DATE=sysdate,
            PLAN_SERIAL_NO=v_plan_serial_no,
            PLAN_NAME=:P257_PLAN_NAME,
            IS_ENABLE=:P257_PLAN_STATUS
        where PLAN_ID = :P257_PLAN_ID;
        row_count := SQL%ROWCOUNT;
        v_plan_id := :P257_PLAN_ID;
    end if;

    apex_util.set_session_state(''P257_ROW_COUNT'', row_count);
    apex_util.set_session_state(''P257_PLAN_ID'', v_plan_id);
    apex_util.set_session_state(''P257_IS_SHOW'', v_plan_id);
    apex_util.set_session_state(''P257_PLAN_SERIAL_NO'', v_plan_serial_no);


exception
    when others then
        apex_util.set_session_state(''P257_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;
', 100, 257, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 0;
begin

    
    update CHECK_FORM set PLAN_ID=null where FORM_ID in (select * from JA_UTILS_PKG.SPLIT_STR(:P257_FORM_IDS, '',''));
    row_count := SQL%ROWCOUNT;
    apex_util.set_session_state(''P257_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P257_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 258, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 1;
begin

 
    update CHECK_FORM set PLAN_ID=:P258_PLAN_ID where FORM_ID in (select * from UTILS_PKG.SPLIT_STR(:P258_FORM_IDS, '',''));
    row_count := SQL%ROWCOUNT;
    apex_util.set_session_state(''P258_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P258_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 260, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 0;
begin

    update CHECK_OBJECT
    set DEL_FLAG=1,
        UPDATED_BY=:USER_ID,
        UPDATED_DATE=sysdate
    where OBJECT_ID in (select * from UTILS_PKG.SPLIT_STR(:P260_OBJECT_IDS, '',''));
    row_count := SQL%ROWCOUNT;

    apex_util.set_session_state(''P260_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P260_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 262, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 0;
begin

    delete CHECK_OBJECT_DEVICE_ASSO
    where DEVICE_ID in (select * from UTILS_PKG.SPLIT_STR(:P262_DEVICE_IDS, '',''));
    row_count := SQL%ROWCOUNT;

    apex_util.set_session_state(''P262_ROW_COUNT'', row_count);
exception
    when others then
        apex_util.set_session_state(''P262_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;', 100, 262, 'declare
    v_err_msg nvarchar2(2000);
    row_count number(20) := 1;
begin

    update CHECK_OBJECT
    set EXT_ORG_ID=:P262_EXT_ORG_ID,
        CATEGORY_FIRST_CODE=:P262_CATEGORY_FIRST_CODE,
        UPDATED_BY=:USER_ID,
        UPDATED_DATE=sysdate
    where OBJECT_ID = :P262_OBJECT_ID;

    -- 删除本次取消选中的表单
    delete CHECK_OBJECT_FORM_ASSO s
    where s.OBJECT_ID = :P262_OBJECT_ID
      and not exists(
            select 1
            from JA_UTILS_PKG.SPLIT_STR(:P262_FORM_ID, '':'') A
            where s.FORM_ID = A.data_val
        );

    MERGE INTO CHECK_OBJECT_FORM_ASSO A
    USING (
        select data_val form_id, :P262_OBJECT_ID object_id
        from JA_UTILS_PKG.SPLIT_STR(:P262_FORM_ID, '':'')
    ) B
    ON (A.OBJECT_ID = B.object_id and A.FORM_ID = B.form_id)
    WHEN NOT MATCHED THEN
        insert (created_by, updated_by, object_id, form_id)
        values (:USER_ID, :USER_ID, B.object_id, B.form_id);

    commit;
    apex_util.set_session_state(''P262_ROW_COUNT'', row_count);

exception
    when others then
        rollback;
        apex_util.set_session_state(''P262_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;
', 100, 262, 'declare
    v_err_msg   nvarchar2(2000);
    v_object_id number(20);
    row_count   number(20) := 1;
begin

    insert into CHECK_OBJECT(created_by, updated_by, tenant_id, ext_org_id, category_first_code)
    values (:USER_ID, :USER_ID, :USERTENANT, :P262_EXT_ORG_ID, :P262_CATEGORY_FIRST_CODE)
    returning OBJECT_ID into v_object_id;
    
    for c in (select data_val from JA_UTILS_PKG.SPLIT_STR(:P262_FORM_ID, '':''))
        loop
            insert into CHECK_OBJECT_FORM_ASSO(created_by, updated_by, object_id, form_id)
            values (:USER_ID, :USER_ID, v_object_id, c.data_val);
        end loop;

    apex_util.set_session_state(''P262_ROW_COUNT'', row_count);
    apex_util.set_session_state(''P262_OBJECT_ID'', v_object_id);
    apex_util.set_session_state(''P262_IS_SHOW'', v_object_id);

exception
    when others then
        apex_util.set_session_state(''P262_ROW_COUNT'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);
end;


', 100, 263, 'declare
    v_err_msg   nvarchar2(2000);
    v_row_count number(10) := 1;

begin

    for c in (select *
              from CODE_DEVICE
              where DEVICE_ID in (
                  select *
                  from JA_UTILS_PKG.SPLIT_STR(:P263_DEVICE_IDS, '','')
              ))

        loop
            insert into CHECK_OBJECT_DEVICE_ASSO(OBJECT_ID,UPDATED_BY,UPDATED_DATE,DEVICE_ID,
                                                   CREATED_BY, CREATION_DATE)
            values (:P263_OBJECT_ID, :USER_ID, sysdate,c.DEVICE_ID, :USER_ID, sysdate);

        end loop;

    apex_util.set_session_state(''P263_ROW_COUNT1'', v_row_count);
exception
    when
        others then
        apex_util.set_session_state(''P263_ROW_COUNT1'', 0);
        v_err_msg := sqlerrm || chr(13) || dbms_utility.format_error_backtrace;
        JA_WRITE_LOG(''P'' || :APP_PAGE_ID || '':'' || :APP_PAGE_ALIAS, ''error'', v_err_msg, :USER_ID, :USERTENANT,
                     :APP_NAME || '':'' || :APP_ID);

end;'