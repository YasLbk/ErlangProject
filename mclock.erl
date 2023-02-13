-module(mclock).
-export([setmatrix/4,setnth/3,show_element/3,sendmessage/4,intmessage/2,callback/2,vector_clock/3,vector_proc/4,run_test/1,run/1,create_processes/1, format_list/1, format_matrix/1, merge/2, extract_column/5, leq/2, run_param/2, run_test_param/4]).


%---------------------------- 
%---- Fonctions spécifiquess aux Matrices
%---------------------------- 
% Fonction qui change la valeur de l'élement mat[x][y] dans une matrice  
setmatrix(Matrix, X, Y, New) ->
    Row = lists:nth(X, Matrix), % Cherche la ligne
    RowT = setnth(Y, Row, New), % Change l'elem dans la ligne
    MatrixT = setnth(X, Matrix, RowT), %Change la ligne 
    MatrixT.   

% Fonction qui change la nième valeur d'un tableau
setnth(1, [_|Rest], New) -> [New|Rest];
setnth(I, [E|Rest], New) -> [E|setnth(I-1, Rest, New)].

% Gère l'affichage de la matrice dans l'ouput
format_list(Row) ->
	lists:flatten(io_lib:format("~w",[Row])).
format_matrix(Mat) ->
	string:join(lists:map(fun format_list/1, Mat),"\n").  


% Un getter de l'élèment mat[x][y]
show_element(Mat,X,Y) ->
    Row = lists:nth(X, Mat), % choisis le Y la colonne
    Elem = lists:nth(Y, Row),
    Elem.

% Combine deux vecteurs en prenant le max element [i] de chaque vect 
merge(L, Lc) ->
    Res = lists:zipwith(fun(X, Y)->max(X, Y) end, L, Lc),
    Res.

% Extrait une colonne spécifique d'une matrice 
extract_column(Vect, _, _,0, _)->
    Vect;
extract_column(Vect, M, Column, Counter, Taille) ->
    Value = show_element(M, Taille + 1 - Counter, Column),
    extract_column(Vect++[Value], M, Column, Counter - 1, Taille).

% Comparaison de vecteurs Ti <= Tj, return 1
leq(Ti, Tj) ->
    if Ti > Tj ->
        -1;
    true ->
        1
    end.

%---------------------------- 


%---------------------------- 
%---- Fonctions spécifiquess à la communication inter-proc
%---------------------------- 

% Alerte un process de l'exécution d'un évènement interne
intmessage(Which_Proc, VProc)->
	lists:nth(Which_Proc, VProc) ! intern_event .
   
% Alerte un process d'envoyer un message
sendmessage(From, To, VProc, Counter)->
	lists:nth(From, VProc) ! {message_send, lists:nth(To, VProc), To, Counter}.

