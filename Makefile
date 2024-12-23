build/debian-rootfs.tar.gz:
	out=$$(mktemp -d); \
	rootfs=$${out}/rootfs; \
	sudo debootstrap --include=fakeroot stable $${rootfs} http://deb.debian.org/debian; \
	touch $${out}/.mutable; \
	sudo chown -R $(USER):$(USER) $${out}; \
	tar --exclude="./rootfs/dev/*" -czf $${out}.tar -C $${out} .; \
	rm -rf $${out}; \
	mv $${out}.tar ./build/debian-rootfs.tar.gz

build/alpine-rootfs.tar.gz:
	ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-minirootfs-3.21.0-x86_64.tar.gz"; \
	out=$$(mktemp -d); \
	rootfs=$${out}/rootfs; \
	mkdir -p $${rootfs}; \
	wget -O- $${ALPINE_URL} | tar xz -C $${rootfs}; \
	touch $${out}/.mutable; \
	tar --exclude="./dev/*" -czf $${out}.tar -C $${out} .; \
	rm -rf $${out}; \
	mv $${out}.tar ./build/alpine-rootfs.tar.gz

debian-ipakdir: build/debian-rootfs.tar.gz
	rm -rf build/debian.ipakdir; \
	mkdir -p build/debian.ipakdir; \
	tar -xzf ./build/debian-rootfs.tar.gz -C build/debian.ipakdir; \
	cp ./ipak-dir.sh build/debian.ipakdir/.run.sh; \
	chmod +x build/debian.ipakdir/.run.sh;

alpine-ipakdir: build/alpine-rootfs.tar.gz
	rm -rf build/alpine.ipakdir; \
	mkdir -p build/alpine.ipakdir; \
	tar -xzf ./build/alpine-rootfs.tar.gz -C build/alpine.ipakdir; \
	cp ./ipak-dir.sh build/alpine.ipakdir/.run.sh; \
	chmod +x build/alpine.ipakdir/.run.sh;

alpine-ipakdir-tgz: alpine-ipakdir
	tar -czf build/alpine.tgz -C build/alpine.ipakdir .
	rm -rf build/alpine.ipakdir

debian-ipakdir-tgz: debian-ipakdir
	tar -czf build/debian.tgz -C build/debian.ipakdir .
	rm -rf build/debian.ipakdir


debian-base: build/debian-rootfs.tar.gz

alpine-base: build/alpine-rootfs.tar.gz

debian-ipak: build/debian.ipak

alpine-ipak: build/alpine.ipak

dists:  alpine-ipakdir-tgz debian-ipakdir-tgz


install: ipak-creater.sh build-ipak.sh
	cp -f build-ipak.sh "$(HOME)/.local/bin/build-ipak"
	cp -f ipak-creater.sh "$(HOME)/.local/bin/ipak-creater"