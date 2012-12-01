prefix=/usr/local
EXEC_FILES=harvest-gtk
ICON_FILES=harvest-gtk.png
DESKTOP_FILES=harvest-gtk.desktop

all:
	@echo "Usage:"
	@echo "		make install"
	@echo "		make uninstall"

install:
	install -d -m 0755 $(prefix)/bin
	install -m 0755 $(EXEC_FILES) $(prefix)/bin
	install -m 0755 $(ICON_FILES) /usr/share/icons
	install -m 0755 $(DESKTOP_FILES) /usr/share/applications

uninstall:
	test -d $(prefix)/bin && cd $(prefix)/bin && rm -f $(EXEC_FILES) && rm -f $(ICON_FILES) && rm -f $(DESKTOP_FILES)