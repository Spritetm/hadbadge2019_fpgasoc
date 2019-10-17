module button_number( 
	input clk, 
	input [7:0] btn, 
	output [4:0] button
);

always@(posedge clk) begin 
	if (btn[0] == 0) begin 
		button <= 0;
	end
	else if (btn[1] == 0) begin 
		button <= 1;
	end
	else if (btn[2] == 0) begin 
		button <= 2;
	end
	else if (btn[3] == 0) begin 
		button <= 3;
	end
	else if (btn[4] == 0) begin 
		button <= 4;
	end
	else if (btn[5] == 0) begin 
		button <= 5;
	end
	else if (btn[6] == 0) begin 
		button <= 6;
	end
	else if (btn[7] == 0) begin 
		button <= 7;
	end
	else 
		button <= 15; // signal no button
end

endmodule


