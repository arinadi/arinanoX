#!/bin/bash
# ═══════════════════════════════════════════
#  DroidDesk Dark Mobile Theme
#  Blackbird GTK + xfwm4 + Adwaita icons + 64px panel
# ═══════════════════════════════════════════

CONF_DIR="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$CONF_DIR"

echo ">>> Applying DroidDesk Dark Mobile Theme..."

# ── xsettings: Blackbird, Adwaita-dark icons, DPI 96 + Scale 2 ──
cat > "$CONF_DIR/xsettings.xml" << 'XEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Blackbird"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
    <property name="IconSizes" type="string" value="gtk-large=48,48:gtk-dialog=48,48:gtk-menus=48,48:gtk-toolbar=48,48"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="int" value="96"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Sans 12"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
    <property name="CursorThemeSize" type="int" value="24"/>
    <property name="DecorationLayout" type="string" value="icon,menu:minimize,maximize,close"/>
  </property>
  <property name="Xfce" type="empty">
    <property name="LastCustomDPI" type="int" value="96"/>
    <property name="SyncThemes" type="bool" value="true"/>
    <property name="WindowScalingFactor" type="int" value="2"/>
  </property>
</channel>
XEOF

# ── xfwm4: Blackbird (has xfwm4 theme), center, no compositing ──
cat > "$CONF_DIR/xfwm4.xml" << 'WMEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="theme" type="string" value="Default-xhdpi"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="placement_mode" type="string" value="center"/>
    <property name="borderless_maximize" type="bool" value="true"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="title_font" type="string" value="Sans Bold 11"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="true"/>
    <property name="wrap_windows" type="bool" value="true"/>
  </property>
</channel>
WMEOF

# ── Panel: 64px dark, Whisker Menu ──
cat > "$CONF_DIR/xfce4-panel.xml" << 'PEOF'
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
        <value type="int" value="4"/><value type="int" value="5"/><value type="int" value="6"/>
        <value type="int" value="7"/><value type="int" value="8"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu"/>
    <property name="plugin-2" type="string" value="tasklist">
      <property name="show-labels" type="bool" value="false"/>
      <property name="grouping" type="uint" value="1"/>
      <property name="icon-size" type="uint" value="48"/>
    </property>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
    </property>
    <property name="plugin-4" type="string" value="pager"/>
    <property name="plugin-5" type="string" value="pulseaudio">
      <property name="show-notifications" type="bool" value="false"/>
    </property>
    <property name="plugin-6" type="string" value="systray">
      <property name="icon-size" type="uint" value="32"/>
    </property>
    <property name="plugin-7" type="string" value="clock">
      <property name="mode" type="uint" value="4"/>
    </property>
    <property name="plugin-8" type="string" value="actions"/>
  </property>
</channel>
PEOF

# ── Desktop: almost-black, no icons ──
cat > "$CONF_DIR/xfce4-desktop.xml" << 'DEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-style" type="int" value="0"/>
        <property name="color-style" type="int" value="0"/>
        <property name="rgba1" type="array">
          <value type="double" value="0.05"/>
          <value type="double" value="0.05"/>
          <value type="double" value="0.05"/>
          <value type="double" value="1.0"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="primary" type="bool" value="false"/>
  </property>
</channel>
DEOF

echo ""
echo "╔═══════════════════════════════════╗"
echo "║  🌙 Dark Mobile Theme Applied     ║"
echo "╠═══════════════════════════════════╣"
echo "║  GTK:   Blackbird (dark)          ║"
echo "║  Icons: Adwaita (dark)            ║"
echo "║  WM:    Default-xhdpi (large borders)║"
echo "║  Panel: 64px dark, 8 plugins      ║"
echo "║  DPI:   96 + Scale 2x             ║"
echo "║  Font:  Sans 12                   ║"
echo "║  Cursor: 24px (2x → 48px)         ║"
echo "╠═══════════════════════════════════╣"
echo "║  Restart XFCE to apply            ║"
echo "╚═══════════════════════════════════╝"
