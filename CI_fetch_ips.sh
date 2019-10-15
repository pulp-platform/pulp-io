#!/bin/bash
mkdir ips_local_dep
cd ips_local_dep

git clone https://github.com/pulp-platform/udma_adc_rx.git
cd udma_adc_rx
git checkout 24e1c7d 
cd ..

git clone https://github.com/pulp-platform/udma_adc_ts.git
cd udma_adc_ts
git checkout 294cbdd 
cd ..

git clone https://github.com/pulp-platform/udma_camera.git
cd udma_camera
git checkout d0f71b8 
cd ..

git clone https://github.com/pulp-platform/udma_core.git
cd udma_core
git checkout f5d7cc3 
cd ..

git clone https://github.com/pulp-platform/udma_external_per.git
cd udma_external_per
git checkout 0e53cfe 
cd ..

git clone https://github.com/pulp-platform/udma_filter.git
cd udma_filter
git checkout 9fe2568 
cd ..

git clone https://github.com/pulp-platform/udma_hyperbus.git
cd udma_hyperbus
git checkout 78613ab 
cd ..

git clone https://github.com/pulp-platform/udma_i2c.git
cd udma_i2c
git checkout 0402233
cd ..

git clone https://github.com/pulp-platform/udma_i2s.git
cd udma_i2s
git checkout ea9b73f 
cd ..

git clone https://github.com/pulp-platform/udma_jtag_fifo.git
cd udma_jtag_fifo
git checkout 1459a82 
cd ..

git clone https://github.com/pulp-platform/udma_qspi.git
cd udma_qspi
git checkout ec08ef3 
cd ..

git clone https://github.com/pulp-platform/udma_sdio.git
cd udma_sdio
git checkout 00061b1 
cd ..

git clone https://github.com/pulp-platform/udma_uart.git
cd udma_uart
git checkout 7741356
cd ..