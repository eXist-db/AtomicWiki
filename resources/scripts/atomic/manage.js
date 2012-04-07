$(document).ready(function() {
    var columns = [
        {id:"id", name:"Id", field:"id", sortable: true, resizable: true, maxWidth: 100, minWidth: 60},
        {id:"name", name:"Name", field:"name", sortable: true, resizable: true, minWidth: 100},
    	{id:"title", name:"Title", field:"title", sortable: true, resizable: true, minWidth: 100}
	];
    var options = {
		editable: false,
        multiSelect: false,
        forceFitColumns: true,
        enableColumnReorder: false
	};
    var gridData = [];
    var grid;
    
    grid = new Slick.Grid("#structure", gridData, columns, options);
    var selectionModel = new Slick.RowSelectionModel({selectActiveRow: true});
    grid.setSelectionModel(selectionModel);
    
    $.getJSON("modules/list.xql", function (data) {
        gridData.length = data.length;
        for (var i = 0; i < data.length; i++) {
            gridData[i] = data[i];
        }
        grid.updateRowCount();
	    grid.render();
        grid.setActiveCell(0, 0);
		grid.setSelectedRows([0]);
    })
});