/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Copyright Team Samurai 2016. All Rights

Abstract:
Primary view controller for what is displayed by the application.
In this class we configure an MKMapView to display a floorplan,
also implementing the positioning algorithm in the class, and add
the annotaion for display and updating current position
*/

import CoreLocation
import Foundation
import MapKit


/**
Primary view controller for what is displayed by the application.

In this class we configure an MKMapView to display a floorplan, recieve
location updates to determine floor number, as well as provide a few helpful
debugging annotations.

We will also show how to highlight a region that you have defined in PDF
coordinates but not Latitude & Longitude.
*/
class ViewController: UIViewController, MKMapViewDelegate,CLLocationManagerDelegate {
	
	
	/// Outlet for the map view in the storyboard.
	@IBOutlet weak var mapView: MKMapView!
	
	/// Outlet for the visuals switch at the lower-right of the storyboard.
	@IBOutlet weak var debugVisualsSwitch: UISwitch!
	
	@IBOutlet weak var mapLabel: UILabel!
	/**
	To enable user location to be shown in the map, go to Main.storyboard,
	select the Map View, open its Attribute Inspector and click the checkbox
	next to User Location
	
	The user will need to authorize this app to use their location either by
	enabling it in Settings or by selecting the appropriate option when
	prompted.
	*/
	var beaconList:[beaconInfo] = []
	
	var destinationRoom:String?
	
	var Mapfilename:String = "Welcome"
	
	var roomList:[String]!
	
	
	let locationManager = CLLocationManager()
	let region = CLBeaconRegion(proximityUUID:NSUUID(UUIDString: "F7826DA6-4FA2-4E98-8024-BC5B71E0893E")!, identifier: "Kontakt.io")
	
	
	var timer = NSTimer()
	
	var x:CGFloat = 1.0
	var y:CGFloat = 1.0
	
	var hideBackgroundOverlayAlpha: CGFloat!
	
	/// Helper class for managing the scroll & zoom of the MapView camera.
	var visibleMapRegionDelegate: VisibleMapRegionDelegate!
	
	/// Store the data about our floorplan here.
	var floorplan0: FloorplanOverlay!
	
	var anchorPair: GeoAnchorPair!
	
	var coordinateConverter: CoordinateConverter!
	
	/// This property remembers which floor we're on.
	var lastFloor: CLFloor!
	
	/**
	Set to false if you want to turn off auto-scroll & auto-zoom that snaps
	to the floorplan in case you scroll or zoom too far away.
	*/
	var snapMapViewToFloorplan: Bool!
	
	var polyline:MKGeodesicPolyline!
	
	var AutoZoom:Bool = false //the indicator for auto zoom in
	var zoomUnzoom:Bool = false
	
	/**
	Set to true when we reveal the MapKit tileset (by pressing the trashcan
	button).
	*/
	
	@IBOutlet weak var ZoomBtn: UIBarButtonItem!
	/// Call this to reset the camera.
	@IBAction func setCamera(sender: AnyObject) {
		zoomUnzoom = !zoomUnzoom
		if(zoomUnzoom == true){
			zoomin()
			ZoomBtn.title = "Zoom Out"
		}else{
			ZoomBtn.title = "Zoom In"
			let theSpan = MKCoordinateSpanMake(0.0025, 0.0025)
			let location = MKCoordinateForMapPoint(coordinateConverter.MKMapPointFromPDFPoint(CGPointMake(x, y)))
			let theRegion = MKCoordinateRegion(center: location, span: theSpan)
			mapView.setRegion(theRegion, animated: false)
			visibleMapRegionDelegate.mapViewResetCameraToFloorplan(mapView)
			
		}
		
	}
	
	/**
	When the switch is on, performing auto zoom lock feature, when turn off reset the free camara
	*/
	@IBAction func toggleDebugVisuals(sender: AnyObject) {
		if (sender.isKindOfClass(UISwitch.classForCoder())) {
			let senderSwitch: UISwitch = sender as! UISwitch
			/*
			If we have revealed the mapkit tileset (i.e. the trash icon was
			pressed), toggle the floorplan display off.
			*/
			
			if (senderSwitch.on == true) {
				AutoZoom = true
				ZoomBtn.title = "Auto Zoom"
				ZoomBtn.enabled = false
				
			} else {
				ZoomBtn.title = "Zoom Out"
				ZoomBtn.enabled = true
				AutoZoom = false
				zoomUnzoom = true
			}
		}
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		// === Configure region beacons
		locationManager.delegate = self
		
		if(CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse){
			locationManager.requestWhenInUseAuthorization()
		}
		beaconList = make_list()
		
		if(Mapfilename != "Welcome"){
			locationManager.startRangingBeaconsInRegion(region)
			
		}
		
		// === Configure our floorplan.
		
		/*
		We setup a pair of anchors that will define how the floorplan image
		maps to geographic co-ordinates.
		*/
		
		
		let anchor1 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(37.770419,-122.465726), pdfPoint: CGPointMake(26.2, 86.4))
		
