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
    input  logic               sys_rst_i,
    input  logic               sys_clk_i,
    // DDR 3
    input  logic               ddr_aresetn,
    inout  logic [15:0]        ddr3_dq,
    inout  logic [1:0]         ddr3_dqs_n,
    inout  logic [1:0]         ddr3_dqs_p,
    `ifdef ZYBO
    output logic [14:0]        ddr3_addr,
    `elsif ARTY
    output logic [13:0]        ddr3_addr,
    `endif
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
    logic  clk_i, soc_clk;
    logic  ui_clk;
    logic  soc_clk_locked;

    logic ddr3_ref_clk, ddr3_sys_clk;

    assign test_en_i = 1'b0;
    assign rst_ni = ~ui_clk_sync_rst;
    // assign rst_ni = 1'b1;
    assign clk_i = soc_clk;

    // -------------
    // Clk Manager
    // 
    // Used to generate the sys and ref clock for the DDR controler
    // clkin: 12Mhz (from oscilator)
    // clkout1: 166.667MHz (ddr sys clock)
    // clkout2: 200MHz (ddr ref clock)
    // -------------
    xilinx_clock_manager i_xilinx_clock_manager(
        // Clock out ports
        .clk_out1    ( ddr3_sys_clk    ), // output clk_out1
        .clk_out2    ( ddr3_ref_clk    ), // output clk_out2
        // Status and control signals
        .reset       ( sys_rst_i       ), // input reset
        .locked      (                 ), // output locked
        // Clock in ports
        .clk_in1     ( sys_clk_i       )  // input clk_in1
    );

    // Clk Manager 2
    //
    // Used to generate 50MHz system clock for the ariane core from the returned ui_clk from the DDR controler
    // clkin: 81.25MHz
    // clkout: 50MHz
    xilinx_clock_manager_2 i_xilinx_clock_manager_2(
        // Clock out ports
        .clk_out1    ( soc_clk         ), // output clk_out1
        // Status and control signals
        .reset       ( rst_core_i      ), // input reset
        .locked      ( soc_clk_locked  ), // output locked
        // Clock in ports
        .clk_in1     ( ui_clk          )  // input clk_in1
    );

    logic rst_core_i, rst_core_ni;
    logic rst_bus_i, rst_bus_ni;
    logic rst_peri_i, rst_peri_ni;

    assign rst_core_ni = ~rst_core_i;
    // Reset generator
    // Ip from Xilinx: https://www.xilinx.com/support/documentation/ip_documentation/proc_sys_reset/v5_0/pg164-proc-sys-reset.pdf
    xilinx_system_reset reset_sync_i (
        .slowest_sync_clk( soc_clk ),          // input wire slowest_sync_clk
        .ext_reset_in( ui_clk_sync_rst),                  // input wire ext_reset_in
        .aux_reset_in( 1'b0 ),                  // input wire aux_reset_in
        .mb_debug_sys_rst( 1'b0 ),          // input wire mb_debug_sys_rst
        .dcm_locked( soc_clk_locked ),                      // input wire dcm_locked
        .mb_reset( rst_core_i ),                          // output wire mb_reset
        .bus_struct_reset( rst_bus_i ),          // output wire [0 : 0] bus_struct_reset
        .peripheral_reset( rst_peri_i ),          // output wire [0 : 0] peripheral_reset
        .interconnect_aresetn( rst_bus_ni ),  // output wire [0 : 0] interconnect_aresetn
        .peripheral_aresetn( rst_peri_ni )      // output wire [0 : 0] peripheral_aresetn
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
    // axi_cdc #(
    //     .AXI_ADDR_WIDTH   ( K_AXI_ADDRESS_WIDTH   ),
    //     .AXI_DATA_WIDTH   ( K_AXI_DATA_WIDTH      ),
    //     .AXI_USER_WIDTH   ( K_AXI_USER_WIDTH      ),
    //     .AXI_ID_WIDTH     ( K_AXI_SLAVE_ID_WIDTH  )
    // ) i_axi_ddr3_soc ( 
    //     .clk_slave_i           ( soc_clk                ),
    //     .rst_slave_ni          ( rst_ni                 ), 
    //     .axi_slave             ( slaves[0]              ), 
    //     .test_cgbypass_i       ( test_en_i              ),
    //     .isolate_slave_i       ( 1'b0                   ),
    //     .clk_master_i          ( ui_clk                 ),
    //     .rst_master_ni         ( rst_ni                 ),
    //     .axi_master            ( axi_ddr3_i             ),
    //     .isolate_master_i      ( 1'b0                   ),
    //     .clock_down_master_i   ( 1'b0                   ),
    //     .incoming_req_master_o (                        )
    // );

    xilinx_axi_clock_converter i_axi_ddr3_soc (
        .s_axi_aclk(soc_clk),          // input wire s_axi_aclk
        .s_axi_aresetn(rst_bus_i),    // input wire s_axi_aresetn
        .s_axi_awid(slaves[0].aw_id),          // input wire [3 : 0] s_axi_awid
        .s_axi_awaddr(slaves[0].aw_addr),      // input wire [63 : 0] s_axi_awaddr
        .s_axi_awlen(slaves[0].aw_len),        // input wire [7 : 0] s_axi_awlen
        .s_axi_awsize(slaves[0].aw_size),      // input wire [2 : 0] s_axi_awsize
        .s_axi_awburst(slaves[0].aw_burst),    // input wire [1 : 0] s_axi_awburst
        .s_axi_awlock(slaves[0].aw_lock),      // input wire [0 : 0] s_axi_awlock
        .s_axi_awcache(slaves[0].aw_cache),    // input wire [3 : 0] s_axi_awcache
        .s_axi_awprot(slaves[0].aw_prot),      // input wire [2 : 0] s_axi_awprot
        .s_axi_awregion(slaves[0].aw_region),  // input wire [3 : 0] s_axi_awregion
        .s_axi_awqos(slaves[0].aw_qos),        // input wire [3 : 0] s_axi_awqos
        .s_axi_awvalid(slaves[0].aw_valid),    // input wire s_axi_awvalid
        .s_axi_awready(slaves[0].aw_ready),    // output wire s_axi_awready
        .s_axi_wdata(slaves[0].w_data),        // input wire [63 : 0] s_axi_wdata
        .s_axi_wstrb(slaves[0].w_strb),        // input wire [7 : 0] s_axi_wstrb
        .s_axi_wlast(slaves[0].w_last),        // input wire s_axi_wlast
        .s_axi_wvalid(slaves[0].w_valid),      // input wire s_axi_wvalid
        .s_axi_wready(slaves[0].w_ready),      // output wire s_axi_wready
        .s_axi_bid(slaves[0].b_id),            // output wire [3 : 0] s_axi_bid
        .s_axi_bresp(slaves[0].b_resp),        // output wire [1 : 0] s_axi_bresp
        .s_axi_bvalid(slaves[0].b_valid),      // output wire s_axi_bvalid
        .s_axi_bready(slaves[0].b_ready),      // input wire s_axi_bready
        .s_axi_arid(slaves[0].ar_id),          // input wire [3 : 0] s_axi_arid
        .s_axi_araddr(slaves[0].ar_addr),      // input wire [63 : 0] s_axi_araddr
        .s_axi_arlen(slaves[0].ar_len),        // input wire [7 : 0] s_axi_arlen
        .s_axi_arsize(slaves[0].ar_size),      // input wire [2 : 0] s_axi_arsize
        .s_axi_arburst(slaves[0].ar_burst),    // input wire [1 : 0] s_axi_arburst
        .s_axi_arlock(slaves[0].ar_lock),      // input wire [0 : 0] s_axi_arlock
        .s_axi_arcache(slaves[0].ar_cache),    // input wire [3 : 0] s_axi_arcache
        .s_axi_arprot(slaves[0].ar_prot),      // input wire [2 : 0] s_axi_arprot
        .s_axi_arregion(slaves[0].ar_region),  // input wire [3 : 0] s_axi_arregion
        .s_axi_arqos(slaves[0].ar_qos),        // input wire [3 : 0] s_axi_arqos
        .s_axi_arvalid(slaves[0].ar_valid),    // input wire s_axi_arvalid
        .s_axi_arready(slaves[0].ar_ready),    // output wire s_axi_arready
        .s_axi_rid(slaves[0].r_id),            // output wire [3 : 0] s_axi_rid
        .s_axi_rdata(slaves[0].r_data),        // output wire [63 : 0] s_axi_rdata
        .s_axi_rresp(slaves[0].r_resp),        // output wire [1 : 0] s_axi_rresp
        .s_axi_rlast(slaves[0].r_last),        // output wire s_axi_rlast
        .s_axi_rvalid(slaves[0].r_valid),      // output wire s_axi_rvalid
        .s_axi_rready(slaves[0].r_ready),      // input wire s_axi_rready
        .m_axi_aclk(ui_clk),          // input wire m_axi_aclk
        .m_axi_aresetn(ui_clk_sync_rst),    // input wire m_axi_aresetn
        .m_axi_awid(axi_ddr3_i.aw_id),          // output wire [3 : 0] m_axi_awid
        .m_axi_awaddr(axi_ddr3_i.aw_addr),      // output wire [63 : 0] m_axi_awaddr
        .m_axi_awlen(axi_ddr3_i.aw_len),        // output wire [7 : 0] m_axi_awlen
        .m_axi_awsize(axi_ddr3_i.aw_size),      // output wire [2 : 0] m_axi_awsize
        .m_axi_awburst(axi_ddr3_i.aw_burst),    // output wire [1 : 0] m_axi_awburst
        .m_axi_awlock(axi_ddr3_i.aw_lock),      // output wire [0 : 0] m_axi_awlock
        .m_axi_awcache(axi_ddr3_i.aw_cache),    // output wire [3 : 0] m_axi_awcache
        .m_axi_awprot(axi_ddr3_i.aw_prot),      // output wire [2 : 0] m_axi_awprot
        .m_axi_awregion(axi_ddr3_i.aw_region),  // output wire [3 : 0] m_axi_awregion
        .m_axi_awqos(axi_ddr3_i.aw_qos),        // output wire [3 : 0] m_axi_awqos
        .m_axi_awvalid(axi_ddr3_i.aw_valid),    // output wire m_axi_awvalid
        .m_axi_awready(axi_ddr3_i.aw_ready),    // input wire m_axi_awready
        .m_axi_wdata(axi_ddr3_i.w_data),        // output wire [63 : 0] m_axi_wdata
        .m_axi_wstrb(axi_ddr3_i.w_strb),        // output wire [7 : 0] m_axi_wstrb
        .m_axi_wlast(axi_ddr3_i.w_last),        // output wire m_axi_wlast
        .m_axi_wvalid(axi_ddr3_i.w_valid),      // output wire m_axi_wvalid
        .m_axi_wready(axi_ddr3_i.w_ready),      // input wire m_axi_wready
        .m_axi_bid(axi_ddr3_i.b_id),            // input wire [3 : 0] m_axi_bid
        .m_axi_bresp(axi_ddr3_i.b_resp),        // input wire [1 : 0] m_axi_bresp
        .m_axi_bvalid(axi_ddr3_i.b_valid),      // input wire m_axi_bvalid
        .m_axi_bready(axi_ddr3_i.b_ready),      // output wire m_axi_bready
        .m_axi_arid(axi_ddr3_i.ar_id),          // output wire [3 : 0] m_axi_arid
        .m_axi_araddr(axi_ddr3_i.ar_addr),      // output wire [63 : 0] m_axi_araddr
        .m_axi_arlen(axi_ddr3_i.ar_len),        // output wire [7 : 0] m_axi_arlen
        .m_axi_arsize(axi_ddr3_i.ar_size),      // output wire [2 : 0] m_axi_arsize
        .m_axi_arburst(axi_ddr3_i.ar_burst),    // output wire [1 : 0] m_axi_arburst
        .m_axi_arlock(axi_ddr3_i.ar_lock),      // output wire [0 : 0] m_axi_arlock
        .m_axi_arcache(axi_ddr3_i.ar_cache),    // output wire [3 : 0] m_axi_arcache
        .m_axi_arprot(axi_ddr3_i.ar_prot),      // output wire [2 : 0] m_axi_arprot
        .m_axi_arregion(axi_ddr3_i.ar_region),  // output wire [3 : 0] m_axi_arregion
        .m_axi_arqos(axi_ddr3_i.ar_qos),        // output wire [3 : 0] m_axi_arqos
        .m_axi_arvalid(axi_ddr3_i.ar_valid),    // output wire m_axi_arvalid
        .m_axi_arready(axi_ddr3_i.ar_ready),    // input wire m_axi_arready
        .m_axi_rid(axi_ddr3_i.r_id),            // input wire [3 : 0] m_axi_rid
        .m_axi_rdata(axi_ddr3_i.r_data),        // input wire [63 : 0] m_axi_rdata
        .m_axi_rresp(axi_ddr3_i.r_resp),        // input wire [1 : 0] m_axi_rresp
        .m_axi_rlast(axi_ddr3_i.r_last),        // input wire m_axi_rlast
        .m_axi_rvalid(axi_ddr3_i.r_valid),      // input wire m_axi_rvalid
        .m_axi_rready(axi_ddr3_i.r_ready)      // output wire m_axi_rready
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
        .rst_n        ( rst_bus_ni                 ),
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
        .rst_ni       ( rst_core_ni ),
        .test_en_i    ( test_en_i   ),
        .boot_addr_i  ( K_BOOT_ADDR ),
        .core_id_i    ( 4'b0        ),
        .cluster_id_i ( 6'b0        ),
        .instr_if     ( masters[0]  ),
        .data_if      ( masters[1]  ),
        .bypass_if    ( masters[2]  ),
        .irq_i        (             ),
        .ipi_i        ( 1'b0        ),
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
        .ui_addn_clk_0         (                     ),  // output			ui_addn_clk_0
        .ui_addn_clk_1         (                     ),  // output			ui_addn_clk_1
        .ui_addn_clk_2         (                     ),  // output			ui_addn_clk_2
        .ui_addn_clk_3         (                     ),  // output			ui_addn_clk_3
        .ui_addn_clk_4         (                     ),  // output			ui_addn_clk_4
        .mmcm_locked           (                     ),  // output			mmcm_locked
        .aresetn               ( ddr_aresetn         ),  // input			aresetn
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
        .sys_clk_i             ( ddr3_sys_clk              ),  // input			sys_clk_i
        // Reference Clock Ports
        .clk_ref_i             ( ddr3_ref_clk              ),  // input				clk_ref_i
        .sys_rst               ( sys_rst_i                 ) // input sys_rst
    );
    
    

endmodule
