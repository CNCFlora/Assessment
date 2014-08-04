var map = function() {

    var map = L.map('map',{crs:L.CRS.EPSG3857}).setView([-15.79889,-47.866667],4);

    var land = L.tileLayer('http://{s}.tile3.opencyclemap.org/landscape/{z}/{x}/{y}.png')//.addTo(map);
    var ocm = L.tileLayer('http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png').addTo(map);
    var osm = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png')//.addTo(map);

    var markersOk = new L.MarkerClusterGroup(); // clustered valid points
    var pointsOk  = new L.layerGroup(); // valid points

    var markersNok = new L.MarkerClusterGroup(); // clustered invalid points
    var pointsNok  = new L.layerGroup(); // invalid points

    var points  = {};

    for(var i in occurrences) {
        var feature = occurrences[i];

        if(!feature.decimalLatitude || !feature.decimalLongitude) continue;
        if(feature.decimalLatitude == 0.0 || feature.decimalLongitude == 0.0) continue;

        var marker = L.marker(new L.LatLng(feature.decimalLatitude,feature.decimalLongitude));
        marker.bindPopup(document.getElementById("occ-"+feature.occurrenceID+"-unit").innerHTML);

        if(feature.valid) {
            markersOk.addLayer(marker);
            pointsOk.addLayer(marker);
        } else {
            markersNok.addLayer(marker);
            pointsNok.addLayer(marker);
        }

        points[feature.occurrenceID] = marker;
    }

    map.addLayer(markersOk);
    map.addLayer(markersNok);

    var base = {
        Landscape: land,
        OpenCycleMap: ocm,
        OpenStreetMap: osm
    };

    var layers = {
        'Valid points': pointsOk,
        'Valid points clustered': markersOk,
        'Non-valid points': pointsNok,
        'Non-valid points clustered': markersNok,
    };

    L.control.layers(base,layers).addTo(map);
    L.control.scale().addTo(map);

    $(".to-map").click(function(evt){ 
        // zoom in and open point in map
        var id = $(evt.target).attr("rel");
        map.setView(points[id]._latlng,10)
        setTimeout(function(){
            location.hash="map";
            points[id].openPopup();
        },250);
        location.hash="";
    });

};
