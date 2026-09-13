"use strict";
var g = Object.defineProperty;
var A = Object.getOwnPropertyDescriptor;
var E = Object.getOwnPropertyNames;
var $ = Object.prototype.hasOwnProperty;
var B = (e, t) => { for (var n in t) g(e, n, { get: t[n], enumerable: !0 }); };
var R = (e, t, n, s) => {
    if (t && typeof t == "object" || typeof t == "function")
        for (let i of E(t))
            !$.call(e, i) && i !== n && g(e, i, { get: () => t[i], enumerable: !(s = A(t, i)) || s.enumerable });
    return e;
};
var P = e => R(g({}, "__esModule", { value: !0 }), e);
var G = {};
B(G, { default: () => PowerMenu });
module.exports = P(G);

var r = require("@vicinae/api");
var a = require("react/jsx-runtime");
var React = require("react");
var cp = require("node:child_process");
var fs = require("node:fs");
var path = require("node:path");

const CONFIG_FILE = path.join(
    process.env.XDG_CONFIG_HOME || path.join(process.env.HOME, ".config"),
    "vicinae",
    "power-session.json"
);

function loadCustomConfig() {
    try {
        if (fs.existsSync(CONFIG_FILE)) {
            const raw = fs.readFileSync(CONFIG_FILE, "utf8");
            return JSON.parse(raw);
        }
    } catch (e) {
        console.warn("Failed reading custom config:", e);
    }
    return {};
}

function saveCustomConfig(config) {
    try {
        const dir = path.dirname(CONFIG_FILE);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2), "utf8");
        return true;
    } catch (e) {
        console.error("Failed writing custom config:", e);
        return false;
    }
}

const ITEMS = [
    {
        id: "lock",
        title: "Lock Screen",
        subtitle: "Lock session",
        icon: r.Icon.Lock,
        deeplink: "vicinae://launch/power/lock",
        defaultCmd: "vicinae://launch/power/lock",
        placeholder: "hyprlock",
        type: "Security / Session",
        shortcutKey: "l",
        description: "Locks the current desktop session."
    },
    {
        id: "suspend",
        title: "Suspend / Sleep",
        subtitle: "Low-power sleep",
        icon: r.Icon.Moon,
        deeplink: "vicinae://launch/power/suspend",
        defaultCmd: "vicinae://launch/power/suspend",
        placeholder: "systemctl suspend",
        type: "Power State",
        shortcutKey: "u",
        description: "Puts the computer into low-power sleep mode."
    },
    {
        id: "reboot",
        title: "Restart / Reboot",
        subtitle: "Reboot computer",
        icon: r.Icon.ArrowClockwise,
        deeplink: "vicinae://launch/power/reboot",
        defaultCmd: "vicinae://launch/power/reboot",
        placeholder: "systemctl reboot",
        type: "System Lifecycle",
        shortcutKey: "r",
        description: "Restarts the operating system and reboots the machine."
    },
    {
        id: "power-off",
        title: "Power Off / Shutdown",
        subtitle: "Shut down system",
        icon: r.Icon.Power,
        deeplink: "vicinae://launch/power/power-off",
        defaultCmd: "vicinae://launch/power/power-off",
        placeholder: "systemctl poweroff",
        type: "System Lifecycle",
        shortcutKey: "s",
        description: "Safely terminates processes and powers off hardware."
    },
    {
        id: "logout",
        title: "Log Out",
        subtitle: "Exit current session",
        icon: r.Icon.ArrowRightCircleFilled,
        deeplink: "vicinae://launch/power/logout",
        defaultCmd: "vicinae://launch/power/logout",
        placeholder: "hyprctl dispatch exit",
        type: "Session Lifecycle",
        shortcutKey: "e",
        description: "Ends the current desktop session and returns to login manager."
    },
    {
        id: "hibernate",
        title: "Hibernate",
        subtitle: "Save state to disk",
        icon: r.Icon.HardDrive,
        deeplink: "vicinae://launch/power/hibernate",
        defaultCmd: "vicinae://launch/power/hibernate",
        placeholder: "systemctl hibernate",
        type: "Power State",
        shortcutKey: "h",
        description: "Writes active memory state to disk and powers down completely."
    }
];

async function triggerAction(item, customCmd) {
    await (0, r.closeMainWindow)();
    if (customCmd && customCmd.trim() !== "") {
        if (customCmd.startsWith("vicinae://")) {
            await (0, r.open)(customCmd);
        } else {
            cp.exec(customCmd, (err) => {
                if (err) {
                    (0, r.showToast)({
                        style: r.Toast.Style.Failure,
                        title: `Failed to execute: ${item.title}`,
                        message: err.message
                    });
                }
            });
        }
    } else {
        await (0, r.open)(item.deeplink);
    }
}

