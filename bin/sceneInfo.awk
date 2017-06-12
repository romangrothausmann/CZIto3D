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
	    Wn=$3;
	    }
	}
    }

/\tHeight/ {
    if(s == 1) {
	H=$3;
	h=H;
	}
    else { if($3 < h) {
	    h=$3;
	    }
	else {
	    print S, W, H, w, h, V, v, s-1;
	    S++;
	    s= 1;
	    W=Wn;
	    H=$3;
	    V=i;
	    w=W;
	    h=H;
	    v=i;
	    }
	}
    i++;
    s++;     
    }

END {
    print S, W, H, w, h, V, v, s-1;
    }
