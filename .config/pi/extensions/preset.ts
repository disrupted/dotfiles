/**
 * Preset Extension (local fork)
 *
 * Allows defining named presets that configure model, thinking level, tools,
 * and system prompt instructions. Presets are defined in JSON config files
 * and can be activated via CLI flag or /preset command.
 *
 * Config files (merged, project takes precedence):
 * - ~/.pi/agent/presets.json (global)
 * - <cwd>/.pi/presets.json (project-local)
 *
 * Local changes vs. the shipped example:
 * - A preset may use `instructionsFile` instead of `instructions`. The file is
 *   resolved relative to the agent directory and read when the preset is applied.
 * - The Ctrl+Shift+U cycle shortcut (and its helpers) were removed; use /preset.
 *
 * Example presets.json:
 * ```json
 * {
 *   "reviewer": {
 *     "provider": "anthropic",
 *     "model": "claude-sonnet-5-5",
 *     "thinkingLevel": "medium",
 *     "tools": ["read", "bash", "grep", "find", "ls"],
 *     "instructionsFile": "instructions/reviewer.md"
 *   }
 * }
 * ```
 *
 * Usage:
 * - `pi --preset reviewer` - start with the reviewer preset
 * - `/preset` - show selector to switch presets mid-session
 * - `/preset reviewer` - switch to the reviewer preset directly
 *
 * CLI flags always override preset values.
 */

import { existsSync, readFileSync } from "node:fs";
import { isAbsolute, join } from "node:path";
import type { Api, Model } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { CONFIG_DIR_NAME, DynamicBorder, getAgentDir } from "@earendil-works/pi-coding-agent";
import { Container, type SelectItem, SelectList, Text } from "@earendil-works/pi-tui";

// Preset configuration
interface Preset {
	/** Provider name (e.g., "anthropic", "openai") */
	provider?: string;
	/** Model ID (e.g., "claude-sonnet-5-5") */
	model?: string;
	/** Thinking level */
	thinkingLevel?: "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";
	/** Tools to enable (replaces default set) */
	tools?: string[];
	/** Instructions to append to system prompt */
	instructions?: string;
	/** Path to a Markdown file whose contents replace/appended as instructions */
	instructionsFile?: string;
}

interface PresetsConfig {
	[name: string]: Preset;
}

/**
 * Load presets from config files.
 * Project-local presets override global presets with the same name.
 */
function loadPresets(cwd: string): PresetsConfig {
	const globalPath = join(getAgentDir(), "presets.json");
	const projectPath = join(cwd, CONFIG_DIR_NAME, "presets.json");

	let globalPresets: PresetsConfig = {};
	let projectPresets: PresetsConfig = {};

	// Load global presets
	if (existsSync(globalPath)) {
		try {
			const content = readFileSync(globalPath, "utf-8");
			globalPresets = JSON.parse(content);
		} catch (err) {
			console.error(`Failed to load global presets from ${globalPath}: ${err}`);
		}
	}

	// Load project presets
	if (existsSync(projectPath)) {
		try {
			const content = readFileSync(projectPath, "utf-8");
			projectPresets = JSON.parse(content);
		} catch (err) {
			console.error(`Failed to load project presets from ${projectPath}: ${err}`);
		}
	}

	// Merge (project overrides global)
	return { ...globalPresets, ...projectPresets };
}

interface OriginalState {
	model: Model<Api> | undefined;
	thinkingLevel: "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";
	tools: string[];
}