function SettingsForm({ config, onSaved }) {
    const { pop } = (0, r.useNavigation)();

    const handleSubmit = async (values) => {
        const cleaned = {};
        for (const [k, v] of Object.entries(values)) {
            if (v && typeof v === "string" && v.trim() !== "") {
                cleaned[k] = v.trim();
            }
        }
        const ok = saveCustomConfig(cleaned);
        if (ok) {
            await (0, r.showToast)({
                style: r.Toast.Style.Success,
                title: "Custom Commands Saved",
                message: "Power actions updated successfully."
            });
            onSaved(cleaned);
            pop();
        } else {
            await (0, r.showToast)({
                style: r.Toast.Style.Failure,
                title: "Save Failed",
                message: "Could not write configuration to disk."
            });
        }
    };

    return (0, a.jsxs)(r.Form, {
        navigationTitle: "Configure Power Commands",
        actions: (0, a.jsxs)(r.ActionPanel, {
            children: [
                (0, a.jsx)(r.Action.SubmitForm, {
                    title: "Save Commands",
                    icon: r.Icon.CheckCircle,
                    onSubmit: handleSubmit
                }),
                (0, a.jsx)(r.Action, {
                    title: "Cancel",
                    icon: r.Icon.XMarkCircle,
                    onAction: pop
                })
            ]
        }),
        children: [
            (0, a.jsx)(r.Form.Description, {
                text: "Specify custom shell commands to execute (e.g. hyprctl dispatch exit, hyprlock, systemctl poweroff). Leave any input blank to fallback to the default Vicinae built-in power deeplink."
            }),
            (0, a.jsx)(r.Form.Separator, {}),
            ...ITEMS.map(item => (
                (0, a.jsx)(r.Form.TextField, {
                    id: item.id,
                    title: item.title,
                    placeholder: item.placeholder,
                    defaultValue: config[item.id] || ""
                }, item.id)
            ))
        ]
    });
}

function PowerMenu() {
    const [config, setConfig] = React.useState(() => loadCustomConfig());
    const { push } = (0, r.useNavigation)();

    const openSettings = () => {
        push((0, a.jsx)(SettingsForm, {
            config,
            onSaved: (newCfg) => setConfig(newCfg)
        }));
    };

    return (0, a.jsx)(r.List, {
        isShowingDetail: true,
        searchBarPlaceholder: "Search power action...",
        children: (0, a.jsx)(r.List.Section, {
            title: "Power & Session Actions",
            subtitle: `${ITEMS.length} Actions`,
            children: ITEMS.map(item => {
                const customCmd = config[item.id];
                const hasCustomCmd = customCmd && customCmd.trim() !== "";
                const commandDisplay = hasCustomCmd ? customCmd.trim() : item.deeplink;

                return (0, a.jsx)(r.List.Item, {
                    id: item.id,
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    keywords: [item.title, item.subtitle, item.type, commandDisplay],
                    actions: (0, a.jsxs)(r.ActionPanel, {
                        children: [
                            (0, a.jsx)(r.Action, {
                                title: item.title,
                                icon: item.icon,
                                shortcut: { modifiers: ["ctrl"], key: item.shortcutKey },
                                onAction: () => triggerAction(item, customCmd)
                            }),
                            (0, a.jsx)(r.Action, {
                                title: "Configure Custom Commands (UI)",
                                icon: r.Icon.Gear,
                                shortcut: { modifiers: ["ctrl"], key: "c" },
                                onAction: openSettings
                            }),
                            (0, a.jsx)(r.Action.CopyToClipboard, {
                                title: "Copy Action Command",
                                content: commandDisplay
                            })
                        ]
                    }),
                    detail: (0, a.jsx)(r.List.Item.Detail, {
                        markdown: `### ${item.title}\n\n${item.description}\n\n---\n\n${
                            hasCustomCmd
                                ? `**Custom Command (Active):**\n\`\`\`bash\n$ ${customCmd.trim()}\n\`\`\``
                                : `**Default Target:**\n\`\`\`text\n${item.deeplink}\n\`\`\``
                        }`,
                        metadata: (0, a.jsxs)(r.List.Item.Detail.Metadata, {
                            children: [
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Label, {
                                    title: "Action Type",
                                    text: item.type
                                }),
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Label, {
                                    title: "Handler",
                                    text: hasCustomCmd ? "Custom Command" : "Vicinae Built-in"
                                }),
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Separator, {}),
                                (0, a.jsx)(r.List.Item.Detail.Metadata.TagList, {
                                    title: "Direct Hotkey",
                                    children: (0, a.jsx)(r.List.Item.Detail.Metadata.TagList.Item, {
                                        text: `Ctrl + ${item.shortcutKey.toUpperCase()}`,
                                        color: r.Color.Blue
                                    })
                                })
                            ]
                        })
                    })
                }, item.id);
            })
        })
    });
}
