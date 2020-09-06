
//test bench
module  cacheTs;

reg  clk;
reg   [7:0]data_in;
reg   mem_read, mem_write;
reg  [15:0]address_bus;
reg  [15:0] mem_data;
wire  [7:0]data_out;
wire  cache_hit, cache_miss;

initial
begin
clk=1; 
end

always #5 clk=~clk;

initial
begin
mem_read <=0;mem_write <=0;			// initially reset condition where no read and write performed
#5 mem_read <=1;mem_write <=0;address_bus <=16'b_111100001111_000_1; // the data is read out here
#10 address_bus <=16'b_111100001110_111_1;     // to demonstrate the LRU policy 
#10 address_bus <=16'b_111100001110_111_1;    
#10 mem_data[15:0] <= 15'habcd; 
# 10 mem_read <=0; mem_write <=1; address_bus <=16'b_010101100101_011_1;
#10 data_in[7:0] <= 8'hab;              
end

cache2way c1(.clk(clk), .data_in(data_in), .mem_read(mem_read), .mem_write(mem_write),  .address_bus(address_bus) ,.mem_data(mem_data), .data_out(data_out),.cache_hit(cache_hit), .cache_miss(cache_miss));

endmodule
