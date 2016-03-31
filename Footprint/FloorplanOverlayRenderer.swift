/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class draws your FloorplanOverlay into an MKMapView.
                It is also capable of drawing diagnostic visuals to help with
                debugging, if needed.
*/

import Foundation
import MapKit


class FloorplanOverlayRenderer: MKOverlayRenderer {

    override init(overlay: MKOverlay) {
        super.init(overlay: overlay)
    }

    /**
        - note: Overrides the drawMapRect method for MKOverlayRenderer.
    */
    override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
        assert(overlay.isKindOfClass(FloorplanOverlay), "Wrong overlay type")

        let floorplanOverlay = overlay as! FloorplanOverlay

        let boundingMapRect = overlay.boundingMapRect

        /*
            Mapkit converts to its own dynamic CGPoint frame, which we can read
            through rectForMapRect.
        */
        let mapkitToGraphicsConversion = rectForMapRect(boundingMapRect)

        let graphicsFloorplanCenter = CGPoint(x: CGRectGetMidX(mapkitToGraphicsConversion), y: CGRectGetMidY(mapkitToGraphicsConversion))
        let graphicsFloorplanWidth = CGRectGetWidth(mapkitToGraphicsConversion)
        let graphicsFloorplanHeight = CGRectGetHeight(mapkitToGraphicsConversion)

        // Now, how does this compare to MapKit coordinates?
        let mapkitFloorplanCenter = MKMapPoint(x: MKMapRectGetMidX(overlay.boundingMapRect), y: MKMapRectGetMidY(overlay.boundingMapRect))

        let mapkitFloorplanWidth = MKMapRectGetWidth(overlay.boundingMapRect)
        let mapkitFloorplanHeight = MKMapRectGetHeight(overlay.boundingMapRect)

        /*
            Create the transformation that converts to Graphics coordinates from
            MapKit coordinates.

                graphics.x = (mapkit.x - mapkitFloorplanCenter.x) * 
                                graphicsFloorplanWidth / mapkitFloorplanWidth 
                                + graphicsFloorplanCenter.x
        */
        var fromMapKitToGraphics = CGAffineTransformIdentity as CGAffineTransform

        fromMapKitToGraphics = CGAffineTransformTranslate(fromMapKitToGraphics, CGFloat(-mapkitFloorplanCenter.x), CGFloat(-mapkitFloorplanCenter.y))
        fromMapKitToGraphics = CGAffineTransformScale(
            fromMapKitToGraphics,
            graphicsFloorplanWidth / CGFloat(mapkitFloorplanWidth),
            graphicsFloorplanHeight / CGFloat(mapkitFloorplanHeight)
        )
        fromMapKitToGraphics = CGAffineTransformTranslate(fromMapKitToGraphics, graphicsFloorplanCenter.x, graphicsFloorplanCenter.y)

       
        /*
            However, we want to be able to send draw commands in the original
            PDF coordinates though, so we'll also need the transformations that
            convert to MapKit coordinates from PDF coordinates.
        */
        let fromPDFToMapKit = floorplanOverlay.transformerFromPDFToMk

        CGContextConcatCTM(context, CGAffineTransformConcat(fromPDFToMapKit, fromMapKitToGraphics))

        CGContextDrawPDFPage(context, floorplanOverlay.pdfPage)

		}

	
}