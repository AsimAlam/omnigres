create function instantiate_file_store(filename text, schema regnamespace default 'omni_credentials') returns void
    language plpgsql
as
$$
begin
    perform set_config('search_path', schema::text || ',public', true);

    if filename not like '/%' then
        filename := current_setting('data_directory') || '/' || filename;
    end if;

    create table if not exists credential_file_stores
    (
        filename text unique
    );

    create or replace function credential_file_store_reload(filename text) returns boolean
        language plpgsql
    as
    $code$
    begin
        if filename not like '/%' then
            filename := current_setting('data_directory') || '/' || filename;
        end if;
        perform pg_stat_file(filename);
        create temp table __new_encrypted_credentials__
        (
            like encrypted_credentials
        ) on commit drop;
        execute format('copy __new_encrypted_credentials__ from %L', filename);
        raise notice '%', pg_read_file(filename);

        insert into encrypted_credentials (name, value, kind, principal, scope)
        select name, value, kind, principal, scope
        from __new_encrypted_credentials__
        on conflict (name, kind, principal, scope) do update set value = excluded.value;
        return true;
    exception
        when others then return false;
    end;
    $code$;
    execute format('alter function credential_file_store_reload set search_path to %I,public', schema);

    insert into credential_file_stores (filename) values (instantiate_file_store.filename);

    perform credential_file_store_reload(filename);
    execute format('copy encrypted_credentials to %L', filename);

    create or replace function file_store_credentials_update() returns trigger
        security definer
        language plpgsql as
    $code$
    declare
        rec record;
    begin
        for rec in select * from credential_file_stores
            loop
                execute format('copy encrypted_credentials to %L', rec.filename);
            end loop;
        return new;
    end;
    $code$;
    execute format('alter function file_store_credentials_update set search_path to %I,public', schema);

    perform
    from pg_trigger
    where tgname = 'file_store_credentials_update'
      and tgrelid = 'encrypted_credentials'::regclass;

    if not found then
        create constraint trigger file_store_credentials_update
            -- TODO: truncate can't be supported at this level
            after update or insert or delete
            on encrypted_credentials
            deferrable initially deferred
            for each row
        execute function file_store_credentials_update();
    end if;

end;
$$;
