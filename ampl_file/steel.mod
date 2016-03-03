#---------------------------------------------
#-------------- INSIEMI ----------------------
#---------------------------------------------
set TURNI; #L'insieme dei turni di lavoro
set PRODOTTI; #L'insieme dei prodotti che si possono produrre nell'azienda
set MACCHINE; #L'insieme delle macchine numerate, indipendenti dalla fabbrica
set DEPOSITI; #L'insieme dei depositi numerati
set FABBRICHE; #L'insieme delle fabbriche dell'azienda




#---------------------------------------------
#-------------- PARAMETRI --------------------
#---------------------------------------------
param bigM;	#Un valore grande per l'attivazione delle variabili logiche
param guadagniAFinito{PRODOTTI}; #Guadagni provenienti dalla vendita dell'acciaio
param costiAGrezzo{PRODOTTI}; #Costi per lavorare un tipo di acciaio
param tempiMaxMacchine{FABBRICHE,MACCHINE,TURNI}; #Tempo massimo di lavorazione delle macchine per turni in entrambe le fabbriche
param tempiProd{FABBRICHE,MACCHINE,TURNI,PRODOTTI}; #Tempi neccessari per produrre una tonnellata di un tipo di acciaio lavorato
param numOperaiMacchine; #Numero operai per macchina
param costoPuliziaM; #Costo per pulizia macchina 
param tempoPuliziaM; #Tempo impiegato per la pulizia delle macchine
param costoOperaioProduzione; #Costo di ogni operaio che segue le macchine durante la loro produzione
param mImpostateObbligatorie{FABBRICHE,MACCHINE,PRODOTTI}; #Macchine impostate obbligatoriamente alla produzione di un solo tipo di acciaio lavorato        Si = 1         No = 0
param costiTrasporto{FABBRICHE,DEPOSITI}; #Costi di strasporto del camion da una fabbrica ad un deposito
param tempiTrasporto{FABBRICHE,DEPOSITI}; #Tempi di trasporto da una fabbrica ad un deposito
param costoOperaioTrasporto; #Costo di ogni operaio che guida un camion
param tonnellatePerCamion; #Tonnellate di acciaio lavorato che un camion riesce a trasportare
param richiesteMinDepositi{PRODOTTI,DEPOSITI}; #Richiesta minima di acciaio lavorato per ogni deposito
param richiesteMaxDepositi{DEPOSITI}; #Massima capacità di acciaio lavorato per ogni deposito




#---------------------------------------------
#-------------- VARIABILI --------------------
#---------------------------------------------
#Rappresenta il numero di tonnellate prodotto lavorato per ogni spicifico acciaio, turno, macchina e una fabbrica
var al{FABBRICHE,MACCHINE,TURNI,PRODOTTI}  integer >= 0;
#Rappresenta il numero di tonnelate di ogni prodotto lavorato che occorre traspostare da ogni fabbrica ad ogni deposito
var at{FABBRICHE,PRODOTTI,DEPOSITI}  >= 0;
#Rappresenta il numero di camion neccessari per trasportare tutto il prodotto lavorato di ogni fabbrica ai rispettivi magazzini
var nc{FABBRICHE,DEPOSITI} integer >= 0;
#Data una fabbrica, una macchina, un turno di lavoro e un tipo di acciaio, questa variabile logica binaria indica se è stata eseguita una lavorazione del prodotto indicato
#Si = 1         No = 0
var mAcciaio{FABBRICHE,MACCHINE,TURNI,PRODOTTI} binary;
#Data una fabbrica, un turno di lavoro e una macchina, questa variabile logica binaria indica se è stata eseguita una lavorazione con tale macchina
#Si = 1         No = 0
var mAttive{FABBRICHE,MACCHINE,TURNI} binary;
#Data una fabbrica, una macchina ed un tipo di acciaio, questa variabile logica binaria indica se la macchina indicata è stata impostata per la lavorazione del prodotto.
#Si = 1         No = 0
var mImpostate{FABBRICHE,MACCHINE,PRODOTTI} binary;




#---------------------------------------------
#-------------- FUNZIONE OBBIETTIVO ----------
#---------------------------------------------
#Il profitto deriva dalle entrare dovute alla vendita di tutto l'acciaio lavorato meno i costi sostenuti nel produrlo.
maximize profitto: 
			#Profitto ottenuto dalla vendita dell'acciaio meno il suo costo iniziale
			sum{p in PRODOTTI}((guadagniAFinito[p]-costiAGrezzo[p])*sum{f in FABBRICHE,m in MACCHINE,t in TURNI}al[f,m,t,p])-

			#PICCOLO PROBLEMA
			#Costo dei dipendenti che seguono le macchine
			sum{f in FABBRICHE, m in MACCHINE,t in TURNI}(mAttive[f,m,t]*numOperaiMacchine*costoOperaioProduzione)-

			#Costi delle pulizie delle macchine non impostate alla produzione di un unico tipo di acciaio
			sum{f in FABBRICHE, m in MACCHINE,t in TURNI}sum{p in PRODOTTI}(mAcciaio[f,m,t,p]- mImpostate[f,m,p])*costoPuliziaM-

			#Costi delle pulizie delle macchine impostate alla prodduzione di un unico tipo di acciaio
			sum{f in FABBRICHE, m in MACCHINE,p in PRODOTTI}mImpostate[f,m,p]*costoPuliziaM -

			#Costi del trasporto con i camion 
			sum{f in FABBRICHE,d in DEPOSITI}(nc[f,d]*costiTrasporto[f,d])-

			#Costi dei operai che guidano i camion
			sum{f in FABBRICHE,d in DEPOSITI}(nc[f,d]*tempiTrasporto[f,d])*costoOperaioTrasporto;




