# Muninn — Regras do Projeto

## Stack
- SwiftUI exclusivamente.
- macOS 14+ (Sonoma/Sequoia).
- Swift 5.9+.

## UI / HIG
- Janela de ajustes nativa do macOS via `Window` Scene (não-modal, arrastável, com botões de fechar/minimizar/expandir).
- Atalho `⌘,` preservado via `CommandGroup(after: .appSettings)`.
- Usar SF Symbols; nunca ícones custom raster.
- Suporte total a Dark Mode via `.preferredColorScheme` e tokens do sistema.
- `Form { }.formStyle(.grouped)` em telas de preferências.
- `LabeledContent` para alinhamento label/controle.
- Tipografia do sistema: `.body`, `.caption`, `.caption2`.
- Acento: `AccentColor` da Apple.

## Arquitetura
- MVVM com `@Observable` (preferencial) ou `ObservableObject` + `@Published`.
- Preferências simples com `@AppStorage`.
- ViewModels marcados com `@MainActor`.
- Estado complexo persistido em `UserDefaults` via `JSONEncoder/JSONDecoder`.
- Cada view struct em arquivo separado, dentro de `Screens/<Feature>/Views/`.

## Modelos
- Todo model deve adotar `Identifiable` e `Codable`.
- Enums com `String` como `RawValue`; conformar `CaseIterable` e `Identifiable` quando usados em Pickers.
- `id: UUID` com `init(id: UUID = UUID())` explícito para garantir síntese correta de `Codable`.
- Propriedades armazenadas sem valor padrão quando o tipo precisa ser `Decodable` (ou fornecer `init` explícito).

## Comandos
- Build: `xcodebuild -scheme Cardeal -configuration Debug build`.
- Test: `xcodebuild -scheme Cardeal -configuration Debug test`.
- Abrir projeto: `open Cardeal.xcodeproj`.

## Estrutura
```
Cardeal/
├── CardealApp.swift
├── Assets.xcassets/
├── Screens/
│   ├── Dashboard/
│   ├── Settings/
│   └── Attachments/
├── Views/
├── Shared/
│   ├── Components/
│   ├── Models/
│   ├── Mocks/
│   └── Theme/
```
