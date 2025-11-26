# Architecture Overview

This document provides a comprehensive overview of the Reels SDK architecture, design patterns, and key architectural decisions.

## High-Level Architecture

```mermaid
graph TB
    subgraph "Native Layer"
        subgraph "iOS App"
            IOS_APP[iOS Application]
            IOS_COORDINATOR[App Coordinators]
        end

        subgraph "Android App"
            ANDROID_APP[Android Application]
            ANDROID_ACTIVITIES[Activities/Fragments]
        end
    end

    subgraph "Native Bridges"
        subgraph "reels_ios"
            IOS_MODULE[ReelsModule]
            IOS_ENGINE[ReelsEngineManager]
            IOS_PIGEON[ReelsPigeonHandler]
        end

        subgraph "reels_android"
            ANDROID_MODULE[ReelsModule]
            ANDROID_ENGINE[FlutterEngineManager]
            ANDROID_PIGEON[FlutterMethodChannelHandler]
        end
    end

    subgraph "Platform Communication"
        PIGEON[Pigeon<br/>Type-Safe Channels]
    end

    subgraph "Flutter Core (reels_flutter)"
        subgraph "Presentation"
            SCREENS[Screens]
            WIDGETS[Widgets]
            PROVIDERS[State Providers]
        end

        subgraph "Domain"
            ENTITIES[Entities]
            USECASES[Use Cases]
            REPO_INTERFACES[Repository Interfaces]
        end

        subgraph "Data"
            DATASOURCES[Data Sources]
            MODELS[Models]
            REPO_IMPL[Repository Implementations]
        end

        subgraph "Core"
            DI[Dependency Injection<br/>GetIt]
            SERVICES[Platform Services]
            PIGEON_GEN[Pigeon Generated]
        end
    end

    IOS_APP --> IOS_COORDINATOR
    IOS_COORDINATOR --> IOS_MODULE
    ANDROID_APP --> ANDROID_ACTIVITIES
    ANDROID_ACTIVITIES --> ANDROID_MODULE

    IOS_MODULE --> IOS_ENGINE
    IOS_ENGINE --> IOS_PIGEON
    ANDROID_MODULE --> ANDROID_ENGINE
    ANDROID_ENGINE --> ANDROID_PIGEON

    IOS_PIGEON <--> PIGEON
    ANDROID_PIGEON <--> PIGEON

    PIGEON <--> SERVICES
    SERVICES --> PIGEON_GEN

    SCREENS --> PROVIDERS
    PROVIDERS --> USECASES
    USECASES --> REPO_INTERFACES
    REPO_INTERFACES --> REPO_IMPL
    REPO_IMPL --> DATASOURCES
    REPO_IMPL --> MODELS

    DI --> USECASES
    DI --> REPO_IMPL
    DI --> SERVICES

    style IOS_APP fill:#87CEEB
    style ANDROID_APP fill:#90EE90
    style IOS_MODULE fill:#FFB6C1
    style ANDROID_MODULE fill:#FFD700
    style PIGEON fill:#FFA500
    style SCREENS fill:#FFB6C1
    style USECASES fill:#87CEEB
    style REPO_IMPL fill:#90EE90
```

## Architectural Patterns

### 1. Clean Architecture

The Flutter core follows Clean Architecture principles with clear layer separation:

```mermaid
graph LR
    subgraph "Outer Layer"
        UI[UI/Presentation]
        FRAMEWORK[Framework & Drivers]
    end

    subgraph "Middle Layer"
        CONTROLLERS[Interface Adapters<br/>Providers, Services]
    end

    subgraph "Inner Layer"
        USECASES[Application Business Rules<br/>Use Cases]
        ENTITIES[Enterprise Business Rules<br/>Entities]
    end

    UI --> CONTROLLERS
    FRAMEWORK --> CONTROLLERS
    CONTROLLERS --> USECASES
    USECASES --> ENTITIES

    style ENTITIES fill:#FFB6C1
    style USECASES fill:#87CEEB
    style CONTROLLERS fill:#FFD700
    style UI fill:#90EE90
```

