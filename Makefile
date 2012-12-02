BIN_DIR=/usr/local/bin
BIN_FILES=harvest-gtk
ICON_DIR=/usr/share/icons
ICON_FILES=harvest-gtk.png
DESKTOP_DIR=/usr/share/applications
DESKTOP_FILES=harvest-gtk.desktop

all:
	@echo "Usage:"
	@echo "		make install"
	@echo "		make uninstall"

install:
	install -d -m 0755 $(BIN_DIR)
	install -m 0755 $(BIN_FILES) $(BIN_DIR)
	install -d -m 0755 $(ICON_DIR)
	install -m 0755 $(ICON_FILES) $(ICON_DIR)
	install -d -m 0755 $(DESKTOP_DIR)
	install -m 0755 $(DESKTOP_FILES) $(DESKTOP_DIR)

uninstall:
	test -d $(BIN_DIR) && cd $(BIN_DIR) && rm -f $(BIN_FILES)
	test -d $(ICON_DIR) && cd $(ICON_DIR) && rm -f $(ICON_FILES)
	test -d $(DESKTOP_DIR) && cd $(DESKTOP_DIR) && rm -f $(DESKTOP_FILES)