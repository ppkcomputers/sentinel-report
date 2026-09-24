import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    Process {
        id: apiProcess

        property string rawResponse: ""

        stdout: StdioCollector {
            onStreamFinished: {
                apiProcess.rawResponse = this.text
                console.log("[Sentinel Debug] STDOUT Output:\n", this.text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 0) {
                    console.log("[Sentinel Debug] STDERR Output:\n", this.text)
                }
            }
        }

        onExited: (code, status) => {
            console.log("[Sentinel Debug] Process exited with code:", code, "status:", status)

            if (code === 0) {
                if (apiProcess.rawResponse.includes("ipAddress") ||
                    apiProcess.rawResponse.includes("submission") ||
                    apiProcess.rawResponse.includes("Zone") ||
                    apiProcess.rawResponse.includes("data") ||
                    apiProcess.rawResponse.includes("name")) {
                    statusText.text = "Received & Verified by APIs!"
                    statusText.color = "#81C784"
                    } else if (apiProcess.rawResponse.length > 0) {
                        statusText.text = "Dispatched: " + apiProcess.rawResponse.substring(0, 40) + "..."
                        statusText.color = "#FFD54F"
                    } else {
                        statusText.text = "Dispatched (No status payload)"
                        statusText.color = "#FFD54F"
                    }
            } else {
                statusText.text = "One or more API submissions failed."
                statusText.color = "#E57373"
            }
            sendButton.enabled = true
        }
    }

    // Process helper to handle wl-paste on right-click
    Process {
        id: pasteProcess
        command: ["wl-paste", "--no-newline"]

        stdout: StdioCollector {
            onStreamFinished: {
                var pastedText = this.text;
                console.log("[Sentinel Debug] Clipboard contents read:", pastedText);
                if (pastedText.length > 0) {
                    targetInput.text = pastedText;
                    targetInput.forceActiveFocus();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 0) {
                    console.log("[Sentinel Debug] wl-paste error:", this.text);
                }
            }
        }
    }

    PanelWindow {
        id: window
        anchors.top: true
        anchors.right: true
        exclusiveZone: 0
        implicitHeight: 850
        implicitWidth: 800
        color: "transparent"

        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            id: body
            x: window.implicitWidth
            y: 20
            width: parent.width - 40
            height: parent.height - 40
            radius: 20
            clip: true

            color: Qt.rgba(0, 0, 0, 0.85)
            border.width: 3
            border.color: "#535337"

            Behavior on x {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }

            // Local Background Image
            Image {
                anchors.fill: parent
                source: "./sentinel.jpeg"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.35
            }

            Column {
                anchors.fill: parent
                anchors.margins: 32
                spacing: 14

                Text {
                    text: "Sentinel Threat Reporter"
                    color: "#FFFFFF"
                    font.bold: true
                    font.pixelSize: 28
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // Input Field Container
                Rectangle {
                    width: parent.width
                    height: 64
                    color: Qt.rgba(0.1, 0.1, 0.1, 0.85)
                    border.color: targetInput.activeFocus ? "#7E7E52" : "#333333"
                    border.width: 2
                    radius: 10

                    TextInput {
                        id: targetInput
                        anchors.fill: parent
                        anchors.margins: 16
                        color: "#FFFFFF"
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 22
                        clip: true
                        selectByMouse: true
                        focus: true

                        Text {
                            text: "Enter URL or IP address..."
                            color: "#888888"
                            font.pixelSize: 22
                            visible: !targetInput.text && !targetInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        onAccepted: sendButton.triggerSend()

                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: {
                                console.log("[Sentinel Debug] Right-click paste triggered");
                                targetInput.forceActiveFocus();
                                pasteProcess.running = true;
                            }
                        }
                    }
                }

                // Centered Normal Size Submit Button
                Rectangle {
                    id: sendButton
                    width: 220
                    height: 48
                    radius: 10
                    enabled: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: !enabled ? "#2A2A2A" : (buttonArea.pressed ? "#3C3C27" : (buttonArea.containsMouse ? "#535337" : "#42422C"))

                    function triggerSend() {
                        var target = targetInput.text.trim();
                        console.log("[Sentinel Debug] Triggering send for target:", target);
                        if (target.length > 0) {
                            sendButton.enabled = false;
                            statusText.text = "Submitting to APIs...";
                            statusText.color = "#CCCCCC";
                            root.dispatchApis(target);
                        } else {
                            console.log("[Sentinel Debug] Target input is empty. Skipping dispatch.");
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: sendButton.enabled ? "Submit" : "Submitting..."
                        color: sendButton.enabled ? "#FFFFFF" : "#777777"
                        font.bold: true
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: buttonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sendButton.triggerSend()
                    }
                }

                // Active Automated Submit Target Services
                Text {
                    text: "Submits to: Google Web Risk • Kaspersky OpenTIP • AbuseIPDB (IPs)"
                    color: "#AAAAAA"
                    font.pixelSize: 13
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    id: statusText
                    text: ""
                    font.pixelSize: 18
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: parent.width
                    height: 2
                    color: "#333333"
                }

                Text {
                    text: "Manual Web Form Portals:"
                    color: "#AAAAAA"
                    font.pixelSize: 22
                    font.bold: true
                }

                ScrollView {
                    width: parent.width
                    height: 310
                    clip: true

                    Column {
                        width: parent.width
                        spacing: 10

                        Repeater {
                            model: [
                                { name: "AbuseIPDB Check", url: "https://www.abuseipdb.com/check/" },
                                { name: "Google Safe Browsing", url: "https://safebrowsing.google.com/safebrowsing/report_phish/?url=" },
                                { name: "Microsoft WDSI", url: "https://www.microsoft.com/en-us/wdsi/support/report-unsafe-site-guest?url=" },
                                { name: "McAfee SiteLookup", url: "https://sitelookup.mcafee.com/en/feedback/url?action=checksingle&url=" },
                                { name: "Spamhaus", url: "https://www.spamhaus.org/lookup/" },
                                { name: "Palo Alto Networks", url: "https://urlfiltering.paloaltonetworks.com/" },
                                { name: "Netcraft Web", url: "https://report.netcraft.com/report?url=" },
                                { name: "Trend Micro", url: "https://global.sitesafety.trendmicro.com/index.php" },
                                { name: "Symantec SiteReview", url: "https://sitereview.symantec.com/#/" }
                            ]

                            delegate: Item {
                                width: parent.width
                                height: 34

                                property string target: targetInput.text.trim()
                                property string fullUrl: modelData.url + encodeURIComponent(target)

                                Rectangle {
                                    id: linkBg
                                    anchors.fill: parent
                                    radius: 6
                                    color: linkArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                                    scale: linkArea.pressed ? 0.96 : (linkArea.containsMouse ? 1.02 : 1.0)
                                    opacity: linkArea.pressed ? 0.6 : 1.0

                                    Behavior on scale {
                                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation { duration: 100 }
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "• " + modelData.name
                                        color: linkArea.containsMouse ? "#B3E5FC" : "#81D4FA"
                                        font.pixelSize: 19
                                        font.underline: linkArea.containsMouse
                                    }

                                    MouseArea {
                                        id: linkArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally(parent.parent.fullUrl)
                                    }
                                }
                            }
                        }
                    }
                }

                // Centered Normal Size Close Button
                Rectangle {
                    id: closeButton
                    width: 140
                    height: 36
                    radius: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: closeArea.pressed ? "#3C3C27" : (closeArea.containsMouse ? "#535337" : "#42422C")

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }
        }

        Timer {
            interval: 50
            running: true
            repeat: false
            onTriggered: {
                body.x = 20;
                targetInput.forceActiveFocus();
            }
        }
    }

/////////////////////////////////////////////////
//Include your own api key for these 3 websites//
/////////////////////////////////////////////////

    function dispatchApis(target) {
        apiProcess.rawResponse = "";

        var abuseKey     = "put your api key";
        var googleKey    = "put your api key";
        var kasperskyKey = "put your api key";

        var isIp = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(target);

        var formattedUri = target;
        if (!/^https?:\/\//i.test(target)) {
            formattedUri = "http://" + target;
        }

        var commands = [];

        // 1. AbuseIPDB Request (ONLY when target is an IP)
        if (isIp) {
            var abuseCmd = "curl -s -X POST https://api.abuseipdb.com/api/v2/report " +
            "-H 'Key: " + abuseKey + "' " +
            "-H 'Accept: application/json' " +
            "--data-urlencode \"ip=" + target + "\" " +
            "--data-urlencode 'categories=18,22' " +
            "--data-urlencode 'comment=Submitted via SentinelReport OSD'";
            commands.push(abuseCmd);
        }

        // 2. Google Web Risk Request
        var googlePayload = JSON.stringify({ "submission": { "uri": formattedUri } });
        var googleCmd = "curl -s -X POST 'https://webrisk.googleapis.com/v1/uris:submission?key=" + googleKey + "' " +
        "-H 'Content-Type: application/json' " +
        "-d '" + googlePayload.replace(/'/g, "'\\''") + "'";
        commands.push(googleCmd);

        // 3. Kaspersky OpenTIP Request
        var kasperskyType = isIp ? "ip" : "url";
        var kasperskyTarget = isIp ? target : formattedUri;
        var kasperskyCmd = "curl -s -X GET 'https://opentip.kaspersky.com/api/v1/search/" + kasperskyType + "?request=" + encodeURIComponent(kasperskyTarget) + "' " +
        "-H 'x-api-key: " + kasperskyKey + "'";
        commands.push(kasperskyCmd);

        var fullBashCommand = commands.join(" ; echo '' ; ");
        console.log("[Sentinel Debug] Executing command string:\n", fullBashCommand);

        apiProcess.command = ["bash", "-c", fullBashCommand];
        apiProcess.running = true;
    }
}
