
//This is the main cache module. The outputs and inputs are
//data_Out 		: The byte output from the cache
//mem_Write 		: Asserted when memory write is performed
//mem_Read 		: Asserted when memory read is performed
//data_In		: Byte input to the cache
//adress_bus		: 16-bit address of the byte accessed
//validBit		: Used to validate or invalidate the byte at the address
//clk			: External clock
//cache_hit		: Asserted when there is a cache hit.
//cache_miss		: Asserted when there is a miss.


module cache2way(clk, data_in,mem_read, mem_write, address_bus,mem_data,data_out,cache_hit,cache_miss);

input clk;				//External clock
input [7:0]data_in;			// Input to the cache in byte
input mem_read,mem_write;		// used to indicate id read operation is performed or write
input [15:0]address_bus;		// the 16 bit address bus for the access of bytes
input [15:0] mem_data;			// The data present in the cache memory

output reg [7:0]data_out;		// Output of the data
output reg cache_hit,cache_miss;	// It indicates if there is a miss or a hit, that is data was available in cache(hit) or not

reg [29:0] way1 [7:0];			//As it is a 2 way cache, every line has 2 ways or sets
reg [29:0] way2 [7:0];			//Each way is of 29 bits which consists of 2 bytes of data(16 bits), tag(12 bits) & a valid bit(1 bit)

reg [11:0]tag_addr;			// the tag present in the bytes of address bus
reg [11:0]tag_1,tag_2;			// The tag of way/set 1 and 2
reg validbit_1,validbit_2;		// valid bit pesent in the 2 way sets
reg offset;				// Offest bit determines which way will be used out of the 2 way present 
reg [2:0]index;				// Determines the line number in the cache memory
reg lrubit_1,lrubit_2;			// The LRU bit used to implement the replacement policy of Pseudo LRU
 
always@(posedge clk)

begin

index[2:0]=address_bus[3:1];		//extracting index bits from the address bus
offset=address_bus[0];			//extracting the offset bit from the address bus
tag_addr=address_bus[15:4];		// extracting the tag bits fron the address bus
validbit_1= way1[index][29];		//extracting valid bit from the way 1 fron cache
validbit_2= way2[index][29];		//extracting valid bit from the way 2 fron cache
tag_1[11:0] = way1[index][28:17];	//extracting tag bits from the way 1 fron cache
tag_2[11:0] = way2[index][28:17];	//extracting tag bits from the way 2 fron cache
lrubit_1= way1[index][0];		//extracting LRU bit from way 1 which works as counter to tell which was least recently used
lrubit_2= way2[index][0];		//extracting LRU bit from way 2 which works as counter to tell which was least recently used

end

// implementing values in the cache memory
initial 

begin

way1[0]=30'b1_111100001111_11111111_00001111_0;
way1[1]=30'b0_010101010111_11110011_00001100_0;
way1[2]=30'b1_100111111001_01010001_10101110_0;
way1[3]=30'b0_001101110011_11001011_00110000_0;
way1[4]=30'b1_010111100101_11111100_11000100_0;
way1[5]=30'b1_010111000101_00010101_11001001_0;
way1[6]=30'b0_111111100000_01111110_00000111_0;
way1[7]=30'b1_111100001110_01011001_11001100_0;


way2[0]=30'b0_000000010101_00000000_11111111_0;
way2[1]=30'b1_010101110101_11100111_00001100_1;
way2[2]=30'b1_010111000101_11000100_11000000_0;
way2[3]=30'b0_010101100101_11001111_00110100_0;
way2[4]=30'b1_100110111001_01000001_10100110_0;
way2[5]=30'b0_111001000000_01100010_00011000_0;
way2[6]=30'b0_010001111000_01011111_11001111_0;
way2[7]=30'b1_111100001110_00011101_11100001_1;

end


//read operation

always@(posedge clk)

begin

