```
 ██████   █████  ███                  █████             
░░██████ ░░███  ░░░                  ░░███              
 ░███░███ ░███  ████  █████████████   ░███████   ██████ 
 ░███░░███░███ ░░███ ░░███░░███░░███  ░███░░███ ███░░███
 ░███ ░░██████  ░███  ░███ ░███ ░███  ░███ ░███░███ ░███
 ░███  ░░█████  ░███  ░███ ░███ ░███  ░███ ░███░███ ░███
 █████  ░░█████ █████ █████░███ █████ ████████ ░░██████ 
░░░░░    ░░░░░ ░░░░░ ░░░░░ ░░░ ░░░░░ ░░░░░░░░   ░░░░░░  
                                                                                                                
```

### About This Post
This repository accompanies a forthcoming blog post on _{{placeholder-blog-title}}_, walking through how to build a lightweight, multi-tool coding agent in Swift.

### Architecture at a Glance
- **CLI Entry (`Sources/NimboCLI/main.swift`)** wires environment configuration and launches the `Agent`.
- **Agent Orchestrator (`Sources/NimboCLI/Agent.swift`)** tracks chat history, loops through model calls, and routes tool invocations (list files, read file, edit file) using SwiftOpenAI.
- **Tool Protocol & Implementations (`Sources/NimboCLI/Tools/`)** provide self-contained actions:
  - `ListFiles` surfaces directory snapshots.
  - `ReadFile` streams capped file contents.
  - `EditFile` performs targeted text replacements with guardrails.
- **Shared Helpers (`Sources/NimboCLI/Tools/Tool+Helpers.swift`)** centralize path decoding, URL utilities, and string helpers to keep tool logic terse.

Together these components form an iterative agent loop capable of planning, calling multiple tools per turn, and reflecting the results back to the user—ready for deeper exploration in the upcoming blog write-up.
