//
//  RCTMGLHeatmapLayer.m
//  RCTMGL
//
//  Created by Lazar on 10/28/18.
//  Copyright © 2018 Mapbox Inc. All rights reserved.
//

#import "RCTMGLHeatmapLayer.h"
#import "RCTMGLStyle.h"

@implementation RCTMGLHeatmapLayer

- (void)updateFilter:(NSPredicate *)predicate
{
    ((MGLHeatmapStyleLayer *) self.styleLayer).predicate = predicate;
}

- (void)setSourceLayerID:(NSString *)sourceLayerID
{
    _sourceLayerID = sourceLayerID;
    
    if (self.styleLayer != nil) {
        ((MGLHeatmapStyleLayer*) self.styleLayer).sourceLayerIdentifier = _sourceLayerID;
    }
}

- (void)addToMap:(MGLStyle *)style
{
    [super addToMap:style];
    
    NSPredicate *filter = [self buildFilters];
    if (filter != nil) {
        [self updateFilter:filter];
    }
}

- (MGLHeatmapStyleLayer*)makeLayer:(MGLStyle*)style
{
    MGLSource *source = [style sourceWithIdentifier:self.sourceID];
    MGLHeatmapStyleLayer *layer = [[MGLHeatmapStyleLayer alloc] initWithIdentifier:self.id source:source];
    layer.sourceLayerIdentifier = _sourceLayerID;
    return layer;
}

- (void)addStyles
{
    RCTMGLStyle *style = [[RCTMGLStyle alloc] initWithMGLStyle:self.style];
    style.bridge = self.bridge;
    [style heatmapLayer:(MGLHeatmapStyleLayer*)self.styleLayer withReactStyle:self.reactStyle];
}

@end