**Benefits:**
- Clear separation of concerns
- Testable business logic
- Independent of frameworks
- Database/UI agnostic

### 2. Add-to-App Pattern

Flutter's Add-to-App pattern enables integration into existing native apps:

```mermaid
graph TB
    NATIVE[Native App<br/>Existing Codebase]

    subgraph "Flutter Module"
        FLUTTER_CODE[Flutter Code<br/>Shared Logic]
        FLUTTER_ENGINE[Flutter Engine]
    end

    subgraph "Native Integration"
        FLUTTER_VIEW[FlutterViewController<br/>iOS]
        FLUTTER_ACTIVITY[FlutterActivity<br/>Android]
    end

    NATIVE --> FLUTTER_VIEW
    NATIVE --> FLUTTER_ACTIVITY

    FLUTTER_VIEW --> FLUTTER_ENGINE
    FLUTTER_ACTIVITY --> FLUTTER_ENGINE

    FLUTTER_ENGINE --> FLUTTER_CODE

    style NATIVE fill:#87CEEB
    style FLUTTER_CODE fill:#9370DB
    style FLUTTER_ENGINE fill:#FFA500
```

**Advantages:**
- Gradual migration
- Shared codebase across platforms
- Native performance
- Existing app integration

### 3. Coordinator Pattern (iOS)

iOS bridge uses the Coordinator pattern for navigation:

```mermaid
graph TB
    APP[App]

    subgraph "Host App Coordinators"
        FEED_COORD[FeedCoordinator]
        REELS_DETAIL_COORD[ReelsDetailCoordinator]
    end

    subgraph "SDK Coordinator"
        REELS_COORD[ReelsCoordinator<br/>Static Utility]
        DEFAULT_LISTENER[DefaultReelsListener]
        DELEGATE[ReelsCoordinatorDelegate]
    end

    subgraph "Flutter Integration"
        REELS_MODULE[ReelsModule]
        ENGINE_MGR[ReelsEngineManager]
    end

    APP --> FEED_COORD
    FEED_COORD --> REELS_DETAIL_COORD
    REELS_DETAIL_COORD --> REELS_COORD

    REELS_COORD --> DEFAULT_LISTENER
    REELS_COORD --> DELEGATE
    REELS_COORD --> REELS_MODULE

    REELS_MODULE --> ENGINE_MGR

    style APP fill:#87CEEB
    style FEED_COORD fill:#FFB6C1
    style REELS_COORD fill:#FFD700
    style REELS_MODULE fill:#9370DB
```

**Benefits:**
- Clean navigation flow
- Proper lifecycle management
- Follows iOS best practices
- Reusable navigation logic

### 4. Module Pattern (Android)

Android bridge uses a Singleton Module pattern:

```mermaid
graph TB
    APP[Android App]

    subgraph "Reels SDK"
        MODULE[ReelsModule<br/>Singleton]
        ENGINE_MGR[FlutterEngineManager<br/>Lifecycle Management]

        subgraph "Presentation"
            ACTIVITY[FlutterReelsActivity<br/>Full Screen]
            FRAGMENT[FlutterReelsFragment<br/>Embeddable]
        end

        subgraph "Communication"
            METHOD_HANDLER[FlutterMethodChannelHandler]
            PIGEON_GEN[PigeonGenerated]
        end
    end

    APP --> MODULE
    MODULE --> ENGINE_MGR
    MODULE --> ACTIVITY
    MODULE --> FRAGMENT

    ENGINE_MGR --> METHOD_HANDLER
    METHOD_HANDLER --> PIGEON_GEN

    style APP fill:#90EE90
    style MODULE fill:#FFD700
    style ENGINE_MGR fill:#FFA500
    style ACTIVITY fill:#87CEEB
```

**Benefits:**
- Simple API surface
- Centralized state
- Easy initialization
- Multiple presentation options

## Data Flow

### Request Flow (Native → Flutter)