export default function presetExtension(pi: ExtensionAPI) {
	let presets: PresetsConfig = {};
	let activePresetName: string | undefined;
	let activePreset: Preset | undefined;
	let originalState: OriginalState | undefined;

	// Register --preset CLI flag
	pi.registerFlag("preset", {
		description: "Preset configuration to use",
		type: "string",
	});

	/**
	 * Resolve a preset's instructions, reading `instructionsFile` when present.
	 */
	function resolveInstructions(preset: Preset, ctx: ExtensionContext): string | undefined {
		if (preset.instructionsFile) {
			const path = isAbsolute(preset.instructionsFile)
				? preset.instructionsFile
				: join(getAgentDir(), preset.instructionsFile);
			try {
				return readFileSync(path, "utf-8");
			} catch (err) {
				ctx.ui.notify(`Preset: failed to read instructionsFile ${path}: ${err}`, "warning");
				return preset.instructions;
			}
		}
		return preset.instructions;
	}

	/**
	 * Apply a preset configuration.
	 */
	async function applyPreset(name: string, preset: Preset, ctx: ExtensionContext): Promise<boolean> {
		// Snapshot state before the first preset is applied (i.e. only when transitioning from no-preset)
		if (activePresetName === undefined) {
			originalState = {
				model: ctx.model,
				thinkingLevel: pi.getThinkingLevel(),
				tools: pi.getActiveTools(),
			};
		}

		// Apply model if specified
		if (preset.provider && preset.model) {
			const model = ctx.modelRegistry.find(preset.provider, preset.model);
			if (model) {
				const success = await pi.setModel(model);
				if (!success) {
					ctx.ui.notify(`Preset "${name}": No API key for ${preset.provider}/${preset.model}`, "warning");
				}
			} else {
				ctx.ui.notify(`Preset "${name}": Model ${preset.provider}/${preset.model} not found`, "warning");
			}
		}

		// Apply thinking level if specified
		if (preset.thinkingLevel) {
			pi.setThinkingLevel(preset.thinkingLevel);
		}

		// Apply tools if specified
		if (preset.tools && preset.tools.length > 0) {
			const allToolNames = pi.getAllTools().map((t) => t.name);
			const validTools = preset.tools.filter((t) => allToolNames.includes(t));
			const invalidTools = preset.tools.filter((t) => !allToolNames.includes(t));

			if (invalidTools.length > 0) {
				ctx.ui.notify(`Preset "${name}": Unknown tools: ${invalidTools.join(", ")}`, "warning");
			}

			if (validTools.length > 0) {
				pi.setActiveTools(validTools);
			}
		}

		// Store active preset (with resolved instructions) for system prompt injection
		activePresetName = name;
		activePreset = { ...preset, instructions: resolveInstructions(preset, ctx) };

		return true;
	}

	/**
	 * Build description string for a preset.
	 */
	function buildPresetDescription(preset: Preset): string {
		const parts: string[] = [];

		if (preset.provider && preset.model) {
			parts.push(`${preset.provider}/${preset.model}`);
		}
		if (preset.thinkingLevel) {
			parts.push(`thinking:${preset.thinkingLevel}`);
		}
		if (preset.tools) {
			parts.push(`tools:${preset.tools.join(",")}`);
		}
		if (preset.instructionsFile) {
			parts.push(`file:${preset.instructionsFile}`);
		} else if (preset.instructions) {
			const truncated =
				preset.instructions.length > 30 ? `${preset.instructions.slice(0, 27)}...` : preset.instructions;
			parts.push(`"${truncated}"`);
		}

		return parts.join(" | ");
	}

	/**
	 * Show preset selector UI using custom SelectList component.
	 */
	async function showPresetSelector(ctx: ExtensionContext): Promise<void> {
		const presetNames = Object.keys(presets);

		if (presetNames.length === 0) {
			ctx.ui.notify(
				`No presets defined. Add presets to ${join(getAgentDir(), "presets.json")} or ${join(ctx.cwd, CONFIG_DIR_NAME, "presets.json")}`,
				"warning",
			);
			return;
		}

		// Build select items with descriptions
		const items: SelectItem[] = presetNames.map((name) => {
			const preset = presets[name];
			const isActive = name === activePresetName;
			return {
				value: name,
				label: isActive ? `${name} (active)` : name,
				description: buildPresetDescription(preset),
			};
		});

		// Add "None" option to clear preset
		items.push({
			value: "(none)",
			label: "(none)",
			description: "Clear active preset, restore defaults",
		});

		const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
			const container = new Container();
			container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));

			// Header
			container.addChild(new Text(theme.fg("accent", theme.bold("Select Preset"))));

			// SelectList with themed styling
			const selectList = new SelectList(items, Math.min(items.length, 10), {
				selectedPrefix: (text) => theme.fg("accent", text),
				selectedText: (text) => theme.fg("accent", text),
				description: (text) => theme.fg("muted", text),
				scrollInfo: (text) => theme.fg("dim", text),
				noMatch: (text) => theme.fg("warning", text),
			});

			selectList.onSelect = (item) => done(item.value);
			selectList.onCancel = () => done(null);

			container.addChild(selectList);

			// Footer hint
			container.addChild(new Text(theme.fg("dim", "↑↓ navigate • enter select • esc cancel")));

			container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));

			return {
				render(width: number) {
					return container.render(width);
				},
				invalidate() {
					container.invalidate();
				},
				handleInput(data: string) {
					selectList.handleInput(data);
					tui.requestRender();
				},
			};
		});

		if (!result) return;

		if (result === "(none)") {
			// Clear preset and restore original state
			activePresetName = undefined;
			activePreset = undefined;
			if (originalState) {
				if (originalState.model) {
					await pi.setModel(originalState.model);
				}
				pi.setThinkingLevel(originalState.thinkingLevel);
				pi.setActiveTools(originalState.tools);
			} else {
				pi.setActiveTools(["read", "bash", "edit", "write"]);
			}
			ctx.ui.notify("Preset cleared, defaults restored", "info");
			updateStatus(ctx);
			return;
		}

		const preset = presets[result];
		if (preset) {
			await applyPreset(result, preset, ctx);
			ctx.ui.notify(`Preset "${result}" activated`, "info");
			updateStatus(ctx);
		}
	}

	/**
	 * Update status indicator.
	 */
	function updateStatus(ctx: ExtensionContext) {
		if (activePresetName) {
			ctx.ui.setStatus("preset", ctx.ui.theme.fg("accent", `preset:${activePresetName}`));
		} else {
			ctx.ui.setStatus("preset", undefined);
		}
	}

	// Register /preset command
	pi.registerCommand("preset", {
		description: "Switch preset configuration",
		handler: async (args, ctx) => {
			// If preset name provided, apply directly
			if (args?.trim()) {
				const name = args.trim();
				const preset = presets[name];

				if (!preset) {
					const available = Object.keys(presets).join(", ") || "(none defined)";
					ctx.ui.notify(`Unknown preset "${name}". Available: ${available}`, "error");
					return;
				}

				await applyPreset(name, preset, ctx);
				ctx.ui.notify(`Preset "${name}" activated`, "info");
				updateStatus(ctx);
				return;
			}

			// Otherwise show selector
			await showPresetSelector(ctx);
		},
	});

	// Inject preset instructions into system prompt
	pi.on("before_agent_start", async (event) => {
		if (activePreset?.instructions) {
			return {
				systemPrompt: `${event.systemPrompt}\n\n${activePreset.instructions}`,
			};
		}
	});

	// Initialize on session start
	pi.on("session_start", async (_event, ctx) => {
		// Load presets from config files
		presets = loadPresets(ctx.cwd);

		// Reset active preset for the new/resumed session; it is restored below
		// only from the --preset flag or this session's persisted state. Without
		// this, activating a preset then starting /new would leak the preset into
		// the new session.
		activePresetName = undefined;
		activePreset = undefined;

		// Check for --preset flag
		const presetFlag = pi.getFlag("preset");
		if (typeof presetFlag === "string" && presetFlag) {
			const preset = presets[presetFlag];
			if (preset) {
				await applyPreset(presetFlag, preset, ctx);
				ctx.ui.notify(`Preset "${presetFlag}" activated`, "info");
			} else {
				const available = Object.keys(presets).join(", ") || "(none defined)";
				ctx.ui.notify(`Unknown preset "${presetFlag}". Available: ${available}`, "warning");
			}
		}

		// Restore preset from session state
		const entries = ctx.sessionManager.getEntries();
		const presetEntry = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "preset-state")
			.pop() as { data?: { name: string } } | undefined;

		if (presetEntry?.data?.name && !presetFlag) {
			const preset = presets[presetEntry.data.name];
			if (preset) {
				activePresetName = presetEntry.data.name;
				// Don't re-apply model/tools on restore, just keep the name/instructions
				activePreset = { ...preset, instructions: resolveInstructions(preset, ctx) };
			}
		}

		updateStatus(ctx);
	});

	// Persist preset state
	pi.on("turn_start", async () => {
		if (activePresetName) {
			pi.appendEntry("preset-state", { name: activePresetName });
		}
	});
}
