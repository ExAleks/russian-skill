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
| OpenCode | `opencode/russian/SKILL.md` | `~/.config/opencode/skills/russian/` (или `$XDG_CONFIG_HOME/opencode/skills/russian/`) | `.opencode/skills/russian/` |
| Codex CLI | `codex/AGENTS.md` | `~/.codex/AGENTS.md` | `AGENTS.md` в корне |
| Cursor | `cursor/.cursor/rules/russian.mdc` | — | `.cursor/rules/` в корне (`alwaysApply: true`) |
| Cline | `cline/.clinerules/russian.md` | Custom Instructions: `cline/user-instructions.txt` | `.clinerules/` в корне |
| Windsurf | `windsurf/.windsurf/rules/russian.md` | — | `.windsurf/rules/` в корне (`trigger: always_on`) |
| Gemini CLI | `gemini/GEMINI.md` | `~/.gemini/GEMINI.md` | `GEMINI.md` в корне |

Глобальное правило для OpenCode (действует всегда, а не по триггеру скилла):
`shared/language-rule.md` → блок в `~/.config/opencode/AGENTS.md`.

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

Скопируйте нужный файл из таблицы выше в соответствующий путь. Для инструкций
(`AGENTS.md`, `GEMINI.md`) скопируйте блок из `shared/language-rule.md`, а не
перезаписывайте файл целиком — иначе потеряются ваши собственные правила.

## Что делает установщик

- Ставит скилл OpenCode в `skills/russian/` (именно `skills`, не `skill`) и учитывает
  `XDG_CONFIG_HOME`, если переменная задана.
- Правило языка **дописывает** в существующие `AGENTS.md` / `GEMINI.md`, а не заменяет их.
  Блок обёрнут маркерами `<!-- russian-skill:begin -->` / `<!-- russian-skill:end -->`,
  поэтому повторный запуск обновляет его на месте и не создаёт дублей.
- Сохраняет переводы строк файла (LF или CRLF) и кодировку UTF-8 без BOM.
- С `--force` / `-Force` перезаписывает файлы скилла, оставляя копию `*.bak-<timestamp>`.
- В конце проверяет, что скилл и правило действительно лежат по ожидаемым путям,
  и завершается с ненулевым кодом, если что-то не на месте.
- `--list-only` / `-ListOnly` показывает план без записи, `--project-dir` / `-ProjectDir`
  дополнительно ставит правила Cursor, Windsurf и Cline в проект.

## Тесты

Установщики проверяются смоук-тестами: правильный путь скилла, сохранение
пользовательского `AGENTS.md`, отсутствие дублей блока при повторном запуске, CRLF,
файл без завершающего перевода строки, `XDG_CONFIG_HOME`.

```powershell
powershell -NoProfile -File .\tests\run-tests.ps1
```

```sh
./tests/run-tests.sh
```

## Заметки по совместимости

- **Claude Code / OpenCode**: скилл срабатывает по `description`, когда пользователь
  пишет по-русски или просит русский. Для безусловного действия установщик сам
  дописывает правило в глобальный `AGENTS.md` (OpenCode); в Claude Code продублируйте
  блок из `shared/language-rule.md` в `CLAUDE.md`.
- **Codex CLI и Gemini CLI** скиллов не имеют — там правило идёт через `AGENTS.md` / `GEMINI.md`.
- **Cursor и Windsurf**: правило живёт в проекте, куда скопирован файл; флаги
  `alwaysApply` / `trigger: always_on` делают его постоянным.
- **Cline**: `.clinerules` действует на проект, Custom Instructions — глобально.

## Лицензия

MIT — см. [LICENSE](LICENSE).
