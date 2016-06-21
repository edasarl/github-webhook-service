MAKEFLAGS = s

project := $(shell node -p "require('./package').name")
$(info $(project))

ifneq "$(findstring $(NODE_ENV),staging production)" ""
SITE = $(HOME)/public_nodejs/$(project)/$(NODE_ENV)
else
SITE = $(CURDIR)
NODE_ENV = development
endif

$(info NODE_ENV $(NODE_ENV))
$(info SITE $(SITE))

PUBLIC_FILES="Makefile app.js bin *.json"

.PHONY: copy
copy:
ifneq "$(CURDIR)" "$(SITE)"
	mkdir -p $(SITE)
	rsync -arcv --exclude="node_modules" --exclude="service" --exclude="private" --exclude="public/google*.html" --exclude="cache" --exclude="public/uploads" --exclude="public/bundles" --delete "${PUBLIC_FILES}" ${SITE}/
endif

.PHONY: node_modules
node_modules:
	cd $(SITE); \
	npm prune && npm install --build-from-source;

.PHONY: install
install: copy node_modules

.PHONY: restart
restart:
	systemctl --user restart $(project)-$(NODE_ENV).service

.PHONY: service
service:
	mkdir -p $(SITE)/service
	sed -e 's/$$NODE_ENV/$(NODE_ENV)/' -e 's|$$SITE|$(SITE)|' \
		service/template.service > $(SITE)/service/$(project)-$(NODE_ENV).service

.PHONY: enable
enable: service
	systemctl --user enable $(SITE)/service/$(project)-$(NODE_ENV).service

