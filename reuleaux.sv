module reuleaux(input logic clk, input logic rst_n, input logic [2:0] colour,
                input logic [7:0] centre_x, input logic [6:0] centre_y, input logic [7:0] diameter,
                input logic start, output logic done,
                output logic [7:0] vga_x, output logic [6:0] vga_y,
                output logic [2:0] vga_colour, output logic vga_plot);
     // draw the Reuleaux triangle
     logic [15:0] sqrt3_fixed = 16'd444; // sqrt(3) * 256
     logic [7:0] c_x1, c_x2, c_x3;
     logic [6:0] c_y1, c_y2, c_y3;
     logic [15:0] diameter_val_fixed;  
     logic [23:0] temp_x1, temp_x2, temp_x3;  // Wider temporary variables for rounding
     logic [23:0] temp_y1, temp_y2, temp_y3;
     logic [7:0] offset_y;
     logic [7:0] offset_x ;
     logic signed [15:0] crit;
     logic [7:0] x_count;
     logic [6:0] y_count;
     logic [7:0] centre_x_rst;
     logic [6:0] centre_y_rst;
     logic [7:0] diameter_val;
     

     enum{s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15,s16,s17,s18,s19,s20,s21,s22,s23,s24,s25,s26,s27,s28,s29,s30, start_state} ps;

     always_comb begin 
          // Convert diameter_val to fixed-point (8 integer bits, 8 fractional bits)
          diameter_val_fixed = diameter_val << 8;
          temp_x1 = (centre_x_rst << 8) + (diameter_val_fixed >> 1);  // c_x + diameter_val / 2
          temp_y1 = (centre_y_rst << 8) + ((diameter_val_fixed * sqrt3_fixed) / 6);  // c_y + diameter_val * sqrt(3) / 6
          temp_x2 = (centre_x_rst << 8) - (diameter_val_fixed >> 1);  // c_x - diameter_val / 2
          temp_y2 = (centre_y_rst << 8) + ((diameter_val_fixed * sqrt3_fixed) / 6);  // c_y + diameter_val * sqrt(3) / 6
          temp_x3 = (centre_x_rst << 8);  // c_x
          temp_y3 = 120 - ((centre_y_rst << 8) - ((diameter_val * sqrt3_fixed) / 3));  // c_y - diameter_val * sqrt(3) / 3

          // Apply rounding by adding 0.5 in fixed-point (which is 1 << 7) and then truncating the fractional part
          c_x1 = (temp_x1 + (1 << 7)) >> 8;  // Round and truncate
          c_y1 = (temp_y1 + (1 << 7)) >> 8;  // Round and truncate
          c_x2 = (temp_x2 + (1 << 7)) >> 8;  // Round and truncate
          c_y2 = (temp_y2 + (1 << 7)) >> 8;  // Round and truncate
          c_x3 = (temp_x3 + (1 << 7)) >> 8;  // Round and truncate
          //c_y3 = (temp_y3 + (1 << 7)) >> 8;  // Round and truncate
			 c_y3 = 6'd23;
     end
     always_ff @(posedge clk) begin 
          if(!rst_n) begin 
          	done <= 1'b0;
               vga_plot <= 1'b0;
               x_count <= 8'b0;
               y_count <= 7'b0;
               centre_x_rst <= 8'd80;
               centre_y_rst <= 7'd60;
               diameter_val <= 8'd80;
               ps <= s0;
          end
          else begin 
               case(ps) 
                    s0 : begin 
                         //Black screen pixels
                         if(x_count < 8'd160) begin // x < 160
                    		if(y_count < 7'd120) begin // y < 120
                              	vga_colour <= 3'b000;
                              	vga_x <= x_count;
                              	vga_y <= y_count;
                              	y_count <= y_count + 1'b1;
                              	vga_plot <= 1'b1;
                              	ps <= s0;
                            	end
                            	else begin 
                              	x_count <= x_count + 1'b1;
                              	y_count <= 7'b0;
                              	ps <= s0;
                            	end
                        end
                         else begin 
                              vga_plot <= 1'b0;
                         	x_count <= 8'b0;
                         	y_count <= 7'b0;
                              offset_y <= 8'b0;
                              offset_x <= diameter_val;
                              crit <= 1 - diameter_val;
                              ps <= s1;
                         end
                    end
				s1 : begin 
					if(offset_y <= offset_x) begin
                              vga_colour <= colour;
                              done <= 1'b0;
                              if((c_x1 + offset_x) < 8'd160 && (c_y1 + offset_y) < 7'd120 && ((c_x1 + offset_x) <= c_x3 && (c_x1 + offset_x) >= c_x2 && (c_y1 + offset_y) <= c_y2 && (c_y1 + offset_y) >= c_y3)) begin 
                                   vga_plot <= 1'b1;
                                   vga_x <= c_x1 + offset_x; //oct1
                                   vga_y <= c_y1 + offset_y;
                              end
                              else begin 
                                   vga_plot <= 1'b0;
                                   vga_x <= c_x1 + offset_x; //oct1
                                   vga_y <= c_y1 + offset_y;
                              end
                              ps <= s2;
                         end
                         else begin 
                              //done <= 1'b1;
                              vga_plot <= 1'b0;
                              offset_y <= 8'b0;
                              offset_x <= diameter_val;
                              crit <= 1 - diameter_val;
                              ps <= s9;
                         end
				end
				s2 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x1 + offset_y) < 8'd160 && (c_y1 + offset_x) < 7'd120 && ((c_x1 + offset_y) <= c_x3 && (c_x1 + offset_y) >= c_x2 && (c_y1 + offset_x) <= c_y2 && (c_y1 + offset_x) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x1 + offset_y; //oct2
                              vga_y <= c_y1 + offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x1 + offset_y; //oct2
                              vga_y <= c_y1 + offset_x;
                         end
                         ps <= s3;
				end
				s3 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x1 - offset_y) < 8'd160 && (c_y1 + offset_x) < 7'd120 && ((c_x1 - offset_y) <= c_x3 && (c_x1 - offset_y) >= c_x2 && (c_y1 + offset_x) <= c_y2 && (c_y1 + offset_x) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x1 - offset_y; //oct3
                              vga_y <= c_y1 + offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x1 - offset_y; //oct3
                              vga_y <= c_y1 + offset_x;
                         end
                         ps <= s4;
				end
				s4 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x1 - offset_x) < 8'd160 && (c_y1 + offset_y) < 7'd120 && ((c_x1 - offset_x) <= c_x3 && (c_x1 - offset_x) >= c_x2 && (c_y1 + offset_y) <= c_y2 && (c_y1 + offset_y) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x1 - offset_x; //oct4
                              vga_y <= c_y1 + offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x1 - offset_x; //oct4
                              vga_y <= c_y1 + offset_y;
                         end
                         ps <= s5;
				end
				s5 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x1 - offset_x) < 8'd160 && (c_y1 - offset_y) < 7'd120 && ((c_x1 - offset_x) <= c_x3 && (c_x1 - offset_x) >= c_x2 && (c_y1 - offset_y) <= c_y2 && (c_y1 - offset_y) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x1 - offset_x; //oct5
                              vga_y <= c_y1 - offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x1 - offset_x; //oct5
                              vga_y <= c_y1 - offset_y;
                         end
                         ps <= s6;
				end
				s6 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         vga_x <= c_x1 - offset_y; //oct6
                         vga_y <= c_y1 - offset_x;
                         if((c_x1 - offset_y) < 8'd160 && (c_y1 - offset_x) < 7'd120 && ((c_x1 - offset_y) <= c_x3 && (c_x1 - offset_y) >= c_x2 && (c_y1 - offset_x) <= c_y2 && (c_y1 - offset_x) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x1 - offset_y; //oct6
                              vga_y <= c_y1 - offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x1 - offset_y; //oct6
                              vga_y <= c_y1 - offset_x;
                         end
                         ps <= s7;
				end
				s7 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x1 + offset_y) < 8'd160 && (c_y1 - offset_x) < 7'd120 && ((c_x1 + offset_y) <= c_x3 && (c_x1 + offset_y) >= c_x2 && (c_y1 - offset_x) <= c_y2 && (c_y1 - offset_x) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x1 + offset_y; //oct7
                              vga_y <= c_y1 - offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x1 + offset_y; //oct7
                              vga_y <= c_y1 - offset_x;
                         end
                         ps <= s8;
				end
				s8 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x1 + offset_x) < 8'd160 && (c_y1 - offset_y) < 7'd120 && ((c_x1 + offset_x) <= c_x3 && (c_x1 + offset_x) >= c_x2 && (c_y1 - offset_y) <= c_y2 && (c_y1 - offset_y) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x1 + offset_x; //oct8
                              vga_y <= c_y1 - offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x1 + offset_x; //oct8
                              vga_y <= c_y1 - offset_y;
                         end
                         offset_y <= (offset_y) + 1;
                         ps <= s25;
				end
                    s25 : begin 
                         if(crit <= 0) begin 
                              crit <= (crit) + 2 * offset_y + 1;
                              ps <= s1;
                         end
                         else begin 
                              offset_x <= offset_x - 1;
                              ps <= s26;
                         end
                    end
                    s26 : begin 
                         crit <= (crit) + 2 * ((offset_y) - (offset_x)) + 1;
                         ps <= s1;
                    end
				///////////////Circle 2////////////////
				s9 : begin 
					if(offset_y <= offset_x) begin
                              vga_colour <= colour;
                              done <= 1'b0;
                              if((c_x2 + offset_x) < 8'd160 && (c_y2 + offset_y) < 7'd120 && ((c_x2 + offset_x) <= c_x1 && (c_x2 + offset_x) >= c_x3 && (c_y2 + offset_y) <= c_y1 && (c_y2 + offset_y) >= c_y3)) begin 
                                   vga_plot <= 1'b1;
                                   vga_x <= c_x2 + offset_x; //oct1
                                   vga_y <= c_y2 + offset_y;
                              end
                              else begin 
                                   vga_plot <= 1'b0;
                                   vga_x <= c_x2 + offset_x; //oct1
                                   vga_y <= c_y2 + offset_y;
                              end
                              ps <= s10;
                         end
                         else begin 
                              //done <= 1'b1;
                              vga_plot <= 1'b0;
                              offset_y <= 8'b0;
                              offset_x <= diameter_val;
                              crit <= 1 - diameter_val;
                              ps <= s17;
                         end
				end
				s10 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x2 + offset_y) < 8'd160 && (c_y2 + offset_x) < 7'd120 && ((c_x2 + offset_y) <= c_x1 && (c_x2 + offset_y) >= c_x3 && (c_y2 + offset_x) <= c_y1 && (c_y2 + offset_x) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x2 + offset_y; //oct2
                              vga_y <= c_y2 + offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x2 + offset_y; //oct2
                              vga_y <= c_y2 + offset_x;
                         end
                         ps <= s11;
				end
				s11 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x2 - offset_y) < 8'd160 && (c_y2 + offset_x) < 7'd120 && ((c_x2 - offset_y) <= c_x1 && (c_x2 - offset_y) >= c_x3 && (c_y2 + offset_x) <= c_y1 && (c_y2 + offset_x) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x2 - offset_y; //oct3
                              vga_y <= c_y2 + offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x2 - offset_y; //oct3
                              vga_y <= c_y2 + offset_x;
                         end
                         ps <= s12;
				end
				s12 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x2 - offset_x) < 8'd160 && (c_y2 + offset_y) < 7'd120 && ((c_x2 - offset_x) <= c_x1 && (c_x2 - offset_x) >= c_x3 && (c_y2 + offset_y) <= c_y1 && (c_y2 + offset_y) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x2 - offset_x; //oct4
                              vga_y <= c_y2 + offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x2 - offset_x; //oct4
                              vga_y <= c_y2 + offset_y;
                         end
                         ps <= s13;
				end
				s13 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x2 - offset_x) < 8'd160 && (c_y2 - offset_y) < 7'd120 && ((c_x2 - offset_x) <= c_x1 && (c_x2 - offset_x) >= c_x3 && (c_y2 - offset_y) <= c_y1 && (c_y2 - offset_y) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x2 - offset_x; //oct5
                              vga_y <= c_y2 - offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x2 - offset_x; //oct5
                              vga_y <= c_y2 - offset_y;
                         end
                         ps <= s14;
				end
				s14 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x2 - offset_y) < 8'd160 && (c_y2 - offset_x) < 7'd120 && ((c_x2 - offset_y) <= c_x1 && (c_x2 - offset_y) >= c_x3 && (c_y2 - offset_x) <= c_y1 && (c_y2 - offset_x) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x2 - offset_y; //oct6
                              vga_y <= c_y2 - offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x2 - offset_y; //oct6
                              vga_y <= c_y2 - offset_x;
                         end
                         ps <= s15;
				end
				s15 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x2 + offset_y) < 8'd160 && (c_y2 - offset_x) < 7'd120 && ((c_x2 + offset_y) <= c_x1 && (c_x2 + offset_y) >= c_x3 && (c_y2 - offset_x) <= c_y1 && (c_y2 - offset_x) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x2 + offset_y; //oct7
                              vga_y <= c_y2 - offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x2 + offset_y; //oct7
                              vga_y <= c_y2 - offset_x;
                         end
                         ps <= s16;
				end
				s16 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x2 + offset_x) < 8'd160 && (c_y2 - offset_y) < 7'd120 && ((c_x2 + offset_x) <= c_x1 && (c_x2 + offset_x) >= c_x3 && (c_y2 - offset_y) <= c_y1 && (c_y2 - offset_y) >= c_y3)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x2 + offset_x; //oct8
                              vga_y <= c_y2 - offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x2 + offset_x; //oct8
                              vga_y <= c_y2 - offset_y;
                         end
                         offset_y <= (offset_y) + 1;
                         ps <= s27;
				end
                    s27 : begin 
                         if(crit <= 0) begin 
                              crit <= (crit) + 2 * offset_y + 1;
                              ps <= s9;
                         end
                         else begin 
                              offset_x <= offset_x - 1;
                              ps <= s28;
                         end
                    end
                    s28 : begin 
                         crit <= (crit) + 2 * ((offset_y) - (offset_x)) + 1;
                         ps <= s9;
                    end
				///////////////Circle 3////////////////
				s17 : begin 
					if(offset_y <= offset_x) begin
                              vga_colour <= colour;
                              done <= 1'b0;
                              if((c_x3 + offset_x) < 8'd160 && (c_y3 + offset_y) < 7'd120 && ((c_x3 + offset_x) <= c_x1 && (c_x3 + offset_x) >= c_x2 && (c_y3 + offset_y) >= c_y1)) begin 
                                   vga_plot <= 1'b1;
                                   vga_x <= c_x3 + offset_x; //oct1
                                   vga_y <= c_y3 + offset_y;
                              end
                              else begin 
                                   vga_plot <= 1'b0;
                                   vga_x <= c_x3 + offset_x; //oct1
                                   vga_y <= c_y3 + offset_y;
                              end
                              ps <= s18;
                         end
                         else begin 
                              done <= 1'b1;
                              vga_plot <= 1'b0;
                              offset_y <= 8'b0;
                              centre_x_rst <= centre_x;
                              centre_y_rst <= centre_y;
                              diameter_val <= diameter;
                              ps <= start_state;
                         end
				end
				s18 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x3 + offset_y) < 8'd160 && (c_y3 + offset_x) < 7'd120 && ((c_x3 + offset_y) <= c_x1 && (c_x3 + offset_y) >= c_x2 && (c_y3 + offset_x) >= c_y1)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x3 + offset_y; //oct2
                              vga_y <= c_y3 + offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x3 + offset_y; //oct2
                              vga_y <= c_y3 + offset_x;
                         end
                         ps <= s19;
				end
				s19 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x3 - offset_y) < 8'd160 && (c_y3 + offset_x) < 7'd120 && ((c_x3 - offset_y) <= c_x1 && (c_x3 - offset_y) >= c_x2 && (c_y3 + offset_x) >= c_y1)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x3 - offset_y; //oct3
                              vga_y <= c_y3 + offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x3 - offset_y; //oct3
                              vga_y <= c_y3 + offset_x;
                         end
                         ps <= s20;
				end
				s20 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x3 - offset_x) < 8'd160 && (c_y3 + offset_y) < 7'd120 && ((c_x3 - offset_x) <= c_x1 && (c_x3 - offset_x) >= c_x2 && (c_y3 + offset_y) >= c_y1)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x3 - offset_x; //oct4
                              vga_y <= c_y3 + offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x3 - offset_x; //oct4
                              vga_y <= c_y3 + offset_y;
                         end
                         ps <= s21;
				end
				s21 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x3 - offset_x) < 8'd160 && (c_y3 - offset_y) < 7'd120 && ((c_x3 - offset_x) <= c_x1 && (c_x3 - offset_x) >= c_x2 && (c_y3 - offset_y) >= c_y1)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x3 - offset_x; //oct5
                              vga_y <= c_y3 - offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x3 - offset_x; //oct5
                              vga_y <= c_y3 - offset_y;
                         end
                         ps <= s22;
				end
				s22 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x3 - offset_y) < 8'd160 && (c_y3 - offset_x) < 7'd120 && ((c_x3 - offset_y) <= c_x1 && (c_x3 - offset_y) >= c_x2 && (c_y3 - offset_x) >= c_y1)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x3 - offset_y; //oct6
                              vga_y <= c_y3 - offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x3 - offset_y; //oct6
                              vga_y <= c_y3 - offset_x;
                         end
                         ps <= s23;
				end
				s23 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x3 + offset_y) < 8'd160 && (c_y3 - offset_x) < 7'd120 && ((c_x3 + offset_y) <= c_x1 && (c_x3 + offset_y) >= c_x2 && (c_y3 - offset_x) >= c_y1)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x3 + offset_y; //oct7
                              vga_y <= c_y3 - offset_x;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x3 + offset_y; //oct7
                              vga_y <= c_y3 - offset_x;
                         end
                         ps <= s24;
				end
				s24 : begin 
                         vga_colour <= colour;
                         done <= 1'b0;
                         if((c_x3 + offset_x) < 8'd160 && (c_y3 - offset_y) < 7'd120 && ((c_x3 + offset_x) <= c_x1 && (c_x3 + offset_x) >= c_x2 && (c_y3 - offset_y) >= c_y1)) begin 
                              vga_plot <= 1'b1;
                              vga_x <= c_x3 + offset_x; //oct8
                              vga_y <= c_y3 - offset_y;
                         end
                         else begin 
                              vga_plot <= 1'b0;
                              vga_x <= c_x3 + offset_x; //oct8
                              vga_y <= c_y3 - offset_y;
                         end
                         offset_y <= (offset_y) + 1;
                         ps <= s29;
				end
                    s29 : begin 
                         if(crit <= 0) begin 
                              crit <= (crit) + 2 * offset_y + 1;
                              ps <= s17;
                         end
                         else begin 
                              offset_x <= offset_x - 1;
                              ps <= s30;
                         end
                    end
                    s30 : begin 
                         crit <= (crit) + 2 * ((offset_y) - (offset_x)) + 1;
                         ps <= s17;
                    end
                    start_state : begin 
                         if(start) begin 
                              offset_x <= diameter_val;
                              crit <= 1 - diameter_val;
                              ps <= s1;
                         end
                         else begin 
                              ps <= start_state;
                         end
                    end
               endcase
          end
     end
   
endmodule


