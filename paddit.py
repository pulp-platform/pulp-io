# -*- coding: utf-8 -*-
# @Author: Alfio Di Mauro
# @Date:   2021-02-19 15:24:41
# @Last Modified by:   Alfio Di Mauro
# @Last Modified time: 2021-02-23 10:03:24

from mako.template import Template
import argparse
import csv

PACKAGE_PAD_NAME = 13
PAD_LOGIC_NUMBER = 1
PACKAGE_PIN      = 2
TYPE             = 3
MULTI            = 4
EDGE             = 5
CELL_TYPE        = 6
DRIVING          = 7
SLEWRATE         = 8
SCHMIT           = 9
PU               = 10
PD               = 11
POW              = 12
ALT0             = 13
DIR0             = 14
OUT0             = 15
IN0              = 16
ALT1             = 17
DIR1             = 18
OUT1             = 19
IN1              = 20
ALT2             = 21
DIR2             = 22
OUT2             = 23
IN2              = 24

# fill the dictionary
pad = {}
pad_number = 0
with open('kraken_padframe_plaincsv.csv') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    line_count = 0
    for row in csv_reader:
        if line_count > 2:
            pad[row[PACKAGE_PAD_NAME]] = {}    
            pad[row[PACKAGE_PAD_NAME]]['mux_config']    = row[TYPE]
            pad[row[PACKAGE_PAD_NAME]]['pad_inst_name'] = "i_pad_" + str(row[ALT0])
            pad[row[PACKAGE_PAD_NAME]]['pad_cell_type'] = row[CELL_TYPE]
            pad[row[PACKAGE_PAD_NAME]]['pad_sig_name']  = "PAD_" + str(row[TYPE]) + "_" + str(row[PACKAGE_PAD_NAME]).upper()
            pad[row[PACKAGE_PAD_NAME]]['alt0_name']     = "PAD_" + str(row[ALT0]).upper()
            pad[row[PACKAGE_PAD_NAME]]['pad_logic_num'] = row[PAD_LOGIC_NUMBER]

            pad[row[PACKAGE_PAD_NAME]]['alt0_dflt_dir'] = 1 if row[DIR0] == 'O' else 0
            pad[row[PACKAGE_PAD_NAME]]['alt0_dflt_in']  = row[IN0] if row[IN0] == 1 or row[IN0] == 0 else 0
            pad[row[PACKAGE_PAD_NAME]]['alt0_dflt_out'] = row[OUT0] if row[OUT0] == 1 or row[OUT0] == 0 else 0
            pad[row[PACKAGE_PAD_NAME]]['alt0_dflt_cfg'] = "6'b0" + str(row[DRIVING]) + str(row[SCHMIT]) + str(row[PU]) + str(row[PD])

            if row[TYPE] in ['MXIO']:        
                pad[row[PACKAGE_PAD_NAME]]['alt1_name']     = "PAD_" + str(row[ALT1]).upper()
                pad[row[PACKAGE_PAD_NAME]]['alt1_dflt_dir'] = 1 if row[DIR1] == 'O' else 0
                pad[row[PACKAGE_PAD_NAME]]['alt1_dflt_out'] = row[IN1] if row[IN1] == 1 or row[IN1] == 0 else 0
                pad[row[PACKAGE_PAD_NAME]]['alt1_dflt_in']  = row[OUT1] if row[OUT1] == 1 or row[OUT1] == 0 else 0
                pad[row[PACKAGE_PAD_NAME]]['alt1_dflt_cfg'] = pad[row[PACKAGE_PAD_NAME]]['alt0_dflt_cfg']

                pad[row[PACKAGE_PAD_NAME]]['alt2_name']     = "PAD_" + str(row[ALT2]).upper()
                pad[row[PACKAGE_PAD_NAME]]['alt2_dflt_dir'] = 1 if row[DIR2] == 'O' else 0 
                pad[row[PACKAGE_PAD_NAME]]['alt2_dflt_in']  = row[IN2] if row[IN2] == 1 or row[IN2] == 0 else 0
                pad[row[PACKAGE_PAD_NAME]]['alt2_dflt_out'] = row[OUT2] if row[OUT2] == 1 or row[OUT2] == 0 else 0
                pad[row[PACKAGE_PAD_NAME]]['alt2_dflt_cfg'] = pad[row[PACKAGE_PAD_NAME]]['alt0_dflt_cfg']

            if row[TYPE] in ['MXIO','UTL','IO']:
                pad_number += 1;
                #print(pad_number)

        line_count += 1
    #print(f'Processed {line_count} lines.')

