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
//
// Date: 13.08.2018
// Description: Kerbin Top Level

import kerbin_pkg::*;

module kerbin (
    // System Ports
    input  logic               sys_clk_i,
    input  logic               sys_rst,
    // DDR 3
    input  logic               ddr3_ref_clk_p,
    input  logic               ddr3_ref_clk_n,
    input  logic               ddr3_sys_clk_p,
    input  logic               ddr3_sys_clk_n,
    input  logic               ddr_areset_n,

    inout  logic [15:0]        ddr3_dq,
    inout  logic [1:0]         ddr3_dqs_n,
    inout  logic [1:0]         ddr3_dqs_p,
    output logic [12:0]        ddr3_addr,
    output logic [2:0]         ddr3_ba,
    output logic               ddr3_ras_n,
    output logic               ddr3_cas_n,
    output logic               ddr3_we_n,
    output logic               ddr3_reset_n,
    output logic               ddr3_ck_p,
    output logic               ddr3_ck_n,
    output logic               ddr3_cke,
    output logic               ddr3_cs_n,
    output logic [1:0]         ddr3_dm,
    output logic               ddr3_odt
);
    logic  test_en_i, rst_ni;
    logic  ui_clk_sync_rst;
    logic  clk_i;
    logic  ui_clk;
    logic  clk;

    assign test_en_i = 1'b0;
    assign rst_ni = ~ui_clk_sync_rst;
    assign clk_i = clk;

    // -------------
    // Clk Manager
    // -------------
    xilinx_clock_manager i_xilinx_clock_manager(
        // Clock out ports
        .clk_out1    ( clk             ), // output clk_out1
        // Status and control signals
        .reset       ( ui_clk_sync_rst ), // input reset
        .locked      (                 ), // output locked
        // Clock in ports
        .clk_in1     ( ui_clk          )  // input clk_in1
    );

    AXI_BUS #(
        .AXI_ADDR_WIDTH   ( K_AXI_ADDRESS_WIDTH  ),
        .AXI_DATA_WIDTH   ( K_AXI_DATA_WIDTH     ),
        .AXI_ID_WIDTH     ( K_AXI_SLAVE_ID_WIDTH ),
        .AXI_USER_WIDTH   ( K_AXI_USER_WIDTH     )
    ) slaves[NR_SLAVES_SOC-1:0]();

    AXI_BUS #(
        .AXI_ADDR_WIDTH   ( K_AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH   ( K_AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH     ( K_AXI_MASTER_ID_WIDTH ),
        .AXI_USER_WIDTH   ( K_AXI_USER_WIDTH      )
    ) masters[NR_MASTERS_SOC-1:0]();

    AXI_BUS #(
        .AXI_ADDR_WIDTH   ( K_AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH   ( K_AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH     ( K_AXI_SLAVE_ID_WIDTH  ),
        .AXI_USER_WIDTH   ( K_AXI_USER_WIDTH      )
    ) axi_ddr3_i();

    // ------------------------------------------------------
    // AXI Slices to ease timing path to DDR3
    // ------------------------------------------------------
    axi_slice_wrap #(
        .AXI_ADDR_WIDTH ( K_AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH ( K_AXI_DATA_WIDTH      ),
        .AXI_USER_WIDTH ( K_AXI_USER_WIDTH      ),
        .AXI_ID_WIDTH   ( K_AXI_MASTER_ID_WIDTH ),
        .SLICE_DEPTH    ( 2                     )
    ) i_axi_ddr3_slice ( 
        .axi_slave  ( slaves[0]  ), 
        .axi_master ( axi_ddr3_i ), 
        .*
    );

    // -------------
    // AXI interconnect
    // -------------
    axi_node_intf_wrap #(
        .NB_MASTER      ( NR_SLAVES_SOC         ),
        .NB_SLAVE       ( NR_MASTERS_SOC        ),
        .AXI_ADDR_WIDTH ( K_AXI_ADDRESS_WIDTH   ),
        .AXI_DATA_WIDTH ( K_AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH   ( K_AXI_MASTER_ID_WIDTH ),
        .AXI_USER_WIDTH ( K_AXI_USER_WIDTH      )
    ) axi_xbar_i (
        .clk          ( clk_i                      ),
        .rst_n        ( rst_ni                     ),
        .test_en_i    ( test_en_i                  ),
        .slave        ( masters                    ),
        .master       ( slaves                     ),
        .start_addr_i ( kerbin_pkg::start_addr_soc ),
        .end_addr_i   ( kerbin_pkg::end_addr_soc   )
    );

    ariane #(
        .CACHE_START_ADDR ( K_CACHE_START_ADDR    ),
        .AXI_ID_WIDTH     ( K_AXI_MASTER_ID_WIDTH ),
        .AXI_USER_WIDTH   ( K_AXI_USER_WIDTH      )
    ) ariane_i (
        .clk_i        ( clk_i       ),
        .rst_ni       ( rst_ni      ),
        .test_en_i    ( test_en_i   ),
        .boot_addr_i  ( K_BOOT_ADDR ),
        .core_id_i    (             ),
        .cluster_id_i (             ),
        .instr_if     ( masters[0]  ),
        .data_if      ( masters[1]  ),
        .bypass_if    ( masters[2]  ),
        .irq_i        (             ),
        .ipi_i        (             ),
        .time_irq_i   (             ),
        .debug_req_i  (             )
    );

    xilinx_mig7_ddr3 u_xilinx_mig7_ddr3 (

        // Memory interface ports
        .ddr3_addr             ( ddr3_addr           ),  // output [12:0]	ddr3_addr
        .ddr3_ba               ( ddr3_ba             ),  // output [2:0]	ddr3_ba
        .ddr3_cas_n            ( ddr3_cas_n          ),  // output			ddr3_cas_n
        .ddr3_ck_n             ( ddr3_ck_n           ),  // output [0:0]	ddr3_ck_n
        .ddr3_ck_p             ( ddr3_ck_p           ),  // output [0:0]	ddr3_ck_p
        .ddr3_cke              ( ddr3_cke            ),  // output [0:0]	ddr3_cke
        .ddr3_ras_n            ( ddr3_ras_n          ),  // output			ddr3_ras_n
        .ddr3_reset_n          ( ddr3_reset_n        ),  // output			ddr3_reset_n
        .ddr3_we_n             ( ddr3_we_n           ),  // output			ddr3_we_n
        .ddr3_dq               ( ddr3_dq             ),  // inout [15:0]	ddr3_dq
        .ddr3_dqs_n            ( ddr3_dqs_n          ),  // inout [1:0]		ddr3_dqs_n
        .ddr3_dqs_p            ( ddr3_dqs_p          ),  // inout [1:0]		ddr3_dqs_p
        .init_calib_complete   (                     ),  // output			init_calib_complete
        
        .ddr3_cs_n             ( ddr3_cs_n           ),  // output [0:0]    ddr3_cs_n
        .ddr3_dm               ( ddr3_dm             ),  // output [1:0]	ddr3_dm
        .ddr3_odt              ( ddr3_odt            ),  // output [0:0]	ddr3_odt
        // Application interface ports
        .ui_clk                ( ui_clk              ),  // output			ui_clk
        .ui_clk_sync_rst       ( ui_clk_sync_rst     ),  // output			ui_clk_sync_rst
        .mmcm_locked           (                     ),  // output			mmcm_locked
        .aresetn               ( ddr_areset_n        ),  // input			aresetn
        .app_sr_req            ( 1'b0                ),  // input			app_sr_req
        .app_ref_req           ( 1'b0                ),  // input			app_ref_req
        .app_zq_req            ( 1'b0                ),  // input			app_zq_req
        .app_sr_active         (                     ),  // output			app_sr_active
        .app_ref_ack           (                     ),  // output			app_ref_ack
        .app_zq_ack            (                     ),  // output			app_zq_ack
        // Slave Interface Write Address Ports
        .s_axi_awid            ( axi_ddr3_i.aw_id          ),  // input [3:0]		s_axi_awid
        .s_axi_awaddr          ( axi_ddr3_i.aw_addr        ),  // input [26:0]	s_axi_awaddr
        .s_axi_awlen           ( axi_ddr3_i.aw_len         ),  // input [7:0]		s_axi_awlen
        .s_axi_awsize          ( axi_ddr3_i.aw_size        ),  // input [2:0]		s_axi_awsize
        .s_axi_awburst         ( axi_ddr3_i.aw_burst       ),  // input [1:0]		s_axi_awburst
        .s_axi_awlock          ( axi_ddr3_i.aw_lock        ),  // input [0:0]		s_axi_awlock
        .s_axi_awcache         ( axi_ddr3_i.aw_cache       ),  // input [3:0]		s_axi_awcache
        .s_axi_awprot          ( axi_ddr3_i.aw_prot        ),  // input [2:0]		s_axi_awprot
        .s_axi_awqos           ( axi_ddr3_i.aw_qos         ),  // input [3:0]		s_axi_awqos
        .s_axi_awvalid         ( axi_ddr3_i.aw_valid       ),  // input			s_axi_awvalid
        .s_axi_awready         ( axi_ddr3_i.aw_ready       ),  // output			s_axi_awready
        // Slave Interface Write Data Ports
        .s_axi_wdata           ( axi_ddr3_i.w_data         ),  // input [63:0]	s_axi_wdata
        .s_axi_wstrb           ( axi_ddr3_i.w_strb         ),  // input [7:0]		s_axi_wstrb
        .s_axi_wlast           ( axi_ddr3_i.w_last         ),  // input			s_axi_wlast
        .s_axi_wvalid          ( axi_ddr3_i.w_valid        ),  // input			s_axi_wvalid
        .s_axi_wready          ( axi_ddr3_i.w_ready        ),  // output			s_axi_wready
        // Slave Interface Write Response Ports
        .s_axi_bid             ( axi_ddr3_i.b_id           ),  // output [3:0]	s_axi_bid
        .s_axi_bresp           ( axi_ddr3_i.b_resp         ),  // output [1:0]	s_axi_bresp
        .s_axi_bvalid          ( axi_ddr3_i.b_valid        ),  // output			s_axi_bvalid
        .s_axi_bready          ( axi_ddr3_i.b_ready        ),  // input			s_axi_bready
        // Slave Interface Read Address Ports
        .s_axi_arid            ( axi_ddr3_i.ar_id          ),  // input [3:0]		s_axi_arid
        .s_axi_araddr          ( axi_ddr3_i.ar_addr        ),  // input [26:0]	s_axi_araddr
        .s_axi_arlen           ( axi_ddr3_i.ar_len         ),  // input [7:0]		s_axi_arlen
        .s_axi_arsize          ( axi_ddr3_i.ar_size        ),  // input [2:0]		s_axi_arsize
        .s_axi_arburst         ( axi_ddr3_i.ar_burst       ),  // input [1:0]		s_axi_arburst
        .s_axi_arlock          ( axi_ddr3_i.ar_lock        ),  // input [0:0]		s_axi_arlock
        .s_axi_arcache         ( axi_ddr3_i.ar_cache       ),  // input [3:0]		s_axi_arcache
        .s_axi_arprot          ( axi_ddr3_i.ar_prot        ),  // input [2:0]		s_axi_arprot
        .s_axi_arqos           ( axi_ddr3_i.ar_qos         ),  // input [3:0]		s_axi_arqos
        .s_axi_arvalid         ( axi_ddr3_i.ar_valid       ),  // input			s_axi_arvalid
        .s_axi_arready         ( axi_ddr3_i.ar_ready       ),  // output			s_axi_arready
        // Slave Interface Read Data Ports
        .s_axi_rid             ( axi_ddr3_i.r_id           ),  // output [3:0]	s_axi_rid
        .s_axi_rdata           ( axi_ddr3_i.r_data         ),  // output [63:0]	s_axi_rdata
        .s_axi_rresp           ( axi_ddr3_i.r_resp         ),  // output [1:0]	s_axi_rresp
        .s_axi_rlast           ( axi_ddr3_i.r_last         ),  // output			s_axi_rlast
        .s_axi_rvalid          ( axi_ddr3_i.r_valid        ),  // output			s_axi_rvalid
        .s_axi_rready          ( axi_ddr3_i.r_ready        ),  // input			s_axi_rready
        // System Clock Ports
        .sys_clk_p             ( ddr3_sys_clk_p            ),  // input			sys_clk_p
        .sys_clk_n             ( ddr3_sys_clk_n            ),  // input			sys_clk_n
        // Reference Clock Ports
        .clk_ref_p             ( ddr3_ref_clk_p            ),  // input			clk_ref_p
        .clk_ref_n             ( ddr3_ref_clk_n            ),  // input			clk_ref_n
        .sys_rst               ( sys_rst                   )   // input sys_rst
    );
    
    

endmodule
