`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Tablica przeglądowa (Look-Up Table) stałych pozycji skrzyń.
 * Mapuje indeksy skrzyń (0-31) na stałe, zbalansowane współrzędne X/Y na mapie świata,
 * wykorzystywane przez silnik graficzny i fizyczny.
 */

 module crate_lut (
    output logic [15:0] crate_x,
    output logic [15:0] crate_y,
    input logic [4:0] crate_id
);

always_comb begin
    case (crate_id)
        /* GRUPA 1: Narozne "L-ki" (Bezpieczna oslona na start) */
        5'd0: begin
            crate_x = 16'd384;
            crate_y = 16'd384;
        end
        5'd1: begin
            crate_x = 16'd512;
            crate_y = 16'd384;
        end
        5'd2: begin
            crate_x = 16'd1504;
            crate_y = 16'd384;
        end
        5'd3: begin
            crate_x = 16'd1632;
            crate_y = 16'd384;
        end
        5'd4: begin
            crate_x = 16'd384;
            crate_y = 16'd1632;
        end
        5'd5: begin
            crate_x = 16'd512;
            crate_y = 16'd1632;
        end
        5'd6: begin
            crate_x = 16'd1504;
            crate_y = 16'd1632;
        end
        5'd7: begin
            crate_x = 16'd1632;
            crate_y = 16'd1632;
        end

        /* GRUPA 2: Flanki (Obwodowe sciezki wokol mapy) */
        5'd8: begin
            crate_x = 16'd1024;
            crate_y = 16'd128;
        end
        5'd9: begin
            crate_x = 16'd1024;
            crate_y = 16'd1888;
        end
        5'd10: begin
            crate_x = 16'd128;
            crate_y = 16'd1024;
        end
        5'd11: begin
            crate_x = 16'd1888;
            crate_y = 16'd1024;
        end

        /* GRUPA 3: Narozniki poteznego "+" na srodku (Epicentrum walki) */
        /* Wcisniete w wewnetrzne katy krzyza - idealna zaslona! */
        5'd12: begin
            crate_x = 16'd832;
            crate_y = 16'd896;
        end
        5'd13: begin
            crate_x = 16'd1056;
            crate_y = 16'd896;
        end
        5'd14: begin
            crate_x = 16'd832;
            crate_y = 16'd1120;
        end
        5'd15: begin
            crate_x = 16'd1056;
            crate_y = 16'd1120;
        end
        
        /* GRUPA 4: Otwarte pole (Ziemia niczyja miedzy rogiem a srodkiem) */
        5'd16: begin
            crate_x = 16'd640;
            crate_y = 16'd640;
        end
        5'd17: begin
            crate_x = 16'd1376;
            crate_y = 16'd640;
        end
        5'd18: begin
            crate_x = 16'd640;
            crate_y = 16'd1376;
        end
        5'd19: begin
            crate_x = 16'd1376;
            crate_y = 16'd1376;
        end

        /* GRUPA 5: Waskie przejscia w osi pionowej (Gateway) */
        5'd20: begin
            crate_x = 16'd768;
            crate_y = 16'd512;
        end
        5'd21: begin
            crate_x = 16'd1248;
            crate_y = 16'd512;
        end
        5'd22: begin
            crate_x = 16'd768;
            crate_y = 16'd1504;
        end
        5'd23: begin
            crate_x = 16'd1248;
            crate_y = 16'd1504;
        end

        /* GRUPA 6: Waskie przejscia w osi poziomej (Gateway) */
        5'd24: begin
            crate_x = 16'd512;
            crate_y = 16'd768;
        end
        5'd25: begin
            crate_x = 16'd1504;
            crate_y = 16'd768;
        end
        5'd26: begin
            crate_x = 16'd512;
            crate_y = 16'd1248;
        end
        5'd27: begin
            crate_x = 16'd1504;
            crate_y = 16'd1248;
        end

        /* GRUPA 7: "Glebokie rogi" (Dla snajperow i uciekinierow) */
        5'd28: begin
            crate_x = 16'd64;
            crate_y = 16'd64;
        end
        5'd29: begin
            crate_x = 16'd1952;
            crate_y = 16'd64;
        end
        5'd30: begin
            crate_x = 16'd64;
            crate_y = 16'd1952;
        end
        5'd31: begin
            crate_x = 16'd1952;
            crate_y = 16'd1952;
        end
        
        default: begin
            crate_x = 16'd0;
            crate_y = 16'd0;
        end
    endcase
end

endmodule