module spi_core_tb;

localparam DATA_WIDTH = 8;
localparam CLK_DIV    = 4;
reg clk;
reg rst;
reg [DATA_WIDTH-1:0] tx_data;
reg spi_miso;
reg start;

reg tx_valid;
reg rx_read;
wire busy;
wire done;
wire [DATA_WIDTH-1:0] rx_data;
wire spi_clk;
wire spi_mosi;
wire cs;
initial begin
    $dumpfile("spi.vcd");
    $dumpvars(0, spi_core_tb);
end

spi_core #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(4),
    .CLK_DIV(CLK_DIV)
)

dut
(
    .clk(clk),
    .rst(rst),

    .tx_data(tx_data),
    .spi_miso(spi_miso),
    .start(start),

    .tx_valid(tx_valid),
     .rx_read(rx_read),
    .busy(busy),
    .done(done),
    .tx_full(),
    .tx_empty(),
    .rx_full(),
    .rx_empty(),
    .rx_data(rx_data),

    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .cs(cs)
);

always #5 clk = ~clk;

reg [DATA_WIDTH-1:0] slave_data;
reg [DATA_WIDTH-1:0] slave_tx_shift_reg;
reg [DATA_WIDTH-1:0] slave_rx_shift_reg;
reg [DATA_WIDTH-1:0] captured_mosi;
initial
begin
    slave_data = 8'h3C;
end
always @(negedge cs)
begin
    slave_tx_shift_reg <= slave_data;
    spi_miso <= slave_data[DATA_WIDTH-1];
    slave_rx_shift_reg <= 0;
end



always @(negedge spi_clk)
begin
    if(!cs)
    begin
        slave_tx_shift_reg <={slave_tx_shift_reg[DATA_WIDTH-2:0],1'b0};
		spi_miso <=
        slave_tx_shift_reg[DATA_WIDTH-2];
    end
end

always @(posedge spi_clk)
begin
    if(!cs)
    begin
        slave_rx_shift_reg<={slave_rx_shift_reg[DATA_WIDTH-2:0],spi_mosi};
    end
end

always @(posedge done)
begin
    captured_mosi <= slave_rx_shift_reg;
end
initial
begin
    clk = 0;
    rst = 0;
    start = 0;
    tx_valid = 0;
    rx_read = 0;
  
    tx_data = 0;

    spi_miso = 0;
    #20;
    rst = 1;
    #20;
    tx_valid = 1;

    tx_data = 8'hA5;

    #10;
    tx_data = 8'h3C;


    #10;
    tx_valid = 0;

    #20;

    start = 1;

    #10;

    start = 0;
    wait(done);

    #20;
    start = 1;

    #10;

    start = 0;
end

initial
begin
    wait(done);
    wait(dut.tx_count==0);

    #50;
    rx_read = 1;

    #10;
    rx_read = 0;
    #20;

    $display("FIFO VERIFICATION");
	$display("RX=%h MOSI=%h", rx_data, captured_mosi);
    if(
        dut.tx_count == 0 &&
        dut.rx_count == 0 &&
        rx_data == 8'h3C &&
        captured_mosi == 8'hA5)
	begin
      $display("FIFO test passed");
    end

    else
    begin 
      $display("Test failed");
    end
    $finish;
end
endmodule
