################################################################################
#
# docker-engine
#
################################################################################

DOCKER_ENGINE_VERSION = 19.03.12
DOCKER_ENGINE_SITE = $(call github,docker,engine,v$(DOCKER_ENGINE_VERSION))

DOCKER_ENGINE_LICENSE = Apache-2.0
DOCKER_ENGINE_LICENSE_FILES = LICENSE

DOCKER_ENGINE_DEPENDENCIES = host-pkgconf
DOCKER_ENGINE_SRC_SUBDIR = github.com/docker/docker

DOCKER_ENGINE_LDFLAGS = \
	-X main.GitCommit=$(DOCKER_ENGINE_VERSION) \
	-X main.Version=$(DOCKER_ENGINE_VERSION)

DOCKER_ENGINE_TAGS = cgo exclude_graphdriver_zfs autogen
DOCKER_ENGINE_BUILD_TARGETS = cmd/dockerd

ifeq ($(BR2_PACKAGE_LIBSECCOMP),y)
DOCKER_ENGINE_TAGS += seccomp
DOCKER_ENGINE_DEPENDENCIES += libseccomp
endif

ifeq ($(BR2_INIT_SYSTEMD),y)
DOCKER_ENGINE_DEPENDENCIES += systemd
DOCKER_ENGINE_TAGS += systemd journald
endif
ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_EXPERIMENTAL),y)
DOCKER_ENGINE_TAGS += experimental
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_BTRFS),y)
DOCKER_ENGINE_DEPENDENCIES += btrfs-progs
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_btrfs
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_DEVICEMAPPER),y)
DOCKER_ENGINE_DEPENDENCIES += lvm2
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_devicemapper
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_VFS),y)
DOCKER_ENGINE_DEPENDENCIES += gvfs
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_vfs
endif

DOCKER_ENGINE_INSTALL_BINS = $(notdir $(DOCKER_ENGINE_BUILD_TARGETS))

define DOCKER_ENGINE_RUN_AUTOGEN
	cd $(@D) && \
		BUILDTIME="$$(date)" \
		VERSION="$(patsubst v%,%,$(DOCKER_ENGINE_VERSION))" \
		PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)" $(TARGET_MAKE_ENV) \
		bash ./hack/make/.go-autogen
endef

DOCKER_ENGINE_POST_CONFIGURE_HOOKS += DOCKER_ENGINE_RUN_AUTOGEN

define DOCKER_ENGINE_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(@D)/contrib/init/systemd/docker.service \
		$(TARGET_DIR)/usr/lib/systemd/system/docker.service
	$(INSTALL) -D -m 0644 $(@D)/contrib/init/systemd/docker.socket \
		$(TARGET_DIR)/usr/lib/systemd/system/docker.socket
endef

define DOCKER_ENGINE_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 755 package/docker-engine/S60dockerd \
		$(TARGET_DIR)/etc/init.d/S60dockerd
endef

define DOCKER_ENGINE_USERS
	- - docker -1 * - - - Docker Application Container Framework
endef

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_BTRFS),y)
define DOCKER_ENGINE_DRIVER_BTRFS_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_BTRFS_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BTRFS_FS_POSIX_ACL)
endef
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_DEVICEMAPPER),y)
define DOCKER_ENGINE_DRIVER_DM_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_MD)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BLK_DEV_DM)
	$(call KCONFIG_ENABLE_OPT,CONFIG_MD_THIN_PROVISIONING)
endef
endif

# based on contrib/check-config.sh
define DOCKER_ENGINE_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_POSIX_MQUEUE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUPS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_MEMCG)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUP_SCHED)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUP_FREEZER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CPUSETS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUP_DEVICE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_CGROUP_CPUACCT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NAMESPACES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_UTS_NS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IPC_NS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_PID_NS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET_NS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_ADVANCED)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BRIDGE_NETFILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NF_CONNTRACK)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XTABLES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_ADDRTYPE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_CONNTRACK)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NETFILTER_XT_MATCH_IPVS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_IPTABLES)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_FILTER)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_NAT)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IP_NF_TARGET_MASQUERADE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_BRIDGE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NET_CORE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_DUMMY)
	$(call KCONFIG_ENABLE_OPT,CONFIG_MACVLAN)
	$(call KCONFIG_ENABLE_OPT,CONFIG_IPVLAN)
	$(call KCONFIG_ENABLE_OPT,CONFIG_VXLAN)
	$(call KCONFIG_ENABLE_OPT,CONFIG_VETH)
	$(call KCONFIG_ENABLE_OPT,CONFIG_OVERLAY_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_KEYS)
	$(DOCKER_ENGINE_DRIVER_BTRFS_LINUX_CONFIG_FIXUPS)
	$(DOCKER_ENGINE_DRIVER_DM_LINUX_CONFIG_FIXUPS)
endef

$(eval $(golang-package))
