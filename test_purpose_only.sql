----
declare
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
end;, 
----
declare
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
end;
----
declare
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
end;
----
declare
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
end;
----
declare
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
end;