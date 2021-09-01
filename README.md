# AdfsToolkit-IDEM

ADFS Toolkit per la federazione Italiana IDEM di GARR 

Questo modulo powershell gestisce l'importazione in Microsoft ADFS di metadata di federazioni SAML 2.0 ed è esplicitamente pensato per l'utilizzo di un server ADFS come Identity provider per la Federazione IDEM di GARR.
Si tratta di una versione modificata di [AdfsToolkit](https://github.com/fedtools/adfstoolkit) e agli autori di questo progetto va tutto il merito per l'ottimo lavoro svolto.

La versione attuale di AdfsToolkit-IDEM è basata sul codice della versione 1.0.0.0 di AdfsToolkit. Nella loro versione attuale (2.0.1) molte cose sono cambiate, ma praticamente tutte le modifiche necessarie al funzionamento secondo le prescrizioni di IDEM sono ancora necessarie.  
E' in valutazione la riscrittura di una nova versione di questo modulo basato su AdfsToolkit v2, ma al momento non c'è una data prevista.

# Installazione ed utilizzo
E' necessario scaricare il codice del modulo e copiarlo nella cartella *c:\Program Files\WindowsPowerShell\Modules\ADFSToolkit-IDEM\\* di uno dei server ADFS.   
**TODO**: caricare il modulo su PSGallery

Da una sessione powershell da amministratore eseguire:
```
Import-module adfstoolkit-idem 
New-ADFSTkConfiguration
```
La procedura guidata creerà automaticamente la cartella *c:\ADFSToolkit-IDEM\\* e al suo interno il file di configurazione, lo script da eseguire e tutto quanto necessario ed eventualmente creerà anche una entry nel Task Scheduler per l'esecuzione ripetuta (che però va attivato manualmente).

# Caratteristiche principali
Per il funzionamento di base del modulo fare riferimento alla documentazione di [AdfsToolkit v1](https://github.com/fedtools/adfstoolkit/tree/ADFSToolkit-1.0.0.0). Di seguito vengono riportate le principali modifiche e aggiunte rispetto a questo.

### Rilascio degli attributi
Il modulo gestisce solo gli attributi obbligatori e raccomandati della federazione IDEM. Inoltre, rilascia agli SP solo gli attributi esplicitamente indicati come obbligatori nel metadata.
Viene rilasciato sempre l'attributo **eduPersonScopedAffiliation** e un NameID (vedi punto successivo).

### NameID 
Se il SP richiede nel subject dell’asserzione come prima entry il NameID:persistent viene utilizzato questo, in tutti gli altri casi viene rilasciato il NameID:transient.  
Il NameID:persistent è calcolato a partire dal SID dell'utente, ma utilizza anche un altro attributo che normalmente dovrebbe essere vuoto per tutti gli utenti: nel caso ci fosse la necessità di modificare il valore generato per un utente (ad esempio in caso di furto di identità) sarebbe sufficiente valorizzare questo attributo ad un qualsiasi valore non nullo.  
Nella configurazione di default viene utilizzato a questo scopo l'attributo Active Directory "extensionAttribute15".  
L'eduPersonTargetedID viene trattato come un normale attributo e rilasciato solo se esplicitamente richiesto.

### Entity Category
Lo script supporta la entity-category "REFEDS Research and Scholarship (R&S)": se un SP la dichiara nel metadata, vengono automaticamente rilasciati gli attributi previsti (eduPersonPrincipalName, mail, displayName, givenName, sn).

Con l'attuale politica, che limita il rilascio degli attributi solo a quelli esplicitamente richiesti, potrebbe rispettare anche quanto previsto da "GÉANT Data Protection Code of Conduct (CoCo)", ma questo richiede ulteriori verifiche.

### Personalizzazione pagina di Login
Nella pagina di accesso viene sempre visualizzato il nome dell'SP a cui si sta accedendo con il messaggio "Accedi a" in italiano oppure "Login to" in inglese.  
Nella configurazione è possibile definire del codice HTML da aggiungere, sempre in doppia lingua. All'interno di questo codice è possibile utilizzare dei tag specifici ed in particolare:
* **[ReplaceWithDESCRIPTION]** : viene sostituito con la descrizione del SP riportata nel metadata (sempre in italiano e in inglese)
* **[ReplaceWithATTRIBUTELIST]** : viene sostituito con l'elenco degli attributi che verranno rilasciati al login

Modificare la pagina di accesso è necessario per rispettare quanto previsto dalle specifiche tecniche di IDEM, in particolare la presenza del logo della federazione, i link alla politica sulla privacy, al supporto, ecc.  
Inoltre, ADFS non prevede una pagina di consenso per l'invio dei dati dopo il login, per questo è utile presentare prima l'elenco degli attributi che verranno inviati.

Lo script prevede anche la possibilità di impostare un tema specifico a tutti gli SP di una federazione, ma **ATTENZIONE!!** questa opzione non va assolutamente utilizzata per le federazioni IDEM o EduGAIN: per come funziona ADFS, quando ad un singolo SP viene assegnato un tema, tutti gli elementi di questo (comprese le immagini) vengono duplicate e riscritte nella configurazione dell'SP stesso. Applicare lo stesso tema a centinaia di SP (o migliaia in caso di EduGain) farebbe esplodere la dimensione del database di configurazione in modo pericoloso e assolutamente inutile.  
L'opzione resta disponibile solo per l'eventuale utilizzo con altre federazioni con numeri decisamente più ristretti.

### Gruppi Opt-IN e Opt-OUT
E' possibile limitare l'accesso alle risorse federate utilizzando specifici gruppi:
* se viene definito in configurazione il valore **optInGroup** solo gli utenti membri di questo gruppo avranno accesso
* se viene definito in configurazione il valore **optOutGroup** ai membri di questo gruppo verrà sempre negato l'accesso

Nella configurazione va sempre indicato il SID dei gruppi e vengono correttamente gestiti i "nested group"
 
### Parametro ForceUpdate
Il parametro --ForceUpdate del comando Import-ADFSTkMetadata ha un funzionamento leggermente diverso dalla versione originale.  
Quando nel metadata viene trovatu un SP nuovo o modificato rispetto all'esecuzione precedente, viene verificata l'esistenza dell'entityID nel database ADFS:
* Se l'entityID non è presente, il RelyingPartyTrust corrispondente viene creato.
* Se l'entityID è presente e il nome del RelyingPartyTrust inizia con il prefisso dell'aggregato, questo viene aggiornato con le configurazioni attuali.
* Se l'entityID è presente, il nome del RelyingPartyTrust non inizia con il prefisso dell'aggregato ma è passato il parametro --ForceUpdate, il RelyingPartyTrust viene aggiornato con le configurazioni attuali.
* Se l'entityID è presente, il nome del RelyingPartyTrust non inizia con il prefisso dell'aggregato e non viene passato il parametro --ForceUpdate, il RelyingPartyTrust non viene modificato.

Il parametro --ForceUpdate è utilizzato di default, per garantire la maggiore aderenza possibile alle configurazioni presenti nei metadata. Rimuoverlo può essere utile se si intende definire manualmente un RelyingPartyTrust per una delle entityID presenti nel metadata per evitare che questo venga sovrasctritto.  
Il parametro --AddRemoveOnly disponibile in adfstoolkit non è più utilizzato.


# Requisiti
Il codice è stato utilizzato solo *Windows Server 2019 AD FS*. Dovrebbe funzionare correttamente anche sulla versione 2016, ma non è mai stato testato.  
L'installazione standard di ADFS basata su *Windows Internal Database* (WID) supporta fino ad un massimo di 100 RelyingPartyTrust: per usarlo con la federazione IDEM (e ancor più con EduGAIN) è necessario l'utilizzo di un database SQL Server esterno.  
Per girare richiede almeno Powershell 5.1, ma questa è di default su Server 2019.  
Per poter modificare la configurazione deve essere necessariamente eseguito su uno dei server ADFS e con i privilegi di amministratore.  

# Note
### Configurazione per EduGAIN
Il modo più semplice per l'adesione a EduGAIN è utilizzare una sola configurazione per importare il metadata **edugain2idem-metadata-sha256.xml**.  
Qualora però si volessero distinguere i RelyingPartyTrust che afferiscono ad IDEM da quelli di EduGAIN, è possibile:
* Attivare una configurazione per IDEM che importa il metadata **idem-metadata-sha256.xml**
* Attivare una seconda configurazione per il metadata **edugain2idem-metadata-sha256.xml** e utilizzare in questa l'opzione **SPHashFileToExclude** per escludere le entityID già trattate dalla prima  

In questo modo è possibile, ad esempio, utilizzare codice HTML diverso nelle due configurazioni per includere nella seconda il logo di EduGAIN insieme a quello di IDEM.  
Inoltre, aiuta a distingure a colpo d'occhio la provenienza di un RelyingPartyTrust grazie ad un prefisso diverso.

### Erasmus Plus e ESI
Per l'accesso ai servizi Erasmus Plus è necessario il rilascio dello **European Student Identifier** attraverso l'attributo **schacPersonalUniqueCode** ([riferimenti](https://wiki.idem.garr.it/wiki/Erasmus_Plus_e_ESI)).  
Lo script è in grado di generare questo attributo utilizzando nel campo "code" un valore presente in ActiveDirectory (nella configurazione di default è utilizzato "employeeID").  
Siccome, però, questo attributo non è definito tra quelli di IDEM e tenendo conto che si tratta di una valorizzazione molto specifica, non è stato aggiunto agli attributi riconosciuti e rilasciati di default a tutti gli SP che lo richiedono.  
Per rilasciarlo al proxy MyAcademicID, è necessario inserire una regola specifica nel file *get-ADFSTkLocalManualSpSettings.ps1*

# Contatti
Per ogni informazione, commento o suggerimento in merito a questo modulo è possibile contattare l'autore Fabrizio Carusi (fabrizio.carusi@univaq.it).  
  
  
