# PALINOPSIA — Live Electronics per violoncello
SuperCollider patch per violoncello ed elettronica in tempo reale

Questo progetto è pensato per l’esecuzione dal vivo.
Il codice è separato in due livelli distinti:

1) ENGINE  
   Tutta la logica tecnica: synth, routing, buffer, bus, funzioni on/off, controlli.
2) SCORE (PARTITURA)  
   La partitura elettronica vera e propria: scene, cue, routine e settaggi dei parametri,
   da attivare manualmente durante l’esecuzione.

Il musicista apre i file, li esegue uno alla volta, e durante il brano lancia
manualmente i vari blocchi della partitura.

------------------------------------------------------------
REQUISITI
------------------------------------------------------------
- SuperCollider (versione recente consigliata)
- Interfaccia audio funzionante
- Microfono per violoncello
- Livelli di ingresso correttamente regolati

------------------------------------------------------------
STRUTTURA DEI FILE 
------------------------------------------------------------

10_setup.scd
- Avvio del server
- Creazione di bus audio e di controllo
- Creazione dei buffer
- Creazione dei gruppi (mic, fx, rec, ecc.)

20_defs_load.scd
- Caricamento di tutti i SynthDef

30_engine.scd
- Funzioni di performance (strumento elettronico)
- Accensione/spegnimento dei moduli
- Funzioni di registrazione
- Funzioni di controllo dei parametri 
- Selezione dei buffer
- GUI e/o keymap

40_score.scd
- Partitura elettronica
- Cue e scene musicali
- Routine temporali
- Solo istruzioni musicali, nessuna logica di sistema

IMPORTANTE:
I file vanno eseguiti in QUESTO ORDINE.

------------------------------------------------------------
PROCEDURA DI AVVIO (PRIMA DEL CONCERTO)
------------------------------------------------------------

1) Aprire SuperCollider
2) Aprire ed eseguire nell’ordine:

   - Apri 10_setup.scd
     → seleziona tutto o il blocco principale
     → premi Run

   - Apri 20_defs_load.scd
     → premi Run

   - Apri 30_engine.scd
     → premi Run

   - Apri 40_score.scd

A questo punto:
- Il server è attivo
- I SynthDef sono caricati
- Tutte le funzioni dell’engine sono disponibili
- La partitura è pronta per essere usata

------------------------------------------------------------
CONCETTI BASE
------------------------------------------------------------

ENGINE = STRUMENTO
Lo strumento elettronico mette a disposizione funzioni del tipo:

- ~grainOn.() / ~grainOff.()
- ~sliceOn.() / ~sliceOff.()
- ~harmOn.() / ~harmOff.()
- ~ringOn.() / ~ringOff.()
- ~delayOn.(\echo | \fbk | \pingpong | \vardel)
- ~delayOff.()
- ~fshiftOn.(...) / ~fshiftOff.()
- ~recStart.(\replace | \sum)
- ~recStop.()
- ~useSlice.(n)

e funzioni di controllo parametri tramite bus:

- ~grainCtrl.(\param, type: ..., val / freq / range)
- ~sliceCtrl.(\param, type: ..., val / freq / range)
- ~ringCtrl.(...)
- ~delayCtrl.(...)

NOTA IMPORTANTE:
Ogni chiamata ctrl controlla UN SOLO parametro.
Esempio corretto:

~grainCtrl.(\amp, type: -1, val: 1);
~grainCtrl.(\trsp, type: -1, val: -4);

------------------------------------------------------------
SCORE = PARTITURA ELETTRONICA
------------------------------------------------------------

Nel file 40_score.scd ci sono solo:
- blocchi di comandi
- cue
- scene
- routine temporali

Il musicista NON modifica l’engine durante il concerto,
ma lavora quasi esclusivamente nello score.

------------------------------------------------------------
MODALITÀ DI ESECUZIONE DURANTE IL BRANO
------------------------------------------------------------

MODALITÀ 1 — Blocchi manuali
Nel file score trovi blocchi come:

(
~sliceOn.();
~sliceCtrl.(\wait, type: -1, val: 0.05);
~sliceCtrl.(\dur,  type: -1, val: 0.3);
)

Durante l’esecuzione:
- seleziona il blocco
- premi Run
- il gesto elettronico entra immediatamente

------------------------------------------------------------

MODALITÀ 2 — Cue nominati 
Nel file score possono essere definiti cue come funzioni:

~cue = IdentityDictionary.new;

~cue[\A1] = {
  ~useSlice.(0);
  ~sliceOn.();
  ~sliceCtrl.(\wait, type: -1, val: 0.05);
};

~cue[\A2] = {
  ~sliceCtrl.(\wait, type: -1, val: 0.5);
};

Durante il concerto il musicista lancia semplicemente:

~cue[\A1].();
~cue[\A2].();

------------------------------------------------------------

MODALITÀ 3 — Routine automatiche
Per processi graduali:

~sliceChaosToPulses.(bufIndex: 0, totalDur: 30);

Il musicista lancia UNA riga,
la trasformazione avviene automaticamente nel tempo.

------------------------------------------------------------
NOTE OPERATIVE
------------------------------------------------------------

- Tenere aperti TUTTI i file in tab separati
- Durante il concerto lavorare solo su 40_score.scd
- Non modificare l’engine dal vivo
- Testare sempre livelli e carico CPU in prova

------------------------------------------------------------
FINE
------------------------------------------------------------
