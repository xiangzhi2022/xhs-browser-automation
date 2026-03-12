#!/usr/bin/env python3
import sys
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GdkPixbuf

if len(sys.argv) != 2:
    print('usage: set_image_clipboard.py /path/to/image', file=sys.stderr)
    sys.exit(2)

path = sys.argv[1]
pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)
display = Gdk.Display.get_default()
if display is None:
    print('no GDK display available', file=sys.stderr)
    sys.exit(1)
clipboard = Gtk.Clipboard.get_default(display)
clipboard.set_image(pixbuf)
clipboard.store()
# keep a short main loop turn so clipboard owner updates cleanly
while Gtk.events_pending():
    Gtk.main_iteration_do(False)
print('CLIPBOARD_IMAGE_SET')
