# -*- make -*-
PROJ := $(notdir $(PWD))
SOURCES := $(wildcard *.ino wildcard Plugins/*.c wildcard Config/*.c)

CFGFILE := arduino-cli.yaml
CLI := arduino-cli --config-file $(CFGFILE)
PLATFORM := arduino:avr
BOARDS := arduino/package_index.json

# PORT can be overridden by the environment or on the command line. E.g.:
# export PORT=/dev/ttyUSB2; make upload, or: make upload PORT=/dev/ttyUSB2
PORT ?= /dev/ttyACM0

INO = $(PROJ).ino
FILES = $(wildcard $(PLUGINDIR)/*.c $(CONFIGDIR)/*.c)
BOARD = $(PLATFORM):mega
FQBN = $(BOARD)
IMAGE = build/$(subst :,.,$(BOARD))/$(INO).hex
CFLAGS = --build-property "build.extra_flags=\"-DSKETCH_PATH=$(PWD)\""

binaries: $(IMAGE)

platform: $(BOARDS)

clean:
	rm -f *~

distclean: clean
	rm -rf arduino build libraries staging arduino-cli.yaml

$(CFGFILE):
	$(CLI) config init --dest-file $(CFGFILE)
	$(CLI) config set directories.data $(PWD)/arduino
	$(CLI) config set directories.downloads $(PWD)/staging
	$(CLI) config set directories.user $(PWD)
	$(CLI) config set sketch.always_export_binaries true

$(BOARDS): | $(CFGFILE)
	$(CLI) core update-index
	$(CLI) core install $(PLATFORM)

$(IMAGE): $(BOARDS) $(LIBRARIES) $(SOURCES)
	$(CLI) compile --fqbn=$(FQBN) --warnings default --verbose $(CFLAGS)

upload: $(IMAGE)
	$(CLI) upload -p $(PORT) --fqbn=$(FQBN) .

.PHONY: binaries platform clean distclean upload

### Allow customization through a local Makefile: Makefile-local.mk

# Include the local make file, if it exists
-include Makefile-local.mk
