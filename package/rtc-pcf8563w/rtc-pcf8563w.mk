################################################################################
#
# rtc-pcf8563w
#
################################################################################

RTC_PCF8563W_VERSION = 1.0
RTC_PCF8563W_SITE = $(NERVES_DEFCONFIG_DIR)/package/rtc-pcf8563w/src
RTC_PCF8563W_SITE_METHOD = local
RTC_PCF8563W_LICENSE = GPL-2.0

$(eval $(kernel-module))
$(eval $(generic-package))
