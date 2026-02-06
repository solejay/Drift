## Skill Discovery Requirement
For every user request, always search the available skills list first to see if a skill or combination of skills applies. Use any matching skill(s) before proceeding. If no skill applies, explicitly state that and continue with the best fallback approach.

## Skill Selection Rules
Choose the minimal set of skills that fully covers the task.
If multiple skills apply, use them in a logical order and state that order briefly.
Do not carry skills across turns unless the user re-mentions them or the task clearly requires it.
If a skill is mentioned explicitly by name, it must be used.

## Skill Intake Workflow
Open the relevant `SKILL.md` files before acting.
Read only what you need to execute the request.
If a `SKILL.md` references other files, open only the specific ones required.
Prefer scripts and templates provided by the skill over re-creating them.

## Skill Communication
Announce which skill(s) you will use and why in one short line.
If a skill cannot be used due to missing or invalid files, say so and proceed with the next-best approach.
When no skill applies, explicitly note that and continue normally.

## Guardrails
Do not skip skill discovery even for small or simple tasks.
Do not guess a skill's behavior; always consult its `SKILL.md`.
Keep context small: avoid loading large reference trees unless needed.