% Fonction callback de chaque process 
% Nproc indique le numéro du process courant ( le self )
callback(MatClock, NProc) ->

	receive

	intern_event->
		NewMatClock = setmatrix(MatClock, NProc, NProc,
								show_element(MatClock, NProc, NProc) + 1),

		% On incrémente M[i,i] ou M[Nproc, Nproc] dans notre cas

		io:format(
					"Site ~w ~n	Simule un évenement interne ~n",
					[ NProc]),

		io:format("* Changement de l'estampille matricielle ~n* du site ~w: ~n~s ~n   V~n~s ~n",
					[NProc, format_matrix(MatClock), format_matrix(NewMatClock)]),
		callback(NewMatClock, NProc);

	{ message_send, ProcDst, NDst, Npack}->


		MatClock_ = setmatrix(MatClock, NProc, NProc,
							show_element(MatClock, NProc, NProc) + 1),
		NewMatClock = setmatrix(MatClock_, NProc, NDst,
								show_element(MatClock_, NProc, NDst) + 1),

		% On incrémente M[Nproc, Nproc] et M[Nproc, NDst]

		io:format(
					"Site ~w ~n	Envoi vers le site ~w du message ~w avec la matrice ~n~s ~n",
					[ NProc, NDst, Npack, format_matrix(NewMatClock)]),
		

		io:format("* Changement de l'estampille matricielle ~n* du site ~w: ~n~s ~n   V~n~s ~n",
					[NProc, format_matrix(MatClock), format_matrix(NewMatClock)]),


				ProcDst !{NewMatClock, Npack, NProc, NDst},
		callback(NewMatClock, NProc);


	{ MatClockSrc, Npack, NSrc, NDst}->

		% On check les conditions 

		% Condition 1
		% On va comparer ultérieurment A et B 
		% qui sont MatriceSite[NSrc, NDst]+1 et MatriceRecue[Nsrc, NDst]

	    A = show_element(MatClock, NSrc, NDst) + 1 ,
		B = show_element(MatClockSrc, NSrc, NDst),
		%io:format("Compare ~b ~b~n",[A,B]),

		% Condition 2
		Vect =[],
		% On extrait la colonne NDst de chaque matrice
		SiteRow= extract_column(Vect, MatClock, NDst, length(MatClock), length(MatClock)),
		SiteRcv= extract_column(Vect, MatClockSrc, NDst, length(MatClockSrc), length(MatClockSrc)),
		% On va fixer la valeur du cas ou k=Ndst et k=Nsrc dans les deux vecteurs 
		SiteRow_=setnth(NDst, SiteRow, 0),
		SiteRow_Mod=setnth(NDst, SiteRow_, 0),
		SiteRcv_=setnth(NSrc, SiteRcv, 0),
		SiteRcv_Mod=setnth(NSrc, SiteRcv_, 0),
		% On compare les deux vecteurs 
		Result=leq(SiteRcv_Mod, SiteRow_Mod),
		%io:format("Compare ~w ~w ~n",[SiteRcv_Mod, SiteRow_Mod]),
		%io:format("Compare ~b ~n",[Result]),
		if
			A/=B -> timer:send_after(1000, self(), {MatClockSrc, Npack, NSrc, NDst}); %error resend
			true -> if 
						Result == -1 -> timer:send_after(1000, self(), {MatClockSrc, Npack, NSrc, NDst}) ; %error resend 
						true -> 
						Merged = lists:zipwith(fun(X, Y)->merge(X, Y) end, MatClock, MatClockSrc), %On combine les deux matrices en prenant le max
						% io:format("~w~n",[Merged]),
						Merged_ = setmatrix(Merged, NDst, NDst,	
											show_element(MatClock, NDst, NDst) + 1),  	% M[NDst, NDst]++
						NewMatClock = setmatrix(Merged_, NSrc, NDst,
													show_element(MatClock, NSrc, NDst) + 1), % M[NSrc, NDst]++

						io:format(
									"Site ~w ~n	Réception delapart du site ~w du message ~w avec la matrice ~n~s ~n",
									[ NProc, NSrc, Npack, format_matrix(MatClockSrc)]),

						io:format("* Changement de l'horloge matricielle ~n* du site ~w: ~n~s ~n   V~n~s ~n",
									[NDst, format_matrix(MatClock), format_matrix(NewMatClock)]),
						
						
						callback(NewMatClock, NProc)
					end
		end;
		
	Unexpected->
		io:format(" ERROR Received unexpected message: ~s", [Unexpected]),
		callback(MatClock, NProc)

	end.


%---------------------------- 
%---- Fonctions spécifiquess à la création de la matrice clock et la liste des procs 
%---------------------------- 

% Crée un vecteur de taille N et initialise ses élèments avec Value
vector_clock(Vect, 0, _)->
	Vect;
vector_clock(Vect, Taille, Value) ->
	vector_clock(Vect++[Value], Taille - 1, Value).

% Créer une liste de processus
vector_proc(SinglePro, _, _, 0) ->
	SinglePro;
vector_proc(PrList, Matrix, Taille, Counter) ->
	vector_proc(PrList ++ [spawn(mclock, callback, [Matrix, Taille + 1 - Counter])], Matrix, Taille, Counter - 1).


%---------------------------- 
%---- Fonctions spécifiquess aux test1
%---------------------------- 
% Fonction test 
run_test(VProc) ->

	sendmessage(1, 3, VProc, 1), 
	sendmessage(2, 1, VProc, 2),
	sendmessage(3, 2, VProc, 3),
	sendmessage(1, 2, VProc, 4), 
	intmessage(2, VProc).


% Crée une liste de proc et affecte à chaque proc une horloge matricielle
create_processes(Number_Proc) ->
	Vect = [],
    Vector_row = vector_clock(Vect, Number_Proc, 0),
    Matrix = vector_clock(Vect, Number_Proc, Vector_row),
	Vect_P = [],
    Procs = vector_proc(Vect_P, Matrix, Number_Proc, Number_Proc),
	Procs.

% Lance le test spécifique avec N process
run(Number_Proc)->
    Procs = create_processes(Number_Proc),
	run_test(Procs).


%---------------------------- 
%---- Fonctions spécifiquess au test random
%---------------------------- 

% Test avec M=Number_msg random messages et N=NProc proc
run_test_param(Procs, NProc, 1, Number_msg)	->
%	Rand = [rand:uniform(NProc) || _ <- lists:seq(1, 2)],
%	Send = lists:nth(1, Rand),
%	Rcv = lists:nth(2, Rand),
	Send = rand:uniform(NProc),
	Rcv = rand:uniform(NProc),
	sendmessage(Send, Rcv, Procs, Number_msg);
run_test_param(Procs, NProc, Counter, Number_msg) ->
	Send = rand:uniform(NProc),
	Rcv = rand:uniform(NProc),
	sendmessage(Send, Rcv, Procs, Number_msg-Counter+1),
	run_test_param(Procs, NProc, Counter-1, Number_msg).	

% Lance le test random
run_param(Number_Proc, Number_msg)->
    Procs = create_processes(Number_Proc),
	run_test_param(Procs, Number_Proc, Number_msg, Number_msg).

