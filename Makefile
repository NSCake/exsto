include $(THEOS)/makefiles/common.mk

ADDITIONAL_CFLAGS = -fobjc-arc
TWEAK_NAME = Exsto
Exsto_FILES = /mnt/d/codes/exsto/Tweak.xm /mnt/d/codes/exsto/EXSTOCircleMenuView.m
Exsto_FRAMEWORKS = CydiaSubstrate UIKit CoreGraphics Foundation QuartzCore
Exsto_LIBRARIES = 
Exsto_LDFLAGS += -Wl,-segalign,4000

export ARCHS = arm64
Exsto_ARCHS = arm64

include $(THEOS_MAKE_PATH)/tweak.mk
