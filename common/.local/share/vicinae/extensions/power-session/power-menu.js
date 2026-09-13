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

async function triggerAction(item) {
    await (0, r.closeMainWindow)();
    await (0, r.open)(item.deeplink);
}

const ITEMS = [
    {
        id: "lock",
        title: "Lock Screen",
        subtitle: "Lock session",
        icon: r.Icon.Lock,
        deeplink: "vicinae://launch/power/lock",
        type: "Security / Session",
        shortcutKey: "l",
        description: "Locks the current desktop session using Vicinae's native lock provider."
    },
    {
        id: "suspend",
        title: "Suspend / Sleep",
        subtitle: "Low-power sleep",
        icon: r.Icon.Moon,
        deeplink: "vicinae://launch/power/suspend",
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
        type: "System Lifecycle",
        shortcutKey: "r",
        description: "Safely restarts the operating system and reboots the machine."
    },
    {
        id: "power-off",
        title: "Power Off / Shutdown",
        subtitle: "Shut down system",
        icon: r.Icon.Power,
        deeplink: "vicinae://launch/power/power-off",
        type: "System Lifecycle",
        shortcutKey: "s",
        description: "Safely terminates processes, syncs storage, and powers down hardware."
    },
    {
        id: "logout",
        title: "Log Out",
        subtitle: "Exit current session",
        icon: r.Icon.Door,
        deeplink: "vicinae://launch/power/logout",
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
        type: "Power State",
        shortcutKey: "h",
        description: "Writes active memory state to disk swap image and powers down."
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
                                onAction: () => triggerAction(item)
                            }),
                            (0, a.jsx)(r.Action.CopyToClipboard, {
                                title: "Copy Vicinae Deeplink",
                                content: item.deeplink
                            })
                        ]
                    }),
                    detail: (0, a.jsx)(r.List.Item.Detail, {
                        markdown: `### ${item.title}\n\n${item.description}\n\n---\n\n\`\`\`text\n${item.deeplink}\n\`\`\``,
                        metadata: (0, a.jsxs)(r.List.Item.Detail.Metadata, {
                            children: [
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Label, {
                                    title: "Action Type",
                                    text: item.type
                                }),
                                (0, a.jsx)(r.List.Item.Detail.Metadata.Label, {
                                    title: "Vicinae Target",
                                    text: item.deeplink.replace("vicinae://launch/", "")
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
                }, item.id)
            ))
        })
    });
}
