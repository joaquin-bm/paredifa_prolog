/**
 * @author Joaquin Barrientos 
 * @email joaquin2899 at gmail.com
 * @since 2021
 * **/

%some imports
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_files)).
:- use_module(library(http/html_head)).
:- use_module(library(http/json)).
:- use_module(library(http/http_json)).

%creating shortcuts to modules
:- assert(file_search_path(utils, './modules/utils/')).   
:- assert(file_search_path(parser, './modules/parser/')).
:- assert(file_search_path(compiler, './modules/compiler/')).
:- assert(file_search_path(simplifier, './modules/simplifier/')).
:- [compiler(opers)].
%

%
:- use_module(parser(parser), [begin_parse/2]).
:- use_module(compiler(compiler), [begin_compile/2]).
:- use_module(compiler(converter), [begin_convert/2]).
:- use_module(compiler(fa), [normalize_json/2]).
:- use_module(simplifier(simplifier), [begin_simplify/2]).

:- multifile http:location/3.
:- dynamic   http:location/3.

http:location(web, '/w', []).
mime:mime_extension('js', 'application/javascript'). 

:- initialization
    (current_prolog_flag(argv, [SPort | _]) -> true; SPort='9000'),
    atom_number(SPort, Port), 
    server(Port).

:- http_handler('/compiler', compile, []).    % regex to dfa
:- http_handler('/evaluator', evaluate, []).  % dfa/input to queue
:- http_handler('/simplifier', simplify, []). % simplify regex to dfa
:- http_handler('/converter', convert, []).   % nfa to dfa


:- http_handler(web(.), serve_files, [prefix]).

server(Port) :-
    http_server(http_dispatch, [port(Port)]).

serve_files(Request) :-
    http_reply_from_files('web', [], Request).
serve_files(Request) :-
    http_404([], Request).  

compile(Request) :-    
    %compiles without simplification     
    http_read_json_dict(Request, Data), %Data is a PL-Dict / Request is a JSON
    begin_parse(Data.value, Tree),
    begin_compile(Tree, FA),
    term_to_atom(Tree, Atom),
    
    Output = json{
        done : true,
        tree:  Atom,
        fa: FA
    },
    
    reply_json(Output)
.


simplify(Request) :-
     %simplifies the regex, then compiles it
    http_read_json_dict(Request, Data), %Data is a PL-Dict / Request is a JSON


    begin_parse(Data.value, Tree),
    begin_simplify(Tree, Simp),
    begin_compile(Simp, FA),
    term_to_atom(Simp, Atom),

    Output = json{
        done: true,
        tree:  Atom,
        fa: FA
    },
    
reply_json(Output)
. 

convert(Request) :-
    %converts a JSON NFA to a JSON DFA
    http_read_json_dict(Request, Data), %Data is a PL-Dict / Request is a JSON
    
    normalize_json(Data.value, NFA),
    begin_convert(NFA, DFA),

    Output = json{
        done: true,
        fa: DFA
    },

    reply_json(Output)
. 

% evaluate(Request) :-
%     %evaluates the DFA with a given input.  
%     http_read_json_dict(Request, Data), %Data is a PL-Dict / Request is a JSON
%     Value = Data.value,
%     begin_parse(Value, Tree),
%     begin_simplify(Tree, Simp),
%     %begin_compile(Simp, FA),
%     term_to_atom(Simp, Atom),
%     term_to_atom(Tree, Arbol),

%     Output = json{
%         tree:  Arbol,
%         simplified: Atom
%     },

%     reply_json(Output)
% . 

 