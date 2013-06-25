PYTHON=`which python`
DESTDIR=/
BUILDIR=$(CURDIR)/debian/ajenti
RPMTOPDIR=$(CURDIR)/build
PROJECT=ajenti
VERSION=0.99.6
PREFIX=/usr
DATE=`date -R`

SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
PAPER         =
DOCBUILDDIR   = docs/build
DOCSOURCEDIR   = docs/source
ALLSPHINXOPTS   = -d $(DOCBUILDDIR)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) $(DOCSOURCEDIR)

all: build

build:
	echo version = \"$(VERSION)\" > ajenti/build.py
	./compile_resources.py || true
	./make_messages.py
	
run: 
	./ajenti-panel -v -c ./config.json

doc:
	$(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(DOCBUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(BUILDDIR)/html."

cdoc:
	rm -rf $(DOCBUILDDIR)/*
	make doc

pull-crowdin:
	curl http://api.crowdin.net/api/project/ajenti/export?key=`cat ~/Dropbox/.crowdin.ajenti.key`
	wget http://api.crowdin.net/api/project/ajenti/download/all.zip?key=`cat ~/Dropbox/.crowdin.ajenti.key` -O all.zip
	unzip -o all.zip
	rm all.zip
	./make_messages.py

push-crowdin:
	./make_messages.py
	curl -F "files[/ajenti.po]=@ajenti/locale/ajenti.po" http://api.crowdin.net/api/project/ajenti/update-file?key=`cat ~/Dropbox/.crowdin.ajenti.key`

install: build
	$(PYTHON) setup.py install --root $(DESTDIR) $(COMPILE) --prefix $(PREFIX)

rpm: build tgz
	rm -rf dist/*.rpm

	cat packaging/ajenti.spec.in | sed s/__VERSION__/$(VERSION)/g > ajenti.spec

	mkdir -p build/SOURCES || true
	cp dist/ajenti*.tar.gz build/SOURCES

	rpmbuild --define '_topdir $(RPMTOPDIR)' -bb ajenti.spec 

	mv build/RPMS/noarch/$(PROJECT)*.rpm dist

	rm ajenti.spec

deb: build tgz
	rm -rf dist/*.deb

	cat debian/changelog.in | sed s/__VERSION__/$(VERSION)/g | sed "s/__DATE__/$(DATE)/g" > debian/changelog

	cp dist/$(PROJECT)*.tar.gz ..
	rename -f 's/$(PROJECT)-(.*)\.tar\.gz/$(PROJECT)_$$1\.orig\.tar\.gz/' ../*
	dpkg-buildpackage -b -rfakeroot -us -uc

	mv ../$(PROJECT)*.deb dist/
	
	rm ../$(PROJECT)*.orig.tar.gz
	rm ../$(PROJECT)*.changes
	rm debian/changelog

upload-deb: deb
	scp dist/*.deb root@ajenti.org:/srv/repo/ng/debian
	ssh root@ajenti.org /srv/repo/rebuild-debian.sh

upload-rpm: rpm
	scp dist/*.rpm root@ajenti.org:/srv/repo/ng/centos/6
	ssh root@ajenti.org /srv/repo/rebuild-centos.sh

tgz: build
	rm dist/*.tar.gz || true
	
	$(PYTHON) setup.py sdist 

clean:
	$(PYTHON) setup.py clean
	rm -rf $(DOCBUILDDIR)/*
	rm -rf build/ debian/$(PROJECT)* debian/*stamp* debian/files MANIFEST *.egg-info
	find . -name '*.pyc' -delete
	find . -name '*.c.js' -delete
	find . -name '*.coffee.js' -delete
	find . -name '*.c.css' -delete
	find . -name '*.less.css' -delete

.PHONY: build
