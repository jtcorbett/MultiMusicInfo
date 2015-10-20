SDKVERSION=5.0

include theos/makefiles/common.mk

TWEAK_NAME = MultiMusicInfo
MultiMusicInfo_FILES = MMI.mm
MultiMusicInfo_FRAMEWORKS = Foundation UIKit CoreGraphics MediaPlayer

include $(THEOS_MAKE_PATH)/tweak.mk
