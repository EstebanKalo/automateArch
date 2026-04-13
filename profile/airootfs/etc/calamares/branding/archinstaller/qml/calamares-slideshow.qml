import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: 800
    height: 400

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Installing Arch Linux..."
            font.pixelSize: 28
            font.bold: true
            color: "#FFFFFF"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "A clean, minimal system is being set up.\nOnce complete, you'll have a blank canvas to customize."
            font.pixelSize: 16
            color: "#CCCCCC"
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.4
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Tip: After rebooting, install a desktop environment:\n  sudo pacman -S xfce4 lightdm lightdm-gtk-greeter\n  sudo systemctl enable lightdm"
            font.pixelSize: 13
            font.family: "monospace"
            color: "#999999"
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.6
        }
    }
}
