// clean results
run("Clear Results");
// get all points
getSelectionCoordinates(xCoordinates, yCoordinates);

// chose name pattern for exporting
name = getTitle;

// export as CSV file
for(i=0; i<lengthOf(xCoordinates); i++) {
    setResult("X", i, xCoordinates[i]);
    setResult("Y", i, yCoordinates[i]);
}
updateResults();
saveAs("Results", "slides/"+name+".txt"); 
