BIN = ./node_modules/.bin
SRC = $(wildcard src/*.coffee)
LIB = $(SRC:src/%.coffee=lib/%.js)
DOC = docs
SPEC = $(wildcard specs/*Spec.coffee) $(wildcard specs/lib/*Spec.coffee) $(wildcard specs/acceptance/*.coffee)

MOCHA_REPORTERS = "spec=- html-cov=coverage/html-cov.html json-cov=coverage/json-cov.json mocha-lcov-reporter=coverage/coverage.lcov"


build: $(LIB)

lib/%.js: src/%.coffee
	@mkdir -p $(@D)
	@$(BIN)/coffee -bcp $< > $@


test: build
	@mkdir -p coverage
	COVERAGE=1 \
	  NODE_ENV=test \
		multi=$(MOCHA_REPORTERS) \
		$(BIN)/mocha \
		--compilers coffee:coffee-script/register \
		--require specs/loader.js \
		--reporter mocha-multi \
		--ui bdd \
		$(SPEC)


coverall: test
	@cat coverage/coverage.lcov | ./node_modules/coveralls/bin/coveralls.js


doc:
	VERSION=`node -pe "require('./package.json').version"` && \
		$(BIN)/yuidoc \
		-e .coffee \
		--syntaxtype coffee \
		--project-version "$$VERSION" \
		-o $(DOC) \
		./src


publish-doc: doc
	BRANCH=`git rev-parse --abbrev-ref HEAD` && \
		git checkout gh-pages && \
		cp -R docs/* . && \
		git add -A && \
		git commit -m "Updating documentation" && \
		git push origin gh-pages && \
		git checkout "$$BRANCH"


clean:
	@rm -f $(LIB)
	@rm -rf $(DOC)


install link:
	@npm $@


define release
	VERSION=`node -pe "require('./package.json').version"` && \
	NEXT_VERSION=`node -pe "require('semver').inc(\"$$VERSION\", '$(1)')"` && \
	node -e "\
		var j = require('./package.json');\
		j.version = \"$$NEXT_VERSION\";\
		var s = JSON.stringify(j, null, 2);\
		require('fs').writeFileSync('./package.json', s);" && \
	git commit -m "release $$NEXT_VERSION" -- package.json && \
	git tag "$$NEXT_VERSION" -m "release $$NEXT_VERSION"
endef


release-patch: build test
	@$(call release,patch)


release-minor: build test
	@$(call release,minor)


release-major: build test
	@$(call release,major)


publish: build test doc
	git push --tags origin HEAD:master
	npm publish
