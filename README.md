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

**A complete AI coding agent in ~500 lines of Swift.** No framework, no orchestration library, no magic — a loop, three tools, and a language model with opinions.

Nimbo is the companion project to [**Demystifying AI Coding Agents in Swift**](https://gioscalzo.com/blog/demystifying-ai-coding-agents-in-swift/), which walks through every piece of this code and explains why tools like Claude Code and Cursor are far less mysterious than they look.

## The whole trick

Watching an agent chain file reads together, spot a bug, and fix it feels like watching something think. Under the hood, it's this:

1. Send the conversation — *all of it, every time* — to the model, along with descriptions of the tools it's allowed to call.
2. If the model answers with text, print it. Done.
3. If it answers with a tool call instead, run the tool, append the result to the conversation, and go back to step 1.

That's `respond()` in [`Agent.swift`](Sources/NimboCLI/Agent.swift). Nobody taught the model to list a directory before reading a file, or to re-read a file after a failed edit. That behavior emerges from the loop and the tool descriptions alone.

## The three tools

| Tool | What it does | Guardrail |
|------|--------------|-----------|
| `list_files` | Snapshot of a directory | Capped at 200 entries |
| `read_file` | Return a file's contents | Capped at 100 KB |
| `edit_file` | Exact-match string replacement (creates the file when `old_str` is empty) | Refuses ambiguous matches |

A tool is just a name, a description the model reads, and a function that runs when the model asks for it. The whole contract is an [8-line protocol](Sources/NimboCLI/Tools/Tool.swift) — adding a fourth tool means writing one struct.

## Run it

You'll need macOS 12+, Swift 5.9+, and an OpenAI API key (Nimbo talks to `gpt-5-mini` through [SwiftOpenAI](https://github.com/jamesrochabrun/SwiftOpenAI)).

```bash
git clone https://github.com/gscalzo/Nimbo.git
cd Nimbo
OPENAI_API_KEY=sk-... swift run nimbo
```

Then chat:

```
Chat with Nimbo (use 'ctrl-c' to quit)

You: what does this project do?
tool: list_files({"path":"."})
tool: read_file({"path":"Package.swift"})
tool: read_file({"path":"Sources/NimboCLI/Agent.swift"})
Nimbo: It's a Swift CLI agent that answers questions by calling tools...
```

Every `tool:` line is the model deciding, on its own, that it needs more context before it can answer.

Things worth trying:

- *"Find the TODO comments in this codebase and tell me which one looks most urgent."*
- *"Create a Swift script that plays an emoji guessing game, then improve the hints."*
- *"Rename this function across the project"* — and watch it chain list → read → edit without being told to.

## Project layout

```
Sources/NimboCLI/
├── main.swift              # the REPL: read a line, print the answer, repeat
├── Agent.swift             # conversation history + the tool loop
└── Tools/
    ├── Tool.swift          # the protocol every tool conforms to
    ├── ListFiles.swift
    ├── ReadFile.swift
    ├── EditFile.swift
    └── Tool+Helpers.swift  # path decoding, shared plumbing
```

## Safety rails

A loop where an LLM decides when the loop ends deserves a little skepticism. Nimbo keeps things honest with:

- **At most 8 tool iterations** per user message, so a confused model can't spin forever.
- **Output caps** on reads and listings, so one stray `node_modules/` doesn't flood the context window (and your bill).
- **Unambiguous edits only** — `edit_file` fails loudly rather than guess when a search string matches more than once.

Production agents add sandboxing, token budgets, rate limiting, and permission prompts on top. Same skeleton, more armor.

## Where to go from here

Fork it and make it yours: add a `run_command` tool, swap in a different model, give it a system prompt with attitude, or split it into cooperating sub-agents. The point of Nimbo is that once you've seen the loop, you can build any of these.

The full story — context windows, emergent tool chaining, and two worked examples — is in the blog post:

**→ [Demystifying AI Coding Agents in Swift](https://gioscalzo.com/blog/demystifying-ai-coding-agents-in-swift/)**
