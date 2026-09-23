# Sentinel Threat Reporter

![Sentinel Banner](sentinel.png)

**Sentinel Threat Reporter** is a desktop On-Screen Display (OSD) and threat intelligence dispatch widget built with [Quickshell](https://outfoxxed.me/quickshell/) and QML. Designed for Wayland compositors (such as Hyprland), it allows security analysts, sysadmins, and Linux enthusiasts to quickly report or query malicious URLs and IP addresses across multiple security APIs and manual web portals simultaneously.

---

## Features

- **Automated API Submissions:**
  - **Google Web Risk:** Submits suspicious URIs directly via the Google Web Risk Submission API.
  - **Kaspersky OpenTIP:** Automatically queries threat analysis for submitted IP addresses and URLs.
  - **AbuseIPDB:** Automatically dispatches abuse reports for valid IPv4 addresses.
- **Wayland Clipboard Integration:**
  - Fast paste capability using `wl-paste` (right-click anywhere in the input field to paste copied targets).
- **Manual Web Portal Shortcuts:**
  - Pre-configured dynamic links to popular manual report and lookup tools including Safe Browsing, Microsoft WDSI, Spamhaus, Netcraft, Palo Alto, Symantec, and Trend Micro.
- **Native Desktop Overlay:**
  - Built using Wayland Layer Shell protocol (`wlr-layer-shell`) with smooth animated panel transitions.

---

## Dependencies

Before running Sentinel Threat Reporter, ensure you have the following installed on your system:

- **Quickshell** (Compiled with Wayland support)
- **`curl`** (For handling HTTP requests to security APIs)
- **`wl-clipboard`** (Provides `wl-paste` for clipboard interactions)
- **`bash`** (For executing combined command pipelines)

On Arch-based distributions (e.g., Arch Linux, CachyOS), you can install the system utilities via `pacman`:

```bash
sudo pacman -S curl wl-clipboard bash
