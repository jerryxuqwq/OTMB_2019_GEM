`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:00:59 02/26/2025 
// Design Name: 
// Module Name:    DRP 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module DRP (
    input wire         clk,        // DRP Clock
    input wire         rst,        // Reset signal
    input wire         drp_rdy,    // DRP Ready signal
    input wire [7:0]   addr,  // address
    output reg         drp_en,     // DRP Enable signal
    output reg         drp_we,     // DRP Write Enable (should be 0 for read)
    output reg [9:0]   drp_addr,   // DRP Address
    output reg [15:0]  drp_di,     // DRP Data Input (not used in read)
    input wire [15:0]  drp_do,     // DRP Data Output (data read)
    output reg [15:0]  data_out,   // Output data
    output reg         data_valid // Data valid flag
    
);
    reg timeout;     // Timeout flag
    reg [1:0] state;
    reg [7:0] timeout_counter; // 8-bit timeout counter
    localparam IDLE = 2'b00, START = 2'b01, WAIT_RDY = 2'b10, DONE = 2'b11;
    localparam TIMEOUT_COUNT = 8'd1000; // Example timeout value (adjust as needed)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= IDLE;
            drp_en           <= 0;
            drp_we           <= 0;
            drp_addr         <= 8'b0;
            drp_di           <= 16'b0;
            data_out         <= 16'b0;
            data_valid       <= 0;
            timeout          <= 0;
            timeout_counter  <= 0;
        end else begin
            case (state)
                IDLE: begin
                    drp_en   <= 1'b1;
                    drp_we   <= 1'b0;  // Read operation
                    drp_addr <= addr; // Example address
                    timeout  <= 1'b0;
                    timeout_counter <= 8'b0;
                    state    <= START;
                end

                START: begin
                    drp_en   <= 1'b0;  // Deassert enable after one cycle
                    state    <= WAIT_RDY;
                end

                WAIT_RDY: begin
                    if (drp_rdy) begin
                        data_out   <= drp_do; // Capture read data
                        data_valid <= 1'b1;
                        state      <= DONE;
                    end 
                    //  else if (timeout_counter >= TIMEOUT_COUNT) begin
                    //     timeout  <= 1'b1; // Set timeout flag
                    //     state    <= IDLE; // Reset to idle state
                    //  end 
                    else begin
                        timeout_counter <= timeout_counter + 1; // Increment timeout counter
                    end
                end

                DONE: begin
                    data_valid <= 1'b0; // Clear valid signal after one cycle
                    state      <= IDLE; // Ready for next transaction
                end
            endcase
        end
    end
endmodule