#print(pad)

pad_mux_utl_io_tlp = Template(
    """ 
    logic pad_do_{pad_sig_name};
    logic pad_oe_{pad_sig_name};
    assign pad_do_{pad_sig_name} = {alt0_name}.OUT;
    assign pad_oe_{pad_sig_name} = {alt0_name}.OE;
    """
    )

pad_mux_mxio_tlp = Template( 
"""
   // output connection to the pad
   logic s_do_${pad_sig_name};
   logic s_oe_${pad_sig_name};
   // configuration connecton to the pad
   logic [5:0] s_cfg_${pad_sig_name};
   // mux output alternate signals to the output pad connection (pad out mux)
   assign s_do_${pad_sig_name}  = pad_mux[${pad_logic_num}] == 2'b00 ? ${alt0_name}.OUT : pad_mux[${pad_logic_num}] == 2'b01 ? ${alt1_name}.OUT : pad_mux[${pad_logic_num}] == 2'b10 ? ${alt2_name}.OUT : ${alt0_dflt_out};
   assign s_oe_${pad_sig_name}  = pad_mux[${pad_logic_num}] == 2'b00 ? ${alt0_name}.OE  : pad_mux[${pad_logic_num}] == 2'b01 ? ${alt1_name}.OE  : pad_mux[${pad_logic_num}] == 2'b10 ? ${alt2_name}.OE  : ${alt0_dflt_dir};
   %if 'GPIO' in alt0_name:
   assign s_cfg_${pad_sig_name} = pad_mux[${pad_logic_num}] == 2'b00 ? gpio_cfg[${pad_logic_num}] : pad_mux[${pad_logic_num}] == 2'b01 ? gpio_cfg[${pad_logic_num}] : pad_mux[${pad_logic_num}] == 2'b10 ? gpio_cfg[${pad_logic_num}] : ${alt0_dflt_cfg};
   %elif 'GPIO' in alt1_name:
   assign s_cfg_${pad_sig_name} = pad_mux[${pad_logic_num}] == 2'b00 ? pad_cfg[${pad_logic_num}] : pad_mux[${pad_logic_num}] == 2'b01 ? gpio_cfg[${pad_logic_num}] : pad_mux[${pad_logic_num}] == 2'b10 ? gpio_cfg[${pad_logic_num}] : ${alt0_dflt_cfg};
   %elif 'GPIO' in alt2_name:
   assign s_cfg_${pad_sig_name} = pad_mux[${pad_logic_num}] == 2'b00 ? pad_cfg[${pad_logic_num}] : pad_mux[${pad_logic_num}] == 2'b01 ? pad_cfg[${pad_logic_num}] : pad_mux[${pad_logic_num}] == 2'b10 ? gpio_cfg[${pad_logic_num}] : ${alt0_dflt_cfg};
   %else:
   assign s_cfg_${pad_sig_name} = pad_mux[${pad_logic_num}] == 2'b00 ? pad_cfg[${pad_logic_num}] : pad_mux[${pad_logic_num}] == 2'b01 ? pad_cfg[${pad_logic_num}] : pad_mux[${pad_logic_num}] == 2'b10 ? pad_cfg[${pad_logic_num}] : ${alt0_dflt_cfg};
   %endif
   // input connection from the pad
   logic s_di_${pad_sig_name};
   // connect the pad input connection to the input peripheral signals (pad input demux)
   assign ${alt0_name}.IN = pad_mux[${pad_logic_num}] == 2'b00 ? s_di_${pad_sig_name} : ${alt0_dflt_in}; 
   %if alt1_name != alt0_name and alt1_name != "":
   assign ${alt1_name}.IN = pad_mux[${pad_logic_num}] == 2'b01 ? s_di_${pad_sig_name} : ${alt1_dflt_in}; 
   %endif
   %if alt2_name != alt1_name and alt2_name != alt0_name and alt2_name != "":
   assign ${alt2_name}.IN = pad_mux[${pad_logic_num}] == 2'b10 ? s_di_${pad_sig_name} : ${alt2_dflt_in}; 
   %endif
   ${pad_cell_type} ${pad_inst_name} (
       .PAD(         ${pad_sig_name}),
       .I  (    s_di_${pad_sig_name}),
       .O  (    s_do_${pad_sig_name}),
       .OEN(    s_oe_${pad_sig_name}),
       .PEN(s_cfg_${pad_sig_name}[0])
   );"""
    )

