# Inherit common OSE stuff
$(call inherit-product, vendor/ose/config/common.mk)

# Include OSE LatinIME dictionaries
PRODUCT_PACKAGE_OVERLAYS += vendor/ose/overlay/dictionaries

# Optional OSE packages
PRODUCT_PACKAGES += \
    LiveWallpapersPicker \
    PhaseBeam \
    PhotoTable \
    PhotoPhase

# Extra tools in OSE
PRODUCT_PACKAGES += \
    vim \
    zip \
    unrar
