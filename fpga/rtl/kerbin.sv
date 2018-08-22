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
    output logic               ddr3_ref_clk_p,
    output logic               ddr3_ref_clk_n,
    input  logic               sys_rst,
    output logic               ddr3_sys_clk_p,
    output logic               ddr3_sys_clk_n,
    // DDR 3
    inout  logic [63:0]        ddr3_dq,
    inout  logic [7:0]         ddr3_dqs_n,
    inout  logic [7:0]         ddr3_dqs_p,
    output logic [13:0]        ddr3_addr,
    output logic [2:0]         ddr3_ba,
    output logic               ddr3_ras_n,
    output logic               ddr3_cas_n,
    output logic               ddr3_we_n,
    output logic               ddr3_reset_n,
    output logic               ddr3_ck_p,
    output logic               ddr3_ck_n,
    output logic               ddr3_cke,
    output logic               ddr3_cs_n,
    output logic [7:0]         ddr3_dm,
    output logic               ddr3_odt
);
    logic  test_en_i, rst_ni, rst_no;
    logic  ui_clk_sync_rst;
    logic  clk_i;
    logic  ui_clk;
    logic  clk, ddr3_clk;

    assign test_en_i = 1'b0;
    assign rst_ni = ~ui_clk_sync_rst;
    assign clk_i = clk;
    assign ui_clock = clk;

    // -------------
    // Clk Manager
    // -------------
    xilinx_clock_manager i_xilinx_clock_manager(
        // Clock out ports
        .clk_out1_ce ( 1'b1            ), // input clk_out1_ce
        .clk_out1    ( clk             ), // output clk_out1
        .clk_out2_ce ( 1'b1            ), // input clk_out2_ce
        .clk_out2    ( ddr3_clk        ), // output clk_out2
        // Status and control signals
        .reset       ( ui_clk_sync_rst ), // input reset
        .locked      (                 ), // output locked
        // Clock in ports
        .clk_in1     ( sys_clk_i       )  // input clk_in1
    );

    // generate the differential clocks for the DDR3 interface
    OBUFDS gen_ddr3_sys_i(
        .O  ( ddr3_sys_clk_p ), // output diff_p
        .OB ( ddr3_sys_clk_n ), // output diff_n
        .I  ( ddr3_clk   )  // input clock
    );
    OBUFDS gen_ddr3_ref_i(
        .O  ( ddr3_ref_clk_p ), // output diff_p
        .OB ( ddr3_ref_clk_n ), // output diff_n
        .I  ( sys_clk_i )  // input clock
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
        .instr_if     ( slaves[0].Master  ),
        .data_if      ( slaves[1].Master  ),
        .bypass_if    ( slaves[2].Master  ),
        .irq_i        (             ),
        .ipi_i        (             ),
        .time_irq_i   (             ),
        .debug_req_i  (             )
    );

    //----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG

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
        .aresetn               ( rst_no              ),  // input			aresetn
        .app_sr_req            ( 1'b0                ),  // input			app_sr_req
        .app_ref_req           ( 1'b0                ),  // input			app_ref_req
        .app_zq_req            ( 1'b0                ),  // input			app_zq_req
        .app_sr_active         (                     ),  // output			app_sr_active
        .app_ref_ack           (                     ),  // output			app_ref_ack
        .app_zq_ack            (                     ),  // output			app_zq_ack
        // Slave Interface Write Address Ports
        .s_axi_awid            ( masters[1].aw_id          ),  // input [3:0]		s_axi_awid
        .s_axi_awaddr          ( masters[1].aw_addr        ),  // input [26:0]	s_axi_awaddr
        .s_axi_awlen           ( masters[1].aw_len         ),  // input [7:0]		s_axi_awlen
        .s_axi_awsize          ( masters[1].aw_size        ),  // input [2:0]		s_axi_awsize
        .s_axi_awburst         ( masters[1].aw_burst       ),  // input [1:0]		s_axi_awburst
        .s_axi_awlock          ( masters[1].aw_lock        ),  // input [0:0]		s_axi_awlock
        .s_axi_awcache         ( masters[1].aw_cache       ),  // input [3:0]		s_axi_awcache
        .s_axi_awprot          ( masters[1].aw_prot        ),  // input [2:0]		s_axi_awprot
        .s_axi_awqos           ( masters[1].aw_qos         ),  // input [3:0]		s_axi_awqos
        .s_axi_awvalid         ( masters[1].aw_valid       ),  // input			s_axi_awvalid
        .s_axi_awready         ( masters[1].aw_ready       ),  // output			s_axi_awready
        // Slave Interface Write Data Ports
        .s_axi_wdata           ( masters[1].w_data         ),  // input [63:0]	s_axi_wdata
        .s_axi_wstrb           ( masters[1].w_strb         ),  // input [7:0]		s_axi_wstrb
        .s_axi_wlast           ( masters[1].w_last         ),  // input			s_axi_wlast
        .s_axi_wvalid          ( masters[1].w_valid        ),  // input			s_axi_wvalid
        .s_axi_wready          ( masters[1].w_ready        ),  // output			s_axi_wready
        // Slave Interface Write Response Ports
        .s_axi_bid             ( masters[1].b_id           ),  // output [3:0]	s_axi_bid
        .s_axi_bresp           ( masters[1].b_resp         ),  // output [1:0]	s_axi_bresp
        .s_axi_bvalid          ( masters[1].b_valid        ),  // output			s_axi_bvalid
        .s_axi_bready          ( masters[1].b_ready        ),  // input			s_axi_bready
        // Slave Interface Read Address Ports
        .s_axi_arid            ( masters[1].ar_id          ),  // input [3:0]		s_axi_arid
        .s_axi_araddr          ( masters[1].ar_addr        ),  // input [26:0]	s_axi_araddr
        .s_axi_arlen           ( masters[1].ar_len         ),  // input [7:0]		s_axi_arlen
        .s_axi_arsize          ( masters[1].ar_size        ),  // input [2:0]		s_axi_arsize
        .s_axi_arburst         ( masters[1].ar_burst       ),  // input [1:0]		s_axi_arburst
        .s_axi_arlock          ( masters[1].ar_lock        ),  // input [0:0]		s_axi_arlock
        .s_axi_arcache         ( masters[1].ar_cache       ),  // input [3:0]		s_axi_arcache
        .s_axi_arprot          ( masters[1].ar_prot        ),  // input [2:0]		s_axi_arprot
        .s_axi_arqos           ( masters[1].ar_qos         ),  // input [3:0]		s_axi_arqos
        .s_axi_arvalid         ( masters[1].ar_valid       ),  // input			s_axi_arvalid
        .s_axi_arready         ( masters[1].ar_ready       ),  // output			s_axi_arready
        // Slave Interface Read Data Ports
        .s_axi_rid             ( masters[1].r_id           ),  // output [3:0]	s_axi_rid
        .s_axi_rdata           ( masters[1].r_data         ),  // output [63:0]	s_axi_rdata
        .s_axi_rresp           ( masters[1].r_resp         ),  // output [1:0]	s_axi_rresp
        .s_axi_rlast           ( masters[1].r_last         ),  // output			s_axi_rlast
        .s_axi_rvalid          ( masters[1].r_valid        ),  // output			s_axi_rvalid
        .s_axi_rready          ( masters[1].r_ready        ),  // input			s_axi_rready
        // System Clock Ports
        .sys_clk_p             ( ddr3_sys_clk_p            ),  // input			sys_clk_p
        .sys_clk_n             ( ddr3_sys_clk_n            ),  // input			sys_clk_n
        // Reference Clock Ports
        .clk_ref_p             ( ddr3_ref_clk_p            ),  // input			clk_ref_p
        .clk_ref_n             ( ddr3_ref_clk_n            ),  // input			clk_ref_n
        .sys_rst               ( sys_rst                   )   // input sys_rst
    );
    
endmodule
