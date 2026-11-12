# Terasic DE0-CV — Intel/Altera Cyclone V 5CEBA4F23C7
# Fluxo open source experimental: yosys (synth_intel_alm) + nextpnr-mistral.
# Gravação na SRAM pelo openFPGALoader via cabo USB-Blaster (ele detecta o
# chip pela IDCODE). Pinagem de referência: boards/de0cv.qsf
DESCRIPTION="Terasic DE0-CV (Cyclone V 5CEBA4) — Mistral, experimental"
FAMILY=mistral
DEVICE="5CEBA4F23C7"
LOADER_CABLE=usb-blaster
NO_FLASH="a flash de configuração (EPCS) do Cyclone V usa outro processo de gravação"
