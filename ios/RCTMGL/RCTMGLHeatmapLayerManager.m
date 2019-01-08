//
//  RCTMGLHeatmapLayerManager.m
//  RCTMGL
//
//  Created by Lazar on 10/28/18.
//  Copyright © 2018 Mapbox Inc. All rights reserved.
//

#import "RCTMGLHeatmapLayerManager.h"
#import "RCTMGLHeatmapLayer.h"

@implementation RCTMGLHeatmapLayerManager

RCT_EXPORT_MODULE()

// heapmap layer props
RCT_EXPORT_VIEW_PROPERTY(sourceLayerID, NSString);

// standard layer props
RCT_EXPORT_VIEW_PROPERTY(id, NSString);
RCT_EXPORT_VIEW_PROPERTY(sourceID, NSString);
RCT_EXPORT_VIEW_PROPERTY(filter, NSArray);

RCT_EXPORT_VIEW_PROPERTY(aboveLayerID, NSString);
RCT_EXPORT_VIEW_PROPERTY(belowLayerID, NSString);
RCT_EXPORT_VIEW_PROPERTY(layerIndex, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(reactStyle, NSDictionary);

RCT_EXPORT_VIEW_PROPERTY(maxZoomLevel, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(minZoomLevel, NSNumber);

- (UIView*)view
{
    RCTMGLHeatmapLayer *layer = [RCTMGLHeatmapLayer new];
    layer.bridge = self.bridge;
    return layer;
}

@end