if(mem_read==1'b1)			//To determine that read is performed

begin
          if (validbit_1==1'b1)		// check for the valid bit
          
begin 
           if (tag_addr==tag_1)		// if valid bit is 1, compare for tag bits 
                  
		begin			//if tag bits of way 1 matches
                  
		if (offset==1'b0) 	// If offset is 0, data read from LSB byte of data line
                     
		 begin 
                       
		data_out = way1[index][8:1];		// Lowest significant byte
                cache_hit=1'b1; cache_miss=1'b0;	//as data present, cache hit is 1
                lrubit_1=1'b1; lrubit_2=1'b0; 		// set lru bits
                way1[index][0]= lrubit_1;		//update the LRU bits
                way2[index][0]= lrubit_2;
                       
		end

                else if(offset==1'b1)		// if offest is 1, data read from Second byte of data line
                       
		begin
                
		data_out = way1[index][16:9];		// Most significant byte of way 1
                cache_hit=1'b1; cache_miss=1'b0;	// bits updated according to their operation
                lrubit_1=1'b1; lrubit_2=1'b0;
                way1[index][0]= lrubit_1;
                way2[index][0]= lrubit_2;
                       
		 end
                   
	end
        end

          else if (tag_addr[11:0]==tag_2[11:0] && validbit_2==1'b1)	// If tag bits of way 2 matches and valid bit is also set
          
		 begin 
           
		if (offset==1'b0) 			//offest 0, uses first byte of way2
           
	        begin
       	         
		data_out = way2[index][8:1];		
  		cache_hit=1'b1; cache_miss=1'b0;
   		lrubit_1=1'b0; lrubit_2=1'b1;
                way1[index][0]= lrubit_1;
                way2[index][0]= lrubit_2;
   		 
		end
 
  	else 
   		 
		begin
  		  
		data_out = way2[index][16:9];		// if offset bit is 1, uses second byte of way 2
  		cache_hit=1'b1; cache_miss=1'b0;	// cache hit bit updated as data is present
 	        lrubit_1=1'b0; lrubit_2=1'b1; 		// LRU bits are set
                way1[index][0]= lrubit_1;		//LRU bits updated to keep track of the data LRU
                way2[index][0]= lrubit_2;
  		  
		end
	  end

      	else 
      		 begin
	
		cache_miss = 1'b1;			//if tag bits does not match we give a cache miss signal as data cannot be read and have to be retrieved from memory
         	$display ("There is miss and the data requested will be read from the main memory to chache"); 		//display
 	 
	if(lrubit_1==1'b0)		//implmentation of replacement policy
  		
		begin			// if LRU bit is 0, LRU data. used for replacement
   		 
		 way1[index][16:1]=mem_data; // input data to cache from memory
   		  
		if(offset==1'b0)		// if offset 0, first byte used to replace
  		  
		 begin
   		  
		data_out= way1[index][8:1];	// output recieved
  		   
		end
   		   
	else					// second byte used to replace as offset is 1
   		 begin
   		  
		data_out= way1[index][16:9];	// second byte used
   		   
		 end
  		  
		lrubit_1=1'b1 ; lrubit_2= 1'b0;		// LRU bits are updated, as way 1 is used for replacement, lru bit 1 is set as 1 and lru bit 2 as 0
                
		end
   
         else if(lrubit_2==1'b0)		// if lru bit 2 was 0
  		 
		begin
   		  
		way2[index][16:1]=mem_data;	//input datain way 2 , bytes determined by offset bit
		 
	if(offset==1'b0)
    		 begin
    		 
		data_out= way2[index][8:1];
   		  
		end
   	else
   		begin
  		   
		data_out= way2[index][16:9]; 		// output recieved from way 2
  		   
		end
  		  
		lrubit_1=1'b0 ; lrubit_2= 1'b1;		// LRU bit set as way 2 is used
   		end 
        end
end 


//write operation

if(mem_write==1'b1)
begin

if(validbit_1==1'b1)
begin

if (tag_addr[11:0]==tag_1[11:0]) 
begin
    if (offset==1'b0) 
    begin
    way1[index][8:1]=data_in;
    cache_hit=1'b1; cache_miss=1'b0;	//as data present, cache hit is 1
    lrubit_1=1'b1; lrubit_2=1'b0; 	// set lru bits
    way1[index][0]= lrubit_1;		//update the LRU bits
     way2[index][0]= lrubit_2;
    end

    else 
    begin
    way1[index][16:9]=data_in; 
    cache_hit=1'b1; cache_miss=1'b0;	// bits updated according to their operation
     lrubit_1=1'b1; lrubit_2=1'b0;
     way1[index][0]= lrubit_1;
     way2[index][0]= lrubit_2;
    end
end

else if (tag_addr[11:0]==tag_2[11:0])
begin 
    if (offset==1'b0) 
    begin
    way2[index][8:1]=data_in;
     cache_hit=1'b1; cache_miss=1'b0;
   	lrubit_1=1'b0; lrubit_2=1'b1;
        way1[index][0]= lrubit_1;
        way2[index][0]= lrubit_2;
    end

    else 
    begin
    way2[index][16:9]=data_in;
     cache_hit=1'b1; cache_miss=1'b0;	// cache hit bit updated as data is present
     lrubit_1=1'b0; lrubit_2=1'b1; 		// LRU bits are set
      way1[index][0]= lrubit_1;		//LRU bits updated to keep track of the data LRU
     way2[index][0]= lrubit_2;
    end
end

else 
begin
   cache_miss = 1'b1;		/*if the tag bits do not match, the cache line is empty and to fill that line ,
				 we have to first write data from main memory to the cache line*/
   
$display ("There is miss"); 	// hence it is a cache miss
end

end 
end
end

endmodule			// end of code
