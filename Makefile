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

pypi-dependencies.flatpak-manifest.yaml: requirements.txt
	flatpak-builder-tools/pip/flatpak-pip-generator --runtime=org.freedesktop.Sdk//22.08 --requirements-file=requirements.txt attrdict3 --output pypi-dependencies.flatpak-manifest --yaml

dist/repo: names.txt.gz dict_en.dat.gz manual.html pypi-dependencies.flatpak-manifest.yaml Devel.flatpak-manifest.yml
	flatpak-builder --repo=dist/repo --force-clean build-dir Devel.flatpak-manifest.yml

dist/trelby.flatpak: dist/repo
	flatpak build-bundle dist/repo dist/trelby.flatpak com.github.limburgher.trelby.Devel

install-flatpak: dist/trelby.flatpak
	flatpak install dist/trelby.flatpak

clean:
	rm -f bin/*.pyc src/*.pyc tests/*.pyc names.txt.gz dict_en.dat.gz manual.html MANIFEST trelby.1.gz doc/trelby.1.gz
	rm -rf build dist
	dh_clean

install: dist
	python3 setup.py install

test:
	pytest
