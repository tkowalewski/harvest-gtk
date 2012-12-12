#!/bin/bash

# nemiver ./harvest-gtk
# gdb ./harvest-gtk

valac-0.18 -g --save-temps --pkg gee-1.0 --pkg gtk+-3.0 --pkg libxml-2.0 --pkg libsoup-2.4 ./harvest-gtk.vala