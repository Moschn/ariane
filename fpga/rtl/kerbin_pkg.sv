// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
//         Moritz Schneider, ETH Zurich
// Date: 17.08.2018
// Description: Package containing definitions valid for Kerbin

package kerbin_pkg;
// Boot Address from which the Core will boot by default
    localparam logic [63:0] K_BOOT_ADDR = 64'h8000_0000;

    localparam K_AXI_ADDRESS_WIDTH = 64;
    localparam K_AXI_DATA_WIDTH    = 64;
    localparam K_AXI_USER_WIDTH    = 1;
    localparam logic [63:0] K_CACHE_START_ADDR = 64'h4000_0000;

    localparam logic [63:0] L2_END            = 64'h8100_0000; // 18 kByte Address Range
    localparam logic [63:0] L2_START          = 64'h8000_0000;

    localparam logic [63:0] PERIPHERALS_END   = 64'h1A00_1FFF;
    localparam logic [63:0] PERIPHERALS_START = 64'h1A00_0000;

    localparam int unsigned NR_SLAVES_SOC           = 3;
    localparam int unsigned NR_MASTERS_SOC          = 3;

    localparam K_AXI_MASTER_ID_WIDTH      = 4;
    localparam K_AXI_SLAVE_ID_WIDTH     = K_AXI_MASTER_ID_WIDTH + $clog2(NR_MASTERS_SOC);


    localparam logic [NR_SLAVES_SOC-1:0][K_AXI_ADDRESS_WIDTH-1:0] start_addr_soc = { L2_START, PERIPHERALS_START  };
    localparam logic [NR_SLAVES_SOC-1:0][K_AXI_ADDRESS_WIDTH-1:0] end_addr_soc   = { L2_END,   PERIPHERALS_END    };

endpackage

