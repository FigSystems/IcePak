debian-base:
	out := $(shell mktemp -d); \
	sudo debootstrap --include=fakeroot stable ${out} http://deb.debian.org/debian; \
	sudo chown -R $(USER):$(USER) $(out); \
	tar -czf $(out).tar -C $(out) .; \
	rm -rf $(out); \
	mv $(out).tar ./build/debian-rootfs.tar.gz

alpine-base:
	ALPINE_URL := "https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-minirootfs-3.21.0-x86_64.tar.gz"; \
	out := $(shell mktemp -d); \
	wget -O- $(ALPINE_URL) | tar xz -C $(out); \
	tar -czf $(out).tar -C $(out) .; \
	rm -rf $(out); \
	mv $(out).tar ./build/alpine-rootfs.tar.gz


install: ipak-creater.sh build-ipak.sh dist-to-ipak.sh
	cp -f build-ipak.sh "$(HOME)/.local/bin/build-ipak"
	cp -f dist-to-ipak.sh "$(HOME)/.local/bin/dist-to-ipak"
	cp -f ipak-creater.sh "$(HOME)/.local/bin/ipak-creater"