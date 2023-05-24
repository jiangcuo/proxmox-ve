include /usr/share/dpkg/default.mk

PACKAGE=proxmox-ve

GITVERSION:=$(shell git rev-parse HEAD)

BUILDDIR ?= $(PACKAGE)-$(DEB_VERSION)
DSC=$(PACKAGE)_$(DEB_VERSION).dsc

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

dsc: $(DSC)
	$(MAKE) clean
	$(MAKE) $(DSC)
	lintian $(DSC)

$(DSC): $(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -S -uc -us

sbuild: $(DSC)
	sbuild $(DSC)

.PHONY: upload
upload: UPLOAD_DIST ?= $(DEB_DISTRIBUTION)
upload: $(DEBS)
	tar cf - $(DEBS)|ssh repoman@repo.proxmox.com -- upload --product pve --dist $(UPLOAD_DIST)

.PHONY: distclean
distclean: clean

.PHONY: clean
clean:
	rm -rf *~ $(PACKAGE)-[0-9]*/ $(PACKAGE)*.tar.* *.deb *.dsc *.changes *.build *.buildinfo