		let anchor2 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(37.769288,-122.466376), pdfPoint: CGPointMake(570.1, 317.7))
		
		anchorPair = GeoAnchorPair(fromAnchor: anchor1, toAnchor: anchor2)
		
		
		// === Initialize our assets
		
		/*
		We have to specify subdirectory here since we copy our folder
		reference during "Copy Bundle Resources" section under target
		settings build phases.
		*/
		
		
		
		let pdfUrl = NSBundle.mainBundle().URLForResource(Mapfilename, withExtension: "pdf", subdirectory:"Floorplans")!
		
		floorplan0 = FloorplanOverlay(floorplanUrl: pdfUrl, withPDFBox: CGPDFBox.TrimBox, andAnchors: anchorPair, forFloorLevel: 0)
		
		visibleMapRegionDelegate = VisibleMapRegionDelegate(floorplanBounds: floorplan0.boundingMapRectIncludingRotations, boundingPDFBox: floorplan0.floorplanPDFBox,
			floorplanCenter: floorplan0.coordinate,
			floorplanUprightMKMapCameraHeading: floorplan0.getFloorplanUprightMKMapCameraHeading())
		
		// === Initialize our view
		hideBackgroundOverlayAlpha = 1.0
		
		// Disable tileset.
		mapView.addOverlay(HideBackgroundOverlay.hideBackgroundOverlay(), level: .AboveRoads)
		
		
		// Draw the floorplan!
		mapView.addOverlay(floorplan0)
		
		//show the current location
		trackFootprint()
		
		
		/*
		By default, we listen to the scroll & zoom events to make sure that
		if the user scrolls/zooms too far away from the floorplan, we
		automatically bounce back. If you would like to disable this
		behavior, comment out the following line.
		*/
		snapMapViewToFloorplan = true
		
		roomList = getRoomTable(Mapfilename,mapList:mapList())
		mapLabel.text = Mapfilename
		ZoomBtn.title = "Zoom In"
		
	}
	
	
	override func viewDidAppear(animated: Bool) {
		/*
		For additional debugging, you may prefer to use non-satellite
		(standard) view instead of satellite view. If so, uncomment the line
		below. However, satellite view allows you to zoom in more closely
		than non-satellite view so you probably do not want to leave it this
		way in production.
		*/
		
	}
	
	//auto zoom in function
	func zoomin(){
		var theLocation:CLLocationCoordinate2D!
		var theSpan:MKCoordinateSpan!
		var ax:Double,ay:Double
		if(destinationRoom == nil){
			ax = Double(x)
			ay = Double(y)
		}else{
			(ax,ay) = findRoom(destinationRoom!)
		}
		let (tX,tY) = (CGFloat(ax),CGFloat(ay))
		
		let dist = abs(Int(x-tX))
		
		if (dist < 150) {
			theSpan = MKCoordinateSpanMake(0.0006, 0.0006)
		}else if (dist < 220) {
			theSpan = MKCoordinateSpanMake(0.0009, 0.0009)
		}else{
			theSpan = MKCoordinateSpanMake(0.0013, 0.0013)
			
		}
		theLocation = MKCoordinateForMapPoint(coordinateConverter.MKMapPointFromPDFPoint(CGPointMake((x+tX)/2, (y+tY)/2)))
		let theRegion = MKCoordinateRegion(center: theLocation, span: theSpan)
		mapView.setRegion(theRegion, animated: true)
		
		
		
	}
	
	//Track and show the current position
	func trackFootprint(){
		coordinateConverter = CoordinateConverter(anchors: anchorPair)
		timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "timerAction", userInfo: nil, repeats: true)
	}
	
	func timerAction(){
		let location = locationAnnotationsForMapView()
		mapView.addAnnotation(location)
		if(AutoZoom == true){
			zoomin()
		}
		let delay = 0.99 * Double(NSEC_PER_SEC)
		let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
		dispatch_after(time, dispatch_get_main_queue()) {
			self.mapView.removeAnnotation(location)
		}
		
		
	}
	
	//function makes the annotation point for current position
	func locationAnnotationsForMapView() -> MKPointAnnotation {
		// Drop a red pin on the fromAnchor latitudeLongitude location
		let location = MKPointAnnotation()
		location.title = "Current Position"
		location.coordinate =  MKCoordinateForMapPoint(coordinateConverter.MKMapPointFromPDFPoint(CGPointMake(x, y)))
		
		return location
	}
	
	func showDesination() {
		
		
		print("the room is \(destinationRoom!)")
		let anchor1 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(37.770419,-122.465726), pdfPoint: CGPointMake(26.2, 86.4))
		
		let anchor2 = GeoAnchor(latitudeLongitudeCoordinate: CLLocationCoordinate2DMake(37.769288,-122.466376), pdfPoint: CGPointMake(570.1, 317.7))
		anchorPair = GeoAnchorPair(fromAnchor: anchor1, toAnchor: anchor2)
		// Drop a red pin on the fromAnchor latitudeLongitude location
		let coordinateConverter = CoordinateConverter(anchors: anchorPair)
		let destination = MKPointAnnotation()
		destination.title = destinationRoom!
		let (ax,ay) = findRoom(destinationRoom!)
		destination.coordinate =  MKCoordinateForMapPoint(coordinateConverter.MKMapPointFromPDFPoint(CGPointMake(CGFloat(ax), CGFloat(ay))))
		print(destination.coordinate)
		let delay = 1.00 * Double(NSEC_PER_SEC)
		let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
		dispatch_after(time, dispatch_get_main_queue()) {
			self.mapView.addAnnotation(destination)
		}
		
		
		
		
		
	}
	
	
	
	/// Respond to CoreLocation updates
	func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
		let location: CLLocation = userLocation.location!
		
		// CLLocation updates will not always have floor information...
		if (location.floor != nil) {
			// ...but when they do, take note!
			NSLog("Location (Floor %ld): %s", location.floor!, location.description)
			lastFloor = location.floor
			NSLog("We are on floor %ld", lastFloor.level)
		}
	}
	
	/// Request authorization if needed.
	func mapViewWillStartLocatingUser(mapView: MKMapView) {
		switch (CLLocationManager.authorizationStatus()) {
		case CLAuthorizationStatus.NotDetermined:
			// Ask the user for permission to use location.
			locationManager.requestWhenInUseAuthorization()
		case CLAuthorizationStatus.Denied:
			NSLog("Please authorize location services for this app under Settings > Privacy")
		case CLAuthorizationStatus.AuthorizedAlways, CLAuthorizationStatus.AuthorizedWhenInUse, CLAuthorizationStatus.Restricted:
			break
		}
	}
	
	/// Helper method that shows the floorplan.
	func showFloorplan() {
		mapView.addOverlay(floorplan0)
	}
	
	/// Helper method that hides the floorplan.
	func hideFloorplan() {
		mapView.removeOverlay(floorplan0)
	}
	
	
	
	/**
	Check for when the MKMapView is zoomed or scrolled in case we need to
	bounce back to the floorplan. If, instead, you're using e.g.
	MKUserTrackingModeFollow then you'll want to disable
	snapMapViewToFloorplan since it will conflict with the user-follow
	scroll/zoom.
	*/
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		if (snapMapViewToFloorplan == true) {
			visibleMapRegionDelegate.mapView(mapView, regionDidChangeAnimated:animated)
		}
	}
	
	//create route
	func createPolyline(){
		
		let coordinateConverter = CoordinateConverter(anchors: anchorPair)
		let (ax,ay) = findRoom(destinationRoom!)
		
		let newY = (CGFloat(ay)+y)/2
		
		let Location1:CLLocationCoordinate2D = MKCoordinateForMapPoint(coordinateConverter.MKMapPointFromPDFPoint(CGPointMake(x, y)))
		let Location2 =  MKCoordinateForMapPoint(coordinateConverter.MKMapPointFromPDFPoint(CGPointMake(CGFloat(ax), CGFloat(y))))
		
		var points: [CLLocationCoordinate2D]
		points = [Location1, Location2]
		polyline = MKGeodesicPolyline(coordinates: &points[0], count: 2)
		
		mapView.addOverlay(polyline)
		
	}
	
	
	/// Produce each type of renderer that might exist in our mapView.
	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		
		if (overlay.isKindOfClass(FloorplanOverlay)) {
			let renderer: FloorplanOverlayRenderer = FloorplanOverlayRenderer(overlay: overlay as MKOverlay)
			return renderer
		}
		
		if (overlay.isKindOfClass(HideBackgroundOverlay) == true) {
			let renderer = MKPolygonRenderer(overlay: overlay as MKOverlay)
			
			/*
			HideBackgroundOverlay covers the entire world, so this means all
			of MapKit's tiles will be replaced with a solid white background
			*/
			renderer.fillColor = UIColor.whiteColor().colorWithAlphaComponent(hideBackgroundOverlayAlpha)
			
			// No border.
			renderer.lineWidth = 0.0
			renderer.strokeColor = UIColor.whiteColor().colorWithAlphaComponent(0.0)
			
			return renderer
		}
		
		if (overlay.isKindOfClass(MKPolygon) == true) {
			let polygon: MKPolygon = overlay as! MKPolygon
			
			/*
			A quick and dirty MKPolygon renderer for addDebuggingOverlays
			and our custom highlight region.
			In production, you'll want to implement this more cleanly.
			"However, if each overlay uses different colors or drawing
			attributes, you should find a way to initialize that information
			using the annotation object, rather than having a large decision
			tree in mapView:rendererForOverlay:"
			
			See "Creating Overlay Renderers from Your Delegate Object"
			*/
			if (polygon.title == "Hello World") {
				let renderer = MKPolygonRenderer(polygon: polygon)
				renderer.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.5)
				renderer.strokeColor = UIColor.yellowColor().colorWithAlphaComponent(0.0)
				renderer.lineWidth = 0.0
				return renderer
			}
			
			if (polygon.title == "debug") {
				let renderer = MKPolygonRenderer(polygon: polygon)
				renderer.fillColor = UIColor.grayColor().colorWithAlphaComponent(0.1)
				renderer.strokeColor = UIColor.cyanColor().colorWithAlphaComponent(0.5)
				renderer.lineWidth = 2.0
				return renderer
			}
		}
		//overlay route
		if (overlay is MKPolyline) {
			let pr = MKPolylineRenderer(overlay: overlay);
			pr.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.5);
			pr.lineWidth = 7;
			return pr;
		}
		
		NSException(name:"InvalidMKOverlay", reason:"Did you add an overlay but forget to provide a matching renderer here? The class was type \(overlay.dynamicType)", userInfo:["wasClass": overlay.dynamicType]).raise()
		return MKOverlayRenderer()
	}
	
	/// Produce each type of annotation view that might exist in our MapView.
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		/*
		For now, all we have are some quick and dirty pins for viewing debug
		annotations. To learn more about showing annotations,
		see "Annotating Maps".
		*/
		//the destination pinview configuration
		if (destinationRoom != nil) {
			if (annotation.title! == destinationRoom!){
				
				if annotation is MKUserLocation {
					return nil
				}
				
				let pinView = "destination"
				
				var pin: MKAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(pinView)
				if pin != nil {
					pin.annotation = annotation
				}else{
					pin = MKAnnotationView(annotation: annotation, reuseIdentifier: pinView)
					pin.image = UIImage(named: "Floorplans/destination.png")
					pin.canShowCallout = true
					pin.rightCalloutAccessoryView = UIButton(type: .ContactAdd)
				}
				
				return pin
			}
		}
		
		//the current position pinview configuration
		if (annotation.title! == "Current Position") {
			if annotation is MKUserLocation {
				return nil
			}
			
			let annotationIdentifier = "userlocation" // use something unique that functionally identifies the type of pin
			
			var annotationView: MKAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationIdentifier)
			
			if annotationView != nil {
				annotationView.annotation = annotation
			} else {
				annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
				
				annotationView.image = UIImage(named: "Floorplans/current.png")
				
				annotationView.canShowCallout = true
				
				annotationView.autoresizesSubviews = true
			}
			
			return annotationView
		}
		
		return nil
	}
	//control the button for destination
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		if control == view.rightCalloutAccessoryView{
			
			
			if(polyline != nil){
				mapView.removeOverlay(polyline)
			}
			createPolyline()
			
		}
	}
	
	
	//beacon range definition
	func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
		let knownBeacons = beacons.filter{$0.proximity != CLProximity.Unknown}
		var calX:Double = 0.0
		var calY:Double = 0.0
		var flag:Bool = false //initialize
		
		//print("beacon number is \(knownBeacons.count)")
		//        Get position through tag reconition
		if(knownBeacons.count == 0){
			ZoomBtn.enabled = false;
			debugVisualsSwitch.enabled = false;
		}
		
		if(knownBeacons.count < 3){
			
			var avgX = 0.0
			var avgY = 0.0
			for aBeacon in knownBeacons{
				
				let tempMinor = aBeacon.minor
				for i in 0...beaconList.count-1{
					if(tempMinor == beaconList[i].Minor){
						(calX,calY) = (beaconList[i].addrX,beaconList[i].addrY)
						//                        print("[tag pos]the cordinate is \(calX,calY)")
					}
				}
				if(aBeacon.proximity == .Immediate){
					flag = true
					break;//return calX,Y
				}else{
					avgX += calX
					avgY += calY
				}
				
				
			}
			if(flag == false){
				calX = avgX / Double(knownBeacons.count)
				calY = avgY / Double(knownBeacons.count)
				flag = true
			}
			
		}
		
		
		
		//Get position through Triangulation
		if(knownBeacons.count >= 3 && flag == false){
			print(knownBeacons.count)
			
			let addr = calcPosition(knownBeacons)
			
			
			calX = NSString(format: "%.1f", addr.pX).doubleValue
			calY = NSString(format: "%.2f", addr.pY).doubleValue
			
			//            print("[tri pos]the cordinate is \(calX,calY)")
			
			
		}
		
		x = CGFloat(calX)
		y = CGFloat(calY)
		
		
		
	}
	
	//calculate position in triangulation
	func calcPosition(Beacons : [CLBeacon])->(pX:Double, pY: Double){ //return the positioning cordinate
		
		var useBeaconNum = Beacons.count
		var count:Double = 0.0
		
		//initial address list
		var beaconAddr : [(addrX:Double,addrY:Double)] = []
		
		if(useBeaconNum > 6){
			useBeaconNum = 6
		}
		print(useBeaconNum)
		
		for i in 0...(useBeaconNum - 1){
			for j in 0...beaconList.count-1 {
				if (Beacons[i].minor == beaconList[j].Minor){
					beaconAddr.append((addrX: beaconList[j].addrX, addrY: beaconList[j].addrY))
				}
			}
		}
		
		
		
		
		
		var mass = [Double](count:beaconList.count, repeatedValue: 0.0)
		
		for i in 0...beaconAddr.count-1 {
			mass[i] = calcMass(Beacons[i])
		}
		
		
		var sumX = 0.0
		var sumY = 0.0
		
		
		for i in 0...beaconAddr.count-1{
			count += mass[i]
			sumX += beaconAddr[i].addrX * mass[i]
			sumY += beaconAddr[i].addrY * mass[i]
		}
		
		let calx = sumX / count
		let caly = sumY / count
		
		return (calx,caly)
	}
	
	
	//calculate mass as a numeric representation to distance
	func calcMass(Beacon:CLBeacon)->Double{
		
		var Mass = 0.0
		
		switch(Beacon.proximity){
		case .Immediate:
			Mass = 1000 + (1/Beacon.accuracy)
			break
		case .Near:
			Mass = 100 + (10/Beacon.accuracy)
			break
		case .Far:
			Mass = 10 + (100/Beacon.accuracy)
			break
		default:
			Mass = 1;
		}
		
		//        print("Prox: \(Beacon.proximity.hashValue) rssi: \(rssi) accuracy\(Accuracy)")
		//        print("distance\(dist)")
		
		
		
		return Mass
	}
	
	//segue activity for view switching
	
	let listRoomSegue = "roomList"
	let mapSelectSegue = "mapSelect"
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == listRoomSegue {
			locationManager.stopMonitoringForRegion(region)
			if let destination = segue.destinationViewController as?  FirstTableViewController{
				destination.FirstTableArray = self.roomList
				destination.Map = self.Mapfilename
			}
		}
		if segue.identifier == mapSelectSegue {
			locationManager.stopMonitoringForRegion(region)
			if let destination = segue.destinationViewController as?  MapSelectViewController{
				self.mapView.removeOverlay(self.floorplan0)
				destination.FirstTableArray = mapList()
			}
		}
	}
	
	
	
}




