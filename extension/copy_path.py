"""Nautilus extension: adds "Copy Path" (Ctrl+Shift+C) to the file and background context menus.

Install to ~/.local/share/nautilus-python/extensions/ (requires python3-nautilus).
"""

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
from gi.repository import Gdk, GObject, Gtk, Nautilus

ACCEL = "<Control><Shift>c"
FILE_ITEM = "CopyPathExtension-CopyPath"
FOLDER_ITEM = "CopyPathExtension-CopyFolderPath"

# Nautilus names extension actions "view.extension_extensions_<idx>_<item name>",
# where idx is the item's position among *all* extensions' items, so cover a range.
MAX_IDX = 16

# Nautilus rebuilds its context menus (calling get_file_items and then
# get_background_items) on every selection change, but never removes old
# actions. Remember the latest state so the shortcut always copies the
# current selection, or the current folder when nothing is selected.
_selection = []
_folder = None
_accels_set = False


def _ensure_accels():
    global _accels_set
    if _accels_set:
        return
    app = Gtk.Application.get_default()
    if app is None:
        return
    for idx in range(MAX_IDX):
        for name in (FILE_ITEM, FOLDER_ITEM):
            app.set_accels_for_action(f"view.extension_extensions_{idx}_{name}", [ACCEL])
    _accels_set = True


def _path_of(file_info):
    location = file_info.get_location()
    path = location.get_path() if location else None
    return path or file_info.get_uri()


def _copy_to_clipboard(text):
    display = Gdk.Display.get_default()
    if display is not None:
        display.get_clipboard().set(text)


def _on_activate(_item):
    targets = _selection or ([_folder] if _folder else [])
    if targets:
        _copy_to_clipboard("\n".join(_path_of(f) for f in targets))


class CopyPathExtension(GObject.GObject, Nautilus.MenuProvider):
    def get_file_items(self, files):
        global _selection
        _selection = list(files)
        _ensure_accels()
        if not files:
            return []
        item = Nautilus.MenuItem(
            name=FILE_ITEM,
            label="Copy Path" if len(files) == 1 else "Copy Paths",
            tip="Copy the full path to the clipboard",
        )
        item.connect("activate", _on_activate)
        return [item]

    def get_background_items(self, folder):
        global _folder
        _folder = folder
        _ensure_accels()
        item = Nautilus.MenuItem(
            name=FOLDER_ITEM,
            label="Copy Path",
            tip="Copy this folder's full path to the clipboard",
        )
        item.connect("activate", _on_activate)
        return [item]
