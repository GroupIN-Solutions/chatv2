-module(mongoose_graphql_user_query).

-export([execute/4]).

-ignore_xref([execute/4]).

execute(_Ctx, _Obj, <<"account">>, _Args) ->
    {ok, account};
execute(_Ctx, _Obj, <<"muc_light">>, _Args) ->
    {ok, muc_light};
execute(_Ctx, _Obj, <<"session">>, _Args) ->
    {ok, session};
execute(_Ctx, _Obj, <<"checkAuth">>, _Args) ->
    {ok, user}.
