module spi_apb
(
input wire pclk,
input wire presetn,
input wire psel,
input wire penable,
input wire pwrite,
input wire [7:0] paddr,
input wire [31:0] pwdata,
output reg [31:0] prdata,
output reg pready,
input wire spi_miso,

output wire spi_mosi,
output wire spi_clk,
output wire cs
);
reg tx_valid;
reg [7:0] tx_data;

reg start;
reg rx_read;
wire busy;
wire done;
wire tx_full;
wire tx_empty;
wire rx_empty;
wire [7:0] rx_data;

//spi core
spi_core u_spi_core
(

.clk(pclk),
.rst(presetn),
.tx_data(tx_data),
.spi_miso(spi_miso),

.start(start),

.tx_valid(tx_valid),
.rx_read(rx_read),
.busy(busy),
.done(done),
.tx_full(tx_full),
.tx_empty(tx_empty),
.rx_empty(rx_empty),
.rx_data(rx_data),
.spi_clk(spi_clk),
.spi_mosi(spi_mosi),
.cs(cs)

);

//apb interface
wire apb_write;
assign apb_write =psel && penable && pwrite;
wire apb_read;
assign apb_read =psel && penable && !pwrite;
  
// Status register
// [0] busy
// [1] done
// [2] tx_empty
// [3] tx_full
// [4] rx_empty
always @(posedge pclk)
begin
	if(!presetn)
    begin
		tx_valid  <= 0;
        tx_data   <= 0;
        rx_read <=0;
		start <= 0;

        prdata <= 0;
        pready <= 0;
	end
	else
    begin
		start <= 0;
        pready <= 1;
		rx_read <=0;
        if(apb_write)
        begin
			case(paddr)
            8'h08:
            begin
              tx_data <= pwdata[7:0];
			  tx_data <= 1;
            end
            8'h00:
            begin
              if(pwdata[0])
                begin
					start <= 1'b1;
				end

            end


            default:
            begin
            end
			endcase
		end

		if(apb_read)
		begin
		case(paddr)
    		8'h04:
    		begin
				rx_read <=1;

        		prdata <= {24'b0,rx_data};
			end
    		8'h0C:
    		begin
				prdata <={26'b0,1'b0,rx_empty,tx_full,tx_empty,done,busy};

    end
	default:
    begin
        prdata <=0;
    end
    endcase

end
      if(tx_valid && !tx_full)
        begin
            tx_valid <=0;
        end
    end
end


endmodule
