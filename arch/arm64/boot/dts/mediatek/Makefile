# SPDX-License-Identifier: GPL-2.0
ifeq ($(CONFIG_MACH_MT6765),y)
dtb-y += mt6765.dtb
dtb-$(CONFIG_HQ_PROJECT_HS04) += mt6765_a04e_eur_open_00.dtb mt6765_m04_eur_open_00.dtb
dtb-$(CONFIG_HQ_PROJECT_HS03S) += mt6765_a03s_eur_open_00.dtb
endif

#ifeq ($(CONFIG_MACH_MT6768),y)
#dtb-y += mt6768.dtb
#dtb-$(CONFIG_HQ_PROJECT_O8) += mt6769v_a06_eur_open_00.dtb
#endif

always            := $(dtb-y)
clean-files       := *.dtb*