```mermaid
sequenceDiagram
    participant Native as Native App
    participant Bridge as Native Bridge
    participant Pigeon as Pigeon
    participant Service as Platform Service
    participant UseCase as Use Case
    participant Repo as Repository

    Native->>Bridge: openReels()
    Bridge->>Pigeon: Initialize Flutter
    activate Pigeon

    Note over Service: Flutter initializes<br/>and needs data

    Service->>Pigeon: getAccessToken()
    Pigeon->>Bridge: Host API
    Bridge->>Native: accessTokenProvider()
    Native-->>Bridge: return token
    Bridge-->>Pigeon: return token
    Pigeon-->>Service: return token

    Service->>UseCase: getVideos(token)
    UseCase->>Repo: fetchVideos(token)
    Repo-->>UseCase: List<Video>
    UseCase-->>Service: List<VideoEntity>
    Service-->>Pigeon: Update UI

    deactivate Pigeon
```

### Event Flow (Flutter → Native)

```mermaid
sequenceDiagram
    participant UI as Flutter UI
    participant Provider as State Provider
    participant UseCase as Use Case
    participant Service as Platform Service
    participant Pigeon as Pigeon
    participant Bridge as Native Bridge
    participant Native as Native App

    UI->>Provider: User taps like
    Provider->>UseCase: toggleLike(videoId)
    UseCase->>Service: notifyLikeChanged()

    Service->>Pigeon: onLikeButtonClick()
    Pigeon->>Bridge: Flutter API
    Bridge->>Native: listener.onLikeButtonClick()

    Note over Native: Handle like<br/>Update backend

    Native-->>Bridge: Success
    Bridge-->>Pigeon: ACK
```

## Layer Responsibilities

### Presentation Layer

```mermaid
graph TB
    subgraph "Presentation Layer"
        SCREENS[Screens<br/>reels_screen.dart<br/>video_list_screen.dart]
        WIDGETS[Widgets<br/>video_player_widget.dart<br/>engagement_buttons.dart]
        PROVIDERS[Providers<br/>reels_provider.dart<br/>video_state_provider.dart]
    end

    SCREENS --> WIDGETS
    SCREENS --> PROVIDERS
    WIDGETS --> PROVIDERS

    PROVIDERS --> USECASES[Use Cases]

    style SCREENS fill:#FFB6C1
    style WIDGETS fill:#87CEEB
    style PROVIDERS fill:#FFD700
```

**Responsibilities:**
- Display UI
- Handle user input
- Manage UI state
- Trigger use cases
- No business logic

### Domain Layer

```mermaid
graph TB
    subgraph "Domain Layer"
        ENTITIES[Entities<br/>video_entity.dart<br/>user_entity.dart]
        USECASES[Use Cases<br/>get_videos.dart<br/>toggle_like.dart]
        REPOS[Repository Interfaces<br/>video_repository.dart]
    end

    USECASES --> ENTITIES
    USECASES --> REPOS

    style ENTITIES fill:#FFB6C1
    style USECASES fill:#87CEEB
    style REPOS fill:#FFD700
```

**Responsibilities:**
- Business logic
- Business entities
- Repository contracts
- Platform independent
- No framework dependencies

### Data Layer

```mermaid
graph TB
    subgraph "Data Layer"
        MODELS[Models<br/>video_model.dart<br/>user_model.dart]
        DATASOURCES[Data Sources<br/>local_data_source.dart<br/>mock_videos.json]
        REPO_IMPL[Repository Impl<br/>video_repository_impl.dart]
    end

    REPO_IMPL --> DATASOURCES
    REPO_IMPL --> MODELS
    DATASOURCES --> MODELS

    style MODELS fill:#FFB6C1
    style DATASOURCES fill:#87CEEB
    style REPO_IMPL fill:#FFD700
```

**Responsibilities:**
- Data retrieval
- Data transformation
- Repository implementation
- Data source abstraction
- Model mapping

### Core Layer

```mermaid
graph TB
    subgraph "Core Layer"
        DI[Dependency Injection<br/>service_locator.dart]
        SERVICES[Platform Services<br/>analytics_service.dart<br/>token_service.dart]
        PIGEON[Pigeon Generated<br/>pigeon_generated.dart]
    end

    SERVICES --> PIGEON
    DI --> SERVICES

    style DI fill:#FFB6C1
    style SERVICES fill:#87CEEB
    style PIGEON fill:#FFA500
```

