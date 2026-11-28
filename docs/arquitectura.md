# Arquitectura

Clean Architecture con MVVM, igual que DrawPad
([ADR 0003](adr/0003-clean-architecture-mvvm.md)).

## Capas

```mermaid
flowchart TB
    subgraph App
        AC[AppContainer<br/>composition root]
    end
    subgraph Presentation
        PS[ProfilesScreen] --> PVM[ProfilesViewModel]
        PF[ProfileScreen] --> PFVM[ProfileViewModel]
        SC[SeatCalibrationScreen] --> SCVM[SeatCalibrationViewModel]
        SK[SeatCheckScreen] --> SKVM[SeatCheckViewModel]
        HC[HeadCalibrationScreen] --> HCVM[HeadCalibrationViewModel]
        HK[HeadCheckScreen] --> HKVM[HeadCheckViewModel]
        SS{{SeatScanner}}
        HT{{HeadTracker}}
        OV[AROverlay]
        ARS[ARKitSeatScanner<br/>cámara trasera] -.implementa.-> SS
        ART[ARKitHeadTracker<br/>cámara frontal] -.implementa.-> HT
        SCVM & SKVM --> SS
        SKVM --> OV
        HCVM & HKVM --> HT
    end
    subgraph Domain
        UC[Casos de uso]
        CF[CarFrame / SeatPosition]
        SE[SeatEvaluator / AimSmoother]
        HE[PostureGeometry / HeadEvaluator]
        PR{{ProfileRepository}}
        UC --> PR & SE & HE
    end
    subgraph Data
        SD[SwiftDataProfileRepository] -.implementa.-> PR
        REC[(ProfileRecord)]
        SD --> REC
    end
    AC --> PVM & PFVM & SCVM & SKVM & HCVM & HKVM & SD & ARS & ART
    PVM & PFVM & SCVM & SKVM & HCVM & HKVM --> UC
    SCVM & SKVM --> CF
    ART --> HE
```

| Capa | Importa | Contiene |
| ---- | ------- | -------- |
| Domain | `Foundation` | `Vector3`, `CarFrame`, `SeatLandmark`, `SeatPosition`, `SeatTolerance`, `CushionCheck`/`BackrestCheck`, `PostureSample`/`PostureMeasurement`, `HeadTolerance`, `HeadEvaluation`, `Adjustment`, `DrivingProfile`, `PositionError`, servicios (`SeatEvaluator`, `AimSmoother`, `PostureGeometry`, `HeadEvaluator`), `ProfileRepository`, casos de uso. |
| Data | `SwiftData` | `ProfileRecord`, `SwiftDataProfileRepository`. |
| Presentation | `SwiftUI`; `ARKit`/`SceneKit` solo en dos archivos | Pantallas, ViewModel, `SeatScanner`, `HeadTracker`, `AROverlay`, adaptadores de ARKit y simulados. |
| App | todo | `AppContainer`, `CarPositionApp`. |

## Navegación

```mermaid
flowchart LR
    L[Lista de posiciones] -->|+| SC[Nueva posición<br/>cámara trasera]
    L --> P[Ficha de la posición]
    P --> SK[Ajustar asiento<br/>guía AR]
    P --> HC[Calibrar con mi cara]
    P --> HK[Comprobar con mi cara]
```

Ninguna pantalla con cámara abre otra con cámara: así nunca hay dos sesiones
de ARKit a la vez.

## Secuencia: guía del asiento

```mermaid
sequenceDiagram
    autonumber
    actor U as Conductor
    participant S as SeatCheckScreen
    participant VM as SeatCheckViewModel
    participant AR as ARKitSeatScanner
    participant UC as CheckSeatUseCase

    S->>VM: onAppear()
    VM->>AR: onAim = receive, start()
    loop cada fotograma
        AR-->>VM: receive(punto bajo la mira)
        VM->>VM: AimSmoother (mediana)
    end
    U->>S: Marcar (umbral trasero)
    U->>S: Marcar (umbral delantero)
    VM->>VM: CarFrame(umbral)
    VM->>AR: show(AROverlay: umbral + asiento ideal)
    loop fase cojín, ~10 por segundo
        AR-->>VM: receive(punto en el cojín)
        VM->>UC: cushion(frame.local(punto), profile)
        UC-->>VM: CushionCheck
        VM->>AR: show(barra hasta la bola verde)
        VM-->>S: "Adelanta el asiento unos 3 cm"
    end
    U->>S: Siguiente, Marcar (respaldo bajo)
    loop fase respaldo
        AR-->>VM: receive(punto alto del respaldo)
        VM->>UC: backrest(bajo, alto, profile)
        VM->>AR: show(barra actual, barra ideal, arco)
        VM-->>S: "Endereza el respaldo unos 4°"
    end
```

## Pruebas

| Qué | Dónde | Cómo |
| --- | ----- | ---- |
| `CarFrame`, ángulos, evaluadores, mediana | `CarPositionTests/Domain` | Números a mano, incluido otro origen de ARKit y el auto en pendiente. |
| Casos de uso | `CarPositionTests/Domain/UseCasesTests` | `InMemoryProfileRepository`. |
| ViewModel | `CarPositionTests/Presentation` | `FakeSeatScanner.aim(at:)` y `FakeHeadTracker.emit(_:)`; se comprueba también el `AROverlay`. |
| Flujo completo | `CarPositionUITests` | App real con `-uiTesting` (cámaras simuladas). |
| ARKit y SceneKit reales | — | A mano, en el auto. |
