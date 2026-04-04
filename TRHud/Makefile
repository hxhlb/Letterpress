ARCHS := arm64 x86_64
TARGET := macosx:clang:latest:12.0
DEBUG := 0

ADDITIONAL_LDFLAGS := $(filter-out -lroot -lroothide,$(ADDITIONAL_LDFLAGS))

include $(THEOS)/makefiles/common.mk

TOOL_NAME := mach-o-verifier

mach-o-verifier_USE_MODULES := 0
mach-o-verifier_INSTALL := 0

mach-o-verifier_FILES += verifier.mm
mach-o-verifier_FILES += Sources/TRHudObjC/TRHudCore.mm

mach-o-verifier_CFLAGS += -fobjc-arc
mach-o-verifier_CFLAGS += -fobjc-arc-exceptions
mach-o-verifier_CFLAGS += -fvisibility=hidden
mach-o-verifier_CFLAGS += -ISources/TRHudObjC
mach-o-verifier_CFLAGS += -DALLOW_PROTECTED=1

mach-o-verifier_CCFLAGS += -std=c++17

mach-o-verifier_FRAMEWORKS += Foundation
mach-o-verifier_FRAMEWORKS += CoreFoundation

include $(THEOS_MAKE_PATH)/tool.mk

after-stage::
	@cp -f $(THEOS_OBJ_DIR)/mach-o-verifier $(THEOS)/bin/mach-o-verifier
