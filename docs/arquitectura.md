# Arquitectura

Clean Architecture con MVVM, igual que DrawPad
([ADR 0003](adr/0003-clean-architecture-mvvm.md)).

## Capas

```mermaid
flowchart TB
    subgraph App
        AC[AppContainer<br/>composition root]
        CPA[CarPositionApp]
    end
    subgraph Presentation
        PS[ProfilesScreen] --> PVM[ProfilesViewModel]
        CS[CalibrationScreen] --> CVM[CalibrationViewModel]
        KS[CheckScreen] --> KVM[CheckViewModel]
        HT{{HeadTracker}}
        CPS{{CameraPreviewSource}}
        ARK[ARKitHeadTracker] -.implementa.-> HT
        ARK -.implementa.-> CPS
        SIM[SimulatedHeadTracker] -.implementa.-> HT
        CVM --> HT
        KVM --> HT
    end
    subgraph Domain
        UC[Casos de uso]
        PG[PostureGeometry]
        PE[PositionEvaluator]
        PR{{ProfileRepository}}
        UC --> PR
        UC --> PE
    end
    subgraph Data
        SD[SwiftDataProfileRepository] -.implementa.-> PR
        REC[(ProfileRecord)]
        SD --> REC
    end
    AC --> PVM & CVM & KVM & SD & ARK & SIM
    PVM & CVM & KVM --> UC
    ARK --> PG
```

Las flechas solo van hacia dentro: `Domain` no conoce a nadie; `Data` y
`Presentation` conocen el dominio; solo `App` conoce todas las capas.

| Capa | Importa | Contiene |
| ---- | ------- | -------- |
| Domain | `Foundation` | `Vector3`, `PostureSample`, `PostureMeasurement`, `DrivingProfile`, `Tolerance`, `PositionEvaluation`/`Adjustment`, `PositionError`, `PostureGeometry`, `PositionEvaluator`, `ProfileRepository`, casos de uso. |
| Data | `SwiftData` | `ProfileRecord`, `SwiftDataProfileRepository`. |
| Presentation | `SwiftUI`, `ARKit` (solo un archivo) | Pantallas, ViewModel, `HeadTracker`, `ARKitHeadTracker`, `SimulatedHeadTracker`, `CameraPreview`. |
| App | todo | `AppContainer`, `CarPositionApp`. |

## Clases principales

```mermaid
classDiagram
    class HeadTracker {
        <<protocol>>
        +isSupported: Bool
        +onSample: (PostureSample?) -> Void
        +start()
        +stop()
    }
    class CalibrationViewModel {
        +name: String
        +notes: String
        +phase: Phase
        +isFaceDetected: Bool
        +startCapture()
        +cancelCapture()
        +receive(PostureSample?)
    }
    class CheckViewModel {
        +profile: DrivingProfile?
        +evaluation: PositionEvaluation?
        +receive(PostureSample?)
        +saveCurrentAsReference()
        +saveDetails(name, notes)
    }
    class PostureMeasurement {
        +depth: Double
        +height: Double
        +lateral: Double
        +deviceGravity: Vector3
        +init?(samples)
    }
    class DrivingProfile {
        +id: UUID
        +name: String
        +notes: String
        +reference: PostureMeasurement
    }
    class PositionEvaluator {
        +tolerance: Tolerance
        +evaluate(current, reference) PositionEvaluation
    }
    CalibrationViewModel --> HeadTracker
    CheckViewModel --> HeadTracker
    CalibrationViewModel --> CreateProfileUseCase
    CheckViewModel --> EvaluatePositionUseCase
    CheckViewModel --> UpdateReferenceUseCase
    EvaluatePositionUseCase --> PositionEvaluator
    DrivingProfile --> PostureMeasurement
```

## Secuencia: calibrar

```mermaid
sequenceDiagram
    autonumber
    actor U as Conductor
    participant S as CalibrationScreen
    participant VM as CalibrationViewModel
    participant T as ARKitHeadTracker
    participant UC as CreateProfileUseCase
    participant R as SwiftDataProfileRepository

    S->>VM: onAppear()
    VM->>T: onSample = receive, start()
    loop ~60 por segundo
        T-->>VM: receive(sample o nil)
        VM-->>S: isFaceDetected, distancia
    end
    U->>S: Calibrar
    S->>VM: startCapture()
    VM-->>S: countdown 3, 2, 1
    VM-->>S: capturing(progress)
    loop hasta 90 fotogramas con cara
        T-->>VM: receive(sample)
    end
    VM->>VM: PostureMeasurement(samples) (mediana)
    VM->>UC: execute(name, notes, reference)
    UC->>R: save(profile)
    VM-->>S: phase = saved
    S->>S: dismiss()
    S->>VM: onDisappear() → stop()
```

## Secuencia: comprobar

```mermaid
sequenceDiagram
    autonumber
    actor U as Conductor
    participant S as CheckScreen
    participant VM as CheckViewModel
    participant T as ARKitHeadTracker
    participant E as EvaluatePositionUseCase

    S->>VM: onAppear()
    VM->>VM: loadProfile
    VM->>T: start()
    loop cada fotograma
        T-->>VM: receive(sample)
        VM->>VM: ventana de 30 → mediana
        opt cada 6 fotogramas
            VM->>E: execute(current, profile)
            E-->>VM: PositionEvaluation
            VM-->>S: "Adelanta el asiento unos 3 cm"
        end
    end
    U->>U: mueve la palanca del asiento
    T-->>VM: receive(sample)…
    VM-->>S: "Todo en su sitio"
```

## Pruebas

| Qué | Dónde | Cómo |
| --- | ----- | ---- |
| Geometría, mediana, evaluación | `CarPositionTests/Domain` | Números a mano. |
| Casos de uso | `CarPositionTests/Domain/UseCasesTests` | `InMemoryProfileRepository`. |
| ViewModel | `CarPositionTests/Presentation` | `FakeHeadTracker.emit(...)` simula fotogramas. |
| Flujo completo | `CarPositionUITests` | App real con `-uiTesting` (cámara simulada). |
| ARKit real | — | A mano, en el auto. |
