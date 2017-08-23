function integer imax;
    input integer x, y;
    begin
        if (x>y) begin
            imax = x;
        end
        else begin
            imax = y;
        end
    end
endfunction
function integer round_to_next_two;
    input integer x;
    begin
    if (x < 2) begin
        round_to_next_two = 2;
    end
    else begin
        x = x - 1;
        x = x | (x >> 1);
        x = x | (x >> 2);
        x = x | (x >> 4);
        x = x | (x >> 8);
        x = x | (x >> 16);
        x = x + 1;
        round_to_next_two = x;
    end
    end
endfunction

function integer clogb2;
    input integer x;
    integer i;
    begin
      clogb2 = 0;
      for(i = 0; 2**i < x; i = i + 1)
            clogb2 = i + 1;
    end
endfunction

function integer gcd;
    input integer x, y;
    integer tmp;
    begin
        while(x) begin
            tmp = x;
            x = y % x;
            y = tmp;
        end
        gcd = y;
    end
endfunction

function integer lcm;
    input integer x, y;
    begin
        lcm = x / gcd(x, y) * y;
    end
endfunction
