#!/bin/awk

BEGIN {
    i= 0;
    S= 0;
    s= 1;
    }

/\tWidth/ {
    if(s == 1) {
	W=$3;
	V=i;
	w=W;
	v=i;
	}
    else { if($3 < w) {
	    w=$3;
	    v=i;
	    }
	else {
	    print S, W, w, V, v, s-1;
	    S++;
	    s= 1;
	    W=$3;
	    V=i;
	    w=W;
	    v=i;
	    }
	}
    i++;
    s++;     
    }

END {
    print S, W, w, V, v, s-1;
    }
