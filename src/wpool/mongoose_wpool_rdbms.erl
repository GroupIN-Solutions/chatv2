-module(mongoose_wpool_rdbms).
-behaviour(mongoose_wpool).

-export([init/0]).
-export([start/4]).
-export([stop/2]).

init() ->
    case ets:info(prepared_statements) of
        undefined ->
            Heir = case whereis(ejabberd_sup) of
                       undefined -> [];
                       Pid -> [{heir, Pid, undefined}]
                   end,
            ets:new(prepared_statements,
                    [named_table, public, {read_concurrency, true} | Heir]),
            ok;
        _ ->
            ok
    end.

start(Host, Tag, WpoolOpts, RdbmsOpts) ->
    try do_start(Host, Tag, WpoolOpts, RdbmsOpts)
    catch
        Err -> {error, Err}
    end.

do_start(Host, Tag, WpoolOpts0, RdbmsOpts) when is_list(WpoolOpts0) and is_list(RdbmsOpts) ->
    Backend =
        case lists:keyfind(server, 1, RdbmsOpts) of
            {_, ConnStr} when is_list(ConnStr) -> odbc;
            {_, Tuple} when is_tuple(Tuple) -> element(1, Tuple)
        end,

    try mongoose_rdbms_backend:backend_name() of
        Backend -> ok;
        OtherBackend ->
            throw(#{reason => "Cannot start an RDBMS connection pool: only one RDBMS backend can be used",
                    opts => RdbmsOpts, new_backend => Backend, existing_backend => OtherBackend})
    catch
        error:undef ->
            backend_module:create(mongoose_rdbms, Backend, [query, execute])
    end,

    mongoose_metrics:ensure_db_pool_metric({rdbms, Host, Tag}),

    Worker = {mongoose_rdbms, RdbmsOpts},
    %% Without lists:map dialyzer doesn't understand that WpoolOpts is a list (?) and the
    %% do_start function has no return.
    WpoolOpts = lists:map(fun(X) -> X end, [{worker, Worker}, {pool_sup_shutdown, infinity} | WpoolOpts0]),
    Name = mongoose_wpool:make_pool_name(rdbms, Host, Tag),
    case wpool:start_sup_pool(Name, WpoolOpts) of
        {ok, Pid} -> {ok, {Pid, [{call_timeout, 60000}]}};
        Err -> Err
    end.

stop(_, _) ->
    ok.
