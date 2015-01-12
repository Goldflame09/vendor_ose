# Inherit common OSE stuff
$(call inherit-product, vendor/ose/config/common.mk)

# Bring in all video files
$(call inherit-product, frameworks/base/data/videos/VideoPackage2.mk)

# Include OSE audio files
include vendor/ose/config/ose_audio.mk

# Include OSE LatinIME dictionaries
PRODUCT_PACKAGE_OVERLAYS += vendor/ose/overlay/dictionaries

# Optional OSE packages
PRODUCT_PACKAGES += \
    Galaxy4 \
    HoloSpiralWallpaper \
    LiveWallpapers \
    LiveWallpapersPicker \
    MagicSmokeWallpapers \
    NoiseField \
    PhaseBeam \
    VisualizationWallpapers \
    PhotoTable \
    SoundRecorder \
    PhotoPhase

PRODUCT_PACKAGES += \
    VideoEditor \
    libvideoeditor_jni \
    libvideoeditor_core \
    libvideoeditor_osal \
    libvideoeditor_videofilters \
    libvideoeditorplayer

# Extra tools in OSE
PRODUCT_PACKAGES += \
    vim \
    zip \
    unrar