#!/bin/bash
# 📱 DroidDesk XFCE Pre-config Applier
# Focus: Panel (64px), WM (Center/xhdpi), GTK Settings (DPI 140, Large Cursor)

# 1. Ensure directories exist
CONF_DIR="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$CONF_DIR"

# 2. Apply Panel Config (64px bottom, dark mode, tasklist with icons only)
cat <<EOF > "$CONF_DIR/xfce4-panel.xml"
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="64"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/><value type="int" value="2"/><value type="int" value="3"/>
        <value type="int" value="4"/><value type="int" value="6"/><value type="int" value="8"/>
        <value type="int" value="10"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="tasklist">
      <property name="show-labels" type="bool" value="false"/>
      <property name="grouping" type="uint" value="1"/>
    </property>
    <property name="plugin-3" type="string" value="separator"><property name="expand" type="bool" value="true"/></property>
    <property name="plugin-4" type="string" value="pager"/>
    <property name="plugin-6" type="string" value="systray"/>
    <property name="plugin-8" type="string" value="clock">
      <property name="mode" type="uint" value="4"/>
      <property name="timezone" type="string" value="Asia/Jakarta"/>
    </property>
    <property name="plugin-10" type="string" value="actions"/>
  </property>
</channel>
EOF

# 3. Apply Window Manager Config (Default-xhdpi theme, centered placement)
cat <<EOF > "$CONF_DIR/xfwm4.xml"
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Default-xhdpi"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="placement_mode" type="string" value="center"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="borderless_maximize" type="bool" value="true"/>
    <property name="title_alignment" type="string" value="right"/>
    <property name="title_font" type="string" value="Sans Bold 9"/>
  </property>
</channel>
EOF

# 4. Apply Settings (DPI 140, Large Cursor 64px)
cat <<EOF > "$CONF_DIR/xsettings.xml"
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Xft" type="empty">
    <property name="DPI" type="int" value="140"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="Adwaita"/>
    <property name="CursorThemeSize" type="int" value="64"/>
    <property name="DecorationLayout" type="string" value="icon,menu:minimize,maximize,close"/>
  </property>
  <property name="Xfce" type="empty">
    <property name="LastCustomDPI" type="int" value="140"/>
  </property>
</channel>
EOF

# 5. Apply Solid Black Wallpaper
cat <<EOF > "$CONF_DIR/xfce4-desktop.xml"
<?xml version="1.1" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-style" type="int" value="0"/>
        <property name="color-style" type="int" value="0"/>
        <property name="rgba1" type="array">
          <value type="double" value="0.0"/>
          <value type="double" value="0.0"/>
          <value type="double" value="0.0"/>
          <value type="double" value="1.0"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

echo ">>> DroidDesk pre-config applied. Please restart XFCE session."
