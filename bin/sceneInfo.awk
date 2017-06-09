#!/bin/awk

BEGIN {
    i= 0;
    s= 1;
    }

/\tWidth/ {
    if(s == 1) {
	W=$3;
	w=W;
	}
    else { if($3 < w) {
	    w=$3;
	    }
	else {
	    print i, W, w, s-1;
	    i++;
	    s= 1;
	    W=$3;
	    w=W;
	    }
	}
     s++;
     
   }

END {
    print i, W, w, s-1;
    }
