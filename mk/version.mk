# Versión común del proyecto: VERSION en la raíz + commit (git describe, con «-dirty» si hay
# cambios sin commit). Los Makefiles la incluyen con `include ../../mk/version.mk`.
VERSION_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
PROJ_VERSION := $(shell cat "$(VERSION_ROOT)/VERSION" 2>/dev/null || echo 0.0.0)
GIT_VERSION  := $(shell git -C "$(VERSION_ROOT)" describe --always --dirty 2>/dev/null || echo desconocida)
FULL_VERSION := $(PROJ_VERSION)+$(GIT_VERSION)
# $(call stamp_plist,ruta del Info.plist ya copiado): versión corta = VERSION, versión de compilación = commit
stamp_plist = plutil -replace CFBundleShortVersionString -string "$(PROJ_VERSION)" "$(1)" && plutil -replace CFBundleVersion -string "$(GIT_VERSION)" "$(1)"
