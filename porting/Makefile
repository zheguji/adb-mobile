iphone: lz4 zstd brotli protobuf adb

## lz4
lz4: lz4/appletvsimulator/arm64
lz4/%:
	@echo "|-> Making $@ ..."
	TARGET=$@ OUTPUT=../output bash ./scripts/make-lz4.sh

## zstd
zstd: zstd/appletvsimulator/arm64
zstd/%:
	@echo "|-> Making $@ ..."
	TARGET=$@ OUTPUT=../output bash ./scripts/make-zstd.sh

## brotli
brotli: brotli/appletvsimulator/arm64
brotli/%:
	@echo "|-> Making $@ ..."
	TARGET=$@ OUTPUT=../output bash ./scripts/make-brotli.sh

## protobuf
protobuf: protobuf/appletvsimulator/arm64
protobuf/%:
	@echo "|-> Making $@ ..."
	TARGET=$@ OUTPUT=../output bash ./scripts/make-protobuf.sh

## adb
adb: adb/appletvsimulator/arm64
adb/%:
	@echo "|-> Making $@ ..."
	TARGET=$@ OUTPUT=../output bash ./scripts/make-adb.sh
