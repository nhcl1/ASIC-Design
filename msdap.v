
`include "definitions.vh"

module msdap(
    input wire sclk,
    input wire dclk,
    input wire start,
    input wire frame,
    input wire reset,
    input wire [`INPUT_WIDTH-1:0] inputL, // Only use inputL[0]
    input wire [`INPUT_WIDTH-1:0] inputR, // Only use inputR[0]
    output wire inready,
    output wire outready,
    output wire [`OUTPUT_WIDTH-1:0] outputL,
    output wire [`OUTPUT_WIDTH-1:0] outputR
    );
    
wire internal_reset, init_reset;
wire write_rj, write_coeff, write_data;
wire zeroL, zeroR;
wire enable_cu;

wire [`INPUT_WIDTH-1:0] data_inL;
wire [`INPUT_WIDTH-1:0] data_inR;

wire [`RJ_ADDR_BITS-1:0] rj_read_addrL;
wire [`RJ_WIDTH-1:0] rj_data_outL;
wire [`RJ_ADDR_BITS-1:0] rj_read_addrR;
wire [`RJ_WIDTH-1:0] rj_data_outR;

wire [`COEFF_ADDR_BITS-1:0] coeff_read_addrL;
wire [`COEFF_WIDTH-1:0] coeff_data_outL;
wire [`COEFF_ADDR_BITS-1:0] coeff_read_addrR;
wire [`COEFF_WIDTH-1:0] coeff_data_outR;

wire [`INPUT_ADDR_BITS-1:0] input_read_addrL;
wire [`INPUT_WIDTH-1:0] input_data_outL;

wire [`INPUT_WIDTH-1:0] input_data_outR;
wire [`INPUT_ADDR_BITS-1:0] input_read_addrR;

// control unit
control_unit ctrl_unit(
    .sclk(sclk),
    .dclk(dclk),
    .start(start),
    .frame(frame),
    .reset_in(reset),
    .zeroL(zeroL),
    .zeroR(zeroR),
    .write_rj(write_rj),
    .write_coeff(write_coeff),
    .write_data(write_data),
    .reset_out(internal_reset),
    .init_out(init_reset),
    .enable_cu(enable_cu),
    .outready(outready),
    .inready(inready)
);

// serial to parallel 
serial_to_parallel StPL(
    .serial_in(inputL[0]),
    .clk(dclk),
    .parallel_out(data_inL)
    );
    
serial_to_parallel StPR(
    .serial_in(inputR[0]),
    .clk(dclk),
    .parallel_out(data_inR)
    );    
// zero detector

zero_check zero_checkL(
    .data_in(data_inL),
    .zero(zeroL)
    );
    
zero_check zero_checkR(
    .data_in(data_inR),
    .zero(zeroR)
    );
    
    
// rj mem   
rj_mem rj_memL(
    .data_in(data_inL[`RJ_WIDTH-1:0]),
    .write(write_rj),
    .reset(init_reset),
    .read_addr(rj_read_addrL),
    .data_out(rj_data_outL)
    );

rj_mem rj_memR(
    .data_in(data_inR[`RJ_WIDTH-1:0]),
    .write(write_rj),
    .reset(init_reset),
    .read_addr(rj_read_addrR),
    .data_out(rj_data_outR)
    );

// coeff mem
coeff_mem coeff_memL(
    .data_in(data_inL[`COEFF_WIDTH-1:0]),
    .write(write_coeff),
    .reset(init_reset),
    .read_addr(coeff_read_addrL),
    .data_out(coeff_data_outL)
    );
    
// coeff mem
coeff_mem coeff_memR(
    .data_in(data_inR[`COEFF_WIDTH-1:0]),
    .write(write_coeff),
    .reset(init_reset),
    .read_addr(coeff_read_addrR),
    .data_out(coeff_data_outR)
    );    
    
    
// data mem     
data_mem data_memL(
    .data_in(data_inL),
    .read_addr(input_read_addrL),
    .reset(internal_reset), 
    .write(write_data),
    .data_out(input_data_outL)
    );

data_mem data_memR(
    .data_in(data_inR),
    .read_addr(input_read_addrR),
    .reset(internal_reset), 
    .write(write_data),
    .data_out(input_data_outR)
    );


// convolution unit
convolution_unit conv_unitL(
    .reset(internal_reset),
    .sclk(sclk),
    .enable(enable_cu),
    .data_in(input_data_outL),
    .rj_in(rj_data_outL),
    .coeff_in(coeff_data_outL),
    .data_addr(input_read_addrL),
    .rj_addr(rj_read_addrL),
    .coeff_addr(coeff_read_addrL),
    .data_out(outputL)
    );
    
convolution_unit conv_unitR(
    .reset(internal_reset),
    .sclk(sclk),
    .enable(enable_cu),
    .data_in(input_data_outR),
    .rj_in(rj_data_outR),
    .coeff_in(coeff_data_outR),
    .data_addr(input_read_addrR),
    .rj_addr(rj_read_addrR),
    .coeff_addr(coeff_read_addrR),
    .data_out(outputR)
    );

    
endmodule
