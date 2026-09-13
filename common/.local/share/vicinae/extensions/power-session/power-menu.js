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
var cp = require("node:child_process");

function runCommand(cmd, title) {
    (0, r.closeMainWindow)();
    cp.exec(cmd, (err) => {
        if (err) {
            (0, r.showToast)({
                style: r.Toast.Style.Failure,
                title: "Failed to execute action",
                message: err.message
            });
        }
    });
}

const ITEMS = [
    {
        id: "lock",
        title: "Lock Screen",
        subtitle: "Lock session",
        icon: r.Icon.Lock,
        action: "hyprlock",
        command: "hyprlock",
        type: "Security / Session",
        target: "Display Compositor",
        shortcutKey: "l",
        description: "Locks the current Hyprland session and displays the secure lockscreen."
    },
    {
        id: "suspend",
        title: "Suspend / Sleep",
        subtitle: "Low power mode",
        icon: r.Icon.Moon,
        action: "systemctl suspend",
        command: "systemctl suspend",
        type: "Power State",
        target: "Systemd ACPI S3",
        shortcutKey: "u",
        description: "Places the computer into low-power RAM sleep mode."
    },
    {
        id: "reboot",
        title: "Restart / Reboot",
        subtitle: "Restart computer",
        icon: r.Icon.ArrowClockwise,
        action: "systemctl reboot",
        command: "systemctl reboot",
        type: "System Lifecycle",
        target: "Full Hardware Reset",
        shortcutKey: "r",
        description: "Gracefully stops all running services and restarts the operating system."
    },
    {
        id: "poweroff",
        title: "Power Off / Shutdown",
        subtitle: "Shut down system",
        icon: r.Icon.Power,
        action: "systemctl poweroff",
        command: "systemctl poweroff",
        type: "System Lifecycle",
        target: "ACPI Power State S5",
        shortcutKey: "s",
        description: "Safely syncs filesystems, terminates processes, and powers off the machine."
    },
    {
        id: "logout",
        title: "Log Out",
        subtitle: "Exit Hyprland",
        icon: r.Icon.Door,
        action: "hyprctl dispatch exit",
        command: "hyprctl dispatch exit",
        type: "Compositor Session",
        target: "Display Server",
        shortcutKey: "e",
        description: "Ends your current Hyprland desktop session and returns to login manager/TTY."
    },
    {
        id: "hibernate",
        title: "Hibernate",
        subtitle: "Save state to disk",
        icon: r.Icon.HardDrive,
        action: "systemctl hibernate",
        command: "systemctl hibernate",
        type: "Power State",
        target: "Disk Swap Image (S4)",
        shortcutKey: "h",
        description: "Writes active RAM state to swap disk and completely powers down."
    }
];

function PowerMenu() {
    return (0, a.jsx)(r.List, {
        isShowingDetail: true,
        searchBarPlaceholder: "Search power action...",
        children: (0, a.jsx)(r.List.Section, {
            title: "Power & Session Actions",
            subtitle: `${ITEMS.length} Actions`,
            children: ITEMS.map(item => (
                (0, a.jsx)(r.List.Item, {
                    id: item.id,
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    keywords: [item.title, item.subtitle, item.type],
                    actions: (0, a.jsxs)(r.ActionPanel, {
                        children: [
                            (0, a.jsx)(r.Action, {
                                title: item.title,
                                icon: item.icon,
                                shortcut: { modifiers: ["ctrl"], key: item.shortcutKey },
                                onAction: () => runCommand(item.action, item.title)
                            }),
                            (0, a.jsx)(r.Action.CopyToClipboard, {
                                title: "Copy Shell Command",
                                content: item.command
                            })
                        ]
                    }),
                    detail: (0, a.jsx)(r.List.Item.Detail, {
                        markdown: `### ${item.title}\n\n${item.description}\n\n---\n\n\`\`\`bash\n$ ${item.command}\n\`\`\``,
                        metadata: (0, a.jsxs)(r.List.Item.Detail.Metadata, {
                            children: [
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Label, {
                                    title: "Action Type",
                                    text: item.type
                                }),
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Label, {
                                    title: "Target Subsystem",
                                    text: item.target
                                }),
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Separator, {}),
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Label, {
                                    title: "Command",
                                    text: item.command
                                }),
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
                }, item.id)
            ))
        })
    });
}