#---------------------------------------------
#-------------- VINCOLI ----------------------
#---------------------------------------------

#Questo vincolo fa si che per ogni fabbrica, macchina e turno, il tempo effettivo di lavorazione dell'acciaio sia sempre inferirore o uguale al tempo di lavoro dei dipendenti imposto dai sindacati
#In particolar modo tiene conto anche del tempo di pulizia della macchina, sia essa impostata o no, alla produzione di un solo tipo di acciaio
s.t. VtempoMNImpostate{f in FABBRICHE, m in MACCHINE,t in TURNI}: sum{p in PRODOTTI}(tempiProd[f,m,t,p]*al[f,m,t,p] + (mAcciaio[f,m,t,p]- mImpostate[f,m,p])*tempoPuliziaM) <= tempiMaxMacchine[f,m,t];

#Questo vincolo fa si che per ogni fabbrica, macchina e prodotto, il tempo complessivo di lavorazione sia sempre inferirore o uguale al tempo di lavoro dei dipendenti imposto dai sindacati
#In particolar modo tiene conto anche del tempo di pulizia della macchina nel caso essa sia impostata alla produzione di un solo tipo di acciaio
s.t. VtempoMImpostate{f in FABBRICHE, m in MACCHINE,p in PRODOTTI}: sum{t in TURNI}(tempiProd[f,m,t,p]*al[f,m,t,p])+mImpostate[f,m,p]*tempoPuliziaM <= sum{t in TURNI}tempiMaxMacchine[f,m,t];

#Questo vincolo lega la variabile al con la variabile at, permettendo così di legare le richieste di acciaio dei depositi, con la loro produzione
s.t. VCat{f in FABBRICHE,p in PRODOTTI}: sum{m in MACCHINE,t in TURNI}al[f,m,t,p] = sum{d in DEPOSITI}at[f,p,d];

#Questi due vincoli impongono alla varibile at un limite inferiore dovuto alla richiesta dei depositi e un vincolo superiore dovuto alla loro massima capienza
s.t. VRichiesteMinDepositi{p in PRODOTTI,d in DEPOSITI}: sum{f in FABBRICHE}at[f,p,d] >= richiesteMinDepositi[p,d];
s.t. VRichiesteMaxDepositi{d in DEPOSITI}: sum{f in FABBRICHE,p in PRODOTTI}at[f,p,d] <= richiesteMaxDepositi[d];

#Questo vincolo lega la variabile c a quella at, permettendo così di definire per ogni fabbrica e deposito, il numero di camion necessari per trasportare tutto l'acciaio prodotto
#In particolare a variabile c è un intero e poichè a parità di acciaio, l'aumentare del numero di camion diminuisce il profitto, in automatico il numero sarà l'intero superiore risultante dalla divisione della somma(prodotto)/capienza(camion)
s.t. VUCamion{f in FABBRICHE,d in DEPOSITI}: sum{p in PRODOTTI}at[f,p,d] <= nc[f,d]*tonnellatePerCamion;

#Questo vincolo permette di legare la variabile logica mAcciaio alla variabile al
#Poichè all'aumentare mAcciaio provoca un costo maggiore, non si presenteranno valori spuri in quanto la variabile verrà posta in automatico a 0 quando possibile
s.t. VUmAcciaio{f in FABBRICHE,m in MACCHINE,t in TURNI,p in PRODOTTI}: al[f,m,t,p] <= bigM*mAcciaio[f,m,t,p];

#Questo vincolo permette di legare la variabile logica mAttive alla variabile mAcciaio
#Poichè all'aumentare mAttive provoca un costo maggiore, non si presenteranno valori spuri in quanto la variabile verrà posta in automatico a zero quando possibile
s.t. VUmAttive{f in FABBRICHE,m in MACCHINE,t in TURNI}: sum{p in PRODOTTI}mAcciaio[f,m,t,p] <= bigM*mAttive[f,m,t];

#Questo vincolo permette di legare la variabile logica mImpostate alla variabile logica mAcciaio.
#Data una fabbrica, una macchina e un prodotto, la macchina risulta impostata su tale lavorazione se e solo se non ha lavorato altri prodotti in tutta la giornata.
#Poichè impostare una macchina induce ad eseguire meno cicli di pulizia, e dunque ad un minor costo, la funzione obbiettivo farà si che non si verifichino valori spuri, e imposterà ad 1 la variabile logica mImpostate quando possibile
s.t. VUmImpostate{f in FABBRICHE,m in MACCHINE,p in PRODOTTI}:  sum{t in TURNI,pp in PRODOTTI:pp <> p}mAcciaio[f,m,t,pp] <= bigM*(mImpostate[f,m,p] + 1 - 2*mImpostate[f,m,p]) ;

#Questo vincolo fa si di limitare il problema delle macchine da impostare, imponendo dei vincoli esterni su esso
s.t. VmImpostateObbligatorie{f in FABBRICHE,m in MACCHINE,p in PRODOTTI}:mImpostate[f,m,p] >= mImpostateObbligatorie[f,m,p];

#Questo vincolo da si che data una fabbrica e una macchina, la variabile logica mImpostate possa risultare 1 solo su un unico prodotto.
s.t. VCmImpostate{f in FABBRICHE,m in MACCHINE}: sum{p in PRODOTTI}mImpostate[f,m,p] <= 1;

 
