################################################################################
#
# recomputer-r20xx
#
################################################################################

# Remember to bump the version when anything changes in this directory.
RECOMPUTER_R20XX_SOURCE =
RECOMPUTER_R20XX_VERSION = 0.1.0
RECOMPUTER_R20XX_DEPENDENCIES = host-dtc linux

define RECOMPUTER_R20XX_BUILD_CMDS
	cp $(NERVES_DEFCONFIG_DIR)/package/recomputer-r20xx/*.dts $(@D)
	for filename in $(@D)/*.dts; do \
		$(CPP) -I$(@D) -I $(LINUX_SRCDIR)include -I $(LINUX_SRCDIR)arch -nostdinc -undef -D__DTS__ -x assembler-with-cpp $$filename | \
			$(HOST_DIR)/usr/bin/dtc -Wno-unit_address_vs_reg -@ -I dts -O dtb -b 0 -o $${filename%.dts}.dtbo || exit 1; \
	done
endef

define RECOMPUTER_R20XX_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 -t $(BINARIES_DIR)/rpi-firmware/overlays $(@D)/*.dtbo
endef

$(eval $(generic-package))
