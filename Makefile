PREFIX = $(DESTDIR)/usr

.PHONY : clean dist deb install-flatpak

dist: names.txt.gz dict_en.dat.gz manual.html trelby.1.gz
	python3 setup.py sdist && cp trelby.1.gz doc/

deb: dist
	debuild -us -uc -b

names.txt.gz: names.txt
	gzip -c names.txt > names.txt.gz

dict_en.dat.gz: dict_en.dat
	gzip -c dict_en.dat > dict_en.dat.gz

manual.html: doc/*
	make -C doc html && mv doc/manual.html .

trelby.1.gz: doc/*
	make -C doc manpage && mv doc/trelby.1.gz .

rpm: dist
	python3 setup.py bdist_rpm

flatpak-builder-tools/pip/flatpak-pip-generator:
	git submodule update --init flatpak-builder-tools
	pip3 install --user requirements-parser PyYAML

pypi-dependencies.flatpak-manifest.yaml: requirements.txt flatpak-builder-tools/pip/flatpak-pip-generator
	yes | flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
	flatpak install flathub org.freedesktop.Sdk//23.08
	flatpak-builder-tools/pip/flatpak-pip-generator --runtime=org.freedesktop.Sdk//23.08 --requirements-file=requirements.txt attrdict3 --output pypi-dependencies.flatpak-manifest --yaml

dist/repo: src bin names.txt.gz dict_en.dat.gz manual.html setup.py pypi-dependencies.flatpak-manifest.yaml Devel.flatpak-manifest.yml
	flatpak install flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08
	flatpak-builder --repo=dist/repo --force-clean build-dir Devel.flatpak-manifest.yml

dist/trelby.flatpak: dist/repo
	flatpak build-bundle dist/repo dist/trelby.flatpak com.github.limburgher.trelby.Devel

install-flatpak: dist/trelby.flatpak
	flatpak --user install dist/trelby.flatpak

clean:
	rm -f bin/*.pyc src/*.pyc tests/*.pyc names.txt.gz dict_en.dat.gz manual.html MANIFEST trelby.1.gz doc/trelby.1.gz
	rm -rf build dist
	dh_clean

install: dist
	python3 setup.py install

test:
	pytest
