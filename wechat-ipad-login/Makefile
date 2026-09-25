TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = WeChat

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WeChatIPadLogin
WeChatIPadLogin_FILES = Tweak.x
WeChatIPadLogin_CFLAGS = -fobjc-arc
WeChatIPadLogin_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
