SHELL := /bin/bash
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(ROOT)/scripts
ANALYZER := $(ROOT)/analyzer
RUN_ID ?=

.PHONY: doctor swift-smoke flutter-it-smoke flutter-patrol-smoke export report pack all

doctor:
	$(SCRIPTS)/doctor.sh

swift-smoke:
	$(SCRIPTS)/run_swift_ui.sh

flutter-it-smoke:
	$(SCRIPTS)/run_flutter_it.sh

flutter-patrol-smoke:
	$(SCRIPTS)/run_flutter_patrol.sh

export:
	$(SCRIPTS)/export_artifacts.sh $(RUN_ID)

report:
	$(ANALYZER)/analyze.sh $(RUN_ID)

pack:
	$(SCRIPTS)/pack_artifacts.sh $(RUN_ID)

all: doctor flutter-it-smoke report pack
