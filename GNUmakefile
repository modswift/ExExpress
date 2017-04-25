# GNUmakefile

PACKAGE_DIR=.

include $(PACKAGE_DIR)/xcconfig/config.make

MODULES = ExExpress

ifeq ($(HAVE_SPM),yes)

all :
	$(SWIFT_BUILD_TOOL)

clean :
	$(SWIFT_CLEAN_TOOL)

distclean : clean
	rm -rf .build

tests : all
	$(SWIFT_TEST_TOOL)

else

MODULE_LIBS = \
  $(addsuffix $(SHARED_LIBRARY_SUFFIX),$(addprefix $(SHARED_LIBRARY_PREFIX),$(MODULES)))
MODULE_BUILD_RESULTS = $(addprefix $(SWIFT_BUILD_DIR)/,$(MODULE_LIBS))

all :
	@$(MAKE) -C Sources/ExExpress all

clean :
	rm -rf .build

distclean : clean

endif

docker-build:
	mkdir -p .docker.build .docker.Packages
	docker run --rm \
		-v $(PWD):/src \
		-v $(PWD)/.docker.build:/src/.build	\
		-v $(PWD)/.docker.Packages:/src/Packages\
		swift:3.1 \
		bash -c "cd /src && swift build"

docker-clean:
	rm -rf .build-docker
