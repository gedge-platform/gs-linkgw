# Copyright (C) 2023 by ETRI. All right reserved
# Version: 1.0
# Description
#   This docuement provide Gedge environment to support kubernetes live migration 
#   - go version: 1.15.1
#   - containerd version: 1.3.6
#   - runc version: 1.0.0-rc92
#   - kubernetes version: 1.19
#   - containerd-cri version: 1.1 
#
MAKEFLAGS += --silent
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SCRIPT_DIR := $(ROOT_DIR)/scripts
CONFIG_DIR := $(ROOT_DIR)/config
SUBM_DIR := $(ROOT_DIR)/submariner
TEST_DIR := $(ROOT_DIR)/test
BUILDS := $(shell find $(SCRIPT_DIR) -name 'build.sh' | sort)
CLEANS := $(shell find $(SCRIPT_DIR) -name 'clean.sh' | sort)
INSTALLS := $(shell find $(SCRIPT_DIR) -name '*_install_*.sh' | sort)
UNINSTALLS := $(shell find $(SCRIPT_DIR) -name '*_uninstall_*.sh' | sort)
ENVFILE := $(ROOT_DIR)/.env
SHELL := /bin/bash

.PHONY: \
all build clean install uninstall \
deploy_master deploy_master_info remove_master \
deploy_worker remove_worker \
deploy_migrater remove_migrater \
deploy_broker remove_broker deploy_broker_info \
join_broker

all:
	$(MAKE) config
	$(MAKE) clean
	$(MAKE) build

build:
	for item in $(BUILDS); do \
	  echo $$item; \
	  chmod 755 $$item || exit; \
	  source $(ENVFILE) && $$item || exit; \
	done

clean:
	$(SCRIPT_DIR)/clean.sh

install:
	for item in $(INSTALLS); do \
	  echo $$item; \
	  chmod 755 $$item || exit; \
	  source $(ENVFILE) && $$item || exit; \
	done

uninstall:
	for item in $(UNINSTALLS); do \
	  echo $$item; \
	  chmod 755 $$item || exit; \
	  source $(ENVFILE) && $$item || exit; \
	done

deploy_master:
	source $(ENVFILE) && $(SCRIPT_DIR)/deploy_master.sh

remove_master:
	source $(ENVFILE) && $(SCRIPT_DIR)/remove_master.sh

deploy_master_info:
	$(SCRIPT_DIR)/deploy_master_info.sh

deploy_worker:
	source $(ENVFILE) && $(SCRIPT_DIR)/deploy_worker.sh

remove_worker:
	source $(ENVFILE) && $(SCRIPT_DIR)/remove_worker.sh

join_master:
	$(SCRIPT_DIR)/master_join.sh

deploy_migrater:
	$(SCRIPT_DIR)/deploy_migrater.sh

remove_migrater:
	$(SCRIPT_DIR)/remove_migrater.sh

deploy_broker:
	$(SUBM_DIR)/deploy_broker.sh

remove_broker:
	$(SUBM_DIR)/remove_broker.sh	

deploy_broker_info:
	$(SUBM_DIR)/deploy_broker_info.sh

join_broker:
	$(SUBM_DIR)/join_broker.sh

help:
	@echo "make all"
	@echo "make build"
	@echo "make clean"
	@echo "make install"
	@echo "make uninstall"
	@echo "make deploy_master"
	@echo "make remove_master"
	@echo "make deploy_master_info"
	@echo "make deploy_worker"
	@echo "make deploy_migrater"
	@echo "make remove_migrater"
	@echo "make deploy_broker"
	@echo "make deploy_broker_info"
	@echo "make join_broker"
	@echo "make join_master"
	@echo "make remove_broker"
