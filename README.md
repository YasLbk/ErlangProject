## Horloges matricielles 

* Projet d'Algo Dis dans le but de comprendre le fonctionnement des horloges matricielles qui représente une extension de l'algorithme de Lamport et Mattern.

* Pour lancer et compiler le projet
```
erl
c(mclock).
```
* Pour lancer le test spécfique avec 3 process

```
mclock:run(3)
``` 


* Pour lancer le test random avec M process et N messages , run_param(M,N)

```
mclock:run_param(3,3)
``` 
* Ce projet comprend toutes les instructions demandées
```
	- Code bien écris et présenté
	- Le programme compile
	- courte documentation
	- Création de M processus communiquant entre eux
	- Gestion de l'affichae output
	- Commentaire du code
	- Création horloge matricielle 
	- Mise à jour horloge matricielle 
	- Messages retardés 
	- Fonction test présentant un scénario exact, spécifié 
	- Fonction test, échange de N messages aléatoires entre M processus 
	- Paramétrable 
	- Vérification erreurs
```