/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description: 
 * LUT mapping crate ID (0-31) to global map coordinates (X, Y).
 * Map resolution: 64x64 tiles. Each tile = 32px (64 * 32 = 2048px).
 * Coordinates are provided in pixels (0-2047).
 */

 module crate_lut (
    input  logic [4:0]  crate_id,
    output logic [15:0] crate_x,
    output logic [15:0] crate_y
);

always_comb begin
    case (crate_id)
        // Środkowy obszar (pusta przestrzeń)
        5'd0:  begin crate_x = 16'd512;  crate_y = 16'd256;  end
        5'd1:  begin crate_x = 16'd512;  crate_y = 16'd512;  end
        5'd2:  begin crate_x = 16'd1536; crate_y = 16'd256;  end
        5'd3:  begin crate_x = 16'd1536; crate_y = 16'd512;  end
        
        // Prawy obszar (między ścianami)
        5'd4:  begin crate_x = 16'd1800; crate_y = 16'd1000; end
        5'd5:  begin crate_x = 16'd1800; crate_y = 16'd1200; end
        5'd6:  begin crate_x = 16'd1800; crate_y = 16'd1400; end
        5'd7:  begin crate_x = 16'd1800; crate_y = 16'd1600; end
        
        // Lewy obszar
        5'd8:  begin crate_x = 16'd250;  crate_y = 16'd1000; end
        5'd9:  begin crate_x = 16'd250;  crate_y = 16'd1200; end
        5'd10: begin crate_x = 16'd250;  crate_y = 16'd1400; end
        5'd11: begin crate_x = 16'd250;  crate_y = 16'd1600; end
        
        // Dolne sekcje
        5'd12: begin crate_x = 16'd600;  crate_y = 16'd1700; end
        5'd13: begin crate_x = 16'd800;  crate_y = 16'd1700; end
        5'd14: begin crate_x = 16'd1200; crate_y = 16'd1700; end
        5'd15: begin crate_x = 16'd1400; crate_y = 16'd1700; end
        
        // Rozproszenie w pozostałych pustych strefach
        5'd16: begin crate_x = 16'd1024; crate_y = 16'd1024; end
        5'd17: begin crate_x = 16'd1024; crate_y = 16'd1200; end
        5'd18: begin crate_x = 16'd1200; crate_y = 16'd1024; end
        5'd19: begin crate_x = 16'd800;  crate_y = 16'd1024; end
        
        // Górne sekcje
        5'd20: begin crate_x = 16'd300;  crate_y = 16'd300;  end
        5'd21: begin crate_x = 16'd400;  crate_y = 16'd400;  end
        5'd22: begin crate_x = 16'd1600; crate_y = 16'd300;  end
        5'd23: begin crate_x = 16'd1700; crate_y = 16'd400;  end
        
        // Dodatkowe skrzynki
        5'd24: begin crate_x = 16'd900;  crate_y = 16'd400;  end
        5'd25: begin crate_x = 16'd1100; crate_y = 16'd400;  end
        5'd26: begin crate_x = 16'd900;  crate_y = 16'd1500; end
        5'd27: begin crate_x = 16'd1100; crate_y = 16'd1500; end
        5'd28: begin crate_x = 16'd500;  crate_y = 16'd1500; end
        5'd29: begin crate_x = 16'd1500; crate_y = 16'd1500; end
        5'd30: begin crate_x = 16'd500;  crate_y = 16'd500;  end
        5'd31: begin crate_x = 16'd1500; crate_y = 16'd500;  end
        
        default: begin
            crate_x = 16'd0;
            crate_y = 16'd0;
        end
    endcase
end
endmodule