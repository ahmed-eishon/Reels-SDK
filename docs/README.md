# Reels SDK Documentation

This directory is organized as an Obsidian vault containing comprehensive technical documentation for the Reels SDK, including architecture details, integration guides, and development resources.

## 📚 Documentation Structure

### Main Documentation Hub

**Start here:** [00-MOC-Reels-SDK.md](00-MOC-Reels-SDK.md) (Main Hub - Map of Content)

### Quick Links

**Getting Started:**
- [Obsidian Setup Guide](00-Obsidian-Setup-Guide.md) - How to view documentation with proper diagram rendering
- [Quick Overview](QUICK-OVERVIEW.md) - Presentation-ready summary

**Integration Guides:**
- [iOS Integration Guide](02-Integration/01-iOS-Integration-Guide.md)
- [Android Integration Guide](02-Integration/02-Android-Integration-Guide.md)

**Architecture Documentation:**
- [Platform Communication](03-Architecture/01-Platform-Communication.md)
- [Flutter Engine Lifecycle](03-Architecture/02-Flutter-Engine-Lifecycle.md)
- [Generation-Based State Management](03-Architecture/03-Generation-Based-State-Management.md)

**Development Guides:**
- [Build Process](Build-Process.md) - Detailed guide on building the SDK with room-ios
- [Quick Start Guide for AI Agents](Quick-Start-Guide-AI-Agent.md) - Guide for AI agents working with this codebase

## 🎯 Viewing Documentation

### Option 1: Obsidian (Recommended)

For the best experience with Mermaid diagrams and internal links:

1. **Install Obsidian:** https://obsidian.md
2. **Open Vault:** File → Open folder as vault → Select the `docs` folder
3. **View:** Switch to Reading View (Cmd/Ctrl + E) to see rendered diagrams

See [Obsidian Setup Guide](00-Obsidian-Setup-Guide.md) for detailed instructions.

### Option 2: GitHub/Text Editor

All documentation is in standard Markdown format and can be viewed in any text editor or on GitHub.

**Note:** Mermaid diagrams will appear as code blocks in plain text editors.

### Option 3: VS Code with Extensions

Install these VS Code extensions:
- Markdown Preview Mermaid Support
- Markdown All in One

Then use Markdown Preview (Cmd/Ctrl + Shift + V) to view rendered documents.

## 📂 Directory Structure

```
docs/                                  ← Obsidian vault root
├── README.md                          ← You are here
├── 00-MOC-Reels-SDK.md                ← Main Hub (START HERE)
├── 00-Obsidian-Setup-Guide.md         ← Setup guide
├── QUICK-OVERVIEW.md                  ← Quick reference
├── Build-Process.md                   ← Build documentation
├── Quick-Start-Guide-AI-Agent.md      ← AI agent guide
├── .obsidian/                         ← Obsidian configuration
├── 01-Overview/                       ← SDK overview docs
├── 02-Integration/                    ← Integration guides
│   ├── 01-iOS-Integration-Guide.md
│   └── 02-Android-Integration-Guide.md
└── 03-Architecture/                   ← Architecture docs
    ├── 01-Platform-Communication.md
    ├── 02-Flutter-Engine-Lifecycle.md
    └── 03-Generation-Based-State-Management.md
```

## 🎨 Documentation Features

- ✅ **Mermaid Diagrams** - Visual architecture and flow diagrams
- ✅ **Internal Links** - Easy navigation between documents
- ✅ **Code Examples** - Swift, Kotlin, and Dart code samples
- ✅ **Callouts** - Info, warning, and tip boxes
- ✅ **Comprehensive** - 800+ lines of detailed architecture documentation
- ✅ **Generic** - Platform-agnostic examples for universal use

## 🔧 Contributing to Documentation

When updating documentation:

1. **Follow Structure:** Keep files in appropriate folders
2. **Update Links:** Update internal links if moving files
3. **Use Mermaid:** Convert complex ASCII diagrams to Mermaid
4. **Be Generic:** Use generic examples, not specific implementation details
5. **Update MOC:** Add new documents to `00-MOC-Reels-SDK.md`

## 📖 Quick Reference

| Topic | Document |
|-------|----------|
| **Main Hub** | [00-MOC-Reels-SDK.md](00-MOC-Reels-SDK.md) |
| **Getting Started** | [QUICK-OVERVIEW.md](QUICK-OVERVIEW.md) |
| **iOS Integration** | [02-Integration/01-iOS-Integration-Guide.md](02-Integration/01-iOS-Integration-Guide.md) |
| **Android Integration** | [02-Integration/02-Android-Integration-Guide.md](02-Integration/02-Android-Integration-Guide.md) |
| **Architecture** | [03-Architecture/](03-Architecture/) |
| **Build Process** | [Build-Process.md](Build-Process.md) |
| **Obsidian Setup** | [00-Obsidian-Setup-Guide.md](00-Obsidian-Setup-Guide.md) |
| **AI Agent Guide** | [Quick-Start-Guide-AI-Agent.md](Quick-Start-Guide-AI-Agent.md) |

## 🆘 Support

For questions or issues with documentation:

- **Internal:** ROOM Team at room-team@rakuten.com
- **Git:** https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk

---

**Version:** 1.0.0 | **Last Updated:** November 14, 2025 | **Maintained by:** ROOM Team
