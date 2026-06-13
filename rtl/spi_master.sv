`default_nettype none

module spi_core #(
parameter DATA_WIDTH = 8,
parameter FIFO_DEPTH = 4,
parameter CLK_DIV = 4
)
(
input wire clk,
input wire rst,
input wire [DATA_WIDTH-1:0] tx_data,
input wire spi_miso,
input wire start,
input wire tx_valid,
input wire rx_read,
output wire busy,
output wire done,
output wire tx_full,
output wire tx_empty,
output wire rx_full,
output wire rx_empty,
output reg [DATA_WIDTH-1:0] rx_data,
output reg spi_clk,
output wire spi_mosi,
output wire cs
);

//FSM

localparam IDLE=2'b00;
localparam ASSERT_CS=2'b01;
localparam TRANSFER=2'b10;
localparam DEASSERT_CS=2'b11;
reg [1:0] state,next_state;
reg [$clog2(DATA_WIDTH+1)-1:0] bit_count;
always @(posedge clk)
begin
    if(!rst)
        state <= IDLE;
    else
        state <= next_state;
end
always @(*)
begin
next_state = state;
case(state)
	IDLE:
		if(start && !tx_empty)
    		next_state = ASSERT_CS;
	ASSERT_CS:
		next_state = TRANSFER;
	TRANSFER:
		if(bit_count == DATA_WIDTH)
    		next_state = DEASSERT_CS;
	DEASSERT_CS:
		next_state = IDLE;
endcase
end

//Clock Division
reg [7:0] clk_divider_count;
always @(posedge clk)
begin

	if(!rst)
		begin
    		clk_divider_count <=0;
    		spi_clk <=0;
		end
	else if(state==TRANSFER)
		begin
			if(clk_divider_count==CLK_DIV)
    		begin
        		clk_divider_count<=0;
        		spi_clk<=~spi_clk;
    		end
			else
        		clk_divider_count<=clk_divider_count+1;
	end
	else
	begin
    	clk_divider_count<=0;
    	spi_clk<=0;
	end
end
wire divider_expired;
assign divider_expired =
(clk_divider_count==CLK_DIV);

// Transfer fifo
reg [DATA_WIDTH-1:0] tx_fifo[0:FIFO_DEPTH-1];
reg [$clog2(FIFO_DEPTH)-1:0] tx_wr_ptr;
reg [$clog2(FIFO_DEPTH)-1:0] tx_rd_ptr;
reg [$clog2(FIFO_DEPTH+1)-1:0] tx_count;
assign tx_full = (tx_count==FIFO_DEPTH);
assign tx_empty = (tx_count==0);
always @(posedge clk)
begin
	if(!rst)
	begin
        tx_wr_ptr<=0;
		tx_rd_ptr<=0;
		tx_count<=0;
	end
	else if(tx_valid && !tx_full)
	begin
		tx_fifo[tx_wr_ptr]<=tx_data;
		tx_wr_ptr<=tx_wr_ptr+1;
		tx_count<=tx_count+1;
	end
end
// reciever fifo
reg [DATA_WIDTH-1:0] rx_fifo[0:FIFO_DEPTH-1];
reg [$clog2(FIFO_DEPTH)-1:0] rx_wr_ptr;
reg [$clog2(FIFO_DEPTH)-1:0] rx_rd_ptr;
reg [$clog2(FIFO_DEPTH+1)-1:0] rx_count;
assign rx_full = (rx_count==FIFO_DEPTH);
assign rx_empty = (rx_count==0);
always @(posedge clk)
begin
	if(!rst) begin
    rx_wr_ptr<=0;
	rx_rd_ptr<=0;
	rx_count<=0;
	rx_data<=0;

	end
	else
	begin
		if(rx_read && !rx_empty)
		begin
			rx_data <= rx_fifo[rx_rd_ptr];
			rx_rd_ptr <= rx_rd_ptr+1;
			rx_count <= rx_count-1;
		end
   	end
end
reg [DATA_WIDTH-1:0] tx_shift_register;
reg [DATA_WIDTH-1:0] rx_shift_register;
assign spi_mosi = tx_shift_register[DATA_WIDTH-1];

always @(posedge clk)
begin
  if(!rst)
  begin
	tx_shift_register<=0;
	rx_shift_register<=0;
	bit_count<=0;
  end
  else
  begin
		case(state)
		ASSERT_CS:
		begin
			tx_shift_register <= tx_fifo[tx_rd_ptr];
			tx_rd_ptr <= tx_rd_ptr+1;

			tx_count <= tx_count-1;
			rx_shift_register<=0;
			bit_count<=0;
		end
		TRANSFER:
        begin
		if(divider_expired)
		begin
			if(spi_clk==0)
			begin
             rx_shift_register={rx_shift_register[DATA_WIDTH-2:0],spi_miso};
			bit_count<=bit_count+1;
			end
			else
			begin
				tx_shift_register <={tx_shift_register[DATA_WIDTH-2:0],1'b0};
			end
		end

		end
		DEASSERT_CS:
		begin

		if(!rx_full)
		begin
            rx_fifo[rx_wr_ptr]<= rx_shift_register;
          	rx_wr_ptr<=rx_wr_ptr+1;
			rx_count<=rx_count+1;
		end
		end
		endcase

	end

end
assign cs =~((state==ASSERT_CS) ||(state==TRANSFER));
assign busy =(state!=IDLE);
assign done =(state==DEASSERT_CS);
endmodule