
 
 `timescale 1ns / 1ps
 `include "definitions.vh"
 
 
 module tb_msdap();
 
 reg [`INPUT_WIDTH-1:0] rj_L [0:`RJ_COUNT-1];
 reg [`INPUT_WIDTH-1:0] rj_R [0:`RJ_COUNT-1];
 
 reg [`INPUT_WIDTH-1:0] coeff_L [0:`FILTER_ORDER-1];
 reg [`INPUT_WIDTH-1:0] coeff_R [0:`FILTER_ORDER-1];
 
 reg [`INPUT_WIDTH-1:0] data_in_L [0:`INPUT_COUNT-1];
 reg [`INPUT_WIDTH-1:0] data_in_R [0:`INPUT_COUNT-1];
 
 reg [`INPUT_WIDTH-1:0] par_data_inL;
 reg [`INPUT_WIDTH-1:0] par_data_inR;
 
 
 // File processing 
 integer infile, outfile, status, c;
 integer rj_index, coeff_index, input_index;
 reg rj_flag, coeff_flag, input_flag;
 reg finished; 
 reg [8*100:0] line;
 reg first = 1;
 
 // MSDAP Testing
 integer i;
 
 wire sclk, dclk;
 reg frame, reset, start;
 wire outready, inready;
 
 // keep enable high
 reg enable_pts;

 wire [`INPUT_WIDTH-1:0] inputL;
 wire [`INPUT_WIDTH-1:0] inputR;
 wire [`OUTPUT_WIDTH-1:0] outputL;
 wire [`OUTPUT_WIDTH-1:0] outputR;
 
 clk_gen #(`DCLK_CYCLE) data_osc(
    .clk(dclk)
 );
 
 clk_gen #(`SCLK_CYCLE) sys_osc(
    .clk(sclk)
 );
 
 hold_low #(`INPUT_WIDTH-1) lowL(
    .low(inputL[`INPUT_WIDTH-1:1])
    );
 
  hold_low #(`INPUT_WIDTH-1) lowR(
    .low(inputR[`INPUT_WIDTH-1:1])
    );
 
 parallel_to_serial #(`INPUT_WIDTH) PtSL(
    .clk(dclk),
    .frame(frame),
    .enable(enable_pts),
    .parallel_in(par_data_inL),
    .serial_out(inputL[0])
    );  
 
  parallel_to_serial #(`INPUT_WIDTH) PtSR(
    .clk(dclk),
    .frame(frame),
    .enable(enable_pts),
    .parallel_in(par_data_inR),
    .serial_out(inputR[0])
    );  
 
 msdap UUT(
    .sclk(sclk),
    .dclk(dclk),
    .start(start),
    .frame(frame),
    .reset(reset),
    .inputL(inputL),
    .inputR(inputR),
    .inready(inready),
    .outready(outready),
    .outputL(outputL),
    .outputR(outputR)
 );
 
 
 initial begin
    // RESET points are <value in file - 1>
    
    rj_index = 0;
    coeff_index = 0;
    input_index = 0;
    rj_flag = 1;
    coeff_flag = 1;
    input_flag  = 1;
    finished = 0;
    outfile = $fopen("data2.out","w");
    infile = $fopen(`PATH_DATAIN, "r");
    if (infile == 0) begin
        $error("Error: infile Failed to open");
    end
    
    while( !finished) begin
        c = $fgetc(infile);
        if( c != `ASCII_FWDSLASH) begin
            status = $ungetc(c,infile);
            if(rj_index < `RJ_COUNT) begin
                status = $fscanf(infile, " %h %h", rj_L[rj_index], rj_R[rj_index]);
                status = $fgets(line,infile);
                rj_index = rj_index + 1;
            end
            else if(coeff_index < `FILTER_ORDER) begin
                status = $fscanf(infile, " %h %h", coeff_L[coeff_index], coeff_R[coeff_index]);
                status = $fgets(line,infile);
                coeff_index = coeff_index + 1;
            end
            else if(input_index < `INPUT_COUNT) begin
                status = $fscanf(infile, " %h %h", data_in_L[input_index], data_in_R[input_index]);
                status = $fgets(line,infile);
                input_index = input_index + 1;
            end
     
        end
        else begin
            $display("Line starts with / skipping line");
            status = $fgets(line, infile);
            
        end
        
        if(rj_index >= `RJ_COUNT && rj_flag) begin
            $display("All Rjs read in");
            rj_flag = 0;
        end
        
        if(coeff_index >= `FILTER_ORDER && coeff_flag) begin
            $display("All coeffs read in");
            coeff_flag = 0;
        end
        
        if(input_index >= `INPUT_COUNT && input_flag) begin
            $display("All inputs read in");
            input_flag = 0;
            finished = 1;
        end
        
        if((input_index + 1) % 1000 == 0) begin
            $display("Inputs read in: %d", input_index + 1);
        end
        
    end
    #10;
    $fclose(infile);
    start = 0;
    frame = 0;
    reset = 0;
    
    enable_pts = 1;
    #25;
    start = 1;
    #25;
    start = 0;
    
    #(`DCLK_CYCLE/2 - 60)
    
    
    for(i = 0; i < `RJ_COUNT; i = i + 1) begin
        par_data_inL = rj_L[i];
        par_data_inR = rj_R[i];
        frame = 1;
        #(`DCLK_CYCLE)
        frame = 0;
        #(16*`DCLK_CYCLE);
     end
     
     for(i = 0; i < `COEFF_COUNT; i = i + 1) begin
        par_data_inL = coeff_L[i];
        par_data_inR = coeff_R[i];
        frame = 1;
        #(`DCLK_CYCLE)
        frame = 0;
        #(16*`DCLK_CYCLE);
    
    end
    
    // limits should be 0 & `INPUT_COUNT
    for(i = 0; i < `INPUT_COUNT; i = i + 1) begin
        par_data_inL = data_in_L[i];
        par_data_inR = data_in_R[i];
        frame = 1;
        #(`DCLK_CYCLE)
        frame = 0;
        #(3*`DCLK_CYCLE);
        // RESET 
        if(i == 4200 || i == 6000) begin
            #(`DCLK_CYCLE/4);
            reset = 1;
            #(`DCLK_CYCLE/4);
            reset = 0;
            #(`DCLK_CYCLE/2);
        end
        else begin
            #(`DCLK_CYCLE);
        end 
        #(11*`DCLK_CYCLE);
    end
    
    // Uncomment to test reset 
    /*
    reset = 1;
    #20;
    reset = 0;
    #20;
    reset = 1;
    #20;
    reset = 0;
    #100;
    reset = 1;
    #20;
    */
    
    $fflush(outfile);
    $fclose(outfile);
    $finish;
    
 end
 
 always@(posedge outready) begin
    $fwrite(outfile, "%h      %h\n",outputL,outputR);
 end
 
 
 
 endmodule
 