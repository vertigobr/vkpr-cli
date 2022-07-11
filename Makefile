.DEFAULT_GOAL := help
vkpr_dir = ${HOME}/.vkpr
current_dir = $(shell pwd)

export PATH := ${vkpr_dir}/bin:${PATH}

.PHONY: init
init:
	@rit delete repo --name="vkpr-cli"
	@rit add workspace --name "vkpr-formulas" --path ${current_dir}
	@rit vkpr init

.PHONY: sync-release
sync-release:
	@rit add repo --provider="Github" --name="vkpr-cli" --repoUrl="https://github.com/vertigobr/vkpr-cli"

.PHONY: reload-workspace
reload-workspace:
	@rit delete workspace --name="Vkpr-Formulas"
	@rit add workspace --name vkpr-formulas --path ${current_dir}

.PHONY: lint
application_files = $(shell find ${current_dir}/vkpr/$(app) -name 'formula.sh' -type f 2> /dev/null)
lint:
	@shellcheck -S warning ${application_files} 2> /dev/null || (echo "Invalid application name"; exit 1)

.PHONY: test
bats_path = ${vkpr_dir}/bats/bin/bats
test:
ifneq (,"$(wildcard $(${current_dir}/vkpr-test/$(app)/$(app).bats))")
	@${bats_path} ${current_dir}/vkpr-test/$(app)/$(app).bats
endif

.PHONY: clean
clean:
	@rit delete workspace --name="Vkpr-Formulas"
	@rm -rf ${vkpr_dir}

.PHONY: help
help:
	@echo 'Makefile to assist with casual vkpr tasks                                 							'
	@echo '                                                                          							'
	@echo 'Usage:                                                                    							'
	@echo '   make                                Runs rules specified under all     							'
	@echo '   make init         		       Initializes VKPR so that it syncs with the local repository   '
	@echo '   make sync-release                   Sync VKPR with repository releases       					  	'
	@echo '   make reload-workspace               Reload the workspace (Recommended when updating/creating functions)'
	@echo '   make test app=value                 Test formula scripts   										'
	@echo '   make lint app=value                 Lint formula scripts         									'
	@echo '   make clean                          Clean all VKPR content locally                 				'
	@echo '                                                                          							'
