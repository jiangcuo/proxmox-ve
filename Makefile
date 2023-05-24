include /usr/share/dpkg/default.mk

PACKAGE=proxmox-ve

GITVERSION:=$(shell git rev-parse HEAD)

BUILDDIR ?= $(PACKAGE)-$(DEB_VERSION)

PVE_DEB=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION)_all.deb
PVE_HEADERS_DEB=pve-headers_$(DEB_VERSION_UPSTREAM_REVISION)_all.deb

DEBS=$(PVE_DEB) $(PVE_HEADERS_DEB)

all: deb
deb: $(DEBS)

$(BUILDDIR): debian
	rm -rf $@ $@.tmp
	mkdir -p $@.tmp/debian
	cp -a debian/ $@.tmp/
	echo "git clone git://git.proxmox.com/git/proxmox-ve.git\\ngit checkout $(GITVERSION)" > $@.tmp/debian/SOURCE
	mv $@.tmp $@

$(PVE_HEADERS_DEB): $(PVE_DEB)
$(PVE_DEB): $(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -b -uc -us
	lintian $(DEBS)

.PHONY: upload
upload: $(DEBS)
	tar cf - $(DEBS)|ssh repoman@repo.proxmox.com -- upload --product pve --dist bullseye --arch $(DEB_BUILD_ARCH)

.PHONY: distclean
distclean: clean

.PHONY: clean
clean:
	rm -rf *~ $(PACKAGE)-[0-9]*/ $(PACKAGE)*.tar.* *.deb *.dsc *.changes *.build *.buildinfo
