(* Ce mini-projet porte sur l'apprentissage d'automates séparateurs.
   La lecture de la Section 16.3 des notes de cours est fortement
   recommandée. Le code que vous devez écrire prend en entrée deux
   listes de mots I et E, lues à partir d'un fichier passé en argument
   et renvoie sur la sortie standard le code SMT-LIB à faire passer
   dans une solveur SMT, comme Z3. 
 *)

open Printf

(* ensembles de test : ensemble I *) 
let li = ["";"ab";"abaa";"abaab"]
             
(* ensembles de test : ensemble E *)
let le = ["aa";"b";"ba";"bab"]

(* EXERCICE 1 : extraire  l'alphabet de l'automate.
   La fonction alphabet_from_list prend en entrée une liste de
   chaînes de caractères et retourne une liste triée de
   caractères sans duplication. 
 *)
(* explode : string -> char list 
   prend une chaîne de caractères et renvoie la liste de ses caractères 
 *)
let explode s =
  let rec exp i l =
    if i < 0 then l else exp (i - 1) (s.[i] :: l) in
  exp (String.length s - 1) []

(* alphabet_from_list : string list -> char list  
   - prend en entrée une liste l de chaînes de caractères 
   - renvoie la liste triée et sans duplication de caractères
     apparaissant dans l
 *)
let alphabet_from_list l =
  (*récupération de la liste des caractères dans list_chars*)
  let list_chars= List.flatten (List.map (fun x -> explode x) l) in 
  (*On utilise un sort_uniq pour triée la liste et enlever les duplications*)
	List.sort_uniq compare list_chars;;
  
(* test *)
let a = alphabet_from_list (li @ le) ;;
(* ======================================================================= *)
(* EXERCICE 2 : définition de l'alphabet A et de l'arbre préfixe T en
   SMT-LIB Pour les listes données en exemple, la sortie de la
   fonction declare_types doit être la chaîne de caractères
   "(declare-datatypes () ((A a b) (T e ea eaa eab eb)))" *)

(* prefixes : string -> string list
   renvoie la liste des préfixes d'une chaîne de caractères 
   Nous allons ajouter à chaque préfixe le caractère 'e'.
   Par exemple, prefixes "aba" = ["e"; "ea"; "eab"; "eaba"] *)
let rec prefixes s =
  (*On initialisera une liste de taille len(s)+1 tout en appliquant une extraction de prefixes de s on utilisant x (entier) donné par List.init *)
  List.init ((String.length s)+1) (fun x -> if x=0 then "e" else "e"^(String.sub s 0 x));;


