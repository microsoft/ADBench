include_HEADERS = adept.h
EXTRA_DIST = Timer.h create_adept_source_header adept_source.h

adept_source.h: ../adept/*.cpp
	./create_adept_source_header
all-local: adept_source.h