function subplotNr = findSubplotNr(rowNr,columnNr,totalColumns)
    subplotNr = (rowNr-1)*totalColumns + columnNr;
end