(* prefixes_of_list : string list -> string list
   renvoie la liste triée et sans doublons des préfixes des chaînes 
   de caractères d'une liste donnée *)
let prefixes_of_list l =
  (*On applique prefixes pour chaque element de la liste l , ensuite on applique List.flatten*)
  let list_strs= List.flatten (List.map (fun x -> prefixes x) l) in
  (*On trie la liste résultante , sans doublons*)
	List.sort_uniq compare list_strs;;
  
  
(* declare_types_alphabet : char list -> string
   prend une liste de caractères [c_1; ...; c_n] et renvoie une chaîne 
   de la forme "(A c_1... c_n)" *)
let declare_types_alphabet cl =
  (*string_of_listChars :fonction récursive pour concatener les caractères de l dans une seule chaine*)
  let rec string_of_listChars l = 
    match l with
    |[]->""
    |[x]->Char.escaped x
    |x::l'->(Char.escaped x)^" "^string_of_listChars l'
  in
  let str_of_cl= string_of_listChars cl in
  "(A "^str_of_cl^")";;


(*
  string_of_listStrings : fonction récursive pour concatener les chaines de l dans une seule chaine sous un certain format : string list -> string -> string 
  le deuxième paramètre "string" est une séparation entre les chaines , parceque la fonction participe dans plusieurs fonctions qui va suivre (exemple de séparation : " " , "\n\t\t" , ...)
*)
let rec string_of_listStrings l s = 
   match l with
   |[]->""
   |[x]->x
   |x::l'->x^s^string_of_listStrings l' s;;
   
(* declare_types_trie : string list -> string 
   prend une liste l de chaînes de caractères et 
   renvoie une chaîne de la forme "(T es_1 ... es_n)" où 
   s_1... s_n est une énumération de tous les 
   prefixes des chaînes apparaissant dans l *)
let declare_types_trie l =
  (*Récupération des prefixes de la liste l*)
  let prefixes_l=prefixes_of_list l in
  (*Récupération des éléments de prefixes_l sous forme d'une chaine de caractères*)
  let str_of_l= string_of_listStrings prefixes_l " " in 
  "(T "^str_of_l^")";;


(* declare_types : string list -> char list -> string *)  
let declare_types l cl =
  "(declare-datatypes () ("^(declare_types_alphabet cl)^" "^(declare_types_trie l)^"))";;
  
(* test *)
(*Printf.printf "%s" (declare_types (li @ le) a) *)
  

(* ======================================================================= *)
(* EXERCICE 3 : définir une chaîne de caractères pour les définitions
   en SMT-LIB de
   - l'ensemble d'états Q,
   - la fonction delta de transition de l'automate,
   - l'ensemble final des états acceptants et
   - la fonction f,
   ainsi que les assertions associées.
   Ces définitions ne dépendent pas des listes de mots acceptés ou rejetés. *)

let define_sorts_and_functions  =
  (*l'ensemble des états Q*)
  let etats="(define-sort Q () Int)\n(declare-const n Q)\n(assert (> n 0))\n" in
  (*fonction de transition*)
  let func="(declare-fun delta (Q A) Q)\n(assert (forall ((q Q) (a A)) (and (>= (delta q a) 0) (< (delta q a) n))))\n" in
  (*l'ensemble final des états*)
  let ens_final="(declare-fun final (Q) Bool)\n" in
  (*fonction f *)
  let f="(declare-fun f (T) Q)\n(assert (forall ((x T))(and (>= (f x) 0) (< (f x) n))))\n" in
  etats^func^ens_final^f;;
  
(*test*)
(*Printf.printf "%s" define_sorts_and_functions;;*)
  
(* ======================================================================= *)
(* EXERCICE 4 : contraintes sur les transitions
   La fonction assert_transition_constraints prend en entrée une trie 
   et retourne une chaîne qui modélise les contraintes sur les transitions 
   de l'automate décrites par la formule (56). *)
  
(* eq_trans_constr : string -> char -> string
   renvoie une chaîne de caractères qui correspond à une formule atomique pour 
   la transition étiquetée avec 'a' à partir de l'état s
   Par exemple, pour s = "abc" et  c = 'd' on a 
   eq_trans_constr outputs "(= (f abcd)  (delta (f abc)  d))" *)
let eq_trans_constr s a =
  "(= (f "^s^(Char.escaped a)^")  (delta (f "^s^")  "^(Char.escaped a)^"))";;

(* list_transition_constraints : string list -> string list
   prend une liste de chaînes de caractères et génère une liste 
   de formules atomiques ou de chaînes vides comme suit
   - pour une chaîne non vide de la forme sa on obtient
     une chaine correspondant à l'équation f(sa) = delta (fs) a
   - pour la chaîne vide on obtient la chaîne vide *)
let rec list_transition_constraints l =
  List.map (fun x -> if x="" then "" else eq_trans_constr (String.sub x 0 ((String.length x)-1)) (x.[((String.length x)-1)])) l ;;
  
(* assert_transition_constraints : string list -> string
   prend en entrée une liste de mots et renvoie une chaîne qui modélise 
   les contraintes sur les transitions de l'automate décrit par la 
   formule (56).
   Par exemple, pour la liste [""; "ab"; "aa"; "b"] on obtient la chaîne
   "(assert (and 
               (= (f ea)  (delta (f e)  a))
               (= (f eaa)  (delta (f ea)  a))
               (= (f eab)  (delta (f ea)  b))
               (= (f eb)  (delta (f e)  b))))"
 *)
let assert_transition_constraints l =
  let l_t_c=list_transition_constraints (List.filter (fun x-> x <> "e") (prefixes_of_list l)) in 
  let str=string_of_listStrings l_t_c "\n\t\t" in
  "(assert (and\n\t\t"^str^"))";;

(* test *)
(*Printf.printf "%s" (assert_transition_constraints (li @ le)) *)

(* ======================================================================= *)
(* EXERCICE 5 : contraintes sur les états acceptants La fonction
   assert_acceptance prend en entrée deux listes de mots et retourne
   une chaîne de caractères qui modélise les contraintes sur les états
   acceptants décrites par la formule (57). *)

(* eq_accept : string -> string 
   - prend une chaîne de caractères s et renvoie une chaîne de caractères 
   qui modélise l'appartenance de s à l'ensemble final des états acceptants *)
let eq_accept s =
  "(final (f "^s^"))";;

(* eq_non_accept : string -> string 
   - prend une chaîne de caractères s et renvoie une chaîne de caractères 
   qui modélise la non-appartenance de s à l'ensemble final des états acceptants 
 *)
let eq_non_accept s =
  "(not(final (f "^s^")))";;

(* assert_acceptance : string list -> string list > string
   prend deux listes de chaînes de caractères, li et le, et renvoie une
   chaine qui modélise les contraintes sur les états acceptants
   décrites par la formule (52). 
   Les mots dans li sont acceptés et les mots dans le ne le sont pas. *)
let assert_acceptance li le  =
  (*pour chaque élément acceptable de li si c'est la chaine vide "" on le remplace par epsilon "e" sinon on lui ajoute epsilon au début*)
  let m_li=List.map (fun x ->if x="" then eq_accept "e" else eq_accept ("e"^x)) li in
  (*pour chaque élément non acceptable on lui ajoute aussi un epsilon au début*)
  let m_le=List.map (fun x ->if x="" then failwith("e est acceptable") else eq_non_accept ("e"^x)) le in
  let str=string_of_listStrings (m_li@m_le) "\n\t\t" in
  "(assert (and \t"^str^"))";;
  
  
(* test *)
(*Printf.printf "%s" (assert_acceptance li le) *)
  
(* ======================================================================= *)
(* EXERCICE 6 :
   La fonction smt_code prend en entrée deux listes de mots
   et retourne une chaîne de caractères qui donne l'implémentation 
   en SMT-LIB. *)

(* smt_code : string list -> string list -> string 
   prend deux listes de chaînes de caractères, li et le, et renvoie une chaîne 
   de caractères qui donne l'implémentation en SMT-LIB.
   Les mots dans li sont acceptés et les mots dans le ne le sont pas. 
   Pour vérifier votre algorithme, vous pouvez essayer le code SMT-LIB 
   que vous obtenez dans le solveur Z3: https://rise4fun.com/z3 *)
let smt_code li le =
  (*combination de toutes les fonctions*)
  (*déclaration des types*)
  let s1=declare_types (li @ le) (alphabet_from_list (li @ le)) in
  (*définition des sorts et des fonctions*)
  let s2=define_sorts_and_functions in
  (*les assertion sur les transitions et les contraintes*)
  let s3=assert_transition_constraints (li @ le) in
  (*les contraintes d'acceptance*)
  let s4=assert_acceptance li le in
  let c_init="(assert (= 0 (f e)))\n" in
  s1^"\n"^s2^c_init^s3^"\n"^s4^"\n(check-sat-using (then qe smt))\n(get-model)\n(exit)\n";;
(* test *)
(*Printf.printf "%s" (smt_code li le) *)


(* ======================================================================= *)
(* lire deux listes de chaîne de caractères I et E d'un fichier *)
(* Ne pas modifier cette partie *)

let input_line_opt ic =
  try Some (input_line ic)
  with End_of_file -> None
                    
let read_lines ic =
  let rec aux acc =
    match input_line_opt ic with
    | Some line -> aux (line::acc)
    | None -> (List.rev acc)
  in
  aux []
  
let lines_of_file filename =
  let ic = open_in filename in
  let lines = read_lines ic in
  close_in ic;
  (lines)

let read_lists_from_file (filename: string): ((string list) * (string list))  =
  let lines = lines_of_file filename in
  (String.split_on_char ' ' (List.nth lines 0),
   String.split_on_char ' ' (List.nth lines 1))
  
let () =
  let (li,le) = (read_lists_from_file Sys.argv.(1)) in
  Printf.printf "%s" (smt_code li le)
