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
	@COVERAGE=1 \
		multi=$(MOCHA_REPORTERS) \
		$(BIN)/mocha \
		--require coffee-script/register \
		--require spec/loader-coverage.js \
		--reporter mocha-multi \
		--ui bdd \
		$(SPEC)


coverall: test
	@cat ./coverage/coverage.lcov | @$(./node_modules/coveralls/bin/coveralls.js)


doc:
	VERSION=`node -pe "require('./package.json').version"`
	@$(BIN)/yuidoc \
		-e .coffee \
		--syntaxtype coffee \
		--project-version "$$VERSION" \
		-o $(DOC) \
		./src


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


release-patch: build test doc
	@$(call release,patch)


release-minor: build test doc
	@$(call release,minor)


release-major: build test doc
	@$(call release,major)


publish:
	git push --tags origin HEAD:master
	npm publish
