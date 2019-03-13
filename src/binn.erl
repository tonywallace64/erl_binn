%%%-------------------------------------------------------------------
%%% @author Tony Wallace <tony@resurrection>
%%% @copyright (C) 2019, Tony Wallace
%%% @doc
%%%
%%% @end
%%% Created :  8 Mar 2019 by Tony Wallace <tony@resurrection>
%%%-------------------------------------------------------------------
-module(binn).

%% API
-export([encode/2,decode/1,test/0]).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
-spec encode(binary(),term()) -> binary().
encode(_,_) ->
    throw(not_implemented).
-spec decode(binary()) -> {binary(),term()}.
%%%===================================================================
%%% Internal functions
%%%===================================================================
decode(<<0:3,_SubTypeSize:1,Subtype:4,Rest/binary>>=K) ->
    io:format("~p~n",[K]),
    {Rest,boolean_decode(Subtype)};
decode(<<32:8,Data:8,Rest/binary>>) ->
    % unsiged integer
    {Rest,Data};
decode(<<33:8,Data:8/signed,Rest/binary>>) ->
    {Rest,Data};
decode(<<64:8,Data:16,Rest/binary>>) ->
    {Rest,Data};
decode(<<65:8,Data:16/signed,Rest/binary>>) ->
    {Rest,Data};
decode(<<96:8,Data:32,Rest/binary>>) ->
    {Rest,Data};
decode(<<97:8,Data:32/signed,Rest/binary>>) ->
    {Rest,Data};
decode(<<98:8,Data:32/float,Rest/binary>>) ->
    {Rest,Data};
decode(<<128:8,Data:64,Rest/binary>>) ->
    {Rest,Data};
decode(<<129:8,Data:64/signed,Rest/binary>>) ->
    {Rest,Data};
decode(<<130:8,Data:64/float,Rest/binary>>) ->
    {Rest,Data};
decode(<<160:8,Size:8,R0/binary>>=K1) ->
    {Size2,<<R2/binary>>} = one_four_decode({Size,R0}),
    maybe_decode_string(K1,Size2,R2);
decode(<<224:8,Size:8,R0/binary>> = K1) ->
    {Size2,<<R2/binary>>} = one_four_decode({Size,R0}),
    maybe_decode_list(size(K1),K1,Size2,R2).

maybe_decode_list(Bytes,_,ListSize,<<Count0:8,R2/binary>>) when Bytes >= ListSize ->
    {Count1,R3} = one_four_decode({Count0,R2}),
    decode_list(Count1,R3,[]);
maybe_decode_list(_,R0,_,_) ->
    {R0,insufficient_data}.


% Note, the sting length specified in the the size parameter does not include
% null termination characher thus the string "hi" has given length of two,
% but the string is stored as <<$h$i,0>> thus taking 3 bytes (in addition to
% other parameters).
maybe_decode_string(_Original,StrLen,R0) when size(R0) > StrLen ->
    <<Data:StrLen/binary-unit:8,0:8,R1/binary>> = R0,
    {R1,binary_to_list(Data)};
maybe_decode_string(R0,_,_) ->
    {R0,insufficient_data}.


boolean_decode(0) ->
    null;
boolean_decode(1) ->
    true;
boolean_decode(2) ->
    false.

one_four_decode({X,R}) when X < 128 ->
    {X,R};
one_four_decode({X,R}) ->
    R0 = <<X:8,R/binary>>,
    <<1:1,X2:31,R1/binary>> = R0,
    {X2,R1}.

decode_list(0,Coded,L) ->
    {Coded,lists:reverse(L)};
decode_list(N,Coded,Acc) when is_integer(N), N>0 ->
    {R1,Decoded} = decode(Coded),
    decode_list(N-1,R1,[Decoded|Acc]).

test() ->
    {<<>>,[123,-456,789]} 
	= decode(
	    <<16#e0,16#0b,16#03,16#20,123,16#41,16#fe,16#38,16#40,3,16#15>>),
    {<<>>,"hi"} 
	= decode(<<160,2,"hi",0>>),
    {<<160,2,"hi">>,insufficient_data} 
	= decode(<<160,2,"hi">>),
    pass.
