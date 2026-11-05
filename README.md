# russian-skill

**Always answer in Russian** — одно правило языка для AI-редакторов и CLI-агентов,
адаптированное под форматы каждого инструмента.

Один и тот же смысл, нативная обёртка для каждого инструмента:
отвечать по-русски всегда, даже если запрос на английском (если явно не попросили другой язык);
код, команды, пути, идентификаторы, логи и тексты ошибок не переводить;
комментарии в коде и коммиты — на английском.

## Поддерживаемые инструменты

| Инструмент | Файл | Установка (глобально) | Установка (в проект) |
|---|---|---|---|
| Claude Code | `claude-code/russian/SKILL.md` | `~/.claude/skills/russian/` | `.claude/skills/russian/` |
| OpenCode | `opencode/russian/SKILL.md` | `~/.config/opencode/skills/russian/` или через `"skills"` в `opencode.json` | `.opencode/skills/russian/` |
| Codex CLI | `codex/AGENTS.md` | `~/.codex/AGENTS.md` | `AGENTS.md` в корне |
| Cursor | `cursor/.cursor/rules/russian.mdc` | — | `.cursor/rules/` в корне (`alwaysApply: true`) |
| Cline | `cline/.clinerules/russian.md` | Custom Instructions: `cline/user-instructions.txt` | `.clinerules/` в корне |
| Windsurf | `windsurf/.windsurf/rules/russian.md` | — | `.windsurf/rules/` в корне (`trigger: always_on`) |
| Gemini CLI | `gemini/GEMINI.md` | `~/.gemini/GEMINI.md` | `GEMINI.md` в корне |

Глобальное правило для OpenCode (действует всегда, а не по триггеру скилла):
`opencode/AGENTS.md` → `~/.config/opencode/AGENTS.md`.

## Суть правила

- Всегда отвечать по-русски: объяснения, планы, статусы, вопросы, итоговые ответы.
- Отвечать по-русски, даже если сообщение пользователя на английском,
  если он явно не попросил другой язык.
- Не переводить и не транслитерировать код, команды, пути к файлам, идентификаторы,
  имена API, ключи конфигурации, логи и тексты ошибок — оставлять как есть.
- Комментарии в коде и сообщения коммитов — на английском, если не попросили иначе.
- Общепринятые термины (API, deploy, merge, pull request) не переводить.
- Не объявлять, что действует правило языка или что текст был переведён.

## Установка

### Скриптом (Windows, PowerShell)

```powershell
git clone https://github.com/ExAleks/russian-skill.git
cd russian-skill
.\install.ps1
```

### Скриптом (macOS / Linux)

```sh
git clone https://github.com/ExAleks/russian-skill.git
cd russian-skill
chmod +x install.sh && ./install.sh
```

### Вручную

Скопируйте нужный файл из таблицы выше в соответствующий путь. Точки назначения
создаются автоматически, существующие файлы не перезаписываются без `--force`.

## Заметки по совместимости

- **Claude Code / OpenCode**: скилл срабатывает по `description`, когда пользователь
  пишет по-русски или просит русский. Для безусловного действия продублируйте правило
  в `CLAUDE.md` (Claude Code) или глобальном `AGENTS.md` (OpenCode).
- **Codex CLI и Gemini CLI** скиллов не имеют — там правило идёт через `AGENTS.md` / `GEMINI.md`.
- **Cursor и Windsurf**: правило живёт в проекте, куда скопирован файл; флаги
  `alwaysApply` / `trigger: always_on` делают его постоянным.
- **Cline**: `.clinerules` действует на проект, Custom Instructions — глобально.

## Лицензия

MIT — см. [LICENSE](LICENSE).