**Responsibilities:**
- Service registration
- Platform communication
- Cross-cutting concerns
- Framework integration

## State Management

### Provider Architecture

```mermaid
graph TB
    UI[UI Widgets]

    subgraph "State Management"
        PROVIDER[ChangeNotifier Provider]
        STATE[State<br/>Videos, Current Index, etc.]
        NOTIFY[notifyListeners]
    end

    subgraph "Business Logic"
        USECASES[Use Cases]
    end

    UI -->|Listen| PROVIDER
    UI -->|User Action| PROVIDER
    PROVIDER --> STATE
    PROVIDER --> USECASES
    USECASES --> PROVIDER
    PROVIDER --> NOTIFY
    NOTIFY -->|Rebuild| UI

    style UI fill:#87CEEB
    style PROVIDER fill:#FFD700
    style USECASES fill:#90EE90
```

### Generation-Based State

See [Generation-Based State Management](./03-Generation-Based-State-Management.md) for details.

```mermaid
graph LR
    OPEN1[Open Reels<br/>Generation 1]
    CLOSE1[Close]
    OPEN2[Open Reels<br/>Generation 2]
    CLOSE2[Close]
    OPEN3[Open Reels<br/>Generation 3]

    OPEN1 --> CLOSE1
    CLOSE1 --> OPEN2
    OPEN2 --> CLOSE2
    CLOSE2 --> OPEN3

    subgraph "Each Generation"
        STATE[Independent State<br/>Cached Position<br/>Paused Videos]
    end

    OPEN1 -.-> STATE
    OPEN2 -.-> STATE
    OPEN3 -.-> STATE

    style OPEN1 fill:#FFB6C1
    style OPEN2 fill:#87CEEB
    style OPEN3 fill:#90EE90
```

## Engine Lifecycle

See [Flutter Engine Lifecycle](./02-Flutter-Engine-Lifecycle.md) for details.

```mermaid
stateDiagram-v2
    [*] --> NotInitialized
    NotInitialized --> Initializing: initialize()
    Initializing --> Ready: Engine Created
    Ready --> Running: openReels()
    Running --> Paused: pauseAll()
    Paused --> Running: resumeAll()
    Running --> Ready: close()
    Ready --> [*]: destroy()

    Running --> Running: resetState()
```

## Platform Communication

See [Platform Communication](./01-Platform-Communication.md) for details.

### Communication Types

```mermaid
graph TB
    subgraph "Host API (Flutter calls Native)"
        HOST1[getAccessToken]
        HOST2[getInitialCollect]
        HOST3[getCurrentGeneration]
        HOST4[isDebugMode]
    end

    subgraph "Flutter API (Native calls Flutter)"
        FLUTTER1[trackEvent]
        FLUTTER2[onLikeButtonClick]
        FLUTTER3[onShareButtonClick]
        FLUTTER4[onScreenStateChanged]
        FLUTTER5[onVideoStateChanged]
        FLUTTER6[onSwipeLeft/Right]
        FLUTTER7[onUserProfileClick]
        FLUTTER8[resetState/pauseAll/resumeAll]
    end

    PIGEON[Pigeon<br/>Code Generator]

    PIGEON -->|Generate| HOST1
    PIGEON -->|Generate| HOST2
    PIGEON -->|Generate| HOST3
    PIGEON -->|Generate| HOST4
    PIGEON -->|Generate| FLUTTER1
    PIGEON -->|Generate| FLUTTER2
    PIGEON -->|Generate| FLUTTER3
    PIGEON -->|Generate| FLUTTER4
    PIGEON -->|Generate| FLUTTER5
    PIGEON -->|Generate| FLUTTER6
    PIGEON -->|Generate| FLUTTER7
    PIGEON -->|Generate| FLUTTER8

    style PIGEON fill:#FFA500
    style HOST1 fill:#87CEEB
    style FLUTTER1 fill:#FFB6C1
```

