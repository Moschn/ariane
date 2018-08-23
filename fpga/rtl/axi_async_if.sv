// Copyright (c) 2014-2018 ETH Zurich, University of Bologna
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>


/// An asynchronous AXI4 interface.
interface AXI_BUS_ASYNC
#(
  parameter AXI_ADDR_WIDTH = -1,
  parameter AXI_DATA_WIDTH = -1,
  parameter AXI_ID_WIDTH   = -1,
  parameter AXI_USER_WIDTH = -1,
  parameter BUFFER_WIDTH   = -1
);

  localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;


  logic [AXI_ID_WIDTH-1:0]    aw_id;
  logic [AXI_ADDR_WIDTH-1:0]  aw_addr;
  logic [7:0]                 aw_len;
  logic [2:0]                 aw_size;
  logic [1:0]                 aw_burst;
  logic                       aw_lock;
  logic [3:0]                 aw_cache;
  logic [2:0]                 aw_prot;
  logic [3:0]                 aw_qos;
  logic [3:0]                 aw_region;
  logic [AXI_USER_WIDTH-1:0]  aw_user;
  logic [BUFFER_WIDTH-1:0]    aw_writetoken;
  logic [BUFFER_WIDTH-1:0]    aw_readpointer;

  logic [AXI_DATA_WIDTH-1:0]  w_data;
  logic [AXI_STRB_WIDTH-1:0]  w_strb;
  logic                       w_last;
  logic [AXI_USER_WIDTH-1:0]  w_user;
  logic [BUFFER_WIDTH-1:0]    w_writetoken;
  logic [BUFFER_WIDTH-1:0]    w_readpointer;

  logic [AXI_ID_WIDTH-1:0]    b_id;
  logic [1:0]                 b_resp;
  logic [AXI_USER_WIDTH-1:0]  b_user;
  logic [BUFFER_WIDTH-1:0]    b_writetoken;
  logic [BUFFER_WIDTH-1:0]    b_readpointer;

  logic [AXI_ID_WIDTH-1:0]    ar_id;
  logic [AXI_ADDR_WIDTH-1:0]  ar_addr;
  logic [7:0]                 ar_len;
  logic [2:0]                 ar_size;
  logic [1:0]                 ar_burst;
  logic                       ar_lock;
  logic [3:0]                 ar_cache;
  logic [2:0]                 ar_prot;
  logic [3:0]                 ar_qos;
  logic [3:0]                 ar_region;
  logic [AXI_USER_WIDTH-1:0]  ar_user;
  logic [BUFFER_WIDTH-1:0]    ar_writetoken;
  logic [BUFFER_WIDTH-1:0]    ar_readpointer;

  logic [AXI_ID_WIDTH-1:0]    r_id;
  logic [AXI_DATA_WIDTH-1:0]  r_data;
  logic [1:0]                 r_resp;
  logic                       r_last;
  logic [AXI_USER_WIDTH-1:0]  r_user;
  logic [BUFFER_WIDTH-1:0]    r_writetoken;
  logic [BUFFER_WIDTH-1:0]    r_readpointer;

  modport Master (
    output aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_user, aw_writetoken, input aw_readpointer,
    output w_data, w_strb, w_last, w_user, w_writetoken, input w_readpointer,
    input b_id, b_resp, b_user, b_writetoken, output b_readpointer,
    output ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_writetoken, input ar_readpointer,
    input r_id, r_data, r_resp, r_last, r_user, r_writetoken, output r_readpointer
  );

  modport Slave (
    input aw_id, aw_addr, aw_len, aw_size, aw_burst, aw_lock, aw_cache, aw_prot, aw_qos, aw_region, aw_user, aw_writetoken, output aw_readpointer,
    input w_data, w_strb, w_last, w_user, w_writetoken, output w_readpointer,
    output b_id, b_resp, b_user, b_writetoken, input b_readpointer,
    input ar_id, ar_addr, ar_len, ar_size, ar_burst, ar_lock, ar_cache, ar_prot, ar_qos, ar_region, ar_user, ar_writetoken, output ar_readpointer,
    output r_id, r_data, r_resp, r_last, r_user, r_writetoken, input r_readpointer
  );

endinterface