padframe_open_tpl = Template (
""" 
module kraken_padframe (
    // pad mux
    input logic [1:0][${padn}-1:0] pad_mux,
    input logic [5:0][${padn}-1:0] gpio_cfg,
    input logic [5:0][${padn}-1:0] pad_cfg,
    // SoC connections"""

    )

padframe_close_tpl = Template (
""" 
endmodule // kraken_padframe"""

    )

port_tlp = Template (
    """    wire ${pad_sig_name}${term}"""
)

port_soc_tlp = Template (
    """    BIPAD_IF.PADFRAME_SIDE ${port_name},"""
)

pads = list(pad.keys())
padn = 1

print(padframe_open_tpl.render(padn = pad_number))

## add soc connections
for p in pads:
    if pad[p]['mux_config'] in ['MXIO','UTL','IO']:
        print(port_soc_tlp.render(pad_sig_name=pad[p]['pad_sig_name'],port_name=pad[p]['alt0_name']))
        if 'alt1_name' in pad[p].keys():
            if pad[p]['alt0_name'] != pad[p]['alt0_name']:
                print(port_soc_tlp.render(pad_sig_name=pad[p]['pad_sig_name'],port_name=pad[p]['alt1_name']))
        if 'alt2_name' in pad[p].keys():
            if pad[p]['alt2_name'] != pad[p]['alt0_name'] and pad[p]['alt2_name'] != pad[p]['alt1_name']:
                print(port_soc_tlp.render(pad_sig_name=pad[p]['pad_sig_name'],port_name=pad[p]['alt2_name']))

## add pad wires
for p in pads:
    if pad[p]['mux_config'] in ['MXIO','UTL','IO']:
        if padn == pad_number:
            print(port_tlp.render(pad_sig_name=pad[p]['pad_sig_name'],term="\n);", alt0_name=pad[p]['alt0_name']))
        else:
            print(port_tlp.render(pad_sig_name=pad[p]['pad_sig_name'],term=",", alt0_name=pad[p]['alt0_name']))
        padn = padn + 1

## construct padframe_padmux
for p in pads:
    if pad[p]['mux_config'] in ['MXIO']:
         print(pad_mux_mxio_tlp.render( pad_inst_name = pad[p]['pad_inst_name'],
                                        pad_cell_type = pad[p]['pad_cell_type'],
                                        pad_sig_name  = pad[p]['pad_sig_name'],
                                        alt0_name     = pad[p]['alt0_name'],
                                        alt1_name     = pad[p]['alt1_name'],
                                        alt2_name     = pad[p]['alt2_name'],
                                        pad_logic_num = pad[p]['pad_logic_num'],
                                        alt0_dflt_dir = pad[p]['alt0_dflt_dir'],
                                        alt1_dflt_dir = pad[p]['alt1_dflt_dir'],
                                        alt2_dflt_dir = pad[p]['alt2_dflt_dir'],
                                        alt0_dflt_in  = pad[p]['alt0_dflt_in'],
                                        alt1_dflt_in  = pad[p]['alt1_dflt_in'],
                                        alt2_dflt_in  = pad[p]['alt2_dflt_in'],
                                        alt0_dflt_out = pad[p]['alt0_dflt_out'],
                                        alt1_dflt_out = pad[p]['alt1_dflt_out'],
                                        alt2_dflt_out = pad[p]['alt2_dflt_out'],
                                        alt0_dflt_cfg = pad[p]['alt0_dflt_cfg'],
                                        alt1_dflt_cfg = pad[p]['alt1_dflt_cfg'],
                                        alt2_dflt_cfg = pad[p]['alt2_dflt_cfg']))

                      
                      
print(padframe_close_tpl.render())                    