## Key Architectural Decisions

### 1. Flutter Module (Not Plugin)

**Decision:** Use Flutter module, not Flutter plugin

**Rationale:**
- Full UI control
- Custom navigation
- Shared business logic
- Native wrapper flexibility

### 2. Pigeon for Platform Channels

**Decision:** Use Pigeon instead of MethodChannel directly

**Rationale:**
- Type safety
- Code generation
- Compile-time checks
- Better IDE support
- Reduced errors

### 3. Clean Architecture

**Decision:** Implement Clean Architecture in Flutter core

**Rationale:**
- Testability
- Maintainability
- Clear boundaries
- Platform independence
- Scalability

### 4. Separate Native Bridges

**Decision:** Maintain separate iOS and Android bridges

**Rationale:**
- Platform-specific patterns (Coordinator vs Module)
- Native performance
- Platform conventions
- Independent releases

### 5. Generation-Based State

**Decision:** Use generation IDs for state management

**Rationale:**
- Independent screen instances
- Resume capability
- Memory efficiency
- No state conflicts
- Clean lifecycle

## Architecture Diagrams

### Complete System Architecture

```mermaid
graph TB
    subgraph "iOS App"
        IOS_APP[iOS Application]
    end

    subgraph "Android App"
        ANDROID_APP[Android Application]
    end

    subgraph "reels_ios"
        IOS_MODULE[ReelsModule]
        IOS_ENGINE[Engine Manager]
        IOS_PIGEON[Pigeon Handler]
    end

    subgraph "reels_android"
        ANDROID_MODULE[ReelsModule]
        ANDROID_ENGINE[Engine Manager]
        ANDROID_PIGEON[Pigeon Handler]
    end

    subgraph "Pigeon"
        PIGEON_CHANNELS[Type-Safe Channels]
    end

    subgraph "reels_flutter"
        direction TB

        subgraph "Presentation"
            P1[Screens]
            P2[Widgets]
            P3[Providers]
        end

        subgraph "Domain"
            D1[Entities]
            D2[Use Cases]
            D3[Repo Interfaces]
        end

        subgraph "Data"
            DA1[Models]
            DA2[Data Sources]
            DA3[Repo Impl]
        end

        subgraph "Core"
            C1[DI]
            C2[Services]
            C3[Pigeon Gen]
        end

        P1 --> P3
        P3 --> D2
        D2 --> D3
        D3 --> DA3
        DA3 --> DA2

        C1 --> D2
        C1 --> DA3
        C2 --> C3
    end

    IOS_APP --> IOS_MODULE
    ANDROID_APP --> ANDROID_MODULE

    IOS_MODULE --> IOS_ENGINE
    IOS_ENGINE --> IOS_PIGEON
    ANDROID_MODULE --> ANDROID_ENGINE
    ANDROID_ENGINE --> ANDROID_PIGEON

    IOS_PIGEON <--> PIGEON_CHANNELS
    ANDROID_PIGEON <--> PIGEON_CHANNELS

    PIGEON_CHANNELS <--> C2

    style IOS_APP fill:#87CEEB
    style ANDROID_APP fill:#90EE90
    style IOS_MODULE fill:#FFB6C1
    style ANDROID_MODULE fill:#FFD700
    style PIGEON_CHANNELS fill:#FFA500
    style P1 fill:#FFB6C1
    style D2 fill:#87CEEB
    style DA3 fill:#90EE90
    style C2 fill:#FFD700
```

## Further Reading

- [Platform Communication](./01-Platform-Communication.md) - Detailed Pigeon API documentation
- [Flutter Engine Lifecycle](./02-Flutter-Engine-Lifecycle.md) - Engine management
- [Generation-Based State Management](./03-Generation-Based-State-Management.md) - State architecture
- [iOS Coordinator Pattern](./04-iOS-Coordinator-Pattern.md) - iOS integration patterns and coordinator architecture
- [Android Module Pattern](./05-Android-Module-Pattern.md) - Android integration patterns and multimodal navigation architecture
