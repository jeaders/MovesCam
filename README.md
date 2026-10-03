# MovesCam

**MovesCam** è un'app macOS nativa che trasforma la tua webcam in una tela da disegno: usa le mani per disegnare a schermo senza toccare il Mac.

![macOS](https://img.shields.io/badge/macOS-12.0%2B-blue)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0%2B-orange)
![Vision](https://img.shields.io/badge/Vision-Hand%20Tracking-red)

---

## Come funziona

L'app usa la webcam per rilevare la posizione della tua mano in tempo reale. Il dito indice funziona da "pennello":

- **Mano aperta** → disegna
- **Pugno chiuso** → smetti di disegnare
- **Nessuna mano** → nessun disegno

Puoi cambiare colore e spessore del pennello, visualizzare o nascondere l'anteprima della camera, e cancellare il disegno quando vuoi.

---

## Installazione

### 1. Installa Xcode

Xcode è il tool ufficiale Apple per sviluppare app macOS. Ecco come installarlo:

1. Apri l'**App Store** sul tuo Mac
2. Cerca **Xcode**
3. Clicca **Installa** (oppure **Aggiorna** se già installato)
4. Al termine, apri Xcode una volta per completare l'installazione dei componenti aggiuntivi

> **Requisito minimo:** macOS 12.0 (Monterey) o superiore.

### 2. Crea il progetto in Xcode

1. Apri Xcode
2. Scegli **File > New > Project**
3. Seleziona **macOS > App** e clicca **Next**
4. Compila:
   - **Product Name:** `MovesCam`
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - **Storage:** `None`
5. Scegli la cartella di salvataggio e crea il progetto

### 3. Sostituisci i file

Sostituisci i file generati da Xcode con quelli di questa repository:

- `MovesCam/MovesCamApp.swift`
- `MovesCam/ContentView.swift`
- `MovesCam/CameraManager.swift`
- `MovesCam/HandTrackingManager.swift`
- `MovesCam/DrawingCanvas.swift`
- `MovesCam/Resources/Info.plist`

Inoltre aggiungi la cartella `MovesCam/Resources/Assets.xcassets` al progetto (trascinala nel navigatore di Xcode).

### 4. Abilita i permessi

L'app richiede l'accesso alla fotocamera. In Xcode:

1. Seleziona il progetto nel navigatore
2. Scheda **Signing & Capabilities**
3. Aggiungi la chiave `NSCameraUsageDescription` in **Info.plist** con una descrizione come:
   > "MovesCam needs access to the camera for hand tracking and drawing with gestures."

Se hai usato l'`Info.plist` fornito, è già configurato.

### 5. Build e Run

 Premi **⌘R** oppure **Product > Run**. L'app si aprirà e potrai iniziare a disegnare con le mani.

---

## Uso

1. Clicca **Start Camera** per attivare la webcam
2. Mostra la mano alla camera:
   - **Mano aperta** → disegna con l'indice
   - **Pugno chiuso** → interrompi il disegno
3. Usa i controlli in alto per:
   - Mostrare/nascondere l'anteprima della camera
   - Cambiare colore del pennello
   - Regolare lo spessore
   - Cancellare il disegno

---

## Tecnologie

- **SwiftUI** — Interfaccia utente
- **AVFoundation** — Accesso alla webcam
- **Vision** — Rilevamento della mano (`VNDetectHumanHandPoseRequest`)
- **Core Image** — Elaborazione frame video
- **Core Video** — Gestione pixel buffer

---

## Troubleshooting

- **Camera non si attiva:** Verifica che nessun'altra app stia usando la webcam. Controlla in **System Preferences > Security & Privacy > Camera** che Xcode abbia i permessi.
- **Mano non rilevata:** Usa una mano alla volta, con buona illuminazione, e tienila a 30-60 cm dalla webcam.
- **Disegno tremolante:** Assicurati che la mano sia ben visibile e non ci siano ombre forti.
- **Performance basse:** Chiudi altre app che usano la GPU. Su Mac con Apple Silicon le prestazioni sono migliori.

---

## Struttura del progetto

```
MovesCam/
├── MovesCam/
│   ├── Sources/
│   │   ├── MovesCamApp.swift          # Entry point
│   │   ├── ContentView.swift          # Vista principale e logica disegno
│   │   ├── CameraManager.swift        # Cattura frame dalla webcam
│   │   ├── HandTrackingManager.swift  # Rilevamento mani con Vision
│   │   └── DrawingCanvas.swift        # Modello percorso di disegno
│   └── Resources/
│       ├── Info.plist                 # Permessi e configurazione app
│       └── Assets.xcassets/           # Icona app (placeholder)
└── README.md
```

---

## Licenza

MIT
