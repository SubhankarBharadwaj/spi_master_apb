module spi_apb_tb;
reg pclk;
reg presetn;
reg psel;
reg penable;
reg pwrite;
reg [7:0] paddr;
reg [31:0] pwdata;
wire [31:0] prdata;
wire pready;
wire spi_clk;
wire spi_mosi;
wire cs;
reg spi_miso;

initial begin
    $dumpfile("apb.vcd");
    $dumpvars(0,spi_apb_tb);
end
spi_apb dut
(
.pclk(pclk),
.presetn(presetn),

.psel(psel),
.penable(penable),
.pwrite(pwrite),

.paddr(paddr),
.pwdata(pwdata),

.prdata(prdata),
.pready(pready),

.spi_miso(spi_miso),

.spi_mosi(spi_mosi),
.spi_clk(spi_clk),
.cs(cs)

);
always #5 pclk = ~pclk;
task apb_write(input [7:0] addr,input [31:0] data);
begin
@(posedge pclk);
psel = 1;
penable = 0;

paddr = addr;
pwdata = data;
pwrite = 1;
@(posedge pclk);
penable = 1;
@(posedge pclk);
psel = 0;
penable = 0;
pwrite = 0;
end
endtask
task apb_read(input [7:0] addr);
begin
@(posedge pclk);

psel = 1;
penable = 0;

paddr = addr;
pwrite = 0;
@(posedge pclk);
penable = 1;
@(posedge pclk);

psel = 0;
penable = 0;

end

endtask


initial
begin
pclk=0;
presetn=0;
psel=0;
penable=0;
pwrite=0;
paddr=0;
pwdata=0;
spi_miso=0;

#20;
presetn=1;
apb_write(
8'h08,
32'h000000A5
);
#20;

apb_write(
8'h00,
32'h00000001
);
#20;

apb_write(
8'h00,
32'h00000000
);
wait(dut.u_spi_core.done);

apb_read(8'h04);
 if(dut.u_spi_core.rx_data == 8'h3C)
begin
$display("APB RX=%h", prdata[7:0]);
end
else
begin
$display("SPI Failed");
end
$finish;
end

endmodule