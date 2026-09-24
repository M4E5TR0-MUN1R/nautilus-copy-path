"""Nautilus extension: adds "Copy Path" to the file and background context menus.

Install to ~/.local/share/nautilus-python/extensions/ (requires python3-nautilus).
"""

import gi

gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, GObject, Nautilus


def _path_of(file_info):
    location = file_info.get_location()
    path = location.get_path() if location else None
    return path or file_info.get_uri()


def _copy_to_clipboard(text):
    display = Gdk.Display.get_default()
    if display is not None:
        display.get_clipboard().set(text)


class CopyPathExtension(GObject.GObject, Nautilus.MenuProvider):
    def _on_activate(self, _item, files):
        _copy_to_clipboard("\n".join(_path_of(f) for f in files))

    def get_file_items(self, files):
        if not files:
            return []
        item = Nautilus.MenuItem(
            name="CopyPathExtension::CopyPath",
            label="Copy Path" if len(files) == 1 else "Copy Paths",
            tip="Copy the full path to the clipboard (Ctrl+Shift+C)",
        )
        item.connect("activate", self._on_activate, files)
        return [item]

    def get_background_items(self, folder):
        item = Nautilus.MenuItem(
            name="CopyPathExtension::CopyFolderPath",
            label="Copy Path",
            tip="Copy this folder's full path to the clipboard",
        )
        item.connect("activate", self._on_activate, [folder])
        return [item]
